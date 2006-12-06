###################################################################
#                   aMSN gNotify Plugin                           #
#                    By Youness Alaoui                            #
#                        KaKaRoTo                                 #
#                                                                 #
#                   Based on Pop3 plugin                          #
###################################################################


namespace eval ::gnotify {
	variable config
	variable configlist

	for {set acntn 0} {$acntn < 10} {incr acntn} {
		variable status_$acntn 0
		variable info_$acntn [list]
		variable oldmails_$acntn 0
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
			minutes {5}
			accounts {1}
		}

		for {set acntn 0} {$acntn < 10} {incr acntn} {
			array set ::gnotify::config [ list \
							  user_[set acntn] {username@gmail.com} \
							  passe_[set acntn] [::gnotify::encrypt ""] \
							  notify_[set acntn] {1} \
							 ]
		}

		set ::gnotify::configlist [list \
					       [list str [trans check_minutes] minute] \
					       [list frame ::gnotify::populateframe ""] \
					      ]

		::skin::setPixmap gnotify_new gnotify_new.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap gnotify_empty gnotify_empty.gif pixmaps [file join $dir pixmaps]


		#Load lang files
		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir

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
		catch {
			# Make sure there isn't duplicat calls
			after cancel ::gnotify::check
			
			set ::gnotify::checkingnow 1
			
			for {set acntn 0} {$acntn < $::gnotify::config(accounts)} {incr acntn} {
				::gnotify::check_gmail $::gnotify::config(user_$acntn) [::gnotify::decrypt $::gnotify::config(passe_$acntn)] $acntn
			}

			# Call itself again after x minutes
			set time [expr {int($::gnotify::config(minute) *60000)}]
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
	#	acntn ->  The number of the account to notify for
	# Results:
	#	A notify window pops up when required.
	proc notify { acntn } {
		variable info_$acntn

		array set info [set info_$acntn]

		if { $::gnotify::config(notify_$acntn) == 1 } {
			switch -- $info(nb_mails) {
				1  { set mailmsg "[trans onenewmail]" }
				2  { set mailmsg "[trans twonewmail 2]"	}
				default { set mailmsg "[trans newmail $info(nb_mails)]" }
			}
		
			::amsn::notifyAdd "[set ::gnotify::config(user_$acntn)]\n$mailmsg" "launch_browser {http://mail.google.com}" newemail plugins
		
			
			#If Growl plugin is loaded, show the notification, Mac OS X only
			if { [info commands growl] != "" } {
				catch {growl post Pop GMAIL $mailmsg}
			}
		}
	}

	proc encrypt { password } {
		binary scan [::des::encrypt pasencky $password] h* encpass
		return $encpass
	}

	proc decrypt { key } {
		set password [::des::decrypt pasencky [binary format h* $key]]
		return $password
	}

	proc encryptField { val text } {
		set ::gnotify::config(passe_$val) [::gnotify::encrypt $text]
		return 1
	}
	


	# ::gnotify::draw
	# Description:
	#	Adds a line in the contact list of the number of emails drawn for each account
	# Arguments:
	#	acntn   -> The number of the account to notify for
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc draw_no {acntn evPar} {
		upvar 3 $evPar vars
		variable info_$acntn
		variable status_$acntn
		variable oldmails_$acntn

		array set info [set info_$acntn]

		#TODO: add parameter to event and get rid of hardcoded variable
		set pgtop $::pgBuddyTop
		set clbar $::pgBuddyTop.colorbar
		
		set textb $pgtop.gnotifymail_$acntn
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
		} else {
			set img gnotify_empty
		}
		clickableImage $textb popmailpic_$acntn $img {after cancel ::gnotify::check; after 1 ::gnotify::check} [::skin::getKey mailbox_xpad] [::skin::getKey mailbox_ypad]
		
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
		$textb tag bind $textb.popmailpic_$acntn <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		$textb tag bind $textb.popmailpic_$acntn <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		$textb tag bind $textb.popmailpic_$acntn <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		
		if { [set status_$acntn] == 0 } {
			set mailmsg "[trans not_checked] ([set ::gnotify::config(user_$acntn)])"
		} elseif { [set status_$acntn] == 1 } {
			set mailmsg "[trans checking] ([set ::gnotify::config(user_$acntn)])"
		} elseif { [set status_$acntn] == 3 } {
			set mailmsg "[trans error_checking] ([set ::gnotify::config(user_$acntn)])"
		} elseif { $info(nb_mails) == 0 } {
			set mailmsg "[trans nonewmail] ([set ::gnotify::config(user_$acntn)])"
		} elseif { $info(nb_mails) == 1} {
			set mailmsg "[trans onenewmail] ([set ::gnotify::config(user_$acntn)])"
		} elseif { $info(nb_mails) == 2} {
			set mailmsg "[trans twonewmail 2] ([set ::gnotify::config(user_$acntn)])"
		} else {
			set mailmsg "[trans newmail $info(nb_mails)] ([set ::gnotify::config(user_$acntn)])"
		}
		
		set maxw [expr [winfo width [winfo parent $pgtop]]-[image width [::skin::loadPixmap $img]]-(2*[::skin::getKey mailbox_xpad])]
		set short_mailmsg [trunc $mailmsg $textb $maxw splainf]

		$textb tag conf gnotifymail_$acntn -fore black -underline false -font splainf
		$textb tag conf gnotifymail_$acntn -underline true
		$textb tag bind gnotifymail_$acntn <Enter> "$textb tag conf gnotifymail_$acntn -under false;$textb conf -cursor hand2"
		$textb tag bind gnotifymail_$acntn <Leave> "$textb tag conf gnotifymail_$acntn -under true;$textb conf -cursor left_ptr"
		
		$textb tag bind gnotifymail_$acntn <Button1-ButtonRelease> "$textb conf -cursor watch; after 1 [list launch_browser {http://mail.google.com}]"
		
		$textb tag bind gnotifymail_$acntn <Button3-ButtonRelease> "after 1 [list ::gnotify::rightclick %X %Y $acntn]"
		
		set balloon_message "$mailmsg"
		$textb tag bind gnotifymail_$acntn <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		$textb tag bind gnotifymail_$acntn <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		$textb tag bind gnotifymail_$acntn <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		$textb insert end "$short_mailmsg" [list gnotifymail_$acntn dont_replace_smileys]
		
		$textb configure -state disabled

		if { [info exists info(nb_mails)] && [set status_$acntn] == 2} {
			if {$info(nb_mails) > [set oldmails_$acntn] } {
				notify $acntn
			}
			set oldmails_$acntn $info(nb_mails)
		}

	}

