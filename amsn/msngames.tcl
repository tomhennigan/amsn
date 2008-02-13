################## GameTTT #######################
## This plugin is the game "Tic Tac Toe" of the ##
## MSN-Zone games. It is fully compatible.      ##
##                                              ##
## written by Mirko Hansen (BaaaZen)            ##
##################################################

namespace eval ::MSNGames {
	proc IncomingGameRequest {chatid dest branchuid cseq uid sid context} {
		set gameinfo [split $context ";"]
	
		if {[llength $gameinfo] == 3} {
			#check if we have a fitting plugin for this game
			if {[::MSNGamesPlugins::supportedGame [lindex $gameinfo 0]] == 1} {
				SendMessageFIFO [list ::MSNGames::IncomingGameRequestShow $chatid $dest $branchuid $cseq $uid $sid $gameinfo] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
			} else {
				#no plugin found, so warn the user and abort request
				SendMessageFIFO [list ::MSNGames::IncomingGameRequestInvalid $chatid $dest $branchuid $cseq $uid $sid $gameinfo] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
			
				# abort invitation
				::MSN::ChatQueue $chatid [list ::MSN6FT::RejectFT $chatid $sid $branchuid $uid]
			}
		} else {
			status_log "WARNING: game context format is invalid: $context" red

			#seems like the format of the context is invalid, so abort request
			::MSN::ChatQueue $chatid [list ::MSN6FT::RejectFT $chatid $sid $branchuid $uid]
		}
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
		::amsn::WinWriteClickable $chatid "[trans accept]" [list ::MSNGames::IncomingGameRequestAccept $chatid $dest $branchuid $cseq $uid $sid $gameinfo] acceptgame$sid
		::amsn::WinWrite $chatid " / " green
		::amsn::WinWriteClickable $chatid "[trans reject]" [list ::MSNGames::IncomingGameRequestReject $chatid $sid $branchuid $uid] rejectgame$sid
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
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptgame$sid <Button1-ButtonRelease> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure rejectgame$sid \
				-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Button1-ButtonRelease> ""

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
		[::ChatWindow::GetOutText ${win_name}] tag bind acceptgame$sid <Button1-ButtonRelease> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure rejectgame$sid \
				-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind rejectgame$sid <Button1-ButtonRelease> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr

		# accept invitation
		if {[::MSN::ChatQueue $chatid [list ::MSNGames::AcceptGameOpenSB $chatid $dest $branchuid $cseq $uid $sid $gameinfo]] == 0} {
				return 0
		}
	}

