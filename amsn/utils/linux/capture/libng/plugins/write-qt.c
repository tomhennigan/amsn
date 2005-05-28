#include "config.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <quicktime/quicktime.h>
#include <quicktime/colormodels.h>
#include <quicktime/lqt.h>

#include "grab-ng.h"

/* ----------------------------------------------------------------------- */

struct qt_video_priv {
    char  fcc[5];
    int   yuvsign;
    int   libencode;
    int   cmodel;
};

struct qt_audio_priv {
    char  fcc[5];
    int   libencode;
};

struct qt_handle {
    /* libquicktime handle */
    quicktime_t *fh;

    /* format */
    struct ng_video_fmt video;
    struct ng_audio_fmt audio;

    /* misc */
    int lib_video;
    int lib_audio;
    int yuvsign;
    int audio_sample;
    unsigned char **rows;
    unsigned char *data;
};

/* ----------------------------------------------------------------------- */

static void*
qt_open(char *filename, char *dummy,
	struct ng_video_fmt *video, const void *priv_video, int fps,
	struct ng_audio_fmt *audio, const void *priv_audio)
{
    const struct qt_video_priv *pvideo = priv_video;
    const struct qt_audio_priv *paudio = priv_audio;
    struct qt_handle *h;

    if (NULL == (h = malloc(sizeof(*h))))
	return NULL;

    memset(h,0,sizeof(*h));
    h->video      = *video;
    h->audio      = *audio;
    if (h->video.fmtid != VIDEO_NONE) {
	h->lib_video  = pvideo->libencode;
	h->yuvsign    = pvideo->yuvsign;
    }
    if (h->audio.fmtid != AUDIO_NONE)
	h->lib_audio  = paudio->libencode;

    if (NULL == (h->fh = quicktime_open(filename,0,1))) {
	fprintf(stderr,"quicktime_open failed (%s)\n",filename);
	goto fail;
    }
    if (h->lib_video)
	if (NULL == (h->rows = malloc(h->video.height * sizeof(char*))))
	    goto fail;
    if (h->yuvsign)
	if (NULL == (h->data = malloc(h->video.height * h->video.width * 2)))
	    goto fail;

    if (h->audio.fmtid != AUDIO_NONE) {
	quicktime_set_audio(h->fh,
			    ng_afmt_to_channels[h->audio.fmtid],
			    h->audio.rate,
			    ng_afmt_to_bits[h->audio.fmtid],
			    (char*)paudio->fcc);
	h->audio_sample = ng_afmt_to_channels[h->audio.fmtid] *
	    ng_afmt_to_bits[h->audio.fmtid] / 8;
	if (h->lib_audio) {
	    if (!quicktime_supported_audio(h->fh, 0)) {
		fprintf(stderr,"libquicktime: audio codec not supported\n");
		goto fail;
	    }
	}
    }
    if (h->video.fmtid != VIDEO_NONE) {
	quicktime_set_video(h->fh,1,h->video.width,h->video.height,
			    (float)fps/1000,(char*)pvideo->fcc);
	if (h->lib_video) {
	    quicktime_set_cmodel(h->fh,pvideo->cmodel);
	    if (!quicktime_supported_video(h->fh, 0)) {
		fprintf(stderr,"libquicktime: video codec not supported\n");
		goto fail;
	    }
	}
    }
    quicktime_set_info(h->fh, "Dumme Bemerkungen gibt's hier umsonst.");
    return h;

 fail:
    if (h->rows)
	free(h->rows);
    if (h->data)
	free(h->data);
    free(h);
    return NULL;
}

