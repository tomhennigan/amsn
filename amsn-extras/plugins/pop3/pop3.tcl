#######################################################
#             aMSN POP3 Checker Plugin                #
#        By Alberto Díaz and Arieh Schneier           #
#          POP3 Code from Tclib project               #
#######################################################
namespace eval ::pop3 {
	variable config
	variable configlist
	variable emails 0

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
			host {"your.mailserver.here"}
			user {"user_login@here"}
			pass {""}
			port {110}
			minute {5}
			notify {1}
			loadMailProg {0}
			mailProg {msimn}
		}

		set ::pop3::configlist [list \
			[list str "Check for new messages every ? minutes" minute] \
			[list str "POP3 Server"  host] \
			[list str "Your user login" user] \
			[list pass "Your password" pass] \
			[list str "Port (optional)" port] \
			[list bool "Show notify window" notify] \
			[list bool "Load mail program on click" loadMailProg] \
			[list str "          Mail Program" mailProg] \
		]

		#only start checking now if already online
		if { (!$::initialize_amsn) && ([::MSN::myStatusIs] != "FLN") } {
			::pop3::start 0 0
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
		catch {::pop3::send $chan "QUIT"}
		::close $chan
	}


	# pop3::open
	# Description
	#	Opens a connection to a POP3 mail server.
	# Arguments:
	#       args ->  A list of options and values, possibly empty,
	#		 followed by the regular arguments, i.e. host, user,
	#		 passwd and port. The latter is optional.
	#
	#	host   -> The name or IP address of the POP3 server host.
	#       user   -> The username to use when logging into the server.
	#       passwd -> The password to use when logging into the server.
	#       port   -> (optional) The socket port to connect to, defaults
	#                 to port 110, the POP standard port address.
	# Results:
	#	The connection channel (a socket).
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
	
		set chan [socket $host $port]
		fconfigure $chan -buffering none
	
		if {$cstate(msex)} {
			# We are talking to MS Exchange. Work around its quirks.
			fconfigure $chan -translation binary
		} else {
			fconfigure $chan -translation {binary crlf}
		}
	
		if {[catch {::pop3::send $chan {}} errorStr]} {
			::close $chan
		}

		if {0} {
			# -FUTURE- Identify MS Exchange servers
			set cstate(msex) 1
	
			# We are talking to MS Exchange. Work around its quirks.
			fconfigure $chan -translation binary
		}
	
		if {[catch {
			::pop3::send $chan "user $user"
			::pop3::send $chan "pass $password"
		} errorStr]} {
			::close $chan
			return "POP3 LOGIN ERROR: $errorStr\n"
		}
		
		return $chan
	}
	
	
	# ::pop3::send
	# Description:
	#	Send a command string to the POP3 server.  This is an
	#	internal function, but may be used in rare cases.
	# Arguments:
	#	chan      -> The channel open to the POP3 server.
	#       cmdstring -> POP3 command string
	# Results:
	#	Result string from the POP3 server, except for the +OK tag.
	#	Errors from the POP3 server are thrown.
	proc ::pop3::send {chan cmdstring} {
		global PopErrorNm PopErrorStr debug
		set stated 0
	
		if {$cmdstring != {}} {
			puts $chan $cmdstring
		}
	   
		set popRet [string trim [gets $chan]]
	
		if {[string first "+OK" $popRet] == -1} {
			error [string range $popRet 4 end]
		}
	
		return [string range $popRet 3 end]
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
		set data  [::pop3::send $chan "STAT"]
		return [lindex [split [string range $data 1 end] ] 0]
	}


	# ::pop3::check
	# Description:
	#	Use the 3 above methods to get the number of mails continuously
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#       evPar   -> The array of parameters (Supplied by Plugins System)
	# Results:
	#	An integer variable wich contains the number of mails in the mbox
	proc ::pop3::check { } {
		catch {
			set chan [::pop3::open $::pop3::config(host) $::pop3::config(user) $::pop3::config(pass) $::pop3::config(port)]
			set mails [::pop3::status $chan]
			::pop3::close $chan

			if { $::pop3::emails != $mails } {
				set ::pop3::emails $mails
				cmsn_draw_online

				if { $::pop3::config(notify) == 1 && $mails != 0 } {
					::amsn::notifyAdd "POP3\n[trans newmail $mails]" "" "" plugins
				}
				plugins_log pop3 "POP3 messages: $mails\n"
			}
		}

		catch {
			# Call itself again after x minutes
			set time [expr {int($::pop3::config(minute) *60000)}]
			after $time ::pop3::check
		}
	}


	# ::pop3::start
	# Description:
	#	Starts checking for new messages
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#     evPar   -> The array of parameters (Supplied by Plugins System)
	proc start {event evPar} {
		#cancel any previous starts first
		::pop3::stop 0 0
		catch { after 5000 ::pop3::check }
	}


	# ::pop3::stop
	# Description:
	#	Stops checking for new messages
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#     evPar   -> The array of parameters (Supplied by Plugins System)
	proc stop {event evPar} {
		catch { after cancel ::pop3::check }
	}


	# ::pop3::loadDefaultEmail
	# Description:
	#	Loads the default email program for the system
	# Arguments: none
	proc loadDefaultEmail { } {
		if { $::tcl_platform(platform) == "windows" } {
			if { [catch { WinLoadFile $::pop3::config(mailProg) } ] } {
				load [file join plugins winutils winutils.dll]
				WinLoadFile "msimn"
			}
		} else {
			if { [catch {eval "exec $::pop3::config(mailProg)"} res] } {
				plugins_log pop3 "Failed to load $::pop3::config(mailProg) with the error: $res"
			}
		}
	}


	# ::pop3::draw
	# Description:
	#	Adds a line in the contact list of the number of emails drawn
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#     evPar   -> The array of parameters (Supplied by Plugins System)
	proc draw {event evPar} {		
		upvar 2 $evPar vars

		if { $::pop3::emails == 0 } {
			set mailmsg "[trans nonewmail] (POP3)"
		} elseif {$::pop3::emails == 1} {
			set mailmsg "[trans onenewmail] (POP3)"
		} elseif {$::pop3::emails == 2} {
			set mailmsg "[trans twonewmail 2] (POP3)"
		} else {
			set mailmsg "[trans newmail $::pop3::emails] (POP3)"
		}
		set maxw [expr [winfo width $vars(text)] -30]
		set short_mailmsg [trunc $mailmsg $vars(text) $maxw splainf]

		clickableImage $vars(text) popmailpic mailbox {::pop3::stop 0 0; after 1 ::pop3::check} 5 0
		#TODO needs translation
		set balloon_message "Click here to check the number of messages now."
		bind $vars(text).popmailpic <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		bind $vars(text).popmailpic <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		bind $vars(text).popmailpic <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		if { $::pop3::config(loadMailProg) } {
			#clickableImage $vars(text) popmailpic mailbox "::pop3::loadDefaultEmail" 5 0

			#Set up TAGS for mail notification
			$vars(text) tag conf pop3mail -fore black -underline true -font splainf
			$vars(text) tag bind pop3mail <Button1-ButtonRelease> "$vars(text) conf -cursor watch; ::pop3::loadDefaultEmail"
			$vars(text) tag bind pop3mail <Enter> "$vars(text) tag conf pop3mail -under false;$vars(text) conf -cursor hand2"
			$vars(text) tag bind pop3mail <Leave> "$vars(text) tag conf pop3mail -under true;$vars(text) conf -cursor left_ptr"

			$vars(text) insert end "$short_mailmsg\n"  pop3mail
			$vars(text) tag add dont_replace_smileys pop3mail.first pop3mail.last
		} else {
			#label $vars(text).popmailpic -image [::skin::loadPixmap mailbox] -background white
			$vars(text) window create end -window $vars(text).popmailpic -padx 3 -pady 0 -align center -stretch true

			$vars(text) insert end "$short_mailmsg\n"
		}

		if { ![::config::getKey checkemail] } {
			$vars(text) insert end "\n"
		}
	}


	# ::pop3::addhotmail
	# Description:
	#	Adds ' (Hotmail)' to the line in the contact list of the number of emails
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#     evPar   -> The array of parameters (Supplied by Plugins System)
	proc addhotmail {event evPar} {		
		upvar 2 $evPar vars
		upvar 2 $vars(msg) msg

		set msg "[string range $msg 0 end-1] (Hotmail)\n"
	}
}
