#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <dlfcn.h>
#include <inttypes.h>

#include "grab-ng.h"

/* ---------------------------------------------------------------------- */
/* stuff we need from lame.h                                              */

struct lame_global_struct;
typedef struct lame_global_struct lame_global_flags;

static lame_global_flags* (*lame_init)(void);
static int (*lame_close)(lame_global_flags *);

static int (*lame_set_in_samplerate)(lame_global_flags *, int);
static int (*lame_set_num_channels)(lame_global_flags *, int);
static int (*lame_set_quality)(lame_global_flags *, int);
static int (*lame_init_params)(lame_global_flags * const );

/*
 * num_samples = number of samples in the L (or R)
 * channel, not the total number of samples in pcm[]  
 * returns # of output bytes
 * mp3buffer_size_max = 1.25*num_samples + 7200
 */
static int (*lame_encode_buffer_interleaved)(
    lame_global_flags*  gfp,           /* global context handlei          */
    short int           pcm[],         /* PCM data for left and right
					  channel, interleaved            */
    int                 num_samples,   /* number of samples per channel,
					  _not_ number of samples in
					  pcm[]                           */
    unsigned char*      mp3buf,        /* pointer to encoded MP3 stream   */
    int                 mp3buf_size ); /* number of valid octets in this
					  stream                          */
static int (*lame_encode_flush)(
    lame_global_flags *  gfp,    /* global context handle                 */
    unsigned char*       mp3buf, /* pointer to encoded MP3 stream         */
    int                  size);  /* number of valid octets in this stream */

/* ---------------------------------------------------------------------- */
/* simple, portable dynamic linking (call stuff indirectly using          */
/* function pointers)                                                     */

#define SYM(symbol) { .func = (void*)(&symbol), .name = #symbol }
static struct {
    void   **func;
    char   *name;
} symtab[] = {
    SYM(lame_init),
    SYM(lame_close),
    SYM(lame_set_in_samplerate),
    SYM(lame_set_num_channels),
    SYM(lame_set_quality),
    SYM(lame_init_params),
    SYM(lame_encode_buffer_interleaved),
    SYM(lame_encode_flush),
};

static int link_lame(void)
{
    void *handle;
    void *symbol;
    unsigned int i;

    handle = dlopen("libmp3lame.so.0",RTLD_NOW);
    if (NULL == handle)
	return -1;
    for (i = 0; i < sizeof(symtab)/sizeof(symtab[0]); i++) {
	symbol = dlsym(handle,symtab[i].name);
	if (NULL == symbol) {
	    fprintf(stderr,"dlsym(mp3lame,%s): %s\n",
		    symtab[i].name, dlerror());
	    dlclose(handle);
	    return -1;
	}
	*(symtab[i].func) = symbol;
    }
    return 0;
}

/* ---------------------------------------------------------------------- */
/* mp3 encoding using lame                                                */

struct mp3_enc_state {
    lame_global_flags *gf;
    int first;
};

static void* mp3_enc_init(void *priv)
{
    struct mp3_enc_state *h;

    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));
    h->gf    = lame_init();
    h->first = 1;
    return h;
}

static struct ng_audio_buf*
mp3_enc_data(void *handle, struct ng_audio_buf *in)
{
    static struct ng_audio_fmt fmt = {
	.fmtid = AUDIO_MP3,
	.rate  = 0,
    };
    struct mp3_enc_state *h = handle;
    struct ng_audio_buf *out;
    int samples, size;

    if (h->first) {
	lame_set_in_samplerate(h->gf, in->fmt.rate);
	lame_set_num_channels(h->gf, ng_afmt_to_channels[in->fmt.fmtid]);
	lame_set_quality(h->gf, 5 /* FIXME */);
	lame_init_params(h->gf);
	h->first = 0;
    }
    samples = in->size >> 2;
    size = 7200 + samples * 5 / 4; /* worst case */
    out = ng_malloc_audio_buf(&fmt, size);

    out->size = lame_encode_buffer_interleaved
	(h->gf, (short int*) in->data, samples, out->data, size);
    out->info = in->info;
    free(in);
    return out;
}

static void mp3_enc_fini(void *handle)
{
    struct mp3_enc_state *h = handle;

    lame_close(h->gf);
    free(h);
}

/* ---------------------------------------------------------------------- */

