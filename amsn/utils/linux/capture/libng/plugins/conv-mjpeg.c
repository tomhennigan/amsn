#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>
#include <jpeglib.h>

#include "grab-ng.h"

/* ---------------------------------------------------------------------- */

struct mjpeg_compress {
    struct jpeg_destination_mgr  mjpg_dest; /* must be first */
    struct jpeg_compress_struct  mjpg_cinfo;
    struct jpeg_error_mgr        mjpg_jerr;

    struct ng_video_fmt          fmt;

    JOCTET *mjpg_buffer;
    size_t  mjpg_bufsize;
    size_t  mjpg_bufused;
    int     mjpg_tables;

    /* yuv */
    unsigned char **mjpg_ptrs[3];
};

struct mjpeg_decompress {
    struct jpeg_source_mgr         mjpg_src; /* must be first */
    struct jpeg_decompress_struct  mjpg_cinfo;
    struct jpeg_error_mgr          mjpg_jerr;

    struct ng_video_fmt            fmt;
    struct ng_video_buf            *buf;

    /* yuv */
    unsigned char **mjpg_ptrs[3];
};

struct mjpeg_yuv_priv {
    int luma_h;
    int luma_v;
};

static void
swap_rgb24(char *mem, int n)
{
    char  c;
    char *p = mem;
    int   i = n;
    
    while (--i) {
	c = p[0]; p[0] = p[2]; p[2] = c;
	p += 3;
    }
}

/* ---------------------------------------------------------------------- */
/* I/O manager                                                            */

static void mjpg_dest_init(struct jpeg_compress_struct *cinfo)
{
    struct mjpeg_compress *h = (struct mjpeg_compress*)cinfo->dest;
    cinfo->dest->next_output_byte = h->mjpg_buffer;
    cinfo->dest->free_in_buffer   = h->mjpg_bufsize;
}

static boolean mjpg_dest_flush(struct jpeg_compress_struct *cinfo)
{
    fprintf(stderr,"mjpg: panic: output buffer too small\n");
    exit(1);
}

static void mjpg_dest_term(struct jpeg_compress_struct *cinfo)
{
    struct mjpeg_compress *h = (struct mjpeg_compress*)cinfo->dest;
    h->mjpg_bufused = h->mjpg_bufsize - cinfo->dest->free_in_buffer;
}

static void mjpg_src_init(struct jpeg_decompress_struct *cinfo)
{
    struct mjpeg_decompress *h  = (struct mjpeg_decompress*)cinfo->src;
    cinfo->src->next_input_byte = h->buf->data;
    cinfo->src->bytes_in_buffer = h->buf->size;
}

static int mjpg_src_fill(struct jpeg_decompress_struct *cinfo)
{
    fprintf(stderr,"mjpg: panic: no more input data\n");
    exit(1);
}

static void mjpg_src_skip(struct jpeg_decompress_struct *cinfo,
			  long num_bytes)
{
    cinfo->src->next_input_byte += num_bytes;
}

static void mjpg_src_term(struct jpeg_decompress_struct *cinfo)
{
    /* nothing */
}

/* ---------------------------------------------------------------------- */
/* compress                                                               */

static struct mjpeg_compress*
mjpg_init(struct ng_video_fmt *fmt)
{
    struct mjpeg_compress *h;
    
    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));
    
    h->mjpg_cinfo.err = jpeg_std_error(&h->mjpg_jerr);
    jpeg_create_compress(&h->mjpg_cinfo);

    h->mjpg_dest.init_destination    = mjpg_dest_init;
    h->mjpg_dest.empty_output_buffer = mjpg_dest_flush;
    h->mjpg_dest.term_destination    = mjpg_dest_term;
    h->mjpg_cinfo.dest               = &h->mjpg_dest;

    h->fmt = *fmt;
    h->mjpg_tables = TRUE;
    h->mjpg_cinfo.image_width  =  fmt->width;
    h->mjpg_cinfo.image_height =  fmt->height;

    h->mjpg_cinfo.image_width  &= ~(2*DCTSIZE-1);
    h->mjpg_cinfo.image_height &= ~(2*DCTSIZE-1);

    return h;
}

static void
mjpg_cleanup(void *handle)
{
    struct mjpeg_compress *h = handle;
    int i;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_cleanup\n");
    
    jpeg_destroy_compress(&h->mjpg_cinfo);
    for (i = 0; i < 3; i++)
	if (NULL != h->mjpg_ptrs[i])
	    free(h->mjpg_ptrs[i]);
    free(h);
}

