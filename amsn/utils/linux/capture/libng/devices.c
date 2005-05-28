/*
 * default devices names
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "devices.h"

#if defined(__OpenBSD__) || defined(__FreeBSD__) || defined(__NetBSD__)
struct ng_device_config ng_dev = {
    video:  "/dev/bktr0",
    radio:  NULL,
    vbi:    "/dev/vbi0",
    dsp:    "/dev/dsp",
    mixer:  "/dev/mixer",
    video_scan: {
	"/dev/bktr0",
	"/dev/bktr1",
	"/dev/cxm0",
	"/dev/cxm1",
	NULL
    },
    vbi_scan: {
	"/dev/vbi0",
	"/dev/vbi1",
	NULL
    },
    mixer_scan: {
	"/dev/mixer",
	"/dev/mixer1", 
	"/dev/mixer2",
	"/dev/mixer3",
	NULL
    },
    dsp_scan: {
	"/dev/dsp",
	"/dev/dsp1",
	"/dev/dsp2",
	"/dev/dsp3",
	NULL
    },
};
#endif

#if defined(__linux__)
struct ng_device_config ng_dev = {
    video:  "/dev/video0", /* <rant>thank you redhat breaking
			    * /dev/video as symbolic link to the
			    * default video device ... </rant> */
    radio:  "/dev/radio",
    vbi:    "/dev/vbi",
    dsp:    "/dev/dsp",
    mixer:  "/dev/mixer",
    video_scan:   {
	"/dev/video0",
	"/dev/video1",
	"/dev/video2",
	"/dev/video3",
	NULL
    },
    vbi_scan: {
	"/dev/vbi0",
	"/dev/vbi1",
	"/dev/vbi2",
	"/dev/vbi3",
	NULL
    },
    mixer_scan: {
	"/dev/mixer",
	"/dev/mixer1", 
	"/dev/mixer2",
	"/dev/mixer3",
	NULL
    },
    dsp_scan: {
	"/dev/dsp",
	"/dev/adsp",
	"/dev/dsp1",
	"/dev/adsp1",
	"/dev/dsp2",
	"/dev/adsp2",
	"/dev/dsp3",
	"/dev/adsp3",
	NULL
    },
};

struct ng_device_config ng_dev_devfs = {
    video:  "/dev/v4l/video0",
    radio:  "/dev/v4l/radio0",
    vbi:    "/dev/v4l/vbi0",
    dsp:    "/dev/sound/dsp",
    mixer:  "/dev/sound/mixer",
    video_scan:   {
	"/dev/v4l/video0",
	"/dev/v4l/video1",
	"/dev/v4l/video2",
	"/dev/v4l/video3",
	NULL
    },
    vbi_scan: {
	"/dev/v4l/vbi0",
	"/dev/v4l/vbi1",
	"/dev/v4l/vbi2",
	"/dev/v4l/vbi3",
	NULL
    },
    mixer_scan: {
	"/dev/sound/mixer",
	"/dev/sound/mixer1", 
	"/dev/sound/mixer2",
	"/dev/sound/mixer3",
	NULL
    },
    dsp_scan: {
	"/dev/sound/dsp",
	"/dev/sound/adsp",
	"/dev/sound/dsp1",
	"/dev/sound/adsp1",
	"/dev/sound/dsp2",
	"/dev/sound/adsp2",
	"/dev/sound/dsp3",
	"/dev/sound/adsp3",
	NULL
    },
};
#endif

#if defined(__linux__)
static void __attribute__ ((constructor)) device_init(void)
{
    struct stat st;

    if (-1 == lstat("/dev/.devfsd",&st))
	return;
    if (!S_ISCHR(st.st_mode))
	return;
    ng_dev = ng_dev_devfs;
}
#endif
