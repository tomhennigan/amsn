/*
  File : tcl_siren.c

  Description :	Contains all functions for accessing the Siren7 library

  Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
*/


// Include the header file
#include "tcl_siren.h"

static int codec_counter = 0;
static Tcl_HashTable *Coders = NULL;


static int Siren_NewCodec (Tcl_Interp *interp, int objc, Tcl_Obj *CONST objv[], SirenCodecType type) {

	SirenCodecObject *new_codec;
	char name[15];
	char * req_name = NULL;
	int sample_rate = 16000;
	char *prefix;
	Tcl_HashEntry *hPtr = NULL;
	int newHash;
	static char encoder_prefix[] = "encoder";
	static char decoder_prefix[] = "decoder";


	// We verify the arguments
	if( objc > 3) {
		Tcl_WrongNumArgs(interp, 1, objv, "?sample_rate? ?name?");
		Tcl_AppendResult (interp, " where the sample_rate MUST be 16000 to be compatible with MSN Messenger", (char *) NULL);
		return TCL_ERROR;
	}


	if (objc > 1) {
		if (Tcl_GetIntFromObj(interp, objv[1], &sample_rate) != TCL_OK) {
			Tcl_ResetResult(interp);
			sample_rate = 16000;
		}
	} else {
		sample_rate = 16000;
	}

	new_codec = (SirenCodecObject *) malloc(sizeof(SirenCodecObject));
	new_codec->decoder = NULL;
	new_codec->encoder = NULL;
	new_codec->codecType = type;

	if ( type == SIREN_ENCODER) {
		prefix = encoder_prefix;
	} else if (type == SIREN_DECODER) {
		prefix = decoder_prefix;
	}

	if ( objc == 3) {
	  // Set the requested name and see if it exists...
	  req_name = Tcl_GetStringFromObj(objv[2], NULL);
	  if (Tcl_FindHashEntry(Coders, req_name) == NULL) {
	    strcpy(name, req_name);
	  }else {
	    sprintf(name, "%s%d", prefix, ++codec_counter);
	  }
	} else {
	  sprintf(name, "%s%d", prefix, ++codec_counter);
	}
		
	strcpy(new_codec->name, name);


	if ( type == SIREN_ENCODER) {
		new_codec->encoder = Siren7_NewEncoder(sample_rate);
	} else if (type == SIREN_DECODER) {
		new_codec->decoder = Siren7_NewDecoder(sample_rate);
	}

	hPtr = Tcl_CreateHashEntry(Coders, name, &newHash);
	Tcl_SetHashValue(hPtr, (ClientData) new_codec);

	Tcl_ResetResult(interp);
	Tcl_AppendResult(interp, name, NULL);

	return TCL_OK;
	
}



int Siren_NewEncoder _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[])) 
{
	return Siren_NewCodec(interp, objc, objv, SIREN_ENCODER);
}

int Siren_NewDecoder _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[])) 
{
	return Siren_NewCodec(interp, objc, objv, SIREN_DECODER);
}


int Siren_Encode _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[])) 
{
	char * name = NULL;
	SirenCodecObject * encoder;
	

	unsigned char * output = NULL;
	unsigned char * out_ptr = NULL;
	unsigned char* input = NULL;
	Tcl_HashEntry *hPtr = NULL;
	int length = 0;
	int dataSize;
	int processed = 0;

	// We verify the arguments
	if( objc != 3) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Siren::Encode encoder data\"" , (char *) NULL);
		return TCL_ERROR;
	} 

	name = Tcl_GetStringFromObj(objv[1], NULL);

	hPtr = Tcl_FindHashEntry(Coders, name);
	if (hPtr != NULL) {
	  encoder = (SirenCodecObject *) Tcl_GetHashValue(hPtr);
	}

	if (!encoder || encoder->codecType != SIREN_ENCODER) {
		Tcl_AppendResult (interp, "Invalid encoder : " , name, (char *) NULL);
		return TCL_ERROR;
	}

	input = Tcl_GetByteArrayFromObj(objv[2], &dataSize);

	output = (unsigned char *) malloc (dataSize / 16);
	out_ptr = output;
	processed = 0;
	while (processed + 640 <= dataSize) {
		if (Siren7_EncodeFrame(encoder->encoder, input + processed, out_ptr) != 0) {
			Tcl_AppendResult (interp, "Unexpected error Encoding data" , (char *) NULL);
			return TCL_ERROR;
		}
		out_ptr += 40;
		processed += 640;
	}

	Tcl_SetObjResult(interp, Tcl_NewByteArrayObj(output, out_ptr - output));
	free(output);

	
	return TCL_OK;
}


int Siren_Decode _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[])) 
{
	char * name = NULL;
	SirenCodecObject * decoder;
	

	unsigned char * output = NULL;
	unsigned char * out_ptr = NULL;
	unsigned char* input = NULL;
	Tcl_HashEntry *hPtr = NULL;
	int length = 0;
	int dataSize;
	int processed = 0;

	// We verify the arguments
	if( objc != 3) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Siren::Decode decoder data\"" , (char *) NULL);
		return TCL_ERROR;
	} 

	name = Tcl_GetStringFromObj(objv[1], NULL);

	hPtr = Tcl_FindHashEntry(Coders, name);
	if (hPtr != NULL) {
	  decoder = (SirenCodecObject *) Tcl_GetHashValue(hPtr);
	}

	if (!decoder || decoder->codecType != SIREN_DECODER) {
		Tcl_AppendResult (interp, "Invalid decoder : " , name, (char *) NULL);
		return TCL_ERROR;
	}

	input = Tcl_GetByteArrayFromObj(objv[2], &dataSize);

	output = (unsigned char *) malloc (dataSize * 16);
	out_ptr = output;
	processed = 0;
	while (processed + 40 <= dataSize) {
		if (Siren7_DecodeFrame(decoder->decoder, input + processed, out_ptr) != 0) {
			Tcl_AppendResult (interp, "Unexpected error Decoding data" , (char *) NULL);
			return TCL_ERROR;
		}
		out_ptr += 640;
		processed += 40;
	}

	Tcl_SetObjResult(interp, Tcl_NewByteArrayObj(output, out_ptr - output));
	free(output);
	
	return TCL_OK;
}


