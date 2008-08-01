/*
  File : tcl_farishgt.c

  Description :	Contains all functions for accessing farsight 2

  Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
*/


// Include the header file
#include "tcl_farsight.h"

#include <string.h>

#include <gst/gst.h>
#include <gst/farsight/fs-conference-iface.h>
#include <gst/farsight/fs-stream-transmitter.h>

#ifdef G_OS_WIN32
#include <winsock2.h>
#include <Wspiapi.h>
#endif

#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>


GstElement *pipeline = NULL;
GstElement *conference = NULL;
FsSession *session = NULL;
FsParticipant *participant = NULL;
FsStream *stream = NULL;
gboolean candidates_prepared = FALSE;
gboolean codecs_ready = FALSE;
Tcl_Obj *local_candidates = NULL;
Tcl_Obj *callback = NULL;
Tcl_Interp *callback_interp = NULL;
Tcl_ThreadId main_tid = 0;


static char *host2ip(char *hostname)
{
    struct addrinfo * result;
    static char ip[30];
    char * ret;
    int error;

    error = getaddrinfo(hostname, NULL, NULL, &result);
    if (error != 0) {
      return NULL;
    }

    if (result) {
      ret = inet_ntop (AF_INET,
          &((struct sockaddr_in *) result->ai_addr)->sin_addr,
          ip, INET_ADDRSTRLEN);
      freeaddrinfo (result);
      if (ret == NULL) {
        return NULL;
      }
    }

    return ip;
}


static void Close ()
{
  if (stream) {
    g_object_unref (stream);
    stream = NULL;
  }

  if (participant) {
    g_object_unref (participant);
    participant = NULL;
  }

  if (session) {
    g_object_unref (session);
    session = NULL;
  }

  if (pipeline) {
    gst_element_set_state (pipeline, GST_STATE_NULL);
    gst_object_unref (pipeline);
    pipeline = NULL;
  }

  candidates_prepared = FALSE;
  codecs_ready = FALSE;

  if (local_candidates) {
    Tcl_DecrRefCount(local_candidates);
    local_candidates = NULL;
  }

  if (callback) {
    Tcl_DecrRefCount (callback);
    callback = NULL;
    callback_interp = NULL;
  }

}


static void
_notify_error (char *error)
{

  Tcl_Obj *status = Tcl_NewStringObj ("ERROR", -1);
  Tcl_Obj *eval = Tcl_NewStringObj ("eval", -1);
  Tcl_Obj *error_obj = Tcl_NewStringObj (error, -1);
  Tcl_Obj *args = Tcl_NewListObj (0, NULL);
  Tcl_Obj *command[] = {eval, callback, args};

  g_debug ("An error occured : %s", error);

  Tcl_ListObjAppendElement(NULL, args, status);
  Tcl_ListObjAppendElement(NULL, args, error_obj);
  Tcl_ListObjAppendElement(NULL, args, error_obj);

  if (callback && callback_interp) {
    Tcl_Obj *c = callback;
    Tcl_Obj *i = callback_interp;
    Tcl_IncrRefCount (eval);
    Tcl_IncrRefCount (args);
    Tcl_IncrRefCount (c);

    g_debug ("Calling error handler %s ", Tcl_GetString (callback));
    if (Tcl_EvalObjv(callback_interp, 3, command, TCL_EVAL_GLOBAL)
        == TCL_ERROR) {
      g_debug ("Error executing error handler %s : %s", Tcl_GetString (c),
          Tcl_GetStringResult(i));
    }
    g_debug ("Called error handler %s : %s", Tcl_GetString (c),
        Tcl_GetStringResult(i));
    Tcl_DecrRefCount (c);
    Tcl_DecrRefCount (args);
    Tcl_DecrRefCount (eval);
  }

  Close ();
}


typedef struct {
  Tcl_Event header;
  char *error;
} FarsightErrorEvent;

