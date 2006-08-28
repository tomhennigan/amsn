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

#include <string.h>
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
  gint trid;
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

static void
msn_connection_dispose (GObject *object)
{
  //MsnConnection *self = MSN_CONNECTION (object);
  //MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (self);

  /* release any references held by the object here */

  if (G_OBJECT_CLASS (msn_connection_parent_class)->dispose)
    G_OBJECT_CLASS (msn_connection_parent_class)->dispose (object);
}

static void
msn_connection_finalize (GObject *object)
{
  //MsnConnection *self = MSN_CONNECTION (object);
  //MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (self);

  G_OBJECT_CLASS (msn_connection_parent_class)->finalize (object);
}

static struct addrinfo *get_msn_server(const gchar *server, gint port)  {
  struct addrinfo hints;
  struct addrinfo *msn_serv;
  if (server == NULL) server = MSN_DEFAULT_SERVER;
  memset(&hints, 0, sizeof(struct addrinfo));
  hints.ai_flags = AI_ADDRCONFIG;
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  if(getaddrinfo(server, g_strdup_printf("%i", port), &hints, &msn_serv) != 0) return NULL;
  else return msn_serv;
}


static int get_connected_socket(const gchar *server, gint port) {
  struct addrinfo *msn_serv = get_msn_server(server, port);
  struct addrinfo *addr;
  int sock = -1;

  for(addr = msn_serv; (sock < 0) && (addr != NULL); addr = addr->ai_next) {
    sock = socket(addr->ai_family, addr->ai_socktype, addr->ai_protocol);
    if(sock < 0) {
      g_debug("socket() call failed.");
    } else if(connect(sock, addr->ai_addr, addr->ai_addrlen) < 0) {
      g_debug("connect() call failed.");
      close(sock);
      sock = -1;
    }
  }
  g_printf("socket: %i\n", sock);

  freeaddrinfo(msn_serv);
  return sock;
}


static void incoming_message(GIOChannel *source, GIOCondition condition, gpointer data) {
  MsnConnection *conn = (MsnConnection *) data;
  g_assert(MSN_IS_CONNECTION (conn));
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(conn);

  gsize length, terminator_pos;
  gchar *buffer;
  GError *error = NULL;
  g_io_channel_read_line(priv->channel, &buffer, &length, &terminator_pos, &error);
  g_printf("Server: %s\n", buffer);
}


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
  return TRUE;
}

/**
 * msn_connection_login
 *
 *
 *    This function will log into the MSN Messenger Service. 
 *    [Protocol sequence: USR, XFR NS]
 *    It delegates the Tweener (HTTP + SOAP) part to the callback function.
 *
 *    This function should only be invoked on a DS or NS connection that did not 
 *    yet login. If invoked on a SB connection or on a connection that logged in
 *    already, it must immediately return with return value 0.
 *
 *    This function executes asynchronously and returns immediately after sending 
 *    the initial USR.
 *
 *    This function initiates a chain of actions:
 *     1. This function checks if this MsnConnection object has authenticated already,
 *        if not, it sends the initial USR and updates the object's state accordingly.
 *        This function returns here, the rest of the actions are initiated from the
 *        glib mainloop.
 *     2. When the reply from the server arrives, and that is an USR, the twn_cb 
 *        callback function is called, which will send the Tweener authentication 
 *        request. This should be done using a HTTP library that also utilises the 
 *        glib mainloop, or is just non-blocking so it can be wrapped to run in the 
 *        mainloop. The twn_cb function should make sure that a callback (let's call
 *        it twn_reply_cb) is registered to catch the Tweener reply. The twn_cb 
 *        function must return without delay (i.e. it must not wait for the HTTP 
 *        response).
 *        If the server sent an XFR reply instead of USR, an event is fired to
 *        indicate that we're being redirected [Needs detail], and the sequence
 *        ends here.
 *     3. On arrival of the Tweener response, twn_reply_cb will extract the ticket 
 *        from it, and call msn_connection_set_login_ticket. That function will send
 *        the USR message with the ticket and return.
 *     4. On arrival of the final USR response an event is fired to indicate success
 *        or failure of the authentication. [Needs detail]
 *
 * Parameters:
 *    <this>     Pointer to the object the method is invoked on. The pointer must be 
 *               obtained from msn_connection_new.
 *    <account>  The account name to use when logging in
 *    <password> The password of the account
 *    <twn_cb>   A callback function as defined by:
 *
 *               typedef void (MsnTweenerAuthCallback) (const char *account, 
 *                                                      const char *password, 
 *                                                      const char *auth_string);
 *               <account>     The account name to use when logging in, this is the same 
 *                             pointer as was passed to msn_connection_login.
 *               <password>    The password of the account, this is the same pointer as was
 *                             passed to msn_connection_login.
 *               <auth_string> is the string obtained from the NS in the USR sequence before
 *                             Tweener authentication.
 *
 *               twn_cb may free the account and password strings, libmsn will not use 
 *               them after doing the callback.
 *               twn_cb must not free auth_string, it is owned by libmsn, and will 
 *               therefore be freed by libmsn.
 *
 * Returns: 
 *    -
 */
