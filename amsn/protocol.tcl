#=======================================================================
for {set i 0} {$i < 256} {incr i} {
   set c [format %c $i]
   set hex [string tolower %[format %.2X $i]]
      if { $c == ")" } {
      	set url_map() $hex
	set url_unmap($hex) "\)"
      } elseif { $c == "," } {
      	set url_map(\,) $hex
	set url_unmap($hex) "\,"
      } else {
        set url_map($c) $hex
        set url_unmap($hex) "$c"
      }	

}


for {set i 256} {$i < 65536} {incr i} {
   set c [format %c $i]
   set hex [string tolower %[format %.2X $i]]
   set url_map($c) $hex
   set url_unmap($hex) "$c"

}

namespace eval ::MSN {
   namespace export changeName logout
   
   proc changeName { $userlogin newname } {
      write_ns_sock "REA" "$userlogin [urlencode $newname]"     
   }

   proc logout {} {
      global config
      puts -nonewline [sb get ns sock] "OUT\r\n"
      status_log "Loging out\n"
      if {$config(adverts)} {
         adv_pause
      }
   }
}




proc change_my_status {new_status} {
   write_ns_sock "CHG" $new_status
   status_log "Changing state to $new_status\n" red
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
#      status_log "$sbn: RECV: $log\n" green
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


proc write_sb_sock {sbn cmd param {handler ""}} {
   global trid
   incr trid

   puts [sb get $sbn sock] "$cmd $trid $param\r"
#   status_log "$sbn: SEND: $cmd $trid $param\n" red
   degt_protocol "->SB $cmd $trid $param"

   if {$handler != ""} {
      global list_cmdhnd
      lappend list_cmdhnd [list $trid $handler]
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

}

proc read_ns_sock {} {
   global ns_data ns_stat unread config password

   set ns_sock [sb get ns sock]
   if {[eof $ns_sock]} {
      close $ns_sock
      sb set ns stat "d"
      status_log "Closing NS socket!\n" red
      cmsn_draw_offline
   } else {
      gets $ns_sock tmp_data
#      sb append ns data $tmp_data

      set log [string map {\r ""} $tmp_data]

#      status_log "RECV: <-$log->\n" green
      degt_protocol "<-NS $tmp_data"

      sb append ns data $tmp_data		 

      if {[string range $tmp_data 0 2] == "MSG"} {

         set recv [split $tmp_data]
	 fconfigure $ns_sock -blocking 1
	 set msg_data [read $ns_sock [lindex $recv 3]]
	 status_log "MSGDATA: $msg_data " green
	 fconfigure $ns_sock -blocking 0
         sb append ns data $msg_data
      } 
   }

}

proc write_ns_sock {cmd param {handler ""}} {
   global trid
   incr trid

   puts -nonewline [sb get ns sock] "$cmd $trid $param\r\n"
#   status_log "SEND: $cmd $trid $param\n" red
   degt_protocol "->NS $cmd $trid $param"

   if {$handler != ""} {
      global list_cmdhnd
      lappend list_cmdhnd [list $trid $handler]
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
}


proc cmsn_msg_parse {msg hname bname} {
   upvar $hname headers
   upvar $bname body

   set head_len [string first "\r\n\r\n" $msg]
   set head [string range $msg 0 [expr $head_len - 1]]
   set body [string range $msg [expr $head_len + 4] [string length $msg]]

   set body [encoding convertfrom utf-8 $body]
   set body [string map {"\r" ""} $body]

   set head [string map {"\r" ""} $head]
   set head_lines [split $head "\n"]
   foreach line $head_lines {
      set colpos [string first ":" $line]
      set attribute [string tolower [string range $line 0 [expr $colpos-1]]]
      set value [string range $line [expr $colpos+2] [string length $line]]
      array set headers [list $attribute $value]
   }

}

proc cmsn_sb_msg {sb_name recv} {
   global filetoreceive HOME

   set msg [sb index $sb_name data 1]

#   status_log "LOG: $msg\n" white

 
   sb ldel $sb_name data 1
   array set headers {}
   set body ""
   cmsn_msg_parse $msg headers body

   set content [lindex [array get headers content-type] 1]
   set timestamp [clock format [clock seconds] -format %H:%M]

   if {[string range $content 0 9] == "text/plain"} {
      cmsn_win_write $sb_name \
        "\[$timestamp\] [trans says [urldecode [lindex $recv 2]]]:\n" gray
      cmsn_win_write $sb_name "$body\n" red
      set idx [sb search $sb_name typers [lindex $recv 1]]
      sb ldel $sb_name typers $idx
      cmsn_show_typers $sb_name
      cmsn_msgwin_flicker $sb_name 20
      
      set win_name "msg_[string tolower ${sb_name}]"

      if { [string compare [wm state .${win_name}] "withdrawn"] == 0 } {
        wm state .${win_name} iconic
	cmsn_notify_add [trans says [urldecode [lindex $recv 2]]]:\n$body \
	  "wm state .${win_name} normal"
      }

      if { [string first $win_name [focus]] != 1 } {
        sonido type
      }
      
   } elseif {[string range $content 0 19] == "text/x-msmsgscontrol"} {

#      status_log "$msg\n" white     
      set typer [array get headers typinguser]
      if {[llength $typer]} {
         set typer [lindex $typer 1]
	 set idx [sb search $sb_name typers "$typer"]
	 if {$idx == -1} {
            sb append $sb_name typers $typer
	 } else {
            sb ldel $sb_name typers $idx
         }
         cmsn_show_typers $sb_name
      }

   } elseif {[string range $content 0 18] == "text/x-msmsgsinvite"} {
#File transfers
      set invcommand [aim_get_str $body Invitation-Command]
      set cookie [aim_get_str $body Invitation-Cookie]
      if { $invcommand == "ACCEPT" } {
      
      	set requestdata [aim_get_str $body Request-Data]
	set requestdata [string range $requestdata 0 [expr [string length requestdata] -2]]
	
	set data [aim_get_str $body $requestdata]
	
	if { $data == "" } {
  	  status_log "Invitation cookie $cookie ACCEPTED\n" white
	  amsn_sendfile $cookie $sb_name  
	} else {
	  set ipaddr $data
	  set port [aim_get_str $body Port]
	  set authcookie [aim_get_str $body AuthCookie]
	  status_log "Going to receive a file..\n" 
	  status_log "Body: $body\n"
	  yesNoDialog "Accept file [lindex $filetoreceive 0], [lindex $filetoreceive 1] bytes?\nSaved to ${HOME}" "amsn_connectfiletransfer $ipaddr $port $authcookie \"[lindex $filetoreceive 0]\" $sb_name"
	  
	}		

	

      } elseif {$invcommand =="CANCEL" } {
        set cancelcode [aim_get_str $body Cancel-Code]
	status_log "Invitation cookie $cookie CANCELED: $cancelcode\n" white	
      } elseif {$invcommand == "INVITE" } {
        set app [aim_get_str $body Application-Name]	
	set cookie [aim_get_str $body Invitation-Cookie]
	set filename [aim_get_str $body Application-File]
	set filesize [aim_get_str $body Application-FileSize]
	status_log "Invited to $app\n" white
	status_log "$body\n" black
	amsn_acceptfiletransfer $cookie $sb_name
	
	set filetoreceive [list "$filename" $filesize]
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
      eval "[lindex [lindex $list_cmdhnd $idx] 1] \"$item\""
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
   write_sb_sock $name "CAL" $user
}

proc cmsn_chat_user {user} {
   set name [cmsn_draw_msgwin]

   sb set $name stat "r"
   sb set $name invite $user

   status_log "$name: CHAT1 Talking with $user\n" green
   write_ns_sock "XFR" "SB" "cmsn_open_sb $name"
   
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
   global config

   set sbn [cmsn_draw_msgwin]
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


   if [catch { cmsn_msgwin_top $sbn "[trans sbcon]..."} res]  {
     status_log "Ignoring: Chat window $sbn has been closed\n"
   } else {
     cmsn_socket $sbn
   }
}

proc cmsn_conn_sb {name} {
   fileevent [sb get $name sock] writable {}
   sb set $name stat "a"
   set cmd [sb get $name auth_cmd]; set param [sb get $name auth_param]
   write_sb_sock $name $cmd $param "cmsn_connected_sb $name"
   cmsn_msgwin_top $name "[trans ident]..."
}

proc cmsn_conn_ans {name} {
   fileevent [sb get $name sock] writable {}
   sb set $name stat "a"
   set cmd [sb get $name auth_cmd]; set param [sb get $name auth_param]
   write_sb_sock $name $cmd $param
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
      sb set $name stat "rc"
      sb set $name invite [lindex [sb get $name last_user] 0]
      write_ns_sock "XFR" "SB" "cmsn_open_sb $name"
      cmsn_msgwin_top $name "[trans reconnecting]..."
   }
}



#New protocol by AIM
proc cmsn_answer_challenge {item} {
   global trid

   if { [lindex $item 1] != 0 } {
     status_log "Invalid challenge\n" white
   } else {
     set cadenita [lindex $item 2]Q1P7W2E4J9R8U3S5
     set cadenita [::md5::md5 $cadenita]
     write_ns_sock "QRY" "msmsgs@msnmsgr.com 32"     
     puts -nonewline [sb get ns sock] $cadenita
#   incr trid

#   puts -nonewline [sb get ns sock] "QRY $trid msmsgs@msnmsgr.com 32\r\n$cadenita"

   }
}

proc cmsn_ns_handler {item} {
   global list_cmdhnd password

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
            cmsn_ns_connect
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
         global user_info
         set user_info $item
	 cmsn_draw_online
	 return 0
      }
      ADD -
      LST {
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
	 set user_stat [lindex $item 2]
	 cmsn_draw_online
	 return 0
      }
      GTC -
      BLP -
      SYN {
	 return 0
      }
      CHL {
     	  status_log "Challenge received\n" red
	  cmsn_answer_challenge $item
	  return 0
      }
      QRY {
          status_log "Challenge accepted\n" green
	  return 0
      }
      BPR {
      	status_log "BPR: TODO $item\n" white
	return 0
      }
      PRP {
      	status_log "PRP: TODO $item\n" white
	return 0
      }
      LSG {
      	status_log "LSG: TODO $item\n" white
	return 0
      }
      200 {
          status_log "Error: Sintax error\n" error
	  msg_box "[trans sintaxerror]"
          return 0
      }
      911 {
          status_log "Error: User/Password\n" red
	  set password ""
	  msg_box "[trans baduserpass]"
          return 0
      }     
      913 {
          status_log "Error: Not allowed when offline\n" red
	  msg_box "[trans notallowedoffline]"
          return 0
      }     
      default {
#         status_log "RECV: -[join $item]-\n" green
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
   write_ns_sock "LST" "[lindex $recv 2]"
}

proc cmsn_auth {{recv ""}} {
   global config


   switch [sb get ns stat] {
      c {
#New version of protocol
         write_ns_sock "VER" "MSNP7 MSNP6 MSNP5 MSNP4 CVR0"
	 sb set ns stat "v"
	 return 0
      }
      v {
         if {[lindex $recv 0] != "VER"} {
	    status_log "was expecting VER reply but got a [lindex $recv 0]\n" red
	    return 1
	 } elseif {[lsearch -exact $recv "CVR0"] != -1} {
            write_ns_sock "INF" ""
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
            write_ns_sock "USR" "MD5 I $config(login)"
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
         write_ns_sock "USR" "MD5 S [get_password 'MD5' [lindex $recv 4]]"
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
	 write_ns_sock "SYN" "0"
# Me pongo online al comenzar
   if {$config(startoffline)} {
      write_ns_sock "CHG" "HDN" ;
   } else {
      write_ns_sock "CHG" "NLN" ;
   }
   #Log out
   .main_menu.file entryconfigure 2 -state normal
   #My status
   .main_menu.file entryconfigure 3 -state normal
   #Add a contact
   .main_menu.tools entryconfigure 0 -state normal
   #Change nick
   .main_menu.actions entryconfigure 2 -state normal
   .options entryconfigure 0 -state normal

#         .main_menu entryconfigure 0 -state normal
#         .main_menu.msn entryconfigure 1 -state normal
#         .main_menu.msn entryconfigure 2 -state normal
#         .main_menu.msn entryconfigure 4 -state normal
#         .main_menu.msn entryconfigure 5 -state normal
	 return 0
      }
   }

}

proc sb_change { sbn } {
	global trid typing config

	if { $typing != $sbn } {
	
		set typing $sbn	

		after 4000 "set typing \"\""
		
		set sock [sb get $sbn sock]

		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgscontrol\r\nTypingUser: $config(login)\r\n\r\n\r\n"

		set msg_len [string length $msg]
		incr trid
		puts $sock "MSG $trid U $msg_len"
		puts -nonewline $sock $msg
	}
}

proc sb_enter { sbn name } {
   global trid user_info

   set txt [$name get 0.0 end-1c]
   if {[string length $txt] < 1} { return 0 }

   set sock [sb get $sbn sock]
   if {[string index $txt 0] == "/"} {
#      set cmd [string range $txt 1 [string length $txt]]
#      puts $sock $cmd


   } 
   
   if {[sb length $sbn users]} {
      set txt_send [string map {"\n" "\r\n"} $txt]
      set msg "MIME-Version: 1.0\r\nContent-Type: text/plain\r\n\r\n"
      set msg "$msg$txt_send"
      set msg_len [string length $msg]
      set timestamp [clock format [clock seconds] -format %H:%M]
      incr trid
      puts $sock "MSG $trid N $msg_len"
      puts -nonewline $sock $msg
#      cmsn_win_write $sbn "\[$timestamp\] [trans yousay]:\n" gray
      cmsn_win_write $sbn "\[$timestamp\] [trans says [urldecode [lindex $user_info 4]]]:\n" gray
      cmsn_win_write $sbn "$txt\n" blue
   } else {
      status_log "$sbn: trying to send, but no users in this session\n" white
      return 0
   }
   $name delete 0.0 end
   focus ${name}
}

set atransfer ""

proc amsn_acceptfiletransfer {cookie sbn} {
	global trid

	set sock [sb get $sbn sock]

	set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
	set msg "${msg}Invitation-Command: ACCEPT\r\n"
	set msg "${msg}Invitation-Cookie: $cookie\r\n"
	set msg "${msg}Launch-Application: FALSE\r\n"
	set msg "${msg}Request-Data: IP-Address:\r\n\r\n"

	set msg_len [string length $msg]
	incr trid
	puts $sock "MSG $trid N $msg_len"
	puts -nonewline $sock $msg

	status_log "Accepting filetransfer sent\n" red


}

proc amsn_sendfile {cookie sbn} {
	global atransfer trid

	set sock [sb get $sbn sock]

	#Invitation accepted, send IP and Port to connect to
	set ipaddr [lindex [fconfigure $sock -sockname] 0]
	set port 6891
	set authcookie [expr $trid * $port % (65536 * 4)]
	

	set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
	set msg "${msg}Invitation-Command: ACCEPT\r\n"
	set msg "${msg}Invitation-Cookie: $cookie\r\n"
	set msg "${msg}IP-Address: $ipaddr\r\n"
	set msg "${msg}Port: $port\r\n"
	set msg "${msg}AuthCookie: $authcookie\r\n"
	set msg "${msg}Launch-Application: FALSE\r\n"
	set msg "${msg}Request-Data: IP-Address:\r\n\r\n"

	while {[catch {set sockid [socket -server amsn_acceptconnection $port]} res]} {
	  set port [expr $port + 1]
	}
	after 120000 "status_log \"Closing $sockid\n\";close $sockid"
	lappend atransfer $authcookie
	
	set msg_len [string length $msg]
	incr trid
	puts $sock "MSG $trid N $msg_len"
	puts -nonewline $sock $msg

	status_log "Final invitation for filetransfer sent\n" red

}


proc yesNoDialog { msg yescmd {nocmd ""}} {
    toplevel .yesno
    wm title .yesno "Question"
     label .yesno.msg -justify center -text $msg
     pack .yesno.msg -side top

     frame .yesno.buttons
     pack .yesno.buttons -side bottom -fill x -pady 2m
      button .yesno.buttons.no -text No -command "destroy .yesno; $nocmd"
      button .yesno.buttons.yes -text Yes \
        -command "$yescmd; destroy .yesno"
      pack .yesno.buttons.yes .yesno.buttons.no -side left -expand 1

    focus .yesno.buttons.yes

}

proc amsn_connectfiletransfer {ipaddr port authcookie filename sbn} {
   #I connect to a remote host to retrive the file
   global config HOME

   status_log "Conectando a $ipaddr puerto $port\n"
   set sockid [socket $ipaddr $port]
   fconfigure $sockid -blocking 0 -buffering none -translation {binary binary}   
   status_log "Conectado, voy a enviar\n"
   puts $sockid "VER MSNFTP\r"
   status_log "ENVIO: VER MSNFTP\r\n"
   fconfigure $sockid -blocking 1
   gets $sockid tmpdata
   status_log "MEENVIAN: $tmpdata\n"
   if {[string range $tmpdata 0 9] == "VER MSNFTP"} {
     fconfigure $sockid -blocking 0
     puts $sockid "USR $config(login) $authcookie\r"
     status_log "ENVIO: USR $config(login) $authcookie\r\n"
   
      fconfigure $sockid -blocking 1
      gets $sockid tmpdata
      status_log "MEENVIAN: $tmpdata\n"
      if {[string range $tmpdata 0 2] == "FIL"} {
        set filesize [string range $tmpdata 3 [string length $tmpdata]]
	status_log "Me envian archivo de tamaño $filesize\n"

        fconfigure $sockid -blocking 0
	puts $sockid "TFR\r"
	
	status_log "Recibiendo archivo...\n"

	set fileid [open "${HOME}/$filename" w]
	fconfigure $fileid -blocking 0 -translation {binary binary}

	#TODO: Receive the file
	
#        fconfigure $sockid -blocking 1
#	set recvbytes 0

	fconfigure $sockid -blocking 1 -buffersize 2048 -buffering full
	
	fileevent $sockid readable "acceptfilepacket $sockid $fileid $filesize $sbn"
	
	return 0;

      }

   }
   
   status_log "Fallo en la transferencia, conexion cerrada\n"
   close $sockid
   return 1;
}


proc acceptfilepacket { sockid fileid filesize sbn} {
   set header [read $sockid 3]

   set win_name "msg_[string tolower ${sbn}]"

   set packet1 1

   binary scan $header ccc packet1 packet2 packet3
	
   #If packet1 is 1 -- Transfer canceled by the other
   if { $packet1 != 0 } {
      status_log "File transfer cancelled\n"
	
      close $fileid
      close $sockid

   }
   #If you want to cancel, send "CCL\n"
	
   set packet2 [expr ($packet2 + 0x100) % 0x100]
   set packet3 [expr ($packet3 + 0x100) % 0x100]
	
   set packetsize [expr $packet2 + ($packet3<<8)]
	
   status_log "packetsize: $packetsize\n"
		
   set thedata [read $sockid $packetsize]
   puts -nonewline $fileid $thedata
		
   set recvbytes [tell $fileid]
   status_log "Received $recvbytes of $filesize\n"

   #Windows closed?
   .${win_name}.status configure -state normal
   .${win_name}.status delete 0.0 end
   .${win_name}.status insert end "Received $recvbytes of $filesize\n"
   .${win_name}.status configure -state disabled

	
   if { $recvbytes >= $filesize} {
      puts $sockid "BYE 16777989\r"	
      status_log "File received\n"
	
      close $fileid
      close $sockid
   }
}

proc amsn_acceptconnection {sockid hostaddr hostport} {
  global atransfer
   #Someone connects to my host to get the file i offer
  status_log "Conexión aceptada sockid: $sockid hostaddr: $hostaddr port: $hostport\n" white  
  fconfigure $sockid -blocking 0 -buffering none -translation {binary binary}
  fconfigure $sockid -blocking 1
  gets $sockid tmpdata
  status_log "RECIBO: $tmpdata\n"
  if { [string range $tmpdata 0 9] == "VER MSNFTP"} {
    puts $sockid "VER MSNFTP\r"
    status_log "ENVIO: VER MSNFTP\n"
    fconfigure $sockid -blocking 1
    gets $sockid tmpdata
    fconfigure $sockid -blocking 0
    status_log "Recibo: $tmpdata\n"      
    
    if { [string range $tmpdata 0 2] == "USR" } {
	set filename [lindex $atransfer 1]	
	set filesize [lindex $atransfer 2]

      puts $sockid "FIL $filesize\r"
      status_log "ENVIO: FIL $filesize\n"

      fconfigure $sockid -blocking 1      
      gets $sockid tmpdata
      fconfigure $sockid -blocking 0
      status_log "Recibo: $tmpdata\n"
      if { [string range $tmpdata 0 2] == "TFR" } {
        fconfigure $sockid -blocking 0	
        #Send the file


	set fileid [open $filename r]
	fconfigure $fileid -translation {binary binary}
	status_log "Sending file $filename size $filesize\n"

	set sentbytes 0
	
	while {$sentbytes < $filesize} {
	  
	  if {[expr $filesize-$sentbytes >2045]} {
	    set packetsize 2045
	  } else {
	    set packetsize [expr $filesize-$sentbytes]
	  }
	  
  	  set datos [read $fileid $packetsize]
	  
	  set byte1 [expr $packetsize & 0xFF]
	  set byte2 [expr $packetsize >> 8]
	  
	  puts -nonewline $sockid "\0[format %c $byte1][format %c $byte2]"
	  puts -nonewline $sockid $datos
	  set sentbytes [expr $sentbytes + $packetsize]
	  status_log "sending $sentbytes of $filesize bytes\n"
	}
	
	status_log "File sent complete\n"
	close $sockid
	close $fileid
	return 0;

      }
    } 
  } 
  status_log "Transferencia cancelada\n"  
  close $sockid
}

###################### Other Features     ###########################
proc SelectFileToTransfer { twn title } {
    # TODO File selection box, use nickname as filename (caller)
    set w .form$title
    toplevel $w
    wm title $w "Send session"
     label $w.msg -justify center -text "Please give a filename"
     pack $w.msg -side top

     frame $w.buttons
     pack $w.buttons -side bottom -fill x -pady 2m
      button $w.buttons.dismiss -text Cancel -command "destroy $w"
      button $w.buttons.save -text Send \
        -command "sb_sendfile $twn $w.filename.entry; destroy $w"
      pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

    frame $w.filename -bd 2
     entry $w.filename.entry -relief sunken -width 40 
     label $w.filename.label -text "Filename:"
     pack $w.filename.entry -side right
     pack $w.filename.label -side left
    pack $w.msg $w.filename -side top -fill x
    focus $w.filename.entry

    fileDialog2 $w $w.filename.entry open Untitled
}


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
    if [string compare $file ""] {
	$ent delete 0 end
	$ent insert 0 $file
	$ent xview end
    }
}


proc sb_sendfile { sbn file} {
	global trid atransfer

	set file [ $file get ]

	status_log "File size: [file size $file]\n"
	set filesize [file size $file]

	set sock [sb get $sbn sock]

	#Invitation to filetransfer, initial message
	set cookie [expr $trid * $filesize % (65536 * 4)]

	set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msmsgsinvite; charset=UTF-8\r\n\r\n"
	set msg "${msg}Application-Name: File Transfer\r\n"
	set msg "${msg}Application-GUID: {5D3E02AB-6190-11d3-BBBB-00C04F795683}\r\n"
	set msg "${msg}Invitation-Command: INVITE\r\n"
	set msg "${msg}Invitation-Cookie: $cookie\r\n"
	set msg "${msg}Application-File: [file tail $file]\r\n"
	set msg "${msg}Application-FileSize: $filesize\r\n\r\n"
	
	set msg_len [string length $msg]
	incr trid
	puts $sock "MSG $trid N $msg_len"
	puts -nonewline $sock $msg

	status_log "Sending file $file\n" red

	set atransfer [list "Cookie:$cookie" "$file" $filesize $sbn ]

}


proc ns_enter {} {
   set command "[.status.enter get]"
   .status.enter delete 0 end
   if { [string range $command 0 0] == "/"} {
     puts -nonewline [sb get ns sock] "[string range $command 1 [string length $command]]\r\n"
   } elseif {$command != ""} {
     if {[catch {eval $command} res]} {
        msg_box "$res"
     }
   }
   
#   status_log "SEND: [.status.enter get]\n" red
}

proc cmsn_socket {name} {
   global config

   if {$config(withproxy) == 1} {
      set proxy_serv [split $config(proxy) ":"]
      set tmp_serv [lindex $proxy_serv 0]
      set tmp_port [lindex $proxy_serv 1]
      set next "cmsn_proxy_connect $name"
      set readable_handler "cmsn_proxy_read $name"
      sb set $name stat "pw"
   } else {
      set tmp_serv [lindex [sb get $name serv] 0]
      set tmp_port [lindex [sb get $name serv] 1]
      set readable_handler [sb get $name readable]
      set next [sb get $name connected]
      sb set $name stat "cw"
   }

     set sock [socket -async $tmp_serv $tmp_port]
      sb set $name sock $sock
     fconfigure $sock -buffering none -translation {binary binary} -blocking 0
     fileevent $sock readable $readable_handler
     fileevent $sock writable $next
}

proc cmsn_proxy_read {name} {
   global proxy_header

   set sock [sb get $name sock]
   if {[eof $sock]} {
      close $sock
      sb set $name stat "d"
      status_log "PROXY: $name CLOSED\n" red
   } elseif {[gets $sock tmp_data] != -1} {
	 global proxy_header
	 set tmp_data [string map {\r ""} $tmp_data]
	 lappend proxy_header $tmp_data
	 status_log "PROXY RECV: $tmp_data\n"
	 if {$tmp_data == ""} {
	    set proxy_status [split [lindex $proxy_header 0]]
	    if {[lindex $proxy_status 1] != "200"} {
	       close $sock
	       sb set $name stat "d"
	       status_log "PROXY CLOSED: [lindex $proxy_header 0]\n"
               if {$name == "ns"} cmsn_draw_offline ;# maybe should be passed
	       return 1
	    }
	    status_log "PROXY ESTABLISHED: running [sb get $name connected]\n"
            fileevent [sb get $name sock] readable [sb get $name readable]
            eval [sb get $name connected]
          }
   }
}

proc cmsn_proxy_connect {name} {
   fileevent [sb get $name sock] writable {}
   sb set $name stat "pc"
   set tmp_data "CONNECT [join [sb get $name serv] ":"] HTTP/1.0"
   status_log "PROXY SEND: $tmp_data\n"
   puts -nonewline [sb get $name sock] "$tmp_data\r\n\r\n"
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
   write_sb_sock $name [sb get $name auth_cmd] [sb get $name auth_param]
   cmsn_msgwin_top $name "[trans indent]..."
}

proc cmsn_ns_connect {} {
   global config unread list_al list_bl list_fl list_rl password

   if { ($config(login) == "") || ($password == "")} {
     cmsn_draw_login
     return
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
   .options entryconfigure 1 -state disabled

#   .main_menu.msn entryconfigure 0 -state disabled
#   .main_menu.msn entryconfigure 7 -state disabled

   wm title . "[trans title] - $config(login)"
   cmsn_draw_signin

   sb set ns data [list]
   sb set ns connected "cmsn_ns_connected"
   sb set ns readable "read_ns_sock"

   set unread 0

   cmsn_socket ns
}

proc get_password {method data} {
   global password

   set pass [::md5::md5 $data$password]
   return $pass

}

proc urldecode {str} {
  global url_unmap url_map
    # estracted from ncgi - solves users from needing to install extra packages!
#    regsub -all {\+} $str { } str
#    regsub -all {[][\\\$]} $str {\\&} str
#    regsub -all {%([0-9a-fA-F][0-9a-fA-F])} $str {[format %c 0x\1]} str

#Nuevo a ver si arregla el $ y los corchetes
    regsub -all {[\$]} $str {$url_map(&)} str
    set str [subst -nocommands -nobackslashes $str]
#    status_log "Original: $str\n" white
    regsub -all {%([0-9a-fA-F][0-9a-fA-F])} $str {$url_unmap([string tolower &])} str
#    status_log "Prueba: $str\n" white
#    status_log "Prueba2: [subst -nocommands -nobackslashes $str]\n" white

    return [subst -nocommands -nobackslashes $str]
}

proc urlencode {str} {
   global url_map

#   regsub -all \[^a-zA-Z0-9\)\\\[\\\\]\\\\\] $str {$url_map(&)} str
   regsub -all {[^a-zA-Z0-9\)\[\]\\]} $str {$url_map(&)} str
   set str [subst -nobackslashes -nocommands $str]

   #Special character with problems
   regsub -all {\\} $str $url_map(\\) str
   regsub -all {\)} $str $url_map() str
   regsub -all {\[} $str $url_map(\[) str
   regsub -all {\]} $str $url_map(\]) str

   return [subst -nobackslashes -nocommands -novariables $str]

}
