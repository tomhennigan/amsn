#
#	Loging procedures
#
################################################################################

# TODO Implement some sort of log file size limit or date limit (remove any log entries older than date)
# TODO Save to LOG (if loging disabled, allows to log certain conversations only)
# TODO "Clear all logs" button
# TODO Selective loging (only log or don't log certain users)
# TODO Compress log files with optimal algorithm for txt files
# TODO Loging syntax options (timestamps, email or nics, etc)

namespace eval ::log {

#///////////////////////////////////////////////////////////////////////////////
# StartLog (email)
# Opens the log file by email adress, called from WriteLog
# WriteLog has to check if fileid already exists before calling this proc

proc StartLog { email } {

	global log_dir config

	# if we got no profile, set fileid to 0
	if { [LoginList exists 0 $config(login)] == 0 } {
		LogArray $email set 0
	} else {
		LogArray $email set [open "[file join ${log_dir} ${email}.log]" a+]
	    if { $config(lineflushlog) == 1 } {
		fconfigure [LogArray $email get] -buffering none -encoding utf-8 
	    } else {
		fconfigure [LogArray $email get] -buffersize 1024 -encoding utf-8
	    }
	}
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
# StopLog (email (who))
# Closes the log file for given user, called when closing chat window or when
# user leaves conference
# If user leaves conference and already has a chat window open, it'll close and
# reopen file on next message send/receive
# If who = 1 means user leaves conference
# If who = 0 means YOU have closed window
proc StopLog {email {who 0} } {

	status_log "DEBUG: Closing log file for $email\n"
	if { [LogArray $email get] != 0 } {
		if { $who == 1 } {
			puts -nonewline [LogArray $email get] "\|\"LRED\[[trans lclosedwin $email [clock format [clock seconds] -format "%d %b %T"]]\]\n\n"
		} else {
			puts -nonewline [LogArray $email get] "\|\"LRED\[[trans luclosedwin [clock format [clock seconds] -format "%d %b %T"]]\]\n\n"
		}
		close [LogArray $email get]
	}
	LogArray $email unset
	ConfArray $email unset
}


#///////////////////////////////////////////////////////////////////////////////
# PutLog (chatid user msg)
# Writes messages sent to PutMessage into the appropriate log files
# Checks for conferences and fixes conflicts if we have 2 windows for same user (1 private 1 conference)
# chatid : the chatid where the message was typed/sent
# user : user who sent message
# msg : msg

proc PutLog { chatid user msg } {
	
		set user_list [::MSN::usersInChat $chatid]
		foreach user_info $user_list {
			set user_login [lindex $user_info 0]
			if { [llength $user_list] > 1 } {
				::log::WriteLog $user_login "\|\"LITA$user \|\"LNOR: $msg\n" 1 $user_list
			} else {
				# for 2 windows (1 priv 1 conf)
				# if conf exists for current user & current chatid is not a conf
				if { [ConfArray $user_login get] == 1 && $chatid == $user_login} {
					::log::WriteLog $user_login "\|\"LITA\[[trans linprivate]\] $user \|\"LNOR: $msg\n" 2 $user_list
				} else {
					::log::WriteLog $user_login "\|\"LITA$user \|\"LNOR: $msg\n" 0 $user_list
				}
			}
		}
}

	
#///////////////////////////////////////////////////////////////////////////////
# WriteLog (email txt (conf) (userlist))
# Writes txt to logfile of user given by email
# Checks if a fileid for current user already exists before writing
# conf 1 is used for conference messages

proc WriteLog { email txt {conf 0} {user_list ""}} {

	set fileid [LogArray $email get]

	ConfArray $email newset $conf
	set last_conf [ConfArray $email get]
	
	foreach user_info $user_list {
		if { [info exists users] } {
			set users "$users, [lindex $user_info 0]"
		} else {
			set users [lindex $user_info 0]
		}
	}	

	if { $fileid != 0 } {
		if { $last_conf != $conf && $conf != 2} {
			if { $conf == 1 } {
				puts -nonewline $fileid "\|\"LRED\[[trans lprivtoconf ${users}]\]\n"
				ConfArray $email set $conf
			} elseif { [llength $user_list] == 1 } {
				puts -nonewline $fileid "\|\"LRED\[[trans lconftopriv ${users}]\]\n"
				ConfArray $email set $conf
			}
		}
		puts -nonewline $fileid "\|\"LGRA[timestamp] $txt"
	} else {
		StartLog $email
		set fileid [LogArray $email get]
		if { $fileid != 0 } {
		if { $conf == 0 } {
			puts -nonewline $fileid "\|\"LRED\[[trans lconvstarted [clock format [clock seconds] -format "%d %b %T"]]\]\n"
		} else {
			puts -nonewline $fileid "\|\"LRED\[[trans lenteredconf $email [clock format [clock seconds] -format "%d %b %T"]] \(${users}\) \]\n"
		}
		puts -nonewline $fileid "\|\"LGRA[timestamp] $txt"
		}
	}
}


#///////////////////////////////////////////////////////////////////////////////
# LeavesConf (usr_name user_list)
# Handles loging for when a user leaves a conference
# usr_name : email of person who has left

proc LeavesConf { chatid usr_name } {

	set user_list [::MSN::usersInChat $chatid]
	# If was in conference before this user leaves
	if { [llength $user_list] >= 1 && $usr_name != [lindex [lindex $user_list 0] 0] } {
		foreach user_info $user_list {
			set fileid [LogArray [lindex $user_info 0] get]
			if { $fileid != 0 } {
				puts -nonewline $fileid "\|\"LRED\[[trans lleftconf $usr_name]\]\n"
			}
			if { [llength $user_list] == 1 } {
				ConfArray [lindex $user_info 0] set 3
			}
		}
	StopLog $usr_name 1
	}
}	


#///////////////////////////////////////////////////////////////////////////////
# JoinsConf (usr_name user_list)
# Handles loging for when a user joins a conference
# usr_name : email of person who has joined

proc JoinsConf { chatid usr_name } {

	set user_list [::MSN::usersInChat $chatid]
	# If there is already 1 user in chat
	if { [llength $user_list] > 1  } {
		foreach user_info $user_list {
			set login [lindex $user_info 0]
			set fileid [LogArray $login get]
			if { $login != $usr_name && $fileid != 0} {
				puts -nonewline $fileid "\|\"LRED\[[trans ljoinedconf $usr_name]\]\n"
			}
		}
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

proc OpenLogWin { email } {

	global bgcolor config log_dir langenc
	
	set fileid [LogArray $email get]
	if { $fileid != 0 && $fileid != "stdout"} {
		flush $fileid
	}
	unset fileid
	
	set wname [split $email "@ ."]
	set wname [join $wname "_"]
	set wname ".${wname}_hist"

	if { [catch {toplevel ${wname} -width 600 -height 400 -borderwidth 0 -highlightthickness 0 } res ] } {
        	raise ${wname}
        	focus ${wname}
		wm deiconify ${wname}
        	return 0
      	}

	wm group ${wname} .

	wm title $wname "[trans history] (${email})"
      	wm geometry $wname 600x400

	frame $wname.blueframe -background $bgcolor

	frame $wname.blueframe.log -class Amsn -borderwidth 0
      	frame $wname.buttons -class Amsn


      	text $wname.blueframe.log.txt -yscrollcommand "$wname.blueframe.log.ys set" -font splainf \
         -background white -relief flat -highlightthickness 0 -height 1 -exportselection 1 -selectborderwidth 1 \
	 -wrap word
      	scrollbar $wname.blueframe.log.ys -command "$wname.blueframe.log.txt yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
	
	if { [file exists [file join ${log_dir} ${email}.log]] == 1 } {
		set id [open "[file join ${log_dir} ${email}.log]" r]
		fconfigure $id -encoding utf-8
		set logvar [read $id]
		close $id
	} else {
		set logvar "\|\"LRED[trans nologfile $email]"
	}


	ParseLog $wname $logvar

	button $wname.buttons.close -text "[trans close]" -command "destroy $wname" -font sboldf
	button $wname.buttons.save -text "[trans savetofile]" -command "::log::SaveToFile ${wname} ${email} [list ${logvar}]" -font sboldf
  	button $wname.buttons.clear -text "[trans clearlog]" -command "destroy $wname; ::log::ClearLog $email" -font sboldf

	menu ${wname}.copypaste -tearoff 0 -type normal
      	${wname}.copypaste add command -label [trans copy] -command "copy 0 ${wname}"
      	
 	pack $wname.blueframe.log.ys -side right -fill y
	pack $wname.blueframe.log.txt -side left -expand true -fill both
 	pack $wname.blueframe.log -side top -expand true -fill both -padx 4 -pady 4
	pack $wname.blueframe -side top -expand true -fill both
	pack $wname.buttons.close -padx 0 -side left
	pack $wname.buttons.save -padx 0 -side right
	pack $wname.buttons.clear -padx 0 -side right
	pack $wname.buttons -side bottom -fill x -pady 3
	bind $wname <Escape> "destroy $wname"
	bind ${wname}.blueframe.log.txt <Button3-ButtonRelease> "tk_popup ${wname}.copypaste %X %Y"
	bind ${wname} <Control-c> "copy 0 ${wname}"
}




#///////////////////////////////////////////////////////////////////////////////
# ParseLog (wname logvar)
# Decodes the log file and writes to log window
#
# wname : Log window
# logvar : variable containing the whole log file (sure need to setup log file limits)

proc ParseLog { wname logvar } {

	set aidx 0

	while {1} {
		set color [string range $logvar [expr $aidx + 3] [expr $aidx + 5]]
		set aidx [expr $aidx + 6]
		set bidx [string first "\|\"L" $logvar $aidx]
		if { $bidx != -1 } {
			set string [string range $logvar [expr $aidx] [expr $bidx - 1]]
			LogWriteWin $wname $string $color
			set aidx $bidx
		} else {
			set string [string range $logvar [expr $aidx] end]
			LogWriteWin $wname $string $color
			break
		}
	}

	${wname}.blueframe.log.txt yview moveto 1.0
      	${wname}.blueframe.log.txt configure -state disabled
}


#///////////////////////////////////////////////////////////////////////////////
# LogWriteWin (wname string color)
# Writes each string to log window with given color/style and subs the smileys
#
# wname : Log window
# string : variable containing the string to output
# color : varibale containing color/style information (RED, GRA, ITA, NOR)

proc LogWriteWin { wname string color } {
	
	${wname}.blueframe.log.txt tag configure red -foreground red
	${wname}.blueframe.log.txt tag configure gray -foreground gray
	${wname}.blueframe.log.txt tag configure normal -foreground black
	${wname}.blueframe.log.txt tag configure italic -foreground blue

	switch $color {
		RED {
			${wname}.blueframe.log.txt insert end "$string" red
		}
		GRA {
			${wname}.blueframe.log.txt insert end "$string" gray
		}
		NOR {
			${wname}.blueframe.log.txt insert end "$string" normal
		}
		ITA {
			${wname}.blueframe.log.txt insert end "$string" italic
		}
	}

	# This makes rendering long log files slow, maybe should make it optional?
	#smile_subst ${wname}.blueframe.log.txt
}


#///////////////////////////////////////////////////////////////////////////////
# SaveToFile (wname email logvar)
# File name selection menu and calls ParseToFile
#
# wname : Log window
# logvar : variable containing the whole log file (sure need to setup log file limits)

proc SaveToFile { wname email logvar } {
	set wname [string range $wname 1 end]
	set w .form${wname}
	toplevel $w
	wm title $w \"[trans savetofile]\"
	label $w.msg -justify center -text "Please give a filename"
	pack $w.msg -side top

	frame $w.buttons -class Degt
	pack $w.buttons -side bottom -fill x -pady 2m
	button $w.buttons.dismiss -text Cancel -command "destroy $w"
	button $w.buttons.save -text Save -command "::log::ParseToFile [list ${logvar}] $w.filename.entry; destroy $w"
	pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

	frame $w.filename -bd 2 -class Degt
	entry $w.filename.entry -relief sunken -width 40
	label $w.filename.label -text "Filename:"
	pack $w.filename.entry -side right 
	pack $w.filename.label -side left
	pack $w.msg $w.filename -side top -fill x
	focus $w.filename.entry

	fileDialog $w $w.filename.entry save $wname
}


#///////////////////////////////////////////////////////////////////////////////
# ParseToFile (logvar filepath)
# Decodes the log file and writes to file
#
# wname : Log window
# logvar : variable containing the whole log file (sure need to setup log file limits)

proc ParseToFile { logvar filepath } {

	global langenc

	set fileid [open [${filepath} get] a+]
	fconfigure $fileid -encoding utf-8
	if { $fileid != 0 } {
		set aidx 0
		while {1} {
			set aidx [expr $aidx + 6]
			set bidx [string first "\|\"L" $logvar $aidx]
			if { $bidx != -1 } {
				puts -nonewline $fileid [string range $logvar [expr $aidx] [expr $bidx - 1]]
				set aidx $bidx
			} else {
				puts -nonewline $fileid [string range $logvar [expr $aidx] end]
				break
			}
		}
	close $fileid
	}
}


#///////////////////////////////////////////////////////////////////////////////
# ClearLog (email)
# Deletes the current log file
#
# email : email of log to delete

proc ClearLog { email } {
	set parent "."
	catch {set parent [focus]}
	set answer [tk_messageBox -message "[trans confirm]" -type yesno -icon question -title [trans block] -parent $parent]
	if {$answer == "yes"} {	
		global log_dir
	
		catch { file delete [file join ${log_dir} ${email}.log] }

		OpenLogWin $email
	}
}


#///////////////////////////////////////////////////////////////////////////////
# ClearAllLogs ()
# Deletes the all the log files
#

proc ClearAllLogs {} {
	
	set parent "."
	catch {set parent [focus]}
	set answer [tk_messageBox -message "[trans confirm]" -type yesno -icon question -title [trans block] -parent $parent]
	if {$answer == "yes"} {

		global log_dir

		catch { file delete -force ${log_dir} }
		create_dir $log_dir
	}

}

}
