namespace eval ::hotmail {
   variable unread 0

   proc unreadMessages {} {
      variable unread
      return $unread
   }


   proc SetUnreadMessages { number } {
      variable unread
      set unread $number
   }

   proc composeMail { toaddr userlogin {pass ""} } {
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
            set page_data "$page_data\n$tmp_data"
         }

         close $read_id

         #Here we calculate the creds and fields in the web page
         set d(valid) Y
         ::abook::getDemographics d

         set userdata [split $userlogin "@"]
         set email $userlogin

         set login [lindex $userdata 0]

         set kv $d(kv)
         set sl [expr {[clock seconds] - $d(sessionstart)}]
         set sid $d(sid)
         set auth $d(mspauth)
         set tomd5 $auth$sl$pass
         set creds [::md5::md5 $tomd5]

         set url "/cgi-bin/compose?mailto=1&to=$toaddr"

         #Now let's substitute the $vars in hotmlog.htm

         set page_data [subst -nocommands -nobackslashes $page_data]

         if {$tcl_platform(platform) == "unix"} {
            set file_id [open "[file join ${HOME} hotlog.htm]" w 00600]
         } else {
            set file_id [open "[file join ${HOME} hotlog.htm]" w]
         }

         puts $file_id $page_data

         close $file_id

         launch_browser "file://${HOME}/hotlog.htm"

      } else {

	 launch_browser "http://www.hotmail.com"

      }

   }

   proc viewProfile {user_login} {
      launch_browser "http://members.msn.com/default.msnw?mem=${user_login}&pgmarket="
   }
}

proc hotmail_login {userlogin {pass ""}} {
# Note: pass can be empty, so user must enter password in the login
# page.
#
# $Id$
#
  global tcl_platform HOME program_dir config d

  if {($config(autohotlogin)) && ($pass != "")} {

    set read_id [open "${program_dir}/hotmlog.htm" r]

    set page_data ""
    while {[gets $read_id tmp_data] != "-1"} {
      set page_data "$page_data\n$tmp_data"
    }

    close $read_id


    #Here we calculate the creds and fields in the web page
    set d(valid) Y
    ::abook::getDemographics d

    set userdata [split $userlogin "@"]
    set email $userlogin

    set login [lindex $userdata 0]

    set kv $d(kv)
    set sl [expr {[clock seconds] - $d(sessionstart)}]
    set sid $d(sid)
    set auth $d(mspauth)
    set tomd5 $auth$sl$pass
    set creds [::md5::md5 $tomd5]

    set url "/cgi-bin/HoTMaiL"


    #Now let's substitute the $vars in hotmlog.htm

    set page_data [subst -nocommands -nobackslashes $page_data]

    if {$tcl_platform(platform) == "unix"} {
      set file_id [open "[file join ${HOME} hotlog.htm]" w 00600]
    } else {
      set file_id [open "[file join ${HOME} hotlog.htm]" w]
    }

     puts $file_id $page_data

     close $file_id

     launch_browser "file://${HOME}/hotlog.htm"
   } else {
     launch_browser "http://www.hotmail.com"
   }

}


proc hotmail_viewmsg {msgurl userlogin {pass ""}} {
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
      set page_data "$page_data\n$tmp_data"
    }

    close $read_id

    #Here we calculate the creds and fields in the web page
    set d(valid) Y
    ::abook::getDemographics d

    set userdata [split $userlogin "@"]
    set email $userlogin

    set login [lindex $userdata 0]

    set kv $d(kv)
    set sl [expr {[clock seconds] - $d(sessionstart)}]
    set sid $d(sid)
    set auth $d(mspauth)
    set tomd5 $auth$sl$pass
    set creds [::md5::md5 $tomd5]

    set url $msgurl

    #Now let's substitute the $vars in hotmlog.htm

    set page_data [subst -nocommands -nobackslashes $page_data]

    if {$tcl_platform(platform) == "unix"} {
      set file_id [open "[file join ${HOME} hotlog.htm]" w 00600]
    } else {
      set file_id [open "[file join ${HOME} hotlog.htm]" w]
    }

     puts $file_id $page_data

     close $file_id

     launch_browser "file://${HOME}/hotlog.htm"
   } else {
     launch_browser "http://www.hotmail.com"
   }

}

proc aim_get_str { bodywithr str } {

    set body [stringmap {"\r" ""} $bodywithr]
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
	global config password

	#Nuevo by AIM
	
	set content [aim_get_str $msg Content-Type]

	if {[string range $content 0 29] == "text/x-msmsgsemailnotification"} {					     
	  if {[aim_get_str $msg From] != ""} {				
	    set from [aim_get_str $msg From]
	    set fromaddr [aim_get_str $msg From-Addr]
	    set msgurl [aim_get_str $msg Message-URL]
	    status_log "Hotmail: New mail from $from - $fromaddr\n"

            ::hotmail::setUnreadMessages [expr { [::hotmail::unreadMessages] + 1}]

            ::amsn::notifyAdd "[trans newmailfrom]\n$from\n($fromaddr)" \
	      "hotmail_viewmsg $msgurl $config(login) $password" newemail
	    cmsn_draw_online

	  } 
	}
	if {[string range $content 0 36]  == "text/x-msmsgsinitialemailnotification"} {
  	  set noleidos [aim_get_str $msg Inbox-Unread]
	  status_log "Hotmail: $noleidos unread emails\n"
	  if { [string length $noleidos] > 0 } {
	    ::hotmail::setUnreadMessages $noleidos
	    cmsn_draw_online
	  }
	}
	if {[string range $content 0 34]  == "text/x-msmsgsactivemailnotification"} {
	  set source [aim_get_str $msg Src-Folder]
	  set dest [aim_get_str $msg Dest-Folder]
	  set delta [aim_get_str $msg Message-Delta]
	  if { $source == "ACTIVE" } {
  	    set noleidos [expr {[::hotmail::unreadMessages] - $delta}]
	  } elseif {$dest == "ACTIVE"} {
  	    set noleidos [expr {[::hotmail::unreadMessages] + $delta}]
	  } else {
	    set noleidos [::hotmail::unreadMessages]
	  }
	  status_log "Hotmail cambio mensajes: $noleidos unread emails\n"
	  if { [string length $noleidos] > 0 } {
	    ::hotmail::setUnreadMessages $noleidos
	    cmsn_draw_online
	  }
	}
		#End by AIM

}
