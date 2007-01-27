#ifndef _SIREN_DECODER_H
#define _SIREN_DECODER_H

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "dct4.h"
#include "rmlt.h"
#include "huffman.h"
#include "common.h"


typedef struct stSirenDecoder { 
	int sample_rate;
	PCMWavHeader WavHeader;
	float context[320];
	int frame_error;
	float backup_frame[320];
	int dw1;
	int dw2;
	int dw3;
	int dw4;
} * SirenDecoder;

extern SirenDecoder Siren7_NewDecoder(int sample_rate); /* MUST be 16000 to be compatible with MSN Voice clips (I think) */
extern void Siren7_CloseDecoder(SirenDecoder encoder);
extern int Siren7_DecodeFrame(SirenDecoder decoder, unsigned char *DataIn, unsigned char *DataOut);
extern int next_bit();

#endif /* _SIREN_DECODER_H */
