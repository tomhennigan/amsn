################## MSNGames #######################
## MSN-Games communication and plugin interface  ##
##                                               ##
## written by Mirko Hansen (BaaaZen)             ##
###################################################


::Version::setSubversionId {$Id$}

namespace eval ::MSNGames {
	proc IncomingGameRequest {chatid dest branchuid cseq uid sid context} {
		set gameinfo [split $context ";"]
		status_log "game request: $context" green
	
		if {[llength $gameinfo] == 3} {
			#check if we have a fitting plugin for this game
			set appId [string range [lindex $gameinfo 0] [expr [string length [lindex $gameinfo 0]] - 4] end]
			if {[::MSNGamesPlugins::supportedGame $appId] == 1} {
				SendMessageFIFO [list ::MSNGamesGUI::IncomingGameRequestShow $chatid $dest $branchuid $cseq $uid $sid $gameinfo] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
			} else {
				#no plugin found, so warn the user and abort request
				SendMessageFIFO [list ::MSNGamesGUI::IncomingGameRequestInvalid $chatid $dest $branchuid $cseq $uid $sid $gameinfo] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
			
				# abort invitation
				::MSN::ChatQueue $chatid [list ::MSN6FT::RejectFT $chatid $sid $branchuid $uid]
			}
		} else {
			status_log "WARNING: game context format is invalid: $context" red

			#seems like the format of the context is invalid, so abort request
			::MSN::ChatQueue $chatid [list ::MSN6FT::RejectFT $chatid $sid $branchuid $uid]
		}
	}
	
	proc SendInviteQueue {appId chatid} {
		::MSN::ChatQueue $chatid [list ::MSNGames::SendInvite $appId $chatid]
	}
	
