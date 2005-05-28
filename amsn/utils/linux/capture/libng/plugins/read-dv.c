/* gcc 2.95.x doesn't compile some c99 constructs ... */
#if __GNUC__ >= 3

#include "config.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <inttypes.h>
#include <sys/mman.h>

#include <libdv/dv.h>

#include "grab-ng.h"

/* ----------------------------------------------------------------------- */

struct dv_handle {
    /* handles */
    int fd;
    dv_decoder_t  *dec;

    /* mmap()ed data */
    unsigned char  *map_start;
    unsigned char  *map_ptr;
    off_t          map_size;
    int            map_frame;

    /* format */
    struct ng_video_fmt vfmt;
    struct ng_audio_fmt afmt;

    /* misc video */
    int rate,vframe,frames;

    /* misc audio */
    int aframe,samples;
    int16_t *audiobuf[4];
};

/* ----------------------------------------------------------------------- */

static enum color_space_e fmtid_to_colorspace[VIDEO_FMT_COUNT] = {
    [ 0 ... VIDEO_FMT_COUNT-1 ] = UNSET,
    [ VIDEO_YUYV   ] = e_dv_color_yuv,
    [ VIDEO_RGB24  ] = e_dv_color_rgb,
    [ VIDEO_BGR32  ] = e_dv_color_bgr0,
};

/* ----------------------------------------------------------------------- */

static void dv_unmap(struct dv_handle *h)
{
    if (!h->map_ptr)
	return;
    munmap(h->map_start,h->map_size);
    h->map_ptr = NULL;
}

static void dv_map(struct dv_handle *h, int frame)
{
    off_t map_offset;
    off_t pgsize, size, offset;

    size = h->dec->frame_size;
    if (0 == size)
	size = 120000; /* NTSC frame size */
    offset = frame * size;

    pgsize = getpagesize();
    map_offset   = offset & ~(pgsize-1);
    h->map_size  = offset - map_offset + size;
    h->map_start = mmap(0, h->map_size, PROT_READ, MAP_SHARED,
			h->fd, map_offset);
    if (MAP_FAILED == h->map_start) {
	perror("mmap");
	exit(1);
    }
    h->map_ptr = h->map_start + (offset - map_offset);
}

static void dv_fmt(struct dv_handle *h, int *vfmt, int vn)
{
    off_t len;
    int i;

    /* video format */
    for (i = 0; i < vn; i++) {
	if (ng_debug)
	    fprintf(stderr,"dv: trying: %d [%s]\n",
		    vfmt[i],ng_vfmt_to_desc[vfmt[i]]);
	if (UNSET == fmtid_to_colorspace[vfmt[i]])
	    continue;
	h->vfmt.fmtid = vfmt[i];
	break;
    }
    h->vfmt.width        = h->dec->width;
    h->vfmt.height       = h->dec->height;
    h->vfmt.bytesperline = (h->vfmt.width*ng_vfmt_to_depth[h->vfmt.fmtid]) >> 3;
    h->rate              = (e_dv_system_625_50 == h->dec->system) ? 25 : 30;

    /* audio fmt */
    if (1 == h->dec->audio->num_channels ||
	2 == h->dec->audio->num_channels) {
	h->afmt.fmtid = (16 == h->dec->audio->quantization) ?
	    AUDIO_S16_NATIVE_MONO : AUDIO_U8_MONO;
	if (2 == h->dec->audio->num_channels)
	    h->afmt.fmtid++;
    }
    h->afmt.rate = h->dec->audio->frequency;
    
    /* movie length (# of frames) */
    len = lseek(h->fd,0,SEEK_END);
    h->frames = len / h->dec->frame_size;
    
    if (ng_debug) {
	fprintf(stderr,"dv: len=%" PRId64 " => %d frames [%" PRId64 "]\n",
		(int64_t)len, h->frames,
		(int64_t)len - (int64_t)h->frames * h->dec->frame_size);
	fprintf(stderr,
		"dv: quality=%d system=%d std=%d sampling=%d num_dif_seqs=%d\n"
		"dv: height=%d width=%d frame_size=%ld\n",
		h->dec->quality, h->dec->system, h->dec->std,
		h->dec->sampling, h->dec->num_dif_seqs, h->dec->height,
		h->dec->width, h->dec->frame_size);
	fprintf(stderr, "dv: audio: %d Hz, %d bits, %d channels,"
		" emphasis %s\n",
		h->dec->audio->frequency,
		h->dec->audio->quantization,
		h->dec->audio->num_channels,
		(h->dec->audio->emphasis ? "on" : "off"));
    }
}

/* ----------------------------------------------------------------------- */

static void* dv_open(char *moviename)
{
    struct dv_handle *h;
    
    if (NULL == (h = malloc(sizeof(*h))))
	goto oops;
    memset(h,0,sizeof(*h));
    h->map_frame = -1;

    if (-1 == (h->fd = open(moviename,O_RDONLY))) {
	fprintf(stderr,"dv: open %s: %s\n",moviename,strerror(errno));
	goto oops;
    }
    if (NULL == (h->dec = dv_decoder_new(0,0,0))) {
	fprintf(stderr,"dv: dv_decoder_new failed\n");
	goto oops;
    }
    h->dec->quality = 3;

    dv_map(h, 0);
    if (dv_parse_header(h->dec, h->map_ptr) < 0) {
	fprintf(stderr,"dv: dv_parse_header failed\n");
	goto oops;
    }
    dv_fmt(h,NULL,0);

    return h;

 oops:
    if (h->dec)
	dv_decoder_free(h->dec);
    if (-1 != h->fd)
	close(h->fd);
    if (h)
	free(h);
    return NULL;
}