static int Farsight_ErrorEventProc (Tcl_Event *evPtr, int flags)
{
  FarsightErrorEvent *ev = (FarsightErrorEvent *) evPtr;
  char *error = ev->error;

  _notify_error (error);

  return 1;
}


static void
_notify_error_post (char *error)
{
  FarsightErrorEvent *evPtr;

  evPtr = (FarsightErrorEvent *)ckalloc(sizeof(FarsightErrorEvent));
  evPtr->header.proc = Farsight_ErrorEventProc;
  evPtr->header.nextPtr = NULL;
  evPtr->error = error;

  Tcl_ThreadQueueEvent(main_tid, (Tcl_Event *)evPtr, TCL_QUEUE_TAIL);
  Tcl_ThreadAlert(main_tid);

}


static void
_notify_callback ()
{

  if (codecs_ready && candidates_prepared) {
    Tcl_Obj *local_codecs = Tcl_NewListObj (0, NULL);
    Tcl_Obj *eval = Tcl_NewStringObj ("eval", -1);
    Tcl_Obj *prepared = Tcl_NewStringObj ("PREPARED", -1);
    Tcl_Obj *args = Tcl_NewListObj (0, NULL);
    Tcl_Obj *command[] = {eval, callback, args};

    GList *codecs = NULL;
    GList *item = NULL;

    g_object_get (session, "codecs", &codecs, NULL);

    for (item = g_list_first (codecs); item; item = g_list_next (item))
    {
      FsCodec *codec = item->data;
      Tcl_Obj *tcl_codec = NULL;
      Tcl_Obj *elements[3];
      elements[0] = Tcl_NewStringObj (codec->encoding_name, -1);
      elements[1] = Tcl_NewIntObj (codec->id);
      elements[2] = Tcl_NewIntObj (codec->clock_rate);

      tcl_codec = Tcl_NewListObj (3, elements);
      Tcl_ListObjAppendElement(NULL, local_codecs, tcl_codec);
    }

    fs_codec_list_destroy (codecs);

    Tcl_ListObjAppendElement(NULL, args, prepared);
    Tcl_ListObjAppendElement(NULL, args, local_codecs);
    Tcl_ListObjAppendElement(NULL, args, local_candidates);

    Tcl_IncrRefCount (eval);
    Tcl_IncrRefCount (args);
    Tcl_IncrRefCount (callback);
    Tcl_Obj *c = callback;
    Tcl_Obj *i = callback_interp;

    g_debug ("Calling notify handler %s ", Tcl_GetString (callback));
    if (Tcl_EvalObjv(callback_interp, 3, command, TCL_EVAL_GLOBAL)
        == TCL_ERROR) {
      g_debug ("Error executing notifier handler %s : %s", Tcl_GetString (callback),
          Tcl_GetStringResult(callback_interp));
    }
    g_debug ("Called notify handler %s : %s", Tcl_GetString (c),
          Tcl_GetStringResult(i));

    Tcl_DecrRefCount (c);
    Tcl_DecrRefCount (args);
    Tcl_DecrRefCount (eval);

  }
}

static void
_new_local_candidate (FsStream *stream, FsCandidate *candidate)
{

  if (local_candidates == NULL) {
    local_candidates = Tcl_NewListObj (0, NULL);
    Tcl_IncrRefCount(local_candidates);
  }
  Tcl_Obj *tcl_candidate = NULL;
  Tcl_Obj *elements[7];
  elements[0] = Tcl_NewStringObj (candidate->username == NULL ?
      "" : candidate->username, -1);
  elements[1] = Tcl_NewIntObj (candidate->component_id);
  elements[2] = Tcl_NewStringObj (candidate->password == NULL ?
      "" : candidate->password, -1);
  elements[3] = Tcl_NewStringObj (candidate->proto == FS_NETWORK_PROTOCOL_UDP ?
      "UDP" : "TCP", -1);
  elements[4] = Tcl_NewDoubleObj ((gfloat) candidate->priority / 1000);
  elements[5] = Tcl_NewStringObj (candidate->ip, -1);
  elements[6] = Tcl_NewIntObj (candidate->port);

  tcl_candidate = Tcl_NewListObj (7, elements);

  Tcl_ListObjAppendElement(NULL, local_candidates, tcl_candidate);

}

