/*	
   File : aio.h

   Description : Header file for the aio extension for tcl.

   Authors : Youness El Alaoui ( KaKaRoTo - kakaroto@user.sourceforge.net)
    Bencheraiet Mohamed abderaouf (kenshin kenshin@cerberus.endoftheinternet.org)


*/

#ifndef _TCL_AIO_H
#define _TCL_AIO_H


#include <aio/aio.h>
#include <aio/af_format.h>
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
#define BUILD_AIO

#ifdef BUILD_AIO
#  undef TCL_STORAGE_CLASS
#  define TCL_STORAGE_CLASS DLLEXPORT
#endif

#ifdef __cplusplus
extern "C"
#endif

// External functions
EXTERN int Aio_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Aio_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Tclaio_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Tclaio_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));


EXTERN int Aio_Open _ANSI_ARGS_((ClientData clientData,
				 Tcl_Interp *interp,
				 int objc,
				 Tcl_Obj *CONST objv[]));

EXTERN int Aio_Play _ANSI_ARGS_((ClientData clientData,
				 Tcl_Interp *interp,
				 int objc,
				 Tcl_Obj *CONST objv[]));

EXTERN int Aio_PlayWav _ANSI_ARGS_((ClientData clientData,
				    Tcl_Interp *interp,
				    int objc,
				    Tcl_Obj *CONST objv[]));

EXTERN int Aio_Record _ANSI_ARGS_((ClientData clientData,
				   Tcl_Interp *interp,
				   int objc,
				   Tcl_Obj *CONST objv[]));

EXTERN int Aio_Close _ANSI_ARGS_((ClientData clientData,
				  Tcl_Interp *interp,
				  int objc,
				  Tcl_Obj *CONST objv[])); 


# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT
#endif /* _TCL_AIO_H */
