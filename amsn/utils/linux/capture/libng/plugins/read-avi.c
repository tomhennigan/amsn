#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <inttypes.h>
#include <sys/uio.h>

#include "riff.h"
#include "grab-ng.h"

/* ----------------------------------------------------------------------- */

struct movi_range {
    off_t start;
    off_t size;
};

struct avi_handle {
    int                   fd;
    struct iovec          *vec;

    /* avi header */
    unsigned char         riff_type[4];
    unsigned char         fcc_type[4];
    struct RIFF_avih      avih;
    struct RIFF_strh      v_strh;
    struct RIFF_strh      a_strh;
    struct RIFF_strf_vids vids;
    struct RIFF_strf_auds auds;
    int32_t               dml_frames;
    struct movi_range     *movi;
    int                   movi_cnt;
    struct movi_range     wave;

    /* libng stuff */
    struct ng_video_fmt   vfmt;
    struct ng_audio_fmt   afmt;

    /* status data */
    off_t                 a_pos;
    off_t                 v_pos;
    int                   frames;
    off_t                 a_bytes;
};

/* ----------------------------------------------------------------------- */

#define FCC(a,b,c,d) (((uint32_t)a << 24) |\
		      ((uint32_t)b << 16) |\
		      ((uint32_t)c << 8)  |\
		      (uint32_t)d)
#define FCCS(str) FCC(str[0],str[1],str[2],str[3])

static void avi_add_movi(struct avi_handle *h,  int level,
			off_t start, off_t size)
{
    if (0 == h->movi_cnt % 16)
	h->movi = realloc(h->movi,sizeof(struct movi_range)*(h->movi_cnt+16));
    h->movi[h->movi_cnt].start = start;
    h->movi[h->movi_cnt].size  = size;
    h->movi_cnt++;
    if (ng_debug)
	fprintf(stderr,"%*s[movie data list: 0x%" PRIx64 "+0x%" PRIx64 "]\n",
		level, "", (int64_t)start, (int64_t)size);
}

static void avi_swap_strh(struct RIFF_strh *strh)
{
    strh->flags       = AVI_SWAP4(strh->flags);
    strh->priority    = AVI_SWAP4(strh->priority);
    strh->init_frames = AVI_SWAP4(strh->init_frames);
    strh->scale       = AVI_SWAP4(strh->scale);
    strh->rate        = AVI_SWAP4(strh->rate);
    strh->start       = AVI_SWAP4(strh->start);
    strh->length      = AVI_SWAP4(strh->length);
    strh->bufsize     = AVI_SWAP4(strh->bufsize);
    strh->quality     = AVI_SWAP4(strh->quality);
    strh->samplesize  = AVI_SWAP4(strh->samplesize);
}

static void avi_swap_vids(struct RIFF_strf_vids *fmt)
{
    fmt->size        = AVI_SWAP4(fmt->size);
    fmt->width       = AVI_SWAP4(fmt->width);
    fmt->height      = AVI_SWAP4(fmt->height);
    fmt->planes      = AVI_SWAP2(fmt->planes);
    fmt->bit_cnt     = AVI_SWAP2(fmt->bit_cnt);
    fmt->image_size  = AVI_SWAP4(fmt->image_size);
    fmt->xpels_meter = AVI_SWAP4(fmt->xpels_meter);
    fmt->ypels_meter = AVI_SWAP4(fmt->ypels_meter);
    fmt->num_colors  = AVI_SWAP4(fmt->num_colors);
    fmt->imp_colors  = AVI_SWAP4(fmt->imp_colors);
}

static void avi_swap_auds(struct RIFF_strf_auds *fmt)
{
    fmt->format     = AVI_SWAP2(fmt->format);
    fmt->channels   = AVI_SWAP2(fmt->channels);
    fmt->rate       = AVI_SWAP4(fmt->rate);
    fmt->av_bps     = AVI_SWAP4(fmt->av_bps);
    fmt->blockalign = AVI_SWAP2(fmt->blockalign);
    fmt->size       = AVI_SWAP2(fmt->size);
}

