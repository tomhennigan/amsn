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

  Tcl_Obj *data = Tcl_NewObj();
  int retVal;

  Tcl_SetChannelOption(interp, chan, "-encoding", "binary");
  Tcl_SetChannelOption(interp, chan, "-translation", "binary");
  
  Tcl_ReadChars(chan, data, -1, 0);
  
  LOG("Reading from file :"); //
  APPENDLOG(fileName); //
  
  retVal = ObjMatch(data, format, widthPtr, heightPtr, interp);
  Tcl_DecrRefCount(data);
  return retVal;

}


int ObjMatch (Tcl_Obj *data, Tcl_Obj *format, int *widthPtr, int *heightPtr, Tcl_Interp *interp) {

  BYTE * buffer = NULL;
  int length = 0;

  CxImage image;

  LOG("Data matching"); //

  buffer = Tcl_GetByteArrayFromObj(data, &length);

  if (image.CheckFormat(buffer,length,CXIMAGE_FORMAT_UNKNOWN)) {
    LOG("Supported Format : "); //
    APPENDLOG(image.GetType());
    LOG("Size : ");
    *widthPtr = image.GetWidth();
    *heightPtr = image.GetHeight();
    APPENDLOG(*widthPtr);
    APPENDLOG("x");
    APPENDLOG(*heightPtr);
    return true;
  }

  LOG("Unknown format");
  return false;
}

int ChanRead (Tcl_Interp *interp, Tcl_Channel chan, CONST char *fileName, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
		     int destX, int destY, int width, int height, int srcX, int srcY)
{
	Tcl_Obj *data = Tcl_NewObj();
	int retVal;

	Tcl_SetChannelOption(interp, chan, "-encoding", "binary");
	Tcl_SetChannelOption(interp, chan, "-translation", "binary");

	Tcl_ReadChars(chan, data, -1, 0);

	LOG("Reading from file :"); //
	APPENDLOG(fileName); //

	retVal = ObjRead(interp, data, format, imageHandle, destX, destY, width, height, srcX, srcY);
	Tcl_DecrRefCount(data);
	return retVal;
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
#if TK_MINOR_VERSION >= 5
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
		item->image->DestroyFrames();
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
	if(numframes > 1) {

		GifInfo * AnimatedGifInfo = new GifInfo;

		AnimatedGifInfo->CurrentFrame = 0;
		AnimatedGifInfo->CopiedFrame = -1;
		AnimatedGifInfo->NumFrames = numframes;
		AnimatedGifInfo->Handle = imageHandle;
		AnimatedGifInfo->ImageMaster = (Tk_ImageMaster) *((void **)imageHandle);
		AnimatedGifInfo->interp = interp;
		AnimatedGifInfo->image = new CxImage;
		AnimatedGifInfo->image->SetRetreiveAllFrames(true);
		AnimatedGifInfo->image->SetFrame(numframes - 1);
		AnimatedGifInfo->image->Decode(FileData, length, CXIMAGE_FORMAT_GIF);

		LOG("Adding AnimatedGifInfo");
		APPENDLOG(imageHandle);
		TkCxImage_lstAddItem(AnimatedGifInfo);

		AnimatedGifInfo->Enabled = true;
		if (AnimatedGifInfo)
			AnimatedGifInfo->timerToken=Tcl_CreateTimerHandler(AnimatedGifInfo->image->GetFrame(0)->GetFrameDelay(), AnimateGif, (ClientData) AnimatedGifInfo);
	}

#endif // ANIMATE_GIFS

  LOG("Freeing memory used by buffer"); //
  image.FreeMemory(buffer);

  return TCL_OK;
}

int ChanWrite (Tcl_Interp *interp, CONST char *fileName, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr) {

  int Type = CXIMAGE_FORMAT_UNKNOWN;
  char * cxFormat = NULL;
  Tcl_Obj *data = NULL;
  Tcl_Channel chan = Tcl_OpenFileChannel(interp, fileName, "w", 0644);

  if (chan == NULL)
    return TCL_ERROR;

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


  if (DataWrite(interp, Type, blockPtr) == TCL_ERROR) {
    return TCL_ERROR;
  }
  
  data = Tcl_GetObjResult(interp);

  Tcl_SetChannelOption(interp, chan, "-encoding", "binary");
  Tcl_SetChannelOption(interp, chan, "-translation", "binary");

  Tcl_WriteObj(chan, data);
    
  Tcl_ResetResult(interp);

  return Tcl_Close(interp, chan);
}

int StringWrite (Tcl_Interp *interp, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr) {

  int Type = CXIMAGE_FORMAT_UNKNOWN;
  char * cxFormat = NULL;

  if (format) {
    cxFormat = Tcl_GetStringFromObj(format, NULL);
    Type = GetFileTypeFromFormat(cxFormat);
  }

  if (Type == CXIMAGE_FORMAT_UNKNOWN) {
    Type = CXIMAGE_FORMAT_GIF;
  }

  return DataWrite(interp, Type, blockPtr);

}

int DataWrite (Tcl_Interp *interp, int Type, Tk_PhotoImageBlock *blockPtr) {

  BYTE * buffer = NULL;
  long size = 0;
  BYTE * pixelPtr = NULL;
  int alpha = 0;
  CxImage image;

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

  Tcl_SetObjResult(interp, Tcl_NewByteArrayObj(buffer, size));

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
			Info->CurrentFrame++;
			if(Info->CurrentFrame >= Info->NumFrames || Info->image->GetFrame(Info->CurrentFrame) == NULL)
				Info->CurrentFrame = 0;
			CxImage *image = Info->image->GetFrame(Info->CurrentFrame);
			Tk_ImageChanged(Info->ImageMaster, 0, 0, image->GetWidth(), image->GetHeight(), image->GetWidth(), image->GetHeight());
		
			Info->timerToken=Tcl_CreateTimerHandler(image->GetFrameDelay()?10*image->GetFrameDelay():40, AnimateGif, data);
		} else {
			LOG("Image destroyed, deleting... Image Master was : ");
			APPENDLOG( master );
			APPENDLOG(" - ");
			APPENDLOG( Info->ImageMaster);

			Info->image->DestroyFrames();
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

#if !defined(__APPLE__) && !defined (WIN32)

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
  if (width + drawableX > (int) drawableWidth_geo) {
    width = (int) drawableWidth_geo - drawableX;
  }
  
  if (height + drawableY > (int) drawableHeight_geo) {
    height = (int) drawableHeight_geo - drawableY;
  }
  
  /*
   * End of the fix
   */

#endif


	Tk_PhotoHandle handle = (Tk_PhotoHandle) *((void **) instanceData);
	GifInfo* item=TkCxImage_lstGetItem(handle);
	if (item != NULL){
		if (item->CurrentFrame != (unsigned int)item->CopiedFrame) { //Frame isn't the good one in the photo buffer
			CxImage *image = item->image->GetFrame(item->CurrentFrame);
			if (image == NULL) {
			  item->CurrentFrame = 0;
			  image = item->image->GetFrame(item->CurrentFrame);
			}
			item->CopiedFrame = item->CurrentFrame; //We set the copied frame before to avoid infinite loops
			AnimatedGifFrameToTk(NULL, item, image, true);
			//fprintf(stderr, "Copied frame n°%u\n",item->CopiedFrame);
		}
	}

	

	
	PhotoDisplayOriginal(instanceData,display,drawable,imageX,imageY,width,height,drawableX,drawableY);
}

#endif // ANIMATE_GIFS
