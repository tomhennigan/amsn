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

G_DEFINE_TYPE(MsnConnection, msn_connection, G_TYPE_OBJECT)

/* private structure */
typedef struct _MsnConnectionPrivate MsnConnectionPrivate;

struct _MsnConnectionPrivate
{
  gboolean connected;
  GIOChannel *channel;
  gint trid;
  MsnConnectionType type;
  GHashTable *sent_messages;
};

struct cmd_handler {
  union ucmdcompare cmd;
  void (*handler) (MsnMessage *msg, MsnConnection *conn);
};

gchar *cached_server = NULL;
gchar *redirected_server = NULL;
gint cached_port = -1;
gint redirected_port = -1;


#define MSN_CONNECTION_GET_PRIVATE(o)     (G_TYPE_INSTANCE_GET_PRIVATE ((o), MSN_TYPE_CONNECTION, MsnConnectionPrivate))

/* type definition stuff --------------------------------------- */
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
/* end type definition stuff ----------------------------------- */


/* private function -------------------------------------------- */
/**
 * this function calculates the next trid to be used
 */
static gint
next_trid(MsnConnection *this) 
{
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(this);
  return (priv->trid)++;
}

/**
 * this function gets the addrinfo struct with the appropriate server and port variables set
 */
static struct addrinfo *
get_msn_server(const gchar *server, gint port)  
{
  struct addrinfo hints;
  struct addrinfo *msn_serv;
  if (server == NULL) server = MSN_DEFAULT_SERVER;
  if (port == -1) port = MSN_DEFAULT_PORT;
  memset(&hints, 0, sizeof(struct addrinfo));
  hints.ai_flags = AI_ADDRCONFIG;
  hints.ai_family = AF_UNSPEC;
  hints.ai_socktype = SOCK_STREAM;
  gchar *port_str = g_strdup_printf("%i", port);
  if (getaddrinfo(server, port_str, &hints, &msn_serv) != 0) {
    g_free(port_str);
    return NULL;
  } else {
    g_free(port_str);
    return msn_serv;
  }
}

/**
 * this function creates a socket connection with the msn server
 */
static int 
get_connected_socket(const gchar *server, gint port) 
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


/**
 * This function checks whether a given command header starts with a payload command
 */
static gboolean
is_payload_command(const gchar *string) 
{
  static const union ucmdcompare cmd_list[] = {
    { "GCF" },
    { .i_cmd = 0 }		// close the list
  };
  GString *command = g_string_new(string);
  if (command->len < 4) return FALSE;
  g_string_truncate(command, 3);
  register guint32 ref_cmd = *((const guint32 *) command->str);
  for (register gint i = 0; cmd_list[i].i_cmd != 0; i++) {
    if (cmd_list[i].i_cmd == ref_cmd) return TRUE;
  }
  return FALSE;
}


/**
 * The VER handler
 */
static void
VER_handler(MsnMessage *message, MsnConnection *conn) 
{
  g_printf("\nVER handler\n");
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(conn);
  gint trid = msn_message_get_trid(message);
  MsnMessage *orig = (MsnMessage *) g_hash_table_lookup(priv->sent_messages, &trid);
  g_hash_table_remove(priv->sent_messages, &trid);
  g_printf("orig command: %s\norig trid   : %i\n",
           msn_message_get_command(orig),
           msn_message_get_trid(orig));
  g_object_unref(orig);
}


/**
 * The USR handler
 */
static void
USR_handler(MsnMessage *message, MsnConnection *conn) 
{
  g_printf("\nUSR handler\n");
}


/**
 * The CVR handler
 */
static void
CVR_handler(MsnMessage *message, MsnConnection *conn) 
{
  g_printf("\nCVR handler\n");
}


/**
 * The GCF handler
 */
static void
GCF_handler(MsnMessage *message, MsnConnection *conn) 
/* GCF payload is in the message body and can be accessed with msn_message_get_body() */
{
  g_printf("\nGCF handler\n");
}


/**
 * The XFR handler
 */
static void
XFR_handler(MsnMessage *message, MsnConnection *conn) 
{
  g_printf("\nXFR handler\n");
  gchar **command_header = (gchar **) msn_message_get_command_header(message);
  if (g_str_equal(command_header[1], "NS")) {
    gchar **ns_address = g_strsplit(command_header[2], ":", 2);
    redirected_server  = g_strdup(ns_address[0]);
    redirected_port    = (gint) g_ascii_strtod(ns_address[1], NULL);
    g_strfreev(ns_address);
  }
}


