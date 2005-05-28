#ifndef __LINUX_VIDEODEV2_H
#define __LINUX_VIDEODEV2_H
/*
 *	Video for Linux Two
 *
 *	Header file for v4l or V4L2 drivers and applications, for
 *	Linux kernels 2.2.x or 2.4.x.
 *
 *	See http://www.thedirks.org/v4l2/ for API specs and other
 *	v4l2 documentation.
 *
 *	Author: Bill Dirks <bdirks@pacbell.net>
 *		Justin Schoeman
 *		et al.
 */

#define V4L2_MAJOR_VERSION	0
#define V4L2_MINOR_VERSION	20


/*
 *	M I S C E L L A N E O U S
 */

/*  Four-character-code (FOURCC) */
#define v4l2_fourcc(a,b,c,d)\
        (((__u32)(a)<<0)|((__u32)(b)<<8)|((__u32)(c)<<16)|((__u32)(d)<<24))

/*  Open flag for non-capturing opens on capture devices  */
#define O_NONCAP	O_TRUNC
#define O_NOIO		O_TRUNC

/*  Timestamp data type, 64-bit signed integer, in nanoseconds  */
#ifndef STAMP_T
#define STAMP_T
typedef __s64 stamp_t;
#endif

/*
 *	D R I V E R   C A P A B I L I T I E S
 */
struct v4l2_capability
{
	char	        name[32];	/* Descriptive, and unique */
	unsigned int	type;		/* Device type, see below */
	unsigned int	inputs;		/* Num video inputs */
	unsigned int	outputs;	/* Num video outputs */
	unsigned int	audios;		/* Num audio devices */
	unsigned int	maxwidth;
	unsigned int	maxheight;
	unsigned int	minwidth;
	unsigned int	minheight;
	unsigned int	maxframerate;
	__u32	        flags;		/* Feature flags, see below */
	__u32	        reserved[4];
};
/* Values for 'type' field */
#define V4L2_TYPE_CAPTURE	0	/* Is a video capture device */
#define V4L2_TYPE_CODEC		1	/* Is a CODEC device */
#define V4L2_TYPE_OUTPUT	2	/* Is a video output device */
#define V4L2_TYPE_FX		3	/* Is a video effects device */
#define V4L2_TYPE_VBI		4	/* Is a VBI capture device */
#define V4L2_TYPE_VTR		5	/* Is a tape recorder controller */
#define V4L2_TYPE_VTX		6	/* Is a teletext device */
#define V4L2_TYPE_RADIO		7	/* Is a radio device */
#define V4L2_TYPE_VBI_INPUT	4	/* Is a VBI capture device */
#define V4L2_TYPE_VBI_OUTPUT	9	/* Is a VBI output device */
#define V4L2_TYPE_PRIVATE	1000	/* Start of driver private types */
/* Flags for 'flags' field */
#define V4L2_FLAG_READ		0x00001 /* Can capture via read() call */
#define V4L2_FLAG_WRITE		0x00002 /* Can accept data via write() */
#define V4L2_FLAG_STREAMING	0x00004 /* Can capture streaming video */
#define V4L2_FLAG_PREVIEW	0x00008 /* Can do automatic preview */
#define V4L2_FLAG_SELECT	0x00010 /* Supports the select() call */
#define V4L2_FLAG_TUNER		0x00020 /* Can tune */
#define V4L2_FLAG_MONOCHROME	0x00040 /* Monochrome only */
#define V4L2_FLAG_DATA_SERVICE	0x00080 /* Has a related data service dev. */


/*
 *	V I D E O   I M A G E   F O R M A T
 */
