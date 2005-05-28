/*
 * MPEG1/2 parser and demuxer, can handle:
 *
 *   - program streams
 *   - transport streams
 *   - simple mp3 files
 *
 * (c) 2003 Gerd Knorr <kraxel@bytesex.org>
 *
 */
#include "config.h"
#define _GNU_SOURCE       /* for memmem() */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <inttypes.h>
#include <sys/stat.h>
#include <sys/uio.h>

#include "grab-ng.h"
#include "misc.h"
#include "parse-mpeg.h"

#define MP3_AUDIO_BUF        (4*1024)
#define TS_AUDIO_BUF        (32*1026)

#define DROP_FRAMES                 1
#define ERROR_LIMIT                64

/* ----------------------------------------------------------------------- */
/* common MPEG demux code                                                  */

static int set_video_seq_ts(struct mpeg_handle *h, struct psc_info *psc)
{
    uint64_t pts;
    int frames;

    /* calculate sequence number */
    if (psc->gop_seen)
	h->gop_ref = *psc;
    psc->play_seq = h->gop_ref.dec_seq + psc->temp_ref - h->gop_ref.temp_ref;

    /* calculate pts */
    if (psc->pts) {
	h->pts_ref = *psc;
	pts        = psc->pts;
    } else {
	frames = psc->play_seq - h->pts_ref.play_seq;
	pts    = h->pts_ref.pts + (int64_t)90000 * frames *
	    mpeg_rate_d[h->rate] / mpeg_rate_n[h->rate];
    }

    /* set buffer */
    h->vbuf->info.ts        = pts * (uint64_t)1000000 / (uint64_t)90;
    h->vbuf->info.file_seq  = psc->dec_seq;
    h->vbuf->info.play_seq  = psc->play_seq;
    h->vbuf->info.frame     = psc->frame;
    if (ng_debug > 1)
	fprintf(stderr,
		"mpeg: pts %8.3f temp_ref %2d  ->  file %d play %d ts %.3f  [%s%s]\n",
		psc->pts/90000.0, psc->temp_ref,
		h->vbuf->info.file_seq, h->vbuf->info.play_seq,
		h->vbuf->info.ts / 1000000000.0,
		mpeg_frame_s[psc->frame], psc->gop_seen ? ",gop" : "");
    return 0;
}

