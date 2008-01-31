# -*- coding: utf-8 -*-
#
# pymsn - a python client library for Msn
#
# Copyright (C) 2007 Youness Alaoui <kakaroto@users.sourceforge.net>
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

from pymsn.service.SOAPService import SOAPService
from pymsn.service.SingleSignOn import *

__all__ = ['ContactCardService']

class ContactCardSubElement(object):
    def __init__(self, xml):
        self.type = xml.element.attrib["type"]
        self.last_updated = xml.element.attrib["lastUpdated"]
        self.description = xml.findtext("./spaces:description")
        self.title = xml.findtext("./spaces:title")
        self.tooltip = xml.findtext("./spaces:tooltip")
        self.url = xml.findtext("./spaces:url")

        if self.type == "Photo":
            self.thumbnail_url = xml.findtext("./spaces:thumbnailUrl")
            self.web_ready_url = xml.findtext("./spaces:webReadyUrl")
            self.album_name = xml.findtext("./spaces:albumName")
            # FIXME The "xsi:type" attribute is missing.. but do we need it ? what is it ?

    def __str__(self):
        ret = "    SubElement type %s - title %s - url %s - tooltip %s\n" % (self.type, self.title, self.url, self.tooltip)
        try:
            ret += "        album name %s  - thumbnail url %s - web ready url %s\n" % (self.album_name, self.thumbnail_url, self.web_ready_url)
        except AttributeError:
            pass

        return ret

class ContactCardElement(object):
    def __init__(self, xml):
        self.type = xml.element.attrib["type"]
        self.title = xml.findtext("./spaces:title")
        self.url = xml.findtext("./spaces:url")
        self.total_new_items = xml.findtext("./spaces:totalNewItems")
        
        self.sub_elements = []
        all_subelements = xml.findall("./spaces:subElement")
        for e in all_subelements:
            self.sub_elements.append(ContactCardSubElement(e))

    def __str__(self):
        ret = "  Element type %s - title %s - url %s\n" % (self.type, self.title, self.url)
        for s in self.sub_elements:
            ret += "%s\n" % str(s)
            
        return ret

class ContactCard(object):
    def __init__(self, xml):
        self.storage_auth_cache = xml.findtext("./spaces:storageAuthCache")
        self.last_update = xml.findtext("./spaces:lastUpdate")
        
        elements_xml = xml.find("./spaces:elements")
        self.returned_matches = elements_xml.element.attrib["returnedMatches"];
        self.total_matches = elements_xml.element.attrib["totalMatches"];
        try:
            self.display_name = elements_xml.element.attrib["displayName"];
        except KeyError:
            self.display_name = ""

        try:
            self.display_picture_url = elements_xml.element.attrib["displayPictureUrl"];
        except KeyError:
            self.display_picture_url = ""
        
        self.elements = []
        all_elements = xml.findall("./spaces:elements/spaces:element")
        for e in all_elements:
            self.elements.append(ContactCardElement(e))

    def __str__(self):
        ret = "matches %s\n" % self.returned_matches
        for s in self.elements:
            ret += "%s\n" % str(s)
        return ret

class ContactCardService(SOAPService):
    def __init__(self, sso, proxies=None):
        self._sso = sso
        self._tokens = {}
        SOAPService.__init__(self, "Spaces", proxies)


    @RequireSecurityTokens(LiveService.SPACES)
    def GetXmlFeed(self, callback, errback, contact):
        self.__soap_request(self._service.GetXmlFeed,
                            (contact.cid),
                            callback, errback)
    
    def _HandleGetXmlFeedResponse(self, callback, errback, response, user_data):
        if response is not None:
            callback[0](ContactCard(response.find("./spaces:contactCard")), *callback[1:])
        else:
            callback[0](None, *callback[1:])

    def __soap_request(self, method, cid,
                       callback, errback, user_data=None):
        token = str(self._tokens[LiveService.SPACES])
        http_headers = method.transport_headers()
        soap_action = method.soap_action()
        
        soap_header = method.soap_header(token)
        soap_body = method.soap_body(cid)
        
        method_name = method.__name__.rsplit(".", 1)[1]
        self._send_request(method_name, self._service.url, 
                           soap_header, soap_body, soap_action, 
                           callback, errback, http_headers, user_data)

    def _HandleSOAPFault(self, request_id, callback, errback,
            soap_response, user_data):
        errback[0](None, *errback[1:])
