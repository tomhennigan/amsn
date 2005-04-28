#include "capture.h"

static int fvideo;
static struct video_mbuf       mb;
static char *mmbuf;
static struct video_window     vw;
static int bright, cont, hue, colour;

int Capture_Initialize _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{

  char * dev = NULL;


  struct video_capability vcap;
  struct video_channel    vc;
  struct video_picture    vp;
  int i;

  bright = 42767;
  cont = 22767;
  hue = 32767;
  colour = 44767;


  if( objc != 2) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::Init device\"" , (char *) NULL);
    return TCL_ERROR;
  }

  dev = Tcl_GetStringFromObj(objv[1], NULL);

  if ((fvideo = open(dev, O_RDONLY)) < 0) {
    perror("open");
    return TCL_ERROR;
  }

  if (ioctl(fvideo, VIDIOCGCAP, &vcap) < 0) {
    perror("VIDIOCGCAP");
    exit(1);
  }


    /*fprintf(stderr,"Video Capture Device Name : %s\n",vcap.name);
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
    if (vcap.type & VID_TYPE_SUBCAPTURE) fprintf(stderr, "Can subcapture\n");*/

    for(i=0; i<vcap.channels; i++) {
      vc.channel = i;
      if (ioctl(fvideo, VIDIOCGCHAN, &vc) < 0){
	perror("VIDIOCGCHAN");
	exit(1);
      }
      /*fprintf(stderr,"Video Source (%d) Name : %s\n",i, vc.name);
      fprintf(stderr, "channel %d: %s ", vc.channel, vc.name);
      fprintf(stderr, "%d tuners, has ", vc.tuners);
      if (vc.flags & VIDEO_VC_TUNER) fprintf(stderr, "tuner(s) ");
      if (vc.flags & VIDEO_VC_AUDIO) fprintf(stderr, "audio ");
      //      if (vc.flags & VIDEO_VC_NORM) fprintf(stderr, "norm ");
      fprintf(stderr, "\ntype: ");
      if (vc.type & VIDEO_TYPE_TV) fprintf(stderr, "TV ");
      if (vc.type & VIDEO_TYPE_CAMERA) fprintf(stderr, "CAMERA ");
      fprintf(stderr, "norm: %d\n", vc.norm);*/
    }
    if(ioctl(fvideo, VIDIOCGPICT, &vp)<0){
      perror("VIDIOCGPICT");
      exit;
    }
    /*fprintf(stderr, "picture: brightness %d hue %d colour %d\n",
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
    fprintf(stderr, "\n");*/


  vc.channel = 0;
  vc.type = VIDEO_TYPE_CAMERA;
  vc.norm = 0;
  if(ioctl(fvideo, VIDIOCSCHAN, &vc) < 0){
    perror("VIDIOCSCHAN");
    return TCL_ERROR;
  }

  if(ioctl(fvideo, VIDIOCGWIN, &vw)<0){
    perror("VIDIOCGWIN");
    return TCL_ERROR;
  }

  //fprintf(stderr, "window: x %d y %d w %d h %d\n",vw.x,vw.y,vw.width,vw.height);
  //fprintf(stderr, "window: flags %d chromakey %d\n",vw.flags,vw.chromakey);

  /* set default picture parameters */
  vp.depth = 24;

  vp.brightness = bright;
  vp.contrast = cont;
  vp.hue = hue;
  vp.colour = colour;

  vp.palette = VIDEO_PALETTE_RGB24;
  if (ioctl(fvideo, VIDIOCSPICT, &vp)) {
    perror("set picture");
    return TCL_ERROR;
  }

  if (ioctl(fvideo, VIDIOCGMBUF, &mb)) {
    perror("get mbuf");
    return TCL_ERROR;
  }

  mmbuf = (unsigned char*)mmap(0, mb.size,
			     PROT_READ, MAP_SHARED, fvideo, 0);
  if((int)mmbuf < 0){
    perror("mmap");
    return TCL_ERROR;
  }

  return TCL_OK;
}

int Capture_DeInitialize _ANSI_ARGS_((ClientData clientData))
{
  munmap(mmbuf,mb.size);
  mmbuf=(char *) -1;
  close(fvideo);
  fvideo=0;
  return TCL_OK;
}