int Siren_Close _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[]))
{
	char * name = NULL;
	SirenCodecObject * codec;
	Tcl_HashEntry *hPtr = NULL;

	// We verify the arguments
	if( objc != 2) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Siren::Close encoder\"" , (char *) NULL);
		return TCL_ERROR;
	} 


	name = Tcl_GetStringFromObj(objv[1], NULL);

	hPtr = Tcl_FindHashEntry(Coders, name);
	if (hPtr != NULL) {
	  codec = (SirenCodecObject *) Tcl_GetHashValue(hPtr);
	}

	if (!codec) {
		Tcl_AppendResult (interp, "Invalid Siren codec : " , name, (char *) NULL);
		return TCL_ERROR;
	}

	if (codec->codecType == SIREN_ENCODER) {
		Siren7_CloseEncoder(codec->encoder);
	} else if (codec->codecType == SIREN_DECODER) {
		Siren7_CloseDecoder(codec->decoder);
	}

	Tcl_DeleteHashEntry(hPtr);

	free(codec);

	return TCL_OK;
	
}

int Siren_WriteWav _ANSI_ARGS_((ClientData clientData,
								Tcl_Interp *interp,
								int objc,
								Tcl_Obj *CONST objv[])) {

	char *filename = NULL;
	char * name = NULL;
	char *data = NULL;
	FILE * f = NULL;
	unsigned int dataSize;
	SirenCodecObject * codec;
	Tcl_HashEntry *hPtr = NULL;

	// We verify the arguments
	if( objc != 4) {
		Tcl_AppendResult (interp, "Wrong number of args.\nShould be \"::Siren::WriteWav codec filename data\"" , (char *) NULL);
		return TCL_ERROR;
	} 

	name = Tcl_GetStringFromObj(objv[1], NULL);

	hPtr = Tcl_FindHashEntry(Coders, name);
	if (hPtr != NULL) {
	  codec = (SirenCodecObject *) Tcl_GetHashValue(hPtr);
	}

	if (!codec) {
		Tcl_AppendResult (interp, "Invalid codec : " , name, (char *) NULL);
		return TCL_ERROR;
	}


	filename = Tcl_GetStringFromObj(objv[2], NULL);
	data = Tcl_GetByteArrayFromObj(objv[3], &dataSize);

	if (codec->codecType == SIREN_ENCODER) {
		if (dataSize != ME_FROM_LE32(codec->encoder->WavHeader.DataSize)) {
			Tcl_AppendResult (interp, "The data you provided does not correspond to this encoder instance" , (char *) NULL);
			return TCL_ERROR;
		}
	} else if (codec->codecType == SIREN_DECODER) {
		if (dataSize != ME_FROM_LE32(codec->decoder->WavHeader.DataSize)) {
			Tcl_AppendResult (interp, "The data you provided does not correspond to this decoder instance" , (char *) NULL);
			return TCL_ERROR;
		}
	}

	f = fopen(filename, "wb");

	if (f == NULL) {
		Tcl_AppendResult (interp, "Unable to open file <" , filename, ">", (char *) NULL);
		return TCL_ERROR;
	}

  	if (codec->codecType == SIREN_ENCODER) {
		fwrite(&(codec->encoder->WavHeader), sizeof(codec->encoder->WavHeader), 1, f);
	} else if (codec->codecType == SIREN_DECODER) {
		fwrite(&(codec->decoder->WavHeader), sizeof(codec->decoder->WavHeader), 1, f);
	}

	fwrite(data, 1, dataSize, f);
	fclose(f);


	return TCL_OK;
}

/*
  Function : Siren_Init

  Description :	The Init function that will be called when the extension is loaded to your tcl shell

  Arguments   :	Tcl_Interp *interp    :	This is the interpreter from which the load was made and to 
  which we'll add the new command


  Return value : TCL_OK in case everything is ok, or TCL_ERROR in case there is an error (Tk version < 8.3)

  Comments     : hummmm... not much, it's simple :)

*/
int Siren_Init (Tcl_Interp *interp ) {
	

  //Check Tcl version is 8.3 or higher
  if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
    return TCL_ERROR;
  }

  Coders = (Tcl_HashTable *) ckalloc(sizeof(Tcl_HashTable));
  Tcl_InitHashTable(Coders, TCL_STRING_KEYS);
   

  // Create the wrapping commands in the Webcamsn namespace linked to custom functions with a NULL clientdata and 
  // no deleteproc inside the current interpreter
  Tcl_CreateObjCommand(interp, "::Siren::NewEncoder", Siren_NewEncoder,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Siren::Encode", Siren_Encode,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Siren::NewDecoder", Siren_NewDecoder,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Siren::Decode", Siren_Decode,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Siren::Close", Siren_Close,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL); 
  Tcl_CreateObjCommand(interp, "::Siren::WriteWav", Siren_WriteWav,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL); 

  // end of Initialisation
  return TCL_OK;
}
int Siren_SafeInit (Tcl_Interp *interp) {
  return Siren_Init(interp);
}

int Tcl_siren_Init (Tcl_Interp *interp ) {
	return Siren_Init(interp);
}

int Tcl_siren_SafeInit (Tcl_Interp *interp) {
  return Tcl_siren_Init(interp);
}
