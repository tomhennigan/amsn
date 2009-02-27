/*
  File : gupnp.c

  Description :	Contains all functions for accessing gupnp

  Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
*/


// Include the header file
#include "gupnp.h"

#include <libgupnp-igd/gupnp-simple-igd-thread.h>

static int _counter = 0;
static Tcl_HashTable *_igds = NULL;
Tcl_ThreadId main_tid = 0;

typedef struct {
  Tcl_Event header;
  Tcl_Interp *interp;
  gchar *proto;
  gchar *external_ip;
  gchar *replaces_external_ip;
  guint external_port;
  gchar *local_ip;
  guint local_port;
  gchar *description;
} GupnpMappedEvent;

int Gupnp_DummyCB _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  return TCL_OK;
}

static int Gupnp_MappedExternalPort (Tcl_Event *evPtr, int flags)
{
  GupnpMappedEvent *ev = (GupnpMappedEvent *) evPtr;
  Tcl_Obj *eval = Tcl_NewStringObj ("eval", -1);
  Tcl_Obj *callback = Tcl_NewStringObj ("::gupnp::MappedExternalPort", -1);
  Tcl_Obj *args = Tcl_NewListObj (0, NULL);
  Tcl_Obj *command[] = {eval, callback, args};
  Tcl_Interp *interp = ev->interp;


  Tcl_ListObjAppendElement(NULL, args, Tcl_NewStringObj(ev->proto, -1));
  Tcl_ListObjAppendElement(NULL, args, Tcl_NewStringObj(ev->external_ip, -1));
  Tcl_ListObjAppendElement(NULL, args, Tcl_NewStringObj(ev->replaces_external_ip, -1));
  Tcl_ListObjAppendElement(NULL, args, Tcl_NewIntObj (ev->external_port));
  Tcl_ListObjAppendElement(NULL, args, Tcl_NewStringObj(ev->local_ip, -1));
  Tcl_ListObjAppendElement(NULL, args, Tcl_NewIntObj (ev->local_port));
  Tcl_ListObjAppendElement(NULL, args, Tcl_NewStringObj(ev->description, -1));

  /* Take the callback here in case it gets Closed by the eval */
  Tcl_IncrRefCount (eval);
  Tcl_IncrRefCount (args);
  Tcl_IncrRefCount (callback);

  if (Tcl_EvalObjv(interp, 3, command, TCL_EVAL_GLOBAL) == TCL_ERROR) {
    g_debug("gupnp: Error executing callback : %s",
	    Tcl_GetStringResult(interp));
  }

  Tcl_DecrRefCount (callback);
  Tcl_DecrRefCount (args);
  Tcl_DecrRefCount (eval);

  g_free(ev->proto);
  g_free(ev->external_ip);
  g_free(ev->replaces_external_ip);
  g_free(ev->local_ip);
  g_free(ev->description);

  return 1;
}


static void
_upnp_mapped_external_port (GUPnPSimpleIgdThread *igd, gchar *proto,
    gchar *external_ip, gchar *replaces_external_ip, guint external_port,
    gchar *local_ip, guint local_port, gchar *description, gpointer user_data)
{
  Tcl_Interp *interp = (Tcl_Interp *) user_data;

  GupnpMappedEvent *evPtr;

  evPtr = (GupnpMappedEvent *)ckalloc(sizeof(GupnpMappedEvent));
  evPtr->header.proc = Gupnp_MappedExternalPort;
  evPtr->header.nextPtr = NULL;
  evPtr->interp = interp;
  evPtr->proto = g_strdup (proto);
  evPtr->external_ip = g_strdup (external_ip);
  evPtr->replaces_external_ip = g_strdup (replaces_external_ip);
  evPtr->external_port = external_port;
  evPtr->local_ip = g_strdup (local_ip);
  evPtr->local_port = local_port;
  evPtr->description = g_strdup (description);

  Tcl_ThreadQueueEvent(main_tid, (Tcl_Event *)evPtr, TCL_QUEUE_TAIL);
  Tcl_ThreadAlert(main_tid);
}



int Gupnp_New _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  GUPnPSimpleIgdThread *igd = NULL;
  char * name = NULL;
  Tcl_HashEntry *hPtr = NULL;
  int newHash;

  // We verify the arguments
  if( objc > 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "?name?");
    return TCL_ERROR;
  }

  if ( objc == 2) {
    // Set the requested name and see if it exists...
    name = Tcl_GetStringFromObj(objv[2], NULL);
    if (Tcl_FindHashEntry(_igds, name) == NULL) {
      name = g_strdup(name);
    } else {
      Tcl_AppendResult (interp, name, " already exists", (char *) NULL);
      return TCL_ERROR;
    }
  } else {
    name = g_strdup_printf("gupnp%d", ++_counter);
  }
  igd = gupnp_simple_igd_thread_new ();

  if (igd == NULL) {
    Tcl_AppendResult (interp, "Error creating the upnp object", (char *) NULL);
    return TCL_ERROR;    
  }

  g_signal_connect (igd, "mapped-external-port",
            G_CALLBACK (_upnp_mapped_external_port), interp);
  
  hPtr = Tcl_CreateHashEntry(_igds, name, &newHash);
  Tcl_SetHashValue(hPtr, (ClientData) igd);

  Tcl_ResetResult(interp);
  Tcl_AppendResult(interp, name, NULL);

  g_free(name);

  return TCL_OK;
}


