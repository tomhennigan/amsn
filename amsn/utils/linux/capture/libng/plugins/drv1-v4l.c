/*
 * interface to the v4l driver
 *
 *   (c) 1997-2004 Gerd Knorr <kraxel@bytesex.org>
 *
 */
#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <signal.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include "videodev.h"

#include "grab-ng.h"

#include "struct-dump.h"
#include "struct-v4l.h"

#define SYNC_TIMEOUT 5

/* ---------------------------------------------------------------------- */

/* open+close */
static void*   v4l_init(char *device);
static int     v4l_open(void *handle);
static int     v4l_close(void *handle);
static int     v4l_fini(void *handle);

static char*   v4l_devname(void *handle);
static struct ng_devinfo* v4l_probe(int verbose);

/* attributes */
static int     v4l_flags(void *handle);
static struct ng_attribute* v4l_attrs(void *handle);
static int     v4l_read_attr(struct ng_attribute*);
static void    v4l_write_attr(struct ng_attribute*, int val);

#if 0
/* overlay */
static int   v4l_setupfb(void *handle, struct ng_video_fmt *fmt, void *base);
static int   v4l_overlay(void *handle, struct ng_video_fmt *fmt, int x, int y,
			 struct OVERLAY_CLIP *oc, int count, int aspect);
#endif

/* capture video */
static int v4l_setformat(void *handle, struct ng_video_fmt *fmt);
static int v4l_startvideo(void *handle, int fps, unsigned int buffers);
static void v4l_stopvideo(void *handle);
static struct ng_video_buf* v4l_nextframe(void *handle);
static struct ng_video_buf* v4l_getimage(void *handle);

/* tuner */
static unsigned long v4l_getfreq(void *handle);
static void v4l_setfreq(void *handle, unsigned long freq);
static int v4l_tuned(void *handle);

/* ---------------------------------------------------------------------- */

static const char *device_cap[] = {
    "capture", "tuner", "teletext", "overlay", "chromakey", "clipping",
    "frameram", "scales", "monochrome", NULL
};

static const char *device_pal[] = {
    "-", "grey", "hi240", "rgb16", "rgb24", "rgb32", "rgb15",
    "yuv422", "yuyv", "uyvy", "yuv420", "yuv411", "raw",
    "yuv422p", "yuv411p", "yuv420p", "yuv410p"
};
#define PALETTE(x) ((x < sizeof(device_pal)/sizeof(char*)) ? device_pal[x] : "UNKNOWN")

static struct STRTAB stereo[] = {
    {  0,                  "auto"    },
    {  VIDEO_SOUND_MONO,   "mono"    },
    {  VIDEO_SOUND_STEREO, "stereo"  },
    {  VIDEO_SOUND_LANG1,  "lang1"   },
    {  VIDEO_SOUND_LANG2,  "lang2"   },
    { -1, NULL },
};
static struct STRTAB norms_v4l[] = {
    {  VIDEO_MODE_PAL,     "PAL"   },
    {  VIDEO_MODE_NTSC,    "NTSC"  },
    {  VIDEO_MODE_SECAM,   "SECAM" },
    {  VIDEO_MODE_AUTO,    "AUTO"  },
    { -1, NULL }
};
static struct STRTAB norms_bttv[] = {
    {  VIDEO_MODE_PAL,   "PAL"     },
    {  VIDEO_MODE_NTSC,  "NTSC"    },
    {  VIDEO_MODE_SECAM, "SECAM"   },
    {  3,                "PAL-NC"  },
    {  4,                "PAL-M"   },
    {  5,                "PAL-N"   },
    {  6,                "NTSC-JP" },
    { -1, NULL }
};

static unsigned short format2palette[VIDEO_FMT_COUNT] = {
    [ VIDEO_RGB08 ]    = VIDEO_PALETTE_HI240,
    [ VIDEO_GRAY ]     = VIDEO_PALETTE_GREY,
    [ VIDEO_RGB15_LE ] = VIDEO_PALETTE_RGB555,
    [ VIDEO_RGB16_LE ] = VIDEO_PALETTE_RGB565,
    [ VIDEO_BGR24 ]    = VIDEO_PALETTE_RGB24,
    [ VIDEO_BGR32 ]    = VIDEO_PALETTE_RGB32,
    [ VIDEO_YUYV ]     = VIDEO_PALETTE_YUV422,
    [ VIDEO_UYVY ]     = VIDEO_PALETTE_UYVY,
    [ VIDEO_YUV422P ]  = VIDEO_PALETTE_YUV422P,
    [ VIDEO_YUV420P ]  = VIDEO_PALETTE_YUV420P,
};

#if 0
/* pass 0/1 by reference */
static int                      one = 1, zero = 0;
#endif

/* ---------------------------------------------------------------------- */

struct v4l_handle {
    int                      fd;
    char                     *device;

    /* general informations */
    struct video_capability  capability;
    struct video_channel     *channels;
    struct video_tuner       tuner;
    struct video_audio       audio;
    struct video_picture     pict;

    /* attributes */
    int                      nattr;
    struct ng_attribute      *attr;
    int                      input;
    int                      audio_mode;
    
    /* overlay */
    struct video_buffer      fbuf;
    struct video_window      win;
    int                      ov_error;
    unsigned int             ov_fmtid;
    int                      ov_enabled;
    int                      ov_on;

    /* capture */
    int                      use_read;
    int                      rw;
    struct ng_video_fmt      fmt;
    long long                start;
    int                      fps;
    
    /* capture via read() */
    struct ng_video_fmt      rd_fmt;
    struct video_window      rd_win;
    unsigned int             rd_fmtid;
    
