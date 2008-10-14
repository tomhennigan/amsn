#	Microsoft Messenger Protocol Implementation
#=======================================================================

::Version::setSubversionId {$Id$}

if { $initialize_amsn == 1 } {
	global list_BLP list_cmdhnd sb_list contactlist_loaded

	set contactlist_loaded 0

	#To be deprecated and replaced with ::abook thing
	set list_BLP -1

	#Clear all user infomation
	::abook::clearData

	set list_cmdhnd [list]

	set sb_list [list]


	package require base64
	package require sha1
	if { [version_vcompare [info patchlevel] 8.4.13] >= 0} {
		package require snit
	} else {
		source utils/snit/snit.tcl
	}
}


namespace eval ::MSNFT {
	namespace export inviteFT acceptFT rejectFT

	#TODO: Instead of using a list, use many variables: ft_name, ft_sockid...

	# If type is = 1 then it's an MSNP2P file send
	proc invitationReceived { filename filesize cookie chatid fromlogin {type "0"}} {
		variable filedata

		if { $type == 0 } {
			set filedata($cookie) [list "$filename" $filesize $chatid $fromlogin "receivewait" "ipaddr"]
			after 300000 "::MSNFT::DeleteFT $cookie"
			SendMessageFIFO [list ::amsn::fileTransferRecv $filename $filesize $cookie $chatid $fromlogin] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
			#set filetoreceive [list "$filename" $filesize]
		} elseif { $type == 1 } {
			set filedata($cookie) [list "$filename" $filesize $chatid $fromlogin]
		}
	}

	proc acceptReceived {cookie chatid fromlogin message} {

		variable filedata

		#status_log "DATA: $cookie $chatid $fromlogin $message $body\n"

		if {![info exists filedata($cookie)]} {
			return
		}

		#set requestdata [string range $requestdata 0 [expr {[string length requestdata] -2}]]
		set requestdata [$message getField Request-Data]

		status_log "Ok, so here we have cookie=$cookie, requestdata=$requestdata\n" red

		if { $requestdata != "IP-Address:" } {
			status_log "Requested data is not IP-Address!!: $requestdata\n" red
			return
		}

		set ipaddr [$message getField IP-Address]

		#If IP field is blank, and we are sender, Send the File and requested IP (SendFile)
		if { ($ipaddr == "") && ([getTransferType $cookie]=="send") } {
			status_log "Invitation to filetransfer $cookie accepted\n" black
			SendMessageFIFO [list ::amsn::acceptedFT $chatid $fromlogin [getFilename $cookie]] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
			set newcookie [::md5::md5 "$cookie$fromlogin"]
			set filedata($newcookie) $filedata($cookie)
			SendFile $newcookie $cookie
			#TODO: Show accept or reject messages from other users? (If transferType=="receive")
		} elseif {($ipaddr == "") && ([getTransferType $cookie]!="send")} {
			SendMessageFIFO [list ::amsn::acceptedFT $chatid $fromlogin [getFilename $cookie]] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
		#If message comes from sender, and we are receiver, connect
		} elseif { ($fromlogin == [lindex $filedata($cookie) 3]) && ([getTransferType $cookie]=="receive")} {
			after cancel "::MSNFT::timeoutedFT $cookie"
			set port [$message getField Port]
			set authcookie [$message getField AuthCookie]
			#status_log "Body: $body\n"
			ConnectMSNFTP $ipaddr $port $authcookie $cookie
		}
	}

	proc getUsername { cookie } {
		variable filedata
		if {[info exists filedata($cookie)]} {
			return [lindex $filedata($cookie) 3]
		}
		return ""
	}

	proc getFilename { cookie } {
		variable filedata
		if {[info exists filedata($cookie)]} {
			return [lindex $filedata($cookie) 0]
		}
		return ""
	}

	proc getTransferType { cookie } {
		variable filedata
		if {[info exists filedata($cookie)]} {
			return [lindex $filedata($cookie) 4]
		}
		return ""
	}



	proc cancelFT { cookie } {
		variable filedata
		if {[info exists filedata($cookie)]} {
			::amsn::FTProgress ca $cookie [lindex $filedata($cookie) 0]
			set sockid [lindex $filedata($cookie) 6]
			catch {puts $sockid "CCL\n"}
			DeleteFT $cookie
			status_log "File transfer manually canceled\n"
		}
	}

	proc timeoutedFT { cookie } {
		variable filedata
		after cancel "::MSNFT::timeoutedFT $cookie"
		if {[info exists filedata($cookie)]} {
			::amsn::FTProgress e $cookie [lindex $filedata($cookie) 0]
			DeleteFT $cookie
			status_log "File transfer timeouted\n"
		}
	}

	proc FinishedFT { cookie } {
		variable filedata

		set filename [file join [::config::getKey receiveddir] [lindex $filedata($cookie) 0] ]
		set finishedname [filenoext $filename]
		if { [string range $filename [expr [string length $filename] - 11] [string length $filename]] == ".incomplete" } {
			if { [catch { file rename $filename $finishedname } ] } {
				::amsn::infoMsg [trans couldnotrename $filename] warning
			}
		}

		DeleteFT $cookie
		status_log "File transfer finished ok\n"
	}

	proc DeleteFT { cookie } {
		variable filedata
		if {[info exists filedata($cookie)] }  {
			set sockid [lindex $filedata($cookie) 6]
			set fileid [lindex $filedata($cookie) 7]
			status_log "Closing FT socket $sockid\n"
			catch {fileevent $sockid writable ""}
			catch {fileevent $sockid readable ""}
			catch {close $sockid}
			status_log "Closing FT file $fileid\n"
			catch {close $fileid}

			unset filedata($cookie)
		}
	}


	#################################
	#All about receiving files
	#################################

	proc acceptFT {chatid cookie} {
		#Send the acceptation for a file transfer, request IP
		variable filedata


		if { ![info exists filedata($cookie)]} {
			return -1
		}

		after cancel "::MSNFT::DeleteFT $cookie"
		set filedata($cookie) [lreplace $filedata($cookie) 4 4 "receive"]

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
		set msg "${msg}Invitation-Command: ACCEPT\r\n"
		set msg "${msg}Invitation-Cookie: $cookie\r\n"
		set msg "${msg}Launch-Application: FALSE\r\n"
		set msg "${msg}Request-Data: IP-Address:\r\n\r\n"
		set msg [encoding convertto utf-8 $msg]
		set msg_len [string length $msg]

		set sbn [::MSN::SBFor $chatid]
		if {$sbn == 0 } {
			cancelFT $cookie
			return 0
		}

		set sock [$sbn cget -sock]
		::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"

		after 20000 "::MSNFT::timeoutedFT $cookie"
		::amsn::FTProgress a $cookie [lindex $filedata($cookie) 0]

		return 1
	}


	proc rejectFT {chatid cookie} {
		set sbn [::MSN::SBFor $chatid]
		if {$sbn == 0 } {
			cancelFT $cookie
			return 0
		}

		#Send the cancellation for a file transfer
		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
		set msg "${msg}Invitation-Command: CANCEL\r\n"
		set msg "${msg}Invitation-Cookie: $cookie\r\n"
		set msg "${msg}Cancel-Code: REJECT\r\n\r\n"
		set msg [encoding convertto utf-8 $msg]
		set msg_len [string length $msg]
		::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"

		status_log "Rejecting filetransfer sent\n" red
		cancelFT $cookie
	}


	proc ConnectMSNFTP {ipaddr port authcookie cookie} {
		#I connect to a remote host to retrieve the file
		variable filedata

		if {![info exists filedata($cookie)]} {
			status_log "ConnectMSNFTP: Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
			return
		}

		status_log "Connecting to $ipaddr port $port\n"
		::amsn::FTProgress c $cookie [lindex $filedata($cookie) 0] $ipaddr $port

		if { [catch {set sockid [socket -async $ipaddr $port]} res ]} {
			set filename [lindex $filedata($cookie) 0]
			cancelFT $cookie
			::amsn::FTProgress e $cookie $filename
			return
		}

		lappend filedata($cookie) $sockid

		#TODO: What are we cancelling here?
		after cancel "::MSNFT::cancelFT $cookie"
		fconfigure $sockid -blocking 0 -translation {binary binary} -buffering line
		fileevent $sockid writable "::MSNFT::ConnectedMSNFTP $sockid $authcookie $cookie"
	}

	proc ConnectedMSNFTP {sockid authcookie cookie} {
		variable filedata

		if {![info exists filedata($cookie)]} {
			status_log "ConnectedMSNFTP: Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
			return
		}

		set error_msg [fconfigure $sockid -error]

		if {$error_msg != ""} {
			status_log "Can't connect to server: $error_msg!!\n" white
			set filename [lindex $filedata($cookie) 0]
			cancelFT $cookie
			::amsn::FTProgress e $cookie $filename
			return
		}

		fileevent $sockid writable ""
		fileevent $sockid readable "::MSNFT::FTNegotiation $sockid $cookie 0 $authcookie"

		status_log "Connected, going to give my identity\n"
		::amsn::FTProgress i $cookie [lindex $filedata($cookie) 0]

		status_log "I SEND: VER MSNFTP\r\n"
		catch {puts $sockid "VER MSNFTP\r"}

	}

	proc FTNegotiation { sockid cookie state {authcookie ""}} {
		variable filedata

		if {![info exists filedata($cookie)]} {
			status_log "ConnectedMSNFTP: Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
			return
		}

		if { [eof $sockid] } {
			status_log "FTNegotiation:: EOF\n" white
			set filename [lindex $filedata($cookie) 0]
			cancelFT $cookie
			::amsn::FTProgress l $cookie $filename
			return
		}

		gets $sockid tmpdata
		status_log "FTNegotiation: I RECEIVE: $tmpdata\n"

		if { $tmpdata == "" } {
			update idletasks
			return
		}

		switch -- $state {
			0 {
				if {[string range $tmpdata 0 9] == "VER MSNFTP"} {
					catch {fileevent $sockid readable "::MSNFT::FTNegotiation $sockid $cookie 1"}
					catch {puts $sockid "USR [::config::getKey login] $authcookie\r"}
					status_log "FTNegotiation: I SEND: USR [::config::getKey login] $authcookie\r\n"
				} else {
					status_log "FT failed in state 0\n" red
					set filename [lindex $filedata($cookie) 0]
					cancelFT $cookie
					::amsn::FTProgress l $cookie $filename
				}
			}
			
			1 {
				if {[string range $tmpdata 0 2] == "FIL"} {
					set filesize [string range $tmpdata 4 [expr {[string length $tmpdata]-2}]]

					if { "$filesize" != "[lindex $filedata($cookie) 1]" } {
						status_log "Filesize is now $filesize and was [lindex $filedata($cookie) 1] before!!\n" white
					}

					status_log "FTNegotiation: They send me file with size $filesize\n"
					catch {puts $sockid "TFR\r"}
					status_log "Receiving file...\n"

					set filename [file join [::config::getKey receiveddir] [lindex $filedata($cookie) 0]]
					set origfile $filename

					set num 1
					while { [file exists $filename] } {
						set filename "[filenoext $origfile] $num[fileext $origfile]"
						incr num
					}

					if {[catch {open $filename w} fileid]} {
						# Cannot create this file. Abort.
						status_log "Could not saved the file '$filename' (write-protected target directory?)\n" red
						cancelFT $cookie
						::amsn::FTProgress l $cookie $filename
						::amsn::infoMsg [trans readonlymsgbox] warning
						return
					}
				
					lappend filedata($cookie) $fileid
					fconfigure $fileid -blocking 1 -buffering none -translation {binary binary}

					#Receive the file
					fconfigure $sockid -blocking 0 -translation {binary binary} -buffering full -buffersize 16384
					catch {fileevent $sockid readable "::MSNFT::ReceivePacket $sockid $fileid $filesize $cookie"}
				} else {
					status_log "FT failed in state 1\n" red
					set filename [lindex $filedata($cookie) 0]
					cancelFT $cookie
					::amsn::FTProgress l $cookie $filename
				}

			}
			
			default {
				status_log "FTNegotiation: Unknown state!!!\n" white
				cancelFT $cookie
			}
		}
	}

	proc ReceivePacket { sockid fileid filesize cookie} {
		#Get a packet from the file transfer
		variable filedata

		if {![info exists filedata($cookie)]} {
			status_log "ConnectedMSNFTP: Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
			return
		}


		if { [eof $sockid] } {
			status_log "ReveivePacket EOF\n" white
			set filename [lindex $filedata($cookie) 0]
			cancelFT $cookie
			::amsn::FTProgress l $cookie $filename
			return
		}

		fileevent $sockid readable ""

		set recvbytes [tell $fileid]
		set packetrest [expr {2045 - ($recvbytes % 2045)}]


		if {$packetrest == 2045} {
			#Need a full packet, header included

			::amsn::FTProgress r $cookie [lindex $filedata($cookie) 0] $recvbytes $filesize
			update idletasks

			fconfigure $sockid -blocking 1
			set header [read $sockid 3]

			set packet1 1
			binary scan $header ccc packet1 packet2 packet3

			#If packet1 is 1 -- Transfer canceled by the other
			if { ($packet1 != 0) } {
				status_log "File transfer cancelled by remote with packet1=$packet1\n"
				cancelFT $cookie
				return
			}

			#If you want to cancel, send "CCL\n"
			set packet2 [expr {($packet2 + 0x100) % 0x100}]
			set packet3 [expr {($packet3 + 0x100) % 0x100}]
			set packetsize [expr {$packet2 + ($packet3<<8)}]

			set firstbyte [read $sockid 1]
			catch {puts -nonewline $fileid $firstbyte}

			fconfigure $sockid -blocking 0

			set recvbytes [tell $fileid]
			#::amsn::fileTransferProgress r $cookie $recvbytes $filesize
		} else {
			#A full packet didn't come the previous reading, read the rest
			set thedata [read $sockid $packetrest]
			catch {puts -nonewline $fileid $thedata}
			set recvbytes [tell $fileid]
		}

		if { $recvbytes >= $filesize} {
			#::amsn::fileTransferProgress r $cookie $recvbytes $filesize
			catch {puts $sockid "BYE 16777989\r"}
			status_log "File received\n"
			::amsn::FTProgress fr $cookie [lindex $filedata($cookie) 0] $recvbytes $filesize
			FinishedFT $cookie
		} else {
			fileevent $sockid readable "::MSNFT::ReceivePacket $sockid $fileid $filesize $cookie"
		}
	}


	###################################
	#All about sending files
	###################################

	proc supportsNewFT { clientid } {

		# If a user chats with you while being as "Appear offline", his client ID will be empty, and we don't want a crash in that case.
		# We assume the user supports new FT because only WLM 8.1+ allows you to chat while being as appear offline.
		if { $clientid == [list] } {
			status_log "supportsNewFT: Empty clientid for FT (user invisible/offline?)" white
			return 1
		}

		set msnc [expr 0xF0000000]

		if { ($clientid & $msnc) !=  0 } {
			return 1
		}

		return 0

	}

	proc sendFTInvitation { chatid filename filesize ipaddr cookie} {
		#Invitation to filetransfer, initial message
		variable filedata

		if {[supportsNewFT [::abook::getContactData $chatid clientid]]} {
			set sid [::MSN6FT::SendFT $chatid $filename $filesize]
			setObjOption $cookie msn6ftsid $sid
			setObjOption $sid theCookie $cookie
			return 0
		}


		set sbn [::MSN::SBFor $chatid]
		if {$sbn == 0 } {
			return 0
		}

		status_log "sentFTInvitation: filename (not converted to utf-8) is [file tail $filename]\n" blue
		status_log "sentFTInvitation: filename (converted to utf-8) is [encoding convertto utf-8 [file tail $filename]]\n" blue

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
		set msg "${msg}Application-Name: File Transfer\r\n"
		set msg "${msg}Application-GUID: {5D3E02AB-6190-11d3-BBBB-00C04F795683}\r\n"
		set msg "${msg}Invitation-Command: INVITE\r\n"
		set msg "${msg}Invitation-Cookie: $cookie\r\n"
		set msg "${msg}Application-File: [file tail $filename]\r\n"
		set msg "${msg}Application-FileSize: $filesize\r\n\r\n"
		set msg [encoding convertto utf-8 $msg]
		set msg_len [string length $msg]

		::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"

		status_log "sentFTInvitation: Invitation to $filename sent: $msg\n" red

		#Change to allow multiple filetransfer
		#set filedata($cookie) [list $sbn "$filename" $filesize $cookie $ipaddr]
		set filedata($cookie) [list "$filename" $filesize $chatid [::MSN::usersInChat $chatid] "send" $ipaddr]
		after 300000 "::MSNFT::DeleteFT $cookie"

	}

	proc cancelFTInvitation { chatid cookie } {
		set sid [getObjOption $cookie msn6ftsid]
		if { $sid != "" } {
			::MSN6FT::CancelFT $chatid $sid
			DeleteFT $cookie
		} else {
			rejectFT $chatid $cookie
		}
	}

	proc rejectedFT {chatid who cookie} {
		variable filedata

		if {![info exists filedata($cookie)]} {
			return
		}

		SendMessageFIFO [list ::amsn::rejectedFT $chatid $who [getFilename $cookie] ] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

	}


	proc SendFile { cookie oldcookie} {
		#File transfer accepted by remote, send final ACK
		variable filedata

		status_log "Here in sendfile\n" red
		if {![info exists filedata($cookie)]} {
			return
		}

		status_log "File transfer ok, begin\n"

		set sbn [::MSN::SBFor [lindex $filedata($cookie) 2]]

		if { $sbn == 0 } {
			cancelFT $cookie
			return
		}

		#Invitation accepted, send IP and Port to connect to
		#option: possibility to enter IP address (firewalled connections)
		set ipaddr [lindex $filedata($cookie) 5]
		#if error ::AMSN::Error ...

		if {![string is digit [::config::getKey initialftport]] || [string length [::config::getKey initialftport]] == 0} {
			::config::setKey initialftport 6891
		}

		set port [::config::getKey initialftport]


		#Random authcookie
		set authcookie [expr {[clock clicks] % (65536 * 4)}]

		while {[catch {set sockid [socket -server "::MSNFT::AcceptConnection $cookie $authcookie" $port]} res]} {
			incr port
		}

		#TODO: More than one transfer? Don't create one listening socket for every person, just one for all,
		# but that makes the authcookie thing difficult...
		lappend filedata($oldcookie) $sockid
		after 300000 "catch {close $sockid}"

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
		set msg "${msg}Invitation-Command: ACCEPT\r\n"
		set msg "${msg}Invitation-Cookie: $oldcookie\r\n"
		set msg "${msg}IP-Address: $ipaddr\r\n"
		set msg "${msg}Port: $port\r\n"
		set msg "${msg}AuthCookie: $authcookie\r\n"
		set msg "${msg}Launch-Application: FALSE\r\n"
		set msg "${msg}Request-Data: IP-Address:\r\n\r\n"
		set msg [encoding convertto utf-8 $msg]

		set msg_len [string length $msg]
		::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"

		::amsn::FTProgress w $cookie [lindex $filedata($cookie) 0] $port

		status_log "Listening on port $port for incoming connections...\n" red

	}


	proc AcceptConnection {cookie authcookie sockid hostaddr hostport} {


		variable filedata

		if {![info exists filedata($cookie)]} {
			status_log "AcceptConnection: Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
			return
		}

		lappend filedata($cookie) $sockid

		status_log "::MSNFT::AcceptConnection have connection from $hostaddr : $hostport\n" white

		fconfigure $sockid -blocking 0 -buffering none -translation {binary binary}
		fileevent $sockid readable "::MSNFT::FTSendNegotiation $sockid $cookie 0 $authcookie"

		::amsn::FTProgress i $cookie [lindex $filedata($cookie) 0]

	}

	proc FTSendNegotiation { sockid cookie state {authcookie ""}} {
		variable filedata

		if {![info exists filedata($cookie)]} {
			status_log "ConnectedMSNFTP: Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
			return
		}


		if { [eof $sockid] } {
			status_log "FTSendNegotiation:: EOF\n" white
			set filename [lindex $filedata($cookie) 0]
			cancelFT $cookie
			::amsn::FTProgress l $cookie $filename
			return
		}

		gets $sockid tmpdata
		status_log "FTNegotiation: I RECEIVE: $tmpdata\n"

		if { $tmpdata == "" } {

			update idletasks
			return
		}

		switch -- $state {
			0 {
				if { [regexp "^VER\ ?\[0-9\]* MSNFTP" $tmpdata] } {
					catch {fileevent $sockid readable "::MSNFT::FTSendNegotiation $sockid $cookie 1 $authcookie"}
					catch {puts $sockid "VER MSNFTP\r"}

					status_log "FTSendNegotiation: I SEND: VER MSNFTP\r\n"
				} else {
					status_log "FT failed in state 0\n" red
					cancelFT $cookie
				}

			}
			1 {

				if {[string range $tmpdata 0 2] == "USR"} {
					set filename [lindex $filedata($cookie) 0]
					set filesize [lindex $filedata($cookie) 1]

					catch {fileevent $sockid readable "::MSNFT::FTSendNegotiation $sockid $cookie 2"}
					catch {puts $sockid "FIL $filesize\r"}
					status_log "SENT: FIL $filesize\n"
				} else {
					status_log "FT failed in state 1\n" red
					cancelFT $cookie
				}
			}
			
			2 {
				if {[string range $tmpdata 0 2] == "TFR"} {
					set filename [lindex $filedata($cookie) 0]
					set filesize [lindex $filedata($cookie) 1]

					#Send the file
					#TODO, what if not exists?
					if {[catch {set fileid [open $filename r]} res]} {
						return 0;
					}
				
					lappend filedata($cookie) $fileid

					fconfigure $fileid -translation {binary binary} -blocking 1
					status_log "Sending file $filename size $filesize\n"

					fconfigure $sockid -blocking 0 -buffering full -buffersize 16384
					fileevent $sockid writable "::MSNFT::SendPacket $sockid $fileid $filesize $cookie"
					fileevent $sockid readable "::MSNFT::MonitorTransfer $sockid $cookie"
				} else {
					status_log "FT failed in state 2\n" red
					cancelFT $cookie
				}

			}
	
			default {
				status_log "FTNegotiation: Unknown state!!!\n" white
				cancelFT $cookie
			}
		}
	}


	proc SendPacket { sockid fileid filesize cookie } {
		variable filedata

		if {![info exists filedata($cookie)]} {
			status_log "ConnectedMSNFTP: Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
			return
		}

		#Send a packet for the file transfer
		fileevent $sockid writable ""

		set sentbytes [tell $fileid]

		set packetsize [expr {$filesize-$sentbytes}]
		if {$packetsize > 2045} {
			set packetsize 2045
		}


		if {$packetsize>0} {
			set data [read $fileid $packetsize]

			set byte1 [expr {$packetsize & 0xFF}]
			set byte2 [expr {$packetsize >> 8}]

			catch {puts -nonewline $sockid "\0[format %c $byte1][format %c $byte2]$data" ; flush $sockid }
			set sentbytes [expr {$sentbytes + $packetsize}]
			::amsn::FTProgress s $cookie [lindex $filedata($cookie) 0] $sentbytes $filesize
			fileevent $sockid writable "::MSNFT::SendPacket $sockid $fileid $filesize $cookie"

		}
	}

	proc MonitorTransfer { sockid cookie} {

		#puts "Monitortransfer"
		variable filedata

		if {![info exists filedata($cookie)]} {
			status_log "::MSNFT::MonitorTransfer:  Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
			return
		}

		if { [eof $sockid] } {
			status_log "MonitorTransfer EOF\n" white
			cancelFT $cookie
			return
		}

		fileevent $sockid readable ""

		#Monitor messages from the receiving host in a file transfer
		catch {fconfigure $sockid -blocking 1}
		if {[catch {gets $sockid datos} res]} {
			status_log "::MSNFT::MonitorTransfer: Transfer failed: $res\n"
			cancelFT $cookie
			return
		}

		status_log "Got from remote side: $datos\n"
		if {[string range $datos 0 2] == "CCL"} {
			status_log "::MSNFT::MonitorTransfer: Connection cancelled\n"
			cancelFT $cookie
			return
		}

		if {[string range $datos 0 2] == "BYE"} {
			status_log "::MSNFT::MonitorTransfer: Connection finished\n"
			::amsn::FTProgress fs $cookie [lindex $filedata($cookie) 0]
			FinishedFT $cookie
			return
		}

		cancelFT $cookie
	}

}

namespace eval ::MSN {

	#TODO: Export missing procedures (the one whose starts with lowercase)
	namespace export changeName logout changeStatus connect blockUser \
	unblockUser addUser removeUserFromGroup deleteUser login myStatusIs \
	cancelReceiving cancelSending moveUser