static void
_local_candidates_prepared (FsStream *stream)
{

  candidates_prepared = TRUE;

  g_debug ("CANDIDATES ARE PREPARED");
  _notify_callback ();
}



static void
_sink_element_added (GstBin *bin, GstElement *sink, gpointer user_data)
{

  g_object_set (sink, "sync", FALSE, NULL);
}


static void
_src_pad_added (FsStream *self, GstPad *pad, FsCodec *codec, gpointer user_data)
{
  GstElement *pipeline = user_data;
  GstElement *sink = gst_element_factory_make ("autoaudiosink", NULL);
  GstElement *convert = gst_element_factory_make ("audioconvert", NULL);
  GstElement *resample = gst_element_factory_make ("audioresample", NULL);
  GstElement *convert2 = gst_element_factory_make ("audioconvert", NULL);
  GstPad *sink_pad = NULL;
  GstPadLinkReturn ret;

  if (sink == NULL) {
    _notify_error_post ("Could not create sink");
    return;
  }

  g_signal_connect (sink, "element-added",
      G_CALLBACK (_sink_element_added), NULL);

  if (gst_bin_add (GST_BIN (pipeline), sink) == FALSE)  {
    _notify_error_post ("Could not add sink to pipeline");
    return;
  }

  if (gst_bin_add (GST_BIN (pipeline), convert) == FALSE) {
    _notify_error_post ("Could not add converter to pipeline");
    return;
  }
  if (gst_bin_add (GST_BIN (pipeline), resample) == FALSE) {
    _notify_error_post ("Could not add resampler to pipeline");
    return;
  }
  if (gst_bin_add (GST_BIN (pipeline), convert2) == FALSE) {
    _notify_error_post ("Could not add second converter to pipeline");
    return;
  }

  sink_pad = gst_element_get_static_pad (convert, "sink");
  ret = gst_pad_link (pad, sink_pad);
  gst_object_unref (sink_pad);

  if (ret != GST_PAD_LINK_OK)  {
    _notify_error_post ("Could not link converter to fsrtpconference sink pad");
    return;
  }

  if (gst_element_link(convert, resample) == FALSE)  {
    _notify_error_post ("Could not link converter to resampler");
    return;
  }
  if (gst_element_link(resample, convert2) == FALSE)  {
    _notify_error_post ("Could not link resampler to second converter");
    return;
  }
  if (gst_element_link(convert2, sink) == FALSE)  {
    _notify_error_post ("Could not link sink to converter");
    return;
  }

  if (gst_element_set_state (convert, GST_STATE_PLAYING) ==
      GST_STATE_CHANGE_FAILURE) {
    _notify_error_post ("Unable to set converter to PLAYING");
    return;
  }

  if (gst_element_set_state (resample, GST_STATE_PLAYING) ==
      GST_STATE_CHANGE_FAILURE) {
    _notify_error_post ("Unable to set resampler to PLAYING");
    return;
  }

  if (gst_element_set_state (convert2, GST_STATE_PLAYING) ==
      GST_STATE_CHANGE_FAILURE) {
    _notify_error_post ("Unable to set second converter to PLAYING");
    return;
  }

  if (gst_element_set_state (sink, GST_STATE_PLAYING) ==
      GST_STATE_CHANGE_FAILURE) {
    _notify_error_post ("Unable to set sink to PLAYING");
    return;
  }

}

static void
_codecs_ready (FsSession *session)
{
  codecs_ready = TRUE;

  g_debug ("CODECS ARE READY");

  _notify_callback ();
}

