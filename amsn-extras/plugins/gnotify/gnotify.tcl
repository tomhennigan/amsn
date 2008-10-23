###################################################################
#                   aMSN gNotify Plugin                           #
#                    By Youness Alaoui                            #
#                        KaKaRoTo                                 #
#                                                                 #
#                   Based on Pop3 plugin                          #
###################################################################


# For more information on the format and protocol read this article :
# http://www.amsn-project.net/wiki/index.php/Gmail
namespace eval ::gnotify {
	variable config
	variable configlist

	for {set acnt 0} {$acnt < 10} {incr acnt} {
		variable status_$acnt 0
		variable info_$acnt [list errors 0 mails [list]]
		variable notified_$acnt 0
	}

	#######################################################################################
	#######################################################################################
	####            Initialization Procedure (Called by the Plugins System)            ####
	#######################################################################################
	#######################################################################################

	proc Init { dir } {
		::plugins::RegisterPlugin gnotify
		::plugins::RegisterEvent gnotify OnConnect start
		::plugins::RegisterEvent gnotify OnDisconnect stop
		::plugins::RegisterEvent gnotify ContactListColourBarDrawn draw

		array set ::gnotify::config {
			minutes {1}
			accounts {1}
		}

		#Load lang files
		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir

		for {set acnt 0} {$acnt < 10} {incr acnt} {
			array set ::gnotify::config [ list \
							  user_[set acnt] {username@gmail.com} \
							  passe_[set acnt] [::gnotify::encrypt ""] \
							  notify_[set acnt] {1} \
							  known_mids_$acnt [list]
						     ]
		}

		set ::gnotify::configlist [list \
					       [list str [trans check_minutes] minutes] \
					       [list frame ::gnotify::populateframe ""] \
					      ]

		::skin::setPixmap gnotify_new gnotify_new.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap gnotify_empty gnotify_empty.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap gnotify_error gnotify_error.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap attachment paperclip.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap star star.gif pixmaps [file join $dir pixmaps]


		set ::gnotify::checkingnow 0
		
		#only start checking now if already online
		if { (!$::initialize_amsn) && ([::MSN::myStatusIs] != "FLN") } {
			::gnotify::start 0 0
		}
	}

	proc DeInit { } {
		::gnotify::stop 0 0
	}

	proc populateframe { win } {
		#total number of accounts
		frame $win.num
		label $win.num.label -text [trans num_accounts]
		combobox::combobox $win.num.accounts -editable false -highlightthickness 0 -width 3 -bg #FFFFFF -font splainf -textvariable ::gnotify::config(accounts)
		for { set i 1 } { $i < 11 } { incr i } {
			$win.num.accounts list insert end $i
		}
		#$win.num.accounts select 0
		pack $win.num.label -side left -anchor w
		pack $win.num.accounts -side left -anchor w
		pack $win.num -anchor w -padx 20

		#frame around selections
		framec $win.c -bc #0000FF
		set f [$win.c getinnerframe]
		pack $win.c -anchor w -padx 20

		#current selection box
		frame $f.num
		label $f.num.label -text [trans account_settings] 
		combobox::combobox $f.num.account -editable false -highlightthickness 0 -width 3 -bg #FFFFFF -font splainf
		for { set i 1 } { $i < 11 } { incr i } {
			$f.num.account list insert end $i
		}
		$f.num.account select 0
		pack $f.num.label -side left -anchor w
		pack $f.num.account -side left -anchor w
		pack $f.num -anchor w

		
		#user name
		frame $f.user
		label $f.user.label -text [trans username]
		entry $f.user.entry -textvariable ::gnotify::config(user_0) -bg white
		pack $f.user.label -side left -anchor w
		pack $f.user.entry -side left -anchor w
		pack $f.user -anchor w

		#password
		frame $f.pass
		label $f.pass.label -text [trans password]
		entry $f.pass.entry -show "*" -bg white -validate all -validatecommand  [list ::gnotify::encryptField 0 %P]
		$f.pass.entry insert end [gnotify::decrypt $::gnotify::config(passe_0)]
		pack $f.pass.label -side left -anchor w
		pack $f.pass.entry -side left -anchor w
		pack $f.pass -anchor w

		#Show notify
		checkbutton $f.notify -text [trans show_notify] -variable ::gnotify::config(notify_0)
		pack $f.notify -anchor w


		$win.num.accounts configure -command [list ::gnotify::switchnumaccounts $f]
		::gnotify::switchnumaccounts $f $win.num.accounts [$win.num.accounts get]
		$f.num.account configure -command [list ::gnotify::switchconfig $f]
	}

	proc switchconfig { f widget val } {
		incr val -1

		$f.user.entry configure -textvariable ::gnotify::config(user_$val)
		$f.pass.entry configure -validate none
		$f.pass.entry configure -validatecommand [list ::gnotify::encryptField $val %P]
		$f.pass.entry delete 0 end
		$f.pass.entry insert end [gnotify::decrypt $::gnotify::config(passe_$val)]
		$f.pass.entry configure -validate all
		$f.notify configure -variable ::gnotify::config(notify_$val)
	}