static int put_video(struct mpeg_handle *h,
		     unsigned char *ptr, size_t bytes)
{
    struct ng_video_fifo  *fifo = NULL;
    unsigned char *p1,*p2,*cut;
    struct psc_info psc;
    size_t add;
    
    p1  = ptr;
    cut = NULL;
    for (;;) {
#if 0 /* for debugging, works for TS streams only */
	if (bytes > TS_SIZE)
	    abort();
#endif
	if (bytes < 4) {
	    if (ng_debug > 2)
		fprintf(stderr,"mpeg: ignoring tiny packet (%d bytes)\n",(int)bytes);
	    return 0;
	}
	p2 = memchr(p1,0,bytes - (p1-ptr) - 3);
	if (NULL == p2)
	    break;
	if (p2[1] == 0x00 && p2[2] == 0x01) {
	    switch (p2[3]) {
	    case 0xb3: /* sequence header */
	    case 0xb8: /* group of pictures (I-frame follows) */
		if (h->psc_seen) {
		    cut   = p2;
		    psc   = h->psc;
		    h->psc_seen = 0;
		}
		h->gop_seen = 1;
		break;
	    case 0x00: /* picture start code */
		if (h->psc_seen) {
		    cut   = p2;
		    psc   = h->psc;
		} else {
		    h->psc_seen = 1;
		}
		switch (mpeg_getbits(p2,42,3)) {
		case 1:  h->psc.frame = NG_FRAME_I_FRAME; break;
		case 2:  h->psc.frame = NG_FRAME_P_FRAME; break;
		case 3:  h->psc.frame = NG_FRAME_B_FRAME; break;
		default:
		    if (ng_log_bad_stream)
			OOPS("mpeg: unknown frame type (%d)",mpeg_getbits(p2,42,3));
		    h->psc.frame = NG_FRAME_UNKNOWN;
		    break;
		}
		h->psc.temp_ref = mpeg_getbits(p2,32,10);
		h->psc.pts      = h->video_pts;
		h->psc.gop_seen = h->gop_seen;
		h->psc.dec_seq  = h->frames++;
		h->video_pts    = 0;
		h->gop_seen     = 0;
		break;
	    }
	    if (ng_debug > 2)
		fprintf(stderr,"mpeg: %02x %02x %02x %02x %s\n",
			p2[0], p2[1], p2[2], p2[3], (cut == p2) ? "[cut]" : "");

	    if (cut) {
		/* finish up buffer */
		add = cut - ptr;
		if (add > bytes)
		    abort();
		memcpy(h->vbuf->data + h->vbuf->size, ptr, add);
		h->vbuf->size += add;
		bytes -= add;
		ptr   += add;
		cut    = NULL;

		/* sequence number + time stamps */
		set_video_seq_ts(h,&psc);
		
		/* add buffer to fifo */
		fifo = malloc(sizeof(*fifo));
		memset(fifo,0,sizeof(*fifo));
		list_add_tail(&fifo->next, &h->vfifo);
		fifo->buf = h->vbuf;

		/* alloc a new buffer */
		h->vbuf = ng_malloc_video_buf(NULL, &h->vfmt);
		h->vbuf->info.ratio = h->ratio;
		h->vbuf->size = 0;
	    }
	}
	p1 = p2+1;
    }

    /* put remaining bytes into buffer */
    memcpy(h->vbuf->data + h->vbuf->size, ptr, bytes);
    h->vbuf->size += bytes;
    return 0;
}

static void check_pts(char *msg, uint64_t *pts, uint64_t *last)
{
    uint64_t secs = 30;

    if (0 == *last)
	goto done;

    if (*pts < *last - secs*90000) {
	if (ng_log_bad_stream)
	    fprintf(stderr,"mpeg: broken %s pts (< last -%ds) [%.2f]\n",
		    msg, (int)secs, (int)((*pts) - (*last))/90000.0);
	*pts = *last;
    }
    if (*pts > *last + secs*90000) {
	if (ng_log_bad_stream)
	    fprintf(stderr,"mpeg: broken %s pts (> last +%ds) [%.2f]\n",
		    msg, (int)secs, (int)((*pts) - (*last))/90000.0);
	*pts = *last;
    }
    
 done:
    *last = *pts;
}

static enum ng_video_frame dropper(int drop)
{
    enum ng_video_frame seek = NG_FRAME_UNKNOWN;

    if (drop > 12) {
	if (ng_debug)
	    fprintf(stderr,"mpeg: seeking to next I frame\n");
	seek = NG_FRAME_I_FRAME;
    } else if (drop > 3) {
	if (ng_debug)
	    fprintf(stderr,"mpeg: seeking to next P frame\n");
	seek = NG_FRAME_P_FRAME;
    }
    return seek;
}

static int skip(enum ng_video_frame seek, enum ng_video_frame curr)
{
    int skip = 0;

    switch (seek) {
    case NG_FRAME_I_FRAME:
	if (curr != NG_FRAME_I_FRAME)
	    skip = 1;
	break;
    case NG_FRAME_P_FRAME:
	if (curr == NG_FRAME_B_FRAME)
	    skip = 1;
	break;
    default:
	break;
    }

    if (skip && ng_debug > 1)
	fprintf(stderr,"mpeg:   -> skipping %s\n",
		mpeg_frame_s[curr]);
    return skip;
}

/* ----------------------------------------------------------------------- */

static struct ng_video_fmt* mpeg_vfmt(void *handle, int *vfmt, int vn)
{
    struct mpeg_handle *h = handle;

    return VIDEO_NONE != h->vfmt.fmtid ? &h->vfmt : NULL;
}

