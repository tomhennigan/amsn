/*
 * parse mpeg program + transport streams.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <iconv.h>
#include <inttypes.h>

#include "grab-ng.h"
#include "parse-mpeg.h"

#define FILE_BUF_MIN       (512*1024)
#define FILE_BUF_MAX    (8*1024*1024)
#define FILE_BLKSIZE        (16*1024)

#ifndef PRId64
# warning Hmm, your C99 support is incomplete, will guess (should be ok for 32bit archs)
# define PRId64 "lld"
# define PRIx64 "llx"
# define PRIu64 "llu"
#endif

int  ng_mpeg_vpid    = 0;
int  ng_mpeg_apid    = 0;
int  ng_read_timeout = 3; /* seconds */

/* ----------------------------------------------------------------------- */
/* static data                                                             */

int mpeg_rate_n[16] = {
    [ 1 ] = 24000,
    [ 2 ] = 24000,
    [ 3 ] = 25000,
    [ 4 ] = 30000,
    [ 5 ] = 30000,
    [ 6 ] = 50000,
    [ 7 ] = 60000,
    [ 8 ] = 60000,
};

int mpeg_rate_d[16] = {
    [ 1 ] = 1001,
    [ 2 ] = 1000,
    [ 3 ] = 1000,
    [ 4 ] = 1001,
    [ 5 ] = 1000,
    [ 6 ] = 1000,
    [ 7 ] = 1001,
    [ 8 ] = 1000,
};

static char *rate_s[16] = {
    [        0 ] = "illegal",
    [        1 ] = "24000/1001",
    [        2 ] = "24",
    [        3 ] = "25",
    [        4 ] = "30000/1001",
    [        5 ] = "30",
    [        6 ] = "50",
    [        7 ] = "60000/1001",
    [        8 ] = "60",
    [ 9 ... 15 ] = "reserved",
};

static char *ratio_s[] = {
    [        0 ] = "illegal",
    [        1 ] = "square sample",
    [        2 ] = "3:4",
    [        3 ] = "9:16",
    [        4 ] = "1:2,21",
    [ 5 ... 15 ] = "reserved",
};

const char *mpeg_frame_s[] = {
    [ NG_FRAME_UNKNOWN ] = "unknown",
    [ NG_FRAME_I_FRAME ] = "I frame",
    [ NG_FRAME_P_FRAME ] = "P frame",
    [ NG_FRAME_B_FRAME ] = "B frame",
};

static const char *pes_s[] = {
    [ 0x00 ... 0xff ] = "*UNKNOWN* stream",
    [ 0xbc          ] = "program stream map",
    [ 0xbd          ] = "private stream 1",
    [ 0xbe          ] = "padding stream",
    [ 0xbf          ] = "private stream 2",
    [ 0xc0 ... 0xdf ] = "audio stream",
    [ 0xe0 ... 0xef ] = "video stream",
    [ 0xf0          ] = "ECM stream",
    [ 0xf1          ] = "EMM stream",
    [ 0xf2          ] = "DSMCC stream",
    [ 0xf3          ] = "13522 stream",
    [ 0xf4          ] = "H.222.1 type A",
    [ 0xf5          ] = "H.222.1 type B",
    [ 0xf6          ] = "H.222.1 type C",
    [ 0xf7          ] = "H.222.1 type D",
    [ 0xf8          ] = "H.222.1 type E",
    [ 0xf9          ] = "ancillary stream",
    [ 0xfa ... 0xfe ] = "reserved data stream",
    [ 0xff          ] = "program stream directory",
};

static const char *stream_type_s[] = {
    [ 0x00          ] = "reserved",
    [ 0x01          ] = "ISO 11172     Video",
    [ 0x02          ] = "ISO 13818-2   Video",
    [ 0x03          ] = "ISO 11172     Audio",
    [ 0x04          ] = "ISO 13818-3   Audio",
    [ 0x05          ] = "ISO 13818-1   private sections",
    [ 0x06          ] = "ISO 13818-1   private data",
    [ 0x07          ] = "ISO 13522     MHEG",
    [ 0x08          ] = "ISO 13818-1   Annex A DSS CC",
    [ 0x09          ] = "ITU-T H.222.1",
    [ 0x0a          ] = "ISO 13818-6   type A",
    [ 0x0b          ] = "ISO 13818-6   type B",
    [ 0x0c          ] = "ISO 13818-6   type C",
    [ 0x0d          ] = "ISO 13818-6   type D",
    [ 0x0e          ] = "ISO 13818-6   auxiliary",
    [ 0x0f ... 0x7f ] = "reserved",
    [ 0x80 ... 0xff ] = "user private",
};

