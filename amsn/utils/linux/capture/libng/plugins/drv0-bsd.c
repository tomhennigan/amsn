/*
 * interface to the bsd bktr driver
 *
 *   (c) 2000-04 Gerd Knorr <kraxel@bytesex.org>
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

#if defined(HAVE_DEV_IC_BT8XX_H)
# include <dev/ic/bt8xx.h>
#elif defined(HAVE_DEV_BKTR_IOCTL_BT848_H)
# include <dev/bktr/ioctl_bt848.h>
# include <dev/bktr/ioctl_meteor.h>
#else
# include <machine/ioctl_bt848.h>
# include <machine/ioctl_meteor.h>
#endif

#include "grab-ng.h"

/* ---------------------------------------------------------------------- */
/* global variables                                                       */

struct bsd_handle {
    int                     fd;
    int                     tfd;
    char                    *device;
    char                    *tdevice;

    /* formats */
    int                     pf_count;
    struct meteor_pixfmt    pf[64];
    int                     xawtv2pf[VIDEO_FMT_COUNT];
    unsigned char           *map;

    /* attributes */
    int muted;
    struct ng_attribute     *attr;
    
    /* overlay */
    struct meteor_video     fb,pos;
    struct meteor_geomet    ovgeo;
    struct meteor_pixfmt    *ovfmt;
    struct bktr_clip        clip[BT848_MAX_CLIP_NODE];
    int                     ov_enabled,ov_on;

    /* capture */
    int                     fps;
    long long               start;
    struct ng_video_fmt     fmt;
    struct meteor_video     nofb;
    struct meteor_geomet    capgeo;
    struct meteor_pixfmt    *capfmt;
    struct bktr_clip        noclip[BT848_MAX_CLIP_NODE];
};

/* ---------------------------------------------------------------------- */
/* prototypes                                                             */

/* open/close */
static void*   bsd_init(char *device);
static int     bsd_open(void *handle);
static int     bsd_close(void *handle);
static int     bsd_fini(void *handle);
static char*   bsd_devname(void *handle);
static struct ng_devinfo* bsd_probe(void);

/* attributes */
static int     bsd_flags(void *handle);
static struct ng_attribute* bsd_attrs(void *handle);
static int     bsd_read_attr(struct ng_attribute*);
static void    bsd_write_attr(struct ng_attribute*, int val);

#if 0
static int   bsd_setupfb(void *handle, struct ng_video_fmt *fmt, void *base);
static int   bsd_overlay(void *handle, struct ng_video_fmt *fmt, int x, int y,
			 struct OVERLAY_CLIP *oc, int count, int aspect);
#endif

/* capture */
static void catchsignal(int signal);
static void siginit(void);
static int bsd_setformat(void *handle, struct ng_video_fmt *fmt);
static int bsd_startvideo(void *handle, int fps, unsigned int buffers);
static void bsd_stopvideo(void *handle);
static struct ng_video_buf* bsd_nextframe(void *handle);
static struct ng_video_buf* bsd_getimage(void *handle);

/* tuner */
static unsigned long bsd_getfreq(void *handle);
static void bsd_setfreq(void *handle, unsigned long freq);
static int bsd_tuned(void *handle);

struct ng_vid_driver bsd_driver = {
    .name          = "bktr",
    .priority      = 1,

    .init          = bsd_init,
    .open          = bsd_open,
    .close         = bsd_close,
    .fini          = bsd_fini,
    .devname       = bsd_devname,
    .probe         = bsd_probe,
    
    .capabilities  = bsd_flags,
    .list_attrs    = bsd_attrs,

#if 0
    .setupfb       = bsd_setupfb,
    .overlay       = bsd_overlay,
#endif

    .setformat     = bsd_setformat,
    .startvideo    = bsd_startvideo,
    .stopvideo     = bsd_stopvideo,
    .nextframe     = bsd_nextframe,
    .getimage      = bsd_getimage,
    
    .getfreq       = bsd_getfreq,
    .setfreq       = bsd_setfreq,
    .is_tuned      = bsd_tuned,
};

/* ---------------------------------------------------------------------- */

static struct STRTAB inputs[] = {
    {  0, "Television"   },
    {  1, "Composite1"   },
    {  2, "S-Video"      },
    {  3, "CSVIDEO"      },
    { -1, NULL }
};
static long inputs_map[] = {
    METEOR_INPUT_DEV1,
    METEOR_INPUT_DEV0,
    METEOR_INPUT_DEV_SVIDEO,
    METEOR_INPUT_DEV2,
};