/* ---------------------------------------------------------------------- */

static void*
mjpg_rgb_init(struct ng_video_fmt *out, void *priv)
{
    struct mjpeg_compress *h;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_rgb_init\n");

    h = mjpg_init(out);
    if (NULL == h)
	return NULL;

    h->mjpg_cinfo.input_components = 3;
    h->mjpg_cinfo.in_color_space = JCS_RGB;

    jpeg_set_defaults(&h->mjpg_cinfo);
    h->mjpg_cinfo.dct_method = JDCT_FASTEST;
    jpeg_set_quality(&h->mjpg_cinfo, ng_jpeg_quality, TRUE);
    jpeg_suppress_tables(&h->mjpg_cinfo, TRUE);

    return h;
}

static void
mjpg_rgb_compress(void *handle, struct ng_video_buf *out,
		  struct ng_video_buf *in)
{
    struct mjpeg_compress *h = handle;
    unsigned char *line;
    unsigned int i;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_rgb_compress\n");
    
    h->mjpg_buffer  = out->data;
    h->mjpg_bufsize = out->size;

    jpeg_start_compress(&h->mjpg_cinfo, h->mjpg_tables);
    for (i = 0, line = in->data; i < h->mjpg_cinfo.image_height;
	 i++, line += 3*h->mjpg_cinfo.image_width)
	jpeg_write_scanlines(&h->mjpg_cinfo, &line, 1);
    jpeg_finish_compress(&h->mjpg_cinfo);
    out->size = h->mjpg_bufused;
    out->info = in->info;
}

static void
mjpg_bgr_compress(void *handle, struct ng_video_buf *out,
		  struct ng_video_buf *in)
{
    swap_rgb24(in->data,in->fmt.width*in->fmt.height); /* FIXME */
    return mjpg_rgb_compress(handle,out,in);
}

/* ---------------------------------------------------------------------- */

static void*
mjpg_yuv_init(struct ng_video_fmt *out, void *priv)
{
    struct mjpeg_compress    *h;
    struct mjpeg_yuv_priv  *c = priv;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_yuv_init\n");

    h = mjpg_init(out);
    if (NULL == h)
	return NULL;

    h->mjpg_cinfo.input_components = 3;
    h->mjpg_cinfo.in_color_space = JCS_YCbCr; 

    jpeg_set_defaults(&h->mjpg_cinfo);
    h->mjpg_cinfo.dct_method = JDCT_FASTEST;
    jpeg_set_quality(&h->mjpg_cinfo, ng_jpeg_quality, TRUE);

    h->mjpg_cinfo.raw_data_in = TRUE;
    jpeg_set_colorspace(&h->mjpg_cinfo,JCS_YCbCr);

    h->mjpg_ptrs[0] = malloc(h->fmt.height*sizeof(char*));
    h->mjpg_ptrs[1] = malloc(h->fmt.height*sizeof(char*));
    h->mjpg_ptrs[2] = malloc(h->fmt.height*sizeof(char*));
    
    h->mjpg_cinfo.comp_info[0].h_samp_factor = c->luma_h;
    h->mjpg_cinfo.comp_info[0].v_samp_factor = c->luma_v;
    h->mjpg_cinfo.comp_info[1].h_samp_factor = 1;
    h->mjpg_cinfo.comp_info[1].v_samp_factor = 1;
    h->mjpg_cinfo.comp_info[2].h_samp_factor = 1;
    h->mjpg_cinfo.comp_info[2].v_samp_factor = 1;
    
    jpeg_suppress_tables(&h->mjpg_cinfo, TRUE);
    return h;
}

static void
mjpg_420_compress(struct mjpeg_compress *h)
{
    unsigned char **mjpg_run[3];
    unsigned int y;

    mjpg_run[0] = h->mjpg_ptrs[0];
    mjpg_run[1] = h->mjpg_ptrs[1];
    mjpg_run[2] = h->mjpg_ptrs[2];
    
    jpeg_start_compress(&h->mjpg_cinfo, h->mjpg_tables);
    for (y = 0; y < h->mjpg_cinfo.image_height; y += 2*DCTSIZE) {
	jpeg_write_raw_data(&h->mjpg_cinfo, mjpg_run,2*DCTSIZE);
	mjpg_run[0] += 2*DCTSIZE;
	mjpg_run[1] += DCTSIZE;
	mjpg_run[2] += DCTSIZE;
    }
    jpeg_finish_compress(&h->mjpg_cinfo);
}

