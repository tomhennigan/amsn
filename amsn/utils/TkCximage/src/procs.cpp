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
int Tk_IsAnimated (ClientData clientData,
		       Tcl_Interp *interp,
		       int objc,
		       Tcl_Obj *CONST objv[]) 
{
  CxImage image;
  char *In = NULL;

  int InType = 0;
    

  // We verify the arguments, we must have one arg, not more
  if( objc != 2) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::CxImage::IsAnimated Filename\"" , (char *) NULL);
    return TCL_ERROR;
  }
	
	
  // Get the first argument string (object name) and check it 
  In = Tcl_GetStringFromObj(objv[1], NULL);

  InType = GetFileTypeFromFileName(In);

  if(!LoadFromFile(interp, &image, In, InType) ) {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }
  Tcl_SetObjResult( interp, Tcl_NewBooleanObj(image.GetNumFrames() > 1) );
  return TCL_OK;
}
int Tk_Convert (ClientData clientData,
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

  if(!LoadFromFile(interp, &image, In, InType) ) {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }

  if ( (OutType == CXIMAGE_FORMAT_UNKNOWN) || (image.GetNumFrames() > 1) )
    OutType = CXIMAGE_FORMAT_GIF;
  
  if (image.GetNumFrames() > 1){
    image.SetRetreiveAllFrames(true);
    image.SetFrame(image.GetNumFrames() - 1);
    if(!LoadFromFile(interp, &image, In, InType) ) {
      Tcl_AppendResult(interp, image.GetLastError(), NULL);
      return TCL_ERROR;
    }
  }

  if (OutType == CXIMAGE_FORMAT_GIF) 
    image.DecreaseBpp(8, true);
	
  if (SaveToFile(interp, &image, Out, OutType)){
    LOG("End of tk_convert");
    return TCL_OK;
  }
  else {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }

	

  return TCL_OK;

}

int Tk_Resize (ClientData clientData,
		      Tcl_Interp *interp,
		      int objc,
		      Tcl_Obj *CONST objv[]) 
{
	

  CxImage image;
  char *ImageName = NULL;
  Tk_PhotoHandle Photo;
  Tk_PhotoImageBlock photoData;

  BYTE * pixelPtrCopy = NULL;

  int alpha = 0;
  int width = 0;
  int height = 0;
#if ANIMATE_GIFS
  GifInfo* item = NULL;
#endif

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

#if ANIMATE_GIFS
  item = TkCxImage_lstGetItem(Photo);
  if ( item != NULL ) {
    for(unsigned int i=0; i< item->NumFrames; i++) {
      /* an image could have X frames but not all of them could have been decoded */
      if (item->image->GetFrame(i) != NULL) {
        item->image->GetFrame(i)->Resample(width, height, 1);
      }
    }

    //We clear stored buffers and when we will display them they will be recreated
    for(GifBuffersIterator it=item->buffers.begin(); it!=item->buffers.end(); it++){
      (*it)->Close();
      delete (*it);
    }
    item->buffers.clear();
    #if TK_MINOR_VERSION == 3
    Tk_PhotoSetSize(Photo, width, height);
    #else 
    #if TK_MINOR_VERSION == 4
    Tk_PhotoSetSize(Photo, width, height);
    #else 
    #if TK_MINOR_VERSION >= 5
    Tk_PhotoSetSize(interp, Photo, width, height);
    #endif
    #endif
    #endif
    return TCL_OK;

  } else
#endif
  {
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

	/* Modes:
		0 - Bilinear (Slow[er])
		1 - Nearest Pixel (Fast[er])
		2 - Bicubic Spline (Accurate) */
	int resampleMode = 0;
	#if SMART_RESIZE == 1
	if(image.GetWidth() <= 800 && image.GetHeight() <= 800) {
		// Use a higher quality resample for small/medium images.
		resampleMode = 0;
	} else if(image.GetWidth() >= 1024 && image.GetHeight() >= 1024) {
		// Fastest mode for large images.
		resampleMode = 1;
	} else {
		// Fast but accurate for medium images.
		resampleMode = 2;
	}
	#endif
    if(!image.Resample(width, height, resampleMode)) {
      Tcl_AppendResult(interp, image.GetLastError(), NULL);
      return TCL_ERROR;
    }

/*    if(!image.Flip()) {
      Tcl_AppendResult(interp, image.GetLastError(), NULL);
      return TCL_ERROR;
    }*/
    return CopyImageToTk(interp, &image, Photo, image.GetWidth(), image.GetHeight());
  }

}


