#include	<stdlib.h>
#include	<string.h>
#include	<stdio.h>

#include	"libISF.h"
#include	"createISF.h"
#include	"misc.h"



/*******************************************************************************
 * \brief Create the Drawing Attributes Tags
 *
 * Create a payload structure containing one or more drawing attributes tags.
 *
 * \param lastpayload_ptr pointer on the last element where we should put that
 *                        data
 * \param pDA             pointer to a list a drawing attributes
 * \param payloadSize     integer we're going to increase by the size of the
 *                        drawing attributes tags
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createDrawAttributesTag (
        payload_t ** lastPayload_ptr,
        drawAttrs_t * pDA,
        INT64 * globalPayloadSize)
{
    int err = OK;
    drawAttrs_t * ptrDA = pDA;
    payload_t * headerPayload_ptr;
    INT64 payloadSize = 0;

    /* Check whether we need only a block, or a table */
    if (pDA->next)
    {
        /* we need a DRAW_ATTRS_TABLE */
        /* create the payload where we put tag id + payloadSize of the table */
        err = createPayload(&((*lastPayload_ptr)->next), 11, NULL);
        if (err != OK) return err;

        /* save the @ of the struct where we put tag id + payloadSize */
        *lastPayload_ptr = (*lastPayload_ptr)->next;
        headerPayload_ptr = *lastPayload_ptr;

        while (ptrDA)
        {
            printf("COLOR = #%.8X\n",ptrDA->color);
            err = createDrawAttrsBlock(ptrDA, lastPayload_ptr, &payloadSize);
            if (err != OK) return err;

            ptrDA = ptrDA->next;
        }

        /* Add header tag */
        headerPayload_ptr->data[0] = DRAW_ATTRS_TABLE;
        headerPayload_ptr->cur_length = 1;

        /* write payloadSize */
        encodeMBUINT(payloadSize, headerPayload_ptr);

        /* update globalPayloadSize */
        *globalPayloadSize += payloadSize + headerPayload_ptr->cur_length;

    } else {
        /*TODO: Do nothing if the DA block is the default one */
        /* we need only a DRAW_ATTRS_BLOCK */
        /* create the payload where we put only 0x03 */
        /* the rest of the tag is built by createDrawAttrsBlock */
        err = createPayload(&(*lastPayload_ptr)->next, 1, NULL);
        if (err != OK) return err;

        /* save the @ of the struct where we put tag id */
        *lastPayload_ptr = (*lastPayload_ptr)->next;
        headerPayload_ptr = *lastPayload_ptr;

        /* create the drawing attributes block */
        createDrawAttrsBlock(pDA, lastPayload_ptr, &payloadSize);

        /* Add header tag */
        headerPayload_ptr->data[0] = DRAW_ATTRS_BLOCK;
        headerPayload_ptr->cur_length = 1;
        /* update globalPayloadSize */
        *globalPayloadSize += payloadSize + 1;
        /* 1 = headerPayload_ptr->length */
    }
    return err;
}



/*******************************************************************************
 * \brief Create a Drawing Attributes Block
 *
 * Create a payload structure containing a drawing attributes block
 *
 * \param lastpayload_ptr pointer on the last element where we should put that
 *                        block
 * \param pDA             pointer to a drawing attributes structure
 * \param payloadSize     integer we're going to increase by the size of the
 *                        drawing attributes block
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createDrawAttrsBlock (
        drawAttrs_t * pDA,
        payload_t ** lastPayload_ptr,
        INT64 * blockPayloadSize)
{
    int err = OK;
    INT64 payloadSize = 0;
    payload_t * payload_ptr,
              * headerPayload_ptr;

    err = createPayload(&((*lastPayload_ptr)->next), 10, NULL);
    if (err != OK) return err;

    *lastPayload_ptr = (*lastPayload_ptr)->next;
    headerPayload_ptr = *lastPayload_ptr;

    /* 255 should be enough */
    err = createPayload(&((*lastPayload_ptr)->next), 255, NULL);
    if (err != OK) return err;

    *lastPayload_ptr = (*lastPayload_ptr)->next;
    payload_ptr = *lastPayload_ptr;

    /* Color */
