###################################################################
#                   aMSN POP3 Checker Plugin                      #
#                      By Arieh Schneier                          #
#                                                                 #
#                With small contributions from:                   #
#             Alberto Díaz and Jonas De Meulenaere                #
#                 Boris Faure (Gmail support)                     #
#       POP3 Code originally from Tclib project (modified)        #
###################################################################

#TODO:
#  * add translation


namespace eval ::gnotify {
	variable config
	variable configlist

	for {set acntn 0} {$acntn<10} {incr acntn} {
		variable emails_$acntn -1
		variable newMails_$acntn -1
		variable balloontext_$acntn ""
	}

	#######################################################################################
	#######################################################################################
	####            Initialization Procedure (Called by the Plugins System)            ####
	#######################################################################################
	#######################################################################################

	proc Init { dir } {
		::plugins::RegisterPlugin pop3
		::plugins::RegisterEvent pop3 OnConnect start
		::plugins::RegisterEvent pop3 OnDisconnect stop
		::plugins::RegisterEvent pop3 ContactListColourBarDrawn draw
		::plugins::RegisterEvent pop3 ContactListEmailsDraw addhotmail

		array set ::pop3::config {
			minute {5}
			accounts {1}
		}

		for {set acntn 0} {$acntn<10} {incr acntn} {
			array set ::pop3::config [ list \
				host_[set acntn] {"your.mailserver.here"} \
				user_[set acntn] {"user_login@here"} \
				passe_[set acntn] [::pop3::encrypt ""] \
				port_[set acntn] {110} \
				notify_[set acntn] {1} \
				loadMailProg_[set acntn] {0} \
				rightdeletemenu_[set acntn] {1} \
				mailProg_[set acntn] {msimn} \
				caption_[set acntn] {POP3} \
				leavemails_[set acntn] {0} \
			]
		}

		set ::pop3::configlist [list \
			[list str "Check for new messages every ? minutes" minute] \
			[list frame ::pop3::populateframe ""] \
		]

		::skin::setPixmap pop3_mailpic pop3_mailpic.gif pixmaps [file join $dir pixmaps]

		set ::pop3::checkingnow 0
		
		#only start checking now if already online
		if { (!$::initialize_amsn) && ([::MSN::myStatusIs] != "FLN") } {
			::pop3::start 0 0
		}
	}

	proc DeInit { } {
		::pop3::stop 0 0
	}

	proc populateframe { win } {
		#total number of accounts
		frame $win.num
		label $win.num.label -text "How many accounts do you have: "
		combobox::combobox $win.num.accounts -editable false -highlightthickness 0 -width 3 -bg #FFFFFF -font splainf -textvariable ::pop3::config(accounts)
		for { set i 1 } { $i < 11 } { incr i } {
			$win.num.accounts list insert end $i
		}
		#$win.num.accounts select 0
		pack $win.num.label -side left -anchor w
		pack $win.num.accounts -side left -anchor w
		pack $win.num -anchor w -padx 20

		#frame around selections
		#set f [frame $win.c -bd 2 -bg black]
		framec $win.c -bc #0000FF
		set f [$win.c getinnerframe]
		pack $win.c -anchor w -padx 20

		#current selection box
		frame $f.num
		label $f.num.label -text "Settings for accunt number: "
		combobox::combobox $f.num.account -editable false -highlightthickness 0 -width 3 -bg #FFFFFF -font splainf
		for { set i 1 } { $i < 11 } { incr i } {
			$f.num.account list insert end $i
		}
		$f.num.account select 0
		pack $f.num.label -side left -anchor w
		pack $f.num.account -side left -anchor w
		pack $f.num -anchor w

		#server
		frame $f.host
		label $f.host.label -text "POP3 Server"
		entry $f.host.entry -textvariable ::pop3::config(host_0) -bg white
		pack $f.host.label -side left -anchor w
		pack $f.host.entry -side left -anchor w
		pack $f.host -anchor w

		#user name
		frame $f.user
		label $f.user.label -text "Your user login"
		entry $f.user.entry -textvariable ::pop3::config(user_0) -bg white
		pack $f.user.label -side left -anchor w
		pack $f.user.entry -side left -anchor w
		pack $f.user -anchor w

		#password
		frame $f.pass
		label $f.pass.label -text "Your password"
		entry $f.pass.entry -show "*" -bg white -validate all \
		-validatecommand {
			set ::pop3::config(passe_0) [::pop3::encrypt %P]
			return 1
		}
		$f.pass.entry insert end [pop3::decrypt $::pop3::config(passe_0)]
		pack $f.pass.label -side left -anchor w
		pack $f.pass.entry -side left -anchor w
		pack $f.pass -anchor w

		#port
		frame $f.port
		label $f.port.label -text "Port (optional)"
		entry $f.port.entry -textvariable ::pop3::config(port_0) -bg white
		pack $f.port.label -side left -anchor w
		pack $f.port.entry -side left -anchor w
		pack $f.port -anchor w

		#Show notify
		checkbutton $f.notify -text "Show notify window" -variable ::pop3::config(notify_0)
		pack $f.notify -anchor w

		#load mail program
		checkbutton $f.loadMailProg -text "Load mail program on left click" -variable ::pop3::config(loadMailProg_0)
		pack $f.loadMailProg -anchor w

		#mail program
		frame $f.mailProg
		label $f.mailProg.label -text "          Mail Program"
		entry $f.mailProg.entry -textvariable ::pop3::config(mailProg_0) -bg white
		pack $f.mailProg.label -side left -anchor w
		pack $f.mailProg.entry -side left -anchor w
		pack $f.mailProg -anchor w

		#rightdeletemenu
		checkbutton $f.rightdeletemenu -text "Load delete menu on right click" -variable ::pop3::config(rightdeletemenu_0)
		pack $f.rightdeletemenu -anchor w

		#leavemails
		checkbutton $f.leavemails -text "Your mail program leaves mails on server" -variable ::pop3::config(leavemails_0)
		pack $f.leavemails -anchor w

		#caption
		frame $f.caption
		label $f.caption.label -text "Display name"
		entry $f.caption.entry -textvariable ::pop3::config(caption_0) -bg white
		pack $f.caption.label -side left -anchor w
		pack $f.caption.entry -side left -anchor w
		pack $f.caption -anchor w

		$win.num.accounts configure -command ::pop3::switchnumaccounts
		::pop3::switchnumaccounts $win.num.accounts [$win.num.accounts get]
		$f.num.account configure -command ::pop3::switchconfig
	}