    /* capture to mmap()'ed buffers */
    struct video_mbuf        mbuf;
    unsigned char            *mmap;
    unsigned int             nbuf;
    unsigned int             queue;
    unsigned int             waiton;
    int                      probe[VIDEO_FMT_COUNT];
    struct video_mmap        *buf_v4l;
    struct ng_video_buf      *buf_me;
};

struct ng_vid_driver v4l_driver = {
    .name          = "v4l",
    .priority      = 2,
    
    .init          = v4l_init,
    .open          = v4l_open,
    .close         = v4l_close,
    .fini          = v4l_fini,
    .devname       = v4l_devname,
    .probe         = v4l_probe,
    
    .capabilities  = v4l_flags,
    .list_attrs    = v4l_attrs,

#if 0
    .setupfb       = v4l_setupfb,
    .overlay       = v4l_overlay,
#endif
    
    .setformat     = v4l_setformat,
    .startvideo    = v4l_startvideo,
    .stopvideo     = v4l_stopvideo,
    .nextframe     = v4l_nextframe,
    .getimage      = v4l_getimage,
    
    .getfreq       = v4l_getfreq,
    .setfreq       = v4l_setfreq,
    .is_tuned      = v4l_tuned,
};

/* ---------------------------------------------------------------------- */

static int alarms;

static void
sigalarm(int signal)
{
    alarms++;
    fprintf(stderr,"v4l: timeout (got SIGALRM), hardware/driver problems?\n");
}

static void
siginit(void)
{
    struct sigaction act,old;
    
    memset(&act,0,sizeof(act));
    act.sa_handler  = sigalarm;
    sigemptyset(&act.sa_mask);
    sigaction(SIGALRM,&act,&old);
}

/* ---------------------------------------------------------------------- */

#define PREFIX "ioctl: "

static int
xioctl(int fd, int cmd, void *arg)
{
    int rc;

    rc = ioctl(fd,cmd,arg);
    if (0 == rc && ng_debug < 2)
	return 0;
    print_ioctl(stderr,ioctls_v4l1,PREFIX,cmd,arg);
    fprintf(stderr,": %s\n",(rc == 0) ? "ok" : strerror(errno));
    return rc;
}

/* ---------------------------------------------------------------------- */

static void
v4l_add_attr(struct v4l_handle *h, int id, int type,
	     int defval, struct STRTAB *choices)
{
    h->attr = realloc(h->attr,(h->nattr+2) * sizeof(struct ng_attribute));
    memset(h->attr+h->nattr,0,sizeof(struct ng_attribute)*2);
    h->attr[h->nattr].id       = id;
    h->attr[h->nattr].priority = 2;
    h->attr[h->nattr].type     = type;
    h->attr[h->nattr].defval   = defval;
    h->attr[h->nattr].choices  = choices;
    if (ATTR_TYPE_INTEGER == type) {
	h->attr[h->nattr].min  = 0;
	h->attr[h->nattr].max  = 65535;
    }
    if (id < ATTR_ID_COUNT)
	h->attr[h->nattr].name = ng_attr_to_desc[id];

    h->attr[h->nattr].read     = v4l_read_attr;
    h->attr[h->nattr].write    = v4l_write_attr;
    h->attr[h->nattr].handle   = h;
    h->nattr++;
}

static void
v4l_buffer_map(struct v4l_handle *h)
{
    int i, flags;
    
    if (0 == xioctl(h->fd,VIDIOCGMBUF,&h->mbuf)) {
	if (ng_debug)
	    fprintf(stderr,"  mbuf: size=%d frames=%d\n",
		    h->mbuf.size,h->mbuf.frames);
	flags = PROT_READ;
	if (h->rw)
	  flags |= PROT_WRITE;
	h->mmap = mmap(0,h->mbuf.size, flags,
		       MAP_SHARED,h->fd,0);
	if (MAP_FAILED == h->mmap)
	    perror("mmap");
    } else {
	h->mmap = MAP_FAILED;
    }
    if (MAP_FAILED != h->mmap) {
	if (ng_debug)
	    fprintf(stderr,"  v4l: using mapped buffers for capture\n");
	h->use_read = 0;
	h->nbuf = h->mbuf.frames;
	h->buf_v4l = malloc(h->nbuf * sizeof(struct video_mmap));
	memset(h->buf_v4l,0,h->nbuf * sizeof(struct video_mmap));
	h->buf_me = malloc(h->nbuf * sizeof(struct ng_video_buf));
	for (i = 0; i < h->nbuf; i++) {
	    ng_init_video_buf(h->buf_me+i);
	    h->buf_me[i].release = ng_wakeup_video_buf;
	}
    } else {
	if (ng_debug)
	    fprintf(stderr,"  v4l: using read() for capture\n");
	h->use_read = 1;
    }
}

static void
v4l_buffer_unmap(struct v4l_handle *h)
{
    if (MAP_FAILED != h->mmap) {
	munmap(h->mmap,h->mbuf.size);
	free(h->buf_v4l);
	free(h->buf_me);
	h->buf_v4l = NULL;
	h->buf_me  = NULL;
	h->nbuf    = 0;
	h->mmap    = MAP_FAILED;
    } else {
	h->use_read = 0;
    }
}

/* ---------------------------------------------------------------------- */

