#	Microsoft Messenger Protocol Implementation
# $Id$
#=======================================================================

namespace eval ::MSN {
   namespace export changeName logout changeStatus connect blockUser \
   unblockUser addUser deleteUser login myStatusIs inviteFT acceptFT rejectFT \
   cancelReceiving cancelSending getMyIP moveUser

   variable myStatus FLN

   proc connect { username password } {
      
      #cmsn_ns_connect $username $password
      
      if {[catch { cmsn_ns_connect $username $password } res]} {
        msg_box "[trans connecterror]"
	
        sb set ns stat "d"
        cmsn_draw_offline

      }
      
      ::MSN::TogglePolling
      
      #Alert dock of status change
      send_dock "NLN"
   }

   proc logout {} {
      global config
      variable myStatus
      catch {puts -nonewline [sb get ns sock] "OUT\r\n"} res

      set myStatus FLN
      status_log "Loging out\n"

      if {$config(adverts)} {
         adv_pause
      }

      ::groups::Disable

      cmsn_draw_offline
      #Alert dock of status change
      send_dock "FLN"
   }




   proc changeName { userlogin newname } {
      set name [urlencode $newname]
      if { [string length $name] > 350} {
        set name [string range $name 0 350]
      }
      ::MSN::WriteNS "REA" "$userlogin $name"
   }


   proc changeStatus {new_status} {
      variable myStatus
      ::MSN::WriteNS "CHG" $new_status
      status_log "Changing state to $new_status\n" red
      set myStatus $new_status
   }

   proc myStatusIs {} {
       variable myStatus
       return $myStatus
   }

   proc blockUser { userlogin username} {
     ::MSN::WriteNS REM "AL $userlogin"
     ::MSN::WriteNS ADD "BL $userlogin $userlogin"
   }

   proc unblockUser { userlogin username} {
      ::MSN::WriteNS REM "BL $userlogin"
      ::MSN::WriteNS ADD "AL $userlogin $username"
   }
   
   # Move user from one group to another group
   proc moveUser { passport oldGid newGid {userName ""}} {
      if { $userName == "" } {
        set userName $passport
      }
      set rtrid [::MSN::WriteNS "REM" "FL $passport $oldGid"]
      set atrid [::MSN::WriteNS "ADD" "FL $passport [urlencode $userName] $newGid"]

   }

   proc copyUser { passport oldGid newGid {userName ""}} {
      if { $userName == "" } {
        set userName $passport
      }
      set atrid [::MSN::WriteNS "ADD" "FL $passport [urlencode $userName] $newGid"]
   }
   
   
   proc addUser { userlogin {username ""}} {
      if { $username == "" } {
        set username $userlogin
      }
      ::MSN::WriteNS "ADD" "FL $userlogin $username 0"   
   }
   
   proc deleteUser { userlogin } {
      ::MSN::WriteNS REM "FL $userlogin"
   }   

   proc inviteFT { sbn filename cookie ipaddr} {
      #Invitation to filetransfer, initial message
      variable trid 
      variable atransfer

      if { [catch {set filesize [file size $filename]} res]} {
	::amsn::errorMsg "[trans filedoesnotexist]"
	::amsn::fileTransferProgress c $cookie -1 -1
	return 1
      }
      set sock [sb get $sbn sock]

      set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
      set msg "${msg}Application-Name: File Transfer\r\n"
      set msg "${msg}Application-GUID: {5D3E02AB-6190-11d3-BBBB-00C04F795683}\r\n"     
      set msg "${msg}Invitation-Command: INVITE\r\n"
      set msg "${msg}Invitation-Cookie: $cookie\r\n"
      set msg "${msg}Application-File: [file tail $filename]\r\n"
      set msg "${msg}Application-FileSize: $filesize\r\n\r\n"
      set msg_len [string length $msg]

      incr trid
      puts $sock "MSG $trid N $msg_len"
      set msg [encoding convertto utf-8 $msg]
      puts -nonewline $sock $msg

      status_log "Invitation to $filename sent\n" red

      #Change to allow multiple filetransfer
      set atransfer($cookie) [list $sbn $filename $filesize $cookie $ipaddr]

   }

   proc acceptFT {sbn filename filesize cookie} {
      #Send the acceptation for a file transfer, request IP
      variable atransfer
      set sock [sb get $sbn sock]

      set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
      set msg "${msg}Invitation-Command: ACCEPT\r\n"
      set msg "${msg}Invitation-Cookie: $cookie\r\n"
      set msg "${msg}Launch-Application: FALSE\r\n"
      set msg "${msg}Request-Data: IP-Address:\r\n\r\n"

      set msg_len [string length $msg]
      incr ::MSN::trid
      puts $sock "MSG $::MSN::trid N $msg_len"
      puts -nonewline $sock $msg

      set atransfer($cookie) [list $sbn $filename $filesize $cookie]      

   }


   proc rejectFT {sbn cookie} {
      #Send the cancelation for a file transfer
      set sock [sb get $sbn sock]

      set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
      set msg "${msg}Invitation-Command: CANCEL\r\n"
      set msg "${msg}Invitation-Cookie: $cookie\r\n"
      set msg "${msg}Cancel-Code: REJECT\r\n\r\n"

      set msg_len [string length $msg]
      incr ::MSN::trid
      puts $sock "MSG $::MSN::trid N $msg_len"
      puts -nonewline $sock $msg      

      status_log "Rejecting filetransfer sent\n" red

   }


