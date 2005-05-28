/*
 * colorspace conversion functions
 *    -- translate RGB using lookup tables
 *
 *  (c) 1998-2001 Gerd Knorr <kraxel@bytesex.org>
 *
 */

#define NG_PRIVATE
#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <inttypes.h>
#include <sys/time.h>
#include <sys/types.h>

#include "grab-ng.h"
#include "byteswap.h"

int32_t   ng_lut_red[256];
int32_t   ng_lut_green[256];
int32_t   ng_lut_blue[256];

/* ------------------------------------------------------------------- */

void
ng_rgb24_to_lut2(unsigned char* restrict dest, unsigned char* restrict src,
		 int p)
{
    uint16_t* restrict d = (uint16_t*)dest;

    while (p-- > 0) {
	*(d++) = ng_lut_red[src[0]] | ng_lut_green[src[1]] |
	    ng_lut_blue[src[2]];
	src += 3;
    }
}

static void
bgr24_to_lut2(unsigned char* restrict dest, unsigned char* restrict src,
	      int p)
{
    uint16_t* restrict d = (uint16_t*)dest;

    while (p-- > 0) {
	*(d++) = ng_lut_red[src[2]] | ng_lut_green[src[1]] |
	    ng_lut_blue[src[0]];
	src += 3;
    }
}

static void
rgb32_to_lut2(unsigned char* restrict dest, unsigned char* restrict src,
	      int p)
{
    uint16_t* restrict d = (uint16_t*)dest;

    while (p-- > 0) {
	*(d++) = ng_lut_red[src[1]] | ng_lut_green[src[2]] |
	    ng_lut_blue[src[3]];
	src += 4;
    }
}

static void
bgr32_to_lut2(unsigned char* restrict dest, unsigned char* restrict src,
	      int p)
{
    uint16_t* restrict d = (uint16_t*)dest;

    while (p-- > 0) {
       *(d++) = ng_lut_red[src[2]] | ng_lut_green[src[1]] |
           ng_lut_blue[src[0]];
	src += 4;
    }
}

static void
gray_to_lut2(unsigned char* restrict dest, unsigned char* restrict src,
	     int p)
{
    uint16_t* restrict d = (uint16_t*)dest;

    while (p-- > 0) {
	*(d++) = ng_lut_red[*src] | ng_lut_green[*src] | ng_lut_blue[*src];
	src++;
    }
}

/* ------------------------------------------------------------------- */

void
ng_rgb24_to_lut4(unsigned char* restrict dest, unsigned char* restrict src,
		 int p)
{
    unsigned int* restrict d = (unsigned int*)dest;

    while (p-- > 0) {
	*(d++) = ng_lut_red[src[0]] | ng_lut_green[src[1]] |
	    ng_lut_blue[src[2]];
	src += 3;
    }
}

static void
bgr24_to_lut4(unsigned char* restrict dest, unsigned char* restrict src,
	      int p)
{
    unsigned int* restrict d = (unsigned int*)dest;

    while (p-- > 0) {
	*(d++) = ng_lut_red[src[2]] | ng_lut_green[src[1]] |
	    ng_lut_blue[src[0]];
	src += 3;
    }
}

static void
rgb32_to_lut4(unsigned char* restrict dest, unsigned char* restrict src,
	      int p)
{
    unsigned int* restrict d = (unsigned int*)dest;

    while (p-- > 0) {
	*(d++) = ng_lut_red[src[1]] | ng_lut_green[src[2]] |
	    ng_lut_blue[src[3]];
	src += 4;
    }
}

static void
bgr32_to_lut4(unsigned char* restrict dest, unsigned char* restrict src,
	      int p)
{
    unsigned int* restrict d = (unsigned int*)dest;

    while (p-- > 0) {
       *(d++) = ng_lut_red[src[2]] | ng_lut_green[src[1]] |
           ng_lut_blue[src[0]];
	src += 4;
    }
}

static void
gray_to_lut4(unsigned char* restrict dest, unsigned char* restrict src,
	     int p)
{
    unsigned int* restrict d = (unsigned int*)dest;

    while (p-- > 0) {
	*(d++) = ng_lut_red[*src] | ng_lut_green[*src] | ng_lut_blue[*src];
	src++;
    }
}