	proc switchnumaccounts { f widget val } {
		set oldval [$f.num.account get]

		
		$f.num.account list delete 0 end
		for { set i 1 } { $i <= $val } { incr i } {
			$f.num.account list insert end $i
		}
		if { $oldval < $val } {
			incr oldval -1
			$f.num.account select $oldval
		} else {
			$f.num.account select 0
		}
	}


	# ::gnotify::check
	# Description:
	#	Continuously check the number of emails for each of the accounts
	# Arguments: None
	# Results:
	#	An integer variable wich contains the number of mails in the mbox
	proc check { } {

		if { ![info exists ::gnotify::config(minutes)] || ![string is digit $::gnotify::config(minutes)] || $::gnotify::config(minutes) == "" } {
			set ::gnotify::config(minutes) 1
		}
		# Call itself again after x minutes
		set time [expr {int($::gnotify::config(minutes) *60000)}]

		if { [catch {
			# Make sure there isn't duplicat calls
			after cancel ::gnotify::check
			
			set ::gnotify::checkingnow 1
			
			for {set acnt 0} {$acnt < $::gnotify::config(accounts)} {incr acnt} {
				if { [catch { ::gnotify::check_gmail $acnt } res ] } {
					plugins_log gnotify "Error checking account $acnt : $res\n$::errorInfo"

					variable status_$acnt

					set status_$acnt -3
					set info_$acnt [list errors 1 mails [list]]
					cmsn_draw_online
				}
			}

			after $time ::gnotify::check

			set ::gnotify::checkingnow 0
		} res] } {
			plugins_log gnotify "Error during check : $res\n$::errorInfo"

			after cancel ::gnotify::check
			after $time ::gnotify::check

			set ::gnotify::checkingnow 0
		}
	}
	
	# ::gnotify::start
	# Description:
	#	Starts checking for new messages
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc start {event evPar} {
		#cancel any previous starts first
		catch { after cancel ::gnotify::check }
		catch { after 5000 ::gnotify::check }
		
		for {set acnt 0} {$acnt < 10} {incr acnt} {
			variable notified_$acnt 0
		}

		cmsn_draw_online
	}


	# ::gnotify::stop
	# Description:
	#	Stops checking for new messages
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc stop {event evPar} {
		catch { after cancel ::gnotify::check }
		#If online redraw main window to remove new line
		#Doesn't work yet, as events are still triggered after unload (need to fix)
		if { (!$::initialize_amsn) && ([::MSN::myStatusIs] != "FLN") } {
			cmsn_draw_online
		}
	}




	# ::gnotify::notify
	# Description:
	#	Posts a notification of new emails.
	# Arguments:
	#	acnt ->  The number of the account to notify for
	# Results:
	#	A notify window pops up when required.
	proc notify { acnt } {
		variable info_$acnt

		array set info [set info_$acnt]

		if { $::gnotify::config(notify_$acnt) == 1 } {
			switch -- $info(nb_mails) {
				1  { set mailmsg "[trans onenewmail]" }
				2  { set mailmsg "[trans twonewmail 2]"	}
				default { set mailmsg "[trans newmail $info(nb_mails)]" }
			}
			
			::amsn::notifyAdd "[set ::gnotify::config(user_$acnt)]\n$mailmsg" [list ::gnotify::open_gmail_account $acnt] newemail plugins
			
			
			#If Growl plugin is loaded, show the notification, Mac OS X only
			if { [info commands growl] != "" } {
				catch {growl post Pop GMAIL $mailmsg}
			}
		}
	}
	
	proc encrypt { password } {
		binary scan [::des::encrypt pasencky "${password}\n"] h* encpass
		return $encpass
	}

	proc decrypt { key } {
		set password [::des::decrypt pasencky [binary format h* $key]]
		set password [string range $password 0 [expr { [string first "\n" $password] -1 }]]
		return $password
	}

	proc encryptField { val text } {
		set ::gnotify::config(passe_$val) [::gnotify::encrypt $text]
		return 1
	}
	
	proc buildFromField { authors } {
		set first 1
		set from ""
		foreach author_l $authors {
			array set author $author_l
			set id_l $author(id)
			array set id $id_l
			if {[llength $authors] == 1 } {
				append from "$id(nick) <$id(email)>"
			} else {
				if {$first == 0 } {
					append from ", "
				}
				if { $author(has_unread) == 1 } {
					append from "*"
				}
				append from "$id(nick)"
				set first 0
			}					
		}
		set from
	}