/* ----------------------------------------------------------------------- */

char *psi_charset[0x20] = {
    [ 0x00 ... 0x1f ] = "reserved",
    [ 0x00 ] = "ISO-8859-1",
    [ 0x01 ] = "ISO-8859-5",
    [ 0x02 ] = "ISO-8859-6",
    [ 0x03 ] = "ISO-8859-7",
    [ 0x04 ] = "ISO-8859-8",
    [ 0x05 ] = "ISO-8859-9",
    [ 0x06 ] = "ISO-8859-10",
    [ 0x07 ] = "ISO-8859-11",
    [ 0x08 ] = "ISO-8859-12",
    [ 0x09 ] = "ISO-8859-13",
    [ 0x0a ] = "ISO-8859-14",
    [ 0x0b ] = "ISO-8859-15",
    [ 0x10 ] = "fixme",
    [ 0x11 ] = "UCS-2BE",        // correct?
    [ 0x12 ] = "EUC-KR",
    [ 0x13 ] = "GB2312",
    [ 0x14 ] = "BIG5"
};

char *psi_service_type[0x100] = {
    [ 0x00 ... 0xff ] = "reserved",
    [ 0x80 ... 0xfe ] = "user defined",
    [ 0x01 ] = "digital television service",
    [ 0x02 ] = "digital radio sound service",
    [ 0x03 ] = "teletext service",
    [ 0x04 ] = "NVOD reference service",
    [ 0x05 ] = "NVOD time-shifted service",
    [ 0x06 ] = "mosaic service",
    [ 0x07 ] = "PAL coded signal",
    [ 0x08 ] = "SECAM coded signal",
    [ 0x09 ] = "D/D2-MAC",
    [ 0x0a ] = "FM Radio",
    [ 0x0b ] = "NTSC coded signal",
    [ 0x0c ] = "data broadcast service",
    [ 0x0d ] = "reserved for CI",
    [ 0x0e ] = "RCS Map",
    [ 0x0f ] = "RCS FLS",
    [ 0x10 ] = "DVB MHP service",
};

/* ----------------------------------------------------------------------- */
/* handle psi_ structs                                                     */

struct psi_info* psi_info_alloc(void)
{
    struct psi_info *info;

    info = malloc(sizeof(*info));
    memset(info,0,sizeof(*info));
    INIT_LIST_HEAD(&info->streams);
    INIT_LIST_HEAD(&info->programs);
    info->pat_version = PSI_NEW;
    info->sdt_version = PSI_NEW;
    info->nit_version = PSI_NEW;
    return info;
}

void psi_info_free(struct psi_info *info)
{
    struct psi_program *program;
    struct psi_stream  *stream;
    struct list_head   *item,*safe;

    list_for_each_safe(item,safe,&info->streams) {
	stream = list_entry(item, struct psi_stream, next);
	list_del(&stream->next);
	free(stream);
    }
    list_for_each_safe(item,safe,&info->programs) {
	program = list_entry(item, struct psi_program, next);
	list_del(&program->next);
	free(program);
    }
    free(info);
}

struct psi_stream* psi_stream_get(struct psi_info *info, int tsid, int alloc)
{
    struct psi_stream *stream;
    struct list_head  *item;

    list_for_each(item,&info->streams) {
        stream = list_entry(item, struct psi_stream, next);
	if (stream->tsid == tsid)
	    return stream;
    }
    if (!alloc)
	return NULL;
    stream = malloc(sizeof(*stream));
    memset(stream,0,sizeof(*stream));
    stream->tsid    = tsid;
    stream->updated = 1;
    list_add_tail(&stream->next,&info->streams);
    return stream;
}

struct psi_program* psi_program_get(struct psi_info *info, int tsid,
				    int pnr, int alloc)
{
    struct psi_program *program;
    struct list_head   *item;

    list_for_each(item,&info->programs) {
        program = list_entry(item, struct psi_program, next);
	if (program->tsid == tsid &&
	    program->pnr  == pnr)
	    return program;
    }
    if (!alloc)
	return NULL;
    program = malloc(sizeof(*program));
    memset(program,0,sizeof(*program));
    program->tsid    = tsid;
    program->pnr     = pnr;
    program->version = PSI_NEW;
    program->updated = 1;
    list_add_tail(&program->next,&info->programs);
    return program;
}