   proc cancelReceiving {cookie} {
      variable atransfer
      status_log "Canceling receiving (TO-DO)\n"
      set sockid [lindex $atransfer($cookie) 4]
      set sbn [lindex $atransfer($cookie) 0]

      if { $sockid != ""} {
         catch {
	    puts $sockid "CCL\r"
	    close $sockid
	  } res
	 ::amsn::fileTransferProgress c $cookie -1 -1
	 array unset atransfer $cookie
      } else {
         status_log "unsetting atransfer\n"
         array unset atransfer $cookie
	 ::amsn::fileTransferProgress c $cookie -1 -1
      }
   }


   proc cancelSending {cookie} {
      variable atransfer
      status_log "Canceling sending\n"
      set sockid [lindex $atransfer($cookie) 5]
      set sbn [lindex $atransfer($cookie) 0]

      #Avoid sending the file
      if { $sockid != "" } {
         catch {
	    close $sockid
	 } res
         ::amsn::fileTransferProgress c $cookie -1 -1
         array unset atransfer $cookie
      } else {
         status_log "unsetting atransfer\n"
         array unset atransfer $cookie
	 ::amsn::fileTransferProgress c $cookie -1 -1
      }
   }

   proc getMyIP {} {
      global config
      set sock [sb get ns sock]

      status_log "Called getmyip"
      
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
	set idx [string first "\n" $ip]
	set ip [string range $ip 0 [expr $idx-1] ]
	status_log "$ip\n$token"
	
	::http::cleanup $token
      	unset token
      }

