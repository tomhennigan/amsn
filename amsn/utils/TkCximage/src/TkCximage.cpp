/*
 * TkCximage Tk extension providing bindings to the CxImage library.
 *
 *    @author : The aMSN Team
 *
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 */


// Include the header file
#include "TkCximage.h"

char currenttime[30];
FILE * logfile;

#define AVAILABLE_FORMATS 6
Tk_PhotoImageFormat cximageFormats[] = {
  {
    "cximage",
    (Tk_ImageFileMatchProc *) ChanMatch,	
    (Tk_ImageStringMatchProc *) ObjMatch,	
    (Tk_ImageFileReadProc *) ChanRead,	
    (Tk_ImageStringReadProc *) ObjRead,	
    (Tk_ImageFileWriteProc *) ChanWrite,	
    (Tk_ImageStringWriteProc *) StringWrite
  },
  {
    "cxgif",
    (Tk_ImageFileMatchProc *) ChanMatch,	
    (Tk_ImageStringMatchProc *) ObjMatch,	
    (Tk_ImageFileReadProc *) ChanRead,	
    (Tk_ImageStringReadProc *) ObjRead,	
    (Tk_ImageFileWriteProc *) ChanWrite,	
    (Tk_ImageStringWriteProc *) StringWrite
  },
  {
    "cxpng",
    (Tk_ImageFileMatchProc *) ChanMatch,	
    (Tk_ImageStringMatchProc *) ObjMatch,	
    (Tk_ImageFileReadProc *) ChanRead,	
    (Tk_ImageStringReadProc *) ObjRead,	
    (Tk_ImageFileWriteProc *) ChanWrite,	
    (Tk_ImageStringWriteProc *) StringWrite
  },
  {
    "cxjpg",
    (Tk_ImageFileMatchProc *) ChanMatch,	
    (Tk_ImageStringMatchProc *) ObjMatch,	
    (Tk_ImageFileReadProc *) ChanRead,	
    (Tk_ImageStringReadProc *) ObjRead,	
    (Tk_ImageFileWriteProc *) ChanWrite,	
    (Tk_ImageStringWriteProc *) StringWrite
  },
  {
    "cxtga",
    (Tk_ImageFileMatchProc *) ChanMatch,	
    (Tk_ImageStringMatchProc *) ObjMatch,	
    (Tk_ImageFileReadProc *) ChanRead,	
    (Tk_ImageStringReadProc *) ObjRead,	
    (Tk_ImageFileWriteProc *) ChanWrite,	
    (Tk_ImageStringWriteProc *) StringWrite
  },
  {
    "cxbmp",
    (Tk_ImageFileMatchProc *) ChanMatch,	
    (Tk_ImageStringMatchProc *) ObjMatch,	
    (Tk_ImageFileReadProc *) ChanRead,	
    (Tk_ImageStringReadProc *) ObjRead,	
    (Tk_ImageFileWriteProc *) ChanWrite,	
    (Tk_ImageStringWriteProc *) StringWrite
  }
};
  
  
int RGB2BGR(Tk_PhotoImageBlock *data, BYTE * pixelPtr) {
  int i;
  int size = data->height * data->width * data->pixelSize;

  int alpha = data->offset[3];

  if (alpha == data->offset[0] || alpha == data->offset[1] || alpha == data->offset[2]) {
    alpha = 0;
  } else {
    alpha = 1;
  }

  LOG("alpha is : "); //
  APPENDLOG(alpha); //

	
  for (i = 0; i < size; i+= data->pixelSize) {
    *(pixelPtr++) = *(data->pixelPtr + i + data->offset[2]);
    *(pixelPtr++) = *(data->pixelPtr + i + data->offset[1]);
    *(pixelPtr++) = *(data->pixelPtr + i + data->offset[0]);
    *(pixelPtr++) = alpha?*(data->pixelPtr + i + data->offset[3]):255;

  }
 
  return alpha;

}


