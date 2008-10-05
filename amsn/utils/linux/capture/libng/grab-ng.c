/*
 * next generation[tm] xawtv capture interfaces
 *
 * (c) 2001 Gerd Knorr <kraxel@bytesex.org>
 *
 */

#define NG_PRIVATE
#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>
#include <dirent.h>
#include <fnmatch.h>
#include <errno.h>
#include <ctype.h>
#include <inttypes.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <dlfcn.h>
#ifndef RTLD_NOW
# define RTLD_NOW RTLD_LAZY
#endif

#include "grab-ng.h"

#ifdef HAVE_LIBV4L
#include <libv4l2.h>
#else
#define v4l2_open open
#define v4l2_close close
#endif

int  ng_debug          = 0;
int  ng_log_bad_stream = 0;
int  ng_log_resync     = 0;

int  ng_chromakey      = 0x00ff00ff;
int  ng_ratio_x        = 4;
int  ng_ratio_y        = 3;
int  ng_jpeg_quality   = 75;

char ng_v4l_conf[256]  = "v4l-conf";

/* --------------------------------------------------------------------- */

const unsigned int ng_vfmt_to_depth[VIDEO_FMT_COUNT] = {
    0,               /* unused   */
    8,               /* RGB8     */
    8,               /* GRAY8    */
    16,              /* RGB15 LE */
    16,              /* RGB16 LE */
    16,              /* RGB15 BE */
    16,              /* RGB16 BE */
    24,              /* BGR24    */
    32,              /* BGR32    */
    24,              /* RGB24    */
    32,              /* RGB32    */
    16,              /* LUT2     */
    32,              /* LUT4     */
    16,		     /* YUYV     */
    16,		     /* YUV422P  */
    12,		     /* YUV420P  */
    0,		     /* MJPEG    */
    0,		     /* JPEG     */
    16,		     /* UYVY     */
    0,		     /* MPEG     */
    24,		     /* BAYER	*/
    24,		     /* S910	*/
};

const char* ng_vfmt_to_desc[VIDEO_FMT_COUNT] = {
    "none",
    "8 bit PseudoColor (dithering)",
    "8 bit StaticGray",
    "15 bit TrueColor (LE)",
    "16 bit TrueColor (LE)",
    "15 bit TrueColor (BE)",
    "16 bit TrueColor (BE)",
    "24 bit TrueColor (LE: bgr)",
    "32 bit TrueColor (LE: bgr-)",
    "24 bit TrueColor (BE: rgb)",
    "32 bit TrueColor (BE: -rgb)",
    "16 bit TrueColor (lut)",
    "32 bit TrueColor (lut)",
    "16 bit YUV 4:2:2 (packed, YUYV)",
    "16 bit YUV 4:2:2 (planar)",
    "12 bit YUV 4:2:0 (planar)",
    "MJPEG (AVI)",
    "JPEG (JFIF)",
    "16 bit YUV 4:2:2 (packed, UYVY)",
    "MPEG video",
    "Sequential Bayer (BA81)",
    "SN9C102 Driver Compressed Format (S910)",  
};

/* --------------------------------------------------------------------- */

const unsigned int   ng_afmt_to_channels[AUDIO_FMT_COUNT] = {
    0,  1,  2,  1,  2,  1,  2, 0
};
const unsigned int   ng_afmt_to_bits[AUDIO_FMT_COUNT] = {
    0,  8,  8, 16, 16, 16, 16, 0
};
const char* ng_afmt_to_desc[AUDIO_FMT_COUNT] = {
    "none",
    "8bit mono",
    "8bit stereo",
    "16bit mono (LE)",
    "16bit stereo (LE)",
    "16bit mono (BE)",
    "16bit stereo (BE)",
    "MPEG audio",
};

/* --------------------------------------------------------------------- */

const char* ng_attr_to_desc[] = {
    "none",
    "norm",
    "input",
    "volume",
    "mute",
    "audio mode",
    "color",
    "bright",
    "hue",
    "contrast",
};

/* --------------------------------------------------------------------- */

void ng_init_video_buf(struct ng_video_buf *buf)
{
    memset(buf,0,sizeof(*buf));
    pthread_mutex_init(&buf->lock,NULL);    
    pthread_cond_init(&buf->cond,NULL);
}

