#include "capture.h"

// List management function prototypes
static struct list_ptr* Capture_lstGetListItem(char *list_element_id);
static struct data_item* Capture_lstAddItem(struct data_item* item);
static struct data_item* Capture_lstGetItem(char *list_element_id);
static struct data_item* Capture_lstDeleteItem(char *list_element_id);

static struct list_ptr* opened_devices = NULL;

/* List of TCL commands and their implementation */
static struct { char* command; Tcl_ObjCmdProc *proc; } proc_list[] = {
  { "::Capture::ListResolutions", Capture_ListResolutions },
  { "::Capture::ListDevices", Capture_ListDevices },
  { "::Capture::ListChannels", Capture_ListChannels },
  { "::Capture::Open", Capture_Open },
  { "::Capture::Close", Capture_Close },
  { "::Capture::ChangeResolution", Capture_ChangeResolution },
  { "::Capture::GetGrabber", Capture_GetGrabber },
  { "::Capture::Grab", Capture_Grab },
  { "::Capture::SetBrightness", Capture_SetAttribute },
  { "::Capture::SetContrast", Capture_SetAttribute },
  { "::Capture::SetHue", Capture_SetAttribute },
  { "::Capture::SetColour", Capture_SetAttribute },
  { "::Capture::GetBrightness", Capture_GetAttribute },
  { "::Capture::GetContrast", Capture_GetAttribute },
  { "::Capture::GetHue", Capture_GetAttribute },
  { "::Capture::GetColour", Capture_GetAttribute },
  { "::Capture::IsValid", Capture_IsValid },
  { "::Capture::ListGrabbers", Capture_ListGrabbers },
  { "::Capture::Debug", Capture_Debug },
  { NULL, NULL } // If you like segfaults, remove this!
};

/* Listhead structure */
struct list_ptr {
  struct list_ptr* prev_item;
  struct list_ptr* next_item;
  struct data_item* element;
};

/////////////////////////////////////
// Functions to manage lists       //
/////////////////////////////////////

/* Get a pointer to the listhead struct of the item with the specified name */
static struct list_ptr* Capture_lstGetListItem(char *list_element_id) {
  struct list_ptr* item = g_list;

  while(item && strcmp(item->element->list_element_id, list_element_id))
    item = item->next_item;

  return item;
}


/* Add an item to the list */
static struct data_item* Capture_lstAddItem(struct data_item* item) {
  struct list_ptr* newItem = NULL;

  if (!item) return NULL;
  if (Capture_lstGetListItem(item->list_element_id)) return NULL;

  newItem = (struct list_ptr *) calloc(1, sizeof(struct list_ptr));

