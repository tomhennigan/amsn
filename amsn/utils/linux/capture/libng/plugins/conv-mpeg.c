#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>
#include <inttypes.h>

#include <mpeg2dec/mpeg2.h>

#include "grab-ng.h"

/* ---------------------------------------------------------------------- */

struct mpeg_frame {
    struct ng_video_buf    *buf;
    int                    released;
    struct list_head       list;
};

struct mpeg_handle {
    mpeg2dec_t             *dec;
    const mpeg2_info_t     *info;
    struct ng_video_fmt    fmt;

    ng_get_video_buf       get;
    void                   *ghandle;

    struct list_head       wip;
    struct list_head       done;
    struct list_head       free;

    int                    wip_cnt;
    int                    wip_max;
};

/* ---------------------------------------------------------------------- */
/* decompress                                                             */

static void mpeg_open(struct mpeg_handle *h)
{
    h->dec  = mpeg2_init();
    h->info = mpeg2_info(h->dec);
    INIT_LIST_HEAD(&h->wip);
    INIT_LIST_HEAD(&h->done);
    INIT_LIST_HEAD(&h->free);
}

static void mpeg_close(struct mpeg_handle *h)
{
    struct mpeg_frame  *fr;

    mpeg2_close(h->dec);
    while (!list_empty(&h->wip)) {
	fr = list_entry(h->wip.next, struct mpeg_frame, list);
	list_del(&fr->list);
	ng_release_video_buf(fr->buf);
	free(fr);
    }
    while (!list_empty(&h->done)) {
	fr = list_entry(h->done.next, struct mpeg_frame, list);
	list_del(&fr->list);
	ng_release_video_buf(fr->buf);
	free(fr);
    }
    while (!list_empty(&h->free)) {
	fr = list_entry(h->free.next, struct mpeg_frame, list);
	list_del(&fr->list);
	free(fr);
    }
}

static void*
mpeg_init(struct ng_video_fmt *fmt, void *priv)
{
    struct mpeg_handle *h;
    
    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));
    h->fmt  = *fmt;

    mpeg_open(h);
    return h;
}

static void mpeg_setup(void *handle, ng_get_video_buf get, void *ghandle)
{
    struct mpeg_handle *h = handle;

    h->get     = get;
    h->ghandle = ghandle;
}

static void mpeg_pr_buf(struct ng_video_buf *buf, char *tag)
{
    static const char *type[] = {
	[ NG_FRAME_UNKNOWN ] = "unknown",
	[ NG_FRAME_I_FRAME ] = "I-Frame",
	[ NG_FRAME_P_FRAME ] = "P-Frame",
	[ NG_FRAME_B_FRAME ] = "B-Frame",
    };
    fprintf(stderr,"mdec %7s: %s ts=%.3f file=%d play=%d broken=%d\n",
	    tag, type[buf->info.frame],
	    buf->info.ts / 1000000000.0,
	    buf->info.file_seq, buf->info.play_seq,
	    buf->info.broken);
}

