#
#	Logging procedures
#
################################################################################

::Version::setSubversionId {$Id$}

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
			if {[catch {set fd [CheckLogDate $email]}] } {
				return
			}
			LogArray $email set $fd

			if { [::config::getKey lineflushlog] == 1 } {
				fconfigure $fd -buffering none -encoding utf-8 
			} else {
				fconfigure $fd -buffersize 1024 -encoding utf-8
			}
		}
	}


	#///////////////////////////////////////////////////////////////////////////////
	# CheckLogDate (email)
	# Opens the log file by email address, called from StartLog
	# Checks if the date the file was created is older than a month, and moves file if necessary
	#

	proc CheckLogDate {email} {
		global log_dir webcam_dir

		#status_log "Opening file\n"
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

		#status_log "stating file $log_dir/date = [array get datestat]\n"

		set months "0 January February March April May June July August September October November December"
		set month [clock format $datestat(mtime) -format "%m"]
		if { [string range $month 0 0] == "0" } {
			set month [string range $month 1 1]
		}
		set month [lindex $months $month]
		set year [clock format $datestat(mtime) -format "%Y"]

		set date "$month $year"
		
		set clockmonth [clock format [clock seconds] -format "%m"]
		if { [string range $clockmonth 0 0] == "0" } {
			set clockmonth [string range $clockmonth 1 1]
		}
		set clockmonth [lindex $months $clockmonth]
		set clockyear [clock format [clock seconds] -format "%Y"]
		
		set clock "$clockmonth $clockyear"
		

		#status_log "Found date : $date\n" red

		if {  $date != $clock } {
			status_log "Log was begun in a different month, moving logs\n" red
			
			set to $date
			set idx 0
			while {[file exists [file join ${log_dir} $to]] } {
				status_log "Directory already used.. .bug? anyways, we don't want to overwrite\n"
				set to "${date}.$idx"
				incr idx
			}
			
			set cam_to $date
			set idx 0
			while {[file exists [file join ${webcam_dir} $cam_to]] } {
				status_log "Directory already used.. .bug? anyways, we don't want to overwrite\n"
				set cam_to "${date}.$idx"
				incr idx
			}

			catch {file delete [file join ${log_dir} date]}
			
			create_dir [file join ${log_dir} $to]
			create_dir [file join ${webcam_dir} $cam_to]

			foreach file [glob -nocomplain -types f "${log_dir}/*.log"] {
				status_log "moving $file\n" blue
				if {[catch {file rename $file [file join ${log_dir} $to]} res]} {
					status_log "moving file error $res \n"
				}
			}
			
			foreach file [glob -nocomplain -types f "${webcam_dir}/*.cam"] {
				status_log "moving $file\n" blue
				if {[catch {file rename $file [file join ${webcam_dir} $cam_to]} res]} {
					status_log "moving file error $res \n"
				}
			}

			foreach file [glob -nocomplain -types f "${webcam_dir}/*.dat"] {
				status_log "moving $file\n" blue
				if {[catch {file rename $file [file join ${webcam_dir} $cam_to]} res]} {
					status_log "moving file error $res \n"
				}
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

	proc PutLog { chatid user msg {fontformat ""} {failed 0} {OIMStamp 0}} {
		if {$msg == ""} {
			return
		}
		if {$fontformat == ""} {
			set color "NOR"
		} else {
			set color "C[lindex $fontformat 2]"
		}

		if { $failed == 1 } {
			set color "RED"
			# When the message failed to deliver, we should show the deliverfail message instead of the user's nickname.
			set user [trans deliverfail]
		} 

		if {[::OIM_GUI::IsOIM $chatid] || $OIMStamp != 0 } {
			::log::WriteLog $chatid "\|\"LITA$user :\|\"L$color $msg\n" 0 $chatid $OIMStamp
		} else  {
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
	}

	
	#///////////////////////////////////////////////////////////////////////////////
	# WriteLog (email txt (conf) (userlist))
	# Writes txt to logfile of user given by email
	# Checks if a fileid for current user already exists before writing
	# conf 1 is used for conference messages

	proc WriteLog { email txt {conf 0} {user_list ""} {OIMStamp 0}} {

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
			if {$OIMStamp == 0 } {
				puts -nonewline $fileid "\|\"LGRA[::config::getKey leftdelimiter]\|\"LTIME[clock seconds] [::config::getKey rightdelimiter] $txt"
			} else {
				puts -nonewline $fileid "\|\"LGRA$OIMStamp $txt"				
			}
		} else {
			StartLog $email
			set fileid [LogArray $email get]
			if { $fileid != 0 } {
				if {[::OIM_GUI::IsOIM $email] || $OIMStamp != 0} {
					puts -nonewline $fileid "\|\"LRED\[[trans lconvstartedOIM \|\"LTIME[clock seconds] ]\]\n"
				} elseif { $conf == 0 } {
					puts -nonewline $fileid "\|\"LRED\[[trans lconvstarted \|\"LTIME[clock seconds] ]\]\n"
				} else {
					puts -nonewline $fileid "\|\"LRED\[[trans lenteredconf $email \|\"LTIME[clock seconds] ]\(${users}\) \]\n"
				}
				if {$OIMStamp == 0 } {
					puts -nonewline $fileid "\|\"LGRA[::config::getKey leftdelimiter]\|\"LTIME[clock seconds] [::config::getKey rightdelimiter] $txt"
				} else {
					puts -nonewline $fileid "\|\"LGRA$OIMStamp $txt"				
				}
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

		# Get all the contacts with logs
		set lDirs [concat [list ${log_dir}] [glob -nocomplain -types d "${log_dir}/*"]]

		set contact_list [list]
		foreach sDir $lDirs {
			foreach sLogFile [glob -tails -nocomplain -types f -directory ${sDir} "*.log"] {
				set sLogFile [ string range $sLogFile 0 [ expr { [string length $sLogFile] - 5 } ] ]
				lappend contact_list $sLogFile
			}
		}

		#Sort contacts
		set contact_list [lsort -dictionary -unique $contact_list]

		#If there is no email defined, we replace it by the first email in the dictionary order
		if {$email == ""} {
			set email [lindex $contact_list 0]
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
			set size "[::amsn::sizeconvert [file size "[file join ${log_dir} ${email}.log]"]][trans bytesymbol]"
			wm title $wname "[trans history2] (${email} - $size)"
		} else {
			wm title $wname "[trans history2] (${email})"
		}

		wm geometry $wname 600x400

		frame $wname.top
		#No ugly blue frame on Mac OS X, system already put a border around windows
		if { [OnMac] } {
			frame $wname.blueframe
		} else {
			frame $wname.blueframe -background [::skin::getKey mainwindowbg]
		}
		frame $wname.blueframe.log -borderwidth 0
		frame $wname.buttons


		::ChatWindow::rotext $wname.blueframe.log.txt -yscrollcommand "$wname.blueframe.log.ys set" -font splainf \
		    -relief flat -highlightthickness 0 -height 1 -exportselection 1 -selectborderwidth 1 \
		    -wrap word
		scrollbar $wname.blueframe.log.ys -command "$wname.blueframe.log.txt yview" -highlightthickness 0 \
		    -borderwidth 1 -elementborderwidth 2

		# Add search dialog
		searchdialog $wname.search -searchin $wname.blueframe.log.txt -title [trans find]
		$wname.search hide
		$wname.search bindwindow $wname

		if { [file exists [file join ${log_dir} ${email}.log]] == 1 } {
			set id [open "[file join ${log_dir} ${email}.log]" r]
			fconfigure $id -encoding utf-8
			set logvar [read $id]
			close $id
		} else {
			set logvar "\|\"LRED[trans nologfile $email]"
		}

		frame $wname.top.contact -borderwidth 0
		combobox::combobox $wname.top.contact.list -highlightthickness 0 -width 22
		$wname.top.contact.list list delete 0 end
		foreach contact $contact_list {
			$wname.top.contact.list list insert end $contact
		}

		#Get all the list
		set list [$wname.top.contact.list list get 0 end]
		#Do a search in that list to find where is exactly the email we need
		set exactMatch [lsearch -exact $list $email]
		#Select the email in the list when we open the window with the result of the search
		$wname.top.contact.list select $exactMatch
		$wname.top.contact.list configure -command [list ::log::ChangeLogWin $wname]
		$wname.top.contact.list configure -editable false

		pack $wname.top.contact.list -side left
		pack $wname.top.contact -side left

		::log::LogsByDate $wname $email

		ParseLog $wname $logvar

		button $wname.buttons.close -text "[trans close]" -command [list destroy $wname]
		button $wname.buttons.find -text "[trans find]" -command [list $wname.search show]
		button $wname.buttons.stats -text "[trans stats]" -command "::log::stats"
		button $wname.buttons.save -text "[trans savetofile]" -command [list ::log::SaveToFile ${wname}]
		button $wname.buttons.clear -text "[trans clearlog]"  -command [list ::log::ClearLogGUI ${wname}]
		    


		menu ${wname}.copypaste -tearoff 0 -type normal
		${wname}.copypaste add command -label [trans copy] -command [list tk_textCopy ${wname}.blueframe.log.txt]
		
		pack $wname.top -side top -fill x
		pack $wname.blueframe.log.ys -side right -fill y
		pack $wname.blueframe.log.txt -side left -expand true -fill both
		pack $wname.blueframe.log -side top -expand true -fill both -padx 4 -pady 4
		pack $wname.blueframe -side top -expand true -fill both
		pack $wname.buttons.close -padx 0 -side left
		pack $wname.buttons.stats -padx 0 -side right
		pack $wname.buttons.save -padx 0 -side right
		pack $wname.buttons.clear -padx 0 -side right
		pack $wname.buttons.find -padx 0 -side right
		pack $wname.buttons -side bottom -fill x -pady 3
		bind $wname <<Escape>> "destroy $wname"
		bind ${wname}.blueframe.log.txt <<Button3>> "tk_popup ${wname}.copypaste %X %Y"
		moveinscreen $wname 30
	}

	proc OpenCamLogWin { {email ""} } {

		global webcam_dir langenc logvar

		# Get all the contacts with saved webcam sessions
		set lDirs [concat [list ${webcam_dir}] [glob -nocomplain -types d "${webcam_dir}/*"]]

		set contact_list [list]
		foreach sDir $lDirs {
			foreach sLogFile [glob -tails -nocomplain -types f -directory ${sDir} "*.cam" "*.CAM"] {

				#it's possible that if we move the cam files in another file system and then we import them, every extensions can be uppercased. So we have to convert *.CAM in *.cam. The same for dat files.
				if {[file extension $sLogFile] eq ".CAM"} {
					set filenoext "${sDir}/"
					append filenoext [string range $sLogFile 0 end-4]
					catch { [file rename "${filenoext}.CAM" "${filenoext}.cam"]}
					catch { [file rename "${filenoext}.DAT" "${filenoext}.dat"]}
				}

				set sLogFile [ string range $sLogFile 0 [ expr { [string length $sLogFile] - 5 } ] ]
				lappend contact_list $sLogFile
			}
		}

		if { [llength $contact_list] == 0 } {
			::amsn::infoMsg "[trans nologfile [::config::getKey login]]"
			return
		}
		
		set contact_list [lsort -dictionary -unique $contact_list]

		#If there is no email defined, we replace it by the first email in the dictionary order
		if {$email == ""} {
			set email [lindex $contact_list 0]
		}
		
		set wname [::log::cam_wname $email]

		if { [catch {toplevel ${wname} -borderwidth 0 -highlightthickness 0 } res ] } {
			raise ${wname}
			focus ${wname}
			wm deiconify ${wname}
			return 0
		}
		
		wm group ${wname} .

		if { [file exists [file join ${webcam_dir} ${email}.cam]] } {
			set fsize [file size [file join ${webcam_dir} ${email}.cam]]

			set size "[::amsn::sizeconvert ${fsize}][trans bytesymbol]"
			set exists normal
		} else {
			set exists disabled
			set size "0K[trans bytesymbol]"
		}

		wm title $wname "[trans webcamhistory2] (${email} - $size)"
		
		frame $wname.top
		#No ugly blue frame on Mac OS X, system already put a border around windows
		if { [OnMac] } {
			frame $wname.blueframe
		} else {
			frame $wname.blueframe -background [::skin::getKey mainwindowbg]
		}
		frame $wname.blueframe.log -borderwidth 0
		frame $wname.buttons

		set img [image create photo ${wname}_img -w 320 -h 240]
		label $wname.blueframe.log.l -image $img

		frame $wname.top.contact -borderwidth 0
		combobox::combobox $wname.top.contact.list -editable true -highlightthickness 0 -width 22
		$wname.top.contact.list list delete 0 end
		foreach contact $contact_list {
			$wname.top.contact.list list insert end $contact
		}

		#Get all the list
		set list [$wname.top.contact.list list get 0 end]
		#Do a search in that list to find where is exactly the email we need
		set exactMatch [lsearch -exact $list $email]
		#Select the email in the list when we open the window with the result of the search
		$wname.top.contact.list select $exactMatch
		$wname.top.contact.list configure -command [list ::log::ChangeCamLogWin $wname ]
		$wname.top.contact.list configure -editable false

		pack $wname.top.contact.list -side left -expand true -fill both
		grid $wname.top.contact -row 0 -column 0 -sticky news

		::log::CamLogsByDate $wname $email 

		button $wname.buttons.play -text "[trans play]" -state $exists \
		    -command [list ::CAMGUI::Play $wname [file join ${webcam_dir} ${email}.cam]]
		
		button $wname.buttons.pause -text "[trans pause]" -command [list ::CAMGUI::Pause $wname]  -state disabled
		button $wname.buttons.stop -text "[trans stop]" -command [list ::CAMGUI::Stop $wname] -state disabled

		button $wname.buttons.save -text "[trans snapshot]" -command [list ::CAMGUI::saveToImage $wname] -state $exists
		button $wname.buttons.close -text "[trans close]" -command [list destroy $wname]

		button $wname.buttons.clear -text "[trans clearlog]" -command [list ::log::ClearCamLogGUI ${wname}]

		frame $wname.slider -borderwidth 0

		scale $wname.slider.playbackspeed -from 10 -to 1000 -resolution 1 -showvalue 1 -label "[trans playbackspeed]" -variable [::config::getVar playbackspeed] -orient horizontal

		checkbutton $wname.dynamicrate -text "[trans dynamicrate]" -variable [::config::getVar dynamic_rate]
		frame $wname.dynrate
		label $wname.dynrate.label -text "[trans currentdynrate] : " 
		label $wname.dynrate.value -textvariable ::webcam_dynamic_rate

		frame $wname.position -borderwidth 0

		#if { ![info exists ::seek_val($img)] } {
		#	set ::seek_val($img) 0
		#}

		if { ![file exists [file join ${webcam_dir} ${email}.cam]] } {
			set whole_size 0
		} else {
			set whole_size [file size [file join ${webcam_dir} ${email}.cam]]
		}
	
		scale $wname.position.slider -from 0 -to $whole_size -resolution 1 -showvalue 0 -label "[trans playbackposition]" -variable ::seek_val($img) -orient horizontal

		if { $whole_size > 0 } {
			$wname.slider.playbackspeed configure -state normal
			$wname.position.slider configure -state normal
		} else {
			$wname.slider.playbackspeed configure -state disabled
			$wname.position.slider configure -state disabled
		}

		#not using -command to avoid constantly changing while user is dragging it around
		#interp alias {} imgseek {} ::CAMGUI::Seek $wname [file join ${webcam_dir} ${email}.cam]
		bind $wname.position.slider <<Button1-Press>> "::CAMGUI::Pause $wname"
		#bind $wname.position.slider <<Button1>> {imgseek [%W get]}
		bind $wname.position.slider <<Button1>> [list ::CAMGUI::Resume $wname [file join ${webcam_dir} ${email}.cam]]

		
		pack $wname.top -side top -fill x
		pack $wname.blueframe.log.l -side left -expand true -fill both
		pack $wname.blueframe.log -side top -expand true -fill both -padx 4 -pady 4
		pack $wname.blueframe -side top -expand true -fill both
		pack $wname.buttons.play -padx 0 -side left
		pack $wname.buttons.pause -padx 0 -side left
		pack $wname.buttons.stop -padx 0 -side left
		#	pack $wname.buttons.stats -padx 0 -side right
		pack $wname.buttons.save -padx 0 -side right
		pack $wname.buttons.clear -padx 0 -side right
		pack $wname.buttons.close -padx 0 -side right
		pack $wname.buttons -side bottom -fill x -pady 3
		pack $wname.dynrate.label -side left -fill x -pady 3
		pack $wname.dynrate.value -side left -fill x -pady 3
		pack $wname.dynrate -side bottom -fill x -pady 3
		pack $wname.dynrate -side bottom -fill x -pady 3
		pack $wname.dynamicrate -side bottom -fill x -pady 3
		pack $wname.slider.playbackspeed -fill x
		pack $wname.slider -side bottom -fill x -pady 3

		pack $wname.position.slider -fill x
		pack $wname.position -side bottom -fill x -pady 3

		bind $wname <<Escape>> "destroy $wname"
		bind $wname <Destroy> "::CAMGUI::Stop $wname; catch {image delete $img}"
		moveinscreen $wname 30
	}

	proc updateCamButtonsState {wname button} {
		set play $wname.buttons.play
		set pause $wname.buttons.pause
		set stop $wname.buttons.stop
		set save $wname.buttons.save

		if {![winfo exists $play] || ![winfo exists $pause] || ![winfo exists $stop] || ![winfo exists $save]} { return }

		switch $button {
			play {
				$play configure -state disabled
				$pause configure -state normal
				$stop configure -state normal
				$save configure -state normal
			}
			pause {
				$play configure -state normal
				$pause configure -state disabled
				$stop configure -state normal
				$save configure -state normal
			}
			stop {
				$play configure -state normal
				$pause configure -state disabled
				$stop configure -state disabled
				$save configure -state disabled
			}
			default {
			}
			
		}
	}

	proc UpdateCamMetadata {email} {
		global webcam_dir
		if { ![catch {set fd [open [file join $webcam_dir ${email}.dat] a]}] } {
			set epoch [clock seconds]
			if { [file exists [file join $webcam_dir ${email}.cam]] } {
				set fsize [file size [file join $webcam_dir ${email}.cam]]
			} else {
				set fsize 0
			}
			puts $fd "$epoch $fsize"		
			close $fd
		}
	}

	proc UpdateSessionList {wname email {date "."}} {
		global webcam_dir
		variable logged_webcam_sessions_${email}
		

		# Clear session list
		$wname.top.sessions.list configure -editable true
		$wname.top.sessions.list list delete 0 end
		# Open metadata
		set metadata [file join $webcam_dir $date ${email}.dat]
		set camfile [file join $webcam_dir $date ${email}.cam]
		if { [file exists "$metadata"] && [file exists "$camfile"]} {
			set fd [open "$metadata" r]
			# Parse session data
			array unset logged_webcam_sessions_${email}
			set i 0
			while {[gets $fd line] >= 0} {
				set logged_webcam_sessions_${email}($i,epoch) [lindex $line 0]
				set logged_webcam_sessions_${email}($i,fsize) [lindex $line 1]
				incr i
			}
			close $fd
			# Add sessions to combobox
			for {set j 0} {$j < $i} {incr j} {
				set session_date [clock format [set logged_webcam_sessions_${email}($j,epoch)]]
				if {$j < [expr {$i-1}]} {
					set fsize1 [set logged_webcam_sessions_${email}($j,fsize)]
					set fsize2 [set logged_webcam_sessions_${email}([expr {$j+1}],fsize)]
					set fsize [expr {$fsize2 - $fsize1}]
				} else {
					set fsize1 [set logged_webcam_sessions_${email}($j,fsize)]
					set fsize2 [file size "$camfile"]
					set fsize [expr {$fsize2 - $fsize1}]
				}

				set fsize "[::amsn::sizeconvert $fsize][trans bytesymbol]"
				$wname.top.sessions.list list insert end "Session [expr {$j+1}], ${session_date}, (${fsize})"
			}
		} else {
			status_log "::log::UpdateSessionList: cannot open metadata $metadata."
		}
		$wname.top.sessions.list select 0
		$wname.top.sessions.list configure -editable false
	}

	proc JumpToSession {wname widget sel} {
		global webcam_dir

		# Rebuild .cam filename
		set email [$wname.top.contact.list list get [$wname.top.contact.list curselection]]
		if { [winfo exists $wname.top.date.list] } {
			set date [$wname.top.date.list list get [$wname.top.date.list curselection]]
			if { $date == "[trans currentdate]" } { set date "." }
			if { $date == "_ _ _ _ _" } { return }
		} else {
			set date "."	
		}

		variable logged_webcam_sessions_${email}
		set idx [$wname.top.sessions.list curselection]
		if {[catch {set seekval [set logged_webcam_sessions_${email}($idx,fsize)]}]} {
			set seekval 0
		}


		set filename [file join ${webcam_dir} $date ${email}.cam]

		status_log "Seeking to $sel at $seekval"
		# after 100 to give the combobox time to close, how to do this neatly?
		::CAMGUI::Seek $wname $filename $seekval
		#if {[catch {::CAMGUI::Seek $wname $filename $seekval} res]} {
		#	status_log "Seeking failed: $res"
		#}
	}

	proc wname {email} {

		set wname [split $email "@ .:"]
		set wname [join $wname "_"]
		set wname ".${wname}_hist"
		return $wname
	}

	proc cam_wname {email} {

		set wname [split $email "@ ."]
		set wname [join $wname "_"]
		set wname ".${wname}_cam"
		return $wname
	}

	proc LogsByDate {wname email} {

		global log_dir logvar

		#If we store logs by date
		if { [::config::getKey logsbydate] == 1 } {
			#If this is the first log we view
			if {![winfo exists ${wname}.top.date]} {
				frame $wname.top.date -borderwidth 0
				combobox::combobox $wname.top.date.list -editable true -highlightthickness 0 -width 22
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

			set months "0 January February March April May June July August September October November December"

			$wname.top.date.list list insert end "[trans currentdate]"
			foreach date $sorteddate_list {
				status_log "Adding date [clock format $date -format "%B"] [clock format $date -format "%Y"]\n" blue
				set month [clock format $date -format "%m"]
				if { [string range $month 0 0] == "0" } {
					set month [string range $month 1 1]
				}
				set month "[lindex $months $month]"
				set year "[clock format $date -format "%Y"]"
				$wname.top.date.list list insert end "$month $year"
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

	proc CamLogsByDate {wname email} {

		global webcam_dir

		# Create the sessions combobox
		if {![winfo exists ${wname}.top.sessions]} {
			frame $wname.top.sessions -borderwidth 0
			combobox::combobox $wname.top.sessions.list \
			    -command "::log::JumpToSession $wname" \
			    -highlightthickness 0 -width 22
		}


		#If we store logs by date
		if { [::config::getKey logsbydate] == 1 } {
			#If this is the first log we view
			if {![winfo exists $wname.top.date]} {
				frame $wname.top.date -borderwidth 0
				combobox::combobox $wname.top.date.list -editable true -highlightthickness 0 -width 22
			}			
			set date_list ""
			set erdate_list ""
			$wname.top.date.list list delete 0 end
			foreach date [glob -nocomplain -types f [file join ${webcam_dir} * ${email}.cam]] {
				set date [getfilename [file dirname $date]]
				status_log "Found date $date for log of $email\n"
				if { [catch { clock scan "1 $date"}] == 0 } {
					lappend date_list  [clock scan "1 $date"]
				} else {
					lappend erdate_list $date
				}
			}
			set sorteddate_list [lsort -integer -decreasing $date_list]

			set months "0 January February March April May June July August September October November December"

			$wname.top.date.list list insert end "[trans currentdate]"
			foreach date $sorteddate_list {
				status_log "Adding date [clock format $date -format "%B"] [clock format $date -format "%Y"]\n" blue
				set month [clock format $date -format "%m"]
				if { [string range $month 0 0] == "0" } {
					set month [string range $month 1 1]
				}
				set month "[lindex $months $month]"
				set year "[clock format $date -format "%Y"]"
				$wname.top.date.list list insert end "$month $year"
			}
			if { $erdate_list != "" } {
				$wname.top.date.list list insert end "_ _ _ _ _"
				foreach date $erdate_list {
					status_log "Adding Erroneous date $date\n" red
					$wname.top.date.list list insert end "$date"
				}
			}

			$wname.top.date.list select 0

			$wname.top.date.list configure -command "::log::ChangeCamLogToDate $wname $email"
			$wname.top.date.list configure -editable false
			pack $wname.top.date.list -side right -expand true -fill both
			grid $wname.top.date -row 0 -column 1 -sticky news
		}

		UpdateSessionList $wname $email
		pack $wname.top.sessions.list -expand true -fill both
		grid $wname.top.sessions -row 1 -column 0 -columnspan 2 -sticky news
		grid columnconfigure $wname.top 0 -weight 1
		grid columnconfigure $wname.top 1 -weight 1
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


	proc ChangeLogToDate { w email widget date } {

		global log_dir logvar

		status_log "Changing log for $email to $date\n" blue

		if { $date == "[trans currentdate]" } {
			set date "."
		}
		if { $date == "_ _ _ _ _" } {
			return
		}

		::log::Fileexist $email $date

		$w.blueframe.log.txt rodelete 0.0 end


		if { [file exists [file join ${log_dir} $date ${email}.log]] } {
			set size "[::amsn::sizeconvert [file size "[file join ${log_dir} $date ${email}.log]"]][trans bytesymbol]"
			wm title $w "[trans history2] (${email} - $size)"
		} else {
			wm title $w "[trans history2] (${email})"
		}


		ParseLog $w $logvar

	}


	proc ChangeCamLogToDate { w email {widget ""} {date ""} } {

		global webcam_dir

		status_log "Changing log for $email to $date\n\n"
		if { $date == "" } {
			return
		}
		if { $date == "[trans currentdate]" } {
			set date "."
		}
		if { $date == "_ _ _ _ _" } {
			return
		}



		if { [file exists [file join ${webcam_dir} $date ${email}.cam]] } {
			set size "[::amsn::sizeconvert [file size "[file join ${webcam_dir} $date ${email}.cam]"]][trans bytesymbol]"
			set exists normal
		} else {
			set size "0K[trans bytesymbol]"
			set exists disabled
		}

		wm title $w "[trans webcamhistory2] (${email} - $size)"

		set img ${w}_img

		::CAMGUI::Stop $w

		if { ![file exists [file join ${webcam_dir} $date ${email}.cam]] } {
			set whole_size 0
		} else {
			set whole_size [file size [file join ${webcam_dir} $date ${email}.cam]]
		}
		$w.position.slider configure -to $whole_size
		bind $w.position.slider <ButtonRelease-1> [list ::CAMGUI::Resume $w [file join ${webcam_dir} $date ${email}.cam]]

		if { $whole_size > 0 } {
			$w.slider.playbackspeed configure -state normal
			$w.position.slider configure -state normal
		} else {
			$w.slider.playbackspeed configure -state disabled
			$w.position.slider configure -state disabled
		}

		$w.buttons.play configure -state $exists \
		    -command [list ::CAMGUI::Play $w [file join ${webcam_dir} $date ${email}.cam]]
		
		$w.buttons.pause configure -command "::CAMGUI::Pause $w"  -state disabled
		$w.buttons.stop configure -command "::CAMGUI::Stop $w" -state disabled


		UpdateSessionList $w $email $date
	}

	proc ChangeLogWin {w widget email} {

		global log_dir logvar

		status_log "Switch to $email\n" blue

		::log::Fileexist $email "."

		$w.blueframe.log.txt rodelete 0.0 end
		if { [file exists [file join ${log_dir} ${email}.log]] } {
			set size "[::amsn::sizeconvert [file size "[file join ${log_dir} ${email}.log]"]][trans bytesymbol]"
			wm title $w "[trans history2] (${email} - $size)"
		} else {
			wm title $w "[trans history2] (${email})"
		}

		::log::LogsByDate $w $email

		ParseLog $w $logvar

		catch {$w.top.date.list select 0}

	}	

	proc ChangeCamLogWin {w {widget ""} {email ""}} {

		global webcam_dir

		if { $email == "" } {
			return
		}

		status_log "(CamLoging)Switch to $email" blue

		if { [file exists [file join ${webcam_dir} ${email}.cam]] } {
			set size "[::amsn::sizeconvert [file size "[file join ${webcam_dir} ${email}.cam]"]][trans bytesymbol]"
			set exists normal
		} else {
			set exists disabled
			set size "0K[trans bytesymbol]"
		}

		::log::CamLogsByDate $w $email 	

		set img ${w}_img

		::CAMGUI::Stop $w

		if { ![file exists [file join ${webcam_dir} ${email}.cam]] } {
			set whole_size 0
		} else {
			set whole_size [file size [file join ${webcam_dir} ${email}.cam]]
		}
		$w.position.slider configure -to $whole_size
		bind $w.position.slider <ButtonRelease-1> [list ::CAMGUI::Resume $w [file join ${webcam_dir} ${email}.cam]]

		if { $whole_size > 0 } {
			$w.slider.playbackspeed configure -state normal
			$w.position.slider configure -state normal
		} else {
			$w.slider.playbackspeed configure -state disabled
			$w.position.slider configure -state disabled
		}

		$w.buttons.play configure -state $exists \
		    -command [list ::CAMGUI::Play $w [file join ${webcam_dir} ${email}.cam]]
		
		$w.buttons.pause configure -state disabled
		$w.buttons.stop configure -state disabled

		
		wm title $w "[trans webcamhistory2] (${email} - $size)"

	}



	#///////////////////////////////////////////////////////////////////////////////
	#LogDateConvert
	#takes clock seconds and returns the date and time using the user's prefered date format
	#
	#

	proc LogDateConvert { time } {
		set str ""
		if { $time != "" } {
			set part1 "[string tolower "[string index "[::config::getKey dateformat]]" 0 ]" ]"
			set part2 "[string tolower "[string index "[::config::getKey dateformat]]" 1 ]" ]"
			set part3 "[string tolower "[string index "[::config::getKey dateformat]]" 2 ]" ]"
			if { [catch {set str  "[ clock format $time -format "%$part1/%$part2/%$part3 %T"]"} ] } {
				set str ""
			}
		}
		return $str
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
		set color grey
		foreach line $loglines {
			incr nbline
			set aidx 0
			while {$aidx != -1} {
				# Checks if the line begins by |"L (it happens when we go to the line in the chat window).
				# If not, use the tags of the previous line
				if { $aidx == 0 & [string range $line 0 2] != "\|\"L" } {
					set bidx -1
				} else {
					# If the portion of the line begins by |"LC, there is a color information.
					# The color is indicated by the 6 fingers after it
					if {[string index $line [expr {$aidx + 3}]] == "C"} {
						set color [string range $line [expr {$aidx + 4}] [expr {$aidx + 9}]]
						${wname}.blueframe.log.txt tag configure C_$nbline -foreground "#$color"
						set color "C_$nbline"
						incr aidx 10
						# Else, it is the system with LNOR, LGRA...
					} else {
						if {[string range $line $aidx [expr {$aidx + 6}]] == "\|\"LTIME"  } {
							#it is a time in [clock seconds]
							incr aidx 7
							#add formated date/time stamp to the log output
							#search a non digit character since on older version, there wasn't always a space after the timestamp
							regexp -start $aidx -indices {\D} $line sidx
							set sidx [lindex $sidx 0]
							incr sidx -1
							lappend result [ LogDateConvert [string range $line $aidx $sidx  ]  ] [list $color]
							set aidx $sidx
							incr aidx 1
						} else {
							set color [string range $line [expr {$aidx + 3}] [expr {$aidx + 5}]]
							incr aidx 6
						}
					}
					set bidx [string first "\|\"L" $line $aidx]
				}
				if { [string first "\|\"L" $line] == -1 } {
					set string [string range $line 0 end]
				} elseif { $bidx != -1 } {
					set string [string range $line $aidx [expr {$bidx - 1}]]
				} else {
					set string [string range $line $aidx end]
				}
				lappend result $string [list $color]
				set aidx $bidx
			}
			lappend result "\n" [list $color]
		}

		if {[llength $result] > 0} {
			eval [list ${wname}.blueframe.log.txt roinsert end] $result
		}
		${wname}.blueframe.log.txt yview moveto 1.0
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
				${wname}.blueframe.log.txt roinsert end "$string" red
			}
			GRA {
				${wname}.blueframe.log.txt roinsert end "$string" gray
			}
			NOR {
				${wname}.blueframe.log.txt roinsert end "$string" normal
			}
			ITA {
				${wname}.blueframe.log.txt roinsert end "$string" italic
			}
		}

		# This makes rendering long log files slow, maybe should make it optional?
		#smile_subst ${wname}.blueframe.log.txt
	}

	#///////////////////////////////////////////////////////////////////////////////
	# ClearLogGUI (wname)
	#
	# wname : Log window

	proc ClearLogGUI { wname } {

		set email [$wname.top.contact.list list get [$wname.top.contact.list curselection]]
		
		if { ![winfo exists $wname.top.date.list] } {
			set date "."
		} else {
			set date [$wname.top.date.list list get [$wname.top.date.list curselection]]
		}
        if { [::log::ClearLog $email $date] } { 
			destroy $wname
		}
	}

	#///////////////////////////////////////////////////////////////////////////////
	# ClearCamLogGUI (wname)
	#
	# wname : Log window

	proc ClearCamLogGUI { wname } {

		set email [$wname.top.contact.list list get [$wname.top.contact.list curselection]]
		
		if { ![winfo exists $wname.top.date.list] } {
			set date "."
		} else {
			set date [$wname.top.date.list list get [$wname.top.date.list curselection]]
		}
        if { [::log::ClearCamLog $email $date] } { 
			destroy $wname
		}
	}

	#///////////////////////////////////////////////////////////////////////////////
	# SaveToFile (wname email logvar)
	# File name selection and calls ParseToTextFile or ParseToHTMLFile, depending on what file type we want to save.
	#
	# wname : Log window
	# logvar : variable containing the whole log file (sure need to setup log file limits)

	proc SaveToFile { wname } {
		global logvar

		set email [$wname.top.contact.list list get [$wname.top.contact.list curselection]]

		set file [chooseFileDialog "$email.html" "[trans save]" $wname "" save]

		if { $file != "" } {
			# Are we writing a HTML file?
			set ext [file extension $file]
			if {$ext == ".htm" ||
			    $ext == ".html"} {
				ParseToHTMLFile $logvar $file		
			} else {
				ParseToTextFile $logvar $file
			}
		}
	}
	
	#///////////////////////////////////////////////////////////////////////////////
	# ParseToTextFile (logvar file)
	# Decodes the log file and writes to file
	#
	# logvar : variable containing the whole log file (sure need to setup log file limits)
	# file : filaname
	proc ParseToTextFile { logvar file } {

		global langenc

		set fileid [open $file a+]
		fconfigure $fileid -encoding utf-8
		if { $fileid != 0 } {
			set aidx 0
			set str ""
			while {1} {
				if {[string index $logvar [expr {$aidx + 3}]] == "C"} {
					incr aidx 10
				} else {
					if {[string range $logvar $aidx [expr {$aidx + 6}]] == "\|\"LTIME"  } {
						#it is a time in [clock seconds]
						incr aidx 7
						#add formated date/time stamp to the log output
						#search a non digit character since on older version, there wasn't always a space after the timestamp
						regexp -start $aidx -indices {\D} $logvar sidx
						set sidx [lindex $sidx 0]
						incr sidx -1
						append str [ LogDateConvert [string range $logvar $aidx $sidx] ]
						set aidx $sidx
						incr aidx 1
					} else {
					set color [string range $logvar [expr {$aidx + 3}] [expr {$aidx + 5}]]
					incr aidx 6
					}
				}
				set bidx [string first "\|\"L" $logvar $aidx]
				if { $bidx != -1 } {
					append str [string range $logvar $aidx [expr {$bidx - 1}]]
					puts -nonewline $fileid $str
					set aidx $bidx
				} else {
					append str [string range $logvar $aidx end]
					puts -nonewline $fileid $str
					break
				}
				set str ""
			}
			close $fileid
		}
	}
	
	#///////////////////////////////////////////////////////////////////////////////
	# ParseToHTMLFile (logvar file)
	# Decodes the log file and writes to a HTML file
	#
	# logvar : variable containing the whole log file (sure need to setup log file limits)
	# file : filename
	proc ParseToHTMLFile { logvar file } {
	
		global langenc

		set fileid [open $file w+]
		fconfigure $fileid -encoding utf-8
		if { $fileid != 0 } {
		
			# Write the HTML header and stuff
			puts $fileid {<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	
	<title>aMSN Log File</title>
	<style type="text/css">
	body
	{
		font-family: Verdana, arial, sans-serif;
	}
	</style>
</head>

<body>
	}

			set nbline 0

			set loglines [split $logvar "\n"]
			set result [list]
			set color "#efefef"
			foreach line $loglines {
				incr nbline
				set aidx 0
				while {$aidx != -1} {
					# Checks if the line begins by |"L (it happens when we go to the line in the chat window).
					# If not, use the tags of the previous line
					if { $aidx == 0 & [string range $line 0 2] != "\|\"L" } {
						set bidx -1
					} else {
						# If the portion of the line begins by |"LC, there is a color information.
						# The color is indicated by the 6 fingers after it
						if {[string index $line [expr {$aidx + 3}]] == "C"} {
							set color "#[string range $line [expr {$aidx + 4}] [expr {$aidx + 9}]]"
							incr aidx 10
							# Else, it is the system with LNOR, LGRA...
						} else {
							if {[string range $line $aidx [expr {$aidx + 6}]] == "\|\"LTIME"  } {
								#it is a time in [clock seconds]
								incr aidx 7
								#add formated date/time stamp to the log output
								#search a non digit character since on older version, there wasn't always a space after the timestamp
								regexp -start $aidx -indices {\D} $line sidx
								set sidx [lindex $sidx 0]
								incr sidx -1
								puts -nonewline $fileid "<span style=\"color: $color\">[ LogDateConvert [string range $line $aidx $sidx  ]]</span>"
								set aidx $sidx
								incr aidx 1
							} else {
								switch [string range $line [expr {$aidx + 3}] [expr {$aidx + 5}]] {
									RED {
										set color "red"
									}
									GRA {
										set color "gray"
									}
									NOR {
										set color "black"
									}
									ITA {
										set color "blue"
									}
									GRE {
										set color "darkgreen"
									}
								}
								incr aidx 6
							}
						}
						set bidx [string first "\|\"L" $line $aidx]
					}
					if { [string first "\|\"L" $line] == -1 } {
						set string [string range $line 0 end]
					} elseif { $bidx != -1 } {
						set string [string range $line $aidx [expr {$bidx - 1}]]
					} else {
						set string [string range $line $aidx end]
					}
					puts -nonewline $fileid "<span style=\"color: $color\">$string</span>"
					set aidx $bidx
				}
				puts -nonewline $fileid "<br />\n\t"
				
			}
			
			puts $fileid {
</body>
</html>}
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

	proc ClearCamLog { email date } {


		status_log "ClearCamLog $email $date\n\n"
		if { $date == "[trans currentdate]" } {
			set date "."
		}
		if { $date == "_ _ _ _ _" } {
			return 0
		}


		set answer [::amsn::messageBox "[trans confirm]" yesno question [trans clearlog]]
		if {$answer == "yes"} {	
			global webcam_dir
			
			catch { file delete [file join ${webcam_dir} $date ${email}.cam] }
			catch { file delete [file join ${webcam_dir} $date ${email}.dat] }
		}
		return 1
	}

	#///////////////////////////////////////////////////////////////////////////////
	# ClearAllLogs ()
	# Deletes all the log files

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
	proc ClearAllCamLogs {} {
		
		set parent "."
		catch {set parent [focus]}
		set answer [::amsn::messageBox "[trans confirm]" yesno question [trans clearwebcamlogs] $parent]
		if {$answer == "yes"} {

			global webcam_dir

			catch { file delete -force ${webcam_dir} }
			create_dir $webcam_dir
		}

	}

	#///////////////////////////////////////////////////////////////////////////////
	#Events logging

	proc OpenLogEvent { } {
		StartLog eventlog
	}

	proc CloseLogEvent { } {
		set fileid [LogArray eventlog get]
		if {$fileid != 0 } {
			catch {close $fileid}
		}
		LogArray eventlog unset
	}
	

	#Log Events
	proc EventLog { txt } {
		::log::OpenLogEvent
		set fileid [LogArray eventlog get]
		if {$fileid != 0 } {
			catch {puts -nonewline $fileid "\|\"LGRA\|\"LTIME[clock seconds] \|\"LNOR: $txt\n" }
		}
		::log::CloseLogEvent
	}

	proc event { event name {status ""} } {

		switch $event {
			connect {
				set eventlog "$name [trans online]"
			}
			disconnect {
				set eventlog "$name [trans offline]"
			}
			email {
				set eventlog "[trans email] $name"
			}
			state {
				set eventlog "$name [trans $status]"
			}
		}

		if {[::config::getKey display_event_$event]} {
			set eventmenu "[timestamp] $eventlog"
			.main.eventmenu.list list insert 0 $eventmenu
			if { [.main.eventmenu.list list size] > 100 } {
				.main.eventmenu.list list delete 100 end
			}
			.main.eventmenu.list select 0
		}

		if {[::config::getKey log_event_$event]} {
			::log::EventLog $eventlog
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
		if { [::config::getKey log_event_connect] ||
		     [::config::getKey log_event_disconnect] ||
		     [::config::getKey log_event_email] ||
		     [::config::getKey log_event_state]|| 
		     [::config::getKey log_event_nick]|| 
		     [::config::getKey log_event_psm]} {
			return 1
		} else {
			return 0
		}
	}

	#Display/log when we connect if we display/log an event
	proc eventlogin { } {
		global eventdisconnected
		if { ![info exists eventdisconnected] || $eventdisconnected } {
			set eventdisconnected 0
			if { [::log::checkeventdisplay] } {
				.main.eventmenu.list list insert 0 "[timestamp] [trans connectedwith [::config::getKey login]]"
			}
			if { [::log::checkeventlog] } {
				::log::OpenLogEvent
				set fileid [LogArray eventlog get]
				if {$fileid != 0 } {
					catch {puts -nonewline $fileid "\|\"LRED \|\"LTIME[clock seconds] [trans connectedwith [::config::getKey login]]\n"}
				}
				::log::CloseLogEvent
			}
		}
	}

	#Display/log when we disconnect if we display/log an event
	proc eventlogout { } {

		if { [::log::checkeventdisplay] } {
			.main.eventmenu.list list insert 0 "[timestamp] : [trans disconnectedfrom [::config::getKey login]]"
			.main.eventmenu.list select 0
		}
		if { [::log::checkeventlog] } {
			::log::OpenLogEvent
			set fileid [LogArray eventlog get]
			if { $fileid != 0 } {
				catch {puts -nonewline $fileid "\|\"LRED \|\"LTIME[clock seconds] [trans disconnectedfrom [::config::getKey login]]\n\n"}
			}

			::log::CloseLogEvent
		}
	}


	# Display/log when a user changes nick if we display/log an event
	proc eventnick {email nick} {

		if {  [::config::getKey display_event_nick] } {
			.main.eventmenu.list list insert 0 "[timestamp] : [trans nickchanged $email $nick]"
			.main.eventmenu.list select 0
		}
		if { [::config::getKey log_event_nick] } {
			::log::EventLog "[trans nickchanged $email $nick]"
		}
	}

	# Display/log when a user changes psm if we display/log an event
	proc eventpsm {email psm} {

		if {  [::config::getKey display_event_psm] } {
			.main.eventmenu.list list insert 0 "[timestamp] : [trans psmchanged $email $psm]"
			.main.eventmenu.list select 0
		}
		if { [::config::getKey log_event_psm] } {
			::log::EventLog "[trans psmchanged $email $psm]"
		}
	}

	#///////////////////////////////////////////////////////////////////////////////
	# Log what concerns filetransferts

	proc ftlog {email txt} {

		if { [::config::getKey keep_logs] } {
			set fileid [LogArray $email get]
			if { $fileid == 0 } {
				StartLog $email
				set fileid [LogArray $email get]
				if { $fileid != 0 } {
					puts -nonewline $fileid "\|\"LRED\[[trans lconvstarted \|\"LTIME[clock seconds] ]\]\n"
					puts -nonewline $fileid "\|\"LGRA\|\"LTIME[clock seconds] \|\"LGRE $txt\n"
				}
			} else {
				puts -nonewline $fileid "\|\"LGRA\|\"LTIME[clock seconds] \|\"LGRE $txt\n"
			}
		}
		
		#Postevent when filetrasfer is logged
		set evPar(email) email
		set evPar(txt) txt
		::plugins::PostEvent ft_loged evPar
		
	}


	#///////////////////////////////////////////////////////////////////////////////
	# Sort the contact by the log size

	proc getcontactlogsize { email {month "."} {include_subdirs 1}} {
		global log_dir

		set file [file join ${log_dir} ${month} ${email}.log]
			
		if { [file exists $file] == 1 } {
			set size [file size $file]
		} else {
			set size 0
		}
		
		if {$include_subdirs } {
			foreach file [glob -nocomplain -types f [file join ${log_dir} * ${email}.log]] {
				incr size [file size $file]
			}
		}
			
		return $size
	}

	proc getlogsizes { {month "."} {include_subdirs 1} } {
		set contactsize [list]
		
		foreach email [::abook::getAllContacts] {
			lappend contactsize [list $email [::log::getcontactlogsize $email $month $include_subdirs]]
		}
		
		set contactsize [lsort -integer -index 1 -decreasing $contactsize]
		
		return $contactsize
		
	}

	proc sortalllog { } {
		return [::log::getlogsizes]
		
	}

	proc sortmonthlog { month } {
		return [::log::getlogsizes $month 0]
	}


	proc sortthismonthlog { } {
		return [::log::getlogsizes . 0]
	}


	proc getAllDates { } {

		if { [::config::getKey logsbydate] == 1 } {

			global log_dir
			
			set datelist [list]
			set datelisterror [list]
			
			foreach date [glob -nocomplain -types d -path "${log_dir}/" *] {
				set idx [expr {[string last "/" $date] + 1}]
				set date2 [string range $date $idx end]
				
				if { [catch {
					set date2 [clock scan "1 $date2"]
					set datelist [lappend datelist $date2]
				} ] } {
					set datelisterror [lappend datelisterror $date2]
				}
			}
			
			set datelist [lsort -integer -decreasing $datelist]

			set datelist2 [list]

			set months "0 January February March April May June July August September October November December"


			foreach date $datelist {
				set month [clock format $date -format "%m"]
				if { [string range $month 0 0] == "0" } {
					set month [string range $month 1 1]
				}
				set month "[lindex $months $month]"
				set year "[clock format $date -format "%Y"]"
				set date "$month $year"
				set datelist2 [lappend datelist2 $date]
			}
			
			set datelist2 [concat $datelist2 $datelisterror]
			
			return $datelist2

		} else {
			
			return ""
			
		}
		
	}


	#///////////////////////////////////////////////////////////////////////////////
	# Make a stats window

	proc stats { } {

		set w .stats
		
		if { [winfo exists $w] } {
			raise $w
			return
		}

		toplevel $w
		
		wm title $w "[trans stats]"
		wm geometry $w 300x390
		
		set months [::log::getAllDates]
		
		frame $w.select
		label $w.select.text -text [trans stats] -font bigfont
		combobox::combobox $w.select.list -editable true -highlightthickness 0 -width 15
		$w.select.list list delete 0 end
		$w.select.list list insert end "[trans allmonths]"
		$w.select.list select "0"

		$w.select.list list insert end "[trans thismonth]"
		
		foreach month $months {
			$w.select.list list insert end "$month"
		}
		pack configure $w.select.text -side top	
		pack configure $w.select.list -side right
		pack configure $w.select -side top -fill x -expand false

		frame $w.totalsize
		label $w.totalsize.txt -text "[trans totalsize]:"
		pack configure $w.totalsize.txt -side bottom -fill x
		pack $w.totalsize -side top -fill x -expand false

		ScrolledWindow $w.list
		ScrollableFrame $w.list.sf -constrainedwidth 1
		$w.list setwidget $w.list.sf
		pack $w.list -anchor n -side top -fill both -expand true
		set frame [$w.list.sf getframe]
		
		set contactsize [::log::sortalllog]
		
		set id 0
		set totalsize 0

		foreach contact $contactsize {
			set email [lindex $contact 0]
			set size [lindex $contact 1]
			if { $size == 0 } {
				break
			}
			incr id
			incr totalsize $size
			set wlabel "label_$id"
			label $frame.$wlabel -text "$id) $email ([::amsn::sizeconvert $size][trans bytesymbol])"
			pack configure $frame.$wlabel -side top
		}
		
		$w.select.list configure -editable false -command "::log::stats_select $id"

		$w.totalsize.txt configure -text "[trans totalsize]: [::amsn::sizeconvert $totalsize][trans bytesymbol]"

		#frame $w.button
		button $w.close -text "[trans close]" -command "destroy $w"
		pack configure $w.close -side bottom -padx 10 -pady 10
		#pack configure $w.button -side bottom -fill x -expand true
		
		bind $w <<Escape>> "destroy $w"
		moveinscreen $w 30
		
		
	}


	proc stats_select { id wname month} {

		set w .stats
		
		set frame [$w.list.sf getframe]
		
		for {set i 1} {$i<=$id} {incr i} {
			set wlabel "label_$i"
			destroy $frame.$wlabel
		}
		
		if { [$w.select.list curselection] == 0} {
			set contactsize [::log::sortalllog]
		} elseif { [$w.select.list curselection] == 1 } {
			set contactsize [::log::sortthismonthlog]
		} else {
			set contactsize [::log::sortmonthlog $month]
		}
		
		set id 0
		set totalsize 0
		
		foreach contact $contactsize {
			set email [lindex $contact 0]
			set size [lindex $contact 1]
			if { $size == 0 } {
				break
			}
			incr id
			incr totalsize $size
			set wlabel "label_$id"
			label $frame.$wlabel -text "$id) $email ([::amsn::sizeconvert $size][trans bytesymbol])"
			pack configure $frame.$wlabel -side top
		}
		
		$w.select.list configure -editable false -command "::log::stats_select $id"
		$w.totalsize.txt configure -text "[trans totalsize]: [::amsn::sizeconvert $totalsize][trans bytesymbol]"
		$w.list.sf yview moveto 0
		
		
	}




}
