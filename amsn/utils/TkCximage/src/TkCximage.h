/*	
		File : flash.h

		Description : Header file for the flash window extension for tk

		Author : Youness El Alaoui ( KaKaRoTo - kakaroto@user.sourceforge.net)

  */

#ifndef _TKCXIMAGE
#define _TKCXIMAGE

// Include files, must include windows.h before tk.h and tcl.h before tk.h or else compiling errors
// So we will include ximage.h before everything else
#include <ximage.h>

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
#define BUILD_CXIMAGE

#ifdef BUILD_CXIMAGE
#  undef TCL_STORAGE_CLASS
#  define TCL_STORAGE_CLASS DLLEXPORT
#endif

#ifdef __cplusplus
extern "C"
#endif

#define AvailableFromats 6
const char *KnownFormats[] = {"cximage", "cxgif", "cxpng", "cxjpg", "cxtga", "cxbmp"};


static int ImageRead(Tcl_Interp *interp, CxImage image, Tk_PhotoHandle imageHandle, int destX, int destY,
					 int width, int height, int srcX, int srcY);

static int ChanMatch (Tcl_Channel chan, CONST char *fileName, Tcl_Obj *format,int *widthPtr,
					  int *heightPtr,Tcl_Interp *interp);
static int ObjMatch (Tcl_Obj *data, Tcl_Obj *format, int *widthPtr, int *heightPtr, Tcl_Interp *interp);
static int ChanRead (Tcl_Interp *interp, Tcl_Channel chan, CONST char *fileName, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
					 int destX, int destY, int width, int height, int srcX, int srcY);
static int ObjRead (Tcl_Interp *interp, Tcl_Obj *data, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
					int destX, int destY, int width, int height, int srcX, int srcY);
static int ChanWrite (Tcl_Interp *interp, CONST char *fileName, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr);
static int StringWrite (Tcl_Interp *interp, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr);

int GetFileTypeFromFileName(char * Filename);
int GetFileTypeFromFormat(char * Format);
void RGB2BGR(Tk_PhotoImageBlock *data);

// External functions
EXTERN int Tkcximage_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Tkcximage_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));


static int Tk_Convert _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));
static int Tk_Resize _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));
static int Tk_Thumbnail _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));


# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT
#endif /* _TKCXIMAGE */
