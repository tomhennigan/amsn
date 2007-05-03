namespace eval ::ustat {
	variable arguments ""

	proc init { dir } {
		status_log "UserStatus loaded"
	
		::plugins::RegisterPlugin "UserStatus"
		::plugins::RegisterEvent "UserStatus" ChangeState statechange 
	
	}

	proc writestat { chatid user status } {
		set cur_status [::MSN::stateToDescription $status]
		set statuscolor [::skin::getKey contact_$cur_status]
		set statuscolor [string replace $statuscolor 0 0 ""]
		set family [lindex [::config::getGlobalKey basefont] 0]
		if { $family == "" } { set family "Helvetica"}
		set fontformat [list $family bold $statuscolor]
		::amsn::WinWrite $chatid "\n" says $fontformat 0
		::amsn::WinWriteIcon $chatid miniinfo 5 0
		set msg "[timestamp] [::abook::getDisplayNick $user] is now [trans $cur_status]\n"
	
		#status_log $msg
		::amsn::WinWrite $chatid $msg says $fontformat 0
	
	}

	proc statechange { event evPar } {
		
		# upvar 2 evPar newvar
		upvar 2 user user
		upvar 2 substate substate
		set newstate $substate
		set email $user
		set allchatids [::ChatWindow::getAllChatIds]
		foreach chatid $allchatids {
			if {[string first ::MSN::SB $chatid] != -1} {
				set user_list [::MSN::usersInChat $chatid]
				if {[lsearch $user_list $email] != -1 } {
						writestat $chatid $email $newstate
				}
			} elseif {$chatid == $email} {
				writestat $chatid $email $newstate
			}
		}
	return 1
	}
}
