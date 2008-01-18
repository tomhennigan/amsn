#ifndef DECODEISF_H
#define DECODEISF_H

#include "libISF.h"


/*CONSTANTS*/
#define RADIANPER100THOFDEGREE 0.000174532925




/* struct where we store tempory values while decoding */
typedef struct decodeISF
{
    void * streamInfo;
    int (*getUChar) (void *, INT64 *, unsigned char*);
    long fileSize;
    INT64 bytesRead; /* Bytes needed to be read */
    drawAttrs_t * curDrawAttrs;
    drawAttrs_t ** lastDrawAttrs;
    stroke_t ** lastStroke;
    stroke_t ** lastHighlighterStroke;
    transform_t * curTransform;
    transform_t * transforms;
    transform_t ** lastTransform;
    char gotStylusPressure;
    int guidIdMax;
    ISF_t * ISF;
} decodeISF_t;





/*FUNCTIONS*/
/* in decodeTags.c */
int finishPayload(decodeISF_t * pDecISF, const char * label, INT64 endPayload);

int getUnknownTag (decodeISF_t * pDecISF);

int getPersistentFormat (decodeISF_t * pDecISF);

int getHimetricSize (decodeISF_t * pDecISF);

int getDrawAttrsTable (decodeISF_t * pDecISF);
int getDrawAttrsBlock (decodeISF_t * pDecISF);

int getMetricBlock (decodeISF_t * pDecISF);
int getMetricEntry (decodeISF_t * pDecISF);

int getTransformTable (decodeISF_t * pDecISF);
int getTransform (decodeISF_t * pDecISF);
int getTransformIsotropicScale (decodeISF_t * pDecISF);
int getTransformAnisotropicScale (decodeISF_t * pDecISF);
int getTransformRotate (decodeISF_t * pDecISF);
int getTransformTranslate (decodeISF_t * pDecISF);
int getTransformScaleAndTranslate (decodeISF_t * pDecISF);

int getStrokeIds (decodeISF_t * pDecISF);
int getStroke (decodeISF_t * pDecISF);
int getDIDX (decodeISF_t * pDecISF);
int getTIDX (decodeISF_t * pDecISF);

int getStrokeDescBlock (decodeISF_t * pDecISF);

int getGUIDTable (decodeISF_t * pDecISF);

/* in read.c */
int readMBUINT (decodeISF_t * pDecISF, INT64 * mbuint);
int readMBSINT (decodeISF_t * pDecISF, INT64 * smbuint);

int readFloat (decodeISF_t * pDecISF, float * f);

int readByte(decodeISF_t * pDecISF, unsigned char * c);

int readNBits (
        decodeISF_t * pDecISF,
        int n,
        unsigned char * buffer,
        unsigned char * offset,
        INT64 * value);

/* in decompression.c */
int decodePacketData(decodeISF_t * pDecISF, INT64 packetNumber, INT64 * arr);

int decodeHuffman (
        decodeISF_t * pDecISF,
        INT64 packetNumber,
        int index,
        INT64 * arr,
        unsigned char * buffer,
        unsigned char * offset);
int generateHuffBases (int index, int * n, INT64 ** huffBases);
int extractValueHuffman (
        decodeISF_t * pDecISF,
        int index,
        int n,
        unsigned char * buffer,
        unsigned char * offset,
        INT64 * value,
        INT64 * huffBases);

int transformInverseDeltaDelta (INT64 packetNumber, INT64 * value);

int decodeGorilla (
        decodeISF_t * pDecISF,
        INT64 packetNumber,
        int blockSize,
        INT64 * arr,
        unsigned char * buffer,
        unsigned char * offset);

/* in decProperty.c */
int getProperty (decodeISF_t * pDecISF, INT64 guidId);

/* in libISF.c */
int checkHeader (decodeISF_t * pDecISF);
void freeDecodeISF (decodeISF_t * pDecISF);


#endif
