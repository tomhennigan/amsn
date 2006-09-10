/** @file msn-connection.c Source for the MsnConnection type */
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
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <netdb.h>

#include "msn-protocol.h"
#include "msn-connection.h"

G_DEFINE_TYPE(MsnConnection, msn_connection, G_TYPE_OBJECT)

/* private structure */
typedef struct _MsnConnectionPrivate MsnConnectionPrivate;

struct _MsnConnectionPrivate {
  gboolean connected;
  GIOChannel *channel;
  gint trid;
  MsnConnectionType type;
  GHashTable *sent_messages;
};

#define MSN_CONNECTION_GET_PRIVATE(o)     (G_TYPE_INSTANCE_GET_PRIVATE ((o), MSN_TYPE_CONNECTION, MsnConnectionPrivate))

static gchar *cached_server = NULL;
static gchar *redirected_server = NULL;
static gint cached_port = -1;
static gint redirected_port = -1;

/* type definition stuff --------------------------------------- */

static void msn_connection_dispose (GObject *object);
static void msn_connection_finalize (GObject *object);

static void msn_connection_init (MsnConnection *this)
{
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (this);
  priv->connected = FALSE;
  priv->trid = 1;

  this->protocol = msn_protocol_find("CVR0");
}

static void msn_connection_class_init (MsnConnectionClass *msn_connection_class)
{
  GObjectClass *object_class = G_OBJECT_CLASS (msn_connection_class);
  g_type_class_add_private (msn_connection_class, sizeof (MsnConnectionPrivate));
  object_class->dispose = msn_connection_dispose;
  object_class->finalize = msn_connection_finalize;
}

static void msn_connection_dispose (GObject *object)
{
  //MsnConnection *self = MSN_CONNECTION (object);
  //MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (self);

  /* release any references held by the object here */

  if (G_OBJECT_CLASS (msn_connection_parent_class)->dispose)
    G_OBJECT_CLASS (msn_connection_parent_class)->dispose (object);
}

static void msn_connection_finalize (GObject *object)
{
  //MsnConnection *self = MSN_CONNECTION (object);
  //MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (self);

  G_OBJECT_CLASS (msn_connection_parent_class)->finalize (object);
}

/* end type definition stuff ----------------------------------- */




/* private functions ------------------------------------------- */

/* This function calculates the next trid to be used */
static gint next_trid(MsnConnection *this)
{
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(this);
  return (priv->trid)++;
}

/* This function gets the addrinfo struct with the appropriate server and port variables set */
static struct addrinfo * get_msn_server(const gchar *server,
                                        gint port)
{
  struct addrinfo *msn_serv = NULL;
  struct addrinfo hints;

  if (server == NULL) server = MSN_DEFAULT_SERVER;
  if (port == -1) port = MSN_DEFAULT_PORT;

  memset(&hints, 0, sizeof(struct addrinfo));
  hints.ai_flags = AI_ADDRCONFIG;
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;

  gchar *port_str = g_strdup_printf("%i", port);
  if (getaddrinfo(server, port_str, &hints, &msn_serv) != 0) {
    msn_serv = NULL;
  }

  g_free(port_str);
  return msn_serv;
}

/* This function creates a socket connection with the msn server */
static int get_connected_socket(const gchar *server,
                                gint port)
{
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

  freeaddrinfo(msn_serv);
  return sock;
}


/* This function checks whether a given command header starts with a payload command (for incoming messages!) */
static gboolean has_payload_command(const MsnProtocol *protocol,
                                    const gchar *string)
{
  gchar *cmd_str = g_strndup(string, 3);
  const MsnCommand *command = msn_protocol_find_command(protocol, cmd_str);
  g_free(cmd_str);

  return (command != NULL) ? command->has_payload : FALSE;
}


/* This function calls a message handler depending on its command */
static void handle_message(MsnConnection *this,
                           MsnMessage *msg)
{
  const MsnCommand *command = msn_protocol_find_command(this->protocol, msn_message_get_command(msg));
  if(command != NULL && command->handler != NULL) command->handler(msg, this);
}


