#SIP : vp.sip.messenger.msn.com
#TURN : relay.voice.messenger.msn.com

snit::type SIPConnection {
	option -user -default ""
	option -password -default ""
	option -request_handler -default ""
	option -error_handler -default ""
	option -user_agent -default "aTSC/0.1"
	option -registered_host -default ""
	option -local_codecs -default ""
	option -local_candidates -default ""
	option -remote_codecs -default ""
	option -remote_candidates -default ""

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
	variable trying_afterid
	variable timeout_afterid

	constructor { args } {
		install socket using SIPSocket %AUTO% -sipconnection $self
		$self configurelist $args

		set options(-registered_host) [$socket cget -host]

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
		catch {$socket destroy}
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
		if {$state != "" } {
			$self Unregister
		}
		set state ""
	}

	method Disconnected { } {
		status_log "Got Disconnected from SIP"
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
		foreach callid [array names trying_afterid] {
			after cancel $trying_afterid($callid)
		}
		foreach callid [array names timeout_afterid] {
			after cancel $timeout_afterid($callid)
		}
	}

	method KeepAlive { } {
		status_log "SIP Keepalive" green
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
			status_log "Received a non SIP message " red
			if {$options(-error_handler) != "" } {
				if {[catch {eval [linsert $options(-error_handler) end NOT_SIP]} result]} {
					bgerror $result
				}				
			}
			return
		}
		
		set callid [$self GetHeader $headers "Call-ID"]

		if { ![info exists call_to($callid)] ||
		     [$self GetCallee $callid] ==
		     [$self GetRecipient [$self GetHeader $headers "To"]] } {
			set call_from($callid) [$self GetHeader $headers "From"]
			set call_to($callid) [$self GetHeader $headers "To"]
		}
		
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

		if {$type == "status" } {
			if { ![info exists callid_handler($callid)] } {
				# Answer with 'Call/Transaction does not exit error
				$self Send [$self BuildResponse $callid [$self GetCommand $headers] 481]
				status_log "ERROR : unknown callid : $callid" red
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
					$self SendTrying $callid
					$self ParseSDP $body
					set callid_handler($callid) [list $self InviteRequestHandler $callid]
					eval [linsert $options(-request_handler) end $callid INVITE ""]
				} else {
					status_log "SIP ERROR: Received non-INVITE Request" red
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

		status_log "SIP : Registering : $state"
		if { $state == "REGISTERED" } {
			if {$callbk != "" } {
				if {[catch {eval $callbk} result]} {
					bgerror $result
				}
			}
			return
		}

		set auth "msmsgs:RPS_$options(-password)"
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
		status_log "SIP : Register expired"

		after cancel [list $self RegisterExpires] 
		set state ""
		$self Register
	}

	method RegisterResponse {callbk response headers body} {
		if {[lindex $response 1] == "200" } {
			set options(-registered_host) [lindex $response 3]

			set state "REGISTERED"
			
			status_log "SIP : Registered"
			set expires [$self GetHeader $headers "Expires"]
			if {$expires != "" } {
				after [expr {$expires * 1000}] [list $self RegisterExpires] 
			} else {
				after 30000 [list $self RegisterExpires] 
			}
			#puts "Current time is [clock seconds]"
			if {$callbk != "" } {
				if {[catch {eval $callbk} result]} {
					bgerror $result
				}				
			}
		} else {
			status_log "SIP :error on registration : $response"
			if {$options(-error_handler) != "" } {
				if {[catch {eval [linsert $options(-error_handler) end REGISTRATION]} result]} {
					bgerror $result
				}				
			}
		}
	}


	method Unregister { } {
		status_log "SIP : Unregistering"

		set auth "$options(-user):$options(-password)"
		set auth [string map {"\n" "" } [base64::encode $auth]]

		set request [$self BuildRequest REGISTER [lindex [split $options(-user) @] 1] $options(-user) ]
		set callid [lindex $request 0]
		
		set msg [lindex $request 1]
		append msg "ms-keep-alive: UAC;hop-hop=yes\r\n"
		append msg "Expires: 0\r\n"
		append msg "Authorization: Basic $auth\r\n"
		
		set callid_handler($callid) [list $self UnregisterResponse]
		
		$self Send $msg
		after cancel [list $self KeepAlive]
		after cancel [list $self RegisterExpires]
	}

	method UnregisterResponse { response headers body } {
		$socket Disconnect
	}

	########################################
	################ INVITE ################
	########################################

	method Invite {destination {callbk ""}} {
		set sdp [$self BuildSDP]

		set request [$self BuildRequest INVITE $destination $destination]
		set callid [lindex $request 0]
		set msg [lindex $request 1]
		append msg "Ms-Conversation-ID: f=0\r\n"

		set callid_handler($callid) [list $self InviteResponse $callid $callbk]

		$self Register [list $self InviteCB $msg $sdp $callbk]
		return $callid
	}

	method InviteCB {msg sdp callbk} {
		status_log "SIP : Sending Invite"
		$self Send $msg "application/sdp" $sdp
	}

	method InviteResponse {callid callbk response headers body } {
		status_log "Received INVITE response"

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
				
				$self ParseSDP $body
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid OK ""]} result]} {
						bgerror $result
					}
				}
			} elseif {$status == "408" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid NOANSWER ""]} result]} {
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
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid CLOSED REMOTE_BYE]} result]} {
						bgerror $result
					}
				}
			} elseif { [lindex $response 1] == "200" ||
				   [lindex $response 1] == "403" } {
				if {$callbk != "" } {
					if {[catch {eval [linsert $callbk end $callid CLOSED LOCAL_BYE]} result]} {
						bgerror $result
					}				
				}
			} elseif { [lindex $response 1] == "500"} {
				$self Bye $callid
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

	method RenegociateInvite { callid } {
		set content [$self BuildSDP]
		set uri [string range $call_route($callid) [expr {[string first "<sip:" $call_route($callid)] + 5}] [expr {[string first ">" $call_route($callid)] - 1}]]
		set msg [lindex [$self BuildRequest INVITE $uri [$self GetCallee $callid] $callid 1] 1]
		append msg "Ms-Conversation-ID: f=0\r\n"
		
		$self Send $msg "application/sdp" $content
	}

	method SendTrying { callid } {
		$self Send [$self BuildResponse $callid INVITE 100]
		set trying_afterid($callid) [after 25000 [list $self SendSecondTrying $callid]]
	}

	method SendSecondTrying { callid } {
		unset trying_afterid($callid)
		$self Send [$self BuildResponse $callid INVITE 100]
		set timeout_afterid($callid) [after 25000 [list $self SendTimeout $callid]]
	}

	method SendTimeout { callid } {
		unset timeout_afterid($callid)
		$self Send [$self BuildResponse $callid INVITE 408]
		if {[catch {eval [linsert $options(-request_handler) end $callid TIMEOUT ""]} result]} {
			bgerror $result
		}
	}

	method InviteRequestHandler {callid response headers body } {
		status_log "SIP : InviteRequestHandler called "

		if {[$self GetCommand $headers] == "ACK"} {
			if {[catch {eval [linsert $options(-request_handler) end $callid ACK ""]} result]} {
				bgerror $result
			}
		} elseif {[$self GetCommand $headers] == "BYE"} {
			# Answer 200 OK only when receiving the BYE request
			if {[lindex $response 0] == "BYE" } {
				$self Send [$self BuildResponse $callid BYE 200]
				if {[catch {eval [linsert $options(-request_handler) end $callid CLOSED REMOTE_BYE]} result]} {
					bgerror $result
				}
			} elseif { [lindex $response 1] == "200" ||
				   [lindex $response 1] == "403" } {
				# Forbidden means 'call ended' for WLM it seems...
				if {[catch {eval [linsert $options(-request_handler) end $callid CLOSED LOCAL_BYE]} result]} {
					bgerror $result
				}
			} elseif { [lindex $response 1] == "500"} {
				$self Bye $callid
			}
		} elseif {[$self GetCommand $headers] == "CANCEL"} {

			if {[info exists trying_afterid($callid)] } {
				after cancel $trying_afterid($callid)
				unset trying_afterid($callid)
			}
			if {[info exists timeout_afterid($callid)] } {
				after cancel $timeout_afterid($callid)
				unset timeout_afterid($callid)
			}

			$self Send [$self BuildResponse $callid CANCEL 200]
			if {[catch {eval [linsert $options(-request_handler) end $callid CANCEL ""]} result]} {
				bgerror $result
			}
		}			

		
	}

	method AnswerInvite { callid status } {
		switch -- $status {
			"RINGING" {
				set status 180
				set content_type ""
				set content ""
			}
			"UNAVAILABLE" {
				set status 480
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
				set content [$self BuildSDP]
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
		status_log "SIP : Answering Invite with status $status"

		$self Send [$self BuildResponse $callid INVITE $status] $content_type $content
		if {$status != 180 } {
			if {[info exists trying_afterid($callid)] } {
				after cancel $trying_afterid($callid)
				unset trying_afterid($callid)
			}
			if {[info exists timeout_afterid($callid)] } {
				after cancel $timeout_afterid($callid)
				unset timeout_afterid($callid)
			}
		}
	}


	method SendACK { callid } {
		$self Send [lindex [$self BuildRequest ACK [$self GetCallee $callid] [$self GetCallee $callid] $callid] 1]
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
		$self Send [lindex [$self BuildRequest CANCEL [$self GetCallee $callid] [$self GetCallee $callid] $callid] 1]

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

		set msg [lindex [$self BuildRequest BYE $uri [$self GetCallee $callid] $callid 1] 1]
		
		$self Send $msg
	}


	
	########################################
	######### Message Builders #############
	########################################

	# new_request here is not really whether it's a new request
	# or not, it's rather whether it's a new request relating to
	# an existing callid. Useful because INVITE renegociation
	# and BYE need to be sent with the 'From' field set to self
	method BuildRequest { request uri to {callid ""} {new_request 0}} {
		$self Connect

		set sockname [$socket GetInfo]

		if {$new_request} {
			if { ![info exists cseqs($request)] } {
				set cseqs($request) 2
			} else {
				incr cseqs($request)
			}
			set cseq $cseqs($request)
		} else {
			if { ![info exists cseqs($request)] } {
				set cseqs($request) 1
			} else {
				incr cseqs($request)
			}

			if {$callid == "" } {
				set callid [$self GenerateCallID]
				set call_cseq($callid) $cseqs($request)
				if {$request == "REGISTER" } {
					set name ""
				} else {
					set name "\"0\" "
				}
				set call_from($callid) "$name<sip:$options(-user)>;tag=[$self GenerateTag];epid=[$self GenerateEpid]"
				set call_to($callid) "<sip:$to>"
			}
			set cseq $call_cseq($callid)
		}

		set msg "$request sip:$uri SIP/2.0\r\n"
		append msg "v: SIP/2.0/TLS [lindex $sockname 0]:[lindex $sockname 2]\r\n"
		append msg "Max-Forwards: 70\r\n"
		# Switch the from/to only if we send a new invite of an existing
		# call, where we were the original recipient..
		if { $new_request == 1 &&
		     [$self GetCallee $callid] == $options(-user)} {
			append msg "f: $call_to($callid)\r\n"
			append msg "t: $call_from($callid)\r\n"		
		} else {
			append msg "f: $call_from($callid)\r\n"
			append msg "t: $call_to($callid)\r\n"
		}
		append msg "i: $callid\r\n"
		append msg "CSeq: $cseq $request\r\n"
		if {$request == "REGISTER"} {
			append msg "m: <sip:[lindex $sockname 0]:[lindex $sockname 2];"
			append msg "transport=tls>;proxy=replace\r\n"
		} elseif { $request == "INVITE" } {
			append msg "m: \"0\" <sip:$options(-user):[lindex $sockname 2];"
			append msg "maddr=[lindex $sockname 0];transport=tls>;proxy=replace\r\n"
		}
		append msg "User-Agent: $options(-user_agent)\r\n"
		if {$new_request} {
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
		if {$status != 100 &&
		    $call_to($callid) == "<sip:$options(-user)>" } {
			set call_to($callid) "\"0\" <sip:$options(-user)>;tag=[$self GenerateTag]"
		}
		append msg "Max-Forwards: 70\r\n"
		append msg "f: $call_from($callid)\r\n"
		append msg "t: $call_to($callid)\r\n"
		append msg "i: $callid\r\n"
		append msg "CSeq: $call_cseq($callid) $request\r\n"
		if {$request == "INVITE" && $status == 200} {
			append msg "m: \"0\" <sip:$options(-user):[lindex $sockname 2];"
			append msg "maddr=[lindex $sockname 0];transport=tls>;proxy=replace\r\n"
		}
		append msg "User-Agent: $options(-user_agent)\r\n"

		return $msg
	}

	method BuildSDP { } {

		set pt_list ""
		foreach codec $options(-local_codecs) {
			foreach {encoding_name payload_type bitrate fmtp} $codec break
			append pt_list " $payload_type"
		}

		set rtcp_port 0
		set default_ip 0
		set default_port 0
		foreach candidate $options(-local_candidates) {
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
		foreach candidate $options(-local_candidates) {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break
			if {$candidate_id != "" && $password != "" } {
				append sdp "a=candidate:$candidate_id $component_id $password $transport $qvalue $ip $port\r\n"
			}
		}
		if {$rtcp_port != 0 } {
			append sdp "a=rtcp:$rtcp_port\r\n"
		}

		foreach codec $options(-local_codecs) {
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

	method GetRecipient { field } {
		set recipient [string range $field [expr {[string first "<sip:" $field] + 5}] [expr {[string first ">" $field] - 1}]]
		set recipient [lindex [split $recipient ";"] 0]
		set recipient [lindex [split $recipient ":"] 0]

		return $recipient
	}

	method GetCaller { callid } {
		return [$self GetRecipient $call_from($callid)]
	}
	method GetCallee { callid } {
		return [$self GetRecipient $call_to($callid)]
	}
	
	method GetCommand { headers } {
		set cseq [$self GetHeader $headers "CSeq"]
		return [lindex [split $cseq " "] 1]
	}

	method Random { min max } {
		return [expr {int($min + rand() * (1+$max-$min))}]
	}

	method GenerateHex { num } {
		set res ""
		while { $num > 0 } {
			append res [format %x [$self Random 0 15]]
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
		set options(-remote_codecs) [list]
		set ice_candidates [list]
		set rtcp_port 0

		foreach line [split $body "\n"] {
			set line [string trim $line]
			set field [string range $line 0 0]
			set value [string range $line 2 end]

			switch -- $field {
				"c" {
					set ip [lindex [split $value " "] 2]
				}
				"m" {
					set port [lindex [split $value " "] 1]
				}
				"a" {
					set attribute [lindex [split $value ":"] 0]
					set attr [string range $value [expr {[string length $attribute] +1}] end]
					#puts "$attribute -- $attr"
					switch -- $attribute {
						"candidate" {
							lappend ice_candidates [split $attr " "]
						}
						"rtcp" {
							set rtcp_port $attr
						}
						"rtpmap" {
							set pt [lindex $attr 0]
							set codec [lindex $attr 1]
							set encoding_name [lindex [split $codec "/"] 0]
							set bitrate [lindex [split $codec "/"] 1]
							
							lappend options(-remote_codecs) [list $encoding_name $pt $bitrate]
						}
					}
				}
			}
		}
		if {$rtcp_port == 0 } {
			set rtcp_port $port
			incr rtcp_port
		}
		set options(-remote_candidates) [list]
		lappend options(-remote_candidates) [list "" 1 "" UDP 1 $ip $port]
		lappend options(-remote_candidates) [list "" 2 "" UDP 1 $ip $rtcp_port]
		
		foreach candidate $ice_candidates {
			lappend options(-remote_candidates) $candidate
		}
	}

}





###########################################
#  SIPSocket is a socket wrapper for SIP  #
###########################################

snit::type TURN {
	option -user -default ""
	option -password -default ""
	option -host -default "relay.voice.messenger.msn.com"
	option -port -default "443"
	option -transport -default "tls"
	option -proxy -default "direct" -configuremethod ProxyChanged
	option -proxy_host -default ""
	option -proxy_port -default ""
	option -proxy_authenticate -default 0
	option -proxy_user -default ""
	option -proxy_password -default ""

	variable sock ""
	variable message_types
	variable attribute_types
	variable messages

	constructor { args } {
		$self configurelist $args

		array set message_types [list "1" "BINDING-REQUEST" \
					     "2" "SHARED-SECRET-REQUEST" \
					     "3" "ALLOCATE-REQUEST" \
					     "257" "BINDING-RESPONSE" \
					     "258" "SHARED-SECRET-RESPONSE" \
					     "259" "ALLOCATE-RESPONSE" \
					     "273" "BINDING-ERROR" \
					     "274" "SHARED-SECRET-ERROR" \
					     "275" "ALLOCATE-ERROR"]

		array set attribute_types [list "1" "MAPPED-ADDRESS" \
					       "2" "RESPONSE_ADDRESS" \
					       "3" "CHANGE_REQUEST" \
					       "4" "SOURCE_ADDRESS" \
					       "5" "CHANGED-ADDRESS" \
					       "6" "USERNAME" \
					       "7" "PASSWORD" \
					       "8" "MESSAGE-INTEGRITY" \
					       "9" "ERROR-CODE" \
					       "10" "UNKNOWN-ATTRIBUTES" \
					       "11" "REFLECTED-FROM" \
					       "12" "TRANSPORT-PREFERENCES" \
					       "13" "LIFETIME" \
					       "14" "ALTERNATE-SERVER" \
					       "15" "MAGIC-COOKIE" \
					       "16" "BANDWIDTH" \
					       "17" "MORE-AVAILABLE" \
					       "18" "REMOTE-ADDRESS" \
					       "19" "DATA" \
					       "20" "REALM" \
					       "21" "NONCE" \
					       "22" "RELAY-ADDRESS" \
					       "23" "REQUESTED-ADDRESS-TYPE" \
					       "24" "REQUESTED-PORT" \
					       "25" "REQUESTED-TRANSPORT" \
					       "26" "XOR-MAPPED-ADDRESS" \
					       "27" "TIMER-VAL" \
					       "28" "REQUESTED-IP" \
					       "29" "FINGERPRINT" \
					       "32802" "SERVER" \
					       "32803" "ALTERNATE-SERVER" \
					       "32804" "REFRESH-INTERVAL"]
	}

	destructor {
		$self Disconnect
	}

	method Disconnect { } {
		puts "Disconnecting"
		catch {close $sock}
		set sock ""
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
		puts "Connecting"

		if { $options(-transport) == "tls" } {
			package require tls
		} else {

			error "Only 'tls' transport currently supported!"
		}

		switch -- $options(-proxy) {
			"direct" {
				set sock [::tls::socket -async $options(-host) $options(-port)]
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

		set state "NONE"
		fconfigure $sock -buffering none -translation binary
		fileevent $sock readable [list $self SocketReadable]

		return 1
	}

	method Send { data } {
		puts "Sending [hexify $data]"
		if {[catch {puts -nonewline $sock $data} res] } {
			status_log "SIPSocket : Unable to send data : $res"
			$self Disconnect
			return 0
		} else {
			return 1
		}
	}

	method SocketReadable { } {
		if { [eof $sock] } {
			status_log "TURN: $sock reached eof"
			$self Disconnect
			return
		}

		if { [catch {set header [read $sock 20] } res]} {
			status_log "TURN: Reading line got error $res"
			$self Disconnect
			return
		}

		if {![info exists header] || [string length $header] != 20 } {
			puts "Not enough header : [string length $header]"
			return
		}

		binary scan $header SSH32 message_type payload_size id
		set message_type [expr {$message_type & 0xFFFF}]

		set message_type [$self MessageTypeToString $message_type]

		puts "Received message of type $message_type"

		if { [catch {set payload [read $sock $payload_size] } res]} {
			status_log "TURN: Reading line got error $res"
			$self Disconnect
			return
		}
		if {![info exists payload] || [string length $payload] != $payload_size } {
			puts "Not enough payload : [string length $payload] != $payload_size"
			return
		}

		puts "Received [hexify $payload]"

		set attributes [list]
		set total_size 0
		while {$total_size < $payload_size } {
			binary scan $payload @${total_size}SS attribute_type attribute_size
			set attribute_type [expr {$attribute_type & 0xFFFF}]
			incr total_size 4
			set attribute_value [string range $payload $total_size [expr {$total_size + $attribute_size - 1}]]
			incr total_size $attribute_size
			lappend attributes [$self AttributeTypeToString $attribute_type]
			lappend attributes $attribute_value
			puts "Received attribute [$self AttributeTypeToString $attribute_type] : [hexify $attribute_value]"
		}

		$self HandleResponse $id $message_type $attributes
		
	}

	method MessageTypeToString { message_type } {
		if {[info exists message_types($message_type)] } {
			return $message_types($message_type)
		} else {
			return "UNKNOWN_MESSAGE_$message_type"
		}
	}

	method AttributeTypeToString { attribute_type } {
		if {[info exists attribute_types($attribute_type)] } {
			return $attribute_types($attribute_type)
		} else {
			return "UNKNOWN_ATTRIBUTE_$attribute_type"
		}
	}

	method StringToMessageType { message_type } {
		foreach value [array names message_types] {
			if {$message_types($value) == $message_type } {
				return $value
			}
		}
		return 0
	}

	method StringToAttributeType { attribute_type } {
		foreach value [array names attribute_types] {
			if {$attribute_types($value) == $attribute_type } {
				return $value
			}
		}
		return 0
	}

	method RequestSharedSecret { {total 2} } {
		$self Connect

		for {set i 0} { $i < $total} { incr i} {
			set id [$self GenerateId]
			set message [$self BuildMessage $id "SHARED-SECRET-REQUEST" \
					 [list "USERNAME" "RPS_$options(-password)\x00\x00\x00"]]
			set messages($id) $message
			$self Send $message
		}
	}

	method HandleResponse { id message_type attributes } {
		puts "Received response $message_type for id $id"
		if {[info exists messages($id)] } {
			unset messages($id)
			if {$message_type == "SHARED-SECRET-ERROR" } {
				foreach {attr_type value} $attributes {
					puts "Parsing $attr_type"
					if {$attr_type == "REALM" } {
						set realm $value
					} elseif {$attr_type == "NONCE" } {
						set nonce $value
					} elseif {$attr_type == "ERROR-CODE" } {
						binary scan $value Ia* error_code error_message
					}
				}
				if {$error_message == "Unauthorized" } {
					set id [$self GenerateId]
					set message [$self BuildMessage $id \
							 "SHARED-SECRET-REQUEST" \
							 [list "USERNAME" "RPS_$options(-password)\x00\x00\x00" \
							      "REALM" $realm \
							      "NONCE" $nonce ] 24]
					puts "Doing integrity check ($nonce) on [hexify $message] "
					set message_integrity [$self BuildSharedSecretIntegrity $message $nonce]
					
					set message [$self BuildMessage $id \
							 "SHARED-SECRET-REQUEST" \
							 [list "USERNAME" "RPS_$options(-password)\x00\x00\x00" \
							      "REALM" $realm \
							      "NONCE" $nonce \
							      "MESSAGE-INTEGRITY" $message_integrity]]
					set messages($id) $message
					$self Send $message
				}

			} elseif {$message_type == "SHARED-SECRET-RESPONSE" } {
				foreach {attr_type value} $attributes {
					if {$attr_type == "USERNAME" } {
						set username $value
					} elseif {$attr_type == "PASSWORD" } {
						set password $value
					} elseif {$attr_type == "ALTERNATE-SERVER" } {
						binary scan $value SScccc ipv4 port i1 i2 i3 i4
						set ipv4 [expr {$ipv4 & 0xFFFF}]
						set port [expr {$port & 0xFFFF}]

						set server_ip " [expr {$i1 & 0xFF}]. [expr {$i2 & 0xFF}]. [expr {$i3 & 0xFF}]. [expr {$i4 & 0xFF}]"
						set server_port $port
						puts "TURN server $server_ip : $server_port"
					}
				}
			}
		} else {
			puts "Received unknown id $id"
			return
		}
		if {[llength [array names messages]] == 0} {
			$self Disconnect
		}
	}

	method BuildMessage { id message_type attributes {extra_size 0}} {
		set message_type [$self StringToMessageType $message_type]
		if {$message_type == 0 } {
			error "Unknown message type $message_type"
		}

		set message ""
		foreach {attr_type value} $attributes {
			set attribute_type [$self StringToAttributeType $attr_type]
			append message [binary format SS $attribute_type [string length $value]]
			append message $value
		}

		set header [binary format SSH32 $message_type [expr {[string length $message] + $extra_size}] $id]

		return "${header}${message}"
	}

	method BuildSharedSecretIntegrity { message nonce } {
		set nonce [string trim $nonce "\""]
		set md5 [::md5::md5 "RPS_$options(-password)\x00\x00\x00:$nonce:$options(-user)"]
		set key "[binary format H* $md5][string repeat \x00 16]"
		set hash [::sha1::hmac $key "$message[string repeat \x00 16]"]
		return [binary format H* $hash]
	}

	method Random { min max } {
		return [expr {int($min + rand() * (1+$max-$min))}]
	}

	method GenerateHex { num } {
		set res ""
		while { $num > 0 } {
			append res [format %x [$self Random 0 15]]
			incr num -1
		}
		return $res
	}

	method GenerateId { } {
		return [$self GenerateHex 32]
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
	variable state "NONE"
	variable start ""
	variable headers ""

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
		set state "NONE"
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
				set sock [::tls::socket -async $options(-host) $options(-port)]
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

		set state "NONE"
		fconfigure $sock -buffering none -translation {crlf binary}
		fileevent $sock readable [list $self SocketReadable]

		return 1
	}

	method Send { data } {
		if {[string trim $data] != "" } {
			degt_protocol "-->SIP ($options(-host)) $data" "sbsend"
		}
		
		if {[catch {puts -nonewline $sock $data} res] } {
			status_log "SIPSocket : Unable to send data : $res"
			$self Disconnect
			return 0
		} else {
			return 1
		}
	}

	method SocketReadable { } {
		if { [eof $sock] } {
			status_log "SIPSocket: $sock reached eof"
			$self Disconnect
			return
		}

		if {$state == "BODY" } {
			set content_length [$options(-sipconnection) GetHeader $headers "Content-Length"]
			status_log "Going to Read : $content_length"
			set body ""
			while { [string length $body] < $content_length } {
				if { [catch {set line [gets $sock]} res]} {
					status_log "SIPSocket: Reading Body got error $res"
					$self Disconnect
					return
				}
				append body "$line\r\n"
			}
			set done 1
		} else {
			if { [catch {gets $sock line} res]} {
				status_log "SIPSocket: Reading line got error $res"
				$self Disconnect
				return
			}
			
			set line [string trim $line]
			set done 0
		}

		if {$state == "NONE" } {
			set start $line
			set state "HEADERS"
			set headers ""
		} elseif {$state == "HEADERS" } {
			append headers "$line\n"
			if {$line == "" } {
				set content_length [$options(-sipconnection) GetHeader $headers "Content-Length"]
				if {$content_length > 0 } {
					set state "BODY"
				} else {
					set body ""
					set done 1

				}
			}
		}

		if {$done} {
			degt_protocol "<--SIP ($options(-host)) $start\n$headers\n\n$body" "sbrecv"
			$options(-sipconnection) HandleMessage $start $headers $body
			set state "NONE"
		}
	}

	method GetInfo { } {
		return [fconfigure $sock -sockname]
	}
}


snit::type Farsight {
	variable pipe ""
	variable local_codecs [list]
	variable local_candidates [list]
	variable ice_candidates [list]
	variable remote_candidates [list]
	variable remote_ice_candidates [list]
	variable remote_codecs [list]
	variable codecs_done 0
	variable candidates_done 0
	variable prepared 0
	variable known_bitrates
	option -closed -default ""
	option -prepared -default ""
	option -enable_ice -default 0
	option -sipconnection -default ""

	constructor { args } {
		$self configurelist $args
		$self Reset

		array set known_bitrates [list "SIREN" 16000 \
					      "x-msrta" 12000 \
					      "G7221" 24000]
	}

	method Reset { } {
		set local_codecs [list]
		set local_candidates [list]
		set ice_candidates [list]
		set remote_candidates [list]
		set remote_codecs [list]
		set codecs_done 0
		set candidates_done 0
		set prepared 0
		set options(-sipconnection) ""
	}

	method Closed { } {
		status_log "Farsight : Closed"
		$self Close
		if {$options(-closed) != "" } {
			if {[catch {eval $options(-closed)} result]} {
				bgerror $result
			}
		}
	}

	method Close { } {
		if {$pipe != "" } {
			catch {puts $pipe "EXIT"}
			catch {close $pipe} res
			status_log "Closed pipe : $res" red
		}
		set pipe ""
		$self Reset
	}

	method AcceptCandidates { candidates } {
		if {$options(-enable_ice) == 0} {
			return [expr {[llength $candidates] == 2}]
		}
		return 1
	}

	method SetRemoteCandidates { candidates } {
		set remote_candidates [list]
		foreach candidate $candidates {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break			
			if {$transport == "UDP" } {
				lappend remote_candidates $candidate
			}
		}
		$self CandidatesFromICE
		
	}

	method SetRemoteCodecs { codecs } {
		set remote_codecs $codecs
	}

	method GetLocalCandidates { } {
		if {$options(-enable_ice)} {
			return $ice_candidates
		} else {
			return $local_candidates
		}
	}

	method GetLocalCodecs { } {
		return [lsort -decreasing -command [list $self CompareCodecs] $local_codecs]
	}
	
	method CompareCodecs {codec1 codec2} {
		foreach {name1 payload_type bitrate} $codec1 break
		foreach {name2 payload_type bitrate} $codec2 break
		
		if {$name1 == "SIREN" } {
			return 1
		} elseif {$name2 == "SIREN" } {
			return -1
		}
		return 0
		
	}
	
	method IsInUse { } {
		return [expr {$pipe != ""}]
	}

	method Test { } {
		if {[catch {$self Prepare}] } {
			return 0
		}
		return -1

	}

	method Prepare { } {
		$self Close

		status_log "Farsight : Preparing"

		if {[OnWin] } {
			set ::env(GST_PLUGIN_PATH) [file join [pwd] utils windows gstreamer]
			set ::env(FS_PLUGIN_PATH) [file join [pwd] utils windows gstreamer]
			set pipe [open "| ./utils/windows/gstreamer/farsight.exe user@localhost remote@remotehost" r+]
		} elseif { [OnMac] } {
			set ::env(DYLD_LIBRARY_PATH) [file join [pwd] utils macosx gstreamer]
			set ::env(GST_PLUGIN_PATH) [file join [pwd] utils macos gstreamer]
			set ::env(FS_PLUGIN_PATH) [file join [pwd] utils macos gstreamer]
			set pipe [open "| ./utils/macosx/gstreamer/farsight user@localhost remote@remotehost" r+]
		} else {
			set pipe [open "| ./utils/farsight/farsight user@localhost remote@remotehost" r+]
		}
		fconfigure $pipe -buffering line
		fileevent $pipe readable [list $self PipeReadable]
	}

	method Start { } {


		if {$options(-enable_ice) == 0} {
			set candidates $remote_candidates
		} else {
			set candidates $remote_ice_candidates
		}

		status_log "Farsight starting : $remote_codecs - $remote_candidates"

		foreach codec $remote_codecs {
			foreach {encoding_name payload_type bitrate} $codec break
			puts $pipe "REMOTE_CODEC: $payload_type $encoding_name $bitrate"
		}
		puts $pipe "REMOTE_CODECS_DONE"

		foreach candidate $candidates {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break			
			puts $pipe "REMOTE_CANDIDATE: $candidate_id $component_id $password $transport $qvalue $ip $port"
		}
		puts $pipe "REMOTE_CANDIDATES_DONE"
		
		flush $pipe
	}

	method PipeReadable { } {
		if { [eof $pipe] } {
			status_log "Farsight : got eof"
			$self Closed
			return
		}

		if { [catch {set line [gets $pipe]} res] } {
			status_log "Farsight : read error : $res"
			$self Closed
			return
		}

		status_log "Farsight answering : $line"

		if {[string first "LOCAL_CODEC: " $line] == 0} {
			set codec [string range $line 13 end]
			foreach {pt name rate} [split $codec " "] break
			if {$name == "PCMA" || $name == "PCMU" || 
			    $name == "SIREN" || $name == "G723" || 
			    $name == "AAL2-G726-32" || $name == "x-msrta"} {
				if {[info exists known_bitrates($name)] } {
					lappend local_codecs [list $name $pt $rate "bitrate=$known_bitrates($name)"]
				} else {
					lappend local_codecs [list $name $pt $rate]
				}
			}
			if {$name == "telephone-event" && $rate == "8000"} {
				lappend local_codecs [list $name $pt $rate "0-16"]
			}
		} elseif  {[string first "LOCAL_CANDIDATE: " $line] == 0} {
			set candidate [string range $line 17 end]
			lappend local_candidates [split $candidate " "]
		} elseif  {$line == "LOCAL_CODECS_DONE"} {
			set codecs_done 1
		} elseif  {$line == "LOCAL_CANDIDATES_DONE"} {
			set candidates_done 1
		} else {
			# Unknown message.. ignore
		}
	
		if {$prepared == 0 && $codecs_done && $candidates_done } {
			status_log "Farsight : Farsight is now prepared!"

			set prepared 1

			$self CandidatesToICE

			if {$options(-prepared) != "" } {
				if {[catch {eval $options(-prepared)} result]} {
					bgerror $result
				}
			}
		}
	}

	method CandidatesToICE { } {
		foreach candidate $local_candidates {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break
			if {$component_id == 1 } {
				set rtp_ip $ip
				set rtp_port $port
			} elseif {$component_id == 2 } {
				set rtcp_ip $ip
				set rtcp_port $port
			}
		}
		set ice_candidates [list]
			
		# Host candidate
		lappend ice_candidates [list "d4M8DKejjp0T+F59lmFoQ6tEqPU4UQz/PWWKC9x598g=" 1 "CXwpC2uyZdZMgIXekG/t1Q==" "UDP" "0.830" [::abook::getDemographicField localip] $rtp_port]
		lappend ice_candidates [list "d4M8DKejjp0T+F59lmFoQ6tEqPU4UQz/PWWKC9x598g=" 2 "CXwpC2uyZdZMgIXekG/t1Q==" "UDP" "0.830" [::abook::getDemographicField localip] $rtcp_port]
			
		# STUN Server Reflexive candidate
		if {$rtp_ip != [::abook::getDemographicField localip] } {
			lappend ice_candidates [list "n7dIOYDH4Ez9eks5lhDa4AiEir/ohyuHH/YxgOV+l7Y=" 1 "JUZOFZaDMojxN3SOIdGIJQ==" "UDP" "0.550" $rtp_ip $rtp_port]
			lappend ice_candidates [list "n7dIOYDH4Ez9eks5lhDa4AiEir/ohyuHH/YxgOV+l7Y=" 2 "JUZOFZaDMojxN3SOIdGIJQ==" "UDP" "0.550" $rtcp_ip $rtcp_port]
		}

		# Server Reflexive candidate
		if {$rtp_ip != [::abook::getDemographicField clientip]} {
			lappend ice_candidates [list "5NTz7LG4dhD842wSFGqnm618QV+json8E7Zk1FnI2YQ=" 1 "UUrgoZjOk04pDwHn3qnovg==" "UDP" "0.450" [::abook::getDemographicField clientip] $rtp_port]
			lappend ice_candidates [list "5NTz7LG4dhD842wSFGqnm618QV+json8E7Zk1FnI2YQ=" 2 "UUrgoZjOk04pDwHn3qnovg==" "UDP" "0.450" [::abook::getDemographicField clientip] $rtcp_port]
		}

	}

	method CandidatesFromICE { } {
		set priorities [list]
		foreach candidate $remote_candidates {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break
			if {$qvalue == 1 } {
				continue
			}
			if {[lsearch $priorities $qvalue] == -1} {
				lappend priorities $qvalue
			}
		}
		set priorities [lsort -decreasin $priorities]

		set remote_ice_candidates $remote_candidates

		# Didn't receive ICE candidates
		if {[llength $priorities] < 2 } {
			return
		}

		set remote_candidates [list]
			
		# Host candidates
		set host_candidates [list]
		set srflx_candidates [list]
		set relay_candidates [list]
			
		foreach candidate $remote_ice_candidates {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break
			if {[lindex $priorities 0] == $qvalue} {
				lappend host_candidates $candidate
			} elseif {[lindex $priorities 1] == $qvalue} {
				lappend srflx_candidates $candidate
			} elseif {[lindex $priorities 2] == $qvalue} {
				lappend relay_candidates $candidate
			}
		}
	
		foreach candidate $srflx_candidates {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break
			if {$component_id != 1} {
				continue
			}
			if {$ip == [::abook::getDemographicField clientip]} {
				# host is in the same local network
				set max 0
				set cand ""
				set n0 [lindex [split [::abook::getDemographicField localip] "."] 0]
				set n1 [lindex [split [::abook::getDemographicField localip] "."] 1]
				set n2 [lindex [split [::abook::getDemographicField localip] "."] 2]
				set n3 [lindex [split [::abook::getDemographicField localip] "."] 3]

				foreach candidate2 $host_candidates {
					foreach {candidate_id component_id password transport qvalue ip port} $candidate2 break
					set m0 [lindex [split $ip "."] 0]
					set m1 [lindex [split $ip "."] 1]
					set m2 [lindex [split $ip "."] 2]
					set m3 [lindex [split $ip "."] 3]
					set current 0
					if {$m0 == $n0} {
						incr current
						if {$m1 == $n1 } {
							incr current
							if {$m2 == $n2 } {
								incr current
								if {$m3 == $n3 } {
									incr current
								}
							}
						}
					}
					if {$current > $max} {
						set max $current
						set cand $candidate_id
					}
				}
				if {$cand != "" } {
					foreach candidate2 $host_candidates {
						foreach {candidate_id component_id password transport qvalue ip port} $candidate2 break
						if {$candidate_id == $cand} {
							lappend remote_candidates $candidate2
						}
					}
					break					
				}
			}
		}

		if {$remote_candidates == [list] } {
			set remote_candidates $srflx_candidates
		}
		
	}
}

namespace eval ::MSNSIP {
	namespace export ReceivedInvite InviteUser AcceptInvite DeclineInvite HangUp CancelCall

	variable sipconnections [list]

	proc createSIP { {host "vp.sip.messenger.msn.com"} } {
		variable sipconnections
		global sso
		if {![info exists sso] } {
			status_log "MSNSIP : Creating SIP.. not authenticated"
			return ""
		}

		status_log "MSNSIP : Creating SIP connection to $host"

		set token [$sso GetSecurityTokenByName MessengerSecure]
		set sip [SIPConnection create %AUTO% -user [::config::getKey login] -password [$token cget -ticket] -host $host]
		$sip configure -error_handler [list ::MSNSIP::errorSIP $sip] -request_handler [list ::MSNSIP::requestSIP $sip]
		lappend sipconnections $sip

		status_log "MSNSIP : SIP connection created : $sip"
		return $sip
		
	}

	proc destroySIP { sip } {
		variable sipconnections

		# TODO : Make sure the sip connection is not used by another call..
		# Imagine you talk on a SIP server, and you receive an invite from 
		# someone else on the same server, you decline it with BUSY
		# we shouldn't destroy our sip connection and close farsight from
		# our first call...

		# if we do a '$sip destroy' here...  Tcl segfaults!!! :D

		status_log "MSNSIP : Destroying $sip"
		set idx [lsearch $sipconnections $sip]
		if {$idx >= 0} {
			set sipconnections [lreplace $sipconnections $idx $idx]
			$sip Unregister
			after 10000 [list $sip destroy]
		}

		if {[$::farsight cget -sipconnection] == $sip } {
			$::farsight Close
			$::farsight configure -sipconnection "" -closed "" -prepared ""
		}
	}

	proc ReceivedInvite { ip } {
		variable sipconnections

		status_log "MSNSIP : Received SIP invite on $ip"
		foreach sip $sipconnections {
			if {[$sip cget -registered_host] == $ip } {
				# Just in case we're connected but registration expired
				# and the timer didn't re-register us..
				status_log "MSNSIP : $sip already registered on $ip"
				$sip RegisterExpires
				return
			}
		}

		set sip [createSIP $ip]
		if {$sip == "" } {
			SSOAuthenticate [list ::MSNSIP::ReceivedInvite $ip]
		} else {
			$sip Register
		}
	}

	proc SSOAuthenticated { callback failed } {
		if {$failed == 0 } {
			eval $callback
		}
		# TODO : if can't auth for some reason.. signal the UI ?
	}

	proc SSOAuthenticate { callback } {
		global sso 
		set sso [::SSOAuthentication create %AUTO% -username [::config::getKey login] -password $::password]
		$sso Authenticate [list ::MSNSIP::SSOAuthenticated $callback]
	}

	proc InviteUser { email } {
		status_log "MSNSIP : Inviting user $email to a SIP call"
		if {[$::farsight IsInUse] } {
			# Signal the UI
			::amsn::SIPCallYouAreBusy $email
			return "BUSY"
		} else {
			set sip [createSIP]
			if {$sip == "" } {
				SSOAuthenticate [list ::MSNSIP::InviteUser $email]
				return "DELAYED"
			}

			$::farsight configure -sipconnection $sip -prepared [list ::MSNSIP::invitePrepared $sip $email] -closed  [list ::MSNSIP::inviteClosed $sip $email "" -1]
		
			if {[catch {$::farsight Prepare}] } {
				::amsn::SIPCallImpossible $email
				return "IMPOSSIBLE"
			} else {
				# Reset the SipConnection because the Prepare clears it
				$::farsight configure -sipconnection $sip 
				return $sip
			}
		}
	}

	proc invitePrepared { sip email } {
		$sip configure -local_candidates [$::farsight GetLocalCandidates]
		$sip configure -local_codecs [$::farsight GetLocalCodecs] 
		set callid [$sip Invite $email [list ::MSNSIP::inviteSIPCB $sip $email]]

		$::farsight configure -closed [list ::MSNSIP::inviteClosed $sip $email $callid 0]

		# Signal the UI
		::amsn::SIPInviteSent $email $sip $callid
	}


	proc inviteClosed { sip email callid {started 0}} {
		status_log "MSNSIP : InviteClosed $sip $email $callid $started"
		if {$started == 1} {
			$sip Bye $callid

			# Signal the UI
			::amsn::SIPCallEnded $email $sip $callid
		} elseif {$started == 0 } {
			$sip Cancel $callid
			
			# Signal the UI
			::amsn::SIPCallEnded $email $sip $callid
		} else {
			# Signal the UI
			::amsn::SIPCallImpossible $email
		}
		destroySIP $sip

	}

	proc CancelCall { sip callid } {
		status_log "MSNSIP : Canceling SIP call"
		$sip Cancel $callid
		destroySIP $sip		
	}

	proc HangUp { sip callid } {
		status_log "MSNSIP : Hanging up SIP call"
		$sip Bye $callid
		destroySIP $sip
	}

	proc inviteSIPCB { sip email callid status detail} {
		status_log "MSNSIP : inviteSIPCB : $sip $email $callid $status $detail" green
		if { $status == "OK" } {
			# Signal the UI
			::amsn::SIPCalleeAccepted $email $sip $callid

			$::farsight SetRemoteCandidates [$sip cget -remote_candidates]
			$::farsight SetRemoteCodecs [$sip cget -remote_codecs]
			$::farsight Start
			$::farsight configure -closed [list ::MSNSIP::inviteClosed $sip $callid 1]
		} elseif {$status == "BUSY"} {
			# Signal the UI
			::amsn::SIPCalleeBusy $email $sip $callid
		} elseif {$status == "DECLINED"} {
			# Signal the UI
			::amsn::SIPCalleeDeclined $email $sip $callid
		} elseif {$status == "CLOSED"} {
			# Signal the UI
			if {$detail == "LOCAL_BYE" } {
				::amsn::SIPCallEnded $email $sip $callid
			} elseif {$detail == "REMOTE_BYE" } {
				::amsn::SIPCalleeClosed $email $sip $callid
			}
		} elseif {$status == "UNAVAILABLE"} {
			# Signal the UI
			::amsn::SIPCalleeUnavailable $email $sip $callid
		} elseif {$status == "NOANSWER"} {
			# Signal the UI
			::amsn::SIPCalleeNoAnswer $email $sip $callid
		} elseif {$status != "TRYING" && $status != "RINGING" && $status != "CANCEL"} {
			# Signal the UI
			::amsn::SIPCallEnded $email $sip $callid
		}
		if {$status != "OK" && $status != "TRYING" && $status != "RINGING"}  {
			destroySIP $sip
		}
	}

	proc requestSIP { sip callid what detail } {
		status_log "MSNSIP : requestSIP : $sip $callid $what" green
		if {$what == "INVITE" } {
			if {[$::farsight IsInUse] } {
				# Signal the UI
				::amsn::SIPCallMissed [$sip GetCaller $callid]

				$sip AnswerInvite $callid BUSY
				destroySIP $sip
			} else {
				if { [$::farsight AcceptCandidates [$sip cget -remote_candidates]] } {
					$::farsight configure -prepared [list ::MSNSIP::requestPrepared $sip $callid] -closed [list ::MSNSIP::answerClosed $sip $callid 0] -sipconnection $sip
					if {[catch {$::farsight Prepare}] } {
						$::farsight configure -sipconnection $sip 
						# Signal the UI
						::amsn::SIPCallImpossible [$sip GetCaller $callid]

						$sip AnswerInvite $callid UNAVAILABLE
						destroySIP $sip
					} else {
						# Reset the SipConnection because the Prepare clears it
						$::farsight configure -sipconnection $sip 
						$::farsight SetRemoteCandidates [$sip cget -remote_candidates]
						$::farsight SetRemoteCodecs [$sip cget -remote_codecs]
					}
				} else {
					# Signal the UI
					::amsn::SIPCallUnsupported [$sip GetCaller $callid]

					$sip AnswerInvite $callid UNAVAILABLE
					destroySIP $sip
				}
			}
		} elseif {$what == "CLOSED" } {
			# Signal the UI
			if {$detail == "REMOTE_BYE" } {
				::amsn::SIPCalleeClosed [$sip GetCaller $callid] $sip $callid
			} elseif {$detail == "LOCAL_BYE" } {
				::amsn::SIPCallEnded [$sip GetCaller $callid] $sip $callid
			}

			destroySIP $sip
		} elseif {$what == "CANCEL" } {
			# Signal the UI
			::amsn::SIPCalleeCanceled [$sip GetCaller $callid] $sip $callid

			destroySIP $sip
		} elseif {$what == "TIMEOUT" } {
			# Signal the UI
			::amsn::SIPCallMissed [$sip GetCaller $callid] $callid

			destroySIP $sip
		}
	}



	proc answerClosed { sip callid {started 0}} {
		status_log "MSNSIP: answerClosed : $sip $callid $started"
		if {$started } {
			# Signal the UI
			::amsn::SIPCallEnded [$sip GetCaller $callid] $sip $callid

			$sip Bye $callid
		} else {
			# Signal the UI
			::amsn::SIPCallImpossible [$sip GetCaller $callid]

			$sip AnswerInvite $callid UNAVAILABLE
		}
		destroySIP $sip
	}

	proc requestPrepared { sip callid } {
		status_log "MSNSIP : request Prepared for $sip $callid"

		# Signal the UI
		::amsn::SIPCallReceived [$sip GetCaller $callid] $sip $callid

		$sip AnswerInvite $callid RINGING
	}

	proc DeclineInvite {sip callid } {
		status_log "MSNSIP: Declining invite"

		$sip AnswerInvite $callid DECLINE
		destroySIP $sip
	}

	proc AcceptInvite { sip callid } {
		status_log "MSNSIP: Accepting invite"

		# no prepare since it's already done before it started RINGING
		$::farsight Start
		$sip configure -local_candidates [$::farsight GetLocalCandidates]
		$sip configure -local_codecs [$::farsight GetLocalCodecs]
		$sip AnswerInvite $callid OK
		$::farsight configure -closed [list ::MSNSIP::answerClosed $sip $callid 1]
	}

	proc errorSIP { sip reason } {
		status_log "MSNSIP: Got an error"
		# TODO : what use case where we need to signal the UI?
		destroySIP $sip
	}


	proc FarsightTestFailed { callbk } {
		if { ([::config::getKey clientid 0] & 0x100000) != 0 } {
			::MSN::setClientCap sip 0
			if {[::MSN::myStatusIs] != "FLN" } {
				::MSN::changeStatus [::MSN::myStatusIs]
			}
		}
		
		$::farsight configure -prepared "" -closed ""
		$::farsight Close
		if {$callbk != "" } {
			eval [linsert $callbk end 0]
		}
	}

	proc FarsightTestSucceeded { callbk } {
		if { [::config::getKey protocol] >= 15 &&
		     ([::config::getKey clientid 0] & 0x100000) == 0 } {
			::MSN::setClientCap sip
			if {[::MSN::myStatusIs] != "FLN" } {
				::MSN::changeStatus [::MSN::myStatusIs]
			}
		}

		$::farsight configure -prepared "" -closed ""
		$::farsight Close

		if {$callbk != "" } {
			eval [linsert $callbk end 1]
		}
	}


	proc TestFarsight { {callbk ""} } {
		if {![$::farsight IsInUse] } {
			$::farsight configure -prepared [list ::MSNSIP::FarsightTestSucceeded $callbk] -closed [list ::MSNSIP::FarsightTestFailed $callbk]
			set result [$::farsight Test]
			if { $result == 1 } {
				::MSNSIP::FarsightTestSucceeded $callbk
			} elseif {$result == 0 } {
				::MSNSIP::FarsightTestFailed $callbk
			} ;# else let the callbacks act
		}
	}
}



if { ![info exists ::farsight] } {
	set ::farsight [Farsight create farsight]
}