static int
v4l_open(void *handle)
{
    struct v4l_handle *h = handle;

    if (ng_debug)
	fprintf(stderr, "v4l: open\n");
    BUG_ON(h->fd != -1,"device is open");
    h->rw = 1;
    h->fd = ng_chardev_open(h->device, O_RDWR, 81, 1, 0);
    if (-1 == h->fd) {
      h->rw = 0;
      h->fd = ng_chardev_open(h->device, O_RDONLY, 81, 1, 0);
       if (-1 == h->fd)
	 return -1;
    }
    if (-1 == ioctl(h->fd,VIDIOCGCAP,&h->capability)) {
	close(h->fd);
	return -1;
    }
    v4l_buffer_map(h);
    return 0;
}

static int
v4l_close(void *handle)
{
    struct v4l_handle *h = handle;

    if (ng_debug)
	fprintf(stderr, "v4l: close\n");
    BUG_ON(h->fd == -1,"device not open");
    v4l_buffer_unmap(h);
    close(h->fd);
    h->fd = -1;
    return 0;
}

static void*
v4l_init(char *device)
{
    struct v4l_handle *h;
    struct STRTAB *inputs;
    struct STRTAB *norms;
    unsigned int i;
    int rc;

    if (device && 0 != strncmp(device,"/dev/",5))
	return NULL;
    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));
    h->device = strdup(device ? device : ng_dev.video);
    h->fd     = -1;
    h->mmap   = MAP_FAILED;

    /* open device */
    if (0 != v4l_open(h))
	goto err;

    if (ng_debug)
	fprintf(stderr, "v4l: init: %s (%s)\n",device,h->capability.name);
    siginit();
    if (ng_debug) {
	fprintf(stderr,"  capabilities: ");
	for (i = 0; device_cap[i] != NULL; i++)
	    if (h->capability.type & (1 << i))
		fprintf(stderr," %s",device_cap[i]);
	fprintf(stderr,"\n");
	fprintf(stderr,"  size    : %dx%d => %dx%d\n",
		h->capability.minwidth,h->capability.minheight,
		h->capability.maxwidth,h->capability.maxheight);
    }

    /* input sources */
    if (ng_debug)
	fprintf(stderr,"  channels: %d\n",h->capability.channels);
    h->channels = malloc(sizeof(struct video_channel)*h->capability.channels);
    memset(h->channels,0,sizeof(struct video_channel)*h->capability.channels);
    inputs = malloc(sizeof(struct STRTAB)*(h->capability.channels+1));
    memset(inputs,0,sizeof(struct STRTAB)*(h->capability.channels+1));
    for (i = 0; i < h->capability.channels; i++) {
	h->channels[i].channel = i;
	xioctl(h->fd,VIDIOCGCHAN,&(h->channels[i]));
	inputs[i].nr  = i;
	inputs[i].str = h->channels[i].name;
	if (ng_debug)
	    fprintf(stderr,"    %s: %d %s%s %s%s\n",
		    h->channels[i].name,
		    h->channels[i].tuners,
		    (h->channels[i].flags & VIDEO_VC_TUNER)   ? "tuner "  : "",
		    (h->channels[i].flags & VIDEO_VC_AUDIO)   ? "audio "  : "",
		    (h->channels[i].type & VIDEO_TYPE_TV)     ? "tv "     : "",
		    (h->channels[i].type & VIDEO_TYPE_CAMERA) ? "camera " : "");
    }
    inputs[i].nr  = -1;
    inputs[i].str = NULL;
    v4l_add_attr(h,ATTR_ID_INPUT,ATTR_TYPE_CHOICE,0,inputs);
    
    /* audios */
    if (ng_debug)
	fprintf(stderr,"  audios  : %d\n",h->capability.audios);
    if (h->capability.audios) {
	h->audio.audio = 0;
	xioctl(h->fd,VIDIOCGAUDIO,&h->audio);
	if (ng_debug) {
	    fprintf(stderr,"    %d (%s): ",i,h->audio.name);
	    if (h->audio.flags & VIDEO_AUDIO_MUTABLE)
		fprintf(stderr,"muted=%s ",
			(h->audio.flags&VIDEO_AUDIO_MUTE) ? "yes":"no");
	    if (h->audio.flags & VIDEO_AUDIO_VOLUME)
		fprintf(stderr,"volume=%d ",h->audio.volume);
	    if (h->audio.flags & VIDEO_AUDIO_BASS)
		fprintf(stderr,"bass=%d ",h->audio.bass);
	    if (h->audio.flags & VIDEO_AUDIO_TREBLE)
		fprintf(stderr,"treble=%d ",h->audio.treble);
	    fprintf(stderr,"\n");
	}
	v4l_add_attr(h,ATTR_ID_MUTE,ATTR_TYPE_BOOL,0,NULL);
	v4l_add_attr(h,ATTR_ID_AUDIO_MODE,ATTR_TYPE_CHOICE,0,stereo);
	if (h->audio.flags & VIDEO_AUDIO_VOLUME)
	    v4l_add_attr(h,ATTR_ID_VOLUME,ATTR_TYPE_INTEGER,0,NULL);
    }

    /* tv norms / tuner */
    norms = malloc(sizeof(norms_v4l));
    memcpy(norms,norms_v4l,sizeof(norms_v4l));
    if (h->capability.type & VID_TYPE_TUNER) {
	/* have tuner */
	xioctl(h->fd,VIDIOCGTUNER,&h->tuner);
	if (ng_debug)
	    fprintf(stderr,"  tuner   : %s %lu-%lu",
		    h->tuner.name,h->tuner.rangelow,h->tuner.rangehigh);
	for (i = 0; norms[i].str != NULL; i++) {
	    if (h->tuner.flags & (1<<i)) {
		if (ng_debug)
		    fprintf(stderr," %s",norms[i].str);
	    } else
		norms[i].nr = -1;
	}
	if (ng_debug)
	    fprintf(stderr,"\n");
    } else {
	/* no tuner */
	struct video_channel vchan;
	memcpy(&vchan, &h->channels[0], sizeof(struct video_channel));
	for (i = 0; norms[i].str != NULL; i++) {
	    vchan.norm = i;
	    if (-1 == xioctl(h->fd,VIDIOCSCHAN,&vchan))
		norms[i].nr = -1;
	    else if (ng_debug)
		fprintf(stderr," %s",norms[i].str);
	}
	/* restore settings after probe */
	memcpy(&vchan, &h->channels[0], sizeof(struct video_channel));
	xioctl(h->fd,VIDIOCSCHAN,&vchan);
	if (ng_debug)
	    fprintf(stderr,"\n");
    }
    
