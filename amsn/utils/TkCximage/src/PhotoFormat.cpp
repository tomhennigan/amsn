/*
  File : TkCximage.cpp

  Description :	Contains all functions for the Tk extension for the CxImage utility

  Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
*/

#include "TkCximage.h"

static struct list_ptr* animated_gifs = NULL;

struct list_ptr {
	struct list_ptr* prev_item;
	struct list_ptr* next_item;
	struct data_item* element;
};

/////////////////////////////////////
// Functions to manage lists       //
/////////////////////////////////////

struct list_ptr* TkCxImage_lstGetListItem(Tk_PhotoHandle list_element_id){ //Get the list item with the specified name
  struct list_ptr* item = g_list;

  while(item && (item->element->list_element_id != list_element_id))
    item = item->next_item;

  return item;

}


struct data_item* TkCxImage_lstAddItem(struct data_item* item) {
  struct list_ptr* newItem = NULL;

  if (!item) return NULL;
  if (TkCxImage_lstGetListItem(item->list_element_id)) return NULL;

  newItem = (struct list_ptr *) malloc(sizeof(struct list_ptr));

  if(newItem) {
    memset(newItem,0,sizeof(struct list_ptr));
    newItem->element = item;

    newItem->next_item = g_list;

    if (g_list) {
      g_list->prev_item = newItem;
    }
    g_list = newItem;

    return newItem->element;
  } else
    return NULL;

}

struct data_item* TkCxImage_lstGetItem(Tk_PhotoHandle list_element_id){ //Get the item with the specified name
	struct list_ptr* listitem = TkCxImage_lstGetListItem(list_element_id);
	if(listitem)
		return listitem->element;
	else
		return NULL;
}

struct data_item* TkCxImage_lstDeleteItem(Tk_PhotoHandle list_element_id){
	struct list_ptr* item = TkCxImage_lstGetListItem(list_element_id);
	struct data_item* element = NULL;

	if(item) {
	  element = item->element;
	  if(item->prev_item==NULL) //The first item
	    g_list = item->next_item;
	  else
	    (item->prev_item)->next_item = item->next_item;

	  if (item->next_item)
	    (item->next_item)->prev_item = item->prev_item;

	  free(item);
	}

	return element;
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

  if (image.AlphaIsValid()) {
    LOG("Alpha is valid, setting offset[3]"); //
    block.offset[3] = 3;
  }

  LOG("Putting Block into image"); //
#if TK_MINOR_VERSION == 3
  Tk_PhotoPutBlock(imageHandle, &block, destX, destY, width, height);
#else
#if TK_MINOR_VERSION == 4
  Tk_PhotoPutBlock(imageHandle, &block, destX, destY, width, height, TK_PHOTO_COMPOSITE_OVERLAY);
#else
#if TK_MINOR_VERSION == 5
  Tk_PhotoPutBlock((Tcl_Interp *) NULL, imageHandle, &block, destX, destY, width, height, TK_PHOTO_COMPOSITE_OVERLAY);
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
		LOG("Deleting AnimatedGifInfo");
		APPENDLOG(item->Handle);
		TkCxImage_lstDeleteItem(item->Handle);
		delete item;
	}
  // If it's an animated gif, take care of it right here
	if(g_EnableAnimated && numframes > 1) {

		GifInfo * AnimatedGifInfo = new GifInfo;
		CxImage *image = NULL;

		AnimatedGifInfo->CurrentFrame = 1;
		AnimatedGifInfo->NumFrames = numframes;
		AnimatedGifInfo->Handle = imageHandle;
		AnimatedGifInfo->HandleMaster  = *((void **) (imageHandle));
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
	if(g_EnableAnimated && Info) {
		CxImage *image = Info->image->GetFrameNo(Info->CurrentFrame);
		void * tkMaster = *((void **) (Info->Handle));

		if(tkMaster == Info->HandleMaster && CopyImageToTk(NULL, image, Info->Handle, image->GetWidth(), image->GetHeight(), false) == TCL_OK) {
			Info->CurrentFrame++;
			if(Info->CurrentFrame == Info->NumFrames)
				Info->CurrentFrame = 0;

			Info->timerToken=Tcl_CreateTimerHandler(image->GetFrameDelay()?10*image->GetFrameDelay():40, AnimateGif, data);

		} else {
		  LOG("Image destroyed, deleting... tkMaster was : ");
		  APPENDLOG( tkMaster );
		  APPENDLOG(" - ");
		  APPENDLOG( Info->HandleMaster);

			Info->image->DestroyGifFrames();
			delete Info->image;
			LOG("Deleting AnimatedGifInfo");
			APPENDLOG(Info->Handle);
			TkCxImage_lstDeleteItem(Info->Handle);
			delete Info;
			Info = NULL;
		}
	} else if (Info) {
		int currentFrame = Info->CurrentFrame;
		if(currentFrame)
			currentFrame--;
		else
			currentFrame = Info->NumFrames;
		CxImage *image = Info->image->GetFrameNo(currentFrame);
		Info->timerToken=Tcl_CreateTimerHandler(image->GetFrameDelay()?10*image->GetFrameDelay():40, AnimateGif, data);
	}

}

#endif // ANIMATE_GIFS