      return $ip
   }


   #Internal procedures

   proc TogglePolling {} {
      global config

      if {$config(keepalive) == 1 } {
      	after 60000 "::MSN::PollConnection"
      } else {
      	after cancel "::MSN::PollConnection"
      }
   }

   proc PollConnection {} {
      variable myStatus

      #Let's try to keep the connection alive... sometimes it gets closed if we
      #don't do send or receive something for a long time

      if { $myStatus != "FLN" } {
         #::MSN::WriteNS "CHG" $myStatus
	::MSN::WriteNS "REA" "dummy@dummy.com"
      }

      after 120000 "::MSN::PollConnection"
   }

   variable trid 0
   variable atransfer

   proc WriteSB {sbn cmd param {handler ""}} {
      variable trid
      incr trid
      
      puts [sb get $sbn sock] "$cmd $trid $param\r"
      degt_protocol "->SB $cmd $trid $param"

      if {$handler != ""} {
         global list_cmdhnd
         lappend list_cmdhnd [list $trid $handler]
      }
   }


   proc WriteNS {cmd param {handler ""}} {
      variable trid
      set thistrid [incr trid]

      puts -nonewline [sb get ns sock] "$cmd $thistrid $param\r\n"
      degt_protocol "->NS $cmd $thistrid $param"

      if {$handler != ""} {
         global list_cmdhnd
         lappend list_cmdhnd [list $thistrid $handler]
      }
      return $thistrid
   }


   #New protocol by AIM, challenges
   proc AnswerChallenge { item } {
      if { [lindex $item 1] != 0 } {
        status_log "Invalid challenge\n" white
      } else {
        set cadenita [lindex $item 2]Q1P7W2E4J9R8U3S5
        set cadenita [::md5::md5 $cadenita]
        ::MSN::WriteNS "QRY" "msmsgs@msnmsgr.com 32"
        puts -nonewline [sb get ns sock] $cadenita
      }
   }


   #All about sending files
   
   proc SendFile {cookie sbn} {
      #File transfer accepted by remote, send final ACK
      variable atransfer
      variable trid

      if {[info exists atransfer($cookie)] == 0} {
        status_log "Ignoring file transfer, cancelled\n"
        return 1
      }
      
      status_log "atransfer: $atransfer($cookie)\n"
      
      status_log "File transfer ok, begin\n"

      set sock [sb get $sbn sock]

      #Invitation accepted, send IP and Port to connect to
      #option: posibility to enter IP address (firewalled connections)
      set ipaddr [lindex $atransfer($cookie) 4]
      #if error ::AMSN::Error ...

      #A configurable port needed for firewalled connections
      set port 6891

      #Random authcookie
      set authcookie [expr {$trid * $port % (65536 * 4)}]
	
      while {[catch {set sockid [socket -server "::MSN::AcceptConnection $cookie $authcookie" $port]} res]} {
         incr port
      }

      after 120000 "status_log \"Closing $sockid\n\";close $sockid"

      set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
      set msg "${msg}Invitation-Command: ACCEPT\r\n"
      set msg "${msg}Invitation-Cookie: $cookie\r\n"
      set msg "${msg}IP-Address: $ipaddr\r\n"
      set msg "${msg}Port: $port\r\n"
      set msg "${msg}AuthCookie: $authcookie\r\n"
      set msg "${msg}Launch-Application: FALSE\r\n"
      set msg "${msg}Request-Data: IP-Address:\r\n\r\n"


      set msg_len [string length $msg]
      incr trid
      puts $sock "MSG $trid N $msg_len"
      puts -nonewline $sock $msg

      ::amsn::fileTransferProgress p $cookie $port 0

      status_log "Listening on port $port for incoming connections...\n" red

   }

   proc SendFileRejected {cookie cancelcode} {
      status_log "Invitation cookie $cookie CANCELED: $cancelcode\n"
      ::amsn::fileTransferProgress c $cookie -1 -1
      array unset atransfer $cookie
   }

   proc AcceptConnection {cookie authcookie sockid hostaddr hostport} {
      #Someone connects to my host to get the file i offer
      variable atransfer

      lappend atransfer($cookie) $sockid

      status_log "Conexión aceptada sockid: $sockid hostaddr: $hostaddr port: $hostport\n" white
      fconfigure $sockid -blocking 1 -buffering none -translation {binary binary}

      gets $sockid tmpdata
      status_log "RECIBO: $tmpdata\n"
      if { [string range $tmpdata 0 9] == "VER MSNFTP"} {
         puts $sockid "VER MSNFTP\r"

         status_log "ENVIO: VER MSNFTP\n"
         gets $sockid tmpdata
         status_log "Recibo: $tmpdata\n"


         #Comprobar authcookie
         if { [string range $tmpdata 0 2] == "USR" } {
            set filename [lindex $atransfer($cookie) 1]
            set filesize [lindex $atransfer($cookie) 2]
            set cookie [lindex $atransfer($cookie) 3]

            puts $sockid "FIL $filesize\r"
            status_log "ENVIO: FIL $filesize\n"

            gets $sockid tmpdata
            status_log "Recibo: $tmpdata\n"
            if { [string range $tmpdata 0 2] == "TFR" } {

               #Send the file

               if {[catch {set fileid [open $filename r]} res]} {
	         return 0;
	       }
               fconfigure $fileid -translation {binary binary} -blocking 1
               status_log "Sending file $filename size $filesize\n"

               fconfigure $sockid -blocking 0
	       fileevent $sockid writable "::MSN::SendPacket $sockid $fileid $filesize $cookie"
               fileevent $sockid readable "::MSN::MonitorTransfer $sockid $cookie"

	       return 0

            }
         }
      }
      status_log "Transferencia cancelada\n"
      ::amsn::fileTransferProgress c $cookie -1 -1
      close $sockid
      return 1

   }

   proc SendPacket { sockid fileid filesize cookie } {
      #Send a packet for the file transfer
      fileevent $sockid writable ""
      
      set sentbytes [tell $fileid]


      if {[expr {$filesize-$sentbytes >2045}]} {
         set packetsize 2045
      } else {
         set packetsize [expr {$filesize-$sentbytes}]
      }

   
      if {$packetsize>0} {
         set datos [read $fileid $packetsize]
	  
         set byte1 [expr {$packetsize & 0xFF}]
         set byte2 [expr {$packetsize >> 8}]
	  
         if {[catch {
	    puts -nonewline $sockid "\0[format %c $byte1][format %c $byte2]$datos"
	 } res]} {
	   cancelSending $cookie
	   return
	 }
         set sentbytes [expr {$sentbytes + $packetsize}]
	 ::amsn::fileTransferProgress s $cookie $sentbytes $filesize
         fileevent $sockid writable "::MSN::SendPacket $sockid $fileid $filesize $cookie"

      } else {
         close $fileid
         variable atransfer
         array unset atransfer $cookie      
         ::amsn::fileTransferProgress s $cookie $filesize $filesize
	 status_log "All file content sent\n"

      }
      
   }

   proc MonitorTransfer { sockid cookie} {
      #Monitor messages from the receiving host in a file transfer
      fconfigure $sockid -blocking 1
      gets $sockid datos
      fconfigure $sockid -blocking 0
      status_log "Recibido del receptor: $datos\n"
      if {[string range $datos 0 2] == "CCL"} {
         status_log "Connection cancelled\n"
	 cancelSending $cookie
         return
      }
  
      if {[string range $datos 0 2] == "BYE"} {
         status_log "Connection finished\n"
         close $sockid
         return
      }
      if {[eof $sockid]} {
         status_log "EOF in connection\n"
         cancelSending $cookie
         return
      }

   }


   #All about receiving files


   proc ConnectMSNFTP {ipaddr port authcookie filename cookie} {
      #I connect to a remote host to retrive the file
      variable atransfer

      if {[info exists atransfer($cookie)] == 0} {
        status_log "Ignoring file transfer, atransfer(\$cookie) doesn't exists, cancelled\n"
        return 1
      }

      status_log "Connecting to $ipaddr port $port\n"

      set sockid [socket -async $ipaddr $port]
      set cancelid [after 10000  ::MSN::cancelReceiving $cookie]

      fconfigure $sockid -blocking 0
      fileevent $sockid writable "::MSN::ConnectedMSNFTP $sockid $cancelid $authcookie \"$filename\" $cookie"

      return 1

   }

   proc ConnectedMSNFTP {sockid cancelid authcookie filename cookie} {
      global config files_dir
      variable atransfer

      fileevent $sockid writable {}
      after cancel $cancelid

      lappend atransfer($cookie) $sockid

      fconfigure $sockid -blocking 1 -buffering none -translation {binary binary}

      status_log "Connected, going to give my identity\n"
      puts $sockid "VER MSNFTP\r"
      status_log "I SEND: VER MSNFTP\r\n"
      gets $sockid tmpdata
      status_log "I RECEIVE: $tmpdata\n"
      if {[string range $tmpdata 0 9] == "VER MSNFTP"} {
         puts $sockid "USR $config(login) $authcookie\r"
         status_log "I SEND: USR $config(login) $authcookie\r\n"

         gets $sockid tmpdata
         status_log "I RECEIVE: $tmpdata\n"

         if {[string range $tmpdata 0 2] == "FIL"} {
            set filesize [string range $tmpdata 3 [string length $tmpdata]]
            status_log "They send me file $filename with size $filesize\n"

            puts $sockid "TFR\r"

            status_log "Receiving file...\n"

            set origfile [file join ${files_dir} $filename]
	    set filename $origfile
	    set num 1
            while { [file exists $filename] } {
	      set filename "$origfile.$num"
	      incr num
	    }

            set fileid [open $filename w]
            fconfigure $fileid -blocking 1 -buffering none -translation {binary binary}

            #Receive the file

            fconfigure $sockid -blocking 0
            fileevent $sockid readable "catch {::MSN::ReceivePacket $sockid $fileid $filesize $cookie} res"

            return 0
         }

      }

      ::amsn::fileTransferProgress c $cookie -1 -1
      status_log "Transfer failed, connection closed\n"
      close $sockid
      return 1
   }


   proc ReceivePacket { sockid fileid filesize cookie} {
      #Get a packet from the file transfer

     fileevent $sockid readable ""

     set recvbytes [tell $fileid]
     set packetrest [expr {2045 - ($recvbytes % 2045)}]

      if {$packetrest == 2045} {
         #Need a full packet, header included

         fconfigure $sockid -blocking 1
         set header [read $sockid 3]

         set packet1 1
         binary scan $header ccc packet1 packet2 packet3

         #If packet1 is 1 -- Transfer canceled by the other
         if { ($packet1 != 0) } {
            status_log "File transfer cancelled by remote with packet1=$packet1\n"

	    ::amsn::fileTransferProgress c $cookie -1 -1

            close $fileid
            close $sockid
	    return

         }

         #If you want to cancel, send "CCL\n"
         set packet2 [expr {($packet2 + 0x100) % 0x100}]
         set packet3 [expr {($packet3 + 0x100) % 0x100}]
         set packetsize [expr {$packet2 + ($packet3<<8)}]

         set firstbyte [read $sockid 1]
         puts -nonewline $fileid $firstbyte

         fconfigure $sockid -blocking 0

         set recvbytes [tell $fileid]
         ::amsn::fileTransferProgress r $cookie $recvbytes $filesize


      } else {
         #A full packet didn't come the previous reading, read the rest
         set thedata [read $sockid $packetrest]
         puts -nonewline $fileid $thedata
         set recvbytes [tell $fileid]     
      }   	

      if { $recvbytes >= $filesize} {
         ::amsn::fileTransferProgress r $cookie $recvbytes $filesize
         puts $sockid "BYE 16777989\r"
	 variable atransfer	
         array unset atransfer $cookie
         status_log "File received\n"
	
         close $fileid
         close $sockid
	 return
      } else {
         fileevent $sockid readable "::MSN::ReceivePacket $sockid $fileid $filesize $cookie"
	 return
      }
   }


}