	proc SendInvite {appId chatid} {
		set gameName [::MSNGamesPlugins::getName $appId]
		set localecode [::config::getKey localecode [::config::getKey localecode_autodetect 1033]]
	
		set guid "6A13AF9C-5308-4F35-923A-67E8DDA40C2F"
		set context "$localecode$appId;1;$gameName"
	
		if {[::ChatWindow::For $chatid]==0} {
			::amsn::chatUser $chatid
		}

		status_log "Sending Game $gameName Request\n"

		set sid [expr {int([expr {rand() * 1000000000}])%125000000 + 4}]
		# Generate BranchID and CallID
		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

		set dest [lindex [::MSN::usersInChat $chatid] 0]

		# This is a fixed value... it must be that way or the invite won't work
		set context [ToUnicode $context]

		::MSNP2P::SessionList set $sid [list 0 0 0 $dest 0 $callid 0 "game" "$context" "$branchid"]

		setObjOption $sid inviter 1
		setObjOption $sid chatid $chatid
		setObjOption $sid reflector 0
		setObjOption $sid appid $appId
		setObjOption $sid completeappid "$localecode$appId"

		::MSNGamesGUI::InvitationSent $chatid $sid $appId $gameName

		status_log "branchid : [lindex [::MSNP2P::SessionList get $sid] 9]\n"

		# Create and send our packet
		set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 0 $callid 0 0 $guid $sid 4 \
				 [string map { "\n" "" } [::base64::encode "$context"]]]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
		status_log "Sent an INVITE to [::MSN::usersInChat $chatid]  on chatid $chatid for game $gameName\n" red
	}
	
	proc SendInvite2 {sid chatid} {
		set session [::MSNP2P::SessionList get $sid]
		set branchid [lindex $session 9]
		set callid [lindex $session 5]
		set dest [lindex $session 3]
		set conntype [abook::getDemographicField conntype]
		
		set listening [abook::getDemographicField listening]
		#set listening "false"

		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "INVITE2" -1 -1 -1 -1 -1]

		if {$listening == "true" } {
			set nonce "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
			set port [OpenGamePort [config::getKey initialftport] $nonce $sid 1]
			set clientip [::abook::getDemographicField clientip]
			set localip [::abook::getDemographicField localip]
		} else {
			set nonce "00000000-0000-0000-0000-000000000000"
			set port ""
			set clientip ""
			set localip ""
		}
		
		if { $listening == "true" } {
			set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 1 $callid 0 2 "TCPv1" "$listening" "$nonce" "$clientip"\
					 "$port" "$localip" "$port"]
			::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
			after 5000 "::MSNGames::ReflectorConnection $sid [getObjOption $sid chatid]"
		} else {
			after 5000 "::MSNGames::ReflectorConnection $sid [getObjOption $sid chatid]"
		}
	}
	
	proc ReflectorConnection {sid chatid} {
		if {[getObjOption $sid directconnection 0] == 1} {
			return
		}
		
		status_log "no direct connection -> using reflector!" blue
		setObjOption $sid reflector 1
		startGame $sid
	}

	proc SendAcceptInvite {sid chatid} {
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
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
	}

	proc AcceptGame {chatid dest branchuid cseq uid sid gameinfo} {
		setObjOption $sid inviter 0
		setObjOption $sid chatid $chatid
		setObjOption $sid reflector 1
		setObjOption $sid appid [string range [lindex $gameinfo 0] [expr [string length [lindex $gameinfo 0]] - 4] end]
		setObjOption $sid completeappid [lindex $gameinfo 0]

		# Let's make and send a 200 OK Message
		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr {$cseq + 1}] $uid 0 0 $sid]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
		
		SendAcceptInvite $sid $chatid
	}

	proc AcceptGameOpenSB {chatid dest branchuid cseq uid sid gameinfo} {
		if {[catch {::MSNGames::AcceptGame $chatid $dest $branchuid $cseq $uid $sid $gameinfo} res]} {
				status_log "Error in InvitationAccepted: $res\n" red
				return 0
		}
    }
	
	proc answerGameInvite {sid chatid branchid} {
		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 -1 -1 -1 -1 -1 "$branchid" ]
		set session [::MSNP2P::SessionList get $sid]
		set dest [lindex $session 3]
		set callid [lindex $session 5]

		set listening [abook::getDemographicField listening]
		#set listening "false"

		if {$listening == "true" } {
				set nonce "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
				set port [OpenGamePort [config::getKey initialftport] $nonce $sid 0]
				set clientip [::abook::getDemographicField clientip]
				set localip [::abook::getDemographicField localip]
		} else {
				set nonce "00000000-0000-0000-0000-000000000000"
				set port ""
				set clientip ""
				set localip ""
		}

		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchid 1 $callid 0 2 "TCPv1" "$listening" "$nonce" "$clientip"\
						 "$port" "$localip" "$port"]

		status_log "sending 200 OK packet for game"
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
	}
	
	proc GameCanceled {chatid sid} {
		#aborted game
		::MSNGamesInterface::abortedGame $sid
		::MSNGamesGUI::GameClosedByOther $chatid
	}
	
	proc CancelGame {sid} {
		set session_data [::MSNP2P::SessionList get $sid]
		set user_login [lindex $session_data 3]
		set callid [lindex $session_data 5]
		set branchid [lindex $session_data 9]
		set chatid [getObjOption $sid chatid 0]
		set sock [getObjOption $sid sock 0]
		
		::MSNGamesGUI::GameClosedBySelf $chatid
		
		if {$sock == 0} {
			#abort game
			set slpdata [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] $branchid 0 $callid 0 2 $sid "dAMAgQ==\r\n"]
			::MSN::ChatQueue $chatid [list ::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]]
		} else {
			#close direct connection
			set slpdata [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] $branchid 0 $callid 0 2 \
				"$sid\r\nSChannelState: 0\r\nCapabilities-Flags: 1" "dAMAgQ==\r\n"]
			SendBYE $sid $slpdata 0
		}
			
		#game aborted
		::MSNGamesInterface::abortedGame $sid
	}

	proc OpenGamePort {port nonce sid sending} {
		while { [catch {set sock [socket -server "::MSNGames::handleGamePort $nonce $sid $sending" $port] } ] } {
			incr port
		}
		
		::abook::OpenUPnPPort $port

		# close server socket after 5 minutes
		after 300000 "catch {close $sock}; ::abook::CloseUPnPPort $port"

		status_log "Opening server on port $port for games\n" red
		return $port
	}

	proc ConnectPort {sid nonce ip port sending} {
		set ips [getObjOption $sid ips]

		if { $ips == "" } {
			set ips [list]
		}

		set nips [split $ip " "]

		foreach connection $nips {
			status_log "Trying to connect to $connection at port $port\n" red
			set socket [connectGamePort $sid $nonce "$connection" $port]
			if { $socket != 0 } {
				lappend ips [list $connection $port $socket]
			}
		}

		setObjOption $sid sending $sending
		setObjOption $sid ips $ips

		foreach connection $ips {
			set sock [lindex $connection 2]

			catch { fconfigure $sock -blocking 0 -buffering none -translation {binary binary} }
			catch { fileevent $sock readable "::MSNGames::CheckConnected $sid $sock " }
			catch { fileevent $sock writable "::MSNGames::CheckConnected $sid $sock " }
		}

		after cancel "::MSNGames::CheckConnectSuccess $sid"
		after 5000 "::MSNGames::CheckConnectSuccess $sid"
	}

	proc CheckConnectSuccess { sid } {
		set ips [getObjOption $sid ips]
		set connected_ips [getObjOption $sid connected_ips]
		status_log "we have $ips connecting sockets and $connected_ips connected sockets\n" red

		after 5000 "::MSNGames::ReflectorConnection $sid [getObjOption $sid chatid]"
		if { [llength $ips] == 0 && [llength $connected_ips] == 0 } {
			status_log "No socket was connected\n" red
		}
	}

	proc CheckConnected {sid socket}  {
		status_log "fileevent CheckConnected for socket $socket\n"

		fileevent $socket readable ""
		fileevent $socket writable ""

		if { [eof $socket] || [fconfigure $socket -error] != "" } {
			status_log "Socket didn't connect $socket : [eof $socket] || [fconfigure $socket -error]\n" red
			close $socket

			set ips [getObjOption $sid ips]
			setObjOption $sid ips [::MSNCAM::RemoveSocketFromList $ips $socket]
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

			fileevent $socket readable "::MSNGames::handleReadPort $socket"
			fileevent $socket writable "::MSNGames::handleWritePort $socket"
			CloseUnusedSockets $sid $socket

			set ips [getObjOption $sid ips]
			setObjOption $sid ips [::MSNCAM::RemoveSocketFromList $ips $socket]
		}
	}

	proc CloseUnusedSockets {sid used_socket {list ""}} {
		if { $list == "" } {
			set ips [getObjOption $sid ips]
			status_log "Closing ips $ips\n" red
			if { $ips != "" } {
				CloseUnusedSockets $sid $used_socket $ips
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
				if {$sock == $used_socket } {
					setObjOption $sid sock $sock
					continue
				}

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

	proc connectGamePort {sid nonce ip port} {
		if { [catch {set sock [socket -async $ip $port]}] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red
			return 0
		} else {
			setObjOption $sock nonce $nonce
			setObjOption $sock state "FOO"
			setObjOption $sock server 0
			setObjOption $sock sid $sid
			setObjOption $sock waitack 0
			setObjOption $sock sendqueue [list]
				
			status_log "connectedto $ip on port $port  - $sock\n"
			return $sock
		}
	}

	proc handleGamePort {nonce sid sending sock ip port} {
		setObjOption $sid sending $sending
		setObjOption $sid reflector 0
		setObjOption $sid sock $sock
		setObjOption $sock nonce $nonce
		setObjOption $sock state "FOO"
		setObjOption $sock server 1
		setObjOption $sock sid $sid
		setObjOption $sock waitack 0
		setObjOption $sock sendqueue [list]

		status_log "Received game connection from $ip on port $port - socket $sock\n"

		fileevent $sock readable "::MSNGames::handleReadPort $sock"
		fconfigure $sock -blocking 0 -buffering none -translation {binary binary}
	}

	
	proc handleReadPort { sock } {
		set sid [getObjOption $sock sid]
		set state [getObjOption $sock state]
		set server [getObjOption $sock server]
		set sending [getObjOption $sid sending]

		set tmpsize 0
		set data [getObjOption $sock buffer]
		set size [getObjOption $sock size]

		if { $sid == "" } {
			status_log "Can't find sid for socket $sock!!! ERROR" red
			close $sock
			return
		}
		
		#Check if we have any data in the buffer
		#If not we get size in next packet
		if { $size == 0 || $size == "" } {
			set size ""
			while { $tmpsize < 4 && ![eof $sock] } {
				update idletasks
				set tmpdata [read $sock [expr {4 - $tmpsize}]]
				append size $tmpdata
				set tmpsize [string length $size]
			}
	
			if {$size == "" && [eof $sock] } {
				status_log "Game Socket $sock closed\n"
				close $sock
				return
			}
	
			if { $size == "" } {
				update idletasks
				return
			}
	
			binary scan $size i size
			
			setObjOption $sock size $size
			set data ""
		}

		#We get the data
		set tmpsize [string length $data]
	
		if { $tmpsize < $size } {
			set tmpdata [read $sock [expr {$size - $tmpsize}]]
			append data $tmpdata
			set tmpsize [string length $data]
		}

		if {$tmpsize == $size } {
			#Data is complete we remove it from the buffer
			setObjOption $sock size 0
			setObjOption $sock buffer ""
			
			if { $data == "" } {
				update idletasks
				return
			}
	
			#status_log "READ data = $data SOCKstate = [getObjOption $sock state]" green
			
			switch -- $state {
				"FOO"
				{
					if { $server && $data == "foo\x00" } {
						setObjOption $sock state "NONCE_GET"
					} 
				}
	
				"NONCE_GET"
				{
					set nonce [getObjOption $sock nonce]
					if { $nonce == [GetNonceFromData $data] } {
						if { $server } {
							setObjOption $sock state "NONCE_SEND"
							fileevent $sock writable "::MSNGames::handleWritePort $sock"
						} else {
							setObjOption $sock state "CONNECTED"
							setObjOption $sid directconnection 1
							setObjOption $sid reflector 0
							startGame $sid
						}
					}
				}
	
				"CONNECTED"
				{
					set message [Message create %AUTO%]
					$message setRaw $data
	
					set p2pmessage [P2PMessage create %AUTO%]
					$p2pmessage createFromMessage $message
				
					if { [$p2pmessage cget -offset] == 0 } {
						degt_protocol "<--DC-MSNP2P ([getObjOption $sid chatid]) $data" "sbrecv"
					}

					::MSNP2P::ReadData $p2pmessage [getObjOption $sid chatid]
					catch { $p2pmessage destroy }
					catch { $message destroy }
				}
	
				default
				{
					catch {close $sock}
				}
	
			}

			#status_log "READ new state! SOCKstate = [getObjOption $sock state]" green
		} else {
			#The data we grabbed isn't integral we save actual data and we wait the next
			setObjOption $sock buffer $data
		}
	}
	
	proc handleWritePort {sock} {
		set sid [getObjOption $sock sid]
		set state [getObjOption $sock state]
		set server [getObjOption $sock server]
		set sending [getObjOption $sid sending]
		set appId [getObjOption $sid appid]

		if { $sid == "" } {
			status_log "Can't find sid for socket $sock!!! ERROR" red
			close $sock
			return
		}

		fileevent $sock writable ""

		set data ""
		set startgame 0
		
		switch -- $state {
			"FOO"			
			{
				if { $server == 0 } {
					set data "foo\x00"
					setObjOption $sock state "NONCE_SEND"
					fileevent $sock writable "::MSNGames::handleWritePort $sock"
					fileevent $sock readable "::MSNGames::handleReadPort $sock"
				}
			}

			"NONCE_SEND"
			{
				set nonce [getObjOption $sock nonce]
				
				set data "[GetDataFromNonce $nonce $sid]"
				if { $server } {
					setObjOption $sock state "CONNECTED"
					set startgame 1
				} else {
					setObjOption $sock state "NONCE_GET"
				}
			}

			"CONNECTED"
			{
				#nothing to do
			}

		}

		if { $data != "" } {
#			status_log "Writing Data on socket $sock with state $state : $data\n" red
			puts -nonewline $sock "[binary format i [string length $data]]$data"
		}
		if {$startgame == 1} {
			setObjOption $sid directconnection 1
			setObjOption $sid reflector 0
			startGame $sid
		}
	}
	
	proc GetNonceFromData {data} {
		set bnonce [string range $data 32 end]
		binary scan $bnonce H2H2H2H2H2H2H2H2H4H* n1 n2 n3 n4 n5 n6 n7 n8 n9 n10
		set nonce [string toupper "$n4$n3$n2$n1-$n6$n5-$n8$n7-$n9-$n10"]
		status_log "Got game NONCE : $nonce\n" red
		return $nonce
	}

	proc GetDataFromNonce {nonce sid} {
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
		status_log "Got NONCE : $nonce\n" red

		set bnonce [binary format H2H2H2H2H2H2H2H2H4H* $n1 $n2 $n3 $n4 $n5 $n6 $n7 $n8 $n9 $n10]
		status_log "got Binary NONCE : $bnonce\n" red

		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]
		incr MsgId

		set data "[binary format iiiiiiii 0 $MsgId 0 0 0 0 0 256]$bnonce"
		incr MsgId

		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]

		return $data
	}
	
	proc handleIncoming {message chatid} {
		set cFlags [$message cget -flag]
		if {$cFlags == 0} {
			handleMessage $message $chatid
		} else {
			status_log "MSNGames - handleIncoming: !!!WARNING!!! cFlags = $cFlags ... not yet handled" red
		}
	}
	
	proc handleACK {cSid cAckId} {
		status_log "MSNGames - handleACK: checking ..." blue
		if {$cSid == 0} {
			return
		}
		
		set waitACK [getObjOption $cSid waitack 0]
		set byeACK [getObjOption $cSid byeack 0]
		status_log "MSNGames - handleACK: byeACK = $byeACK" blue
		status_log "MSNGames - handleACK: waitACK = $waitACK" blue
		status_log "MSNGames - handleACK: cAckId = $cAckId" blue
		
		if {$byeACK == $cAckId} {
			#close connection
			if {[getObjOption $cSid reflector 0] == 0} {
				set sock [getObjOption $cSid sock 0]
				setObjOption $sock state "END"
				setObjOption $cSid sock 0
				catch { close $sock }
			}

			set ips [getObjOption $cSid ips]
			setObjOption $cSid ips [::MSNCAM::RemoveSocketFromList $ips $sock]

			CloseUnusedSockets $cSid ""
		} elseif {$waitACK == $cAckId} {
			dequeueOutBuffer $cSid 1
		}
	}
	
	proc handleMessage {message chatid} {
		set cSid [$message cget -sessionid]
		set cId [$message cget -identifier]
		set cOffset [$message cget -offset]
		set cTotalDataSize [$message cget -totalsize]
		set cMsgSize [$message cget -datalength]
		set cFlags [$message cget -flag]
		set cAckId [$message cget -ackid]
		set cAckUID [$message cget -ackuid]
		set cAckSize [$message cget -acksize]
		set data [$message getBody]
		
		if {$cSid == 0} {
			return
		}
		
		#trim message (reflector communication has footer after data!)
		set data [string range $data 0 [expr $cMsgSize - 1]]
		
		set firstMessage [getObjOption $cSid firstMessage 1]
		set reflector [getObjOption $cSid reflector 0]
		
		set sock [getObjOption $cSid sock 0]
		if {$sock == 0} {
			if {$firstMessage == 1} {
				setObjOption $cSid reflector 1
				set reflector 1
				if {[getObjOption $cSid gamestarted 0] == 0} {
					startGame $cSid
				}
			}
			
			if {$reflector != 1} {
				return
			}
		}
		
		status_log "MSNGames - handleMessage: received message with cId = $cId" blue
		
		#send ACK
		if {[expr $cOffset + $cMsgSize] < $cTotalDataSize} {
			set bufferedData [getObjOption $cSid buffereddata ""]$data
			setObjOption $cSid buffereddata $bufferedData
			
			return
		} else {
			enqueueOutBuffer $cSid [buildACK $cSid $cTotalDataSize $cId $cAckId]
			if {$cMsgSize < $cTotalDataSize} {
				set data [getObjOption $cSid buffereddata ""]$data
				setObjOption $cSid buffereddata ""
			}
		}
		status_log "MSNGames - handleMessage: send ACK with cId = $cId" blue
		status_log "MSNGames - handleMessage: cMsgSize = $cMsgSize" blue

		if {![::MSNGamesInterface::getSetting $cSid opponentready 0] && $cMsgSize == 4} {
			#opponent is ready
			::MSNGamesInterface::setSetting $cSid opponentready 1
		} elseif {$cMsgSize > 0} {
			::MSNGamesInterface::receiveData $cSid [decodeGameMessage $data]
		}
	}
	
	proc SendData {sid data {sendSid 1}} {
		if {$sid == 0} {
			return
		}
		
		#send data
		enqueueOutBuffer $sid [buildPackage $sid $data $sendSid]
	}
	
	proc SendBYE {sid data {sendSid 1}} {
		if {$sid == 0} {
			return
		}
		
		#send data
		set pkg [buildPackage $sid $data $sendSid]
		setObjOption $sid byeack [lindex $pkg 0]
		enqueueOutBuffer $sid $pkg
	}
	
	proc SendLast {sid pkg} {
		if {$sid == 0} {
			return
		}
		
		#send data
		setObjOption $sid lastpkg 1
		enqueueOutBuffer $sid $pkg
	}
	
	proc enqueueOutBuffer {sid pkg} {
		set queue [getObjOption $sid sendqueue]
		setObjOption $sid sendqueue [lappend $queue $pkg]
		
		#set waitACK [getObjOption $sock waitack]
		dequeueOutBuffer $sid
	}
	
	proc dequeueOutBuffer {sid {nocheck 0}} {
		if {$sid == 0} {
			return
		}
		set reflector [getObjOption $sid reflector 0]
		
		if {$nocheck == 0} {
			set waitACK [getObjOption $sid waitack]
		} else {
			set waitACK 0
		}
		
		set queue [getObjOption $sid sendqueue]
		set newQueue [list]
		foreach item $queue {
			set ackId [lindex $item 0]
			if {$waitACK > 0 && $ackId > 0 && $reflector == 0} {
				set newQueue [lappend $newQueue $item]
			} else {
				set waitACK $ackId
				set data [lindex $item 1]
				
				if {$reflector == 1} {
					set chatid [getObjOption $sid chatid]
					set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $chatid\r\n\r\n"
					::MSNP2P::SendPacket [::MSN::SBFor $chatid] "$theader$data"
				} else {
					set sock [getObjOption $sid sock 0]
					if { [catch { puts -nonewline $sock $data } ] } {
						#did our sock get closed?
						catch {close $sock}
					}
				}
			}
		}
		
		setObjOption $sid waitack $waitACK
		setObjOption $sid sendqueue $newQueue
		
		if {[getObjOption $sid lastpkg 0] == 1 && [llength $newQueue] == 0} {
			set sock [getObjOption $sid sock 0]
			setObjOption $sid sock 0
			setObjOption $sock state "END"
			if {$reflector == 0} {
				catch { close $sock }
			}
			
			set ips [getObjOption $sid ips]
			setObjOption $sid ips [::MSNCAM::RemoveSocketFromList $ips $sock]

			CloseUnusedSockets $sid ""
		}
	}
	
	proc buildPackage {cSid data {sendSid 1}} {
		set SessionInfo [::MSNP2P::SessionList get $cSid]
		set MsgId [lindex $SessionInfo 0]

		incr MsgId

		if {$sendSid == 1} {
			set sid $cSid
		} else {
			set sid 0
		}
		
		set b [binary format iiiiiiiiiiii $sid $MsgId 0 0 [string length $data] 0 [string length $data] 0 [myRand 4369 6545000] 0 0 0]
		set b $b$data
		
		set reflector [getObjOption $cSid reflector 0]
		if {$reflector == 0} {
			set b [binary format i [string length $b]]$b
		} else {
			set appId [getObjOption $cSid completeappid]
			set b "$b[binary format I $appId]"
		}
		
		::MSNP2P::SessionList set $cSid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]

		return [list $MsgId $b]
	}
	
	proc buildACK {cSid cTotalDataSize cId cAckId {finalAck 0}} {
		set SessionInfo [::MSNP2P::SessionList get $cSid]
		set MsgId [lindex $SessionInfo 0]

		incr MsgId

		if {$finalAck == 1} {
			set b [binary format iiiiiiiiiiii 0 $MsgId 0 0 0 0 0 2 $cId $cAckId $cTotalDataSize 0]
		} else {
			set b [binary format iiiiiiiiiiii $cSid $MsgId 0 0 $cTotalDataSize 0 0 2 $cId $cAckId 0 $cTotalDataSize]
		}
		set reflector [getObjOption $cSid reflector 0]
		if {$reflector == 0} {
			set b [binary format i [string length $b]]$b
		} else {
			set b "$b[binary format i 0]"
		}
		
		::MSNP2P::SessionList set $cSid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]

		return [list 0 $b]
	}
	
	proc buildGameMessage {data {unicode 0}} {
		if {$unicode == 0} {
			set data [ToUnicode $data]
		}
		set data "$data\x00\x00"
		
		set b [binary format isss 128 8 [string length $data] 0]$data
		
		return $b
	}
	
	proc decodeGameMessage {data} {
		binary scan [string range $data 0 10] isss p1 p2 cLen p4
		
		set data [string range $data 10 [expr 10 + $cLen]]
		if {[string range $data [expr [string length $data] - 2] end] == "\x00\x00"} {
			set data [string range $data 0 [expr [string length $data] - 2]]
		}
		
		return [FromUnicode $data]
	}

	proc startGame {sid} {
		setObjOption $sid gamestarted 1
	
		#get opponent nick
		set chatid [getObjOption $sid chatid 0]
		if {$chatid > 0} {
			set oppNick [::abook::getDisplayNick $chatid]
		} else {
			set oppNick "?"
		}
		
		#get settings of the game
		set appId [getObjOption $sid appid]
		set inviter [getObjOption $sid inviter]
		
		#start game
		::MSNGamesInterface::startGame $sid $appId $oppNick $inviter
	}
}