static int
qt_video(void *handle, struct ng_video_buf *buf)
{
    struct qt_handle *h = handle;
    unsigned int *src,*dest;
    int rc,i,n;

    if (h->lib_video) {
	unsigned int row,len;
	char *line;

	/* QuickTime library expects an array of pointers to image rows (RGB) */
	len = h->video.width * 3;
	for (row = 0, line = buf->data; row < h->video.height; row++, line += len)
	    h->rows[row] = line;
	rc = quicktime_encode_video(h->fh, h->rows, 0);

    } else if (h->yuvsign) {
	dest = (unsigned int *)h->data;
	src  = (unsigned int *)buf->data;
	n    = buf->size / 4;
	/* U V values are signed but Y R G B values are unsigned. */
	for (i = 0; i < n; i++) {
#if BYTE_ORDER == BIG_ENDIAN
	    *(dest++) = *(src++) ^ 0x00800080;
#else
	    *(dest++) = *(src++) ^ 0x80008000;
#endif
	}
	rc = quicktime_write_frame(h->fh, h->data, buf->size, 0);

    } else {
	rc = quicktime_write_frame(h->fh, buf->data, buf->size, 0);
    }
    return rc;
}

static int
qt_audio(void *handle, struct ng_audio_buf *buf)
{
    struct qt_handle *h = handle;
    int16_t *ch[2];
    
    if (h->lib_audio) {
	/* FIXME: works for one channel (mono) only */
	ch[0] = (int16_t*)buf->data;
	return quicktime_encode_audio(h->fh, ch, NULL,
				      buf->size / h->audio_sample);
    } else {
	return quicktime_write_audio(h->fh, buf->data,
				     buf->size / h->audio_sample, 0);
    }
}

static int
qt_close(void *handle)
{
    struct qt_handle *h = handle;

    quicktime_close(h->fh);
    if (h->rows)
	free(h->rows);
    if (h->data)
	free(h->data);
    free(h);
    return 0;
}

/* ----------------------------------------------------------------------- */

static int cmodels[] = {
    [BC_BGR888]  = VIDEO_BGR24,
    [BC_RGB888]  = VIDEO_RGB24,
    [BC_YUV422]  = VIDEO_YUYV,
    [BC_YUV422P] = VIDEO_YUV422P,
    [BC_YUV420P] = VIDEO_YUV420P,
};

static struct qt_video_priv qt_raw = {
    .fcc       = QUICKTIME_RAW,
    .libencode = 0,
};
static struct qt_video_priv qt_yuv2 = {
    .fcc       = QUICKTIME_YUV2,
    .yuvsign   = 1,
    .libencode = 0,
};
static struct qt_video_priv qt_yv12 = {
    .fcc       = QUICKTIME_YUV420,
    .libencode = 0,
};
static struct qt_video_priv qt_jpeg = {
    .fcc       = QUICKTIME_JPEG,
    .libencode = 0,
};

static const struct ng_format_list qt_vformats[] = {
    {
	.name  = "raw",
	.ext   = "mov",
	.fmtid = VIDEO_RGB24,
	.priv  = &qt_raw,
    },{
	.name  = "yuv2",
	.ext   = "mov",
	.fmtid = VIDEO_YUYV,
	.priv  = &qt_yuv2,
    },{
	.name  = "yv12",
	.ext   = "mov",
	.fmtid = VIDEO_YUV420P,
	.priv  = &qt_yv12,
    },{
	.name  = "jpeg",
	.ext   = "mov",
	.fmtid = VIDEO_JPEG,
	.priv  = &qt_jpeg,
    },{
	/* EOF */
    }
};

static struct qt_audio_priv qt_mono8 = {
    .fcc        = QUICKTIME_RAW,
    .libencode  = 0,
};
static struct qt_audio_priv qt_mono16 = {
    .fcc	= QUICKTIME_TWOS,
    .libencode	= 0,
};
static struct qt_audio_priv qt_stereo = {
    .fcc	= QUICKTIME_TWOS,
    .libencode	= 0,
};
static const struct ng_format_list qt_aformats[] = {
    {
	.name  = "mono8",
	.ext   = "mov",
	.fmtid = AUDIO_U8_MONO,
	.priv  = &qt_mono8,
    },{
        .name  = "mono16",
	.ext   = "mov",
	.fmtid = AUDIO_S16_BE_MONO,
	.priv  = &qt_mono16,
    },{
        .name  = "stereo",
	.ext   = "mov",
	.fmtid = AUDIO_S16_BE_STEREO,
	.priv  = &qt_stereo,
    },{
	/* EOF */
    }
};

