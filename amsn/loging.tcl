#
#	Logging procedures
#
################################################################################

# TODO Implement some sort of log file size limit or date limit (remove any log entries older than date)
# TODO Save to LOG (if logging disabled, allows to log certain conversations only)
# TODO "Clear all logs" button
# TODO Selective logging (only log or don't log certain users)
# TODO Compress log files with optimal algorithm for text files
# TODO Logging syntax options (timestamps, email or nics, etc)

namespace eval ::log {

#///////////////////////////////////////////////////////////////////////////////
# StartLog (email)
# Opens the log file by email address, called from WriteLog
# WriteLog has to check if fileid already exists before calling this proc

proc StartLog { email } {


	# if we got no profile, set fileid to 0
	if { [LoginList exists 0 [::config::getKey login]] == 0 } {
		LogArray $email set 0
	} else {
	    LogArray $email set [CheckLogDate $email]

	    if { [::config::getKey lineflushlog] == 1 } {
		fconfigure [LogArray $email get] -buffering none -encoding utf-8 
	    } else {
		fconfigure [LogArray $email get] -buffersize 1024 -encoding utf-8
	    }
	}
}


#///////////////////////////////////////////////////////////////////////////////
# CheckLogDate (email)
# Opens the log file by email address, called from StartLog
# Checks if the date the file was created is older than a month, and moves file if necessary
#

proc CheckLogDate {email} {
    global log_dir

    status_log "Opening file\n"
    create_dir $log_dir

    if { ![file exists [file join $log_dir date]] } {
	status_log "Date file not found, creating\n\n"
	set fd [open "[file join ${log_dir} date]" w]
	close $fd
	return [open "[file join ${log_dir} ${email}.log]" a+]
    } 

    if { [::config::getKey logsbydate] == 0 } {
	return [open "[file join ${log_dir} ${email}.log]" a+]
    }



    file stat [file join  $log_dir date] datestat
    
    status_log "stating file $log_dir/date = [array get datestat]\n"

    set date [clock format $datestat(mtime) -format "%B %Y"]

    status_log "Found date : $date\n" red

    if {  $date != [clock format [clock seconds] -format "%B %Y"] } {
	status_log "Log was begun in a different month, moving logs\n\n" red

	set to $date
	set idx 0
	while {[file exists [file join ${log_dir} $to]] } {
	    status_log "Directory already used.. .bug? anyways, we don't want to overwrite\n"
	    set to "${date}.$idx"
	    incr idx
	}

	catch {file delete [file join ${log_dir} date]}

	create_dir [file join ${log_dir} $to]

	foreach file [glob -nocomplain -types f "${log_dir}/*.log"] {
	    status_log "moving $file\n" blue
	    file rename $file [file join ${log_dir} $to]
	}
	
	set fd [open "[file join ${log_dir} date]" w]
	close $fd
	


    }
    
    return [open "[file join ${log_dir} ${email}.log]" a+]

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
				status_log "DEBUG: Closing old Log fileid in set (this shouldn't happen)\n"
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
#	newset : Sets new conf if doesn't exist already
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
			puts -nonewline [LogArray $email get] "\|\"LRED\[[trans lclosedwin $email [clock format [clock seconds] -format "%d %b %Y %T"]]\]\n\n"
		} else {
			puts -nonewline [LogArray $email get] "\|\"LRED\[[trans luclosedwin [clock format [clock seconds] -format "%d %b %Y %T"]]\]\n\n"
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

proc PutLog { chatid user msg {fontformat ""}} {
	
	if {$fontformat == ""} {
		set color "NOR"
	} else {
		set color "C[lindex $fontformat 2]"
	}

	set user_list [::MSN::usersInChat $chatid]
	foreach user_info $user_list {
		set user_login [lindex $user_info 0]
		if { [llength $user_list] > 1 } {
			::log::WriteLog $user_login "\|\"LITA$user :\|\"L$color $msg\n" 1 $user_list
		} else {
			# for 2 windows (1 priv 1 conf)
			# if conf exists for current user & current chatid is not a conf
			if { [ConfArray $user_login get] == 1 && $chatid == $user_login} {
				::log::WriteLog $user_login "\|\"LITA\[[trans linprivate]\] $user :\|\"L$color $msg\n" 2 $user_list
			} else {
				::log::WriteLog $user_login "\|\"LITA$user :\|\"L$color $msg\n" 0 $user_list
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
			puts -nonewline $fileid "\|\"LRED\[[trans lconvstarted [clock format [clock seconds] -format "%d %b %Y %T"]]\]\n"
		} else {
			puts -nonewline $fileid "\|\"LRED\[[trans lenteredconf $email [clock format [clock seconds] -format "%d %b %Y %T"]] \(${users}\) \]\n"
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
# I don't think I will refresh this window while user is chatting, since he has the
# chat window open... So it will be static and contain what has been said before
# history button was pressed

proc OpenLogWin { {email ""} } {

	global log_dir langenc logvar

	#Get all the contacts
	foreach contact [::abook::getAllContacts] {
		#Selects the contacts who are in our list and adds them to the contact_list
		if {[string last "FL" [::abook::getContactData $contact lists]] != -1} {
			lappend contact_list $contact
		}
	}
	#Sorts contacts
	set sortedcontact_list [lsort -dictionary $contact_list]

	#Add the eventlog
	lappend sortedcontact_list eventlog

	#If there is no email defined, we remplace it by the first email in the dictionary order
	if {$email == ""} {
		set email [lindex $sortedcontact_list 0]
	}
	
	set fileid [LogArray $email get]
	if { $fileid != 0 && $fileid != "stdout"} {
		flush $fileid
	}
	unset fileid

	set wname [::log::wname $email]

	if { [catch {toplevel ${wname} -width 600 -height 400 -borderwidth 0 -highlightthickness 0 } res ] } {
        	raise ${wname}
        	focus ${wname}
		wm deiconify ${wname}
        	return 0
      	}

	wm group ${wname} .

	if { [file exists [file join ${log_dir} ${email}.log]] } {
		set size "[::amsn::sizeconvert [file size "[file join ${log_dir} ${email}.log]"]]o"
	} else {
		set size "0Ko"
	}

	wm title $wname "[trans history] (${email} - $size)"
      	wm geometry $wname 600x400

	frame $wname.top
	#No ugly blue frame on Mac OS X, system already put a border around windows
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		frame $wname.blueframe
	} else {
		frame $wname.blueframe -background [::skin::getKey background1]
	}
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

	frame $wname.top.contact  -class Amsn -borderwidth 0
	combobox::combobox $wname.top.contact.list -editable true -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf
	$wname.top.contact.list list delete 0 end
	foreach contact $sortedcontact_list {
		$wname.top.contact.list list insert end $contact
	}

	#Get all the list
 	set list [$wname.top.contact.list list get 0 end]
 	#Do a search in that list to find where is exactly the email we need
	set exactMatch [lsearch -exact $list $email]
  	#Select the email in the list when we open the window with the result of the search
	$wname.top.contact.list select $exactMatch
	$wname.top.contact.list configure -command "::log::ChangeLogWin $wname $email"
	$wname.top.contact.list configure -editable false

	pack $wname.top.contact.list -side left
	pack $wname.top.contact -side left

	::log::LogsByDate $wname $email "1"

	ParseLog $wname $logvar

	button $wname.buttons.close -text "[trans close]" -command "destroy $wname"
	button $wname.buttons.save -text "[trans savetofile]" -command "::log::SaveToFile ${wname} ${email} [list ${logvar}]"
  	button $wname.buttons.clear -text "[trans clearlog]" \
				    -command "if { !\[winfo exists $wname.top.date.list\] } { \
				                    set date \".\" \
				              } else {
				                    set date \[$wname.top.date.list list get \[$wname.top.date.list curselection\]\]\
					      }
                                              if { \[::log::ClearLog $email \"\$date\"\] } { 
				                    destroy $wname
			         	      }" \
	                            


	menu ${wname}.copypaste -tearoff 0 -type normal
      	${wname}.copypaste add command -label [trans copy] -command "tk_textCopy ${wname}.blueframe.log.txt"
      	
	pack $wname.top -side top -fill x
 	pack $wname.blueframe.log.ys -side right -fill y
	pack $wname.blueframe.log.txt -side left -expand true -fill both
 	pack $wname.blueframe.log -side top -expand true -fill both -padx 4 -pady 4
	pack $wname.blueframe -side top -expand true -fill both
	pack $wname.buttons.close -padx 0 -side left
	pack $wname.buttons.save -padx 0 -side right
	pack $wname.buttons.clear -padx 0 -side right
	pack $wname.buttons -side bottom -fill x -pady 3
	bind $wname <<Escape>> "destroy $wname"
	bind ${wname}.blueframe.log.txt <<Button3>> "tk_popup ${wname}.copypaste %X %Y"
	bind ${wname} <Control-c> "tk_textCopy ${wname}.blueframe.log.txt"
	moveinscreen $wname 30
}


proc wname {email} {

	set wname [split $email "@ ."]
	set wname [join $wname "_"]
	set wname ".${wname}_hist"
	return $wname
}


proc LogsByDate {wname email init} {

	global log_dir logvar

	#If we store logs by date
	if { [::config::getKey logsbydate] == 1 } {
		#If this is the first log we view
		if {$init == 1} {
			frame $wname.top.date  -class Amsn -borderwidth 0
			combobox::combobox $wname.top.date.list -editable true -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf
		}			
		set date_list ""
		set erdate_list ""
		$wname.top.date.list list delete 0 end
		foreach date [glob -nocomplain -types f [file join ${log_dir} * ${email}.log]] {
			set date [getfilename [file dirname $date]]
			status_log "Found date $date for log of $email\n"
			if { [catch { clock scan "1 $date"}] == 0 } {
				lappend date_list  [clock scan "1 $date"]
			} else {
				lappend erdate_list $date
			}
		}
		set sorteddate_list [lsort -integer -decreasing $date_list]

		$wname.top.date.list list insert end "[trans currentdate]"
		foreach date $sorteddate_list {
			status_log "Adding date [trans [clock format $date -format "%B"]] [clock format $date -format "%Y"]\n" blue
			$wname.top.date.list list insert end "[trans [clock format $date -format "%B"]] [clock format $date -format "%Y"]"
		}
		if { $erdate_list != "" } {
			$wname.top.date.list list insert end "_ _ _ _ _"
			foreach date $erdate_list {
				status_log "Adding Erroneous date $date\n" red
				$wname.top.date.list list insert end "$date"
			}
		}

		$wname.top.date.list select 0

		$wname.top.date.list configure -command "::log::ChangeLogToDate $wname $email"
		$wname.top.date.list configure -editable false
		pack $wname.top.date.list -side right
		pack $wname.top.date -side right
	}
}


proc Fileexist {email date} {

	global logvar log_dir

	#Checks if the log exists
	if { [file exists [file join ${log_dir} $date ${email}.log]] == 1} {
		set id [open "[file join ${log_dir} $date ${email}.log]" r]
		fconfigure $id -encoding utf-8
		set logvar [read $id]
		close $id
	} else {
		set logvar "\|\"LRED[trans nologfile $email]"
  	}
}


proc ResetSave {w email} {

	global logvar

	set name [::log::wname $email]

	#Redefined the command of the button according to the new contact logging
	$w.buttons.save configure -command "::log::SaveToFile ${name} ${email} [list ${logvar}]"

}


proc ResetDelete {w email} {
	
	global logvar date

	set name [::log::wname $email]

	#Redefined the command of the button according to the new contact logging
	$w.buttons.clear configure -command	"if { !\[winfo exists $w.top.date.list\] } { \
							set date \".\" \
						} else {
							set date \[$w.top.date.list list get \[$w.top.date.list curselection\]\]\
						}
						if { \[::log::ClearLog $email \"\$date\"\] } { 
							destroy $w
						} "
}


proc ChangeLogToDate { w email widget date } {

	global log_dir logvar

	status_log "Changing log for $w to $date\n\n"

	if { $date == "[trans currentdate]" } {
		set date "."
	}
	if { $date == "_ _ _ _ _" } {
		return
	}

	::log::Fileexist $email $date

	$w.blueframe.log.txt configure -state normal
	$w.blueframe.log.txt delete 0.0 end

	::log::ResetSave $w $email


	if { [file exists [file join ${log_dir} $date ${email}.log]] } {
		set size "[::amsn::sizeconvert [file size "[file join ${log_dir} $date ${email}.log]"]]o"
	} else {
		set size "0Ko"
	}
	wm title $w "[trans history] (${email} - $size)"

	ParseLog $w $logvar

}

proc ChangeLogWin {w contact widget email} {

	global log_dir logvar date

	status_log "Switch to $email\n\n" blue

	::log::Fileexist $email "."

	$w.blueframe.log.txt configure -state normal
	$w.blueframe.log.txt delete 0.0 end
	if { [file exists [file join ${log_dir} ${email}.log]] } {
		set size "[::amsn::sizeconvert [file size "[file join ${log_dir} ${email}.log]"]]o"
	} else {
		set size "0Ko"
	}
	wm title $w "[trans history] (${email} - $size)"

	::log::LogsByDate $w $email "0"	

	::log::ResetSave $w $email
	::log::ResetDelete $w $email

	ParseLog $w $logvar

	catch {$w.top.date.list select 0}

}	


#///////////////////////////////////////////////////////////////////////////////
# ParseLog (wname logvar)
# Decodes the log file and writes to log window
#
# wname : Log window
# logvar : variable containing the whole log file (sure need to setup log file limits)

proc ParseLog { wname logvar } {

	set aidx 0

	# Set up formatting tags
	${wname}.blueframe.log.txt tag configure red -foreground red
	${wname}.blueframe.log.txt tag configure RED -foreground red
	${wname}.blueframe.log.txt tag configure gray -foreground gray
	${wname}.blueframe.log.txt tag configure GRA -foreground gray
	${wname}.blueframe.log.txt tag configure normal -foreground black
	${wname}.blueframe.log.txt tag configure NOR -foreground black
	${wname}.blueframe.log.txt tag configure italic -foreground blue
	${wname}.blueframe.log.txt tag configure ITA -foreground blue
	${wname}.blueframe.log.txt tag configure GRE -foreground darkgreen

	set nbline 0

	set loglines [split $logvar "\n"]
	set result [list]
	foreach line $loglines {
		set nbline [expr $nbline + 1]
		set aidx 0
		while {$aidx != -1} {
			# Checks if the line begins by |"L (it happens when we go to the line in the chat window).
			# If not, use the tags of the previous line
			if { $aidx == 0 & [string range $line 0 2] != "\|\"L" } {
				set bidx -1
			} else {
				# If the portion of the line begins by |"LC, there is a color information.
				# The color is indicated by the 6 fingers after it
				if {[string index $line [expr $aidx + 3]] == "C"} {
					set color [string range $line [expr $aidx + 4] [expr $aidx + 9]]
					${wname}.blueframe.log.txt tag configure C_$nbline -foreground "#$color"
					set color "C_$nbline"
					set aidx [expr $aidx + 10]
				# Else, it is the system with LNOR, LGRA...
				} else {
					set color [string range $line [expr $aidx + 3] [expr $aidx + 5]]
					set aidx [expr $aidx + 6]
				}
				set bidx [string first "\|\"L" $line $aidx]
			}
			if { [string first "\|\"L" $line] == -1 } {
				set string [string range $line 0 end]
			} elseif { $bidx != -1 } {
				set string [string range $line [expr $aidx] [expr $bidx - 1]]
			} else {
				set string [string range $line [expr $aidx] end]
			}
			lappend result $string [list $color]
			set aidx $bidx
		}
		lappend result "\n" [list $color]
	}

	if {[llength $result] > 0} {
		eval [list ${wname}.blueframe.log.txt insert end] $result
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
# color : variable containing color/style information (RED, GRA, ITA, NOR)

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

	chooseFileDialog $wname "" $w $w.filename.entry save
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
			if {[string index $logvar [expr $aidx + 3]] == "C"} {
				set aidx [expr $aidx + 10]
			} else {
				set aidx [expr $aidx + 6]
			}
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

proc ClearLog { email date } {


	status_log "ClearLog $email $date\n\n"
	if { $date == "[trans currentdate]" } {
		set date "."
	}
	if { $date == "_ _ _ _ _" } {
		return 0
	}


	set answer [::amsn::messageBox "[trans confirm]" yesno question [trans clearlog]]
	if {$answer == "yes"} {	
		global log_dir
	
		catch { file delete [file join ${log_dir} $date ${email}.log] }
	}
	return 1
}


#///////////////////////////////////////////////////////////////////////////////
# ClearAllLogs ()
# Deletes the all the log files
#

proc ClearAllLogs {} {
	
	set parent "."
	catch {set parent [focus]}
	set answer [::amsn::messageBox "[trans confirm]" yesno question [trans clearlog3] $parent]
	if {$answer == "yes"} {

		global log_dir

		catch { file delete -force ${log_dir} }
		create_dir $log_dir
	}

}

#///////////////////////////////////////////////////////////////////////////////
#Events logging

proc OpenLogEvent { } {
	StartLog eventlog
}

proc CloseLogEvent { } {
	close [LogArray eventlog get]
	LogArray eventlog unset
}
	

#Log Events
proc EventLog { txt } {
	::log::OpenLogEvent
	set fileid [LogArray eventlog get]
	catch {puts -nonewline $fileid "\|\"LGRA[timestamp] \|\"LNOR: $txt\n" }
	::log::CloseLogEvent
}

#When contacts go online
proc eventconnect {name} {
	if {[::config::getKey display_event_connect]} {
		.main.eventmenu.list list insert 0 "[clock format [clock seconds] -format "%H:%M:%S"] : $name [trans online]"
	}
	if {[::config::getKey log_event_connect]} {
		::log::EventLog "$name [trans online]"
	}
}

#When contacts go offline
proc eventdisconnect {name} {
	if {[::config::getKey display_event_disconnect]} {
		.main.eventmenu.list list insert 0 "[clock format [clock seconds] -format "%H:%M:%S"] : $name [trans offline]"
	}
	if {[::config::getKey log_event_disconnect]} {
		::log::EventLog "$name [trans offline]"
	}
}

#When a mail is received
proc eventmail { name } {
	if {[::config::getKey display_event_email]} {
		.main.eventmenu.list list insert 0 "[clock format [clock seconds] -format "%H:%M:%S"] : [trans email] $name"
		.main.eventmenu.list select 0
	}
	if {[::config::getKey log_event_email]} {
		::log::EventLog "[trans email] $name"
	}
}

#When contacts change status
proc eventstatus { name state } {
	if {[::config::getKey display_event_state]} {
		.main.eventmenu.list list insert 0 "[clock format [clock seconds] -format "%H:%M:%S"] : $name [trans $state]"
	}
	if {[::config::getKey log_event_state]} {
		::log::EventLog "$name [trans $state]"
	}
}

#Check if an event display is activated
proc checkeventdisplay { } {
	if { [::config::getKey display_event_connect] || [::config::getKey display_event_disconnect] || [::config::getKey display_event_email] || [::config::getKey display_event_state] } {
		return 1
	} else {
		return 0
	}
}

#Check if an event log is activated
proc checkeventlog { } {
	if { [::config::getKey log_event_connect] || [::config::getKey log_event_disconnect] || [::config::getKey log_event_email] || [::config::getKey log_event_state] } {
		return 1
	} else {
		return 0
	}
}

#Display/log when we connect if we display/log an event
proc eventlogin { } {
	global eventdisconnected
	if { $eventdisconnected } {
		set eventdisconnected 0
		if { [::log::checkeventdisplay] } {
			.main.eventmenu.list list insert 0 "[clock format [clock seconds] -format "%H:%M:%S"] : [trans connectedwith [::config::getKey login]]"
		}
		if { [::log::checkeventlog] } {
			::log::OpenLogEvent
			set fileid [LogArray eventlog get]
			catch {puts -nonewline $fileid "\|\"LRED\[[clock format [clock seconds] -format "%d %b %Y %T"]\] [trans connectedwith [::config::getKey login]]\n"}
			::log::CloseLogEvent
		}
	}
}

#Display/log when we disconnect if we display/log an event
proc eventlogout { } {

	global eventdisconnected

	if { [::log::checkeventdisplay] } {
		.main.eventmenu.list list insert 0 "[clock format [clock seconds] -format "%H:%M:%S"] : [trans disconnectedfrom [::config::getKey login]]"
		.main.eventmenu.list select 0
	}
	if { [::log::checkeventlog] } {
		::log::OpenLogEvent
		set fileid [LogArray eventlog get]
		puts -nonewline $fileid "\|\"LRED\[[clock format [clock seconds] -format "%d %b %Y %T"]\] [trans disconnectedfrom [::config::getKey login]]\n\n"
		::log::CloseLogEvent
	}
}


#///////////////////////////////////////////////////////////////////////////////
#Log what concerns filetransferts

proc ftlog {email txt} {

		if { [::config::getKey keep_logs] } {
			set fileid [LogArray $email get]
			if { $fileid == 0 } {
				StartLog $email
				set fileid [LogArray $email get]
				puts -nonewline $fileid "\|\"LRED\[[trans lconvstarted [clock format [clock seconds] -format "%d %b %Y %T"]]\]\n"
			}
			puts -nonewline $fileid "\|\"LGRA[timestamp]\|\"LGRE $txt\n"
		}
		
		#Postevent when filetrasfer is logged
		set evPar(email) email
		set evPar(txt) txt
		::plugins::PostEvent ft_loged evPar
}

}