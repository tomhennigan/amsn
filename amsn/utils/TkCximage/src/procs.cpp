/*
  File : TkCximage.cpp

  Description :	Contains all functions for the Tk extension for the CxImage utility

  Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
*/


// Include the header file

#include "TkCximage.h"



/*
  Function : Tk_Convert

  Description :	This function converts an input file to an output file depending on the extension

  Arguments   :	ClienData clientdata  :	who knows what's that used for :P 
  anways, it's set to NULL and it's not used (supposed to be aditional arguments)

  Tcl_Interp *interp    :	This is the interpreter that called this function
  it will be used to get some info about the window used

  int objc			  :	This is the number of arguments given to the function

  Tcl_Obj *CONST objv[] : This is the array that contains all arguments given to
  the function

  Return value : TCL_OK in case everything is ok, or TCL_ERROR in case there is an error

  Comments     : Uses CxImage class

*/
static int Tk_Convert (ClientData clientData,
		       Tcl_Interp *interp,
		       int objc,
		       Tcl_Obj *CONST objv[]) 
{
	

  CxImage image;
  char *In = NULL,
    *Out = NULL;

  int InType = 0;
  int OutType = 0;
    

  // We verify the arguments, we must have one arg, not more
  if( objc != 3) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::CxImage::Convert FilenameIn FilenameOut\"" , (char *) NULL);
    return TCL_ERROR;
  }
	
	
  // Get the first argument string (object name) and check it 
  In = Tcl_GetStringFromObj(objv[1], NULL);
  Out = Tcl_GetStringFromObj(objv[2], NULL);

  InType = GetFileTypeFromFileName(In);
  OutType = GetFileTypeFromFileName(Out);

  if(!image.Load(In, InType) ) {
	
    if(!image.Load(In, CXIMAGE_FORMAT_UNKNOWN)) {
      Tcl_AppendResult(interp, image.GetLastError(), NULL);
      return TCL_ERROR;
    }
  }

  if (OutType == CXIMAGE_FORMAT_UNKNOWN)
    OutType = CXIMAGE_FORMAT_GIF;
	
  if (OutType == CXIMAGE_FORMAT_GIF) 
    image.DecreaseBpp(8, true);
	
  if (image.Save(Out, OutType))
    return TCL_OK;
  else {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }

	
  return TCL_OK;

}

static int Tk_Resize (ClientData clientData,
		      Tcl_Interp *interp,
		      int objc,
		      Tcl_Obj *CONST objv[]) 
{
	

  CxImage image;
  char *ImageName = NULL;
  Tk_PhotoHandle Photo;
  Tk_PhotoImageBlock photoData;

  BYTE * buffer = NULL;
  BYTE * pixelPtr = NULL;
  BYTE * pixelPtrCopy = NULL;
  long size = 0;

  int alpha = 0;
  int width = 0;
  int height = 0;
    

  // We verify the arguments, we must have one arg, not more
  if( objc != 4) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::CxImage::Resize photoImage_name new_width new_height\"" , (char *) NULL);
    return TCL_ERROR;
  }
	
	
  // Get the first argument string (object name) and check it 
  ImageName = Tcl_GetStringFromObj(objv[1], NULL);
	
  if( Tcl_GetIntFromObj(interp, objv[2], &width) == TCL_ERROR)
    return TCL_ERROR;
  if( Tcl_GetIntFromObj(interp, objv[3], &height) == TCL_ERROR) 
    return TCL_ERROR;

  if ( (Photo = Tk_FindPhoto(interp, ImageName)) == NULL) {
    Tcl_AppendResult(interp, "The image you specified is not a valid photo image", NULL);
    return TCL_ERROR;
  }

  Tk_PhotoGetImage(Photo, &photoData);

  pixelPtrCopy = (BYTE *) malloc(photoData.width * photoData.height * photoData.pixelSize);

  if (RGB2BGR(&photoData, pixelPtrCopy)) {
    alpha = 1;
  }

  if(!image.CreateFromArray(pixelPtrCopy, photoData.width, photoData.height, 
			    8 * photoData.pixelSize, photoData.pitch, true))
    {
      free(pixelPtrCopy);
      Tcl_AppendResult(interp, image.GetLastError(), NULL);
      return TCL_ERROR;
    }

  free(pixelPtrCopy);

  if(alpha == 0 ) 
    image.AlphaDelete();

  if(!image.Resample(width, height)) {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }

  Tk_PhotoBlank(Photo);

#if TK_MINOR_VERSION == 3
  Tk_PhotoSetSize(Photo, width, height);
#else 
#if TK_MINOR_VERSION == 4
  Tk_PhotoSetSize(Photo, width, height);
#else 
#if TK_MINOR_VERSION == 5
  Tk_PhotoSetSize(interp, Photo, width, height);
#endif
#endif
#endif


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

#if TK_MINOR_VERSION == 3
	Tk_PhotoPutBlock(Photo, &block, 0, 0, width, height);
