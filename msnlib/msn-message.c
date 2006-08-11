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

G_DEFINE_TYPE(MsnMessage, msn_message, G_TYPE_OBJECT)

/* private structure */
typedef struct _MsnMessagePrivate MsnMessagePrivate;

struct _MsnMessagePrivate
{
  GString *body;
  gchar **command_header;
  GHashTable *headers;
  gint trid, command_header_length;
  // private variables go here
};

gint trid = 1;

#define MSN_MESSAGE_GET_PRIVATE(o)     (G_TYPE_INSTANCE_GET_PRIVATE ((o), MSN_TYPE_MESSAGE, MsnMessagePrivate))

gint get_argc(const gchar * const argv[]) {
  gint i = 0;
  while (argv[i] != NULL) {
    i++;
  }
  return i;
}

/* type definition stuff */

static void
msn_message_init (MsnMessage *obj)
{
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE (obj);
  priv->body = g_string_new("");
  priv->headers = g_hash_table_new(g_str_hash, g_str_equal);
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

void
msn_message_dispose (GObject *object)
{
 // MsnMessage *self = MSN_MESSAGE (object);
  //MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE (self);

  /* release any references held by the object here */

  if (G_OBJECT_CLASS (msn_message_parent_class)->dispose)
    G_OBJECT_CLASS (msn_message_parent_class)->dispose (object);
}

void
msn_message_finalize (GObject *object)
{
  MsnMessage *self = MSN_MESSAGE (object);
  MsnMessagePrivate *priv = MSN_MESSAGE_GET_PRIVATE (self);

  g_free(priv->command_header);

  G_OBJECT_CLASS (msn_message_parent_class)->finalize (object);
}

/**
 * This function creates a new, empty MsnMessage object.
 *
 * Returns: 
 *    new MsnMessage if successful, else NULL.
 */
MsnMessage *msn_message_new() {
  return g_object_new(MSN_TYPE_MESSAGE, NULL);
}


/**
 * This function creates an MsnMessage object from the passed string.
 * The returned MsnMessage object will be read only.
 *
 * Parameters:
 *    <msgtext> The message as a string. This will usually have been received from the server. 
 *
 * Returns: 
 *    MsnMessage if successful, else NULL.
 */
MsnMessage *msn_message_from_string(const gchar *msgtext) {
  /* Parse the string msgtext into a MsnMessage object
   * 1. split the body from the header
   * 2. split the header into command header and other headers
   */
  gint i;
  gchar **body_split, **headers_split, **single_header_split;
  MsnMessagePrivate *priv;
  MsnMessage *message = msn_message_new();
  priv = MSN_MESSAGE_GET_PRIVATE(message);
  body_split = g_strsplit(msgtext, BODY_SEPERATOR, 2);
  if (get_argc((const gchar **) body_split) == 2) {
    msn_message_set_body(message, body_split[1]);
  } 
  headers_split = g_strsplit(body_split[0], LINE_SEPERATOR, G_MAXINT);
  msn_message_set_command_header_from_string(message, headers_split[0]);
  for (i = 1; i < get_argc((const gchar **) headers_split); i++) {
    single_header_split = g_strsplit(headers_split[i], HEADER_SEPERATOR, 2);
    if (single_header_split[0] == NULL) break; /* for just a command header and no other headers */
    msn_message_set_header(message, single_header_split[0], single_header_split[1]);
    g_strfreev(single_header_split);
  }
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
const gchar *msn_message_get_header(MsnMessage *this, const gchar *name) {  
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
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
const gchar *msn_message_get_body(MsnMessage *this) {
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
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
const gchar * msn_message_get_command(MsnMessage *this) {
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
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
const gchar * const * msn_message_get_command_header(MsnMessage *this) {
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
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
gint msn_message_get_trid(MsnMessage *this) {
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
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
void msn_message_set_header(MsnMessage *this, const gchar *name, const gchar *value) {
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
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
void msn_message_set_body(MsnMessage *this, const gchar *body){
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
  priv->body = g_string_assign(priv->body, body);
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
void msn_message_append_body(MsnMessage *this, const gchar *string){
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
  priv->body = g_string_append(priv->body, string);
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
void msn_message_set_command_header(MsnMessage *this, const gchar * const argv[]){
  gint i = 0;
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
  for (i = 0; i < priv->command_header_length; i++) {
    g_free(priv->command_header[i]);
  }
  priv->command_header_length = get_argc(argv);
  priv->command_header = malloc(priv->command_header_length * sizeof(gchar *));
  for (i = 0; i < priv->command_header_length; i++) {
    priv->command_header[i] = g_strdup(argv[i]);
  }
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
void msn_message_set_command_header_from_string(MsnMessage *this, const gchar *command_hdr){
  gchar **command_header;
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
  command_header = g_strsplit(command_hdr, SPACE_SEPERATOR, G_MAXINT);
  msn_message_set_command_header(this, (const gchar **) command_header);
  g_strfreev(command_header);
}

static void header_concat(gpointer key, gpointer value, gpointer user_data) {
  gchar **header_ptr;
  header_ptr = (gchar **) user_data;
  (*header_ptr) = g_strconcat((*header_ptr), (gchar *) key, HEADER_SEPERATOR, (gchar *) value, LINE_SEPERATOR, NULL);;
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
void msn_message_send(MsnMessage *this, MsnConnection *conn){
  guint written;
  GError *error = NULL;
  gchar *command_header, *headers, **headers_ptr, *str;
  gint i;
  MsnMessagePrivate *priv;
  priv = MSN_MESSAGE_GET_PRIVATE(this);
  /* send command header*/
  command_header = g_strdup(priv->command_header[0]);
  str = g_strdup_printf("%i", trid++);
  command_header = g_strconcat(command_header, SPACE_SEPERATOR, str, NULL);
  g_free(str);
  for (i = 1; i < priv->command_header_length; i++) {
    command_header = g_strconcat(command_header, SPACE_SEPERATOR, priv->command_header[i], NULL);
  }
  command_header = g_strconcat(command_header, LINE_SEPERATOR, NULL);
  g_printf("%s", command_header);
  g_io_channel_write_chars(msn_connection_get_channel(conn), command_header, -1, &written, &error);
  /* send message headers if necessary */
  if (g_hash_table_size(priv->headers) > 0) {
     headers = "";
     headers_ptr = &headers;
     g_hash_table_foreach(priv->headers, header_concat, headers_ptr);
     g_printf("%s", headers);
     g_io_channel_write_chars(msn_connection_get_channel(conn), headers, -1, &written, &error);
  }
  /* send body */
  if (priv->body->len > 0) {
     g_io_channel_write_chars(msn_connection_get_channel(conn), priv->body->str, -1, &written, &error);
  }
  g_io_channel_flush(msn_connection_get_channel(conn), &error);
  g_free(command_header);
}