struct v4l2_pix_format
{
	__u32	width;
	__u32	height;
	__u32	depth;
	__u32	pixelformat;
	__u32	flags;
	__u32	bytesperline;	/* only used when there are pad bytes */
	__u32	sizeimage;
	__u32	priv;		/* private data, depends on pixelformat */
};
/*           Pixel format    FOURCC                  depth  Description   */
#define V4L2_PIX_FMT_RGB332  v4l2_fourcc('R','G','B','1') /*  8  RGB-3-3-2     */
#define V4L2_PIX_FMT_RGB555  v4l2_fourcc('R','G','B','O') /* 16  RGB-5-5-5     */
#define V4L2_PIX_FMT_RGB565  v4l2_fourcc('R','G','B','P') /* 16  RGB-5-6-5     */
#define V4L2_PIX_FMT_RGB555X v4l2_fourcc('R','G','B','Q') /* 16  RGB-5-5-5 BE  */
#define V4L2_PIX_FMT_RGB565X v4l2_fourcc('R','G','B','R') /* 16  RGB-5-6-5 BE  */
#define V4L2_PIX_FMT_BGR24   v4l2_fourcc('B','G','R','3') /* 24  BGR-8-8-8     */
#define V4L2_PIX_FMT_RGB24   v4l2_fourcc('R','G','B','3') /* 24  RGB-8-8-8     */
#define V4L2_PIX_FMT_BGR32   v4l2_fourcc('B','G','R','4') /* 32  BGR-8-8-8-8   */
#define V4L2_PIX_FMT_RGB32   v4l2_fourcc('R','G','B','4') /* 32  RGB-8-8-8-8   */
#define V4L2_PIX_FMT_GREY    v4l2_fourcc('G','R','E','Y') /*  8  Greyscale     */
#define V4L2_PIX_FMT_YVU410  v4l2_fourcc('Y','V','U','9') /*  9  YVU 4:1:0     */
#define V4L2_PIX_FMT_YVU420  v4l2_fourcc('Y','V','1','2') /* 12  YVU 4:2:0     */
#define V4L2_PIX_FMT_YUYV    v4l2_fourcc('Y','U','Y','V') /* 16  YUV 4:2:2     */
#define V4L2_PIX_FMT_UYVY    v4l2_fourcc('U','Y','V','Y') /* 16  YUV 4:2:2     */
#if 0
#define V4L2_PIX_FMT_YVU422P v4l2_fourcc('4','2','2','P') /* 16  YVU422 planar */
#define V4L2_PIX_FMT_YVU411P v4l2_fourcc('4','1','1','P') /* 16  YVU411 planar */
#endif
#define V4L2_PIX_FMT_YUV422P v4l2_fourcc('4','2','2','P') /* 16  YVU422 planar */
#define V4L2_PIX_FMT_YUV411P v4l2_fourcc('4','1','1','P') /* 16  YVU411 planar */
#define V4L2_PIX_FMT_Y41P    v4l2_fourcc('Y','4','1','P') /* 12  YUV 4:1:1     */

/* two planes -- one Y, one Cr + Cb interleaved  */
#define V4L2_PIX_FMT_NV12    v4l2_fourcc('N','V','1','2') /* 12  Y/CbCr 4:2:0  */
#define V4L2_PIX_FMT_NV21    v4l2_fourcc('N','V','2','1') /* 12  Y/CrCb 4:2:0  */

/*  The following formats are not defined in the V4L2 specification */
#define V4L2_PIX_FMT_YUV410  v4l2_fourcc('Y','U','V','9') /*  9  YUV 4:1:0     */
#define V4L2_PIX_FMT_YUV420  v4l2_fourcc('Y','U','1','2') /* 12  YUV 4:2:0     */
#define V4L2_PIX_FMT_YYUV    v4l2_fourcc('Y','Y','U','V') /* 16  YUV 4:2:2     */
#define V4L2_PIX_FMT_HI240   v4l2_fourcc('H','I','2','4') /*  8  8-bit color   */

/*  Vendor-specific formats   */
#define V4L2_PIX_FMT_WNVA    v4l2_fourcc('W','N','V','A') /* Winnov hw compres */


/*  Flags */
#define V4L2_FMT_FLAG_COMPRESSED	0x0001	/* Compressed format */
#define V4L2_FMT_FLAG_BYTESPERLINE	0x0002	/* bytesperline field valid */
#define V4L2_FMT_FLAG_NOT_INTERLACED	0x0000
#define V4L2_FMT_FLAG_INTERLACED	0x0004	/* Image is interlaced */
#define V4L2_FMT_FLAG_TOPFIELD		0x0008	/* is a top field only */
#define V4L2_FMT_FLAG_BOTFIELD		0x0010	/* is a bottom field only */
#define V4L2_FMT_FLAG_ODDFIELD		V4L2_FMT_FLAG_TOPFIELD
#define V4L2_FMT_FLAG_EVENFIELD		V4L2_FMT_FLAG_BOTFIELD
#define V4L2_FMT_FLAG_COMBINED		V4L2_FMT_FLAG_INTERLACED
#define V4L2_FMT_FLAG_FIELD_field	0x001C
#define V4L2_FMT_CS_field		0xF000	/* Color space field mask */
#define V4L2_FMT_CS_601YUV		0x1000	/* ITU YCrCb color space */
#define V4L2_FMT_FLAG_SWCONVERSION	0x0800	/* used only in format enum. */
/*  SWCONVERSION indicates the format is not natively supported by the  */
/*  driver and the driver uses software conversion to support it  */


/*
 *	F O R M A T   E N U M E R A T I O N
 */
struct v4l2_fmtdesc
{
	int	index;			/* Format number */
	char	description[32];	/* Description string */
	__u32	pixelformat;		/* Format fourcc */
	__u32	flags;			/* Format flags */
	__u32	depth;			/* Bits per pixel */
	__u32	reserved[2];
};

struct v4l2_cvtdesc
{
	int	index;
	struct
	{
		__u32	pixelformat;
		__u32	flags;
		__u32	depth;
		__u32	reserved[2];
	}	in, out;
};

struct v4l2_fxdesc
{
	int	index;
	char 	name[32];
	__u32	flags;
	__u32	inputs;
	__u32	controls;
	__u32	reserved[2];
};


/*
 *	T I M E C O D E
 */
