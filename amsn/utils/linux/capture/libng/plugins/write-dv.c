/*
 * Far from being finished, I know.  But todays computers are too slow
 * to encode DV in real time anyway ...
 *
 */
#include "config.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>

#include <libdv/dv.h>

#include "grab-ng.h"
#include "list.h"

/* ----------------------------------------------------------------------- */

struct dv_frame {
    struct list_head  list;
    int               seq;
    int               video,audio;
    unsigned char     obuf[0];
};

struct dv_handle {
    /* handles */
    int fd;
    dv_encoder_t  *enc;

    /* format */
    struct ng_video_fmt video;
    struct ng_audio_fmt audio;

    /* misc */
    int framesize, fvideo, faudio;
    struct list_head frames;
};

/* ----------------------------------------------------------------------- */

static struct dv_frame*
dv_get_frame(struct dv_handle *h, int nr)
{
    struct dv_frame *frame = NULL;
    struct list_head *item;

    list_for_each(item,&h->frames) {
	frame = list_entry(item,struct dv_frame,list);
	if (frame->seq == nr)
	    break;
    }
    if (NULL == frame || frame->seq != nr) {
	frame = malloc(sizeof(*frame) + h->framesize);
	memset(frame,0,sizeof(*frame) + h->framesize);
	frame->seq = nr;
	list_add_tail(&frame->list,&h->frames);
    }
    return frame;
}

static int dv_put_frame(struct dv_handle *h, struct dv_frame *frame)
{
    int rc;

    if (h->video.fmtid  &&  !frame->video)
	return 0;
    if (h->audio.fmtid  &&  !frame->audio)
	return 0;

    if (ng_debug)
	fprintf(stderr,"dv: write frame #%d\n",frame->seq);
    rc = write(h->fd, frame->obuf, h->framesize);
    list_del(&frame->list);
    free(frame);
    return (rc == h->framesize) ? 0 : -1;
}

/* ----------------------------------------------------------------------- */

static void*
dv_open(char *filename, char *dummy,
	struct ng_video_fmt *video, const void *priv_video, int fps,
	struct ng_audio_fmt *audio, const void *priv_audio)
{
    struct dv_handle *h;

    if (NULL == (h = malloc(sizeof(*h))))
	return NULL;

    memset(h,0,sizeof(*h));
    h->video      = *video;
    h->audio      = *audio;

    if (-1 == (h->fd = open(filename,O_CREAT | O_RDWR | O_TRUNC, 0666))) {
        fprintf(stderr,"open %s: %s\n",filename,strerror(errno));
	goto fail;
    }
    h->enc = dv_encoder_new(0,0,0);
    if (NULL == h->enc) {
	fprintf(stderr,"dv: dv_encoder_new failed\n");
	goto fail;
    }
	
    if (h->audio.fmtid != AUDIO_NONE) {
    }
    if (h->video.fmtid != VIDEO_NONE) {
	if (720   == h->video.width  &&
	    480   == h->video.height &&
	    30000 == fps) {
	    /* NTSC */
	    h->enc->isPAL = 0;
	    h->framesize  = 120000;
	} else if (720   == h->video.width  &&
		   576   == h->video.height &&
		   25000 == fps) {
	    /* PAL */
	    h->enc->isPAL = 1;
	    h->framesize  = 144000;
	} else {
	    fprintf(stderr,
		    "dv: %dx%d @ %d fps is not allowed for digital video\n"
		    "dv: use 720x480/30 (NTSC) or 720x576/25 (PAL)\n",
		    h->video.width, h->video.height, fps/1000);
	    goto fail;
	}
    }
    INIT_LIST_HEAD(&h->frames);
    return h;

 fail:
    if (h->enc)
	dv_encoder_free(h->enc);
    if (-1 != h->fd)
	close(h->fd);
    free(h);
    return NULL;
}

static int
dv_video(void *handle, struct ng_video_buf *buf)
{
    struct dv_handle *h = handle;
    struct dv_frame *frame;
    unsigned char *pixels[3];

    frame = dv_get_frame(h,h->fvideo);
    pixels[0] = buf->data;
    switch (buf->fmt.fmtid) {
    case VIDEO_YUYV:
	dv_encode_full_frame(h->enc,pixels,e_dv_color_yuv,frame->obuf);
	break;
    case VIDEO_RGB24:
	dv_encode_full_frame(h->enc,pixels,e_dv_color_rgb,frame->obuf);
	break;
    case VIDEO_BGR32:
	dv_encode_full_frame(h->enc,pixels,e_dv_color_bgr0,frame->obuf);
	break;
    default:
	BUG_ON(1,"unknown fmtid");
    }
    frame->video = 1;
    dv_put_frame(h,frame);
    h->fvideo++;
    return 0;
}

static int
dv_audio(void *handle, struct ng_audio_buf *buf)
{
    //struct dv_handle *h = handle;
    //struct dv_frame *frame;

    return -1;
}

static int
dv_close(void *handle)
{
    struct dv_handle *h = handle;

    dv_encoder_free(h->enc);
    close(h->fd);
    free(h);
    return 0;
}

/* ----------------------------------------------------------------------- */

static const struct ng_format_list dv_vformats[] = {
    {
	.name  = "dv",
	.ext   = "dv",
	.desc  = "digital video",
	.fmtid = VIDEO_YUYV,
    },{
	/* EOF */
    }
};

static const struct ng_format_list dv_aformats[] = {
    {
	.name  = "stereo16",
	.ext   = "dv",
	.fmtid = AUDIO_S16_NATIVE_STEREO,
    },{
	/* EOF */
    }
};

struct ng_writer dv_writer = {
    .name      = "dv",
    .desc      = "Digital Video",
    //combined:  1,
    .video     = dv_vformats,
    //audio:     dv_aformats,
    .wr_open   = dv_open,
    .wr_video  = dv_video,
    .wr_audio  = dv_audio,
    .wr_close  = dv_close,
};

static void __init plugin_init(void)
{
    //ng_writer_register(NG_PLUGIN_MAGIC,__FILE__,&dv_writer);
}
