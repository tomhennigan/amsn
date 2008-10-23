# proxy.tcl --
#
#	This file defines various procedures which implement a
#	Proxy access system. Code originally by Dave Mifsud,
#	converted to namespace and improved by D. Emilio Grimaldo T.
#	SOCKS5 support (integration) is experimental!!!
#

::Version::setSubversionId {$Id$}

package provide Proxy 0.1
package require http

# This should be converted to a proper package, to use with package require
source socks.tcl	;# SOCKS5 proxy support

#the framework for connections. You create an instance of this object only,
#never the other proxy objects directly

proc globalGotNexusReply { proxy token {total 0} {current 0} } {
	if {![catch {$proxy cget -name}]} {
		$proxy GotNexusReply $token $total $current
	} else {
		::http::cleanup $token
	}
}

proc globalGotAuthReply { proxy str token } {
	if {![catch {$proxy cget -name}]} {
		$proxy GotAuthReply $str $token
	} else {
		::http::cleanup $token
	}
}

proc globalWrite { proxy name {msg ""} } {
	if {![catch {$proxy cget -name}]} {
		$proxy write $name $msg
	}
}

#The only way to get HTTP proxy + SSL to work...
#http://wiki.tcl.tk/2627
#helped by patthoyts autoproxy!
proc HTTPsecureSocket { args } {
	set phost [::http::config -proxyhost]
	set pport [::http::config -proxyport]
	upvar host thost
	upvar port tport

	# if a proxy has been configured
	if {[string length $phost] && [string length $pport]} {
		#TODO: make async: set socket [socket -async $phost $pport]
		# create the socket to the proxy
		set socket [socket -async $phost $pport]
		fconfigure $socket -buffering line -translation crlf
		puts $socket "CONNECT $thost:$tport HTTP/1.0"
        	puts $socket "Host: $thost"
	        puts $socket "User-Agent: [http::config -useragent]"
		puts $socket "Content-Length: 0"
	        puts $socket "Proxy-Connection: Keep-Alive"
	        puts $socket "Connection: Keep-Alive"
		puts $socket "Cache-Control: no-cache"
		puts $socket "Pragma: no-cache"
		if { [::config::getKey proxyauthenticate] } {
			set proxy_user [::config::getKey proxyuser]
			set proxy_pass [::config::getKey proxypass]
			set auth [string map {"\n" "" } [base64::encode ${proxy_user}:${proxy_pass}]]
			puts $socket "Proxy-Authorization: Basic $auth"
		}
		puts $socket ""
		#flush $socket

		set reply ""
		while {[gets $socket r] > 0} {
			lappend reply $r
		}

		set result [lindex $reply 0]
		set code [lindex [split $result { }] 1]

		# be sure there's a valid response code
		# We use a regexp because of some (or maybe only one) proxy returning "HTTP/1.0  200 .." with two spaces, 
		# so the split makes the code the 3rd argument not the second, and $code becomes empty. 
		# refer to http://amsn.sf.net/forums/viewtopic.php?t=1030
		if {! [regexp {^HTTP/1\.[01] +2[0-9][0-9]} $result]} {
			return -code error $result
		}

		# now add tls to the socket and return it
		fconfigure $socket -blocking 0 -buffering none -translation binary
		return [::tls::import $socket]
	}

	# if not proxifying, just create a tls socket directly
	return [::tls::socket $thost $tport]
}

proc SOCKSsecureSocket { args } {
	set phost [::http::config -proxyhost]
	set pport [::http::config -proxyport]
	upvar host thost
	upvar port tport
	# if a proxy has been configured
	if {[string length $phost] && [string length $pport]} {
		#TODO: make async: set socket [socket -async $phost $pport]
		# create the socket to the proxy
		set socket [socket -async $phost $pport]

		set proxy_authenticate [expr [::config::getKey proxyauthenticate] == 1 ? 1 : 0]
		set proxy_user [::config::getKey proxyuser]
		set proxy_pass [::config::getKey proxypass]
		if {[catch {set res [::Socks5::Init $socket $thost $tport $proxy_authenticate $proxy_user $proxy_pass]} res] } {
			catch {close $socket}
		}
		if { $res != "OK" } {
			return -code error $res
		}

		# now add tls to the socket and return it
		fconfigure $socket -blocking 0 -buffering none -translation binary
		return [::tls::import $socket]

	}

	# if not proxifying, just create a tls socket directly
	return [::tls::socket $thost $tport]
}

