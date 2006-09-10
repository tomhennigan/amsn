/** @file msn-protocol.h MSN Protocol header file */
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

#ifndef __MSN_PROTOCOL_H__
#define __MSN_PROTOCOL_H__

#include <glib.h>

typedef struct _MsnCommand MsnCommand;
typedef struct _MsnProtocol MsnProtocol;

/* Compilation errors occur if these includes are on top of the file
 * This is because of two-way dependencies */
#include "msn-message.h"
#include "msn-connection.h"

/**
 * Callback that handles a message with a certain command.
 *
 * @param msg  The incoming message
 * @param conn The connection where the message came in
 */
typedef void (MsnCommandHandler)(MsnMessage *msg, MsnConnection *conn);


struct _MsnCommand{
  union {
    guint32           name_u32;        ///< The command name as an integer value
    gchar             name[4];         ///< The command name, e.g.: "CVR"
  };
  gboolean            has_trid;        ///< Whether the command has a Transaction ID
  gboolean            has_payload;     ///< Whether the command has a Payload (server to client)
  MsnCommandHandler * handler;         ///< The handler function to be invoked when this command is received
};

struct _MsnProtocol {
  const gchar * name;                  ///< The protocol name as used in the VER command, e.g.: "MSNP13"
  const MsnCommand * const * cmd_list; ///< Pointer to an array of MsnCommand structures
};


typedef const MsnProtocol * (MsnProtocolInitializer) (void);


const MsnProtocol *msn_protocol_find(const gchar *protocol_name);
const MsnCommand *msn_protocol_find_command(const MsnProtocol *protocol, const gchar *command);
gchar *msn_protocol_get_all_string();


/* This function determines whether a message needs a TrId */
static inline gboolean msn_protocol_command_has_trid(const MsnProtocol *protocol,
                                                     const gchar *cmd_str)
{
  const MsnCommand *command = msn_protocol_find_command(protocol, cmd_str);
  return (command != NULL) ? command->has_trid : FALSE;
}

#endif /* #ifndef __MSN_PROTOCOL_H__ */