struct v4l2_timecode
{
	__u8	frames;
	__u8	seconds;
	__u8	minutes;
	__u8	hours;
	__u8	userbits[4];
	__u32	flags;
	__u32	type;
};
/*  Type  */
#define V4L2_TC_TYPE_24FPS		1
#define V4L2_TC_TYPE_25FPS		2
#define V4L2_TC_TYPE_30FPS		3
#define V4L2_TC_TYPE_50FPS		4
#define V4L2_TC_TYPE_60FPS		5


/*  Flags  */
#define V4L2_TC_FLAG_DROPFRAME		0x0001 /* "drop-frame" mode */
#define V4L2_TC_FLAG_COLORFRAME		0x0002
#define V4L2_TC_USERBITS_field		0x000C
#define V4L2_TC_USERBITS_USERDEFINED	0x0000
#define V4L2_TC_USERBITS_8BITCHARS	0x0008
/* The above is based on SMPTE timecodes */


/*
 *	C O M P R E S S I O N   P A R A M E T E R S
 */
struct v4l2_compression
{
	int	quality;
	int	keyframerate;
	int	pframerate;
	__u32	reserved[5];
};


/*
 *	M E M O R Y - M A P P I N G   B U F F E R S
 */
struct v4l2_requestbuffers
{
	int	count;
	__u32	type;
	__u32	reserved[2];
};
struct v4l2_buffer
{
	int			index;
	__u32			type;
	__u32			offset;
	__u32			length;
	__u32			bytesused;
	__u32			flags;
	stamp_t			timestamp;
	struct v4l2_timecode	timecode;
	__u32			sequence;
	__u32			reserved[3];
};
/*  Buffer type codes and flags for 'type' field */
#define V4L2_BUF_TYPE_field		0x00001FFF  /* Type field mask  */
#define V4L2_BUF_TYPE_CAPTURE		0x00000001
#define V4L2_BUF_TYPE_CODECIN		0x00000002
#define V4L2_BUF_TYPE_CODECOUT		0x00000003
#define V4L2_BUF_TYPE_EFFECTSIN		0x00000004
#define V4L2_BUF_TYPE_EFFECTSIN2	0x00000005
#define V4L2_BUF_TYPE_EFFECTSOUT	0x00000006
#define V4L2_BUF_TYPE_VIDEOOUT		0x00000007
#define V4L2_BUF_TYPE_FXCONTROL		0x00000008
#define V4L2_BUF_TYPE_VBI		0x00000009

/*  Starting value of driver private buffer types  */
#define V4L2_BUF_TYPE_PRIVATE		0x00001000

#define V4L2_BUF_ATTR_DEVICEMEM	0x00010000  /* Buffer is on device (flag) */

/*  Flags used only in VIDIOC_REQBUFS  */
#define V4L2_BUF_REQ_field	0xF0000000
#define V4L2_BUF_REQ_CONTIG	0x10000000  /* Map all buffers in one
					       contiguous mmap(). This flag
					       only used in VIDIOC_REQBUFS */

/*  Flags for 'flags' field */
#define V4L2_BUF_FLAG_MAPPED	0x0001  /* Buffer is mapped (flag) */
#define V4L2_BUF_FLAG_QUEUED	0x0002	/* Buffer is queued for processing */
#define V4L2_BUF_FLAG_DONE	0x0004	/* Buffer is ready */
#define V4L2_BUF_FLAG_KEYFRAME	0x0008	/* Image is a keyframe (I-frame) */
#define V4L2_BUF_FLAG_PFRAME	0x0010	/* Image is a P-frame */
#define V4L2_BUF_FLAG_BFRAME	0x0020	/* Image is a B-frame */
#define V4L2_BUF_FLAG_TOPFIELD	0x0040	/* Image is a top field only */
#define V4L2_BUF_FLAG_BOTFIELD	0x0080	/* Image is a bottom field only */
#define V4L2_BUF_FLAG_ODDFIELD	V4L2_BUF_FLAG_TOPFIELD
#define V4L2_BUF_FLAG_EVENFIELD	V4L2_BUF_FLAG_BOTFIELD
#define V4L2_BUF_FLAG_TIMECODE	0x0100	/* timecode field is valid */

/*
 *	O V E R L A Y   P R E V I E W
 */
struct v4l2_framebuffer
{
	__u32			capability;
	__u32			flags;
	void			*base[3];
	struct v4l2_pix_format	fmt;
};
/*  Flags for the 'capability' field. Read only */
#define V4L2_FBUF_CAP_EXTERNOVERLAY	0x0001
#define V4L2_FBUF_CAP_CHROMAKEY		0x0002
#define V4L2_FBUF_CAP_CLIPPING		0x0004
#define V4L2_FBUF_CAP_SCALEUP		0x0008
#define V4L2_FBUF_CAP_SCALEDOWN		0x0010
#define V4L2_FBUF_CAP_BITMAP_CLIPPING	0x0020
/*  Flags for the 'flags' field. */
#define V4L2_FBUF_FLAG_PRIMARY		0x0001
#define V4L2_FBUF_FLAG_OVERLAY		0x0002
#define V4L2_FBUF_FLAG_CHROMAKEY	0x0004

