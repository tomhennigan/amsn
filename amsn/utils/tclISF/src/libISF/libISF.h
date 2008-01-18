/*
 * libISF.h
 *
 * Copyright (C) 2007 Boris FAURE <boris.faure@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 * USA
 */

/*
 * All that code has been made possible with the great help from
 * Youness Alaoui and Ole Andre Vadla Ravnas.
 *
 * A quick documentation of the format can be found at :
 * http://synce.org/moin/FormatDocumentation/InkSerializedFormat
 */


#ifndef LIBISF_H
#define LIBISF_H

#include	<limits.h>

/* Define the INT64 type */
/* TODO: define or typedef ?? */
#ifndef INT64
#ifndef INT64_MAX
#ifndef INT64_MIN

#ifdef WIN32
# define INT64 __int64
#else
# define INT64 long long
#endif

#ifndef INT64_MAX
# ifdef LLONG_MAX
#  define INT64_MAX LLONG_MAX
# else
#  ifdef LONG_LONG_MAX
#   define INT64_MAX LONG_LONG_MAX
#  else
#   ifdef _I64_MAX
#    define INT64_MAX _I64_MAX
#   else
     /* assuming 64bit(2's complement) long long */
#    define INT64_MAX 9223372036854775807LL
#   endif
#  endif
# endif
#endif

#ifndef INT64_MIN
# ifdef LLONG_MIN
#  define INT64_MIN LLONG_MIN
# else
#  ifdef LONG_LONG_MIN
#   define INT64_MIN LONG_LONG_MIN
#  else
#   ifdef _I64_MIN
#    define INT64_MIN _I64_MIN
#   else
#    define INT64_MIN (-INT64_MAX-1)
#   endif
#  endif
# endif
#endif

#endif
#endif
#endif

#define UINT64 unsigned INT64

/* CONSTANTS */
#define HIMPERPX 26.4572454037811

/* MASKS */
#define DA_FITTOCURVE       0x0001
#define DA_IGNOREPRESSURE   0x0004
#define DA_ISHIGHLIGHTER    0x0100
#define DA_ISRECTANGLE      0x0200

/* DEFAULT VALUES */
#define DEFAULT_COLOR       0
#define DEFAULT_PEN_WIDTH   53
#define DEFAULT_PEN_HEIGHT  53
#define DEFAULT_FLAGS       16
/* TODO */
#define DEFAULT_STROKE_SIZE 256


#ifndef MIN
#define MIN(X, Y)  ((X) < (Y) ? (X) : (Y))
#endif
#ifndef MAX
#define MAX(X, Y)  ((X) > (Y) ? (X) : (Y))
#endif


/**
 * Drawing Attributes
 */
typedef struct drawAttrs
{
    /** width of the pencil in Himetric units */
    float penWidth;
    /** height of the pencil in Himetric units */
    float penHeight;
    /** color in AABBGGRR format 
     * Value of the alpha channel. (Transparent is 0XFFxxxxxx) */
    unsigned int color; /* must be minimum a 32 bits int */
    /** have a look at 'define's DA_* */
    unsigned short flags;
    /*TODO: to be completed */
    /** number of strokes using those attributes */
    int nStrokes;
    /** next drawing attributes */
    struct drawAttrs * next;
} drawAttrs_t;


/**
 * Structure describing a stroke
 */
typedef struct stroke
{
    /** number of coords of the stroke */
    INT64 nPoints;
    /** X coordinates */
    INT64 * X;
    /** Y coordinates */
    INT64 * Y;
    /** Pressure information */
    INT64 * P;
    /* bounding box */
    /** most left coordinate used */
    INT64 xOrigin;
    /** top coordinate used */
    INT64 yOrigin;
    /** most right coordinate used, not used while encoding */
    INT64 xEnd;
    /** bottom coordinate used, not used while encoding */
    INT64 yEnd;
    /** size of X and Y arrays (and P if P is allocated), not used while encoding  */
    INT64 size;
    /** pointer to the drawing attributes structure used to display that stroke */
    drawAttrs_t * drawAttrs;
    /** next stroke */
    struct stroke * next;
} stroke_t;



