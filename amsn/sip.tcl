
snit::type SIPConnection {
	option -user -default ""
	option -password -default ""
	option -host -default "vp.sip.messenger.msn.com"
	option -port -default "443"
	option -transport -default "tls"
	option -user_agent -default "aTSC/0.1"
	option -proxy -default "direct" -configuremethod ProxyChanged
	option -proxy_host -default ""
	option -proxy_port -default ""
	option -proxy_authenticate -default 0
	option -proxy_user -default ""
	option -proxy_password -default ""
	option -request_handler -default ""
	option -error_handler -default ""

	variable sock ""
	variable compact_form 
	variable state "DISCONNECTED"
	variable cseqs
	variable callids
	variable callid_handler
	variable tags

	constructor { args } {
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
	}

	destructor {
		$self Disconnect
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

	method Disconnect { } {
		if {$sock != "" && $state != "DISCONNECTED" } {
			puts "Current time is [clock seconds]"
			close $sock
			set sock ""
			set state "DISCONNECTED"
		}
		after cancel [list $self KeepAlive]
		after cancel [list $self RegisterExpires]

	}

	method Connect { } {
		if {$sock != "" && $state != "DISCONNECTED" } {
			return
		}

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
		set state "CONNECTED"
		after 30000 [list $self KeepAlive]
	}

	method KeepAlive { } {
		
		puts "Keepalive"
		if { [catch {puts -nonewline $sock "\r\n"}] } {
			$self Disconnect
			# TODO : eval error_handler
		} else {
			after 30000 [list $self KeepAlive]
		}

	}

	method GetHeader { headers name} {
		if {[info exist compact_form([string tolower $name])] } {
			set short_name $compact_form([string tolower $name])
		} else {
			set short_name $name
		}
		set reg {^}
		append reg "($name|$short_name)"
		append reg {:[ \t]*(.*)[ \t]*$}
		if {[regexp -nocase -line $reg $headers -> field value] } {
			return [string trim $value]			
		} else {
			return ""
		} 
	}

	method SocketReadable { } {
		if { [eof $sock] } {
			puts "Socket $sock reached eof"
			$self Disconnect
			return
		}
		set r [gets $sock]
		if {[string range $r 0 6] == "SIP/2.0" } {
			set response $r
			set method "response"
		} else {
			set request $r
			set method "request"
		}
		
		# TODO : Find a better way of checking for the empty line
		set headers ""
		set body ""
		while {[gets $sock r] > 1} {
			append headers "$r\n"
		}
		set content_length [$self GetHeader $headers "Content-Length"]
		if {$content_length > 0 } {
			set body [read $sock $content_length]
		}

		puts "Received a $method : [set $method] : \n$headers\n\n$body"
		if {$method == "response" } {
			set callid [$self GetHeader $headers "Call-ID"]
			if { ![info exists callid_handler($callid)] } {
				puts "ERROR : unknown callid : $callid"
				return
			} else {
				set handler $callid_handler($callid)
				eval [linsert $handler end $response $headers $body]
			}
		} elseif {$options(-request_handler) != ""} {
			set handler $callid_handler($callid)
			eval [linsert $handler end $response $headers $body]
		}
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

	method RegisterResponse {callbk response headers body} {
		if {[lindex $response 1] == "200" } {
			set state "REGISTERED"
			puts "registered"
			set expires [$self GetHeader $headers "Expires"]
			after [expr {$expires * 1000 - 10000}] [list $self RegisterExpires] 
			puts "Current time is [clock seconds]"
			if {$callbk != "" } {
				if {[catch {eval $callbk 1} result]} {
					bgerror $result
				}				
			}
		} else {
			puts "error on registration"
			if {$callbk != "" } {
				if {[catch {eval $callbk 0} result]} {
					bgerror $result
				}				
			}
		}
	}

	method Send { headers {content_type ""} {body ""}} {
		set msg $headers
		if {$content_type != ""} {
			append msg "c: $content_type\r\n"
		}
		append msg "l: [string length $body]\r\n"
		append msg "\r\n"
		append msg "$body"

		puts "Writing to $sock : \n$msg"
		if { [catch {puts -nonewline $sock "$msg"}] } {
			$self Disconnect
			# TODO : eval error_handler
		}

	}
	method RegisterExpires { } {
		set state "CONNECTED"
		$self Register
	}

	method Register { {callbk ""} } {
		$self Connect

		if { $state == "REGISTERED" } {
			if {$callbk != "" } {
				if {[catch {eval $callbk 1} result]} {
					bgerror $result
				}
			}
			return
		}

		if { ![info exists cseqs(REGISTER)] } {
			set cseqs(REGISTER) 1
		} else {
			incr cseqs(REGISTER)
		}

		set sockname [fconfigure $sock -sockname]
		set auth "$options(-user):$options(-password)"
		set auth [string map {"\n" "" } [base64::encode $auth]]

		set callid [$self GenerateCallID]
		set tag [$self GenerateTag]
		set epid [$self GenerateEpid]
		set callids($callid) "$cseqs(REGISTER) REGISTER"
		set callid_handler($callid) [list $self RegisterResponse $callbk]
		set tags($callid) [list $tag $epid]


		set msg "REGISTER sip:[lindex [split $options(-user) @] 1] SIP/2.0\r\n"
		append msg "v: SIP/2.0/TLS [lindex $sockname 0]:[lindex $sockname 2]\r\n"
		append msg "Max-Forwards: 70\r\n"
		append msg "f: <sip:$options(-user)>;tag=$tag;epid=$epid\r\n"
		append msg "t: <sip:$options(-user)>\r\n"
		append msg "i: $callid\r\n"
		append msg "CSeq: $cseqs(REGISTER) REGISTER\r\n"
		append msg "m: <sip:[lindex $sockname 0]:[lindex $sockname 2];"
		append msg "transport=$options(-transport)>;proxy=replace\r\n"
		append msg "User-Agent: $options(-user_agent)\r\n"
		append msg "ms-keep-alive: UAC;hop-hop=yes\r\n"
		append msg "o: registration\r\n"
		append msg "Authorization: Basic $auth\r\n"

		$self Send $msg

		return 0
	}

	method CreateSDP { codec_list candidate_list  } {

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
		append sdp "m=audio $default_port RTP/AVP$pt_list\r\n"
		foreach candidate $candidate_list {
			foreach {candidate_id component_id password transport qvalue ip port} $candidate break
			if {$candidate_id != "" } {
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

		return $sdp
	}
	method Invite {destination codec_list candidate_list {callbk ""}} {
		set callid [$self GenerateCallID]
		set tag [$self GenerateTag]
		set epid [$self GenerateEpid]
		set tags($callid) [list $tag $epid]
		$self Register [list $self InviteCB $destination $callid $codec_list $candidate_list $callbk]
		return $callid
	}

	method InviteCB {destination callid codec_list candidate_list callbk success} {

		if {$success == 0} {
			puts "Not registered"
			return
		}

		if { ![info exists cseqs(INVITE)] } {
			set cseqs(INVITE) 1
		} else {
			incr cseqs(INVITE)
		}

		set sockname [fconfigure $sock -sockname]
		set callids($callid) "$cseqs(INVITE) INVITE"
		set callid_handler($callid) [list $self InviteResponse $callbk]

		set tag [lindex $tags($callid) 0]
		set epid [lindex $tags($callid) 1]

		set sdp [$self CreateSDP $codec_list $candidate_list]

		set msg "INVITE sip:$destination SIP/2.0\r\n"
		append msg "v: SIP/2.0/TLS [lindex $sockname 0]:[lindex $sockname 2]\r\n"
		append msg "Max-Forwards: 70\r\n"
		append msg "f: <sip:$options(-user)>;tag=$tag;epid=$epid\r\n"
		append msg "t: <sip:$destination>\r\n"
		append msg "i: $callid\r\n"
		append msg "CSeq: $cseqs(INVITE) INVITE\r\n"
		append msg "m: <sip:$options(-user):[lindex $sockname 2];maddr=[lindex $sockname 0];"
		append msg "transport=$options(-transport)>;proxy=replace\r\n"
		append msg "User-Agent: $options(-user_agent)\r\n"
		append msg "Ms-Conversation-ID: f=0\r\n"

		$self Send $msg "application/sdp" $sdp
	}

	method SendACK { destination callid from_tag from_epid to_tag } {
		if { ![info exists cseqs(ACK)] } {
			set cseqs(ACK) 1
		} else {
			incr cseqs(ACK)
		}

		set sockname [fconfigure $sock -sockname]

		set msg "ACK sip:$destination SIP/2.0\r\n"
		append msg "v: SIP/2.0/TLS [lindex $sockname 0]:[lindex $sockname 2]\r\n"
		append msg "Max-Forwards: 70\r\n"
		append msg "f: <sip:$options(-user)>;tag=$from_tag;epid=$from_epid\r\n"
		append msg "t: <sip:$destination>;tag=$to_tag\r\n"
		append msg "i: $callid\r\n"
		append msg "CSeq: $cseqs(ACK) ACK\r\n"
		append msg "User-Agent: $options(-user_agent)\r\n"

		$self Send $msg
	
	}

	method InviteResponse {callbk response headers body } {
		puts "Received INVITE response"
		set callid [$self GetHeader $headers "Call-ID"]
		if {[lindex $response 1] >= "200" && [$self GetHeader $headers "CSeq"] == "$callids($callid)" } {
			set from [$self GetHeader $headers "From"]
			set to [$self GetHeader $headers "To"]
			set from_epid [$self GenerateEpid]
			set from_tag [$self GenerateTag]
			foreach option [lrange [split $from ";"] 1 end] {
				foreach {name value} [split $option "="] break
				if {$name == "tag" } {
					set from_tag $value
				} elseif {$name == "epid" } {
					set from_epid $value
				}
			}
			foreach option [lrange [split $to ";"] 1 end] {
				foreach {name value} [split $option "="] break
				if {$name == "tag" } {
					set to_tag $value
				}
			}
			set to [lindex [split $to ";"] 0]
			set destination [string range $to [expr {[string first "<sip:" $to] + 5}] [expr {[string first ">" $to] - 1}]]

			$self SendACK $destination $callid $from_tag $from_epid $to_tag
		}
		
	}

	method Cancel { destination callid } {
		$self Register [list $self CancelCB $destination $callid]
	}

	method CancelCB { destination callid success} {

		if {$success == 0} {
			puts "Not registered"
			return
		}

		if { ![info exists cseqs(CANCEL)] } {
			set cseqs(CANCEL) 1
		} else {
			incr cseqs(CANCEL)
		}

		set sockname [fconfigure $sock -sockname]

		set tag [lindex $tags($callid) 0]
		set epid [lindex $tags($callid) 1]

		set msg "CANCEL sip:$destination SIP/2.0\r\n"
		append msg "v: SIP/2.0/TLS [lindex $sockname 0]:[lindex $sockname 2]\r\n"
		append msg "Max-Forwards: 70\r\n"
		append msg "f: <sip:$options(-user)>;tag=$tag;epid=$epid\r\n"
		append msg "t: <sip:$destination>\r\n"
		append msg "i: $callid\r\n"
		append msg "CSeq: $cseqs(CANCEL) CANCEL\r\n"
		append msg "User-Agent: $options(-user_agent)\r\n"

		$self Send $msg
	}

	method Bye { destination callid } {
		$self Register [list $self ByeCB $destination $callid]
	}

	method ByeCB { destination callid success } {

		if {$success == 0} {
			puts "Not registered"
			return
		}

		if { ![info exists cseqs(BYE)] } {
			set cseqs(BYE) 1
		} else {
			incr cseqs(BYE)
		}

		set sockname [fconfigure $sock -sockname]

		set tag [lindex $tags($callid) 0]
		set epid [lindex $tags($callid) 1]

		set msg "BYE sip:$destination SIP/2.0\r\n"
		append msg "v: SIP/2.0/TLS [lindex $sockname 0]:[lindex $sockname 2]\r\n"
		append msg "Max-Forwards: 70\r\n"
		append msg "f: <sip:$options(-user)>;tag=$tag;epid=$epid\r\n"
		append msg "t: <sip:$destination>\r\n"
		append msg "i: $callid\r\n"
		append msg "CSeq: $cseqs(BYE) BYE\r\n"
		append msg "User-Agent: $options(-user_agent)\r\n"

		$self Send $msg
	}
}

# TODO : Move socket creation in here...
snit::type SocketFactory {

	method CreateSocket {transport proxy} {
		
	}
}