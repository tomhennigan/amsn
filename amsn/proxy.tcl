# proxy.tcl --
#
#	This file defines various procedures which implement a
#	Proxy access system. Code originally by Dave Mifsud,
#	converted to namespace and improved by D. Emilio Grimaldo T.
#	SOCKS5 support (integration) is experimental!!!
#
# RCS: @(#) $Id$

package provide Proxy 0.1
package require http

# This should be converted to a proper package, to use with package require
source socks.tcl	;# SOCKS5 proxy support


#Connection wrapper for HTTP connection or http proxy
namespace eval ::HTTPConnection {

	
	proc write { name {msg ""} } {
		variable proxy_queued_data
		variable proxy_session_id
		variable proxy_gateway_ip
		variable proxy_writing

		#Cancel any previous attemp to write or POLL
		after cancel "::HTTPConnection::PollPOST $name"
		after cancel "::HTTPConnection::write $name"    
	
		if {![info exists proxy_queued_data($name)]} {
			set proxy_queued_data($name) ""
		}
	
		if { ![info exists proxy_session_id($name)]} {
			return -1
		}
	
		#Kind of mutex here, to avoid race conditions
		set old_proxy_session_id $proxy_session_id($name)    
		set proxy_session_id($name) ""      

		if { $msg != "" } {
			#If msg!="", enqueue it
			set proxy_queued_data($name) "$proxy_queued_data($name)$msg"   
		}
	
	
		#Check if we got the mutex, then write
		if { $old_proxy_session_id != "" } {
			set current_data $proxy_queued_data($name)    
			set size [string length $current_data]
			set strend [expr {$size -1 }]
			set proxy_queued_data($name) [string replace $proxy_queued_data($name) 0 $strend]         

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
			
			if {[sb get $name proxy_authenticate]  == 1 } {
				set tmp_data "$tmp_data\r\nProxy-Authorization: Basic [::base64::encode [sb get $name proxy_user]:[sb get $name proxy_password]]"
			}
			
						
			set tmp_data "$tmp_data\r\n\r\n$current_data"
			status_log "::HTTPConnection::Write: PROXY POST Sending: ($name)\n$tmp_data\n" blue
			set proxy_writing $tmp_data
			if { [catch {puts -nonewline [sb get $name sock] "$tmp_data"} res] } {
				connect $name [list ::HTTPConnection::RetryWrite $name]
				return 0
			}
	    
		} else {
		
			set proxy_session_id($name) $old_proxy_session_id
			after 500 "::HTTPConnection::write $name"
	    
		}
		
		return 0
	
	}

	proc authInit {} {
		catch {http::unregister https}
		
		set proxy_host [sb get ns proxy_host]
		set proxy_port [sb get ns proxy_port]		
		if {$proxy_host == "" } {
			::http::config -proxyhost ""
		} else {
			if { $proxy_port == "" } {
				set proxy_port 8080
			}
	
			::http::config -proxyhost $proxy_host -proxyport $proxy_port
		}
	
		set ::login_passport_url "https://login.passport.com/login2.srf"
	}
	
