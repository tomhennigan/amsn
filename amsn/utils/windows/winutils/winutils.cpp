/*
		File : winutils.cpp

		Description :	Ariehs library for windows utilities

		MAN :

			NAME :
				WinLoadFile
			SYNOPSYS :
				WinLoadFile file
			DESCRIPTION :
				This command loads a file (or url) with the default application.


			NAME :
				WinPlaySound
			SYNOPSYS :
				WinPlaySound file
			DESCRIPTION :
				Plays a sound file


			NAME :
				WinSayit
			SYNOPSYS :
				WinSayit text
			DESCRIPTION :
				Speaks the text "text"

  
			NAME :
				WinRemoveTitle
			SYNOPSYS :
				WinRemoveTitle window titlebarheight
			DESCRIPTION :
				Removes the title bar and border of the window (plus a little extra)


			NAME :
				WinReplaceTitle
			SYNOPSYS :
				WinReplaceTitle window
			DESCRIPTION :
				Replaces the title bar and border of the window (whatever was removed with WinRemoveTitle)


		Author : Arieh Schneier ( lio_lion - lio_lion@user.sourceforge.net)

		In order to be able to use UNICODE functions with Win9x we must use the unicows system
		http://libunicows.sourceforge.net/ provides a free implementation of the lib that is compatible with opencow and unicows

*/

//HWND hWnd = Tk_GetHWND(Tk_WindowId((Tk_Window) clientData));

// Include the header file
#include "winutils.h"

static int Tk_WinLoadFile (ClientData clientData,
								 Tcl_Interp *interp,
								 int objc,
								 Tcl_Obj *CONST objv[]) {

	WCHAR *file = NULL;
	Tcl_Obj *argsObj = NULL;
	WCHAR* argsStr = NULL;
	int res;

	// We verify the arguments, we must have one arg, not more
	if( objc < 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"WinLoadFile file [arguments]\"" , (char *) NULL);
		return TCL_ERROR;
	}

	// Get the first argument string (file)
	file = Tcl_GetUnicode(objv[1]);

	if (objc >= 3) {
		argsObj = Tcl_NewStringObj("", 0);
		//Get the arguments
		for (int i=2; i<objc; i++)
		{
			Tcl_AppendObjToObj(argsObj, objv[i]);
			if (i == objc-1) Tcl_AppendToObj(argsObj," ",-1);
		}
		argsStr = Tcl_GetUnicode(argsObj);
	}

	res = (int) ShellExecute(NULL, L"open", file, argsStr, NULL, SW_SHOWNORMAL);
	if (res <= 32) {
		Tcl_Obj *result = Tcl_NewStringObj("Unable to open file : ", strlen("Unable to open file : "));
		Tcl_AppendUnicodeToObj(result, file, lstrlen(file));
		Tcl_AppendToObj(result, " " , strlen(" "));
		Tcl_AppendUnicodeToObj(result, argsStr, lstrlen(argsStr));
		Tcl_AppendToObj(result, " : " , strlen(" : "));
		Tcl_AppendObjToObj(result, Tcl_NewIntObj(res));

		Tcl_SetObjResult(interp, result);
		return TCL_ERROR;
	}

	return TCL_OK;
}

static int Tk_WinPlaySound (ClientData clientData,
								 Tcl_Interp *interp,
								 int objc,
								 Tcl_Obj *CONST objv[]) {

	WCHAR *file = NULL;


	// We verify the arguments, we must have one arg, not more
	if( objc < 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"WinPlaySound file\"" , (char *) NULL);
		return TCL_ERROR;
	}

	// Get the first argument string (file)
	file = Tcl_GetUnicode(objv[1]);

	PlaySound(file, NULL, SND_ASYNC | SND_NODEFAULT);


	return TCL_OK;
}

static int Tk_WinSayit (ClientData clientData,
								 Tcl_Interp *interp,
								 int objc,
								 Tcl_Obj *CONST objv[]) {

	WCHAR * text = NULL;

	// We verify the arguments, we must have one arg, not more
	if( objc < 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"WinSayit text\"" , (char *) NULL);
		return TCL_ERROR;
	}

	// Get the first argument string (file)
	text=Tcl_GetUnicode(objv[1]);

    ISpVoice * pVoice = NULL;

    if (FAILED(::CoInitialize(NULL))){
		Tcl_AppendResult (interp, "Failed to run ::CoInitialize" , (char *) NULL);
		return TCL_ERROR;
	}

    HRESULT hr = CoCreateInstance(CLSID_SpVoice, NULL, CLSCTX_ALL, IID_ISpVoice, (void **)&pVoice);
    if( SUCCEEDED( hr ) )
    {
        hr = pVoice->Speak(text, SPF_DEFAULT | SPF_IS_NOT_XML, NULL); //| SPF_ASYNC 
        pVoice->Release();
        pVoice = NULL;
    }

    ::CoUninitialize();
	return TCL_OK;
}

