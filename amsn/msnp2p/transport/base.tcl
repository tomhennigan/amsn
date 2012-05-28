namespace eval ::p2p {

	snit::type BaseP2PTransport {

		option -transport_manager -default ""
		option -name
		option -local_chunk_id ""
		option -remote_chunk_id ""
		option -transport ""
		option -connected 1
		option -peer ""
		option -peer_guid ""

		variable data_blob_queue {}
		variable chunk_queue {}
		variable pending_blob -array {}
		variable pending_ack -array {}
		variable signaling_blobs -array {}
		variable first 1


		constructor { args } {

			$self configurelist $args
			::Event::registerEvent p2pSessionClosed all [list $self On_session_closed]

		}

		method conf2 { } {

			$options(-transport_manager) Register_transport $options(-transport)

			$self Reset

		}

		destructor {

			catch {::Event::unregisterEvent p2pSessionClosed all [list $self On_session_closed]}
			catch {after cancel [list $self Process_send_queue]}
			catch {$options(-transport_manager) Unregister_transport $options(-transport)}
			#$options(-transport) destroy

		}

		method version { } {
			#@@@@@@@@@@@@@@@@@ p2pv2
			if { [::config::getKey protocol] > 15 && [::MSN::hasCapability [::abook::getContactData $options(-peer) clientid] p2pv2]} {
			  return 2
			} else {
			  return 1
			}
		}

		method send {peer peer_guid blob} {

			lappend data_blob_queue [list $peer $peer_guid $blob]
			$self Process_send_queue
		}

		method close { } {
			#set trsp [$self cget -transport_manager]
			#list $trsp unregister_transport $options(-transport)
			#catch {$options(-transport) destroy}
			#destructor will take care of the above
			after idle [list catch [list $options(-transport) destroy]]
		}

		method Reset { } {

			set data_blob_queue {}
			set first 1

		}

		method Add_pending_ack { blob_id {chunk_id 0} } {

			if { ![info exists pending_ack($blob_id)] } {
				set pending_ack($blob_id) {}
			}

			lappend pending_ack($blob_id) $chunk_id
		}

		method Add_pending_blob {ack_id blob} {

			if { [$self version] == 1 } {
				set pending_blob($ack_id) $blob
			} else {
				::Event::fireEvent p2pBlobSent p2pBaseTransport $blob
				catch {$blob destroy}
			}

		}

		method Del_pending_blob { ack_id } {

			if { ![info exists pending_blob($ack_id)] } {
				return
			}
			set blob $pending_blob($ack_id)
			array unset pending_blob $ack_id
			::Event::fireEvent p2pBlobSent p2pBaseTransport $blob
			status_log "Del_pending_blob destroying blob"
			catch {$blob destroy}

		}

		# Unused
		method Del_blobs_of_session { sid } {

			foreach ack_id [array names pending_blob] {
				set blob $pending_blob($ack_id)
				if { [$blob cget -session_id] == $sid } {
					array unset pending_blob $ack_id
					if { [info exists pending_ack([$blob cget -id])] } {
						array unset pending_ack [$blob cget -id]
					}
					status_log "Del_blobs_of_session destroying blob"
					$blob destroy
				}
			}
	
		}

		method Del_pending_ack {blob_id {chunk_id 0} } {

			if { ![info exists pending_ack($blob_id)] } {
				return
			}
			set blob $pending_ack($blob_id)
			set pos [lsearch $blob $chunk_id]
			set blob [lreplace $blob $pos $pos]

			if { [info exists pending_ack($blob_id)] } {
				array unset pending_ack $blob_id
			} else {
				set pending_ack($blob_id) $blob
			}
		}

		method On_chunk_received { peer peer_guid chunk } {
			
			status_log "base.tcl received $chunk"
			puts "base.tcl received $chunk"
			if { [$chunk require_ack] == 1 } {
				puts "Requires ACK"
				status_log "Will send ACK"
				set ack_chunk [$chunk create_ack_chunk]
				$self __Send_chunk $peer $peer_guid $ack_chunk "skip"
				#$ack_chunk destroy
			}

			if { [$chunk is_control_chunk] == 0 || [$chunk is_signaling_chunk] == 1 } {
				puts "No control"
				status_log "It is not a control chunk"
				if { [$chunk is_signaling_chunk] == 1 } {
					status_log "It is a signaling chunk"
					$self On_signaling_chunk_received $chunk
				} else {
					status_log "It is not a signaling chunk either"
					::Event::fireEvent p2pChunkReceived p2pBaseTransport $self $chunk
				}
			}

			if { [$chunk is_ack_chunk] || [$chunk is_nak_chunk]} {
				$self Del_pending_ack [$chunk acked_id]
				$self Del_pending_blob [$chunk acked_id]
			}


			$self Process_send_queue

		}

		method On_signaling_chunk_received { chunk } {

			set blob_id [$chunk blob_id]

			if { [info exists signaling_blobs($blob_id)] } {
				set blob $signaling_blobs($blob_id)
			} else {
				set blob [MessageBlob %AUTO% -application_id [$chunk cget -application_id] -blob_size [$chunk blob_size] -session_id [$chunk session_id] -blob_id $blob_id]
				set signaling_blobs($blob_id) $blob
			}

			$blob append_chunk $chunk
			if { [$blob is_complete] } {
				status_log "The blob $blob is complete"
				::Event::fireEvent p2pBlobReceived p2pBaseTransport $blob
				array unset signaling_blobs $blob_id
				status_log "Signaling chunk received, destroying blob"
				catch {$blob destroy}
			} else {
				status_log "Waiting for more data"
			}

		}

		method On_chunk_sent { chunk blob } {

			::Event::fireEvent p2pChunkSent p2pBaseTransport $chunk $blob
			#$self Process_send_queue

		}

		method On_session_closed { event sid } {

			set queue $data_blob_queue
			set i 0
			foreach item $queue {
				set blob [lindex $item 2]
				if { [$blob cget -session_id] == $sid } {
					set queue [lreplace $queue $i $i]
					set data_blob_queue $queue
					#$blob destroy
				} else {
					incr i
				}
			}

		}

		method Process_send_queue { } {

			status_log "Processing send queue"
			if { [llength $data_blob_queue] > 0 } {
				set queue $data_blob_queue
			} else {
				status_log "Send queue empty!"
				return 0
			}

			#set first 0

			set blob [lindex [lindex $queue 0] 2]
			set peer_guid [lindex [lindex $queue 0] 1]
			set peer [lindex [lindex $queue 0] 0]
			status_log "Blob $blob for $peer"
			if { [$blob is_complete] } {
				status_log "Not resending a complete blob!"
				if { [lindex [lindex $data_blob_queue 0] 2] == $blob } {
					set data_blob_queue [lreplace $data_blob_queue 0 0]

				}
				return
			}

			set chunk [$blob get_chunk [$self version] [$self max_chunk_size] $first] 
			status_log "Sending $chunk"
			$self __Send_chunk $peer $peer_guid $chunk $blob

		}

		method max_chunk_size { } {

			return 1200

		}

		method __Send_chunk {peer peer_guid chunk blob} {
			variable local_chunk_id
			status_log "Sending chunk $chunk to $peer -- $peer_guid"

			if { ![info exists local_chunk_id] } {
				set local_chunk_id [expr {(randByte() << 24) |
				                          (randByte() << 16) |
				                          (randByte() <<  8) |
				                           randByte()}]
			}
			$chunk set_id $local_chunk_id
			set local_chunk_id [$chunk next_id]

			if { [$chunk require_ack] == 1 } {
				$self Add_pending_ack [$chunk ack_id]
			}

			#puts "Going to send [hexify [$chunk toString]]"
			puts "Adding command : Send_chunk $peer $peer_guid $chunk"
			puts "Chunk id is [hexify [$chunk id]]"
			set chunk_queue [lappend chunk_queue [list [list $options(-transport) Send_chunk $peer $peer_guid $chunk] $blob]]
			puts "send $self. Chunk queue: $chunk_queue"

			set sock [$options(-transport) get_sock]
			if { $sock == "" } {
				#Just pretend we sent it??
				return 1
			}
			if { [fileevent $sock writable] == "" } {
				fileevent $sock writable [list $self Process_queue $peer $peer_guid]
			}

			return 1

		}

		method Process_queue { peer peer_guid } {

			set sock [$options(-transport) get_sock]
			fileevent $sock writable ""

			if { [llength $chunk_queue] <= 0 } { return }
			puts "process $self: Chunk queue: $chunk_queue"
			set command [lindex $chunk_queue 0]
			set blob [lindex $command 1]
			set command [lindex $command 0]
			puts "Calling command : $command"
			eval $command
			set chunk_queue [lreplace $chunk_queue 0 0]

			set chunk [lindex $command 4]

			#puts "Sent [hexify [$chunk toString]]"

                        if { $blob != "skip" && [llength $data_blob_queue] > 0 } {
				if { [catch {$blob is_complete}] } {
					#can't really debug something that happens so rarely , so just catch it here...?
					return
				}
				if { [$blob is_complete] } {
					status_log "Queue says blob $blob is complete with chunk $chunk"
					if { [lindex [lindex $data_blob_queue 0] 2] == $blob } {
						set data_blob_queue [lreplace $data_blob_queue 0 0]
					}
					status_log "New queue: $data_blob_queue"
					$self Add_pending_blob [$chunk ack_id] $blob
				 } else {
					status_log "Blob size is [$blob cget -blob_size] and we have [$blob transferred]"
					$self Process_send_queue
				}

				$self On_chunk_sent $chunk $blob
                        }

                        catch {$chunk destroy}

			after 5 [list $self Set_send_chunk_event $peer $peer_guid $sock]

			#$options(-transport) Send_chunk $peer $peer_guid $chunk
			#catch {$chunk destroy}

		}

		method Set_send_chunk_event { peer peer_guid sock } {

			catch { fileevent $sock writable [list $self Process_queue $peer $peer_guid] }

		}

		#method Send_chunk { peer peer_guid chunk } {

		#Implemented in each transport on its own
		#  return ""

		#}

	}

}
