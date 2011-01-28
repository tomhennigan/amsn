namespace eval ::p2p {

	snit::type MSNObjectStore {

		option -client ""
		variable outgoing_sessions -array {}
		variable incoming_sessions -array {}
		variable published_objects {}
		variable incoming_DPs_by_user -array {}

		constructor {args} {

			$self configurelist $args

			#::Event::registerEvent p2pIncomingCompleted all [list $self Incoming_session_transfer_completed]

		}

		destructor {

			set handles [list p2pOnSessionAnswered On_session_answered p2pOnSessionRejected On_session_rejected p2pOutgoingSessionTransferCompleted Outgoing_session_transfer_completed]
                        foreach {event callb} $handles {
                                catch {::Event::unregisterEvent $event all [list $self $callb]}
                        }

		}

		method Can_handle_message { message} {

			status_log "Can I handle $message with body [$message body]?"
			set euf_guid [[$message body] cget -euf_guid]
			if { $euf_guid == $::p2p::EufGuid::MSN_OBJECT } {
				return 1
			} else {
				return 0
			}

		}

		method Handle_message { peer guid message} {

			#status_log "Received message of type [$message info type]!!!"
			set session [MSNObjectSession %AUTO% -session_manager [$self cget -client] -peer $peer -guid $guid -application_id [$message cget -application_id] -message $message -context [[$message body] cget -context]]
			$session conf2

			set incoming_sessions($session) {p2pIncomingCompleted Incoming_session_transfer_completed}
			set msnobj [MSNObject parse [$session cget -context]]
			foreach obj $published_objects {
				if {[$obj cget -shad] == [$msnobj cget -shad]} {
					$session accept [$obj cget -data]
					status_log "Returning session $session!!!!!!"
					$msnobj destroy
					return $session
				}
			}
			$msnobj destroy
			$session reject
			status_log "No such object, rejecting"
			return $session

		}

		method request { msnobj callback {errback ""} {peer ""}} {

			if { [$msnobj cget -data] != "" } {
				status_log "p2p.tcl method request going to eval [lindex $callback 0] $msnobj [lindex $callback 1]"
				eval [lindex $callback 0] $msnobj [lindex $callback 1]
			}

			if { $peer == "" } {
				set peer [$msnobj cget -creator]
			}

			if { [$msnobj cget -type] == $::p2p::MSNObjectType::CUSTOM_EMOTICON } {
				set application_id $::p2p::ApplicationID::CUSTOM_EMOTICON_TRANSFER
			} elseif { [$msnobj cget -type] == $::p2p::MSNObjectType::DISPLAY_PICTURE } {
				set application_id $::p2p::ApplicationID::DISPLAY_PICTURE_TRANSFER
			} elseif { [$msnobj cget -type] == $::p2p::MSNObjectType::WINK } {
				set application_id $::p2p::ApplicationID::WINK_TRANSFER
			} elseif { [$msnobj cget -type] == $::p2p::MSNObjectType::VOICE_CLIP } {
				set application_id $::p2p::ApplicationID::VOICE_CLIP_TRANSFER
			} else {
				return ""
			}

			# TODO: p2pv2:  send a request to all end points of the peer and cancel the other sessions when one of them answers
			set context [$msnobj toString]
			status_log "Context: $context"
			status_log "Peer: $peer"
			set session [MSNObjectSession %AUTO% -session_manager [$self cget -client] -peer $peer -guid "" -application_id $application_id -context $context]
			$session conf2
			status_log "Session $session created with peer [$session cget -peer]"
			set handles [list p2pOnSessionAnswered On_session_answered p2pOnSessionRejected On_session_rejected p2pOutgoingSessionTransferCompleted Outgoing_session_transfer_completed]
			foreach {event callb} $handles {
				::Event::registerEvent $event all [list $self $callb]
			}
			set outgoing_sessions([$session p2p_session]) [list $handles $callback $errback $msnobj]
			$session invite $context

		}

		method publish { msnobj } {

			if { [$msnobj cget -data] != "" } {
				foreach obj $published_objects {
					if {[$obj cget -shad] == [$msnobj cget -shad]} {
						$msnobj destroy
                        	                return
					}
				}

				set published_objects [lappend published_objects $msnobj]
			}

		}

		method Outgoing_session_transfer_completed { event session data} {

			if {![info exists outgoing_sessions($session)] } {
				status_log "$self Outgoing_session_transfer_completed : Couldn't find outgoing session" red
				return
			}

			status_log "Outgoing session transfer completed!!!!!!!"
			set lst $outgoing_sessions($session)
			set handles [lindex $lst 0]
			set callback [lindex $lst 1]
			set errback [lindex $lst 2]
			set msnobj [lindex $lst 3]
			status_log "Callback is $callback"

			foreach {event callb} $handles {
				::Event::unregisterEvent $event all [list $self $callb]
			}

			$msnobj configure -data $data

			set method_name [lindex $callback 0]
			set args [lreplace $callback 0 0]
			status_log "p2p.tcl method Outgoing_session_transfer_completed going to eval $method_name $msnobj $args"
			eval $method_name $msnobj $args

			array unset outgoing_sessions $session

			set type [$msnobj cget -type]
			if { $type == $::p2p::MSNObjectType::CUSTOM_EMOTICON || $type == $::p2p::MSNObjectType::WINK || $type == $::p2p::MSNObjectType::VOICE_CLIP } {
				catch {$msnobj destroy}
			} elseif { $type == $::p2p::MSNObjectType::DISPLAY_PICTURE } {
				catch {$incoming_DPs_by_user([$msnobj cget -creator]) destroy}
				set incoming_DPs_by_user([$msnobj cget -creator]) $msnobj
			}

		}

		method Incoming_session_transfer_completed { event session data } {
			if {![info exists incoming_sessions($session)] } {
				status_log "Incoming_session_transfer_completed : unknown session" red
				return
			}

			set {event callback} $incoming_sessions($session)
			::Event::unregisterEvent $event all [list $self $callback]
			array unset incoming_sessions $session

		}

		method On_session_answered { answered_session } {

			foreach session [array names outgoing_sessions] {
				if { $session == $answered_session } { continue }
				if { [$session cget -peer] != [$answered_session cget -peer] } { continue }
				if { [$session cget -context] != [$answered_session cget -context] } { continue }
				set lst $outgoing_sessions($session)
				set handles [lindex $lst 0]
				set callback [lindex $lst 1]
				set errback [lindex $lst 2]
				set msnobj [lindex $lst 3]
				foreach {event callback} $handles {
					::Event::unregisterEvent $event all [list $self $callback]
				}
				$session cancel
				array unset outgoing_sessions $session
				
			}

		}

		method On_session_rejected { session } {

			if {![info exists outgoing_sessions($session)] } {
				status_log "$self On_session_rejected : Couldn't find outgoing session" red
				return
			}
			$self On_session_answered $session

			set lst $outgoing_sessions($session)
			set handles [lindex $lst 0]
			set callback [lindex $lst 1]
			set errback [lindex $lst 2]
			set msnobj [lindex $lst 3]
			foreach {event callback} $handles {
				::Event::unregisterEvent $event all [list $self $callback]
			}
			if { [info exists [lindex $errback 0]] } {
				status_log "p2p.tcl rejected going to eval [lindex $errback 0] $msnobj [lindex $errback 1]"
				eval [lindex $errback 0] $msnobj [lindex $errback 1]
			}
			array unset outgoing_sessions $session

		}

		method get_all_objects { } {
			return $published_objects
		}

	}
	snit::type WebcamHandler {

		option -client ""
		variable sessions {}

		constructor {args} {

			$self configurelist $args

		}

		method Can_handle_message { message } {

			status_log "Can webcam handle [[$message body] cget -euf_guid]?"
			set euf_guid [[$message body] cget -euf_guid]
			if { $euf_guid == $::p2p::EufGuid::MEDIA_SESSION || $euf_guid == $::p2p::EufGuid::MEDIA_RECEIVE_ONLY } {
				return 1
			}
			return 0

		}

		method Handle_message { peer guid message } {

			set euf_guid [[$message body] cget -euf_guid]
			if { $euf_guid == $::p2p::EufGuid::MEDIA_SESSION } {
				set producer 0
			} elseif { $euf_guid == $::p2p::EufGuid::MEDIA_RECEIVE_ONLY } {
				set producer 1
			}

			set session [WebcamSession %AUTO% -producer $producer -session_manager $options(-client) -peer $peer -euf_guid [[$message body] cget -euf_guid] -message $message]
			set sessions [lappend sessions $session]
			::Event::fireEvent p2pSessionCreated p2pWebcamHandler $session $producer
			$session On_invite_received $message
			return $session

		}

		method Invite { peer producer } {

			status_log "Creating new webcam session"
			if { $producer == 1 } {
				set euf_guid $::p2p::EufGuid::MEDIA_SESSION
			} else {
				set euf_guid $::p2p::EufGuid::MEDIA_RECEIVE_ONLY
			}
			set session [WebcamSession %AUTO% -producer $producer -session_manager $options(-client) -peer $peer -euf_guid $euf_guid]
			set sessions [lappend sessions $session]
			$session invite
			return $session

		}

	}

}
