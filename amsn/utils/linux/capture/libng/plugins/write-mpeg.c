/*
 * write out mpeg program streams
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
#include <inttypes.h>
#include <sys/param.h>
#include <sys/uio.h>

#include "grab-ng.h"
#include "parse-mpeg.h"

/* ----------------------------------------------------------------------- */

struct mpeg_wr_handle {
    /* file name+handle */
    char   file[MAXPATHLEN];
    int    fd;
    int    afirst;
    int    vfirst;

    /* format */
    struct ng_video_fmt video;
    struct ng_audio_fmt audio;
};

/* ----------------------------------------------------------------------- */

static int build_pes_hdr(unsigned char *buf, int id, size_t dlen, int64_t ts)
{
    // buf->info.ts = (h->audio_pts - h->start_pts) * (uint64_t)1000000 / (uint64_t)90;
    int len;
    size_t size;
    uint64_t pts;

    len = (-1 != ts) ? 14 : 9;
    size = dlen + len - 6;

    memset(buf,0,len);
    buf[ 2]  = 0x01;
    buf[ 3]  = id;
    buf[ 4]  = size/256;  // len1
    buf[ 5]  = size%256;  // len2
    buf[ 6] |= 0x80;      // fixed
    buf[ 8]  = len-9;
    if (-1 != ts) {
	pts = ts * (uint64_t)90 / (uint64_t)1000000;
	buf[ 6] |= 0x04;  // aligned
	buf[ 7] |= 0x80;  // ptsdts == pts
	buf[ 9] |= 0x20;  // fixed
	buf[ 9] |= 0x01;  // marker
	buf[11] |= 0x01;  // marker
	buf[13] |= 0x01;  // marker
	buf[ 9] |= (pts >> 30) & 0x07;
	buf[10] |= (pts >> 22) & 0xff;
	buf[11] |= (pts >> 14) & 0xfe;
	buf[12] |= (pts >>  7) & 0xff;
	buf[13] |= (pts <<  1) & 0xfe;
    }
    return len;
}

static int build_ps_pack_hdr(unsigned char *buf)
{
    int len = 14;

    memset(buf,0,len);
    buf[ 2]  = 0x01;
    buf[ 3]  = 0xba;
    buf[ 4] |= 0x40;      // fixed
    buf[ 4] |= 0x04;      // marker
    buf[ 6] |= 0x04;      // marker
    buf[ 8] |= 0x04;      // marker
    buf[ 9] |= 0x01;      // marker
    buf[12] |= 0x03;      // marker
    // buf[4-12] = stuff;
    buf[13] |= (len-14);  // padding
    return len;
}

static int build_ps_system_hdr(unsigned char *buf)
{
#if 0
    int len = 12;

    memset(buf,0,len);
    buf[ 2]  = 0x01;
    buf[ 3]  = 0xbb;
    buf[ 4]  = 0;     // len1
    buf[ 5]  = len-6; // len2
    buf[ 6] |= 0x80;  // marker
    buf[ 7] |= 0x01;  // marker
    buf[ 9] |= 0x20;  // marker
    // buf[6-11] = stuff;
    return len;
#else
    return 0;
#endif
}

/* ----------------------------------------------------------------------- */

static void*
mpeg_open(char *filename, char *dummy,
	  struct ng_video_fmt *video, const void *priv_video, int fps,
	  struct ng_audio_fmt *audio, const void *priv_audio)
{
    struct mpeg_wr_handle      *h;

    if (NULL == filename)
	return NULL;
    if (NULL == (h = malloc(sizeof(*h))))
	return NULL;

    /* init */
    memset(h, 0, sizeof(*h));
    h->video = *video;
    h->audio = *audio;

    strcpy(h->file,filename);
    if (-1 == (h->fd = open(h->file,O_CREAT | O_RDWR | O_TRUNC, 0666))) {
	fprintf(stderr,"open %s: %s\n",h->file,strerror(errno));
	free(h);
	return NULL;
    }

    /* video */
    if (h->video.fmtid != VIDEO_NONE) {
    }

    /* audio */
    if (h->audio.fmtid != AUDIO_NONE) {
    }

    return h;
}

static int
mpeg_video(void *handle, struct ng_video_buf *buf)
{
    struct mpeg_wr_handle *h = handle;
    int off,size,len = 0;
    char hdr[256];
    
    len += build_ps_pack_hdr(hdr+len);
    if (0 == h->vfirst) {
	h->vfirst++;
	len += build_ps_system_hdr(hdr+len);
    }
    write(h->fd, hdr, len);
    for (off = 0;  off < buf->size; off += size) {
	size = buf->size - off;
	if (size > 20000)
	    size = 16384;
	len = build_pes_hdr(hdr, 0xe0, size, off ? -1 : buf->info.ts);
	write(h->fd, hdr, len);
	write(h->fd, buf->data+off, size);
    }
    return 0;
}

