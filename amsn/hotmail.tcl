namespace eval ::hotmail {
   variable unread 0

   proc unreadMessages {} {
      variable unread
      return $unread
   }


   proc setUnreadMessages { number } {
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



proc hotmail_procmsg {msg} {
	global config password

	#Nuevo by AIM
	
	set content [::MSN::GetHeaderValue $msg Content-Type]

	if {[string range $content 0 29] == "text/x-msmsgsemailnotification"} {     
	  if {[::MSN::GetHeaderValue $msg From] != ""} {				
	    set from [::MSN::GetHeaderValue $msg From]
	    set fromaddr [::MSN::GetHeaderValue $msg From-Addr]
	    set msgurl [::MSN::GetHeaderValue $msg Message-URL]
	    status_log "Hotmail: New mail from $from - $fromaddr\n"

            ::hotmail::setUnreadMessages [expr { [::hotmail::unreadMessages] + 1}]
	
	    if { $config(notifyemail) == 1 } {
	    	::amsn::notifyAdd "[trans newmailfrom $from $fromaddr]" \
	      	"hotmail_viewmsg $msgurl $config(login) $password" newemail
	    }

	    cmsn_draw_online

	  } 
	}
	if {[string range $content 0 36]  == "text/x-msmsgsinitialemailnotification"} {
  	  set noleidos [::MSN::GetHeaderValue $msg Inbox-Unread]
	  status_log "Hotmail: $noleidos unread emails\n"
	  if { [string length $noleidos] > 0 } {
	    ::hotmail::setUnreadMessages $noleidos
	    cmsn_draw_online
	  }
	}
	if {[string range $content 0 34]  == "text/x-msmsgsactivemailnotification"} {
	  set source [::MSN::GetHeaderValue $msg Src-Folder]
	  set dest [::MSN::GetHeaderValue $msg Dest-Folder]
	  set delta [::MSN::GetHeaderValue $msg Message-Delta]
	  if { $source == "ACTIVE" } {
  	    set noleidos [expr {[::hotmail::unreadMessages] - $delta}]
	  } elseif {$dest == "ACTIVE"} {
  	    set noleidos [expr {[::hotmail::unreadMessages] + $delta}]
	  } else {
	    set noleidos [::hotmail::unreadMessages]
	  }
	  status_log "Hotmail num of messages changed: $noleidos unread emails\n"
	  if { [string length $noleidos] > 0 } {
	    ::hotmail::setUnreadMessages $noleidos
	    cmsn_draw_online
	  }
	}
		#End by AIM
	# dock mail icon 
	send_dock "MAIL" [::hotmail::unreadMessages]

}
