#include    <stdio.h>
#include    <stdlib.h>

#include    "tclISF.h"


/*
 * TODO:
 * we should have :
 * tclISF save filename strokes_list
 * tclISF load canvas ?-file filename? ?-data data?
 * be able to choose encoding
 * ...
 */


/*
 * tclISF_Init is called when the package is loaded.
 */
int Tclisf_Init(Tcl_Interp *interp)
{
    /*
     * Initialize the stub table interface
     */
    if (Tcl_InitStubs(interp, TCL_VERSION, 1) == NULL) {
        return TCL_ERROR;
    }

    /*
     * Register the command tclISF_save
     * The tclISF_save command uses the object interface.
     */
    Tcl_CreateObjCommand(interp, "tclISF_save", tclISF_save,
            (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

    /*
     * Declare that we implement the tclISF package
     * so scripts that do "package require tclISF"
     * can load the library automatically.
     */
    Tcl_PkgProvide(interp, "tclISF", "0.1");
    return TCL_OK;
}


/*
 * tclISF_save --
 * Arguments are :
 * filename (string) : filename of the GIF file to fortify
 * strokes_list (list) : list of list which contains coordinates like x y x y ...
 */
int tclISF_save(ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[])
{
    Tcl_Obj ** strokes_vector;


    int filename_length = 0,
        strokes_counter = 0,
        err = 0;

    ISF_t * pISF = NULL;
    payload_t * rootTag = NULL;
    INT64 payloadSize = 0;

    char * filename = NULL;

    if (objc != 3)
    {
        Tcl_WrongNumArgs(interp, 1, objv, "filename strokes_list");
        return TCL_ERROR;
    }

    /* Get the filename */
    filename = Tcl_GetStringFromObj(objv[1], &filename_length);

    /* Get the strokes list */
    if ( Tcl_ListObjGetElements(interp, objv[2], &strokes_counter, &strokes_vector) != TCL_OK )
    {
        /* wrong args */
        sprintf(interp->result, "Wrong arguments given to %s\nThe second parameter is a list", objv[0]);
        return TCL_ERROR;
    }

    /* Generate the ISF structure */
    pISF = getISF_FromTclList(interp, strokes_vector, strokes_counter);
    if (!pISF)
    {
        return TCL_ERROR;
    }

    /* Encode as ISF */
    err = createISF(pISF, &rootTag, NULL, &payloadSize);
    if (err != OK)
    {
        freeISF(pISF);
        sprintf(interp->result, "Got error %d (from createISF) while encoding to ISF to the file %s.", err, filename);
        return TCL_ERROR;
    }

    /* write to file */
    if (writeGIFFortified(interp, filename, rootTag, payloadSize) != TCL_OK)
    {
        free(pISF);
        return TCL_ERROR;
    }

    free(pISF);
    return TCL_OK;
}


/*
 * create an ISF_t structure from the Tcl lists in strokes_vector
 */
ISF_t * getISF_FromTclList (Tcl_Interp *interp, Tcl_Obj ** strokes_vector, int strokes_counter)
{
    int i,j,
        err,
        llength,tmp;
    stroke_t ** lastStroke = NULL;
    stroke_t * pStroke;
    Tcl_Obj ** coords_vector = NULL;
    drawAttrs_t * curDA = NULL;
    ISF_t * pISF = NULL;

    if ( createSkeletonISF(&pISF,0,0) != OK)
        return NULL;

    /* change himetric units to pixels units */
    changeZoom(pISF, (double) 1/HIMPERPX);

    /* default pencil used is 7px large */
    curDA = pISF->drawAttrs;
    curDA->penWidth = curDA->penHeight = 7;

    lastStroke = &(pISF->strokes);

    for (i = 0; i < strokes_counter; i++)
    {
        /* treat each list of coordinates */
        if (Tcl_ListObjGetElements(interp, strokes_vector[i], &llength, &coords_vector) != TCL_OK)
        {
            freeISF(pISF);
            sprintf(interp->result, "Wrong arguments. The strokes_list is a list of lists");
            return NULL;
        }
        llength >>= 1;
        err = createStroke(&pStroke, llength,NULL,pISF->drawAttrs);
        if (err != OK)
        {
            freeISF(pISF);
            sprintf(interp->result, "Got error %d (from createStroke)", err);
            return NULL;
        }
        for (j=0; j<llength; j++)
        {
            /* We don't check for errors here :s */
            /* X */
            Tcl_GetIntFromObj(interp, coords_vector[j<<1], &tmp);
            pStroke->X[j] = (INT64) tmp;

            /* Y */
            Tcl_GetIntFromObj(interp, coords_vector[j<<1|1], &tmp);
            pStroke->Y[j] = (INT64) tmp;
        }
        pStroke->nPoints = (INT64) llength;
        *lastStroke = pStroke;
        lastStroke = &(pStroke->next);
        curDA->nStrokes++;
    }
    
    /* get back to pixels units */
    changeZoom(pISF, (float) HIMPERPX);

    return pISF;
}


/*******************************************************************************
 * \brief Write the ISF content into a GIF file.
 *
 * The considered GIF File should be valid, which means it must finish 
 * with ';'. It shouldn't contain any Comment Extension field.
 *
 * \param interp         the current Tcl interpretor
 * \param filename       filename of the gif file
 * \param rootTag        Head of the payload_t chained list 
 * \param outputFileSize size of the "isf file"
 *
 * \returns TCL_ERROR or TCL_OK.
 ******************************************************************************/
/* TODO : check fwrite errors */
int writeGIFFortified(
        Tcl_Interp * interp,
        const char * filename,
        payload_t * rootTag,
        INT64 outputFileSize)
{
    unsigned char c = 0;
    INT64 pos = 0;
    payload_t * ptrCur = rootTag;
    FILE * fp = fopen(filename, "rb+");

    if (!fp)
    {
        /* OPEN_ERROR */
        sprintf(interp->result, "Can not open the file %s. Can not make it a GIF Fortified file.", filename);
        return TCL_ERROR;
    }
    if (fseek(fp, -1, SEEK_END) != 0)
    {
        fclose(fp);
        sprintf(interp->result, "Can not read the file %s. Can not make it a GIF Fortified file.", filename);
        return TCL_ERROR;
    }

    /* TODO : MAY FAIL. needs improvements */
    /* check if we are at the end of the GIF file */
    fread(&c,1,1,fp);
    if(c != ';')
    {
        /* FILE_CORRUPTED */
        fclose(fp);
        sprintf(interp->result, "The file %s seems corrupted. Can not make it a GIF Fortified file.", filename);
        return TCL_ERROR;
    }

    /* change the end of the file with a Comment Extension */
    fseek(fp, -1, SEEK_CUR);
    c = '!';
    fwrite(&c,1,1,fp);
    c = 0XFE;
    fwrite(&c,1,1,fp);
    /* write the isf struct in the comment */
    while(outputFileSize > 0)
    {   
        /* block size */
        c = MIN(outputFileSize,255);
        outputFileSize -= 255;
        fwrite(&c,1,1,fp);
        do
        {
            if ( ptrCur->cur_length - pos <= c)
            {
                /* finish that payload_t and go to the next one */
                fwrite(ptrCur->data+pos,1,ptrCur->cur_length - pos,fp);
                c -= ptrCur->cur_length - pos;
                /* go to the next payload_t */
                ptrCur = ptrCur->next;
                pos = 0;
            } else {
                /* enough data remaining in that payload_t */
                fwrite(ptrCur->data+pos,1,c,fp);
                pos += c;
                c = 0;
            }
        } while (c>0);
    }
    /* block terminator */
    c = 0;
    fwrite(&c,1,1,fp);
    /* End Of File */
    c = ';';
    fwrite(&c,1,1,fp);

    fclose(fp);
    return TCL_OK;
}