namespace eval ::MSNGamesGUI {
	proc buildMenu {menu {w ""}} {
		set gamesmenu $menu.games

		menu $gamesmenu -tearoff 0 -type normal

		set gameList [::MSNGamesPlugins::getGameList]
		
		foreach game $gameList {
			set appName [lindex $game 1]
			set appId [lindex $game 0]
			
			if {$w == ""} {
				#menu in contact list
				$gamesmenu add command -label $appName -command "::amsn::ShowUserList \[trans playgame2 \[list $appName\]\] \[list ::MSNGames::SendInviteQueue $appId\]"
			} else {
				#menu in chatwindow
				$gamesmenu add command -label $appName -command "::amsn::ShowChatList \[trans playgame2 \[list $appName\]\] \[::ChatWindow::getCurrentTab $w\] \[list ::MSNGames::SendInviteQueue $appId\]"
			}
		}
		
		return $gamesmenu
	}
	
	proc InvitationSent {chatid sid appId gameName} {
		SendMessageFIFO [list ::MSNGamesGUI::InvitationSentWrapped $chatid $sid $appId $gameName] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}
	
	proc InvitationSentWrapped {chatid sid appId gameName} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green
		::amsn::WinWrite $chatid "[timestamp] [trans gamerequest [::abook::getDisplayNick $chatid] $gameName]" green
		::amsn::WinWrite $chatid " - (" green
		::amsn::WinWriteClickable $chatid "[trans cancel]" [list ::MSNGamesGUI::CancelInvitation $chatid $sid] cancelgame$sid
		::amsn::WinWrite $chatid ")\n" green
		::amsn::WinWriteIcon $chatid greyline 3
	}
	
	proc CancelInvitation {chatid sid} {
		#Get the chatwindow name
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
				return 0
		}

		#Disable item in the chatwindow
		[::ChatWindow::GetOutText ${win_name}] tag configure cancelgame$sid \
				-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelgame$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelgame$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelgame$sid <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr

		# abort invitation
		if {[::MSN::ChatQueue $chatid [list ::MSNGames::CancelGame $sid]] == 0} {
			return 0
		}
	}
	
	proc InvitationRejected {chatid sid} {
		#Get the chatwindow name
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
				return 0
		}

		#Disable item in the chatwindow
		[::ChatWindow::GetOutText ${win_name}] tag configure cancelgame$sid \
				-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelgame$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelgame$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelgame$sid <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr


		#show message in CW
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green

		#Show invitation
		::amsn::WinWrite $chatid "[timestamp] [trans gamerejected [::abook::getDisplayNick $chatid]]\n" green

		#Grey line
		::amsn::WinWriteIcon $chatid greyline 3
	}

	proc InvitationAccepted {chatid sid} {
		#Get the chatwindow name
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
				return 0
		}

		#Disable item in the chatwindow
		[::ChatWindow::GetOutText ${win_name}] tag configure cancelgame$sid \
				-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelgame$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelgame$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind cancelgame$sid <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr


		#show message in CW
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green

		#Show invitation
		::amsn::WinWrite $chatid "[timestamp] [trans gameaccepted [::abook::getDisplayNick $chatid]]\n" green

		#Grey line
		::amsn::WinWriteIcon $chatid greyline 3
	}
	
	proc IncomingGameRequestInvalid {chatid dest branchuid cseq uid sid gameinfo} {
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green

		#Show invitation
		::amsn::WinWrite $chatid "[timestamp] [trans gamepluginnotfound [::abook::getDisplayNick $chatid] [lindex $gameinfo 2]]\n" green

		#Grey line
		::amsn::WinWriteIcon $chatid greyline 3
	}

	proc IncomingGameRequestShow {chatid dest branchuid cseq uid sid gameinfo} {
		#Grey line
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green

		#Show invitation
		::amsn::WinWrite $chatid "[timestamp] [trans gameinvitation [::abook::getDisplayNick $chatid] [lindex $gameinfo 2]]" green

		#Accept and refuse actions
		::amsn::WinWrite $chatid " - (" green
		::amsn::WinWriteClickable $chatid "[trans accept]" [list ::MSNGamesGUI::IncomingGameRequestAccept $chatid $dest $branchuid $cseq $uid $sid $gameinfo] acceptgame$sid
		::amsn::WinWrite $chatid " / " green
		::amsn::WinWriteClickable $chatid "[trans reject]" [list ::MSNGamesGUI::IncomingGameRequestReject $chatid $sid $branchuid $uid] rejectgame$sid
		::amsn::WinWrite $chatid ")\n" green

		#Grey line
		::amsn::WinWriteIcon $chatid greyline 3
	}

	proc IncomingGameRequestReject {chatid sid branchuid uid} {
		#Get the chatwindow name
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
				return 0
		}

		#Disable items in the chatwindow
		[::ChatWindow::GetOutText ${win_name}] tag configure acceptgame$sid \
				-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptgame$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptgame$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptgame$sid <<Button1>> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure rejectgame$sid \
				-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr

		# abort invitation
		if {[::MSN::ChatQueue $chatid [list ::MSN6FT::RejectFT $chatid $sid $branchuid $uid]] == 0} {
			return 0
		}
	}
	
	proc IncomingGameRequestAccept {chatid dest branchuid cseq uid sid gameinfo} {
		#Get the chatwindow name
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
				return 0
		}

		#Disable items in the chatwindow
		[::ChatWindow::GetOutText ${win_name}] tag configure acceptgame$sid \
				-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptgame$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptgame$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptgame$sid <<Button1>> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure rejectgame$sid \
				-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr

		# accept invitation
		if {[::MSN::ChatQueue $chatid [list ::MSNGames::AcceptGameOpenSB $chatid $dest $branchuid $cseq $uid $sid $gameinfo]] == 0} {
				return 0
		}
	}

	proc GameClosedByOther {chatid} {
		#show message in CW
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green

		::amsn::WinWrite $chatid "[timestamp] [trans gameclosedbyother [::abook::getDisplayNick $chatid]]\n" green

		#Grey line
		::amsn::WinWriteIcon $chatid greyline 3
	}
	
	proc GameClosedBySelf {chatid} {
		#show message in CW
		::amsn::WinWrite $chatid "\n" green
		::amsn::WinWriteIcon $chatid greyline 3
		::amsn::WinWrite $chatid " \n" green

		::amsn::WinWrite $chatid "[timestamp] [trans gameclosedbyself [::abook::getDisplayNick $chatid]]\n" green

		#Grey line
		::amsn::WinWriteIcon $chatid greyline 3
	}
}

