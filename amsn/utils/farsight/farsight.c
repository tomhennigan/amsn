#include <string.h>

#include <gst/gst.h>
#include <gst/farsight/fs-conference-iface.h>
#include <gst/farsight/fs-stream-transmitter.h>

#ifdef G_OS_WIN32
#include <winsock2.h>
#endif

static void
_new_local_candidate (FsStream *stream, FsCandidate *candidate)
{

  g_print ("LOCAL_CANDIDATE: %s %d %s %s %.3f %s %d\n",
      candidate->username == NULL ? "" : candidate->username,
      candidate->component_id,
      candidate->password == NULL ? "" : candidate->password,
      candidate->proto == FS_NETWORK_PROTOCOL_UDP ? "UDP" : "TCP",
      (gfloat) candidate->priority / 1000, candidate->ip, candidate->port);

}

static void
_local_candidates_prepared (FsStream *stream)
{

  g_print ("LOCAL_CANDIDATES_DONE\n");

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

  g_assert (sink);

  g_signal_connect (sink, "element-added",
      G_CALLBACK (_sink_element_added), NULL);

  gst_bin_add (GST_BIN (pipeline), sink);
  gst_bin_add (GST_BIN (pipeline), convert);
  gst_bin_add (GST_BIN (pipeline), resample);
  gst_bin_add (GST_BIN (pipeline), convert2);

  sink_pad = gst_element_get_static_pad (convert, "sink");
  ret = gst_pad_link (pad, sink_pad);
  gst_object_unref (sink_pad);

  g_assert (GST_PAD_LINK_SUCCESSFUL(ret));

  gst_element_link(convert, resample);
  gst_element_link(resample, convert2);
  gst_element_link(convert2, sink);

  g_assert (gst_element_set_state (convert, GST_STATE_PLAYING) !=
      GST_STATE_CHANGE_FAILURE);

  g_assert (gst_element_set_state (resample, GST_STATE_PLAYING) !=
      GST_STATE_CHANGE_FAILURE);

  g_assert (gst_element_set_state (convert2, GST_STATE_PLAYING) !=
      GST_STATE_CHANGE_FAILURE);

  g_assert (gst_element_set_state (sink, GST_STATE_PLAYING) !=
      GST_STATE_CHANGE_FAILURE);

}