static void
mjpg_422_compress(struct mjpeg_compress *h)
{
    unsigned char **mjpg_run[3];
    unsigned int y;

    mjpg_run[0] = h->mjpg_ptrs[0];
    mjpg_run[1] = h->mjpg_ptrs[1];
    mjpg_run[2] = h->mjpg_ptrs[2];
    
    h->mjpg_cinfo.write_JFIF_header = FALSE;
    jpeg_start_compress(&h->mjpg_cinfo, h->mjpg_tables);
    jpeg_write_marker(&h->mjpg_cinfo, JPEG_APP0, "AVI1\0\0\0\0", 8);
    for (y = 0; y < h->mjpg_cinfo.image_height; y += DCTSIZE) {
	jpeg_write_raw_data(&h->mjpg_cinfo, mjpg_run, DCTSIZE);
	mjpg_run[0] += DCTSIZE;
	mjpg_run[1] += DCTSIZE;
	mjpg_run[2] += DCTSIZE;
    }
    jpeg_finish_compress(&h->mjpg_cinfo);
}

/* ---------------------------------------------------------------------- */

static void
mjpg_422_420_compress(void *handle, struct ng_video_buf *out,
		      struct ng_video_buf *in)
{
    struct mjpeg_compress *h = handle;
    unsigned char *line;
    unsigned int i;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_422_420_compress\n");

    h->mjpg_buffer  = out->data;
    h->mjpg_bufsize = out->size;

    line = in->data;
    for (i = 0; i < h->mjpg_cinfo.image_height; i++, line += in->fmt.width)
	h->mjpg_ptrs[0][i] = line;

    line = in->data + in->fmt.width*in->fmt.height;
    for (i = 0; i < h->mjpg_cinfo.image_height; i+=2, line += in->fmt.width)
	h->mjpg_ptrs[1][i/2] = line;

    line = in->data + in->fmt.width*in->fmt.height*3/2;
    for (i = 0; i < h->mjpg_cinfo.image_height; i+=2, line += in->fmt.width)
	h->mjpg_ptrs[2][i/2] = line;

    mjpg_420_compress(h);
    out->size = h->mjpg_bufused;
    out->info = in->info;
}

static void
mjpg_420_420_compress(void *handle, struct ng_video_buf *out,
		      struct ng_video_buf *in)
{
    struct mjpeg_compress *h = handle;
    unsigned char *line;
    unsigned int i;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_420_420_compress\n");

    h->mjpg_buffer  = out->data;
    h->mjpg_bufsize = out->size;

    line = in->data;
    for (i = 0; i < h->mjpg_cinfo.image_height; i++, line += in->fmt.width)
	h->mjpg_ptrs[0][i] = line;

    line = in->data + in->fmt.width*in->fmt.height;
    for (i = 0; i < h->mjpg_cinfo.image_height; i+=2, line += in->fmt.width/2)
	h->mjpg_ptrs[1][i/2] = line;

    line = in->data + in->fmt.width*in->fmt.height*5/4;
    for (i = 0; i < h->mjpg_cinfo.image_height; i+=2, line += in->fmt.width/2)
	h->mjpg_ptrs[2][i/2] = line;

    mjpg_420_compress(h);
    out->size = h->mjpg_bufused;
    out->info = in->info;
}

/* ---------------------------------------------------------------------- */

static void
mjpg_422_422_compress(void *handle, struct ng_video_buf *out,
		      struct ng_video_buf *in)
{
    struct mjpeg_compress *h = handle;
    unsigned char *line;
    unsigned int i;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_422_422_compress\n");

    h->mjpg_buffer  = out->data;
    h->mjpg_bufsize = out->size;

    line = in->data;
    for (i = 0; i < h->mjpg_cinfo.image_height; i++, line += in->fmt.width)
	h->mjpg_ptrs[0][i] = line;

    line = in->data + in->fmt.width*in->fmt.height;
    for (i = 0; i < h->mjpg_cinfo.image_height; i++, line += in->fmt.width/2)
	h->mjpg_ptrs[1][i] = line;

    line = in->data + in->fmt.width*in->fmt.height*3/2;
    for (i = 0; i < h->mjpg_cinfo.image_height; i++, line += in->fmt.width/2)
	h->mjpg_ptrs[2][i] = line;

    mjpg_422_compress(h);
    out->size = h->mjpg_bufused;
    out->info = in->info;
}

/* ---------------------------------------------------------------------- */
/* decompress                                                             */