void ng_release_video_buf(struct ng_video_buf *buf)
{
    int release;

    pthread_mutex_lock(&buf->lock);
    buf->refcount--;
    release = (buf->refcount == 0);
    pthread_mutex_unlock(&buf->lock);
    if (release && NULL != buf->release)
	buf->release(buf);
}

void ng_print_video_buf(char *tag, struct ng_video_buf *buf)
{
    fprintf(stderr,"buf %5s: %dx%d [%s]\n",
	    tag, buf->fmt.width, buf->fmt.height,
	    ng_vfmt_to_desc[buf->fmt.fmtid]);
}

void ng_copy_video_buf(struct ng_video_buf *dst, struct ng_video_buf *src)
{
    memcpy(dst->data, src->data, src->size);
    dst->size = src->size;
    dst->info = src->info;
}

void ng_wakeup_video_buf(struct ng_video_buf *buf)
{
    pthread_cond_signal(&buf->cond);
}

void ng_waiton_video_buf(struct ng_video_buf *buf)
{
    pthread_mutex_lock(&buf->lock);
    while (buf->refcount)
	pthread_cond_wait(&buf->cond, &buf->lock);
    pthread_mutex_unlock(&buf->lock);
}

static int malloc_video_bufs;
static int malloc_audio_bufs;

static void ng_free_video_buf(struct ng_video_buf *buf)
{
    free(buf->data);
    free(buf);
    malloc_video_bufs--;
}

struct ng_video_buf*
ng_malloc_video_buf(void *handle, struct ng_video_fmt *fmt)
{
    struct ng_video_buf *buf;

    buf = malloc(sizeof(*buf));
    if (NULL == buf)
	return NULL;
    ng_init_video_buf(buf);
    buf->fmt  = *fmt;
    buf->size = fmt->height * fmt->bytesperline;
    if (0 == buf->size)
	buf->size = fmt->width * fmt->height * 3;
    buf->data = malloc(buf->size);
    if (NULL == buf->data) {
	free(buf);
	return NULL;
    }
    buf->refcount = 1;
    buf->release  = ng_free_video_buf;
    malloc_video_bufs++;
    return buf;
}

struct ng_audio_buf*
ng_malloc_audio_buf(struct ng_audio_fmt *fmt, int size)
{
    struct ng_audio_buf *buf;

    buf = malloc(sizeof(*buf)+size);
    memset(buf,0,sizeof(*buf));
    buf->fmt  = *fmt;
    buf->size = size;
    buf->data = (char*)buf + sizeof(*buf);
    malloc_audio_bufs++;
    return buf;
}

void ng_free_audio_buf(struct ng_audio_buf *buf)
{
    malloc_audio_bufs--;
    free(buf);
}

static void __fini malloc_bufs_check(void)
{
    OOPS_ON(malloc_video_bufs > 0, "malloc_video_bufs is %d (expected 0)",
	    malloc_video_bufs);
    OOPS_ON(malloc_audio_bufs > 0, "malloc_audio_bufs is %d (expected 0)",
	    malloc_audio_bufs);
}

/* --------------------------------------------------------------------- */

struct ng_attribute*
ng_attr_byid(struct ng_devstate *dev, int id)
{
    struct list_head     *item;
    struct ng_attribute  *attr;
    
    list_for_each(item, &dev->attrs) {
	attr = list_entry(item, struct ng_attribute, device_list);
	if (attr->id == id)
	    return attr;
    }
    return NULL;
}

struct ng_attribute*
ng_attr_byname(struct ng_devstate *dev, char *name)
{
    struct list_head     *item;
    struct ng_attribute  *attr;
    
    list_for_each(item, &dev->attrs) {
	attr = list_entry(item, struct ng_attribute, device_list);
	if (0 == strcasecmp(attr->name,name))
	    return attr;
    }
    return NULL;
}

const char*
ng_attr_getstr(struct ng_attribute *attr, int value)
{
    int i;
    
    if (NULL == attr)
	return NULL;
    if (attr->type != ATTR_TYPE_CHOICE)
	return NULL;

    for (i = 0; attr->choices[i].str != NULL; i++)
	if (attr->choices[i].nr == value)
	    return attr->choices[i].str;
    return NULL;
}