	if { $initialize_amsn == 1 } {
		#Forward list
		variable list_FL [list]
		#Reverse List
		variable list_RL [list]
		#Accept List
		variable list_AL [list]
		#Block list
		variable list_BL [list]
		#Pending list (MSNP11)
		variable list_PL [list]
		#Email (Non-IM) list (MSNP15)
		variable list_EL [list]

		variable list_users ""

		variable myStatus FLN
		#Double array containing:
		# CODE NAME COLOR ONLINE/OFFLINE  SMALLIMAGE BIGIMAGE
		variable list_states {
			{NLN online #0000A0 online online bonline}
			{IDL noactivity #008000 online away baway}
			{BRB rightback #008080 online away baway}
			{PHN onphone #008080 online busy bbusy}
			{BSY busy #800000 online busy bbusy}
			{AWY away #008000 online away baway}
			{LUN gonelunch #008000 online away baway}
			{HDN appearoff #404040 offline offline boffline}
			{FLN offline #404040 offline offline boffline}
		}
	}


	proc reconnect { error_msg } {
		global reconnect_timer reconnect_timer_remaining

		if {![info exists reconnect_timer] || $reconnect_timer < 5000} {
			set reconnect_timer 5000
		} else {
			set reconnect_timer [expr {$reconnect_timer * 2}]
		}
		if {$reconnect_timer > 900000 } {
			set reconnect_timer 900000
		}

		set reconnect_timer_remaining $reconnect_timer

		cmsn_draw_reconnect $error_msg
		after $reconnect_timer ::MSN::connect

	}
	
	proc saveOldStatus { {status "" } {amessage ""} } {
		global oldstatus
		global automessage

		if {$status != "" } {
			set oldstatus $status
		} else {
			set oldstatus [::MSN::myStatusIs]
		}

		if { $amessage == "" } {
			if { [info exists automessage] } {
				set automsg $automessage
			} else {
				set automsg -1
			}
		} else {
			set automsg $amessage			
		}

		if {$automsg != -1 } {
			for {set idx 0} {$idx < [StateList size] } { incr idx } {
				if { [StateList get $idx] == $automsg} {
					set oldstatus $idx
				}
			}
		}
	}
	proc cancelReconnect { } {
		global reconnect_timer
		set reconnect_timer 0

		after cancel ::MSN::connect
		after cancel cmsn_update_reconnect_timer
		catch { unset ::oldstatus }
		::MSN::logout
		cmsn_draw_offline

	}


	proc connect { {passwd ""}} {
		#Cancel any pending reconnect
		after cancel ::MSN::connect
		after cancel cmsn_update_reconnect_timer

		if { [ns cget -stat] != "d" } {
			return
		}

		set username [::config::getKey login]

		if { $passwd == "" } {
			global password
			set passwd [set password]
		}
		if {$passwd == "" } {
			return
		}

		if {[::config::getKey protocol] >= 15} {
			global sso
			if {[info exists sso] && $sso != "" } {
				$sso destroy
				set sso ""
			}
		}
		ns configure -stat "d" -sock "" \
			-server [split [::config::getKey start_ns_server] ":"]

		#Setup the conection
		setup_connection ns


		global tlsinstalled
		#Check if we need to install the TLS module
		if { $tlsinstalled == 0 && [checking_package_tls] == 0} {
			::autoupdate::installTLS
			return -1
		}

		#Call the pre authentication
		set proxy [ns cget -proxy]
		if { [::config::getKey protocol] < 13 } {
			if { [$proxy authInit] < 0 } {
				return -1
			}
		}

		# Test if farsight is available to set the sip clientcap
		# do it on every connect in case you changed protocol
		# version used, or change profile, etc...
		# Do it only if necessary (protocol >= 13)
		if { [::config::getKey protocol] >= 13 } {
			::MSNSIP::TestFarsight
		}

		cmsn_ns_connect $username $passwd

		::Event::fireEvent loggingIn protocol
	}


	proc logoutEP { ep } {
		set msg "goawyplzthxbye"
		::MSN::WriteSBNoNL ns "UUN" "[::config::getKey login];$ep 4 [string length $msg]\r\n$msg"
	}

	proc logoutGtfo {} {
		set msg "gtfo"
		foreach ep [::abook::getEndPoints] {
			if {![string equal -nocase $ep [::config::getGlobalKey machineguid]] } {
				::MSN::WriteSBNoNL ns "UUN" "[::config::getKey login];$ep 4 [string length $msg]\r\n$msg"
			}
		}
		logout
	}

	proc logout {} {
		after cancel cmsn_update_reconnect_timer

		::abook::lastSeen

		::log::eventlogout

		::MSN::WriteSBRaw ns "OUT\r\n";

		set proxy [ns cget -proxy]
		$proxy finish ns
		ns configure -stat "d"

		CloseSB ns

		global automessage

		ns configure -server [split [::config::getKey start_ns_server] ":"]

		setMyStatus FLN
		status_log "Loging out\n"

		if {[::config::getKey enablebanner] && [::config::getKey adverts]} {
			adv_pause
		}

		::groups::Disable

		StopPolling

		::abook::saveToDisk

		global list_BLP emailBList

		::MSN::clearList AL
		::MSN::clearList BL
		::MSN::clearList FL
		::MSN::clearList RL
		::MSN::clearList EL

		set list_BLP -1
		if { [info exists emailBList] } {
			unset emailBList
		}

		::abook::unsetConsistent

		#Try to update Preferences
		catch {InitPref 1}

		set automessage "-1"

		::plugins::PostEvent OnDisconnect evPar

		#an event to let the GUI know we are actually logged out now
		::Event::fireEvent loggedOut protocol

		set ::contactlist_loaded 0

		#Set all CW users as offline
		foreach user_name [::abook::getAllContacts] {
			::abook::setVolatileData $user_name state "FLN"
		}

		::abook::clearEndPoints

		foreach chat_id [::ChatWindow::getAllChatIds] {
			::ChatWindow::TopUpdate $chat_id
		}

		#Alert dock of status change
		send_dock "STATUS" "FLN"
		
		# Remove mail icon once offline.
		send_dock "MAIL" 0
	}

	#Callback procedure called when a UUX (PSM change) message is received
	proc GotUUXResponse { recv } {

		cmsn_draw_online 1 1
		#an event used by guicontactlist to know when we changed our nick
		::Event::fireEvent myNickChange protocol

	}

	#Callback procedure called when a ADC message is received
	proc GotADCResponse { recv } {
		set username ""
		set nickname ""
		set contactguid ""
		set curr_list ""
		set groups "0"
		#We skip ADC TrID
		foreach information [lrange $recv 2 end] {
			set key [string toupper [string range $information 0 1]]
			if { $key == "N=" } {
				set username [string range $information 2 end]
			} elseif { $key == "F=" } {
				set nickname [urldecode [string range $information 2 end]]
			} elseif { $key == "C=" } {
				set contactguid [string range $information 2 end]
			} elseif { $curr_list == "" } {
				#We didn't get the list names yet
				set curr_list $information
			} elseif { $groups == "0" } {
				#We didn't get the group list yet
				set groups $information
			}
		}
		if { $curr_list == "RL" && [lsearch [::abook::getLists $username] "PL"] == -1 && [lsearch [::abook::getLists $username] "AL"] == -1 && [lsearch [::abook::getLists $username] "BL"] == -1 } {
			newcontact $username $nickname
		} elseif { $curr_list == "RL" && ( [lsearch [::abook::getLists $username] "AL"] != -1 || [lsearch [::abook::getLists $username] "BL"] != -1 ) } {
			#Contact already in Allow List or Block List, so the notification window is useless, just silently remove from the PL:
			::MSN::WriteSB ns "REM" "PL $username"
		}
		if { $curr_list == "FL" } {
			status_log "Addition to FL"
			if { $username == "" } {
				#The server doesn't give the username so it gives the GUID
				set username [::abook::getContactForGuid $contactguid]
			} else {
				#It's a new contact so we save its guid and its nick
				::abook::setContactData $username contactguid $contactguid
				::abook::setContactForGuid $contactguid $username
				if {[::abook::getContactData $username nick ""] == ""} {
					::abook::setContactData $username nick $nickname
				}
			}
			status_log "$username was in groups [::abook::getGroups $username]"
			if {[::abook::getGroups $username] != "" && $groups == 0} {
				status_log "do nothing since a contact can't be in no group AND in a group"
			} else {
				::abook::addContactToGroup $username $groups
			}
			status_log "$username is in groups [::abook::getGroups $username]"
		}
		::abook::addContactToList $username $curr_list
		::MSN::addToList $curr_list $username

		::MSN::contactListChanged


		set contactlist_loaded 1
		::abook::setConsistent
		::abook::saveToDisk

		if { $curr_list != "FL" } {
			#there isn't any group for other lists than FL
			set groups ""
		}

		if { $curr_list == "FL" || $curr_list == "RL" } {
			#Don't send the event for an addition to any other list
			::Event::fireEvent contactAdded protocol $username $groups
		}
	}

	proc GotREMResponse { recv } {
		set list_sort [string toupper [lindex $recv 2]]

		if { [lindex $recv 2] == "FL" } {
			set userguid [lindex $recv 3]
			set user [::abook::getContactForGuid $userguid]
			if { [lindex $recv 4] == "" } {
				#Remove from all groups!!
				set affected_groups [::abook::getGroups $user]
				::abook::emptyUserGroups $user

				status_log "GotREMResponse: Contact $user isn't in any group, removing!!\n" blue
				::MSN::deleteFromList FL $user
				::abook::removeContactFromList $user FL
				#The GUID is invalid if the contact is removed from the FL list
				::abook::setContactForGuid $userguid ""
				::abook::setContactData $user contactguid ""
				::abook::clearVolatileData $user
			} else {
				#Remove fromonly one group
				set affected_groups [list [lindex $recv 4]]
				::abook::removeContactFromGroup $user [lindex $recv 4]
			}

			if { [::abook::getGroups $user] == [list 0] } {
				#User is now on nogroup
				::Event::fireEvent contactMoved protocol $user [linsert $affected_groups end 0]
				::Event::fireEvent contactAdded protocol $user 0
			} else {
				#an event to let the GUI know a user is removed from a group / the list
				::Event::fireEvent contactRemoved protocol $user $affected_groups
			}
		} else {
			set user [lindex $recv 3]
			::MSN::deleteFromList $list_sort $user
			::abook::removeContactFromList $user $list_sort
			#an event to let the GUI know a user is removed from a list
			::Event::fireEvent contactListChange protocol $user
		}

		global contactlist_loaded
		set contactlist_loaded 1

	}

	#Change a users nickname
	proc changeName { newname {update 1}} {
		set name [urlencode $newname]
		::MSN::WriteSB ns "PRP" "MFN $name" [list ns handlePRPResponse "$name" $update]

	}

	#Change a users personal message
	proc changePSM { newpsm {state ""} {update 1} {force 0} } {
		#TODO: encode XML etc
		if { $force  || [::abook::getPersonal PSM] != $newpsm } {
			::abook::setPersonal PSM $newpsm
			
			if {$update && [info exists ::roaming] && [::config::getKey protocol] >= 15 } {
				$::roaming UpdateProfile [list ns updateProfileCB] [::abook::getPersonal MFN] [::abook::getPersonal PSM]
			}
			
			# We catch because we might have a plugin changing
			# the psm when we are offline and we don't want a bugreport
			# if amsn hasn't finished loading
			# We also can't check if the state is != "FLN" since we need to send
			# the UUX data before the initial CHG
			catch {sendUUXData $state}

			save_config
			::abook::saveToDisk
		}
	}

	#changes the current media in the personal message
	#type: can be one of: Music, Games or Office
	#enabled: 0 or 1
	#format: A formatter string ala .Net; For example: {0} - {1}
	#args: list with the other things, first will match {0} in format	
	proc changeCurrentMedia { type enabled format args } {
		if {$enabled == 1} {
			set currentMedia "aMSN\\0$type\\01\\0$format\\0[join $args \\0]\\0"
		} else {
			set currentMedia ""
		}
		# Check if an update is necessary.
		if { [::abook::getVolatileData myself currentMedia] != ${currentMedia} } {
			::abook::setVolatileData myself currentMedia $currentMedia
			sendUUXData
		}
	}

	#Change a users personal message
	proc changeEndPointName { newname  } {
		::config::setKey epname $newname
		
		sendUUXData
		save_config
		::abook::saveToDisk
	}

	proc sendUUXData { {state ""} } {
		# Send Endpoint data
		if {[::config::getKey protocol] >= 16 } {
			global idletime
			if {$idletime >= [expr {[::config::getKey idletime] * 60}]} {
				set idle "true"
			} else {
				set idle "false"
			}

			if {$state == "" } {
				set state [::MSN::myStatusIs]
			}

			set epname [::config::getKey epname aMSN]
			set epname [::sxml::xmlreplace $epname]
			set epname [encoding convertto utf-8 $epname]

			set endpoint "<EndpointData><Capabilities>[::config::getKey clientid]:0</Capabilities></EndpointData>"
			set privateep "<PrivateEndpointData><EpName>$epname</EpName><Idle>$idle</Idle><State>$state</State></PrivateEndpointData>"

			::MSN::WriteSBNoNL ns "UUX" "[string length $endpoint]\r\n$endpoint"
			::MSN::WriteSBNoNL ns "UUX" "[string length $privateep]\r\n$privateep"
		}

		set psm [::abook::getPersonal PSM]
		set psm [::sxml::xmlreplace $psm]
		set psm [encoding convertto utf-8 $psm]

		set currentMedia [::abook::getVolatileData myself currentMedia]
		set currentMedia [::sxml::xmlreplace $currentMedia]
		set currentMedia [encoding convertto utf-8 $currentMedia]

		set machineguid [::config::getGlobalKey machineguid]
		set machineguid [::sxml::xmlreplace $machineguid]

		set data "<Data><PSM>$psm</PSM><CurrentMedia>$currentMedia</CurrentMedia><MachineGuid>$machineguid</MachineGuid>"
		if {[::config::getKey protocol] >= 16} {
			set signatureSound [::abook::getPersonal signatureSound]
			set signatureSound [::sxml::xmlreplace $signatureSound]
			set signatureSound [encoding convertto utf-8 $signatureSound]

			append data "<SignatureSound>$signatureSound</SignatureSound>"
		}
		append data "</Data>"
		::MSN::WriteSBNoNL ns "UUX" "[string length $data]\r\n$data"
	}

	#Procedure called to change our status
	proc changeStatus {new_status} {
		global autostatuschange

		if {[::config::getKey displaypic] == "" } {
			::config::setKey displaypic nopic.gif
		}
		if { [::config::getKey displaypic] != "nopic.gif" } {
			::MSN::WriteSB ns "CHG" "$new_status [::config::getKey clientid] [urlencode [create_msnobj [::config::getKey login] 3 [::skin::GetSkinFile displaypic [PathRelToAbs [::config::getKey displaypic]]]]]"
		} else {
			::MSN::WriteSB ns "CHG" "$new_status [::config::getKey clientid]"
		}

		#Reset automatic status change to 0
		set autostatuschange 0
	}

	# set a capability of the client
	# possiblities for cap are:
	# mobile Mobile Device
	# inkgif receive Ink as gif
	# inkisf receive Ink as ISF
	# webcam Webcam
	# multip Multi-Packeting
	# paging Paging
	# drctpg Direct-Paging
	# webmsn WebMessenger
	# tgw    Connected via TGW
	# space  User has an MSN Spaces
	# mce    Connected using Win XP Media Center Edition
	# direct DirectIM
	# winks  Winks
	# search Client supports Shared search
	# bot    Is Bot
	# voice  Client supports Voice Clips
	# secure Client supports secure channel chatting
	# sip    Client supports SIP based communiation
	# shared Client supports Shared Folders
	# msnc1  This is the value for MSNC1 (MSN Msgr 6.0)
	# msnc2  This is the value for MSNC2 (MSN Msgr 6.1)
	# msnc3  This is the value for MSNC3 (MSN Msgr 6.2)
	# msnc4  This is the value for MSNC4 (MSN Msgr 7.0)
	# msnc5  This is the value for MSNC5 (MSN Msgr 7.5)
	# msnc6  This is the value for MSNC5 (MSN Msgr 8.0)
	# msnc7  This is the value for MSNC5 (MSN Msgr 8.1)
	#
	#switch==1 means turn on, 0 means turn off 
	#
	# Reference : http://zoronax.spaces.live.com/?_c11_BlogPart_FullView=1&_c11_BlogPart_blogpart=blogview&_c=BlogPart&partqs=amonth%3d6%26ayear%3d2006
	#
	# From http://forums.fanatic.net.nz/index.php?showtopic=17639 thanks to Ole Andre 
	#define CapabilityMobileOnline 0x00000001
	#define CapabilityMSN8User 0x00000002
	#define CapabilityRendersGif 0x00000004
	#define CapabilityRendersIsf 0x00000008
	#define CapabilityWebCamDetected 0x00000010
	#define CapabilitySupportsChunking 0x00000020
	#define IsMobileEnabled 0x00000040
	#// FIXME: the canonical meaning of 0x00000080 is missing
	#define CapabilityWebIMClient 0x00000200
	#define CapabiltiyConnectedViaTGW 0x00000800
	#// FIXME: the canonical meaning of 0x00001000 is missing
	#define CapabilityMCEUser 0x00002000
	#define CapabilitySupportsDirectIM 0x00004000
	#define CapabilitySupportsWinks 0x00008000
	#define CapabilitySupportsSharedSearch 0x00010000
	#define CapabilityIsBot 0x00020000
	#define CapabilitySupportsVoiceIM 0x00040000
	#define CapabilitySupportsSChannel 0x00080000
	#define CapabilitySupportsSipInvite 0x00100000
	#define CapabilitySupportsSDrive 0x00400000
	#define CapabilityHasOnecare 0x01000000
	#define CapabilityP2PSupportsTurn 0x02000000
	#define CapabilityP2PBootstrapViaUUN 0x04000000
	#define CapabilityMsgrVersion 0xf0000000
	#define CapabilityP2PAware(id) ((id & CapabilityMsgrVersion) != 0)
	proc setClientCap { cap { switch 1 } } {
		set clientid [::config::getKey clientid 0]

		if $switch {
			switch -- $cap {
				mobile { set clientid [expr {$clientid | 0x000001} ] }
				inkgif { set clientid [expr {$clientid | 0x000004} ] }
				inkisf { set clientid [expr {$clientid | 0x000008} ] }
				webcam { set clientid [expr {$clientid | 0x000010} ] }
				multip { set clientid [expr {$clientid | 0x000020} ] }
				paging { set clientid [expr {$clientid | 0x000040} ] }
				drctpg { set clientid [expr {$clientid | 0x000080} ] }
				webmsn { set clientid [expr {$clientid | 0x000200} ] }
				tgw    { set clientid [expr {$clientid | 0x000800} ] }
				space  { set clientid [expr {$clientid | 0x001000} ] }
				mce    { set clientid [expr {$clientid | 0x002000} ] }
				direct { set clientid [expr {$clientid | 0x004000} ] }
				winks  { set clientid [expr {$clientid | 0x008000} ] }
				search { set clientid [expr {$clientid | 0x010000} ] }
				bot    { set clientid [expr {$clientid | 0x020000} ] }
				voice  { set clientid [expr {$clientid | 0x040000} ] }
				secure { set clientid [expr {$clientid | 0x080000} ] }
				sip    { set clientid [expr {$clientid | 0x100000} ] }
				shared { set clientid [expr {$clientid | 0x400000} ] }
				uun    { set clientid [expr {$clientid | 0x04000000} ] }
				msnc1  { set clientid [expr {$clientid | 0x10000000} ] }
				msnc2  { set clientid [expr {$clientid | 0x20000000} ] }
				msnc3  { set clientid [expr {$clientid | 0x30000000} ] }
				msnc4  { set clientid [expr {$clientid | 0x40000000} ] }
				msnc5  { set clientid [expr {$clientid | 0x50000000} ] }
				msnc6  { set clientid [expr {$clientid | 0x60000000} ] }
				msnc7  { set clientid [expr {$clientid | 0x70000000} ] }
				msnc8  { set clientid [expr {$clientid | 0x80000000} ] }
				msnc9  { set clientid [expr {$clientid | 0x90000000} ] }
			}
		} else {
			switch -- $cap {
				mobile { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x000001)} ] }
				inkgif { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x000004)} ] }
				inkisf { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x000008)} ] }
				webcam { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x000010)} ] }
				multip { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x000020)} ] }
				paging { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x000040)} ] }
				drctpg { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x000080)} ] }
				webmsn { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x000200)} ] }
				tgw    { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x000800)} ] }
				space  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x001000)} ] }
				mce    { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x002000)} ] }
				direct { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x004000)} ] }
				winks  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x008000)} ] }
				search { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x010000)} ] }
				bot    { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x020000)} ] }
				voice  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x040000)} ] }
				secure { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x080000)} ] }
				sip    { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x100000)} ] }
				shared { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x400000)} ] }
				uun    { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x04000000)} ] }
				msnc1  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x10000000)} ] }
				msnc2  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x20000000)} ] }
				msnc3  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x30000000)} ] }
				msnc4  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x40000000)} ] }
				msnc5  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x50000000)} ] }
				msnc6  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x60000000)} ] }
				msnc7  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x70000000)} ] }
				msnc8  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x80000000)} ] }
				msnc9  { set clientid [expr {$clientid & (0xFFFFFFFF ^ 0x90000000)} ] }
			}
		}
		::config::setKey clientid $clientid
		return $clientid
	}

	proc myStatusIs {} {
		variable myStatus
		return $myStatus
	}

	proc setMyStatus { status } {
		variable myStatus
		set myStatus $status
	}

	proc userIsNotIM {userlogin} {
		if { [lsearch  [::abook::getLists $userlogin] FL] == -1} {
			return 1
		}
		return 0

	}
	proc userIsBlocked {userlogin} {
		if { [lsearch  [::abook::getLists $userlogin] BL] != -1} {
			return 1
		}
		return 0

	}

	proc blockUser { userlogin } {
		if {[::config::getKey protocol] >= 13} {
			set users_to_delete [list]
			set users_to_add [list]
			foreach user $userlogin {
				if {[lsearch [::abook::getContactData $user lists] "FL"] == -1 &&
				    [lsearch [::abook::getContactData $user lists] "RL"] == -1} {
					continue
				}
				if {[lsearch [::abook::getContactData $user lists] "AL"] != -1} {
					lappend users_to_delete $user
				}
				if {[lsearch [::abook::getContactData $user lists] "BL"] == -1} {
					lappend users_to_add $user
				}
			}
			if {$users_to_add != [list] } {
				$::ab AddMember [list ::MSN::blockUserAddCB $users_to_delete $users_to_add] "BlockUnblock" $users_to_add "Block"
			} elseif {$users_to_delete != [list] } {
				$::ab DeleteMember [list ::MSN::blockUserDeleteCB $users_to_delete $users_to_add] "BlockUnblock" $users_to_delete "Allow"
			}
		} else {
			::MSN::WriteSB ns REM "AL $userlogin"
			::MSN::WriteSB ns ADC "BL N=$userlogin"
			
			#an event to let the GUI know a user is blocked
			after 500 [list ::Event::fireEvent contactBlocked protocol $userlogin]
			set evpar(userlogin) userlogin
			::plugins::PostEvent contactBlocked evpar
		}
	}

	proc blockUserAddCB { users_to_delete users_added fail } {
		if {$fail == 0 || $fail == 2} {
			$::ab DeleteMember [list ::MSN::blockUserDeleteCB $users_to_delete $users_added] "BlockUnblock" $users_to_delete "Allow"
		} else {
			set blocked_users [concat $users_to_delete $users_added]
			set blocked_users [lsort -unique $blocked_users]
			if {[llength $blocked_users] > 1 } {
				::MSN::blockUserGroupChained $blocked_users
			}
		}
	}

	proc blockUserGroupChained { users } {
		set user [lindex $users 0]
		set users [lreplace $users 0 0]

		::MSN::blockUser $user
		update
		after 100 [list ::MSN::blockUserGroupChained $users]
	}

	proc blockUserDeleteCB { users_deleted users_added fail } {
		if {$fail == 0 || $fail == 2} {
			foreach userlogin $users_deleted {
				set contact [split $userlogin "@"]
				set user [lindex $contact 0]
				set domain [lindex $contact 1]
				set xml "<ml><d n=\"$domain\"><c n=\"$user\" l=\"2\" t=\"1\"/></d></ml>"
				set xmllen [string length $xml]

				::MSN::WriteSBNoNL ns "RML" "$xmllen\r\n$xml"
				::abook::removeContactFromList $userlogin AL
				::MSN::deleteFromList AL $userlogin

			}
			foreach userlogin $users_added {
				set contact [split $userlogin "@"]
				set user [lindex $contact 0]
				set domain [lindex $contact 1]
				set xml "<ml><d n=\"$domain\"><c n=\"$user\" l=\"4\" t=\"1\"/></d></ml>"
				set xmlllen [string length $xml]
				::MSN::WriteSBNoNL ns "ADL" "$xmlllen\r\n$xml" [list ns handleADLResponse]
				
				::abook::addContactToList $userlogin BL
				::MSN::addToList BL $userlogin
				::MSN::contactListChanged
			}
			
			set blocked_users [concat $users_deleted $users_added]
			set blocked_users [lsort -unique $blocked_users]

			foreach userlogin $blocked_users {	
				#an event to let the GUI know a user is blocked
				::Event::fireEvent contactBlocked protocol $userlogin
				set evpar(userlogin) userlogin
				::plugins::PostEvent contactBlocked evpar
			}
		} elseif {$users_deleted != [list] } {
			$::ab DeleteMember [list ::MSN::blockUnblockUserFailureCB] "BlockUnblock" $users_deleted "Block"
		}
	}

	proc unblockUser { userlogin } {
		if {[::config::getKey protocol] >= 13} {
			set users_to_delete [list]
			set users_to_add [list]
			foreach user $userlogin {
				if {[lsearch [::abook::getContactData $user lists] "FL"] == -1 &&
				    [lsearch [::abook::getContactData $user lists] "RL"] == -1} {
					continue
				}
				if {[lsearch [::abook::getContactData $user lists] "BL"] != -1} {
					lappend users_to_delete $user
				}
				if {[lsearch [::abook::getContactData $user lists] "AL"] == -1} {
					lappend users_to_add $user
				}
			}
			if {$users_to_add != [list] } {
				$::ab AddMember [list ::MSN::unblockUserAddCB $users_to_delete $users_to_add] "BlockUnblock" $users_to_add "Allow"
			} elseif {$users_to_delete != [list] } {
				$::ab DeleteMember [list ::MSN::unblockUserDeleteCB $users_to_delete $users_to_add] "BlockUnblock" $users_to_delete "Block"
			}
		} else {
			::MSN::WriteSB ns REM "BL $userlogin"
			::MSN::WriteSB ns ADC "AL N=$userlogin"
		
			#an event to let the GUI know a user is unblocked
			after 500 [list ::Event::fireEvent contactUnblocked protocol $userlogin]
			set evpar(userlogin) userlogin
			::plugins::PostEvent contactUnblocked evpar
		}
	}

	proc unblockUserAddCB { users_to_delete users_added fail } {
		if {$fail == 0 || $fail == 2} {
			$::ab DeleteMember [list ::MSN::unblockUserDeleteCB $users_to_delete $users_added] "BlockUnblock" $users_to_delete "Block"
		} else {
			set unblocked_users [concat $users_to_delete $users_added]
			set unblocked_users [lsort -unique $unblocked_users]
			if {[llength $unblocked_users] > 1 } {
				::MSN::unblockUserGroupChained $unblocked_users
			}
		}
	}

	proc unblockUserGroupChained { users } {
		set user [lindex $users 0]
		set users [lreplace $users 0 0]

		::MSN::unblockUser $user
		update
		after 100 [list ::MSN::unblockUserGroupChained $users]
	}


	proc unblockUserDeleteCB { users_deleted users_added fail } {
		if {$fail == 0 || $fail == 2} {
			foreach userlogin $users_deleted {
				set contact [split $userlogin "@"]
				set user [lindex $contact 0]
				set domain [lindex $contact 1]
				set xml "<ml><d n=\"$domain\"><c n=\"$user\" l=\"4\" t=\"1\"/></d></ml>"
				set xmllen [string length $xml]

				::MSN::WriteSBNoNL ns "RML" "$xmllen\r\n$xml"
				::abook::removeContactFromList $userlogin BL
				::MSN::deleteFromList BL $userlogin

			}
			foreach userlogin $users_added {
				set contact [split $userlogin "@"]
				set user [lindex $contact 0]
				set domain [lindex $contact 1]
				set xml "<ml><d n=\"$domain\"><c n=\"$user\" l=\"2\" t=\"1\"/></d></ml>"
				set xmlllen [string length $xml]
				::MSN::WriteSBNoNL ns "ADL" "$xmlllen\r\n$xml" [list ns handleADLResponse]
				
				::abook::addContactToList $userlogin AL
				::MSN::addToList AL $userlogin
				::MSN::contactListChanged
			}
			
			set unblocked_users [concat $users_deleted $users_added]
			set unblocked_users [lsort -unique $unblocked_users]

			foreach userlogin $unblocked_users {	
				#an event to let the GUI know a user is blocked
				::Event::fireEvent contactUnblocked protocol $userlogin
				set evpar(userlogin) userlogin
				::plugins::PostEvent contactUnblocked evpar
			}
		} elseif {$users_deleted != [list] } {
			$::ab DeleteMember [list ::MSN::blockUnblockUserFailureCB] "BlockUnblock" $users_deleted "Allow"
		}
	}


	proc blockUnblockUserFailureCB { fail } {
		# Silently ignore anything here...
	}

	# Move user from one group to another group
	proc moveUser { passport oldGid newGid {userName ""}} {
		if { $userName == "" } {
			set userName $passport
		}
		if { $oldGid == $newGid } {
			return
		}

		set contactguid [::abook::getContactData $passport contactguid]
		if {[::config::getKey protocol] >= 13 } {
			$::ab ABGroupContactAdd [list ::MSN::moveUserCB $passport $newGid $oldGid] $newGid $contactguid
		} else {
			set atrid [::MSN::WriteSB ns "ADC" "FL C=$contactguid $newGid" "::MSN::MOVHandler $oldGid $contactguid $passport" ]
		}

		#an event to let the GUI know a user is moved between 2 groups
		::Event::fireEvent contactMoved protocol $passport [list $oldGid $newGid]

	}

	proc moveUserCB { passport newGid oldGid fail} {
		if {$fail == 0} {
			set affected_groups $newGid
			::abook::addContactToGroup $passport $newGid
			if { $oldGid != "0" } {
				set contactguid [::abook::getContactData $passport contactguid]
				$::ab ABGroupContactDelete [list ::MSN::moveUserDoneCB $passport $newGid $oldGid] $oldGid $contactguid
			} else {
				lappend affected_groups 0
				::abook::removeContactFromGroup $passport "0"
			}
			::Event::fireEvent contactAdded protocol $passport $affected_groups
		}
	}

	proc moveUserDoneCB { passport newGid oldGid fail} {
		if  {$fail == 0} {
			set affected_groups [::abook::getGroups $passport]
			::abook::removeContactFromGroup $passport $oldGid
			if { [::abook::getGroups $passport] == [list 0] } {
				#User is now on nogroup
				::Event::fireEvent contactMoved protocol $passport [linsert $affected_groups end 0]
				::Event::fireEvent contactAdded protocol $passport 0
			} else {
				#an event to let the GUI know a user is removed from a group / the list
				::Event::fireEvent contactRemoved protocol $passport $affected_groups
			}			
		}
	}

	#Copy user from one group to another
	proc copyUser { passport newGid {userName ""}} {
		if { $userName == "" } {
			set userName $passport
		}

		set contactguid [::abook::getContactData $passport contactguid]
		if {[::config::getKey protocol] >= 13 } {
			$::ab ABGroupContactAdd [list ::MSN::copyUserCB $passport $newGid] $newGid $contactguid
		} else {
		    set atrid [::MSN::WriteSB ns "ADC" "FL C=$contactguid $newGid"]
		}
	}

	proc copyUserCB { passport newGid fail} {
		if {$fail == 0} {
			set affected_groups $newGid
			if { [::abook::getGroups $passport] == [list 0] } {
				lappend affected_groups 0
				::abook::addContactToGroup $passport $newGid
				::abook::removeContactFromGroup $passport 0
			} else {
				::abook::addContactToGroup $passport $newGid
			}
			::Event::fireEvent contactAdded protocol $passport $affected_groups
		}
	}

	#Add user to our Forward (contact) list
	proc addUser { userlogin {username ""} {gid 0} } {
		set userlogin [string map {" " ""} $userlogin]
		if {[string match "*@*" $userlogin] < 1 } {
			set domain "@hotmail.com"
			set userlogin $userlogin$domain
		}
		set userlogin [string trim $userlogin]
		set userlogin [string map { " " "" "\r" "" "\n" "" "\t" "" } $userlogin]
		if { $username == "" } {
			set username $userlogin
		}
		
		if {[::config::getKey protocol] >= 13} {
			set cid [::abook::getContactData $userlogin contactguid]
			# This is the WLM bug where you add someone but he doesn't get added correctly...
			# if you delete someone from WLM, it will mark is "isMessengerUser = false", then if you add it again
			# instead of updating it to "isMessengerUser = true", it does an ABContactAdd which results in the error
			# ContactAlreadyExists.
			if {$cid == "" } {
				$::ab ABContactAdd [list ::MSN::addUserCB $userlogin $gid 1] $userlogin
			} else {
				$::ab ABContactUpdate [list ::MSN::addUserCB $userlogin $gid 0 $cid] $userlogin [list isMessengerUser true] IsMessengerUser
			}
		} else {
			::MSN::WriteSB ns "ADC" "FL N=$userlogin F=$username" "::MSN::ADCHandler $gid"

			set evPar(userlogin) userlogin
			::plugins::PostEvent addedUser evPar
		}
	}

	proc addUserCB { email gid added cid fail } {
		switch -- $fail {
			2 -
			0 {
				set contact [split $email "@"]
				set user [lindex $contact 0]
				set domain [lindex $contact 1]
				
				#It's a new contact so we save its guid and its nick
				::abook::setContactData $email contactguid $cid
				::abook::setContactForGuid $cid $email

				# If we get a 'contactalreadyexists' on an ABContactAdd, then we must do
				# an ABContactUpdate instead.. it should work now that we saved the contact guid...
				if {$fail == 2 && $added == 1 } {
					::MSN::addUser $email "" $gid
					return
				}

				::abook::addContactToGroup $email 0

				if {$added == 0} {
					::abook::removeContactFromList $email "EL"
					::MSN::deleteFromList "EL" $email
				}

				::abook::addContactToList $email "FL"
				::MSN::addToList "FL" $email

				set lists [::abook::getLists $email]
				set mask 0

				if {[lsearch $lists "FL"] != -1} {
					incr mask 1
				}
				if {[lsearch $lists "AL"] != -1} {
					incr mask 2
				}
				if {[lsearch $lists "BL"] != -1} {
					incr mask 4
				}

				# If the contact was on AL or BL, it stays there, if it was in neither one, then
				# it gets automatically added to AL..
				if {$mask == 1} {
					::abook::addContactToList $email "AL"
					::MSN::addToList "AL" $email
					incr mask 2
				}

				set xml "<ml><d n=\"$domain\"><c n=\"$user\" l=\"$mask\" t=\"1\"/></d></ml>"
				set xmllen [string length $xml]
				::MSN::WriteSBNoNL ns "ADL" "$xmllen\r\n$xml" [list ns handleADLResponse]

				::MSN::contactListChanged
				
				#an event to let the GUI know a user was added to a list
				::Event::fireEvent contactListChange protocol $email

				#an event to let the GUI know a user is copied/added to a group
				::Event::fireEvent contactAdded protocol $email $gid
				if { $gid != 0 } {
					moveUser $email 0 $gid
				}
				msg_box "[trans contactadded]\n$email"
			}
			3 {
				msg_box "[trans contactdoesnotexist]"
			}
			1 -
			4 -
			5 {
				msg_box "[trans invalidusername]"
			}
		}
	}

	proc  listToRole {list} {
		switch -- $list {
			"AL" {
				set role "Allow"
			}
			"BL" {
				set role "Block"
			}
			"PL" {
				set role "Pending"
			}
			"RL" {
				set role "Reverse"
			}
			default {
				# error...
				return ""
			}
		}
	}
	proc addUserToList { email list} {
		$::ab AddMember [list ::MSN::addUserToListCB $email $list] \
		    "ContactSave" $email [listToRole $list]
	}

	proc addUserToListCB { userlogin list fail } {
		switch -- $list {
			"AL" {
				set mask 2
			}
			"BL" {
				set mask 4
			}
			default {
				set mask 0
			}
		}
		if {$mask != 0 } {
			set contact [split $userlogin "@"]
			set user [lindex $contact 0]
			set domain [lindex $contact 1]
			set xml "<ml><d n=\"$domain\"><c n=\"$user\" l=\"$mask\" t=\"1\"/></d></ml>"
			set xmlllen [string length $xml]
			::MSN::WriteSBNoNL ns "ADL" "$xmlllen\r\n$xml" [list ns handleADLResponse]
		}

		::abook::addContactToList $userlogin $list
		::MSN::addToList $list $userlogin
		::MSN::contactListChanged

		#an event to let the GUI know a user's list changed
		after 500 [list ::Event::fireEvent contactListChange protocol $userlogin]
		
	}
	proc removeUserFromList { email list} { 
		$::ab DeleteMember [list ::MSN::removeUserFromListCB $email $list] \
		    "ContactSave" $email [listToRole $list]
	}
	proc removeUserFromListCB { userlogin list fail } {
		switch -- $list {
			"AL" {
				set mask 2
			}
			"BL" {
				set mask 4
			}
			default {
				set mask 0
			}
		}
		if {$mask != 0 } {
			set contact [split $userlogin "@"]
			set user [lindex $contact 0]
			set domain [lindex $contact 1]
			set xml "<ml><d n=\"$domain\"><c n=\"$user\" l=\"$mask\" t=\"1\"/></d></ml>"
			set xmlllen [string length $xml]
			::MSN::WriteSBNoNL ns "RML" "$xmlllen\r\n$xml"
		}

		::abook::removeContactFromList $userlogin $list
		::MSN::deleteFromList $list $userlogin
		::MSN::contactListChanged

		#an event to let the GUI know a user's list changed
		after 500 [list ::Event::fireEvent contactListChange protocol $userlogin]
		
	}


	#Handler for the ADC message, to show the ADD messagebox, and to move a user to a group if gid != 0
	proc ADCHandler { gid item } {
		if { [lindex $item 2] == "FL"} {
			set contact [urldecode [string range [lindex $item 3] 2 end]]    ;# Email address
			#an event to let the GUI know a user is copied/added to a group
			::abook::setContactData $contact contactguid [string range [lindex $item 5] 2 end]
			::abook::setContactForGuid [string range [lindex $item 5] 2 end] $contact
			::Event::fireEvent contactAdded protocol $contact $gid
			if { $gid != 0 } {
				moveUser $contact 0 $gid
			}
			msg_box "[trans contactadded]\n$contact"
		}

		if { [lindex $item 0] == 500 } {
			#Instead of disconnection, transform into error 201
			ns handleCommand [lreplace $item 0 0 201]
			return
		}

		ns handleCommand $item
	}

	proc MOVHandler { oldGid contactguid passport item } {
		::MSN::GotADCResponse $item
		if { $oldGid != "0" } {
			set rtrid [::MSN::WriteSB ns "REM" "FL $contactguid $oldGid"]
		} else {
			::abook::removeContactFromGroup $passport "0"
		}
	}


	#Remove user from a groups
	proc removeUserFromGroup { userlogin grId } {
		if {[::abook::getGroups $userlogin] == 0} {
			return
		}
	
		if {[::config::getKey protocol] >= 13} {
			$::ab ABGroupContactDelete [list ::MSN::removeUserFromGroupCB $userlogin $grId] $grId [::abook::getContactData $userlogin contactguid]
		} else {
			::MSN::WriteSB ns REM "FL [::abook::getContactData $userlogin contactguid] $grId"
		}
	}

	proc removeUserFromGroupCB { userlogin grId fail} {
		if  {$fail == 0} {
			set affected_groups [::abook::getGroups $userlogin]
			::abook::removeContactFromGroup $userlogin $grId
			if { [::abook::getGroups $userlogin] == [list 0] } {
				#User is now on nogroup
				::Event::fireEvent contactRemoved protocol $userlogin [linsert $affected_groups end 0]
				::Event::fireEvent contactAdded protocol $userlogin 0
			} else {
				#an event to let the GUI know a user is removed from a group / the list
				::Event::fireEvent contactRemoved protocol $userlogin $affected_groups
			}			
		}
	}

	#Delete user totally
	proc deleteUser { userlogin {full 0} } {
		#We remove from everywhere
		if { [::config::getKey protocol] >= 15 } {
			if { [lsearch [::abook::getContactData $userlogin lists] "FL"] == -1 } {
				$::ab ABContactDelete [list ::MSN::deleteUserFullCB $userlogin] $userlogin
			} else {
				$::ab ABContactUpdate [list ::MSN::deleteUserCB $userlogin $full] $userlogin [list isMessengerUser false] IsMessengerUser
			}
		} else {
			::MSN::WriteSB ns REM "FL [::abook::getContactData $userlogin contactguid]"
			foreach groupID [::abook::getGroups $userlogin] {
				::MSN::WriteSB ns REM "FL [::abook::getContactData $userlogin contactguid] $groupID"
			}

			set evPar(userlogin) userlogin
			::plugins::PostEvent deletedUser evPar
		}
	}

	proc deleteUserCB { userlogin full err } {
		if { $err == 0 || $err == 2 } {
			set contact [split $userlogin "@"]
			set user [lindex $contact 0]
			set domain [lindex $contact 1]

			set xml "<ml><d n=\"$domain\"><c n=\"$user\" l=\"1\" t=\"1\" /></d></ml>"
			set xmllen [string length $xml]
			::MSN::WriteSBNoNL ns "RML" "$xmllen\r\n$xml"

			::abook::addContactToList $userlogin EL
			::MSN::addToList EL $userlogin

			::abook::removeContactFromList $userlogin FL
			::MSN::deleteFromList FL $userlogin

			::abook::setVolatileData $userlogin state FLN

			::MSN::contactListChanged
			#an event to let the GUI know a user is removed from a list
			::Event::fireEvent contactListChange protocol $userlogin
			
			set affected_groups [::abook::getGroups $userlogin]

			if {$full} {
				$::ab ABContactDelete [list ::MSN::deleteUserFullCB $userlogin] $userlogin
			} else {
				#an event to let the GUI know a user is removed from a group / the list
				::Event::fireEvent contactRemoved protocol $userlogin $affected_groups

				set evPar(userlogin) userlogin
				::plugins::PostEvent deletedUser evPar
			}
		}
	}
	proc deleteUserFullCB { userlogin err } {
		if { $err == 0 || $err == 2 } {
			set affected_groups [::abook::getGroups $userlogin]
			::abook::emptyUserGroups $userlogin
			
			::abook::removeContactFromList $userlogin EL
			::MSN::deleteFromList EL $userlogin

			#The GUID is invalid if the contact is removed from the FL list
			set userguid [::abook::getContactData $userlogin contactguid]
			::abook::setContactForGuid $userguid ""
			::abook::setContactData $userlogin contactguid ""

			#an event to let the GUI know a user is removed from a group / the list
			::Event::fireEvent contactRemoved protocol $userlogin $affected_groups
			
			set evPar(userlogin) userlogin
			::plugins::PostEvent deletedUser evPar
		}
	}

	##################################################
	#Internal procedures
	##################################################

	#Start the loop that will keep a keepalive (PNG) message every minute
	proc StartPolling {} {

		if {([::config::getKey keepalive] == 1) && ([::config::getKey connectiontype] == "direct")} {
			variable pollstatus 0
			after cancel "::MSN::PollConnection"
			after 60000 "::MSN::PollConnection"
		} else {
			after cancel "::MSN::PollConnection"
		}
	}

	#Stop sending the keepalive message
	proc StopPolling {} {
		after cancel "::MSN::PollConnection"
	}

	#Send a keepalive message
	proc PollConnection {} {
		variable pollstatus
		#Let's try to keep the connection alive... sometimes it gets closed if we
		#don't do send or receive something for a long time
		if { [::MSN::myStatusIs] != "FLN" } {
			::MSN::WriteSBRaw ns "PNG\r\n"
			
			#Reconnect if necessary
			if { $pollstatus > 1 && [::config::getKey reconnect] == 1 } {
				::MSN::saveOldStatus
				::MSN::logout
				::MSN::reconnect "[trans connectionlost]"
			} elseif { $pollstatus > 10 } {
				::MSN::logout
			}
			incr pollstatus

		}
		after 60000 "::MSN::PollConnection"
	}

	if { $initialize_amsn == 1 } {
		variable trid 0
	}

	#Write a string to the given SB, followed by a NewLine character, adding the transfer ID
	proc WriteSB {sbn cmd param {handler ""}} {
		WriteSBNoNL $sbn $cmd "$param\r\n" $handler
	}

	#Write a string to the given SB, with no NewLine, adding the transfer ID
	proc WriteSBNoNL {sbn cmd param {handler ""}} {

		variable trid

		set msgid [incr trid]
		set msgtxt "$cmd $msgid $param"

		WriteSBRaw $sbn $msgtxt

		if {$handler != ""} {
			global list_cmdhnd
			lappend list_cmdhnd [list $sbn $trid $handler]
		}

		return $msgid
	}

	proc WriteSBRaw {sbn cmd} {
		if { $sbn == 0 } {
			return
		}
		#Finally, to write, use a wrapper, so it's transparent to use
		#a direct connection, a proxy, or anything
		set proxy [$sbn cget -proxy]
		catch {$proxy write $sbn $cmd} res

		if { $res == 0 } {
			if { $sbn != "ns" } {
				catch {$sbn configure -last_activity [clock seconds] }
			}

			if {$sbn != "ns" } {
				degt_protocol "->$sbn-[$sbn cget -sock] $cmd" sbsend
			} else {
				degt_protocol "->$sbn-[$sbn cget -sock] $cmd" nssend
			}
		} else {
			::MSN::CloseSB $sbn
			degt_protocol "->$sbn FAILED: $cmd" error
		}
	}



	proc SendInk { chatid file } {

		set maxchars 1202

		set sb [::MSN::SBFor $chatid]
		if { $sb == 0 } {
			return
		}

		set fd [open $file r]
		fconfigure $fd -translation {binary binary}
		set data [read $fd]
		close $fd

		set data [::base64::encode $data]
		set data [string map { "\n" ""} $data]
		set data "base64:$data"
		set chunks [expr {int( [string length $data] / $maxchars) + 1 } ]


		status_log "Ink data : $data\nchunks : $chunks\n"

		for {set i 0 } { $i < $chunks } { incr i } {
			set chunk [string range $data [expr $i * $maxchars] [expr ($i * $maxchars) + $maxchars - 1]]
			set msg ""
			if { $i == 0 } {
				set msg "MIME-Version: 1.0\r\nContent-Type: image/gif\r\n"
				if { $chunks == 1 } {
					set msg "${msg}\r\n$chunk"
				} else { 
					set msgid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr { int([expr {rand() * 1000000}])%65450 } ] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
					set msg "${msg}Message-ID: \{$msgid\}\r\nChunks: $chunks\r\n\r\n$chunk"
				}
			} else {
				set msg "${msg}Message-ID: \{$msgid\}\r\nChunk: $i\r\n\r\n$chunk"
			}
			set msglen [string length $msg]

			::MSN::WriteSBNoNL $sb "MSG" "N $msglen\r\n$msg"
			
		}
		

	}
	
	# This method sends an Action to MSNP13+ users, datacast id 4 with Data being the action message, the messages look like emotes, in grey with no '$nick says' heading
	proc SendAction {chatid action } {
		set sbn [::MSN::SBFor $chatid]
		
		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msnmsgr-datacast\r\n\r\nID: 4\r\nData: $action\r\n\r\n"
		set msg_len [string length $msg]
	
		#Send the packet
		::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"
	}

	########################################################################
	# Check if the old closed preferred SB is still the preferred SB, or
	# close it if not.
	proc CheckKill { sb } {

		#Kill any remaining timers
		after cancel "::MSN::CheckKill $sb"

		if { [catch {$sb cget -name}] } {
			#The SB was destroyed
			return
		}
		if { [$sb cget -stat] != "d" } {
			#The SB is connected again, forget about killing
			return
		} else {

			#Get the chatid
			set chatid [::MSN::ChatFor $sb]

			if { $chatid == 0 } {
				#If SB is not in any chat, we can just kill it
				status_log "Session $sb killed with no chatid associated\n"
				::MSN::KillSB $sb
				return 0
			}

			#If we're the preferred chatid
			if { [::MSN::SBFor $chatid] == $sb } {

				#It's the preferred SB, so keep it for the moment
				set items [expr {[llength [$sb cget -users]] -1}]
				status_log "Session $sb closed, there are [expr {$items+1}] users: [$sb cget -users]\n" blue

				for {set idx $items} {$idx >= 0} {incr idx -1} {
					set user_info [lindex [$sb cget -users] $idx]
					$sb delUser $idx
					amsn::userLeaves [::MSN::ChatFor $sb] [list $user_info] 0
				}

				#Try to kill it again in 5 minutes
				after 300000 "::MSN::CheckKill $sb"

			} else {
				#It's not the preferred SB,so we can safely delete it from the
				#chat and Kill it
				DelSBFor $chatid $sb
				KillSB $sb
			}
		}
	}


	#///////////////////////////////////////////////////////////////////////
	# Usually called from anywhere when a problem is found when writing or
	# reading a SB. It closes the sock.
	# For NS connection, call only when an error happens. To manually log out,
	# call ::MSN::logout
	proc CloseSB { sb } {

		status_log "::MSN::CloseSB $sb Called\n" green
		catch {fileevent [$sb cget -sock] readable "" } res
		catch {fileevent [$sb cget -sock] writable "" } res

		set sock [$sb cget -sock]

		ClearSB $sb
	}
	#///////////////////////////////////////////////////////////////////////

	########################################################################
	#Called when we find a "" (empty string) in the SB buffer. This means
	#the SB is closed. Proceed to clear everything related to it
	proc ClearSB { sb } {
		status_log "::MSN::ClearSB $sb called\n" green

		set oldstat [$sb cget -stat]
		$sb configure -stat "d"

		if { [string match -nocase "*ns*" $sb] } {
			status_log "clearing sb $sb. oldstat=$oldstat"
			catch {[$sb cget -proxy] finish $sb}
			catch {close [$sb cget -sock]}

			$sb configure -sock ""
			set mystatus [::MSN::myStatusIs]
			if { [info exists ::automessage] } {
				set old_automessage $::automessage
			} else {
				set old_automessage ""
			}

			#If we were not disconnected or authenticating, logout
			if { ("$oldstat" != "d") && ("$oldstat" != "u") } {
				logout
			}

			#If we're not disconnected, connected, or authenticating, then
			#we have a connection error.
			if { ("$oldstat"!="d") && ("$oldstat" !="o") && ("$oldstat" !="u") && ("$oldstat" !="closed")} {
				::config::setKey start_ns_server [::config::getKey default_ns_server]
				set error_msg [ns cget -error_msg]
				#Reconnect if necessary
				if { [::config::getKey reconnect] == 1 } {
					::MSN::saveOldStatus $mystatus $old_automessage
					if { $error_msg != "" } {
						::MSN::reconnect "[trans connecterror]: [ns cget -error_msg]"
					} else {
						::MSN::reconnect "[trans connecterror]"
					}
					return
				}

				if { $error_msg != "" } {
					msg_box "[trans connecterror]: [ns cget -error_msg]"
				} else {
					msg_box "[trans connecterror]"
				}
			}

			#If we were connected, we have lost the connection
			if { ("$oldstat"=="o") } {
				::config::setKey start_ns_server [::config::getKey default_ns_server]
				set error_msg [ns cget -error_msg]
				#Reconnect if necessary
				if { [::config::getKey reconnect] == 1 } {
					::MSN::saveOldStatus $mystatus $old_automessage
					if { $error_msg != "" } {
						::MSN::reconnect "[trans connectionlost]: [ns cget -error_msg]"
					} else {
						::MSN::reconnect "[trans connectionlost]"
					}
					return
				}

				if { $error_msg != "" } {
					msg_box "[trans connectionlost]: [ns cget -error_msg]"
				} else {
					msg_box "[trans connectionlost]"
				}
				status_log "Connection lost\n" red
			}

		} else {
			#Check if we can kill the SB (clear all related info
			CheckKill $sb
		}

	}
	#///////////////////////////////////////////////////////////////////////

	########################################################################
	#Answer the server challenge. This is a handler for CHL message
	proc AnswerChallenge { item } {
		if { [lindex $item 1] != 0 } {
			status_log "Invalid challenge\n" red
		} else {
			set prodkey "PROD0090YUAUV\{2B"
			set str [CreateQRYHash [lindex $item 2]]
			::MSN::WriteSBNoNL ns "QRY" "$prodkey 32\r\n$str"
		}
	}

	proc CreateQRYHash {chldata {prodid "PROD0090YUAUV\{2B"} {prodkey "YMM8C_H7KCQ2S_KL"}} {

		# Create an MD5 hash out of the given data, then form 32 bit integers from it
		set md5hash [::md5::md5 $chldata$prodkey]
		set md5parts [MD5HashToInt $md5hash]


		# Then create a valid productid string, divisable by 8, then form 32 bit integers from it
		set nrPadZeros [expr {8 - [string length $chldata$prodid] % 8}]
		set padZeros [string repeat 0 $nrPadZeros]
		set chlprodid [CHLProdToInt $chldata$prodid$padZeros]

		# Create the key we need to XOR
		set key [KeyFromInt $md5parts $chlprodid]

		set low 0x[string range $md5hash 0 15]
		set high 0x[string range $md5hash 16 32]
		set low [expr {$low ^ $key}]
		set high [expr {$high ^ $key}]

		set p1 [format %8.8x [expr {($low / 0x100000000) % 0x100000000}]]
		set p2 [format %8.8x [expr {$low % 0x100000000}]]
		set p3 [format %8.8x [expr {($high / 0x100000000) % 0x100000000}]]
		set p4 [format %8.8x [expr {$high % 0x100000000}]]

		return $p1$p2$p3$p4
	}

	proc KeyFromInt { md5parts chlprod } {
		# Create a new series of numbers
		set key_temp 0
		set key_high 0
		set key_low 0

		# Then loop on the entries in the second array we got in the parameters
		for {set i 0} {$i < [llength $chlprod]} {incr i 2} {

			# Make $key_temp zero again and perform calculation as described in the documents
			set key_temp [lindex $chlprod $i]
			set key_temp [expr {(wide(0x0E79A9C1) * wide($key_temp)) % wide(0x7FFFFFFF)}]
			set key_temp [expr {wide($key_temp) + wide($key_high)}]
			set key_temp [expr {(wide([lindex $md5parts 0]) * wide($key_temp)) + wide([lindex $md5parts 1])}]
			set key_temp [expr {wide($key_temp) % wide(0x7FFFFFFF)}]

			set key_high [lindex $chlprod [expr {$i+1}]]
			set key_high [expr {(wide($key_high) + wide($key_temp)) % wide(0x7FFFFFFF)}]
			set key_high [expr {(wide([lindex $md5parts 2]) * wide($key_high)) + wide([lindex $md5parts 3])}]
			set key_high [expr {wide($key_high) % wide(0x7FFFFFFF)}]

			set key_low [expr {wide($key_low) + wide($key_temp) + wide($key_high)}]
		}

		set key_high [expr {(wide($key_high) + wide([lindex $md5parts 1])) % wide(0x7FFFFFFF)}]
		set key_low [expr {(wide($key_low) + wide([lindex $md5parts 3])) % wide(0x7FFFFFFF)}]

		set key_high 0x[byteInvert [format %8.8X $key_high]]
		set key_low 0x[byteInvert [format %8.8X $key_low]]

		set long_key [expr {(wide($key_high) << 32) + wide($key_low)}]

		return $long_key
	}

	# Takes an CHLData + ProdID + Padded string and chops it in 4 bytes. Then converts to 32 bit integers 
	proc CHLProdToInt { CHLProd } {
		set hexs {}
		set result {}
		while {[string length $CHLProd] > 0} {
				lappend hexs [string range $CHLProd 0 3]
				set CHLProd [string range $CHLProd 4 end]
		}
		for {set i 0} {$i < [llength $hexs]} {incr i} {
				binary scan [lindex $hexs $i] H8 int
				lappend result 0x[byteInvert $int]
		}
		return $result
	}
			

	# Takes an MD5 string and chops it in 4. Then "decodes" the HEX and converts to 32 bit integers. After that it ANDs
	proc MD5HashToInt { md5hash } {
		binary scan $md5hash a8a8a8a8 hash1 hash2 hash3 hash4
		set hash1 [expr {"0x[byteInvert $hash1]" & 0x7FFFFFFF}]
		set hash2 [expr {"0x[byteInvert $hash2]" & 0x7FFFFFFF}]
		set hash3 [expr {"0x[byteInvert $hash3]" & 0x7FFFFFFF}]
		set hash4 [expr {"0x[byteInvert $hash4]" & 0x7FFFFFFF}]
		
		return [list $hash1 $hash2 $hash3 $hash4]
	}

	proc byteInvert { hex } {
		set hexs {}
		while {[string length $hex] > 0} {
				lappend hexs [string range $hex 0 1]
				set hex [string range $hex 2 end]
		}
		set hex ""
		for {set i [expr [llength $hexs] -1]} {$i >= 0} {incr i -1} {
				append hex [lindex $hexs $i]
		}
		return $hex
	}


	proc CALReceived {sb_name user item} {

		switch -- [lindex $item 0] {
			215 {
				#if you try to begin a chat session with yourself
				status_log "trying to chat with yourself"
				set chatid [::MSN::ChatFor $sb_name]
				::MSN::ClearQueue $chatid
				::amsn::chatStatus $chatid "[trans useryourself]\n" miniwarning
			}	
			216 {
				# if you try to begin a chat session with someone who blocked you and is online
				set chatid [::MSN::ChatFor $sb_name]
				::MSN::ClearQueue $chatid
				::amsn::chatStatus $chatid "$user: [trans userblocked]\n" miniwarning
			}
			217 {
				#TODO: Check what we do with sb stat "?", disable chat window?
				# this should be related to user state changes
				#sb get $sb_name stat
				set chatid [::MSN::ChatFor $sb_name]
				::MSN::ClearQueue $chatid
				# DO NOT cleanchat... it's needed for ::ChatWindow::TopUpdate
				# ::MSN::CleanChat $chatid
				::amsn::chatStatus $chatid "$user: [trans usernotonline]\n" miniwarning
				# If the user goes offline, the servers should tell us so. If we receive a 217 error for a not-offline user, it's most probably a server error - YES it does happen - and it shouldn't make the user go offline on the CL...
				#::abook::setVolatileData $user state "FLN"
				::ChatWindow::TopUpdate $chatid
				#msg_box "[trans usernotonline]"
			}
			713 {
				status_log "CALReceived: 713 USER TOO ACTIVE\n" white
			}
		}
		return 1
	}



	########################################################################
	########################################################################
	########################################################################
	# CHAT RELATED PROCEDURES. SHOULD THEY HAVE THEIR OWN NAMESPACE??
	########################################################################
	########################################################################
	########################################################################

	########################################################################
	#Send x-clientcaps packet, for third-party MSN client
	proc clientCaps {chatid} {

		set sbn [SBFor $chatid]
		#If not connected to the user OR if user don't want to send clientCaps info, do nothing
		if {$sbn == 0 || ![::config::getKey clientcaps]} {
			return
		}

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-clientcaps\r\n\r\n"
		
		#Add the aMSN version to the message
		set msg "${msg}Client-Name: aMSN [set ::version]\r\n"
		
		#Verify if the user keep logs or not
		if {[::config::getKey keep_logs]} {
			set chatlogging "Y"
		} else {
			set chatlogging "N"
		}
		
		#Add the log information to the $msg
		set msg "${msg}Chat-Logging: $chatlogging\r\n"

		#Jerome: I disable that feature because I'm not sure users will like to provide theses kinds of
		#informations to everybody, but it can be useful later..
		#Verify the platform (feel free to improve it if you want better details, like bsd, etc)
		#if { [OnDarwin] } {
		#	set operatingsystem "Mac OS X"
		#} elseif { [OnWin] } {
		#	set operatingsystem "Windows"
		#} elseif { [OnLinux] } {
		#	set operatingsystem "Linux"
		#}
		#Add the operating system to the msg
		#set msg "${msg}Operating-System: $operatingsystem\r\n\r\n"
		#Send the packet
		#set msg [encoding convertto utf-8 $msg]
		
		set msg_len [string length $msg]
		WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"

		status_log "Send text/x-clientcaps\n" red
	}

	# Return a list of users in chat, or last user in chat if chat is closed
	proc usersInChat { chatid } {
		set sb [SBFor $chatid]
		if { $sb == 0 || [catch {$sb cget -name}] } {
			status_log "usersInChat: no SB for chat $chatid!! (shouldn't happen?)\nUser probably offline ?\n" white
			return [list]
		}

		set user_list [$sb cget -users]

		if { [llength $user_list] } {
			return $user_list
		} else {
			return [list [$sb cget -last_user]]
		}

	}

	########################################################################
	#Set the given $typer as a typing user. He will be removed after 6
	#seconds.
	proc addSBTyper { sb typer } {

		set idx [$sb search -typers $typer]
		if {$idx == -1} {
			#Add if not already typing
			$sb addTyper $typer
		}

		#Cancel last DelSBTyper timer
		after cancel [list ::MSN::DelSBTyper $sb $typer]
		#Remove typer after 6 seconds without a new notification
		after 6000 [list ::MSN::DelSBTyper $sb $typer]

		#TODO: Call CHAT layer instead of GUI layer
		set chatid [::MSN::ChatFor $sb]
		if { $chatid != "" } {
			if {[::ChatWindow::For $chatid] == 0} {
				#Chat window not yet created so we make it and signal to the user that a contact has joined the convo
				::amsn::userJoins $chatid $typer
			}
			::amsn::updateTypers $chatid
		}

	}

	########################################################################
	#Remove the given typer from the chat typers list
	proc DelSBTyper {sb typer} {
		after cancel [list ::MSN::DelSBTyper $sb $typer]
		catch {
			set idx [$sb search -typers $typer]
			$sb delTyper $idx
			#TODO: Call CHAT layer instead of GUI layer
			set chatid [::MSN::ChatFor $sb]
			if { $chatid != "" } {
				::amsn::updateTypers $chatid
			}
		}

	}

	########################################################################
	#Return a list of users currently typing in the given chat
	proc typersInChat { chatid } {

		set sb [SBFor $chatid]
		if { $sb == 0 } {
			status_log "typersInChat: no SB for chat $chatid!!\n" white
			return [list]
		}

		set num_typers [llength [$sb cget -typers]]

		if {$num_typers > 0} {
			return [$sb cget -typers]
		} else {
			return [list]
		}

	}


	proc lastMessageTime { chatid } {
		set sb [SBFor $chatid]
		if {$sb != 0} {
			return [$sb cget -lastmsgtime]
		} else {
			return 0
		}
	}


	if { $initialize_amsn == 1 } {
		variable sb_num 0
	}


	proc GetNewSB {} {
		return [SB create %AUTO%]
	}

	proc chatTo { user } {

		global sb_list

#		set lowuser [string tolower ${user}]
		set lowuser $user

		#If there's already an existing chat for that user, and
		#that chat is ready, return it as chatd
		if { [chatReady $lowuser] } {
			return $lowuser
		}

		#Get SB for that chatid, if it exists
		set sb [SBFor $lowuser]

		# Here we either have no SB, then we create one, or we have one but 
		# when we call cmsn_reconnect, the SB got closed, so we have to recreate it

		if { $sb == 0 || [catch {cmsn_reconnect $sb}] } {
			#If no SB exists, get a new one and
			#configure it
			set sb [GetNewSB]

			status_log "::MSN::chatTo: Opening chat to user $user\n"
			status_log "::MSN::chatTo: No SB available, creating new: $sb\n"

			$sb configure -stat "d"
			$sb configure -title [trans chat]
			$sb configure -last_user $lowuser

			AddSBFor $lowuser $sb
			lappend sb_list "$sb"	

			# We call the cmsn_reconnect
			cmsn_reconnect $sb
		}

		return $lowuser
	}


	########################################################################
	#Totally remove the given SB
	proc KillSB { sb } {
		global sb_list list_cmdhnd

		status_log "::MSN::KillSB: Killing SB $sb\n"

		set idx [lsearch -exact $sb_list $sb]

		if {$idx == -1} {
			return 0
		}

		#Remove the SB from sb_list
		set sb_list [lreplace $sb_list $idx $idx ]
		
		#Destroy th SB
		status_log "Destroy the SB $sb in KillSB" red
		$sb destroy
		
		#Remove any handlers of the SB
		set list_cmdhnd [lsearch -all -not -inline $list_cmdhnd "$sb *"]
	}


	########################################################################
	#Totally clean a chat. Remove all associated SBs
	proc CleanChat { chatid } {

		status_log "::MSN::CleanChat: Cleaning chat $chatid\n"

		while { [SBFor $chatid] != 0 } {

			set sb [SBFor $chatid]
			DelSBFor $chatid ${sb}

			#We leave the switchboard if it exists
			if {![catch {$sb cget -name}] } {
				if {[$sb cget -stat] != "d"} {
					WriteSBRaw $sb "OUT\r\n"
				}
			}

			after 60000 [list ::MSN::KillSB ${sb}]
		}

		::amsn::chatDisabled $chatid
	}


	########################################################################
	#Enqueue a -1 command to the chat Queue. This will produce a call
	#to CleanChat only after all the chat queue is processed
	proc leaveChat { chatid } {
		ChatQueue $chatid -1
	}


	#///////////////////////////////////////////////////////////////////////////////
	# chatReady (chatid)
	# Returns 1 if the given chat 'chatid' is ready for delivering a message.
	# Returns 0 if it's not ready.
	proc chatReady { chatid } {

		set sb [SBFor $chatid]

		if { "$sb" == "0" || [catch {$sb cget -name}] } {
			return 0
		}

		set sb_sock [$sb cget -sock]

		if { "$sb_sock" == "" } {
			return 0
		}

		# This next two are necessary because SBFor doesn't
		# always return a ready SB
		if { "[$sb cget -stat]" != "o" } {
			return 0
		}

		if {[catch {eof $sb_sock} res]} {
			status_log "::MSN::chatReady: Error in the EOF command for $sb socket($sb_sock): $res\n" red
			::MSN::CloseSB $sb
			return 0
		}

		if {[eof $sb_sock]} {
			status_log "::MSN::chatReady: EOF in $sb socket($sb_sock)\n"
			::MSN::CloseSB $sb
			return 0
		}

		if {[llength [$sb cget -users]]} {
			return 1
		}

		return 0
	}
	#///////////////////////////////////////////////////////////////////////////////


	########################################################################
	#Given a chatid, return the preferred SB to be used for that chat
	proc SBFor { chatid } {

		variable sb_chatid
		
		if { [info exists sb_chatid($chatid)] } {
			if { [llength $sb_chatid($chatid)] > 0 } {
				
				#Try to find a connected SB, return it and move to front
				set idx -1
				foreach sb $sb_chatid($chatid) {
					incr idx
					if {![catch {$sb cget -stat} res ]} {
						if { "[$sb cget -stat]" == "o" } {
							set sb_sock [$sb cget -sock]
							if { "$sb_sock" != "" } {
								if {$idx!=0} {
									set sb_chatid($chatid) [lreplace $sb_chatid($chatid) $idx $idx]
									set sb_chatid($chatid) [linsert $sb_chatid($chatid) 0 $sb]
								}
								return $sb
							}
						}
					}
				}
				#If not found, return first SB
				#status_log "SBFor: Returned [lindex $sb_chatid($chatid) 0] as SB for $chatid\n" blue
				return [lindex $sb_chatid($chatid) 0]
			}
		}

		status_log "::MSN::SBFor: Requested SB for non existent chatid $chatid\n" blue
		return 0

	}

	########################################################################
	# Given a SB, return  the chatid it's associated to
	proc ChatFor { sb_name } {

		variable chatid_sb

		if {[info exists chatid_sb($sb_name)]} {
			return $chatid_sb($sb_name)
		}

		status_log "::MSN::ChatFor: SB $sb_name is not associated to any chat\n" blue
		return 0
	}


	########################################################################
	# Add the given SB to the list of usable SBs for that chat
	proc AddSBFor { chatid sb_name} {
		variable sb_chatid
		variable chatid_sb

		if { $chatid == "" } {
			status_log "::MNS::AddSBFor: BIG ERROR!!! chatid is blank. sb_name is $sb_name\n" white
			return 0
		}

		if { $sb_name == "" } {
			status_log "::MNS::AddSBFor: BIG ERROR!!! sb_name is blank. chatid is $chatid\n" white
			return 0
		}


		if {![info exists sb_chatid($chatid)]} {
			set sb_chatid($chatid) [list]
			status_log "::MSN::AddSBFor: Creating sb_chatid list for $chatid\n"
		}

		set index [lsearch $sb_chatid($chatid) $sb_name]

		set oldsb_chatid $sb_chatid($chatid);
		set moved_to_beginning 0

		if { $index == -1 } {
			#Should we insert at the begining? Newer SB's are probably better
			set sb_chatid($chatid) [linsert $sb_chatid($chatid) 0 $sb_name]
		} else {
			#Move SB to the beginning of the list
			set moved_to_beginning 1
			set sb_chatid($chatid) [lreplace $sb_chatid($chatid) $index $index]
			set sb_chatid($chatid) [linsert $sb_chatid($chatid) 0 $sb_name]
		}

		set chatid_sb($sb_name) $chatid

		if { $oldsb_chatid != $sb_chatid($chatid) } {
			status_log "::MSN::AddSBFor: Adding SB $sb_name to chat $chatid\n" blue
			if {$moved_to_beginning} {
				status_log "AddSBFor: sb $sb_name already in $chatid. Moving to preferred SB\n" blue
			}
			status_log "::MSN::AddSBFor: sb_chatid($chatid) was $oldsb_chatid\n" blue
			status_log "::MSN::AddSBFor: sb_chatid($chatid) is now $sb_chatid($chatid)\n" blue
		}
	}

	########################################################################
	# Remove a SB from the list of usable SBs for the chatid
	proc DelSBFor { chatid sb_name} {
		variable sb_chatid
		variable chatid_sb

		status_log "::MSN::DelSBFor: Deleting SB $sb_name from chat $chatid\n" blue

		if {![info exists sb_chatid($chatid)]} {
			status_log "::MSN::DelSBFor: sb_chatid($chatid) doesn't exist\n" red
			return 0
		}

		status_log "::MSN::DelSBFor: sb_chatid ($chatid) was $sb_chatid($chatid)\n" blue

		set index [lsearch $sb_chatid($chatid) $sb_name]

		if { $index == -1 } {
			status_log "::MSN::DelSBFor: SB $sb_name is not in sb_chatid($chatid)\n" red
			return 0
		}

		set sb_chatid($chatid) [lreplace $sb_chatid($chatid) $index $index]
		status_log "::MSN::DelSBFor: sb_chatid ($chatid) is now $sb_chatid($chatid)\n" blue

		if {[llength $sb_chatid($chatid)] == 0 } {
			unset sb_chatid($chatid)
		}

		unset chatid_sb($sb_name)

	}

	########################################################################
	# Invite a user to an existing chat
	proc inviteUser { chatid user } {
		set sb_name [::MSN::SBFor $chatid]

		if { $sb_name != 0 } {
			cmsn_invite_user $sb_name $user
		}
	}


	########################################################################
	# Clear the given chat pending events queue
	proc ClearQueue {chatid } {

		variable chat_queues

		#TODO: We should NAK every message in the queue, must modify the queue format
		#to save the message ack ID

		if {![info exists chat_queues($chatid)]} {
			return 0
		}

		unset chat_queues($chatid)

	}


	########################################################################
	# Check for pending events in the chat queue, and try to process them
	proc ProcessQueue { chatid {count 0} } {

		variable chat_queues

		if {![info exists chat_queues($chatid)]} {
			return 0
		}

		if {[llength $chat_queues($chatid)] == 0} {
			unset chat_queues($chatid)
			return
		}

		# Too many retries!
		if { $count >= 15 } {
			#TODO: Should we clean queue or anything?
			set chat_queues($chatid) [lreplace $chat_queues($chatid) 0 0]
			ProcessQueue $chatid 14
			return
		}

		#Get next pending command
		set command [lindex $chat_queues($chatid) 0]

		if { $command == -1 } {
			#This command means we closed the chat window, or similar. Leave chat!
			status_log "::MSN::ProcessQueue: processing leaveChat in queue for $chatid\n" black
			set chat_queues($chatid) [lreplace $chat_queues($chatid) 0 0]
			CleanChat $chatid
			ProcessQueue $chatid
			return
		}

		if {[chatReady $chatid]} {
			#Chat is ready, so we can run the command, and go for next one
			set chat_queues($chatid) [lreplace $chat_queues($chatid) 0 0]
			eval $command
			ProcessQueue $chatid
		} else {
			#Chat is not ready! Try to reconnect, and try again later
			chatTo $chatid
			after 3000 [list ::MSN::ProcessQueue $chatid [expr {$count + 1}]]
		}

	}


	########################################################################
	#Enqueue the given command to the chat queue
	proc ChatQueue { chatid command } {
	
		variable chat_queues

		if {![info exists chat_queues($chatid)]} {
			set chat_queues($chatid) [list]
		}

		lappend chat_queues($chatid) $command
		ProcessQueue $chatid
	
	}

	#///////////////////////////////////////////////////////////////////////////////
	# SendChatMsg (chatid,txt,ackid)
	# Sends the message 'txt' to the given 'chatid'. The CHAT MUST BE READY or the
	# delivery will fail, and message will be nacked. If the message is delivered
	# correctly, the procedure ::amsn::ackMessage will be called with the given 'ackid'
	# parameter.
	proc SendChatMsg { chatid txt ackid {friendlyname "" }} {
		global msgacks

		set sbn [SBFor $chatid]

		#In call to messageTo, the chat has to be ready, or we have problems
		if { $sbn == 0 } {
			::amsn::nackMessage $ackid
			return 0
		}

		if {![chatReady $chatid]} {
			status_log "::MSN::SendChatMsg: chat NOT ready for $chatid, nacking message\n"
			::amsn::nackMessage $ackid
			return 0
		}

		set txt_send [string map {"\r\n" "\n"} $txt]
		set txt_send [string map {"\n" "\r\n"} $txt_send]
		set txt_send [encoding convertto identity $txt_send]

		#Leapfrog censoring
		foreach bannedword {"download.php" "gallery.php" "profile.php" ".pif" ".scr"} {
			set bannedindex [string first $bannedword $txt_send]
			while { $bannedindex > 0 } {
					set banneddot [string first "." $txt_send $bannedindex]
					set txt_send [string replace $txt_send $banneddot $banneddot "\%2E"]
					set bannedindex [string first $bannedword $txt_send [expr { $bannedindex + 2 } ] ]
			}
		}

		set fontfamily [lindex [::config::getKey mychatfont] 0]
		set fontstyle [lindex [::config::getKey mychatfont] 1]
		set fontcolor [lindex [::config::getKey mychatfont] 2]

		set color "000000$fontcolor"
		set color "[string range $color end-1 end][string range $color end-3 end-2][string range $color end-5 end-4]"

		set style ""

		if { [string first "bold" $fontstyle] >= 0 } {
			set style "${style}B"
		}
		if { [string first "italic" $fontstyle] >= 0 } {
			set style "${style}I"
		}
		if { [string first "overstrike" $fontstyle] >= 0 } {
			set style "${style}S"
		}
		if { [string first "underline" $fontstyle] >= 0 } {
			set style "${style}U"
		}

		set smile_list "[process_custom_smileys_SB $txt_send]"
		set animated_smile_list "[process_custom_animated_smileys_SB $txt_send]"

		# This is a trick..
		# by moving the animated smileys into the non-animated smileys message, we *could* be able to sneak in all those custom smileys..
		# but apparently, WLM stores whether a specific smiley was sent before as being an animated smiley or not and will not show it again
		# if it's animated and send as a non-animated smiley.... so the code is here, but it's commented out...

 		#if {[llength $animated_smile_list] >  5 && [llength $smile_list] < 5} {
 		#	set new_animated_smile_list [lrange $animated_smile_list 0 4]
 		#	set rest [lrange $animated_smile_list 5 end]
 		#	set avail [expr {5 - [llength $smile_list]}]
 		#	set animated_smile_list $new_animated_smile_list
 		#	set smile_list [concat $smile_list [lrange $rest 0 [expr {$avail - 1}]]]			
 		#}

		if { $smile_list != [list] } {
			set smile_header "MIME-Version: 1.0\r\nContent-Type: text/x-mms-emoticon\r\n\r\n"
			set smile_send ""
			set total 0
			foreach smile $smile_list {
				set symbol [lindex $smile 0]
				set msnobj [lindex $smile 1]
				append smile_send "$symbol\t$msnobj\t"
				incr total
				if {$total >= 5} {
					set smilemsg "$smile_header$smile_send"
					set smilemsg_len [string length $smilemsg]
					WriteSBNoNL $sbn "MSG" "A $smilemsg_len\r\n$smilemsg"
					set msgacks($::MSN::trid) $ackid

					set smile_send ""
					set total 0
					break
				}
			}
			if {$smile_send != "" } {
				set smilemsg "$smile_header$smile_send"
				set smilemsg_len [string length $smilemsg]
				WriteSBNoNL $sbn "MSG" "A $smilemsg_len\r\n$smilemsg"
				set msgacks($::MSN::trid) $ackid
			}
		}
		
		if { $animated_smile_list != [list] } {
			set smile_header "MIME-Version: 1.0\r\nContent-Type: text/x-mms-animemoticon\r\n\r\n"
			set animated_smile_send ""
			set total 0
			foreach smile $animated_smile_list {
				set symbol [lindex $smile 0]
				set msnobj [lindex $smile 1]
				append animated_smile_send "$symbol\t$msnobj\t"
				incr total
				if {$total >= 5} {
					set smilemsg "$smile_header$animated_smile_send"
					set smilemsg_len [string length $smilemsg]
					WriteSBNoNL $sbn "MSG" "A $smilemsg_len\r\n$smilemsg"
					set msgacks($::MSN::trid) $ackid

					set animated_smile_send ""
					set total 0
					break
				}
			}
			if {$animated_smile_send != "" } {
				set smilemsg "$smile_header$animated_smile_send"
				set smilemsg_len [string length $smilemsg]
				WriteSBNoNL $sbn "MSG" "A $smilemsg_len\r\n$smilemsg"
				set msgacks($::MSN::trid) $ackid
			}
		}

		set msg "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n"
		if { $friendlyname != "" } {
			set msg "${msg}P4-Context: $friendlyname\r\n"
		} elseif { [::config::getKey p4c_name] != "" } {
			set msg "${msg}P4-Context: [encoding convertto identity [::config::getKey p4c_name]]\r\n"
		}

		set msg "${msg}X-MMS-IM-Format: FN=[urlencode $fontfamily]; EF=$style; CO=$color; CS=0; PF=22\r\n\r\n"
		set msg "$msg$txt_send"
		set msg_len [string length $msg]

		WriteSBNoNL $sbn "MSG" "A $msg_len\r\n$msg"

		#Setting trid - ackid correspondence
		set msgacks($::MSN::trid) $ackid

		global typing
		if { [info exists typing($sbn)] } {
			after cancel "unset typing($sbn)"
			unset typing($sbn)
		}

	}

	#///////////////////////////////////////////////////////////////////////////////
	# messageTo (chatid,txt,ackid)
	# Just queue the message send
	proc messageTo { chatid txt ackid {friendlyname "" }} {
		if { [::MSNMobile::IsMobile $chatid] == 1} {
			::MSNMobile::MessageSend $chatid $txt
			return 0
		} elseif { [::OIM_GUI::IsOIM $chatid] == 1 } {
			foreach user [usersInChat $chatid] {
				set ::OIM_GUI::oim_asksend_[string map {: _} ${user} ] 1
			}

			if { [::OIM_GUI::MessageSend $chatid $txt] != "no" } {
				return 0
			}
		}

		ChatQueue $chatid [list ::MSN::SendChatMsg $chatid "$txt" $ackid $friendlyname]
	}
	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////
	#Parses "name: value\nname: value\n..." headers and returns the "value" for "name"
	#TODO remove this proc after deleting the stuff that needs it in the proxy code
	#///////////////////////////////////////////////////////////////////////////////
	proc GetHeaderValue { body name } {

		set reg {^}
		append reg $name
		append reg {:[ \t]*(.*)[ \t]*$}
		if {[regexp -nocase -line $reg $body -> value] } {
			return [string trim $value]			
		} else {
			return ""
		} 
	}
	#///////////////////////////////////////////////////////////////////////////////


	########################################################################
	# Return a sorted version of the contact list
	proc sortedContactList { } {
		variable list_users
		variable last_ordering_options

		if { ![info exists last_ordering_options] } {
			set last_ordering_options ""
		}

		set new_ordering_options [list [::config::getKey orderusersincreasing 1] [config::getKey orderusersbystatus 1] [::config::getKey orderusersbylogsize 0] \
					      [config::getKey emailsincontactlist 0] [config::getKey shownonim 1] [config::getKey groupnonim 0]]

		#Don't sort list again if it's already sorted
		if { $list_users == "" || $last_ordering_options != $new_ordering_options} {
			if { [::config::getKey orderusersincreasing 1] } {
				set order "-increasing"
			} else {
				set order "-decreasing"
			}
			set list_users [::MSN::getList FL]
			if {[::config::getKey shownonim 1] == 1} {
				set list_users [concat $list_users [::MSN::getList EL]]
			}
			set list_users [lsort $order -command ::MSN::CompareNick $list_users]

			if { [config::getKey orderusersbylogsize 1] } {
				# We set the logsize as volatile data because if we get the logsize from
				# the CompareLogSize function, we'll have to call the ::log::getcontactlogsize
				# MANY times for the same contact, and the sorting becomes extremeley difficult.
				foreach user $list_users {
					::abook::setVolatileData $user logsize [::log::getcontactlogsize $user]
				}
				set list_users [lsort -decreasing -command ::MSN::CompareLogSize $list_users]
			}
			if { [config::getKey orderusersbystatus 1] } {
				set list_users [lsort -increasing -command ::MSN::CompareState $list_users]
			}
			set last_ordering_options $new_ordering_options
		}
		return $list_users
	}

	#Mark the contact list as changed
	proc contactListChanged { } {
		variable list_users
		set list_users ""
	}

	#Return the given list
	proc getList { list_type } {
		variable list_${list_type}
		return [set list_${list_type}]
	}

	#Clear the given list
	proc clearList { list_type } {
		variable list_${list_type}
		set list_${list_type}  [list]

		#Clean sorted list cache
		variable list_users
		set list_users ""
	}

	#Make the lists from the abook
	proc makeLists { } {
		foreach contact [::abook::getAllContacts] {
			foreach lst [::abook::getLists $contact] {
				::MSN::addToList $lst $contact
			}
		}
	}

	#Add a user to a list
	proc addToList {list_type user} {
		variable list_${list_type}

		if { ![info exists list_${list_type}] } {
			return
		}
		if { [lsearch [set list_${list_type}]  $user] == -1 } {
			lappend list_${list_type} $user
		} else {
			status_log "::MSN::addToList: User $user already on list $list_type\n" red
		}

		#Clean sorted list cache
		variable list_users
		set list_users ""

	}

	#Delete a user from a list
	proc deleteFromList {list_type user} {
		variable list_${list_type}

		set idx [lsearch [set list_${list_type}] $user]
		if { $idx != -1 } {
			set list_${list_type} [lreplace [set list_${list_type}] $idx $idx]
		} else {
			status_log "::MSN::deleteFromList: User $user is not on list $list_type\n" red
		}

		#Clean sorted list cache
		variable list_users
		set list_users ""
	}

	#Compare two contacts by log size, for sorting
	proc CompareLogSize { item1 item2 } {
		set size1 [::abook::getVolatileData $item1 logsize]
		set size2 [::abook::getVolatileData $item2 logsize]

		set non_im1 [expr {[lsearch [::abook::getContactData $item1 lists] "FL"] == -1}]
		set non_im2 [expr {[lsearch [::abook::getContactData $item2 lists] "FL"] == -1}]
		if {$non_im1 && !$non_im2} {
			return -1
		} elseif {!$non_im1 && $non_im2 } {
			return 1
		} else {
			if { $size1 < $size2 } {
				return -1
			} elseif { $size1 > $size2 } {
				return 1
			} else {
				return 0
			}
		}
	}

	#Compare two states, for sorting
	proc CompareState { item1 item2 } {
		set state1 [::MSN::stateToNumber [::abook::getVolatileData $item1 state FLN]]
		set state2 [::MSN::stateToNumber [::abook::getVolatileData $item2 state FLN]]

		if { $state1 < $state2 } {
			return -1
		} elseif { $state1 > $state2 } {
			return 1
		} else {
			return 0
		}
	}

	#Compare two nicks, for sorting
	proc CompareNick { item1 item2 } {
		set non_im1 [expr {[lsearch [::abook::getContactData $item1 lists] "FL"] == -1}]
		set non_im2 [expr {[lsearch [::abook::getContactData $item2 lists] "FL"] == -1}]
		if {$non_im1 && !$non_im2} {
			if { [::config::getKey orderusersincreasing 1] } {
				return 1
			} else {
				return -1
			}
		} elseif {!$non_im1 && $non_im2 } {
			if { [::config::getKey orderusersincreasing 1] } {
				return -1
			} else {
				return 1
			}
		} else {
			return [string compare -nocase [::abook::getDisplayNick $item1] [::abook::getDisplayNick $item2]]
		}
	}

	proc stateToNumber { state_code } {
		variable list_states
		return [lsearch $list_states "$state_code *"]
	}

	proc numberToState { state_number } {
		variable list_states
		return [lindex [lindex $list_states $state_number] 0]
	}

	proc stateToDescription { state_code } {
		variable list_states
		set state [lindex $list_states [lsearch $list_states "$state_code *"]]
		return [lindex $state 1]
	}


	proc stateToColor { state_code {prefix "contact"}} {
		variable list_states
		set state [lindex $list_states [lsearch $list_states "$state_code *"]]
		set skincolor [::skin::getKey "${prefix}_[lindex $state 1]" [lindex $state 2]]

		return $skincolor
	}

	proc stateToSection { state_code } {
		variable list_states
		set state [lindex $list_states [lsearch $list_states "$state_code *"]]
		return [lindex $state 3]
	}

	proc stateToImage { state_code } {
		variable list_states
		set state [lindex $list_states [lsearch $list_states "$state_code *"]]
		return [lindex $state 4]
	}

	proc stateToBigImage { state_code } {
		variable list_states
		set state [lindex $list_states [lsearch $list_states "$state_code *"]]
		return [lindex $state 5]
	}

	proc getClientConfig {} {
		set soap [SOAPRequest create %AUTO% -url "http://config.messenger.msn.com/Config/MsgrConfig.asmx" -action "http://www.msn.com/webservices/Messenger/Client/GetClientConfig" -xml [::MSN::getClientConfigXml]]
		$soap SendSOAPRequest
		if {[$soap GetStatus] == "success" } {
			set ret [$soap GetResponse]
		} else {
			set ret [$soap GetLastError]
		}
		$soap destroy
		return $ret
	}

	proc getClientConfigXml {} {
		#TODO: make it choose the right Country, CLCID, PLCID, GeoID
		return {<?xml version="1.0" encoding="utf-8"?> <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><GetClientConfig xmlns='http://www.msn.com/webservices/Messenger/Client'> <clientinfo> <Country>HT</Country> <CLCID>0409</CLCID> <PLCID>0409</PLCID> <GeoID>244</GeoID> </clientinfo> </GetClientConfig></soap:Body></soap:Envelope>}
	}

}