struct ng_writer qt_writer = {
    .name      = "qt",
    .desc      = "Apple QuickTime format",
    .combined  = 1,
    .video     = qt_vformats,
    .audio     = qt_aformats,
    .wr_open   = qt_open,
    .wr_video  = qt_video,
    .wr_audio  = qt_audio,
    .wr_close  = qt_close,
};

/* ----------------------------------------------------------------------- */

#if 0
/* debug only */
static void dump_codecs(void)
{
    lqt_codec_info_t **info;
    int i,j;

    info = lqt_query_registry(1, 1, 1, 1);
    for (i = 0; info[i] != NULL; i++) {
	fprintf(stderr,"lqt: %s codec: %s [%s]\n",
		info[i]->type == LQT_CODEC_AUDIO ? "audio" : "video",
		info[i]->name,info[i]->long_name);
	fprintf(stderr,"   encode: %s\n",
		info[i]->direction == LQT_DIRECTION_DECODE ? "no" : "yes");
	fprintf(stderr,"   decode: %s\n",
		info[i]->direction == LQT_DIRECTION_ENCODE ? "no" : "yes");
	for (j = 0; j < info[i]->num_fourccs; j++)
	    fprintf(stderr,"   fcc   : %s\n",info[i]->fourccs[j]);
	for (j = 0; j < info[i]->num_encoding_colormodels; j++)
	    fprintf(stderr,"   cmodel: %s\n",
		    lqt_get_colormodel_string(info[i]->encoding_colormodels[j]));
	fprintf(stderr,"\n");
    }
    lqt_destroy_codec_info(info);
}
#endif

static struct ng_format_list*
qt_list_add(struct ng_format_list* list,
	 char *name, char *desc, char *ext, int fmtid, void *priv)
{
    int n;

    for (n = 0; list[n].name != NULL; n++)
	/* nothing */;
    list = realloc(list,sizeof(struct ng_format_list)*(n+2));
    memset(list+n,0,sizeof(struct ng_format_list)*2);
    list[n].name  = strdup(name);
    list[n].desc  = strdup(desc);
    list[n].ext   = strdup(ext);
    list[n].fmtid = fmtid;
    list[n].priv  = priv;
    return list;
}

static struct ng_format_list* video_list(void)
{
    static int debug = 0;
    lqt_codec_info_t **info;
    struct ng_format_list *video;
    int i,j,k,skip,fmtid;
    unsigned int cmodel;
    struct qt_video_priv *vp;