int
ng_attr_getint(struct ng_attribute *attr, char *value)
{
    int i,val;
    
    if (NULL == attr)
	return -1;
    if (attr->type != ATTR_TYPE_CHOICE)
	return -1;

    for (i = 0; attr->choices[i].str != NULL; i++) {
	if (0 == strcasecmp(attr->choices[i].str,value))
	    return attr->choices[i].nr;
    }

    if (isdigit(value[0])) {
	/* Hmm.  String not found, but starts with a digit.
	   Check if this is a valid number ... */
	val = atoi(value);
	for (i = 0; attr->choices[i].str != NULL; i++)
	    if (val == attr->choices[i].nr)
		return attr->choices[i].nr;
	
    }
    return -1;
}

void
ng_attr_listchoices(struct ng_attribute *attr)
{
    int i;
    
    fprintf(stderr,"valid choices for \"%s\": ",attr->name);
    for (i = 0; attr->choices[i].str != NULL; i++)
	fprintf(stderr,"%s\"%s\"",
		i ? ", " : "",
		attr->choices[i].str);
    fprintf(stderr,"\n");
}

int
ng_attr_int2percent(struct ng_attribute *attr, int value)
{
    int range,percent;

    range   = attr->max - attr->min;
    percent = (value - attr->min) * 100 / range;
    if (percent < 0)
	percent = 0;
    if (percent > 100)
	percent = 100;
    return percent;
}

int
ng_attr_percent2int(struct ng_attribute *attr, int percent)
{
    int range,value;

    range = attr->max - attr->min;
    value = percent * range / 100 + attr->min;
    if (value < attr->min)
	value = attr->min;
    if (value > attr->max)
	value = attr->max;
    return value;
}

int
ng_attr_parse_int(struct ng_attribute *attr, char *str)
{
    int value,n;

    if (0 == sscanf(str,"%d%n",&value,&n))
	/* parse error */
	return attr->defval;
    if (str[n] == '%')
	value = ng_attr_percent2int(attr,value);
    if (value < attr->min)
	value = attr->min;
    if (value > attr->max)
	value = attr->max;
    return value;
}

/* --------------------------------------------------------------------- */

void
ng_ratio_fixup(int *width, int *height, int *xoff, int *yoff)
{
    int h = *height;
    int w = *width;

    if (0 == ng_ratio_x || 0 == ng_ratio_y)
	return;
    if (w * ng_ratio_y < h * ng_ratio_x) {
	*height = *width * ng_ratio_y / ng_ratio_x;
	if (yoff)
	    *yoff  += (h-*height)/2;
    } else if (w * ng_ratio_y > h * ng_ratio_x) {
	*width  = *height * ng_ratio_x / ng_ratio_y;
	if (yoff)
	    *xoff  += (w-*width)/2;
    }
}

void
ng_ratio_fixup2(int *width, int *height, int *xoff, int *yoff,
		int ratio_x, int ratio_y, int up)
{
    int h = *height;
    int w = *width;

    if (0 == ratio_x || 0 == ratio_y)
	return;
    if ((!up  &&  w * ratio_y < h * ratio_x) ||
	(up   &&  w * ratio_y > h * ratio_x)) {
	*height = *width * ratio_y / ratio_x;
	if (yoff)
	    *yoff  += (h-*height)/2;
    } else if ((!up  &&  w * ratio_y > h * ratio_x) ||
	       (up   &&  w * ratio_y < h * ratio_x)) {
	*width  = *height * ratio_x / ratio_y;
	if (yoff)
	    *xoff  += (w-*width)/2;
    }
}

/* --------------------------------------------------------------------- */

LIST_HEAD(ng_conv);
LIST_HEAD(ng_aconv);
LIST_HEAD(ng_filters);
LIST_HEAD(ng_writers);
LIST_HEAD(ng_readers);
LIST_HEAD(ng_vid_drivers);
LIST_HEAD(ng_dsp_drivers);
LIST_HEAD(ng_mix_drivers);

static int ng_check_magic(int magic, char *plugname, char *type)
{
    char *h;

    h=strrchr(plugname,'/');
    if (h)
	h++;
    else
	h=plugname;
    
    if (magic != NG_PLUGIN_MAGIC) {
	fprintf(stderr, "ERROR: plugin magic mismatch [me=%x,%s=%x]\n",
		NG_PLUGIN_MAGIC,h,magic);
	return -1;
    }
#if 0
    if (ng_debug)
	fprintf(stderr,"plugins: %s registered by %s\n",type,plugname);
#endif
    return 0;
}

int
ng_conv_register(int magic, char *plugname,
		 struct ng_video_conv *list, int count)
{
    int n;