/* ------------------------------------------------------------------- */

static struct ng_video_conv lut2_list[] = {
    {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_RGB24,
	.priv		= ng_rgb24_to_lut2,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_BGR24,
	.priv		= bgr24_to_lut2,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_RGB32,
	.priv		= rgb32_to_lut2,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_BGR32,
	.priv		= bgr32_to_lut2,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_GRAY,
	.priv		= gray_to_lut2,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_YUYV,
	.priv		= ng_yuv422_to_lut2,
    },{
	.init           = ng_conv_nop_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.fini         = ng_conv_nop_fini,
	.p.frame        = ng_yuv422p_to_lut2,
	.fmtid_in	= VIDEO_YUV422P,
    },{
	.init           = ng_conv_nop_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.fini         = ng_conv_nop_fini,
	.p.frame        = ng_yuv420p_to_lut2,
	.fmtid_in	= VIDEO_YUV420P,
    }
};

static struct ng_video_conv lut4_list[] = {
    {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_RGB24,
	.priv		= ng_rgb24_to_lut4,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_BGR24,
	.priv		= bgr24_to_lut4,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_RGB32,
	.priv		= rgb32_to_lut4,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_BGR32,
	.priv		= bgr32_to_lut4,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_GRAY,
	.priv		= gray_to_lut4,
    }, {
	NG_GENERIC_PACKED,
	.fmtid_in	= VIDEO_YUYV,
	.priv		= ng_yuv422_to_lut4,
    },{
	.init           = ng_conv_nop_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.fini         = ng_conv_nop_fini,
	.p.frame        = ng_yuv422p_to_lut4,
	.fmtid_in	= VIDEO_YUV422P,
    },{
	.init           = ng_conv_nop_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.fini         = ng_conv_nop_fini,
	.p.frame        = ng_yuv420p_to_lut4,
	.fmtid_in	= VIDEO_YUV420P,
    }
};

static const unsigned int nconv2 = sizeof(lut2_list)/sizeof(lut2_list[0]);
static const unsigned int nconv4 = sizeof(lut4_list)/sizeof(lut4_list[0]);

static void init_one(int32_t *lut, int32_t mask)
{
    int bits  = 0;
    int shift = 0;
    int i;
    
    for (i = 0; i < 32; i++) {
        if (mask & ((int32_t)1 << i))
	    bits++;
        else if (!bits)
	    shift++;
    }
    
    if (bits > 8)
	for (i = 0; i < 256; i++)
	    lut[i] = (i << (bits + shift - 8));
    else
	for (i = 0; i < 256; i++)
	    lut[i] = (i >> (8 - bits)) << shift;
}

void
ng_lut_init(unsigned long red_mask, unsigned long green_mask,
	    unsigned long blue_mask, unsigned int fmtid, int swap)
{
    static int      once=0;
    unsigned int    i;
    
    if (once++) {
	fprintf(stderr,"panic: ng_lut_init called twice\n");
	return;
    }

    init_one(ng_lut_red,   red_mask);
    init_one(ng_lut_green, green_mask);
    init_one(ng_lut_blue,  blue_mask);

    switch (ng_vfmt_to_depth[fmtid]) {
    case 16:
	if (swap) {
	    for (i = 0; i < 256; i++) {
		ng_lut_red[i] = SWAP2(ng_lut_red[i]);
		ng_lut_green[i] = SWAP2(ng_lut_green[i]);
		ng_lut_blue[i] = SWAP2(ng_lut_blue[i]);
	    }
	}
	for (i = 0; i < nconv2; i++)
	    lut2_list[i].fmtid_out = fmtid;
	ng_conv_register(NG_PLUGIN_MAGIC,"built-in",lut2_list,nconv2);
	break;
    case 32:
	if (swap) {
	    for (i = 0; i < 256; i++) {
		ng_lut_red[i] = SWAP4(ng_lut_red[i]);
		ng_lut_green[i] = SWAP4(ng_lut_green[i]);
		ng_lut_blue[i] = SWAP4(ng_lut_blue[i]);
	    }
	}
	for (i = 0; i < nconv4; i++)
	    lut4_list[i].fmtid_out = fmtid;
	ng_conv_register(NG_PLUGIN_MAGIC,"built-in",lut4_list,nconv4);
	break;
    }
}