	proc switchconfig { widget val } {
		incr val -1
		set f [string replace $widget end-11 end ""]

		$f.host.entry configure -textvariable ::pop3::config(host_$val)
		$f.user.entry configure -textvariable ::pop3::config(user_$val)
		$f.pass.entry configure -validate none
		$f.pass.entry configure -validatecommand "set ::pop3::config(passe_$val) \[::pop3::encrypt %P\]; return 1"
		$f.pass.entry delete 0 end
		$f.pass.entry insert end [pop3::decrypt $::pop3::config(passe_$val)]
		$f.pass.entry configure -validate all
		$f.port.entry configure -textvariable ::pop3::config(port_$val)
		$f.notify configure -variable ::pop3::config(notify_$val)
		$f.loadMailProg configure -variable ::pop3::config(loadMailProg_$val)
		$f.mailProg.entry configure -textvariable ::pop3::config(mailProg_$val)
		$f.rightdeletemenu configure -variable ::pop3::config(rightdeletemenu_$val)
		$f.leavemails configure -variable ::pop3::config(leavemails_$val)
		$f.caption.entry configure -textvariable ::pop3::config(caption_$val)
	}

	proc switchnumaccounts { widget val } {
		set acc [[string replace $widget end-12 end ""].c getinnerframe].num.account
		set oldval [$acc get]

		$acc list delete 0 end
		for { set i 1 } { $i <= $val } { incr i } {
			$acc list insert end $i
		}
		if { $oldval < $val } {
			incr oldval -1
			$acc select $oldval
		} else {
			$acc select 0
		}
	}


	
	# ::pop3::start
	# Description:
	#	Starts checking for new messages
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc start {event evPar} {
		#cancel any previous starts first
		catch { after cancel ::pop3::check }
		catch { after 5000 ::pop3::check }
	}


	# ::pop3::stop
	# Description:
	#	Stops checking for new messages
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc stop {event evPar} {
		catch { after cancel ::pop3::check }
		#If online redraw main window to remove new line
		#Doesn't work yet, as events are still triggered after unload (need to fix)
		if { (!$::initialize_amsn) && ([::MSN::myStatusIs] != "FLN") } {
			cmsn_draw_online
		}
	}