/**
 * This function calls a message handler depending on its command
 */
static void
handle_message(const gchar *message_str, MsnConnection *conn)
{
  static const struct cmd_handler handler_list[] = {
    { .cmd = { "VER" },    .handler = VER_handler}, 
    { .cmd = { "CVR" },    .handler = CVR_handler},
    { .cmd = { "USR" },    .handler = USR_handler},
    { .cmd = { "XFR" },    .handler = XFR_handler},
    { .cmd = { "GCF" },    .handler = GCF_handler},
    { .cmd = {.i_cmd = 0}, .handler = NULL}		// close the list
  };

  MsnMessage *mess = msn_message_from_string_in(message_str);
  g_printf("<-- %s", message_str);
  register guint32 ref_cmd = *((const guint32 *) msn_message_get_command(mess));
  for (register gint i = 0; handler_list[i].cmd.i_cmd != 0; i++) {
    if(handler_list[i].cmd.i_cmd == ref_cmd) (handler_list[i].handler) (mess, conn);
  }
  g_object_unref(mess);
}


/**
 * This function receives a full message and calls handle_message
 */
static void 
receive_msn_message(GIOChannel *source, GIOCondition condition, gpointer data) 
{
  MsnConnection *conn = (MsnConnection *) data;
  g_assert(MSN_IS_CONNECTION (conn));
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(conn);
  GError *error = NULL;
  gchar *message;
  g_io_channel_read_line(priv->channel, &message, NULL, NULL, &error);
  /* if the current command is a payload command, extract the payload length
   * from the first line (always the last argument) and use that value to
   * read the payload of the message */
  if (is_payload_command(message)) {
    gchar *payload_size_str = g_strrstr(message, " ");
    gsize payload = (gsize) g_ascii_strtod(&(payload_size_str[1]), NULL);
    gchar *payload_str = g_malloc(payload + 1); /* payload is not NULL terminated, so do add \0 */
    g_io_channel_read_chars(priv->channel, payload_str, payload, NULL, &error);
    payload_str[payload] = '\0';
    message = g_strdup_printf("%s\r\n%s", message, payload_str); /* concat the message and the payload */
    g_free(payload_str);
  }
  handle_message(message, conn);
  g_free(message);
}

/**
 * This function sends a message and if it has a trid registers it
 */
static void
send_msn_message(MsnMessage *message, MsnConnection *conn, GError **err)
{
  MsnConnectionPrivate *priv = MSN_CONNECTION_GET_PRIVATE(conn);
  g_printf("--> %s\n", msn_message_to_string(message));
  if (msn_message_get_trid(message) != -1) {
    if (priv->sent_messages == NULL) priv->sent_messages = g_hash_table_new(g_int_hash, g_int_equal);
    gint trid = msn_message_get_trid(message);
    g_hash_table_insert(priv->sent_messages, &trid, message);
  }
  g_io_channel_write_chars(priv->channel, msn_message_to_string(message), -1, NULL, err);
  g_io_channel_flush(priv->channel, err);
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
  GError *error = NULL;
  gchar *cvr_string = g_strdup_printf("CVR 0x0409 linux 2.6 i386 AMSN 1.99.0001 MSMSGS %s\r\n", account);
  MsnMessage *cvr_message = msn_message_from_string_out(cvr_string);
  g_free(cvr_string);
  msn_message_set_trid(cvr_message, next_trid(this));
  send_msn_message(cvr_message, this, &error);
  gchar *usr_string = g_strdup_printf("USR TWN I %s\r\n", account);
  MsnMessage *usr_message = msn_message_from_string_out(usr_string);
  g_free(usr_string);
  msn_message_set_trid(usr_message, next_trid(this));
  send_msn_message(usr_message, this, &error);
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

  /* Send VER message */
  MsnMessage *ver_message = msn_message_from_string_out("VER MSNP13 CVR0\r\n");
  msn_message_set_trid(ver_message, next_trid(conn));
  send_msn_message(ver_message, conn, &error);
  g_io_add_watch(priv->channel, G_IO_IN, (GIOFunc) receive_msn_message, conn);
  return conn;
}