namespace eval ::MSNOIM {

	proc parseFieldEncoding { encoded } {
		set parts [split $encoded ?]
		if { [lindex $parts 0] == "=" &&
		     ( [lindex $parts 4] == "=" || [lindex $parts 4] == "= ")} {
			foreach {c1 charset type data c2} $parts break
			set encoding_exists 0
			foreach enc [encoding names] {
				if { $enc == $charset } {
					set encoding_exists 1
				}
			}
			
			if {$type == "B" } {
				if { [string range $data 0 0] == "=" } {
					set data [string range $data 1 end]
				}
				# We might receive an invalid base64 value...
				set decoded $data
				catch {set decoded [base64::decode $data]}
			} elseif {$type == "Q" } {
				set decoded [urldecode $data]
			} else {
				set decoded $data
			}
			if { $encoding_exists } {
				set decoded [encoding convertfrom $charset $decoded]
			}
		} else {
			set decoded $encoded
		}
		return $decoded
	}
	
	proc getOIMMessageCallback { callbk mid msg } {
		if { $msg != ""} {
			set from [$msg getHeader From]
			set sequence [$msg getHeader X-OIM-Sequence-Num]
			set runId [$msg getHeader X-OIM-Run-ID]
			set body [string map {"\r\n" "\n"} [$msg getBody]]
			set ctype [$msg getHeader Content-type]
			set cencoding [$msg getHeader Content-Transfer-Encoding]
			set arrivalTime [$msg getHeader X-OriginalArrivalTime]
			if { ![regexp {([^\<]*)\s?\<([^\>]+)\>} $from -> nick email] } {
				set email $from
				set nick $from
			} elseif { $nick == ""} {
				set nick $email
			}
			set email [string trim $email " <>"]
			set nick [parseFieldEncoding $nick]
			if { $cencoding == "base64" } {
				set body [encoding convertfrom identity [string map {"\r\n" "\n"} [base64::decode [string trim $body]]]]
			}
			if {[catch {eval $callbk [list [list $sequence $email $nick $body $mid $runId $arrivalTime]]} result]} {
				bgerror $result
			}
		} else {
			if {[catch {eval $callbk [list [list]]} result]} {
				bgerror $result
			}
		}
	}