namespace eval ::MSNGamesInterface {
	########## ::MSNGamesInterface::restartGame ###################
	## after game round is finished this triggers the restart
	## process
	##
	## parameter:
	##  sid:	unique session-ID
	##
	## return:
	##	-
	###############################################################
	proc restartGame {sid} {
		#trigger handshake process
		after 1000 "::MSNGamesInterface::checkHandshake $sid"
	}
	
	########## ::MSNGamesInterface::closeGame #####################
	## closes game connection and informs opponent of the end of  
	## the game
	##
	## parameter:
	##  sid:	unique session-ID
	##
	## return:
	##	-
	###############################################################
	proc closeGame {sid} {
		::MSNGames::CancelGame $sid
	}
	
	########## ::MSNGamesInterface::destroyGame ###################
	## removes all internal data of the game session and informs 
	## the plugin-system
	## IMPORTANT: this function should be called at last after
	## destroying a game session
	##
	## parameter:
	##  sid:	unique session-ID
	##
	## return:
	##	-
	###############################################################
	proc destroyGame {sid} {
		::MSNGamesPlugins::removeGame $sid
		after 60000 "::MSNGamesInterface::removeSettings $sid"
		
		#abort running handshake process
		resetHandshakeState $sid [getHandshakeFlag complete]
	}
	
