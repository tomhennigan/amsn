########################################################
#             AMSNPLUS PLUGIN NAMESPACE
########################################################
# Maintainer: markitus (markitus@catmail.homelinux.org)
# Created: 13/09/2004
#
# New features:
#   - Save nicks: with xml? how-to?
########################################################

namespace eval ::amsnplus {


	################################################
	# this starts amsnplus
	proc amsnplusStart { dir } {
		#register plugin
		::plugins::RegisterPlugin "aMSNPlus"
		source [file join $dir amsnplus.tcl]
		#plugin config
		array set ::amsnplus::config {
			colour_nicks {0}
		}
		#set ::amsnplus::configlist [ \
		#	list [list bool "Colour Nicks?" colour_nicks] \
		#]
		#register events
		::plugins::RegisterEvent amsnplus UserNameWritten parse_nick
		::plugins::RegisterEvent amsnplus chat_msg_send parseCommand
	}


	################################################
	# this proc deletes ·$<num> codification
	# and colours nick if enabled
	# should parse ALSO MULTIPLE COLORS ·$(num,num,num)
	proc parse_nick {event epvar} {
		upvar 2 user_name user_name
		upvar 2 colour colour
		set strlen [string length $user_name]
		set i 0
		while {$i < $strlen} {
			set str [string range $user_name $i [expr $i + 1]]
			if {[string equal $str "·\$"]} {
				if {$::amsnplus::config(colour_nicks)} {
					#know if the number has 1 or 2 digits
					set last [expr $i + 3]
					set char [string index $user_name [expr $i + 3]]
					if {![::amsnplus::is_a_number $char]} {
						set last [expr $i + 2]
					}
					#obtain rbg color
					set num [string range $user_name [expr $i + 2] $last]
					set colour [::amsnplus::getColor $num $colour]
					
					incr i
				}
				if {!$::amsnplus::config(colour_nicks)} {
					set last [expr $i + 3]
					set char [string index $user_name [expr $i + 3]]
					if {![::amsnplus::is_a_number $char]} {
						set last [expr $i + 2]
					}
					set user_name [string replace $user_name $i $last ""]
				}
			}
			if {![string equal $str "·\$"]} {
				incr i
			}
		}
	}
	
	####################################################
	# returns an rbg color with <num> code
	proc getColor { num default } {
		if {[string equal $num "0"]} {return "#FFFFFF"}
		if {[string equal $num "1"]} {return "#000000"}
		if {[string equal $num "2"]} {return "#00FF00"}
		if {[string equal $num "3"]} {return "#0000FF"}
		if {[string equal $num "4"]} {return "#FF0000"}
		return $default
	}
	
	####################################################
	# returns 1 if the char is a numbar, otherwise 0
	proc is_a_number { char } {
		if {[string equal $char "0"]} {return 1}
		if {[string equal $char "1"]} {return 1}
		if {[string equal $char "2"]} {return 1}
		if {[string equal $char "3"]} {return 1}
		if {[string equal $char "4"]} {return 1}
		if {[string equal $char "5"]} {return 1}
		if {[string equal $char "6"]} {return 1}
		if {[string equal $char "7"]} {return 1}
		if {[string equal $char "8"]} {return 1}
		if {[string equal $char "9"]} {return 1}
		return 0
	}
	
	#####################################################
	# this returns the first word read in a string
	proc readWord { i msg strlen } {
		set a $i
		set str ""
		while {$a<$strlen} {
			set char [string index $msg $a]
			if {[string equal $char " "]} {
				return $str
			}
			set str "$str$char"
			incr a
		}
		return $str
	}
	
