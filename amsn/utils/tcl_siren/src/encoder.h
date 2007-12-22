#ifndef _SIREN_ENCODER_H
#define _SIREN_ENCODER_H

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "dct4.h"
#include "rmlt.h"
#include "huffman.h"
#include "common.h"


typedef struct stSirenEncoder { 
	int sample_rate;
	SirenWavHeader WavHeader;
	float context[320];
} * SirenEncoder;

/* sample_rate MUST be 16000 to be compatible with MSN Voice clips (I think) */
extern SirenEncoder Siren7_NewEncoder(int sample_rate);
extern void Siren7_CloseEncoder(SirenEncoder encoder);
extern int Siren7_EncodeFrame(SirenEncoder encoder, unsigned char *DataIn, unsigned char *DataOut);


#endif /* _SIREN_ENCODER_H */