	proc getOIMMessage { callbk mid } {
		set msg [getOIMMail "::MSNOIM::getOIMMessageCallback [list $callbk] $mid" $mid]
	}

	proc getOIMMailCallback { callbk mid retry soap } {
		if { [$soap GetStatus] == "success" } {
			set xml [$soap GetResponse]
			$soap destroy

			set msg [GetXmlEntry $xml "soap:Envelope:soap:Body:GetMessageResponse:GetMessageResult"]
			set msg [string map {"\r\n" "\n" } $msg]
			set msg [string map {"\n" "\r\n" } $msg]
			set message [Message create %AUTO%]
			$message createFromPayload $msg
			if {[catch {eval $callbk [list $message]} result]} {
				bgerror $result
			}
		} elseif { [$soap GetStatus] == "fault" } {
                        set xml [$soap GetResponse]
                        status_log "Error in OIM:" white
                        status_log $xml white
                        set faultcode [$soap GetFaultCode]
                        $soap destroy
			status_log "Fault code: $faultcode" white

                        if { $faultcode == "AuthenticationFailed" } {
				status_log "Auth failed, retry : $retry" white
                                set reauth [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:detail:RequiredAuthPolicy"]
                                set lock_challenge [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:detail:LockKeyChallenge"]
                                if { $lock_challenge != "" } {
                                        CreateLockKey $lock_challenge
                                }
				if {$reauth != "" } {
					set token [$::sso GetSecurityTokenByName MessengerSecure]
					$token configure -expires ""
				}
				if { $retry > 0 } {
					::MSNOIM::getOIMMail $callbk $mid [incr retry -1]
				} else {
					if {[catch {eval $callbk [list [list]]} result]} {
						bgerror $result
					}
				}
                        } else {
                                if {[catch {eval $callbk [list [list]]} result]} {
                                        bgerror $result
                                }
                        }
		} else {
			$soap destroy
			if {[catch {eval $callbk [list [list]]} result]} {
				bgerror $result
			}
		}
	}

	proc getOIMMail { callbk mid {retry 2} } {
		$::sso RequireSecurityToken Messenger [list ::MSNOIM::getOIMMailSSOCB $callbk $mid $retry]
	}

	proc getOIMMailSSOCB { callbk mid retry ticket} {
		set cookies [split $ticket &]
		foreach cookie $cookies {
			set c [split $cookie =]
			set ticket_[lindex $c 0] [lindex $c 1]
		}
				
		if { [info exists ticket_t] && [info exists ticket_p] } {
			set soap_req [SOAPRequest create %AUTO% \
					  -url "https://rsi.hotmail.com/rsi/rsi.asmx" \
					  -action "http://www.hotmail.msn.com/ws/2004/09/oim/rsi/GetMessage" \
					  -xml [::MSNOIM::getOIMMailXml $mid $ticket_t $ticket_p] \
					  -callback  [list ::MSNOIM::getOIMMailCallback $callbk $mid $retry]]


			$soap_req SendSOAPRequest
			return
		}
		
		# This gets executed if the SOAP request is not sent.. serves as error handler
		if {[catch {eval $callbk [list [list]]} result]} {
			bgerror $result
		}
	}
	
	proc getOIMMailXml {mid ticket_t ticket_p } {
		set xml {<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Header><PassportCookie xmlns="http://www.hotmail.msn.com/ws/2004/09/oim/rsi"><t>}
		append xml [xmlencode $ticket_t]
		append xml {</t><p>}
		append xml [xmlencode $ticket_p]
		append xml {</p></PassportCookie></soap:Header><soap:Body><GetMessage xmlns="http://www.hotmail.msn.com/ws/2004/09/oim/rsi"><messageId>}
		append xml [xmlencode $mid]
		append xml {</messageId><alsoMarkAsRead>false</alsoMarkAsRead></GetMessage></soap:Body></soap:Envelope>}
		return $xml
	}

	proc sendOIMMessageCallback { callbk to msg retry seq_nbr soap} {
		if { [$soap GetStatus] == "success" } {
			status_log "OIM sent to $to successfully : [$soap GetResponse]" green
			set res "success"
		} elseif { [$soap GetStatus] == "fault" } {
			set xml [$soap GetResponse]
			status_log "Error in OIM:" white
			status_log $xml white
			set faultcode [$soap GetFaultCode]

			if { $faultcode == "q0:AuthenticationFailed" } {
				set reauth [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:detail:RequiredAuthPolicy"]
				set lock_challenge [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:detail:LockKeyChallenge"]
				if { $lock_challenge != "" } {
					CreateLockKey $lock_challenge
				} 
				if {$reauth != "" } {
					set token [$::sso GetSecurityTokenByName MessengerSecure]
					$token configure -expires ""
				}
				if { $retry > 0 } {
					$soap destroy
					::MSNOIM::sendOIMMessage $callbk $to $msg [incr retry -1] $seq_nbr
					return
				} else {
					set res "authentication failed"
				}
			} elseif { $faultcode == "q0:SystemUnavailable" } {
				set res "invaliduser"
			} elseif { $faultcode == "q0:SenderThrottleLimitExceeded" } {
				set res "Flood Protection Activated"
			} else {
				set res "Unexpected error"
			}
		} else {
			set res "Unexpected error"
		}

		$soap destroy
		if {[catch {eval $callbk [list $res]} result]} {
			bgerror $result
		}
	}
	
	proc sendOIMMessage { callbk to msg {retry 5} {seq_nbr 0}} {
		$::sso RequireSecurityToken MessengerSecure [list ::MSNOIM::sendOIMMessageSSOCB $callbk $to $msg $retry $seq_nbr]
	}

	proc sendOIMMessageSSOCB { callbk to msg retry seq_nbr ticket} {
		variable seq_number
		set id [::md5::hmac $to $msg]

		if { $seq_nbr == 0 } {
			if {![info exists seq_number($to)] } {
				set seq_number($to) 1
			} else {
				incr seq_number($to)
			}
			set seq_nbr [set seq_number($to)]
		}

		set soap_req [SOAPRequest create %AUTO% \
				  -url "https://ows.messenger.msn.com/OimWS/oim.asmx" \
				  -action "http://messenger.live.com/ws/2006/09/oim/Store2" \
				  -xml [::MSNOIM::sendOIMMessageXml $ticket $to $msg $seq_nbr] \
				  -callback [list ::MSNOIM::sendOIMMessageCallback $callbk $to $msg $retry $seq_nbr]]

		$soap_req SendSOAPRequest
	}
	
	proc CreateLockKey { challenge } {
		variable lockkey
		set lockkey [::MSN::CreateQRYHash $challenge  {PROD0119GSJUC$18} {ILTXC!4IXB5FB*PX}]
	}

	proc sendOIMMessageXml {ticket to msg seq_number} {
		variable lockkey 
		variable runid

		if { ![info exists lockkey ]} {
			set lockkey ""
		}
		if {![info exists runid($to)]} {
			set runid($to) "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr { int([expr {rand() * 1000000}])%65450 } ] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		}

		# The official client sends the nickname limited to 48 characters, if we don't limit it to 48, the server will throw an error at us...
		set bmessage [base64::encode [encoding convertto identity [string map {"\n" "\r\n"} $msg]] ]

		set bnick [string map {"\n" "" } [base64::encode [string range [encoding convertto utf-8 [::abook::getPersonal MFN]] 0 47]]]

		set xml {<?xml version="1.0" encoding="utf-8"?> <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Header><From}
		append xml " memberName=\"[config::getKey login]\" friendlyName=\"=?utf-8?B?${bnick}?=\" "
		append xml {xml:lang="en-US" proxy="MSNMSGR" xmlns="http://messenger.msn.com/ws/2004/09/oim/" msnpVer="MSNP15" buildVer="8.5.1302"/> <To}
		append xml " memberName=\"$to\" "
		append xml {xmlns="http://messenger.msn.com/ws/2004/09/oim/"/><Ticket}
		append xml " passport=\"[xmlencode $ticket]\" appid=\"PROD0119GSJUC\$18\" lockkey=\"[xmlencode $lockkey]\" xmlns=\"http://messenger.msn.com/ws/2004/09/oim/\"/> "
		append xml {<Sequence xmlns="http://schemas.xmlsoap.org/ws/2003/03/rm"><Identifier xmlns="http://schemas.xmlsoap.org/ws/2002/07/utility">http://messenger.msn.com</Identifier><MessageNumber>}
		append xml $seq_number
		append xml {</MessageNumber></Sequence></soap:Header><soap:Body><MessageType xmlns="http://messenger.msn.com/ws/2004/09/oim/">text</MessageType><Content xmlns="http://messenger.msn.com/ws/2004/09/oim/">}
		append xml "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\nContent-Transfer-Encoding: base64\r\nX-OIM-Message-Type: OfflineMessage\r\nX-OIM-Run-Id: {[set runid($to)]}\r\nX-OIM-Sequence-Num: ${seq_number}\r\n\r\n$bmessage"
		append xml {</Content></soap:Body></soap:Envelope>}
		status_log "Sending OIM:" green
		#status_log $xml green
		return $xml
	}

	proc deleteOIMMessageCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
			$soap destroy
			if {[catch {eval $callbk [list 1]} result]} {
				bgerror $result
			}
		} else {
			$soap destroy
			status_log "error deleting OIMS : [$soap GetResponse]" red
			if {[catch {eval $callbk [list 0]} result]} {
				bgerror $result
			}
		}
	}

	proc deleteOIMMessage { callbk mids } {
		$::sso RequireSecurityToken Messenger [list ::MSNOIM::deleteOIMMessageSSOCB $callbk $mids]
	}

	proc deleteOIMMessageSSOCB { callbk mids ticket } {
		set cookies [split $ticket &]
		foreach cookie $cookies {
			set c [split $cookie =]
			set ticket_[lindex $c 0] [lindex $c 1]
		}
			
		status_log "deleting oims : $mids"
		if { [info exists ticket_t] && [info exists ticket_p] } {
			set id [::md5::hmac $callbk $mids]
			set soap_req [SOAPRequest create %AUTO% \
					  -url "https://rsi.hotmail.com/rsi/rsi.asmx" \
					  -action "http://www.hotmail.msn.com/ws/2004/09/oim/rsi/DeleteMessages" \
					  -xml [::MSNOIM::deleteOIMMessageXml $mids $ticket_t $ticket_p] \
					  -callback [list ::MSNOIM::deleteOIMMessageCallback $callbk] ]
			$soap_req SendSOAPRequest
		}
	}

	proc deleteOIMMessageXml { mids ticket_t ticket_p} {
		set xml {<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Header><PassportCookie xmlns="http://www.hotmail.msn.com/ws/2004/09/oim/rsi"><t>}
		append xml [xmlencode $ticket_t]
		append xml {</t><p>}
		append xml [xmlencode $ticket_p]
		append xml {</p></PassportCookie></soap:Header><soap:Body><DeleteMessages xmlns="http://www.hotmail.msn.com/ws/2004/09/oim/rsi"><messageIds>}
		foreach mid $mids {
			append xml {<messageId>}
			append xml $mid
			append xml {</messageId>}
		}
		append xml {</messageIds></DeleteMessages></soap:Body></soap:Envelope>}
		return $xml
	}
	
	proc getMailDataCallback { callbk soap } {
		if { [$soap GetStatus] == "success" && 
			[catch {list2xml [lindex [lindex [GetXmlNode [$soap GetResponse] "soap:Envelope:soap:Body:GetMetadataResponse"] 2] 0]} MailData] == 0 } {
			$soap destroy
			if {[catch {eval $callbk [list $MailData]} result]} {
				bgerror $result
			}
		} else {
			$soap destroy
			if {[catch {eval $callbk [list [list]]} result]} {
				bgerror $result
			}
		}
	}
	

	proc getMailData { callbk } {
		$::sso RequireSecurityToken Messenger [list ::MSNOIM::getMailDataSSOCB $callbk]
	}

	proc getMailDataSSOCB { callbk ticket } {
		set cookies [split $ticket &]
		foreach cookie $cookies {
			set c [split $cookie =]
			set ticket_[lindex $c 0] [lindex $c 1]
		}

		if { [info exists ticket_t] && [info exists ticket_p] } {
			set soap_req [SOAPRequest create %AUTO% \
                	                  -url "https://rsi.hotmail.com/rsi/rsi.asmx" \
                        	          -action "http://www.hotmail.msn.com/ws/2004/09/oim/rsi/GetMetadata" \
                                	  -xml [::MSNOIM::getMailDataXml $ticket_t $ticket_p] \
	                                  -callback [list ::MSNOIM::getMailDataCallback $callbk]]
			$soap_req SendSOAPRequest
		}
	}

	proc getMailDataXml { ticket_t ticket_p } {
		set xml {<?xml version="1.0" encoding="utf-8"?> <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Header><PassportCookie xmlns="http://www.hotmail.msn.com/ws/2004/09/oim/rsi"> <t>}
		append xml [xmlencode $ticket_t]
		append xml {</t><p>}
		append xml [xmlencode $ticket_p]
		append xml {</p></PassportCookie></soap:Header><soap:Body><GetMetadata xmlns="http://www.hotmail.msn.com/ws/2004/09/oim/rsi" /></soap:Body></soap:Envelope>}
		return $xml
	}


}

::snit::type Message {

	variable fields
	variable headers
	variable body ""

	constructor {args} {
	}

	method setRaw { data {headers_list {}} {fields_list {}}} {
		set body $data
		array set headers $headers_list
		array set fields $fields_list
	}

	#creates a message object from a received payload
	method createFromPayload { payload } {
		set idx [string first "\r\n\r\n" $payload]
		if {$idx == -1 } { 
			$self setRaw $payload 
		} else {
			set head [string range $payload 0 [expr {$idx -1}]]
			set body [string range $payload [expr {$idx +4}] end]
			set head [string map {"\r\n" "\n"} $head]
			set heads [split $head "\n"]
			foreach header $heads {
				set idx [string first ": " $header]
				array set headers [list [string range $header 0 [expr {$idx -1}]] \
						       [string range $header [expr {$idx +2}] end]]
			}
			
			set bsplit [split [string map {"\r\n" "\n"} $body] "\n"]
			foreach field $bsplit {
				set idx [string first ": " $field]
				array set fields [list [string range $field  0  [expr {$idx -1}]] \
						      [string range $field [expr {$idx +2}] end]]
			}
		}
	}

	method getBody { } {
		return $body
	}

	method getField { name } {
		return [lindex [array get fields $name] 1]
	}

	method getFields { } {
		return [array get fields]
	}

	method getHeader { name } {
		return [lindex [array get headers $name] 1]
	}

	method getHeaders { } {
		return [array get headers]
	}

	method setBody { txt } {
		set body $txt
	}

	method setHeader { list } {
		array set headers $list
	}
}


::snit::type Connection {

	option -name
	option -server ""
	option -stat ""
	option -sock ""
	option -connected ""
	option -proxy ""
	option -time ""
	option -error_msg ""
	option -force_gateway_server ""
	option -proxy_host
	option -proxy_port
	option -proxy_authenticate
	option -proxy_user
	option -proxy_password

	variable dataBuffer ""

	##########################################################################################
	# Public methods
	# these are the methods you want to call from outside this object
	destructor {
		status_log "End of proxy for $options(-name). Destruction of proxy $options(-proxy). Closing socket $options(-sock)" red
		catch {
			$options(-proxy) finish $options(-name)
			after idle [list $options(-proxy) destroy]
		}
		catch {
			close $options(-sock)
		}
	}

	##########################################################################################
	# Private methods
	# these are the methods you DON'T want to call from outside this object, only from inside

	#this method is called when the socket becomes readable
	#it will get data from the socket and call handleCommand
	method receivedData { {httpdata ""} } {
		set dataRemains 1
		set httpdata_added 0
		while { $dataRemains } {
			# Ugly hack.. this is a dc 'socket readable' callback and a function called by HTTPRead with the content-data
			if {$httpdata == "" } {
				#put available data in buffer. When buffer is empty dataRemains is set to 0
				if { [info procs $self] != "" || [info procs Snit_methodreceivedData] != ""} {
					if {[catch {set dataRemains [$self appendDataToBuffer]}] } {
						status_log "$self has been destroyed while being in use.. couldn't test it, but caught it" red
					}
				} else {
					status_log "$self has been destroyed while being used" red
					break
				}
			} elseif {$httpdata_added == 0} {
				append dataBuffer $httpdata
				set httpdata_added 1
			}
			#check if appendDataToBuffer didn't close this object because the socket was closed
			if { [info exists dataBuffer] == 0 } { break }
		
			#check for the a newline, if there is we have a command if not return
			set idx [string first "\r\n" $dataBuffer]
			if { $idx == -1 } { return }
			set command [string range $dataBuffer 0 [expr {$idx -1}]]
			

			set has_payload 0

			global list_cmdhnd
			set sb_name $options(-name)
			if {$sb_name == "::ns" } {
				set sb_name "ns"
			}
			set trid [lindex [split $command] 1]
			set handler_idx [lsearch $list_cmdhnd "$sb_name $trid *"]
			if {$handler_idx != -1} {		;# Command has a handler associated!
				set cmd [lindex [lindex $list_cmdhnd $handler_idx] 2]
				set handler [lindex $cmd 0]
				set handler_args [lrange $cmd 1 end]
				set handler_numargs [llength $handler_args]
				set handler_realargs [list]

				set handler_is_snit 0
				#snit with tcl 8.5 creates a command, but not a proc
				if {[info command $handler] == "$handler" &&
				    [namespace eval :: info proc $handler] == "" } {
					set handler_is_snit 1
				} else {
					set handler_realargs [info args $handler]
					#snit with tcl 8.4 gives us "method args"
					if {$handler_realargs == "method args" } {
						set handler_is_snit 1
					}
				}

				if {$handler_is_snit } {
					set method [lindex $cmd 1]
					set handler_args [lrange $cmd 2 end]
					set handler_numargs [llength $handler_args]
					set handler_realargs [$handler info args $method]
					status_log "Detected snit object $handler. Method was $method" blue
				}

				set handler_num_realargs [llength $handler_realargs]

				if {$handler_num_realargs == [expr {$handler_numargs + 1}] } {
					set has_payload 0
				} elseif {$handler_num_realargs == [expr {$handler_numargs + 2}] } {
					set length [lindex [split $command] end]
					if {[string is integer -strict $length] } {
						set has_payload 1
					} else {
						status_log "We expect a payload but the length is $length. Could be an ADL OK or ILN. No payload." blue
						set has_payload 0
					}
				} else {
					status_log "We are expecting a bug here!!!!"
				}

				status_log "Found handler for command [lindex [split $command] 0] with trid $trid : $handler with $handler_numargs args. Function needs $handler_realargs. So the command has payload : $has_payload" blue
			} else {
				#check for payload commands:
				if {[lsearch {MSG NOT PAG IPG UBX GCF UBN UBM FQY} [string range $command 0 2]] != -1 ||
				    ($trid == 0 && [lsearch {RML ADL} [string range $command 0 2]] != -1)} {
					set has_payload 1
				}
			}

			if { $has_payload } {
				set length [lindex [split [string trimright $command]] end]

				#There is a bug (#2265) where $length is not numeric
				# report error on status_log is this occurs so we can track it down
				if {![string is integer -strict $length]} {
					status_log "#-----------------------#\nERROR in $self :: var \$length is \"$length\" while it should be an integer !!!\n\tCommand: $command (last element is length)\n#-----------------------#" white
				}

				set remaining [string range $dataBuffer [expr {$idx +2}] end]
				
				#if the whole payload is in the buffer process the command else return
				if { [string length $remaining] >= $length } {
					set payload [string range $remaining 0 [expr {$length -1}]]
					set dataBuffer [string range $dataBuffer [string length "$command\r\n$payload"] end]
					set command [encoding convertfrom utf-8 $command]
					$options(-name) handleCommand $command $payload
				} else {
					return
				}
			} else {
				set dataBuffer [string range $dataBuffer [string length "$command\r\n"] end]
				set command [encoding convertfrom utf-8 $command]
				$options(-name) handleCommand $command
			}
			update idletasks
		}
	}

	#this is called by receivedData to get data from the socket into a buffer
	#if there is data available on the socket put it in the buffer and return 1
	#if no data is available return 0
	method appendDataToBuffer { } {
		set sock $options(-sock)
		if {[catch {eof $sock} res]} {
			status_log "Error reading EOF for $self: $res\n" red
			catch {fileevent $sock readable ""}
			$self sockError
			return 0
		} elseif {[eof $sock]} {
			status_log "Read EOF in $self, closing\n" red
			catch {fileevent $sock readable ""}
			$self sockError
			return 0
		} else {
			set tmp_data "ERROR READING SOCKET !!!"
			if {[catch {set tmp_data [read $sock]} res]} {
				status_log "Read error in $self, closing: $res\n" red
				catch {fileevent $sock readable ""}
				$self sockError
				return 0
			}
			
			append dataBuffer $tmp_data
			return 1
		}
	}

	method sockError { } {
		::MSN::CloseSB $options(-name)
	}
}

::snit::type NS {

	delegate option * to connection
	delegate method * to connection
	option -autherror_handler ""
	option -passerror_handler ""
	option -ticket_handler ""
	option -proxy_port

	constructor {args} {
		install connection using Connection %AUTO% -name $self
		$self configurelist $args
	}

	destructor {
		catch { $connection destroy }
	}

	method handleCommand { command {payload ""}} {
		set command [split $command]
		degt_protocol "<-ns-[$self cget -sock] $command" "nsrecv"
		set message ""
		if { $payload != "" } {
			degt_protocol "Message Contents:\n$payload" "nsrecv"
			set message [Message create %AUTO%]
			$message createFromPayload $payload
		}

		global list_cmdhnd
		set ret_trid [lindex $command 1]
		set idx [lsearch $list_cmdhnd "ns $ret_trid *"]
		if {$idx != -1 && [lindex $command 0] != "LSG"} {		;# Command has a handler associated!
			status_log "::NS::handleCommand: evaluating handler for $ret_trid\n"

			set cmd "[lindex [lindex $list_cmdhnd $idx] 2] [list $command]"
			if {$payload != "" } {
				set done [eval [linsert $cmd end $payload]]
			} else {
				set done [eval $cmd]
			}
			if {$done} {
				set list_cmdhnd [lreplace $list_cmdhnd $idx $idx]
			}

			return 0
		} else {

			switch -- [lindex $command 0] {
				UBM {
					$self handleUBM $command $message
				}
				RML {
					$self handleRML $command $payload
				}
				ADL {
					$self handleADL $command $payload
				}
				ILN {
					cmsn_ns_handler $command $message
				}
				IPG {
					cmsn_ns_handler $command $payload
				}
				LSG {
					$self handleLSG $command
				}
				LST {
					$self handleLST $command
				}
				NLN {
					cmsn_ns_handler $command $message
				}
				PRP {
					$self handlePRP $command
				}
				#SIP request
				UBN {
					$self handleUBN $command $payload
				}
				#psm info
				UBX {
					$self handleUBX $command $payload
					catch {$message destroy}
				}
				#spaces info
				NOT {
					$self handleNOT $command $payload
					catch {$message destroy}
				}				
				default {
					cmsn_ns_handler $command $message
				}
			}
		}
	}

	method handleUBN { command message } {
		if {$message == "goawyplzthxbye" || $message == "gtfo"} {
			::MSN::logout
		} 
		switch -- [lindex $command 2] {
			1 {
				# XML data
			}
			2 {
				# SIP INVITE
				if {[llength $message] == 3 && [lindex $message 0] == "INVITE"} {
					::MSNSIP::ReceivedInvite [lindex $message 1]
				}
			}
			3 {
				# MSNP2P SLP data...
			}
			11 {
				# Unknown "1 1 5 134546710 0" prior to SIP invite...
			}
		}
	}

	method handleUBM { command message } {
		# TODO handle messages received from yahoo contacts
	}

	method handleRML { command payload } {
		if {$payload == "" } {
			set ok [lindex $command end]
			if { $ok == "OK" } {
				
			}
		} else {
			set xml [xml2list $payload]
			set node [GetXmlNode $xml "ml:d"]
			set dmn [GetXmlAttribute $node d n]
			set cfield [GetXmlNode $node "d:c"]
			set usr [GetXmlAttribute $cfield c n]
			set mask [GetXmlAttribute $cfield c l]
			set user "$usr@$dmn"
			
			switch -- $mask {
				1 {
					set lst FL
				}
				2 {
					set lst AL
				}
				4 {
					set lst BL
				}
				8 {
					set lst RL
				}
			}

			::abook::removeContactFromList $user $lst
			::MSN::deleteFromList $lst $user
			::MSN::contactListChanged
			#an event to let the GUI know a user is removed from a list
			::Event::fireEvent contactListChange protocol $user
		}
	}

	method handleADL { command payload } {
		if {$payload == "" } {
			set ok [lindex $command end]
		} else {
			set xml [xml2list $payload]
			set node [GetXmlNode $xml "ml:d"]
			set dmn [GetXmlAttribute $node d n]
			set cfield [GetXmlNode $node "d:c"]
			set usr [GetXmlAttribute $cfield c n]
			set mask [GetXmlAttribute $cfield c l]
			set nick [GetXmlAttribute $cfield c f]
			set username "$usr@$dmn"

			switch -- $mask {
				1 {
					set lst FL
				}
				2 {
					set lst AL
				}
				4 {
					set lst BL
				}
				8 {
					set lst RL
				}
			}

			::abook::addContactToList $username $lst
			::MSN::addToList $lst $username

			::MSN::contactListChanged

			#an event to let the GUI know a user was added to a list
			::Event::fireEvent contactListChange protocol $username

			if { $lst == "RL" && [lsearch [::abook::getContactData $username lists] "FL"] == -1} {
				$::ab Synchronize [list ::MSN::ABSynchronizationDone 0]
			}
			if { $lst == "FL" || $lst == "RL" } {
				#Don't send the event for an addition to any other list
				::Event::fireEvent contactAdded protocol $username ""
			}
		}
	}
	method handleADLResponse { command {payload ""}} {
		# We should probably take a look at the command returned, if we get an 'OK' or an error, etc... 
		# maybe our list/xml has something wrong in it, etc...
		if {[lindex $command 0] != "ADL" } {
			status_log "ADL Response is an error : [lindex $command 0] = $payload" red
			# TODO : keep a list of the contacts originally sent and the list of contacts with an error
			# if all contacts sent returned with an error, then return 1, since we can't expect an ADL OK
			return 0
		} else {
			return 1
		}
	}

	method handleLSG { command } {
		global loading_list_info

		set group [Group create %AUTO% -name [lindex $command 1] -id [lindex $command 2]]
		$group showInfo
		::groups::Set [lindex $command 2] [lindex $command 1]

		#Increment the group number
		incr loading_list_info(gcurrent)

		#Get the current group number
		set current $loading_list_info(gcurrent)
		set total $loading_list_info(gtotal)


		# Check if there are no users and we got all LSGs, then we finished the authentification
		if {$current == $total && $loading_list_info(total) == 0} {
			$self setInitialStatus
			$self authenticationDone
		}
	}

	
	method authenticationDone {} {
		global reconnect_timer
		set reconnect_timer 0

		set ::contactlist_loaded 1
		::abook::setConsistent
		::abook::saveToDisk

		after 0 { 
			cmsn_draw_online 1

			#Update Preferences window if it's open
			after 1000 {catch {InitPref 1}}
		}

		::Event::fireEvent contactlistLoaded protocol
		::plugins::PostEvent contactlistLoaded evPar

	}

	method handleLST { command } {
		global contactlist_loaded
		global loading_list_info

		set contactlist_loaded 0

		#Increment the contact number
		incr loading_list_info(current)

		#Get the current contact number
		set current $loading_list_info(current)
		set total $loading_list_info(total)


		set nickname ""
		set contactguid ""
		set list_names ""
		set unknown ""
		set groups "0"

		#We skip LST
		foreach information [lrange $command 1 end] {
			set key [string toupper [string range $information 0 1]]
			if { $key == "N=" } {
				set username [string range $information 2 end]
			} elseif { $key == "F=" } {
				set nickname [urldecode [string range $information 2 end]]
			} elseif { $key == "C=" } {
				set contactguid [string range $information 2 end]
			} elseif { $list_names == "" } {
				#We didn't get the list names
				set list_names $information
				#status_log $list_names
			} elseif { $unknown == "" } {
				set unknown $information
			} elseif { $groups == "0" } {
				#We didn't get the group list
				set groups $information
			}
		}

		set list_names [process_msnp11_lists $list_names]
		set groups [split $groups ,]

		if { $groups == "" } {
			set groups 0
		}

		#Make list unconsistent while receiving contact lists
		::abook::unsetConsistent

		::abook::setContactData $username nick $nickname

		::abook::setContactData $username contactguid $contactguid
		::abook::setContactForGuid $contactguid $username

		foreach list_sort $list_names {

			#If list is not empty, get user information
			if {$current != 0} {

				::abook::addContactToList $username $list_sort
				::MSN::addToList $list_sort $username

				#No need to set groups and set offline state if contact is not in FL
				if { $list_sort == "FL" } {
					::abook::setContactData $username group $groups
					set loading_list_info(last) $username
					::abook::setVolatileData $username state "FLN"
				}
			}
		}

		set lists [::abook::getLists $username]
		if { [lsearch $lists PL] != -1 } {
			if { [lsearch [::abook::getLists $username] "AL"] != -1 || [lsearch [::abook::getLists $username] "BL"] != -1 } {
				#We already added it we only move it from PL to RL
				#Just add to RL for now and let the handler remove it from PL... to be sure it's the correct order...
				::MSN::WriteSB ns "ADC" "RL N=$username"
			} else {
				newcontact $username $nickname
			}
		}

		::MSN::contactListChanged

		#Last user in list
		if {$current == $total} {
			$self setInitialStatus
			$self authenticationDone
		}

	}

	method handlePRP { command } {
		if { [llength $command] == 3 } {
			#initial PRP without trID
			::abook::setPersonal [lindex $command 1] [urldecode [lindex $command 2]]
			if { ([lindex $command 1] == "MOB") && ([lindex $command 2] == "Y") } {
				::MSN::setClientCap paging
			}
		} else {
			#PRP in response to phone number change
			::abook::setPersonal [lindex $command 2] [urldecode [lindex $command 3]]
		}
	}

	#Callback procedure called when a PRP (Personal info like nick and phone change) message is received
	method handlePRPResponse { newname update command } {
		switch -- [lindex $command 0] {
			PRP {
				::abook::setPersonal [lindex $command 2] [urldecode [lindex $command 3]]
				#TODO: put this here to be the same as the old REA response, should it be moved to abook?
				if { [lindex $command 2] == "MFN" } {
					cmsn_draw_online 1 1
					send_dock STATUS [::MSN::myStatusIs]
					
					if {$update && [::config::getKey protocol] >= 15 } {
						$::roaming UpdateProfile [list $self updateProfileCB] [::abook::getPersonal MFN] [::abook::getPersonal PSM]
						$::ab ABContactUpdate [list ::MSN::ABUpdateNicknameCB] "" [list contactType Me displayName [xmlencode [::abook::getPersonal MFN]]] DisplayName

					}
					#an event used by guicontactlist to know when we changed our nick
					::Event::fireEvent myNickChange protocol
				}
				::abook::saveToDisk
			}
			209 {
				#Nickname change illegal.
				msg_box [trans invalidusername]
			}
			715 {
				# passport account not verified
				msg_box [trans passportnotverified]
			}
			default {
			}
		}
		return 1
	}

	method updateProfileCB { fail } {
	}

	method handleUBX { command payload } {
		set contact [lindex $command 1]
		if {$payload != ""} {
			if { [catch { set xml [xml2list $payload] } ] } {
				return
			}
			set psm [::sxml::replacexml [encoding convertfrom utf-8 [GetXmlEntry $xml "Data:PSM"]]]
			set currentMedia [::sxml::replacexml [encoding convertfrom utf-8 [GetXmlEntry $xml "Data:CurrentMedia"]]]
			set signatureSound [::sxml::replacexml [encoding convertfrom utf-8 [GetXmlEntry $xml "Data:SignatureSound"]]]
		} else {
			set psm ""
			set currentMedia ""
			set signatureSound ""
		}
		::abook::setVolatileData $contact PSM $psm
		::abook::setVolatileData $contact currentMedia $currentMedia

		if {[config::getKey protocol] >= 16} {
			::abook::setVolatileData $contact signatureSound $signatureSound
			if { [config::getKey login] == $contact} {
				::abook::setPersonal PSM $psm
				::abook::setVolatileData myself currentMedia $currentMedia	
				::abook::setPersonal signatureSound $signatureSound

				if {$payload != ""} {
					if { ![catch { set xml [xml2list $payload] } ] } {
						set  i 0
						::abook::clearEndPoints
						while {1} {
							set node [GetXmlNode $xml "Data:PrivateEndpointData" $i]
							if {$node == "" } {
								break
							} 
							incr i
							set ep [GetXmlAttribute $node "PrivateEndpointData" "id"]
							set epname [::sxml::replacexml [encoding convertfrom utf-8 [GetXmlEntry $node "PrivateEndpointData:EpName"]]]
							::abook::setEndPoint $ep $epname
						}
					}
				}
				cmsn_draw_online 1 1	
			}
		}

		if {$currentMedia != "" } {
			::log::eventpsm $contact $currentMedia
		} else {
			::log::eventpsm $contact $psm
		}

		foreach chat_id [::ChatWindow::getAllChatIds] {
			if { $chat_id == $contact } {
				::ChatWindow::TopUpdate $chat_id
			} else {
				foreach user_in_chat [::MSN::usersInChat $chat_id] {
						if { $user_in_chat == $contact } {
								::ChatWindow::TopUpdate $chat_id
								break
						}
				}
			}
		}
		::Event::fireEvent contactPSMChange protocol $contact
	}
	
	method handleNOT { command payload } {
		#save the spaces notification here
		set contact [lindex $command 1]
		status_log "got spaces notification for $contact ($command)"
		::abook::setVolatileData $contact space_updated 1
		::Event::fireEvent contactSpaceChange protocol $contact
	}

	method setInitialStatus { } {

		set newstate "NLN"
		set newstate_custom $newstate
		#Don't use oldstatus if it was "FLN" (disconnectd) or we will get a 201 error
		if {[info exists ::oldstatus] && $::oldstatus != "FLN" } {
			set newstate $::oldstatus
			unset ::oldstatus
			set newstate_custom $newstate
		} elseif {![is_connectas_custom_state [::config::getKey connectas]]} {
			#Protocol code to choose our state on connect
			set number [get_state_list_idx [::config::getKey connectas]]
			set goodstatecode "[::MSN::numberToState $number]"

			if {$goodstatecode != ""} {
				set newstate $goodstatecode
			} else {
				status_log "Not able to get choosen key: [::config::getKey connectas]"
				set newstate "NLN"
			}
			set newstate_custom $newstate
		} else {
			set idx [get_custom_state_idx [::config::getKey connectas]]
			set newstate_custom $idx
			if { [lindex [StateList get $idx] 2] != "" } {
				set newstate [::MSN::numberToState [lindex [StateList get $idx] 2]]
			}
		}

		if {[::config::getKey protocol] >= 15 } {
			$::roaming GetProfile [list $self setInitialNicknameCB $newstate $newstate_custom]
		} else {
			# Send our PSM to the server because it doesn't know about it!
			::MSN::sendUUXData $newstate

			set_initial_nick

			# Change status after sending the UUX stuff
			ChCustomState $newstate_custom
			send_dock "STATUS" $newstate
		}

	}

	method setInitialNicknameCB { newstate newstate_custom nickname last_modif psm dp fail } {
		if {$fail == 0} {
			status_log "GetProfile : Retrieved nickname from server : $nickname - psm : $psm"
			::MSN::changePSM $psm $newstate 0 1

			set lastchange [::abook::getPersonal info_lastchange]
			set roaming_newer 1
			set roaming_last_modif 0
			set ab_last_modif 0
			if { [regexp {(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})} $last_modif -> y m d h min s] } {
				set roaming_last_modif [clock scan "${y}-${m}-${d} ${h}:${min}:${s}"]
			}

			if { [regexp {(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})} $lastchange -> y m d h min s] } {
				set ab_last_modif [clock scan "${y}-${m}-${d} ${h}:${min}:${s}"]
			}
			status_log "Roaming last modif :$last_modif, AB last modif : $lastchange" 
			if {$nickname != "" } {
				if {[::abook::getPersonal MFN] != ""} {
					if {$nickname != [::abook::getPersonal MFN]} {
						if { $roaming_last_modif > $ab_last_modif } {
							::MSN::changeName $nickname 1
						} else {
							::MSN::changeName [::abook::getPersonal MFN] 1
						}
					} else {
						::MSN::changeName $nickname 0
					}
				} else {
					::MSN::changeName $nickname 1
				}
			} else {
				::MSN::changeName [::abook::getPersonal MFN] 1
			}

			# Change status after sending the UUX stuff
			ChCustomState $newstate_custom
			send_dock "STATUS" $newstate
		} else {
			# Send our PSM to the server because it doesn't know about it!
			::MSN::sendUUXData $newstate

			set_initial_nick

			# Change status after sending the UUX stuff
			ChCustomState $newstate_custom
			send_dock "STATUS" $newstate			
		}
		if {$fail == 3} {
			# ItemDoesNotExist
			$::roaming CreateProfile [list $self RoamingProfileCreated]
		}
	}
	method RoamingProfileCreated { rid fail } {
		if {$rid == "" } {
			set rid [::abook::getPersonal profile_resourceid]
		}
		if {$rid != "" } {
			$::roaming ShareItem [list $self RoamingItemShared] $rid
		}
	}

	method RoamingItemShared { fail } {
		$::ab AddMember [list $self RoamingMemberAdded] RoamingSeed "" ProfileExpression
	}
	method RoamingMemberAdded { fail } {
		$::ab ABContactUpdate [list $self RoamingAnnotationAdded] "" [list contactType Me annotations "<Annotation><Name>MSN.IM.RoamLiveProperties</Name><Value>1</Value></Annotation>"] Annotation
	}
	method RoamingAnnotationAdded { fail } {
		$::roaming UpdateProfile [list ns updateProfileCB] [::abook::getPersonal MFN] [::abook::getPersonal PSM]
	}
}

::snit::type SB {

	delegate option * to connection
	delegate method * to connection
	option -users [list]
	option -typers [list]
	option -lastmsgtime 0
	option -title ""
	option -last_user ""
	option -invite ""
	option -auth_cmd ""
	option -auth_param ""
	option -last_activity 0

	constructor {args} {
		install connection using Connection %AUTO% -name $self
		$self configurelist $args
	}

	destructor {
		catch { $connection destroy }
	}

	method addUser { user } {
		lappend options(-users) $user
	}

	method delUser { idx } {
		set options(-users) [lreplace $options(-users) $idx $idx]
	}

	method addTyper { typer } {
		lappend options(-typers) $typer
	}

	method delTyper { idx } {
		set options(-typers) [lreplace $options(-typers) $idx $idx]
	}

	method handleCommand { command {payload ""}} {
		set command [split $command]
		degt_protocol "<-$self-[$self cget -sock] $command" "sbrecv"
		if { $payload != "" } {
			degt_protocol "Message Contents:\n$payload" "sbrecv"
			set message [Message create %AUTO%]
			$message createFromPayload $payload
		}

		global list_cmdhnd msgacks
		set ret_trid [lindex $command 1]
		set idx [lsearch $list_cmdhnd "$self $ret_trid *"]

		if {$idx != -1} {		;# Command has a handler associated!
			status_log "sb::handleCommand: Evaluating handler for $ret_trid in SB $self\n"
			set cmd "[lindex [lindex $list_cmdhnd $idx] 2] {$command}"
			#status_log "command is $cmd"
			if {[eval $cmd] } {
				set list_cmdhnd [lreplace $list_cmdhnd $idx $idx]				
			}
		} else {
			switch -- [lindex $command 0] {
				MSG {
					$self handleMSG $command $message
				}
				BYE -
				JOI -
				IRO {
					cmsn_update_users $self $command
				}
				CAL {
					#status_log "$self_name: [join $command]\n" green
				}
				ANS {
					status_log "sb::handleCommand: ANS Chat started. [llength [$self cget -users]] users: [$self cget -users]\n" green
					if { [llength [$self cget -users]] == 1 } {
						set chatid [lindex [$self cget -users] 0]
					} else {
						set chatid $self
					}
					::MSN::AddSBFor $chatid $self

					foreach usr_login [$self cget -users] {
						::MSNP2P::loadUserPic $chatid $usr_login
						::amsn::userJoins $chatid $usr_login 0
					}

					#Send x-clientcaps information
					::MSN::clientCaps $chatid
				}
				NAK {
					if { [info exists msgacks($ret_trid)]} {
						set ackid $msgacks($ret_trid)
						::amsn::nackMessage $ackid
						#::MSN::retryMessage $ackid
						unset msgacks($ret_trid)
					}
				}
				ACK {
					if { [info exists msgacks($ret_trid)]} {
						set ackid $msgacks($ret_trid)
						::amsn::ackMessage $ackid
						unset msgacks($ret_trid)
					}
				}
				208 {
					status_log "sb::handleCommand: invalid user name for chat\n" red
					msg_box "[trans invalidusername]"
				}
				"" {
				}
				default {
					if { "[$self cget -stat ]" == "d" } {
						status_log "$self: UNKNOWN SB ENTRY! --> [join $command]\n" red
					}
				}
			}
		}

		catch { set options(-last_activity) [clock seconds] }
	}

	method handleMSG { command message } {

		set p4context [encoding convertfrom identity [$message getHeader P4-Context]]

		set typer [string tolower [lindex $command 1]]
		if { [::config::getKey displayp4context] !=1 || $p4context == "" } {
			set nick [::abook::getDisplayNick $typer]
			set p4c_enabled 0
		} else {
			set nick "[::config::getKey p4contextprefix]$p4context"
			set p4c_enabled 1
		}
		#Notice that we're ignoring the nick sent in the own MSG command, and using the one in ::abook

		set users_list $options(-users)

		#Look what should be our chatID, depending on the number of users
		if { [llength $users_list] == 1 } {
			set desiredchatid $typer
		} else {
			set desiredchatid $self ;#For conferences, use sb_name as chatid
		}

		#Get the current chatid
		set chatid [::MSN::ChatFor $self]

		if { $chatid != 0} {
			if { "$chatid" != "$desiredchatid" } {
				#Our chatid is different than the desired one!! try to change
				status_log "cmsn_sb_msg: Trying to change chatid from $chatid to $desiredchatid for SB $self\n"
				set newchatid [::ChatWindow::Change $chatid $desiredchatid]
				if { "$newchatid" != "$desiredchatid" } {
					#The GUI doesn't accept the change, as there's another window for that chatid
					status_log "cmsn_sb_msg: change NOT accepted\n"
				} else {
					#The GUI accepts the change, so let's change
					status_log "sb_msg: change accepted\n"
					::MSN::DelSBFor $chatid $self
					set chatid $desiredchatid
					::MSN::AddSBFor $chatid $self
				}
			} else {
				#Add it so it's moved to front
				::MSN::AddSBFor $chatid $self
			}
		} else {
			status_log "cmsn_sb_msg: NO chatid in cmsn_sb_msg, please check this!!\n" white
			set chatid $desiredchatid
			::MSN::AddSBFor $chatid $self
		}


		set message_id [$message getHeader Message-ID]
		set chunks [$message getHeader Chunks]
		set current_chunk [$message getHeader Chunk]
		if { $message_id != "" && ($chunks != "" || $current_chunk != "" ) } {
			
			if { $chunks != "" } {
				status_log "chunked message : $chunks chunks - [$message getHeaders]" blue
				set ::MSN::split_messages(${message_id}_total_chunks) $chunks
				set ::MSN::split_messages(${message_id}_got_chunks) 1
				set ::MSN::split_messages(${message_id}_chunk_0) [$message getBody]
				set ::MSN::split_messages(${message_id}_headers) [$message getHeaders]
				set ::MSN::split_messages(${message_id}_fields) [$message getFields]
			} elseif {[info exists ::MSN::split_messages(${message_id}_got_chunks)]} {
				status_log "chunked message : $chunks chunk - [$message getHeaders] - [set ::MSN::split_messages(${message_id}_headers)]" blue
				incr ::MSN::split_messages(${message_id}_got_chunks)
				set ::MSN::split_messages(${message_id}_chunk_${current_chunk}) [$message getBody]
				
				array set headers [set ::MSN::split_messages(${message_id}_headers)]
				array set headers [$message getHeaders]
				set ::MSN::split_messages(${message_id}_headers) [array get headers]
				
				array set fields [set ::MSN::split_messages(${message_id}_fields)]
				array set fields [$message getFields]
				set ::MSN::split_messages(${message_id}_fields) [array get fields]
				
			}

			if {[info exists ::MSN::split_messages(${message_id}_total_chunks)] &&
			    [set ::MSN::split_messages(${message_id}_total_chunks)] == [set ::MSN::split_messages(${message_id}_got_chunks)] } {
				set body ""

				for { set i 0 } { $i < [set ::MSN::split_messages(${message_id}_total_chunks)] } { incr i } {
					append body [set ::MSN::split_messages(${message_id}_chunk_${i})]
					unset ::MSN::split_messages(${message_id}_chunk_${i})
				}

				$message setRaw $body [set ::MSN::split_messages(${message_id}_headers)] [set ::MSN::split_messages(${message_id}_fields)]

				unset ::MSN::split_messages(${message_id}_total_chunks)
				unset ::MSN::split_messages(${message_id}_got_chunks)
				unset ::MSN::split_messages(${message_id}_headers)
				unset ::MSN::split_messages(${message_id}_fields)
			} else {
				# Ignore this message until you get the whole message
				return
			}

					
		}
		set contentType [lindex [split [$message getHeader Content-Type] ";"] 0]

		switch -- $contentType {
			text/plain {
				::Event::fireEvent messageReceived $self $message
				$message setBody [encoding convertfrom identity [string map {"\r\n" "\n"} [$message getBody]]]

				::amsn::messageFrom $chatid $typer $nick $message user $p4c_enabled
				catch {set options(-lastmsgtime) [clock format [clock seconds] -format %H:%M:%S]}
				::abook::setContactData $typer last_msgedme [clock format [clock seconds] -format "%D - %H:%M:%S"]
				#if alarm_onmsg is on run it
				if { ( [::alarms::isEnabled $typer] == 1 )&& ( [::alarms::getAlarmItem $typer onmsg] == 1) } {
					set username [::abook::getDisplayNick $typer]
					run_alarm $typer $typer  $username "[trans says $username]: [$message getBody]"
				} elseif { ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all onmsg] == 1) } {
					set username [::abook::getDisplayNick $typer]
					run_alarm all $typer  $username "[trans says $username]: [$message getBody]"
				}
				global automessage automsgsent
				# Send automessage once to each user
				if { [info exists automessage] } {
					if { $automessage != "-1" && [lindex $automessage 4] != ""} {
						if { [info exists automsgsent($typer)] } {
							if { $automsgsent($typer) != 1 } {
								::amsn::MessageSend [::ChatWindow::For $chatid] 0 [parse_exec [lindex $automessage 4]] "[trans automessage]"
								set automsgsent($typer) 1
							}
						} else {
							::amsn::MessageSend [::ChatWindow::For $chatid] 0 [parse_exec [lindex $automessage 4]] "[trans automessage]"
							set automsgsent($typer) 1
						}
					}
				}
				::MSN::DelSBTyper $self $typer

			}

			text/x-msmsgscontrol {
				set typer_real [string tolower [$message getHeader TypingUser]]
				if { ($typer == $typer_real) || ($typer_real == "") } {
					::MSN::addSBTyper $self $typer
				}
			}

			text/x-msmsgsinvite {
				#File transfers or other invitations
				set fromlogin [lindex $command 1]

				#OK, what happens now is, we have to extract the info from the
				#body, which looks like the MIME header. Therefore, we simply
				#steal the code for extracting the headers, and replace
				#getHeader with array get.

				#The above is no longer true! the message object now has a function,
				#getField, that works just like getHeader, except it gets... you
				#guessed it - a field from the body.

				set invcommand [$message getField Invitation-Command]
				set cookie [$message getField Invitation-Cookie]



				status_log "Command: $invcommand Message: $message\n" blue


				#Do we need this? Looks a bit... untidy
				#puts $invcommand
				#puts $cookie

				if {$invcommand == "INVITE" } {


					#set guid [lindex [array get headers Application-GUID] 1]
					set guid [$message getField Application-GUID]


					#An invitation, generate invitation event
					if { $guid == "{5D3E02AB-6190-11d3-BBBB-00C04F795683}" } {
						#We have a file transfer here
						set filename [$message getField Application-File]
						set filesize [$message getField Application-FileSize]

						::MSNFT::invitationReceived $filename $filesize $cookie $chatid $fromlogin

					} elseif { $guid == "{02D3C01F-BF30-4825-A83A-DE7AF41648AA}" } {
						# We got an audio only invitation or audio/video invitation
						set context [$message getField Context-Data]
						#Remove the # on the next line if you want to test audio/video feature (with Linphone, etc...)
						#Ask Burger for more details..
						SendMessageFIFO [list ::MSNAV::invitationReceived $cookie $context $chatid $fromlogin] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

					}

				} elseif { $invcommand == "ACCEPT" } {
					# let's see if it's an A/V session cancel
					if { [::MSNAV::CookieList get $cookie] != 0 } {
						set ip [$message getField IP-Address]
						::MSNAV::readAccept $cookie $ip $chatid

					} else {


						#Generate "accept" event
						::MSNFT::acceptReceived $cookie $chatid $fromlogin $message
					}

				} elseif { $invcommand =="CANCEL" } {

					# let's see if it's an A/V session cancel
					if { [::MSNAV::CookieList get $cookie] != 0 } {
						::MSNAV::cancelSession $cookie $chatid "TIMEOUT"
					} else {
						# prolly an FT
						set cancelcode [$message getField Cancel-Code]
						if { $cancelcode == "FTTIMEOUT" } {
							::MSNFT::timeoutedFT $cookie
						} elseif { $cancelcode == "REJECT" } {
							::MSNFT::rejectedFT $chatid $fromlogin $cookie
						}
					}

				} else {

					#... other types of commands
				}
			}
			application/x-msnmsgrp2p {
				set dest [$message getHeader "P2P-Dest"]
				if { [string compare -nocase $dest [::config::getKey login]] == 0 } {
					set p2pmessage [P2PMessage create %AUTO%]
					$p2pmessage createFromMessage $message
					::MSNP2P::ReadData $p2pmessage $chatid
					#status_log [$p2pmessage toString 1]
					catch { $p2pmessage destroy }
				}
			}

			text/x-mms-emoticon -
			text/x-mms-animemoticon {
				upvar #0 [string map {: _} ${chatid}]_smileys chatsmileys
				status_log "Got a custom smiley from peer\n" red
				set chatsmileys(dummy) ""
				parse_x_mms_emoticon [$message getBody] $chatid
				status_log "got smileys : [array names chatsmileys]\n" blue
				foreach smile [array names chatsmileys] {
					if { $smile == "dummy" } { continue }
					MSNP2P::loadUserSmiley $chatid $typer "[set chatsmileys($smile)]"
				}
			}

			text/x-clientcaps {
				#Packet we receive from 3rd party client (not by MSN)
				xclientcaps_received $message $typer
			}
			image/gif {
				set body [$message getBody]
				if { [string first "base64:" $body] != -1 } {
					set data [::base64::decode [string range $body 7 end]]
				} else {
					set data $body
				}
				# don't try to display it if the image is considered as invalid
				if { [catch {set img [image create photo [TmpImgName] -data $data]}]} {
					status_log "(protocol.tcl) receiving an invalid gif from $typer" red
				} else {
					SendMessageFIFO [list ::amsn::ShowInk $chatid $typer $nick $img ink $p4c_enabled] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
				}

			}
			text/x-keepalive {
			#kopete sends this to keep the SB open all time when the window is open, every 50 seconds.  Generates a lot of network traffic + handling cpu power for nothing.

				#if we didn't receive any message on this SB, close it
				if {[$self cget -lastmsgtime] == 0} {
					status_log "Closing the SB for an aggresive Kopete user: $chatid" white
					::MSN::CloseSB $self
				}			
			}
			text/x-msnmsgr-datacast {
				set body [$message getBody]
				set lines [split $body "\r\n"]
				
				# We set these because some clients (www.imhaha.com/webmsg/) can send datacast messages without anything in them...
				set key ""
				set value ""

				foreach line $lines {
					foreach {key value} [split $line ":"] break
					if {$key == "ID"} {
						set id $value
					} elseif {$key == "Data"} {
						set data $value
					}
				}

				# Make sure it was a valid datacast packet...
				if { [info exists id] } {
					set evpar(chatid) chatid
					set evpar(typer) typer
					set evpar(nick) nick
					set evpar(msg) message
					set evpar(id) id
					set evpar(data) data
					::plugins::PostEvent DataCastPacketReceived evpar
					
					if { [info exists id] && [info exists data] } {
						if {$id == "3" } {
							::MSNP2P::RequestObjectEx $chatid $typer $data "voice"
						} elseif {$id == "4" } {
							# Action messages... 
							# TODO : find a better way to write the messages ?
							::amsn::WinWrite $chatid "\n" gray
							::amsn::WinWriteIcon $chatid greyline 3
							::amsn::WinWrite $chatid "\n" gray
							::amsn::WinWrite $chatid $data gray
							::amsn::WinWrite $chatid "\n" gray
							::amsn::WinWriteIcon $chatid greyline 3
							::amsn::WinWrite $chatid "\n" gray
						}
					}
				}
			}


			default {
				status_log "$self handleMSG: === UNKNOWN MSG ===\n$command\n[$message getHeaders]\n[$message getBody]" red
				#Postevent for others kinds of packet (like nudge)
				set evpar(chatid) chatid
				set evpar(typer) typer
				set evpar(nick) nick
				set evpar(msg) message
				::plugins::PostEvent PacketReceived evpar
			}
		}
		$message destroy
	}

