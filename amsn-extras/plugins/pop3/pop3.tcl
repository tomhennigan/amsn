#######################################################
#             aMSN POP3 Checker Plugin                #
#                By Arieh Schneier                    #
#          With small contributions from:             #
#       Alberto Díaz and Jonas De Meulenaere          #
#          POP3 Code from Tclib project               #
#######################################################

#TODO:
#  * add translation
#  * allow for multiple emails
#  * create a right click menu to delete mails
#  * make getfroms non blocking


namespace eval ::pop3 {
	variable config
	variable configlist
	variable emails -1
	variable newMails -1
	variable balloontext ""

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

	proc DeInit { } {
		::pop3::stop 0 0
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
			#test for end of file
			if { [eof $chan] } {
				plugins_log pop3 "ERROR : EOF reached in open(2)\n"
				error
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
				return
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
	#	The name in the "From:" section.
	proc ::pop3::from {chan id} {
		set from "unknown"
		set subject ""

		if {![catch {
			set data [::pop3::send $chan "TOP $id 0"]
		} errorStr]} {
			while {1} {
				set line [string trimright [gets $chan] \r]

				# End of the message is a line with just "."
				if {$line == "."} {
					break
				} elseif {[string index $line 0] == "."} {
					set line [string range $line 1 end]
				}

				if {[string equal -nocase -length 5 $line "From: "]} {
					set from [::pop3mime::field_decode [string range $line 6 end]]
				} elseif {[string equal -nocase -length 8 $line "Subject: "]} {
					set subject [::pop3mime::field_decode [string range $line 9 end]]
				}
			}
		}

		return [list $from $subject]
	}


	# ::pop3::getfroms
	# Description:
	#	Create a list of froms for the balloon message.
	# Arguments:
	#	chan   ->  The channel, returned by ::pop3::open
	#	first  ->  The id of the first email to check
	#	last   ->  The id of the last email to check
	# Results:
	#	A message for the balloon containing the names of who the mails are from is set
	#	in ::pop3::balloontext
	proc ::pop3::getfroms {chan first last} {
		set ::pop3::balloontext ""
		if {$first <= $last} {
			set ::pop3::balloontext "\n\nNew mail from:"
			for {set x $first} {$x <= $last} {incr x} {
				set info [::pop3::from $chan $x]
				set from [lindex $info 0]
				set subject [lindex $info 1] 
				set ::pop3::balloontext "$::pop3::balloontext\n$from\n$subject\n"
			}
		}
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
	# Arguments: None
	# Results:
	#	A notify window pops up when required.
	proc ::pop3::notify { } {
		if { $::pop3::config(notify) == 1 && $::pop3::newMails != 0 } {
			::amsn::notifyAdd "POP3\n[trans newmail $::pop3::newMails]" "" "" plugins

			#If Growl plugin is loaded, show the notification
			set pluginidx [lindex [lsearch -all $::plugins::found "*growl*"] 0]
			if { $pluginidx != "" } {
				catch {growl post Pop POP3 [trans newmail $::pop3::newMails]}
			}
		}
	}


	# ::pop3::check
	# Description:
	#	Use the 3 above methods to get the number of mails continuously
	# Arguments: None
	# Results:
	#	An integer variable wich contains the number of mails in the mbox
	proc ::pop3::check { } {
		catch {
			plugins_log pop3 "Checking for messages now\n"
			set chan [::pop3::open $::pop3::config(host) $::pop3::config(user) $::pop3::config(pass) $::pop3::config(port)]
			#check that it opened properly
			if { [set ::pop3::chanopen_$chan] == 1 } {
				set mails [::pop3::status $chan]

				plugins_log pop3 "POP3 messages: $mails\n"
				set dontnotifythis 1
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

					::pop3::getfroms $chan [expr $mails-$::pop3::newMails+1] $mails
				}
				::pop3::close $chan

				if { $dontnotifythis == 0 } {
					cmsn_draw_online
					::pop3::notify
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

		if { $::pop3::config(leavemails) == 1 } {
			#reset number of new mails
			set ::pop3::newMails 0
			cmsn_draw_online
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
			
			set mailheight [expr [$textb.popmailpic cget -height]+(2*[::skin::getKey mailbox_ypad])]
			#in windows need an extra -2 is to include the extra 1 pixel above and below in a font
			if {$::tcl_platform(platform) == "windows"} {
				set mailheight [expr $mailheight - 2]
			}
			set textheight [font metrics splainf -linespace]
			if { $mailheight < $textheight } {
				set mailheight $textheight
			}
			$textb configure -font "{} -$mailheight"
		}

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
		set balloon_message "$mailmsg$::pop3::balloontext"
		$textb tag bind pop3mail <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		$textb tag bind pop3mail <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		$textb tag bind pop3mail <Motion> +[list balloon_motion %W %X %Y $balloon_message]

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
		utf-8 ""]

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
#			error "unknown charset '$charset'"
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
			append result [::encoding convertfrom $charset $string]

			# remove encoded-word and trailing space (RFC 2047, see part 8)
			# from the rest of the string

			incr end
			set field [string trimleft [string range $field $end end]]
		}

		# append last part of field to the result after a space (need because
		# of the trimleft above)

		if {[string length $field]} {
#			append result " "
			append result $field
		}

		return $result
	}
}