  if (newItem) {
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


/* Get the item with the specified name */
static struct data_item* Capture_lstGetItem(char *list_element_id) {
  struct list_ptr* listitem = Capture_lstGetListItem(list_element_id);
  
  if (listitem)
    return listitem->element;
  else
    return NULL;
}


/* Remove the item with the specified name */
static struct data_item* Capture_lstDeleteItem(char *list_element_id) {
  struct list_ptr* item = Capture_lstGetListItem(list_element_id);
  struct data_item* element = NULL;
  
  if (item) {
    element = item->element;
    
    if(item->prev_item == NULL) // The first item
      g_list = item->next_item;
    else
      (item->prev_item)->next_item = item->next_item;
    
    if (item->next_item)
      (item->next_item)->prev_item = item->prev_item;
    
    free(item);
  }

  return element;
}


//////////////////////////////////////
// Other functions for internal use //
//////////////////////////////////////

/* Function for getting a pointer to the video buffer */
static struct ng_video_buf* get_video_buf(void *handle, struct ng_video_fmt *fmt) {
  return ((struct capture_item*) handle)->rgb_buffer;
}

/* Select the correct colorspace to use with a device */
static int set_color_conv(struct capture_item* captureItem, struct image_format* image_size)
{
  int i;
  unsigned int rw, rh;
  unsigned int w, h;
  unsigned int d, dmin = (unsigned int) -1;
  unsigned int bestfmtid;

  struct ng_video_conv *conv;
  struct ng_video_fmt gfmt;

  // Test if captureItem isn't NULL
  if(NULL == captureItem)
    return -1;

  rw = image_size->width;
  rh = image_size->height;

  // try native colorspace RGB24
  captureItem->fmt.fmtid  = VIDEO_RGB24;
  captureItem->fmt.width  = rw;
  captureItem->fmt.height = rh;
  if (captureItem->dev.v->setformat(captureItem->dev.handle,&captureItem->fmt) == 0) {
    w = captureItem->fmt.width;
    h = captureItem->fmt.height;
    d = min(w, rw) * min(h, rh);
    d = w*h + rw*rh - 2*d;
    if (d == 0)
      //What do you want more ?
      return 0;
    else {
      if (d < dmin) {
        bestfmtid = captureItem->fmt.fmtid;
        dmin = d;
      }
    }
  }
  // If failed, try native BGR24 (mostly all webcams on LE systems)
  captureItem->fmt.fmtid  = VIDEO_BGR24;
  captureItem->fmt.width  = rw;
  captureItem->fmt.height = rh;
  if (captureItem->dev.v->setformat(captureItem->dev.handle,&captureItem->fmt) == 0) {
    w = captureItem->fmt.width;
    h = captureItem->fmt.height;
    d = min(w, rw) * min(h, rh);
    d = w*h + rw*rh - 2*d;
    if (d == 0)
      //What do you want more ?
      return 0;
    else {
      if (d < dmin) {
        bestfmtid = captureItem->fmt.fmtid;
        dmin = d;
      }
    }
  }

  // If it failed, try to find a converter to RGB24
  captureItem->fmt.fmtid = VIDEO_RGB24;

  // check all available conversion functions
  captureItem->fmt.bytesperline = captureItem->fmt.width * ng_vfmt_to_depth[captureItem->fmt.fmtid] / 8;

  for (i = 0;;) {
    // Find a converter to RGB24
    if ((conv = ng_conv_find_to(VIDEO_RGB24, &i)) == NULL) break;

#   ifdef DEBUG
      fprintf(stderr, "Trying converter from %s to %s\n",
              ng_vfmt_to_desc[conv->fmtid_in],
              ng_vfmt_to_desc[conv->fmtid_out]);
#   endif

    // Set the new capture format to the colorspace of the input from the converter
    captureItem->fmt.fmtid = conv->fmtid_in;
    captureItem->fmt.width  = image_size->width;
    captureItem->fmt.height = image_size->height;
    captureItem->fmt.bytesperline = 0;
    
    // Check if webcam supports the input colorspace of that converter
    if (captureItem->dev.v->setformat(captureItem->dev.handle,&captureItem->fmt) == 0) {
      w = captureItem->fmt.width;
      h = captureItem->fmt.height;
      d = min(w, rw) * min(h, rh);
      d = w*h + rw*rh - 2*d;
      if (d == 0) {
        //What do you want more ?
        // Initialize the converter
        gfmt = captureItem->fmt;
        captureItem->fmt.fmtid = VIDEO_RGB24;
        captureItem->fmt.bytesperline = captureItem->fmt.width * ng_vfmt_to_depth[captureItem->fmt.fmtid] / 8;
        captureItem->handle = ng_conv_init(conv, &gfmt, &captureItem->fmt);
        return 0;
       } else {
         if (d < dmin) {
           bestfmtid = captureItem->fmt.fmtid;
           dmin = d;
         }
      }
    }
  }

  //If nothing was good we return -1
  if (dmin == (unsigned int)-1)
    return -1;

  //If we are here, it's because we didn't manage to find a good support for the requested size : we will now use the best fmtid
  captureItem->fmt.fmtid  = bestfmtid;
  captureItem->fmt.width  = rw;
  captureItem->fmt.height = rh;
  //I assume it could only return 0 else why would we be here ?
  captureItem->dev.v->setformat(captureItem->dev.handle,&captureItem->fmt);

  switch(bestfmtid) {
  case VIDEO_RGB24:
  case VIDEO_BGR24:
    break;
  default:
    //I assume conv must be different of 0 else the format couldn't have been enumerated
    conv = ng_conv_find_match(bestfmtid,VIDEO_RGB24);
    gfmt = captureItem->fmt;
    captureItem->fmt.fmtid = VIDEO_RGB24;
    captureItem->fmt.bytesperline = captureItem->fmt.width * ng_vfmt_to_depth[captureItem->fmt.fmtid] / 8;
    captureItem->handle = ng_conv_init(conv, &gfmt, &captureItem->fmt);
    break;
  }
  return 0;
}


/////////////////////////////////////
// Tcl command implementations     //
/////////////////////////////////////

/* ::Capture::ListResolutions - List supported resolutions */
int Capture_ListResolutions _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  Tcl_Obj *           lstResolutions = NULL;
  struct image_format* image_size = NULL;

  if (objc != 1) {
    Tcl_WrongNumArgs(interp, 1, objv, (char *)NULL);
    return TCL_ERROR;
  }

  lstResolutions=Tcl_NewListObj(0, NULL);

  for(image_size = formats_list; image_size->format_name != NULL; image_size++) {
    Tcl_ListObjAppendElement(interp,lstResolutions,Tcl_NewStringObj(image_size->format_name,-1));
  }

  Tcl_SetObjResult(interp,lstResolutions);
  return TCL_OK;
}

/* ::Capture::ListDevices - List available capture devices */
int Capture_ListDevices _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  struct ng_devinfo * info = NULL;
  char                name[50];
  int                 i = 0;

