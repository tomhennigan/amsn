#!/usr/bin/wish
#########################################################
# alarm.tcl v 1.0	2002/07/21   BurgerMan
#########################################################


# Function that loads all alarm settings (usernames, paths and status) from a
# config file called alarms
proc load_alarms {} {
   global alarms HOME config alarm_win_number
 
   set alarm_win_number 0

   if {([file readable "[file join ${HOME} alarms]"] == 0) ||
       ([file isfile "[file join ${HOME}/alarms]"] == 0)} {
	return 1
   }
   set file_id [open "${HOME}/alarms" r]

   gets $file_id tmp_data
   if {$tmp_data != "amsn_alarm_version 1"} {	;# config version not supported!
      return 1
   }
   while {[gets $file_id tmp_data] != "-1"} {
      set var_data [split $tmp_data]
      set var_attribute [lindex $var_data 0]
      set var_value [lindex $var_data 1]
      set alarms($var_attribute) $var_value			
   }
   close $file_id
}

# Function that writes all alarm settings into a config file called alarms
proc save_alarms {} {
   global tcl_platform alarms HOME HOME2 config

   # Only save if current login has a profile
   if { $HOME == $HOME2 } {
	return 1
   }
   

   if { ([info exists alarms]) && ([array size alarms] != 0) } {

        if {$tcl_platform(platform) == "unix"} {
		set file_id [open "[file join ${HOME} alarms]" w 00600]
	} else {
	        set file_id [open "[file join ${HOME} alarms]" w]
	}

	puts $file_id "amsn_alarm_version 1"

	set alarms_array [array get alarms]
	set items [llength $alarms_array]
	for {set idx 0} {$idx < $items} {incr idx 1} {
		set var_attribute [lindex $alarms_array $idx]; incr idx 1
		set var_value [lindex $alarms_array $idx]
		puts $file_id "$var_attribute $var_value"
	}
	close $file_id
#	unset alarms 
   
   } else {
	if {$tcl_platform(platform) == "unix"} {
		set file_id [open "[file join ${HOME} alarms]" w 00600]
	} else {
	        set file_id [open "[file join ${HOME} alarms]" w]
	}
	puts $file_id "amsn_alarm_version 1"
	close $file_id
   }
}