	########## ::MSNGamesInterface::send ##########################
	## send game data to the communication channel
	##
	## parameter:
	##  sid:	unique session-ID
	##  data:	data to send
	##
	## return:
	##	-
	###############################################################
	proc send {sid data} {
		#build game message and send out
		::MSNGames::SendData $sid [::MSNGames::buildGameMessage $data]
	}
	
	########## ::MSNGamesInterface::setSetting ####################
	## save game-dependant data
	## (will be destroyed after destroyGame!)
	##
	## parameter:
	##  sid:	unique session-ID
	##  key:	storage key
	##  value:	value to store
	##
	## return:
	##	-
	###############################################################
	proc setSetting {sid key value} {
		global gameSettings
		
		if {[info exists gameSettings($sid)]} {
			set sidSetsList [set gameSettings($sid)]
		} else {
			set sidSetsList [list]
		}
		
		array set sidSetsArray $sidSetsList
		set sidSetsArray($key) $value
		set gameSettings($sid) [array get sidSetsArray]
	}
	
	########## ::MSNGamesInterface::getSetting ####################
	## read game-dependant data from storage
	##
	## parameter:
	##  sid:	unique session-ID
	##  key:	storage key
	##  def:	default value if storage key doesn't exist
	##
	## return:
	##	the stored data
	###############################################################
	proc getSetting {sid key {def ""}} {
		global gameSettings
		
		if {[info exists gameSettings($sid)]} {
			set sidSetsList [set gameSettings($sid)]
		} else {
			return $def
		}

		array set sidSetsArray $sidSetsList
		if {[info exists sidSetsArray($key)]} {
			return [set sidSetsArray($key)]
		} else {
			return $def
		}
	}
	
