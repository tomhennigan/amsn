#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>

#include <artsc.h>

#include "grab-ng.h"

/* -------------------------------------------------------------------- */

struct arts_handle {
    arts_stream_t  *stream;
};

static void*
ng_arts_init(char *device, int record)
{
    struct arts_handle *h;
    int err;

    if (record)
	return NULL;
    if (NULL != device && 0 != strcasecmp(device,"arts"))
	return NULL;

    if (0 != (err = arts_init())) {
	if (ng_debug)
	    fprintf(stderr,"arts: init: %s\n",arts_error_text(err));
	return NULL;
    }
    arts_free();

    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));
    return h;
}

static int
ng_arts_open(void *handle, struct ng_audio_fmt *fmt)
{
    struct arts_handle *h = handle;

    BUG_ON(h->stream,"stream already open");
    if (0 != arts_init())
	return -1;
    if (NULL == (h->stream = arts_play_stream(fmt->rate,
					      ng_afmt_to_bits[fmt->fmtid],
					      ng_afmt_to_channels[fmt->fmtid],
					      "libng"))) {
	arts_free();
	return -1;
    }
#if 0
    fcntl(h->fd,F_SETFD,FD_CLOEXEC);
#endif
    return 0;
}

static int
ng_arts_close(void *handle)
{
    struct arts_handle *h = handle;

    BUG_ON(!h->stream,"stream not open");
    arts_close_stream(h->stream);
    arts_free();
    h->stream = NULL;
    return 0;
}

static int
ng_arts_fini(void *handle)
{
    struct arts_handle *h = handle;

    BUG_ON(h->stream,"stream still open");
    free(h);
    return 0;
}

static int
ng_arts_startplay(void *handle)
{
    struct arts_handle *h = handle;

    if (ng_debug)
	fprintf(stderr,"arts: startplay\n");
    BUG_ON(!h->stream,"stream not open");
    return 0;
}

static struct ng_audio_buf*
ng_arts_write(void *handle, struct ng_audio_buf *buf)
{
    struct arts_handle *h = handle;
    int rc;

    BUG_ON(!h->stream,"stream not open");
    rc = arts_write(h->stream, buf->data+buf->written, buf->size-buf->written);
    switch (rc) {
    case -1:
	fprintf(stderr,"arts: write: %s",arts_error_text(rc));
	ng_free_audio_buf(buf);
	buf = NULL;
    case 0:
	fprintf(stderr,"arts: write: Huh? no data written?\n");
	ng_free_audio_buf(buf);
	buf = NULL;
    default:
	buf->written += rc;
	if (buf->written == buf->size) {
	    ng_free_audio_buf(buf);
	    buf = NULL;
	}
    }
    return buf;
}

static int64_t
ng_arts_latency(void *handle)
{
    struct arts_handle *h = handle;
    uint64_t latency;

    BUG_ON(!h->stream,"stream not open");
    latency  = arts_stream_get(h->stream, ARTS_P_TOTAL_LATENCY);
    latency *= 1000000;
    return latency;
}

static int
ng_arts_fd(void *handle)
{
    return -1;
}

static struct ng_devinfo* ng_arts_probe(int record)
{
    static struct ng_devinfo info[2] = {
	{
	    .device = "arts",
	    .name   = "aRts daemon"
	}
    };
    int err;

    if (record)
	return NULL;

    err = arts_init();
    arts_free();
    return (0 == err) ? info : NULL;
}

/* ------------------------------------------------------------------- */

static struct ng_dsp_driver arts_dsp = {
    .name      = "arts",
    .priority  = 1,

    .probe     = ng_arts_probe,
    .init      = ng_arts_init,
    .open      = ng_arts_open,
    .close     = ng_arts_close,
    .fini      = ng_arts_fini,
    
    .fd        = ng_arts_fd,
    .startplay = ng_arts_startplay,
    .write     = ng_arts_write,
    .latency   = ng_arts_latency,
};

static void __init plugin_init(void)
{
    ng_dsp_driver_register(NG_PLUGIN_MAGIC,__FILE__,&arts_dsp);
}