static struct STRTAB norms[] = {
    {  0, "NTSC"      },
    {  1, "NTSC-JP"   },
    {  2, "PAL"       },
    {  3, "PAL-M"     },
    {  4, "PAL-N"     },
    {  5, "SECAM"     },
    {  6, "RSVD"      },
    { -1, NULL }
};
static long norms_map[] = {
    BT848_IFORM_F_NTSCM,
    BT848_IFORM_F_NTSCJ,
    BT848_IFORM_F_PALBDGHI,
    BT848_IFORM_F_PALM,
    BT848_IFORM_F_PALN,
    BT848_IFORM_F_SECAM,
    BT848_IFORM_F_RSVD,
};

static struct STRTAB audio[] = {
    {  0, "Tuner"   },
    {  1, "Extern"   },
    {  2, "Intern"      },
    { -1, NULL }
};
static long audio_map[] = {
    AUDIO_TUNER,
    AUDIO_EXTERN,
    AUDIO_INTERN,
};

static struct ng_attribute bsd_attr[] = {
    {
	.id       = ATTR_ID_COUNT+1,
	.name     = "audio",
	.priority = 2,
	.type     = ATTR_TYPE_CHOICE,
	.choices  = audio,
	.read     = bsd_read_attr,
	.write    = bsd_write_attr,
    },{
	.id       = ATTR_ID_NORM,
	.name     = "norm",
	.priority = 2,
	.type     = ATTR_TYPE_CHOICE,
	.choices  = norms,
	.read     = bsd_read_attr,
	.write    = bsd_write_attr,
    },{
	.id       = ATTR_ID_INPUT,
	.name     = "input",
	.priority = 2,
	.type     = ATTR_TYPE_CHOICE,
	.choices  = inputs,
	.read     = bsd_read_attr,
	.write    = bsd_write_attr,
    },{
	.id       = ATTR_ID_MUTE,
	.name     = "mute",
	.priority = 2,
	.type     = ATTR_TYPE_BOOL,
	.read     = bsd_read_attr,
	.write    = bsd_write_attr,
    },{
	.id       = ATTR_ID_HUE,
	.name     = "hue",
	.priority = 2,
	.type     = ATTR_TYPE_INTEGER,
	.min      = BT848_HUEREGMIN,
	.max      = BT848_HUEREGMAX,
	.read     = bsd_read_attr,
	.write    = bsd_write_attr,
    },{
	.id       = ATTR_ID_BRIGHT,
	.name     = "bright",
	.priority = 2,
	.type     = ATTR_TYPE_INTEGER,
	.min      = BT848_BRIGHTREGMIN,
	.max      = BT848_BRIGHTREGMAX,
	.read     = bsd_read_attr,
	.write    = bsd_write_attr,
    },{
	.id       = ATTR_ID_CONTRAST,
	.name     = "contrast",
	.priority = 2,
	.type     = ATTR_TYPE_INTEGER,
	.min      = BT848_CONTRASTREGMIN,
	.max      = BT848_CONTRASTREGMAX,
	.read     = bsd_read_attr,
	.write    = bsd_write_attr,
    },{
	.id       = ATTR_ID_COLOR,
	.name     = "color",
	.priority = 2,
	.type     = ATTR_TYPE_INTEGER,
	.min      = BT848_CHROMAREGMIN,
	.max      = BT848_CHROMAREGMAX,
	.read     = bsd_read_attr,
	.write    = bsd_write_attr,
    },{
	/* end of list */
    }
};

static int single     = METEOR_CAP_SINGLE;
static int start      = METEOR_CAP_CONTINOUS;
static int stop       = METEOR_CAP_STOP_CONT;
static int signal_on  = SIGUSR1;
static int signal_off = METEOR_SIG_MODE_MASK;

/* ---------------------------------------------------------------------- */

#define PREFIX "bktr: ioctl: "

