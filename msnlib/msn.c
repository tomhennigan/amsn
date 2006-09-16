/*
 * msn.c - 
 * Copyright (C) 2006
 * Copyright (C) 2006
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

#include <stdlib.h>
#include <unistd.h>
#include <glib/gprintf.h>

#include "msn.h"
#include "msn-connection.h"

GMainLoop *mainloop = NULL;
MsnConnection *conn = NULL;


/**
 * msn_set_g_main_context 
 *
 * This function should only be called before calling any other libmsn function. 
 * Libmsn will loosely check this. If you don't follow that rule, and libmsn 
 * doesn't detect that, you have successfully created chaos. This function will 
 * fail if context doesn't point to a valid GMainContext object or previous calls 
 * to libmsn functions have been detected.
 *
 * Parameters:
 *    <context> the GMainContext that should be used by libmsn to generate events.
 *
 * Returns: 
 *    This function shall return TRUE on success or FALSE on failure.
 */
gboolean 
msn_set_g_main_context(GMainContext *context) 
{
  g_main_context_ref(context); // ???
  return TRUE;
}

void 
tweener_func(MsnAuthScheme scheme, const char *account, const char *password, const char *auth_string) {

}


int
main(int argc, char **argv)
{
  g_type_init();
  g_set_prgname("msn-test");
  mainloop = g_main_loop_new (NULL, FALSE);
  conn = msn_connection_new(MSN_CONNECTION_TYPE_NS);
  msn_connection_login(conn, "someone@hotmail.com", "something", tweener_func);
  g_main_loop_run (mainloop);
  return 0;
}


