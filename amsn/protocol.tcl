#	Microsoft Messenger Protocol Implementation
#=======================================================================

if { $initialize_amsn == 1 } {
    global user_info user_stat list_fl list_rl list_al list_bl list_version
    global list_users list_BLP list_otherusers list_cmdhnd sb_list list_states contactlist_loaded

    set contactlist_loaded 0


    set user_info ""
    set user_stat "FLN"
    set list_fl [list]
    set list_rl [list]
    set list_al [list]
    set list_bl [list]
    set list_version 0
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
}


namespace eval ::MSNFT {
   namespace export inviteFT acceptFT rejectFT

   #TODO: Instead of using a list, use many variables: ft_name, ft_sockid...

   proc invitationReceived { filename filesize cookie chatid fromlogin } {
      variable filedata

      set filedata($cookie) [list "$filename" $filesize $chatid $fromlogin "receivewait" "ipaddr"]
      after 300000 "::MSNFT::DeleteFT $cookie"
       ::amsn::fileTransferRecv $filename $filesize $cookie $chatid $fromlogin
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

      #Send the cancelation for a file transfer
      set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
      set msg "${msg}Invitation-Command: CANCEL\r\n"
      set msg "${msg}Invitation-Cookie: $cookie\r\n"
      set msg "${msg}Cancel-Code: REJECT\r\n\r\n"

      set msg_len [string length $msg]
      ::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"

      status_log "Rejecting filetransfer sent\n" red
      cancelFT $cookie

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
                 set filename "$origfile.$num"
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

   if { $initialize_amsn == 1 } {

       variable myStatus FLN
   }

   proc connect { username password } {

      global config tlsinstalled

      if { $config(protocol) == 9 && $tlsinstalled == 0 && [checking_package_tls] == 0 && $config(nossl) == 0} {
         ::amsn::installTLS
          return
      }

		if { $config(nossl) == 0 } {
			http::register https 443 ::tls::socket
		} else  {
			catch {http::unregister https}
		}

      #Log out
      .main_menu.file entryconfigure 2 -state normal

      ::MSN::StartPolling
      ::groups::Reset
		if {$config(connectiontype) == "direct" || $config(connectiontype) == "http" } {
			::http::config -proxyhost ""
		} elseif {$config(connectiontype) == "proxy"} {
			set lproxy [split $config(proxy) ":"]
			set proxy_host [lindex $lproxy 0]
			set proxy_port [lindex $lproxy 1]

			::http::config -proxyhost $proxy_host -proxyport $proxy_port
		}



      cmsn_ns_connect $username $password

   }

   proc logout {} {

      ::MSN::WriteSBRaw ns "OUT\r\n";

      catch {close [sb get ns sock]} res
      sb set ns stat "d"

      CloseSB ns

      global config user_stat automessage
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

      save_contact_list
      clean_contact_lists

      set automessage "-1"

      cmsn_draw_offline
      #Alert dock of status change
#      send_dock "FLN"
	send_dock "STATUS" "FLN"
   }


   proc GotREAResponse { recv } {

         global user_info config

         if { [string tolower [lindex $recv 3]] == [string tolower $config(login)] } {
            set user_info $recv
            cmsn_draw_online
         }

   }

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

   proc changeName { userlogin newname } {

      global config

      set name [urlencode $newname]

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

   proc copyUser { passport newGid {userName ""}} {
      if { $userName == "" } {
        set userName $passport
      }
      set atrid [::MSN::WriteSB ns "ADD" "FL $passport [urlencode $userName] $newGid"]
   }


   proc addUser { userlogin {username ""}} {
      if { $username == "" } {
        set username $userlogin
      }
      ::MSN::WriteSB ns "ADD" "FL $userlogin $username 0" "::MSN::ADDHandler"
   }
   
   proc ADDHandler { item } {
   
      if { [lindex $item 2] == "FL"} {
         set contact [lindex $item 4]	;# Email address
         msg_box "[trans contactadded]\n$contact"
      }
      
      cmsn_ns_handler $item

   }

   proc deleteUser { userlogin {grId ""}} {
      if { $grId == "" } {
         ::MSN::WriteSB ns REM "FL $userlogin"
      } else {
         ::MSN::WriteSB ns REM "FL $userlogin $grId"
      }
   }


   proc getMyIP { } {

      global config

      set sock [sb get ns sock]

      set localip [lindex [fconfigure $sock -sockname] 0]

      status_log "Called getmyIP, local: $localip\n"

      if { [string compare -length 3 $localip "10."] == 0 \
      || [string compare -length 4 $localip "127."] == 0 \
      || [string compare -length 8 $localip "192.168."] == 0 \
      || $config(natip) == 1 } {
        if { [catch {set token [::http::geturl "http://www.showmyip.com/simple/" -timeout 10000]} res]} {
           return $localip
        }

        if { [::http::status $token] == "ok" && [::http::ncode $token] == 200 } {
           set httpip [lindex [split [::http::data $token]] 0]
        } else {
           set httpip $localip
        }
        ::http::cleanup $token
        status_log "Called get http ip: $httpip, $token\n"

		  return httpip
      } else {
         return $localip
      }

   }


   proc getMyIPSilent { } {

      global config

		if { $config(autoftip) } {
			set sock [sb get ns sock]
			if { $sock == "" } return

			set localip [lindex [fconfigure $sock -sockname] 0]

			status_log "Called getmyIPSilent, local: $localip\n"

			if { [string compare -length 3 $localip "10."] == 0 \
			|| [string compare -length 4 $localip "127."] == 0 \
			|| [string compare -length 8 $localip "192.168."] == 0 \
			|| $config(natip) == 1 } {
				catch {set token [::http::geturl "http://www.showmyip.com/simple/" \
					-timeout 10000 -command "::MSN::GotMyIPSilent"]}
			} else {
				set config(myip) $localip
				status_log "IP automatically set to: $config(myip)\n" blue
			}

		} else {
			status_log "No autoftip - IP manually set to: $config(myip)\n" blue
		}

   }

	proc GotMyIPSilent { token } {
		if { [::http::status $token] == "ok" && [::http::ncode $token] == 200 } {
			set ip [lindex [split [::http::data $token]] 0]
			::http::cleanup $token
			status_log "Called GotMyIPSilent, http ip: $ip, $token\n"
		}
		::http::cleanup $token
	}


   #Internal procedures

   proc StartPolling {} {
      global config

      if {($config(keepalive) == 1) && ($config(connectiontype) == "direct")} {
        after cancel "::MSN::PollConnection"
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

   if { $initialize_amsn == 1 } {

       variable trid 0
       variable atransfer
   }

   proc DirectWrite { sbn cmd } {
   
      set sb_sock [sb get $sbn sock]

      #set command "[sb get ns puts] -nonewline [sb get ns sock] \"$cmd\""
      if {[catch {puts -nonewline $sb_sock "$cmd"} res]} {
         status_log "::MSN::DirectWrite: SB $sbn problem when writing to the socket: $res...\n" red
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
      catch {eval $command}
      

   }

   # Check if the old closed preferred SB is still the preferred SB, or close it
   # if not
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
            #Try to kill it again in 60 seconds
            after 60000 "::MSN::CheckKill $sbn"
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

      #If we keep it here we have problems, specially the proc_ns one (can't connect)
      #if { $sbn == "ns" } {
      #   proc_ns      
      #} else {
      #   proc_sb
      #}
      
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

	 if { ("$oldstat"!="d") && ("$oldstat" !="o") && ("$oldstat" !="u") && ("$oldstat" !="us")} {
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
      
         proc_sb
  
         CheckKill $sbn
	 
      }
   }
   #///////////////////////////////////////////////////////////////////////
   
   
   proc AnswerChallenge { item } {
      if { [lindex $item 1] != 0 } {
        status_log "Invalid challenge\n" red
      } else {
			#set str [lindex $item 2]Q1P7W2E4J9R8U3S5
			#set str [::md5::md5 $str]

			#::MSN::WriteSBNoNL ns "QRY" "msmsgs@msnmsgr.com 32\r\n$str"

			#Let's test MSN6 challenge strings
			set str [lindex $item 2]JXQ6J@TUOGYV@N0M
			set str [::md5::md5 $str]

			::MSN::WriteSBNoNL ns "QRY" "PROD0061VRRZH@4F 32\r\n$str"

		}
   }


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

   if { $initialize_amsn == 1 } {

       variable sb_num 0
   }

   proc GetNewSB {} {
      variable sb_num
      incr sb_num
      return "sb_${sb_num}"
   }

   proc chatTo { user } {

      global sb_list
     
      set lowuser [string tolower ${user}]

      if { [chatReady $lowuser] } {
        return $lowuser
      }

      status_log "::MSN::chatTo: Opening chat to user $user\n"
            
      set sbn [SBFor $lowuser]

      if { $sbn == 0 } {

           
         set sbn [GetNewSB]

         status_log "::MSN::chatTo: No SB available, creating new: $sbn\n"
	 
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
          
      cmsn_reconnect $sbn
      return $lowuser

   }


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
      	 fileevent [sb get $name sock] readable ""
	 fileevent [sb get $name sock] writable ""
         close [sb get $name sock]
      } res

      set sb_list [lreplace $sb_list $idx $idx ]

      unset ${name}_info
   }

   
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

	  # This next two are necessary because SBFor doesn't
	  # always return a ready SB
	  if { "[sb get $sbn stat]" != "o" } {
	     return 0
	  }

	  set sb_sock [sb get $sbn sock]

	  if { "$sb_sock" == "" } {
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


   proc ChatFor { sb_name } {
   
      variable chatid_sb

      if {[info exists chatid_sb($sb_name)]} {
         return $chatid_sb($sb_name)
      }

      status_log "::MSN::ChatFor: SB $sb_name is not associated to any chat\n" blue                         
      return 0
   }

   
   proc AddSBFor { chatid sb_name} {
          variable sb_chatid
	  variable chatid_sb

	  if {![info exists sb_chatid($chatid)]} {
	     set sb_chatid($chatid) [list]
	     status_log "::MSN::AddSBFor: Creating sb_chatid list for $chatid\n"
	  }

	  set index [lsearch $sb_chatid($chatid) $sb_name]
	  
	  set oldsb_chatid $sb_chatid($chatid);
	  set moved_to_beginning 0
	  
	  if { $index == -1 } {
	     #Should we insert at the beggining? Newer SB's are probably better
	     set sb_chatid($chatid) [linsert $sb_chatid($chatid) 0 $sb_name]
	  } else {
	     #Move SB to the begginning of the list
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
         status_log "::MSN::ProcessQueue: processing leaveChat in queue for $chatid\n" black
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
         status_log "::MSN::SendChatMsg: chat NOT ready for $chatid, nacking message\n"
         ::amsn::nackMessage $ackid
	 return 0
      }


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
         status_log "::MSN::messageTo: chat NOT ready for $chatid\n"
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

      status_log "read_sb_sock: Error reading EOF for $sbn: $res\n" red
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
         status_log "problem processing NS data: $item!!\n" red
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
      
      #if alarm_onmsg is on run it
      global alarms list_users
      if { ([info exists alarms(${chatid}_onmsg)]) && ($alarms(${chatid}_onmsg) == 1) && ([info exists alarms(${chatid})]) && ($alarms(${chatid}) == 1)} {
        set idx [lsearch $list_users "${chatid} *"]
        set username [lindex [lindex $list_users $idx] 1]
        run_alarm $chatid  "[trans says $username] $body"
      }

      # Send automessage once to each user
      	if { [info exists automessage] } {
	if { $automessage != "-1" } {
		if { [info exists automsgsent($typer)] } {
			if { $automsgsent($typer) != 1 } {
				::amsn::MessageSend [::amsn::WindowFor $chatid] 0 [parse_exec [lindex $automessage 3]]
				set automsgsent($typer) 1
			}
		} else {
				::amsn::MessageSend [::amsn::WindowFor $chatid] 0 [parse_exec [lindex $automessage 3]]
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
      status_log "cmsn_sb_msg: === UNKNOWN MSG ===\n$msg\n" red
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
#	  ::MSN::CleanChat $chatid
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
   cmsn_sb_handler $sb_name [encoding convertto utf-8 $item]
}

proc cmsn_sb_handler {sb_name item} {
   global list_cmdhnd msgacks


   set item [encoding convertfrom utf-8 $item]

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

      ::MSN::WriteSB $name "CAL" $user "CALReceived $name $user"

   } else {

      status_log "cmsn_invite_user: Can't invite user to non connected SB!!\n" red

   }

}


proc cmsn_rng {recv} {

   global config sb_list

   set emaill [string tolower [lindex $recv 5]]

	#Quick fix to avoid annoying messages from Microsoft

	if { $emaill == "messenger@microsoft.com" } {
		status_log "Received chat from messenger@microsoft.com. Ignoring!!\n" white
		return 0
	}

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

   status_log "[trans chatack] [lindex $recv 5]... (Got ANS1 in SB $sbn\n" green

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

   sb set $sbn serv [split [lindex $recv 3] ":"]
   sb set $sbn connected "cmsn_conn_sb $sbn"
   sb set $sbn auth_cmd "USR"
   sb set $sbn auth_param "$config(login) [lindex $recv 5]"


   ::amsn::chatStatus [::MSN::ChatFor $sbn] "[trans sbcon]...\n" miniinfo ready
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

   } elseif {[sb get $name stat] == "i"} {

      #status_log "cmsn_reconnect: stat = i , SB= $name\n" green   
   
      if { [expr {[clock seconds] - [sb get $name time]}] > 15 } {
         status_log "cmsn_reconnect: called again while inviting timeouted for sb $name\n" red
	 catch { fileevent [sb get $name sock] readable "" } res
	 catch { fileevent [sb get $name sock] writable "" } res
	 catch {close [sb get $name sock]} res
	 sb set $name stat "d"
	 cmsn_reconnect $name
      }

   } elseif {[sb get $name stat] == "c"} {

      #status_log "cmsn_reconnect: stat = c , SB= $name\n" green      
   
      if { [expr {[clock seconds] - [sb get $name time]}] > 10 } {
         status_log "cmsn_reconnect: called again while reconnect timeouted for sb $name\n" red
	 catch { fileevent [sb get $name sock] readable "" } res
	 catch { fileevent [sb get $name sock] writable "" } res
	 catch {close [sb get $name sock]} res
	 sb set $name stat "d"
	 cmsn_reconnect $name
      }

   } elseif {([sb get $name stat] == "cw") \
      || ([sb get $name stat] == "pw") \
      || ([sb get $name stat] == "a")} {
      
      #status_log "cmsn_reconnect: stat =[sb get $name stat] , SB= $name\n" green         

      if { [expr {[clock seconds] - [sb get $name time]}] > 10 } {
         status_log "cmsn_reconnect: called again while authentication timeouted for sb $name\n" red
	 catch { fileevent [sb get $name sock] readable "" } res
	 catch { fileevent [sb get $name sock] writable "" } res
	 catch {close [sb get $name sock]} res
	 sb set $name stat "d"
	 cmsn_reconnect $name
      }
   } elseif {[sb get $name stat] == ""} {
      status_log "cmsn_reconnect: SB $name stat is [sb get $name stat]. This is bad, should delete it and create a new one\n" red
      catch {
          set chatid [::MSN::ChatFor $name]
          ::MSN::DelSBFor $chatid $name
          ::MSN::KillSB $name
          ::MSN::chatTo $name
      }


   } else {

       status_log "cmsn_reconnect: SB $name stat is [sb get $name stat]\n" red

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
          if {[::MSN::SBFor $chatid] == $sb_name} {
             ::amsn::userJoins $chatid $usr_login
          }

      }
   }

}
#///////////////////////////////////////////////////////////////////////



proc cmsn_change_state {recv} {
   global list_users config list_states alarms

    ::plugins::PostEvent ChangeState recv list_users list_states

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

#sistema de alarmas (que debe sustituir al anterio que esta implementado mas adelante) de KNO
   global alarms
   if {[lindex $recv 0] !="ILN"} {
   #no es la comprobacion del principio
     if {[lindex $recv 0] == "FLN"} {
     #el usuario se ha desconectado
     set idx [lsearch $list_users "$user *"]
     set user_name [lindex [lindex $list_users $idx] 1]
       if { ([info exists alarms([lindex $recv 1]_ondisconnect)]) && ($alarms([lindex $recv 1]_ondisconnect) == 1) && ([info exists alarms([lindex $recv 1])]) && ($alarms([lindex $recv 1]) == 1)} {
	 run_alarm [lindex $recv 1] [trans disconnect $user_name]
       }
     } else {
	     if { ([info exists alarms([lindex $recv 2]_onstatus)]) && ($alarms([lindex $recv 2]_onstatus) == 1) && ([info exists alarms([lindex $recv 2])]) && ($alarms([lindex $recv 2]) == 1)} {
       switch -exact [lindex $recv 1] {
         "NLN" {
	 	run_alarm [lindex $recv 2] "[trans changestate $user_name [trans online]]"
	 }
	 "IDL" {
	 	run_alarm [lindex $recv 2] "[trans changestate $user_name [trans away]]"
	 }
	 "BSY" {
	 	run_alarm [lindex $recv 2] "[trans changestate $user_name [trans busy]]"
	 }
	 "BRB" {
	 	run_alarm [lindex $recv 2] "[trans changestate $user_name [trans rightback]]"
	 }
	 "AWY" {
	 	run_alarm [lindex $recv 2] "[trans changestate $user_name [trans away]]"
	 }
	 "PHN" {
	 	run_alarm [lindex $recv 2] "[trans changestate $user_name [trans onphone]]"
	 }
	 "LUN" {
	 	run_alarm [lindex $recv 2] "[trans changestate $user_name [trans gonelunch]]"
	 }
       }
       }
     }
   }
#fin sistema de alarmas

   set idx [lsearch $list_users "$user *"]
   if {$idx != -1} {

      set user_data [lindex $list_users $idx]
      if {$user_name == ""} {
         set user_name [urldecode [lindex $user_data 1]]
      }

       set state_no [lsearch $list_states "$substate *"]

      if {$user_name != [lindex $user_data 1]} {
      	#Nick differs from the one on our list, so change it
	#in the server list too
	::MSN::changeName $user $user_name
    }

	set maxw [expr {$config(notifwidth)-20}]
	set short_name [trunc $user_name . $maxw splainf]

	if {[lindex $user_data 2] < 7} {		;# User was online before

		if { $config(notifystate) == 1 &&  $substate != "FLN" && [lindex $recv 0] != "ILN" } {

			::amsn::notifyAdd "$short_name\n[trans statechange]\n[trans [lindex [lindex $list_states $state_no] 1]]." \
				"::amsn::chatUser $user" state state
		}


	} elseif {[lindex $recv 0] == "NLN"} {	;# User was offline, now online

	  user_not_blocked "$user"

	 if { $config(notifyonline) == 1 } {
        ::amsn::notifyAdd "$short_name\n[trans logsin]." "::amsn::chatUser $user" online
	 }

	 if { ([info exists alarms([lindex $recv 2]_onconnect)]) && ($alarms([lindex $recv 2]_onconnect) == 1) && ([info exists alarms([lindex $recv 2])]) && ($alarms([lindex $recv 2]) == 1)} {
             #catch { run_alarm [lindex $recv 2] [lindex $recv 3]}        ;# Run Alarm using EMAIL ADDRESS (Burger)
	     catch { run_alarm [lindex $recv 2] "$user_name [trans logsin]"}
	 }
      }

      if {$substate != "FLN"} {

#      	 status_log "Inserting <$user_name> in menu\n" white
#         .main_menu.msg insert 0 command -label "$user_name <$user>" \
#            -command "::amsn::chatUser $user"
      } else {

	  if { $config(notifyoffline) == 1 } {
	      ::amsn::notifyAdd "$short_name\n[trans logsout]." "" offline offline
	  }
	  if { $config(checkonfln) == 1 } {
	      ::MSN::chatTo "$user"
	  }
      }

       #TODO: Change this with ::MSN::setUserInfo
      set list_users [lreplace $list_users $idx $idx [list $user $user_name $state_no]]
      set list_users [lsort -decreasing -index 2 [lsort -decreasing -index 1 $list_users]]

      cmsn_draw_online
   } else {
      status_log "cmsn_change_state: PANIC!\n" red
   }

}

proc cmsn_ns_handler {item} {
   global list_cmdhnd password config protocol

   set item [encoding convertfrom utf-8 $item]
   set item [stringmap {\r ""} $item]

   set ret_trid [lindex $item 1]
   set idx [lsearch $list_cmdhnd "$ret_trid *"]
   if {$idx != -1} {		;# Command has a handler associated!
      status_log "cmsn_ns_handler: evaluating handler for $ret_trid\n"
      
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
      CVR -
      USR {
	 return [cmsn_auth $item]
      }
      XFR {
	 if {[lindex $item 2] == "NS"} {
	    set tmp_ns [split [lindex $item 3] ":"]
            sb set ns serv $tmp_ns
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
	  new_contact_list "[lindex $item 3]"
	 set curr_list [lindex $item 2]
	 if { ($curr_list == "FL") } {
	     ::abook::setContact [lindex $item 4] nick [lindex $item 5]
	     ::abook::addContactToGroup [lindex $item 4] [lindex $item 6]	     
	 }
         cmsn_listupdate $item
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
      GTC {
	 return 0
      }
      SYN {
	  new_contact_list "[lindex $item 2]" 1
	  global protocol
	  if { $protocol == "9" } {
	      global loading_list_info
	      
	      set loading_list_info(version) [lindex $item 2]
	      set loading_list_info(total) [lindex $item 3]
	      set loading_list_info(current) 1
	      set loading_list_info(gtotal) [lindex $item 4]
	  }
	 return 0
      }
      BLP {
#	  puts "$item == [llength $item]"
	  if { $protocol == "9" && [llength $item] == 3} {
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
	  if { $protocol == "9" && [llength $item] == 4} {
	      global loading_list_info
	      #status_log "$item --- protocol 9 --- $protocol\n"
	      ::abook::setContact $loading_list_info(last) [lindex $item 1] [lindex $item 2]

	  } else {
	      #status_log "$item --- protocol 7 --- $protocol\n"
	      new_contact_list "[lindex $item 1]"
	      # Update entry in address book setContact(email,PH*/M*,phone/setting)
	      ::abook::setContact [lindex $item 2] [lindex $item 3] [lindex $item 4] 
	  }
	 return 0
      }
      PRP {
	  if { $protocol != "9" } {
	      new_contact_list "[lindex $item 2]"
	      ::abook::setPersonal [lindex $item 3] [lindex $item 4]
	  }
	return 0
      }
      LSG {

	  global protocol
	  if { $protocol == "9" } {
	      ::groups::Set [lindex $item 1] [lindex $item 2]
	  } else {
	      ::groups::Set [lindex $item 5] [lindex $item 6]
	      new_contact_list "[lindex $item 2]"
	      #status_log "$item\n" blue
	  }
	return 0
      }
      REG {	# Rename Group
	  new_contact_list "[lindex $item 2]"
      	#status_log "$item\n" blue
	::groups::RenameCB [lrange $item 0 5]
	cmsn_draw_online
	return 0
      }
      ADG {	# Add Group
	  new_contact_list "[lindex $item 2]"
      	#status_log "$item\n" blue
	::groups::AddCB [lrange $item 0 5]
   	cmsn_draw_online
	return 0
      }
      RMG {	# Remove Group
	  new_contact_list "[lindex $item 2]"
      	#status_log "$item\n" blue
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
	  status_log "Error: Internal server error\n" red
	  ::amsn::errorMsg "[trans internalerror]"
          return 0
      }
      911 {
	  #set password ""
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
      ::abook::setDemographics d
   } else {
      hotmail_procmsg $msg_data	 
   }
}


proc cmsn_listdel {recv} {
   set list_name "list_[string tolower [lindex $recv 2]]"
   
   
   if { [lindex $recv 2] == "FL" } {
      if { [lindex $recv 5] == "" } {
         #Remove from all groups!!
         foreach group [::abook::getGroup [lindex $recv 4] -id] {
            ::abook::removeContactFromGroup [lindex $recv 4] $group
         }
      } else {
         #Remove fromonly one group
         ::abook::removeContactFromGroup [lindex $recv 4] [lindex $recv 5]
      }
   
      if { [llength [::abook::getGroup [lindex $recv 4] -id]] == 0 } {
         status_log "cmsn_listdel: Contact [lindex $recv 4] is in no groups, removing!!\n" blue
         upvar #0 $list_name the_list
         set idx [lsearch $the_list "[lindex $recv 4] *"]
         if { $idx != -1 } {
            set the_list [lreplace $the_list $idx $idx]
         } else {
            status_log "cmsn_listdel: PANIC_1!!!\n" red
         }
      }
   } else {
      upvar #0 $list_name the_list
      set idx [lsearch $the_list "[lindex $recv 4] *"]
      if { $idx != -1 } {
         set the_list [lreplace $the_list $idx $idx]
      } else {
         status_log "cmsn_listdel: PANIC_2!!!\n" red
      }
   }
   
   
   #lists_compare		;# FIX: hmm, maybe I should not run it always!
   list_users_refresh
   #::MSN::WriteSB ns "LST" "[lindex $recv 2]"
}

proc cmsn_auth {{recv ""}} {
   global config list_version protocol

    if {($protocol == "9") && ([info exist recv])} { return [cmsn_auth_msnp9 $recv]}
    if {($protocol == "9") && (![info exist recv])} { return [cmsn_auth_msnp9]}

   switch [sb get ns stat] {
      c {
#New version of protocol
         ::MSN::WriteSB ns "VER" "MSNP7 MSNP6 MSNP5 MSNP4 CVR0"
	 sb set ns stat "v"
	 return 0
      }
      v {
         if {[lindex $recv 0] != "VER"} {
	    status_log "cmsn_auth: was expecting VER reply but got a [lindex $recv 0]\n" red
	    return 1
	 } elseif {[lsearch -exact $recv "CVR0"] != -1} {
            ::MSN::WriteSB ns "INF" ""
	    sb set ns stat "i"
	    return 0
	 } else {
	    status_log "cmsn_auth: could not negotiate protocol!\n" red
	    return 1
	 }
      }
      i {
         if {[lindex $recv 0] != "INF"} {
	    status_log "cmsn_auth: was expecting INF reply but got a [lindex $recv 0]\n" red
            return 1
         } elseif {[lsearch -exact $recv "MD5"] != -1} {
            global config
            ::MSN::WriteSB ns "USR" "MD5 I $config(login)"
            sb set ns stat "u"
            return 0
         } else {
            status_log "cmsn_auth: could not negotiate authentication method!\n" red
            return 1
         }
      }
      u {
         if {([lindex $recv 0] != "USR") || \
            ([lindex $recv 2] != "MD5") || \
            ([lindex $recv 3] != "S")} {
            status_log "cmsn_auth: was expecting USR x MD5 S xxxxx but got something else!\n" red
            return 1
         }
         ::MSN::WriteSB ns "USR" "MD5 S [get_password 'MD5' [lindex $recv 4]]"
         sb set ns stat "us"
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
         global user_info
         set user_info $recv
         sb set ns stat "o"
	 save_config						;# CONFIG
	  load_contact_list
	 ::MSN::WriteSB ns "SYN" "$list_version"

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
	 #configureMenuEntry .options "[trans changenick]..." normal

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


proc msnp9_userpass_error {} {

	::MSN::logout
	status_log "Error: User/Password\n" red
	::amsn::errorMsg "[trans baduserpass]"

}

proc msnp9_auth_error {} {

	status_log "Error connecting to server\n"
	::MSN::logout
	::amsn::errorMsg "[trans connecterror]"

}

proc gotNexusReply {str token {total 0} {current 0}} {
	if { [::http::status $token] != "ok" || [::http::ncode $token ] != 200 } {
		::http::cleanup $token
		status_log "gotNexusReply: error in nexus reply, getting url manually\n"
		msnp9_do_auth $str "https://login.passport.com/login2.srf"
		return
	}
	upvar #0 $token state

	set index [expr {[lsearch $state(meta) "PassportURLs"]+1}]
	set values [split [lindex $state(meta) $index] ","]
	set index [lsearch $values "DALogin=*"]
	set loginurl "https://[string range [lindex $values $index] 8 end]"
	status_log "gotNexusReply: loginurl=$loginurl\n"
	::http::cleanup $token
	msnp9_do_auth [list $str] $loginurl


}

proc gotAuthReply { str token } {
	if { [::http::status $token] != "ok" } {
		::http::cleanup $token
		status_log "gotAuthReply error: [::http::error]\n"
		msnp9_auth_error
		return
	}

	upvar #0 $token state

	if { [::http::ncode $token] == 200 } {
		set index [expr {[lsearch $state(meta) "Authentication-Info"]+1}]
		set values [split [lindex $state(meta) $index] ","]
		set index [lsearch $values "from-PP=*"]
		set value [string range [lindex $values $index] 9 end-1]
		status_log "gotAuthReply 200 Headers:\n $state(meta)\n"
		status_log "gotAuthReply 200 Ticket= $value\n"
		msnp9_authenticate $value

	} elseif {[::http::ncode $token] == 302} {
		set index [expr {[lsearch $state(meta) "Location"]+1}]
		set url [lindex $state(meta) $index]
		status_log "gotAuthReply 320: Forward to $url\n"		
		msnp9_do_auth $str $url
	} elseif {[::http::ncode $token] == 401} {
		msnp9_userpass_error
	} else {
		msnp9_auth_error
	}
	::http::cleanup $token


}


proc msnp9_do_auth {str url} {
	status_log "msnp9_do_auth\n"
	global config password

	set head [list Authorization "Passport1.4 OrgVerb=GET,OrgURL=http%3A%2F%2Fmessenger%2Emsn%2Ecom,sign-in=$config(login),pwd=${password},${str}"]
	if { $config(nossl) == 1 || ($config(connectiontype) != "direct" && $config(connectiontype) != "http") } {
		set url [string map { https:// http:// } $url]
	}
	status_log "msnp9_do_auth: Getting $url\n"
	if {[catch {::http::geturl $url -command "gotAuthReply [list $str]" -headers $head}]} {
		msnp9_auth_error
	}

}


proc msnp9_authenticate { ticket } {

	::MSN::WriteSB ns "USR" "TWN S $ticket"
	sb set ns stat "us"
	return

}

proc cmsn_auth_msnp9 {{recv ""}} {
	global config list_version info protocol

	switch [sb get ns stat] {

		c {
			::MSN::WriteSB ns "VER" "MSNP9 MSNP8 CVR0"
			sb set ns stat "v"
			return 0
		}

		v {
			if {[lindex $recv 0] != "VER"} {
				status_log "cmsn_auth: was expecting VER reply but got a [lindex $recv 0]\n" red
				return 1
			} elseif {[lsearch -exact $recv "CVR0"] != -1} {
				::MSN::WriteSB ns "CVR" "0x0409 winnt 5.1 i386 MSNMSGR 5.0.0540 MSMSGS $config(login)"
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
				::MSN::WriteSB ns "USR" "TWN I $config(login)"
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

			if {$config(nossl)
			|| ($config(connectiontype) != "direct" && $config(connectiontype) != "http")
			||[catch {puts "Here"; ::http::geturl https://nexus.passport.com/rdr/pprdr.asp -timeout 5000 -command "gotNexusReply [list $info(all)]" }]} {
				msnp9_do_auth [list $info(all)] https://login.passport.com/login2.srf
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

			global user_info
			set user_info $recv
			sb set ns stat "o"
			save_config						;# CONFIG
			load_contact_list

			::MSN::WriteSB ns "SYN" "$list_version"

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
			#configureMenuEntry .options "[trans changenick]..." normal

			configureMenuEntry .main_menu.actions "[trans sendmail]..." normal
			configureMenuEntry .main_menu.actions "[trans sendmsg]..." normal

			configureMenuEntry .main_menu.file "[trans savecontacts]..." normal


			::MSN::getMyIPSilent

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


proc fileDialog2 {w ent operation basename {types {{"All files"         *}} }} {
    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    #   set types {{"All files"		*} }

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

      status_log "cmsn_socket: Setting up http connection\n" green
      set tmp_serv "gateway.messenger.hotmail.com"
      set tmp_port 80

      ::Proxy::Init "$tmp_serv:$tmp_port" "http"

      ::Proxy::OnCallback "dropped" "proxy_callback"

      status_log "cmsn_socket: Calling proxy::Setup now\n" green
      ::Proxy::Setup next readable_handler $name
      
      
   } elseif {$config(connectiontype) == "proxy"} {
   
      status_log "cmsn_socket: Setting up Proxy connection (type=$config(proxytype))\n" green
      ::Proxy::Init $config(proxy) $config(proxytype)
      #::Proxy::Init $config(proxy) "post"
      #::Proxy::Init $config(proxy) $config(proxytype)
      ::Proxy::LoginData $config(proxyauthenticate) $config(proxyuser) $config(proxypass)
   
      set proxy_serv [split $config(proxy) ":"]
      set tmp_serv [lindex $proxy_serv 0]
      set tmp_port [lindex $proxy_serv 1]        
      ::Proxy::OnCallback "dropped" "proxy_callback"
      
      status_log "cmsn_connect: Calling proxy::Setup now\n" green
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
         status_log "lists_compare: $x in your RL list but not in your AL/BL list!\n" blue
	 newcontact [lindex $x 0] [lindex $x 1]

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

proc process_msnp9_lists { bin } {

    set lists [list]
    
    if { [expr $bin % 2] } {
	lappend lists "list_fl"
    }
    set bin [expr $bin / 2]

    if { [expr $bin % 2] } {
	lappend lists "list_al"
    }

    set bin [expr $bin / 2]

    if { [expr $bin % 2] } {
	lappend lists "list_bl"
    }
    set bin [expr $bin / 2]

    if { [expr $bin % 2] } {
	lappend lists "list_rl"
    }

    return $lists
}

proc cmsn_listupdate {recv} {
   global list_fl list_al list_bl list_rl protocol contactlist_loaded

    set contactlist_loaded 0

    if { [lindex $recv 0] == "ADD" } {
	set list_names "list_[string tolower [lindex $recv 2]]"
	set version [lindex $recv 3]

	set command ADD

	set current 1
	set total 1
	
	set username [lindex $recv 4]
	set nickname [lindex $recv 5]
	set groups [lindex $recv 6]
	

    } elseif { $protocol == "9" } {
	global loading_list_info

	set command LST

	set current $loading_list_info(current)
	set total $loading_list_info(total)

	incr loading_list_info(current)

	set username [lindex $recv 1]
	set nickname [lindex $recv 2]

	set list_names [process_msnp9_lists [lindex $recv 3]]
	#puts "$username --- $list_names"
	set groups [lindex $recv 4]

    } else {

	set command LST

	set list_names "list_[string tolower [lindex $recv 2]]"
	set version [lindex $recv 3]

	set current [lindex $recv 4]
	set total [lindex $recv 5]
	
	if {$current != 0} {
	    set username [lindex $recv 6]
	    set nickname [lindex $recv 7]
	    set groups [lindex $recv 8]
	}
	    
    } 



    foreach list_name $list_names {
   
	#List is empty or first user in list
	if {($current <= 1) && ($command == "LST")} {
	    set $list_name [list]
	    status_log "cmsn_listupdate: Clearing $list_name\n"
	    if {$list_name == "list_al"} { # Here we have the groups already
		::groups::Enable
	    }
	}


	#If list is not empty, get user information
	if {$current != 0} {
	    set contact_info ""
	    set user $username
	
	    #Add only if user is not already in list
	    upvar #0 $list_name the_list
	    if { [lsearch $the_list "$user *"] == -1 } {      
		lappend contact_info $user
		lappend contact_info [urldecode $nickname]
		lappend $list_name $contact_info
		
		#status_log "cmsn_listupdate: adding to $list_name $contact_info\n"
	    } 

	    # New entry in address book setContact(email,FL,groupID)
	    # NOTE: IF a user belongs to several groups, the group part
	    #       of this packet will have the group ids separated
	    #       by commas:  0,5  (group 0 & 5).
	    # It could be that it is in the FL but not in RL or viceversa.
	    # Everything that is in AL or BL is in either of the above.
	    # Only FL contains the group membership though...
	    if { ($list_name == "list_fl") } {
		::abook::setContact $username group $groups
		::abook::setContact $username nick $nickname
		if { $protocol == "9" } {
		    set loading_list_info(last) $username
		}
	    }
	}
	 
    }

    #Last user in list
    if {$current == $total} {
	lists_compare		;# FIX: hmm, maybe I should not run it always!
	list_users_refresh
	if { $protocol != "9" } {
	    new_contact_list "$version"
	    set contactlist_loaded 1
	} else {
	    if { $list_name == "list_rl" } {
		set contactlist_loaded 1
	    }
	}
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
	    status_log "urldecode: strange thing number 2 with string: $str\n" red
	 } else {
	    status_log "urldecode: strange thing number 1 with string: $str\n" red
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

       if {[string match {[^a-zA-Z0-9]} $character]==0} {
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

proc new_contact_list { version {load 0} } {
    global list_version HOME list_al list_fl list_bl list_rl list_users protocol

    if {[string is digit $version] == 0} {return }

    if { $load} {
       status_log "new_contact_list: new contact list version : $version --- previous was : $list_version\n"
    }


    if { $list_version == $version } {
	if { $load } {

	    status_log "new_contact_list loading contact list from file\n"
	    if {[file readable "[file join ${HOME} contacts.ver]"] == 0} {
		return 0
	    }
	    set list_al [list]
	    set list_bl [list]
	    set list_rl [list]
	    set list_fl [list] 
	    set list_users [list] 
	    
	    set contact_id [sxml::init [file join ${HOME} contacts.xml]]
	    
	    sxml::register_routine $contact_id "contactlist_${list_version}:AL:user" "create_contact_list"
	    sxml::register_routine $contact_id "contactlist_${list_version}:BL:user" "create_contact_list"
	    sxml::register_routine $contact_id "contactlist_${list_version}:FL:user" "create_contact_list"
	    sxml::register_routine $contact_id "contactlist_${list_version}:RL:user" "create_contact_list"
	    sxml::register_routine $contact_id "contactlist_${list_version}:Group" "create_group"
	    sxml::register_routine $contact_id "contactlist_${list_version}" "finished_loading_list"
	    
	    status_log "new_contact_list: parsing file\n"
	    set ret [sxml::parse $contact_id]
	    if { $ret < 0 } {
		set list_version 0
		::MSN::WriteSB ns "SYN" "0"
	    }

	    status_log "new_contact_list ended parsing of file with return code : $ret \n"
	    sxml::end $contact_id
	}

    } else {
	#status_log "$list_version becomes $version\n"
	set list_version $version
    }
   
}


proc load_contact_list { } {
    global list_version HOME

    status_log "load_contact_list: checking if contact list files exists\n"

    if {[file readable "[file join ${HOME} contacts.xml]"] == 0} {
	set list_version "0"
	return 0
    }

    if {[file readable "[file join ${HOME} contacts.ver]"] == 0} {
	set list_version "0"
	return 0
    }

    set file_id [open [file join ${HOME} contacts.ver] r]
    gets $file_id version
    close $file_id

    status_log "load_contact_list: setting contact list version to $version\n"

    set list_version $version

}

proc save_contact_list { } {
    global HOME list_version list_al list_fl list_rl list_bl list_BLP contactlist_loaded

    if { $contactlist_loaded == 0 } { return }

    if {[file readable "[file join ${HOME} contacts.ver]"] != 0} {

	set file_id [open [file join ${HOME} contacts.ver] r]
	gets $file_id version

	if { $version == $list_version } {
	    close $file_id
	    return 
	}
    } 


    set file_id [open "[file join ${HOME} contacts.ver]" w]
    
    puts $file_id "$list_version"

    close $file_id
    
    set file_id [open "[file join ${HOME} contacts.xml]" w ]

    fconfigure $file_id -encoding utf-8

    puts $file_id "<?xml version=\"1.0\"?>"

    ::abook::getPersonal perso

    puts $file_id "<contactlist_${list_version}>\n   <BLP>${list_BLP}</BLP>\n   <PHH>[set perso(phh)]</PHH>\n   <PHW>[set perso(phw)]</PHW>"
    puts $file_id "   <PHM>[set perso(phm)]</PHM>\n   <MOB>[set perso(mob)]</MOB>\n   <MBE>[set perso(mbe)]</MBE>"

    foreach group [::groups::GetList] {
	puts $file_id "   <Group>\n      <gid>${group}</gid>\n      <name>[::groups::GetName $group]</name>\n   </Group>"
    }

    puts $file_id "   <AL>"


    foreach user $list_al { 
	set user [string map { "<" "&lt;" "&" "&amp;" "\"" "&quot;" "'" "&apos;"} $user]
	puts $file_id "      <user>\n         <email>[lindex $user 0]</email>\n         <nickname>[lindex $user 1]</nickname>\n      </user>"
    }

    puts $file_id "   </AL>\n\n   <BL>"

    foreach user $list_bl { 
	set user [string map { "<" "&lt;" "&" "&amp;" "\"" "&quot;" "'" "&apos;"} $user]
	puts $file_id "      <user>\n         <email>[lindex $user 0]</email>\n         <nickname>[lindex $user 1]</nickname>\n      </user>"
    }
    
    puts $file_id "   </BL>\n\n   <RL>"

    foreach user $list_rl { 
	set user [string map { "<" "&lt;" "&" "&amp;" "\"" "&quot;" "'" "&apos;"} $user]
	puts $file_id "      <user>\n         <email>[lindex $user 0]</email>\n         <nickname>[lindex $user 1]</nickname>\n      </user>"
    }

    puts $file_id "   </RL>\n\n   <FL>"

    foreach user $list_fl { 
	::abook::getContact [lindex $user 0] userd
       	set user [string map { "<" "&lt;" "&" "&amp;" "\"" "&quot;" "'" "&apos;"} $user]
	puts $file_id "      <user>\n         <email>[lindex $user 0]</email>\n         <nickname>[lindex $user 1]</nickname>"
	puts $file_id "         <gid>[join [::abook::getGroup [lindex $user 0] -id] ,]</gid>\n         <PHH>[set userd(phh)]</PHH>"
	puts $file_id "         <PHW>[set userd(phw)]</PHW>\n         <PHM>[set userd(phm)]</PHM>\n         <MOB>[set userd(mob)]</MOB>"
	puts $file_id "\n      </user>"
    }

    puts $file_id "   </FL>\n</contactlist_${list_version}>\n"

    close $file_id


}


proc create_contact_list {cstack cdata saved_data cattr saved_attr args } {
    global list_al list_bl list_rl list_fl

    upvar $saved_data sdata 
    
    set list "list_[string range $cstack end-6 end-5]"

    if { $list == "list_fl" } {
	::abook::setContact $sdata(${cstack}:email) group $sdata(${cstack}:gid)
	::abook::setContact $sdata(${cstack}:email) nick $sdata(${cstack}:nickname)
	::abook::setContact $sdata(${cstack}:email) PHH $sdata(${cstack}:phh)
	::abook::setContact $sdata(${cstack}:email) PHW $sdata(${cstack}:phw)
	::abook::setContact $sdata(${cstack}:email) PHM $sdata(${cstack}:phm)
	::abook::setContact $sdata(${cstack}:email) MOB $sdata(${cstack}:mob)
    }

    set contactinfo ""

    lappend contactinfo "$sdata(${cstack}:email)"
    lappend contactinfo "$sdata(${cstack}:nickname)"

    lappend ${list} "$contactinfo"


    return 0
}

proc create_group { cstack cdata saved_data cattr saved_attr args } {
    upvar $saved_data sdata 

    ::groups::Set $sdata(${cstack}:gid) "$sdata(${cstack}:name)"
    return 0
}


proc create_null { cstack cdata saved_data cattr saved_attr args } {

    #puts "mv $cstack > /dev/null"
    return 0
}


proc finished_loading_list { cstack cdata saved_data cattr saved_attr args } { 
    global list_BLP
    upvar $saved_data sdata 

    set list_BLP $sdata(${cstack}:blp)

    ::abook::setPersonal PHH $sdata(${cstack}:phh)
    ::abook::setPersonal PHW $sdata(${cstack}:phw)
    ::abook::setPersonal PHM $sdata(${cstack}:phm)
    ::abook::setPersonal MOB $sdata(${cstack}:mob)
    ::abook::setPersonal MBE $sdata(${cstack}:mbe)


    list_users_refresh
    return 0
}


proc clean_contact_lists {} {
    global list_version list_al list_fl list_bl list_rl list_users list_BLP emailBList

    set list_version 0
    set list_al [list]
    set list_bl [list]
    set list_fl [list]
    set list_rl [list]
    set list_users [list]
    set list_BLP -1
    if { [info exists emailBList] } {
	unset emailBList
    }
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
