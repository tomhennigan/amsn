/*
 * msn-connection.c - Source for MsnConnection
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


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <netdb.h>

#include "msn-connection.h"

#define g_printf printf

G_DEFINE_TYPE(MsnConnection, msn_connection, G_TYPE_OBJECT)

/* private structure */
typedef struct _MsnConnectionPrivate MsnConnectionPrivate;

struct _MsnConnectionPrivate
{
  gboolean connected;
  GIOChannel *channel;
  guint trid;
};

#define MSN_CONNECTION_GET_PRIVATE(o)     (G_TYPE_INSTANCE_GET_PRIVATE ((o), MSN_TYPE_CONNECTION, MsnConnectionPrivate))

/* type definition stuff */

static void
msn_connection_init (MsnConnection *obj)
{
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (obj);
  priv->connected = FALSE;
  priv->trid = 1;
}

static void msn_connection_dispose (GObject *object);
static void msn_connection_finalize (GObject *object);

static void
msn_connection_class_init (MsnConnectionClass *msn_connection_class)
{
  GObjectClass *object_class = G_OBJECT_CLASS (msn_connection_class);

  g_type_class_add_private (msn_connection_class, sizeof (MsnConnectionPrivate));

  object_class->dispose = msn_connection_dispose;
  object_class->finalize = msn_connection_finalize;
}

void
msn_connection_dispose (GObject *object)
{
  MsnConnection *self = MSN_CONNECTION (object);
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (self);

  /* release any references held by the object here */

  if (G_OBJECT_CLASS (msn_connection_parent_class)->dispose)
    G_OBJECT_CLASS (msn_connection_parent_class)->dispose (object);
}

void
msn_connection_finalize (GObject *object)
{
  MsnConnection *self = MSN_CONNECTION (object);
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (self);

  G_OBJECT_CLASS (msn_connection_parent_class)->finalize (object);
}

struct sockaddr_in *get_msn_server(const char *server, gint port) {
  /*
  * if no server is specified (NULL) then MSN_DEFAULT_SERVER is taken
  * if no port is specified (< 0) then MSN_DEFAULT_PORT is taken
  */

  struct sockaddr_in *msn_serv;
  struct in_addr *addr;
  struct hostent *host;
  msn_serv = malloc((socklen_t) sizeof(struct sockaddr_in));
  if (msn_serv == NULL) {
    // error
    return NULL;
  }
  if (server == NULL) {
    host = gethostbyname(MSN_DEFAULT_SERVER);
  } else {
    host = gethostbyname(server);
  }
  if (host == NULL) {
    // error
    return NULL;
  }
  addr = (struct in_addr*) host->h_addr_list[0];
  msn_serv->sin_family = AF_INET;
  if (port < 0) {
    port = MSN_DEFAULT_PORT;
  }
  msn_serv->sin_port = htons(port);
  msn_serv->sin_addr.s_addr = addr->s_addr;
  return msn_serv;
}



/**
 * msn_connection_connect
 *
 *
 * Returns: MsnConnection if successful, NULL if not successfull.
 */
MsnConnection *msn_connection_new(MsnConnectionType type)
{
  MsnConnectionPrivate *priv;
  MsnConnection *conn;
  guint written;
  gint port, i;
  gchar *server, *buffer;
  GError *error = NULL;
  guint err, my_socket;
  GIOStatus status;

  conn = g_object_new(MSN_TYPE_CONNECTION, NULL);
  g_assert (MSN_IS_CONNECTION (conn));

  priv = MSN_CONNECTION_GET_PRIVATE (conn);

  buffer = malloc(512 * sizeof(gchar));

  /* Create a connection to given server */
  switch (type) {
    case MSN_NS_CONNECTION:
/*      if (cached) {
        port = cached_port;
        server = cached_server;
        break;
      }*/
    case MSN_DS_CONNECTION:
      port = -1;
      server = NULL;
      break;
    case MSN_SB_CONNECTION:
      break;
    default:
      break;
  }

  my_socket = socket(AF_INET, SOCK_STREAM, 0);
  if (my_socket == -1) {
    g_debug("socket call failed");
    return NULL;
  }
  if (connect(my_socket, (struct sockaddr *) get_msn_server(server, port), (socklen_t) sizeof(struct sockaddr_in)) != 0) {
    g_debug("connect call failed");
    return NULL;
  }

  /* Create G_IO_Channel */
  priv->channel = g_io_channel_unix_new(my_socket);
  g_io_channel_set_encoding(priv->channel, NULL, NULL);
  g_io_channel_set_line_term(priv->channel, "\r\n", 2);
  g_printf("connected to server!\n");
  g_printf("sending VER 1 MSNP13 CVR0\\r\\n\n");
  status = g_io_channel_write_chars(priv->channel, "VER 1 MSNP13 CVR0\r\n", -1, &written, &error);
  g_io_channel_flush(priv->channel, &error);
  g_printf("status: %i\n", status);
  g_printf("written %i\n", written);
  status = g_io_channel_read_chars(priv->channel, &buffer[0], 19, &written, &error);
  g_printf("status: %i\n", status);
  g_printf("written %i\n", written);
  g_printf("return: ");
  for (i = 0; i < 19; i++) {
    g_printf("%c", buffer[i]);
  }
  g_printf("\n");
/*  g_printf("sending CVR 2 0x0409 winnt 5.1 i386 MSG80BETA 8.0.0566 msmsgs roelofkemp@hotmail.com\\r\\n\n");
  err = write(my_socket, "CVR 2 0x0409 winnt 5.1 i386 MSG80BETA 8.0.0566 msmsgs roelofkemp@hotmail.com\r\n", strlen("CVR 2 0x0409 winnt 5.1 i386 MSG80BETA 8.0.0566 msmsgs roelofkemp@hotmail.com\r\n") + 1);*/
/*  g_io_channel_shutdown(priv->channel, TRUE, &error);*/
  close(my_socket);
  return NULL;
}

