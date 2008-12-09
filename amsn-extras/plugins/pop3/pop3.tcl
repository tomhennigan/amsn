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


namespace eval ::pop3 {
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
				host_[set acntn] {your.mailserver.here} \
				user_[set acntn] {user_login@here} \
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


	#######################################################################################
	#######################################################################################
	####                 AUXILIAR FUNCTIONS NEEDED BY THE POP3 CLIENT                  ####
	#######################################################################################
	#######################################################################################

	proc ::pop3::getopt {argvVar optstring optVar valVar} {
		upvar 1 $argvVar argsList
		upvar 1 $optVar option
		upvar 1 $valVar value

		set result [getKnownOpt argsList $optstring option value]

		if {$result < 0} {
			# Collapse unknown-option error into any-other-error result.
			set result -1
		}
		return $result
	}

	proc ::pop3::getKnownOpt {argvVar optstring optVar valVar} {
		upvar 1 $argvVar argsList
		upvar 1 $optVar  option
		upvar 1 $valVar  value

		# default settings for a normal return
		set value ""
		set option ""
		set result 0

		# check if we're past the end of the args list
		if {[llength $argsList] != 0} {
			# if we got -- or an option that doesn't begin with -, return (skipping
			# the --).  otherwise process the option arg.
			switch -glob -- [set arg [lindex $argsList 0]] {
			"--" {
				set argsList [lrange $argsList 1 end]
			}

			"-*" {
				set option [string range $arg 1 end]
				if {[lsearch -exact $optstring $option] != -1} {
					# Booleans are set to 1 when present
					set value 1
					set result 1
					set argsList [lrange $argsList 1 end]
				} elseif {[lsearch -exact $optstring "$option.arg"] != -1} {
					set result 1
					set argsList [lrange $argsList 1 end]
					if {[llength $argsList] != 0} {
						set value [lindex $argsList 0]
						set argsList [lrange $argsList 1 end]
					} else {
						set value "Option \"$option\" requires an argument"
						set result -2
					}
				} else {
					# Unknown option.
					set value "Illegal option \"$option\""
					set result -1
				}
			}

			default {
				# Skip ahead
			}
			}
		}
		return $result
	}
	
	proc ::pop3::encrypt { password } {
		if {[info proc "::DES::des"] == "::DES::des"} {
			binary scan [::DES::des -mode ecb -dir encrypt -key pasencky "${password}\n"] h* encpass
		} else {
			binary scan [::des::encrypt pasencky "${password}\n"] h* encpass
		}
		return $encpass
	}

	proc ::pop3::decrypt { key } {
		if {[info proc "::DES::des"] == "::DES::des"} {
			set password [::DES::des -mode ecb -dir decrypt -key pasencky [binary format h* $key]]
		} else {
			set password [::des::decrypt pasencky [binary format h* $key]]
		}
		set password [string range $password 0 [expr { [string first "\n" $password] -1 }]]
		return $password
	}


	#######################################################################################
	#######################################################################################
	####                     CORE FUNCTIONS OF THE POP3 PLUGIN                         ####
	#######################################################################################
	#######################################################################################

	# ::pop3::close
	# Description:
	#	Close the connection to the POP3 server.
	# Arguments:
	#	chan -> The channel, returned by ::pop3::open
	# Results:
	#	None
	proc ::pop3::close {chan} {
		catch {
			::pop3::send $chan "QUIT"
		}

		::close $chan
		unset ::pop3::chanopen_$chan
	}