static int Tk_WinRemoveTitle (ClientData clientData,
								 Tcl_Interp *interp,
								 int objc,
								 Tcl_Obj *CONST objv[]) {
	HWND hWnd;
	Tk_Window tkwin;
	Window window;
	char * win = NULL;

	// We verify the arguments, we must have one arg, not more
	if( objc < 3) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"WinRemoveTitle window titlebarheight\"" , (char *) NULL);
		return TCL_ERROR;
	}


	// Get the first argument string (object name) and check it 
	win=Tcl_GetStringFromObj(objv[1], NULL);
	// We check if the pathname is valid, this means it must beguin with a "." 
	// the strncmp(win, ".", 1) is used to compare the first char of the pathname
	if (strncmp(win,".",1)) {
		Tcl_AppendResult (interp, "Bad window path name : ",
			Tcl_GetStringFromObj(objv[1], NULL) , (char *) NULL);
		return TCL_ERROR;
	}

	// Here we ge the long pathname (tk window name), from the short pathname, using the MainWindow from the interpreter
	tkwin = Tk_NameToWindow(interp, win, Tk_MainWindow(interp));
	// Error check
	if ( tkwin == NULL) return TCL_ERROR;

	// We then get the windowId (the X token) of the window, from it's long pathname
	window = Tk_WindowId(tkwin);
	// Error check
	if ( window == NULL ) {
		Tcl_AppendResult (interp, "error while processing WindowId : Window probably not viewable", (char *) NULL);
		return TCL_ERROR;
	}
	
	// We then get the HWND (Window Handler) from the X token.
	hWnd = Tk_GetHWND(window);
	// Error check
	if ( hWnd == NULL ) {
		Tcl_AppendResult (interp, "error while processing GetHWND ", (char *) NULL);
		return TCL_ERROR;
	}

	// We get it's parent window handler. This is a bit tricky, in fact, in Tk, toplevel windows are 
	// just widgets embeded in a container, and we need to get that container's HWND to make it flash
	hWnd = GetParent(hWnd);
	// Error check
	if ( hWnd == NULL || ! IsWindow(hWnd)) {
		Tcl_AppendResult(interp, "Unknown error, pathname is not a valid toplevel window" , (char *) NULL);
		return TCL_ERROR;
	}


	// --------------------------------------------------
	// change window style (get rid of the caption bar)
	// --------------------------------------------------
	DWORD dwStyle = GetWindowLong(hWnd, GWL_STYLE);
	//dwStyle &= ~(WS_CAPTION|WS_SIZEBOX|WS_SYSMENU|WS_MAXIMIZEBOX|WS_MINIMIZEBOX);
	dwStyle &= ~(WS_CAPTION|WS_SIZEBOX);
	//SetWindowLong(hWnd, GWL_STYLE, dwStyle);
	if ( SetWindowLong(hWnd, GWL_STYLE, dwStyle) == 0 ) {
		Tcl_AppendResult (interp, "error while SetWindowLong ", (char *) NULL);
		return TCL_ERROR;
	}

	// --------------------------------------------------
	// set the visible regions
	// --------------------------------------------------
//	HRGN hRegion1 = CreateRectRgn(Tcl_GetIntFromObj(interp,objv[2], NULL),
//									Tcl_GetIntFromObj(interp,objv[3], NULL),
//									Tcl_GetIntFromObj(interp,objv[4], NULL),
//									Tcl_GetIntFromObj(interp,objv[5], NULL));

	RECT rc;
	if(!GetWindowRect(hWnd,&rc))
	{
		Tcl_AppendResult (interp, "error while GetWindowRect ", (char *) NULL);
		return TCL_ERROR;
	}
	int width = (rc.right)-(rc.left);
	int height = rc.bottom-rc.top;
	//int menuheight = Tcl_GetIntFromObj(interp,objv[2], NULL);
	int menuheight;
	char * ob = Tcl_GetStringFromObj(objv[2], NULL);
	sscanf(ob,"%d",&menuheight);

	//region 1 is menu size
	HRGN hRegion1 = CreateRectRgn(menuheight,0,width/2,menuheight);
	//region 2 is main area
	HRGN hRegion2 = CreateRectRgn(0,menuheight,width,height);
	//this if for rounded corners
	//HRGN hRegion2 = CreateRoundRectRgn(0,menuheight,width,height,menuheight,menuheight);
	//combine both into region1
	CombineRgn(hRegion1, hRegion1, hRegion2, RGN_OR);
	//using regions 2, as hiding menu bar for now (to show it just set its height to 0)
	SetWindowRgn(hWnd, hRegion2, true);
	DeleteObject(hRegion1);
	DeleteObject(hRegion2);

	// --------------------------------------------------
	// force a window repainting
	// --------------------------------------------------
	InvalidateRect(hWnd, NULL, TRUE);
	SetWindowPos(hWnd, NULL, 0,0,320,242, SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_FRAMECHANGED);