typedef struct {
  Tcl_Event header;
  GstMessage *message;
} FarsightBusEvent;

static int Farsight_BusEventProc (Tcl_Event *evPtr, int flags)
{
  FarsightBusEvent *ev = (FarsightBusEvent *) evPtr;
  GstMessage *message = ev->message;


  g_debug ("Receive bus message from the event proc : %s",
      gst_structure_get_name (message->structure));
  g_debug ("Thread ID : %d", Tcl_GetCurrentThread());

  switch (GST_MESSAGE_TYPE (message))
  {
    case GST_MESSAGE_ELEMENT:
      {
        const GstStructure *s = gst_message_get_structure (message);
        if (gst_structure_has_name (s, "farsight-error")) {
          const GValue *errorvalue, *debugvalue;
          gint errno;

          gst_structure_get_int (message->structure, "error-no", &errno);
          errorvalue = gst_structure_get_value (message->structure, "error-msg");
          debugvalue = gst_structure_get_value (message->structure, "debug-msg");

          if (errno != FS_ERROR_UNKNOWN_CNAME)  {
            _notify_error ("Farsight error");
          }
        } else if (gst_structure_has_name (s, "farsight-new-local-candidate")) {
          FsStream *stream;
          FsCandidate *candidate;
          const GValue *value;

          value = gst_structure_get_value (s, "stream");
          stream = g_value_get_object (value);

          value = gst_structure_get_value (s, "candidate");
          candidate = g_value_get_boxed (value);

          _new_local_candidate (stream, candidate);
        } else if (gst_structure_has_name (s,
                "farsight-local-candidates-prepared")) {
          FsStream *stream;
          FsCandidate *candidate;
          const GValue *value;

          value = gst_structure_get_value (s, "stream");
          stream = g_value_get_object (value);


          _local_candidates_prepared (stream);
        } else if (gst_structure_has_name (s, "farsight-codecs-changed")) {
          gboolean ready;
          const GValue *value;

          if (!codecs_ready) {
            g_object_get (session, "codecs-ready", &ready, NULL);
            if (ready) {
              _codecs_ready (session);
            }
          }
        }
      }

      break;
    case GST_MESSAGE_ERROR:
      {
        GError *error = NULL;
        gchar *debug = NULL;
        gst_message_parse_error (message, &error, &debug);

        g_debug ("Got an error on the BUS (%d): %s (%s)", error->code,
            error->message, debug);
        g_error_free (error);
        g_free (debug);

        _notify_error ("Gstreamer error");
      }
      break;
    default:
      break;
  }

  gst_message_unref (message);
  return 1;
}


static GstBusSyncReply
_bus_callback (GstBus *bus, GstMessage *message, gpointer user_data)
{
  FarsightBusEvent *evPtr;

  switch (GST_MESSAGE_TYPE (message))
  {
    case GST_MESSAGE_ELEMENT:
      {
        const GstStructure *s = gst_message_get_structure (message);
        g_debug ("bus message : %s", gst_structure_get_name (s));
        g_debug ("Thread ID : %d", Tcl_GetCurrentThread());
        if (gst_structure_has_name (s, "farsight-error")) {
          goto drop;
        } else if (gst_structure_has_name (s, "farsight-new-local-candidate")) {
          goto drop;
        } else if (gst_structure_has_name (s,
                "farsight-local-candidates-prepared")) {
          goto drop;
        } else if (gst_structure_has_name (s, "farsight-codecs-changed")) {
          goto drop;
        }
      }

      break;
    case GST_MESSAGE_ERROR:
      goto drop;
      break;
    default:
      break;
  }

  return GST_BUS_PASS;

 drop:
  evPtr = (FarsightBusEvent *)ckalloc(sizeof(FarsightBusEvent));
  evPtr->header.proc = Farsight_BusEventProc;
  evPtr->header.nextPtr = NULL;
  evPtr->message = message;

  Tcl_ThreadQueueEvent(main_tid, (Tcl_Event *)evPtr, TCL_QUEUE_TAIL);
  Tcl_ThreadAlert(main_tid);

  return GST_BUS_DROP;
}


