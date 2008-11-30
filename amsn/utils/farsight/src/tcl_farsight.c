/*
  File : tcl_farishgt.c

  Description :	Contains all functions for accessing farsight 2

  Author : Youness El Alaoui (KaKaRoTo - kakaroto@users.sourceforge.net)
*/


// Include the header file
#include "tcl_farsight.h"

#include <string.h>
#include <math.h>

#include <gst/gst.h>
#include <gst/farsight/fs-conference-iface.h>
#include <gst/farsight/fs-stream-transmitter.h>
#include <gst/interfaces/propertyprobe.h>

#ifdef G_OS_WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#include <wspiapi.h>
#define snprintf _snprintf
#define inet_ntop inet_ntop_win32
#else
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#endif



Tcl_Obj *level_callback = NULL;
Tcl_Interp *level_callback_interp = NULL;
Tcl_Obj *debug_callback = NULL;
Tcl_Interp *debug_callback_interp = NULL;
char *source = NULL;
char *device = NULL;
GstElement *pipeline = NULL;
GstElement *conference = NULL;
GstElement *volumeIn = NULL;
GstElement *volumeOut = NULL;
GstElement *levelIn = NULL;
GstElement *levelOut = NULL;
FsSession *session = NULL;
FsParticipant *participant = NULL;
FsStream *stream = NULL;
gboolean candidates_prepared = FALSE;
gboolean codecs_ready = FALSE;
Tcl_Obj *local_candidates = NULL;
Tcl_Obj *callback = NULL;
Tcl_Interp *callback_interp = NULL;
Tcl_ThreadId main_tid = 0;
int components_selected = 0;


#ifdef _WIN32
const char *inet_ntop_win32(int af, const void *src, char *dst, socklen_t cnt)
{
        if (af == AF_INET) {
                struct sockaddr_in in;
                memset(&in, 0, sizeof(in));
                in.sin_family = AF_INET;
                memcpy(&in.sin_addr, src, sizeof(struct in_addr));
                getnameinfo((struct sockaddr *)&in, sizeof(struct sockaddr_in), dst, cnt, NULL, 0, NI_NUMERICHOST);
                return dst;
        }
        return NULL;
}

#endif

static char *host2ip(char *hostname)
{
    struct addrinfo * result;
    static char ip[30];
    const char * ret;
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

  if (volumeIn) {
    gst_object_unref (volumeIn);
    volumeIn = NULL;
  }
  if (volumeOut) {
    gst_object_unref (volumeOut);
    volumeOut = NULL;
  }

  candidates_prepared = FALSE;
  codecs_ready = FALSE;
  components_selected = 0;

  if (local_candidates) {
    Tcl_DecrRefCount(local_candidates);
    local_candidates = NULL;
  }

  if (callback) {
    Tcl_DecrRefCount (callback);
    callback = NULL;
    callback_interp = NULL;
  }
  if (source) {
    g_free (source);
    source = NULL;
  }
  if (device) {
    g_free (device);
    device = NULL;
  }

}


static void
_notify_debug (gchar *format, ...)
{

  Tcl_Obj *msg = NULL;
  Tcl_Obj *eval = Tcl_NewStringObj ("eval", -1);
  Tcl_Obj *args = Tcl_NewListObj (0, NULL);
  Tcl_Obj *command[] = {eval, debug_callback, args};
  Tcl_Interp *interp = debug_callback_interp;
  gchar *message;
  va_list ap;
  va_start (ap, format);
  message = g_strdup_vprintf (format, ap);
  va_end (ap);

  msg = Tcl_NewStringObj (message, -1);
  Tcl_ListObjAppendElement(NULL, args, msg);

  if (debug_callback && debug_callback_interp) {
    /* Take the callback here in case it gets Closed by the eval */
    Tcl_Obj *cbk = debug_callback;
    Tcl_IncrRefCount (eval);
    Tcl_IncrRefCount (args);
    Tcl_IncrRefCount (cbk);

    if (Tcl_EvalObjv(interp, 3, command, TCL_EVAL_GLOBAL) == TCL_ERROR) {
      g_debug ("Error executing debug handler : %s --- %s",
          Tcl_GetStringResult(interp), msg);
    }
    Tcl_DecrRefCount (cbk);
    Tcl_DecrRefCount (args);
    Tcl_DecrRefCount (eval);
  }

  g_free (message);
}

