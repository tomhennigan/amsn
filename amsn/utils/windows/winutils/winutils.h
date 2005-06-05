/*	
		File : winutils.h

		Description : Header file for Ariehs windows utilities library

		Author : Arieh Schneier ( lio_lion - lio_lion@user.sourceforge.net)

  */

#ifndef _WINUTILS
#define _WINUTILS

// Include files, must include windows.h before tk.h and tcl.h before tk.h
#include <windows.h>

#include <tcl.h>
#include <tk.h>
//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
#include <tkPlatDecls.h>
#include <shellapi.h>

// Defined as described in tcl.tk compiling extension help
#ifndef STATIC_BUILD

#if defined(_MSC_VER)
#   define EXPORT(a,b) __declspec(dllexport) a b
#   define DllEntryPoint DllMain
#else
#   if defined(__BORLANDC__)
#       define EXPORT(a,b) a _export b
#   else
#       define EXPORT(a,b) a b
#   endif
#endif
#endif


#define DLL_BUILD
#define BUILD_Winutils

#ifdef BUILD_Winutils
#  undef TCL_STORAGE_CLASS
#  define TCL_STORAGE_CLASS DLLEXPORT
#endif

#ifdef __cplusplus
extern "C"
#endif


// Prototype of my functions

EXTERN int Winutils_Init _ANSI_ARGS_((Tcl_Interp *interp));


EXTERN int Tk_WinLoadFile (ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]);

EXTERN int Tk_WinPlaySound (ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]);

EXTERN int Tk_WinRemoveTitle (ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]);

EXTERN int Tk_WinReplaceTitle (ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]);

# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT
#endif /* _WINUTILS */