  Tcl_HashTable       table;
  int                 isNew;

  struct list_head *item;
  struct ng_vid_driver *drv;

  Tcl_Obj *           device[2] = { NULL, NULL };
  Tcl_Obj *           lstDevice = NULL;
  Tcl_Obj *           lstAll = NULL;
  
  if (objc != 1) {
    Tcl_WrongNumArgs(interp, 1, objv, (char *)NULL);
    return TCL_ERROR;
  }

  Tcl_InitHashTable(&table,TCL_STRING_KEYS);
  
  lstAll=Tcl_NewListObj(0, NULL);
  /* check all grabber drivers */
  list_for_each(item,&ng_vid_drivers) {
    drv = list_entry(item, struct ng_vid_driver, list);
    if (ng_debug)
      fprintf(stderr,"vid-probe: trying: %s... \n", drv->name);

    info = drv->probe(ng_debug);
    if (info) {
      // loop on all found devices
      for (i = 0; info[i].device[0] != 0; i++) {
#       ifdef DEBUG
          fprintf(stderr, "Found %s at %s\n", info[i].name, info[i].device);
#       endif

        strcpy(name, drv->name);
        strcat(name, ": ");
        strcat(name, info[i].name);

        Tcl_CreateHashEntry(&table, info[i].device, &isNew);
        if(isNew) {
          //The device wasn't listed yet...
          device[0]=Tcl_NewStringObj(info[i].device,-1);
          device[1]=Tcl_NewStringObj(name,-1);
          lstDevice=Tcl_NewListObj(2,device);
          Tcl_ListObjAppendElement(interp,lstAll,lstDevice);
        }
      }
    }
    free(info);
  }

  Tcl_DeleteHashTable(&table);

  Tcl_SetObjResult(interp,lstAll);
  return TCL_OK;
}


/* ::Capture::ListChannels - List the channels available on a capture device */
int Capture_ListChannels _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  char *                  device = NULL;
  int                     i;
  struct ng_devstate          dev;
  struct ng_attribute *attr = NULL;
  Tcl_Obj*                channel[2] = {NULL,NULL};
  Tcl_Obj*                lstChannel = NULL;
  Tcl_Obj*                lstAll = NULL;
  
  if (objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "devicename");
    return TCL_ERROR;
  }
  
  // Get the device name
  device = Tcl_GetStringFromObj(objv[1], NULL);
  
  // Init the device and let libng find the appropriate driver for it
  if (0 != ng_vid_init(&dev, device)) {
#   ifdef DEBUG
      fprintf(stderr,"no grabber device available\n");
#   endif
    Tcl_SetResult (interp, "no grabber device available\n" , TCL_STATIC);
    return TCL_ERROR;
  }

  // Search for the ATTR_ID_INPUT (channel) ng_attribute struct
  attr = ng_attr_byid(&dev, ATTR_ID_INPUT);

  lstAll=Tcl_NewListObj(0, NULL);

  // Lists the channels
  const char * devName = NULL;
  for(i=0; (devName = ng_attr_getstr(attr,i)) != NULL; i++) {
    channel[0] = Tcl_NewIntObj(i);
    channel[1] = Tcl_NewStringObj(devName,-1);
    lstChannel = Tcl_NewListObj(2,channel);
    Tcl_ListObjAppendElement(interp,lstAll,lstChannel);
  }

  ng_dev_fini(&dev);

  if (attr != NULL) {
    Tcl_SetObjResult(interp,lstAll);
    return TCL_OK;
  } else {
    Tcl_SetResult (interp, "Error getting channels list\n" , TCL_STATIC);
    return TCL_ERROR;
  }
}