static int
xioctl(int fd, unsigned long cmd, void *arg)
{
    int rc;

    rc = ioctl(fd,cmd,arg);
    if (0 == rc && ng_debug < 2)
	return 0;
    switch (cmd) {
    case METEORSVIDEO:
    {
	struct meteor_video *a = arg;

	fprintf(stderr,PREFIX "METEORSVIDEO(addr=0x%08lx,width=%ld,bank=%ld,ram=%ld)",
		a->addr,a->width,a->banksize,a->ramsize);
	break;
    }
    case METEORSETGEO:
    {
	struct meteor_geomet *a = arg;

	fprintf(stderr,PREFIX "METEORSETGEO(%dx%d,frames=%d,oformat=0x%lx)",
		a->columns,a->rows,a->frames,a->oformat);
	break;
    }
    case METEORSACTPIXFMT:
    {
	struct meteor_pixfmt *a = arg;

	fprintf(stderr,PREFIX "METEORSACTPIXFMT(%d,type=%d,bpp=%d,"
		"masks=0x%lx/0x%lx/0x%lx,sb=%d,ss=%d)",
		a->index,a->type,a->Bpp,a->masks[0],a->masks[1],a->masks[2],
		a->swap_bytes,a->swap_shorts);
	break;
    }
    case METEORCAPTUR:
    {
        int *a = arg;

	fprintf(stderr,PREFIX "METEORCAPTUR(%d)",*a);
	break;
    }
    case METEORSSIGNAL:
    {
        int *a = arg;

	fprintf(stderr,PREFIX "METEORSSIGNAL(0x%x)",*a);
	break;
    }
    case BT848SCLIP:
    {
	fprintf(stderr,PREFIX "BT848SCLIP");
	break;
    }
    default:
	fprintf(stderr,PREFIX "UNKNOWN(cmd=0x%lx)",cmd);
	break;
    }
    fprintf(stderr,": %s\n",(rc == 0) ? "ok" : strerror(errno));
    return rc;
}

/* ---------------------------------------------------------------------- */

static void
bsd_print_format(struct meteor_pixfmt *pf, int format)
{
    switch (pf->type) {
    case METEOR_PIXTYPE_RGB:
	fprintf(stderr,
		"bktr: pf: rgb bpp=%d mask=%ld,%ld,%ld",
		pf->Bpp,pf->masks[0],pf->masks[1],pf->masks[2]);
	break;
    case METEOR_PIXTYPE_YUV:
	fprintf(stderr,"bktr: pf: yuv h422 v111 (planar)");
	break;
    case METEOR_PIXTYPE_YUV_PACKED:
	fprintf(stderr,"bktr: pf: yuyv h422 v111 (packed)");
	break;
    case METEOR_PIXTYPE_YUV_12:
	fprintf(stderr,"bktr: pf: yuv h422 v422 (planar)");
	break;
    default:
	fprintf(stderr,"bktr: pf: unknown");
    }
    fprintf(stderr," sbytes=%d sshorts=%d (fmt=%d)\n",
	    pf->swap_bytes,pf->swap_shorts,format);
}

/* ---------------------------------------------------------------------- */

static int
bsd_open(void *handle)
{
    struct bsd_handle *h = handle;

    BUG_ON(h->fd != -1,"device is open");
    if (ng_debug)
	fprintf(stderr, "bktr: open\n");

    if (-1 == (h->fd = open(h->device,O_RDONLY))) {
	fprintf(stderr,"bktr: open %s: %s\n", h->device, strerror(errno));
	goto err1;
    }
    if (-1 == (h->tfd = open(h->tdevice,O_RDONLY))) {
	fprintf(stderr,"bktr: open %s: %s\n", h->tdevice, strerror(errno));
	goto err2;
    }
    h->map = mmap(0,768*576*4, PROT_READ, MAP_SHARED, h->fd, 0);
    if (MAP_FAILED == h->map) {
	perror("bktr: mmap");
	h->map = NULL;
	goto err3;
    }
    return 0;

 err3:
    close(h->tfd);
    h->tfd = -1;
 err2:
    close(h->fd);
    h->fd = -1;
 err1:
    return -1;
}

static int
bsd_close(void *handle)
{
    struct bsd_handle *h = handle;

    BUG_ON(h->fd == -1,"device not open");
    if (ng_debug)
	fprintf(stderr, "bktr: close\n");
    close(h->fd);
    if (-1 != h->tfd)
	close(h->tfd);
    if (NULL != h->map)
	munmap(h->map,768*576*4);
    h->fd  = -1;
    h->tfd = -1;
    return 0;
}

static int
bsd_fini(void *handle)
{
    struct bsd_handle *h = handle;

    BUG_ON(h->fd != -1,"device is open");
    if (ng_debug)
	fprintf(stderr, "bktr: fini\n");
    if (h->device)
	free(h->device);
    if (h->tdevice)
	free(h->tdevice);
    if (h->attr)
	free(h->attr);
    free(h);
    return 0;
}