    if (0 != ng_check_magic(magic,plugname,"video converters"))
	return -1;
    for (n = 0; n < count; n++)
	list_add_tail(&(list[n].list),&ng_conv);
    return 0;
}

int
ng_aconv_register(int magic, char *plugname,
		  struct ng_audio_conv *list, int count)
{
    int n;
    
    if (0 != ng_check_magic(magic,plugname,"audio converters"))
	return -1;
    for (n = 0; n < count; n++)
	list_add_tail(&(list[n].list),&ng_aconv);
    return 0;
}

int
ng_filter_register(int magic, char *plugname, struct ng_video_filter *filter)
{
    if (0 != ng_check_magic(magic,plugname,"filter"))
	return -1;
    list_add_tail(&filter->list,&ng_filters);
    return 0;
}

int
ng_writer_register(int magic, char *plugname, struct ng_writer *writer)
{
    if (0 != ng_check_magic(magic,plugname,"writer"))
	return -1;
    list_add_tail(&writer->list,&ng_writers);
    return 0;
}

int
ng_reader_register(int magic, char *plugname, struct ng_reader *reader)
{
    if (0 != ng_check_magic(magic,plugname,"reader"))
	return -1;
    list_add_tail(&reader->list,&ng_readers);
    return 0;
}

int
ng_vid_driver_register(int magic, char *plugname, struct ng_vid_driver *driver)
{
    struct list_head *item;
    struct ng_vid_driver *drv;

    if (0 != ng_check_magic(magic,plugname,"video drv"))
	return -1;

    list_for_each(item,&ng_vid_drivers) {
        drv = list_entry(item, struct ng_vid_driver, list);
	if (drv->priority > driver->priority) {
	    list_add_tail(&driver->list,&drv->list);
	    return 0;
	}
    }
    list_add_tail(&driver->list,&ng_vid_drivers);
    return 0;
}

int
ng_dsp_driver_register(int magic, char *plugname, struct ng_dsp_driver *driver)
{
    struct list_head *item;
    struct ng_dsp_driver *drv;

    if (0 != ng_check_magic(magic,plugname,"dsp drv"))
	return -1;

    list_for_each(item,&ng_dsp_drivers) {
        drv = list_entry(item, struct ng_dsp_driver, list);
	if (drv->priority > driver->priority) {
	    list_add_tail(&driver->list,&drv->list);
	    return 0;
	}
    }
    list_add_tail(&driver->list,&ng_dsp_drivers);
    return 0;
}

int
ng_mix_driver_register(int magic, char *plugname, struct ng_mix_driver *driver)
{
    struct list_head *item;
    struct ng_mix_driver *drv;

    if (0 != ng_check_magic(magic,plugname,"mixer drv"))
	return -1;

    list_for_each(item,&ng_mix_drivers) {
        drv = list_entry(item, struct ng_mix_driver, list);
	if (drv->priority > driver->priority) {
	    list_add_tail(&driver->list,&drv->list);
	    return 0;
	}
    }
    list_add_tail(&driver->list,&ng_mix_drivers);
    return 0;
}

struct ng_video_conv*
ng_conv_find_to(unsigned int out, int *i)
{
    struct list_head *item;
    struct ng_video_conv *ret;
    int j = 0;

    list_for_each(item,&ng_conv) {
	if (j < *i) {
	    j++;
	    continue;
	}
	ret = list_entry(item, struct ng_video_conv, list);
#if 0
	fprintf(stderr,"\tconv to:  %-28s =>  %s\n",
		ng_vfmt_to_desc[ret->fmtid_in],
		ng_vfmt_to_desc[ret->fmtid_out]);
#endif
	if (ret->fmtid_out == out) {
	    (*i)++;
	    return ret;
	}
	(*i)++;
	j++;
    }
    return NULL;
}

struct ng_video_conv*
ng_conv_find_from(unsigned int in, int *i)
{
    struct list_head *item;
    struct ng_video_conv *ret;
    
    int j = 0;

    list_for_each(item,&ng_conv) {
	if (j < *i) {
	    j++;
	    continue;
	}
	ret = list_entry(item, struct ng_video_conv, list);
#if 0
	fprintf(stderr,"\tconv from:  %-28s =>  %s\n",
		ng_vfmt_to_desc[ret->fmtid_in],
		ng_vfmt_to_desc[ret->fmtid_out]);
#endif
	if (ret->fmtid_in == in) {
	    (*i)++;
	    return ret;
	}
    }
    return NULL;
}