static struct ng_video_fmt* dv_vfmt(void *handle, int *vfmt, int vn)
{
    struct dv_handle *h = handle;

    dv_fmt(h,vfmt,vn);
    return &h->vfmt;
}

static struct ng_audio_fmt* dv_afmt(void *handle)
{
    struct dv_handle *h = handle;

    return h->afmt.fmtid ? &h->afmt : NULL;
}

static struct ng_video_buf* dv_vdata(void *handle, unsigned int *drop)
{
    struct dv_handle *h = handle;
    struct ng_video_buf *buf;
    unsigned char *pixels[3];
    int pitches[3];

    h->vframe += *drop;
    *drop = 0;
    if (h->vframe >= h->frames)
	return NULL;
    if (ng_debug > 1)
	fprintf(stderr,"dv: frame %d [drop=%d]\n",h->vframe,*drop);

    dv_unmap(h); dv_map(h, h->vframe);
    if (dv_parse_header(h->dec, h->map_ptr) < 0) {
	fprintf(stderr,"dv: dv_parse_header failed\n");
	return NULL;
    }

    buf = ng_malloc_video_buf(NULL, &h->vfmt);
    switch (h->vfmt.fmtid) {
    case VIDEO_YUYV:
	pixels[0]  = buf->data;
	pitches[0] = buf->fmt.width*2;
	break;
    case VIDEO_RGB24:
	pixels[0]  = buf->data;
	pitches[0] = buf->fmt.width*3;
	break;
    case VIDEO_BGR32:
	pixels[0]  = buf->data;
	pitches[0] = buf->fmt.width*4;
	break;
    default:
	BUG_ON(1,"unknown fmtid");
    }

    dv_parse_packs(h->dec, h->map_ptr);
    dv_decode_full_frame(h->dec, h->map_ptr,
			 fmtid_to_colorspace[h->vfmt.fmtid], 
			 pixels, pitches);
    buf->info.file_seq  = h->vframe;
    buf->info.play_seq  = h->vframe;
    buf->info.ts        = (long long) buf->info.play_seq * 1000000000 / h->rate;
    h->vframe++;
    return buf;
}

static struct ng_audio_buf* dv_adata(void *handle)
{
    struct dv_handle *h = handle;
    struct ng_audio_buf *buf;
    int16_t *dest;
    int asize, i;

    if (h->aframe >= h->frames)
	return NULL;

    dv_unmap(h); dv_map(h, h->aframe);
    if (dv_parse_header(h->dec, h->map_ptr) < 0) {
	fprintf(stderr,"dv: dv_parse_header failed\n");
	return NULL;
    }

    asize = h->dec->audio->samples_this_frame *
	h->dec->audio->num_channels *
	h->dec->audio->quantization >> 3;
    if (ng_debug > 1)
	fprintf(stderr,"dv: audio %d [samples=%d]\n",h->aframe,
		h->dec->audio->samples_this_frame);

    buf  = ng_malloc_audio_buf(&h->afmt, asize);
    dest = (int16_t*)buf->data;
    if (2 == h->dec->audio->num_channels) {
	if (NULL == h->audiobuf[0])
	    for (i = 0; i < 4; i++)
		h->audiobuf[i] = malloc(DV_AUDIO_MAX_SAMPLES*sizeof(int16_t));
	dv_decode_full_audio(h->dec, h->map_ptr, h->audiobuf);
	for (i = 0; i < h->dec->audio->samples_this_frame; i++) {
	    dest[2*i+0] = h->audiobuf[0][i];
	    dest[2*i+1] = h->audiobuf[1][i];
	}
    }
    if (1 == h->dec->audio->num_channels)
	dv_decode_full_audio(h->dec, h->map_ptr, &dest);
    
    buf->info.ts = (long long) h->samples * 1000000000 / h->afmt.rate;
    h->samples += h->dec->audio->samples_this_frame;
    h->aframe++;
    return buf;
}

static int64_t dv_frame_time(void *handle)
{
    struct dv_handle *h = handle;

    return 1000000000 / h->rate;
}

static int dv_close(void *handle)
{
    struct dv_handle *h = handle;
    int i;

    for (i = 0; i < 4; i++)
	if (h->audiobuf[i])
	    free(h->audiobuf[i]);
    dv_unmap(h);
    dv_decoder_free(h->dec);
    close(h->fd);
    free(h);
    return 0;
}

/* ----------------------------------------------------------------------- */

struct ng_reader dv_reader = {
    .name       = "dv",
    .desc       = "Digital Video",

    .magic	= { "\x1f\x07\x00",  "\x3f\x07\x00" },
    .moff       = {  0,              0x50           },
    .mlen       = {  3,              3              },
    
    .rd_open    = dv_open,
    .rd_vfmt    = dv_vfmt,
    .rd_afmt    = dv_afmt,
    .rd_vdata   = dv_vdata,
    .rd_adata   = dv_adata,
    .frame_time = dv_frame_time,
    .rd_close   = dv_close,
};

static void __init plugin_init(void)
{
    ng_reader_register(NG_PLUGIN_MAGIC,__FILE__,&dv_reader);
}
#endif /* gcc3 */
