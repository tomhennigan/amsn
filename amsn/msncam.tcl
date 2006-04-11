proc setObjOption { obj option value } {
	global objects

	if { [info exists objects($obj)] } {
		set my_list  [set objects($obj)]
	} else {
		set my_list [list]
	}

	array set my_obj $my_list

	set my_obj($option) $value

	set my_list [array get my_obj]
	set objects($obj) $my_list

}

proc getObjOption { obj option } {
	global objects

	if { [info exists objects($obj)] } {
		set my_list  [set objects($obj)]
	} else {
		return ""
	}

	array set my_obj $my_list

	if { [info exists my_obj($option)] } {
		return [set my_obj($option)]
	} else {
		return ""
	}

}

proc nbread { sock numChars } {
	set tmpsize 0
	set tmpdata ""
	
	if { [catch {
		#To avoid to be recalled when we do update
		set oldfileevent [fileevent $sock readable]

		fileevent $sock readable ""
		
		while { $tmpsize < $numChars && ![eof $sock] } {
			append tmpdata [read $sock [expr $numChars - $tmpsize]]
			set tmpsize [string length $tmpdata]
			update
		}

		fileevent $sock readable $oldfileevent
	} errormsg] } {
		status_log "Error in nbread : $errormsg" white
		#We are here if there is an error in the catch
		return ""
	} else {
		return $tmpdata
	}
}

proc nbgets { sock {varName ""} } {
	set char " "
	set data ""
	while { $char != "\n" && $char != "" } {
		set char [nbread $sock 1]
		append data $char
	}
	set data [string range $data 0 [expr [string length $data] - 2] ]
	
	if { $varName != "" } {
		upvar 1 $varName buffer
		set buffer $data
		return [string length $data]
	}

	return $data
}

namespace eval ::MSNCAM {
	namespace export CancelCam SendInvite AskWebcam CamCanceled


	#//////////////////////////////////////////////////////////////////////////////
	# CamCanceled ( chat sid )
	#  This function is called when a file transfer is canceled by the remote contact
	proc CamCanceled { chatid sid } {
		set grabber [getObjOption $sid grabber]
		set window [getObjOption $sid window]

		#draw a notification in the window (gui)
		::CAMGUI::CamCanceled $chatid

		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			set grabber .grabber.seq
			#Delete the button of current cams sending, on Mac OS X, if it exists
			if { [winfo exists .grabber.delete_$sid] } {
				destroy .grabber.delete_$sid
				set ::activegrabbers [expr {$::activegrabbers - 1}]
			}

		} else {
			if { [::CAMGUI::IsGrabberValid $grabber] } {
				::CAMGUI::CloseGrabber $grabber $window
			}
		}
		
		# close file for log of the webcam...
		set fd [getObjOption $sid weblog]
		if { $fd != "" } {
			catch { close $fd }
		}

		if { [winfo exists $window] } {
			wm protocol $window WM_DELETE_WINDOW "destroy $window"
			$window.q configure -command "destroy $window"
			if { [getObjOption $sid producer] } {
				#We disable the button which show the properties
				$window.settings configure -state disable -command ""
			}
		}