static void*
mjpg_de_init(struct ng_video_fmt *fmt, void *priv)
{
    struct mjpeg_decompress *h;
    
    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));
    h->fmt = *fmt;
    
    h->mjpg_cinfo.err = jpeg_std_error(&h->mjpg_jerr);
    jpeg_create_decompress(&h->mjpg_cinfo);

    h->mjpg_src.init_source         = mjpg_src_init;
    h->mjpg_src.fill_input_buffer   = mjpg_src_fill;
    h->mjpg_src.skip_input_data     = mjpg_src_skip;
    h->mjpg_src.resync_to_restart   = jpeg_resync_to_restart;
    h->mjpg_src.term_source         = mjpg_src_term;
    h->mjpg_cinfo.src               = &h->mjpg_src;

    switch (h->fmt.fmtid) {
    case VIDEO_YUV420P:
	h->mjpg_ptrs[0] = malloc(h->fmt.height*sizeof(char*));
	h->mjpg_ptrs[1] = malloc(h->fmt.height*sizeof(char*));
	h->mjpg_ptrs[2] = malloc(h->fmt.height*sizeof(char*));
	break;
    }
    return h;
}

static void
mjpg_rgb_decompress(void *handle, struct ng_video_buf *out,
		    struct ng_video_buf *in)
{
    struct mjpeg_decompress *h = handle;
    unsigned char *line;
    unsigned int i;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_rgb_decompress\n");

    h->buf = in;
    jpeg_read_header(&h->mjpg_cinfo,1);
    h->mjpg_cinfo.out_color_space = JCS_RGB;
    jpeg_start_decompress(&h->mjpg_cinfo);
    for (i = 0, line = out->data; i < out->fmt.height;
	 i++, line += out->fmt.bytesperline) {
	jpeg_read_scanlines(&h->mjpg_cinfo, &line, 1);
    }
    jpeg_finish_decompress(&h->mjpg_cinfo);
    out->info = in->info;
}

static void
mjpg_yuv420_decompress(void *handle, struct ng_video_buf *out,
		       struct ng_video_buf *in)
{
    struct mjpeg_decompress *h = handle;
    unsigned char **mjpg_run[3];
    unsigned char *line;
    unsigned int i,y;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_yuv_decompress\n");

    h->buf = in;
    jpeg_read_header(&h->mjpg_cinfo,1);
    h->mjpg_cinfo.raw_data_out = 1;

    if (ng_debug > 1)
	fprintf(stderr,"yuv: %dx%d  -  %d %d / %d %d / %d %d\n",
		h->mjpg_cinfo.image_width,
		h->mjpg_cinfo.image_height,
		h->mjpg_cinfo.comp_info[0].h_samp_factor,
		h->mjpg_cinfo.comp_info[0].v_samp_factor,
		h->mjpg_cinfo.comp_info[1].h_samp_factor,
		h->mjpg_cinfo.comp_info[1].v_samp_factor,
		h->mjpg_cinfo.comp_info[2].h_samp_factor,
		h->mjpg_cinfo.comp_info[2].v_samp_factor);
    
    jpeg_start_decompress(&h->mjpg_cinfo);
    mjpg_run[0] = h->mjpg_ptrs[0];
    mjpg_run[1] = h->mjpg_ptrs[1];
    mjpg_run[2] = h->mjpg_ptrs[2];

    line = out->data;
    for (i = 0; i < h->mjpg_cinfo.image_height; i++, line += out->fmt.width)
	h->mjpg_ptrs[0][i] = line;

    if (2 == h->mjpg_cinfo.comp_info[0].v_samp_factor) {
	/* file has 420 -- all fine */
	line = out->data + out->fmt.width*out->fmt.height;
	for (i = 0; i < out->fmt.height; i+=2, line += out->fmt.width/2)
	    h->mjpg_ptrs[1][i/2] = line;
	
	line = out->data + out->fmt.width*out->fmt.height*5/4;
	for (i = 0; i < out->fmt.height; i+=2, line += out->fmt.width/2)
	    h->mjpg_ptrs[2][i/2] = line;

	for (y = 0; y < out->fmt.height; y += 2*DCTSIZE) {
	    jpeg_read_raw_data(&h->mjpg_cinfo, mjpg_run,2*DCTSIZE);
	    mjpg_run[0] += 2*DCTSIZE;
	    mjpg_run[1] += DCTSIZE;
	    mjpg_run[2] += DCTSIZE;
	}

    } else {
	/* file has 422 -- drop lines */
	line = out->data + out->fmt.width*out->fmt.height;
	for (i = 0; i < out->fmt.height; i+=2, line += out->fmt.width/2) {
	    h->mjpg_ptrs[1][i+0] = line;
	    h->mjpg_ptrs[1][i+1] = line;
	}
	
	line = out->data + out->fmt.width*out->fmt.height*5/4;
	for (i = 0; i < out->fmt.height; i+=2, line += out->fmt.width/2) {
	    h->mjpg_ptrs[2][i+0] = line;
	    h->mjpg_ptrs[2][i+1] = line;
	}

	for (y = 0; y < h->mjpg_cinfo.image_height; y += DCTSIZE) {
	    jpeg_read_raw_data(&h->mjpg_cinfo, mjpg_run,DCTSIZE);
	    mjpg_run[0] += DCTSIZE;
	    mjpg_run[1] += DCTSIZE;
	    mjpg_run[2] += DCTSIZE;
	}
    }

