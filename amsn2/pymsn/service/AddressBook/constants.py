# -*- coding: utf-8 -*-
#
# pymsn - a python client library for Msn
#
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

__all__ = ['AddressBookError', 'AddressBookState']

class AddressBookError(object):
    UNKNOWN = 0

    CONTACT_ALREADY_EXISTS  = 1
    CONTACT_DOES_NOT_EXIST  = 2
    INVALID_CONTACT_ADDRESS = 3

    GROUP_ALREADY_EXISTS = 4
    GROUP_DOES_NOT_EXIST = 5
    CONTACT_NOT_IN_GROUP = 6

class AddressBookState(object):
    """Addressbook synchronization state.

    An adressbook is said to be synchronized when it
    matches the addressbook stored on the server."""

    NOT_SYNCHRONIZED = 0
    """The addressbook is not synchronized yet"""
    SYNCHRONIZING = 1
    """The addressbook is being synchronized"""
    SYNCHRONIZED = 2
    """The addressbook is already synchronized"""