struct v4l2_clip
{
	int			x;
	int			y;
	int			width;
	int			height;
	struct v4l2_clip	*next;
};
struct v4l2_window
{
	int			x;
	int			y;
        unsigned int   		width;
	unsigned int	       	height;
	__u32			chromakey;
	struct v4l2_clip	*clips;
	int			clipcount;
	void			*bitmap;
};


/*
 *	D E V I C E   P E R F O R M A N C E
 */
struct v4l2_performance
{
	int	frames;
	int	framesdropped;
	__u64	bytesin;
	__u64	bytesout;
	__u32	reserved[4];
};

/*
 *	C A P T U R E   P A R A M E T E R S
 */
struct v4l2_captureparm
{
	__u32		capability;	/*  Supported modes */
	__u32		capturemode;	/*  Current mode */
	unsigned long	timeperframe;	/*  Time per frame in .1us units */
	__u32		extendedmode;	/*  Driver-specific extensions */
	__u32		reserved[4];
};
/*  Flags for 'capability' and 'capturemode' fields */
#define V4L2_MODE_HIGHQUALITY	0x0001	/*  High quality imaging mode */
//#define V4L2_MODE_VFLIP		0x0002	/*  Flip image vertically */
//#define V4L2_MODE_HFLIP		0x0004	/*  Flip image horizontally */
#define V4L2_CAP_TIMEPERFRAME	0x1000	/*  timeperframe field is supported */

struct v4l2_outputparm
{
	__u32		capability;	/*  Supported modes */
	__u32		outputmode;	/*  Current mode */
	unsigned long	timeperframe;	/*  Time per frame in .1us units */
	__u32		extendedmode;	/*  Driver-specific extensions */
	__u32		reserved[4];
};

/*
 *	I N P U T   I M A G E   C R O P P I N G
 */
struct v4l2_cropcap
{
	__u32	capability;
	int	min_x;
	int	min_y;
	int	max_x;
	int	max_y;
	int	default_left;
	int	default_top;
	int	default_right;
	int	default_bottom;
	__u32	reserved[2];
};
struct v4l2_crop
{
	int	left;
	int	top;
	int	right;
	int	bottom;
	__u32	reserved;
};

/*
 *	D I G I T A L   Z O O M
 */
struct v4l2_zoomcap
{
	__u32	capability;
	__u32	maxwidth;
	__u32	maxheight;
	__u32	minwidth;
	__u32	minheight;
	__u32	reserved[2];
};
/*  Flags for the capability field  */
#define V4L2_ZOOM_NONCAP		0x0001
#define V4L2_ZOOM_WHILESTREAMING	0x0002

struct v4l2_zoom
{
	__u32	x;
	__u32	y;
	__u32	width;
	__u32	height;
	__u32	reserved;
};


/*
 *      A N A L O G   V I D E O   S T A N D A R D
 */
struct v4l2_standard
{
	__u8		name[24];
	struct {
		__u32	numerator;
		__u32	denominator;	/* >= 1 */
	} framerate;			/* Frames, not fields */
	__u32		framelines;
	__u32		reserved1;
	__u32		colorstandard;
	union {				
		struct {
			__u32		colorsubcarrier; /* Hz */
		} 		pal;
		struct {					
			__u32		colorsubcarrier; /* Hz */
		} 		ntsc;
		struct {
			__u32		f0b;	/* Hz (blue) */
			__u32		f0r;	/* Hz (red)  */
		} 		secam;
		__u8		reserved[12];
	} colorstandard_data;
	__u32		transmission;	/* Bit field. Must be zero for
					   non-modulators/demodulators. */
	__u32		reserved2;	/* Must be set to zero */
};

/*  Values for the 'colorstandard' field  */
#define V4L2_COLOR_STD_PAL		1
#define V4L2_COLOR_STD_NTSC		2
#define V4L2_COLOR_STD_SECAM		3

/*  Values for the color subcarrier fields  */
#define V4L2_COLOR_SUBC_PAL	4433619		/* PAL BGHI, NTSC-44 */
#define V4L2_COLOR_SUBC_PAL_M	3575611		/* PAL M (Brazil) */
#define V4L2_COLOR_SUBC_PAL_N	3582056		/* PAL N */
#define V4L2_COLOR_SUBC_NTSC	3579545		/* NTSC M, NTSC-Japan */
#define V4L2_COLOR_SUBC_SECAMB	4250000		/* SECAM B - Y carrier */
#define V4L2_COLOR_SUBC_SECAMR	4406250		/* SECAM R - Y carrier */

/*  Flags for the 'transmission' field  */
#define V4L2_TRANSM_STD_B		(1<<1)
#define V4L2_TRANSM_STD_D		(1<<3)
#define V4L2_TRANSM_STD_G		(1<<6)
#define V4L2_TRANSM_STD_H		(1<<7)
#define V4L2_TRANSM_STD_I		(1<<8)
#define V4L2_TRANSM_STD_K		(1<<10)
#define V4L2_TRANSM_STD_K1		(1<<11)
#define V4L2_TRANSM_STD_L		(1<<12)
#define V4L2_TRANSM_STD_M		(1<<13)
#define V4L2_TRANSM_STD_N		(1<<14)