proc SOCKSSocket { args } {
	set phost [::http::config -proxyhost]
	set pport [::http::config -proxyport]
	upvar host thost
	upvar port tport
	# if a proxy has been configured
	if {[string length $phost] && [string length $pport]} {
		#TODO: make async: set socket [socket -async $phost $pport]
		# create the socket to the proxy
		set socket [socket -async $phost $pport]

		set proxy_authenticate [expr [::config::getKey proxyauthenticate] == 1 ? 1 : 0]
		set proxy_user [::config::getKey proxyuser]
		set proxy_pass [::config::getKey proxypass]
		if {[catch {set res [::Socks5::Init $socket $thost $tport $proxy_authenticate $proxy_user $proxy_pass]} res] } {
			catch {close $socket}
		}
		if { $res != "OK" } {
			return -code error $res
		}

		return $socket

	}

	# if not proxifying, just create a socket directly
	return [socket $thost $tport]
}

::snit::type Proxy {

	delegate method * to proxy

	constructor {args} {
		if {[::config::getKey connectiontype] == "direct" } {
			install proxy using ProxyDirect %AUTO% -name $self
		} elseif {[::config::getKey connectiontype] == "http" } {
			install proxy using ProxyHTTP %AUTO% -name $self -direct 1
		} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "http" && 
			   [::config::getKey http_proxy_use_gateway 1]} {
			install proxy using ProxyHTTP %AUTO% -name $self -direct 0
		} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "http" && 
			   ![::config::getKey http_proxy_use_gateway 1]} {
			install proxy using ProxyDirect %AUTO% -name $self
		} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "socks5" } {
			install proxy using ProxyDirect %AUTO% -name $self
		} else {
			::config::setKey connectiontype "direct"
			install proxy using ProxyDirect %AUTO% -name $self
		}

		$self configurelist $args
	}

	destructor {
		catch { $proxy destroy }
	}
}