	# pop3::open
	# Description
	#	Opens a connection to a POP3 mail server.
	# Arguments:
	#	args ->  A list of options and values, possibly empty,
	#	           followed by the regular arguments, i.e. host, user,
	#	           passwd and port. The latter is optional.
	#
	#	host   -> The name or IP address of the POP3 server host.
	#	user   -> The username to use when logging into the server.
	#	passwd -> The password to use when logging into the server.
	#	port   -> (optional) The socket port to connect to, defaults
	#	            to port 110, the POP standard port address.
	# Results:
	#	Returns connection channel (a socket).
	#	If the channel is ready (open) it sets ::pop3::chanopen_$chan to 1
	#	If the there was a problem opening then it sets ::pop3::chanopen_$chan to -1
	#	May throw errors from the server.
	proc ::pop3::open {args} {
		array set cstate {msex 0 retr_mode retr limit {}}

		while {[set err [getopt args {msex.arg retr-mode.arg} opt arg]]} {
			if {$err < 0} {
				return -code error "::pop3::open : $arg"
			}
			switch -exact -- $opt {
				msex {
					if {![string is boolean $arg]} {
						return -code error \
						":pop3::open : Argument to -msex has to be boolean"
					}
					set cstate(msex) $arg
				}
				
				retr-mode {
					switch -exact -- $arg {
						retr - list - slow {
							set cstate(retr_mode) $arg
						}
						default {
							return -code error \
							":pop3::open : Argument to -retr-mode has to be one of retr, list or slow"
						}
					}
				}
				default {
					# Can't happen
				}
			}
		}
	
		if {[llength $args] > 4} {
			return "Too many arguments to ::pop3::open"
		}
		if {[llength $args] < 3} {
			return "Not enough arguments to ::pop3::open"
		}
		foreach {host user password port} $args break
		if {$port == {}} {
			set port 110
		}
	
		# Argument processing is finally complete, now open the channel
	
		set chan [socket -async $host $port]
		fconfigure $chan -buffering none
	
		if {$cstate(msex)} {
			# We are talking to MS Exchange. Work around its quirks.
			fconfigure $chan -translation binary
		} else {
			fconfigure $chan -translation {binary crlf}
		}

		fconfigure $chan -blocking 0
		set ::pop3::chanopen_$chan 0

		#give it a chance to open then call rest
		fileevent $chan writable [list ::pop3::Open2 $chan $user $password]
		
		#wait till chan is open before returning
		vwait ::pop3::chanopen_$chan

		return $chan
	}
	#continuation of open when the channel is ready
	proc ::pop3::Open2 {chan user password} {
		fileevent $chan writable ""

		if {[catch {
			#test for end of file
			if { [eof $chan] } {
				plugins_log pop3 "ERROR : EOF reached in open(2)\n"
				error "EOF in ::pop3::Open2"
			}
			
			::pop3::send $chan {} 1
			::pop3::send $chan "user $user" 1
			::pop3::send $chan "pass $password" 1
		} errorStr]} {
			::close $chan
			set ::pop3::chanopen_$chan -1
			return
		}

		set ::pop3::chanopen_$chan 1
	}


	# ::pop3::send
	# Description:
	#	Send a command string to the POP3 server.  This is an
	#	internal function, but may be used in rare cases.
	# Arguments:
	#	chan      -> The channel open to the POP3 server.
	#	cmdstring -> POP3 command string
	#	override  -> skip the not open check
	# Results:
	#	Result string from the POP3 server, except for the +OK tag.
	#	Errors from the POP3 server are thrown.
	proc ::pop3::send {chan cmdstring {override 0}} {
		global PopErrorNm PopErrorStr debug

		if { ($override == 0) && ([set ::pop3::chanopen_$chan] != 1) } {
			plugins_log pop3 "ERROR : Data sent when channel not open\n"
			error "ERROR : Data sent when channel not open"
		}

		if {$cmdstring != {}} {
			puts $chan $cmdstring
		}

		set ::pop3::chanreturn_$chan "somethingtodelete"
		fileevent $chan readable [list ::pop3::send2 $chan]
		vwait ::pop3::chanreturn_$chan

		set popRet [set ::pop3::chanreturn_$chan]
		unset ::pop3::chanreturn_$chan
		if { $popRet == "ERROR" } { error }

		return $popRet
	}
	# continuation of send when data return is received
	proc ::pop3::send2 {chan} {
		if {[catch {
			set popRet ""

			#test for end of file
			if { [eof $chan] } {
				set popRet "xxx EOF reached in send(2)"
				error
			}

			#get result
			set popRet [string trim [gets $chan]]

			#check for non completed read, already tested for eof above
			if { $popRet == "" } {
				if { [fblocked $chan] == 1 } {
					#still more data
					error "continue!"
				} else {
					#read an empty line need to call gets again to continue
					::pop3::send2 $chan
					error "continue!"
				}
			}

			#read complete so remove filevent
			fileevent $chan readable ""

			#check the result was +OK
			if {[string first "+OK" $popRet] == -1} {
				error
			}
	
			#return result
			set ::pop3::chanreturn_$chan [string range $popRet 3 end]
		} errorStr]} {
			if { $errorStr == "continue!" } { 
				#need some way to return without an error?
				return
			}

			fileevent $chan readable ""
			plugins_log pop3 "ERROR : [string range $popRet 4 end]\n"
			set ::pop3::chanreturn_$chan "ERROR"
			return
		}
	}


