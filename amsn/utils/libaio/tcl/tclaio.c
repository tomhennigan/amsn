/*
  File : aio.c

  Description :	Contains all functions for accessing the libao/libai library

  Authors : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
  	    Bencheraiet Mohamed abderaouf (kenshin kenshin@cerberus.endoftheinternet.org)
*/


// Include the header file
#include "tclaio.h"
extern int aio_verbosity;
Tcl_HashTable  *devices = NULL;

typedef struct {
    const char *name;
    const int format;
} fmt_table;



fmt_table af_fmtstr_table[] = {
    { "mulaw", AF_FORMAT_MU_LAW },
    { "alaw", AF_FORMAT_A_LAW },
    { "mpeg2", AF_FORMAT_MPEG2 },
    { "ac3", AF_FORMAT_AC3 },
    { "imaadpcm", AF_FORMAT_IMA_ADPCM },

    { "u8", AF_FORMAT_U8 },
    { "s8", AF_FORMAT_S8 },
    { "u16le", AF_FORMAT_U16_LE },
    { "u16be", AF_FORMAT_U16_BE },
    { "u16ne", AF_FORMAT_U16_NE },
    { "s16le", AF_FORMAT_S16_LE },
    { "s16be", AF_FORMAT_S16_BE },
    { "s16ne", AF_FORMAT_S16_NE },
    { "u24le", AF_FORMAT_U24_LE },
    { "u24be", AF_FORMAT_U24_BE },
    { "u24ne", AF_FORMAT_U24_NE },
    { "s24le", AF_FORMAT_S24_LE },
    { "s24be", AF_FORMAT_S24_BE },
    { "s24ne", AF_FORMAT_S24_NE },
    { "u32le", AF_FORMAT_U32_LE },
    { "u32be", AF_FORMAT_U32_BE },
    { "u32ne", AF_FORMAT_U32_NE },
    { "s32le", AF_FORMAT_S32_LE },
    { "s32be", AF_FORMAT_S32_BE },
    { "s32ne", AF_FORMAT_S32_NE },
    { "floatle", AF_FORMAT_FLOAT_LE },
    { "floatbe", AF_FORMAT_FLOAT_BE },
    { "floatne", AF_FORMAT_FLOAT_NE },
        
    { NULL, 0 }
};

static int _str2fmt(char *fmt){
	int i = 0;
	while (af_fmtstr_table[i].name != NULL){
		if(strcmp(af_fmtstr_table[i].name,fmt) == 0)
			return af_fmtstr_table[i].format;
		i++;
	}
	return -1;


}

static aio_device_t * _get_device(Tcl_Interp *interp, Tcl_Obj *objv)
{
  char * name = NULL;
  aio_device_t *device = NULL;
  Tcl_HashEntry *hPtr = NULL;

  name = Tcl_GetStringFromObj(objv, NULL);

  hPtr = Tcl_FindHashEntry(devices, name);
  if (hPtr != NULL) {
    device = (aio_device_t *) Tcl_GetHashValue(hPtr);
  }

  if (!device) {
    Tcl_AppendResult (interp, "Invalid device : " , name, (char *) NULL);
    return NULL;
  }

  return device;
}