int Capture_Grab _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  char * image_name = NULL;
  Tk_PhotoHandle Photo;

  struct video_mmap       mm;
  int i, j, x;
  int zero = 0, one = 1;
  BYTE * image_data = NULL;
  mm.frame  = 0;
  mm.height = vw.height; //240;
  mm.width  = vw.width; //320;
  mm.format = VIDEO_PALETTE_RGB24;

  if( objc != 2) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::Grab image_name\"" , (char *) NULL);
    return TCL_ERROR;
  }

  image_name = Tcl_GetStringFromObj(objv[1], NULL);

  if ( (Photo = Tk_FindPhoto(interp, image_name)) == NULL) {
    Tcl_AppendResult(interp, "The image you specified is not a valid photo image", NULL);
    return TCL_ERROR;
  }


  if(ioctl(fvideo, VIDIOCMCAPTURE, &mm)<0){
    perror("VIDIOCMCAPTURE");
    return TCL_ERROR;
  }

  if(ioctl(fvideo, VIDIOCSYNC, &mm.frame)<0){
    perror("VIDIOCSYNC");
    return TCL_ERROR;
  }

  image_data = (BYTE *) malloc(mm.width*mm.height*3);

  //fprintf(stderr, "save %d bytes @ %p -> %p\n", msize, mmbuf, image_data);
  if((int) mmbuf<0){
  	Tcl_AppendResult(interp, "You don't call Init", NULL);
  	return TCL_ERROR;
  }
  memcpy(image_data, mmbuf+mb.offsets[0], mm.width*mm.height*3);


  Tk_PhotoBlank(Photo);

#if TK_MINOR_VERSION == 3
  Tk_PhotoSetSize(Photo, mm.width, mm.height);
#endif
#if TK_MINOR_VERSION == 4
  Tk_PhotoSetSize(Photo, mm.width, mm.height);
#endif
#if TK_MINOR_VERSION == 5
  Tk_PhotoSetSize(interp, Photo, mm.width, mm.height);
#endif


  Tk_PhotoImageBlock block = {
    image_data,		// pixel ptr
    mm.width,
    mm.height,
    mm.width*3,	// pitch : number of bytes separating 2 adjacent pixels vertically
    3,			// pixel size : size in bytes of one pixel .. 4 = RGBA
  };

  block.offset[0] = 2;
  block.offset[1] = 1;
  block.offset[2] = 0;

#if TK_MINOR_VERSION == 3
  Tk_PhotoPutBlock(Photo, &block, 0, 0, mm.width, mm.height);
#endif
#if TK_MINOR_VERSION == 4
  Tk_PhotoPutBlock(Photo, &block, 0, 0, mm.width, mm.height, TK_PHOTO_COMPOSITE_OVERLAY);
#endif
#if TK_MINOR_VERSION == 5
  Tk_PhotoPutBlock(interp, Photo, &block, 0, 0, mm.width, mm.height, TK_PHOTO_COMPOSITE_OVERLAY);
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

int Capture_SBrightness _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  struct video_picture    vp;
  int brightness=0;

  if( objc != 2) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::SetBrightness bright\"" , (char *) NULL);
    return TCL_ERROR;
  }
  if(Tcl_GetIntFromObj(interp, objv[1], &brightness)==TCL_ERROR) return TCL_ERROR;
  if (brightness>65535) return TCL_ERROR;
  bright=brightness;

  vp.depth = 24;

  vp.brightness = bright;
  vp.contrast = cont;
  vp.hue = hue;
  vp.colour = colour;

  vp.palette = VIDEO_PALETTE_RGB24;
  if (ioctl(fvideo, VIDIOCSPICT, &vp)) {
    perror("set picture");
    return TCL_ERROR;
  }

  return TCL_OK;

}

int Capture_SContrast _ANSI_ARGS_((ClientData clientData,
			      Tcl_Interp *interp,
			      int objc,
			      Tcl_Obj *CONST objv[]))
{
  struct video_picture    vp;
  int contrast=0;

  if( objc != 2) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Capture::SetContrast contrast\"" , (char *) NULL);
    return TCL_ERROR;
  }
  if(Tcl_GetIntFromObj(interp, objv[1], &contrast)==TCL_ERROR) return TCL_ERROR;
  if (contrast>65535) return TCL_ERROR;
  cont=contrast;

  vp.depth = 24;

  vp.brightness = bright;
  vp.contrast = cont;
  vp.hue = hue;
  vp.colour = colour;

  vp.palette = VIDEO_PALETTE_RGB24;
  if (ioctl(fvideo, VIDIOCSPICT, &vp)) {
    perror("set picture");
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



  Tcl_CreateObjCommand(interp, "::Capture::Init", Capture_Initialize,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)Capture_DeInitialize);
  Tcl_CreateObjCommand(interp, "::Capture::Grab", Capture_Grab,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Capture::SetBrightness", Capture_SBrightness,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Capture::SetContrast", Capture_SContrast,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);


  // end of Initialisation
  return TCL_OK;
}

int Capture_SafeInit (Tcl_Interp *interp ) {

  return Capture_Init(interp);
}
