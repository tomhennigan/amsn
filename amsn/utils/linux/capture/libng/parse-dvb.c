/*
 * parse various TV stuff out of DVB TS streams.
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <iconv.h>

#include "grab-ng.h"
#include "parse-mpeg.h"

/* ----------------------------------------------------------------------- */

static unsigned int unbcd(unsigned int bcd)
{
    unsigned int factor = 1;
    unsigned int ret = 0;
    unsigned int digit;

    while (bcd) {
	digit   = bcd & 0x0f;
	ret    += digit * factor;
	bcd    /= 16;
	factor *= 10;
    }
    return ret;
}

static int iconv_string(char *from, char *to,
			char *src, size_t len,
			char *dst, size_t max)
{
    size_t ilen = (-1 != len) ? len : strlen(src);
    size_t olen = max-1;
    iconv_t ic;

    ic = iconv_open(to,from);
    if (NULL == ic)
	return 0;

    while (ilen > 0) {
	if (-1 == iconv(ic,&src,&ilen,&dst,&olen)) {
	    /* skip + quote broken byte unless we are out of space */
	    if (E2BIG == errno)
		break;
	    if (olen < 4)
		break;
	    sprintf(dst,"\\x%02x",(int)(unsigned char)src[0]);
	    src  += 1;
	    dst  += 4;
	    ilen -= 1;
	    olen -= 4;
	}
    }
    dst[0] = 0;
    iconv_close(ic);
    return max-1 - olen;
}

static int handle_control_8(unsigned char *src,  int slen,
			    unsigned char *dest, int dlen)
{
    int s,d;

    for (s = 0, d = 0; s < slen && d < dlen;) {
	if (src[s] >= 0x80  &&  src[s] <= 0x9f) {
	    switch (src[s]) {
	    case 0x86: /* <em>  */
	    case 0x87: /* </em> */
		s++;
		break;
	    case 0x1a: /* ^Z    */
		dest[d++] = ' ';
		s++;
		break;
	    case 0x8a: /* <br>  */
		dest[d++] = '\n';
		s++;
		break;
	    default:
		s++;
	    }
	} else {
	    dest[d++] = src[s++];
	}
    }
    return d;
}

void mpeg_parse_psi_string(unsigned char *src, int slen,
			   unsigned char *dest, int dlen)
{
    unsigned char *tmp;
    int tlen,ch = 0;

    if (src[0] < 0x20) {
	ch = src[0];
	src++;
	slen--;
    }

    memset(dest,0,dlen);
    if (ch < 0x10) {
	/* 8bit charset */
	tmp = malloc(slen);
	tlen = handle_control_8(src, slen, tmp, slen);
	iconv_string(psi_charset[ch], "UTF-8", tmp, tlen, dest, dlen);
	free(tmp);
    } else {
	/* 16bit charset */
	iconv_string(psi_charset[ch], "UTF-8", src, slen, dest, dlen);
    }
}

static void parse_nit_desc_1(unsigned char *desc, int dlen,
			     char *dest, int max)
{
    int i,t,l;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
	t = desc[i];
	l = desc[i+1];

	switch (t) {
	case 0x40:
	    mpeg_parse_psi_string(desc+i+2,l,dest,max);
	    break;
	}
    }
}

static void parse_nit_desc_2(unsigned char *desc, int dlen,
			     struct psi_stream *stream)
{
    static char *bw[4] = {
	[ 0 ] = "8",
	[ 1 ] = "7",
	[ 2 ] = "6",
    };
    static char *co_t[4] = {
	[ 0 ] = "0",
	[ 1 ] = "16",
	[ 2 ] = "64",
    };
    static char *co_c[16] = {
	[ 0 ] = "0",
	[ 1 ] = "16",
	[ 2 ] = "32",
	[ 3 ] = "64",
	[ 4 ] = "128",
	[ 5 ] = "256",
    };
    static char *hi[4] = {
	[ 0 ] = "0",
	[ 1 ] = "1",
	[ 2 ] = "2",
	[ 3 ] = "4",
    };
    static char *ra_t[8] = {
	[ 0 ] = "12",
	[ 1 ] = "23",
	[ 2 ] = "34",
	[ 3 ] = "56",
	[ 4 ] = "78",
    };
    static char *ra_sc[8] = {
	[ 1 ] = "12",
	[ 2 ] = "23",
	[ 3 ] = "34",
	[ 4 ] = "56",
	[ 5 ] = "78",
    };
    static char *gu[4] = {
	[ 0 ] = "32",
	[ 1 ] = "16",
	[ 2 ] = "8",
	[ 3 ] = "4",
    };
    static char *tr[2] = {
	[ 0 ] = "2",
	[ 1 ] = "8",
    };
    static char *po[4] = {
	[ 0 ] = "H",
	[ 1 ] = "V",
	[ 2 ] = "L",  // circular left
	[ 3 ] = "R",  // circular right
    };
    unsigned int freq,rate,fec;
    int i,t,l;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
	t = desc[i];
	l = desc[i+1];