	method search { option index } {
		return [lsearch $options($option) $index]
	}
}


# parse_exec(text)
#
# Split the specified text in lines then replace shell commands by their
# output. A line will be interpreted as a shell command if its first
# character is a pipe. When such a line is found, the text up to the end
# of line is passed to the shell to be executed and its output inserted
# in place.
proc parse_exec {text} {
	foreach line [split $text "\n"] {
		if {[string index $line 0] == "|"} {
			set cmd [string range $line 1 [string length $line]]
			if { [OnUnix] } {
				catch {exec /bin/sh -c $cmd} output
			} elseif { [OnWin] } {
				catch {exec "c:\\windows\\system32\\cmd.exe" /c $cmd} output
			}
			append outtext "$output\n"
		} else {
			append outtext "$line\n"
		}
	}
	return [string trimright $outtext "\n"]
}

proc cmsn_invite_user {sb user} {

	if { ("[$sb cget -stat]" == "o") \
		|| ("[$sb cget -stat]" == "n") \
		|| ("[$sb cget -stat]" == "i")} {

		::MSN::WriteSB $sb "CAL" $user "::MSN::CALReceived $sb $user"

	} else {

		status_log "cmsn_invite_user: Can't invite user to non connected SB!!\n" red

	}

}


proc cmsn_rng {recv} {

	global sb_list

	set email [string tolower [lindex $recv 5]]
	if {[::abook::getContactData $email ignored 0] != 0} { return 0 }

	set sb [::MSN::GetNewSB]

	#Init SB properly
	if { [config::getKey protocol] == 11 ||
	     ([config::getKey protocol] >= 13 && [lindex $recv 9] == "1") } {
		$sb configure -force_gateway_server [lindex [split [lindex $recv 2] ":"]]
	}
	set auth_username [::config::getKey login]
	if {[::config::getKey protocol] >= 16 } {
		append auth_username ";[::config::getGlobalKey machineguid]"
	}
	$sb configure -stat ""
	$sb configure -server [split [lindex $recv 2] ":"]
	$sb configure -connected [list cmsn_conn_ans $sb]
	$sb configure -auth_cmd "ANS"
	$sb configure -auth_param "$auth_username [lindex $recv 4] [lindex $recv 1]"

	lappend sb_list "$sb"

	status_log "Accepting conversation from: [lindex $recv 5]... (Got ANS1 in SB $sb\n" green

	setup_connection $sb
	cmsn_socket $sb
	return 0
}

proc cmsn_open_sb {sb recv} {

	#if the sb doesn't exist return
	if {[catch {$sb cget -name}]} {
		return 1
	}

	#TODO: I hope this works. If stat is not "c" (trying to connect), ignore
	if { [$sb cget -stat] != "c" } {
		return 1
	}

	if {[lindex $recv 0] == "913"} {
		#Not allowed when offline
		set chatid [::MSN::ChatFor $sb]
		::MSN::ClearQueue $chatid
		::MSN::CleanChat $chatid
		::amsn::chatStatus $chatid "[trans needonline]\n" miniwarning
		#msg_box "[trans needonline]"
		return 1
	}

	if {[lindex $recv 4] != "CKI"} {
		status_log "cmsn_open_sb: SB $sb: Unknown SP requested!\n" red
		return 1
	}

	status_log "cmsn_open_sb: Opening SB $sb\n" green

	if { [config::getKey protocol] == 11 ||
	     ([config::getKey protocol] >= 13 && [lindex $recv 8] == "1") } {
		$sb configure -force_gateway_server [lindex [split [lindex $recv 3] ":"]]
	}
	set auth_username [::config::getKey login]
	if {[::config::getKey protocol] >= 16 } {
		append auth_username ";[::config::getGlobalKey machineguid]"
	}
	$sb configure -server [split [lindex $recv 3] ":"]
	$sb configure -connected [list cmsn_conn_sb $sb]
	$sb configure -auth_cmd "USR"
	$sb configure -auth_param "$auth_username [lindex $recv 5]"


	::amsn::chatStatus [::MSN::ChatFor $sb] "[trans sbcon]...\n" miniinfo ready
	setup_connection $sb
	cmsn_socket $sb
	return 1
}



proc cmsn_conn_sb {sb sock} {

	catch { fileevent $sock writable "" } res

	#Reset timeout timer
	$sb configure -time [clock seconds]

	$sb configure -stat "a"

	set cmd [$sb cget -auth_cmd]
	set param [$sb cget -auth_param]

	::MSN::WriteSB $sb $cmd $param "cmsn_auth_sb $sb"

	::amsn::chatStatus [::MSN::ChatFor $sb] "[trans ident]...\n" miniinfo ready

}

proc cmsn_auth_sb { sb recv } {
	set cmd [lindex $recv 0]
	
	if { $cmd == [$sb cget -auth_cmd] } {
		#We got a valid response
		cmsn_connected_sb $sb $recv
	} else {
		switch -- $cmd {
			911 {
				#Authentication failed, server will disconnect us.
				status_log "cmsn_auth_sb: SB authentication failed for $sb, reconnecting..." red
				$sb configure -stat "af"
				cmsn_reconnect $sb
			}
			
			default {
				status_log "cmsn_auth_sb: unknown server reply on $sb: $recv" red
				cmsn_reconnect $sb
			}
		}
	}
	return 1
}

proc cmsn_conn_ans {sb sock} {

	#status_log "cmsn_conn_ans: Connected to invitation SB $name...\n" green

	catch {fileevent $sock writable {}} res

	$sb configure -time [clock seconds]
	$sb configure -stat "a"

	set cmd [$sb cget -auth_cmd]
	set param [$sb cget -auth_param]
	::MSN::WriteSB $sb $cmd $param

	#status_log "cmsn_conn_ans: Authenticating in $name...\n" green

}


proc cmsn_connected_sb {sb recv} {

	#status_log "cmsn_connected_sb: SB $name connected\n" green

	$sb configure -time [clock seconds]
	$sb configure -stat "i"

set invite [$sb cget -invite]

	if {$invite != ""} {
		cmsn_invite_user $sb $invite
		::amsn::chatStatus [::MSN::ChatFor $sb] "[trans willjoin $invite]...\n" miniinfo ready
	} else {
		status_log "cmsn_connected_sb: got SB $sb stat=i but no one to invite!!! CHECK!!\n" white
	}

}

#SB stat values:
#  "d" - Disconnected, the SB is not connected to the server
#  "c" - The SB is going to get a socket to connect to the server.
#  "cw" - "Connect wait" The SB is trying to connect to the server.
#  "a" - Authenticating. The SB is authenticating to the server.
#  "af" - Authentication failed.
#  "i" - Inviting first person to the chat. Successive invitations will be while in "o" status
#  "o" - Opened. The SB is connected and ready for chat
#  "n" - Nobody. The SB is connected but there's nobody at the conversation


proc cmsn_reconnect { sb } {
	switch -- [$sb cget -stat] {
		"n" {

			status_log "cmsn_reconnect: stat = n , SB= $sb, user=[$sb cget -last_user]\n" green

			$sb configure -time [clock seconds]
			$sb configure -stat "i"

			cmsn_invite_user $sb [$sb cget -last_user]

			::amsn::chatStatus [::MSN::ChatFor $sb] \
				"[trans willjoin [$sb cget -last_user]]..." miniinfo ready

		}

		"d" {

			status_log "cmsn_reconnect: stat = d , SB= $sb, user=[$sb cget -last_user]\n" green

			$sb configure -time [clock seconds]

			catch {[$sb cget -proxy] finish $sb}
			$sb configure -sock ""
			#$sb configure -data [list]
			$sb configure -users [list]
			$sb configure -typers [list]
			$sb configure -title [trans chat]
			$sb configure -lastmsgtime 0

			$sb configure -stat "c"
			$sb configure -invite [$sb cget -last_user]

			if { [ns cget -stat] != "o" } {
				set chatid [::MSN::ChatFor $sb]
				::MSN::ClearQueue $chatid
				::MSN::CleanChat $chatid
				::amsn::chatStatus $chatid "[trans needonline]\n" miniwarning
				return
			}

			::MSN::WriteSB ns "XFR" "SB" "cmsn_open_sb $sb"
			::amsn::chatStatus [::MSN::ChatFor $sb] "[trans chatreq]..." miniinfo ready

		}

		"i" {

			#status_log "cmsn_reconnect: stat = i , SB= $sb\n" green

			if { ([clock seconds] - [$sb cget -time]) > 15 } {
				status_log "cmsn_reconnect: called again while inviting timeouted for sb $sb\n" red
				set proxy [$sb cget -proxy]
				$proxy finish $sb
				$sb configure -stat "d"
				cmsn_reconnect $sb
			}

		}

		"c" {

			#status_log "cmsn_reconnect: stat = c , SB= $sb\n" green

			if { ([clock seconds] - [$sb cget -time]) > 10 } {
				status_log "cmsn_reconnect: called again while reconnect timeouted for sb $sb\n" red
				#set command [list "::[$name cget -connection_wrapper]::finish" $name]
				#eval $command
				$sb configure -stat "d"
				cmsn_reconnect $sb
			}

		}

		"cw" -
		"pw" -
		"a" {

			#status_log "cmsn_reconnect: stat = \"[$sb cget -stat]\" , SB= $sb\n" green

			if { ([clock seconds] - [$sb cget -time]) > 10 } {
				status_log "cmsn_reconnect: called again while authentication timeouted for sb $sb\n" red
				set proxy [$sb cget -proxy]
				$proxy finish $sb
				$sb configure -stat "d"
				cmsn_reconnect $sb
			}
		}
		
		"af" {
			#status_log "cmsn_reconnect: stat = af , SB= $sb\n" green
			set proxy [$sb cget -proxy]
			$proxy finish $sb
			$sb configure -stat "d"
			cmsn_reconnect $sb			
		}
		
		"" {
			status_log "cmsn_reconnect: SB $sb stat is \"\". This is bad, should delete it and create a new one\n" red
			catch {
				set chatid [::MSN::ChatFor $sb]
				::MSN::DelSBFor $chatid $sb
				::MSN::KillSB $sb
				::MSN::chatTo $chatid
			}

		}
		default {
			status_log "cmsn_reconnect: SB $sb stat is [$sb cget -stat]\n" red
		}
	}

}





