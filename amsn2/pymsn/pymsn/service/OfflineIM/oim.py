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

from pymsn.service.OfflineIM.constants import *
from pymsn.service.SOAPService import SOAPService
from pymsn.msnp.notification import ProtocolConstant
from pymsn.service.SingleSignOn import *

__all__ = ['OIM']

class OIM(SOAPService):
    def __init__(self, sso, proxies=None):
        self._sso = sso
        self._tokens = {}
        self.__lock_key = ""
        SOAPService.__init__(self, "OIM", proxies)

    def set_lock_key(self, lock_key):
        self.__lock_key = lock_key

    @RequireSecurityTokens(LiveService.MESSENGER_SECURE)
    def Store2(self, callback, errback, from_member_name, friendly_name, 
               to_member_name, session_id, message_number, message_type, message_content):
        import base64
        token = str(self._tokens[LiveService.MESSENGER_SECURE])
        fname = "=?utf-8?B?%s?=" % base64.b64encode(friendly_name)

        content = self.__build_mail_data(session_id, message_number, message_content)

        self.__soap_request(self._service.Store2,
                            (from_member_name, fname, 
                             ProtocolConstant.CVR[4],
                             ProtocolConstant.VER[0],
                             ProtocolConstant.CVR[5],
                             to_member_name,
                             message_number, 
                             token,
                             ProtocolConstant.PRODUCT_ID,
                             self.__lock_key),
                            (message_type, content),
                            callback, errback)

    def _HandleStore2Response(self, callback, errback, response, user_data):
        callback[0](*callback[1:])

    def _HandleStore2Fault(self, callback, errback, soap_response, user_data): 
        error_code = OfflineMessagesBoxError.UNKNOWN
        auth_policy = None
        lock_key_challenge = None

        if soap_response.fault.faultcode.endswith("AuthenticationFailed"):
            error_code = OfflineMessagesBoxError.AUTHENTICATION_FAILED
            auth_policy = soap_response.fault.detail.findtext("./oim:RequiredAuthPolicy")
            lock_key_challenge = soap_response.fault.detail.findtext("./oim:LockKeyChallenge")

            if auth_policy == "":
                auth_policy = None
            if lock_key_challenge == "":
                lock_key_challenge = None

            #print "Authentication failed - policy = %s - lockkey = %s" % (auth_policy, lock_key_challenge)
        elif soap_response.fault.faultcode.endswith("SystemUnavailable"):
            error_code = OfflineMessagesBoxError.SYSTEM_UNAVAILABLE
        elif soap_response.fault.faultcode.endswith("SenderThrottleLimitExceeded"):
            error_code = OfflineMessagesBoxError.SENDER_THROTTLE_LIMIT_EXCEEDED
            
        errback[0](error_code, auth_policy, lock_key_challenge, *errback[1:])

    def __build_mail_data(self, run_id, sequence_number, content):
        import base64
        mail_data = 'MIME-Version: 1.0\r\n'
        mail_data += 'Content-Type: text/plain; charset=UTF-8\r\n'
        mail_data += 'Content-Transfer-Encoding: base64\r\n'
        mail_data += 'X-OIM-Message-Type: OfflineMessage\r\n'
        mail_data += 'X-OIM-Run-Id: {%s}\r\n' % run_id
        mail_data += 'X-OIM-Sequence-Num: %s\r\n\r\n' % sequence_number
        mail_data += base64.b64encode(content)
        return mail_data
    
    def __soap_request(self, method, header_args, body_args, 
                       callback, errback, user_data=None):
        http_headers = method.transport_headers()
        soap_action = method.soap_action()
        
        soap_header = method.soap_header(*header_args)
        soap_body = method.soap_body(*body_args)
        
        method_name = method.__name__.rsplit(".", 1)[1]
        self._send_request(method_name, self._service.url, 
                           soap_header, soap_body, soap_action, 
                           callback, errback, http_headers, user_data)

    def _HandleSOAPFault(self, request_id, callback, errback,
            soap_response, user_data):
        errback[0](None, *errback[1:])