//	SetWindowPos(hWnd, NULL, 0,0,320,242, SWP_NOMOVE|SWP_NOZORDER);
//	SetWindowPos(hWnd, NULL, 0,0,320,242, SWP_NOREPOSITION | SWP_NOZORDER | SWP_FRAMECHANGED);


	char res[200];
	sprintf(res, "%d , %d , %d , %d , %d , %d , %d",rc.left,rc.right,rc.top,rc.bottom, width, height, menuheight);
	Tcl_SetResult (interp, res, TCL_VOLATILE);
	return TCL_OK;
}


static int Tk_WinReplaceTitle (ClientData clientData,
								 Tcl_Interp *interp,
								 int objc,
								 Tcl_Obj *CONST objv[]) {
	HWND hWnd;
	Tk_Window tkwin;
	Window window;
	char * win = NULL;

	// We verify the arguments, we must have one arg, not more
	if( objc < 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"WinReplaceTitle window\"" , (char *) NULL);
		return TCL_ERROR;
	}


	// Get the first argument string (object name) and check it 
	win=Tcl_GetStringFromObj(objv[1], NULL);
	// We check if the pathname is valid, this means it must beguin with a "." 
	// the strncmp(win, ".", 1) is used to compare the first char of the pathname
	if (strncmp(win,".",1)) {
		Tcl_AppendResult (interp, "Bad window path name : ",
			Tcl_GetStringFromObj(objv[1], NULL) , (char *) NULL);
		return TCL_ERROR;
	}

	// Here we ge the long pathname (tk window name), from the short pathname, using the MainWindow from the interpreter
	tkwin = Tk_NameToWindow(interp, win, Tk_MainWindow(interp));
	// Error check
	if ( tkwin == NULL) return TCL_ERROR;

	// We then get the windowId (the X token) of the window, from it's long pathname
	window = Tk_WindowId(tkwin);
	// Error check
	if ( window == NULL ) {
		Tcl_AppendResult (interp, "error while processing WindowId : Window probably not viewable", (char *) NULL);
		return TCL_ERROR;
	}
	
	// We then get the HWND (Window Handler) from the X token.
	hWnd = Tk_GetHWND(window);
	// Error check
	if ( hWnd == NULL ) {
		Tcl_AppendResult (interp, "error while processing GetHWND ", (char *) NULL);
		return TCL_ERROR;
	}

	// We get it's parent window handler. This is a bit tricky, in fact, in Tk, toplevel windows are 
	// just widgets embeded in a container, and we need to get that container's HWND to make it flash
	hWnd = GetParent(hWnd);
	// Error check
	if ( hWnd == NULL || ! IsWindow(hWnd)) {
		Tcl_AppendResult(interp, "Unknown error, pathname is not a valid toplevel window" , (char *) NULL);
		return TCL_ERROR;
	}


	// --------------------------------------------------
	// change window style (replace the caption bar)
	// --------------------------------------------------
	DWORD dwStyle = GetWindowLong(hWnd, GWL_STYLE);
	dwStyle |= (WS_CAPTION|WS_SIZEBOX);
	if ( SetWindowLong(hWnd, GWL_STYLE, dwStyle) == 0 ) {
		Tcl_AppendResult (interp, "error while SetWindowLong ", (char *) NULL);
		return TCL_ERROR;
	}

	// --------------------------------------------------
	// remove any regions
	// --------------------------------------------------
	SetWindowRgn(hWnd, NULL, true);

	// --------------------------------------------------
	// force a window repainting
	// --------------------------------------------------
	InvalidateRect(hWnd, NULL, TRUE);
	SetWindowPos(hWnd, NULL, 0,0,320,242, SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_FRAMECHANGED);


	return TCL_OK;
}

/*
	Function	:	Winutils_Init
	Description :	The Init function that will be called when the extension is loaded to your tk shell
	Arguments   :	Tcl_Interp *interp    :	This is the interpreter from which the load was made and to 
											which we'll add the new command
	Return value : TCL_OK in case everything is ok, or TCL_ERROR in case there is an error (Tk version < 8.3)
	Comments     : 
*/
int Winutils_Init (Tcl_Interp *interp ) {
	
	//Check TCl version
	if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
		return TCL_ERROR;
	}

	//Check TK version
	if (Tk_InitStubs(interp, TK_VERSION, 0) == NULL) {
		return TCL_ERROR;
	}
	
	
	// Create the new command "WinLoadFile" linked to the ShellExecute function
	Tcl_CreateObjCommand(interp, "WinLoadFile", Tk_WinLoadFile,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// Create the new command "WinPlaySound" linked to the PlaySound function
	Tcl_CreateObjCommand(interp, "WinPlaySound", Tk_WinPlaySound,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// Create the new command "WinSayit"
	Tcl_CreateObjCommand(interp, "WinSayit", Tk_WinSayit,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// Create the new command "WinRemoveTitle"
	Tcl_CreateObjCommand(interp, "WinRemoveTitle", Tk_WinRemoveTitle,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// Create the new command "WinReplaceTitle"
	Tcl_CreateObjCommand(interp, "WinReplaceTitle", Tk_WinReplaceTitle,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// end
	return TCL_OK;
}