/* ----------------------------------------------------------------------- */
/* bit fiddeling                                                           */

unsigned int mpeg_getbits(unsigned char *buf, int start, int count)
{
    unsigned int result = 0;
    unsigned char bit;

    while (count) {
	result <<= 1;
	bit      = 1 << (7 - (start % 8));
	result  |= (buf[start/8] & bit) ? 1 : 0;
	start++;
	count--;
    }
    return result;
}

void hexdump(char *prefix, unsigned char *data, size_t size)
{
    char ascii[17];
    int i;

    for (i = 0; i < size; i++) {
	if (0 == (i%16)) {
	    fprintf(stderr,"%s%s%04x:",
		    prefix ? prefix : "",
		    prefix ? ": "   : "",
		    i);
	    memset(ascii,0,sizeof(ascii));
	}
	if (0 == (i%4))
	    fprintf(stderr," ");
	fprintf(stderr," %02x",data[i]);
	ascii[i%16] = isprint(data[i]) ? data[i] : '.';
	if (15 == (i%16))
	    fprintf(stderr," %s\n",ascii);
    }
    if (0 != (i%16)) {
	while (0 != (i%16)) {
	    if (0 == (i%4))
		fprintf(stderr," ");
	    fprintf(stderr,"   ");
	    i++;
	};
	fprintf(stderr," %s\n",ascii);
    }
}

/* ----------------------------------------------------------------------- */
/* common code                                                             */

struct mpeg_handle* mpeg_init(void)
{
    struct mpeg_handle *h;
    
    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));
    h->fd     = -1;
    h->pgsize = getpagesize();
    h->init   = 1;
    return h;
}

void mpeg_fini(struct mpeg_handle *h)
{
    if (h->vbuf)
	ng_release_video_buf(h->vbuf);
    if (-1 != h->fd)
	close(h->fd);
    if (h->buffer)
	free(h->buffer);
    free(h);
}

unsigned char* mpeg_get_data(struct mpeg_handle *h, off_t pos, size_t size)
{
    fd_set set;
    struct timeval tv;
    off_t  low;
    size_t rdbytes;
    int rc;
    
    if (pos < h->boff) {
	/* shouldn't happen */
	fprintf(stderr,"mpeg: panic: seek backwards [pos=%ld,boff=%ld]\n",
		(long)pos,(long)h->boff);
	exit(1);
    }

    low = 0;
    if (!h->init && pos > h->init_offset*6) {
	if (h->video_offset > h->init_offset &&
	    h->audio_offset > h->init_offset)
	    low = (h->video_offset < h->audio_offset)
		? h->video_offset : h->audio_offset;
	else if (h->audio_offset > h->init_offset)
	    low = h->audio_offset;
	else if (h->video_offset > h->init_offset)
	    low = h->video_offset;
    }
    
    if (low > h->boff + h->balloc*3/4  &&
	low < h->boff + h->bsize       &&
	!h->beof) {
	/* move data window */
	rdbytes = (low - h->boff) & ~(h->pgsize - 1);
	memmove(h->buffer, h->buffer + rdbytes, h->balloc - rdbytes);
	h->boff  += rdbytes;
	h->bsize -= rdbytes;
	if (ng_debug)
	    fprintf(stderr,"mpeg: %dk file buffer shift\n", (int)(rdbytes >> 10));
    }
    
    while (pos+size + 2*TS_SIZE > h->boff + h->balloc  &&  !h->beof) {
	/* enlarge buffer */
	if (0 == h->bsize) {
	    h->balloc = FILE_BUF_MIN;
	    h->buffer = malloc(h->balloc);
	} else {
	    h->balloc *= 2;
	    if (h->balloc > FILE_BUF_MAX) {
		fprintf(stderr,"mpeg: panic: file buffer limit exceeded "
			"(l=%d,b=%d,v=%d,a=%d)\n",
			FILE_BUF_MAX,(int)h->balloc,
			(int)h->video_offset,(int)h->audio_offset);
		exit(1);
	    }
	    h->buffer  = realloc(h->buffer,h->balloc);
	}
	if (ng_debug)
	    fprintf(stderr,"mpeg: %dk file buffer\n",(int)(h->balloc >> 10));
    }

    while (pos+size > h->boff + h->bsize) {
	if (h->beof)
	    return NULL;
	/* read data */
	rdbytes  = h->balloc - h->bsize;
	if (rdbytes > FILE_BLKSIZE)
	    rdbytes = FILE_BLKSIZE;
	rdbytes -= rdbytes % TS_SIZE;
	rc = read(h->fd, h->buffer + h->bsize, rdbytes);
	switch (rc) {
	case -1:
	    switch (errno) {
	    case EAGAIN:
		/* must wait for data ... */
		if (!h->init) {
		    if (ng_log_resync)
			fprintf(stderr,"mpeg: sync: must wait for data\n");
		    h->slowdown++;
		}
		FD_ZERO(&set);
		FD_SET(h->fd,&set);
		tv.tv_sec  = ng_read_timeout;
		tv.tv_usec = 0;
		switch (select(h->fd+1,&set,NULL,NULL,&tv)) {
		case -1:
		    fprintf(stderr,"mpeg: select: %s\n",strerror(errno));
		    h->beof = 1;
		    break;
		case 0:
		    fprintf(stderr,"mpeg: select: timeout (%d sec)\n",
			    ng_read_timeout);
		    h->beof = 1;
		    break;
		}
		break;
	    case EOVERFLOW:
		if (ng_log_resync)
		    fprintf(stderr,"mpeg: sync: kernel buffer overflow\n");
		break;
	    default:
		fprintf(stderr,"mpeg: read: %s [%d]\n",strerror(errno),errno);
		h->beof = 1;
		break;
	    }
	    break;
	case 0:
	    if (ng_debug)
		fprintf(stderr,"mpeg: EOF\n");
	    h->beof = 1;
	    break;
	default:
	    h->bsize += rc;
	    break;
	}
    }
    return h->buffer + (pos - h->boff);
}

