namespace eval ::p2p {

	package require snit

	::snit::type SLPMessage {

		option -to ""
		option -frm ""
		option -branch ""
		option -cseq 0
		option -call_id ""
		option -max_forwards 0
		option -application_id \x00\x00\x00\x00

		variable headers -array {}
		variable headernames {}
		variable body

		constructor { args } {

			$self configurelist $args

		}

		destructor {

			catch {$body destroy}

		}

		method conf2 { } {

			$self add_header To [join [list "<msnmsgr:" $options(-to) ">"] ""]
			$self add_header From [join [list "<msnmsgr:" $options(-frm) ">"] ""]
			if { $options(-branch) != "" } {
				$self add_header Via [join [list "MSNSLP/1.0/TLP ;branch={" $options(-branch) "}"] ""]
			}
			$self add_header CSeq $options(-cseq)
			if { $options(-call_id) != "" } {
				$self add_header Call-ID [join [list "{" $options(-call_id) "}"] ""]
			}
			$self add_header Max-Forwards $options(-max_forwards)

			#if { [info exists $body] } { puts "$self configured twice!" }
			set body [SLPNullBody %AUTO%]
			$self add_header Content-Type [$body cget -content_type]
			$self add_header Content-Length [string length [$body toString]]
			
		}

		method add_header { key value } {
			set headers($key) $value
			if { [lsearch $headernames $key] < 0 } {
				set headernames [lappend headernames $key]
			}

		}

		method setBody { data } {
			catch {$body destroy}
			set body $data
			$self add_header Content-Type [$body cget -content_type]
			$self add_header Content-Length [string length [$body toString]]
		}

		method headers { } {
			return [array get headers]
		}

		method get_header { key } {
			return $headers($key)
		}

		method setHeader { key val } {

			$self add_header $key $val

		}

		method is_SLP { } {
			return 1
		}

		method body { } {
			return $body
		}

		method parse { chunk {type ""} } {
			variable found 
			if { ![info exists found] } { set found 0 }

			if { $found == 1 } {
				set raw_body $chunk
			} else {
				set idx [string first "\r\n\r\n" $chunk]
				set head [string range $chunk 0 [expr {$idx -1}]]
				set raw_body [string range $chunk [expr {$idx+4}] end]
				set head [string map {"\r\n" "\n"} $head]
				set lines [split $head "\n"]
				foreach line $lines {
					if { $line == "" } {
						set found 1
					} else {
						set colon [string first ": " $line]
						set key [string range $line 0 [expr {$colon - 1}]]
						set value [string range $line [expr {$colon + 2}] end]
						$self add_header $key $value
					}
				}
			}

			if { [lsearch [array names headers] "Content-Type"] >= 0 } {
				set content_type $headers(Content-Type)
			} else {
				set content_type ""
			}

			set to [$self get_header To]
			set colon [string first : $to]
			set gt [string first > $to]
			set options(-to) [string range $to [expr {$colon+1}] [expr {$gt-1}]]

			set from [$self get_header From]
			set colon [string first : $from]
			set gt [string first > $from]
			set options(-frm) [string range $from [expr {$colon+1}] [expr {$gt-1}]]

			set via [$self get_header Via]
			set left [string first "{" $via]
			set right [string first "}" $via]
			set options(-branch) [string range $via [expr {$left+1}] [expr {$right-1}]]

			set options(-cseq) [$self get_header CSeq]

			set call_id [$self get_header Call-ID]
			set left [string first "{" $call_id]
			set right [string first "}" $call_id]
			set options(-call_id) [string range $call_id [expr {$left+1}] [expr {$right-1}]]

			set options(-content_type) $content_type

			if { $type == "" } {
				status_log "Building null body!"
			} elseif { $type == "request" } {
				status_log "Building request"
			} elseif { $type == "response" } {
				status_log "Building response"
			}
			set new_body [SLPMessageBody build $content_type $raw_body]
			$new_body conf2
			$self setBody $new_body
			
		}

		method toString { } {

			set str ""
			set newl \r\n
			#content-length
			foreach key $headernames {
				set value $headers($key)
				set str [join [list $str $key ": " $value $newl] ""] ;#concat strips newlines
			}
			set bodyStr [$body toString]
			set str [join [list $str $newl $bodyStr] ""]
			return $str

		}

		typemethod build {raw_message} {

			if { [string first "MSNSLP/1.0" $raw_message] < 0 } {
				return -code error {"Message doesn't seem to be an MSNSLP/1.0 message"}
			}
			set content [split $raw_message "\n"]
			set start_line [lindex $content 0]
			set content [lreplace $content 0 0]

			set start_line [split [string trim $start_line] " "]
			set i 0
			foreach line $content {
				set line [string trim $line]
				lreplace $content $i $i $line
				incr i
			}
			set content [join $content "\n"]

			if { [string trim [lindex $start_line 0]] == "MSNSLP/1.0" } {
				set status [string trim [lindex $start_line 1]]
				set reason [string trim [lindex $start_line 2]]
				status_log "We have a response message"
				set slp_message [SLPResponseMessage %AUTO% -status $status -reason $reason]
				#$slp_message conf2
				set type request
			} else {
				set method [string trim [lindex $start_line 0]]
				set resource [string trim [lindex $start_line 1]]
				status_log "We have a request message"
				set slp_message [SLPRequestMessage %AUTO% -method $method -resource $resource]
				set type response
				$slp_message conf2
			}
			$slp_message parse $content $type
			return $slp_message
		}
	}

