
::Version::setSubversionId {$Id$}

::snit::type P2PMessage {

	option -sessionid
	option -identifier
	option -offset
	option -totalsize
	option -datalength
	option -flag
	option -ackid
	option -ackuid
	option -acksize
	variable headers
	variable body ""

	constructor {args} {
		#TODO: remove me when object is destroyed in the right place
		#DONE (hopefully)
		#after 30000 $self destroy
	}

	#creates a P2PMessage object from a normal Message object
	method createFromMessage { message } {
		#		array set headers [$message getHeaders]
		#		set data [$message getBody]
		#		set idx [string first "\r\n\r\n" $data]
		#		set head [string range $data 0 [expr $idx -1]]
		##		set body [string range $data [expr $idx +4] end]
		set body [$message getBody]
		#		set head [string map {"\r" ""} $head]
		#		set heads [split $head "\n"]
		#		foreach header $heads {
		#			set idx [string first ": " $header]
		#			array set headers [list [string range $header 0 [expr $idx -1]] \
		    #					  [string range $header [expr $idx +2] end]]
		#		}
		set ret [binary scan [string range $body 0 48] iiiiiiiiiiii cSid cId cOffset1 cOffset2 cTotalDataSize1 cTotalDataSize2 cMsgSize cFlags cAckId cAckUID cAckSize1 cAckSize2]
		if {$ret != 12} {
			error "Not enough data to scan header"
		}
		set body [string range $body 48 end]
		set options(-sessionid) $cSid
		set options(-identifier) $cId
		set options(-offset) [int2word $cOffset1 $cOffset2]
		set options(-totalsize) [int2word $cTotalDataSize1 $cTotalDataSize2]
		set options(-datalength) $cMsgSize
		set options(-flag) $cFlags
		set options(-ackid) $cAckId
		set options(-ackuid) $cAckUID
		set options(-acksize) [int2word $cAckSize1 $cAckSize2]
	}

	method toString { {humanReadable 0} } {
		set str ""
		foreach { header info } [array get headers] {
			set str "$str$header: $info\r\n"
		}
		set str "$str\r\n\r\n"
		if { $humanReadable } {
			set str "${str}sessionid: $options(-sessionid)\n"
			set str "${str}identifier: $options(-identifier)\n"
			set str "${str}offset: $options(-offset)\n"
			set str "${str}totalsize: $options(-totalsize)\n"
			set str "${str}datalength: $options(-datalength)\n"
			set str "${str}flag: $options(-flag)\n"
			set str "${str}ackid: $options(-ackid)\n"
			set str "${str}ackuid: $options(-ackuid)\n"
			set str "${str}acksize: $options(-acksize)\n"
		} else {
			#TODO
		}
		set str "$str$body"
		return $str
	}


	#	proc ReadData { message chatid } {
	#		variable chunkedData
	#		# Get values from the header
	##		set idx [expr [string first "\r\n\r\n" $data] + 4]
	##		set headend [expr $idx + 48]
	#		set data [$message getBody]
	#
	#	        binary scan [string range $data 0 48] iiiiiiiiiiii cSid cId cOffset1 cOffset2 cTotalDataSize1 cTotalDataSize2 cMsgSize cFlags cAckId cAckUID cAckSize1 cAckSize2
	#
	#	        set cOffset [int2word $cOffset1 $cOffset2]
	#	        set cTotalDataSize [int2word $cTotalDataSize1 $cTotalDataSize2]
	#   	        set cAckSize [int2word $cAckSize1 $cAckSize2]
	#
	#		#status_log "Read header : $cSid $cId $cOffset $cTotalDataSize $cMsgSize $cFlags $cAckId $cAckUID $cAckSize\n" red
	#		#status_log "Sid : $cSid -> " red
	#
	#		if {$cSid == "0" && $cMsgSize != "0" && $cMsgSize != $cTotalDataSize } {
	#
	#			if { ![info exists chunkedData($cId)] } {
	#				set chunkedData($cId) "[string range $data 48 end-4]"
	#			} else {
	#				set chunkedData($cId) "$chunkedData($cId)[string range $data 48 end-4]"
	#			}
	#			#status_log "Data is now : $chunkedData($cId)\n\n";
	#
	#			if { $cTotalDataSize != [string length $chunkedData($cId)] } {
	#				return
	#			} else {
	#				set data $chunkedData($cId)
	#				set headend 0
	#				set cMsgSize $cTotalDataSize
	#			}
	#
	#		}
	#	}








	method getBody { } {
		return $body
	}

	method getHeader { name } {
		return [lindex [array get headers $name] 1]
	}
}

namespace eval ::MSNP2P {
	namespace export loadUserPic SessionList ReadData MakePacket MakeACK MakeSLP


	#Get picture from $user, if cached, or sets image as "loading", and request it
	#using MSNP2P
	proc loadUserPic { chatid user {reload "0"} } {
		global HOME

		#Line below changed from != -1 to == 0 because -1 means 
		#"enabled but imagemagick unavailable"
		if { [::config::getKey getdisppic] == 0 } {
			status_log "Display Pics disabled, exiting loadUserPic\n" red
			return
		} 
		# For MSNP16, don't get our own DP since opening an SB with ourselves is now possible
		if {$user == [::config::getKey login] } {
			status_log "Trying to download DP from ourself.. skipping" red
			return
		}

		#status_log "::MSNP2P::GetUser: Checking if picture for user $user exists\n" blue

		set msnobj [::abook::getVolatileData $user msnobj]

		#status_log "::MSNP2P::GetUser: MSNOBJ is $msnobj\n" blue

		#set filename [::MSNP2P::GetFilenameFromMSNOBJ $msnobj]
		set filename [::abook::getContactData $user displaypicfile ""]
		status_log "::MSNP2P::GetUser: filename is $filename\n" white

		if { $filename == "" } {
			return
		}

		#Reload 1 means that we force aMSN to reload a new display pic
		#Destroy it before to avoid TkCxImage to redraw animated gif above the good display pic
		#TODO: FIX: I think the next line is incorrect, did you want image delete? (be careful if there are images on the screen)
		destroy user_pic_$user
		if { ![file readable "[file join $HOME displaypic cache $user ${filename}].png"] || $reload == "1" } {
			status_log "::MSNP2P::GetUser: FILE [file join $HOME displaypic cache $user ${filename}] doesn't exist!!\n" white
			image create photo user_pic_$user -file [::skin::GetSkinFile "displaypic" "loading.gif"] -format cximage

			#if the small picture (for notifications e.g.) already exists, change it
			if { [ImageExists displaypicture_not_$user] } {
			
				status_log "User DP Changed, recreating small image as it already exist"
				
				#clear it first before overwriting
				displaypicture_not_$user blank
				#if there is no problem copying, it's OK, we resize it if bigger then 50x50
				if {![catch {displaypicture_not_$user copy user_pic_$user}]} {
					if {[image width displaypicture_not_$user] > 50 || [image height displaypicture_not_$user] > 50} {
						::picture::ResizeWithRatio displaypicture_not_$user 50 50
					}
				} else {
					image delete displaypicture_not_$user
				}
			}				

			create_dir [file join $HOME displaypic]
			create_dir [file join $HOME displaypic cache]
			create_dir [file join $HOME displaypic cache $user]
			::MSNP2P::RequestObject $chatid $user $msnobj
		} else {
			::skin::getDisplayPicture $user 1	
		}
		# launch an event for plugins
		set evPar(user) $user
		::plugins::PostEvent ChangeDP evPar
	}

	proc loadUserSmiley { chatid user msnobj } {
		global HOME

		set filename [::MSNP2P::GetFilenameFromMSNOBJ $msnobj]

		status_log "Got filename $filename for $chatid with $user and $msnobj\n" red

		if { $filename == "" } {
			return
		}

		image create photo emoticonCustom_std_$filename -width 19 -height 19

		status_log "::MSNP2P::GetUserPic: filename is $filename\n" white

		if { [catch {image create photo emoticonCustom_std_$filename -file "[file join $HOME smileys cache ${filename}].png" -format cximage}] } {
			#We didn't manage to load the smiley (either we haven't it either it's bad) so we ask it
			status_log "::MSNP2P::GetUser: FILE [file join $HOME smileys cache ${filename}] doesn't exist!!\n" white
			image create photo emoticonCustom_std_$filename -width 19 -height 19

			create_dir [file join $HOME smileys]
			create_dir [file join $HOME smileys cache]
			if { [::abook::getContactData $user showcustomsmileys] != 0 } { ::MSNP2P::RequestObject $chatid $user $msnobj }
		} else {
			# Make sure the smiley is max 50x50
			if {[::config::getKey big_incoming_smileys 0] == 0} {
				::smiley::resizeCustomSmiley emoticonCustom_std_${filename}
			}
		}
	}


	proc GetFilenameFromMSNOBJ { msnobj } {
		set sha1d [split $msnobj " "]
		set idx [lsearch $sha1d "SHA1D=*"]
		set sha1d [lindex $sha1d $idx]
		set sha1d [string range $sha1d 7 end-1]
		if { $sha1d == "" } {
			return ""
		}
		#return [::md5::md5 $sha1d]
		binary scan $sha1d h* filename
		return $filename
	}

