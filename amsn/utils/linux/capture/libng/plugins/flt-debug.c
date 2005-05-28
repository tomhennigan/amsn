/*
 * This plugin provides some filter controls (for GUI code debugging).
 * It does nothing else, video frames just passed through as-is.
 *
 * You can have a look at the invert filter for sample code which
 * actually does some image processing.
 *
 * (c) 2002 Gerd Knorr <kraxel@bytesex.org>
 *
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#include "grab-ng.h"

/* ------------------------------------------------------------------- */

static void *init(struct ng_video_fmt *out)
{
    /* don't have to carry around status info */
    static int dummy;
    return &dummy;
}

static struct ng_video_buf*
frame(void *handle, struct ng_video_buf *in)
{
    /* do nothing -- just return the frame as-is */
    return in;
}

static void fini(void *handle)
{
    /* nothing to clean up */
}

/* ------------------------------------------------------------------- */

static int vals[3] = { 32, 1, 2 };

static int read_attr(struct ng_attribute *attr)
{
    return vals[attr->id];
}

static void write_attr(struct ng_attribute *attr, int value)
{
    fprintf(stderr,PLUGNAME ": %s: %d\n", attr->name, value);
    vals[attr->id] = value;
}

/* ------------------------------------------------------------------- */

static struct STRTAB items[] = {
    {  1, "entry 1" },
    {  2, "entry 2" },
    {  3, "entry 3" },
    { -1, NULL },
};

static struct ng_attribute attrs[] = {
    {
	.id       = 0,
	.name     = "scale (integer)",
	.type     = ATTR_TYPE_INTEGER,
	.min      = 0,
	.max      = 100,
	.read     = read_attr,
	.write    = write_attr,
    },{
	.id       = 1,
	.name     = "yes/no (boolean)",
	.type     = ATTR_TYPE_BOOL,
	.read     = read_attr,
	.write    = write_attr,
    },{
	.id       = 2,
	.name     = "menu (choice)",
	.type     = ATTR_TYPE_CHOICE,
	.choices  = items,
	.read     = read_attr,
	.write    = write_attr,
    },{
	/* end of list */
    }
};

static struct ng_filter filter = {
    .name    = "gui debug",
    .attrs   = attrs,
    fmts:
    (1 << VIDEO_RGB08)    |
    (1 << VIDEO_GRAY)     |
    (1 << VIDEO_RGB15_LE) |
    (1 << VIDEO_RGB16_LE) |
    (1 << VIDEO_RGB15_BE) |
    (1 << VIDEO_RGB16_BE) |
    (1 << VIDEO_BGR24)    |
    (1 << VIDEO_BGR32)    |
    (1 << VIDEO_RGB24)    |
    (1 << VIDEO_RGB32)    |
    (1 << VIDEO_YUV422)   |
    (1 << VIDEO_YUV422P)  |
    (1 << VIDEO_YUV420P),
    .init    = init,
    .frame   = frame,
    .fini    = fini,
};

static void __init plugin_init(void)
{
    ng_filter_register(NG_PLUGIN_MAGIC,PLUGNAME,&filter);
}