	# ::pop3::from
	# Description:
	#	Get the name of the person that the email is from.
	# Arguments:
	#	chan ->  The channel, returned by ::pop3::open
	#	id   ->  The id number of the message
	# Results:
	#	An array with information in it:
	#	1st element : The name in the "From:" section.
	#	2nd element : The subject.
	proc ::pop3::getinfo {chan id} {
		set from "unknown"
		set subject ""

		if {[catch {
			set data [::pop3::send $chan "TOP $id 0"]
		} errorStr]} {
			#error, most likely incorrect id number
			set from -1
			set subject -1
		} else {
			set ::pop3::chanreturn_from_$chan "unknown"
			set ::pop3::chanreturn_subject_$chan ""
			set ::pop3::chanreturn_complete_$chan "somethingtodelete"
			fileevent $chan readable [list ::pop3::getinfo2 $chan]
			vwait ::pop3::chanreturn_complete_$chan

			set from [set ::pop3::chanreturn_from_$chan]
			unset ::pop3::chanreturn_from_$chan
			set subject [set ::pop3::chanreturn_subject_$chan]
			unset ::pop3::chanreturn_subject_$chan
			set popRet [set ::pop3::chanreturn_complete_$chan]
			unset ::pop3::chanreturn_complete_$chan
			if { $popRet == "ERROR" } { error }
		}

		return [list $from $subject]
	}
	# continuation of send when data return is received
	proc ::pop3::getinfo2 {chan} {
		#turn off event while processing to stop infinite loop
		fileevent $chan readable ""

		if {[catch {
			#test for end of file
			if { [eof $chan] } {
				error "EOF reached in getinfo(2)"
			}

			#get the next line line
			set line [string trimright [gets $chan] \r]

			#check for non completed read, already tested for eof above
			if { $line == "" } {
				if { [fblocked $chan] == 1 } {
					#still more data
					fileevent $chan readable [list ::pop3::getinfo2 $chan]
					error "continue!"
				} else {
					#read an empty line need to call gets again to continue
					::pop3::getinfo2 $chan
					error "continue!"
				}
			}

			# End of the message is a line with just "."
			if {$line == "."} {
				#fileevent $chan readable ""
				set ::pop3::chanreturn_complete_$chan "COMPLETE"
				error "continue!"
			} elseif {[string index $line 0] == "."} {
				set line [string range $line 1 end]
			}

			if {[string equal -nocase -length 5 $line "From: "]} {
				set ::pop3::chanreturn_from_$chan [::pop3mime::field_decode [string range $line 6 end]]
			} elseif {[string equal -nocase -length 8 $line "Subject: "]} {
				set ::pop3::chanreturn_subject_$chan  [::pop3mime::field_decode [string range $line 9 end]]
			}

			#still more data
			fileevent $chan readable [list ::pop3::getinfo2 $chan]
		} errorStr]} {
			if { $errorStr == "continue!" } { 
				#need some way to return without an error?
				return
			}

			fileevent $chan readable ""
			plugins_log pop3 "ERROR (in getinfo2): $errorStr\n"
			set ::pop3::chanreturn_complete_$chan "ERROR"
			return
		}
	}


	# ::pop3::getfroms
	# Description:
	#	Create a list of froms for the balloon message.
	# Arguments:
	#	chan   ->  The channel, returned by ::pop3::open
	#	first  ->  The id of the first email to check
	#	last   ->  The id of the last email to check
	# Results:
	#	A message for the balloon containing the names of who the mails are from is returned
	proc ::pop3::getfroms {chan first last} {
		set balloontext ""
		if {$first <= $last} {
			set balloontext "\n\nNew mail from:"
			for {set x $first} {$x <= $last} {incr x} {
				set info [::pop3::getinfo $chan $x]
				if { $info != "-1 -1" } {
					set from [lindex $info 0]
					set subject [lindex $info 1] 
					set balloontext "$balloontext\n$from : \"$subject\""
				}
			}
		}
		return $balloontext
	}


	# ::pop3::status
	# Description:
	#	Get the status of the mail spool on the POP3 server.
	# Arguments:
	#	chan ->  The channel, returned by ::pop3::open
	# Results:
	#	A list containing two elements, {msgCount octetSize},
	#	where msgCount is the number of messages in the spool
	#	and octetSize is the size (in octets, or 8 bytes) of
	#	the entire spool.
	proc ::pop3::status {chan} {
		set data [::pop3::send $chan "STAT"]
		return [lindex [split [string range $data 1 end] ] 0]
	}


