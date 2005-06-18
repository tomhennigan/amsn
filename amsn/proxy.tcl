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

#the framework for connections. You create an instance of this object only,
#never the other proxy objects directly
::snit::type Proxy {

	delegate method * to proxy

	constructor {args} {
		if {[::config::getKey connectiontype] == "direct" } {
			install proxy using ProxyDirect %AUTO% -name $self
		} elseif {[::config::getKey connectiontype] == "http" } {
			install proxy using ProxyHTTP %AUTO% -name $self
		} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "http" } {
			install proxy using ProxyHTTP %AUTO% -name $self
		} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "socks5" } {
			install proxy using ProxyDirect %AUTO% -name $self
		} else {
			::config::setKey connectiontype "direct"
			install proxy using ProxyDirect %AUTO% -name $self
		}

		$self configurelist $args
	}

	destructor {
		catch { $self proxy destroy }
	}
}

::snit::type ProxyDirect {

	option -name

	#Called to write some data to the connection
	method write { sb data } {

		set sb_sock [$sb cget -sock]
		if {[catch {puts -nonewline $sb_sock "$data"} res]} {
			status_log "::DirectConnectin::Write: SB $sb problem when writing to the socket: $res...\n" red
			return -1
		} else {
			return 0
		}

	}

	#Called to close the given connection
	method finish {sb} {

		set sock [$sb cget -sock]

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
	#The "server" field in the sb data must be set to server:port
	method connect {sb} {

		if { [$sb cget -proxy_host] != ""} {
			#We connect through SOCKS socket
			set tmp_serv [$sb cget -proxy_host]
			set tmp_port [$sb cget -proxy_port]
			set proxy_serv [lindex [$sb cget -server] 0]
			set proxy_port [lindex [$sb cget -server] 1]
			if {[$sb cget -proxy_authenticate] == 1 } {
				set proxy_authenticate 1
				set proxy_user [$sb cget -proxy_user]
				set proxy_password [$sb cget -proxy_password]
			} else {
				set proxy_authenticate 0
				set proxy_user ""
				set proxy_password ""
			}
		} else {
			#We connect directly
			set tmp_serv [lindex [$sb cget -server] 0]
			set tmp_port [lindex [$sb cget -server] 1]
		}
		if { [catch {set sock [socket -async $tmp_serv $tmp_port]} res ] } {
			$sb configure -error_msg $res
			return -1
		}

		$sb configure -sock $sock
		if { [$sb cget -proxy_host] != ""} {
			set res [::Socks5::Init $sb $proxy_serv $proxy_port $proxy_authenticate $proxy_user $proxy_password]
			if { $res != "OK" } {
				$sb configure -error_msg $res
				return -1
			}
		}
		fconfigure $sock -buffering none -translation binary -blocking 0
		fileevent $sock readable [list $sb receivedData]
		set connected_command [$sb cget -connected]
		lappend connected_command $sock
		fileevent $sock writable $connected_command
		return 0

	}

	method authInit {} {
		global tlsinstalled login_passport_url

		#Check if we need to install the TLS module
		if { $tlsinstalled == 0 && [checking_package_tls] == 0 && [::config::getKey nossl] == 0} {
			::autoupdate::installTLS
			return -1
		}

		#If SSL is used, register https:// protocol
		if { [::config::getKey nossl] == 0 } {
			http::register https 443 ::tls::socket
		} else  {
			catch {http::unregister https}
		}

		#No proxy is used
		::http::config -proxyhost ""

		if { [::config::getKey nossl] == 1 } {
			#If we can't use ssl, avoid getting url from nexus
			set login_passport_url "https://login.passport.com/login2.srf"
		} else {
			#Contact nexus to get login url
			set login_passport_url 0
			degt_protocol $self
			after 500 "catch {::http::geturl [list https://nexus.passport.com/rdr/pprdr.asp] -timeout 10000 -command {$self GotNexusReply}}"
		}
	}

	method authenticate {str url} {

		set head [list Authorization "Passport1.4 OrgVerb=GET,OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom,sign-in=[::config::getKey login],pwd=[urlencode $::password],${str}"]
		#if { [::config::getKey nossl] == 1 || ([::config::getKey connectiontype] != "direct" && [::config::getKey connectiontype] != "http") } {
		#	set url [string map { https:// http:// } $url]
		#}
		if { [::config::getKey nossl] == 1 } {
			set url [string map { https:// http:// } $url]
		}
		status_log "::DirectConnection::authenticate: Getting $url\n" blue
		if {[catch {::http::geturl $url -command "$self GotAuthReply [list $str]" -headers $head}]} {
			eval [ns cget -autherror_handler]
			#msnp9_auth_error
		}

	}


	method GotNexusReply {token {total 0} {current 0}} {

		global login_passport_url
		if { [::http::status $token] != "ok" || [::http::ncode $token ] != 200 } {
			#Nexus connection failed, so let's just set login URL manually
			set loginurl "https://login.passport.com/login2.srf"
			status_log "gotNexusReply: error in nexus reply, getting url manually\n" red
		} else {
			#We got reply from nexus. Extract login URL
			upvar #0 $token state

			set index [expr {[lsearch $state(meta) "PassportURLs"]+1}]
			set values [split [lindex $state(meta) $index] ","]
			set index [lsearch $values "DALogin=*"]
			set loginurl "https://[string range [lindex $values $index] 8 end]"
			status_log "gotNexusReply: loginurl=$loginurl\n" green
		}
		::http::cleanup $token

		#If $login_passport_url == 0, we got login url before authentication took place
		if { $login_passport_url == 0 } {
			#Set loginurl (will be used in authentication), and rest in peace
			set login_passport_url $loginurl
			status_log "gotNexusReply: finished before authentication took place\n" green
		} else {
			#Authentication is waiting for us to get this url!! Do authentication inmediatly
			status_log "gotNexusReply: authentication was waiting for me, so I'll do it\n" green
			$self authenticate $login_passport_url $loginurl
		}

	}

	method GotAuthReply { str token } {
		if { [::http::status $token] != "ok" } {
			::http::cleanup $token
			status_log "$self GotAuthReply error: [::http::error]\n"
			eval [ns cget -autherror_handler]
			#msnp9_auth_error
			return
		}

		upvar #0 $token state

		if { [::http::ncode $token] == 200 } {
			#Authentication done correctly
			set index [expr {[lsearch $state(meta) "Authentication-Info"]+1}]
			set values [split [lindex $state(meta) $index] ","]
			set index [lsearch $values "from-PP=*"]
			set value [string range [lindex $values $index] 9 end-1]
			status_log "::DirectConnection::GotAuthReply 200 Ticket= $value\n" green

			set command [list [ns cget -ticket_handler] $value]
			eval $command
			#msnp9_authenticate $value

		} elseif {[::http::ncode $token] == 302} {
			#Redirected to another URL, try again
			set index [expr {[lsearch $state(meta) "Location"]+1}]
			set url [lindex $state(meta) $index]
			status_log "::DirectConnection::GotAuthReply 302: Forward to $url\n" green
			$self authenticate $str $url
		} elseif {[::http::ncode $token] == 401} {
			#msnp9_userpass_error
			eval [ns cget -passerror_handler]
		} else {
			eval [ns cget -autherror_handler]
			#msnp9_auth_error
		}
		::http::cleanup $token

	}
}

#Connection wrapper for HTTP connection or http proxy
::snit::type ProxyHTTP {

	option -name
	option -proxy_queued_data
	option -proxy_session_id
	option -proxy_gateway_ip
	option -options(-proxy_writing)


	method write { name {msg ""} } {
#		variable proxy_queued_data
#		variable proxy_session_id
#		variable proxy_gateway_ip
#		variable options(-proxy_writing)

		#Cancel any previous attemp to write or POLL
		after cancel "$self PollPOST $name"
		after cancel "$self write $name"

		if {![info exists options(-proxy_queued_data)]} {
			set options(-proxy_queued_data) ""
		}

		if { ![info exists options(-proxy_session_id)]} {
			return -1
		}

		#Kind of mutex here, to avoid race conditions
		set old_proxy_session_id $options(-proxy_session_id)
		set options(-proxy_session_id) ""

		if { $msg != "" } {
			#If msg!="", enqueue it
			set options(-proxy_queued_data) "$options(-proxy_queued_data)$msg"
		}


		#Check if we got the mutex, then write
		if { $old_proxy_session_id != "" } {
			set current_data $options(-proxy_queued_data)
			set size [string length $current_data]
			set strend [expr {$size -1 }]
			set options(-proxy_queued_data) [string replace $options(-proxy_queued_data) 0 $strend]

			set tmp_data "POST http://$options(-proxy_gateway_ip)/gateway/gateway.dll?SessionID=$old_proxy_session_id HTTP/1.1"
			set tmp_data "$tmp_data\r\nAccept: */*"
			set tmp_data "$tmp_data\r\nAccept-Encoding: gzip, deflate"
			set tmp_data "$tmp_data\r\nUser-Agent: MSMSGS"
			set tmp_data "$tmp_data\r\nHost: $options(-proxy_gateway_ip)"
			set tmp_data "$tmp_data\r\nProxy-Connection: Keep-Alive"
			set tmp_data "$tmp_data\r\nConnection: Keep-Alive"
			set tmp_data "$tmp_data\r\nPragma: no-cache"
			set tmp_data "$tmp_data\r\nContent-Type: application/x-msn-messenger"
			set tmp_data "$tmp_data\r\nContent-Length: $size"

			if {[$name cget -proxy_authenticate]  == 1 } {
				set tmp_data "$tmp_data\r\nProxy-Authorization: Basic [::base64::encode [$name cget -proxy_user]:[$name cget -proxy_password]]"
			}


			set tmp_data "$tmp_data\r\n\r\n$current_data"
			status_log "::HTTPConnection::Write: PROXY POST Sending: ($name)\n$tmp_data\n" blue
			set options(-proxy_writing) $tmp_data
			if { [catch {puts -nonewline [$name cget -sock] "$tmp_data"} res] } {
				$self connect $name [list $self RetryWrite $name]
				return 0
			}

		} else {

			set options(-proxy_session_id) $old_proxy_session_id
			after 500 "$self write $name"

		}

		return 0

	}

	method authInit {} {
		catch {::http::unregister https}

		set proxy_host [ns cget -proxy_host]
		set proxy_port [ns cget -proxy_port]
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

	method authenticate {str url} {
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
		::http::geturl $url -command "$self GotAuthReply [list $str]" -headers $head
#			eval [ns cget -autherror_handler]
#
	}

	method GotAuthReply { str token } {
		if { [::http::status $token] != "ok" } {
			::http::cleanup $token
			status_log "::HTTPConnection::GotAuthReply error: [::http::error]\n"
			eval [ns cget -autherror_handler]
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

			set command [list [ns cget -ticket_handler] $value]
			eval $command

		} elseif {[::http::ncode $token] == 302} {
			#Redirected to another URL, try again
			set index [expr {[lsearch $state(meta) "Location"]+1}]
			set url [lindex $state(meta) $index]
			status_log "::HTTPConnection::GotAuthReply 302: Forward to $url\n" green
			$self authenticate $str $url
		} elseif {[::http::ncode $token] == 401} {
			eval [ns cget -passerror_handler]
		} else {
			eval [ns cget -autherror_handler]
		}
		::http::cleanup $token

	}


	#Called to close the given connection
	method finish {name} {

		variable proxy_session_id
#		variable proxy_gateway_ip
		variable proxy_queued_data

		if {[info exists options(-proxy_session_id)]} {
			unset options(-proxy_session_id)
		}

		if {[info exists options(-proxy_gateway_ip)]} {
			unset options(-proxy_gateway_ip)
		}

		if {[info exists options(-proxy_queued_data)]} {
			unset options(-proxy_queued_data)
		}

		set sock [$name cget -sock]

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
	#The "server" field in the sb data must be set to server:port
	method connect {sb {connected_handler ""}} {
		variable http_gateway
		variable proxy_user
		variable proxy_password
		variable proxy_authenticate

		#On direct http connection, use gateway directly as proxy
		if { [$sb cget -proxy_host] == ""} {
			set proxy_host "gateway.messenger.hotmail.com"
			set proxy_port 80
		} else {
			set proxy_host [$sb cget -proxy_host]
			set proxy_port [$sb cget -proxy_port]
		}


		if {[$sb cget -proxy_authenticate] == 1 } {
			set proxy_authenticate 1
			set proxy_user [$sb cget -proxy_user]
			set proxy_password [$sb cget -proxy_password]
		}


		if { [catch {set sock [socket -async $proxy_host $proxy_port]} res ] } {
			$sb configure -error_msg $res
			return -1
		}

		$sb configure -sock $sock
		fconfigure $sock -buffering none -translation {binary binary} -blocking 0

		fileevent $sock readable ""
		if { $connected_handler == "" } {
			fileevent $sock writable [list $self Connected $sb $sock]
		} else {
			fileevent $sock writable $connected_handler
		}
		return 0

	}

	method Connected {sb sock} {

		status_log "::HTTPConnection::Connected: Proxy connected!!\n" green

		fileevent $sock writable {}

		$sb configure -stat "pc"
		set remote_server [lindex [$sb cget -server] 0]
		set remote_port 1863

		set error_msg [fconfigure $sock -error]
		if { $error_msg != "" } {
			$sb configure -error_msg $error_msg
			$sb sockError
			return
		}

		set server "NS"
		if { [string first "SB" $sb] != "-1" } {
			set server "SB"
		}

		set tmp_data "POST http://gateway.messenger.hotmail.com/gateway/gateway.dll?Action=open&Server=$server&IP=$remote_server HTTP/1.1"
		set tmp_data "$tmp_data\r\nAccept: */*"
		set tmp_data "$tmp_data\r\nAccept-Encoding: gzip, deflate"
		set tmp_data "$tmp_data\r\nUser-Agent: MSMSGS"
		set tmp_data "$tmp_data\r\nHost: gateway.messenger.hotmail.com"
		set tmp_data "$tmp_data\r\nProxy-Connection: Keep-Alive"
		set tmp_data "$tmp_data\r\nConnection: Keep-Alive"
		set tmp_data "$tmp_data\r\nPragma: no-cache"
		set tmp_data "$tmp_data\r\nContent-Type: application/x-msn-messenger"
		set tmp_data "$tmp_data\r\nContent-Length: 0"
		if {[$sb cget -proxy_authenticate] == 1 } {
			set tmp_data "$tmp_data\r\nProxy-Authorization: Basic [::base64::encode [$sb cget -proxy_user]:[$sb cget -proxy_password]]"
		}
		set tmp_data "$tmp_data\r\n\r\n"
		status_log "::HTTPConnection::Connected: PROXY SEND ($sb)\n$tmp_data\n" blue
		if { [catch {puts -nonewline $sock "$tmp_data"} res]} {
			$sb sockError
		}

		fileevent $sock readable [list $self ConnectReply $sb $sock]

	}

	method ConnectReply {sb sock} {
		status_log "::HTTPConnection::ConnectReply\n" green
		$self HTTPRead $sb
		catch {
			fileevent $sock readable [list $self HTTPRead $sb]
			set connected_command [$sb cget -connected]
			lappend connected_command $sock
			fileevent $sock writable $connected_command
		}
	}

	method RetryWrite { name } {
#		variable options(-proxy_writing)
		status_log "Retrying write\n" blue
		catch {fileevent [$name cget -sock] writable ""}
		if { [catch {puts -nonewline [$name cget -sock] $options(-proxy_writing)} res] } {
			$name configure -error_msg $res
			$name sockError
		}
		catch {unset options(-proxy_writing)}
		if { [catch {fileevent [$name cget -sock] readable [list $self HTTPRead $name]} res] } {
			$name configure -error_msg $res
			$name sockError
		}


	}

	method HTTPRead { name } {

		variable proxy_session_id
#		variable proxy_gateway_ip
		variable proxy_data
		variable options(-proxy_writing)

		after cancel "$self HTTPPoll $name"

		set sock [$name cget -sock]
		if {[catch {eof $sock} res]} {
			status_log "::HTTPConnection::HTTPRead: Error, closing\n" red
			$name sockError
		} elseif {[eof $sock]} {
			fileevent $sock readable ""
			fileevent $sock writable ""
			catch { close $sock }
			status_log "::HTTPConnection::HTTPRead: EOF, closing\n" red
			if { [info exists options(-proxy_writing)] } {
				$self connect $name [list $self RetryWrite $name]
				return 0
			} else {
				after 5000 "$self HTTPPoll $name"
			}
		} else {
			set tmp_data "ERROR READING POST PROXY !!\n"

			catch {gets $sock tmp_data} res

			if { $tmp_data == "" } {
				return
			}

			catch {unset options(-proxy_writing)}

			if { ([string range $tmp_data 9 11] != "200") && ([string range $tmp_data 9 11] != "100")} {
				status_log "::HTTPConnection::HTTPRead: Proxy POST connection closed for $name:\n$tmp_data\n" red
				$name sockError
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
					set command [string range $log 0 [expr {$endofline-2}]]
					set log [string range $log [expr {$endofline +1}] end]
					#sb append $name data $command

					#degt_protocol "<-Proxy($name) $command" nsrecv

					if {[string range $command 0 2] == "MSG"} {
						set recv [split $command]
						set msg_data [string range $log 0 [expr {[lindex $recv 3]-1}]]
						set log [string range $log [expr {[lindex $recv 3]}] end]

						$name handleCommand $command $msg_data
						#degt_protocol " Message contents:\n$msg_data" msgcontents

						#sb append $name data $msg_data
					} else {
						$name handleCommand $command
					}

				}

				if { $session_id != ""} {
					#status_log "Scheduling HTTPPoll\n" white
					after 5000 "$self HTTPPoll $name"
				}

				set options(-proxy_gateway_ip) $gateway_ip
				set options(-proxy_session_id) $session_id

			}
		}
	}

	method HTTPPoll { name } {
#		variable proxy_session_id
#		variable proxy_gateway_ip
#		variable proxy_queued_data
#		variable options(-proxy_writing)

		if { ![info exists options(-proxy_session_id)]} {
			return
		}

		#TODO: Race condition!! A write can happen here
		set old_proxy_session_id $options(-proxy_session_id)
		set options(-proxy_session_id) ""

		if { $old_proxy_session_id == ""} {
			status_log "ERROR, RACE CONDITION, THIS SHOULD'T HAPPEN IN ::proxy::PollPOST!!!!\n" white
		} else {
			if { $old_proxy_session_id != ""} {

				set tmp_data "POST http://$options(-proxy_gateway_ip)/gateway/gateway.dll?Action=poll&SessionID=$old_proxy_session_id HTTP/1.1"
				set tmp_data "$tmp_data\r\nAccept: */*"
				set tmp_data "$tmp_data\r\nAccept-Encoding: gzip, deflate"
				set tmp_data "$tmp_data\r\nUser-Agent: MSMSGS"
				set tmp_data "$tmp_data\r\nHost: $options(-proxy_gateway_ip)"
				set tmp_data "$tmp_data\r\nProxy-Connection: Keep-Alive"
				set tmp_data "$tmp_data\r\nConnection: Keep-Alive"
				set tmp_data "$tmp_data\r\nPragma: no-cache"
				set tmp_data "$tmp_data\r\nContent-Type: application/x-msn-messenger"
				set tmp_data "$tmp_data\r\nContent-Length: 0"
				if {[$name cget -proxy_authenticate] == 1 } {
					set tmp_data "$tmp_data\r\nProxy-Authorization: Basic [::base64::encode [$name cget -proxy_user]:[$name cget -proxy_password]]"
				}
				set tmp_data "$tmp_data\r\n\r\n"

				#status_log "PROXY POST polling connection ($name):\n$tmp_data\n" blue
				set options(-proxy_writing) $tmp_data
				if { [catch {puts -nonewline [$name cget -sock] "$tmp_data" } res]} {
					$self connect $name [list $self RetryWrite $name]
					return 0
				}

			}

		}
	}


}



snit::type ProxyProxy {

	option -name

#	if { $initialize_amsn == 1 } {
#		variable proxy_host "";
#		variable proxy_port "";
#		variable proxy_type "http";
#		variable proxy_username "";
#		variable proxy_password "";
#		variable proxy_with_authentication 0;
#		variable proxy_header "";
#		variable proxy_dropped_cb "";
#	}

	method OnCallback {event callback} {
		variable proxy_dropped_cb

		switch $event {
			dropped { set proxy_dropped_cb $callback; }
		}
	}


	method Init { proxy ptype } {
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


	method LoginData { authenticate user passwd} {
		variable proxy_with_authentication
		variable proxy_username
		variable proxy_password

		set proxy_with_authentication $authenticate
		set proxy_username $user
		set proxy_password $passwd
	};# Proxy::LoginData

    # ::Proxy::Setup next readable_handler $socket_name
	method Setup {next_handler readable_handler name} {
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

	method Connect {name} {
		variable proxy_type
		variable proxy_username
		variable proxy_password
		variable proxy_with_authentication
		variable proxy_dropped_cb
		variable proxy_host
		variable proxy_port

		status_log "Calliinnnggggg Connect !!\n" white

		fileevent [$name cget -sock] writable {}

		$name configure -stat "pc"
		set remote_server [lindex [$name cget -server] 0]
		set remote_port 1863

		switch $proxy_type {
			http {

				set error_msg [fconfigure [$name cget -sock] -error]

				if { $error_msg != "" } {
					$name configure -error_msg $error_msg
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
				if { [catch {puts -nonewline [$name cget -sock] "$tmp_data"} res]} {
					#TODO: Error connecting, logout and show error message
					#$name configure -error_msg "[fconfigure [$name cget -sock] -error]"
					ClosePOST $name
				}
			}
			ssl {
				set tmp_data "CONNECT [join [list $remote_server $remote_port] ":"] HTTP/1.0"
				status_log "PROXY SEND: $tmp_data\n"
				puts -nonewline [$name cget -sock] "$tmp_data\r\n\r\n"
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

	method ClosePOST { name } {
		variable proxy_session_id
#		variable proxy_gateway_ip
		variable proxy_queued_data


		if {[info exists options(-proxy_session_id)]} {
			unset options(-proxy_session_id)
		}

		if {[info exists options(-proxy_gateway_ip)]} {
			unset options(-proxy_gateway_ip)
		}

		if {[info exists options(-proxy_queued_data)]} {
			unset options(-proxy_queued_data)
		}

		catch {
			fileevent [$name cget -sock] readable ""
			fileevent [$name cget -sock] writable ""
		}
		::MSN::CloseSB $name
	}



	method ConnectedPOST { name } {
		ReadPOST $name
		#$name configure -write_proc [list ::Proxy::WritePOST $name]
		#$name configure -read_proc [list ::Proxy::ReadPOST $name"]
		$name configure -connection_wrapper "ProxyPOST"
		#catch { fileevent [$name cget -sock] readable [$name cget -readable] } res
		catch { fileevent [$name cget -sock] readable "::Proxy::ReadPOST $name" } res
		status_log "Evaluating: [$name cget -connected]\n" white
		eval [$name cget -connected]
	}

	method PollPOST { name } {
		variable proxy_session_id
		variable proxy_gateway_ip
		variable proxy_queued_data
		variable proxy_username
		variable proxy_password
		variable proxy_with_authentication

		if { ![info exists options(-proxy_session_id)]} {
			return
		}

		#TODO: Race condition!! A write can happen here
		set old_proxy_session_id $options(-proxy_session_id)
		set options(-proxy_session_id) ""


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
				if { [catch {puts -nonewline [$name cget -sock] "$tmp_data" } res]} {
					$name configure -error_msg $res
					ClosePOST $name
				}

			}

		}
	}


	method WritePOST { name {msg ""} } {
		variable proxy_queued_data
		variable proxy_session_id
		variable proxy_gateway_ip
		variable proxy_username
		variable proxy_password
		variable proxy_with_authentication


		after cancel "::Proxy::PollPOST $name"
		after cancel "::Proxy::WritePOST $name"

		if {![info exists options(-proxy_queued_data)]} {
			set options(-proxy_queued_data) ""
		}

		if { ![info exists options(-proxy_session_id)]} {
			return
		}

		set old_proxy_session_id $options(-proxy_session_id)
		set options(-proxy_session_id) ""

		if { $msg != "" } {

			set options(-proxy_queued_data) "$options(-proxy_queued_data)$msg"

			if {$name != "ns" } {
				degt_protocol "->Proxy($name) $msg" sbsend
			} else {
				degt_protocol "->Proxy($name) $msg" nssend
			}
		}


		if { $old_proxy_session_id != "" } {


			set size [string length $options(-proxy_queued_data)]
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

			set tmp_data "$tmp_data\r\n\r\n[string range $options(-proxy_queued_data) 0 $strend]"

			status_log "PROXY POST Sending: ($name)\n$tmp_data\n" blue
			set options(-proxy_queued_data) [string replace $options(-proxy_queued_data) 0 $strend]
			if { [catch {puts -nonewline [$name cget -sock] "$tmp_data"} res] } {
				$name configure -error_msg $res
				ClosePOST $name
			}


		} else {
			set options(-proxy_session_id) $old_proxy_session_id
			after 500 "::Proxy::WritePOST $name"

		}

	}


	method ReadPOST { name } {

		variable proxy_session_id
		variable proxy_gateway_ip
		variable proxy_data

		after cancel "::Proxy::PollPOST $name"

		set sock [$name cget -sock]
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
				set options(-proxy_session_id) $session_id

			}
		}
	}

	method Read { name } {
		variable proxy_header
		variable proxy_dropped_cb

		set sock [$name cget -sock]

		if {[eof $sock]} {

			close $sock
			$name configure -stat "d"
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
					#$name configure -stat "d"
					status_log "CLOSING PROXY: [lindex $proxy_header 0]\n"

					# DEGT Use a callback mechanism to keep code pure
					if {$proxy_dropped_cb != ""} {
						set cbret [eval $proxy_dropped_cb "dropped" "$name"]
					}
					return 1
				}
				status_log "PROXY ESTABLISHED: running [$name cget -connected]\n"
				fileevent [$name cget -sock] readable [$name cget -readable]
				eval [$name cget -connected]
			}
		}
		return 0
	};# Proxy::Read

}
