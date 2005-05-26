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
		}

		set listening [getObjOption $sid listening_socket]
		if { $listening != "" } {
			close $listening
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

		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"


		status_log "Canceling webcam $sid with $chatid \n" red
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] $branchid 0 $callid 0 1 "dAMAgQ==\r\n"] 1]

		if { $socket != "" } {
			status_log "Connected through socket $socket : closing socket\n" red
			catch { close $socket}
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
	# This function is called when a file transfer is accepted by the user
	proc AcceptWebcam { chatid dest branchuid cseq uid sid producer} {

		setObjOption $sid producer $producer
		setObjOption $sid inviter 0
		setObjOption $sid chatid $chatid

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

		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

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

	proc AskWebcam { chatid } {
		SendInvite $chatid "1C9AA97E-9C05-4583-A3BD-908A196F1E92"
	}
	#SendInvite queue, open connection before sending invitation
	proc SendInviteQueue {chatid} {
		::MSN::ChatQueue $chatid [list ::MSNCAM::SendInvite $chatid]
	}
	proc SendInvite { chatid {guid "4BD96FC0-AB17-4425-A14A-439185962DC8"}} {

		status_log "Sending Webcam Request\n"

		set sid [expr int([expr rand() * 1000000000])%125000000 + 4]
		# Generate BranchID and CallID
		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

		set dest [lindex [::MSN::usersInChat $chatid] 0]


		# This is a fixed value... it must be that way or the invite won't work
		set context [ToUnicode "\{B8BE70DE-E2CA-4400-AE03-88FF85B9F4E8\}"]

		::MSNP2P::SessionList set $sid [list 0 0 0 $dest 0 $callid 0 "webcam" "$context" "$branchid"]

		setObjOption $sid inviter 1
		setObjOption $sid chatid $chatid
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

		setObjOption $sock sid $sid
		setObjOption $sock server 1
		setObjOption $sock state "AUTH"

		status_log "Received connection from $ip on port $port - socket $sock\n" red
		fconfigure $sock -blocking 1 -buffering none -translation {binary binary}

		set connected_ips [getObjOption $sid connected_ips]
		lappend connected_ips [list $ip $port $sock]
		setObjOption $sid connected_ips $connected_ips

		if { [getObjOption $sid socket] == "" } {
			#setObjOption $sid socket $sock
			fileevent $sock readable "::MSNCAM::ReadFromSock $sock"
		}

	}



	proc connectMsnCam { sid ip port } {


		if { [catch {set sock [socket -async $ip $port] } ] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red
			return 0
		} else {

			setObjOption $sock sid $sid
			setObjOption $sock server 0
			setObjOption $sock state "AUTH"

			status_log "connectedto $ip on port $port  - $sock\n" red

			return $sock
		}
	}


	proc ReadFromSock { sock } {
		fileevent $sock readable ""


		set sid [getObjOption $sock sid]

		set producer [getObjOption $sid producer]
		set server [getObjOption $sock server]
		set state [getObjOption $sock state]

		set my_rid [getObjOption $sid my_rid]
		set rid [getObjOption $sid rid]
		set session [getObjOption $sid session]


		fileevent $sock readable "::MSNCAM::ReadFromSock $sock"


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
					gets $sock data
					status_log "Received Data on socket $sock $my_rid - $rid server=$server - state=$state : \n$data\n" red
					if { $data == "recipientid=${my_rid}&sessionid=${session}\r" } {
						gets $sock
						setObjOption $sock state "CONNECTED"
						fileevent $sock writable "::MSNCAM::WriteToSock $sock"
						setObjOption $sid socket $sock
						CloseUnusedSockets $sid $sock
					} else {
						AuthFailed $sid $sock
					}
				}
			}
			"CONNECTED"
			{
				if { $server == 0 } {
					gets $sock data
					status_log "Received Data on socket $sock sending=$producer - server=$server - state=$state : \n$data\n" red
					if { $data == "connected\r" } {
						gets $sock
						setObjOption $sid socket $sock
						CloseUnusedSockets $sid $sock
						puts -nonewline $sock "connected\r\n\r\n"
						status_log "Sending \"connected\" to the server\n" red
						if { $producer } {
							setObjOption $sock state "SEND"
							fileevent $sock writable "::MSNCAM::WriteToSock $sock"
							AuthSuccessfull $sid $sock
						} else {
							setObjOption $sock state "RECEIVE"
							AuthSuccessfull $sid $sock
						}
					} else {
						status_log "ERROR2 : $data - [eof $sock] - [gets $sock] - [gets $sock]\n" red
						AuthFailed $sid $sock
					}
				}
			}
			"SEND" -
			"CONNECTED2"
			{
				if {$server} {

					set data [read $sock 13]
					status_log "Received Data on socket $sock sending=$producer - server=$server - state=$state : \n$data\n" red

					if { $data == "connected\r\n\r\n" } {
						setObjOption $sid socket $sock
						if { $producer == 0} {
							setObjOption $sock state "RECEIVE"
						}
					} elseif { $producer == 0 } {
						set header "${data}[read $sock 11]"
						setObjOption $sock state "RECEIVE"

						set size [GetCamDataSize $header]
						if { $size > 0 } {
							set data "$header[read $sock $size]"
							::CAMGUI::ShowCamFrame $sid $data
						} else {
							setObjOption $sock state "END"
							status_log "ERROR1 : $data - invalid data received" red
						}

					} else {
						setObjOption $sock state "END"
						status_log "ERROR1 : $data - [eof $sock] - [gets $sock] - [gets $sock]\n" red
					}

				} else {
					setObjOption $sock state "END"
					status_log "ERROR1 : $data - should never received data on state $state when we're the client\n" red
				}
			}

			"RECEIVE"
			{
				set header [read $sock 24]
				set size [GetCamDataSize $header]
				if { $size > 0 } {
					set data "$header[read $sock $size]"
					if { [::config::getKey webcamlogs] == 1 } {
						set fd [getObjOption $sid weblog]
						if { $fd == "" } {
							set email [lindex [::MSNP2P::SessionList get $sid] 3]
							set fd [open [file join $::webcam_dir ${email}.cam] a]
							fconfigure $fd -encoding binary -translation binary
							setObjOption $sid weblog $fd
						}
					
						catch {puts -nonewline $fd $data}
					}

					::CAMGUI::ShowCamFrame $sid $data
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
				#close $sock
				CancelCam $chatid $sid

			}
			default
			{
				status_log "option $state of socket $sock : [getObjOption $sock state] not defined.. receiving data [gets $sock]... closing \n" red
				setObjOption $sock state "END"
				close $sock
			}

		}

		#puts  "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n"
		#status_log "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" red



	}
	proc WriteToSock { sock } {

		fileevent $sock writable ""


		set sid [getObjOption $sock sid]

		set sending [getObjOption $sock sending]
		set server [getObjOption $sock server]
		set state [getObjOption $sock state]
		set producer [getObjOption $sid producer]

		set rid [getObjOption $sid rid]
		set session [getObjOption $sid session]


		# Uncomment next line to test for failed authentifications...
		#set session 0

		if { [fconfigure $sock -error] != "" } {
			status_log "ERROR writing to socket!!! : [fconfigure $sock -error]" red
			close $sock
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
			"CONNECTED"
			{
				set data "connected\r\n\r\n"
				if { $producer } {
					setObjOption $sock state "SEND"
					fileevent $sock writable "::MSNCAM::WriteToSock $sock"
					AuthSuccessfull $sid $sock
				} else {
					setObjOption $sock state "CONNECTED2"
					AuthSuccessfull $sid $sock
				}
			}
			"SEND"
			{
				after 100 "::CAMGUI::GetCamFrame $sid $sock"
				#fileevent $sock writable "::MSNCAM::WriteToSock $sock"
			}
			"END"
			{
				set chatid [getObjOption $sid chatid]
				status_log "Closing socket $sock because it's in END state\n" red
				#close $sock
				CancelCam $chatid $sid
			}

		}

		if { $data != "" } {
			status_log "Writing Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" red
			puts -nonewline $sock "$data"
		}



	}

	proc CloseSocket { sock } {

		set sid [getObjOption $sock sid]

		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]

		set bheader [binary format ii 0 $MsgId][binword 0][binword 0][binary format iiii 0 4 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]

		puts -nonewline $sock "[binary format i 48]$bheader"
		status_log "Closing socket... \n" red
		close $sock

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


		if {$listening == "true" } {
			set port [OpenCamPort [config::getKey initialftport] $sid]
			set clientip [::abook::getDemographicField clientip]
			set localip [::abook::getDemographicField localip]
		} else {
			set port ""
			set clientip ""
			set localip ""
		}

		if { $producer } {
			set begin_type "<producer>"
			set end_type "</producer>"
		} else {
			set begin_type "<viewer>"
			set end_type "</viewer>"
		}

		set header "<version>2.0</version><rid>$rid</rid><session>$session</session><ctypes>0</ctypes><cpu>730</cpu>"
		set tcp "<tcp><tcpport>$port</tcpport>								<tcplocalport>$port</tcplocalport>								<tcpexternalport>$port</tcpexternalport><tcpipaddress1>$localip</tcpipaddress1>"
		if { $clientip != $localip} {
			set tcp "${tcp}<tcpipaddress2>$clientip</tcpipaddress2></tcp>"
		} else {
			set tcp "${tcp}</tcp>"
		}

		set udp "<udp><udplocalport>0</udplocalport><udpexternalport>0</udpexternalport><udpexternalip>$clientip</udpexternalip><a1_port>$port</a1_port><b1_port>$port</b1_port><b2_port>$port</b2_port><b3_port>$port</b3_port><symmetricallocation>0</symmetricallocation><symmetricallocationincrement>0</symmetricallocationincrement><udpinternalipaddress1>$localip</udpinternalipaddress1></udp>"
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

		set session [GetXmlEntry $list "session"]
		set rid [GetXmlEntry $list "rid"]


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
		if { $ips == "" } {
			set ips [list]
		}


		while { 1 } {
			if { $ip_idx == 7 } {
				set ip [GetXmlEntry $list "tcpexternalip"]
			} elseif { $ip_idx == 6 } {
				set ip [GetXmlEntry $list "udpexternalip"]
			} elseif {$ip_idx > 0 } {
				set ip [GetXmlEntry $list "tcpipaddress${ip_idx}"]
			} else {
				break
			}


			if {$ip != "" } {
				foreach port_idx { tcpport tcplocalport tcpexternalport } {
					set port [GetXmlEntry $list "${port_idx}"]
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

			catch {fconfigure $sock -blocking 1 -buffering none -translation {binary binary} }
			fileevent $sock readable "::MSNCAM::CheckConnected $sid $sock "
			fileevent $sock writable "::MSNCAM::CheckConnected $sid $sock "
		}

		after 5000 "::MSNCAM::CheckConnectSuccess $sid"

	}

	proc CheckConnectSuccess { sid } {
		set ips [getObjOption $sid ips]
		set connected_ips [getObjOption $sid connected_ips]
		status_log "we have $ips connecting sockets and $connected_ips connected sockets\n" red
		if { [llength $ips] == 0 && [llength $connected_ips] == 0
		     && [getObjOption $sid canceled] != 1} {
			status_log "No socket was connected\n" red
			::MSNCAM::CancelCam [getObjOption $sid chatid] $sid
		}
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

		close $socket
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
			status_log "invalid - $h_size" red
			return -1
		}
		if { $fcc != $r_fcc} {
			status_log "fcc invalide - $fcc - $r_fcc" red
			return -1
		}
		#status_log "resolution : $w x $h - $h_size $p_size \n" red

		return $p_size

	}

	proc SendFrame { sock encoder img } {
		#If the img is not at the right size, don't encode (crash issue..)
		if { [image width $img] != "320" || [image height $img] != "240" } {
			#status_log "webcam: Wrong size: Width is [image width $img] and height is [image height $img]\n" red
			#return
			
			#We crop the image to avoid bad sizes
			#This is a test..seems to work well for bad-sized ratio camera
			if { [image width $img] != "0" || [image height $img] != "0" } {
				$img configure -width 320 -height 240
			} else {
				return
			}
			
		}
		if { [catch {set data [::Webcamsn::Encode $encoder $img]} res] } {
			status_log "Error encoding frame : $res\n"
		    return
		} else {
			set header "[binary format ssssi 24 [::Webcamsn::GetWidth $encoder] [::Webcamsn::GetHeight $encoder] 0 [string length $data]]"
			set header "${header}\x4D\x4C\x32\x30\x00\x00\x00\x00\x00\x00\x00\x00"

			set data "${header}${data}"
		}
		catch {
		    if { ![eof $sock] && [fconfigure $sock -error] == "" } {
			puts -nonewline $sock "$data"
		    }
		}

	}




}

