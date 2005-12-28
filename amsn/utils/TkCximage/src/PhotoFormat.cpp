/*
  File : TkCximage.cpp

  Description :	Contains all functions for the Tk extension for the CxImage utility

  Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
*/

#include "TkCximage.h"

static ChainedList animated_gifs;
Tk_ImageDisplayProc *PhotoDisplayOriginal=NULL;

/////////////////////////////////////
// Functions to manage lists       //
/////////////////////////////////////

ChainedIterator TkCxImage_lstGetListItem(list_element_type list_element_id) { //Get the iterator with the specified id

  ChainedIterator item;

  for( item = g_list.begin(); item != g_list.end() && (*item)->list_element_id != list_element_id; item++);

  return item;

}


struct data_item* TkCxImage_lstAddItem(struct data_item* item) { //Add the specified item if its id not already exists

  if ( !item ) return NULL;
  if ( TkCxImage_lstGetListItem(item->list_element_id) != g_list.end() ) return NULL;

  g_list.push_back( item );

  return item;

}

struct data_item* TkCxImage_lstGetItem(list_element_type list_element_id) { //Get the item with the specified id

	ChainedIterator listitem = TkCxImage_lstGetListItem( list_element_id );
	if( listitem != g_list.end() )
		return (*listitem);
	else
		return NULL;
}

struct data_item* TkCxImage_lstDeleteItem(list_element_type list_element_id) { //Delete the item with the specified id if exists

	ChainedIterator item = TkCxImage_lstGetListItem( list_element_id );
	struct data_item* element;

	if( item != g_list.end() ) {
		element = (*item);
		g_list.erase( item );
		return element;
	}
	else {
		return NULL;
	}

}

////////////////////////////
// TkCxImage code         //
////////////////////////////

int ChanMatch (Tcl_Channel chan, CONST char *fileName, Tcl_Obj *format,int *widthPtr,
		      int *heightPtr, Tcl_Interp *interp)
{
  CxImage image;

  LOG("Chanel matching"); //
  LOG("Filename is"); //
  APPENDLOG(fileName); //

  // Set escape to -1 to prevent decoding the image, but just return it's width and height
  //image.SetEscape(-1);

  if (image.Load(fileName, CXIMAGE_FORMAT_UNKNOWN)) {
    *widthPtr = image.GetWidth();
    *heightPtr = image.GetHeight();

    LOG("Supported Format"); //
    LOG("Width :"); //
    APPENDLOG(*widthPtr); //
    LOG("Heigth :"); //
    APPENDLOG(*heightPtr); //

    return true;
  }

  return false;
}


int ObjMatch (Tcl_Obj *data, Tcl_Obj *format, int *widthPtr, int *heightPtr, Tcl_Interp *interp) {

  BYTE * buffer = NULL;
  int length = 0;

  CxImage image;

  LOG("Data matching"); //

  buffer = Tcl_GetByteArrayFromObj(data, &length);

  LOG(""); //

  if (image.Decode(buffer, length, CXIMAGE_FORMAT_GIF) ||
      image.Decode(buffer, length, CXIMAGE_FORMAT_PNG) ||
      image.Decode(buffer, length, CXIMAGE_FORMAT_JPG) ||
      image.Decode(buffer, length, CXIMAGE_FORMAT_TGA) ||
      image.Decode(buffer, length, CXIMAGE_FORMAT_BMP)) {
    *widthPtr = image.GetWidth();
    *heightPtr = image.GetHeight();

    LOG("Supported Format"); //
    LOG("Width :"); //
    APPENDLOG(*widthPtr); //
    LOG("Heigth :"); //
    APPENDLOG(*heightPtr); //

    return true;
  }

  LOG("Unknown format");

  return false;
}

int ChanRead (Tcl_Interp *interp, Tcl_Channel chan, CONST char *fileName, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
		     int destX, int destY, int width, int height, int srcX, int srcY)
{
	Tcl_Obj *data = Tcl_NewObj();

	Tcl_SetChannelOption(interp, chan, "-encoding", "binary");
	Tcl_SetChannelOption(interp, chan, "-translation", "binary");

	Tcl_ReadChars(chan, data, -1, 0);

	LOG("Reading from file :"); //
	APPENDLOG(fileName); //

  return ObjRead(interp, data, format, imageHandle, destX, destY, width, height, srcX, srcY);

}

