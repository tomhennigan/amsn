#	Microsoft Messenger Protocol Implementation
#=======================================================================

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
	package require snit
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
       	::amsn::fileTransferRecv $filename $filesize $cookie $chatid $fromlogin
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

      set ipaddr [$message getField $requestdata]

      #If IP field is blank, and we are sender, Send the File and requested IP (SendFile)
      if { ($ipaddr == "") && ([getTransferType $cookie]=="send") } {

      	status_log "Invitation to filetransfer $cookie accepted\n" black
	 	::amsn::acceptedFT $chatid $fromlogin [getFilename $cookie]
	 	set newcookie [::md5::md5 "$cookie$fromlogin"]
	 	set filedata($newcookie) $filedata($cookie)
      	SendFile $newcookie $cookie
      	#TODO: Show accept or reject messages from other users? (If transferType=="receive")
      } elseif {($ipaddr == "") && ([getTransferType $cookie]!="send")} {
      	::amsn::acceptedFT $chatid $fromlogin [getFilename $cookie]
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
      global files_dir
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
      global files_dir
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

      switch $state {
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
		 #cancelFT $cookie
		 #return
	      }

              status_log "FTNegotiation: They send me file with size $filesize\n"
              catch {puts $sockid "TFR\r"}
              status_log "Receiving file...\n"

              set filename [file join ${files_dir} [lindex $filedata($cookie) 0]]
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

   proc sendFTInvitation { chatid filename filesize ipaddr cookie} {
      #Invitation to filetransfer, initial message
      variable filedata

		#Use new FT protocol only if the user choosed this option in advanced preferences.
      if {[::config::getKey new_ft_protocol]} {
      	::MSN6FT::SendFT $chatid $filename $filesize
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
	if {[::config::getKey new_ft_protocol]} {
	    #TODO: here we should send CANCEL message so the other side will know it is cancelled
	} {
	    rejectFT $chatid $cookie
	}
    }

   proc rejectedFT {chatid who cookie} {
      variable filedata

      if {![info exists filedata($cookie)]} {
         return
      }

      ::amsn::rejectedFT $chatid $who [getFilename $cookie]

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
      global files_dir
      variable filedata

      #puts "Here2 state=$state cookie=$cookie sockid=$sockid"

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

      switch $state {
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

	      #Comprobar authcookie y nombre de usuario

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

#      puts "cookie=$cookie"
      if {![info exists filedata($cookie)]} {
        status_log "ConnectedMSNFTP: Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
        return
      }

      #Send a packet for the file transfer
      fileevent $sockid writable ""

      set sentbytes [tell $fileid]

      if {[expr {$filesize-$sentbytes >2045}]} {
         set packetsize 2045
      } else {
         set packetsize [expr {$filesize-$sentbytes}]
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
   unblockUser addUser deleteUser login myStatusIs \
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
		cmsn_draw_reconnect $error_msg
		after 5000 ::MSN::connect

	}

	proc cancelReconnect { } {

		after cancel ::MSN::connect
		catch { unset ::oldstatus }
		::MSN::logout

	}


	proc connect { {passwd ""}} {

		#Cancel any pending reconnect
		after cancel ::MSN::connect


		if { [ns cget -stat] != "d" } {
			return
		}

		set username [::config::getKey login]

		if { $passwd == "" } {
			global password
			set passwd [set password]
		}

		ns configure -stat "d" -sock "" \
			-server [split [::config::getKey start_ns_server] ":"]

		#Setup the conection
		setup_connection ns
		#Call the pre authentication
		set proxy [ns cget -proxy]
		if { [$proxy authInit] < 0 } {
			return -1
		}

		cmsn_ns_connect $username $passwd

  	 }


	proc logout {} {

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

		set list_BLP -1
		if { [info exists emailBList] } {
			unset emailBList
		}

		::abook::unsetConsistent

		set automessage "-1"

		cmsn_draw_offline

		#an event to let the GUI know we are actually logged out now
		::Event::fireEvent loggedOut protocol

		#Alert dock of status change
		#      send_dock "FLN"
		send_dock "STATUS" "FLN"
	}


	#Callback procedure called when a REA (screen name change) message is received
	proc GotREAResponse { recv } {


		if { [string tolower [lindex $recv 3]] == [string tolower [::config::getKey login]] } {
			#This is our own nick change
			::abook::setPersonal nick [urldecode [lindex $recv 4]]
			send_dock STATUS [::MSN::myStatusIs]
			cmsn_draw_online 1
			#an event used by guicontactlist to know when we changed our nick
			::Event::fireEvent myNickChange protocol
		} else {
			#This is another one nick change
			::abook::setContactData [lindex $recv 3] nick [urldecode [lindex $recv 4]]
			#an event used by guicontactlist to know when a contact changed nick
			::Event::fireEvent contactNickChange protocol [lindex $recv 3]
		}

	}

	#Handler when we're setting our nick, so we check if the nick is allowed or not
	proc badNickCheck { userlogin newname recv } {

		if { "[lindex $recv 0]" == "209"} {

			#Try again urlencoding any character
			set name [urlencode_all $newname]
			::MSN::WriteSB ns "REA" "$userlogin $name"
			return 0

		} elseif { "[lindex $recv 0]" == "REA"} {
			GotREAResponse $recv
			return 0
		}
	}

	#Change a users nickname
	proc changeName { userlogin newname { nourlencode 0 } } {

		if { $userlogin == "" } {
			return
		}

		if { $nourlencode } {
			set name $newname
		} else {
			set name [urlencode $newname]
		}

		if { [::config::getKey allowbadwords] == 1 } {
			#If we're allowing banned words in nicks, try to set usual nick. It it fails,
			#we will try again urlencoding every character, to avoid censure
			::MSN::WriteSB ns "REA" "$userlogin $name" \
				"::MSN::badNickCheck $userlogin [list $name]"
		} else {
			::MSN::WriteSB ns "REA" "$userlogin $name"
		}
	}


	#Procedure called to change our status
	proc changeStatus {new_status} {
		global autostatuschange clientid

#		set clientid 805306412
		if { [::config::getKey displaypic] != "" } {
			::MSN::WriteSB ns "CHG" "$new_status $clientid [urlencode [create_msnobj [::config::getKey login] 3 [::skin::GetSkinFile displaypic [::config::getKey displaypic]]]]"
		} else {
			::MSN::WriteSB ns "CHG" "$new_status $clientid"
		}

		#Reset automatic status change to 0
		set autostatuschange 0

	}


	proc myStatusIs {} {
		variable myStatus
		return $myStatus
	}

	proc setMyStatus { status } {
		variable myStatus
		set myStatus $status
	}

	proc userIsBlocked {userlogin} {
		set lists [::abook::getLists $userlogin]
		if { [lsearch $lists BL] != -1} {
			return 1
		}
		return 0

	}

	proc blockUser { userlogin username} {
	::MSN::WriteSB ns REM "AL $userlogin"
	::MSN::WriteSB ns ADD "BL $userlogin $username"

	#an event to let the GUI know a user is blocked
	after 500 ::Event::fireEvent blockedContact protocol $userlogin

	}

	proc unblockUser { userlogin username} {
		::MSN::WriteSB ns REM "BL $userlogin"
		::MSN::WriteSB ns ADD "AL $userlogin $username"
	#an event to let the GUI know a user is unblocked
	after 500 ::Event::fireEvent unblockedContact protocol $userlogin
	}

	# Move user from one group to another group
	proc moveUser { passport oldGid newGid {userName ""}} {
		if { $userName == "" } {
			set userName $passport
		}
		set atrid [::MSN::WriteSB ns "ADD" "FL $passport [urlencode $userName] $newGid"]
		set rtrid [::MSN::WriteSB ns "REM" "FL $passport $oldGid"]

		#an event to let the GUI know a user is moved between 2 groups
		::Event::fireEvent movedContact protocol $passport $oldGid $newGid


	}

	#Copy user from one group to another
	proc copyUser { passport newGid {userName ""}} {
		if { $userName == "" } {
			set userName $passport
		}
		set atrid [::MSN::WriteSB ns "ADD" "FL $passport [urlencode $userName] $newGid"]
		#an event to let the GUI know a user is copied/added to a group
		::Event::fireEvent addedUser protocol $passport $newGid
	}


	#Add user to our Forward (contact) list
	proc addUser { userlogin {username ""} {gid 0} } {
		set userlogin [string map {" " ""} $userlogin]
		if {[string match "*@*" $userlogin] < 1 } {
			set domain "@hotmail.com"
			set userlogin $userlogin$domain
		}
		if { $username == "" } {
			set username $userlogin
		}
		::MSN::WriteSB ns "ADD" "FL $userlogin $username $gid" "::MSN::ADDHandler"
	}


	#Handler for the ADD message, to show the ADD messagebox
	proc ADDHandler { item } {
		if { [lindex $item 2] == "FL"} {
			set contact [urldecode [lindex $item 4]]    ;# Email address
			#an event to let the GUI know a user is copied/added to a group
			set newGid [lindex $item 6]
			::Event::fireEvent addedUser protocol $contact $newGid
			msg_box "[trans contactadded]\n$contact"
		}

		if { [lindex $item 0] == 500 } {
			#Instead of disconnection, transform into error 201
			cmsn_ns_handler [lreplace $item 0 0 201]
			return
		}

		cmsn_ns_handler $item

	}

	#Delete user (from a given group $grID, or from all groups)
	proc deleteUser { userlogin {grId ""}} {
		if { $grId == "" } {
			::MSN::WriteSB ns REM "FL $userlogin"
		} else {
			::MSN::WriteSB ns REM "FL $userlogin $grId"
		}
		#an event to let the GUI know a user is removed from a group / the list
		::Event::fireEvent deletedUser protocol $userlogin $grId
	}

	##################################################
	#Internal procedures
	##################################################

	#Start the loop that will keep a keepalive (PNG) message every minute
	proc StartPolling {} {

		if {([::config::getKey keepalive] == 1) && ([::config::getKey connectiontype] == "direct")} {
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
		#Let's try to keep the connection alive... sometimes it gets closed if we
		#don't do send or receive something for a long time
		if { [::MSN::myStatusIs] != "FLN" } {
			::MSN::WriteSBRaw ns "PNG\r\n"
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
			lappend list_cmdhnd [list $trid $handler]
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


	########################################################################
	# Check if the old closed preferred SB is still the preferred SB, or
	# close it if not.
	proc CheckKill { sb } {

		#Kill any remaining timers
		after cancel "::MSN::CheckKill $sb"

		if { [info procs $sb] == "" } {
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
				::MSN::KillSB $sb
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

		if {$sock != ""} {
			set proxy [$sb cget -proxy]
			$proxy finish $sb
#			$proxy destroy
		}

#		#Append an empty string to the SB buffer. This will cause the
#		#actual SB cleaning, but will allow to process all buffer
#		#before doing the cleaning
#		$sb addData ""
		ClearSB $sb
	}
	#///////////////////////////////////////////////////////////////////////

	########################################################################
	#Called when we find a "" (empty string) in the SB buffer. This means
	#the SB is closed. Proceed to clear everything related to it
	proc ClearSB { sb } {

		status_log "::MSN::ClearSB $sb called\n" green

		set oldstat [$sb cget -stat]
#		$sb configure -data ""
		$sb configure -sock ""
		$sb configure -stat "d"

		if { [string first NS $sb] != -1 || $sb == "ns" } {
			status_log "clearing sb $sb. oldstat=$oldstat"
			set mystatus [::MSN::myStatusIs]

			#If we were not disconnected or authenticating, logout
			if { ("$oldstat" != "d") && ("$oldstat" != "u") } {
				logout
			}

			#If we're not disconnected, connected, or authenticating, then
			#we have a connection error.
			if { ("$oldstat"!="d") && ("$oldstat" !="o") && ("$oldstat" !="u") && ("$oldstat" !="closed")} {

				set error_msg [ns cget -error_msg]
				#Reconnect if necessary
				if { [::config::getKey reconnect] == 1 } {
					set ::oldstatus $mystatus
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

				set error_msg [ns cget -error_msg]
				#Reconnect if necessary
				if { [::config::getKey reconnect] == 1 } {
					set ::oldstatus $mystatus
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
			#MSN6 challenge strings
			#Get the challenge string, append this string, and
			#send back the md5sum of the composed string
			set str [lindex $item 2]JXQ6J@TUOGYV@N0M
			set str [::md5::md5 $str]

			::MSN::WriteSBNoNL ns "QRY" "PROD0061VRRZH@4F 32\r\n$str"

		}
	}

	proc CALReceived {sb_name user item} {

		switch [lindex $item 0] {
			216 {
				# if you try to begin a chat session with someone who blocked you and is online
				set chatid [::MSN::ChatFor $sb_name]
				::MSN::ClearQueue $chatid
				::amsn::chatStatus $chatid "$user: [trans userblocked]\n" miniwarning
				warn_blocked $user
				return 0
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
				#msg_box "[trans usernotonline]"
				user_not_blocked $user
				return 0
			}
			713 {
				status_log "CALReceived: 713 USER TOO ACTIVE \nStoping the VerifyBlocked procedure\n" white
				StopVerifyBlocked
				return 0
			}
		}
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
      #if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
      #	set operatingsystem "Mac OS X"
      #} elseif {$tcl_platform(platform) == "windows"} {
      #	set operatingsystem "Windows"
      #} elseif {$tcl_platform(platform) == "unix"} {
      #	set operatingsystem "Linux"
      #}
      #Add the operating system to the msg
      #set msg "${msg}Operating-System: $operatingsystem\r\n\r\n"
      #Send the packet
      #set msg [encoding convertto utf-8 $msg]
      set msg_len [string length $msg]
      WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"

      status_log "Send text/x-clientcaps\n" red
      #status_log "$msg" red

   }

	# Return a list of users in chat, or last user in chat is chat is closed
	proc usersInChat { chatid } {

		set sb [SBFor $chatid]

		if { $sb == 0 || [info procs $sb] == "" } {
			status_log "usersInChat: no SB for chat $chatid!! (shouldn't happen?)\n" white
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

		if { $sb == 0 } {
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
		}
		#Now we have a SB ready for reconnection
		cmsn_reconnect $sb

		return $lowuser
	}


	########################################################################
	#Totally remove the given SB
	proc KillSB { sb } {
		global sb_list

		status_log "::MSN::KillSB: Killing SB $sb\n"

		set idx [lsearch -exact $sb_list $sb]

		if {$idx == -1} {
			return 0
		}

		catch {
			#fileevent [$name cget -sock] readable ""
			#fileevent [$name cget -sock] writable ""
			set proxy [$sb cget -proxy]
			$proxy finish $sb
#			$proxy destroy
		} res

		set sb_list [lreplace $sb_list $idx $idx ]

		$sb destroy
	}


	########################################################################
	#Totally clean a chat. Remove all associated SBs
	proc CleanChat { chatid } {

		status_log "::MSN::CleanChat: Cleaning chat $chatid\n"

		while { [SBFor $chatid] != 0 } {

			set sb [SBFor $chatid]
			DelSBFor $chatid ${sb}

			#We leave the switchboard if it exists
			if {[info procs $sb] != ""} {
				if {[$sb cget -stat] != "d"} {
					WriteSBRaw $sb "OUT\r\n"
				}
			}

			after 60000 "::MSN::KillSB ${sb}"
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

		if { "$sb" == "0" } {
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
	#Given a chatid, retuen the preferred SB to be used for that chat
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
			after 3000 "::MSN::ProcessQueue $chatid [expr {$count + 1}]"

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


		#set sock [$sbn cget -sock]

		set txt_send [string map {"\r\n" "\n"} $txt]
		set txt_send [string map {"\n" "\r\n"} $txt_send]
		set txt_send [encoding convertto identity $txt_send]

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

		set smile_send "[process_custom_smileys_SB $txt_send]"


		set msg "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n"
		if { $friendlyname != "" } {
			set msg "${msg}P4-Context: $friendlyname\r\n"
		} elseif { [::config::getKey p4c_name] != "" } {
			set msg "${msg}P4-Context: [::config::getKey p4c_name]\r\n"
		}
		#set msg "${msg}x-clientcaps : aMSN/[set ::version]\r\n"
		set msg "${msg}X-MMS-IM-Format: FN=[urlencode $fontfamily]; EF=$style; CO=$color; CS=0; PF=22\r\n\r\n"
		set msg "$msg$txt_send"
		#set msg_len [string length $msg]
		set msg_len [string length $msg]

		#WriteSB $sbn "MSG" "A $msg_len"
		#WriteSBRaw $sbn "$msg"
		if { $smile_send != "" } {
			set smilemsg "MIME-Version: 1.0\r\nContent-Type: text/x-mms-emoticon\r\n\r\n"
			set smilemsg "$smilemsg$smile_send"
			set smilemsg_len [string length $smilemsg]
			WriteSBNoNL $sbn "MSG" "A $smilemsg_len\r\n$smilemsg"
			set msgacks($::MSN::trid) $ackid
		}

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
		}

		if {![chatReady $chatid] && [::abook::getVolatileData [lindex [usersInChat $chatid] 0] state] == "FLN" } {
			status_log "::MSN::messageTo: chat NOT ready for $chatid\n"
			::amsn::nackMessage $ackid
			chatTo $chatid
			return 0
		}
		ChatQueue $chatid [list ::MSN::SendChatMsg $chatid "$txt" $ackid $friendlyname]
	}
	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////
	#Parses "name: value\nname: value\n..." headers and returns the "value" for "name"
	#TODO remove this proc after deleting the stuff that needs it in the proxy code
	#///////////////////////////////////////////////////////////////////////////////
	proc GetHeaderValue { bodywithr name } {

		set body "\n[string map {"\r" ""} $bodywithr]"
		set pos [string first "\n${name}:" $body]

		if { $pos < 0 } {
			return ""
		} else {
			set strstart [expr { $pos + [string length $name] + 3 } ]
			set strend [expr { $strstart + [string first "\n" [string range $body $strstart end]] - 1 } ]
			return [string range $body $strstart $strend]
		}
		#///////////////////////////////////////////////////////////////////////////////

	}


	########################################################################
	# Return a sorted version of the contact list
	proc sortedContactList { } {
		variable list_users

		#Don't sort list again if it's already sorted
		if { $list_users == "" } {
			set list_users [lsort -increasing -command ::MSN::CompareState [lsort -increasing -command ::MSN::CompareNick [::MSN::getList FL]]]
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

	#Add a user to a list
	proc addToList {list_type user} {
		variable list_${list_type}

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
		return [string compare -nocase [::abook::getDisplayNick $item1] [::abook::getDisplayNick $item2]]
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


	proc stateToColor { state_code } {
		variable list_states
		set state [lindex $list_states [lsearch $list_states "$state_code *"]]
		set skincolor [::skin::getKey "contact_[lindex $state 1]"]

		if { $skincolor == "" } {
			return [lindex $state 2]
		} else {
			return $skincolor
		}
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

}

namespace eval ::Event {

	variable eventsArray

	# sends to all interested listeners the event that occured
	# eventName: name of the event that happened
	# caller:    the object that fires the event, set to all to
	#            notify all listeners for all events with that name
	proc fireEvent { eventName caller args } {
		variable eventsArray
		#fire events registered for both the current caller and 'all'
		foreach call [list $caller "all"] {
			#first check there were some events registered to caller or it will fail
			if { [array names eventsArray "$eventName,$call"] == "$eventName,$call" } {
				foreach listener [set eventsArray($eventName,$call)] {
					$listener $eventName $args
				}
			}
		}
	}

	# registers a listener for an event
	# the listener has to have a method the same as the eventName
	# eventName: name of the event to listen to
	# caller:    the object that fires the event, set to all to
	#            register for all events with that name
	# listener:  the object that wants to receive the events
	proc registerEvent { eventName caller listener } {
		variable eventsArray
		lappend eventsArray($eventName,$caller) $listener
	}

}

::snit::type Test {

	constructor {args} {
		::Event::registerEvent messageReceived all $self
		::Event::registerEvent messageReceived test $self
	}

	method messageReceived { message } {
		puts [$message getBody]
	}
}

::snit::type Message {

	variable fields
	variable headers
	variable body ""

	constructor {args} {
		#TODO: remove me when object is destroyed in the right place
		after 30000 $self destroy
	}

	method setRaw { data } {
		set body $data
		array set header {}
		array set fields {}
	}

	#creates a message object from a received payload
	method createFromPayload { payload } {
		set idx [string first "\r\n\r\n" $payload]
		set head [string range $payload 0 [expr $idx -1]]
		set body [string range $payload [expr $idx +4] end]
		set head [string map {"\r\n" "\n"} $head]
		set heads [split $head "\n"]
		foreach header $heads {
			set idx [string first ": " $header]
			array set headers [list [string range $header 0 [expr $idx -1]] \
					  [string range $header [expr $idx +2] end]]
		}

		set bsplit [split [string map {"\r\n" "\n"} $body] "\n"]
		foreach field $bsplit {
			set idx [string first ": " $field]
			array set fields [list [string range $field  0  [expr $idx -1]] \
			                       [string range $field [expr $idx +2] end]]
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
	option -proxy_host
	option -proxy_authenticate

	variable dataBuffer ""

	##########################################################################################
	# Public methods
	# these are the methods you want to call from outside this object


	##########################################################################################
	# Private methods
	# these are the methods you DON'T want to call from outside this object, only from inside

	#this method is called when the socket becomes readable
	#it will get data from the socket and call handleCommand
	method receivedData { } {

		set dataRemains 1
		while { $dataRemains } {

			#put available data in buffer. When buffer is empty dataRemains is set to 0
			set dataRemains [$self appendDataToBuffer]

			#check for the a newline, if there is we have a command if not return
			set idx [string first "\r\n" $dataBuffer]
			if { $idx == -1 } { return }
			set command [string range $dataBuffer 0 [expr $idx -1]]

			#check for payload commands:
			if {[lsearch {MSG NOT PAG IPG} [string range $command 0 2]] != -1} {
			        set length [lindex [split $command] end]

				set remaining [string range $dataBuffer [expr $idx +2] end]
				#if the whole payload is in the buffer process the command else return
				if { [string length $remaining] >= $length } {
					set payload [string range $remaining 0 [expr $length -1]]
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
			if { $tmp_data == "" } {
			}
			append dataBuffer $tmp_data
			return 1
		}
	}

	method sockError { } {
		::MSN::CloseSB $self
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
		catch { $self connection destroy }
	}

	method handleCommand { command {payload ""}} {
		degt_protocol "<-ns-[$self cget -sock] $command" "nsrecv"
		set message ""
		if { $payload != "" } {
			degt_protocol "Message Contents:\n$payload" "nsrecv"
			set message [Message create %AUTO%]
			$message createFromPayload $payload
		}
		if {[lindex [split $command] 0] == "IPG" } {
			cmsn_ns_handler [split $command] $payload
		} else {
			cmsn_ns_handler [split $command] $message
		}
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


	constructor {args} {
		install connection using Connection %AUTO% -name $self
		$self configurelist $args
	}

	destructor {
		catch { $self connection destroy }
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
		set idx [lsearch $list_cmdhnd "$ret_trid *"]

		if {$idx != -1} {		;# Command has a handler associated!
			status_log "sb::handleCommand: Evaluating handler for $ret_trid in SB $self\n"
			set cmd "[lindex [lindex $list_cmdhnd $idx] 1] {$command}"
			set list_cmdhnd [lreplace $list_cmdhnd $idx $idx]
			eval "$cmd"
			return 0
		} else {
			switch [lindex $command 0] {
				MSG {
					$self handleMSG $command $message
					return 0
				}
				BYE -
				JOI -
				IRO {
					cmsn_update_users $self $command
					return 0
				}
				CAL {
					#status_log "$self_name: [join $command]\n" green
					return 0
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
					}
					return 0
				}
				NAK {
					if { ! [info exists msgacks($ret_trid)]} {
					return 0
					}
					set ackid $msgacks($ret_trid)
					::amsn::nackMessage $ackid
					#::MSN::retryMessage $ackid
					unset msgacks($ret_trid)
					return 0
				}
				ACK {
					if { ! [info exists msgacks($ret_trid)]} {
					return 0
					}
					set ackid $msgacks($ret_trid)
					::amsn::ackMessage $ackid
					unset msgacks($ret_trid)
					return 0
				}
				208 {
					status_log "sb::handleCommand: invalid user name for chat\n" red
					msg_box "[trans invalidusername]"
				}
				215 {
					#if you try to begin a chat session with yourself
					set chatid [::MSN::ChatFor $self]
					::MSN::ClearQueue $chatid
					::amsn::chatStatus $chatid "[trans useryourself]\n" miniwarning
					return 0
				}
				"" {
					return 0
				}
				default {
					if { "[$self cget -stat ]" == "d" } {
						status_log "$self: UNKNOWN SB ENTRY! --> [join $command]\n" red
					}
					return 0
				}
			}
		}
	}

	method handleMSG { command message } {

		set p4context [$message getHeader P4-Context]

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
				status_log "cmsn_sb_msg: Trying to change chatid from $chatid to $desiredchatid for SB $sb\n"
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


		set contentType [lindex [split [$message getHeader Content-Type] ";"] 0]
		switch $contentType {
			text/plain {
				::Event::fireEvent messageReceived $self $message
				$message setBody [encoding convertfrom identity [string map {"\r\n" "\n"} [$message getBody]]]

				::amsn::messageFrom $chatid $typer $nick $message user $p4c_enabled
				set options(-lastmsgtime) [clock format [clock seconds] -format %H:%M:%S]
				::abook::setContactData $typer last_msgedme [clock format [clock seconds] -format "%D - %H:%M:%S"]
				#if alarm_onmsg is on run it
				if { ( [::alarms::isEnabled $typer] == 1 )&& ( [::alarms::getAlarmItem $typer onmsg] == 1) } {
					set username [::abook::getDisplayNick $typer]
					run_alarm $typer  $username "[trans says $username]: [$message getBody]"
				} elseif { ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all onmsg] == 1) } {
					set username [::abook::getDisplayNick $typer]
					run_alarm $typer  $username "[trans says $username]: [$message getBody]"
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
				::MSN::addSBTyper $self $typer
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
				puts $invcommand
				puts $cookie

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
						::MSNAV::invitationReceived $cookie $context $chatid $fromlogin

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
				#TODO: check if header P2P-Dest == our own nick. If not, discard message
				set p2pmessage [P2PMessage create %AUTO%]
				$p2pmessage createFromMessage $message
				::MSNP2P::ReadData $p2pmessage $chatid
				#status_log [$p2pmessage toString 1]
			}

			text/x-mms-emoticon -
			text/x-mms-animemoticon {
				global ${chatid}_smileys
				status_log "Got a custom smiley from peer\n" red
				set ${chatid}_smileys(dummy) ""
				parse_x_mms_emoticon [$message getBody] $chatid
				status_log "got smileys : [array names ${chatid}_smileys]\n" blue
				foreach smile [array names ${chatid}_smileys] {
					if { $smile == "dummy" } { continue }
					MSNP2P::loadUserSmiley $chatid $typer "[set ${chatid}_smileys($smile)]"
				}
			}

			text/x-clientcaps {
				#Packet we receive from 3rd party client (not by MSN)
				xclientcaps_received $message $typer
			}

			default {
				status_log "$self handleMSG: === UNKNOWN MSG ===\n$command\n[$message getHeaders]\n[$message getBody]" red
				#Postevent for others kinds of packet (like nudge)
				set evpar(chatid) chatid
				set evpar(nick) nick
				set evpar(msg) message
				::plugins::PostEvent PacketReceived evpar
			}
		}
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
	global tcl_platform
	foreach line [split $text "\n"] {
		if {[string index $line 0] == "|"} {
			set cmd [string range $line 1 [string length $line]]
			if {$tcl_platform(platform) == "unix"} {
				catch {exec /bin/sh -c $cmd} output
			} elseif {$tcl_platform(platform) == "windows"} {
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

	set emaill [string tolower [lindex $recv 5]]

	set sb [::MSN::GetNewSB]

	#Init SB properly
	$sb configure -stat ""
	$sb configure -server [split [lindex $recv 2] ":"]
	$sb configure -connected [list cmsn_conn_ans $sb]
	$sb configure -auth_cmd "ANS"
	$sb configure -auth_param "[::config::getKey login] [lindex $recv 4] [lindex $recv 1]"

	lappend sb_list "$sb"

	status_log "Accepting conversation from: [lindex $recv 5]... (Got ANS1 in SB $sb\n" green

	setup_connection $sb
	cmsn_socket $sb
	return 0
}

proc cmsn_open_sb {sb recv} {

	#if the sb doesn't exist return
	if {[info procs $sb] == ""} {
		return 0
	}

	#TODO: I hope this works. If stat is not "c" (trying to connect), ignore
	if { [$sb cget -stat] != "c" } {
		return 0
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

	$sb configure -server [split [lindex $recv 3] ":"]
	$sb configure -connected [list cmsn_conn_sb $sb]
	$sb configure -auth_cmd "USR"
	$sb configure -auth_param "[::config::getKey login] [lindex $recv 5]"


	::amsn::chatStatus [::MSN::ChatFor $sb] "[trans sbcon]...\n" miniinfo ready
	setup_connection $sb
	cmsn_socket $sb
	return 0
}



proc cmsn_conn_sb {sb sock} {

	catch { fileevent $sock writable "" } res

	#Reset timeout timer
	$sb configure -time [clock seconds]

	$sb configure -stat "a"

	set cmd [$sb cget -auth_cmd]
	set param [$sb cget -auth_param]

	::MSN::WriteSB $sb $cmd $param "cmsn_connected_sb $sb"

	::amsn::chatStatus [::MSN::ChatFor $sb] "[trans ident]...\n" miniinfo ready

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

	if {[$sb cget -invite] != ""} {

		cmsn_invite_user $sb [$sb cget -invite]

		::amsn::chatStatus [::MSN::ChatFor $sb] \
			"[trans willjoin [$sb cget -invite]]...\n" miniinfo ready

	} else {

		status_log "cmsn_connected_sb: got SB $sb stat=i but no one to invite!!! CHECK!!\n" white

	}

}

#SB stat values:
#  "d" - Disconnected, the SB is not connected to the server
#  "c" - The SB is going to get a socket to connect to the server.
#  "cw" - "Connect wait" The SB is trying to connect to the server.
#  "a" - Authenticating. The SB is authenticating to the server
#  "i" - Inviting first person to the chat. Successive invitations will be while in "o" status
#  "o" - Opened. The SB is connected and ready for chat
#  "n" - Nobody. The SB is connected but there's nobody at the conversation


proc cmsn_reconnect { sb } {

	switch [$sb cget -stat] {
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

			#status_log "cmsn_reconnect: stat = i , SB= $name\n" green

			if { [expr {[clock seconds] - [$sb cget -time]}] > 15 } {
				status_log "cmsn_reconnect: called again while inviting timeouted for sb $sb\n" red
				#catch { fileevent [$name cget -sock] readable "" } res
				#catch { fileevent [$name cget -sock] writable "" } res
				set proxy [$sb cget -proxy]
				$proxy finish $sb
				$sb configure -stat "d"
				cmsn_reconnect $sb
			}

		}

		"c" {

			#status_log "cmsn_reconnect: stat = c , SB= $name\n" green

			if { [expr {[clock seconds] - [$sb cget -time]}] > 10 } {
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

			#status_log "cmsn_reconnect: stat =[$name cget -stat] , SB= $name\n" green

			if { [expr {[clock seconds] - [$sb cget -time]}] > 10 } {
				status_log "cmsn_reconnect: called again while authentication timeouted for sb $sb\n" red
				#catch { fileevent [$name cget -sock] readable "" } res
				#catch { fileevent [$name cget -sock] writable "" } res
				set command [$sb cget -proxy]
				$proxy finish $sb
				$sb configure -stat "d"
				cmsn_reconnect $sb
			}
		}
		"" {
			status_log "cmsn_reconnect: SB $name stat is [$name cget -stat]. This is bad, should delete it and create a new one\n" red
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

	switch [lindex $recv 0] {

		BYE {

			set chatid [::MSN::ChatFor $sb]


			set leaves [$sb search -users "[lindex $recv 1]"]
			$sb configure -last_user [lindex [$sb cget -users] $leaves]
			$sb delUser $leaves

			set usr_login [lindex [$sb cget -users] 0]

			if { [llength [$sb cget -users]] == 1 } {
				#We were a conference! try to become a private

				set desiredchatid $usr_login

				set newchatid [::ChatWindow::Change $chatid $desiredchatid]

				if { "$newchatid" != "$desiredchatid" } {
					#The GUI doesn't accept the change, as there's another window for that chatid
					status_log "cmsn_update_users: change NOT accepted from $chatid to $desiredchatid\n"

				} else {
					#The GUI accepts the change, so let's change
					status_log "cmsn_update_users: change accepted from $chatid to $desiredchatid\n"

					::MSN::DelSBFor $chatid $sb
					::MSN::AddSBFor $newchatid $sb



					set chatid $newchatid


				}

			} elseif { [llength [$sb cget -users]] == 0 && [$sb cget -stat] != "d" } {
				$sb configure -stat "n"
			}

			#Another option for the condition:
			# "$chatid" != "[lindex $recv 1]" || ![MSN::chatReady $chatid]
			if { [::MSN::SBFor $chatid] == $sb } {
				if { [lindex $recv 2] == "1" } {
					::amsn::userLeaves $chatid [list [lindex $recv 1]] 0
				} else {
					::amsn::userLeaves $chatid [list [lindex $recv 1]] 1
				}
			}
		}

		IRO {

			#You get an IRO message when you're invited to some chat. The chatid name won't be known
			#until the first message comes
			$sb configure -stat "o"

			set usr_login [string tolower [lindex $recv 4]]
			set usr_name [urldecode [lindex $recv 5]]

			$sb addUser [list $usr_login]

			::abook::setContactData $usr_login nick $usr_name

			$sb configure -last_user $usr_login

		}

		JOI {
			$sb configure -stat "o"

			set usr_login [string tolower [lindex $recv 1]]
			set usr_name [urldecode [lindex $recv 2]]

			$sb addUser [list $usr_login]

			::abook::setContactData $usr_login nick $usr_name


			if { [llength [$sb cget -users]] == 1 } {

				$sb configure -last_user $usr_login
				set chatid $usr_login

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

			}

			#Don't put it in status if we're not the preferred SB.
			#It can happen that you invite a user to your sb,
			#but just in that moment the user invites you,
			#so you will connect to its sb and be able to chat, but after
			#a while the user will join your old invitation,
			#and get a fake "user joins" message if we don't check it
			::MSNP2P::loadUserPic $chatid $usr_login

			if {[::MSN::SBFor $chatid] == $sb} {
				::amsn::userJoins $chatid $usr_login 0
			}
		}
	}

}
#///////////////////////////////////////////////////////////////////////


#TODO: ::abook system
proc cmsn_change_state {recv} {

	if {[lindex $recv 0] == "FLN"} {
		#User is going offline
		set user [lindex $recv 1]
		set evpar(user) user
		set user_name ""
		set substate "FLN"
		set evpar(substate) substate
		set msnobj [::abook::getVolatileData $user msnobj ""]
	status_log "contactStateChange in protocol cmsn_change_state FLN"
	#an event used by guicontactlist to know when a contact changed state
	after 500 ::Event::fireEvent contactStateChange protocol $user

		::plugins::PostEvent ChangeState evpar

	} elseif {[lindex $recv 0] == "ILN"} {
		#Initial status when we log in
		set user [lindex $recv 3]
		set encoded_user_name [lindex $recv 4]
		set user_name [urldecode [lindex $recv 4]]
		set substate [lindex $recv 2]
		set msnobj [urldecode [lindex $recv 6]]
		#Add clientID to abook
		add_Clientid $user [lindex $recv 5]
		#I don't think we should add ChangeState PostEvent here...
	} else {
		#Coming online or changing state
		set user [lindex $recv 2]
		set evpar(user) user
		set encoded_user_name [lindex $recv 3]
		set user_name [urldecode [lindex $recv 3]]
		set substate [lindex $recv 1]
		set evpar(substate) substate
		set msnobj [urldecode [lindex $recv 5]]
		#Add clientID to abook
		add_Clientid $user [lindex $recv 4]

	status_log "contactStateChange in protocol cmsn_change_state $user"
	#an event used by guicontactlist to know when a contact changed state
	after 500 ::Event::fireEvent contactStateChange protocol $user

		#Send plugin's postevent
		::plugins::PostEvent ChangeState evpar

	}

	if { $msnobj == "" } {
		set msnobj -1
	}

	if {$user_name == ""} {
		set user_name [::abook::getNick $user]
	}


	if {$user_name != [::abook::getNick $user]} {
		#Nick differs from the one on our list, so change it
		#in the server list too
		::abook::setContactData $user nick $user_name
		::MSN::changeName $user [encoding convertto utf-8 $encoded_user_name] 1

	#an event used by guicontactlist to know when we changed our nick
	::Event::fireEvent contactNickChange protocol $user

	}

	set custom_user_name [::abook::getDisplayNick $user]

	set state_no [::MSN::stateToNumber $substate ]


    #alarm system (that must replace the one that was before) - KNO
	if {[lindex $recv 0] !="ILN"} {

		if {[lindex $recv 0] == "FLN"} {
			#User disconnected

			if {  ( [::alarms::isEnabled $user] == 1 )&& ( [::alarms::getAlarmItem $user ondisconnect] == 1) } {
				run_alarm $user $custom_user_name [trans disconnect $custom_user_name]
			} elseif {  ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all ondisconnect] == 1) } {
				run_alarm $user $custom_user_name [trans disconnect $custom_user_name]
			}

		} else {
			if { ( [::alarms::isEnabled $user] == 1 )&& ( [::alarms::getAlarmItem $user onstatus] == 1) } {
				switch -exact [lindex $recv 1] {
					"NLN" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans online]]"
					}
					"IDL" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans away]]"
					}
					"BSY" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans busy]]"
					}
					"BRB" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans rightback]]"
					}
					"AWY" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans away]]"
					}
					"PHN" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans onphone]]"
					}
					"LUN" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans gonelunch]]"
					}
				}
			} elseif { ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all onstatus] == 1)} {
				switch -exact [lindex $recv 1] {
					"NLN" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans online]]"
					}
					"IDL" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans away]]"
					}
					"BSY" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans busy]]"
					}
					"BRB" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans rightback]]"
					}
					"AWY" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans away]]"
					}
					"PHN" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans onphone]]"
					}
					"LUN" {
						run_alarm $user $custom_user_name "[trans changestate $custom_user_name [trans gonelunch]]"
					}
				}
			}
		}
	}
	#end of alarm system


	set maxw [expr {([::skin::getKey notifwidth]-53)*2} ]
	set short_name [trunc $custom_user_name . $maxw splainf]

	#User logsout
	if {$substate == "FLN"} {

		#Register last logout, last seen and notify it in the events
		::abook::setAtomicContactData $user [list last_logout last_seen] \
			[list [clock format [clock seconds] -format "%D - %H:%M:%S"] [clock format [clock seconds] -format "%D - %H:%M:%S"]]
		::log::eventdisconnect $custom_user_name


		if { ([::config::getKey notifyoffline] == 1 && [::abook::getContactData $user notifyoffline -1] != 0) ||
		     [::abook::getContactData $user notifyoffline -1] == 1 } {
			#Show notify window if globally enabled, and not locally disabled, or if just locally enabled
			::amsn::notifyAdd "$short_name\n[trans logsout]." "" offline offline $user
		}

	# User was online before, so it's just a status change, and it's not
	# an initial state notification
	} elseif {[::abook::getVolatileData $user state FLN] != "FLN" && [lindex $recv 0] != "ILN"  } {

		if { ([::config::getKey notifystate] == 1 && [::abook::getContactData $user notifystatus -1] != 0) ||
		     [::abook::getContactData $user notifystatus -1] == 1 } {
			::amsn::notifyAdd "$short_name\n[trans statechange]\n[trans [::MSN::stateToDescription $substate]]." \
				"::amsn::chatUser $user" state state $user
		}

		#Notify in the events
		::log::eventstatus $custom_user_name [::MSN::stateToDescription $substate]

	} elseif {[lindex $recv 0] == "NLN"} {	;# User was offline, now online

		user_not_blocked "$user"

		#Register last login and notify it in the events
		::abook::setContactData $user last_login [clock format [clock seconds] -format "%D - %H:%M:%S"]
		::log::eventconnect $custom_user_name
		#Register PostEvent "UserConnect" for Plugins, email = email user_name=custom nick
		set evPar(user) user
		set evPar(user_name) custom_user_name
		::plugins::PostEvent UserConnect evPar

		if { ([::config::getKey notifyonline] == 1 && [::abook::getContactData $user notifyonline -1] != 0) ||
		     [::abook::getContactData $user notifyonline -1] == 1 } {
			::amsn::notifyAdd "$short_name\n[trans logsin]." "::amsn::chatUser $user" online online $user
		}

		if {  ( [::alarms::isEnabled $user] == 1 )&& ( [::alarms::getAlarmItem $user onconnect] == 1)} {
			run_alarm $user $custom_user_name "$custom_user_name [trans logsin]"
		} elseif {  ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all onstatus] == 1)} {
			run_alarm $user $custom_user_name "$custom_user_name [trans logsin]"
		}
	}
	set oldmsnobj [::abook::getVolatileData $user msobj]
	#set list_users [lreplace $list_users $idx $idx [list $user $user_name $state_no $msnobj]]

	::abook::setVolatileData $user state $substate
	::abook::setVolatileData $user msnobj $msnobj
	set oldPic [::abook::getContactData $user displaypicfile]
	set newPic [::MSNP2P::GetFilenameFromMSNOBJ $msnobj]
	::abook::setContactData $user displaypicfile $newPic

	if { $oldPic != $newPic} {
		status_log "picture changed for user $user\n" white
		if { [::config::getKey lazypicretrieval] || [::MSN::userIsBlocked $user]} {
			global sb_list
			foreach sb $sb_list {
				set users_in_chat [$sb cget -users]
				if { [lsearch $users_in_chat $user] != -1 } {
					status_log "User changed image while image in use!! Updating!!\n" white
					::MSNP2P::loadUserPic [::MSN::ChatFor $sb] $user
				}
			}
		} else {
			if { [::MSN::myStatusIs] != "FLN" && [::MSN::myStatusIs] != "HDN"} {
				set chat_id [::MSN::chatTo $user]
				::MSN::ChatQueue $chat_id [list ::MSNP2P::loadUserPic $chat_id $user]
			}
		}
	}


	::MSN::contactListChanged
	cmsn_draw_online 1

}