/**
 * A Transform is a 3x3 matrix.\n
 * It is used to apply an affine transformation on points.\n
 *
 * The transform matrix is :\n
 * \f[
 *    \mbox{T} = \left( \begin{array}{ccc} \mbox{m}_{11} & \mbox{m}_{12} & \mbox{m}_{13} \\ \mbox{m}_{21} & \mbox{m}_{22} & \mbox{m}_{23} \\ 0 & 0 & 1\\ \end{array} \right)
 * \f]
 *
 * If you have a point A \f$(X_0,Y_0)\f$, you'll get the new point B \f$(X_1,Y_1)\f$ \n
 * The transformation goes like this :
 *
 * \f[
 \left( \begin{array}{c} X_{1} \\ Y_{1} \\ \phi \end{array} \right) =
 \underbrace{\left(\begin{array}{ccc}
 m_{11} & m_{12}& m_{13} \\
 m_{21} & m_{22}& m_{23} \\
 0      & 0     & 1
 \end{array}\right)}_{T}
 \times
 \begin{array}{c} X_{0} \\ Y_{0} \\1 \end{array}
 \f]
 */
typedef struct transform
{
    float m11,
          m12,
          m13,
          m21,
          m22,
          m23;
    /** pointer to the next transform matrix */
    struct transform * next;
} transform_t;



/**
 * Structure describing an ISF image.
 * It is returned after decoding,
 * and should be given for encoding.
 */
typedef struct ISF
{
    /** bounding box, not used while decoding  */
    /** most left coordinate used */
    INT64 xOrigin;
    /** top coordinate used */
    INT64 yOrigin;
    /** most right coordinate used */
    INT64 xEnd;
    /** bottom coordinate used */
    INT64 yEnd;
    /** width of the image, or width of the area used to draw the ISF */
    INT64 width;
    /** height of the image, or height of the area used to draw the ISF */
    INT64 height;
    /** highest pencil width used */
    float penWidthMax;
    /** highest pencil height used */
    float penHeightMax;

    /** collection of strokes */
    stroke_t * strokes;
    /** drawing attributes related to those strokes */
    drawAttrs_t * drawAttrs;
} ISF_t;






/**
 * Structure where we store a binary ISF in order to be put in a file
 * This structure is only used while encoding.
 * It's not used for decoding
 */
typedef struct payload
{
    /** current use of the tab; must be <= size */
    INT64 cur_length;
    /** size of the tab */
    INT64 size;
    /** pointer where the data is stored */
    unsigned char * data;
    /** pointer to the next element */
    struct payload * next;
} payload_t;


/*
 * ERROR CODES:
 * those <0 are used when we must stop processing
 * those >0 are used when we have an error while decoding but when we still can
 * keep on decoding the file.
 *     unknown drawing attribute for example.
 */
/* TODO */
#define OK 0
#define UNKNOWN_COMPRESSION 10
#define WRONG_CMD -10
#define OUT_OF_MEMORY -20
#define READ_ERROR -30
#define OPEN_ERROR -40
#define FILE_NOT_ISF -50
#define FILE_CORRUPTED -60
#define STROKES_T_INVALID -70


/* FUNCTIONS */
int getISF (
        ISF_t ** pISF,
        void * streamInfo,
        int (*getUChar) (void *, INT64 *, unsigned char*));

int createDrawingAttrs(drawAttrs_t ** pDA);
int createTransform(transform_t ** pTransform);
int createStroke(stroke_t ** pStroke, INT64 size, stroke_t * next,
        drawAttrs_t * drawAttrs);
int createSkeletonISF(ISF_t ** pISF, int width, int height);

drawAttrs_t * searchDrawingAttrsFor (
        drawAttrs_t * pDA_list,
        float penWidth,
        float penHeight,
        unsigned int color,
        unsigned short flags);

void changeZoom (ISF_t * pISF, float zoom);
void freeISF (ISF_t * pISF);


int createPayload (payload_t ** payload_ptr, int size, payload_t * next_ptr);
int createISF (
        ISF_t * pISF,
        payload_t ** rootTag,
        transform_t * transformList_ptr,
        INT64 * fullPayloadSize);



#endif