static gboolean
stdin_io_cb(GIOChannel *source, GIOCondition condition, gpointer data) {
  gsize length = 0;
  gsize term = 0;
  GError *error = NULL;
  gchar *line = NULL;
  static GList *remote_codecs = NULL;
  static GList *remote_candidates = NULL;
  FsStream *stream = data;


  /* Free what was entered */
  if (g_io_channel_read_line (source, &line, &length, &term, &error) != G_IO_STATUS_NORMAL) {
    return FALSE;
  }
  g_free (error);

  if (length == 0) {
    return TRUE;
  }

  line[term] = 0;

  if (strncmp (line, "REMOTE_CANDIDATE: ", 18) == 0) {
    FsCandidate *candidate = g_new0 (FsCandidate, 1);
    gchar **elements = NULL;

    elements = g_strsplit (line + 18, " ", 0);

    g_assert (elements[0] && elements[1] && elements[2] &&
        elements[3] && elements[4] && elements[5] &&
        elements[6] && !elements[7]);

    candidate->username = g_strdup (elements[0]);
    candidate->foundation = g_strdup (elements[0]);
    g_assert (strlen (elements[1]) == 1);
    g_assert (elements[1][0] == '1' || elements[1][0] == '2');
    candidate->component_id = elements[1][0] == '1' ? 1 : 2;
    candidate->password = g_strdup (elements[2]);
    g_assert (strcmp (elements[3], "UDP") == 0 ||
        strcmp (elements[3], "TCP") == 0);
    candidate->proto = strcmp (elements[3], "UDP") == 0 ?
        FS_NETWORK_PROTOCOL_UDP : FS_NETWORK_PROTOCOL_TCP;
    candidate->priority = g_ascii_strtoull (elements[4], NULL, 10);
    candidate->ip = g_strdup (elements[5]);
    candidate->port = g_ascii_strtoull (elements[6], NULL, 10);
    g_strfreev(elements);

    g_debug ("New Remote candidate: %s %d %s %s %d %s %d\n",
      candidate->username == NULL ? "-" : candidate->username,
      candidate->component_id,
      candidate->password == NULL ? "-" : candidate->password,
      candidate->proto == FS_NETWORK_PROTOCOL_UDP ? "UDP" : "TCP",
      candidate->priority, candidate->ip, candidate->port);

    remote_candidates = g_list_append (remote_candidates, candidate);
  } else if (strcmp (line, "REMOTE_CANDIDATES_DONE") == 0) {
    gboolean ret;
    GError *error = NULL;
    GList *lp;
    FsCandidate *c;

    g_debug ("Remote candidates done 1");

    ret = fs_stream_set_remote_candidates (stream, remote_candidates, &error);

    g_debug ("Remote candidates done : %p", error);
    if (error) {
      g_printerr ("Error while adding candidates: (%s:%d) %s",
          g_quark_to_string (error->domain), error->code, error->message);
      g_assert (0);
    }

    g_debug ("Remote candidates done : %d", ret);
    g_assert (ret == TRUE);
    g_debug ("Remote candidates done");


    /* Free list of remote candidates */
    for (lp = remote_candidates; lp; lp = g_list_next (lp)) {
      c = (FsCandidate *) lp->data;
      g_free (c->foundation);
      g_free (c->username);
      g_free (c->password);
      g_free (c->ip);
      g_free (c);
      lp->data = NULL;
    }
    g_list_free (remote_candidates);
    remote_candidates = NULL;

  } else if (strncmp (line, "REMOTE_CODEC: ", 14) == 0) {
    FsCodec *codec = g_new0 (FsCodec, 1);
    gchar **elements = NULL;

    elements = g_strsplit (line + 14, " ", 0);
    g_assert (elements[0] && elements[1] && elements[2] && !elements[3]);

    codec->id = g_ascii_strtoull (elements[0], NULL, 10);
    codec->encoding_name = g_strdup (elements[1]);
    codec->clock_rate = g_ascii_strtoull (elements[2], NULL, 10);
    codec->media_type = FS_MEDIA_TYPE_AUDIO;
    g_strfreev(elements);

    /*g_debug ("New remote codec : %d %s %d\n",
      codec->id, codec->encoding_name, codec->clock_rate);*/
    remote_codecs = g_list_append (remote_codecs, codec);
  } else if (strcmp (line, "REMOTE_CODECS_DONE") == 0) {
    GError *error = NULL;

    /*g_debug ("Setting remote codecs");*/
    if (!fs_stream_set_remote_codecs (stream, remote_codecs, &error)) {
      if (error) {
        g_printerr ("Could not set the remote codecs on stream %d : %s",
            error->code, error->message);
      }
      g_assert (0);
    }
    fs_codec_list_destroy (remote_codecs);
    remote_codecs = NULL;
  } else if (strcmp (line, "EXIT") == 0) {
    return FALSE;
  }

  g_free (line);

  return TRUE;
}


static GstBusSyncReply
_bus_sync_callback (GstBus *bus, GstMessage *message, gpointer user_data)
{
  g_debug ("sync handler bus_callback...");

}

