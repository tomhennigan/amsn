#
#	Loging procedures
#
################################################################################

# TODO Implement some sort of log file size limit or date limit (remove any log entries older than date)

namespace eval ::log {

#///////////////////////////////////////////////////////////////////////////////
# StartLog (email)
# Opens the log file by email adress, called from WriteLog
# WriteLog has to check if fileid already exists before calling this proc

proc StartLog { email } {

	global log_dir config
	status_log "DEBUG: Opening log file for $email\n"
	set dirname [split $config(login) "@ ."]
	set dirname [join $dirname "_"]
	file mkdir [file join ${log_dir} ${dirname}]
	
	LogArray $email set [open "[file join ${log_dir} ${dirname} ${email}.log]" a+]
	fconfigure [LogArray $email get] -buffersize 1024
}


#///////////////////////////////////////////////////////////////////////////////
# LogArray (email action [sockid])
# Controls information about array for chosen user
# action can be :
#	set : Sets new fileid for certain user
#	get : Returns fileid for certain user, returns 0 if no fileid open
#	unset : Unsets fileid for certain user.

proc LogArray { email action {fileid 0}} {

	variable LogInfo

	switch $action {
		set {
			if { [info exists LogInfo($email)] } {
				status_log "DEBUG: Closing old Log fileid in set (this shouldnt happen)\n"
				StopLog $LogInfo($email)
				set LogInfo($email) $fileid
			} else {
				set LogInfo($email) $fileid
			}
		}

		unset {
			if { [info exists LogInfo($email)] } {
				unset LogInfo($email)
			} else {
				status_log "DEBUG: Calling unset on an unexisting variable\n"
			}
		}

		get {
			if { [info exists LogInfo($email)] } {
				return $LogInfo($email)
			} else {
				return 0
			}
		}
	}
}

#///////////////////////////////////////////////////////////////////////////////
# ConfArray (email action [conf])
# Controls information for array for chosen user for conference/conversation messages
# action can be :
#	newset : Sets new conf if dosen't exist already
#	set : Sets new conf number for certain user only if never set before
#	get : Returns conf number for certain user, returns 0 if no conf number set yet
#	unset : Unsets conf number for certain user.

proc ConfArray { email action {conf 0}} {

	variable ConfInfo

	switch $action {
		newset {
			if { [info exists ConfInfo($email)] == 0 } {
				set ConfInfo($email) $conf
			}
		}

		set {
			if { [info exists ConfInfo($email)] } {
				set ConfInfo($email) $conf
			}
		}

		unset {
			if { [info exists ConfInfo($email)] } {
				unset ConfInfo($email)
			} else {
				status_log "DEBUG: Calling unset on an unexisting variable\n"
			}
		}

		get {
			if { [info exists ConfInfo($email)] } {
				return $ConfInfo($email)
			} else {
				return 0
			}
		}
	}
}


		
#///////////////////////////////////////////////////////////////////////////////
# StopLog (email)
# Closes the log file for given user, called when closing chat window or when
# user leaves conference
# If user leaves conference and already has a chat window open, it'll close and
# reopen file on next message send/receive
proc StopLog {email} {

	status_log "DEBUG: Closing log file for $email\n"
	if { [LogArray $email get] != 0 } {
		puts -nonewline [LogArray $email get] "\[Window closed on [clock format [clock seconds] -format "%d %b %T"]\]\n\n"
		close [LogArray $email get]
	}
	LogArray $email unset
	ConfArray $email unset
}

	
#///////////////////////////////////////////////////////////////////////////////
# WriteLog (email txt)
# Writes txt to logfile of user given by email
# Checks if a fileid for current user already exists before writing
# conf 0 is used for conference messages

proc WriteLog { email txt {conf 0}} {

	set fileid [LogArray $email get]

	ConfArray $email newset $conf
	set last_conf [ConfArray $email get]

	status_log "$conf $last_conf"
	
	if { $fileid != 0 } {
		if { $last_conf != $conf } {
			if { $conf == 1 } {
				puts -nonewline $fileid "\[Private chat turned into Conference\]\n"
				ConfArray $email set $conf
			} else {
				puts -nonewline $fileid "\[Conference turned into Private chat\]\n"
				ConfArray $email set $conf
			}
		}
		puts -nonewline $fileid "[timestamp] $txt"
	} else {
		status_log "DEBUG : Opening log file for $email from WriteLog\n"
		StartLog $email
		set fileid [LogArray $email get]
		if { $conf == 0 } {
			puts -nonewline $fileid "\[Conversation started on [clock format [clock seconds] -format "%d %b %T"]\]\n"
		} else {
			puts -nonewline $fileid "\[Conference started on [clock format [clock seconds] -format "%d %b %T"]\]\n"
		}
		puts -nonewline $fileid "[timestamp] $txt"
	}
}


#///////////////////////////////////////////////////////////////////////////////
# OpenLogWin (email)
# Opens log window for user given by email, Called when History is chosen
# Thinking of adding a button to chat window and History to right click in list
#
# I dont think I will refresh this window while user is chatting, since he has the
# chat window open... So it will be static and contain what has been said before
# history button was pressed

}
