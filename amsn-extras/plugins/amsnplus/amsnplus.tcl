########################################################
#             AMSNPLUS PLUGIN NAMESPACE
########################################################
# Maintainer: markitus (markitus@catmail.homelinux.org)
# Created: 13/09/2004
########################################################

namespace eval ::amsnplus {


	################################################
	# this starts amsnplus
	proc amsnplusStart { dir } {
		#register plugin
		::plugins::RegisterPlugin "aMSN Plus"
		#set the amsnplus dir in config
		::config::setKey amsnpluspluginpath $dir
		#loading lang - if version is 0.95b (keep compatibility with 0.94)
		if {[string equal $version "0.95b"]} {
			set langdir [append dir "/lang"]
			set lang [::config::getGlobalKey language]
			load_lang $lang $langdir
		}
		#plugin config
		array set ::amsnplus::config {
			parse_nicks {1}
			colour_nicks {0}
			allow_commands {1}
		}
		if {[string equal $version "0.95b"]} {
			set ::amsnplus::configlist [ \
				list [list bool "[trans parsenicks]" parse_nicks] \
				list [list bool "[trans allowcommands]" allow_commands] \  
			]
		} else {
			set ::amsnplus::configlist [ \
				list [list bool "Do you want to parse nicks?" parse_nicks] \
				list [list bool "Do you want to allow commands in the chat window?" allow_commands] \
			]
		}
		#register events
		::plugins::RegisterEvent "aMSN Plus" parse_nick parse_nick
		::plugins::RegisterEvent "aMSN Plus" chat_msg_send parseCommand
	}

	################################################
	# this proc add external commands to amsnplus
	# (useful for other plugins)
	proc add_command { keyword action } {
		array set ::amsnplus::external_commands [list "/$keyword" $action]
	}

