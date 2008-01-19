#include	<stdio.h>
#include	<stdlib.h>
#include	<stdarg.h>

#include	"libISF.h"
#include	"DecodeISF.h"
#include	"createISF.h"
#include	"misc.h"

/******************************************************************************
 *                               DECODING                                     *
 ******************************************************************************/

/*******************************************************************************
 * \brief Get an ISF structure from a stream
 *
 * \param pISF pointer where we construct the ISF structure
 * \param streamInfo data structure where informations about the stream are
 *                   stored
 * \param pGetUChar function used to get an unsigned char from a stream.
 *
 *
 * \returns the error code given while processing
 ******************************************************************************/
int getISF (
        ISF_t ** pISF,
        void * streamInfo,
        int (*pGetUChar) (void *, INT64 *, unsigned char*))
{
    int err = OK; /* the error code */
    INT64 tag; /* number of the current tag */
    decodeISF_t * pDecISF;

    /* we init the ISF structure */
    *pISF = (ISF_t *) malloc (sizeof(ISF_t));
    if (!*pISF)
        return OUT_OF_MEMORY;

    pDecISF = (decodeISF_t *) malloc(sizeof(decodeISF_t));
    if (!pDecISF)
    {
        free(*pISF);
        pISF = NULL;
        return OUT_OF_MEMORY;
    }
    pDecISF->streamInfo = streamInfo;
    pDecISF->getUChar = pGetUChar;
    pDecISF->ISF = *pISF;
    pDecISF->lastStroke = pDecISF->lastHighlighterStroke = &((*pISF)->strokes);
    (*pISF)->strokes = NULL;
    pDecISF->gotStylusPressure = 0;

    /* Add default Transform */
    err = createTransform(&pDecISF->transforms);
    if (err != OK)
        return err;
    pDecISF->curTransform = pDecISF->transforms;
    pDecISF->lastTransform = &pDecISF->transforms;

    /* Add default drawing attributes */
    err = createDrawingAttrs(&(*pISF)->drawAttrs);
    if (err != OK)
        return err;
    pDecISF->curDrawAttrs = (*pISF)->drawAttrs;
    pDecISF->lastDrawAttrs = &(*pISF)->drawAttrs;

    (*pISF)->width = (*pISF)->height = 0;
    (*pISF)->xOrigin = (*pISF)->yOrigin = INT64_MAX;
    (*pISF)->xEnd = (*pISF)->yEnd = INT64_MIN;
    (*pISF)->penWidthMax = (*pISF)->penHeightMax = 0;



    /* Checking the header of that file */
    err = checkHeader (pDecISF);

    while ( err == OK && pDecISF->bytesRead < pDecISF->fileSize )
    {
        err = readMBUINT(pDecISF, &tag);
        switch (tag)
        {
            case INK_SPACE_RECT:
                LOG(stderr,"\nINK_SPACE_RECT\n");
                /* TODO: nothing ?? */
                break;

            case GUID_TABLE:
                LOG(stdout,"\nGUID_TABLE\n");
                err =  getGUIDTable (pDecISF);
                break;

            case DRAW_ATTRS_TABLE:
                LOG(stdout,"\nDRAW_ATTRS_TABLE\n");
                err = getDrawAttrsTable (pDecISF);
                break;

            case DRAW_ATTRS_BLOCK:
                LOG(stdout,"\nDRAW_ATTRS_BLOCK\n");
                err = getDrawAttrsBlock (pDecISF);
                break;

            case STROKE_DESC_TABLE:
                LOG(stderr,"\nSTROKE_DESC_TABLE\n");
                /* TODO */
                break;

            case STROKE_DESC_BLOCK:
                LOG(stdout,"\nSTROKE_DESC_BLOCK\n");
                err = getStrokeDescBlock (pDecISF);
                break;

            case BUTTONS:
                LOG(stderr,"\nBUTTONS\n");
                /* TODO */
                break;

            case NO_X:
                LOG(stderr,"\nNO_X\n");
                /* TODO */
                break;

            case NO_Y:
                LOG(stderr,"\nNO_Y\n");
                /* TODO */
                break;

            case DIDX:
                LOG(stdout,"\nDIDX\n");
                err = getDIDX (pDecISF);
                break;

            case STROKE:
                LOG(stdout,"\nSTROKE\n");
                err = getStroke (pDecISF);
                break;

            case STROKE_PROPERTY_LIST:
                LOG(stderr,"\nSTROKE_PROPERTY_LIST\n");
                /* TODO */
                break;

            case POINT_PROPERTY:
                LOG(stderr,"\nPOINT_PROPERTY\n");
                /* TODO */
                break;

            case SIDX:
                LOG(stderr,"\nSIDX\n");
                /* TODO */
                break;

            case COMPRESSION_HEADER:
                LOG(stderr,"\nCOMPRESSION_HEADER\n");
                /* TODO */
                break;

            case TRANSFORM_TABLE:
                LOG(stdout,"\nTRANSFORM_TABLE\n");
                err = getTransformTable (pDecISF);
                break;

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

            case TIDX:
                LOG(stdout,"\nTIDX\n");
                err = getTIDX (pDecISF);
                break;

            case METRIC_TABLE:
                LOG(stderr,"\nMETRIC_TABLE\n");
                /* TODO */
                break;

            case METRIC_BLOCK:
                LOG(stdout,"\nMETRIC_BLOCK\n");
                err = getMetricBlock (pDecISF);
                break;

            case MIDX:
                LOG(stderr,"\nMIDX\n");
                /* TODO */
                break;

            case MANTISSA:
                LOG(stderr,"\nMANTISSA\n");
                /* TODO */
                break;

            case PERSISTENT_FORMAT:
                LOG(stdout,"\nPERSISTENT_FORMAT\n");
                err = getPersistentFormat (pDecISF);
                break;

            case HIMETRIC_SIZE:
                LOG(stdout,"\nHIMETRIC_SIZE\n");
                err = getHimetricSize (pDecISF);
                break;

            case STROKE_IDS:
                LOG(stdout,"\nSTROKE_IDS\n");
                err = getStrokeIds (pDecISF);
                break;

            case 31:
                LOG(stdout,"\nTAG_31\n");
                err = getUnknownTag (pDecISF);
                break;

            default:
                if (tag >= 100 && tag <= pDecISF->guidIdMax)
                {
                    /* There's a GUID for that tag */
                    LOG(stdout,"\nGUID_%lld\n",tag);
                    err = getProperty (pDecISF, tag);
                } else {
                    LOG(stderr,"/!\\[MAIN] Oops, wrong flag found: %lld\n", tag);
                }
        }
    }
    /* pDecISF is no longer needed : decoding is finished */
    freeDecodeISF(pDecISF);

    return err;
}