/* ::Capture::GetGrabber - Get the grabber for the specified device and channel */
int Capture_GetGrabber _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  char * dev = NULL;
  int channel;
  struct list_ptr* item = opened_devices;
  
  // Check number of arguments
  if(objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "device channel");
    return TCL_ERROR;
  }
  
  // Get the device name
  dev = Tcl_GetStringFromObj(objv[1], NULL);
  
  // Get the channel
  if (Tcl_GetIntFromObj(interp, objv[2], &channel) == TCL_ERROR) {
    return TCL_ERROR;
  }
  
  // Find the correct grabber
  while (item) {
    if ((strcasecmp(dev,item->element->devicePath)==0) && (channel == item->element->channel)) {
      Tcl_SetResult(interp, item->element->captureName, TCL_VOLATILE);
      break;
    }
    item = item->next_item;
  }
  
  return TCL_OK;
}


/* ::Capture::ListGrabbers - List all available grabbers */
int Capture_ListGrabbers _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  struct list_ptr* item = opened_devices;
  Tcl_Obj* grabber[3] = { NULL, NULL, NULL };
  Tcl_Obj* lstGrabber = NULL;
  Tcl_Obj* lstAll = NULL;
  
  if (objc != 1) {
    Tcl_WrongNumArgs(interp, 1, objv, (char *)NULL);
    return TCL_ERROR;
  }
  
  lstAll = Tcl_NewListObj(0, NULL);
  
  while (item) {
#   ifdef DEBUG
      fprintf(stderr, "Grabber : %s for device %s and channel %d\n",
        item->element->captureName, item->element->devicePath, item->element->channel);
#   endif
    
    grabber[0] = Tcl_NewStringObj(item->element->captureName, -1);
    grabber[1] = Tcl_NewStringObj(item->element->devicePath, -1);
    grabber[2] = Tcl_NewIntObj(item->element->channel);
    lstGrabber = Tcl_NewListObj(3, grabber);
    Tcl_ListObjAppendElement(interp, lstAll, lstGrabber);
    item = item->next_item;
  }
  
  Tcl_SetObjResult(interp,lstAll);
  return TCL_OK;
}


