
snit::type SIPConnection {
	option -user -default ""
	option -password -default ""
	option -request_handler -default ""
	option -error_handler -default ""
	option -user_agent -default "aTSC/0.1"

	delegate option {-host -port -transport
		-proxy -proxy_host -proxy_port
		-proxy_authenticate -proxy_user -proxy_password} to socket


	variable compact_form 
	variable reasons

	variable state ""
	variable cseqs
	variable callid_handler
	variable call_from
	variable call_to
	variable call_cseq
	variable call_route
	variable call_contact
	variable call_via

	constructor { args } {
		install socket using SIPSocket %AUTO% -sipconnection $self
		$self configurelist $args

		array set compact_form [list "call-id" "i" \
					    "contact" "m" \
					    "content-encoding" "e" \
					    "content-length" "l" \
					    "content-type" "c" \
					    "from" "f" \
					    "subject" "s" \
					    "supported" "k" \
					    "to" "t" \
					    "via" "v" \
					    "event" "o" \
					    "allow-events" "u"]

		array set reasons [list 100 "Trying" \
					    180 "Ringing" \
					    181 "Call Is Being Forwarded" \
					    182 "Queues" \
					    183 "Session Progress" \
					    200 "OK" \
					    300 "Multiple Choices" \
					    301 "Moved Permanently" \
					    302 "Moved Temporarily" \
					    305 "Use Proxy" \
					    380 "Alternative Service" \
					    400 "Bad Request" \
					    401 "Unauthorized" \
					    402 "Payment Required" \
					    403 "Forbidden" \
					    404 "Not Found" \
					    405 "Method Not Allowed" \
					    406 "Not Acceptable" \
					    407 "Proxy Authentication Required" \
					    408 "Request Timeout" \
					    410 "Gone" \
					    413 "Request Entity Too Large" \
					    414 "Request-URI Too Long" \
					    415 "Unsupported Media Type" \
					    416 "Unsupported URI Scheme" \
					    420 "Bad Extension" \
					    421 "Extension Required" \
					    423 "Interval Too Brief" \
					    480 "Temporarily Unavailable" \
					    481 "Call/Transaction Does Not Exist" \
					    482 "Loop Detected" \
					    483 "Too Many Hops" \
					    484 "Address Incomplete" \
					    485 "Ambiguous" \
					    486 "Busy Here" \
					    487 "Request Terminated" \
					    488 "Not Acceptable Here" \
					    491 "Request Pending" \
					    493 "Undecipherable" \
					    500 "Server Internal Error" \
					    501 "Not Implemented" \
					    502 "Bad Gateway" \
					    503 "Service Unavailable" \
					    504 "Server Time-out" \
					    505 "Version Not Supported" \
					    513 "Message Too Large" \
					    600 "Busy Everywhere" \
					    603 "Decline" \
					    604 "Does Not Exist Anywhere" \
					    606 "Not Acceptable"]
	}

	destructor {
		$self Disconnect
	}


	########################################
	############# Connection ###############
	########################################

	method Connect { } {
		if {[$socket IsConnected] } {
			return
		}

		if { [$socket Connect] } {
			after 20000 [list $self KeepAlive]
		}
	}

	method Disconnect { } {
		set state ""
		if {[$socket IsConnected] } {
			$socket Disconnect
		}
	}

	method Disconnected { } {
		if {$state != "" } {
			if {$options(-error_handler) != "" } {
				if {[catch {eval [linsert $options(-error_handler) end DISCONNECTED]} result]} {
					bgerror $result
				}
			}
		}
		set state ""
		after cancel [list $self KeepAlive]
		after cancel [list $self RegisterExpires]
	}

	method KeepAlive { } {
		#puts "Keepalive"
		if { [$socket Send "\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n"] } {
			after 20000 [list $self KeepAlive]
		} else {
			$self Disconnect
		}

	}

	method HandleMessage { start headers body } {
		if {[string range $start 0 6] == "SIP/2.0" } {
			set type "status"
		} elseif {[string range $start end-6 end] == "SIP/2.0" } {
			set type "request"
		} else {
			puts "Received a non SIP message "
			if {$options(-error_handler) != "" } {
				if {[catch {eval [linsert $options(-error_handler) end NOT_SIP]} result]} {
					bgerror $result
				}				
			}
			return
		}
		
		set callid [$self GetHeader $headers "Call-ID"]

		set call_from($callid) [$self GetHeader $headers "From"]
		set call_to($callid) [$self GetHeader $headers "To"]

		set route [$self GetHeader $headers "Record-Route"]
		set contact [$self GetHeader $headers "Contact"]

		set call_via($callid) [$self GetHeaders $headers "Via"]

		if {$route != "" && $contact != "" } {
			set call_route($callid) $route
			set call_contact($callid) $contact
		}
		
		if {![info exists call_cseq($callid)] } {
			set call_cseq($callid) [lindex [$self GetHeader $headers "CSeq"] 0]
		}

		#puts "Received a $type message : $start : \n$headers\n\n$body"
		if {$type == "status" } {
			if { ![info exists callid_handler($callid)] } {
				# Answer with 'Call/Transaction does not exit error
				$self Send [$self BuildResponse $callid [$self GetCommand $headers] 481]
				puts "ERROR : unknown callid : $callid"
				if {$options(-error_handler) != "" } {
					if {[catch {eval [linsert $options(-error_handler) end UNKNOWN_CALL]} result]} {
						bgerror $result
					}				
				}
			} else {
				set handler $callid_handler($callid)
				eval [linsert $handler end $start $headers $body]
			}
		} else {

			if { [info exists callid_handler($callid)] } {
				eval [linsert $callid_handler($callid) end $start $headers $body]
			} elseif {$options(-request_handler) != ""} {
				if {[$self GetCommand $headers] == "INVITE" } {
					$self Send [$self BuildResponse $callid INVITE 100]
					set sdp [$self ParseSDP $body]
					set candidates [lindex $sdp 0]
					set codecs [lindex $sdp 1]
					set callid_handler($callid) [list $self InviteRequestHandler $callid]
					eval [linsert $options(-request_handler) end $callid INVITE [list $candidates $codecs]]
				} else {
					puts "ERROR: Received non-INVITE Request"
					if {$options(-error_handler) != "" } {
						if {[catch {eval [linsert $options(-error_handler) end NOT_INVITE]} result]} {
							bgerror $result
						}				
					}
				}
			}
		}
	}


	########################################
	############### REGISTER ###############
	########################################

	method Register { {callbk ""} } {
		$self Connect

		if { $state == "REGISTERED" } {
			if {$callbk != "" } {
				if {[catch {eval $callbk} result]} {
					bgerror $result
				}
			}
			return
		}

		set auth "$options(-user):$options(-password)"
		set auth [string map {"\n" "" } [base64::encode $auth]]

		set request [$self BuildRequest REGISTER [lindex [split $options(-user) @] 1] $options(-user) ]
		set callid [lindex $request 0]

		set msg [lindex $request 1]
		append msg "ms-keep-alive: UAC;hop-hop=yes\r\n"
		append msg "o: registration\r\n"
		append msg "Authorization: Basic $auth\r\n"

		set callid_handler($callid) [list $self RegisterResponse $callbk]

		$self Send $msg

	}

	method RegisterExpires { } {
		set state ""
		sip Register
	}

	method RegisterResponse {callbk response headers body} {
		if {[lindex $response 1] == "200" } {
			set state "REGISTERED"
			#puts "registered"
			set expires [$self GetHeader $headers "Expires"]
			after [expr {$expires * 1000 - 10000}] [list $self RegisterExpires] 
			#puts "Current time is [clock seconds]"
			if {$callbk != "" } {
				if {[catch {eval $callbk} result]} {
					bgerror $result
				}				
			}
		} else {
			#puts "error on registration"
			if {$options(-error_handler) != "" } {
				if {[catch {eval [linsert $options(-error_handler) end REGISTRATION]} result]} {
					bgerror $result
				}				
			}
		}
	}


	########################################
	################ INVITE ################
	########################################

	method Invite {destination candidate_list codec_list {callbk ""}} {
		set sdp [$self BuildSDP $candidate_list $codec_list]

		set request [$self BuildRequest INVITE $destination $destination]
		set callid [lindex $request 0]
		set msg [lindex $request 1]
		append msg "Ms-Conversation-ID: f=0\r\n"

		set callid_handler($callid) [list $self InviteResponse $callid $callbk]

		$self Register [list $self InviteCB $msg $sdp $callbk]
		return $callid
	}

	method InviteCB {msg sdp callbk} {
		$self Send $msg "application/sdp" $sdp
	}

	method InviteResponse {callid callbk response headers body } {
		#puts "Received INVITE response"

		# Answer with ACK to any INVITE response (200 ok, or call terminated, or busy..)
		# Answer only to INVITE responses
		if {[$self GetCommand $headers] == "INVITE"} {
			set status [lindex $response 1] 
			if {$status >= "200" } {
				$self SendACK $callid
			}
			
			if {$status == "100" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid TRYING ""]} result]} {
						bgerror $result
					}
				}
			} elseif {$status == "180" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid RINGING ""]} result]} {
						bgerror $result
					}
				}
			} elseif {$status == "200" } {
				
				set sdp [$self ParseSDP $body]
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid OK $sdp]} result]} {
						bgerror $result
					}
				}
			} elseif {$status == "408" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid NO_ANSWER ""]} result]} {
						bgerror $result
					}
				}
			} elseif {$status == "480" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid UNAVAILABLE ""]} result]} {
						bgerror $result
					}
				}
			} elseif {$status == "486" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid BUSY ""]} result]} {
						bgerror $result
					}
				}
			} elseif {$status == "487" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid TERMINATED ""]} result]} {
						bgerror $result
					}
				}
			} elseif {$status == "603" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid DECLINED ""]} result]} {
						bgerror $result
					}
				}
			} elseif {$status == "504" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid TIMEOUT ""]} result]} {
						bgerror $result
					}
				}
			} else {
				# TODO : Maybe some other messages are not errors..
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid ERROR [lrange $response 1 end]]} result]} {
						bgerror $result
					}
				}
			}
		} elseif {[$self GetCommand $headers] == "BYE"} {
			# Answer 200 OK only when receiving the BYE request
			if {[lindex $response 0] == "BYE" } {
				$self Send [$self BuildResponse $callid BYE 200]
			} elseif { [lindex $response 1] == "200" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid CLOSED BYE]} result]} {
						bgerror $result
					}				
				}
			}
		} elseif {[$self GetCommand $headers] == "CANCEL"} {
			set status [lrange $response 1 end]
			if {$callbk != "" } {
				if {[catch {eval [linsert $callbk end $callid CANCEL $status]} result]} {
					bgerror $result
				}				
			}
		}
		
	}

	method InviteRequestHandler {callid response headers body } {
		if {[$self GetCommand $headers] == "ACK"} {
			if {[catch {eval [linsert $options(-request_handler) end $callid ACK ""]} result]} {
				bgerror $result
			}				
		} elseif {[$self GetCommand $headers] == "BYE"} {
			# Answer 200 OK only when receiving the BYE request
			if {[lindex $response 0] == "BYE" } {
				$self Send [$self BuildResponse $callid BYE 200]
			}
			if {[catch {eval [linsert $options(-request_handler) end $callid CLOSED BYE]} result]} {
				bgerror $result
			}				
		} elseif {[$self GetCommand $headers] == "CANCEL"} {
			$self Send [$self BuildResponse $callid CANCEL 200]
			if {[catch {eval [linsert $options(-request_handler) end $callid CLOSED CANCEL]} result]} {
				bgerror $result
			}
		}			

		
	}

	method AnswerInvite { callid status {detail ""} } {
		switch -- $status {
			"RINGING" {
				set status 180
				set content_type ""
				set content ""
			}
			"BUSY" {
				set status 486
				set content_type ""
				set content ""
			}
			"OK" {
				set status 200
				set content_type "application/sdp"
				set candidates [lindex $detail 0]
				set codecs [lindex $detail 1]
				set content [$self BuildSDP $candidates $codecs]
			}
			"DECLINE" {
				set status 603
				set content_type ""
				set content ""
			}
			default {
				error "Unknown Status"
			}
		}
		$self Send [$self BuildResponse $callid INVITE $status] $content_type $content
	}


	method SendACK { callid } {
		$self Send [lindex [$self BuildRequest ACK [$self GetDestination $callid] [$self GetDestination $callid] $callid] 1]
	}

	########################################
	################ CANCEL ################
	########################################

	method Cancel { callid } {
		if { ![info exists call_to($callid)] } {
			return
		}
		$self Register [list $self CancelCB $callid]
	}

	method CancelCB { callid } {
		$self Send [lindex [$self BuildRequest CANCEL [$self GetDestination $callid] [$self GetDestination $callid] $callid] 1]

	}

	########################################
	################# BYE ##################
	########################################

	method Bye { callid } {
		if { ![info exists call_route($callid)] ||
		     ![info exists call_contact($callid)] } {
			return
		}
		$self Register [list $self ByeCB $callid]
	}

	method ByeCB { callid } {

		set uri [string range $call_route($callid) [expr {[string first "<sip:" $call_route($callid)] + 5}] [expr {[string first ">" $call_route($callid)] - 1}]]

		set msg [lindex [$self BuildRequest BYE $uri [$self GetDestination $callid] $callid] 1]		
		
		$self Send $msg
	}


	
	########################################
	######### Message Builders #############
	########################################

	method BuildRequest { request uri to {callid ""} } {
		$self Connect

		set sockname [$socket GetInfo]

		if {$callid == "" } {
			if { ![info exists cseqs($request)] } {
				set cseqs($request) 1
			} else {
				incr cseqs($request)
			}
			set callid [$self GenerateCallID]
			set call_cseq($callid) $cseqs($request)
			set call_from($callid) "<sip:$options(-user)>;tag=[$self GenerateTag];epid=[$self GenerateEpid]"
			set call_to($callid) "<sip:$to>"
		}

		set cseq $call_cseq($callid) 

		if {$request == "BYE" } {
			incr cseq
		}

		set msg "$request sip:$uri SIP/2.0\r\n"
		append msg "v: SIP/2.0/TLS [lindex $sockname 0]:[lindex $sockname 2]\r\n"
		append msg "Max-Forwards: 70\r\n"
		append msg "f: $call_from($callid)\r\n"
		append msg "t: $call_to($callid)\r\n"
		append msg "i: $callid\r\n"
		append msg "CSeq: $cseq $request\r\n"
		if {$request == "REGISTER" || 
		    $request == "INVITE" } {
			append msg "m: <sip:[lindex $sockname 0]:[lindex $sockname 2];"
			append msg "transport=tls>;proxy=replace\r\n"
		}
		append msg "User-Agent: $options(-user_agent)\r\n"
		if {$request == "BYE" } {
			append msg "Route: $call_contact($callid)\r\n"	
		}

		return [list $callid $msg]
	}

	method BuildResponse { callid request status } {
		$self Connect

		set sockname [$socket GetInfo]
 
		set reason ""
		if {[info exists reasons($status)] } {
			set reason $reasons($status)
		} 

		set msg "SIP/2.0 $status $reason\r\n"
		foreach via $call_via($callid) {
			append msg "v: $via\r\n"
		}
		if {$request == "INVITE" && $status >= 180} {
			append msg "Record-Route: $call_route($callid)\r\n"
		}
		append msg "Max-Forwards: 70\r\n"
		append msg "f: $call_from($callid)\r\n"
		append msg "t: $call_to($callid)\r\n"
		append msg "i: $callid\r\n"
		append msg "CSeq: $call_cseq($callid) $request\r\n"
		if {$request == "INVITE" && $status == 200} {
			append msg "m: <sip:[lindex $sockname 0]:[lindex $sockname 2];"
			append msg "transport=tls>;proxy=replace\r\n"
		}
		append msg "User-Agent: $options(-user_agent)\r\n"

		return $msg
	}

	method BuildSDP { candidate_list codec_list } {

		set pt_list ""
		foreach codec $codec_list {
			foreach {encoding_name payload_type bitrate fmtp} $codec break
			append pt_list " $payload_type"
		}

		set rtcp_port 0
		set default_ip 0
		set default_port 0
		foreach candidate $candidate_list {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break
			if {$component_id == 1 && $default_ip == 0} {
				set default_ip $ip
				set default_port $port
			} elseif { $component_id == 2 && $ip == $default_ip} {
				set rtcp_port $port
				break
			}
		}

		set sdp "v=0\n"
		append sdp "o=- 0 0 IN IP4 $default_ip\r\n"
		append sdp "s=session\r\n"
		append sdp "c=IN IP4 $default_ip\r\n"
		append sdp "b=CT:100\r\n"
		append sdp "t=0 0\r\n"
		append sdp "m=audio $default_port RTP/AVP$pt_list\r\n"
		foreach candidate $candidate_list {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break
			if {$candidate_id != "" && $password != "" } {
				append sdp "a=candidate:$candidate_id $component_id $password $transport $qvalue $ip $port\r\n"
			}
		}
		if {$rtcp_port != 0 } {
			append sdp "a=rtcp:$rtcp_port\r\n"
		}

		foreach codec $codec_list {
			foreach {encoding_name payload_type bitrate fmtp} $codec break
			append sdp "a=rtpmap:$payload_type $encoding_name/$bitrate\r\n"
			if { $fmtp != "" } {
				append sdp "a=fmtp:$payload_type $fmtp\r\n"
			}
		}
		append sdp "a=encryption:rejected\r\n"

		return $sdp
	}


	method Send { headers {content_type ""} {body ""}} {
		$self Connect

		set msg $headers
		if {$content_type != ""} {
			append msg "c: $content_type\r\n"
		}
		append msg "l: [string length $body]\r\n"
		append msg "\r\n"
		append msg "$body"

		if { ![$socket Send $msg] } {
			$self Disconnect
		}

	}

	########################################
	######### Helper Functions #############
	########################################

	method GetHeader { headers name} {
		return [lindex [$self GetHeaders $headers $name] 0]
	}

	method GetHeaders { headers name} {
		if {[info exist compact_form([string tolower $name])] } {
			set short_name $compact_form([string tolower $name])
		} else {
			set short_name $name
		}
		set reg {^}
		append reg "($name|$short_name)"
		append reg {:[ \t]*(.*)[ \t]*$}
		set result [regexp -nocase -all -inline -line $reg $headers]
		set header [list]
		foreach {match field value} $result {
			lappend header [string trim $value]
		}
		return $header
	}

	method GetDestination { callid } {
		set destination [string range $call_to($callid) [expr {[string first "<sip:" $call_to($callid)] + 5}] [expr {[string first ">" $call_to($callid)] - 1}]]
		set destination [lindex [split $destination ";"] 0]
		set destination [lindex [split $destination ":"] 0]

		return $destination
	}
	
	method GetCommand { headers } {
		set cseq [$self GetHeader $headers "CSeq"]
		return [lindex [split $cseq] 1]
	}

	method Random { min max } {
		return [expr {int($min + rand() * (1+$max-$min))}]
	}

	method GenerateHex { num } {
		set res ""
		while { $num > 0 } {
			append res [format %X [$self Random 0 15]]
			incr num -1
		}
		return $res
	}
	
	method GenerateEpid { } {
		return [$self GenerateHex 10]
	}

	method GenerateTag { } {
		return [$self GenerateHex 10]
	}

	method GenerateCallID { } {
		return [$self GenerateHex 32]
	}

	method ParseSDP { body } {
		set codecs [list]
		set ice_candidates [list]
		set rtcp_port 0

		foreach line [split $body "\n"] {
			set line [string trim $line]
			set field [string range $line 0 0]
			set value [string range $line 2 end]

			switch -- $field {
				"c" {
					set ip [lindex [split $value] 2]
				}
				"m" {
					set port [lindex [split $value] 1]
				}
				"a" {
					set attribute [lindex [split $value ":"] 0]
					set attr [string range $value [expr {[string length $attribute] +1}] end]
					#puts "$attribute -- $attr"
					switch -- $attribute {
						"candidate" {
							lappend ice_candidates [split $attr ""]
						}
						"rtcp" {
							set rtcp_port $attr
						}
						"rtpmap" {
							set pt [lindex $attr 0]
							set codec [lindex $attr 1]
							set encoding_name [lindex [split $codec "/"] 0]
							set bitrate [lindex [split $codec "/"] 1]
							
							lappend codecs [list $encoding_name $pt $bitrate]
						}
					}
				}
			}
		}
		if {$rtcp_port == 0 } {
			set rtcp_port $port
			incr rtcp_port
		}
		set candidates [list]
		lappend candidates [list "" 1 "" UDP 1 $ip $port]
		lappend candidates [list "" 2 "" UDP 1 $ip $rtcp_port]
		
		foreach candidate $ice_candidates {
			lappend candidates $candidate
		}

		return [list $candidates $codecs]
	}

}