/*******************************************************************************
 * \brief check the header of the ISF file
 *
 * We check if the file is a ISF. \n
 * We get the number of Bytes to read.
 *
 * \param pDecISF structure used to decode the ISF file.
 *
 * \returns the error code given while processing
 ******************************************************************************/
int checkHeader (decodeISF_t * pDecISF)
{
    int err = OK; /* the error code */
    INT64 value;

    /* get the first MBUINT of the stream into value */
    err = readMBUINT(pDecISF, &value);

    /* File begins by a 0 */
    if (value != 0)
    {
        LOG(stderr,"File is not in ISF\n");
        return FILE_NOT_ISF;
    }
    /* get the payload size of the file */
    err = readMBUINT(pDecISF, &value);
    pDecISF->fileSize = value + pDecISF->bytesRead;
    LOG(stdout,"File Size: %ld\n", pDecISF->fileSize);

    return err;
}





/*******************************************************************************
 * \brief Create and init a drawing attributes structure.
 *
 * We create a drawing attributes structure and we set it with default values.
 *
 * \param pDA pointer where we create the drawing attributes structure.
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createDrawingAttrs(drawAttrs_t ** pDA)
{
    int err = OK;
    drawAttrs_t * ptrDA = (drawAttrs_t *) malloc(sizeof(drawAttrs_t));

    if (ptrDA)
    {
        ptrDA->penWidth = (float) DEFAULT_PEN_WIDTH;
        ptrDA->penHeight = (float) DEFAULT_PEN_HEIGHT;
        ptrDA->color = DEFAULT_COLOR;
        ptrDA->flags = DEFAULT_FLAGS;
        ptrDA->nStrokes = 0;
        ptrDA->next = NULL;
        *pDA = ptrDA;
    } else {
        *pDA = NULL;
        err = OUT_OF_MEMORY;
    }
    return err;
}



/*******************************************************************************
 * Search for a Drawing Attributes structure in a list
 *
 * \param pDA_list  list of drawAttrs_t structures to search on
 * \param penWidth  width of the pencil searched
 * \param penHeight height of the pencil searched
 * \param color     color searched
 * \param flags     flags searched
 *
 * \returns a NULL pointer or the searched structure
 ******************************************************************************/
