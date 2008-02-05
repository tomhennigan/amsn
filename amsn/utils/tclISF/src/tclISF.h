#ifndef     TCLISF_H
#define     TCLISF_H


#ifdef WIN32
#include <windows.h>
#endif

#include    <tcl.h>

#include    "libISF/libISF.h"


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
#define BUILD_TCLISF

#ifdef BUILD_TCLISF
#  undef TCL_STORAGE_CLASS
#  define TCL_STORAGE_CLASS DLLEXPORT
#endif

#ifdef __cplusplus
extern "C"
#endif

/*
 * Declaration for application-specific command procedure
 */
EXTERN int tclISF_save _ANSI_ARGS_((
        ClientData clientData,
        Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]));

EXTERN int Tclisf_Init _ANSI_ARGS_((Tcl_Interp *interp));


EXTERN ISF_t * getISF_FromTclList _ANSI_ARGS_((
        Tcl_Interp *interp,
        Tcl_Obj ** strokes_vector,
        Tcl_Obj ** drawAttrs_vector,
        int strokes_counter));


EXTERN int writeGIFFortified _ANSI_ARGS_((
        Tcl_Interp * interp,
        const char * filename,
        payload_t * rootTag,
        INT64 outputFileSize));

EXTERN unsigned int stringToAABBGGRRColor _ANSI_ARGS_((char * color_string));

# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT
#endif /* TCLISF_H */
