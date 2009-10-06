
#include "statusicon.h"

#define QUARTZ_POOL_ALLOC NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]
#define QUARTZ_POOL_RELEASE [pool release]

static int icon_counter = 0;
static Tcl_HashTable *icons = NULL;

int Statusicon_Create(ClientData clientData, Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[])
{
  char name[15];
  Tcl_HashEntry *hPtr = NULL;
  int newHash;

  /* TODO: actually needs a callback here */
  if(objc != 1) {
    Tcl_WrongNumArgs(interp, 1, objv, "");
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;
  QuartzStatusIcon *status_item = [[QuartzStatusIcon alloc] initWithCallback:Statusicon_Callback];
  if (status_icon == NULL) {
    return TCL_ERROR;
  } else {
    sprintf(name, "statusicon%d", ++icon_counter);
    hPtr = Tcl_CreateHashEntry(icons, name, &newHash);
    Tcl_SetHashValue(hPtr, (ClientData) status_item);

    Tcl_ResetResult(interp);
    Tcl_AppendResult(interp, name, NULL);
  }
  QUARTZ_POOL_RELEASE;
	
  return TCL_OK;
}

void *Statusicon_Callback()
{
  /*TODO: this is fucked*/
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
  tooltipwpath = Tcl_GetStringFromObj(objv[2], NULL);

  hPtr = Tcl_FindHashEntry(icons, name);
  if (hPtr != NULL) {
    status_item = (QuartzStatusIcon *) Tcl_GetHashValue(hPtr);
  }

  if (!status_item) {
    Tcl_AppendResult (interp, "Invalid StatusIcon : " , name, (char *) NULL);
    return TCL_ERROR;
  }

  QUARTZ_POOL_ALLOC;
  [status_item setImage:path];
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
  [status_item setTooltip:tooltip];
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

  return TCL_OK;
}

int Statusicon_Init(Tcl_Interp *interp)
{
  if (Tcl_InitStubs(interp, "8.4", 0) == NULL) {
    return TCL_ERROR;
  }
  if (Tk_InitStubs(interp, "8.4", 0) == NULL) {
    return TCL_ERROR;
  }
  
  icons = (Tcl_HashTable *) ckalloc(sizeof(Tcl_HashTable));
  Tcl_InitHashTable(icons, TCL_STRING_KEYS);

  Tcl_CreateObjCommand(interp, "::statusicon::create", Statusicon_Create, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::setImage", Statusicon_SetImage, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::setTooltip", Statusicon_SetTooltip, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::setVisible", Statusicon_SetVisible, NULL, NULL);
  Tcl_CreateObjCommand(interp, "::statusicon::destroy", Statusicon_Destroy, NULL, NULL);
  

  return Tcl_PkgProvide(interp, "statusicon", "0.1");
}

int Statusicon_SafeInit(Tcl_Interp *interp)
{
  return Statusicon_Init(interp);
}
