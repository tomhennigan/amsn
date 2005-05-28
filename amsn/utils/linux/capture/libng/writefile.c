/*
 * save pictures to disk (ppm,pgm,jpeg)
 *
 *  (c) 1998-2000 Gerd Knorr <kraxel@bytesex.org>
 *
 */

#define NG_PRIVATE
#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <time.h>
#include <fcntl.h>
#include <jpeglib.h>
#include <pthread.h>
#include <inttypes.h>
#include <sys/types.h>
#include <sys/param.h>
#include "byteswap.h"

#include "grab-ng.h"
#include "writefile.h"

/* ---------------------------------------------------------------------- */

/*
 * count up the latest block of digits in the passed string
 * (used for filename numbering
 */
int
patch_up(char *name)
{
    char *ptr;
    
    for (ptr = name+strlen(name); ptr >= name; ptr--)
	if (isdigit(*ptr))
	    break;
    if (ptr < name)
	return 0;
    while (*ptr == '9' && ptr >= name)
	*(ptr--) = '0';
    if (ptr < name)
	return 0;
    if (isdigit(*ptr)) {
	(*ptr)++;
	return 1;
    }
    return 0;
}

char*
snap_filename(char *base, char *channel, char *ext)
{
    static time_t last = 0;
    static int count = 0;
    static char *filename = NULL;
    
    time_t now;
    struct tm* tm;
    char timestamp[32];
    
    time(&now);
    tm = localtime(&now);
    
    if (last != now)
	count = 0;
    last = now;
    count++;
    
    if (filename != NULL)
	free(filename);	
    filename = malloc(strlen(base)+strlen(channel)+strlen(ext)+32);
    
    strftime(timestamp,31,"%Y%m%d-%H%M%S",tm);
    sprintf(filename,"%s-%s-%s-%d.%s",
	    base,channel,timestamp,count,ext);
    return filename;
}

/* ---------------------------------------------------------------------- */

static int do_write_jpeg(FILE *fp, struct ng_video_buf *buf,
			 int quality, int gray)
{
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    unsigned int i;
    unsigned char *line;
    int line_length;

    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);
    jpeg_stdio_dest(&cinfo, fp);
    cinfo.image_width  = buf->fmt.width;
    cinfo.image_height = buf->fmt.height;
    cinfo.input_components = gray ? 1: 3;
    cinfo.in_color_space = gray ? JCS_GRAYSCALE: JCS_RGB;
    jpeg_set_defaults(&cinfo);
    jpeg_set_quality(&cinfo, quality, TRUE);
    jpeg_start_compress(&cinfo, TRUE);

    line_length = gray ? buf->fmt.width : buf->fmt.width * 3;
    for (i = 0, line = buf->data; i < buf->fmt.height;
	 i++, line += line_length)
	jpeg_write_scanlines(&cinfo, &line, 1);
    
    jpeg_finish_compress(&(cinfo));
    jpeg_destroy_compress(&(cinfo));
    fclose(fp);

    return 0;
}

int write_jpeg(char *filename, struct ng_video_buf *buf,
	       int quality, int gray)
{
    FILE *fp;

    if (NULL == (fp = fopen(filename,"w"))) {
	fprintf(stderr,"grab: can't open %s: %s\n",filename,strerror(errno));
	return -1;
    }
    return do_write_jpeg(fp,buf,quality,gray);
}

#if 0
int write_jpeg_fd(int fd, struct ng_video_buf *buf,
		  int quality, int gray)
{
    FILE *fp;
    
    if (NULL == (fp = fdopen(fd,"w"))) {
	fprintf(stderr,"grab: can't fdopen(%d): %s\n",fd,strerror(errno));
	return -1;
    }
    return do_write_jpeg(fp,buf,quality,gray);
}
#endif

int write_ppm(char *filename, struct ng_video_buf *buf)
{
    FILE *fp;
    
    if (NULL == (fp = fopen(filename,"w"))) {
	fprintf(stderr,"grab: can't open %s: %s\n",filename,strerror(errno));
	return -1;
    }
    fprintf(fp,"P6\n%d %d\n255\n",
	    buf->fmt.width,buf->fmt.height);
    fwrite(buf->data, buf->fmt.height, 3*buf->fmt.width,fp);
    fclose(fp);

    return 0;
}

