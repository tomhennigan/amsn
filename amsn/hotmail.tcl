namespace eval ::hotmail {
	if { $initialize_amsn == 1 } {
		variable unread 0
		variable froms [list]
	}

	proc unreadMessages {} {
		variable unread
		return $unread
	}


	proc setUnreadMessages { number } {
		variable unread
		set unread $number
	}

	proc addFrom { from fromaddr } {
		variable froms
		lappend froms $from $fromaddr
	}

	proc emptyFroms { } {
		variable froms
		set froms [list]
	}

	proc getFroms { } {
		variable froms
		return $froms
	}

	proc composeMail { toaddr userlogin {pass ""} } {
		# Note: pass can be empty, so user must enter password in the login
		# page.
		#
		# $Id$
		#
		global tcl_platform HOME

		if {$pass != ""} {

			set read_id [open "hotmlog.htm" r]

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

			if {$tcl_platform(os) != "Darwin"} {
				launch_browser "file://${HOME}/hotlog.htm" 1
			} else {
				launch_browser [file join ${HOME} hotlog.htm] 1
			}

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
	global tcl_platform HOME d

	if {$pass != ""} {

		set read_id [open "hotmlog.htm" r]

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
		if {$tcl_platform(os) != "Darwin"} {
			launch_browser "file://${HOME}/hotlog.htm" 1
		} else {
			launch_browser [file join ${HOME} hotlog.htm] 1
		}

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
	global tcl_platform HOME

	if {$pass != ""} {

		set read_id [open "hotmlog.htm" r]

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

		if {$tcl_platform(os) != "Darwin"} {
			launch_browser "file://${HOME}/hotlog.htm" 1
		} else {
			launch_browser [file join ${HOME} hotlog.htm] 1
		}

	} else {
		launch_browser "http://www.hotmail.com"
	}
}


proc QPDecode {str} {

	#New version, no need of url_unmap

	set begin 0
	set end [string first "=" $str $begin]
	set decode ""


	while { $end >=0 } {
		set decode "${decode}[string range $str $begin [expr {$end-1}]]"

		set carval [format %d 0x[string range $str [expr {$end+1}] [expr {$end+2}]]]
		if {$carval > 128} {
			set carval [expr { $carval - 0x100 }]
		}

		set car [binary format c $carval]

		set decode "${decode}$car"

		set begin [expr {$end+3}]
		set end [string first "=" $str $begin]
	}

	set decode ${decode}[string range $str $begin [string length $str]]

}


proc decode_from_field { from } {
	set from [string map {"\r" ""} $from]
	set from_list [split $from "?"]
	
	if { [llength $from_list] == 1 } {
		return $from
	}
	
	set encoding [string tolower [lindex $from_list 1]]
	set sender [string map {"_" " " "= " ""} [join [lrange $from_list 3 end]]]
	set sender [QPDecode $sender]
	if { [catch {set sender [encoding convertfrom $encoding $sender]}]} {
		status_log "decode_from_field: Wrong encoding - $encoding\n" red
		return $sender 
	}
	
	return $sender
	
}

proc hotmail_procmsg {message} {
	global password

	#Nuevo by AIM
	
	set content [lindex [split [$message getHeader Content-Type] ";"] 0 ]
#	set message [Message create %AUTO%]
#	$message createFromPayload "[$msg getBody]\r\n"
	switch $content {
		"text/x-msmsgsemailnotification" {     
			if {[set from [$message getField From]] != ""} {
				set fromaddr [$message getField From-Addr]
				if {[catch {set from [decode_from_field $from]} res]} {
					status_log "Fail to decode from field: $res\n" res
					set from $fromaddr
				}
				set msgurl [$message getField Message-URL]
				status_log "Hotmail: New mail from $from - $fromaddr\n"

				set dest [$message getField Dest-Folder]
				if {$dest == "ACTIVE"} {
					::hotmail::setUnreadMessages [expr { [::hotmail::unreadMessages] + 1}]
					::hotmail::addFrom $from $fromaddr
					cmsn_draw_online
					if { [::config::getKey notifyemail] == 1 } {
						::amsn::notifyAdd "[trans newmailfrom $from $fromaddr]" \
							"hotmail_viewmsg $msgurl [::config::getKey login] $password" newemail
					}
				} else {
					if { [::config::getKey notifyemailother] == 1 } {
						::amsn::notifyAdd "[trans newmailfromother $from $fromaddr]" \
							"hotmail_viewmsg $msgurl [::config::getKey login] $password" newemail
					}
				}
			}

			::log::eventmail $from
	
		}
		#Get the number of unread messages
		"text/x-msmsgsinitialemailnotification" {
			#Number of unread messages in inbox
			set noleidos [$message getField Inbox-Unread]
			#Get the URL of inbox directory in hotmail
			set msgurl [$message getField Inbox-URL]
			status_log "Hotmail: $noleidos unread emails\n"
			#Remember the number of unread mails in inbox and create a notify window if necessary
			if { [string length $noleidos] > 0 && $noleidos != 0} {
				::hotmail::setUnreadMessages $noleidos
				::hotmail::emptyFroms
				cmsn_draw_online
				if { [::config::getKey notifyemail] == 1} {
					::amsn::notifyAdd "[trans newmail $noleidos]" \
						"hotmail_login [::config::getKey login] $password" newemail
				}
			}


			#Number of unread messages in other folders
			set folderunread [$message getField Folders-Unread]
			#URL of folder directory in Hotmail
			set msgurl [$message getField Folders-URL]
			status_log "Hotmail: $folderunread unread emails in others folders \n"
			#If the pref notifyemail is active and more than 0 email unread, show a notify on connect
			if { [::config::getKey notifyemailother] == 1 && [string length $folderunread] > 0} {
				::amsn::notifyAdd "[trans newmailfolder $folderunread]" \
					"hotmail_viewmsg $msgurl [::config::getKey login] $password" newemail
			}
		}
	
		"text/x-msmsgsactivemailnotification" {
			set source [$message getField Src-Folder]
			set dest [$message getField Dest-Folder]
			set delta [$message getField Message-Delta]
			if { $source == "ACTIVE" } {
				set unread [expr {[::hotmail::unreadMessages] - $delta}]
				::hotmail::emptyFroms
				if { $unread < 0 } {
					status_log "number of unread hotmail messages is $unread, setting to 0\n" red
					set unread 0
				}
			} elseif {$dest == "ACTIVE"} {
				set unread [expr {[::hotmail::unreadMessages] + $delta}]
			} else {
				set unread [::hotmail::unreadMessages]
			}
			status_log "Hotmail num of messages changed: $unread unread emails\n"
			if { [string length $unread] > 0 } {
				::hotmail::setUnreadMessages $unread
				cmsn_draw_online
			}
		}
	}
	#End by AIM
	# dock mail icon 
	send_dock "MAIL" [::hotmail::unreadMessages]
	status_log "hotmail_procmsg: Finishing\n"

}
