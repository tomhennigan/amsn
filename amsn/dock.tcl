# Docking Protocol

set docksock 0

proc dock_handler { sock } {
        global password
	set l [gets $sock]
	
	if { [eof $sock] || ($l == "SESSION_END") || ($l == "") } {
		global docksock config
		fileevent $docksock readable {}
		close $docksock
		set docksock 0
		set config(dock) 0
		return
	}
		
	if { $l == "GO_INBOX" } {
		hotmail_login $config(login) $password
	} elseif { $l == "GO_SIGNINAS" } {
		cmsn_ns_connect $config(login) $password
	} elseif { $l == "GO_SIGNIN" } {
		cmsn_draw_login
	} elseif { $l == "GO_OPEN" } {
		if { [wm state .] == "iconic" } {
			wm deiconify .
		} elseif { [wm state .] == "normal" } {
			wm iconify .
		}
	} elseif { $l == "GO_ONLINE"} {
		::MSN::changeStatus NLN
	} elseif { $l == "GO_NOACT" } {
		::MSN::changeStatus IDL
	} elseif { $l == "GO_BUSY" } {
		::MSN::changeStatus BSY
	} elseif { $l == "GO_BRB" } {
			::MSN::changeStatus BRB
	} elseif { $l == "GO_AWAY" } {
			::MSN::changeStatus AWY
	} elseif { $l == "GO_ONPHONE" } {
		::MSN::changeStatus PHN
	} elseif { $l == "GO_LUNCH" } {
		::MSN::changeStatus LUN
	} elseif { $l == "GO_APP_OFFLINE" } {
		::MSN::changeStatus HDN
	} elseif { $l == "OPEN_INBOX" } {
		global config password
		hotmail_login $config(login) $password
	} elseif { $l == "SIGNIN" } {
		global config password
		::MSN::connect $config(login) $password
	} elseif { $l == "SIGNINAS" } {
		cmsn_draw_login
	} elseif { $l == "SIGNOUT" } {
		::MSN::logout
		save_alarms
	} elseif { $l == "AMSN_CLOSE" } {
		close_cleanup
		exit
	} else {
		puts stdout "Unknow dock command"
	}
}

#proc send_dock {status} {
#	global docksock
#	if { $docksock != 0 } {
#	   puts $docksock $status
#	}
#}

proc send_dock {type status} {
	global docksock 
	if { $type == "STATUS" } {
		if { $docksock != 0 } {
		   puts $docksock $status
		}
		statusicon_proc $status
	} elseif { $type == "MAIL" } {
		mailicon_proc $status
	}
}


proc close_dock {} {
	mailicon_proc 0
	statusicon_proc "REMOVE"

	global docksock config
        if { $docksock != 0 } {
        	puts $docksock "SESSION_END"
		fileevent $docksock readable {}
		close $docksock
		set docksock 0
	}
	set config(dock) 0		;# Config is saved before so this dosent affect it
}


proc accept_dock { sock addr cport } {
	global docksock user_stat srvSock
	if { $addr == "127.0.0.1" } {
		set docksock $sock
		
		close $srvSock
		set srvSock 0
	
		fconfigure $docksock -buffering line
		puts $docksock "SESSION_HAND"

		set reply [gets $docksock]
		if { $reply == "SESSION_HAND" } {
			puts $docksock $user_stat
			fileevent $docksock readable [list dock_handler $docksock]
		} else {
			puts stdout "Error During HandShake! Closing!"
			close_dock
		}
	} else {
		puts stdout "Dock connection attempted from remote location, refused!"
	}
}

proc init_dock {} {
#	global config program_dir srvSock docksock
	global config systemtray_exist srvSock docksock

	if { $config(dock) != 0} {
		if { $config(dock) == 1 } {
			set svcPort 11983
			if { [catch {socket -server accept_dock $svcPort} srvSock] } {
				close_dock
			}
		}
		
		if { $config(dock) == 1} {

			if { $docksock != 0 } {
				close_dock
				set config(dock) 1
			}
			catch {exec [file join ${program_dir} plugins/gnomedock] ${program_dir}/plugins/icons/ &} res
		} elseif { $config(dock) == 2} {
#			if { $docksock != 0 } {
#				close_dock
#				set config(dock) 2
#			}
#			catch {exec [file join ${program_dir} plugins/gnomedock] ${program_dir}/plugins/icons/ &} res
		} elseif { $config(dock) == 3} {
			if { $systemtray_exist == 0 } {
				trayicon_init
				if { $systemtray_exist == -1 } {
					set config(dock) 0
					msg_box "[trans nosystemtray]"
				}
			}
			statusicon_proc "FLN"
		}
		vwait events

	} elseif { $config(dock) == 0 } {
		close_dock
	}
}
