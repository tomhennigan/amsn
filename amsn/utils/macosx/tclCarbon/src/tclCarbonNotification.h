#ifndef __TCLCARBONNOTIFICATION_H_INCLUDE
#define __TCLCARBONNOTIFICATION_H_INCLUDE

#include <Carbon/Carbon.h>
#include "tk.h"
#include "tcl.h"

#include "tclCarbon.h"

static int notificationAdded = 0;
static NMRec request;

int endNotification(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);
int notification(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);
static char * TclCarbonNotificationErr(OSErr err);

#endif