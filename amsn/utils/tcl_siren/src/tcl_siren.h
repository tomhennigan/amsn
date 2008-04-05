/*	
		File : tcl_siren.h

		Description : Header file for the tcl_siren extension for tcl.

		Author : Youness El Alaoui ( KaKaRoTo - kakaroto@user.sourceforge.net)

  */

#ifndef _TCL_SIREN
#define _TCL_SIREN

// Include files, must include windows.h before tk.h and tcl.h before tk.h or else compiling errors
#include <stdlib.h>
#include "siren7.h"


#ifdef WIN32
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
#define BUILD_TCL_SIREN

#ifdef BUILD_TCL_SIREN
#  undef TCL_STORAGE_CLASS
#  define TCL_STORAGE_CLASS DLLEXPORT
#endif

#ifdef __cplusplus
extern "C"
#endif

typedef enum enumSirenCodecType
{
    SIREN_ENCODER,
	SIREN_DECODER,
} SirenCodecType;

typedef struct SirenCodecObject {
	SirenEncoder encoder;
	SirenDecoder decoder;
	SirenCodecType codecType;
	char name[30];
} SirenCodecObject;


// External functions
EXTERN int Siren_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Siren_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Tcl_siren_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Tcl_siren_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));

EXTERN int Siren_NewEncoder _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Siren_Encode _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));
EXTERN int Siren_NewDecoder _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Siren_Decode _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Siren_WriteWav _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Siren_Close _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[])); 


# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT
#endif /* _TCL_SIREN */