#///////////////////////////////////////////////////////////////////////
proc cmsn_update_users {sb recv} {

	switch -- [lindex $recv 0] {

		BYE {

			set chatid [::MSN::ChatFor $sb]


			set leaves [$sb search -users "[lindex $recv 1]"]

			# Ignore double BYEs for protocol MSNP16
			if {$leaves == -1 } {
				return 0
			}

			$sb configure -last_user [lindex [$sb cget -users] $leaves]
			$sb delUser $leaves


			set usr_login [lindex [$sb cget -users] 0]

			if { [llength [$sb cget -users]] > 1 } {
				::ChatWindow::TopUpdate $chatid
			}

			if { [llength [$sb cget -users]] == 1 } {
				#We were a conference! try to become a private

				set desiredchatid $usr_login

				set newchatid [::ChatWindow::Change $chatid $desiredchatid]

				if { "$newchatid" != "$desiredchatid" } {
					#The GUI doesn't accept the change, as there's another window for that chatid
					status_log "cmsn_update_users: change NOT accepted from $chatid to $desiredchatid\n"
					#We will close the conference window and return to the previous
					set oldwindow [::ChatWindow::For $desiredchatid]
					set container [::ChatWindow::GetContainerFromWindow $oldwindow]
					if { $container != "" } {
						::ChatWindow::SwitchToTab $container $oldwindow
						raise $container
					} else {
						raise $oldwindow
					}
					
					set newwindow [::ChatWindow::For $chatid]
					set container [::ChatWindow::GetContainerFromWindow $newwindow]
					if { $container != "" } {
						set tab [set ::ChatWindow::win2tab($newwindow)]
						::ChatWindow::CloseTab $tab
					} else {
						::ChatWindow::Close $newwindow
					}
				} else {
					#The GUI accepts the change, so let's change
					status_log "cmsn_update_users: change accepted from $chatid to $desiredchatid\n"

					::MSN::DelSBFor $chatid $sb
					::MSN::AddSBFor $newchatid $sb



					set chatid $newchatid

					::ChatWindow::TopUpdate $chatid


				}

			} elseif { [llength [$sb cget -users]] == 0 && [$sb cget -stat] != "d" } {
				$sb configure -stat "n"
			}

			#Another option for the condition:
			# "$chatid" != "[lindex $recv 1]" || ![MSN::chatReady $chatid]
			if { [::MSN::SBFor $chatid] == $sb } {
				# the last argument to userLeaves means :
				# 0 : closed for inactivity
				# 1 : user leaves conversation
				if { [lindex $recv 2] == "1" || 
				     ([expr [clock seconds] - [$sb cget -last_activity]] > 50 &&
				      [expr [clock seconds] - [$sb cget -last_activity]] < 90)} {
					::amsn::userLeaves $chatid [list [lindex $recv 1]] 0
				} else {					
					::amsn::userLeaves $chatid [list [lindex $recv 1]] 1
				}
			}
			if { [::ChatWindow::For $chatid] == 0 } {
				::MSN::DelSBFor $chatid $sb
				::MSN::KillSB $sb
			}

		}

		IRO {

			#You get an IRO message when you're invited to some chat. The chatid name won't be known
			#until the first message comes
			$sb configure -stat "o"

			set usr_login [string tolower [lindex $recv 4]]
			set usr_name [urldecode [lindex $recv 5]]
			
			# Ignore our own user when on MSNP16
			# And ignore duplicate users
			if {[config::getKey protocol] >= 16 } {
				foreach {usr_login machineguid} [split $usr_login ";"] break
				if {$usr_login == [::config::getKey login] ||
				    [$sb search -users $usr_login] >= 0} {
					return 0
				}
			}

			$sb addUser [list $usr_login]

			::abook::setContactData $usr_login nick $usr_name

			$sb configure -last_user $usr_login

			if {[config::getKey protocol] >= 15 } {
				set clientid [lindex $recv 6]
				if {[config::getKey protocol] >= 16 } {
					set clientid [lindex [split $clientid ":"] 0]
				}
				add_Clientid $usr_login $clientid
			}

		}

		JOI {
			$sb configure -stat "o"

			set usr_login [string tolower [lindex $recv 1]]
			set usr_name [urldecode [lindex $recv 2]]

			# Ignore our own user when on MSNP16
			# And ignore duplicate users
			if {[config::getKey protocol] >= 16 } {
				foreach {usr_login machineguid} [split $usr_login ";"] break
				if {$usr_login == [::config::getKey login] ||
				    [$sb search -users $usr_login] >= 0} {
					return 0
				}
			}

			$sb addUser [list $usr_login]

			::abook::setContactData $usr_login nick $usr_name

			if {[config::getKey protocol] >= 15 } {
				set clientid [lindex $recv 3]
				if {[config::getKey protocol] >= 16 } {
					set clientid [lindex [split $clientid ":"] 0]
				}
				add_Clientid $usr_login $clientid
			}

			if { [llength [$sb cget -users]] == 1 } {

				$sb configure -last_user $usr_login
				set chatid $usr_login
				::ChatWindow::TopUpdate $chatid

			} else {

				#More than 1 user, change into conference

				#Procedure to change chatid-sb correspondences
				set oldchatid [::MSN::ChatFor $sb]

				if { $oldchatid == 0 } {
					status_log "cmsn_update_users: JOI - VERY BAD ERROR, oldchatid = 0. CHECK!!\n" white
					return 0
				}

				set chatid $sb

				#Remove old chatid correspondence
				::MSN::DelSBFor $oldchatid $sb
				::MSN::AddSBFor $chatid $sb

				status_log "cmsn_update_users: JOI - Another user joins, Now I'm chatid $chatid (I was $oldchatid)\n"

				::ChatWindow::Change $oldchatid $chatid

				::ChatWindow::TopUpdate $chatid

			}

			#Don't put it in status if we're not the preferred SB.
			#It can happen that you invite a user to your sb,
			#but just in that moment the user invites you,
			#so you will connect to its sb and be able to chat, but after
			#a while the user will join your old invitation,
			#and get a fake "user joins" message if we don't check it
			::MSNP2P::loadUserPic $chatid $usr_login
			#Send x-clientcaps information
			::MSN::clientCaps $chatid

			if {[::MSN::SBFor $chatid] == $sb} {
				::amsn::userJoins $chatid $usr_login 0
			}
		}
	}

}
#///////////////////////////////////////////////////////////////////////


#TODO: ::abook system
proc cmsn_change_state {recv} {
	global remote_auth HOME

	if {[lindex $recv 0] == "FLN"} {
		#User is going offline
		set user [lindex $recv 1]
		set evpar(user) user

		if {[::config::getKey protocol] >= 14} {
			set network  [lindex $recv 2]
		} 
		set user_name ""
		set substate "FLN"
		set evpar(substate) substate
		set msnobj [::abook::getVolatileData $user msnobj ""]
#		status_log "contactStateChange in protocol cmsn_change_state FLN"
	} elseif {[lindex $recv 0] == "ILN"} {
		#Initial status when we log in
		set substate [lindex $recv 2]
		set user [lindex $recv 3]

		set idx 4
		if {[::config::getKey protocol] >= 14} {
			set network  [lindex $recv 4]
			incr idx
		} 
		set encoded_user_name [lindex $recv $idx]
		set user_name [urldecode [lindex $recv $idx]]
		incr idx
		#Add clientID to abook
		set clientid [lindex $recv $idx]
		if {[::config::getKey protocol] >= 16} {
			set clientid [lindex [split $clientid ":"] 0]
		}
		add_Clientid $user  $clientid
		incr idx
		set msnobj [urldecode [lindex $recv $idx]]
		incr idx
		if {[::config::getKey protocol] >= 16} {
			set unknown_machineguid [lindex $recv $idx]
		}
		#Previous clientname info is now inaccurate
		::abook::setContactData $user clientname ""
	} else {
		#Coming online or changing state
		set substate [lindex $recv 1]
		set evpar(substate) substate
		set user [lindex $recv 2]
		set evpar(user) user

		set idx 3
		if {[::config::getKey protocol] >= 14} {
			set network  [lindex $recv 3]
			incr idx
		} 
		set encoded_user_name [lindex $recv $idx]
		set user_name [urldecode [lindex $recv $idx]]
		incr idx
		#Add clientID to abook
		set clientid [lindex $recv $idx]
		if {[::config::getKey protocol] >= 16} {
			set clientid [lindex [split $clientid ":"] 0]
		}
		add_Clientid $user $clientid
		incr idx
		set msnobj [urldecode [lindex $recv $idx]]
		incr idx
		if {[::config::getKey protocol] >= 16} {
			set unknown_machineguid [lindex $recv $idx]
		}
#		status_log "contactStateChange in protocol cmsn_change_state $user"
	}

	set oldstate [::abook::getVolatileData $user state]
	if { $oldstate != $substate } {
		set state_changed 1
	} else {
		set state_changed 0
	}

	if { $msnobj == "" } {
		set msnobj -1
	}

	if {$user_name == ""} {
		set user_name [::abook::getContactData $user nick]
		set nick_changed 0
	} elseif {$user_name != [::abook::getContactData $user nick]} {
		#Nick differs from the one on our list, so change it
		#in the server list too
		::abook::setContactData $user nick $user_name

		#an event used by guicontactlist to know when we changed our nick
		::Event::fireEvent contactNickChange protocol $user

		set nick_changed 1

		if {[config::getKey protocol] < 13} {
			# This check below is because today I received a NLN for a user 
			# who doesn't appear in ANY of my 5 MSN lists (RL,AL,BL,FL,PL)
			# so amsn just sent the SBP with an empty string for the contactguid, 
			# which resulted in a wrongly formed SBP, which resulted in the msn server disconnecting me... :@
			if { [::abook::getContactData $user contactguid] != "" } {
				::MSN::WriteSB ns "SBP" "[::abook::getContactData $user contactguid] MFN [urlencode $user_name]"
			}
		} else {
			# Update the contact's nickname in the server's abook as well
			if { [::abook::getContactData $user contactguid] != "" } {
				$::ab ABContactUpdate [list ::MSN::ABUpdateNicknameCB] $user [list displayName [xmlencode $user_name]] DisplayName
			}
		}

		::log::eventnick $user $user_name
	} else {
		set nick_changed 0
	}

	set custom_user_name [::abook::getDisplayNick $user]


	if {[lindex $recv 0] != "ILN" && $state_changed} {

		::plugins::PostEvent ChangeState evpar

		#alarm system (that must replace the one that was before) - KNO
		if {[lindex $recv 0] == "FLN"} {
			#User disconnected

			if {  ( [::alarms::isEnabled $user] == 1 )&& ( [::alarms::getAlarmItem $user ondisconnect] == 1) } {
				run_alarm $user $user $custom_user_name [trans disconnect $custom_user_name]
			} elseif {  ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all ondisconnect] == 1) } {
				run_alarm all $user $custom_user_name [trans disconnect $custom_user_name]
			}

		} else {
			set status "[trans [::MSN::stateToDescription $substate]]"
			if { ( [::alarms::isEnabled $user] == 1 )&& ( [::alarms::getAlarmItem $user onstatus] == 1) } {
				run_alarm $user $user $custom_user_name "[trans changestate $custom_user_name $status]"
			} elseif { ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all onstatus] == 1)} {
				run_alarm all $user $custom_user_name "[trans changestate $custom_user_name $status]"
			}
		}
		#end of alarm system
	}

	# Write remote the nick change if the state didn't change
	if {$remote_auth == 1 && $nick_changed && !$state_changed && 
	    $substate != "FLN" && [::abook::getVolatileData $user state FLN] != "FLN" && [lindex $recv 0] != "ILN"  } {
		set nameToWriteRemote "$user_name ($user)"
		write_remote "** [trans changestate $nameToWriteRemote [trans [::MSN::stateToDescription $substate]]]" event
	}


	if {$state_changed } {

		#an event used by guicontactlist to know when a contact changed state
		after 500 [list ::Event::fireEvent contactStateChange protocol $user]

		set maxw [expr {([::skin::getKey notifwidth]-53)*2} ]
		set font [::skin::getKey notify_font]
		set short_name [trunc_list "[::abook::getDisplayNick $user 1]" . $maxw $font]

		#User logsout
		if {$substate == "FLN"} {
			#Register last logout, last seen and notify it in the events
			::abook::setAtomicContactData $user [list last_logout last_seen] \
			    [list [clock format [clock seconds] -format "%D - %H:%M:%S"] [clock format [clock seconds] -format "%D - %H:%M:%S"]]
			::log::event disconnect $custom_user_name


			# Added by Yoda-BZH
			if {$remote_auth == 1} {
				set nameToWriteRemote "$user_name ($user)"
				write_remote "** $nameToWriteRemote [trans logsout]" event
			}

			if { (([::config::getKey notifyoffline] == 1 && 
			       [::abook::getContactData $user notifyoffline -1] != 0) ||
			      [::abook::getContactData $user notifyoffline -1] == 1) &&
			     ([::config::getKey no_blocked_notif 0] == 0 || ![::MSN::userIsBlocked $user])} {
				#Show notify window if globally enabled, and not locally disabled, or if just locally enabled
				set msg $short_name
				lappend msg [list "newline"]
				lappend msg [list "text" "[trans logsout]."]
				::amsn::notifyAdd $msg "" offline offline $user 1
			}

			# User was online before, so it's just a status change, and it's not
			# an initial state notification
		} elseif {[::abook::getVolatileData $user state FLN] != "FLN" && [lindex $recv 0] != "ILN"  } {

			#Notify in the events
			::log::event state $custom_user_name [::MSN::stateToDescription $substate]

			# Added by Yoda-BZH
			if {$remote_auth == 1} {
				set nameToWriteRemote "$user_name ($user)"
				write_remote "** [trans changestate $nameToWriteRemote [trans [::MSN::stateToDescription $substate]]]" event
			}

			if { (([::config::getKey notifystate] == 1 && 
			       [::abook::getContactData $user notifystatus -1] != 0) ||
			      [::abook::getContactData $user notifystatus -1] == 1)  &&
			     ([::config::getKey no_blocked_notif 0] == 0 || ![::MSN::userIsBlocked $user])} {

				set msg $short_name
				lappend msg [list "newline"]
				lappend msg [list "text" "[trans statechange]"]
				lappend msg [list "newline"]
				lappend msg [list "text" "[trans [::MSN::stateToDescription $substate]]."]
				::amsn::notifyAdd $msg "::amsn::chatUser $user" state state $user 1
			}

		} elseif {[lindex $recv 0] == "NLN"} {	;# User was offline, now online

			#Register last login and notify it in the events
			::abook::setContactData $user last_login [clock format [clock seconds] -format "%D - %H:%M:%S"]
			::log::event connect $custom_user_name
			::abook::setVolatileData $user PSM ""
			#Register PostEvent "UserConnect" for Plugins, email = email user_name=custom nick
			set evPar(user) user
			set evPar(user_name) custom_user_name
			#Reset clientname, if it's not M$N it will set it again
			#later on with x-clientcaps
			::abook::setContactData $user clientname ""
			::plugins::PostEvent UserConnect evPar

			# Added by Yoda-BZH
			if {$remote_auth == 1} {
				set nameToWriteRemote "$user_name ($user)"
				write_remote "** $nameToWriteRemote [trans logsin]" event
			}

			if { (([::config::getKey notifyonline] == 1 && 
			       [::abook::getContactData $user notifyonline -1] != 0) ||
			      [::abook::getContactData $user notifyonline -1] == 1) &&
			     ([::config::getKey no_blocked_notif 0] == 0 || ![::MSN::userIsBlocked $user]) } {

				set msg $short_name
				lappend msg [list "newline"]
				lappend msg [list "text" "[trans logsin]."]
				::amsn::notifyAdd $msg "::amsn::chatUser $user" online online $user 1
			}

			if {  ( [::alarms::isEnabled $user] == 1 )&& ( [::alarms::getAlarmItem $user onconnect] == 1)} {
				run_alarm $user $user $custom_user_name "$custom_user_name [trans logsin]"
			} elseif {  ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all onstatus] == 1)} {
				run_alarm all $user $custom_user_name "$custom_user_name [trans logsin]"
			}
			
		}
	}

	# Retreive the new display picture if it changed
#	set oldmsnobj [::abook::getVolatileData $user msobj]
	#set list_users [lreplace $list_users $idx $idx [list $user $user_name $state_no $msnobj]]

	if {$state_changed} {
		::abook::setVolatileData $user state $substate
	}
	::abook::setVolatileData $user msnobj $msnobj
	set oldPic [::abook::getContactData $user displaypicfile]
	set newPic [::MSNP2P::GetFilenameFromMSNOBJ $msnobj]

	if { $oldPic != $newPic && $user != [::config::getKey login] } {
		::abook::setContactData $user displaypicfile $newPic

		if { $newPic == "" } {
			::skin::getDisplayPicture $user 1
		} else {
			status_log "picture changed for user $user\n" white

			if { [file readable "[file join $HOME displaypic cache $user ${newPic}].png"] } {
				#it's possible that the user set again a DP that we already have in our cache so just load it again, even if we are HDN, or the user is blocked.
				::MSNP2P::loadUserPic "" $user
			} elseif { [::MSN::myStatusIs] != "FLN" && [::MSN::myStatusIs] != "HDN" &&
				   ![::config::getKey lazypicretrieval] && ![::MSN::userIsBlocked $user]} {
				set chat_id [::MSN::chatTo $user]
				::MSN::ChatQueue $chat_id [list ::MSNP2P::loadUserPic $chat_id $user]
			} else {
				global sb_list

				foreach sb $sb_list {
					set users_in_chat [$sb cget -users]
					if { [lsearch $users_in_chat $user] != -1 } {
						status_log "User changed image while image in use!! Updating!!\n" white
						::MSNP2P::loadUserPic [::MSN::ChatFor $sb] $user
						break
					}
				}	
			}
		}
	}
	

	if { $state_changed || $nick_changed } {
		::MSN::contactListChanged

		foreach chat_id [::ChatWindow::getAllChatIds] {
			if { $chat_id == $user } {
				::ChatWindow::TopUpdate $chat_id
			} else {
				foreach user_in_chat [::MSN::usersInChat $chat_id] {
					if { $user_in_chat == $user } {
						::ChatWindow::TopUpdate $chat_id
						break
					}
				}
			}
		}
	}
}


proc cmsn_ns_handler {item {message ""}} {
	global password

	switch -- [lindex $item 0] {
		MSG {
			cmsn_ns_msg $item $message
			$message destroy
			return 0
		}
		IPG {
			::MSNMobile::MessageReceived "$message"
			return 0
			}
		VER -
		INF -
		CVR -
		USR {
			return [cmsn_auth $item]
		}
		XFR {
			if {[lindex $item 2] == "NS"} {
				::config::setKey start_ns_server [lindex $item 3]
				set tmp_ns [split [lindex $item 3] ":"]
				ns configure -server $tmp_ns
				status_log "cmsn_ns_handler: got a NS transfer, reconnecting to [lindex $tmp_ns 0]!\n" green
				cmsn_ns_connect [::config::getKey login] $password nosigin
				set recon 1
				return 0
			} else {
				status_log "cmsn_ns_handler: got an unknown transfer!!\n" red
				return 0
			}
		}
		RNG {
			return [cmsn_rng $item]
		}
		UUX {
			::MSN::GotUUXResponse $item
			return 0
		}
		ADC {
			::MSN::GotADCResponse $item
			return 0
		}
		REM {
			::MSN::GotREMResponse $item
			return 0
		}
		FLN -
		ILN -
		NLN {
			if {[::config::getKey protocol] >= 16 &&
			    [lindex $item 2] == [::config::getKey login] &&
			    [lindex $item 0] == "NLN" &&
			    [lindex $item 1] != "IDL" } {
				::abook::setPersonal MFN [urldecode [lindex $item 4]]

				::MSN::setMyStatus [lindex $item 1]
				cmsn_draw_online 1 1
				#Alert dock of status change
				send_dock "STATUS" [lindex $item 1]
			}
			cmsn_change_state $item
			return 0
		}
		CHG {
			if { [::MSN::myStatusIs] != [lindex $item 2] } {
				::abook::setVolatileData myself msnobj [lindex $item 4]
				::MSN::setMyStatus [lindex $item 2]

				cmsn_draw_online 1 1

				#Alert dock of status change
				send_dock "STATUS" [lindex $item 2]

				# If we had a new clientid change between the time we sent the CHG and
				# the time we received the answer (in case we were FLN before),
				# that new clientid will never get known, so we need to resend our
				# status with new clientid (happens if farsight takes a long time to
				# timeout the STUN discovery)
				set clientid [lindex $item 3]
				if {[::config::getKey protocol] >= 16} {
					set clientid [lindex [split $clientid ":"] 0]
				}

				if { [::config::getKey clientid 0] != $clientid } {
					::MSN::changeStatus [::MSN::myStatusIs]
				}
			}
			return 0
		}
		GTC {
			#TODO: How we store this privacy information??
			return 0
		}
		SYN {
			
			global loading_list_info

			::MSN::clearList FL
			::MSN::clearList BL
			::MSN::clearList RL
			::MSN::clearList AL
			::MSN::clearList PL
			::MSN::clearList EL

			new_contact_list "[lindex $item 2]" "[lindex $item 3]"
			if { [llength $item] == 6 } {
				status_log "Going to receive contact list\n" blue
				#First contact in list
				::groups::Reset
				::groups::Set 0 [trans nogroup]

				foreach username [::abook::getAllContacts] {
					#Remove user from all lists while receiving List data
					::abook::setContactData $username lists ""
				}

				set loading_list_info(cl_version) [lindex $item 2]
				set loading_list_info(list_version) [lindex $item 3]
				set loading_list_info(total) [lindex $item 4]
				set loading_list_info(current) 0
				set loading_list_info(gcurrent) 0
				set loading_list_info(gtotal) [lindex $item 5]

				# Check if there are no users and no groups, then we already finished authentification
				if {$loading_list_info(gtotal) == 0 && $loading_list_info(total) == 0} {
					ns setInitialStatus
					ns authenticationDone
				}
			} else {
				::MSN::makeLists
				foreach username [::MSN::getList "FL"] {
					::abook::setVolatileData $username state "FLN"
				}
				ns setInitialStatus
				ns authenticationDone
			}
			return 0
		}
		BLP {
			change_BLP_settings "[lindex $item 1]"
			return 0
		}
		CHL {
			status_log "Challenge received, answering\n" green
			::MSN::AnswerChallenge $item
			return 0
		}
		QRY {
			status_log "Challenge accepted\n" green
			return 0
		}
		BPR {
			global loading_list_info

			if { [string length [lindex $item 1]] == 3 } {
				set var [lindex $item 1]
				set value [urldecode [lindex $item 2]]
				if {[string first "tel:" $value] == 0} {
					set value [string range $value [string length "tel:"] end]
				}
				::abook::setContactData $loading_list_info(last) $var $value
			} else {
				#here the first element is the addres of the user, this is when it's not received on login.
				set var [lindex $item 2]
				set value [urldecode [lindex $item 3]]
				::abook::setContactData [lindex $item 1] $var $value
			}
			return 0
		}
		REG {	# Rename Group
			#status_log "$item\n" blue
			::groups::RenameCB [lrange $item 0 5]

			return 0
		}
		ADG {	# Add Group
			#status_log "$item\n" blue
			::groups::AddCB [lrange $item 0 5]

			return 0
		}
		RMG {	# Remove Group
			#status_log "$item\n" blue
			::groups::DeleteCB [lrange $item 0 5]

			return 0
		}
		OUT {
			if { [lindex $item 1] == "OTH"} {
				::MSN::logout
				msg_box "[trans loggedotherlocation]"
				status_log "Logged other location\n" red
				return 0
			} else {
				::config::setKey start_ns_server [::config::getKey default_ns_server]
				if { [::config::getKey reconnect] == 1 } {
					::MSN::saveOldStatus
					::MSN::logout
					::MSN::reconnect "[trans servergoingdown]"
				} else {
					::MSN::logout
					msg_box "[trans servergoingdown]"
				}
				return 0
			}
		}

		URL {
			::hotmail::gotURL [lindex $item 2] [lindex $item 3] [lindex $item 4]
			return
		}

		QNG {
			#Ping response
			variable ::MSN::pollstatus 0
			return 0
		}
		GCF {
			catch {
				set xml [xml2list [$message getBody]]
				set i 0
				while {1} {
					if {[config::getKey protocol] >= 15} {
						set subxml [GetXmlNode $xml "Policies:Policy:config:block:regexp:imtext" $i]
					} else { 
						set subxml [GetXmlNode $xml "config:block:regexp:imtext" $i]
					}
				
					incr i
					if {$subxml == "" } {
						break
					}
					status_log "Found new censored regexp : [base64::decode [GetXmlAttribute $subxml imtext value]]"
				}
			}
			return 0
		}
		200 {
			status_log "Error: Syntax error\n" red
			msg_box "[trans syntaxerror]"
			return 0
		}
		201 {
			status_log "Error: Invalid parameter\n" red
			msg_box "[trans invalidparameter]"
			return 0
		}
		205 {
			status_log "Warning: Invalid user $item\n" red
			msg_box "[trans contactdoesnotexist]"
			return 0
		}
		206 {
			status_log "Warning: Domain name missing $item\n" red
			msg_box "[trans contactdoesnotexist]"
			return 0
		}
		208 {
			status_log "Warning: Invalid username $item\n" red
			msg_box "[trans invalidusername]"
			return 0
		}
		209 {
			status_log "Warning: Invalid username $item\n" red
			#msg_box "[trans invalidusername]"
			return 0
		}
		210 {
			msg_box "[trans fullcontactlist]"
			status_log "Warning: User list full $item\n" red
			return 0
		}
		216 {
			#status_log "Keeping connection alive\n" blue
			return 0
		}
		224 {
			#status_log "Warning: Invalid group" red
			msg_box "[trans invalidgroup]"
		}
		500 {
			::config::setKey start_ns_server [::config::getKey default_ns_server]
			if { [::config::getKey reconnect] == 1 } {
				::MSN::saveOldStatus
				::MSN::logout
				::MSN::reconnect "[trans internalerror]"
			} else {
				::MSN::logout
				::amsn::errorMsg "[trans internalerror]"
			}
			status_log "Error: Internal server error\n" red
			return 0
		}
		600 {
			::config::setKey start_ns_server [::config::getKey default_ns_server]
			if { [::config::getKey reconnect] == 1 } {
				::MSN::saveOldStatus
				::MSN::logout
				::MSN::reconnect "[trans serverbusy]"
			} else {
				::MSN::logout
				::amsn::errorMsg "[trans serverbusy]"
			}
			status_log "Error: Server is busy\n" red
			return 0
		}
		601 {
			::config::setKey start_ns_server [::config::getKey default_ns_server]
			if { [::config::getKey reconnect] == 1 } {
				::MSN::saveOldStatus
				::MSN::logout
				::MSN::reconnect "[trans serverunavailable]"
			} else {
				::MSN::logout
				::amsn::errorMsg "[trans serverunavailable]"
			}
			status_log "Error: Server is unavailable\n" red
			return 0
		}
		715 {
			#we get a weird character in PSM, need to reset it
			status_log "Error: Weird PSM\n" red
			::abook::setPersonal PSM ""
			::MSN::logout
			::MSN::reconnect ""
		}
		911 {
			#set password ""
			ns configure -stat "closed"
			::MSN::logout
			status_log "Error: User/Password\n" red
			::amsn::errorMsg "[trans baduserpass]"
			return 0
		}
		928 {
			# Apparently, the server said invalid passport, so this server was probably cached and your account
			# was moved to another server (http://www.amsn-project.net/forums/viewtopic.php?p=24823)
			# We'll ask the default_ns_server for a new NS that accepts our passport.
		
			status_log "Account was probably moved to a different server, NS says invalid passport, changing cached server to default"
			::config::setKey start_ns_server [::config::getKey default_ns_server]
			::MSN::saveOldStatus
			::MSN::logout
			::MSN::reconnect "[trans serverunavailable]" ;#actually accountunavailable	
		}
		931 {  ;#this server doesn't know about that account
			status_log "Account was moved to a different server, changing cached server to default"
			::config::setKey start_ns_server [::config::getKey default_ns_server]
			::MSN::saveOldStatus
			::MSN::logout
			::MSN::reconnect "[trans serverunavailable]" ;#actually accountunavailable
			return 0
		}
		"" {
			return 0
		}
		default {
			status_log "Got unknown NS input!! --> [lindex $item 0]\n\t$item" red
			return 0
		}
	}

}


proc cmsn_ns_msg {recv message} {

	if { [lindex $recv 1] != "Hotmail" && [lindex $recv 2] != "Hotmail"} {
		status_log "cmsn_ns_msg: NS MSG From Unknown source ([lindex $recv 1] [lindex $recv 2]):\n$message\n" red
		return
	}

	# Demographic Information about subscriber/user. Can be used
	# for a variety of things.
	set content [$message getHeader Content-Type]
	if {[string range $content 0 19] == "text/x-msmsgsprofile"} {
		status_log "Getting demographic and auth information\n" blue
		# 1033 is English. See XXXX for info
		set d(email_enabled) [$message getHeader EmailEnabled]
		set d(langpreference) [$message getHeader lang_preference]
		set d(preferredemail) [$message getHeader preferredEmail]
		set d(country) [string toupper [$message getHeader country]]
		set d(gender) [string toupper [$message getHeader Gender]]
		set d(kids) [$message getHeader Kid]
		set d(age) [$message getHeader Age]
		#Used for authentication
		set d(mspauth) [$message getHeader MSPAuth]
		set d(kv) [$message getHeader kv]
		set d(sid) [$message getHeader sid]
		set d(sessionstart) [clock seconds]
		set d(clientip) [$message getHeader ClientIP]
		::abook::setDemographics d

		::config::setKey myip $d(clientip)
		status_log "My IP is [::config::getKey myip]\n"
		
		# fetch localization-code from info as long as it wasn't detected/set before
		if {$d(langpreference) != ""} {
			::config::setKey localecode_autodetect $d(langpreference)
		}

		# Looks like MSN sends us whether this user has his emails enabled, so for non hotmail accounts we can automatically remove that inbox line from the CL
		if { [::config::getKey checkemail] == 1 && $d(email_enabled) == 0} {
			::config::setKey checkemail $d(email_enabled)
		}

	} else {
		::hotmail::hotmail_procmsg $message
	}
}

proc sso_authenticate {} {
	global sso
	if {[ns cget -stat] == "u" } {
		set token [$sso GetSecurityTokenByName MessengerClear]
		set nonce [$sso cget -nonce]
		set proof [$token cget -proof]
		set mbi [MBIAuthentication MBICrypt $nonce $proof]
		
		set ticket [$token cget -ticket]
		if {$ticket == "" || $proof == "" || $nonce == "" } {
			eval [ns cget -autherror_handler]
			return
		}
		if {[::config::getKey protocol] >= 16} {
			::MSN::WriteSB ns "USR" "SSO S $ticket $mbi [::config::getGlobalKey machineguid]"
		} else {
			::MSN::WriteSB ns "USR" "SSO S $ticket $mbi"
		}
		ns configure -stat "us"
	} elseif {[ns cget -stat] != "d" } {

		status_log "Connection timeouted : state is [ns cget -stat]\n" white
		::MSN::logout
		::config::setKey start_ns_server [::config::getKey default_ns_server]
		#Reconnect if necessary
		if { [::config::getKey reconnect] == 1 } {
			::MSN::reconnect "[trans connecterror]: Connection timed out"
			return
		}

		msg_box "[trans connecterror]: Connection timed out"
	}
}
proc sso_authenticated { failed } {
	global sso
	if {$failed == 2} {
		eval [ns cget -passerror_handler]
	} elseif { $failed == 1 } {
		eval [ns cget -autherror_handler]
	} else {
		if { [$sso cget -nonce] != "" } {
			sso_authenticate
		}
	}
}

proc cmsn_auth {{recv ""}} {
	global HOME info

	status_log "cmsn_auth starting, stat=[ns cget -stat]\n" blue

	switch -- [ns cget -stat] {
		a {
			#Send three first commands at same time, to be faster
			if { [::config::getKey protocol] == 16 } {
				::MSN::WriteSB ns "VER" "MSNP16 MSNP15 CVR0"
				::MSN::WriteSB ns "CVR" "0x0409 winnt 5.1 i386 WLMSGRBETA 9.0.1407 msmsgs [::config::getKey login]"
			} elseif { [::config::getKey protocol] == 15 } {
				::MSN::WriteSB ns "VER" "MSNP15 CVR0"
				::MSN::WriteSB ns "CVR" "0x0409 winnt 5.1 i386 MSNMSGR 8.0.0812 msmsgs [::config::getKey login]"
			} else {
				::MSN::WriteSB ns "VER" "MSNP12 CVR0"
				::MSN::WriteSB ns "CVR" "0x0409 winnt 5.1 i386 MSNMSGR 8.0.0812 msmsgs [::config::getKey login]"
			}
			if { [::config::getKey protocol] >= 15 } {
				::MSN::WriteSB ns "USR" "SSO I [::config::getKey login]"
			} else {
				::MSN::WriteSB ns "USR" "TWN I [::config::getKey login]"
			}

			ns configure -stat "v"
			return 0
		}

		v {
		
			if { [::config::getKey protocol] == 16 } {
				set ver "MSNP16"
			} elseif { [::config::getKey protocol] == 15 } {
				set ver "MSNP15"
			} else {
				set ver "MSNP12"
			}
	
			if {[lindex $recv 0] != "VER"} {
				status_log "cmsn_auth: was expecting VER reply but got a [lindex $recv 0]\n" red
				return 1
			} elseif {[lsearch -exact $recv $ver] != -1} {
				status_log "Logged in with protocol $ver"
				ns configure -stat "i"
				return 0
			} else {
				status_log "cmsn_auth: could not negotiate protocol!\n" red
				return 1
			}
		}

		i {
			if {[lindex $recv 0] != "CVR"} {
				status_log "cmsn_auth: was expecting CVR reply but got a [lindex $recv 0]\n" red
				return 1
			} else {
				ns configure -stat "u"
				if { [::config::getKey protocol] >= 15 } {
					if {[info exists ::sso] && $::sso != "" } {
						$::sso destroy
						set ::sso ""
					}
					set ::sso [::SSOAuthentication create %AUTO% -username [::config::getKey login] -password $::password]

					if {[info exists ::roaming] } {
						catch {$::roaming destroy}
						unset ::roaming
					}
					set ::roaming [::ContentRoaming create %AUTO%]
					if {[info exists ::ab] } {
						catch {$::ab destroy}
						unset ::ab
					}
					set ::ab [::Addressbook create %AUTO%]

					$::sso Authenticate [list sso_authenticated]
				}
				return 0
			}
		}

		u {
			if { [::config::getKey protocol] >= 15 } {
				if {([lindex $recv 0] != "USR") || \
					([lindex $recv 2] != "SSO") || \
					([lindex $recv 3] != "S")} {
					
					status_log "cmsn_auth: was expecting USR x SSO S xxxxx but got something else!\n" red
					return 1
				}
				global sso
				$sso configure -nonce [lindex $recv 5]
				set token [$sso GetSecurityTokenByName MessengerClear]
				if { [$token cget -ticket] != "" } {
					sso_authenticate
				}

			} else {
				if {([lindex $recv 0] != "USR") || \
					([lindex $recv 2] != "TWN") || \
					([lindex $recv 3] != "S")} {
					
					status_log "cmsn_auth: was expecting USR x TWN S xxxxx but got something else!\n" red
					return 1
				}

				foreach x [split [lrange $recv 4 end] ","] { set info([lindex [split $x "="] 0]) [lindex [split $x "="] 1] }
				set info(all) [lrange $recv 4 end]

				global login_passport_url
				if { $login_passport_url == 0 } {
					status_log "cmsn_auth: Nexus didn't reply yet...\n"
					set login_passport_url $info(all)
				} else {
					status_log "cmsn_auth: Nexus has replied so we have login URL...\n"
					set proxy [ns cget -proxy]
					$proxy authenticate $info(all) $login_passport_url
				}
			}

			return 0

		}

		us {

			if {[lindex $recv 0] != "USR"} {
				status_log "cmsn_auth: was expecting USR reply but got a [lindex $recv 0]\n" red
				return 1
			}

			if {[lindex $recv 2] != "OK"} {
				status_log "cmsn_auth: error authenticating with server!\n" red
				return 1
			}

			ns configure -stat "o"

			save_config						;# CONFIG
			::config::saveGlobal

			if { [::abook::loadFromDisk] < 0 } {
				::abook::clearData
				::abook::setConsistent
			}
			
			::abook::setPersonal login [lindex $recv 3]
			
			#We need to wait until the SYN reply comes, or we can send the CHG request before
			#the server sends the list, and then it won't work (all contacts offline)
			if { [config::getKey protocol] >= 13 } {
				$::ab Synchronize [list ::MSN::ABSynchronizationDone 1]
			} else {
				set list_version [::abook::getContactData contactlist list_version]
				#If the value is invalid, we will be disconnected from server
				if { ![regexp {^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]+-[0-9]{2}:[0-9]{2}$} $list_version] } {
					set list_version "0"
					::abook::setContactData contactlist list_version "0"
				}
				set cl_version [::abook::getContactData contactlist cl_version]
				if { ![regexp {^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]+-[0-9]{2}:[0-9]{2}$} $cl_version] } {
					set cl_version "0"
					::abook::setContactData contactlist cl_version "0"
				}
				::MSN::WriteSB ns "SYN" "$cl_version $list_version" initial_syn_handler
			}

			#Alert dock of status change
			send_dock "MAIL" 0

			#Send "loggedIn" core event
			::Event::fireEvent loggedIn protocol

			#Send event "OnConnect" to plugins when we connect
			::plugins::PostEvent OnConnect evPar

			return 0
		}

	}

	return -1

}


