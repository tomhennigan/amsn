/*
		File : TkCximage.cpp

		Description :	Contains all functions for the Tk extension for the CxImage utility

		Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
*/




static int ChanMatch (Tcl_Channel chan, CONST char *fileName, Tcl_Obj *format,int *widthPtr,
					  int *heightPtr, Tcl_Interp *interp) 
{
	CxImage image;


	if (image.Load(fileName, CXIMAGE_FORMAT_UNKNOWN)) {
		*widthPtr = image.GetWidth();
		*heightPtr = image.GetHeight();
		return true;
	} 

	return false;
}
					  
					  
static int ObjMatch (Tcl_Obj *data, Tcl_Obj *format, int *widthPtr, int *heightPtr, Tcl_Interp *interp) {

	BYTE * buffer = NULL;
	int length = 0;

	CxImage image;

	buffer = Tcl_GetByteArrayFromObj(data, &length);

	if (image.Decode(buffer, length, CXIMAGE_FORMAT_GIF)) {
		*widthPtr = image.GetWidth();
		*heightPtr = image.GetHeight();
		return true;
	} 	
	if (image.Decode(buffer, length, CXIMAGE_FORMAT_PNG)) {
		*widthPtr = image.GetWidth();
		*heightPtr = image.GetHeight();
		return true;
	} 
	if (image.Decode(buffer, length, CXIMAGE_FORMAT_JPG)) {
		*widthPtr = image.GetWidth();
		*heightPtr = image.GetHeight();
		return true;
	} 
	if (image.Decode(buffer, length, CXIMAGE_FORMAT_TGA)) {
		*widthPtr = image.GetWidth();
		*heightPtr = image.GetHeight();
		return true;
	} 
	if (image.Decode(buffer, length, CXIMAGE_FORMAT_BMP)) {
		*widthPtr = image.GetWidth();
		*heightPtr = image.GetHeight();
		return true;
	} 

	return false;
}

static int ChanRead (Tcl_Interp *interp, Tcl_Channel chan, CONST char *fileName, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
					 int destX, int destY, int width, int height, int srcX, int srcY) 
{
	CxImage image;


	if (!image.Load(fileName, CXIMAGE_FORMAT_UNKNOWN))
		return TCL_ERROR;
	else
        return ImageRead(interp, image, imageHandle, destX, destY, width, height, srcX, srcY);

}

static int ObjRead (Tcl_Interp *interp, Tcl_Obj *data, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
					int destX, int destY, int width, int height, int srcX, int srcY) 
{
	BYTE * buffer = NULL;
	int length = 0;

	CxImage image;

	buffer = Tcl_GetByteArrayFromObj(data, &length);

	if (! image.Decode(buffer, length, CXIMAGE_FORMAT_GIF) && 
		! image.Decode(buffer, length, CXIMAGE_FORMAT_PNG) && 
		! image.Decode(buffer, length, CXIMAGE_FORMAT_JPG) &&
	    ! image.Decode(buffer, length, CXIMAGE_FORMAT_TGA) &&
		! image.Decode(buffer, length, CXIMAGE_FORMAT_BMP)) 
		return TCL_ERROR;
	else
		return ImageRead(interp, image, imageHandle, destX, destY, width, height, srcX, srcY);
}