static struct ng_audio_fmt* mpeg_afmt(void *handle)
{
    struct mpeg_handle *h = handle;

    return AUDIO_NONE != h->afmt.fmtid ? &h->afmt : NULL;
}

static int64_t mpeg_frame_time(void *handle)
{
    struct mpeg_handle *h = handle;
    int n = 1, d = 1;

    switch (h->rate) {
    case 1: n = 24000; d = 1001; break;
    case 2: n = 24000; d = 1000; break;
    case 3: n = 25000; d = 1000; break;
    case 4: n = 30000; d = 1001; break;
    case 5: n = 30000; d = 1000; break;
    case 6: n = 50000; d = 1000; break;
    case 7: n = 60000; d = 1001; break;
    case 8: n = 60000; d = 1000; break;
    };
    return (int64_t)1000000000 * d / n;
}

static int mpeg_close(void *handle)
{
    struct mpeg_handle *h = handle;

    mpeg_fini(h);
    return 0;
}

/* ----------------------------------------------------------------------- */
/* program stream parser                                                   */

static void* mpeg_ps_open(char *moviename)
{
    struct mpeg_handle *h;
    unsigned char *buffer,*hdr;
    off_t  pos,off;
    size_t size;
    int aligned;

    h = mpeg_init();
    h->fd = open(moviename,O_RDONLY);
    if (-1 == h->fd) {
	fprintf(stderr,"open %s: %s\n",moviename,strerror(errno));
	goto fail;
    }
    fcntl(h->fd,F_SETFL,O_NONBLOCK);

    /* audio */
    pos  = 0;
    for (;;) {
	size = mpeg_find_ps_packet(h,0xc0,0xf0,&pos);
	if (!size)
	    break;
	off = mpeg_parse_pes_packet(h, mpeg_get_data(h,pos,32),
				    &h->audio_pts, &aligned);
	buffer = mpeg_get_data(h,pos+off,32);
	hdr = mpeg_find_audio_hdr(buffer,0,32);
	if (hdr) {
	    h->afmt.fmtid = AUDIO_MP3;
	    h->afmt.rate  = mpeg_get_audio_rate(hdr);
	    break;
	}
	pos += size;
    }

    /* video */
    pos  = 0;
    for (;;) {
	size = mpeg_find_ps_packet(h,0xe0,0xf0,&pos);
	if (!size)
	    break;
	off = mpeg_parse_pes_packet(h, mpeg_get_data(h,pos,32),
				    &h->video_pts, &aligned);
	buffer = mpeg_get_data(h,pos+off,32);
	if (0 == mpeg_get_video_fmt(h,buffer)) {
	    h->video_offset = pos;
	    break;
	}
	pos += size;
    }

    /* init video fifo */
    h->vbuf = ng_malloc_video_buf(NULL, &h->vfmt);
    h->vbuf->info.ratio = h->ratio;
    h->vbuf->size = 0;
    INIT_LIST_HEAD(&h->vfifo);

    h->init = 0;
    return h;
    
 fail:
    mpeg_fini(h);
    return NULL;
}

static struct ng_video_buf* mpeg_ps_vdata(void *handle, unsigned int *drop)
{
    struct mpeg_handle *h = handle;
    struct ng_video_fifo *fifo;
    struct ng_video_buf  *buf;
    unsigned char *data;
    size_t size, off;
    enum ng_video_frame seek = dropper(*drop);
    int aligned;