	proc authenticate {str url} {
		variable proxy_user
		variable proxy_password
		variable proxy_authenticate
		
		set head [list Authorization "Passport1.4 OrgVerb=GET,OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom,sign-in=[::config::getKey login],pwd=[urlencode $::password],${str}"]
		#if { [::config::getKey nossl] == 1 || ([::config::getKey connectiontype] != "direct" && [::config::getKey connectiontype] != "http") } {
		#	set url [string map { https:// http:// } $url]
		#}
		if {[info exists proxy_authenticate] && $proxy_authenticate  == 1 } {
			lappend head "Proxy-Authorization" "Basic [::base64::encode $proxy_user:$proxy_password]"
		}
		
		set url [string map { https:// http:// } $url]
		status_log "::HTTPConnection::authenticate: Getting $url\n" blue
		if {[catch {::http::geturl $url -command "::HTTPConnection::GotAuthReply [list $str]" -headers $head}]} {
			eval [sb get ns autherror_handler]
		}
	}

	proc GotAuthReply { str token } {
		if { [::http::status $token] != "ok" } {
			::http::cleanup $token
			status_log "::HTTPConnection::GotAuthReply error: [::http::error]\n"
			eval [sb get ns autherror_handler]
			return
		}
	
		upvar #0 $token state
	
		if { [::http::ncode $token] == 200 } {
			#Authentication done correctly
			set index [expr {[lsearch $state(meta) "Authentication-Info"]+1}]
			set values [split [lindex $state(meta) $index] ","]
			set index [lsearch $values "from-PP=*"]
			set value [string range [lindex $values $index] 9 end-1]
			status_log "::HTTPConnection::GotAuthReply 200 Ticket= $value\n" green
			
			set command [list [sb get ns ticket_handler] $value]
			eval $command
	
		} elseif {[::http::ncode $token] == 302} {
			#Redirected to another URL, try again
			set index [expr {[lsearch $state(meta) "Location"]+1}]
			set url [lindex $state(meta) $index]
			status_log "::HTTPConnection::GotAuthReply 302: Forward to $url\n" green
			::HTTPConnection::authenticate $str $url
		} elseif {[::http::ncode $token] == 401} {
			eval [sb get ns passerror_handler]
		} else {
			eval [sb get ns autherror_handler]
		}
		::http::cleanup $token
	
	}
	
		
	#Called to close the given connection
	proc finish {name} {
				
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
		
		set sock [sb get $name sock]
		
		catch {
			fileevent $sock readable ""
			fileevent $sock writable ""
		}
		
		if {[catch {close $sock}]} {
			return -1
		} else {
			return 0
		}
	}
	
	#Called to stablish the given connection.
	#The "server" field in the sbn data must be set to server:port
	proc connect {sbn {connected_handler ""}} {
		variable http_gateway
		variable proxy_user
		variable proxy_password
		variable proxy_authenticate
		
		#On direct http connection, use gateway directly as proxy
		if { [sb get $sbn proxy_host] == ""} {
			set proxy_host "gateway.messenger.hotmail.com"
			set proxy_port 80
		} else {
			set proxy_host [sb get $sbn proxy_host]
			set proxy_port [sb get $sbn proxy_port]
		}

		
		if {[sb get $sbn proxy_authenticate] == 1 } {
			set proxy_authenticate 1
			set proxy_user [sb get $sbn proxy_user]
			set proxy_password [sb get $sbn proxy_password]
		}
				
			
		if { [catch {set sock [socket -async $proxy_host $proxy_port]} res ] } {
			sb set $sbn error_msg $res
			return -1
		}
	
		sb set $sbn sock $sock
		fconfigure $sock -buffering none -translation {binary binary} -blocking 0
		
		fileevent $sock readable ""
		if { $connected_handler == "" } {
			fileevent $sock writable [list ::HTTPConnection::Connected $sbn $sock]
		} else {
			fileevent $sock writable $connected_handler
		}
		return 0
	
	}
	
	proc Connected {sbn sock} {
		
		status_log "::HTTPConnection::Connected: Proxy connected!!\n" green
		
		fileevent $sock writable {}
		
		sb set $sbn stat "pc"
		set remote_server [lindex [sb get $sbn server] 0]
		set remote_port 1863

		set error_msg [fconfigure $sock -error]   		
		if { $error_msg != "" } {
			sb set $sbn error_msg $error_msg
			eval [sb get $sbn error_handler]
			return
		}

		set tmp_data "POST http://gateway.messenger.hotmail.com/gateway/gateway.dll?Action=open&Server=[string toupper [string range $sbn 0 1]]&IP=$remote_server HTTP/1.1"
		set tmp_data "$tmp_data\r\nAccept: */*"
		set tmp_data "$tmp_data\r\nAccept-Encoding: gzip, deflate"
		set tmp_data "$tmp_data\r\nUser-Agent: MSMSGS"
		set tmp_data "$tmp_data\r\nHost: gateway.messenger.hotmail.com"
		set tmp_data "$tmp_data\r\nProxy-Connection: Keep-Alive"
		set tmp_data "$tmp_data\r\nConnection: Keep-Alive"
		set tmp_data "$tmp_data\r\nPragma: no-cache"
		set tmp_data "$tmp_data\r\nContent-Type: application/x-msn-messenger"
		set tmp_data "$tmp_data\r\nContent-Length: 0"
		if {[sb get $sbn proxy_authenticate] == 1 } {
			set tmp_data "$tmp_data\r\nProxy-Authorization: Basic [::base64::encode [sb get $sbn proxy_user]:[sb get $sbn proxy_password]]"
		}
		set tmp_data "$tmp_data\r\n\r\n"
		status_log "::HTTPConnection::Connected: PROXY SEND ($sbn)\n$tmp_data\n" blue
		if { [catch {puts -nonewline $sock "$tmp_data"} res]} {
			eval [sb get $sbn error_handler]
		}
		
		fileevent $sock readable [list ::HTTPConnection::ConnectReply $sbn $sock]
		
	}
	
	proc ConnectReply {sbn sock} {
		status_log "::HTTPConnection::ConnectReply\n" green
		HTTPRead $sbn
		catch {
			fileevent $sock readable [list ::HTTPConnection::HTTPRead $sbn]
			set connected_command [sb get $sbn connected]
			lappend connected_command $sock
			fileevent $sock writable $connected_command			
		}
	}	
	
	proc RetryWrite { name } {
		variable proxy_writing
		status_log "Retrying write\n" blue
		fileevent [sb get $name sock] writable ""
		if { [catch {puts -nonewline [sb get $name sock] $proxy_writing} res] } {
			sb set $name error_msg $res
			eval [sb get $name error_handler]
		}
		catch {unset proxy_writing}
		fileevent [sb get $name sock] readable [list ::HTTPConnection::HTTPRead $name]
		
	}

	proc HTTPRead { name } {

		variable proxy_session_id
		variable proxy_gateway_ip
		variable proxy_data
		variable proxy_writing

		after cancel "::HTTPConnection::HTTPPoll $name"   

		set sock [sb get $name sock]
		if {[catch {eof $sock} res]} {      
			status_log "::HTTPConnection::HTTPRead: Error, closing\n" red
			eval [sb get $name error_handler]
		} elseif {[eof $sock]} {
			fileevent $sock readable ""	
			fileevent $sock writable ""	
			catch { close $sock }
			status_log "::HTTPConnection::HTTPRead: EOF, closing\n" red
			if { [info exists proxy_writing] } {
				connect $name [list ::HTTPConnection::RetryWrite $name]
				return 0
			} else {
				after 5000 "::HTTPConnection::HTTPPoll $name"	
			}
		} else {
			set tmp_data "ERROR READING POST PROXY !!\n"

			catch {gets $sock tmp_data} res

			if { $tmp_data == "" } {
				return
			}
			
			catch {unset proxy_writing}

			if { ([string range $tmp_data 9 11] != "200") && ([string range $tmp_data 9 11] != "100")} {
				status_log "::HTTPConnection::HTTPRead: Proxy POST connection closed for $name:\n$tmp_data\n" red
				eval [sb get $name error_handler]
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

				
				#TODO: Replace everything down here. Reading should be done from ::MSN
				set content_length "[::MSN::GetHeaderValue $headers Content-Length]\n"
				set content_data ""
				if { $content_length > 0 } {
					fconfigure $sock -blocking 1
					set content_data [read $sock $content_length]
					fconfigure $sock -blocking 0
				}

				#set log [string map {\r ""} $content_data]
				set log $content_data

				status_log "::HTTPConnection::HTTPRead: Proxy POST Received ($name):\n$headers\n " green
				while { $log != "" } {
					set endofline [string first "\n" $log]
					set command [string range $log 0 [expr {$endofline-1}]]
					set log [string range $log [expr {$endofline +1}] end]
					#sb append $name data $command

					#degt_protocol "<-Proxy($name) $command" nsrecv

					if {[string range $command 0 2] == "MSG"} {
						set recv [split $command]
						set msg_data [string range $log 0 [expr {[lindex $recv 3]-1}]]
						set log [string range $log [expr {[lindex $recv 3]}] end]

						set evcommand [sb get $name payload_handler]
						lappend evcommand $command
						lappend evcommand $msg_data
						eval $evcommand
						#degt_protocol " Message contents:\n$msg_data" msgcontents

						#sb append $name data $msg_data
					} else {
						set evalcomm [sb get $name command_handler]
						lappend evalcomm $command
						eval $evalcomm
					}

				}

				if { $session_id != ""} {
					#status_log "Scheduling HTTPPoll\n" white
					after 5000 "::HTTPConnection::HTTPPoll $name"
				}

				set proxy_gateway_ip($name) $gateway_ip	 
				set proxy_session_id($name) $session_id

			}
		}   
	}

	proc HTTPPoll { name } {
		variable proxy_session_id
		variable proxy_gateway_ip 
		variable proxy_queued_data  
		variable proxy_writing

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
				if {[sb get $name proxy_authenticate] == 1 } {
					set tmp_data "$tmp_data\r\nProxy-Authorization: Basic [::base64::encode [sb get $name proxy_user]:[sb get $name proxy_password]]"
				}
				set tmp_data "$tmp_data\r\n\r\n"

				#status_log "PROXY POST polling connection ($name):\n$tmp_data\n" blue      
				set proxy_writing $tmp_data
				if { [catch {puts -nonewline [sb get $name sock] "$tmp_data" } res]} {
					connect $name [list ::HTTPConnection::RetryWrite $name]
					return 0
				}

			} 
	    
		}	
	}
	
	
}



