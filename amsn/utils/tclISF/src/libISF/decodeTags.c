#include	<stdlib.h>
#include	<stdio.h>
#include	<math.h>

#include	"libISF.h"
#include	"DecodeISF.h"
#include	"misc.h"

#define MAX(X, Y)  ((X) > (Y) ? (X) : (Y))


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Read the rest of the payload                                        *
 *                                                                            *
 * This function is mainly used when we don't know how to understand values.\n*
 * It displays values as hexadecimal, 16 per lines.                           *
 *                                                                            *
 * \param pDecISF    structure used to decode the ISF file.                   *
 * \param label      string displayed before every line of hex values         *
 * \param endPayload number pDecISF->bytesRead should be when the job is      *
 *                   done. it's pDecISF->bytesRead + number of bytes to read. *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int finishPayload(decodeISF_t * pDecISF, const char * label, INT64 endPayload)
{
    int err = OK; /* the error code */
    unsigned char c;
    int lineNb,
        i,j; /* loop index */

    /* First, check if we need to do something. */
    if (endPayload != pDecISF->bytesRead)
    {
        lineNb = (endPayload + 15 - pDecISF->bytesRead)/16;
        LOG(stdout,"%s: %lld bytes to read\n",
                label,
                endPayload - pDecISF->bytesRead);
        /* Display only 16 bytes per line */
        for (i=0; i<lineNb && err == OK; i++)
        {
            LOG(stdout,"%s ",label);
            j = 0;
            do
            {
                err = readByte (pDecISF, &c);
                j++;
                /* DEBUG should be in the condition to avoid to display an
                 * erroneous value in case err != OK
                 * and avoid checking 2 times whether err == OK
                 */
                if (err == OK)
                    LOG(stdout,"%.2X ", c);
            } while (err == OK && pDecISF->bytesRead < endPayload && j<16);
            LOG(stdout,"\n");
        }
    }
    return err;
}



/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get an unknown tag                                                  *
 *                                                                            *
 * Used when we don't know how to handle a tag.\n                             *
 * We read an MBUINT and we consider it as the payload size of that tag.\n    *
 * #finishPayload does the rest.                                              *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getUnknownTag (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload = 0,
          value;

    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value != 0)
    {
        LOG(stdout,"(UNKNOWN_TAG) payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;
        err = finishPayload(pDecISF,"(UNKNOWN_TAG)",endPayload);
    }
    return err;
}