	# ::pop3::notify
	# Description:
	#	Posts a notification of new emails.
	# Arguments:
	#	acntn ->  The number of the account to notify for
	# Results:
	#	A notify window pops up when required.
	proc ::pop3::notify { acntn } {
		if { $::pop3::config(notify_$acntn) == 1 && [set ::pop3::newMails_$acntn] != 0 } {
			switch [set ::pop3::newMails_$acntn] {
				1  { set mailmsg "[trans onenewmail]" }
				2  { set mailmsg "[trans twonewmail 2]"	}
				default { set mailmsg "[trans newmail [set ::pop3::newMails_$acntn]]" }
			}
			if { [set ::pop3::config(loadMailProg_$acntn)] } {
				::amsn::notifyAdd "[set ::pop3::config(caption_$acntn)]\n$mailmsg" "::pop3::loadDefaultEmail $acntn" newemail plugins
			} else {
				::amsn::notifyAdd "[set ::pop3::config(caption_$acntn)]\n$mailmsg" "" newemail plugins
			}
			
			#If Growl plugin is loaded, show the notification, Mac OS X only
			if { [info commands ::growl::InitPlugin] != "" } {
				catch {growl post Pop POP3 $mailmsg}
			}
		}
	}


	# ::pop3::check_no
	# Description:
	#	Use the above methods to get the number of mails
	# Arguments:
	#	acntn ->  The number of the account to check for
	# Results:
	#	An integer variable wich contains the number of mails in the mbox
	proc ::pop3::check_no { acntn } {
		catch {
			plugins_log pop3 "Checking messages now for account $acntn\n"
			#check if the account is a gmail account
			if { [string match *@gmail.com* $::pop3::config(user_$acntn) ] } {
				::pop3::Check_gmail $acntn
			} else {
				set chan [::pop3::open [set ::pop3::config(host_$acntn)] [set ::pop3::config(user_$acntn)] [pop3::decrypt $::pop3::config(passe_$acntn)] [set ::pop3::config(port_$acntn)]]
				#check that it opened properly
				if { [set ::pop3::chanopen_$chan] == 1 } {
					set mails [::pop3::status $chan]

					plugins_log pop3 "POP3 ($acntn) messages: $mails\n"
					set dontnotifythis 1
					if { [set ::pop3::emails_$acntn] != $mails } {
						set dontnotifythis 0
						if { [set ::pop3::config(leavemails_$acntn)] == 1 } {
							if { [set ::pop3::emails_$acntn] < $mails } {
								set ::pop3::newMails_$acntn [expr { [set pop3::newMails_$acntn] + $mails - [set ::pop3::emails_$acntn] } ]
							} else {
								set dontnotifythis 1
							}
						} else {
							set ::pop3::newMails_$acntn $mails
						}
						set ::pop3::emails_$acntn $mails

						set ::pop3::balloontext_$acntn [::pop3::getfroms $chan [expr {$mails-[set ::pop3::newMails_$acntn]+1}] $mails]
					}
					::pop3::close $chan

					if { $dontnotifythis == 0 } {
						cmsn_draw_online
						::pop3::notify $acntn
					}
				} else {
					plugins_log pop3 "POP3 failed to open\n"
					unset ::pop3::chanopen_$chan
				}
			}
		}
	}