#if 1
#define BTTV_VERSION  	        _IOR('v' , BASE_VIDIOCPRIVATE+6, int)
    /* dirty hack time / v4l design flaw -- works with bttv only
     * this adds support for a few less common PAL versions */
    if (-1 != (rc = ioctl(h->fd,BTTV_VERSION,&i))) {
	norms = norms_bttv;
	if (ng_debug || rc < 0x000700)
	    fprintf(stderr,"v4l: bttv version %d.%d.%d\n",
		    (rc >> 16) & 0xff,
		    (rc >> 8)  & 0xff,
		    rc         & 0xff);
	if (rc < 0x000700)
	    fprintf(stderr,
		    "v4l: prehistoric bttv version found, please try to\n"
		    "     upgrade the driver before mailing bug reports\n");
    }
#endif
    v4l_add_attr(h,ATTR_ID_NORM,ATTR_TYPE_CHOICE,0,norms);
    
    /* frame buffer */
    xioctl(h->fd,VIDIOCGFBUF,&h->fbuf);
    if (ng_debug)
	fprintf(stderr,"  fbuffer : base=0x%p size=%dx%d depth=%d bpl=%d\n",
		h->fbuf.base, h->fbuf.width, h->fbuf.height,
		h->fbuf.depth, h->fbuf.bytesperline);

    /* picture parameters */
    xioctl(h->fd,VIDIOCGPICT,&h->pict);
    v4l_add_attr(h,ATTR_ID_BRIGHT,  ATTR_TYPE_INTEGER,0,NULL);
    v4l_add_attr(h,ATTR_ID_HUE,     ATTR_TYPE_INTEGER,0,NULL);
    v4l_add_attr(h,ATTR_ID_COLOR,   ATTR_TYPE_INTEGER,0,NULL);
    v4l_add_attr(h,ATTR_ID_CONTRAST,ATTR_TYPE_INTEGER,0,NULL);
    if (ng_debug) {
	fprintf(stderr,
		"  picture : brightness=%d hue=%d colour=%d contrast=%d\n",
		h->pict.brightness, h->pict.hue,
		h->pict.colour, h->pict.contrast);
	fprintf(stderr,
		"  picture : whiteness=%d depth=%d palette=%s\n",
		h->pict.whiteness, h->pict.depth, PALETTE(h->pict.palette));
    }

    v4l_close(h);
    return h;

err:
    if (h->fd != -1)
	close(h->fd);
    free(h);
    return NULL;
}

static int
v4l_fini(void *handle)
{
    struct v4l_handle *h = handle;
    
    BUG_ON(h->fd != -1,"device still open");
    if (ng_debug)
	fprintf(stderr, "v4l: close\n");

    free(h->device);
    free(h);
    return 0;
}

/* ---------------------------------------------------------------------- */

static char*
v4l_devname(void *handle)
{
    struct v4l_handle *h = handle;
    return h->capability.name;
}

static struct ng_devinfo* v4l_probe(int verbose)
{
    struct ng_devinfo *info = NULL;
    struct video_capability cap;
    int i,n,fd;

    n = 0;
    for (i = 0; NULL != ng_dev.video_scan[i]; i++) {
	fd = ng_chardev_open(ng_dev.video_scan[i], O_RDONLY | O_NONBLOCK,
			     81, verbose, 0);
	if (-1 == fd)
	    continue;
	if (-1 == xioctl(fd,VIDIOCGCAP,&cap)) {
	    if (verbose)
		perror("ioctl VIDIOCGCAP");
	    close(fd);
	    continue;
	}
	info = realloc(info,sizeof(*info) * (n+2));
	memset(info+n,0,sizeof(*info)*2);
	strcpy(info[n].device, ng_dev.video_scan[i]);
	sprintf(info[n].name, "%.32s", cap.name);
	close(fd);
	n++;
    }
    return info;
}

static int v4l_flags(void *handle)
{
    struct v4l_handle *h = handle;
    int ret = 0;

#if 0
    if (h->capability.type & VID_TYPE_OVERLAY)
	ret |= CAN_OVERLAY;
#endif
    if (h->capability.type & VID_TYPE_CAPTURE &&
	!h->ov_error)
	ret |= CAN_CAPTURE;
    if (h->capability.type & VID_TYPE_TUNER)
	ret |= CAN_TUNE;
    if (h->capability.type & VID_TYPE_CHROMAKEY)
	ret |= NEEDS_CHROMAKEY;
    return ret;
}

static struct ng_attribute* v4l_attrs(void *handle)
{
    struct v4l_handle *h = handle;
    return h->attr;
}

static int audio_mode_mask2bit(int mode)
{
    if (mode & VIDEO_SOUND_STEREO)
	return VIDEO_SOUND_STEREO;
    if (mode & VIDEO_SOUND_LANG1)
	return VIDEO_SOUND_LANG1;
    if (mode & VIDEO_SOUND_LANG2)
	return VIDEO_SOUND_LANG2;
    if (mode & VIDEO_SOUND_MONO)
	return VIDEO_SOUND_MONO;
    return 0;
}

