/*
 * hello.c -- A minimal Tcl C extension.
 */
#include <tcl.h>
#include <stdlib.h>
#include <string.h>

//TODO: Unix only??
#include <pthread.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>


int resolved_handler(ClientData clientData, Tcl_Interp *interp, int code);
void *resolver_thread(void*);

typedef struct {
	char *host;
	char *ip;
	char *cmd;
	Tcl_AsyncHandler async_handler;
	Tcl_Interp *interp;
} resolver_clientdata;


static int
Asyncresolve_Cmd(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	resolver_clientdata *clientData = malloc(sizeof(resolver_clientdata));
	pthread_t t;

	if (objc<3) {
		Tcl_SetObjResult(interp, Tcl_NewStringObj("Use: asyncresolve host resolved_cmd", -1));		
		return TCL_ERROR;
	}

	clientData->async_handler = Tcl_AsyncCreate(resolved_handler,clientData);
	clientData->ip = NULL;
	clientData->host = strdup(Tcl_GetString(objv[1]));
	clientData->cmd = strdup( Tcl_GetString(objv[2]));
	clientData->interp = interp;
	pthread_create(&t, NULL, resolver_thread, clientData);

	return TCL_OK;
}


void *resolver_thread(void *args) {

	resolver_clientdata *clientData = (resolver_clientdata*)args;
	
	struct addrinfo * result;
	char * ret;
	char ip[30];
	int error;

	error = getaddrinfo(clientData->host, NULL, NULL, &result);
	if (error == 0 && result != NULL) {

		/* TODO: Maybe a small mutex for inet_ntop static buffer? (non reentrant) */
		ret = inet_ntop (AF_INET,
			&((struct sockaddr_in *) result->ai_addr)->sin_addr,
			ip, INET_ADDRSTRLEN);
		if (ret != NULL) {
			clientData->ip = strdup(ip);
		}
		freeaddrinfo(result);
	}

	// Tell TCL async handler can be run
	Tcl_AsyncMark(clientData->async_handler);
	
	
	//~ struct hostent he;
	//~ struct hostent *host;
	//~ int err_nop;
	//~ char buf[1024];

	//~ resolver_clientdata *clientData = (resolver_clientdata*)args;

	//~ /* TODO: Control ERANGE error if buffer too small */
	//~ if(!gethostbyname_r(clientData->host, &he, buf, 1024, &host, &err_nop ) && host != NULL) {
		//~ /* TODO: Maybe a small mutex for inet_ntoa static buffer? (non reentrant) */
		//~ clientData->ip = strdup(inet_ntoa(*(struct in_addr*)host->h_addr_list[0]));
	//~ }

	//~ // Tell TCL async handler can be run
	//~ Tcl_AsyncMark(clientData->async_handler);
	
}


int resolved_handler(ClientData _clientData, Tcl_Interp *interp, int code) {

	int res;
	char buffer[1024];
	Tcl_DString oldResult;
	resolver_clientdata *clientData = (resolver_clientdata*)_clientData;

	snprintf(buffer,1024, "%s %s", clientData->cmd, clientData->ip != NULL ? clientData->ip : "");
	//printf(buffer);
	//printf("\n");
	
	/* TODO: if interp != NULL, save errorInfo and errorCode */
	if (interp != NULL) {
		Tcl_DStringInit(&oldResult);
		Tcl_DStringGetResult(interp, &oldResult);
	}

	res = Tcl_Eval(clientData->interp, buffer);
	if (res != TCL_OK) {
		Tcl_BackgroundError(clientData->interp);
	}

	free(clientData->cmd);
	free(clientData->host);
	if (clientData->ip = NULL) free(clientData->ip);
	free(clientData);

	/* TODO: If interp != NULL, restore errorInfo and errorCode */
	if (interp != NULL) {
		Tcl_DStringResult(interp, &oldResult);
		Tcl_DStringFree(&oldResult);
	}
	return code;
}


int DLLEXPORT
Asyncresolver_Init(Tcl_Interp *interp)
{
    if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
 	return TCL_ERROR;
    }
    /* changed this to check for an error - GPS */
    if (Tcl_PkgProvide(interp, "asyncresolver", "0.1") == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_CreateObjCommand(interp, "asyncresolve", Asyncresolve_Cmd, NULL, NULL);
    return TCL_OK;
 }
