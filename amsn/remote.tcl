#########################################################
### remote.tcl v 1.0	2003/05/22   KaKaRoTo
#########################################################

::Version::setSubversionId {$Id$}

if { $initialize_amsn == 1 } {
	global remote_port remote_auth remote_sock_lock remote_sock
   
	set remote_port 0
	set remote_auth 0
	set remote_sock_lock 0
	set remote_sock 0
	set remote_authtimer 0
}

proc remote_check_online { } {
	if { [::MSN::myStatusIs] != "FLN" } {
		write_remote "[trans connected]..."
		return
	} else {
		after 1000 "remote_check_online"
	}
}

proc remote_touchauthtimer {} {
	global remote_authtimer
	set remote_authtimer 0
}

namespace eval ::remote {

	# connect 
	# connects you to your account
	#
	proc connect { } {
	
		if { [catch { ::MSN::connect } res] } {
			write_remote "[trans connecterror]"
		} else {
			write_remote "[trans connecting] ..." 
			after 1000 "remote_check_online"
		}
	}

	# logout
	# logs you out from the current session
	#
	proc logout { } {
		write_remote "[trans logout]"
		::MSN::logout
	}

	# help
	# prints the help message from the remote.help file
	#
	proc help { } {

		set fd [open "remote.help" r]
		set printhelp [read $fd]
		close $fd

		write_remote "$printhelp"
  
	}

	# online
	# Shows list of users connected
	#
	proc online { } {
		foreach username [::MSN::getList FL] {
			set state_code [::abook::getVolatileData $username state]

			if { $state_code !="FLN" } {
				write_remote "$username - [::abook::getNick $username] --- [trans status] : [trans [::MSN::stateToDescription $state_code]]"
			}
		}
	}

	proc status { } {
		set nick [::abook::getPersonal MFN]
		write_remote "[trans nick]: $nick"
		if {[ ::config::getKey protocol] == 11 } {
			set psm [::abook::getPersonal PSM]
			write_remote "[trans PSM]: $psm"
		}
		getstate
	}

	proc getstate { } {

		set my_state [::MSN::stateToDescription [::MSN::myStatusIs]]

		write_remote "Your state is currently on : $my_state"

	}

	proc setstate { {state ""} } {
		if { "$state" == "" } {
			write_remote "Possible status are :"
			write_remote " online, away, busy, noactivity, brb, onphone, lunch, appearoffline"
			return
		}

		set state [string tolower $state]
		if { "$state" == "online" } {
			ChCustomState NLN
		} elseif { "$state" == "away" } {
			ChCustomState AWY
		} elseif { "$state" == "busy" } {
			ChCustomState BSY
		} elseif { "$state" == "noactivity" } {
			ChCustomState IDL
		} elseif { "$state" == "brb" } {
			ChCustomState BRB
		} elseif { "$state" == "onphone" } {
			ChCustomState PHN
		} elseif { "$state" == "lunch" } {
			ChCustomState LUN
		} elseif { "$state" == "appearoffline" } {
			ChCustomState HDN
		} else {
			write_remote "Invalid state" error
			return
		}
		write_remote "State changed"
	}
	proc listcustomstates { } { 
		set numstates [StateList size] 
		
		if {$numstates > 0} { 
			write_remote "ID\tState name" 
			
			for { set stateid 0 } { $stateid < $numstates } { incr stateid } { 
				set state [StateList get $stateid] 
				write_remote "$stateid\t [lindex $state 0]" 
			} 
		} else { 
			write_remote "No custom states defined" 
		} 
	} 
	
	proc setcustomstate { state } { 
		set numstates [StateList size] 
		
		if { [string is digit $state] != 1 || $state < 0 || $state >= $numstates } { 
			write_remote "Invalid state" 
		} else { 
			ChCustomState $state 
		} 
	} 
	

       proc setpsm { {psm ""} } { 
                       ::MSN::changePSM "$psm" 
                       write_remote "PSM set to : $psm" 
       } 

	proc setnick { nickname } {
		if {$nickname != ""} {
			::MSN::changeName [::config::getKey login] "$nickname"
			write_remote "New nick set to : $nickname"
		} else {
			write_remote "New nick not entered"
		}
	}

	proc amsn_close { } {
		exit
	}

	proc whois { user } {

		set found 0

		foreach username [::MSN::getList FL] {
			if { "[::abook::getNick $username]" == "$user" } {
				write_remote "$user is : $username" 
				set found 1
				break
			}
		}
		if { $found == 0 } {
			write_remote "$user was not found in your contact list..." error
		}
	}

	proc whatis { user } {

		set found 0

		if { [string match "*@*" $user] == 0 } {
			set user [split $user "@"]
			set user "[lindex $user 0]@hotmail.com"
			set user [string tolower $user]
		}	

		foreach username [::MSN::getList FL] {
			if { "$username" == "$user" } {
				write_remote "$user is known as : [::abook::getNick $user]" 
				set found 1
				break
			}
		}
		if { $found == 0 } {
			write_remote "$user was not found in your contact list..." error
		}
	}