/*  Used in the VIDIOC_ENUMSTD ioctl for querying supported standards  */
struct v4l2_enumstd
{
	int			index;
	struct v4l2_standard	std;
	__u32			inputs;  /* set of inputs that */
					 /* support this standard */
	__u32			outputs; /* set of outputs that */
					 /* support this standard */
	__u32			reserved[2];
};


/*
 *	V I D E O   I N P U T S
 */
struct v4l2_input
{
	int	index;		/*  Which input */
	char	name[32];	/*  Label */
	int	type;		/*  Type of input */
	__u32	capability;	/*  Capability flags */
	int	assoc_audio;	/*  Associated audio input */
	__u32	reserved[4];
};
/*  Values for the 'type' field */
#define V4L2_INPUT_TYPE_TUNER		1
#define V4L2_INPUT_TYPE_CAMERA		2

/*  Flags for the 'capability' field */
#define V4L2_INPUT_CAP_AUDIO		0x0001	/* assoc_audio */


/*
 *	V I D E O   O U T P U T S
 */
struct v4l2_output
{
	int	index;		/*  Which output */
	char	name[32];	/*  Label */
	int	type;		/*  Type of output */
	__u32	capability;	/*  Capability flags */
	int	assoc_audio;	/*  Associated audio */
	__u32	reserved[4];
};
/*  Values for the 'type' field */
#define V4L2_OUTPUT_TYPE_MODULATOR		1
#define V4L2_OUTPUT_TYPE_ANALOG			2
#define V4L2_OUTPUT_TYPE_ANALOGVGAOVERLAY	3

/*  Flags for the 'capability' field */
#define V4L2_OUTPUT_CAP_AUDIO		0x0001	/* assoc_audio */


/*
 *	C O N T R O L S
 */
struct v4l2_control
{
	__u32		id;
	int		value;
};

/*  Used in the VIDIOC_QUERYCTRL ioctl for querying controls */
struct v4l2_queryctrl
{
	__u32		id;
	__u8		name[32];	/* Whatever */
	int		minimum;	/* Note signedness */
	int		maximum;
	unsigned int	step;
	int		default_value;
	__u32		type;
	__u32		flags;
	__u32		category;	/* Automatically filled in by V4L2 */
	__u8		group[32];	/*   for pre-defined controls      */
	__u32		reserved[2];
};

/*  Used in the VIDIOC_QUERYMENU ioctl for querying menu items */
struct v4l2_querymenu
{
	__u32		id;
	int		index;
	__u8		name[32];	/* Whatever */
	int		reserved;
};

/*  Used in V4L2_BUF_TYPE_FXCONTROL buffers  */
struct v4l2_fxcontrol
{
	__u32	id;
	__u32	value;
};

/*  Control types  */
#define V4L2_CTRL_TYPE_INTEGER		0
#define V4L2_CTRL_TYPE_BOOLEAN		1
#define V4L2_CTRL_TYPE_MENU		2
#define V4L2_CTRL_TYPE_BUTTON		3

/*  Control flags  */
#define V4L2_CTRL_FLAG_DISABLED		0x0001
#define V4L2_CTRL_FLAG_GRABBED		0x0002

/*  Control categories	*/
#define V4L2_CTRL_CAT_VIDEO		1  /*  "Video"   */
#define V4L2_CTRL_CAT_AUDIO		2  /*  "Audio"   */
#define V4L2_CTRL_CAT_EFFECT		3  /*  "Effect"  */

/*  Control IDs defined by V4L2 */
#define V4L2_CID_BASE			0x00980900
/*  IDs reserved for driver specific controls */
#define V4L2_CID_PRIVATE_BASE		0x08000000
/*  IDs reserved for effect-specific controls on effects devices  */
#define V4L2_CID_EFFECT_BASE		0x0A00B000

#define V4L2_CID_BRIGHTNESS		(V4L2_CID_BASE+0)
#define V4L2_CID_CONTRAST		(V4L2_CID_BASE+1)
#define V4L2_CID_SATURATION		(V4L2_CID_BASE+2)
#define V4L2_CID_HUE			(V4L2_CID_BASE+3)
#define V4L2_CID_AUDIO_VOLUME		(V4L2_CID_BASE+5)
#define V4L2_CID_AUDIO_BALANCE		(V4L2_CID_BASE+6)
#define V4L2_CID_AUDIO_BASS		(V4L2_CID_BASE+7)
#define V4L2_CID_AUDIO_TREBLE		(V4L2_CID_BASE+8)
#define V4L2_CID_AUDIO_MUTE		(V4L2_CID_BASE+9)
#define V4L2_CID_AUDIO_LOUDNESS		(V4L2_CID_BASE+10)
#define V4L2_CID_BLACK_LEVEL		(V4L2_CID_BASE+11)
#define V4L2_CID_AUTO_WHITE_BALANCE	(V4L2_CID_BASE+12)
#define V4L2_CID_DO_WHITE_BALANCE	(V4L2_CID_BASE+13)
#define V4L2_CID_RED_BALANCE		(V4L2_CID_BASE+14)
#define V4L2_CID_BLUE_BALANCE		(V4L2_CID_BASE+15)
#define V4L2_CID_GAMMA			(V4L2_CID_BASE+16)
#define V4L2_CID_WHITENESS		(V4L2_CID_GAMMA) /* ? Not sure */
#define V4L2_CID_EXPOSURE		(V4L2_CID_BASE+17)
#define V4L2_CID_AUTOGAIN		(V4L2_CID_BASE+18)
#define V4L2_CID_GAIN			(V4L2_CID_BASE+19)
#define V4L2_CID_HFLIP			(V4L2_CID_BASE+20)
#define V4L2_CID_VFLIP			(V4L2_CID_BASE+21)
#define V4L2_CID_HCENTER		(V4L2_CID_BASE+22)
#define V4L2_CID_VCENTER		(V4L2_CID_BASE+23)
#define V4L2_CID_LASTP1			(V4L2_CID_BASE+24) /* last CID + 1 */
/*  Remember to change fill_ctrl_category() in videodev.c  */