	proc startGame {sid appId oppNick inviter} {
		#check if game is already started
		set isStarted [getSetting $sid started 0]
		if {$isStarted == 0} {
			setSetting $sid started 1
			
			#setup important settings
			setSetting $sid opponentnick $oppNick
			setSetting $sid inviter $inviter
			
			#send "i am ready" package
			::MSNGames::SendData $sid [binary format Ss [myRand 17 127] 1]
			resetHandshakeState $sid [getHandshakeFlag newgame]
			after 1000 "::MSNGamesInterface::checkHandshake $sid"
			
			#trigger start game
			::MSNGamesPlugins::setupGame $sid $appId
			::MSNGamesPlugins::trigger $sid create
		}
	}
	
	proc abortedGame {sid} {
		set isStarted [getSetting $sid started 0]
		if {$isStarted == 1} {
			setSetting $sid started 2

			#trigger abort game
			::MSNGamesPlugins::trigger $sid destroy
		}
	}
	
	proc resetHandshakeState {sid state} {
		setSetting $sid handshakestate $state
	}

	proc setHandshakeState {sid flag} {
		set state [getSetting $sid handshakestate 0]
		set state [expr {$state | $flag}]
		setSetting $sid handshakestate $state
	}

	proc getHandshakeState {sid flag} {
		set state [getSetting $sid handshakestate 0]
		return [expr {$state & $flag}]
	}
	
