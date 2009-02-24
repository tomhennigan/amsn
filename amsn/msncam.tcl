
::Version::setSubversionId {$Id$}

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

proc getObjOption { obj option {def ""}} {
	global objects

	if { [info exists objects($obj)] } {
		set my_list  [set objects($obj)]
	} else {
		return $def
	}

	array set my_obj $my_list

	if { [info exists my_obj($option)] } {
		return [set my_obj($option)]
	} else {
		return $def
	}

}


proc clearObjOption { obj } {
	global objects

	status_log "Clearing ObjOption for $obj"
#	catch { unset objects($obj) }
}

proc checkObjExists { obj } {
	global objects
	return [info exists objects($obj)]
}

proc nbread { sock numChars } {
	set tmpsize 0
	set tmpdata ""
	
	if { [catch {
		#To avoid to be recalled when we do update
		set oldfileevent [fileevent $sock readable]

		fileevent $sock readable ""
		
		while { $tmpsize < $numChars && ![eof $sock] } {
			append tmpdata [read $sock [expr {$numChars - $tmpsize}]]
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
	set data [string range $data 0 [expr {[string length $data] - 2}] ]
	
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

		set sock [getObjOption $sid socket]

		after cancel "::MSNCAM::CreateReflectorSession $sid"
		 
 		CloseUnusedSockets $sid ""


		#draw a notification in the window (gui)
		::CAMGUI::CamCanceled $chatid $sid

		if { [OnDarwin] } {
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
			if { [winfo toplevel $window] eq $window } {
				wm protocol $window WM_DELETE_WINDOW "destroy $window"
				#$window.q configure -command "destroy $window"
				#$window.canvas bind stopbut <<Button1>> [list destroy $window]
				$window.canvas delete stopbut
	
				if { [getObjOption $sid producer] } {
					#We disable the button which show the properties
					#$window.settings configure -state disable -command ""
					$window.canvas delete confbut
					$window.canvas delete pausebut
				}
			} else {
				destroy $window.canvas
				if { [winfo exists $window.dps] } {
					pack $window.dps
	                               	if { [::config::getKey old_dpframe 0] == 1 } {
        	                                pack $window
                                }

				} elseif { [winfo exists $window.pic] } {
					pack $window.pic
				}
				::amsn::UpdateAllPictures
			}
		}

		set listening [getObjOption $sid listening_socket]
		if { $listening != "" } {
			catch { close $listening }
		}


		clearObjOption $sid
		catch {close $sock}
		clearObjOption $sock
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

		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "BYE" -1 -1 -1 -1 -1]

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

	proc RejectFTOpenSB { chatid sid branchuid uid } {
		#Execute the reject webcam protocol
		if {[catch {::MSNCAM::RejectFT $chatid $sid $branchuid $uid} res]} {
			status_log "Error in InvitationRejected: $res\n" red
			return 0
		}
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
		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr {$cseq + 1}] $uid 0 0 $sid]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

		SendAcceptInvite $sid $chatid
		status_log "::MSNCAM::SendAcceptInvite $sid $chatid\n" green
		SendSyn $sid $chatid
	}

	proc AcceptWebcamOpenSB {chatid dest branchuid cseq uid sid producer } {
		if {[catch {::MSNCAM::AcceptWebcam $chatid $dest $branchuid $cseq $uid $sid $producer} res]} {
			status_log "Error in InvitationAccepted: $res\n" red
			return 0
		}
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

		set data "[binary format ii $sid $MsgId][binword 0][binword $size][binary format iiii $size 0 [expr { int([expr {rand() * 1000000000}])%125000000 + 4}] 0][binword 0]${msg}${footer}"

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

		set data "[binary format ii $sid $MsgId][binword 0][binword $size][binary format iiii $size 0 [expr {int([expr {rand() * 1000000000}])%125000000 + 4}] 0][binword 0]${msg}${footer}"

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

		set data "[binary format ii $sid $MsgId][binword 0][binword $size][binary format iiii $size 0 [expr {int([expr {rand() * 1000000000}])%125000000 + 4}] 0][binword 0]${msg}${footer}"

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

		set data "[binary format ii $sid $MsgId][binword 0][binword $size][binary format iiii $size 0 [expr {int([expr {rand() * 1000000000}])%125000000 + 4}] 0][binword 0]${msg}${footer}"

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

		if {[::ChatWindow::For $chatid]==0} {
			::amsn::chatUser $chatid
		}

		status_log "Sending Webcam Request\n"

		set sid [expr {int([expr {rand() * 1000000000}])%125000000 + 4}]
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
			::CAMGUI::InvitationToSendSent $chatid $sid
		} else {
			setObjOption $sid producer 0
			::CAMGUI::InvitationToReceiveSent $chatid $sid
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

		set producer [getObjOption $sid producer]
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		set nick [::abook::getDisplayNick $chatid]
		if { $producer == 1 } {
			::amsn::WinWrite $chatid "[timestamp] [trans sendwebcamaccepted $nick]" green
		} else {
			::amsn::WinWrite $chatid "[timestamp] [trans recvwebcamaccepted $nick]" green
		}

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

		set ru [string range $refldata [expr {[string first "ru=" $refldata] + 3}] end]
		if { [string first "&" $ru] != -1 } {
			set ru [string range $ru 0 [expr {[string first "&" $ru] -1}]]
		}

		set ti [string range $refldata [expr {[string first "ti=" $refldata] + 3}] end]
		if { [string first "&" $ti] != -1 } {
			set ti [string range $ti 0 [expr {[string first "&" $ti] -1}]]
		}


		if { [string first "http://" $ru] != -1 } {
			set ru [string range $ru [expr {[string first "http://" $ru] + 7}] end]
		}

		set host [string range $ru 0 [expr {[string first ":" $ru]-1}]]
		set port [string range $ru [expr {[string first ":" $ru]+1}] end]
		
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


	proc PausePlayCam { window sock } {
		set state [getObjOption $sock state]
		after cancel "catch {fileevent $sock writable \"::MSNCAM::WriteToSock $sock\" }"
		if {$state == "SEND"} {
			setObjOption $sock state "PAUSED"
			$window.canvas itemconfigure pausebut -image [::skin::loadPixmap playbut] -activeimage [::skin::loadPixmap playbuth]
			$window.canvas bind pausebut <Enter> [list balloon_enter %W %X %Y [trans playwebcamsend]]
			$window.canvas bind pausebut <Leave> "set Bulle(first) 0; kill_balloon"
			$window.canvas bind pausebut <Motion> [list balloon_motion %W %X %Y [trans playwebcamsend]]

		} elseif {$state == "TSP_SEND" } {
			setObjOption $sock state "TSP_PAUSED"
			$window.canvas itemconfigure pausebut -image [::skin::loadPixmap playbut] -activeimage [::skin::loadPixmap playbuth]
			$window.canvas bind pausebut <Enter> [list balloon_enter %W %X %Y [trans playwebcamsend]]
			$window.canvas bind pausebut <Leave> "set Bulle(first) 0; kill_balloon"
			$window.canvas bind pausebut <Motion> [list balloon_motion %W %X %Y [trans playwebcamsend]]
			catch { fileevent $sock writable "::MSNCAM::WriteToSock $sock" }
		} elseif {$state == "PAUSED" } {
			setObjOption $sock state "SEND"
			$window.canvas itemconfigure pausebut -image [::skin::loadPixmap pausebut] -activeimage [::skin::loadPixmap pausebuth]
			$window.canvas bind pausebut <Enter> [list balloon_enter %W %X %Y [trans pausewebcamsend]]
			$window.canvas bind pausebut <Leave> "set Bulle(first) 0; kill_balloon"
			$window.canvas bind pausebut <Motion> [list balloon_motion %W %X %Y [trans pausewebcamsend]]
			catch { fileevent $sock writable "::MSNCAM::WriteToSock $sock" }
		}  elseif {$state == "TSP_PAUSED" } {
			setObjOption $sock state "TSP_SEND"
			$window.canvas itemconfigure pausebut -image [::skin::loadPixmap pausebut] -activeimage [::skin::loadPixmap pausebuth]
			$window.canvas bind pausebut <Enter> [list balloon_enter %W %X %Y [trans pausewebcamsend]]
			$window.canvas bind pausebut <Leave> "set Bulle(first) 0; kill_balloon"
			$window.canvas bind pausebut <Motion> [list balloon_motion %W %X %Y [trans pausewebcamsend]]
			catch { fileevent $sock writable "::MSNCAM::WriteToSock $sock" }
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
		set chatid [getObjOption $sid chatid]

	 	if { [eof $sock] } {
 			status_log "WebCam Socket $sock closed\n"
 			close $sock
			CancelCam $chatid $sid
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
					AuthSuccessfull $sid $sock
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
						} elseif { $size != 0 } {
							setObjOption $sock state "END"
							status_log "ERROR1 : $header - invalid data received" red
							catch { close $sock }
							CancelCam $chatid $sid
						} else {
							::CAMGUI::GotPausedFrame $sid
						}

					} else {
						setObjOption $sock state "END"
						status_log "ERROR2 : $data - [nbgets $sock] - [nbgets $sock]\n" red
						catch { close $sock }
						CancelCam $chatid $sid
					}

				} else {
					setObjOption $sock state "END"
					status_log "ERROR3 : [nbgets $sock] - should never received data on state $state when we're the client\n" red
					catch { close $sock }
					CancelCam $chatid $sid
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
					status_log "ERROR4 : Received $data from socket on state TSP_SEND \n" red
					catch { close $sock }
					CancelCam $chatid $sid
				}
			}
			"TSP_PAUSED"
			{
				set data [nbread $sock 4]
				if { $data != "\xd2\x04\x00\x00" } {
					setObjOption $sock state "END"
					status_log "ERROR4 : Received $data from socket on state TSP_PAUSED \n" red
					catch { close $sock }
					CancelCam $chatid $sid
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
							set email [string tolower [lindex [::MSNP2P::SessionList get $sid] 3]]
							if { ![catch {set fd [open [file join $::webcam_dir ${email}.cam] a]}] } {
								fconfigure $fd -translation binary
								setObjOption $sid weblog $fd
								# Update cam sessions metadata
								::log::UpdateCamMetadata $email
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
				} elseif {$size != 0 }  {
					#AuthFailed $sid $sock
					setObjOption $sock state "END"
					status_log "ERROR5 : $data - invalid data received" red
					catch { close $sock }
					CancelCam $chatid $sid

				} else {
					::CAMGUI::GotPausedFrame $sid
				}

			}
			"END"
			{
				status_log "Closing socket $sock because it's in END state\n" red
				catch { close $sock }
				CancelCam $chatid $sid

			}
			default
			{
				status_log "option $state of socket $sock : [getObjOption $sock state] not defined.. receiving data [nbgets $sock]... closing \n" red
				setObjOption $sock state "END"
				catch { close $sock }
				CancelCam $chatid $sid
			}

		}

		#puts  "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n"
		#status_log "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" red



	}
	proc WriteToSock { sock } {

		catch { fileevent $sock writable "" }


		set sid [getObjOption $sock sid]

		set sending [getObjOption $sock producer]
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
			"TSP_PAUSED" -
			"PAUSED" 
			{
				set encoder [getObjOption $sock codec]
				if { $encoder != "" } {
					set uid [getObjOption $encoder unique_id]
					if {$uid == "" } {
						set byte1 [myRand 1 255]
						set byte2 [myRand 1 255]
						set byte3 [myRand 1 255]
						set byte4 [myRand 1 255]
						set uid [binary format cccc $byte1 $byte2 $byte3 $byte4]					
						setObjOption $encoder unique_id $uid
					}
				} else {
					set uid 0
				}

				after cancel "catch {fileevent $sock writable \"::MSNCAM::WriteToSock $sock\" }"
				after 4000 "catch {fileevent $sock writable \"::MSNCAM::WriteToSock $sock\" }"
				set data "[binary format ccsssii 24 1 0 0 0 0 0]"
				append data $uid
				set timestamp [ expr { [clock clicks -milliseconds] % 315360000 } ]
				append data "[binary format i $timestamp]"
				status_log "sending paused header"
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

		set bheader [binary format ii 0 $MsgId][binword 0][binword 0][binary format iiii 0 4 [expr {int([expr {rand() * 1000000000}])%125000000 + 4}] 0][binword 0]

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
		     && [getObjOption $sid canceled] != 1 && [checkObjExists $sid]
		     && [getObjOption $sid reflector] != 1} {
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
			set tmp_data [string range $tmp_data [expr {[string first "?>" $tmp_data] +2}] end]

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
		
			set tmp_data [string range $tmp_data [expr {[string first "?>" $tmp_data] +2}] end]

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
		status_log "fileevent CheckConnected for socket $socket\n"

		fileevent $socket readable ""
		fileevent $socket writable ""

		if { [eof $socket] || [fconfigure $socket -error] != "" } {
			status_log "Socket didn't connect $socket : [eof $socket] || [fconfigure $socket -error]\n" red
			close $socket
			clearObjOption $socket

			if {[checkObjExists $sid] } {
				set ips [getObjOption $sid ips]
				setObjOption $sid ips [RemoveSocketFromList $ips $socket]
			}

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
		clearObjOption $socket

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

			set ips [getObjOption $sid connected_ips]
			for {set idx 0} { $idx < [llength $ips] } {incr idx } {
				set connection [lindex $ips $idx]
				foreach {ip port sock} $connection break
				if {$sock == $used_socket } break
			}
			if {$used_socket != "" && [info exists sock] && $sock == $used_socket } {
				setObjOption $sid connected_ips [list $ip $port $sock]
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
				clearObjOption $sock
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


		if { [expr {$offset + 1202}] < $totalsize } {
			set footer "\x00\x00\x00\x04"
			set to_send [string range $msg 0 1201]
			set size [string length $to_send]
			set data "[binary format ii $sid $MsgId][binword $offset][binword $totalsize][binary format iiii $size 0 [expr {int([expr {rand() * 1000000000}])%125000000 + 4}] 0][binword 0]${to_send}${footer}"

			set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $dest\r\n\r\n"

			set data "${theader}${data}"
			set msg_len [string length $data]

			::MSNP2P::SendPacket [::MSN::SBFor $chatid] "$data"
			set offset [expr {$offset + 1202}]
			set msg [string range $msg 1202 end]
			SendXMLChunk $chatid $sid $msg $offset $totalsize
		} else {
			set footer "\x00\x00\x00\x04"
			set to_send $msg
			set size [string length $to_send]
			set data "[binary format ii $sid $MsgId][binword $offset][binword $totalsize][binary format iiii $size 0 [expr {int([expr {rand() * 1000000000}])%125000000 + 4}] 0][binword 0]${to_send}${footer}"

			set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $dest\r\n\r\n"

			set data "${theader}${data}"
			set msg_len [string length $data]

			::MSNP2P::SendPacket [::MSN::SBFor $chatid] "$data"

		}
	}

	proc GetCamDataUID { data } {
		# struct header {
		#    char header_size;
		#    char is_pause_frame;
		#    short width;
		#    short height;
		#    short is_keyframe;
		#    int payload_size;
		#    int FCC; \\ ML20
		#    int unique_random_id;
		#    int timestamp;
		# }
		

		if { [string length $data] < 24 } {
			return -1
		}

		#binary scan $data ccsssiiii h_size paused w h is_keyframe p_size fcc uid timestamp
		binary scan $data c@16i h_size uid
		

		if { $h_size != 24 } {
			status_log "invalid - $h_size - [string range $data 0 50]" red
			return -1
		}
		set fcc [string range $data 12 15]
		if { $fcc != "ML20" } {
			status_log "fcc invalid - $fcc - [string range $data 0 50]" red
			return -1
		}

		return $uid

	}
	proc GetCamDataTimestamp { data } {
		# struct header {
		#    char header_size;
		#    char is_pause_frame;
		#    short width;
		#    short height;
		#    short is_keyframe;
		#    int payload_size;
		#    int FCC; \\ ML20
		#    int unique_random_id;
		#    int timestamp;
		# }
		

		if { [string length $data] < 24 } {
			return -1
		}

		#binary scan $data ccsssiiii h_size paused w h is_keyframe p_size fcc uid timestamp
		binary scan $data c@20i h_size timestamp
		

		if { $h_size != 24 } {
			status_log "invalid - $h_size - [string range $data 0 50]" red
			return -1
		}
		set fcc [string range $data 12 15]
		if { $fcc != "ML20" } {
			status_log "fcc invalid - $fcc - [string range $data 0 50]" red
			return -1
		}
		return $timestamp


	}

	proc GetCamDataSize { data } {

		# struct header {
		#    char header_size;
		#    char is_pause_frame;
		#    short width;
		#    short height;
		#    short is_keyframe;
		#    int payload_size;
		#    int FCC; \\ ML20
		#    int unique_random_id;
		#    int timestamp;
		# }
		

		if { [string length $data] < 24 } {
			return -1
		}


		#binary scan $data ccsssiiii h_size paused w h is_keyframe p_size fcc uid timestamp
		binary scan $data cc@8i h_size paused p_size
		
		#binary scan "\x30\x32\x4C\x4D" I r_fcc

		#status_log "got webcam header :  $data" green
		if { $h_size != 24 } {
			status_log "invalid - $h_size - [string range $data 0 50]" red
			return -1
		}
		# Pause header
		if { $paused == 1} {
			#status_log "Got 'pause' header" red
			return 0
		}
		set fcc [string range $data 12 15]
		if { $fcc != "ML20" } {
		# if { $fcc != $r_fcc} 
			status_log "fcc invalide - $fcc - [string range $data 0 50]" red
			return -1
		}
		#status_log "resolution : $w x $h - $h_size $p_size \n" red

		return $p_size

	}

	proc SendFrame { sock encoder img } {
		#If the img is not at the right size, don't encode (crash issue..)

		if { [::config::getKey lowrescam] == 1 && ([OnLinux] || [OnBSD]) } {
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
				return 0
			}
			
		}
		if { !([info exists ::test_webcam_send_log] && $::test_webcam_send_log != "")
		     && [catch {set data [::Webcamsn::Encode $encoder $img]} res] } {
			status_log "Error encoding frame : $res\n"
		    return 0
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
				# struct header {
				#    char header_size;
				#    char is_pause_frame;
				#    short width;
				#    short height;
				#    short is_keyframe;
				#    int payload_size;
				#    int FCC; \\ ML20
				#    int unique_random_id;
				#    int timestamp;
				# }
				
				# determine if it's a keyframe..
				binary scan $data @12c keyframe_flag
				if {[info exists keyframe_flag] && $keyframe_flag == 0} {
					set is_keyframe 1 
				} else {
					set is_keyframe 0
				}
				set uid [getObjOption $encoder unique_id]
				if {$uid == "" } {
					set byte1 [myRand 1 255]
					set byte2 [myRand 1 255]
					set byte3 [myRand 1 255]
					set byte4 [myRand 1 255]
					set uid [binary format cccc $byte1 $byte2 $byte3 $byte4]					
					setObjOption $encoder unique_id $uid
				}

				# set basic header info
				set header "[binary format ccsssi 24 0 [::Webcamsn::GetWidth $encoder] [::Webcamsn::GetHeight $encoder] $is_keyframe [string length $data]]"
				# add ML20
				append header "\x4D\x4C\x32\x30"
				# add a unique identifier
				append header "$uid"
				# add a timestamp
				set timestamp [ expr { [clock clicks -milliseconds] % 315360000 } ]
				append header "[binary format i $timestamp]"
				set data "${header}${data}"

			}
		}
		catch {
		    if { ![eof $sock] && [fconfigure $sock -error] == "" } {
			puts -nonewline $sock "$data"
		    }
		
		}
		return 1

	}




}

namespace eval ::CAMGUI {

	proc camPresent { } {
		if { ! [info exists ::webcamsn_loaded] } { ::CAMGUI::ExtensionLoaded }
		if { ! $::webcamsn_loaded } { status_log "Error when trying to load Webcamsn extension" red; return }
		if { ! [info exists ::capture_loaded] } { ::CAMGUI::CaptureLoaded }
		if { ! $::capture_loaded } { return 0 }

		#Now we are sure that both webcamsn and capture are loaded
		set campresent 0
		if { [OnLinux] || [OnBSD] } {
			if { [llength [::Capture::ListDevices]] > 0 } {
				set campresent 1
			}
		} elseif { [OnWin] } {
			destroy .webcam_preview
			tkvideo .webcam_preview
			set devices [.webcam_preview devices]
			if { [llength $devices] > 0 } {
				set campresent 1
			}
			destroy .webcam_preview
		} elseif { [OnDarwin] } {
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
	        set img [getObjOption $sid image]

# 		if { 1 == 1 } {
# 		    set chatid [getObjOption $sid chatid]
# 		    set window [::ChatWindow::For $chatid]
# 		    set img displaypicture_std_$chatid
# 		}


		if { $decoder == "" } {
			set decoder [::Webcamsn::NewDecoder]
			setObjOption $sid codec $decoder
		}

		if { $window == "" } {
			set window .webcam_$sid
			set chatid [getObjOption $sid chatid]
			set img [image create photo [TmpImgName]]
			if { [::config::getKey cam_in_cw] } {
                                set win_name [::ChatWindow::For $chatid]
                                set window [::ChatWindow::GetOutDisplayPicturesFrame $win_name]
                                pack forget $window.dps
				canvas $window.canvas -width 160 -height 120
				set wwidth 158
				set wheight 120
				[winfo parent $window] configure -width [expr {160 +  [image width [::skin::loadPixmap imghide]] + (2 * [::skin::getKey chat_dp_border])} ]
				if { [::config::getKey old_dpframe 0] == 1 } {
					pack $window
				}
			} else {
                                toplevel $window -class AmsnWebcam
                                wm title $window "$chatid - [::abook::getDisplayNick $chatid]"
                                wm protocol $window WM_DELETE_WINDOW "::MSNCAM::CancelCam $chatid $sid"
				canvas $window.canvas -width 320 -height 240
				set wwidth 318
				set wheight 240
			}
			set canv $window.canvas
			$canv create image 0 0 -anchor nw -image $img
			pack $canv
			bind $canv <Destroy> "image delete $img"
			#label $window.paused -fg red -text ""
			#pack $window.paused -expand true -fill x
			$canv create image $wwidth 0 -anchor ne -image [::skin::loadPixmap pause] -state hidden -tags paused
			$canv create image $wwidth $wheight -anchor se -image [::skin::loadPixmap stopbut] -activeimage [::skin::loadPixmap stopbuth] -tags stopbut
			$canv bind stopbut <<Button1>> [list ::MSNCAM::CancelCam $chatid $sid]
			$canv bind stopbut <Enter> [list balloon_enter %W %X %Y [trans stopwebcamreceive]]
			$canv bind stopbut <Leave> "set Bulle(first) 0; kill_balloon"
			$canv bind stopbut <Motion> [list balloon_motion %W %X %Y [trans stopwebcamreceive]]
			setObjOption $sid window $window
			setObjOption $sid image $img
		} else {
			#$window.paused configure -text ""
			if {[winfo exists $window.canvas]} {
				$window.canvas itemconfigure paused -state hidden
			}
		}


		catch {::Webcamsn::Decode $decoder $img $data}
		if { [winfo exists $window] && [winfo toplevel $window] != $window } {
			catch {::picture::Resize $img 160 120}
                } elseif { ![winfo exists $window] && ![OnDarwin] } {
                        ::MSNCAM::CancelCam $chatid $sid
                }


	}
	
	proc GotPausedFrame {sid} {
		set window [getObjOption $sid window]
		if { $window != "" } {
			#$window.paused configure -text "[trans pausedwebcamreceive]"
			$window.canvas itemconfigure paused -state normal
		}
	}

	proc GetCamFrame { sid socket } {

		if { ! [info exists ::webcamsn_loaded] } { ExtensionLoaded }
		if { ! $::webcamsn_loaded } { return }

		if { ! [info exists ::capture_loaded] } { CaptureLoaded }
		if { ! $::capture_loaded } { return }

		if { [getObjOption $socket state] == "END" } { return }

		set chatid [getObjOption $sid chatid]

		set window [getObjOption $sid window]
		set img [getObjOption $sid image]

		set encoder [getObjOption $socket codec]
		set source [getObjOption $sid source]

		if { [OnLinux]  || [OnBSD]} {
			if {$source == "0" } { set source "/dev/video0:0" }
			set pos [string last ":" $source]
			set dev [string range $source 0 [expr {$pos-1}]]
			set channel [string range $source [expr {$pos+1}] end]
		}

		set grabber [getObjOption $sid grabber]
		if { $grabber == "" } {
			if { [OnWin] } {
				foreach grabberItm [array names ::grabbers] {
					if {[$grabberItm cget -source] == $source} {
						set grabber $grabberItm
						break
					}
				}
				if { $grabber == "" } {
					set grabber .grabber_$sid
				}
			} elseif { [OnDarwin] } {
				set grabber .grabber.seq
			} elseif { [OnLinux] || [OnBSD] } {
				set grabber [::Capture::GetGrabber $dev $channel]
			}
		}


		set grab_proc [getObjOption $sid grab_proc]

		if { !([info exists ::test_webcam_send_log] && $::test_webcam_send_log != "") && ![::CAMGUI::IsGrabberValid $grabber] } {
			status_log "Invalid grabber : $grabber"

			if { [OnWin] } {

				set grabber .grabber_$sid
				set grabber [tkvideo $grabber]
				set source [getObjOption $sid source]
				if { [catch { $grabber configure -source $source } res] } {
					msg_box "[trans badwebcam]\n$res"
					return
				}	
				if { [catch { $grabber start } res] } {
					msg_box "[trans badwebcam]\n$res"
					return
				}
				if { [catch { $grabber format 320x240 } res] } {
					msg_box "[trans badwebcam]\n$res"
					return
				}
				setObjOption $sid grab_proc "Grab_Windows"

			} elseif { [OnDarwin] } {
				#Add grabber to the window
				if {![::CAMGUI::CreateGrabberWindowMac]} {
					::MSNCAM::CancelCam $chatid $sid
					return
				}
				setObjOption $sid grab_proc "Grab_Mac"

			} elseif { [OnLinux] || [OnBSD] } {
				set pos [string last ":" $source]
				set dev [string range $source 0 [expr {$pos-1}]]
				set channel [string range $source [expr {$pos+1}] end]

				if { [::config::getKey lowrescam] == 1 } {
					set cam_res "QSIF"
				} else {
					set cam_res "SIF"
				}

				if { [catch { ::Capture::Open $dev $channel $cam_res} grabber] } {
					::MSNCAM::CancelCam $chatid $sid
					msg_box "[trans badwebcam]\n$grabber"
					return
				}
				
				if { ![info exists ::webcam_settings_bug] || $::webcam_settings_bug == 0} {
					set settings [::config::getKey "webcam$dev:$channel" "-1:-1:-1:-1"]
					set settings [split $settings ":"]
					set set_b [lindex $settings 0]
					set set_c [lindex $settings 1]
					set set_h [lindex $settings 2]
					set set_co [lindex $settings 3]

					if {[string is integer -strict $set_b] && $set_b >= 0 && $set_b <= 65535 } {
						::Capture::SetBrightness $grabber $set_b
					}
					if {[string is integer -strict $set_c] && $set_c >= 0 && $set_c <= 65535 } {
						::Capture::SetContrast $grabber $set_c
					}
					if {[string is integer -strict $set_h] && $set_h >= 0 && $set_h <= 65535 } {
						::Capture::SetHue $grabber $set_h
					}
					if {[string is integer -strict $set_co] && $set_co >= 0 && $set_co <= 65535 } {
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
			if { [OnDarwin] } {
				set img [image create photo [TmpImgName]]
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
				set img [image create photo [TmpImgName]]
				if { [::config::getKey cam_in_cw]} {
					set win_name [::ChatWindow::For $chatid]
					set window [::ChatWindow::GetInDisplayPictureFrame $win_name]
					pack forget $window.pic
	                                canvas $window.canvas -width 160 -height 120
        	                        set wwidth 158
                	                set wheight 120
					[winfo parent $window] configure -width [expr {160 +  [image width [::skin::loadPixmap imghide]] + (2 * [::skin::getKey chat_dp_border])} ]
				} else {
					toplevel $window -class AmsnWebcam
					wm title $window "$chatid - [::abook::getDisplayNick $chatid]"
					wm protocol $window WM_DELETE_WINDOW "::MSNCAM::CancelCam $chatid $sid"
					canvas $window.canvas -width 320 -height 240
	                                set wwidth 318
        	                        set wheight 240
				}
				set canv $window.canvas
				$canv create image 0 0 -anchor nw -image $img
				pack $canv
				bind $canv <Destroy> "image delete $img"
				set confbut [$canv create image $wwidth $wheight -anchor se -image [::skin::loadPixmap confbut] -activeimage [::skin::loadPixmap confbuth] -tags confbut]
				set stopbut [$canv create image [expr {$wwidth - 28}] $wheight -anchor se -image [::skin::loadPixmap stopbut] -activeimage [::skin::loadPixmap stopbuth] -tags stopbut]
				set pausebut [$canv create image [expr {$wwidth - 56}] $wheight -anchor se -image [::skin::loadPixmap pausebut] -activeimage [::skin::loadPixmap pausebuth] -tags pausebut]
				$canv bind stopbut <<Button1>> [list ::MSNCAM::CancelCam $chatid $sid]
				$canv bind stopbut <Enter> [list balloon_enter %W %X %Y [trans stopwebcamreceive]]
				$canv bind stopbut <Leave> "set Bulle(first) 0; kill_balloon"
				$canv bind stopbut <Motion> [list balloon_motion %W %X %Y [trans stopwebcamreceive]]

				$canv bind pausebut <<Button1>> [list ::MSNCAM::PausePlayCam $window $socket]
				$canv bind pausebut <Enter> [list balloon_enter %W %X %Y [trans pausewebcamsend]]
				$canv bind pausebut <Leave> "set Bulle(first) 0; kill_balloon"
				$canv bind pausebut <Motion> [list balloon_motion %W %X %Y [trans pausewebcamsend]]

				$canv bind confbut <<Button1>> [list ::CAMGUI::ShowPropertiesPage $grabber $img]
				$canv bind confbut <Enter> [list balloon_enter %W %X %Y [trans changevideosettings]]
				$canv bind confbut <Leave> "set Bulle(first) 0; kill_balloon"
				$canv bind confbut <Motion> [list balloon_motion %W %X %Y [trans changevideosettings]]

			}

			if { [OnDarwin] } {
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
			if { [OnWin] } {
				setObjOption $sid grab_proc "Grab_Windows"

			} elseif { [OnDarwin] } {
				setObjOption $sid grab_proc "Grab_Mac"

			} elseif { [OnLinux] || [OnBSD] } {
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
                if { [winfo exists $window] && [winfo toplevel $window] != $window } {
                        catch {::picture::Resize $img 160 120}
                } elseif { ![winfo exists $window] && ![OnDarwin] } {
			::MSNCAM::CancelCam $chatid $sid
		}

	}

	proc Grab_Windows {grabber socket encoder img} {

		if { $encoder == "" } {
			set encoder [::Webcamsn::NewEncoder HIGH]
			::Webcamsn::SetQuality $encoder 4500
			setObjOption $socket codec $encoder
		}

		if { ![catch { $grabber picture $img} res] } {
			::MSNCAM::SendFrame $socket $encoder $img
		} else {
		    status_log "error grabbing : $res\n" red
		}
		#catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
	}

	proc Grab_Linux {grabber socket encoder img} {
		if { ([info exists ::test_webcam_send_log] && $::test_webcam_send_log != "") ||
		     ![catch { ::Capture::Grab $grabber $img} res] } {
			if { !([info exists ::test_webcam_send_log] && 
			      $::test_webcam_send_log != "") &&$encoder == "" } {
				#Here we translate for the encoder...
				if { $res == "SIF" } {
					set res "HIGH"
				} else {
					set res "LOW"
				}
				set encoder [::Webcamsn::NewEncoder $res]
				::Webcamsn::SetQuality $encoder 4500
				setObjOption $socket codec $encoder
			}
			::MSNCAM::SendFrame $socket $encoder $img
		} else {
		    status_log "error grabbing : $res\n" red
		}
		#catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
	}

	proc Grab_Mac { grabber socket encoder img } {

		if { $encoder == "" } {
			set encoder [::Webcamsn::NewEncoder HIGH]
			::Webcamsn::SetQuality $encoder 4500
			setObjOption $socket codec $encoder
		}

		if {[winfo ismapped $grabber]} {
			set socker_ [getObjOption $img socket]
			set encoder_ [getObjOption $img encoder]

			if { $socker_ == "" || $encoder_ == "" } {
				setObjOption $img socket $socket
				setObjOption $img encoder $encoder
			}
			::CAMGUI::ImageReady_Mac $grabber $img
			$grabber image ImageReady_Mac $img
		} else {
			# Ok, this is very important!! this is the famous bugfix to the infamous
			# 'whitescreen bug'.. the problem is that if the window is not yet mapped
			# we didn't do anything, and for a direct connection, that pretty much meant
			# that 250ms later, we get the chance to send a new frame...
			# the problem with the WSOD is that it happens when using the reflector
			# if we don't send a frame, we can't get an ACK for it, if we don't get the ACK
			# then we'll never get the writable event called again, so we won't get the chance
			# to send any frame.. ever.. no frame = white screen..
			catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
		}


	}
	
	proc ImageReady_Mac {w img } {
		set socket [getObjOption $img socket]
		set encoder [getObjOption $img encoder]
		if { $socket == "" || $encoder == "" } { return }
		if {[::MSNCAM::SendFrame $socket $encoder $img] == 0 } {
			# SendFrame returns 0 if it didn't send the frame so we need
			# to reset the fileevent.. read comment above in Grab_Mac to know why
			catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
		}
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
		set camwidth 320
	
		#Add grabber to the window
		#Show message error if it's not possible
		if { ![catch [list seqgrabber $w.seq  -audio 0 -width $camwidth] res] } {
			pack $w.seq
					
			#Add button to change settings
			button $w.settings -command "::CAMGUI::ChooseDeviceMac" -text "[trans changevideosettings]"
			pack $w.settings
			
			#Add zoom option
			label $w.zoomtext -text "[trans zoom]:" -font sboldf
			spinbox $w.zoom -from 1 -to 5 -increment 0.5 -width 2 -command "catch {$w.seq configure -zoom %s}"
			pack $w.zoomtext
			pack $w.zoom
			wm title $w "[trans webcam] - [::config::getKey login]"
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

		if { [OnWin] || [OnDarwin] } {
			return [winfo exists $grabber]
		} elseif { [OnLinux] || [OnBSD] } {
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

		if { [OnLinux] || [OnBSD] } {
			::Capture::Close $grabber
		} elseif { [OnDarwin] } {
			destroy $grabber
			destroy .grabber
		} elseif { [OnWin] } {
			destroy $grabber
		}
		unset ::grabbers($grabber)

	}

	proc CaptureLoaded { } {
		if { [info exists ::capture_loaded] && $::capture_loaded } { return 1 }

		if { [OnWin] } {
			set extension "tkvideo"
		} elseif { [OnDarwin] } {
			set extension "QuickTimeTcl"
		} elseif { [OnLinux] || [OnBSD] } {
			set extension "capture"
		} else {
			set ::capture_loaded 0
			return 0
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

	proc AcceptOrRefuse {chatid dest branchuid cseq uid sid producer} {
		SendMessageFIFO [list ::CAMGUI::AcceptOrRefuseWrapped $chatid $dest $branchuid $cseq $uid $sid $producer] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	#Executed when we receive a request to accept or refuse a webcam session
	proc AcceptOrRefuseWrapped {chatid dest branchuid cseq uid sid producer} {
	
		#Grey line
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green
		
		::amsn::WinWriteIcon $chatid winwritecam 3 2

		if { [::abook::getContactData $chatid autoacceptwc] == 1 } {
			if { $producer == 0 } {
				::amsn::WinWrite $chatid "[timestamp] [trans webcaminvitereceivingauto [::abook::getDisplayNick $chatid]]\n" green
			} else {
				::amsn::WinWrite $chatid "[timestamp] [trans webcaminvitesendingauto [::abook::getDisplayNick $chatid]]\n" green
			}
			
			::CAMGUI::InvitationAccepted $chatid $dest $branchuid $cseq $uid $sid $producer
			
		} else {
			#Show invitation
			#::amsn::WinWrite $chatid "[timestamp] [trans webcaminvitereceived [::abook::getDisplayNick $chatid]]" green

			if { $producer == 0 } {
				::amsn::WinWrite $chatid "[timestamp] [trans webcaminvitereceiving [::abook::getDisplayNick $chatid]]" green
			} else {
				::amsn::WinWrite $chatid "[timestamp] [trans webcaminvitesending [::abook::getDisplayNick $chatid]]" green
			}
		
			#Accept and refuse actions
			::amsn::WinWrite $chatid " - (" green
			::amsn::WinWriteClickable $chatid "[trans accept]" [list ::CAMGUI::InvitationAccepted $chatid $dest $branchuid $cseq $uid $sid $producer] acceptwebcam$sid
			::amsn::WinWrite $chatid " / " green
			::amsn::WinWriteClickable $chatid "[trans reject]" [list ::CAMGUI::InvitationRejected $chatid $sid $branchuid $uid] nowebcam$sid
			::amsn::WinWrite $chatid ")\n" green
		}
		
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
		::amsn::WinWrite $chatid " \n" green
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
		[::ChatWindow::GetOutText ${win_name}] tag bind askwebcam$chatid <<Button1>> ""
		
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
		[::ChatWindow::GetOutText ${win_name}] tag bind sendwebcam$chatid <<Button1>> ""
		
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
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <<Button1>> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure nowebcam$sid \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr
		
		#Execute the accept webcam protocol
		if {[::MSN::ChatQueue $chatid [list ::MSNCAM::AcceptWebcamOpenSB $chatid $dest $branchuid $cseq $uid $sid $producer]] == 0} {
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
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <<Button1>> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure nowebcam$sid \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr
		
		#Execute the reject webcam protocol
		if {[::MSN::ChatQueue $chatid [list ::MSNCAM::RejectFTOpenSB $chatid $sid $branchuid $uid ]] == 0} {
			return 0
		}
	}
	
	#Executed when you invite someone to a webcam session and he refuses the request
	proc InvitationDeclined {chatid sid} {
		SendMessageFIFO [list ::CAMGUI::InvitationDeclinedWrapped $chatid $sid] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	proc InvitationDeclinedWrapped {chatid sid} {
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0 } {
			return 0
		}

		[::ChatWindow::GetOutText ${win_name}] tag configure cancelwebcam$sid \
		    -foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelwebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelwebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelwebcam$sid <<Button1>> ""

		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		::amsn::WinWrite $chatid "[timestamp] [trans webcamrejected [::abook::getDisplayNick $chatid]]\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	#Executed when your contact stops the webcam session
	proc CamCanceled {chatid sid} {
		SendMessageFIFO [list ::CAMGUI::CamCanceledWrapped $chatid $sid] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	proc CamCanceledWrapped {chatid sid} {
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0 } {
			return 0
		}
		
		# Disabling Cancel Button
		[::ChatWindow::GetOutText ${win_name}] tag configure cancelwebcam$sid \
		    -foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelwebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelwebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelwebcam$sid <<Button1>> ""

		# Disabling Accept Button
		[::ChatWindow::GetOutText ${win_name}] tag configure acceptwebcam$sid \
		    -foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptwebcam$sid <<Button1>> ""

		# Disabling Decline Button
		[::ChatWindow::GetOutText ${win_name}] tag configure nowebcam$sid \
		    -foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind nowebcam$sid <<Button1>> ""

		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		::amsn::WinWrite $chatid "[timestamp] [trans webcamcanceled [::abook::getDisplayNick $chatid]]\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	#Executed when you invite someone to send your webcam
	proc InvitationToSendSent {chatid sid} {
		SendMessageFIFO [list ::CAMGUI::InvitationToSendSentWrapped $chatid $sid] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	proc InvitationToSendSentWrapped {chatid sid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		::amsn::WinWrite $chatid "[timestamp] [trans webcamrequestsend]" green
		::amsn::WinWrite $chatid " - (" green
		::amsn::WinWriteClickable $chatid "[trans cancel]" [list ::MSNCAM::CancelCam $chatid $sid] cancelwebcam$sid
		::amsn::WinWrite $chatid ")\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	#Executed when you invite someone to receive his webcam
	proc InvitationToReceiveSent {chatid sid} {
		SendMessageFIFO [list ::CAMGUI::InvitationToReceiveSentWrapped $chatid $sid] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	proc InvitationToReceiveSentWrapped {chatid sid} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green
		::amsn::WinWriteIcon $chatid winwritecam 3 2
		::amsn::WinWrite $chatid "[timestamp] [trans webcamrequestreceive]" green
		::amsn::WinWrite $chatid " - (" green
		::amsn::WinWriteClickable $chatid "[trans cancel]" [list ::MSNCAM::CancelCam $chatid $sid] cancelwebcam$sid
		::amsn::WinWrite $chatid ")\n" green
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
		if { [abook::getDemographicField listening] == "" || [abook::getDemographicField conntype] == "" } {
			abook::getIPConfig
		}
		#Small picture at the top of the window
		label $w.webcampic -image [::skin::loadPixmap webcam]
		pack $w.webcampic
		#Show the two connection informations to know if we are firewalled or not
		frame $w.abooktype
		if { [::abook::getDemographicField conntype] == "" } {
			label $w.abooktype.abook -text "[trans connectfirst]" -font sboldf
		} else {
			label $w.abooktype.text -text "[trans type]" -font sboldf
			label $w.abooktype.abook -text [::abook::getDemographicField conntype]
			frame $w.abooklistening
			label $w.abooklistening.text -text "[trans listening]" -font sboldf
			label $w.abooklistening.abook -text [::abook::getDemographicField listening]
		}

		if { [::abook::getDemographicField conntype] != "" } {
			pack $w.abooktype.text  -padx 5 -side left
			pack $w.abooktype.abook -padx 5 -side right
			pack $w.abooktype -expand true
			pack $w.abooklistening.text -padx 5 -side left
			pack $w.abooklistening.abook -padx 5 -side right
			pack $w.abooklistening -expand true
		
			if { [::abook::getDemographicField listening] == "false"} {
				label $w.abookresult -text "[trans firewalled]" -font sboldf -foreground red
			} else {
				label $w.abookresult -text "[trans portswellconfigured]" -font sboldf
			}
			pack $w.abookresult -expand true -padx 5
		} else {
			pack $w.abooktype.abook -padx 5 -side right
			pack $w.abooktype -expand true
		}

		#Verify if the extension webcamsn is loaded
		if {[::CAMGUI::ExtensionLoaded]} {
			label $w.webcamsn -text "[trans webcamextloaded]" -font sboldf
		} else {
			label $w.webcamsn -text "[trans webcamextnotloaded]" -font sboldf -foreground red
		}
		pack $w.webcamsn -expand true -padx 5
		#Verify if the capture extension is loaded, change on each platform
		if { [OnWin] } {
			set extension "tkvideo"
		} elseif { [OnDarwin] } {
			set extension "QuickTimeTcl"
		} elseif { [OnLinux] || [OnBSD] } {
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

		checkbutton $w.wanttosharecam -text "[trans wanttosharecam]" -font sboldf -variable [::config::getVar wanttosharecam] -onvalue 1 -offvalue 0 -state active -command "::CAMGUI::buttonToggled"
		pack $w.wanttosharecam

		checkbutton $w.lowrescam -text "[trans lowrescam]" -font sboldf -variable [::config::getVar lowrescam] -onvalue 1 -offvalue 0 -state active 
		if { [OnLinux] || [OnBSD] } {
			pack $w.lowrescam
		}

		if { [::CAMGUI::camPresent] == 0 } {
			$w.wanttosharecam configure -state disabled
			$w.lowrescam configure -state disabled
		}

		button $w.settings -command "::CAMGUI::ChooseDevice" -text "[trans changevideosettings]"
		#Add button to change settings
		pack $w.settings
		#Add button to open link to the wiki
		set lang [::config::getGlobalKey language]
		set link "$::weburl/webcamfaq.php?lang=$lang"
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

		if { [OnLinux]  || [OnBSD]} {
			ChooseDeviceLinux
		} elseif { [OnDarwin] } {
			ChooseDeviceMac
		} elseif { [OnWin] } {
			ChooseDeviceWindows
		}
	}

	proc ShowPropertiesPage { grabber img } {
		if { ! [info exists ::capture_loaded] } { CaptureLoaded }
		if { ! $::capture_loaded } { return }
		if { ![IsGrabberValid $grabber] } { return }
		
		if { [OnLinux] || [OnBSD] } {
			ShowPropertiesPageLinux $grabber $img
		} elseif { [OnDarwin] } {
			return
		} elseif { [OnWin] } {
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
			::amsn::infoMsg [trans nodevices]
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

		set img [image create photo [TmpImgName]]
		label $preview -image $img
		button $settings -text "[trans changevideosettings]"

		frame $buttons -relief sunken -borderwidth 3
		button $buttons.ok -text "[trans ok]" -command [list ::CAMGUI::Choose_OkLinux $window $devs.list $chans.list $img $devices]
		button $buttons.cancel -text "[trans cancel]" -command [list ::CAMGUI::Choose_CancelLinux $window $img]
		wm protocol $window WM_DELETE_WINDOW [list ::CAMGUI::Choose_CancelLinux $window $img]
		#bind $window <Destroy> "::CAMGUI::Choose_CancelLinux $window $img $preview"
		pack $buttons.ok $buttons.cancel -side left

		pack $lists $status $preview $settings $buttons -side top

		bind $devs.list <<Button1>> [list ::CAMGUI::FillChannelsLinux $devs.list $chans.list $status $devices]
		bind $chans.list <<Button1>> [list ::CAMGUI::StartPreviewLinux $devs.list $chans.list $status $devices $preview $settings]

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

		if { [::config::getKey lowrescam] == 1 } {
			set cam_res "QSIF"
		} else {
			set cam_res "SIF"
		}

		if { [catch {set ::CAMGUI::webcam_preview [::Capture::Open $device $channel $cam_res]} res] } {
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

			if {[string is integer -strict $set_b] && $set_b > 0 && $set_b < 65535 } {
				::Capture::SetBrightness $::CAMGUI::webcam_preview $set_b
			}
			if {[string is integer -strict $set_c] && $set_c > 0 && $set_c < 65535 } {
				::Capture::SetContrast $::CAMGUI::webcam_preview $set_c
			}
			if {[string is integer -strict $set_h] && $set_h > 0 && $set_b < 65535 } {
				::Capture::SetHue $::CAMGUI::webcam_preview $set_h
			}
			if {[string is integer -strict $set_co] && $set_co > 0 && $set_co < 65535 } {
				::Capture::SetColour $::CAMGUI::webcam_preview $set_co
			}
		}

		$settings configure -command [list ::CAMGUI::ShowPropertiesPage $::CAMGUI::webcam_preview $img]
		after 0 [list ::CAMGUI::PreviewLinux $::CAMGUI::webcam_preview $img]

	}

	proc PreviewLinux { grabber img } {
		set semaphore ::CAMGUI::sem_$grabber
		set $semaphore 0
		while { [::Capture::IsValid $grabber] && [ImageExists $img]} {
			if {[catch {::Capture::Grab $grabber $img} res]} {
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

		#if the channel for reading (capture) is not valid
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
		#withing the list of grabbers, get the device/channel for our grabber
		foreach grabber $grabbers {
			if { [lindex $grabber 0] == $capture_fd } {
				set device [lindex $grabber 1]
				set channel [lindex $grabber 2]
				break
			}
		}

		#if there already exists a list of windows using this grabber, append this one
		if { [info exists ::grabbers($capture_fd)] } {
			lappend ::grabbers($capture_fd) $window
		#otherwise, create this list with this window as first element
		} else {
			set ::grabbers($capture_fd) [list $window]
		}

		#split the capture settings in a list of values and store 'm in the named vars
		foreach {set_b set_c set_h set_co }\
			[split [::config::getKey "webcam$device:$channel" "0:0:0:0"] ":"]\
			{break}

		#if the values stored in config are valid, set 'm
                if {[string is integer -strict $set_b] && $set_b > 0 && $set_b < 65535 } {
                        ::Capture::SetBrightness $capture_fd $set_b
                }
                if {[string is integer -strict $set_c] && $set_c > 0 && $set_c < 65535 } {
                        ::Capture::SetContrast $capture_fd $set_c
                }
                if {[string is integer -strict $set_h] && $set_h > 0 && $set_h < 65535 } {
                        ::Capture::SetHue $capture_fd $set_h
                }
                if {[string is integer -strict $set_co] && $set_co > 0 && $set_co < 65535 } {
                        ::Capture::SetColour $capture_fd $set_co
                }

		#otherwise just get the device settings, also to make sure the above set's are well done		
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
			set img [image create photo [TmpImgName]]
		}
		label $preview -image $img

#		after 0 "::CAMGUI::PreviewLinux $capture_fd $img"

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

		if { ! ([string is integer -strict $new_value] && $new_value > 0 && $new_value < 65535 ) } { return }

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

		set img [image create photo [TmpImgName]]
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

		bind $devs.list <<Button1>> "::CAMGUI::StartPreviewWindows $devs.list $status $preview $settings"

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

		while { [winfo exists $grabber] && [ImageExists $img] } {
			catch {$grabber picture $img}
			after 100 "incr $semaphore"
			tkwait variable $semaphore
		}
	}

	proc getNextKeyframeOffset { filename {offset 0} } {
		set fd [open $filename r]
		seek $fd $offset
		fconfigure $fd -encoding binary -translation binary
		set data [read $fd 1024000]
		# we need to start looking at least after the 12th char otherwise the $advance -12 will give us a negative value in our data.
		set advance [string first "ML20" $data 12]
		if { $advance == -1 } {
			close $fd
			return [file size $filename]
		}
		incr advance -12
		set keyframe 0
		set not_keyframe 1
		while { $keyframe == 0 && $advance < [file size $filename]} {
			binary scan $data @${advance}c@[expr {$advance + 8}]i h_size p_size
			binary scan $data @[expr {$advance + 24 + 12}]c not_keyframe
			if { $h_size == 24 && $not_keyframe == 0 } {
				set keyframe 1
			} else {
				incr advance 24
				incr advance $p_size
			}
		}

		close $fd
		incr offset $advance
		return $offset

	}

	proc ::incr_sem {sem} {
		if { [info exists $sem] } {
			incr $sem
		}
	}

	proc Play { w filename } {
		set img ${w}_img
		::log::updateCamButtonsState $w play
		status_log "Play"

		if { [::config::getKey playbackspeed] == "" } {
			::config::setKey playbackspeed 100
		}
		
		if { ! [info exists ::webcamsn_loaded] } { ::CAMGUI::ExtensionLoaded }
		if { ! $::webcamsn_loaded } { return }
		
		set semaphore ::${img}_semaphore

		if { [info exists $semaphore] } {
			after [::config::getKey playbackspeed] "incr_sem $semaphore"
			return
		}
		if { ![info exists ::seek_val($img)] } {
			set ::seek_val($img) 0
		}

		set $semaphore 0

		set fd [open $filename r]
		fconfigure $fd -encoding binary -translation binary
		#close $fd

		set decoder [::Webcamsn::NewDecoder]

		while { [set ::seek_val($img)] < [file size $filename] } {
			seek $fd [set ::seek_val($img)]
			set data [read $fd 24]
			set size [::MSNCAM::GetCamDataSize $data] 
			set timestamp [::MSNCAM::GetCamDataTimestamp $data] 
			if {$size < 0} {
				set ::seek_val($img) [getNextKeyframeOffset $filename $::seek_val($img)]
				continue
			}
			append data [read $fd $size]

			if { ![info exists $semaphore] } {
				break
			}

			if { [catch { ::Webcamsn::Decode $decoder $img $data} res] } {
				status_log "Play : Decode error $res" red
				set ::seek_val($img) [getNextKeyframeOffset $filename $::seek_val($img)]
				::Webcamsn::Close $decoder
				set decoder [::Webcamsn::NewDecoder]
			} else {
				incr ::seek_val($img) $size
				incr ::seek_val($img) +24
			}
	
			set data [read $fd 24]
			set next_timestamp [::MSNCAM::GetCamDataTimestamp $data] 
			seek $fd -24 current
			if {$next_timestamp == -1} {
				continue
			}
			set diff  [expr {$next_timestamp - $timestamp}]
			if { $diff < 0 || $diff > 5000 } {
				set diff 0 
			}
			set ::webcam_dynamic_rate $diff

			if  { [::config::getKey dynamic_rate 0] && $diff != 0} {
				set next_frame $diff
			} else {
				set next_frame [::config::getKey playbackspeed]
			}

			# Make sure the semaphore wasn't unset during the call to Decode, and that the 'after' gets executed after the 'after cancel' is called..
			after $next_frame "incr_sem $semaphore"
			tkwait variable $semaphore
			
		}
		close $fd
		::Webcamsn::Close $decoder
		catch {unset $semaphore}
		
	}

	proc Resume { w filename } {

		set img ${w}_img
		set semaphore ::${img}_semaphore
		if { [info exists $semaphore] } {
			Play $w $filename
		}

	}

	proc Seek { w filename seek } {
		set img ${w}_img
		status_log "Seek to $seek"


		set ::seek_val($img) $seek


#	 	set semaphore ::${img}_semaphore
# 		if {![info exists $semaphore] } {
# 			# Only set seek_val, which we did already
# 			return
# 		}

# 		# Stop and Start to use new seek value
# 		Stop $w
# 		set ::seek_val($img) $seek
# 		Play $w $filename
	}

	proc Pause { w  } {
		set img ${w}_img
		::log::updateCamButtonsState $w pause
		status_log "Pause"

		set semaphore ::${img}_semaphore
		
		if { ![info exists $semaphore] } {
			return
		}

		after cancel "incr_sem $semaphore"

	}

	proc Stop { w } {
		set img ${w}_img
		::log::updateCamButtonsState $w stop
		status_log "Stop"

		set semaphore ::${img}_semaphore
		
		if { ![info exists $semaphore] } {
			return
		}
		after cancel "incr_sem $semaphore"
		set ::seek_val($img) 0
		catch {unset $semaphore}
		catch {$img blank}
	}	

	proc saveToImage { w } {

		if { [winfo exists $w.saveToImageFormat] } {
			raise $w.saveToImageFormat
			return
		}

		set img ${w}_img

		Pause $w

		set ::${w}_saveToImageFormat "cximage"

		set new_w $w.saveToImageFormat
		toplevel $new_w
		radiobutton $new_w.gif -text "GIF File" -variable ::${w}_saveToImageFormat -value "cxgif"
		radiobutton $new_w.png -text "PNG File" -variable ::${w}_saveToImageFormat -value "cxpng"
		radiobutton $new_w.jpg -text "JPG File" -variable ::${w}_saveToImageFormat -value "cxjpg"
		radiobutton $new_w.tga -text "TGA File" -variable ::${w}_saveToImageFormat -value "cxtga"
		radiobutton $new_w.default -text "Choose from file extension" -variable ::${w}_saveToImageFormat -value "cximage"	
		label $new_w.separator -text " "
		button $new_w.ok -text "[trans save]" -command "destroy $new_w; ::CAMGUI::saveToImageStep2 $w; unset ::${w}_saveToImageFormat"
		pack $new_w.gif $new_w.png $new_w.jpg $new_w.tga $new_w.default $new_w.separator $new_w.ok -side top
	}

	proc saveToImageStep2  { w } {
		set img ${w}_img

		set imgFormat [ set ::${w}_saveToImageFormat ]
		switch -- $imgFormat {
			"cxgif" {
				set type { {"GIF Files" .gif} }
			}
			"cxpng" {
				set type { {"PNG Files" .png} }
			}
			"cxjpg" {
				set type { {"JPEG Files" .jpg} }
			}
			"cxtga" {
				set type { {"TGA Files" .tga} }
			}
			default {
				set type [list [list [trans imagefiles] [list *.gif *.GIF *.jpg *.JPG *.jpeg *.JPEG *.bmp *.BMP *.png *.PNG]]]
			}
		}

		set filename [tk_getSaveFile -filetypes $type]

		if { $filename != "" } {
			$img write $filename -format [set ::${w}_saveToImageFormat]
		}

	}

}

if { $initialize_amsn == 1 } {
	if { [::config::getKey wanttosharecam] && [::CAMGUI::camPresent] == 1 } {
		::MSN::setClientCap webcam
	}
}