proc ::MSN::ABSynchronizationDone { initial error } {
	if {$error == 0 } {
		::MSN::contactListChanged

		set contacts [::MSN::getList FL]
		set contacts [concat $contacts [::MSN::getList AL]]
		set contacts [concat $contacts [::MSN::getList BL]]
		set contacts [lsort -unique $contacts]

		set xml "<ml l=\"1\">"
		array set domains {}
		foreach contact $contacts {
			set contact [split $contact "@"]
			set user [lindex $contact 0]
			set domain [lindex $contact 1]
			lappend domains($domain) $user
		}
		foreach {domain users} [array get domains] {
			append xml "<d n=\"$domain\">"
			set added_users 0
			foreach user $users {
				set lists [::abook::getLists "$user@$domain"]
				set mask 0

				if {[lsearch $lists "FL"] != -1} {
					incr mask 1
				}
				if {[lsearch $lists "AL"] != -1} {
					incr mask 2
				}
				if {[lsearch $lists "BL"] != -1} {
					incr mask 4
				}
				# Make sure we don't have a contact in AL and BL at the same time
				if {[expr {$mask & 6}] == 6} {
					after 0 [list ::MSN::removeUserFromList "$user@$domain" AL]
					incr mask -2
				}
				if {$added_users > 0 && [expr {[string length $xml] + [string length "<c n=\"$user\" l=\"$mask\" t=\"1\" /></d></ml>"]}] > 7400} {
					append xml "</d></ml>"
					set xmllen [string length $xml]
					::MSN::WriteSBNoNL ns "ADL" "$xmllen\r\n$xml" [list ns handleADLResponse]
					set xml "<ml l=\"1\">"
					append xml "<d n=\"$domain\">"
				}
				incr added_users
				append xml "<c n=\"$user\" l=\"$mask\" t=\"1\" />"
			}
			append xml "</d>"
		}
		append xml "</ml>"
		set xmllen [string length $xml]
		::MSN::WriteSBNoNL ns "ADL" "$xmllen\r\n$xml" [list ns handleADLResponse]

		foreach username [::MSN::getList PL] {
			if { [lsearch [::abook::getLists $username] "AL"] != -1 || [lsearch [::abook::getLists $username] "BL"] != -1 } {
				#We already added it we only move it from PL to RL
				#Just add to RL for now and let the handler remove it from PL... to be sure it's the correct order...
				::MSN::removeUserFromList $username PL
				::MSN::addUserToList $username RL
			} else {
				set nickname [::abook::getContactData $username nick]
				if {$nickname == "" } {
					set nickname $username
				}
				newcontact $username $nickname
			}
		}
		foreach username [::MSN::getList RL] {
			if { [lsearch [::abook::getLists $username] "AL"] == -1 && [lsearch [::abook::getLists $username] "BL"] == -1 } {
				set nickname [::abook::getContactData $username nick]
				if {$nickname == "" } {
					set nickname $username
				}
				newcontact $username $nickname
			}
		}
		if {$initial } {
			ns setInitialStatus
		}
		ns authenticationDone	
	} elseif {$error == 2 } {
		#ABDoesNotExist
		$::ab ABAdd ::MSN::ABAddDone [::config::getKey login]
	} else {
		::MSN::logout
		::amsn::errorMsg "[trans internalerror]"		
	}
}

proc ::MSN::ABAddDone { error } {
	if {$error == 0 } {
		::abook::setPersonal MFN [::config::getKey login]
		$::ab ABContactUpdate [list ::MSN::ABUpdateNicknameCB] "" [list contactType Me displayName [xmlencode [::abook::getPersonal MFN]]] DisplayName
		$::ab Synchronize [list ::MSN::ABSynchronizationDone 1]
	} else {
		::MSN::logout
		::amsn::errorMsg "[trans internalerror]"
	}
}
proc ::MSN::ABUpdateNicknameCB { fail } {
}

proc recreate_contact_lists {} {

	#There's no need to recreate groups, as ::groups already gets all data
	#from ::abook
	foreach groupid [::groups::GetList] {
		::groups::Set $groupid [::groups::GetName $groupid]
	}

	#Let's put every user in their contacts list and groups
	::MSN::clearList AL
	::MSN::clearList BL
	::MSN::clearList FL
	::MSN::clearList RL
	::MSN::clearList EL
	foreach user [::abook::getAllContacts] {
		foreach list_name [::abook::getLists $user] {
			if { $list_name == "FL" } {
				::abook::setVolatileData $user state FLN
			} 
			if { $list_name == "AL" || $list_name == "BL" || $list_name == "FL" || $list_name == "RL"} {
				::MSN::addToList $list_name $user
			}
		}
	}
}

proc set_initial_nick { } {

	global HOME

	set nick_changed 0

	# Switch to our cached nickname if the server's one is different that ours
	if { [file exists [file join ${HOME} "nick.cache"]] && [::config::getKey storename] } {

		set nickcache [open [file join ${HOME} "nick.cache"] r]
		fconfigure $nickcache -encoding utf-8

		gets $nickcache storednick
		gets $nickcache custom_nick
		gets $nickcache stored_login

		close $nickcache

		set indexofnick [string first "\$nick" $custom_nick]
		if { $indexofnick >= 0 } {
			set custom_nick [string replace $custom_nick $indexofnick [expr {$indexofnick + 4}] $storednick]
		}

		if { ($custom_nick == [::abook::getPersonal MFN]) && ($stored_login == [::abook::getPersonal login]) && ($storednick != "") } {
			::MSN::changeName $storednick
			set nick_changed 1
		}
	}
	catch { file delete [file join ${HOME} "nick.cache"] }


	if {$nick_changed == 0 && [config::getKey protocol] >= 15 } {
		# Send our nickname to the server because it doesn't know about it!
		if { [::abook::getPersonal MFN] != "" } {
			::MSN::changeName [::abook::getPersonal MFN]
		}
	}

	if { [file exists [file join ${HOME} "psm.cache"]] && [::config::getKey storename] } {

		set psmcache [open [file join ${HOME} "psm.cache"] r]
		fconfigure $psmcache -encoding utf-8

		gets $psmcache storedpsm
		gets $psmcache custom_psm
		gets $psmcache stored_login

		close $psmcache

		set indexofpsm [string first "\$psm" $custom_psm]
		if { $indexofpsm >= 0 } {
				set custom_psm [string replace $custom_psm $indexofpsm [expr {$indexofpsm + 3}] $storedpsm]
		}

		if { ($custom_psm == [::abook::getPersonal PSM]) && ($stored_login == [::abook::getPersonal login]) } {
				::MSN::changePSM $storedpsm
		}
	}
	
	catch { file delete [file join ${HOME} "psm.cache"] }
}

proc initial_syn_handler {recv} {

	set_initial_nick
	cmsn_ns_handler $recv

	return 1
}

proc msnp11_userpass_error {} {
	global reconnect_timer
	set reconnect_timer 0

	ns configure -stat "closed"
	::MSN::logout
	status_log "Error: User/Password\n" red
	::amsn::errorMsg "[trans baduserpass]"
}

proc msnp11_auth_error {} {
	global reconnect_timer
	set reconnect_timer 0

	status_log "Error connecting to server\n"
	::MSN::logout
	::amsn::errorMsg "[trans connecterror]"
}

proc msnp11_authenticate { ticket } {
	if {[ns cget -stat] == "u" } {
		::MSN::WriteSB ns "USR" "TWN S $ticket"
		set ::authentication_ticket $ticket
		ns configure -stat "us"
	} elseif {[ns cget -stat] != "d" } {

		status_log "Connection timeouted : state is [ns cget -stat]\n" white
		::MSN::logout
		::config::setKey start_ns_server [::config::getKey default_ns_server]
		#Reconnect if necessary
		if { [::config::getKey reconnect] == 1 } {
			::MSN::reconnect "[trans connecterror]: Connection timed out"
			return
		}

		msg_box "[trans connecterror]: Connection timed out"
	}
	return
}


proc sb_change { chatid } {
	global typing

	set sb [::MSN::SBFor $chatid]

	if { $sb == 0 } {
		status_log "sb_change: VERY BAD ERROR - SB=0\n" error
		return 0
	}

	if { ![info exists typing($sb)] } {
		set typing($sb) 1

		after 4000 "unset typing($sb)"

		set sock [$sb cget -sock]

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgscontrol\r\nTypingUser: [::config::getKey login]\r\n\r\n\r\n"
		set msg_len [string length $msg]

		#::MSN::WriteSB $sbn "MSG" "U $msg_len"
		#::MSN::WriteSBRaw $sbn "$msg"
		::MSN::WriteSBNoNL $sb "MSG" "U $msg_len\r\n$msg"
	}
}

proc ::MSN::SendRecordingUserNotification { chatid } {
	set sb [::MSN::SBFor $chatid]

	if { $sb == 0 } {
		status_log "SendRecordingUserNotification: VERY BAD ERROR - SB=0\n" error
		return 0
	}
	set sock [$sb cget -sock]
	set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgscontrol\r\nRecordingUser: [::config::getKey login]\r\n\r\n\r\n"
	set msg_len [string length $msg]
	
	::MSN::WriteSBNoNL $sb "MSG" "U $msg_len\r\n$msg"
}


###################### Other Features     ###########################


proc ns_enter {} {
	set command "[.status.enter get]"
	.status.enter delete 0 end
	status_log "Executing : $command\n"
	if { [string range $command 0 0] == "/"} {
		#puts -nonewline [ns cget -sock] "[string range $command 1 [string length $command]]\r\n"
		::MSN::WriteSBRaw ns "[string range $command 1 [string length $command]]\r\n"
	} elseif {$command != ""} {
		if {[catch {eval $command} res]} {
			::amsn::errorMsg "$res"
		} else {
			status_log "$res\n"
		}
	}

}

proc setup_connection {name} {

	#This is the default read handler, if not changed by proxy
	#This is the default procedure that should be called when an error is detected
	#$name configure -error_handler [list ::MSN::CloseSB $name]
	if {![catch {[$name cget -proxy] cget -name}]} {
		#The connection already has a Proxy defined so we clean it
		[$name cget -proxy] finish $name
		[$name cget -proxy] destroy
	}
	$name configure -proxy [Proxy create %AUTO%]
	if {[::config::getKey connectiontype] == "direct" } {
		#$name configure -connection_wrapper DirectConnection

	} elseif {[::config::getKey connectiontype] == "http"} {

		#$name configure -connection_wrapper HTTPConnection
		$name configure -proxy_host ""
		$name configure -proxy_port ""

		#status_log "cmsn_socket: Setting up http connection\n" green
		#set tmp_serv "gateway.messenger.hotmail.com"
		#set tmp_port 80

		#::Proxy::Init "$tmp_serv:$tmp_port" "http"

		#::Proxy::OnCallback "dropped" "proxy_callback"

		#status_log "cmsn_socket: Calling proxy::Setup now\n" green
		#::Proxy::Setup next readable_handler $name


	} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "http" } {

		#TODO: Right now it's always HTTP proxy!!
		#$name configure -connection_wrapper HTTPConnection
		set proxy [::config::getKey proxy]
		$name configure -proxy_host [lindex $proxy 0]
		$name configure -proxy_port [lindex $proxy 1]
		$name configure -proxy_authenticate [::config::getKey proxyauthenticate]
		$name configure -proxy_user [::config::getKey proxyuser]
		$name configure -proxy_password [::config::getKey proxypass]

		#set proxy [$name cget -proxy]
		#status_log "cmsn_socket: Setting up Proxy connection (type=[::config::getKey proxytype])\n" green
		#$proxy Init [::config::getKey proxy] [::config::getKey proxytype]
		#$proxy LoginData [::config::getKey proxyauthenticate] [::config::getKey proxyuser] [::config::getKey proxypass]

		#set proxy_serv [split [::config::getKey proxy] ":"]
		#set tmp_serv [lindex $proxy_serv 0]
		#set tmp_port [lindex $proxy_serv 1]
		#$proxy OnCallback "dropped" "proxy_callback"

		#status_log "cmsn_connect: Calling proxy::Setup now\n" green
		#$proxy Setup next readable_handler $name
	} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "socks5" } {

		#We set the parameters for the SOCKS5 proxy
		
		set proxy [::config::getKey proxy]
		$name configure -proxy_host [lindex $proxy 0]
		$name configure -proxy_port [lindex $proxy 1]
		$name configure -proxy_authenticate [::config::getKey proxyauthenticate]
		$name configure -proxy_user [::config::getKey proxyuser]
		$name configure -proxy_password [::config::getKey proxypass]

	} else {
		#$name configure -connection_wrapper DirectConnection
		::config::setKey connectiontype "direct"
	}
}

proc cmsn_socket {name} {

	$name configure -time [clock seconds]
	$name configure -stat "cw"
	$name configure -error_msg ""

	set proxy [$name cget -proxy]
	if {[catch {$proxy cget -name}] } {
		#The proxy was deleted
		$name configure -proxy [Proxy create %AUTO%]
	}
	
	if {[$proxy connect $name]<0} {
		::MSN::CloseSB $name
	}

	degt_protocol "< Connected to: [$name cget -server] >"

}

proc cmsn_ns_connected {sock} {
	fileevent $sock writable ""
	set error_msg ""
	set therewaserror [catch {set error_msg [fconfigure [ns cget -sock] -error]} res]
	if { ($error_msg != "") || $therewaserror == 1 } {
		ns configure -error_msg $error_msg
		::config::setKey start_ns_server [::config::getKey default_ns_server]
		status_log "cmsn_ns_connected ERROR: $error_msg\n" red
		::MSN::CloseSB ns
		return
	}

	ns configure -stat "a"

	cmsn_auth
	if {[::config::getKey enablebanner] && [::config::getKey adverts]} {
		adv_resume
	}
}


#TODO: ::abook system
proc cmsn_ns_connect { username {password ""} {nosignin ""} } {
	if { ($username == "") || ($password == "")} {
		return -1
	}

	::MSN::clearList FL
	::MSN::clearList AL
	::MSN::clearList BL
	::MSN::clearList RL
	::MSN::clearList PL
	::MSN::clearList EL

	if {[ns cget -stat] != "d"} {
		set proxy [ns cget -proxy]
		$proxy finish ns
	}

	ns configure -stat "c"

	if { $nosignin == "" } {
		cmsn_draw_signin
	}

	::MSN::StartPolling
	::groups::Reset

	#TODO: Call "on connect" handlers, where hotmail will be registered.
	set ::hotmail::unread 0

	ns configure -autherror_handler "msnp11_auth_error"
	ns configure -passerror_handler "msnp11_userpass_error"
	ns configure -ticket_handler "msnp11_authenticate"
	ns configure -connected "cmsn_ns_connected"

	cmsn_socket ns

	return 0
}


proc process_msnp11_lists { bin } {

	set lists [list]

	if { $bin == "" } {
		status_log "process_msnp11_lists: No lists!!!\n" red
		return $lists
	}

	if { $bin & 1 } {
		lappend lists "FL"
	}

	if { $bin & 2 } {
		lappend lists "AL"
	}

	if { $bin & 4 } {
		lappend lists "BL"
	}

	if { $bin & 8 } {
		lappend lists "RL"
	}

	if { $bin & 16 } {
		lappend lists "PL"
	}

	return $lists
}

proc urldecode {str} {

	#New version, no need of url_unmap
	set str [encoding convertto utf-8 $str]

	set begin 0
	set end [string first "%" $str $begin]
	set decode ""


	while { $end >=0 } {
		set decode "${decode}[string range $str $begin [expr {$end-1}]]"

		#TODO: Here, why some nicks can have thins like %he ??? why is it allowed if they're encoded
		# using ulrencode??? We "catch" the error and try another thing.
		set hexvalue [string range $str [expr {$end+1}] [expr {$end+2}]]
		if {[catch {set carval [format %d 0x$hexvalue]} res]} {
			set decode "${decode}\%"
			set begin [expr {$end+1}]

		} else {
			if {$carval > 128} {
				set carval [expr { $carval - 0x100 }]
			}

			set car [binary format c $carval]

			set decode "${decode}$car"

			#if {[catch {set decode2 "${decode2}[format %c 0x[string range $str [expr {$end+1}] [expr {$end+2}]]]"} res]} {
			#   catch {set decode2 "${decode2}[format %c 0x[string range $str [expr {$end+1}] [expr {$end+1}]]]"} res
			#}

			set begin [expr {$end+3}]
		}
		set end [string first "%" $str $begin]
	}

	set decode ${decode}[string range $str $begin [string length $str]]

	#status_log "urldecode: original:$str\n   decoded=$decode\n   un-utf-8=[encoding convertfrom utf-8 $decode]\n"
	return [encoding convertfrom utf-8 $decode]
}

proc urlencode_all {str} {

	set encode ""

	set utfstr [encoding convertto utf-8 $str]


	for {set i 0} {$i<[string length $utfstr]} {incr i} {
	set character [string range $utfstr $i $i]
		binary scan $character c charval
		#binary scan $character s charval
		set charval [expr {($charval + 0x100) % 0x100}]
		#set charval [expr {( $charval + 0x10000 ) % 0x10000}]
		if {$charval <= 0xFF} {
			set encode "${encode}%[format %.2X $charval]"
		} else {
			status_log "urlencode_all: THIS SHOULDN'T HAPPEN, CHECK IT IN proc urlencode!!!\n" white
			#set charval1 [expr {$charval & 0xFF} ]
			#set charval2 [expr {$charval >> 8}]
			#set encode "${encode}$character"
		}
	}
	
	#status_log "urlencode: original=$str\n   utf-8=$utfstr\n   encoded=$encode\n"
	if  {[string length $encode] <=387 } {
		return $encode
	} else {
		return [string range $encode 0 349]
	}
}


proc urlencode {str} {
#   global url_map

	set encode ""

	set utfstr [encoding convertto utf-8 $str]


	for {set i 0} {$i<[string length $utfstr]} {incr i} {
		set character [string range $utfstr $i $i]

		if {[string match {[^a-zA-Z0-9()]} $character]==0} {
			binary scan $character c charval
			#binary scan $character s charval
			set charval [expr {($charval + 0x100) % 0x100}]
			#set charval [expr {( $charval + 0x10000 ) % 0x10000}]
			if {$charval <= 0xFF} {
				set encode "${encode}%[format %.2X $charval]"
			} else {
				status_log "urlencode: THIS SHOULDN'T HAPPEN, CHECK proc urlencode!!!\n" white

				#set charval1 [expr {$charval & 0xFF} ]
				#set charval2 [expr {$charval >> 8}]
				#set encode "${encode}$character"
			}
		} else {
			set encode "${encode}${character}"
		}
	}
	#status_log "urlencode: original=$str\n   utf-8=$utfstr\n   encoded=$encode\n"
	if  {[string length $encode] <=387 } {
		return $encode
	} else {
		return [string range $encode 0 349]
	}
}

proc change_BLP_settings { state } {
	global list_BLP

	if { "$state" == "AL" } {
		set list_BLP 1
	} elseif { "$state" == "BL" } {
		set list_BLP 0
	} else {
		set list_BLP -1
	}

}


proc new_contact_list { cl_version list_version } {
	global contactlist_loaded

	set old_list_version [::abook::getContactData contactlist list_version]
	set old_cl_version [::abook::getContactData contactlist cl_version]

	status_log "new_contact_list: new contact list version : $list_version $cl_version --- previous was : $old_list_version $old_cl_version\n"

	if { ($old_list_version eq $list_version) && ($old_cl_version eq $cl_version) } {
		return 0
	} else {
		::abook::setContactData contactlist list_version $list_version
		::abook::setContactData contactlist cl_version $cl_version
		return 1
	}

}

proc getCensoredWords { } {
	catch {::MSN::WriteSB ns GCF Shields.xml}
}



proc checking_package_tls { }  {
	global tlsinstalled

	if { [catch {package require tls}] } {
		# Either tls is not installed, or $auto_path does not point to it.
		# Should now never happen; the check for the presence of tls is made
		# before this point.
		#    status_log "Could not find the package tls on this system.\n"
		set tlsinstalled 0
		return 0
	} else {
		set tlsinstalled 1
		return 1
	}

}

proc create_msnobj { Creator type filename {friendly "AAA="} {stamp ""}} {
	global msnobjcontext

	if { [file exists $filename] == 0 } { return "" }
	set fd [open $filename r]
	fconfigure $fd -translation binary
	set data [read $fd]
	close $fd

	set file [filenoext [getfilename $filename]]

	set size [string length $data]

	set sha1d [::base64::encode [binary format H* [::sha1::sha1 $data]]]

	set sha1c [::base64::encode [binary format H* [::sha1::sha1 "Creator${Creator}Size${size}Type${type}Location${file}.tmpFriendly${friendly}SHA1D${sha1d}"]]]

	set msnobj "<msnobj Creator=\"$Creator\" Size=\"$size\" Type=\"$type\" Location=\"[urlencode $file].tmp\" Friendly=\"${friendly}\" SHA1D=\"$sha1d\" SHA1C=\"$sha1c\""

	if { $stamp == "" } {
		append msnobj "/>"
	} else {
		append msnobj " stamp=\"$stamp\"/>"
	}

	set msnobjcontext($msnobj) $filename

	return $msnobj
}

proc getfilename { filename } {
	return "[file tail $filename]"
}

proc filenoext { filename } {
	if {[string last . $filename] != -1 } {
		return "[string range $filename 0 [expr [string last . $filename] - 1]]"
	} else {
		return $filename
	}
}

proc fileext { filename } {
	if {[string last . $filename] != -1 } {
		return "[string range $filename [string last . $filename] end]"
	} else {
		return ""
	}
}
#############################################################
# xclientcaps_received msg chatid                           #
# ----------------------------------------------------------#
# Packets received from 3rd party client (not by MSN)       #
# Add the information to ContactData                        #
# More information:                                         #
# http://www.chat.solidhouse.com/msninterop/clientcaps.php  #
#############################################################
proc xclientcaps_received {msg chatid} {
		#Get String for Client-Name (Gaim, dMSN and others)
		set clientname [$msg getHeader "Client-Name"]
		if { $clientname == "" } {
			set clientname [$msg getField "Client-Name"]
		}
		::abook::setContactData $chatid clientname $clientname

		set chatlogging [$msg getHeader "Chat-Logging"]
		if { $chatlogging == "" } {
			set chatlogging [$msg getField "Chat-Logging"]
		}
		::abook::setContactData $chatid chatlogging $chatlogging

		set operatingsystem [$msg getHeader "Operating-System"]
		if { $clientname == "" } {
			set operatingsystem [$msg getField "Operating-System"]
		}
		::abook::setContactData $chatid operatingsystem $operatingsystem
}

#################################################
# add_Clientid chatid clientid                	#
# ---------------------------------------------	#
# Look for clientid information               	#
# Add it to ContactData                       	#
# More information:                           	#
# http://ceebuh.info/docs/?url=clientid.html	#
#################################################
# id bit     capability				#
# 0x00000001 Mobile Device			#
# 0x00000002 Unknown				#
# 0x00000004 Ink Viewing			#
# 0x00000008 Ink Creating			#
# 0x00000010 Webcam				#
# 0x00000020 Multi-Packeting			#
# 0x00000040 Paging				#
# 0x00000080 Direct-Paging			#
# 0x00000200 WebMessenger			#
# 0x00001000 Unknown (Msgr 7 always[?] sets it)	#
# 0x00004000 DirectIM				#
# 0x00008000 Winks				#
#################################################
proc add_Clientid {chatid clientid} {

	##First save the clientid (number)
	::abook::setContactData $chatid clientid $clientid

	##Find out how the client-program is called
	switch -- [expr {$clientid & 0xF0000000}] {
		268435456 {
			# 0x10000000
			set clientname "MSN 6.0"
		}
		536870912 {
			# 0x20000000
			set clientname "MSN 6.1"
		}
		805306368 {
			# 0x30000000
			set clientname "MSN 6.2"
		}
		1073741824 {
			# 0x40000000
			set clientname "MSN 7.0"
		}
		1342177280 {
			# 0x50000000
			set clientname "MSN 7.5"
		}
		1610612736 {
			# 0x60000000
			set clientname "Windows Live Messenger 8.0"
		}
		1879048192 {
			# 0x70000000
			set clientname "Windows Live Messenger 8.1"
		}
		2147483648 {
			# 0x80000000
			set clientname "Windows Live Messenger 8.5"
		}
		default {
			if {($clientid & 0x200) == [expr {0x200}]} {
					set clientname "Webmessenger"
			} elseif {($clientid & 0x800) == [expr {0x800}]} {
					set clientname "Microsoft Office gateway"
			} else {
					set clientname "[trans unknown]"
			}
		}
	}	

	##Store the name of the client this user uses in the adressbook
	::abook::setContactData $chatid client $clientname



	##Set the capability flags for this user##

	set flags [list [list 1 mobile_device] [list 4 receive_ink] [list 8 sendnreceive_ink] [list 16 webcam_shared] [list 32 multi_packet] [list 64 msn_mobile] [list 128 msn_direct] [list 16384 directIM ] [list 32768 winks] ]
	
	foreach flag $flags {
		set bit [lindex $flag 0]
		set flagname [lindex $flag 1]
		#check if this bit is on in the clientid, ifso set it's flag
		if {($clientid & $bit) == $bit} {
			::abook::setContactData $chatid $flagname 1
		} else {
			::abook::setContactData $chatid $flagname 0
		}
	}		

}

###############################################
# system_message msg                          #
# ------------------------------------------- #
# Show an alert when the server send the      #
# message that MSN going down for maintenance #
# in $minute minutes.                         #
###############################################
proc system_message {msg} {

	if {[string first "Arg1:" $msg] != "-1"} {
		#Find the minute variable
		set minute [$message getHeader Arg1]
		status_log "Server close for maintenance in -$minute- minutes"
		#Show the alert
		::amsn::messageBox [trans maintenance $minute] ok error
	}
}

proc myRand { min max } {
	return [expr {int($min + rand() * (1+$max-$min))}]
}


proc binword { word } {
	if {$word == "" || [string is digit $word] == 0 } {
		set word 0
	}
	return [binary format ii $word 0]
	#return [binary format ii [expr $word % 4294967296] [expr ( $word - ( $word % 4294967296)) / 4294967296 ]]

}

proc ToLittleEndian { bin length } {
	if { $::tcl_platform(byteOrder) == "littleEndian" } { return "$bin"}

	if { $length == 2 } { set type s } elseif {$length == 4} { set type i } else { return "$bin"}

	set binout ""
	incr length -1
	while { $bin != "" } {
		set in [string range $bin 0 $length]
		binary scan $in [string toupper $type] out
		set out [binary format $type $out]
		set binout "${binout}${out}"
		set bin [string replace $bin 0 $length]
	}
	return $binout
}

proc ToBigEndian { bin length } {
	if { $::tcl_platform(byteOrder) == "littleEndian" } { return "$bin"}

	if { $length == 2 } { set type S } elseif {$length == 4} { set type I } else { return "$bin"}

	set binout ""
	incr length -1
	while { [string length $bin] > $length } {
		set in [string range $bin 0 $length]
		binary scan $in [string tolower $type] out
		set out [binary format $type $out]
		set binout "${binout}${out}"
		set bin [string replace $bin 0 $length]
	}
	return $binout
}

proc ToUnicode { text } {
	#status_log "Converting $text to unicode\n" red

#	set text [encoding convertfrom $text]
	#status_log "text msg is : $text\n" red
	set text [encoding convertto unicode $text]
	#status_log "text msg is : $text\n" red
	#set text [binary format a* $text]
	#status_log "text msg is : $text\n" red
	set text [ToLittleEndian $text 2]
	#status_log "text msg is : $text\n" red

	return $text
}

proc FromUnicode { text } {
	#status_log "Converting $text from unicode\n" red

	#binary scan $text A* text
	#status_log "text msg is : $text\n" red

	set text [ToBigEndian "$text" 2]
	#status_log "text msg is : $text\n" red
	set text [encoding convertfrom unicode "$text"]
	#status_log "text msg is : $text\n" red

#	set text [encoding convertto "$text"]
	#status_log "text msg is : $text\n" red

	return $text
}

proc int2word { int1 int2 } {
	if { $int2>0} {
		status_log "Warning!!!! int was a 64-bit integer!! Ignoring for tcl/tk 8.3 compatibility!!!!\n" white
	}
	return $int1
	#return [expr $int2 * 4294967296 + $int1]
}

namespace eval ::MSN6FT {
	namespace export SendFT AcceptFT RejectFT handleMsnFT


	proc SendFT { chatid filename filesize} {
		global HOME

		status_log "Sending File $filename with size $filesize to $chatid\n"

		set sid [expr {int(rand() * 1000000000)%125000000 + 4}]
		# Generate BranchID and CallID
		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

		set dest [lindex [::MSN::usersInChat $chatid] 0]

#		set session [::MSNP2P::Session %AUTO% -totalsize $filesize -dest $dest -callid $callid \
#		-type "filetransfer" -filename $filename -branchid $branchid]
#		::MSNP2P::putSession $sid $session
#		status_log "branchid : [::MSNP2P::$sessions($sid) cget -branchid]\n"

		::MSNP2P::SessionList set $sid [list 0 $filesize 0 $dest 0 $callid 0 "filetransfer" "$filename" "$branchid"]
		setObjOption $sid chatid $chatid

		status_log "branchid : [lindex [::MSNP2P::SessionList get $sid] 9]\n"

		set ext [string tolower [string range [fileext $filename] 1 end]]
		if { $ext == "jpg" || $ext == "gif" || $ext == "png" || $ext == "bmp" || $ext == "jpeg" || $ext == "tga" } {
			set nopreview 0
		} else {
			set nopreview 1
		}

		# If the advanced option to not send the preview is enabled, we force it not to send any preview
		if {[::config::getKey noftpreview]} {
			set nopreview 1
		}
 
		# TODO filesize is a QWORD not a DWORD followed by a 0 DWORD.
		set context "[binary format i 574][binary format i 2][binary format i $filesize][binary format i 0][binary format i $nopreview]"


		set file [ToUnicode [getfilename $filename]]

		set file [binary format a550 $file]
		set context "${context}${file}\xFF\xFF\xFF\xFF"

		if { $nopreview == 0 } {
			#Here we resize the picture and save it in /FT/cache for the preview (we send it and we see it)
			create_dir [file join $HOME FT cache]
			if {[catch {set image [image create photo [TmpImgName] -file $filename]}]} {
				set image [::skin::getNoDisplayPicture]
			}
			if {[catch {::picture::ResizeWithRatio $image 96 96} res]} {
				status_log $res
			}
			set file  "[file join $HOME FT cache ${callid}.png]"
			if {[catch {::picture::Save $image $file cxpng} res] } {
				status_log $res
			}
			
			if {$image != [::skin::getNoDisplayPicture]} {
				image delete $image
			}
			
			::skin::setPixmap ${callid}.png $file
							
			if { [catch { open $file} fd] == 0 } {
				fconfigure $fd -translation {binary binary }
				set context "$context[read $fd]"
				close $fd
			}
			#Show the preview picture in the window
			if { [::skin::loadPixmap "${callid}.png"] != "" } {
				::amsn::WinWrite $chatid "\n" green
				::amsn::WinWriteIcon $chatid ${callid}.png 5 5
				::amsn::WinWrite $chatid "\n" green
			}
		}


		# Create and send our packet
		set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 0 $callid 0 0 "5D3E02AB-6190-11D3-BBBB-00C04F795683" $sid 2 \
				 [string map { "\n" "" } [::base64::encode "$context"]]]
		::MSNP2P::SendPacketExt [::MSN::SBFor $chatid] $sid $slpdata 1
		status_log "Sent an INVITE to [::MSN::usersInChat $chatid]  on chatid $chatid for filetransfer of filename $filename\n" red
		
