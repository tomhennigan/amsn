#include    <cstdio>
#include    <cstdlib>

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
	 * Register the command tclISF_main
	 * The tclISF_save command uses the object interface.
	 */
	Tcl_CreateObjCommand(interp, "tclISF", tclISF_main,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	/*
	 * Declare that we implement the tclISF package
	 * so scripts that do "package require tclISF"
	 * can load the library automatically.
	 */
	Tcl_PkgProvide(interp, "tclISF", "0.3");
	return TCL_OK;
}

/*
 * tclISF_main --
 * Check if the command is save or fortify and then perform the corresponding action
 */
int tclISF_main(ClientData clientData, Tcl_Interp *interp,
		int objc, Tcl_Obj *CONST objv[])
{
	const char * cmd = NULL;
	int cmd_length = 0,
		err = TCL_OK;

	if (objc < 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "save filename strokes_list drawingAttributes_list \n fortify filename");
		return TCL_ERROR;
	}

	/* Get the filename */
	cmd = Tcl_GetStringFromObj(objv[1], &cmd_length);
	if (strcmp(cmd, "save")==0)
		err = tclISF_save(clientData,interp,objc-1, objv+1);
	else if (strcmp(cmd, "fortify")==0)
		err = tclISF_fortify(clientData,interp,objc-1,objv+1);
	else {
		Tcl_WrongNumArgs(interp, 1, objv, "save filename strokes_list drawingAttributes_list \n fortify filename");
		return TCL_ERROR;
	}

	return err;
}



/*
 * tclISF_save --
 * Arguments are :
 * filename (string) : filename of the GIF file to fortify
 * strokes_list (list) : list of list which contains coordinates like x y x y ...
 * drawingAttributes_list (list) : list of list which contains drawing attributes:
 *   (pencil_width color)
 */
int tclISF_save(ClientData clientData, Tcl_Interp *interp,
		int objc, Tcl_Obj *CONST objv[])
{
	Tcl_Obj ** strokes_vector;
	Tcl_Obj ** drawAttrs_vector;

	int filename_length = 0,
		strokes_counter = 0,
		drawAttrs_counter = 0,
		err = 0;

	ISF_t * pISF = NULL;
	payload_t * rootTag = NULL;
	INT64 payloadSize = 0;

	const char * filename = NULL;

	if (objc != 4)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "filename strokes_list drawingAttributes_list");
		return TCL_ERROR;
	}
	/* Get the filename */
	filename = Tcl_GetStringFromObj(objv[1], &filename_length);

	/* Get the strokes list */
	if ( Tcl_ListObjGetElements(interp, objv[2], &strokes_counter, &strokes_vector) != TCL_OK )
	{
		/* wrong args */
		Tcl_WrongNumArgs(interp, 0, 0, "Wrong arguments given.\nThe second parameter must be a list");
		return TCL_ERROR;
	}

	/* Get the drawing attributes list */
	if ( Tcl_ListObjGetElements(interp, objv[3], &drawAttrs_counter, &drawAttrs_vector) != TCL_OK )
	{
		/* wrong args */
		Tcl_WrongNumArgs(interp, 0, 0, "Wrong arguments given.\nThe third parameter must be a list");
		return TCL_ERROR;
	}

	if (drawAttrs_counter != strokes_counter )
	{
		/* wrong args */
		Tcl_AppendResult(interp, "Wrong arguments given.\n strokes_list and drawingAttributes_list must have the same length.", 0);
		return TCL_ERROR;
	}

	/* Generate the ISF structure */
	pISF = getISF_FromTclList(interp, strokes_vector, drawAttrs_vector, strokes_counter);
	if (!pISF)
	{
		return TCL_ERROR;
	}

	/* Encode as ISF */
	err = createISF(pISF, &rootTag, NULL, &payloadSize);
	if (err != OK)
	{
        char buffer[15]; //should be enough
		freeISF(pISF);
		freePayloads(rootTag);
        sprintf(buffer,"%s", err);
		Tcl_AppendResult(interp, "Got error ", buffer," (from createISF) while encoding to ISF to the file ",filename, 0);
		return TCL_ERROR;
	}

	/* write to file */
	if (writeGIFFortified(interp, filename, rootTag, payloadSize) != TCL_OK)
	{
		freeISF(pISF);
		freePayloads(rootTag);
		return TCL_ERROR;
	}

	freeISF(pISF);
	freePayloads(rootTag);
	return TCL_OK;
}

unsigned int stringToAABBGGRRColor (char * color_string)
{
	unsigned int r,g,b;
	sscanf(color_string,"#%2x%2x%2x",&r,&g,&b);
	return (r | (g<<8) | (b<<16));
}

/*
 * create an ISF_t structure from the Tcl lists in strokes_vector
 */