###########################################
#  SIPSocket is a socket wrapper for SIP  #
###########################################

snit::type SIPSocket {
	option -host -default "vp.sip.messenger.msn.com"
	option -port -default "443"
	option -transport -default "tls"
	option -proxy -default "direct" -configuremethod ProxyChanged
	option -proxy_host -default ""
	option -proxy_port -default ""
	option -proxy_authenticate -default 0
	option -proxy_user -default ""
	option -proxy_password -default ""
	option -sipconnection

	variable sock ""

	constructor { args } {
		$self configurelist $args
	}

	destructor {
		$self Disconnect
	}

	method Disconnect { } {
		catch {close $sock}
		set sock ""
		$options(-sipconnection) Disconnected
	}

	method IsConnected { } {
		return [expr {$sock != ""}]
	}

	method ProxyChanged {option value} {
		switch -- $value {
			"direct" -
			"socks" -
			"http" {
				set options($option) $value
			}
			default {
				error "Unknown value '$value' to -proxy option. Accepted values are : 'direct', 'socks' and 'http'"
			}
		}
	}

	method Connect {} {
	
		if { $options(-transport) == "tls" } {
			package require tls
		} else {

			error "Only 'tls' transport currently supported!"
		}

		switch -- $options(-proxy) {
			"direct" {
				set sock [::tls::socket $options(-host) $options(-port)]
			}
			"socks" {
				# FIXME : we should 'package require socks' ...
				# But socks.tcl must first be made into a proper package

				set socket [socket -async $options(-proxy_host) $options(-proxy_port)]
			
				set res [::Socks5::Init $socket $options(-host) $options(-port) \
					     $options(-proxy_authenticate) \
					     $options(-proxy_user) $options(-proxy_pass)]

				if { $res != "OK" } {
					error $res
				}

				# now add tls to the socket and return it
				fconfigure $socket -blocking 0 -buffering none -translation binary
				set sock [::tls::import $socket]

			}
			"http" {
				set socket [socket -async $options(-proxy_host) $options(-proxy_port)]
				fconfigure $socket -buffering line -translation crlf
				puts $socket "CONNECT $options(-host):$options(-port) HTTP/1.0"
				puts $socket "Host: $options(-host)"
				puts $socket "User-Agent: $options(-user_agent)"
				puts $socket "Content-Length: 0"
				puts $socket "Proxy-Connection: Keep-Alive"
				puts $socket "Connection: Keep-Alive"
				puts $socket "Cache-Control: no-cache"
				puts $socket "Pragma: no-cache"
				
				if { $options(-proxy_authenticate) } {
					set auth "$options(-proxy_user):$options(-proxy_pass)"
					set auth [string map {"\n" "" } [base64::encode $auth]]
					puts $socket "Proxy-Authorization: Basic $auth"
				}
				puts $socket ""

				set reply ""
				while {[gets $socket r] > 0} {
					lappend reply $r
				}

				set result [lindex $reply 0]
				set code [lindex [split $result { }] 1]

				# be sure there's a valid response code
				# We use a regexp because of some (or maybe only one) 
				# proxy returning "HTTP/1.0  200 .." with two spaces, 
				# so the split makes the code the 3rd argument not 
				# the second, and $code becomes empty. 
				# refer to http://amsn.sf.net/forums/viewtopic.php?t=1030
				if {! [regexp {^HTTP/1\.[01] +2[0-9][0-9]} $result]} {
					return -code error $result
				}

				# now add tls to the socket and return it
				fconfigure $socket -blocking 0 -buffering none -translation binary
				set sock [::tls::import $socket]
			}
			default {
				error "Unkwown proxy method : $options(-proxy)"
			}
		}

		fconfigure $sock -buffering none -translation binary
		fileevent $sock readable [list $self SocketReadable]

		return 1
	}

	method Send { data } {
		degt_protocol "-->SIP ($options(-host)) $data" "sbsend"
		
		if {[catch {puts -nonewline $sock $data}] } {
			$self Disconnect
			return 0
		} else {
			return 1
		}
	}

	method SocketReadable { } {
		if { [eof $sock] } {
			#puts "Socket $sock reached eof"
			$self Disconnect
			return
		}

		set start [string trim [gets $sock]]
		if {$start == "" } {
			$self Disconnect
			return
		}
		set headers ""
		set body ""
		while {[string length [set r [string trim [gets $sock]]]] > 0} {
			append headers "$r\n"
		}
		set content_length [$options(-sipconnection) GetHeader $headers "Content-Length"]
		if {$content_length > 0 } {
			set body [read $sock $content_length]
		}

		degt_protocol "<--SIP ($options(-host)) $start\n$headers\n\n$body" "sbrecv"
		$options(-sipconnection) HandleMessage $start $headers $body
	}

	method GetInfo { } {
		return [fconfigure $sock -sockname]
	}
}