struct ng_video_conv*
ng_conv_find_match(unsigned int in, unsigned int out)
{
    struct list_head *item;
    struct ng_video_conv *ret = NULL;
    
    list_for_each(item,&ng_conv) {
	ret = list_entry(item, struct ng_video_conv, list);
	if (ret->fmtid_in  == in && ret->fmtid_out == out)
	    return ret;
    }
    return NULL;
}

/* --------------------------------------------------------------------- */

int ng_vid_init(struct ng_devstate *dev, char *device)
{
    struct list_head *item;
    struct ng_vid_driver *drv;
    struct ng_attribute *attr;
    void *handle;
    int i, err = ENODEV;

    /* check all grabber drivers */
    memset(dev,0,sizeof(*dev));
    list_for_each(item,&ng_vid_drivers) {
        drv = list_entry(item, struct ng_vid_driver, list);
	if (ng_debug)
	    fprintf(stderr,"vid-open: trying: %s... \n", drv->name);
	if (NULL != (handle = drv->init(device)))
	    break;
	if (errno)
	    err = errno;
	if (ng_debug)
	    fprintf(stderr,"vid-open: failed: %s\n",drv->name);
    }
    if (item == &ng_vid_drivers)
	return err;
    if (ng_debug)
	fprintf(stderr,"vid-open: ok: %s\n", drv->name);

    dev->type   = NG_DEV_VIDEO;
    dev->v      = drv;
    dev->handle = handle;
    dev->device = dev->v->devname(dev->handle);
    dev->flags  = dev->v->capabilities(dev->handle);
    if (ng_debug)
	fprintf(stderr,"vid-open: flags: %x\n", dev->flags);
	
    INIT_LIST_HEAD(&dev->attrs);
    attr = dev->v->list_attrs(dev->handle);
    for (i = 0; attr && attr[i].name; i++) {
	attr[i].dev   = dev;
	attr[i].group = dev->device;
	list_add_tail(&attr[i].device_list,&dev->attrs);
    }
    return 0;
}

struct ng_devinfo* ng_vid_probe(char *driver)
{
    struct list_head *item;
    struct ng_vid_driver *drv;

    /* check all grabber drivers */
    list_for_each(item,&ng_vid_drivers) {
        drv = list_entry(item, struct ng_vid_driver, list);
	if (ng_debug)
	    fprintf(stderr,"vid-probe: trying: %s... \n", drv->name);
	if (strcmp(driver, drv->name))
	    continue;

	return drv->probe(ng_debug);
    }

    return NULL;
}

int ng_dsp_init(struct ng_devstate *dev, char *device, int record)
{
    struct list_head *item;
    struct ng_dsp_driver *drv;
    void *handle;
    int err = ENODEV;

    /* check all dsp drivers */
    list_for_each(item,&ng_dsp_drivers) {
        drv = list_entry(item, struct ng_dsp_driver, list);
	if (record && NULL == drv->read)
	    continue;
	if (!record && NULL == drv->write)
	    continue;
	if (ng_debug)
	    fprintf(stderr, "dsp-open: trying: %s... \n", drv->name);
	if (NULL != (handle = drv->init(device, record)))
	    break;
	if (errno)
	    err = errno;
	if (ng_debug)
	    fprintf(stderr,"dsp-open: failed: %s\n", drv->name);
    }
    if (item == &ng_dsp_drivers)
	return err;
    if (ng_debug)
	fprintf(stderr,"dsp-open: ok: %s\n",drv->name);

    memset(dev,0,sizeof(*dev));
    dev->type   = NG_DEV_DSP;
    dev->a      = drv;
    dev->handle = handle;
    dev->device = dev->a->devname(dev->handle);
    //dev->flags  = dev->a->capabilities(dev->handle);
    INIT_LIST_HEAD(&dev->attrs);

    return 0;
}