namespace eval ::CAMGUI {

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
			wm protocol $window WM_DELETE_WINDOW "::MSNCAM::CancelCam $chatid $sid"
			set img [image create photo]
			label $window.l -image $img
			pack $window.l
			button $window.q -command "::MSNCAM::CancelCam $chatid $sid" -text "Stop receiving Webcam"
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

		if { $encoder == "" } {
			set encoder [::Webcamsn::NewEncoder HIGH]
			setObjOption $socket codec $encoder
		}

		if { ![::CAMGUI::IsGrabberValid $grabber] } {
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
					return
				}
				setObjOption $sid grab_proc "Grab_Mac"

			} elseif { [set ::tcl_platform(os)] == "Linux" } {
				set pos [string last ":" $source]
				set dev [string range $source 0 [expr $pos-1]]
				set channel [string range $source [expr $pos+1] end]

				set grabber [::Capture::Open $dev $channel]

				set init_b [::Capture::GetBrightness $grabber]
				set init_c [::Capture::GetContrast $grabber]
				set init_h [::Capture::GetHue $grabber]
				set init_co [::Capture::GetColour $grabber]

				set settings [::config::getKey "webcam$dev:$channel" "$init_b:$init_c:$init_h:$init_co"]
				set settings [split $settings ":"]
				set init_b [lindex $settings 0]
				set init_c [lindex $settings 1]
				set init_h [lindex $settings 2]
				set init_co [lindex $settings 3]

				::Capture::SetBrightness $grabber $init_b
				::Capture::SetContrast $grabber $init_c
				::Capture::SetHue $grabber $init_h
				::Capture::SetColour $grabber $init_co

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
						label $w.label -text "List of people you are currently sending webcam\nClick to cancel"
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

				label $window.l -image $img
				pack $window.l
				button $window.settings -command "::CAMGUI::ShowPropertiesPage $grabber $img" -text "Show properties page"
				pack $window.settings -expand true -fill x
				button $window.q -command "::MSNCAM::CancelCam $chatid $sid" -text "Stop sending Webcam"
				pack $window.q -expand true -fill x
				wm protocol $window WM_DELETE_WINDOW "::MSNCAM::CancelCam $chatid $sid"
			}
			set windows $::grabbers($grabber)
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
		if { ![catch { $grabber picture $img} res] } {
			::MSNCAM::SendFrame $socket $encoder $img
		} else {
		    status_log "error grabbing : $res\n" red
		}
	    catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
	}

	proc Grab_Linux {grabber socket encoder img} {
		if { ![catch { ::Capture::Grab $grabber $img} res] } {
			::MSNCAM::SendFrame $socket $encoder $img
		} else {
		    status_log "error grabbing : $res\n" red
		}
	    catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
	}

	proc Grab_Mac { grabber socket encoder img } {
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

		catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}

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
	
		#Add grabber to the window
		#Show message error if it's not possible
		if { ![catch {seqgrabber $w.seq -width 320} res] } {
			
			catch {$w.seq configure -volume 0}
			pack $w.seq
					
			#Add button to change settings
			button $w.settings -command "::CAMGUI::ChooseDeviceMac" -text "Change video settings"
			pack $w.settings
			
			#Add zoom option
			label $w.zoomtext -text "[trans zoom]:" -font sboldf
			spinbox $w.zoom -from 1 -to 5 -increment 0.5 -width 2 -command "$w.seq configure -zoom %s"
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
			msg_box "You have to cancel all webcam sessions before closing the window"
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
			return
		}

		if { [catch {package require $extension}] } {
			set ::capture_loaded 0
			return 0
		} else {
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

	#Executed when you invite someone to a webcam session and he refuses the request
	proc InvitationDeclined {chatid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid butwebcam 3 2
		::amsn::WinWrite $chatid "[timestamp] [::abook::getDisplayNick $chatid] rejected invitation for webcam session\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	#Executed when your contact stops the webcam session
	proc CamCanceled {chatid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid butwebcam 3 2
		::amsn::WinWrite $chatid "[timestamp] The webcam session with [::abook::getDisplayNick $chatid] has been canceled\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	#Executed when you invite someone to send your webcam
	proc InvitationToSendSent {chatid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid butwebcam 3 2
		::amsn::WinWrite $chatid "[timestamp] Send request to send webcam\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	#Executed when you invite someone to receive his webcam
	proc InvitationToReceiveSent {chatid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid butwebcam 3 2
		::amsn::WinWrite $chatid "[timestamp] Send request to receive webcam\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	
	proc WebcamWizard {} {
	
		set w .webcamwizard
		if {[winfo exists $w]} {
			raise $w
			return 1
		}
		toplevel $w
		
		label $w.webcampic -image [::skin::loadPixmap butwebcam]
		pack $w.webcampic
		
		frame $w.abooktype
		label $w.abooktype.text -text "Type" -font sboldf
		label $w.abooktype.abook -text [::abook::getDemographicField conntype]
		frame $w.abooklistening
		label $w.abooklistening.text -text "Listening" -font sboldf
		label $w.abooklistening.abook -text [::abook::getDemographicField listening]
		
		pack $w.abooktype.text  -padx 5 -side left
		pack $w.abooktype.abook -padx 5 -side right
		pack $w.abooktype -expand true
		pack $w.abooklistening.text -padx 5 -side left
		pack $w.abooklistening.abook -padx 5 -side right
		pack $w.abooklistening -expand true
		
		if {[::abook::getDemographicField conntype] == "IP-Restrict-NAT" && [::abook::getDemographicField listening] == "false"} {
			label $w.abookresult -text "You are firewalled or behind a router" -font sboldf -foreground red
		} else {
			label $w.abookresult -text "Your ports are well configured" -font sboldf
		}
		pack $w.abookresult -expand true -padx 5
		
		if {[::CAMGUI::ExtensionLoaded]} {
			label $w.webcamsn -text "Webcamsn extension is loaded" -font sboldf
		} else {
			label $w.webcamsn -text "Webcamsn extension is not loaded. You have to compile it." -font sboldf -foreground red
		}
		pack $w.webcamsn -expand true -padx 5
		
		if { [set ::tcl_platform(platform)] == "windows" } {
			set extension "tkvideo"
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			set extension "QuickTimeTcl"
		} elseif { [set ::tcl_platform(os)] == "Linux" } {
			set extension "capture"
		} else {
			set extension "Unknown"
		}
		
		
		if {[::CAMGUI::CaptureLoaded]} {
			label $w.capture -text "Capture extension -$extension- is loaded" -font sboldf
		} else {
			label $w.capture -text "Capture extension -$extension- is not loaded, you have to compile it" -font sboldf -foreground red
		}
		pack $w.capture -expand true -padx 5
		
		#Add button to change settings
		button $w.settings -command "::CAMGUI::ChooseDevice" -text "Change video settings"
		pack $w.settings
		set link "http://amsn.sourceforge.net/wiki/tiki-index.php?page=Webcam+In+aMSN"
		button $w.wiki -command "launch_browser $link" -text "FAQ/Help for Webcam"
		pack $w.wiki
		
		#wm geometry $w 300x150
		
		moveinscreen $w 30
		
	
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
		$grabber videosettings
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
		set devices [::Capture::ListDevices]

		if { [llength $devices] == 0 } {
			tk_messageBox -message "You haven't devices installed"
			return
		}

		destroy $window
		toplevel $window


		frame $lists


		frame $devs -relief sunken -borderwidth 3
		label $devs.label -text "Devices"
		listbox $devs.list -yscrollcommand "$devs.ys set" -background \
		white -relief flat -highlightthickness 0 -height 5
		scrollbar $devs.ys -command "$devs.list yview" -highlightthickness 0 \
		-borderwidth 1 -elementborderwidth 2
		pack $devs.label $devs.list -side top -expand false -fill x
		pack $devs.ys -side right -fill y
		pack $devs.list -side left -expand true -fill both


		frame $chans -relief sunken -borderwidth 3
		label $chans.label -text "Channels"
		listbox $chans.list -yscrollcommand "$chans.ys set"  -background \
		white -relief flat -highlightthickness 0 -height 5 -selectmode extended
		scrollbar $chans.ys -command "$chans.list yview" -highlightthickness 0 \
		-borderwidth 1 -elementborderwidth 2
		pack $chans.label $chans.list -side top -expand false -fill x
		pack $chans.ys -side right -fill y
		pack $chans.list -side left -expand true -fill both

		pack $devs $chans -side left

		label $status -text "Please choose a device"

		set img [image create photo]
		label $preview -image $img
		button $settings -text "Camera Settings"

		frame $buttons -relief sunken -borderwidth 3
		button $buttons.ok -text "Ok" -command "::CAMGUI::Choose_OkLinux $window $devs.list $chans.list $img $devices"
		button $buttons.cancel -text "Cancel" -command "::CAMGUI::Choose_CancelLinux $window $img"
		wm protocol $window WM_DELETE_WINDOW "::CAMGUI::Choose_CancelLinux $window $img"
		#bind $window <Destroy> "::CAMGUI::Choose_CancelLinux $window $img $preview"
		pack $buttons.ok $buttons.cancel -side left

		pack $lists $status $preview $settings $buttons -side top

		bind $devs.list <Button1-ButtonRelease> "::CAMGUI::FillChannelsLinux $devs.list $chans.list $status $devices"
		bind $chans.list <Button1-ButtonRelease> "::CAMGUI::StartPreviewLinux $devs.list $chans.list $status $preview $settings $devices"

		foreach device $devices {
			set dev [lindex $device 0]
			set name [lindex $device 1]

			if {$name == "" } {
				set name "Device $dev is busy"
			}

			$devs.list insert end $name
		}

		tkwait window $window
	}

	proc FillChannelsLinux { device_w chan_w status devices } {

		$chan_w delete 0 end

		if { [$device_w curselection] == "" } {
			$status configure -text "Please choose a device"
			return
		}
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

		$status configure -text "Please choose a Channel"
	}

	proc StartPreviewLinux { device_w chan_w status preview_w settings devices } {

	# 	if { [$device_w curselection] == "" } {
	# 		$status configure -text "Please choose a device"
	# 		return
	# 	}

		if { [$chan_w curselection] == "" } {
			$status configure -text "Please choose a Channel"
			return
		}

		set img [$preview_w cget -image]
		if {$img == "" } {
			return
		}

		set dev [$device_w curselection]
		set chan [$chan_w curselection]

		set device [lindex $devices $dev]
		set device [lindex $device 0]


		if { [catch {set channels [::Capture::ListChannels $device]} res] } {
			$status configure -text $res
			return
		}

		set channel [lindex $channels $chan]
		set channel [lindex $channel 0]

		if { [::Capture::IsValid $::CAMGUI::webcam_preview] } {
			::Capture::Close $::CAMGUI::webcam_preview
		}

		if { [catch {set ::CAMGUI::webcam_preview [::Capture::Open $device $channel]} res] } {
			$status configure -text $res
			return
		}

		set init_b [::Capture::GetBrightness $::CAMGUI::webcam_preview]
		set init_c [::Capture::GetContrast $::CAMGUI::webcam_preview]
		set init_h [::Capture::GetHue $::CAMGUI::webcam_preview]
		set init_co [::Capture::GetColour $::CAMGUI::webcam_preview]

		set sets [::config::getKey "webcam$device:$channel" "$init_b:$init_c:$init_h:$init_co"]
		set sets [split $sets ":"]
		set init_b [lindex $sets 0]
		set init_c [lindex $sets 1]
		set init_h [lindex $sets 2]
		set init_co [lindex $sets 3]

		::Capture::SetBrightness $::CAMGUI::webcam_preview $init_b
		::Capture::SetContrast $::CAMGUI::webcam_preview $init_c
		::Capture::SetHue $::CAMGUI::webcam_preview $init_h
		::Capture::SetColour $::CAMGUI::webcam_preview $init_co

		$settings configure -command "$preview_w configure -image \"\"; ::CAMGUI::ShowPropertiesPage $::CAMGUI::webcam_preview $img; status_log \"Img is $img\"; $preview_w configure -image $img"
		after 0 "::CAMGUI::PreviewLinux $::CAMGUI::webcam_preview $img"

	}

	proc PreviewLinux { grabber img } {
		set semaphore ::CAMGUI::sem_$grabber
		set $semaphore 0

		while { [::Capture::IsValid $grabber] && [lsearch [image names] $img] != -1 } {
			::Capture::Grab $grabber $img
			after 100 "incr $semaphore"
			tkwait variable $semaphore
		}
	}

	proc Choose_OkLinux { w device_w chan_w img devices } {

		#if { [$device_w curselection] == "" } {
		#	::CAMGUI::Choose_CancelLinux $w $img
		#	return
		#}

		if { [$chan_w curselection] == "" } {
			::CAMGUI::Choose_CancelLinux $w $img
			return
		}

		set dev [$device_w curselection]
		set chan [$chan_w curselection]



		set device [lindex $devices $dev]
		set device [lindex $device 0]


		if { [catch {set channels [::Capture::ListChannels $device]} res] } {
			::CAMGUI::Choose_CancelLinux $w $img
			return
		}

		set channel [lindex $channels $chan]
		set channel [lindex $channel 0]


		::config::setKey "webcamDevice" "$device:$channel"

		::CAMGUI::Choose_CancelLinux $w $img
	}

	proc Choose_CancelLinux { w  img } {

		if { [::Capture::IsValid $::CAMGUI::webcam_preview] } {
			::Capture::Close $::CAMGUI::webcam_preview
		}

		image delete $img

		if { [winfo exists .properties_$::CAMGUI::webcam_preview] } {
			destroy .properties_$::CAMGUI::webcam_preview
		}

		destroy $w
	}

	proc ShowPropertiesPageLinux { capture_fd {img ""} } {

		if { ![::Capture::IsValid $capture_fd] } {
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
			}
		}

		set init_b [::Capture::GetBrightness $capture_fd]
		set init_c [::Capture::GetContrast $capture_fd]
		set init_h [::Capture::GetHue $capture_fd]
		set init_co [::Capture::GetColour $capture_fd]

		set settings [::config::getKey "webcam$device:$channel" "$init_b:$init_c:$init_h:$init_co"]
		set settings [split $settings ":"]
		set init_b [lindex $settings 0]
		set init_c [lindex $settings 1]
		set init_h [lindex $settings 2]
		set init_co [lindex $settings 3]

		::Capture::SetBrightness $capture_fd $init_b
		::Capture::SetContrast $capture_fd $init_c
		::Capture::SetHue $capture_fd $init_h
		::Capture::SetColour $capture_fd $init_co

		destroy $window
		toplevel $window
		grab set $window

		frame $slides
		scale $slides.b -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Brightness" -command "::CAMGUI::Properties_SetLinux $slides.b b $capture_fd" -orient horizontal
		scale $slides.c -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Contrast" -command "::CAMGUI::Properties_SetLinux $slides.c c $capture_fd" -orient horizontal
		scale $slides.h -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Hue" -command "::CAMGUI::Properties_SetLinux $slides.h h $capture_fd" -orient horizontal
		scale $slides.co -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Colour" -command "::CAMGUI::Properties_SetLinux $slides.co co $capture_fd" -orient horizontal

		pack $slides.b $slides.c $slides.h $slides.co -expand true -fill x

		frame $buttons -relief sunken -borderwidth 3
		status_log "::CAMGUI::Properties_OkLinux $window $capture_fd $device $channel"
		button $buttons.ok -text "Ok" -command "::CAMGUI::Properties_OkLinux $window $capture_fd $device $channel"
		button $buttons.cancel -text "Cancel" -command "::CAMGUI::Properties_CancelLinux $window $capture_fd $init_b $init_c $init_h $init_co"
		wm protocol $window WM_DELETE_WINDOW "::CAMGUI::Properties_CancelLinux $window $capture_fd $init_b $init_c $init_h $init_co"


		pack $buttons.ok $buttons.cancel -side left

		if { $img == "" } {
			set img [image create photo]
		}
		label $preview -image $img

		after 0 "::CAMGUI::PreviewLinux $capture_fd $img"

		pack $slides -fill x -expand true
		pack $preview $buttons -side top


		$slides.b set $init_b
		$slides.c set $init_c
		$slides.h set $init_h
		$slides.co set $init_co

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

		set brightness [::Capture::GetBrightness $capture_fd]
		set contrast [::Capture::GetContrast $capture_fd]
		set hue [::Capture::GetHue $capture_fd]
		set colour [::Capture::GetColour $capture_fd]
		::config::setKey "webcam$device:$channel" "$brightness:$contrast:$hue:$colour"
		grab release $window
		destroy $window
	}


	proc Properties_CancelLinux { window capture_fd init_b init_c init_h init_co } {

		::Capture::SetBrightness $capture_fd $init_b
		::Capture::SetContrast $capture_fd $init_c
		::Capture::SetHue $capture_fd $init_h
		::Capture::SetColour $capture_fd $init_co
		grab release $window
		destroy $window
	}


	proc ChooseDeviceWindows { } {

		set window .webcam_chooser
		set lists $window.lists
		set devs $lists.devices
		set chans $lists.channels
		set buttons $window.buttons
		set status $window.status
		set preview $window.preview
		set settings $window.settings
		tkvideo .webcam_preview
		set devices [.webcam_preview devices]

		destroy $window
		toplevel $window


		frame $lists


		frame $devs -relief sunken -borderwidth 3
		label $devs.label -text "Devices"
		listbox $devs.list -yscrollcommand "$devs.ys set" -background \
		white -relief flat -highlightthickness 0 -height 5
		scrollbar $devs.ys -command "$devs.list yview" -highlightthickness 0 \
		-borderwidth 1 -elementborderwidth 2
		pack $devs.label $devs.list -side top -expand false -fill x
		pack $devs.ys -side right -fill y
		pack $devs.list -side left -expand true -fill both


		pack $devs -side left

		label $status -text "Please choose a device"

		set img [image create photo]
		label $preview -image $img
		button $settings -text "Camera Settings" -command ".webcam_preview property_page filter"

		frame $buttons -relief sunken -borderwidth 3
		button $buttons.ok -text "Ok" -command "::CAMGUI::Choose_OkWindows $window $devs.list $img $devices"
		button $buttons.cancel -text "Cancel" -command  "::CAMGUI::Choose_CancelWindows $window $img $preview"
		wm protocol $window WM_DELETE_WINDOW   "::CAMGUI::Choose_CancelWindows $window $img $preview"
		#bind $window <Destroy> "::CAMGUI::Choose_CancelWindows $window $img $preview"
		pack $buttons.ok $buttons.cancel -side left

		pack $lists $status $preview $settings $buttons -side top

		bind $devs.list <Button1-ButtonRelease> "::CAMGUI::StartPreviewWindows $devs.list $status $preview $settings"

		foreach device $devices {

			$devs.list insert end $device
		}

		tkwait window $window
	}

	proc Choose_OkWindows { w device_w img devices } {

		if { [$device_w curselection] == "" } {
			::CAMGUI::Choose_CancelWindows
			return
		}

		set dev [$device_w curselection]



		#set device [lindex $devices $dev]
		#set device [lindex $device 0]


		::config::setKey "webcamDevice" "$device:$channel"

		::CAMGUI::Choose_CancelWindows
	}

	proc Choose_CancelWindows { w  img preview } {

		destroy .webcam_preview

		image delete $img

		destroy $w
	}

	proc StartPreviewWindows { device_w status preview_w settings } {

		if { [$device_w curselection] == "" } {
			$status configure -text "Please choose a device"
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
		.webcam_preview start

		after 0 "::CAMGUI::PreviewWindows .webcam_preview $img"

	}

	proc PreviewWindows { grabber img } {
		set semaphore ::CAMGUI::sem_$grabber
		set $semaphore 0

		while { [winfo exists $grabber] && [lsearch [image names] $img] != -1 } {
			$grabber picture $img
			after 100 "incr $semaphore"
			tkwait variable $semaphore
		}
	}

	proc Play { img filename } {
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
			::Webcamsn::Decode $decoder $img $data
			set data [string range $data $size end]
			after 250 "incr $semaphore"
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
		after cancel "incr $semaphore"
		catch {unset $semaphore}
		catch {$img blank}
	}
	
}