static struct ng_audio_conv enc_list[] = {
    {
	.init           = mp3_enc_init,
	.data           = mp3_enc_data,
	.fini           = mp3_enc_fini,
	.fmtid_in	= AUDIO_S16_NATIVE_STEREO,
	.fmtid_out	= AUDIO_MP3,
	.priv		= NULL,
    }
};
static const int nenc = sizeof(enc_list)/sizeof(enc_list[0]);


/* ---------------------------------------------------------------------- */
/* mp3 decoding using mad                                                 */

#ifdef HAVE_LIBMAD
#include <mad.h>

struct mp3_dec_state {
    struct mad_stream  stream;
    struct mad_frame   frame;
    struct mad_synth   synth;

    /* input */
    unsigned char      *buf;
    unsigned int       bufused;
    unsigned int       bufsize;

    /* output */
    int                osize;
};

static inline int16_t scale(mad_fixed_t sample)
{
    /* round */
    sample += (1L << (MAD_F_FRACBITS - 16));
    
    /* clip */
    if (sample >= MAD_F_ONE)
	sample = MAD_F_ONE - 1;
    else if (sample < -MAD_F_ONE)
	sample = -MAD_F_ONE;
    
    /* quantize */
    return sample >> (MAD_F_FRACBITS + 1 - 16);
}

static void* mp3_dec_init(void *priv)
{
    struct mp3_dec_state *h;

    h = malloc(sizeof(*h));
    if (NULL == h)
	return NULL;
    memset(h,0,sizeof(*h));

    mad_stream_init(&h->stream);
    mad_frame_init(&h->frame);
    mad_synth_init(&h->synth);

    //mad_stream_options(stream, decoder->options);

    return h;
}

static struct ng_audio_buf*
mp3_dec_data(void *handle, struct ng_audio_buf *in)
{
    struct mp3_dec_state *h = handle;
    unsigned int         drop;

    struct ng_audio_fmt  fmt;
    struct ng_audio_buf  *out = NULL, *tmp;
    struct mad_pcm       *pcm;
    int16_t              *dest;
    int i;

    /* input buffer */
    if (h->stream.next_frame) {
        drop = h->stream.next_frame - h->buf;
	memmove(h->buf, h->stream.next_frame, h->bufused - drop);
	h->bufused -= drop;
    }
    if (h->bufsize < h->bufused + 2*in->size) {
	h->bufsize = h->bufused + 2*in->size;
	h->buf = realloc(h->buf,h->bufsize);
    }
    memcpy(h->buf + h->bufused, in->data, in->size);
    h->bufused += in->size;
    mad_stream_buffer(&h->stream, h->buf, h->bufused);

    for (;;) {
	/* decode data */
	if (-1 == mad_frame_decode(&h->frame, &h->stream)) {
	    switch (h->stream.error) {
	    case MAD_ERROR_BUFLEN:
		if (NULL == out) {
		    /* Hmm, need dummy buffer ... */
		    out = ng_malloc_audio_buf(&fmt, h->osize);
		    out->size = 0;
		}
		out->info = in->info;
		ng_free_audio_buf(in);
		return out;
	    default:
		if (ng_log_bad_stream)
		    fprintf(stderr,"mad: %s: %s [broken=%d]\n",
			    MAD_RECOVERABLE(h->stream.error)
			    ? "warning" : "error",
			    mad_stream_errorstr(&h->stream),
			    in->info.broken);
		if (!MAD_RECOVERABLE(h->stream.error)) {
		    /* fatal error */
		    ng_free_audio_buf(in);
		    if (out)
			ng_free_audio_buf(out);
		    return NULL;
		}
		break;
	    }
	}
	mad_synth_frame(&h->synth, &h->frame);

	/* output buffer */
	pcm = &h->synth.pcm;
	fmt.fmtid = AUDIO_S16_NATIVE_STEREO;
	fmt.rate  = pcm->samplerate;

	if (NULL == out) {
	    if (h->osize < pcm->length * 4)
		h->osize = pcm->length * 4;
	    out = ng_malloc_audio_buf(&fmt, h->osize);
	    out->size = 0;
	    out->info = in->info;
	}
	if (h->osize < out->size + pcm->length * 4) {
	    h->osize = out->size + pcm->length * 4;
	    tmp = ng_malloc_audio_buf(&fmt, h->osize);
	    memcpy(tmp->data,out->data,out->size);
	    tmp->size = out->size;
	    tmp->info = in->info;
	    ng_free_audio_buf(out);
	    out = tmp;
	}
	dest = (int16_t*)(out->data + out->size);
	
	if (2 == pcm->channels) {
	    for (i = 0; i < pcm->length; i++, dest += 2) {
		dest[0] = scale(pcm->samples[0][i]);
		dest[1] = scale(pcm->samples[1][i]);
	    }
	} else {
	    for (i = 0; i < pcm->length; i++, dest += 2) {
		dest[0] = scale(pcm->samples[0][i]);
		dest[1] = scale(pcm->samples[0][i]);
	    }
	}
	out->size += pcm->length * 4;
    }
}

