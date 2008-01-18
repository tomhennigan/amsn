#ifndef CREATEISF_H
#define CREATEISF_H

#include "libISF.h"

/* in encoding.c */
void encodeMBUINT ( INT64 i, payload_t * p);
void putFloat (float f, payload_t * p);

/* in createTags.c */
int createDrawAttributesTag (
        payload_t ** lastPayload_ptr,
        drawAttrs_t * pDA,
        INT64 * globalPayloadSize);
int createDrawAttrsBlock (
        drawAttrs_t * pDA,
        payload_t ** lastPayload_ptr,
        INT64 * blockPayloadSize);

int createTransformTag (
        payload_t ** lastPayload_ptr,
        transform_t * transformList_ptr,
        INT64 * globalPayloadSize);
int createTransformBlock (
        transform_t * transform_ptr,
        payload_t ** lastPayload_ptr,
        INT64 * blockPayloadSize);


int createStrokesTags(
        payload_t ** lastPayload_ptr,
        stroke_t * strokes,
        drawAttrs_t * ptrDA,
        transform_t * transformList_ptr,
        INT64 * globalPayloadSize);

int createStrokeTag (
        payload_t ** lastPayload_ptr,
        stroke_t * s_ptr,
        INT64 * globalPayloadSize);

/* in compression.c */
int createPacketData (
        payload_t ** lastPayload_ptr,
        INT64 nPoints,
        INT64 * arr,
        INT64 * payloadSize);
int getBlockSize( int points_nb, INT64 * arr);
void encodeGorilla (
        unsigned char * uchar_arr,
        INT64 * int_arr,
        int packetNumber,
        int blockSize);


#endif