	proc GetFilenameFromContext { context } {
		global msnobjcontext

		set old_msnobj [::base64::decode $context]
		set msnobj [string range $old_msnobj [string first "<" $old_msnobj] [expr {[string first "/>" $old_msnobj] + 1}]]

		status_log "GetFilenameFromContext : $context == $old_msnobj == $msnobj\n[string first "<" $old_msnobj] - [string first "/>"  $old_msnobj]\n\n" red
		if { [info exists msnobjcontext($msnobj)] } {
			status_log "Found filename\n" red
			return $msnobjcontext($msnobj)
		} else {
			status_log "Couln't find filename for context \n$context\n = $msnobj --- [array get msnobjcontext] --[info exists msnobjcontext($msnobj)] \n" red
			return ""
		}


	}

	#//////////////////////////////////////////////////////////////////////////////
	# SessionList (action sid [varlist])
	# Data Structure for MSNP2P Sessions, contains :
	# 0 - Message Identifier	(msgid)
	# 1 - TotalDataSize		(totalsize) This variable is only used if sending data in split packets
	# 2 - Offset			(offset)
	# 3 - Destination		(dest)
	# 4 - Step to run after ack     (AferAck)   For now can be DATAPREP, SENDDATA
	# 5 - CallID (MSNSLP)		(callid)
	# 6 - File Descriptor		(fd)
	# 7 - Session Type		(type) bicon, emoticon, filetransfer
        # 8 - Filename for transfer     (Filename)
	# 9 - branchid                  (branchid)
	#
	# action can be :
	#	get : This method returns a list with all the array info, 0 if non existent
	#	set : This method sets the variables for the given sessionid, takes a list as argument.
	#	unset : This method removes the given sessionid variables
	#	findid : This method searches all Sessions for one that has the given Identifier, returns session ID or -1 if not found
	#	findcallid : This method searches all Sessions for one that has the given Call-ID, returns session ID or -1 if not found
	proc SessionList { action sid { varlist "" } } {

		switch $action {
			get {
				set ret [getObjOption sl_$sid MsgId] 
				#status_log "getting $sid : [getObjOption $sid MsgId] - $ret" green

				if { $ret != "" } {
					# Session found, return values
					lappend ret [getObjOption sl_$sid TotalSize] 
					lappend ret [getObjOption sl_$sid Offset] 
					lappend ret [getObjOption sl_$sid Destination] 
					lappend ret [getObjOption sl_$sid AfterAck]
					lappend ret [getObjOption sl_$sid CallId] 
					lappend ret [getObjOption sl_$sid Fd]
					lappend ret [getObjOption sl_$sid Type] 
					lappend ret [getObjOption sl_$sid Filename]
					lappend ret [getObjOption sl_$sid branchid]

					#status_log "returning $ret" green
					return $ret
				} else {
					#status_log "Not found" green
					# Session not found, return 0
					return 0
				}
			}

			set {
				#status_log "setting $sid with $varlist" green
				# This overwrites previous vars if they are set to something else than -1
				if { [lindex $varlist 0] != -1 } {
					set MsgsIds [getObjOption sl_${sid} MsgsIds]
					lappend MsgsIds [lindex $varlist 0]
					setObjOption sl_$sid MsgId [lindex $varlist 0]
					setObjOption sl_$sid MsgsIds $MsgsIds
					setObjOption slm_[lindex $varlist 0] sid $sid
				}
				if { [lindex $varlist 1] != -1 } {
					setObjOption sl_$sid TotalSize [lindex $varlist 1]
				}
				if { [lindex $varlist 2] != -1 } {
					setObjOption sl_$sid Offset [lindex $varlist 2]
				}
				if { [lindex $varlist 3] != -1 } {
					setObjOption sl_$sid Destination [lindex $varlist 3]
				}
				if { [lindex $varlist 4] != -1 } {
					setObjOption sl_$sid AfterAck [lindex $varlist 4]
				}
				if { [lindex $varlist 5] != -1 } {
					set CallsIds [getObjOption sl_${sid} CallsIds]
					lappend CallsIds [lindex $varlist 0]
					setObjOption sl_$sid CallId [lindex $varlist 5]
					setObjOption sl_$sid CallsIds $CallsIds
					setObjOption slc_[lindex $varlist 5] sid $sid
				}
				if { [lindex $varlist 6] != -1 } {
					setObjOption sl_$sid Fd [lindex $varlist 6]
				}
				if { [lindex $varlist 7] != -1 } {
					setObjOption sl_$sid Type [lindex $varlist 7]
				}
				if { [lindex $varlist 8] != -1 } {
				        setObjOption sl_$sid Filename [lindex $varlist 8]
				}
				if { [lindex $varlist 9] != -1 } {
				        setObjOption sl_$sid branchid [lindex $varlist 9]
				}
			}

			unset {
				#status_log "unsetting..." green
				set msgsids [getObjOption sl_$sid MsgsIds] 
				set callsids [getObjOption sl_$sid CallsIds] 
				clearObjOption sl_$sid
				foreach msgid $msgsids {
					clearObjOption slm_$msgid
				}
				foreach callid $callsids {
					clearObjOption slc_$callid
				}
				return
			}
			findcallid {
				return [getObjOption slc_$sid sid]
			}
			findid {
				#status_log "Finding $action of $sid, found : [getObjOption $sid sid]" green
				return [getObjOption slm_$sid sid]
			}
		}
	}

	proc SendVoiceClip {chatid file } {
		set sbn [::MSN::SBFor $chatid]
		set msnobj [create_msnobj [::config::getKey login] 11 $file]
		
		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msnmsgr-datacast\r\n\r\nID: 3\r\nData: $msnobj\r\n\r\n"
		set msg_len [string length $msg]
	
		#Send the packet
		::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"

		# Let the magic do the rest... (the INVITE will be sent by the other client requesting the msnobj 
		# created with [create_msnobj] which also links the msnobj to the filename which will be automatically sent)
	}


