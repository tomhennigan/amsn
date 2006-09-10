/** @file cvr0.c CVR0 message handlers */
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

#include <string.h>
#include <glib/gprintf.h>

#include "../msn-connection.h"
#include "../msn-protocol.h"

static void VER_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  /* Get the request we sent */
  gint trid = msn_message_get_trid(message);
  MsnMessage *request = msn_connection_get_sent_message_by_trid(conn, trid);

  /* Check if it is a proper context for this reply */
  if(request != NULL) {
    const gchar *request_command = msn_message_get_command(request);
    if(request_command == NULL || strcmp(request_command, "VER") != 0) {
      g_printf("VER ignored because of bad context.\n");
      return;
    }
  } else {
    g_printf("VER ignored: no context.\n");
    return;
  }

  /* Get the protocol to use */
  const gchar * const *command_header = msn_message_get_command_header(message);
  const gchar *protocol_name = command_header[1];
  if(strcmp(protocol_name, "CVR0") == 0) {
    g_printf("Too bad! Server suggests protocol CVR0. Not much we can do with that...\n");
    return;
  } else {
    const MsnProtocol *protocol = msn_protocol_find(protocol_name);
    
    if(protocol != NULL) {
      conn->protocol = protocol;
      g_printf("Selected protocol %s", protocol_name);
    } else {
      g_printf("Huh? The server suggests a protocol that we don't support!\n");
    }
  }
}


static void CVR_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nCVR handler\n");
}


static MsnCommand CVR_command = {
  { .name        = "CVR" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = CVR_NS_handler
};
 
static MsnCommand VER_command = {
  { .name        = "VER" },
  .has_trid    = TRUE,
  .has_payload = FALSE,
  .handler     = VER_NS_handler
};

static const MsnCommand *cmd_list[] = {
  &CVR_command,
  &VER_command,
  NULL
};


static const MsnProtocol protocol_cvr0 = {
  .name = "CVR0",
  .cmd_list = cmd_list
};


const MsnProtocol *msn_protocol_init_cvr0(void) {
  return &protocol_cvr0;
}
