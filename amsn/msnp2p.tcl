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
		after 30000 $self destroy
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
		binary scan [string range $body 0 48] iiiiiiiiiiii cSid cId cOffset1 cOffset2 cTotalDataSize1 cTotalDataSize2 cMsgSize cFlags cAckId cAckUID cAckSize1 cAckSize2
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
		if { [::config::getKey getdisppic] != 1 } {
			status_log "Display Pics disabled, exiting loadUserPic\n" red
			return
		}

		#status_log "::MSNP2P::GetUser: Checking if picture for user $user exists\n" blue

		set msnobj [::abook::getVolatileData $user msnobj]

		#status_log "::MSNP2P::GetUser: MSNOBJ is $msnobj\n" blue
		#Send x-clientcaps information
		::MSN::clientCaps $chatid
		#set filename [::MSNP2P::GetFilenameFromMSNOBJ $msnobj]
		set filename [::abook::getContactData $user displaypicfile ""]
		status_log "::MSNP2P::GetUser: filename is $filename\n" white

		if { $filename == "" } {
			return
		}

		global HOME
		#Reload 1 means that we force aMSN to reload a new display pic 
		if { ![file readable "[file join $HOME displaypic cache ${filename}].gif"] || $reload == "1" } {
			status_log "::MSNP2P::GetUser: FILE [file join $HOME displaypic cache ${filename}] doesn't exist!!\n" white
			image create photo user_pic_$user -file [::skin::GetSkinFile "displaypic" "loading.gif"]

			create_dir [file join $HOME displaypic]
			create_dir [file join $HOME displaypic cache]
			::MSNP2P::RequestObject $chatid $user $msnobj
		} else {
			catch {image create photo user_pic_$user -file "[file join $HOME displaypic cache ${filename}].gif"}

		}
	}

	proc loadUserSmiley { chatid user msnobj } {
		if { [::config::getKey getdisppic] != 1 } {
			status_log "Display Pics disabled, exiting loadUserSmiley\n" red
			return
		}

		set filename [::MSNP2P::GetFilenameFromMSNOBJ $msnobj]

		status_log "Got filename $filename for $chatid with $user and $msnobj\n" red

		if { $filename == "" } {
			return
		}

		image create photo custom_smiley_$filename -width 19 -height 19

		status_log "::MSNP2P::GetUserPic: filename is $filename\n" white


		global HOME
		if { ![file readable "[file join $HOME smileys cache ${filename}].gif"] } {
			status_log "::MSNP2P::GetUser: FILE [file join $HOME smileys cache ${filename}] doesn't exist!!\n" white
			image create photo custom_smiley_$filename -width 19 -height 19

			create_dir [file join $HOME smileys]
			create_dir [file join $HOME smileys cache]
			::MSNP2P::RequestObject $chatid $user $msnobj
		} else {
			catch {image create photo custom_smiley_$filename -file "[file join $HOME smileys cache ${filename}].gif"}

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
		set msnobj [string range $old_msnobj [string first "<" $old_msnobj] [expr [string first "/>" $old_msnobj] + 1]]

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
		variable MsgId
		variable TotalSize
		variable Offset
		variable Destination
		variable AfterAck
		variable CallId
		variable Fd
		variable Type
   	        variable Filename
		variable branchid

		switch $action {
			get {
				if { [info exists MsgId($sid)] } {
					# Session found, return values
					return [list $MsgId($sid) $TotalSize($sid) $Offset($sid) $Destination($sid) $AfterAck($sid) $CallId($sid) $Fd($sid) $Type($sid) $Filename($sid) $branchid($sid)]
				} else {
					# Session not found, return 0
					return 0
				}
			}

			set {
				# This overwrites previous vars if they are set to something else than -1
				if { [lindex $varlist 0] != -1 } {
					set MsgId($sid) [lindex $varlist 0] 
				}
				if { [lindex $varlist 1] != -1 } {
					set TotalSize($sid) [lindex $varlist 1]
				}
				if { [lindex $varlist 2] != -1 } {
					set Offset($sid) [lindex $varlist 2]
				}
				if { [lindex $varlist 3] != -1 } {
					set Destination($sid) [lindex $varlist 3]
				}
				if { [lindex $varlist 4] != -1 } {
					set AfterAck($sid) [lindex $varlist 4]
				}
				if { [lindex $varlist 5] != -1 } {
					set CallId($sid) [lindex $varlist 5]
				}
				if { [lindex $varlist 6] != -1 } {
					set Fd($sid) [lindex $varlist 6]
				}
				if { [lindex $varlist 7] != -1 } {
					set Type($sid) [lindex $varlist 7]
				}
				if { [lindex $varlist 8] != -1 } {
				        set Filename($sid) [lindex $varlist 8]
				}
				if { [lindex $varlist 9] != -1 } {
				        set branchid($sid) [lindex $varlist 9]
				}
			}

			unset {
				if { [info exists MsgId($sid)] } {
					unset MsgId($sid)
				} else {
					status_log "Trying to unset MsgID($sid) but do not exist\n" red
				}
				if { [info exists TotalSize($sid)] } {
					unset TotalSize($sid)
				} else {
					status_log "Trying to unset TotalSize($sid) but do not exist\n" red
				}
				if { [info exists Offset($sid)] } {
					unset Offset($sid)
				} else {
					status_log "Trying to unset Offset($sid) but does not exist\n" red
				}
				if { [info exists Destination($sid)] } {
					unset Destination($sid)
				} else {
					status_log "Trying to unset Destination($sid) but dosent exist\n" red
				}
				if { [info exists Afterack($sid)] } {
					unset AfterAck($sid)
				} else {
					status_log "Trying to unset Afterack($sid) but dosent exist\n" red
				}
				if { [info exists Fd($sid)] } {
					unset Fd($sid)
				} else {
					status_log "Trying to unset Fd($sid) but dosent exist\n" red
				}
				if { [info exists Type($sid)] } {
					unset Type($sid)
				} else {
					status_log "Trying to unset Type($sid) but dosent exist\n" red
				}
			        if { [info exists Filename($sid)] } {
					unset Filename($sid)
				} else {
					status_log "Trying to unset Filename($sid) but dosent exist\n" red
				}
			        if { [info exists branchid($sid)] } {
					unset branchid($sid)
				} else {
					status_log "Trying to unset Filename($sid) but dosent exist\n" red
				}
			}

			findid {
				set idx [lsearch [array get MsgId] $sid]
				if { $idx != -1 } {
					return [lindex [array get MsgId] [expr $idx - 1]]
				} else {
					return -1
				}
			}
			findcallid {
				set idx [lsearch [array get CallId] $sid]
				if { $idx != -1 } {
					return [lindex [array get CallId] [expr $idx - 1]]
				} else {
					return -1
				}
			}
		}
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

		#status_log "Read header : $cSid $cId $cOffset $cTotalDataSize $cMsgSize $cFlags $cAckId $cAckUID $cAckSize\n" red
		#status_log "Sid : $cSid -> " red

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

		if {$cSid == "0" && $cMsgSize != "0" && $cMsgSize != $cTotalDataSize } {
			
			if { ![info exists chunkedData($cId)] } {
				set chunkedData($cId) "[string range $data 0 end-4]"
			} else {
				set chunkedData($cId) "$chunkedData($cId)[string range $data 0 end-4]"
			}
			#status_log "Data is now : $chunkedData($cId)\n\n";

			if { $cTotalDataSize != [string length $chunkedData($cId)] } {
				return 
			} else {
				set data $chunkedData($cId)
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
			#status_log "GOT SID : $sid for Ackid : $cAckId\n"
			if { $sid != -1 } {
			 	#status_log "MSNP2P | $sid -> Got MSNP2P ACK " red

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
							SendData $sid $chatid "[::skin::GetSkinFile displaypic [::config::getKey displaypic]]"
						}
					}
					DATASENT {
						SessionList set $sid [list -1 -1 0 -1 0 -1 -1 -1 -1 -1]
						#status_log "MSNP2P | $sid -> Got ACK for sending data, now sending BYE\n" red
						set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
						SendPacket [::MSN::SBFor $chatid] [MakePacket $sid [MakeMSNSLP "BYE" [lindex [SessionList get $sid] 3] [::config::getKey login] "$branchid" "0" [lindex [SessionList get $sid] 5] 0 0] 1]
					}
				}
			}
			return
		}

		# Check if this is an INVITE message
		if { [string first "INVITE MSNMSGR" $data] != -1 } {
			#status_log "Got an invitation!\n" red

			# Let's get the session ID, destination email, branchUID, UID, AppID, Cseq
			set idx [expr [string first "SessionID:" $data] + 11]
			set idx2 [expr [string first "\r\n" $data $idx] - 1]
			set sid [string range $data $idx $idx2]
			
			set idx [expr [string first "From: <msnmsgr:" $data] + 15]
			set idx2 [expr [string first "\r\n" $data $idx] - 2]
			set dest [string range $data $idx $idx2]

			set idx [expr [string first "branch=\{" $data] + 8]
			set idx2 [expr [string first "\}" $data $idx] - 1]
			set branchuid [string range $data $idx $idx2]

			set idx [expr [string first "Call-ID: \{" $data] + 10]
			set idx2 [expr [string first "\}" $data $idx] - 1]
			set uid [string range $data $idx $idx2]

			set idx [expr [string first "CSeq:" $data] + 6]
			set idx2 [expr [string first "\r\n" $data $idx] - 1]
			set cseq [string range $data $idx $idx2]

			set idx [expr [string first "Content-Type: " $data $idx] + 14]
			set idx2 [expr [string first "\r\n" $data $idx] - 1]
			set ctype [string range $data $idx $idx2]

			status_log "Got INVITE with content-type : $ctype\n" red

			if { $ctype == "application/x-msnmsgr-transreqbody"} {

				set sid [SessionList findcallid $uid]
				set type [lindex [SessionList get $sid] 7]

				#this catches an error with MSN7, still need to find out why sid = -1
				if {$sid == -1} {return}
				set idx [expr [string first "Conn-Type: " $data] + 11]
				set idx2 [expr [string first "\r\n" $data $idx] - 1]
				set conntype [string range $data $idx $idx2]
				
				set idx [expr [string first "UPnPNat: " $data] + 9]
				set idx2 [expr [string first "\r\n" $data $idx] - 1]
				set upnp [string range $data $idx $idx2]

				# Let's send an ACK
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]

				if { $type == "filetransfer" } {
					# We received an invite for a FT, send 200 OK
					::MSN6FT::answerFTInvite $sid $chatid $branchuid $conntype
				} elseif { $type == "webcam" } {
					::MSNCAM::answerCamInvite $sid $chatid $branchuid
				}

			} elseif { $ctype == "application/x-msnmsgr-sessionreqbody" } {
				
				set idx [expr [string first "AppID:" $data] + 7]
				set idx2 [expr [string first "\r\n" $data $idx] - 1]
				set appid [string range $data $idx $idx2]
				
				# Let's check if it's an invitation for buddy icon or emoticon
				set idx [expr [string first "EUF-GUID:" $data] + 11]
				set idx2 [expr [string first "\}" $data $idx] - 1]
				set eufguid [string range $data $idx $idx2]
				
				set idx [expr [string first "Context:" $data] + 9]
				set idx2 [expr [string first "\r\n" $data $idx] - 1]
				set context [string range $data $idx $idx2]
				
				
				if { $eufguid == "A4268EEC-FEC5-49E5-95C3-F126696BDBF6" || 
				     $eufguid == "5D3E02AB-6190-11D3-BBBB-00C04F795683" || 
				     $eufguid == "E073B06B-636E-45B7-ACA4-6D4B5978C93C" || 
				     $eufguid == "4BD96FC0-AB17-4425-A14A-439185962DC8" || 
				     $eufguid == "1C9AA97E-9C05-4583-A3BD-908A196F1E92"} {
					status_log "MSNP2P | $sid $dest -> Got INVITE for buddy icon, emoticon, or file transfer, or Wink(MSN 7)\n" red
					
					# Make new data structure for this session id
					if { $eufguid == "A4268EEC-FEC5-49E5-95C3-F126696BDBF6" } {
						# Buddyicon or emoticon 
						if { [GetFilenameFromContext $context] != "" } {
							SessionList set $sid [list 0 0 0 $dest 0 $uid 0 "bicon" [GetFilenameFromContext $context] ""]
						} else {
							status_log "MSNP2P | $sid -> This is not an invitation for us, don't reply.\n" red
							# Now we tell this procedure to ignore all packets with this sid
							SessionList set $sid [list 0 0 0 0 0 0 0 "ignore" 0 ""]
							return
						}
					} elseif { $eufguid == "5D3E02AB-6190-11D3-BBBB-00C04F795683" } {
						# File transfer
						SessionList set $sid [list 0 0 0 $dest 0 $uid 0 "filetransfer" "" "$branchuid"]
					} elseif { $eufguid =="E073B06B-636E-45B7-ACA4-6D4B5978C93C"} {
						#We received Winks
						status_log "####WINKS RECEIVED####\n" blue
						set decoding [base64::decode $context]
						status_log "$decoding\n" blue
						status_log "######################\n" blue
						
						# Let's notify the user that he/she has received a Wink
						::amsn::WinWrite $chatid "\n [trans winkreceived [::abook::getDisplayNick $chatid]]\n" black "" 0
					} elseif { $eufguid == "4BD96FC0-AB17-4425-A14A-439185962DC8" || 
						   $eufguid == "1C9AA97E-9C05-4583-A3BD-908A196F1E92" }	{

						if { $eufguid == "4BD96FC0-AB17-4425-A14A-439185962DC8" } {
							set producer 0
						} else {
							set producer 1
						}

						status_log "we got an webcam invitation" red
						::amsn::WinWrite $chatid "\n [trans webcaminvite [::abook::getNick $dest]]" black ""
						SessionList set $sid [list 0 0 0 $dest 0 $uid 0 "webcam" "" "$branchuid"]
						
						::MSNCAM::AcceptWebcam $chatid $dest $branchuid $cseq $uid $sid $producer
					#answerFtInvite $sid $chatid $branchuid $conntype
				}
				
				# Let's send an ACK
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
				status_log "MSNP2P | $sid $dest -> Sent ACK for INVITE\n" red
				
				# Check if this is Buddy Icon or Emoticon request
				if { $appid == 1 } {
					# Let's make and send a 200 OK Message
					set slpdata [MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr $cseq + 1] $uid 0 0 $sid]
					SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]
					status_log "MSNP2P | $sid $dest -> Sent 200 OK Message\n" red
					
					# Send Data Prep AFTER ACK received (set AfterAck)
					SessionList set $sid [list -1 -1 -1 -1 "DATAPREP" -1 -1 -1 -1 -1]
					
					# Check if this is a file transfer
				} elseif { $appid == 2 } {
					# Let's get filename and filesize from context
					set idx [expr [string first "Context:" $data] + 9]
					set context [base64::decode [string range $data $idx end]]
					::MSN6FT::GotFileTransferRequest $chatid $dest $branchuid $cseq $uid $sid $context
				}
				return
			}
		} elseif { $ctype == "application/x-msnmsgr-transrespbody" } {

			set idx [expr [string first "Call-ID: \{" $data] + 10]
			set idx2 [expr [string first "\}" $data $idx] -1]
			set uid [string range $data $idx $idx2]
			set sid [SessionList findcallid $uid]
			set idx [expr [string first "Listening: " $data] + 11]
			set idx2 [expr [string first "\r\n" $data $idx] -1]
			set listening [string range $data $idx $idx2]

			#status_log "MSNP2P | $sid -> Got 200 OK for File transfer, parsing result\n"
			#status_log "MSNP2P | $sid -> Found uid = $uid , lestening = $listening\n"

			if { $sid != -1 }  {
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
				set type [lindex [SessionList get $sid] 7]

				if { $listening == "true" } {
					set idx [expr [string first "Nonce: \{" $data] + 8]
					set idx2 [expr [string first "\r\n" $data $idx] -2]
					set nonce [string range $data $idx $idx2]
					
					if {[string first "IPv4External-Addrs: " $data] != -1 } {
						set idx [expr [string first "IPv4External-Addrs: " $data] + 20]
						set idx2 [expr [string first "\r\n" $data $idx] -1]
						set addr [string range $data $idx $idx2]
						
						set idx [expr [string first "IPv4External-Port: " $data] + 19]
						set idx2 [expr [string first "\r\n" $data $idx] -1]
						set port [string range $data $idx $idx2]
					} else {
						set idx [expr [string first "IPv4Internal-Addrs: " $data] + 20]
						set idx2 [expr [string first "\r\n" $data $idx] -1]
						set addr [string range $data $idx $idx2]
						
						set idx [expr [string first "IPv4Internal-Port: " $data] + 19]
						set idx2 [expr [string first "\r\n" $data $idx] -1]
						set port [string range $data $idx $idx2]
					}

					status_log "MSNP2P | $sid -> Receiver is listening with $addr : $port\n" red
					#after 5500 "::MSNP2P::SendData $sid $chatid [lindex [SessionList get $sid] 8]"
					if {$type == "filetransfer" } {
						::MSN6FT::connectMsnFTP $sid $nonce $addr $port 0
					} elseif { $type == "webcam" } {
						::MSNCAM::connectMsnCam2 $sid $nonce $addr $port 0
					}
				}
			}
		}
	}
	# Check if it is a 200 OK message
	if { [string first "MSNSLP/1.0 200 OK" $data] != -1 } {
		# Send a 200 OK ACK
		set first [string first "SessionID:" $data]
		if { $first != -1 } {
			set idx [expr [string first "SessionID:" $data] + 11]
			set idx2 [expr [string first "\r\n" $data $idx] -1]
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
			}
		} else {
			set idx [expr [string first "Call-ID: \{" $data] + 10]
			set idx2 [expr [string first "\}" $data $idx] -1]
			set uid [string range $data $idx $idx2]
			set sid [SessionList findcallid $uid]
			set idx [expr [string first "Listening: " $data] + 11]
			set idx2 [expr [string first "\r\n" $data $idx] -1]
			set listening [string range $data $idx $idx2]

			#status_log "MSNP2P | $sid -> Got 200 OK for File transfer, parsing result\n"
			#status_log "MSNP2P | $sid -> Found uid = $uid , lestening = $listening\n"


			set type [lindex [SessionList get $sid] 7]

			if { $sid != -1 }  {
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
				
				if { $listening == "true" } {
					set idx [expr [string first "Nonce: \{" $data] + 8]
					set idx2 [expr [string first "\r\n" $data $idx] -2]
					set nonce [string range $data $idx $idx2]
					
					if {[string first "IPv4External-Addrs: " $data] != -1 } {
						set idx [expr [string first "IPv4External-Addrs: " $data] + 20]
						set idx2 [expr [string first "\r\n" $data $idx] -1]
						set addr [string range $data $idx $idx2]
						
						set idx [expr [string first "IPv4External-Port: " $data] + 19]
						set idx2 [expr [string first "\r\n" $data $idx] -1]
						set port [string range $data $idx $idx2]
					} else {
						set idx [expr [string first "IPv4Internal-Addrs: " $data] + 20]
						set idx2 [expr [string first "\r\n" $data $idx] -1]
						set addr [string range $data $idx $idx2]
						
						set idx [expr [string first "IPv4Internal-Port: " $data] + 19]
						set idx2 [expr [string first "\r\n" $data $idx] -1]
						set port [string range $data $idx $idx2]						
					}
					status_log "MSNP2P | $sid -> Receiver is listening with $addr : $port\n" red
					#after 5500 "::MSNP2P::SendData $sid $chatid [lindex [SessionList get $sid] 8]"
					::MSN6FT::connectMsnFTP $sid $nonce $addr $port 1
				} elseif { $listening == "false" } {
					status_log "MSNP2P | $sid -> Receiver is not listening, sending INVITE\n" red
					if { $type == "filetransfer" } {
						::MSN6FT::SendFTInvite2 $sid $chatid
					} elseif { $type == "webcam" } {
						#::MSNCAM::SendAcceptInvite $sid $chatid
					}
				} else {
					status_log "Error sending file $filename, got answer to invite :\n$data\n\n" red
				}
			}
		}
		
		
		return
		
		
	}
	
	# Check if we got BYE message
	if { [string first "BYE MSNMSGR:" $data] != -1 } {
		# Lets get the call ID and find our SessionID
		set idx [expr [string first "Call-ID: \{" $data] + 10]
		set idx2 [expr [string first "\}" $data $idx] - 1]
		set uid [string range $data $idx $idx2]
		set sid [SessionList findcallid $uid]
		status_log "MSNP2P | $sid -> Got BYE for UID : $uid\n" red

		if { $sid != -1 } {
			# Send a BYE ACK
			SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
			status_log "MSNP2P | $sid -> Sending BYE ACK\n" red

			# If it's a file transfer, advise the user it has been canceled
			if { [lindex [SessionList get $sid] 7] == "filetransfer" } {
				status_log "File transfer canceled\n"
				if { [::amsn::FTProgress ca $sid [lindex [SessionList get $sid] 6]] == -1 } {
					::amsn::RejectFT $chatid "-2" $sid
				}
			}

			# Delete SessionID Data
			SessionList unset $sid
			
		} else {
			status_log "MSNP2P | $sid -> Got a BYE for unexisting SessionID\n" red
		}
		return
	}
	# Check if we got BYE message
	if { [string first "603 Decline" $data] != -1 } {
		# Lets get the call ID and find our SessionID
		set idx [expr [string first "Call-ID: \{" $data] + 10]
		set idx2 [expr [string first "\}" $data $idx] - 1]
		set uid [string range $data $idx $idx2]
		set sid [SessionList findcallid $uid]
		status_log "MSNP2P | $sid -> Got DECLINE for UID : $uid\n" red

		if { $sid != -1 } {
			# Send a BYE ACK
			SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
			status_log "MSNP2P | $sid -> Sending DECLINE ACK\n" red

			# If it's a file transfer, advise the user it has been canceled
			if { [lindex [SessionList get $sid] 7] == "webcam" } {
				::MSNCAM::SendSyn $sid $chatid
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
			::amsn::FTProgress w $cSid "" [trans throughserver]
			::amsn::FTProgress r $cSid [lindex [SessionList get $cSid] 6] $cOffset $cTotalDataSize
		}
		if { $type != "webcam" && $fd != "" && $fd != 0 && $fd != -1 } {
			# File already open and being written to (fd exists)
			# Lets write data to file
			puts -nonewline $fd [string range $data 0 [expr $cMsgSize - 1]]
			#status_log "MSNP2P | $sid -> FD EXISTS, file already open... with fd = $fd --- $cOffset + $cMsgSize + $cTotalDataSize . Writing DATA to file\n" red
			# Check if this is last part if splitted
			if { [expr $cOffset + $cMsgSize] >= $cTotalDataSize } {
				close $fd
				
				set session_data [SessionList get $cSid]
				set user_login [lindex $session_data 3]
				set filename [lindex $session_data 8]
				
				# Lets send an ACK followed by a BYE if it's a buddy icon or emoticon
				#status_log "MSNP2P | $sid -> Sending an ACK for file received and sending a BYE\n" red
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid $cSid $cTotalDataSize $cId $cAckId]
				
				if { [lindex [SessionList get $cSid] 7] == "bicon" } {
					SendPacket [::MSN::SBFor $chatid] [MakePacket $sid [MakeMSNSLP "BYE" $user_login [::config::getKey login] "19A50529-4196-4DE9-A561-D68B0BF1E83F" 0 [lindex $session_data 5] 0 0] 1]
					
					#set filename2 [::MSNP2P::GetFilenameFromMSNOBJ [::abook::getVolatileData $user_login msnobj]]
					set filename2 [::abook::getContactData $user_login displaypicfile ""]
					status_log "MSNP2P | $sid -> Got picture with file : $filename and $filename2\n" blue
					if {$filename == $filename2 } {
						
						status_log "MSNP2P | $sid -> Closed file $filename.. finished writing\n" red
						set file [png_to_gif [file join $HOME displaypic cache ${filename}.png]]
						if { $file != "" } {
							set file [filenoext $file].gif
							if {[catch {image create photo user_pic_${user_login} -file [file join $HOME displaypic cache "${filename}.gif"]}] } {
								image create photo user_pic_${user_login} -file [::skin::GetSkinFile displaypic nopic.gif]
							}

							set desc_file "[file join $HOME displaypic cache ${filename}.dat]"
					                create_dir [file join $HOME displaypic]
							set fd [open [file join $HOME displaypic $desc_file] w]
							status_log "Writing description to $desc_file\n"
							puts $fd "[clock format [clock seconds] -format %x]\n$user_login"
							close $fd

						}
					} else {
						set file [png_to_gif [file join $HOME smileys cache ${filename}.png]]
						if { $file != "" } {
							set file [filenoext $file].gif
							image create photo custom_smiley_${filename} -file "[file join $HOME smileys cache ${filename}.gif]"
						}
					}

				} elseif { [lindex [SessionList get $cSid] 7] == "filetransfer" } {
					# Display message that file transfer is finished...
					status_log "MSNP2P | $cSid -> File transfer finished!\n"
					::amsn::FTProgress fr $cSid [lindex [SessionList get $cSid] 6] $cOffset $cTotalDataSize
					SessionList set $cSid [list -1 -1 -1 -1 -1 -1 -1 "filetransfersuccessfull" -1 -1]
				}
			}
		} elseif { $cMsgSize == 4 } {
			# We got ourselves a DATA PREPARATION message, lets open file and send ACK
			set session_data [SessionList get $sid]
			set user_login [lindex $session_data 3]
			#status_log "MSNP2P | $sid $user_login -> Got data preparation message, opening file for writing\n" red
			set filename [lindex $session_data 8]
			#set filename2 [::MSNP2P::GetFilenameFromMSNOBJ [::abook::getVolatileData $user_login msnobj]]
			set filename2 [::abook::getContactData $user_login displaypicfile ""]
			#status_log "MSNP2P | $sid $user_login -> opening file $filename for writing with $filename2 as user msnobj\n\n" blue
			if { $filename == $filename2 } {
				create_dir [file join $HOME displaypic cache]
				set fd [open "[file join $HOME displaypic cache ${filename}.png]" w]
			} else {
				create_dir [file join $HOME smileys cache]
				set fd [open "[file join $HOME smileys cache ${filename}.png]" w]   
			}

			fconfigure $fd -translation {binary binary}
			SendPacket [::MSN::SBFor $chatid] [MakeACK $sid $cSid $cTotalDataSize $cId $cAckId]
			#status_log "MSNP2P | $sid $user_login -> Sent an ACK for DATA PREP Message\n" red
			SessionList set $sid [list -1 -1 -1 -1 -1 -1 $fd -1 -1 -1]
		} elseif { $type == "webcam" } {
			# WEBCAM TO COMPLETE
			
			set h1 [string range $data 0 3]
			set h2 [string range $data 4 9]
			set msg [string range $data 10 [expr { $cMsgSize - 1}]]
			set msg [encoding convertfrom unicode $msg]
			status_log "Received data for webcam $sid : $data\n$msg\n" red

			if {[expr $cOffset + $cMsgSize] >= $cTotalDataSize} {
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid $cSid $cTotalDataSize $cId $cAckId]
			}

			if { $msg == "syn\x00" } {
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
			} elseif {[string first "<producer>" $msg] == 0 || [string first "<viewer>" $msg] == 0 || $cOffset != 0} {
				set xml [getObjOption $sid xml]
				set xml "${xml}[string range $data 0 [expr { $cMsgSize - 1}]]"					
						
				setObjOption $sid xml $xml
				
				if { [expr $cOffset + $cMsgSize] >= $cTotalDataSize } {	 
					set xml [string range $xml 10 end]
					setObjOption $sid xml $xml

					::MSNCAM::ReceivedXML $chatid $sid
				}
			
			} else {
				status_log "UNKNOWN" red
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
# filename: the file where data should be saved to
proc RequestObject { chatid dest msnobject} {
	# Let's create a new session
	set sid [expr int([expr rand() * 1000000000])%125000000 + 4]
	# Generate BranchID and CallID
	set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
	set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

	SessionList set $sid [list 0 0 0 $dest 0 $callid 0 "bicon" [::MSNP2P::GetFilenameFromMSNOBJ $msnobject] ""]

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

	# Let's get our session id variables and put them in a list
	# If sessionid is 0, means we want to initiate a new session
	if { $sid != 0 } {
		set SessionInfo [SessionList get $sid]
		set MsgId [lindex $SessionInfo 0]
		set TotalSize [lindex $SessionInfo 1]
		set Offset [lindex $SessionInfo 2]
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
		set bheader [binary format i $sid]
	}

	if { $MsgId == 0 } {
		# No MsgId let's generate one and add to our list
		set MsgId [expr int([expr rand() * 1000000]) + 4]
	} elseif { $Offset == 0 } {
		# Offset is different than 0, we need to incr the MsgId to prepare our next message
		incr MsgId
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
		set MsgId [expr int([expr rand() * 1000000]) + 10]
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
# method :		INVITE, BYE, OK, DECLINE
# contenttype : 	0 for application/x-msnmsgr-sessionreqbody (Starting a session)
#			1 for application/x-msnmsgr-transreqbody (Starting transfer)
#			2 for application/x-msnmsgr-transrespbody (Starting transfer)
#                       3 for null (starting webcam)
#
# If INVITE method is chosen then A, B, C, D and/or E are used dependinf on contenttype
# for 0 we got : "EUF-GUID", "SessionID", "AppID" and "Context" (E not used)
# for 1 we got : "Bridges", "NetID", "Conn-Type", "UPnPNat" and "ICF"
# for 2 we got : "Bridge", "Listening", "Nonce", "IPv4External-Addrs","IPv4External-Port"
#		 "IPv4Internal-Addrs" and "IPv4Internal-Port"
#
# If OK method is chosen then A to G are used depending on contenttype
# for 0 we got : "SessionID"
# for 1 we got : "Bridge", "Listening", "Nonce", "IPv4External-Addrs","IPv4External-Port"
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
		set data "MSNSLP/1.0 603 DECLINE\r\n"
	}

	# Lets create our message body first (so we can calc it's length for the header)
	set body ""
	if { $method == "INVITE" } {
		if { $contenttype == 0 } {
			append body "EUF-GUID: {${A}}\r\nSessionID: ${B}\r\nAppID: ${C}\r\nContext: ${D}\r\n"
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
			append body "SessionID: ${A}\r\n"
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
	} elseif { $method == "DECLINE" } {
		append body "SessionID: ${A}\r\n"
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
	if { [lindex [SessionList get $sid] 1] == 0 } {
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
		fileevent $sock writable "::MSNP2P::SendDataEvent $sbn $sid $fd" 
	}



} 

proc SendDataEvent { sbn sid fd } {


	set sock [$sbn cget -sock]
	fileevent $sock writable ""
	#return

	set offset [lindex [SessionList get $sid] 2]
	set filesize [lindex [SessionList get $sid] 1]

	if { $offset == "" } {
		close $fd
		return
	}
	
	set data [read $fd 1202]
	#		status_log "Reading 1202 bytes of data : got [string length $data]"
	if { [string length $data] >= 1202 } {
		set msg [MakePacket $sid $data 0 0 0 0 0 0 16777264]
		set msg_len [string length $msg]
		puts -nonewline $sock "MSG [incr ::MSN::trid] D $msg_len\r\n$msg"
		set offset [expr $offset + 1202]
		SessionList set $sid [list -1 -1 $offset -1 -1 -1 -1 -1 -1 -1]
		::amsn::FTProgress s $sid "" $offset $filesize
		catch {after 200 [list fileevent $sock writable "::MSNP2P::SendDataEvent $sbn $sid $fd"]}
	} else {

		set msg [MakePacket $sid $data 0 0 0 0 0 0 16777264]
		set msg_len [string length $msg]
		puts -nonewline $sock "MSG [incr ::MSN::trid] D $msg_len\r\n$msg"
		set offset [expr $offset + 1202]	
		SessionList set $sid [list -1 -1 0 -1 -1 -1 -1 -1 -1 -1 ]
		
		set msgId [expr [lindex [SessionList get $sid] 0] + 1]
		SessionList set $sid [list $msgId -1 0 -1 DATASENT -1 0 -1 -1 -1]
		close $fd
		unset fd

		::amsn::FTProgress fs $sid ""
	}
}



#//////////////////////////////////////////////////////////////////////////////
# SendPacket ( sbn msg )
# This function sends the packet given by (msg) into the given (sbn)
proc SendPacket { sbn msg } {
	#	if { [string length $msg] > 1202 } 
	set msg_len [string length $msg]
	::MSN::WriteSBNoNL $sbn "MSG" "D $msg_len\r\n$msg"
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

	if { [expr $offset + 1202] < [string length $slpdata] } {
		set msg [MakePacket $sid [string range $slpdata $offset [expr $offset + 1201]] $nullsid $MsgId $TotalSize $Offset $Destination $AfterAck $flags]
		set msg_len [string length $msg]
		::MSN::WriteSBNoNL $sbn "MSG" "D $msg_len\r\n$msg"
		set offset [expr $offset + 1202]
		SessionList set $sid [list -1 -1 $offset -1 -1 -1 -1 -1 -1 -1]
		after 200 [list fileevent $fd writable "::MSNP2P::SendPacketExtEvent $sbn $sid [list $slpdata] $nullsid $MsgId $TotalSize $Offset $Destination $AfterAck $flags" ]
	} else {

		set msg [MakePacket $sid [string range $slpdata $offset [expr $offset + 1201]] $nullsid $MsgId $TotalSize $Offset $Destination $AfterAck $flags]
		set msg_len [string length $msg]
		::MSN::WriteSBNoNL $sbn "MSG" "D $msg_len\r\n$msg"
		set offset [expr $offset + 1202]	
		SessionList set $sid [list -1 -1 0 -1 -1 -1 -1 -1 -1 -1 ]
	}
}

}