static GstBusSyncReply
_bus_callback (GstBus *bus, GstMessage *message, gpointer user_data)
{
  switch (GST_MESSAGE_TYPE (message))
  {
    case GST_MESSAGE_ELEMENT:
      {
        const GstStructure *s = gst_message_get_structure (message);
        g_debug ("bus message : %s", gst_structure_get_name (s));
        if (gst_structure_has_name (s, "farsight-error")) {
          const GValue *errorvalue, *debugvalue;
          gint errno;

          gst_structure_get_int (message->structure, "error-no", &errno);
          errorvalue = gst_structure_get_value (message->structure, "error-msg");
          debugvalue = gst_structure_get_value (message->structure, "debug-msg");

          if (errno != FS_ERROR_UNKNOWN_CNAME)  {
            g_debug ("Error on BUS (%d) %s .. %s", errno,
                g_value_get_string (errorvalue),
                g_value_get_string (debugvalue));
          }
          goto drop;
        } else if (gst_structure_has_name (s, "farsight-new-local-candidate")) {
          FsStream *stream;
          FsCandidate *candidate;
          const GValue *value;

          value = gst_structure_get_value (s, "stream");
          stream = g_value_get_object (value);

          value = gst_structure_get_value (s, "candidate");
          candidate = g_value_get_boxed (value);

          _new_local_candidate (stream, candidate);
          goto drop;
        } else if (gst_structure_has_name (s,
                "farsight-local-candidates-prepared")) {
          FsStream *stream;
          FsCandidate *candidate;
          const GValue *value;

          value = gst_structure_get_value (s, "stream");
          stream = g_value_get_object (value);


          _local_candidates_prepared (stream);
          goto drop;
        }
      }

      break;
    case GST_MESSAGE_ERROR:
      {
        GError *error = NULL;
        gchar *debug = NULL;
        gst_message_parse_error (message, &error, &debug);

        g_error ("Got an error on the BUS (%d): %s (%s)", error->code,
            error->message, debug);
        g_error_free (error);
        g_free (debug);
      }
      goto drop;
      break;
    case GST_MESSAGE_WARNING:
      {
        GError *error = NULL;
        gchar *debug = NULL;
        gst_message_parse_warning (message, &error, &debug);

        g_debug ("Got a warning on the BUS (%d): %s (%s)",
            error->code,
            error->message, debug);
        g_error_free (error);
        g_free (debug);
      }
      goto drop;
      break;
    default:
      break;
  }

  return GST_BUS_PASS;
 drop:
  gst_message_unref (message);
  return GST_BUS_DROP;
}