	# ::pop3::check
	# Description:
	#	Continuously check the number of emails for each of the accounts
	# Arguments: None
	# Results:
	#	An integer variable wich contains the number of mails in the mbox
	proc ::pop3::check { } {
		catch {
			# Make sure there isn't duplicat calls
			after cancel ::pop3::check
			
			set ::pop3::checkingnow 1
			
			for {set acntn 0} {$acntn<$::pop3::config(accounts)} {incr acntn} {
				::pop3::check_no $acntn
			}

			# Call itself again after x minutes
			set time [expr {int($::pop3::config(minute) *60000)}]
			after $time ::pop3::check

			set ::pop3::checkingnow 0
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
		$textb tag bind pop3mail_$acntn <Button3-ButtonRelease> "after 1 [list ::pop3::rightclick %X %Y $acntn]"
		
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

		if { [set ::pop3::config(rightdeletemenu_$acntn)] } {
			$rmenu add command -label "Select an email to delete"
		}
		$rmenu add command -label "Check for new email" -command ::pop3::check
		$rmenu add separator

		if { [set ::pop3::config(rightdeletemenu_$acntn)] } {
			set i 0
			foreach line [split [string range [set ::pop3::balloontext_$acntn] 17 end] \n] { 
				incr i
				$rmenu add command -label "$line" -command [list ::pop3::deletemail $acntn $i $line]
			}
		}

		tk_popup $rmenu $X $Y
	}


	# ::pop3::deletemail
	# Description:
	#	Deletes email at index i, but checking that the name/subject match first
	# Arguments:
	#	acntn        -> The number of the account to delete for
	#	index        -> index of the email to delete
	#	namesubject  -> the name/subject as displayed in the balloon
	proc deletemail { acntn index namesubject } {
		set answer [::amsn::messageBox "Are you sure you want to delete the email:\n$namesubject" yesno question "Delete"]
		if { $answer == "yes" } {
			#dont run check during delete
			if { $::pop3::checkingnow == 1} {
				vwait ::pop3::checkingnow
			}
			after cancel ::pop3::check
			set failed 0

			set chan [::pop3::open [set ::pop3::config(host_$acntn)] [set ::pop3::config(user_$acntn)] [pop3::decrypt $::pop3::config(passe_$acntn)] [set ::pop3::config(port_$acntn)]]

			#check that it opened properly
			if { [set ::pop3::chanopen_$chan] == 1 } {
				set info [::pop3::getinfo $chan $index]
				set from [lindex $info 0]
				set subject [lindex $info 1] 
				set info "$from : \"$subject\""

				if { $info == $namesubject } {
					if {[catch {
						set data [::pop3::send $chan "DELE $index"]
					} errorStr]} {
						set failed 1
					}
				} else {
					set failed 1
				}

				::pop3::close $chan
			} else {
				msg_box "Failed to open a connection, please try again later"
			}

			after 1 ::pop3::check

			if { $failed == 1 } {
				msg_box "Delete failed\nYour email may have changed since last update\nUpdating now."
			}
		}
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
		set pos1 [expr [string first "<meta content=\"0\;" $data)] + 22]
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
}


	#######################################################################################
	#######################################################################################
	####                MIME DECODING FUNCTIONS OF THE POP3 PLUGIN                     ####
	#######################################################################################
	#######################################################################################

namespace eval ::pop3mime {

	set encList [list \
		ascii US-ASCII \
		big5 Big5 \
		cp1250 "" \
		cp1251 "" \
		cp1252 "" \
		cp1253 "" \
		cp1254 "" \
		cp1255 "" \
		cp1256 "" \
		cp1257 "" \
		cp1258 "" \
		cp437 "" \
		cp737 "" \
		cp775 "" \
		cp850 "" \
		cp852 "" \
		cp855 "" \
		cp857 "" \
		cp860 "" \
		cp861 "" \
		cp862 "" \
		cp863 "" \
		cp864 "" \
		cp865 "" \
		cp866 "" \
		cp869 "" \
		cp874 "" \
		cp932 "" \
		cp936 "" \
		cp949 "" \
		cp950 "" \
		dingbats "" \
		euc-cn EUC-CN \
		euc-jp EUC-JP \
		euc-kr EUC-KR \
		gb12345 GB12345 \
		gb1988 GB1988 \
		gb2312 GB2312 \
		iso2022 ISO-2022 \
		iso2022-jp ISO-2022-JP \
		iso2022-kr ISO-2022-KR \
		iso8859-1 ISO-8859-1 \
		iso8859-2 ISO-8859-2 \
		iso8859-3 ISO-8859-3 \
		iso8859-4 ISO-8859-4 \
		iso8859-5 ISO-8859-5 \
		iso8859-6 ISO-8859-6 \
		iso8859-7 ISO-8859-7 \
		iso8859-8 ISO-8859-8 \
		iso8859-9 ISO-8859-9 \
		jis0201  "" \
		jis0208 "" \
		jis0212 "" \
		koi8-r KOI8-R \
		ksc5601 "" \
		macCentEuro "" \
		macCroatian "" \
		macCyrillic "" \
		macDingbats "" \
		macGreek "" \
		macIceland "" \
		macJapan "" \
		macRoman "" \
		macRomania "" \
		macThai "" \
		macTurkish "" \
		macUkraine "" \
		shiftjis Shift_JIS \
		symbol "" \
		unicode "" \
		utf-8 "" \
	]

