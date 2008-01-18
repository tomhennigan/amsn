#ifndef     TCLISF_h
#define     TCLISF_H


/*
 * Declaration for application-specific command procedure
 */
int tclISF_save(ClientData clientData,
        Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]);

int Tclisf_Init(Tcl_Interp *interp);

int tclISF_save(ClientData clientData, Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]);

ISF_t * getISF_FromTclList (Tcl_Interp *interp, Tcl_Obj ** strokes_vector, int strokes_counter);

int writeGIFFortified(
        Tcl_Interp * interp,
        const char * filename,
        payload_t * rootTag,
        INT64 outputFileSize);

#endif
