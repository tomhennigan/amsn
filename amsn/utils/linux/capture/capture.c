#include "capture.h"

struct capture_item {
	char captureName[32];
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

struct capture_listitem* lstCreateItem(){ // Create an item in the list and put it at the begin
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
	return newItem;
}

struct capture_listitem* lstGetItem(char *captureName){ //Get the item with the specified name
	struct capture_listitem* item=openeddevices;
	while(item!=NULL){
		if(strcmp(item->data.captureName,captureName)==0){
			break;
		}
		item=item->next_item;
	}
	return item;
}

void lstDeleteItem(struct capture_listitem* item){
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
	while((fd = open(filename, O_RDONLY)) != -1) {
		device_idx ++;
//		fprintf(stderr,"%s : %d\n",filename,fd);

		if (ioctl(fd, VIDIOCGCAP, &vcap) < 0) {
			perror("VIDIOCGCAP");
			return TCL_ERROR;
		}

		device[0]=Tcl_NewStringObj(filename,-1);
		device[1]=Tcl_NewStringObj(vcap.name,-1);
		lstDevice=Tcl_NewListObj(2,&device[0]);
		Tcl_ListObjAppendElement(interp,lstAll,lstDevice);

		close(fd);
		sprintf(filename, "/dev/video%d", device_idx);

	}
	Tcl_SetObjResult(interp,lstAll);
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
	struct capture_listitem* captureItem=NULL;

	struct video_capability vcap;
	struct video_channel    vc;
	struct video_picture    vp;
	struct video_window     vw;

	BYTE testbuffer=0;
	char *mmbuf; //To uncomment if we use mmap : not for now
	struct video_mbuf       mb;

	int i;
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

	for(i=0; i<vcap.channels; i++) {
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
	}

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

	vp.brightness = bright;
	vp.contrast = cont;
	vp.hue = hue;
	vp.colour = colour;

	vp.palette = VIDEO_PALETTE_RGB24;

	if (ioctl(fvideo, VIDIOCSPICT, &vp)) {
		perror("set picture");
		close(fvideo);
		return TCL_ERROR;
	}


	if (read(fvideo,&testbuffer,1)==-1){ //Try the mmap way if read fails
		mmapway=1;
		perror("read failed -> switching to mmap way\nerrno");
		if (ioctl(fvideo, VIDIOCGMBUF, &mb)) {
			perror("VIDIOCGMBUF");
			close(fvideo);
			return TCL_ERROR;
		}

		mmbuf = (unsigned char*)mmap(0, mb.size,
				PROT_READ, MAP_SHARED, fvideo, 0);
		if((int)mmbuf < 0){
			perror("mmap");
			return TCL_ERROR;
		}
	}

	if((captureItem=lstCreateItem())==NULL){
		perror("lstCreateItem");
		close(fvideo);
		return TCL_ERROR;
	}

	sprintf(captureItem->data.captureName,"capture%d",curentCaptureNumber);
	curentCaptureNumber++;
	captureItem->data.fvideo=fvideo;
	memcpy(&captureItem->data.vw,&vw,sizeof(captureItem->data.vw));

	if(mmapway){
		memcpy(&captureItem->data.mb,&mb,sizeof(captureItem->data.mb));
		captureItem->data.mmbuf=mmbuf;
	}

	Tcl_SetObjResult(interp, Tcl_NewStringObj(captureItem->data.captureName,-1));

	return TCL_OK;
}

int Capture_Close _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	char *captureDescriptor=NULL;
	struct capture_listitem *capItem=NULL;
	if( objc != 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::Close capturedescriptor\"" , (char *) NULL);
		return TCL_ERROR;
	}

	captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
	if((capItem=lstGetItem(captureDescriptor))==NULL) {
		Tcl_AppendResult (interp, "Invalid capture descriptor. Please call Open before." , (char *) NULL);
		return TCL_ERROR;
	}

	if(capItem->data.mmbuf){
		munmap(capItem->data.mmbuf,capItem->data.mb.size);
	}

	close(capItem->data.fvideo);
	lstDeleteItem(capItem);
	return TCL_OK;
}