#Function that displays the Alarm configuration for the given user
proc alarm_cfg { user } {
   global alarms my_alarms

   if { [ winfo exists .alarm_cfg ] } {
        return
   }

   if { [info exists alarms(${user})] } {
        set my_alarms(${user}) $alarms(${user})
	set my_alarms(${user}_sound) $alarms(${user}_sound)
	set my_alarms(${user}_sound_st) $alarms(${user}_sound_st)
	set my_alarms(${user}_pic) $alarms(${user}_pic)
	set my_alarms(${user}_pic_st) $alarms(${user}_pic_st)
	set my_alarms(${user}_loop) $alarms(${user}_loop)
	set my_alarms(${user}_onconnect) $alarms(${user}_onconnect)
	set my_alarms(${user}_onmsg) $alarms(${user}_onmsg)
	set my_alarms(${user}_onstatus) $alarms(${user}_onstatus)
	set my_alarms(${user}_ondisconnect) $alarms(${user}_ondisconnect)
   } else {
	set my_alarms(${user}) 1
	set my_alarms(${user}_sound) "[GetSkinFile sounds alarm.wav]"
	set my_alarms(${user}_sound_st) 1
	set my_alarms(${user}_pic) "[GetSkinFile pixmaps alarm.gif]"
	set my_alarms(${user}_pic_st) 1
	set my_alarms(${user}_onconnect) 1
	set my_alarms(${user}_onmsg) 0
	set my_alarms(${user}_onstatus) 0
	set my_alarms(${user}_ondisconnect) 0
   }

   toplevel .alarm_cfg
   wm title .alarm_cfg "[trans alarmpref] $user"
   wm iconname .alarm_cfg [trans alarmpref]   

   frame .alarm_cfg.sound1
   frame .alarm_cfg.sound2
   LabelEntry .alarm_cfg.sound1.entry "[trans soundfile]" my_alarms(${user}_sound) 30
   button .alarm_cfg.sound1.browse -text [trans browse] -command {fileDialog2 .alarm_cfg .alarm_cfg.sound1.entry.ent open "" } -font sboldf
   checkbutton .alarm_cfg.sound2.button -text "[trans soundstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_sound_st) -font sboldf
   checkbutton .alarm_cfg.sound2.button2 -text "[trans soundloop]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_loop) -font sboldf
   pack .alarm_cfg.sound1.entry .alarm_cfg.sound1.browse -side left
   pack .alarm_cfg.sound2.button .alarm_cfg.sound2.button2 -side left
   pack .alarm_cfg.sound1 -side top -padx 2 -pady 2
   pack .alarm_cfg.sound2 -side top -padx 2 -pady 2

   frame .alarm_cfg.pic1
   frame .alarm_cfg.pic2
   LabelEntry .alarm_cfg.pic1.entry "[trans picfile]" my_alarms(${user}_pic) 30
   button .alarm_cfg.pic1.browse -text [trans browse] -command {fileDialog2 .alarm_cfg .alarm_cfg.pic1.entry.ent open "" } -font sboldf
   checkbutton .alarm_cfg.pic2.button -text "[trans picstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_pic_st) -font sboldf
   pack .alarm_cfg.pic1.entry .alarm_cfg.pic1.browse -side left
   pack .alarm_cfg.pic2.button -side left
   pack .alarm_cfg.pic1 -side top -padx 2 -pady 2
   pack .alarm_cfg.pic2 -side top -padx 2 -pady 2

   checkbutton .alarm_cfg.alarm -text "[trans alarmstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}) -font sboldf
   checkbutton .alarm_cfg.alarmonconnect -text "[trans alarmonconnect]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_onconnect) -font sboldf
   checkbutton .alarm_cfg.alarmonmsg -text "[trans alarmonmsg]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_onmsg) -font sboldf
   checkbutton .alarm_cfg.alarmonstatus -text "[trans alarmonstatus]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_onstatus) -font sboldf
   checkbutton .alarm_cfg.alarmondisconnect -text "[trans alarmondisconnect]" -onvalue 1 -offvalue 0 -variable my_alarms(${user}_ondisconnect) -font sboldf

   pack .alarm_cfg.alarm -side top
   pack .alarm_cfg.alarmonconnect -side top
   pack .alarm_cfg.alarmonmsg -side top
   pack .alarm_cfg.alarmonstatus -side top
   pack .alarm_cfg.alarmondisconnect -side top

   frame .alarm_cfg.b -class Degt
   button .alarm_cfg.b.save -text [trans ok] -command "save_alarm_pref $user; destroy .alarm_cfg" -font sboldf
   button .alarm_cfg.b.cancel -text [trans close] -command "unset my_alarms; destroy .alarm_cfg" -font sboldf
   button .alarm_cfg.b.delete -text [trans delete] -command "delete_alarm $user; destroy .alarm_cfg" -font sboldf
   pack .alarm_cfg.b.save .alarm_cfg.b.cancel .alarm_cfg.b.delete -side left
   pack .alarm_cfg.b -side top -padx 4 -pady 4
}

#Deletes variable settings for current user.
proc delete_alarm { user} {
   global alarms my_alarms
   if { [info exists alarms(${user})] } {
	unset alarms(${user}) alarms(${user}_sound) alarms(${user}_sound_st) alarms(${user}_pic) alarms(${user}_pic_st) alarms(${user}_loop)  alarms(${user}_onconnect) alarms(${user}_onmsg) alarms(${user}_onstatus) alarms(${user}_ondisconnect)
   }
   unset my_alarms(${user}) my_alarms(${user}_sound) my_alarms(${user}_sound_st) my_alarms(${user}_pic) my_alarms(${user}_pic_st) my_alarms(${user}_loop) my_alarms(${user}_onconnect) my_alarms(${user}_onmsg) my_alarms(${user}_onstatus) my_alarms(${user}_ondisconnect)
   cmsn_draw_online
}

