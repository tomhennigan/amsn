#!/usr/bin/wish
#########################################################
# alarm.tcl v 1.0	2002/07/21   BurgerMan
#########################################################


#::Alarms namespace. Everything related to alarms (alerts)
namespace eval ::alarms {

	#Returns 1 if the user has an alarm enabled
	proc isEnabled { user } {
		return [getAlarmItem $user enabled]
	}

	#Return an alarm configuration item for the given user
	proc getAlarmItem { user item } {
	
		#We convert the stored data (a list) into an array
		array set alarms [::abook::getContactData $user alarms]
		
		if { [info exists alarms($item)] } {
			return $alarms($item)
		} else {
			return ""
		}
	}
	
	proc InitMyAlarms {user} {
		global my_alarms
		
		set my_alarms(${user}_enabled) [getAlarmItem $user enabled]
		set my_alarms(${user}_sound) [getAlarmItem $user sound]
		if { $my_alarms(${user}_sound) == "" } {
			set my_alarms(${user}_sound) [GetSkinFile sounds alarm.wav]
		}
		set my_alarms(${user}_sound_st) [getAlarmItem $user sound_st]
		set my_alarms(${user}_pic) [getAlarmItem $user pic]
		if { $my_alarms(${user}_pic) == "" } {
			set my_alarms(${user}_pic) [GetSkinFile pixmaps alarm.gif]
		}
		set my_alarms(${user}_pic_st) [getAlarmItem $user pic_st]
		set my_alarms(${user}_loop) [getAlarmItem $user loop]
		set my_alarms(${user}_onconnect) [getAlarmItem $user onconnect]
		set my_alarms(${user}_onmsg) [getAlarmItem $user onmsg]
		set my_alarms(${user}_onstatus) [getAlarmItem $user onstatus]
		set my_alarms(${user}_ondisconnect) [getAlarmItem $user ondisconnect]
		set my_alarms(${user}_command) [getAlarmItem $user command]
		set my_alarms(${user}_oncommand) [getAlarmItem $user oncommand]
	
	}
	