/*    if (pDA->color != DEFAULT_COLOR) // Default is 0 : black 
    {*/
        payload_ptr->data[payload_ptr->cur_length++] = COLOR;
        encodeMBUINT( (INT64) pDA->color, payload_ptr);
    /*}*/

    /* PenWidth */
    if ( (int) pDA->penWidth != DEFAULT_PEN_WIDTH)
    {
        payload_ptr->data[payload_ptr->cur_length++] = PEN_WIDTH;
        encodeMBUINT( (INT64) pDA->penWidth, payload_ptr);
    }

    /* PenHeight */
    if ( (int) pDA->penHeight != DEFAULT_PEN_HEIGHT)
    {
        payload_ptr->data[payload_ptr->cur_length++] = PEN_HEIGHT;
        encodeMBUINT( (INT64) pDA->penHeight, payload_ptr);
    }

    /* PenTip */
    if (pDA->flags & DA_ISRECTANGLE)
    {
        payload_ptr->data[payload_ptr->cur_length++] = PEN_TIP;
        payload_ptr->data[payload_ptr->cur_length++] = PEN_TIP_RECTANGLE;
    }

    /* Flags */
    if ((pDA->flags & ISF_FLAGS_MASK) != DEFAULT_FLAGS)
    {
        payload_ptr->data[payload_ptr->cur_length++] = FLAGS;
        encodeMBUINT( (INT64) pDA->flags & ISF_FLAGS_MASK, payload_ptr);
    }

    /* Transparency */
    if ( (pDA->color&0xFF000000))
    {
        payload_ptr->data[payload_ptr->cur_length++] = TRANSPARENCY;
        encodeMBUINT( (INT64) ((pDA->color&0xFF000000)>>24),
                      payload_ptr);
    }

    /* IsHighlighter */
    if (pDA->flags & DA_ISHIGHLIGHTER)
    {
        payload_ptr->data[payload_ptr->cur_length++] = ISHIGHLIGHTER;
        /*TODO*/
        payload_ptr->data[payload_ptr->cur_length++] = 0;
        payload_ptr->data[payload_ptr->cur_length++] = 0;
        payload_ptr->data[payload_ptr->cur_length++] = 0;
        payload_ptr->data[payload_ptr->cur_length++] = 9;
    }


    payloadSize += payload_ptr->cur_length;

    /*TODO : now deal with guid >= 100 */

    /* write payloadSize */
    encodeMBUINT(payloadSize, headerPayload_ptr);

    /* update blockPayloadSize */
    *blockPayloadSize += payloadSize + headerPayload_ptr->cur_length;

    return err;
}



/*******************************************************************************
 * \brief Create a Transform Tag
 *
 * Create a payload structure containing one or more transformation tags.
 *
 * \param lastpayload_ptr   pointer on the last element where we should put
 *                          those tags
 * \param transformList_ptr pointer to a list of transforms
 * \param payloadSize       integer we're going to increase by the size of the
 *                          transform tag(s)
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createTransformTag (
        payload_t ** lastPayload_ptr,
        transform_t * transformList_ptr,
        INT64 * globalPayloadSize)
{
    int err = OK;
    transform_t * curTransform_ptr = transformList_ptr;
    payload_t * headerPayload_ptr;
    INT64 payloadSize = 0;

    /* Check whether we need only a block, or a table */
    if (transformList_ptr->next)
    {
        /* we need a TRANSFORM_TABLE */
        /* create the payload where we put tag id + payloadSize of the table */
        err = createPayload(&((*lastPayload_ptr)->next), 11, NULL);
        if (err != OK) return err;

        /* save the @ of the struct where we put tag id + payloadSize */
        *lastPayload_ptr = (*lastPayload_ptr)->next;
        headerPayload_ptr = *lastPayload_ptr;

        while (curTransform_ptr)
        {
            err = createTransformBlock(
                    curTransform_ptr,
                    lastPayload_ptr,
                    &payloadSize);
            if (err != OK) return err;

            curTransform_ptr = curTransform_ptr->next;
        }

        /* Add header tag */
        headerPayload_ptr->data[0] = TRANSFORM_TABLE;
        headerPayload_ptr->cur_length = 1;

        /* write payloadSize */
        encodeMBUINT(payloadSize, headerPayload_ptr);

        /* update globalPayloadSize */
        *globalPayloadSize += payloadSize + headerPayload_ptr->cur_length;

    } else {
        /*TODO: Do nothing if the Transform matrix is Identity */
        /* we need only a TRANSFORM BLOCK */

        /* create the Transform block */
        createTransformBlock(
                curTransform_ptr,
                lastPayload_ptr,
                globalPayloadSize);
    }
    return err;
}