proc cmsn_ns_handler {item {message ""}} {
	global list_cmdhnd password

	set ret_trid [lindex $item 1]
	set idx [lsearch $list_cmdhnd "$ret_trid *"]
	if {$idx != -1} {		;# Command has a handler associated!
		status_log "cmsn_ns_handler: evaluating handler for $ret_trid\n"

		#TODO: Better use [list ]: test it
		set command "[lindex [lindex $list_cmdhnd $idx] 1] [list $item]"
		set list_cmdhnd [lreplace $list_cmdhnd $idx $idx]
		eval "$command"

		#eval "[lindex [lindex $list_cmdhnd $idx] 1] \"$item\""
		return 0
	} else {
		switch [lindex $item 0] {
			MSG {
				cmsn_ns_msg $item $message
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
			REA {
				::MSN::GotREAResponse $item
				return 0
			}
			ADD {
				status_log "Before: [lindex $item 4] is now in groups: [::abook::getGroups [lindex $item 4]]\n"
				new_contact_list "[lindex $item 3]"
				status_log "After 1: [lindex $item 4] is now in groups: [::abook::getGroups [lindex $item 4]]\n"
				set curr_list [lindex $item 2]
				status_log "curr_list=$curr_list\n"
				if { ($curr_list == "FL") } {
					::abook::setContactData [lindex $item 4] nick [urldecode [lindex $item 5]]
					::abook::addContactToGroup [lindex $item 4] [lindex $item 6]
					status_log "Adding contact to group [lindex $item 6]\n"
					status_log "After 2: [lindex $item 4] is now in groups: [::abook::getGroups [lindex $item 4]]\n"
				}
				cmsn_listupdate $item
				status_log "After 3: [lindex $item 4] is now in groups: [::abook::getGroups [lindex $item 4]]\n"
				return 0
			}
			LST {
				cmsn_listupdate $item
				return 0
			}
			REM {
				new_contact_list "[lindex $item 3]"
				cmsn_listdel $item
				return 0
			}
			FLN -
			ILN -
			NLN {
				cmsn_change_state $item
				return 0
			}
			CHG {
				if { [::MSN::myStatusIs] != [lindex $item 2] } {
					::abook::setVolatileData myself msnobj [lindex $item 4]
					::MSN::setMyStatus [lindex $item 2]

					cmsn_draw_online 1

				#Alert dock of status change
				#send_dock [lindex $item 2]
				send_dock "STATUS" [lindex $item 2]
				}
				return 0
			}
			GTC {
				#TODO: How we store this privacy information??
				return 0
			}
			SYN {
				new_contact_list "[lindex $item 2]"
				global loading_list_info

				if { [llength $item] == 5 } {
					status_log "Going to receive contact list\n" blue
					#First contact in list
					::MSN::clearList FL
					::MSN::clearList BL
					::MSN::clearList RL
					::MSN::clearList AL
					::groups::Reset

					set loading_list_info(version) [lindex $item 2]
					set loading_list_info(total) [lindex $item 3]
					set loading_list_info(current) 1
					set loading_list_info(gtotal) [lindex $item 4]
				}
				return 0
			}
			BLP {
				#puts "$item == [llength $item]"
				if { [llength $item] == 2} {
					change_BLP_settings "[lindex $item 1]"
				} else {
					new_contact_list "[lindex $item 2]"
					change_BLP_settings "[lindex $item 3]"
				}
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
				if { [llength $item] == 3} {
					#That's here we receive MOB, PHM,PHW,PHH information
					global loading_list_info
					::abook::setVolatileData $loading_list_info(last) [lindex $item 1] [urldecode [lindex $item 2]]
				} else {
					# Update entry in address book setContact(email,PH*/M*,phone/setting)
					::abook::setContactData [lindex $item 2] [lindex $item 3] [urldecode [lindex $item 4]]
				}
				return 0
			}
			PRP {
				if { [llength $item] == 3 } {
			    	::abook::setPersonal [lindex $item 1] [urldecode [lindex $item 2]]
				} else {
					new_contact_list "[lindex $item 2]"
			    	::abook::setPersonal [lindex $item 3] [urldecode [lindex $item 4]]
				}
				#TODO: Why do we ignore this??? It's our own phone number...
				return 0
			}
			LSG {

				::groups::Set [lindex $item 1] [lindex $item 2]
				if { [::config::getKey expanded_group_[lindex $item 1]]!="" } {
					set ::groups::bShowing([lindex $item 1]) [::config::getKey expanded_group_[lindex $item 1]]
				}

				return 0
			}
			REG {	# Rename Group
				new_contact_list "[lindex $item 2]"
				#status_log "$item\n" blue
				::groups::RenameCB [lrange $item 0 5]
				cmsn_draw_online 1
				return 0
			}
			ADG {	# Add Group
				new_contact_list "[lindex $item 2]"
				#status_log "$item\n" blue
				::groups::AddCB [lrange $item 0 5]
				cmsn_draw_online 1
				return 0
			}
			RMG {	# Remove Group
				new_contact_list "[lindex $item 2]"
				#status_log "$item\n" blue
				::groups::DeleteCB [lrange $item 0 5]
				cmsn_draw_online 1
				return 0
			}
			OUT {
				if { [lindex $item 1] == "OTH"} {
					::MSN::logout
					msg_box "[trans loggedotherlocation]"
					status_log "Logged other location\n" red
					return 0
				} else {
					if { [::config::getKey reconnect] == 1 } {
						set ::oldstatus [::MSN::myStatusIs]
						::MSN::logout
						::MSN::reconnect "[trans servergoingdown]"
					} else {
						::MSN::logout
						msg_box "[trans servergoingdown]"
					}
					return 0
				}
			}
			QNG {
				#Ping response
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
				status_log "Warning: Invalid fusername $item\n" red
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
# # # 				status_log "Warning: Invalid group" red
				msg_box "[trans invalidgroup]"
			}
			600 {
				if { [::config::getKey reconnect] == 1 } {
					set ::oldstatus [::MSN::myStatusIs]
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
				if { [::config::getKey reconnect] == 1 } {
					set ::oldstatus [::MSN::myStatusIs]
					::MSN::logout
					::MSN::reconnect "[trans serverunavailable]"
				} else {
					::MSN::logout
					::amsn::errorMsg "[trans serverunavailable]"
				}
				status_log "Error: Server is unavailable\n" red
				return 0
			}
			500 {
				if { [::config::getKey reconnect] == 1 } {
					set ::oldstatus [::MSN::myStatusIs]
					::MSN::logout
					::MSN::reconnect "[trans internalerror]"
				} else {
					::MSN::logout
					::amsn::errorMsg "[trans internalerror]"
				}
				status_log "Error: Internal server error\n" red
				return 0
			}
			911 {
				#set password ""
				ns configure -stat "closed"
				::MSN::logout
				status_log "Error: User/Password\n" red
				::amsn::errorMsg "[trans baduserpass]"
				return 0
			}
			"" {
				return 0
			}
			default {
				status_log "Got unknown NS input!! --> [lindex $item 0]\n" red
				return 0
			}
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
		set d(langpreference) [$message getHeader lang_preference]
		set d(preferredemail) [$message getHeader preferredEmail]
		set d(country) [$message getHeader country]
		set d(gender) [$message getHeader Gender]
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
	} else {
		hotmail_procmsg $message
	}
}


#TODO: ::abook system
proc cmsn_listdel {recv} {

	set user [lindex $recv 4]
	set list_sort [string toupper [lindex $recv 2]]



	if { [lindex $recv 2] == "FL" } {
		if { [lindex $recv 5] == "" } {
			#Remove from all groups!!
			foreach group [::abook::getGroups $user] {
				::abook::removeContactFromGroup $user $group
			}
		} else {
			#Remove fromonly one group
			::abook::removeContactFromGroup $user [lindex $recv 5]
		}

		if { [llength [::abook::getGroups $user]] == 0 } {
			status_log "cmsn_listdel: Contact [lindex $recv 4] is in no groups, removing!!\n" blue
			::MSN::deleteFromList FL $user
			::abook::removeContactFromList $user FL
		}
#
	} else {
#
		::MSN::deleteFromList $list_sort $user
		::abook::removeContactFromList $user $list_sort
	}


	cmsn_draw_online 1
	global contactlist_loaded
	set contactlist_loaded 1
}


proc cmsn_auth {{recv ""}} {

	status_log "cmsn_auth starting, stat=[ns cget -stat]\n" blue

	global HOME info

	switch [ns cget -stat] {

		a {
			#Send three first commands at same time, to it faster
			::MSN::WriteSB ns "VER" "MSNP9 CVR0"
			::MSN::WriteSB ns "CVR" "0x0409 winnt 6.0 i386 MSNMSGR 7.0.0732 MSMSGSBETAM2 [::config::getKey login]"
			::MSN::WriteSB ns "USR" "TWN I [::config::getKey login]"

			ns configure -stat "v"
			return 0
		}

		v {
			if {[lindex $recv 0] != "VER"} {
				status_log "cmsn_auth: was expecting VER reply but got a [lindex $recv 0]\n" red
				return 1
			} elseif {[lsearch -exact $recv "CVR0"] != -1} {
				#::MSN::WriteSB ns "CVR" "0x0409 winnt 6.0 i386 MSNMSGR 6.0.0602 MSMSGS [::config::getKey login]"
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
				#::MSN::WriteSB ns "USR" "TWN I [::config::getKey login]"
				ns configure -stat "u"
				return 0
			}
		}

		u {
			if {([lindex $recv 0] != "USR") || \
				([lindex $recv 2] != "TWN") || \
				([lindex $recv 3] != "S")} {

				status_log "cmsn_auth: was expecting USR x TWN S xxxxx but got something else!\n" red
				return 1
			}

			foreach x [split [lrange $recv 4 end] ","] { set info([lindex [split $x "="] 0]) [lindex [split $x "="] 1] }
			set info(all) [lrange $recv 4 end]

			#if {[::config::getKey nossl]
			#|| ([::config::getKey connectiontype] != "direct" && [::config::getKey connectiontype] != "http") } {
			#http::geturl "https://nexus.passport.com/rdr/pprdr.asp" -timeout 8000 -command "gotNexusReply [list $info(all)]"
				global login_passport_url
				if { $login_passport_url == 0 } {
					status_log "cmsn_auth_msnp9: Nexus didn't reply yet...\n"
					set login_passport_url $info(all)
				} else {
					status_log "cmsn_auth_msnp9: Nexus has replied so we have login URL...\n"
					set proxy [ns cget -proxy]
					$proxy authenticate $info(all) $login_passport_url
					#msnp9_do_auth [list $info(all)] $login_passport_url
				}
			#}

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


			::abook::setPersonal nick [urldecode [lindex $recv 4]]
			::abook::setPersonal login [lindex $recv 3]
			recreate_contact_lists

			#We need to wait until the SYN reply comes, or we can send the CHG request before
			#the server sends the list, and then it won't work (all contacts offline)
			#::MSN::WriteSB ns "SYN" "$list_version" initial_syn_handler
			::MSN::WriteSB ns "SYN" "[::abook::getContactData contactlist list_version 0]" initial_syn_handler

			#Alert dock of status change
			#      send_dock "NLN"
			send_dock "MAIL" 0

			#Log out
			.main_menu.file entryconfigure 2 -state normal
			#My status
			.main_menu.file entryconfigure 3 -state normal
			#Inbox
			.main_menu.file entryconfigure 5 -state normal
			#savecontactlist
			.main_menu.file entryconfigure 7 -state normal
			#LoadContactlist
			.main_menu.file entryconfigure 8 -state normal

			#Add a contact
			.main_menu.tools entryconfigure 0 -state normal
			.main_menu.tools entryconfigure 1 -state normal
			.main_menu.tools entryconfigure 4 -state normal
			#Added by Trevor Feeney
			#Enables the Group Order Menu
			.main_menu.tools entryconfigure 5 -state normal
			#Enables View contacts by
			.main_menu.tools entryconfigure 6 -state normal

			#Enable View History
			.main_menu.tools entryconfigure 8 -state normal
			#Enable View Event logging
			.main_menu.tools entryconfigure 9 -state normal

			#Change nick
			configureMenuEntry .main_menu.actions "[trans changenick]..." normal
			#configureMenuEntry .options "[trans changenick]..." normal

			configureMenuEntry .main_menu.actions "[trans sendmail]..." normal
			configureMenuEntry .main_menu.actions "[trans sendmsg]..." normal

			#Send postevent "OnConnect" to plugin when we connect
			::plugins::PostEvent OnConnect evPar

			return 0
		}

	}

	return -1

}

proc recreate_contact_lists {} {


	#There's no need to recreate groups, as ::groups already gets all data
	#from ::abook
	foreach groupid [::groups::GetList] {
		::groups::Set $groupid [::groups::GetName $groupid]
		if { [::config::getKey expanded_group_$groupid]!="" } {
			set ::groups::bShowing($groupid) [::config::getKey expanded_group_$groupid]
		} else {
			set ::groups::bShowing($groupid) 1
			::config::setKey expanded_group_$groupid 1
		}
	}

	#Let's put every user in their contacts list and groups
	::MSN::clearList AL
	::MSN::clearList BL
	::MSN::clearList FL
	::MSN::clearList RL
	foreach user [::abook::getAllContacts] {
		foreach list_name [::abook::getLists $user] {
			if { $list_name == "FL" } {
				::abook::setVolatileData $user state FLN
			}
			::MSN::addToList $list_name $user
		}
	}

}

proc initial_syn_handler {recv} {

	global HOME

	# Switch to our cached nickname if the server's one is different that ours
	if { [file exists [file join ${HOME} "nick.cache"]] && [::config::getKey storename] } {

		set nickcache [open [file join ${HOME} "nick.cache"] r]
		fconfigure $nickcache -encoding utf-8


		gets $nickcache storednick
		gets $nickcache custom_nick
		gets $nickcache stored_login

		close $nickcache

		if { ($custom_nick == [::abook::getPersonal nick]) && ($stored_login == [::abook::getPersonal login]) && ($storednick != "") } {
			::MSN::changeName [::abook::getPersonal login] $storednick
		}

		catch { file delete [file join ${HOME} "nick.cache"] }
	}


	#Don't use oldstatus if it was "FLN" (disconnectd) or we will get a 201 error
	if {[info exists ::oldstatus] && $::oldstatus != "FLN" } {
		ChCustomState $::oldstatus
		send_dock "STATUS" $::oldstatus
		unset ::oldstatus
	} elseif {[string is digit -strict "[::config::getKey connectas]"]} {
		#Protocol code to choose our state on connect
		set number [::config::getKey connectas]
		set goodstatecode "[::MSN::numberToState $number]"

		if {$goodstatecode != ""} {
			ChCustomState "$goodstatecode"
			send_dock "STATUS" "$goodstatecode"
		} else {
			status_log "Not able to get choosen key: [::config::getKey connectas]"
			ChCustomState "NLN"
			send_dock "STATUS" "NLN"
		}

	} else {
		ChCustomState "NLN"
		send_dock "STATUS" "NLN"
	}

	cmsn_ns_handler $recv
}

proc msnp9_userpass_error {} {

	ns configure -stat "closed"
	::MSN::logout
	status_log "Error: User/Password\n" red
	::amsn::errorMsg "[trans baduserpass]"

}

proc msnp9_auth_error {} {

	status_log "Error connecting to server\n"
	::MSN::logout
	::amsn::errorMsg "[trans connecterror]"

}



proc msnp9_authenticate { ticket } {

	if {[ns cget -stat] == "u" } {
		::MSN::WriteSB ns "USR" "TWN S $ticket"
		ns configure -stat "us"
	} else {

		status_log "Connection timeouted\n" white
		::MSN::logout

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
#	$name configure -error_handler [list ::MSN::CloseSB $name]

	$name configure -proxy [Proxy create %AUTO%]
#	if {[::config::getKey connectiontype] == "direct" } {
#		$name configure -connection_wrapper DirectConnection

#	} elseif {[::config::getKey connectiontype] == "http"} {

# 		$name configure -connection_wrapper HTTPConnection
#		$name configure -proxy_host ""
#		$name configure -proxy_port ""

		#status_log "cmsn_socket: Setting up http connection\n" green
		#set tmp_serv "gateway.messenger.hotmail.com"
		#set tmp_port 80

		#::Proxy::Init "$tmp_serv:$tmp_port" "http"

		#::Proxy::OnCallback "dropped" "proxy_callback"

		#status_log "cmsn_socket: Calling proxy::Setup now\n" green
		#::Proxy::Setup next readable_handler $name


#	} elseif {[::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "http"} {

		#TODO: Right now it's always HTTP proxy!!
#		$name configure -connection_wrapper HTTPConnection
#		set proxy [::config::getKey proxy]
#		$name configure -proxy_host [lindex $proxy 0]
#		$name configure -proxy_port [lindex $proxy 1]
#		$name configure -proxy_authenticate [::config::getKey proxyauthenticate]
#		$name configure -proxy_user [::config::getKey proxyuser]
#		$name configure -proxy_password [::config::getKey proxypass]

		#status_log "cmsn_socket: Setting up Proxy connection (type=[::config::getKey proxytype])\n" green
		#::Proxy::Init [::config::getKey proxy] [::config::getKey proxytype]
		#::Proxy::LoginData [::config::getKey proxyauthenticate] [::config::getKey proxyuser] [::config::getKey proxypass]

		#set proxy_serv [split [::config::getKey proxy] ":"]
		#set tmp_serv [lindex $proxy_serv 0]
		#set tmp_port [lindex $proxy_serv 1]
		#::Proxy::OnCallback "dropped" "proxy_callback"

		#status_log "cmsn_connect: Calling proxy::Setup now\n" green
		#::Proxy::Setup next readable_handler $name

#	} else {
#		::config::setKey connectiontype "direct"
 #		$name configure -connection_wrapper DirectConnection
#	}
}

proc cmsn_socket {name} {


	$name configure -time [clock seconds]
	$name configure -stat "cw"
	$name configure -error_msg ""

	set proxy [$name cget -proxy]
	if {[$proxy connect $name]<0} {
		::MSN::CloseSB $name
	}



	#if { [catch {set sock [socket -async $tmp_serv $tmp_port]} res ] } {
	#	$sb configure -error_msg $res
	#	::MSN::CloseSB $name
	#	return
	#}

	#$sb configure -sock $sock
	#fconfigure $sock -buffering none -translation {binary binary} -blocking 0
	#fileevent $sock readable $readable_handler
	#fileevent $sock writable $next
}

proc cmsn_ns_connected {sock} {

	fileevent $sock writable ""
	set error_msg ""
	set therewaserror [catch {set error_msg [fconfigure [ns cget -sock] -error]} res]
	if { ($error_msg != "") || $therewaserror == 1 } {
		ns configure -error_msg $error_msg
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
		cmsn_draw_login
		return -1
	}

	::MSN::clearList FL
	::MSN::clearList AL
	::MSN::clearList BL
	::MSN::clearList RL

	if {[ns cget -stat] != "d"} {
		set proxy [ns cget -proxy]
		$proxy finish ns
	}

	ns configure -stat "c"

	if { $nosignin == "" } {
		cmsn_draw_signin
	}

	#Log in
	.main_menu.file entryconfigure 0 -state disabled
	.main_menu.file entryconfigure 1 -state disabled
	#Log out
	.main_menu.file entryconfigure 2 -state normal


	::MSN::StartPolling
	::groups::Reset

	#TODO: Call "on connect" handlers, where hotmail will be registered.
	set ::hotmail::unread 0

	ns configure -autherror_handler "msnp9_auth_error"
	ns configure -passerror_handler "msnp9_userpass_error"
	ns configure -ticket_handler "msnp9_authenticate"
	#ns configure -data [list]
	ns configure -connected "cmsn_ns_connected"

	cmsn_socket ns


	return 0
}



proc process_msnp9_lists { bin } {

	set lists [list]

	if { $bin == "" } {
		status_log "process_msnp9_lists: No lists!!!\n" red
		return $lists
	}

	if { [expr {$bin % 2}] } {
		lappend lists "FL"
	}
	set bin [expr {$bin >> 1}]

	if { [expr {$bin % 2}] } {
		lappend lists "AL"
	}

	set bin [expr {$bin >> 1}]

	if { [expr {$bin % 2}] } {
		lappend lists "BL"
	}
	set bin [expr {$bin >> 1}]

	if { [expr {$bin % 2}] } {
		lappend lists "RL"
	}

	return $lists
}


#TODO: ::abook system
proc cmsn_listupdate {recv} {
	global contactlist_loaded

	set contactlist_loaded 0

	if { [lindex $recv 0] == "ADD" } {
		set list_names "[string toupper [lindex $recv 2]]"
		set version [lindex $recv 3]

		set command ADD

		set current 1
		set total 1

		set username [lindex $recv 4]
		set nickname [urldecode [lindex $recv 5]]
		set groups [::abook::getGroups $username]


	} else {

		global loading_list_info

		set command LST

		#Get the current contact number
		set current $loading_list_info(current)
		set total $loading_list_info(total)

		#Increment the contact number
		incr loading_list_info(current)

		set username [lindex $recv 1]
		set nickname [urldecode [lindex $recv 2]]


		set list_names [process_msnp9_lists [lindex $recv 3]]
		set groups [split [lindex $recv 4] ,]

		#Make list unconsistent while receiving contact lists
		::abook::unsetConsistent

		#Remove user from all lists while receiving List data
		::abook::setContactData $username lists ""


	}

	::abook::setContactData $username nick $nickname

	foreach list_sort $list_names {

		#If list is not empty, get user information
		if {$current != 0} {

			::abook::addContactToList $username $list_sort
			::MSN::addToList $list_sort $username

			#No need to set groups and set offline state if command is not LST
			if { ($list_sort == "FL") && ($command == "LST") } {
				::abook::setContactData $username group $groups
				set loading_list_info(last) $username
				::abook::setVolatileData $username state "FLN"

			}
		}
	}

	set lists [::abook::getLists $username]
	if { ([lsearch $lists RL] != -1) && ([lsearch $lists AL] < 0) && ([lsearch $lists BL] < 0)} {
		newcontact $username $nickname
	}

	::MSN::contactListChanged

	#Last user in list
	if {$current == $total} {
		cmsn_draw_online 1

		set contactlist_loaded 1
		::abook::setConsistent
		::abook::saveToDisk
	}

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


proc new_contact_list { version } {
	global contactlist_loaded

	if {[string is digit $version] == 0} {
		status_log "new_contact_list: Wrong version=$version\n" red
		return
	}

	status_log "new_contact_list: new contact list version : $version --- previous was : [::abook::getContactData contactlist list_version] \n"

	::abook::setContactData contactlist list_version $version
	#if { $list_version != $version } {
	#	set list_version $version
	#} else {
	#	set contactlist_loaded 1
	#}

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

proc create_msnobj { Creator type filename } {
	global msnobjcontext

	if { [file exists $filename] == 0 } { return "" }
	set fd [open $filename r]
	fconfigure $fd -translation binary
	set data [read $fd]
	close $fd

	set file [filenoext [getfilename $filename]]

	set size [string length $data]

	set sha1d [::base64::encode [binary format H* [::sha1::sha1 $data]]]

	set sha1c [::base64::encode [binary format H* [::sha1::sha1 "Creator${Creator}Size${size}Type${type}Location${file}.tmpFriendlyAAA=SHA1D${sha1d}"]]]

	set msnobj "<msnobj Creator=\"$Creator\" Size=\"$size\" Type=\"$type\" Location=\"[urlencode $file].tmp\" Friendly=\"AAA=\" SHA1D=\"$sha1d\" SHA1C=\"$sha1c\"/>"

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
		if {[string first "Client-Name:" $msg] != "-1"} {
			set begin [expr {[string first "Client-Name:" $msg]+13}]
			set end   [expr {[string first "\n" $msg $begin]-2}]
			set clientname "[urldecode [string range $msg $begin $end]]"
			#status_log "Client-Name:\n$clientname\n"
			#Add this information to abook
			::abook::setContactData $chatid clientname $clientname
		}
		#Get String for Chat Logging (Gaim and some others)
		if {[string first "Chat-Logging" $msg] != "-1"} {
			set begin [expr {[string first "Chat-Logging" $msg]+14}]
			set end   [expr {[string first "\n" $msg $begin]-2}]
			set chatlogging "[urldecode [string range $msg $begin $end]]"
			#status_log "ChatLogging:\n$chatlogging\n"
			#Add this information to abook
			if {$chatlogging == "Y"} {
				set chatlogging "[trans yes]"
			} else {
				set chatlogging "[trans no]"
			}
			::abook::setContactData $chatid chatlogging $chatlogging
		}
		#Get String for Operating System (dMSN)
		#This information is stored but not used anywhere inside aMSN
		if {[string first "Operating-System:" $msg] != "-1"} {
			set begin [expr {[string first "Operating-System:" $msg]+18}]
			set end   [expr {[string first "\n" $msg $begin]-1}]
			set operatingsystem "[urldecode [string range $msg $begin $end]]"
			#status_log "Operating System:\n$operatingsystem\n"
			#Add this information to abook
			::abook::setContactData $chatid operatingsystem $operatingsystem
		}
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
	#We look on the clientid number to determine witch client it is
	#Remember, aMSN 0.94B is known as MSN 7, 0.93 as MSN 6.0
	switch [string range $clientid 0 3]  {
		2684 {
			::abook::setContactData $chatid clientid "MSN 6.0"
		}
		5368 {
			::abook::setContactData $chatid clientid "MSN 6.1"
		}
		8053 {
			::abook::setContactData $chatid clientid "MSN 6.2"
		}
		1073 {
			::abook::setContactData $chatid clientid "MSN 7.0"
		}
		512 {
			::abook::setContactData $chatid clientid "Web Messenger"
		}
		default {
			::abook::setContactData $chatid clientid "[trans unknown]"
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
	set maxFactor [expr [expr $max + 1] - $min]
	set value [expr int([expr rand() * 1000000])]
	set value [expr [expr $value % $maxFactor] + $min]
	return $value
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
	status_log "Converting $text to unicode\n" red

#	set text [encoding convertfrom $text]
	status_log "text msg is : $text\n" red
	set text [encoding convertto unicode $text]
	status_log "text msg is : $text\n" red
	#set text [binary format a* $text]
	status_log "text msg is : $text\n" red
	set text [ToLittleEndian $text 2]
	status_log "text msg is : $text\n" red

	return $text
}

proc FromUnicode { text } {
	status_log "Converting $text from unicode\n" red

	#binary scan $text A* text
	status_log "text msg is : $text\n" red

	set text [ToBigEndian "$text" 2]
	status_log "text msg is : $text\n" red
	set text [encoding convertfrom unicode "$text"]
	status_log "text msg is : $text\n" red

#	set text [encoding convertto "$text"]
	status_log "text msg is : $text\n" red

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

		status_log "Sending File $filename with size $filesize to $chatid\n"

		set sid [expr int([expr rand() * 1000000000])%125000000 + 4]
		# Generate BranchID and CallID
		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

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
		set context "[binary format i 574][binary format i 2][binary format i $filesize][binary format i 0][binary format i $nopreview]"


		set file [ToUnicode [getfilename $filename]]

		set file [binary format a550 $file]
		set context "${context}${file}\xFF\xFF\xFF\xFF"

		if { $nopreview == 0 } {

			create_dir [file join [set ::HOME] FT cache]

			#set file [convert_file "$filename" "[file join [set ::HOME] FT cache ${callid}.png]" "96x96"]
			set file [convert_image_plus $filename FT/cache "96x96"]

			if { [catch { open $file} fd] == 0 } {
				
				fconfigure $fd -translation {binary binary }
				set context "$context[read $fd]"
				close $fd
			}
		}




		# Create and send our packet
		set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 0 $callid 0 0 "5D3E02AB-6190-11D3-BBBB-00C04F795683" $sid 2 \
				 [string map { "\n" "" } [::base64::encode "$context"]]]
		::MSNP2P::SendPacketExt [::MSN::SBFor $chatid] $sid $slpdata 1
		status_log "Sent an INVITE to [::MSN::usersInChat $chatid]  on chatid $chatid for filetransfer of filename $filename\n" red

	}



	proc SendFTInvite { sid chatid} {

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

		set slpdata [::MSNP2P::MakeMSNSLP "INVITE" $dest [::config::getKey login] $branchid 0 $callid 0 1 "TCPv1" \
				 $netid $conntype $upnp "false"]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

		after 5000 "::MSNP2P::SendDataFile $sid $chatid [list [lindex [::MSNP2P::SessionList get $sid] 8]] \"INVITE1\""
	}


	proc SendFTInvite2 { sid chatid} {

		set session [::MSNP2P::SessionList get $sid]
		set branchid [lindex $session 9]
		set callid [lindex $session 5]

		set dest [lindex $session 3]
		set conntype [abook::getDemographicField conntype]

		set listening [abook::getDemographicField listening]

		set fd [open [lindex $session 8] "r"]
		fconfigure $fd -translation {binary binary}

		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 "INVITE2" -1 $fd -1 -1 -1]

		if {$listening == "true" } {
			set nonce "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
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
		while { [catch {set sock [socket -server "::MSN6FT::handleMsnFT  $nonce $sid $sending" $port] } ] } {
			incr port
		}
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
		fconfigure $sock -blocking 1 -buffering none -translation {binary binary}

		fileevent $sock readable "::MSN6FT::ReadFromSock $sock"
		#fileevent $sock writable "::MSN6FT::WriteToSock $sock"
	}




	proc connectMsnFTP { sid nonce ip port sending } {

		#Use new FT protocol only if the user choosed this option in advanced preferences.
		if {[::config::getKey new_ft_protocol]} {
			#Nothing
		} else {
			return
		}
		
		::amsn::FTProgress c $sid "" $ip $port

		if { [catch {set sock [ socket $ip $port] } ] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red
		} else {

			setObjOption $sid sending $sending
			setObjOption $sock nonce $nonce
			setObjOption $sock state "FOO"
			setObjOption $sock server 0
			setObjOption $sock sid $sid
			
			status_log "connectedto $ip on port $port  - $sock\n"
			fconfigure $sock -blocking 1 -buffering none -translation {binary binary}
			fileevent $sock readable "::MSN6FT::ReadFromSock $sock"
			fileevent $sock writable "::MSN6FT::WriteToSock $sock"
		}
	}


	proc ReadFromSock { sock } {
		set sid [getObjOption $sock sid]
		set state [getObjOption $sock state]
		set server [getObjOption $sock server]
		set sending [getObjOption $sid sending]

		if { $sid == "" } {
			status_log "Can't find sid for socket $sock!!! ERROR" red
			close $sock
			return
		}

		set size [read $sock 4]


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
		set data [read $sock $size]

		#status_log "Received Data on socket $sock status $state: $data\n" red

		if { $data == "" } {
			update idletasks
			return
		}

		switch $state {
			"FOO"
			{
				if { $server && $data == "foo\x00" } {
					setObjOption $sock state "NONCE_GET"
				} 
			}

			"NONCE_GET"
			{
				set nonce [getObjOption $sock nonce]
				
				if { $server && $nonce == [GetNonceFromData $data]} {
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
 				::MSNP2P::ReadData $p2pmessage [getObjOption $sid chatid]

# 				if { [WriteDataToFile $data] == "0" } {
# 					SendDataAck $sock $data
# 					set sockState($sock) [expr $sockState($sock) + 1 ]

# 				}
			}

			default
			{
				catch {close $sock}
			}

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


		switch $state {

			"FOO"			
			{
				if { $server == 0 } {
					set data "[binary format i 4]foo\x00"
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
				} else {
					fileevent $sock writable "::MSN6FT::WriteToSock $sock"
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


	proc CloseSocket { sock } {

		#return
		set sid [getObjOption $sock sid]

		set MsgId [lindex [::MSNP2P::SessionList get $sid] 0]

		set bheader [binary format ii 0 $MsgId][binword 0][binword 0][binary format iiii 0 4 [expr int([expr rand() * 1000000000])%125000000 + 4] 0][binword 0]

		puts -nonewline $sock "[binary format i 48]$bheader"
		status_log "Closing socket... \n" red
		close $sock

	}


	proc SendFileToSock  { sock } {

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

		set filename [FromUnicode [string range $context 20 569]]

		binary scan $filename A* filename

		if { $nopreview == 0 } {
			set previewdata [string range $context $size end]
			set dir [file join [set ::HOME] FT cache]
			create_dir $dir
			set fd [open "[file join $dir ${sid}.png ]" "w"]
			fconfigure $fd -translation binary
			puts -nonewline $fd "$previewdata"
			close $fd
			set file [file join $dir ${sid}.png]
			if { $file != "" } {
				::skin::setPixmap FT_preview_${sid} "[file join $dir ${sid}.png]"
			}
		}
		setObjOption $sid chatid $chatid

		status_log "context : $context \n size : $size \n filesize : $filesize \n nopreview : $nopreview \nfilename : $filename\n"
		::MSNFT::invitationReceived $filename $filesize $sid $chatid $dest 1
		::amsn::GotFileTransferRequest $chatid $dest $branchuid $cseq $uid $sid $filename $filesize

	}

	proc answerFTInvite { sid chatid branchid conntype } {

	#Use new FT protocol only if the user choosed this option in advanced preferences.
    if {[::config::getKey new_ft_protocol]} {
   		#Nothing
    } else {
   		return
    }

		::MSNP2P::SessionList set $sid [list -1 -1 -1 -1 -1 -1 -1 -1 -1 "$branchid" ]
		set session [::MSNP2P::SessionList get $sid]
		set dest [lindex $session 3]
		set callid [lindex $session 5]

		set conntype [abook::getDemographicField conntype]

		set listening [abook::getDemographicField listening]

		if {$listening == "true" } {
			set nonce "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
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

		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]

	}



	#//////////////////////////////////////////////////////////////////////////////
	# AcceptFT ( chatid dest branchuid cseq uid sid filename1 )
	# This function is called when a file transfer is accepted by the user
	proc AcceptFT { chatid dest branchuid cseq uid sid filename1 } {
		global files_dir

		# Let's open the file
		set filename [file join ${files_dir} $filename1]

		set origfile $filename

		set num 1
		while { [file exists $filename] } {
	                set filename "[filenoext $origfile] $num[fileext $origfile]"
			#set filename "$origfile.$num"
			incr num
		}

		status_log "Saving to file $filename\n" green

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
		set slpdata [::MSNP2P::MakeMSNSLP "OK" $dest [::config::getKey login] $branchuid [expr $cseq + 1] $uid 0 0 $sid]
		::MSNP2P::SendPacket [::MSN::SBFor $chatid] [::MSNP2P::MakePacket $sid $slpdata 1]
		::amsn::FTProgress a $sid $filename1 $dest 1000 $chatid
		status_log "MSNP2P | $sid -> Sent 200 OK Message for File Transfer\n" red
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

		switch $action {
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
if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
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
		[::ChatWindow::GetOutText ${win_name}] tag bind avyes$cookie <Button1-ButtonRelease> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure avno$cookie \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Button1-ButtonRelease> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr

		set txt [trans avaccepted]


		::amsn::WinWrite $chatid "\n----------\n" green
		::amsn::WinWrite $chatid " $txt\n" green
		::amsn::WinWrite $chatid "----------" green

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

		set sessionid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
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
		[::ChatWindow::GetOutText ${win_name}] tag bind avyes$cookie <Button1-ButtonRelease> ""


		[::ChatWindow::GetOutText ${win_name}] tag configure avno$cookie \
			-foreground #808080 -font bplainf -underline false
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Enter> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Leave> ""
		[::ChatWindow::GetOutText ${win_name}] tag bind avno$cookie <Button1-ButtonRelease> ""

		[::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr


		# Show on screen
		set txt [trans avcanceled]
		::amsn::WinWrite $chatid "\n----------\n" green
		::amsn::WinWrite $chatid " $txt\n" green
		::amsn::WinWrite $chatid "----------" green


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
		set sessionid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
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
		::amsn::WinWrite $chatid "\n----------\n" green
		::amsn::WinWrite $chatid " $txt\n" green
		::amsn::WinWrite $chatid "----------" green
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
    }

    proc MessageReceived { data } {

	status_log "Got data : $data" red
	set idx1 [string first "<TEXT" $data]
	set idx1 [string first ">" $data $idx1]
	set idx2 [string first "</TEXT>" $data $idx1]
	status_log "idx1 $idx1 [string first \"<TEXT\" $data] - idx2 $idx2\n" red
	if { $idx1 == -1 || $idx2 == -1 } {
	    return 0
	}
	set msg [string range $data [expr $idx1 + 1] [expr $idx2 -1]]

	set idx1 [string first "<FROM" $data]
	set idx1 [string first "name=\"" $data $idx1]
	incr idx1 6
	set idx2 [string first "\"" $data $idx1]
	incr idx2 -1
	if { $idx1 == -1 || $idx2 == -1 } {
	    return 0
	}
	set user [string range $data $idx1 $idx2]

	status_log "idx1 $idx1 - idx2 $idx2\n" red

	set chatid [GetChatId $user]

	if { $chatid == 0 } {
	    OpenMobileWindow $user
	    set chatid [GetChatId $user]
	}

	status_log "Writing mobile msg \"$msg\" on : $chatid\n" red
	::amsn::WinWrite $chatid "\n[trans mobilesays $user] : \n" says
	::amsn::WinWrite $chatid "$msg" user

    }


    proc OpenMobileWindow { user } {
	set chatid [GetChatId $user]
	status_log "opening chat window for mobile messaging : $chatid\n" red

	if { $chatid == 0 } {
	    set win [::ChatWindow::Open]
	    set chatid "mobile@$user"
	    ::ChatWindow::SetFor $chatid $win
	    SetChatId $user $chatid
	    UpdateWindow $win $user

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
	set to [::ChatWindow::GetTopToText $win_name]
	$to configure -state normal
	$to delete 0.0 end
	$to insert end "[trans tomobile]:"
	$to configure -width [string length "[trans tomobile]:"]

	set title "[trans tomobile] : $user_login"
	set toptext [::ChatWindow::GetTopText ${win_name}]

	$toptext configure -state normal -font sboldf -height 1 -wrap none

	set user_name [string map {"\n" " "} [::abook::getDisplayNick $user_login]]
	set state_code [::abook::getVolatileData $user_login state]

	if { $state_code == "" } {
	    set user_state ""
	    set state_code FLN
	} else {
	    set user_state [::MSN::stateToDescription $state_code]
	}

	set user_image [::MSN::stateToImage $state_code]

	if {[::config::getKey truncatenames]} {
	    #Calculate maximum string width
	    set maxw [winfo width $toptext]

	    if { "$user_state" != "" && "$user_state" != "online" } {
		incr maxw [expr 0-[font measure sboldf -displayof $toptext " \([trans $user_state]\)"]]
	    }

	    incr maxw [expr 0-[font measure sboldf -displayof $toptext " <${user_login}>"]]
	    $toptext insert end "[trunc ${user_name} ${win_name} $maxw sboldf] <${user_login}>"
	} else {
	    $toptext insert end "${user_name} <${user_login}>"
	}

	#TODO: When we have better, smaller and transparent images, uncomment this
	#$toptext image create end -image [::skin::loadPixmap $user_image] -pady 0 -padx 2

	if { "$user_state" != "" && "$user_state" != "online" } {
	    $toptext insert end "\([trans $user_state]\)"
	}
	$toptext insert end "\n"


	#Change color of top background by the status of the contact
	::ChatWindow::ChangeColorState $user_login $user_state $state_code ${win_name}


	#Calculate number of lines, and set top text size
	set size [$toptext index end]
	set posyx [split $size "."]
	set lines [expr {[lindex $posyx 0] - 2}]
	set ::ChatWindow::titles(${win_name}) ${title}

	$toptext delete [expr {$size - 1.0}] end
	$toptext configure -state normal -font sboldf -height $lines -wrap none
	$toptext configure -state disabled

	if { [info exists ::ChatWindow::new_message_on(${win_name})] && $::ChatWindow::new_message_on(${win_name}) == 1 } {
	    wm title ${win_name} "*${title}"
	} else {
	    wm title ${win_name} ${title}
	}
	update idletasks
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
