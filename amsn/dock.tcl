# Docking Protocol

::Version::setSubversionId {$Id$}

if { $initialize_amsn == 1 } { 
    global docksock 
    
    set docksock 0
}

proc dock_handler { sock } {
        global password systemtray_exist
	set l [gets $sock]
	
	if { [eof $sock] || ($l == "SESSION_END") || ($l == "") } {
		global docksock
		fileevent $docksock readable {}
		close $docksock
		set docksock 0
		set systemtray_exist 0
		return
	}
		
	if { $l == "GO_INBOX" } {
		::hotmail::hotmail_login
	} elseif { $l == "GO_SIGNINAS" } {
		cmsn_ns_connect [::config::getKey login] $password
	} elseif { $l == "GO_SIGNIN" } {
		cmsn_draw_login
	} elseif { $l == "GO_OPEN" } {
		if { [wm state .] == "iconic" } {
			wm deiconify .
		} elseif { [wm state .] == "normal" } {
			wm iconify .
		}
	} elseif { $l == "GO_ONLINE"} {
		ChCustomState NLN
	} elseif { $l == "GO_NOACT" } {
		ChCustomState IDL
	} elseif { $l == "GO_BUSY" } {
		ChCustomState BSY
	} elseif { $l == "GO_BRB" } {
		ChCustomState BRB
	} elseif { $l == "GO_AWAY" } {
		ChCustomState AWY
	} elseif { $l == "GO_ONPHONE" } {
		ChCustomState PHN
	} elseif { $l == "GO_LUNCH" } {
		ChCustomState LUN
	} elseif { $l == "GO_APP_OFFLINE" } {
		ChCustomState HDN
	} elseif { $l == "OPEN_INBOX" } {
		::hotmail::hotmail_login
	} elseif { $l == "SIGNIN" } {
		global password
		::MSN::connect
	} elseif { $l == "SIGNINAS" } {
		cmsn_draw_login
	} elseif { $l == "SIGNOUT" } {
		::MSN::logout
	} elseif { $l == "AMSN_CLOSE" } {
		exit
	} else {
		#puts stdout "Unknown dock command"
		status_log "Unknown dock command"
	}
}

proc send_dock {type status} {
	global docksock 
	if { $type == "STATUS" } {
		if { $docksock != 0 } {
		   after 100 [list puts $docksock $status]
		}
		after 100 [list statusicon_proc $status]
	} elseif { $type == "MAIL" } {
		after 100 [list mailicon_proc $status]
	}
}


proc close_dock {} {
	global systemtray_exist
	
	mailicon_proc 0
	statusicon_proc "REMOVE"

	global docksock
        if { $docksock != 0 } {
        	puts $docksock "SESSION_END"
		fileevent $docksock readable {}
		close $docksock
		set docksock 0
	}
	set systemtray_exist 0
}


proc accept_dock { sock addr cport } {
	global docksock srvSock
	if { $addr == "127.0.0.1" } {
		set docksock $sock
		
		close $srvSock
		set srvSock 0
	
		fconfigure $docksock -buffering line
		puts $docksock "SESSION_HAND"

		set reply [gets $docksock]
		if { $reply == "SESSION_HAND" } {
			puts $docksock [::MSN::myStatusIs]
			fileevent $docksock readable [list dock_handler $docksock]
		} else {
			#puts stdout "Error During HandShake! Closing!"
			status_log  "Error During HandShake! Closing!"
			close_dock
		}
	} else {
		#puts stdout "Dock connection attempted from remote location, refused!"
		status_log "Dock connection attempted from remote location, refused!"
	}
}

proc init_dock {} {
	global systemtray_exist
	#If the traydock is not disabled
	if { [::config::getKey use_tray] != 0} {

		if {[OnWin]} {
			trayicon_init
		} elseif {[OnLinux] || [OnOpenBSD]} {
			#We use the freedesktop standard here
			if { $systemtray_exist == 0 } {
				trayicon_init
				if { $systemtray_exist == -1 } {
					status_log "dock prob dock.tcl"
					#Too bad, couldn't load the trayicon
#					msg_box "[trans nosystemtray]"
				}
			}
			statusicon_proc [::MSN::myStatusIs]
		}		
	} else {
		close_dock
	}
}

proc UnixDock { } {
	if {[::config::getKey use_tray] && ([OnLinux] || [OnOpenBSD]) } {
		return 1
	} else {
		return 0
	}
}
proc WinDock { } {
	if {[::config::getKey use_tray] && [OnWin] } {
		return 1
	} else {
		return 0
	}
}