    for (;;) {
	if (!list_empty(&h->vfifo)) {
	    fifo = list_entry(h->vfifo.next, struct ng_video_fifo, next);
	    buf  = fifo->buf;
	    list_del(&fifo->next);
	    free(fifo);
	    if (skip(seek,buf->info.frame) ||
		buf->info.play_seq < 0) {
		*drop = 0;
		ng_release_video_buf(buf);
		continue;
	    }
	    buf->info.slowdown = h->slowdown;
	    h->slowdown = 0;
	    return buf;
	}
	size = mpeg_find_ps_packet(h,0xe0,0xf0,&h->video_offset);
	if (0 == size)
	    return NULL;
	off = mpeg_parse_pes_packet(h, mpeg_get_data(h,h->video_offset,32),
				    &h->video_pts, &aligned);
	data = mpeg_get_data(h,h->video_offset+off,size-off);
	if (NULL == data)
	    return NULL;
	mpeg_check_video_fmt(h, data);
	put_video(h,data,size-off);
	h->video_offset += size;
    }
}

static struct ng_audio_buf* mpeg_ps_adata(void *handle)
{
    struct mpeg_handle *h = handle;
    struct ng_audio_buf *buf = NULL;
    unsigned char *data;
    size_t size, off;
    int aligned;

    size = mpeg_find_ps_packet(h,0xc0,0xf0,&h->audio_offset);
    if (0 == size)
	return NULL;
    off = mpeg_parse_pes_packet(h, mpeg_get_data(h,h->audio_offset,32),
				&h->audio_pts, &aligned);
    buf = ng_malloc_audio_buf(&h->afmt,size-off);
    buf->size = size-off;
    data = mpeg_get_data(h,h->audio_offset+off,buf->size);
    if (NULL == data) {
	free(buf);
	return NULL;
    }
    memcpy(buf->data,data,buf->size);

    if (ng_debug > 1)
	fprintf(stderr,"mpeg: audio packet at 0x%08" PRIx64
		" / size 0x%" PRIx64 " / off 0x%" PRIx64 "\n",
		(int64_t)h->audio_offset,(int64_t)size,(int64_t)off);
    
    buf->info.ts = h->audio_pts * (uint64_t)1000000 / (uint64_t)90;
    h->audio_offset += size;
    buf->info.slowdown = h->slowdown;
    h->slowdown = 0;
    return buf;
}

/* ----------------------------------------------------------------------- */
/* transport stream parser                                                 */

