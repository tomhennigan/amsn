namespace eval ::p2p {

	################################################################################
	#
	# setObjOption vars: needed here?
	#
	# YES: canceled, producer, state, my_rid, rid, chatid, inviter, xml, session
	# NO: grabber, window, socket, fd, connected_ips, server, listening, ips,
	#     listening_socket, listening_port, reflector
	# 1: send_syn, webcam
	# 0: conference, authenticated
	#
	################################################################################

	snit::type WebcamSessionMessage {

		option -id ""
		option -producer ""
		option -session ""
		option -body ""
		option -partof ""

		option -localip ""
		option -localport ""
		option -remoteip ""
		option -remoteport ""
		option -rid ""
		option -my_rid ""


		constructor { args } {

			$self configurelist $args
			if { $options(-body) != "" } {
				$self Parse $options(-body)
			} else {
				set rid [myRand 100 199]
				set options(-my_rid) $rid
				$options(-partof) configure -my_rid $rid
			}

		}

		method Parse { body } {

			set body [string map { "\r\n" "" } $body]
			set options(-body) $body
			set list [xml2list $body]
			if { $options(-producer) == 1 } {
				set type "viewer"
			} else {
				set type "producer"
			}
			set session [GetXmlEntry $list "$type:session"]
			set rid [GetXmlEntry $list "$type:rid"]
			set options(-session) $session
			set options(-rid) $rid
			$options(-partof) configure -session $session -rid $rid -producer $options(-producer)
			status_log "Configured parent $options(-partof) to have session $session"
			::MSNCAM::ConnectSockets $options(-partof)

		}

		method toString { } {

			set session $options(-session)
			if { $session == "" } {
				set session [myRand 9000 9999]
				status_log "Random session $session for $options(-partof)"
			}
			set options(-session) $session
			set sid $options(-id)

			if { $options(-rid) != "" } {
				set rid $options(-rid)
			} else {
				set rid $options(-my_rid)
			}

			set udprid [expr {$rid + 1}]
			set conntype [abook::getDemographicField conntype]
			set listening [abook::getDemographicField listening]
			set producer $options(-producer)

			set port [::MSNCAM::OpenCamPort [config::getKey initialftport] $options(-partof)]
			if { [info exists ::cam_mask_ip] } {
				set clientip $::cam_mask_ip
				set localip $::cam_mask_ip
			} else {
				set clientip [::abook::getDemographicField clientip]
				set localip [::abook::getDemographicField localip]
			}

			if { $producer } {
				set begin_type "<producer>"
				set end_type "</producer>"
			} else {
				set begin_type "<viewer>"
				set end_type "</viewer>"
			}

			set header "<version>2.0</version><rid>$rid</rid><session>$session</session><ctypes>0</ctypes><cpu>730</cpu>"
			set tcp "<tcp><tcpport>$port</tcpport><tcplocalport>$port</tcplocalport><tcpexternalport>$port</tcpexternalport><tcpipaddress1>$clientip</tcpipaddress1>"
			if { $clientip != $localip} {
				set tcp "${tcp}<tcpipaddress2>$localip</tcpipaddress2></tcp>"
			} else {
				set tcp "${tcp}</tcp>"
			}

			set udp "<udp><udplocalport>$port</udplocalport><udpexternalport>$port</udpexternalport><udpexternalip>$clientip</udpexternalip><a1_port>$port</a1_port><b1_port>$port</b1_port><b2_port>$port</b2_port><b3_port>$port</b3_port><symmetricallocation>0</symmetricallocation><symmetricallocationincrement>0</symmetricallocationincrement><udpinternalipaddress1>$localip</udpinternalipaddress1></udp>"
			set footer "<codec></codec><channelmode>1</channelmode>"

			set xml "${begin_type}${header}${tcp}${footer}${end_type}\r\n\r\n"

			return $xml

		}

	}

	snit::type WebcamSession {

		delegate option * to p2pSession
		delegate method * to p2pSession

		option -producer 0

		variable answered 0

		# Options that both we and msncam.tcl use
		option -sid ""
		option -session ""
		option -xml ""
		option -canceled ""
		option -my_rid ""
		option -rid ""
		option -chatid ""
		option -inviter 0
		option -blob_id ""
		option -send_syn 0

		# Options for msncam.tcl only (lots of them :()
		option -grabber ""
		option -window ""
		option -socket ""
		option -fd ""
		option -connected_ips ""
		option -server ""
		option -listening ""
		option -ips ""
		option -listening_socket ""
		option -listening_port ""
		option -reflector 0
		option -codec ""
		option -image ""
		option -source ""
		option -grabber ""
		option -grab_proc ""
		option -encoder ""
		option -weblog ""

		option -webcam 1
		option -conference 0
		option -authenticated 0

		variable xml_needed 1

		constructor {args} {

			install p2pSession using P2PSession %AUTO% -application_id $::p2p::ApplicationID::WEBCAM
			$self configurelist $args
			$p2pSession conf2
			set options(-chatid) [$p2pSession cget -peer]
			set options(-sid) [$p2pSession cget -id]
			::Event::registerEvent p2pTransreqReceived all [list $self On_transreq_received]
			::Event::registerEvent p2pOutgoingSessionTransferCompleted all [list $self On_data_blob_received] ;#not really completed, just a blob received
			::Event::registerEvent p2pAccepted all [list $self On_session_accepted]
			::Event::registerEvent p2pRejected all [list $self On_session_rejected]
			::Event::registerEvent p2pByeReceived all [list $self On_bye_received]

		}

		destructor {

			#::Event::fireEvent p2pCallEnded p2pWebcamSession {}
                        catch {::Event::unregisterEvent p2pTransreqReceived all [list $self On_transreq_received]}
                        catch {::Event::unregisterEvent p2pOutgoingSessionTransferCompleted all [list $self On_data_blob_received]}
                        catch {::Event::unregisterEvent p2pAccepted all [list $self On_session_accepted]}
                        catch {::Event::unregisterEvent p2pRejected all [list $self On_session_rejected]}
                        catch {::Event::unregisterEvent p2pByeReceived all [list $self On_bye_received]}
			catch {$session_manager Unregister_session $self}
			$p2pSession destroy

		}

		method invite { } {

			set answered 1
			set context "{B8BE70DE-E2CA-4400-AE03-88FF85B9F4E8}"
			set context [encoding convertto unicode $context]
			if { $options(-producer) == 1 } {
				set euf_guid $::p2p::EufGuid::MEDIA_SESSION
				::CAMGUI::InvitationToSendSent $options(-chatid) $self
			} else {
				set euf_guid $::p2p::EufGuid::MEDIA_RECEIVE_ONLY
				::CAMGUI::InvitationToReceiveSent $options(-chatid) $self
			}
			$self configure -inviter 1 -producer $options(-producer)
			$p2pSession configure -euf_guid $euf_guid
			$p2pSession invite $context

		}

		method accept { } {

			set answered 1
			::CAMGUI::InvitationAccepted [$p2pSession cget -peer] [$p2pSession cget -id]
			set temp_appid [$self cget -application_id]
			$self configure -application_id 0
			$p2pSession Respond 200
			$self configure -application_id $temp_appid
			$self send_binary_syn

		}

		method reject { } {

			set answered 1
			::CAMGUI::InvitationRejected [$p2pSession cget -peer] [$p2pSession cget -id]
			$p2pSession Respond 603
			$self configure -canceled 1
			after 60000 [list catch [list $self destroy]]

		}

		method end { } { 

			if { $answered == 0 } {
				$self reject
			} else {
				set context "\x74\x03\x00\x81"
				$self Close $context ""
				::MSNCAM::CamCanceled $options(-chatid) $self 
			}
			$self configure -canceled 1
			after 60000 [list catch [list $self destroy]]

		}

		method on_media_session_prepared { session } {

			if { $xml_needed == 1 } {
				$self Send_xml
			}

		}

		method On_invite_received { message } {

			if { [[$message body] cget -euf_guid] == $::p2p::EufGuid::MEDIA_SESSION } {
				$self configure -producer 0
			} else {
				$self configure -producer 1
			}
			::CAMGUI::AcceptOrRefuse $options(-chatid) $self $options(-producer)

		}

		method On_transreq_received { event msg } {

			if { [$msg cget -call_id] != [$self cget -call_id] } { return }

			#$self Switch_bridge $msg
			$p2pSession Decline_transreq $msg
			$self send_binary_syn

		}

		method On_bye_received { event session } {

			if { $session != $p2pSession } { return }
			$self configure -canceled 1
			::CAMGUI::CamCanceled $options(-chatid) [$self cget -id]
			after 60000 [list catch [list $self destroy]]

		}

		method On_session_accepted { event session } {

			if { $session != $p2pSession } { return }

			set chatid [$p2pSession cget -peer]
                	set producer [$self cget -producer]
	                ::amsn::WinWrite $chatid "\n" green
        	        ::amsn::WinWriteIcon $chatid winwritecam 3 2
                	set nick [::abook::getDisplayNick $chatid]
	                if { $producer == 1 } {
        	                ::amsn::WinWrite $chatid "[timestamp] [trans sendwebcamaccepted $nick]" green
                	} else {
                        	::amsn::WinWrite $chatid "[timestamp] [trans recvwebcamaccepted $nick]" green
	                }
			#::Event::fireEvent p2pCallAccepted p2pWebcamSession {}
	
		}

		method On_session_rejected { event session message } {

			if { $session != $p2pSession } { return }

			::CAMGUI::InvitationDeclined [$p2pSession cget -peer] [$p2pSession cget -id]
			#::Event::fireEvent p2pCallRejected p2pWebcamSession {}
			$self configure -canceled 1
			after 60000 [list catch [list $self destroy]]

		}

		method On_data_blob_received { event session data } {

			if { $session != $p2pSession } { return }

			#set data [$blob cget -data]
			set data [string range $data 10 end]
			set data [encoding convertfrom unicode $data]
			set data [string trim $data "\x00"]
			status_log "Webcam received data $data"

			if { $options(-send_syn) == 0 } {
				#@@@@@@ TODO: really needed?
				$self send_binary_syn
			}
			if { $data == "syn" } {
				$self send_binary_ack
			} elseif { $data == "ack" && $options(-producer) == 1 } {
				$self Send_xml
			} elseif { [string first "<producer>" $data] >= 0 || [string first "<viewer>" $data] >= 0 } {
				$self Handle_xml $data
			} elseif { [string first "ReflData" $data] == 0 } {
				#@@@@@@@@@@@ MSNCAM where?
			} elseif { $data == "receivedViewerData" } {
				#$self configure -blob_id [$blob cget -blob_id]
				::MSNCAM::ConnectSockets $self
			}

		}

		method send_data { data } {

			set h1 "\x80[binary format s [myRand 0 65000]]\x01\x08\x00"
			set h3 [ToUnicode "${data}\x00"]
			set h2 [binary format i [string length $data]]
			set msg "${h1}${h2}${h3}"
			$p2pSession Send_p2p_data $msg

		}

		method send_binary_syn {} {

			$self send_data "syn"
			$self configure -send_syn 1

		}

		method send_binary_ack {} {

			$self send_data "ack"

		}

		method send_binary_viewer_data {} {

			$self send_data "receivedViewerData"

		}

		method Send_xml {} {

			set xml_needed 0
			status_log "Sent XML for session $options(-sid)"
			set message [WebcamSessionMessage %AUTO% -partof $self -id $options(-sid) -producer $options(-producer) -session $options(-session)]
			$self send_data [$message toString]
			catch {$message destroy}

		}

		method Handle_xml { data } {

			$self configure -xml $data
			set message [WebcamSessionMessage %AUTO% -partof $self -body $data -producer $options(-producer) -session $options(-session)]
			status_log "Received XML for session $options(-sid)"
			if { $options(-producer) == 1 } {
				$self send_binary_viewer_data
			} else {
				$self Send_xml
			}
			catch {$message destroy}

		}

	}

}