static void*
bsd_init(char *filename)
{
    struct bsd_handle *h;
    int format,i;

    if (NULL == filename)
	return NULL;
    if (0 != strncmp(filename,"/dev/",5))
	return NULL;
    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));
    h->fd      = -1;
    h->tfd     = -1;
    h->device  = strdup(filename);
    h->tdevice = strdup("/dev/tuner0");  // FIXME

    if (-1 == bsd_open(h))
	goto err1;

    /* video formats */
    for (format = 0; format < VIDEO_FMT_COUNT; format++)
	h->xawtv2pf[format] = -1;

    for (h->pf_count = 0; h->pf_count < 64; h->pf_count++) {
	h->pf[h->pf_count].index = h->pf_count;
	if (-1 == ioctl(h->fd, METEORGSUPPIXFMT,h->pf+h->pf_count)) {
	    if (ng_debug)
		perror("bktr: ioctl METEORGSUPPIXFMT");
	    if (0 == h->pf_count)
		goto err2;
	    break;
	}
	format = -1;
	switch (h->pf[h->pf_count].type) {
	case METEOR_PIXTYPE_RGB:
	    switch(h->pf[h->pf_count].masks[0]) {
	    case 31744: /* 15 bpp */
	        format = h->pf[h->pf_count].swap_bytes
		    ? VIDEO_RGB15_LE : VIDEO_RGB15_BE;
		break;
	    case 63488: /* 16 bpp */
	        format = h->pf[h->pf_count].swap_bytes
		    ? VIDEO_RGB16_LE : VIDEO_RGB16_BE;
		break;
	    case 16711680: /* 24/32 bpp */
		if (h->pf[h->pf_count].Bpp == 3 &&
		    h->pf[h->pf_count].swap_bytes == 1) {
		    format = VIDEO_BGR24;
		} else if (h->pf[h->pf_count].Bpp == 4 &&
			   h->pf[h->pf_count].swap_bytes == 1 &&
			   h->pf[h->pf_count].swap_shorts == 1) {
		    format = VIDEO_BGR32;
		} else if (h->pf[h->pf_count].Bpp == 4 &&
			   h->pf[h->pf_count].swap_bytes == 0 &&
			   h->pf[h->pf_count].swap_shorts == 0) {
		    format = VIDEO_RGB32;
		}
	    }
	    break;
	case METEOR_PIXTYPE_YUV:
	    format = VIDEO_YUV422P;
	    break;
#if 0
	case METEOR_PIXTYPE_YUV_PACKED:
	    format = VIDEO_YUV422;
	    h->pf[h->pf_count].swap_shorts = 0; /* seems not to work */
	    break;
#endif
	case METEOR_PIXTYPE_YUV_12:
	case METEOR_PIXTYPE_YUV_PACKED:
	    /* nothing */
	    break;
	}
	if (-1 != format)
	    h->xawtv2pf[format] = h->pf_count;

	if (ng_debug)
	  bsd_print_format(h->pf+h->pf_count,format);
    }
    bsd_close(h);
    siginit();

    h->attr = malloc(sizeof(bsd_attr));
    memcpy(h->attr,bsd_attr,sizeof(bsd_attr));
    for (i = 0; h->attr[i].name != NULL; i++)
	h->attr[i].handle = h;

    return h;

 err2:
    bsd_close(h);
 err1:
    bsd_fini(h);
    return NULL;
}

static char*
bsd_devname(void *handle)
{
    return "bsd bkdr device";
}

static struct ng_devinfo* bsd_probe(void)
{
    struct ng_devinfo *info = NULL;
    int i,n,fd,status;
    
    n = 0;
    for (i = 0; NULL != ng_dev.video_scan[i]; i++) {
	fd = open(ng_dev.video_scan[i], O_RDONLY);
	if (-1 == fd)
	    continue;
	if (-1 == ioctl(fd,BT848_GSTATUS,&status)) {
	    close(fd);
	    continue;
	}
	info = realloc(info,sizeof(*info) * (n+2));
	memset(info+n,0,sizeof(*info)*2);
	strcpy(info[n].device, ng_dev.video_scan[i]);
	sprintf(info[n].name, ng_dev.video_scan[i]);
	close(fd);
	n++;
    }
    return info;
}