static int avi_parse_header(struct avi_handle *h, off_t offset, int level)
{
    struct CHUNK_HDR chunk;
    struct RIFF_strh strh;
    unsigned char id[4];
    off_t pos = offset;

    lseek(h->fd,offset,SEEK_SET);
    pos += read(h->fd,&chunk,sizeof(chunk));
    chunk.size = AVI_SWAP4(chunk.size);
    if (ng_debug)
	fprintf(stderr,"%*s%4.4s <0x%x>\n",level,"",chunk.id,chunk.size);
    switch (FCCS(chunk.id)) {
    case FCC('R','I','F','F'):
    case FCC('L','I','S','T'):
	pos += read(h->fd,&id,sizeof(id));
	if (FCCS(chunk.id) == FCC('R','I','F','F'))
	    memcpy(h->riff_type,id,4);
	if (ng_debug)
	    fprintf(stderr,"%*s[list type is %4.4s]\n",level,"",id);
	if (FCCS(id) == FCC('m','o','v','i')) {
	    avi_add_movi(h,level,pos,chunk.size-4);
	} else {
	    while (pos < offset + chunk.size)
		pos += avi_parse_header(h,pos,level+3);
	}
	break;
    case FCC('a','v','i','h'):
	read(h->fd,&h->avih,sizeof(h->avih));
	break;
    case FCC('s','t','r','h'):
	read(h->fd,&strh,sizeof(strh));
	memcpy(h->fcc_type,strh.type,sizeof(h->fcc_type));
	if (ng_debug)
	    fprintf(stderr,"%*s[header type is %4.4s]\n",level,"",h->fcc_type);
	avi_swap_strh(&strh);
	if (FCCS(h->fcc_type) == FCC('a','u','d','s'))
	    h->a_strh = strh;
	if (FCCS(h->fcc_type) == FCC('v','i','d','s'))
	    h->v_strh = strh;
	break;
    case FCC('s','t','r','f'):
	if (FCCS(h->fcc_type) == FCC('a','u','d','s')) {
	    read(h->fd,&h->auds,sizeof(h->auds));
	    avi_swap_auds(&h->auds);
	}
	if (FCCS(h->fcc_type) == FCC('v','i','d','s')) {
	    read(h->fd,&h->vids,sizeof(h->vids));
	    avi_swap_vids(&h->vids);
	}
	break;
    case FCC('d','m','l','h'):
	read(h->fd,&h->dml_frames,sizeof(h->dml_frames));
	h->dml_frames = AVI_SWAP4(h->dml_frames);
	break;
    case FCC('f','m','t',' '):
	if (FCCS(h->riff_type) == FCC('W','A','V','E')) {
	    read(h->fd,&h->auds,sizeof(h->auds));
	    avi_swap_auds(&h->auds);
	}
	break;
    case FCC('d','a','t','a'):
	if (FCCS(h->riff_type) == FCC('W','A','V','E')) {
	    h->wave.start = pos;
	    h->wave.size  = chunk.size-4;
	}
	break;
    }
    return chunk.size+8;
}

static uint32_t avi_find_chunk(struct avi_handle *h, uint32_t id, off_t *pos)
{
    struct CHUNK_HDR chunk;
    int n = 0, bytes;

    if (NULL == h->movi) {
	/* WAVE */
	if (*pos >= h->wave.start + h->wave.size)
	    return 0;
	lseek(h->fd,*pos,SEEK_SET);
	bytes = h->wave.start + h->wave.size - *pos;
	if (bytes > 64*1024)
	    bytes = 64*1024;
	*pos += bytes;
	return bytes;
    }

    /* AVI + AVIX */
    while (*pos >= h->movi[n].start + h->movi[n].size) {
	n++;
	if (n >= h->movi_cnt)
	    return 0;
    }
    for (;;) {
        if (*pos >= h->movi[n].start + h->movi[n].size) {
	    n++;
	    if (n >= h->movi_cnt)
		return 0;
	    *pos = h->movi[n].start;
	}
	lseek(h->fd,*pos,SEEK_SET);
	*pos += read(h->fd,&chunk,sizeof(chunk));
	chunk.size = AVI_SWAP4(chunk.size);
	chunk.size = (chunk.size + 1) & ~0x01; /* 16-bit align */
	*pos += chunk.size;
	if (FCCS(chunk.id) == id) {
	    if (ng_debug)
		fprintf(stderr,"avi: chunk %4.4s: 0x%" PRIx64 "+0x%x\n",
			chunk.id,(uint64_t)(*pos),chunk.size);
	    return chunk.size;
	}
    }
}

