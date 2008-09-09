# -*- coding: utf-8 -*-
#
# pymsn - a python client library for Msn
#
# Copyright (C) 2005-2007 Ali Sabil <ali.sabil@gmail.com>
# Copyright (C) 2006-2007 Ole André Vadla Ravnås <oleavr@gmail.com>
# Copyright (C) 2007 Johann Prieur <johann.prieur@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

"""Client

This module contains the main class used to login into the MSN Messenger
network. The following example demonstrates a simple client.

    >>> import pymsn
    >>>
    >>> server = ('messenger.hotmail.com', 1863)
    >>> account = ('pymsn@hotmail.com', 'pymsn is great !')
    >>>
    >>> client = pymsn.Client(server)
    >>> client.login(*account)
    >>>
    >>> if __name__ == "__main__":
    ...     import gobject
    ...     import logging
    ...     logging.basicConfig(level=logging.DEBUG) # allows us to see the protocol debug
    ...
    ...     mainloop = gobject.MainLoop()
    ...     mainloop.run()

This client will try to login, but will probably fail because of the wrong
password, so let's enhance this client so that it displays an error if the
password was wrong, this will lead us to use the L{pymsn.event} interfaces:

    >>> import pymsn
    >>> import pymsn.event
    >>>
    >>> class ClientEventHandler(pymsn.event.ClientEventInterface):
    ...     def on_client_error(self, error_type, error):
    ...         if error_type == pymsn.event.ClientErrorType.AUTHENTICATION:
    ...             print ""
    ...             print "********************************************************"
    ...             print "* You bummer ! you did input a wrong username/password *"
    ...             print "********************************************************"
    ...         else:
    ...             print "ERROR :", error_type, " ->", error
    >>>
    >>>
    >>> server = ('messenger.hotmail.com', 1863)
    >>> account = ('pymsn@hotmail.com', 'pymsn is great !')
    >>>
    >>> client = pymsn.Client(server)
    >>> client_events_handler = ClientEventHandler(client)
    >>>
    >>> client.login(*account)
    >>>
    >>> if __name__ == "__main__":
    ...     import gobject
    ...     import logging
    ...
    ...     logging.basicConfig(level=logging.DEBUG) # allows us to see the protocol debug
    ...
    ...     mainloop = gobject.MainLoop()
    ...     mainloop.run()

"""

import pymsn.profile as profile
import pymsn.msnp as msnp

import pymsn.service.SingleSignOn as SSO
import pymsn.service.AddressBook as AB
import pymsn.service.OfflineIM as OIM
import pymsn.service.Spaces as Spaces

from pymsn.util.decorator import rw_property
from pymsn.transport import *
from pymsn.switchboard_manager import SwitchboardManager
from pymsn.msnp2p import P2PSessionManager
from pymsn.p2p import MSNObjectStore
from pymsn.conversation import SwitchboardConversation, \
    ExternalNetworkConversation
from pymsn.event import ClientState, ClientErrorType, \
    AuthenticationError, EventsDispatcher

import logging

__all__ = ['Client']

logger = logging.getLogger('client')

