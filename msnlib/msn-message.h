/*
 * msn-message.h - Header for MsnMessage
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

#ifndef __MSN_MESSAGE_H__
#define __MSN_MESSAGE_H__

#include <glib.h>
#include <glib-object.h>
#include "msn-connection.h"

G_BEGIN_DECLS

typedef struct _MsnMessage MsnMessage;
typedef struct _MsnMessageClass MsnMessageClass;

struct _MsnMessageClass {
    GObjectClass parent_class;
};

struct _MsnMessage {
    GObject parent;
};

GType msn_message_get_type(void);

/* TYPE MACROS */
#define MSN_TYPE_MESSAGE \
  (msn_message_get_type())
#define MSN_MESSAGE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), MSN_TYPE_MESSAGE, MsnMessage))
#define MSN_MESSAGE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), MSN_TYPE_MESSAGE, MsnMessageClass))
#define MSN_IS_MESSAGE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), MSN_TYPE_MESSAGE))
#define MSN_IS_MESSAGE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), MSN_TYPE_MESSAGE))
#define MSN_MESSAGE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), MSN_TYPE_MESSAGE, MsnMessageClass))

/**
 * This function creates a new, empty MsnMessage object.
 *
 * Returns: 
 *    new MsnMessage if successful, else NULL.
 */
MsnMessage *msn_message_new(); 


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
MsnMessage *msn_message_from_string(const gchar *msgtext); 


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
const gchar *msn_message_get_header(MsnMessage *this, const gchar *name);

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
const gchar *msn_message_get_body(MsnMessage *this);


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
const gchar * msn_message_get_command(MsnMessage *this);


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
const gchar * const * msn_message_get_command_header(MsnMessage *this);


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
gint msn_message_get_trid(MsnMessage *this);
 

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
void msn_message_set_header(MsnMessage *this, const gchar *name, const gchar *value);


/**
 * This function sets the message body. If a body is already set, it will be replaced.
 * The passed body may be freed by the caller after this function returns.
 *
 * Parameters:
 *    <this>  Pointer to the object the method is invoked on. Must be obtained from msn_message_new.
 *    <body>  The message body
 *
 */
void msn_message_set_body(MsnMessage *this, const gchar *body);


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
void msn_message_append_body(MsnMessage *this, const gchar *string);


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
void msn_message_set_command_header(MsnMessage *this, const gchar * const argv[]);



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
void msn_message_set_command_header_from_string(MsnMessage *this, const gchar *command_hdr);


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
void msn_message_send(MsnMessage *this, MsnConnection *conn, GError **err);

G_END_DECLS

#endif /* #ifndef message*/