static void* mpeg_ts_open(char *moviename)
{
    struct mpeg_handle *h;
    off_t pos, off;
    int aligned;

    h = mpeg_init();
    h->fd = open(moviename,O_RDONLY);
    if (-1 == h->fd) {
	fprintf(stderr,"open %s: %s\n",moviename,strerror(errno));
	goto fail;
    }
    fcntl(h->fd,F_SETFL,O_NONBLOCK);

    if (0 == ng_mpeg_vpid  &&  0 == ng_mpeg_apid) {
	/* no pids given => pick any ... */
	struct psi_info *info;
	info = psi_info_alloc();
	pos = 0;
	if (-1 == mpeg_find_ts_packet(h, 0x0000, &pos)) {
	    fprintf(stderr,"mpeg ts: no pids given and no PAT found\n");
	    goto fail;
	}
	mpeg_parse_psi(info,h,1);
	
	/* program map */
	if (NULL == info->pr || !info->pr->pnr) {
	    fprintf(stderr,"mpeg ts: no pids given and no PAT found\n");
	    goto fail;
	}
	pos = 0;
	if (-1 == mpeg_find_ts_packet(h, info->pr->p_pid, &pos)) {
	    fprintf(stderr,"mpeg ts: no PMT found for pid=%d\n",h->p_pid);
	    goto fail;
	}
	mpeg_parse_psi(info,h,1);
	h->a_pid = info->pr->a_pid;
	h->v_pid = info->pr->v_pid;
	psi_info_free(info);
    } else {
	/* pids given ...  */
	h->a_pid = ng_mpeg_apid;
	h->v_pid = ng_mpeg_vpid;
    }

    /* audio */
    if (h->a_pid) {
	pos = 0;
	aligned = 1;
	for (;;pos += TS_SIZE) {
	    if (-1 == mpeg_find_ts_packet(h, h->a_pid, &pos)) {
		fprintf(stderr,"mpeg: no ts packet [audio,pid=%d] found\n",
			h->a_pid);
		goto fail;
	    }
	    if (!h->ts.payload)
		continue;
	    if (0 == h->ts.size)
		continue;

	    if (h->errors > ERROR_LIMIT) {
		fprintf(stderr,"mpeg: insane amount of stream errors, drop out\n");
		h->error_out = 1;
		goto fail;
	    }
	    if (h->ts.tei) {
		if (ng_log_bad_stream)
		    fprintf(stderr,"mpeg ts: warning %d: video: tei "
			    "(error flag) set\n",h->errors);
		h->errors++;
		continue;
	    }
	    
	    h->audio_offset = pos;
	    if (h->init_offset < pos)
		h->init_offset = pos;
	    off = mpeg_parse_pes_packet(h,h->ts.data, &h->audio_pts, &aligned);
	    if (aligned) {
		// easy ;)
		h->afmt.fmtid = AUDIO_MP3;
		h->afmt.rate  = mpeg_get_audio_rate(h->ts.data+off);
	    } else {
		// must search for mpeg audio header
		char *hdr;
		hdr = mpeg_find_audio_hdr(h->ts.data, off, h->ts.size);
		if (NULL == hdr)
		    continue;
		h->afmt.fmtid = AUDIO_MP3;
		h->afmt.rate  = mpeg_get_audio_rate(hdr);
		if (ng_debug)
		    fprintf(stderr,"mpeg ts: unaligned audio\n");
	    }
	    break;
	}
    }

    /* video */
    if (h->v_pid) {
	pos = 0;
	for (;;pos += TS_SIZE) {
	    if (-1 == mpeg_find_ts_packet(h, h->v_pid, &pos)) {
		fprintf(stderr,"mpeg: no ts packet [video,pid=%d] found\n",
			h->v_pid);
		goto fail;
	    }
	    if (!h->ts.payload)
		continue;
	    if (0 == h->ts.size)
		continue;

	    if (h->errors > ERROR_LIMIT) {
		fprintf(stderr,"mpeg: insane amount of stream errors, drop out\n");
		h->error_out = 1;
		goto fail;
	    }
	    if (h->ts.tei) {
		if (ng_log_bad_stream)
		    fprintf(stderr,"mpeg ts: warning %d: video: tei "
			    "(error flag) set\n",h->errors);
		h->errors++;
		continue;
	    }

	    h->video_offset = pos;
	    if (h->init_offset < pos)
		h->init_offset = pos;
	    off = mpeg_parse_pes_packet(h,h->ts.data, &h->video_pts, &aligned);
	    if (aligned) {
		mpeg_get_video_fmt(h, h->ts.data+off);
	    } else {
		// must search for header
		char *hdr = NULL;

		hdr = memmem(h->ts.data+off,     h->ts.size-off,
			     "\x00\x00\x01\xb3", 4);
		if (hdr) {
		    mpeg_get_video_fmt(h, hdr);
		    if (ng_debug)
			fprintf(stderr,"mpeg ts: unaligned video\n");
		}
	    }
	    if (VIDEO_NONE != h->vfmt.fmtid)
		break;
	}
    }

    /* init video fifo */
    h->vbuf = ng_malloc_video_buf(NULL, &h->vfmt);
    h->vbuf->info.ratio = h->ratio;
    h->vbuf->size = 0;
    INIT_LIST_HEAD(&h->vfifo);

    h->init = 0;
    return h;
    
 fail:
    mpeg_fini(h);
    return NULL;
}

static struct ng_video_buf* mpeg_ts_vdata(void *handle, unsigned int *drop)
{
    struct mpeg_handle *h = handle;
    struct ng_video_fifo *fifo;
    struct ng_video_buf  *buf;
    int aligned;
    int cont,errors;
    off_t off;
    enum ng_video_frame seek = dropper(*drop);

    if (h->error_out)
	return NULL;
    errors = h->errors;