#else 
#if TK_MINOR_VERSION == 4
  Tk_PhotoPutBlock(Photo, &block, 0, 0, width, height, TK_PHOTO_COMPOSITE_OVERLAY);
#else 
#if TK_MINOR_VERSION == 5
  Tk_PhotoPutBlock((Tcl_Interp *) NULL, Photo, &block, 0, 0, width, height, TK_PHOTO_COMPOSITE_OVERLAY);
#endif
#endif
#endif

  image.FreeMemory(buffer);

  return TCL_OK;

}


static int Tk_Thumbnail (ClientData clientData,
			 Tcl_Interp *interp,
			 int objc,
			 Tcl_Obj *CONST objv[]) 
{
	
  XColor *Color;
  RGBQUAD CxColor;
  CxImage image;
  char *ImageName = NULL;
  Tk_PhotoHandle Photo;
  Tk_PhotoImageBlock photoData;

  BYTE * buffer = NULL;
  BYTE * pixelPtr = NULL;
  BYTE * pixelPtrCopy = NULL;
  long size = 0;
  int alpha = 0;
  int alphaopt = 255;

  int width = 0;
  int height = 0;
    

  // We verify the arguments, we must have one arg, not more
  if( objc < 5 || (objc > 5 && objc != 7)) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::CxImage::Resize photoImage_name new_width new_height bordercolor ?-alpha value? \"" , (char *) NULL);
    return TCL_ERROR;
  }
	
	
  // Get the first argument string (object name) and check it 
  ImageName = Tcl_GetStringFromObj(objv[1], NULL);
	
  if( Tcl_GetIntFromObj(interp, objv[2], &width) == TCL_ERROR)
    return TCL_ERROR;
  if( Tcl_GetIntFromObj(interp, objv[3], &height) == TCL_ERROR) 
    return TCL_ERROR;

  if( (Color = Tk_AllocColorFromObj(interp, Tk_MainWindow(interp), objv[4])) == NULL) {
    Tcl_AppendResult(interp, "Invalid Color for background", NULL);
    return TCL_ERROR;
  }

  if ( objc > 5) {
    if (strcmp("-alpha", Tcl_GetStringFromObj(objv[5], NULL))) {
      Tcl_AppendResult(interp, "Wrong option, should be \"-alpha\"", NULL);
      return TCL_ERROR;
    }
    if( Tcl_GetIntFromObj(interp, objv[6], &alphaopt) == TCL_ERROR) 
      return TCL_ERROR;

    alphaopt = alphaopt % 256;

  }

  Photo = Tk_FindPhoto(interp, ImageName);

  Tk_PhotoGetImage(Photo, &photoData);

  pixelPtrCopy = (BYTE *) malloc(photoData.width * photoData.height * photoData.pixelSize);

  if (RGB2BGR(&photoData, pixelPtrCopy)) {
    alpha = 1;
  }

  if(!image.CreateFromArray(pixelPtrCopy, photoData.width, photoData.height, 
			    8 * photoData.pixelSize, photoData.pitch, true) )
    {
      free(pixelPtrCopy);
      Tcl_AppendResult(interp, image.GetLastError(), NULL);
      return TCL_ERROR;
    }
  free(pixelPtrCopy);

  if(alpha == 0 && alphaopt != 255) 
    image.AlphaDelete();
  else if (alpha == 0 && alphaopt != 255) {
    image.AlphaDelete();
    image.AlphaCreate();
  } else {
    image.AlphaCreate();
  }

  CxColor.rgbBlue = (BYTE) Color->blue;
  CxColor.rgbGreen = (BYTE) Color->green;
  CxColor.rgbRed = (BYTE) Color->red;
  CxColor.rgbReserved = alphaopt;

  if(!image.Thumbnail(width, height, CxColor)) {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }

  Tk_PhotoBlank(Photo);

#if TK_MINOR_VERSION == 3
  Tk_PhotoSetSize(Photo, width, height);
#else 
#if TK_MINOR_VERSION == 4
  Tk_PhotoSetSize(Photo, width, height);
#else 
#if TK_MINOR_VERSION == 5
  Tk_PhotoSetSize(interp, Photo, width, height);
#endif
#endif
#endif


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

#if TK_MINOR_VERSION == 3
  Tk_PhotoPutBlock(Photo, &block, 0, 0, width, height);
#else 
#if TK_MINOR_VERSION == 4
  Tk_PhotoPutBlock(Photo, &block, 0, 0, width, height, TK_PHOTO_COMPOSITE_OVERLAY);
#else 
#if TK_MINOR_VERSION == 5
  Tk_PhotoPutBlock((Tcl_Interp *) NULL, Photo, &block, 0, 0, width, height, TK_PHOTO_COMPOSITE_OVERLAY);
#endif
#endif
#endif

  image.FreeMemory(buffer);
	
  return TCL_OK;

}