static int bsd_flags(void *handle)
{
    int ret = 0;

    ret |= CAN_CAPTURE;
    ret |= CAN_TUNE;
    return ret;
}

static struct ng_attribute* bsd_attrs(void *handle)
{
    struct bsd_handle *h = handle;

    return h->attr;
}

/* ---------------------------------------------------------------------- */

static int
bsd_get_range(int id, int *get, long *set)
{
    switch (id) {
    case ATTR_ID_HUE:
	*get = BT848_GHUE;
	*set = BT848_SHUE;
	break;
    case ATTR_ID_BRIGHT:
	*get = BT848_GBRIG;
	*set = BT848_SBRIG;
	break;
    case ATTR_ID_CONTRAST:
	*get = BT848_GCONT;
	*set = BT848_SCONT;
	break;
    case ATTR_ID_COLOR:
	*get = BT848_GCSAT;
	*set = BT848_SCSAT;
	break;
    default:
	return -1;
    }
    return 0;
}

static int bsd_read_attr(struct ng_attribute *attr)
{
    struct bsd_handle *h = attr->handle;
    int get, i;
    long arg, set;
    int value = -1;

    BUG_ON(h->fd == -1,"device not open");
    switch (attr->id) {
    case ATTR_ID_NORM:
	if (-1 != xioctl(h->fd,BT848GFMT,&arg))
	    for (i = 0; i < sizeof(norms_map)/sizeof(*norms_map); i++)
		if (arg == norms_map[i])
		    value = i;
	break;
    case ATTR_ID_INPUT:
	if (-1 != xioctl(h->fd,METEORGINPUT,&arg))
	    for (i = 0; i < sizeof(inputs_map)/sizeof(*inputs_map); i++)
		if (arg == inputs_map[i])
		    value = i;
	break;
    case ATTR_ID_MUTE:
	if (-1 != xioctl(h->tfd, BT848_GAUDIO, &arg))
	    value = (arg == AUDIO_MUTE) ? 1 : 0;
	break;
    case ATTR_ID_HUE:
    case ATTR_ID_BRIGHT:
    case ATTR_ID_CONTRAST:
    case ATTR_ID_COLOR:
	bsd_get_range(attr->id,&get,&set);
	if (-1 != xioctl(h->tfd,get,&arg))
	    value = arg;
	break;
    case ATTR_ID_COUNT+1: /* AUDIO */
	if (-1 != xioctl(h->tfd, BT848_GAUDIO, &arg))
	    for (i = 0; i < sizeof(audio_map)/sizeof(*audio_map); i++)
		if (arg == audio_map[i])
		    value = i;
	break;
    default:
	break;
    }
    return value;
}

static void bsd_write_attr(struct ng_attribute *attr, int value)
{
    struct bsd_handle *h = attr->handle;
    int get;
    long arg, set;

    BUG_ON(h->fd == -1,"device not open");
    switch (attr->id) {
    case ATTR_ID_NORM:
	xioctl(h->fd,BT848SFMT,&norms_map[value]);
	break;
    case ATTR_ID_INPUT:
	xioctl(h->fd,METEORSINPUT,&inputs_map[value]);
	break;
    case ATTR_ID_MUTE:
	h->muted = value;
	arg = h->muted ? AUDIO_MUTE : AUDIO_UNMUTE;
	xioctl(h->tfd, BT848_SAUDIO, &arg);
	break;
    case ATTR_ID_HUE:
    case ATTR_ID_BRIGHT:
    case ATTR_ID_CONTRAST:
    case ATTR_ID_COLOR:
	bsd_get_range(attr->id,&get,&set);
	arg = value;
	xioctl(h->tfd,set,&arg);
	break;
    case ATTR_ID_COUNT+1: /* audio */
	xioctl(h->tfd, BT848_SAUDIO,&audio_map[value]);
	break;
    default:
	break;
    }
}

static unsigned long bsd_getfreq(void *handle)
{
    struct bsd_handle *h = handle;
    unsigned long freq = 0;

    BUG_ON(h->fd == -1,"device not open");
    if (-1 == ioctl(h->tfd, TVTUNER_GETFREQ, &freq))
	perror("bktr: ioctl TVTUNER_GETFREQ");
    if (ng_debug)
	fprintf(stderr,"bktr: get freq: %.3f\n",(float)freq/16);
    return freq;
}

