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
	    status_log "Proxy is POST. Next handler is ::Proxy::Connect $name\n" white
	    set next "::Proxy::Connect $name"
	    set read "::Proxy::ConnectedPOST $name"
	}
        ssl {
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
   set remote_server [lindex [sb get $name serv] 0]
   set remote_port 1863
     
   switch $proxy_type {
       http {
       
         set error_msg [fconfigure [sb get $name sock] -error]   
         if { $error_msg != "" } {
            sb set $name error_msg $error_msg
            ClosePOST $name
            return
         }
       
	   set tmp_data "POST http://gateway.messenger.hotmail.com/gateway/gateway.dll?Action=open&Server=[string toupper [string range $name 0 1]]&IP=$remote_server HTTP/1.1"
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
	   #status_log "PROXY SEND ($name)\n$tmp_data\n" blue
	   if { [catch {puts -nonewline [sb get $name sock] "$tmp_data"} res]} {
	      #TODO: Error connecting, logout and show error message
	      #sb set $name error_msg "[fconfigure [sb get $name sock] -error]"
	      ClosePOST $name
	   }
       }
       ssl {
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

proc ClosePOST { name } {
   variable proxy_session_id
   variable proxy_gateway_ip
   variable proxy_queued_data

   
   if {[info exists proxy_session_id($name)]} {
      unset proxy_session_id($name)
   }

   if {[info exists proxy_gateway_ip($name)]} {
      unset proxy_gateway_ip($name)
   }
   
   if {[info exists proxy_queued_data($name)]} {
      unset proxy_queued_data($name)
   }
         
   ::MSN::CloseSB $name
}

proc ConnectedPOST { name } {

   ReadPOST $name   
   sb set $name write_proc "::Proxy::WritePOST $name"
   #sb set $name read_proc "::Proxy::ReadPOST $name"
   #catch { fileevent [sb get $name sock] readable [sb get $name readable] } res      
   catch { fileevent [sb get $name sock] readable "::Proxy::ReadPOST $name" } res   
   status_log "Evaluating: [sb get $name connected]\n" white
   eval [sb get $name connected]    
  


}

proc PollPOST { name } {
   variable proxy_session_id
   variable proxy_gateway_ip 
   variable proxy_queued_data  
   
   if { ![info exists proxy_session_id($name)]} {
      return
   }
   
   #TODO: Race condition!! A write can happen here
   set old_proxy_session_id $proxy_session_id($name)
   set proxy_session_id($name) ""
   
      
   if { $old_proxy_session_id == ""} {
   
      status_log "ERROR, RACE CONDITION, THIS SHOULD'T HAPPEN IN ::proxy::PollPOST!!!!\n" white
	 
	 
   } else {
   
      if { $old_proxy_session_id != ""} {
            
         set tmp_data "POST http://$proxy_gateway_ip($name)/gateway/gateway.dll?Action=poll&SessionID=$old_proxy_session_id HTTP/1.1"      
         set tmp_data "$tmp_data\r\nAccept: */*"
         set tmp_data "$tmp_data\r\nAccept-Encoding: gzip, deflate"
         set tmp_data "$tmp_data\r\nUser-Agent: MSMSGS"
         set tmp_data "$tmp_data\r\nHost: $proxy_gateway_ip($name)"
         set tmp_data "$tmp_data\r\nProxy-Connection: Keep-Alive"
         set tmp_data "$tmp_data\r\nConnection: Keep-Alive"
         set tmp_data "$tmp_data\r\nPragma: no-cache"
         set tmp_data "$tmp_data\r\nContent-Type: application/x-msn-messenger"
         set tmp_data "$tmp_data\r\nContent-Length: 0"
         set tmp_data "$tmp_data\r\n\r\n"
	 
         #status_log "PROXY POST polling connection ($name):\n$tmp_data\n" blue      
	 if { [catch {puts -nonewline [sb get $name sock] "$tmp_data" } res]} {
	    sb set $name error_msg $res
            ClosePOST $name
	 }
	          
      }      
      
   }
     
      #ClosePOST $name             

}


proc WritePOST { name {msg ""} } {
   variable proxy_queued_data
   variable proxy_session_id
   variable proxy_gateway_ip
   
   after cancel "::Proxy::PollPOST $name"
   after cancel "::Proxy::WritePOST $name"    
   
   if {![info exists proxy_queued_data($name)]} {
      set proxy_queued_data($name) ""
   }
   
   if { ![info exists proxy_session_id($name)]} {
      return
   }
   
   set old_proxy_session_id $proxy_session_id($name)    
   set proxy_session_id($name) ""      
   
   if { $msg != "" } {
   
      set proxy_queued_data($name) "$proxy_queued_data($name)$msg"   

      if {$name != "ns" } {
         degt_protocol "->Proxy($name) $msg" sbsend
      } else {
         degt_protocol "->Proxy($name) $msg" nssend
      }
   }	 
   
   
   if { $old_proxy_session_id != "" } {
   
 
      set size [string length $proxy_queued_data($name)]
      set strend [expr {$size -1 }]

      set tmp_data "POST http://$proxy_gateway_ip($name)/gateway/gateway.dll?SessionID=$old_proxy_session_id HTTP/1.1"                 
      set tmp_data "$tmp_data\r\nAccept: */*"
      set tmp_data "$tmp_data\r\nAccept-Encoding: gzip, deflate"
      set tmp_data "$tmp_data\r\nUser-Agent: MSMSGS"
      set tmp_data "$tmp_data\r\nHost: $proxy_gateway_ip($name)"
      set tmp_data "$tmp_data\r\nProxy-Connection: Keep-Alive"
      set tmp_data "$tmp_data\r\nConnection: Keep-Alive"
      set tmp_data "$tmp_data\r\nPragma: no-cache"
      set tmp_data "$tmp_data\r\nContent-Type: application/x-msn-messenger"
      set tmp_data "$tmp_data\r\nContent-Length: $size"
      set tmp_data "$tmp_data\r\n\r\n[string range $proxy_queued_data($name) 0 $strend]"
      
      #status_log "PROXY POST Sending: ($name)\n$tmp_data\n" blue
      set proxy_queued_data($name) [string replace $proxy_queued_data($name) 0 $strend]         
      if { [catch {puts -nonewline [sb get $name sock] "$tmp_data"} res] } {
         sb set $name error_msg $res
         ClosePOST $name
      }

	    
   } else {
      set proxy_session_id($name) $old_proxy_session_id
      after 500 "::Proxy::WritePOST $name"
	    
   }
   
      
   #after cancel "::Proxy::PollPOST $name"	
   #after 500 "::Proxy::PollPOST $name"	

}

proc ReadPOST { name } {

   variable proxy_session_id
   variable proxy_gateway_ip
   variable proxy_data
   
   after cancel "::Proxy::PollPOST $name"   
   
   set sock [sb get $name sock]
   if {[catch {eof $sock} res]} {      

      ClosePOST $name
	
   } elseif {[eof $sock]} {

      ClosePOST $name
      
   } else {
   
      set tmp_data "ERROR READING POST PROXY !!\n"
      
      catch {gets $sock tmp_data} res        
      
      if { ([string range $tmp_data 9 11] != "200") && ([string range $tmp_data 9 11] != "100")} {
      #if { ($tmp_data != "HTTP/1.0 200 OK") && ($tmp_data != "HTTP/1.1 100 Continue") } {}
         status_log "Proxy POST connection closed for $name:\n$tmp_data\n" red
	 ClosePOST $name
      } else {
      
         set headers $tmp_data
         while { $tmp_data != "\r"  } {
            catch {gets $sock tmp_data} res        
	    set headers "$headers\n$tmp_data"
	 }
	 set info "[::MSN::GetHeaderValue $headers X-MSN-Messenger]\n"
	 
	 set start [expr {[string first "SessionID=" $info] + 10}]
	 set end [expr {[string first ";" $info $start]-1}]
	 if { $end < 0 } { set end [expr {[string first "\n" $info $start]-1}] }
	 set session_id "[string range $info $start $end]"
	 	 
	 set start [expr {[string first "GW-IP=" $info] + 6}]
	 set end [expr {[string first ";" $info $start]-1}]
	 if { $end < 0 } { set end [expr {[string first "\n" $info $start]-1}] }
	 set gateway_ip "[string range $info $start $end]"
	 
	 set content_length "[::MSN::GetHeaderValue $headers Content-Length]\n"	 
	 set content_data ""
	 if { $content_length > 0 } {	    
	    fconfigure $sock -blocking 1
	    set content_data [read $sock $content_length]
            fconfigure $sock -blocking 0	    
	 }

	 #set log [stringmap {\r ""} $content_data]
	 set log $content_data
	 
	 #status_log "Proxy POST Received ($name):\n$headers\n " green
	 while { $log != "" } {
	 	set endofline [string first "\n" $log]
		set command [string range $log 0 [expr {$endofline-1}]]
		set log [string range $log [expr {$endofline +1}] end]
		sb append $name data $command
		
		degt_protocol "<-Proxy($name) $command" nsrecv      
		
      		if {[string range $command 0 2] == "MSG"} {
         		set recv [split $command]
	 		set msg_data [string range $log 0 [expr {[lindex $recv 3]-1}]]
			set log [string range $log [expr {[lindex $recv 3]}] end]

	 		degt_protocol " Message contents:\n$msg_data" msgcontents
	 
         		sb append $name data $msg_data	
		}	 
	 
	 }
	 
         if { $session_id != ""} {
	    after 5000 "::Proxy::PollPOST $name"
	 }
	 
	 set proxy_gateway_ip($name) $gateway_ip	 
	 set proxy_session_id($name) $session_id
	 
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
	       #close $sock
	       #sb set $name stat "d"
	       status_log "CLOSING PROXY: [lindex $proxy_header 0]\n"

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
# Revision 1.13  2003/06/09 11:43:48  airadier
# Minor changes in gui.tcl (added a catch) and some improvements in http proxy code.
#
# Revision 1.12  2003/06/05 15:56:53  airadier
# Proxy finished, including preferences and minor things.
# Begin to do password encryption
#
# Revision 1.10  2003/06/05 12:21:27  airadier
# Fixed a thing that could make the proxy write messages not in the right order they were sent
#
# Revision 1.9  2003/06/04 23:36:01  airadier
# Fixed the latest proxy POST support bug (don't allow PNG command)
#
# Revision 1.8  2003/06/04 22:39:30  airadier
# Proxy POST and http connection support finished, please test it. Need to add it to preferences.
#
# Revision 1.7  2003/06/02 22:07:34  airadier
# Support to connect directly via http port 80!!!
# Set "gateway.messenger.hotmail.com:80" as proxy server, and done!
#
# Revision 1.6  2003/06/02 01:36:37  airadier
# Proxy POST support quite finished (still misses catching errors and that things)
#
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