		set listening [getObjOption $sid listening_socket]
		if { $listening != "" } {
			catch { close $listening }
		}
		setObjOption $sid listening_socket ""
	}

	#//////////////////////////////////////////////////////////////////////////////
	# CancelFT ( chatid sid )
	# This function is called when a file transfer is canceled by the user
	proc CancelCam { chatid sid } {

		set session_data [::MSNP2P::SessionList get $sid]
		set user_login [lindex $session_data 3]
		set callid [lindex $session_data 5]
		set socket [getObjOption $sid socket]
		setObjOption $socket state "END"

		if {[getObjOption $sid canceled] == 1 } {
			return
		}
		setObjOption $sid canceled 1

		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"


		status_log "Canceling webcam $sid with $chatid \n" red
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] $branchid 0 $callid 0 1 "dAMAgQ==\r\n"] 1]

		if { $socket != "" } {
			status_log "Connected through socket $socket : closing socket\n" red
			catch { close $socket }
			CloseUnusedSockets $sid ""
		}

		CamCanceled $chatid $sid

		#::MSNP2P::SessionList unset $sid
	}

	#//////////////////////////////////////////////////////////////////////////////
	# RejectFT ( chatid sid branchuid uid )
	# This function is called when a file transfer is rejected/canceled
	proc RejectFT { chatid sid branchuid uid } {
		# All we need to do is send a DECLINE
		set slpdata [::MSNP2P::MakeMSNSLP "DECLINE" [lindex [::MSNP2P::SessionList get $sid] 3] [::config::getKey login] $branchuid 1 $uid 0 0 $sid]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

		# And we unset our sid vars
		::MSNP2P::SessionList unset $sid
	}


	#//////////////////////////////////////////////////////////////////////////////
	# AcceptFT ( chatid dest branchuid cseq uid sid filename1 )
	# This function is called when a file transfer is accepted by the user (local)
	proc AcceptWebcam { chatid dest branchuid cseq uid sid producer} {

		setObjOption $sid producer $producer
		setObjOption $sid inviter 0
		setObjOption $sid chatid $chatid
		setObjOption $sid reflector 0


		if { $producer } {
		    setObjOption $sid source [::config::getKey "webcamDevice" "0"]
		}

		# Let's make and send a 200 OK Message
		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr $cseq + 1] $uid 0 0 $sid]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

		SendAcceptInvite $sid $chatid
		status_log "::MSNCAM::SendAcceptInvite $sid $chatid\n" green
		SendSyn $sid $chatid
	}


	proc SendAcceptInvite { sid chatid} {

		set session [::MSNP2P::SessionList get $sid]
		set branchid [lindex $session 9]
		set callid [lindex $session 5]
		set dest [lindex $session 3]

		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

		status_log "branchid  : $branchid\n" red
		set netid [abook::getDemographicField netid]
		set conntype [abook::getDemographicField conntype]
		set upnp [abook::getDemographicField upnpnat]

		if { $netid == "" || $conntype == "" } {
			abook::getIPConfig
			set netid [abook::getDemographicField netid]
			set conntype [abook::getDemographicField conntype]
			if { $netid == "" } { set netid 0 }
			if { $conntype == "" } {set conntype "Firewall" }
		}


		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "INVITE1" -1 -1 -1 -1 $branchid]

		set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid "0 " $callid 0 1 "TRUDPv1 TCPv1" \
				 $netid $conntype $upnp "false"]
		status_log "size : [string length $slpdata]\n" red
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

	}

	proc SendReflData { sid chatid refldata } {

		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]
		set dest [lindex [::MSNP2P::SessionList get $sid] 3]
		incr MsgId
		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1 ]

		binary scan $refldata H* refldata

		set refldata "ReflData:[string toupper $refldata]\x00"
		
		status_log "ReflData is : $refldata"

		set h1 "\x80\x00\x00\x00\x08\x00"
		set refldata [ToUnicode $refldata]
		set h2 [binary format i [string length $refldata]]

		set footer "\x00\x00\x00\x04"
		set msg "${h1}${h2}${refldata}"

		set size [string length $msg]

		set data "[binary format ii $sid $MsgId][binword 0][binword $size][binary format iiii $size 0 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]${msg}${footer}"

		set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $dest\r\n\r\n"

		status_log "Sending Refldata : $data" green

		::MSNP2P::SendPacket [::MSN::SBFor $chatid] "${theader}${data}"
	}

	proc SendSyn { sid chatid } {
		if { [getObjOption $sid send_syn] == 1 } {
			status_log "Try to send double syn"
			return
		}
		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]
		set dest [lindex [::MSNP2P::SessionList get $sid] 3]
		incr MsgId
		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1 ]


		set h1 "\x80[binary format s [myRand 0 65000]]\x01\x08\x00"
		set syn [ToUnicode "syn\x00"]
		set h2 [binary format i [string length $syn]]

		set footer "\x00\x00\x00\x04"
		set msg "${h1}${h2}${syn}"

		set size [string length $msg]

		set data "[binary format ii $sid $MsgId][binword 0][binword $size][binary format iiii $size 0 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]${msg}${footer}"

		set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $dest\r\n\r\n"


		::MSNP2P::SendPacket [::MSN::SBFor $chatid] "${theader}${data}"
		setObjOption $sid send_syn 1
	}


	proc SendAck { sid chatid } {
		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]
		set dest [lindex [::MSNP2P::SessionList get $sid] 3]
		incr MsgId
		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1 ]

		set h1 "\x80\xea\x00\x00\x08\x00"

		set ack [ToUnicode "ack\x00"]
		set h2 [binary format i [string length $ack]]

		set footer "\x00\x00\x00\x04"
		set msg "${h1}${h2}${ack}"

		set size [string length $msg]

		set data "[binary format ii $sid $MsgId][binword 0][binword $size][binary format iiii $size 0 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]${msg}${footer}"

		set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $dest\r\n\r\n"

		::MSNP2P::SendPacket [::MSN::SBFor $chatid] "${theader}${data}"

	}
	proc SendReceivedViewerData { chatid sid } {
		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]
		set dest [lindex [::MSNP2P::SessionList get $sid] 3]
		incr MsgId
		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1 ]


		set h1 "\x80\xec[binary format c [myRand 0 255]]\x03\x08\x00"

		set recv [ToUnicode "receivedViewerData\x00"]
		set h2 [binary format i [string length $recv]]

		set footer "\x00\x00\x00\x04"
		set msg "${h1}${h2}${recv}"

		set size [string length $msg]

		set data "[binary format ii $sid $MsgId][binword 0][binword $size][binary format iiii $size 0 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]${msg}${footer}"

		set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $dest\r\n\r\n"


		::MSNP2P::SendPacket [::MSN::SBFor $chatid] "${theader}${data}"
	}

	#Askwebcam queue, open connection before sending invitation
	proc AskWebcamQueue { chatid } {
		::MSN::ChatQueue $chatid [list ::MSNCAM::AskWebcam $chatid]
	}
	#SendInvite queue, open connection before sending invitation
	proc SendInviteQueue {chatid} {
		::MSN::ChatQueue $chatid [list ::MSNCAM::SendInvite $chatid]
	}
	proc StartVideoConferenceQueue { chatid } {
		::MSN::ChatQueue $chatid [list ::MSNCAM::StartVideoconference $chatid]
	}

	proc SendInvite { chatid } {
		SendCamInvitation $chatid  "4BD96FC0-AB17-4425-A14A-439185962DC8" "\{B8BE70DE-E2CA-4400-AE03-88FF85B9F4E8\}"
	}
	proc AskWebcam { chatid } {
		SendCamInvitation $chatid "1C9AA97E-9C05-4583-A3BD-908A196F1E92" "\{B8BE70DE-E2CA-4400-AE03-88FF85B9F4E8\}"
	}
	proc StartVideoConference { chatid } {
		SendCamInvitation $chatid "4BD96FC0-AB17-4425-A14A-439185962DC8" "\{0425E797-49F1-4D37-909A-031116119D9B\}"
	}

	proc SendCamInvitation { chatid guid context } {
		status_log "Sending Webcam Request\n"

		set sid [expr int([expr rand() * 1000000000])%125000000 + 4]
		# Generate BranchID and CallID
		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

		set dest [lindex [::MSN::usersInChat $chatid] 0]

		if { $context == "\{B8BE70DE-E2CA-4400-AE03-88FF85B9F4E8\}" } {
			setObjOption $sid webcam 1
			setObjOption $sid conference 0
		} else {
			setObjOption $sid webcam 0
			setObjOption $sid conference 1
		}

		# This is a fixed value... it must be that way or the invite won't work
		set context [ToUnicode $context]

		::MSNP2P::SessionList set $sid [list 0 0 0 $dest 0 $callid 0 "webcam" "$context" "$branchid"]

		setObjOption $sid inviter 1
		setObjOption $sid chatid $chatid
		setObjOption $sid reflector 0

		if { $guid == "4BD96FC0-AB17-4425-A14A-439185962DC8" } {
			setObjOption $sid producer 1

		    setObjOption $sid source [::config::getKey "webcamDevice" "0"]
		    ::CAMGUI::InvitationToSendSent $chatid
		} else {
			setObjOption $sid producer 0
			::CAMGUI::InvitationToReceiveSent $chatid
		}

		status_log "branchid : [lindex [::MSNP2P::SessionList get $sid] 9]\n"



		# Create and send our packet
		set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 0 $callid 0 0 $guid $sid 4 \
				 [string map { "\n" "" } [::base64::encode "$context"]]]
		::MSNP2P::SendPacketExt [::MSN::SBFor $chatid] $sid $slpdata 1
		status_log "Sent an INVITE to [::MSN::usersInChat $chatid]  on chatid $chatid for webcam\n" red

	}

	proc answerCamInvite { sid chatid branchid } {


		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 -1 -1 -1 -1 -1 "$branchid" ]
		set session [::MSNP2P::SessionList get $sid]
		set dest [lindex $session 3]
		set callid [lindex $session 5]

		set slpdata [::MSNP2P::MakeMSNSLP "DECLINE" $dest [::config::getKey login] $branchid 1 $callid 0 3]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

		SendSyn $sid $chatid

	}

	proc OpenCamPort { port sid} {
		while { [catch {set sock [socket -server "::MSNCAM::handleMsnCam $sid" $port] } ] } {
			incr port
		}
		setObjOption $sid listening_socket $sock
		status_log "Opening server on port $port\n" red
		return $port
	}


	proc handleMsnCam { sid sock ip port } {


		if { [info exists ::test_webcam_reflector] && $::test_webcam_reflector} {
			status_log "Received connection from $ip on port $port - socket $sock\n" red
			status_log "Closing the socket to allow testing of the reflector...\n" red
			catch { close $sock}
			return
		}

		setObjOption $sock sid $sid
		setObjOption $sock server 1
		setObjOption $sock state "AUTH"
		setObjOption $sock reflector 1

		status_log "Received connection from $ip on port $port - socket $sock\n" red
		fconfigure $sock -blocking 0 -buffering none -translation {binary binary}

		set connected_ips [getObjOption $sid connected_ips]
		lappend connected_ips [list $ip $port $sock]
		setObjOption $sid connected_ips $connected_ips

		if { [getObjOption $sid socket] == "" } {
			#setObjOption $sid socket $sock
			fileevent $sock readable "::MSNCAM::ReadFromSock $sock"
		}

	}



	proc connectMsnCam { sid ip port } {

		if { [info exists ::test_webcam_reflector] && $::test_webcam_reflector} {
			return 0
		}

		if { [catch {set sock [socket -async $ip $port] } ] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red
			return 0
		} else {

			setObjOption $sock sid $sid
			setObjOption $sock server 0
			setObjOption $sock state "AUTH"
			setObjOption $sock reflector 0

			status_log "connectedto $ip on port $port  - $sock\n" red

			return $sock
		}
	}

	proc ConnectToReflector { sid refldata } {

		set ru [string range $refldata [expr [string first "ru=" $refldata] + 3] end]
		if { [string first "&" $ru] != -1 } {
			set ru [string range $ru 0 [expr [string first "&" $ru] -1]]
		}

		set ti [string range $refldata [expr [string first "ti=" $refldata] + 3] end]
		if { [string first "&" $ti] != -1 } {
			set ti [string range $ti 0 [expr [string first "&" $ti] -1]]
		}


		if { [string first "http://" $ru] != -1 } {
			set ru [string range $ru [expr [string first "http://" $ru] + 7] end]
		}

		set host [string range $ru 0 [expr [string first ":" $ru]-1]]
		set port [string range $ru [expr [string first ":" $ru]+1] end]
		
		status_log "Connecting to reflector : $host at $port\n$ru - [string first ":" $ru]\n$ti\n$refldata\n" red

		if { [catch {set sock [socket $host $port] } ] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red
			::MSNCAM::CancelCam [getObjOption $sid chatid] $sid
		} else {

			setObjOption $sid socket $sock
			setObjOption $sid reflector 1

			setObjOption $sock sid $sid
			setObjOption $sock server 0
			setObjOption $sock state "TID"
			setObjOption $sock tid "$ti"
			setObjOption $sock reflector 1

			status_log "connected to $host on port $port  - $sock\n" red
			
			fconfigure $sock -blocking 0 -buffering none -translation {binary binary} -encoding binary 
			fileevent $sock readable "::MSNCAM::ReadFromSock $sock"
			fileevent $sock writable "::MSNCAM::WriteToSock $sock"

			return $sock
		}
	}



	proc ReadFromSock { sock } {


		set sid [getObjOption $sock sid]

		set producer [getObjOption $sid producer]
		set server [getObjOption $sock server]
		set state [getObjOption $sock state]
		set reflector [getObjOption $sid reflector]

		set my_rid [getObjOption $sid my_rid]
		set rid [getObjOption $sid rid]
		set session [getObjOption $sid session]

	 	if { [eof $sock] } {
 			status_log "WebCam Socket $sock closed\n"
 			close $sock
 			return
 		}


		set data ""

		switch $state {

			"AUTH"
			{
				if { $server } {
					nbgets $sock data
					status_log "Received Data on socket $sock $my_rid - $rid server=$server - state=$state : \n$data\n" red
					if { $data == "recipientid=${my_rid}&sessionid=${session}\r" } {
						nbgets $sock
						setObjOption $sock state "CONNECTED"
						catch { fileevent $sock writable "::MSNCAM::WriteToSock $sock" }
						setObjOption $sid socket $sock
						CloseUnusedSockets $sid $sock
					} else {
						AuthFailed $sid $sock
					}
				}
			}
			"TSP_OK" 
			{
				nbgets $sock data
				status_log "Received Data on Reflector socket $sock $my_rid - $rid server=$server - state=$state : \n$data\n" red
				if { $data == "TSP/1.0 200 OK\r" } {
					nbgets $sock 
					setObjOption $sock state "TSP_CONNECTED"
				} else {
					status_log "ERROR AUTHENTICATING TO THE REFLECTOR - $data\n" red
				}
			}
			"TSP_CONNECTED"
			{
				nbgets $sock data
				status_log "Received Data on Reflector socket $sock $my_rid - $rid server=$server - state=$state : \n$data\n" red
				if { $data == "CONNECTED\r" } {
					nbgets $sock 
					if { $producer } {
						setObjOption $sock state "TSP_SEND"
						catch { fileevent $sock writable "::MSNCAM::WriteToSock $sock" }
					} else {
						setObjOption $sock state "TSP_RECEIVE"
					}
					
				} else {
					status_log "ERROR CONNECTING TO THE REFLECTOR - $data\n" red
				}
			}
			"CONNECTED"
			{
				if { $server == 0 } {
					nbgets $sock data
					status_log "Received Data on socket $sock sending=$producer - server=$server - state=$state : \n$data\n" red
					if { $data == "connected\r" } {
						nbgets $sock
						setObjOption $sid socket $sock
						CloseUnusedSockets $sid $sock
						puts -nonewline $sock "connected\r\n\r\n"
						status_log "Sending \"connected\" to the server\n" red
						if { $producer } {
							setObjOption $sock state "SEND"
							catch { fileevent $sock writable "::MSNCAM::WriteToSock $sock" }
							AuthSuccessfull $sid $sock
						} else {
							setObjOption $sock state "RECEIVE"
							AuthSuccessfull $sid $sock
						}
					} else {
						status_log "ERROR2 : $data -  [nbgets $sock] - [nbgets $sock]\n" red
						AuthFailed $sid $sock
					}
				}
			}
			"SEND" -
			"CONNECTED2"
			{
				if {$server} {

					set data [nbread $sock 13]
					status_log "Received Data on socket $sock sending=$producer - server=$server - state=$state : \n$data\n" red

					if { $data == "connected\r\n\r\n" } {
						setObjOption $sid socket $sock
						if { $producer == 0} {
							setObjOption $sock state "RECEIVE"
						}
					} elseif { $producer == 0 } {
						set header "${data}[nbread $sock 11]"
						setObjOption $sock state "RECEIVE"

						set size [GetCamDataSize $header]
						if { $size > 0 } {
							set data "$header[nbread $sock $size]"
							::CAMGUI::ShowCamFrame $sid $data
						} else {
							setObjOption $sock state "END"
							status_log "ERROR1 : $header - invalid data received" red
						}

					} else {
						setObjOption $sock state "END"
						status_log "ERROR1 : $data - [nbgets $sock] - [nbgets $sock]\n" red
					}

				} else {
					setObjOption $sock state "END"
					status_log "ERROR1 : [nbgets $sock] - should never received data on state $state when we're the client\n" red
				}
			}
			"TSP_SEND" 
			{
			
				set data [nbread $sock 4]
				#status_log "Received $data on state TSP_SEND" blue
				if { $data == "\xd2\x04\x00\x00" } {
					catch { fileevent $sock writable "::MSNCAM::WriteToSock $sock" }
				} else {
					setObjOption $sock state "END"
					status_log "ERROR1 : Received $data from socket on state TSP_SEND \n" red
				}
			}
			"TSP_RECEIVE" -
			"RECEIVE"
			{
				set header [nbread $sock 24]
				set size [GetCamDataSize $header]
				if { $size > 0 } {
					set data "$header[nbread $sock $size]"
					if { [::config::getKey webcamlogs] == 1 } {
						set fd [getObjOption $sid weblog]
						if { $fd == "" } {
							set email [lindex [::MSNP2P::SessionList get $sid] 3]
							if { ![catch {set fd [open [file join $::webcam_dir ${email}.cam] a]}] } {
								fconfigure $fd -translation binary
								setObjOption $sid weblog $fd
							}

						}
					
						catch {puts -nonewline $fd $data}
					}
					catch { fileevent $sock readable "" }

					after 0 "::CAMGUI::ShowCamFrame $sid [list $data];
						 catch {fileevent $sock readable \"::MSNCAM::ReadFromSock $sock\"}"

					if { $reflector } {
						catch { fileevent $sock writable "::MSNCAM::WriteToSock $sock" }
					}
					#::CAMGUI::ShowCamFrame $sid $data
				} else {
					#AuthFailed $sid $sock
					setObjOption $sock state "END"
					status_log "ERROR1 : $data - invalid data received" red

				}

			}
			"END"
			{
				set chatid [getObjOption $sid chatid]
				status_log "Closing socket $sock because it's in END state\n" red
				catch { close $sock }
				CancelCam $chatid $sid

			}
			default
			{
				status_log "option $state of socket $sock : [getObjOption $sock state] not defined.. receiving data [nbgets $sock]... closing \n" red
				setObjOption $sock state "END"
				catch { close $sock }
			}

		}

		#puts  "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n"
		#status_log "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" red



	}
	proc WriteToSock { sock } {

		catch { fileevent $sock writable "" }


		set sid [getObjOption $sock sid]

		set sending [getObjOption $sock sending]
		set server [getObjOption $sock server]
		set state [getObjOption $sock state]
		set producer [getObjOption $sid producer]
		set reflector [getObjOption $sid reflector]

		set rid [getObjOption $sid rid]
		set session [getObjOption $sid session]


		# Uncomment next line to test for failed authentifications...
		#set session 0

		if { [fconfigure $sock -error] != "" } {
			status_log "ERROR writing to socket!!! : [fconfigure $sock -error]" red
			catch { close $sock }
			return
		}


		set data ""

		switch $state {

			"AUTH"
			{
				if { $server == 0 } {
					set data "recipientid=$rid&sessionid=$session\r\n\r\n"
					setObjOption $sock state "CONNECTED"
				}
			}
			"TID" 
			{
				if {$producer} {
					set data "PROD [getObjOption $sock tid] TSP/1.0\r\n\r\n"
					setObjOption $sock state "TSP_OK"
				} else {
					set data "VIEW [getObjOption $sock tid] TSP/1.0\r\n\r\n"
					setObjOption $sock state "TSP_OK"
				}
			}
			"CONNECTED"
			{
				set data "connected\r\n\r\n"
				if { $producer } {
					setObjOption $sock state "SEND"
					catch { fileevent $sock writable "::MSNCAM::WriteToSock $sock" }
					AuthSuccessfull $sid $sock
				} else {
					setObjOption $sock state "CONNECTED2"
					AuthSuccessfull $sid $sock
				}
			}
			"TSP_SEND" 
			{
				after 250 "::CAMGUI::GetCamFrame $sid $sock"	
			}
			"SEND"
			{
				after 250 "::CAMGUI::GetCamFrame $sid $sock;
					   catch {fileevent $sock writable \"::MSNCAM::WriteToSock $sock\" }"
			}
			"TSP_RECEIVE" 
			{
				puts -nonewline $sock "\xd2\x04\x00\x00"
			}
			"END"
			{
				set chatid [getObjOption $sid chatid]
				status_log "Closing socket $sock because it's in END state\n" red
				catch { close $sock }
				CancelCam $chatid $sid
			}

		}

		if { $data != "" } {
			status_log "Writing Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" red
		
			catch { puts -nonewline $sock "$data" }
		}



	}

	proc CloseSocket { sock } {

		set sid [getObjOption $sock sid]

		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]

		set bheader [binary format ii 0 $MsgId][binword 0][binword 0][binary format iiii 0 4 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]

		puts -nonewline $sock "[binary format i 48]$bheader"
		status_log "Closing socket... \n" red
		catch { close $sock }

	}



	proc CreateInvitationXML { sid } {
		set session [getObjOption $sid session]
		if {$session == "" } {
			set session [myRand 9000 9999]
		}

		setObjOption $sid session $session

		set rid [getObjOption $sid my_rid]
		if { $rid == "" } {
			set rid [myRand 100 199]
		}
		setObjOption $sid my_rid $rid

		set udprid [expr {$rid + 1}]
		set conntype [abook::getDemographicField conntype]
		set listening [abook::getDemographicField listening]

		set producer [getObjOption $sid producer]

		# Here we force the creation of a server and send it in the XML in case we don't detect correctly
		# the firewalled state, in any case, it doesn't bother us if we're firewalled, we'll either connect 
		# as a client or use the reflector

		#if {$listening == "true" } {
			set port [OpenCamPort [config::getKey initialftport] $sid]
			set clientip [::abook::getDemographicField clientip]
			set localip [::abook::getDemographicField localip]
		#} else {
		#	set port ""
		#	set clientip ""
		#	set localip ""
		#}

		if { $producer } {
			set begin_type "<producer>"
			set end_type "</producer>"
		} else {
			set begin_type "<viewer>"
			set end_type "</viewer>"
		}

		set header "<version>2.0</version><rid>$rid</rid><session>$session</session><ctypes>0</ctypes><cpu>730</cpu>"
		set tcp "<tcp><tcpport>$port</tcpport>								<tcplocalport>$port</tcplocalport>								<tcpexternalport>$port</tcpexternalport><tcpipaddress1>$clientip</tcpipaddress1>"
		if { $clientip != $localip} {
			set tcp "${tcp}<tcpipaddress2>$localip</tcpipaddress2></tcp>"
		} else {
			set tcp "${tcp}</tcp>"
		}

		set udp "<udp><udplocalport>$port</udplocalport><udpexternalport>$port</udpexternalport><udpexternalip>$clientip</udpexternalip><a1_port>$port</a1_port><b1_port>$port</b1_port><b2_port>$port</b2_port><b3_port>$port</b3_port><symmetricallocation>0</symmetricallocation><symmetricallocationincrement>0</symmetricallocationincrement><udpinternalipaddress1>$localip</udpinternalipaddress1></udp>"
		set footer "<codec></codec><channelmode>1</channelmode>"

		set xml "${begin_type}${header}${tcp}${footer}${end_type}\r\n\r\n\x00"


		return $xml

	}

	proc ReceivedXML {chatid sid } {
		set producer [getObjOption $sid producer]
		set inviter [getObjOption $sid inviter]

		set xml [getObjOption $sid xml]
		set xml [FromUnicode $xml]
		set xml [string map  { "\r\n\r\n\x00" ""} $xml]
		setObjOption $sid xml $xml

		status_log "Got XML : $xml\n" red

		set list [xml2list $xml]

		if { $producer } {
			set type "viewer"
		
		} else {
			set type "producer"
		}
		set session [GetXmlEntry $list "$type:session"]
		set rid [GetXmlEntry $list "$type:rid"]


		status_log "Found session $session and rid $rid\n" red


		setObjOption $sid session $session
		setObjOption $sid rid $rid


		if { $producer } {
			SendReceivedViewerData $chatid $sid
			ConnectSockets $sid
		} else {
			status_log "::MSNCAM::SendXML $chatid $sid" red
			SendXML $chatid $sid
		}

	}

	proc ConnectSockets { sid } {
		set auth [getObjOption $sid authenticated]
		if { $auth == 1} { return }

		set xml [getObjOption $sid xml]
		set list [xml2list $xml]

		set ip_idx 7
		set ips [getObjOption $sid ips]
		set producer [getObjOption $sid producer]

		if { $ips == "" } {
			set ips [list]
		}


		while { 1 } {
			if { $producer } {
				set type "viewer"
				
			} else {
				set type "producer"
			}

			if { $ip_idx == 7 } {
				set ip [GetXmlEntry $list "$type:tcp:tcpexternalip"]
			} elseif { $ip_idx == 6 } {
				set ip [GetXmlEntry $list "$type:udp:udpexternalip"]
			} elseif {$ip_idx > 0 } {
				set ip [GetXmlEntry $list "$type:tcp:tcpipaddress${ip_idx}"]
			} else {
				break
			}


			if {$ip != "" } {
				foreach port_idx { tcpport tcplocalport tcpexternalport } {
					set port [GetXmlEntry $list "$type:tcp:${port_idx}"]
					if {$port != "" } {
						status_log "Trying to connect to $ip at port $port\n" red
						set socket [connectMsnCam $sid "$ip" $port]
						if { $socket != 0 } {
							lappend ips [list $ip $port $socket]
						}
					}
				}
			}


		    incr ip_idx -1
		}

		setObjOption $sid ips $ips

		foreach connection $ips {
			set sock [lindex $connection 2]

			catch { fconfigure $sock -blocking 0 -buffering none -translation {binary binary} }
			catch { fileevent $sock readable "::MSNCAM::CheckConnected $sid $sock " }
			catch { fileevent $sock writable "::MSNCAM::CheckConnected $sid $sock " }
		}

		after 15000 "::MSNCAM::CheckConnectSuccess $sid"

	}

	proc CheckConnectSuccess { sid } {
		set ips [getObjOption $sid ips]
		set connected_ips [getObjOption $sid connected_ips]
		status_log "we have $ips connecting sockets and $connected_ips connected sockets\n" red
		if { [llength $connected_ips] == 0
		     && [getObjOption $sid canceled] != 1 && [getObjOption $sid reflector] != 1} {
			status_log "No socket was connected\n" red
			after 5000 "::MSNCAM::CreateReflectorSession $sid"
		}
	}
	
	proc CreateReflectorSession { sid } {
		if { [getObjOption $sid producer] && [getObjOption $sid reflector] != 1} {
			status_log "Trying Reflector\n" red 
			setObjOption $sid reflector 1
			if { [catch {::http::geturl [list http://m1reflector.spotlife.net/createSession]  -timeout 3000 -command "::MSNCAM::ReflectorCreateSession $sid" }] } {
				status_log "Unable to connect to the reflector.. canceling\n" red
				::MSNCAM::CancelCam [getObjOption $sid chatid] $sid
			}
		}
		
	}

	proc ReflectorCreateSession { sid token } {

		if { ! [info exists ::webcamsn_loaded] } { ::CAMGUI::ExtensionLoaded }
		if { ! $::webcamsn_loaded } { status_log "Error when trying to load Webcamsn extension" red; return }

		set tmp_data [::http::data $token]
		
		#status_log "createSession url get finished : $tmp_data\n" red
		
		if { $::webcamsn_loaded && [::http::status $token] == "ok" && [::http::ncode $token] == 200 } {
			set tmp_data [string range $tmp_data [expr [string first "?>" $tmp_data] +2] end]

			status_log "Got XML : $tmp_data"

			if {[catch {set xml [xml2list  $tmp_data]} res ] } {
				status_log "Error in parsing xml file... $tmp_data  -- $res\n" red
				::MSNCAM::CancelCam [getObjOption $sid chatid] $sid
				::http::cleanup $token
				return
			}
			#status_log "got xml $xml\n" red
			set refl_sid [GetXmlEntry $xml "createsessionresponse:sid"]
			set refl_kid [GetXmlEntry $xml "createsessionresponse:kid"]
			set refl_url [GetXmlEntry $xml "createsessionresponse:createtunnelurl"]

			if {$refl_url == "" } { set refl_url "http://m1reflector14.spotlife.net:9010/createTunnel"}
			if { $refl_sid == "" || $refl_kid == "" } {
				status_log "Was not able to find the sid/kid from the xml..."
				::http::cleanup $token
				return
			}

			set a [::Webcamsn::CreateHashFromKid $refl_kid $refl_sid]
			set refl_url "$refl_url\?sid=$refl_sid\&a=$a"

			status_log "Creating the tunnel with the url : $refl_url\n" red

			if { [catch {::http::geturl [list $refl_url]  -timeout 3000 -command "::MSNCAM::ReflectorCreateTunnel $sid" } res] } {
				status_log "Unable to connect to the reflector.. $res canceling\n" red
				::MSNCAM::CancelCam [getObjOption $sid chatid] $sid
			}
			
			
		} else {
			status_log "Session : Unable to connect to the Reflector: status=[::http::status $token] ncode=[::http::ncode $token]\n" blue
			status_log "tmp_data : $tmp_data\n" blue
			
			::MSNCAM::CancelCam [getObjOption $sid chatid] $sid
		}
		
		::http::cleanup $token
		
	}

	proc ReflectorCreateTunnel {sid token} {
		set tmp_data [ ::http::data $token ]

		status_log "createTunnel  finished : $tmp_data\n" red

		if { [::http::status $token] == "ok" && [::http::ncode $token] == 200 } {
		
			set tmp_data [string range $tmp_data [expr [string first "?>" $tmp_data] +2] end]

			if {[catch {set xml [xml2list $tmp_data] } res ] } {
				status_log "Error in parsing xml file... $tmp_data  -- res\n" red
				::MSNCAM::CancelCam [getObjOption $sid chatid] $sid
				::http::cleanup $token
				return
			}
			status_log "Retreiving information from XML" red
			set tid [GetXmlEntry $xml "createtunnelresponse:tid"]
			set url [GetXmlEntry $xml "createtunnelresponse:tunnelserverurl"]

			set refldata "ru=$url&ti=$tid"

			status_log "ReflData is : $refldata\n" red

			if { [catch { SendReflData $sid [getObjOption $sid chatid] $refldata} res] } {
				status_log "ERROR Sending REFLDATA : $res\n" red
			}
			
			status_log "Connecting to the reflector\n" red
			if { [catch { ConnectToReflector $sid $refldata} res] } {
				status_log "ERROR Connecting to reflector : $res\n" red
			}

		
		} else {
			status_log "Tunnel : Unable to connect to the Reflector: status=[::http::status $token] ncode=[::http::ncode $token]\n" blue
			status_log "tmp_data : $tmp_data\n" blue
			
			::MSNCAM::CancelCam [getObjOption $sid chatid] $sid
		}

		::http::cleanup $token
		
	}

	proc CheckConnected { sid socket}  {
		status_log "fileevent CheckConnectd for socket $socket\n"

		fileevent $socket readable ""
		fileevent $socket writable ""

		if { [eof $socket] || [fconfigure $socket -error] != "" } {
			status_log "Socket didn't connect $socket : [eof $socket] || [fconfigure $socket -error]\n" red
			close $socket

			set ips [getObjOption $sid ips]
			setObjOption $sid ips [RemoveSocketFromList $ips $socket]

		} else {
			status_log "Connected on socket $socket : [eof $socket] || [fconfigure $socket -error]\n" red


			set ips [getObjOption $sid ips]
			for {set idx 0} { $idx < [llength $ips] } {incr idx } {
				set connection [lindex $ips $idx]
				set ip [lindex $connection 0]
				set port [lindex $connection 1]
				set sock [lindex $connection 2]

				if {$sock == $socket } {
					break
				}
			}

			set connected_ips [getObjOption $sid connected_ips]
			lappend connected_ips [list $ip $port $socket]
			setObjOption $sid connected_ips $connected_ips

			if { [getObjOption $sid socket] == "" } {
				#setObjOption $sid socket $socket
				fileevent $socket readable "::MSNCAM::ReadFromSock $socket"
				fileevent $socket writable "::MSNCAM::WriteToSock $socket"
			}

			set ips [getObjOption $sid ips]
			setObjOption $sid ips [RemoveSocketFromList $ips $socket]



		}

		after 5000 "::MSNCAM::CheckConnectSuccess $sid"
	}

	proc AuthSuccessfull { sid socket } {
		status_log "Authentification on socket $socket successfull [fileevent $socket readable] - [fileevent $socket writable]\n" red
		CloseUnusedSockets $sid $socket

		setObjOption $sid authenticated 1

		status_log "wtf  : [fileevent $socket readable] - [fileevent $socket writable]\n" red
	}

	proc AuthFailed { sid socket } {
		set list [RemoveSocketFromList [getObjOption $sid connected_ips] $socket]
		setObjOption $sid connected_ips $list

		#setObjOption $sid socket ""

		catch { close $socket }
		status_log "Authentification on socket $socket failed\n" red
		#if {[llength $list] > 0 } {
		#	set element [lindex $list 0]
		#	set socket [lindex $element 2]

		#	setObjOption $sid socket $socket
		#	fileevent $socket readable "::MSNCAM::ReadFromSock $socket"

		#	if { [getObjOption $sid server] == 0 } {
		#		fileevent $socket writable "::MSNCAM::WriteToSock $socket"
		#	}

		#}

		after 5000 "::MSNCAM::CheckConnectSuccess $sid"
	}

	proc RemoveSocketFromList { list socket } {

		set ips $list
		for {set idx 0} { $idx < [llength $ips] } {incr idx } {
			set connection [lindex $ips $idx]
			set ip [lindex $connection 0]
			set port [lindex $connection 1]
			set sock [lindex $connection 2]

			if {$sock == $socket } {
				set ips [lreplace $ips $idx $idx]
				return $ips
			}
		}
		status_log "Returning list, no $socket in $list\n" red
		return $list
	}

	proc CloseUnusedSockets { sid used_socket {list ""}} {
		if { $list == "" } {
			set ips [getObjOption $sid ips]
			status_log "Closing ips $ips\n" red
			if { $ips != "" } {
				CloseUnusedSockets $sid $used_socket  $ips
				setObjOption $sid ips ""
			}

			set ips [getObjOption $sid connected_ips]
			status_log "Closing connected_ips $ips\n" red
			if { $ips != "" } {
				CloseUnusedSockets $sid $used_socket $ips
			}

			status_log "resetting ips and connected_ipss\n red"

			if { $used_socket != "" } {
				set ips ""
				if { ![catch {set ip [lindex [fconfigure $used_socket -peer] 0]
					set port [lindex [fconfigure $used_socket -peer] 2]}] } {
					lappend ips [list $ip $port $used_socket]
				}

				setObjOption $sid connected_ips $ips
			}
		} else {
			status_log "Closing in $list of length [llength $list]\n" red
			for {set idx 0 } { $idx < [llength $list] } {incr idx } {
				set connection [lindex $list $idx]
				set ip [lindex $connection 0]
				set port [lindex $connection 1]
				set sock [lindex $connection 2]

				status_log "verifying $ip : $port on $sock \n" red
				if {$sock == $used_socket } { continue }

				status_log "Closing $sock\n" red
				catch {
					fileevent $sock readable ""
					fileevent $sock writable ""
				}

				status_log "fileevents reset\n" red
				catch {close $sock}
				status_log "closed\n" red
			}

		}
		status_log "Finished\n" red
	}

	proc SendXML { chatid sid } {
		set producer [getObjOption $sid producer]
		set inviter [getObjOption $sid inviter]

		set xml [CreateInvitationXML $sid]
		set xml [ToUnicode $xml]

		setObjOption $sid my_xml $xml

		set int [binary format i [myRand 0 255]]
		if {$producer } {
			set h1 "\x80\x00\x00\x00"
			set h2 "\x08\x00"
		} else {
			set h1 "\x80\x00\x09\x00"
			set h2 "\x08\x00"
		}

		set size [string length $xml]

		set msg "${h1}${h2}[binary format i $size]${xml}"


		SendXMLChunk $chatid $sid $msg 0 [string length $msg]


		return

	}

	proc SendXMLChunk { chatid sid msg offset totalsize } {
		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]
		set dest [lindex [::MSNP2P::SessionList get $sid] 3]
		incr MsgId
		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1 ]


		if { [expr $offset + 1202] < $totalsize } {
			set footer "\x00\x00\x00\x04"
			set to_send [string range $msg 0 1201]
			set size [string length $to_send]
			set data "[binary format ii $sid $MsgId][binword $offset][binword $totalsize][binary format iiii $size 0 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]${to_send}${footer}"

			set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $dest\r\n\r\n"

			set data "${theader}${data}"
			set msg_len [string length $data]

			::MSNP2P::SendPacket [::MSN::SBFor $chatid] "$data"
			set offset [expr $offset + 1202]
			set msg [string range $msg 1202 end]
			SendXMLChunk $chatid $sid $msg $offset $totalsize
		} else {
			set footer "\x00\x00\x00\x04"
			set to_send $msg
			set size [string length $to_send]
			set data "[binary format ii $sid $MsgId][binword $offset][binword $totalsize][binary format iiii $size 0 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]${to_send}${footer}"

			set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $dest\r\n\r\n"

			set data "${theader}${data}"
			set msg_len [string length $data]

			::MSNP2P::SendPacket [::MSN::SBFor $chatid] "$data"

		}
	}

	proc GetCamDataSize { data } {
		binary scan $data ssssiiii h_size w h r1 p_size fcc r2 r3

		binary scan "\x30\x32\x4C\x4D" I r_fcc

		if { [string length $data] < 24 } {
			return 0
		}

		if { $h_size != 24 } {
			status_log "invalid - $h_size - $data" red
			return -1
		}
		if { $fcc != $r_fcc} {
			status_log "fcc invalide - $fcc - $r_fcc - $data" red
			return -1
		}
		#status_log "resolution : $w x $h - $h_size $p_size \n" red

		return $p_size

	}

	proc SendFrame { sock encoder img } {
		#If the img is not at the right size, don't encode (crash issue..)

		if { [::config::getKey lowrescam] == 1 && [set ::tcl_platform(os)] == "Linux" } {
			set camwidth 160
			set camheight 120
                } else {
                        set camwidth 320
			set camheight 240
                }
		
		if { !([info exists ::test_webcam_send_log] && $::test_webcam_send_log != "")
		     && ([image width $img] != "$camwidth" || [image height $img] != "$camheight") } {
			#status_log "webcam: Wrong size: Width is [image width $img] and height is [image height $img]\n" red
			#return
			
			#We crop the image to avoid bad sizes
			#This is a test..seems to work well for bad-sized ratio camera
			if { [image width $img] != "0" || [image height $img] != "0" } {
				$img configure -width $camwidth -height $camheight
			} else {
				return
			}
			
		}
		if { !([info exists ::test_webcam_send_log] && $::test_webcam_send_log != "")
		     && [catch {set data [::Webcamsn::Encode $encoder $img]} res] } {
			status_log "Error encoding frame : $res\n"
		    return
		} else {
			if { ([info exists ::test_webcam_send_log] && $::test_webcam_send_log != "") } {
				set fd [getObjOption $sock send_log_fd]
				if { $fd == "" } {
					set fd [open $::test_webcam_send_log]
					fconfigure $fd -encoding binary -translation {binary binary}
					setObjOption $sock send_log_fd $fd
				}
				if {[eof $fd] } { 
					close $fd 
					set fd [open $::test_webcam_send_log]
					fconfigure $fd -encoding binary -translation {binary binary}
					setObjOption $sock send_log_fd $fd
					
				}
				    
				set header [read $fd 24]
				set size [GetCamDataSize $header]
				if { $size > 0 } {
					set data "$header[read $fd $size]"
				}
			} else {
				set header "[binary format ssssi 24 [::Webcamsn::GetWidth $encoder] [::Webcamsn::GetHeight $encoder] 0 [string length $data]]"
				set header "${header}\x4D\x4C\x32\x30\x00\x00\x00\x00\x00\x00\x00\x00"
				set data "${header}${data}"

			}
		}
		catch {
		    if { ![eof $sock] && [fconfigure $sock -error] == "" } {
			puts -nonewline $sock "$data"
		    }
		
		}

	}




}

namespace eval ::CAMGUI {

	proc camPresent { } {
		if { ! [info exists ::webcamsn_loaded] } { ::CAMGUI::ExtensionLoaded }
		if { ! $::webcamsn_loaded } { status_log "Error when trying to load Webcamsn extension" red; return }
		if { ! [info exists ::capture_loaded] } { ::CAMGUI::CaptureLoaded }
		if { ! $::capture_loaded } { return }
		#Now we are sure that both webcamsn and capture are loaded
		set campresent 0
		if { [set ::tcl_platform(os)] == "Linux" } {
                        if { [llength [::Capture::ListDevices]] > 0 } {
                                set campresent 1
                        }
		} elseif { [set ::tcl_platform(platform)] == "windows" } {
			tkvideo .webcam_preview
			set devices [.webcam_preview devices]
			if { [llength $devices] > 0 } {
				set campresent 1
			}
			destroy .webcam_preview
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			#Jerome said there's no easy Mac way to check...
			set campresent 1
		}
		return $campresent
	}

	proc ShowCamFrame { sid data } {
		if { ! [info exists ::webcamsn_loaded] } { ExtensionLoaded }
		if { ! $::webcamsn_loaded } { return }

		if { [getObjOption [getObjOption $sid socket] state] == "END" } { return }

		set window [getObjOption $sid window]
		set decoder [getObjOption $sid codec]

		if { $decoder == "" } {
			set decoder [::Webcamsn::NewDecoder]
			setObjOption $sid codec $decoder
		}

		if { $window == "" } {
			set window .webcam_$sid
			toplevel $window
			set chatid [getObjOption $sid chatid]
			wm title $window "$chatid - [::abook::getDisplayNick $chatid]"
			wm protocol $window WM_DELETE_WINDOW "::MSNCAM::CancelCam $chatid $sid"
			set img [image create photo]
			label $window.l -image $img
			pack $window.l
			button $window.q -command "::MSNCAM::CancelCam $chatid $sid" -text "[trans stopwebcamreceive]"
			pack $window.q -expand true -fill x
			setObjOption $sid window $window
			setObjOption $sid image $img
		}

		set img [getObjOption $sid image]

		catch {::Webcamsn::Decode $decoder $img $data}

	}

	proc GetCamFrame { sid socket } {

		if { ! [info exists ::webcamsn_loaded] } { ExtensionLoaded }
		if { ! $::webcamsn_loaded } { return }

		if { ! [info exists ::capture_loaded] } { CaptureLoaded }
		if { ! $::capture_loaded } { return }

		if { [getObjOption $socket state] == "END" } { return }

		set window [getObjOption $sid window]
		set img [getObjOption $sid image]
		set encoder [getObjOption $socket codec]
		set source [getObjOption $sid source]

		if { [set ::tcl_platform(os)] == "Linux" } {
			if {$source == "0" } { set source "/dev/video0:0" }
			set pos [string last ":" $source]
			set dev [string range $source 0 [expr $pos-1]]
			set channel [string range $source [expr $pos+1] end]
		}

		set grabber [getObjOption $sid grabber]
		if { $grabber == "" } {
			if { [set ::tcl_platform(platform)] == "windows" } {
				foreach grabberItm [array names ::grabbers] {
					if {[$grabberItm cget -source] == $source} {
						set grabber $grabberItm
						break
					}
				}
				if { $grabber == "" } {
					set grabber .grabber_$sid
				}
			} elseif { [set ::tcl_platform(os)] == "Darwin" } {
				set grabber .grabber.seq
			} elseif { [set ::tcl_platform(os)] == "Linux" } {
				set grabber [::Capture::GetGrabber $dev $channel]
			}
		}

		set chatid [getObjOption $sid chatid]

		set grab_proc [getObjOption $sid grab_proc]

		if { !([info exists ::test_webcam_send_log] && $::test_webcam_send_log != "") && ![::CAMGUI::IsGrabberValid $grabber] } {
			status_log "Invalid grabber : $grabber"

			if { [set ::tcl_platform(platform)] == "windows" } {

				set grabber .grabber_$sid
				set grabber [tkvideo $grabber]
				set source [getObjOption $sid source]
				$grabber configure -source $source
				$grabber start

				setObjOption $sid grab_proc "Grab_Windows"

			} elseif { [set ::tcl_platform(os)] == "Darwin" } {
				#Add grabber to the window
				if {![::CAMGUI::CreateGrabberWindowMac]} {
					::MSNCAM::CancelCam $chatid $sid
					return
				}
				setObjOption $sid grab_proc "Grab_Mac"

			} elseif { [set ::tcl_platform(os)] == "Linux" } {
				set pos [string last ":" $source]
				set dev [string range $source 0 [expr $pos-1]]
				set channel [string range $source [expr $pos+1] end]

				if { [catch { ::Capture::Open $dev $channel } grabber] } {
					::MSNCAM::CancelCam $chatid $sid
					msg_box "[trans badwebcam]\n$grabber"
					return
				}
				
				if { ![info exists ::webcam_settings_bug] || $::webcam_settings_bug == 0} {
					set settings [::config::getKey "webcam$dev:$channel" "0:0:0:0"]
					set settings [split $settings ":"]
					set set_b [lindex $settings 0]
					set set_c [lindex $settings 1]
					set set_h [lindex $settings 2]
					set set_co [lindex $settings 3]

					if {[string is integer -strict $set_b]} {
						::Capture::SetBrightness $grabber $set_b
					}
					if {[string is integer -strict $set_c]} {
						::Capture::SetContrast $grabber $set_c
					}
					if {[string is integer -strict $set_h]} {
						::Capture::SetHue $grabber $set_h
					}
					if {[string is integer -strict $set_co]} {
						::Capture::SetColour $grabber $set_co
					}
				}
				
				setObjOption $sid grab_proc "Grab_Linux"

				#scale $window.b -from 0 -to 65535 -resolution 1 -showvalue 1 -label "B" -command "::Capture::SetBrightness $grabber" -orient horizontal
				#scale $window.c -from 0 -to 65535 -resolution 1 -showvalue 1 -label "C" -command "::Capture::SetContrast $grabber" -orient horizontal
				#$window.b set 49500
				#$window.c set 39000
				#pack $window.b -expand true -fill x
				#pack $window.c -expand true -fill x

			} else {
				return
			}
			status_log "Created grabber : $grabber"
			set ::grabbers($grabber) [list]
			setObjOption $sid grabber $grabber
			set grab_proc [getObjOption $sid grab_proc]
			status_log "grab_proc is $grab_proc - [getObjOption $sid grab_proc]\n" red
			status_log "SID of this connection is $sid\n" red
		}

		if { $window == "" } {
			set window .webcam_$sid

			#Don't show the sending frame on Mac OS X (we already have the grabber)
			if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
				set img [image create photo]
				set w .grabber

				if { [winfo exists $w] } {
					if {![winfo exists $w.label]} {
						label $w.label -text "[trans webcamsending]"
						pack $w.label
					}
					#Add button for each contact you are sending webcam
					set buttontext [trunc [::abook::getDisplayNick $chatid] . 200 splainf]
					button $w.delete_$sid -command "::MSNCAM::CancelCam $chatid $sid" -text $buttontext
					pack $w.delete_$sid
					if {![info exists ::activegrabbers]} {
						set ::activegrabbers 0
					}
					set ::activegrabbers [expr {$::activegrabbers + 1}]
				}

			} else {
				set img [image create photo]
				toplevel $window
				wm title $window "$chatid - [::abook::getDisplayNick $chatid]"
				label $window.l -image $img
				pack $window.l
				button $window.settings -command "::CAMGUI::ShowPropertiesPage $grabber $img" -text "[trans changevideosettings]"
				pack $window.settings -expand true -fill x
				button $window.q -command "::MSNCAM::CancelCam $chatid $sid" -text "[trans stopwebcamsend]"
				pack $window.q -expand true -fill x
				wm protocol $window WM_DELETE_WINDOW "::MSNCAM::CancelCam $chatid $sid"
			}

			if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
				if {![winfo exists ::grabbers($grabber)]} {
					setObjOption $sid grab_proc "Grab_Mac"
					set ::grabbers($grabber) [list]
					setObjOption $sid grabber $grabber
					set grab_proc [getObjOption $sid grab_proc]
					status_log "grab_proc is $grab_proc - [getObjOption $sid grab_proc]\n" red
					status_log "SID of this connection is $sid\n" red
				}
			}

			if { [info exists ::grabbers($grabber)] } {
				set windows $::grabbers($grabber)
			} else {
				set windows [list]
			}

			lappend windows $window
			set ::grabbers($grabber) $windows

			setObjOption $sid window $window
			setObjOption $sid image $img
		}

		if { $grab_proc == "" } {
			if { [set ::tcl_platform(platform)] == "windows" } {
				setObjOption $sid grab_proc "Grab_Windows"

			} elseif { [set ::tcl_platform(os)] == "Darwin" } {
				setObjOption $sid grab_proc "Grab_Mac"

			} elseif { [set ::tcl_platform(os)] == "Linux" } {
				setObjOption $sid grab_proc "Grab_Linux"

			} else {
				return
			}
			set grab_proc [getObjOption $sid grab_proc]
			status_log "grab_proc is $grab_proc - [getObjOption $sid grab_proc]\n" red
		}


		if {[catch {$grab_proc $grabber $socket $encoder $img} res]} {
			status_log "Trying to call the grabber but get an error $res\n" red
		} 

	}

	proc Grab_Windows {grabber socket encoder img} {

		set encoder [::Webcamsn::NewEncoder HIGH]
		setObjOption $socket codec $encoder

		if { ![catch { $grabber picture $img} res] } {
			::MSNCAM::SendFrame $socket $encoder $img
		} else {
		    status_log "error grabbing : $res\n" red
		}
		#catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
	}

	proc Grab_Linux {grabber socket encoder img} {
		if { [::config::getKey lowrescam] == 1 } {
			set cam_res LOW
		} else {
			set cam_res HIGH
		}
		if { ([info exists ::test_webcam_send_log] && $::test_webcam_send_log != "") ||
		     ![catch { ::Capture::Grab $grabber $img $cam_res} res] } {
			if { !([info exists ::test_webcam_send_log] && 
			      $::test_webcam_send_log != "") &&$encoder == "" } {
				if { $res == "" } { set res $cam_res }
				set encoder [::Webcamsn::NewEncoder $res]
				setObjOption $socket codec $encoder
			}
			::MSNCAM::SendFrame $socket $encoder $img
		} else {
		    status_log "error grabbing : $res\n" red
		}
		#catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
	}

	proc Grab_Mac { grabber socket encoder img } {

		set encoder [::Webcamsn::NewEncoder HIGH]

		if {[winfo ismapped $grabber]} {
			set socker_ [getObjOption $img socket]
			set encoder_ [getObjOption $img encoder]

			if { $socker_ == "" || $encoder_ == "" } {
				setObjOption $img socket $socket
				setObjOption $img encoder $encoder
			}
			$grabber image ImageReady_Mac $img
			::CAMGUI::ImageReady_Mac $grabber $img
		}

		#catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}

	}
	
	proc ImageReady_Mac {w img } {
		set socket [getObjOption $img socket]
		set encoder [getObjOption $img encoder]
		if { $socket == "" || $encoder == "" } { return }
		::MSNCAM::SendFrame $socket $encoder $img
	}
	
	#We use that proc when we try to create the grabber window
	proc CreateGrabberWindowMac {} {
		set w .grabber
		#Stop if the grabber is already there
		if { [winfo exists $w] } {
			return 1
		}
		
		toplevel $w
		wm protocol $w WM_DELETE_WINDOW "::CAMGUI::CloseGrabberWindowMac"
		if { [::config::getKey lowrescam] == 1 } {
			set camwidth 160
		} else {
			set camwidth 320
		}
	
		#Add grabber to the window
		#Show message error if it's not possible
		if { ![catch {seqgrabber $w.seq -width $camwidth} res] } {
			
			catch {$w.seq configure -volume 0}
			pack $w.seq
					
			#Add button to change settings
			button $w.settings -command "::CAMGUI::ChooseDeviceMac" -text "[trans changevideosettings]"
			pack $w.settings
			
			#Add zoom option
			label $w.zoomtext -text "[trans zoom]:" -font sboldf
			spinbox $w.zoom -from 1 -to 5 -increment 0.5 -width 2 -command "catch {$w.seq configure -zoom %s}"
			pack $w.zoomtext
			pack $w.zoom
		} else {
			destroy $w
			#If it's not possible to create the video frame, show the error
			::amsn::messageBox "$res" ok error "[trans failed]"
			return 0
		}
		
		return 1
	}
	
	#This proc is used when someone try to close the grabber window
	proc CloseGrabberWindowMac {} {
		#If the variable activegrabbers doesn't exist, create one and delete the window
		if {![info exists ::activegrabbers]} {
			destroy .grabber
			set ::activegrabbers 0
		}
		
		#If there's no webcam grabber active, destroy the window
		if {$::activegrabbers < 1} {
			destroy .grabber
			set ::activegrabbers 0
		} else {
			msg_box "[trans webcamclosebefcancel]"
		}
	}

	proc IsGrabberValid { grabber } {
#		status_log "Testing grabber : $grabber"
		if { !([info exists ::capture_loaded] && $::capture_loaded) } { return 0 }

		if { [set ::tcl_platform(platform)] == "windows" } {
			return [winfo exists $grabber]
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			return [winfo exists $grabber]
		} elseif { [set ::tcl_platform(os)] == "Linux" } {
			return [::Capture::IsValid $grabber]
		} else {
			return 0
		}
	}

	proc CloseGrabber { grabber window } {
		if { !([info exists ::capture_loaded] && $::capture_loaded ) } { return }

		if { ![info exists ::grabbers($grabber)] } { return }

		set windows $::grabbers($grabber)
		#status_log "For grabber $grabber : windows are $windows"
		set idx [lsearch $windows $window]

		if { $idx == -1 } {
			status_log "Window $window not found in $windows"
			return
		}
		set windows [lreplace $windows $idx $idx]
		status_log "Removed window $window idx : $idx from windows"
		status_log "Now windows is $windows"
		set ::grabbers($grabber) $windows

		if { [llength $windows] > 0 } { return }

		if { [set ::tcl_platform(os)] == "Linux" } {
			::Capture::Close $grabber
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			destroy $grabber
			destroy .grabber
		} elseif { [set ::tcl_platform(platform)] == "windows" } {
			destroy $grabber
		}
		unset ::grabbers($grabber)

	}

	proc CaptureLoaded { } {
		if { [info exists ::capture_loaded] && $::capture_loaded } { return 1 }

		if { [set ::tcl_platform(platform)] == "windows" } {
			set extension "tkvideo"
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			set extension "QuickTimeTcl"
		} elseif { [set ::tcl_platform(os)] == "Linux" } {
			set extension "capture"
		} else {
			set ::capture_loaded 0
			return 0
		}

		if { [catch {package require $extension}] } {
			set ::capture_loaded 0
			return 0
		} else {
			
			#Verify for that pwc_driver
			if { [set ::tcl_platform(os)] == "Linux" }  {
				catch { exec /sbin/lsmod } pwc_driver
				if {[string first $pwc_driver "pwc"] != -1 } {
					set ::pwc_driver 1
				} else {
					set ::pwc_driver 0
				}
			}
			set ::capture_loaded 1
			array set ::grabbers {}
			return 1
		}

	}

	proc ExtensionLoaded { } {
		if { [info exists ::webcamsn_loaded] && $::webcamsn_loaded } { return 1}

		if { [catch {package require webcamsn}] } {
			set ::webcamsn_loaded 0
			return 0
		} else {
			foreach lib [info loaded] {
				if { [lindex $lib 1] == "Webcamsn" } {
					set ::webcamsn_loaded 1
					return 1
				} 
			}
		}
	}

	proc AcceptOrRefuse {chatid dest branchuid cseq uid sid producer} {
		SendMessageFIFO [list ::CAMGUI::AcceptOrRefuseWrapped $chatid $dest $branchuid $cseq $uid $sid $producer] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	#Executed when we receive a request to accept or refuse a webcam session
	proc AcceptOrRefuseWrapped {chatid dest branchuid cseq uid sid producer} {
		
		#Grey line
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		#Show invitation
		::amsn::WinWrite $chatid "[timestamp] [trans webcaminvitereceived [::abook::getDisplayNick $chatid]]" green
		
		#Accept and refuse actions
		::amsn::WinWrite $chatid " - (" green
		::amsn::WinWriteClickable $chatid "[trans accept]" [list ::CAMGUI::InvitationAccepted $chatid $dest $branchuid $cseq $uid $sid $producer] acceptwebcam$sid
		::amsn::WinWrite $chatid " / " green
		::amsn::WinWriteClickable $chatid "[trans reject]" [list ::CAMGUI::InvitationRejected $chatid $sid $branchuid $uid] nowebcam$sid
		::amsn::WinWrite $chatid ")\n" green
		
		#Grey line
		::amsn::WinWriteIcon $chatid greyline 3

	}
	
	proc GotVideoConferenceInvitation {chatid} {			
		SendMessageFIFO [list ::CAMGUI::GotVideoConferenceInvitationWrapped $chatid] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	
	
	#Show a message when we receive a video-conference invitation to ask the user if he wants
	#To ask to receive/send webcam because video-conference is not supported
	proc GotVideoConferenceInvitationWrapped {chatid} {
		
		#Grey line
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		#WebcamIcon
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		#Description of the problem
		::amsn::WinWrite $chatid "[timestamp] [trans videoconversationrequest]\n" green
		#Choices of action
		::amsn::WinWriteClickable $chatid "[trans clickhere]" [list ::CAMGUI::AskWebcamAfterVideoInvitation $chatid] askwebcam$chatid
		::amsn::WinWrite $chatid " [trans askcontactwebcam]" green
		::amsn::WinWriteClickable $chatid "[trans clickhere]" [list ::CAMGUI::SendInviteCamAfterVideoInvitation $chatid] sendwebcam$chatid	
		::amsn::WinWrite $chatid " [trans asksendingyourwebcam]" green
			
	}
	#After we clicked one time on Ask webcam invitaiton, disable the click here button in the chatwindow
	proc AskWebcamAfterVideoInvitation {chatid } {
	
		#Get the chatwindow name
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}
	
		#Disable items in the chatwindow
		[::ChatWindow::GetOutText ${win_name}] tag configure askwebcam$chatid \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind askwebcam$chatid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind askwebcam$chatid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind askwebcam$chatid <Button1-ButtonRelease> ""
		
		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr
		
		#Send the invitation to ask webcam
		::MSNCAM::AskWebcamQueue $chatid
	}
	
	proc SendInviteCamAfterVideoInvitation {chatid} {
		
		#Get the chatwindow name
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}
	
		#Disable items in the chatwindow
		[::ChatWindow::GetOutText ${win_name}] tag configure sendwebcam$chatid \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind sendwebcam$chatid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind sendwebcam$chatid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind sendwebcam$chatid <Button1-ButtonRelease> ""
		
		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr
		#Send the invitation to send webcam
		::MSNCAM::SendInviteQueue $chatid
	}
	
	proc InvitationAccepted { chatid dest branchuid cseq uid sid producer} {
		#Get the chatwindow name
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		#Disable items in the chatwindow
		[::ChatWindow::GetOutText ${win_name}] tag configure acceptwebcam$sid \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <Button1-ButtonRelease> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure nowebcam$sid \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Button1-ButtonRelease> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr
		
		#Execute the accept webcam protocol
		if {[catch {::MSNCAM::AcceptWebcam $chatid $dest $branchuid $cseq $uid $sid $producer} res]} {
			status_log "Error in InvitationAccepted: $res\n" red
			return 0
		}
		
		
	}
	
	proc InvitationRejected {chatid sid branchuid uid} {
		
		#Get the chatwindow name
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		#Disable items in the chatwindow
		[::ChatWindow::GetOutText ${win_name}] tag configure acceptwebcam$sid \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <Button1-ButtonRelease> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure nowebcam$sid \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Button1-ButtonRelease> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr
		
		#Execute the reject webcam protocol
		if {[catch {::MSNCAM::RejectFT $chatid $sid $branchuid $uid} res]} {
			status_log "Error in InvitationRejected: $res\n" red
			return 0
		}
	}
	
	#Executed when you invite someone to a webcam session and he refuses the request
	proc InvitationDeclined {chatid} {
		SendMessageFIFO [list ::CAMGUI::InvitationDeclinedWrapped $chatid] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	proc InvitationDeclinedWrapped {chatid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		::amsn::WinWrite $chatid "[timestamp] [trans webcamrejected [::abook::getDisplayNick $chatid]]\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	#Executed when your contact stops the webcam session
	proc CamCanceled {chatid} {
		SendMessageFIFO [list ::CAMGUI::CamCanceledWrapped $chatid] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	proc CamCanceledWrapped {chatid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		::amsn::WinWrite $chatid "[timestamp] [trans webcamcanceled [::abook::getDisplayNick $chatid]]\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	#Executed when you invite someone to send your webcam
	proc InvitationToSendSent {chatid} {
		SendMessageFIFO [list ::CAMGUI::InvitationToSendSentWrapped $chatid] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	proc InvitationToSendSentWrapped {chatid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		::amsn::WinWrite $chatid "[timestamp] [trans webcamrequestsend]\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	#Executed when you invite someone to receive his webcam
	proc InvitationToReceiveSent {chatid} {
		SendMessageFIFO [list ::CAMGUI::InvitationToReceiveSentWrapped $chatid] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	proc InvitationToReceiveSentWrapped {chatid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		::amsn::WinWrite $chatid "[timestamp] [trans webcamrequestreceive]\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	
	#In that window, we can see many specific configurations related to webcam
	#We can also change webcam settings
	#And we can see if the extensions are loaded
	proc WebcamWizard {} {
	
		set w .webcamwizard
		if {[winfo exists $w]} {
			raise $w
			return
		}
		toplevel $w
		wm title $w "[trans webcamconfigure]"
		abook::getIPConfig
		#Small picture at the top of the window
		label $w.webcampic -image [::skin::loadPixmap webcam]
		pack $w.webcampic
		#Show the two connection informations to know if we are firewalled or not
		frame $w.abooktype
		label $w.abooktype.text -text "[trans type]" -font sboldf
		label $w.abooktype.abook -text [::abook::getDemographicField conntype]
		frame $w.abooklistening
		label $w.abooklistening.text -text "[trans listening]" -font sboldf
		label $w.abooklistening.abook -text [::abook::getDemographicField listening]
		
		pack $w.abooktype.text  -padx 5 -side left
		pack $w.abooktype.abook -padx 5 -side right
		pack $w.abooktype -expand true
		pack $w.abooklistening.text -padx 5 -side left
		pack $w.abooklistening.abook -padx 5 -side right
		pack $w.abooklistening -expand true
		
		if {[::abook::getDemographicField conntype] == "IP-Restrict-NAT" && [::abook::getDemographicField listening] == "false"} {
			label $w.abookresult -text "[trans firewalled]" -font sboldf -foreground red
		} else {
			label $w.abookresult -text "[trans portswellconfigured]" -font sboldf
		}
		pack $w.abookresult -expand true -padx 5
		#Verify if the extension webcamsn is loade
		if {[::CAMGUI::ExtensionLoaded]} {
			label $w.webcamsn -text "[trans webcamextloaded]" -font sboldf
		} else {
			label $w.webcamsn -text "[trans webcamextnotloaded]" -font sboldf -foreground red
		}
		pack $w.webcamsn -expand true -padx 5
		#Verify if the capture extension is loaded, change on each platform
		if { [set ::tcl_platform(platform)] == "windows" } {
			set extension "tkvideo"
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			set extension "QuickTimeTcl"
		} elseif { [set ::tcl_platform(os)] == "Linux" } {
			set extension "capture"
		} else {
			set extension "[trans unknown]"
		}
		
		
		if {[::CAMGUI::CaptureLoaded]} {
			label $w.capture -text "[trans captureextloaded $extension]" -font sboldf
		} else {
			label $w.capture -text "[trans captureextnotloaded $extension]" -font sboldf -foreground red
		}
		pack $w.capture -expand true -padx 5

		checkbutton $w.wanttosharecam -text "[trans wanttosharecam]" -font sboldf -variable [::config::getVar wanttosharecam] -onvalue 1 -offvalue 0 -state disabled -command "::CAMGUI::buttonToggled"
		pack $w.wanttosharecam

		checkbutton $w.lowrescam -text "[trans lowrescam]" -font sboldf -variable [::config::getVar lowrescam] -onvalue 1 -offvalue 0 -state disabled
		if { [set ::tcl_platform(os)] == "Linux" } {
			pack $w.lowrescam
		}

		if { [::CAMGUI::camPresent] == 1 } {
			$w.wanttosharecam configure -state active
			$w.lowrescam configure -state active
		}

		button $w.settings -command "::CAMGUI::ChooseDevice" -text "[trans changevideosettings]"
		#Add button to change settings
		if { ![info exists ::pwc_driver] || $::pwc_driver == 0} {
			#Nothing
		} else {
			label $w.pwc -text "[trans pwcdriver]" -font sboldf -foreground red
			pack $w.pwc
		}
		pack $w.settings
		#Add button to open link to the wiki
		set lang [::config::getGlobalKey language]
		set link "http://amsn.sourceforge.net/webcamfaq.php?lang=$lang"
		button $w.wiki -command "launch_browser $link" -text "[trans webcamfaq]"
		pack $w.wiki
		
		#wm geometry $w 300x150
		
		moveinscreen $w 30
		
	
	}

	proc buttonToggled { } {
		if { [::config::getKey wanttosharecam] } {
			::MSN::setClientCap webcam
		} else {
			::MSN::setClientCap webcam 0
		}
		#Refresh clientid if connected
		if { [::MSN::myStatusIs] != "FLN" } {
			::MSN::changeStatus [set ::MSN::myStatus]
		}
	}
	
	
	proc ChooseDevice { } {
		if { ! [info exists ::capture_loaded] } { CaptureLoaded }
		if { ! $::capture_loaded } { return }

		if { [set ::tcl_platform(os)] == "Linux" } {
			ChooseDeviceLinux
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			ChooseDeviceMac
		} elseif { [set ::tcl_platform(platform)] == "windows" } {
			ChooseDeviceWindows
		}
	}

	proc ShowPropertiesPage { grabber img } {
		if { ! [info exists ::capture_loaded] } { CaptureLoaded }
		if { ! $::capture_loaded } { return }
		if { ![IsGrabberValid $grabber] } { return }
		
		if { [set ::tcl_platform(os)] == "Linux" } {
			ShowPropertiesPageLinux $grabber $img
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			return
		} elseif { [set ::tcl_platform(platform)] == "windows" } {
			$grabber propertypage filter
		}
	}
	#There's a limit of one grabber maximum wih QuickTime TCL
	#To use the videosettings, the grabber needs to be open
	#So we have to verify if it's open, if not we have to create it
	proc ChooseDeviceMac {} {
		set grabber .grabber.seq
		if {![::CAMGUI::CreateGrabberWindowMac]} {
				return
		}
		if {[catch {$grabber videosettings} res]} {
			msg_box $res
		}
	}
	proc ChooseDeviceLinux { } {

		set ::CAMGUI::webcam_preview ""

		set window .webcam_chooser
		set lists $window.lists
		set devs $lists.devices
		set chans $lists.channels
		set buttons $window.buttons
		set status $window.status
		set preview $window.preview
		set settings $window.settings

		if { [winfo exists $window] } {
			raise $window
			return
		}

		set devices [::Capture::ListDevices]

		if { [llength $devices] == 0 } {
			tk_messageBox -message "[trans nodevices]"
			return
		}

		toplevel $window


		frame $lists


		frame $devs -relief sunken -borderwidth 3
		label $devs.label -text "[trans devices]"
		listbox $devs.list -yscrollcommand "$devs.ys set" -background \
		white -relief flat -highlightthickness 0 -height 5
		scrollbar $devs.ys -command "$devs.list yview" -highlightthickness 0 \
		-borderwidth 1 -elementborderwidth 2
		pack $devs.label $devs.list -side top -expand false -fill x
		pack $devs.ys -side right -fill y
		pack $devs.list -side left -expand true -fill both


		frame $chans -relief sunken -borderwidth 3
		label $chans.label -text "[trans channels]"
		listbox $chans.list -yscrollcommand "$chans.ys set"  -background \
		white -relief flat -highlightthickness 0 -height 5 -selectmode extended
		scrollbar $chans.ys -command "$chans.list yview" -highlightthickness 0 \
		-borderwidth 1 -elementborderwidth 2
		pack $chans.label $chans.list -side top -expand false -fill x
		pack $chans.ys -side right -fill y
		pack $chans.list -side left -expand true -fill both

		pack $devs $chans -side left

		label $status -text "[trans choosedevice]"

		set img [image create photo]
		label $preview -image $img
		button $settings -text "[trans changevideosettings]"

		frame $buttons -relief sunken -borderwidth 3
		button $buttons.ok -text "[trans ok]" -command [list ::CAMGUI::Choose_OkLinux $window $devs.list $chans.list $img $devices]
		button $buttons.cancel -text "[trans cancel]" -command [list ::CAMGUI::Choose_CancelLinux $window $img]
		wm protocol $window WM_DELETE_WINDOW [list ::CAMGUI::Choose_CancelLinux $window $img]
		#bind $window <Destroy> "::CAMGUI::Choose_CancelLinux $window $img $preview"
		pack $buttons.ok $buttons.cancel -side left

		pack $lists $status $preview $settings $buttons -side top

		bind $devs.list <Button1-ButtonRelease> [list ::CAMGUI::FillChannelsLinux $devs.list $chans.list $status $devices]
		bind $chans.list <Button1-ButtonRelease> [list ::CAMGUI::StartPreviewLinux $devs.list $chans.list $status $devices $preview $settings]

		foreach device $devices {
			set dev [lindex $device 0]
			set name [lindex $device 1]

			if {$name == "" } {
				set name "[trans devicebusy $dev]"
			}

			$devs.list insert end $name
		}

		tkwait window $window
	}

	proc FillChannelsLinux { device_w chan_w status devices } {
	
		$chan_w delete 0 end

		if { [$device_w curselection] == "" } {
			$status configure -text "[trans choosedevice]"
			return
		}
		variable dev
		set dev [$device_w curselection]
		set device [lindex $devices $dev]
		set device [lindex $device 0]

		if { [catch {set channels [::Capture::ListChannels $device]} res] } {
			$status configure -text $res
			return
		}

		foreach chan $channels {
			$chan_w insert end [lindex $chan 1]
		}

		$status configure -text "[trans choosechannel]"
	}
		

	proc StartPreviewLinux { device_w chan_w status devices preview_w settings} {
	##WARNING : [$device_w curselection] is always "" !!! That's why we use variable dev
	# 	if { [$device_w curselection] == "" } {
	# 		$status configure -text "Please choose a device"
	# 		return
	# 	}

		if { [$chan_w curselection] == "" } {
			$status configure -text "[trans choosechannel]"
			return
		}

		set img [$preview_w cget -image]
		if {$img == "" } {
			return
		}
		
		variable dev
		set chan [$chan_w curselection]
		set device [lindex $devices $dev]
		set device [lindex $device 0]

		if { [catch {set channels [::Capture::ListChannels $device]} res] } {
			$status configure -text $res
			return
		}
		variable channel
		set channel [lindex $channels $chan]
		set channel [lindex $channel 0]

		::CAMGUI::CloseGrabber $::CAMGUI::webcam_preview $preview_w

		if { [catch {set ::CAMGUI::webcam_preview [::Capture::Open $device $channel]} res] } {
			$status configure -text $res
			return
		}

		if { [info exists ::grabbers($::CAMGUI::webcam_preview)] } {
			set windows $::grabbers($::CAMGUI::webcam_preview)
		} else {
			set windows [list]
		}

		lappend windows $preview_w
		set ::grabbers($::CAMGUI::webcam_preview) $windows

		if { ![info exists ::webcam_settings_bug] || $::webcam_settings_bug == 0} {
			set sets [::config::getKey "webcam$device:$channel" "0:0:0:0"]
			set sets [split $sets ":"]
			set set_b [lindex $sets 0]
			set set_c [lindex $sets 1]
			set set_h [lindex $sets 2]
			set set_co [lindex $sets 3]

			if {[string is integer -strict $set_b]} {
				::Capture::SetBrightness $::CAMGUI::webcam_preview $set_b
			}
			if {[string is integer -strict $set_c]} {
				::Capture::SetContrast $::CAMGUI::webcam_preview $set_c
			}
			if {[string is integer -strict $set_h]} {
				::Capture::SetHue $::CAMGUI::webcam_preview $set_h
			}
			if {[string is integer -strict $set_co]} {
				::Capture::SetColour $::CAMGUI::webcam_preview $set_co
			}
		}

		$settings configure -command [list ::CAMGUI::ShowPropertiesPage $::CAMGUI::webcam_preview $img]
		after 0 [list ::CAMGUI::PreviewLinux $::CAMGUI::webcam_preview $img]

	}

	proc PreviewLinux { grabber img } {
		set semaphore ::CAMGUI::sem_$grabber
		set $semaphore 0
		if { [::config::getKey lowrescam] == 1 } {
			set cam_res LOW
		} else {
			set cam_res HIGH
		}
		while { [::Capture::IsValid $grabber] && [lsearch [image names] $img] != -1 } {
			if {[catch {::Capture::Grab $grabber $img $cam_res} res]} {
				status_log "Problem grabbing from the device.  Device busy or unavailable ?\n\t \"$res\""
			}
			after 100 "incr $semaphore"
			tkwait variable $semaphore
		}
	}

	proc Choose_OkLinux { w device_w chan_w img devices } {
		##WARNING : [$device_w curselection] is always "" !!! That's why we use variable dev
		#if { [$device_w curselection] == "" } {
		#	::CAMGUI::Choose_CancelLinux $w $img
		#	return
		#}

		if { [$chan_w curselection] == "" } {
			::CAMGUI::Choose_CancelLinux $w $img
			return
		}
		variable dev
		set chan [$chan_w curselection]

		set device [lindex $devices $dev]
		set device [lindex $device 0]

		## WARNING : [::Capture::ListChannels $device] returns "Error opening device" because the device is used by the preview !
		# that's why we use variable channel
		variable channel

		status_log "webcamDevice=$device:$channel" green

		::config::setKey "webcamDevice" "$device:$channel"

		::CAMGUI::Choose_CancelLinux $w $img
	}

	proc Choose_CancelLinux { w  img } {

		::CAMGUI::CloseGrabber $::CAMGUI::webcam_preview "$w.preview"

		if { [winfo exists .properties_$::CAMGUI::webcam_preview] } {
			eval "[wm protocol .properties_$::CAMGUI::webcam_preview WM_DELETE_WINDOW]"
		}

		image delete $img

		destroy $w
	}

	proc ShowPropertiesPageLinux { capture_fd {img ""} } {

		if { ![::Capture::IsValid $capture_fd] } {
			return
		}

		if { [info exists ::webcam_settings_bug] && $::webcam_settings_bug == 1} {
			return
		}

		set window .properties_$capture_fd
		set slides $window.slides
		set preview $window.preview
		set buttons $window.buttons

		set device ""
		set channel ""

		set grabbers [::Capture::ListGrabbers]
		status_log "Grabbers : $grabbers"
		foreach grabber $grabbers {
			if { [lindex $grabber 0] == $capture_fd } {
				set device [lindex $grabber 1]
				set channel [lindex $grabber 2]
				break
			}
		}

		if { [info exists ::grabbers($capture_fd)] } {
			set windows $::grabbers($capture_fd)
		} else {
			set windows [list]
		}

		lappend windows $window
		set ::grabbers($capture_fd) $windows


		set settings [::config::getKey "webcam$device:$channel" "0:0:0:0"]
		set settings [split $settings ":"]
		set set_b [lindex $settings 0]
		set set_c [lindex $settings 1]
		set set_h [lindex $settings 2]
		set set_co [lindex $settings 3]

		if {[string is integer -strict $set_b]} {
			::Capture::SetBrightness $capture_fd $set_b
		}
		if {[string is integer -strict $set_c]} {
			::Capture::SetContrast $capture_fd $set_c
		}
		if {[string is integer -strict $set_h]} {
			::Capture::SetHue $capture_fd $set_h
		}
		if {[string is integer -strict $set_co]} {
			::Capture::SetColour $capture_fd $set_co
		}


		
		set set_b [::Capture::GetBrightness $capture_fd]
		set set_c [::Capture::GetContrast $capture_fd]
		set set_h [::Capture::GetHue $capture_fd]
		set set_co [::Capture::GetColour $capture_fd]
		

		destroy $window
		toplevel $window
		#grab set $window
		wm title $window "[trans captureproperties]"

		frame $slides
		scale $slides.b -from [::Capture::GetBrightness $capture_fd MIN] -to [::Capture::GetBrightness $capture_fd MAX] -resolution 1 -showvalue 1 -label "[trans brightness]" -command "::CAMGUI::Properties_SetLinux $slides.b b $capture_fd" -orient horizontal
		scale $slides.c -from [::Capture::GetContrast $capture_fd MIN] -to [::Capture::GetContrast $capture_fd MAX] -resolution 1 -showvalue 1 -label "[trans contrast]" -command "::CAMGUI::Properties_SetLinux $slides.c c $capture_fd" -orient horizontal
		scale $slides.h -from [::Capture::GetHue $capture_fd MIN] -to [::Capture::GetHue $capture_fd MAX] -resolution 1 -showvalue 1 -label "[trans hue]" -command "::CAMGUI::Properties_SetLinux $slides.h h $capture_fd" -orient horizontal
		scale $slides.co -from [::Capture::GetColour $capture_fd MIN] -to [::Capture::GetColour $capture_fd MAX] -resolution 1 -showvalue 1 -label "[trans color]" -command "::CAMGUI::Properties_SetLinux $slides.co co $capture_fd" -orient horizontal

		pack $slides.b $slides.c $slides.h $slides.co -expand true -fill x

		frame $buttons -relief sunken -borderwidth 3

		button $buttons.ok -text "[trans ok]" -command [list ::CAMGUI::Properties_OkLinux $window $capture_fd $device $channel]
		button $buttons.cancel -text "[trans cancel]" -command [list ::CAMGUI::Properties_CancelLinux $window $capture_fd $set_b $set_c $set_h $set_co]
		wm protocol $window WM_DELETE_WINDOW [list ::CAMGUI::Properties_CancelLinux $window $capture_fd $set_b $set_c $set_h $set_co]


		pack $buttons.ok $buttons.cancel -side left

		if { $img == "" } {
			set img [image create photo]
		}
		label $preview -image $img

		after 0 "::CAMGUI::PreviewLinux $capture_fd $img"

		pack $slides -fill x -expand true
		pack $preview $buttons -side top

		if {[string is integer -strict $set_b]} {
			$slides.b set $set_b
		}
		if {[string is integer -strict $set_c]} {
			$slides.c set $set_c
		}
		if {[string is integer -strict $set_h]} {
			$slides.h set $set_h
		}
		if {[string is integer -strict $set_co]} {
			$slides.co set $set_co
		}

		return $window

	}

	proc Properties_SetLinux { w property capture_fd new_value } {

		switch $property {
			b {
				::Capture::SetBrightness $capture_fd $new_value
				set val [::Capture::GetBrightness $capture_fd]
				$w set $val
			}
			c {
				::Capture::SetContrast $capture_fd $new_value
				set val [::Capture::GetContrast $capture_fd]
				$w set $val
			}
			h
			{
				::Capture::SetHue $capture_fd $new_value
				set val [::Capture::GetHue $capture_fd]
				$w set $val
			}
			co
			{
				::Capture::SetColour $capture_fd $new_value
				set val [::Capture::GetColour $capture_fd]
				$w set $val
			}
		}

	}

	proc Properties_OkLinux { window capture_fd device channel } {
		if { [::Capture::IsValid $capture_fd] } {
			set brightness [::Capture::GetBrightness $capture_fd]
			set contrast [::Capture::GetContrast $capture_fd]
			set hue [::Capture::GetHue $capture_fd]
			set colour [::Capture::GetColour $capture_fd]
			::config::setKey "webcam$device:$channel" "$brightness:$contrast:$hue:$colour"
		}
		grab release $window
		destroy $window
		::CAMGUI::CloseGrabber $capture_fd $window
	}


	proc Properties_CancelLinux { window capture_fd init_b init_c init_h init_co } {
		if { [::Capture::IsValid $capture_fd] } {
			::Capture::SetBrightness $capture_fd $init_b
			::Capture::SetContrast $capture_fd $init_c
			::Capture::SetHue $capture_fd $init_h
			::Capture::SetColour $capture_fd $init_co
		}
		grab release $window
		destroy $window
		::CAMGUI::CloseGrabber $capture_fd $window
	}


	proc ChooseDeviceWindows { } {

		set window .webcam_chooser
		set lists $window.lists
		set devs $lists.devices
		#set chans $lists.channels
		set buttons $window.buttons
		set status $window.status
		set preview $window.preview
		set settings $window.settings

		if { [winfo exists $window] } {
			raise $window
			return
		}

		toplevel $window

		tkvideo .webcam_preview
		set devices [.webcam_preview devices]


		frame $lists


		frame $devs -relief sunken -borderwidth 3
		label $devs.label -text "[trans devices]"
		listbox $devs.list -yscrollcommand "$devs.ys set" -background \
			white -relief flat -highlightthickness 0 -height 3
		scrollbar $devs.ys -command "$devs.list yview" -highlightthickness 0 \
			-borderwidth 1 -elementborderwidth 2
		pack $devs.label $devs.list -side top -expand false -fill x
		pack $devs.ys -side right -fill y
		pack $devs.list -side left -expand true -fill both


		pack $devs -side left -expand true -fill both

		label $status -text "[trans choosedevice]"

		set img [image create photo]
		label $preview -image $img
		button $settings -text "[trans changevideosettings]" -command "::CAMGUI::Choose_SettingsWindows $devs.list"

		frame $buttons -relief sunken -borderwidth 3
		button $buttons.ok -text "[trans ok]" -command "::CAMGUI::Choose_OkWindows $devs.list $window $img $preview"
		button $buttons.cancel -text "[trans cancel]" -command  "::CAMGUI::Choose_CancelWindows $window $img $preview"
		wm protocol $window WM_DELETE_WINDOW   "::CAMGUI::Choose_CancelWindows $window $img $preview"
		#bind $window <Destroy> "::CAMGUI::Choose_CancelWindows $window $img $preview"
		pack $buttons.ok $buttons.cancel -side left

		pack $lists -side top -expand true -fill both
		pack $status $preview $settings $buttons -side top

		bind $devs.list <Button1-ButtonRelease> "::CAMGUI::StartPreviewWindows $devs.list $status $preview $settings"

		foreach device $devices {

			$devs.list insert end $device
		}

		tkwait window $window
	}

	proc Choose_SettingsWindows { device_w} {
		if { [$device_w curselection] == "" } {
			return
		}
		.webcam_preview propertypage filter
	}

	proc Choose_OkWindows { device_w w img preview} {

		set dev [$device_w curselection]

		if { $dev == "" } {
			::CAMGUI::Choose_CancelWindows $w $img $preview
			return
		}

		::config::setKey "webcamDevice" "$dev"

		::CAMGUI::Choose_CancelWindows $w $img $preview
	}

	proc Choose_CancelWindows { w img preview } {

		destroy .webcam_preview

		image delete $img

		destroy $w
	}

	proc StartPreviewWindows { device_w status preview_w settings } {

		if { [$device_w curselection] == "" } {
			$status configure -text "[trans choosedevice]"
			return
		}

		set img [$preview_w cget -image]
		if {$img == "" } {
			return
		}

		set device [$device_w curselection]
		catch { .webcam_preview stop }
		if { [catch { .webcam_preview configure -source $device } res] } {
			$status configure -text $res
			return
		}
		if { [catch { .webcam_preview start } res] } {
			$status configure -text $res
			return
		}

		after 0 "::CAMGUI::PreviewWindows .webcam_preview $img"

	}

	proc PreviewWindows { grabber img } {
		set semaphore ::CAMGUI::sem_$grabber
		set $semaphore 0

		while { [winfo exists $grabber] && [lsearch [image names] $img] != -1 } {
			catch {$grabber picture $img}
			after 100 "incr $semaphore"
			tkwait variable $semaphore
		}
	}

	proc Play { img filename } {
		
		if { ! [info exists ::webcamsn_loaded] } { ::CAMGUI::ExtensionLoaded }
		if { ! $::webcamsn_loaded } { return }
		
		set semaphore ::${img}_semaphore


		if { [info exists $semaphore] } {
			after 250 "incr $semaphore"
			return
		}

		set $semaphore 0

		set fd [open $filename]
		fconfigure $fd -encoding binary -translation binary
		set data [read $fd]
		close $fd
	
		set decoder [::Webcamsn::NewDecoder]
		
		while { [set size [::MSNCAM::GetCamDataSize $data] ] > 0 } {
		
			if { ![info exists $semaphore] } {
				break
			}
			incr size +24
			if { [catch { ::Webcamsn::Decode $decoder $img $data} res] } {
				status_log "Play : Decode error $res" red
			}
			set data [string range $data $size end]
			after 100 "incr $semaphore"
			tkwait variable $semaphore
		
		}
		::Webcamsn::Close $decoder
		catch {unset $semaphore}
		
	}

	proc Pause { img  } {
		set semaphore ::${img}_semaphore
		
		if { ![info exists $semaphore] } {
			return
		}

		after cancel "incr $semaphore"

	}

	proc Stop { img } {
		set semaphore ::${img}_semaphore
		
		if { ![info exists $semaphore] } {
			return
		}
		after cancel "incr $semaphore"
		catch {unset $semaphore}
		catch {$img blank}
	}	
}





######################################################################################
######################################################################################
#####                                                                            #####
#####      Here begins the code for the (HIG-compliant) webcam-assistant         #####
#####                                                                            #####
######################################################################################
######################################################################################

#Skin-things added:
#* "Yes" emblem
#* "No" emblem
#* Webcam-icon

namespace eval ::CAMSETUP {


	######################################################################################
	#Procedure that starts the assistant.  It creates the window's framework etc         #
	######################################################################################
	proc WebcamAssistant {} {
	
		#set the name of the window
		set win .wcassistantwindow
		
		#if we already have this window openend, raise it and quit this code (as there should only be 1 running)
		if {[winfo exists $win]} {raise $win; return}


		#name the parts of the window
#+-------------------------------+__window
#|+-----------------------------+|
#||+---------------------------+||
#|||        titlef             ||___bodyf
#||+---------------------------+||
#||+---------------------------+||
#|||                           |||
#|||        contentf           |||
#|||                           |||
#||+---------------------------+||
#|+-----------------------------+|
#|+-----------------------------+|
#||         buttonf             ||
#|+-----------------------------+|
#+-------------------------------+		

		set bodyf $win.bodyf
 		  set titlef $bodyf.titleframe
		    set titlec $titlef.canvas
		  set contentf $bodyf.optionsf
		set buttonf $win.buttonframe
		
#make some vars global so they can be used in all the procs:
		set ::CAMSETUP::window $win		
		set ::CAMSETUP::titlec $titlec
		set ::CAMSETUP::contentf $contentf
		set ::CAMSETUP::buttonf $buttonf
		

		#create the window
		toplevel $win
		#set the window's title
		wm title $win "Webcam Setup Assistant"

		#set the window's size
		set winwidth 600
		set winheight 500
		wm geometry $win ${winwidth}x${winheight}
		#make it unpossible to resize the window as this isn't needed, we should make it all fit in the window
#		wm resizable $win 0 0 


		#create and pack the framework		
		frame $bodyf -bd 1  -background [::skin::getKey menuactivebackground]
			#create title frame and first contents
			frame $titlef -height 50 -bd 0 -bg [::skin::getKey menuactivebackground]
			  canvas $titlec -bg [::skin::getKey menuactivebackground] -height 50 ;#TODO: setting for color
			  #set a default text for the title in the canvas that canbe changed
			  $titlec create text 10 25 -text "" -anchor w -fill [::skin::getKey menuactiveforeground] -font bboldf -tag title ;#TODO: setting for color
			  #maybe add a <Configure> if we want the win to be resizable
			  $titlec create image [expr {$winwidth -20}] 25 -image [::skin::loadPixmap webcam] -anchor e
			  pack $titlec -fill x
			pack $titlef -side top -fill x

			#create optionsframe 
			ClearContentFrame
		pack $bodyf -side top -fill both -padx 4 -pady 4 -expand 1

		#open up the first page
		Step0
		
		moveinscreen $win 30
	}


	######################################################################################
	#Procedure that (re)created (clears) the Contentframe                                #
	######################################################################################	
	proc ClearContentFrame {} {
		set frame $::CAMSETUP::contentf
		if {[winfo exists $frame]} {destroy $frame}
		frame $frame -padx 1 -pady 1 ;#-background #ffffff ;#-height 300   ;#these pads make a 1 pixel border
		pack $frame -side top -fill both -expand 1 
		return $frame
	}

	######################################################################################
	#Procedure that (re)created (clears) the Buttonsframe                                #
	######################################################################################
	proc ClearButtonsFrame {} {
		set frame $::CAMSETUP::buttonf
		if {[winfo exists $frame]} {destroy $frame}
		frame $frame  -bd 0 ;#-background #ffffff  ;#bgcolor for debug only
		pack $frame  -side top  -fill x -padx 4 -pady 4 ;#pads keep the stuff a bit away from windowborder
		return $frame
	}


	######################################################################################
	#Procedure that sets the Title in the canvas on top of the window                    #
	######################################################################################	
	proc SetTitlecText { newtext } {
		$::CAMSETUP::titlec itemconfigure title -text $newtext
	}



	################################
	################################
	##                            ##
	##   CODE TO FILL THE PAGES:  ##
	##                            ##
	################################
	################################
	
	######################################################################################
	#Step 0 (intro-page)                                                                 #
	######################################################################################	
	proc Step0 {} {
		status_log "entered step 0 of Webcam-Assistant"

		#Set the title-text
		SetTitlecText "Webcam Setup Assistant"

		#clear the content and optionsframe
		set contentf [ClearContentFrame]
		set buttonf [ClearButtonsFrame]

		#add the buttons
		button $buttonf.back -text "Back" -state disabled
		button $buttonf.next -text "Next" -command "::CAMSETUP::Step1"
		button $buttonf.cancel -text "Close" -command "destroy $::CAMSETUP::window"
		#pack 'm
		pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right
		
		
		#add the Content
		label $contentf.text -justify left -anchor nw -font bplainf -text "This assistant will guide you through the setup of your webcam \nfor aMSN.\n\nIt will check if the required extensions are present and loaded \nand you'll be able to choose the device and channel, set the \npicture settings and resolution."
		#pack it
		pack $contentf.text -padx 20 -pady 20 -side left -fill both -expand 1
				
	}



	######################################################################################
	#Step 1: check for extensions                                                        #
	######################################################################################	
	proc Step1 {} {
		status_log "entered step 1 of Webcam-Assistant"

		#Set the title-text
		SetTitlecText "Check for required extensions (Step 1 of 5)"

		#clear the content and optionsframe
		set contentf [ClearContentFrame]
		set buttonf [ClearButtonsFrame]
		#add the buttons
		button $buttonf.back -text "Back" -command "::CAMSETUP::Step0"
		button $buttonf.next -text "Next" -command "::CAMSETUP::Step2"
		button $buttonf.cancel -text "Close" -command "destroy $::CAMSETUP::window"
		#pack 'm
		pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right		
		
		##Webcam extension check##
		if {[::CAMGUI::ExtensionLoaded]} {
			set ::CAMSETUP::infoarray(wcextloaded) 1
			set wcextpic [::skin::loadPixmap yes-emblem]
		} else {
			set ::CAMSETUP::infoarray(wcextloaded) 0
			set wcextpic [::skin::loadPixmap no-emblem]
		}

		##Capture extension check
		#set the name for the capture extension
		set capextname "grab"
		if { [set ::tcl_platform(platform)] == "windows" } { set capextname "tkvideo"}\
		 elseif { [set ::tcl_platform(os)] == "Darwin" } { set capextname "QuickTimeTcl"}\
		 elseif { [set ::tcl_platform(os)] == "Linux" } { set capextname "capture" }
		
		#check if loaded
		if {[::CAMGUI::CaptureLoaded]} { 
			set ::CAMSETUP::infoarray(capextloaded) 1
			set capextpic [::skin::loadPixmap yes-emblem]	
		} else {
			set ::CAMSETUP::infoarray(capextloaded) 0
			set capextpic [::skin::loadPixmap no-emblem]
		}		

		#maybe we should do better checks like "you can receive but not send if the grabber is unavailable ...
		if { $capextpic == [::skin::loadPixmap no-emblem] ||$wcextpic == [::skin::loadPixmap no-emblem] } {
			$buttonf.next configure -state disabled
		}
		
		
		#pack a frame inside where we put our stuff in so it's away from theedges of the window
		set frame $contentf.innerframe		
		frame $frame -bd 0 
		pack $frame -padx 20 -pady 50

		#create frames for the both lines (I want the emblem on the right)		
		set wcextbox $frame.wcextbox
		set capextbox $frame.capextbox
		frame $wcextbox -bd 0 
		frame $capextbox -bd 0 
		pack $wcextbox $capextbox -side top -padx 10 -pady 10 -fill y
		
		set wcexttext $wcextbox.wcexttext
		set wcextpicl $wcextbox.wcextpicl

		set capexttext $capextbox.capexttext
		set capextpicl $capextbox.capextpicl

		label $wcexttext -justify left -anchor nw -font bboldf -text "Check if webcam extension is loaded ..." ;#-fg $wcexttextcolor
		label $capexttext -justify left -anchor nw -font bboldf -text "Check if '$capextname' extension is loaded ..." ;#-fg $wcexttextcolor
		

		label $wcextpicl -image $wcextpic -bg [::skin::getKey menubackground]
		label $capextpicl -image $capextpic -bg [::skin::getKey menubackground]

		pack $wcexttext -side left -expand 1	
		pack $wcextpicl -side right				
		pack $capexttext -side left
		pack $capextpicl -side right


		
		
	}
	

	######################################################################################
	#Step 2:  Set device/channel                                                         #
	######################################################################################	
	proc Step2 {} {
		status_log "entered step 2 of Webcam-Assistant, or 2&3 for mac"

		#we should be able to alter this vars in other procs
		global chanswidget
		global previmc
		global selecteddevice
		global selectedchannel	
		global channels
		global previmg

		#when running on mac, this will be step 2 and 3 with only 1 button to open the QT prefs
		if { [OnMac] } {
			SetTitlecText "Set up webcamdevice and channel and finetune picture (Step 2 and 3 of 5)"

			#clear the content and optionsframe
			set contentf [ClearContentFrame]
			set buttonf [ClearButtonsFrame]

			#add the buttons
			button $buttonf.back -text "Back" -command "::CAMSETUP::Step1"
			button $buttonf.next -text "Next" -command "::CAMSETUP::Step4"
			button $buttonf.cancel -text "Close" -command "destroy $::CAMSETUP::window"
			#pack 'm
			pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right

			#create the innerframe
			set frame $contentf.innerframe
			frame $frame -bd 0
			pack $frame -padx 10 -pady 10			

			button $frame.button -text "Open camsettings window" -command "::CAMGUI::ChooseDeviceMac"
			pack $frame.button
			
				
		} else {
			#Set the title-text
			SetTitlecText "Set up webcamdevice and channel (Step 2 of 5)"

			#clear the content and optionsframe
			set contentf [ClearContentFrame]
			set buttonf [ClearButtonsFrame]

			#add the buttons
			button $buttonf.back -text "Back" -command "::CAMSETUP::stopPreviewGrabbing; ::CAMSETUP::Step1" ;#save the thing ?
			button $buttonf.next -text "Next" -command "::CAMSETUP::step2_to_step3" ;#needs to save the thing !
			button $buttonf.cancel -text "Close" -command "::CAMSETUP::stopPreviewGrabbing; destroy $::CAMSETUP::window"
			#pack 'm
			pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right


			##Here comes the content:##

			#check if we can capture.  If not, show a message.
			if {!$::CAMSETUP::infoarray(capextloaded)} {

				#TODO: show a message
				#...
				status_log "can't capture, no extension"
			
			} else {
			
				#build the GUI framework (same for windows/linux)
				
# +-------------------------+
# |+----------+ +---------+ |--innerframe ($frame)
# ||          | |         | |
# ||          | |         | |
# ||          | |         |----rightframe (a canvas $rightframe))
# ||          | |         | |
# ||          | |         | |
# ||          |-|---------|----leftframe
# |+----------+ +---------+ |
# +-------------------------+

				#create the innerframe
				set frame $contentf.innerframe
				frame $frame -bd 0
				pack $frame -padx 10 -pady 10 -side left

				#create the left frame (for the comboboxes)
				set leftframe $frame.left
				frame $leftframe -bd 0
				pack $leftframe -side left -padx 10

				#create the 'rightframe' canvas where the preview-image will be shown
				set rightframe $frame.right

                                if { [::config::getKey lowrescam] == 1 } {
                                        set camwidth 160
                                        set camheight 120
                                } else {
                                        set camwidth 320
                                        set camheight 240
                                }

				#this is a canvas so we gcan have a border and put some OSD-like text on it too
				canvas $rightframe -background #000000 -width $camwidth -height $camheight -bd 0
				pack $rightframe -side right -padx 10

				#draw the border image that will be layed ON the preview-img
				$rightframe create image 0 0 -image [::skin::loadPixmap camempty] -anchor nw -tag border
				#give the canvas a clear name
				set previmc $rightframe

				##First "if on unix" (linux -> v4l), then for windows##
				if {[OnUnix]} {

					#first clear the grabber var
					set ::CAMGUI::webcam_preview ""

					#ask the list of devices on the system
					set devices [::Capture::ListDevices]

					#check if we have devices available, if not we're gonne show a msg instead of the 
					# comboboxes
					if { [llength $devices] == 0 } {
						status_log "Webcam-Assistant: No devices available"
						#have some message showing no device and go further with

					#we have minimum 1 device available
					} else {
					
						#First line, device-chooser title
						label $leftframe.devstxt -text "Choose device:"
						pack $leftframe.devstxt -side top
					
						#create and pack the devices-combobox
						combobox::combobox $leftframe.devs -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf -exportselection true -editable false -command "::CAMSETUP::step2_FillChannelsLinux" 

						#make sure the devs-combobox is empty first
						$leftframe.devs list delete 0 end
					
						#get the already set device from the config (if there is one set)
						set setdev [lindex [split [::config::getKey "webcamDevice"] ":"] 0]
						#set the count to see which nr this device has in the list on -1 to begin,
						# so it becomes 0 if it's the first element in the list ([lindex $foo 0])
						set count -1
						#set a start-value for the device's nr
						set setdevnr -1
						
						#insert the device-names in the widget
						foreach device $devices {
status_log "$device"
							set dev [lindex $device 0]
							set name [lindex $device 1]

							#it will allways set the last one, which is a bit weird to the
							# user though if he has like /dev/video0 that come both as V4L 
							# and V4L2 device
							incr count
							#store which nr the setdev has in the combobox
							if { $dev == $setdev} {
								set setdevnr $count
							}
	
							#if we can't get the name, show it the user
							if {$name == "" } {
								#TODO: is this the right cause ?
								set name "$dev (Err: busy?)"
								status_log "Webcam-Assistant: No name found for $dev ... busy ?"
							}
							#put the name of the device in the widget
							$leftframe.devs list insert end $name
						}
						#pack the dev's combobox
						pack $leftframe.devs -side top

						#create and pack the chans-txt
						label $leftframe.chanstxt -text "\n\nChoose channel:"
						pack $leftframe.chanstxt -side top

						#create and pack the chans-combobox
						set chanswidget $leftframe.chans
						combobox::combobox $leftframe.chans -highlightthickness 0 -width 22  -font splainf -exportselection true -command "after 1 ::CAMSETUP::step2_StartPreviewLinux" -editable  false	-bg #FFFFFF
						pack $leftframe.chans -side top 

						#Select the device if in the combobox (won't select anything if -1)
						catch {$leftframe.devs select $setdevnr}
				
					
					#close the "if no devices avaliable / else" statement
					}
					
				#If on windows
				} else {
				
					#TODO ... (tobe continued ... :))
					status_log "we are on windows, in developpement"
										
				
				#End the platform checks
				# we're sure it's win, lin or mac.  maybe a check for unsupported platform on teh 1st page ?
				} 


			#end the "if cap extension not loaded / else" statement
			}			
		#end the "if on mac / else" statement
		}		
	#end the Step2 proc
	}


	######################################################################################
	#Step 2 - Auxilary procs                                                             #
	######################################################################################	

	proc step2_FillChannelsLinux {devswidget value} {
		global chanswidget
		global selecteddevice
		global channels
		
		if { $value == "" } {
			status_log "No device selected; CAN'T BE POSSIBLE ?!?"
		} else {
	
			#get the nr of the selected device
			set devnr [lsearch [$devswidget list get 0 end] $value]
			#get that device out of the list and the first element is the device itself ([list /dev/foo "name"])
			set selecteddevice [lindex [lindex [::Capture::ListDevices] $devnr] 0]

			if { [catch {set channels [::Capture::ListChannels $selecteddevice]} errormsg] } {
				status_log "Webcam-Assistant: Couldn't list chans for device $selecteddevice: $errormsg"
				return
			}

			#make sure the chanswidget is empty before filling it
			$chanswidget list delete 0 end


			#search the already set channel (cfr devices)
			set setchan [lindex [split [::config::getKey "webcamDevice"] ":"] 1]
			set count -1
			set setchannr -1

			foreach channel $channels {
				set chan [lindex $channel 0] ;#this is a nr
				set channame [lindex $channel 1]
				incr count

				if { $chan == $setchan} {
					set setchannr $count
				}

				$chanswidget list insert end $channame
			}
	
			#select the already set chan if possible
			catch {$chanswidget select $setchannr}
			
		}

	}	
	
	
	proc step2_StartPreviewLinux {chanswidget value} {
		global selecteddevice
		global selectedchannel
		global channels
		global previmc
		global previmg
		

#		WcAssistant_stopPreviewGrab
		
	
		if { $value == "" } {
			status_log "No channel selected; IS THIS POSSIBLE ?"
		} else {

			#get the nr of the selected channel
			set channr [lsearch [$chanswidget list get 0 end] $value]
			#get that channel out of the list and the first element is the chan itself ([list 0 "television"])
			set selectedchannel [lindex [lindex $channels $channr] 0]
			status_log "Will preview: $selecteddevice on channel $selectedchannel"

			
			#close the device if open
			if { [::Capture::IsValid $::CAMGUI::webcam_preview] } {
				::Capture::Close $::CAMGUI::webcam_preview
			}

			if { [catch {set ::CAMGUI::webcam_preview [::Capture::Open $selecteddevice $selectedchannel]} errormsg] } {
				status_log "problem opening device: $errormsg"
				return
			}

			set previmg [image create photo]

					
			$previmc create image 0 0 -image $previmg -anchor nw 

			$previmc create text 10 10 -anchor nw -font bboldf -text "Preview $selecteddevice:$selectedchannel" -fill #FFFFFF -anchor nw -tag device


			after 2000 "catch { $previmc delete device }"

			#put the border-pic on top
			$previmc raise border
			setPic $::CAMGUI::webcam_preview
			
			set semaphore ::CAMGUI::sem_$::CAMGUI::webcam_preview
			set $semaphore 0
			if { [::config::getKey lowrescam] == 1 } {
				set cam_res "LOW"
			} else {
				set cam_res "HIGH"
			}
			while { [::Capture::IsValid $::CAMGUI::webcam_preview] && [lsearch [image names] $previmg] != -1 } {
				if {[catch {::Capture::Grab $::CAMGUI::webcam_preview $previmg $cam_res} res ]} {
					status_log "Problem grabbing from the device:\n\t \"$res\""
					$previmc create text 10 215 -anchor nw -font bboldf -text "ERROR: $res" -fill #FFFFFF -anchor nw -tag errmsg
				after 2000 "catch { $previmc delete errmsg }"
					
				}
				after 100 "incr $semaphore"
				tkwait variable $semaphore
			}
			
		
		}
	
	
	}
	###proc to stop the grabber###
	proc stopPreviewGrabbing {} {
		global previmg
		
		if { [info exists ::CAMGUI::webcam_preview]} {
			if { [::Capture::IsValid $::CAMGUI::webcam_preview] } {
				::Capture::Close $::CAMGUI::webcam_preview
			}
		}
		catch {image delete $previmg}
		status_log "Webcam-Assistant: Stopped grabbing"
	}
	#proc to store the values when we go from step 2 to step 3
	proc step2_to_step3 {} {
		global selecteddevice
		global selectedchannel

		stopPreviewGrabbing
		

		#save settings
		::config::setKey "webcamDevice" "$selecteddevice:$selectedchannel"
		
		Step3
	}
	
	
	#proc to set the picture settings
	proc setPic { grabber } {
		global selecteddevice
		global selectedchannel

		global brightness
		global contrast
		global hue
		global color

		
		#First set the values to the one the cam is on when we start preview
		set brightness [::Capture::GetBrightness $grabber]
		set contrast [::Capture::GetContrast $grabber]	
		set hue [::Capture::GetHue $grabber]	
		set color [::Capture::GetColour $grabber]	


		#Then, if there are valid settings in our config, overwrite the values with these
		set colorsettings [split [::config::getKey "webcam$selecteddevice:$selectedchannel"] ":"]
		set set_b [lindex $colorsettings 0]
		set set_c [lindex $colorsettings 1]
		set set_h [lindex $colorsettings 2]
		set set_co [lindex $colorsettings 3]
		
		if {[string is integer -strict $set_b]} {
				set brightness $set_b
		}
		if {[string is integer -strict $set_c]} {
				set contrast $set_c
		}
		if {[string is integer -strict $set_h]} {
				set hue $set_h
		}
		if {[string is integer -strict $set_co]} {
				set color $set_co
		}
		
		#Set 'm	
		::Capture::SetBrightness $grabber $brightness
		::Capture::SetContrast $grabber $contrast
		::Capture::SetHue $grabber $hue
		::Capture::SetColour $grabber $color		
	}


	######################################################################################
	#Step 3:  Finetune picture settings                                                  #
	######################################################################################	

	proc Step3 {} {
	
		if {[OnMac]} {
			::CAMSETUP::Step2
			return
		}
#Only linux for now ...
		global selecteddevice
		global selectedchannel
		
		global brightness
		global contrast
		global hue
		global color
		
		
		status_log "entered step 3 of Webcam-Assistant"

		#Set the title-text
		SetTitlecText "Finetune picture settings (Step 3 of 5)"
		#clear the content and optionsframe
		set contentf [ClearContentFrame]
		set buttonf [ClearButtonsFrame]

		#add the buttons
		button $buttonf.back -text "Back" -command "::CAMSETUP::stopPreviewGrabbing; ::CAMSETUP::Step2" ;#save the thing ?
		button $buttonf.next -text "Next" -command "::CAMSETUP::step3_to_step4 $::CAMGUI::webcam_preview" ;#needs to save the thing !
		button $buttonf.cancel -text "Close" -command "::CAMSETUP::stopPreviewGrabbing; destroy $::CAMSETUP::window"
		#pack 'm
		pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right


		#create the innerframe
		set frame $contentf.innerframe
		frame $frame -bd 0
		pack $frame -padx 10 -pady 10 -side left
		#create the left frame (for the comboboxes)
		set leftframe $frame.left
		#frame $leftframe -bd 0
		#pack $leftframe -side left -padx 10

               if { [::config::getKey lowrescam] == 1 } {
                        set camwidth 160
			set camheight 120
                } else {
                        set camwidth 320
			set camheight 240
                }


		#create the 'rightframe' canvas where the preview-image will be shown
		set rightframe $frame.right
		#this is a canvas so we gcan have a border and put some OSD-like text on it too
		canvas $rightframe -background #000000 -width $camwidth -height $camheight -bd 0
		pack $rightframe -side right -padx 10

		#draw the border image that will be layed ON the preview-img
		$rightframe create image 0 0 -image [::skin::loadPixmap camempty] -anchor nw -tag border
		#give the canvas a clear name
		set previmc $rightframe



		#close the device if open
		if { [::Capture::IsValid $::CAMGUI::webcam_preview] } {
			::Capture::Close $::CAMGUI::webcam_preview
		}

		if { [catch {set ::CAMGUI::webcam_preview [::Capture::Open $selecteddevice $selectedchannel]} errormsg] } {
			status_log "problem opening device: $errormsg"
			return
		}

		set previmg [image create photo]

					
		$previmc create image 0 0 -image $previmg -anchor nw 
		$previmc create text 10 10 -anchor nw -font bboldf -text "Preview $selecteddevice:$selectedchannel" -fill #FFFFFF -anchor nw -tag device


		after 2000 "catch { $previmc delete device }"

		#put the border-pic on top
		$previmc raise border


		#First set the values to the one the cam is on when we start preview
		set brightness [::Capture::GetBrightness $::CAMGUI::webcam_preview]
		set contrast [::Capture::GetContrast $::CAMGUI::webcam_preview]	
		set hue [::Capture::GetHue $::CAMGUI::webcam_preview]	
		set color [::Capture::GetColour $::CAMGUI::webcam_preview]	
status_log "Device: $brightness, $contrast, $hue, $color"


		#Then, if there are valid settings in our config, overwrite the values with these
		set colorsettings [split [::config::getKey "webcam$selecteddevice:$selectedchannel"] ":"]
		set set_b [lindex $colorsettings 0]
		set set_c [lindex $colorsettings 1]
		set set_h [lindex $colorsettings 2]
		set set_co [lindex $colorsettings 3]
		
		if {[string is integer -strict $set_b]} {
				set brightness $set_b
		}
		if {[string is integer -strict $set_c]} {
				set contrast $set_c
		}
		if {[string is integer -strict $set_h]} {
				set hue $set_h
		}
		if {[string is integer -strict $set_co]} {
				set color $set_co
		}
status_log "Config'ed: $brightness, $contrast, $hue, $color"


		set slides $leftframe
		frame $slides
		scale $slides.b -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Brightness" -command "::CAMSETUP::Properties_SetLinux $slides.b b $::CAMGUI::webcam_preview" -orient horizontal
		scale $slides.c -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Contrast" -command "::CAMSETUP::Properties_SetLinux $slides.c c $::CAMGUI::webcam_preview" -orient horizontal
		scale $slides.h -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Hue" -command "::CAMSETUP::Properties_SetLinux $slides.h h $::CAMGUI::webcam_preview" -orient horizontal
		scale $slides.co -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Colour" -command "::CAMSETUP::Properties_SetLinux $slides.co co $::CAMGUI::webcam_preview" -orient horizontal

		pack $slides.b $slides.c $slides.h $slides.co -expand true -fill x
		pack $leftframe -side right -padx 10

		#set the sliders right
		Properties_SetLinux $slides.b b $::CAMGUI::webcam_preview $brightness
		Properties_SetLinux $slides.c c $::CAMGUI::webcam_preview $contrast
		Properties_SetLinux $slides.h h $::CAMGUI::webcam_preview $hue
		Properties_SetLinux $slides.co co $::CAMGUI::webcam_preview $color



			
			set semaphore ::CAMGUI::sem_$::CAMGUI::webcam_preview
			set $semaphore 0
			while { [::Capture::IsValid $::CAMGUI::webcam_preview] && [lsearch [image names] $previmg] != -1 } {
				if {[catch {::Capture::Grab $::CAMGUI::webcam_preview $previmg $cam_res} res ]} {
					status_log "Problem grabbing from the device:\n\t \"$res\""
					$previmc create text 10 215 -anchor nw -font bboldf -text "ERROR: $res" -fill #FFFFFF -anchor nw -tag errmsg
					after 2000 "catch { $previmc delete errmsg }"				
					
				}
				after 100 "incr $semaphore"
				tkwait variable $semaphore
			}

#TODO: Add a key-combo to reread the device settings and set these and go to next step (to adjust to settings of other programs)

	}

	######################################################################################
	#Step 3 - Auxilary procs                                                             #
	######################################################################################	
	proc Properties_SetLinux { w property capture_fd new_value } {
		global selecteddevice
		global selectedchannel
		
		global brightness
		global contrast
		global hue
		global color		


#		set b [::Capture::GetBrightness $capture_fd]
#		set c [::Capture::GetContrast $capture_fd]
#		set h [::Capture::GetHue $capture_fd]
#		set co [::Capture::GetColour $capture_fd]

		
		switch $property {
			b {
				::Capture::SetBrightness $capture_fd $new_value
				set brightness [::Capture::GetBrightness $capture_fd]
				$w set $brightness
			}
			c {
				::Capture::SetContrast $capture_fd $new_value
				set contrast [::Capture::GetContrast $capture_fd]
				$w set $contrast
			}
			h
			{
				::Capture::SetHue $capture_fd $new_value
				set hue [::Capture::GetHue $capture_fd]
				$w set $hue
			}
			co
			{
				::Capture::SetColour $capture_fd $new_value
				set color [::Capture::GetColour $capture_fd]
				$w set $color
			}
		}
#	::config::setKey "webcam$selecteddevice:$selectedchannel" "$b:$c:$h:$co"

	}
	#proc to store the values when we go from step 2 to step 3
	proc step3_to_step4 {grabber} {
		global selecteddevice
		global selectedchannel

		global brightness
		global contrast
		global hue
		global color

		#save settings
		::config::setKey "webcam$selecteddevice:$selectedchannel" "$brightness:$contrast:$hue:$color"

		stopPreviewGrabbing
		
		
		Step4
	}	

	
	
	
	######################################################################################
	#Step 4:  Network stuff                                                              #
	######################################################################################		
	proc Step4 {} {
#Step 4
		status_log "entered step 4 of Webcam-Assistant"

		#Set the title-text
		SetTitlecText "Network settings (Step 4 of 5)"
		#clear the content and optionsframe
		set contentf [ClearContentFrame]
		set buttonf [ClearButtonsFrame]

		#add the buttons
		button $buttonf.back -text "Back" -command "::CAMSETUP::Step3"
		button $buttonf.next -text "Next" -command "::CAMSETUP::Step5" ;#needs to save the thing !
		button $buttonf.cancel -text "Close" -command "destroy $::CAMSETUP::window"
		#pack 'm
		pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right


		#create the innerframe
		set frame $contentf.innerframe
		frame $frame -bd 0
		pack $frame -padx 10 -pady 10

		if {[::abook::getDemographicField conntype] == "IP-Restrict-NAT" && [::abook::getDemographicField listening] == "false"} {
			label $frame.abookresult -text "[trans firewalled]" -font bboldf
		} else {
			label $frame.abookresult -text "[trans portswellconfigured]" -font bboldf
		}
		
		pack $frame.abookresult

}



	######################################################################################
	#Step 5:  Congrats                                                                   #
	######################################################################################		
	proc Step5 {} {
#Step 4
		status_log "entered step 5 of Webcam-Assistant"

		#Set the title-text
		SetTitlecText "Done (Step 5 of 5)"
		#clear the content and optionsframe
		set contentf [ClearContentFrame]
		set buttonf [ClearButtonsFrame]

		#add the buttons
		button $buttonf.back -text "Back" -command "::CAMSETUP::Step4"
		button $buttonf.next -text "Done" -command "destroy $::CAMSETUP::window"
		button $buttonf.cancel -text "Close" -command "destroy $::CAMSETUP::window"
		#pack 'm
		pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right


		#create the innerframe
		set frame $contentf.innerframe
		frame $frame -bd 0
		pack $frame -padx 10 -pady 10


		label $frame.txt -text "Done" -font bboldf

		
		pack $frame.txt

}



#Close the ::CAMSETUP namespace
}
if { [::config::getKey wanttosharecam] && [::CAMGUI::camPresent] == 1 } {
	::MSN::setClientCap webcam
}