/*
 *	T U N I N G
 */
struct v4l2_tuner
{
	int			input;
	char			name[32];
	struct v4l2_standard	std;
	__u32			capability;
	__u32			rangelow;
	__u32			rangehigh;
	__u32			rxsubchans;
	__u32			audmode;
	int			signal;
	int			afc;
	__u32			reserved[4];
};
struct v4l2_modulator
{
	int			output;
	char			name[32];
	struct v4l2_standard	std;
	__u32			capability;
	__u32			rangelow;
	__u32			rangehigh;
	__u32			txsubchans;
	__u32			reserved[4];
};
/*  Flags for the 'capability' field */
#define V4L2_TUNER_CAP_LOW		0x0001
#define V4L2_TUNER_CAP_NORM		0x0002
#define V4L2_TUNER_CAP_STEREO		0x0010
#define V4L2_TUNER_CAP_LANG2		0x0020
#define V4L2_TUNER_CAP_SAP		0x0020
#define V4L2_TUNER_CAP_LANG1		0x0040

/*  Flags for the 'rxsubchans' field */
#define V4L2_TUNER_SUB_MONO		0x0001
#define V4L2_TUNER_SUB_STEREO		0x0002
#define V4L2_TUNER_SUB_LANG2		0x0004
#define V4L2_TUNER_SUB_SAP		0x0004
#define V4L2_TUNER_SUB_LANG1		0x0008

/*  Values for the 'audmode' field */
#define V4L2_TUNER_MODE_MONO		0x0000
#define V4L2_TUNER_MODE_STEREO		0x0001
#define V4L2_TUNER_MODE_LANG2		0x0002
#define V4L2_TUNER_MODE_SAP		0x0002
#define V4L2_TUNER_MODE_LANG1		0x0003

struct v4l2_frequency
{
	int	input;
	__u32	frequency;
	__u32	reserved[2];
};

/*
 *	A U D I O
 */
struct v4l2_audio
{
	int	audio;
	char	name[32];
	__u32	capability;
	__u32	mode;
	__u32	reserved[2];
};
/*  Flags for the 'capability' field */
#define V4L2_AUDCAP_EFFECTS		0x0020
#define V4L2_AUDCAP_LOUDNESS		0x0040
#define V4L2_AUDCAP_AVL			0x0080

/*  Flags for the 'mode' field */
#define V4L2_AUDMODE_LOUDNESS		0x00002
#define V4L2_AUDMODE_AVL		0x00004
#define V4L2_AUDMODE_STEREO_field	0x0FF00
#define V4L2_AUDMODE_STEREO_LINEAR	0x00100
#define V4L2_AUDMODE_STEREO_PSEUDO	0x00200
#define V4L2_AUDMODE_STEREO_SPATIAL30	0x00300
#define V4L2_AUDMODE_STEREO_SPATIAL50	0x00400

struct v4l2_audioout
{
	int	audio;
	char	name[32];
	__u32	capability;
	__u32	mode;
	__u32	reserved[2];
};

/*
 *	D A T A   S E R V I C E S   ( V B I )
 *
 *	Data services API by Michael Schimek
 */

struct v4l2_vbi_format
{
	__u32	sampling_rate;		/* in 1 Hz */
	__u32	offset;
	__u32	samples_per_line;
	__u32	sample_format;		/* V4L2_VBI_SF_* */
	__s32	start[2];
	__u32	count[2];
	__u32	flags;			/* V4L2_VBI_* */
	__u32	reserved2;		/* must be zero */
};

/*  VBI sampling formats */
#define V4L2_VBI_SF_UBYTE	1

/*  VBI flags  */
#define V4L2_VBI_UNSYNC		(1<< 0)
#define V4L2_VBI_INTERLACED	(1<< 1)


/*
 *	A G G R E G A T E   S T R U C T U R E S
 */

/*	Stream data format
 */