	# msg { args }
	# sends a message to a user
	#
	proc msg { args } {
		global userchatto

		if { [info exists userchatto] } {
			set user "$userchatto"
			set message "$args"
		} else {
			set user [lindex $args 0]
			set message "[lrange $args 1 end]"
		}

		set message [string map { \{ "" \} ""} $message]

		if { [string match "*@*" $user] == 0 } {
			set user [split $user "@"]
			set user "[lindex $user 0]@hotmail.com"
		}

		set lowuser [string tolower $user]
   
		set win_name [::ChatWindow::For $lowuser]

		if { $win_name == 0 } {
			::amsn::chatUser "$user"

			while { [set win_name [::ChatWindow::For $lowuser]] == 0 } { }
		}

		#set input "${win_name}.f.bottom.in.input"
		set input [text ${win_name}.tmp]
		$input insert end "${message}"
	
		::amsn::MessageSend $win_name $input 
	
		destroy $input
	
	}

	proc chatto { user } { 
		global userchatto
	
		if { [string match "*@*" $user] == 0 } {
			set user [split $user "@"]
			set user "[lindex $user 0]@hotmail.com"
		}

		set userchatto "$user"

	}

	proc endchat { } {
		global userchatto
		if { [info exists userchatto] } {
			unset userchatto
		}
	}

}

proc write_remote { dataout {colour "normal"} } {
	global remote_sock

	#set dataout [string map [list "\n" " $colour\n"]  $dataout]
  
	catch {puts $remote_sock [list $dataout $colour]}
}

proc read_remote { command sock } {
	global remote_auth remote_sock

	if { ![::config::getKey enableremote]} { 
		close $sock
		return
	} 	

	if { "$remote_sock" != "$sock" } {
		set remote_temp_sock $remote_sock
		init_remote $sock
		if {  $remote_auth == 1 } {
			write_remote "Remote controlling is already active"
			init_remote $remote_temp_sock
			return 0
		}
	}


	if {$command != ""} {
		#AIM-FIX: Make command a real quoted list, or it will raise
		#errors when containing braces
		set command [split $command]
		if { $remote_auth == 0 } {
			authenticate "$command" "$sock"
		} elseif { [catch {eval "::remote::$command" } res] } {
			write_remote "[trans syntaxerror] : $res" error
		}
	}
}


proc md5keygen { } { 
	set key [expr rand()]
	set key [expr {$key * 1000000}]

	return "$key"
}

proc authenticate { command sock } {
	global remotemd5key remote_auth remote_sock_lock remote_authtimer
	global userchatto

	if {$remote_authtimer} {
		close $sock
		return
	}

	if { $command == "auth" } {
		set remotemd5key "[md5keygen]"
		write_remote "auth $remotemd5key"
	} elseif { [lindex $command 0] == "auth2" && [info exists remotemd5key] } {
		if { "[lindex $command 1]" ==  "[::md5::hmac $remotemd5key [list [::config::getKey remotepassword]]]" } {
			set remote_auth 1
			set remote_sock_lock $sock
			catch { unset userchatto }
			write_remote "Authentication successfull"
		} else {
			set remote_authtimer 1
			after 3000 [list remote_touchauthtimer]
			vwait remote_authtimer
			write_remote "Authentication failed"
		}	
		unset remotemd5key
	} else {
		write_remote "[trans syntaxerror] : $command" error
	}
}


proc init_remote { sock } {
	global remote_sock

	set remote_sock $sock
}

proc close_remote { sock } {
	global remote_sock_lock remote_auth

	if { $remote_sock_lock == $sock } {
		set remote_auth 0
	} 
}

proc init_remote_DS { } {
	catch {socket -server new_remote_DS 63251}
}

proc new_remote_DS { sock addr port } {

	fileevent $sock readable "remote_DS_Hdl $sock"
	fconfigure $sock -buffering line
}

proc remote_DS_Hdl { sock } {

	set email [gets $sock]
	if {[eof $sock]} {
		catch {close $sock}
	} else {
		grep $email $sock
	}
}

proc grep { pattern sock } {
	global HOME2

	set filename "[file join $HOME2 profiles]"

	if { [string match "*@*" $pattern] == 0 } {
		set pattern [split $pattern "@"]
		set pattern "[lindex $pattern 0]@hotmail.com"
	}

	if {([file readable "$filename"] != 0) && ([file isfile "$filename"] != 0)} {
	
		set file_id [open "$filename" r]
		gets $file_id tmp_data
		if {$tmp_data != "amsn_profiles_version 1"} {	;# config version not supported!
			puts $sock "versionerror"
			close $file_id
			return 0
	   	}

		# Now add profiles from file to list
		while {[gets $file_id tmp_data] != "-1"} {
			set temp_data [split $tmp_data]
			if { [lindex $temp_data 0] == "$pattern" }  {
				close $file_id
				puts $sock "[lindex $temp_data 1]"
				return 1
			}
		}
		puts $sock "invalid"
		close $file_id
		return 0
	} else {
		puts $sock "noexist"
		return 0
	}
}