/*******************************************************************************
 * \brief Create a Transform block
 *
 * Create a payload structure containing one or more transformation tags.
 * That function finds the best transform tag to represent that matrix.
 *
 * \param transform_ptr    pointer to a transform structure
 * \param lastpayload_ptr  pointer on the last element where we should put that
 *                         block
 * \param blockPayloadSize integer we're going to increase by the size of the
 *                         transform tag(s)
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createTransformBlock (
        transform_t * transform_ptr,
        payload_t ** lastPayload_ptr,
        INT64 * blockPayloadSize)
{
    int err = OK;
    payload_t * payload_ptr = NULL;

    /* 25 =
     * 6*4     6 Floats of 4 bytes
     * + 1     tag id
     */
    err = createPayload(&((*lastPayload_ptr)->next), 25, NULL);
    if (err != OK) return err;

    *lastPayload_ptr = (*lastPayload_ptr)->next;
    payload_ptr = *lastPayload_ptr;

    if (transform_ptr->m13 == 0 && transform_ptr->m23 == 0)
    {
        /* Can be TRANSFORM_ISOTROPIC_SCALE or TRANSFORM_ANISOTROPIC_SCALE */
        if (transform_ptr->m11 == transform_ptr->m22)
        {
            /* Is TRANSFORM_ISOTROPIC_SCALE */
            payload_ptr->data[payload_ptr->cur_length++] = TRANSFORM_ISOTROPIC_SCALE;
            putFloat(transform_ptr->m11, payload_ptr);
        } else {
            /* Is TRANSFORM_ANISOTROPIC_SCALE */
            payload_ptr->data[payload_ptr->cur_length++] = TRANSFORM_ANISOTROPIC_SCALE;
            putFloat(transform_ptr->m11, payload_ptr);
            putFloat(transform_ptr->m22, payload_ptr);
        }
    } else {
        /* Can be TRANSFORM_TRANSLATE or TRANSFORM_SCALE_AND_TRANSLATE or TRANSFORM */
        if (transform_ptr->m12 == 0 && transform_ptr->m21 == 0)
        {
            /* Can be TRANSFORM_TRANSLATE or TRANSFORM_SCALE_AND_TRANSLATE */
            if (transform_ptr->m11 == 0 && transform_ptr->m22 == 0)
            {
                /* Is TRANSFORM_TRANSLATE */
                payload_ptr->data[payload_ptr->cur_length++] = TRANSFORM_TRANSLATE;
                putFloat(transform_ptr->m13, payload_ptr);
                putFloat(transform_ptr->m23, payload_ptr);
            } else {
                /* Is TRANSFORM_SCALE_AND_TRANSLATE */
                payload_ptr->data[payload_ptr->cur_length++] = TRANSFORM_SCALE_AND_TRANSLATE;
                putFloat(transform_ptr->m11, payload_ptr);
                putFloat(transform_ptr->m22, payload_ptr);
                putFloat(transform_ptr->m13, payload_ptr);
                putFloat(transform_ptr->m23, payload_ptr);
            }
        } else {
            /* Is TRANSFORM */
            payload_ptr->data[payload_ptr->cur_length++] = TRANSFORM;
            putFloat(transform_ptr->m11, payload_ptr);
            putFloat(transform_ptr->m21, payload_ptr);
            putFloat(transform_ptr->m12, payload_ptr);
            putFloat(transform_ptr->m22, payload_ptr);
            putFloat(transform_ptr->m13, payload_ptr);
            putFloat(transform_ptr->m23, payload_ptr);
        }
    }

    /* update blockPayloadSize */
    *blockPayloadSize += payload_ptr->cur_length;

    return err;
}