static int v4l_read_attr(struct ng_attribute *attr)
{
    struct v4l_handle *h = attr->handle;

    BUG_ON(h->fd == -1,"device not open");

    switch (attr->id) {
    case ATTR_ID_INPUT:
	return -1;
    case ATTR_ID_NORM:
	xioctl(h->fd, VIDIOCGCHAN, &h->channels[h->input]);
	return h->channels[h->input].norm;
    case ATTR_ID_MUTE:
	xioctl(h->fd, VIDIOCGAUDIO, &h->audio);
	return h->audio.flags & VIDEO_AUDIO_MUTE;
    case ATTR_ID_VOLUME:
	xioctl(h->fd, VIDIOCGAUDIO, &h->audio);
	return h->audio.volume;
    case ATTR_ID_AUDIO_MODE:
	xioctl(h->fd, VIDIOCGAUDIO, &h->audio);
	return audio_mode_mask2bit(h->audio.mode);
    case ATTR_ID_COLOR:
	xioctl(h->fd, VIDIOCGPICT, &h->pict);
	return h->pict.colour;
    case ATTR_ID_BRIGHT:
	xioctl(h->fd, VIDIOCGPICT, &h->pict);
	return h->pict.brightness;
    case ATTR_ID_HUE:
	xioctl(h->fd, VIDIOCGPICT, &h->pict);
	return h->pict.hue;
    case ATTR_ID_CONTRAST:
	xioctl(h->fd, VIDIOCGPICT, &h->pict);
	return h->pict.contrast;
    }
    return -1;
}

static void v4l_write_attr(struct ng_attribute *attr, int val)
{
    struct v4l_handle *h = attr->handle;

    BUG_ON(h->fd == -1,"device not open");

    /* read ... */
    switch (attr->id) {
    case ATTR_ID_INPUT:
	/* nothing */
	break;
    case ATTR_ID_NORM:
	xioctl(h->fd, VIDIOCGCHAN, &h->channels[h->input]);
	break;
    case ATTR_ID_MUTE:
    case ATTR_ID_VOLUME:
    case ATTR_ID_AUDIO_MODE:
	xioctl(h->fd, VIDIOCGAUDIO, &h->audio);
	break;
    case ATTR_ID_COLOR:
    case ATTR_ID_BRIGHT:
    case ATTR_ID_HUE:
    case ATTR_ID_CONTRAST:
	xioctl(h->fd, VIDIOCGPICT, &h->pict);
	break;
    }

    /* ... modify ... */
    switch (attr->id) {
    case ATTR_ID_INPUT:
	h->input = val;
	h->audio_mode = 0;
	break;
    case ATTR_ID_NORM:
	h->channels[h->input].norm = val;
	h->audio_mode = 0;
	break;
    case ATTR_ID_MUTE:
	if (val)
	    h->audio.flags |= VIDEO_AUDIO_MUTE;
	else
	    h->audio.flags &= ~VIDEO_AUDIO_MUTE;
	break;
    case ATTR_ID_VOLUME:
	h->audio.volume = val;
	break;
    case ATTR_ID_AUDIO_MODE:
	h->audio_mode = val;
	break;
    case ATTR_ID_COLOR:
	h->pict.colour = val;
	break;
    case ATTR_ID_BRIGHT:
	h->pict.brightness = val;
	break;
    case ATTR_ID_HUE:
	h->pict.hue = val;
	break;
    case ATTR_ID_CONTRAST:
	h->pict.contrast = val;
	break;
    }
    /* have to set that all the time as read and write have
       slightly different semantics:
          read  == bitmask with all available modes flagged
	  write == one bit set (for the selected mode, zero is autodetect)
    */
    h->audio.mode = h->audio_mode;

    /* ... write */
    switch (attr->id) {
    case ATTR_ID_INPUT:
    case ATTR_ID_NORM:
	xioctl(h->fd, VIDIOCSCHAN, &h->channels[h->input]);
	break;
    case ATTR_ID_MUTE:
    case ATTR_ID_VOLUME:
    case ATTR_ID_AUDIO_MODE:
	xioctl(h->fd, VIDIOCSAUDIO, &h->audio);
	break;
    case ATTR_ID_COLOR:
    case ATTR_ID_BRIGHT:
    case ATTR_ID_HUE:
    case ATTR_ID_CONTRAST:
	xioctl(h->fd, VIDIOCSPICT, &h->pict);
	break;
    }
}

static unsigned long
v4l_getfreq(void *handle)
{
    struct v4l_handle *h = handle;
    unsigned long freq;

    BUG_ON(h->fd == -1,"device not open");
    xioctl(h->fd, VIDIOCGFREQ, &freq);
    return freq;
}

static void
v4l_setfreq(void *handle, unsigned long freq)
{
    struct v4l_handle *h = handle;

    if (ng_debug)
	fprintf(stderr,"v4l: freq: %.3f\n",(float)freq/16);
    BUG_ON(h->fd == -1,"device not open");
    xioctl(h->fd, VIDIOCSFREQ, &freq);
    h->audio_mode = 0;
}

static int
v4l_tuned(void *handle)
{
    struct v4l_handle *h = handle;

    BUG_ON(h->fd == -1,"device not open");
    /* usleep(10000); */
    if (-1 == xioctl(h->fd,VIDIOCGTUNER,&h->tuner))
	return 0;
    return h->tuner.signal ? 1 : 0;
}


/* ---------------------------------------------------------------------- */
/* do overlay                                                             */

#if 0