int Farsight_Prepare _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  GError *error = NULL;
  GstBus *bus = NULL;
  GstElement *src;
  GstPad *sinkpad = NULL, *srcpad = NULL;
  GIOChannel *ioc = g_io_channel_unix_new (0);
  GParameter transmitter_params[3];

  char *stun_ip = NULL;
  char *stun_hostname = NULL;
  int stun_port = 3478;

  // We verify the arguments
  if( objc < 2 || objc > 4) {
    Tcl_WrongNumArgs (interp, 1, objv, " callback ?stun_ip? stun_port?");
    return TCL_ERROR;
  }

  callback = objv[1];
  Tcl_IncrRefCount (callback);
  callback_interp = interp;
  main_tid = Tcl_GetCurrentThread();

  if (objc > 2) {
    stun_hostname = Tcl_GetStringFromObj (objv[2], NULL);
    stun_ip = host2ip (stun_hostname);
    if (stun_ip == NULL) {
      Tcl_AppendResult (interp, "Stun server invalid : Could not resolve hostname",
          (char *) NULL);
      return TCL_ERROR;
    }
  }
  if (objc > 3) {
    if (Tcl_GetIntFromObj (interp, objv[3], &stun_port) == TCL_ERROR) {
      Tcl_AppendResult (interp, "Stun port invalid : Expected integer" , (char *) NULL);
      return TCL_ERROR;
    }
  }

  if (pipeline != NULL) {
    Tcl_AppendResult (interp, "Already prepared/in preparation" , (char *) NULL);
    return TCL_ERROR;
  }

  candidates_prepared = FALSE;
  codecs_ready = FALSE;

  pipeline = gst_pipeline_new ("pipeline");
  if (pipeline == NULL) {
    Tcl_AppendResult (interp, "Couldn't create gstreamer pipeline" , (char *) NULL);
    goto error;
  }

  bus = gst_element_get_bus (pipeline);
  gst_bus_set_sync_handler (bus, _bus_callback, NULL);
  gst_object_unref (bus);

  conference = gst_element_factory_make ("fsrtpconference", NULL);

  if (conference == NULL) {
    Tcl_AppendResult (interp, "Couldn't create fsrtpconference" , (char *) NULL);
    goto error;
  }

  if (gst_bin_add (GST_BIN (pipeline), conference) == FALSE) {
    Tcl_AppendResult (interp, "Couldn't add fsrtpconference to the pipeline",
        (char *) NULL);
    goto error;
  }

  g_object_set (conference, "sdes-cname", "", NULL);

  session = fs_conference_new_session (FS_CONFERENCE (conference),
      FS_MEDIA_TYPE_AUDIO, &error);
  if (error) {
    char temp[1000];
    snprintf (temp, 1000, "Error while creating new session (%d): %s",
        error->code, error->message);
    Tcl_AppendResult (interp, temp, (char *) NULL);
    goto error;
  }
  if (session == NULL) {
    Tcl_AppendResult (interp, "Couldn't create new session" , (char *) NULL);
    goto error;
  }

  if (!codecs_ready) {
    gboolean ready;
    const GValue *value;

    g_object_get (session, "codecs-ready", &ready, NULL);
    if (ready) {
      _codecs_ready (session);
    }
  }

  g_object_set (session, "no-rtcp-timeout", 0, NULL);

  g_object_get (session, "sink-pad", &sinkpad, NULL);

  if (sinkpad == NULL) {
    Tcl_AppendResult (interp, "Couldn't get sink pad" , (char *) NULL);
    goto error;
  }

  src = gst_element_factory_make ("dshowaudiosrc", NULL);
  if (src == NULL)
    src = gst_element_factory_make ("directsoundsrc", NULL);
  if (src == NULL)
    src = gst_element_factory_make ("osxaudiosrc", NULL);
  if (src == NULL)
    src = gst_element_factory_make ("gconfuadiosrc", NULL);
  if (src == NULL)
    src = gst_element_factory_make ("alsasrc", NULL);
  if (src == NULL)
    src = gst_element_factory_make ("osssrc", NULL);
  if (src == NULL) {
    Tcl_AppendResult (interp, "Couldn't create audio source" , (char *) NULL);
    goto error;
  }

  g_object_set(src, "blocksize", 640, NULL);
  g_object_set(src, "buffer-time", G_GINT64_CONSTANT(20000), NULL);

  if (gst_bin_add (GST_BIN (pipeline), src) == FALSE) {
    Tcl_AppendResult (interp, "Couldn't add source to pipeline" , (char *) NULL);
    goto error;
  }

  srcpad = gst_element_get_static_pad (src, "src");

  if (gst_pad_link (srcpad, sinkpad) != GST_PAD_LINK_OK) {
    Tcl_AppendResult (interp, "Couldn't link the source to fsrtpconference" ,
        (char *) NULL);
    goto error;
  }

  gst_object_unref (sinkpad);
  gst_object_unref (srcpad);

  participant = fs_conference_new_participant ( FS_CONFERENCE (conference),
      "", &error);
  if (error) {
    char temp[1000];
    snprintf (temp, 1000, "Error while creating new participant (%d): %s",
        error->code, error->message);
    Tcl_AppendResult (interp, temp, (char *) NULL);
    goto error;
  }
  if (participant == NULL) {
    Tcl_AppendResult (interp, "Couldn't create new participant" , (char *) NULL);
    goto error;
  }


  memset (transmitter_params, 0, sizeof (GParameter) * 3);

  transmitter_params[0].name = "compatibility-mode";
  g_value_init (&transmitter_params[0].value, G_TYPE_UINT);
  g_value_set_uint (&transmitter_params[0].value, 2);

  if (stun_ip) {
    g_debug ("stun ip : %s : %d", stun_ip, stun_port);
    transmitter_params[1].name = "stun-ip";
    g_value_init (&transmitter_params[1].value, G_TYPE_STRING);
    g_value_set_string (&transmitter_params[1].value, stun_ip);

    transmitter_params[2].name = "stun-port";
    g_value_init (&transmitter_params[2].value, G_TYPE_UINT);
    g_value_set_uint (&transmitter_params[2].value, stun_port);

    stream = fs_session_new_stream (session, participant, FS_DIRECTION_BOTH,
        "nice", 3, transmitter_params, &error);
  } else {
    stream = fs_session_new_stream (session, participant, FS_DIRECTION_BOTH,
        "nice", 1, transmitter_params, &error);
  }

  if (error) {
    char temp[1000];
    snprintf (temp, 1000, "Error while creating new stream (%d): %s",
        error->code, error->message);
    Tcl_AppendResult (interp, temp, (char *) NULL);
    goto error;
  }
  if (stream == NULL) {
    Tcl_AppendResult (interp, "Couldn't create new stream" , (char *) NULL);
    goto error;
  }

  g_signal_connect (stream, "src-pad-added",
      G_CALLBACK (_src_pad_added), pipeline);

  if (gst_element_set_state (pipeline, GST_STATE_PLAYING) ==
      GST_STATE_CHANGE_FAILURE) {
    Tcl_AppendResult (interp, "Unable to set pipeline to PLAYING",
        (char *) NULL);
    goto error;
  }

  return TCL_OK;

 error:
  Close ();

  return TCL_ERROR;
}

