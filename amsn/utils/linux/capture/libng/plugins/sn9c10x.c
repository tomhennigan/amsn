/*
 * SN9C10x formats
 * (C) 2007 Gabriel Gambetta <ggambett@adinet.com.uy>
 *
 * A libng plugin for the SN9C102 driver formats.
 *
 *
 *
 * BA81 decoding taken from :
 *
 * Sonix SN9C101 based webcam basic I/F routines
 * Copyright (C) 2004 Takafumi Mizuno <taka-qce@ls-a.jp>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *
 *
 * S910 decoding taken from sn-webcam (http://sn-webcam.sourceforge.net)
 *
 */

#define NG_PRIVATE
#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/time.h>
#include <sys/types.h>

#include "grab-ng.h"

/* ========================================================================	*/
/*  BA81 decoder															*/
/* ========================================================================	*/
static void* bayer_init (struct ng_video_fmt* out, void* priv)
{
	return 0;
}


static void bayer_decompress (void* handle, struct ng_video_buf* out, struct ng_video_buf* in)
{
	long int i;
	unsigned char* rawpt;
	unsigned char* scanpt;
	long int size;
	int WIDTH, HEIGHT;

	WIDTH = in->fmt.width;
	HEIGHT = in->fmt.height;

	rawpt = in->data;
	scanpt = out->data;
	size = WIDTH * HEIGHT;

	for (i = 0; i < size; i++)
	{
		if ((i / WIDTH) % 2 == 0)
		{
			if ((i % 2) == 0)
			{
				/* B */
				if ((i > WIDTH) && ((i % WIDTH) > 0))
				{
					*scanpt++ = (*(rawpt - WIDTH - 1) + *(rawpt - WIDTH + 1) + *(rawpt + WIDTH - 1) + *(rawpt + WIDTH + 1)) / 4;	/* R */
					*scanpt++ = (*(rawpt - 1) + *(rawpt + 1) + *(rawpt + WIDTH) + *(rawpt - WIDTH)) / 4;	/* G */
					*scanpt++ = *rawpt;	/* B */
				}
				else
				{
					/* first line or left column */
					*scanpt++ = *(rawpt + WIDTH + 1);	/* R */
					*scanpt++ = (*(rawpt + 1) + *(rawpt + WIDTH)) / 2;	/* G */
					*scanpt++ = *rawpt;	/* B */
				}
			}
			else
			{
				/* (B)G */
				if ((i > WIDTH) && ((i % WIDTH) < (WIDTH - 1)))
				{
					*scanpt++ = (*(rawpt + WIDTH) + *(rawpt - WIDTH)) / 2;	/* R */
					*scanpt++ = *rawpt;	/* G */
					*scanpt++ = (*(rawpt - 1) + *(rawpt + 1)) / 2;	/* B */
				}
				else
				{
					/* first line or right column */
					*scanpt++ = *(rawpt + WIDTH);	/* R */
					*scanpt++ = *rawpt;	/* G */
					*scanpt++ = *(rawpt - 1);	/* B */
				}
			}
		}
		else
		{
			if ((i % 2) == 0)
			{
				/* G(R) */
				if ((i < (WIDTH * (HEIGHT - 1))) && ((i % WIDTH) > 0))
				{
					*scanpt++ = (*(rawpt - 1) + *(rawpt + 1)) / 2;	/* R */
					*scanpt++ = *rawpt;	/* G */
					*scanpt++ = (*(rawpt + WIDTH) + *(rawpt - WIDTH)) / 2;	/* B */
				}
				else
				{
					/* bottom line or left column */
					*scanpt++ = *(rawpt + 1);	/* R */
					*scanpt++ = *rawpt;	/* G */
					*scanpt++ = *(rawpt - WIDTH);	/* B */
				}
			}
			else
			{
				/* R */
				if (i < (WIDTH * (HEIGHT - 1)) && ((i % WIDTH) < (WIDTH - 1)))
				{
					*scanpt++ = *rawpt;	/* R */
					*scanpt++ = (*(rawpt - 1) + *(rawpt + 1) + *(rawpt - WIDTH) + *(rawpt + WIDTH)) / 4;	/* G */
					*scanpt++ = (*(rawpt - WIDTH - 1) + *(rawpt - WIDTH + 1) + *(rawpt + WIDTH - 1) + *(rawpt + WIDTH + 1)) / 4;	/* B */
				}
				else
				{
					/* bottom line or right column */
					*scanpt++ = *rawpt;	/* R */
					*scanpt++ = (*(rawpt - 1) + *(rawpt - WIDTH)) / 2;	/* G */
					*scanpt++ = *(rawpt - WIDTH - 1);	/* B */
				}
			}
		}
		rawpt++;
	}
}


static void bayer_cleanup (void* handle)
{

}


/* ========================================================================	*/
/*  SN10 decoder															*/
/* ========================================================================	*/
#define CLAMP(x)	((x)<0?0:((x)>255)?255:(x))

typedef struct
{
	int is_abs;
	int len;
	int val;
	int unk;
} code_table_t;


/* local storage */
static code_table_t table[256];
static int init_done = 0;

/* global variable */
int sonix_unknown = 0;