	# ::gnotify::draw
	# Description:
	#	Adds a line in the contact list of the number of emails drawn for each account
	# Arguments:
	#	acnt   -> The number of the account to notify for
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc draw_no {acnt evPar} {
		upvar 3 $evPar vars
		variable info_$acnt
		variable status_$acnt

		array set info [set info_$acnt]

		#TODO: add parameter to event and get rid of hardcoded variable
		set pgtop $::pgBuddyTop
		set clbar $::pgBuddyTop.colorbar
		
		set textb $pgtop.gnotifymail_$acnt
		text $textb -font bboldf -height 1 -background [::skin::getKey topcontactlistbg] -borderwidth 0 -wrap none -cursor left_ptr \
		    -relief flat -highlightthickness 0 -selectbackground white -selectborderwidth 0 \
		    -exportselection 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0

		if {[::skin::getKey emailabovecolorbar]} {
			pack $textb -expand true -fill x -after $clbar -side bottom -padx 0 -pady 0
		} else {
			pack $textb -expand true -fill x -before $clbar -side bottom -padx 0 -pady 0
		}
		
		$textb configure -state normal

		if { [info exists info(nb_mails)] && $info(nb_mails) > 0} {
			set img gnotify_new
		} elseif { [set status_$acnt] < 0} {
			set img gnotify_error
		} else {
			set img gnotify_empty
		}
		clickableImage $textb popmailpic_$acnt $img {after cancel ::gnotify::check; after 1 ::gnotify::check} [::skin::getKey mailbox_xpad] [::skin::getKey mailbox_ypad]
		
		set mailheight [expr [image height [::skin::loadPixmap $img]]+(2*[::skin::getKey mailbox_ypad])]
		#in windows need an extra -2 is to include the extra 1 pixel above and below in a font
		if {$::tcl_platform(platform) == "windows"} {
			set mailheight [expr $mailheight - 2]
		}
		set textheight [font metrics splainf -linespace]
		if { $mailheight < $textheight } {
			set mailheight $textheight
		}
		$textb configure -font "{} -$mailheight"

		set balloon_message [trans click_to_check] 
		$textb tag bind $textb.popmailpic_$acnt <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		$textb tag bind $textb.popmailpic_$acnt <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		$textb tag bind $textb.popmailpic_$acnt <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		
		if { [set status_$acnt] == 0 } {
			set mailmsg "[trans not_checked] ([set ::gnotify::config(user_$acnt)])"
		} elseif { [set status_$acnt] == 1 } {
			set mailmsg "[trans checking] ([set ::gnotify::config(user_$acnt)])"
		} elseif { [set status_$acnt] == -1 } {
			set mailmsg "[trans wrong_pass] ([set ::gnotify::config(user_$acnt)])"
		} elseif { [set status_$acnt] == -2 } {
			set mailmsg "[trans account_locked] ([set ::gnotify::config(user_$acnt)])"
		} elseif { [set status_$acnt] == -3 } {
			set mailmsg "[trans error_checking] ([set ::gnotify::config(user_$acnt)])"
		} elseif { $info(nb_mails) == 0 } {
			set mailmsg "[trans nonewmail] ([set ::gnotify::config(user_$acnt)])"
		} elseif { $info(nb_mails) == 1} {
			set mailmsg "[trans onenewmail] ([set ::gnotify::config(user_$acnt)])"
		} elseif { $info(nb_mails) == 2} {
			set mailmsg "[trans twonewmail 2] ([set ::gnotify::config(user_$acnt)])"
		} else {
			set mailmsg "[trans newmail $info(nb_mails)] ([set ::gnotify::config(user_$acnt)])"
		}
		
		set maxw [expr [winfo width [winfo parent $pgtop]]-[image width [::skin::loadPixmap $img]]-(2*[::skin::getKey mailbox_xpad])]
		set short_mailmsg [trunc $mailmsg $textb $maxw splainf]

		$textb tag conf gnotifymail_$acnt -fore black -underline false -font splainf
		$textb tag conf gnotifymail_$acnt -underline true
		$textb tag bind gnotifymail_$acnt <Enter> "$textb tag conf gnotifymail_$acnt -under false;$textb conf -cursor hand2"
		$textb tag bind gnotifymail_$acnt <Leave> "$textb tag conf gnotifymail_$acnt -under true;$textb conf -cursor left_ptr"
		
		$textb tag bind gnotifymail_$acnt <Button1-ButtonRelease> "$textb conf -cursor watch; after 1 [list ::gnotify::open_gmail_account $acnt]"
		
		$textb tag bind gnotifymail_$acnt <Button3-ButtonRelease> "after 1 [list ::gnotify::rightclick %X %Y $acnt]"
		
		set balloon_message "$mailmsg"

		if { [set status_$acnt] == 2 } {
			foreach mail_l $info(mails) {
				append balloon_message "\n"
				array set mail $mail_l
				foreach tag $mail(tags) {
					if {$tag == "^t" } {
						append balloon_message "(*)"
					}
				}
				append balloon_message [buildFromField $mail(authors)]
				append balloon_message " : $mail(subject)"
			}
		}

		$textb tag bind gnotifymail_$acnt <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		$textb tag bind gnotifymail_$acnt <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		$textb tag bind gnotifymail_$acnt <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		$textb insert end "$short_mailmsg" [list gnotifymail_$acnt dont_replace_smileys]
		
		$textb configure -state disabled

		if { [set ::gnotify::config(notify_$acnt)] == 1 && [info exists info(nb_mails)] && [set status_$acnt] == 2} {
			foreach mail_l $info(mails) {
				array set mail $mail_l
				if {[lsearch [set ::gnotify::config(known_mids_$acnt)] $mail(mid)] == -1} {
					::amsn::notifyAdd "[trans receivedmail [buildFromField $mail(authors)]]" \
					    [list ::gnotify::open_gmail_account $acnt] newemail
					lappend ::gnotify::config(known_mids_$acnt) $mail(mid)
				}
			}
			variable notified_$acnt
			if {[set notified_$acnt] == 0 && $info(nb_mails) > 0 } {
				notify $acnt
				set notified_$acnt 1
			}
		}

	}