	#Function that displays the Alarm configuration for the given user
	proc configDialog { user {window ""} } {
		global my_alarms
	
		#Create window if not "embedded" mode
		if { $window == "" } {
			set w ".alarm_cfg_[::md5::md5 $user]"
			if { [ winfo exists $w ] } {
				catch { raise $w }
				catch { focus -force $w }
				return
			}
			toplevel $w
			wm title $w "[trans alarmpref] $user"
			wm iconname $w [trans alarmpref]
		} else {
			set w $window
		}
		
		InitMyAlarms $user
	
		#If window mode, set a title
		if { $window == "" } {
			label $w.title -text "[trans alarmpref]: $user" -font bboldf
			pack $w.title -side top -padx 15 -pady 15
		}
		
		checkbutton $w.alarm -text "[trans alarmstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_enabled) -font splainf
		Separator $w.sep1 -orient horizontal
		checkbutton $w.alarmonconnect -text "[trans alarmonconnect]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_onconnect) -font splainf
		checkbutton $w.alarmonmsg -text "[trans alarmonmsg]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_onmsg) -font splainf
		checkbutton $w.alarmonstatus -text "[trans alarmonstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_onstatus) -font splainf
		checkbutton $w.alarmondisconnect -text "[trans alarmondisconnect]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_ondisconnect) -font splainf
		Separator $w.sep2 -orient horizontal
	
		pack $w.alarm -side top -anchor w -expand true -padx 30
		pack $w.sep1 -side top -anchor w -expand true -fill x -padx 5 -pady 5
		pack $w.alarmonconnect -side top -anchor w -expand true -padx 30
		pack $w.alarmonmsg -side top -anchor w -expand true -padx 30
		pack $w.alarmonstatus -side top -anchor w -expand true -padx 30
		pack $w.alarmondisconnect -side top -anchor w -expand true -padx 30
		pack $w.sep2 -side top -anchor w -expand true -fill x -padx 5 -pady 5
	
		frame $w.sound1
		LabelEntry $w.sound1.entry "[trans soundfile]" my_alarms(${user}_sound) 30
		button $w.sound1.browse -text [trans browse] -command [list chooseFileDialog "" "" $w $w.sound1.entry.ent] -font sboldf
		pack $w.sound1.entry -side left -expand true -fill x
		pack $w.sound1.browse -side left
		pack $w.sound1 -side top -padx 10 -pady 2 -anchor w -fill x
		checkbutton $w.button -text "[trans soundstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_sound_st) -font splainf
		checkbutton $w.button2 -text "[trans soundloop]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_loop) -font splainf
		Separator $w.sepsound -orient horizontal		
		pack $w.button -side top -anchor w -expand true -padx 30
		pack $w.button2 -side top -anchor w -expand true -padx 30
		pack $w.sepsound -side top -anchor w -expand true -fill x -padx 5 -pady 5
		
	
		frame $w.command1
		LabelEntry $w.command1.entry "[trans command]" my_alarms(${user}_command) 30
		menubutton $w.command1.help -font sboldf -text "<-" -menu $w.command1.help.menu
		menu $w.command1.help.menu -tearoff 0
		$w.command1.help.menu add command -label [trans nick] -command "$w.command1.entry.ent insert insert \\\$nick"
		$w.command1.help.menu add command -label [trans email] -command "$w.command1.entry.ent insert insert \\\$user"
		$w.command1.help.menu add command -label [trans msg] -command "$w.command1.entry.ent insert insert \\\$msg"
		$w.command1.help.menu add separator
		$w.command1.help.menu add command -label [trans delete] -command "$w.command1.entry.ent delete 0 end"
		
		pack $w.command1.entry -side left -expand true -fill x
		pack $w.command1.help -side left
		pack $w.command1 -side top -padx 10 -pady 2 -anchor w -fill x
		checkbutton $w.buttoncomm -text "[trans commandstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_oncommand) -font splainf
		Separator $w.sepcommand -orient horizontal		
		pack $w.buttoncomm -side top -anchor w -expand true -padx 30
		pack $w.sepcommand -side top -anchor w -expand true -fill x -padx 5 -pady 5
	
		frame $w.pic1
		LabelEntry $w.pic1.entry "[trans picfile]" my_alarms(${user}_pic) 30
		button $w.pic1.browse -text [trans browse] -command [list chooseFileDialog "" "" $w $w.pic1.entry.ent] -font sboldf
		pack $w.pic1.entry -side left -expand true -fill x
		pack $w.pic1.browse -side left
		pack $w.pic1 -side top -padx 10 -pady 2 -anchor w -fill x
		checkbutton $w.buttonpic -text "[trans picstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_pic_st) -font splainf
		pack $w.buttonpic -side top -anchor w -expand true -padx 30
		
		if { $window == "" } {
			#Window mode
			frame $w.b -class Degt
			button $w.b.save -text [trans ok] -command [list ::alarms::OkPressed $user $w] -font sboldf
			button $w.b.cancel -text [trans close] -command "destroy $w; unset my_alarms" -font sboldf
			button $w.b.delete -text [trans delete] -command "::alarms::DeleteAlarm $user; destroy $w" -font sboldf
			pack $w.b.save $w.b.cancel $w.b.delete -side right -padx 10
			pack $w.b -side top -padx 0 -pady 4 -anchor e -expand true -fill both
		} else {
			#Embedded mode
			Separator $w.sepbutton -orient horizontal		
			pack $w.sepbutton -side top -anchor w -expand true -fill x -padx 5 -pady 5
			button $w.delete -text [trans delete] -command "::alarms::DeleteAlarm $user" -font sboldf
			pack $w.delete -side top -anchor c
		
		}
	}
	
