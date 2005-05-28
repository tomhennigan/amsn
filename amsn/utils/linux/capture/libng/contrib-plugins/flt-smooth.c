/*
 * libng filter -- Smooth the image to reduce snow at bad TV receiption
 *
 *
 * Filter options
 * --------------
 *
 * There are 2 options available that can be turned on and off separately.
 *
 * Smooth over time:    Calculate average of previous and current frame.
 *                      Longer filter lengths could improve static
 *                      images but would be unusable for movies and
 *                      require high CPU power. I found averaging of
 *                      2 frames the most useful filter.
 *
 * Smooth horizontally: For every pixel, the average of the actual colour
 *                      and the colour of the pixel to the left is displayed.
 *
 *
 * (c) 2002  Klaus Peichl <pei@freenet.de> (smoothing filter),
 *           Gerd Knorr <kraxel@bytesex.org> (framework)
 *
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include "grab-ng.h"

/* ------------------------------------------------------------------- */

typedef struct {
  struct ng_video_buf * pLastFrame;
}
SMOOTH_BUFFER;


static int smoothTime = 1;
static int smoothHorizontal = 1;


static void inline
invert_bytes(unsigned char *dst, unsigned char *src, int bytes)
{
    while (bytes--)
	*(dst++) = 0xff - *(src++);
}


#if 1

/*
  Fast 32-bit smoothing
*/
static void inline
smooth_native_32bit(unsigned int *last,
		    unsigned int *dst,
		    unsigned int *src,
		    int pixels)
{
  unsigned int  old,new, old2,new2;

  if (smoothTime && smoothHorizontal) {

    /* Smoothing in time and horizontally */

    old2 = *last;
    new2 = *src;

    while (pixels--) {

      old = *last;
      new = *src++;
      *last++ = new;

      /*
	Fast averaging:
	All 4 bytes (of which only 3 are used) can be averaged in one 32bit-word.
	The lowest 2 bits of every colour are thrown away to avoid influences
	between the colours.
      */

      *dst++ =
	((new >> 2) & 0x3F3F3F3F) +
	((new2 >> 2) & 0x3F3F3F3F) +
	((old >> 2) & 0x3F3F3F3F) +
	((old2 >> 2) & 0x3F3F3F3F);

      old2 = old;
      new2 = new;
    }
  }
  else if (smoothTime) {

    /* Smoothing in time only */

    while (pixels--) {

      old = *last;
      new = *src++;
      *last++ = new;

      /*
	Fast averaging:
	All 4 bytes (of which only 3 are used) can be averaged in one 32bit-word.
	The lowest bit of every colour is thrown away to avoid influences
	between the colours.
      */

      *dst++ =
	((new >> 1) & 0x7F7F7F7F) +
	((old >> 1) & 0x7F7F7F7F);
    }
  }
  else if (smoothHorizontal) {

    /* Smooth horizontally only */

    new2 = *src;

    while (pixels--) {

      new = *src++;
      *last++ = new;

      /*
	Fast averaging:
	All 4 bytes (of which only 3 are used) can be averaged in one 32bit-word.
	The lowest bit of every colour is thrown away to avoid influences
	between the colours.
      */

      *dst++ =
	((new >> 1) & 0x7F7F7F7F) +
	((new2 >> 1) & 0x7F7F7F7F);

      new2 = new;
    }
  }
  else {

    /* No smoothing at all */

    while (pixels--) {
      new = *src++;
      *last++ = new;
      *dst++ = new;
    }
  }
}

#else

/*
  This is an alternative implementation of the above function
  which does not throw away the lowest bits before addition.
  It is derived from the byte-based 24-bit-function below but
  processes 4 bytes for every pixel instead of 3.
*/

