proc hotmail_login {userlogin {pass ""}} {
# Note: pass can be empty, so user must enter password in the login
# page.
#
# $Id$
#
  global tcl_platform HOME program_dir config

  if {($config(autohotlogin)) && ($pass != "")} {

    set read_id [open "${program_dir}/hotmlog.htm" r]

    set page_data ""
    while {[gets $read_id tmp_data] != "-1"} {
      set page_data "$page_data $tmp_data"
    }

    close $read_id

    set userdata [split $userlogin "@"]
   
    set user [lindex $userdata 0]
    set domain [lindex $userdata 1]

    set page_data [subst -nocommands -nobackslashes $page_data]

    if {$tcl_platform(platform) == "unix"} {
      set file_id [open "${HOME}/hotlog.htm" w 00600]
    } else {
      set file_id [open "${HOME}/hotlog.htm" w]
    }

     puts $file_id $page_data

     close $file_id

     launch_browser "file://${HOME}/hotlog.htm"
   } else {
     launch_browser "http://www.hotmail.com"
   }

}

proc hotmail_viewmsg {msgurl userlogin {pass ""}} {
#To-do go directly to msgurl
  hotmail_login $userlogin $pass
}

proc aim_get_str { bodywithr str } {

    set body [string map {"\r" ""} $bodywithr]
    set pos [string first $str $body]
    
    if { $pos < 0 } {
      status_log "aim_get_str not found\n"
      return ""
    } else {
	    set inicio [expr { $pos + [string length $str] + 2 } ]
	    set fin [expr { $inicio + [string first "\n" [string range $body $inicio end]] - 1 } ]
	    return [string range $body $inicio $fin]
    }	   

}



proc hotmail_procmsg {msg} {
	global unread config password

	#Nuevo by AIM
	status_log "Hotmail me dice: $msg\n" white
		
	set content [aim_get_str $msg Content-Type]

	if {[string range $content 0 29] == "text/x-msmsgsemailnotification"} {					     
	  if {[aim_get_str $msg From] != ""} {				
	    set from [aim_get_str $msg From]
	    set fromaddr [aim_get_str $msg From-Addr]
	    set msgurl [aim_get_str $msg Message-URL]
	    status_log "Hotmail: New mail from $from - $fromaddr\n"
	    set unread [expr {$unread + 1}]
	    
            ::amsn::notifyAdd "[trans newmailfrom]\n$from\n($fromaddr)" \
	      "hotmail_viewmsg $msgurl $config(login) $password" newemail
	    cmsn_draw_online

	  } 
	}
	if {[string range $content 0 36]  == "text/x-msmsgsinitialemailnotification"} {
  	  set noleidos [aim_get_str $msg Inbox-Unread]
	  status_log "Hotmail: $noleidos unread emails\n"
	  if { [string length $noleidos] > 0 } {
	    set unread $noleidos
	    cmsn_draw_online
	  }
	}
	if {[string range $content 0 34]  == "text/x-msmsgsactivemailnotification"} {
	  set source [aim_get_str $msg Src-Folder]
	  set dest [aim_get_str $msg Dest-Folder]
	  set delta [aim_get_str $msg Message-Delta]
	  if { $source == "ACTIVE" } {
  	    set noleidos [expr {$unread - $delta}]
	  } elseif {$dest == "ACTIVE"} {
  	    set noleidos [expr {$unread + $delta}]
	  } else {
	    set noleidos $unread
	  }
	  status_log "Hotmail cambio mensajes: $noleidos unread emails\n"
	  if { [string length $noleidos] > 0 } {
	    set unread $noleidos
	    cmsn_draw_online
	  }
	}
		#End by AIM

}
