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
        post {
	    status_log "Proxy is POST. Next handler is ::Proxy::Connect $name\n" white
	    set next "::Proxy::Connect $name"
	    set read "::Proxy::ConnectedPOST $name"
	}
        http {
	    status_log "proxy is CONNECT. Next handler is ::Proxy::Connect $name\n" white
	    set next "::Proxy::Connect $name"
	    set read "::Proxy::Read $name"
	}
	socks5 {
	    set next "::Proxy::Connect $name"
	    set read "::Socks5::Readable $name"
	}
    }
    status_log "Proxy::Setup $proxy_type $name\n" white
};# Proxy::Setup

proc Connect {name} {
   variable proxy_type
   variable proxy_username
   variable proxy_password
   variable proxy_with_authentication
   
   status_log "Calliinnnggggg Connect !!\n" white
   
   fileevent [sb get $name sock] writable {}
   sb set $name stat "pc"
   set remote_server [sb get $name serv]
   set remote_port 1863
   switch $proxy_type {
       post {
           status_log "Here in ::Proxy::Connect\n" white
	   set tmp_data "POST http://gateway.messenger.hotmail.com/gateway/gateway.dll?Action=open&Server=NS&IP=$remote_server HTTP/1.1"
	   set tmp_data "$tmp_data\r\nAccept: */*"
	   set tmp_data "$tmp_data\r\nAccept-Encoding: gzip, deflate"
	   set tmp_data "$tmp_data\r\nUser-Agent: MSMSGS"
	   set tmp_data "$tmp_data\r\nHost: gateway.messenger.hotmail.com"
	   set tmp_data "$tmp_data\r\nProxy-Connection: Keep-Alive"
	   set tmp_data "$tmp_data\r\nConnection: Keep-Alive"
	   set tmp_data "$tmp_data\r\nPragma: no-cache"
	   set tmp_data "$tmp_data\r\nContent-Type: application/x-msn-messenger"
	   set tmp_data "$tmp_data\r\nContent-Length: 0"
	   set tmp_data "$tmp_data\r\n\r\n"
	   status_log "PROXY SEND: $tmp_data\n"
	   puts -nonewline [sb get $name sock] "$tmp_data\r\n\r\n"
       }
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

proc ConnectedPOST { name } {

   variable proxy_session_id
   variable proxy_gateway_ip
   variable proxy_queued_data

   set sock [sb get $name sock]
   if {[catch {eof $sock} res]} {      

   	sb set $name "d"
        fileevent [sb get $name sock] readable [sb get $name readable]        	
	catch {close $sock} res
	
   } elseif {[eof $sock]} {

   	sb set $name "d"
        fileevent [sb get $name sock] readable [sb get $name readable]        	
	catch {close $sock} res
      
   } else {
   
      set tmp_data "ERROR READING POST PROXY !!\n"
      
      catch {gets $sock tmp_data} res        
      
      if { $tmp_data != "HTTP/1.0 200 OK\r" } {
         status_log "Proxy POST Reply: $tmp_data\n" red
   	 sb set $name "d"         
         fileevent [sb get $name sock] readable [sb get $name readable]
	 catch {close $sock} res
      } else {
         set headers ""
         while { $tmp_data != "" } {
            catch {gets $sock tmp_data} res        
	    set headers "$headers\n$tmp_data"
	 }
         status_log "Proxy POST Headers: $headers\n" white	 
	 set info "[::MSN::GetHeaderValue $headers X-MSN-Messenger]\n"
	 
	 set start [expr {[string first "SessionID=" $info] + 10}]
	 set end [expr {[string first ";" $info $start]-1}]
	 if { $end < 0 } { set end [expr {[string first "\n" $info $start]-1}] }
	 set proxy_session_id($name) "[string range $info $start $end]"
	 
	 set start [expr {[string first "GW-IP=" $info] + 6}]
	 set end [expr {[string first ";" $info $start]-1}]
	 if { $end < 0 } { set end [expr {[string first "\n" $info $start]-1}] }
	 set proxy_gateway_ip($name) "[string range $info $start $end]"
	 
	 set proxy_queued_data($name) ""
	 
	 sb set $name puts "::Proxy::WritePOST $name"
         #fileevent [sb get $name sock] readable [sb get $name readable]
	 fileevent [sb get $name sock] readable "::Proxy::ReadPOST $name"
	 status_log "Evaluating: [sb get $name connected]\n" white
	 eval [sb get $name connected]
	 	 
	 
      }
   }   

}

proc PollPOST { name } {

	variable proxy_queued_data

	status_log "Polling proxy POST connection\n"
	if { [string length $proxy_queued_data($name)] > 0 } {
		WritePOST $name -nonewline [sb get $name sock] ""
	} else {
		after 5000 "::Proxy::PollPOST $name"	
	}	

}

proc WritePOST { name nonewline sock { msg 0} } {
   variable proxy_session_id
   variable proxy_gateway_ip
   variable proxy_queued_data

   if { $msg == 0} {
     set msg $sock
     set sock $nonewline
     set nonewline ""
   }

   if { $nonewline != "-nonewline" } {
     set msg "$msg\n"  
   }
   
   set proxy_queued_data($name) "$proxy_queued_data($name)$msg"
   
   if { $proxy_session_id($name) != "" } {
   
      set tmp_data "POST http://$proxy_gateway_ip($name)/gateway/gateway.dll?SessionID=$proxy_session_id($name) HTTP/1.1"
      set tmp_data "$tmp_data\r\nAccept: */*"
      set tmp_data "$tmp_data\r\nAccept-Encoding: gzip, deflate"
      set tmp_data "$tmp_data\r\nUser-Agent: MSMSGS"
      set tmp_data "$tmp_data\r\nHost: $proxy_gateway_ip($name)"
      set tmp_data "$tmp_data\r\nProxy-Connection: Keep-Alive"
      set tmp_data "$tmp_data\r\nConnection: Keep-Alive"
      set tmp_data "$tmp_data\r\nPragma: no-cache"
      set tmp_data "$tmp_data\r\nContent-Type: application/x-msn-messenger"
      set tmp_data "$tmp_data\r\nContent-Length: [string length $proxy_queued_data($name)]"
      set tmp_data "$tmp_data\r\n\r\n$proxy_queued_data($name)"
      status_log "PROXY SEND: $tmp_data\n"
      puts -nonewline [sb get $name sock] "$tmp_data\r\n"
   
      set proxy_queued_data($name) ""   
      set proxy_session_id($name) ""
   }
   
   after cancel "::Proxy::PollPOST $name"	
   after 5000 "::Proxy::PollPOST $name"	

}

proc ReadPOST { name } {
   variable proxy_session_id
   variable proxy_gateway_ip
   variable proxy_data

   set sock [sb get $name sock]
   if {[catch {eof $sock} res]} {      

   	sb set $name "d"
        fileevent [sb get $name sock] readable [sb get $name readable]        	
	catch {close $sock} res
	
   } elseif {[eof $sock]} {

   	sb set $name "d"
        fileevent [sb get $name sock] readable [sb get $name readable]        	
	catch {close $sock} res
      
   } else {
   
      set tmp_data "ERROR READING POST PROXY !!\n"
      
      catch {gets $sock tmp_data} res        
      set tmp_data [stringmap { "\r" "" } $tmp_data]
      
      if { $tmp_data != "HTTP/1.0 200 OK" } {
         status_log "Proxy POST Headers: $tmp_data\n" red
   	 sb set $name "d"  
         fileevent [sb get $name sock] readable [sb get $name readable]        
	 catch {close $sock} res
      } else {
      
         set headers ""
         while { $tmp_data != "" } {
            catch {gets $sock tmp_data} res        
	    set headers "$headers\n$tmp_data"
	 }
         status_log "Proxy POST Headers: $headers\n" white	 
	 set info "[::MSN::GetHeaderValue $headers X-MSN-Messenger]\n"
	 
	 set start [expr {[string first "SessionID=" $info] + 10}]
	 set end [expr {[string first ";" $info $start]-1}]
	 if { $end < 0 } { set end [expr {[string first "\n" $info $start]-1}] }
	 set proxy_session_id($name) "[string range $info $start $end]"
	 
	 set start [expr {[string first "GW-IP=" $info] + 6}]
	 set end [expr {[string first ";" $info $start]-1}]
	 if { $end < 0 } { set end [expr {[string first "\n" $info $start]-1}] }
	 set proxy_gateway_ip($name) "[string range $info $start $end]"
	 
	 set content_length "[::MSN::GetHeaderValue $headers Content-Length]\n"
	 status_log "Content_Length: $content_length\n"
	 fconfigure $sock -blocking 1
	 set content_data [read $sock $content_length]
	 fconfigure $sock -blocking 0
	 status_log "Content_Data: $content_data\n"

	 set log [stringmap {\r ""} $content_data]
	 
	 while { $log != "" } {
	 	set endofline [string first "\n" $log]
		set command [string range $log 0 $endofline]
		set log [string range $log [expr {$endofline +1}] end]
		sb append $name data $command
		
		degt_protocol "<-Proxy($name) $command\\n" nsrecv      
		
      		if {[string range $command 0 2] == "MSG"} {
         		set recv [split $command]
	 		set msg_data [string range $log 0 [lindex $recv 3]]
			set log [string range $log [expr {[lindex $recv 3] +1}] end]

	 		degt_protocol " Message contents:\n$msg_data" msgcontents
	 
         		sb append ns data $msg_data			
		}	 
	 
	 }
	 
         #fileevent [sb get $name sock] readable [sb get $name readable]
	 #fileevent [sb get $name sock] readable "::Proxy::ReadPOST $name"
	 
      }
   }   
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
# Revision 1.5  2003/06/01 19:49:36  airadier
# Very alpha support of POST proxy method.
# Removed WriteNS, WriteNSRaw, and read_ns_sock, it was same code as WriteSB, WriteSBRaw and read_sb_sock, so now they're the same, always use SB procedures.
#
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