    for (;;) {
	if (!list_empty(&h->vfifo)) {
	    fifo = list_entry(h->vfifo.next, struct ng_video_fifo, next);
	    buf  = fifo->buf;
	    list_del(&fifo->next);
	    free(fifo);
	    if (skip(seek,buf->info.frame) ||
		buf->info.play_seq < 0) {
		*drop = 0;
		ng_release_video_buf(buf);
		continue;
	    }
	    buf->info.slowdown = h->slowdown;
	    h->slowdown = 0;
	    return buf;
	}

	if (-1 == mpeg_find_ts_packet(h, h->v_pid, &h->video_offset))
	    return NULL;
	if (!h->ts.payload || 0 == h->ts.size) {
	    h->video_offset += TS_SIZE;
	    continue;
	}
	cont = h->ts.cont;
	off = mpeg_parse_pes_packet(h,h->ts.data, &h->video_pts, &aligned);
	check_pts("video", &h->video_pts, &h->video_pts_last);
	if (off > h->ts.size) {
	    if (ng_log_bad_stream)
		fprintf(stderr,"mpeg ts: warning %d: broken pes offset [%lx]\n",
			h->errors,(unsigned long)h->video_offset);
	    h->video_offset += TS_SIZE;
	    h->errors++;
	    continue;
	}
	mpeg_check_video_fmt(h, h->ts.data+off);
	put_video(h,h->ts.data+off,h->ts.size-off);
	h->video_offset += TS_SIZE;

	for (;;h->video_offset += TS_SIZE) {
	    if (-1 == mpeg_find_ts_packet(h, h->v_pid, &h->video_offset))
		return NULL;
	    if (h->ts.payload)
		break;
	    if (0 == h->ts.size)
		continue;

	    if (h->errors - errors > ERROR_LIMIT) {
		fprintf(stderr,"mpeg: insane amount of stream errors, drop out\n");
		h->error_out = 1;
		return NULL;
	    }
	    if (h->ts.tei) {
		if (ng_log_bad_stream)
		    fprintf(stderr,"mpeg ts: warning %d: video: tei "
			    "(error flag) set\n",h->errors);
		h->errors++;
		if (h->vbuf)
		    h->vbuf->info.broken++;
	    }

	    if ((cont+1)%16 != h->ts.cont) {
		if (ng_log_bad_stream)
		    fprintf(stderr,"mpeg ts: warning %d: video: cont mismatch, "
			    "pkg dropped? [%d+1 != %d]\n",
			    h->errors, cont, h->ts.cont);
		h->errors++;
		if (h->vbuf)
		    h->vbuf->info.broken++;
	    }
	    cont = h->ts.cont;
	    put_video(h,h->ts.data,h->ts.size);
	}
    }
    return NULL;
}

static struct ng_audio_buf* mpeg_ts_adata(void *handle)
{
    struct mpeg_handle *h = handle;
    struct ng_audio_buf *buf = NULL;
    unsigned char *data;
    int aligned;
    size_t size;
    off_t off;
    int cont,errors;

    if (h->error_out)
	return NULL;
    errors = h->errors;

    buf = ng_malloc_audio_buf(&h->afmt, TS_AUDIO_BUF);
    buf->size = 0;

 again:
    if (-1 == mpeg_find_ts_packet(h, h->a_pid, &h->audio_offset)) {
	free(buf);
	return NULL;
    }
    if (!h->ts.payload || 0 == h->ts.size) {
	h->audio_offset += TS_SIZE;
	goto again;
    }

    cont = h->ts.cont;
    off  = mpeg_parse_pes_packet(h,h->ts.data, &h->audio_pts, &aligned);
    check_pts("audio", &h->audio_pts, &h->audio_pts_last);
    if (off > h->ts.size) {
	if (ng_log_bad_stream)
	    fprintf(stderr,"mpeg ts: warning %d: broken pes offset [%lx]\n",
		    h->errors,(unsigned long)h->audio_offset);
	h->audio_offset += TS_SIZE;
	h->errors++;
	goto again;
    }
    if (!aligned) {
	unsigned char *hdr;
	hdr  = memchr(h->ts.data+off, 0xff, h->ts.size-off);
	if (hdr)
	    off = hdr - h->ts.data;
    }
    data = h->ts.data+off;
    size = h->ts.size-off;
    memcpy(buf->data + buf->size, data, size);
    buf->size += size;
    h->audio_offset += TS_SIZE;