int write_pgm(char *filename, struct ng_video_buf *buf)
{
    FILE *fp;
    
    if (NULL == (fp = fopen(filename,"w"))) {
	fprintf(stderr,"grab: can't open %s: %s\n",filename,strerror(errno));
	return -1;
    }
    fprintf(fp,"P5\n%d %d\n255\n",
	    buf->fmt.width, buf->fmt.height);
    fwrite(buf->data, buf->fmt.height, buf->fmt.width, fp);
    fclose(fp);

    return 0;
}

/* ---------------------------------------------------------------------- */
/* *.wav I/O stolen from cdda2wav                                         */

/* Copyright (C) by Heiko Eissfeldt */

typedef uint8_t   BYTE;
typedef uint16_t  WORD;
typedef uint32_t  DWORD;
typedef uint32_t  FOURCC;	/* a four character code */

/* flags for 'wFormatTag' field of WAVEFORMAT */
#define WAVE_FORMAT_PCM 1

/* MMIO macros */
#define mmioFOURCC(ch0, ch1, ch2, ch3) \
  ((DWORD)(BYTE)(ch0) | ((DWORD)(BYTE)(ch1) << 8) | \
  ((DWORD)(BYTE)(ch2) << 16) | ((DWORD)(BYTE)(ch3) << 24))

#define FOURCC_RIFF	mmioFOURCC ('R', 'I', 'F', 'F')
#define FOURCC_LIST	mmioFOURCC ('L', 'I', 'S', 'T')
#define FOURCC_WAVE	mmioFOURCC ('W', 'A', 'V', 'E')
#define FOURCC_FMT	mmioFOURCC ('f', 'm', 't', ' ')
#define FOURCC_DATA	mmioFOURCC ('d', 'a', 't', 'a')

typedef struct CHUNKHDR {
    FOURCC ckid;		/* chunk ID */
    DWORD dwSize; 	        /* chunk size */
} CHUNKHDR;

/* simplified Header for standard WAV files */
typedef struct WAVEHDR {
    CHUNKHDR chkRiff;
    FOURCC fccWave;
    CHUNKHDR chkFmt;
    WORD wFormatTag;	   /* format type */
    WORD nChannels;	   /* number of channels (i.e. mono, stereo, etc.) */
    DWORD nSamplesPerSec;  /* sample rate */
    DWORD nAvgBytesPerSec; /* for buffer estimation */
    WORD nBlockAlign;	   /* block size of data */
    WORD wBitsPerSample;
    CHUNKHDR chkData;
} WAVEHDR;

#if BYTE_ORDER == BIG_ENDIAN
# define cpu_to_le32(x) SWAP4((x))
# define cpu_to_le16(x) SWAP2((x))
# define le32_to_cpu(x) SWAP4((x))
# define le16_to_cpu(x) SWAP2((x))
#else
# define cpu_to_le32(x) (x)
# define cpu_to_le16(x) (x)
# define le32_to_cpu(x) (x)
# define le16_to_cpu(x) (x)
#endif

