/* 
 * Simple xawtv deinterlacing plugin - linear blend
 * 
 * CAVEATS: Still some interlacing effects in high motion perhaps
 * Some ghosting in instant transitions, slightly noticeable
 * 
 * BENEFITS: NO DROP IN FRAMERATE =]
 * Looks absolutely beautiful
 * Doesn't lower framerate
 * Oh and did I mention it doesn't lower framerate?
 * Plus, its MMX'itized now, so it really doesn't lower framerate.
 *
 * AUTHORS:
 * Conrad Kreyling <conrad@conrad.nerdland.org>
 * Patrick Barrett <yebyen@nerdland.org>
 *
 * This is licenced under the GNU GPL until someone tells me I'm stealing code
 * and can't do that ;) www.gnu.org for any version of the license.
 *
 * Based on xawtv-3.72/libng/plugins/flt-nop.c (also GPL)
 * Linear blend deinterlacing algorithm adapted from mplayer's libpostproc
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include "grab-ng.h"

#define PAVGB(a,b)  "pavgb " #a ", " #b " \n\t"

#ifdef MMX
#define emms()                  __asm__ __volatile__ ("emms")
#else
#define emms()
#endif

static inline void linearBlend(unsigned char *src, int stride)
{
#ifdef MMX
  asm volatile(
       "leal (%0, %1), %%eax                           \n\t"
       "leal (%%eax, %1, 4), %%edx                     \n\t"

       "movq (%0), %%mm0                               \n\t" // L0
       "movq (%%eax, %1), %%mm1                        \n\t" // L2
       PAVGB(%%mm1, %%mm0)                                   // L0+L2
       "movq (%%eax), %%mm2                            \n\t" // L1
       PAVGB(%%mm2, %%mm0)
       "movq %%mm0, (%0)                               \n\t"
       "movq (%%eax, %1, 2), %%mm0                     \n\t" // L3
       PAVGB(%%mm0, %%mm2)                                   // L1+L3
       PAVGB(%%mm1, %%mm2)                                   // 2L2 + L1 + L3
       "movq %%mm2, (%%eax)                            \n\t"
       "movq (%0, %1, 4), %%mm2                        \n\t" // L4
       PAVGB(%%mm2, %%mm1)                                   // L2+L4
       PAVGB(%%mm0, %%mm1)                                   // 2L3 + L2 + L4
       "movq %%mm1, (%%eax, %1)                        \n\t"
       "movq (%%edx), %%mm1                            \n\t" // L5
       PAVGB(%%mm1, %%mm0)                                   // L3+L5
       PAVGB(%%mm2, %%mm0)                                   // 2L4 + L3 + L5
       "movq %%mm0, (%%eax, %1, 2)                     \n\t"
       "movq (%%edx, %1), %%mm0                        \n\t" // L6
       PAVGB(%%mm0, %%mm2)                                   // L4+L6
       PAVGB(%%mm1, %%mm2)                                   // 2L5 + L4 + L6
       "movq %%mm2, (%0, %1, 4)                        \n\t"
       "movq (%%edx, %1, 2), %%mm2                     \n\t" // L7
       PAVGB(%%mm2, %%mm1)                                   // L5+L7
       PAVGB(%%mm0, %%mm1)                                   // 2L6 + L5 + L7
       "movq %%mm1, (%%edx)                            \n\t"
       "movq (%0, %1, 8), %%mm1                        \n\t" // L8
       PAVGB(%%mm1, %%mm0)                                   // L6+L8
       PAVGB(%%mm2, %%mm0)                                   // 2L7 + L6 + L8
       "movq %%mm0, (%%edx, %1)                        \n\t"
       "movq (%%edx, %1, 4), %%mm0                     \n\t" // L9
       PAVGB(%%mm0, %%mm2)                                   // L7+L9
       PAVGB(%%mm1, %%mm2)                                   // 2L8 + L7 + L9
       "movq %%mm2, (%%edx, %1, 2)                     \n\t"

       : : "r" (src), "r" (stride)
       : "%eax", "%edx"
  );
  emms();
#else
  int x;
  for (x=0; x<8; x++)
  {
     src[0       ] = (src[0       ] + 2*src[stride  ] + src[stride*2])>>2;
     src[stride  ] = (src[stride  ] + 2*src[stride*2] + src[stride*3])>>2;
     src[stride*2] = (src[stride*2] + 2*src[stride*3] + src[stride*4])>>2;
     src[stride*3] = (src[stride*3] + 2*src[stride*4] + src[stride*5])>>2;
     src[stride*4] = (src[stride*4] + 2*src[stride*5] + src[stride*6])>>2;
     src[stride*5] = (src[stride*5] + 2*src[stride*6] + src[stride*7])>>2;
     src[stride*6] = (src[stride*6] + 2*src[stride*7] + src[stride*8])>>2;
     src[stride*7] = (src[stride*7] + 2*src[stride*8] + src[stride*9])>>2;

     src++;
  }
#endif
}

static void inline
deinterlace (struct ng_video_buf *frame)
{
  unsigned int x, y, bytes = frame->fmt.bytesperline;
  unsigned char *src;

  for (y = 1; y < frame->fmt.height - 8; y+=8)
  {
        for (x = 0; x < bytes; x+=8)
        {
            src = frame->data + x + y * bytes;
            linearBlend(src, bytes);
        } 
  }

  emms();
}


static void *
init (struct ng_video_fmt *out)
{
  /* no status info needed */
  static int dummy; 
  return &dummy;
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
  name:"linear blend",
  fmts:
    (1 << VIDEO_GRAY) |
    (1 << VIDEO_RGB15_NATIVE) |
    (1 << VIDEO_RGB16_NATIVE) |
    (1 << VIDEO_BGR24) |
    (1 << VIDEO_RGB24) |
    (1 << VIDEO_BGR32) |
    (1 << VIDEO_RGB32) |
    (1 << VIDEO_YUYV)  |
    (1 << VIDEO_UYVY),
  init:init,
  frame:frame,
  fini:fini,
};

extern void ng_plugin_init (void);
void
ng_plugin_init (void) 
{
  ng_filter_register (NG_PLUGIN_MAGIC,__FILE__,&filter);
}

