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

__all__ = ["ProtocolConstant"]

class ProtocolConstant(object):
    VER = ('MSNP15', 'MSNP14', 'MSNP13', 'CVR0')
    CVR = ('0x0409', 'winnt', '5.1', 'i386', 'MSNMSGR', '8.1.0178', 'msmsgs')
    PRODUCT_ID = "PROD0114ES4Z%Q5W"
    PRODUCT_KEY = "PK}_A_0N_K%O?A9S"
    CHL_MAGIC_NUM = 0x0E79A9C1
