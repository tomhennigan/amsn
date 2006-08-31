/*
 * msn-message.c - Source for MsnMessage
 * Copyright (C) 2006 ?
 * Copyright (C) 2006 ?
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */


#include <glib/gprintf.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <netdb.h>

#include "msn-message.h"

#define LINE_SEPERATOR "\r\n"
#define BODY_SEPERATOR "\r\n\r\n"
#define HEADER_SEPERATOR ": "
#define SPACE_SEPERATOR " "

//G_DEFINE_TYPE(MsnMessage, msn_message, G_TYPE_OBJECT)



/* private structure */
typedef struct _MsnMessagePrivate MsnMessagePrivate;

struct _MsnMessagePrivate
{
  gchar **command_header;
  GHashTable *headers;
  GString *body;
  gint trid;
};

#define MSN_MESSAGE_GET_PRIVATE(o)     (G_TYPE_INSTANCE_GET_PRIVATE ((o), MSN_TYPE_MESSAGE, MsnMessagePrivate))

static inline gint 
get_argc (const gchar * const argv[]) 
{
  register gint i;
  for (i = 0; argv[i] != NULL; i++) { ; }
  return i;
}



static gboolean
command_has_trid (const gchar *command) {
  static const union ucmdcompare cmd_list[] = {
    { "CVR" }, 
    { "VER" },
    { "USR" },
    { "XFR" },
    { "ADD" }, // MSNP11 only?
    { "ADC" }, // MSNP11 only?
    { "CHG" },
    { "GCF" },
    { "ILN" },
    { "QRY" },
    { "SYN" },
    { "REA" },
    { "ANS" },
    { "IRO" },
    { "CAL" },
    { .i_cmd = 0 }		// close the list
  };

  register guint32 ref_cmd = *((const guint32 *) command);
  for (register gint i = 0; cmd_list[i].i_cmd != 0; i++) {
    if(cmd_list[i].i_cmd == ref_cmd) return TRUE;
  }
  return FALSE;
}



/* type definition stuff */
static void
msn_message_init (GTypeInstance *instance, gpointer g_class)
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(instance);
  priv->command_header = NULL;
  priv->body = NULL;
  priv->headers = NULL;
  priv->trid = -1;
}

static void msn_message_dispose (GObject *object);
static void msn_message_finalize (GObject *object);

static void
msn_message_class_init (MsnMessageClass *msn_message_class)
{
  GObjectClass *object_class = G_OBJECT_CLASS (msn_message_class);
  g_type_class_add_private (msn_message_class, sizeof (MsnMessagePrivate));
  object_class->dispose = msn_message_dispose;
  object_class->finalize = msn_message_finalize;
}

static void
msn_message_dispose (GObject *object)
{
 // MsnMessage *self = MSN_MESSAGE (object);
  //MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE (self);

  /* release any references held by the object here */

//   if (G_OBJECT_CLASS (msn_message_parent_class)->dispose)
//     G_OBJECT_CLASS (msn_message_parent_class)->dispose (object);
}

static void
msn_message_finalize (GObject *object)
{
  MsnMessage *self = MSN_MESSAGE (object);
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE (self);

  if (priv->command_header != NULL) g_free(priv->command_header);
  if (priv->headers != NULL) g_hash_table_unref(priv->headers);
  if (priv->body != NULL) g_string_free(priv->body, TRUE);

//   G_OBJECT_CLASS (msn_message_parent_class)->finalize (object);
}


GType 
msn_message_get_type (void)
{
  static GType msn_message_type = 0;
  if (!msn_message_type) {
    static const GTypeInfo msn_message_info = {
      sizeof(MsnMessageClass),
      NULL,
      NULL,
      (GClassInitFunc) msn_message_class_init,
      NULL,
      NULL,
      sizeof(MsnMessage),
      0,
      (GInstanceInitFunc) msn_message_init,
    };
    msn_message_type = g_type_register_static(G_TYPE_OBJECT, "MsnMessage", &msn_message_info, 0);
  }
  return msn_message_type;
}

