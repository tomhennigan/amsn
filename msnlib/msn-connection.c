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

#include <arpa/inet.h>
#include <glib/gprintf.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <netdb.h>

#include "msn-connection.h"
#include "msn-message.h"

G_DEFINE_TYPE(MsnConnection, msn_connection, G_TYPE_OBJECT)

/* private structure */
typedef struct _MsnConnectionPrivate MsnConnectionPrivate;

struct _MsnConnectionPrivate
{
  gboolean connected;
  GIOChannel *channel;
};

#define MSN_CONNECTION_GET_PRIVATE(o)     (G_TYPE_INSTANCE_GET_PRIVATE ((o), MSN_TYPE_CONNECTION, MsnConnectionPrivate))

/* type definition stuff */

static void
msn_connection_init (MsnConnection *obj)
{
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (obj);
  priv->connected = FALSE;
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
  //MsnConnection *self = MSN_CONNECTION (object);
  //MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (self);

  /* release any references held by the object here */

  if (G_OBJECT_CLASS (msn_connection_parent_class)->dispose)
    G_OBJECT_CLASS (msn_connection_parent_class)->dispose (object);
}

void
msn_connection_finalize (GObject *object)
{
  //MsnConnection *self = MSN_CONNECTION (object);
  //MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (self);

  G_OBJECT_CLASS (msn_connection_parent_class)->finalize (object);
}

gint min(gint a, gint b) 
{
	return a < b ? a : b;
}

gint max(gint a, gint b) 
{
	return a > b ? a : b;
}

struct in_addr *address_convert(const gchar *address) 
{
	/*
	* Checks whether given address is an IP address or a URL and converts it to a struct in_addr
	*/
	
	gint count, a1, a2, a3, a4;
	gchar c;
	struct hostent *host;
	struct in_addr *addr;
	
	count = sscanf(address,"%d.%d.%d.%d%c", &a1, &a2, &a3, &a4, &c);
	if (count == 4 && max(max(a1, a2), max(a3, a4)) < 256 && min(min(a1, a2), min(a3, a4)) >= 0) {
		// IP address
		addr = malloc(sizeof(struct in_addr));
		if (addr == NULL) {
			// error
			return NULL;
		}
		addr->s_addr = inet_addr(address);
	} else {
		// no IP address
		host = gethostbyname(address);
		if (host == NULL) {
			// error
			return NULL;
		}
		addr = (struct in_addr*) host->h_addr_list[0];
	}
	return addr;
}

struct sockaddr_in *get_msn_server(const char *server, gint port) 
{
  /*
  * if no server is specified (NULL) then MSN_DEFAULT_SERVER is taken
  * if no port is specified (< 0) then MSN_DEFAULT_PORT is taken
  */

  struct sockaddr_in *msn_serv;
  struct in_addr *addr;
  msn_serv = malloc((socklen_t) sizeof(struct sockaddr_in));
  if (msn_serv == NULL) {
    // error
    return NULL;
  }
  if (server == NULL) {
    addr = address_convert(MSN_DEFAULT_SERVER);
  } else {
    addr = address_convert(server);
  }
  if (addr == NULL) {
    // error
    return NULL;
  }
  msn_serv->sin_family = AF_INET;
  if (port < 0) {
    port = MSN_DEFAULT_PORT;
  }
  msn_serv->sin_port = htons(port);
  msn_serv->sin_addr.s_addr = addr->s_addr;
  return msn_serv;
}

static void incoming_message(GIOChannel *source, GIOCondition condition, gpointer data) {
  MsnConnection *conn;
  MsnConnectionPrivate *priv;
  gsize length, terminator_pos;
  gchar *buffer;
  GError *error = NULL;

  conn = (MsnConnection *) data;
  g_assert(MSN_IS_CONNECTION (conn));
  priv = MSN_CONNECTION_GET_PRIVATE(conn);
  g_io_channel_read_line(priv->channel, &buffer, &length, &terminator_pos, &error);
  g_printf("Server: %s\n", buffer);
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
  MsnMessage *mess;
  gint port;
  gchar *server;
  guint my_socket;

  conn = g_object_new(MSN_TYPE_CONNECTION, NULL);
  g_assert (MSN_IS_CONNECTION (conn));
  priv = MSN_CONNECTION_GET_PRIVATE (conn);

  /* Create a connection to given server */
  switch (type) {
    case MSN_NS_CONNECTION:
      server = "207.46.2.111";
      port = 1863;
      break;
    case MSN_DS_CONNECTION:
      port = -1;
      server = NULL;
      break;
    case MSN_SB_CONNECTION:
      break;
    default:
      break;
  }

  /* Create a socket */
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

  /* Construct VER CVR and USR messages */
  mess = msn_message_from_string("VER MSNP13 CVR0\r\n");
  msn_message_send(mess, conn);
  g_object_unref(mess);
  incoming_message(NULL, G_IO_IN, conn);
  mess = msn_message_from_string("CVR 0x0409 winnt 5.1 i386 MSG80BETA 8.0.0.0566 msmsgs someone@hotmail.com\r\n");
  msn_message_send(mess, conn);
  g_object_unref(mess);
  incoming_message(NULL, G_IO_IN, conn);
  mess = msn_message_from_string("USR TWN I someone@hotmail.com\r\n");
  msn_message_send(mess, conn);
  g_object_unref(mess);
  incoming_message(NULL, G_IO_IN, conn);
//  g_io_add_watch(priv->channel, G_IO_IN, (GIOFunc) incoming_message, conn);
  return conn;
}

GIOChannel *msn_connection_get_channel(MsnConnection *this) {
  MsnConnectionPrivate *priv;
  priv = MSN_CONNECTION_GET_PRIVATE(this);
  return priv->channel;
}
