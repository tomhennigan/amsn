#	Microsoft Messenger Protocol Implementation
#=======================================================================


set user_info ""
set user_stat "FLN"
set list_fl [list]
set list_rl [list]
set list_al [list]
set list_bl [list]
set list_users [list]
set list_BLP -1
#A list for temp users, usually that join chats but are not in your list
set list_otherusers [list]
set list_cmdhnd [list]

set sb_list [list]

#Double array containing:
# CODE NAME COLOR ONLINE/OFFLINE  SMALLIMAGE BIGIMAGE
set list_states {
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


namespace eval ::MSNFT {
   namespace export inviteFT acceptFT rejectFT

   #TODO: Instead of using a list, use many variables: ft_name, ft_sockid...
      
   proc invitationReceived { filename filesize cookie chatid fromlogin } {
      variable filedata
      
      ::amsn::fileTransferRecv $filename $filesize $cookie $chatid $fromlogin
      set filedata($cookie) [list "$filename" $filesize $chatid $fromlogin "receivewait" "ipaddr"]
      after 300000 "::MSNFT::DeleteFT $cookie"
      #set filetoreceive [list "$filename" $filesize]
      
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
         status_log "Requested data is not IP-Adress!!: $requesteddata\n" red
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
         puts "Closing FT socket $sockid\n" 
         catch {fileevent $sockid writable ""}
	 catch {fileevent $sockid readable ""}
	 catch {close $sockid}
         puts "Closing FT file $fileid\n" 
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
         return 0
      }

      after cancel "::MSNFT::DeleteFT $cookie"
      set filedata($cookie) [lreplace $filedata($cookie) 4 4 "receive"]

      set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
      set msg "${msg}Invitation-Command: ACCEPT\r\n"
      set msg "${msg}Invitation-Cookie: $cookie\r\n"
      set msg "${msg}Launch-Application: FALSE\r\n"
      set msg "${msg}Request-Data: IP-Address:\r\n\r\n"
      
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
      
   }


   proc rejectFT {chatid cookie} {
   
      set sbn [::MSN::SBFor $chatid]
      if {$sbn == 0 } {
         cancelFT $cookie
         return 0
      }

      #Send the cancelation for a file transfer
      set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
      set msg "${msg}Invitation-Command: CANCEL\r\n"
      set msg "${msg}Invitation-Cookie: $cookie\r\n"
      set msg "${msg}Cancel-Code: REJECT\r\n\r\n"

      set msg_len [string length $msg]
      ::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"
      
      status_log "Rejecting filetransfer sent\n" red

   }


   proc ConnectMSNFTP {ipaddr port authcookie cookie} {
      #I connect to a remote host to retrive the file
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

      puts "Here2"
      
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
                 set filename "$origfile.$num"
                 incr num
              }

              #TODO: Can write to that file?
	      set fileid [open $filename w]
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

      set sbn [::MSN::SBFor $chatid]
      if {$sbn == 0 } {
         return 0
      }

      set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
      set msg "${msg}Application-Name: File Transfer\r\n"
      set msg "${msg}Application-GUID: {5D3E02AB-6190-11d3-BBBB-00C04F795683}\r\n"
      set msg "${msg}Invitation-Command: INVITE\r\n"
      set msg "${msg}Invitation-Cookie: $cookie\r\n"
      set msg "${msg}Application-File: [file tail $filename]\r\n"
      set msg "${msg}Application-FileSize: $filesize\r\n\r\n"
      set msg_len [string length $msg]

      set msg [encoding convertto utf-8 $msg]      
      ::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"

      status_log "Invitation to $filename sent: $msg\n" red

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
      #option: posibility to enter IP address (firewalled connections)
      set ipaddr [lindex $filedata($cookie) 5]
      #if error ::AMSN::Error ...

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

      puts "Here2 state=$state cookie=$cookie sockid=$sockid"
      
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
   
      puts "cookie=$cookie"
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
	  
         catch {puts -nonewline $sockid "\0[format %c $byte1][format %c $byte2]$data"} 
	 flush $sockid
         set sentbytes [expr {$sentbytes + $packetsize}]
	 ::amsn::FTProgress s $cookie [lindex $filedata($cookie) 0] $sentbytes $filesize
         fileevent $sockid writable "::MSNFT::SendPacket $sockid $fileid $filesize $cookie"

      } 
      

   }

   proc MonitorTransfer { sockid cookie} {
      
      puts "Monitortransfer"
      variable filedata
      
      if {![info exists filedata($cookie)]} {
        status_log "MonitorTransfer: Ignoring file transfer, filedata($cookie) doesn't exists, cancelled\n" red
        return
      }     
                  
      if { [eof $sockid] } {
         status_log "MonitorTransfer EOF\n" white
	 cancelFT $cookie
	 return
      }

      fileevent $sockid readable ""
      
      #Monitor messages from the receiving host in a file transfer
      fconfigure $sockid -blocking 1
      gets $sockid datos
      
      status_log "Got from remote side: $datos\n"
      if {[string range $datos 0 2] == "CCL"} {
         status_log "Connection cancelled\n"
	 cancelFT $cookie
         return
      }
  
      if {[string range $datos 0 2] == "BYE"} {
         status_log "Connection finished\n"
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
   cancelReceiving cancelSending getMyIP moveUser

   variable myStatus FLN
   
   proc connect { username password } {

      #Log out
      .main_menu.file entryconfigure 2 -state normal

      ::MSN::StartPolling
      ::groups::Reset      
      
      cmsn_ns_connect $username $password

   }

   proc logout {} {

      #if {[sb get ns stat] == "d"} {
      #   return 0
      #}
      status_log "::MSN::logout called\n"
      
      ::MSN::WriteSBRaw ns "OUT\r\n";      
      
      catch {close [sb get ns sock]} res
      sb set ns stat "d"
      
      CloseSB ns
      
      global config user_stat
      variable myStatus

      sb set ns serv [split $config(start_ns_server) ":"]

      set myStatus FLN
      #TODO: Remove user_stat global variable
      set user_stat FLN
      status_log "Loging out\n"

      if {$config(adverts)} {
         adv_pause
      }

      ::groups::Disable
      
      StopPolling

      cmsn_draw_offline
      #Alert dock of status change
#      send_dock "FLN"
	send_dock "STATUS" "FLN"
   }


   proc GotREAResponse { recv } {

         global user_info config

         status_log "recv: $recv\n" blue

         if { [lindex $recv 3] == $config(login) } {
            set user_info $recv
            cmsn_draw_online
         }

   }

   proc badNickCheck { userlogin newname recv } {

      if { "[lindex $recv 0]" == "209"} {

         status_log "Nick not accepted\n" white

         #Try again urlencoding any character
	 set name [urlencode_all $newname]
         if { [string length $name] > 350} {
           set name [string range $name 0 350]
         }
         ::MSN::WriteSB ns "REA" "$userlogin $name"
	 return 0

      } elseif { "[lindex $recv 0]" == "REA"} {
         status_log "Nick accepted\n" white
         GotREAResponse $recv
         return 0
      }
   }

   proc changeName { userlogin newname } {

      global config
   
      set name [urlencode $newname]
      if { [string length $name] > 350} {
        set name [string range $name 0 350]
      }

      if { $config(allowbadwords) } {
         ::MSN::WriteSB ns "REA" "$userlogin $name" \
      	   "::MSN::badNickCheck $userlogin [list $newname]"
      } else {
         ::MSN::WriteSB ns "REA" "$userlogin $name"
      }
   }


   proc changeStatus {new_status} {
      variable myStatus
      global autostatuschange

      ::MSN::WriteSB ns "CHG" $new_status
      set myStatus $new_status

      #Reset automatic status change to 0
      set autostatuschange 0
   }

   proc myStatusIs {} {
       variable myStatus
       return $myStatus
   }

   proc userIsBlocked {userlogin} {
      global list_bl

      if {[lsearch $list_bl "$userlogin*"] != -1} {
         return 1
      } else {
         return 0
      }

   }

   proc blockUser { userlogin username} {
     ::MSN::WriteSB ns REM "AL $userlogin"
     ::MSN::WriteSB ns ADD "BL $userlogin $userlogin"
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

   proc copyUser { passport oldGid newGid {userName ""}} {
      if { $userName == "" } {
        set userName $passport
      }
      set atrid [::MSN::WriteSB ns "ADD" "FL $passport [urlencode $userName] $newGid"]
   }


   proc addUser { userlogin {username ""}} {
      if { $username == "" } {
        set username $userlogin
      }
      ::MSN::WriteSB ns "ADD" "FL $userlogin $username 0"
   }

   proc deleteUser { userlogin } {
      ::MSN::WriteSB ns REM "FL $userlogin"
   }


   proc getMyIP {} {
      global config
      set sock [sb get ns sock]

      status_log "Called getmyip"
      
      #TODO: The sockname options is not documented... find a better way?
      set ip [lindex [fconfigure $sock -sockname] 0]

      status_log "$ip"

      if { [string compare -length 3 $ip "10."] == 0 \
      || [string compare -length 4 $ip "127."] == 0 \
      || [string compare -length 8 $ip "192.168."] == 0 \
      || $config(natip) == 1 } {
      	status_log "called get http ip"
	set token [::http::geturl "http://www2.simflex.com/ip.shtml" -timeout 10000]
	
	set ip [::http::data $token]
	
	set ip [string range $ip 162 176]
	set idx [string first \n $ip]
	set ip [string range $ip 0 [expr {$idx-1}] ]
	status_log "$ip\n$token"
	
	::http::cleanup $token
      	unset token
      }

      return $ip
   }


   #Internal procedures
  
   proc StartPolling {} {
      global config

      if {($config(keepalive) == 1) && ($config(connectiontype) == "direct")} {
      	after 60000 "::MSN::PollConnection"
      } else {
      	after cancel "::MSN::PollConnection"
      }
   }

   proc StopPolling {} {
      after cancel "::MSN::PollConnection"
   }   
   
   proc PollConnection {} {
      variable myStatus

      #Let's try to keep the connection alive... sometimes it gets closed if we
      #don't do send or receive something for a long time

      if { $myStatus != "FLN" } {
	#puts -nonewline [sb get ns sock] "PNG\r\n"
	::MSN::WriteSBRaw ns "PNG\r\n"
      }

      after 60000 "::MSN::PollConnection"
   }

   variable trid 0
   variable atransfer

   proc DirectWrite { sbn cmd } {
   
      set sb_sock [sb get $sbn sock]

      #set command "[sb get ns puts] -nonewline [sb get ns sock] \"$cmd\""
      if {[catch {puts -nonewline $sb_sock "$cmd"} res]} {
         status_log "::MSN::DirectWrite: problem when writing to the socket: $res...\n" WHITE
         ::MSN::CloseSB $sbn
         degt_protocol "->$sbn FAILED: $cmd" error
      } else {

         if {$sbn != "ns" } {
            degt_protocol "->$sbn-$sb_sock $cmd" sbsend
         } else {
            degt_protocol "->$sbn-$sb_sock $cmd" nssend
         }
	 
      }
      
   }
   
   proc WriteSB {sbn cmd param {handler ""}} {
      WriteSBNoNL $sbn $cmd "$param\r\n" $handler
   }
   
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

      global config
      #TODO: change this

      #Finally, to write, use write_proc (by default ::MSN::DirectWrite)      
      set command "[sb get $sbn write_proc] [list $cmd]"
      #status_log "Evaluating: $command\n" white
      catch {eval $command}
      

   }

   #///////////////////////////////////////////////////////////////////////
   # Usually called from anywhere when a problem is found when writing or
   # reading a SB. It closes the sock.
   # For NS connection, call only when an error happens. To manually log out,
   # call ::MSN::logout
   proc CloseSB { sbn } {

      status_log "::MSN::CloseSB: $sbn\n" green
            
      catch {fileevent [sb get $sbn sock] readable "" } res
      catch {fileevent [sb get $sbn sock] writable "" } res

      if { $sbn == "ns" } {
         proc_ns      
      } else {
         proc_sb
      }
      
      set oldstat [sb get $sbn stat]
      set oldsock [sb get $sbn sock]      
            
      sb set $sbn stat "d"         
      sb set $sbn sock ""
        
      catch {close $oldsock} res      

      if { $sbn == "ns" } {
	  
         status_log "Closing NS socket! (stat= $oldstat)\n" red      
         if { ("$oldstat" != "d") && ("$oldstat" != "u") } {
            logout
         }
	 
	 if { ("$oldstat"!="d") && ("$oldstat" !="o") && ("$oldstat" !="u")} {
	    set error_msg [sb get ns error_msg]
	    if { $error_msg != "" } {
	       msg_box "[trans connecterror]: [sb get ns error_msg]"
	    } else {
	       msg_box "[trans connecterror]"
	    }
	 }

	 if { ("$oldstat"=="o") } {
	    set error_msg [sb get ns error_msg]	    
	    if { $error_msg != "" } {
	       msg_box "[trans connectionlost]: [sb get ns error_msg]"
	    } else {
	       msg_box "[trans connectionlost]"
	    }
	 }
	 
	 	 	       
      } else {
  
         set chatid [::MSN::ChatFor $sbn]

         if { $chatid == 0 } {
            status_log "Session closed but was not connected to a chatid\n"
            ::MSN::KillSB $sbn
            return 0
         }

         if { [::MSN::SBFor $chatid] == $sbn } {

            set items [expr {[sb length $sbn users] -1}]
	    status_log "When SB Closed, there are $items users: [sb get $sbn users]\n" white
            #TODO: Check if this works
            #sb set $sbn last_user [sb index $sbn users 0]
            for {set idx $items} {$idx >= 0} {incr idx -1} {
               set user_info [sb index $sbn users $idx]
               sb ldel $sbn users $idx

               amsn::userLeaves [::MSN::ChatFor $sbn] [list $user_info]
            }

         } else {
	    ::MSN::KillSB $sbn
	 }
      }
   }
   #///////////////////////////////////////////////////////////////////////
   
   
   proc AnswerChallenge { item } {
      if { [lindex $item 1] != 0 } {
        status_log "Invalid challenge\n" red
      } else {
        set str [lindex $item 2]Q1P7W2E4J9R8U3S5
        set str [::md5::md5 $str]
        #::MSN::WriteSB ns "QRY" "msmsgs@msnmsgr.com 32"
	#::MSN::WriteSBRaw ns "$str"
	::MSN::WriteSBNoNL ns "QRY" "msmsgs@msnmsgr.com 32\r\n$str"
      }
   }


   proc usersInChat { chatid } {

	set sb_name [SBFor $chatid]

	if { $sb_name == 0 } {
	   status_log "usersInChat: no SB for chat $chatid!!\n" red
	   return [list]
	}

	#status_log "Getting users in chat from $sb_name\n" blue

	set user_list [sb get $sb_name users]

       if { [llength $user_list] } {
	   return $user_list
       } else {
	   return [list [sb get $sb_name last_user]]
       }

   }

   proc typersInChat { chatid } {

      set name [SBFor $chatid]

      if { $name == 0 } {
	status_log "typersInChat: no SB for chat $chatid!!\n" red        
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

   proc getUserInfo { user } {
      
      global list_users list_states list_otherusers user_info

      set wanted_info [list $user $user 0]

      set idx [lsearch $list_users "${user} *"]

      if { "$user" == "[lindex $user_info 3]" } {

         set wanted_info [list $user "[urldecode [lindex $user_info 4]]"  ""]

      } elseif { $idx != -1} {

         set wanted_info [lindex $list_users $idx]

      } else {

         set idx [lsearch $list_otherusers "${user} *"]

         if { $idx != -1} {

            set wanted_info [lindex $list_otherusers $idx]

         }

      }

      set user_login [lindex $wanted_info 0]
      set user_name [lindex $wanted_info 1]
      set state [lindex $wanted_info 2]

      return [list $user_login $user_name $state]

   }

   proc setUserInfo { user_login {user_name ""} {user_state_no ""} } {
      global list_users list_states list_otherusers

      set idx [lsearch $list_users "${user_login} *"]

      if { $idx != -1} {

         set olduserinfo [lindex $list_users $idx]

         if { "$user_name" == "" } {
	    set user_name [lindex $olduserinfo 1]
	 }

         if { "$user_state_no" == "" } {
	    set user_state_no [lindex $olduserinfo 2]
	 }

	 set list_users [lreplace $list_users $idx $idx [list $user_login $user_name $user_state_no]]
	 set list_users [lsort -decreasing -index 2 [lsort -decreasing -index 1 $list_users]]

      } else {

         set idx [lsearch $list_otherusers "${user_login} *"]

	 if {$idx != -1} {
	    #TODO: If user_name=="", delete the user. Use this from BYE
            set list_otherusers [lreplace $list_otherusers $idx $idx [list $user_login $user_name $user_state_no]]
	 } else {
            lappend list_otherusers [list $user_login $user_name $user_state_no]
	 }

      }

   }


   variable sb_num 0

   proc GetNewSB {} {
      variable sb_num
      incr sb_num
      return "sb_${sb_num}"
   }

   proc chatTo { user } {

      global sb_list

      status_log "chatTo: Opening chat to user $user\n" blue
      
      set lowuser [string tolower ${user}]

      if { [chatReady $lowuser] } {
        return $lowuser
      }
      
      set sbn [SBFor $lowuser]

      if { $sbn == 0 } {

           
         set sbn [GetNewSB]

         status_log "chatTo: No SB available to that user, creating new SB: $sbn\n" blue      	 
	 
         sb set $sbn name $sbn
         sb set $sbn sock ""
         sb set $sbn data [list]
         sb set $sbn users [list]
         sb set $sbn typers [list]
         sb set $sbn title [trans chat]
         sb set $sbn lastmsgtime 0

         sb set $sbn last_user $lowuser

         sb set $sbn stat "d"

         AddSBFor $lowuser $sbn
	 lappend sb_list "$sbn"
      }

      status_log "chatTo: Calling cmsn_reconnect SB $sbn\n" blue      
      
      cmsn_reconnect $sbn
      return $lowuser

   }


   proc KillSB { name } {
      global sb_list
      global ${name}_info

      status_log "Killing SB $name\n"

      set idx [lsearch -exact $sb_list $name]

      if {$idx == -1} {
         status_log "tried to destroy unknown SB $name\n" white
         return 0
      }

      catch {
      	 fileevent [sb get $name sock] readable ""
	 fileevent [sb get $name sock] writable ""
         close [sb get $name sock]
      } res

      set sb_list [lreplace $sb_list $idx $idx ]

      unset ${name}_info
   }

   
   proc CleanChat { chatid } {
      global config sb_list

      status_log "Entering CleanChat\n"

      while { [SBFor $chatid] != 0 } {

         set name [SBFor $chatid]
         DelSBFor $chatid ${name}

	  #We leave the switchboard if it exists
         if {[sb get $name stat] != "d"} {
		WriteSBRaw $name "OUT\r\n"
         }

	  #after 60000 "::MSN::KillSB ${name}"

      }

      ::amsn::chatDisabled $chatid
   }
   

   proc leaveChat { chatid } {
      ChatQueue $chatid -1
   }
   

   #///////////////////////////////////////////////////////////////////////////////
   # chatReady (chatid)
   # Returns 1 if the given chat 'chatid' is ready for delivering a message.
   # Returns 0 if it's not ready.
   proc chatReady { chatid } {

         set sbn [SBFor $chatid]

	  if { "$sbn" == "0" } {
	     return 0
	  }

	  if { "[sb get $sbn stat]" != "o" } {
	     return 0
	  }

	  set sb_sock [sb get $sbn sock]

	  if { "$sb_sock" == "" } {
	     return 0
	  }

	  if {[catch {eof $sb_sock} res]} {
	     status_log "chatReady: Error in the EOF command: $res\n" red
	     ::MSN::CloseSB $sbn
	     return 0
	  }

	  if {[eof $sb_sock]} {
	    status_log "Closing from chatready\n"
            ::MSN::CloseSB $sbn
	    return 0
	  }

         if {[sb length $sbn users]} {
	     return 1
         }

	  return 0
   }
   #///////////////////////////////////////////////////////////////////////////////



   proc SBFor { chatid } {

      variable sb_chatid

      if { [info exists sb_chatid($chatid)] } {

	  if { [llength $sb_chatid($chatid)] > 0 } {

	     #Try to find a connected SB
	     foreach sbn $sb_chatid($chatid) {

	        if {![catch {sb get $sbn stat} res ]} {
	           if { "[sb get $sbn stat]" == "o" } {

	              set sb_sock [sb get $sbn sock]

	              if { "$sb_sock" != "" } {
                         #status_log "SBFor: Returned $sbn as SB for $chatid\n" blue
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
           
      status_log "SBFor: Returned 0 as SB for $chatid\n" blue
      return 0

   }


   proc ChatFor { sb_name } {
   
      variable chatid_sb

      if {[info exists chatid_sb($sb_name)]} {
         #status_log "ChatFor: Returned $chatid_sb($sb_name) as chat for $sb_name\n" blue                   
         return $chatid_sb($sb_name)
      }

      status_log "ChatFor: Returned 0 as chat for $sb_name\n" blue                         
      return 0
   }

   
   proc AddSBFor { chatid sb_name} {
          variable sb_chatid
	  variable chatid_sb

	  if {![info exists sb_chatid($chatid)]} {
	     set sb_chatid($chatid) [list]
	  }

	  set index [lsearch $sb_chatid($chatid) $sb_name]
	  
          status_log "AddSBFor: Adding SB $sb_name to chat $chatid\n" blue
          status_log "AddSBFor: sb_chatid ($chatid) was $sb_chatid($chatid)\n" blue
	  
	  if { $index == -1 } {
	     #Should we insert at the beggining? Newer SB's are probably better
	     set sb_chatid($chatid) [linsert $sb_chatid($chatid) 0 $sb_name]
	     #lappend sb_chatid($chatid) $sb_name
	  } else {
	     #Move SB to the begginning of the list
	     status_log "AddSBFor: sb $sb_name already in $chatid. Moving to preferred SB\n" blue
	     set sb_chatid($chatid) [lreplace $sb_chatid($chatid) $index $index]
	     set sb_chatid($chatid) [linsert $sb_chatid($chatid) 0 $sb_name]
	  }

         set chatid_sb($sb_name) $chatid

	 status_log "AddSBFor: sb_chatid ($chatid) is now $sb_chatid($chatid)\n" blue
   }

   proc DelSBFor { chatid sb_name} {
      variable sb_chatid
      variable chatid_sb

      status_log "DelSBFor: Deleting SB $sb_name from chat $chatid\n" blue

      if {![info exists sb_chatid($chatid)]} {
         status_log "DelSBFor: sb_chatid($chatid) doesn't exist\n" red
	 return 0
      }
      status_log "DelSBFor: sb_chatid ($chatid) was $sb_chatid($chatid)\n" blue


      set index [lsearch $sb_chatid($chatid) $sb_name]

      if { $index == -1 } {
         status_log "DelSBFor: SB $sb_name is not in sb_chatid($chatid)\n" red
	 return 0
      }

      set sb_chatid($chatid) [lreplace $sb_chatid($chatid) $index $index]
      status_log "DelSBFor: sb_chatid ($chatid) is now $sb_chatid($chatid)\n" blue

      if {[llength $sb_chatid($chatid)] == 0 } {
        unset sb_chatid($chatid)
      }

      unset chatid_sb($sb_name)

   }


   proc inviteUser { chatid user } {

      set sb_name [::MSN::SBFor $chatid]

      if { $sb_name != 0 } {
         cmsn_invite_user $sb_name $user
      }


   }


   proc ClearQueue {chatid } {

      variable chat_queues

      #TODO: We should NAK every message in the queue, must modify the queue format
      #to save the message ack ID

      if {![info exists chat_queues($chatid)]} {
         return 0
      }

      unset chat_queues($chatid)

   }

   proc ProcessQueue { chatid {count 0} } {

      variable chat_queues

      if {![info exists chat_queues($chatid)]} {
         return 0
      }

      if {[llength $chat_queues($chatid)] == 0} {
         unset chat_queues($chatid)
         return
      }

      if { $count >= 15 } {
         #TODO: Should we clean queue or anything?
         set chat_queues($chatid) [lreplace $chat_queues($chatid) 0 0]         
	 ProcessQueue $chatid 14 
	 return
      }

      set command [lindex $chat_queues($chatid) 0]
      
      if { $command == -1 } {
         status_log "ProcessQueue: processing leaveChat in queue\n" blue
         set chat_queues($chatid) [lreplace $chat_queues($chatid) 0 0]
	 CleanChat $chatid
	 ProcessQueue $chatid
	 return
      }

      if {[chatReady $chatid]} {

         set chat_queues($chatid) [lreplace $chat_queues($chatid) 0 0]
         eval $command
         ProcessQueue $chatid

      } else {

         chatTo $chatid
         after 3000 "::MSN::ProcessQueue $chatid [expr {$count + 1}]"

      }

   }



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
   proc SendChatMsg { chatid txt ackid } {
      global config user_info msgacks

      set sbn [SBFor $chatid]

      #In call to messageTo, the chat has to be ready, or we have problems
      if { $sbn == 0 } {
         ::amsn::nackMessage $ackid
	  return 0
      }

      if {![chatReady $chatid]} {
         status_log "chat NOT ready in ::MSN::SendChatMsg\n"
         ::amsn::nackMessage $ackid
	 return 0
      }

      status_log "SendChatMsg:: Sending message to chat $chatid using SB $sbn\n" blue

      #set sock [sb get $sbn sock]

      set txt_send [encoding convertto utf-8 [stringmap {"\n" "\r\n"} $txt]]

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

      set msg "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\n"
      set msg "${msg}X-MMS-IM-Format: FN=[urlencode $fontfamily]; EF=$style; CO=$color; CS=0; PF=22\r\n\r\n"
      set msg "$msg$txt_send"
      set msg_len [string length $msg]

      #WriteSB $sbn "MSG" "A $msg_len"
      #WriteSBRaw $sbn "$msg"
      WriteSBNoNL $sbn "MSG" "A $msg_len\r\n$msg"

      #Setting trid - ackid correspondence
      set msgacks($::MSN::trid) $ackid

   }

   #///////////////////////////////////////////////////////////////////////////////
   # messageTo (chatid,txt,ackid)
   # Just queue the message send
   proc messageTo { chatid txt ackid } {
      if {![chatReady $chatid] && [lindex [::MSN::getUserInfo [lindex [usersInChat $chatid] 0]] 2] == 8 } {
         status_log "chat NOT ready in ::MSN::SendChatMsg\n"
         ::amsn::nackMessage $ackid
	 chatTo $chatid
	 return 0
      }
      ChatQueue $chatid [list ::MSN::SendChatMsg $chatid "$txt" $ackid]
   }
   #///////////////////////////////////////////////////////////////////////////////


   #///////////////////////////////////////////////////////////////////////////////
   #Parses "name: value\nname: value\n..." headers and returns the "value" for "name"
   #///////////////////////////////////////////////////////////////////////////////
   proc GetHeaderValue { bodywithr name } {

      set body "\n[stringmap {"\r" ""} $bodywithr]"
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


}

proc read_sb_sock {sbn} {

   set sb_sock [sb get $sbn sock]
   
   if { $sbn == "ns" } {
     set debugcolor "nsrecv"
   } else {
     set debugcolor "sbrecv"
   }
   
   if {[catch {eof $sb_sock} res]} {

      status_log "read_sb_sock: Error reading EOF in read_sb_sock: $res\n" red
      ::MSN::CloseSB $sbn

   } elseif {[eof $sb_sock]} {

      degt_protocol "<-$sbn CLOSED" $debugcolor
      ::MSN::CloseSB $sbn

   } else {

      set tmp_data "ERROR READING SB !!!"
      if {[catch {gets $sb_sock tmp_data} res]} {

         degt_protocol "<-$sbn Read Error, Closing: $res" error
         ::MSN::CloseSB $sbn

      } elseif  { "$tmp_data" == "" } {
      
         update idletasks
	 
      } else {

         sb append $sbn data $tmp_data

         degt_protocol "<-$sbn $tmp_data\\n" $debugcolor

         if {[string range $tmp_data 0 2] == "MSG"} {
            set recv [split $tmp_data]
	    #TODO: Do this non-blocking
	    fconfigure $sb_sock -blocking 1
	    set msg_data [read $sb_sock [lindex $recv 3]]
	    fconfigure $sb_sock -blocking 0

            degt_protocol "Message Contents:\n$msg_data" msgcontents

	    sb append $sbn data $msg_data
         }
      }
   }
   
   if { $sbn == "ns" } {
     proc_ns
   } else {
     proc_sb
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
         lappend sb_data $value
      }
      index {
         return [lindex $sb_data $value]
      }
      ldel {
         set sb_data [lreplace $sb_data $value $value]
      }
      length {
	if {![info exists sb_data]} {
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


proc proc_sb {} {
   global sb_list

   after cancel proc_sb
   
   foreach sbn $sb_list {
      while {[sb length $sbn data]} {
         set item [split [sb index $sbn data 0]]
         sb ldel $sbn data 0
         set result [cmsn_sb_handler $sbn $item]
         if {$result == 0} {
	    
         } else {
            status_log "proc_sb: problem processing SB data!\n" red
	    continue
         }

      }
   }

   after 250 proc_sb
   return 1
}

proc proc_ns {} {

   after cancel proc_ns

   while {[sb length ns data]} {

      set item [split [sb index ns data 0]]
      sb ldel ns data 0

      set result [cmsn_ns_handler $item]
      if {$result == 0} {
	 
      } else {
         status_log "problem processing NS data!\n" red
      }

   }

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
   set body [stringmap {"\r" ""} $body]

   set head [stringmap {"\r" ""} $head]
   set head_lines [split $head "\n"]
   foreach line $head_lines {
      set colpos [string first ":" $line]
      set attribute [string tolower [string range $line 0 [expr {$colpos-1}]]]
      set value [string range $line [expr {$colpos+2}] [string length $line]]
      array set headers [list $attribute $value]
   }

}

proc cmsn_sb_msg {sb_name recv} {
   #TODO: A little cleaning on all this
   global filetoreceive files_dir automessage automsgsent

   set msg [sb index $sb_name data 0]
   sb ldel $sb_name data 0
   
   array set headers {}
   set body ""
   cmsn_msg_parse $msg headers body

   set content [lindex [array get headers content-type] 1]

   set typer [string tolower [lindex $recv 1]]
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
	  status_log "sb_msg: Trying to change chatid from $chatid to $desiredchatid\n"

         set newchatid [::amsn::chatChange $chatid $desiredchatid]
         if { "$newchatid" != "$desiredchatid" } {
            #The GUI doesn't accept the change, as there's another window for that chatid
            status_log "sb_msg: change NOT accepted\n"
         } else {
            #The GUI accepts the change, so let's change
            status_log "sb_msg: change accepted\n"
           ::MSN::DelSBFor $chatid $sb_name
	     set chatid $desiredchatid
            ::MSN::AddSBFor $chatid $sb_name
         }

      }
   } else {
   
      status_log "Error, no chatid in cmsn_sb_msg, please check this!!\n" red
      set chatid $desiredchatid
      ::MSN::AddSBFor $chatid $sb_name
      
   }


   #after cancel "catch \{set idx [sb search $sb_name typers $typer];sb ldel $sb_name typers \$idx;cmsn_show_typers $sb_name\} res"
   #TODO: better use afterID
   after cancel "catch \{set idx [sb search $sb_name typers $typer];sb ldel $sb_name typers \$idx;::amsn::updateTypers $chatid\} res"

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
      ::amsn::messageFrom $chatid $typer "$body" user [list $fontfamily $style $fontcolor]
      sb set $sb_name lastmsgtime [clock format [clock seconds] -format %H:%M:%S]
      
      # Send automessage once to each user
      	if { [info exists automessage] } {
	if { $automessage != "-1" } {
		if { [info exists automsgsent($typer)] } {
			if { $automsgsent($typer) != 1 } {
				::amsn::MessageSend [::amsn::WindowFor $chatid] 0 [lindex $automessage 3]
				set automsgsent($typer) 1
			}
		} else {
				::amsn::MessageSend [::amsn::WindowFor $chatid] 0 [lindex $automessage 3]
				set automsgsent($typer) 1
			}
	}
	}


      set idx [sb search $sb_name typers $typer]
      sb ldel $sb_name typers $idx
      ::amsn::updateTypers $chatid


   } elseif {[string range $content 0 19] == "text/x-msmsgscontrol"} {

      if {[llength $typer]} {
	 set idx [sb search $sb_name typers $typer]
	 if {$idx == -1} {
            sb append $sb_name typers $typer
	 }

	 #after 8000 "catch \{set idx [sb search $sb_name typers $typer];sb ldel $sb_name typers \$idx;cmsn_show_typers $sb_name\} res"
	 #We have to catch it as the sb can be closed before the 8 seconds to delete the typing user
	 after 8000 "catch \{set idx [sb search $sb_name typers $typer];sb ldel $sb_name typers \$idx;::amsn::updateTypers $chatid\} res"
        ::amsn::updateTypers $chatid

      }

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
	    status_log "$body\n" black
           
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
      
   } else {
      status_log "=== UNKNOWN MSG ===\n$msg\n" red
   }

}

proc CALReceived {sb_name user item} {
   status_log "CALReceived:  $sb_name $user $item\n" white
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
	  #::MSN::CleanChat $chatid
          ::amsn::chatStatus $chatid "$user: [trans usernotonline]\n" miniwarning
	  #msg_box "[trans usernotonline]"
	  user_not_blocked $user
          return 0
      }   
   }
   cmsn_sb_handler $sb_name [encoding convertto utf-8 $item]
}

proc cmsn_sb_handler {sb_name item} {
   global list_cmdhnd msgacks


   set item [encoding convertfrom utf-8 $item]

   set ret_trid [lindex $item 1]
   set idx [lsearch $list_cmdhnd "$ret_trid *"]
   if {$idx != -1} {		;# Command has a handler associated!
      status_log "evaluating handler for $ret_trid\n"
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
	status_log "Got ANS reply in $sb_name\n" green
	status_log "There are [sb length $sb_name users] Users: [sb get $sb_name users]\n" green
	if { [sb length $sb_name users] == 1 } {
	   set chatid [sb index $sb_name users 0]
	} else {
	   set chatid $sb_name
	}
        ::MSN::AddSBFor $chatid $sb_name

        foreach usr_login [sb get $sb_name users] {
           ::amsn::userJoins $chatid $usr_login
	}

	 #status_log "$sb_name: [join $item]\n" green
	 return 0
      }
      NAK {
         if { ! [info exists msgacks($ret_trid)]} {
	    return 0
	 }
         set ackid $msgacks($ret_trid)
	  ::amsn::nackMessage $ackid
	  unset msgacks($ret_trid)
	  return 0
      }
      ACK {
         set ackid $msgacks($ret_trid)
	  ::amsn::ackMessage $ackid
	  unset msgacks($ret_trid)
	  return 0
      }
      208 {
         status_log "invalid user name for chat\n"
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

      ::MSN::WriteSB $name "CAL" $user "CALReceived $name $user"

   } else {

      status_log "cmsn_invite_user: Can't invite user to non connected SB!!\n" red

   }

}


proc cmsn_rng {recv} {

   global config sb_list

   set emaill [string tolower [lindex $recv 5]]

   set sbn [::MSN::GetNewSB]

   lappend sb_list "$sbn"

   #Init SB properly
   sb set $sbn name $sbn
   sb set $sbn sock ""
   sb set $sbn stat ""
   sb set $sbn data [list]
   sb set $sbn users [list]
   sb set $sbn typers [list]
   sb set $sbn lastmsgtime 0
   sb set $sbn serv [split [lindex $recv 2] ":"]
   sb set $sbn connected "cmsn_conn_ans $sbn"
   sb set $sbn auth_cmd "ANS"
   sb set $sbn auth_param "$config(login) [lindex $recv 4] [lindex $recv 1]"

   status_log "cmsn_rng: SB $sbn, ANS1 answering [lindex $recv 5]\n" green
   status_log "[trans chatack] [lindex $recv 5]...\n" green

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
          status_log "Error: Not allowed when offline\n" red
	  set chatid [::MSN::ChatFor $sbn]
          ::MSN::ClearQueue $chatid
          ::MSN::CleanChat $chatid
          ::amsn::chatStatus $chatid "[trans needonline]\n" miniwarning
          #msg_box "[trans needonline]"
          return 1
   }

   if {[lindex $recv 4] != "CKI"} {
      status_log "$sbn: Unknown SP requested!\n" red
      return 1
   }
   
   status_log "cmsn_open_sb: Opening SB $sbn\n" green

   sb set $sbn serv [split [lindex $recv 3] ":"]
   sb set $sbn connected "cmsn_conn_sb $sbn"
   sb set $sbn auth_cmd "USR"
   sb set $sbn auth_param "$config(login) [lindex $recv 5]"


   ::amsn::chatStatus [::MSN::ChatFor $sbn] "[trans sbcon]...\n" miniinfo ready
   cmsn_socket $sbn
   return 0
}

proc cmsn_conn_sb {name} {

   status_log "cmsn_conn_sb $name (sock is [sb get $name sock])\n" green
   catch { fileevent [sb get $name sock] writable "" } res

   #Reset timeout timer
   sb set $name time [clock seconds]

   sb set $name stat "a"

   set cmd [sb get $name auth_cmd]
   set param [sb get $name auth_param]

   status_log "Here before writeSB\n" green
   ::MSN::WriteSB $name $cmd $param "cmsn_connected_sb $name"
   status_log "Here AFTER writeSB\n" green
   ::amsn::chatStatus [::MSN::ChatFor $name] "[trans ident]...\n" miniinfo ready
   status_log "Here exiting cmsn_conn_sb\n" green   
}

proc cmsn_conn_ans {name} {



   status_log "cmsn_conn_ans $name\n" green
   catch {fileevent [sb get $name sock] writable {}} res

   sb set $name time [clock seconds]
   sb set $name stat "a"


   set cmd [sb get $name auth_cmd]; set param [sb get $name auth_param]
   ::MSN::WriteSB $name $cmd $param
   #cmsn_msgwin_top $name "[trans ident]..."
   status_log "cmsn_conn_ans: Authenticating in $name...\n" green

}


proc cmsn_connected_sb {name recv} {

   status_log "cmsn_connected_sb $name\n" green
   sb set $name time [clock seconds]
   sb set $name stat "i"

   if {[sb exists $name invite]} {

      cmsn_invite_user $name [sb get $name invite]

      ::amsn::chatStatus [::MSN::ChatFor $name] \
         "[trans willjoin [sb get $name invite]]...\n" miniinfo ready

   } else {

      status_log "cmsn_connected_sb: got sb stat=i but no one to invite!!!\n" red

   }

}

#SB stat values:
#  "d" - Disconnected, the SB is not connected to the server
#  "c" - The SB is trying to get a socket to the server.
#  "cw" - "Connect wait" The SB is trying to connect to the server.
#  "pw" - "Proxy wait" The SB is trying to connect to the server using a proxy.
#  "a" - Authenticating. The SB is authenticating to the server
#  "i" - Inviting first person to the chat. Succesive invitations will be while in "o" status
#  "o" - Opened. The SB is connected and ready for chat
#  "n" - Nobody. The SB is connected but there's nobody at the conversation


proc cmsn_reconnect { name } {

   if {[sb get $name stat] == "n"} {

      
      status_log "cmsn_reconnect: stat = n , SB= $name, user=[sb get $name last_user]\n" green
      sb set $name time [clock seconds]
      sb set $name stat "i"

      cmsn_invite_user $name [sb get $name last_user]

      ::amsn::chatStatus [::MSN::ChatFor $name] \
         "[trans willjoin [sb get $name last_user]]..." miniinfo ready

   } elseif {[sb get $name stat] == "d"} {

      #status_log "--Calling reconnect with d tag\n"

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



      ::MSN::WriteSB ns "XFR" "SB" "cmsn_open_sb $name"

      ::amsn::chatStatus [::MSN::ChatFor $name] "[trans chatreq]..." miniinfo ready

   } elseif {[sb get $name stat] == "i"} {

      status_log "cmsn_reconnect: stat = i , SB= $name\n" green   
   
      if { [expr {[clock seconds] - [sb get $name time]}] > 15 } {
         status_log "--cmsn_reconnect: called again while inviting timeouted\n" red
	 catch { fileevent [sb get $name sock] readable "" } res
	 catch { fileevent [sb get $name sock] writable "" } res
	 catch {close [sb get $name sock]} res
	 sb set $name stat "d"
	 cmsn_reconnect $name
      }

   } elseif {[sb get $name stat] == "c"} {

      status_log "cmsn_reconnect: stat = c , SB= $name\n" green      
   
      if { [expr {[clock seconds] - [sb get $name time]}] > 10 } {
         status_log "cmsn_reconnect: called again while reconnect timeouted\n" red
	 catch { fileevent [sb get $name sock] readable "" } res
	 catch { fileevent [sb get $name sock] writable "" } res
	 catch {close [sb get $name sock]} res
	 sb set $name stat "d"
	 cmsn_reconnect $name
      }

   } elseif {([sb get $name stat] == "cw") \
      || ([sb get $name stat] == "pw") \
      || ([sb get $name stat] == "a")} {
      
      status_log "cmsn_reconnect: stat =[sb get $name stat] , SB= $name\n" green         

      if { [expr {[clock seconds] - [sb get $name time]}] > 10 } {
         status_log "cmsn_reconnect: called again while authentication timeouted\n" red
	 catch { fileevent [sb get $name sock] readable "" } res
	 catch { fileevent [sb get $name sock] writable "" } res
	 catch {close [sb get $name sock]} res
	 sb set $name stat "d"
	 cmsn_reconnect $name
      }

   } else {

       status_log "cmsn_reconnect: sb stat is [sb get $name stat]\n" red

   }

}





#///////////////////////////////////////////////////////////////////////
proc cmsn_update_users {sb_name recv} {
   global config 


   switch [lindex $recv 0] {

      BYE {

         set chatid [::MSN::ChatFor $sb_name]

	 	 
         if {[sb get $sb_name stat] != "d"} {

	    set leaves [sb search $sb_name users "[lindex $recv 1]"]
            sb set $sb_name last_user [sb index $sb_name users $leaves]
            sb ldel $sb_name users $leaves

            set usr_login [sb index $sb_name users 0]

            if {[sb length $sb_name users] == 1} {
               #We were a conference! try to become a private

               set desiredchatid $usr_login

               set newchatid [::amsn::chatChange $chatid $desiredchatid]

               if { "$newchatid" != "$desiredchatid" } {
                  #The GUI doesn't accept the change, as there's another window for that chatid
                  status_log "sb_msg: change NOT accepted from $chatid to $desiredchatid\n"

               } else {
                  #The GUI accepts the change, so let's change
                  status_log "sb_msg: change accepted from $chatid to $desiredchatid\n"
                  ::MSN::DelSBFor $chatid $sb_name
                  ::MSN::AddSBFor $newchatid $sb_name                  
		  set chatid $newchatid
               }

            } elseif {[sb length $sb_name users] == 0 } {
               sb set $sb_name stat "n"
            }

         } else {
            status_log "BYE but sb is in \"d\" state, so \
            the close event has been catch before the BYE...\n"
         }

	 #Another option for the condition:
	 # "$chatid" != "[lindex $recv 1]" || ![MSN::chatReady $chatid]
         if { [::MSN::SBFor $chatid] == $sb_name } {
            ::amsn::userLeaves $chatid [list [lindex $recv 1]]
         }

      }

      IRO {

         #You get an IRO message when you're invited to some chat. The chatid name won't be known
         #until the first message comes
         sb set $sb_name stat "o"

	  set usr_login [string tolower [lindex $recv 4]]
	  set usr_name [urldecode [lindex $recv 5]]

	  #sb append $sb_name users [list $usr_login $usr_name [lindex [::MSN::getUserInfo $usr_login] 2]]
	  sb append $sb_name users [list $usr_login]

	  ::MSN::setUserInfo $usr_login $usr_name

          sb set $sb_name last_user $usr_login

      }

      JOI {
         sb set $sb_name stat "o"

	  set usr_login [string tolower [lindex $recv 1]]
	  set usr_name [urldecode [lindex $recv 2]]

	  #sb append $sb_name users [list $usr_login $usr_name [lindex [::MSN::getUserInfo $usr_login] 2]]
	  sb append $sb_name users [list $usr_login]

	  ::MSN::setUserInfo $usr_login $usr_name


	  if { [sb length $sb_name users] == 1 } {

            sb set $sb_name last_user $usr_login

             set chatid $usr_login


	  } else {

	     #More than 1 user, change into conference

	     #Procedure to change chatid-sb correspondences
	     set oldchatid [::MSN::ChatFor $sb_name]

	     if { $oldchatid == 0 } {
	        status_log "cmsn_update_users: JOI - VERY BAD ERROR, oldchatid = 0. CHECK!!\n" error
		return 0
	     }

	     set chatid $sb_name

	     #Remove old chatid correspondence
	     ::MSN::DelSBFor $oldchatid $sb_name
	     ::MSN::AddSBFor $chatid $sb_name

	     status_log "JOI - Another user joins, Now I'm chatid $chatid (I was $oldchatid)\n"
	     ::amsn::chatChange $oldchatid $chatid

	  }

	  #Don't put it in status if we're not the preferred SB.
          #It can happen that you invite a user to your sb,
          #but just in that moment the user invites you,
          #so you will connect to its sb and be able to chat, but after
          #a while the user will join your old invitation,
          #and get a fake "user joins" message if we don't check it
          if {[::MSN::SBFor $chatid] == $sb_name} {
             ::amsn::userJoins $chatid $usr_login
          }

      }
   }

}
#///////////////////////////////////////////////////////////////////////



proc cmsn_change_state {recv} {
   global list_fl list_users config

   if {[lindex $recv 0] == "FLN"} {
      set user [lindex $recv 1]
      set user_name ""
      set substate "FLN"
   } else {
      if {[lindex $recv 0] == "ILN"} {
         set user [lindex $recv 3]
         set user_name [urldecode [lindex $recv 4]]
         set substate [lindex $recv 2]
      } else {
         set user [lindex $recv 2]
         set user_name [urldecode [lindex $recv 3]]
         set substate [lindex $recv 1]
      }
   }

   set idx [lsearch $list_users "$user *"]
   if {$idx != -1} {
      global list_users list_states alarms

      set user_data [lindex $list_users $idx]
      if {$user_name == ""} {
         set user_name [urldecode [lindex $user_data 1]]
      }

      if {$user_name != [lindex $user_data 1]} {
      	#Nick differs from the one on our list, so change it
	#in the server list too
	::MSN::changeName $user $user_name
      }


      if {[lindex $user_data 2] < 7} {		;# User was online before


	 #TODO: Is this used for anything???
         #set oldusername [string map {\\ \\\\ \[ \\\[ * \\* ? \\?} \
	 #  [urldecode [lindex $user_data 1]]]


      } elseif {[lindex $recv 0] == "NLN"} {	;# User was offline, now online

	  user_not_blocked "$user"

	 if { $config(notifyonline) == 1 } {
	 	::amsn::notifyAdd "$user_name\n[trans logsin]." "::amsn::chatUser $user" online
	 }
	 
         if { ([info exists alarms([lindex $recv 2])]) && ($alarms([lindex $recv 2]) == 1) } {
             run_alarm [lindex $recv 2] [lindex $recv 3]        ;# Run Alarm using EMAIL ADDRESS (Burger)
         }
      }

      if {$substate != "FLN"} {
#      	 status_log "Inserting <$user_name> in menu\n" white
#         .main_menu.msg insert 0 command -label "$user_name <$user>" \
#            -command "::amsn::chatUser $user"
      } else {
	  ::MSN::chatTo "$user"	  
      }

      set state_no [lsearch $list_states "$substate *"]

      #TODO: Change this with ::MSN::setUserInfo
      set list_users [lreplace $list_users $idx $idx [list $user $user_name $state_no]]
      set list_users [lsort -decreasing -index 2 [lsort -decreasing -index 1 $list_users]]

      cmsn_draw_online
   } else {
      status_log "PANIC!\n" red
   }

}

proc cmsn_ns_handler {item} {
   global list_cmdhnd password config

   set item [encoding convertfrom utf-8 $item]
   set item [stringmap {\r ""} $item]

   set ret_trid [lindex $item 1]
   set idx [lsearch $list_cmdhnd "$ret_trid *"]
   if {$idx != -1} {		;# Command has a handler associated!
      status_log "evaluating handler for $ret_trid\n"
      
      set command "[lindex [lindex $list_cmdhnd $idx] 1] {$item}"
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
      USR {
	 return [cmsn_auth $item]
      }
      XFR {
	 if {[lindex $item 2] == "NS"} {
	    set tmp_ns [split [lindex $item 3] ":"]
            sb set ns serv $tmp_ns
            status_log "got a NS transfer!\n"
            status_log "reconnecting to [lindex $tmp_ns 0]\n"
            cmsn_ns_connect $config(login) $password nosigin
            return 0
	 } else {
            status_log "got an unknown transfer!!\n" red
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
	     if { [lindex $item 2] == "FL"} {
	       set contact [lindex $item 4]	;# Email address
	       set addtrid [lindex $item 3]	;# Transaction ID
	       msg_box "[trans contactadded]\n$contact"
	   }

	 set curr_list [lindex $item 2]
	 if { ($curr_list == "FL") } {
	     status_log "PRUEBA1: $item\n" blue
	     ::abook::setContact [lindex $item 4] FL [lindex $item 6]
	     ::abook::setContact [lindex $item 4] nick [lindex $item 5]
	 }
         cmsn_listupdate $item
         return 0
      }
      LST {
	 # New entry in address book setContact(email,FL,groupID)
	 # NOTE: IF a user belongs to several groups, the group part
	 #       of this packet will have the group ids separated
	 #       by commas:  0,5  (group 0 & 5).
	 set curr_list [lindex $item 2]
	 # It could be that it is in the FL but not in RL or viceversa.
	 # Everything that is in AL or BL is in either of the above.
	 # Only FL contains the group membership though...
	 if { ($curr_list == "FL") } {
	     ::abook::setContact [lindex $item 6] FL [lindex $item 8]
	     ::abook::setContact [lindex $item 6] nick [lindex $item 7]
	 }
         cmsn_listupdate $item
         return 0
      }
      REM {
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
	 global user_stat
    	    if { $user_stat != [lindex $item 2] } {
	       set user_stat [lindex $item 2]
	       cmsn_draw_online

	       #Alert dock of status change
#	       send_dock [lindex $item 2]
	       send_dock "STATUS" [lindex $item 2]
	     }
         return 0
      }
      GTC -
      SYN {
	 return 0
      }
      BLP {
	  change_BLP_settings "$item"	  
      }
      CHL {
     	  status_log "Challenge received\n" red
	  ::MSN::AnswerChallenge $item
	  return 0
      }
      QRY {
          status_log "Challenge accepted\n" green
	  return 0
      }
      BPR {
	 # Update entry in address book setContact(email,PH*/M*,phone/setting)
	 ::abook::setContact [lindex $item 2] [lindex $item 3] [lindex $item 4] 
	 return 0
      }
      PRP {
	 ::abook::setPersonal [lindex $item 3] [lindex $item 4]
	return 0
      }
      LSG {
      	status_log "$item\n" blue
	::groups::Set [lindex $item 5] [lindex $item 6]
	return 0
      }
      REG {	# Rename Group
      	status_log "$item\n" blue
	::groups::RenameCB [lrange $item 0 5]
	return 0
      }
      ADG {	# Add Group
      	status_log "$item\n" blue
	::groups::AddCB [lrange $item 0 5]
   	cmsn_draw_online
	return 0
      }
      RMG {	# Remove Group
      	status_log "$item\n" blue
	::groups::DeleteCB [lrange $item 0 5]
   	cmsn_draw_online
	return 0
      }
      OUT {	
      	if { [lindex $item 1] == "OTH"} {
	  ::MSN::logout	  
	  msg_box "[trans loggedotherlocation]"
	  return 0
	} else {
	  ::MSN::logout	  
	  msg_box "[trans servergoingdown]"
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
          return 0
      }
      209 {
          status_log "Warning: Invalid fusername $item\n" red
	  msg_box "[trans invalidusername]"
          return 0
      }
      210 {
          status_log "Warning: User list full $item\n" red
          return 0
      }
      216 {
          #status_log "Keeping connection alive\n" blue
          return 0
      }
      600 {
	  return 0
      }
      601 {
	  return 0
      }
      500 {
	  ::MSN::logout          
	  status_log "Error:Internal server error\n" red
	  ::amsn::errorMsg "[trans internalerror]"
          return 0
      }
      911 {
	  set password ""      
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
   
   if { [lindex $recv 1] != "Hotmail" && [lindex $recv 2] != "Hotmail"} {
      status_log "NS MSG From Unknown source ([lindex $recv 1] [lindex $recv 2]):\n$msg_data\n" red
      return
   }
   
   # Demographic Information about subscriber/user. Can be used
   # for a variety of things.
   set content [::MSN::GetHeaderValue $msg_data Content-Type]
   if {[string range $content 0 19] == "text/x-msmsgsprofile"} {
      status_log "Getting demographic and auth information\n"
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
      ::abook::setDemographics d
   } else {
      hotmail_procmsg $msg_data	 
   }
}


proc cmsn_listdel {recv} {
   ::MSN::WriteSB ns "LST" "[lindex $recv 2]"
}

proc cmsn_auth {{recv ""}} {
   global config


   switch [sb get ns stat] {
      c {
#New version of protocol
         ::MSN::WriteSB ns "VER" "MSNP7 MSNP6 MSNP5 MSNP4 CVR0"
	 sb set ns stat "v"
	 return 0
      }
      v {
         if {[lindex $recv 0] != "VER"} {
	    status_log "was expecting VER reply but got a [lindex $recv 0]\n" red
	    return 1
	 } elseif {[lsearch -exact $recv "CVR0"] != -1} {
            ::MSN::WriteSB ns "INF" ""
	    sb set ns stat "i"
	    return 0
	 } else {
	    status_log "could not negotiate protocol!\n" red
	    return 1
	 }
      }
      i {
         if {[lindex $recv 0] != "INF"} {
	    status_log "was expecting INF reply but got a [lindex $recv 0]\n" red
            return 1
         } elseif {[lsearch -exact $recv "MD5"] != -1} {
            global config
            ::MSN::WriteSB ns "USR" "MD5 I $config(login)"
            sb set ns stat "u"
            return 0
         } else {
            status_log "could not negotiate authentication method!\n" red
            return 1
         }
      }
      u {
         if {([lindex $recv 0] != "USR") || \
            ([lindex $recv 2] != "MD5") || \
            ([lindex $recv 3] != "S")} {
            status_log "was expecting USR x MD5 S xxxxx but got something else!\n" red
            return 1
         }
         ::MSN::WriteSB ns "USR" "MD5 S [get_password 'MD5' [lindex $recv 4]]"
         sb set ns stat "us"
         return 0
      }
      us {
         if {[lindex $recv 0] != "USR"} {
            status_log "was expecting USR reply but got a [lindex $recv 0]\n" red
            return 1
         }
         if {[lindex $recv 2] != "OK"} {
            status_log "error authenticating with server!\n" red
            return 1
         }
         global user_info
         set user_info $recv
         sb set ns stat "o"
	 save_config						;# CONFIG
	 ::MSN::WriteSB ns "SYN" "0"

         if {$config(startoffline)} {
            ::MSN::changeStatus "HDN"
 	    send_dock "STATUS" "HDN"	    
         } else {
            ::MSN::changeStatus "NLN"
	    send_dock "STATUS" "NLN"         
	 }
	       #Alert dock of status change
         #      send_dock "NLN"
	 send_dock "MAIL" 0

         #Log out
         .main_menu.file entryconfigure 2 -state normal
         #My status
         .main_menu.file entryconfigure 3 -state normal
         #Add a contact
         .main_menu.tools entryconfigure 0 -state normal
         .main_menu.tools entryconfigure 1 -state normal
         .main_menu.tools entryconfigure 4 -state normal
         #Added by Trevor Feeney
	 #Enables the Group Order Menu
	 .main_menu.tools entryconfigure 5 -state normal
 
         #Change nick
	 configureMenuEntry .main_menu.actions "[trans changenick]..." normal
	 configureMenuEntry .options "[trans changenick]..." normal

	 configureMenuEntry .main_menu.actions "[trans sendmail]..." normal
	 configureMenuEntry .main_menu.actions "[trans sendmsg]..." normal
	 
	 #configureMenuEntry .main_menu.actions "[trans verifyblocked]..." normal
	 #configureMenuEntry .main_menu.actions "[trans showblockedlist]..." normal


	 configureMenuEntry .main_menu.file "[trans savecontacts]..." normal

         return 0
      }
   }
   return -1
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


proc fileDialog2 {w ent operation basename} {
    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    set types {{"All files"		*} }

    if {$operation == "open"} {
	set file [tk_getOpenFile -filetypes $types -parent $w]
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
   if { [string range $command 0 0] == "/"} {
     #puts -nonewline [sb get ns sock] "[string range $command 1 [string length $command]]\r\n"
     ::MSN::WriteSBRaw ns "[string range $command 1 [string length $command]]\r\n"
   } elseif {$command != ""} {
     if {[catch {eval $command} res]} {
        msg_box "$res"
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

proc cmsn_socket {name} {

   global config

   #This is the default read handler, if not changed by proxy
   sb set $name readable "read_sb_sock $name"
   
   #read_proc not yet used, maybe in the future (by Alvaro)
   #sb set $name read_proc "::MSN::DirectRead $name"
   sb set $name write_proc "::MSN::DirectWrite $name"
   
   if {$config(connectiontype) == "direct" } {
   
      set tmp_serv [lindex [sb get $name serv] 0]
      set tmp_port [lindex [sb get $name serv] 1]
      set readable_handler "read_sb_sock $name"
      set read_procedure "::MSN::ReadSB"
      set next [sb get $name connected]  
       
   } elseif {$config(connectiontype) == "http"} { 
      
      status_log "Setting up http connection\n"
      set tmp_serv "gateway.messenger.hotmail.com"
      set tmp_port 80
      
      ::Proxy::Init "$tmp_serv:$tmp_port" "http"
      
      ::Proxy::OnCallback "dropped" "proxy_callback"
      
      status_log "Calling proxy::Setup now\n" white  
      ::Proxy::Setup next readable_handler $name
      
      
   } elseif {$config(connectiontype) == "proxy"} {
   
      status_log "Setting up Proxy connection (type=$config(proxytype))\n"
      ::Proxy::Init $config(proxy) $config(proxytype)
      #::Proxy::Init $config(proxy) "post"
      #::Proxy::Init $config(proxy) $config(proxytype)
      #::Proxy::LoginData $config(proxyauthenticate) $config(proxyuser) $config(proxypass)
   
      set proxy_serv [split $config(proxy) ":"]
      set tmp_serv [lindex $proxy_serv 0]
      set tmp_port [lindex $proxy_serv 1]        
      ::Proxy::OnCallback "dropped" "proxy_callback"
      
      status_log "Calling proxy::Setup now\n" white  
      ::Proxy::Setup next readable_handler $name
   
   }
     
   sb set $name time [clock seconds]
   sb set $name stat "cw"
   sb set $name error_msg ""
   
   if { [catch {set sock [socket -async $tmp_serv $tmp_port]} res ] } {
      sb set $name error_msg $res
      ::MSN::CloseSB $name
      return
   }
   
   sb set $name sock $sock
   fconfigure $sock -buffering none -translation {binary binary} -blocking 0
   fileevent $sock readable $readable_handler
   fileevent $sock writable $next
}

proc cmsn_ns_connected {} {
   global config

   
   set error_msg ""
   set therewaserror [catch {set error_msg [fconfigure [sb get ns sock] -error]} res]
   if { ($error_msg != "") || $therewaserror == 1 } {
      sb set ns error_msg $error_msg
      ::MSN::CloseSB ns
      return
   }   
   
   fileevent [sb get ns sock] writable {}
   sb set ns stat "c"
   cmsn_auth
   if {$config(adverts)} {
     adv_resume
   }

}


proc cmsn_ns_connect { username {password ""} {nosignin ""} } {
   global list_al list_bl list_fl list_rl list_users config

   if { ($username == "") || ($password == "")} {
     cmsn_draw_login
     return -1
   }


   set list_al [list]
   set list_bl [list]
   set list_fl [list]
   set list_rl [list]
   #TODO: I hope this breaks nothing
   set list_users [list]


   if {[sb get ns stat] != "d"} {
      catch {fileevent [sb get ns sock] readable {}} res
      catch {close [sb get ns sock]} res
   }

   if { $nosignin == "" } {
      cmsn_draw_signin
   }

   #Log in
   .main_menu.file entryconfigure 0 -state disabled
   .main_menu.file entryconfigure 1 -state disabled

   sb set ns data [list]
   sb set ns connected "cmsn_ns_connected"

   #TODO: Call "on connect" handlers, where hotmail will be registered.
   set ::hotmail::unread 0

   cmsn_socket ns

   load_alarms		;# Load alarms config on login

   return 0
}

proc get_password {method data} {
   global password

   set pass [::md5::md5 $data$password]
   return $pass

}


proc list_users_refresh {} {
   global list_fl list_users list_states

   set list_users_new [list]
   set fln [lsearch $list_states "FLN *"]

   foreach user $list_fl {
      set user_login [lindex $user 0]
      set user_name [lindex $user 1]
      set idx [lsearch $list_users "$user_login *"]
      if {$idx != -1} {
         lappend list_users_new [lindex $list_users $idx]
      } else {
         lappend list_users_new [list $user_login $user_name $fln]
      }
   }

   set list_users [lsort -decreasing -index 2 [lsort -decreasing -index 1 $list_users_new]]
   cmsn_draw_online

}

proc lists_compare {} {
   global list_fl list_al list_bl list_rl
   set list_albl [lsort [concat $list_al $list_bl]]
   set list_rl [lsort $list_rl]

   foreach x $list_rl {
      if {[lsearch $list_albl "[lindex $x 0] *"] == -1} {
         status_log "$x in your RL list but not in your AL/BL list!\n" white
	 newcontact [lindex $x 0] [lindex $x 1]
#         tkwait window .newc


      } ;# NOT in AL/BL
   }
}
proc newcontact_ok { newc_exit newc_add_to_list x0 x1} {
    global newc_allow_block

    if {$newc_exit == "OK"} {
	if {$newc_allow_block == "1"} {
	    ::MSN::WriteSB ns "ADD" "AL $x0 [urlencode $x1]"
	} else {
	    ::MSN::WriteSB ns "ADD" "BL $x0 [urlencode $x1]"
	}
	if {$newc_add_to_list} {
	    ::MSN::addUser $x0 [urlencode $x1]
	}
    } else {;# if clicked on OK, by default Accept List
	#	       ::MSN::WriteSB ns "ADD" "AL [lindex $x 0] [urlencode [lindex $x 1]]"
    }
}

proc cmsn_listupdate {recv} {
   global list_fl list_al list_bl list_rl

   set list_name "list_[string tolower [lindex $recv 2]]"

   if {([lindex $recv 4] <= 1) && ([lindex $recv 0] == "LST")} {
      set $list_name [list]
      status_log "clearing $list_name\n"
       if {$list_name == "list_al"} { # Here we have the groups already
	   ::groups::Enable
       }
   }

   if {[lindex $recv 0] == "ADD"} {		;# FIX: guess I should really
      set recv [linsert $recv 4 "1" "1"]	;# get it out of here!!
      status_log "ADDING...\n" blue
   }

   if {[lindex $recv 4] != 0} {
      set contact_info ""
      set user [lindex $recv 6]
      lappend contact_info $user
      lappend contact_info [urldecode [lindex $recv 7]]
      lappend $list_name $contact_info
      #status_log "adding to $list_name $contact_info\n"
   }

   if {[lindex $recv 4] == [lindex $recv 5]} {
      lists_compare		;# FIX: hmm, maybe I should not run it always!
      list_users_refresh
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
      if {[catch {set carval [format %d 0x[string range $str [expr {$end+1}] [expr {$end+2}]]]} res]} {
         if {[catch {set carval [format %d 0x[string range $str [expr {$end+1}] [expr {$end+1}]]]} res]} {
            binary scan [string range $str [expr {$end+1}] [expr {$end+1}]] c carval
	    status_log "proc urldecode: strange thing number 2 with string: $str\n" red
	 } else {
	    status_log "proc urldecode: strange thing number 1 with string: $str\n" red
	 }
      }
      if {$carval > 128} {
      	set carval [expr { $carval - 0x100 }]
      }

      set car [binary format c $carval]
#      status_log "carval: $carval = $car\n"

      set decode "${decode}$car"

      #if {[catch {set decode2 "${decode2}[format %c 0x[string range $str [expr {$end+1}] [expr {$end+2}]]]"} res]} {
      #   catch {set decode2 "${decode2}[format %c 0x[string range $str [expr {$end+1}] [expr {$end+1}]]]"} res
      #}

      set begin [expr {$end+3}]
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
          status_log "THIS ELSE SHOULDN'T HAPPEN, CHECK IT IN proc urlencode!!!\n" red
          #set charval1 [expr {$charval & 0xFF} ]
          #set charval2 [expr {$charval >> 8}]
          #set encode "${encode}$character"
       }
   }
   #status_log "urlencode: original=$str\n   utf-8=$utfstr\n   encoded=$encode\n"
   return $encode
}


proc urlencode {str} {
#   global url_map

   set encode ""

   set utfstr [encoding convertto utf-8 $str]


   for {set i 0} {$i<[string length $utfstr]} {incr i} {
       set character [string range $utfstr $i $i]

       if {[string match {[^a-zA-Z0-9]} $character]==0} {
          binary scan $character c charval
          #binary scan $character s charval
          set charval [expr {($charval + 0x100) % 0x100}]
          #set charval [expr {( $charval + 0x10000 ) % 0x10000}]
          if {$charval <= 0xFF} {
             set encode "${encode}%[format %.2X $charval]"
          } else {
             status_log "THIS SHOULDN'T HAPPEN, CHECK proc urlencode!!!\n" red

             #set charval1 [expr {$charval & 0xFF} ]
             #set charval2 [expr {$charval >> 8}]
             #set encode "${encode}$character"
          }
      } else {
         set encode "${encode}${character}"
      }
   }
   #status_log "urlencode: original=$str\n   utf-8=$utfstr\n   encoded=$encode\n"
   return $encode
}

proc change_BLP_settings { item } {
    global list_BLP

    set state [lindex $item 3]

    if { "$state" == "AL" } {
	set list_BLP 1
    } elseif { "$state" == "BL" } {
	set list_BLP 0
    } else {
	set list_BLP -1
    }
    
}