    /* handle video encoders */
    video = malloc(sizeof(qt_vformats));
    memcpy(video,qt_vformats,sizeof(qt_vformats));
    info = lqt_query_registry(0, 1, 1, 0);
    for (i = 0; info[i] != NULL; i++) {
	if (debug) {
	    fprintf(stderr,"\nlqt: %s codec: %s [%s]\n",
		    info[i]->type == LQT_CODEC_AUDIO ? "audio" : "video",
		    info[i]->name,info[i]->long_name);
	    for (j = 0; j < info[i]->num_fourccs; j++)
		fprintf(stderr,"   fcc   : %s\n",info[i]->fourccs[j]);
	    for (j = 0; j < info[i]->num_encoding_colormodels; j++)
		fprintf(stderr,"   cmodel: %d [%s]\n",
			info[i]->encoding_colormodels[j],
			lqt_get_colormodel_string(info[i]->encoding_colormodels[j]));
	}

	/* sanity checks */
	if (0 == info[i]->num_fourccs) {
	    if (debug)
		fprintf(stderr,"   skipping, no fourcc\n");
	    continue;
	}
	
	/* avoid dup entries */
	skip = 0;
	for (j = 0; video[j].name != NULL; j++) {
	    const struct qt_video_priv *p = video[j].priv;
	    for (k = 0; k < info[i]->num_fourccs; k++)
		if (0 == strcmp(p->fcc,info[i]->fourccs[k]))
		    skip = 1;
	}
	if (skip) {
	    if (debug)
		fprintf(stderr,"   skipping, fourcc already in list\n");
	    continue;
	}

	/* pick colormodel */
	fmtid  = VIDEO_NONE;
	cmodel = 0;
	for (j = 0; j < info[i]->num_encoding_colormodels; j++) {
	    cmodel = info[i]->encoding_colormodels[j];
	    if (cmodel>= sizeof(cmodels)/sizeof(int))
		continue;
	    if (!cmodels[cmodel])
		continue;
	    fmtid = cmodels[cmodel];
	    break;
	}
	if (VIDEO_NONE == fmtid) {
	    if (debug)
		fprintf(stderr,"   skipping, can't handle color model\n");
	    continue;
	}

	/* all fine */
	if (debug)
	    fprintf(stderr,"   ok, using fmtid %d [%s]\n",
		    fmtid,ng_vfmt_to_desc[fmtid]);
	vp = malloc(sizeof(*vp));
	memset(vp,0,sizeof(*vp));
	strcpy(vp->fcc,info[i]->fourccs[0]);
	vp->libencode = 1;
	vp->cmodel    = cmodel;
	video = qt_list_add(video,vp->fcc,info[i]->long_name,"mov",fmtid,vp);
    }
    lqt_destroy_codec_info(info);
    return video;
}

static struct ng_format_list* audio_list(void)
{
    static int debug = 0;
    lqt_codec_info_t **info;
    struct ng_format_list *audio;
    int i,j;
    struct qt_audio_priv *ap;

    /* handle video encoders */
    audio = malloc(sizeof(qt_aformats));
    memcpy(audio,qt_aformats,sizeof(qt_aformats));
    info = lqt_query_registry(1, 0, 1, 0);
    for (i = 0; info[i] != NULL; i++) {
	if (debug) {
	    fprintf(stderr,"\nlqt: %s codec: %s [%s]\n",
		    info[i]->type == LQT_CODEC_AUDIO ? "audio" : "video",
		    info[i]->name,info[i]->long_name);
	    for (j = 0; j < info[i]->num_fourccs; j++)
		fprintf(stderr,"   fcc   : %s\n",info[i]->fourccs[j]);
	}

	/* sanity checks */
	if (0 == info[i]->num_fourccs) {
	    if (debug)
		fprintf(stderr,"   skipping, no fourcc\n");
	    continue;
	}

	/* skip uncompressed formats */
	if (0 == strcmp(info[i]->fourccs[0],QUICKTIME_RAW)  ||
	    0 == strcmp(info[i]->fourccs[0],QUICKTIME_ULAW) ||
	    0 == strcmp(info[i]->fourccs[0],QUICKTIME_IMA4) || /* ??? */
	    0 == strcmp(info[i]->fourccs[0],QUICKTIME_TWOS)) {
	    if (debug)
		fprintf(stderr,"   skipping, uncompressed\n");
	    continue;
	}

	/* all fine */
	if (debug)
	    fprintf(stderr,"   ok\n");
	ap = malloc(sizeof(*ap));
	memset(ap,0,sizeof(*ap));
	strcpy(ap->fcc,info[i]->fourccs[0]);
	ap->libencode = 1;
	audio = qt_list_add(audio,ap->fcc,info[i]->long_name,"mov",
			    AUDIO_S16_NATIVE_MONO,ap);
    }
    lqt_destroy_codec_info(info);
    return audio;
}

static void __init plugin_init(void)
{
    qt_writer.video = video_list();
    qt_writer.audio = audio_list();
    ng_writer_register(NG_PLUGIN_MAGIC,__FILE__,&qt_writer);
}