static void inline
smooth_native_32bit(unsigned char *last,
		    unsigned char *dst,
		    unsigned char *src,
		    int pixels)
{
  unsigned char  oldR,newR, oldR2,newR2;
  unsigned char  oldG,newG, oldG2,newG2;
  unsigned char  oldB,newB, oldB2,newB2;
  unsigned char  oldP,newP, oldP2,newP2;

  if (smoothTime && smoothHorizontal) {

    /* Smoothing in time and horizontally */

    oldR2 = last[0];
    oldG2 = last[1];
    oldB2 = last[2];
    oldP2 = last[3];
    newR2 = src[0];
    newG2 = src[1];
    newB2 = src[2];
    newP2 = src[3];

    while (pixels--) {

      oldR = *last;  newR = *src++;  *last++ = newR;
      oldG = *last;  newG = *src++;  *last++ = newG;
      oldB = *last;  newB = *src++;  *last++ = newB;
      oldP = *last;  newP = *src++;  *last++ = newP;

      *dst++ = (newR + oldR + newR2 + oldR2) / 4;
      *dst++ = (newG + oldG + newG2 + oldG2) / 4;
      *dst++ = (newB + oldB + newB2 + oldB2) / 4;
      *dst++ = (newP + oldP + newP2 + oldP2) / 4;

      oldR2 = oldR;
      oldG2 = oldG;
      oldB2 = oldB;
      oldP2 = oldP;

      newR2 = newR;
      newG2 = newG;
      newB2 = newB;
      newP2 = newP;
    }
  }
  else if (smoothTime) {

    /* Smoothing in time only */

    while (pixels--) {

      oldR = *last;  newR = *src++;  *last++ = newR;
      oldG = *last;  newG = *src++;  *last++ = newG;
      oldB = *last;  newB = *src++;  *last++ = newB;
      oldP = *last;  newP = *src++;  *last++ = newP;

      *dst++ = (newR + oldR) / 2;
      *dst++ = (newG + oldG) / 2;
      *dst++ = (newB + oldB) / 2;
      *dst++ = (newP + oldP) / 2;
    }
  }
  else if (smoothHorizontal) {

    /* Smooth horizontally only */

    newR2 = src[0];
    newG2 = src[1];
    newB2 = src[2];
    newP2 = src[3];

    while (pixels--) {

      newR = *src++;  *last++ = newR;
      newG = *src++;  *last++ = newG;
      newB = *src++;  *last++ = newB;
      newP = *src++;  *last++ = newP;

      *dst++ = (newR + newR2) / 2;
      *dst++ = (newG + newG2) / 2;
      *dst++ = (newB + newB2) / 2;
      *dst++ = (newP + newP2) / 2;

      newR2 = newR;
      newG2 = newG;
      newB2 = newB;
      newP2 = newP;
    }
  }
  else {

    /* No smoothing at all */

    while (pixels--) {
      newR = *src++;  *last++ = newR;  *dst++ = newR;
      newG = *src++;  *last++ = newG;  *dst++ = newG;
      newB = *src++;  *last++ = newB;  *dst++ = newB;
      newP = *src++;  *last++ = newP;  *dst++ = newP;

    }
  }
}
#endif