size_t mpeg_parse_pes_packet(struct mpeg_handle *h, unsigned char *packet,
			     uint64_t *ts, int *al)
{
    uint64_t pts, dts;
    int id;
    size_t size;
    int i, val;

    pts = 0;
    dts = 0;
    id  = 0;
    *al = 0;
    
    for (i = 48; i < 48 + 8*16; i += 8)
	if (0xff != mpeg_getbits(packet,i,8))
	    break;

    if (mpeg_getbits(packet,i,2) == 0x02) {
	/* MPEG 2 */
	id   = mpeg_getbits(packet, i-24, 8);
	*al  = mpeg_getbits(packet, i+ 5, 1);
	size = mpeg_getbits(packet, i+16, 8);
	size += i/8 + 3;
	switch (mpeg_getbits(packet, i+8, 2)) {
	case 3:
	    dts  = (uint64_t)mpeg_getbits(packet, i + 68,  3) << 30;
	    dts |= (uint64_t)mpeg_getbits(packet, i + 72, 15) << 15;
	    dts |= (uint64_t)mpeg_getbits(packet, i + 88, 15);
	    /* fall */
	case 2:
	    pts  = (uint64_t)mpeg_getbits(packet, i + 28,  3) << 30;
	    pts |= (uint64_t)mpeg_getbits(packet, i + 32, 15) << 15;
	    pts |= (uint64_t)mpeg_getbits(packet, i + 48, 15);
	    break;
	}
	if (ng_debug > 2)
	    fprintf(stderr,"mpeg2 pes: pl=%d al=%d copy=%d orig=%d ts=%d hl=%d | "
		    " pts=%" PRIx64 " dts=%" PRIx64 " size=%d\n",
		    mpeg_getbits(packet, i - 16, 16),
		    mpeg_getbits(packet, i +  5,  1),
		    mpeg_getbits(packet, i +  6,  1),
		    mpeg_getbits(packet, i +  7,  1),
		    mpeg_getbits(packet, i +  8,  2),
		    mpeg_getbits(packet, i + 16,  8),
		    pts, dts, (int)size);
	if (ng_debug > 3) {
	    hexdump("mpeg2 pes",packet,32);
	    fprintf(stderr,"--\n");
	}
    } else {
	/* MPEG 1 */
	if (mpeg_getbits(packet,i,2) == 0x01)
	    i += 16;
	val = mpeg_getbits(packet,i,8);
	if ((val & 0xf0) == 0x20) {
	    pts  = (uint64_t)mpeg_getbits(packet, i +  4,  3) << 30;
	    pts |= (uint64_t)mpeg_getbits(packet, i +  8, 15) << 15;
	    pts |= (uint64_t)mpeg_getbits(packet, i + 24, 15);
	    i += 40;
	} else if ((val & 0xf0) == 0x30) {
	    pts  = (uint64_t)mpeg_getbits(packet, i +  4,  3) << 30;
	    pts |= (uint64_t)mpeg_getbits(packet, i +  8, 15) << 15;
	    pts |= (uint64_t)mpeg_getbits(packet, i + 24, 15);
	    i += 80;
	} else if (val == 0x0f)
	    i += 8;
	size = i/8;
    }
    if (pts) {
	if (ng_debug > 1)
	    fprintf(stderr,"pts: %8.3f | id 0x%02x %s\n",
		    pts/90000.0,id,pes_s[id]);
	if (ts)
	    *ts = pts;
    }
    return size;
}

