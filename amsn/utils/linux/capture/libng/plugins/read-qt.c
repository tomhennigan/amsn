#include "config.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <quicktime/quicktime.h>
#include <quicktime/colormodels.h>
#include <quicktime/lqt.h>

#include "grab-ng.h"

#define AUDIO_SIZE (64*1024)

/* ----------------------------------------------------------------------- */

static int fmtid_to_cmodel[VIDEO_FMT_COUNT] = {
    [ VIDEO_RGB24    ] = BC_RGB888,
    [ VIDEO_BGR24    ] = BC_BGR888,
    [ VIDEO_YUYV     ] = BC_YUV422,
    [ VIDEO_YUV420P  ] = BC_YUV420P,
};

/* ----------------------------------------------------------------------- */

struct qt_handle {
    /* libquicktime handle */
    quicktime_t *qt;

    /* format */
    struct ng_video_fmt vfmt;
    struct ng_audio_fmt afmt;

    /* misc video */
    unsigned char **rows;
    int rate;

    /* misc audio */
    int channels;
    int16_t *left,*right;
    long long bps;
};

static void* qt_open(char *moviename)
{
    struct qt_handle *h;
    char *str;
    int i;

    if (NULL == (h = malloc(sizeof(*h))))
	return NULL;
    memset(h,0,sizeof(*h));

    /* open file */
    h->qt = quicktime_open(moviename,1,0);
    if (NULL == h->qt) {
	fprintf(stderr,"ERROR: can't open file: %s\n",moviename);
	free(h);
	return NULL;
    }

    if (ng_debug) {
	/* print misc info */
	fprintf(stderr,"quicktime movie %s:\n",moviename);
	str = quicktime_get_copyright(h->qt);
	if (str)
	    fprintf(stderr,"  copyright: %s\n",str);
	str = quicktime_get_name(h->qt);
	if (str)
	    fprintf(stderr,"  name: %s\n",str);
	str = quicktime_get_info(h->qt);
	if (str)
	    fprintf(stderr,"  info: %s\n",str);
	
	/* print video info */
	if (quicktime_has_video(h->qt)) {
	    fprintf(stderr,"  video: %d track(s)\n",quicktime_video_tracks(h->qt));
	    for (i = 0; i < quicktime_video_tracks(h->qt); i++) {
		fprintf(stderr,
			"    track #%d\n"
			"      width : %d\n"
			"      height: %d\n"
			"      depth : %d bit\n"
			"      rate  : %.2f fps\n"
			"      codec : %s\n",
			i+1,
			quicktime_video_width(h->qt,i),
			quicktime_video_height(h->qt,i),
			quicktime_video_depth(h->qt,i),
			quicktime_frame_rate(h->qt,i),
			quicktime_video_compressor(h->qt,i));
	    }
	}
	
	/* print audio info */
	if (quicktime_has_audio(h->qt)) {
	    fprintf(stderr,"  audio: %d track(s)\n",quicktime_audio_tracks(h->qt));
	    for (i = 0; i < quicktime_audio_tracks(h->qt); i++) {
		fprintf(stderr,
			"    track #%d\n"
			"      rate  : %ld Hz\n"
			"      bits  : %d\n"
			"      chans : %d\n"
			"      codec : %s\n",
			i+1,
			quicktime_sample_rate(h->qt,i),
			quicktime_audio_bits(h->qt,i),
			quicktime_track_channels(h->qt,i),
			quicktime_audio_compressor(h->qt,i));
	    }
	}
    }

    /* video format */
    if (!quicktime_has_video(h->qt)) {
	if (ng_debug)
	    fprintf(stderr,"qt: no video stream\n");
    } else if (!quicktime_supported_video(h->qt,0)) {
	if (ng_debug)
	    fprintf(stderr,"qt: unsupported video codec\n");
    } else {
	h->vfmt.width  = quicktime_video_width(h->qt,0);
	h->vfmt.height = quicktime_video_height(h->qt,0);
	h->rate = quicktime_frame_rate(h->qt,0);
    }

    /* audio format */
    if (!quicktime_has_audio(h->qt)) {
	if (ng_debug)
	    fprintf(stderr,"qt: no audio stream\n");
    } else if (!quicktime_supported_audio(h->qt,0)) {
	if (ng_debug)
	    fprintf(stderr,"qt: unsupported audio codec\n");
    } else {
	h->channels   = quicktime_track_channels(h->qt,0);
	h->afmt.fmtid = (h->channels > 1) ?
	    AUDIO_S16_NATIVE_STEREO : AUDIO_S16_NATIVE_MONO;
	h->afmt.rate = quicktime_sample_rate(h->qt,0);
    }

    return h;
}

static struct ng_video_fmt* qt_vfmt(void *handle, int *vfmt, int vn)
{
    struct qt_handle *h = handle;
    int i;