	proc tell_no {acnt} {
		variable info_$acnt
		variable status_$acnt
		
		set w .gnotify_tell_me
		set sw $w.sw
		set t $sw.msg
		set close $w.close
		if { [winfo exists $w] } {
			destroy $w
		}
		toplevel $w

		wm title $w "[trans mail_info [set ::gnotify::config(user_$acnt)]]"

		ScrolledWindow $sw -auto vertical -scrollbar vertical -ipad 0
		text $t -relief solid -background [::skin::getKey chat_output_back_color] \
			-setgrid 0 -wrap word -exportselection 1 -highlightthickness 0 -selectborderwidth 1 

		$t tag configure subject -font sboldf
		$t tag configure author_read -underline on -font sitalf
		$t tag configure author_unread -underline on -font sbolditalf
		$t tag configure mail_threads -font sboldf
		$t tag configure author_pli -foreground darkred
		$t tag configure body -font sitalf
		$t tag configure glabel -foreground darkgreen
		$t tag configure datefmt -foreground darkblue
		$t tag configure attachmentfmt -foreground darkred

		$sw setwidget $t
		button $close -text "[trans close]" -command "destroy $w"

		array set info [set info_$acnt]
		if { [set status_$acnt] == 0 } {
			$t insert end "[trans not_checked]"
		} elseif { [set status_$acnt] == 1 } {
			$t insert end "[trans checking]"
		} elseif { [set status_$acnt] == -1 } {
			$t insert end  "[trans wrong_pass]"
		} elseif { [set status_$acnt] == -2 } {
			$t insert end  "[trans account_locked]"
		} elseif { [set status_$acnt] == -3 } {
			$t insert end  "[trans error_checking]"
		} else {
			$t insert end  "[trans gotmail $info(nb_mails)]"
			set i 0
			foreach mail_l $info(mails) {
				incr i
				array set mail $mail_l
				$t insert end "\n\n($i/$info(nb_mails)) "

				if { $mail(pli) == 1} {
					$t insert end "> " author_pli
				} elseif { $mail(pli) == 2} {
					$t insert end ">> " author_pli
				}


				foreach tag $mail(tags) {
					if {$tag == "^t" } {
						$t image create end -image [::skin::loadPixmap star]
					}
				}

				set first 1
				foreach author_l $mail(authors) {
					array set author $author_l
					set id_l $author(id)
					array set id $id_l
					if {[llength $mail(authors)] == 1 } {
						$t insert end "$id(nick)" author_unread
						$t insert end " "
						$t insert end "<$id(email)>" author_unread
 					} else {
						if {$first == 0 } {
							$t insert end ", " authors_read
						}
						if { $author(has_unread) == 1 } {
							$t insert end "$id(nick)" author_unread
							$t insert end " "
							$t insert end "<$id(email)>" author_unread
						} else {
							$t insert end "$id(nick)" author_read
							$t insert end " "
							$t insert end "<$id(email)>" author_read
						}
						set first 0
					}					
				}
				
				if { $mail(threads) > 1 } { 
					$t insert end " ($mail(threads))" mail_threads
				}
				
				$t insert end "\n"
				
				if {$mail(timestamp) != 0 } {
					$t insert end "[clock format [expr int($mail(timestamp) / 1000)] -format %c]\n" datefmt
				}

				if {[llength $mail(tags)] > 0 } {
					set first 1
					set was_label 0
					foreach tag $mail(tags) {
						if { ![regexp {^[\^]} $tag] } {
							set was_label 1
							if {$first == 0 } {
								$t insert end ", " glabel
							}
							$t insert end "$tag" glabel
							set first 0
						}
					}
					if { $was_label == 1 } {
						$t insert end " "
					}
				}
				$t insert end "$mail(subject)\n" subject
				$t insert end "$mail(body)\n" body
				if {[llength $mail(attachments)] > 0 } {
					set first 1
					foreach att $mail(attachments) {
						if {$first == 0 } {
							$t insert end ", " attachmentfmt
						}
						$t image create end -image [::skin::loadPixmap attachment]
						$t insert end "$att" attachmentfmt
						set first 0
					} 
					$t insert end "\n"
				}
			}
		}

		$t configure -state disabled
		pack $close -expand false -anchor ne -padx 3 -pady 3 -side bottom
		pack $sw -expand true -fill both -padx 3 -pady 3 -side bottom
	}

