#ifndef __TCLCARBONHICOMMAND_H_INCLUDE
#define __TCLCARBONHICOMMAND_H_INCLUDE

#include <Carbon/Carbon.h>
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