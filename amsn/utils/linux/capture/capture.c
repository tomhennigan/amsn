#include "capture.h"

struct capture_item {
	char captureName[32];
	char devicePath[32];
	int channel;
	int fvideo;
	struct video_window vw;
	char *mmbuf; //To uncomment if we use mmap : not for now
	struct video_mbuf       mb;
};

struct capture_listitem {
	struct capture_listitem* prev_item;
	struct capture_listitem* next_item;
	struct capture_item data;
};

static struct capture_listitem* openeddevices=NULL;
static int curentCaptureNumber=0;


/////////////////////////////////////
// Functions to manage lists       //
/////////////////////////////////////

struct capture_item* lstCreateItem(){ // Create an item in the list and put it at the begin
	struct capture_listitem* newItem;
	newItem=(struct capture_listitem *) malloc(sizeof(struct capture_listitem));
	if(newItem!=NULL){
		memset(newItem,0,sizeof(struct capture_listitem));
		newItem->next_item=openeddevices;
		if (openeddevices!=NULL) {
			openeddevices->prev_item=newItem;
		}
		openeddevices=newItem;
	}
	return &newItem->data;
}

struct capture_listitem* lstGetListItem(char *captureName){ //Get the list item with the specified name
	struct capture_listitem* item=openeddevices;
	while(item!=NULL){
		if(strcmp(item->data.captureName,captureName)==0){
			break;
		}
		item=item->next_item;
	}
	return item;
}

struct capture_item* lstGetItem(char *captureName){ //Get the item with the specified name
	struct capture_listitem* listitem=lstGetListItem(captureName);
	if(listitem!=NULL)
		return &listitem->data;
	else
		return NULL;
}

void lstDeleteItem(char *captureName){
	struct capture_listitem* item=lstGetListItem(captureName);
	if(item!=NULL){
		if(item->prev_item==NULL){ //The first item
			openeddevices=item->next_item;
		}
		else {
			(item->prev_item)->next_item=item->next_item;
		}
		free(item);
	}
}


/////////////////////////////////////
// Functions to grab images        //
/////////////////////////////////////

int GetGoodSize(int min, int max, int prefered){
	if((min<=prefered)&&(prefered<=max)){
		return prefered;
	}
	else if (prefered<min) {
		return min;
	}
	else {
		return max;
	}
}

int Capture_ListDevices _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	char filename[15];
	int device_idx = 0;
	int fd=0;
	struct video_capability vcap;
	Tcl_Obj* device[2]={NULL,NULL};
	Tcl_Obj* lstDevice=NULL;
	Tcl_Obj* lstAll=NULL;

	if( objc != 1) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::ListDevices\"" , (char *) NULL);
		return TCL_ERROR;
	}

	lstAll=Tcl_NewListObj(0, NULL);

//	strcpy(filename, "/dev/video");
	sprintf(filename, "/dev/video%d", device_idx);
	while( ((fd = open(filename, O_RDONLY)) != -1) || ((errno != ENOENT) && (errno != ENODEV)) ){
//		fprintf(stderr,"Device %d : fd=%d errno=%d\n",device_idx,fd,errno);
//		fprintf(stderr,"%s : %d\n",filename,fd);

		if (fd!=-1) {
			if (ioctl(fd, VIDIOCGCAP, &vcap) < 0) {
				perror("VIDIOCGCAP");
				return TCL_ERROR;
			}
		}
		else {
			vcap.name[0]='\0';
		}

		device[0]=Tcl_NewStringObj(filename,-1);
		device[1]=Tcl_NewStringObj(vcap.name,-1);
		lstDevice=Tcl_NewListObj(2,device);
		Tcl_ListObjAppendElement(interp,lstAll,lstDevice);

		close(fd);
		device_idx ++;
		sprintf(filename, "/dev/video%d", device_idx);
	}
	Tcl_SetObjResult(interp,lstAll);
	return TCL_OK;
}