/*******************************************************************************
 * \brief Create Strokes Tags
 *
 * Create a payload structure containing one or more Strokes.
 *
 * \param lastpayload_ptr   pointer on the last element where we should put
 *                          those tags
 * \param strokes           pointer on a list of strokes
 * \param ptrDA             pointer on a list of Drawing Attributes
 * \param transformList_ptr pointer to a list of transforms.
 * \param payloadSize       integer we're going to increase by the size of the
 *                          strokes tag(s)
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createStrokesTags(
        payload_t ** lastPayload_ptr,
        stroke_t * strokes,
        drawAttrs_t * ptrDA,
        transform_t * transformList_ptr,
        INT64 * globalPayloadSize)
{
    int err = OK,
    curDA = 0,
    curT = 0;
    stroke_t * s_ptr = strokes;
    transform_t * t_ptr = transformList_ptr;
    drawAttrs_t * da_ptr = ptrDA;

    while (s_ptr)
    {
        /* Does it needs a DIDX */
        if (da_ptr != s_ptr->drawAttrs)
        {
            /* we need to add a DIDX tag */
            da_ptr = ptrDA;
            curDA = 0;
            while ( da_ptr && da_ptr != s_ptr->drawAttrs )
            {
                curDA++;
                da_ptr = da_ptr->next;
            }
            err = createPayload(&((*lastPayload_ptr)->next), 11, NULL);
            if (err != OK) return err;

            *lastPayload_ptr = (*lastPayload_ptr)->next;

            (*lastPayload_ptr)->data[(*lastPayload_ptr)->cur_length++] = DIDX;
            encodeMBUINT( curDA, *lastPayload_ptr);
            *globalPayloadSize += (*lastPayload_ptr)->cur_length;
        }

        /* Does it need a TIDX ?*/
        /* TODO : change stroke_t : add a field to match that transform
         */
        if (t_ptr)
        {
            /* we need to add a TIDX tag */
        }

        err = createStrokeTag(lastPayload_ptr, s_ptr, globalPayloadSize);
        if (err != OK) return err;

        s_ptr = s_ptr->next;
    }
    return err;
}



/*******************************************************************************
 * \brief Create a Stroke Tag
 *
 * Create a payload structure containing a stroke tags.
 *
 * \param lastpayload_ptr   pointer on the last element where we should put that
 *                          data
 * \param s_ptr             pointer to the stroke we're going to proceed on.
 * \param globalpayloadSize integer we're going to increase by the size of the
 *                          stroke tag
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createStrokeTag (
        payload_t ** lastPayload_ptr,
        stroke_t * s_ptr,
        INT64 * globalPayloadSize)
{
    int err = OK;
    payload_t * headerPayload_ptr;
    INT64 payloadSize = 0;

    if ( !s_ptr->X || !s_ptr->Y )
        return STROKES_T_INVALID;

    /* create the payload where we put tag id + payloadsize */
    err = createPayload(&(*lastPayload_ptr)->next, 11, NULL);
    if (err != OK) return err;

    /* save the @ of the struct where we put tag id */
    *lastPayload_ptr = (*lastPayload_ptr)->next;
    headerPayload_ptr = *lastPayload_ptr;

    /* create the payload where we put only the packet number */
    err = createPayload(&(*lastPayload_ptr)->next, 10, NULL);
    if (err != OK) return err;

    *lastPayload_ptr = (*lastPayload_ptr)->next;

    /* Add packet Number */
    printf("s_ptr->nPoints=%lld\n",s_ptr->nPoints);
    encodeMBUINT(s_ptr->nPoints, *lastPayload_ptr);
    payloadSize = (*lastPayload_ptr)->cur_length;

    /* Add X coordinates */
    err = createPacketData(lastPayload_ptr, s_ptr->nPoints, s_ptr->X, &payloadSize);

    /* Add Y coordinates */
    err = createPacketData(lastPayload_ptr, s_ptr->nPoints, s_ptr->Y, &payloadSize);

    /* Add pressure information if there's such one */
    if (s_ptr->P)
    {
        err = createPacketData(lastPayload_ptr, s_ptr->nPoints, s_ptr->P, &payloadSize);
    }

    /* Add header tag */
    headerPayload_ptr->data[0] = STROKE;
    headerPayload_ptr->cur_length = 1;
    encodeMBUINT(payloadSize, headerPayload_ptr);
    /* update globalPayloadSize */
    *globalPayloadSize += payloadSize + headerPayload_ptr->cur_length;

    return err;
}