static int
mpeg_audio(void *handle, struct ng_audio_buf *buf)
{
    struct mpeg_wr_handle *h = handle;
    int off,size,len = 0;
    char hdr[256];

    len += build_ps_pack_hdr(hdr+len);
    if (0 == h->afirst) {
	h->afirst++;
	len += build_ps_system_hdr(hdr+len);
    }
    write(h->fd, hdr, len);

    for (off = 0; off < buf->size; off += size) {
	size = buf->size - off;
	if (size > 20000)
	    size = 16384;
	len = build_pes_hdr(hdr, 0xc0, size, off ? -1 : buf->info.ts);
	write(h->fd, hdr, len);
	write(h->fd, buf->data+off, size);
    }
    return 0;
}

static int
mpeg_close(void *handle)
{
    static unsigned char end_code[4] = { 0x00, 0x00, 0x01, 0xb9 };
    struct mpeg_wr_handle *h = handle;

    write(h->fd, end_code, 4);
    close(h->fd);
    free(h);
    return 0;
}

/* ----------------------------------------------------------------------- */

static void*
mp3_open(char *filename, char *dummy,
	 struct ng_video_fmt *video, const void *priv_video, int fps,
	 struct ng_audio_fmt *audio, const void *priv_audio)
{
    struct mpeg_wr_handle      *h;

    if (NULL == filename)
	return NULL;
    if (NULL == (h = malloc(sizeof(*h))))
	return NULL;

    /* init */
    memset(h, 0, sizeof(*h));
    h->audio = *audio;

    strcpy(h->file,filename);
    if (-1 == (h->fd = open(h->file,O_CREAT | O_RDWR | O_TRUNC, 0666))) {
	fprintf(stderr,"open %s: %s\n",h->file,strerror(errno));
	free(h);
	return NULL;
    }

    /* audio */
    if (h->audio.fmtid != AUDIO_NONE) {
    }

    return h;
}

static int
mp3_audio(void *handle, struct ng_audio_buf *buf)
{
    struct mpeg_wr_handle *h = handle;
    char *hdr = NULL;
    int off;

    if (0 != h->afirst)
	return write(h->fd, buf->data, buf->size);

    /* first blk: look for mpeg frame start */
    hdr = mpeg_find_audio_hdr(buf->data, 0, buf->size);
    if (NULL == hdr)
	return 0;
    h->afirst++;
    off = hdr - buf->data;
    return write(h->fd, hdr, buf->size - off);
}

static int
mp3_close(void *handle)
{
    struct mpeg_wr_handle *h = handle;

    close(h->fd);
    free(h);
    return 0;
}

/* ----------------------------------------------------------------------- */
/* data structures describing our capabilities                             */

static const struct ng_format_list mpeg_vformats[] = {
    {
	.name  = "mpeg",
	.ext   = "mpeg",
	.fmtid = VIDEO_MPEG,
    },{
	/* EOF */
    }
};

static const struct ng_format_list mpeg_aformats[] = {
    {
	.name  = "mpeg",
	.ext   = "mpeg",
	.fmtid = AUDIO_MP3,
    },{
	/* EOF */
    }
};

struct ng_writer mpeg_writer = {
    .name      = "mpeg-ps",
    .desc      = "MPEG Programm Stream",
    .combined  = 1,
    .video     = mpeg_vformats,
    .audio     = mpeg_aformats,
    .wr_open   = mpeg_open,
    .wr_video  = mpeg_video,
    .wr_audio  = mpeg_audio,
    .wr_close  = mpeg_close,
};

static const struct ng_format_list mp3_aformats[] = {
    {
	.name  = "mp3",
	.ext   = "mp3",
	.fmtid = AUDIO_MP3,
    },{
	/* EOF */
    }
};

struct ng_writer mp3_writer = {
    .name      = "mp3",
    .desc      = "MPEG Audio",
    .audio     = mp3_aformats,
    .wr_open   = mp3_open,
    .wr_audio  = mp3_audio,
    .wr_close  = mp3_close,
};

static void __init plugin_init(void)
{
    ng_writer_register(NG_PLUGIN_MAGIC,__FILE__,&mpeg_writer);
    ng_writer_register(NG_PLUGIN_MAGIC,__FILE__,&mp3_writer);
}
