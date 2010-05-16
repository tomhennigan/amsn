
#include "statusicon.h"

#define QUARTZ_POOL_ALLOC NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]
#define QUARTZ_POOL_RELEASE [pool release]

static int icon_counter = 0;
static Tcl_HashTable *icons = NULL;
static Tcl_HashTable *callbacks = NULL;

typedef struct {
  Tcl_Interp *interp;
  Tcl_Obj *cb;
} callback_s;

int Statusicon_Create(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  char name[15];
  Tcl_HashEntry *hPtr = NULL;
  int newHash;
  callback_s *callback = NULL;

  if(objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "callback");
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;

  callback = (callback_s *) ckalloc(sizeof(callback_s));
  callback->interp = interp;
  callback->cb = objv[1];
  Tcl_IncrRefCount(callback->cb);

  QuartzStatusIcon *status_item = [[QuartzStatusIcon alloc] initWithCallback:Statusicon_Callback andUserData:callback];
  if (status_item == NULL) {
    Tcl_DecrRefCount(callback->cb);
    ckfree(callback);
    QUARTZ_POOL_RELEASE;
    return TCL_ERROR;
  } else {
    sprintf(name, "statusicon%d", ++icon_counter);

    hPtr = Tcl_CreateHashEntry(icons, name, &newHash);
    Tcl_SetHashValue(hPtr, (ClientData) status_item);

    hPtr = Tcl_CreateHashEntry(callbacks, name, &newHash);
    Tcl_SetHashValue(hPtr, (ClientData) callback);

    Tcl_ResetResult(interp);
    Tcl_AppendResult(interp, name, NULL);
  }
  QUARTZ_POOL_RELEASE;
	
  return TCL_OK;
}

void Statusicon_Callback(QuartzStatusIcon *status_item, void *user_data, int doubleAction)
{
  callback_s * callback = (callback_s *) user_data;
  Tcl_Obj *action = Tcl_NewStringObj(doubleAction ? "DOUBLE_ACTION" : "ACTION", -1);
  Tcl_Obj *eval = Tcl_NewStringObj("eval", -1);
  Tcl_Obj *command[] = {eval, callback->cb, action};

  Tcl_Obj *cb = callback->cb;
  Tcl_IncrRefCount (eval); 
  Tcl_IncrRefCount (action); 
  Tcl_IncrRefCount (cb); 

  if (Tcl_EvalObjv(callback->interp, 3, command, TCL_EVAL_GLOBAL) == TCL_ERROR) {
    Tcl_BackgroundError(callback->interp);
  }

  Tcl_DecrRefCount (eval); 
  Tcl_DecrRefCount (action); 
  Tcl_DecrRefCount (cb); 
  
}

int Statusicon_SetImage(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  QuartzStatusIcon *status_item;
  Tcl_HashEntry *hPtr = NULL;
  char * name = NULL;
  char * path = NULL;

  // We verify the arguments
  if( objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "icon pathToImage");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);
  path = Tcl_GetStringFromObj(objv[2], NULL);

  hPtr = Tcl_FindHashEntry(icons, name);
  if (hPtr != NULL) {
    status_item = (QuartzStatusIcon *) Tcl_GetHashValue(hPtr);
  }

  if (!status_item) {
    Tcl_AppendResult (interp, "Invalid StatusIcon : " , name, (char *) NULL);
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;
  [status_item setImagePath:path];
  QUARTZ_POOL_RELEASE;

  return TCL_OK;
}

int Statusicon_SetAlternateImage(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  QuartzStatusIcon *status_item;
  Tcl_HashEntry *hPtr = NULL;
  char * name = NULL;
  char * path = NULL;

  // We verify the arguments
  if( objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "icon pathToImage");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);
  path = Tcl_GetStringFromObj(objv[2], NULL);

  hPtr = Tcl_FindHashEntry(icons, name);
  if (hPtr != NULL) {
    status_item = (QuartzStatusIcon *) Tcl_GetHashValue(hPtr);
  }

  if (!status_item) {
    Tcl_AppendResult (interp, "Invalid StatusIcon : " , name, (char *) NULL);
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;
  [status_item setAlternateImagePath:path];
  QUARTZ_POOL_RELEASE;

  return TCL_OK;
}

int Statusicon_SetTooltip(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  QuartzStatusIcon *status_item;
  Tcl_HashEntry *hPtr = NULL;
  char * name = NULL;
  char * tooltip = NULL;

  // We verify the arguments
  if( objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "icon tooltip");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);
  tooltip = Tcl_GetStringFromObj(objv[2], NULL);

  hPtr = Tcl_FindHashEntry(icons, name);
  if (hPtr != NULL) {
    status_item = (QuartzStatusIcon *) Tcl_GetHashValue(hPtr);
  }

  if (!status_item) {
    Tcl_AppendResult (interp, "Invalid StatusIcon : " , name, (char *) NULL);
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;
  [status_item setToolTip:tooltip];
  QUARTZ_POOL_RELEASE;

  return TCL_OK;
}

