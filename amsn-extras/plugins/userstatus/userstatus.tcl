namespace eval ::ustat {
	variable arguments ""

	proc init { dir } {
		status_log "UserStatus loaded"
	
		::plugins::RegisterPlugin "UserStatus"
		::plugins::RegisterEvent "UserStatus" ChangeState statechange 
	
	}

	proc writestat { chatid status } {
		::amsn::WinWrite $chatid "\n" blue  "" 0
		::amsn::WinWriteIcon $chatid miniinfo 5 0
		set msg "[timestamp] [::abook::getDisplayNick $chatid] is now [trans [::MSN::stateToDescription $status]] \n"
	
		#status_log $msg
		::amsn::WinWrite $chatid $msg blue "" 0
	
	}

	proc statechange { event evPar } {
		
		# upvar 2 evPar newvar
		upvar 2 user user
		upvar 2 substate substate
		set newstate $substate
		set email $user
	

		if { [ lsearch [::ChatWindow::getAllChatIds] $email ] >= 0 } {
			writestat $email $newstate
		}

	}
}