	#####################################################
	# this looks chat text for a command
	# if found, executes what command is supposed to do
	proc parseCommand {event epvar} {
		#upvar 2 evPar loc_epvar
		upvar 2 nick nick
		upvar 2 msg msg
		upvar 2 chatid chatid
		upvar 2 win_name win_name
		upvar 2 fontfamily fontfamily
		upvar 2 fontcolor fontcolor
		upvar 2 fontstyle fontstyle
		set strlen [string length $msg]
		set i 0
		set incr 1
		while {$i<$strlen} {
			set char [::amsnplus::readWord $i $msg $strlen]
			######################################################
			#                 MORE COMMAND IDEAS
			# /sound file
			######################################################
			if {[string equal $char "/add"]} {
				set msg [string replace $msg $i [expr $i + 4] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				::MSN::addUser $userlogin
				set incr 0
			}
			if {[string equal $char "/addgroup"]} {
				set msg [string replace $msg $i [expr $i + 9] ""]
				set strlen [string length $msg]
				set groupname $msg
				set msg ""
				set strlen [string length $msg]
				::groups::Add $groupname
				::amsn::WinWrite $chatid "\nAdded group $groupname" green
				set incr 0
			}
			if {[string equal $char "/block"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				set nick [::abook::getNick $user_login]
				::MSN::blockUser $user_login [urlencode $nick]
				set incr 0
			}
			if {[string equal $char "/clear"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set chat_win $::ChatWindow::msg_windows($chatid)
				::ChatWindow::Clear $chat_win
				set incr 0
			}
			if {[string equal $char "/color"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set fontcolor [::amsnplus::readWord $i $msg $strlen]
				set flen [string length $fontcolor]
				set msg [string replace $msg $i [expr $i + $flen] ""]
				set strlen [string length $msg]
				set incr 0
			}
			if {[string equal $char "/config"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				Preferences
				set incr 0
			}
			if {[string equal $char "/delete"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				::MSN::deleteUser $user_login
				::amsn::WinWrite $chatid "\nYou've removed $user_login from the list\nTo add this contact again do: /add $user_login" green
				set incr 0
			}
			if {[string equal $char "/deletegroup"]} {
				set msg [string replace $msg $i [expr $i + 12] ""]
				set strlen [string length $msg]
				set groupname $msg
				set msg ""
				set strlen [string length $msg]
				::groups::Delete [::groups::GetId $groupname]
				::amsn::WinWrite $chatid "\nYou've deleted group $groupname\nTo add this group again do: /addgroup $groupname" green
				set incr 0
			}
			if {[string equal $char "/font"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set fontfamily [::amsnplus::readWord $i $msg $strlen]
				set flen [string length $fontfamily]
				set msg [string replace $msg $i [expr $i + $flen] ""]
				set strlen [string length $msg]
				set incr 0
			}
			if {[string equal $char "/help"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				::amsn::WinWrite $chatid "\nThis is the command help (text not implemented)" green
				set incr 0
			}
			if {[string equal $char "/info"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set field [::amsnplus::readWord $i $msg $strlen]
				set lfield [string length $field]
				set msg [string replace $msg $i [expr $i + $lfield] ""]
				set strlen [string length $msg]
				if {[string equal $field "nick"]} {
					set nick [::abook::getPersonal nick]
					::amsn::WinWrite $chatid "\nYour nick is $nick" green
				}
				if {[string equal $field "state"]} {
					set status [::MSN::myStatusIs]
					set status [::MSN::stateToDescription $status]
					::amsn::WinWrite $chatid "\nYour status is $status" green
				}
				set incr 0
			}
			if {[string equal $char "/invite"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				::MSN::inviteUser $chatid $userlogin
				set incr 0
			}
			if {[string equal $char "/leave"]} {
				set msg ""
				set strlen [string length $msg]
				::MSN::leaveChat $chatid
				::amsn::WinWrite $chatid "\nYou have left this conversation" green
				set incr 0
			}
			if {[string equal $char "/login"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				::MSN::connect
				set incr 0
			}
			if {[string equal $char "/logout"]} {
				set msg ""
				set strlen [string length $msg]
				::MSN::logout
				set incr 0
			}
			if {[string equal $char "/nick"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set nick $msg
				set nlen [string length $nick]
				set msg ""
				set strlen [string length $msg]
				::MSN::changeName [::config::getKey login] $nick
				::amsn::WinWrite $chatid "\nYour new nick is: $nick" green
				set incr 0
			}
			if {[string equal $char "/sendfile"]} {
				set msg [string replace $msg $i [expr $i + 9] ""]
				set strlen [string length $msg]
				set file [::amsnplus::readWord $i $msg $strlen]
				if {[string equal $file ""]} {
					::amsn::FileTransferSend $win_name
				}
				if {![string equal $file ""]} {
					::amsn::FileTransferSend $win_name $file
				}
				set msg ""
				set strlen [string length $msg]
				set incr 0
			}
			if {[string equal $char "/shell"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set command $msg
				set msg ""
				set strlen [string length $msg]
				set catch [catch {exec $command}]
				::amsn::WinWrite $chatid "\nExecuting in the shell: $command" green
				if {[string equal $catch "1"]} {
					::amsn::WinWrite $chatid "\nYour command is not valid" green
				} else {
					set result [exec $command]
					if {![string equal $result ""]} {
						::amsn::WinWrite $chatid "\nResults of the command/s:\n$result" green
					}
				}
				set incr 0
			}
			if {[string equal $char "/speak"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				set strlen [string length $msg]
				::amsn::chatUser $userlogin
				set incr 0
			}
			if {[string equal $char "/state"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set nstate [::amsnplus::readWord $i $msg $strlen]
				set slen [string length $nstate]
				set msg [string replace $msg $i [expr $i + $slen]]
				set strlen [string length $nick]
				if {[::amsnplus::stateIsValid $nstate]} {
					set cstate [::amsnplus::descriptionToState $nstate]
					::MSN::changeStatus $cstate
					::amsn::WinWrite $chatid "\nYour new state is: $nstate" green
				} else {
					::amsn::WinWrite $chatid "\n$nstate is not valid" green
				}
				set incr 0
			}
			if {[string equal $char "/style"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set fontstyle [::amsnplus::readWord $i $msg $strlen]
				set flen [string length $fontstyle]
				set msg [string replace $msg $i [expr $i + $flen] ""]
				set strlen [string length $msg]
				set incr 0
			}
			if {[string equal $char "/text"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				return $msg
			}
			if {[string equal $char "/unblock"]} {
				set msg [string replace $msg $i [expr $i + 8] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				set nick [::abook::getNick ${user_login}]
				::MSN::unblockUser ${user_login} [urlencode $nick]
				set incr 0
			}
			if {[string equal $char "/whois"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				if {[string equal $user_login ""]} {
					::amsn::WinWrite $chatid "\nYou must specify a contact" green
				} else {
					set ulen [string length $user_login]
					set msg [string replace $msg $i [expr $i + $ulen] ""]
					set strlen [string length $msg]
					set group [::groups::GetName [::abook::getContactData $user_login group]]
					set nick [::abook::getContactData $user_login nick]
					::amsn::WinWrite $chatid "\nContact information:\n$user_login\nNick: $nick\nGroup: $group" green
				}
				set incr 0
			}
			if {[string equal $incr "1"]} { incr i }
			set incr 1
		}
	}
	
	####################################################################
	# this is a proc to parse description to state in order to make
	# more easier to the user to change the state
	proc descriptionToState { newstate } {
		if {[string equal $newstate "online"]} { return "NLN" }
		if {[string equal $newstate "away"]} { return "AWY" }
		if {[string equal $newstate "busy"]} { return "BSY" }
		if {[string equal $newstate "rightback"]} { return "BSY" }
		if {[string equal $newstate "onphone"]} { return "PHN" }
		if {[string equal $newstate "gonelunch"]} { return "LUN" }
		return $newstate
	}

	###################################################################
	# this detects if the state user want to change is valid
	proc stateIsValid { state } {
		if {[string equal $state "online"]} { return 1 }
		if {[string equal $state "away"]} { return 1 }
		if {[string equal $state "busy"]} { return 1 }
		if {[string equal $state "rightback"]} { return 1 }
		if {[string equal $state "onphone"]} { return 1 }
		if {[string equal $state "gonelunch"]} { return 1 }
		return 0	
	}

}