int
v4l_setupfb(void *handle, struct ng_video_fmt *fmt, void *base)
{
    struct v4l_handle *h = handle;

    BUG_ON(h->fd == -1,"device not open");

    /* overlay supported ?? */
    if (!(h->capability.type & VID_TYPE_OVERLAY)) {
	if (ng_debug)
	    fprintf(stderr,"v4l: device has no overlay support\n");
	return -1;
    }

    /* double-check settings */
    if (ng_debug)
	fprintf(stderr,"v4l: %dx%d, %d bit/pixel, %d byte/scanline\n",
		h->fbuf.width,h->fbuf.height,
		h->fbuf.depth,h->fbuf.bytesperline);
    if ((fmt->bytesperline > 0 &&
	 h->fbuf.bytesperline != fmt->bytesperline) ||
	(h->fbuf.width  != fmt->width) ||
	(h->fbuf.height != fmt->height)) {
	fprintf(stderr,
		"WARNING: v4l and x11 disagree about the screen size\n"
		"WARNING: Is v4l-conf installed correctly?\n");
	h->ov_error = 1;
    }
    if (ng_vfmt_to_depth[fmt->fmtid] != ((h->fbuf.depth+7)&0xf8)) {
	fprintf(stderr,
		"WARNING: v4l and x11 disagree about the color depth\n"
		"WARNING: fbuf.depth=%d, x11 depth=%d\n"
		"WARNING: Is v4l-conf installed correctly?\n",
		h->fbuf.depth,ng_vfmt_to_depth[fmt->fmtid]);
	h->ov_error = 1;
    }
    if (NULL != base) {
	/* XXX: minor differences are legal... (matrox problems) */
	if ((void*)((unsigned long)h->fbuf.base & 0xfffff000) !=
	    (void*)((unsigned long)base         & 0xfffff000)) {
	    fprintf(stderr,
		    "WARNING: v4l and dga disagree about the framebuffer base\n"
		    "WARNING: fbuf.base=%p, dga=%p\n"
		    "WARNING: Is v4l-conf installed correctly?\n",
		    h->fbuf.base,base);
	    h->ov_error = 1;
	}
    }
    if (h->ov_error) {
	fprintf(stderr,"WARNING: overlay mode disabled\n");
	return -1;
    }
    return 0;
}

static void
v4l_overlay_set(struct v4l_handle *h, int state)
{
    int rc;
    
    if (0 == state) {
	/* off */
	if (0 == h->ov_on)
	    return;
	xioctl(h->fd, VIDIOCCAPTURE, &zero);
	h->ov_on = 0;
    } else {
	/* on */
	h->pict.depth   = ng_vfmt_to_depth[h->ov_fmtid];
	h->pict.palette = GETELEM(format2palette,h->ov_fmtid,0);
	xioctl(h->fd, VIDIOCSPICT, &h->pict);
	rc = xioctl(h->fd, VIDIOCSWIN, &h->win);
	if (0 == rc) {
	    if (0 != h->ov_on)
		return;
	    xioctl(h->fd, VIDIOCCAPTURE, &one);
	    h->ov_on = 1;
	} else {
	    /* disable overlay on SWIN failure */
	    xioctl(h->fd, VIDIOCCAPTURE, &zero);
	    h->ov_on = 0;
	}
    }
}

int
v4l_overlay(void *handle, struct ng_video_fmt *fmt, int x, int y,
	    struct OVERLAY_CLIP *oc, int count, int aspect)
{
    struct v4l_handle *h = handle;
    int i;

    BUG_ON(h->fd == -1,"device not open");

    if (h->ov_error)
	return -1;
    
    if (NULL == fmt) {
	if (ng_debug)
	    fprintf(stderr,"v4l: overlay off\n");
	h->ov_enabled = 0;
	v4l_overlay_set(h,h->ov_enabled);
	return 0;
    }

    h->win.x          = x;
    h->win.y          = y;
    h->win.width      = fmt->width;
    h->win.height     = fmt->height;
    h->win.flags      = 0;
    h->win.chromakey  = 0;

    /* check against max. size */
    xioctl(h->fd,VIDIOCGCAP,&h->capability);
    if (h->win.width > h->capability.maxwidth) {
	h->win.width = h->capability.maxwidth;
	h->win.x += (fmt->width - h->win.width)/2;
    }
    if (h->win.height > h->capability.maxheight) {
	h->win.height = h->capability.maxheight;
	h->win.y +=  (fmt->height - h->win.height)/2;
    }
    if (aspect)
	ng_ratio_fixup(&h->win.width,&h->win.height,&h->win.x,&h->win.y);

#if 0
    /* pass aligned values -- the driver does'nt get it right yet */
    h->win.width  &= ~3;
    h->win.height &= ~3;
    h->win.x      &= ~3;
    if (h->win.x < x)
	h->win.x     += 4;
    if (h->win.x+h->win.width > x+fmt->width)
	h->win.width -= 4;
#endif

    /* fixups */
    ng_check_clipping(h->win.width, h->win.height,
		      x - h->win.x, y - h->win.y,
		      oc, &count);

    /* handle clipping */
    if (h->win.clips) {
	free(h->win.clips);
	h->win.clips = NULL;
    }
    h->win.clipcount = 0;
    if (h->capability.type & VID_TYPE_CLIPPING && count > 0) {
	h->win.clipcount  = count;
	h->win.clips      = malloc(count * sizeof(struct video_clip));
	for (i = 0; i < count; i++) {
	    h->win.clips[i].x      = oc[i].x1;
	    h->win.clips[i].y      = oc[i].y1;
	    h->win.clips[i].width  = oc[i].x2-oc[i].x1;
	    h->win.clips[i].height = oc[i].y2-oc[i].y1;
	}
    }
    if (h->capability.type & VID_TYPE_CHROMAKEY)
	h->win.chromakey = ng_chromakey;
    h->ov_enabled = 1;
    h->ov_fmtid = fmt->fmtid;
    v4l_overlay_set(h,h->ov_enabled);

