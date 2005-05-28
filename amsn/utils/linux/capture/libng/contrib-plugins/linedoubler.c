/* 
 * Simple xawtv deinterlacing plugin - line doubling
 * 
 * CAVEATS: Effectively halves framerate and vertical resolution
 * Framerate problem is to be addressed, vertical resolution problem is
 * inherent in line doubling.  Use one of the interpolating (or blending, when
 * we write them) filters.
 * 
 * BENEFITS: It's no longer interlaced ;) thats about it.
 * 
 * AUTHORS:
 * Conrad Kreyling <conrad@conrad.nerdland.org>
 * Patrick Barrett <yebyen@nerdland.org>
 * 
 * This is licenced under the GNU GPL until someone tells me I'm stealing code
 * and can't do that ;) www.gnu.org for any version of the license.
 *
 * Based on xawtv-3.67/libng/plugins/flt-nop.c (also GPL)
 */


#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include "grab-ng.h"

static void inline
deinterlace(struct ng_video_buf *frame)
{
   unsigned int x,y;
   
   for (y = 1; y < frame->fmt.height; y += 2)
	  for (x = 0; x < frame->fmt.bytesperline + 1; x++)
		 frame->data[(y * frame->fmt.bytesperline) + x] = 
			frame->data[((y - 1) * frame->fmt.bytesperline) + x];
}


static void *init(struct ng_video_fmt *out)
{
    /* don't have to carry around status info */
    static int dummy;
    return &dummy;
}

static struct ng_video_buf*
frame(void *handle, struct ng_video_buf *frame)
{
   deinterlace(frame); // In hindsight, we may not have needed the function ;)
					   // Added clarity when we make it more complicated.
   return frame;
}

static void fini(void *handle)
{
    /* nothing to clean up */
}

/* ------------------------------------------------------------------- */

static struct ng_filter filter = {
    name:    "line doubler deinterlace",
    fmts:
    (1 << VIDEO_GRAY)         |
    (1 << VIDEO_RGB15_NATIVE) |
    (1 << VIDEO_RGB16_NATIVE) |
    (1 << VIDEO_BGR24)        |
    (1 << VIDEO_RGB24)        |
    (1 << VIDEO_BGR32)        |
    (1 << VIDEO_RGB32)        |
    (1 << VIDEO_YUYV)         |
    (1 << VIDEO_UYVY),
    init:    init,
    frame:   frame,
    fini:    fini,
};

extern void ng_plugin_init(void);
void ng_plugin_init(void)
{
    ng_filter_register(NG_PLUGIN_MAGIC,__FILE__,&filter);
}