/* ::Capture::Open - Open a capture descriptor */
int Capture_Open _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  static int currentCaptureNumber = 0;
  char *device = NULL, *tmpRes = NULL;
  struct ng_attribute *attr = NULL;
  struct capture_item* captureItem = NULL;
  struct image_format* image_size = NULL;
  int channel;
  
  // Check the number of arguments
  if (objc != 4) {
    Tcl_WrongNumArgs(interp, 1, objv, "device channel resolution");
    return TCL_ERROR;
  }
  
  // Get the argument values
  device = Tcl_GetStringFromObj(objv[1], NULL);
  
  if (Tcl_GetIntFromObj(interp, objv[2], &channel) == TCL_ERROR) {
    return TCL_ERROR;
  }

  tmpRes = Tcl_GetStringFromObj(objv[3], NULL);
  for(image_size = formats_list; image_size->format_name != NULL; image_size++) {
    if (!strcasecmp(image_size->format_name,tmpRes))
      break;
  }

  if (image_size->format_name == NULL) {
    Tcl_SetResult(interp, "The resolution chosen is invalid", TCL_STATIC);
    return TCL_ERROR;
  }
  
  // Allocate memory for the capture descriptor
  captureItem = (struct capture_item *) calloc(1, sizeof(struct capture_item));
  
  // Init the device and let libng find the appropriate driver for it
  if (0 != ng_vid_init(&captureItem->dev, device)) {
#   ifdef DEBUG
      fprintf(stderr,"no grabber device available\n");
#   endif
    Tcl_SetResult (interp, "no grabber device available\n" , TCL_STATIC);
    return TCL_ERROR;
  }
  
  // Check if we can capture from it
  if (!(captureItem->dev.flags & CAN_CAPTURE)) {
#   ifdef DEBUG
      fprintf(stderr,"device doesn't support capture\n");
#   endif
    Tcl_SetResult (interp, "device doesn't support capture\n" , TCL_STATIC);
    ng_dev_fini(&captureItem->dev);
    free(captureItem);
    return TCL_ERROR;
  }
  
  // If we get here, driver initialisation was sucessful
  // Now open the driver...
  ng_dev_open(&captureItem->dev);
  
  // Search for the ATTR_ID_INPUT (channel) ng_attribute struct
  attr = ng_attr_byid(&(captureItem->dev), ATTR_ID_INPUT);
  
  // Set the channel using ng_attribute->write function
  if (attr != NULL) {
    if (channel != -1)
      attr->write(attr, channel);
  }
  
  // Select the colorspace conversion to use, return an error if none is found (we can't do without!)
  if (set_color_conv(captureItem,image_size) != 0) {
#   ifdef DEBUG
      fprintf(stderr, "Your webcam uses a combination of palette/resolution that this extension does not support yet\n");
#   endif

    Tcl_SetResult (interp, "Your webcam uses a combination of palette/resolution that this extension does not support yet" , TCL_STATIC);
    ng_dev_close(&captureItem->dev);
    ng_dev_fini(&captureItem->dev);
    free(captureItem);
    return TCL_ERROR;
  }

  captureItem->requested_format = image_size;
  
  // Add the capture descriptor to the list of open descriptors, return an error if this fails
  if (Capture_lstAddItem(captureItem) == NULL) {
    perror("lstAddItem");
    ng_dev_close(&captureItem->dev);
    ng_dev_fini(&captureItem->dev);
    free(captureItem);
    return TCL_ERROR;
  }
  
  // Set the name, devicePath and channel properties of the capture descriptor
  sprintf(captureItem->captureName, "capture%d", currentCaptureNumber++);
  strcpy(captureItem->devicePath, device);
  captureItem->channel = channel;
  
  // If a converter was used, setup the converter and allocate a new rgb_buffer
  if (captureItem->handle) {
    // To setup the converter, you give it a proc and a handle.
    // The proc is used to return to the converter the output buffer where to store the result...
    ng_process_setup(captureItem->handle, get_video_buf, (void *)captureItem);
    captureItem->rgb_buffer = ng_malloc_video_buf(&captureItem->dev, &captureItem->fmt);
  }
  
  captureItem->dev.v->startvideo(captureItem->dev.handle, 25, 1);
  
  Tcl_SetResult(interp, captureItem->captureName, TCL_VOLATILE);
  
  return TCL_OK;
}


/* ::Capture::Close - Close a capture descriptor */
int Capture_Close _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  char *captureDescriptor = NULL;
  struct capture_item *capItem = NULL;
  
  if (objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "capturedescriptor");
    return TCL_ERROR;
  }
  
  captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
  if ((capItem = Capture_lstGetItem(captureDescriptor)) == NULL) {
    Tcl_SetResult(interp, "Invalid capture descriptor.", TCL_STATIC);
    return TCL_ERROR;
  }
  
  capItem->dev.v->stopvideo(capItem->dev.handle);

  // If a converter was used, close it and release the rgb_buffer
  if (capItem->handle) {
    ng_process_fini(capItem->handle);
    ng_release_video_buf(capItem->rgb_buffer);
  }
  
  // Close the device, and free the device structure
  ng_dev_close(&capItem->dev);
  ng_dev_fini(&capItem->dev);
  Capture_lstDeleteItem(captureDescriptor);
  free(capItem);
  
  return TCL_OK;
}