/* ----------------------------------------------------------------------- */

static void* avi_open(char *moviename)
{
    struct avi_handle *h;
    off_t pos, size;

    h = malloc(sizeof(*h));
    memset(h,0,sizeof(*h));
    h->fd = -1;

    h->fd = open(moviename,O_RDONLY);
    if (-1 == h->fd) {
	fprintf(stderr,"open %s: %s\n",moviename,strerror(errno));
	goto fail;
    }

    size = lseek(h->fd,0,SEEK_END);
    for (pos = 0; pos < size;)
	pos += avi_parse_header(h,pos,0);
    
    if (h->movi) {
	h->a_pos = h->movi[0].start;
	h->v_pos = h->movi[0].start;
    } else if (h->wave.start) {
	h->a_pos = h->wave.start;
    }
    
    /* audio stream ?? */
    if (FCCS(h->a_strh.type) == FCC('a','u','d','s') ||
	FCCS(h->riff_type) == FCC('W','A','V','E')) {
	switch (h->auds.format) {
	case WAVE_FORMAT_PCM:
	    if (h->auds.size == 8)
		h->afmt.fmtid = AUDIO_U8_MONO;
	    if (h->auds.size == 16)
		h->afmt.fmtid = AUDIO_S16_LE_MONO;
	    if (h->afmt.fmtid) {
		if (h->auds.channels > 1)
		    h->afmt.fmtid++; /* mono => stereo */
		h->afmt.rate = h->auds.rate;
	    }
	    break;
	case WAVE_FORMAT_MP3:
	    h->afmt.fmtid = AUDIO_MP3;
	    h->afmt.rate  = h->auds.rate;
	    break;
	}
	if (ng_debug) {
	    if (h->afmt.fmtid != AUDIO_NONE)
		fprintf(stderr,"avi: audio is %s @ %d Hz\n",
			ng_afmt_to_desc[h->afmt.fmtid],h->afmt.rate);
	    else
		fprintf(stderr,"avi: can't handle audio stream\n");
	}
    }

    /* video stream ?? */
    if (FCCS(h->v_strh.type) == FCC('v','i','d','s')) {
	switch (FCCS(h->v_strh.handler)) {
	case 0:
	    if (h->vids.bit_cnt == 15)
		h->vfmt.fmtid = VIDEO_RGB15_LE;
	    if (h->vids.bit_cnt == 24)
		h->vfmt.fmtid = VIDEO_BGR24;
	    break;
	case FCC('M','J','P','G'):
//	case FCC('m','j','p','g'):
	    h->vfmt.fmtid = VIDEO_MJPEG;
	    break;
	}
	if (VIDEO_NONE != h->vfmt.fmtid) {
	    h->vfmt.width  = h->vids.width;
	    h->vfmt.height = h->vids.height;
	    h->vfmt.bytesperline = (h->vfmt.width*ng_vfmt_to_depth[h->vfmt.fmtid]) >> 3;
	    h->vec = malloc(sizeof(struct iovec) * h->vfmt.height);
	    if (ng_debug)
		fprintf(stderr,"avi: video is %s, %dx%d @ %d fps\n",
			ng_vfmt_to_desc[h->vfmt.fmtid],
			h->vfmt.width, h->vfmt.height,
			(int)((long long) 1000000 / h->avih.us_frame));
	} else {
	    if (ng_debug)
		fprintf(stderr,"avi: can't handle video stream\n");
	}
    }
    return h;
    
 fail:
    if (-1 != h->fd)
	close(h->fd);
    free(h);
    return NULL;
}