int mpeg_get_audio_rate(unsigned char *header)
{
    int rate = 44100;

    if (mpeg_getbits(header,12,1) == 1) {
	/* MPEG 1.0 */
	switch (mpeg_getbits(header,20,2)) {
	case 0: rate  = 44100; break;
	case 1: rate  = 48000; break;
	case 2: rate  = 32000; break;
	}
	if (ng_debug)
	    fprintf(stderr,"mpeg: MPEG1 audio, rate %d\n",rate);
    } else {
	/* MPEG 2.0 */
	switch (mpeg_getbits(header,20,2)) {
	case 0: rate  = 22050; break;
	case 1: rate  = 24000; break;
	case 2: rate  = 16000; break;
	}
	if (ng_debug)
	    fprintf(stderr,"mpeg: MPEG2 audio, rate %d\n",rate);
    }
    return rate;
}

unsigned char* mpeg_find_audio_hdr(unsigned char *buf, int off, int size)
{
    int i;
    
    for (i = off; i < size-1; i++) {
	if (0xff != buf[i])
	    continue;
	if (0xf0 == (buf[i+1] & 0xf0))
	    return buf+i;
    }
    return NULL;
}

int mpeg_get_video_fmt(struct mpeg_handle *h, unsigned char *header)
{
    if (header[0] != 0x00  ||  header[1] != 0x00  ||
	header[2] != 0x01  ||  header[3] != 0xb3)
	return -1;
    h->vfmt.fmtid  = VIDEO_MPEG;
    h->vfmt.width  = (mpeg_getbits(header,32,12) + 15) & ~15;
    h->vfmt.height = (mpeg_getbits(header,44,12) + 15) & ~15;
    h->ratio  = mpeg_getbits(header,56,4);
    h->rate   = mpeg_getbits(header,60,4);
    if (ng_debug)
	fprintf(stderr,"mpeg: MPEG video, %dx%d [ratio=%s,rate=%s]\n",
		h->vfmt.width, h->vfmt.height,
		ratio_s[h->ratio], rate_s[h->rate]);
    return 0;
}

int mpeg_check_video_fmt(struct mpeg_handle *h, unsigned char *header)
{
    int width, height, ratio;
    int change = 0;

    if (header[0] != 0x00  ||  header[1] != 0x00  ||
	header[2] != 0x01  ||  header[3] != 0xb3)
	return 0;
    width  = (mpeg_getbits(header,32,12) + 15) & ~15;
    height = (mpeg_getbits(header,44,12) + 15) & ~15;
    ratio  = mpeg_getbits(header,56,4);
    if (width != h->vfmt.width || height != h->vfmt.height) {
	if (ng_debug)
	    fprintf(stderr,"mpeg: size change: %dx%d => %dx%d\n",
		    h->vfmt.width, h->vfmt.height, width, height);
	change++;
    }
    if (ratio != h->ratio) {
	if (ng_debug)
	    fprintf(stderr,"mpeg: ratio change: %s => %s\n",
		    ratio_s[h->ratio], ratio_s[ratio]);
	change++;
    }
    h->vfmt.height = height;
    h->vfmt.width  = width;
    h->ratio       = ratio;
    return change;
}

/* ----------------------------------------------------------------------- */
/* program streams                                                         */