/**
 * This function creates a new, empty MsnMessage object.
 *
 * Returns: 
 *    new MsnMessage if successful, else NULL.
 */
MsnMessage *
msn_message_new()
{
  return g_object_new(MSN_TYPE_MESSAGE, NULL);
}


/**
 * These functions create an MsnMessage object from the passed string.
 * The returned MsnMessage object will be read only. 
 * the msn_message_from_string_in should be used with incoming messages (possibly with a trid)
 * the msn_message_from_string_out should be used with outgoing messages (no trid, this should
 * be set with msn_message_set_trid)
 *
 * Parameters:
 *    <msgtext> The message as a string. This will usually have been received from the server. 
 *
 * Returns: 
 *    MsnMessage if successful, else NULL.
 */
MsnMessage *
msn_message_from_string_in(const gchar *msgtext) 
{
  MsnMessage *message = msn_message_new();
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(message);
  
  /* Split the message into a header and a body */
  gchar **body_split = g_strsplit(msgtext, BODY_SEPERATOR, 2);
  if (get_argc((const gchar **) body_split) == 2) {
    msn_message_set_body(message, body_split[1]);
  }

  /* Split the header on line breaks */
  gchar **headers_split = g_strsplit(body_split[0], LINE_SEPERATOR, G_MAXINT);

  /* First header line is the MSNP command + TrId + arguments.
   * We need to separate the TrId from the rest because
   * msn_message_set_command_header_from_string() doesn't
   * like to have a TrId. So we split the sting here, remove
   * the TrId, and use msn_message_set_command_header(). */
  gchar **command_split = g_strsplit(headers_split[0], SPACE_SEPERATOR, G_MAXINT);
  if (command_has_trid(command_split[0]) && (command_split[1] != NULL)) {
    priv->trid = atoi(command_split[1]);
    g_free(command_split[1]);
    for (register gint p = 1; command_split[p] != NULL; p++)
      command_split[p] = command_split[p + 1];
  }

  msn_message_set_command_header(message, (const gchar **) command_split);

  /* Other header lines are message headers */
  for (gint i = 1; headers_split[i] != NULL && g_str_equal(headers_split[i], "") != TRUE; i++) {
    gchar **single_header_split = g_strsplit(headers_split[i], HEADER_SEPERATOR, 2);
    msn_message_set_header(message, single_header_split[0], single_header_split[1]);
    g_strfreev(single_header_split);
  }

  /* Free allocated memory and return */

  g_strfreev(command_split);
  g_strfreev(headers_split);
  g_strfreev(body_split);

  return message;
}


/**
 * These functions create an MsnMessage object from the passed string.
 * The returned MsnMessage object will be read only. 
 * the msn_message_from_string_in should be used with incoming messages (possibly with a trid)
 * the msn_message_from_string_out should be used with outgoing messages (no trid, this should
 * be set with msn_message_set_trid)
 *
 * Parameters:
 *    <msgtext> The message as a string. This will usually have been received from the server. 
 *
 * Returns: 
 *    MsnMessage if successful, else NULL.
 */
MsnMessage *
msn_message_from_string_out(const gchar *msgtext) 
{
  MsnMessage *message = msn_message_new();
  
  /* Split the message into a header and a body */
  gchar **body_split = g_strsplit(msgtext, BODY_SEPERATOR, 2);
  if (get_argc((const gchar **) body_split) == 2) {
    msn_message_set_body(message, body_split[1]);
  }

  /* Split the header on line breaks */
  gchar **headers_split = g_strsplit(body_split[0], LINE_SEPERATOR, G_MAXINT);

  gchar **command_split = g_strsplit(headers_split[0], SPACE_SEPERATOR, G_MAXINT);
  msn_message_set_command_header(message, (const gchar **) command_split);

  /* Other header lines are message headers */
  for (gint i = 1; headers_split[i] != NULL && g_str_equal(headers_split[i], "") != TRUE; i++) {
    gchar **single_header_split = g_strsplit(headers_split[i], HEADER_SEPERATOR, 2);
    msn_message_set_header(message, single_header_split[0], single_header_split[1]);
    g_strfreev(single_header_split);
  }

  /* Free allocated memory and return */

  g_strfreev(command_split);
  g_strfreev(headers_split);
  g_strfreev(body_split);

  return message;
}