int ng_mix_init(struct ng_devstate *dev, char *device, char *control)
{
    struct list_head *item;
    struct ng_mix_driver *drv;
    struct ng_attribute *attr;
    void *handle;
    int i, err = ENODEV;

    /* check all dsp drivers */
    list_for_each(item,&ng_mix_drivers) {
        drv = list_entry(item, struct ng_mix_driver, list);
	if (ng_debug)
	    fprintf(stderr, "mix-open: trying: %s... \n", drv->name);
	if (NULL != (handle = drv->init(device, control)))
	    break;
	if (errno)
	    err = errno;
	if (ng_debug)
	    fprintf(stderr,"mix-open: failed: %s\n", drv->name);
    }
    if (item == &ng_mix_drivers)
	return err;
    if (ng_debug)
	fprintf(stderr,"mix-open: ok: %s\n",drv->name);

    memset(dev,0,sizeof(*dev));
    dev->type   = NG_DEV_MIX;
    dev->m      = drv;
    dev->handle = handle;
    dev->device = dev->m->devname(dev->handle);

    INIT_LIST_HEAD(&dev->attrs);
    attr = dev->m->list_attrs(dev->handle);
    for (i = 0; attr && attr[i].name; i++) {
	attr[i].dev   = dev;
	attr[i].group = dev->device;
	list_add_tail(&attr[i].device_list,&dev->attrs);
    }

    return 0;
}

int ng_dev_fini(struct ng_devstate *dev)
{
    switch (dev->type) {
    case NG_DEV_NONE:
	/* nothing */
	break;
    case NG_DEV_VIDEO:
	dev->v->fini(dev->handle);
	break;
    case NG_DEV_DSP:
	dev->a->fini(dev->handle);
	break;
    case NG_DEV_MIX:
	dev->m->fini(dev->handle);
	break;
    }
    memset(dev,0,sizeof(*dev));
    return 0;
}

int ng_dev_open(struct ng_devstate *dev)
{
    int rc = 0;

    if (0 == dev->refcount) {
	switch (dev->type) {
	case NG_DEV_NONE:
	    BUG_ON(1,"dev type NONE");
	    break;
	case NG_DEV_VIDEO:
	    rc = dev->v->open(dev->handle);
	    break;
	case NG_DEV_DSP:
	    rc = dev->a->open(dev->handle);
	    break;
	case NG_DEV_MIX:
	    rc = dev->m->open(dev->handle);
	    break;
	}
    }
    if (0 == rc) {
	dev->refcount++;
	if (ng_debug)
	    fprintf(stderr,"%s: opened %s [refcount %d]\n",
		    __FUNCTION__, dev->device, dev->refcount);
    }
    return rc;
}

int ng_dev_close(struct ng_devstate *dev)
{
    dev->refcount--;
    BUG_ON(dev->refcount < 0, "refcount below 0");
    
    if (0 == dev->refcount) {
	switch (dev->type) {
	case NG_DEV_NONE:
	    BUG_ON(1,"dev type NONE");
	    break;
	case NG_DEV_VIDEO:
	    dev->v->close(dev->handle);
	    break;
	case NG_DEV_DSP:
	    dev->a->close(dev->handle);
	    break;
	case NG_DEV_MIX:
	    dev->m->close(dev->handle);
	    break;
	}
    }
    if (ng_debug)
	fprintf(stderr,"%s: closed %s [refcount %d]\n",
		__FUNCTION__, dev->device, dev->refcount);
    return 0;
}

int ng_dev_users(struct ng_devstate *dev)
{
    return dev->refcount;
}

int ng_chardev_open(char *device, int flags, int major, int complain)
{
    struct stat st;
    int fd = -1;

    if (strncmp(device, "/dev/", 5)) {
	if (complain)
	    fprintf(stderr,"%s: not below /dev\n",device);
	goto err;
    }
    if (-1 == (fd = v4l2_open(device, flags))) {
	if (complain)
	    fprintf(stderr,"open(%s): %s\n",device,strerror(errno));
	goto err;
    }
    if (-1 == fstat(fd,&st)) {
	if (complain)
	    fprintf(stderr,"fstat(%s): %s\n",device,strerror(errno));
	goto err;
    }
    if (!S_ISCHR(st.st_mode)) {
	if (complain)
	    fprintf(stderr,"%s: not a charcter device\n",device);
	goto err;
    }
    if (major(st.st_rdev) != major) {
	if (complain)
	    fprintf(stderr,"%s: wrong major number (expected %d, got %d)\n",
		    device, major, major(st.st_rdev));
	goto err;
    }
    fcntl(fd,F_SETFD,FD_CLOEXEC);
    return fd;

 err:
    if (-1 != fd)
	v4l2_close(fd);
    return -1;
}

/* --------------------------------------------------------------------- */

struct ng_reader* ng_find_reader_magic(char *filename)
{
    struct list_head *item;
    struct ng_reader *reader;
    char blk[512];
    FILE *fp;
    int m;

