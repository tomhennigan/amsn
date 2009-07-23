#ifndef __TCLCARBONHICOMMAND_H_INCLUDE
#define __TCLCARBONHICOMMAND_H_INCLUDE


#ifdef __APPLE__
#define Cursor       QD_Cursor
#define WindowPtr    QD_WindowPtr
#define Picture      QD_Picture
#define BOOL         OSX_BOOL
#define EventType    HIT_EventType
#endif

#include <Carbon/Carbon.h>

#ifdef __APPLE__
#undef Cursor
#undef WindowPtr
#undef Picture
#undef BOOL
#undef EventType
#endif

#include "tk.h"
#include "tcl.h"

#include "tclCarbon.h"

typedef struct TkWindowPrivate {
	Tk_Window *winPtr;
	CGrafPtr  grafPtr;
} TkWindowPrivate;

int processHICommand(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);
int enableMenuCommand(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);
static char * TclCarbonHICommandErr(OSErr err);

#endif
