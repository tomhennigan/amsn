/** @file msn-connection.h Header file for the MsnConnection type. */
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

#ifndef __MSN_CONNECTION_H__
#define __MSN_CONNECTION_H__

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define MSN_DEFAULT_SERVER	"messenger.hotmail.com"
#define MSN_DEFAULT_PORT	1863

/** MsnConnection type. */
typedef struct _MsnConnection MsnConnection;
typedef struct _MsnConnectionClass MsnConnectionClass;


/**
 * Enum used to specify the type of a MsnConnection.
 *
 * @see msn_connection_new()
 */
typedef enum {
  MSN_CONNECTION_TYPE_DS,  ///< Dispatch Server Connection. Forces connection to the dispatch server,
                           ///< otherwise the same as MSN_CONNECTION_TYPE_NS.
  MSN_CONNECTION_TYPE_NS,  ///< Notification Server Connection.
  MSN_CONNECTION_TYPE_SB   ///< Switchboard Connection. Use msn_connection_request_sb() to get a connection of this type.
} MsnConnectionType;


/* Compilation errors occur if these includes are on top of the file
 * This is because of two-way dependencies */
#include "msn-protocol.h"
#include "msn-message.h"

/**
 * Prototype for callback function used in Tweener authentication.
 *
 * This function may free the \a account and \a password strings, however, it must NOT free \a auth_string which is
 * owned by libmsn, and will therefore also be freed by libmsn.
 *
 * @param account     The account name to use when logging in, this is the same pointer as was passed to
 *                    msn_connection_login().
 * @param password    The password of the account, this is the same pointer as was passed to msn_connection_login.
 * @param auth_string This is the string obtained from the NS in the USR sequence just before Tweener authentication.
 *
 * @see msn_connection_login()
 */
typedef void (MsnTweenerAuthCallback) (const gchar *account, const gchar *password, const gchar *auth_string);


struct _MsnConnectionClass {
    GObjectClass parent_class;
};

struct _MsnConnection {
    GObject parent;
    MsnProtocol *protocol;
};

GType msn_connection_get_type(void);

/* TYPE MACROS */
#define MSN_TYPE_CONNECTION \
  (msn_connection_get_type())
#define MSN_CONNECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), MSN_TYPE_CONNECTION, MsnConnection))
#define MSN_CONNECTION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), MSN_TYPE_CONNECTION, MsnConnectionClass))
#define MSN_IS_CONNECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), MSN_TYPE_CONNECTION))
#define MSN_IS_CONNECTION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), MSN_TYPE_CONNECTION))
#define MSN_CONNECTION_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), MSN_TYPE_CONNECTION, MsnConnectionClass))

void              msn_connection_register_message(MsnConnection *this, MsnMessage *message);
MsnConnection *   msn_connection_new(MsnConnectionType type);
GIOChannel *      msn_connection_get_channel(MsnConnection *this);
gint              msn_connection_get_next_trid(MsnConnection *this);
void              msn_connection_login(MsnConnection *this, const gchar *account,
                                       const gchar *password, MsnTweenerAuthCallback *twn_cb);
void              msn_connection_set_login_ticket(MsnConnection *this, const gchar *ticket);
void              msn_connection_request_sb(MsnConnection *this);
void              msn_connection_close(MsnConnection *this);
void              msn_connection_send_message(MsnConnection *this, MsnMessage *message, GError **error_ptr);
MsnConnectionType msn_connection_get_conn_type(MsnConnection *this);
G_END_DECLS

#endif /* #ifndef __MSN_CONNECTION_H__*/