int Capture_ListChannels _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	char * dev = NULL;
	struct video_capability vcap;
	struct video_channel    vc;
	int i;
	int fvideo;
	Tcl_Obj* channel[2]={NULL,NULL};
	Tcl_Obj* lstChannel=NULL;
	Tcl_Obj* lstAll=NULL;

	if( objc != 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::ListChannels devicename\"" , (char *) NULL);
		return TCL_ERROR;
	}

	dev = Tcl_GetStringFromObj(objv[1], NULL);

	if ((fvideo = open(dev, O_RDONLY))==-1){
		Tcl_AppendResult (interp, "Error opening device" , (char *) NULL);
		return TCL_ERROR;
	}
	if (ioctl(fvideo, VIDIOCGCAP, &vcap) < 0) {
		Tcl_AppendResult (interp, "Error getting capabilities" , (char *) NULL);
		close(fvideo);
		return TCL_ERROR;
	}

	lstAll=Tcl_NewListObj(0, NULL);

	for(i=0; i<vcap.channels; i++) {
		vc.channel = i;
		if (ioctl(fvideo, VIDIOCGCHAN, &vc) < 0){
			Tcl_AppendResult (interp, "Error getting capabilities" , (char *) NULL);
			close(fvideo);
			return TCL_ERROR;
		}
		fprintf(stderr,"Video Source (%d) Name : %s\n",i, vc.name);
		fprintf(stderr, "channel %d: %s ", vc.channel, vc.name);
		fprintf(stderr, "%d tuners, has ", vc.tuners);
		if (vc.flags & VIDEO_VC_TUNER) fprintf(stderr, "tuner(s) ");
		if (vc.flags & VIDEO_VC_AUDIO) fprintf(stderr, "audio ");
		fprintf(stderr, "\ntype: ");
		if (vc.type & VIDEO_TYPE_TV) fprintf(stderr, "TV ");
		if (vc.type & VIDEO_TYPE_CAMERA) fprintf(stderr, "CAMERA ");
		fprintf(stderr, "norm: %d\n", vc.norm);

		channel[0]=Tcl_NewIntObj(vc.channel);
		channel[1]=Tcl_NewStringObj(vc.name,-1);
		lstChannel=Tcl_NewListObj(2,channel);
		Tcl_ListObjAppendElement(interp,lstAll,lstChannel);

	}

	close(fvideo);

	Tcl_SetObjResult(interp,lstAll);
	return TCL_OK;
}

int Capture_GetGrabber _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	char * dev = NULL;
	int channel;
	struct capture_listitem* item=openeddevices;

	if( objc != 3) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::Init device channel\"" , (char *) NULL);
		return TCL_ERROR;
	}

	dev = Tcl_GetStringFromObj(objv[1], NULL);

	if(Tcl_GetIntFromObj(interp, objv[2], &channel)==TCL_ERROR){
		return TCL_ERROR;
	}

	while(item!=NULL){
		if((strcasecmp(dev,item->data.devicePath)==0) && (channel == item->data.channel)){
			Tcl_SetObjResult(interp, Tcl_NewStringObj(item->data.captureName,-1));
			break;
		}
	}
	return TCL_OK;

}