int Tk_Thumbnail (ClientData clientData,
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

    BYTE * pixelPtrCopy = NULL;

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

  if(alpha == 0 && alphaopt == 255) 
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

/*  if(!image.Flip()) {
		Tcl_AppendResult(interp, image.GetLastError(), NULL);
		return TCL_ERROR;
	}*/

  return CopyImageToTk(interp, &image, Photo, image.GetWidth(), image.GetHeight());
}

int Tk_Colorize (ClientData clientData,
		      Tcl_Interp *interp,
		      int objc,
		      Tcl_Obj *CONST objv[]) 
{
	

  CxImage image;
  char *ImageName = NULL;
  Tk_PhotoHandle Photo;
  Tk_PhotoImageBlock photoData;
  XColor *color;
  int i=0;
  unsigned char* ptr=NULL;
  unsigned char red, green, blue;
  bool alpha = false;
  double opacity = 1.0;

  // We verify the arguments, we must have two args, not more
  if( objc < 3 && objc > 4) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::CxImage::Colorize photoImage_name color ?opacity?\"" , (char *) NULL);
    return TCL_ERROR;
  }
	
	
  // Get the first argument string (object name) and check it 
  ImageName = Tcl_GetStringFromObj(objv[1], NULL);

  if (objc == 4) {
    if( Tcl_GetDoubleFromObj(interp, objv[3], &opacity) == TCL_ERROR) {
        Tcl_AppendResult(interp, "The opacity you specified is not a valid number", NULL);
        return TCL_ERROR;
    }
  }

  if (opacity < 0 && opacity > 1) {
    Tcl_AppendResult(interp, "The opacity you specified is not between 0 and 1", NULL);
    return TCL_ERROR;
  }

  if ( (Photo = Tk_FindPhoto(interp, ImageName)) == NULL) {
    Tcl_AppendResult(interp, "The image you specified is not a valid photo image", NULL);
    return TCL_ERROR;
  }

  if( (color = Tk_AllocColorFromObj(interp, Tk_MainWindow(interp), objv[2])) == NULL) {
    Tcl_AppendResult(interp, "Invalid Color for background", NULL);
    return TCL_ERROR;
  }

  Tk_PhotoGetImage(Photo, &photoData);
  
  red=(BYTE) color->red;
  green=(BYTE) color->green;
  blue=(BYTE) color->blue;


  if (photoData.offset[3] != photoData.offset[0] && photoData.offset[3] != photoData.offset[1] && photoData.offset[3] != photoData.offset[2] && opacity != 1.0)
    alpha = true;
  
  for (i = 0; i < (photoData.pixelSize*photoData.width*photoData.height); i+= photoData.pixelSize) {
    ptr = photoData.pixelPtr+i;//pixelPtrCopy+i;

    
    *(ptr+photoData.offset[0])=( red * *(ptr + photoData.offset[0]) )/255;
    *(ptr+photoData.offset[1])=( green * *(ptr + photoData.offset[1]) )/255;
    *(ptr+photoData.offset[2])=( blue * *(ptr + photoData.offset[2]) )/255;
    if (alpha) {
      *(ptr+photoData.offset[3])= (char) (opacity * *(ptr + photoData.offset[3]) );
    }
  }
  
  #if TK_MINOR_VERSION == 3
  Tk_PhotoBlank(Photo);
  Tk_PhotoPutBlock(Photo, &photoData, 0, 0, photoData.width, photoData.height);
  #else 
  #if TK_MINOR_VERSION == 4
  Tk_PhotoPutBlock(Photo, &photoData, 0, 0, photoData.width, photoData.height, TK_PHOTO_COMPOSITE_SET );
  #else 
  #if TK_MINOR_VERSION >= 5
  Tk_PhotoPutBlock((Tcl_Interp *) interp, Photo, &photoData, 0, 0, photoData.width, photoData.height, TK_PHOTO_COMPOSITE_SET );
  #endif
  #endif
  #endif
  
  //free(pixelPtrCopy);
  
  return TCL_OK;
}