	proc getHandshakeFlag {flag} {
		switch -- $flag {
			endgame 		{ return 1 }
			clickedyessent 	{ return 2 }
			clickedyesrecv	{ return 4 }
			triggergameend 	{ return 8 }
			triggerrestart	{ return 16 }
			guidsent		{ return 32 }
			guidrecv		{ return 64 }
			triggerstart	{ return 128 }
			
			gameendcheck	{ return 5 }
			restartcompl	{ return 15 }
			restartcheck	{ return 31 }

			startcompl		{ return 96 }
			startcheck		{ return 224 }
			
			newgame			{ return 31 }
			restartgame		{ return 0 }
			complete		{ return 255 }
		}
		return 0
	}

	proc checkHandshake {sid} {
		if {![::MSNGamesInterface::getSetting $sid opponentready 0]} {
			#wait until connection is ready and opponent finished loading
			after 1000 "::MSNGamesInterface::checkHandshake $sid"
			return
		}
		
		if {[getHandshakeState $sid [getHandshakeFlag endgame]] == 0 && [getSetting $sid inviter 0] == 0} {
			#aren't we inviter and have sent GameEnd after restarting a game yet?
			send $sid "0:GameEnd:"
			setHandshakeState $sid [getHandshakeFlag endgame]
		}
		if {[getHandshakeState $sid [getHandshakeFlag clickedyessent]] == 0} {
			#have we sent PlayerClickedYes after restarting a game yet?
			send $sid "0:PlayerClickedYes:"
			setHandshakeState $sid [getHandshakeFlag clickedyessent]
		}
		if {[getHandshakeState $sid [getHandshakeFlag gameendcheck]] > 0 && \
			[getHandshakeState $sid [getHandshakeFlag triggergameend]] == 0} {
			#trigger gameend after we sent/received GameEnd and have received and sent PlayerClickedYes
			::MSNGamesPlugins::trigger $sid gameend
			setHandshakeState $sid [getHandshakeFlag triggergameend]
		}
		
		if {[getHandshakeState $sid [getHandshakeFlag restartcheck]] == [getHandshakeFlag restartcompl]} {
			#trigger restart after triggering gameend
			::MSNGamesPlugins::trigger $sid restart
			setHandshakeState $sid [getHandshakeFlag triggerrestart]
		} elseif {[getHandshakeState $sid [getHandshakeFlag restartcheck]] == [getHandshakeFlag restartcheck]} {
			if {[getHandshakeState $sid [getHandshakeFlag guidsent]] == 0} {
				#have we sent the guid yet?
				if {[getSetting $sid inviter 0] == 1} {
					#generate guid and sendout handshake
					set guid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
					::MSNGames::SendData $sid [::MSNGames::buildGameMessage "0:SendGameGuid:\{$guid\}"]
					setHandshakeState $sid [getHandshakeFlag guidsent]
				} elseif {[getHandshakeState $sid [getHandshakeFlag guidrecv]] > 0} {
					#simply fake ticket data with DUMMY, the other side should accept that but scoring will not work
					#TODO: if we want to use the server-side scoring we should replace DUMMY by the ticket-ID that
					#      can be requested from the MSN-server
					::MSNGames::SendData $sid [::MSNGames::buildGameMessage "0:SendSignedTicket:[::config::getKey login]:DUMMY"]
					setHandshakeState $sid [getHandshakeFlag guidsent]
				}
			} elseif {[getHandshakeState $sid [getHandshakeFlag startcheck]] == [getHandshakeFlag startcompl]} {
				#tell local game that handshake is complete
				::MSNGamesPlugins::trigger $sid gamestart
				setHandshakeState $sid [getHandshakeFlag triggerstart]
			}
		}
		
		if {[getHandshakeState $sid [getHandshakeFlag complete]] == [getHandshakeFlag complete]} {
			#handshake complete
			resetHandshakeState $sid [getHandshakeFlag restartgame]
		} else {
			#handshake incomplete, keep on checking every 1s
			after 1000 "::MSNGamesInterface::checkHandshake $sid"
		}
	}
	