static void fs_candidates_list_destroy (GList *candidates) {
  GList *lp;
  FsCandidate *c;

  /* Free list of remote candidates */
  for (lp = candidates; lp; lp = g_list_next (lp)) {
    c = (FsCandidate *) lp->data;
    g_free (c->foundation);
    g_free (c->username);
    g_free (c->password);
    g_free (c->ip);
    g_free (c);
    lp->data = NULL;
  }
  g_list_free (candidates);

}

int Farsight_Start _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  GError *error = NULL;
  GList *remote_codecs = NULL;
  FsCodec *codec = NULL;
  int total_codecs;
  Tcl_Obj **tcl_remote_codecs = NULL;
  GList *remote_candidates = NULL;
  FsCandidate *candidate = NULL;
  int total_candidates;
  Tcl_Obj **tcl_remote_candidates = NULL;
  int i;

  // We verify the arguments
  if( objc != 3) {
    Tcl_WrongNumArgs (interp, 1, objv, " remote_codecs remote_candidates");
    return TCL_ERROR;
  }


  if (pipeline == NULL) {
    Tcl_AppendResult (interp, "Farsight needs to be prepared first",
        (char *) NULL);
    return TCL_ERROR;
  }

  if (Tcl_ListObjGetElements(interp, objv[1],
          &total_codecs, &tcl_remote_codecs) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid codec list", (char *) NULL);
      return TCL_ERROR;
  }

  for (i = 0; i < total_codecs; i++) {
    int total_elements;
    Tcl_Obj **elements = NULL;
    codec = g_new0 (FsCodec, 1);

    if (Tcl_ListObjGetElements(interp, tcl_remote_codecs[i],
            &total_elements, &elements) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid codec", (char *) NULL);
      goto error_codec;
    }
    if (total_elements != 3) {
      Tcl_AppendResult (interp, "\nInvalid codec : ",
          Tcl_GetString (tcl_remote_codecs[i]), (char *) NULL);
      goto error_codec;
    }

    codec->encoding_name = g_strdup (Tcl_GetStringFromObj (elements[0], NULL));

    if (Tcl_GetIntFromObj (interp, elements[1], &codec->id) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid codec : ",
          Tcl_GetString (tcl_remote_codecs[i]), (char *) NULL);
      goto error_codec;
    }

    if (Tcl_GetIntFromObj (interp, elements[2], &codec->clock_rate) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid codec : ",
          Tcl_GetString (tcl_remote_codecs[i]), (char *) NULL);
      goto error_codec;
    }

    codec->media_type = FS_MEDIA_TYPE_AUDIO;

    g_debug ("New remote codec : %d %s %d",
      codec->id, codec->encoding_name, codec->clock_rate);
    remote_codecs = g_list_append (remote_codecs, codec);
  }

  /*g_debug ("Setting remote codecs");*/
  if (!fs_stream_set_remote_codecs (stream, remote_codecs, &error)) {
    Tcl_AppendResult (interp, "Could not set the remote codecs", (char *) NULL);
    goto error_codecs;
  }
  fs_codec_list_destroy (remote_codecs);


  if (Tcl_ListObjGetElements(interp, objv[2],
          &total_candidates, &tcl_remote_candidates) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid candidates list", (char *) NULL);
      return TCL_ERROR;
  }

  for (i = 0; i < total_candidates; i++) {
    int total_elements;
    Tcl_Obj **elements = NULL;
    candidate = g_new0 (FsCandidate, 1);
    double temp;

    if (Tcl_ListObjGetElements(interp, tcl_remote_candidates[i],
            &total_elements, &elements) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid candidate", (char *) NULL);
      goto error_candidate;
    }
    if (total_elements != 7) {
      Tcl_AppendResult (interp, "Invalid candidate : ",
          Tcl_GetString (tcl_remote_candidates[i]), (char *) NULL);
      goto error_candidate;
    }

    candidate->username = g_strdup (Tcl_GetString (elements[0]));
    candidate->foundation = g_strdup (Tcl_GetString (elements[0]));

    if (Tcl_GetIntFromObj (interp, elements[1], &candidate->component_id) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid candidate : ",
          Tcl_GetString (tcl_remote_candidates[i]), (char *) NULL);
      goto error_candidate;
    }
    candidate->password = g_strdup (Tcl_GetString (elements[2]));
    candidate->proto = strcmp (Tcl_GetString (elements[3]), "UDP") == 0 ?
        FS_NETWORK_PROTOCOL_UDP : FS_NETWORK_PROTOCOL_TCP;

    if (Tcl_GetDoubleFromObj (interp, elements[4], &temp) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid candidate : ",
          Tcl_GetString (tcl_remote_candidates[i]), (char *) NULL);
      goto error_candidate;
    }

    candidate->priority = temp * 1000;
    candidate->ip = g_strdup (Tcl_GetString (elements[5]));

    if (Tcl_GetIntFromObj (interp, elements[6], &candidate->port) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid candidate : ",
          Tcl_GetString (tcl_remote_candidates[i]), (char *) NULL);
      goto error_candidate;
    }

    g_debug ("New Remote candidate: %s %d %s %s %d %s %d\n",
      candidate->username == NULL ? "-" : candidate->username,
      candidate->component_id,
      candidate->password == NULL ? "-" : candidate->password,
      candidate->proto == FS_NETWORK_PROTOCOL_UDP ? "UDP" : "TCP",
      candidate->priority, candidate->ip, candidate->port);

    remote_candidates = g_list_append (remote_candidates, candidate);
  }

  if (!fs_stream_set_remote_candidates (stream, remote_candidates, &error)) {
    Tcl_AppendResult (interp, "Could not set the remote candidates",
        (char *) NULL);
    goto error_candidate;
  }
  fs_candidates_list_destroy (remote_candidates);

  return TCL_OK;

 error_codec:
  g_free (codec);
 error_codecs:
  fs_codec_list_destroy (remote_codecs);
  return TCL_ERROR;

 error_candidate:
  g_free (candidate);
 error_candidates:
  fs_candidates_list_destroy (remote_candidates);
  return TCL_ERROR;
}