/**
 * This function returns the content of the requested header, or NULL if the message does 
 * not contain a header with the specified name. The caller must not free the string 
 * returned by this function.
 *
 * Parameters:
 *    <name> The name of the header to get.
 *
 * Returns: 
 *    gchar * if successful, else NULL.
 */
const gchar *
msn_message_get_header(MsnMessage *this, const gchar *name)
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  return (gchar *) g_hash_table_lookup(priv->headers, name);
}

/**
 * This function returns the content of the message body, or NULL if the message has no body.
 * The caller must not free the string returned by this function.
 *
 * Parameters:
 *    <this> Pointer to the object the method is invoked on. Must be obtained from msn_message_new 
 *           or msn_message_from_string.
 *
 * Returns: 
 *    gchar * if successful, else NULL.
 */
const gchar *
msn_message_get_body(MsnMessage *this)
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  return priv->body->str; 
}


/**
 * This function returns the MSN protocol command in this message. This is equal to the element at
 * index 0 of the array returned by msn_message_get_command_header.
 * The caller must not free the string returned by this function.
 *
 * Parameters:
 *    <this> Pointer to the object the method is invoked on. Must be obtained from msn_message_new 
 *           or msn_message_from_string.
 *
 * Returns: 
 *    gchar * if successful, else NULL.
 */
const gchar *
msn_message_get_command(MsnMessage *this) 
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  return priv->command_header[0];
}


/**
 * This function returns an array of strings. Each element of the array holds one token from the
 * very first line of the message (the MSNP protocol command, and its arguments). The TrId is
 * omitted. The array will be NULL-terminated.
 * The caller must not free the returned array, nor any of the strings it points to.
 *
 * Parameters:
 *    <this> Pointer to the object the method is invoked on. Must be obtained from msn_message_new 
 *           or msn_message_from_string.
 *
 * Returns: 
 *    gchar ** if successful, else NULL.
 */
const gchar * const *
msn_message_get_command_header(MsnMessage *this) 
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  return (const gchar **) priv->command_header;
}


/**
 * This function returns the message's TrId, or -1 if it has no TrId.
 *
 * Parameters:
 *    <this> Pointer to the object the method is invoked on. Must be obtained from msn_message_new 
 *           or msn_message_from_string.
 *
 * Returns: 
 *    trid if successful, else -1.
 */
gint
msn_message_get_trid(MsnMessage *this) 
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  return priv->trid; 
}
 

/**
 * This function sets a header with the specified name, and assigns it the given value. 
 * If a header of that name already exists, it is replaced.
 * Both the name and the value may be freed by the caller after this function returns.
 *
 * Parameters:
 *    <this>  Pointer to the object the method is invoked on. Must be obtained from msn_message_new.
 *    <name>  The name of the header to set.
 *    <value> The value to set it to.
 *
 */
void
msn_message_set_header(MsnMessage *this, const gchar *name, const gchar *value)
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  if (priv->headers == NULL) priv->headers = g_hash_table_new(g_str_hash, g_str_equal);
  g_hash_table_insert(priv->headers, g_strdup(name), g_strdup(value));
}


/**
 * This function sets the message body. If a body is already set, it will be replaced.
 * The passed body may be freed by the caller after this function returns.
 *
 * Parameters:
 *    <this>  Pointer to the object the method is invoked on. Must be obtained from msn_message_new.
 *    <body>  The message body
 *
 */
void
msn_message_set_body(MsnMessage *this, const gchar *body)
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  if (priv->body != NULL) priv->body = g_string_assign(priv->body, body);
  else priv->body = g_string_new(body);
}


/**
 * This function appends the given string to the message body.
 * If no body has been set yet, it operates like the msn_message_set_body function.
 * The passed string may be freed by the caller after this function returns.
 *
 * Parameters:
 *    <this>   Pointer to the object the method is invoked on. Must be obtained from msn_message_new.
 *    <string> The string to append to the message body.
 *
 */