#Saves alarm settings for current user on OK press.
proc save_alarm_pref { user } {
   global alarms my_alarms 
   
   if { ($my_alarms(${user}_sound_st) == 1) && ([file exists "$my_alarms(${user}_sound)"] == 0) } {
	msg_box [trans invalidsound]
	return
   }

   if { ($my_alarms(${user}_pic_st) == 1) } {
	if { ([file exists "$my_alarms(${user}_pic)"] == 0) } {
		msg_box [trans invalidpic]
		return
   	} else {
		image create photo joanna -file $my_alarms(${user}_pic)
		if { ([image width joanna] > 300) && ([image height joanna] > 400) } {
	    		image delete joanna
	    		msg_box [trans invalidpicsize]
	    		return
		}
		image delete joanna
	}
   }

   set alarms(${user}) $my_alarms(${user})
   set alarms(${user}_loop) $my_alarms(${user}_loop)
   set alarms(${user}_sound_st) $my_alarms(${user}_sound_st)
   set alarms(${user}_pic_st) $my_alarms(${user}_pic_st)
   if { $my_alarms(${user}_sound) == "" } {
	set alarms(${user}_sound) "[GetSkinFile sounds alarm.wav]"
   } else {
	set alarms(${user}_sound) $my_alarms(${user}_sound)
   }
   if { $my_alarms(${user}_pic) == "" } {
	set alarms(${user}_pic) "[GetSkinFile sounds alarm.wav]"
   } else {
	set alarms(${user}_pic) $my_alarms(${user}_pic)
   }
   set alarms(${user}_onconnect) $my_alarms(${user}_onconnect)
   set alarms(${user}_onmsg) $my_alarms(${user}_onmsg)
   set alarms(${user}_onstatus) $my_alarms(${user}_onstatus)
   set alarms(${user}_ondisconnect) $my_alarms(${user}_ondisconnect)
   cmsn_draw_online

   unset my_alarms
}

#Runs the alarm (sound and pic)
proc run_alarm {user msg} {
   global alarms program_dir config alarm_win_number

   incr alarm_win_number
   set wind_name alarm_${alarm_win_number}
   
   toplevel .${wind_name}
   wm title .${wind_name} "[trans alarm] $user"
   label .${wind_name}.txt -text "$msg"
   pack .${wind_name}.txt
   if { ($alarms(${user}_pic_st) == 1) } {
	image create photo joanna -file $alarms(${user}_pic)
	if { ([image width joanna] < 500) && ([image height joanna] < 500) } {
	label .${wind_name}.jojo -image joanna
	pack .${wind_name}.jojo
	}
   }

	status_log "${wind_name}"
   if { $alarms(${user}_sound_st) == 1 } {
	if { $alarms(${user}_loop) == 1 } {
	    button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}; catch { eval exec killall jwakeup } ; catch { eval exec killall $config(soundcommand) }"
            pack .${wind_name}.stopmusic -padx 2
	    catch { eval exec ${program_dir}/jwakeup $config(soundcommand) $alarms(${user}_sound) & } res
        } else {
	    catch { eval exec $config(soundcommand) $alarms(${user}_sound) & } res 
	    button .${wind_name}.stopmusic -text [trans stopalarm] -command "catch { eval exec killall $config(soundcommand) } res ; destroy .${wind_name}"
            pack .${wind_name}.stopmusic -padx 2
  	}
   } else {
      button .${wind_name}.stopmusic -text [trans stopalarm] -command "destroy .${wind_name}"
      pack .${wind_name}.stopmusic -padx 2
   }
}

# Switches alarm setting from ON/OFF
proc switch_alarm { user icon} {
   global alarms
   if { $alarms($user) == 1 } {
        set alarms($user) 0
   } else {
        set alarms($user) 1
   }
   redraw_alarm_icon $user $icon
}

# Redraws the alarm icon for current user ONLY without redrawing full list of contacts
proc redraw_alarm_icon { user icon} {
   global pgBuddy alarms

   if { $alarms($user) == 1 } {
       $icon configure  -image bell
   } else {
       $icon configure  -image belloff
   }
}
