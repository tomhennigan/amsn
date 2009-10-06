#ifndef _STATUS_ICON
#define _STATUS_ICON

#include <tcl.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#ifdef __cplusplus
extern "C"
#endif

// External functions
EXTERN int Statusicon_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Statusicon_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));

EXTERN int Statusicon_Create _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_SetImage _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_SetVisible _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_SetTooltip _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_Destroy _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));

void * Statusicon_Callback();

#endif /* _STATUS_ICON */