::snit::type ProxyDirect {

	option -name
	variable http_idlist
	variable sockErr

	method checkSocketErrors { sock } {
		fileevent $sock writable {}
		set sockErr [fconfigure $sock -err]
	}

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
		if { [catch {set sock [socket $tmp_serv $tmp_port]} res ] } {
			$sb configure -error_msg $res
			return -1
		}

		set sockErr ""
		fileevent $sock writable [list $self checkSocketErrors $sock]
		tkwait variable [myvar sockErr]
		if { $sockErr == "" } {
			$sb configure -sock $sock
                	if { [$sb cget -proxy_host] != ""} {
	                        if { [::config::getKey proxytype] == "http"} {
	                                set res [$self ConnectHTTP $sock $proxy_serv $proxy_port $proxy_authenticate $proxy_user $proxy_password]
	                                if { $res != "OK" } {
	                                        $sb configure -error_msg $res
	                                        return -1
	                                }
	                        } else {
	                                set res [::Socks5::Init $sock $proxy_serv $proxy_port $proxy_authenticate $proxy_user $proxy_password]
	                                if { $res != "OK" } {
	                                        $sb configure -error_msg $res
	                                        return -1
	                                }
	                        }
	                }
	                fconfigure $sock -buffering none -translation binary -blocking 0
	                fileevent $sock readable [list $sb receivedData]
	                set connected_command [$sb cget -connected]
	                lappend connected_command $sock
	                fileevent $sock writable $connected_command
			return 0
		} else {
			$sb configure -error_msg $sockErr
			return -1
		}
	}

	method ConnectHTTP {sck addr port auth user pass} {

		set http_idlist(stat,$sck) 0
		set http_idlist(data,$sck) ""

		
		set msg "CONNECT ${addr}:${port} HTTP/1.0\r\n"
		append msg "Host: ${addr}:${port}\r\n"
		append msg "User-Agent: [http::config -useragent]\r\n"
		append msg "Content-Length: 0\r\n"
		append msg "Proxy-Connection: Keep-Alive\r\n"
		append msg "Connection: Keep-Alive\r\n"
		append msg "Pragma: no-cache\r\n"
		append msg "Cache-Control: no-cache\r\n"
		if {$auth} {
			set basic [base64::encode "${user}:${pass}"]
			append msg "Proxy-Authorization: Basic $basic\r\n"
		}
		append msg "\r\n"
		
		status_log "sending $msg" blue
		fconfigure $sck -translation {binary binary} -blocking 0
		fileevent $sck readable [list $self ReceivedHTTPResponse $sck]

		puts -nonewline $sck "$msg"
		flush $sck


		status_log "HTTP going into tkwait\n"
		tkwait variable [myvar http_idlist(stat,$sck)]

		fileevent $sck readable {}
		set data [set http_idlist(data,$sck)]
		unset http_idlist(stat,$sck)
		unset http_idlist(data,$sck)
		if {[eof $sck]} {
			catch {close $sck}
			status_log "ERROR:Connection closed with HTTP Server!"
			return "ERROR:Connection closed with HTTP Server!"
		}

		if { ([string range $data 9 11] != "200") && ([string range $data 9 11] != "100")} {
			catch {close $sck}
			status_log "HTTP Proxy answered non 200 : $data" red
			return "ERROR: Proxy answered non 200"
		} else {
			fconfigure $sck -translation {auto auto}
			status_log "HTTP: OK"
			return "OK"
		}
	}
	method ReceivedHTTPResponse { sck } {
		if { [catch {set http_idlist(data,$sck) [read $sck]} res] } {
			status_log "Error when reading from http server : $res"
		}

		incr http_idlist(stat,$sck)
	}

	method authInit {} {
		global login_passport_url

		set proxy_host [ns cget -proxy_host]
		set proxy_port [ns cget -proxy_port]
		if {$proxy_host == "" } {
			::http::config -proxyhost ""
		} else {
			if { $proxy_port == "" } {
				set proxy_port 1080
			}
			::http::config -proxyhost $proxy_host -proxyport $proxy_port
		}

		if { [::config::getKey proxytype] == "http"} {
			status_log "registering http secure socket "
			if { [catch {http::register https 443 HTTPsecureSocket} res]} {
				MSN::logout
				MSN::reconnect "Proxy returned error: $res"
				return -1
			}
		} else {
			# http://wiki.tcl.tk/2627 :(
			if { [catch {http::register https 443 SOCKSsecureSocket} res]} {
				MSN::logout
				MSN::reconnect "Proxy returned error: $res"
				return -1
			}
		}

#		if { [::config::getKey nossl] == 1 } {
#			#If we can't use ssl, avoid getting url from nexus
#			set login_passport_url "https://login.passport.com/login2.srf"
#		} else {
			#Contact nexus to get login url
			set login_passport_url 0
			degt_protocol $self

			after 0 "catch {::http::geturl [list https://nexus.passport.com/rdr/pprdr.asp] -timeout 5000 -command {globalGotNexusReply $self}}"
#		}
	}

	method authenticate {str url} {
		set head [list Authorization "Passport1.4 OrgVerb=GET,OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom,sign-in=[::config::getKey login],pwd=[urlencode $::password],${str}"]
		#if { [::config::getKey nossl] == 1 || ([::config::getKey connectiontype] != "direct" && [::config::getKey connectiontype] != "http") } {
		#	set url [string map { https:// http:// } $url]
		#}
#		if { [::config::getKey nossl] == 1 } {
#			set url [string map { https:// http:// } $url]
#		}
		status_log "::DirectConnection::authenticate: Getting $url\n" blue
		if { [catch {::http::geturl $url -command "globalGotAuthReply $self [list $str]" -headers $head}] } {
			eval [ns cget -autherror_handler]
			#msnp9_auth_error
		}

	}


	method GotNexusReply {token {total 0} {current 0}} {

		global login_passport_url
		if { [::http::status $token] != "ok" || [::http::ncode $token ] != 200 } {
			#Nexus connection failed, so let's just set login URL manually
			set loginurl "https://login.live.com/login2.srf"
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

	option -direct
	option -name
	option -proxy_queued_data
	option -proxy_session_id
	option -proxy_gateway_ip
	option -proxy_writing
	variable poll_afterids
	variable created_sockets [list]

	constructor {args } {
		array set poll_afterids [list]
		$self configurelist $args
	}

	destructor {
		foreach name [array names poll_afterids]  {
			after cancel [set poll_afterids($name)]
		}
		foreach sock $created_sockets {
			catch {close $sock}
		}
	}

	method write { name {msg ""} } {
#		variable proxy_queued_data
#		variable proxy_session_id
#		variable proxy_gateway_ip
#		variable options(-proxy_writing)

		#Cancel any previous attemp to write or POLL
		after cancel [list $self HTTPPoll $name]
		array unset poll_afterids $name

		after cancel "globalWrite $self $name"

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

			if { $options(-direct) } {
				set tmp_data "POST /gateway/gateway.dll?SessionID=$old_proxy_session_id HTTP/1.1\r\n"
			} else {
				set tmp_data "POST http://$options(-proxy_gateway_ip)/gateway/gateway.dll?SessionID=$old_proxy_session_id HTTP/1.1\r\n"
			}
			append tmp_data "Accept: */*\r\n"
			append tmp_data "Content-Type: text/xml; charset=utf-8\r\n"
			append tmp_data "Content-Length: $size\r\n"
			append tmp_data "User-Agent: MSMSGS\r\n"
			append tmp_data "Host: $options(-proxy_gateway_ip)\r\n"
			append tmp_data "Proxy-Connection: Keep-Alive\r\n"
			append tmp_data "Connection: Keep-Alive\r\n"
			append tmp_data "Pragma: no-cache\r\n"
			append tmp_data "Cache-Control: no-cache\r\n"

			if {[$name cget -proxy_authenticate]  == 1 } {
				append tmp_data "Proxy-Authorization: Basic [::base64::encode [$name cget -proxy_user]:[$name cget -proxy_password]]\r\n"
			}


			append tmp_data "\r\n"
			append tmp_data $current_data

			#status_log "::HTTPConnection::Write: PROXY POST Sending: ($name)\n$tmp_data\n" blue
			set options(-proxy_writing) $tmp_data
			if { [catch {puts -nonewline [$name cget -sock] "$tmp_data"} res] } {
				$self connect $name [list $self RetryWrite $name]
				return 0
			}

		} else {

			set options(-proxy_session_id) $old_proxy_session_id
			after 500 "globalWrite $self $name"

		}

		return 0

	}

	method authInit {} {
		#catch {::http::unregister https}

		global tlsinstalled login_passport_url

                #Check if we need to install the TLS module
                if { $tlsinstalled == 0 && [checking_package_tls] == 0} {
                        ::autoupdate::installTLS
                        return -1
                }

                #If SSL is used, register https:// protocol
#                if { [::config::getKey nossl] == 0 } {
#                        http::register https 443 ::tls::socket
#                } else  {
#                        catch {http::unregister https}
#                }


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

		# http://wiki.tcl.tk/2627 :(
		if { [catch {http::register https 443 HTTPsecureSocket} res]} {
			MSN::logout
			MSN::reconnect "Proxy returned error: $res"
			return -1
		}

#		set ::login_passport_url "https://login.passport.com/login2.srf"
#		        if { [::config::getKey nossl] == 1 } {
                        #If we can't use ssl, avoid getting url from nexus
#                        set login_passport_url "https://login.passport.com/login2.srf"
#                } else {
                        #Contact nexus to get login url
                        set login_passport_url 0
                        degt_protocol $self

			#::http::geturl [list https://nexus.passport.com/rdr/pprdr.asp] -timeout 10000 -command [list globalGotNexusReply $self]
                        if { [catch {::http::geturl https://nexus.passport.com/rdr/pprdr.asp -timeout 10000 -command [list globalGotNexusReply $self]} res]} {
				MSN::logout
				MSN::reconnect "proxy error: $res"
				return -1
			}

#                }
		return 1

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

		#set url [string map { https:// http:// } $url]
		status_log "::HTTPConnection::authenticate: Getting $url\n" blue
		::http::geturl $url -command "$self GotAuthReply [list $str]" -headers $head
#			eval [ns cget -autherror_handler]
#
	}

        method GotNexusReply {token {total 0} {current 0}} {

                global login_passport_url
                if { [::http::status $token] != "ok" || [::http::ncode $token ] != 200 } {
                        #Nexus connection failed, so let's just set login URL manually
                        set loginurl "https://login.live.com/login2.srf"
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

		#status_log "Canceling \"$self HTTPPoll $name\""
		after cancel [list $self HTTPPoll $name]
		array unset poll_afterids $name
		
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
		set created_sockets [lreplace $created_sockets [lsearch $created_sockets $sock] [lsearch $created_sockets $sock]]

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
			set proxy_host [$sb cget -force_gateway_server]
			if {$proxy_host == "" } {
				set proxy_host "gateway.messenger.hotmail.com"
			}
			
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
		lappend created_sockets $sock

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

		if { $options(-direct) } {
			set tmp_data "POST /gateway/gateway.dll?Action=open&Server=$server&IP=$remote_server HTTP/1.1\r\n"
		} else {
			set tmp_data "POST http://gateway.messenger.hotmail.com/gateway/gateway.dll?Action=open&Server=$server&IP=$remote_server HTTP/1.1\r\n"
		}
	
		append tmp_data "Accept: */*\r\n"
		append tmp_data "Content-Type: text/xml; charset=utf-8\r\n"
		append tmp_data "Content-Length: 0\r\n"
		append tmp_data "User-Agent: MSMSGS\r\n"
		append tmp_data "Host: gateway.messenger.hotmail.com\r\n"
		append tmp_data "Proxy-Connection: Keep-Alive\r\n"
		append tmp_data "Connection: Keep-Alive\r\n"
		append tmp_data "Pragma: no-cache\r\n"
		append tmp_data "Cache-Control: no-cache\r\n"

		if {[$sb cget -proxy_authenticate] == 1 } {
			append tmp_data "Proxy-Authorization: Basic [::base64::encode [$sb cget -proxy_user]:[$sb cget -proxy_password]]\r\n"
		}
		append tmp_data "\r\n"
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
		variable options

		after cancel [list $self HTTPPoll $name]
		array unset poll_afterids $name

		set sock [$name cget -sock]
		if {[catch {eof $sock} res]} {
			status_log "::HTTPConnection::HTTPRead: Error, closing\n" red
			catch { close $sock }
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
				set poll_afterids($name) [after 2000 [list $self HTTPPoll $name]]
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
					set content_data [nbread $sock $content_length]
				}

				if {$content_data != "" } {
					catch {$name receivedData $content_data}
				}

				# the handleCommand *could* potentially destroy our own object for some reason...
				# we must be prepared to not crash because of that.
				if { [catch { 
					if { $session_id != ""} {
						#status_log "Scheduling HTTPPoll\n" white
						set poll_afterids($name) [after 2000 [list $self HTTPPoll $name]]
					}
					
					set options(-proxy_gateway_ip) $gateway_ip
					set options(-proxy_session_id) $session_id
				}] } {
					after cancel [list $self HTTPPoll $name]
				}
			}
		}
	}

	method HTTPPoll { name } {
#		variable proxy_session_id
#		variable proxy_gateway_ip
#		variable proxy_queued_data
#		variable options(-proxy_writing)

		array unset poll_afterids $name
		if { ![info exists options(-proxy_session_id)]} {
			return
		}

		#TODO: Race condition!! A write can happen here
		set old_proxy_session_id $options(-proxy_session_id)
		set options(-proxy_session_id) ""

		if { $old_proxy_session_id == ""} {
			status_log "ERROR, RACE CONDITION, THIS SHOULD'T HAPPEN IN HTTPPoll with \"$self HTTPPoll $name\" !!!!!!" white
		} else {
			if { $old_proxy_session_id != ""} {

				if { $options(-direct) } {
					set tmp_data "POST /gateway/gateway.dll?Action=poll&SessionID=$old_proxy_session_id HTTP/1.1\r\n"
				} else {
					set tmp_data "POST http://$options(-proxy_gateway_ip)/gateway/gateway.dll?Action=poll&SessionID=$old_proxy_session_id HTTP/1.1\r\n"
				}
				
				append tmp_data "Accept: */*\r\n"
				append tmp_data "Content-Type: text/xml; charset=utf-8\r\n"
				append tmp_data "Content-Length: 0\r\n"
				append tmp_data "User-Agent: MSMSGS\r\n"
				append tmp_data "Host: $options(-proxy_gateway_ip)\r\n"
				append tmp_data "Proxy-Connection: Keep-Alive\r\n"
				append tmp_data "Connection: Keep-Alive\r\n"
				append tmp_data "Pragma: no-cache\r\n"
				append tmp_data "Cache-Control: no-cache\r\n"
				
				if {[$name cget -proxy_authenticate] == 1 } {
					append tmp_data "Proxy-Authorization: Basic [::base64::encode [$name cget -proxy_user]:[$name cget -proxy_password]]\r\n"
				}

				append tmp_data "\r\n"


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