static struct ng_video_fmt* avi_vfmt(void *handle, int *vfmt, int vn)
{
    struct avi_handle *h = handle;

    return &h->vfmt;
}

static struct ng_audio_fmt* avi_afmt(void *handle)
{
    struct avi_handle *h = handle;

    return AUDIO_NONE != h->afmt.fmtid ? &h->afmt : NULL;
}

static struct ng_video_buf* avi_vdata(void *handle, unsigned int *drop)
{
    struct avi_handle *h = handle;
    struct ng_video_buf *buf;
    struct iovec *line;
    uint32_t size;
    unsigned int y;

    /* drop frames */
    while (*drop) {
	if (0 == avi_find_chunk(h,FCC('0','0','d','b'),&h->v_pos))
	    return NULL;
	h->frames++;
	(*drop)--;
    }

    size = avi_find_chunk(h,FCC('0','0','d','b'),&h->v_pos);
    if (0 == size)
	return NULL;
    buf = ng_malloc_video_buf(NULL, &h->vfmt);
    switch (h->vfmt.fmtid) {
    case VIDEO_RGB15_LE:
    case VIDEO_BGR24:
	for (line = h->vec, y = h->vfmt.height-1; y >= 0; line++, y--) {
	    line->iov_base = ((unsigned char*)buf->data) +
		y * h->vfmt.bytesperline;
	    line->iov_len = h->vfmt.bytesperline;
	}
	readv(h->fd,h->vec,h->vfmt.height);
	break;
    case VIDEO_MJPEG:
    case VIDEO_JPEG:
	read(h->fd,buf->data,size);
	break;
    }
    buf->info.file_seq = h->frames;
    buf->info.play_seq = h->frames;
    buf->info.ts       = (long long)h->frames * h->avih.us_frame * 1000;
    h->frames++;
    return buf;
}

static struct ng_audio_buf* avi_adata(void *handle)
{
    struct avi_handle *h = handle;
    struct ng_audio_buf *buf;
    uint32_t size, samples;

    size = avi_find_chunk(h,FCC('0','1','w','b'),&h->a_pos);
    if (0 == size)
	return NULL;
    buf = ng_malloc_audio_buf(&h->afmt,size);
    read(h->fd,buf->data,size);
    if (ng_afmt_to_bits[h->afmt.fmtid]) {
	samples = h->a_bytes * 8
	    / ng_afmt_to_channels[h->afmt.fmtid]
	    / ng_afmt_to_bits[h->afmt.fmtid];
	buf->info.ts = (long long)samples * 1000000000 / h->afmt.rate;
    } else {
	/* FIXME */
    }
    h->a_bytes += size;
    return buf;
}

static int64_t avi_frame_time(void *handle)
{
    struct avi_handle *h = handle;

    return h->avih.us_frame * 1000;
}

static int avi_close(void *handle)
{
    struct avi_handle *h = handle;

    if (h->vec)
	free(h->vec);
    close(h->fd);
    free(h);
    return 0;
}

/* ----------------------------------------------------------------------- */

struct ng_reader avi_reader = {
    .name       = "avi",
    .desc       = "Microsoft AVI (RIFF) format",

    .magic	= { "RIFF" },
    .moff       = {  0     },
    .mlen       = {  4     },
    
    .rd_open    = avi_open,
    .rd_vfmt    = avi_vfmt,
    .rd_afmt    = avi_afmt,
    .rd_vdata   = avi_vdata,
    .rd_adata   = avi_adata,
    .frame_time = avi_frame_time,
    .rd_close   = avi_close,
};

static void __init plugin_init(void)
{
    ng_reader_register(NG_PLUGIN_MAGIC,__FILE__,&avi_reader);
}