int Aio_Open  _ANSI_ARGS_((ClientData clientData,
			   Tcl_Interp *interp,
			   int objc,
			   Tcl_Obj *CONST objv[])) 
{
  int driver;
  aio_device_t *device = NULL;
  aio_sample_format_t s_format;
  char *name=NULL;
  char def_name[15];
  char *req_name = NULL;
  static const char device_prefix[] = "device";
  static int device_counter = 0;
  static char *prefs[] = {"oss", "alsa", NULL};

  char *fmt;
  int format = AF_FORMAT_S16_NE;
  int channels = 2;
  int rate = 16000;
  char *prefered_driver = NULL;
  char *str_mode = NULL;
  int open_mode = 0 ;
  Tcl_HashEntry *hPtr = NULL;
  int newHash;

  Tcl_Obj *CONST *objPtr;
  int index;
  static CONST char *switches[] = {"-fmt", "-channels",
				   "-rate", "-format",
				   "-driver", (char *) NULL};

  enum command { COMMAND_FMT, COMMAND_CHANNELS, COMMAND_RATE,
		 COMMAND_FORMAT, COMMAND_DRIVER};

	if(objc < 2) {
		Tcl_WrongNumArgs(interp,1,objv,"mode");
		return TCL_ERROR;
	}
	
	str_mode = Tcl_GetStringFromObj(objv[1],NULL);
	
	if(strcmp(str_mode,"rec") == 0 ){
		open_mode = AIO_RECONLY;
	}else if(strcmp(str_mode,"play") == 0){
		open_mode = AIO_PLAYONLY;
	}else if(strcmp(str_mode,"recplay")==0){
		open_mode = AIO_RECPLAY;
	}else{
		Tcl_AppendResult(interp,"inavlide open mode",(char*)NULL);
		return  TCL_ERROR;
	}

  objPtr = objv + 2;
  objc -= 2;


  while (objc > 1) {
    if (Tcl_GetIndexFromObj(interp, objPtr[0], switches,
			    "switch", 0, &index) != TCL_OK) {
      return TCL_ERROR;
    }
    switch (index) {
    case COMMAND_FMT:		/* -fmt */
      fmt = Tcl_GetStringFromObj(objPtr[1],  NULL);
	printf("%s\n",fmt);
      
      if ((format = _str2fmt(fmt)) == -1){
       Tcl_AppendResult(interp, "Invalid format ", fmt, (char *)NULL);

      
      	return TCL_ERROR;
      }
      break;
    case COMMAND_CHANNELS:		/* -channels */
      if (Tcl_GetIntFromObj(interp, objPtr[1],
			    &channels) != TCL_OK) {
	return TCL_ERROR;
      }
      break;
    case COMMAND_RATE:		/* -rate */
      if (Tcl_GetIntFromObj(interp, objPtr[1],
			    &rate) != TCL_OK) {
	return TCL_ERROR;
      }
      break;
    case COMMAND_DRIVER:		/* -driver */
      prefered_driver = Tcl_GetStringFromObj(objPtr[1], NULL);
      break;
    }
    objPtr += 2;
    objc -= 2;
  }
  
  // We verify the arguments
  if( objc > 1) {
    Tcl_WrongNumArgs(interp, 1, objv, "?options? ?name?");
    return TCL_ERROR;
  }

  if ( objc == 1) {
    // Set the requested name and see if it exists...
    req_name = Tcl_GetStringFromObj(objPtr[0], NULL);
    if (Tcl_FindHashEntry(devices, req_name) == NULL) {
      name = req_name;
    } else {
      Tcl_AppendResult(interp, "Device name '", req_name,
		       "' already exists", (char *)NULL);
    }
  } else {
    /* In case someone created a device with a futurely generated name */
    do {
      sprintf(def_name, "%s%d", device_prefix, ++device_counter);
    } while(Tcl_FindHashEntry(devices, def_name) != NULL);
    name = def_name;
  }

  if (prefered_driver) {
    driver = aio_driver_id(prefered_driver);
    if (driver == -1) {
      Tcl_AppendResult(interp, "Driver '", prefered_driver, "' is invalid", 
		       (char *)NULL);
      return TCL_ERROR;
    }
  } else {
    driver = aio_default_driver_id(prefs);
  }

  s_format.channels = channels;
  s_format.samplerate = rate;
  s_format.format = format;
	
  /* -- Open driver -- */
  device = aio_open(driver, &s_format, NULL /* no options */, open_mode);

  if (device == NULL) {
    Tcl_AppendResult(interp, "Unable to open device", NULL);
    return TCL_ERROR;
  }

  hPtr = Tcl_CreateHashEntry(devices, name, &newHash);
  Tcl_SetHashValue(hPtr, (ClientData) device);

  Tcl_ResetResult(interp);
  Tcl_AppendResult(interp, name, NULL);

  return TCL_OK;
}


int Aio_Play _ANSI_ARGS_((ClientData clientData,
			  Tcl_Interp *interp,
			  int objc,
			  Tcl_Obj *CONST objv[])) 
{
  aio_device_t *device = NULL;
  unsigned char* input = NULL;
  int dataSize;
  int final = 0;
  char *final_opt = NULL;

  // We verify the arguments
  if(objc < 3 || objc > 4) {
    Tcl_WrongNumArgs(interp, 1, objv, "name ?-final? data");
    return TCL_ERROR;
  }

  device = _get_device(interp, objv[1]);

  if (!device) {
    return TCL_ERROR;
  }

  if (objc == 3) {
    input = Tcl_GetByteArrayFromObj(objv[2], &dataSize);    
  } else {
    final_opt = Tcl_GetStringFromObj(objv[2], NULL);
    if (strcmp(final_opt, "-final") != 0) {
      Tcl_AppendResult(interp, "Invalid option '", final_opt,
		       "'. Must be : -final", (char *)NULL);
      return TCL_ERROR;
    }
    final = AIOPLAY_FINAL_CHUNK;
    input = Tcl_GetByteArrayFromObj(objv[3], &dataSize);    
  }

  Tcl_SetObjResult(interp,
		   Tcl_NewIntObj(aio_play(device,
					  (int8_t *) input, dataSize, final)));

  return TCL_OK;
}
int Aio_Record _ANSI_ARGS_((ClientData clientData,
			  Tcl_Interp *interp,
			  int objc,
			  Tcl_Obj *CONST objv[])) 
{
	aio_device_t *device = NULL;
	int8_t * output =NULL;
	int dataSize;
	int err = 0;
	// We verify the arguments
	if(objc < 2  ) {
	Tcl_WrongNumArgs(interp, 1, objv, "name count");
		return TCL_ERROR;
	}

	device = _get_device(interp, objv[1]);
	
	if (!device) {
		return TCL_ERROR;
	}
	
	if(Tcl_GetIntFromObj(interp,objv[2],&dataSize) == TCL_ERROR){
		Tcl_AppendResult(interp, "Invalid option '", "count must be an integer", (char *)NULL);

		return TCL_ERROR;
	}
	/*ensure a larg enough buffer*/

	if(dataSize < 4096)
		dataSize = 4096;

	output = (int8_t*)Tcl_Alloc(dataSize * 2);
	
	if(output  == NULL){
		
		return TCL_ERROR;

	}
	err = aio_record(device,output, dataSize,0);

	if(err < 0){
		Tcl_AppendResult(interp,"An error has occured in record",(char* )NULL);
		return TCL_ERROR;

	}	

	Tcl_SetObjResult (interp ,Tcl_NewByteArrayObj((unsigned char *)output, dataSize));
	Tcl_Free((char* )output);


  return TCL_OK;
}



