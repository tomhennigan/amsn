namespace eval ::p2p {

	snit::type SwitchboardP2PTransport {

		delegate method * to BaseP2PTransport
		delegate option * to BaseP2PTransport

		option -name "switchboard"
		option -protocol "SBBridge"
		option -rating 0
		option -peer_guid ""
		option -switchboard ""
		option -connected 1
		option -contacts ""
		option -listening 0
		option -client ""

		#variable queue {}

		constructor { args } {

			install BaseP2PTransport using BaseP2PTransport %AUTO% -transport $self
			$self configurelist $args
			$BaseP2PTransport conf2
			::Event::registerEvent ackReceived all [list $self On_ack]

		}

		destructor {
			
			catch {::Event::unregisterEvent ackReceived all [list $self On_ack]}
			$BaseP2PTransport destroy

		}

		#method close {} {

		#	BaseP2PTransport close $self
			#::MSN::CloseSB [::MSN::SBFor $peer]

		#}

		method get_sock { } {

			set sb [::MSN::SBFor [$self cget -peer]]
			return [$sb cget -sock]

		}

		method On_ack { event sb } {

			#if { $sb != [::MSN::SBFor [$self cget -peer]] } {
				#status_log "Not acked for [$self cget -peer] on $sb"
				return
			#} else {
			#	status_log "Processing queue for $sb"
			#	if { [llength $queue] <= 0 } { return }
			#	eval [lindex $queue 0]
			#	set queue [lreplace $queue 0 0]
			#}

		}

		typemethod Can_handle_message { message switchboard_client} {

			#could we have several content types?
			return [expr { [string first "application/x-msnmsgrp2p" [$message cget -content_type] >= 0} ]

			}

			method rating {} {
				return 0
			}

			method max_chunk_size {} {
				return 1250
			}

			method Send_chunk { peer peer_guid chunk } {

				set content_type "application/x-msnmsgrp2p"
				set sendme [Message %AUTO%]
				$sendme add_header MIME-Version 1.0
				$sendme add_header Content-Type $content_type
				if { [$self version] == 1 } {
					$sendme add_header P2P-Dest $peer
				} else {
					$sendme add_header P2P-Src "[::abook::getPersonal login]\;[::config::getGlobalKey machineguid]"
					$sendme add_header P2P-Dest "$peer\;$peer_guid"
				}  
				#binary scan [$chunk cget -application_id] iu appid
				set body [$chunk toString]
				$sendme set_body $body
				set data [$sendme toString]
				set data_len [expr [string length $data]]
				set chatid [::MSN::chatTo $peer]
				set sb [::MSN::SBFor $chatid]
				if { [$sb get_unacked] < 10 } {
					::MSN::ChatQueue $chatid [list ::MSN::WriteSBNoNL $sb "MSG" "D $data_len\r\n$data"]
				} else {
					#set queue [lappend queue [list ::MSN::ChatQueue $chatid [list ::MSN::WriteSBNoNL [::MSN::SBFor $chatid] "MSG" "D $data_len\r\n$data"]]]
					#set queue [lappend queue [list $self AddToQueue $chatid $data]]
					$self AddToQueue $chatid $data
				}
				catch {$sendme destroy}
			}

			method AddToQueue { chatid data } {

				set data_len [expr [string length $data]]
				::MSN::ChatQueue $chatid [list ::MSN::WriteSBNoNL [::MSN::SBFor $chatid] "MSG" "D $data_len\r\n$data"]

			}

			method On_message_received { message} {

				set version 1
				set headers [$message headers]
				foreach {key value} $headers {
					if { $key == "P2P-Dest" && [string first ";" $value] >= 0 } {
						set version 2
						set semic [string first ";" $value]
						set dest_guid [string range $value [expr {$semic+1}] end]
						if { $dest_guid != [::config::getGlobalKey machineguid] } {
							#this chunk is for our other self
							status_log "Ignoring our other self"
							# TODO: @@@@@@@@@@@ p2pv2T
							#return
						}
					}
				}
				if { [catch {set chunk [MessageChunk parse $version [string range [$message get_body] 0 end-4]]} msg] } {
					status_log "Received erroneous chunk"
					puts "Received erroneous chunk: $msg"
					return ""
				}
				puts "Received a right chunk"
				binary scan [string range [$message get_body] end-4 end] iu appid
				puts "Destroying"
				catch {$message destroy}
				$self On_chunk_received [$self cget -peer] [$self cget -peer_guid] $chunk
				catch {$chunk destroy}

			}

			method On_contact_joined { contact} {
				set options(-contacts) [lappend $options(-contacts) $contact]
			}

			method On_contact_left { contact} {
				#::MSN::CloseSB [::MSN::SBFor $contact]
			}

			typemethod handle_peer { transport_manager peer peer_guid } {
				status_log "Creating new SB for manager $transport_manager"
				return [SwitchboardP2PTransport %AUTO% -peer $peer -peer_guid $peer_guid -transport_manager $transport_manager -contacts $peer ]
			}

			typemethod handle_message { switchboard message transport_manager} {

				array set headers [$message cget -headers]
				set guid ""
				set peer ""
				foreach key [array names headers] {
					set value $headers($key)
					if { $key == "P2P-Src"} {
						if { [lsearch $value ";"] > 0 } {
							set semic [string first ";" $value]
							set peer [string range $value 0 [expr {$semic - 1}]] ;#If that is our own address, check who is in the switchboard
							set guid [string range $value [expr {$semic + 1}] end]]
					} else {
						set peer $value
					}
				} 
			}
			return [SwitchboardP2PTransport %AUTO% -switchboard $switchboard -peer $peer -guid $guid -transport_manager $transport_manager]

		}

		method peer_guid {} {}

		method can_send { peer peer_guid blob {bootstrap}} {
			return [expr { [$self cget -peer]==$peer && [$self cget -peer_guid]==peer_guid } ]
		}

	}

}