	proc receiveData {sid data} {
		status_log "MSNGamesInterface - receiveData: data = \"$data\"" blue
		status_log "MSNGamesInterface - receiveData: length(data) = [string length $data]" blue
		
		set recv [split $data :]
		if {[lindex $recv 0] == "0"} {
			#message in the messenger layer
			if {[lindex $recv 1] == "SendGameGuid"} {
				setHandshakeState $sid [getHandshakeFlag guidrecv]
			} elseif {[lindex $recv 1] == "SendSignedTicket"} {
				setHandshakeState $sid [getHandshakeFlag guidrecv]
			} elseif {[lindex $recv 1] == "PlayerClickedYes"} {
				setHandshakeState $sid [getHandshakeFlag clickedyesrecv]
			} elseif {[lindex $recv 1] == "GameEnd"} {
				setHandshakeState $sid [getHandshakeFlag endgame]
			} else {
				#send message to game plugin
				::MSNGamesPlugins::trigger $sid message $data
			}
		} else {
			#send message to game plugin
			::MSNGamesPlugins::trigger $sid message $data
		}
	}
	
	proc removeSettings {sid} {
		global gameSettings
	
		if {[info exists gameSettings($sid)]} {
			unset gameSettings($sid)
		}
	}
}

namespace eval ::MSNGamesPlugins {
	########## ::MSNGamesPlugins::register ########################
	## registers a new plugin as a game
	##
	## parameter:
	##  name:	unique identifier of plugin
	##  pVer:	plugin protocol version
	## 	appId: 	list of application IDs (set by Microsoft!) with
	##			corresponding names
	##  funcs:	trigger functions list
	##				0: create
	##				1: destroy
	##				2: restart
	##				3: gamestart
	##  			4: gameend
	##  			5: message
	##
	## return:
	##	current protocol version
	###############################################################
	proc register {name pVer appId funcs} {
		global gamePlugins appIds
		
		set currentVersion 1
		set minVersion 1
		if {$pVer < $minVersion} {
			return 0
		}
		
		#check if plugin is already listed
		if {[info exists gamePlugins($name)]} {
			return 0
		}
		
		#check if one of the appIds is already listed
		foreach item $appId {
			set id [lindex $item 0]
			if {[info exists appIds($id)]} {
				return 0
			}
		}
		
		#register plugin name
		array set plugin [list]
		set plugin(appId) $appId
		set plugin(funcs) $funcs
		set gamePlugins($name) [array get plugin]
		
		#register appIds
		foreach item $appId {
			set id [lindex $item 0]
			set appIds($id) $name
		}
		
		return $currentVersion
	}
	
	########## ::MSNGamesPlugins::unregister ######################
	## unregisters a plugin
	##
	## parameter:
	##  name:	unique identifier of plugin
	##
	## return:
	##	-
	###############################################################
	proc unregister {name} {
		global gamePlugins appIds
		
		if {[info exists gamePlugins($name)]} {
			array set plugin [set gamePlugins($name)]
			set appId [set plugin(appId)]
			
			#remove appIds
			foreach item $appId {
				set id [lindex $item 0]
				if {[info exists appIds($id)]} {
					unset appIds($id)
				}
			}
		
			#remove plugin name
			unset gamePlugins($name)
		}
	}

	proc getGameList {} {
		global gamePlugins
		
		set ret [list]
		set gameNames [array names gamePlugins]
		foreach gameName $gameNames {
			array set plugin [set gamePlugins($gameName)]
			set appIdList $plugin(appId)
			foreach appId $appIdList {
				set ret [lappend ret $appId]
			}
		}
		
		return $ret
	}
	
	proc supportedGame {appId} {
		global appIds
		
		if {[info exists appIds($appId)]} {
			return 1
		} else {
			return 0
		}
	}
	
	proc setupGame {sid appId} {
		global gamePlugins appIds runningGame
		
		if {![info exists appIds($appId)]} {
			return 0
		}
		
		set name [set appIds($appId)]
		if {![info exists gamePlugins($name)]} {
			return 0
		}
		
		array set plugin [set gamePlugins($name)]
		set descr ""
		foreach item [set plugin(appId)] {
			set id [lindex $item 0]
			if {$id == $appId} {
				set descr [lindex $item 1]
				break
			}
		}
		
		array set game [list]
		set game(appId) $appId
		set game(name) $name
		set game(funcs) [set plugin(funcs)]
		set game(descr) $descr
		
		set runningGame($sid) [array get game]
	}
	
	proc getName {appId} {
		global gamePlugins appIds
		
		if {![info exists appIds($appId)]} {
			return ""
		}
		
		set name [set appIds($appId)]
		if {![info exists gamePlugins($name)]} {
			return ""
		}
		
		array set plugin [set gamePlugins($name)]
		set descr ""
		foreach item [set plugin(appId)] {
			set id [lindex $item 0]
			if {$id == $appId} {
				set descr [lindex $item 1]
				break
			}
		}
		
		return $descr
	}
	
	proc removeGame {sid} {
		global runningGame
		
		if {[info exists runningGame($sid)]} {
			unset runningGame($sid)
		}
	}
	
	proc trigger {sid cmd {param ""}} {
		global runningGame
		
		if {![info exists runningGame($sid)]} {
			return 0
		}
		
		array set game [set runningGame($sid)]
		set funcs [set game(funcs)]

		status_log "MSNGamesPlugins - trigger: sid = $sid" blue
		status_log "MSNGamesPlugins - trigger: cmd = $cmd" blue
		status_log "MSNGamesPlugins - trigger: param = $param" blue

		if {$cmd == "create"} {
			set func [lindex $funcs 0]
		} elseif {$cmd == "destroy"} {
			set func [lindex $funcs 1]
		} elseif {$cmd == "restart"} {
			set func [lindex $funcs 2]
		} elseif {$cmd == "gamestart"} {
			set func [lindex $funcs 3]
		} elseif {$cmd == "gameend"} {
			set func [lindex $funcs 4]
		} elseif {$cmd == "message"} {
			set func [lindex $funcs 5]
		} else {
			status_log "WARNING: invalid command for trigger: $cmd" red
			return
		}
		
		catch { eval $func $sid [list $param] } res
		
		status_log "MSNGamesPlugins - trigger: res = $res" blue
	}
}
