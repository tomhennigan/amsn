/*
 * libng filter -- Correction of lens distortion
 *
 * (c) 2002 Frederic Helin <Frederic.Helin@inrialpes.fr>,
 *          Gerd Knorr <kraxel@bytesex.org>
 *
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <inttypes.h>
#include <pthread.h>

#include "grab-ng.h"

/* ------------------------------------------------------------------- */

int parm_k = 700;
int parm_cx = 50; 
int parm_cy = 50;
int parm_zoom = 50;

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
    uint8_t  *dst8;
    uint8_t  *src8;
    uint16_t *dst16;
    uint16_t *src16;

    int i, j, cx, cy, di, dj;
    float dr, cr,ca, sx, zoom, k;
    
    dst8  = out->data;
    src8  = in->data;
    dst16 = (uint16_t*) out->data;
    src16 = (uint16_t*) in->data;

    zoom     = parm_zoom / 100.0;
    k        = parm_k / 100.0;
    cx       = in->fmt.width  * parm_cx / 100;
    cy       = in->fmt.height * parm_cy / 100;

#if 0
    sensor_w = parm_sensorw/100.0;
    sensor_h = parm_sensorh/100.0;

    /* calc ratio x/y */
    sx = in->fmt.width * sensor_h / (in->fmt.height * sensor_w);
    
    /* calc new value of k in the coordonates systeme of computer */
    k = k * in->fmt.height / sensor_h;
#else
    sx = 1;
    k  = k * 100.0;
#endif

    for (j = 0; j < (int)in->fmt.height ; j++) {
	for (i = 0; i < (int)in->fmt.width ; i++) {	
	    
	    // compute radial distortion / parameters of center of image 
	    cr  = sqrt((i-cx)/sx*(i-cx)/sx+(j-cy)*(j-cy));
	    ca  = atan(cr/k/zoom);
	    dr = k * tan(ca/2);	
	    
	    if (i == cx && j == cy) {
		di = cx;
		dj = cy;
	    } else {
		di = (i-cx) * dr / cr + cx;
		dj = (j-cy) * dr / cr + cy;
	    }
	    
	    if (dj >= (int)in->fmt.height || dj < 0 ||
		di >= (int)in->fmt.width  || di < 0)
		continue;
	    
	    switch (in->fmt.fmtid) {
	    case VIDEO_RGB15_LE:
	    case VIDEO_RGB16_LE:
	    case VIDEO_RGB15_BE:
	    case VIDEO_RGB16_BE:
		dst16[i] = src16[dj*in->fmt.width + di];
		break;
	    case VIDEO_BGR24:
	    case VIDEO_RGB24:
		dst8[3*i  ] = src8[3*(dj*in->fmt.width + di)  ];
		dst8[3*i+1] = src8[3*(dj*in->fmt.width + di)+1];
		dst8[3*i+2] = src8[3*(dj*in->fmt.width + di)+2];
		break;
	    }
	}
	dst8  += out->fmt.bytesperline;
	dst16 += out->fmt.bytesperline/2;
    }
}

static void fini(void *handle)
{
    /* nothing to clean up */
}

/* ------------------------------------------------------------------- */

static int read_attr(struct ng_attribute *attr)
{
    switch (attr->id) {
    case 1000:
	return parm_k;
    case 1001:
	return parm_zoom;
    case 1002:
	return parm_cx;
    case 1003:
	return parm_cy;
    }
    return 0;
}

static void write_attr(struct ng_attribute *attr, int value)
{
    switch (attr->id) {
    case 1000:
	parm_k = value;
	break;
    case 1001:
	parm_zoom = value;
	break;
    case 1002:
	parm_cx = value;
	break;
    case 1003:
	parm_cy = value;
	break;
    }
}

/* ------------------------------------------------------------------- */

static struct ng_attribute attrs[] = {
    {
	.id       = 1000,
	.name     = "k",
	.type     = ATTR_TYPE_INTEGER,
	.defval   = 700,
	.min      = 1,
	.max      = 2000,
	.read     = read_attr,
	.write    = write_attr,
    },{
	.id       = 1001,
	.name     = "zoom",
	.type     = ATTR_TYPE_INTEGER,
	.defval   = 50,
	.min      = 10,
	.max      = 100,
	.read     = read_attr,
	.write    = write_attr,
    },{
	.id       = 1002,
	.name     = "center x",
	.type     = ATTR_TYPE_INTEGER,
	.defval   = 50,
	.min      = 0,
	.max      = 100,
	.read     = read_attr,
	.write    = write_attr,
    },{
	.id       = 1003,
	.name     = "center y",
	.type     = ATTR_TYPE_INTEGER,
	.defval   = 50,
	.min      = 0,
	.max      = 100,
	.read     = read_attr,
	.write    = write_attr,
    },{
	/* end of list */
    }
};

static struct ng_video_filter filter = {
    .name      = "disortion correction",
    .attrs     = attrs,
    .fmts      = (
	(1 << VIDEO_RGB15_BE)     |
	(1 << VIDEO_RGB16_BE)     |
	(1 << VIDEO_RGB15_LE)     |
	(1 << VIDEO_RGB16_LE)     |
	(1 << VIDEO_BGR24)        |
	(1 << VIDEO_RGB24)),
    .init      = init,
    .p.frame   = frame,
    .p.fini    = fini,
};

static void __init plugin_init(void)
{
    ng_filter_register(NG_PLUGIN_MAGIC,__FILE__,&filter);
}