static void mp3_dec_fini(void *handle)
{
    struct mp3_dec_state *h = handle;

    mad_synth_finish(&h->synth);
    mad_frame_finish(&h->frame);
    mad_stream_finish(&h->stream);
    free(h);
}

static struct ng_audio_conv dec_list[] = {
    {
	.init           = mp3_dec_init,
	.data           = mp3_dec_data,
	.fini           = mp3_dec_fini,
	.fmtid_in	= AUDIO_MP3,
	.fmtid_out	= AUDIO_S16_NATIVE_STEREO,
	.priv		= NULL,
    }
};
static const int ndec = sizeof(dec_list)/sizeof(dec_list[0]);
#endif


/* ---------------------------------------------------------------------- */
/* byteswapping filter                                                    */

static int dummy_handle;

static int swap_fmtid[AUDIO_FMT_COUNT] = {
    [ AUDIO_S16_LE_MONO ]   = AUDIO_S16_BE_MONO,
    [ AUDIO_S16_LE_STEREO ] = AUDIO_S16_BE_STEREO,
    [ AUDIO_S16_BE_MONO ]   = AUDIO_S16_LE_MONO,
    [ AUDIO_S16_BE_STEREO ] = AUDIO_S16_LE_STEREO,
};

static void* swap_init(void *priv)
{
    if (ng_debug)
	fprintf(stderr,"audio: byteswapping\n");
    return &dummy_handle;
}

static void swap_fini(void *handle)
{
}

static struct ng_audio_buf*
swap_buffer(void *handle, struct ng_audio_buf *in)
{
    struct ng_audio_fmt fmt;
    struct ng_audio_buf *out;
    uint16_t *src,*dst;
    int i,samples;

    fmt = in->fmt;
    fmt.fmtid = swap_fmtid[in->fmt.fmtid];
    BUG_ON(AUDIO_NONE == fmt.fmtid, "non-swappable audio format");
    out = ng_malloc_audio_buf(&fmt, in->size);

    src = (uint16_t*)in->data;
    dst = (uint16_t*)out->data;
    samples = in->size >> 1;
    for (i = 0; i < samples; i++)
	dst[i] = ((src[i] >> 8) & 0xff) | ((src[i] << 8) & 0xff00);

    out->size = in->size;
    out->info = in->info;
    free(in);
    return out;
}

static struct ng_audio_conv swap_list[] = {
    {
	.init           = swap_init,
	.data           = swap_buffer,
	.fini           = swap_fini,
	.fmtid_in	= AUDIO_S16_BE_MONO,
	.fmtid_out	= AUDIO_S16_LE_MONO,
    },{
	.init           = swap_init,
	.data           = swap_buffer,
	.fini           = swap_fini,
	.fmtid_in	= AUDIO_S16_LE_MONO,
	.fmtid_out	= AUDIO_S16_BE_MONO,
    },{
	.init           = swap_init,
	.data           = swap_buffer,
	.fini           = swap_fini,
	.fmtid_in	= AUDIO_S16_BE_STEREO,
	.fmtid_out	= AUDIO_S16_LE_STEREO,
    },{
	.init           = swap_init,
	.data           = swap_buffer,
	.fini           = swap_fini,
	.fmtid_in	= AUDIO_S16_LE_STEREO,
	.fmtid_out	= AUDIO_S16_BE_STEREO,
    }
};
static const int nswap = sizeof(swap_list)/sizeof(swap_list[0]);

/* ---------------------------------------------------------------------- */
/* init stuff                                                             */

static void __init plugin_init(void)
{
    ng_aconv_register(NG_PLUGIN_MAGIC,__FILE__,swap_list,nswap);
#ifdef HAVE_LIBMAD
    ng_aconv_register(NG_PLUGIN_MAGIC,__FILE__,dec_list,ndec);
#endif
    if (0 == link_lame())
	ng_aconv_register(NG_PLUGIN_MAGIC,__FILE__,enc_list,nenc);
}