int Capture_Open _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{

	char * dev = NULL;
	int fvideo;
	int channel;
	char mmapway=0;
	struct capture_item* captureItem=NULL;

	struct video_capability vcap;
	struct video_channel    vc;
	struct video_picture    vp;
	struct video_window     vw;

	BYTE* image_data=NULL;
	char *mmbuf=NULL; //To uncomment if we use mmap : not for now
	struct video_mbuf       mb;

	//int i;
	int bright, cont, hue, colour;

	bright = 42767;
	cont = 22767;
	hue = 32767;
	colour = 44767;

	if( objc != 3) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::Init device channel\"" , (char *) NULL);
		return TCL_ERROR;
	}

	dev = Tcl_GetStringFromObj(objv[1], NULL);

	if(Tcl_GetIntFromObj(interp, objv[2], &channel)==TCL_ERROR){
		return TCL_ERROR;
	}

	if ((fvideo = open(dev, O_RDONLY)) < 0) {
		perror("open");
		return TCL_ERROR;
	}

	if (ioctl(fvideo, VIDIOCGCAP, &vcap) < 0) {
		perror("VIDIOCGCAP");
		close(fvideo);
		return TCL_ERROR;
	}


	fprintf(stderr,"Video Capture Device Name : %s\n",vcap.name);
	fprintf(stderr,"%d < width < %d : %d < height < %d\n",
		vcap.minwidth, vcap.maxwidth, vcap.minheight, vcap.maxheight);
	if (vcap.type & VID_TYPE_CAPTURE) fprintf(stderr, "Can capture\n");
	if (vcap.type & VID_TYPE_TUNER) fprintf(stderr, "Has tuner\n");
	if (vcap.type & VID_TYPE_TELETEXT) fprintf(stderr, "Has teletext\n");
	if (vcap.type & VID_TYPE_OVERLAY) fprintf(stderr, "Can overlay\n");
	if (vcap.type & VID_TYPE_CHROMAKEY) fprintf(stderr, "Chromakeyed overlay\n");
	if (vcap.type & VID_TYPE_CLIPPING) fprintf(stderr, "Overlay clipping\n");
	if (vcap.type & VID_TYPE_FRAMERAM) fprintf(stderr, "Overwrites frame buffer\n");
	if (vcap.type & VID_TYPE_SCALES) fprintf(stderr, "Image scaling\n");
	if (vcap.type & VID_TYPE_MONOCHROME) fprintf(stderr, "Grey scale only\n");
	if (vcap.type & VID_TYPE_SUBCAPTURE) fprintf(stderr, "Can subcapture\n");

	if(channel>=vcap.channels){
		Tcl_AppendResult (interp, "Invalid channel" , (char *) NULL);
		return TCL_ERROR;
	}