static void
wav_init_header(WAVEHDR *fileheader, struct ng_audio_fmt *audio)
{
    /* stolen from cdda2wav */
    int nBitsPerSample = ng_afmt_to_bits[audio->fmtid];
    int channels       = ng_afmt_to_channels[audio->fmtid];
    int rate           = audio->rate;

    unsigned long nBlockAlign = channels * ((nBitsPerSample + 7) / 8);
    unsigned long nAvgBytesPerSec = nBlockAlign * rate;
    unsigned long temp = /* data length */ 0 +
	sizeof(WAVEHDR) - sizeof(CHUNKHDR);

    fileheader->chkRiff.ckid    = cpu_to_le32(FOURCC_RIFF);
    fileheader->fccWave         = cpu_to_le32(FOURCC_WAVE);
    fileheader->chkFmt.ckid     = cpu_to_le32(FOURCC_FMT);
    fileheader->chkFmt.dwSize   = cpu_to_le32(16);
    fileheader->wFormatTag      = cpu_to_le16(WAVE_FORMAT_PCM);
    fileheader->nChannels       = cpu_to_le16(channels);
    fileheader->nSamplesPerSec  = cpu_to_le32(rate);
    fileheader->nAvgBytesPerSec = cpu_to_le32(nAvgBytesPerSec);
    fileheader->nBlockAlign     = cpu_to_le16(nBlockAlign);
    fileheader->wBitsPerSample  = cpu_to_le16(nBitsPerSample);
    fileheader->chkData.ckid    = cpu_to_le32(FOURCC_DATA);
    fileheader->chkRiff.dwSize  = cpu_to_le32(temp);
    fileheader->chkData.dwSize  = cpu_to_le32(0 /* data length */);
}

static void
wav_start_write(int fd, WAVEHDR *fileheader, struct ng_audio_fmt *audio)
{
    wav_init_header(fileheader,audio);
    write(fd,fileheader,sizeof(WAVEHDR));
}

static void
wav_stop_write(int fd, WAVEHDR *fileheader, int wav_size)
{
    unsigned long temp = wav_size + sizeof(WAVEHDR) - sizeof(CHUNKHDR);

    fileheader->chkRiff.dwSize = cpu_to_le32(temp);
    fileheader->chkData.dwSize = cpu_to_le32(wav_size);
    lseek(fd,0,SEEK_SET);
    write(fd,fileheader,sizeof(WAVEHDR));
}

/* ---------------------------------------------------------------------- */

struct files_handle {
    /* file name */
    char   file[MAXPATHLEN];

    /* format */
    struct ng_video_fmt video;
    struct ng_audio_fmt audio;

    /* *.wav file */
    int      wav_fd;
    WAVEHDR  wav_header;
    int      wav_size;

    /* misc */
    int      gotcha;
};

static void*
files_open(char *filesname, char *audioname,
	   struct ng_video_fmt *video, const void *priv_video, int fps,
	   struct ng_audio_fmt *audio, const void *priv_audio)
{
    struct files_handle *h;

    if (video->fmtid != VIDEO_NONE && NULL == filesname)
	return NULL;
    if (NULL == (h = malloc(sizeof(*h))))
	return NULL;

    /* init */
    memset(h,0,sizeof(*h));
    h->video         = *video;
    h->audio         = *audio;
    if (filesname)
	strcpy(h->file,filesname);

    if (h->audio.fmtid != AUDIO_NONE) {
	h->wav_fd = open(audioname, O_CREAT | O_RDWR | O_TRUNC, 0666);
	if (-1 == h->wav_fd) {
	    fprintf(stderr,"open %s: %s\n",audioname,strerror(errno));
	    free(h);
	    return NULL;
	}
	wav_start_write(h->wav_fd,&h->wav_header,&h->audio);
    }

    return h;
}

static int
files_video(void *handle, struct ng_video_buf *buf)
{
    struct files_handle *h = handle;
    int rc = -1;
    FILE *fp;

    if (h->gotcha) {
	fprintf(stderr,"Oops: can't count up file names any more\n");
	return -1;
    }
    
    switch (h->video.fmtid) {
    case VIDEO_RGB24:
	rc = write_ppm(h->file, buf);
	break;
    case VIDEO_GRAY:
	rc = write_pgm(h->file, buf);
	break;
    case VIDEO_JPEG:
	if (NULL == (fp = fopen(h->file,"w"))) {
	    fprintf(stderr,"grab: can't open %s: %s\n",h->file,strerror(errno));
	    rc = -1;
	} else {
	    fwrite(buf->data,buf->size,1,fp);
	    fclose(fp);
	    rc = 0;
	}
    }
    if (1 != patch_up(h->file))
	h->gotcha = 1;
    return rc;
}

static int
files_audio(void *handle, struct ng_audio_buf *buf)
{
    struct files_handle *h = handle;
    if (buf->size != write(h->wav_fd,buf->data,buf->size))
	return -1;
    h->wav_size += buf->size;
    return 0;
}