static void bsd_setfreq(void *handle, unsigned long freq)
{
    struct bsd_handle *h = handle;

    BUG_ON(h->fd == -1,"device not open");
    if (ng_debug)
	fprintf(stderr,"bktr: set freq: %.3f\n",(float)freq/16);
    if (-1 == ioctl(h->tfd, TVTUNER_SETFREQ, &freq))
	perror("bktr: ioctl TVTUNER_SETFREQ");
}

static int bsd_tuned(void *handle)
{
    struct bsd_handle *h = handle;
    int signal;

    BUG_ON(h->fd == -1,"device not open");
    usleep(10000);
    if (-1 == xioctl(h->tfd, TVTUNER_GETSTATUS, &signal))
        return 0;
    return signal == 106 ? 1 : 0;
}

/* ---------------------------------------------------------------------- */
/* overlay                                                                */


static void
set_overlay(struct bsd_handle *h, int state)
{
    if (h->ov_on == state)
	return;
    h->ov_on = state;
    
    if (state) {
	/* enable */
	xioctl(h->fd, METEORSVIDEO, &h->pos);
	xioctl(h->fd, METEORSETGEO, &h->ovgeo);
	xioctl(h->fd, METEORSACTPIXFMT, h->ovfmt);
	xioctl(h->fd, BT848SCLIP, &h->clip);
	xioctl(h->fd, METEORCAPTUR, &start);
    } else {
	/* disable */
	xioctl(h->fd, METEORCAPTUR, &stop);
    }
}

#if 0
static int bsd_setupfb(void *handle, struct ng_video_fmt *fmt, void *base)
{
    struct bsd_handle *h = handle;

    h->fb.addr     = (long)base;
    h->fb.width    = fmt->bytesperline;
    h->fb.banksize = fmt->bytesperline * fmt->height;
    h->fb.ramsize  = fmt->bytesperline * fmt->height / 1024;
    return 0;
}

static int bsd_overlay(void *handle, struct ng_video_fmt *fmt, int x, int y,
		       struct OVERLAY_CLIP *oc, int count, int aspect)
{
    struct bsd_handle *h = handle;
    int i,win_width,win_height,win_x,win_y;

    h->ov_enabled = 0;
    set_overlay(h,h->ov_enabled);
    if (NULL == fmt)
	return 0;

    if (-1 == h->xawtv2pf[fmt->fmtid])
	return -1;

    /* fixups - fixme: no fixed max size */
    win_x      = x;
    win_y      = y;
    win_width  = fmt->width;
    win_height = fmt->height;
    if (win_width > 768) {
	win_width = 768;
	win_x += (fmt->width - win_width)/2;
    }
    if (win_height > 576) {
	win_height = 576;
	win_y +=  (fmt->height - win_height)/2;
    }
    if (aspect)
	ng_ratio_fixup(&win_width,&win_height,&win_x,&win_y);
    ng_check_clipping(win_width, win_height,
		      x - win_x, y - win_y,
		      oc, &count);

    /* fill data */
    h->pos           = h->fb;
    h->pos.addr     += win_y*h->pos.width;
    h->pos.addr     += win_x*ng_vfmt_to_depth[fmt->fmtid]>>3;
    h->ovgeo.rows    = win_height;
    h->ovgeo.columns = win_width;
    h->ovgeo.frames  = 1;
    h->ovgeo.oformat = 0x10000;

    if (ng_debug)
	fprintf(stderr,"bktr: overlay win=%dx%d+%d+%d, %d clips\n",
		win_width,win_height,win_x,win_y,count);

    /* clipping */
    memset(h->clip,0,sizeof(h->clip));
    for (i = 0; i < count; i++) {
#if 0
	/* This way it *should* work IMHO ... */
	h->clip[i].x_min      = oc[i].x1;
	h->clip[i].x_max      = oc[i].x2;
	h->clip[i].y_min      = oc[i].y1;
	h->clip[i].y_max      = oc[i].y2;
#else
	/* This way it does work.  Sort of ... */
	h->clip[i].x_min      = (oc[i].y1) >> 1;
	h->clip[i].x_max      = (oc[i].y2) >> 1;
	h->clip[i].y_min      = oc[i].x1;
	h->clip[i].y_max      = oc[i].x2;
#endif
    }
    h->ovfmt = h->pf+h->xawtv2pf[fmt->fmtid];

    h->ov_enabled = 1;
    set_overlay(h,h->ov_enabled);
    return 0;
}
#endif

/* ---------------------------------------------------------------------- */
/* capture                                                                */