/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get the Persistent format                                           *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getPersistentFormat (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          value;

    err = readMBUINT(pDecISF, &value);
    /* check the payload size */
    if (err == OK && value != 0)
    {
        LOG(stdout,"payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;

        err = readMBUINT(pDecISF, &value);
        /* /!\ err can be != OK */
        LOG(stdout,"PersistentFormat=%lld\n", value);

        err = finishPayload(pDecISF,"(PERSISTENT_FORMAT)",endPayload);
    }
    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get the Himetric size                                               *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getHimetricSize (decodeISF_t * pDecISF)
{
    int err = OK;
    ISF_t * pISF = pDecISF->ISF;
    INT64 endPayload,
          value;
    /**
     *  This tag consists of:
     *  - One MBUINT that contains the tag ID (29)
     *  - One MBUINT that contains the payload size
     *  - The payload which consists of
     *		- One Signed multibyte integer
     *		- Another Signed multibyte integer
     *
     *  The two signed multibyte integers represent #HIMETRIC sizes.\n
     *  These are assumed to be the width and height of the canvas where the
     *  image was created.\n
     *  Those sizes are often not the size of the image.\n
     *  Those sizes are store in #ISF.width and #ISF.height .
     */
    err = readMBUINT(pDecISF, &value);
    /* check the payload size */
    if (err == OK && value != 0)
    {
        LOG(stdout,"payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;

        err = readMBSINT (pDecISF, &value);
        if (err != OK) return err;
        pISF->width = value;
        err = readMBSINT (pDecISF, &value);
        if (err != OK) return err;
        pISF->height = value;
        LOG(stdout,"(HIMETRIC_SIZE) width=%lld, height=%lld\n",
                pISF->width,
                pISF->height);
        err = finishPayload(pDecISF,"(HIMETRIC_SIZE)",endPayload);
    }
    return err;
}




/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Drawing Attributes block                                      *
 *                                                                            *
 * The drawing attributes block decoded is chained in #ISF.DrawAttrs          *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getDrawAttrsBlock (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          value;
    drawAttrs_t * pDrawAttrs;

    /**
     * The DRAW_ATTRS_BLOCK tag starts with an MBUINT which represents the
     * payload size as usual.\n
     * Its payload consists of one or more drawing attributes following each
     * other.\n
     * Each drawing attribute's layout is like this:
     * - an MBUINT which represents the drawing attribute's GUID
     * - attribute-specific data
     *
     * ID  Name          Description                                          \n
     * -------------------------------------------------------------------------
     * 67  PenStyle                                                           \n
     * 68  Color         The color in BBGGRR format.                          \n
     * 69  PenWidth      Pen width in #HIMETRIC units.                        \n
     * 70  PenHeight     Pen height in #HIMETRIC units.                       \n
     * 71  PenTip 	     There are 2 values known :                           \n
     *                   0 : the pen tip is an ellipse (default)              \n
     *                   1 : the pen tip is a rectangle                       \n
     * 72  Flags 	     Known masks are:                                     \n
     *                   0x01  Fit To Curve                                   \n
     *                   0x04  Ignore Pressure                                \n
     * 80  Transparency  Value of the alpha channel. (Transparent is 0XFF)    \n
     * 87  IsHighlighter 4 bytes ...                                          \n
     * 27  Mantissa      Occurs after PenHeight or PenWidth. Payload should be\n
     *                   decoded as property data.                            \n
     * ID > 100 : \n
     * Payload is property data associated with the ID.
     */

    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value != 0)
    {
        LOG(stdout,"payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;

        /* Check whether we should add a DrawAttrs or use the default one */
        if (pDecISF->lastDrawAttrs != &(pDecISF->ISF->drawAttrs) )
        {
            err = createDrawingAttrs(&pDrawAttrs);
            if (err != OK)
                return err;
        } else {
            pDrawAttrs = *(pDecISF->lastDrawAttrs);
        }

        do
        {
            err = readMBUINT (pDecISF, &value);
            switch (value)
            {
                case PEN_STYLE:
                    /*TODO*/
                    LOG(stderr,"We get a PEN STYLE !!!\n");
                    break;
                case COLOR:
                    err = readMBUINT (pDecISF, &value);
                    LOG(stdout,"COLOR=%#X\n", (int) value);
                    pDrawAttrs->color = (pDrawAttrs->color&0xFF000000) | (int) value;
                    /* The color in BBGGRR format */
                    break;
                case PEN_WIDTH:
                    err = readMBUINT (pDecISF, &value);
                    /* Pen width in HIMETRIC units */
                    LOG(stdout,"PenWidth(HIM)=%lld\n",value);
                    pDrawAttrs->penWidth = (float) value;
                    /*TODO: works, but hum ...*/
                    pDrawAttrs->penHeight = pDrawAttrs->penWidth;
                    break;
                case PEN_HEIGHT:
                    err = readMBUINT (pDecISF, &value);
                    LOG(stdout,"PenHeight(HIM)=%lld\n",value);
                    /* Pen height in Himetric units */
                    pDrawAttrs->penHeight = (float) value;
                    break;
                case PEN_TIP:
                    err = readMBUINT (pDecISF, &value);
                    LOG(stdout,"PenTip=%lld\n",value);
                    if (value)
                        pDrawAttrs->flags |= DA_ISRECTANGLE;
                    break;
                case FLAGS:
                    err = readMBUINT (pDecISF, &value);
                    LOG(stdout,"Flags=%lld\n",value);
                    pDrawAttrs->flags = (0XFF00 &pDrawAttrs->flags) | (unsigned short) value;
                    break;
                case TRANSPARENCY:
                    err = readMBUINT (pDecISF, &value);
                    pDrawAttrs->color = (pDrawAttrs->color&0xFFFFFF)
                                      | (((unsigned char) value)<<24);
                    LOG(stdout,"Transparency=%X (%X)\n",
                            (unsigned int)value,
                            (unsigned int)(255-value));
                    break;
                case ISHIGHLIGHTER:
                    pDrawAttrs->flags |= DA_ISHIGHLIGHTER;
                    /*TODO: payloadSize seems to be 4 */
                    finishPayload(pDecISF,"ISHIGHLIGHTER",pDecISF->bytesRead+4);
                    break;
                case MANTISSA:
                    /*TODO*/
                    err = getProperty (pDecISF, 27);
                    break;
                default:
                    if (value >= 100 && value <= pDecISF->guidIdMax)
                    {
                        /* There's a GUID for that attribute */
                        err = getProperty (pDecISF, value);
                    } else {
                        LOG(stderr, "[DRAW_ATTRS_TABLE] Oops, wrong flag found : %lld\n",
                                value);
                        err = finishPayload(pDecISF,"(DRAWATTRS)",endPayload);
                    }
            }
        } while (err == OK && pDecISF->bytesRead < endPayload);

        pDecISF->ISF->penWidthMax = MAX(pDecISF->ISF->penWidthMax, pDrawAttrs->penWidth);
        pDecISF->ISF->penHeightMax = MAX(pDecISF->ISF->penHeightMax, pDrawAttrs->penHeight);

        LOG(stdout,"----------------------\n");

        /* Insert the current Draw Attributes block in the ISF struct */
        *(pDecISF->lastDrawAttrs) = pDrawAttrs;
        pDecISF->lastDrawAttrs = &(pDrawAttrs->next);
    }
    return err;
}



/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a drawing attributes table.                                     *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getDrawAttrsTable (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          value;

    /**
     * The DRAW_ATTRS_TABLE tag consists of an MBUINT which represents the
     * payload size.\n
     * Its payload consists of one or more DRAW_ATTRS_BLOCK payloads following
     * each other, each prefixed by an MBUINT specifying the size of that block,
     * in bytes.
     */
    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value != 0)
    {
        LOG(stdout,"payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;
        /* Get every block */
        do
        {
            err = getDrawAttrsBlock (pDecISF);
        } while (err == OK && pDecISF->bytesRead < endPayload);
    }
    return err;
}



/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Metric block                                                  *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getMetricBlock (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          value;
    /**
     * The METRIC_BLOCK tag consists of an MBUINT which represents the payload
     * size.\n
     * Its payload consists of one or many Metric Entries following each other.\n
     * This tag's payload consists of the following:
     * - an MBUINT which represent the METRIC Entry GUID
     * - an MBUINT which represents the payload size of the METRIC Entry.
     * - The payload of the METRIC Entry.
     */

    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value != 0)
    {
        LOG(stdout,"payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;
        do
        {
            err = getMetricEntry (pDecISF);
        } while (err == OK && pDecISF->bytesRead < endPayload);
    }
    return err;
}

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a metric entry                                                  *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getMetricEntry (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          value;
    unsigned char c;
    float f;

    /**
     * The Entries' data consists of the following :
     * - A signed MBINT
     * - A signed MBINT
     * - An MBUINT
     * - A 4 byte integer.
     *
     * The entry's GUID 50 seems to represent the screen's resolution width
     * while GUID 51 the screen's resolution height.\n
     * The entry's GUID 56 seems to represent the number of colors the screen
     * can display.
     * This value (the screen width or height or number of colors) is located in
     * the second MBINT32 of the entry's data.\n
     * The other values' signification are not known yet.
     */
    err = readMBUINT (pDecISF, &value);
    LOG(stdout,"GUID=%lld\n",value);
    err = readMBUINT (pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value != 0)
    {
        
        LOG(stdout,"METRIC ENTRY\n");
        LOG(stdout,"payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;
        err = readMBSINT(pDecISF, &value);
        if (err != OK) return err;
        LOG(stdout,"(METRIC ENTRY) Logical Min = %lld\n",value);
        err = readMBSINT(pDecISF, &value);
        if (err != OK) return err;
        LOG(stdout,"(METRIC ENTRY) Logical Max = %lld\n",value);
        err = readByte(pDecISF, &c);
        if (err != OK) return err;
        LOG(stdout,"(METRIC ENTRY) BYTE|Units = %X\n", c);
        err = readFloat(pDecISF, &f);
        if (err != OK) return err;
        LOG(stdout,"(METRIC ENTRY) FLOAT|Resolution = %f\n", f);
        err = finishPayload(pDecISF,"(METRIC ENTRY)",endPayload);
    }
    LOG(stdout,"-------------------\n");
    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Transform Table                                               *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getTransformTable (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          value;

    /**
     * The TransformTable tag consists of an MBUINT which represents the payload
     * size.\n
     * Its payload consists of one or more Transforms tags following each other.
     */

    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err ==OK && value != 0)
    {
        LOG(stdout,"payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;

        /* Get every transform */
        do
        {
            err = readMBUINT(pDecISF, &value);
            if (err == OK)
            {
                switch(value)
                {
                    case TRANSFORM:
                        LOG(stdout,"\nTRANSFORM\n");
                        err = getTransform (pDecISF);
                        break;

                    case TRANSFORM_ISOTROPIC_SCALE:
                        LOG(stdout,"\nTRANSFORM_ISOTROPIC_SCALE\n");
                        err = getTransformIsotropicScale (pDecISF);
                        break;

                    case TRANSFORM_ANISOTROPIC_SCALE:
                        LOG(stdout,"\nTRANSFORM_ANISOTROPIC_SCALE\n");
                        err = getTransformAnisotropicScale (pDecISF);
                        break;

                    case TRANSFORM_ROTATE:
                        LOG(stdout,"\nTRANSFORM_ROTATE\n");
                        err = getTransformRotate (pDecISF);
                        break;

                    case TRANSFORM_TRANSLATE:
                        LOG(stdout,"\nTRANSFORM_TRANSLATE\n");
                        err = getTransformTranslate (pDecISF);
                        break;

                    case TRANSFORM_SCALE_AND_TRANSLATE:
                        LOG(stdout,"\nTRANSFORM_SCALE_AND_TRANSLATE\n");
                        err = getTransformScaleAndTranslate (pDecISF);
                        break;

                    case TRANSFORM_QUAD:
                        LOG(stderr,"\nTRANSFORM_QUAD\n");
                        /* TODO */
                        break;
                    default:
                        if (value >= 100 && value <= pDecISF->guidIdMax)
                        {
                            /* There's a GUID for that tag */
                            LOG(stdout,"\nGUID_%lld\n",value);
                            err = getProperty (pDecISF, value);
                        } else {
                            LOG(stderr,"/!\\[TRANSFORM_TABLE] Oops, wrong flag found: %lld\n", value);
                            err = finishPayload(
                                    pDecISF,
                                    "(TRANSFORM_TABLE)",
                                    endPayload);
                        }
                }
            }
            LOG(stdout,"-------------------\n");
        } while (err == OK && pDecISF->bytesRead < endPayload);
    }
    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Transform                                                     *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getTransform (decodeISF_t * pDecISF)
{
    int err = OK;
    transform_t * pTransform;

    /**
     * This tag consists of the six values describing the transform matrix.\n
     * Those six values are coded in the stream as floats (IEEE 754)\n
     * We have in order:
     * - m11
     * - m21
     * - m12
     * - m22
     * - m13
     * - m23
     *
     * The transform matrix is :\n
     * \f[
     *	\mbox{T} = \left( \begin{array}{ccc} \mbox{m}_{11} & \mbox{m}_{12} & \mbox{m}_{13} \\ \mbox{m}_{21} & \mbox{m}_{22} & \mbox{m}_{23} \\ 0 & 0 & 1\\ \end{array} \right)
     * \f]
     *
     * \see #transform_t
     */

    /* Check whether we should add a transform or use the default one */
    if (pDecISF->lastTransform != &(pDecISF->transforms) )
    {
        err = createTransform(&pTransform);
        if (err != OK)
            return err;
    } else {
        pTransform = *(pDecISF->lastTransform);
    }

    /* Fill the transform matrix */
    err = readFloat (pDecISF, &pTransform->m11);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m21);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m12);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m22);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m13);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m23);
    if (err != OK) return err;

    /*DEBUG*/
    LOG(stdout,"(TRANSFORM) m11 = %f\n", pTransform->m11);
    LOG(stdout,"(TRANSFORM) m12 = %f\n", pTransform->m12);
    LOG(stdout,"(TRANSFORM) m13 = %f\n", pTransform->m13);
    LOG(stdout,"(TRANSFORM) m21 = %f\n", pTransform->m21);
    LOG(stdout,"(TRANSFORM) m22 = %f\n", pTransform->m22);
    LOG(stdout,"(TRANSFORM) m23 = %f\n", pTransform->m23);

    /* Insert the current Transform */
    *(pDecISF->lastTransform) = pTransform;
    pDecISF->lastTransform = &(pTransform->next);

    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get an Isotropic Scale Transform                                    *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getTransformIsotropicScale (decodeISF_t * pDecISF)
{
    int err = OK;
    float a;
    transform_t * pTransform;

    /**
     * This tag consists of the one value describing an isotropic scale
     * transform matrix.\n
     * This value (let's call it "A") is coded in the stream as float IEEE 754\n
     * The transform matrix is :\n
     * \f[
     *	\mbox{T} = \mbox{A} * \left( \begin{array}{ccc} 1 & 0 & 0 \\ 0 & 1 & 0 \\ 0 & 0 & 1\\ \end{array} \right)
     *	= \left( \begin{array}{ccc} \mbox{A} & 0 & 0 \\ 0 & \mbox{A} & 0 \\ 0 & 0 & 1\\ \end{array} \right)
     * \f]
     * \see #transform_t
     */

    /* Check whether we should add a transform or use the default one */
    if (pDecISF->lastTransform != &(pDecISF->transforms) )
    {
        err = createTransform(&pTransform);
        if (err != OK)
            return err;
    } else {
        pTransform = *(pDecISF->lastTransform);
    }

    /*DEBUG*/
    err = readFloat (pDecISF, &a);
    if (err == OK)
    {
        LOG(stdout,"(TRANSFORM_ISOTROPIC_SCALE) a = %f\n", a);

        /* Apply the transformation to the transformation matrix */
        pTransform->m11 = pTransform-> m22 = a;

        /* Insert the current Transform */
        *(pDecISF->lastTransform) = pTransform;
        pDecISF->lastTransform = &(pTransform->next);
    }
    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get an Anisotropic Scale Transform                                  *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getTransformAnisotropicScale (decodeISF_t * pDecISF)
{
    int err = OK;
    transform_t * pTransform;

    /**
     * This tag consists of 2 values describing an anisotropic scale transform
     * matrix.\n
     * Those two values are coded in the stream as floats (IEEE 754)\n
     * We have in order:
     * - A
     * - B
     *
     * The transform matrix is :\n
     * \f[
     *	\mbox{T} = \left( \begin{array}{ccc} \mbox{A} & 0 & 0 \\ 0 & \mbox{B} & 0 \\ 0 & 0 & 1\\ \end{array} \right)
     * \f]
     */

    /* Check whether we should add a transform or use the default one */
    if (pDecISF->lastTransform != &(pDecISF->transforms) )
    {
        err = createTransform(&pTransform);
        if (err != OK)
            return err;
    } else {
        pTransform = *(pDecISF->lastTransform);
    }

    err = readFloat (pDecISF, &pTransform->m11);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m22);
    if (err != OK) return err;

    LOG(stdout,"(TRANSFORM_ANISOTROPIC_SCALE) m11 = %f\n", pTransform->m11);
    LOG(stdout,"(TRANSFORM_ANISOTROPIC_SCALE) m22 = %f\n", pTransform->m22);

    /* Insert the current Transform */
    *(pDecISF->lastTransform) = pTransform;
    pDecISF->lastTransform = &(pTransform->next);

    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Rotate Transform                                              *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getTransformRotate (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 rotate;
    double angle;
    transform_t * pTransform;

    /**
     * This tag consists of one MBUINT describing a rotate transform matrix.\n
     * Let's call this value "A".
     *
     * If A = 0, then there's no transformation to do; \n
     * elsewise A is one hundredth of a degree.
     *
     * The transform matrix is (with cos and sin working with radians) :\n
     * \f[
     *	\mbox{T} = \left( \begin{array}{ccc} \cos{\frac{\mbox{A} * 2 \pi}{36000}} & -\cos{\frac{\mbox{A} * 2 \pi}{36000}} & 0 \\
     *										 \sin{\frac{\mbox{A} * 2 \pi}{36000}} &  \cos{\frac{\mbox{A} * 2 \pi}{36000}} & 0 \\
     *										              0                       &              0                        & 1 \\
     *										\end{array} \right)
     * \f]
     *
     * \see #transform_t
     */

    /* Check whether we should add a transform or use the default one */
    if (pDecISF->lastTransform != &(pDecISF->transforms) )
    {
        err = createTransform(&pTransform);
        if (err != OK)
            return err;
    } else {
        pTransform = *(pDecISF->lastTransform);
    }

    err = readMBUINT(pDecISF, &rotate);
    if (err == OK && rotate)
    {
        angle = (double) rotate * RADIANPER100THOFDEGREE;
        LOG(stdout,"(TRANSFORM_ROTATE) Rotate = %lld = %lf\n",rotate,angle);

        pTransform->m11 = pTransform->m22 = (float) cos(angle);
        pTransform->m12 = - pTransform->m11;
        pTransform->m21 = (float) sin(angle);

        /* Insert the current Transform */
        *(pDecISF->lastTransform) = pTransform;
        pDecISF->lastTransform = &(pTransform->next);

    }
    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Translate Transform                                           *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getTransformTranslate (decodeISF_t * pDecISF)
{
    int err = OK;
    transform_t * pTransform;

    /**
     * This tag consists of 2 values describing a translate transform matrix.\n
     * Those two values are coded in the stream as floats (IEEE 754)\n
     * We have in order:
     * - dx
     * - dy
     *
     * The transform matrix is :\n
     * \f[
     *	\mbox{T} = \left( \begin{array}{ccc} 0 & 0 & \mbox{dx} \\ 0 & 0 & \mbox{dy} \\ 0 & 0 & 1\\ \end{array} \right)
     * \f]
     *
     * In fact the transform matrix shouldn't be like that cause that
     * transformation don't translate.\n
     * Anyway, it seems to work this way with the .Net 3.0 framework ...
     * The transform matrix should be :\n
     * \f[
     *	\mbox{T} = \left( \begin{array}{ccc} \mbox{1} & 0 & \mbox{dx} \\ 0 & \mbox{1} & \mbox{dy} \\ 0 & 0 & 1\\ \end{array} \right)
     * \f]
     */

    /* Check whether we should add a transform or use the default one */
    if (pDecISF->lastTransform != &(pDecISF->transforms) )
    {
        err = createTransform(&pTransform);
        if (err != OK)
            return err;
    } else {
        pTransform = *(pDecISF->lastTransform);
    }

    err = readFloat (pDecISF, &pTransform->m13);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m23);
    if (err != OK) return err;

    LOG(stdout,"(TRANSFORM_TRANSLATE) m13 = %f\n", pTransform->m13);
    LOG(stdout,"(TRANSFORM_TRANSLATE) m23 = %f\n", pTransform->m23);

    /* Insert the current Transform */
    *(pDecISF->lastTransform) = pTransform;
    pDecISF->lastTransform = &(pTransform->next);

    return err;
}

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Scale and Translate Transform                                 *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getTransformScaleAndTranslate (decodeISF_t * pDecISF)
{
    int err = OK;
    transform_t * pTransform;

    /**
     * This tag consists of four values describing a scale and translate
     * transform matrix.\n
     * Those four values are coded in the stream as floats (IEEE 754)\n
     * We have in order:
     * - m11
     * - m22
     * - m13
     * - m23
     *
     * The transform matrix is :\n
     * \f[
     *	\mbox{T} = \left( \begin{array}{ccc} \mbox{m}_{11} & 0 & \mbox{m}_{13} \\ 0 & \mbox{m}_{22} & \mbox{m}_{23} \\ 0 & 0 & 1\\ \end{array} \right)
     * \f]
     *
     * \see #transform_t
     */

    /* Check whether we should add a transform or use the default one */
    if (pDecISF->lastTransform != &(pDecISF->transforms) )
    {
        err = createTransform(&pTransform);
        if (err != OK)
            return err;
    } else {
        pTransform = *(pDecISF->lastTransform);
    }

    /* Fill the transform matrix */
    err = readFloat (pDecISF, &pTransform->m11);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m22);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m13);
    if (err != OK) return err;
    err = readFloat (pDecISF, &pTransform->m23);
    if (err != OK) return err;

    LOG(stdout,"(TRANSFORM_SCALE_AND_TRANSLATE) m11 = %f\n", pTransform->m11);
    LOG(stdout,"(TRANSFORM_SCALE_AND_TRANSLATE) m22 = %f\n", pTransform->m22);
    LOG(stdout,"(TRANSFORM_SCALE_AND_TRANSLATE) m13 = %f\n", pTransform->m13);
    LOG(stdout,"(TRANSFORM_SCALE_AND_TRANSLATE) m23 = %f\n", pTransform->m23);

    /* Insert the current Transform */
    *(pDecISF->lastTransform) = pTransform;
    pDecISF->lastTransform = &(pTransform->next);

    return err;
}

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get Stroke Ids                                                      *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
/*TODO*/
int getStrokeIds (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          value;

    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value != 0)
    {
        LOG(stdout,"payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;
        err = finishPayload(pDecISF, "(STROKE_IDS)", endPayload);
    }
    return err;
}

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Stroke                                                        *
 *                                                                            *
 * The stroke decoded is chained in #ISF.strokes and chained to its drawing   *
 * attributes.\n                                                              *
 * The current transform is also applied.                                     *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getStroke (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          packetNumber,
          value,
          i,
          max,
          min;
    stroke_t * pStroke;
    float m11,m12,m13,m21,m22,m23;

    /**
     * This tag consist of:
     * - One MBUINT that represents the payload size in bytes.
     * - One MBUINT that contains the number of packets following.
     * - Packet data for GUID_X.
     * - Packet data for GUID_Y.
     * - Possibly more in some cases : we can have the pressure on the pen when
     *   the drawing was made
     *
     * GUID_X and GUID_Y are both a list of absolute x and y coordinates (in
     * #Himetric units), where each element in each list maps directly to the
     * element at the same index in the other list. These form an ordered
     * list of points.
     */


    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value != 0)
    {
        endPayload = pDecISF->bytesRead + value;
        LOG(stdout,"payload size = %lld (bytesRead=%lld)\n", value, pDecISF->bytesRead);

        readMBUINT (pDecISF, &packetNumber);
        if (packetNumber != 0 )
        {
            LOG(stdout,"packetNumber=%lld\n", packetNumber);

            err = createStroke( &pStroke, packetNumber, NULL, pDecISF->curDrawAttrs);
            if (err != OK)
                return err;

            /* Link the stroke to its drawing attributes */
            pStroke->drawAttrs->nStrokes++;
            pStroke->nPoints = packetNumber;

            /* Add the P array if needed */
            if (pDecISF->gotStylusPressure == 1)
            {
                pStroke->P = (INT64 *) malloc ((unsigned int)packetNumber*sizeof(INT64));
                if (!pStroke->P)
                {
                    free(pStroke->X);
                    free(pStroke->Y);
                    free(pStroke);
                    return OUT_OF_MEMORY;
                }
            }

            /* Decode the X coordinates */
            err = decodePacketData(pDecISF, packetNumber, pStroke->X);
            if (err != OK)
            {
                free(pStroke->X);
                free(pStroke->Y);
                free(pStroke->P); /* "works" with NULL pointer */
                free(pStroke);
                if (err > OK)
                    finishPayload(pDecISF,"(STROKE)", endPayload);

                return err;
            }

            /* Decode the Y coordinates */
            err = decodePacketData(pDecISF, packetNumber, pStroke->Y);
            if (err != OK)
            {
                free(pStroke->X);
                free(pStroke->Y);
                free(pStroke->P); /* "works" with NULL pointer */
                free(pStroke);
                if (err > OK)
                    finishPayload(pDecISF,"(STROKE)", endPayload);

                return err;
            }

            if ( pDecISF->gotStylusPressure == 1 )
            {
                /* Decode the pressure array */
                err = decodePacketData(pDecISF, packetNumber, pStroke->P);
                if (err != OK)
                {
                    free(pStroke->X);
                    free(pStroke->Y);
                    free(pStroke->P); /* "works" with NULL pointer */
                    if (err > OK)
                        finishPayload(pDecISF,"(STROKE)", endPayload);

                    free(pStroke);
                    return err;
                }
            }

            /* Insert the strokes in the ISF structure */
            if (pStroke->drawAttrs->flags & DA_ISHIGHLIGHTER)
            {
                /* the job is to insert highlighter strokes before
                 * non-highlighter ones */
                pStroke->next = *(pDecISF->lastHighlighterStroke);
                if (pDecISF->lastStroke == pDecISF->lastHighlighterStroke)
                    /* need to change lastStroke too */
                    pDecISF->lastStroke = &(pStroke->next);
                *(pDecISF->lastHighlighterStroke) = pStroke;
                pDecISF->lastHighlighterStroke = &(pStroke->next);
            } else {
                /* Stroke is not a highlighter */
                *(pDecISF->lastStroke) = pStroke;
                pDecISF->lastStroke = &(pStroke->next);
            }

            /* Apply the transformation if needed:
             * (X Y *) = (X Y 1) * transformMatrix
             */
            m11 = pDecISF->curTransform->m11;
            m12 = pDecISF->curTransform->m12;
            m13 = pDecISF->curTransform->m13;
            m21 = pDecISF->curTransform->m21;
            m22 = pDecISF->curTransform->m22;
            m23 = pDecISF->curTransform->m23;
            /* Check whether the transform is not the identity (the default) */
            if ( m11 != 1 || m22 != 1 || m12 != 0 || m21 != 0 || m13 != 0 || m23 != 0)
            {
                for(i=0; i<packetNumber; i++)
                {
                    *(pStroke->X+i) = m11 * *(pStroke->X+i) + m12 * *(pStroke->Y+i) + m13;
                    *(pStroke->Y+i) = m21 * *(pStroke->X+i) + m22 * *(pStroke->Y+i) + m23;
                }
            }

            /* We search highest/lowest coords to know the size of the image
             * since that information is not coded in the format.
             */
            /* First with X coords */
            min = max = pStroke->X[0];
            for(i=0; i<packetNumber; i++)
            {
                if (pStroke->X[i] > max)
                    max = pStroke->X[i];
                else {
                    if (pStroke->X[i] < min)
                        min = pStroke->X[i];
                }
            }
            /* Fill the bounding box for that stroke */
            pStroke->xOrigin = min;
            pStroke->xEnd = max;
            /* Fill the bounding box for the whole image */
            if (pStroke->xOrigin < pDecISF->ISF->xOrigin)
                pDecISF->ISF->xOrigin = pStroke->xOrigin;
            if (pStroke->xEnd > pDecISF->ISF->xEnd)
                pDecISF->ISF->xEnd = pStroke->xEnd;

            /* Now Y coords */
            min = max = pStroke->Y[0];
            for(i=0; i<packetNumber; i++)
            {
                if (pStroke->Y[i] > max)
                    max = pStroke->Y[i];
                else {
                    if (pStroke->Y[i] < min)
                        min = pStroke->Y[i];
                }
            }
            /* Fill the bounding box for that stroke */
            pStroke->yOrigin = min;
            pStroke->yEnd = max;
            /* Fill the bounding box for the image if needed */
            if (pStroke->yOrigin < pDecISF->ISF->yOrigin)
                pDecISF->ISF->yOrigin = pStroke->yOrigin;
            if (pStroke->yEnd > pDecISF->ISF->yEnd)
                pDecISF->ISF->yEnd = pStroke->yEnd;

            err = finishPayload(pDecISF,"(STROKE)",endPayload);

#ifdef DEBUG
            LOG(stdout,"\n");
            for(i=0; i<packetNumber; i++)
            {
                LOG(stdout,"%lld %lld ", pStroke->X[i], pStroke->Y[i]);
            }
            LOG(stdout,"\n\n");
#endif
        }
    }
    return err;
}


