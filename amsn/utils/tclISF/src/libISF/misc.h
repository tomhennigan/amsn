#ifndef MISC_H
#define MISC_H

#include <stdio.h>

/*
 * TAGS IDs
 */
#define INK_SPACE_RECT                    0
#define GUID_TABLE                        1
#define DRAW_ATTRS_TABLE                  2
#define DRAW_ATTRS_BLOCK                  3
#define STROKE_DESC_TABLE                 4
#define STROKE_DESC_BLOCK                 5
#define BUTTONS                           6
#define NO_X                              7
#define NO_Y                              8
#define DIDX                              9
#define STROKE                           10
#define STROKE_PROPERTY_LIST             11
#define POINT_PROPERTY                   12
#define SIDX                             13
#define COMPRESSION_HEADER               14
#define TRANSFORM_TABLE                  15
#define TRANSFORM                        16
#define TRANSFORM_ISOTROPIC_SCALE        17
#define TRANSFORM_ANISOTROPIC_SCALE      18
#define TRANSFORM_ROTATE                 19
#define TRANSFORM_TRANSLATE              20
#define TRANSFORM_SCALE_AND_TRANSLATE    21
#define TRANSFORM_QUAD                   22
#define TIDX                             23
#define METRIC_TABLE                     24
#define METRIC_BLOCK                     25
#define MIDX                             26
#define MANTISSA                         27
#define PERSISTENT_FORMAT                28
#define HIMETRIC_SIZE                    29
#define STROKE_IDS                       30


/* 
 * DRAWING ATTRIBUTES IDs
 */
#define PEN_STYLE                        67
#define COLOR                            68
#define PEN_WIDTH                        69
#define PEN_HEIGHT                       70
#define PEN_TIP                          71
#define PEN_TIP_RECTANGLE                 1
#define FLAGS                            72
#define TRANSPARENCY                     80
#define ISHIGHLIGHTER                    87

/*MASKS*/
#define ISF_FLAGS_MASK	0xFF
#define GORILLA 		0x00

/*FUNCTIONS*/
void LOG (FILE * stream, char * fmt, ...);

#endif
