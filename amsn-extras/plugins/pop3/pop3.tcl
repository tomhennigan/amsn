#######################################################
#             aMSN POP3 Checker Plugin                #
#                By Arieh Schneier                    #
#          With small contributions from:             #
#       Alberto Díaz and Jonas De Meulenaere          #
#          POP3 Code from Tclib project               #
#######################################################

namespace eval ::pop3 {
	variable config
	variable configlist
	variable emails 0
	variable newMails -1

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
			caption {POP3}
			leavemails {0}
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
			[list bool "Your mail program leaves mails on server" leavemails] \
			[list str "Display name" caption] \
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
		set popRet [string trim [gets $chan]]
		if { $popRet == "" && ![eof $chan] } {
			return
		}
		fileevent $chan readable ""

		if {[string first "+OK" $popRet] == -1} {
			plugins_log pop3 "ERROR : [string range $popRet 4 end]\n"
			set ::pop3::chanreturn_$chan "ERROR"
			return
		}
	
		set ::pop3::chanreturn_$chan [string range $popRet 3 end]
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
			plugins_log pop3 "Checking for messages now\n"
			set chan [::pop3::open $::pop3::config(host) $::pop3::config(user) $::pop3::config(pass) $::pop3::config(port)]
			#check that it opened properly
			if { [set ::pop3::chanopen_$chan] == 1 } {
				set mails [::pop3::status $chan]
				::pop3::close $chan

				plugins_log pop3 "POP3 messages: $mails\n"
				if { $::pop3::emails != $mails } {
					set dontnotifythis 0
					if { $::pop3::config(leavemails) == 1 } {
						if { $::pop3::emails < $mails } {
							set ::pop3::newMails [expr { $pop3::newMails + $mails - $::pop3::emails } ]
						} else {
							set dontnotifythis 1
						}
					} else {
						set ::pop3::newMails $mails
					}
					set ::pop3::emails $mails
					cmsn_draw_online

					if { $::pop3::config(notify) == 1 && $::pop3::newMails != 0 && $dontnotifythis == 0 } {
						::amsn::notifyAdd "POP3\n[trans newmail $::pop3::newMails]" "" "" plugins

						#If Growl plugin is loaded, show the notification
						set pluginidx [lindex [lsearch -all $::plugins::found "*growl*"] 0]
						if { $pluginidx != "" } {
							catch {growl post Pop POP3 [trans newmail $mails]}
						}
					}
				}
			} else {
				plugins_log pop3 "POP3 failed to open\n"
				unset ::pop3::chanopen_$chan
			}
		}

		catch {
			# Make sure there isn't duplicat calls
			after cancel ::pop3::check
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
		catch { after cancel ::pop3::check }
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
		#If online redraw main window to remove new line
		#Doesn't work yet, as events are still triggered after unload (need to fix)
		if { (!$::initialize_amsn) && ([::MSN::myStatusIs] != "FLN") } {
			cmsn_draw_online
		}
	}


	# ::pop3::loadDefaultEmail
	# Description:
	#	Loads the default email program for the system
	# Arguments: none
	proc loadDefaultEmail { } {
		if { $::tcl_platform(platform) == "windows" } {
			if { [catch { WinLoadFile $::pop3::config(mailProg) } ] } {
				if {[string equal $::version "0.94"]} {
					load [file join plugins winutils winutils.dll]
				} else {
					load [file join utils windows winutils winutils.dll]
				}
				WinLoadFile $::pop3::config(mailProg)
			}
		} else {
			if { [catch {eval "exec $::pop3::config(mailProg)"} res] } {
				plugins_log pop3 "Failed to load $::pop3::config(mailProg) with the error: $res\n"
			}
		}

		#reset number of new mails
		set ::pop3::newMails 0
		cmsn_draw_online
	}


	# ::pop3::draw
	# Description:
	#	Adds a line in the contact list of the number of emails drawn
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#     evPar   -> The array of parameters (Supplied by Plugins System)
	proc draw {event evPar} {		
		upvar 2 $evPar vars

		if {[string equal $::version "0.94"]} {
			set textb $vars(text)

			clickableImage $textb popmailpic mailbox {after cancel ::pop3::check; after 1 ::pop3::check} 5 0
		} else {
			#TODO: add parameter to event and get rid of hardcoded variable
			set pgtop $::pgBuddyTop
			set clbar $::pgBuddyTop.colorbar
			
			set textb $pgtop.pop3mail
			text $textb -font bboldf -height 1 -background white -borderwidth 0 -wrap none -cursor left_ptr \
				-relief flat -highlightthickness 0 -selectbackground white -selectborderwidth 0 \
				-exportselection 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0
			if {[::skin::getKey emailabovecolorbar]} {
				pack $textb -expand true -fill x -after $clbar -side bottom -padx 0 -pady 0
			} else {
				pack $textb -expand true -fill x -before $clbar -side bottom -padx 0 -pady 0
			}

			$textb configure -state normal

			clickableImage $textb popmailpic mailbox {after cancel ::pop3::check; after 1 ::pop3::check} [::skin::getKey mailbox_xpad] [::skin::getKey mailbox_ypad]
			
			#need the -2 is to include the 1 pixel above and below extra in a font
			set mailheight [expr [$textb.popmailpic cget -height]+(2*[::skin::getKey mailbox_ypad])-2]
			set textheight [font metrics splainf -linespace]
			if { $mailheight < $textheight } {
				set mailheight $textheight
			}
			$textb configure -font "{} -$mailheight"
		}

		#TODO: needs translation
		set balloon_message "Click here to check the number of messages now."
		bind $textb.popmailpic <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		bind $textb.popmailpic <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		bind $textb.popmailpic <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		if { $::pop3::newMails < 0 } {
			set mailmsg "Not Checked Yet ($::pop3::config(caption))"
		} elseif { $::pop3::newMails == 0 } {
			set mailmsg "[trans nonewmail] ($::pop3::config(caption))"
		} elseif {$::pop3::newMails == 1} {
			set mailmsg "[trans onenewmail] ($::pop3::config(caption))"
		} elseif {$::pop3::newMails == 2} {
			set mailmsg "[trans twonewmail 2] ($::pop3::config(caption))"
		} else {
			set mailmsg "[trans newmail $::pop3::newMails] ($::pop3::config(caption))"
		}
		
		if {[string equal $::version "0.94"]} {
			set maxw [expr [winfo width $vars(text)] -30]
			set short_mailmsg "[trunc $mailmsg $textb $maxw splainf]\n"
		} else {
			set maxw [expr [winfo width [winfo parent $pgtop]]-[$textb.popmailpic cget -width]-(2*[::skin::getKey mailbox_xpad])]
			set short_mailmsg [trunc $mailmsg $textb $maxw splainf]
		}

		$textb tag conf pop3mail -fore black -underline false -font splainf
		if { $::pop3::config(loadMailProg) } {
			$textb tag conf pop3mail -underline true
			$textb tag bind pop3mail <Button1-ButtonRelease> "$textb conf -cursor watch; after 1 ::pop3::loadDefaultEmail"
			$textb tag bind pop3mail <Enter> "$textb tag conf pop3mail -under false;$textb conf -cursor hand2"
			$textb tag bind pop3mail <Leave> "$textb tag conf pop3mail -under true;$textb conf -cursor left_ptr"
		}
		$textb insert end "$short_mailmsg" {pop3mail dont_replace_smileys}
		
		$textb configure -state disabled
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

		if {[string equal $::version "0.94"]} {
			set msg "[string range $msg 0 end-1] (Hotmail)\n"
		} else {
			set msg "[string range $msg 0 end] (Hotmail)"
		}
	}
}