/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Drawing Attributes Index                                      *
 *                                                                            *
 * This tag's data consists of a single MBUINT with the DIDX value.\n         *
 * This value is the index of the drawing attributes list to use for          *
 * subsequent strokes.\n                                                      *
 * We change #DecodeISF.curDrawAttrs to reflect that.                         *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getDIDX (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 value,
          i = 0;
    drawAttrs_t * pDrawAttrs = pDecISF->ISF->drawAttrs;

    err = readMBUINT(pDecISF, &value);
    if (err == OK)
    {
        LOG(stdout,"DIDX=%lld\n",value);
        /* Set the new current drawing attributes according to the DIDX */
        while ( pDrawAttrs && i < value )
        {
            i++;
            pDrawAttrs = pDrawAttrs->next;
        }
        if (pDrawAttrs)
            pDecISF->curDrawAttrs = pDrawAttrs;
    }
    return err;
}

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Transform Index                                               *
 *                                                                            *
 * This tag's data consists of a single MBUINT with the TIDX value.\n         *
 * This value is the index of the transforms list to use for subsequent       *
 * strokes.\n                                                                 *
 * We change #DecodeISF.curTransform to reflect that.                         *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
int getTIDX (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 value,
          i = 0;
    transform_t * pTransform = pDecISF->transforms;

    err = readMBUINT(pDecISF, &value);
    if (err == OK)
    {
        LOG(stdout,"TIDX=%lld\n",value);
        /* Set the new current drawing attributes according to the DIDX */
        while ( pTransform && i < value )
        {
            i++;
            pTransform = pTransform->next;
        }
        if (pTransform)
            pDecISF->curTransform = pTransform;
    }
    return err;
}




