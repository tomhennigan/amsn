/*
This file is part of "aMSN".

"aMSN" is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

"aMSN" is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with "aMSN"; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA 
*/

#include "aMSN.h"

int Macdock_Init(Tcl_Interp *interp)
{
	if (Tcl_InitStubs(interp, "8.4", 0) == NULL) {
		return TCL_ERROR;
	}

	Tcl_CreateObjCommand(interp, \
		"::macDock::setIcon", setIcon, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, \
		"::macDock::overlayIcon", overlayIcon, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateObjCommand(interp, \
		"::macDock::restoreIcon", restoreIcon, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	if (Tcl_PkgProvide(interp, "macDock", "0.1") != TCL_OK) {
		return TCL_ERROR;
	}

	return TCL_OK;
}

int Macdock_SafeInit(Tcl_Interp *interp)
{
	return Macdock_Init(interp);
}