int CopyImageToTk(Tcl_Interp * interp, CxImage *image, Tk_PhotoHandle Photo, int width, int height, int blank) {

	try {
		BYTE * buffer = NULL;
	long size = 0;


	#if TK_MINOR_VERSION == 3
	Tk_PhotoSetSize(Photo, width, height);
	#else 
	#if TK_MINOR_VERSION == 4
	Tk_PhotoSetSize(Photo, width, height);
	#else 
	#if TK_MINOR_VERSION >= 5
	Tk_PhotoSetSize(interp, Photo, width, height);
	#endif
	#endif
	#endif

	if(!image->Encode2RGBA(buffer, size)) {
		Tcl_AppendResult(interp, image->GetLastError(), NULL);
		return TCL_ERROR;
	}

	Tk_PhotoImageBlock block = {
		buffer,		// pixel ptr
		width,
		height,
		width*4,	// pitch : number of bytes separating 2 adjacent pixels vertically
		4,			// pixel size : size in bytes of one pixel .. 4 = RGBA
	};

	block.offset[0] = 0;
	block.offset[1] = 1;
	block.offset[2] = 2;

	if ( image->AlphaIsValid() || image->IsTransparent() )
		block.offset[3] = 3;

	#if TK_MINOR_VERSION == 3
	if(blank)
		Tk_PhotoBlank(Photo);
	Tk_PhotoPutBlock(Photo, &block, 0, 0, width, height);
	#else 
	#if TK_MINOR_VERSION == 4
	Tk_PhotoPutBlock(Photo, &block, 0, 0, width, height, (blank ? TK_PHOTO_COMPOSITE_SET : TK_PHOTO_COMPOSITE_OVERLAY) );
	#else 
	#if TK_MINOR_VERSION >= 5
	Tk_PhotoPutBlock((Tcl_Interp *) interp, Photo, &block, 0, 0, width, height, (blank ? TK_PHOTO_COMPOSITE_SET : TK_PHOTO_COMPOSITE_OVERLAY) );
	#endif
	#endif
	#endif

	image->FreeMemory(buffer);
		
	return TCL_OK;
	} catch(...) {
		return TCL_ERROR;
	}

}