/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a Stroke Description Block                                      *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
/*TODO*/
int getStrokeDescBlock (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          value;

    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value != 0)
    {
        LOG(stdout,"payload size = %lld\n", value);
        endPayload = pDecISF->bytesRead + value;
        err = finishPayload(pDecISF, "(STROKE_DESC_BLOCK)", endPayload);

        pDecISF->gotStylusPressure = 1;
        LOG(stdout,"GOT STYLUS PRESSURE\n");
    }
    return err;
}

/** ------------------------------------------------------------------------ **
 * \internal                                                                  *
 * \brief Get a GUID Table                                                    *
 *                                                                            *
 * \param pDecISF structure used to decode the ISF file.                      *
 *                                                                            *
 * \returns the error code given while processing                             *
 ** ------------------------------------------------------------------------ **/
/*TODO*/
int getGUIDTable (decodeISF_t * pDecISF)
{
    int err = OK;
    INT64 endPayload,
          value;

    err = readMBUINT(pDecISF, &value);
    /* Check the payload size */
    if (err == OK && value != 0)
    {
        LOG(stdout,"(GUID_TABLE) payload size = %lld\n", value);
        /*TODO*/
        /* a GUID is 16 bytes long */
        pDecISF->guidIdMax = 99 + value/16;
        endPayload = pDecISF->bytesRead + value;
        err = finishPayload(pDecISF,"(GUID_TABLE)",endPayload);
    }
    return err;
}

