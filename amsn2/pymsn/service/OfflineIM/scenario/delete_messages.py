# -*- coding: utf-8 -*-
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
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
from pymsn.service.OfflineIM.constants import *
from pymsn.service.OfflineIM.scenario.base import BaseScenario

__all__ = ['DeleteMessagesScenario']

class DeleteMessagesScenario(BaseScenario):
    def __init__(self, rsi, callback, errback, message_ids):
        """Accepts an invitation.

            @param rsi: the rsi service
            @param callback: tuple(callable, *args)
            @param errback: tuple(callable, *args)
        """
        BaseScenario.__init__(self, callback, errback)
        self.__rsi = rsi

        self.message_ids = messages_ids

    def execute(self):
        self.__rsi.DeleteMessages((self.__delete_messages_callback,),
                                  (self.__delete_messages_errback,),
                                  self.message_ids)
            
    def __delete_messages_callback(self):
        callback = self._callback
        callback[0](*callback[1:])

    def __delete_messages_errback(self, error_code):
        errcode = OfflineMessagesBoxError.UNKNOWN
        errback = self._errback[0]
        args = self._errback[1:]
        errback(errcode, *args)