int Statusicon_SetTitle(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  QuartzStatusIcon *status_item;
  Tcl_HashEntry *hPtr = NULL;
  char * name = NULL;
  char * title = NULL;

  // We verify the arguments
  if( objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "icon title");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);
  title = Tcl_GetStringFromObj(objv[2], NULL);

  hPtr = Tcl_FindHashEntry(icons, name);
  if (hPtr != NULL) {
    status_item = (QuartzStatusIcon *) Tcl_GetHashValue(hPtr);
  }

  if (!status_item) {
    Tcl_AppendResult (interp, "Invalid StatusIcon : " , name, (char *) NULL);
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;
  [status_item setTitle:title];
  QUARTZ_POOL_RELEASE;

  return TCL_OK;
}

int Statusicon_SetHighlightMode(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  QuartzStatusIcon *status_item;
  Tcl_HashEntry *hPtr = NULL;
  char * name = NULL;
  int highlighted = 0;

  // We verify the arguments
  if( objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "icon highlightMode");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);
  if (Tcl_GetBooleanFromObj(interp, objv[2], &highlighted) != TCL_OK) 
    return TCL_ERROR;

  hPtr = Tcl_FindHashEntry(icons, name);
  if (hPtr != NULL) {
    status_item = (QuartzStatusIcon *) Tcl_GetHashValue(hPtr);
  }

  if (!status_item) {
    Tcl_AppendResult (interp, "Invalid StatusIcon : " , name, (char *) NULL);
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;
  [status_item setHighlightMode:highlighted];
  QUARTZ_POOL_RELEASE;


  return TCL_OK;
}
int Statusicon_SetVisible(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  QuartzStatusIcon *status_item;
  Tcl_HashEntry *hPtr = NULL;
  char * name = NULL;
  int visible = 0;

  // We verify the arguments
  if( objc != 3) {
    Tcl_WrongNumArgs(interp, 1, objv, "icon visible");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);
  if (Tcl_GetBooleanFromObj(interp, objv[2], &visible) != TCL_OK) 
    return TCL_ERROR;

  hPtr = Tcl_FindHashEntry(icons, name);
  if (hPtr != NULL) {
    status_item = (QuartzStatusIcon *) Tcl_GetHashValue(hPtr);
  }

  if (!status_item) {
    Tcl_AppendResult (interp, "Invalid StatusIcon : " , name, (char *) NULL);
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;
  [status_item setVisible:visible];
  QUARTZ_POOL_RELEASE;


  return TCL_OK;
}

int Statusicon_Destroy(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  QuartzStatusIcon *status_item;
  callback_s * callback = NULL;
  Tcl_HashEntry *hPtr = NULL;
  char * name = NULL;

  // We verify the arguments
  if( objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "icon");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);

  hPtr = Tcl_FindHashEntry(icons, name);
  if (hPtr != NULL) {
    status_item = (QuartzStatusIcon *) Tcl_GetHashValue(hPtr);
  }

  if (!status_item) {
    Tcl_AppendResult (interp, "Invalid StatusIcon : " , name, (char *) NULL);
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;
  [status_item release];
  QUARTZ_POOL_RELEASE;

  Tcl_DeleteHashEntry(hPtr);

  hPtr = Tcl_FindHashEntry(callbacks, name);
  if (hPtr != NULL) {
    callback = (callback_s *) Tcl_GetHashValue(hPtr);
  }

  if (callback) {
    Tcl_DecrRefCount(callback->cb);
    ckfree(callback);
    Tcl_DeleteHashEntry(hPtr);
  }

  return TCL_OK;
}

int Statusicon_Init(Tcl_Interp *interp)
{
  if (Tcl_InitStubs(interp, "8.4", 0) == NULL) {
    return TCL_ERROR;
  }

  NSApplicationLoad();
  
  icons = (Tcl_HashTable *) ckalloc(sizeof(Tcl_HashTable));
  Tcl_InitHashTable(icons, TCL_STRING_KEYS);

  callbacks = (Tcl_HashTable *) ckalloc(sizeof(Tcl_HashTable));
  Tcl_InitHashTable(callbacks, TCL_STRING_KEYS);

  Tcl_CreateObjCommand(interp, "::statusicon::create", Statusicon_Create, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::setImage", Statusicon_SetImage, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::setAlternateImage", Statusicon_SetAlternateImage, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::setTooltip", Statusicon_SetTooltip, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::setTitle", Statusicon_SetTitle, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::setHighlightMode", Statusicon_SetHighlightMode, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::setVisible", Statusicon_SetVisible, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::destroy", Statusicon_Destroy, NULL, NULL);
  

  return Tcl_PkgProvide(interp, "statusicon", "0.1");
}

int Statusicon_SafeInit(Tcl_Interp *interp)
{
  return Statusicon_Init(interp);
}
