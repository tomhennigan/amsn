
::Version::setSubversionId {$Id$}

namespace eval ::hotmail {
	if { $initialize_amsn == 1 } {
		variable unread 0
		variable froms [list]
		variable site ""
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

	proc gotURL {main_url {post_url "https://loginnet.passport.com/ppsecure/md5auth.srf?lc=1033"} {id 2}} {
		global HOME password

		set fd [open "hotmlog.htm" r]
		set page_data [read $fd]
		close $fd
		
		#Here we calculate the creds and fields in the web page
		set site $post_url
		set url $main_url

		set d(valid) Y
		::abook::getDemographics d
		
		set email [::config::getKey login]
		set login [lindex [split $email "@"] 0]
		
		# This was to launch the URL directly without auth for hotmail and msn users, 
		# but there are other accounts now like @live.com that need this
		# problem is that non hotmail/msn/live users will get the http://cgi-bin/Hotmail page
		# which will just not work. So now every URL goes through the msn auth server.
		#if {![string match *@hotmail.* $email ] && ![string match *@msn.* $email ]} {
		#	launch_browser $main_url
		#	return
		#}
		
		set kv $d(kv)
		set sl [expr {[clock seconds] - $d(sessionstart)}]
		set sid $d(sid)
		set auth $d(mspauth)
		set tomd5 $auth$sl$password
		set creds [::md5::md5 $tomd5]
		

		#Now let's substitute the $vars in hotmlog.htm
		
		set page_data [subst -nocommands -nobackslashes $page_data]
		
		if { [OnUnix] } {
			set file_id [open "[file join ${HOME} hotlog.htm]" w 00600]
		} else {
			set file_id [open "[file join ${HOME} hotlog.htm]" w]
		}
		
		puts $file_id $page_data
		
		close $file_id
		
		if { [OnDarwin] } {
			launch_browser [file join ${HOME} hotlog.htm] 1
		} else {
			launch_browser "file://${HOME}/hotlog.htm" 1
		}
		
	}

	proc viewProfile {user_login} {
		gotURL "http://members.msn.com/default.msnw?mem=${user_login}&pgmarket="
	}

	proc composeMail { toaddr} {
		::MSN::WriteSB ns URL "COMPOSE $toaddr"
	}

	proc hotmail_profile {} {
		::MSN::WriteSB ns URL "PROFILE 0x0409"
	}

	proc hotmail_login {} {
		::MSN::WriteSB ns URL INBOX
	}

	proc hotmail_changeAccountInfo {} {
		::MSN::WriteSB ns URL "PERSON 0x0409"
	}

	proc hotmail_changeMobile {} {
		::MSN::WriteSB ns URL CHGMOB
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
		set sender [::hotmail::QPDecode $sender]
		if { [catch {set sender [encoding convertfrom $encoding $sender]}]} {
			status_log "decode_from_field: Wrong encoding - $encoding\n" red
			return $sender 
		}
	
		return $sender
	
	}

	proc handleMailData { mailData } {
		if {$mailData == "too-large" } {
			status_log "Mail-Data is too large, retreiving it via SOAP..."
			::MSNOIM::getMailData "::hotmail::handleMailData"
		} elseif { [catch {set mailList [xml2list $mailData]} ] == 0 } {
			set oim_count 0
			set oim_messages [list]
			while { 1 } {
				set oim_message [GetXmlEntry $mailList ":MD:M:I" $oim_count]
				if { $oim_message == "" } {
					break
				}
				set from [GetXmlEntry $mailList ":MD:M:E" $oim_count]
				set nick [GetXmlEntry $mailList ":MD:M:N" $oim_count]

				# When we receive the notification while being signed in (appear offline for example) the base64
				# has a space in the end (probably a bug in the server) so we remove it here ot make it 'normal'
				if { [string range $nick end-2 end] == " ?=" } {
					set nick [string range $nick 0 end-3]
					append nick "?="
				}
				set oim [list $from $nick $oim_message]
				lappend oim_messages $oim
				incr oim_count
			}
			if { $oim_count > 0 } {
				after 0 [list ::hotmail::askReadReceivedOIMs $oim_count $oim_messages]
			}
		} else {
			status_log "Mail-Data is invalid : $mailData"
		}
	}

	proc askReadReceivedOIMs { oim_count oim_messages } {
		set answer [tk_messageBox -type yesno -title "[trans newoim]" \
			-message [trans receivedoimread $oim_count]]
		if { $answer == "yes" } {
			::OIM_GUI::MessagesReceived $oim_messages
		}
	}

	proc hotmail_procmsg {message} {
		global password

		#Nuevo by AIM
	
		set content [lindex [split [$message getHeader Content-Type] ";"] 0 ]
	#	set message [Message create %AUTO%]
	#	$message createFromPayload "[$msg getBody]\r\n"
		switch $content {
			"text/x-msmsgsinitialmdatanotification" {
				#Number of unread messages in inbox
				set mailData [$message getField Mail-Data]
				if { [catch {set mailList [xml2list $mailData]} ] == 0 } {
					set inbox [GetXmlEntry $mailList ":MD:E:I"] 
					# string range $mailData [expr {[string first <I> $mailData]+3}] [expr {[string first </I> $mailData] -1}]]
					set inboxUnread [GetXmlEntry $mailList ":MD:E:IU"]
					# [string range $mailData [expr {[string first <IU> $mailData]+4}] [expr {[string first </IU> $mailData] -1}]]
					
					
					#Get the URL of inbox directory in hotmail
					set msgurl [$message getField Inbox-URL]
					status_log "Hotmail: $inboxUnread unread emails\n"
					#Remember the number of unread mails in inbox and create a notify window if necessary
					if { [string length $inboxUnread] > 0 && $inboxUnread != 0} {
						::hotmail::setUnreadMessages $inboxUnread
						::hotmail::emptyFroms
						cmsn_draw_online 0 1
						if { [::config::getKey notifyemail] == 1} {
							::amsn::notifyAdd "[trans newmail $inboxUnread\($inbox\)]" \
							    [list ::hotmail::gotURL $msgurl] newemail email
						}
					}
					
					
					#Number of unread messages in other folders
					# set mailData [$message getField Mail-Data]
					set folder [GetXmlEntry $mailList ":MD:E:O"] 
					# [string range $mailData [expr {[string first <O> $mailData]+3}] [expr {[string first </O> $mailData] -1}]]
					set folderUnread [GetXmlEntry $mailList ":MD:E:OU"] 
					#[string range $mailData [expr {[string first <OU> $mailData]+4}] [expr {[string first </OU> $mailData] -1}]]
					
					#URL of folder directory in Hotmail
					set msgurl [$message getField Folders-URL]
					status_log "Hotmail: $folderUnread unread emails in others folders \n"
					#If the pref notifyemail is active and more than 0 email unread, show a notify on connect
					if { [::config::getKey notifyemailother] == 1 && [string length $folderUnread] > 0 && $folderUnread != 0 } {
						::amsn::notifyAdd "[trans newmailfolder $folderUnread\($folder\)]" \
						    [list ::hotmail::gotURL $msgurl] newemail email
					}
				}
				
				handleMailData $mailData
			}
			"text/x-msmsgsemailnotification" {     
				if {[set from [$message getField From]] != ""} {
					set fromaddr [$message getField From-Addr]
					if {[catch {set from [::hotmail::decode_from_field $from]} res]} {
						status_log "Fail to decode from field: $res\n" res
						set from $fromaddr
					}
					set posturl [$message getField Post-URL]
					set id [$message getField id]
					set msgurl [$message getField Message-URL]
					status_log "Hotmail: New mail from $from - $fromaddr\n"

					set dest [$message getField Dest-Folder]
					if {$dest == "ACTIVE"} {
						::hotmail::setUnreadMessages [expr { [::hotmail::unreadMessages] + 1}]
						::hotmail::addFrom $from $fromaddr
						cmsn_draw_online 0 1
						
						set evPar(from) from
						set evPar(fromaddr) fromaddr
						::plugins::PostEvent newmail evPar
						
						if { [::config::getKey notifyemail] == 1 } {
							::amsn::notifyAdd "[trans newmailfrom $from $fromaddr]" \
							    [list ::hotmail::gotURL $msgurl $posturl $id] newemail email
						}
					} else {
						set evPar(from) from
						set evPar(fromaddr) fromaddr
						::plugins::PostEvent newmailother evPar
						
						if { [::config::getKey notifyemailother] == 1 } {
							::amsn::notifyAdd "[trans newmailfromother $from $fromaddr]" \
							    [list ::hotmail::gotURL $msgurl $posturl $id] newemail email
						}
					}
				}

				::log::event email $from
	
			}
			"text/x-msmsgsinitialemailnotification" {
			#Get the number of unread messages obsolete by MSNP11
				#Number of unread messages in inbox
				set noleidos [$message getField Inbox-Unread]
				#Get the URL of inbox directory in hotmail
				set msgurl [$message getField Inbox-URL]
				status_log "Hotmail: $noleidos unread emails\n"
				#Remember the number of unread mails in inbox and create a notify window if necessary
				if { [string length $noleidos] > 0 && $noleidos != 0} {
					::hotmail::setUnreadMessages $noleidos
					::hotmail::emptyFroms
					cmsn_draw_online 0 1
					if { [::config::getKey notifyemail] == 1} {
						::amsn::notifyAdd "[trans newmail $noleidos]" \
							"::hotmail::hotmail_login" newemail email
					}
				}
	
	
				#Number of unread messages in other folders
				set folderunread [$message getField Folders-Unread]
				#URL of folder directory in Hotmail
				set msgurl [$message getField Folders-URL]
				status_log "Hotmail: $folderunread unread emails in others folders \n"
				#If the pref notifyemail is active and more than 0 email unread, show a notify on connect
				if { [::config::getKey notifyemailother] == 1 && [string length $folderunread] > 0 && $folderunread != 0 } {
					::amsn::notifyAdd "[trans newmailfolder $folderunread]" \
					    [list ::hotmail::gotURL $msgurl] newemail email
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
					cmsn_draw_online 0 1
				}
			}

			"text/x-msmsgsoimnotification" {
				handleMailData [$message getField Mail-Data]
			}
		}	
		#End by AIM
		# dock mail icon 
		send_dock "MAIL" [::hotmail::unreadMessages]
		status_log "hotmail_procmsg: Finishing\n"

	}

}