/*	for(i=0; i<vcap.channels; i++) {
		vc.channel = i;
		if (ioctl(fvideo, VIDIOCGCHAN, &vc) < 0){
			perror("VIDIOCGCHAN");
			close(fvideo);
			return TCL_ERROR;
		}
		fprintf(stderr,"Video Source (%d) Name : %s\n",i, vc.name);
		fprintf(stderr, "channel %d: %s ", vc.channel, vc.name);
		fprintf(stderr, "%d tuners, has ", vc.tuners);
		if (vc.flags & VIDEO_VC_TUNER) fprintf(stderr, "tuner(s) ");
		if (vc.flags & VIDEO_VC_AUDIO) fprintf(stderr, "audio ");
		fprintf(stderr, "\ntype: ");
		if (vc.type & VIDEO_TYPE_TV) fprintf(stderr, "TV ");
		if (vc.type & VIDEO_TYPE_CAMERA) fprintf(stderr, "CAMERA ");
		fprintf(stderr, "norm: %d\n", vc.norm);
	}*/

	if(ioctl(fvideo, VIDIOCGPICT, &vp)<0){
		perror("VIDIOCGPICT");
		close(fvideo);
		return TCL_ERROR;
	}

	fprintf(stderr, "picture: brightness %d hue %d colour %d\n",
		vp.brightness, vp.hue, vp.colour);
	fprintf(stderr, "contrast %d whiteness %d depth %d\n",
		vp.contrast, vp.whiteness, vp.depth);
	fprintf(stderr, "palettes: ");
	if (vp.palette & VIDEO_PALETTE_GREY) fprintf(stderr, "GREY ");
	if (vp.palette & VIDEO_PALETTE_HI240) fprintf(stderr, "HI240 ");
	if (vp.palette & VIDEO_PALETTE_RGB565) fprintf(stderr, "RGB565 ");
	if (vp.palette & VIDEO_PALETTE_RGB555) fprintf(stderr, "RGB555 ");
	if (vp.palette & VIDEO_PALETTE_RGB24) fprintf(stderr, "RGB24 ");
	if (vp.palette & VIDEO_PALETTE_YUYV) fprintf(stderr, "YUYV ");
	if (vp.palette & VIDEO_PALETTE_UYVY) fprintf(stderr, "UYVY ");
	if (vp.palette & VIDEO_PALETTE_YUV411) fprintf(stderr, "YUV411 ");
	if (vp.palette & VIDEO_PALETTE_YUV420) fprintf(stderr, "YUV420 ");
	if (vp.palette & VIDEO_PALETTE_YUV422) fprintf(stderr, "YUV422 ");
	if (vp.palette & VIDEO_PALETTE_RAW) fprintf(stderr, "RAW ");
	if (vp.palette & VIDEO_PALETTE_YUV411P) fprintf(stderr, "YUV411P ");
	if (vp.palette & VIDEO_PALETTE_YUV420P) fprintf(stderr, "YUV420P ");
	if (vp.palette & VIDEO_PALETTE_YUV422P) fprintf(stderr, "YUV422P ");
	fprintf(stderr, "\n");


	vc.channel = channel;
	vc.type = VIDEO_TYPE_CAMERA;
	vc.norm = 0;
	if(ioctl(fvideo, VIDIOCSCHAN, &vc) < 0){
		perror("VIDIOCSCHAN");
		close(fvideo);
		return TCL_ERROR;
	}

	if(ioctl(fvideo, VIDIOCGWIN, &vw)<0){
		perror("VIDIOCGWIN");
		close(fvideo);
		return TCL_ERROR;
	}

	fprintf(stderr, "window: x %d y %d w %d h %d\n",vw.x,vw.y,vw.width,vw.height);
	fprintf(stderr, "window: flags %d chromakey %d\n",vw.flags,vw.chromakey);

	vw.x=0;
	vw.y=0;
	vw.width=GetGoodSize(vcap.minwidth,vcap.maxwidth,320);
	vw.height=GetGoodSize(vcap.minheight,vcap.maxheight,240);

	fprintf(stderr, "window: x %d y %d w %d h %d\n",vw.x,vw.y,vw.width,vw.height);
	fprintf(stderr, "window: flags %d chromakey %d\n",vw.flags,vw.chromakey);

	if(ioctl(fvideo, VIDIOCSWIN, &vw)<0){
		perror("VIDIOCSWIN");
		close(fvideo);
		return TCL_ERROR;
	}

	/*if(ioctl(fvideo, VIDIOCGWIN, &vw)<0){
		perror("VIDIOCGWIN");
		close(fvideo);
		return TCL_ERROR;
	}

	fprintf(stderr, "window: x %d y %d w %d h %d\n",vw.x,vw.y,vw.width,vw.height);
	fprintf(stderr, "window: flags %d chromakey %d\n",vw.flags,vw.chromakey);*/

	/* set default picture parameters */
	vp.depth = 24;

/* 	vp.brightness = bright; */
/* 	vp.contrast = cont; */
/* 	vp.hue = hue; */
/* 	vp.colour = colour; */

	vp.palette = VIDEO_PALETTE_RGB24;

	if (ioctl(fvideo, VIDIOCSPICT, &vp)) {
		perror("set picture");
		close(fvideo);
		return TCL_ERROR;
	}

	image_data = (BYTE *) malloc(vw.width*vw.height*3);

	if (read(fvideo,image_data,vw.width*vw.height*3)==-1){ //Try the mmap way if read fails
		mmapway=1;
		perror("read failed -> switching to mmap way\nerrno");
		if (ioctl(fvideo, VIDIOCGMBUF, &mb)) {
			perror("VIDIOCGMBUF");
			close(fvideo);
			return TCL_ERROR;
		}

		mmbuf = (unsigned char*)mmap(0, mb.size,
				PROT_READ, MAP_SHARED, fvideo, 0);
		if(mmbuf == MAP_FAILED){
			perror("mmap");
			close(fvideo);
			return TCL_ERROR;
		}
	}

	free(image_data);

	if((captureItem=lstCreateItem())==NULL){
		perror("lstCreateItem");
		close(fvideo);
		return TCL_ERROR;
	}

	sprintf(captureItem->captureName,"capture%d",curentCaptureNumber);
	curentCaptureNumber++;

	strncpy(captureItem->devicePath,dev,sizeof(captureItem->devicePath));
	captureItem->channel=channel;

	captureItem->fvideo=fvideo;
	memcpy(&captureItem->vw,&vw,sizeof(captureItem->vw));

	if(mmapway){
		memcpy(&captureItem->mb,&mb,sizeof(captureItem->mb));
		captureItem->mmbuf=mmbuf;
	}

	Tcl_SetObjResult(interp, Tcl_NewStringObj(captureItem->captureName,-1));

	return TCL_OK;
}