	proc tell_no {acnt} {
		variable info_$acnt

		array set info [set info_$acnt]
		if { $info(errors) > 0 } {
			puts "Error parsing GData : [::http::data $token]"
		} else {
			puts "You have $info(nb_mails) new emails in your inbox"
			set i 0
			foreach mail_l $info(mails) {
				incr i
				array set mail $mail_l
				puts "\n\n($i/$info(nb_mails)) "
				foreach tag $mail(tags) {
					if {$tag == "^t" } {
						puts -nonewline "(*)"
					}
				}
				if {[llength $mail(authors)] == 1 } {
					set author_l [lindex $mail(authors) 0]
					array set author $author_l
					set author_l $author(author)
					array set author $author_l
					puts -nonewline "$author(nick) <$author(email)>"						
				} else {
					foreach author_l $mail(authors) {
						array set author $author_l
						set author_l $author(author)
						array set author $author_l
						puts -nonewline "$author(nick), "
						
					}
				}
				if { $mail(threads) > 1 } { 
					puts "($mail(threads))"
				} else {
					puts ""
				}
				puts "$mail(subject) || $mail(body)"
				if {[llength $mail(attachments)] > 0 } {
					puts -nonewline "Attachments : "
					foreach att $mail(attachments) {
						puts "$att "
					}
				}
			#	if {[llength $mail(tags)] > 0 } {
			#		puts -nonewline "tags : "
			#		foreach tag $mail(tags) {
			#			puts -nonewline "$tag, "
			#		}
			#	}
				puts ""
			}
		}
	}

