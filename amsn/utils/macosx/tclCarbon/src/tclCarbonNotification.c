/**
 *
 * C code based on Critl original with below copyright.
 *
#!/bin/sh
# #######################################################################
#
#  tclCarbonNotification.tcl
#
#  Critcl wrapper for Mac OS X Notification Manager services.
#
#  Process this file with 'critcl -pkg' to build a loadable package (or
#  simply source this file if [package require critcl] and a compiler
#  are available at deployment).
#
#
#  Author: Daniel A. Steffen
#  E-mail: <steffen@maths.mq.edu.au>
#    mail: Mathematics Departement
#	   Macquarie University NSW 2109 Australia
#     www: <http://www.maths.mq.edu.au/~steffen/>
#
# RCS: @(#) $Id: 13462,v 1.5 2005/02/01 07:01:31 jcw Exp $
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

#include "tclCarbonNotification.h"

/*
 * Start a notification!
 */
int notification(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
        if(objc != 3) {
                Tcl_AppendResult (interp, "Must be carbon::notification message bounce", NULL);
                return TCL_ERROR;
        }

	char *msg = Tcl_GetStringFromObj(objv[1], NULL);
	int bounce;

	if (Tcl_GetIntFromObj(interp, objv[2], &bounce) == TCL_ERROR) {
		return TCL_ERROR;
	}

	OSErr err;
	Str255 message;

	if(notificationAdded) {
		err = NMRemove(&request);
                if (err != noErr) {
                        Tcl_AppendResult(interp, "Could not remove notification: ",
                                        TclCarbonNotificationErr(err), NULL);
                        return TCL_ERROR;
                }
		notificationAdded = 0;
	}
        if(strlen(msg)) {
               CopyCStringToPascal(msg,message);
               request.nmStr = (StringPtr)&message;
        } else {
               request.nmStr = NULL;
        }
        request.nmMark = bounce;
        request.qType = nmType;
        request.nmSound = NULL;
        request.nmResp = NULL;
        err = NMInstall(&request);
        if (err != noErr) {
                Tcl_AppendResult(interp, "Could not install notification: ", TclCarbonNotificationErr(err), NULL);
                return TCL_ERROR;
        }
        notificationAdded = 1;
	return TCL_OK;
}

/*
 * End the notification!
 */
int endNotification(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]) {
        if(objc != 1) {
                Tcl_AppendResult (interp, "No options to carbon::endNotification permitted", NULL);
                return TCL_ERROR;
        }

	OSErr err;
	if(notificationAdded) {
		err = NMRemove(&request);
                if (err != noErr) {
                        Tcl_AppendResult(interp, "Could not remove notification: ", TclCarbonNotificationErr(err), NULL);
                        return TCL_ERROR;
                }
		notificationAdded = 0;
	}
	return TCL_OK;
}

/*
 * Helper routine for errors.
 */
static char * TclCarbonNotificationErr(OSErr err)
{
	static char desc[255];
	sprintf(desc, "OS Error: %d.\n", err);
	return desc;
}