	switch (t) {
	case 0x43: /* dvb-s */
	    freq = mpeg_getbits(desc+i+2,  0, 32);
	    rate = mpeg_getbits(desc+i+2, 56, 28);
	    fec  = mpeg_getbits(desc+i+2, 85,  3);
	    stream->frequency     = unbcd(freq)    * 10;
	    stream->symbol_rate   = unbcd(rate*16) * 10;
	    stream->fec_inner     = ra_sc[fec];
	    stream->polarization  = po[   mpeg_getbits(desc+i+2, 49, 2) ];
	    break;
	case 0x44: /* dvb-c */
	    freq = mpeg_getbits(desc+i+2,  0, 32);
	    rate = mpeg_getbits(desc+i+2, 56, 28);
	    fec  = mpeg_getbits(desc+i+2, 85,  3);
	    stream->frequency     = unbcd(freq)    * 100;
	    stream->symbol_rate   = unbcd(rate*16) * 10;
	    stream->fec_inner     = ra_sc[fec];
	    stream->constellation = co_c[ mpeg_getbits(desc+i+2, 52, 4) ];
	    break;
	case 0x5a: /* dvb-t */
	    stream->frequency     = mpeg_getbits(desc+i+2,  0, 32) * 10;
	    stream->bandwidth     = bw[   mpeg_getbits(desc+i+2, 33, 2) ];
	    stream->constellation = co_t[ mpeg_getbits(desc+i+2, 40, 2) ];
	    stream->hierarchy     = hi[   mpeg_getbits(desc+i+2, 43, 2) ];
	    stream->code_rate_hp  = ra_t[ mpeg_getbits(desc+i+2, 45, 3) ];
	    stream->code_rate_lp  = ra_t[ mpeg_getbits(desc+i+2, 48, 3) ];
	    stream->guard         = gu[   mpeg_getbits(desc+i+2, 51, 2) ];
	    stream->transmission  = tr[   mpeg_getbits(desc+i+2, 54, 1) ];
	    break;
	}
    }
    return;
}

static void parse_sdt_desc(unsigned char *desc, int dlen,
			   struct psi_program *pr)
{
    int i,t,l;
    char *name,*net;

    for (i = 0; i < dlen; i += desc[i+1] +2) {
	t = desc[i];
	l = desc[i+1];

	switch (t) {
	case 0x48:
	    pr->type = desc[i+2];
	    pr->updated = 1;
	    net = desc + i+3;
	    name = net + net[0] + 1;
	    mpeg_parse_psi_string(net+1,  net[0],  pr->net,  sizeof(pr->net));
	    mpeg_parse_psi_string(name+1, name[0], pr->name, sizeof(pr->name));
	    break;
	}
    }
}

/* ----------------------------------------------------------------------- */

int mpeg_parse_psi_sdt(struct psi_info *info, unsigned char *data, int verbose)
{
    static const char *running[] = {
	[ 0       ] = "undefined",
	[ 1       ] = "not running",
	[ 2       ] = "starts soon",
	[ 3       ] = "pausing",
	[ 4       ] = "running",
	[ 5 ... 8 ] = "reserved",
    };
    struct psi_program *pr;
    int tsid,pnr,version,current;
    int j,len,dlen,run,ca;

    len     = mpeg_getbits(data,12,12) + 3 - 4;
    tsid    = mpeg_getbits(data,24,16);
    version = mpeg_getbits(data,42,5);
    current = mpeg_getbits(data,47,1);
    if (!current)
	return len+4;
    if (info->tsid == tsid && info->sdt_version == version)
	return len+4;
    info->sdt_version = version;

    if (verbose)
	fprintf(stderr,
		"ts [sdt]: tsid %d ver %2d [%d/%d]\n",
		tsid, version,
		mpeg_getbits(data,48, 8),
		mpeg_getbits(data,56, 8));
    j = 88;
    while (j < len*8) {
	pnr  = mpeg_getbits(data,j,16);
	run  = mpeg_getbits(data,j+24,3);
	ca   = mpeg_getbits(data,j+27,1);
	dlen = mpeg_getbits(data,j+28,12);
	if (verbose > 1) {
	    fprintf(stderr,"   pnr %3d ca %d %s #",
		    pnr, ca, running[run]);
	    mpeg_dump_desc(data+j/8+5,dlen);
	    fprintf(stderr,"\n");
	}
	pr = psi_program_get(info, tsid, pnr, 1);
	parse_sdt_desc(data+j/8+5,dlen,pr);
	pr->running = run;
	pr->ca      = ca;
	j += 40 + dlen*8;
    }
    if (verbose > 1)
	fprintf(stderr,"\n");
    return len+4;
}

int mpeg_parse_psi_nit(struct psi_info *info, unsigned char *data, int verbose)
{
    struct psi_stream *stream;
    char network[PSI_STR_MAX] = "";
    int id,version,current,len;
    int j,dlen,tsid;

    len     = mpeg_getbits(data,12,12) + 3 - 4;
    id      = mpeg_getbits(data,24,16);
    version = mpeg_getbits(data,42,5);
    current = mpeg_getbits(data,47,1);
    if (!current)
	return len+4;
    if (0 /* info->id == id */ && info->nit_version == version)
	return len+4;
    info->nit_version = version;

    j = 80;
    dlen = mpeg_getbits(data,68,12);
    parse_nit_desc_1(data + j/8, dlen, network, sizeof(network));
    if (verbose) {
	fprintf(stderr,
		"ts [nit]: id %3d ver %2d [%d/%d] #",
		id, version,
		mpeg_getbits(data,48, 8),
		mpeg_getbits(data,56, 8));
	mpeg_dump_desc(data + j/8, dlen);
	fprintf(stderr,"\n");
    }
    j += 16 + 8*dlen;

    while (j < len*8) {
	tsid = mpeg_getbits(data,j,16);
        dlen = mpeg_getbits(data,j+36,12);
	j += 48;
	stream = psi_stream_get(info, tsid, 1);
	stream->updated = 1;
	if (network)
	    strcpy(stream->net, network);
	parse_nit_desc_2(data + j/8, dlen, stream);
	if (verbose > 1) {
	    fprintf(stderr,"   tsid %3d #", tsid);
	    mpeg_dump_desc(data + j/8, dlen);
	    fprintf(stderr,"\n");
	}
	j += 8*dlen;
    }
    
    if (verbose > 1)
	fprintf(stderr,"\n");
    return len+4;
}