	#//////////////////////////////////////////////////////////////////////////////
	# ReadData ( data chatid )
	# This is the handler for all received MSNP2P packets
	# data is the MSNP2P packet
	# chatid will be used to get the SB ?? Ack alvaro if it's better to use chatid or some way to use the dest email
	# For now only manages buddy and emoticon transfer
	# TODO : Error checking on fields (to, from, sizes, etc)
	proc ReadData { message chatid } {
		global HOME
		variable chunkedData

		#		set message [P2PMessage create %AUTO%]
		#		$message createFromMessage $msg

		#status_log "called ReadData with $data\n" red

		# Get values from the header
		#		set idx [expr [string first "\r\n\r\n" $data] + 4]
		#		set headend [expr $idx + 48]
		#		set data [$message getBody]

		#	        binary scan [string range $data 0 48] iiiiiiiiiiii cSid cId cOffset1 cOffset2 cTotalDataSize1 cTotalDataSize2 cMsgSize cFlags cAckId cAckUID cAckSize1 cAckSize2

		#	        set cOffset [int2word $cOffset1 $cOffset2]
		#	        set cTotalDataSize [int2word $cTotalDataSize1 $cTotalDataSize2]
		#   	        set cAckSize [int2word $cAckSize1 $cAckSize2]


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

		#status_log "Read header : $cSid $cId $cOffset $cTotalDataSize $cMsgSize $cFlags $cAckId $cAckUID $cAckSize\n$data" red
		

		if {$cSid == "0" && $cMsgSize != "0" && $cMsgSize != $cTotalDataSize } {

			if { ![info exists chunkedData($cId)] } {
				set chunkedData($cId) "[string range $data 0 [expr { $cMsgSize - 1}]]"
			} else {
				set chunkedData($cId) "$chunkedData($cId)[string range $data 0 [expr { $cMsgSize - 1}]]"
			}
			#			status_log "Data is now : $chunkedData($cId)\n\n";
			status_log "chunked data :  $cTotalDataSize - $cMsgSize - $cOffset - [string length $chunkedData($cId)]"

			if { $cTotalDataSize != [expr {$cMsgSize + $cOffset}] } {
				#	status_log "not enough data to complete chunk...$cTotalDataSize - $cOffset - $cMsgSize - [string length $chunkedData($cId)]" 
				return
			} else {
				#status_log "data completed... $cTotalDataSize - $cOffset - [string length $chunkedData($cId)]"
				set data $chunkedData($cId)
				unset chunkedData($cId)
				#				set headend 0
				set cMsgSize $cTotalDataSize
			}

		}

		if { [lindex [SessionList get $cSid] 7] == "ignore" } {
			status_log "MSNP2P | $cSid -> Ignoring packet! not for us!\n"
			return
		}


		# Check if this is an ACK Message
		# TODO : Actually check if the ACK is good ? check size and all that crap...
		if { $cMsgSize == 0 } {
			# Let us check if any of our sessions is waiting for an ACK
			set sid [SessionList findid $cAckId]
			status_log "GOT SID : $sid for Ackid : $cAckId\n"
			if { $sid != -1 } {
				set type [lindex [SessionList get $sid] 7]
				#status_log "TYPE of SID : $type"
				if { $cFlags == 2 } {
					#status_log "MSNP2P | $sid -> Got MSNP2P ACK " red
					if {$type == "game"} {
						::MSNGames::handleACK $sid $cAckId
						return
					}
					
					# We found a session id that is waiting for an ACK
					set step [lindex [SessionList get $sid] 4]

					# Just these 2 for now, will probably need more with file transfers
					switch $step {
						DATAPREP {
							# Set the right variables, prepare to send data after next ack
							SessionList set $sid [list -1 4 0 -1 "SENDDATA" -1 -1 -1 -1 -1]
							
							# We need to send a data preparation message
							SendPacket [::MSN::SBFor $chatid] [MakePacket $sid [binary format i 0]]
							status_log "MSNP2P | $sid -> Sent DATA Preparation\n" red
						}
						SENDDATA {
							#status_log "MSNP2P | $sid -> Sending DATA now\n" red
							set file [lindex [SessionList get $sid] 8]
							if { $file != "" } {
								SendData $sid $chatid "[lindex [SessionList get $sid] 8]"
							} else {
								SendData $sid $chatid "[::skin::GetSkinFile displaypic [PathRelToAbs [::config::getKey displaypic]]]"
							}
						}
						DATASENT {
							SessionList set $sid [list -1 -1 0 -1 "BYE" -1 -1 -1 -1 -1]
							#status_log "MSNP2P | $sid -> Got ACK for sending data, now sending BYE\n" red
							set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
							SendPacket [::MSN::SBFor $chatid] [MakePacket $sid [MakeMSNSLP "BYE" [lindex [SessionList get $sid] 3] [::config::getKey login] "$branchid" "0" [lindex [SessionList get $sid] 5] 0 0] 1]
						
						}
						BYE {
							SessionList unset $sid
						}
					}
				} elseif { $cFlags == 1 } {
					set blobid [getObjOption $sid data_blob_id]
					if {$cAckId == $blobid } {
						status_log "Received a NAK on our data being sent. Need to reposition ourselves... to $cAckSize"
						setObjOption $sid nak_pos $cAckSize
					}
				}
			}
			return
		}

		#status_log "ReadData : data : $data" green
		# Check if this is an INVITE message

		if { [string first "INVITE MSNMSGR" $data] != -1 } {
			#status_log "Got an invitation!\n" red

			# Let's get the session ID, destination email, branchUID, UID, AppID, Cseq
			set idx [expr {[string first "SessionID:" $data] + 11}]
			set idx2 [expr {[string first "\r\n" $data $idx] - 1}]
			set sid [string range $data $idx $idx2]

			set idx [expr {[string first "From: <msnmsgr:" $data] + 15}]
			set idx2 [expr {[string first "\r\n" $data $idx] - 2}]
			set dest [string range $data $idx $idx2]

			set idx [expr {[string first "branch=\{" $data] + 8}]
			set idx2 [expr {[string first "\}" $data $idx] - 1}]
			set branchuid [string range $data $idx $idx2]

			set idx [expr {[string first "Call-ID: \{" $data] + 10}]
			set idx2 [expr {[string first "\}" $data $idx] - 1}]
			set uid [string range $data $idx $idx2]

			set idx [expr {[string first "CSeq:" $data] + 6}]
			set idx2 [expr {[string first "\r\n" $data $idx] - 1}]
			set cseq [string range $data $idx $idx2]

			set idx [expr {[string first "Content-Type: " $data $idx] + 14}]
			set idx2 [expr {[string first "\r\n" $data $idx] - 1}]
			set ctype [string range $data $idx $idx2]

			status_log "Got INVITE with content-type : $ctype\n" red

			if { $ctype == "application/x-msnmsgr-transreqbody"} {

				set sid [SessionList findcallid $uid]
				set type [lindex [SessionList get $sid] 7]

				#this catches an error with MSN7, still need to find out why sid = -1
				if {$sid == -1} {return}
				set idx [expr {[string first "Conn-Type: " $data] + 11}]
				set idx2 [expr {[string first "\r\n" $data $idx] - 1}]
				set conntype [string range $data $idx $idx2]

				set idx [expr {[string first "UPnPNat: " $data] + 9}]
				set idx2 [expr {[string first "\r\n" $data $idx] - 1}]
				set upnp [string range $data $idx $idx2]

				# Let's send an ACK
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]

				if { $type == "filetransfer" } {
					# We received an invite for a FT, send 200 OK
					::MSN6FT::answerFTInvite $sid $chatid $branchuid $conntype
				} elseif { $type == "webcam" } {
					::MSNCAM::answerCamInvite $sid $chatid $branchuid
				} elseif { $type == "game" } {
					::MSNGames::answerGameInvite $sid $chatid $branchuid
				}

			} elseif { $ctype == "application/x-msnmsgr-sessionreqbody" } {

				# Let's check if it's an invitation for buddy icon or emoticon
				set idx [expr {[string first "EUF-GUID:" $data] + 11}]
				set idx2 [expr {[string first "\}" $data $idx] - 1}]
				set eufguid [string range $data $idx $idx2]

				set idx [expr {[string first "Context:" $data] + 9}]
				set idx2 [expr {[string first "\r\n" $data $idx] - 1}]

				if { $idx == 8 || $idx2 == -2 } {
					# Let's send an ACK
					SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
					status_log "MSNP2P | $sid $dest -> Sent ACK for INVITE\n" red

					# Send a 500 Internal Error in case tehre is no context field sent...
					set slpdata [MakeMSNSLP "ERROR" $dest [::config::getKey login] $branchuid [expr {$cseq + 1}] $uid 0 0 $sid]
					SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]
					status_log "MSNP2P | $sid $dest -> Sent 500 Internal error.. No Context field in request\n" red

					# Avoid it entering the next if processing...
					set eufguid ""
				} else {
					set context [string range $data $idx $idx2]
				}

				status_log "$idx $idx2"

				switch -- $eufguid {
					"A4268EEC-FEC5-49E5-95C3-F126696BDBF6" {
						status_log "MSNP2P | $sid $dest -> Got INVITE for buddy icon or emoticon\n" red
						# Buddyicon or emoticon
						set filenameFromContext [GetFilenameFromContext $context]
						if { $filenameFromContext != "" } {
							#status_log "dest = $dest , uid = $uid , sid = $sid"
							if { ! ( $filenameFromContext == [PathRelToAbs [::config::getKey displaypic]] && [::abook::getContactData $dest dontshowdp] == 1 ) } {
								SessionList set $sid [list 0 0 0 $dest 0 $uid 0 "bicon" $filenameFromContext ""]
							} else {
								return ""
							}
						} else {
							status_log "MSNP2P | $sid -> This is not an invitation for us, don't reply.\n" red
							# Now we tell this procedure to ignore all packets with this sid
							SessionList set $sid [list 0 0 0 0 0 0 0 "ignore" 0 ""]
							return
						}
					} 
					"5D3E02AB-6190-11D3-BBBB-00C04F795683" {
						status_log "MSNP2P | $sid $dest -> Got INVITE for  file transfer\n" red
						# File transfer
						#check if a conversation is open with that contact
						#no need to test either a chatwindow has been created or not, because MakeFor is going to do it ! 
						::ChatWindow::MakeFor $chatid
						SessionList set $sid [list 0 0 0 $dest 0 $uid 0 "filetransfer" "" "$branchuid"]
						# Let's send an ACK
						SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
						status_log "MSNP2P | $sid $dest -> Sent ACK for INVITE\n" red

						# Let's get filename and filesize from context
						set idx [expr {[string first "Context:" $data] + 9}]
						set context [base64::decode [string range $data $idx end]]
						::MSN6FT::GotFileTransferRequest $chatid $dest $branchuid $cseq $uid $sid $context
						return

					}
					"E073B06B-636E-45B7-ACA4-6D4B5978C93C" {
						status_log "MSNP2P | $sid $dest -> Got INVITE for a Wink\n" red
						#We received Winks
						status_log "####WINKS RECEIVED####\n" blue
						set decoding [base64::decode $context]
						status_log "$decoding\n" blue
						status_log "######################\n" blue

						# Let's notify the user that he/she has received a Wink
						SendMessageFIFO [list ::amsn::WinWrite $chatid "\n [trans winkreceived [::abook::getDisplayNick $chatid]]\n" black "" 0] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
					}
					"4BD96FC0-AB17-4425-A14A-439185962DC8" -
					"1C9AA97E-9C05-4583-A3BD-908A196F1E92" {
						status_log "MSNP2P | $sid $dest -> Got INVITE for webcam\n" red
						#check if a conversation is open with that contact
						#no need to test either a chatwindow has been created or not, because MakeFor is going to do it ! 
						::ChatWindow::MakeFor $chatid
						if { $eufguid == "4BD96FC0-AB17-4425-A14A-439185962DC8" } {
							set producer 0
						} else {
							set producer 1
						}

						status_log "we got an webcam invitation" red

						set context [base64::decode $context]
						set context [FromUnicode $context]

						#answerFtInvite $sid $chatid $branchuid $conntype
						# Let's send an ACK
						SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]

						SessionList set $sid [list 0 0 0 $dest 0 $uid 0 "webcam" "" "$branchuid"]
						
						if { $context != "\{B8BE70DE-E2CA-4400-AE03-88FF85B9F4E8\}" } {
							status_log "Received a video conferenced invitation.. we do not support this"
							::CAMGUI::InvitationRejected $chatid $sid $branchuid $uid
							#::MSNCAM::RejectFT $chatid $sid $branchuid $uid
							::CAMGUI::GotVideoConferenceInvitation $chatid
							return
						}

						

						::CAMGUI::AcceptOrRefuse $chatid $dest $branchuid $cseq $uid $sid $producer

						status_log "MSNP2P | $sid $dest -> Sent ACK for INVITE\n" red
						return
					}
					"6A13AF9C-5308-4F35-923A-67E8DDA40C2F"  {
						status_log "MSNP2P | $sid $dest -> Got INVITE for a game \n" red
						::ChatWindow::MakeFor $chatid
						status_log "!!! GAME INVITATION !!!" red

						SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
						status_log "MSNP2P | $sid $dest -> Sent ACK for INVITE\n" red

						set context [base64::decode $context]
						SessionList set $sid [list 0 0 0 $dest 0 $uid 0 "game" "$context" "$branchuid"]
						set context [FromUnicode $context]
						
						::MSNGames::IncomingGameRequest $chatid $dest $branchuid $cseq $uid $sid $context

						return
					}
					"534142D5-1F2A-431F-A60C-B0CF723FDF7D" {
						status_log "MSNP2P | $sid $dest -> Got INVITE for a shared folder\n" red
						return

						::ChatWindow::MakeFor $chatid
						SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]

						SessionList set $sid [list 0 0 0 $dest 0 $uid 0 "shared" "" "$branchuid"]
						
						set context [base64::decode $context]
						set stat1 [string range $context 24 27]
						set stat2 [string range $context 52 55]
						set out_context "\x01\x10\x08\x00\xcc\xcc\xcc\xcc"
						set ctx [binary format ssii 1 1 0 1]
						append ctx $stat1
						append ctx [binary format i 2]
						append ctx $stat2
						append ctx [binary format iiiiiiiiiiii 1 1 2 0 1 0 1 0 2 0 1 0]
						append out_context [binary format w [string length $ctx]]
						append out_context $ctx
						set context [string map { "\n" "" } [base64::encode $out_context]]
						set slpdata [MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr {$cseq + 1}] $uid 0 0 $sid $context]
						SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]

						return
					}
					default {
						status_log "MSNP2P | $sid $dest -> Got INVITE for an unknown EUF-GUID : $eufguid \n" red
						return
					}
				}

				
				# Let's send an ACK
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
				status_log "MSNP2P | $sid $dest -> Sent ACK for INVITE\n" red

				# Let's make and send a 200 OK Message
				set slpdata [MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr {$cseq + 1}] $uid 0 0 $sid]
				SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]
				status_log "MSNP2P | $sid $dest -> Sent 200 OK Message\n" red
					
				# Send Data Prep AFTER ACK received (set AfterAck)
				SessionList set $sid [list -1 -1 -1 -1 "DATAPREP" -1 -1 -1 -1 -1]
					
				return
			} elseif { $ctype == "application/x-msnmsgr-transrespbody" } {
				set idx [expr {[string first "Call-ID: \{" $data] + 10}]
				set idx2 [expr {[string first "\}" $data $idx] -1}]
				set uid [string range $data $idx $idx2]
				set sid [SessionList findcallid $uid]
				set idx [expr {[string first "Listening: " $data] + 11}]
				set idx2 [expr {[string first "\r\n" $data $idx] -1}]
				set listening [string range $data $idx $idx2]
				
				#status_log "MSNP2P | $sid -> Got 200 OK for File transfer, parsing result\n"
				#status_log "MSNP2P | $sid -> Found uid = $uid , lestening = $listening\n"

				if { $sid != -1 }  {
					SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
					set type [lindex [SessionList get $sid] 7]

					if { $listening == "true" } {
						set idx [expr {[string first "Nonce: \{" $data] + 8}]
						set idx2 [expr {[string first "\r\n" $data $idx] -2}]
						set nonce [string range $data $idx $idx2]

						if {[string first "IPv4External-Addrs: " $data] != -1 } {
							set idx [expr {[string first "IPv4External-Addrs: " $data] + 20}]
							set idx2 [expr {[string first "\r\n" $data $idx] -1}]
							set addr [string range $data $idx $idx2]

							set idx [expr {[string first "IPv4External-Port: " $data] + 19}]
							set idx2 [expr {[string first "\r\n" $data $idx] -1}]
							set port [string range $data $idx $idx2]

							status_log "MSNP2P | $sid -> Receiver is listening EXTERNAL with $addr : $port\n" red
							if {$type == "filetransfer" } {
								::MSN6FT::ConnectSockets $sid $nonce $addr $port 0
							} elseif { $type == "webcam" } {
								#::MSNCAM::connectMsnCam2 $sid $nonce $addr $port 0
							} elseif { $type == "game" } {
								::MSNGames::ConnectPort $sid $nonce $addr $port 0
							}
						} 
						if {[string first "IPv4Internal-Addrs: " $data] != -1 } {
							set idx [expr {[string first "IPv4Internal-Addrs: " $data] + 20}]
							set idx2 [expr {[string first "\r\n" $data $idx] -1}]
							set addr [string range $data $idx $idx2]

							set idx [expr {[string first "IPv4Internal-Port: " $data] + 19}]
							set idx2 [expr {[string first "\r\n" $data $idx] -1}]
							set port [string range $data $idx $idx2]

							status_log "MSNP2P | $sid -> Receiver is listening INTERNAL with $addr : $port\n" red
							if {$type == "filetransfer" } {
								::MSN6FT::ConnectSockets $sid $nonce $addr $port 0
							} elseif { $type == "webcam" } {
								#::MSNCAM::connectMsnCam2 $sid $nonce $addr $port 0
							} elseif { $type == "game" } {
								::MSNGames::ConnectPort $sid $nonce $addr $port 0
							}
						}


					}
				}
			}
		}
		# Check if it is a 200 OK message
		if { [string first "MSNSLP/1.0 200 OK" $data] != -1 } {
			# Send a 200 OK ACK
			set first [string first "SessionID:" $data]
			#msn8 introduce a SessionId in the Direct connection invitation message, that's why we check for listening
			set listening_idx [string first "Listening:" $data]
			if { $first != -1 && $listening_idx == -1} {
				set idx [expr {[string first "SessionID:" $data] + 11}]
				set idx2 [expr {[string first "\r\n" $data $idx] -1}]
				set sid [string range $data $idx $idx2]
				set type [lindex [SessionList get $sid] 7]

				if { $type == "ignore" } {
					#status_log "MSNP2P | $sid -> Ignoring packet! not for us!\n"
					return
				}

				#status_log "MSNP2P | $sid -> Got 200 OK message, sending an ACK for it\n" red
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
				if { $type == "filetransfer" } {
					::MSN6FT::SendFTInvite $sid $chatid
				} elseif { $type == "game" } {
					::MSNGamesGUI::InvitationAccepted $chatid $sid
				}
			} else {
				set idx [expr {[string first "Call-ID: \{" $data] + 10}]
				set idx2 [expr {[string first "\}" $data $idx] -1}]
				set uid [string range $data $idx $idx2]
				set sid [SessionList findcallid $uid]
				set idx [expr {[string first "Listening: " $data] + 11}]
				set idx2 [expr {[string first "\r\n" $data $idx] -1}]
				set listening [string range $data $idx $idx2]

				#status_log "MSNP2P | $sid -> Got 200 OK for File transfer, parsing result\n"
				#status_log "MSNP2P | $sid -> Found uid = $uid , lestening = $listening\n"


				set type [lindex [SessionList get $sid] 7]

				if { $sid != -1 }  {
					SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]

					if { $listening == "true" } {
						set idx [expr {[string first "Nonce: \{" $data] + 8}]
						set idx2 [expr {[string first "\r\n" $data $idx] -2}]
						set nonce [string range $data $idx $idx2]

						if {[string first "IPv4External-Addrs: " $data] != -1 } {
							set idx [expr {[string first "IPv4External-Addrs: " $data] + 20}]
							set idx2 [expr {[string first "\r\n" $data $idx] -1}]
							set addr [string range $data $idx $idx2]

							set idx [expr {[string first "IPv4External-Port: " $data] + 19}]
							set idx2 [expr {[string first "\r\n" $data $idx] -1}]
							set port [string range $data $idx $idx2]

							status_log "MSNP2P | $sid -> Receiver is listening EXTERNAL with $addr : $port\n" red
							#after 5500 "::MSNP2P::SendData $sid $chatid [lindex [SessionList get $sid] 8]"
							if { $type == "filetransfer" } {
								::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "INVITE2" -1 -1 -1 -1 -1]
								::MSN6FT::ConnectSockets $sid $nonce $addr $port 1
							} elseif { $type == "webcam" } {
								::MSNCAM::SendSyn $sid $chatid
							} elseif { $type == "game" } {
								::MSNGames::ConnectPort $sid $nonce $addr $port 1
							}
						} 
						if { [string first "IPv4Internal-Addrs: " $data] != -1 } {
							set idx [expr {[string first "IPv4Internal-Addrs: " $data] + 20}]
							set idx2 [expr {[string first "\r\n" $data $idx] -1}]
							set addr [string range $data $idx $idx2]

							set idx [expr {[string first "IPv4Internal-Port: " $data] + 19}]
							set idx2 [expr {[string first "\r\n" $data $idx] -1}]
							set port [string range $data $idx $idx2]

							status_log "MSNP2P | $sid -> Receiver is listening INTERNAL with $addr : $port\n" red
							#after 5500 "::MSNP2P::SendData $sid $chatid [lindex [SessionList get $sid] 8]"
							if { $type == "filetransfer" } {
								::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "INVITE2" -1 -1 -1 -1 -1]
								::MSN6FT::ConnectSockets $sid $nonce $addr $port 1
							} elseif { $type == "webcam" } {
								::MSNCAM::SendSyn $sid $chatid
							} elseif { $type == "game" } {
								::MSNGames::ConnectPort $sid $nonce $addr $port 1
							}
						}

					} elseif { $listening == "false" } {
						status_log "MSNP2P | $sid -> Receiver is not listening, sending INVITE\n" red
						if { $type == "filetransfer" } {
							::MSN6FT::SendFTInvite2 $sid $chatid
						} elseif { $type == "webcam" } {
							::MSNCAM::SendSyn $sid $chatid
							#::MSNCAM::SendAcceptInvite $sid $chatid
						} elseif { $type == "game" } {
							::MSNGames::SendInvite2 $sid $chatid
						}
					} else {
						status_log "Error sending file, got answer to invite :\n$data\n\n" red
					}
				}
			}


			return


		}

		# Check if we got BYE message
		if { [string first "BYE MSNMSGR:" $data] != -1 } {
			# Lets get the call ID and find our SessionID
			set idx [expr {[string first "Call-ID: \{" $data] + 10}]
			set idx2 [expr {[string first "\}" $data $idx] - 1}]
			set uid [string range $data $idx $idx2]
			set sid [SessionList findcallid $uid]
			status_log "MSNP2P | $sid -> Got BYE for UID : $uid\n" red

			if { $sid != -1 } {
				# Send a BYE ACK
				if { [lindex [SessionList get $sid] 7] == "game" } {
					status_log "Game canceled"
					::MSNGames::GameCanceled $chatid $sid
					::MSNGames::SendLast $sid [::MSNGames::buildACK $sid $cTotalDataSize $cId $cAckId 1]
					status_log "MSNP2P | $sid -> Sending game BYE ACK\n" red
				} else {
					SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
					status_log "MSNP2P | $sid -> Sending BYE ACK\n" red
				}
					
				# If it's a file transfer, advise the user it has been canceled
				if { [lindex [SessionList get $sid] 7] == "filetransfer" } {
					status_log "File transfer canceled\n"
					::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 -1 -1 -1 "ftcanceled" -1 -1]
					if { [::amsn::FTProgress ca $sid [lindex [SessionList get $sid] 6]] == -1 } {
						::amsn::RejectFT $chatid "-2" $sid
					}
				}
				if { [lindex [SessionList get $sid] 7] == "webcam" } {
					status_log "Webcam canceled\n"
					::MSNCAM::CamCanceled $chatid $sid
				}
				
				# Delete SessionID Data
				SessionList unset $sid
				clearObjOption $sid

			} else {
				status_log "MSNP2P | $sid -> Got a BYE for unexisting SessionID\n" red
			}
			return
		}
		if { [string first "ACK MSNMSGR:" $data] != -1 } {
			set idx [expr {[string first "SessionID:" $data] + 11}]
			set idx2 [expr {[string first "\r\n" $data $idx] -1}]
			set sid [string range $data $idx $idx2]

			# We get an ACK message for receiving the user's ip:port for a file transfer..
			# if we don't ack this message, the FT gets canceled...
			# TODO : actually parse the message and use it.. RE necessary.
			SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
			return
		}

		# Check if we got DECLINE message
		if { [string first "603 Decline" $data] != -1 } {
			# Lets get the call ID and find our SessionID
			set idx [expr {[string first "Call-ID: \{" $data] + 10}]
			set idx2 [expr {[string first "\}" $data $idx] - 1}]
			set uid [string range $data $idx $idx2]
			set sid [SessionList findcallid $uid]
			status_log "MSNP2P | $sid -> Got DECLINE for UID : $uid\n" red

			if { $sid != -1 } {
				# Send a BYE ACK
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
				status_log "MSNP2P | $sid -> Sending DECLINE ACK\n" red

				# If it's a file transfer, advise the user it has been canceled
				if { [lindex [SessionList get $sid] 7] == "webcam" } {
				    set idx [expr {[string first "Content-Type: " $data] + 14}]
				    set idx2 [expr {[string first "\r\n" $data $idx] - 1}]
				    set content_type [string range $data $idx $idx2]
				    if { $content_type != "null"  &&
					 $content_type != "application/x-msnmsgr-session-failure-respbody" } {
					::CAMGUI::InvitationDeclined $chatid $sid
				    } else {
					::MSNCAM::SendSyn $sid $chatid
				    }
				} elseif {[lindex [SessionList get $sid] 7] == "game"} {
					::MSNGamesGUI::InvitationRejected $chatid $sid
				}


			} else {
				status_log "MSNP2P | $sid -> Got a DECLINE for unexisting SessionID\n" red
			}
		}


		# Let's check for data preparation messages and data messages
		if { $cSid != 0 } {
			# Make sure this isn't a canceled FT
			if { [lindex [SessionList get $cSid] 7] == "ftcanceled" } { return }
			set sid $cSid
			set fd [lindex [SessionList get $cSid] 6]
			set type [lindex [SessionList get $cSid] 7]

			#If it's a file transfer, display Progress bar
			if { $type == "filetransfer" } {
				#::amsn::FTProgress w $cSid "" [trans throughserver]
				::amsn::FTProgress r $cSid [lindex [SessionList get $cSid] 6] $cOffset $cTotalDataSize
			}
			if { $type != "webcam" && $fd != "" && $fd != 0 && $fd != -1 } {
				# File already open and being written to (fd exists)
				# Lets write data to file
				seek $fd $cOffset
				set written [getObjOption $sid written]
				if { $written == "" } {
					set written $cMsgSize
				} else {
					incr written $cMsgSize
				}
				setObjOption $sid written $written

				puts -nonewline $fd [string range $data 0 [expr {$cMsgSize - 1}]]
				#status_log "MSNP2P | $sid -> FD EXISTS, file already open... with fd = $fd --- $cOffset + $cMsgSize + $cTotalDataSize . Writing DATA to file\n" red
				# Check if this is last part if splitted
				if { $written >= $cTotalDataSize } {
					close $fd

					set session_data [SessionList get $cSid]
					set user_login [lindex $session_data 3]
					set filename [lindex $session_data 8]
					#We have closed the file so we set its fd to 0
					SessionList set $cSid [list -1 -1 -1 -1 -1 -1 0 -1 -1 -1]

					# Lets send an ACK followed by a BYE if it's a buddy icon or emoticon
					#status_log "MSNP2P | $sid -> Sending an ACK for file received and sending a BYE\n" red
					SendPacket [::MSN::SBFor $chatid] [MakeACK $sid $cSid $cTotalDataSize $cId $cAckId]

					if { [lindex [SessionList get $cSid] 7] == "bicon" } {
						SendPacket [::MSN::SBFor $chatid] [MakePacket $sid [MakeMSNSLP "BYE" $user_login [::config::getKey login] "19A50529-4196-4DE9-A561-D68B0BF1E83F" 0 [lindex $session_data 5] 0 0] 1]
						::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "BYE" -1 -1 -1 -1 -1]

						#set filename2 [::MSNP2P::GetFilenameFromMSNOBJ [::abook::getVolatileData $user_login msnobj]]
						set filename2 [::abook::getContactData $user_login displaypicfile ""]
						status_log "MSNP2P | $sid -> Got picture with file : $filename and $filename2\n" blue
						if {$filename == $filename2 } {

							status_log "MSNP2P | $sid -> Closed file $filename.. finished writing\n" red
							
							::skin::getDisplayPicture $user_login 1
							::amsn::UpdateAllPictures

							set desc_file "[file join $HOME displaypic cache $user_login ${filename}.dat]"
							create_dir [file join $HOME displaypic]
							set fd [open [file join $HOME displaypic $desc_file] w]
							status_log "Writing description to $desc_file\n"
#							puts $fd "[clock format [clock seconds] -format %x]\n$user_login"
							puts $fd "[clock seconds]\n$user_login"
							close $fd
							# new DP, maybe we need to refresh the CL
							::Event::fireEvent contactDPChange protocol $user_login

						} else {
							#set file [png_to_gif [file join $HOME smileys cache ${filename}.png]]
							set file [file join $HOME smileys cache ${filename}.png]
							if { $file != "" } {
								set tw [::ChatWindow::GetOutText [::ChatWindow::For $chatid]]
								#set file [filenoext $file].gif
								set scrolling [::ChatWindow::getScrolling $tw]
								catch {image create photo emoticonCustom_std_${filename} -file "[file join $HOME smileys cache ${filename}.png]" -format cximage}
								
								# Make sure the smiley is max 50x50
								if {[::config::getKey big_incoming_smileys 0] == 0} {
									::smiley::resizeCustomSmiley emoticonCustom_std_${filename}
								}
								if { $scrolling } { ::ChatWindow::Scroll $tw }
							}
						}

					} elseif { [lindex [SessionList get $cSid] 7] == "voice" } {
						set file [file join $HOME voiceclips cache ${filename}.wav]
						if { $file != "" && [file exists $file]} {
							
							::ChatWindow::ReceivedVoiceClip $chatid $file
							status_log "VOICE: file <$file> should be decoded and played..." red
						} else {
							status_log "VOICE: file <$file> does not exist" red
						}
						
					} elseif { [lindex [SessionList get $cSid] 7] == "wink" } { 
						# Winks support is not in the core, all we can do is support it in the msnp2p code
						# and launch an event for an appropriate plugin to manage it.
						set evPar(chatid) chatid
						set evPar(filename) [file join $HOME winks cache ${filename}.cab]
						::plugins::PostEvent WinkReceived evPar
					} elseif { [lindex [SessionList get $cSid] 7] == "filetransfer" } {
						# Display message that file transfer is finished...
						status_log "MSNP2P | $cSid -> File transfer finished!\n"
						set filename [file join [::config::getKey receiveddir] [lindex [SessionList get $cSid] 8]]
						::amsn::FTProgress fr $cSid [lindex [SessionList get $cSid] 6] $cOffset $cTotalDataSize
						set finishedname [filenoext $filename]
						if { [ string range $filename [expr {[string length $filename] - 11}] [string length $filename]] == ".incomplete" } {
							if { [catch { file rename $filename $finishedname } ] } {
								::amsn::infoMsg [trans couldnotrename $filename] warning
								status_log "Could not rename file $filename to $finishedname!"
							}
						}		
				SessionList set $cSid [list -1 -1 -1 -1 -1 -1 -1 "filetransfersuccessfull" -1 -1]
					}
				}
			} elseif { $type == "game" } {
				::MSNGames::handleMessage $message $chatid
			} elseif { $cMsgSize == 4 } {
				# We got ourselves a DATA PREPARATION message, lets open file and send ACK
				set session_data [SessionList get $sid]
				set user_login [lindex $session_data 3]
				#status_log "MSNP2P | $sid $user_login -> Got data preparation message, opening file for writing\n" red
				set filename [lindex $session_data 8]
				#set filename2 [::MSNP2P::GetFilenameFromMSNOBJ [::abook::getVolatileData $user_login msnobj]]
				set filename2 [::abook::getContactData $user_login displaypicfile ""]
				#status_log "MSNP2P | $sid $user_login -> opening file $filename for writing with $filename2 as user msnobj\n\n" blue
				set type [lindex [SessionList get $cSid] 7]
				if {$type == "bicon" } {
					if { $filename == $filename2 } {
						create_dir [file join $HOME displaypic cache]
						create_dir [file join $HOME displaypic cache $user_login]
						set fd [open "[file join $HOME displaypic cache $user_login ${filename}.png]" w]
					} else {
						create_dir [file join $HOME smileys cache]
						set fd [open "[file join $HOME smileys cache ${filename}.png]" w]
					}
				} elseif {$type == "voice" } {
					create_dir [file join $HOME voiceclips]
					create_dir [file join $HOME voiceclips cache]
					set fd [open "[file join $HOME voiceclips cache ${filename}.wav]" w]
				} elseif {$type == "wink" }  {
					set fd [open "[file join $HOME winks cache ${filename}.cab]" w]
				}
				if {$fd != "" } {
					fconfigure $fd -translation {binary binary}
					SendPacket [::MSN::SBFor $chatid] [MakeACK $sid $cSid $cTotalDataSize $cId $cAckId]
					#status_log "MSNP2P | $sid $user_login -> Sent an ACK for DATA PREP Message\n" red
					SessionList set $sid [list -1 -1 -1 -1 -1 -1 $fd -1 -1 -1]
				}
			} elseif { $type == "webcam" } {
				# WEBCAM TO COMPLETE

				set h1 [string range $data 0 3]
				set h2 [string range $data 4 9]
				set msg [string range $data 10 [expr { $cMsgSize - 1}]]

				set msg [FromUnicode $msg]

				status_log "Received data for webcam $sid : $data\n$msg\n" red

				if {[expr {$cOffset + $cMsgSize}] >= $cTotalDataSize} {
					SendPacket [::MSN::SBFor $chatid] [MakeACK $sid $cSid $cTotalDataSize $cId $cAckId]
				}

				if { $msg == "syn\x00" } {

					::MSNCAM::SendSyn $sid $chatid

					::MSNCAM::SendAck $sid $chatid

				} elseif { $msg == "ack\x00" } {
					set producer [getObjOption $sid producer]
					status_log "Received the ack for webcam\n" red

					if {$producer} {
						status_log "We should send the XML\n" red
						::MSNCAM::SendXML $chatid $sid
					}

				} elseif { $msg == "receivedViewerData\x00" } {
					status_log "ReceivedViewData received\n" red
					::MSNCAM::ConnectSockets $sid
				} elseif {[string first "<producer>" $msg] == 0 || [string first "<viewer>" $msg] == 0 || $cOffset != 0} {
					set xml [getObjOption $sid xml]
					set xml "${xml}[string range $data 0 [expr { $cMsgSize - 1}]]"

					setObjOption $sid xml $xml

					if { [expr {$cOffset + $cMsgSize}] >= $cTotalDataSize } {
						set xml [string range $xml 10 end]
						setObjOption $sid xml $xml

						::MSNCAM::ReceivedXML $chatid $sid
					}

				} elseif { [string first "ReflData:" $msg] == 0 } {
					set refldata [string range $msg 9 end-1]
					set refldata [binary format H* $refldata]

					::MSNCAM::ConnectToReflector $sid $refldata

				} else {
					status_log "UNKNOWN" red
				}


			} elseif {$sid == 64} {
				set msg [FromUnicode $data]
				set ink_message [getObjOption $sid ink_message_$cId]
				set ink_message "${ink_message}[string range $data 0 [expr { $cMsgSize - 1}]]"
				setObjOption $sid ink_message_$cId $ink_message

				if {[expr {$cOffset + $cMsgSize}] >= $cTotalDataSize} {
					setObjOption $sid ink_message_$cId ""
					SendPacket [::MSN::SBFor $chatid] [MakeACK $sid $cSid $cTotalDataSize $cId $cAckId]
					set ink_message [FromUnicode $ink_message]
					set idx [expr {[string first "Content-Type: " $ink_message] + 14}]
					set idx2 [expr {[string first "\r\n" $ink_message $idx] - 1}]
					set ctype [string range $ink_message $idx $idx2]

					set idx [string first "\r\n\r\n" $ink_message]
					incr idx 4
					if {[string first "\x00" $ink_message $idx] == $idx } {
						incr idx
					}
					set body [string range $ink_message $idx end]

					if { [string first "base64:" $body] != -1 } {
						set data [::base64::decode [string range $body 7 end]]
					} else {
						set data $body
					}
					status_log "Received an ink with content type : $ctype "
					set user [lindex [::MSN::usersInChat $chatid] 0]
					if {$ctype == "image/gif" } {
						# don't try to display it if the image is considered as invalid
						if {[catch {set img [image create photo [TmpImgName] -data $data]}]} {
							status_log "(msnp2p.tcl) receiving an invalid gif from $user" red
						} else {
							set nick [::abook::getDisplayNick $user]
							set p4c_enabled 0
							status_log "got ink from $user - $nick with image $img"
							SendMessageFIFO [list ::amsn::ShowInk $chatid $user $nick $img ink $p4c_enabled] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
						}
					} elseif {$ctype == "application/x-ms-ink" } {
						# an ISF ink
						status_log "Received an ISF ink : $body"
					}
				}

			} else {
				status_log "Received data for unknown type : $sid\n" red
			}
		}
	}

	#//////////////////////////////////////////////////////////////////////////////
	# RequestObject ( chatid msnobject filename)
	# This function creates the invitation packet in order to receive an MSNObject (custom emoticon and display buddy for now)
	# chatid : Chatid from which we will request the object
	# dest : The email of the user that will receive our request
	# msnobject : The object we want to request (has to be url decoded)
	proc RequestObject { chatid dest msnobject} {
		RequestObjectEx $chatid $dest $msnobject "bicon"
	}

	proc RequestObjectEx { chatid dest msnobject type} {
		# Let's create a new session
		set sid [expr {int([expr rand() * 1000000000])%125000000 + 4 } ]
		# Generate BranchID and CallID
		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

		SessionList set $sid [list 0 0 0 $dest 0 $callid 0 "$type" [::MSNP2P::GetFilenameFromMSNOBJ $msnobject] ""]

		# Create and send our packet
		set slpdata [MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 0 $callid 0 0 "A4268EEC-FEC5-49E5-95C3-F126696BDBF6" $sid 1 [string map { "\n" "" } [::base64::encode "$msnobject\x00"]]]
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]
		status_log "Sent an INVITE to $dest on chatid $chatid of object $msnobject\n" red
	}

	#//////////////////////////////////////////////////////////////////////////////
	# MakePacket ( sid slpdata [nullsid] [MsgId] [TotalSize] [Offset] [Destination] )
	# This function creates the appropriate MSNP2P packet with the given SLP info
	# This will be used for everything except for ACK's
	# slpdata	: the SLP info created by MakeMSNSLP that will be included in the packet
	#		  it could also be binary data that will be sent in the P2P packet
	# sid		: the session id
	# nullsid 	: 0 to add sid to header, 1 to put 0 instead of sid in header (usefull for negot + bye)
	# Returns the MSNP2P packet (half text half binary)
	proc MakePacket { sid slpdata {nullsid "0"} {MsgId "0"} {TotalSize "0"} {Offset "0"} {Destination "0"} {AfterAck "0"} {flags "0"}} {
		set custom_msgid 1
		set custom_totalsize 1
		set custom_offset 1

		# Let's get our session id variables and put them in a list
		# If sessionid is 0, means we want to initiate a new session
		if { $sid != 0 } {
			set SessionInfo [SessionList get $sid]
			if {$MsgId == "0" } {
				set MsgId [lindex $SessionInfo 0]
				set custom_msgid 0
			}
			if {$TotalSize == "0" } {
				set TotalSize [lindex $SessionInfo 1]
				set custom_totalsize 0
			}
			if {$Offset == "0" } {
				set Offset [lindex $SessionInfo 2]
				set custom_offset 0
			}
			set Destination [lindex $SessionInfo 3]
		}

		# Here is our text header
		set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $Destination\r\n\r\n"

		# We start by creating the 48 byte binary header
		if { $nullsid != 0 } {
			# session id field set to 0 during negotiation and bye
			set bheader [binary format i 0]
		} else {
			# normal message
		    # This is a workaround to prevent a bug with Telepathy client which sends a 64-bit SID..
		    if {[catch {set bheader [binary format i $sid]}] } {
			set bheader [binary format i 0]
		    }
		}

		if { $MsgId == 0 } {
			# No MsgId let's generate one and add to our list
			set MsgId [expr {int([expr rand() * 1000000]) + 4}]
		} elseif { $Offset == 0 } {
			# Offset is different than 0, we need to incr the MsgId to prepare our next message
			incr MsgId
		}

		if {[string is digit $Offset] == 0 || $Offset == ""} {
			set Offset 0
		}

		append bheader [binary format i $MsgId]
		append bheader [binword $Offset]

		set CurrentSize [string length $slpdata]
		# We must set TotalSize to the size of data if it is > 1202 bytes otherwise we set to 0
		if { $TotalSize == 0 } {
			# This isn't a split message
			append bheader "[binword $CurrentSize][binary format i $CurrentSize]"
		} else {
			# This is a split message
			append bheader "[binword $TotalSize][binary format i $CurrentSize]"
			incr Offset $CurrentSize
			if { $Offset >= $TotalSize } {
				# We have finished sending the last part of the message
				set Offset 0
				set TotalSize 0
			}
		}

		# Set flags to 0
		append bheader [binary format i $flags]

		# Just give the Ack Session ID some dumbo random number
		append bheader [binary format i [myRand 4369 6545000]]
		#append bheader [binary format i 67152542]

		# Set last 2 ack fields to 0
		append bheader [binary format i 0][binword 0]

		# Now the footer
		if { $nullsid == 1 } {
			# Negotiating Session so set to 0
			set bfooter [binary format I 0]
		} else {
			# Either sending a display pic, or an emoticon so set to 1
			set bfooter [binary format I 1]
		}

		# Combine it all
		set packet "${theader}${bheader}${slpdata}${bfooter}"
		#status_log "Sent a packet with header $theader\n" red

		unset bheader
		unset bfooter
		unset slpdata

		# Reset variables if we use the custom ones to avoid overriding the ones in SessionList
		# and corrupt our stack
		if {$custom_msgid } {
			set MsgId -1
		} 
		if {$custom_totalsize } {
			set TotalSize -1
		}
		if {$custom_offset } {
			set Offset -1
		}

		# Save new Session Variables into SessionList
		SessionList set $sid [list $MsgId $TotalSize $Offset -1 -1 -1 -1 -1 -1 -1]

		return $packet
	}


	#//////////////////////////////////////////////////////////////////////////////
	# MakeACK (sid originalsid originalsize originalid originaluid)
	# This function creates an ack packet for msnp2p
	# original* arguments are all arguments of the message we want to ack
	# sid has to be != 0
	# Returns the ACK packet
	proc MakeACK { sid originalsid originalsize originalid originaluid } {
		set new 0
		if { $sid != 0 } {
			set SessionInfo [SessionList get $sid]
			set MsgId [lindex $SessionInfo 0]
			set Destination [lindex $SessionInfo 3]
		} else {
			return
		}

		if { $MsgId == 0 } {
			# No MsgId let's generate one and add to our list
			set MsgId [expr {int([expr rand() * 1000000]) + 10 } ]
			set new 1
		} else {
			incr MsgId
		}

		# The text header
		set theader "MIME-Version: 1.0\r\nContent-Type: application/x-msnmsgrp2p\r\nP2P-Dest: $Destination\r\n\r\n"

		# Set the binary header and footer
		set b [binary format ii $originalsid $MsgId][binword 0][binword $originalsize][binary format iiii 0 2 $originalid $originaluid][binword $originalsize][binary format I 0]

		# Save new Session Variables into SessionList
		if { $new == 1 } {
			incr MsgId -4
		}
		SessionList set $sid [list $MsgId -1 -1 -1 -1 -1 -1 -1 -1 -1]

		return "${theader}${b}"
	}


	#//////////////////////////////////////////////////////////////////////////////
	#	# MakeMSNSLP ( method to from branchuid cseq maxfwds contenttentype [A] [B] [C] [D] [E] [F] [G])
	# This function creates the appropriate MSNSLP packets
	# method :		INVITE, BYE, OK, DECLINE, ERROR
	# contenttype : 	0 for application/x-msnmsgr-sessionreqbody (Starting a session) or sessionclosebody for a BYE
	#			1 for application/x-msnmsgr-transreqbody (Starting transfer) or sessionclosebody for a BYE and use A
	#                                                                                                                 as context
	#			2 for application/x-msnmsgr-transrespbody (Starting transfer)
	#                       3 for null (starting webcam)
	#
	#
	# If INVITE method is chosen then A, B, C, D and/or E are used dependinf on contenttype
	# for 0 we got : "EUF-GUID", "SessionID", "AppID" and "Context" (E not used)
	# for 1 we got : "Bridges", "NetID", "Conn-Type", "UPnPNat" and "ICF"
	# for 2 we got : "Bridge", "Listening", "Nonce", "IPv4External-Addrs","IPv4External-Port"
	#		 "IPv4Internal-Addrs" and "IPv4Internal-Port"
	#
	# If OK method is chosen then A to G are used depending on contenttype
	# for 0 we got : "SessionID"
	# for 2 we got : "Bridge", "Listening", "Nonce", "IPv4External-Addrs","IPv4External-Port"
	#		 "IPv4Internal-Addrs" and "IPv4Internal-Port"
	# Returns the formated MSNSLP data
	proc MakeMSNSLP { method to from branchuid cseq uid maxfwds contenttype {A ""} {B ""} {C ""} {D ""} {E ""} {F ""} {G ""} } {

		# Generate start line
		if { $method == "INVITE" } {
			set data "INVITE MSNMSGR:${to} MSNSLP/1.0\r\n"
		} elseif { $method == "BYE" } {
			set data "BYE MSNMSGR:${to} MSNSLP/1.0\r\n"
		} elseif { $method == "OK" } {
			set data "MSNSLP/1.0 200 OK\r\n"
		} elseif { $method == "DECLINE" } {
			set data "MSNSLP/1.0 603 Decline\r\n"
		} elseif { $method == "ERROR" } {
			set data "MSNSLP/1.0 500 Internal Error\r\n"
		}

		# Lets create our message body first (so we can calc it's length for the header)
		set body ""
		if { $method == "INVITE" } {
			if { $contenttype == 0 } {
			    append body "EUF-GUID: {${A}}\r\nSessionID: ${B}\r\nSChannelState: 0\r\nCapabilities-Flags: 1\r\nAppID: ${C}\r\nContext: ${D}\r\n"
			} elseif { $contenttype == 1 } {
				append body "Bridges: ${A}\r\nNetID: ${B}\r\nConn-Type: ${C}\r\nUPnPNat: ${D}\r\nICF: ${E}\r\n"
			} else {
				append body "Bridge: ${A}\r\nListening: ${B}\r\nNonce: \{${C}\}\r\n"
				if {${B} == "true" } {
					if { [::abook::getDemographicField conntype] == "IP-Restrict-NAT" } {
						append body "IPv4External-Addrs: ${D}\r\nIPv4External-Port: ${E}\r\nIPv4Internal-Addrs: ${F}\r\nIPv4Internal-Port: ${G}\r\n"
					} else {
						append body "IPv4Internal-Addrs: ${D}\r\nIPv4Internal-Port: ${E}\r\n"
					}
				}

			}
		} elseif { $method == "OK" } {
			if { $contenttype == 0 } {
				append body "SessionID: ${A}\r\nSChannelState: 0\r\nCapabilities-Flags: 1\r\n"
				if {$B != "" } {
					append body "Context: ${B}\r\n"
				}
			} else {
				append body "Bridge: ${A}\r\nListening: ${B}\r\nNonce: \{${C}\}\r\n"
				if {${B} == "true" } {
					if { [::abook::getDemographicField conntype] == "IP-Restrict-NAT" } {
						append body "IPv4External-Addrs: ${D}\r\nIPv4External-Port: ${E}\r\nIPv4Internal-Addrs: ${F}\r\nIPv4Internal-Port: ${G}\r\n"
					} else {
						append body "IPv4Internal-Addrs: ${D}\r\nIPv4Internal-Port: ${E}\r\n"
					}
				}

			}
		} elseif { $method == "DECLINE" || $method == "ERROR" } {
			append body "SessionID: ${A}\r\n"
		} elseif { $method == "BYE" && $contenttype == 1} {
			append body "Context: ${A}"
		} elseif { $method == "BYE" && $contenttype == 2} {
			append body "SessionID: ${A}\r\n"
			append body "Context: ${B}"
		} 

		append body "\r\n\x00"

		# Here comes the message header
		append data "To: <msnmsgr:${to}>\r\nFrom: <msnmsgr:${from}>\r\nVia: MSNSLP/1.0/TLP ;branch={${branchuid}}\r\nCSeq: ${cseq}\r\nCall-ID: {${uid}}\r\nMax-Forwards: ${maxfwds}\r\n"
		if { $method == "BYE" } {
			append data "Content-Type: application/x-msnmsgr-sessionclosebody\r\n"
		} else {
			if { $contenttype == 0 } {
				append data "Content-Type: application/x-msnmsgr-sessionreqbody\r\n"
			} elseif { $contenttype == 1 } {
				append data "Content-Type: application/x-msnmsgr-transreqbody\r\n"
			} elseif { $contenttype == 2 } {
				append data "Content-Type: application/x-msnmsgr-transrespbody\r\n"
			} elseif { $contenttype == 3 } {
				append data "Content-Type: null\r\n"
				set body ""
			}
		}
		append data "Content-Length: [expr [string length $body]]\r\n\r\n"

		append data $body
		unset body

		#status_log $data
		return $data
	}

	#//////////////////////////////////////////////////////////////////////////////
	# SendData ( sid chatid )
	# This procedure sends the data given by the filename in the Session vars given by SessionID
	proc SendData { sid chatid filename } {


		SessionList set $sid [list -1 [file size "${filename}"] -1 -1 -1 -1 -1 -1 -1 -1]
		set fd [lindex [SessionList get $sid] 6]
		if { $fd == 0 } {
			set fd [open "${filename}"]
			SessionList set $sid [list -1 -1 -1 -1 -1 -1 $fd -1 -1 -1]
			fconfigure $fd -translation binary
		}
		if { $fd == "" } {
			# 			set sock [sb get [MSN::SBFor $chatid] sock]

			# 			if { $sock != "" } {
			# 				fileevent $sock writable ""
			# 			}
			return
		}
		set chunk [read $fd 1200]
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $chunk 0 0 0 0 0 0 32]
		unset chunk

		#status_log "[SessionList get $sid]\n"
		if { [eof $fd] || [lindex [SessionList get $sid] 1] == 0 } {
			# All file has been sent
			close $fd
			unset fd
			# We finished sending the data, set appropriate Afterack and Fd
			SessionList set $sid [list -1 -1 -1 -1 DATASENT -1 0 -1 -1]
		} else {
			#	set sock [sb get [MSN::SBFor $chatid] sock]
			# Still need to send
			#			if { $sock != "" } {
			after 100 "[list ::MSNP2P::SendData $sid $chatid ${filename}]"
			# }
		}


	}


	proc SendDataFile { sid chatid filename match } {

		if { [lindex [::MSNP2P::SessionList get $sid] 7] == "ftcanceled" } {
			return
		}

		if { [lindex [::MSNP2P::SessionList get $sid] 4] != "$match"} {
			return
		}

		status_log "state is [lindex [::MSNP2P::SessionList get $sid] 4] => sending through SB\n\n" red;

		#return

		SessionList set $sid [list -1 [file size "${filename}"] -1 -1 -1 -1 -1 -1 -1 -1]
		set fd [lindex [SessionList get $sid] 6]
		if { $fd == 0 || $fd == "" } {
			set fd [open "${filename}"]
			SessionList set $sid [list -1 -1 -1 -1 -1 -1 $fd -1 -1 -1]
			fconfigure $fd -translation {binary binary}
		}
		if { $fd == "" } {
			return
		}
		::amsn::FTProgress w $sid "" [trans throughserver]

		# 		SendPacketExt [::MSN::SBFor $chatid] $sid [read $fd] 0 0 0 0 0 0 16777264
		# 		close $fd


		set sbn [::MSN::SBFor $chatid]
		set sock [$sbn cget -sock]

		set offset 0
		SessionList set $sid [list -1 -1 $offset -1 -1 -1 -1 -1 -1 -1]

		if { [fileevent $sock writable] == "" } {
			status_log "assining new fileevent proc\n"
			fileevent $sock writable "::MSNP2P::SendDataEvent $sbn $sid $fd $match"
		}



	}

	proc SendDataEvent { sbn sid fd match} {


		set sock [$sbn cget -sock]
		fileevent $sock writable ""
		#return

		set offset [lindex [SessionList get $sid] 2]
		set filesize [lindex [SessionList get $sid] 1]

		if { $offset == "" } {
			close $fd
			return
		}

		if { [lindex [::MSNP2P::SessionList get $sid] 7] == "ftcanceled" } {
			close $fd
			return
		}

		if { [lindex [::MSNP2P::SessionList get $sid] 4] != "$match"} {
			return
		}

		set MsgId [getObjOption $sid data_blob_id 0]

		# We can receive a NAK to our data being sent.
		# When a packet is lost for some reason, we get a nak with the position
		# of the file that WLM wants to receive. If we got that, we simply reposition 
		# ourselves in the file and set the new offset.
		if {[getObjOption $sid nak_pos ""] != "" } {
			set new_pos [getObjOption $sid nak_pos]
			set offset $new_pos
			SessionList set $sid [list -1 -1 $offset -1 -1 -1 -1 -1 -1 -1]
			seek $fd $new_pos
			setObjOption $sid nak_pos ""
		}

		set data [read $fd 1202]
		#		status_log "Reading 1202 bytes of data : got [string length $data]"
		if { [string length $data] >= 1202 } {
			set msg [MakePacket $sid $data 0 $MsgId 0 0 0 0 16777264]
			set msg_len [string length $msg]
			puts -nonewline $sock "MSG [incr ::MSN::trid] D $msg_len\r\n$msg"
			set offset [expr {$offset + 1202}]
			SessionList set $sid [list -1 -1 $offset -1 -1 -1 -1 -1 -1 -1]
			::amsn::FTProgress s $sid "" $offset $filesize
			#catch {after 200 [list catch {fileevent $sock writable "::MSNP2P::SendDataEvent $sbn $sid $fd"}]}
			after 200 [list ::MSNP2P::SetSendDataFileEvent $sock $sbn $sid $fd $match]
			
		} else {

			set msg [MakePacket $sid $data 0 $MsgId 0 0 0 0 16777264]
			set msg_len [string length $msg]
			puts -nonewline $sock "MSG [incr ::MSN::trid] D $msg_len\r\n$msg"
			set offset [expr {$offset + 1202}]
			SessionList set $sid [list -1 -1 0 -1 -1 -1 -1 -1 -1 -1 ]

			set msgId [expr {[lindex [SessionList get $sid] 0] + 1}]
			SessionList set $sid [list $msgId -1 0 -1 DATASENT -1 0 -1 -1 -1]
			close $fd
			unset fd

			::amsn::FTProgress fs $sid ""
		}
		if {$MsgId == 0 } {
			set MsgId [lindex [SessionList get $sid] 0]			
			setObjOption $sid data_blob_id $MsgId
		}
	}
	
	proc SetSendDataFileEvent { sock sbn sid fd match} { 
		catch { 
			fileevent $sock writable "::MSNP2P::SendDataEvent $sbn $sid $fd $match"
		}
	}



	#//////////////////////////////////////////////////////////////////////////////
	# SendPacket ( sbn msg )
	# This function sends the packet given by (msg) into the given (sbn)
	proc SendPacket { sbn msg } {
		#	if { [string length $msg] > 1202 }
		set msg_len [string length $msg]
		catch {::MSN::WriteSBNoNL $sbn "MSG" "D $msg_len\r\n$msg"}
	}

	proc SendPacketExt { sbn sid slpdata {nullsid "0"} {MsgId "0"} {TotalSize "0"} {Offset "0"} {Destination "0"} {AfterAck "0"} {flags "0"}} {
		set offset 0
		SessionList set $sid [list -1 [string length $slpdata] $offset -1 -1 -1 -1 -1 -1 -1]
		set fd [$sbn cget -sock]
		status_log "Got socket $fd\n"
		if { [fileevent $fd writable] == "" } {
			status_log "assining new fileevent proc\n"
			fileevent $fd writable "::MSNP2P::SendPacketExtEvent $sbn $sid [list $slpdata] $nullsid $MsgId $TotalSize $Offset $Destination $AfterAck $flags"
		}
	}

	proc SendPacketExtEvent { sbn sid slpdata {nullsid "0"} {MsgId "0"} {TotalSize "0"} {Offset "0"} {Destination "0"} {AfterAck "0"} {flags "0"} } {
		set fd [$sbn cget -sock]
		fileevent $fd writable ""

		#status_log "got sbn : $sbn, $fd\nsid : $sid\nslpdata: $slpdata \n$nullsid $MsgId $TotalSize $Offset $Destination $AfterAck $flags\n\n"  red

		set offset [lindex [SessionList get $sid] 2]

		if { $offset == "" } {
			return
		}

		if { [expr {$offset + 1202}] < [string length $slpdata] } {
			set msg [MakePacket $sid [string range $slpdata $offset [expr {$offset + 1201}]] $nullsid $MsgId $TotalSize $Offset $Destination $AfterAck $flags]
			set msg_len [string length $msg]
			::MSN::WriteSBNoNL $sbn "MSG" "D $msg_len\r\n$msg"
			set offset [expr {$offset + 1202}]
			SessionList set $sid [list -1 -1 $offset -1 -1 -1 -1 -1 -1 -1]
			after 200 [list fileevent $fd writable "::MSNP2P::SendPacketExtEvent $sbn $sid [list $slpdata] $nullsid $MsgId $TotalSize $Offset $Destination $AfterAck $flags" ]
		} else {

			set msg [MakePacket $sid [string range $slpdata $offset [expr {$offset + 1201}]] $nullsid $MsgId $TotalSize $Offset $Destination $AfterAck $flags]
			set msg_len [string length $msg]
			::MSN::WriteSBNoNL $sbn "MSG" "D $msg_len\r\n$msg"
			set offset [expr {$offset + 1202}]
			SessionList set $sid [list -1 -1 0 -1 -1 -1 -1 -1 -1 -1 ]
		}
	}

}