	proc AcceptGame { chatid dest branchuid cseq uid sid gameinfo} {
		setObjOption $sid inviter 0
		setObjOption $sid chatid $chatid
		setObjOption $sid reflector 0
		setObjOption $sid appid [lindex $gameinfo 0]

		# Let's make and send a 200 OK Message
		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr {$cseq + 1}] $uid 0 0 $sid]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
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
	
		if {$chatid > 0} {
			#show message in CW
			::amsn::WinWrite $chatid "\n" green
			::amsn::WinWriteIcon $chatid greyline 3
			::amsn::WinWrite $chatid " \n" green

			#Show invitation
			::amsn::WinWrite $chatid "[timestamp] [trans gameclosedbyother [::abook::getDisplayNick $chatid]]\n" green

			#Grey line
			::amsn::WinWriteIcon $chatid greyline 3
		}
	
		set sock [getObjOption $sid sock 0]
		if {$sock != 0} {
#			set session_data [::MSNP2P::SessionList get $sid]
#			set user_login [lindex $session_data 3]
#			set callid [lindex $session_data 5]
#			set branchid [lindex $session_data 9]

			#set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
#			set slpdata [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] $branchid 0 $callid 0 1 "dAMAgQ==\r\n"]
#			::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
		
			setObjOption $sock state "END"
			setObjOption $sid sock 0
			CloseUnusedSockets $sid ""
		}
	}
	
	proc CancelGame {sid} {
		set session_data [::MSNP2P::SessionList get $sid]
		set user_login [lindex $session_data 3]
		set callid [lindex $session_data 5]
		set branchid [lindex $session_data 9]
		set chatid [getObjOption $sid chatid 0]
		
		if {$chatid > 0} {
			#cancel session
			set slpdata [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] $branchid 0 $callid 0 1 "dAMAgQ==\r\n"]
			::MSN::ChatQueue $chatid [list ::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]]
		
			#show message in CW
			::amsn::WinWrite $chatid "\n" green
			::amsn::WinWriteIcon $chatid greyline 3
			::amsn::WinWrite $chatid " \n" green

			#Show invitation
			::amsn::WinWrite $chatid "[timestamp] [trans gameclosedbyself [::abook::getDisplayNick $chatid]]\n" green

			#Grey line
			::amsn::WinWriteIcon $chatid greyline 3
		}
		
		#close direct connection
		SendBYE $sid [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] $branchid 0 $callid 0 1 "dAMAgQ==\r\n"]
		
		#game aborted
		::MSNGamesInterface::abortedGame $sid
	}

	proc OpenGamePort {port nonce sid sending} {
		while { [catch {set sock [socket -server "::MSNGames::handleGamePort $nonce $sid $sending" $port] } ] } {
				incr port
		}
		
		# TODO the server socket should be closed as soon as the user authenticated or whatever...
		#after 300000 "catch {close $sock}"

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
		#TODO: use SB for communication!
#		after 5000 "::MSNP2P::SendDataFile $sid [getObjOption $sid chatid] [list [lindex [::MSNP2P::SessionList get $sid] 8]] \"INVITE2\""
		if { [llength $ips] == 0 && [llength $connected_ips] == 0 } {
			status_log "No socket was connected\n" red
			#after 5000 "::MSNP2P::SendDataFile $sid [getObjOption $sid chatid] [list [lindex [::MSNP2P::SessionList get $sid] 8]] \"INVITE2\""
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

	proc connectGamePort {sid nonce ip port} {
		if { [catch {set sock [socket -async $ip $port]}] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red
			return 0
		} else {
			setObjOption $sid sock $sock
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
		setObjOption $sid sock $sock
		setObjOption $sock nonce $nonce
		setObjOption $sock state "FOO"
		setObjOption $sock server 1
		setObjOption $sock sid $sid
		setObjOption $sock waitack 0
		setObjOption $sock sendqueue [list]

		status_log "Received game connection from $ip on port $port - socket $sock\n"

		fileevent $sock readable "::MSNGames::handleReadPort $sock"
		#fileevent $sock writable "::MSNGames::handleWritePort $sock"

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
			
			#TODO: WLM doesn't send foo as handshake anymore, so we need some modifications here!!!
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
						::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "DATASEND" -1 -1 -1 -1 -1]
	
						if { $server } {
							setObjOption $sock state "NONCE_SEND"
							fileevent $sock writable "::MSNGames::handleWritePort $sock"
						} else {
							setObjOption $sock state "CONNECTED"
							if { $sending } {
								fileevent $sock writable "::MSNGames::handleWritePort $sock"	
							}
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

		if { $sid == "" } {
			status_log "Can't find sid for socket $sock!!! ERROR" red
			close $sock
			return
		}

		fileevent $sock writable ""

		set data ""

		switch -- $state {
			"FOO"			
			{
				if { $server == 0 } {
					set data "foo\x00"
					setObjOption $sock state "NONCE_SEND"
					fileevent $sock writable "::MSNGames::handleWritePort $sock"
				}
			}

			"NONCE_SEND"
			{
				set nonce [getObjOption $sock nonce]
				
				set data "[GetDataFromNonce $nonce $sid]"
				if { $server } {
					setObjOption $sock state "CONNECTED"
					if { $sending } {
						fileevent $sock writable "::MSNGames::handleWritePort $sock"	
					}
					startGame $sid
				} else {
					setObjOption $sock state "NONCE_GET"
#					fileevent $sock readable "::MSNGames::handleReadPort $sock"	
				}
			}

			"CONNECTED"
			{
				#after 5 [list fileevent $sock writable "::MSNGames::HandleWritePort $sock"]
				fileevent $sock writable "::MSNGames::HandleWritePort $sock"
			}

		}

		if { $data != "" } {
#			status_log "Writing Data on socket $sock with state $state : $data\n" red
			puts -nonewline $sock "[binary format i [string length $data]]$data"
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

		status_log "Data blob ID is set to $MsgId\n" red

		# Set the blob id of the current data to send
		setObjOption $sid data_blob_id $MsgId
		::MSNP2P::SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]

		return $data
	}
	
	proc handleIncoming {message chatid} {
		set cFlags [$message cget -flag]
		if {$cFlags == 0} {
			handleMessage $message $chatid
		} else {
			status_log "!!!WARNING!!! cFlags = $cFlags ... not yet handled" red
		}
	}
	
	proc handleACK {cSid cAckId} {
		status_log "MSNGames - handleACK: checking ..." blue
		if {$cSid == 0} {
			return
		}
		
		set sock [getObjOption $cSid sock 0]
		if {$sock == 0} {
			return
		}

		set waitACK [getObjOption $sock waitack 0]
		set byeACK [getObjOption $sock byeack 0]
		status_log "MSNGames - handleACK: byeACK = $byeACK" blue
		status_log "MSNGames - handleACK: waitACK = $waitACK" blue
		status_log "MSNGames - handleACK: cAckId = $cAckId" blue
		
		if {$byeACK == $cAckId} {
			#close connection
			setObjOption $sock state "END"
			setObjOption $cSid sock 0
			CloseUnusedSockets $cSid ""
		} elseif {$waitACK == $cAckId} {
			dequeueOutBuffer $sock 1
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
		
		set sock [getObjOption $cSid sock 0]
		if {$sock == 0} {
			return
		}
		
		#status_log "MSNGames-handleMessage: received message with cId = $cId" blue
		
		#send ACK
		if {[expr $cOffset + $cMsgSize] < $cTotalDataSize} {
			set bufferedData [getObjOption $cSid buffereddata ""]$data
			setObjOption $cSid buffereddata $bufferedData
			
			return
		} else {
			enqueueOutBuffer $sock [list 0 [buildACK $cSid $cTotalDataSize $cId $cAckId]]
			if {$cMsgSize < $cTotalDataSize} {
				set data [getObjOption $cSid buffereddata ""]$data
				setObjOption $cSid buffereddata ""
			}
		}
		#status_log "MSNGames-handleMessage: send ACK with cId = $cId" blue
		#status_log "MSNGames-handleMessage: cMsgSize = $cMsgSize" blue

		if {![::MSNGamesInterface::getSetting $cSid opponentready 0] && $cMsgSize == 4} {
			#opponent is ready
			::MSNGamesInterface::setSetting $cSid opponentready 1
		} elseif {$cMsgSize > 0} {
			::MSNGamesInterface::receiveData $cSid [decodeGameMessage $data]
		}
	}
	
	proc SendData {sid data} {
		if {$sid == 0} {
			return
		}
		
		set sock [getObjOption $sid sock 0]
		if {$sock == 0} {
			return
		}

		#send data
		#puts -nonewline $sock [buildPackage $sid $data]
		enqueueOutBuffer $sock [buildPackage $sid $data]
	}
	
	proc SendBYE {sid data} {
		if {$sid == 0} {
			return
		}
		
		set sock [getObjOption $sid sock 0]
		if {$sock == 0} {
			return
		}

		#send data
		set pkg [buildPackage $sid $data]
		setObjOption $sock byeack [lindex $pkg 0]
		enqueueOutBuffer $sock $pkg
	}
	
	proc enqueueOutBuffer {sock pkg} {
		set queue [getObjOption $sock sendqueue]
		setObjOption $sock sendqueue [lappend $queue $pkg]
		
		#set waitACK [getObjOption $sock waitack]
		dequeueOutBuffer $sock
	}
	
	proc dequeueOutBuffer {sock {nocheck 0}} {
		#status_log "dequeue 1: nocheck = $nocheck" blue
		if {$nocheck == 0} {
			set waitACK [getObjOption $sock waitack]
			#status_log "dequeue 1: waitACK = $waitACK" blue
			if {$waitACK != 0} {
				return
			}
		}
		
		set queue [getObjOption $sock sendqueue]
		#status_log "dequeue 2: queue = $queue" blue
		set nextACK 0
		while {$nextACK == 0} {
			#status_log "dequeue 3: nextACK = $nextACK" blue
			if {[llength $queue] > 0} {
				set item [lindex $queue 0]
				#status_log "dequeue 4: item = $item" blue
				set queue [lrange $queue 1 end]
				#status_log "dequeue 4: queue = $queue" blue
				
				set nextACK [lindex $item 0]
				set data [lindex $item 1]
				
				puts -nonewline $sock $data
			} else {
				break
			}
		}
		#status_log "dequeue 5: nextACK = $nextACK" blue
		
		setObjOption $sock waitack $nextACK
		setObjOption $sock sendqueue $queue
	}
	
	proc buildPackage { cSid data } {
		set SessionInfo [::MSNP2P::SessionList get $cSid]
		set MsgId [lindex $SessionInfo 0]

		incr MsgId

		set b [binary format iiiiiiiiiiii $cSid $MsgId 0 0 [string length $data] 0 [string length $data] 0 [myRand 4369 6545000] 0 0 0]
		set b $b$data
		set b [binary format i [string length $b]]$b
		
		::MSNP2P::SessionList set $cSid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]

		return [list $MsgId $b]
	}
	
	proc buildACK { cSid cTotalDataSize cId cAckId } {
		set SessionInfo [::MSNP2P::SessionList get $cSid]
		set MsgId [lindex $SessionInfo 0]

		incr MsgId

		set b [binary format iiiiiiiiiiii $cSid $MsgId 0 0 $cTotalDataSize 0 0 2 $cId $cAckId 0 $cTotalDataSize]
		set b [binary format i [string length $b]]$b
		
		::MSNP2P::SessionList set $cSid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]

		return $b
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
		#reset handshake
		setSetting $sid handshakestate ""

		#send out restart data
		if {[getSetting $sid inviter 0] == 0} {
			send $sid "0:GameEnd:"
		}
		send $sid "0:PlayerClickedYes:"

		#set restart state
		set restartState [getSetting $sid restartstate ""]
		if {[getSetting $sid inviter 0] == 0} {
			if {$restartState == ""} {
				setSetting $sid restartstate "LOCAL"
			} elseif {$restartState == "REMOTE"} {
				#round restarts
				setSetting $sid restartstate ""
				::MSNGamesPlugins::trigger $sid restart
				after 1000 "::MSNGamesInterface::checkHandshake $sid"
			}
		} else {
			if {$restartState == ""} {
				setSetting $sid restartstate "LOCAL"
			} elseif {$restartState == "REMOTEYES"} {
				setSetting $sid restartstate "LOCALYES"
			} elseif {$restartState == "REMOTEEND"} {
				setSetting $sid restartstate "LOCALEND"
			} elseif {$restartState == "REMOTE"} {
				#round restarts
				setSetting $sid restartstate ""
				::MSNGamesPlugins::trigger $sid restart
				after 1000 "::MSNGamesInterface::checkHandshake $sid"
			}
		}
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
		removeSettings $sid
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
	
	proc checkHandshake {sid} {
		if {![::MSNGamesInterface::getSetting $sid opponentready 0]} {
			after 1000 "::MSNGamesInterface::checkHandshake $sid"
			return
		}
	
		set handshakeState [getSetting $sid handshakestate ""]
		if {$handshakeState == "" && [getSetting $sid inviter 0] == 1} {
			setSetting $sid handshakestate "REQUEST"
		
			#generate guid and sendout handshake
			set guid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
			::MSNGames::SendData $sid [::MSNGames::buildGameMessage "0:SendGameGuid:\{$guid\}"]
		}
	}
	
	proc receiveData {sid data} {
		status_log "MSNGamesInterface-receiveData: data = $data" blue
		
		set recv [split $data :]
		if {[lindex $recv 0] == "0"} {
			#message in the messenger layer
			if {[lindex $recv 1] == "SendGameGuid" && [getSetting $sid handshakestate ""] == ""} {
				setSetting $sid handshakestate "READY"
				setSetting $sid gotreset 0

				#simply fake ticket data with DUMMY, the other side should accept that but scoring will not work
				#TODO: if we want to use the server-side scoring we should replace DUMMY by the ticket-ID that
				#      can be requested from the MSN-server
				::MSNGames::SendData $sid [::MSNGames::buildGameMessage "0:SendSignedTicket:[::config::getKey login]:DUMMY"]

				#tell local game that handshake is complete
				::MSNGamesPlugins::trigger $sid gamestart
			} elseif {[lindex $recv 1] == "SendSignedTicket" && [getSetting $sid handshakestate ""] == "REQUEST"} {
				setSetting $sid handshakestate "READY"
				setSetting $sid gotreset 0
				
				#tell local game that handshake is complete
				::MSNGamesPlugins::trigger $sid gamestart
			} elseif {[lindex $recv 1] == "PlayerClickedYes"} {
				if {[getSetting $sid gotreset 0] == 0} {
					setSetting $sid gotreset 1
					::MSNGamesPlugins::trigger $sid gameend
				}
			
				set restartState [getSetting $sid restartstate ""]
				if {[getSetting $sid inviter 0] == 0} {
					if {$restartState == ""} {
						setSetting $sid restartstate "REMOTE"
					} elseif {$restartState == "LOCAL"} {
						#round restarts
						setSetting $sid restartstate ""
						::MSNGamesPlugins::trigger $sid restart
						after 1000 "::MSNGamesInterface::checkHandshake $sid"
					}
				} else {
					if {$restartState == ""} {
						setSetting $sid restartstate "REMOTEYES"
					} elseif {$restartState == "REMOTEEND"} {
						setSetting $sid restartstate "REMOTE"
					} elseif {$restartState == "LOCAL" } {
						setSetting $sid restartstate "LOCALYES"
					} elseif {$restartState == "LOCALEND"} {
						#round restarts
						setSetting $sid restartstate ""
						::MSNGamesPlugins::trigger $sid restart
						after 1000 "::MSNGamesInterface::checkHandshake $sid"
					}
				}
			} elseif {[lindex $recv 1] == "GameEnd"} {
				if {[getSetting $sid gotreset 0] == 0} {
					setSetting $sid gotreset 1
					::MSNGamesPlugins::trigger $sid gameend
				}
			
				set restartState [getSetting $sid restartstate ""]
				if {[getSetting $sid inviter 0] == 0} {
					#just ignore it
				} else {
					if {$restartState == ""} {
						setSetting $sid restartstate "REMOTEEND"
					} elseif {$restartState == "REMOTEYES"} {
						setSetting $sid restartstate "REMOTE"
					} elseif {$restartState == "LOCAL" } {
						setSetting $sid restartstate "LOCALEND"
					} elseif {$restartState == "LOCALYES"} {
						#round restarts
						setSetting $sid restartstate ""
						::MSNGamesPlugins::trigger $sid restart
						after 1000 "::MSNGamesInterface::checkHandshake $sid"
					}
				}
			} elseif {[getSetting $sid handshakestate ""] == "READY"} {
				#send message to game plugin
				::MSNGamesPlugins::trigger $sid message $data
			}
		} elseif {[getSetting $sid handshakestate ""] == "READY"} {
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
			set $appId [set plugin(appId)]
			
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