proc createSIP { {host "vp.sip.messenger.msn.com"} } {
	global sso
	set token [$sso GetSecurityTokenByName Voice]
	catch {sip destroy}
	return [SIPConnection create sip -user [::config::getKey login] -password [$token cget -ticket] -error_handler errorSIP -request_handler requestSIP -host $host]
}

proc inviteSIP { email } {
	global farsight
	global sip_codecs
	global sip_candidates
	global sip_codecs_done
	global sip_candidates_done

	closeFarsight
	set sip_codecs [list]
	set sip_candidates [list]
	set sip_codecs_done 0
	set sip_candidates_done 0

	set farsight [open "| ./utils/farsight/farsight y x" r+]
	fileevent $farsight readable [list farsightRead $farsight $email]
}

proc farsightRead { farsight email} {
	global sip_codecs
	global sip_candidates
	global sip_codecs_done
	global sip_candidates_done

	if { [eof $farsight] } {
		closeFarsight
		return
	}

	set line [gets $farsight]
	if {[string first "LOCAL_CODEC: " $line] == 0} {
		set codec [string range $line 13 end]
		foreach {pt name rate} [split $codec " "] break
		if {$name == "PCMA" || $name == "PCMU" || 
		    $name == "SIREN" || $name == "G723" || 
		    $name == "AAL2-G726-32" || $name == "x-msrta"} {
			lappend sip_codecs [list $name $pt $rate]
		}
	} elseif  {[string first "LOCAL_CANDIDATE: " $line] == 0} {
		set candidate [string range $line 17 end]
		lappend sip_candidates [split $candidate " "]
	} elseif  {$line == "LOCAL_CODECS_DONE"} {
		set sip_codecs_done 1
	} elseif  {$line == "LOCAL_CANDIDATES_DONE"} {
		set sip_candidates_done 1
	}
	if {$sip_codecs_done && $sip_candidates_done } {
		sip Invite $email $sip_candidates $sip_codecs inviteSIPCB
		set sip_codecs_done 0
	}
}