namespace eval ::Proxy {
	namespace export Init LoginData Setup Connect Read OnCallback

	if { $initialize_amsn == 1 } {
		variable proxy_host "";
		variable proxy_port "";
		variable proxy_type "http";
		variable proxy_username "";
		variable proxy_password "";
		variable proxy_with_authentication 0;
		variable proxy_header "";
		variable proxy_dropped_cb "";
	}

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
		} else {
			set proxy_host ""
			set proxy_port ""
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
		variable proxy_dropped_cb
		variable proxy_host
		variable proxy_port
		
		status_log "Calliinnnggggg Connect !!\n" white

		fileevent [sb get $name sock] writable {}
		
		sb set $name stat "pc"
		set remote_server [lindex [sb get $name server] 0]
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
				if {$proxy_with_authentication == 1 } {
					set tmp_data "$tmp_data\r\nProxy-Authorization: Basic [::base64::encode ${proxy_username}:${proxy_password}]"
				}
				set tmp_data "$tmp_data\r\n\r\n"
				status_log "PROXY SEND ($name)\n$tmp_data\n" blue
				if { [catch {puts -nonewline [sb get $name sock] "$tmp_data"} res]} {
					#TODO: Error connecting, logout and show error message
					#sb set $name error_msg "[fconfigure [sb get $name sock] -error]"
					ClosePOST $name
				}
			}
			ssl {
				set tmp_data "CONNECT [join [list $remote_server $remote_port] ":"] HTTP/1.0"
				status_log "PROXY SEND: $tmp_data\n"
				puts -nonewline [sb get $name sock] "$tmp_data\r\n\r\n"
			}
			socks5 {
				set remote_server $proxy_host
				set remote_port $proxy_port
				set pusername $proxy_username
				set ppassword $proxy_password
				if {$proxy_with_authentication == 0} {
					set pusername ""
					set ppassword ""
				}
		#		status_log "Connecting using socks5 to $remote_server ($proxy_host) at port $remote_port ($proxy_port) with user $pusername and password $ppassword\n\n"
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

		catch {
			fileevent [sb get $name sock] readable ""
			fileevent [sb get $name sock] writable ""
		}
		::MSN::CloseSB $name
	}

	
	
	proc ConnectedPOST { name } {
		ReadPOST $name   
		#sb set $name write_proc [list ::Proxy::WritePOST $name]
		#sb set $name read_proc [list ::Proxy::ReadPOST $name"]
		sb set $name connection_wrapper "ProxyPOST"
		#catch { fileevent [sb get $name sock] readable [sb get $name readable] } res      
		catch { fileevent [sb get $name sock] readable "::Proxy::ReadPOST $name" } res   
		status_log "Evaluating: [sb get $name connected]\n" white
		eval [sb get $name connected]    
	}

	proc PollPOST { name } {
		variable proxy_session_id
		variable proxy_gateway_ip 
		variable proxy_queued_data  
		variable proxy_username
		variable proxy_password
		variable proxy_with_authentication

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
				if {$proxy_with_authentication == 1 } {
					set tmp_data "$tmp_data\r\nProxy-Authorization: Basic [::base64::encode ${proxy_username}:${proxy_password}]"
				}
				set tmp_data "$tmp_data\r\n\r\n"

				#status_log "PROXY POST polling connection ($name):\n$tmp_data\n" blue      
				if { [catch {puts -nonewline [sb get $name sock] "$tmp_data" } res]} {
					sb set $name error_msg $res
					ClosePOST $name
				}

			} 
	    
		}	
	}


	proc WritePOST { name {msg ""} } {
		variable proxy_queued_data
		variable proxy_session_id
		variable proxy_gateway_ip
		variable proxy_username
		variable proxy_password
		variable proxy_with_authentication


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
			
			if {$proxy_with_authentication == 1 } {
				set tmp_data "$tmp_data\r\nProxy-Authorization: Basic [::base64::encode ${proxy_username}:${proxy_password}]"
			}
			
			set tmp_data "$tmp_data\r\n\r\n[string range $proxy_queued_data($name) 0 $strend]"

			status_log "PROXY POST Sending: ($name)\n$tmp_data\n" blue
			set proxy_queued_data($name) [string replace $proxy_queued_data($name) 0 $strend]         
			if { [catch {puts -nonewline [sb get $name sock] "$tmp_data"} res] } {
				sb set $name error_msg $res
				ClosePOST $name
			}

	    
		} else {
			set proxy_session_id($name) $old_proxy_session_id
			after 500 "::Proxy::WritePOST $name"
	    
		}
	
	}

	
	proc ReadPOST { name } {

		variable proxy_session_id
		variable proxy_gateway_ip
		variable proxy_data

		after cancel "::Proxy::PollPOST $name"   

		set sock [sb get $name sock]
		if {[catch {eof $sock} res]} {      
			status_log "Proxy::ReadPOST: Error, closing\n" red
			ClosePOST $name
		} elseif {[eof $sock]} {
			status_log "Proxy::ReadPOST: EOF, closing\n" red
			ClosePOST $name
		} else {
			set tmp_data "ERROR READING POST PROXY !!\n"

			catch {gets $sock tmp_data} res

			if { $tmp_data == "" } {
				return
			}

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

				#set log [string map {\r ""} $content_data]
				set log $content_data

				status_log "Proxy POST Received ($name):\n$headers\n " green
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
			set tmp_data [string map {\r ""} $tmp_data]
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
