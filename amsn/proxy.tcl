# proxy.tcl --
#
#	This file defines various procedures which implement a
#	Proxy access system. Code originally by Dave Mifsud,
#	converted to namespace and improved by D. Emilio Grimaldo T.
#	SOCKS5 support (integration) is experimental!!!
#
# RCS: @(#) $Id$

package provide Proxy 0.1
package require http  2.3

# This should be converted to a proper package, to use with package require
source [file join $program_dir socks.tcl]	;# SOCKS5 proxy support

namespace eval ::Proxy {
namespace export Init LoginData Setup Connect Read OnCallback

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
  set proxy_type $ptype
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
};# Proxy::Init

proc LoginData { authenticate user passwd} {
    variable proxy_with_authentication
    variable proxy_username
    variable proxy_password

    set proxy_with_authentication $authenticate
    set proxy_username $user
    set proxy_password $passwd
};# Proxy::LoginData

# ::Proxy::Setup next readable_handler $socket_name
proc Setup {next_handler readable_handler name} {
    variable proxy_type
    upvar $next_handler next
    upvar $readable_handler read

    switch $proxy_type {
        http {
	    status_log "next handler is ::Proxy::Connect $name"
	    set next "::Proxy::Connect $name"
	    set read "::Proxy::Read $name"
	}
	socks5 {
	    set next "::Proxy::Connect $name"
	    set read "::Socks5::Readable $name"
	}
    }
    status_log "Proxy::Setup $proxy_type $name"
};# Proxy::Setup

proc Connect {name} {
   variable proxy_type
   variable proxy_username
   variable proxy_password
   variable proxy_with_authentication
   
   status_log "Calliinnnggggg Connect !!"
   
   fileevent [sb get $name sock] writable {}
   sb set $name stat "pc"
   set remote_server [sb get $name serv]
   set remote_port 1863
   switch $proxy_type {
       http {
	   set tmp_data "CONNECT [join $remote_server ":"] HTTP/1.0"
	   status_log "PROXY SEND: $tmp_data\n"
	   puts -nonewline [sb get $name sock] "$tmp_data\r\n\r\n"
       }
       socks5 {
	   set pusername $proxy_username
	   set ppassword $proxy_password
   	   if {$proxy_with_authentication == 0} {
	       set pusername ""
	       set ppassword ""
	   }
   	   set pstat [::Socks5::Init $name $remote_server $remote_port $proxy_with_authentication $pusername $ppassword]
	   if {$pstat != "OK"} {
	        status_log "SOCKS5: $pstat"
		# DEGT Use a callback mechanism to keep code pure
		if {$proxy_dropped_cb != ""} {
		    set cbret [eval $proxy_dropped_cb "dropped" "$name"]
		}
	   }
       }
   }; #proxy type
};# Proxy::Connect

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
	 set tmp_data [stringmap {\r ""} $tmp_data]
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
};# Proxy::Read
}
###################################################################
# $Log$
# Revision 1.4  2003/03/01 19:02:08  airadier
# Now using PNG command for keepalive connection.
# Trying to change "string map" to "stringmap", our own string map procedure.
#
# Revision 1.3  2002/11/09 03:49:44  burgerman
# HTTP proxy seems to works now! there where only minor changes to do!
# Leaves/Joins messages now added to statusbar
#
# Revision 1.2  2002/07/08 00:06:41  lordofscripts
# - Added LoginData to set proxy authentication parameters (when needed)
# - Added Setup which is used during the setup phase of proxy connection
# - Added experiemental SOCKS5 support (requires socks.tcl)
#
# Revision 1.1  2002/07/07 03:08:29  lordofscripts
# - T-PROXY This namespace created based on HTTP proxy code by Dave Mifsud.
# - Enhanced by using callback mechanism to make it generic
#
