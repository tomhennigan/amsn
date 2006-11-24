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


	# ::pop3::Check_gmail
	# Description:
	#	catch the "Unreads" information about the gmail account by acting as a browser, with cookies support, but no javascript.
	#(i wrote a proc which "enables" javascript, which gives us the beginning of new messages, the email of the authors,
	#but there is more http::geturl procedures, and the "regexp" part is very complex.
	#	create the balloon (this is not working for the moment)
	# Arguments:
	#	acntn        -> The number of the gmail account to check
	#TODO : add the balloon support.
	#TODO : remove some regexp ?
	#
	# i would like to thanks the Live http Headers project (http://livehttpheaders.mozdev.org/), it's a really good extension to firefox to see all headers while browsing.
	# 
	proc Check_gmail {acntn} {
		plugins_log "pop3" "checking for gmail account : $::pop3::config(user_$acntn)"
		package require http
		package require tls
		#bind the https in order to use tls
		http::register https 443 ::tls::socket
			
		#this the array where i put all the variables (i should change that)
		set unreads 0
		
		#remove the quotes around the login if they exists
		if {[string equal [string index $::pop3::config(user_$acntn) 0] "\"" ] && [string equal [string index $::pop3::config(user_$acntn) end] "\""]} {
			set ::pop3::config(user_$acntn) [string range $::pop3::config(user_$acntn) 1 end-1]
		}
		
		#here we go to the page created for mobiles :)
		set headers [list "Host" "gmail.com" ]
		set url "http://m.gmail.com/"
		set token [http::geturl $url -headers $headers -validate 0 ]
		set data [array get $token]
		http::cleanup $token
		#plugins_log "pop3" "data1:=$data"
		regexp {Location\ ([\/\$\*\~\%\,\!\'\#\.\@\+\-\=\?\;\:\^\&\_[:alnum:]]+)\ } $data -> url
		#plugins_log "pop3" "(GMAIL)Location1:=$url"
		
		#we're redirected	
		set headers [list "Host" "mail.google.com"]
		set token [http::geturl $url -headers $headers -validate 0 ]
		set data [array get $token]
		#plugins_log "pop3" "data2:=$data"
		set purl $url
		regexp {Location\ ([\/\$\*\~\%\,\!\'\#\.\@\+\-\=\?\;\:\^\&\_[:alnum:]]+)\ } $data -> url
		http::cleanup $token
		#plugins_log "pop3" "(GMAIL)Location2:=$url"

		
		#and again
		set headers [list "Host" "mail.google.com"]
		set token [http::geturl $url -headers $headers -validate 0 ]
		set data [array get $token]
		#plugins_log "pop3" "data3:=$data"
		set purl $url
		
		#making the query
		set query ""
		set body [::http::data $token]
		http::cleanup $token
		set pos2 1
		set name ""
		set value ""
		set type ""
		for {set i 1} {$i<=[regexp -all {input } $body]} {incr i} {
			set pos1 [expr {[string first "<input" $body $pos2] + 6}]
			set pos2 [expr {[string first ">" $body $pos1] -1}]
			set input [string range $body $pos1 $pos2]
			#plugins_log "pop3" "input:=$input"
			regexp {type=\"(\w+)\"} $input -> type
			#plugins_log "pop3" "type:=$type"
			switch $type {
				hidden {
					regexp {name=\"(\w+)\"} $input -> name
					regexp {value=\"([\/\$\*\~\%\,\!\'\#\.\@\+\-\=\?\;\:\^\&\_[:alnum:]]+)\"} $input -> value
					if {$query != ""} {
						append query "&"
					}
					append query $name = [urlencode $value]
				}
				text {
					#here, we fill the login
					regexp {name=\"(\w+)\"} $input -> name
					if {$query != ""} {
						append query "&"
					}
					append query $name = [urlencode $::pop3::config(user_$acntn)]
				}
				password {
					#here, we fill the password :)
					regexp {name=\"(\w+)\"} $input -> name
					if {$query != ""} {
						append query "&"
					}
					append query $name = [urlencode [pop3::decrypt $::pop3::config(passe_$acntn)]]
				}
				checkbox {
					regexp {name=\"(\w+)\"} $input -> name
					regexp {value=\"(\w+)\"} $input -> value
					if {$query != ""} {
						append query "&"
					}
					append query $name = $value
				}
				submit {}
				default {}
			}
		}
		#plugins_log "pop3" "(GMAIL)query:=$query"
		#plugins_log "pop3" "(GMAIL)purl:=$purl"
		

		#sending login + pass
		set headers [list "Host" "www.google.com" "Referer" "$purl"]
		#TODO : don't harcode $url
		set url https://www.google.com/accounts/ServiceLoginAuth
		set token [http::geturl $url -query $query -headers $headers -validate 0 ]
		set data [array get $token]
		#plugins_log "pop3" "data4:=$data"
		regexp {Location\ ([\/\$\*\~\%\,\!\'\#\.\@\+\-\=\?\;\:\^\&\_[:alnum:]]+)\ Content-Type} $data -> url
		#plugins_log "pop3" "(GMAIL)Location3:=$url"

		#redirected to a page where it checks the cookies
		upvar \#0 $token state
		#gets the invitations to create a cookie by parsing $state
		array set cookies {}
		foreach {name value} $state(meta) {
			if { $name eq "Set-Cookie" } {
				regexp {(\w+)=([\/\$\*\~\%\,\!\'\#\.\@\+\-\=\?\:\^\_[:alnum:]]+)\;} $value -> name value
				set cookies($name) $value
			}
		}
		http::cleanup $token
		set cookies_header [list LSID=$cookies(LSID) SID=$cookies(SID) ]
		set headers [list "Host" "www.google.com" "Referer" "$purl" "Cookie" [join $cookies_header {;}]]
		set token [http::geturl $url -query $query -headers $headers -validate 0 ]
		set data [array get $token]
		http::cleanup $token
		#plugins_log "pop3" "data5:=$data"
		
		#getting the next url
		set pos1 [expr [string first "<meta content=\"0\;" $data] + 22]
		set pos2 [expr [string first "\" http-equiv=\"refresh\"" $data $pos1] -1]
		set url [string range $data $pos1 $pos2]
		set url [string map { &amp; & &quot; "" } $url]
		set url [string map { &amp; & &quot; "" } $url]
		if {[string equal [string index $url 0] "'" ] && [string equal [string index $url end] "'"]} {
			set url [string range $url 1 end-1]
		}
#plugins_log "pop3" "(GMAIL)url6:=$url"
		
		#that will be the latest page
		set cookies_header [list SID=$cookies(SID) ]
#plugins_log "pop3" "(GMAIL)[array names cookies]"
		set headers [list "Host" "mail.google.com" "Cookie" [join $cookies_header {;}]]
		set token [http::geturl $url -headers $headers -validate 0 ]
		set data [array get $token]
#plugins_log "pop3" "data6:=$data"
		set body [::http::data $token]
		http::cleanup $token

		#find the amount of unread messages
		regexp {Inbox&nbsp;\((\d+)\)} $body -> unreads

		plugins_log pop3 "POP3 ($acntn) messages: $unreads\n"
		set dontnotifythis 1
		if { [set ::pop3::emails_$acntn] != $unreads } {
			set dontnotifythis 0
			set ::pop3::newMails_$acntn $unreads
			set ::pop3::emails_$acntn $unreads
		}

		if { $dontnotifythis == 0 } {
			cmsn_draw_online
			::pop3::notify $acntn
		}
		array unset gmail
	}

	proc check_gmail { username password } {
		variable user_cookies
		
		if { [info exists user_cookies($username,gv)] && [info exists user_cookies($username,sid)]} {
			if { [info exists user_cookies($username,s)] } {
				set cookie [join [list [set user_cookies($username,gv)] [set user_cookies($username,sid)] [set user_cookies($username,s)]] "; "]				
			} else {
				set cookie [join [list [set user_cookies($username,gv)] [set user_cookies($username,sid)]] "; "]
			}
			set headers [list Cookie "$cookie"]
			http::geturl "http://mail.google.com/mail/?ui=pb" -headers $headers -command [list ::gnotify::check_gmail_callback $username]
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

			parseGData [::http::data $token]
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


	proc parseGData { data } {
		set len [string length $data]

		binary scan $data H* hex
		set state key
		set new_mail 0
		for { set i 0 } { $i < $len } { incr i } {
			set byte "0x[string range $hex [expr {$i * 2}] [expr {$i * 2} + 1]]"
			#puts "parsing byte $byte - $state"
			switch $state {
				key {
					switch $byte {
						0x0a {
							set state size_mail
							incr new_mail
						} 
						0x88 {
							set state size_new
						}
						default { 
							puts "new unknown key :  [string range $hex [expr {$i * 2}] end]"
						}
					}
				}
				size_mail {
					set size_mail [expr $byte]
					set size_mail [expr {$size_mail & ~0x80}]
					if { [expr {$byte & 0x80}] != 0 } {
						set state size_mail2
					} else {
						set mail_read 0
						set state read_mail
					}
				}
				size_mail2 {
					set size_mail [expr {$size_mail + (0x80 * $byte)} ]
					set mail_read 0
					set state read_mail
				}
				read_mail {
					incr mail_read
					if { $mail_read == $size_mail } {
						set state key
					}
				}
				size_new {
					set size_mail [expr $byte]
					set new_read 0
					set state read_new
				}
				read_new {
					puts "New mails : [expr $byte] - $new_mail"
				}

				
			}
		}
	}
}
