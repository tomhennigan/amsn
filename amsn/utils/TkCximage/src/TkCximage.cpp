/*
  File : TkCximage.cpp

  Description :	Contains all functions for the Tk extension for the CxImage utility

  Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
*/


// Include the header file
#include "TkCximage.h"

char currenttime[30];
FILE * logfile;


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


  int AvailableFromats = 6;
  const char *KnownFormats[] = {"cximage", "cxgif", "cxpng", "cxjpg", "cxtga", "cxbmp"};

  //Check Tcl version is 8.3 or higher
  if (Tcl_InitStubs(interp, "8.3", 0) == NULL) {
    return TCL_ERROR;
  }

  LOG("Tcl stub initialized"); //

  //Check TK version is 8.3 or higher
  if (Tk_InitStubs(interp, "8.3", 0) == NULL) {
    return TCL_ERROR;
  }

  LOG("Tk stub initialized"); //

  Tk_PhotoImageFormat cximageFormats = {
    NULL,
    (Tk_ImageFileMatchProc *) ChanMatch,	
    (Tk_ImageStringMatchProc *) ObjMatch,	
    (Tk_ImageFileReadProc *) ChanRead,	
    (Tk_ImageStringReadProc *) ObjRead,	
    (Tk_ImageFileWriteProc *) ChanWrite,	
    (Tk_ImageStringWriteProc *) StringWrite
  };
	
  LOG("Creating commands"); //

  // Create the wrapping commands in the CxImage namespace linked to custom functions with a NULL clientdata and 
  // no deleteproc inside the current interpreter
  Tcl_CreateObjCommand(interp, "::CxImage::Convert", Tk_Convert,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::CxImage::Resize", Tk_Resize,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::CxImage::Thumbnail", Tk_Thumbnail,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

  LOG("Adding format : "); //
  for (i = 0; i < AvailableFromats; i++) {
    delete cximageFormats.name;
    cximageFormats.name = new char[strlen(KnownFormats[i]) + 1];
    strcpy(cximageFormats.name, KnownFormats[i]);
    Tk_CreatePhotoImageFormat(&cximageFormats);
    APPENDLOG(cximageFormats.name); //
    delete cximageFormats.name;
    cximageFormats.name = NULL;
  }

  // end of Initialisation
  return TCL_OK;
}

int Tkcximage_SafeInit (Tcl_Interp *interp) {
  return Tkcximage_Init(interp);
}