struct v4l2_format
{
	__u32	type;
	union
	{
		struct v4l2_pix_format	pix;	/*  image format  */
		struct v4l2_vbi_format	vbi;	/*  VBI data  */
		/*  add more  */
		__u8	raw_data[200];  /* user-defined */
	} fmt;
};


/*	Stream type-dependent parameters
 */
struct v4l2_streamparm
{
	__u32	type;
	union
	{
		struct v4l2_captureparm	capture;
		struct v4l2_outputparm	output;
		/*  add more  */
		__u8	raw_data[200];  /* user-defined */
	} parm;
};



/*
 *	I O C T L   C O D E S   F O R   V I D E O   D E V I C E S
 *
 */
#define VIDIOC_QUERYCAP		_IOR  ('V',  0, struct v4l2_capability)
#define VIDIOC_RESERVED		_IO   ('V',  1)
#define VIDIOC_ENUM_PIXFMT	_IOWR ('V',  2, struct v4l2_fmtdesc)
#define VIDIOC_ENUM_FBUFFMT	_IOWR ('V',  3, struct v4l2_fmtdesc)
#define VIDIOC_G_FMT		_IOWR ('V',  4, struct v4l2_format)
#define VIDIOC_S_FMT		_IOWR ('V',  5, struct v4l2_format)
#define VIDIOC_G_COMP		_IOR  ('V',  6, struct v4l2_compression)
#define VIDIOC_S_COMP		_IOW  ('V',  7, struct v4l2_compression)
#define VIDIOC_REQBUFS		_IOWR ('V',  8, struct v4l2_requestbuffers)
#define VIDIOC_QUERYBUF		_IOWR ('V',  9, struct v4l2_buffer)
#define VIDIOC_G_FBUF		_IOR  ('V', 10, struct v4l2_framebuffer)
#define VIDIOC_S_FBUF		_IOW  ('V', 11, struct v4l2_framebuffer)
#define VIDIOC_G_WIN		_IOR  ('V', 12, struct v4l2_window)
#define VIDIOC_S_WIN		_IOW  ('V', 13, struct v4l2_window)
#define VIDIOC_PREVIEW		_IOWR ('V', 14, int)
#define VIDIOC_QBUF		_IOWR ('V', 15, struct v4l2_buffer)
#define VIDIOC_DQBUF		_IOWR ('V', 17, struct v4l2_buffer)
#define VIDIOC_STREAMON		_IOW  ('V', 18, int)
#define VIDIOC_STREAMOFF	_IOW  ('V', 19, int)
#define VIDIOC_G_PERF		_IOR  ('V', 20, struct v4l2_performance)
#define VIDIOC_G_PARM		_IOWR ('V', 21, struct v4l2_streamparm)
#define VIDIOC_S_PARM		_IOW  ('V', 22, struct v4l2_streamparm)
#define VIDIOC_G_STD		_IOR  ('V', 23, struct v4l2_standard)
#define VIDIOC_S_STD		_IOW  ('V', 24, struct v4l2_standard)
#define VIDIOC_ENUMSTD		_IOWR ('V', 25, struct v4l2_enumstd)
#define VIDIOC_ENUMINPUT	_IOWR ('V', 26, struct v4l2_input)
#define VIDIOC_G_CTRL		_IOWR ('V', 27, struct v4l2_control)
#define VIDIOC_S_CTRL		_IOW  ('V', 28, struct v4l2_control)
#define VIDIOC_G_TUNER		_IOWR ('V', 29, struct v4l2_tuner)
#define VIDIOC_S_TUNER		_IOW  ('V', 30, struct v4l2_tuner)
#define VIDIOC_G_FREQ		_IOR  ('V', 31, int)
#define VIDIOC_S_FREQ		_IOWR ('V', 32, int)
#define VIDIOC_G_AUDIO		_IOWR ('V', 33, struct v4l2_audio)
#define VIDIOC_S_AUDIO		_IOW  ('V', 34, struct v4l2_audio)
#define VIDIOC_QUERYCTRL	_IOWR ('V', 36, struct v4l2_queryctrl)
#define VIDIOC_QUERYMENU	_IOWR ('V', 37, struct v4l2_querymenu)
#define VIDIOC_G_INPUT		_IOR  ('V', 38, int)
#define VIDIOC_S_INPUT		_IOWR ('V', 39, int)
#define VIDIOC_ENUMCVT		_IOWR ('V', 40, struct v4l2_cvtdesc)
#define VIDIOC_G_OUTPUT		_IOR  ('V', 46, int)
#define VIDIOC_S_OUTPUT		_IOWR ('V', 47, int)
#define VIDIOC_ENUMOUTPUT	_IOWR ('V', 48, struct v4l2_output)
#define VIDIOC_G_AUDOUT		_IOWR ('V', 49, struct v4l2_audioout)
#define VIDIOC_S_AUDOUT		_IOW  ('V', 50, struct v4l2_audioout)
#define VIDIOC_ENUMFX		_IOWR ('V', 51, struct v4l2_fxdesc)
#define VIDIOC_G_EFFECT		_IOR  ('V', 52, int)
#define VIDIOC_S_EFFECT		_IOWR ('V', 53, int)
#define VIDIOC_G_MODULATOR	_IOWR ('V', 54, struct v4l2_modulator)
#define VIDIOC_S_MODULATOR	_IOW  ('V', 55, struct v4l2_modulator)
#define VIDIOC_G_FREQUENCY	_IOWR ('V', 56, struct v4l2_frequency)
#define VIDIOC_S_FREQUENCY	_IOW  ('V', 57, struct v4l2_frequency)