static int ImageRead(Tcl_Interp *interp, CxImage image, Tk_PhotoHandle imageHandle, int destX, int destY,
					 int width, int height, int srcX, int srcY) 
{

	BYTE * buffer = NULL;
	BYTE * pixelPtr = NULL;
	long size = 0;


	if(!image.Crop(srcX, srcY, srcX + width, srcY + height)) {
		Tcl_AppendResult(interp, image.GetLastError(), NULL);
		return TCL_ERROR;
	}
	if(!image.Flip()) {
		Tcl_AppendResult(interp, image.GetLastError(), NULL);
		return TCL_ERROR;
	}
	if(!image.Encode2RGBA(buffer, size)) {
		Tcl_AppendResult(interp, image.GetLastError(), NULL);
		return TCL_ERROR;
	}

	pixelPtr = (BYTE *) malloc(size);
	memcpy(pixelPtr, buffer, size);

	Tk_PhotoImageBlock block = {
		pixelPtr,		// pixel ptr
		width,
		height,
		width*4,	// pitch : number of bytes separating 2 adjacent pixels vertically
		4,			// pixel size : size in bytes of one pixel .. 4 = RGBA
	};

	block.offset[0] = 0;
	block.offset[1] = 1;
	block.offset[2] = 2;

	if (image.AlphaIsValid()) 
		block.offset[3] = 3;

#if TK_MINOR_VERSION == 4
	Tk_PhotoPutBlock(imageHandle, &block, destX, destY, width, height, TK_PHOTO_COMPOSITE_OVERLAY);
#else 
#if TK_MINOR_VERSION == 5
	Tk_PhotoPutBlock((Tcl_Interp *) NULL, imageHandle, &block, destX, destY, width, height, TK_PHOTO_COMPOSITE_OVERLAY);
#endif
#endif

	image.FreeMemory(buffer);

	return TCL_OK;
}

static int ChanWrite (Tcl_Interp *interp, CONST char *fileName, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr) {

	CxImage image;
	int Type = CXIMAGE_FORMAT_UNKNOWN;
	char * cxFormat = NULL;

	if (format) {
		cxFormat = Tcl_GetStringFromObj(format, NULL);
		Type = GetFileTypeFromFormat(cxFormat);
	} 

	if (Type == CXIMAGE_FORMAT_UNKNOWN) {
		Type = GetFileTypeFromFileName((char *) fileName);
	}

	if (Type == CXIMAGE_FORMAT_UNKNOWN) {
		Type = CXIMAGE_FORMAT_GIF;
	}

	RGB2BGR(blockPtr);

	if(!image.CreateFromArray(blockPtr->pixelPtr, blockPtr->width, blockPtr->height, 
		8 * blockPtr->pixelSize, blockPtr->pitch, true))
	{
		Tcl_AppendResult(interp, image.GetLastError(), NULL);
		return TCL_ERROR;
	}


	if (Type == CXIMAGE_FORMAT_GIF) 
		image.DecreaseBpp(8, true);

	if (!image.Save(fileName, Type)) {
		Tcl_AppendResult(interp, image.GetLastError(), NULL);
		return TCL_ERROR;
	}

	return TCL_OK;
}

static int StringWrite (Tcl_Interp *interp, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr) {

	BYTE * buffer = NULL;
	long size = 0;
	int Type = CXIMAGE_FORMAT_UNKNOWN;
	char * cxFormat = NULL;
	CxImage image;

	if (format) {
		cxFormat = Tcl_GetStringFromObj(format, NULL);
		Type = GetFileTypeFromFormat(cxFormat);
	} 
	
	if (Type == CXIMAGE_FORMAT_UNKNOWN) {
		Type = CXIMAGE_FORMAT_GIF;
	}

	RGB2BGR(blockPtr);

	if(!image.CreateFromArray(blockPtr->pixelPtr, blockPtr->width, blockPtr->height, 
		8 * blockPtr->pixelSize, blockPtr->pitch, true)) 
	{
		Tcl_AppendResult(interp, image.GetLastError(), NULL);
		return TCL_ERROR;
	}



	if (Type == CXIMAGE_FORMAT_GIF)
		image.DecreaseBpp(8, true);

		
	if (!image.Encode(buffer, size, Type) ) {		
		Tcl_AppendResult(interp, image.GetLastError(), NULL);
		return TCL_ERROR;
	}

	Tcl_ResetResult(interp);
	Tcl_AppendResult(interp, buffer);

	image.FreeMemory(buffer);

	return TCL_OK;
}