int Capture_Close _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	char *captureDescriptor=NULL;
	struct capture_item *capItem=NULL;
	if( objc != 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::Close capturedescriptor\"" , (char *) NULL);
		return TCL_ERROR;
	}

	captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
	if((capItem=lstGetItem(captureDescriptor))==NULL) {
		Tcl_AppendResult (interp, "Invalid capture descriptor. Please call Open before." , (char *) NULL);
		return TCL_ERROR;
	}

	if(capItem->mmbuf){
		munmap(capItem->mmbuf,capItem->mb.size);
	}

	close(capItem->fvideo);
	lstDeleteItem(captureDescriptor);
	return TCL_OK;
}

int Capture_Grab _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	struct capture_item*    capItem=NULL;
	char *                  captureDescriptor=NULL;

	char *                  image_name = NULL;
	Tk_PhotoHandle          Photo;
	BYTE *                  image_data = NULL;

	struct video_window     vw;
	struct video_mmap       mm;

	if( objc != 3) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::Grab capturedescriptor image_name\"" , (char *) NULL);
		return TCL_ERROR;
	}

	captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
	image_name = Tcl_GetStringFromObj(objv[2], NULL);

	if ( (Photo = Tk_FindPhoto(interp, image_name)) == NULL) {
		Tcl_AppendResult(interp, "The image you specified is not a valid photo image", NULL);
		return TCL_ERROR;
	}

	if( (capItem=lstGetItem(captureDescriptor)) == NULL){
		Tcl_AppendResult (interp, "Invalid capture descriptor. Please call Open before." , (char *) NULL);
		return TCL_ERROR;
	}

	/*if(ioctl(capItem->fvideo, VIDIOCGWIN, &vw)<0){
		perror("VIDIOCGWIN");
		return TCL_ERROR;
	}*/

	memcpy(&vw,&capItem->vw,sizeof(vw));

	if (capItem->mmbuf){
		mm.frame  = 0;
		mm.height = vw.height;
		mm.width  = vw.width;
		mm.format = VIDEO_PALETTE_RGB24;

		if(ioctl(capItem->fvideo, VIDIOCMCAPTURE, &mm)<0){
			perror("VIDIOCMCAPTURE");
			return TCL_ERROR;
		}

		if(ioctl(capItem->fvideo, VIDIOCSYNC, &mm.frame)<0){
			perror("VIDIOCSYNC");
			return TCL_ERROR;
		}
	}

	image_data = (BYTE *) malloc(vw.width*vw.height*3);

	if (capItem->mmbuf){
		memcpy(image_data, capItem->mmbuf+capItem->mb.offsets[0], mm.width*mm.height*3);
	}
	else {
		read(capItem->fvideo,image_data,vw.width*vw.height*3);
	}

	Tk_PhotoBlank(Photo);

	#if TK_MINOR_VERSION == 3
		Tk_PhotoSetSize(Photo, vw.width, vw.height);
	#endif
	#if TK_MINOR_VERSION == 4
		Tk_PhotoSetSize(Photo, vw.width, vw.height);
	#endif
	#if TK_MINOR_VERSION == 5
		Tk_PhotoSetSize(interp, Photo, vw.width, vw.height);
	#endif


	Tk_PhotoImageBlock block = {
		image_data,	// pixel ptr
		vw.width,
		vw.height,
		vw.width*3,	// pitch : number of bytes separating 2 adjacent pixels vertically
		3,		// pixel size : size in bytes of one pixel .. 4 = RGBA
		};

	block.offset[0] = 2;
	block.offset[1] = 1;
	block.offset[2] = 0;
	block.offset[3] = -1;

	#if TK_MINOR_VERSION == 3
		Tk_PhotoPutBlock(Photo, &block, 0, 0, vw.width, vw.height);
	#endif
	#if TK_MINOR_VERSION == 4
		Tk_PhotoPutBlock(Photo, &block, 0, 0, vw.width, vw.height, TK_PHOTO_COMPOSITE_OVERLAY);
	#endif
	#if TK_MINOR_VERSION == 5
		Tk_PhotoPutBlock(interp, Photo, &block, 0, 0, vw.width, vw.height, TK_PHOTO_COMPOSITE_OVERLAY);
	#endif

	free(image_data);

	#if TK_MINOR_VERSION == 3
		Tk_PhotoSetSize(Photo, 320, 240);
	#endif
	#if TK_MINOR_VERSION == 4
		Tk_PhotoSetSize(Photo, 320, 240);
	#endif
	#if TK_MINOR_VERSION == 5
		Tk_PhotoSetSize(interp, Photo, 320, 240);
	#endif

	return TCL_OK;
}