static void
_notify_callback (char *status_msg, Tcl_Obj *obj1, Tcl_Obj *obj2)
{

  Tcl_Obj *status = Tcl_NewStringObj (status_msg, -1);
  Tcl_Obj *eval = Tcl_NewStringObj ("eval", -1);
  Tcl_Obj *empty = Tcl_NewListObj (0, NULL);
  Tcl_Obj *args = Tcl_NewListObj (0, NULL);
  Tcl_Obj *command[] = {eval, callback, args};
  Tcl_Interp *interp = callback_interp;


  Tcl_ListObjAppendElement(NULL, args, status);
  if (obj1)
    Tcl_ListObjAppendElement(NULL, args, obj1);
  else
    Tcl_ListObjAppendElement(NULL, args, empty);

  if (obj2)
    Tcl_ListObjAppendElement(NULL, args, obj2);
  else
    Tcl_ListObjAppendElement(NULL, args, empty);

  if (callback && callback_interp) {
    /* Take the callback here in case it gets Closed by the eval */
    Tcl_Obj *cbk = callback;
    Tcl_IncrRefCount (eval);
    Tcl_IncrRefCount (args);
    Tcl_IncrRefCount (cbk);

    if (Tcl_EvalObjv(interp, 3, command, TCL_EVAL_GLOBAL) == TCL_ERROR) {
      _notify_debug ("Error executing %s handler : %s", status_msg,
          Tcl_GetStringResult(interp));
    }
    Tcl_DecrRefCount (cbk);
    Tcl_DecrRefCount (args);
    Tcl_DecrRefCount (eval);
  }

}

static void
_notify_level (char *direction, gfloat level)
{

  Tcl_Obj *dir = Tcl_NewStringObj (direction, -1);
  Tcl_Obj *eval = Tcl_NewStringObj ("eval", -1);
  Tcl_Obj *args = Tcl_NewListObj (0, NULL);
  Tcl_Obj *command[] = {eval, level_callback, args};
  Tcl_Interp *interp = level_callback_interp;


  Tcl_ListObjAppendElement(NULL, args, dir);
  Tcl_ListObjAppendElement(NULL, args, Tcl_NewDoubleObj (level));

  if (level_callback && level_callback_interp) {
    /* Take the callback here in case it gets Closed by the eval */
    Tcl_Obj *cbk = level_callback;
    Tcl_IncrRefCount (eval);
    Tcl_IncrRefCount (args);
    Tcl_IncrRefCount (cbk);

    if (Tcl_EvalObjv(interp, 3, command, TCL_EVAL_GLOBAL) == TCL_ERROR) {
      _notify_debug ("Error executing level handler : %s",
          Tcl_GetStringResult(interp));
    }
    Tcl_DecrRefCount (cbk);
    Tcl_DecrRefCount (args);
    Tcl_DecrRefCount (eval);
  }
}