    if (NULL == (fp = fopen(filename, "r"))) {
	fprintf(stderr,"open %s: %s\n",filename,strerror(errno));
        return NULL;
    }
    memset(blk,0,sizeof(blk));
    fread(blk,1,sizeof(blk),fp);
    fclose(fp);

    list_for_each(item,&ng_readers) {
	reader = list_entry(item, struct ng_reader, list);
	for (m = 0; m < 8 && reader->mlen[m] > 0; m++) {
	    if (0 == memcmp(blk+reader->moff[m],reader->magic[m],
			    reader->mlen[m]))
		return reader;
	}
    }
    if (ng_debug)
	fprintf(stderr,"%s: no reader found [magic]\n",filename);
    return NULL;
}

struct ng_reader* ng_find_reader_name(char *name)
{
    struct list_head *item;
    struct ng_reader *reader;

    list_for_each(item,&ng_readers) {
	reader = list_entry(item, struct ng_reader, list);
	if (0 == strcasecmp(reader->name,name))
	    return reader;
    }
    if (ng_debug)
	fprintf(stderr,"%s: no reader found [name]\n",name);
    return NULL;
}

struct ng_writer* ng_find_writer_name(char *name)
{
    struct list_head *item;
    struct ng_writer *writer;

    list_for_each(item,&ng_writers) {
	writer = list_entry(item, struct ng_writer, list);
	if (0 == strcasecmp(writer->name,name))
	    return writer;
    }
    if (ng_debug)
	fprintf(stderr,"%s: no writer found [name]\n",name);
    return NULL;
}

int64_t
ng_tofday_to_timestamp(struct timeval *tv)
{
    long long ts;

    ts  = tv->tv_sec;
    ts *= 1000000;
    ts += tv->tv_usec;
    ts *= 1000;
    return ts;
}

int64_t
ng_get_timestamp()
{
    struct timeval tv;

    gettimeofday(&tv,NULL);
    return ng_tofday_to_timestamp(&tv);
}

struct ng_video_buf*
ng_filter_single(struct ng_video_filter *filter, struct ng_video_buf *in)
{
    struct ng_video_buf *out = in;
    void *handle;

    if (NULL != filter  &&  filter->fmts & (1 << in->fmt.fmtid)) {
	handle = filter->init(&in->fmt);
#if 0
	BUG_ON(1,"not fixed yet");
	out = filter->frame(handle,in);
	filter->fini(handle);
#endif
    }
    return out;
}

/* --------------------------------------------------------------------- */

static void clip_dump(char *state, struct OVERLAY_CLIP *oc, int count)
{
    int i;

    fprintf(stderr,"clip: %s - %d clips\n",state,count);
    for (i = 0; i < count; i++)
	fprintf(stderr,"clip:   %d: %dx%d+%d+%d\n",i,
		oc[i].x2 - oc[i].x1,
		oc[i].y2 - oc[i].y1,
		oc[i].x1, oc[i].y1);
}

static void clip_drop(struct OVERLAY_CLIP *oc, int n, int *count)
{
    (*count)--;
    memmove(oc+n, oc+n+1, sizeof(struct OVERLAY_CLIP) * (*count-n));
}

void ng_check_clipping(int width, int height, int xadjust, int yadjust,
		       struct OVERLAY_CLIP *oc, int *count)
{
    int i,j;

    if (ng_debug > 1) {
	fprintf(stderr,"clip: win=%dx%d xa=%d ya=%d\n",
		width,height,xadjust,yadjust);
	clip_dump("init",oc,*count);
    }
    for (i = 0; i < *count; i++) {
	/* fixup coordinates */
	oc[i].x1 += xadjust;
	oc[i].x2 += xadjust;
	oc[i].y1 += yadjust;
	oc[i].y2 += yadjust;
    }
    if (ng_debug > 1)
	clip_dump("fixup adjust",oc,*count);

    for (i = 0; i < *count; i++) {
	/* fixup borders */
	if (oc[i].x1 < 0)
	    oc[i].x1 = 0;
	if (oc[i].x2 < 0)
	    oc[i].x2 = 0;
	if (oc[i].x1 > width)
	    oc[i].x1 = width;
	if (oc[i].x2 > width)
	    oc[i].x2 = width;
	if (oc[i].y1 < 0)
	    oc[i].y1 = 0;
	if (oc[i].y2 < 0)
	    oc[i].y2 = 0;
	if (oc[i].y1 > height)
	    oc[i].y1 = height;
	if (oc[i].y2 > height)
	    oc[i].y2 = height;
    }
    if (ng_debug > 1)
	clip_dump("fixup range",oc,*count);