		#added a return to be able to fetch sid...
		return $sid

	}



	proc SendFTInvite { sid chatid} {
		# Remote user has just accepted our FT invitation

		::amsn::DisableCancelText [getObjOption $sid theCookie] $chatid

		set session [::MSNP2P::SessionList get $sid]
		set branchid [lindex $session 9]
		set callid [lindex $session 5]
		set dest [lindex $session 3]
		set filename [lindex $session 8]


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


		::amsn::FTProgress a $sid $filename $dest 1000 $chatid

		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "INVITE1" -1 -1 -1 -1 -1]

		set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 0 $callid 0 1 "TCPv1 SBBridge" \
				 $netid $conntype $upnp "false"]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

		#after 5000 "::MSNP2P::SendDataFile $sid $chatid [list [lindex [::MSNP2P::SessionList get $sid] 8]] \"INVITE1\""
	}


	proc SendFTInvite2 { sid chatid} {

		set session [::MSNP2P::SessionList get $sid]
		set branchid [lindex $session 9]
		set callid [lindex $session 5]

		set dest [lindex $session 3]
		set conntype [abook::getDemographicField conntype]

		set listening [abook::getDemographicField listening]
		#set listening "false"

		if { [catch {set fd [open [lindex $session 8] "r"]}] } {
			::MSN6FT::CancelFT $chatid $sid
			::amsn::WinWriteRejectFT $chatid [trans filedoesnotexist]
			return 0
		}
		fconfigure $fd -translation {binary binary}

		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "INVITE2" -1 $fd -1 -1 -1]

		if {$listening == "true" } {
			set nonce "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
			set port [OpenMsnFTPort [config::getKey initialftport] $nonce $sid 1]
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
				after 5000 "::MSNP2P::SendDataFile $sid $chatid [list [lindex [::MSNP2P::SessionList get $sid] 8]] \"INVITE2\""
		} else {

			after 5000 "::MSNP2P::SendDataFile $sid $chatid [list [lindex [::MSNP2P::SessionList get $sid] 8]] \"INVITE2\""
		}
	}

	proc OpenMsnFTPort { port nonce sid sending} {
		while { [catch {set sock [socket -server "::MSN6FT::handleMsnFT $nonce $sid $sending" $port] } ] } {
			incr port
		}
		# TODO the server socket should be closed as soon as the user authenticated or whatever... 
		after 300000 "catch {close $sock}"

		::amsn::FTProgress w $sid "" $port
		status_log "Opening server on port $port\n" red
		return $port
	}

	proc handleMsnFT { nonce sid sending sock ip port } {

		setObjOption $sid sending $sending
		setObjOption $sock nonce $nonce
		setObjOption $sock state "FOO"
		setObjOption $sock server 1
		setObjOption $sock sid $sid

		status_log "Received connection from $ip on port $port - socket $sock\n"
		
		fileevent $sock readable "::MSN6FT::ReadFromSock $sock"
		#fileevent $sock writable "::MSN6FT::WriteToSock $sock"
		
		fconfigure $sock -blocking 0 -buffering none -translation {binary binary}
	}


	proc ConnectSockets { sid nonce ip port sending } {

		set ips [getObjOption $sid ips]

		if { $ips == "" } {
			set ips [list]
		}

		set nips [split $ip " "]

		foreach connection $nips {

			status_log "Trying to connect to $connection at port $port\n" red
			set socket [connectMsnFTP $sid $nonce "$connection" $port]
			if { $socket != 0 } {
				lappend ips [list $connection $port $socket]
			}
		}

		setObjOption $sid sending $sending
		setObjOption $sid ips $ips

		foreach connection $ips {
			set sock [lindex $connection 2]

			catch { fconfigure $sock -blocking 0 -buffering none -translation {binary binary} }
			catch { fileevent $sock readable "::MSN6FT::CheckConnected $sid $sock " }
			catch { fileevent $sock writable "::MSN6FT::CheckConnected $sid $sock " }
		}

		after cancel "::MSN6FT::CheckConnectSuccess $sid"
		after 5000 "::MSN6FT::CheckConnectSuccess $sid"

	}

	proc CheckConnectSuccess { sid } {
		set ips [getObjOption $sid ips]
		set connected_ips [getObjOption $sid connected_ips]
		status_log "we have $ips connecting sockets and $connected_ips connected sockets\n" red
		after 5000 "::MSNP2P::SendDataFile $sid [getObjOption $sid chatid] [list [lindex [::MSNP2P::SessionList get $sid] 8]] \"INVITE2\""
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

			::amsn::FTProgress c $sid "" $ip $port
			fileevent $socket readable "::MSN6FT::ReadFromSock $socket"
			fileevent $socket writable "::MSN6FT::WriteToSock $socket"
			CloseUnusedSockets $sid $socket

			set ips [getObjOption $sid ips]
			setObjOption $sid ips [::MSNCAM::RemoveSocketFromList $ips $socket]



		}

	#	after 5000 "::MSN6FT::CheckConnectSuccess $sid"
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

	proc connectMsnFTP { sid nonce ip port } {

		if { [catch {set sock [socket -async $ip $port]}] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red
			return 0
		} else {

			setObjOption $sock nonce $nonce
			setObjOption $sock state "FOO"
			setObjOption $sock server 0
			setObjOption $sock sid $sid
				
			status_log "connectedto $ip on port $port  - $sock\n"
			return $sock

		}
	}

	


	proc ReadFromSock { sock } {
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
				status_log "FT Socket $sock closed\n"
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
							fileevent $sock writable "::MSN6FT::WriteToSock $sock"
						} else {
							setObjOption $sock state "CONNECTED"
							if { $sending } {
								fileevent $sock writable "::MSN6FT::WriteToSock $sock"	
							}
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
					#if { [lindex [::MSNP2P::SessionList get $sid] 7] == "filetransfersuccessfull" } {
					#	catch { close $sock }
					#}
				}
	
				default
				{
					catch {close $sock}
				}
	
			}
		} else {
			#The data we grabbed isn't integral we save actual data and we wait the next
			setObjOption $sock buffer $data
		}


	}
	proc WriteToSock { sock } {
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
					fileevent $sock writable "::MSN6FT::WriteToSock $sock"
				}
			}

			"NONCE_SEND"
			{
				
				set nonce [getObjOption $sock nonce]
				
				set data "[GetDataFromNonce $nonce $sid]"
				if { $server } {
					setObjOption $sock state "CONNECTED"
					if { $sending } {
						fileevent $sock writable "::MSN6FT::WriteToSock $sock"	
					}
				} else {
					setObjOption $sock state "NONCE_GET"
				}

			}

			"CONNECTED"
			{

				if { $sending && [SendFileToSock $sock] == "0" } {
					setObjOption $sock sending 0
					fileevent $sock writable ""
					catch { close $sock }
				} else {
					after 5 [list fileevent $sock writable "::MSN6FT::WriteToSock $sock"]
				}
			}

		}

		if { $data != "" } {
#			status_log "Writing Data on socket $sock with state $state : $data\n" red
			puts -nonewline $sock "[binary format i [string length $data]]$data"
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


	proc CloseSocket { sock } {

		#return
		set sid [getObjOption $sock sid]

		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]

		set bheader [binary format ii 0 $MsgId][binword 0][binword 0][binary format iiii 0 4 [expr {int(rand() * 1000000000)%125000000 + 4}] 0][binword 0]

		puts -nonewline $sock "[binary format i 48]$bheader"
		status_log "Closing socket... \n" red
		close $sock

	}


	proc SendFileToSock  { sock } {
		global msn6ft_test_nak_once
		if {![info exists msn6ft_test_nak_once] } {
			set msn6ft_test_nak_once 0
		}
		set sid [getObjOption $sock sid]

		set fd [lindex [::MSNP2P::SessionList get $sid] 6]
		if { [lindex [::MSNP2P::SessionList get $sid] 7] == "ftcanceled" } {
			
			catch {close $fd }
			return 0
		}
		if { $fd == 0 || $fd == "" } {
			set filename [lindex [::MSNP2P::SessionList get $sid] 8]
			set fd [open "${filename}"]
			::MSNP2P::SessionList set $sid [list -1 [file size "${filename}"] -1 -1 -1 -1 $fd -1 -1 -1]
			fconfigure $fd -translation {binary binary}
		}

#		status_log "Sending file with fd : $fd\n" red

		# Take the MsgId from the session to make sure we use the same blob_id for all the file transfer
		# Apparently, this could be the bug causing FTs being canceled during upload. WLM sends an MSNSLP
		# message for renegociating ip/port or to notify us of out of sync, and we ack it,
		# which will increment the MsgId and all subsequent data messages will use the new MsgId 
		# which WLM will not recognize and will not be able to link to the other data we sent.. then the FT
		# times out and gets canceled.
		# Thanks to the KMess team for finding this : http://www.codingdomain.com/blog/archives/16-KMess-file-transfer-fixes;-MSN-Protocol-goodies.html
		set MsgId [getObjOption $sid data_blob_id]
		set DataSize [lindex [::MSNP2P::SessionList get $sid] 1]
		set Offset [lindex [::MSNP2P::SessionList get $sid] 2]

		# We can receive a NAK to our data being sent.
		# When a packet is lost for some reason, we get a nak with the position
		# of the file that WLM wants to receive. If we got that, we simply reposition 
		# ourselves in the file and set the new offset.
		if {[getObjOption $sid nak_pos ""] != "" } {
			set new_pos [getObjOption $sid nak_pos]
			set Offset $new_pos
			seek $fd $new_pos
			setObjOption $sid nak_pos ""
		}

		if {$DataSize == 0 } {
			status_log "Correcting DataSize\n" green
			set filename [lindex [::MSNP2P::SessionList get $sid] 8]
			set DataSize [file size "${filename}"]
			::MSNP2P::SessionList set $sid [list -1 $DataSize -1 -1 -1 -1 $fd -1 -1 -1]
		}

		set data [read $fd 1352]
		set out "[binary format iiiiiiiiiiii $sid $MsgId $Offset 0 $DataSize 0 [string length $data] 16777264 [expr {int(rand() * 1000000000)%125000000 + 4}] 0 0 0]$data"


		::amsn::FTProgress s $sid "" [expr {$Offset + [string length $data]}] $DataSize
		#status_log "Writing file to socket $sock, send $Offset of $DataSize\n" red

		set Offset [expr {$Offset + [string length $data]}]

		::MSNP2P::SessionList set $sid [list -1 -1 $Offset -1 -1 -1 -1 -1 -1 -1]

		if {$msn6ft_test_nak_once } {
			set msn6ft_test_nak_once 0
			SendFileToSock $sock
		} 

		catch { puts -nonewline $sock  "[binary format i [string length $out]]$out" }
	
#		status_log "Sending : $out"

		if { ($DataSize - $Offset) == 0} {
			catch { close $fd }
			::amsn::FTProgress fs $sid ""
		}

		return [expr {$DataSize - $Offset}]
	}


	proc GotFileTransferRequest { chatid dest branchuid cseq uid sid context } {
		global HOME
		binary scan [string range $context 0 3] i size
		binary scan [string range $context 8 11] i filesize
		binary scan [string range $context 16 19] i nopreview

		set filename [FromUnicode [string range $context 20 569]]

		#binary scan $filename A* filename  <-- destroys encoding

		set idx [string first "\x00" $filename]
		if {$idx != -1 } {
			set filename [string range $filename 0 [expr {$idx - 1}]]
		}

		if { $nopreview == 0 } {
			set previewdata [string range $context $size end]
			set dir [file join $HOME FT cache]
			create_dir $dir
			set fd [open "[file join $dir ${sid}.png ]" "w"]
			fconfigure $fd -translation binary
			puts -nonewline $fd "$previewdata"
			close $fd
			set file [file join $dir ${sid}.png]
			if { $file != "" && ![catch {set img [image create photo [TmpImgName] -file $file]} res]} {
				::skin::setPixmap FT_preview_${sid} "[file join $dir ${sid}.png]"			
			}
			catch {image delete $img}
		}
		setObjOption $sid chatid $chatid

		status_log "context : $context \n size : $size \n filesize : $filesize \n nopreview : $nopreview \nfilename : $filename\n"
		::MSNFT::invitationReceived $filename $filesize $sid $chatid $dest 1
		SendMessageFIFO [list ::amsn::GotFileTransferRequest $chatid $dest $branchuid $cseq $uid $sid $filename $filesize] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

	}

	proc answerFTInvite { sid chatid branchid conntype } {

		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 -1 -1 -1 -1 -1 "$branchid" ]
		set session [::MSNP2P::SessionList get $sid]
		set dest [lindex $session 3]
		set callid [lindex $session 5]

		set conntype [abook::getDemographicField conntype]

		set listening [abook::getDemographicField listening]

		if {$listening == "true" } {
			set nonce "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
			set port [OpenMsnFTPort [config::getKey initialftport] $nonce $sid 0]
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

		status_log "sending 200 OK packet for FT"
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

	}



	#//////////////////////////////////////////////////////////////////////////////
	# AcceptFT ( chatid dest branchuid cseq uid sid filename1 )
	# This function is called when a file transfer is accepted by the user
	proc AcceptFT { chatid dest branchuid cseq uid sid filename1 } {
		# Let's open the file
		set filename [file join [::config::getKey receiveddir] $filename1]

		set origfile $filename
		set incompl "incomplete"

		set num 1
		while { [file exists $filename] || [file exists $filename.$incompl] } {
			set filename "[filenoext $origfile] $num[fileext $origfile]"
			#set filename "$origfile.$num"
			incr num
		}

		status_log "Saving to file $filename\n" green
		set filename $filename.$incompl

		# If we can't create the file notify the user and reject the FT request
		if {[catch {open $filename w} fileid]} {
			# Cannot create this file. Abort.
			status_log "Could not saved the file '$filename' (write-protected target directory?)\n" red
			RejectFT $chatid $sid $branchuid $uid
			::amsn::infoMsg [trans readonlymsgbox] warning
			return
		}

		fconfigure $fileid -translation binary
		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 -1 -1 $fileid -1 $filename -1]

		# Let's make and send a 200 OK Message
		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr {$cseq + 1}] $uid 0 0 $sid]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
		::amsn::FTProgress a $sid $filename $dest 1000 $chatid
		status_log "MSNP2P | $sid -> Sent 200 OK Message for File Transfer\n" red
	}

	#//////////////////////////////////////////////////////////////////////////////
	# CancelFT ( chatid sid )
	# This function is called when a file transfer is canceled by the user
	proc CancelFT { chatid sid } {
		set session_data [::MSNP2P::SessionList get $sid]
		set user_login [lindex $session_data 3]

		status_log "MSNP2P | $sid -> User canceled FT, sending BYE to chatid : $chatid and SB : [::MSN::SBFor $chatid]\n" red
		# Change sid type to canceledft
		::MSNP2P::SessionList set $sid [list -1 0 0 -1 "BYE" -1 -1 "ftcanceled" -1 -1]
		#Make packet shouldn't get from the sessionlist the fileds so I pass to it a null sid
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid [::MSNP2P::MakeMSNSLP "BYE" $user_login [::config::getKey login] "19A50529-4196-4DE9-A561-D68B0BF1E83F" 0 [lindex $session_data 5] 0 0] 1]
		::amsn::FTProgress ca $sid [lindex [::MSNP2P::SessionList get $sid] 6]
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

# all audio/video functions go here
namespace eval ::MSNAV {
	namespace export invitationReceived acceptInvite cancelSession readAccept

	#//////////////////////////////////////////////////////////////////////////////
	# CookieList (action cookie [varlist])
	# Data Structure for MSNAV Sessions, contains :
	# 0 - Local Session ID
	# 1 - Did we invite? 1 if yes, 0 if no
	# 2 - Type of session either A or AV
	# 2 - Remote Session ID		will see if i need
	# 3 - Local port		will see if i need
	# 4 - Remote port		will see if i need
	#
	# action can be :
	#	get : This method returns a list with all the array info, 0 if non existent
	#	set : This method sets the variables for the given cookie, takes a list as argument.
	#	unset : This method removes the given cookie variables
	proc CookieList {action cookie {varlist ""} } {
		variable LocalSID
		variable Invite
		variable Type

		switch -- $action {
			get {
				if { [info exists LocalSID($cookie)] } {
					# Session found, return values
					return [list $LocalSID($cookie) $Invite($cookie) $Type($cookie)]
				} else {
					# Session not found, return 0
					return 0
				}
			}

			set {
				# This overwrites previous vars if they are set to something else than -1
				if { [lindex $varlist 0] != -1 } {
					set LocalSID($cookie) [lindex $varlist 0]
				}
				if { [lindex $varlist 1] != -1 } {
					set Invite($cookie) [lindex $varlist 1]
				}
				if { [lindex $varlist 2] != -1 } {
					set Type($cookie) [lindex $varlist 2]
				}
			}

			unset {
				if { [info exists LocalSID($cookie)] } {
					unset LocalSID($cookie)
				} else {
					status_log "Trying to unset LocalSID($cookie) but do not exist\n" red
				}
				if { [info exists Invite($cookie)] } {
					unset Invite($cookie)
				} else {
					status_log "Trying to unset Invite($cookie) but do not exist\n" red
				}
				if { [info exists Type($cookie)] } {
					unset Type($cookie)
				} else {
					status_log "Trying to unset Type($cookie) but do not exist\n" red
				}
			}
		}
	}

	#//////////////////////////////////////////////////////////////////////////////
	# invitationReceived ( cookie context chatid fromlogin )
	# This function is called when we received an A/V invitation
	# cookie :		invitation cookie
	# context:		Requested:SIP_A,SIP_V;Capabilities:SIP_A,SIP_V;
	# dosen't return nothing
	proc invitationReceived {cookie context chatid fromlogin} {

		# Now we write the request to the screen
		set fromname [::abook::getDisplayNick $fromlogin]

		# Let's get the requested part from our context
		set idx [expr [string first "Capabilities:" $context] - 1]
		set requested [string range $context 0 $idx]

		status_log "requested: $requested\n"

		# Check if it's Audio only or AV
		if { [string first "SIP_V" $requested] == -1 } {
			set txt [trans agotinvitation $fromname]
			CookieList set $cookie [list 0 0 "A"]
		} else {
			set txt [trans avgotinvitation $fromname]
			CookieList set $cookie [list 0 0 "AV"]
		}

		set win_name [::ChatWindow::MakeFor $chatid $txt $fromlogin]
		if { [OnDarwin] } {
			::amsn::WinWrite $chatid "\nAudio/Video requests are not supported on Mac OS X, only Webcam" green
			return
		}
		::amsn::WinWrite $chatid "\n----------\n" green
		::amsn::WinWrite $chatid $txt green
		::amsn::WinWrite $chatid " - (" green
		::amsn::WinWriteClickable $chatid "[trans accept]" "::MSNAV::acceptInvite $cookie [list $requested] $chatid" avyes$cookie
		::amsn::WinWrite $chatid " / " green
		::amsn::WinWriteClickable $chatid "[trans reject]" "::MSNAV::cancelSession $cookie [list $requested] $chatid" avno$cookie
		::amsn::WinWrite $chatid ")\n" green
		::amsn::WinWrite $chatid "----------" green



		#::MSNAV::acceptInvite $cookie [list $requested] $chatid
	}

	#//////////////////////////////////////////////////////////////////////////////
	# acceptInvite ( cookie requested chatid )
	# This function is called when we the user accepts an A/V invitation
	# cookie :		invitation cookie
	# requested :		Requested:SIP_A,SIP_V;
	# dosen't return nothing
	proc acceptInvite {cookie requested chatid} {

		# let's fix the visuals
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		[::ChatWindow::GetOutText ${win_name}] tag configure avyes$cookie \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind avyes$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avyes$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avyes$cookie <<Button1>> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure avno$cookie \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr

		set txt [trans avaccepted]

		SendMessageFIFO [list ::MSNAV::DisplayTxt $chatid $txt] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"

		# We accepted let's init linphone
		set type [lindex [CookieList get $cookie] 2]
		if { [prepareLinphone $chatid $type] == -1 } {
			# Remove the catch here.. I added it because I'm too lazy to
			# test if I made an error in the syntax or anything..
			catch {cancelSession $cookie $chatid USER_CANCELED}
			return
		}

		# Let's send our accept
		acceptInvitationPacket $cookie $requested $chatid
	}

	#//////////////////////////////////////////////////////////////////////////////
	# sendAcceptPacket ( cookie requested chatid )
	# This function makes and sends the acceptance packet of an A/V invitation
	# cookie :		invitation cookie
	# requested:		Requested:SIP_A,SIP_V;
	# returns -1 if something is missing
	proc acceptInvitationPacket {cookie requested chatid} {

		set sessionid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		CookieList set $cookie [list $sessionid -1 -1]

		# we need the connection type
		set conntype [::abook::getDemographicField conntype]
		if { $conntype == "" } {
			return -1
		}
		#set conntype "DIRECT-CONNECT"

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
		set msg "${msg}Invitation-Command: ACCEPT\r\n"
		set msg "${msg}Context-Data: $requested\r\n"
		set msg "${msg}Invitation-Cookie: $cookie\r\n"
		set msg "${msg}Session-ID: {$sessionid}\r\n"
		set msg "${msg}Session-Protocol: SM1\r\n"

		set msg "${msg}[MakeConnType $conntype]"

		set msg "${msg}Launch-Application: TRUE\r\n"
		set msg "${msg}Request-Data: IP-Address:\r\n"
		set msg "${msg}[MakeIP]"

		set msg [encoding convertto utf-8 $msg]
		set msg_len [string length $msg]

		::MSN::WriteSBNoNL [::MSN::SBFor $chatid] "MSG" "A $msg_len\r\n$msg"

	}

	#//////////////////////////////////////////////////////////////////////////////
	# cancelSession ( cookie chatid code)
	# This function cancels the A/V session of the given cookie
	# cookie :		session cookie
	# code :		the cancel code (TIMEOUT, REJECT, ..what else)
	# returns nothing
	proc cancelSession {cookie chatid code}	{

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		# Disable accept/Cancel
		[::ChatWindow::GetOutText ${win_name}] tag configure avyes$cookie \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind avyes$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avyes$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avyes$cookie <<Button1>> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure avno$cookie \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <<Button1>> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr


		# Show on screen
		set txt [trans avcanceled]

		SendMessageFIFO [list ::MSNAV::DisplayTxt $chatid $txt] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"


		set conntype [::abook::getDemographicField conntype]
		#set conntype "Direct-Connect"

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
		set msg "${msg}Invitation-Command: CANCEL\r\n"
		#set msg "${msg}Cancel-Code: $code\r\n"
		set msg "${msg}Cancel-Code: USER_CANCEL\r\n"
		set msg "${msg}Invitation-Cookie: $cookie\r\n"
		set msg "${msg}Session-ID: {[lindex [CookieList get $cookie] 0]}\r\n"

		set msg "${msg}[MakeConnType $conntype]"

		set msg [encoding convertto utf-8 $msg]
		set msg_len [string length $msg]

		::MSN::WriteSBNoNL [::MSN::SBFor $chatid] "MSG" "A $msg_len\r\n$msg"

		# kill linphone
		catch { lp_terminate_dialog }
		catch { lp_uninit }

		CookieList unset $cookie
	}

	#Used to diplay text on chatid's conversation : created for avoid interleaving in convo
	proc DisplayTxt {chatid txt} {
		::amsn::WinWrite $chatid "\n----------\n" green
		::amsn::WinWrite $chatid " $txt\n" green
		::amsn::WinWrite $chatid "----------" green
	}

	#//////////////////////////////////////////////////////////////////////////////
	# readAccept ( cookie ip chatid )
	# This function handles Accepts, there can be 2 kinds of ACCEPT
	# we receive an ACCEPT after we invite
	# we receive an ACCEPT after we accept a remote invitation
	# cookie :		session cookie
	# ip :			ip that shows on the ACCEPT
	# returns nothing
	proc readAccept {cookie ip chatid} {

		# let's check our type
		if { [lindex [CookieList get $cookie] 1] == 0 } {
			# ok this is a 2nd accept

			# now connect to him
			lp_invite "<sip:${ip}>"
		} else {
			# ok so we invited, and this is his ACCEPT to our invite
			# we need to send our own accept

			# get our session id
			set sessionid [lindex [CookieList get $cookie] 0]

			# we need the connection type
			set conntype [::abook::getDemographicField conntype]
			#set conntype "Direct-Connect"
			if { $conntype == "" } {
				return -1
			}

			set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
			set msg "${msg}Invitation-Command: ACCEPT\r\n"
			set msg "${msg}Invitation-Cookie: $cookie\r\n"
			set msg "${msg}Session-ID: {$sessionid}\r\n"

			set msg "${msg}[MakeConnType $conntype]"

			set msg "${msg}Launch-Application: TRUE\r\n"

			set msg "${msg}[MakeIP]"

			set msg [encoding convertto utf-8 $msg]
			set msg_len [string length $msg]

			::MSN::WriteSBNoNL [::MSN::SBFor $chatid] "MSG" "A $msg_len\r\n$msg"
		}
	}

	proc inviteComputerCall { chatid } {

		# make new sessionid
		set sessionid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		# make new cookie
		set cookie [expr {([clock clicks]) % (65536 * 8)}]

		CookieList set $cookie [list $sessionid 1 "voice"]

		# we need the connection type
		set conntype [::abook::getDemographicField conntype]
		if { $conntype == "" } {
			return -1
		}
		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
		set msg "${msg}Application-Name: a Computer Call\r\n"
		set msg "${msg}Application-GUID: {02D3C01F-BF30-4825-A83A-DE7AF41648AA}\r\n"
		set msg "${msg}Session-Protocol: SM1\r\n"

		set msg "${msg}Context-Data: Requested:SIP_A,;Capabilities:SIP_A,;\r\n"

		set msg "${msg}Invitation-Command: INVITE\r\n"
		set msg "${msg}Invitation-Cookie: $cookie\r\n"
		set msg "${msg}Session-ID: {$sessionid}\r\n"
	
		set msg "${msg}Conn-Type: $conntype\r\n"
		set msg "${msg}Sip-Capability: 0\r\n"

		# I don't really know what other conn types there are and what to do
		# TODO test with other types of connections that direct and IP-Restricted-NAT
		if { $conntype == "IP-Restrict-NAT" } {
			set msg "${msg}Private-IP: [::abook::getDemographicField localip]\r\n"
			set msg "${msg}Public-IP: [::abook::getDemographicField clientip]\r\n"
			set msg "${msg}UPnP: [abook::getDemographicField upnpnat]\r\n"
		}

		set msg [encoding convertto utf-8 $msg]
		set msg_len [string length $msg]

		::MSN::WriteSBNoNL [::MSN::SBFor $chatid] "MSG" "S $msg_len\r\n$msg"

	}

	proc acceptComputerCall { chatid cookie } {
		set conntype [::abook::getDemographicField conntype]
		set msg "Invitation-Command: ACCEPT\r\n"
		append msg "Context-Data: Requested:SIP_A,;Capabilities:SIP_A,;\r\n"
		append msg "Invitation-Cookie: 374836\r\n"
		append msg "Session-ID: {A4EE9D51-A7CA-4CD4-90EC-B234285B6D2F}\r\n"
		append msg "Session-Protocol: SM1\r\n"
		append msg "Conn-Type: Symmetric-NAT\r\n"
		append msg "Sip-Capability: 1\r\n"
		append msg "Public-IP: 65.210.205.254\r\n"
		append msg "Private-IP: 10.27.95.174\r\n"
		append msg "UPnP: FALSE\r\n"
		append msg "Launch-Application: TRUE\r\n"
		append msg "UsingRendezvous: FALSE\r\n"
		append msg "Request-Data: IP-Address:\r\n"
		append msg "IP-Address: 10.27.95.174:8348\r\n"
		append msg "IP-Address-Enc64: MTAuMjcuOTUuMTc0OjgzNDg=\r\n"

	}

	#//////////////////////////////////////////////////////////////////////////////
	# inviteAV ( chatid type )
	# This function creates new invitations for A/V
	# chatid :		chatid to send invitation to
	# type :		A, AV
	# returns nothing
	proc inviteAV { chatid type } {

		if { [prepareLinphone $chatid $type] == -1 } {
			return
		}

		# make new sessionid
		set sessionid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		# make new cookie
		set cookie [expr {([clock clicks]) % (65536 * 8)}]

		CookieList set $cookie [list $sessionid 1 $type]

		# we need the connection type
		set conntype [::abook::getDemographicField conntype]
		if { $conntype == "" } {
			return -1
		}
		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
		set msg "${msg}Application-Name: an audio conversation\r\n"
		set msg "${msg}Application-GUID: {02D3C01F-BF30-4825-A83A-DE7AF41648AA}\r\n"
		set msg "${msg}Session-Protocol: SM1\r\n"

		if { $type == "A" } {
			set msg "${msg}Context-Data: Requested:SIP_A,;Capabilities:SIP_A,SIP_V,;\r\n"
		} else {
			set msg "${msg}Context-Data: Requested:SIP_A,SIP_V,;Capabilities:SIP_A,SIP_V,;\r\n"
		}

		set msg "${msg}Invitation-Command: INVITE\r\n"
		set msg "${msg}Invitation-Cookie: $cookie\r\n"
		set msg "${msg}Session-ID: {$sessionid}\r\n"

		set msg "${msg}[MakeConnType $conntype]"

		set msg [encoding convertto utf-8 $msg]
		set msg_len [string length $msg]

		::MSN::WriteSBNoNL [::MSN::SBFor $chatid] "MSG" "S $msg_len\r\n$msg"

	}


	proc MakeConnType { conntype } {
		#set conntype "Direct-Connect"
		set msg "Conn-Type: $conntype\r\n"
		set msg "${msg}Sip-Capability: 1\r\n"

		# I don't really know what other conn types there are and what to do
		# TODO test with other types of connections that direct and IP-Restricted-NAT
		if { $conntype == "IP-Restrict-NAT" } {
			set msg "${msg}Private-IP: [::abook::getDemographicField localip]\r\n"
			set msg "${msg}Public-IP: [::abook::getDemographicField clientip]\r\n"
			set msg "${msg}UPnP: [abook::getDemographicField upnpnat]\r\n"
		}

		return $msg
	}

	proc MakeIP { } {
		set msg "IP-Address: [::abook::getDemographicField clientip]:5060\r\n"
		set msg "${msg}IP-Address-Enc64: [::base64::encode [::abook::getDemographicField clientip]:5060 ]\r\n\r\n"
		#set msg "IP-Address: [::abook::getDemographicField localip]:5060\r\n"
		#set msg "${msg}IP-Address-Enc64: [::base64::encode [::abook::getDemographicField localip]:5060 ]\r\n\r\n"

		return $msg
	}

	proc prepareLinphone { chatid type } {
		if { [LoadExtension] == 0 } {
			DisplayError $chatid
			return -1
		}
		catch { lp_init } res
		# Check if init works good
		if { $res == -1 } {
			DisplayError $chatid
			return -1
		}

		if { $type == "A" } {
			lp_disable_video
			lp_show_local_video 0
		} else {
			status_log "laaaaaaaaaaaaaaaaaaa"
			lp_enable_video
			lp_show_local_video 1
		}

		lp_set_sip_port 5060
		lp_set_audio_port 7078
		lp_set_video_port 9078
		lp_set_primary_contact "sip:myusername@myhostname"
		lp_set_nat_address [::abook::getDemographicField clientip]
		#lp_set_nat_address [::abook::getDemographicField localip]
	}

	proc LoadExtension { } {
		if { [ExtensionLoaded] == 0 } {
			catch { load plugins/linphone/linphone.so}
		}
		return [ExtensionLoaded]
	}

	proc ExtensionLoaded { } {
		foreach lib [info loaded] {
			if { [lindex $lib 1] == "Linphone" } {
				return 1
			}
		}
		return 0
	}

	proc DisplayError { chatid } {
		#display error
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		# Show on screen
		set txt [trans avinitfailed]

		SendMessageFIFO [list ::MSNAV::DisplayTxt $chatid $txt] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
	}

}


namespace eval ::MSNMobile {
	namespace export IsMobile MessageSend MessageReceived OpenMobileWindow

	variable user2chatid

	proc IsMobile { chatid } {

		if { [string first "@" $chatid] != [string last "@" $chatid] &&
			 [string first "mobile@" $chatid] == 0 } {
			return 1
		} else {
			return 0
		}
	}

	proc MessageSend { chatid txt } {

		set name [string range $chatid 7 end]

		set msg "<TEXT xml:space=\"preserve\" enc=\"utf-8\">$txt</TEXT>"

		set msglen [string length $msg]
		#set plen [string length $msg]
		::MSN::WriteSBNoNL ns "PGD" "$name 1 $msglen\r\n$msg"

		if {[::config::getKey keep_logs]} {
			::log::PutLog $chatid [::abook::getPersonal login] $txt
		}
	}

	proc MessageReceived { data } {

		status_log "Got data : $data" red

		set xml [xml2list $data]
		
		set msg [GetXmlEntry $xml "NOTIFICATION:MSG:BODY:TEXT"]
		set user [GetXmlAttribute $xml "NOTIFICATION:FROM" name]

		set chatid [GetChatId $user]

		if { $chatid == 0 } {
			OpenMobileWindow $user
			set chatid [GetChatId $user]
		}

		status_log "Writing mobile msg \"$msg\" on : $chatid\n" red
		::amsn::WinWrite $chatid "\n[timestamp] [trans mobilesays $user] : \n" says
		::amsn::WinWrite $chatid "$msg" user

		if {[::config::getKey keep_logs]} {
			::log::PutLog $chatid $user $msg
		}

	}


	proc OpenMobileWindow { user } {
		set chatid [GetChatId $user]
		status_log "opening chat window for mobile messaging : $chatid\n" red

		if { $chatid == 0 } {
			set win [::ChatWindow::Open]
			set chatid "mobile@$user"
			::ChatWindow::SetFor $chatid $win
			SetChatId $user $chatid
			after 200 "::MSNMobile::UpdateWindow $win $user"
			
			if { [winfo exists .bossmode] } {
			set ::BossMode(${win_name}) "normal"
			wm state $win withdraw
			} else {
			wm state $win normal
			}

			wm deiconify $win
		} else {
			set win [::ChatWindow::For $chatid]
			if { [winfo exists .bossmode] } {
			set ::BossMode(${win_name}) "normal"
			wm state $win withdraw
			} else {
			wm state $win normal
			}

			wm deiconify $win
			focus $win
		}
	}

	proc UpdateWindow { win_name user_login } {
		set top [::ChatWindow::GetTopFrame $win_name]
		if { ![winfo exists $top] } { return }

		$top itemconfigure to -text "[trans tomobile]:"
		
		set toX [::skin::getKey topbarpadx]
		set usrsX [expr {$toX + [font measure bplainf -displayof $top "[trans tomobile]:"] + 5}]
		set txtY [::skin::getKey topbarpady]
		
		$top coords text $usrsX [lindex [$top coords text] 1]

		set title "[trans tomobile] : $user_login"

		set user_name [string map {"\n" " "} [::abook::getDisplayNick $user_login]]
		set state_code [::abook::getVolatileData $user_login state]

		if { $state_code == "" } {
			set user_state ""
			set state_code FLN
		} else {
			set user_state [::MSN::stateToDescription $state_code]
		}

		set user_image [::MSN::stateToImage $state_code]

		$top dchars text 0 end
		if {[::config::getKey truncatenames]} {
			#Calculate maximum string width
			set maxw [expr { 0 - int([lindex [$top coords text] 0])}]

			if { "$user_state" != "" && "$user_state" != "online" } {
			incr maxw [expr {0-[font measure sboldf -displayof $top " \([trans $user_state]\)"]}]
			}

			incr maxw [expr {[winfo width $top] - [::skin::getKey topbarpadx] -[font measure sboldf -displayof $top " <${user_login}>"]}]

			$top insert text end "[trunc ${user_name} ${win_name} $maxw sboldf] <${user_login}>"
		} else {
			$top insert text end "${user_name} <${user_login}>"
		}

		#TODO: When we have better, smaller and transparent images, uncomment this

		if { "$user_state" != "" && "$user_state" != "online" } {
			$top insert text end "\([trans $user_state]\)"
		}
		$top insert text end "\n"


		#Change color of top background by the status of the contact
		::ChatWindow::ChangeColorState $user_login $user_state $state_code ${win_name}


		#Calculate number of lines, and set top text size
		set size [$top index text end]
		
		set ::ChatWindow::titles(${win_name}) ${title}

		$top dchars text [expr {$size - 1}] end

		$top configure -height [expr {[::ChatWindow::MeasureTextCanvas $top "text" "h"] + 2*[::skin::getKey topbarpady]}]

		if { [info exists ::ChatWindow::new_message_on(${win_name})] && $::ChatWindow::new_message_on(${win_name}) == 1 } {
			wm title ${win_name} "*${title}"
		} else {
			wm title ${win_name} ${title}
		}
		update idletasks
		after cancel "::MSNMobile::UpdateWindow $win_name $user_login"

		after 5000 "::MSNMobile::UpdateWindow $win_name $user_login"
	}

	proc GetChatId { user } {
		variable user2chatid
		if { [info exists user2chatid($user)] } {
			set chatid [set user2chatid($user)]
			set win [::ChatWindow::For $chatid]
			if {$win != 0 && [winfo exists $win] } {
			return $chatid
			} else {
			unset user2chatid($user)
			return 0
			}
		} else {
			return 0
		}
	}

	proc SetChatId { user chatid } {
		variable user2chatid
		set user2chatid($user) $chatid
	}


}

