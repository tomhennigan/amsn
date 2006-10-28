/**
 *
 * C code based on Critl original with below copyright.
 *
# #######################################################################
#
#  tclCarbonHICommand.tcl
#
#  Critcl wrapper for Mac OS X HICommand Carbon Event Manager services.
#
#  Process this file with 'critcl -pkg' to build a loadable package (or
#  simply source this file if [package require critcl] and a compiler
#  are available at deployment).
#
#
#  Author: Daniel A. Steffen
#  E-mail: <steffen@maths.mq.edu.au>
#    mail: Mathematics Departement
#          Macquarie University NSW 2109 Australia
#     www: <http://www.maths.mq.edu.au/~steffen/>
#
# RCS: @(#) $Id: 13463,v 1.5 2005/02/01 07:01:36 jcw Exp $
#
# BSD License: c.f. <http://www.opensource.org/licenses/bsd-license>
#
# Copyright (c) 2005, Daniel A. Steffen <das@users.sourceforge.net>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
#   * Redistributions of source code must retain the above
#     copyright notice, this list of conditions and the
#     following disclaimer.
#
#   * Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials
#     provided with the distribution.
#
#   * Neither the name of Macquarie University nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL MACQUARIE
# UNIVERSITY OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
#
# #######################################################################
# \
 */

#include <Carbon/Carbon.h>
#include "tk.h"
#include "tcl.h"
#define Cursor _Cursor

typedef struct TkWindowPrivate {
	Tk_Window *winPtr;
	CGrafPtr  grafPtr;
} TkWindowPrivate;

static char *OSErrDesc(OSErr err) {
	static char desc[255];
	if (err == eventNotHandledErr) {
		sprintf(desc, "Carbon Event not handled.\n", err);
	} else {
		sprintf(desc, "OS Error: %d.\n", err);
	}
	return desc;
}

/*
#---------------------------------------------------------------------------------------------------
#
# carbon::processHICommand commandID toplevel
#
#   this command takes a Carbon HICommand ID (4 char string, c.f. CarbonEvents.h), and either the
#   name of a toplevel window (for window specific HICommands) or an empty string (for menu specific
#   HICommands) and calls ProcessHICommand() with the resulting HICommandExtended structure.
#
*/

int processHICommand(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
        if(objc != 3) {
                Tcl_AppendResult (interp, "Must be carbon::processHICommand commandID toplevel", NULL);
                return TCL_ERROR;
        }

        char *commandID = Tcl_GetStringFromObj(objv[1], NULL);
        char *toplevel = Tcl_GetStringFromObj(objv[2], NULL);

	OSErr err;
	HICommandExtended command;
	EventRef event;

	bzero(&command, sizeof(HICommandExtended));
	if (strlen(commandID) != sizeof(UInt32)) {
		Tcl_AppendResult(interp, "Argument commandID needs to be exactly 4 chars long", NULL);
		return TCL_ERROR;
	}
	memcpy(&(command.commandID), commandID, sizeof(UInt32));
#ifdef __LITTLE_ENDIAN__
	command.commandID = CFSwapInt32HostToBig(command.commandID);
#endif
	if (strlen(toplevel)) {
		Tk_Window tkwin = Tk_NameToWindow(interp,toplevel,Tk_MainWindow(interp));
		if(!tkwin) return TCL_ERROR;
		if(!Tk_IsTopLevel(tkwin)) {
			Tcl_AppendResult(interp, "Window \"", toplevel,
					"\" is not a toplevel window", NULL);
			return TCL_ERROR;
		 }
		 command.source.window = GetWindowFromPort(
		 		((TkWindowPrivate*)Tk_WindowId(tkwin))->grafPtr);
		 command.attributes = kHICommandFromWindow;
	} else {
		err = GetIndMenuItemWithCommandID(NULL, command.commandID, 1,
				&command.source.menu.menuRef, &command.source.menu.menuItemIndex);
		if (err != noErr) {
			Tcl_AppendResult(interp, "Could not find menu item corresponding to commandID: ",
					OSErrDesc(err), NULL);
		} else {
			command.attributes = kHICommandFromMenu;
		}
	}
	err = ProcessHICommand((HICommand*)&command);
	if (err != noErr) {
		Tcl_AppendResult(interp, "Could not process command: ", OSErrDesc(err), NULL);
		return TCL_ERROR;
	}
	return TCL_OK;
}

/*
#---------------------------------------------------------------------------------------------------
#
# carbon::enableMenuCommand commandID disable
#
#   this command takes a Carbon HICommand ID (4 char string, c.f. CarbonEvents.h) of a menu specific
#   HICommand, and a flag specifing whether to enable (0) or disable (1) the associated menu item.
#
#---------------------------------------------------------------------------------------------------
*/

int enableMenuCommand(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
        if(objc != 3) {
                Tcl_AppendResult (interp, "Must be carbon::enableMenuCommand commandID disable", NULL);
                return TCL_ERROR;
        }

	char *commandID = Tcl_GetStringFromObj(objv[1], NULL);
        int disable;

	MenuCommand command;

	if (strlen(commandID) != sizeof(UInt32)) {
		Tcl_AppendResult(interp, "Argument commandID needs to be exactly 4 chars long", NULL);
		return TCL_ERROR;
	}
	memcpy(&command, CFSwapInt32HostToBig(commandID), sizeof(UInt32));
#ifdef __LITTLE_ENDIAN__
	command = CFSwapInt32HostToBig(command);
#endif
	if (disable) {
		DisableMenuCommand(NULL, command);
	} else {
		EnableMenuCommand(NULL, command);
	}
	return TCL_OK;
}

/*
 * Tcl/Tk Magic
 */
int Tclcarbonhicommand_Init(Tcl_Interp *interp ) {
  if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
    return TCL_ERROR;
  }
  if (Tk_InitStubs(interp, TK_VERSION, 0) == NULL) {
    return TCL_ERROR;
  }
  Tcl_CreateObjCommand(interp, "carbon::processHICommand", processHICommand, NULL, NULL);
  Tcl_CreateObjCommand(interp, "carbon::enableMenuCommand", enableMenuCommand, NULL, NULL);
  return Tcl_PkgProvide(interp, "tclCarbonHICommand", "0.1");
}

int Tclcarbonhicommand_SafeInit(Tcl_Interp *interp) {
  return Tclcarbonhicommand_Init(interp);
}