static void inline
smooth_native_24bit(unsigned char *last,
		    unsigned char *dst,
		    unsigned char *src,
		    int pixels)
{
  unsigned char  oldR,newR, oldR2,newR2;
  unsigned char  oldG,newG, oldG2,newG2;
  unsigned char  oldB,newB, oldB2,newB2;

  if (smoothTime && smoothHorizontal) {

    /* Smoothing in time and horizontally */

    oldR2 = last[0];
    oldG2 = last[1];
    oldB2 = last[2];
    newR2 = src[0];
    newG2 = src[1];
    newB2 = src[2];

    while (pixels--) {

      oldR = *last;  newR = *src++;  *last++ = newR;
      oldG = *last;  newG = *src++;  *last++ = newG;
      oldB = *last;  newB = *src++;  *last++ = newB;

      *dst++ = (newR + oldR + newR2 + oldR2) / 4;
      *dst++ = (newG + oldG + newG2 + oldG2) / 4;
      *dst++ = (newB + oldB + newB2 + oldB2) / 4;

      oldR2 = oldR;
      oldG2 = oldG;
      oldB2 = oldB;

      newR2 = newR;
      newG2 = newG;
      newB2 = newB;
    }
  }
  else if (smoothTime) {

    /* Smoothing in time only */

    while (pixels--) {

      oldR = *last;  newR = *src++;  *last++ = newR;
      oldG = *last;  newG = *src++;  *last++ = newG;
      oldB = *last;  newB = *src++;  *last++ = newB;

      *dst++ = (newR + oldR) / 2;
      *dst++ = (newG + oldG) / 2;
      *dst++ = (newB + oldB) / 2;
    }
  }
  else if (smoothHorizontal) {

    /* Smooth horizontally only */

    newR2 = src[0];
    newG2 = src[1];
    newB2 = src[2];

    while (pixels--) {

      newR = *src++;  *last++ = newR;
      newG = *src++;  *last++ = newG;
      newB = *src++;  *last++ = newB;

      *dst++ = (newR + newR2) / 2;
      *dst++ = (newG + newG2) / 2;
      *dst++ = (newB + newB2) / 2;

      newR2 = newR;
      newG2 = newG;
      newB2 = newB;
    }
  }
  else {

    /* No smoothing at all */

    while (pixels--) {
      newR = *src++;  *last++ = newR;  *dst++ = newR;
      newG = *src++;  *last++ = newG;  *dst++ = newG;
      newB = *src++;  *last++ = newB;  *dst++ = newB;

    }
  }
}


static void inline
smooth_native_16bit(unsigned short *last,
		    unsigned short *dst,
		    unsigned short *src,
		    unsigned short maskR,
		    unsigned short maskG,
		    unsigned short maskB,
		    int pixels)
{
  unsigned short  old,new, old2,new2;
  unsigned short  red,green,blue;

  if (smoothTime && smoothHorizontal) {

    /* Smoothing in time and horizontally */

    old2 = *last;
    new2 = *src;

    while (pixels--) {

      old = *last;
      new = *src++;
      *last++ = new;

      red   = ( ((new & maskR) + (old & maskR) + (new2 & maskR) + (old2 & maskR))/4 ) & maskR;
      green = ( ((new & maskG) + (old & maskG) + (new2 & maskG) + (old2 & maskG))/4 ) & maskG;
      blue  = ( ((new & maskB) + (old & maskB) + (new2 & maskB) + (old2 & maskB))/4 ) & maskB;
      *dst++ = red | green | blue;

      old2 = old;
      new2 = new;
    }
  }
  else if (smoothTime) {

    /* Smoothing in time only */

    while (pixels--) {

      old = *last;
      new = *src++;
      *last++ = new;

      red   = ( ((new & maskR) + (old & maskR))/2 ) & maskR;
      green = ( ((new & maskG) + (old & maskG))/2 ) & maskG;
      blue  = ( ((new & maskB) + (old & maskB))/2 ) & maskB;
      *dst++ = red | green | blue;
    }
  }
  else if (smoothHorizontal) {

    /* Smooth horizontally only */

    new2 = *src;

    while (pixels--) {

      new = *src++;
      *last++ = new;

      red   = ( ((new & maskR) + (new2 & maskR))/2 ) & maskR;
      green = ( ((new & maskG) + (new2 & maskG))/2 ) & maskG;
      blue  = ( ((new & maskB) + (new2 & maskB))/2 ) & maskB;
      *dst++ = red | green | blue;

      new2 = new;
    }
  }
  else {

    /* No smoothing at all */

    while (pixels--) {
      new = *src++;
      *last++ = new;
      *dst++ = new;
    }
  }
}


/* ------------------------------------------------------------------- */

static void *init(struct ng_video_fmt *out)
{
    /* don't have to carry around status info */
    static SMOOTH_BUFFER smooth_buffer;

    smooth_buffer.pLastFrame = ng_malloc_video_buf(NULL, out);
    return &smooth_buffer;
}