proc read_sb_sock {sbn} {

   set sb_sock [sb get $sbn sock]
   if {[eof $sb_sock]} {
      close $sb_sock
      cmsn_sb_sessionclosed $sbn
   } else {
      gets $sb_sock tmp_data
      sb append $sbn data $tmp_data
      set log [string map {\r ""} $tmp_data]
      degt_protocol "<-SB $tmp_data"
      if {[string range $tmp_data 0 2] == "MSG"} {
         set recv [split $tmp_data]
	 fconfigure $sb_sock -blocking 1
	 set msg_data [read $sb_sock [lindex $recv 3]]
	 fconfigure $sb_sock -blocking 0
	 sb append $sbn data $msg_data
      }
   }

}


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
         return [llength $sb_data]
      }
      search {
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

proc read_ns_sock {} {
   global ns_data ns_stat unread config password

   set ns_sock [sb get ns sock]
   if {[eof $ns_sock]} {
      close $ns_sock
      sb set ns stat "d"
      status_log "Closing NS socket!\n" red

      ::MSN::logout
   } else {
      gets $ns_sock tmp_data

      set log [string map {\r ""} $tmp_data]

      degt_protocol "<-NS $tmp_data"

      sb append ns data $tmp_data		 

      if {[string range $tmp_data 0 2] == "MSG"} {

         set recv [split $tmp_data]
	 fconfigure $ns_sock -blocking 1
	 set msg_data [read $ns_sock [lindex $recv 3]]
	 status_log "MSGDATA: $msg_data " green

	 # Demographic Information about subscriber/user. Can be used
	 # for a variety of things. 
	 set content [aim_get_str $msg_data Content-Type]
	 if {[string range $content 0 19] == "text/x-msmsgsprofile"} {
             status_log "Getting demographic and auth information" black
	     # 1033 is English. See XXXX for info
	     set d(langpreference) [aim_get_str $msg_data lang_preference]
	     set d(preferredemail) [aim_get_str $msg_data preferredEmail]
	     set d(country) [aim_get_str $msg_data country]
	     set d(gender) [aim_get_str $msg_data Gender]
	     set d(kids) [aim_get_str $msg_data Kid]
	     set d(age) [aim_get_str $msg_data Age]
	     #Used for authentication
	     set d(mspauth) [aim_get_str $msg_data MSPAuth]
	     set d(kv) [aim_get_str $msg_data kv]
	     set d(sid) [aim_get_str $msg_data sid]
	     set d(sessionstart) [clock seconds]
	     ::abook::setDemographics d
	 }

	 fconfigure $ns_sock -blocking 0
         sb append ns data $msg_data
      } 
   }

}


proc proc_sb {} {
   global sb_list

   foreach sbn $sb_list {
      while {[sb length $sbn data]} {
         set item [split [sb index $sbn data 0]]

         set result [cmsn_sb_handler $sbn $item]
         if {$result == 0} {
	    sb ldel $sbn data 0
         } else {
            status_log "problem processing SB data!\n" red
	    return 0
         } ;# if

      } ;# while
   } ;# foreach

   after 250 proc_sb
   return 1
}

proc proc_ns {} {



   while {[sb length ns data]} {

      set item [split [sb index ns data 0]]

      set result [cmsn_ns_handler $item]
      if {$result == 0} {
	 sb ldel ns data 0
      } else {
         status_log "problem processing NS data!\n" red
	 return 0
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

proc cmsn_sb_msg {sb_name recv} {
   global filetoreceive files_dir

   set msg [sb index $sb_name data 1]
 
   sb ldel $sb_name data 1
   array set headers {}
   set body ""
   cmsn_msg_parse $msg headers body

   set content [lindex [array get headers content-type] 1]
   set timestamp [clock format [clock seconds] -format %H:%M]

   set typer [string tolower [lindex $recv 1]]
   after cancel "catch \{set idx [sb search $sb_name typers $typer];sb ldel $sb_name typers \$idx;cmsn_show_typers $sb_name\} res"      

   if {[string range $content 0 9] == "text/plain"} {

      set fonttype [lindex [array get headers x-mms-im-format] 1]
      
      set begin [expr {[string first "FN=" $fonttype]+3}]
      set end   [expr {[string first ";" $fonttype $begin]-1}]      
      set fontfamily \{[urldecode [string range $fonttype $begin $end]]\}

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
      

      cmsn_win_write $sb_name \
        "\[$timestamp\] [trans says [urldecode [lindex $recv 2]]]:\n" gray


      cmsn_win_write $sb_name "$body\n" user $fontfamily $style $fontcolor      



      sb set $sb_name lastmsgtime [clock format [clock seconds] -format %H:%M:%S]
      
      set idx [sb search $sb_name typers $typer]
      sb ldel $sb_name typers $idx
      cmsn_show_typers $sb_name
      
      cmsn_msgwin_flicker $sb_name 20     
      set win_name "msg_[string tolower ${sb_name}]"

      if { [string compare [wm state .${win_name}] "withdrawn"] == 0 } {
        wm state .${win_name} iconic
	::amsn::notifyAdd "[trans says [urldecode [lindex $recv 2]]]:\n$body" \
	   "wm state .${win_name} normal; focus -force .${win_name}.in.input"; #; grab .${win_name}"
      }            

      if { [string first $win_name [focus]] != 1 } {
        sonido type
      }
      
   } elseif {[string range $content 0 19] == "text/x-msmsgscontrol"} {
    
      if {[llength $typer]} {
	 set idx [sb search $sb_name typers $typer]
	 if {$idx == -1} {
            sb append $sb_name typers $typer
	 } 
	 
         cmsn_show_typers $sb_name
	 
	 after 8000 "catch \{set idx [sb search $sb_name typers $typer];sb ldel $sb_name typers \$idx;cmsn_show_typers $sb_name\} res"

      }

   } elseif {[string range $content 0 18] == "text/x-msmsgsinvite"} {
#File transfers
      set invcommand [aim_get_str $body Invitation-Command]
      set cookie [aim_get_str $body Invitation-Cookie]
      if { $invcommand == "ACCEPT" } {
      
      	set requestdata [aim_get_str $body Request-Data]
	set requestdata [string range $requestdata 0 [expr {[string length requestdata] -2}]]
	
	set data [aim_get_str $body $requestdata]
	
	if { $data == "" } {
  	  status_log "Invitation cookie $cookie ACCEPTED\n" white
	  ::MSN::SendFile $cookie $sb_name  
	} else {
	  set ipaddr $data
	  set port [aim_get_str $body Port]
	  set authcookie [aim_get_str $body AuthCookie]
	  status_log "Body: $body\n"
          ::MSN::ConnectMSNFTP $ipaddr $port $authcookie [lindex $filetoreceive 0] $cookie
	  
	}		

	

      } elseif {$invcommand =="CANCEL" } {
        set cancelcode [aim_get_str $body Cancel-Code]	
	::MSN::SendFileRejected $cookie $cancelcode
      } elseif {$invcommand == "INVITE" } {
         set body [encoding convertfrom utf-8 $body]
         set app [aim_get_str $body Application-Name]	
         set guid [aim_get_str $body Application-GUID]	
	 set cookie [aim_get_str $body Invitation-Cookie]
	 set filename [aim_get_str $body Application-File]	 
	 set filesize [aim_get_str $body Application-FileSize]
	 status_log "Invited to $app\n" white
	 status_log "$body\n" black

         set fromlogin [lindex $recv 1]	 
         set fromnick "[urldecode [lindex $recv 2]]"
	 
	 if {[string range $guid 0 37] == "{5D3E02AB-6190-11d3-BBBB-00C04F795683}"}	 {
  	   ::amsn::fileTransferRecv $filename $filesize $cookie $sb_name $fromlogin $fromnick
  	   set filetoreceive [list $filename $filesize]
         }
	
      } else {
        status_log "Unknown invitation!!\n" white
      }
   } else {
      status_log "=== UNKNOWN MSG ===\n$msg\n" white
   }

}


proc cmsn_sb_handler {sb_name item} {
   global list_cmdhnd

   set item [encoding convertfrom utf-8 $item]

   set ret_trid [lindex $item 1]
   set idx [lsearch $list_cmdhnd "$ret_trid *"]
   if {$idx != -1} {		;# Command has a handler associated!
      eval "[lindex [lindex $list_cmdhnd $idx] 1] {$item}"
      status_log "evaluating handler for $ret_trid\n"
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
	 return 0
      }
      ANS {
         status_log "$sb_name: [join $item]\n" green
	 return 0
      }
      default {
         status_log "$sb_name: UNKNOWN SB ENTRY! --> [join $item]\n" red
	 return 0
      }
   }
   }
}

proc cmsn_invite_user {name user} {
   status_log "$name: Inviting $user\n" green
   ::MSN::WriteSB $name "CAL" $user
}

proc cmsn_chat_user {user} {
   global msg_windows

   if { ([::MSN::myStatusIs] == "HDN") || ([::MSN::myStatusIs] == "FLN") } {
       msg_box "[trans needonline]"
       return
   }
   
   set lowuser [string tolower ${user}]
   
   if { [info exists msg_windows(${lowuser})] } {
	wm state .msg_$msg_windows($lowuser) normal
	wm deiconify .msg_$msg_windows($lowuser)
   	raise .msg_$msg_windows($lowuser)
   	focus .msg_$msg_windows($lowuser).in.input
	upvar #0 [sb name $msg_windows($lowuser) users] users_list
	if { [llength $users_list] == 0 } {
		cmsn_reconnect $msg_windows($lowuser)
	}
	return 0
   }
	
   set name [cmsn_draw_msgwin $user]

   status_log "name is : $name"
   if { $name == 0 } {
   	return
   }
 
   sb set $name stat "r"
   sb set $name invite $user

   status_log "$name: CHAT1 Talking with $user\n" green
   ::MSN::WriteNS "XFR" "SB" "cmsn_open_sb $name"
   
   cmsn_msgwin_top $name "[trans chatreq]..."
#   if [catch { cmsn_msgwin_top $name "[trans chatreq]..."} res]  {
#     msg_box "Ventana de chat ya cerrada"
#      puts [sb get $name sock] "OUT"
#      close [sb get $name sock]
#   } 

   set win_name "msg_[string tolower ${name}]"
   wm state .${win_name} normal

}

proc cmsn_open_sb {sbn recv} {
   global config

   if {[lindex $recv 4] != "CKI"} {
      status_log "$sbn: Unknown SP requested!\n" red
      return 1
   }teNS "XFR" "SB" "cmsn_open_sb $name"
   
   cmsn_msgwin_top $name "[trans chatreq]..."
#   if [catch { cmsn_msgwin_top $name "[trans chatreq]..."} res]  {
#     msg_box "Ventana de chat ya cerrada"
#      puts [sb get $name sock] "OUT"
#      close [sb get $name sock]
#   } 

   set win_name "msg_[string tolower ${name}]"
   wm state .${win_name} normal

}

proc cmsn_rng {recv} {
   global config msg_windows

   set emaill [lindex $recv 5]

   if { [info exists msg_windows($emaill)] } {
   	set sbn $msg_windows($emaill)
	
	catch { close [sb get $sbn sock] }

   } else {
   	set sbn [cmsn_draw_msgwin $emaill]
   }
   
   sb set $sbn serv [split [lindex $recv 2] ":"]
   sb set $sbn connected "cmsn_conn_ans $sbn"
   sb set $sbn readable "read_sb_sock $sbn"
   sb set $sbn auth_cmd "ANS"
   sb set $sbn auth_param "$config(login) [lindex $recv 4] [lindex $recv 1]"

   status_log "$sbn: ANS1 answering [lindex $recv 5]\n" green
   cmsn_msgwin_top $sbn "[trans chatack] [lindex $recv 5]..."
   
   cmsn_socket $sbn
   return 0
}

proc cmsn_open_sb {sbn recv} {
   global config

   if {[lindex $recv 4] != "CKI"} {
      status_log "$sbn: Unknown SP requested!\n" red
      return 1
   }

   sb set $sbn serv [split [lindex $recv 3] ":"]
   sb set $sbn connected "cmsn_conn_sb $sbn"
   sb set $sbn readable "read_sb_sock $sbn"
   sb set $sbn auth_cmd "USR"
   sb set $sbn auth_param "$config(login) [lindex $recv 5]"

   status_log "$sbn: CHAT2: connecting to Switch Board [lindex $recv 3]\n"   


   if {[catch { cmsn_msgwin_top $sbn "[trans sbcon]..."} res]}  {
     status_log "Ignoring: Chat window $sbn has been closed\n"
   } else {
     cmsn_socket $sbn
   }
   return 0
}

proc cmsn_conn_sb {name} {
   fileevent [sb get $name sock] writable {}
   sb set $name stat "a"
   set cmd [sb get $name auth_cmd]; set param [sb get $name auth_param]
   ::MSN::WriteSB $name $cmd $param "cmsn_connected_sb $name"
   cmsn_msgwin_top $name "[trans ident]..."
}

proc cmsn_conn_ans {name} {
   fileevent [sb get $name sock] writable {}
   sb set $name stat "a"
   set cmd [sb get $name auth_cmd]; set param [sb get $name auth_param]
   ::MSN::WriteSB $name $cmd $param
   cmsn_msgwin_top $name "[trans ident]..."
}

proc cmsn_connected_sb {name recv} {
   sb set $name stat "i"
   if {[sb exists $name invite]} {
      cmsn_invite_user $name [sb get $name invite]
      cmsn_msgwin_top $name \
        "[trans willjoin [sb get $name invite]]..."
   }
}

proc cmsn_reconnect {name} {
   if {[sb get $name stat] == "n"} {
      sb set $name stat "i"
      cmsn_invite_user $name [lindex [sb get $name last_user] 0]
      cmsn_msgwin_top $name \
         "[trans reconnect [sb get $name last_user]]..."
   } elseif {[sb get $name stat] == "d"} {

 	status_log "Calling reconnect with d tag"
   
      sb set $name stat "rc"
      sb set $name invite [lindex [sb get $name last_user] 0]
      ::MSN::WriteNS "XFR" "SB" "cmsn_open_sb $name"
      cmsn_msgwin_top $name "[trans reconnecting]..."
   }
}




proc cmsn_ns_handler {item} {
   global list_cmdhnd password config
   
   set item [encoding convertfrom utf-8 $item]
   set item [string map {\r ""} $item]

   set ret_trid [lindex $item 1]
   set idx [lsearch $list_cmdhnd "$ret_trid *"]
   if {$idx != -1} {		;# Command has a handler associated!
      eval "[lindex [lindex $list_cmdhnd $idx] 1] \"$item\""
      status_log "evaluating handler for $ret_trid\n"
      return 0
   } else {
   switch [lindex $item 0] {
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
            cmsn_ns_connect $config(login) $password
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
         global user_info config
	      status_log "Item: $item\n" white
	      if { [lindex $item 3] == $config(login) } {
            set user_info $item
   	      cmsn_draw_online
	      }
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
      MSG {
         cmsn_ns_msg $item
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
	       send_dock [lindex $item 2]
	     }
         return 0
      }
      GTC -
      BLP -
      SYN {
	 return 0
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
      OUT {	# Remove Group
      	if { [lindex $item 1] == "OTH"} {
	  msg_box "[trans loggedotherlocation]"
	  return 0
	} else {
	  msg_box "[trans servergoingdown]"
	  return 0
	}
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
          status_log "Warning: Contact does not exist $item\n" red
	  msg_box "[trans contactdoesnotexist]"
          return 0
      }
      206 {
          status_log "Warning: Domain name missing $item\n" red
	  msg_box "[trans contactdoesnotexist]"
          return 0
      }
      209 {
          status_log "Warning: Invalid username $item\n" red
	  msg_box "[trans invalidusername]"
          return 0
      }
      215 {
          status_log "Warning: Domain name missing $item\n" red
	  msg_box "[trans useralreadyonlist]"
          return 0
      }
      911 {
          status_log "Error: User/Password\n" red
	  set password ""
	  ::amsn::errorMsg "[trans baduserpass]"
          return 0
      }     
      913 {
          status_log "Error: Not allowed when offline\n" red
	  msg_box "[trans notallowedoffline]"
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

   set msg [sb index ns data 1]
   sb ldel ns data 1
   
   if { [lindex $recv 1] == "Hotmail" && [lindex $recv 2] == "Hotmail"} {
     hotmail_procmsg $msg
   } else {   
     status_log "[lindex $recv 2] ([lindex $recv 1]) says:\n" green
     status_log "$msg\n" green
     status_log "=========================================\n" green
   }
}


proc cmsn_listdel {recv} {
   ::MSN::WriteNS "LST" "[lindex $recv 2]"
}

proc cmsn_auth {{recv ""}} {
   global config


   switch [sb get ns stat] {
      c {
#New version of protocol
         ::MSN::WriteNS "VER" "MSNP7 MSNP6 MSNP5 MSNP4 CVR0"
	 sb set ns stat "v"
	 return 0
      }
      v {
         if {[lindex $recv 0] != "VER"} {
	    status_log "was expecting VER reply but got a [lindex $recv 0]\n" red
	    return 1
	 } elseif {[lsearch -exact $recv "CVR0"] != -1} {
            ::MSN::WriteNS "INF" ""
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
            ::MSN::WriteNS "USR" "MD5 I $config(login)"
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
         ::MSN::WriteNS "USR" "MD5 S [get_password 'MD5' [lindex $recv 4]]"
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
         sb set ns stat "a"
	 save_config						;# CONFIG
	 ::MSN::WriteNS "SYN" "0"

         if {$config(startoffline)} {
            ::MSN::changeStatus "HDN"
         } else {
            ::MSN::changeStatus "NLN"
         }
         #Log out
         .main_menu.file entryconfigure 2 -state normal
         #My status
         .main_menu.file entryconfigure 3 -state normal
         #Add a contact
         .main_menu.tools entryconfigure 0 -state normal
         .main_menu.tools entryconfigure 1 -state normal
         .main_menu.tools entryconfigure 4 -state normal
         #Change nick
	 configureMenuEntry .main_menu.actions "[trans changenick]..." normal
	 configureMenuEntry .options "[trans changenick]..." normal

	 configureMenuEntry .main_menu.actions "[trans sendmail]..." normal
	 configureMenuEntry .main_menu.actions "[trans sendmsg]..." normal

	 configureMenuEntry .main_menu.file "[trans savecontacts]..." normal

         #Publish Phone Numbers
	 configureMenuEntry .options "[trans publishphones]..." normal

	 return 0
      }
   }
   return -1
}

proc sb_change_fake { sbn } {
	global typing config ${sbn}_info
	
	if { $typing != $sbn && [info exists ${sbn}_info] } {
				
		set typing $sbn	

		after 4000 "set typing \"\""
		
		set sock [sb get $sbn sock]

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgscontrol\r\nTypingUser: $config(login)\r\n\r\n\r\n"
		set msg_len [string length $msg]

		incr ::MSN::trid
		set res [catch { puts $sock "MSG $::MSN::trid U $msg_len" }]
		set res [catch { puts -nonewline $sock $msg }]
	
		if { $res == 0 } {
			after 270000 sb_change_fake $sbn
		}
	}

}

proc sb_change { sbn } {
	global typing config
	
	if { $typing != $sbn } {
		set typing $sbn	

		after 4000 "set typing \"\""
		
		set sock [sb get $sbn sock]

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgscontrol\r\nTypingUser: $config(login)\r\n\r\n\r\n"
		set msg_len [string length $msg]

		incr ::MSN::trid
		puts $sock "MSG $::MSN::trid U $msg_len"
		puts -nonewline $sock $msg
	}
}

proc sb_enter { sbn name } {
   global user_info config

   set txt [$name get 0.0 end-1c]
   if {[string length $txt] < 1} { return 0 }

   set sock [sb get $sbn sock]
   if {[string index $txt 0] == "/"} {

   } 
   
   if {[sb length $sbn users]} {
      set txt_send [string map {"\n" "\r\n"} $txt]

      set txt_send [encoding convertto utf-8 $txt_send]      

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
      set timestamp [clock format [clock seconds] -format %H:%M]

      incr ::MSN::trid
      puts $sock "MSG $::MSN::trid N $msg_len"
      puts -nonewline $sock $msg

      cmsn_win_write $sbn "\[$timestamp\] [trans says [urldecode [lindex $user_info 4]]]:\n" gray
      cmsn_win_write $sbn "$txt\n" yours \{$fontfamily\} \{$fontstyle\} $fontcolor      
   } else {
      status_log "$sbn: trying to send, but no users in this session\n" white
      return 0
   }
   $name delete 0.0 end
   focus ${name}
   return 0
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
     puts -nonewline [sb get ns sock] "[string range $command 1 [string length $command]]\r\n"
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
	        cmsn_draw_offline;
	    }
	}
    }
}

proc cmsn_socket {name} {
   global config

   if {$config(withproxy) == 1} {
      set proxy_serv [split $config(proxy) ":"]
      set tmp_serv [lindex $proxy_serv 0]
      set tmp_port [lindex $proxy_serv 1]
      ::Proxy::OnCallback "dropped" "proxy_callback"

      status_log "Calling proxy::Setup now"
      ::Proxy::Setup next readable_handler $name
      status_log "Before sb set"
      sb set $name stat "pw"
      status_log "After sbset"
   } else {
      set tmp_serv [lindex [sb get $name serv] 0]
      set tmp_port [lindex [sb get $name serv] 1]
      set readable_handler [sb get $name readable]
      set next [sb get $name connected]
      sb set $name stat "cw"
   }

     status_log "HSiiiiiiit\n$readable_handler"

     set sock [socket -async $tmp_serv $tmp_port]
     sb set $name sock $sock
     fconfigure $sock -buffering none -translation {binary binary} -blocking 0
     fileevent $sock readable $readable_handler
     fileevent $sock writable $next
}

proc cmsn_ns_connected {} {
   global config


   fileevent [sb get ns sock] writable {}
   sb set ns stat "c"
   cmsn_auth
   if {$config(adverts)} {
     adv_resume   
   }
 
}

proc cmsn_sb_connected {name} {
   fileevent [sb get $name sock] writable {}
   sb set $name stat "c"
   ::MSN::WriteSB $name [sb get $name auth_cmd] [sb get $name auth_param]
   cmsn_msgwin_top $name "[trans indent]..."
}

proc cmsn_ns_connect { username {password ""}} {
   global unread list_al list_bl list_fl list_rl config
   status_log "Here"
   if { ($username == "") || ($password == "")} {
     cmsn_draw_login
     return -1
   }

   set list_al [list]
   set list_bl [list]
   set list_fl [list]
   set list_rl [list]      
   status_log "Clearing lists\n"

   if {[sb get ns stat] != "d"} {
      fileevent [sb get ns sock] readable {}
      close [sb get ns sock]
   }

   #Log in
   .main_menu.file entryconfigure 0 -state disabled
   .main_menu.file entryconfigure 1 -state disabled
   #Proxy Config

   cmsn_draw_signin

   sb set ns data [list]
   sb set ns connected "cmsn_ns_connected"
   sb set ns readable "read_ns_sock"

   set unread 0

   cmsn_socket ns
   
   load_alarms		;# Load alarms config on login

   return 0
}

proc get_password {method data} {
   global password

   set pass [::md5::md5 $data$password]
   return $pass

}

proc urldecode {str} {

#New version, no need of url_unmap
    set begin 0
    set end [string first "%" $str $begin]
    set decode ""
  
  
    while { $end >=0 } {
      set decode "${decode}[string range $str $begin [expr {$end-1}]]"

      if {[catch {set decode "${decode}[format %c 0x[string range $str [expr {$end+1}] [expr {$end+2}]]]"} res]} {
         catch {set decode "${decode}[format %c 0x[string range $str [expr {$end+1}] [expr {$end+1}]]]"} res
      }

      set begin [expr {$end+3}]
      set end [string first "%" $str $begin]
    }
    
    set decode ${decode}[string range $str $begin [string length $str]]

    return $decode
}

proc urlencode {str} {
#   global url_map

   set encode ""

   set str [encoding convertto utf-8 $str]
   
   for {set i 0} {$i<[string length $str]} {incr i} {
     set character [string range $str $i $i]
     if {[string match {[^a-zA-Z0-9]} $character]==0} {       
       #Try 8 bits character, then 16 bits unicode
       binary scan $character c charval
       binary scan $character s charval
       set charval [expr {( $charval + 0x10000 ) % 0x10000}]
       if {$charval <= 0xFF} {
          set encode "${encode}%[format %.2X $charval]"
       } else {
          set charval1 [expr {$charval & 0xFF} ]
          set charval2 [expr {$charval >> 8}]
          set encode "${encode}$character"
       }
     } else {
       set encode "${encode}$character"
     }
   } 
  
   return $encode
}
