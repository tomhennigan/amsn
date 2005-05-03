/*	
		File : webcamsn.h

		Description : Header file for the webcamsn extension for tk. A wrapper for libmimdec

		Author : Youness El Alaoui ( KaKaRoTo - kakaroto@user.sourceforge.net)

  */

#ifndef _WEBCAMSN
#define _WEBCAMSN

// Include files, must include windows.h before tk.h and tcl.h before tk.h or else compiling errors
#include <stdlib.h>
#include <mimic.h>


#ifdef WIN32
#include <windows.h>
#endif

#include "string.h"


#include <tcl.h>
#include <tk.h>

#include <tkPlatDecls.h>


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
#define BUILD_WEBCAMSN

#ifdef BUILD_WEBCAMSN
#  undef TCL_STORAGE_CLASS
#  define TCL_STORAGE_CLASS DLLEXPORT
#endif

#ifdef __cplusplus
extern "C"
#endif

typedef unsigned char  BYTE;
typedef unsigned short WORD;
typedef unsigned long  DWORD;
typedef unsigned int   UINT; 


typedef struct mimic_header {
  	WORD	header_size;
	WORD	width;
	WORD	height;
	WORD	reserved1;
	DWORD	payload_size;
	DWORD	fourcc;
	DWORD	reserved2;
	DWORD	reserved3;
} MimicHeader; 



enum codec_types {ENCODER, DECODER_UNINITIALIZED, DECODER_INITIALIZED};

struct CodecInfo {
	MimCtx * codec;
	enum codec_types type;
	char name[30];
	unsigned int frames;
};

typedef struct CodecInfo CodecInfo;

#define g_list Codecs
#define data_item CodecInfo
#define list_element_id name

#define MAX_INTERFRAMES 15


EXTERN BYTE * RGBA2RGB(Tk_PhotoImageBlock data);


// External functions
EXTERN int Webcamsn_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Webcamsn_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));


EXTERN int Webcamsn_NewDecoder _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));
EXTERN int Webcamsn_NewEncoder _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));
EXTERN int Webcamsn_Decode _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Webcamsn_Encode _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Webcamsn_SetQuality _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Webcamsn_GetWidth _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Webcamsn_GetHeight _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Webcamsn_GetQuality _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));

EXTERN int Webcamsn_Close _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[])); 

EXTERN int Webcamsn_Count _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[])); 

EXTERN int Webcamsn_Frames _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[])); 


# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT
#endif /* _TKCXIMAGE */