int Gupnp_AddPort _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  char * name = NULL;
  GUPnPSimpleIgdThread * igd = NULL;
  Tcl_HashEntry *hPtr = NULL;
  char *transport = NULL;
  char *ip = NULL;
  int internal_port;
  int external_port;
  int lease_timeout;
  char *description = NULL;

  // We verify the arguments
  if( objc != 8) {
    Tcl_WrongNumArgs(interp, 1, objv, "name transport ip internal_port "
		     "external_port lease_timeout description");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);

  hPtr = Tcl_FindHashEntry(_igds, name);
  if (hPtr != NULL) {
    igd = GUPNP_SIMPLE_IGD (Tcl_GetHashValue(hPtr));
  }

  if (!igd) {
    Tcl_AppendResult (interp, name, " does not exist", (char *) NULL);
    return TCL_ERROR;
  }

  transport = Tcl_GetStringFromObj(objv[2], NULL);
  if (strcmp(transport, "UDP") != 0 && strcmp(transport, "TCP") != 0) {
    Tcl_AppendResult (interp, "invalid transport '", transport, "'. Must be ",
		      "'TCP' or 'UDP'", (char *) NULL);
    return TCL_ERROR;
  }
  ip = Tcl_GetStringFromObj(objv[3], NULL);
  if (Tcl_GetIntFromObj(interp, objv[4], &internal_port) != TCL_OK) {
    return TCL_ERROR;
  }
  if (Tcl_GetIntFromObj(interp, objv[5], &external_port) != TCL_OK) {
    return TCL_ERROR;
  }
  if (Tcl_GetIntFromObj(interp, objv[6], &lease_timeout) != TCL_OK) {
    return TCL_ERROR;
  }
  description = Tcl_GetStringFromObj(objv[7], NULL);

  gupnp_simple_igd_add_port (igd, transport, internal_port, ip, external_port,
			     lease_timeout, description);

  return TCL_OK;
}

int Gupnp_RemovePort _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  char * name = NULL;
  GUPnPSimpleIgdThread * igd;
  Tcl_HashEntry *hPtr = NULL;
  char *transport = NULL;
  int external_port;


  // We verify the arguments
  if( objc != 4) {
    Tcl_WrongNumArgs(interp, 1, objv, "name transport external_port");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);

  hPtr = Tcl_FindHashEntry(_igds, name);
  if (hPtr != NULL) {
    igd = GUPNP_SIMPLE_IGD (Tcl_GetHashValue(hPtr));
  }

  if (!igd) {
    Tcl_AppendResult (interp, name, " does not exist", (char *) NULL);
    return TCL_ERROR;
  }

  transport = Tcl_GetStringFromObj(objv[2], NULL);
  if (strcmp(transport, "UDP") != 0 && strcmp(transport, "TCP") != 0) {
    Tcl_AppendResult (interp, "invalid transport '", transport, "'. Must be ",
		      "'TCP' or 'UDP'", (char *) NULL);
    return TCL_ERROR;
  }
  if (Tcl_GetIntFromObj(interp, objv[3], &external_port) != TCL_OK) {
    return TCL_ERROR;
  }

  gupnp_simple_igd_remove_port (igd, transport, external_port);

  return TCL_OK;
}

int Gupnp_Free _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  char * name = NULL;
  GUPnPSimpleIgdThread * igd;
  Tcl_HashEntry *hPtr = NULL;

  // We verify the arguments
  if( objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "name");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);

  hPtr = Tcl_FindHashEntry(_igds, name);
  if (hPtr != NULL) {
    igd = (GUPnPSimpleIgdThread *) Tcl_GetHashValue(hPtr);
  }

  if (!igd) {
    Tcl_AppendResult (interp, name, " does not exist", (char *) NULL);
    return TCL_ERROR;
  }

  g_object_unref (igd);

  Tcl_DeleteHashEntry(hPtr);

  return TCL_OK;
}

/*
  Function : Gupnp_Init

  Description :	The Init function that will be called when the extension
  is loaded to your tcl shell

*/
int Gupnp_Init (Tcl_Interp *interp) {

  //Check Tcl version is 8.3 or higher
  if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
    return TCL_ERROR;
  }

  g_type_init();
  if (!g_thread_supported ())
    g_thread_init (NULL);

  main_tid = Tcl_GetCurrentThread();

  _igds = (Tcl_HashTable *) ckalloc(sizeof(Tcl_HashTable));
  Tcl_InitHashTable(_igds, TCL_STRING_KEYS);

  // Create the wrapping commands in the gupnp namespace
  Tcl_CreateObjCommand(interp, "::gupnp::New", Gupnp_New,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::gupnp::AddPort", Gupnp_AddPort,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::gupnp::RemovePort", Gupnp_RemovePort,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::gupnp::Free", Gupnp_Free,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::gupnp::MappedExternalPort", Gupnp_DummyCB,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

  // end of Initialisation
  return TCL_OK;
}

int Gupnp_SafeInit (Tcl_Interp *interp) {
  return Gupnp_Init(interp);
}