static void mpeg_put_frame(void *handle, struct ng_video_buf* in)
{
    static char *states[] = {
	[ STATE_BUFFER ]            = "buffer",
	[ STATE_SEQUENCE ]          = "sequence",
	[ STATE_SEQUENCE_REPEATED ] = "sequence repeated",
	[ STATE_GOP ]               = "gop",
	[ STATE_PICTURE ]           = "picture",
	[ STATE_SLICE_1ST ]         = "slice 1st",
	[ STATE_PICTURE_2ND ]       = "picture 2nd",
	[ STATE_SLICE ]             = "slice",
	[ STATE_END ]               = "end",
	[ STATE_INVALID ]           = "invalid",
	[ STATE_INVALID_END ]       = "invalid end",
    };

    struct mpeg_handle  *h = handle;
    struct mpeg_frame   *fr;
    struct ng_video_buf *buf;
    uint8_t *planes[3];
    int state;

    if (ng_debug > 2)
	mpeg_pr_buf(in, "input");
    if (in->info.broken || NG_FRAME_UNKNOWN == in->info.frame) {
	if (ng_log_bad_stream)
	    mpeg_pr_buf(in, "drop");
    } else {
	mpeg2_buffer(h->dec,in->data,in->data+in->size);
    }
    do {
	state = mpeg2_parse(h->dec);
	switch (state) {
	case STATE_BUFFER:
	    break;
	case STATE_PICTURE:
	    BUG_ON(NULL == h->get, "no setup");
	    buf = h->get(h->ghandle, &h->fmt);
	    buf->info = in->info;
	    planes[0] = buf->data;
	    planes[1] = buf->data + buf->fmt.width * buf->fmt.height;
	    planes[2] = buf->data + (buf->fmt.width * buf->fmt.height) * 5 / 4;
	    if (list_empty(&h->free)) {
		fr = malloc(sizeof(*fr));
	    } else {
		fr = list_entry(h->free.next, struct mpeg_frame, list);
		list_del(&fr->list);
	    }
	    fr->buf      = buf;
	    fr->released = 0;
	    list_add_tail(&fr->list,&h->wip);
	    mpeg2_set_buf(h->dec,planes,fr);
	    h->wip_cnt++;
	    if (h->wip_max < h->wip_cnt) {
		h->wip_max = h->wip_cnt;
		if (ng_debug)
		    fprintf(stderr,"mpeg: wip max=%d\n",h->wip_max);
	    }
	    break;
	case STATE_SLICE:
        case STATE_END:
	    if (h->info->display_fbuf && h->info->display_fbuf->id) {
		/* debug */
		fr = h->info->display_fbuf->id;
		if (ng_debug > 2)
		    mpeg_pr_buf(fr->buf, "display");
		list_del(&fr->list);
		list_add_tail(&fr->list,&h->done);
	    }
	    if (h->info->discard_fbuf && h->info->discard_fbuf->id) {
		fr = h->info->discard_fbuf->id;
		if (ng_debug > 2)
		    mpeg_pr_buf(fr->buf, "discard");
		fr->released = 1;
	    }
	    break;
	case STATE_GOP:
	case STATE_SEQUENCE:
	case STATE_SEQUENCE_REPEATED:
	    if (ng_debug > 2)
		fprintf(stderr,"mpeg: state=%d [%s], ignoring\n",
			state,states[state]);
	    break;
	case STATE_INVALID:
	case STATE_INVALID_END:
	    if (ng_debug)
		fprintf(stderr,"mpeg: state=%d [%s], restarting decoder\n",
			state,states[state]);
	    mpeg_close(h);
	    mpeg_open(h);
	    break;
	default:
	    fprintf(stderr,"mpeg: state=%d [%s], don't know how to handle\n",
		    state,states[state]);
	    exit(1);
	    break;
	}
    } while (state != STATE_BUFFER);
    ng_release_video_buf(in);
}

static struct ng_video_buf* mpeg_get_frame(void *handle)
{
    struct mpeg_handle  *h = handle;
    struct mpeg_frame   *fr;
    struct ng_video_buf *buf;

    if (list_empty(&h->done))
	return NULL;
#if 0
    /* try to keep the buffers in the queue constant */
    if (h->wip_cnt < h->wip_max)
	return NULL;
#endif
    fr = list_entry(h->done.next, struct mpeg_frame, list);
    if (!fr->released)
	return NULL;

    buf = fr->buf;
    fr->buf = NULL;
    list_del(&fr->list);
    list_add_tail(&fr->list,&h->free);
    if (ng_debug > 1)
	mpeg_pr_buf(buf, "output");
    h->wip_cnt--;
    return buf;
}

static void
mpeg_fini(void *handle)
{
    struct mpeg_handle *h = handle;

    mpeg_close(h);
    free(h);
}

/* ---------------------------------------------------------------------- */
/* static data + register                                                 */

static struct ng_video_conv mpeg_list[] = {
    {
	.init           = mpeg_init,
	.p.mode         = NG_MODE_COMPLEX,
	//.p.frame        = mpeg_frame,
	.p.setup        = mpeg_setup,
	.p.put_frame    = mpeg_put_frame,
	.p.get_frame    = mpeg_get_frame,
	.p.fini         = mpeg_fini,
	.fmtid_in	= VIDEO_MPEG,
	.fmtid_out	= VIDEO_YUV420P,
    }
};
static const int nconv = sizeof(mpeg_list)/sizeof(struct ng_video_conv);

static void __init plugin_init(void)
{
    ng_conv_register(NG_PLUGIN_MAGIC,__FILE__,mpeg_list,nconv);
}