/* This function receives a full message and calls handle_message */
static void receive_msn_message(GIOChannel *source,
                                GIOCondition condition,
                                gpointer data)
{
  MsnConnection *conn = (MsnConnection *) data;
  g_assert(MSN_IS_CONNECTION (conn));

  gchar *message = NULL;
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(conn);
  g_io_channel_read_line(priv->channel, &message, NULL, NULL, NULL);

  /* If the current command is a payload command, extract the payload length
   * from the first line (always the last argument) and use that value to
   * read the payload of the message */
  if (has_payload_command(conn->protocol, message)) {
    gchar *payload_size_str = g_strrstr(message, " ");
    gsize payload_size = (gsize) strtoul(&(payload_size_str[1]), NULL, 10);

    /* Read payload and null-terminate it */
    gchar *payload_str = g_malloc(payload_size + 1);
    g_io_channel_read_chars(priv->channel, payload_str, payload_size, NULL, NULL); // TODO: GError** in last argument
    payload_str[payload_size] = '\0';

    /* Create a complete message string by concatenating the payload to the message */
    gchar *to_free = message;
    message = g_strdup_printf("%s%s", message, payload_str);
    g_free(to_free);
    g_free(payload_str);
  }

  g_printf("<-- %s", message);

  MsnMessage *msg = msn_message_from_string(conn->protocol, message);
  handle_message(conn, msg);

  g_object_unref(msg);
  g_free(message);
}


/* This function sends a message and if it has a trid registers it */
static void send_msn_message(MsnConnection *this,
                             MsnMessage *message,
                             GError **error_ptr)
{
  g_return_if_fail (error_ptr == NULL || *error_ptr == NULL);

  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(this);
  GError *error;

  g_printf("--> %s\n", msn_message_to_string(message));

  if (msn_message_get_trid(message) != -1) {
    if (priv->sent_messages == NULL)
      priv->sent_messages = g_hash_table_new_full(g_int_hash, g_int_equal, NULL, g_object_unref);

    gint trid = msn_message_get_trid(message);
    g_hash_table_insert(priv->sent_messages, &trid, message);
  }

  g_io_channel_write_chars(priv->channel, msn_message_to_string(message), -1, NULL, &error);
  if(error != NULL) {
    g_propagate_error(error_ptr, error);
    return;
  }

  g_io_channel_flush(priv->channel, &error);
  if(error != NULL) {
    g_propagate_error(error_ptr, error);
    return;
  }
}

/* end private functions --------------------------------------- */



/**
 * Login to the MSN Messenger Service.
 *
 * This method should only be invoked on a DS or NS connection that did not
 * attempt to login before. If invoked on a SB connection or on a connection that
 * tried to log in already (either successfully or not), it returns immediately.
 *
 * Most of this function executes asynchronously. This function returns immediately
 * after sending the initial USR.
 *
 * This function initiates a chain of actions:
 *   1. This function checks if this MsnConnection object has authenticated already,
 *      if not, it sends the initial USR and updates the object's state accordingly.
 *      This function returns here, the rest of the actions are initiated from the
 *      glib mainloop.
 *
 *   2. When the reply from the server arrives, and that is an USR, the twn_cb 
 *      callback function is called, which will send the Tweener authentication 
 *      request. This should be done using a HTTP library that also utilises the 
 *      glib mainloop, or is just non-blocking so it can be wrapped to run in the 
 *      mainloop. The twn_cb function should make sure that a callback (let's call
 *      it twn_reply_cb) is registered to catch the Tweener reply. The twn_cb 
 *      function must return without delay (i.e. it must not wait for the HTTP 
 *      response).
 *      If the server sent an XFR reply instead of USR, an event is fired to
 *      indicate that we're being redirected [Needs detail], and the sequence
 *      ends here.
 *
 *   3. On arrival of the Tweener response, twn_reply_cb will extract the ticket 
 *      from it, and call msn_connection_set_login_ticket. That function will send
 *      the USR message with the ticket and return.
 *
 *   4. On arrival of the final USR response an event is fired to indicate success
 *      or failure of the authentication. [Needs detail]
 *
 * @param this     Pointer to the object the method is invoked on.
 *                 The pointer must be obtained from msn_connection_new.
 * @param account  The account name to use when logging in
 * @param password The password of the account
 * @param twn_cb   A callback function of type MsnTweenerAuthCallback.
 *
 * @see MsnTweenerAuthCallback
 */