class Client(EventsDispatcher):
    """This class provides way to connect to the notification server as well
    as methods to manage the contact list, and the personnal settings.
        @sort: __init__, login, logout, state, profile, address_book,
                msn_object_store, oim_box, spaces"""

    def __init__(self, server, proxies={}, transport_class=DirectConnection):
        """Initializer

            @param server: the Notification server to connect to.
            @type server: tuple(host, port)

            @param proxies: proxies that we can use to connect
            @type proxies: {type: string => L{gnet.proxy.ProxyInfos}}

            @param transport_class: the transport class to use for the network
                    connection
            @type transport_class: L{pymsn.transport.AbstractTransport}"""
        EventsDispatcher.__init__(self)

        self.__state = ClientState.CLOSED

        self._proxies = proxies
        self._transport_class = transport_class
        self._proxies = proxies

        self._transport = transport_class(server, ServerType.NOTIFICATION,
                self._proxies)
        self._protocol = msnp.NotificationProtocol(self, self._transport,
                self._proxies)

        self._switchboard_manager = SwitchboardManager(self)
        self._switchboard_manager.register_handler(SwitchboardConversation)

        self._p2p_session_manager = P2PSessionManager(self)
        self._msn_object_store = MSNObjectStore(self)

        self._external_conversations = {}

        self._sso = None

        self._profile = None
        self._address_book = None
        self._oim_box = None

        self.__die = False
        self.__connect_transport_signals()
        self.__connect_protocol_signals()
        self.__connect_switchboard_manager_signals()

    ### public:
    @property
    def msn_object_store(self):
        """The MSNObjectStore instance associated with this client.
            @type: L{MSNObjectStore<pymsn.p2p.MSNObjectStore>}"""
        return self._msn_object_store

    @property
    def profile(self):
        """The profile of the current user
            @type: L{User<pymsn.profile.Profile>}"""
        return self._profile

    @property
    def address_book(self):
        """The address book of the current user
            @type: L{AddressBook<pymsn.service.AddressBook>}"""
        return self._address_book

    @property
    def oim_box(self):
        """The offline IM for the current user
            @type: L{OfflineIM<pymsn.service.OfflineIM>}"""
        return self._oim_box

    @property
    def spaces(self):
        """The MSN Spaces of the current user
            @type: L{Spaces<pymsn.service.Spaces>}"""
        return self._spaces

    @property
    def state(self):
        """The state of this Client
            @type: L{pymsn.event.ClientState}"""
        return self.__state

    def login(self, account, password):
        """Login to the server.

            @param account: the account to use for authentication.
            @type account: utf-8 encoded string

            @param password: the password needed to authenticate to the account
            @type password: utf-8 encoded string
            """
        if (self._state != ClientState.CLOSED):
            logger.warning('login already in progress')
        self.__die = False
        self._profile = profile.Profile((account, password), self._protocol)
        self.__connect_profile_signals()
        self._transport.establish_connection()
        self._state = ClientState.CONNECTING

    def logout(self):
        """Logout from the server."""
        if self.__state != ClientState.OPEN: # FIXME: we need something better
            return
        self.__die = True
        self._protocol.signoff()
        self._switchboard_manager.close()
        self.__state = ClientState.CLOSED

    ### protected:
    @rw_property
    def _state():
        def fget(self):
            return self.__state
        def fset(self, state):
            self.__state = state
            self._dispatch("on_client_state_changed", state)
        return locals()

    def _register_external_conversation(self, conversation):
        for contact in conversation.participants:
            break

        if contact in self._external_conversations:
            logger.warning("trying to register an external conversation twice")
            return
        self._external_conversations[contact] = conversation

    def _unregister_external_conversation(self, conversation):
        for contact in conversation.participants:
            break
        del self._external_conversations[contact]

    ### private:
    def __connect_profile_signals(self):
        """Connect profile signals"""
        def property_changed(profile, pspec):
            method_name = "on_profile_%s_changed" % pspec.name.replace("-", "_")
            self._dispatch(method_name)

        self.profile.connect("notify::presence", property_changed)
        self.profile.connect("notify::display-name", property_changed)
        self.profile.connect("notify::personal-message", property_changed)
        self.profile.connect("notify::current-media", property_changed)
        self.profile.connect("notify::msn-object", property_changed)

    def __connect_contact_signals(self, contact):
        """Connect contact signals"""
        def event(contact, *args):
            event_name = args[-1]
            event_args = args[:-1]
            method_name = "on_contact_%s" % event_name.replace("-", "_")
            self._dispatch(method_name, contact, *event_args)

        def property_changed(contact, pspec):
            method_name = "on_contact_%s_changed" % pspec.name.replace("-", "_")
            self._dispatch(method_name, contact)

        contact.connect("notify::memberships", property_changed)
        contact.connect("notify::presence", property_changed)
        contact.connect("notify::display-name", property_changed)
        contact.connect("notify::personal-message", property_changed)
        contact.connect("notify::current-media", property_changed)
        contact.connect("notify::msn-object", property_changed)
        contact.connect("notify::client-capabilities", property_changed)

        def connect_signal(name):
            contact.connect(name, event, name)
        connect_signal("infos-changed")

    def __connect_transport_signals(self):
        """Connect transport signals"""
        def connect_success(transp):
            self._sso = SSO.SingleSignOn(self.profile.account,
                                         self.profile.password,
                                         self._proxies)
            self._address_book = AB.AddressBook(self._sso, self._proxies)
            self.__connect_addressbook_signals()
            self._oim_box = OIM.OfflineMessagesBox(self._sso, self, self._proxies)
            self.__connect_oim_box_signals()
            self._spaces = Spaces.Spaces(self._sso, self._proxies)

            self._state = ClientState.CONNECTED

        def connect_failure(transp, reason):
            self._dispatch("on_client_error", ClientErrorType.NETWORK, reason)
            self._state = ClientState.CLOSED

        def disconnected(transp, reason):
            if not self.__die:
                self._dispatch("on_client_error", ClientErrorType.NETWORK, reason)
            self.__die = False
            self._state = ClientState.CLOSED

        self._transport.connect("connection-success", connect_success)
        self._transport.connect("connection-failure", connect_failure)
        self._transport.connect("connection-lost", disconnected)

    def __connect_protocol_signals(self):
        """Connect protocol signals"""
        def state_changed(proto, param):
            state = proto.state
            if state == msnp.ProtocolState.AUTHENTICATING:
                self._state = ClientState.AUTHENTICATING
            elif state == msnp.ProtocolState.AUTHENTICATED:
                self._state = ClientState.AUTHENTICATED
            elif state == msnp.ProtocolState.SYNCHRONIZING:
                self._state = ClientState.SYNCHRONIZING
            elif state == msnp.ProtocolState.SYNCHRONIZED:
                self._state = ClientState.SYNCHRONIZED
            elif state == msnp.ProtocolState.OPEN:
                self._state = ClientState.OPEN
                im_contacts = self.address_book.contacts
                for contact in im_contacts:
                    self.__connect_contact_signals(contact)

        def authentication_failed(proto):
            self._dispatch("on_client_error", ClientErrorType.AUTHENTICATION,
                           AuthenticationError.INVALID_USERNAME_OR_PASSWORD)
            self.__die = True
            self._transport.lose_connection()

        def unmanaged_message_received(proto, sender, message):
            if sender in self._external_conversations:
                conversation = self._external_conversations[sender]
                conversation._on_message_received(message)
            else:
                conversation = ExternalNetworkConversation(self, [sender])
                self._register_external_conversation(conversation)
                if self._dispatch("on_invite_conversation", conversation) == 0:
                    logger.warning("No event handler attached for conversations")
                conversation._on_message_received(message)

        self._protocol.connect("notify::state", state_changed)
        self._protocol.connect("authentication-failed", authentication_failed)
        self._protocol.connect("unmanaged-message-received", unmanaged_message_received)

    def __connect_switchboard_manager_signals(self):
        """Connect Switchboard Manager signals"""
        def handler_created(switchboard_manager, handler_class, handler):
            if handler_class is SwitchboardConversation:
                if self._dispatch("on_invite_conversation", handler) == 0:
                    logger.warning("No event handler attached for conversations")
            else:
                logger.warning("Unknown Switchboard Handler class %s" % handler_class)

        self._switchboard_manager.connect("handler-created", handler_created)

    def __connect_addressbook_signals(self):
        """Connect AddressBook signals"""
        def event(address_book, *args):
            event_name = args[-1]
            event_args = args[:-1]
            if event_name == "messenger-contact-added":
                self.__connect_contact_signals(event_args[0])
            method_name = "on_addressbook_%s" % event_name.replace("-", "_")
            self._dispatch(method_name, *event_args)
        def error(address_book, error_code):
            self._dispatch("on_client_error", ClientErrorType.ADDRESSBOOK, error_code)
            self.__die = True
            self._transport.lose_connection()

        self.address_book.connect('error', error)

        def connect_signal(name):
            self.address_book.connect(name, event, name)

        connect_signal("messenger-contact-added")
        connect_signal("contact-deleted")
        connect_signal("contact-blocked")
        connect_signal("contact-unblocked")
        connect_signal("group-added")
        connect_signal("group-deleted")
        connect_signal("group-renamed")
        connect_signal("group-contact-added")
        connect_signal("group-contact-deleted")

    def __connect_oim_box_signals(self):
        """Connect Offline IM signals"""
        def event(oim_box, *args):
            method_name = "on_oim_%s" % args[-1].replace("-", "_")
            self._dispatch(method_name, *args[:-1])
        def state_changed(oim_box, pspec):
            self._dispatch("on_oim_state_changed", oim_box.state)
        def error(oim_box, error_code):
            self._dispatch("on_client_error", ClientErrorType.OFFLINE_MESSAGES, error_code)

        self.oim_box.connect("notify::state", state_changed)
        self.oim_box.connect('error', error)

        def connect_signal(name):
            self.oim_box.connect(name, event, name)
        connect_signal("messages-received")
        connect_signal("messages-fetched")
        connect_signal("message-sent")
        connect_signal("messages-deleted")