static int
files_close(void *handle)
{
    struct files_handle *h = handle;

    if (h->audio.fmtid != AUDIO_NONE) {
	wav_stop_write(h->wav_fd,&h->wav_header,h->wav_size);
	close(h->wav_fd);
    }
    free(h);
    return 0;
}

/* ---------------------------------------------------------------------- */

struct raw_priv {
    int      yuv4mpeg;
};

struct raw_handle {
    /* format */
    struct ng_video_fmt video;
    struct ng_audio_fmt audio;
    const struct raw_priv *vpriv;

    /* video file*/
    int      fd;

    /* *.wav file */
    int      wav_fd;
    WAVEHDR  wav_header;
    int      wav_size;
};

static void*
raw_open(char *videoname, char *audioname,
	 struct ng_video_fmt *video, const void *priv_video, int fps,
	 struct ng_audio_fmt *audio, const void *priv_audio)
{
    struct raw_handle *h;
    int frame_rate_code = 0;
    int frame_rate_mul  = fps;
    int frame_rate_div  = 1000;
    
    if (NULL == (h = malloc(sizeof(*h))))
	return NULL;

    /* init */
    memset(h,0,sizeof(*h));
    h->video         = *video;
    h->audio         = *audio;
    h->vpriv         = priv_video;

    /* audio */
    if (h->audio.fmtid != AUDIO_NONE) {
	h->wav_fd = open(audioname, O_CREAT | O_RDWR | O_TRUNC, 0666);
	if (-1 == h->wav_fd) {
	    fprintf(stderr,"open %s: %s\n",audioname,strerror(errno));
	    free(h);
	    return NULL;
	}
	wav_start_write(h->wav_fd,&h->wav_header,&h->audio);
    }

    /* video */
    if (h->video.fmtid != VIDEO_NONE) {
	if (h->vpriv && h->vpriv->yuv4mpeg) {
	    switch (fps) {
	    case 23976:  frame_rate_code = 1;          /* 24000 / 1001 */
		         frame_rate_mul  = 24000;
			 frame_rate_div  = 1001;
			 break;
	    case 29970:  frame_rate_code = 4;          /* 30000 / 1001 */
		         frame_rate_mul  = 30000;
		         frame_rate_div  = 1001;
			 break;
	    case 59940:  frame_rate_code = 7;          /* 60000 / 1001 */
		         frame_rate_mul  = 60000;
			 frame_rate_div  = 1001;
			 break;
	    case 24000:  frame_rate_code = 2; break;
	    case 25000:  frame_rate_code = 3; break;
	    case 30000:  frame_rate_code = 5; break;
	    case 50000:  frame_rate_code = 6; break;
	    case 60000:  frame_rate_code = 8; break;
	    default:
		fprintf(stderr,"illegal frame rate\n");
		free(h);
		return NULL;
	    }
	}
	if (NULL != videoname) {
	    h->fd = open(videoname, O_CREAT | O_RDWR | O_TRUNC, 0666);
	    if (-1 == h->fd) {
		fprintf(stderr,"open %s: %s\n",videoname,strerror(errno));
		if (h->wav_fd)
		    close(h->wav_fd);
		free(h);
		return NULL;
	    }
	} else {
	    h->fd = 1; /* use stdout */
	}
	if (h->vpriv && h->vpriv->yuv4mpeg) {
	    char header[64];
	    switch (h->vpriv->yuv4mpeg) {
	    case 1:
		sprintf(header, "YUV4MPEG %d %d %d\n",
			h->video.width, h->video.height,frame_rate_code);
		break;
	    case 2:
	    	sprintf(header, "YUV4MPEG2 W%d H%d F%d:%d\n",
			h->video.width, h->video.height,
			frame_rate_mul, frame_rate_div);
		break;
	    }
	    write(h->fd, header, strlen(header));
	}
    }

    return h;
}

