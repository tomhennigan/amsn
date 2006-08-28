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

#include "msn.h"
#include "msn-connection.h"

GMainLoop *mainloop = NULL;
MsnConnection *conn = NULL;

int
main (int argc,
      char **argv)
{
  g_type_init();
  g_set_prgname("msn-test");
  conn = msn_connection_new(MSN_CONNECTION_TYPE_NS);
  mainloop = g_main_loop_new (NULL, FALSE);
  g_main_loop_run (mainloop);

  return 0;
}
