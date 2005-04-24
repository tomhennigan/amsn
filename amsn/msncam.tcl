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
	# AcceptFT ( chatid dest branchuid cseq uid sid filename1 )
	# This function is called when a file transfer is accepted by the user
	proc AcceptWebcam { chatid dest branchuid cseq uid sid producer} {

		setObjOption $sid producer $producer
		setObjOption $sid inviter 0


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


		set h1 "\x80[binary format s [myRand 0 65000]]\x01"
		set h2 "\x08\x00\x08\x00"
		set syn [encoding convertto unicode "\x00syn\x00"]
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

		set h1 "\x80\xea\x00\x00"
		set h2 "\x08\x00\x08\x00"
		set syn [encoding convertto unicode "\00ack\x00"]
		set footer "\x00\x00\x00\x04"
		set msg "${h1}${h2}${syn}"

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


		set h1 "\x80\xec[binary format s [myRand 0 255]]\x03"
		set h2 "\x08\x00\x26\x00"
		set syn [encoding convertto unicode "\00receivedViewerData\x00"]
		set footer "\x00\x00\x00\x04"
		set msg "${h1}${h2}${syn}"

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
		set context "\{B8BE70DE-E2CA-4400-AE03-88FF85B9F4E8\}"
		set context [encoding convertto unicode $context]

		::MSNP2P::SessionList set $sid [list 0 0 0 $dest 0 $callid 0 "webcam" "$context" "$branchid"]

		setObjOption $sid inviter 1
		if { $guid == "4BD96FC0-AB17-4425-A14A-439185962DC8" } {
			setObjOption $sid producer 1
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
			

		if { [catch {set sock [ socket $ip $port] } ] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red 
			return 0
		} else {

			setObjOption $sock rid $rid
			setObjOption $sock sid $sid
			setObjOption $sock session $session
			setObjOption $sock server 0
			setObjOption $sock state "AUTH"

			status_log "connectedto $ip on port $port  - $sock\n" red

			fconfigure $sock -blocking 1 -buffering none -translation {binary binary} 
			fileevent $sock readable "::MSNCAM::ReadFromSock $sock"
			fileevent $sock writable "::MSNCAM::WriteToSock $sock"
			return 1
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
		set sending [getObjOption $sock sending]
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
					if { $data == "recipientrid=$rid&session=$session\r" } {
						gets $sock  
						setObjOption $sock state "RECEIVE"
					} else {
						status_log "ERROR : $data\n" red
					}
				} else {
					gets $sock data 
					if { $data == "connected\r" } {
						gets $sock  
						puts -nonewline $sock "connected\r\n\r\n"
						setObjOption $sock state "RECEIVE"
					} else {
						status_log "ERROR : $data\n" red
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
				status_log "option not defined... receiving data closing..." red
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
				setObjOption $sock state "SEND"
			}
			"SEND"
			{
				
				if { [SendFileToSock $sock] == "0" } {
					setObjOption $sock state "END"
					fileevent $sock writable ""	
				} else {
					fileevent $sock writable "::MSNCAM::WriteToSock $sock"
				}
			}

		}

		if { $data != "" } {
			status_log "Writing Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" red
			puts -nonewline $sock "$data"
		}


		
	}


	proc GetNonceFromData { data } {
		set bnonce [string range $data 32 end]
		binary scan $bnonce H2H2H2H2H2H2H2H2H4H* n1 n2 n3 n4 n5 n6 n7 n8 n9 n10
		set nonce [string toupper "$n4$n3$n2$n1-$n6$n5-$n8$n7-$n9-$n10"]
		status_log "Got NONCE : $nonce\n" red
		return $nonce
		
	}

	proc GetDataFromNonce { nonce sid } {

		status_log "GetDataFromNonce\n"

		set n1 [string range $nonce 6 7]
		set n2 [string range $nonce 4 5]
		set n3 [string range $nonce 2 3]
		set n4 [string range $nonce 0 1]
		set n5 [string range $nonce 11 12]
		set n6 [string range $nonce 9 10]
		set n7 [string range $nonce 16 17]
		set n8 [string range $nonce 14 15]
		set n9 [string range $nonce 19 22]
		set n10 [string range $nonce 24 end]

		set nonce [string toupper "$n4$n3$n2$n1-$n6$n5-$n8$n7-$n9-$n10"]
		#		status_log "Got NONCE : $nonce\n" red

		set bnonce [binary format H2H2H2H2H2H2H2H2H4H* $n1 $n2 $n3 $n4 $n5 $n6 $n7 $n8 $n9 $n10]
		status_log "got Binary NONCE : $bnonce\n" red

		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]
		incr MsgId


		set data "[binary format iiiiiiii 0 $MsgId 0 0 0 0 0 256]$bnonce"
		incr MsgId
		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]

		return $data

	}

	proc WriteDataToFile { data } {

		#puts -nonewline $data
		return

		binary scan [string range $data 0 47] iiiiiiiiiiii cSid cId cOffset1 cOffset2 cTotalDataSize1 cTotalDataSize2 cMsgSize cFlags cAckId cAckUID cAckSize1 cAckSize2


		if { ![info exists cAckSize2] } {
			return
		}

		set fd [lindex [::MSNP2P::SessionList get $cSid] 6]
		set cOffset [int2word $cOffset1 $cOffset2]
		set cTotalDataSize [int2word $cTotalDataSize1 $cTotalDataSize2]
		set cAckSize [int2word $cAckSize1 $cAckSize2]

		set cRemaining [expr $cTotalDataSize - $cOffset - $cMsgSize]

		if { [catch { puts -nonewline "[string range $data 48 end]" } res] } {
			status_log "ERROR WRITING DATA TO FILE : $fd - $data\n" red
		}
		

		#status_log "Received data : remainging $cRemaining\n" 
		
		if {$cRemaining == 0 } {
			catch {close $fd}
		}
		return $cRemaining


	}

	proc SendByeAck { sock data } {
	
		set sid [getObjOption $sock sid]

		binary scan [string range $data 0 47] iiiiiiiiiiii cSid cId cOffset1 cOffset2 cTotalDataSize1 cTotalDataSize2 cMsgSize cFlags cAckId cAckUID cAckSize1 cAckSize2

		if { ![info exists cAckSize2] } {
			return
		}

		set cOffset [int2word $cOffset1 $cOffset2]
		set cTotalDataSize [int2word $cTotalDataSize1 $cTotalDataSize2]
		set cAckSize [int2word $cAckSize1 $cAckSize2]

		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]
		incr MsgId
		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]


		set out [binary format ii 0 $MsgId][binword 0][binword $cTotalDataSize][binary format iiii 0 2 $cId $cAckId][binword $cTotalDataSize]


		puts -nonewline $sock "[binary format i 48]$out"
		status_log "Sending Bye ACK :  $out\n" red


	}

	proc SendDataAck { sock data } {
			
		set sid [getObjOption $sock sid]

		binary scan [string range $data 0 47] iiiiiiiiiiii cSid cId cOffset1 cOffset2 cTotalDataSize1 cTotalDataSize2 cMsgSize cFlags cAckId cAckUID cAckSize1 cAckSize2

		if { ![info exists cAckSize2] } {
			return
		}

		set cOffset [int2word $cOffset1 $cOffset2]
		set cTotalDataSize [int2word $cTotalDataSize1 $cTotalDataSize2]
		set cAckSize [int2word $cAckSize1 $cAckSize2]
		
		set SessionInfo [::MSNP2P::SessionList get $sid]
		set MsgId [lindex $SessionInfo 0]
		set Destination [lindex $SessionInfo 3]
		incr MsgId
		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]

		set out [binary format ii $sid $MsgId][binword 0][binword $cTotalDataSize][binary format iiii 0 2 $cId $cAckId][binword $cTotalDataSize]

		status_log "Writing ack on sock $sock : $out\n" red

		puts -nonewline $sock "[binary format i [string length $out]]$out"
	}
	
	proc SendDataBye { sock } {
		
		set sid [getObjOption $sock sid]

		set SessionInfo [::MSNP2P::SessionList get $sid]
		set dest [lindex $SessionInfo 3]
		set callid [lindex $SessionInfo 5]
		set branchid [lindex $SessionInfo 9]

		set MsgId [lindex $SessionInfo 0]
		incr MsgId

	        set bye [::MSNP2P::MakeMSNSLP "BYE" $dest [::config::getKey login] $branchid 0 $callid 0 0]
		set size [string length $bye]

		set bheader [binary format ii 0 $MsgId][binword 0][binword $size][binary format iiii $size 0 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]


		return "${bheader}${bye}"

	}

	proc CloseSocket { sock } {

		set sid [getObjOption $sock sid]
	
		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]

		set bheader [binary format ii 0 $MsgId][binword 0][binword 0][binary format iiii 0 4 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]

		puts -nonewline $sock "[binary format i 48]$bheader"
		status_log "Closing socket... \n" red
		close $sock

	}


	proc SendFileToSock  { sock } {

		return 0

	
		set sid [getObjOption $sock sid]
	
		set fd [lindex [::MSNP2P::SessionList get $sid] 6]
		if { $fd == 0 || $fd == "" } {
			set filename [lindex [::MSNP2P::SessionList get $sid] 8]
			set fd [open "${filename}"]
			::MSNP2P::SessionList set $sid [list -1 [file size "${filename}"] -1 -1 -1 -1 $fd -1 -1 -1]
			fconfigure $fd -translation {binary binary}
		}

		#		status_log "Sending file with fd : $fd\n" red

		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]
		set DataSize [lindex [::MSNP2P::SessionList get $sid] 1]
		set Offset [lindex [::MSNP2P::SessionList get $sid] 2]

		if {$DataSize == 0 } {
			status_log "Correcting DataSize\n" green
			set filename [lindex [::MSNP2P::SessionList get $sid] 8]
			set DataSize [file size "${filename}"]
			::MSNP2P::SessionList set $sid [list -1 $DataSize -1 -1 -1 -1 $fd -1 -1 -1]	
		}

		set data [read $fd 1352]
		set out "[binary format iiiiiiiiiiii $sid $MsgId $Offset 0 $DataSize 0 [string length $data] 16777264 [expr int([expr rand() * 1000000000])%125000000 + 4] 0 0 0]$data"

		catch { puts -nonewline $sock  "[binary format i [string length $out]]$out" }

		::amsn::FTProgress s $sid "" [expr $Offset + [string length $data]] $DataSize
		#status_log "Writing file to socket $sock, send $Offset of $DataSize\n" red

		set Offset [expr $Offset + [string length $data]]

		::MSNP2P::SessionList set $sid [list -1 -1 $Offset -1 -1 -1 -1 -1 -1 -1]

		#		status_log "Sending : $out"

		if { [expr $DataSize - $Offset] == "0"} {
			catch { close $fd }
			::amsn::FTProgress fs $sid ""
		}

		return [expr $DataSize - $Offset]
	}


	proc GotFileTransferRequest { chatid dest branchuid cseq uid sid context } {
		binary scan [string range $context 0 3] i size
		binary scan [string range $context 8 11] i filesize
		binary scan [string range $context 16 19] i nopreview
		
		binary scan $context x20A[expr $size - 24] filename

		set filename [ToBigEndian "$filename\x00" 2]
		set filename [encoding convertfrom unicode "$filename"]


		if { $nopreview == 0 } {
			set previewdata [string range $context $size end]
			set dir [file join [set ::HOME] FT cache]
			create_dir $dir
			set fd [open "[file join $dir ${sid}.png ]" "w"]
			fconfigure $fd -translation binary
			puts -nonewline $fd "$previewdata"
			close $fd
			set file [png_to_gif [file join $dir ${sid}.png]]
			if { $file != "" } {
				set file [filenoext $file].gif
				::skin::setPixmap FT_preview_${sid} "[file join $dir ${sid}.gif]"
			}
		}

		status_log "context : $context \n size : $size \n filesize : $filesize \n nopreview : $nopreview \nfilename : $filename\n"
		::MSNFT::invitationReceived $filename $filesize $sid $chatid $dest 1
		::amsn::GotFileTransferRequest $chatid $dest $branchuid $cseq $uid $sid $filename $filesize

	}


	
	
	#//////////////////////////////////////////////////////////////////////////////
	# CancelFT ( chatid sid )
	# This function is called when a file transfer is canceled by the user
	proc CancelFT { chatid sid } {
		set session_data [::MSNP2P::SessionList get $sid]
		set user_login [lindex $session_data 3]
		
		status_log "MSNP2P | $sid -> User canceled FT, sending BYE to chatid : $chatid and SB : [::MSN::SBFor $chatid]\n" red
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] "19A50529-4196-4DE9-A561-D68B0BF1E83F" 0 [lindex $session_data 5] 0 0] 1]
		::amsn::FTProgress ca $sid [lindex [::MSNP2P::SessionList get $sid] 6]

		# Change sid type to canceledft
		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 -1 -1 -1 "ftcanceled" -1 -1]
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
		set xml [encoding convertfrom unicode $xml]
		set xml [string map  { "\r\n\r\n\x00" ""} $xml]

		status_log "Got XML : $xml\n" red


		set list [xml2list $xml]

		set session [GetXmlEntry $list "session"]
		set rid [GetXmlEntry $list "rid"]
		set tcpport [GetXmlEntry $list "tcpport"]


		status_log "Found session $session and rid $rid\n" red
		

		setObjOption $sid session $session
		setObjOption $sid rid $rid

		connectMsnCam $sid $session $rid "192.168.1.201" $tcpport

		if { $inviter } {
			SendReceivedViewerData $chatid $sid
		} else {
			status_log "::MSNCAM::SendXML $chatid $sid" red
			SendXML $chatid $sid
		}


	}

	proc SendXML { chatid sid } {
		set producer [getObjOption $sid producer]
		set inviter [getObjOption $sid inviter]

		set xml [CreateInvitationXML $sid]
		set xml [encoding convertto unicode $xml]

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

		::Webcamsn::Decode $decoder $img $data
		

	}

	proc ExtensionLoaded { } {
		if { [info exists ::webcamsn_loaded] && $::webcamsn_loaded } { return 1}

		catch {package require webcamsn}

		foreach lib [info loaded] {
			if { [lindex $lib 1] == "Webcamsn" } {
				set ::webcamsn_loaded 1
				return 1
			} 
		}
		return 0
	}

}