static int
raw_video(void *handle, struct ng_video_buf *buf)
{
    struct raw_handle *h = handle;

    if (h->vpriv && h->vpriv->yuv4mpeg) 
	switch (h->vpriv->yuv4mpeg) {
	case 1:
	   if (6 != write(h->fd, "FRAME\n", 6))
	   	return -1;
	   break;
	case 2:
	   if (7 != write(h->fd, "FRAME \n", 7))
	   	return -1;
	   break;
	}

    if (buf->size != write(h->fd,buf->data,buf->size))
	return -1;
    return 0;
}

static int
raw_audio(void *handle, struct ng_audio_buf *buf)
{
    struct raw_handle *h = handle;
    if (buf->size != write(h->wav_fd,buf->data,buf->size))
	return -1;
    h->wav_size += buf->size;
    return 0;
}

static int
raw_close(void *handle)
{
    struct raw_handle *h = handle;

    if (h->audio.fmtid != AUDIO_NONE) {
	wav_stop_write(h->wav_fd,&h->wav_header,h->wav_size);
	close(h->wav_fd);
    }
    if (h->video.fmtid != VIDEO_NONE && 1 != h->fd)
	close(h->fd);
    free(h);
    return 0;
}

/* ----------------------------------------------------------------------- */
/* data structures describing our capabilities                             */

static const struct ng_format_list files_vformats[] = {
    {
	name:  "ppm",
	ext:   "ppm",
	fmtid: VIDEO_RGB24,
    },{
	name:  "pgm",
	ext:   "pgm",
	fmtid: VIDEO_GRAY,
    },{
	name:  "jpeg",
	ext:   "jpeg",
	fmtid: VIDEO_JPEG,
    },{
	/* EOF */
    }
};

static struct raw_priv yuv4mpeg = {
    yuv4mpeg: 1
};

static struct raw_priv yuv4mpeg2 = {
    yuv4mpeg: 2
};

static const struct ng_format_list raw_vformats[] = {
    {
	name:  "rgb",
	ext:   "raw",
	fmtid: VIDEO_RGB24,
    },{
	name:  "gray",
	ext:   "raw",
	fmtid: VIDEO_GRAY,
    },{
	name:  "422",
	ext:   "raw",
	fmtid: VIDEO_YUYV,
    },{
	name:  "422p",
	ext:   "raw",
	fmtid: VIDEO_YUV422P,
    },{
	name:  "4mpeg",
	desc:  "yuv4mpeg (mpeg2enc >= 1.6)",
	ext:   "yuv",
	fmtid: VIDEO_YUV420P,
	priv:  &yuv4mpeg2,
    },{
	name:  "4mpeg-o",
	desc:  "yuv4mpeg (old mpeg2enc)",
	ext:   "yuv",
	fmtid: VIDEO_YUV420P,
	priv:  &yuv4mpeg,
    },{
	/* EOF */
    }
};

static const struct ng_format_list wav_aformats[] = {
    {
	name:  "mono8",
	ext:   "wav",
	fmtid: AUDIO_U8_MONO,
    },{
	name:  "mono16",
	ext:   "wav",
	fmtid: AUDIO_S16_LE_MONO,
    },{
	name:  "stereo",
	ext:   "wav",
	fmtid: AUDIO_S16_LE_STEREO,
    },{
	/* EOF */
    }
};

struct ng_writer files_writer = {
    name:      "files",
    desc:      "multiple image files",
    video:     files_vformats,
    audio:     wav_aformats,
    wr_open:   files_open,
    wr_video:  files_video,
    wr_audio:  files_audio,
    wr_close:  files_close,
};

struct ng_writer raw_writer = {
    name:      "raw",
    desc:      "single file, raw video data",
    video:     raw_vformats,
    audio:     wav_aformats,
    wr_open:   raw_open,
    wr_video:  raw_video,
    wr_audio:  raw_audio,
    wr_close:  raw_close,
};

/* ------------------------------------------------------------------- */

static void __init writefile_init(void)
{
    ng_writer_register(NG_PLUGIN_MAGIC,__FILE__,&files_writer);
    ng_writer_register(NG_PLUGIN_MAGIC,__FILE__,&raw_writer);
}
