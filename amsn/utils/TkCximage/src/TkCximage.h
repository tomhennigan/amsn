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

#include <time.h>

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



#define ENABLE_LOGS 1





EXTERN char currenttime[30];
EXTERN FILE * logfile;

inline void timestamp() { 
  time_t t;
  time(&t);
  strftime(currenttime, 29, "[%D %T]", localtime(&t));
};


#if ENABLE_LOGS == 1
#ifndef WINVER
#define LOGS_ENABLED
#endif
#endif

#define LOGPATH "/tmp/TkCximage.log"

inline void LOG (const char * s) {
#ifdef LOGS_ENABLED
  if (logfile) {
    timestamp();
    fprintf(logfile,"\n%s  %s", currenttime, s);
    fflush(logfile);
  }
#endif
}
inline void LOG (const int i) {
#ifdef LOGS_ENABLED
  if (logfile) {
    timestamp();
    fprintf(logfile,"\n%s  %d", currenttime, i);
    fflush(logfile);
  }
#endif
}

inline void APPENDLOG (const char * s) {
#ifdef LOGS_ENABLED
  if (logfile) {
    fprintf(logfile," %s", s);
    fflush(logfile);
  }
#endif
}
inline void APPENDLOG (const int i) {
#ifdef LOGS_ENABLED
  if (logfile) {
    fprintf(logfile," %d", i);
    fflush(logfile);
  }
#endif
}

inline void INITLOGS () {
#ifdef LOGS_ENABLED
logfile = fopen(LOGPATH, "a");
#endif
}



EXTERN static int ImageRead(Tcl_Interp *interp, CxImage image, Tk_PhotoHandle imageHandle, int destX, int destY,
					 int width, int height, int srcX, int srcY);

EXTERN static int ChanMatch (Tcl_Channel chan, CONST char *fileName, Tcl_Obj *format,int *widthPtr,
					  int *heightPtr,Tcl_Interp *interp);
EXTERN static int ObjMatch (Tcl_Obj *data, Tcl_Obj *format, int *widthPtr, int *heightPtr, Tcl_Interp *interp);
EXTERN static int ChanRead (Tcl_Interp *interp, Tcl_Channel chan, CONST char *fileName, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
					 int destX, int destY, int width, int height, int srcX, int srcY);
EXTERN static int ObjRead (Tcl_Interp *interp, Tcl_Obj *data, Tcl_Obj *format, Tk_PhotoHandle imageHandle,
					int destX, int destY, int width, int height, int srcX, int srcY);
EXTERN static int ChanWrite (Tcl_Interp *interp, CONST char *fileName, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr);
EXTERN static int StringWrite (Tcl_Interp *interp, Tcl_Obj *format, Tk_PhotoImageBlock *blockPtr);

EXTERN int GetFileTypeFromFileName(char * Filename);
EXTERN int GetFileTypeFromFormat(char * Format);
EXTERN int RGB2BGR(Tk_PhotoImageBlock *data, BYTE * pixelPtr);

// External functions
EXTERN int Tkcximage_Init _ANSI_ARGS_((Tcl_Interp *interp));
EXTERN int Tkcximage_SafeInit _ANSI_ARGS_((Tcl_Interp *interp));


EXTERN static int Tk_Convert _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));
EXTERN static int Tk_Resize _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));
EXTERN static int Tk_Thumbnail _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]));


# undef TCL_STORAGE_CLASS
# define TCL_STORAGE_CLASS DLLIMPORT
#endif /* _TKCXIMAGE */