	# ::gnotify::draw
	# Description:
	#	Adds a line in the contact list of the number of emails drawn for each account
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc draw {event evPar} {
		for {set acnt 0} {$acnt < $::gnotify::config(accounts)} {incr acnt} {
			::gnotify::draw_no $acnt $evPar
		}
	}
	
	
	# ::gnotify::rightclick
	# Description:
	#	Creates a right click menu to delete an email
	# Arguments:
	#	x  -> x position where to display
	#	y  -> y position where to display
	#	acnt   -> The number of the account to create for
	proc rightclick { X Y acnt} {
		variable info_$acnt
		
		array set info [set info_$acnt]

		set rmenu .gnotifyrightmenu
		destroy $rmenu

		menu $rmenu -tearoff 0 -type normal

		if {[info exists info(nb_mails)] } {
			set new $info(nb_mails)
		} else {
			set new "?"
		}
		
		$rmenu add command -label [trans view_inbox $new] -command [list after 1 [list ::gnotify::open_gmail_account $acnt]]
		$rmenu add separator
		$rmenu add command -label [trans check_now] -command ::gnotify::check
		$rmenu add command -label [trans tell_me] -command [list ::gnotify::tell_no $acnt]
		$rmenu add command -label [trans options] -command ::gnotify::Options
		

		tk_popup $rmenu $X $Y
	}


	proc Options { } {
		if {[catch {
			::plugins::PluginGui
			set w [set ::plugins::w]
			set plugins [$w.plugin_list get 0 end]
			set gnotify_idx [lsearch $plugins "gnotify"]
			if {$gnotify_idx == -1 } {
				::plugins::GUI_Close
			} else {
				$w.plugin_list selection set $gnotify_idx
				::plugins::GUI_NewSel
				::plugins::GUI_Config
			}
			
		} ] } {
			catch {::plugins::GUI_Close}
		}
	}

	proc open_gmail_account {acnt} {
		global HOME 

		# I have to split the < html > tag into to lines (or in this comment with a space) to avoid the autoupdater to recognize it as being an html page being downloaded
		# which makes it think that the server returned an error (404 error or whatever) which had a 200 ncode but still was an error.
		set page_data {<}
		append page_data {html><head><noscript><meta http-equiv=Refresh content="0; url=http://www.gmail.com"></noscript></head>}
		append page_data {<body onload="document.pform.submit(); "><form name="pform" action="https://www.google.com/accounts/ServiceLoginAuth" method="POST">}
		append page_data {<input type="hidden" name="continue" value="http://mail.google.com/mail/">}
		append page_data {<input type="hidden" name="service" value="mail">}
		append page_data {<input type="hidden" name="rm" value="false">}  
		append page_data {<input type="hidden" name="Email" value=}
		append page_data "\"$::gnotify::config(user_$acnt)\""
		append page_data {><input type="hidden" name="Passwd" value=}
		append page_data "\"[::gnotify::decrypt $::gnotify::config(passe_$acnt)]\""
		append page_data {><input type="hidden" name="PersistentCookie" value="no">}
		append page_data {<input type="hidden" name="rmShown" value="1"> }
		append page_data {</form></body></html>}

		if { [OnUnix] } {
			set file_id [open "[file join ${HOME} gnotify.html]" w 00600]
		} else {
			set file_id [open "[file join ${HOME} gnotify.html]" w]
		}
		
		puts $file_id $page_data
		
		close $file_id
		
		if { [OnDarwin] } {
			launch_browser [file join ${HOME} gnotify.html] 1
		} else {
			launch_browser "file://${HOME}/gnotify.html" 1
		}
		after 5000 [list catch [list file delete -force [file join ${HOME} gnotify.html]]]

	}

	proc setup_http { } {
		if { [::config::getKey connectiontype] == "proxy" } {
			set proxy [::config::getKey proxy]
			set proxy_host [lindex $proxy 0]
			set proxy_port [lindex $proxy 1]
			if {$proxy_host == "" } {
				::http::config -proxyhost ""
			} else {
				if { $proxy_port == "" } {
					set proxy_port 1080
				}
				::http::config -proxyhost $proxy_host -proxyport $proxy_port
			}
			#bind the https in order to use tls
			if { [::config::getKey proxytype] == "http"} {
				http::register https 443 HTTPsecureSocket
			} else {
				http::register https 443 SOCKSsecureSocket
			}
		} else {
			::http::config -proxyhost "" -proxyport ""	
		}
	}