static void
_notify_error (char *error)
{
  Tcl_Obj *obj = Tcl_NewStringObj (error, -1);

  _notify_debug ("An error occured : %s", error);

  _notify_callback ("ERROR", obj, obj);

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
_notify_active (const char *local, const char *remote)
{
  Tcl_Obj *local_candidate = Tcl_NewStringObj (local, -1);
  Tcl_Obj *remote_candidate = Tcl_NewStringObj (remote, -1);

  _notify_callback ("ACTIVE", local_candidate, remote_candidate);
}

static void
_notify_prepared ()
{

  if (codecs_ready && candidates_prepared) {
    Tcl_Obj *local_codecs = Tcl_NewListObj (0, NULL);

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

    _notify_callback ("PREPARED", local_codecs, local_candidates);
  }
}

static void
_new_local_candidate (FsStream *stream, FsCandidate *candidate)
{
  Tcl_Obj *tcl_candidate = NULL;
  Tcl_Obj *elements[7];

  if (local_candidates == NULL) {
    local_candidates = Tcl_NewListObj (0, NULL);
    Tcl_IncrRefCount(local_candidates);
  }

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

  _notify_debug ("CANDIDATES ARE PREPARED");
  _notify_prepared ();
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
    if (convert) gst_object_unref (convert);
    if (resample) gst_object_unref (resample);
    if (convert2) gst_object_unref (convert2);
    return;
  }

  g_signal_connect (sink, "element-added",
      G_CALLBACK (_sink_element_added), NULL);

  if (gst_bin_add (GST_BIN (pipeline), sink) == FALSE)  {
    _notify_error_post ("Could not add sink to pipeline");
    if (sink) gst_object_unref (sink);
    if (convert) gst_object_unref (convert);
    if (resample) gst_object_unref (resample);
    if (convert2) gst_object_unref (convert2);
    return;
  }

  if (gst_bin_add (GST_BIN (pipeline), convert) == FALSE) {
    _notify_error_post ("Could not add converter to pipeline");
    if (convert) gst_object_unref (convert);
    if (resample) gst_object_unref (resample);
    if (convert2) gst_object_unref (convert2);
    return;
  }
  if (gst_bin_add (GST_BIN (pipeline), resample) == FALSE) {
    _notify_error_post ("Could not add resampler to pipeline");
    if (resample) gst_object_unref (resample);
    if (convert2) gst_object_unref (convert2);
    return;
  }
  if (gst_bin_add (GST_BIN (pipeline), convert2) == FALSE) {
    _notify_error_post ("Could not add second converter to pipeline");
    if (convert2) gst_object_unref (convert2);
    return;
  }

  volumeOut = gst_element_factory_make ("volume", NULL);
  if (volumeOut) {
    gst_object_ref (volumeOut);

    if (gst_bin_add (GST_BIN (pipeline), volumeOut) == FALSE) {
      _notify_error_post ("Could not add output volume to pipeline");
      return;
    }

    if (gst_element_link(volumeOut, convert) == FALSE)  {
      _notify_error_post ("Could not link volume out to converter");
      return;
    }
    sink_pad = gst_element_get_static_pad (volumeOut, "sink");
  } else {
    sink_pad = gst_element_get_static_pad (convert, "sink");
  }

  ret = gst_pad_link (pad, sink_pad);
  gst_object_unref (sink_pad);

  if (ret != GST_PAD_LINK_OK)  {
    _notify_error_post ("Could not link volume/sink to fsrtpconference sink pad");
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

  levelOut = gst_element_factory_make ("level", NULL);
  if (levelOut) {
    gst_object_ref (levelOut);

    if (gst_bin_add (GST_BIN (pipeline), levelOut) == FALSE) {
      _notify_error_post ("Could not add output level to pipeline");
      return;
    }
    g_object_set (G_OBJECT (levelOut), "message", TRUE, NULL);

    if (gst_element_link(convert2, levelOut) == FALSE)  {
      _notify_error_post ("Could not link level out to converter");
      return;
    }
    if (gst_element_link(levelOut, sink) == FALSE)  {
      _notify_error_post ("Could not link sink to level out");
      return;
    }
  } else {
    if (gst_element_link(convert2, sink) == FALSE)  {
      _notify_error_post ("Could not link sink to converter");
      return;
    }
  }

  if (gst_element_set_state (volumeOut, GST_STATE_PLAYING) ==
      GST_STATE_CHANGE_FAILURE) {
    _notify_error_post ("Unable to set volume OUT to PLAYING");
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
  if (levelOut) {
    if (gst_element_set_state (levelOut, GST_STATE_PLAYING) ==
        GST_STATE_CHANGE_FAILURE) {
      _notify_error_post ("Unable to set sink to PLAYING");
      return;
    }
  }
}

static void
_codecs_ready (FsSession *session)
{
  codecs_ready = TRUE;

  _notify_debug ("CODECS ARE READY");

  _notify_prepared ();
}

typedef struct {
  Tcl_Event header;
  GstMessage *message;
} FarsightBusEvent;

static int Farsight_BusEventProc (Tcl_Event *evPtr, int flags)
{
  FarsightBusEvent *ev = (FarsightBusEvent *) evPtr;
  GstMessage *message = ev->message;

  switch (GST_MESSAGE_TYPE (message))
  {
    case GST_MESSAGE_ELEMENT:
      {
        const GstStructure *s = gst_message_get_structure (message);
        if (gst_structure_has_name (s, "farsight-error")) {
          const GValue *errorvalue, *debugvalue, *error_no;

          error_no = gst_structure_get_value (message->structure, "error-no");
          errorvalue = gst_structure_get_value (message->structure, "error-msg");
          debugvalue = gst_structure_get_value (message->structure, "debug-msg");

          if (g_value_get_enum (error_no) != FS_ERROR_UNKNOWN_CNAME)  {
            _notify_debug ("Error on BUS (%d) %s .. %s", g_value_get_enum (error_no),
                g_value_get_string (errorvalue),
                g_value_get_string (debugvalue));
          }
          if (g_value_get_enum (error_no) != FS_ERROR_UNKNOWN_CNAME)  {
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
          const GValue *value;

          value = gst_structure_get_value (s, "stream");
          stream = g_value_get_object (value);


          _local_candidates_prepared (stream);
        } else if (gst_structure_has_name (s, "farsight-codecs-changed")) {
          gboolean ready;

          if (!codecs_ready) {
            g_object_get (session, "codecs-ready", &ready, NULL);
            if (ready) {
              _codecs_ready (session);
            }
          }
        } else if (gst_structure_has_name (s, "farsight-new-active-candidate-pair")) {
          FsCandidate *local;
          FsCandidate *remote;
          const GValue *value;


          value = gst_structure_get_value (s, "local-candidate");
          local = g_value_get_boxed (value);

          value = gst_structure_get_value (s, "remote-candidate");
          remote = g_value_get_boxed (value);

          _notify_debug ("New active candidate pair : ");

          _notify_debug ("Local candidate: %s %d %s %s %d %s %d\n",
              local->username == NULL ? "-" : local->username,
              local->component_id,
              local->password == NULL ? "-" : local->password,
              local->proto == FS_NETWORK_PROTOCOL_UDP ? "UDP" : "TCP",
              local->priority, local->ip, local->port);

          _notify_debug ("Remote candidate: %s %d %s %s %d %s %d\n",
              remote->username == NULL ? "-" : remote->username,
              remote->component_id,
              remote->password == NULL ? "-" : remote->password,
              remote->proto == FS_NETWORK_PROTOCOL_UDP ? "UDP" : "TCP",
              remote->priority, remote->ip, remote->port);

          if (++components_selected == 2) {
            _notify_active (local->username, remote->username);
          }
        } else if (gst_structure_has_name (s, "level")) {
          gint channels;
          gdouble rms_dB;
          gdouble rms;
          const GValue *list;
          const GValue *value;
          gint i;

          /* we can get the number of channels as the length of any of the value
           * lists */
          list = gst_structure_get_value (s, "rms");
          channels = gst_value_list_get_size (list);

          rms = 0;
          for (i = 0; i < channels; ++i) {
            list = gst_structure_get_value (s, "rms");
            value = gst_value_list_get_value (list, i);
            rms_dB = g_value_get_double (value);

            /* converting from dB to normal gives us a value between 0.0 and 1.0 */
            rms += pow (10, rms_dB / 20);
          }
          if (GST_MESSAGE_SRC (message) == GST_OBJECT(levelIn)) {
            _notify_level ("IN", (gfloat) (rms / channels));
          } else if (GST_MESSAGE_SRC (message) == GST_OBJECT(levelOut)) {
            _notify_level ("OUT", (gfloat) (rms / channels));
		  }
        }
      }

      break;
    case GST_MESSAGE_ERROR:
      {
        GError *error = NULL;
        gchar *debug = NULL;
        gst_message_parse_error (message, &error, &debug);

        _notify_debug ("Got an error on the BUS (%d): %s (%s)", error->code,
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
        if (gst_structure_has_name (s, "farsight-error")) {
          goto drop;
        } else if (gst_structure_has_name (s, "farsight-new-local-candidate")) {
          goto drop;
        } else if (gst_structure_has_name (s,
                "farsight-local-candidates-prepared")) {
          goto drop;
        } else if (gst_structure_has_name (s, "farsight-codecs-changed")) {
          goto drop;
        } else if (gst_structure_has_name (s, "farsight-new-active-candidate-pair")) {
          goto drop;
        } else if (gst_structure_has_name (s, "level")) {
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
  GParameter transmitter_params[6];
  int controlling;
  char *stun_ip = NULL;
  char *stun_hostname = NULL;
  int stun_port = 3478;
  Tcl_Obj **tcl_relay_info = NULL;
  int total_relay_info;
  int i;
  GValueArray *relay_info = NULL;
  int total_params;

  // We verify the arguments
  if( objc < 3 || objc > 6) {
    Tcl_WrongNumArgs (interp, 1, objv, " callback controlling ?relay_info?"
        " ?stun_ip stun_port?\n"
        "Where relay_info is a list with each element being a list containing : "
        "{turn_hostname turn_port turn_username turn_password component type}");
    return TCL_ERROR;
  }

  if (Tcl_GetBooleanFromObj (interp, objv[2], &controlling) != TCL_OK) {
    return TCL_ERROR;
  }

  callback = objv[1];
  Tcl_IncrRefCount (callback);
  callback_interp = interp;
  main_tid = Tcl_GetCurrentThread();


  if (objc > 3) {
    if (Tcl_ListObjGetElements(interp, objv[3],
            &total_relay_info, &tcl_relay_info) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid relay info", (char *) NULL);
      return TCL_ERROR;
    }
    if (total_relay_info > 0) {
      relay_info = g_value_array_new (0);
    }
    for (i = 0; i < total_relay_info; i++) {
      char *turn_ip = NULL;
      char *turn_hostname = NULL;
      int turn_port = 1863;
      int component = 0;
      char *username = NULL;
      char *password = NULL;
      char *type = NULL;
      int total_elements;
      Tcl_Obj **elements = NULL;
      GstStructure *turn_setup = NULL;
      GValue gvalue = { 0 };
      g_value_init (&gvalue, GST_TYPE_STRUCTURE);

      if (Tcl_ListObjGetElements(interp, tcl_relay_info[i],
              &total_elements, &elements) != TCL_OK) {
        g_value_array_free (relay_info);
        Tcl_AppendResult (interp, "\nInvalid relay info element", (char *) NULL);
        return TCL_ERROR;
      }
      if (total_elements != 6) {
        g_value_array_free (relay_info);
        Tcl_AppendResult (interp, "\nInvalid relay info element : ",
            Tcl_GetString (tcl_relay_info[i]), (char *) NULL);
        return TCL_ERROR;
      }

      turn_hostname = Tcl_GetStringFromObj (elements[0], NULL);
      turn_ip = host2ip (turn_hostname);
      if (turn_ip == NULL) {
        g_value_array_free (relay_info);
        Tcl_AppendResult (interp, "TURN server invalid : Could not resolve hostname",
            (char *) NULL);
        return TCL_ERROR;
      }
      if (Tcl_GetIntFromObj (interp, elements[1], &turn_port) == TCL_ERROR) {
        g_value_array_free (relay_info);
        Tcl_AppendResult (interp, "TURN port invalid : Expected integer" , (char *) NULL);
        return TCL_ERROR;
      }
      if (turn_port == 0) {
        turn_port = 1863;
      }
      username = Tcl_GetStringFromObj (elements[2], NULL);
      password = Tcl_GetStringFromObj (elements[3], NULL);
      if (Tcl_GetIntFromObj (interp, elements[4], &component) == TCL_ERROR) {
        g_value_array_free (relay_info);
        Tcl_AppendResult (interp, "TURN component invalid : Expected integer" , (char *) NULL);
        return TCL_ERROR;
      }
      type = Tcl_GetStringFromObj (elements[5], NULL);

      turn_setup = gst_structure_new ("relay-info",
          "ip", G_TYPE_STRING, turn_ip,
          "port", G_TYPE_UINT, turn_port,
          "username", G_TYPE_STRING, username,
          "password", G_TYPE_STRING, password,
          "component", G_TYPE_UINT, component,
          "relay-type", G_TYPE_STRING, type,
          NULL);
      if (turn_setup == NULL) {
        g_value_array_free (relay_info);
        Tcl_AppendResult (interp, "Unable to create relay info" , (char *) NULL);
        return TCL_ERROR;
      }
      gst_value_set_structure (&gvalue, turn_setup);
      relay_info = g_value_array_append (relay_info, &gvalue);
      gst_structure_free (turn_setup);
    }
  }

  if (objc > 4) {
    stun_hostname = Tcl_GetStringFromObj (objv[4], NULL);
    stun_ip = host2ip (stun_hostname);
    if (stun_ip == NULL) {
      Tcl_AppendResult (interp, "Stun server invalid : Could not resolve hostname",
          (char *) NULL);
      return TCL_ERROR;
    }
  }
  if (objc > 5) {
    if (Tcl_GetIntFromObj (interp, objv[5], &stun_port) == TCL_ERROR) {
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

  /* Set codec preferences.. if this fails, then it's no big deal.. */
  {
    GList *codec_preferences = NULL;
    FsCodec *x_msrta_16000 = fs_codec_new (114, "x-msrta", FS_MEDIA_TYPE_AUDIO, 16000);
    FsCodec *siren = fs_codec_new (111, "SIREN", FS_MEDIA_TYPE_AUDIO, 16000);
    FsCodec *g7221 = fs_codec_new (112, "G7221", FS_MEDIA_TYPE_AUDIO, 16000);
    FsCodec *x_msrta_8000 = fs_codec_new (115, "x-msrta", FS_MEDIA_TYPE_AUDIO, 8000);
    FsCodec *aal2 = fs_codec_new (116, "AAL2-G726-32", FS_MEDIA_TYPE_AUDIO, 8000);
    FsCodec *g723 = fs_codec_new (4, "G723", FS_MEDIA_TYPE_AUDIO, 8000);
    FsCodec *pcma = fs_codec_new (8, "PCMA", FS_MEDIA_TYPE_AUDIO, 8000);
    FsCodec *pcmu = fs_codec_new (0, "PCMU", FS_MEDIA_TYPE_AUDIO, 8000);
    FsCodec *red = fs_codec_new (97, "RED", FS_MEDIA_TYPE_AUDIO, 8000);

    codec_preferences = g_list_append (codec_preferences, x_msrta_16000);
    codec_preferences = g_list_append (codec_preferences, siren);
    codec_preferences = g_list_append (codec_preferences, g7221);
    codec_preferences = g_list_append (codec_preferences, x_msrta_8000);
    codec_preferences = g_list_append (codec_preferences, aal2);
    codec_preferences = g_list_append (codec_preferences, g723);
    codec_preferences = g_list_append (codec_preferences, pcma);
    codec_preferences = g_list_append (codec_preferences, pcmu);
    codec_preferences = g_list_append (codec_preferences, red);

    fs_session_set_codec_preferences (session, codec_preferences, NULL);

    fs_codec_list_destroy (codec_preferences);
  }

  if (!codecs_ready) {
    gboolean ready;

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
  else
    g_object_set(src, "buffer-time", G_GINT64_CONSTANT(20000), NULL);
  if (src == NULL)
    src = gst_element_factory_make ("osxaudiosrc", NULL);
  if (src == NULL)
    src = gst_element_factory_make ("gconfaudiosrc", NULL);
  if (src == NULL)
    src = gst_element_factory_make ("alsasrc", NULL);
  if (src == NULL)
    src = gst_element_factory_make ("osssrc", NULL);
  if (src == NULL) {
    Tcl_AppendResult (interp, "Couldn't create audio source" , (char *) NULL);
    goto error;
  }

  g_object_set(src, "blocksize", 640, NULL);

  if (gst_bin_add (GST_BIN (pipeline), src) == FALSE) {
    Tcl_AppendResult (interp, "Couldn't add source to pipeline" , (char *) NULL);
    if (src) gst_object_unref (src);
    goto error;
  }

  volumeIn = gst_element_factory_make ("volume", NULL);
  if (volumeIn) {
    gst_object_ref (volumeIn);
    if (gst_bin_add (GST_BIN (pipeline), volumeIn) == FALSE) {
      Tcl_AppendResult (interp, "Could not add input volume to pipeline",
          (char *) NULL);
      goto error;
    }

    srcpad = gst_element_get_static_pad (volumeIn, "src");
    if (gst_element_link(src, volumeIn) == FALSE)  {
      Tcl_AppendResult (interp, "Could not link source to volume", (char *) NULL);
      goto error;
    }
  } else {
    srcpad = gst_element_get_static_pad (src, "src");
  }

  levelIn = gst_element_factory_make ("level", NULL);
  if (levelIn) {
    GstPad *levelsink;

    gst_object_ref (levelIn);
    if (gst_bin_add (GST_BIN (pipeline), levelIn) == FALSE) {
      Tcl_AppendResult (interp, "Could not add input level to pipeline",
          (char *) NULL);
      goto error;
    }
    g_object_set (G_OBJECT (levelIn), "message", TRUE, NULL);

    levelsink = gst_element_get_static_pad (levelIn, "sink");
    if (gst_pad_link (srcpad, levelsink) != GST_PAD_LINK_OK) {
      gst_object_unref (levelsink);
      gst_object_unref (srcpad);
      Tcl_AppendResult (interp, "Couldn't link the volume/src to level" ,
          (char *) NULL);
      goto error;
    }

    gst_object_unref (srcpad);
    srcpad = gst_element_get_static_pad (levelIn, "src");
  }

  if (gst_pad_link (srcpad, sinkpad) != GST_PAD_LINK_OK) {
    gst_object_unref (sinkpad);
    gst_object_unref (srcpad);
    Tcl_AppendResult (interp, "Couldn't link the volume/level/src to fsrtpconference" ,
        (char *) NULL);
    goto error;
  }

  gst_object_unref (sinkpad);
  gst_object_unref (srcpad);

  participant = fs_conference_new_participant (FS_CONFERENCE (conference),
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


  memset (transmitter_params, 0, sizeof (GParameter) * 6);

  transmitter_params[0].name = "compatibility-mode";
  g_value_init (&transmitter_params[0].value, G_TYPE_UINT);
  g_value_set_uint (&transmitter_params[0].value, 2);

  transmitter_params[1].name = "controlling-mode";
  g_value_init (&transmitter_params[1].value, G_TYPE_BOOLEAN);
  g_value_set_boolean (&transmitter_params[1].value, controlling);

  total_params = 2;
  if (stun_ip) {
    _notify_debug ("stun ip : %s : %d", stun_ip, stun_port);
    transmitter_params[total_params].name = "stun-ip";
    g_value_init (&transmitter_params[total_params].value, G_TYPE_STRING);
    g_value_set_string (&transmitter_params[total_params].value, stun_ip);

    transmitter_params[total_params + 1].name = "stun-port";
    g_value_init (&transmitter_params[total_params + 1].value, G_TYPE_UINT);
    g_value_set_uint (&transmitter_params[total_params + 1].value, stun_port);
    total_params +=2;
  }

  if (relay_info) {
    _notify_debug ("FS: relay info = %p - %d", relay_info, relay_info->n_values);
    transmitter_params[total_params].name = "relay-info";
    g_value_init (&transmitter_params[total_params].value, G_TYPE_VALUE_ARRAY);
    g_value_set_boxed (&transmitter_params[total_params].value, relay_info);
    total_params++;
    g_value_array_free (relay_info);
  }

  stream = fs_session_new_stream (session, participant, FS_DIRECTION_BOTH,
      "nice", total_params, transmitter_params, &error);

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
    Tcl_WrongNumArgs (interp, 1, objv, " remote_codecs remote_candidates\n"
        "Where remote_codecs is a list with each element being a list containing : "
        "{encoding_name payload_type clock_rate}\n"
        "And where remote_candidates is a list with each element being a list containing : "
        "{username component_id password protocol priority ip port}");
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
    codec = fs_codec_new (0, NULL, FS_MEDIA_TYPE_AUDIO, 0);

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

    _notify_debug ("New remote codec : %d %s %d",
      codec->id, codec->encoding_name, codec->clock_rate);
    remote_codecs = g_list_append (remote_codecs, codec);
  }

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
    double temp;
	int temp_port;
    candidate = fs_candidate_new (NULL, 1, 0, FS_NETWORK_PROTOCOL_UDP, NULL, 0);

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
    candidate->foundation[32] = 0;

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

    candidate->priority = (guint32) temp * 1000;
    candidate->ip = g_strdup (Tcl_GetString (elements[5]));

    if (Tcl_GetIntFromObj (interp, elements[6], &temp_port) != TCL_OK) {
      Tcl_AppendResult (interp, "\nInvalid candidate : ",
          Tcl_GetString (tcl_remote_candidates[i]), (char *) NULL);
      goto error_candidate;
    }
	candidate->port = temp_port;

    _notify_debug ("New Remote candidate: %s %d %s %s %d %s %d\n",
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
    goto error_candidates;
  }
  fs_candidate_list_destroy (remote_candidates);

  return TCL_OK;

 error_codec:
  fs_codec_destroy (codec);
 error_codecs:
  fs_codec_list_destroy (remote_codecs);
  return TCL_ERROR;

 error_candidate:
  fs_candidate_destroy (candidate);
 error_candidates:
  fs_candidate_list_destroy (remote_candidates);
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

static int _SetMute (GstElement *element, Tcl_Interp *interp,
    int objc, Tcl_Obj *CONST objv[])
{
  gboolean mute;

  // We verify the arguments
  if( objc != 2) {
    Tcl_WrongNumArgs (interp, 1, objv, "mute");
    return TCL_ERROR;
  }

  if (Tcl_GetBooleanFromObj(interp, objv[1], &mute) == TCL_ERROR) {
    return TCL_ERROR;
  }

  if (element) {
    g_object_set (element, "mute", mute, NULL);
  } else {
    Tcl_AppendResult (interp, "Farsight isn't running", (char *) NULL);
    return TCL_ERROR;
  }

  return TCL_OK;
}

int Farsight_SetMuteIn _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  return _SetMute (volumeIn, interp, objc, objv);
}

int Farsight_SetMuteOut _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  return _SetMute (volumeOut, interp, objc, objv);
}

static int _GetMute (GstElement *element, Tcl_Interp *interp,
    int objc, Tcl_Obj *CONST objv[])
{
  gboolean mute;

  // We verify the arguments
  if( objc != 1) {
    Tcl_WrongNumArgs (interp, 1, objv, "");
    return TCL_ERROR;
  }

  if (element) {
    g_object_get (element, "mute", &mute, NULL);
    Tcl_SetObjResult(interp, Tcl_NewBooleanObj(mute));
  } else {
    Tcl_AppendResult (interp, "Farsight isn't running", (char *) NULL);
    return TCL_ERROR;
  }

  return TCL_OK;
}

int Farsight_GetMuteIn _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  return _GetMute (volumeIn, interp, objc, objv);
}

int Farsight_GetMuteOut _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  return _GetMute (volumeOut, interp, objc, objv);
}

static int _SetVolume (GstElement *element, Tcl_Interp *interp,
    int objc, Tcl_Obj *CONST objv[])
{
  gdouble volume;

  // We verify the arguments
  if( objc != 2) {
    Tcl_WrongNumArgs (interp, 1, objv, "volume");
    return TCL_ERROR;
  }

  if (Tcl_GetDoubleFromObj(interp, objv[1], &volume) == TCL_ERROR) {
    return TCL_ERROR;
  }

  if (element) {
    g_object_set (element, "volume", volume, NULL);
  } else {
    Tcl_AppendResult (interp, "Farsight isn't running", (char *) NULL);
    return TCL_ERROR;
  }

  return TCL_OK;
}

int Farsight_SetVolumeIn _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  return _SetVolume (volumeIn, interp, objc, objv);
}

int Farsight_SetVolumeOut _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  return _SetVolume (volumeOut, interp, objc, objv);
}


static int _GetVolume (GstElement *element, Tcl_Interp *interp,
    int objc, Tcl_Obj *CONST objv[])
{
  gdouble volume;

  // We verify the arguments
  if( objc != 1) {
    Tcl_WrongNumArgs (interp, 1, objv, "");
    return TCL_ERROR;
  }

  if (element) {
    g_object_get (element, "volume", &volume, NULL);
    Tcl_SetObjResult(interp, Tcl_NewDoubleObj(volume));
  } else {
    Tcl_AppendResult (interp, "Farsight isn't running", (char *) NULL);
    return TCL_ERROR;
  }

  return TCL_OK;
}

int Farsight_GetVolumeIn _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  return _GetVolume (volumeIn, interp, objc, objv);
}

int Farsight_GetVolumeOut _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  return _GetVolume (volumeOut, interp, objc, objv);
}


int Farsight_Probe _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  const gchar *elements[] = {"dshowaudiosrc", "directsoundsrc",
                             "osxaudiosrc", "gconfaudiosrc",
                             "alsasrc", "osssrc"};

  gint n;
  Tcl_Obj *source = NULL;
  Tcl_Obj *temp = NULL;
  Tcl_Obj *devices = NULL;
  Tcl_Obj *result = NULL;

  result = Tcl_NewListObj (0, NULL);

  // We verify the arguments
  if( objc != 1) {
    Tcl_WrongNumArgs (interp, 1, objv, "");
    return TCL_ERROR;
  }

  for (n = 0; n < G_N_ELEMENTS (elements); ++n) {
    GstPropertyProbe *probe;
    GValueArray *arr;
    GstElement *element;
    guint i;

    element = gst_element_factory_make (elements[n], elements[n]);
    if (element == NULL)
      continue;

    if (!GST_IS_PROPERTY_PROBE (element))
      continue;

    probe = GST_PROPERTY_PROBE (element);
    if (probe == NULL)
      continue;

    temp = Tcl_NewStringObj (elements[n], -1);
    source = Tcl_NewListObj (0, NULL);
    devices = Tcl_NewListObj (0, NULL);

    Tcl_ListObjAppendElement(NULL, source, temp);

    arr = gst_property_probe_probe_and_get_values_name (probe, "device");
    if (arr) {
      for (i = 0; i < arr->n_values; ++i) {
        const gchar *device;
        GValue *val;

        val = g_value_array_get_nth (arr, i);
        if (val == NULL || !G_VALUE_HOLDS_STRING (val))
          continue;

        device = g_value_get_string (val);
        if (device == NULL)
          continue;

        temp = Tcl_NewStringObj (device, -1);
        Tcl_ListObjAppendElement(NULL, devices, temp);
      }
      g_value_array_free (arr);
    } else {
      /* no devices found */
    }

    Tcl_ListObjAppendElement(NULL, source, devices);
    Tcl_ListObjAppendElement(NULL, result, source);

    gst_object_unref (element);
  }



  Tcl_SetObjResult (interp, result);

  return TCL_OK;
}


int Farsight_Config _ANSI_ARGS_((ClientData clientData,  Tcl_Interp *interp,
        int objc, Tcl_Obj *CONST objv[]))
{
  static const char *farsightOptions[] = {
    "-level", "-debug", "-source", "-device", NULL
  };
  enum farsightOptions {
    FS_LEVEL, FS_DEBUG, FS_SOURCE, FS_DEVICE
  };
  int optionIndex, a;
  char *level = NULL, *source = NULL, *device = NULL;

  for (a = 1; a < objc; a++) {
    const char *arg = Tcl_GetString(objv[a]);

    if (Tcl_GetIndexFromObj(interp, objv[a], farsightOptions, "option",
            TCL_EXACT, &optionIndex) != TCL_OK) {
      return TCL_ERROR;
    }
    switch ((enum farsightOptions) optionIndex) {
      case FS_LEVEL:
        a++;
        if (a >= objc) {
          Tcl_AppendResult(interp,
              "no argument given for -level option", NULL);
          return TCL_ERROR;
        }

        if (level_callback) {
          Tcl_DecrRefCount (level_callback);
          level_callback = NULL;
          level_callback_interp = NULL;
        }
        if (Tcl_GetString (objv[a]) != NULL &&
            Tcl_GetString (objv[a])[0] != 0) {
          level_callback = objv[a];
          Tcl_IncrRefCount (level_callback);
          level_callback_interp = interp;
        }
        break;
      case FS_DEBUG:
        a++;
        if (a >= objc) {
          Tcl_AppendResult(interp,
              "no argument given for -debug option", NULL);
          return TCL_ERROR;
        }

        if (debug_callback) {
          Tcl_DecrRefCount (debug_callback);
          debug_callback = NULL;
          debug_callback_interp = NULL;
        }

        if (Tcl_GetString (objv[a]) != NULL &&
            Tcl_GetString (objv[a])[0] != 0) {
          debug_callback = objv[a];
          Tcl_IncrRefCount (debug_callback);
          debug_callback_interp = interp;
        }
        break;
      case FS_SOURCE:
        a++;
        if (a >= objc) {
          Tcl_AppendResult(interp,
              "no argument given for -source option", NULL);
          return TCL_ERROR;
        }

        source = g_strdup (Tcl_GetString(objv[a]));
        break;
      case FS_DEVICE: {
        a++;
        if (a >= objc) {
          Tcl_AppendResult(interp,
              "no argument given for -myport option", NULL);
          return TCL_ERROR;
        }
        device = g_strdup (Tcl_GetString(objv[a]));
        break;
      }
      default:
        Tcl_Panic("Tcl_SocketObjCmd: bad option index to SocketOptions");
    }
  }

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
  Tcl_CreateObjCommand(interp, "::Farsight::Probe", Farsight_Probe,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::SetVolumeIn", Farsight_SetVolumeIn,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::GetVolumeIn", Farsight_GetVolumeIn,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::SetVolumeOut", Farsight_SetVolumeOut,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::GetVolumeOut", Farsight_GetVolumeOut,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::SetMuteIn", Farsight_SetMuteIn,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::GetMuteIn", Farsight_GetMuteIn,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::SetMuteOut", Farsight_SetMuteOut,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::GetMuteOut", Farsight_GetMuteOut,
		       (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
  Tcl_CreateObjCommand(interp, "::Farsight::Config", Farsight_Config,
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
