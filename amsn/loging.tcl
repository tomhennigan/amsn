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

	global log_dir
	status_log "DEBUG: Opening log file for $email\n"
	set user_email [split $email "@"]
	set user_login [lindex $user_email 0]

	LogArray $email set [open "[file join ${log_dir} ${user_login}]" a+]
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
# StopLog (email)
# Closes the log file for given user, called when closing chat window or when
# user leaves conference
# If user leaves conference and already has a chat window open, it'll close and
# reopen file on next message send/receive
proc StopLog {email} {

	status_log "DEBUG: Closing log file for $email\n"
	if { [LogArray $email get] != 0 } {
		close [LogArray $email get]
	}
	LogArray $email unset
}

	
#///////////////////////////////////////////////////////////////////////////////
# WriteLog (email txt)
# Writes txt to logfile of user given by email
# Checks if a fileid for current user already exists before writing

proc WriteLog { email txt } {

	set fileid [LogArray $email get]
	
	if { $fileid != 0 } {
		status_log "DEBUG : writing to log file of $email\n"
		puts -nonewline $fileid $txt
	} else {
		status_log "DEBUG : Opening log file for $email from WriteLog\n"
		StartLog $email
		set fileid [LogArray $email get]
		puts -nonewline $fileid $txt
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
