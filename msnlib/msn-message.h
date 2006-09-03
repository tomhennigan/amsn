/** @file msn-message.h Header file for the MsnMessage type */
/*
 * Copyright (C) 2006 The aMSN Project
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

G_BEGIN_DECLS

/** The MsnMessage type */
typedef struct _MsnMessage MsnMessage;
typedef struct _MsnMessageClass MsnMessageClass;

/* Compilation errors occur if this include is on top of the file
 * This is because of two-way dependencies */
#include "msn-protocol.h"


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

MsnMessage *msn_message_new(void);
MsnMessage *msn_message_from_string(MsnProtocol *protocol, const gchar *msgtext);
const gchar *msn_message_get_header(MsnMessage *this, const gchar *name);
const gchar *msn_message_get_body(MsnMessage *this);
const gchar * msn_message_get_command(MsnMessage *this);
const gchar * const * msn_message_get_command_header(MsnMessage *this);
gint msn_message_get_trid(MsnMessage *this);
void msn_message_set_header(MsnMessage *this, const gchar *name, const gchar *value);
void msn_message_set_body(MsnMessage *this, const gchar *body);
void msn_message_append_body(MsnMessage *this, const gchar *string);
void msn_message_set_command_header(MsnMessage *this, const gchar * const argv[]);
void msn_message_set_command_header_from_string(MsnMessage *this, const gchar *command_hdr);
void msn_message_set_trid(MsnMessage *this, gint trid);
gchar *msn_message_to_string(MsnMessage *this);

G_END_DECLS



/**
 * Convenience function for creating simple MsnMessage objects
 *
 * @param command MSNP command and arguments, see msn_message_set_command_header_from_string.
 * @return The new MsnMessage if successful, else NULL.
 *
 * @see msn_message_new()
 * @see msn_message_set_command_header_from_string()
 */
static inline MsnMessage *msn_message_new_with_command(const gchar *command) {
  MsnMessage *msg = msn_message_new();
  msn_message_set_command_header_from_string(msg, command);
  return msg;
}


#endif /* #ifndef __MSN_MESSAGE_H__ */
