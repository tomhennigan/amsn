/* statusicon.h:
 *
 * Copyright (C) 2010 Youness Alaoui
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */


#ifndef _STATUS_ICON
#define _STATUS_ICON

#include <tcl.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#ifdef __cplusplus
extern "C"
#endif

#include "statusicon-quartz.h"

// External functions
EXTERN int Statusicon_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Statusicon_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));

EXTERN int Statusicon_Create _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_SetImage _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_SetAlternateImage _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_SetVisible _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_SetTooltip _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_SetTitle _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_SetHighlightMode _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));
EXTERN int Statusicon_Destroy _ANSI_ARGS_((ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));

void Statusicon_Callback(QuartzStatusIcon *status_item, void *user_data, int doubleAction);

#endif /* _STATUS_ICON */