    for (;;h->audio_offset += TS_SIZE) {
	if (-1 == mpeg_find_ts_packet(h, h->a_pid, &h->audio_offset)) {
	    free(buf);
	    return NULL;
	}
	if (0 == h->ts.size)
	    continue;
	if (h->ts.payload) {
	    unsigned char *hdr;
	    off  = mpeg_parse_pes_packet(h,h->ts.data, &h->audio_pts, &aligned);
	    check_pts("audio", &h->audio_pts, &h->audio_pts_last);
	    if (aligned)
		break;
	    hdr = memchr(h->ts.data+off, 0xff, h->ts.size-off);
	    if (hdr) {
		data = h->ts.data+off;
		size = hdr - (h->ts.data+off);
		memcpy(buf->data + buf->size, data, size);
		buf->size += size;
	    }
	    break;
	}

	if (h->errors - errors > ERROR_LIMIT) {
	    fprintf(stderr,"mpeg: insane amount of stream errors, drop out\n");
	    h->error_out = 1;
	    return NULL;
	}
	if (h->ts.tei) {
	    if (ng_log_bad_stream)
		fprintf(stderr,"mpeg ts: warning %d: audio: tei (error flag) set\n",
			h->errors);
	    h->errors++;
	    buf->info.broken++;
	}

	if ((cont+1)%16 != h->ts.cont) {
	    if (ng_log_bad_stream)
		fprintf(stderr,"mpeg ts: warning %d: audio: cont mismatch, "
			"pkg dropped? [%d+1 != %d]\n",
			h->errors,cont, h->ts.cont);
	    h->errors++;
	    buf->info.broken++;
	}
	cont = h->ts.cont;

	off  = 0;
	data = h->ts.data+off;
	size = h->ts.size-off;
	if (buf->size + size > TS_AUDIO_BUF) {
	    fprintf(stderr,"ts: TS_AUDIO_BUF too small (%ld > %d)\n",
		    buf->size + size, TS_AUDIO_BUF);
	    exit(1);
	}
	memcpy(buf->data + buf->size, data, size);
	buf->size += size;
    }

#if 0
    fprintf(stderr,"mpeg audio size=%d pts=%ld [%ld]\n",
	    buf->size,h->audio_pts,h->start_pts);
    hexdump(NULL, buf->data, buf->size);
    fprintf(stderr,"--\n");
#endif
    
    buf->info.ts = h->audio_pts * (uint64_t)1000000 / (uint64_t)90;
    buf->info.slowdown = h->slowdown;
    h->slowdown = 0;
    return buf;
}

/* ----------------------------------------------------------------------- */
/* simple mpeg audio files                                                 */

struct mp3_handle {
    int                  fd;
    struct ng_video_fmt  vfmt;
    struct ng_audio_fmt  afmt;
};

static void* mp3_open(char *filename)
{
    struct mp3_handle *h;
    unsigned char header[16];
    unsigned int id3;
    
    if (NULL == (h = malloc(sizeof(*h))))
	return NULL;
    memset(h,0,sizeof(*h));

    /* open file */
    h->fd = open(filename,O_RDONLY);
    if (-1 == h->fd) {
	fprintf(stderr,"open %s: %s\n",filename,strerror(errno));
	free(h);
	return NULL;
    }
    read(h->fd,header,sizeof(header));
    lseek(h->fd,0,SEEK_SET);

    if (0 == strncmp(header, "ID3", 3)) {
	/* skip ID3 tag */
	id3  = header[9];
	id3 |= (unsigned int)header[8] << 7;
	id3 |= (unsigned int)header[7] << 14;
	id3 |= (unsigned int)header[6] << 21;
	id3 += 10;
	if (ng_debug)
	    fprintf(stderr,"mpeg: skip ID3v2 tag [size=0x%x]\n",id3);
	lseek(h->fd,id3,SEEK_SET);
	read(h->fd,header,sizeof(header));
	lseek(h->fd,id3,SEEK_SET);
	if (0xff != header[0]) {
	    fprintf(stderr,"mpeg: no mpeg header after ID3v2 tag\n");
	    free(h);
	    return NULL;
	}
    }

    h->afmt.fmtid = AUDIO_MP3;
    h->afmt.rate  = mpeg_get_audio_rate(header);

    return h;
}