size_t mpeg_find_ps_packet(struct mpeg_handle *h, int packet, int mask, off_t *pos)
{
    unsigned char *buf;
    size_t size;
    off_t start = *pos;

    /* read header */
    for (;;) {
	buf = mpeg_get_data(h,*pos,16);
	if (NULL == buf)
	    return 0;
	if (buf[0] != 0x00 ||
	    buf[1] != 0x00 ||
	    buf[2] != 0x01)
	    return 0;
	size = mpeg_getbits(buf,32,16) + 6;

	/* handle special cases */
	switch (buf[3]) {
	case 0xba:
	    /* packet start code */
	    if (0x01 == mpeg_getbits(buf,32,2)) {
		/* MPEG 2 */
		size = 14 + mpeg_getbits(buf,109,3);
	    } else if (0x02 == mpeg_getbits(buf,32,4)) {
		/* MPEG 1 */
		size = 12;
	    } else {
		/* Huh? */
		return 0;
	    }
	    break;
	case 0xb9:
	    /* mpeg program end code */
	    return 0;
	}
	if (ng_debug > 1)
	    fprintf(stderr,"mpeg: packet 0x%x at 0x%08" PRIx64 "+%d [need 0x%x]\n",
		    (int)buf[3],(int64_t)*pos,(int)size,packet);

	/* our packet ? */
	if ((buf[3] & mask) == packet)
	    return size;
	*pos += size;

	/* don't search unlimited ... */
	if (*pos - start > FILE_BUF_MIN)
	    return 0;
    }
}

/* ----------------------------------------------------------------------- */
/* transport streams                                                       */

static void parse_pmt_desc(unsigned char *desc, int dlen,
			   struct psi_program *program, int pid)
{
    int i,t,l;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
	t = desc[i];
	l = desc[i+1];

	switch (t) {
	case 0x56:
	    if (!program->t_pid)
		program->t_pid = pid;
	    break;
	}
    }
}

static char* get_lang_tag(unsigned char *desc, int dlen)
{
    int i,t,l;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
	t = desc[i];
	l = desc[i+1];

	if (0x0a == t)
	    return desc+i+2;
    }
    return NULL;
}

static void dump_data(unsigned char *data, int len)
{
    int i;
    
    for (i = 0; i < len; i++) {
	if (isprint(data[i]))
	    fprintf(stderr,"%c", data[i]);
	else
	    fprintf(stderr,"\\x%02x", (int)data[i]);
    }
}

void mpeg_dump_desc(unsigned char *desc, int dlen)
{
    int i,j,t,l,l2,l3;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
	t = desc[i];
	l = desc[i+1];

	switch (t) {
	case 0x0a: /* ??? (pmt) */
	    fprintf(stderr," lang=%3.3s",desc+i+2);
	    break;
	case 0x45: /* vbi data (pmt) */
	    fprintf(stderr," vbidata=");
	    dump_data(desc+i+2,l);
	    break;
	case 0x52: /* stream identifier */
	    fprintf(stderr," sid=%d",(int)desc[i+2]);
	    break;
	case 0x56: /* teletext (pmt) */
	    fprintf(stderr," teletext=%3.3s",desc+i+2);
	    break;
	case 0x59: /* subtitles (pmt) */
	    fprintf(stderr," subtitles=%3.3s",desc+i+2);
	    break;
	case 0x6a: /* ac3 (pmt) */
	    fprintf(stderr," ac3");
	    break;

	case 0x40: /* network name (nit) */
	    fprintf(stderr," name=");
	    dump_data(desc+i+2,l);
	    break;
	case 0x43: /* satellite delivery system (nit) */
	    fprintf(stderr," dvb-s");
	    break;
	case 0x44: /* cable delivery system (nit) */
	    fprintf(stderr," dvb-c");
	    break;
	case 0x5a: /* terrestrial delivery system (nit) */
	    fprintf(stderr," dvb-t");
	    break;

	case 0x48: /* service (sdt) */
	    fprintf(stderr," service=%d,",desc[i+2]);
	    l2 = desc[i+3];
	    dump_data(desc+i+4,desc[i+3]);
	    fprintf(stderr,",");
	    dump_data(desc+i+l2+5,desc[i+l2+4]);
	    break;

	case 0x4d: /*  event (eid) */
	    fprintf(stderr," short=[%3.3s|",desc+i+2);
	    l2 = desc[i+5];
	    l3 = desc[i+6+l2];
	    dump_data(desc+i+6,l2);
	    fprintf(stderr,"|");
	    dump_data(desc+i+7+l2,l3);
	    fprintf(stderr,"]");
	    break;
	case 0x4e: /*  event (eid) */
	    fprintf(stderr," *ext event");
	    break;
	case 0x4f: /*  event (eid) */
	    fprintf(stderr," *time shift event");
	    break;
	case 0x50: /*  event (eid) */
	    fprintf(stderr," *component");
	    break;
	case 0x54: /*  event (eid) */
	    fprintf(stderr," content=");
	    for (j = 0; j < l; j+=2)
		fprintf(stderr,"%s0x%02x", j ? "," : "", desc[i+j+2]);
	    break;
	case 0x55: /*  event (eid) */
	    fprintf(stderr," *parental rating");
	    break;
	    
	default:
	    fprintf(stderr," %02x[",desc[i]);
	    dump_data(desc+i+2,l);
	    fprintf(stderr,"]");
	}
    }
}