void
msn_message_append_body(MsnMessage *this, const gchar *string)
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  if (priv->body != NULL) priv->body = g_string_append(priv->body, string);
  else priv->body = g_string_new(string);
}


/**
 * This function sets the first line of the message (the MSN protocol command and its 
 * arguments). Each element of the argv array holds one token. The TrId must be omitted.
 * The caller may free the array passed to this function after this function returns.
 * 
 * Parameters:
 *    <this> Pointer to the object the method is invoked on. Must be obtained from
 *           msn_message_new or msn_message_from_string.
 *    <argv> An array holding the MSNP command at index 0 and its arguments at index
 *           1 and up. The array must be NULL terminated.
 *
 */
void
msn_message_set_command_header(MsnMessage *this, const gchar * const argv[])
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  if (priv->command_header != NULL) g_strfreev(priv->command_header);
  priv->command_header = g_strdupv((gchar **) argv);
}


/**
 * This function sets the trid of the message
 * 
 * Parameters:
 *    <this>        Pointer to the object the method is invoked on. Must be obtained from
 *                  msn_message_new or msn_message_from_string.
 *    <trid>        Value of the trid
 *
 */
void 
msn_message_set_trid(MsnMessage *this, gint trid) {
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  priv->trid = trid;
}


/**
 * This function sets the first line of the message (the MSN protocol command and its
 * arguments). The TrId must be omitted. The caller may free the string passed to this
 * function after this function returns.
 * 
 * Parameters:
 *    <this>        Pointer to the object the method is invoked on. Must be obtained from
 *                  msn_message_new or msn_message_from_string.
 *    <command_hdr> Pointer to the command string.
 *
 */
void
msn_message_set_command_header_from_string(MsnMessage *this, const gchar *command_hdr)
{
  gchar **command_header = g_strsplit(command_hdr, SPACE_SEPERATOR, G_MAXINT);
  msn_message_set_command_header(this, (const gchar **) command_header);
  g_strfreev(command_header);
}


/**
 * function called by a g_hash_table_for_each
 * this function adds a header to a string of headers 
 */
static void
header_concat(gpointer key, gpointer value, gpointer user_data)
{
  GString *header_ptr = (GString *) user_data;
  g_string_append_printf(
    header_ptr,
    "%s%s%s%s",
    (gchar *) key,
    HEADER_SEPERATOR,
    (gchar *) value,
    LINE_SEPERATOR);
}


/**
 * This function will assign the message a TrId (if required by the protocol) and send
 * it through the specified connection.
 * 
 * Parameters:
 *    <this> Pointer to the object the method is invoked on. Must be obtained from
 *           msn_message_new
 *    <conn> The connection where the message is to be sent.
 *
 */
gchar *
msn_message_to_string(MsnMessage *this)
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE(this);
  gchar *arg_string = g_strjoinv(SPACE_SEPERATOR, &(priv->command_header[1]));
  gchar *command_header;
  command_header = (priv->trid < 0) ?
    g_strdup_printf("%s%s%s%s",
      priv->command_header[0], 
      SPACE_SEPERATOR, 
      arg_string, 
      LINE_SEPERATOR):
    g_strdup_printf("%s%s%i%s%s%s",
      priv->command_header[0], 
      SPACE_SEPERATOR, 
      priv->trid, 
      SPACE_SEPERATOR,
      arg_string, 
      LINE_SEPERATOR);
  g_free(arg_string);
  GString *result = g_string_new(command_header);
  g_free(command_header);
  if (priv->headers != NULL && g_hash_table_size(priv->headers) > 0) {
     GString *headers = g_string_new("");
     g_hash_table_foreach(priv->headers, header_concat, headers);
     result = g_string_append(result, headers->str);
     g_string_free(headers, TRUE);
  } 
  if (priv->body != NULL) result = g_string_append(result, priv->body->str);
  gchar *result_str = g_strdup(result->str);
  g_string_free(result, TRUE);
  return result_str;
}