proc inviteSIPCB { callid status detail} {
	global farsight
	puts "Invite SIP Response $callid : $status -- $detail"
	if { $status == "OK" } {
		set candidates [lindex $detail 0]
		set codecs [lindex $detail 1]
		foreach candidate $candidates {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break			
			puts $farsight "REMOTE_CANDIDATE: $candidate_id $component_id $password $transport $qvalue $ip $port"
			#puts "REMOTE_CANDIDATE: $candidate_id $component_id $password $transport $qvalue $ip $port"
		}
		puts $farsight "REMOTE_CANDIDATES_DONE"
		#puts "REMOTE_CANDIDATES_DONE"
		
		foreach codec $codecs {
			foreach {encoding_name payload_type bitrate} $codec break
			puts $farsight "REMOTE_CODEC: $payload_type $encoding_name $bitrate"
			#puts "REMOTE_CODEC: $payload_type $encoding_name $bitrate"
		}
		puts $farsight "REMOTE_CODECS_DONE"
		#puts "REMOTE_CODECS_DONE"
		
		flush $farsight
	} elseif {$status != "TRYING" && $status != "RINGING" } {
		closeFarsight
	}
}

proc requestSIP { callid what detail } {
	global farsight
	global sip_remote_candidates
	global sip_remote_codecs

	puts "Received $what : $callid - $detail"
	if {$what == "INVITE" } {

		set sip_remote_candidates [lindex $detail 0]
		set sip_remote_codecs [lindex $detail 1]

		set farsight [open "| ./utils/farsight/farsight x y " r+]
		sip AnswerInvite $callid RINGING
	} elseif {$what == "BYE" } {
		closeFarsight
	}
}