/* ::Capture::ChangeResolution - Change the resolution of an opened device */
int Capture_ChangeResolution _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  char *captureDescriptor = NULL, *tmpRes = NULL;
  struct capture_item *capItem = NULL;
  struct image_format* image_size = NULL;
  unsigned int retVal = TCL_OK;
  
  if (objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "capturedescriptor resolution");
    return TCL_ERROR;
  }
  
  captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
  if ((capItem = Capture_lstGetItem(captureDescriptor)) == NULL) {
    Tcl_SetResult(interp, "Invalid capture descriptor.", TCL_STATIC);
    return TCL_ERROR;
  }
  
  tmpRes = Tcl_GetStringFromObj(objv[2], NULL);
  for(image_size = formats_list; image_size->format_name != NULL; image_size++) {
    if (!strcasecmp(image_size->format_name,tmpRes))
      break;
  }

  if (image_size->format_name == NULL) {
    Tcl_SetResult(interp, "The resolution chosen is invalid", TCL_STATIC);
    return TCL_ERROR;
  }

  if (image_size == capItem->requested_format) {
    Tcl_SetResult(interp, "The resolution is the same", TCL_STATIC);
    //Nothing to do
    return TCL_OK;
  }

  capItem->dev.v->stopvideo(capItem->dev.handle);

  // If a converter was used, close it and release the rgb_buffer
  if (capItem->handle) {
    ng_process_fini(capItem->handle);
    capItem->handle = NULL;
    ng_release_video_buf(capItem->rgb_buffer);
    capItem->rgb_buffer = NULL;
  }

  // Select the colorspace conversion to use, return an error if none is found (we can't do without!)
  if (set_color_conv(capItem,image_size) != 0) {
#   ifdef DEBUG
      fprintf(stderr, "Your webcam uses a combination of palette/resolution that this extension does not support yet\n");
#   endif

    Tcl_SetResult (interp, "Your webcam uses a combination of palette/resolution that this extension does not support yet" , TCL_STATIC);
    retVal = TCL_ERROR;

    //Now we put back the old settings
    set_color_conv(capItem,capItem->requested_format);
  } else
    capItem->requested_format = image_size;

  // If a converter was used, setup the converter and allocate a new rgb_buffer
  if (capItem->handle) {
    // To setup the converter, you give it a proc and a handle.
    // The proc is used to return to the converter the output buffer where to store the result...
    ng_process_setup(capItem->handle, get_video_buf, (void *)capItem);
    capItem->rgb_buffer = ng_malloc_video_buf(&capItem->dev, &capItem->fmt);
  }
  
  capItem->dev.v->startvideo(capItem->dev.handle, 25, 1);

  return retVal;
}

/* ::Capture::Grab - Grab a frame */
int Capture_Grab _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{

  struct capture_item* capItem = NULL;
  char * captureDescriptor = NULL;
  char * image_name = NULL;
  char * tmpRes = NULL;
  int rw, rh;
  Tk_PhotoImageBlock block;
  Tk_PhotoHandle Photo;
  
  // Get command arguments and check their validity
  if (objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "capturedescriptor image_name");
    return TCL_ERROR;
  }
  
  captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
  image_name = Tcl_GetStringFromObj(objv[2], NULL);
  
  if ((Photo = Tk_FindPhoto(interp, image_name)) == NULL) {
    Tcl_SetResult(interp, "The image you specified is not a valid photo image", TCL_STATIC);
    return TCL_ERROR;
  }
  
  if ((capItem = Capture_lstGetItem(captureDescriptor)) == NULL) {
    Tcl_SetResult(interp, "Invalid capture descriptor. Please call Open first." , TCL_STATIC);
    return TCL_ERROR;
  }
  

  if ((capItem->image_data = capItem->dev.v->nextframe(capItem->dev.handle)) == NULL) {
# ifdef DEBUG
    fprintf(stderr,"Capturing image failed at %dx%d\n", capItem->fmt.width, capItem->fmt.height);
# endif
    Tcl_SetResult(interp, "Unable to capture from the device", TCL_STATIC);
    return TCL_ERROR;
  }
  
  // if a converter was used, put the frame into the converter and get it, once converted
  if (capItem->handle) {
    ng_process_put_frame(capItem->handle, capItem->image_data);
    capItem->rgb_buffer = ng_process_get_frame(capItem->handle);
  } else {
    capItem->rgb_buffer = capItem->image_data;
  }
  
  // We're not going to use this pointer any more.
  // No need to free it however:
  // - With a converter, libng freed it already.
  // - Without a converter, we still use it through capItem->rgb_buffer, which we free at the end of this function.
  capItem->image_data = NULL;
  
  // Setup block
  block.pixelPtr  = capItem->rgb_buffer->data;
  block.width = capItem->rgb_buffer->fmt.width;
  block.height = capItem->rgb_buffer->fmt.height;
  block.pitch = block.width * 3;
  block.pixelSize = 3;
  block.offset[1] = 1;
  block.offset[3] = -1;

  // Check for RGB24 vs. BGR24
  if (capItem->fmt.fmtid == VIDEO_RGB24) {
    block.offset[0] = 0;
    block.offset[2] = 2;
  } else {
    block.offset[0] = 2;
    block.offset[2] = 0;
  }

  Tk_PhotoSetSize( 
# if TK_MINOR_VERSION >= 5
    interp, 
# endif
    Photo, capItem->requested_format->width, capItem->requested_format->height);

  Tk_PhotoBlank(Photo);

  Tk_PhotoPutBlock(
# if TK_MINOR_VERSION >= 5
    interp, 
#endif
    Photo, &block, 0, 0, block.width, block.height 
# if TK_MINOR_VERSION >= 4
//Overlay is useless as our image hasn't any alpha channel
    , TK_PHOTO_COMPOSITE_SET 
# endif
    );


  Tcl_SetResult(interp, capItem->requested_format->format_name, TCL_VOLATILE);

  // Make sure to release the rgb_buffer if no converter is used so the next grab will not wait unnecessarily
  if (!capItem->handle)
    ng_release_video_buf(capItem->rgb_buffer);

  return TCL_OK;

}