    /* drop zero-sized clips */
    for (i = 0; i < *count;) {
	if (oc[i].x1 == oc[i].x2 || oc[i].y1 == oc[i].y2) {
	    clip_drop(oc,i,count);
	    continue;
	}
	i++;
    }
    if (ng_debug > 1)
	clip_dump("zerosize done",oc,*count);

    /* try to merge clips */
 restart_merge:
    for (j = *count - 1; j >= 0; j--) {
	for (i = 0; i < *count; i++) {
	    if (i == j)
		continue;
	    if (oc[i].x1 == oc[j].x1 &&
		oc[i].x2 == oc[j].x2 &&
		oc[i].y1 <= oc[j].y1 &&
		oc[i].y2 >= oc[j].y1) {
		if (ng_debug > 1)
		    fprintf(stderr,"clip: merge y %d,%d\n",i,j);
		if (oc[i].y2 < oc[j].y2)
		    oc[i].y2 = oc[j].y2;
		clip_drop(oc,j,count);
		if (ng_debug > 1)
		    clip_dump("merge y done",oc,*count);
		goto restart_merge;
	    }
	    if (oc[i].y1 == oc[j].y1 &&
		oc[i].y2 == oc[j].y2 &&
		oc[i].x1 <= oc[j].x1 &&
		oc[i].x2 >= oc[j].x1) {
		if (ng_debug > 1)
		    fprintf(stderr,"clip: merge x %d,%d\n",i,j);
		if (oc[i].x2 < oc[j].x2)
		    oc[i].x2 = oc[j].x2;
		clip_drop(oc,j,count);
		if (ng_debug > 1)
		    clip_dump("merge x done",oc,*count);
		goto restart_merge;
	    }
	}
    }
    if (ng_debug)
	clip_dump("final",oc,*count);
}

/* --------------------------------------------------------------------- */

#if 0
void ng_print_stacktrace(void)
{
    void *array[16];
    size_t size;
    char **strings;
    size_t i;
    
    size = backtrace(array, DIMOF(array));
    strings = backtrace_symbols(array, size);
    
    for (i = 0; i < size; i++)
	fprintf(stderr, "\t%s\n", strings[i]);
    free(strings);
}
#endif

static int ng_plugins(char *dirname)
{
    struct dirent **list;
    char filename[1024];
    void *plugin;
#if 1
    void (*initcall)(void);
#endif
    int i,n = 0,l = 0;

    n = scandir(dirname,&list,NULL,alphasort);
    if (n <= 0)
	return 0;
    for (i = 0; i < n; i++) {
	if (0 != fnmatch("*.so",list[i]->d_name,0))
	    continue;
	sprintf(filename,"%s/%s",dirname,list[i]->d_name);
	if (NULL == (plugin = dlopen(filename,RTLD_NOW))) {
	    fprintf(stderr,"dlopen: %s\n",dlerror());
	    continue;
	}

	if (NULL == (initcall = dlsym(plugin,"ng_plugin_init"))) {
	    if (NULL == (initcall = dlsym(plugin,"_ng_plugin_init"))) {
		continue;
	    }
	}
#if 0
	initcall();
#endif
	l++;
    }
    for (i = 0; i < n; i++)
	free(list[i]);
    free(list);
    return l;
}

void
ng_init(void)
{
    static int once=0;
    int count=0;

    if (once++) {
	fprintf(stderr,"panic: ng_init called twice\n");
	return;
    }


    yuv2rgb_init();
    packed_init();

    /* dirty hack: touch ng_dev to make ld _not_ drop devices.o, it is
     *             needed by various plugins */
    if (!ng_dev.video[0])
	return;

    count += ng_plugins(LIBDIR);
    count += ng_plugins("./libng/plugins");
    count += ng_plugins("./libng/contrib-plugins"); 
    count += ng_plugins("../libng/plugins");
    count += ng_plugins("../libng/contrib-plugins");
    count += ng_plugins("./utils/linux/capture/libng/plugins");
    count += ng_plugins("./utils/linux/capture/libng/contrib-plugins");

 
    /*
    if (0 == count)
	fprintf(stderr,"WARNING: no plugins found [%s]\n",LIBDIR);
    */
}