    if (ng_debug)
	fprintf(stderr,"v4l: overlay win=%dx%d+%d+%d, %d clips\n",
		fmt->width,fmt->height,x,y,count);
    return 0;
}

#else

static void
v4l_overlay_set(struct v4l_handle *h, int state)
{
    /* dummy */
}

#endif

/* ---------------------------------------------------------------------- */

static int
mm_queue(struct v4l_handle *h)
{
    int frame = h->queue % h->nbuf;
    int rc;

    if (0 != h->buf_me[frame].refcount) {
	if (0 != h->queue - h->waiton)
	    return -1;
	fprintf(stderr,"v4l: waiting for a free buffer\n");
	ng_waiton_video_buf(h->buf_me+frame);
    }

    rc = xioctl(h->fd,VIDIOCMCAPTURE,h->buf_v4l+frame);
    if (0 == rc)
	h->queue++;
    return rc;
}

static void
mm_queue_all(struct v4l_handle *h)
{
    for (;;) {
	if (h->queue - h->waiton >= h->nbuf)
	    return;
	if (0 != mm_queue(h))
	    return;
    }
}

static int
mm_waiton(struct v4l_handle *h)
{
    int frame = h->waiton % h->nbuf;
    int rc;
    
    if (0 == h->queue - h->waiton)
	return -1;
    h->waiton++;
    
    alarms=0;
    alarm(SYNC_TIMEOUT);

 retry:
    if (-1 == (rc = xioctl(h->fd,VIDIOCSYNC,h->buf_v4l+frame))) {
	if (errno == EINTR && !alarms)
	    goto retry;
    }
    alarm(0);
    if (-1 == rc)
	return -1;
    return frame;
}

static void
mm_clear(struct v4l_handle *h)
{
    while (h->queue > h->waiton)
	mm_waiton(h);
    h->queue  = 0;
    h->waiton = 0;
}

static int
mm_probe(struct v4l_handle *h, unsigned int fmtid)
{
    if (0 != h->probe[fmtid])
	goto done;

    if (ng_debug)
	fprintf(stderr, "v4l: capture probe %s...\t",
		ng_vfmt_to_desc[fmtid]);

    h->buf_v4l[0].frame  = 0;
    h->buf_v4l[0].width  = h->capability.minwidth;
    h->buf_v4l[0].height = h->capability.minheight;
    h->buf_v4l[0].format = GETELEM(format2palette,fmtid,0);
#if 1 /* bug compatibility: bttv up to 0.7.67 reports wrong minwidth */
    if (h->buf_v4l[0].width == 32)
	h->buf_v4l[0].width = 48;
#endif

    if (0 == h->buf_v4l[0].format)
	goto fail;
    if (-1 == mm_queue(h))
	goto fail;
    if (-1 == mm_waiton(h))
	goto fail;

    if (ng_debug)
	fprintf(stderr, "ok\n");
    h->probe[fmtid] = 1;
    goto done;

 fail:
    if (ng_debug)
	fprintf(stderr, "failed\n");
    h->probe[fmtid] = 2;

 done:
    mm_clear(h);
    return h->probe[fmtid] == 1;
}

static int
mm_setparams(struct v4l_handle *h, struct ng_video_fmt *fmt)
{
    unsigned int i;

    /* buffers available ? */
    if (h->mbuf.frames < 1)
	return -1;
    
    /* verify parameters */
    xioctl(h->fd,VIDIOCGCAP,&h->capability);
    if (fmt->width > h->capability.maxwidth)
	fmt->width = h->capability.maxwidth;
    if (fmt->height > h->capability.maxheight)
	fmt->height = h->capability.maxheight;    
     if (fmt->width < h->capability.minwidth)
	fmt->width = h->capability.minwidth;
    if (fmt->height < h->capability.minheight)
	fmt->height = h->capability.minheight;

   fmt->bytesperline = fmt->width * ng_vfmt_to_depth[fmt->fmtid] / 8;

    /* check if we can handle the format */
    if (!mm_probe(h,fmt->fmtid))
	return -1;

    /* initialize everything */
    h->nbuf = h->mbuf.frames;
    for (i = 0; i < h->nbuf; i++) {
	h->buf_v4l[i].format = GETELEM(format2palette,fmt->fmtid,0);
	h->buf_v4l[i].frame  = i;
	h->buf_v4l[i].width  = fmt->width;
	h->buf_v4l[i].height = fmt->height;
	h->buf_me[i].fmt  = *fmt;
	h->buf_me[i].data = h->mmap + h->mbuf.offsets[i];
	h->buf_me[i].size = fmt->height * fmt->bytesperline;
    }
    return 0;
}

/* ---------------------------------------------------------------------- */

