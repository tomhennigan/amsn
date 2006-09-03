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

#include <glib/gprintf.h>

#include "../msn-connection.h"
#include "../msn-protocol.h"

static void VER_NS_handler(MsnMessage *message,
                           MsnConnection *conn)
{
  g_printf("\nVER handler\n");
/*  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(conn);
  gint trid = msn_message_get_trid(message);
  MsnMessage *orig = (MsnMessage *) g_hash_table_lookup(priv->sent_messages, &trid);
  g_hash_table_remove(priv->sent_messages, &trid);
  g_printf("orig command: %s\norig trid   : %i\n",
           msn_message_get_command(orig),
           msn_message_get_trid(orig));
  g_object_unref(orig);
*/
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


MsnProtocol *msn_protocol_init_cvr0(void) {
  return &protocol_cvr0;
}
