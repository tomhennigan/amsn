# proxy.tcl --
#
#	This file defines various procedures which implement a
#	Proxy access system. Code originally by Dave Mifsud,
#	converted to namespace and improved by D. Emilio Grimaldo T.
#
# RCS: @(#) $Id$

package provide Proxy 0.1
package require http  2.3

namespace eval ::Proxy {
namespace export Init Connect Read OnCallback

variable proxy_host "";
variable proxy_port "";
variable proxy_type "http";
variable proxy_username "";
variable proxy_password "";
variable proxy_with_authentication 0;
variable proxy_header "";
variable proxy_dropped_cb "";

proc OnCallback {event callback} {
    variable proxy_dropped_cb

    switch $event {
        dropped { set proxy_dropped_cb $callback; }
    }
}

proc Init { proxy ptype } {
  variable proxy_host
  variable proxy_port
  variable proxy_type

  # TODO Test with Proxy
  # for the moment, just configure the http to use proxy or not
  if {($proxy != ":") && ($proxy != "") } {
     set lproxy [split $proxy ":"]
     set proxy_host [lindex $lproxy 0]
     set proxy_port [lindex $lproxy 1]
     ::http::config -proxyhost $proxy_host -proxyport $proxy_port
  } else {
     set proxy_host ""
     set proxy_port ""
     ::http::config -proxyhost ""
  }
}

proc Connect {name} {
   fileevent [sb get $name sock] writable {}
   sb set $name stat "pc"
   set tmp_data "CONNECT [join [sb get $name serv] ":"] HTTP/1.0"
   status_log "PROXY SEND: $tmp_data\n"
   puts -nonewline [sb get $name sock] "$tmp_data\r\n\r\n"
}

proc Read { name } {
   variable proxy_header
   variable proxy_dropped_cb

   set sock [sb get $name sock]
   if {[eof $sock]} {
      close $sock
      sb set $name stat "d"
      status_log "PROXY: $name CLOSED\n" red
   } elseif {[gets $sock tmp_data] != -1} {
	 variable proxy_header
	 set tmp_data [string map {\r ""} $tmp_data]
	 lappend proxy_header $tmp_data
	 status_log "PROXY RECV: $tmp_data\n"
	 if {$tmp_data == ""} {
	    set proxy_status [split [lindex $proxy_header 0]]
	    if {[lindex $proxy_status 1] != "200"} {
	       close $sock
	       sb set $name stat "d"
	       status_log "PROXY CLOSED: [lindex $proxy_header 0]\n"

		# DEGT Use a callback mechanism to keep code pure
		if {$proxy_dropped_cb != ""} {
		    set cbret [eval $proxy_dropped_cb "dropped" "$name"]
		}
	       return 1
	    }
	    status_log "PROXY ESTABLISHED: running [sb get $name connected]\n"
	    fileevent [sb get $name sock] readable [sb get $name readable]
	    eval [sb get $name connected]
	  }
   }
   return 0
}
}
###################################################################
# $Log$
# Revision 1.1  2002/07/07 03:08:29  lordofscripts
# - T-PROXY This namespace created based on HTTP proxy code by Dave Mifsud.
# - Enhanced by using callback mechanism to make it generic
#