int Capture_AccessSettings _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	char *captureDescriptor = NULL;
	char *proc = NULL;
	struct capture_item *capItem = NULL;
	int new_value = 0;
	int setting = 0;
	struct video_picture vp;


	proc = Tcl_GetStringFromObj(objv[0], NULL);

	if (!strcmp(proc, "::Capture::SetBrightness")) {
	  setting = SETTINGS_SET_BRIGHTNESS;
	} else if (!strcmp(proc, "::Capture::SetContrast")) {
	  setting = SETTINGS_SET_CONTRAST;
	} else if (!strcmp(proc, "::Capture::SetHue")) {
	  setting = SETTINGS_SET_HUE;
	} else if (!strcmp(proc, "::Capture::SetColour")) {
	  setting = SETTINGS_SET_COLOUR;
	} else if (!strcmp(proc, "::Capture::GetBrightness")) {
	  setting = SETTINGS_GET_BRIGHTNESS;
	} else if (!strcmp(proc, "::Capture::GetContrast")) {
	  setting = SETTINGS_GET_CONTRAST;
	} else if (!strcmp(proc, "::Capture::GetHue")) {
	  setting = SETTINGS_GET_HUE;
	} else if (!strcmp(proc, "::Capture::GetColour")) {
	  setting = SETTINGS_GET_COLOUR;
	}

	if ( setting == 0 ) {
	  Tcl_ResetResult(interp);
	  Tcl_AppendResult (interp, "Wrong procedure name, should be either one of those : \n" , (char *) NULL);
	  Tcl_AppendResult (interp, "::Capture::SetBrightness, ::Capture::SetContrast, ::Capture::SetHue, ::Capture::SetColour\n" , (char *) NULL);
	  Tcl_AppendResult (interp, "::Capture::GetBrightness, ::Capture::GetContrast, ::Capture::GetHue, ::Capture::GetColour" , (char *) NULL);
	  return TCL_ERROR;
	}

	if ( (setting & SETTINGS_SET) && objc != 3) {
		Tcl_WrongNumArgs (interp, 1, objv, "capture_descriptor new_value");
		return TCL_ERROR;
	}
	if ( (setting & SETTINGS_GET) && objc != 2) {
		Tcl_WrongNumArgs (interp, 1, objv, "capture_descriptor");
		return TCL_ERROR;
	}

	captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);

	if((capItem=lstGetItem(captureDescriptor))==NULL){
		Tcl_AppendResult (interp, "Invalid capture descriptor. Please call Open before." , (char *) NULL);
		return TCL_ERROR;
	}

	if (setting & SETTINGS_SET) {
	  if(Tcl_GetIntFromObj(interp, objv[2], &new_value)==TCL_ERROR){
	    return TCL_ERROR;
	  }

	  if (new_value>65535 || new_value < 0) {
	    Tcl_AppendResult (interp, "Invalid value. should be between 0 and 65535" , (char *) NULL);
	    return TCL_ERROR;
	  }
	}


	if(ioctl(capItem->fvideo, VIDIOCGPICT, &vp)<0){
		perror("VIDIOCGPICT");
		return TCL_ERROR;
	}

	Tcl_ResetResult(interp);

	switch (setting) {
	case SETTINGS_SET_BRIGHTNESS :
	  vp.brightness = new_value;
	  break;
	case SETTINGS_SET_HUE:
	  vp.hue = new_value;
	  break;
	case SETTINGS_SET_COLOUR:
	  vp.colour = new_value;
	  break;
	case SETTINGS_SET_CONTRAST:
	  vp.contrast = new_value;
	  break;
	case SETTINGS_GET_BRIGHTNESS:
	  Tcl_SetObjResult(interp, Tcl_NewIntObj(vp.brightness));
	  break;
	case SETTINGS_GET_HUE:
	  Tcl_SetObjResult(interp, Tcl_NewIntObj(vp.hue));
	  break;
	case SETTINGS_GET_COLOUR:
	  Tcl_SetObjResult(interp, Tcl_NewIntObj(vp.colour));
	  break;
	case SETTINGS_GET_CONTRAST:
	  Tcl_SetObjResult(interp, Tcl_NewIntObj(vp.contrast));
	  break;
	default:
	  break;
	}

	if ( setting & SETTINGS_SET) {
	  vp.depth = 24;
	  vp.palette = VIDEO_PALETTE_RGB24;
	  if (ioctl(capItem->fvideo, VIDIOCSPICT, &vp)) {
	    perror("VIDIOCSPICT");
	    return TCL_ERROR;
	  }
	}

	return TCL_OK;
}