/* ::Capture::SetBrightness - Set brightness
 * ::Capture::SetContrast   - Set contrast
 * ::Capture::SetHue        - Set Hue
 * ::Capture::SetColour     - Set colour */
int Capture_SetAttribute _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  struct ng_attribute *attr;
  char *captureDescriptor = NULL;
  char *proc = NULL;
  struct capture_item *capItem = NULL;
  int new_value = 0;
  int attribute;
  int value;
  
  // Check number of arguments
  if (objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "capture_descriptor new_value");
    return TCL_ERROR;
  }
  
  // Depending on the proc, choose the correct attribute to set
  proc = Tcl_GetStringFromObj(objv[0], NULL);
  if (!strcmp(proc, "::Capture::SetBrightness")) {
    attribute = ATTR_ID_BRIGHT;
  } else if (!strcmp(proc, "::Capture::SetContrast")) {
    attribute = ATTR_ID_CONTRAST;
  } else if (!strcmp(proc, "::Capture::SetHue")) {
    attribute = ATTR_ID_HUE;
  } else if (!strcmp(proc, "::Capture::SetColour")) {
    attribute = ATTR_ID_COLOR;
  } else {
    Tcl_SetResult(interp, "Wrong procedure name, should be either one of those: \n" \
        "::Capture::SetBrightness, ::Capture::SetContrast, ::Capture::SetHue, ::Capture::SetColour\n" , TCL_STATIC);
    return TCL_ERROR;
  }
  
  // Get the capture descriptor and check its validity
  captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
  if ((capItem = Capture_lstGetItem(captureDescriptor)) == NULL) {
    Tcl_SetResult (interp, "Invalid capture descriptor. Please call Open first." , TCL_STATIC);
    return TCL_ERROR;
  }
  
  // Get new_value and check its validity
  //2 conditions below modified to silently ignore erroneous value instead of throwing error
  if (Tcl_GetIntFromObj(interp, objv[2], &new_value) == TCL_ERROR) {
    return TCL_OK;
  }
  
  if (new_value > 65535 || new_value < 0) {
//    Tcl_SetResult(interp, "Invalid value. It should be between 0 and 65535" , TCL_STATIC);
//    return TCL_ERROR;
    return TCL_OK;
  }
  
  // Get the ng_attribute struct from the attribute id
  attr = ng_attr_byid(&(capItem->dev), attribute);
  
  // Set attribute value using attribute->write proc...
  if (attr != NULL) {
      if (new_value != -1)
        attr->write(attr, new_value);
  }
  
  return TCL_OK;
}


/* ::Capture::GetBrightness - Get brightness
 * ::Capture::GetContrast   - Get contrast
 * ::Capture::GetHue        - Get Hue
 * ::Capture::GetColour     - Get colour */
