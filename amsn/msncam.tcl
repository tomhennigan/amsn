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
	namespace export SendFT AcceptFT RejectFT handleMsnFT
	
	
	#//////////////////////////////////////////////////////////////////////////////
	# CancelFT ( chatid sid )
	# This function is called when a file transfer is canceled by the user
	proc CancelCam { chatid sid } {
		set session_data [::MSNP2P::SessionList get $sid]
		set user_login [lindex $session_data 3]
	    set callid [lindex $session_data 5]
	    set socket [getObjOption $sid socket]
		
	    set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"


		status_log "Canceling webcam $sid with $chatid \n" red
	    ::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] $branchid 0 $callid 0 1 "dAMAgQ==\r\n"] 1]
	
	    if { $socket != "" } {
		status_log "Connected through socket $socket : closing socket\n" red
		catch { close $socket}
	    }
	    
		
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

		if { $producer } {
		    setObjOption $sid source 0
		}

		# Let's make and send a 200 OK Message
		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr $cseq + 1] $uid 0 0 $sid]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

		SendAcceptInvite $sid $chatid
		status_log "::MSNCAM::SendAcceptInvite $sid $chatid\n" green
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

	proc AskWebcam { chatid } {
		SendInvite $chatid "1C9AA97E-9C05-4583-A3BD-908A196F1E92"
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
		if { $guid == "4BD96FC0-AB17-4425-A14A-439185962DC8" } {
			setObjOption $sid producer 1
	
		    setObjOption $sid source 0
	
		} else {
			setObjOption $sid producer 0
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

	proc SendFinalInvite { sid chatid} {
		
		set session [::MSNP2P::SessionList get $sid]
		set branchid [lindex $session 9]
		set callid [lindex $session 5]

		set dest [lindex $session 3]
		set conntype [abook::getDemographicField conntype]

		set listening [abook::getDemographicField listening]

		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "INVITE2" -1 -1 -1 -1 -1]

		if {$listening == "true" } {
			set nonce "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
			set port [OpenCamPort2 [config::getKey initialftport] $nonce $sid 1]
			set clientip [::abook::getDemographicField clientip]
			set localip [::abook::getDemographicField localip]
		} else {
			set nonce "00000000-0000-0000-0000-000000000000"
			set port ""
			set clientip ""
			set localip ""
		}

		set clientip $localip

		if { $listening == "true" } {
			set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 1 $callid 0 2 "TCPv1" "$listening" "$nonce" "$clientip"\
					 "$port" "$localip" "$port"]
			::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
			#after 5000 "::MSNP2P::SendDataFile $sid $chatid [list [lindex [::MSNP2P::SessionList get $sid] 8]] \"INVITE2\""
		} else {
			
			#after 5000 "::MSNP2P::SendDataFile $sid $chatid [list [lindex [::MSNP2P::SessionList get $sid] 8]] \"INVITE2\""
		}
	}



	proc OpenCamPort { port rid session sid} {
		while { [catch {set sock [socket -server "::MSNCAM::handleMsnCam $sid $rid $session" $port] } ] } {
			incr port
		}
		status_log "Opening server on port $port\n" red
		return $port
	}
	
	proc OpenCamPort2 { port nonce sid sending} {
		while { [catch {set sock [socket -server "::MSNCAM::handleMsnCam2 $sid $nonce $sending" $port] } ] } {
			incr port
		}
		status_log "Opening server on port $port\n" red
		return $port
	}

	proc handleMsnCam { sid rid session sock ip port } {
		setObjOption $sock rid $rid
		setObjOption $sock session $session
		setObjOption $sock sid $sid
		setObjOption $sock server 1
		setObjOption $sock state "AUTH"

		status_log "Received connection from $ip on port $port - socket $sock\n" red
		fconfigure $sock -blocking 1 -buffering none -translation {binary binary} 

		fileevent $sock readable "::MSNCAM::ReadFromSock $sock"
		#fileevent $sock writable "::MSN6FT::WriteToSock $sock"		
	}

	proc handleMsnCam2 { sid nonce sending sock ip port } {
		setObjOption $sock sending $sending
		setObjOption $sock nonce $nonce
		setObjOption $sock sid $sid
		setObjOption $sock server 1
		setObjOption $sock state "FOO"

		status_log "Received connection from $ip on port $port - socket $sock\n" red
		fconfigure $sock -blocking 1 -buffering none -translation {binary binary} 

		fileevent $sock readable "::MSNCAM::ReadFromSock $sock"
		#fileevent $sock writable "::MSN6FT::WriteToSock $sock"		
	}



	proc connectMsnCam { sid session rid ip port } {
			

		if { [catch {set sock [socket -async $ip $port] } ] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red 
			return 0
		} else {

			setObjOption $sock rid $rid
			setObjOption $sock sid $sid
			setObjOption $sock session $session
			setObjOption $sock server 0
			setObjOption $sock state "AUTH"

			status_log "connectedto $ip on port $port  - $sock\n" red

			return $sock
		}
	}


	proc connectMsnCam2 { sid nonce ip port sending } {
			

		if { [catch {set sock [ socket $ip $port] } ] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red 
		} else {

			setObjOption $sock nonce $nonce
			setObjOption $sock sid $sid
			setObjOption $sock sending $sending
			setObjOption $sock server 0
			setObjOption $sock state "FOO"

			status_log "connectedto $ip on port $port  - $sock\n" red

			fconfigure $sock -blocking 1 -buffering none -translation {binary binary} 
			fileevent $sock readable "::MSNCAM::ReadFromSock $sock"
			fileevent $sock writable "::MSNCAM::WriteToSock $sock"
		}
	}


	proc ReadFromSock { sock } { 
		set nonce [getObjOption $sock nonce]
		set sid [getObjOption $sock sid]
		set producer [getObjOption $sid producer]
		set server [getObjOption $sock server]
		set state [getObjOption $sock state]

		set rid [getObjOption $sock rid]
		set session [getObjOption $sock session]


	#	set size [read $sock 4]

	 	if { [eof $sock] } {
 			status_log "WebCam Socket $sock closed\n"
 			close $sock
 			return
 		}

# 		if { $size == "" } {
# 			update idletasks
# 			return
# 		}

# 		binary scan $size i size
# 		set data [read $sock $size]

		#set data [read $sock]
		set data ""
		#status_log "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" red
	
		#if { $data == "" } {
		#	update idletasks
		#	return
		#}

		switch $state {

			"AUTH" 
			{
				if { $server } {
					gets $sock data 
					if { $data == "recipientid=$rid&sessionid=$session\r" } {
					    status_log "Received Data on socket $sock sending=$producer - server=$server - state=$state : \n$data\n" red
						gets $sock  
						setObjOption $sock state "CONNECTED"
						fileevent $sock writable "::MSNCAM::WriteToSock $sock"
					}
				}	
			}
			"CONNECTED"
			{
				if { $server } {
					gets $sock data 
					status_log "Received Data on socket $sock sending=$producer - server=$server - state=$state : \n$data\n" red

					if { $data == "connected\r" } {
					    gets $sock  
					    setObjOption $sid socket $sock
					    if { $producer } {
						setObjOption $sock state "SEND"
						fileevent $sock writable "::MSNCAM::WriteToSock $sock"
					    } else {
						setObjOption $sock state "RECEIVE"
					    }
					} else {
						status_log "ERROR1 : $data\n" red
					}

				} else {
					gets $sock data 
					status_log "Received Data on socket $sock sending=$producer - server=$server - state=$state : \n$data\n" red
					if { $data == "connected\r" } {
						gets $sock  
					    setObjOption $sid socket $sock
						puts -nonewline $sock "connected\r\n\r\n"
						status_log "Sending \"connected\" to the server\n" red
						if { $producer } {
							setObjOption $sock state "SEND"
							fileevent $sock writable "::MSNCAM::WriteToSock $sock"
						} else {
							setObjOption $sock state "RECEIVE"
						}
					} else {
						status_log "ERROR2 : $data\n" red
					}
				}
			}

			"RECEIVE"
			{
				set header [read $sock 24]
				set size [GetCamDataSize $header]
				if { $size > 0 } {
					set data "$header[read $sock $size]"
					ShowCamFrame $sid $data
				}
			
			}

			default 
			{
				status_log "option $state not defined... receiving data closing... : \n$data\n" red
				setObjOption $sock state "END"
				close $sock
			}

		}

		#puts  "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" 
		#status_log "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" red

		

	}
	proc WriteToSock { sock } { 

		set nonce [getObjOption $sock nonce]
		set sid [getObjOption $sock sid]
		set sending [getObjOption $sock sending]
		set server [getObjOption $sock server]
		set state [getObjOption $sock state]

		set rid [getObjOption $sock rid]
		set session [getObjOption $sock session]

		fileevent $sock writable ""

		if { [fconfigure $sock -error] != "" } {
			status_log "ERROR writing to socket!!!" red
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
			}
			"SEND"
			{
				after 100 "::MSNCAM::GetCamFrame $sid $sock"
				#fileevent $sock writable "::MSNCAM::WriteToSock $sock"
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

		set rid [getObjOption $sid rid]
		if { $rid == "" } {
			set rid [myRand 100 199]
		}
		set udprid [expr {$rid + 1}]
		set conntype [abook::getDemographicField conntype]
		set listening [abook::getDemographicField listening]

		set producer [getObjOption $sid producer]


		if {$listening == "true" } {
			set port [OpenCamPort [config::getKey initialftport] $rid $session $sid]
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
		set tcp "<tcp><tcpport>$port</tcpport>								<tcplocalport>$port</tcplocalport>								<tcpexternalport>$port</tcpexternalport><tcpipaddress1>$clientip</tcpipaddress1></tcp>"
		set udp "<udp><udplocalport>0</udplocalport><udpexternalport>0</udpexternalport><udpexternalip>$clientip</udpexternalip><a1_port>$port</a1_port><b1_port>$port</b1_port><b2_port>$port</b2_port><b3_port>$port</b3_port><symmetricallocation>0</symmetricallocation><symmetricallocationincrement>0</symmetricallocationincrement><udpinternalipaddress1>$localip</udpinternalipaddress1></udp>"
		set footer "<codec></codec><channelmode>1</channelmode>"

		set xml "${begin_type}${header}${tcp}${footer}${end_type}\r\n\r\n\x00"
		
		#set xml "<viewer><version>2.0</version><rid>$rid</rid><session>$session</session><ctypes>0</ctypes><cpu>730</cpu><tcp><tcpport>33762</tcpport>								<tcplocalport>9049</tcplocalport>								<tcpexternalport>33762</tcpexternalport><tcpipaddress1>192.168.1.1</tcpipaddress1><tcpipaddress2>$clientip</tcpipaddress2></tcp><udp><udplocalport>62037</udplocalport><udpexternalport>62037</udpexternalport><udpexternalip>$clientip</udpexternalip><a1_port>41635</a1_port><b1_port>62037</b1_port><b2_port>62037</b2_port><b3_port>62037</b3_port><symmetricallocation>0</symmetricallocation><symmetricallocationincrement>0</symmetricallocationincrement><udpinternalipaddress1>192.168.1.1</udpinternalipaddress1></udp><codec></codec><channelmode>1</channelmode></viewer>\r\n\r\n\x00"

		return $xml

	}

	proc ReceivedXML {chatid sid } {
		set producer [getObjOption $sid producer]
		set inviter [getObjOption $sid inviter]

		set xml [getObjOption $sid xml]
		set xml [FromUnicode $xml]
		set xml [string map  { "\r\n\r\n\x00" ""} $xml]

		status_log "Got XML : $xml\n" red


		set list [xml2list $xml]

		set session [GetXmlEntry $list "session"]
		set rid [GetXmlEntry $list "rid"]
		set tcpport [GetXmlEntry $list "tcpport"]


		status_log "Found session $session and rid $rid\n" red
		

		setObjOption $sid session $session
		setObjOption $sid rid $rid

	
		set ip_idx 7 
		set ips [list]
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
						set socket [connectMsnCam $sid $session $rid "$ip" $port]
						if { $socket != 0 } {
							lappend ips [list $ip $port $socket]
						}
					}
				}
			}

		
		    incr ip_idx -1
		}

		
		if { $producer } {
			SendReceivedViewerData $chatid $sid
		} else {
			status_log "::MSNCAM::SendXML $chatid $sid" red
			SendXML $chatid $sid
		}

		setObjOption $sid ips $ips

		set connected 0
		status_log "the ips : $ips\n" red
		for {set idx 0} { $idx < [llength $ips] } {incr idx} {
			set connection [lindex $ips $idx]
			set ip [lindex $connection 0]
			set port [lindex $connection 1]
			set sock [lindex $connection 2]

			
			catch {fconfigure $sock -blocking 1 -buffering none -translation {binary binary} }
			fileevent $sock readable "::MSNCAM::CheckConnected $sid $sock "
			fileevent $sock writable "::MSNCAM::CheckConnected $sid $sock "
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
			for {set idx 0} { $idx < [llength $ips] } {incr idx } {
				set connection [lindex $ips $idx]
				set ip [lindex $connection 0]
				set port [lindex $connection 1]
				set sock [lindex $connection 2]
				
				if {$sock == $socket } { 
					set ips [lreplace $ips $idx $idx]
					setObjOption $sid ips $ips
					break
				}
			}

		} else {
			status_log "Connected on socket $socket : [eof $socket] || [fconfigure $socket -error]\n" red

			fileevent $socket readable "::MSNCAM::ReadFromSock $socket"
			fileevent $socket writable "::MSNCAM::WriteToSock $socket"

			set ips [getObjOption $sid ips]
			for {set idx 0 } { $idx < [llength $ips] } {incr idx } {
				set connection [lindex $ips $idx]
				set ip [lindex $connection 0]
				set port [lindex $connection 1]
				set sock [lindex $connection 2]
				
				if {$sock == $socket } { continue }

				fileevent $sock readable ""
				fileevent $sock writable ""	

				catch {close $sock}
			}


			
		}
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

	proc ShowCamFrame { sid data } {
		if { ! [info exists ::webcamsn_loaded] } { ExtensionLoaded }
		if { ! $::webcamsn_loaded } { return }

		set window [getObjOption $sid window]
		set decoder [getObjOption $sid codec]

		if { $decoder == "" } {
			set decoder [::Webcamsn::NewDecoder]
			setObjOption $sid codec $decoder
		}

		if { $window == "" } {
			set window .webcam_$sid
			toplevel $window
			set img [image create photo]
			label $window.l -image $img
			pack $window.l

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


		set window [getObjOption $sid window]
		set img [getObjOption $sid image]
		set encoder [getObjOption $sid codec]
	    set grabber .grabber
	    set grab_proc [getObjOption $sid grab_proc]

	    if { $encoder == "" } {
		set encoder [::Webcamsn::NewEncoder HIGH]
		setObjOption $sid codec $encoder
	    }

		if { $window == "" } {
			set window .webcam_$sid
			toplevel $window
			set img [image create photo]
			label $window.l -image $img
			pack $window.l

			setObjOption $sid window $window
			setObjOption $sid image $img
		}

	    if { ![winfo exists $grabber] } {
			if { [set ::tcl_platform(platform)] == "windows" } {
				set grabber [tkvideo $grabber]
				set source [getObjOption $sid source]
				$grabber configure -source $source
				$grabber start
				setObjOption $sid grab_proc "Grab_Windows"
		
			} elseif { [set ::tcl_platform(os)] == "Darwin" } {
				set grabber [seqgrabber $grabber]
				setObjOption $sid grab_proc "Grab_Mac"
			} else {
				return
			}
			setObjOption $sid grabber $grabber
		set grab_proc [getObjOption $sid grab_proc]
		status_log "grab_proc is $grab_proc - [getObjOption $sid grab_proc]\n" red
	    }

	    if { $grab_proc == "" } {
		if { [set ::tcl_platform(platform)] == "windows" } {
		    setObjOption $sid grab_proc "Grab_Windows"
		
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
		    setObjOption $sid grab_proc "Grab_Mac"
		} else {
		    return
		}
		set grab_proc [getObjOption $sid grab_proc]
		status_log "grab_proc is $grab_proc - [getObjOption $sid grab_proc]\n" red
	    }

	    $grab_proc $grabber $socket $encoder $img

	}
	proc SendFrame { sock encoder img } {

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

	proc Grab_Windows {grabber socket encoder img} {
		if { ![catch { $grabber picture $img} res] } {
			SendFrame $socket $encoder $img
		} else {
		    status_log "error grabbing : $res\n" red
		}
	    catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
	}

	proc Grab_Mac { grabber socket encoder img } {
		$grabber image "::MSNCAM::ImageReady_Mac" $img
		::MSNCAM::ImageReady_Mac $socket $encoder $grabber $img
	    catch {fileevent $socket writable "::MSNCAM::WriteToSock $socket"}
	}

	proc ImageReady_Mac {socket encoder w img } {
		SendFrame $socket $encoder $img
	}

	proc CaptureLoaded { } {
		if { [info exists ::capture_loaded] && $::capture_loaded } { return 1}

		if { [set ::tcl_platform(platform)] == "windows" } {
			set extension "tkvideo"
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			set extension "QuickTimeTcl"
		} else {
			set ::capture_loaded 0
			return
		}

		if { [catch {package require $extension}] } { 
			set ::capture_loaded 0
			return 0	
		} else {
			set ::capture_loaded 1
			return 1
		}

	}
	proc ExtensionLoaded { } {
		if { [info exists ::webcamsn_loaded] && $::webcamsn_loaded } { return 1}

		catch {package require webcamsn}


		if { [catch {package require webcamsn}] } { 
			set ::webcamsn_loaded 0
			return 0	
		} else {
			set ::webcamsn_loaded 1
			return 1
		}
	}

}