int Aio_GetDelay _ANSI_ARGS_((ClientData clientData,
			  Tcl_Interp *interp,
			  int objc,
			  Tcl_Obj *CONST objv[])) 
{
  aio_device_t *device = NULL;

  // We verify the arguments
  if( objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "name");
    return TCL_ERROR;
  }

  device = _get_device(interp, objv[1]);

  if (!device) {
    return TCL_ERROR;
  }


  Tcl_SetObjResult(interp,
		   Tcl_NewDoubleObj(aio_getdelay(device)));

  return TCL_OK;
}



int Aio_GetSpace _ANSI_ARGS_((ClientData clientData,
			  Tcl_Interp *interp,
			  int objc,
			  Tcl_Obj *CONST objv[])) 
{
  aio_device_t *device = NULL;

  // We verify the arguments
  if( objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "name");
    return TCL_ERROR;
  }

  device = _get_device(interp, objv[1]);

  if (!device) {
    return TCL_ERROR;
  }

  Tcl_SetObjResult(interp,
		   Tcl_NewIntObj(aio_getspace(device, AIO_SPACE_OUT)));
  return TCL_OK;
}



int Aio_Close _ANSI_ARGS_((ClientData clientData,
			   Tcl_Interp *interp,
			   int objc,
			   Tcl_Obj *CONST objv[]))
{
  char * name = NULL;
  aio_device_t *device = NULL;
  Tcl_HashEntry *hPtr = NULL;
 
  // We verify the arguments
  if ( objc != 2) {
    Tcl_WrongNumArgs(interp, 1, objv, "name");
    return TCL_ERROR;
  } 

  name = Tcl_GetStringFromObj(objv[1], NULL);

  hPtr = Tcl_FindHashEntry(devices, name);
  if (hPtr != NULL) {
    device = (aio_device_t *) Tcl_GetHashValue(hPtr);
  }

  if (!device) {
    Tcl_AppendResult (interp, "Invalid device : " , name, (char *) NULL);
    return TCL_ERROR;
  }

  aio_close(device, AIO_IMMED_LATER);
	
  Tcl_DeleteHashEntry(hPtr);

  return TCL_OK;
}

int Aio_Init (Tcl_Interp *interp ) {
  //Check Tcl version is 8.3 or higher
  if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
    return TCL_ERROR;
  }

  aio_initialize();
  aio_verbosity = AIO_VERBOSITY_DEBUG;

  devices = (Tcl_HashTable *) ckalloc(sizeof(Tcl_HashTable));
  Tcl_InitHashTable(devices, TCL_STRING_KEYS);

  // Create the wrapping commands in the Aio namespace
  Tcl_CreateObjCommand(interp, "::Aio::Open", Aio_Open,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Aio::Play", Aio_Play,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Aio::Record", Aio_Record,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Aio::Close", Aio_Close,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL); 
  Tcl_CreateObjCommand(interp, "::Aio::GetSpace", Aio_GetSpace,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL); 
  Tcl_CreateObjCommand(interp, "::Aio::GetDelay", Aio_GetDelay,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL); 


  Tcl_PkgProvide(interp, "Aio", "0.1");

  // end of Initialisation
  return TCL_OK;
}

int Aio_SafeInit (Tcl_Interp *interp) {
  int res = Aio_Init(interp);
  if (res == TCL_OK)
    Tcl_PkgProvide(interp, "Aio", "0.1");
  return res;
}

int Tclaio_Init(Tcl_Interp *interp){
  int res = Aio_Init(interp);
  if (res == TCL_OK)
    Tcl_PkgProvide(interp, "Tclaio", "0.1");
  return res;
}

int Tclaio_SafeInit(Tcl_Interp *interp){
  int res = Aio_Init(interp);
  if (res == TCL_OK)
    Tcl_PkgProvide(interp, "Tclaio", "0.1");
  return res;
}