static int
read_setformat(struct v4l_handle *h, struct ng_video_fmt *fmt)
{
    xioctl(h->fd,VIDIOCGCAP,&h->capability);
    if (fmt->width > h->capability.maxwidth)
	fmt->width = h->capability.maxwidth;
    if (fmt->height > h->capability.maxheight)
	fmt->height = h->capability.maxheight;    
    fmt->bytesperline = fmt->width * ng_vfmt_to_depth[fmt->fmtid] / 8;

    h->rd_win.width  = fmt->width;
    h->rd_win.height = fmt->height;
    h->rd_fmtid = fmt->fmtid;

    h->pict.depth   = ng_vfmt_to_depth[h->rd_fmtid];
    h->pict.palette = GETELEM(format2palette,h->rd_fmtid,0);
    if (-1 == xioctl(h->fd, VIDIOCSPICT, &h->pict))
	return -1;
    if (-1 == xioctl(h->fd, VIDIOCSWIN,  &h->rd_win))
	return -1;

    fmt->width  = h->rd_win.width;
    fmt->height = h->rd_win.height;
    fmt->bytesperline = fmt->width * ng_vfmt_to_depth[fmt->fmtid] / 8;
    h->rd_fmt = *fmt;
    return 0;
}

static struct ng_video_buf*
read_getframe(struct v4l_handle *h)
{
    struct ng_video_buf* buf;

    h->pict.depth   = ng_vfmt_to_depth[h->rd_fmtid];
    h->pict.palette = GETELEM(format2palette,h->rd_fmtid,0);
    xioctl(h->fd, VIDIOCSPICT, &h->pict);
    xioctl(h->fd, VIDIOCSWIN,  &h->rd_win);
    buf = ng_malloc_video_buf(NULL, &h->rd_fmt);
    if (NULL == buf)
	return NULL;
    if (buf->size != read(h->fd,buf->data,buf->size)) {
	ng_release_video_buf(buf);
	return NULL;
    }
    return buf;
}

/* ---------------------------------------------------------------------- */

int
v4l_setformat(void *handle, struct ng_video_fmt *fmt)
{
    struct v4l_handle *h = handle;
    int rc;

    BUG_ON(h->fd == -1,"device not open");

#if 0
    /* for debugging color space conversion functions:
       force xawtv to capture some specific format */
    if (fmt->fmtid != VIDEO_YUV420P)
	return -1;
#endif
    
    if (ng_debug)
	fprintf(stderr,"v4l: setformat\n");
    if (h->use_read) {
	v4l_overlay_set(h,0);
	rc = read_setformat(h,fmt);
	v4l_overlay_set(h,h->ov_enabled);
    } else {
	if (h->queue != h->waiton)
	    fprintf(stderr,"v4l: Huh? setformat: found queued buffers (%d %d)\n",
		    h->queue, h->waiton);
	mm_clear(h);
	rc = mm_setparams(h,fmt);
    }
    return rc;
}

int
v4l_startvideo(void *handle, int fps, unsigned int buffers)
{
    struct v4l_handle *h = handle;

    BUG_ON(h->fd == -1,"device not open");

    if (ng_debug)
	fprintf(stderr,"v4l: startvideo\n");
    if (0 != h->fps)
	fprintf(stderr,"v4l: Huh? start: fps != 0\n");
    if (!h->use_read) {
	if (h->nbuf > buffers)
	    h->nbuf = buffers;
	mm_queue_all(h);
    }
    h->start = ng_get_timestamp();
    h->fps = fps;
    return 0;
}

void
v4l_stopvideo(void *handle)
{
    struct v4l_handle *h = handle;

    BUG_ON(h->fd == -1,"device not open");

    if (ng_debug)
	fprintf(stderr,"v4l: stopvideo\n");
    if (0 == h->fps)
	fprintf(stderr,"v4l: Huh? stop: fps == 0\n");
    if (!h->use_read)
	mm_clear(h);
    h->fps = 0;
}

struct ng_video_buf*
v4l_nextframe(void *handle)
{
    struct v4l_handle *h = handle;
    struct ng_video_buf* buf = NULL;
    int frame = 0;

    if (ng_debug > 1)
	fprintf(stderr,"v4l: getimage\n");
    BUG_ON(h->fd == -1,"device not open");

    if (0 == h->fps) {
	fprintf(stderr,"v4l: nextframe: fps == 0\n");
	return NULL;
    }

    if (h->use_read) {
	if (buf)
	    ng_release_video_buf(buf);
	v4l_overlay_set(h,0);
	buf = read_getframe(h);
	v4l_overlay_set(h,h->ov_enabled);
	if (NULL == buf)
	    return NULL;
	memset(&buf->info,0,sizeof(buf->info));
	buf->info.ts = ng_get_timestamp() - h->start;
	return buf;
    } else {
	mm_queue_all(h);
	frame = mm_waiton(h);
	if (-1 == frame)
	    return NULL;
	memset(&h->buf_me[frame].info,0,sizeof(h->buf_me[frame].info));
	h->buf_me[frame].refcount++;
	h->buf_me[frame].info.ts = ng_get_timestamp() - h->start;
	return h->buf_me+frame;
    }
}

/* ---------------------------------------------------------------------- */

struct ng_video_buf*
v4l_getimage(void *handle)
{
    struct v4l_handle *h = handle;
    struct ng_video_buf* buf = NULL;
    int frame;

    if (ng_debug)
	fprintf(stderr,"v4l: getimage\n");
    BUG_ON(h->fd == -1,"device not open");
	
    if (0 != h->fps) {
	fprintf(stderr,"v4l: getimage: fps != 0\n");
	return NULL;
    }
    if (h->use_read) {
	v4l_overlay_set(h,0);
	buf = read_getframe(h);
	v4l_overlay_set(h,h->ov_enabled);
	return buf;
    } else {
	mm_queue(h);
	frame = mm_waiton(h);
	if (-1 == frame)
	    return NULL;
	h->buf_me[frame].refcount++;
	return h->buf_me+frame;
    }
}

/* ---------------------------------------------------------------------- */

static void __init plugin_init(void)
{
    ng_vid_driver_register(NG_PLUGIN_MAGIC,__FILE__,&v4l_driver);
}
