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
		button $w.sound1.browse -text [trans browse] -command [list fileDialog2 $w $w.sound1.entry.ent open "" ] -font sboldf
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
		pack $w.command1.entry -side left -expand true -fill x
		pack $w.command1 -side top -padx 10 -pady 2 -anchor w -fill x
		checkbutton $w.buttoncomm -text "[trans commandstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_oncommand) -font splainf
		Separator $w.sepcommand -orient horizontal		
		pack $w.buttoncomm -side top -anchor w -expand true -padx 30
		pack $w.sepcommand -side top -anchor w -expand true -fill x -padx 5 -pady 5
	
		frame $w.pic1
		LabelEntry $w.pic1.entry "[trans picfile]" my_alarms(${user}_pic) 30
		button $w.pic1.browse -text [trans browse] -command [list fileDialog2 $w $w.pic1.entry.ent open "" ] -font sboldf
		pack $w.pic1.entry -side left -expand true -fill x
		pack $w.pic1.browse -side left
		pack $w.pic1 -side top -padx 10 -pady 2 -anchor w -fill x
		checkbutton $w.buttonpic -text "[trans picstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_pic_st) -font splainf
		pack $w.buttonpic -side top -anchor w -expand true -padx 30
		
		if { $window == "" } {
			frame $w.b -class Degt
			button $w.b.save -text [trans ok] -command [list ::alarms::OkPressed $user $w] -font sboldf
			button $w.b.cancel -text [trans close] -command "destroy $w; unset my_alarms" -font sboldf
			button $w.b.delete -text [trans delete] -command "::alarms::DeleteAlarm $user; destroy $w" -font sboldf
			pack $w.b.save $w.b.cancel $w.b.delete -side right -padx 10
			pack $w.b -side top -padx 0 -pady 4 -anchor e -expand true -fill both
		} else {
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

		catch {file delete $my_alarms(${user}_pic)}
		::abook::setContactData $user alarms ""
		::abook::saveToDisk
		InitMyAlarms $user
		#unset my_alarms
		
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



# Function that loads all alarm settings (usernames, paths and status) from a
# config file called alarms
#TODO: REMOVE THIS IN FUTURE VERSIONS. Only kept for compatibility!!!
proc load_alarms {} {
	global HOME


	if {([file readable "[file join ${HOME} alarms]"] == 0) ||
	       ([file isfile "[file join ${HOME} alarms]"] == 0)} {
		return 1
	}
	set file_id [open "[file join ${HOME} alarms]" r]

	gets $file_id tmp_data
	if {$tmp_data != "amsn_alarm_version 1"} {	;# config version not supported!
		return 1
	}
	while {[gets $file_id tmp_data] != "-1"} {
		set var_data [split $tmp_data]
		set var_attribute [lindex $var_data 0]
		set var_value [join [lrange $var_data 1 end]]
		set alarms($var_attribute) $var_value			
	}
	close $file_id
	
	#REMOVE OLD VERSION alarms file.Not used anymore
	#file delete [file join ${HOME} alarms]
	
}



#Runs the alarm (sound and pic)
proc run_alarm {user msg} {
	global program_dir config tcl_platform alarm_win_number
	
	if { ![info exists alarm_win_number] } {
		set alarm_win_number 0
	}

	incr alarm_win_number
	set wind_name alarm_${alarm_win_number}

	set command $config(soundcommand)
	set command [string map { "$sound" "" } $command]

	#only creates popup if it is a picture alarm or its a sound alarm (non looping for windows)
	if { ([::alarms::getAlarmItem ${user} pic_st] == 1) || ([::alarms::getAlarmItem ${user} sound_st] == 1 && ($tcl_platform(platform) != "windows" || [::alarms::getAlarmItem ${user} loop] == 1) ) } {
		toplevel .${wind_name}
		wm title .${wind_name} "[trans alarm] $user"
		label .${wind_name}.txt -text "$msg"
		pack .${wind_name}.txt	
	}
	
	if { [::alarms::getAlarmItem ${user} pic_st] == 1 } {
		image create photo joanna -file [::alarms::getAlarmItem ${user} pic]
		if { ([image width joanna] < 1024) && ([image height joanna] < 768) } {
			label .${wind_name}.jojo -image joanna
			pack .${wind_name}.jojo
		}
	}

	if { [::alarms::getAlarmItem ${user} sound_st] == 1 } {
		#need different commands for windows as no kill or bash etc
		if { $tcl_platform(platform) == "windows" } {
			#Some verions of tk don't support this
			catch { wm attributes .${wind_name} -topmost 1 }
			if { [::alarms::getAlarmItem ${user} loop] == 1 } {
				global stoploopsound
				set stoploopsound 0
				button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}; set stoploopsound 1"
				pack .${wind_name}.stopmusic -padx 2
				while { $stoploopsound == 0 } {
					update
					after 100
					catch { eval exec "[regsub -all {\\} $command {\\\\}] [regsub -all {/} [::alarms::getAlarmItem ${user} sound] {\\\\}]" & } res 
					update
				}
			} else {
				#button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}"
				#pack .${wind_name}.stopmusic -padx 2
				#update
				catch { eval exec "[regsub -all {\\} $command {\\\\}] [regsub -all {/} [::alarms::getAlarmItem ${user} sound] {\\\\}]" & } res 
			}			
		} else {
			if { [::alarms::getAlarmItem ${user} loop] == 1 } {
				button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}; catch { eval exec killall jwakeup } ; catch { eval exec killall -TERM $command }"
				pack .${wind_name}.stopmusic -padx 2
				catch { eval exec ${program_dir}/jwakeup $command [::alarms::getAlarmItem ${user} sound] & } res
			} else {
				catch { eval exec $command [::alarms::getAlarmItem ${user} sound] & } res 
				button .${wind_name}.stopmusic -text [trans stopalarm] -command "catch { eval exec killall -TERM $command } res ; destroy .${wind_name}"
				pack .${wind_name}.stopmusic -padx 2
			}
		}
	} elseif { [::alarms::getAlarmItem ${user} pic_st] == 1 } {
		button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}"
		pack .${wind_name}.stopmusic -padx 2
	}
	
	if { [::alarms::getAlarmItem ${user} oncommand] == 1 } {
		string map [list "\$msg" "$msg" "\\" "\\\\" "\$" "\\\$" "\[" "\\\[" "\]" "\\\]" "\(" "\\\(" "\)" "\\\)" "\{" "\\\}" "\"" "\\\"" "\'" "\\\'" ] [::alarms::getAlarmItem ${user} command]
		catch { eval exec [::alarms::getAlarmItem ${user} command] & } res 
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