#define VIDIOC_ENUM_CAPFMT	VIDIOC_ENUM_PIXFMT
#define VIDIOC_ENUM_OUTFMT	VIDIOC_ENUM_PIXFMT
#define VIDIOC_ENUM_SRCFMT	VIDIOC_ENUM_PIXFMT
#define VIDIOC_ENUMFMT		VIDIOC_ENUM_PIXFMT

#define BASE_VIDIOC_PRIVATE	192		/* 192-255 are private */


#ifdef __KERNEL__
/*
 *
 *	V 4 L 2   D R I V E R   H E L P E R   A P I
 *
 *	Some commonly needed functions for drivers.
 */

extern void v4l2_version(int *major, int *minor);
extern int v4l2_major_number(void);
extern void v4l2_fill_ctrl_category(struct v4l2_queryctrl *qc);

/*  Memory management  */
extern unsigned long v4l2_vmalloc_to_bus(void *virt);
extern struct page *v4l2_vmalloc_to_page(void *virt);

/*  Simple queue management  */
struct v4l2_q_node
{
	struct v4l2_q_node 	*forw, *back;
};
struct v4l2_queue
{
	struct v4l2_q_node	*forw, *back;
	rwlock_t		qlock;
};
extern void  v4l2_q_init(struct v4l2_queue *q);
extern void  v4l2_q_add_head(struct v4l2_queue *q, struct v4l2_q_node *node);
extern void  v4l2_q_add_tail(struct v4l2_queue *q, struct v4l2_q_node *node);
extern void *v4l2_q_del_head(struct v4l2_queue *q);
extern void *v4l2_q_del_tail(struct v4l2_queue *q);
extern void *v4l2_q_peek_head(struct v4l2_queue *q);
extern void *v4l2_q_peek_tail(struct v4l2_queue *q);
extern void *v4l2_q_yank_node(struct v4l2_queue *q, struct v4l2_q_node *node);
extern int   v4l2_q_last(struct v4l2_queue *q);

/*  Math functions  */
extern u32 v4l2_math_div6432(u64 a, u32 d, u32 *r);

/*  Time functions  */
extern unsigned long v4l2_timestamp_divide(stamp_t t,
					   unsigned long p_100ns);
extern unsigned long v4l2_timestamp_correct(stamp_t *t,
					    unsigned long p_100ns);

/*  Master Clock functions  */
struct v4l2_clock
{
	void	(*gettime)(stamp_t *);
};
extern int  v4l2_masterclock_register(struct v4l2_clock *clock);
extern void v4l2_masterclock_unregister(struct v4l2_clock *clock);
extern void v4l2_masterclock_gettime(stamp_t *curr);

/*  Video standard functions  */
extern unsigned int v4l2_video_std_fps(struct v4l2_standard *vs);
extern unsigned long v4l2_video_std_tpf(struct v4l2_standard *vs);
extern int v4l2_video_std_confirm(struct v4l2_standard *vs);
extern int v4l2_video_std_construct(struct v4l2_standard *vs,
				    int id, __u32 transmission);

#define V4L2_STD_PAL		1	/* PAL B, G, H, I (...) */
#define V4L2_STD_PAL_M		5	/* (Brazil) */
#define V4L2_STD_PAL_N		6	/* (Argentina, Paraguay, Uruguay) */
#define V4L2_STD_PAL_60		10	/* PAL/NTSC hybrid */
#define V4L2_STD_NTSC		11	/* NTSC M (USA, ...) */
#define V4L2_STD_NTSC_N		12	/* (Barbados, Bolivia, Colombia, 
					   S. Korea) */
#define V4L2_STD_NTSC_44	15	/* PAL/NTSC hybrid */
#define V4L2_STD_SECAM		21	/* SECAM B, D, G, K, K1 (...) */
//#define V4L2_STD_SECAM_H	27	/* (Greece, Iran, Morocco) */ 
//#define V4L2_STD_SECAM_L	28	/* (France, Luxembourg, Monaco) */
//#define V4L2_STD_SECAM_M	29	/* (Jamaica) */

/*  Size of kernel ioctl arg buffer used in ioctl handler  */
#define V4L2_MAX_IOCTL_SIZE		256

/*  Compatibility layer interface  */
typedef int (*v4l2_ioctl_compat)(struct inode *inode, struct file *file,
				 int cmd, void *arg);
int v4l2_compat_register(v4l2_ioctl_compat hook);
void v4l2_compat_unregister(v4l2_ioctl_compat hook);

#endif /* __KERNEL__ */
#endif /* __LINUX_VIDEODEV2_H */