int Capture_Grab _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	struct capture_listitem*    capItem=NULL;
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

	/*if(ioctl(capItem->data.fvideo, VIDIOCGWIN, &vw)<0){
		perror("VIDIOCGWIN");
		return TCL_ERROR;
	}*/

	memcpy(&vw,&capItem->data.vw,sizeof(vw));

	if (capItem->data.mmbuf){
		mm.frame  = 0;
		mm.height = vw.height;
		mm.width  = vw.width;
		mm.format = VIDEO_PALETTE_RGB24;

		if(ioctl(capItem->data.fvideo, VIDIOCMCAPTURE, &mm)<0){
			perror("VIDIOCMCAPTURE");
			return TCL_ERROR;
		}

		if(ioctl(capItem->data.fvideo, VIDIOCSYNC, &mm.frame)<0){
			perror("VIDIOCSYNC");
			return TCL_ERROR;
		}
	}

	image_data = (BYTE *) malloc(vw.width*vw.height*3);

	if (capItem->data.mmbuf){
		memcpy(image_data, capItem->data.mmbuf+capItem->data.mb.offsets[0], mm.width*mm.height*3);
	}
	else {
		read(capItem->data.fvideo,image_data,vw.width*vw.height*3);
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

int Capture_SetBrightness _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	char *                  captureDescriptor=NULL;
	struct capture_listitem*    capItem=NULL;
	int                     brightness=0;
	struct video_picture    vp;

	if( objc != 3) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::SetBrightness capturedescriptor bright\"" , (char *) NULL);
		return TCL_ERROR;
	}

	if(Tcl_GetIntFromObj(interp, objv[2], &brightness)==TCL_ERROR){
		return TCL_ERROR;
	}
	if (brightness>65535) {
		Tcl_AppendResult (interp, "Invalid brightness. brightness < 655535" , (char *) NULL);
		return TCL_ERROR;
	}

	captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);
	if((capItem=lstGetItem(captureDescriptor))==NULL){
		Tcl_AppendResult (interp, "Invalid capture descriptor. Please call Open before." , (char *) NULL);
		return TCL_ERROR;
	}

	if(ioctl(capItem->data.fvideo, VIDIOCGPICT, &vp)<0){
		perror("VIDIOCGPICT");
		return TCL_ERROR;
	}

	vp.brightness = brightness;

	if (ioctl(capItem->data.fvideo, VIDIOCSPICT, &vp)) {
		perror("VIDIOCSPICT");
		return TCL_ERROR;
	}

	return TCL_OK;
}

int Capture_SetContrast _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
	char *                  captureDescriptor=NULL;
	struct capture_listitem*    capItem=NULL;
	int                     contrast=0;
	struct video_picture    vp;

	if( objc != 3) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::SetBrightness capturedescriptor bright\"" , (char *) NULL);
		return TCL_ERROR;
	}

	if(Tcl_GetIntFromObj(interp, objv[2], &contrast)==TCL_ERROR){
		return TCL_ERROR;
	}

	if (contrast>65535) {
		Tcl_AppendResult (interp, "Invalid contrast. contrast < 655535" , (char *) NULL);
		return TCL_ERROR;
	}

	captureDescriptor = Tcl_GetStringFromObj(objv[1], NULL);

	if((capItem=lstGetItem(captureDescriptor))==NULL){
		Tcl_AppendResult (interp, "Invalid capture descriptor. Please call Open before." , (char *) NULL);
		return TCL_ERROR;
	}

	if(ioctl(capItem->data.fvideo, VIDIOCGPICT, &vp)<0){
		perror("VIDIOCGPICT");
		return TCL_ERROR;
	}

	vp.contrast = contrast;

	if (ioctl(capItem->data.fvideo, VIDIOCSPICT, &vp)) {
		perror("VIDIOCSPICT");
		return TCL_ERROR;
	}

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
	Tcl_CreateObjCommand(interp, "::Capture::Open", Capture_Open,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::Close", Capture_Close,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::Grab", Capture_Grab,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::SetBrightness", Capture_SetBrightness,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, "::Capture::SetContrast", Capture_SetContrast,
			(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// end of Initialisation
	return TCL_OK;
}

int Capture_SafeInit (Tcl_Interp *interp ) {
	return Capture_Init(interp);
}
