/*	
	File : gupnp.h

	Description : Header file for the gupnp extension for tcl.

	Author : Youness El Alaoui ( KaKaRoTo - kakaroto@user.sourceforge.net)

  */

#ifndef _TCL_GUPNP
#define _TCL_GUPNP

// Include files, must include windows.h before tk.h and tcl.h before tk.h 
// or else compiling errors
#include <stdlib.h>


#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif


#include <tcl.h>


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
#define BUILD_TCL_GUPNP

#ifdef BUILD_TCL_GUPNP
#  undef TCL_STORAGE_CLASS
#  define TCL_STORAGE_CLASS DLLEXPORT
#endif

#ifdef __cplusplus
extern "C"
#endif

// External functions
EXTERN int Gupnp_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Gupnp_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));

EXTERN int Gupnp_New _ANSI_ARGS_((ClientData clientData,
        Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
EXTERN int Gupnp_AddPort _ANSI_ARGS_((ClientData clientData,
        Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
EXTERN int Gupnp_RemovePort _ANSI_ARGS_((ClientData clientData,
        Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));
EXTERN int Gupnp_Free _ANSI_ARGS_((ClientData clientData,
        Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[]));


# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT
#endif /* _TCL_GUPNP */