	# ::gnotify::draw
	# Description:
	#	Adds a line in the contact list of the number of emails drawn for each account
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc draw {event evPar} {
		for {set acntn 0} {$acntn < $::gnotify::config(accounts)} {incr acntn} {
			::gnotify::draw_no $acntn $evPar
		}
	}
	
	
	# ::gnotify::rightclick
	# Description:
	#	Creates a right click menu to delete an email
	# Arguments:
	#	x  -> x position where to display
	#	y  -> y position where to display
	#	acntn   -> The number of the account to create for
	proc rightclick { X Y acntn} {
		variable info_$acntn
		
		array set info [set info_$acntn]

		set rmenu .gnotifyrightmenu
		destroy $rmenu

		menu $rmenu -tearoff 0 -type normal

		if {[info exists info(nb_mails)] } {
			set new $info(nb_mails)
		} else {
			set new "?"
		}
		
		$rmenu add command -label [trans view_inbox $new] -command {after 1 [list launch_browser {http://mail.google.com}]}
		$rmenu add separator
		$rmenu add command -label [trans check_now] -command ::gnotify::check
		$rmenu add command -label [trans tell_me] -command [list ::gnotify::tell_no $acntn]
		$rmenu add command -label [trans options] -command ::gnotify::Options
		
		$rmenu add separator

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

	proc check_gmail { username password acnt } {
		variable user_cookies
		variable status_$acnt

		set status_$acnt 1
		cmsn_draw_online
		
		if { [info exists user_cookies($username,$password,gv)] && [info exists user_cookies($username,$password,sid)]} {
			if { [info exists user_cookies($username,$password,s)] } {
				set cookie [join [list [set user_cookies($username,$password,gv)] [set user_cookies($username,$password,sid)] [set user_cookies($username,$password,s)]] "; "]
			} else {
				set cookie [join [list [set user_cookies($username,$password,gv)] [set user_cookies($username,$password,sid)]] "; "]
			}
			set headers [list Cookie $cookie]
			http::geturl "http://mail.google.com/mail/?ui=pb" -headers $headers -command [list ::gnotify::check_gmail_callback $username $password $acnt]
		} else {
			authenticate_gmail $username $password [list ::gnotify::check_gmail $username $password $acnt]
		}
		return 
	}

	proc check_gmail_callback { username password acnt token } {
		variable user_cookies
		upvar #0 $token state
		variable status_$acnt
		variable info_$acnt

		set meta $state(meta)
		if { [::http::ncode $token] == 200 } {
			foreach {key val} $meta {
				if { $key == "Set-Cookie"} {
					foreach cookie [split $val ";"] {
						if {[lindex [split $cookie "="] 0] == "S" } {
							set user_cookies($username,$password,s) $cookie	
						} 
					}
				}
			}

		
			set info_$acnt [parseGData [::http::data $token]]

			array set info [set info_$acnt]
			if { $info(errors) > 0 } {
				set status_$acnt 3
				cmsn_draw_online
			} else {
				set status_$acnt 2
				cmsn_draw_online
			}
			
		} else {
			# Should be a 'moved' where Location points to the auth server with the option &continue=... redirecting to this url again..
			puts "ERROR : $token"
		}
	}
	
	proc authenticate_gmail { username password callback } {
		package require http
		package require tls
		package require base64
		#bind the https in order to use tls
		http::register https 443 ::tls::socket
		
		set headers [list Authorization "Basic [base64::encode $username:$password]"]
		http::geturl "https://www.google.com/accounts/ServiceClientLogin?service=mail" -headers $headers \
		    -command [list ::gnotify::authenticate_gmail_callback $username $password $callback]
	}

	proc authenticate_gmail_callback { username password callback token } {
		variable user_cookies
		upvar #0 $token state
		set meta $state(meta)


		if { [::http::ncode $token] == 200 } {
			foreach {key val} $meta {
				if { $key == "Set-Cookie" ||  $key == "X-Set-Google-Cookie" } {
					foreach cookie [split $val ";"] {
						set k [lindex [split $cookie "="] 0]
						if {$k == "SID" } {
							set user_cookies($username,$password,sid) $cookie
						} elseif { $k == "GV" } {
							set user_cookies($username,$password,gv) $cookie				
						}
					}
				}
			}				
			eval $callback
		} elseif {[::http::ncode $token] == 401 } {
			array set meta_array $meta 
			if {[info exists meta_array(WWW-Authenticate)] && [lindex $meta_array(WWW-Authenticate) 0] == "basic"} {
				puts "Wrong username/password : $token"
			} else {
				puts "Unknown authentication realm"
			}
		}
	}

	proc GetByte { var } {
		upvar 1 $var data

		binary scan $data(bin) @$data(offset)H2 byte
		incr data(offset)
		return [expr 0x$byte]
	}

	proc GetBytes { var size } {
		upvar 1 $var data
		set offset $data(offset)
		set bytes [string range $data(bin) $offset [expr {$offset + $size - 1}]]
		incr data(offset) $size
		return $bytes
	}
	proc GetMultiByte { var } {
		upvar 1 $var $var
		set byte [GetByte $var]
		set multi [expr {$byte & ~0x80}]
		while { [expr {$byte & 0x80}] != 0 } {
			set byte [GetByte $var]
			incr multi [expr {0x80 * $byte} ]
		}
		return $multi
	}

	proc ReadKey { var } {
		upvar 1 $var $var
		return [GetMultiByte $var]
	}

	proc ReadSize { var } {
		upvar 1 $var $var
		return [GetMultiByte $var]
	}

	proc DecodeString { str } {
		set start 0
		while { [set start [string first "&#" $str $start]] != -1} {
			set end [string first ";" $str $start]
			set char [format "%c" [string range $str [expr {$start + 2}] [expr {$end - 1}]]]
			set str [string replace $str $start $end $char]
		}
		set str [string map { "&quot;" "\"" "&hellip;" "..." "&lt;" "<" "&gt;" ">"  "&amp;" "&"} [encoding convertfrom identity $str]]
		return $str
	}

	proc GetMailAuthor {var size } {
		upvar 1 $var $var
		upvar 1 $var data

		set start $data(offset)
		set end [expr {$start + $size}]
		set info(author) [list email "" nick ""]
		set info(errors) 0

		while {$data(offset) < $end } {
			set key [ReadKey data]
			switch -- $key {
				10 {
					set size [ReadSize data]
					set offset $data(offset)
					set info(author) [GetMailAuthor2 data $size]
					set data(offset) [expr {$offset + $size}]	
				}
				16 {
					# unknown
					GetMultiByte $var
				}
				24 {
					# unknown
					GetMultiByte $var
				} 
				default {
					puts "Unknown author key : $key"
					incr info(errors)
				}
			}
		}
		return [array get info]
	}

	proc GetMailAuthor2 {var size } {
		upvar 1 $var $var
		upvar 1 $var data

		set start $data(offset)
		set end [expr {$start + $size}]

		set info(email) ""
		set info(nick) ""
		set info(errors) 0

		while {$data(offset) < $end } {
			set key [ReadKey data]
			switch -- $key {
				10 {
					set size [ReadSize data]
					set email [DecodeString [GetBytes data $size]]
					set info(email) $email
				}
				18 {
					set size [ReadSize data]
					set nick [DecodeString [GetBytes data $size]]
					set info(nick) $nick
				}
				default {
					puts "Unknown author key : $key"
					incr info(errors)
				}
			}
		}
		return [array get info]
	}

	proc GetNewMail { var size } {
		upvar 1 $var $var
		upvar 1 $var data

		set start $data(offset)
		set end [expr {$start + $size}]
		set timestamp_size [GetMultiByte $var]

		set info(timestamp) [GetBytes data $timestamp_size]
		set info(attachments) [list]
		set info(tags) [list]
		set info(authors) [list]
		set info(subject) ""
		set info(body) ""
		set info(threads) 1
		set info(errors) 0

		while {$data(offset) < $end } {
			set key [ReadKey data]
			switch -- $key {
				130 {
					set size [ReadSize data]
					set tag [GetBytes data $size]
					lappend info(tags) $tag
				}
				146 {
					# from
					set size [ReadSize data]
					set offset $data(offset)
					lappend info(authors) [GetMailAuthor data $size]
					set data(offset) [expr {$offset + $size}]
				}
				152 {
					# unknown
					GetMultiByte $var
				}
				162 {
					set size [ReadSize data]
					set subject [DecodeString [GetBytes data $size]]
					set info(subject) $subject
				}
				170 {
					set size [ReadSize data]
					set body [DecodeString [GetBytes data $size]]
					set info(body) $body
				}
				178 {
					set size [ReadSize data]
					set attachment [DecodeString [GetBytes data $size]]
					lappend info(attachments) $attachment
				}
				184 {
					set info(threads) [GetMultiByte data]
				}
				default {
					puts "Unknown email key : $key"
					incr info(errors)
				}
			}
		}
		return [array get info]

	}

	proc parseGData { data_bin } {
		set data(bin) $data_bin
		set data(len) [string length $data_bin]
		set data(offset) 0

		set info(mails) [list]
		set info(nb_mails) 0
		set info(errors) 0


		set fd [open D://test.bin w]
		fconfigure $fd -translation binary
		puts -nonewline $fd $data_bin
		close $fd

		
		while {$data(offset) < $data(len)} {
			set key [ReadKey data]
			switch -- $key {
				10 {
					set size [ReadSize data]
					set offset $data(offset)
					lappend info(mails) [GetNewMail data $size]
					set data(offset) [expr {$offset + $size}]
				}
				136 {
					set info(nb_mails) [GetMultiByte data]
				}
				default {
					puts "Unknown key : $key"
					incr info(errors)
				}
			}
		}
		return [array get info]
	}
	
}
