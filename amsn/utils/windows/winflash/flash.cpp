/*
		File : flash.cpp

		Description :	Contains all functions for the Tk extension of flash windows
						This is an extension for Tk only for windows, it will make the window 
						flash in the taskbar until it gets focus.

		MAN :

			NAME :
				winflash - Flashes the window taskbar and caption of a toplevel widget

			SYNOPSYS :
				winflash window_name ?option value option value...?

			DESCRIPTION :
				This command will make the taskbar of a toplevel window and it's caption flash under windows,
				the window_name argument must be the tk pathname of a toplevel widget (.window for example)
				The options (abbrevations allowed) are as follow :

				-state <boolean>
					The -state option sets is used to make the window flash or to make it stop flashing, a boolean 
					must follow the -state option, 0 to make it stop flashing, 1 to make it flash.

				-count <int>
					The -count option specifies the number of time the window must flash before stoping and keeping the 
					orange color. Use -1 to make it flash continuously (you then MUST use a winflash -state 0 to make it 
					stop, it won't stop even if it gets the focus.

				-interval <int>
					The -interval option specifies the interval in ms between each flash, use 0 to take the default 
					cursor timeout.

				-tray <boolean>
					The -tray option can be used to specify that you only want the taskbar to flash.
					If not specified, the taskbar AND the title of the window will flash.
					if you want only the tray to flash, use -caption 0

				-caption <boolean>
					The -caption option can be used to specify that you only want the title of the window to flash
					If you want only the title to flash, use -tray 0

				-appfocus <boolean>
					This option is used to specify that the flashing should stop when any window of the application gets focus.
					If not specified, the flashing will stop only when focus is on the flashing window.



		Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
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

	Comments     : hummmm... not much, it's simple :)

*/
static int Tk_FlashWindow (ClientData clientData,
								 Tcl_Interp *interp,
								 int objc,
								 Tcl_Obj *CONST objv[]) {
	

	// We declare our variables, we need one for every intermediate token we get,
	// so we can verify if one of the function calls returned NULL

	HWND hwnd;
	Tk_Window tkwin;
	Window window;
	char * win = NULL,
		* option = NULL,
		opt[10],
		opt1, opt2;
	int state = 1,
		count = 5,
		interval = 0,
		tray = 1,
		caption = 1,
		appfocus = 0,
		optlength,
		ret = TCL_OK;
    

	// We verify the arguments, we must have one arg, not more
	if( objc < 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"winflash window_name \?option value option value...\?\"" , (char *) NULL);
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
	

	// We then get each more arguments if they exist, and check their validity, and then change variables depending on options
	// We stop one arg before the last arg, because we parse 2 at a time, and we stop when the return value of Tcl_GetBooleanFromObj 
	// or Tcl_GetIntFromObj returns TCL_ERROR
	for (int i = 2; i < objc -1 && ret != TCL_ERROR; i++) {
		// We get the option and the first two chars to compare with (to allow abbrevations)
		option = Tcl_GetStringFromObj(objv[i], &optlength);
		if ( strncmp(option, "-", 1) ){
			Tcl_AppendResult (interp, "Invalid option : ",
				Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
			return TCL_ERROR;
		}
		if ( optlength < 2 ) {
			opt1 = '\0';
			opt2 = '\0';
		}
		if ( optlength == 2 ){
			opt1 = option[1];
			opt2 = '\0';
		}
		if (optlength > 2) { 
			opt1 = option[1];
            opt2 = option[2];
		} 

		// Switch, depending on first letter of the option (after the -)
		switch (opt1) {
			// The state option
			case 's':
				// We compare each char of the option with "-state"
				strcpy(opt,"-state");
				// If option is longer than -state, then it's not valid (also avoids bug in the for statement below
				if ( optlength > 6) {
					Tcl_AppendResult (interp, "Invalid option : ",
						Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
					return TCL_ERROR;
				}
				// For each char of the option, compare it.
				for ( int j = 2; j < optlength ; j++) {
					if ( option[j] != opt[j]) {
						Tcl_AppendResult (interp, "Invalid option : ",
							Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
						return TCL_ERROR;
					}
				}
			
				// Retreive the value
				ret = Tcl_GetBooleanFromObj(interp, objv[++i],&state);
				break;
			case 'c':
				// The -count and -caption options
				if ( opt2 == 'o' ) {
					// The -count option
					strcpy(opt,"-count");

					// comments are the same as in the -state option
					if ( optlength > 6) {
						Tcl_AppendResult (interp, "Invalid option : ",
							Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
						return TCL_ERROR;
					}
					for ( int j = 2; j < optlength ; j++) {
						if ( option[j] != opt[j]) {
							Tcl_AppendResult (interp, "Invalid option : ",
								Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
							return TCL_ERROR;
						}
					}

					ret = Tcl_GetIntFromObj(interp, objv[++i],&count);
				} else if (opt2 == 'a' ) {
					// The -caption option
					strcpy(opt,"-caption");
					if ( optlength > 8) {
						Tcl_AppendResult (interp, "Invalid option : ",
							Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
						return TCL_ERROR;
					}
					for ( int j = 2; j < optlength ; j++) {
						if ( option[j] != opt[j]) {
							Tcl_AppendResult (interp, "Invalid option : ",
								Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
							return TCL_ERROR;
						}
					}

					ret = Tcl_GetBooleanFromObj(interp, objv[++i],&caption);
				} else {
					// If the second letter is not 'o' or 'a' (for count/caption), bring error
					Tcl_AppendResult (interp, "Invalid option : ",
						Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
					return TCL_ERROR;
				}
				break;
			case 'i':
				// The -interval option
				strcpy(opt,"-interval");
				if ( optlength > 9) {
					Tcl_AppendResult (interp, "Invalid option : ",
						Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
					return TCL_ERROR;
				}
				for ( int j = 2; j < optlength ; j++) {
					if ( option[j] != opt[j]) {
						Tcl_AppendResult (interp, "Invalid option : ",
							Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
						return TCL_ERROR;
					}
				}

				ret = Tcl_GetIntFromObj(interp, objv[++i],&interval);
				break;
			case 't':
				// The -trat option
				strcpy(opt,"-tray");
				if ( optlength > 5) {
					Tcl_AppendResult (interp, "Invalid option : ",
						Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
					return TCL_ERROR;
				}
				for ( int j = 2; j < optlength ; j++) {
					if ( option[j] != opt[j]) {
						Tcl_AppendResult (interp, "Invalid option : ",
							Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
						return TCL_ERROR;
					}
				}

				ret = Tcl_GetBooleanFromObj(interp, objv[++i],&tray);
				break;
			case 'a':
				// The -appfocus option
				strcpy(opt,"-appfocus");
				if ( optlength > 9) {
					Tcl_AppendResult (interp, "Invalid option : ",
						Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
					return TCL_ERROR;
				}
				for ( int j = 2; j < optlength ; j++) {
					if ( option[j] != opt[j]) {
						Tcl_AppendResult (interp, "Invalid option : ",
							Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
						return TCL_ERROR;
					}
				}

				ret = Tcl_GetBooleanFromObj(interp, objv[++i],&appfocus);
				break;
			default:
				// If no valid option, bring error
				Tcl_AppendResult (interp, "Invalid option : ",
					Tcl_GetStringFromObj(objv[i], NULL), "\nMust be -state, -count, -interval, -tray, -caption or -appfocus", (char *) NULL);
				return TCL_ERROR;
		}

	}

	// If one of the Tcl_Get*FromObj returned error, then bring error
	if ( ret == TCL_ERROR ) return TCL_ERROR;
 
	// If we stopped before the end, then there is an option without value, bring error.
	if ( i != objc) {
		Tcl_AppendResult (interp, "Option \"",
			Tcl_GetStringFromObj(objv[i], NULL), "\" don't have any value", (char *) NULL);
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
	hwnd = Tk_GetHWND(window);

	// Error check
	if ( hwnd == NULL ) {
		Tcl_AppendResult (interp, "error while processing GetHWND ", (char *) NULL);
		return TCL_ERROR;
	}

	// We get it's parent window handler. This is a bit tricky, in fact, in Tk, toplevel windows are 
	// just widgets embeded in a container, and we need to get that container's HWND to make it flash
	hwnd = GetParent(hwnd);

	if ( hwnd == NULL || ! IsWindow(hwnd)) {
		Tcl_AppendResult(interp, "Unknown error, pathname is not a valid toplevel window" , (char *) NULL);
		return TCL_ERROR;
	}


	// We set our structure and fill it properly
	FLASHWINFO fInfo;
	fInfo.hwnd = hwnd;
	fInfo.cbSize = sizeof(fInfo);
	fInfo.uCount = count;  // number of times to flash
	fInfo.dwTimeout = interval; //Time out between flashes, 0 means default
	
	// The FLASHW_STOP flag is equal to 0, so if state is set to false, the flag is FLASHW_STOP, else, it has one of the 
	// flafs from below
	fInfo.dwFlags = FLASHW_STOP;


	// depending on options, fill the flag variable
	if ( state) {
		if ( tray) {
			fInfo.dwFlags |= FLASHW_TRAY;
		}
		if ( caption ) {
			fInfo.dwFlags |= FLASHW_CAPTION;
		}
		if ( appfocus) {
			fInfo.dwFlags |= FLASHW_TIMERNOFG;
		}
	} 

	// Finally call the Windows API, and it's done :D
	FlashWindowEx ( &fInfo);

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
	
	
	// Create the new command "winflash" linked to the Tk_FlashWindow function with a NULL clientdata and no deleteproc
	Tcl_CreateObjCommand(interp, "winflash", Tk_FlashWindow,
		(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	
	// end
	return TCL_OK;
}