static void
catchsignal(int signal)
{
    if (signal == SIGUSR1  &&  ng_debug > 1)
	fprintf(stderr,"bktr: sigusr1\n");
    if (signal == SIGALRM)
	fprintf(stderr,"bktr: sigalrm\n");
}

static void
siginit(void)
{
    struct sigaction act,old;

    memset(&act,0,sizeof(act));
    sigemptyset(&act.sa_mask);
    act.sa_handler  = catchsignal;
    sigaction(SIGUSR1,&act,&old);
    sigaction(SIGALRM,&act,&old);
}

static int bsd_setformat(void *handle, struct ng_video_fmt *fmt)
{
    struct bsd_handle *h = handle;

    BUG_ON(h->fd == -1,"device not open");
    if (-1 == h->xawtv2pf[fmt->fmtid])
	return -1;

    if (fmt->width > 768)
	fmt->width = 768;
    if (fmt->height > 576)
	fmt->height = 576;
    fmt->bytesperline = fmt->width * ng_vfmt_to_depth[fmt->fmtid] / 8;

    h->capfmt = h->pf+h->xawtv2pf[fmt->fmtid];
    h->capgeo.rows    = fmt->height;
    h->capgeo.columns = fmt->width;
    h->capgeo.frames  = 1;
    h->capgeo.oformat = 0 /* FIXME */;
    if (fmt->height <= 320)
	h->capgeo.oformat |= METEOR_GEO_ODD_ONLY;
    h->fmt = *fmt;
    return 0;
}

static void
set_capture(struct bsd_handle *h, int state)
{
    if (state) {
	/* enable */
	xioctl(h->fd, METEORSVIDEO, &h->nofb);
	xioctl(h->fd, METEORSETGEO, &h->capgeo);
	xioctl(h->fd, METEORSACTPIXFMT, h->capfmt);
	xioctl(h->fd, BT848SCLIP, &h->noclip);
    } else {
	/* disable */
	xioctl(h->fd, METEORCAPTUR, &stop);
    }
}

static int bsd_startvideo(void *handle, int fps, unsigned int buffers)
{
    struct bsd_handle *h = handle;

    BUG_ON(h->fd == -1,"device not open");
    set_overlay(h,0);
    h->fps = fps;
    h->start = ng_get_timestamp();
    set_capture(h,1);
    xioctl(h->fd, METEORSSIGNAL, &signal_on);
    xioctl(h->fd, METEORCAPTUR, &start);
    return 0;
}

static void bsd_stopvideo(void *handle)
{
    struct bsd_handle *h = handle;

    BUG_ON(h->fd == -1,"device not open");
    h->fps = 0;
    set_capture(h,0);
    xioctl(h->fd, METEORCAPTUR, &stop);
    xioctl(h->fd, METEORSSIGNAL, &signal_off);
    set_overlay(h,h->ov_enabled);
}

static struct ng_video_buf* bsd_nextframe(void *handle)
{
    struct bsd_handle *h = handle;
    struct ng_video_buf *buf;
    int size;
    sigset_t sa_mask;

    BUG_ON(h->fd == -1,"device not open");
    size = h->fmt.bytesperline * h->fmt.height;
    buf = ng_malloc_video_buf(NULL,&h->fmt);

    alarm(1);
    sigfillset(&sa_mask);
    sigdelset(&sa_mask,SIGUSR1);
    sigdelset(&sa_mask,SIGALRM);
    sigsuspend(&sa_mask);
    alarm(0);

    memcpy(buf->data,h->map,size);
    buf->info.ts = ng_get_timestamp() - h->start;
    return buf;
}

static struct ng_video_buf* bsd_getimage(void *handle)
{
    struct bsd_handle *h = handle;
    struct ng_video_buf *buf;
    int size;

    BUG_ON(h->fd == -1,"device not open");
    set_overlay(h,0);
    set_capture(h,1);

    size = h->fmt.bytesperline * h->fmt.height;
    buf = ng_malloc_video_buf(NULL,&h->fmt);
    xioctl(h->fd, METEORCAPTUR, &single);
    memcpy(buf->data,h->map,size);

    set_capture(h,0);
    set_overlay(h,h->ov_enabled);

    return buf;
}

/* ---------------------------------------------------------------------- */

static void __init plugin_init(void)
{
    ng_vid_driver_register(NG_PLUGIN_MAGIC,__FILE__,&bsd_driver);
}
