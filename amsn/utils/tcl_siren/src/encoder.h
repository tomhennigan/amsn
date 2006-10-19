#ifndef _SIREN_ENCODER_H
#define _SIREN_ENCODER_H

#include <math.h>
#include <stdlib.h>
#include <string.h>
#include "dct4.h"
#include "rmlt.h"
#include "huffman.h"


typedef struct {
	unsigned int RiffId;
	unsigned int RiffSize;
} RiffHeader;

typedef struct  {
	unsigned short Format; 
	unsigned short Channels;
	unsigned int SampleRate; 
	unsigned int ByteRate;
	unsigned short BlockAlign;
	unsigned short BitsPerSample;
	unsigned short ExtraSize;
	unsigned short DctLength;

} FmtChunk;

typedef struct {
	RiffHeader riff;
	unsigned int WaveId;

	unsigned int FmtId;
	unsigned int FmtSize;

	FmtChunk fmt;

	unsigned int FactId;
	unsigned int FactSize;
	unsigned int Samples;

	unsigned int DataId;
	unsigned int DataSize;
} SirenWavHeader;

typedef struct stSirenEncoder { 
	int sample_rate;
	SirenWavHeader WavHeader;
	float context[320];
} * SirenEncoder;

extern int region_size;
extern float region_size_inverse;
extern float deviation_inverse[64];
extern float region_power_table_boundary[63];
extern int expected_bits_table[8];
extern int vector_dimension[8];
extern int number_of_vectors[8];
extern float dead_zone[8]; 
extern int max_bin[8];
extern float step_size[8];
extern float step_size_inverse[8]; 


extern void siren_init();
extern int categorize_regions(int number_of_regions, int number_of_available_bits, int *absolute_region_power_index, int *power_categories, int *category_balance);



#ifdef __BIG_ENDIAN__

#define POW_2_8 256
#define POW_2_16 65536
#define POW_2_24 16777216


#define GUINT16_TO_LE(val) ( (unsigned short) (\
        ((unsigned short) (val % 256) & 0xff) << 8 | \
        ((unsigned short) ((val / POW_2_8) % 256) & 0xff) ))

#define GUINT32_TO_LE(val) ( (unsigned int) (\
        ((unsigned int) (val % 256 ) & 0xff) << 24 | \
        ((unsigned int) ((val / POW_2_8) % 256) & 0xff) << 16| \
        ((unsigned int) ((val / POW_2_16) % 256 ) & 0xff) << 8 | \
        ((unsigned int) ((val / POW_2_24) % 256 ) & 0xff) ))

#define IDX(val, i) ((unsigned int) ((unsigned char *) &val)[i])

#define GUINT16_FROM_LE(val) ( (unsigned short) ( IDX(val, 0) + (unsigned short) IDX(val, 1) * 256 ))
#define GUINT32_FROM_LE(val) ( (unsigned int) (IDX(val, 0) + IDX(val, 1) * 256 + \
        IDX(val, 2) * 65536 + IDX(val, 3) * 16777216)) 

#else 

#define GUINT16_TO_LE(val) ( (unsigned short) (val))
#define GUINT32_TO_LE(val) ( (unsigned int) (val))
#define GUINT16_FROM_LE(val) ( (unsigned short) (val))
#define GUINT32_FROM_LE(val) ( (unsigned int) (val))

#endif

#endif /* _SIREN_ENCODER_H */