int Capture_IsValid _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	char *                  captureDescriptor=NULL;

	if( objc != 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::IsValid capturedescriptor\"" , (char *) NULL);
		return TCL_ERROR;
	}

	captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);

	Tcl_SetObjResult(interp, Tcl_NewBooleanObj( lstGetItem(captureDescriptor) != NULL ) );

	return TCL_OK;

}

int Capture_Init (Tcl_Interp *interp ) {

	//Check Tcl version is 8.3 or higher
	if (Tcl_InitStubs(interp, "8.3", 0) == NULL) {
		return TCL_ERROR;
	}

	//Check TK version is 8.3 or higher
	if (Tk_InitStubs(interp, "8.3", 0) == NULL) {
		return TCL_ERROR;
	}

	Tcl_CreateObjCommand(interp, "::Capture::ListDevices", Capture_ListDevices,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::ListChannels", Capture_ListChannels,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::Open", Capture_Open,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::GetGrabber", Capture_GetGrabber,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::Close", Capture_Close,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::Grab", Capture_Grab,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp, "::Capture::SetBrightness", Capture_AccessSettings,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::SetContrast", Capture_AccessSettings,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::SetHue", Capture_AccessSettings,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::SetColour", Capture_AccessSettings,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp, "::Capture::GetBrightness", Capture_AccessSettings,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::GetContrast", Capture_AccessSettings,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::GetHue", Capture_AccessSettings,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::GetColour", Capture_AccessSettings,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	Tcl_CreateObjCommand(interp, "::Capture::IsValid", Capture_IsValid,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// end of Initialisation
	return TCL_OK;
}

int Capture_SafeInit (Tcl_Interp *interp ) {
	return Capture_Init(interp);
}
