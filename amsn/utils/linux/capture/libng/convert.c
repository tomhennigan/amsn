#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include "grab-ng.h"

struct ng_process_handle {
    struct ng_video_fmt      ifmt;
    struct ng_video_fmt      ofmt;

    ng_get_video_buf         get;
    void                     *ghandle;

    struct ng_video_process  *p;
    void                     *phandle;
    struct ng_video_buf      *in;
};

/*-------------------------------------------------------------------------*/
/* color space conversion / compression helper functions                   */

static int processes;

struct ng_process_handle* ng_conv_init(struct ng_video_conv *conv,
				       struct ng_video_fmt *i,
				       struct ng_video_fmt *o)
{
    struct ng_process_handle *h;

    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));

    /* fixup output image size to match incoming */
    if (0 == i->bytesperline)
	i->bytesperline = i->width * ng_vfmt_to_depth[i->fmtid] / 8;
    o->width  = i->width;
    o->height = i->height;
    if (0 == o->bytesperline)
	o->bytesperline = o->width * ng_vfmt_to_depth[o->fmtid] / 8;

    h->ifmt    = *i;
    h->ofmt    = *o;
    h->p       = &conv->p;
    h->phandle = conv->init(&h->ofmt,conv->priv);

    switch (h->p->mode) {
    case NG_MODE_TRIVIAL:
    case NG_MODE_COMPLEX:
	break;
    default:
	BUG_ON(1,"mode not initialited");
	break;
    }

    if (ng_debug) {
	fprintf(stderr,"convert-in : %dx%d %s\n",
		h->ifmt.width, h->ifmt.height,
		ng_vfmt_to_desc[h->ifmt.fmtid]);
	fprintf(stderr,"convert-out: %dx%d %s\n",
		h->ofmt.width, h->ofmt.height,
		ng_vfmt_to_desc[h->ofmt.fmtid]);
    }
    processes++;
    return h;
}

struct ng_process_handle* ng_filter_init(struct ng_video_filter *filter,
					 struct ng_video_fmt *fmt)
{
    struct ng_process_handle *h;

    if (!(filter->fmts & (1 << fmt->fmtid))) {
	fprintf(stderr,"filter \"%s\" doesn't support video format \"%s\"\n",
		filter->name, ng_vfmt_to_desc[fmt->fmtid]);
	return NULL;
    }

    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));

    h->ifmt    = *fmt;
    h->ofmt    = *fmt;
    h->p       = &filter->p;
    h->phandle = filter->init(fmt);

    switch (h->p->mode) {
    case NG_MODE_TRIVIAL:
    case NG_MODE_COMPLEX:
	break;
    default:
	BUG_ON(1,"mode not initialited");
	break;
    }

    if (ng_debug)
	fprintf(stderr,"filtering: %s\n", filter->name);
    processes++;
    return h;
}

void ng_process_setup(struct ng_process_handle *h, ng_get_video_buf get, void *ghandle)
{
    switch (h->p->mode) {
    case NG_MODE_TRIVIAL:
	BUG_ON(NULL != h->in, "already have frame");
	h->get     = get;
	h->ghandle = ghandle;
	break;
    case NG_MODE_COMPLEX:
	h->p->setup(h->phandle,get,ghandle);
	break;
    default:
	BUG_ON(1,"mode not implemented yet");
	break;
    }
}

void ng_process_put_frame(struct ng_process_handle *h, struct ng_video_buf* buf)
{
    switch (h->p->mode) {
    case NG_MODE_TRIVIAL:
	BUG_ON(NULL != h->in, "already have frame");
	h->in = buf;
	break;
    case NG_MODE_COMPLEX:
	h->p->put_frame(h->phandle,buf);
	break;
    default:
	BUG_ON(1,"mode not implemented yet");
	break;
    }
}

struct ng_video_buf* ng_process_get_frame(struct ng_process_handle *h)
{
    struct ng_video_buf *buf = NULL;

    switch (h->p->mode) {
    case NG_MODE_TRIVIAL:
	BUG_ON(NULL == h->get, "no setup");
	if (NULL != h->in) {
	    buf = h->get(h->ghandle, &h->ofmt);
#if 0
	    ng_print_video_buf("in",h->in);
	    ng_print_video_buf("out",buf);
#endif
	    h->p->frame(h->phandle, buf, h->in);
	    buf->info = h->in->info;
	    ng_release_video_buf(h->in);
	    h->in = NULL;
	}
	break;
    case NG_MODE_COMPLEX:
	buf = h->p->get_frame(h->phandle);
	break;
    default:
	BUG_ON(1,"mode not implemented yet");
	break;
    }
    return buf;
}

void ng_process_fini(struct ng_process_handle *h)
{
    h->p->fini(h->phandle);
    free(h);
    processes--;
}

static void __fini process_check(void)
{
    OOPS_ON(processes > 0, "processes is %d (expected 0)",processes);
}
