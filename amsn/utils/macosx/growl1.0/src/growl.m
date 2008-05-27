/*
 * growl.m
 *
 * Copyright (c) 2004-2005, Toby Peterson <toby@opendarwin.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the Growl project nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <tcl.h>

#include <Cocoa/Cocoa.h>

#include "GrowlDefines.h"
#include "GrowlApplicationBridge.h"

#include "TclGrowler.h"

static TclGrowler *tg = nil;

NSArray *
Tcl_ListToNSArray(Tcl_Interp * interp, Tcl_Obj * listObj)
{
	NSMutableArray * mut = [[NSMutableArray alloc] init];
	Tcl_Obj ** listPtr;		int listLen;

	if (Tcl_ListObjGetElements(interp, listObj, &listLen, &listPtr) != TCL_OK) { return nil; }
	
	int i;
	for (i=0; i<listLen; i++) {
		[mut addObject:[NSString stringWithUTF8String:Tcl_GetString(listPtr[i])]];
	}
	
	NSArray * ret = [[NSArray alloc] initWithArray:mut];
	[mut release];
	
	return ret;
}

int
growl_register(Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	NSString *appName = nil;
	NSArray *allNotifications = nil;
	NSString *iconFile = nil;
	NSImage *notificationIcon = nil;

	if (tg != nil) {
		Tcl_AppendResult(interp, "application has already been registered...", NULL);
		return TCL_ERROR;
	}
	
	if (objc != 3) {
		Tcl_WrongNumArgs(interp, 0, objv, "growl register appname notifications ?icon?");
		return TCL_ERROR;
	}

	appName = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
	++objv, --objc;

	allNotifications = (NSArray *)Tcl_ListToNSArray(interp, *objv);
	++objv, --objc;

	iconFile = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
	notificationIcon = [[NSImage alloc] initWithContentsOfFile:iconFile];
	++objv, --objc;

	tg = [[TclGrowler alloc] initWithName:appName notifications:allNotifications icon:notificationIcon];

	[notificationIcon release];

	return TCL_OK;
}

int
growl_post(Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	NSString *notificationName = nil;
	NSString *notificationTitle = nil;
	NSString *notificationDescription = nil;
	NSString *iconFile = nil;
	NSImage *notificationIcon = nil;

	if (objc != 3 && objc != 4) {
		Tcl_WrongNumArgs(interp, 0, objv, "growl post notification title description ?icon?");
		return TCL_ERROR;
	}

	notificationName = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
	++objv, --objc;

	notificationTitle = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
	++objv, --objc;

	notificationDescription = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
	++objv, --objc;

	if (objc != 0) {
		iconFile = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
		notificationIcon = [[NSImage alloc] initWithContentsOfFile:iconFile];
		++objv, --objc;
	}

	[GrowlApplicationBridge notifyWithTitle:notificationTitle
		description:notificationDescription
		notificationName:notificationName
		iconData:(notificationIcon ? [notificationIcon TIFFRepresentation] : [tg applicationIconDataForGrowl])
		priority:0
		isSticky:NO
		clickContext:nil];

	[notificationIcon release];

	return TCL_OK;
}

/*
 * GrowlCmd
 * Handles the Tcl 'growl' command.
 */
int
GrowlCmd(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSString *action = nil;
	int e;

	++objv, --objc;

	if (objc != 0) {
		action = [NSString stringWithUTF8String:Tcl_GetString(*objv)];
		++objv, --objc;

		if ([action isEqualToString:@"register"]) {
			e = growl_register(interp, objc, objv);
		} else if ([action isEqualToString:@"post"]) {
			e = growl_post(interp, objc, objv);
		} else {
			e = TCL_ERROR;
			Tcl_AppendResult(interp, "wrong args, should be growl post/register ?args?", NULL);
		}
	} else {
		e = TCL_ERROR;
		Tcl_WrongNumArgs(interp, 0, objv, "growl register/post ?args?");
	}

	[pool release];
	return e;
}

/* Growl_Init
 * Initialize the Tcl package, registering the 'growl' command.
 */
int
Growl_Init(Tcl_Interp *interp)
{
	if (Tcl_InitStubs(interp, "8.4", 0) == NULL) {
		return TCL_ERROR;
	}

	Tcl_CreateObjCommand(interp, "growl", GrowlCmd, NULL, NULL);

	if (Tcl_PkgProvide(interp, "growl", "1.0") != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}

int
Growl_SafeInit(Tcl_Interp *interp)
{
	return Growl_Init(interp);
}