int ObjRead (Tcl_Interp *interp, Tcl_Obj *data, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
		    int destX, int destY, int width, int height, int srcX, int srcY)
{

	BYTE * buffer = NULL;
	long size = 0;

	BYTE * FileData = NULL;
	int length = 0;

  CxImage image;

  LOG("Reading data :"); //

  FileData = Tcl_GetByteArrayFromObj(data, &length);


  if (! image.Decode(FileData, length, CXIMAGE_FORMAT_GIF) &&
      ! image.Decode(FileData, length, CXIMAGE_FORMAT_PNG) &&
      ! image.Decode(FileData, length, CXIMAGE_FORMAT_JPG) &&
      ! image.Decode(FileData, length, CXIMAGE_FORMAT_TGA) &&
      ! image.Decode(FileData, length, CXIMAGE_FORMAT_BMP))
    return TCL_ERROR;

#if ANIMATE_GIFS
  int numframes = image.GetNumFrames();
#endif


  LOG("Cropping"); //

  if(!image.Crop(srcX, srcY, srcX + width, srcY + height)) {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }

  LOG("Flipping image"); //

  if(!image.Flip()) {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }

  LOG("Encoding to RGBA"); //

  if(!image.Encode2RGBA(buffer, size)) {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }

  LOG("Setting PhotoImageBlock"); //

  Tk_PhotoImageBlock block = {
    buffer,		// pixel ptr
    width,
    height,
    width*4,	        // pitch : number of bytes separating 2 adjacent pixels vertically
    4,			// pixel size : size in bytes of one pixel .. 4 = RGBA
  };

  block.offset[0] = 0;
  block.offset[1] = 1;
  block.offset[2] = 2;

  if ( image.AlphaIsValid() || image.IsTransparent() ) {
    LOG("Alpha is valid, setting offset[3]"); //
    block.offset[3] = 3;
  }

  LOG("Putting Block into image"); //
#if TK_MINOR_VERSION == 3
  Tk_PhotoBlank(imageHandle);
  Tk_PhotoPutBlock(imageHandle, &block, destX, destY, width, height);
#else
#if TK_MINOR_VERSION == 4
  Tk_PhotoPutBlock(imageHandle, &block, destX, destY, width, height, TK_PHOTO_COMPOSITE_SET);
#else
#if TK_MINOR_VERSION == 5
  Tk_PhotoPutBlock((Tcl_Interp *) NULL, imageHandle, &block, destX, destY, width, height, TK_PHOTO_COMPOSITE_SET);
#endif
#endif
#endif

#if  ANIMATE_GIFS
	LOG("Getting item");
	APPENDLOG(imageHandle);
	GifInfo* item=TkCxImage_lstGetItem(imageHandle);
	if(item!=NULL) {
		LOG("Got item in Animated list");
		Tcl_DeleteTimerHandler(item->timerToken);
		item->image->DestroyGifFrames();
		delete item->image;
		for(GifBuffersIterator it=item->buffers.begin(); it!=item->buffers.end(); it++){
			(*it)->Close();
			delete (*it);
		}
		LOG("Deleting AnimatedGifInfo");
		APPENDLOG(item->Handle);
		TkCxImage_lstDeleteItem(item->Handle);
		delete item;
	}
  // If it's an animated gif, take care of it right here
	if(g_EnableAnimated && numframes > 1) {

		GifInfo * AnimatedGifInfo = new GifInfo;
		CxImage *image = NULL;

		AnimatedGifInfo->CurrentFrame = 0;
		AnimatedGifInfo->CopiedFrame = -1;
		AnimatedGifInfo->NumFrames = numframes;
		AnimatedGifInfo->Handle = imageHandle;
		AnimatedGifInfo->ImageMaster = (Tk_ImageMaster) *((void **)imageHandle);
		AnimatedGifInfo->interp = interp;
		AnimatedGifInfo->image = new CxImage;
		AnimatedGifInfo->image->RetreiveAllFrame();
		AnimatedGifInfo->image->SetFrame(numframes - 1);
		AnimatedGifInfo->image->Decode(FileData, length, CXIMAGE_FORMAT_GIF);

		for(int i = 0; i < numframes; i++){
			if(AnimatedGifInfo->image->GetFrameNo(i) != AnimatedGifInfo->image) {
				AnimatedGifInfo->image->GetFrameNo(i)->Flip();
			}
		}
		LOG("Adding AnimatedGifInfo");
		APPENDLOG(imageHandle);
		TkCxImage_lstAddItem(AnimatedGifInfo);

		/*
		// Store each frame
		for(int i = 0; i < numframes; i++){
			currentFrame = new CxImage();
			currentFrame->SetFrame(i);
			if(currentFrame->Decode(FileData, length, CXIMAGE_FORMAT_GIF) && currentFrame->Flip()) {
				AnimatedGifInfo->Frames[i] = currentFrame;
			} else {
				delete currentFrame;
				for(int i = 0; i < numframes; i++){
					delete AnimatedGifInfo->Frames[i];
					AnimatedGifInfo->Frames[i] = NULL;
				}
				delete AnimatedGifInfo->Frames;
				AnimatedGifInfo->Frames = NULL;
				delete AnimatedGifInfo;
				AnimatedGifInfo = NULL;
			}
		}
	*/
		if (AnimatedGifInfo)
			AnimatedGifInfo->timerToken=Tcl_CreateTimerHandler(AnimatedGifInfo->image->GetFrameNo(0)->GetFrameDelay(), AnimateGif, (ClientData) AnimatedGifInfo);
	}

#endif // ANIMATE_GIFS

  LOG("Freeing memory used by buffer"); //
  image.FreeMemory(buffer);

  return TCL_OK;
}