/*
	sonix_decompress_init
	=====================
		pre-calculates a locally stored table for efficient huffman-decoding.

	Each entry at index x in the table represents the codeword
	present at the MSB of byte x.

*/
static void sonix_decompress_init (void)
{
	int i;
	int is_abs, val, len, unk;

	for (i = 0; i < 256; i++)
	{
		is_abs = 0;
		val = 0;
		len = 0;
		unk = 0;
		if ((i & 0x80) == 0)
		{
			/* code 0 */
			val = 0;
			len = 1;
		}
		else if ((i & 0xE0) == 0x80)
		{
			/* code 100 */
			val = +4;
			len = 3;
		}
		else if ((i & 0xE0) == 0xA0)
		{
			/* code 101 */
			val = -4;
			len = 3;
		}
		else if ((i & 0xF0) == 0xD0)
		{
			/* code 1101 */
			val = +11;
			len = 4;
		}
		else if ((i & 0xF0) == 0xF0)
		{
			/* code 1111 */
			val = -11;
			len = 4;
		}
		else if ((i & 0xF8) == 0xC8)
		{
			/* code 11001 */
			val = +20;
			len = 5;
		}
		else if ((i & 0xFC) == 0xC0)
		{
			/* code 110000 */
			val = -20;
			len = 6;
		}
		else if ((i & 0xFC) == 0xC4)
		{
			/* code 110001xx: unknown */
			val = 0;
			len = 8;
			unk = 1;
		}
		else if ((i & 0xF0) == 0xE0)
		{
			/* code 1110xxxx */
			is_abs = 1;
			val = (i & 0x0F) << 4;
			len = 8;
		}
		
		table[i].is_abs = is_abs;
		table[i].val = val;
		table[i].len = len;
		table[i].unk = unk;
	}

	sonix_unknown = 0;
	init_done = 1;
}


struct S910Context
{
	unsigned char* sTempBuffer;
	void* pBayerContext;
};


static void* s910_init (struct ng_video_fmt* out, void* priv)
{
	struct S910Context* pContext;
	
	if (!init_done)
		sonix_decompress_init();
	
	pContext = (struct S910Context*)malloc(sizeof(struct S910Context));
	
	pContext->sTempBuffer = (unsigned char*)malloc(3*out->width*out->height);
	pContext->pBayerContext = bayer_init(out, priv);
	
	return pContext;
}


static void s910_decompress (void* handle, struct ng_video_buf* out, struct ng_video_buf* in)
{
	int row, col;
	int val;
	int bitpos;
	unsigned char code;
	unsigned char* addr;
	
	int width;
	int height;
	unsigned char* inp;
	unsigned char* outp;
	unsigned char* inp_save;
	
	struct S910Context* pContext;

	if (!init_done)
		return;
		
	pContext = (struct S910Context*)handle;
	
	width = out->fmt.width;
	height = out->fmt.height;
	
	inp = in->data;
	outp = pContext->sTempBuffer;
	
	inp_save = in->data;
			
	bitpos = 0;
	for (row = 0; row < height; row++)
	{
		col = 0;

		/* first two pixels in first two rows are stored as raw 8-bit */
		if (row < 2)
		{
			addr = inp + (bitpos >> 3);
			code = (addr[0] << (bitpos & 7)) | (addr[1] >> (8 - (bitpos & 7)));
			bitpos += 8;
			*outp++ = code;

			addr = inp + (bitpos >> 3);
			code = (addr[0] << (bitpos & 7)) | (addr[1] >> (8 - (bitpos & 7)));
			bitpos += 8;
			*outp++ = code;

			col += 2;
		}

		while (col < width)
		{
			/* get bitcode from bitstream */
			addr = inp + (bitpos >> 3);
			code = (addr[0] << (bitpos & 7)) | (addr[1] >> (8 - (bitpos & 7)));

			/* update bit position */
			bitpos += table[code].len;

			/* update code statistics */
			sonix_unknown += table[code].unk;

			/* calculate pixel value */
			val = table[code].val;
			if (!table[code].is_abs)
			{
				/* value is relative to top and left pixel */
				if (col < 2)
				{
					/* left column: relative to top pixel */
					val += outp[-2 * width];
				}
				else if (row < 2)
				{
					/* top row: relative to left pixel */
					val += outp[-2];
				}
				else
				{
					/* main area: average of left pixel and top pixel */
					val += (outp[-2] + outp[-2 * width]) / 2;
				}
			}

			/* store pixel */
			*outp++ = CLAMP(val);
			col++;
		}
	}
	
	in->data = pContext->sTempBuffer;	
	bayer_decompress(NULL, out, in);
	in->data = inp_save;
}


static void s910_cleanup (void* handle)
{
	struct S910Context* pContext;

	pContext = (struct S910Context*)handle;
	bayer_cleanup(pContext->pBayerContext);	

	free(pContext->sTempBuffer);
	free(pContext);
}


/* ========================================================================	*/
/*  Init stuff																*/
/* ========================================================================	*/
static struct ng_video_conv conv_list[] = 
{
	{
		.init		= s910_init,
		.p.frame	= s910_decompress,
		.p.fini		= s910_cleanup,
		.p.mode		= NG_MODE_TRIVIAL,

		.fmtid_in	= VIDEO_S910,
		.fmtid_out	= VIDEO_RGB24,
	},
	
	{
		.init		= bayer_init,
		.p.frame	= bayer_decompress,
		.p.fini		= bayer_cleanup,
		.p.mode		= NG_MODE_TRIVIAL,

		.fmtid_in	= VIDEO_BAYER,
		.fmtid_out	= VIDEO_RGB24,
	},

};

static const int nconv = sizeof(conv_list)/sizeof(struct ng_video_conv);

/* ------------------------------------------------------------------- */

static void __init ng_plugin_init(void)
{
    ng_conv_register(NG_PLUGIN_MAGIC, __FILE__, conv_list, nconv);
}