int GetFileTypeFromFileName(char * Filename) {

  char * ptr = NULL; 
  char * previousptr = NULL;
  char extension[4];
	
  ptr = Filename;

  LOG("Getting File type from Filename :"); // 
  APPENDLOG(Filename); //
  LOG("pointer to : "); //

  while (ptr != NULL) { 
    ptr = strchr(ptr, '.');
    if (ptr) {
      ptr++;
      previousptr = ptr;
      APPENDLOG(ptr); //
    }
  } 

  ptr = previousptr;

  if (ptr) {
    strncpy(extension, ptr, 3);
    extension[3] = 0;

    LOG("Pointer is : "); //
    APPENDLOG(ptr); //
    LOG("Extension is : ");
    APPENDLOG(extension); //

    for (int i = 0 ; i < 3; i++)
      extension[i] = tolower(extension[i]);
    if (!strcmp(extension, "bmp")) 
      return CXIMAGE_FORMAT_BMP;
    if (!strcmp(extension, "jpg") || !strcmp(extension, "jpe")) 
      return CXIMAGE_FORMAT_JPG;
    if (!strcmp(extension, "gif")) 
      return CXIMAGE_FORMAT_GIF;
    if (!strcmp(extension, "png"))
      return CXIMAGE_FORMAT_PNG;
    if (!strcmp(extension, "tga"))
      return CXIMAGE_FORMAT_TGA;
		
  } 
    
  return CXIMAGE_FORMAT_UNKNOWN;

}


int GetFileTypeFromFormat(char * Format) {


  if (Format) {
    LOG("Getting file type from format : ");
    APPENDLOG(Format);
    if (!strcmp(Format, "cxbmp")) 
	return CXIMAGE_FORMAT_BMP;
    if (!strcmp(Format, "cxjpg"))
      return CXIMAGE_FORMAT_JPG;
    if (!strcmp(Format, "cxgif")) 
      return CXIMAGE_FORMAT_GIF;
    if (!strcmp(Format, "cxpng"))
      return CXIMAGE_FORMAT_PNG;
    if (!strcmp(Format, "cxtga"))
      return CXIMAGE_FORMAT_TGA;
    if (!strcmp(Format, "cximage"))
      return CXIMAGE_FORMAT_UNKNOWN;
		
  } 
    
  return CXIMAGE_FORMAT_UNKNOWN;

}

int LoadFromFile(Tcl_Interp * interp, CxImage * image, char * fileName, int Type) {

  Tcl_Obj *data = Tcl_NewObj();
  Tcl_Channel chan = Tcl_OpenFileChannel(interp, fileName, "r", 0);
  BYTE * FileData = NULL;
  int length = 0;
  int retVal;

  if (chan == NULL)
    return FALSE;


  if (Type == CXIMAGE_FORMAT_UNKNOWN) {
    Type = GetFileTypeFromFileName((char *)fileName);
  }

  if (Type == CXIMAGE_FORMAT_UNKNOWN) {
    Type = CXIMAGE_FORMAT_GIF;
  }

  Tcl_SetChannelOption(interp, chan, "-encoding", "binary");
  Tcl_SetChannelOption(interp, chan, "-translation", "binary");

  Tcl_ReadChars(chan, data, -1, 0);

  Tcl_Close(interp, chan);

  FileData = Tcl_GetByteArrayFromObj(data, &length);


  if (! image->Decode(FileData, length, Type) &&
      ! image->Decode(FileData, length, CXIMAGE_FORMAT_GIF) &&
      ! image->Decode(FileData, length, CXIMAGE_FORMAT_PNG) &&
      ! image->Decode(FileData, length, CXIMAGE_FORMAT_JPG) &&
      ! image->Decode(FileData, length, CXIMAGE_FORMAT_TGA) &&
      ! image->Decode(FileData, length, CXIMAGE_FORMAT_BMP)) 
    retVal = FALSE;
  else
    retVal = TRUE;

  Tcl_DecrRefCount(data);
  return retVal;
  
}


int SaveToFile(Tcl_Interp * interp, CxImage * image, char * fileName, int Type) {

  Tcl_Channel chan = Tcl_OpenFileChannel(interp, fileName, "w", 0644);
  BYTE * FileData = NULL;
  long length = 0;

  if (chan == NULL)
    return FALSE;


  if (Type == CXIMAGE_FORMAT_UNKNOWN) {
    Type = GetFileTypeFromFileName((char *)fileName);
  }

  if (Type == CXIMAGE_FORMAT_UNKNOWN) {
    Type = CXIMAGE_FORMAT_GIF;
  }

  Tcl_SetChannelOption(interp, chan, "-encoding", "binary");
  Tcl_SetChannelOption(interp, chan, "-translation", "binary");


  if (!image->Encode(FileData, length, Type) ) {
    Tcl_AppendResult(interp, image->GetLastError(), NULL);
    return TCL_ERROR;
  }

  Tcl_WriteObj(chan, Tcl_NewByteArrayObj(FileData, length));

  image->FreeMemory(FileData);

  Tcl_ResetResult(interp);

  if (Tcl_Close(interp, chan) == TCL_ERROR)
    return FALSE;
  else
    return TRUE;
  
}