	::snit::type SLPRequestMessage {
		delegate option * to SLPMessage
		delegate method * to SLPMessage

		#option -to ""
		option -resource ""
		option -method ""

		constructor { args } {
			install SLPMessage using SLPMessage %AUTO%
			$self configurelist $args
		}

		destructor {
			$SLPMessage destroy
		}

		method conf2 { } {
			$SLPMessage conf2
			set colon [string first ":" $options(-resource)]
			if {  [$SLPMessage cget -to] == "" } {
				$SLPMessage configure -to [string range $options(-resource) 0 [expr {$colon - 1}]]
			}
		}

		method toString { } {

			set msg [$SLPMessage toString]
			set start_line [concat $options(-method) $options(-resource) MSNSLP/1.0]
			return [join [list $start_line \r\n $msg] ""]

		}

	}

	::snit::type SLPResponseMessage {
		delegate option * to SLPMessage
		delegate method * to SLPMessage

		typevariable STATUS_MESSAGE { {200 OK} {404 "Not Found"} {500 "Internal Error"} {603 Decline} {606 Unacceptable}}
		option -status ""
		option -reason ""

		constructor { args } {

			install SLPMessage using SLPMessage %AUTO%
			$self configurelist $args
			$SLPMessage conf2

		}

		destructor {

			$SLPMessage destroy

		}

		method toString { } {

			set msg [$SLPMessage toString]
			if { $options(-reason) == "" } {
				foreach stat $STATUS_MESSAGE { 
					if { [lindex $stat 0] == $options(-status) } { 
						set reason [lindex $stat 1] 
					} 
				}
			} else {
				set reason $options(-reason)
			}
			set $options(-reason) $reason

			set start_line [concat MSNSLP/1.0 $options(-status) $reason]
			return [join [list $start_line \r\n $msg] ""]

		}

	}