int mpeg_parse_psi_pat(struct psi_info *info, unsigned char *data, int verbose)
{
    struct list_head   *item;
    struct psi_program *pr;
    int tsid,pnr,version,current;
    int j,len,pid;

    len     = mpeg_getbits(data,12,12) + 3 - 4;
    tsid    = mpeg_getbits(data,24,16);
    version = mpeg_getbits(data,42,5);
    current = mpeg_getbits(data,47,1);
    if (!current)
	return len+4;
    if (info->tsid == tsid && info->pat_version == version)
	return len+4;
    info->tsid         = tsid;
    info->pat_version  = version;
    info->pat_updated  = 1;
    
    if (verbose)
	fprintf(stderr, "ts [pat]: tsid %d ver %2d [%d/%d]\n",
		tsid, version,
		mpeg_getbits(data,48, 8),
		mpeg_getbits(data,56, 8));
    for (j = 64; j < len*8; j += 32) {
	pnr    = mpeg_getbits(data,j+0,16);
	pid    = mpeg_getbits(data,j+19,13);
	if (0 == pnr) {
	    /* network */
	    if (verbose > 1)
		fprintf(stderr,"   pid 0x%04x [network]\n",
			pid);
	} else {
	    /* program */
	    pr = psi_program_get(info, tsid, pnr, 1);
	    pr->p_pid   = pid;
	    pr->updated = 1;
	    pr->seen    = 1;
	    if (NULL == info->pr)
		info->pr = pr;
	}
    }
    if (verbose > 1) {
	list_for_each(item,&info->programs) {
	    pr = list_entry(item, struct psi_program, next);
	    if (pr->tsid != tsid)
		continue;
	    fprintf(stderr,"   pid 0x%04x => pnr %2d [program map%s]\n",
		    pr->p_pid, pr->pnr,
		    pr->seen ? ",seen" : "");
	}
	fprintf(stderr,"\n");
    }
    return len+4;
}

int mpeg_parse_psi_pmt(struct psi_program *program, unsigned char *data, int verbose)
{
    int pnr,version,current;
    int j,len,dlen,type,pid,slen;
    char *lang;

    len     = mpeg_getbits(data,12,12) + 3 - 4;
    pnr     = mpeg_getbits(data,24,16);
    version = mpeg_getbits(data,42,5);
    current = mpeg_getbits(data,47,1);
    if (!current)
	return len+4;
    if (program->pnr == pnr && program->version == version)
	return len+4;
    program->version = version;
    program->updated = 1;

    dlen = mpeg_getbits(data,84,12);
    /* TODO: decode descriptor? */
    if (verbose) {
	fprintf(stderr,
		"ts [pmt]: pnr %d ver %2d [%d/%d]  pcr 0x%04x  "
		"pid 0x%04x  type %2d #",
		pnr, version,
		mpeg_getbits(data,48, 8),
		mpeg_getbits(data,56, 8),
		mpeg_getbits(data,69,13),
		program->p_pid, program->type);
	mpeg_dump_desc(data + 96/8, dlen);
	fprintf(stderr,"\n");
    }
    j = 96 + dlen*8;
    program->v_pid = 0;
    program->a_pid = 0;
    program->t_pid = 0;
    memset(program->audio,0,sizeof(program->audio));
    while (j < len*8) {
	type = mpeg_getbits(data,j,8);
	pid  = mpeg_getbits(data,j+11,13);
	dlen = mpeg_getbits(data,j+28,12);
	switch (type) {
	case 1:
	case 2:
	    /* video */
	    if (!program->v_pid)
		program->v_pid = pid;
	    break;
	case 3:
	case 4:
	    /* audio */
	    if (!program->a_pid)
		program->a_pid = pid;
	    lang = get_lang_tag(data + (j+40)/8, dlen);
	    slen = strlen(program->audio);
	    snprintf(program->audio + slen, sizeof(program->audio) - slen,
		     "%s%.3s:%d", slen ? " " : "", lang ? lang : "xxx", pid);
	    break;
	case 6:
	    /* private data */
	    parse_pmt_desc(data + (j+40)/8, dlen, program, pid);
	    break;
	}
	if (verbose > 1) {
	    fprintf(stderr, "   pid 0x%04x => %-32s #",
		    pid, stream_type_s[type]);
	    mpeg_dump_desc(data + (j+40)/8, dlen);
	    fprintf(stderr,"\n");
	}
	j += 40 + dlen*8;
    }
    if (verbose > 1)
	fprintf(stderr,"\n");
    return len+4;
}