ISF_t * getISF_FromTclList (
		Tcl_Interp *interp,
		Tcl_Obj ** strokes_vector,
		Tcl_Obj ** drawAttrs_vector,
		int strokes_counter)
{
	int i,j,
	err,
	llength,tmp;
	stroke_t ** lastStroke = NULL;
	stroke_t * pStroke = NULL;
	Tcl_Obj ** coords_vector = NULL;
	Tcl_Obj ** curDrawAttrs_vector = NULL;
	drawAttrs_t * curDA = NULL;
	ISF_t * pISF = NULL;
	unsigned int color = 0;
	char * color_string = NULL;
	float penwidth;

	if ( createSkeletonISF(&pISF,0,0) != OK)
		return NULL;

	/* change himetric units to pixels units */
	changeZoom(pISF, (double) 1/HIMPERPX);

	/* default pencil used is 3px large in WLM */
	curDA = pISF->drawAttrs;
	curDA->penWidth = curDA->penHeight = 3;

	lastStroke = &(pISF->strokes);

	for (i = 0; i < strokes_counter; i++)
	{
		/* create the drawing attributes for that stroke */
		if (Tcl_ListObjGetElements(interp, drawAttrs_vector[i], &tmp, &curDrawAttrs_vector) != TCL_OK)
		{
			freeISF(pISF);
			Tcl_WrongNumArgs(interp, 0, 0, "Wrong arguments. The drawingAttributes_list is a list of lists");
			return NULL;
		}
		Tcl_GetIntFromObj(interp, curDrawAttrs_vector[0], &tmp);
		penwidth = (float) tmp;
		/* get the color */
		color_string = Tcl_GetStringFromObj(curDrawAttrs_vector[1],&tmp);
		if(tmp == 7 && color_string[0] == '#') /* no transparency for the moment */
			color = stringToAABBGGRRColor(color_string);

		curDA = searchDrawingAttrsFor(
				pISF->drawAttrs,
				penwidth,
				penwidth,
				color,
				DEFAULT_FLAGS);
		if (!curDA)
		{
			/* need to create one */
			if (createDrawingAttrs(&curDA) != OK)
			{
				freeISF(pISF);
				return NULL;
			}
			curDA->penWidth = curDA->penHeight = penwidth;
			curDA->color = color;

			curDA->next = pISF->drawAttrs;
			pISF->drawAttrs = curDA;
		}



		/* treat each list of coordinates */
		if (Tcl_ListObjGetElements(interp, strokes_vector[i], &llength, &coords_vector) != TCL_OK)
		{
			freeISF(pISF);
			Tcl_WrongNumArgs(interp, 0, 0, "Wrong arguments. The strokes_list is a list of lists");
			return NULL;
		}
		llength >>= 1;
		err = createStroke(&pStroke, llength, NULL, curDA);
		if (err != OK)
		{
            char buffer[15];
			freeISF(pISF);
            sprintf(buffer, "%d", err);
			Tcl_AppendResult(interp, "Got error ",buffer," (from createStroke)", 0);
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
		Tcl_AppendResult(interp, "Can not open the file ", filename, ". Can not make it a GIF Fortified file.", 0);
		return TCL_ERROR;
	}
	if (fseek(fp, -1, SEEK_END) != 0)
	{
		fclose(fp);
		Tcl_AppendResult(interp, "Can not read the file ",filename,". Can not make it a GIF Fortified file.", 0);
		return TCL_ERROR;
	}

	/* check if we are at the end of the GIF file */
	if(fread(&c,1,1,fp) != 1)
	{
		fclose(fp);
		Tcl_AppendResult(interp, "Error while reading from file ", filename, 0);
		return TCL_ERROR;
	}
	if(c != ';')
	{
		/* FILE_CORRUPTED */
		fclose(fp);
		Tcl_AppendResult(interp, "The file ",filename," seems corrupted. Can not make it a GIF Fortified file.", 0);
		return TCL_ERROR;
	}

	/* change the end of the file with a Comment Extension */
	if (fseek(fp, -1, SEEK_CUR) != 0)
	{
		fclose(fp);
		Tcl_AppendResult(interp, "Can not read the file ",filename,". Can not make it a GIF Fortified file.", 0);
		return TCL_ERROR;
	}
	c = '!';
	if(fwrite(&c,1,1,fp) != 1)
	{
		fclose(fp);
		Tcl_AppendResult(interp, "Error while writing to file ", filename,". Can not make it a GIF Fortified file.", 0);
		return TCL_ERROR;
	}
	c = 0XFE;
	if (fwrite(&c,1,1,fp) != 1)
	{
		fclose(fp);
		Tcl_AppendResult(interp, "Error while writing to file ", filename,". Can not make it a GIF Fortified file.", 0);
		return TCL_ERROR;
	}
	/* write the isf struct in the comment */
	while(outputFileSize > 0)
	{   
		/* block size */
		c = MIN(outputFileSize,255);
		outputFileSize -= 255;
		if (fwrite(&c,1,1,fp) != 1)
		{
			fclose(fp);
		    Tcl_AppendResult(interp, "Error while writing to file ", filename,". Can not make it a GIF Fortified file.", 0);
			return TCL_ERROR;
		}
		do
		{
			if ( ptrCur->cur_length - pos <= c)
			{
				/* finish that payload_t and go to the next one */
				if (fwrite(ptrCur->data+pos,1,ptrCur->cur_length - pos,fp) != (ptrCur->cur_length - pos))
				{
					fclose(fp);
		            Tcl_AppendResult(interp, "Error while writing to file ", filename,". Can not make it a GIF Fortified file.", 0);
					return TCL_ERROR;
				}
				c -= ptrCur->cur_length - pos;
				/* go to the next payload_t */
				ptrCur = ptrCur->next;
				pos = 0;
			} else {
				/* enough data remaining in that payload_t */
				if (fwrite(ptrCur->data+pos,1,c,fp) != c)
				{
					fclose(fp);
		            Tcl_AppendResult(interp, "Error while writing to file ", filename,". Can not make it a GIF Fortified file.", 0);
					return TCL_ERROR;
				}
				pos += c;
				c = 0;
			}
		} while (c>0);
	}
	/* block terminator */
	c = 0;
	if (fwrite(&c,1,1,fp) != 1)
	{
		fclose(fp);
		Tcl_AppendResult(interp, "Error while writing to file ", filename,". Can not make it a GIF Fortified file.", 0);
		return TCL_ERROR;
	}
	/* End Of File */
	c = ';';
	if (fwrite(&c,1,1,fp) != 1)
	{
		fclose(fp);
		Tcl_AppendResult(interp, "Error while writing to file ", filename,". Can not make it a GIF Fortified file.", 0);
		return TCL_ERROR;
	}

	fclose(fp);
	return TCL_OK;
}

/*
 * tclISF_fortify --
 * Arguments are :
 * filename (string) : filename of the GIF file to fortify
 */
int tclISF_fortify(ClientData clientData, Tcl_Interp *interp,
		int objc, Tcl_Obj *CONST objv[])
{
	const char * filename = NULL;
	int filename_length;

	if (objc != 2)
	{
		Tcl_WrongNumArgs(interp, 1, objv, "filename");
		return TCL_ERROR;
	}

	/* Get the filename */
	filename = Tcl_GetStringFromObj(objv[1], &filename_length);

	//Fortify!
	return fortify(interp, (TCHAR *)filename);
}

// Don't look at that code, it's plain ugly
int fortify(Tcl_Interp *interp, TCHAR * filename)
{
	int height, width;
	ISF_t * pISF;
	transform_t * transform = NULL;
	payload_t * rootTag = NULL;
	INT64 payloadSize = 0;
	int err;

	// 1st load the image
	CxImage image( filename, (DWORD)0);

	err = createSkeletonISF(&pISF, image.GetWidth(), image.GetHeight());
	if (err != OK)
	{
        char buffer[15];
        sprintf(buffer, "%d", err);
		Tcl_AppendResult(interp, "libISF returned error ", buffer," while fortifying ", filename, 0);
		return TCL_ERROR;
	}
	pISF->drawAttrs->penWidth = 1;
	pISF->drawAttrs->penHeight = 1;

	height = image.GetHeight();
	width = image.GetWidth();

	// search the non-transparent pixels in the image    
	for(long y=0; y<height; y++)
	{
		for(long x=0; x<width; x++)
		{
			if (image.GetPixelGray(x,y) < 0x33)
			{
				err = createStroke(&(pISF->strokes),
						2,
						pISF->strokes,
						pISF->drawAttrs);
				pISF->drawAttrs->nStrokes++;
				if (err != OK)
				{
                    char buffer[15];
					freeISF(pISF);
                    sprintf(buffer, "%d", err);
            		Tcl_AppendResult(interp, "libISF returned error ", buffer," while fortifying ", filename, 0);
					return TCL_ERROR;
				}
				pISF->strokes->nPoints = 1;
				pISF->strokes->X[0] = (INT64)x;
				pISF->strokes->Y[0] = (INT64)(height-y);
				do {
					x++;
				} while (x<width && image.GetPixelGray(x,y)<0x33);
				if (x<width && (INT64)x-1 != pISF->strokes->X[0])
				{
					pISF->strokes->nPoints = 2;
					pISF->strokes->X[1] = (INT64)x-1;
					pISF->strokes->Y[1] = (INT64)(height-y);
				}
			}
		}
	}
	err = createTransform(&transform);
	if (err != OK)
	{
        char buffer[15];
		freeISF(pISF);
        sprintf(buffer, "%d", err);
		Tcl_AppendResult(interp, "libISF returned error ", buffer," while fortifying ", filename, 0);
		return TCL_ERROR;
	}
	transform->m11 = transform->m22 = HIMPERPX;
	// encode
	err = createISF(pISF, &rootTag, transform, &payloadSize);
	if (err != OK)
	{
        char buffer[15];
		freeISF(pISF);
        sprintf(buffer, "%d", err);
		Tcl_AppendResult(interp, "libISF returned error ", buffer," while fortifying ", filename, 0);
		return TCL_ERROR;
	}
	// write to the file :
	err = writeGIFFortified(interp, filename, rootTag, payloadSize);
	freeISF(pISF);
	freePayloads(rootTag);
	return err;
}