void 
msn_connection_login(MsnConnection *this, const gchar *account, const gchar *password, MsnTweenerAuthCallback *twn_cb) 
{
}


/**
 * msn_connection_set_login_ticket 
 *
 * For details about this function, see the descriptions of msn_connection_login
 * and msn_connection_request_sb. If this function is called while the object is
 * not waiting for a Tweener or CKI ticket, it will do nothing and return immediately.
 *
 * Parameters:
 *    <this>   Pointer to the object the method is invoked on. The pointer must be 
 *             obtained from msn_connection_new.
 *    <ticket> is the Tweener or CKI authentication ticket. The ticket string may 
 *             be freed after msn_connection_set_login_ticket returns.
 *
 * Returns: 
 *    -
 */
void 
msn_connection_set_login_ticket(MsnConnection *this, const gchar *ticket)
{
}


/**
 * msn_connection_request_sb
 *
 * It may seem strange that this function has no return value, but that is 
 * intentional. When the switchboard connection is established an event is 
 * generated [Needs detail].  So before using this function, be prepared to
 * handle that event, it is the only way to get a pointer to the new 
 * MsnConnection object! Also note that the same type of event is generated 
 * when you've been invited into a switchboard by someone else.
 *
 *    The full action chain:
 *    1. This function sends an XFR SB and then returns.
 *    2. When the XFR SB response from the server arrives
 *       - msn_connection_new(MSN_CONNECTION_TYPE_SB) is called to create the
 *         new SB connection
 *       - msn_connection_set_login_ticket is called on the brand new SB 
 *         connection to give it its CKI authentication string. The USR message
 *         is sent by msn_connection_set_login_ticket.
 *    3. When the USR OK response is received from the server, an event is
 *       fired to publish the new connection.
 *
 * This method may only be invoked on an NS connection.
 *
 * Parameters:
 *    <this>   Pointer to the object the method is invoked on. The pointer must be 
 *             obtained from msn_connection_new.
 *
 * Returns: 
 *    -
 */
void
msn_connection_request_sb(MsnConnection *this)
{
}


/**
 * msn_connection_close
 *
 * This function will close the connection, and free any resources related to it.
 * A user of libmsn must always call this if a connection will not be used 
 * anymore, a connection is never closed automatically.
 *
 * Please note that this won't free the MsnConnection object itself! The object 
 * will enter the disconnected state, and thus cannot be used anymore. It should 
 * therefore be unref'ed so it will eventually get freed.
 *
 * Parameters:
 *    <this>   Pointer to the object the method is invoked on. The pointer must be 
 *             obtained from msn_connection_new.
 *
 * Returns: 
 *    -
 */
void
msn_connection_close(MsnConnection *this)
{
}



