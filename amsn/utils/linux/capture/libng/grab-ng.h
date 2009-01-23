/*
 * next generation[tm] xawtv capture interfaces
 *
 * (c) 2001-03 Gerd Knorr <kraxel@bytesex.org>
 *
 */

#include <pthread.h>
#include <sys/types.h>

#include "devices.h"
#include "list.h"

extern int  ng_debug;
extern int  ng_log_bad_stream;
extern int  ng_log_resync;
extern int  ng_chromakey;
extern int  ng_ratio_x;
extern int  ng_ratio_y;
extern char ng_v4l_conf[256];

extern int  ng_jpeg_quality;
extern int  ng_mpeg_vpid;
extern int  ng_mpeg_apid;

#undef BUG_ON
#undef BUG

#define BUG_ON(condition,message,arg...)	if (condition) {\
	fprintf(stderr,"BUG: " message " [%s:%s:%d]\n",\
		## arg, __FILE__, __FUNCTION__, __LINE__);\
	abort();}
#define BUG(message,arg...)	if (1) {\
	fprintf(stderr,"BUG: " message " [%s:%s:%d]\n",\
		## arg, __FILE__, __FUNCTION__, __LINE__);\
	abort();}
#define OOPS_ON(condition,message,arg...)	if (condition) {\
	fprintf(stderr,"Oops: " message " [%s:%s:%d]\n",\
		## arg, __FILE__, __FUNCTION__, __LINE__);}
#define OOPS(message,arg...)	if (1) {\
	fprintf(stderr,"Oops: " message " [%s:%s:%d]\n",\
		## arg, __FILE__, __FUNCTION__, __LINE__);}

#if !defined(__cplusplus)  &&  __STDC_VERSION__ < 199901
# undef bool
# define bool int
#endif
#if __STDC_VERSION__ < 199901
# define restrict
#endif

#define UNSET          (-1U)
#define DIMOF(array)   (sizeof(array)/sizeof(array[0]))
#define SDIMOF(array)  ((signed int)(sizeof(array)/sizeof(array[0])))
#define GETELEM(array,index,default) \
	(index < sizeof(array)/sizeof(array[0]) ? array[index] : default)

#ifdef __sun
#include <sys/mkdev.h>		/* For major() */
#define __u32 uint32_t
#define __u16 uint16_t
#define __u8  uint8_t
#endif

/* --------------------------------------------------------------------- */
/* defines                                                               */

#define VIDEO_NONE           0
#define VIDEO_RGB08          1  /* bt848 dithered */
#define VIDEO_GRAY           2
#define VIDEO_RGB15_LE       3  /* 15 bpp little endian */
#define VIDEO_RGB16_LE       4  /* 16 bpp little endian */
#define VIDEO_RGB15_BE       5  /* 15 bpp big endian */
#define VIDEO_RGB16_BE       6  /* 16 bpp big endian */
#define VIDEO_BGR24          7  /* bgrbgrbgrbgr (LE) */
#define VIDEO_BGR32          8  /* bgr-bgr-bgr- (LE) */
#define VIDEO_RGB24          9  /* rgbrgbrgbrgb (BE) */
#define VIDEO_RGB32         10  /* -rgb-rgb-rgb (BE) */
#define VIDEO_LUT2          11  /* lookup-table 2 byte depth */
#define VIDEO_LUT4          12  /* lookup-table 4 byte depth */
#define VIDEO_YUYV	    13  /* 4:2:2 */
#define VIDEO_YUV422P       14  /* YUV 4:2:2 (planar) */
#define VIDEO_YUV420P	    15  /* YUV 4:2:0 (planar) */
#define VIDEO_MJPEG	    16  /* MJPEG (AVI) */
#define VIDEO_JPEG	    17  /* JPEG (JFIF) */
#define VIDEO_UYVY	    18  /* 4:2:2 */
#define VIDEO_MPEG	    19  /* MPEG1/2 */
#define VIDEO_BAYER			20
#define VIDEO_S910			21
#define VIDEO_FMT_COUNT	    22

#define AUDIO_NONE           0
#define AUDIO_U8_MONO        1
#define AUDIO_U8_STEREO      2
#define AUDIO_S16_LE_MONO    3
#define AUDIO_S16_LE_STEREO  4
#define AUDIO_S16_BE_MONO    5
#define AUDIO_S16_BE_STEREO  6
#define AUDIO_MP3            7
#define AUDIO_FMT_COUNT      8

#if BYTE_ORDER == BIG_ENDIAN
# define AUDIO_S16_NATIVE_MONO   AUDIO_S16_BE_MONO
# define AUDIO_S16_NATIVE_STEREO AUDIO_S16_BE_STEREO
# define VIDEO_RGB15_NATIVE      VIDEO_RGB15_BE
# define VIDEO_RGB16_NATIVE      VIDEO_RGB16_BE
#endif
#if BYTE_ORDER == LITTLE_ENDIAN
# define AUDIO_S16_NATIVE_MONO   AUDIO_S16_LE_MONO
# define AUDIO_S16_NATIVE_STEREO AUDIO_S16_LE_STEREO
# define VIDEO_RGB15_NATIVE      VIDEO_RGB15_LE
# define VIDEO_RGB16_NATIVE      VIDEO_RGB16_LE
#endif

#define ATTR_TYPE_INTEGER    1   /*  range 0 - 65535  */
#define ATTR_TYPE_CHOICE     2   /*  multiple choice  */
#define ATTR_TYPE_BOOL       3   /*  yes/no           */

#define ATTR_ID_NORM         1
#define ATTR_ID_INPUT        2
#define ATTR_ID_VOLUME       3
#define ATTR_ID_MUTE         4
#define ATTR_ID_AUDIO_MODE   5
#define ATTR_ID_COLOR        6
#define ATTR_ID_BRIGHT       7
#define ATTR_ID_HUE          8
#define ATTR_ID_CONTRAST     9
#define ATTR_ID_COUNT       10

#define CAN_OVERLAY          1
#define CAN_CAPTURE          2
#define CAN_TUNE             4
#define NEEDS_CHROMAKEY      8
#define CAN_MPEG_PS         16
#define CAN_MPEG_TS         32

#define MPEG_FLAGS_PS        1
#define MPEG_FLAGS_TS        2

/* --------------------------------------------------------------------- */

extern const unsigned int   ng_vfmt_to_depth[VIDEO_FMT_COUNT];
extern const char*          ng_vfmt_to_desc[VIDEO_FMT_COUNT];

extern const unsigned int   ng_afmt_to_channels[AUDIO_FMT_COUNT];
extern const unsigned int   ng_afmt_to_bits[AUDIO_FMT_COUNT];
extern const char*          ng_afmt_to_desc[AUDIO_FMT_COUNT];

extern const char*          ng_attr_to_desc[ATTR_ID_COUNT];

/* --------------------------------------------------------------------- */

struct STRTAB {
    long nr;
    char *str;
};

struct OVERLAY_CLIP {
    int x1,x2,y1,y2;
};

/* fwd decl */
struct ng_devinfo;
struct ng_devstate;

/* --------------------------------------------------------------------- */
/* video data structures                                                 */

struct ng_video_fmt {
    unsigned int   fmtid;         /* VIDEO_* */
    unsigned int   width;
    unsigned int   height;
    unsigned int   bytesperline;  /* zero for compressed formats */
};

enum ng_video_frame {
    NG_FRAME_UNKNOWN  = 0,
    NG_FRAME_I_FRAME  = 1,
    NG_FRAME_P_FRAME  = 2,
    NG_FRAME_B_FRAME  = 3,
};

enum ng_video_ratio {
    // same numbers mpeg2 uses
    NG_RATIO_UNSPEC = 0,
    NG_RATIO_SQUARE = 1,
    NG_RATIO_3_4    = 2,
    NG_RATIO_9_16   = 3,
    NG_RATIO_2dot21 = 4,
};

struct ng_video_buf {
    struct ng_video_fmt  fmt;
    size_t               size;
    unsigned char        *data;

    /* meta info for frame */
    struct {
	int64_t             ts;       /* time stamp */
	int                 file_seq;
	int                 play_seq;
	int                 twice;
	enum ng_video_frame frame;
	enum ng_video_ratio ratio;
	int                 broken;
	int                 slowdown;
    } info;

    /*
     * the lock is for the reference counter.
     * if the reference counter goes down to zero release()
     * should be called.  priv is for the owner of the
     * buffer (can be used by the release callback)
     */
    pthread_mutex_t      lock;
    pthread_cond_t       cond;
    int                  refcount;
    void                 (*release)(struct ng_video_buf *buf);
    void                 *priv;
};

struct ng_video_fifo {
    struct list_head     next;
    struct ng_video_buf  *buf;
};

void ng_init_video_buf(struct ng_video_buf *buf);
void ng_release_video_buf(struct ng_video_buf *buf);
void ng_print_video_buf(char *tag, struct ng_video_buf *buf);
void ng_copy_video_buf(struct ng_video_buf *dst, struct ng_video_buf *src);
struct ng_video_buf* ng_malloc_video_buf(void *handle, struct ng_video_fmt *fmt);
void ng_wakeup_video_buf(struct ng_video_buf *buf);
void ng_waiton_video_buf(struct ng_video_buf *buf);


/* --------------------------------------------------------------------- */
/* audio data structures                                                 */

struct ng_audio_fmt {
    unsigned int   fmtid;         /* AUDIO_* */
    unsigned int   rate;
};

struct ng_audio_buf {
    struct ng_audio_fmt  fmt;
    int                  size;
    int                  written; /* for partial writes */
    char                 *data;

    struct {
	int64_t          ts;
	int              broken;
	int              slowdown;
    } info;
};

struct ng_audio_buf* ng_malloc_audio_buf(struct ng_audio_fmt *fmt,
					 int size);
void ng_free_audio_buf(struct ng_audio_buf *buf);

/* --------------------------------------------------------------------- */
/* someone who receives video and/or audio data (writeavi, ...)          */

struct ng_format_list {
    char           *name;
    char           *desc;  /* if standard fmtid description doesn't work
			      because it's converted somehow */
    char           *ext;
    unsigned int   fmtid;
    void           *priv;
};

struct ng_writer {
    const char *name;
    const char *desc;
    const struct ng_format_list *video;
    const struct ng_format_list *audio;
    const int combined; /* both audio + video in one file */

    void* (*wr_open)(char *moviename, char *audioname,
		     struct ng_video_fmt *video, const void *priv_video, int fps,
		     struct ng_audio_fmt *audio, const void *priv_audio);
    int (*wr_video)(void *handle, struct ng_video_buf *buf);
    int (*wr_audio)(void *handle, struct ng_audio_buf *buf);
    int (*wr_close)(void *handle);

    struct list_head list;
};

struct ng_reader {
    const char *name;
    const char *desc;

    char  *magic[8];
    int   moff[8];
    int   mlen[8];

    void* (*rd_open)(char *moviename);
    struct ng_video_fmt* (*rd_vfmt)(void *handle, int *vfmt, int vn);
    struct ng_audio_fmt* (*rd_afmt)(void *handle);
    struct ng_video_buf* (*rd_vdata)(void *handle, unsigned int *drop);
    struct ng_audio_buf* (*rd_adata)(void *handle);
    int64_t (*frame_time)(void *handle);
    int (*rd_close)(void *handle);

    struct list_head list;
};


/* --------------------------------------------------------------------- */
/* attributes                                                            */

struct ng_attribute {
    /* attribute name + identity */
    int                  id;
    int                  priority;
    const char           *name;
    const char           *group;

    /* attribute properties */
    int                  type;
    int                  defval;
    struct STRTAB        *choices;    /* ATTR_TYPE_CHOICE  */
    int                  min,max;     /* ATTR_TYPE_INTEGER */
    int                  points;      /* ATTR_TYPE_INTEGER -- fixed point */
    int         (*read)(struct ng_attribute*);
    void        (*write)(struct ng_attribute*, int val);

    /* attribute owner's data */
    void                 *handle;
    const void           *priv;
    
    /* attribute user's data */
    struct list_head     device_list;
    struct ng_devstate   *dev;
    struct list_head     global_list;
    void                 *app;
};

struct ng_attribute* ng_attr_byid(struct ng_devstate *dev, int id);
struct ng_attribute* ng_attr_byname(struct ng_devstate *dev, char *name);
const char* ng_attr_getstr(struct ng_attribute *attr, int value);
int ng_attr_getint(struct ng_attribute *attr, char *value);
void ng_attr_listchoices(struct ng_attribute *attr);
int ng_attr_int2percent(struct ng_attribute *attr, int value);
int ng_attr_percent2int(struct ng_attribute *attr, int percent);
int ng_attr_parse_int(struct ng_attribute *attr, char *str);

/* --------------------------------------------------------------------- */

void ng_ratio_fixup(int *width, int *height, int *xoff, int *yoff);
void ng_ratio_fixup2(int *width, int *height, int *xoff, int *yoff,
		     int ratio_x, int ratio_y, int up);

/* --------------------------------------------------------------------- */
/* capture/overlay + sound interface drivers                             */

struct ng_vid_driver {
    const char *name;
    int priority;

    /* open/close */
    struct ng_devinfo* (*probe)(int debug);
    void*  (*init)(char *device);
    int    (*open)(void *handle);
    int    (*close)(void *handle);
    int    (*fini)(void *handle);
    char*  (*devname)(void *handle);
    char*  (*busname)(void *handle);

    /* attributes */
    int   (*capabilities)(void *handle);
    struct ng_attribute* (*list_attrs)(void *handle);

#if 0
    /* overlay */
    int   (*setupfb)(void *handle, struct ng_video_fmt *fmt, void *base);
    int   (*overlay)(void *handle, struct ng_video_fmt *fmt, int x, int y,
		     struct OVERLAY_CLIP *oc, int count, int aspect);
#else
    int   (*overlay)(void *handle,  int enable, int aspect,
		     long window, int dw, int dh);
#endif
    
    /* capture */
    int   (*setformat)(void *handle, struct ng_video_fmt *fmt);
    int   (*startvideo)(void *handle, int fps, unsigned int buffers);
    void  (*stopvideo)(void *handle);
    struct ng_video_buf* (*nextframe)(void *handle); /* video frame  */
    struct ng_video_buf* (*getimage)(void *handle);  /* single image */

    /* read MPEG stream */
    char* (*setup_mpeg)(void *handle, int flags);

    /* tuner */
    unsigned long (*getfreq)(void *handle);
    void  (*setfreq)(void *handle, unsigned long freq);
    int   (*is_tuned)(void *handle);

    struct list_head list;
};

struct ng_dsp_driver {
    const char            *name;
    int priority;

    /* open/close */
    struct ng_devinfo*    (*probe)(int record, int debug);
    void*                 (*init)(char *device, int record);
    int                   (*open)(void *handle);
    int                   (*close)(void *handle);
    int                   (*fini)(void *handle);
    char*                 (*devname)(void *handle);

    /* record/playback */
    int                   (*setformat)(void *handle, struct ng_audio_fmt *fmt);
    int                   (*fd)(void *handle);
    int                   (*startrec)(void *handle);
    int                   (*startplay)(void *handle);
    struct ng_audio_buf*  (*read)(void *handle, int64_t stopby);
    struct ng_audio_buf*  (*write)(void *handle, struct ng_audio_buf *buf);
    int64_t               (*latency)(void *handle);

    struct list_head      list;
};

struct ng_mix_driver {
    const char            *name;
    int priority;

    struct ng_devinfo*    (*probe)(int debug);
    struct ng_devinfo*    (*channels)(char *device);
    void*                 (*init)(char *device, char *control);
    int                   (*open)(void *handle);
    int                   (*close)(void *handle);
    int                   (*fini)(void *handle);
    char*                 (*devname)(void *handle);

    struct ng_attribute*  (*list_attrs)(void *handle);
    struct list_head      list;
};

struct ng_devinfo {
    char  device[32];
    char  name[32];
    char  bus[32];
    int   flags;
};

struct ng_devstate {
    enum {
	NG_DEV_NONE  = 0,
	NG_DEV_VIDEO = 1,
	NG_DEV_DSP   = 2,
	NG_DEV_MIX   = 3,
    } type;
    union {
	struct ng_vid_driver  *v;
	struct ng_dsp_driver  *a;
	struct ng_mix_driver  *m;
    };
    char                      *device;
    void                      *handle;
    struct list_head          attrs;
    int                       flags;
    int                       refcount;
};

/* --------------------------------------------------------------------- */
/* frame processing (color space conversion / compression / filtering)   */

typedef struct ng_video_buf* (*ng_get_video_buf)
	(void *handle, struct ng_video_fmt *fmt);
typedef struct ng_audio_buf* (*ng_get_audio_buf)
	(void *handle);

enum ng_process_mode {
    NG_MODE_UNDEF   = 0,
    NG_MODE_TRIVIAL = 1,
    NG_MODE_COMPLEX = 2,
};

struct ng_video_process {
    enum ng_process_mode mode;

    /* trivial filters -- one frame in, one frame out */
    void   (*frame)(void *handle,
		    struct ng_video_buf *out,
		    struct ng_video_buf *in);
    
    /* complex filters -- anything trivial can't handle */
    void (*setup)(void *handle, ng_get_video_buf get, void *ghandle);
    void (*put_frame)(void *handle, struct ng_video_buf* buf);
    struct ng_video_buf* (*get_frame)(void *handle);

    /* cleanup */
    void (*fini)(void *handle);
};

struct ng_video_conv {
    void*                     (*init)(struct ng_video_fmt *out,
				      void *priv);
    struct ng_video_process   p;

    unsigned int              fmtid_in;
    unsigned int              fmtid_out;
    void                      *priv;

    struct list_head          list;
};

struct ng_video_filter {
    void*                     (*init)(struct ng_video_fmt *fmt);
    struct ng_video_process   p;

    char                      *name;
    int                       fmts;
    struct ng_attribute*      attrs;

    struct list_head          list;
};

struct ng_process_handle;

struct ng_process_handle* ng_conv_init(struct ng_video_conv *conv,
				       struct ng_video_fmt *i,
				       struct ng_video_fmt *o);
struct ng_process_handle* ng_filter_init(struct ng_video_filter *filter,
					 struct ng_video_fmt *fmt);
void ng_process_setup(struct ng_process_handle*, ng_get_video_buf get, void *ghandle);
void ng_process_put_frame(struct ng_process_handle*, struct ng_video_buf*);
struct ng_video_buf* ng_process_get_frame(struct ng_process_handle*);
void ng_process_fini(struct ng_process_handle*);

#if 0

struct ng_convert_handle* ng_convert_alloc(struct ng_video_conv *conv,
					   struct ng_video_fmt *i,
					   struct ng_video_fmt *o);
void ng_convert_init(struct ng_convert_handle *h);
struct ng_video_buf* ng_convert_frame(struct ng_convert_handle *h,
				      struct ng_video_buf *dest,
				      struct ng_video_buf *buf);
void ng_convert_fini(struct ng_convert_handle *h);
struct ng_video_buf* ng_convert_single(struct ng_convert_handle *h,
				       struct ng_video_buf *in);

#endif

/* --------------------------------------------------------------------- */
/* audio converters                                                      */

struct ng_audio_conv {
    unsigned int          fmtid_in;
    unsigned int          fmtid_out;
    void*                 (*init)(void *priv);
    struct ng_audio_buf*  (*data)(void *handle,
				  struct ng_audio_buf *in);
    void                  (*fini)(void *handle);
    void                  *priv;

    struct list_head      list;
};

/* --------------------------------------------------------------------- */

/* must be changed if we break compatibility */
#define NG_PLUGIN_MAGIC 0x20041201

#define __init __attribute__ ((constructor))
#define __fini __attribute__ ((destructor))
#ifndef __used
#define __used __attribute__ ((used))
#endif

extern struct list_head ng_conv;
extern struct list_head ng_aconv;
extern struct list_head ng_filters;
extern struct list_head ng_writers;
extern struct list_head ng_readers;
extern struct list_head ng_vid_drivers;
extern struct list_head ng_dsp_drivers;
extern struct list_head ng_mix_drivers;

int ng_conv_register(int magic, char *plugname,
		     struct ng_video_conv *list, int count);
int ng_aconv_register(int magic, char *plugname,
		      struct ng_audio_conv *list, int count);
int ng_filter_register(int magic, char *plugname,
		       struct ng_video_filter *filter);
int ng_writer_register(int magic, char *plugname,
		       struct ng_writer *writer);
int ng_reader_register(int magic, char *plugname,
		       struct ng_reader *reader);
int ng_vid_driver_register(int magic, char *plugname,
			   struct ng_vid_driver *driver);
int ng_dsp_driver_register(int magic, char *plugname,
			   struct ng_dsp_driver *driver);
int ng_mix_driver_register(int magic, char *plugname,
			   struct ng_mix_driver *driver);

struct ng_video_conv* ng_conv_find_to(unsigned int out, int *i);
struct ng_video_conv* ng_conv_find_from(unsigned int out, int *i);
struct ng_video_conv* ng_conv_find_match(unsigned int in, unsigned int out);

struct ng_devinfo* ng_vid_probe(char *driver);

int ng_vid_init(struct ng_devstate *dev, char *device);
int ng_dsp_init(struct ng_devstate *dev, char *device, int record);
int ng_mix_init(struct ng_devstate *dev, char *device, char *control);

int ng_dev_fini(struct ng_devstate *dev);
int ng_dev_open(struct ng_devstate *dev);
int ng_dev_close(struct ng_devstate *dev);
int ng_dev_users(struct ng_devstate *dev);

int ng_chardev_open(char *device, int flags, int major, int complain, int is_v4l2);

struct ng_reader* ng_find_reader_magic(char *filename);
struct ng_reader* ng_find_reader_name(char *name);
struct ng_writer* ng_find_writer_name(char *name);
int64_t ng_tofday_to_timestamp(struct timeval *tv);
int64_t ng_get_timestamp(void);
void ng_check_clipping(int width, int height, int xadjust, int yadjust,
		       struct OVERLAY_CLIP *oc, int *count);
struct ng_video_buf* ng_filter_single(struct ng_video_filter *filter,
				      struct ng_video_buf *in);

/* --------------------------------------------------------------------- */

void ng_init(void);
void ng_print_stacktrace(void);
void ng_lut_init(unsigned long red_mask, unsigned long green_mask,
		 unsigned long blue_mask, unsigned int fmtid, int swap);

void ng_rgb24_to_lut2(unsigned char *dest, unsigned char *src, int p);
void ng_rgb24_to_lut4(unsigned char *dest, unsigned char *src, int p);

/* --------------------------------------------------------------------- */
/* internal stuff starts here                                            */

#ifdef NG_PRIVATE

/* for yuv2rgb using lookup tables (color_lut.c, color_yuv2rgb.c) */
extern int32_t  ng_lut_red[256];
extern int32_t  ng_lut_green[256];
extern int32_t  ng_lut_blue[256];
void ng_yuv422_to_lut2(unsigned char *dest, unsigned char *s, int p);
void ng_yuv422_to_lut4(unsigned char *dest, unsigned char *s, int p);
void ng_yuv420p_to_lut2(void *h, struct ng_video_buf *out,
			struct ng_video_buf *in);
void ng_yuv420p_to_lut4(void *h, struct ng_video_buf *out,
			struct ng_video_buf *in);
void ng_yuv422p_to_lut2(void *h, struct ng_video_buf *out,
			struct ng_video_buf *in);
void ng_yuv422p_to_lut4(void *h, struct ng_video_buf *out,
			struct ng_video_buf *in);

void __init yuv2rgb_init(void);
void __init packed_init(void);

/* color_common.c stuff */
void* ng_packed_init(struct ng_video_fmt *out, void *priv);
void  ng_packed_frame(void *handle, struct ng_video_buf *out,
		      struct ng_video_buf *in);
void* ng_conv_nop_init(struct ng_video_fmt *out, void *priv);
void  ng_conv_nop_fini(void *handle);

#define NG_GENERIC_PACKED			\
	.init         = ng_packed_init,		\
	.p.mode       = NG_MODE_TRIVIAL,       	\
	.p.frame      = ng_packed_frame,       	\
	.p.fini       = ng_conv_nop_fini

#endif /* NG_PRIVATE */

/* --------------------------------------------------------------------- */
/*
 * Local variables:
 * compile-command: "(cd ..; make)"
 * End:
 */