	proc check_gmail { acnt {url "https://mail.google.com/mail/?ui=pb"}} {
		variable user_cookies
		variable status_$acnt

		set status_$acnt 1
		cmsn_draw_online 1 2
		
		set username $::gnotify::config(user_$acnt)
		set password [::gnotify::decrypt $::gnotify::config(passe_$acnt)]

		if { [info exists user_cookies($username,$password,SID)]} {
			set cookie [buildCookie $username $password]
			set headers [list Cookie $cookie]

			setup_http
			set token [http::geturl $url -headers $headers -timeout 10000 -command [list ::gnotify::check_gmail_callback $acnt]]
		} else {
			set token [authenticate_gmail $acnt [list ::gnotify::check_gmail $acnt]]
		}

		plugins_log gnotify "Checking mail, http token is : $token"
		return 
	}

	proc check_gmail_callback { acnt token } {
		variable user_cookies
		upvar #0 $token state
		variable status_$acnt
		variable info_$acnt

		set meta $state(meta)
		#plugins_log gnotify "check $meta - [::http::ncode $token]"

		set username $::gnotify::config(user_$acnt)
		set password [::gnotify::decrypt $::gnotify::config(passe_$acnt)]

		ParseSetCookie $meta $username $password

		switch [::http::ncode $token] {
			200 {
				set info_$acnt [parseGData [::http::data $token]]
				
				array set info [set info_$acnt]
				if { $info(errors) > 0 } {
					set status_$acnt -3
					cmsn_draw_online
				} else {
					set status_$acnt 2
					cmsn_draw_online
				}
				
			} 
			401 {
				array set meta_array $meta 
				if {[info exists meta_array(WWW-Authenticate)] && [lindex $meta_array(WWW-Authenticate) 0] == "basic"} {
					plugins_log gnotify "Need to authenticate for account $username"
					after 0 [list ::gnotify::authenticate_gmail $acnt [list ::gnotify::check_gmail $acnt] $url]
				} else {
					plugins_log gnotify "Unknown authentication realm for account $username"
					set status_$acnt -1
					set info_$acnt [list errors 1 mails [list] nb_mails 0]
					cmsn_draw_online
				}
			}
			302 {
				set url ""
				foreach {key val} $meta {
					if { $key == "Location" } {	
						plugins_log gnotify "New Location is $val"
						set url $val
					}
				}
				
				if { $url != "" } {
					after 0 [list ::gnotify::authenticate_gmail $acnt [list ::gnotify::check_gmail $acnt] $url]
				} else {
					plugins_log gnotify "Unable to find Location in meta from redirect: $meta - [::http::data $token]"
					set status_$acnt -3
					set info_$acnt [list errors 1 mails [list]]
					cmsn_draw_online
				}
			}
			default {
				plugins_log gnotify "Unknown error during check_gmail for $username : [::http::ncode $token] - $meta - [::http::data $token]"
				set status_$acnt -3
				set info_$acnt [list errors 1 mails [list]]
				cmsn_draw_online
				
				# Start with a fresh config.. forces the re-authentification (in case the cookies expired)
				foreach name [array names user_cookies "$username,$password,*"] {
					array unset user_cookies $name
				}
			}
		}
		::http::cleanup $token
	}
	
	proc authenticate_gmail { acnt callback {url "https://www.google.com/accounts/ServiceClientLogin?service=mail"}} {
		package require http
		package require tls
		package require base64

		
		set username $::gnotify::config(user_$acnt)
		set password [::gnotify::decrypt $::gnotify::config(passe_$acnt)]

		set cookie [buildCookie $username $password]
		if {$cookie != "" } {
			set headers [list Cookie $cookie Authorization "Basic [base64::encode $username:$password]"]
		} else {
			set headers [list Authorization "Basic [base64::encode $username:$password]"]
		}
		plugins_log gnotify "authenticating at $url"

		setup_http
		return [http::geturl $url -headers $headers -timeout 10000 \
			    -command [list ::gnotify::authenticate_gmail_callback $acnt $callback]]
	}

	proc ParseSetCookie { meta username password } {
		variable user_cookies
		
		foreach {key val} $meta {
			if { $key == "Set-Cookie" ||  $key == "X-Set-Google-Cookie" } {
				foreach cookie [split $val ";"] {
					set c [split $cookie "="]
					set k [lindex $c 0]
					set v [lindex $c 1]
					if { $v == "EXPIRED" } {
						catch {unset user_cookies($username,$password,$k)}
					} else {
						set user_cookies($username,$password,$k) $cookie
					}
					break
				}
			}
		}			
	}

	proc buildCookie { username password } {
		variable user_cookies

		set cookie ""
		foreach name [array names user_cookies "$username,$password,*"] {
			if { $cookie == "" } {
				set cookie [set user_cookies($name)]
			} else {
				set cookie [join [list $cookie [set user_cookies($name)]] "; "]
			}
		}
		plugins_log gnotify "Cookie is : $cookie"
		return $cookie
	}

