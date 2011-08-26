namespace eval ::p2p {

	snit::type P2PSessionManager {

		variable sessions -array {}
		variable trsp_mgr ""
		option -handlers {}

		constructor {args} {

			$self configurelist $args
			::Event::registerEvent p2pBlobReceived2 all [list $self On_blob_received]
			::Event::registerEvent p2pBlobSent2 all [list $self On_blob_sent]
			::Event::registerEvent p2pChunkSent all [list $self On_chunk_sent]
			::Event::registerEvent p2pChunkTransferred all [list $self On_chunk_received]

		}

		destructor {

                        $self configurelist $args
                        catch {::Event::unregisterEvent p2pBlobReceived2 all [list $self On_blob_received]}
                        catch {::Event::unregisterEvent p2pBlobSent2 all [list $self On_blob_sent]}
                        catch {::Event::unregisterEvent p2pChunkSent all [list $self On_chunk_sent]}
                        catch {::Event::unregisterEvent p2pChunkTransferred all [list $self On_chunk_received]}

                }

		method transport_manager { } {

			if { $trsp_mgr == "" } {
				set trsp_mgr [P2PTransportManager %AUTO%]
			}
			return $trsp_mgr

		}

		method register_handler { handler_class} {

			set options(-handlers) [lappend options(-handlers) $handler_class]

		}

		method Register_session { session} {

			set sid [$session cget -id]
			set sessions($sid) $session
			status_log "Registering $session on $sid"

		}

		method Unregister_session { session } {

			status_log "Unregistering session [$session cget -id]"
			set sid [$session cget -id]
			catch {array unset sessions $sid}
			#$trsp_mgr delete_blobs_of_session [$session cget -peer] $sid
			if { [$self Search_session_by_peer [$session cget -peer]] == "" } {
				$trsp_mgr close_transport [$session cget -peer]
			}

		}

		method On_chunk_sent { event chunk blob } {

			set sid [$chunk get_field session_id]
			#$self configure -session_id $sid
			if { $sid == 0 } {
				return
			}
			set session [$self Get_session $sid]
			if { $session == "" } {
				return
			}
			$session On_data_chunk_transferred $chunk $blob
			#catch {$chunk destroy}

		}

		method On_chunk_received { event chunk blob } {

			set sid [$chunk get_field session_id]
			set session [$self Get_session $sid]
			::Event::fireEvent p2pChunkReceived2 p2pSessionManager $session $chunk $blob
			#catch {$chunk destroy}

		}

		method Get_session { sid } {

			if { [lsearch [array names sessions] $sid ] >= 0 } {
				return $sessions($sid)
			}
			return ""

		}

		method Search_session_by_call { cid } {

			foreach sid [array names sessions] {
				set session $sessions($sid)
				if { [info commands $session] == "" } {
					#Stale session, unregister
					catch {array unset sessions $sid}
					continue
				}
				if { [$session cget -call_id] == $cid } {
					return $session
				} 
			}
			return ""

		}

		method Search_session_by_peer { peer } {

			foreach session [array names sessions] {  
                               if { [info commands $session] == "" } {
                                        #Stale session, unregister
                                        catch {array unset sessions $sid}
                                        continue
                                }
				if { [$session cget -peer] == $peer } {
					return session
				}
			}
			return ""

		}

		method On_blob_received { event blob } {

			#if { [catch {set session [$self Blob_to_session $blob]} res] } {
			#  status_log "Error: $res"
			#  return 0
			#}
			if { [catch {set session [$self Blob_to_session $blob]}]} {
				status_log "ERROR: Cannot get this blob's session ID!!!"
				return
			}
			if { $session == "" } {
				if { [$blob cget -session_id] != 0 } {
					#TODO: send TLP, RESET connection
					status_log "No session!!!!!"
					return
				}
				set slp_data [$blob read_data]
				set msg [SLPMessage build $slp_data]
				$msg configure -application_id [$blob cget -application_id]
				set sid [[$msg body] cget -session_id]

				if { $sid == 0 } {
					status_log "SID shouldn't be 0!!!" black
					catch {$msg destroy}
					return
				}
				
				status_log "Message is [$msg info type] and the body is [[$msg body] info type]"
				set tempses [$self Search_session_by_call [$msg cget -call_id]]
				if { $tempses != "" } {
					set session $tempses
				} elseif { [$msg info type] == "::p2p::SLPRequestMessage" } {
					set peer [$msg cget -frm]
					status_log "Received session request from $peer"
					foreach handler $options(-handlers) {
						status_log "Trying $handler for [[$msg body] cget -euf_guid]"
						if {[$handler Can_handle_message $msg] } {
							#@@@@@@ p2pv2: $guid!!!
							set session [$handler Handle_message $peer "" $msg]
							if { $session != "" } {
								status_log "Got session $session"
								$self Register_session $session
								break
							}
						}
					}
					if { $session == "" } {
						status_log "Don't know how to handle [[$msg body] cget -euf_guid]"
						catch {$msg destroy}
						return ""
					}
					catch {$msg destroy}
				} elseif { [[$msg body] info type] == "::p2p::SLPSessionRequestBody" } {
					status_log "Unknown session"
					catch {$msg destroy}
					return ""
				} else {
					status_log "[$msg info type] : What is this type?"
					catch {$msg destroy}
					return ""
				}
				catch {$msg destroy}
			}
			$session On_blob_received $blob

		}

		method On_blob_sent {event blob} {

			set session [$self Blob_to_session $blob]
			if { $session == "" } {
				status_log "No session?!?!?!?! Something went VERY wrong" white
				return ""
			}
			$session On_blob_sent $blob

		}

		#method Find_contact { account} {}

		method Blob_to_session { blob} {

			set sid [$blob cget -session_id]
			if { $sid == 0 } {
				set slp_data [$blob read_data]
				set message [SLPMessage build $slp_data]
				$message configure -application_id [$blob cget -application_id]
				set sid [[$message body] cget -session_id]
				if { $sid == 0 || $sid == "" } {
					set cid [$message cget -call_id]
					catch {$message destroy}
					return [$self Search_session_by_call $cid]
				}
				catch {$message destroy}
			}

			return [$self Get_session $sid]

		}

	}

}