proc busySIP {callid } {
	closeFarsight
	sip AnswerInvite $callid BUSY
}
proc declineSIP {callid } {
	closeFarsight
	sip AnswerInvite $callid DECLINE
}

proc acceptSIP { callid } {
	global farsight
	global sip_remote_candidates
	global sip_remote_codecs
	global sip_codecs
	global sip_candidates
	global sip_codecs_done
	global sip_candidates_done

	foreach candidate $sip_remote_candidates {
		foreach {candidate_id component_id password transport qvalue ip port} $candidate break			
		puts $farsight "REMOTE_CANDIDATE: $candidate_id $component_id $password $transport $qvalue $ip $port"
		#puts "REMOTE_CANDIDATE: $candidate_id $component_id $password $transport $qvalue $ip $port"
	}
	puts $farsight "REMOTE_CANDIDATES_DONE"
	#puts "REMOTE_CANDIDATES_DONE"
	
	foreach codec $sip_remote_codecs {
		foreach {encoding_name payload_type bitrate} $codec break
		puts $farsight "REMOTE_CODEC: $payload_type $encoding_name $bitrate"
		#puts "REMOTE_CODEC: $payload_type $encoding_name $bitrate"
	}
	puts $farsight "REMOTE_CODECS_DONE"
	#puts "REMOTE_CODECS_DONE"
	flush $farsight

	set sip_codecs [list]
	set sip_candidates [list]
	set sip_codecs_done 0
	set sip_candidates_done 0
	fileevent $farsight readable [list farsightAcceptRead $farsight $callid]
}