static struct ng_video_fmt* mp3_vfmt(void *handle, int *vfmt, int vn)
{
    struct mp3_handle *h = handle;
    return &h->vfmt;
}

static struct ng_audio_fmt* mp3_afmt(void *handle)
{
    struct mp3_handle *h = handle;
    return &h->afmt;
}

static struct ng_audio_buf* mp3_adata(void *handle)
{
    struct mp3_handle *h = handle;
    struct ng_audio_buf *buf;
    
    buf = ng_malloc_audio_buf(&h->afmt, MP3_AUDIO_BUF);
    buf->size = read(h->fd,buf->data, MP3_AUDIO_BUF);
    if (buf->size <= 0) {
	free(buf);
	return NULL;
    }
    return buf;
}

static int mp3_close(void *handle)
{
    struct mp3_handle *h = handle;

    close(h->fd);
    free(h);
    return 0;
}

/* ----------------------------------------------------------------------- */

struct ng_reader mpeg_ps_reader = {
    .name       = "mpeg-ps",
    .desc       = "MPEG1/2 program stream",

    .magic	= { "\x00\x00\x01\xba" },
    .moff       = {  0                 },
    .mlen       = {  4                 },
    
    .rd_open    = mpeg_ps_open,
    .rd_vfmt    = mpeg_vfmt,
    .rd_afmt    = mpeg_afmt,
    .rd_vdata   = mpeg_ps_vdata,
    .rd_adata   = mpeg_ps_adata,
    .frame_time = mpeg_frame_time,
    .rd_close   = mpeg_close,
};

struct ng_reader mpeg_ts_reader = {
    .name       = "mpeg-ts",
    .desc       = "MPEG1/2 transport stream",

    .magic	= { "\x47" },
    .moff       = {  0     },
    .mlen       = {  1     },
    
    .rd_open    = mpeg_ts_open,
    .rd_vfmt    = mpeg_vfmt,
    .rd_afmt    = mpeg_afmt,
    .rd_vdata   = mpeg_ts_vdata,
    .rd_adata   = mpeg_ts_adata,
    .frame_time = mpeg_frame_time,
    .rd_close   = mpeg_close,
};

struct ng_reader mp3_reader = {
    .name       = "mp3",
    .desc       = "MPEG audio (layer iii)",

    /*              mpg1-l3     mpg2-l3                 mpg2-l3     with td3 tag */
    .magic	= { "\xff\xfa", "\xff\xfb", "\xff\xfc", "\xff\xf3", "ID3" },
    .moff       = { 0,          0,          0,          0,          0     },
    .mlen       = { 2,          2,          2,          2,          3     },
    
    .rd_open    = mp3_open,
    .rd_vfmt    = mp3_vfmt,
    .rd_afmt    = mp3_afmt,
    .rd_adata   = mp3_adata,
    .rd_close   = mp3_close,
};

static void __init plugin_init(void)
{
    ng_reader_register(NG_PLUGIN_MAGIC,__FILE__,&mpeg_ps_reader);
    ng_reader_register(NG_PLUGIN_MAGIC,__FILE__,&mpeg_ts_reader);
    ng_reader_register(NG_PLUGIN_MAGIC,__FILE__,&mp3_reader);
}