	proc OkPressed { user w} {
		if { [::alarms::SaveAlarm $user] == 0 } {
			destroy $w
		}
	}
	
	#Deletes variable settings for current user.
	proc DeleteAlarm { user } {
		global my_alarms

		#Delete file
		catch {file delete [getAlarmItem $user pic]}
		
		::abook::setContactData $user alarms ""
		::abook::saveToDisk
		InitMyAlarms $user
		
		cmsn_draw_online
	}

	#Saves alarm settings for current user on OK press.
	proc SaveAlarm { user } {
		global my_alarms HOME
	
		if { ($my_alarms(${user}_sound_st) == 1) && ([file exists "$my_alarms(${user}_sound)"] == 0) } {
			msg_box [trans invalidsound]
			return -1
		}
		
		#Check the picture file, and copy to our home directory,
		#converting it if necessary
		if { ($my_alarms(${user}_pic_st) == 1) } {
			if { ([file exists "$my_alarms(${user}_pic)"] == 0) } {
				msg_box [trans invalidpic]
				return -1
			} else {
				if { [catch {image create photo joanna -file $my_alarms(${user}_pic)}] } {
					set file [run_convert "$my_alarms(${user}_pic)" "[file join $HOME alarm_${user}.gif]"]
					if { $file == "" } {
						msg_box [trans installconvert]
						return -1
					} else {
						set my_alarms(${user}_pic) $file
					}
				} elseif { ([image width joanna] > 1024) && ([image height joanna] > 768) } {
					image delete joanna
					msg_box [trans invalidpicsize]
					return -1
				} else {
					image delete joanna					
					catch {file copy -force $my_alarms(${user}_pic) [file join $HOME alarm_${user}.gif]}
					set my_alarms(${user}_pic) [file join $HOME alarm_${user}.gif]
				}
			}
		}
	
		set alarms(enabled) $my_alarms(${user}_enabled)
		set alarms(loop) $my_alarms(${user}_loop)
		set alarms(sound_st) $my_alarms(${user}_sound_st)
		set alarms(pic_st) $my_alarms(${user}_pic_st)
		set alarms(sound) $my_alarms(${user}_sound)
		set alarms(pic) $my_alarms(${user}_pic)
		set alarms(onconnect) $my_alarms(${user}_onconnect)
		set alarms(onmsg) $my_alarms(${user}_onmsg)
		set alarms(onstatus) $my_alarms(${user}_onstatus)
		set alarms(ondisconnect) $my_alarms(${user}_ondisconnect)
		set alarms(command) $my_alarms(${user}_command)
		set alarms(oncommand) $my_alarms(${user}_oncommand)
		
		status_log "alarms: saving alarm for $user\n" blue	
		::abook::setContactData $user alarms [array get alarms]
		::abook::saveToDisk
		
		cmsn_draw_online
		unset my_alarms
		
		return 0
	}
}



