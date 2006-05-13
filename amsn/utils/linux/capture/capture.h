/*
		File : capture.h

		Description : Header file for the capture extension for tk. 

		Author : Youness El Alaoui ( KaKaRoTo - kakaroto@user.sourceforge.net)

 */

#ifndef _CAPTURE
#define _CAPTURE

// Include files, must include windows.h before tk.h and tcl.h before tk.h or else compiling errors
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/time.h>

#include <tcl.h>
#include <tk.h>

#include <tkPlatDecls.h>

#include <linux/videodev.h>

#include "grab-ng.h"

// Defined as described in tcl.tk compiling extension help
#ifndef STATIC_BUILD

#if defined(_MSC_VER)
#   define EXPORT(a,b) __declspec(dllexport) a b
#   define DllEntryPoint DllMain
#else
#   if defined(__BORLANDC__)
#       define EXPORT(a,b) a _export b
#   else
#       define EXPORT(a,b) a b
#   endif
#endif
#endif


#define DLL_BUILD
#define BUILD_CAPTURE

#ifdef BUILD_CAPTURE
#  undef TCL_STORAGE_CLASS
#  define TCL_STORAGE_CLASS DLLEXPORT
#endif

#ifdef __cplusplus
extern "C"
#endif

#define HIGH_RES_W 320
#define HIGH_RES_H 240
#define LOW_RES_W 160
#define LOW_RES_H 120

// Structures for the list
struct capture_item {
  char captureName[32];
  char devicePath[32];
  int channel;
  struct ng_devstate          dev;
  struct ng_video_fmt         fmt;
  struct ng_video_conv        *conv;
  struct ng_process_handle    *handle;
  struct ng_video_buf *image_data;
  struct ng_video_buf *rgb_buffer;
};

// Defines for compatibility with the list code..
#define g_list opened_devices
#define data_item capture_item
#define list_element_id captureName

// Capture extension's Tcl command implementations
EXTERN int Capture_ListDevices _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
EXTERN int Capture_ListChannels _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));

EXTERN int Capture_GetGrabber _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
EXTERN int Capture_ListGrabbers _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
EXTERN int Capture_Grab _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));

EXTERN int Capture_Open _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
EXTERN int Capture_Close _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
EXTERN int Capture_IsValid _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));

EXTERN int Capture_SetAttribute _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
EXTERN int Capture_GetAttribute _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));

EXTERN int Capture_Debug _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));

// Capture extension initialisation functions
EXTERN int Capture_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Capture_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));

# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT
#endif /* _CAPTURE */