	::snit::type SLPMessageBody {

		option -content_type ""
		typevariable content_classes -array {}
		variable headers -array {}
		variable headernames {}
		variable body ""
		option -euf_guid ""
		option -session_id ""
		option -s_channel_state ""
		option -capabilities_flags ""
		option -context ""

		constructor { args } {
			$self configurelist $args
			SLPMessageBody register_content $::p2p::SLPContentType::NULL SLPNullBody
			SLPMessageBody register_content $::p2p::SLPContentType::SESSION_REQUEST SLPSessionRequestBody
			SLPMessageBody register_content $::p2p::SLPContentType::TRANSFER_REQUEST SLPTransferRequestBody
			SLPMessageBody register_content $::p2p::SLPContentType::TRANSFER_RESPONSE SLPTransferResponseBody
			SLPMessageBody register_content $::p2p::SLPContentType::SESSION_CLOSE SLPSessionCloseBody

		}

		method conf2 { } {
			if { $options(-euf_guid) != "" } {
				$self setHeader EUF-GUID [join [list "{" $options(-euf_guid) "}"] ""]
			}
			if { $options(-session_id) != "" } {
				$self setHeader SessionID $options(-session_id)
			}
			if { $options(-s_channel_state) != "" } {
				$self setHeader SChannelState $options(-s_channel_state)
			}
			if { $options(-capabilities_flags) != "" } {
				$self setHeader Capabilities-Flags $options(-capabilities_flags)
			}
			if { $options(-context) != "" } {
				$self setHeader Context $options(-context)
			}
		}

		method headers { } {
			return [array get headers]
		}

		method body { } {
			return $body
		}

		method setBody { newBody } {
			set body $newBody
		}

		method setHeaders { headers } {
			$self configure -headers $headers
		}

		method get_header { key } {
			return $headers($key)
		}

		method setHeader { key val } {
			set headers($key) $val
			if { [lsearch $headernames $key] < 0 } {
				set headernames [lappend headernames $key]
			}

		}

		method toString { } {

			set str ""
			set newl \r\n
			#content-length
			foreach key $headernames {
				set value $headers($key)
				set str [join [list $str $key ": " $value $newl] ""] ;#concat strips newlines
			}
			# Ugly hack
			if { [lsearch $headernames "Context"] < 0 && $options(-context) != "" } {
				set key "Context"
				set value [base64::encode $options(-context)]
				set value [string map {"\n" ""} $value]
				set str [join [list $str $key ": " $value $newl] ""]
			}
			set str [join [list $str $newl $body \x00] ""]
			return $str

		}

		method parse { data } {
			variable found 
			if { ![info exists found] } { set found 0 }

			if { [string length $data] == 0 } {
				status_log "Parsing null data!!!!!!!"
				return
			}
			set data [string trim $data \x00]
			set lines [split $data "\n"]
			foreach line $lines {
				set line [string trim $line]
				if { $found == 0 } {
					if { $line == "" } {
						set found 1
					} else {
						set colon [string first : $line]
						set key [string range $line 0 [expr {$colon -1}]]
						set value [string range $line [expr {$colon +1}] end]
						$self setHeader [string trim $key] [string trim $value]
					}
				}
			}
			# TODO: info exists
			catch {set options(-session_id) [$self get_header SessionID]}
			catch {set options(-s_channel_state) [$self get_header SChannelState]}
			catch {set options(-capabilities_flags) [$self get_header Capabilities-Flags]}
			catch {set options(-context) [base64::decode [$self get_header Context]] } 

			if { [info exists headers(EUF-GUID) ] } {
				set euf_guid [$self get_header EUF-GUID]
				set left [string first "{" $euf_guid]
				set right [string first "}" $euf_guid]
				set options(-euf_guid) [string range $euf_guid [expr {$left+1}] [expr {$right-1}]]
			}
		}

		typemethod build {content_type content} {
			set content_type [string trim $content_type]
			status_log "Building content type $content_type"
			if { [array names content_classes -exact $content_type] == "" } {
				set returnme [SLPMessageBody %AUTO% -content_type $content_type]
				$returnme conf2
				$returnme parse $content
				return $returnme
			} else {
				set cls $content_classes($content_type)
				set returnme [$cls %AUTO%]
				$returnme conf2
				$returnme parse $content
				return $returnme
			}
		}

		typemethod register_content { content_type cls } {
			set content_classes($content_type) $cls
		} 
	}

	snit::type SLPNullBody {

		delegate option * to SLPMessageBody
		delegate method * to SLPMessageBody

		constructor { args } {
			install SLPMessageBody using SLPMessageBody %AUTO% -content_type $::p2p::SLPContentType::NULL
			$SLPMessageBody conf2
		}

		destructor {
			$SLPMessageBody destroy
		}
	}

	snit::type SLPSessionRequestBody {

		delegate option * to SLPMessageBody
		delegate method * to SLPMessageBody

		option -app_id ""
		option -context ""

		constructor { args } {
			install SLPMessageBody using SLPMessageBody %AUTO% -session_id 0 -s_channel_state 0 -capabilities_flags 1 -content_type $::p2p::SLPContentType::SESSION_REQUEST
			$self configurelist $args
		}

                destructor {
                        $SLPMessageBody destroy
                }

		method conf2 { } {
			$SLPMessageBody conf2
			set euf_guid [$self cget -euf_guid]
			set app_id [$self cget -app_id]
			set context [$SLPMessageBody cget -context]
			if { $context != "" } { 
				set options(-context) $context 
			} else { 
				$SLPMessageBody configure -context $options(-context) 
			}

			set headers {}
			if { $app_id != "" } {
				$SLPMessageBody setHeader AppID $app_id
			}
			if { $context != "" } {
				$SLPMessageBody setHeader Context [string map {"\n" ""} [base64::encode $context]]
			}

		}

	}

	snit::type SLPTransferRequestBody {

		delegate option * to SLPMessageBody
		delegate method * to SLPMessageBody

		option -session_id ""
		option -s_channel_state ""
		option -capabilities_flags ""
		option -conn_type "Port-Restrict-NAT"
		option -upnp 0
		option -firewall 0

		variable headers -array {}

		constructor { args } {
			install SLPMessageBody using SLPMessageBody %AUTO% -content_type $::p2p::SLPContentType::TRANSFER_REQUEST 
			$self configurelist $args
			$SLPMessageBody conf2
			$SLPMessageBody setHeader NetID -1388627126
			$SLPMessageBody setHeader Bridges "TCPv1 SBBridge"
			$SLPMessageBody setHeader Conn-Type $options(-conn_type)
			$SLPMessageBody setHeader TCP-Conn-Type "Symmetric-NAT"
			$SLPMessageBody setHeader UPnPNat "false"
			$SLPMessageBody setHeader ICF "false"
			$SLPMessageBody setHeader Nonce "\{[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]\}"
			$SLPMessageBody setHeader Nat-Trav-Msg-Type "WLX-Nat-Trav-Msg-Direct-Connect-Req"
		}

                destructor {
                        $SLPMessageBody destroy
                }

		method bridges { } {

			return [split [$self get_header "Bridges"] " "]

		}

	}

