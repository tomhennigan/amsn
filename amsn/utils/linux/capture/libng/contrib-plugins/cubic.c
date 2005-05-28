/* 
 * Simple xawtv deinterlacing plugin - cubic interpolation
 * 
 * CAVEATS: Effectively halves framerate, (working on it)
 * May cause some general slowness (uses more cpu) but the framerate is smooth
 * on my athlon 700, running the -mjc branch of 2.4 kernel (preempt and other
 * patches for desktop performance)
 * 
 * BENEFITS: It's no longer interlaced ;)
 * Looks a metric shitton better than line doubling & bilinear interpolation
 * around text, but these nasty white specks occur on the border of pure black
 * (0) and pure white (255).  My original theory was that it had something to
 * do with 0 messing up our multiplication, but that does not appear to be the
 * case based on preliminary fiddling around.
 * 
 * AUTHORS:
 * Conrad Kreyling <conrad@conrad.nerdland.org>
 * Patrick Barrett <yebyen@nerdland.org>
 * 
 * This is licenced under the GNU GPL until someone tells me I'm stealing code
 * and can't do that ;) www.gnu.org for any version of the license.
 *
 * Based on xawtv-3.66/libng/plugins/flt-nop.c (also GPL)
 * Cubic deinterlacing algorithm adapted from mplayer's libpostproc
 */


#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include "grab-ng.h"

/*static int isOdd; // Global variable so we can tell if a frame uses even or
                  //odd scanlines, not implemented properly yet */

static void inline
deinterlace (struct ng_video_buf *frame)
{
  unsigned int x, y, bytes = frame->fmt.bytesperline;

  /*
   * if(isOdd){
   *     isOdd=0;
   *     y=3;
   * }
   * else
   * {
   *     isOdd=1;
   *     y=4;
   * } //Set y based on scanline evenness/oddness, not implemented yet
   */

 /* for (x=0; x < strlen(frame->data); x++){
	 switch (frame->data[x])
	 {
	   case 0:
		  frame->data[x]++;
		  break;
	   case 255:
		  frame->data[x]--;
		  break;		  
	 }
  }*/ // This doesn't work to fix the problem with the specks
  
  for (y = 3; y < frame->fmt.height - 3; y += 2)
  {
	 for (x = 0; x < bytes; x++)
	 {
		frame->data[(y * bytes + x)] =
		   ((-frame->data[((y - 3) * bytes + x)]) +
			(9 * frame->data[((y - 1) * bytes + x)]) +
			(9 * frame->data[((y + 1) * bytes + x)]) +
			(-frame->data[((y + 3) * bytes + x)])) >> 4;
	 } // Basic algorithm borrowed from mplayer's libpostproc
  }	// Angry math
}


static void *
init (struct ng_video_fmt *out)
{
  /* we will be using this variable soon enough */
  static int isOdd = 0;
  return &isOdd;
}

static struct ng_video_buf *
frame (void *handle, struct ng_video_buf *frame)
{
  deinterlace (frame);
  return frame;
}

static void
fini (void *handle)
{
  /* nothing to clean up */
}

/* ------------------------------------------------------------------- */

static struct ng_filter filter = {
  name:"cubic interpolation",
  fmts:
    (1 << VIDEO_GRAY)			|
    (1 << VIDEO_RGB15_NATIVE)		|
    (1 << VIDEO_RGB16_NATIVE)		|
    (1 << VIDEO_BGR24)			|
    (1 << VIDEO_RGB24)			|
    (1 << VIDEO_BGR32)			|
    (1 << VIDEO_RGB32)			|
    (1 << VIDEO_YUYV)			|
    (1 << VIDEO_UYVY),
  init:		init,
  frame:	frame,
  fini:		fini,
};

extern void ng_plugin_init (void);
void
ng_plugin_init (void)
{
  ng_filter_register (NG_PLUGIN_MAGIC,__FILE__,&filter);
}
