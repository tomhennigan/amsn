/*
This file is part of "aMSN".

"aMSN" is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

"aMSN" is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with "aMSN"; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA 
*/

#ifndef __DOCKICON_H_INCLUDE
#define __DOCKICON_H_INCLUDE

#include <tcl.h>
#include <Carbon/Carbon.h>

CGImageRef getImageRefFromPath(UInt8 *);

int setIcon(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);
int overlayIcon(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);
int restoreIcon(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]);

#endif