#if ANIMATE_GIFS
/*
    Function to hook the TkImageDisplayProc of the photo image type.
    As we can copy frame only when we need to display it
*/
int PlaceHook(Tcl_Interp *interp){
	char buf[255];
	strcpy(buf, "image create photo");
	if (Tcl_EvalEx(interp,buf,-1,TCL_EVAL_GLOBAL) != TCL_OK) {
		LOG("Error creating photo for hook creation ");
		APPENDLOG( Tcl_GetStringResult(interp) );
		return TCL_ERROR;
	}
	const char *name = Tcl_GetStringResult(interp);
	Tk_ImageType *typePhotoPtr = NULL;
	Tk_GetImageMasterData(interp, name, &typePhotoPtr);
	if (PhotoDisplayOriginal == NULL) {
		PhotoDisplayOriginal = typePhotoPtr->displayProc;
		typePhotoPtr->displayProc = (Tk_ImageDisplayProc *) PhotoDisplayProcHook;
	} // else we already put the hook
	Tk_DeleteImage(interp, name);
	Tcl_ResetResult(interp);
	return TCL_OK;
}

#endif

/*
  Function : Cximage_Init

  Description :	The Init function that will be called when the extension is loaded to your tk shell

  Arguments   :	Tcl_Interp *interp    :	This is the interpreter from which the load was made and to 
  which we'll add the new command


  Return value : TCL_OK in case everything is ok, or TCL_ERROR in case there is an error (Tk version < 8.3)

  Comments     : hummmm... not much, it's simple :)

*/
int Tkcximage_Init (Tcl_Interp *interp ) {
	
  int i;

  INITLOGS(); //
  LOG("---------------------------------"); //

  //Check Tcl version is 8.3 or higher
  if (Tcl_InitStubs(interp, TCL_VERSION, 1) == NULL) {
    return TCL_ERROR;
  }

  LOG("Tcl stub initialized"); //

  //Check TK version is 8.3 or higher
  if (Tk_InitStubs(interp, TK_VERSION, 1) == NULL) {
    return TCL_ERROR;
  }

  LOG("Tk stub initialized"); //

	
  LOG("Creating commands"); //

  // Create the wrapping commands in the CxImage namespace linked to custom functions with a NULL clientdata and 
  // no deleteproc inside the current interpreter
  Tcl_CreateObjCommand(interp, "::CxImage::Convert", Tk_Convert,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::CxImage::Resize", Tk_Resize,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::CxImage::Colorize", Tk_Colorize,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::CxImage::Thumbnail", Tk_Thumbnail,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::CxImage::IsAnimated", Tk_IsAnimated,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

#if ANIMATE_GIFS
  Tcl_CreateObjCommand(interp, "::CxImage::StopAnimation", Tk_DisableAnimation,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::CxImage::StartAnimation", Tk_EnableAnimation,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::CxImage::NumberOfFrames", Tk_NumberOfFrames,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::CxImage::JumpToFrame", Tk_JumpToFrame,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  if (PlaceHook(interp) != TCL_OK) return TCL_ERROR;
#endif

  LOG("Adding format : "); //
  for (i = 0; i < AVAILABLE_FORMATS; i++) {
    Tk_CreatePhotoImageFormat(&cximageFormats[i]);
    APPENDLOG(cximageFormats[i].name); //
  }

  // end of Initialisation
  return TCL_OK;
}

int Tkcximage_SafeInit (Tcl_Interp *interp) {
  return Tkcximage_Init(interp);
}

int Tkcximage_Unload(Tcl_Interp* interp, int flags)  {
	return 0;
}

int Tkcximage_SafeUnload(Tcl_Interp* interp, int flags)  {
	return Tkcximage_Unload(interp, flags);
}