    jpeg_finish_decompress(&h->mjpg_cinfo);
    out->info = in->info;
}

static void
mjpg_de_cleanup(void *handle)
{
    struct mjpeg_decompress *h = handle;

    if (ng_debug > 1)
	fprintf(stderr,"mjpg_de_cleanup\n");
    
    jpeg_destroy_decompress(&h->mjpg_cinfo);
    if (h->mjpg_ptrs[0])
	free(h->mjpg_ptrs[0]);
    if (h->mjpg_ptrs[1])
	free(h->mjpg_ptrs[1]);
    if (h->mjpg_ptrs[2])
	free(h->mjpg_ptrs[2]);
    free(h);
}

/* ---------------------------------------------------------------------- */
/* static data + register                                                 */

static struct mjpeg_yuv_priv priv_420 = {
    .luma_h = 2,
    .luma_v = 2,
};
static struct mjpeg_yuv_priv priv_422 = {
    .luma_h = 2,
    .luma_v = 1,
};

static struct ng_video_conv mjpg_list[] = {
    {
	/* --- compress --- */
	.init           = mjpg_yuv_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.frame        = mjpg_420_420_compress,
	.p.fini         = mjpg_cleanup,
	.fmtid_in	= VIDEO_YUV420P,
	.fmtid_out	= VIDEO_JPEG,
	.priv		= &priv_420,
    },{
	.init           = mjpg_yuv_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.frame        = mjpg_422_420_compress,
	.p.fini         = mjpg_cleanup,
	.fmtid_in	= VIDEO_YUV422P,
	.fmtid_out	= VIDEO_JPEG,
	.priv		= &priv_420,
    },{
	.init           = mjpg_rgb_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.frame        = mjpg_rgb_compress,
	.p.fini         = mjpg_cleanup,
	.fmtid_in	= VIDEO_RGB24,
	.fmtid_out	= VIDEO_JPEG,
    },{
	.init           = mjpg_rgb_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.frame        = mjpg_bgr_compress,
	.p.fini         = mjpg_cleanup,
	.fmtid_in	= VIDEO_BGR24,
	.fmtid_out	= VIDEO_JPEG,
    },{
	.init           = mjpg_yuv_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.frame        = mjpg_422_422_compress,
	.p.fini         = mjpg_cleanup,
	.fmtid_in	= VIDEO_YUV422P,
	.fmtid_out	= VIDEO_MJPEG,
	.priv		= &priv_422,
    },{
	/* --- uncompress --- */
	.init           = mjpg_de_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.frame        = mjpg_rgb_decompress,
	.p.fini         = mjpg_de_cleanup,
	.fmtid_in	= VIDEO_MJPEG,
	.fmtid_out	= VIDEO_RGB24,
    },{
	.init           = mjpg_de_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.frame        = mjpg_rgb_decompress,
	.p.fini         = mjpg_de_cleanup,
	.fmtid_in	= VIDEO_JPEG,
	.fmtid_out	= VIDEO_RGB24,
    },{
	.init           = mjpg_de_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.frame        = mjpg_yuv420_decompress,
	.p.fini         = mjpg_de_cleanup,
	.fmtid_in	= VIDEO_MJPEG,
	.fmtid_out	= VIDEO_YUV420P,
    },{
	.init           = mjpg_de_init,
	.p.mode         = NG_MODE_TRIVIAL,
	.p.frame        = mjpg_yuv420_decompress,
	.p.fini         = mjpg_de_cleanup,
	.fmtid_in	= VIDEO_JPEG,
	.fmtid_out	= VIDEO_YUV420P,
    }
};
static const int nconv = sizeof(mjpg_list)/sizeof(struct ng_video_conv);

static void __init plugin_init(void)
{
    ng_conv_register(NG_PLUGIN_MAGIC,__FILE__,mjpg_list,nconv);
}