int Farsight_Stop _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{

  // We verify the arguments
  if( objc != 1) {
    Tcl_WrongNumArgs (interp, 1, objv, "");
    return TCL_ERROR;
  }

  Close ();

  return TCL_OK;
}


int Farsight_InUse _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{

  // We verify the arguments
  if( objc != 1) {
    Tcl_WrongNumArgs (interp, 1, objv, "");
    return TCL_ERROR;
  }

  Tcl_SetObjResult (interp, Tcl_NewBooleanObj (pipeline != NULL));

  return TCL_OK;
}

/*
  Function : Farsight_Init

  Description :	The Init function that will be called when the extension
  is loaded to your tcl shell

*/
int Farsight_Init (Tcl_Interp *interp) {

#ifdef G_OS_WIN32
  WSADATA w;
#endif

  //Check Tcl version is 8.3 or higher
  if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL) {
    return TCL_ERROR;
  }

#if defined(__APPLE__)
  gst_registry_fork_set_enabled((gboolean)FALSE);
#endif

  gst_init (NULL, NULL);

#ifdef G_OS_WIN32
  WSAStartup(0x0202, &w);
#endif

  // Create the wrapping commands in the Farsight namespace
  Tcl_CreateObjCommand(interp, "::Farsight::Prepare", Farsight_Prepare,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::Start", Farsight_Start,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::Stop", Farsight_Stop,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::InUse", Farsight_InUse,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

  // end of Initialisation
  return TCL_OK;
}

int Farsight_SafeInit (Tcl_Interp *interp) {
  return Farsight_Init(interp);
}

int Tcl_farsight_Init (Tcl_Interp *interp) {
  return Farsight_Init(interp);
}

int Tcl_farsight_SafeInit (Tcl_Interp *interp) {
  return Farsight_Init(interp);
}