	snit::type SLPTransferResponseBody {
		delegate option * to SLPMessageBody
		delegate method * to SLPMessageBody

		option -bridge ""
		option -listening "false"
		option -nonce ""
		option -internal_ips ""
		option -internal_port ""
		option -external_ips ""
		option -external_port ""
		option -session_id ""
		option -s_channel_state 0
		option -capabilities_flags 1
		option -conn_type "Port-Restrict-NAT"

		variable headers -array {}

		constructor { args } {
			install SLPMessageBody using SLPMessageBody %AUTO% -content_type $::p2p::SLPContentType::TRANSFER_RESPONSE

			$self configurelist $args

			$SLPMessageBody conf2

			$SLPMessageBody setHeader Listening $options(-listening)
                        $SLPMessageBody setHeader Conn-Type $options(-conn_type)
                        $SLPMessageBody setHeader TCP-Conn-Type "Symmetric-NAT"
                        $SLPMessageBody setHeader IPv6-global ""
                        $SLPMessageBody setHeader Capabilities-Flags $options(-capabilities_flags)
                        if { $options(-external_ips) != "" } {
                                $SLPMessageBody setHeader IPv4External-Addrs $options(-external_ips)
                        }
                        if { $options(-external_port) != "" } {
                                $SLPMessageBody setHeader IPv4External-Port $options(-external_port)
                        }
                        if { $options(-internal_ips) != "" } {
                                $SLPMessageBody setHeader IPv4Internal-Addrs $options(-internal_ips)
                        }
                        if { $options(-internal_port) != "" } {
                                $SLPMessageBody setHeader IPv4Internal-Port $options(-internal_port)
                        }
                        $SLPMessageBody setHeader Nat-Trav-Msg-Type "WLX-Nat-Trav-Msg-Direct-Connect-Req"
                        if { $options(-bridge) != "" } {
                                $SLPMessageBody setHeader Bridge $options(-bridge)
                        }
                        if { $options(-nonce) != "" } {
                                set nonce [string toupper $options(-nonce)]
                                if { [string first \{ $nonce] < 0 } {
                                        set nonce \{${nonce}\}
                                        set options(-nonce) $nonce
                                }
                                $SLPMessageBody setHeader Nonce $nonce
                        }
                        if { $options(-session_id) != "" } {
                                $SLPMessageBody setHeader SessionID $options(-session_id)
                        }
                        $SLPMessageBody setHeader SChannelState $options(-s_channel_state)

		}

                destructor {
                        $SLPMessageBody destroy
                }

		method bridge { } {

			return [$self get_header "Bridge"]

		}

		method listening { } {

			return [$self get_header "Listening"]

		}

		method nonce { } {

			return [$self get_header "Nonce"]

		}

		method internal_ips { } {

			return [split [$self get_header "IPv4Internal-Addrs"]]

		}

		method internal_port { } {

			return [split [$self get_header "IPv4Internal-Port"]]

		}

		method external_ips { } {

			if { [catch {set returnme [split [$self get_header "IPv4External-Addrs"]]} res] } {
				return ""
			}
			return $returnme

		}

		method external_port { } {

			if { [catch {set returnme [split [$self get_header "IPv4External-Port"]]} res] } {
				return ""
			}
			return $returnme

		}


	}

	snit::type SLPSessionCloseBody {

		delegate method * to SLPMessageBody
		delegate option * to SLPMessageBody

		option -context ""
		variable headers -array {}

		constructor { args } {
			install SLPMessageBody using SLPMessageBody %AUTO% -content_type $::p2p::SLPContentType::SESSION_CLOSE
			$self configurelist $args
			$SLPMessageBody conf2

			if { $options(-context) != "" } {
				set headers(Context) [string map {"\n" ""} [base64::encode $options(-context)]]
			}

		}

                destructor {
                        $SLPMessageBody destroy
                }

	}

	snit::type SLPSessionFailureResponseBody {

		delegate method * to SLPMessageBody
		delegate option * to SLPMessageBody

		constructor { args } {
			install SLPMessageBody using SLPMessageBody %AUTO%
			$SLPMessageBody conf2
		}

                destructor {
                        $SLPMessageBody destroy
                }

	}
	#::p2p::SLPRequestMessage msg1 -frm sender@hotmail.com -to receiver@hotmail.com
}