	variable encodings
	array set encodings $encList
	variable reversemap
	foreach {enc mimeType} $encList {
		if {$mimeType != ""} {
			set reversemap([string tolower $mimeType]) $enc
		}
	}


	# mime::reversemapencoding --
	#
	#    mime::reversemapencodings maps MIME charset types onto tcl encoding names.
	#    Those that are unknown return "".
	#
	# Arguments:
	#       mimeType  The MIME charset to convert into a tcl encoding type.
	#
	# Results:
	#	Returns the tcl encoding name for the specified mime charset, or ""
	#       if none is known.

	proc reversemapencoding {mimeType} {

		variable reversemap

		set lmimeType [string tolower $mimeType]
		if {[info exists reversemap($lmimeType)]} {
			return $reversemap($lmimeType)
		}
		return ""
	}

	# mime::qp_decode --
	#
	#	Tcl version of quote-printable decode
	#
	# Arguments:
	#	string        The quoted-prinatble string to decode.
	#       encoded_word  Boolean value to determine whether or not encoded words
	#                     (RFC 2047) should be handled or not. (optional)
	#
	# Results:
	#	The decoded string is returned.

	proc qp_decode {string {encoded_word 0}} {
		# 8.1+ improved string manipulation routines used.
		# Special processing for encoded words (RFC 2047)

		if {$encoded_word} {
			# _ == \x20, even if SPACE occupies a different code position
			set string [string map [list _ \u0020] $string]
		}

		# smash the white-space at the ends of lines since that must've been
		# generated by an MUA.

		regsub -all -- {[ \t]+\n} $string "\n" string
		set string [string trimright $string " \t"]

		# Protect the backslash for later subst and
		# smash soft newlines, has to occur after white-space smash
		# and any encoded word modification.

		set string [string map [list "\\" "\\\\" "=\n" ""] $string]

		# Decode specials

		regsub -all -nocase {=([a-f0-9][a-f0-9])} $string {\\u00\1} string

		# process \u unicode mapped chars

		return [subst -novar -nocommand $string]
	}

	# mime::word_decode --
	#
	#    Word decodes strings that have been word encoded as per RFC 2047.
	#
	# Arguments:
	#       encoded   The word encoded string to decode.
	#
	# Results:
	#	Returns the string that has been decoded from the encoded message.

	proc word_decode {encoded} {

		variable reversemap

		if {[regexp -- {=\?([^?]+)\?(.)\?([^?]*)\?=} $encoded \
		    - charset method string] != 1} {
			error "malformed word-encoded expression '$encoded'"
		}

		set enc [reversemapencoding $charset]
		if {[string equal "" $enc]} {
			set enc $charset
			#error "unknown charset '$charset'"
		}

		switch -exact -- $method {
			b -
			B {
				set method base64
			}
			q -
			Q {
				set method quoted-printable
			}
			default {
				error "unknown method '$method', must be B or Q"
			}
		}

		switch -exact -- $method {
			base64 {
				set result [base64::decode $string]
			}
			quoted-printable {
				set result [qp_decode $string 1]
			}
			"" {
				# Go ahead
			}
			default {
				error "Can't handle content encoding \"$method\""
			}
		}
		return [list $enc $method $result]
	}

	# mime::field_decode --
	#
	#    Word decodes strings that have been word encoded as per RFC 2047
	#    and converts the string from UTF to the original encoding/charset.
	#
	# Arguments:
	#       field     The string to decode
	#
	# Results:
	#	Returns the decoded string in its original encoding/charset..

	proc field_decode {field} {

		# flatten the list of items to reconstruct the string

		set field [join $field]

		set result ""
		while {[regexp -indices -- {=\?([^?]+)\?(.)\?([^?]*)\?=} $field indices]} {

			# get the indices

			foreach {start end} $indices break

			# extract first part of field not containing the encoded-word

			append result [string range $field 0 [expr {$start-1}]]

			# retrieve decoded string and convert it to Unicode
			# from the original enconding/charset

			set decoded [word_decode [string range $field $start $end]]
			foreach {charset - string} $decoded break
			if {[catch {[append result [::encoding convertfrom $charset $string]]} ]} {
				append result $string
			}

			# remove encoded-word and trailing space (RFC 2047, see part 8)
			# from the rest of the string

			incr end
			set field [string trimleft [string range $field $end end]]
		}

		# append last part of field to the result after a space (need because
		# of the trimleft above)

		if {[string length $field]} {
			#append result " "
			append result $field
		}

		return $result
	}
}

