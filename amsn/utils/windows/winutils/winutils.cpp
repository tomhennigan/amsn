/*
		File : winutils.cpp

		Description :	Ariehs library for windows utilities

		MAN :

			NAME :
				WinLoadFile - loads a file (can also be a url) with the default application

			SYNOPSYS :
				WinLoadFile file

			DESCRIPTION :
				This command loads a file (or url) with the default application.


		Author : Arieh Schneier ( lio_lion - lio_lion@user.sourceforge.net)
*/

//HWND hWnd = Tk_GetHWND(Tk_WindowId((Tk_Window) clientData));

// Include the header file
#include "winutils.h"

static int Tk_WinLoadFile (ClientData clientData,
								 Tcl_Interp *interp,
								 int objc,
								 Tcl_Obj *CONST objv[]) {

	char * file = NULL;


	// We verify the arguments, we must have one arg, not more
	if( objc < 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"WinLoadFile file\"" , (char *) NULL);
		return TCL_ERROR;
	}

	// Get the first argument string (file)
	file=Tcl_GetStringFromObj(objv[1], NULL);

	ShellExecute(NULL,"open", file, NULL, NULL, SW_SHOWNORMAL);


	return TCL_OK;
}



/*
	Function : Winutils_Init

	Description :	The Init function that will be called when the extension is loaded to your tk shell

	Arguments   :	Tcl_Interp *interp    :	This is the interpreter from which the load was made and to 
											which we'll add the new command


	Return value : TCL_OK in case everything is ok, or TCL_ERROR in case there is an error (Tk version < 8.3)

	Comments     : 

*/
int Winutils_Init (Tcl_Interp *interp ) {
	
	//Check TK version is 8.0 or higher
	if (Tk_InitStubs(interp, "8.3", 0) == NULL) {
		return TCL_ERROR;
	}
	
	
	// Create the new command "WinLoadFile" linked to the ShellExecute function
	Tcl_CreateObjCommand(interp, "WinLoadFile", Tk_WinLoadFile,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	
	// end
	return TCL_OK;
}