	proc authenticate_gmail_callback {acnt callback token } {
		upvar #0 $token state
		variable status_$acnt
		variable info_$acnt


		set meta $state(meta)
		#plugins_log gnotify "auth $meta - [::http::ncode $token] "
		
		set username $::gnotify::config(user_$acnt)
		set password [::gnotify::decrypt $::gnotify::config(passe_$acnt)]

		ParseSetCookie $meta $username $password
		
		switch [::http::ncode $token] {
			200 {
				eval $callback
			} 
			401 {
				array set meta_array $meta 
				if {[info exists meta_array(WWW-Authenticate)] && [lindex $meta_array(WWW-Authenticate) 0] == "basic"} {
					plugins_log gnotify "Wrong username/password for account $username"
				} else {
					plugins_log gnotify "Unknown authentication realm for account $username"
				}
				set status_$acnt -1
				set info_$acnt [list errors 1 mails [list] nb_mails 0]
				cmsn_draw_online
			}
			403 {
				plugins_log gnotify "Forbidden for account $username"
				set status_$acnt -2
				set info_$acnt [list errors 1 mails [list]]
				cmsn_draw_online
			}
			302 {
				set url ""
				foreach {key val} $meta {
					if { $key == "Location" } {	
						plugins_log gnotify "New Location is $val"
						set url $val
					}
				}
				
				if { $url != "" } {
					#
					after 0 [list ::gnotify::authenticate_gmail $acnt $callback $url]
				} else {
					plugins_log gnotify "Unable to find Location in meta from redirect: $meta - [::http::data $token]"
					set status_$acnt -3
					set info_$acnt [list errors 1 mails [list]]
					cmsn_draw_online
				}
			}
			default {
				plugins_log gnotify "Unknown error during authentification for $username : $meta - [::http::data $token]"
				set status_$acnt -3
				set info_$acnt [list errors 1 mails [list]]
				cmsn_draw_online
				
			}
		}
		::http::cleanup $token
	}

	proc GetByte { var } {
		upvar $var data

		binary scan $data(bin) @$data(offset)H2 byte
		incr data(offset)
		return [expr 0x$byte]
	}

	proc GetBytes { var size } {
		upvar $var data
		set offset $data(offset)
		set bytes [string range $data(bin) $offset [expr {$offset + $size - 1}]]
		incr data(offset) $size
		return $bytes
	}

	# this damn shit is necessary, [expr] does NOT support wide integers when doing shifts... so I get something like this :
	#     binary scan [binary format w [expr wide(0x21 << 28)]] h* s;set s
	#     0000000100000000
	# the '2' disappears if I shift 0x21 by 28 bits... 
	# This method converts the integer into big endian binary bits format, then it appends the necessary '0's then converts it back from binary bits into a wide variable
	# This way the shift works (although it's hacky and for sure non performance efficient).
	proc wide_shl { val sh } { 
		binary scan [binary format W $val] B* bin
		append bin [string repeat "0" $sh]
		set bin [string range $bin end-63 end]
		binary scan [binary format B* $bin] W* shifted
		return $shifted
	}

	proc GetMultiByte { var } {
		upvar $var $var

		set byte [GetByte $var]
		set multi [expr {$byte & ~0x80}]
		set shifts 7
		while { [expr {$byte & 0x80}] != 0 && $shifts < 64 } {
			set byte [GetByte $var]
			set multi [expr {[wide_shl [expr $byte & 0x7F] $shifts] | $multi} ]
			incr shifts 7
		}
		return $multi
	}

	proc ReadKey { var } {
		upvar $var $var
		return [GetMultiByte $var]
	}

	proc ReadSize { var } {
		upvar $var $var
		return [GetMultiByte $var]
	}

	proc DecodeString { str } {
		set start 0
		while { [set start [string first "&#" $str $start]] != -1} {
			set end [string first ";" $str $start]
			set char [format "%c" [string range $str [expr {$start + 2}] [expr {$end - 1}]]]
			set str [string replace $str $start $end $char]
		}
		set str [string map { "&quot;" "\"" "&apos;" "\'" "&hellip;" "..." "&lt;" "<" "&gt;" ">"  "&amp;" "&"} [encoding convertfrom identity $str]]
		return $str
	}

	proc GetMailAuthor {var size } {
		upvar $var $var
		upvar $var data

		set start $data(offset)
		set end [expr {$start + $size}]
		set info(id) [list errors 0 email "" nick ""]
		set info(has_unread) 0
		set info(initiator) 0
		set info(errors) 0

		while {$data(offset) < $end } {
			set key [ReadKey data]
			switch -- $key {
				10 {
					# 0x0A Author info
					set size [ReadSize data]
					set offset $data(offset)
					set info(id) [GetMailAuthor2 data $size]
					set data(offset) [expr {$offset + $size}]
					array set id $info(id)
					incr info(errors) $id(errors)
					unset id
				}
				16 {	
					# 0x10 Has unread mail
					# This key specifies whether an email of this author in the thread is unread
					if { [GetMultiByte $var] == 1} {
						set info(has_unread) 1
					} 
				}
				24 {
					# 0x18 Thread Initiator
					# This key specifies whether this user is the one who started the thread
					if { [GetMultiByte $var] == 1} {
						set info(initiator) 1
					} 
				} 
				default {
					plugins_log gnotify "Unknown author ($info(author)) key : $key"
					incr info(errors)
				}
			}
		}
		return [array get info]
	}