drawAttrs_t *
searchDrawingAttrsFor (
        drawAttrs_t * pDA_list,
        float penWidth,
        float penHeight,
        unsigned int color,
        unsigned short flags
        )
{
    drawAttrs_t * curDA = pDA_list;
    while (curDA 
           && abs(penWidth - curDA->penWidth) > 0.3
           && abs(penHeight - curDA->penHeight) > 0.3
           && color != curDA->color
           && flags != curDA->flags) 
    {
        curDA = curDA->next;
    }
    return curDA;
}


/*******************************************************************************
 * \brief Create and init a transformation structure.
 *
 * We create a transformation structure and we set it with default values.\n
 * The default matrix is Identity
 *
 * \param pTransform pointer where we create the transformation structure.
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createTransform(transform_t ** pTransform)
{
    int err = OK;
    transform_t * ptrT = (transform_t *) malloc(sizeof(transform_t));

    if (ptrT)
    {
        /* the default matrix is Identity */
        ptrT->m11 = ptrT->m22 = 1;
        ptrT->m12 = ptrT->m21 = ptrT->m13 = ptrT->m23 = 0;
        ptrT->next = NULL;
        *pTransform = ptrT;
    } else {
        *pTransform = NULL;
        err = OUT_OF_MEMORY;
    }
    return err;
}


/*******************************************************************************
 * \brief Create a Stroke structure.
 * 
 * The X and Y field are allocated and can have #size elements.
 * The Pressure field is not allocated.
 *
 * \param pStroke   pointer where we create the stroke structure.
 * \param size      number of points that can fit in that stroke.
 * \param next      pointer to the next stroke structure (Default is NULL).
 * \param drawAttrs pointer to the Drawing Attributes of that stroke
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createStroke(stroke_t ** pStroke, INT64 size, stroke_t * next, 
        drawAttrs_t * drawAttrs)
{
    int err = OK;
    stroke_t * ptrS = (stroke_t *) malloc(sizeof(stroke_t));

    if (ptrS)
    {
        ptrS->xOrigin = ptrS->yOrigin = INT64_MAX;
        ptrS->xEnd = ptrS->yEnd = INT64_MIN;
        ptrS->next = next;
        ptrS->P = NULL;
        ptrS->drawAttrs = drawAttrs;
        ptrS->nPoints = 0;
        if (size)
            ptrS->size = size;
        else
            ptrS->size = DEFAULT_STROKE_SIZE;

        ptrS->X = malloc (ptrS->size * sizeof(INT64));
        if(!ptrS->X)
        {
            free(ptrS);
            ptrS = NULL;
            *pStroke = NULL;
            err = OUT_OF_MEMORY;
        }
        ptrS->Y = malloc (ptrS->size * sizeof(INT64));
        if(!ptrS->Y)
        {
            free(ptrS->X);
            free(ptrS);
            ptrS = NULL;
            *pStroke = NULL;
            err = OUT_OF_MEMORY;
        }
    } else {
        err = OUT_OF_MEMORY;
    }
    *pStroke = ptrS;
    return err;
}


/*******************************************************************************
 * \brief Create a skeleton of an ISF structure.
 *
 * This function creates an ISF_t structure. Its bounding box is 0, but its 
 * width and height are those specified by the arguments.
 * Thoses size are used to described the size of the window used to draw that
 * ink.
 * This ISF_t structure has no strokes, but contains the default drawing 
 * attributes.
 *
 * \param pISF    pointer where we create the ISF structure.
 * \param width   width of the drawing area related to that ISF.
 * \param height  height of the drawing area related to that ISF.
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createSkeletonISF(ISF_t ** pISF, int width, int height)
{
    int err = OK;
    
    *pISF = (ISF_t *) malloc (sizeof(ISF_t));
    if (!*pISF)
        return OUT_OF_MEMORY;

    err = createDrawingAttrs(&((*pISF)->drawAttrs));
    if (err != OK)
        return err;

    (*pISF)->strokes = NULL;

    (*pISF)->xOrigin = (*pISF)->yOrigin = INT64_MAX;
    (*pISF)->xEnd = (*pISF)->yEnd = INT64_MIN;
    (*pISF)->width = width;
    (*pISF)->height = height;
    (*pISF)->penWidthMax = (*pISF)->drawAttrs->penWidth;
    (*pISF)->penHeightMax = (*pISF)->drawAttrs->penHeight;

    return err;
}


/*******************************************************************************
 * \brief Change the zoom level of an ISF structure
 *
 * Change the zoom level of an ISF structure by changing the width and height of
 * each of its elements.\n
 * It changes the size of the pencils and the coordinates of the strokes.\n
 * It is mainly used to change the unit of the ISF : converting Himetres to
 * pixels, or the contrary.
 *
 * \param pISF the ISF structure
 * \param zoom factor used to change the zoom level
 *
 * \returns the error code given while processing
 ******************************************************************************/