int main (int argc, char *argv[]) {
  GstElement *pipeline;
  GstElement *conference;
  FsSession *session;
  GError *error = NULL;
  GList *local_codecs = NULL;
  GList *item = NULL;
  GstBus *bus = NULL;
  FsParticipant *participant;
  FsStream *stream;
  GstElement *src;
  GstPad *sinkpad = NULL, *srcpad = NULL;
  GIOChannel *ioc = g_io_channel_unix_new (0);
  GParameter transmitter_params[3];
#ifdef G_OS_WIN32
  WSADATA w;
#endif

#if defined(__APPLE__)
  gst_registry_fork_set_enabled((gboolean)FALSE);
#endif

  gst_init (&argc, &argv);

#ifdef G_OS_WIN32
  WSAStartup(0x0202, &w);
#endif

  pipeline = gst_pipeline_new ("pipeline");
  g_assert (pipeline != NULL);

  bus = gst_element_get_bus (pipeline);
  gst_bus_set_sync_handler (bus, _bus_callback, NULL);
  gst_object_unref (bus);

  conference = gst_element_factory_make ("fsrtpconference", NULL);;

  g_assert (conference != NULL);
  g_assert (gst_bin_add (GST_BIN (pipeline), conference));

  g_object_set (conference, "sdes-cname", "", NULL);

  session = fs_conference_new_session (FS_CONFERENCE (conference),
      FS_MEDIA_TYPE_AUDIO, &error);
  if (error) {
    g_printerr ("Error while creating new session (%d): %s",
        error->code, error->message);
    g_assert (0);
  }
  g_assert (session != NULL);

  g_object_set (session, "no-rtcp-timeout", 0, NULL);

  /*g_signal_connect (session, "notify::current-send-codec",
      G_CALLBACK (_current_send_codec_notify), NULL);

    g_signal_connect (session, "new-negotiated-codecs",
      G_CALLBACK (_new_negotiated_codecs), NULL);*/

  g_object_get (session, "sink-pad", &sinkpad, NULL);
  g_assert (sinkpad != NULL);

  src = gst_element_factory_make ("dshowaudiosrc", NULL);
  if (src == NULL)
     src = gst_element_factory_make ("directsoundsrc", NULL);
  if (src == NULL)
     src = gst_element_factory_make ("osxaudiosrc", NULL);
  if (src == NULL)
     src = gst_element_factory_make ("alsasrc", NULL);
  if (src == NULL)
     src = gst_element_factory_make ("osssrc", NULL);
  g_assert (src != NULL);

  g_object_set(src, "blocksize", 640, NULL);
  g_object_set(src, "buffer-time", G_GINT64_CONSTANT(20000), NULL);

  g_assert (gst_bin_add (GST_BIN (pipeline), src));

  srcpad = gst_element_get_static_pad (src, "src");

  g_assert (gst_pad_link (srcpad, sinkpad) == GST_PAD_LINK_OK);

  gst_object_unref (sinkpad);
  gst_object_unref (srcpad);

  g_object_get (session, "local-codecs", &local_codecs, NULL);

  for (item = g_list_first (local_codecs); item; item = g_list_next (item))
  {
    FsCodec *codec = item->data;
    g_print ("LOCAL_CODEC: %d %s %d\n",
        codec->id, codec->encoding_name, codec->clock_rate);
  }

  fs_codec_list_destroy (local_codecs);
  g_print ("LOCAL_CODECS_DONE\n");

  participant = fs_conference_new_participant (
      FS_CONFERENCE (conference), "", &error);
  if (error) {
    g_printerr ("Error while creating new participant (%d): %s",
        error->code, error->message);
    g_assert (0);
  }
  g_assert (participant != NULL);


  memset (transmitter_params, 0, sizeof (GParameter) * 3);

  transmitter_params[0].name = "stun-ip";
  g_value_init (&transmitter_params[0].value, G_TYPE_STRING);
  g_value_set_static_string (&transmitter_params[0].value, "64.14.48.28");

  transmitter_params[1].name = "stun-port";
  g_value_init (&transmitter_params[1].value, G_TYPE_UINT);
  g_value_set_uint (&transmitter_params[1].value, 3478);

  transmitter_params[2].name = "compatibility-mode";
  g_value_init (&transmitter_params[2].value, G_TYPE_UINT);
  g_value_set_uint (&transmitter_params[2].value, 2);

  stream = fs_session_new_stream (session, participant, FS_DIRECTION_BOTH,
      "nice", 3, transmitter_params, &error);
  if (error) {
    g_printerr ("Error while creating new stream (%d): %s",
        error->code, error->message);
    g_assert (0);
  }
  g_assert (stream != NULL);

  g_io_add_watch (ioc, G_IO_IN, stdin_io_cb, stream);

  g_signal_connect (stream, "src-pad-added",
      G_CALLBACK (_src_pad_added), pipeline);

  g_assert (gst_element_set_state (pipeline, GST_STATE_PLAYING) !=
      GST_STATE_CHANGE_FAILURE);

  while(stdin_io_cb (ioc, G_IO_IN, stream));

  gst_element_set_state (pipeline, GST_STATE_NULL);

  g_object_unref (stream);
  g_object_unref (participant);
  g_object_unref (session);
  gst_object_unref (pipeline);


#ifdef G_OS_WIN32
   WSACleanup();
#endif

  return 0;
}

/*

REMOTE_CANDIDATE: L0 1  UDP 0 192.168.1.106 7078
REMOTE_CANDIDATE: L0 2  UDP 0 192.168.1.106 7079
REMOTE_CANDIDATES_DONE
REMOTE_CODEC: 0 PCMU 8000
REMOTE_CODEC: 8 PCMA 8000
REMOTE_CODECS_DONE


*/
