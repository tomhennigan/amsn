/** @file msn-protocol.c MSN Protocol implementation */
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

#include "msn-connection.h"
#include "msn-protocol.h"

/* prototypes for protocol initializers */
const MsnProtocol *msn_protocol_init_cvr0(void);
const MsnProtocol *msn_protocol_init_msnp13(void);


static gboolean protocol_initialized = FALSE;
static GHashTable *protocols = NULL;
static MsnProtocolInitializer *protocol_initializers[] = {
  msn_protocol_init_cvr0,
  msn_protocol_init_msnp13,
  NULL
};


/* This function initializes the protocol manager */
static void msn_protocol_init(void) {
  g_return_if_fail(!protocol_initialized);
  protocol_initialized = TRUE;

  protocols = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

  for(gint i = 0; protocol_initializers[i] != NULL; i++) {
    const MsnProtocol *protocol = protocol_initializers[i]();
    g_hash_table_insert(protocols, g_strdup(protocol->name), (gpointer) protocol);
  }
}

/* This function looks up the MsnProtocol structure with the given name. */
const MsnProtocol *msn_protocol_find(const gchar *protocol_name) {
  g_assert(protocol_name != NULL);

  if(!protocol_initialized) msn_protocol_init();
  return (const MsnProtocol *) g_hash_table_lookup(protocols, protocol_name);
}


/* This function looks up a command in a protocol */
const MsnCommand *msn_protocol_find_command(const MsnProtocol *protocol,
                                      const gchar *command)
{
  const MsnCommand * const *cmd_list = protocol->cmd_list;
  register guint32 ref_cmd = *((const guint32 *) command);

  for (register gint i = 0; cmd_list[i] != NULL; i++) {
    if(cmd_list[i]->name_u32 == ref_cmd) return cmd_list[i];
  }

  return NULL;
}


static void add_next_protocol(gpointer key, gpointer value, gpointer user_data) {
  GString *string = *((GString **) user_data);

  if(value != NULL) {
    const MsnProtocol *protocol = (const MsnProtocol *) value;
    if(string == NULL) string = g_string_new(protocol->name);
    else g_string_append_printf(string, " %s", protocol->name);
    *((GString **) user_data) = string;
  }
}

/* This function returns the names of all supported protocols, separated by the given separator. */
gchar *msn_protocol_get_all_string() {
  if(!protocol_initialized) msn_protocol_init();

  GString *protocol_names = NULL;
  g_hash_table_foreach(protocols, add_next_protocol, &protocol_names);
  return ((protocol_names != NULL) ? g_string_free(protocol_names, FALSE) : NULL);
}
