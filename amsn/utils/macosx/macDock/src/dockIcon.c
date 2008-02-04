/*
This file is part of "aMSN".

"aMSN" is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

"aMSN" is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with "aMSN"; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA 
*/

#include "dockIcon.h"

// Tcl command to set the dock icon.
int setIcon(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	if(objc != 2) {
		Tcl_WrongNumArgs(interp, 1, objv, "pathToPNG");
		return TCL_ERROR;
	}
	
	UInt8 * path = Tcl_GetStringFromObj(objv[1], NULL);
	
	CGImageRef img = getImageRefFromPath(path);
	
	if(img == NULL) {
		Tcl_AppendResult (interp, "couldn't create CGImageRef from path.", (char *) NULL);
		return TCL_ERROR;
	}
	
	SetApplicationDockTileImage(img);
	
	CGImageRelease(img);
	
	return TCL_OK;
}

// Tcl command to set the dock icon.
int overlayIcon(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	if(objc != 2) {
		Tcl_WrongNumArgs(interp, objc, objv, "pathToPNG");
		return TCL_ERROR;
	}
	
	UInt8 * path = Tcl_GetStringFromObj(objv[1], NULL);
	
	CGImageRef img = getImageRefFromPath(path);
	
	if(img == NULL) {
		Tcl_AppendResult (interp, "couldn't create CGImageRef from path.", (char *) NULL);
		return TCL_ERROR;
	}
	
	OverlayApplicationDockTileImage(img);
	
	CGImageRelease(img);
	
	return TCL_OK;
}

int restoreIcon(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
	if(objc > 1) {
		Tcl_WrongNumArgs(interp, objc, objv, NULL);
		return TCL_ERROR;
	}
	
	RestoreApplicationDockTileImage();
}

// Helper function to create a CGImageRef from a path.
CGImageRef getImageRefFromPath(UInt8 * path)
{
	CFURLRef url = NULL;
	CGDataProviderRef dp = NULL;
	CGImageRef img = NULL;
	
	url = CFURLCreateFromFileSystemRepresentation(\
		(CFAllocatorRef)NULL, path, strlen(path), (Boolean)0);
	
	if(url == NULL) {
		return NULL;
	}

	dp = CGDataProviderCreateWithURL(url);

	if(dp == NULL) {
		CFRelease(url);
		return NULL;
	}

	img = CGImageCreateWithPNGDataProvider(dp, NULL, \
		(bool)1, (CGColorRenderingIntent)kCGRenderingIntentDefault);

	CFRelease(url);
	CFRelease(dp);

	if(img == NULL) {
		return NULL;
	}
	
	return img;
}