#if ANIMATE_GIFS
int AnimatedGifFrameToTk(Tcl_Interp *interp, GifInfo *Info, CxImage *frame, int blank) {
	try {
		int width = 0;
		int height = 0;
		Tk_PhotoHandle Photo = Info->Handle;
	
		CxMemFile *buffer=NULL;

		while(Info->CurrentFrame >= Info->buffers.size()){
			LOG("Loading frame : ");
			APPENDLOG( Info->buffers.size());
			
			CxImage *image = Info->image->GetFrame(Info->buffers.size());
			if (image == NULL)
			  break;
			buffer = new CxMemFile();
			//The image isn't stored yet we will make the buffer and keep it
			buffer->Open();
			image->Encode2RGBA(buffer);
			Info->buffers.push_back(buffer);
		}
	
		buffer = Info->buffers[Info->CurrentFrame];
	
		width = frame->GetWidth();
		height = frame->GetHeight();
		
		Tk_PhotoImageBlock block = {
			buffer->GetBuffer(false),		// pixel ptr false : to avoid detaching of the buffer
			width,
			height,
			width*4,	// pitch : number of bytes separating 2 adjacent pixels vertically
			4,			// pixel size : size in bytes of one pixel .. 4 = RGBA
		};
	
		block.offset[0] = 0;
		block.offset[1] = 1;
		block.offset[2] = 2;
	
		if ( frame->AlphaIsValid() || frame->IsTransparent() )
			block.offset[3] = 3;
	
		#if TK_MINOR_VERSION == 3
		if(blank)
			Tk_PhotoBlank(Photo);
		Tk_PhotoPutBlock(Photo, &block, 0, 0, width, height);
		#else 
		#if TK_MINOR_VERSION == 4
		Tk_PhotoPutBlock(Photo, &block, 0, 0, width, height, (blank ? TK_PHOTO_COMPOSITE_SET : TK_PHOTO_COMPOSITE_OVERLAY) );
		#else 
		#if TK_MINOR_VERSION >= 5
		Tk_PhotoPutBlock((Tcl_Interp *) interp, Photo, &block, 0, 0, width, height, (blank ? TK_PHOTO_COMPOSITE_SET : TK_PHOTO_COMPOSITE_OVERLAY) );
		#endif
		#endif
		#endif
	
		return TCL_OK;
		
	} catch(...) {
		return TCL_ERROR;
	}
}
int Tk_EnableAnimation (ClientData clientData,
		       Tcl_Interp *interp,
		       int objc,
		       Tcl_Obj *CONST objv[]) 
{
	CxImage image;
	char *ImageName = NULL;
	Tk_PhotoHandle Photo;
	GifInfo* item = NULL;
	// We verify the arguments, we must have two args, not more
	if( objc != 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::CxImage::StartAnimation photoImage_name\"" , (char *) NULL);
		return TCL_ERROR;
	}
	
	
	// Get the first argument string (object name) and check it 
	ImageName = Tcl_GetStringFromObj(objv[1], NULL);
	if ( (Photo = Tk_FindPhoto(interp, ImageName)) == NULL) {
		Tcl_AppendResult(interp, "The image you specified is not a valid photo image", NULL);
		return TCL_ERROR;
	}
	item = TkCxImage_lstGetItem(Photo);
	if ( item == NULL ) {
		return TCL_OK;
	}
	if (item != NULL && !item->Enabled) {
		item->Enabled=true;
		if (item->timerToken == NULL) {
			int currentFrame = item->CurrentFrame;
			CxImage *image = item->image->GetFrame(currentFrame);
			if (image == NULL) {
			  currentFrame = item->CurrentFrame = 0;
			  CxImage *image = item->image->GetFrame(currentFrame);
			}
			item->timerToken = Tcl_CreateTimerHandler(image->GetFrameDelay()?10*image->GetFrameDelay():40, AnimateGif, item);
		}
	}
	return TCL_OK;
}
int Tk_DisableAnimation (ClientData clientData,
		       Tcl_Interp *interp,
		       int objc,
		       Tcl_Obj *CONST objv[]) 
{
	CxImage image;
	char *ImageName = NULL;
	Tk_PhotoHandle Photo;
	GifInfo* item = NULL;
	// We verify the arguments, we must have two args, not more
	if( objc != 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::CxImage::StopAnimation photoImage_name\"" , (char *) NULL);
		return TCL_ERROR;
	}
	
	
	// Get the first argument string (object name) and check it 
	ImageName = Tcl_GetStringFromObj(objv[1], NULL);
	if ( (Photo = Tk_FindPhoto(interp, ImageName)) == NULL) {
		Tcl_AppendResult(interp, "The image you specified is not a valid photo image", NULL);
		return TCL_ERROR;
	}
	item = TkCxImage_lstGetItem(Photo);
	if (item != NULL && item->Enabled) {
		item->Enabled=false;
		if (item->timerToken != NULL) {
			Tcl_DeleteTimerHandler(item->timerToken);
			item->timerToken = NULL;
		}
	}
	return TCL_OK;
}
int Tk_NumberOfFrames (ClientData clientData,
		       Tcl_Interp *interp,
		       int objc,
		       Tcl_Obj *CONST objv[]) 
{
	CxImage image;
	char *ImageName = NULL;
	Tk_PhotoHandle Photo;
	GifInfo* item = NULL;
	// We verify the arguments, we must have two args, not more
	if( objc != 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::CxImage::NumberOfFrames photoImage_name\"" , (char *) NULL);
		return TCL_ERROR;
	}
	
	
	// Get the first argument string (object name) and check it 
	ImageName = Tcl_GetStringFromObj(objv[1], NULL);
	if ( (Photo = Tk_FindPhoto(interp, ImageName)) == NULL) {
		Tcl_AppendResult(interp, "The image you specified is not a valid photo image", NULL);
		return TCL_ERROR;
	}
	item = TkCxImage_lstGetItem(Photo);
	if ( item == NULL ) {
		//Image isn't animated : there is 1 frame
		Tcl_SetObjResult( interp, Tcl_NewIntObj(1) );
		return TCL_OK;
	}
	Tcl_SetObjResult( interp, Tcl_NewIntObj(item->NumFrames) );
	return TCL_OK;
}
int Tk_JumpToFrame (ClientData clientData,
		       Tcl_Interp *interp,
		       int objc,
		       Tcl_Obj *CONST objv[]) 
{
	CxImage image;
	char *ImageName = NULL;
	Tk_PhotoHandle Photo;
	GifInfo* item = NULL;
	int frame_number = 0;
	// We verify the arguments, we must have two args, not more
	if( objc != 3) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::CxImage::JumpToFrame photoImage_name frame_number\"" , (char *) NULL);
		return TCL_ERROR;
	}
	
	
	// Get the first argument string (object name) and check it 
	ImageName = Tcl_GetStringFromObj(objv[1], NULL);
	if ( (Photo = Tk_FindPhoto(interp, ImageName)) == NULL) {
		Tcl_AppendResult(interp, "The image you specified is not a valid photo image", NULL);
		return TCL_ERROR;
	}
	item = TkCxImage_lstGetItem(Photo);
	if ( item == NULL ) {
		Tcl_AppendResult(interp, "The image you specified is not an animated image", NULL);
		return TCL_ERROR;
	}
	if( Tcl_GetIntFromObj(interp, objv[2], &frame_number) == TCL_ERROR) {
		return TCL_ERROR;
	}
	if (frame_number < 0) {
		Tcl_AppendResult(interp, "Bad frame number : can't be negative", NULL);
		return TCL_ERROR;
	}

	if ((unsigned int)frame_number < item->NumFrames && item->image->GetFrame(frame_number) != NULL ) {
		item->CurrentFrame = frame_number;
		CxImage *image = item->image->GetFrame(item->CurrentFrame);
		Tk_ImageChanged(item->ImageMaster, 0, 0, image->GetWidth(), image->GetHeight(), image->GetWidth(), image->GetHeight());
	} else {
		Tcl_AppendResult(interp, "The image you specified hasn't enough frames", NULL);
		return TCL_ERROR;
	}
	return TCL_OK;
}
#endif