/**
 * msn_connection_new
 *
 * MSN_CONNECTION_TYPE_DS and MSN_CONNECTION_TYPE_NS are handled the same way,
 * with one exception: NS allows the use of a cached NS address, DS forces the
 * function to connect to the dispatch server messenger.hotmail.com:1863.
 *
 * MSN_CONNECTION_TYPE_SB will connect to a switchboard server.
 *
 * No addresses need to be passed because the connection handler will always
 * know them. Internally it keeps one NS server address cached (the one that 
 * was successfully connected to most recently). This is only cached in memory,
 * so it is lost when the process terminates. If the MSN_CONNECTION_TYPE_NS 
 * type is used while no address is in cache, it is handled as 
 * MSN_CONNECTION_TYPE_DS. If an address is in cache and MSN_CONNECTION_TYPE_DS
 * is used, the cached address should not change. If the DS supplies an NS 
 * address different from the one cached, the cached address should only change
 * once a connection to the new address succeeds. When connecting with type 
 * MSN_CONNECTION_TYPE_NS, while the previous NS or DS connection redirected, 
 * then the address supplied in the redirection command should be favored rather
 * than a cached address. If that connection fails, the next attempt will again
 * use the cached address. The function should only attempt to connect once when
 * called, and should just fail if the connection could not be established.
 * So the 'next attemp' is the next call to the function. [Protocol sequences: VER]
 *
 * MSN_CONNECTION_TYPE_SB is only for use inside libmsn. Calling with this type
 * directly will always fail. Request a new SB connection with 
 * msn_connection_request_sb().
 *
 * This function executes synchronously, but if the connection was established
 * successfully, it will prepare the connection object for asynchronous operation
 * by adding sources to the GMainContext specified by a call to 
 * msn_set_g_main_context(). If none has been set, it defaults to NULL, which will
 * make glib use the default context.
 *
 * Parameters:
 *   <type> is either MSN_CONNECTION_TYPE_DS, MSN_CONNECTION_TYPE_NS or 
 *          MSN_CONNECTION_TYPE_SB.
 *
 *
 * Returns: a new MsnConnection if successful, NULL otherwise.
 */
MsnConnection *msn_connection_new(MsnConnectionType type)
{
  GError *error = NULL;
  MsnConnectionPrivate *priv;
  MsnConnection *conn;
  MsnMessage *mess;
  gint port;
  gchar *server;
  guint my_socket;

  /* Create a connection to given server */
  switch (type) {
    case MSN_CONNECTION_TYPE_NS:
      server = "207.46.2.111";
      port = 1863;
      break;
    case MSN_CONNECTION_TYPE_DS:
      port = -1;
      server = NULL;
      break;
    case MSN_CONNECTION_TYPE_SB:
      break;
    default:
      return NULL;
      break;
  }

  /* Create a socket */
  if((my_socket = get_connected_socket(server, port)) < 0) {
    g_debug("No connection could be established.");
    return NULL;
  }
  g_printf("mysocket: %i\n", my_socket);

  conn = g_object_new(MSN_TYPE_CONNECTION, NULL);
  g_assert (MSN_IS_CONNECTION (conn));
  priv = MSN_CONNECTION_GET_PRIVATE (conn);

  /* Create G_IO_Channel */
  priv->channel = g_io_channel_unix_new(my_socket);
  g_io_channel_set_encoding(priv->channel, NULL, NULL);
  g_io_channel_set_line_term(priv->channel, "\r\n", 2);

  /* Construct VER CVR and USR messages */
  mess = msn_message_from_string("VER 4 MSNP13 CVR0\r\n");
  msn_message_send(mess, conn, &error);
  g_object_unref(mess);
  incoming_message(NULL, G_IO_IN, conn);
  mess = msn_message_from_string("CVR 8 0x0409 linux 2.6 i386 AMSN 1.99.0001 MSMSGS someone@hotmail.com\r\n");
  msn_message_send(mess, conn, &error);
  g_object_unref(mess);
  incoming_message(NULL, G_IO_IN, conn);
  mess = msn_message_from_string("USR 33 TWN I someone@hotmail.com\r\n");
  msn_message_send(mess, conn, &error);
  g_object_unref(mess);
  incoming_message(NULL, G_IO_IN, conn);
//  g_io_add_watch(priv->channel, G_IO_IN, (GIOFunc) incoming_message, conn);
  return conn;
}

GIOChannel *msn_connection_get_channel(MsnConnection *this) {
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(this);
  return priv->channel;
}

// Only for use by msn_message_send!!!
gint msn_connection_get_next_trid(MsnConnection *this) {
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(this);
  return (priv->trid)++;
}