void msn_connection_login(MsnConnection *this,
                          const gchar *account,
                          const gchar *password,
                          MsnTweenerAuthCallback *twn_cb)
{
  GError *error = NULL;

  gchar *cvr_string = g_strdup_printf("CVR 0x0409 linux 2.6 i386 AMSN 1.99.0001 MSMSGS %s", account);
  MsnMessage *cvr_message = msn_message_new_with_command(cvr_string);
  g_free(cvr_string);

  msn_connection_send_message(this, cvr_message, &error);

  gchar *usr_string = g_strdup_printf("USR TWN I %s", account);
  MsnMessage *usr_message = msn_message_new_with_command(usr_string);
  g_free(usr_string);

  msn_connection_send_message(this, usr_message, &error);
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
void msn_connection_set_login_ticket(MsnConnection *this,
                                     const gchar *ticket)
{
}


/**
 * Request an SB connection
 *
 * It may seem strange that this function has no return value, but that is 
 * intentional. When the switchboard connection is established an event is 
 * generated [Needs detail]. So before using this function, be prepared to
 * handle that event, it is the only way to get a pointer to the new 
 * MsnConnection object! Also note that the same type of event is generated 
 * when you've been invited into a switchboard by someone else.
 *
 * The full action chain:
 *   1. This function sends an XFR SB and then returns.
 *   2. When the XFR SB response from the server arrives
 *        - msn_connection_new(MSN_CONNECTION_TYPE_SB) is called to create the
 *          new SB connection
 *        - msn_connection_set_login_ticket is called on the brand new SB 
 *          connection to give it its CKI authentication string. The USR message
 *          is sent by msn_connection_set_login_ticket.
 *   3. When the USR OK response is received from the server, an event is
 *      fired to publish the new connection.
 *
 * This method may only be invoked on an NS connection.
 *
 * @param this Pointer to the object this method is being invoked on.
 *             This must be an MsnConnection object representing a
 *             NS connection that has logged in sucessfully.
 */
void msn_connection_request_sb(MsnConnection *this)
{
}


/**
 * Close a connection.
 *
 * This method will close the connection, and free its resources. You must call
 * this if a connection will not be used anymore, a connection is never closed
 * automatically.
 *
 * @note This won't free the MsnConnection object itself! The object will enter
 *       the disconnected state, and thus cannot be used anymore for communication.
 *
 * @param this Pointer to the object the method is invoked on.
 */
void msn_connection_close(MsnConnection *this)
{
}


/**
 * Create a new MsnConnection object.
 *
 * MSN_CONNECTION_TYPE_DS and MSN_CONNECTION_TYPE_NS are handled the same way,
 * with one exception: NS allows the use of a cached NS address, DS forces the
 * function to connect to the dispatch server.
 *
 * MSN_CONNECTION_TYPE_SB will connect to a switchboard server.
 *
 * No address information needs to be passed to this method because the connection
 * handler will always know them. Internally it keeps one NS server address cached
 * (the one that was successfully connected to most recently). This is only cached
 * in memory, so it is lost when the process terminates.
 * If the MSN_CONNECTION_TYPE_NS type is used when no address is in cache, it is
 * handled the same way as MSN_CONNECTION_TYPE_DS.
 * If an address is in cache and MSN_CONNECTION_TYPE_DS is used, the cached address
 * should not change. If the DS supplies an NS address different from the one cached,
 * the cached address should only change when an attempt to connect to the new
 * address succeeds.
 * When connecting with type MSN_CONNECTION_TYPE_NS, while the previous NS or DS
 * connection redirected, then the address supplied in the redirection command should
 * be favored rather than a cached address. If that connection fails, the next attempt
 * will again use the cached address. The function should only attempt to connect once
 * when called, and should just fail if the connection could not be established.
 *
 * MSN_CONNECTION_TYPE_SB is only for use inside libmsn. Calling with this type
 * directly will always fail. If you want to request a new SB connection, use
 * msn_connection_request_sb() instead.
 *
 * @param type The type of connection to be created.
 * @return a new MsnConnection if successful, NULL otherwise.
 *
 * @see msn_connection_request_sb()
 * @see MsnConnectionType
 */
MsnConnection *msn_connection_new(MsnConnectionType type)
{
  GError *error = NULL;
  gint port;
  gchar *server;
  guint my_socket;

  /* Create a connection to given server */
  switch (type) {
    case MSN_CONNECTION_TYPE_NS:
      server = (redirected_server == NULL) ?  cached_server: redirected_server;
      port = (redirected_port == -1) ? cached_port: redirected_port;
      break;
    case MSN_CONNECTION_TYPE_DS:
      server = NULL;
      port = -1;
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

  MsnConnection *conn = g_object_new(MSN_TYPE_CONNECTION, NULL);
  g_assert (MSN_IS_CONNECTION (conn));
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE (conn);
  priv->type = type;

  /* Create G_IO_Channel */
  priv->channel = g_io_channel_unix_new(my_socket);
  g_io_channel_set_encoding(priv->channel, NULL, NULL);
  g_io_channel_set_line_term(priv->channel, "\r\n", 2);
  g_io_add_watch(priv->channel, G_IO_IN, (GIOFunc) receive_msn_message, conn);

  /* Create VER message */
  gchar *protocols = msn_protocol_get_all_string();
  gchar *ver_message_text = g_strdup_printf("VER %s", protocols);
  MsnMessage *ver_message = msn_message_new_with_command(ver_message_text);
  g_free(ver_message_text);
  g_free(protocols);

  /* Send VER message */
  msn_connection_send_message(conn, ver_message, &error);
  if(error != NULL) {
    g_object_unref(conn);
    return NULL;
  }

  return conn;
}

/**
 * Send a message.
 *
 * If the command of the message is a standard command, a TrId is assigned
 * before actually sending the message.
 *
 * @param this      Pointer to the object this method is being invoked on.
 * @param message   The message to send.
 * @param error_ptr Standard GError mechanism.
 *
 * @see MsnMessage
 */
void msn_connection_send_message(MsnConnection *this,
                                 MsnMessage *message,
                                 GError **error_ptr)
{
  GError *error;

  if(msn_protocol_command_has_trid(this->protocol, msn_message_get_command(message)))
    msn_message_set_trid(message, next_trid(this));

  send_msn_message(this, message, &error);
  if(error != NULL) {
    g_propagate_error(error_ptr, error);
    return;
  }

  return;
}


/**
 * Get a sent message by trid.
 *
 * @param this Pointer to the object this method is being invoked on.
 * @param trid The trid you want to get the associated message of.
 * @return The message if one has been found, NULL otherwise.
 */
MsnMessage * msn_connection_get_sent_message_by_trid(MsnConnection *this,
                                                     gint trid)
{
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(this);
  return (MsnMessage *) g_hash_table_lookup(priv->sent_messages, &trid);
}


/**
 * Get connection type.
 *
 * @param this Pointer to the object this method is being invoked on.
 * @return     The type of the connection
 *
 * @see msn_connection_new for an explanation of the possible return values.
 */
MsnConnectionType msn_connection_get_conn_type(MsnConnection *this)
{
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(this);
  return priv->type;
}
