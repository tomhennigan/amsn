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
		status_log "branchid : [lindex [::MSNP2P::SessionList get $sid] 9]\n"

		
		
		# Create and send our packet
		set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 0 $callid 0 0 $guid $sid 4 \
				 [string map { "\n" "" } [::base64::encode "$context"]]]
		::MSNP2P::SendPacketExt [::MSN::SBFor $chatid] $sid $slpdata 1
		status_log "Sent an INVITE to [::MSN::usersInChat $chatid]  on chatid $chatid for webcam\n" red
		
	}

	proc AskWebcam { chatid } {
		SendInvite $chatid "1C9AA97E-9C05-4583-A3BD-908A196F1E92"
	}

	#//////////////////////////////////////////////////////////////////////////////
	# AcceptFT ( chatid dest branchuid cseq uid sid filename1 )
	# This function is called when a file transfer is accepted by the user
	proc AcceptWebcam { chatid dest branchuid cseq uid sid } {

		# Let's make and send a 200 OK Message
		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr $cseq + 1] $uid 0 0 $sid]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

		SendAcceptInvite $sid $chatid
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

		set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 0 $callid 0 1 "TRUDPv1 TCPv1" \
				 $netid $conntype $upnp "false"]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
		
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
			set port [OpenCamPort [config::getKey initialftport] $nonce $sid 1]
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

	proc answerCamInvite { sid chatid branchid } {
		
		
		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 -1 -1 -1 -1 -1 "$branchid" ]
		set session [::MSNP2P::SessionList get $sid]
		set dest [lindex $session 3]
		set callid [lindex $session 5]

		set conntype [abook::getDemographicField conntype]

		set listening [abook::getDemographicField listening]
		#set listening "false"

		if {$listening == "true" } {
			set nonce "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
			set port [OpenCamPort [config::getKey initialftport] $nonce $sid 0]
			set clientip [::abook::getDemographicField clientip]
			set localip [::abook::getDemographicField localip]
		} else {
			set nonce "00000000-0000-0000-0000-000000000000"
			set port ""
			set clientip ""
			set localip ""
		}

		set clientip $localip

		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchid 1 $callid 0 2 "TCPv1" "$listening" "$nonce" "$clientip"\
				 "$port" "$localip" "$port"]

		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

	}

	proc OpenCamPort { port nonce sid sending} {
		while { [catch {set sock [socket -server "::MSNCAM::handleMsnCam  $nonce $sid $sending" $port] } ] } {
			incr port
		}
		status_log "Opening server on port $port\n" red
		return $port
	}
	
	proc handleMsnCam { nonce sid sending sock ip port } {

		setObjOption $sock nonce $nonce
		setObjOption $sock sid $sid
		setObjOption $sock sending $sending
		setObjOption $sock server 1
		setObjOption $sock state "FOO"

		status_log "Received connection from $ip on port $port - socket $sock\n" red
		fconfigure $sock -blocking 1 -buffering none -translation {binary binary} 

		fileevent $sock readable "::MSNCAM::ReadFromSock $sock"
		#fileevent $sock writable "::MSN6FT::WriteToSock $sock"		
	}




	proc connectMsnCam { sid nonce ip port sending } {
			

		if { [catch {set sock [ socket $ip $port] } ] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red 
		} else {

			setObjOption $sock nonce $nonce
			setObjOption $sock sid $sid
			setObjOption $sock sending $sending
			setObjOption $sock server 0
			setObjOption $sock state "FOO"

			status_log "connectedto $ip on port $port  - $sock\n"
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


		set size [read $sock 4]

		if {$size == "" && [eof $sock] } {
			status_log "WebCam Socket $sock closed\n"
			close $sock
			return
		}

		if { $size == "" } {
			update idletasks
			return
		}

		binary scan $size i size
		set data [read $sock $size]

		status_log "Received Data on socket $sock sending=$sending - server=$server - state=$state : \n$data\n" red

		if { $data == "" } {
			update idletasks
			return
		}

		switch $state {
			"FOO"
			{
				if { $server } {
					if { $data == "foo\x00" } {
						setObjOption $sock state "GET_NONCE"
					}
				}
			}
			
			"GET_NONCE"
			{
				if { $nonce == [GetNonceFromData $data]} {
					::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "DATASEND" -1 -1 -1 -1 -1]

					if { $server } {
						setObjOption $sock state "SEND_NONCE"
						fileevent $sock writable "::MSNCAM::WriteToSock $sock"
					} else {
						if {$sending } {
							setObjOption $sock state "SEND_NONCE"
							fileevent $sock writable "::MSNCAM::WriteToSock $sock"	
						} else {
							setObjOption $sock state "RECEIVE"
						}
					}
				}
			}

			"RECEIVE"
			{
				if { [WriteDataToFile $data] == "0" } {
					SendDataAck $sock $data
					setObjOption $sock state "END"

				}
			}

			default 
			{
				status_log "option not defined... receiving data closing..." red
				setObjOption $sock state "END"
				close $sock
			}

		}

		

	}
	proc WriteToSock { sock } { 

		set nonce [getObjOption $sock nonce]
		set sid [getObjOption $sock sid]
		set sending [getObjOption $sock sending]
		set server [getObjOption $sock server]
		set state [getObjOption $sock state]


		fileevent $sock writable ""


		set data ""

		switch $state {

			"FOO"
			{
				if { $server == 0} {
					set data "[binary format i 4]foo\x00"
					setObjOption $sock state "SEND_NONCE"
					fileevent $sock writable "::MSNCAM::WriteToSock $sock"
				}
			}

			"SEND_NONCE"
			{
				set data "[binary format i 48][GetDataFromNonce $nonce $sid]"
				if { $server } {
					if {$sending } {
						setObjOption $sock state "SEND_SYN"
						fileevent $sock writable "::MSNCAM::WriteToSock $sock"	
					} else {
						setObjOption $sock state "RECEIVE"
					}
				} else {
					setObjOption $sock state "GET_NONCE"
				}
				
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

}

