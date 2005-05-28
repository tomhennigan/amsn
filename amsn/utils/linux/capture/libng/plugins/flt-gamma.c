/*
 * libng filter -- gamma correction
 *
 * (c) 2002 Gerd Knorr <kraxel@bytesex.org>
 *
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <pthread.h>

#include "grab-ng.h"

/* ------------------------------------------------------------------- */

static unsigned char lut[256];
static int g = 100;

static void inline
gamma_bytes(unsigned char *dst, unsigned char *src, int bytes)
{
    while (bytes--)
	*(dst++) = lut[ *(src++) ];
}

static void inline
gamma_native_rgb15(void *d, void *s, int pixels)
{
    unsigned short *dst = d;
    unsigned short *src = s;
    unsigned short r,g,b;

    while (pixels--) {
	r = lut[ ((*src >> 7)  &  0xf8) ] & 0xf8;
	g = lut[ ((*src >> 2)  &  0xf8) ] & 0xf8;
	b = lut[ ((*src << 3)  &  0xf8) ] & 0xf8;
	*dst = (r << 7) | (g << 2) | (b >> 3);
	src++; dst++;
    }
}

static void inline
gamma_native_rgb16(void *d, void *s, int pixels)
{
    unsigned short *dst = d;
    unsigned short *src = s;
    unsigned short r,g,b;

    while (pixels--) {
	r = lut[ ((*src >> 8)  &  0xf8) ] & 0xf8;
	g = lut[ ((*src >> 3)  &  0xfc) ] & 0xfc;
	b = lut[ ((*src << 3)  &  0xf8) ] & 0xf8;
	*dst = (r << 8) | (g << 3) | (b >> 3);
	src++; dst++;
    }
}

/* ------------------------------------------------------------------- */

static void *init(struct ng_video_fmt *out)
{
    /* don't have to carry around status info */
    static int dummy;
    return &dummy;
}

static void
frame(void *handle, struct ng_video_buf *out, struct ng_video_buf *in)
{
    unsigned char *dst;
    unsigned char *src;
    unsigned int y,cnt;

    dst = out->data;
    src = in->data;
    cnt = in->fmt.width * ng_vfmt_to_depth[in->fmt.fmtid] / 8;
    for (y = 0; y < in->fmt.height; y++) {
	switch (in->fmt.fmtid) {
	case VIDEO_GRAY:
	case VIDEO_BGR24:
	case VIDEO_RGB24:
	case VIDEO_BGR32:
	case VIDEO_RGB32:
	    gamma_bytes(dst,src,cnt);
	    break;
	case VIDEO_RGB15_NATIVE:
	    gamma_native_rgb15(dst,src,in->fmt.width);
	    break;
	case VIDEO_RGB16_NATIVE:
	    gamma_native_rgb16(dst,src,in->fmt.width);
	    break;
	}
	dst += out->fmt.bytesperline;
	src += in->fmt.bytesperline;
    }
}

static void fini(void *handle)
{
    /* nothing to clean up */
}

/* ------------------------------------------------------------------- */

static void calc_lut(void)
{
    int i,val;
    
    for (i = 0; i < 256; i++) {
	val = 255 * pow((float)i/255, 100.0/g);
	if (val < 0)   val = 0;
	if (val > 255) val = 255;
	lut[i] = val;
    }
}

static int read_attr(struct ng_attribute *attr)
{
    return g;
}

static void write_attr(struct ng_attribute *attr, int value)
{
    g = value;
    calc_lut();
}

/* ------------------------------------------------------------------- */

static struct ng_attribute attrs[] = {
    {
	.id       = 0,
	.name     = "gamma value",
	.type     = ATTR_TYPE_INTEGER,
	.defval   = 100,
	.min      = 1,
	.max      = 500,
	.points   = 2,
	.read     = read_attr,
	.write    = write_attr,
    },{
	/* end of list */
    }
};

static struct ng_video_filter filter = {
    .name      = "gamma",
    .attrs     = attrs,
    .fmts      = (
	(1 << VIDEO_GRAY)         |
	(1 << VIDEO_RGB15_NATIVE) |
	(1 << VIDEO_RGB16_NATIVE) |
	(1 << VIDEO_BGR24)        |
	(1 << VIDEO_RGB24)        |
	(1 << VIDEO_BGR32)        |
	(1 << VIDEO_RGB32)),
    .init      = init,
    .p.frame   = frame,
    .p.fini    = fini,
};

static void __init plugin_init(void)
{
    calc_lut();
    ng_filter_register(NG_PLUGIN_MAGIC,__FILE__,&filter);
}
