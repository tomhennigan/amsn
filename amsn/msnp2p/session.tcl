namespace eval ::p2p {

	snit::type P2PSession {

		option -session_manager -default ""
		option -peer -readonly no -default ""
		option -euf_guid -default ""
		option -application_id -default 0
		option -message -default ""
		option -id -default ""
		option -call_id -default ""
		option -cseq -default 0
		option -branch -default ""
		option -incoming -default 0
		option -context -default ""
		option -partof -default ""
		option -fd ""

		variable blobs {}

		#option -cookie "" ;#dummy

		constructor {args} {

			$self configurelist $args
                        ::Event::registerEvent p2pNewBlob all [list $self On_blob_created]
                        ::Event::registerEvent blobConstructed all [list $self On_blob_constructed]
                        ::Event::registerEvent blobDestroyed all [list $self On_blob_destroyed]

		}

		destructor {

			catch {after cancel [list $self On_bridge_selected]}
			catch {::Event::unregisterEvent p2pNewBlob all [list $self On_blob_created]}
			catch {::Event::unregisterEvent p2pCreated all [list $self Bridge_created]}
			catch {::Event::unregisterEvent p2pConnected all [list $self Bridge_switched]}
			catch {::Event::unregisterEvent p2pFailed all [list $self Bridge_failed]}
			catch {::Event::unregisterEvent blobConstructed all [list $self On_blob_constructed]}
			catch {::Event::unregisterEvent blobDestroyed all [list $self On_blob_destroyed]}
			foreach blob $blobs {
				catch {$blob destroy}
			}
			$options(-session_manager) Unregister_session $self

		}

		method conf2 { } {

			if { $options(-message) != "" } {
				set message $options(-message)
				set options(-id) [[$message body] cget -session_id]
				set options(-call_id) [$message cget -call_id]
				set options(-cseq) [$message cget -cseq]
				set options(-branch) [$message cget -branch]
				set options(-incoming) 1
			} else {
				set options(-id) [::p2p::generate_id]
				set options(-call_id) [::p2p::generate_uuid]
				set options(-branch) [::p2p::generate_uuid]
			}

			[$self cget -session_manager] Register_session $self
		}

		method transport_manager { } {

			return [ [$self cget -session_manager] transport_manager]

		}

		method set_receive_data_buffer { buffer total_size} {

			set blob [MessageBlob %AUTO% -application_id [$self cget -application_id] -data $buffer -blob_size $total_size -sid [$self cget -id]]
			[$self transport_manager] register_writable_blob $blob

		}

		method invite { context {size ""} {peer ""} } {

			status_log "Inviting for $context"

			set body [SLPSessionRequestBody %AUTO% -euf_guid $options(-euf_guid) -app_id $options(-application_id) -context $context -session_id $options(-id)]
			$body conf2
			set msg [SLPRequestMessage %AUTO% -method $::p2p::SLPRequestMethod::INVITE -resource "MSNMSGR:$options(-peer)" -to $options(-peer) -frm [::abook::getPersonal login] -branch $options(-branch) -cseq $options(-cseq) -call_id $options(-call_id)]
			$msg conf2
			$msg setBody $body
			$self Send_p2p_data $msg

		}

		method Transreq { {body ""} } {

			after 5000 [list $self On_bridge_selected]
			::Event::registerEvent p2pCreated all [list $self Bridge_created]
			set options(-cseq) 0
			if { $body == "" } {
				set body [SLPTransferRequestBody %AUTO% -session_id $options(-id) -s_channel_state 0 -capabilities_flags 1 -conn_type [::abook::getDemographicField conntype]]
			}
			set msg [SLPRequestMessage %AUTO% -method $::p2p::SLPRequestMethod::INVITE -resource "MSNMSGR:$options(-peer)" -to $options(-peer) -frm [::abook::getPersonal login] -branch $options(-branch) -cseq $options(-cseq) -call_id $options(-call_id)]
			$msg conf2
			$msg setBody $body
			$self Send_p2p_data $msg

		}

		method Respond { status_code} {

			set body [SLPSessionRequestBody %AUTO% -session_id $options(-id)]
			$body conf2
			incr options(-cseq)
			set resp [SLPResponseMessage %AUTO% -status $status_code -to $options(-peer) -frm [::abook::getPersonal login] -cseq $options(-cseq) -branch $options(-branch) -call_id $options(-call_id)]
			$resp setBody $body
			$self Send_p2p_data $resp

		}

		method Respond_transreq { transreq status body} {

			incr options(-cseq)
			set resp [SLPResponseMessage %AUTO% -status $status -to $options(-peer) -frm [::abook::getPersonal login] -cseq $options(-cseq) -branch $options(-branch) -call_id $options(-call_id)]
			$resp setBody $body
			$self Send_p2p_data $resp

		}

		method Accept_transreq { transreq bridge listening nonce local_ip local_port extern_ip extern_port} {

			set conn_type [::abook::getDemographicField conntype]
			set body [SLPTransferResponseBody %AUTO% -bridge $bridge -listening $listening -nonce $nonce -internal_ips $local_ip -internal_port $local_port -external_ips $extern_ip -external_port $extern_port -conn_type $conn_type -session_id $options(-id) -s_channel_state 0 -capabilities_flags 1]
			if { $listening != "false" } {
				status_log "Going to listen"
				set trsp [DirectP2PTransport %AUTO% -peer $options(-peer) -transport_manager [$self transport_manager] -nonce $nonce -client $self]
				::Event::registerEvent p2pConnected all [list $self Bridge_switched]
				::Event::registerEvent p2pFailed all [list $self Bridge_failed]
				$trsp listen
			}
			$self Respond_transreq $transreq 200 $body

		}

		method Decline_transreq { transreq} {

			set body [SLPTransferResponseBody %AUTO% -session_id $options(-id)]
			$self Respond_transreq $transreq 603 $body

		}

		method Select_address { transresp } {

			set client_ip [::abook::getDemographicField clientip]
			set local_ip [::abook::getDemographicField localip]
			set port [$transresp external_port]
			set ips {}
			set extern_ips ""

			foreach ip [$transresp external_ips] {
				if { $ip == $client_ip} { ;#same NAT
					set ips {}
					break
				}
				set ips [lappend $ips [list $ip $port]]
			}

			if { [llength $ips] > 0 } {
				status_log "Selected [lindex $ips 0]"
				return [lindex $ips 0]
			}

			set port [$transresp internal_port]
			set dot [string last "." $local_ip]
			set local_subnet [string range $local_ip 0 $dot]
			foreach ip [$transresp internal_ips] {
				status_log "Trying internal IP $ip"
				set dot [string last "." $ip]
				set remote_subnet [string range $ip 0 $dot]
				if { $local_subnet == $remote_subnet} {
					status_log "Selected $ip $port"
					return [list $ip $port]
				}
			}

			#Could not find any valid IPs, so just try something!
			status_log "No suitable IP found, picking one..."
			if { [llength [$transresp external_ips]] > 0 } {
				return [list [lindex [$transresp external_ips] 0] $port]
			} else {
				return [list [lindex [$transresp internal_ips] 0] $port]
			}

		}

		method Bridge_listening { event new_bridge external_ip external_port } {

			#@@@@@@ TODO: add those to SB
			#$self Accept_transreq $transreq [$new_bridge cget -protocol] 1 [$new_bridge cget -nonce] [$new_bridge cget -ip] [$new_bridge cget -port] $external_ip $external_port

		}

		#@@@@@@@@ TODO: make sure these events aren't for another session 
		method Bridge_switched { event new_bridge session } {

			if { $session != $self } { return }
			$self On_bridge_selected

		}

		method Bridge_created { event new_bridge session } {

			if { $session != $self } { return }
			after cancel [list $self On_bridge_selected]

		}

		method Bridge_failed { event new_bridge } {

			$self On_bridge_selected

		}

		method Close { context reason } {

			set body [SLPSessionCloseBody %AUTO% -context $context -session_id $options(-id) -s_channel_state 0]
			::Event::fireEvent p2pSessionClosed p2pSession $options(-id)
			$body conf2
			set options(-cseq) 0
			set options(-branch) [::p2p::generate_uuid]
			set msg [SLPRequestMessage %AUTO% -method $::p2p::SLPRequestMethod::BYE -resource [join [list "MSNMSGR:" $options(-peer)] ""] -to $options(-peer) -frm [::abook::getPersonal login] -branch $options(-branch) -cseq $options(-cseq) -call_id $options(-call_id)]
			$msg conf2
			$msg setBody $body
			$self Send_p2p_data $msg
			#after idle [list catch [list $self destroy]]

		}

		method Send_p2p_data { data_or_filesize {is_file 0} } {
			status_log "Sending p2p data"

			if { $is_file == 1 } {
				set session_id $options(-id)
				set data ""
				set total_size $data_or_filesize
			} elseif { [catch {$data_or_filesize is_SLP}] } {
				set session_id $options(-id)
				set data $data_or_filesize
				set total_size ""
			} else {
				set session_id 0
				set data [$data_or_filesize toString]
				set total_size [string length $data]
			}

			set blob [MessageBlob %AUTO% -application_id $options(-application_id) -data $data -blob_size $total_size -session_id $session_id -fd $options(-fd)]
			[$self transport_manager] send $options(-peer) "" $blob
			if { $is_file == 0 } {
				catch {$data_or_filesize destroy}
			}

		}

		method On_blob_created { event blob } {

			::Event::unregisterEvent p2pNewBlob all [list $self On_blob_created]
			$blob configure -fd $options(-fd)

		}

		method On_blob_constructed { event blob } {

			if { [$blob cget -session_id] != [$self cget -id] } { return }	
			set blobs [lappend blobs $blob]

		}

                method On_blob_destroyed { event blob } {

                        if { [$blob cget -session_id] != [$self cget -id] } { return }
                        set pos [lsearch $blobs $blob]
			set blobs [lreplace $blobs $pos $pos]

		}

		method On_blob_sent { blob } {

			if { [$blob cget -session_id] == 0 } {
				return
			}

			set data [$blob read_data]
			if { [$blob cget -blob_size] == 4 && $data == "\x00\x00\x00\x00" } {
				$self On_data_preparation_blob_sent $blob
			} else {
				$self On_data_blob_sent $blob
			}
			#catch {$blob destroy}

		}

		method On_blob_received { blob } {

			set data [$blob read_data]

			#status_log "Received a new blob: $blob"
			if { [ $blob cget -session_id] == 0 } {
				set msg [SLPMessage build $data]
				$msg configure -application_id [$blob cget -application_id]
				#status_log "Type: [$msg info type] and body: [[$msg body] info type]"
				if { [$msg info type] == "::p2p::SLPRequestMessage" } {
					#status_log "It is SLPRequestMessage"
					if { [[$msg body] info type] == "::p2p::SLPSessionRequestBody" } {
						status_log "Received an invite"
						$self On_invite_received $msg
					} elseif { [[$msg body] info type] == "::p2p::SLPTransferRequestBody" } {
						status_log "Received a transfer request"
						::Event::fireEvent p2pTransreqReceived p2p $msg
					} elseif { [[$msg body] info type] == "::p2p::SLPSessionCloseBody" } {
						status_log "Received a BYE"
						$self On_bye_received $msg
					} elseif { [[$msg body] info type] == "::p2p::SLPTransferResponseBody" } {
						status_log "Our transfer request got accepted"
						$self Transreq_accepted [$msg body]
					} else {
						status_log "$msg : unknown signaling blob"
					}
				} elseif { [$msg info type] == "::p2p::SLPResponseMessage" } {
					#status_log "Received a response"
					if { [[$msg body] info type] == "::p2p::SLPSessionRequestBody" } {
						if { [$msg cget -status] == 200 } {
							status_log "Our session got accepted"
							$self On_session_accepted
							::Event::fireEvent p2pAccepted p2p $self
						} elseif { [$msg cget -status] == 603 } {
							status_log "Our session got rejected :("
							$self On_session_rejected $msg
							::Event::fireEvent p2pRejected p2p $self ""
						}
					} elseif { [[$msg body] info type] == "::p2p::SLPTransferResponseBody" } {
						status_log "Our transfer request got accepted"
						$self Transreq_accepted [$msg body]
					} else {
						status_log "$msg : unknown response blob"
					}
				}
				catch {$msg destroy}
				return
			}

			if { [$blob cget -blob_size] == 4 && $data == "\x00\x00\x00\x00" } {
				status_log "Received a data preparation blob"
				$self On_data_preparation_blob_received $blob
			} else {
				#status_log "Received a data blob"
				$self On_data_blob_received $blob
			}
			#catch {$blob destroy}

		}

		method On_data_chunk_transferred { chunk blob } {

			::Event::fireEvent p2pChunkSent2 p2p $self $chunk $blob

		}

		method Switch_bridge { transreq } {

			set choices [[$transreq body] bridges]
			set proto [[$self transport_manager] get_supported_transport $choices]
			status_log "We will use $proto"
			set new_bridge [[$self transport_manager] create_transport [$self cget -peer] $proto -client $self]
			if { $new_bridge == "" || [$new_bridge cget -connected] == 1 } {
				$self Bridge_selected
			} else {
				#::Event::registerEvent p2pListening all [list $self Bridge_listening ]
				::Event::registerEvent p2pConnected all [list $self Bridge_switched]
				::Event::registerEvent p2pFailed all [list $self Bridge_failed]
			}

		}

		method Request_bridge { } {

			set bridge [[$self transport_manager] find_transport [$self cget -peer]]
			if { $options(-partof) == "" || [$options(-partof) info type] != "::p2p::FileTransferSession" } { ;#MSNObj exists
				$self On_bridge_selected
				return
			}
			if { [info exists bridge] && $bridge != "" && [$bridge rating] > 0 } {
				$self On_bridge_selected
			} else {
				$self Transreq
			}

		}

		method On_data_preparation_blob_sent { blob } { }

		method On_data_blob_sent { blob } { 

			::Event::fireEvent p2pIncomingCompleted p2p $self [$blob cget -data]
			#catch {$blob destroy} ;#No, we are waiting for the ack
			#after idle [list catch [list destroy $self]]

		}

		method On_data_blob_received { blob } {

			::Event::fireEvent p2pOutgoingSessionTransferCompleted p2p $self [$blob cget -data]
			#catch {$blob destroy}

		}

		method On_data_preparation_blob_received { blob } { }

		method Transreq_accepted { transresp } {

			if { [$transresp listening] != "true" } {
				if { [::abook::getDemographicField listening] == "true" } {
					status_log "Going to listen for [$transresp nonce]"
					set body [SLPTransferResponseBody %AUTO% -bridge "TCPv1" -listening  [::abook::getDemographicField listening] -nonce [$transresp nonce] -internal_ips [::abook::getDemographicField localip] -internal_port [config::getKey initialftport] -external_ips [::abook::getDemographicField clientip] -external_port [config::getKey initialftport] -conn_type [::abook::getDemographicField conntype]  -session_id $options(-id) -s_channel_state 0 -capabilities_flags 1]
					set trsp [DirectP2PTransport %AUTO% -peer $options(-peer) -transport_manager [$self transport_manager] -nonce [$transresp nonce] -client $self]
					::Event::registerEvent p2pConnected all [list $self Bridge_switched]
					::Event::registerEvent p2pFailed all [list $self Bridge_failed]
					$trsp listen
					$self Transreq $body
				} else {
					status_log "Bridge failed"
					$self Bridge_failed "" ""
				}
				return
			}

			set ipport [$self Select_address $transresp]
			set ip [lindex $ipport 0]
			set port [lindex $ipport 1]
			status_log "Trying $ip $port"

			#If we received a transreq, it means that the other client won't accept our existing bridge, if any
			#set new_bridge [[$self transport_manager] Get_transport $options(-peer) "" ""] ;# peer_guid and blob not used
			#status_log "We got the new bridge $new_bridge"
			#if { [$new_bridge cget -rating] <= 0 } {
			#	status_log "Bad rating, making a new one"
				set new_bridge [[$self transport_manager] create_transport $options(-peer) [$transresp bridge] -ip $ip -port $port -nonce [$transresp nonce] -client $self]
			#}
			if { $new_bridge == "" || [$new_bridge cget -connected] == 1 } {
				$self Bridge_selected
			} else {
				::Event::registerEvent p2pConnected all [list $self Bridge_switched]
				::Event::registerEvent p2pFailed all [list $self Bridge_failed]
				$new_bridge open
			}

		}

		method Bridge_selected { } { }

		method On_invite_received { msg } { }

		method On_bye_received { msg } { 

			::Event::fireEvent p2pByeReceived p2p $self 
			#after idle [list catch [list $self destroy]]

		}

		method On_session_accepted { } { }

		method On_session_rejected { msg } {

			#after idle [list catch [list $self destroy]]

		}

		method On_bridge_selected { } {

			::Event::fireEvent p2pBridgeSelected p2pSession $self

		}

	}

}