int ChanWrite (Tcl_Interp *interp, CONST char *fileName, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr) {

  CxImage image;
  int Type = CXIMAGE_FORMAT_UNKNOWN;
  char * cxFormat = NULL;
  int alpha = 0;
  BYTE * pixelPtr = NULL;

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

  pixelPtr = (BYTE *) malloc(blockPtr->width * blockPtr->height * blockPtr->pixelSize);

  if (RGB2BGR(blockPtr, pixelPtr)) {
    alpha = 1;
  }

  if(!image.CreateFromArray(pixelPtr, blockPtr->width, blockPtr->height,
			    8 * blockPtr->pixelSize, blockPtr->pitch, true))
    {
      free(pixelPtr);
      Tcl_AppendResult(interp, image.GetLastError(), NULL);
      return TCL_ERROR;
    }

  free(pixelPtr);
  if (alpha == 0)
    image.AlphaDelete();

  if (Type == CXIMAGE_FORMAT_GIF)
    image.DecreaseBpp(8, true);

  if (!image.Save(fileName, Type)) {
    Tcl_AppendResult(interp, image.GetLastError(), NULL);
    return TCL_ERROR;
  }

  return TCL_OK;
}

int StringWrite (Tcl_Interp *interp, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr) {

  BYTE * buffer = NULL;
  long size = 0;
  int Type = CXIMAGE_FORMAT_UNKNOWN;
  char * cxFormat = NULL;
  BYTE * pixelPtr = NULL;
  int alpha = 0;
  CxImage image;

  if (format) {
    cxFormat = Tcl_GetStringFromObj(format, NULL);
    Type = GetFileTypeFromFormat(cxFormat);
  }

  if (Type == CXIMAGE_FORMAT_UNKNOWN) {
    Type = CXIMAGE_FORMAT_GIF;
  }

  pixelPtr = (BYTE *) malloc(blockPtr->width * blockPtr->height * blockPtr->pixelSize);

  if (RGB2BGR(blockPtr, pixelPtr)) {
    alpha = 1;
  }

  if(!image.CreateFromArray(pixelPtr, blockPtr->width, blockPtr->height,
			    8 * blockPtr->pixelSize, blockPtr->pitch, true))
    {
      free(pixelPtr);
      Tcl_AppendResult(interp, image.GetLastError(), NULL);
      return TCL_ERROR;
    }

  free(pixelPtr);
  if (alpha == 0)
    image.AlphaDelete();

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


#if ANIMATE_GIFS
void AnimateGif(ClientData data) {
	GifInfo *Info = (GifInfo *)data;
	if (Info) { //Info is valid
		Tk_ImageMaster master = (Tk_ImageMaster) *((void **) Info->Handle);
		if(master == Info->ImageMaster) {
		//Image is always the same
			if(g_EnableAnimated) {
				Info->CurrentFrame++;
				if(Info->CurrentFrame == Info->NumFrames)
					Info->CurrentFrame = 0;
				CxImage *image = Info->image->GetFrameNo(Info->CurrentFrame);
				Tk_ImageChanged(Info->ImageMaster, 0, 0, image->GetWidth(), image->GetHeight(), image->GetWidth(), image->GetHeight());
		
				Info->timerToken=Tcl_CreateTimerHandler(image->GetFrameDelay()?10*image->GetFrameDelay():40, AnimateGif, data);
			} else {
				int currentFrame = Info->CurrentFrame;
				CxImage *image = Info->image->GetFrameNo(currentFrame);
				Info->timerToken=Tcl_CreateTimerHandler(image->GetFrameDelay()?10*image->GetFrameDelay():40, AnimateGif, data);
			}
		} else {
			LOG("Image destroyed, deleting... Image Master was : ");
			APPENDLOG( master );
			APPENDLOG(" - ");
			APPENDLOG( Info->ImageMaster);

			Info->image->DestroyGifFrames();
			delete Info->image;
			LOG("Deleting AnimatedGifInfo");
			APPENDLOG(Info->Handle);
			TkCxImage_lstDeleteItem(Info->Handle);
			for(GifBuffersIterator it=Info->buffers.begin(); it!=Info->buffers.end(); it++){
				(*it)->Close();
				delete (*it);
			}
			delete Info;
			Info = NULL;
		}
	}

}

void PhotoDisplayProcHook(
	ClientData instanceData,
	Display *display,
	Drawable drawable,
	int imageX,
	int imageY,
	int width,
	int height,
	int drawableX,
	int drawableY){

#ifndef MAC_TCL
#ifndef WIN32

  /* 
   * The whole next block is used to prevent a bug with XGetImage
   * that happens with Tcl/Tk before 8.4.9 that caused a BadMatch.
   */
  Window root_geo;
  int x_geo, y_geo;
  unsigned int drawableWidth_geo;
  unsigned int drawableHeight_geo;
  unsigned int bd_geo;
  unsigned int depth_geo;
  
  // Make sure there's something to draw
  if (width < 1 || height < 1) {
    return;
  }
  
  // Get the drawable's width and height and x and y
  switch (XGetGeometry(display, drawable, &root_geo, &x_geo, &y_geo, 
		       &drawableWidth_geo, &drawableHeight_geo, &bd_geo, &depth_geo)) {
    
  case BadDrawable:
  case BadWindow:
    Tcl_Panic("ClipSizeForDrawable: invalid drawable passed"); 
    break;
  }
  
  // Make sure the coordinates are valid
  if (drawableX < 0) {
    drawableX = 0;
  }

  if (drawableY < 0) {
    drawableY = 0;
  }

  // Make sure we're not requesting a width or heigth more than allowed
  if (width + drawableX > drawableWidth_geo) {
    width = drawableWidth_geo - drawableX;
  }
  
  if (height + drawableY > drawableHeight_geo) {
    height = drawableHeight_geo - drawableY;
  }
  
  /*
   * End of the fix
   */

#endif
#endif


	Tk_PhotoHandle handle = (Tk_PhotoHandle) *((void **) instanceData);
	GifInfo* item=TkCxImage_lstGetItem(handle);
	if (item != NULL){
		if (item->CurrentFrame != item->CopiedFrame) { //Frame isn't the good one in the photo buffer
			CxImage *image = item->image->GetFrameNo(item->CurrentFrame);
			item->CopiedFrame = item->CurrentFrame; //We set the copied frame before to avoid infinite loops
			AnimatedGifFrameToTk(NULL, item, image, true);
			//fprintf(stderr, "Copied frame n°%u\n",item->CopiedFrame);
		}
	}

	

	
	PhotoDisplayOriginal(instanceData,display,drawable,imageX,imageY,width,height,drawableX,drawableY);
}

#endif // ANIMATE_GIFS
