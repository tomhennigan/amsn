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

   proc acceptReceived {cookie chatid fromlogin body} {

      variable filedata

      if {![info exists filedata($cookie)]} {
         return
      }
   
      set requestdata [::MSN::GetHeaderValue $body Request-Data]
      set requestdata [string range $requestdata 0 [expr {[string length requestdata] -2}]]

      status_log "Ok, so here we have cookie=$cookie, requestdata=$requestdata\n" red
      
      if { $requestdata != "IP-Address" } {
         status_log "Requested data is not IP-Address!!: $requestdata\n" red
	 return
      }

      set ipaddr [::MSN::GetHeaderValue $body $requestdata]

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
         set port [::MSN::GetHeaderValue $body Port]
         set authcookie [::MSN::GetHeaderValue $body AuthCookie]
         status_log "Body: $body\n"
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

      set sock [sb get $sbn sock]
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
      global config files_dir
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
      global config files_dir
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
              catch {puts $sockid "USR $config(login) $authcookie\r"}
              status_log "FTNegotiation: I SEND: USR $config(login) $authcookie\r\n"

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
                 set filename "[file join [file dirname $origfile] $num.[file tail $origfile]]"
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

#       ::MSNP2P::SendFT $chatid $filename $filesize
#       return 0

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
      #TODO: here we should send CANCEL message
      cancelFT $cookie
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
      global config
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

		if {![string is digit $config(initialftport)] || [string length $config(initialftport)] == 0} {
			set config(initialftport) 6891
		}

      set port $config(initialftport)


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
      global config files_dir
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

  	#TODO: New abstract connection system
	proc connect { {passwd ""}} {

		global config
		set username [::config::getKey login]
		
		if { $passwd == "" } {
			global password
			set passwd [set password]
		}

		sb set ns name ns
		sb set ns sock ""
		sb set ns data [list]
		sb set ns server [split [::config::getKey start_ns_server] ":"]
		sb set ns stat "d"
		
		#Setup the conection
		setup_connection ns
		#Call the pre authentication
		set command [list "::[sb get ns connection_wrapper]::authInit"]
		if { [eval $command] < 0 } {
			return -1
		}

		cmsn_ns_connect $username $passwd

  	 }

	 
	proc logout {} {
		variable myStatus
		
		::MSN::WriteSBRaw ns "OUT\r\n";

  		#TODO: New abstract connection system
		set command [list "::[sb get ns connection_wrapper]::finish" ns]
		eval $command
		sb set ns stat "d"
		
		CloseSB ns
		
		global config automessage
		
		sb set ns server [split $config(start_ns_server) ":"]
		
		set myStatus FLN
		status_log "Loging out\n"
		
		if {$config(enablebanner) && $config(adverts)} {
			adv_pause
		}
		
		::groups::Disable
		
		StopPolling
		
		::abook::saveToDisk
		
		global list_BLP emailBList
	
		::MSN::clearList AL
		::MSN::clearList BL
		::MSN::clearList FL
		::MSN::clearList rL
		
		set list_BLP -1
		if { [info exists emailBList] } {
			unset emailBList
		}
		
		::abook::unsetConsistent
		
		set automessage "-1"
		
		cmsn_draw_offline
		#Alert dock of status change
		#      send_dock "FLN"
		send_dock "STATUS" "FLN"
	}


	#Callback procedure called when a REA (screen name change) message is received
	proc GotREAResponse { recv } {
	
		global  config
	
		if { [string tolower [lindex $recv 3]] == [string tolower $config(login)] } {
			#This is our own nick change
			::abook::setPersonal nick [urldecode [lindex $recv 4]]
			cmsn_draw_online 1
		} else {
			#This is another one nick change
			::abook::setContactData [lindex $recv 3] nick [urldecode [lindex $recv 4]]

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
	
		if { [::config::getKey displaypic] != "" } {
			::MSN::WriteSB ns "CHG" "$new_status $clientid [urlencode [create_msnobj [::config::getKey login] 3 [GetSkinFile displaypic [::config::getKey displaypic]]]]"
		} else {
			::MSN::WriteSB ns "CHG" "$new_status 0"
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
	}

	proc unblockUser { userlogin username} {
		::MSN::WriteSB ns REM "BL $userlogin"
		::MSN::WriteSB ns ADD "AL $userlogin $username"
	}

	# Move user from one group to another group
	proc moveUser { passport oldGid newGid {userName ""}} {
		if { $userName == "" } {
			set userName $passport
		}
		set rtrid [::MSN::WriteSB ns "REM" "FL $passport $oldGid"]
		set atrid [::MSN::WriteSB ns "ADD" "FL $passport [urlencode $userName] $newGid"]

	}

	#Copy user from one group to another
	proc copyUser { passport newGid {userName ""}} {
		if { $userName == "" } {
		set userName $passport
		}
		set atrid [::MSN::WriteSB ns "ADD" "FL $passport [urlencode $userName] $newGid"]
	}


	#Add user to our Forward (contact) list
	proc addUser { userlogin {username ""}} {
		set userlogin [string map {" " ""} $userlogin]
		if { $username == "" } {
			set username $userlogin
		}
		::MSN::WriteSB ns "ADD" "FL $userlogin $username 0" "::MSN::ADDHandler"
	}
   
	
	#Handler for the ADD message, to show the ADD messagebox
	proc ADDHandler { item } {
	
		if { [lindex $item 2] == "FL"} {
			set contact [lindex $item 4]	;# Email address
			msg_box "[trans contactadded]\n[urldecode $contact]"
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
	}

	##################################################
	#Internal procedures
	##################################################

	#Start the loop that will keep a keepalive (PNG) message every minute
	proc StartPolling {} {
		global config

		if {($config(keepalive) == 1) && ($config(connectiontype) == "direct")} {
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
		variable myStatus
		#Let's try to keep the connection alive... sometimes it gets closed if we
		#don't do send or receive something for a long time
		if { $myStatus != "FLN" } {
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

		#Finally, to write, use a wrapper, so it's transparent to use
		#a direct connection, a proxy, or anything      
		set command [list "::[sb get $sbn connection_wrapper]::write" $sbn $cmd]
		catch {eval $command} res
		
		if { $res == 0 } {
			if {$sbn != "ns" } {
				degt_protocol "->$sbn-[sb get $sbn sock] $cmd" sbsend
			} else {
				degt_protocol "->$sbn-[sb get $sbn sock] $cmd" nssend
			}
		} else {
			::MSN::CloseSB $sbn
			degt_protocol "->$sbn FAILED: $cmd" error
		}
	}


	########################################################################	
	# Check if the old closed preferred SB is still the preferred SB, or
	# close it if not.
	proc CheckKill { sbn } {
	
		#Kill any remaining timers
		after cancel "::MSN::CheckKill $sbn"
	
		if { [sb get $sbn stat] != "d" } {
			#The SB is connected again, forget about killing
			return
		} else {
		
			#Get the chatid
			set chatid [::MSN::ChatFor $sbn]

			if { $chatid == 0 } {
				#If SB is not in any chat, we can just kill it
				status_log "Session $sbn killed with no chatid associated\n"
				::MSN::KillSB $sbn
				return 0
			}

			#If we're the preferred chatid
			if { [::MSN::SBFor $chatid] == $sbn } {

				#It's the preferred SB, so keep it for the moment
				set items [expr {[sb length $sbn users] -1}]
				status_log "Session $sbn closed, there are [expr {$items+1}] users: [sb get $sbn users]\n" blue
				
				for {set idx $items} {$idx >= 0} {incr idx -1} {
					set user_info [sb index $sbn users $idx]
					sb ldel $sbn users $idx
					amsn::userLeaves [::MSN::ChatFor $sbn] [list $user_info] 0
				}
				
				#Try to kill it again in 5 minutes
				after 300000 "::MSN::CheckKill $sbn"
				
			} else {
				#It's not the preferred SB,so we can safely delete it from the
				#chat and Kill it
				DelSBFor $chatid $sbn
				::MSN::KillSB $sbn
			}
		}		
	}
   
	
	#///////////////////////////////////////////////////////////////////////
	# Usually called from anywhere when a problem is found when writing or
	# reading a SB. It closes the sock.
	# For NS connection, call only when an error happens. To manually log out,
	# call ::MSN::logout
	proc CloseSB { sbn } {

		status_log "::MSN::CloseSB $sbn Called\n" green
		catch {fileevent [sb get $sbn sock] readable "" } res
		catch {fileevent [sb get $sbn sock] writable "" } res
		
		set sock [sb get $sbn sock]

		if {$sock != ""} {
			set command [list "::[sb get $sbn connection_wrapper]::finish" $sbn]
			eval $command
		}
		
		#Append an empty string to the SB buffer. This will cause the
		#actual SB cleaning, but will allow to process all buffer
		#before doing the cleaning
		sb append $sbn data ""

	}
	#///////////////////////////////////////////////////////////////////////

	########################################################################
	#Called when we find a "" (empty string) in the SB buffer. This means
	#the SB is closed. Proceed to clear everything related to it
	proc ClearSB { sbn } {

		status_log "::MSN::ClearSB $sbn called\n" green
		
		set oldstat [sb get $sbn stat]
		sb set $sbn data ""
		sb set $sbn sock ""
		sb set $sbn stat "d"
		
		if { $sbn == "ns" } {
		
			#If we were not disconnected or authenticating, logout
			if { ("$oldstat" != "d") && ("$oldstat" != "u") } {
				logout
			}
			
			#If we're not disconnected, connected, or authenticating, then
			#we have a connection error.
			if { ("$oldstat"!="d") && ("$oldstat" !="o") && ("$oldstat" !="u") && ("$oldstat" !="passerror")} {
				set error_msg [sb get ns error_msg]
				if { $error_msg != "" } {
					msg_box "[trans connecterror]: [sb get ns error_msg]"
				} else {
					msg_box "[trans connecterror]"
				}
			}
		
			#If we were connected, we have lost the connection
			if { ("$oldstat"=="o") } {
				set error_msg [sb get ns error_msg]
				if { $error_msg != "" } {
					msg_box "[trans connectionlost]: [sb get ns error_msg]"
				} else {
					msg_box "[trans connectionlost]"
				}
				status_log "Connection lost\n" red
			}
			
		} else {
			#Check if we can kill the SB (clear all related info
			CheckKill $sbn	
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
				# DO NOT cleanchat... it's needed for WinTopUpdate 
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
	# Return a list of users in chat, or last user in chat is chat is closed
	proc usersInChat { chatid } {

		set sb_name [SBFor $chatid]

		if { $sb_name == 0 } {
			status_log "usersInChat: no SB for chat $chatid!! (shouldn't happen?)\n" white
			return [list]
		}
	
	
		set user_list [sb get $sb_name users]
	
		if { [llength $user_list] } {
			return $user_list
		} else {
			return [list [sb get $sb_name last_user]]
		}
	
	}

	########################################################################
	#Set the given $typer as a typing user. He will be removed after 6
	#seconds.
	proc addSBTyper { sb_name typer } {
		
		set idx [sb search $sb_name typers $typer]
		if {$idx == -1} {
			#Add if not already typing
			sb append $sb_name typers $typer
		}
	
		#Cancel last DelSBTyper timer
		after cancel [list ::MSN::DelSBTyper $sb_name $typer]
		#Remove typer after 6 seconds without a new notification
		after 6000 [list ::MSN::DelSBTyper $sb_name $typer]
		
		#TODO: Call CHAT layer instead of GUI layer
		set chatid [::MSN::ChatFor $sb_name]
		if { $chatid != "" } {
			::amsn::updateTypers $chatid
		}
	
	}	
	
	########################################################################
	#Remove the given typer from the chat typers list
	proc DelSBTyper {sb_name typer} {
		after cancel [list ::MSN::DelSBTyper $sb_name $typer]
		catch {
			set idx [sb search $sb_name typers $typer]
			sb ldel $sb_name typers $idx
		
			#TODO: Call CHAT layer instead of GUI layer
			set chatid [::MSN::ChatFor $sb_name]
			if { $chatid != "" } {
				::amsn::updateTypers $chatid
			}
		}
		
	}
	
	########################################################################
	#Return a list of users currently typing in the given chat
	proc typersInChat { chatid } {

		set name [SBFor $chatid]
		if { $name == 0 } {
			status_log "typersInChat: no SB for chat $chatid!!\n" white        
			return [list]
		}

		set num_typers [sb length $name typers]

		if {$num_typers > 0} {
			return [sb get $name typers]
		} else {
			return [list]
		}

	}

	
	proc lastMessageTime { chatid } {
		set sbn [SBFor $chatid]
		if {$sbn != 0} {
			return [sb get [SBFor $chatid] lastmsgtime]
		} else {
			return 0
		}
	}

   
	if { $initialize_amsn == 1 } {
		variable sb_num 0
	}

	
	proc GetNewSB {} {
		variable sb_num
		incr sb_num
		
		set sbn "sb_${sb_num}"
		
		sb set $sbn name $sbn
		sb set $sbn sock ""
		sb set $sbn data [list]
		sb set $sbn users [list]
		sb set $sbn typers [list]
		sb set $sbn lastmsgtime 0
		
		
		return "sb_${sb_num}"
		
		
	}

	
	proc chatTo { user } {

		global sb_list
	
		set lowuser [string tolower ${user}]

		#If there's already an existing chat for that user, and
		#that chat is ready, return it as chatd
		if { [chatReady $lowuser] } {
			return $lowuser
		}

		#Get SB for that chatid, if it exists
		set sbn [SBFor $lowuser]

		if { $sbn == 0 } {
			#If no SB exists, get a new one and
			#configure it
			set sbn [GetNewSB]

			status_log "::MSN::chatTo: Opening chat to user $user\n"
			status_log "::MSN::chatTo: No SB available, creating new: $sbn\n"
	
			sb set $sbn stat "d"
			sb set $sbn title [trans chat]
			sb set $sbn last_user $lowuser

			AddSBFor $lowuser $sbn
			lappend sb_list "$sbn"
		}
		#Now we have a SB ready for reconnection
		cmsn_reconnect $sbn
		
		return $lowuser
	}


	########################################################################
	#Totally remove the given SB
	proc KillSB { name } {
		global sb_list
		global ${name}_info

		status_log "::MSN::KillSB: Killing SB $name\n"

		set idx [lsearch -exact $sb_list $name]

		if {$idx == -1} {
			status_log "tried to destroy unknown SB $name\n" white
			return 0
		}

		catch {
			#fileevent [sb get $name sock] readable ""
			#fileevent [sb get $name sock] writable ""
			set command [list "::[sb get $name connection_wrapper]::finish" $name]
			eval $command
		} res

		set sb_list [lreplace $sb_list $idx $idx ]

		unset ${name}_info
	}

   
	########################################################################
	#Totally clean a chat. Remove all associated SBs
	proc CleanChat { chatid } {
		global config sb_list

		status_log "::MSN::CleanChat: Cleaning chat $chatid\n"

		while { [SBFor $chatid] != 0 } {

			set name [SBFor $chatid]
			DelSBFor $chatid ${name}

			#We leave the switchboard if it exists
			if {[sb get $name stat] != "d"} {
				WriteSBRaw $name "OUT\r\n"
			}

			after 60000 "::MSN::KillSB ${name}"
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

		set sbn [SBFor $chatid]
		set sb_sock [sb get $sbn sock]

		if { "$sbn" == "0" } {
			return 0
		}
	
		if { "$sb_sock" == "" } {
			return 0
		}
		
		# This next two are necessary because SBFor doesn't
		# always return a ready SB
		if { "[sb get $sbn stat]" != "o" } {
			return 0
		}

		if {[catch {eof $sb_sock} res]} {
			status_log "::MSN::chatReady: Error in the EOF command for $sbn socket($sb_sock): $res\n" red
			::MSN::CloseSB $sbn
			return 0
		}

		if {[eof $sb_sock]} {
			status_log "::MSN::chatReady: EOF in $sbn socket($sb_sock)\n"
			::MSN::CloseSB $sbn
			return 0
		}

		if {[sb length $sbn users]} {
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
				for {set idx 0} {$idx<[llength $sb_chatid($chatid)]} {incr idx} {
					set sbn [lindex $sb_chatid($chatid) $idx]
	
					if {![catch {sb get $sbn stat} res ]} {
						if { "[sb get $sbn stat]" == "o" } {
	
							set sb_sock [sb get $sbn sock]
		
							if { "$sb_sock" != "" } {
								if {$idx!=0} {
									set sb_chatid($chatid) [lreplace $sb_chatid($chatid) $idx $idx]
									set sb_chatid($chatid) [linsert $sb_chatid($chatid) 0 $sbn]
								}
								return $sbn
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
		global config msgacks

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


		#set sock [sb get $sbn sock]

		set txt_send [encoding convertto utf-8 [string map {"\n" "\r\n"} $txt]]

		set fontfamily [lindex $config(mychatfont) 0]
		set fontstyle [lindex $config(mychatfont) 1]
		set fontcolor [lindex $config(mychatfont) 2]

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

		set smilemsg "MIME-Version: 1.0\r\nContent-Type: text/x-mms-emoticon\r\n\r\n"
		set smilemsg "$smilemsg$smile_send"
		set smilemsg_len [string length $smilemsg]

		set msg "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n"
		if { $friendlyname != "" } {
			set msg "${msg}P4-Context: $friendlyname\r\n"
		} elseif { [::config::getKey p4c_name] != "" } {
			set msg "${msg}P4-Context: [::config::getKey p4c_name]\r\n"
		}
		set msg "${msg}x-clientcaps : aMSN/[set ::version]\r\n"
		set msg "${msg}X-MMS-IM-Format: FN=[urlencode $fontfamily]; EF=$style; CO=$color; CS=0; PF=22\r\n\r\n"
		set msg "$msg$txt_send"
		#set msg_len [string length $msg]
		set msg_len [string length $msg]

		#WriteSB $sbn "MSG" "A $msg_len"
		#WriteSBRaw $sbn "$msg"
		if { $smile_send != "" } {
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
		return [lindex $state 2]
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

	proc receivedCommand { sbn command } {
		if { $sbn == "ns" } {
			set debugcolor "nsrecv"
		} else {
			set debugcolor "sbrecv"
		}
		
		sb append $sbn data $command
		degt_protocol "<-$sbn $command\\n" $debugcolor
	}
	
	proc receivedPayload { sbn command data } {
		if { $sbn == "ns" } {
			set debugcolor "nsrecv"
		} else {
			set debugcolor "sbrecv"
		}	
		
		sb append $sbn data $command
		sb append $sbn data $data
		degt_protocol "<-$sbn $command\\n" $debugcolor
		degt_protocol "Message Contents:\n$data" msgcontents
	}

}


#Connection wrapper for Direct Connection
namespace eval ::DirectConnection {
	
	#Called to write some data to the connection
	proc write { sbn data } {
	
		set sb_sock [sb get $sbn sock]
		if {[catch {puts -nonewline $sb_sock "$data"} res]} {
			status_log "::DirectConnectin::Write: SB $sbn problem when writing to the socket: $res...\n" red
			return -1
		} else {
			return 0
		}
		
	}
	
	#Called to close the given connection
	proc finish {sbn} {
		
		set sock [sb get $sbn sock]
		
		catch {
			fileevent $sock readable ""
			fileevent $sock writable ""
		}
		
		if {[catch {close $sock}]} {
			return -1
		} else {
			return 0
		}
	}
	
	#Called to stablish the given connection.
	#The "server" field in the sbn data must be set to server:port
	proc connect {sbn} {
	
		set tmp_serv [lindex [sb get $sbn server] 0]
		set tmp_port [lindex [sb get $sbn server] 1]
	
		if { [catch {set sock [socket -async $tmp_serv $tmp_port]} res ] } {
			sb set $sbn error_msg $res
			return -1
		}
	
		sb set $sbn sock $sock
		fconfigure $sock -buffering none -translation {binary binary} -blocking 0
		fileevent $sock readable [list ::DirectConnection::Readable $sbn]
		fileevent $sock writable [sb get $sbn connected]
		return 0
	
	}
	
	proc authInit {} {
		global tlsinstalled login_passport_url
		
		#Check if we need to install the TLS module
		if { $tlsinstalled == 0 && [checking_package_tls] == 0 && [::config::getKey nossl] == 0} {
			::amsn::installTLS
			return -1
		}

		#If SSL is used, register https:// protocol
		if { [::config::getKey nossl] == 0 } {
			http::register https 443 ::tls::socket
		} else  {
			catch {http::unregister https}
		}

		#No proxy is used
		::http::config -proxyhost ""
		
		if { [::config::getKey nossl] == 1 } {
			#If we can't use ssl, avoid getting url from nexus
			set login_passport_url "https://login.passport.com/login2.srf"
		} else {
			#Contact nexus to get login url
			set login_passport_url 0
			after 500 "catch {::http::geturl [list https://nexus.passport.com/rdr/pprdr.asp] -timeout 10000 -command ::DirectConnection::GotNexusReply}"
		}
	}
	
	proc authenticate {str url} {
	
		set head [list Authorization "Passport1.4 OrgVerb=GET,OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom,sign-in=[::config::getKey login],pwd=[urlencode $::password],${str}"]
		#if { $config(nossl) == 1 || ($config(connectiontype) != "direct" && $config(connectiontype) != "http") } {
		#	set url [string map { https:// http:// } $url]
		#}
		if { [::config::getKey nossl] == 1 } {
			set url [string map { https:// http:// } $url]
		}
		status_log "::DirectConnection::authenticate: Getting $url\n" blue
		if {[catch {::http::geturl $url -command "::DirectConnection::GotAuthReply [list $str]" -headers $head}]} {
			eval [sb get ns autherror_handler]
			#msnp9_auth_error
		}
	
	}

	
	proc GotNexusReply {token {total 0} {current 0}} {
	
		global login_passport_url
		if { [::http::status $token] != "ok" || [::http::ncode $token ] != 200 } {
			#Nexus connection failed, so let's just set login URL manually
			set loginurl "https://login.passport.com/login2.srf"
			status_log "gotNexusReply: error in nexus reply, getting url manually\n" red
		} else {
			#We got reply from nexus. Extract login URL
			upvar #0 $token state
	
			set index [expr {[lsearch $state(meta) "PassportURLs"]+1}]
			set values [split [lindex $state(meta) $index] ","]
			set index [lsearch $values "DALogin=*"]
			set loginurl "https://[string range [lindex $values $index] 8 end]"
			status_log "gotNexusReply: loginurl=$loginurl\n" green
		}
		::http::cleanup $token
	
		#If $login_passport_url == 0, we got login url before authentication took place
		if { $login_passport_url == 0 } {
			#Set loginurl (will be used in authentication), and rest in peace
			set login_passport_url $loginurl
			status_log "gotNexusReply: finished before authentication took place\n" green
		} else {
			#Authentication is waiting for us to get this url!! Do authentication inmediatly
			status_log "gotNexusReply: authentication was waiting for me, so I'll do it\n" green
			::DirectConnection::authenticate $login_passport_url $loginurl
		}
	
	}

	proc GotAuthReply { str token } {
		if { [::http::status $token] != "ok" } {
			::http::cleanup $token
			status_log "::DirectConnection::GotAuthReply error: [::http::error]\n"
			eval [sb get ns autherror_handler]
			#msnp9_auth_error
			return
		}
	
		upvar #0 $token state
	
		if { [::http::ncode $token] == 200 } {
			#Authentication done correctly
			set index [expr {[lsearch $state(meta) "Authentication-Info"]+1}]
			set values [split [lindex $state(meta) $index] ","]
			set index [lsearch $values "from-PP=*"]
			set value [string range [lindex $values $index] 9 end-1]
			status_log "::DirectConnection::GotAuthReply 200 Ticket= $value\n" green
			
			set command [list [sb get ns ticket_handler] $value]
			eval $command
			#msnp9_authenticate $value
	
		} elseif {[::http::ncode $token] == 302} {
			#Redirected to another URL, try again
			set index [expr {[lsearch $state(meta) "Location"]+1}]
			set url [lindex $state(meta) $index]
			status_log "::DirectConnection::GotAuthReply 302: Forward to $url\n" green
			::DirectConnection::authenticate $str $url
		} elseif {[::http::ncode $token] == 401} {
			#msnp9_userpass_error
			eval [sb get ns passerror_handler]
		} else {
			eval [sb get ns autherror_handler]
			#msnp9_auth_error
		}
		::http::cleanup $token
	
	}
	
		
	#Private callback, called when there's something to be read in the socket	
	proc Readable {sbn} {

		set sb_sock [sb get $sbn sock]
		#catch {fileevent $sb_sock readable ""}
	
		if {[catch {eof $sb_sock} res]} {
			status_log "::DirectConnection::Read: Error reading EOF for $sbn: $res\n" red
			eval [sb get $sbn error_handler]
			return
		} elseif {[eof $sb_sock]} {	
			status_log "::DirectConnection::Read: EOF in $sbn, closing\n" red
			eval [sb get $sbn error_handler]
			return
		} else {
	
			set tmp_data "ERROR READING SB !!!"
			if {[catch {gets $sb_sock tmp_data} res]} {	
				status_log "::DirectConnection::Read: Read error in $sbn, closing: $res\n" red
				eval [sb get $sbn error_handler]
				return
			} elseif  { "$tmp_data" == "" } {
				update idletasks
			} else {
				if {[string range $tmp_data 0 2] == "MSG"} {
					set recv [split $tmp_data]
					set old_handler "[fileevent $sb_sock readable]"
					ReadNonBlocking $sbn [lindex $recv 3] [list ::DirectConnection::FinishedReadingPayload $sbn $old_handler $tmp_data]
				} else {
					set command [sb get $sbn command_handler]
					lappend command $tmp_data
					eval $command
				}
			}
		}
		#catch {fileevent $sb_sock readable [list ::DirectConnection::Readable $sbn]}
	}

	
	proc ReadNonBlocking { sbn amount finish_proc {read 0}} {
	
		set sock [sb get $sbn sock]
	
		fileevent $sock readable ""
	
		if {[catch {eof $sock} res]} {
			status_log "::DirectConnection::ReadNonBlocking: Error reading EOF for sock $sock ($sbn): $res\n" red
			eval [sb get $sbn error_handler]
			return
		} elseif {[eof $sock]} {
			status_log "::DirectConnection::ReadNonBlocking: Eof in sock $sock ($sbn), closing\n" red
			eval [sb get $sbn error_handler]
			return
		}
	
		set buffer_name "read_buffer_$sock"
		upvar #0 $buffer_name read_buffer
	
		if { $read == 0 } {
			set read_buffer ""
		}
	
		set to_read [expr {$amount - $read}]
		set data [read $sock $to_read]
	
		if  { "$data" == "" } {
			status_log "::DirectConnection::ReadNonBlocking: Blank read!! Why does this happen??\n" red
			update idletasks
		}

		set read_buffer "${read_buffer}$data"	
		set read_bytes [string length ${data}]
		set read_until_now [expr {$read + $read_bytes}]
	
		if { $read_until_now < $amount } {
			fileevent $sock readable [list ::DirectConnection::ReadNonBlocking $sbn $amount $finish_proc $read_until_now]
		} else {
			eval $finish_proc
		}
	}
	
	
	proc FinishedReadingPayload {sbn old_handler msg_data} {
	
		set sock [sb get $sbn sock]
	
		set buffer_name "read_buffer_$sock"
		upvar #0 $buffer_name read_buffer
	
		set command [sb get $sbn payload_handler]
		lappend command $msg_data
		lappend command $read_buffer
		eval $command

		unset read_buffer

		fileevent $sock readable $old_handler
	}
		
}




#Manages the SwitchBoard (SB) structure
#$do parameter is the action to perform over $sbn
proc sb {do sbn var {value ""}} {

	global ${sbn}_info
	set sb_tmp "${sbn}_info(${var})"
	upvar #0 $sb_tmp sb_data

	switch $do {
		name {
			return $sb_tmp
		}
		set {
			set sb_data $value
			return 0
		}
		get {
			if {![info exists sb_data]} {
				return ""
			}
			return $sb_data
		}
		append {
			if {![info exists sb_data]} {
				return ""
			}
			lappend sb_data $value
		}
		index {
			if {![info exists sb_data]} {
				return ""
			}
			return [lindex $sb_data $value]
		}
		ldel {
			if {![info exists sb_data]} {
				return
			}
			set sb_data [lreplace $sb_data $value $value]
		}
		length {
			if {![info exists sb_data]} {
				status_log "BIG ERROR???? TRYING TO GET LENGTH FROM AN UNEXISTING SB: $sbn $var\n" red
				return 0
			}

			return [llength $sb_data]
		}
		search {
			if {![info exists sb_data]} {
				return ""
			}

			return [lsearch $sb_data $value]
		}
		exists {
			return [info exists $sb_tmp]
		}
		unset {
			unset $sb_tmp
		}
	}
	return 0
}

proc proc_sb_watchdog {} {
	status_log "ALERT: PROC_SB STOPPED WORKING!!!!!!!" red
	after cancel proc_sb
	proc_sb
}


proc proc_sb {} {
	global sb_list

	after cancel proc_sb
	after 4000 proc_sb_watchdog
	
	#status_log "Processing SB\n"	
	foreach sbn $sb_list {
		while {[sb length $sbn data]} {
			set item [sb index $sbn data 0]
			
			set item [encoding convertfrom utf-8 $item]
			
			set item [string map {\r ""} $item]
			set item [split $item]
			
			sb ldel $sbn data 0
			
			if { $item == "" } {
				::MSN::ClearSB $sbn
				break
			}
			
			set result [cmsn_sb_handler $sbn $item]
			if {$result == 0} {
		
			} else {
				status_log "proc_sb: problem processing SB data!\n" red
				continue
			}

		}
	}
	
	after cancel proc_sb_watchdog
	after 250 proc_sb
	return 1
}


proc proc_ns_watchdog {} {
	status_log "ALERT: PROC_NS STOPPED WORKING!!!!!!!" red
	after cancel proc_ns
	proc_ns
}

proc proc_ns {} {
	
	after cancel proc_ns
	after 4000 proc_ns_watchdog

	#status_log "Processing NS\n"	
	while {[sb length ns data]} {
		set item [sb index ns data 0]
		

		set item [encoding convertfrom utf-8 $item]
		
		set item [string map {\r ""} $item]
		set item [split $item]
		sb ldel ns data 0

		if { $item == "" } {
			status_log "proc_ns: NS Socket was closed\n" green
			::MSN::ClearSB ns
			break
		}		
		
		set result [cmsn_ns_handler $item]
		if {$result != 0} {
			status_log "problem processing NS data: $item!!\n" red
		}
	}

	after cancel proc_ns_watchdog
	
	after 100 proc_ns
	return 1
}


proc cmsn_msg_parse {msg hname bname} {
	
	upvar $hname headers
	upvar $bname body

	set head_len [string first "\r\n\r\n" $msg]
	set head [string range $msg 0 [expr {$head_len - 1}]]
	set body [string range $msg [expr {$head_len + 4}] [string length $msg]]

	set body [encoding convertfrom utf-8 $body]
	set body [string map {"\r" ""} $body]

	set head [string map {"\r" ""} $head]
	set head_lines [split $head "\n"]
	foreach line $head_lines {
		set colpos [string first ":" $line]
		set attribute [string tolower [string range $line 0 [expr {$colpos-1}]]]
		set value [string range $line [expr {$colpos+2}] [string length $line]]
		array set headers [list $attribute $value]
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

proc cmsn_sb_msg {sb_name recv} {
   #TODO: A little cleaning on all this
   global filetoreceive files_dir automessage automsgsent config

   set msg [sb index $sb_name data 0]
   sb ldel $sb_name data 0

   array set headers {}
   set body ""
   cmsn_msg_parse $msg headers body

   set content [lindex [array get headers content-type] 1]
   set p4context [lindex [array get headers p4-context] 1]

   set typer [string tolower [lindex $recv 1]]
   if { [::config::getKey displayp4context] !=1 || $p4context == "" } {
	set nick [::abook::getDisplayNick $typer]
	   set p4c_enabled 0
   } else {
        set nick "[::config::getKey p4contextprefix]$p4context"
	   set p4c_enabled 1
   }
   #Notice that we're ignoring the nick sent in the own MSG command, and using the one in ::abook

   #upvar #0 [sb name $sb_name users] users_list
   set users_list [sb get $sb_name users]

   #Look what is our chatID, depending on the number of users
   if { [llength $users_list] == 1 } {
      set desiredchatid $typer
   } else {
      set desiredchatid $sb_name ;#For conferences, use sb_name as chatid
   }

   set chatid [::MSN::ChatFor $sb_name]

   if { $chatid != 0} {
      if { "$chatid" != "$desiredchatid" } {
         #Our chatid is different than the desired one!! try to change
	  status_log "cmsn_sb_msg: Trying to change chatid from $chatid to $desiredchatid for SB $sb_name\n"

         set newchatid [::amsn::chatChange $chatid $desiredchatid]
         if { "$newchatid" != "$desiredchatid" } {
            #The GUI doesn't accept the change, as there's another window for that chatid
            status_log "cmsn_sb_msg: change NOT accepted\n"
         } else {
            #The GUI accepts the change, so let's change
            status_log "sb_msg: change accepted\n"
            ::MSN::DelSBFor $chatid $sb_name
            set chatid $desiredchatid
            ::MSN::AddSBFor $chatid $sb_name
         }

      } else {
          #Add it so it's moved to front
          ::MSN::AddSBFor $chatid $sb_name
      }

   } else {

      status_log "cmsn_sb_msg: NO chatid in cmsn_sb_msg, please check this!!\n" white
      set chatid $desiredchatid
      ::MSN::AddSBFor $chatid $sb_name

   }




   #A standard message
   if {[string range $content 0 9] == "text/plain"} {

      #TODO: Process fonts in other place
      set fonttype [lindex [array get headers x-mms-im-format] 1]

      set begin [expr {[string first "FN=" $fonttype]+3}]
      set end   [expr {[string first ";" $fonttype $begin]-1}]
      set fontfamily "[urldecode [string range $fonttype $begin $end]]"

      set begin [expr {[string first "EF=" $fonttype]+3}]
      set end   [expr {[string first ";" $fonttype $begin]-1}]
      set fontstyle "[urldecode [string range $fonttype $begin $end]]"

      set begin [expr {[string first "CO=" $fonttype]+3}]
      set end   [expr {[string first ";" $fonttype $begin]-1}]
      set fontcolor "000000[urldecode [string range $fonttype $begin $end]]"
      set fontcolor "[string range $fontcolor end-1 end][string range $fontcolor end-3 end-2][string range $fontcolor end-5 end-4]"

      set style [list]
      if {[string first "B" $fontstyle] >= 0} {
        lappend style "bold"
      }
      if {[string first "I" $fontstyle] >= 0} {
        lappend style "italic"
      }
      if {[string first "U" $fontstyle] >= 0} {
        lappend style "underline"
      }
      if {[string first "S" $fontstyle] >= 0} {
        lappend style "overstrike"
      }

      #TODO: Remove the font style transformation from here and put it inside messageFrom or gui.tcl
		if { $config(disableuserfonts) } {
			set fontfamily [lindex $config(mychatfont) 0]
			set style [lindex $config(mychatfont) 1]
			#set fontcolor [lindex $config(mychatfont) 2]
		}

      ::amsn::messageFrom $chatid $typer $nick "$body" user [list $fontfamily $style $fontcolor] $p4c_enabled
      sb set $sb_name lastmsgtime [clock format [clock seconds] -format %H:%M:%S]
      ::abook::setContactData $chatid last_msgedme [clock format [clock seconds] -format "%D - %H:%M:%S"]

      #if alarm_onmsg is on run it
      if { ( [::alarms::isEnabled $chatid] == 1 )&& ( [::alarms::getAlarmItem $chatid onmsg] == 1) } {
	  set username [::abook::getDisplayNick $chatid]
	  run_alarm $chatid  "[trans says $username]: $body"
      } elseif { ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all onmsg] == 1) } {
	  set username [::abook::getDisplayNick $chatid]	  
	  run_alarm all  "[trans says $username]: $body"
      }


      # Send automessage once to each user
      	if { [info exists automessage] } {
	if { $automessage != "-1" && [lindex $automessage 4] != ""} {
		if { [info exists automsgsent($typer)] } {
			if { $automsgsent($typer) != 1 } {
				::amsn::MessageSend [::amsn::WindowFor $chatid] 0 [parse_exec [lindex $automessage 4]] "[trans automessage]"
				set automsgsent($typer) 1
			}
		} else {
				::amsn::MessageSend [::amsn::WindowFor $chatid] 0 [parse_exec [lindex $automessage 4]] "[trans automessage]"
				set automsgsent($typer) 1
			}
	}
	}


	::MSN::DelSBTyper $sb_name $typer


   } elseif {[string range $content 0 19] == "text/x-msmsgscontrol"} {

      ::MSN::addSBTyper $sb_name $typer

   } elseif {[string range $content 0 18] == "text/x-msmsgsinvite"} {

      #File transfers or other invitations
      set invcommand [::MSN::GetHeaderValue $body Invitation-Command]
      set cookie [::MSN::GetHeaderValue $body Invitation-Cookie]
      set fromlogin [lindex $recv 1]

      if {$invcommand == "INVITE" } {

         set guid [::MSN::GetHeaderValue $body Application-GUID]

         #An invitation, generate invitation event
	 if { $guid == "{5D3E02AB-6190-11d3-BBBB-00C04F795683}" } {
	    #We have a file transfer here

	    set filename [::MSN::GetHeaderValue $body Application-File]
	    set filesize [::MSN::GetHeaderValue $body Application-FileSize]

	    ::MSNFT::invitationReceived $filename $filesize $cookie $chatid $fromlogin

	 }

      } elseif { $invcommand == "ACCEPT" } {

            #Generate "accept" event
	    ::MSNFT::acceptReceived $cookie $chatid $fromlogin $body

      } elseif {$invcommand =="CANCEL" } {

         set cancelcode [::MSN::GetHeaderValue $body Cancel-Code]

	 if { $cancelcode == "FTTIMEOUT" } {
	    ::MSNFT::timeoutedFT $cookie
	 } elseif { $cancelcode == "REJECT" } {
	    ::MSNFT::rejectedFT $chatid $fromlogin $cookie
	 }

      } else {

	 #... other types of commands

      }

   } elseif { [string range $content 0 23] == "application/x-msnmsgrp2p" } {
   	#status_log "MSNP2P -> " red
	#status_log "Calling MSNP2P::Read with chatid $chatid msg=\n$msg\n"
	MSNP2P::ReadData $msg $chatid
      
   } elseif { [string range $content 0 18] == "text/x-mms-emoticon" } {
       global ${chatid}_smileys
       status_log "Got a custom smiley from peer\n" red
       set ${chatid}_smileys(dummy) ""
       parse_x_mms_emoticon $body $chatid
       status_log "got smileys : [array names ${chatid}_smileys]\n" blue
       foreach smile [array names ${chatid}_smileys] {
	   if { $smile == "dummy" } { continue } 
	   MSNP2P::loadUserSmiley $chatid $typer "[set ${chatid}_smileys($smile)]"
       }


   } else {
      status_log "cmsn_sb_msg: === UNKNOWN MSG ===\n$msg\n" red
   }

}


proc cmsn_sb_handler {sb_name item} {
	global list_cmdhnd msgacks config

	#set item [encoding convertfrom utf-8 $item]

	set ret_trid [lindex $item 1]
	set idx [lsearch $list_cmdhnd "$ret_trid *"]
	
	if {$idx != -1} {		;# Command has a handler associated!
		status_log "cmsn_sb_handler: Evaluating handler for $ret_trid in SB $sb_name\n"
		set command "[lindex [lindex $list_cmdhnd $idx] 1] {$item}"
		set list_cmdhnd [lreplace $list_cmdhnd $idx $idx]
		eval "$command"
		return 0
	} else {
		switch [lindex $item 0] {
			MSG {
				cmsn_sb_msg $sb_name $item
				return 0
			}
			BYE -
			JOI -
			IRO {
				cmsn_update_users $sb_name $item
				return 0
			}
			CAL {
				#status_log "$sb_name: [join $item]\n" green
				return 0
			}
			ANS {
				status_log "cmsn_sb_handler: ANS Chat started. [sb length $sb_name users] users: [sb get $sb_name users]\n" green
				if { [sb length $sb_name users] == 1 } {
					set chatid [sb index $sb_name users 0]
				} else {
					set chatid $sb_name
				}
				::MSN::AddSBFor $chatid $sb_name
	
				foreach usr_login [sb get $sb_name users] {
					::MSNP2P::loadUserPic $chatid $usr_login
					::amsn::userJoins $chatid $usr_login
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
				status_log "cmsn_sb_handler: invalid user name for chat\n" red
				msg_box "[trans invalidusername]"
			}
			215 {
				#if you try to begin a chat session with yourself
				set chatid [::MSN::ChatFor $sb_name]
				::MSN::ClearQueue $chatid
				::amsn::chatStatus $chatid "[trans useryourself]\n" miniwarning
				return 0
			}
			"" {
				return 0
			}
			default {
				if { "[sb get $sb_name stat ]" == "d" } {
					status_log "$sb_name: UNKNOWN SB ENTRY! --> [join $item]\n" red
				}
				return 0
			}
		}
	}
}


proc cmsn_invite_user {name user} {

	if { ("[sb get $name stat]" == "o") \
		|| ("[sb get $name stat]" == "n") \
		|| ("[sb get $name stat]" == "i")} {

		::MSN::WriteSB $name "CAL" $user "::MSN::CALReceived $name $user"

	} else {

		status_log "cmsn_invite_user: Can't invite user to non connected SB!!\n" red

	}

}


proc cmsn_rng {recv} {

	global config sb_list

	set emaill [string tolower [lindex $recv 5]]

	set sbn [::MSN::GetNewSB]

	#Init SB properly
	sb set $sbn stat ""
	sb set $sbn server [split [lindex $recv 2] ":"]
	sb set $sbn connected [list cmsn_conn_ans $sbn]
	sb set $sbn auth_cmd "ANS"
	sb set $sbn auth_param "$config(login) [lindex $recv 4] [lindex $recv 1]"
	
	lappend sb_list "$sbn"

	status_log "Accepting conversation from: [lindex $recv 5]... (Got ANS1 in SB $sbn\n" green

	setup_connection $sbn
	cmsn_socket $sbn
	return 0
}

proc cmsn_open_sb {sbn recv} {
	global config

	#TODO: I hope this works. If stat is not "c" (trying to connect), ignore
	if { [sb get $sbn stat] != "c" } {
		return 0
	}

	if {[lindex $recv 0] == "913"} {
		#Not allowed when offline
		set chatid [::MSN::ChatFor $sbn]
		::MSN::ClearQueue $chatid
		::MSN::CleanChat $chatid
		::amsn::chatStatus $chatid "[trans needonline]\n" miniwarning
		#msg_box "[trans needonline]"
		return 1
	}

	if {[lindex $recv 4] != "CKI"} {
		status_log "cmsn_open_sb: SB $sbn: Unknown SP requested!\n" red
		return 1
	}
	
	status_log "cmsn_open_sb: Opening SB $sbn\n" green

	sb set $sbn server [split [lindex $recv 3] ":"]
	sb set $sbn connected [list cmsn_conn_sb $sbn]
	sb set $sbn auth_cmd "USR"
	sb set $sbn auth_param "$config(login) [lindex $recv 5]"


	::amsn::chatStatus [::MSN::ChatFor $sbn] "[trans sbcon]...\n" miniinfo ready
	setup_connection $sbn	
	cmsn_socket $sbn
	return 0
}



proc cmsn_conn_sb {name} {
   
	catch { fileevent [sb get $name sock] writable "" } res

	#Reset timeout timer
	sb set $name time [clock seconds]

	sb set $name stat "a"

	set cmd [sb get $name auth_cmd]
	set param [sb get $name auth_param]
	
	::MSN::WriteSB $name $cmd $param "cmsn_connected_sb $name"
	
	::amsn::chatStatus [::MSN::ChatFor $name] "[trans ident]...\n" miniinfo ready

}


proc cmsn_conn_ans {name} {

	#status_log "cmsn_conn_ans: Connected to invitation SB $name...\n" green
	
	catch {fileevent [sb get $name sock] writable {}} res

	sb set $name time [clock seconds]
	sb set $name stat "a"

	set cmd [sb get $name auth_cmd]; set param [sb get $name auth_param]
	::MSN::WriteSB $name $cmd $param

	#status_log "cmsn_conn_ans: Authenticating in $name...\n" green

}


proc cmsn_connected_sb {name recv} {

	#status_log "cmsn_connected_sb: SB $name connected\n" green
	
	sb set $name time [clock seconds]
	sb set $name stat "i"

	if {[sb exists $name invite]} {

		cmsn_invite_user $name [sb get $name invite]

		::amsn::chatStatus [::MSN::ChatFor $name] \
			"[trans willjoin [sb get $name invite]]...\n" miniinfo ready

	} else {

		status_log "cmsn_connected_sb: got SB $name stat=i but no one to invite!!! CHECK!!\n" white

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


proc cmsn_reconnect { name } {

	switch [sb get $name stat] {
		"n" {
			
			status_log "cmsn_reconnect: stat = n , SB= $name, user=[sb get $name last_user]\n" green
			
			sb set $name time [clock seconds]
			sb set $name stat "i"
	
			cmsn_invite_user $name [sb get $name last_user]
	
			::amsn::chatStatus [::MSN::ChatFor $name] \
				"[trans willjoin [sb get $name last_user]]..." miniinfo ready
	
		} 
		
		"d" {
	
			status_log "cmsn_reconnect: stat = d , SB= $name, user=[sb get $name last_user]\n" green
			
			sb set $name time [clock seconds]
	
			sb set $name sock ""
			sb set $name data [list]
			sb set $name users [list]
			sb set $name typers [list]
			sb set $name title [trans chat]
			sb set $name lastmsgtime 0
	
			sb set $name stat "c"
			sb set $name invite [sb get $name last_user]
	
			if { [sb get ns stat] != "o" } {
				set chatid [::MSN::ChatFor $name]
				::MSN::ClearQueue $chatid
				::MSN::CleanChat $chatid
				::amsn::chatStatus $chatid "[trans needonline]\n" miniwarning	
				return
			}
			
			::MSN::WriteSB ns "XFR" "SB" "cmsn_open_sb $name"
			::amsn::chatStatus [::MSN::ChatFor $name] "[trans chatreq]..." miniinfo ready
	
		} 
		
		"i" {
	
			#status_log "cmsn_reconnect: stat = i , SB= $name\n" green   
		
			if { [expr {[clock seconds] - [sb get $name time]}] > 15 } {
				status_log "cmsn_reconnect: called again while inviting timeouted for sb $name\n" red
				#catch { fileevent [sb get $name sock] readable "" } res
				#catch { fileevent [sb get $name sock] writable "" } res
				set command [list "::[sb get $name connection_wrapper]::finish" $name]
				eval $command
				#catch {close [sb get $name sock]} res
				sb set $name stat "d"
				cmsn_reconnect $name
			}
	
		}
		
		"c" {
	
			#status_log "cmsn_reconnect: stat = c , SB= $name\n" green      
		
			if { [expr {[clock seconds] - [sb get $name time]}] > 10 } {
				status_log "cmsn_reconnect: called again while reconnect timeouted for sb $name\n" red
				#set command [list "::[sb get $name connection_wrapper]::finish" $name]
				#eval $command
				sb set $name stat "d"
				cmsn_reconnect $name
			}
	
		} 
		
		"cw" -
		"pw" -
		"a" {
			
			#status_log "cmsn_reconnect: stat =[sb get $name stat] , SB= $name\n" green         
	
			if { [expr {[clock seconds] - [sb get $name time]}] > 10 } {
				status_log "cmsn_reconnect: called again while authentication timeouted for sb $name\n" red
				#catch { fileevent [sb get $name sock] readable "" } res
				#catch { fileevent [sb get $name sock] writable "" } res
				set command [list "::[sb get $name connection_wrapper]::finish" $name]
				eval $command
				#catch {close [sb get $name sock]} res
				sb set $name stat "d"
				cmsn_reconnect $name
			}
		} 
		"" {
			status_log "cmsn_reconnect: SB $name stat is [sb get $name stat]. This is bad, should delete it and create a new one\n" red
			catch {
				set chatid [::MSN::ChatFor $name]
				::MSN::DelSBFor $chatid $name
				::MSN::KillSB $name
				::MSN::chatTo $chatid
			}
			
		} 
		default {
			status_log "cmsn_reconnect: SB $name stat is [sb get $name stat]\n" red
		}
	}

}





#///////////////////////////////////////////////////////////////////////
proc cmsn_update_users {sb_name recv} {
	global config 

	switch [lindex $recv 0] {

		BYE {

			set chatid [::MSN::ChatFor $sb_name]

			set leaves [sb search $sb_name users "[lindex $recv 1]"]
			sb set $sb_name last_user [sb index $sb_name users $leaves]
			sb ldel $sb_name users $leaves

			set usr_login [sb index $sb_name users 0]

			if { [sb length $sb_name users] == 1 } {
				#We were a conference! try to become a private

				set desiredchatid $usr_login

				set newchatid [::amsn::chatChange $chatid $desiredchatid]

				if { "$newchatid" != "$desiredchatid" } {
					#The GUI doesn't accept the change, as there's another window for that chatid
					status_log "cmsn_update_users: change NOT accepted from $chatid to $desiredchatid\n"

				} else {
					#The GUI accepts the change, so let's change
					status_log "cmsn_update_users: change accepted from $chatid to $desiredchatid\n"
					::MSN::DelSBFor $chatid $sb_name
					::MSN::AddSBFor $newchatid $sb_name                  
					set chatid $newchatid
				}

			} elseif { [sb length $sb_name users] == 0 && [sb get $sb_name stat] != "d" } {
				sb set $sb_name stat "n"
			}
	
			#Another option for the condition:
			# "$chatid" != "[lindex $recv 1]" || ![MSN::chatReady $chatid]
			if { [::MSN::SBFor $chatid] == $sb_name } {
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
			sb set $sb_name stat "o"

			set usr_login [string tolower [lindex $recv 4]]
			set usr_name [urldecode [lindex $recv 5]]

			sb append $sb_name users [list $usr_login]

			::abook::setContactData $usr_login nick $usr_name

			sb set $sb_name last_user $usr_login

		}

		JOI {
			sb set $sb_name stat "o"

			set usr_login [string tolower [lindex $recv 1]]
			set usr_name [urldecode [lindex $recv 2]]
		
			sb append $sb_name users [list $usr_login]

			::abook::setContactData $usr_login nick $usr_name
		
		
			if { [sb length $sb_name users] == 1 } {

				sb set $sb_name last_user $usr_login
				set chatid $usr_login

			} else {

				#More than 1 user, change into conference
		
				#Procedure to change chatid-sb correspondences
				set oldchatid [::MSN::ChatFor $sb_name]
	
				if { $oldchatid == 0 } {
					status_log "cmsn_update_users: JOI - VERY BAD ERROR, oldchatid = 0. CHECK!!\n" white
					return 0
				}
	
				set chatid $sb_name
	
				#Remove old chatid correspondence
				::MSN::DelSBFor $oldchatid $sb_name
				::MSN::AddSBFor $chatid $sb_name
		
				status_log "cmsn_update_users: JOI - Another user joins, Now I'm chatid $chatid (I was $oldchatid)\n"
				::amsn::chatChange $oldchatid $chatid

			}

			#Don't put it in status if we're not the preferred SB.
			#It can happen that you invite a user to your sb,
			#but just in that moment the user invites you,
			#so you will connect to its sb and be able to chat, but after
			#a while the user will join your old invitation,
			#and get a fake "user joins" message if we don't check it
			::MSNP2P::loadUserPic $chatid $usr_login
			
			if {[::MSN::SBFor $chatid] == $sb_name} {
				::amsn::userJoins $chatid $usr_login
			}
		}
	}

}
#///////////////////////////////////////////////////////////////////////


#TODO: ::abook system
proc cmsn_change_state {recv} {
	global config

	#::plugins::PostEvent ChangeState recv list_users list_states

	if {[lindex $recv 0] == "FLN"} {
		#User is going offline
		set user [lindex $recv 1]
		set user_name ""
		set substate "FLN"
		set msnobj ""
	} elseif {[lindex $recv 0] == "ILN"} {
		#Initial status
		set user [lindex $recv 3]
		set encoded_user_name [lindex $recv 4]
		set user_name [urldecode [lindex $recv 4]]
		set substate [lindex $recv 2]
		set msnobj [lindex $recv 6]
	} else {
		#Coming online or changing state
		set user [lindex $recv 2]
		set encoded_user_name [lindex $recv 3]
		set user_name [urldecode [lindex $recv 3]]
		set substate [lindex $recv 1]
		set msnobj [lindex $recv 5]
	}
	
	if { $msnobj != "" } {
		set msnobj [urldecode $msnobj]	
	} else {
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
	}
		
	set custom_user_name [::abook::getDisplayNick $user]

	set state_no [::MSN::stateToNumber $substate ]
	
	
    #alarm system (that must replace the one that was before) - KNO
	if {[lindex $recv 0] !="ILN"} {
	
		if {[lindex $recv 0] == "FLN"} {
			#User disconnected
			
			if {  ( [::alarms::isEnabled $user] == 1 )&& ( [::alarms::getAlarmItem $user ondisconnect] == 1) } {
				run_alarm [lindex $recv 1] [trans disconnect $custom_user_name]
			} elseif {  ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all ondisconnect] == 1) } {
				run_alarm all [trans disconnect $custom_user_name]
			}
		
		} else {
			if { ( [::alarms::isEnabled $user] == 1 )&& ( [::alarms::getAlarmItem $user onstatus] == 1) } {
				switch -exact [lindex $recv 1] {
					"NLN" {
					run_alarm [lindex $recv 2] "[trans changestate $custom_user_name [trans online]]"
					}
					"IDL" {
					run_alarm [lindex $recv 2] "[trans changestate $custom_user_name [trans away]]"
					}
					"BSY" {
					run_alarm [lindex $recv 2] "[trans changestate $custom_user_name [trans busy]]"
					}
					"BRB" {
					run_alarm [lindex $recv 2] "[trans changestate $custom_user_name [trans rightback]]"
					}
					"AWY" {
					run_alarm [lindex $recv 2] "[trans changestate $custom_user_name [trans away]]"
					}
					"PHN" {
					run_alarm [lindex $recv 2] "[trans changestate $custom_user_name [trans onphone]]"
					}
					"LUN" {
					run_alarm [lindex $recv 2] "[trans changestate $custom_user_name [trans gonelunch]]"
					}
				}
			} elseif { ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all onstatus] == 1)} {
				switch -exact [lindex $recv 1] {
					"NLN" {
					run_alarm all "[trans changestate $custom_user_name [trans online]]"
					}
					"IDL" {
					run_alarm all "[trans changestate $custom_user_name [trans away]]"
					}
					"BSY" {
					run_alarm all "[trans changestate $custom_user_name [trans busy]]"
					}
					"BRB" {
					run_alarm all "[trans changestate $custom_user_name [trans rightback]]"
					}
					"AWY" {
					run_alarm all "[trans changestate $custom_user_name [trans away]]"
					}
					"PHN" {
					run_alarm all "[trans changestate $custom_user_name [trans onphone]]"
					}
					"LUN" {
					run_alarm all "[trans changestate $custom_user_name [trans gonelunch]]"
					}
				}
			}
		}
	}
	#end of alarm system


	set maxw [expr {$config(notifwidth)-20}]
	set short_name [trunc $custom_user_name . $maxw splainf]
		
	#User logsout
	if {$substate == "FLN"} {
		
		#Register last logout
		::abook::setContactData $user last_logout [clock format [clock seconds] -format "%D - %H:%M:%S"]
		
		if { ($config(notifyoffline) == 1 && [::abook::getContactData $user notifyoffline -1] != 0) ||
		     [::abook::getContactData $user notifyoffline -1] == 1 } {
			#Show notify window if globally enabled, and not locally disabled, or if just locally enabled
			::amsn::notifyAdd "$short_name\n[trans logsout]." "" offline offline
		}
		
	# User was online before, so it's just a status change, and it's not
	# an initial state notification
	} elseif {[::abook::getVolatileData $user state FLN] != "FLN" && [lindex $recv 0] != "ILN"  } {

		if { ($config(notifystate) == 1 && [::abook::getContactData $user notifystatus -1] != 0) ||
		     [::abook::getContactData $user notifystatus -1] == 1 } {
			::amsn::notifyAdd "$short_name\n[trans statechange]\n[trans [::MSN::stateToDescription $substate]]." \
				"::amsn::chatUser $user" state state
		}

	} elseif {[lindex $recv 0] == "NLN"} {	;# User was offline, now online

		user_not_blocked "$user"
		
		#Register last login
		::abook::setContactData $user last_login [clock format [clock seconds] -format "%D - %H:%M:%S"]
		
		if { ($config(notifyonline) == 1 && [::abook::getContactData $user notifyonline -1] != 0) ||
		     [::abook::getContactData $user notifyonline -1] == 1 } {
			::amsn::notifyAdd "$short_name\n[trans logsin]." "::amsn::chatUser $user" online
		}

		if {  ( [::alarms::isEnabled $user] == 1 )&& ( [::alarms::getAlarmItem $user onconnect] == 1)} {
			run_alarm [lindex $recv 2] "$custom_user_name [trans logsin]"
		} elseif {  ( [::alarms::isEnabled all] == 1 )&& ( [::alarms::getAlarmItem all onstatus] == 1)} {	
			run_alarm all "$custom_user_name [trans logsin]"
		}
	} 
	set oldmsnobj [::abook::getVolatileData $user msobj]
	#set list_users [lreplace $list_users $idx $idx [list $user $user_name $state_no $msnobj]]
	
	::abook::setVolatileData $user state $substate
	::abook::setVolatileData $user msnobj $msnobj

	#status_log "old is $oldmsnobj new is $msnobj\n"
	if { $oldmsnobj != $msnobj} {

		global sb_list
		foreach sb $sb_list {
			set users_in_chat [sb get $sb users]
			if { [lsearch $users_in_chat $user] != -1 } {
				status_log "User changed image while image in use!! Updating!!\n" white
				::MSNP2P::loadUserPic [::MSN::ChatFor $sb] $user
			}
		}
	}
	
	
	::MSN::contactListChanged
	cmsn_draw_online 1
		
}


proc cmsn_ns_handler {item} {
	global list_cmdhnd password config

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
				cmsn_ns_msg $item
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
					sb set ns server $tmp_ns
					status_log "cmsn_ns_handler: got a NS transfer, reconnecting to [lindex $tmp_ns 0]!\n" green
					cmsn_ns_connect $config(login) $password nosigin
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
					global loading_list_info
					::abook::setContactData $loading_list_info(last) [lindex $item 1] [urldecode [lindex $item 2]]
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
				global config
				if { [info exists config(expanded_group_[lindex $item 1])] } {
					set ::groups::bShowing([lindex $item 1]) $config(expanded_group_[lindex $item 1])
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
					::MSN::logout
					msg_box "[trans servergoingdown]"
					return 0
				}
			}
			QNG {
				#Ping response
				status_log "Ping response\n" blue
				return 0
			}
			200 {
				status_log "Error: Syntax error\n" red
				msg_box "[trans syntaxerror]"
				return 0
			}
			201 {
				status_log "Error: Invalid parameter\n" red
				msg_box "[trans contactdoesnotexist]"
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
				::MSN::logout
				status_log "Error: Server is busy\n" red
				::amsn::errorMsg "[trans serverbusy]"
				return 0
			}
			601 {
				::MSN::logout
				status_log "Error: Server is unavailable\n" red
				::amsn::errorMsg "[trans serverunavailable]"
				return 0
			}
			500 {
				::MSN::logout
				status_log "Error: Internal server error\n" red
				::amsn::errorMsg "[trans internalerror]"
				return 0
			}
			911 {
				#set password ""
				sb set ns stat "passerror"
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


proc cmsn_ns_msg {recv} {

	set msg_data [sb index ns data 0]
	sb ldel ns data 0
	status_log "cmsn_ns_msg:\n$msg_data\n" red

	if { [lindex $recv 1] != "Hotmail" && [lindex $recv 2] != "Hotmail"} {
		status_log "cmsn_ns_msg: NS MSG From Unknown source ([lindex $recv 1] [lindex $recv 2]):\n$msg_data\n" red
		return
	}

	# Demographic Information about subscriber/user. Can be used
	# for a variety of things.
	set content [::MSN::GetHeaderValue $msg_data Content-Type]
	if {[string range $content 0 19] == "text/x-msmsgsprofile"} {
		status_log "Getting demographic and auth information\n" blue
		# 1033 is English. See XXXX for info
		set d(langpreference) [::MSN::GetHeaderValue $msg_data lang_preference]
		set d(preferredemail) [::MSN::GetHeaderValue $msg_data preferredEmail]
		set d(country) [::MSN::GetHeaderValue $msg_data country]
		set d(gender) [::MSN::GetHeaderValue $msg_data Gender]
		set d(kids) [::MSN::GetHeaderValue $msg_data Kid]
		set d(age) [::MSN::GetHeaderValue $msg_data Age]
		#Used for authentication
		set d(mspauth) [::MSN::GetHeaderValue $msg_data MSPAuth]
		set d(kv) [::MSN::GetHeaderValue $msg_data kv]
		set d(sid) [::MSN::GetHeaderValue $msg_data sid]
		set d(sessionstart) [clock seconds]
		set d(clientip) [::MSN::GetHeaderValue $msg_data ClientIP]		     
		::abook::setDemographics d
				
		global config
		::config::setKey myip $d(clientip)
		status_log "My IP is $config(myip)\n"
	} else {
		hotmail_procmsg $msg_data	 
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

	status_log "cmsn_auth starting, stat=[sb get ns stat]\n" blue

	global HOME config info

	switch [sb get ns stat] {

		a {
			#Send three first commands at same time, to it faster
			::MSN::WriteSB ns "VER" "MSNP9 MSNP8 CVR0"
			::MSN::WriteSB ns "CVR" "0x0409 winnt 6.0 i386 MSNMSGR 6.0.0602 MSMSGS $config(login)"
			::MSN::WriteSB ns "USR" "TWN I $config(login)"
			
			sb set ns stat "v"
			return 0
		}

		v {
			if {[lindex $recv 0] != "VER"} {
				status_log "cmsn_auth: was expecting VER reply but got a [lindex $recv 0]\n" red
				return 1
			} elseif {[lsearch -exact $recv "CVR0"] != -1} {
				#::MSN::WriteSB ns "CVR" "0x0409 winnt 6.0 i386 MSNMSGR 6.0.0602 MSMSGS $config(login)"
				sb set ns stat "i"
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
				global config
				#::MSN::WriteSB ns "USR" "TWN I $config(login)"
				sb set ns stat "u"
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

			#if {$config(nossl)
			#|| ($config(connectiontype) != "direct" && $config(connectiontype) != "http") } {
			#http::geturl "https://nexus.passport.com/rdr/pprdr.asp" -timeout 8000 -command "gotNexusReply [list $info(all)]"
				global login_passport_url
				if { $login_passport_url == 0 } {
					status_log "cmsn_auth_msnp9: Nexus didn't reply yet...\n"
					set login_passport_url $info(all)
				} else {
					status_log "cmsn_auth_msnp9: Nexus has replied so we have login URL...\n"
					set command [list "::[sb get ns connection_wrapper]::authenticate" $info(all) $login_passport_url]
					eval $command
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

			sb set ns stat "o"

			save_config						;# CONFIG
			::config::saveGlobal
			
			if { [::abook::loadFromDisk] < 0 } {
				::abook::clearData
				::abook::setConsistent
			}
			

			::abook::setPersonal nick [urldecode [lindex $recv 4]]	
			::abook::setPersonal login [lindex $recv 3]
			recreate_contact_lists
			#For compatibility only!!
			load_alarms

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

			#Add a contact
			.main_menu.tools entryconfigure 0 -state normal
			.main_menu.tools entryconfigure 1 -state normal
			.main_menu.tools entryconfigure 4 -state normal
			#Added by Trevor Feeney
			#Enables the Group Order Menu
			.main_menu.tools entryconfigure 5 -state normal

			#Change nick
			configureMenuEntry .main_menu.actions "[trans changenick]..." normal
			#configureMenuEntry .options "[trans changenick]..." normal

			configureMenuEntry .main_menu.actions "[trans sendmail]..." normal
			configureMenuEntry .main_menu.actions "[trans sendmsg]..." normal


			return 0
		}

	}

	return -1

}

proc recreate_contact_lists {} {

	global config
	
	#There's no need to recreate groups, as ::groups already gets all data
	#from ::abook	
	foreach groupid [::groups::GetList] {
		::groups::Set $groupid [::groups::GetName $groupid]
		if { [info exists config(expanded_group_$groupid)] } {
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


	if {[::config::getKey startoffline]} {
		::MSN::changeStatus "HDN"
		send_dock "STATUS" "HDN"
	} else {
		::MSN::changeStatus "NLN"
		send_dock "STATUS" "NLN"
	}

	cmsn_ns_handler $recv
}

proc msnp9_userpass_error {} {

	sb set ns stat "passerror"
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

	if {[sb get ns stat] == "u" } {
		::MSN::WriteSB ns "USR" "TWN S $ticket"
		sb set ns stat "us"
	} else {
		status_log "Connection timeouted\n" white
		::MSN::logout
		msg_box "[trans connecterror]: Connection timed out"
	}
	return

}


proc sb_change { chatid } {
	global typing config

	set sbn [::MSN::SBFor $chatid]

	if { $sbn == 0 } {
		status_log "sb_change: VERY BAD ERROR - SB=0\n" error
		return 0
	}

	if { ![info exists typing($sbn)] } {
		set typing($sbn) 1

		after 4000 "unset typing($sbn)"

		set sock [sb get $sbn sock]

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgscontrol\r\nTypingUser: $config(login)\r\n\r\n\r\n"
		set msg_len [string length $msg]

		#::MSN::WriteSB $sbn "MSG" "U $msg_len"
		#::MSN::WriteSBRaw $sbn "$msg"
		::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"
	}
}



###################### Other Features     ###########################


proc fileDialog2 {w ent operation basename {types {{"All files"         *}} }} {
    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    #   set types {{"All files"		*} }
    
    global starting_dir

    if {$operation == "open"} {
	set file [tk_getOpenFile -filetypes $types -parent $w -initialdir $starting_dir]
    } else {
	set file [tk_getSaveFile -filetypes $types -parent $w \
	    -initialfile $basename]
    }
    if {[string compare $file ""]} {
	$ent delete 0 end
	$ent insert 0 $file
	$ent xview end
    }
}


proc ns_enter {} {
	set command "[.status.enter get]"
	.status.enter delete 0 end
	status_log "Executing : $command\n"
	if { [string range $command 0 0] == "/"} {
		#puts -nonewline [sb get ns sock] "[string range $command 1 [string length $command]]\r\n"
		::MSN::WriteSBRaw ns "[string range $command 1 [string length $command]]\r\n"
	} elseif {$command != ""} {
		if {[catch {eval $command} res]} {
			::amsn::errorMsg "$res"
		} else {
			status_log "$res\n"
		}
	}
   
}

# Added by DEGT during creation of Proxy namespace based on original
# by Dave Mifsud and expanding on the idea.
proc proxy_callback {event socket_name} {
    switch $event {
        dropped {   # Proxy connection dropped/closed during read
	    if {$socket_name == "ns"} {
	    	::MSN::CloseSB ns
	    }
	}
    }
}

proc setup_connection {name} {

	#This is the default read handler, if not changed by proxy
	sb set $name command_handler [list ::MSN::receivedCommand $name]
	sb set $name payload_handler [list ::MSN::receivedPayload $name]
	#This is the default procedure that should be called when an error is detected
	sb set $name error_handler [list ::MSN::CloseSB $name]

	if {[::config::getKey connectiontype] == "direct" } {
 		sb set $name connection_wrapper DirectConnection

	} elseif {[::config::getKey connectiontype] == "http"} {
	
 		sb set $name connection_wrapper HTTPConnection
		sb set $name proxy_host ""
		sb set $name proxy_port ""

		#status_log "cmsn_socket: Setting up http connection\n" green
		#set tmp_serv "gateway.messenger.hotmail.com"
		#set tmp_port 80

		#::Proxy::Init "$tmp_serv:$tmp_port" "http"

		#::Proxy::OnCallback "dropped" "proxy_callback"

		#status_log "cmsn_socket: Calling proxy::Setup now\n" green
		#::Proxy::Setup next readable_handler $name
		
		
	} elseif {[::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "http"} {
	
		#TODO: Right now it's always HTTP proxy!!
		sb set $name connection_wrapper HTTPConnection
		set proxy [split [::config::getKey proxy] ":"]
		sb set $name proxy_host [lindex $proxy 0]
		sb set $name proxy_port [lindex $proxy 1]
		
		sb set $name proxy_authenticate [::config::getKey proxyauthenticate]
		sb set $name proxy_user [::config::getKey proxyuser]
		sb set $name proxy_password [::config::getKey proxypass]
	
		#status_log "cmsn_socket: Setting up Proxy connection (type=$config(proxytype))\n" green
		#::Proxy::Init $config(proxy) $config(proxytype)
		#::Proxy::LoginData $config(proxyauthenticate) $config(proxyuser) $config(proxypass)
	
		#set proxy_serv [split $config(proxy) ":"]
		#set tmp_serv [lindex $proxy_serv 0]
		#set tmp_port [lindex $proxy_serv 1]        
		#::Proxy::OnCallback "dropped" "proxy_callback"
		
		#status_log "cmsn_connect: Calling proxy::Setup now\n" green
		#::Proxy::Setup next readable_handler $name
	
	}
}

proc cmsn_socket {name} {

	
	sb set $name time [clock seconds]
	sb set $name stat "cw"
	sb set $name error_msg ""
	
	set command [list "::[sb get $name connection_wrapper]::connect" $name]
	if {[eval $command]<0} {
		::MSN::CloseSB $name
	}
	 
	
	
	#if { [catch {set sock [socket -async $tmp_serv $tmp_port]} res ] } {
	#	sb set $name error_msg $res
	#	::MSN::CloseSB $name
	#	return
	#}
	
	#sb set $name sock $sock
	#fconfigure $sock -buffering none -translation {binary binary} -blocking 0
	#fileevent $sock readable $readable_handler
	#fileevent $sock writable $next
}

proc cmsn_ns_connected {} {
	global config


	set error_msg ""
	set therewaserror [catch {set error_msg [fconfigure [sb get ns sock] -error]} res]
	if { ($error_msg != "") || $therewaserror == 1 } {
		sb set ns error_msg $error_msg
		status_log "cmsn_ns_connected ERROR: $error_msg\n" red
		::MSN::CloseSB ns
		return
	}   
	
	fileevent [sb get ns sock] writable {}
	sb set ns stat "a"
	

	cmsn_auth
	if {$config(enablebanner) && $config(adverts)} {
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
	
	if {[sb get ns stat] != "d"} {
		set command [list "::[sb get ns connection_wrapper]::finish" ns]
		eval $command
	}

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

	sb set ns autherror_handler "msnp9_auth_error"
	sb set ns passerror_handler "msnp9_userpass_error"
	sb set ns ticket_handler "msnp9_authenticate"
	sb set ns data [list]
	sb set ns connected "cmsn_ns_connected"

	cmsn_socket ns

	return 0
}



proc process_msnp9_lists { bin } {

	set lists [list]
	
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
		
			#Add only if user is not already in list
			#upvar #0 $list_name the_list
			#if { [lsearch $the_list $username] == -1 } {
			#	lappend $list_name $username
			#	#status_log "cmsn_listupdate: adding $username to $list_name\n"
			#} else {
			#	status_log "cmsn_listupdate: user $username already in list $list_name\n" white
			#}
			::MSN::addToList $list_sort $username

			if { ($list_sort == "FL") } {
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

	set msnobjcontext([string map {"\n" ""} [::base64::encode "$msnobj\x00"]]) $filename
	
	return $msnobj
}

proc getfilename { filename } {
	return "[file tail $filename]"
}

proc filenoext { filename } {
	return "[string replace $filename [string last . $filename] end]"
}

#"

namespace eval ::MSNP2P {
	namespace export loadUserPic SessionList ReadData MakePacket MakeACK MakeSLP  AcceptFT RejectFT

	#Get picture from $user, if cached, or sets image as "loading", and request it
	#using MSNP2P
	proc loadUserPic { chatid user } {
		global config
		if { $config(getdisppic) != 1 } {
			status_log "Display Pics disabled, exiting loadUserPic\n" red
			return
		}

		#status_log "::MSNP2P::GetUser: Checking if picture for user $user exists\n" blue

		set msnobj [::abook::getVolatileData $user msnobj]

		#status_log "::MSNP2P::GetUser: MSNOBJ is $msnobj\n" blue

		set filename [::MSNP2P::GetFilenameFromMSNOBJ $msnobj]
		status_log "::MSNP2P::GetUser: filename is $filename\n" white

		if { $filename == "" } {
			return
		}

		global HOME
		if { ![file readable "[file join $HOME displaypic cache ${filename}].gif"] } {
			status_log "::MSNP2P::GetUser: FILE [file join $HOME displaypic cache ${filename}] doesn't exist!!\n" white
			image create photo user_pic_$user -file [GetSkinFile displaypic "loading.gif"]

			create_dir [file join $HOME displaypic]
			create_dir [file join $HOME displaypic cache]
			::MSNP2P::RequestObject $chatid $user $msnobj
		} else {
			catch {image create photo user_pic_$user -file "[file join $HOME displaypic cache ${filename}].gif"}

		}
	}

	proc loadUserSmiley { chatid user msnobj } {
		global config
		if { $config(getdisppic) != 1 } {
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

	if { [info exists msnobjcontext($context)] } {
	    status_log "Found filename\n" red
	    return $msnobjcontext($context)
	} else {
	    status_log "Couln't find filename for context \n$context\n --- [array get msnobjcontext] --[info exists msnobjcontext($context)] \n" red
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
	proc ReadData { data chatid } {
		global config HOME

		#status_log "called ReadData with $data\n" red

		# Get values from the header
		set idx [expr [string first "\r\n\r\n" $data] + 4]
		set headend [expr $idx + 48]
	    
	        binary scan [string range $data $idx $headend] iiiiiiiiiiii cSid cId cOffset1 cOffset2 cTotalDataSize1 cTotalDataSize2 cMsgSize cFlags cAckId cAckUID cAckSize1 cAckSize2

	        set cOffset [int2word $cOffset1 $cOffset2]
	        set cTotalDataSize [int2word $cTotalDataSize1 $cTotalDataSize2]
   	        set cAckSize [int2word $cAckSize1 $cAckSize2]

		#status_log "Read header : $cSid $cId $cOffset $cTotalDataSize $cMsgSize $cFlags $cAckId $cAckUID $cAckSize\n" red
		#status_log "Sid : $cSid -> " red

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
			 	status_log "MSNP2P | $sid -> Got MSNP2P ACK " red

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
					    status_log "MSNP2P | $sid -> Sending DATA now\n" red
					    set file [lindex [SessionList get $sid] 8]
					    if { $file != "" } {
						SendData $sid $chatid "[lindex [SessionList get $sid] 8]"
					    } else {
						SendData $sid $chatid "[GetSkinFile displaypic $config(displaypic)]"
					    }
					}
				    DATASENT {
					SessionList set $sid [list -1 -1 -1 -1 0 -1 -1 -1 -1 -1]
					status_log "MSNP2P | $sid -> Got ACK for sending data, now sending BYE\n" red
					set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
					SendPacket [::MSN::SBFor $chatid] [MakePacket $sid [MakeMSNSLP "BYE" [lindex [SessionList get $sid] 3] $config(login) "$branchid" "0" [lindex [SessionList get $sid] 5] 0 0] 1]
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

				set idx [expr [string first "Conn-Type: " $data] + 11]
				set idx2 [expr [string first "\r\n" $data $idx] - 1]
				set conntype [string range $data $idx $idx2]
				
				set idx [expr [string first "UPnPNat: " $data] + 9]
				set idx2 [expr [string first "\r\n" $data $idx] - 1]
				set upnp [string range $data $idx $idx2]

				# Let's send an ACK
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]

				# We received an invite for a FT, send 200 OK
				answerFTInvite $sid $chatid $branchuid $conntype

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
				
				
				if { $eufguid == "A4268EEC-FEC5-49E5-95C3-F126696BDBF6" || $eufguid == "5D3E02AB-6190-11D3-BBBB-00C04F795683"} {
					status_log "MSNP2P | $sid $dest -> Got INVITE for buddy icon, emoticon, or file transfer\n" red
					
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
					}
					
					# Let's send an ACK
					SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
					status_log "MSNP2P | $sid $dest -> Sent ACK for INVITE\n" red
					
					# Check if this is Buddy Icon or Emoticon request
					if { $appid == 1 } {
						# Let's make and send a 200 OK Message
						set slpdata [MakeMSNSLP "OK" $dest $config(login) $branchuid [expr $cseq + 1] $uid 0 0 $sid]
						SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]
						status_log "MSNP2P | $sid $dest -> Sent 200 OK Message\n" red
						
						# Send Data Prep AFTER ACK received (set AfterAck)
						SessionList set $sid [list -1 -1 -1 -1 "DATAPREP" -1 -1 -1 -1 -1]
						
						# Check if this is a file transfer
					} elseif { $appid == 2 } {
						# Let's get filename and filesize from context
						set idx [expr [string first "Context:" $data] + 9]
						set idx2 [expr $idx + 250]
						set context [base64::decode [string range $data $idx $idx2]]
						set filename [string map { \x00 "" } [string range $context 19 end]]
						binary scan [string range $context 8 12] i filesize
						status_log "context : $context \n [string range $context 8 12]  \nfilename : $filename $filesize \n"
						::MSNFT::invitationReceived $filename $filesize $sid $chatid $dest 1
						::amsn::GotFileTransferRequest $chatid $dest $branchuid $cseq $uid $sid $filename $filesize
					}
					return
				} elseif { $eufguid == "4BD96FC0-AB17-4425-A14A-439185962DC8" }	{
					status_log "we got an webcam invitation" red
					::amsn::WinWrite $chatid " [trans webcaminvite [::abook::getNick $dest]]\n" black "" 0
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
					status_log "MSNP2P | $sid -> Ignoring packet! not for us!\n"
					return
				}
				
				status_log "MSNP2P | $sid -> Got 200 OK message, sending an ACK for it\n" red
				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]
				if { $type == "filetransfer" } {
					SendFTInvite $sid $chatid 
				}
			} else {
				set idx [expr [string first "Call-ID: \{" $data] + 10]
				set idx2 [expr [string first "\}" $data $idx] -1]
				set uid [string range $data $idx $idx2]
				set sid [SessionList findcallid $uid]
				set idx [expr [string first "Listening: " $data] + 11]
				set idx2 [expr [string first "\r\n" $data $idx] -1]
				set listening [string range $data $idx $idx2]

				status_log "MSNP2P | $sid -> Got 200 OK for File transfer, parsing result\n"
				status_log "MSNP2P | $sid -> Found uid = $uid , lestening = $listening\n"

				SendPacket [::MSN::SBFor $chatid] [MakeACK $sid 0 $cTotalDataSize $cId $cAckId]

				if { $listening == "true" } {
					set idx [expr [string first "Nonce: " $data] + 7]
					set idx2 [expr [string first "\r\n" $data $idx] -1]
					set nonce [string range $data $idx $idx2]

					set idx [expr [string first "IPv4External-Addrs: " $data] + 20]
					set idx2 [expr [string first "\r\n" $data $idx] -1]
					set addr [string range $data $idx $idx2]

					set idx [expr [string first "IPv4External-Port: " $data] + 19]
					set idx2 [expr [string first "\r\n" $data $idx] -1]
					set port [string range $data $idx $idx2]
					status_log "MSNP2P | $sid -> Receiver is listening with $addr : $port\n" red
					after 5500 "::MSNP2P::SendData $sid $chatid [lindex [SessionList get $sid] 8]"
					connectMsnFTP $sid $nonce $addr $port
				} elseif { $listening == "false" } {
					status_log "MSNP2P | $sid -> Receiver is not listening, sending INVITE\n" red
					SendFTInvite2 $sid $chatid
				} else {
					status_log "Error sending file $filename, got answer to invite :\n$data\n\n" red
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

		# Let's check for data preparation messages and data messages
		if { $cSid != 0 } {
		    # Make sure this isn't a canceled FT
		    if { [lindex [SessionList get $cSid] 7] == "ftcanceled" } { return }
		    set sid $cSid
		    set fd [lindex [SessionList get $cSid] 6]
		    
		    #If it's a file transfer, display Progress bar
		    if { [lindex [SessionList get $cSid] 7] == "filetransfer" } {
		    	::amsn::FTProgress r $cSid [lindex [SessionList get $cSid] 6] $cOffset $cTotalDataSize
		    }
		    if { $fd != "" && $fd != 0 && $fd != -1 } {
			# File already open and being written to (fd exists)
			# Lets write data to file
			puts -nonewline $fd [string range $data $headend [expr $headend + $cMsgSize - 1]]
			status_log "MSNP2P | $sid -> FD EXISTS, file already open... with fd = $fd --- $cOffset + $cMsgSize + $cTotalDataSize . Writing DATA to file\n" red
			# Check if this is last part if splitted
			if { [expr $cOffset + $cMsgSize] >= $cTotalDataSize } {
			    close $fd
			    
			    set session_data [SessionList get $cSid]
			    set user_login [lindex $session_data 3]
			    set filename [lindex $session_data 8]
				
			    # Lets send an ACK followed by a BYE if it's a buddy icon or emoticon
			    status_log "MSNP2P | $sid -> Sending an ACK for file received and sending a BYE\n" red
			    SendPacket [::MSN::SBFor $chatid] [MakeACK $sid $cSid $cTotalDataSize $cId $cAckId]
			    			    			
			    if { [lindex [SessionList get $cSid] 7] == "bicon" } {
			    	SendPacket [::MSN::SBFor $chatid] [MakePacket $sid [MakeMSNSLP "BYE" $user_login $config(login) "19A50529-4196-4DE9-A561-D68B0BF1E83F" 0 [lindex $session_data 5] 0 0] 1]
				
				set filename2 [::MSNP2P::GetFilenameFromMSNOBJ [::abook::getVolatileData $user_login msnobj]]
				status_log "MSNP2P | $sid -> Got picture with file : $filename and $filename2\n" blue
				if {$filename == $filename2 } {
				
				    status_log "MSNP2P | $sid -> Closed file $filename.. finished writing\n" red
				    set file [png_to_gif [file join $HOME displaypic cache ${filename}.png]]
				    if { $file != "" } {
							set file [filenoext $file].gif
							if {[catch {image create photo user_pic_${user_login} -file [file join $HOME displaypic cache "${filename}.gif"]}] } {
								image create photo user_pic_${user_login} -file [GetSkinFile displaypic nopic.gif]
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
				#::amsn::WinWrite $chatid "----------\n" green
				#::amsn::WinWriteIcon $chatid fticon 3 2
				#::amsn::WinWrite $chatid " [trans filetransfercomplete]\n\n" green
				#::amsn::WinWrite $chatid "----------\n" green
			    }
			}
		    } elseif { $cMsgSize == 4 } {
			# We got ourselves a DATA PREPARATION message, lets open file and send ACK
			set session_data [SessionList get $sid]
			set user_login [lindex $session_data 3]
			status_log "MSNP2P | $sid $user_login -> Got data preparation message, opening file for writing\n" red
			set filename [lindex $session_data 8]
			set filename2 [::MSNP2P::GetFilenameFromMSNOBJ [::abook::getVolatileData $user_login msnobj]]
			status_log "MSNP2P | $sid $user_login -> opening file $filename for writing with $filename2 as user msnobj\n\n" blue
			if { $filename == $filename2 } {
			    create_dir [file join $HOME displaypic cache]
			    set fd [open "[file join $HOME displaypic cache ${filename}.png]" w]
			} else {
			    create_dir [file join $HOME smileys cache]
			    set fd [open "[file join $HOME smileys cache ${filename}.png]" w]   
			}

			fconfigure $fd -translation binary
			SendPacket [::MSN::SBFor $chatid] [MakeACK $sid $cSid $cTotalDataSize $cId $cAckId]
			status_log "MSNP2P | $sid $user_login -> Sent an ACK for DATA PREP Message\n" red
			SessionList set $sid [list -1 -1 -1 -1 -1 -1 $fd -1 -1 -1]
		    } else {
			# This is a DATA message, lets receive
		#	puts -nonewline $fd [string range $data $headend [expr $headend + $cMsgSize]]
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
		global config
		# Let's create a new session
		set sid [expr int([expr rand() * 1000000000])%125000000 + 4]
		# Generate BranchID and CallID
		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

	        SessionList set $sid [list 0 0 0 $dest 0 $callid 0 "bicon" [::MSNP2P::GetFilenameFromMSNOBJ $msnobject] ""]

		# Create and send our packet
		set slpdata [MakeMSNSLP "INVITE" $dest $config(login) $branchid 0 $callid 0 0 "A4268EEC-FEC5-49E5-95C3-F126696BDBF6" $sid 1 [string map { "\n" "" } [::base64::encode "$msnobject\x00"]]]
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
	proc MakePacket { sid slpdata {nullsid "0"} {MsgId "0"} {TotalSize "0"} {Offset "0"} {Destination "0"} {AfterAck "0"} } {

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
		append bheader [binary format i 0]
		
		# Just give the Ack Session ID some dumbo random number
		append bheader [binary format i [myRand 4369 6545000]]


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
		status_log "Sent a packet with header $theader\n" red
		
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
        #			1 for application/x-msnmsgr-transreqbody (Starting transfer)
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
			} else {
				append data "Content-Type: application/x-msnmsgr-transreqbody\r\n"
			}
		}
		append data "Content-Length: [expr [string length $body]]\r\n\r\n"
#"
		append data $body
		unset body

		#status_log $data
		return $data
	}

	#//////////////////////////////////////////////////////////////////////////////
	# SendData ( sid chatid )
	# This procedure sends the data given by the filename in the Session vars given by SessionID
	proc SendData { sid chatid filename } {
		global config
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
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $chunk]
		unset chunk

		status_log "[SessionList get $sid]\n"
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

	
	#//////////////////////////////////////////////////////////////////////////////
	# SendPacket ( sbn msg )
	# This function sends the packet given by (msg) into the given (sbn)
	proc SendPacket { sbn msg } {
		set msg_len [string length $msg]
		::MSN::WriteSBNoNL $sbn "MSG" "D $msg_len\r\n$msg"
	}








	proc SendFT { chatid filename filesize} {
		global config
		
		set sid [expr int([expr rand() * 1000000000])%125000000 + 4]
		# Generate BranchID and CallID
		set branchid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
		
		set dest [lindex [::MSN::usersInChat $chatid] 0]
		
		SessionList set $sid [list 0 0 0 $dest 0 $callid 0 "filetransfer" "$filename" "$branchid"]
		set previewdata "\x1c\x02\x00\x00\x00\x00\x00\x00[binary format i $filesize]\x00\x00\x00\x00\x00\x00\x00\x00"
		
		set idx 0
		set file [getfilename $filename]
		for { set i 19 } { $i < 539 } { incr i } {
			if { [expr $i % 2] == 1 && $idx < [string length "$file"]} {
				set previewdata "${previewdata}[string range $file $idx $idx]"
				incr idx
			} else {
				set previewdata "${previewdata}\x00"
			}
		}
		
		
		# Create and send our packet
		set slpdata [MakeMSNSLP "INVITE" $dest $config(login) $branchid 0 $callid 0 0 "5D3E02AB-6190-11D3-BBBB-00C04F795683" $sid 2 \
				 [string map { "\n" "" } [::base64::encode "$previewdata"]]]
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]
		status_log "Sent an INVITE to [::MSN::usersInChat $chatid]  on chatid $chatid for filetransfer of filename $filename\n" red
	
	}
	
	
	
	proc SendFTInvite { sid chatid} {
		global config
		
		set session [SessionList get $sid]
		set branchid [lindex $session 9]
		set callid [lindex $session 5]
		set dest [lindex $session 3]

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



		set slpdata [MakeMSNSLP "INVITE" $dest $config(login) $branchid 0 $callid 0 1 "TCPv1" \
				 $netid $conntype $upnp "false"]
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]
		
		#	after 5000 "::MSNP2P::SendData $sid $chatid [lindex [SessionList get $sid] 8]"
	}
	
	
	proc SendFTInvite2 { sid chatid} {
		global config
		
		set session [SessionList get $sid]
		set branchid [lindex $session 9]
		set callid [lindex $session 5]

		set dest [lindex $session 3]
		set conntype [abook::getDemographicField conntype]

		set listening [abook::getDemographicField listening]

		if {$listening == "true" } {
			set nonce "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr [expr int([expr rand() * 1000000])%65450]] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
			set port [OpenMsnFTPort [config::getKey initialftport]]
			set clientip [::abook::getDemographicField clientip]
			set localip [::abook::getDemographicField localip]
		} else {
			set nonce "00000000-0000-0000-0000-000000000000"
			set port ""
			set clientip ""
			set localip ""
		}


		set slpdata [MakeMSNSLP "INVITE" $dest $config(login) $branchid 1 $callid 0 2 "TCPv1" "true" "$nonce" "$clientip"\
				 "$port" "$localip" "$port"]
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]
		
#		after 5000 "::MSNP2P::SendData $sid $chatid [lindex [SessionList get $sid] 8]"
	}

	proc OpenMsnFTPort { port } {
		while { [catch {set sock [socket -server "handleMsnFT" $port] } ] } {
			incr port
		}
		return $port
	}
       
	proc handleMsnFT { sock ip port } {
		status_log "Received connection from $ip on port $port - socket $sock"
		
	}
	proc connectMsnFTP { sid nonce ip port {receive 0}} {
		if { [catch {set sock [ socket $ip $port] } ] } {
			status_log "ERROR CONNECTING TO THE SERVER\n\n" red 
		} else {
			status_log "connected\n"
		}
	}

	proc answerFTInvite { sid chatid branchid conntype } {
		SessionList set $sid [list -1 -1 -1 -1 -1 -1 -1 -1 -1 "$branchid" ]
		set session [SessionList get $sid]
		set dest [lindex $session 3]
		set callid [lindex $session 5]

		set slpdata [MakeMSNSLP "OK" $dest [config::getKey login] $branchid 1 $callid 0 1 "TCPv1" "false" "00000000-0000-0000-0000-000000000000"]
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]

	}
	
	
	
	#//////////////////////////////////////////////////////////////////////////////
	# AcceptFT ( chatid dest branchuid cseq uid sid filename1 )
	# This function is called when a file transfer is accepted by the user
	proc AcceptFT { chatid dest branchuid cseq uid sid filename1 } {
		global config files_dir

		# Let's open the file
		set filename [file join ${files_dir} $filename1]
		set origfile $filename
		
		set num 1
		while { [file exists $filename] } {
			set filename "$origfile.$num"
			incr num
		}

		# If we can't create the file notify the user and reject the FT request
		if {[catch {open $filename w} fileid]} {
			# Cannot create this file. Abort.
			status_log "Could not saved the file '$filename' (write-protected target directory?)\n" red
			RejectFT $chatid $sid $branchuid $uid
			::amsn::infoMsg [trans readonlymsgbox] warning
			return
		}

		fconfigure $fileid -translation binary
		SessionList set $sid [list -1 -1 -1 -1 -1 -1 $fileid -1 -1 -1]

		# Let's make and send a 200 OK Message
		set slpdata [MakeMSNSLP "OK" $dest $config(login) $branchuid [expr $cseq + 1] $uid 0 0 $sid]
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]
		::amsn::FTProgress w $sid $filename1 [trans throughserver] 1000 $chatid
		status_log "MSNP2P | $sid -> Sent 200 OK Message for File Transfer\n" red
	}

	#//////////////////////////////////////////////////////////////////////////////
	# CancelFT ( chatid sid )
	# This function is called when a file transfer is canceled by the user
	proc CancelFT { chatid sid } {
		global config
		set session_data [SessionList get $sid]
		set user_login [lindex $session_data 3]
		
		status_log "MSNP2P | $sid -> User canceled FT, sending BYE to chatid : $chatid and SB : [::MSN::SBFor $chatid]\n" red
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid [MakeMSNSLP "BYE" $user_login $config(login) "19A50529-4196-4DE9-A561-D68B0BF1E83F" 0 [lindex $session_data 5] 0 0] 1]
		::amsn::FTProgress ca $sid [lindex [SessionList get $sid] 6]

		# Change sid type to canceledft
		SessionList set $sid [list -1 -1 -1 -1 -1 -1 -1 "ftcanceled" -1 -1]
	}

	#//////////////////////////////////////////////////////////////////////////////
	# RejectFT ( chatid sid branchuid uid )
	# This function is called when a file transfer is rejected/canceled
	proc RejectFT { chatid sid branchuid uid } {
		global config
		# All we need to do is send a DECLINE
		set slpdata [MakeMSNSLP "DECLINE" [lindex [SessionList get $sid] 3] $config(login) $branchuid 1 $uid 0 0 $sid]
		SendPacket [::MSN::SBFor $chatid] [MakePacket $sid $slpdata 1]

		# And we unset our sid vars
		SessionList unset $sid
	}

	proc myRand { min max } {
		set maxFactor [expr [expr $max + 1] - $min]
		set value [expr int([expr rand() * 1000000])]
		set value [expr [expr $value % $maxFactor] + $min]
		return $value
	}
}


proc binword { word } {

	return [binary format ii $word 0]
	#return [binary format ii [expr $word % 4294967296] [expr ( $word - ( $word % 4294967296)) / 4294967296 ]]

}


proc int2word { int1 int2 } {
	if { $int2>0} {
		status_log "Warning!!!! int was a 64-bit integer!! Ignoring for tcl/tk 8.3 compatibility!!!!\n" white
	}
	return $int1
	#return [expr $int2 * 4294967296 + $int1]
}
