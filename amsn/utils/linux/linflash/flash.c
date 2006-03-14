/*
  File : flash.cpp
  
  Description :	Contains all functions for the Tk extension of flash windows
  This is an extension for Tk only for windows, it will make the window 
  flash in the taskbar until it gets focus.
  
  MAN :
  
  NAME :
  winflash - Flashes the window taskbar and caption of a toplevel widget

  SYNOPSYS :
  winflash window_name 

  DESCRIPTION :
  This command will make the taskbar of a toplevel window and it's caption flash under linux,
  the window_name argument must be the tk pathname of a toplevel widget (.window for example)
			

  Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
  Sander Hoentjen (Tjikkun)
*/


// Include the header file
#include "flash.h"


/*
  Function : Tk_FlashWindow

  Description :	This is the function that does the whole job, it will flash the window as 
  given in it's argument

  Arguments   :	ClienData clientdata  :	who knows what's that used for :P 
  anways, it's set to NULL and it's not used

  Tcl_Interp *interp    :	This is the interpreter that called this function
  it will be used to get some info about the window used
	
  int objc			  :	This is the number of arguments given to the function
	
  Tcl_Obj *CONST objv[] : This is the array that contains all arguments given to
  the function
	
  Return value : TCL_OK in case everything is ok, or TCL_ERROR in case there is an error
	
  Comments     :  http://standards.freedesktop.org/wm-spec/1.4/ar01s05.html#id2527339

*/
int Tk_FlashWindow (ClientData clientData,
			   Tcl_Interp *interp,
			   int objc,
			   Tcl_Obj *CONST objv[]) {
  

  // We verify the arguments, we must have one arg, not more
  if( objc != 2) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"linflash window_name\"" , (char *) NULL);
    return TCL_ERROR;
  }
	

  return flash_window(interp, objv[1], 1l);
}

int Tk_UnFlashWindow (ClientData clientData,
			   Tcl_Interp *interp,
			   int objc,
			   Tcl_Obj *CONST objv[]) {
  

  // We verify the arguments, we must have one arg, not more
  if( objc != 2) {
    Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"linunflash window_name\"" , (char *) NULL);
    return TCL_ERROR;
  }
	

  return flash_window(interp, objv[1], 0l);
}

int flash_window (Tcl_Interp *interp, Tcl_Obj *CONST objv1, long flash) {

  // We declare our variables, we need one for every intermediate token we get,
  // so we can verify if one of the function calls returned NULL
  char * win = NULL;
  Tk_Window tkwin;
  Window window;
  Display * xdisplay;
  Window root, parent, *children;
  unsigned int n;

  static Atom demandsAttention;
  static Atom wmState;

  XEvent e;
  memset(&e, 0, sizeof(e));
  // Get the first argument string (object name) and check it 
  win = Tcl_GetStringFromObj(objv1, NULL);

  // We check if the pathname is valid, this means it must beguin with a "." 
  // the strncmp(win, ".", 1) is used to compare the first char of the pathname

  if (strncmp(win,".",1)) {
    Tcl_AppendResult (interp, "Bad window path name : ",
		      Tcl_GetStringFromObj(objv1, NULL) , (char *) NULL);
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


  xdisplay = Tk_Display(tkwin);

  // We need Atom-s created only once, they don't change during runtime
  demandsAttention = XInternAtom(xdisplay, "_NET_WM_STATE_DEMANDS_ATTENTION", True);
  wmState = XInternAtom(xdisplay, "_NET_WM_STATE", True);

  XQueryTree(xdisplay, window, &root, &parent, &children, &n);
  XFree(children);

  e.xclient.type = ClientMessage;
  e.xclient.message_type = wmState;
  //Since under *nix Tk wraps all windows in another one to put a menu bar, we must use the parent window ID which is the top one
  e.xclient.window = parent;
  e.xclient.display = xdisplay;
  e.xclient.format = 32;
  e.xclient.data.l[0] = flash;
  e.xclient.data.l[1] = demandsAttention;
  e.xclient.data.l[2] = 0l;
  e.xclient.data.l[3] = 0l;
  e.xclient.data.l[4] = 0l;
  
  
  if (XSendEvent(xdisplay, root, False, (SubstructureRedirectMask | SubstructureNotifyMask), &e) == 0) 
    return TCL_ERROR;
  
  return TCL_OK;
}



/*
  Function : Flash_Init

  Description :	The Init function that will be called when the extension is loaded to your tk shell

  Arguments   :	Tcl_Interp *interp    :	This is the interpreter from which the load was made and to 
  which we'll add the new command


  Return value : TCL_OK in case everything is ok, or TCL_ERROR in case there is an error (Tk version < 8.3)

  Comments     : hummmm... not much, it's simple :)

*/
int Flash_Init (Tcl_Interp *interp ) {
	
  //Check TK version is 8.0 or higher
  if (Tk_InitStubs(interp, "8.3", 0) == NULL) {
    return TCL_ERROR;
  }


  // Create the new commands 
  Tcl_CreateObjCommand(interp, "linflash", Tk_FlashWindow,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "linunflash", Tk_UnFlashWindow,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	
  // end
  return TCL_OK;
}