static void
frame(void *h, struct ng_video_buf *out, struct ng_video_buf *in)
{
    SMOOTH_BUFFER *handle = h;
    unsigned char *dst;
    unsigned char *src;
    unsigned char *last;
    unsigned int y,cnt;

    dst = out->data;
    src = in->data;
    last = handle->pLastFrame->data;
    cnt = in->fmt.width * ng_vfmt_to_depth[in->fmt.fmtid] / 8;

    for (y = 0; y < in->fmt.height; y++) {
	switch (in->fmt.fmtid) {
	case VIDEO_GRAY:
	case VIDEO_BGR24:
	case VIDEO_RGB24:
	    smooth_native_24bit((unsigned char*)last,
				(unsigned char*)dst,
				(unsigned char*)src,
				in->fmt.width);
	    break;
	case VIDEO_BGR32:
	case VIDEO_RGB32:
	case VIDEO_YUYV:
	case VIDEO_UYVY:
	    smooth_native_32bit((unsigned int*)last,
				(unsigned int*)dst,
				(unsigned int*)src,
				in->fmt.width);
	    break;
	case VIDEO_RGB15_NATIVE:
	    smooth_native_16bit((unsigned short*)last,
				(unsigned short*)dst,
				(unsigned short*)src,
				0x7C00,  /* mask for red */
				0x03E0,  /* mask for green */
				0x001F,  /* mask for blue */
				in->fmt.width);
	    break;
	case VIDEO_RGB16_NATIVE:
	    smooth_native_16bit((unsigned short*)last,
				(unsigned short*)dst,
				(unsigned short*)src,
				0xF800,  /* mask for red */
				0x07E0,  /* mask for green */
				0x001F,  /* mask for blue */
				in->fmt.width);
	    break;
	}
	dst  += out->fmt.bytesperline ? out->fmt.bytesperline : cnt;
	src  += in->fmt.bytesperline  ? in->fmt.bytesperline  : cnt;
	last += in->fmt.bytesperline  ? in->fmt.bytesperline  : cnt;
    }
}

static void fini(void *handle)
{
  ng_release_video_buf(handle);
}


static int read_attr(struct ng_attribute *attr)
{
  int value;

  switch (attr->id) {
  case 0:
    value = smoothTime;
    break;
  case 1:
    value = smoothHorizontal;
    break;
  default:
    value = 0;
  }

  return value;
}

static void write_attr(struct ng_attribute *attr, int value)
{
  switch (attr->id) {
  case 0:
    smoothTime = value;
    break;
  case 1:
    smoothHorizontal = value;
    break;
  }
}


/* ------------------------------------------------------------------- */

static struct ng_attribute attrs[] = {
    {
	.id       = 0,
	.name     = "smooth over time",
	.type     = ATTR_TYPE_BOOL,
	.defval   = 1,
	.read     = read_attr,
	.write    = write_attr,
    },{
	.id       = 1,
	.name     = "smooth horizontally",
	.type     = ATTR_TYPE_BOOL,
	.defval   = 1,
	.read     = read_attr,
	.write    = write_attr,
    },{
	/* end of list */
    }
};



static struct ng_video_filter filter = {
    .name      = "smooth",
    .attrs     = attrs,
    .fmts      = (
	(1 << VIDEO_GRAY)         |
	(1 << VIDEO_RGB15_NATIVE) |
	(1 << VIDEO_RGB16_NATIVE) |
	(1 << VIDEO_BGR24)        |
	(1 << VIDEO_RGB24)        |
	(1 << VIDEO_BGR32)        |
	(1 << VIDEO_RGB32)        |
	(1 << VIDEO_YUYV)         |
	(1 << VIDEO_UYVY)),
    .init      = init,
    .p.mode    = NG_MODE_TRIVIAL,
    .p.frame   = frame,
    .p.fini    = fini,
};

static void __init plugin_init(void)
{
    if (0)
	/* FIXME: semms to be broken ... */
	ng_filter_register(NG_PLUGIN_MAGIC,__FILE__,&filter);
}