#Runs the alarm (sound and pic)
proc run_alarm {user nick msg} {
	global program_dir tcl_platform alarm_win_number
	
	if { ![info exists alarm_win_number] } {
		set alarm_win_number 0
	}

	incr alarm_win_number
	set wind_name alarm_${alarm_win_number}

	if { [::alarms::getAlarmItem ${user} pic_st] == 1 || [::alarms::getAlarmItem ${user} sound_st] == 1 } {
		toplevel .${wind_name}
		set myDate [ clock format [clock seconds] -format " - %d/%m/%y at %H:%M" ]
		wm title .${wind_name} "[trans alarm] $user $myDate"	
		label .${wind_name}.txt -text "$msg"
		pack .${wind_name}.txt
	}
	
	#Create picture
	if { [::alarms::getAlarmItem ${user} pic_st] == 1 } {
		if {[file readable [::alarms::getAlarmItem ${user} pic]]} {
			image create photo joanna_$alarm_win_number -file [::alarms::getAlarmItem ${user} pic]
			if { ([image width joanna_$alarm_win_number] < 1024) && ([image height joanna_$alarm_win_number] < 768) } {
				label .${wind_name}.jojo -image joanna_$alarm_win_number
				pack .${wind_name}.jojo
			}
		}
	}

	#Play sound
	if { [::alarms::getAlarmItem ${user} sound_st] == 1 } {
	
		if { [::config::getKey usesnack] } {
		
			#Ok, we're using Snack, do it the Snack way
			snack::sound alarmsnd_${alarm_win_number} -load [::alarms::getAlarmItem ${user} sound]
			snack_play_sound alarmsnd_${alarm_win_number} [::alarms::getAlarmItem ${user} loop]
			button .${wind_name}.stopmusic -text [trans stopalarm] -command [list ::alarms::StopSnackAlarm .${wind_name} alarmsnd_${alarm_win_number}]
			wm protocol .${wind_name} WM_DELETE_WINDOW [list ::alarms::StopSnackAlarm .${wind_name} alarmsnd_${alarm_win_number}]
			pack .${wind_name}.stopmusic -padx 2
			
		} else {
		
			set sound [::alarms::getAlarmItem ${user} sound]
			#Prepare the sound command for variable substitution
			#set command [::config::getKey soundcommand]
			#set command [string map {"\[" "\\\[" "\\" "\\\\" "\$" "\\\$" "\(" "\\\(" } $command]
			#Now, let's unquote the variables we want to replace
			#set command "[string map {"\\\$sound" "\${sound}" } $command]"
			
			if { [::alarms::getAlarmItem ${user} loop] == 1 } {
			
				button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}; cancel_loop $wind_name"
				wm protocol .${wind_name} WM_DELETE_WINDOW "destroy .${wind_name}; cancel_loop $wind_name"
				pack .${wind_name}.stopmusic -padx 2
				#Delay it a bit so window users can have the window painted
				after 1000 [list play_loop $sound $wind_name]
				
			} else {
				button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}"
				wm protocol .${wind_name} WM_DELETE_WINDOW "destroy .${wind_name}"
				pack .${wind_name}.stopmusic -padx 2
				play_sound $sound 1 1
			}
			
		}
		
	} elseif { [::alarms::getAlarmItem ${user} pic_st] == 1 } {
		button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}"
		pack .${wind_name}.stopmusic -padx 2
	}
	
	#Replace variables in command
	if { [::alarms::getAlarmItem ${user} oncommand] == 1 } {
		set the_command [::alarms::getAlarmItem ${user} command]
		#By default, quote backslashes and variables
		set the_command [string map {"\[" "\\\[" "\\" "\\\\" "\$" "\\\$" "\(" "\\\(" } $the_command]
		#Now, let's unquote the variables we want to replace
		set the_command "[string map {"\\\$nick" "\${nick}" "\\\$user" "\${user}" "\\\$msg" "\${msg}"} $the_command] &"
		catch {eval exec $the_command} res
	}

	proc StopSnackAlarm {w snd} {	
		destroy $w
		$snd stop
		$snd destroy
	}
	
}

# Switches alarm setting from ON/OFF
proc switch_alarm { user icon} {
	#We get the alarms configuration. It's stored as a list, but it's converted to an array
	array set alarms [::abook::getContactData $user alarms]

	if { [info exists alarms(enabled)] && $alarms(enabled) == 1 } {
		set alarms(enabled) 0
	} else {
		set alarms(enabled) 1
	}
	
	#We set the alarms configuration. We can't store an array, so we convert it to a list
	::abook::setContactData $user alarms [array get alarms]
	redraw_alarm_icon $user $icon
}

# Redraws the alarm icon for current user ONLY without redrawing full list of contacts
proc redraw_alarm_icon { user icon } {

	if { [::alarms::getAlarmItem $user enabled] == 1 } {
		$icon configure -image bell
	} else {
		$icon configure -image belloff
	}
}