void changeZoom (ISF_t * pISF, float zoom)
{
    INT64 i;
    drawAttrs_t * pDrawAttrs = pISF->drawAttrs;
    stroke_t * pStroke = pISF->strokes;

    /* Change Drawing Attributes */
    while (pDrawAttrs)
    {
        pDrawAttrs->penWidth *= zoom;
        pDrawAttrs->penHeight *= zoom;
        pDrawAttrs = pDrawAttrs->next;
    }

    /* Change Strokes */
    while (pStroke)
    {
        /* change coordinates */
        for(i=0; i<pStroke->nPoints; i++)
        {
            *(pStroke->X+i) *= zoom;
            *(pStroke->Y+i) *= zoom;
        }
        /* change bounding box */
        pStroke->xOrigin *= zoom;
        pStroke->yOrigin *= zoom;
        pStroke->xEnd *= zoom;
        pStroke->yEnd *= zoom;

        pStroke = pStroke->next;
    }

    pISF->xOrigin *= zoom;
    pISF->yOrigin *= zoom;
    pISF->xEnd *= zoom;
    pISF->yEnd *= zoom;
    pISF->width *= zoom;
    pISF->height *= zoom;
    pISF->penWidthMax *= zoom;
    pISF->penHeightMax *= zoom;
}

/*******************************************************************************
 * Free an ISF structure
 *
 * \param pISF pointer to the ISF structure we're going to free
 ******************************************************************************/
void freeISF (ISF_t * pISF)
{
    drawAttrs_t * pDrawAttrs,
                * pDrawAttrsNext;
    stroke_t * pStroke,
             * pStrokeNext;
    if (pISF)
    {
        /* Free Drawing Attributes */
        pDrawAttrs = pISF->drawAttrs;
        while (pDrawAttrs)
        {
            pDrawAttrsNext = pDrawAttrs->next;
            free(pDrawAttrs);
            pDrawAttrs = pDrawAttrsNext;
        }
        /* Free the strokes */
        pStroke = pISF->strokes;
        while (pStroke)
        {
            free(pStroke->X);
            free(pStroke->Y);
            free(pStroke->P);/* we can free NULL */
            pStrokeNext = pStroke->next;
            free(pStroke);
            pStroke = pStrokeNext;
        }
        /* Free the ISF struct */
        free(pISF);
    }
}

/*******************************************************************************
 * Free payload_t structures
 *
 * \param pRoot pointer on payload_t list to free
 ******************************************************************************/
void freePayloads (payload_t * pRoot)
{
    payload_t * curPayload = pRoot,
              * nextPayload = NULL;

    /* Free payload_t structures */
    while (curPayload)
    {
        nextPayload = curPayload->next;
        free(curPayload);
        curPayload = nextPayload;
    }
}

/*******************************************************************************
 * Free a decodeISF structure
 *
 * \param pDecISF pointer to the decodeISF structure we're going to free
 ******************************************************************************/
void freeDecodeISF (decodeISF_t * pDecISF)
{
    transform_t * ptrTransform,
                * ptrTransformNext;

    if (pDecISF)
    {
        /* Free Transforms */
        ptrTransform = pDecISF->transforms;
        while (ptrTransform)
        {
            ptrTransformNext = ptrTransform->next;
            free(ptrTransform);
            ptrTransform = ptrTransformNext;
        }
        /* Free the decoding struct */
        free(pDecISF);
    }
}