int Capture_GetAttribute _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  struct ng_attribute *attr;
  char *captureDescriptor = NULL;
  char *proc = NULL;
  char *bound = NULL;
  struct capture_item *capItem = NULL;
  enum { CURRENT = 0, MIN = 1, MAX = 2 } mode = CURRENT;
  int attribute;
  int value;
  
  // Check number of arguments
  if (objc != 2 && objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "capture_descriptor ?bound?");
    return TCL_ERROR;
  }
  
  // Depending on the proc, choose the correct attribute to get
  proc = Tcl_GetStringFromObj(objv[0], NULL);
  if (!strcmp(proc, "::Capture::GetBrightness")) {
    attribute = ATTR_ID_BRIGHT;
  } else if (!strcmp(proc, "::Capture::GetContrast")) {
    attribute = ATTR_ID_CONTRAST;
  } else if (!strcmp(proc, "::Capture::GetHue")) {
    attribute = ATTR_ID_HUE;
  } else if (!strcmp(proc, "::Capture::GetColour")) {
    attribute = ATTR_ID_COLOR;
  } else {
    Tcl_SetResult(interp, "Wrong procedure name, should be either one of those: \n" \
        "::Capture::GetBrightness, ::Capture::GetContrast, ::Capture::GetHue, ::Capture::GetColour" , TCL_STATIC);
    return TCL_ERROR;
  }
  
  if(objc == 3) {
    bound = Tcl_GetStringFromObj(objv[2], NULL);
    if (!strcmp(bound, "MAX")) {
      mode = MAX;
    } else if (!strcmp(bound, "MIN")) {
      mode = MIN;
    } else {
      Tcl_SetResult(interp, "The bound should be either \"MIN\" or \"MAX\"", TCL_STATIC);
      return TCL_ERROR;
    }
  }
  
  // Get the capture descriptor and check its validity
  captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
  if ((capItem = Capture_lstGetItem(captureDescriptor)) == NULL) {
    Tcl_SetResult(interp, "Invalid capture descriptor. Please call Open first." , TCL_STATIC);
    return TCL_ERROR;
  }
  
  // Get attribute value
  if ((attr = ng_attr_byid(&(capItem->dev), attribute)) != NULL) {
    switch (mode) {
      case CURRENT:
        value = attr->read(attr);
        break;
      case MIN:
        value = attr->min;
        break;
      case MAX:
        value = attr->max;
    }
    Tcl_SetObjResult(interp, Tcl_NewIntObj(value));
  } else {
    Tcl_SetObjResult(interp, Tcl_NewIntObj(0));
  }
  
  return TCL_OK;
}


/* ::Capture::IsValid - Check the validity of a capture descriptor */
int Capture_IsValid _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  char *captureDescriptor = NULL;
  
  // Check the number of arguments
  if (objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "capture_descriptor");
    return TCL_ERROR;
  }
  
  // Get captureDescriptor and determine if it is valid
  captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
  Tcl_SetObjResult(interp, Tcl_NewBooleanObj(Capture_lstGetItem(captureDescriptor) != NULL));
  
  return TCL_OK;
}

/* ::Capture::Debug - Set the ng_debug flag */
int Capture_Debug _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  // Check the number of arguments
  if (objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "flag");
    return TCL_ERROR;
  }

  return Tcl_GetIntFromObj(interp, objv[1], &ng_debug);
}

/* Initialisation of the capture extension */
int Capture_Init (Tcl_Interp *interp )
{
  int i;
  
  // Check Tcl version
  if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
    return TCL_ERROR;
  }
  
  // Check TK version
  if (Tk_InitStubs(interp, TK_VERSION, 0) == NULL) {
    return TCL_ERROR;
  }
  
  // Make our commands known to the interpreter
  for (i = 0; proc_list[i].command != NULL && proc_list[i].proc != NULL; i++)
  {
    Tcl_CreateObjCommand(interp,
      proc_list[i].command, proc_list[i].proc,
      (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  }
  
  // Initialise libng
# ifdef DEBUG
    ng_debug = 1;
# else
    ng_debug = 0;
# endif
  ng_init();
  
  // End of Initialisation
  return TCL_OK;
}


/* SafeInit dummy. Just points to Init */
int Capture_SafeInit (Tcl_Interp *interp ) {
  return Capture_Init(interp);
}