	################################################
	# this proc deletes ·$<num> codification
	# and colours nick if enabled
	# should parse ALSO MULTIPLE COLORS ·$(num,num,num)
	proc parse_nick {event epvar} {
		if {!$::amsnplus::config(parse_nicks)} {return}
		upvar 2 data data
		#upvar 2 colour colour
		set strlen [string length $data]
		set i 0
		while {$i < $strlen} {
			set str [string range $data $i [expr $i + 1]]
			if {[string equal $str "·\$"]} {
				if {$::amsnplus::config(colour_nicks)} {
					#know if the number has 1 or 2 digits
					set last [expr $i + 3]
					set char [string index $data [expr $i + 3]]
					if {![::amsnplus::is_a_number $char]} {
						set last [expr $i + 2]
					}
					#obtain rbg color
					set num [string range $data [expr $i + 2] $last]
					#set colour [::amsnplus::getColor $num $colour]
					
					incr i
				} else {
					set last [expr $i + 3]
					set char [string index $data [expr $i + 3]]
					if {![::amsnplus::is_a_number $char]} {
						set last [expr $i + 2]
					}
					set data [string replace $data $i $last ""]
				}
			} else {
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
		return [string match \[0-9\] $char]
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
		if { !$::amsnplus::config(allow_commands) } { return 0 }
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
			#check for the external_commands
			if {[info exists ::amsnplus::external_commands($char)]} {
				[set ::amsnplus::external_commands($char)]
			}
			#amsnplus commands
			if {[string equal $char "/all"]} {
				set msg [string replace $msg $i [expr $i + 4] ""]
				set strlen [string length $msg]
				foreach window $::ChatWindow::windows {
					set chat_id [::ChatWindow::Name $win_name]
					::amsn::MessageSend $window 0 $msg
				}
				set msg ""
				set strlen 0
				set incr 0
			} elseif {[string equal $char "/add"]} {
				set msg [string replace $msg $i [expr $i + 4] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				::MSN::addUser $userlogin
				set incr 0
			} elseif {[string equal $char "/addgroup"]} {
				set msg [string replace $msg $i [expr $i + 9] ""]
				set strlen [string length $msg]
				set groupname $msg
				set msg ""
				set strlen 0
				::groups::Add $groupname
				if {[string equal $version "0.95b"]} {
					::amsn::WinWrite $chatid "[trans groupadded $groupname]" green
				} else {
					::amsn::WinWrite $chatid "\nAdded group $groupname" green
				}
				set incr 0
			} elseif {[string equal $char "/block"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				set nick [::abook::getNick $user_login]
				::MSN::blockUser $user_login [urlencode $nick]
				set incr 0
			} elseif {[string equal $char "/clear"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set chat_win $::ChatWindow::msg_windows($chatid)
				::ChatWindow::Clear $chat_win
				set incr 0
			} elseif {[string equal $char "/color"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set fontcolor [::amsnplus::readWord $i $msg $strlen]
				::config::setKey mychatfont "$fontfamily $fontstyle $fontcolor"
				set flen [string length $fontcolor]
				set msg [string replace $msg $i [expr $i + $flen] ""]
				set strlen [string length $msg]
				set incr 0
			} elseif {[string equal $char "/config"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				Preferences
				set incr 0
			} elseif {[string equal $char "/delete"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				::MSN::deleteUser $user_login
				if {[string equal $version "0.95b"]} {
					::amsn::WinWrite $chatid "[trans groupdeleted $user_login]" green
				} else {
					::amsn::WinWrite $chatid "\nDeleted contact $user_login" green
				}
				set incr 0
			} elseif {[string equal $char "/deletegroup"]} {
				set msg [string replace $msg $i [expr $i + 12] ""]
				set strlen [string length $msg]
				set groupname $msg
				set msg ""
				set strlen 0
				::groups::Delete [::groups::GetId $groupname]
				if {[string equal $version "0.95b"]} {
					::amsn::WinWrite $chatid "[trans groupdeleted $groupname]" green
				} else {
					::amsn::WinWrite $chatid "\nDeleted group $groupname" green
				}
				set incr 0
			} elseif {[string equal $char "/font"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set fontfamily [::amsnplus::readWord $i $msg $strlen]
				::config::setKey mychatfont "$fontfamily $fontstyle $fontcolor"
				set flen [string length $fontfamily]
				set msg [string replace $msg $i [expr $i + $flen] ""]
				set strlen [string length $msg]
				set incr 0
			} elseif {[string equal $char "/help"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set help [::amsnplus::help]
				::amsn::WinWrite $chatid "\n$help" green
				set incr 0
			} elseif {[string equal $char "/info"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set field [::amsnplus::readWord $i $msg $strlen]
				set lfield [string length $field]
				set msg [string replace $msg $i [expr $i + $lfield] ""]
				set strlen [string length $msg]
				if {[string equal $field "color"]} {
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans ccolor $fontcolor]" green
					} else {
						::amsn::WinWrite $chatid "\nYour color is: $fontcolor" green
					}
				} elseif {[string equal $field "font"]} {
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans cfont $fontfamily]" green
					} else {
						::amsn::WinWrite $chatid "\nYour font is: $fontfamily" green
					}
				} elseif {[string equal $field "nick"]} {
					set nick [::abook::getPersonal nick]
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans cnick $nick]" green
					} else {
						::amsn::WinWrite $chatid "\nYour nick is: $nick" green
					}
				} elseif {[string equal $field "state"]} {
					set status [::MSN::myStatusIs]
					set status [::MSN::stateToDescription $status]
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans cstatus $status]" green
					} else {
						::amsn::WinWrite $chatid "\nYour status is: $status" green
					}
				} elseif {[string equal $field "style"]} {
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans cstyle $fontstyle]" green
					} else {
						::amsn::WinWrite $chatid "\nYour style is: $fontstyle" green
					}
				}
				set incr 0
			} elseif {[string equal $char "/invite"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				::MSN::inviteUser $chatid $userlogin
				set incr 0
			} elseif {[string equal $char "/kill"]} {
				set msg ""
				set strlen 0
				close_cleanup;exit
			} elseif {[string equal $char "/leave"]} {
				set msg ""
				set strlen 0
				::MSN::leaveChat $chatid
				if {[string equal $version "0.95b"]} {
					::amsn::WinWrite $chatid "[trans cleave]" green
				} else {
					::amsn::WinWrite $chatid "\nYou've left this conversation" green
				}
				set incr 0
			} elseif {[string equal $char "/login"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				::MSN::connect
				set incr 0
			} elseif {[string equal $char "/logout"]} {
				set msg ""
				set strlen 0
				::MSN::logout
				set incr 0
			} elseif {[string equal $char "/nick"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set nick $msg
				set nlen [string length $nick]
				set msg ""
				set strlen 0
				::MSN::changeName [::config::getKey login] $nick
				if {[string equal $version "0.95"]} {
					::amsn::WinWrite $chatid "[trans cnewnick $nick]" green
				} else {
					::amsn::WinWrite $chatid "\nYour new nick is: $nick" green
				}
				set incr 0
			} elseif {[string equal $char "/sendfile"]} {
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
				set strlen 0
				set incr 0
			} elseif {[string equal $char "/shell"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set command $msg
				set msg ""
				set strlen 0
				set catch [catch {exec $command}]
				if {[string equal $version "0.95b"]} {
					::amsn::WinWrite $chatid "[trans cshell $command]" green
				} else {
					::amsn::WinWrite $chatid "\nExecuting: $command" green
				}
				if {[string equal $catch "1"]} {
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans cnotvalid]" green
					} else {
						::amsn::WinWrite $chatid "\nYour command is not valid" green
					}
				} else {
					set result [exec $command]
					if {![string equal $result ""]} {
						if {[string equal $version "0.95b"]} {
							::amsn::WinWrite $chatid "[trans cresult $result]" green
						} else {
							::amsn::WinWrite $chatid "\nThis is the result of the command:\n$result" green
						}
					}
				}
				set incr 0
			} elseif {[string equal $char "/speak"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				set strlen [string length $msg]
				::amsn::chatUser $userlogin
				set incr 0
			} elseif {[string equal $char "/state"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set nstate [::amsnplus::readWord $i $msg $strlen]
				set slen [string length $nstate]
				set msg [string replace $msg $i [expr $i + $slen]]
				set strlen [string length $nick]
				if {[::amsnplus::stateIsValid $nstate]} {
					set cstate [::amsnplus::descriptionToState $nstate]
					::MSN::changeStatus $cstate
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans cnewstate $nstate]" green
					} else {
						::amsn::WinWrite $chatid "\nNew state is: $nstate" green
					}
				} else {
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans cnewstatenotvalid $nstate]" green
					} else {
						::amsn::WinWrite $chatid "\n$nstate is not valid" green
					}
				}
				set incr 0
			} elseif {[string equal $char "/style"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set fontstyle [::amsnplus::readWord $i $msg $strlen]
				::config::setKey mychatfont "$fontfamily $fontstyle $fontcolor"
				set flen [string length $fontstyle]
				set msg [string replace $msg $i [expr $i + $flen] ""]
				set strlen [string length $msg]
				set incr 0
			} elseif {[string equal $char "/text"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				return $msg
			} elseif {[string equal $char "/unblock"]} {
				set msg [string replace $msg $i [expr $i + 8] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				set nick [::abook::getNick ${user_login}]
				::MSN::unblockUser ${user_login} [urlencode $nick]
				set incr 0
			} elseif {[string equal $char "/whois"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				if {[string equal $user_login ""]} {
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans cspecify]" green
					} else {
						::amsn::WinWrite $chatid "\mYou must specify a contact" green
					}
				} else {
					set ulen [string length $user_login]
					set msg [string replace $msg $i [expr $i + $ulen] ""]
					set strlen [string length $msg]
					set group [::groups::GetName [::abook::getContactData $user_login group]]
					set nick [::abook::getContactData $user_login nick]
					if {[string equal $version "0.95b"]} {
						::amsn::WinWrite $chatid "[trans cinfo $user_login $nick $group]" green
					} else {
						::amsn::WinWrite $chatid "\n$user_login info: $nick $group" green
					}
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

	###################################################################
	# this returns the readme content in a variable
	proc help {} {
		set dir [::config::getKey amsnpluspluginpath]
		set channel [open "$dir/readme" "RDONLY"]
		return "[read $channel]"
	}

}