	# ::pop3::loadDefaultEmail
	# Description:
	#	Loads the default email program for the system
	# Arguments:
	#	acntn ->  The number of the account to load teh default mail program for
	proc loadDefaultEmail { acntn } {
		#check if the account is a gmail account
		if { [string match *@gmail.com* $::pop3::config(user_$acntn) ] } {
			launch_browser [string map {% %%} [list http://mail.google.com]]
		} elseif { $::tcl_platform(platform) == "windows" } {
			package require WinUtils
			eval WinLoadFile [set ::pop3::config(mailProg_$acntn)]
		} elseif { [catch {eval "exec [set ::pop3::config(mailProg_$acntn)]"} res] } {
				plugins_log pop3 "Failed to load [set ::pop3::config(mailProg_$acntn)] with the error: $res\n"
		}

		if { [set ::pop3::config(leavemails_$acntn)] == 1 } {
			#reset number of new mails
			set ::pop3::newMails_$acntn 0
			cmsn_draw_online
		}
	}


	# ::pop3::draw
	# Description:
	#	Adds a line in the contact list of the number of emails drawn for each account
	# Arguments:
	#	acntn   -> The number of the account to notify for
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc draw_no {acntn evPar} {
		upvar 3 $evPar vars

		#TODO: add parameter to event and get rid of hardcoded variable
		set pgtop $::pgBuddyTop
		set clbar $::pgBuddyTop.colorbar
		
		set textb $pgtop.pop3mail_$acntn
		text $textb -font bboldf -height 1 -background [::skin::getKey topcontactlistbg] -borderwidth 0 -wrap none -cursor left_ptr \
			-relief flat -highlightthickness 0 -selectbackground white -selectborderwidth 0 \
			-exportselection 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0
		if {[::skin::getKey emailabovecolorbar]} {
			pack $textb -expand true -fill x -after $clbar -side bottom -padx 0 -pady 0
		} else {
			pack $textb -expand true -fill x -before $clbar -side bottom -padx 0 -pady 0
		}

		$textb configure -state normal

		clickableImage $textb popmailpic_$acntn pop3_mailpic {after cancel ::pop3::check; after 1 ::pop3::check} [::skin::getKey mailbox_xpad] [::skin::getKey mailbox_ypad]
		
		set mailheight [expr [image height [::skin::loadPixmap pop3_mailpic]]+(2*[::skin::getKey mailbox_ypad])]
		#in windows need an extra -2 is to include the extra 1 pixel above and below in a font
		if {$::tcl_platform(platform) == "windows"} {
			set mailheight [expr $mailheight - 2]
		}
		set textheight [font metrics splainf -linespace]
		if { $mailheight < $textheight } {
			set mailheight $textheight
		}
		$textb configure -font "{} -$mailheight"

		set balloon_message "Click here to check the number of messages now."
		$textb tag bind $textb.popmailpic_$acntn <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		$textb tag bind $textb.popmailpic_$acntn <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		$textb tag bind $textb.popmailpic_$acntn <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		set newm [set ::pop3::newMails_$acntn]
		if { $newm < 0 } {
			set mailmsg "Not Checked Yet ([set ::pop3::config(caption_$acntn)])"
		} elseif { $newm == 0 } {
			set mailmsg "[trans nonewmail] ([set ::pop3::config(caption_$acntn)])"
		} elseif { $newm == 1} {
			set mailmsg "[trans onenewmail] ([set ::pop3::config(caption_$acntn)])"
		} elseif { $newm == 2} {
			set mailmsg "[trans twonewmail 2] ([set ::pop3::config(caption_$acntn)])"
		} else {
			set mailmsg "[trans newmail [set ::pop3::newMails_$acntn]] ([set ::pop3::config(caption_$acntn)])"
		}
		
		set maxw [expr [winfo width [winfo parent $pgtop]]-[image width [::skin::loadPixmap pop3_mailpic]]-(2*[::skin::getKey mailbox_xpad])]
		set short_mailmsg [trunc $mailmsg $textb $maxw splainf]

		$textb tag conf pop3mail_$acntn -fore black -underline false -font splainf
		if { [set ::pop3::config(loadMailProg_$acntn)] || [set ::pop3::config(rightdeletemenu_$acntn)] } {
			$textb tag conf pop3mail_$acntn -underline true
			$textb tag bind pop3mail_$acntn <Enter> "$textb tag conf pop3mail_$acntn -under false;$textb conf -cursor hand2"
			$textb tag bind pop3mail_$acntn <Leave> "$textb tag conf pop3mail_$acntn -under true;$textb conf -cursor left_ptr"
		}
		if { [set ::pop3::config(loadMailProg_$acntn)] } {
			$textb tag bind pop3mail_$acntn <Button1-ButtonRelease> "$textb conf -cursor watch; after 1 [list ::pop3::loadDefaultEmail $acntn]"
		}
		if { [set ::pop3::config(rightdeletemenu_$acntn)] } {
			$textb tag bind pop3mail_$acntn <Button3-ButtonRelease> "after 1 [list ::pop3::rightclick %X %Y $acntn]"
		}
		set balloon_message "$mailmsg[set ::pop3::balloontext_$acntn]"
		$textb tag bind pop3mail_$acntn <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		$textb tag bind pop3mail_$acntn <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		$textb tag bind pop3mail_$acntn <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		$textb insert end "$short_mailmsg" [list pop3mail_$acntn dont_replace_smileys]
		
		$textb configure -state disabled
	}


	# ::pop3::draw
	# Description:
	#	Adds a line in the contact list of the number of emails drawn for each account
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc draw {event evPar} {
		for {set acntn 0} {$acntn<$::pop3::config(accounts)} {incr acntn} {
			::pop3::draw_no $acntn $evPar
		}
	}
	
	
	# ::pop3::addhotmail
	# Description:
	#	Adds ' (Hotmail)' to the line in the contact list of the number of emails
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#	evPar   -> The array of parameters (Supplied by Plugins System)
	proc addhotmail {event evPar} {
		upvar 2 $evPar vars
		upvar 2 $vars(msg) msg
		set msg "[string range $msg 0 end] (Hotmail)"
	}


	# ::pop3::rightclick
	# Description:
	#	Creates a right click menu to delete an email
	# Arguments:
	#	x  -> x position where to display
	#	y  -> y position where to display
	#	acntn   -> The number of the account to create for
	proc rightclick { X Y acntn} {
		set rmenu .pop3rightmenu
		destroy $rmenu

		menu $rmenu -tearoff 0 -type normal

		$rmenu add command -label "Select an email to delete"
		$rmenu add command -label "Check for new email" -command ::pop3::check
		$rmenu add separator

		set i 0
		foreach line [split [string range [set ::pop3::balloontext_$acntn] 17 end] \n] { 
			incr i
			$rmenu add command -label "$line" -command [list ::pop3::deletemail $acntn $i $line]
		}

		tk_popup $rmenu $X $Y
	}


	proc check_gmail { username password } {
		variable user_cookies
		#TODO should depend on $username,$password

		if { [info exists user_cookies($username,gv)] && [info exists user_cookies($username,sid)]} {
			if { [info exists user_cookies($username,s)] } {
				set cookie [join [list [set user_cookies($username,gv)] [set user_cookies($username,sid)] [set user_cookies($username,s)]] "; "]				
			} else {
				set cookie [join [list [set user_cookies($username,gv)] [set user_cookies($username,sid)]] "; "]
			}
			set headers [list Cookie "$cookie"]
			http::geturl "http://mail.google.com/mail/?ui=html" -headers $headers -command [list ::gnotify::check_gmail_callback $username]
		} else {
			authenticate_gmail $username $password [list ::gnotify::check_gmail $username $password]
			return 
		}
	}

	proc check_gmail_callback { username token } {
		variable user_cookies
		upvar #0 $token state
		set meta $state(meta)
		if { [::http::ncode $token] == 200 } {
			foreach {key val} $meta {
				if { $key == "Set-Cookie"} {
					foreach cookie [split $val ";"] {
						if {[lindex [split $cookie "="] 0] == "S" } {
							set user_cookies($username,s) $cookie	
						} 
					}
				}
			}
			set info_l [parseGData [::http::data $token]]
			array set info $info_l
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
						puts "$author(nick) <$author(email)>"						
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
					} 
					puts "$mail(subject) || $mail(body)"
					if {[llength $mail(attachments)] > 0 } {
						puts -nonewline "Attachments : "
						foreach att $mail(attachments) {
							puts "$att "
						}
					}
					if {[llength $mail(tags)] > 0 } {
						puts -nonewline "tags : "
						foreach tag $mail(tags) {
							puts -nonewline "$tag, "
						}
					}
					puts ""
				}
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
			puts "authentication successfull : $token"
			foreach {key val} $meta {
				if { $key == "Set-Cookie" ||  $key == "X-Set-Google-Cookie" } {
					foreach cookie [split $val ";"] {
						set k [lindex [split $cookie "="] 0]
						if {$k == "SID" } {
							set user_cookies($username,sid) $cookie
						} elseif { $k == "GV" } {
							set user_cookies($username,gv) $cookie				
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