proc farsightAcceptRead { farsight callid } {
	global sip_codecs
	global sip_candidates
	global sip_codecs_done
	global sip_candidates_done

	if { [eof $farsight] } {
		closeFarsight
		return
	}
	set line [gets $farsight]
	#puts $line
	if {[string first "LOCAL_CODEC: " $line] == 0} {
		set codec [string range $line 13 end]
		foreach {pt name rate} [split $codec " "] break
		if {$name == "PCMA" || $name == "PCMU" || 
		    $name == "SIREN" || $name == "G723" || 
		    $name == "AAL2-G726-32" || $name == "x-msrta"} {
			lappend sip_codecs [list $name $pt $rate]
		}
	} elseif  {[string first "LOCAL_CANDIDATE: " $line] == 0} {
		set candidate [string range $line 17 end]
		lappend sip_candidates [split $candidate " "]
	} elseif  {$line == "LOCAL_CODECS_DONE"} {
		set sip_codecs_done 1
	} elseif  {$line == "LOCAL_CANDIDATES_DONE"} {
		set sip_candidates_done 1
	}
	
	if {$sip_codecs_done && $sip_candidates_done } {
		sip AnswerInvite $callid OK [list $sip_candidates $sip_codecs]
		set sip_codecs_done 0
	}
}

proc errorSIP { reason } {
	puts "Error in SIP : $reason"
	closeFarsight
}

proc closeFarsight { } {
	global farsight
	if {[info exists farsight] && $farsight != "" } {
		catch {puts $farsight "EXIT"}
		catch {close $farsight} res
		puts $res
	}
	set farsight ""
}