	proc GetMailAuthor2 {var size } {
		upvar $var $var
		upvar $var data

		set start $data(offset)
		set end [expr {$start + $size}]

		set info(email) ""
		set info(nick) ""
		set info(errors) 0

		while {$data(offset) < $end } {
			set key [ReadKey data]
			switch -- $key {
				10 {
					# 0x0A Email
					set size [ReadSize data]
					set email [DecodeString [GetBytes data $size]]
					set info(email) $email
				}
				18 {
					# 0x12 Name
					set size [ReadSize data]
					set nick [DecodeString [GetBytes data $size]]
					set info(nick) $nick
				}
				default {
					plugins_log gnotify "Unknown author key : $key"
					incr info(errors)
				}
			}
		}
		return [array get info]
	}

	proc GetNewMail { var size } {
		upvar $var $var
		upvar $var data

		set start $data(offset)
		set end [expr {$start + $size}]

		set info(timestamp) 0
		set info(mid) ""
		set info(attachments) [list]
		set info(tags) [list]
		set info(authors) [list]
		set info(subject) ""
		set info(body) ""
		set info(threads) 1
		set info(errors) 0
		set info(pli) -1


		while {$data(offset) < $end } {
			set key [ReadKey data]
			switch -- $key {
				16 {
					# 0x10 unknown / message id?
					# This looks like a time based message id... 
					set info(mid) [GetMultiByte $var]
				} 
				24 {
					# 0x18 timestamp
					# This is in epoch format but in milliseconds, not in seconds
					set info(timestamp) [GetMultiByte $var]
				}
				130 {
					# 0x82 Tag
					set size [ReadSize data]
					set tag [GetBytes data $size]
					lappend info(tags) $tag
				}
				146 {
					# 0x92 from
					set size [ReadSize data]
					set offset $data(offset)
					array set authors [GetMailAuthor data $size]

					lappend info(authors) [array get authors]
					incr info(errors) $authors(errors)
					unset authors

					set data(offset) [expr {$offset + $size}]
				}
				152 {
					# 0x98 personal level indicator
					# 0 sent by a mailing list
					# 1 sent to this address (not a mailing list)
					# 2 sent only to this adress
					set info(pli) [GetMultiByte $var]
					
				}
				162 {
					# 0xA2 Subject
					set size [ReadSize data]
					set subject [DecodeString [GetBytes data $size]]
					set info(subject) $subject
				}
				170 {
					# 0xAA Body preview
					set size [ReadSize data]
					set body [DecodeString [GetBytes data $size]]
					set info(body) $body
				}
				178 {
					# 0xB2 Attachment
					set size [ReadSize data]
					set attachment [DecodeString [GetBytes data $size]]
					lappend info(attachments) $attachment
				}
				184 {
					# 0xB8 Number of threads
					set info(threads) [GetMultiByte data]
				}
				default {
					plugins_log gnotify "Unknown email key : $key"
					incr info(errors)
				}
			}
		}
		return [array get info]

	}

	# For more information on the format and protocol read this article :
	# http://www.amsn-project.net/wiki/index.php/Gmail
	proc parseGData { data_bin } {
		set data(bin) $data_bin
		set data(len) [string length $data_bin]
		set data(offset) 0

		set info(mails) [list]
		set info(nb_mails) 0
		set info(errors) 0

		while {$data(offset) < $data(len)} {
			set key [ReadKey data]
			switch -- $key {
				10 {
					# 0x0A New mail Key
					set size [ReadSize data]
					set offset $data(offset)
					array set mails [GetNewMail data $size]

					incr info(errors) $mails(errors)
					lappend info(mails) [array get mails]
					unset mails

					set data(offset) [expr {$offset + $size}]
				}
				16 {
					# 0x10 Unknown? Found only in the ASM
					set value [GetMultiByte data]
					plugins_log gnotify "Unknown key 0x10 has value : $value"
				}
				128 {
					# 0x80 Unknown? Found only in the ASM
					set value [GetMultiByte data]
					plugins_log gnotify "Unknown key 0x80 has value : $value"
				}
				136 {
					# 0x88 Number of mails Key
					set info(nb_mails) [GetMultiByte data]
				}
				144 {
					# 0x90 Unknown??? it's new!
					set value [GetMultiByte data]
					plugins_log gnotify "Unknown key 0x90 has value : $value"
				}
				194 {
					# 0xC2 Unknown? Found only in the ASM
					set size [ReadSize data]
					set offset $data(offset)
					set data(offset) [expr {$offset + $size}]

					plugins_log gnotify "Unknown key 0xC2 of size : $size"
				}
				default {
					plugins_log gnotify "Unknown key : $key"
					incr info(errors)
				}
			}
		}
		return [array get info]
	}
	
}