    for (i = 0; i < vn; i++) {
	if (ng_debug)
	    fprintf(stderr,"qt: trying: %d [%s]\n",
		    vfmt[i],ng_vfmt_to_desc[vfmt[i]]);
	if (0 == fmtid_to_cmodel[vfmt[i]])
	    continue;
	if (!quicktime_reads_cmodel(h->qt,fmtid_to_cmodel[vfmt[i]],0))
	    continue;
	quicktime_set_cmodel(h->qt, fmtid_to_cmodel[vfmt[i]]);
	h->vfmt.fmtid = vfmt[i];
	break;
    }
    h->vfmt.bytesperline = (h->vfmt.width*ng_vfmt_to_depth[h->vfmt.fmtid]) >> 3;
    return &h->vfmt;
}

static struct ng_audio_fmt* qt_afmt(void *handle)
{
    struct qt_handle *h = handle;

    return h->afmt.fmtid ? &h->afmt : NULL;
}

static struct ng_video_buf* qt_vdata(void *handle, unsigned int *drop)
{
    struct qt_handle *h = handle;
    struct ng_video_buf *buf;
    unsigned int i;
    
    if (quicktime_video_position(h->qt,0) >= quicktime_video_length(h->qt,0))
	return NULL;

    buf = ng_malloc_video_buf(NULL, &h->vfmt);
    if (!h->rows)
	h->rows = malloc(h->vfmt.height * sizeof(char*));
    switch (fmtid_to_cmodel[h->vfmt.fmtid]) {
    case BC_RGB888:
    case BC_BGR888:
	for (i = 0; i < h->vfmt.height; i++)
	    h->rows[i] = buf->data + h->vfmt.width * 3 * i;
	break;
    case BC_YUV422:
	for (i = 0; i < h->vfmt.height; i++)
	    h->rows[i] = buf->data+ h->vfmt.width * 2 * i;
	break;
    case BC_YUV420P:
	h->rows[0] = buf->data;
	h->rows[1] = buf->data + h->vfmt.width*h->vfmt.height;
	h->rows[2] = buf->data + h->vfmt.width*h->vfmt.height*5/4;
	break;
    default:
	BUG_ON(1,"unknown cmodel");
    }

    /* drop frames */
    while (*drop) {
	quicktime_read_frame(h->qt,buf->data,0);
	(*drop)--;
    };
        
    buf->info.file_seq = quicktime_video_position(h->qt,0);
    buf->info.play_seq = buf->info.file_seq;
    buf->info.ts       = (long long) buf->info.play_seq * 1000000000 / h->rate;
    lqt_decode_video(h->qt, h->rows, 0);
    return buf;
}

static struct ng_audio_buf* qt_adata(void *handle)
{
    struct qt_handle *h = handle;
    struct ng_audio_buf *buf;
    int16_t *dest;
    long pos;
    int i;
    
    if (quicktime_audio_position(h->qt,0) >= quicktime_audio_length(h->qt,0))
	return NULL;

    buf = ng_malloc_audio_buf(&h->afmt,AUDIO_SIZE);
    dest = (int16_t*)buf->data;

    pos = quicktime_audio_position(h->qt,0);
    buf->info.ts = (long long) pos * 1000000000 / h->afmt.rate;
    if (h->channels > 1) {
	/* stereo: two channels => interlaved samples */
	if (!h->left)
	    h->left = malloc(AUDIO_SIZE/2);
	if (!h->right)
	    h->right = malloc(AUDIO_SIZE/2);
	quicktime_set_audio_position(h->qt,pos,0);
	quicktime_decode_audio(h->qt,h->left,NULL,AUDIO_SIZE/4,0);
	quicktime_set_audio_position(h->qt,pos,1);
	quicktime_decode_audio(h->qt,h->right,NULL,AUDIO_SIZE/4,1);
	for (i = 0; i < AUDIO_SIZE/4; i++) {
	    dest[2*i+0] = h->left[i];
	    dest[2*i+1] = h->right[i];
	}
    } else {
	/* mono */
	quicktime_decode_audio(h->qt,dest,NULL,AUDIO_SIZE/2,0);
    }
    return buf;
}

static int64_t qt_frame_time(void *handle)
{
    struct qt_handle *h = handle;

    return 1000000000 / h->rate;
}

static int qt_close(void *handle)
{
    struct qt_handle *h = handle;

    quicktime_close(h->qt);
    if (h->rows)
	free(h->rows);
    free(h);
    return 0;
}

/* ----------------------------------------------------------------------- */

struct ng_reader qt_reader = {
    .name       = "qt",
    .desc       = "Apple QuickTime format",

    .magic	= { "moov", "mdat" },
    .moff       = {  4,      4     },
    .mlen       = {  4,      4     },
    
    .rd_open    = qt_open,
    .rd_vfmt    = qt_vfmt,
    .rd_afmt    = qt_afmt,
    .rd_vdata   = qt_vdata,
    .rd_adata   = qt_adata,
    .frame_time = qt_frame_time,
    .rd_close   = qt_close,
};

static void __init plugin_init(void)
{
    ng_reader_register(NG_PLUGIN_MAGIC,__FILE__,&qt_reader);
}