/*******************************************************************************
 * \brief Send debugging informations
 *
 * It is mainly used to provide informations about the file we're
 * decoding/creating.\n
 * It works like fprintf.
 *
 * \param stream stream where we print the informations
 * \param fmt format describing the informations to print.
 ******************************************************************************/
void LOG (FILE * stream, char * fmt, ...)
{
#ifdef DEBUG
    va_list args;
    va_start(args,fmt);
    vfprintf(stream, fmt, args);
    va_end(args);
#endif
}




/******************************************************************************
 *                               ENCODING                                     *
 ******************************************************************************/


/*******************************************************************************
 * \brief Create a Payload structure
 *
 * Create a payload structure and initiate it.
 *
 * \param payload_ptr pointer on where we put the new payload structure
 * \param size        size in Bytes of the payload
 * \param next_ptr    pointer on the next payload structure
 *                    should be NULL most of the time
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createPayload (payload_t ** payload_ptr, int size, payload_t * next_ptr)
{
    int err = OK;

    *payload_ptr = (payload_t *) malloc(sizeof(payload_t));
    if(!*payload_ptr)
        return OUT_OF_MEMORY;
    (*payload_ptr)->cur_length = 0;
    (*payload_ptr)->size = size;
    (*payload_ptr)->next = next_ptr;
    (*payload_ptr)->data = (unsigned char *) malloc(size * sizeof(unsigned char));
    if (!(*payload_ptr)->data)
        err = OUT_OF_MEMORY;
    return err;
}



/*******************************************************************************
 * \brief Encode an ISF representation into ISF
 *
 * Given an ISF representation (the structure ISF_t which contains a list of
 * strokes, drawing attributes ...), create an ISF "file".
 *
 * \param pISF              pointer on the ISF structure to encode
 * \param rootTag           pointer where the root tag of the file is put.
 * \param transformList_ptr pointer on a list of transformation to apply
 *                          That list can be:
 *                            - empty : no transformation is applied
 *                            - have only one element : this transformation is
 *                              applied to every stroke
 *                            - be as long as the stroke list : each
 *                              transformation matchs the respective stroke.
 * \param fullPayloadSize   pointer on a int where the size of encoded file is
 *                          put.
 *
 * \returns the error code given while processing
 ******************************************************************************/
int createISF (
        ISF_t * pISF,
        payload_t ** rootTag,
        transform_t * transformList_ptr,
        INT64 * fullPayloadSize)
{
    int err = OK;
    drawAttrs_t ** ptrDA = &(pISF->drawAttrs),
                 * ptrDA_tmp;
    INT64 payloadSize = 0;
    payload_t * lastPayload_ptr = NULL;

    err = createPayload(rootTag,
            11,/* 11 B = 1 B (0x00) + 10 B (payload size) */
            NULL);

    if (err == OK)
    {
        lastPayload_ptr = *rootTag;

        /* Drawing attributes */
        /* First, remove useless drawing attributes structures */
        while (*ptrDA)
        {
            if((*ptrDA)->nStrokes == 0)
            {
                /* delete it */
                ptrDA_tmp = *ptrDA;
                *ptrDA = (*ptrDA)->next;
                free(ptrDA_tmp);
            } else {
                ptrDA = &((*ptrDA)->next);
            }
        }
        if (pISF->drawAttrs)
        {
            err = createDrawAttributesTag(
                    &lastPayload_ptr,
                    pISF->drawAttrs,
                    &payloadSize);
            if (err != OK)
                return err;
        }

        /* Transform */
        if (transformList_ptr)
        {

            err = createTransformTag(
                    &lastPayload_ptr,
                    transformList_ptr,
                    &payloadSize);
            if (err != OK)
                return err;
        }

        /* Strokes */
        if(pISF->strokes)
        {
            err = createStrokesTags(
                    &lastPayload_ptr,
                    pISF->strokes,
                    pISF->drawAttrs,
                    transformList_ptr,
                    &payloadSize);
            if (err != OK)
                return err;
        } /* ELSE : WTF ????????? */

        /* write 0x00 as root tag id */
        (*rootTag)->data[0] = 0x00;
        (*rootTag)->cur_length = 1;

        /* write payloadSize */
        encodeMBUINT( payloadSize, *rootTag);

        /* update fullPayloadSize */
        *fullPayloadSize = payloadSize + (*rootTag)->cur_length;

    }
    return err;
}