int mpeg_parse_psi(struct psi_info *info, struct mpeg_handle *h, int verbose)
{
    int i,tid;

    if (h->ts.payload) {
	for (i = h->ts.data[0]+1; i < h->ts.size;) {
	    tid = mpeg_getbits(h->ts.data,i*8,8);
	    switch (tid) {
	    case 0:
		i += mpeg_parse_psi_pat(info, h->ts.data+i, verbose);
		break;
	    case 1:
		fprintf(stderr, "ts: conditional access\n");
		return 0;
	    case 2:
		i += mpeg_parse_psi_pmt(info->pr, h->ts.data+i, verbose);
		break;
	    case 3:
		fprintf(stderr, "ts: description\n");
		return 0;
	    case 0xff:
		/* end of data */
		return 0;
	    default:
		fprintf(stderr, "ts: unknown table id %d\n",tid);
		return 0;
	    }
	}
    }
    return 0;
}

/* ----------------------------------------------------------------------- */

int mpeg_find_ts_packet(struct mpeg_handle *h, int wanted, off_t *pos)
{
    unsigned char *packet;
    int asize = 0;
    off_t start;

    for (start = *pos; *pos - start < FILE_BUF_MIN; *pos += TS_SIZE) {
	memset(&h->ts, 0, sizeof(h->ts));
	packet = mpeg_get_data(h, *pos, TS_SIZE);
	if (NULL == packet) {
	    fprintf(stderr,"mpeg ts: no more data\n");
	    return -1;
	}
	if (packet[0] != 0x47) {
	    if (ng_log_bad_stream)
		fprintf(stderr,"mpeg ts: warning %d: packet id mismatch\n",
			h->errors);
	    h->errors++;
	    continue;
	}
	h->ts.tei      = mpeg_getbits(packet, 8,1);
	h->ts.payload  = mpeg_getbits(packet, 9,1);
	h->ts.pid      = mpeg_getbits(packet,11,13);
	h->ts.scramble = mpeg_getbits(packet,24,2);
	h->ts.adapt    = mpeg_getbits(packet,26,2);
	h->ts.cont     = mpeg_getbits(packet,28,4);
	if (0 == h->ts.adapt)
	    /* reserved -- should discard */
	    continue;
	if (0x1fff == h->ts.pid)
	    /* NULL packet -- discard */
	    continue;
	if (h->ts.pid != wanted)
	    /* need something else */
	    continue;
	switch (h->ts.adapt) {
	case 3:
	    /* adaptation + payload */
	    asize      = mpeg_getbits(packet,32,8) +1;
	    h->ts.data = packet  + (4 + asize);
	    h->ts.size = TS_SIZE - (4 + asize);
	    if (h->ts.size > TS_SIZE) {
		if (ng_log_bad_stream)
		    fprintf(stderr,"mpeg ts: warning %d: broken adaptation"
			    " size [%lx]\n",h->errors,(unsigned long)(*pos));
		h->errors++;
		continue;
	    }
	    /* fall throuth */
	case 2:
	    /* adaptation only */
	    /* TODO: parse adaptation field */
	    break;
	case 1:
	    /* payload only */
	    h->ts.data = packet  + 4;
	    h->ts.size = TS_SIZE - 4;
	    break;
	}
	if (ng_debug > 2)
	    fprintf(stderr,"mpeg ts: pl=%d pid=%d adapt=%d cont=%d size=%d [%d]\n",
		    h->ts.payload, h->ts.pid, h->ts.adapt,
		    h->ts.cont, h->ts.size, asize);
	return 0;
    }
    return -1;
}
