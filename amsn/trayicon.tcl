if { $initialize_amsn == 1 } {
    global statusicon mailicon systemtray_exist iconmenu ishidden

    set statusicon 0
    set mailicon 0
    set systemtray_exist 0
    set iconmenu 0
    set ishidden 0
}

proc iconify_proc {} {
	global statusicon config systemtray_exist
	if { [focus] == "."} {
		wm iconify .
		if { $config(closingdocks) } {
		   wm state . withdrawn
		}
	} else {
		wm deiconify .
		wm state . normal
		raise .
		focus -force .
	}
	#bind $statusicon <Button-1> deiconify_proc
}

proc taskbar_icon_handler { msg x y } {
	global iconmenu ishidden
	if { $msg=="WM_RBUTTONUP" } {
		tk_popup $iconmenu $x $y
	}
	if { $msg=="WM_LBUTTONDBLCLK" } {
		if { $ishidden == 0 } {
			wm iconify .
			wm state . withdrawn
			set ishidden 1
		} else {
			wm deiconify .
			wm state . normal
			raise .
			focus -force .
			set ishidden 0
		}
	}
}

proc trayicon_init {} {
	global program_dir config systemtray_exist password iconmenu wintrayicon statusicon

  if { $config(dock) == 4 } {
	set ext "[file join $program_dir plugins winico03.dll]"
	if { [file exists $ext] != 1 } {
###need to put in translations
		msg_box "need winico03.dll in plugins directory"
		close_dock
		set config(dock) 0
		return
	}
	load $ext winico
	set systemtray_exist 1
	set wintrayicon [winico create [file join $program_dir icons winicons msn.ico]]
	winico taskbar add $wintrayicon -text "[trans offline]" -callback "taskbar_icon_handler %m %x %y"
	set statusicon 1
  } else {
	set ext "[file join $program_dir plugins traydock libtray.so]"
	if { [file exists $ext] != 1 } {
		msg_box "[trans traynotcompiled]"
		close_dock
		set config(dock) 0
		return
	}
	
	if { $systemtray_exist == 0 && $config(dock) == 3} {
		load $ext Tray
		set  systemtray_exist [systemtray_exist]; #a system tray exist?
	}
  }

	destroy .immain
	set iconmenu .immain           
#	menu .imstatus -tearoff 0 -type normal              #######     submenu in the icon menu won't work in my setup. why?
#	.imstatus add command -label [trans online] -command "ChCustomState NLN"
#	.imstatus add command -label [trans noactivity] -command "ChCustomState IDL"
#	.imstatus add command -label [trans busy] -command "ChCustomState BSY"
#	.imstatus add command -label [trans rightback] -command "ChCustomState BRB"
#	.imstatus add command -label [trans away] -command "ChCustomState AWY"
#	.imstatus add command -label [trans onphone] -command "ChCustomState PHN"
#	.imstatus add command -label [trans gonelunch] -command "ChCustomState LUN"
#	.imstatus add command -label [trans appearoff] -command "ChCustomState HDN"
#	.imstatus add separator
#	.imstatus add command -label "[trans changenick]..." -command cmsn_change_name
#	

	menu $iconmenu -tearoff 0 -type normal
	$iconmenu add command -label "[trans offline]"
	#$iconmenu add command -label "[trans offline]"
	$iconmenu add separator
	if { [string length $config(login)] > 0 } {
	     if {$password != ""} {
	        #$iconmenu add command -label "[trans login] $config(login)" -command "::MSN::connect $config(login) $password" -state normal
	     } else {
	     	#$iconmenu add command -label "[trans login] $config(login)" -command cmsn_draw_login -state normal
	     }
	} else {
	     #$iconmenu add command -label "[trans login]" -command "::MSN::connect $config(login) $password" -state disabled
	}
	#$iconmenu add command -label "[trans login]..." -command cmsn_draw_login
  	$iconmenu add command -label "[trans logout]" -command "::MSN::logout; save_alarms" -state disabled
	$iconmenu add command -label "[trans changenick]..." -command cmsn_change_name -state disabled
	$iconmenu add separator
   	$iconmenu add command -label "[trans sendmsg]..." -command  "::amsn::ChooseList \"[trans sendmsg]\" online ::amsn::chatUser 1 0" -state disabled
   	$iconmenu add command -label "[trans sendmail]..." -command "::amsn::ChooseList \"[trans sendmail]\" both \"launch_mailer\" 1 0" -state disabled
   	#$iconmenu add command -label "[trans checkver]..." -command "check_version"
	$iconmenu add separator
	$iconmenu add command -label "[trans mystatus]" -state disabled
	$iconmenu add command -label "   [trans online]" -command "ChCustomState NLN" -state disabled
	$iconmenu add command -label "   [trans noactivity]" -command "ChCustomState IDL" -state disabled
	$iconmenu add command -label "   [trans busy]" -command "ChCustomState BSY" -state disabled
	$iconmenu add command -label "   [trans rightback]" -command "ChCustomState BRB" -state disabled
	$iconmenu add command -label "   [trans away]" -command "ChCustomState AWY" -state disabled
	$iconmenu add command -label "   [trans onphone]" -command "ChCustomState PHN" -state disabled
	$iconmenu add command -label "   [trans gonelunch]" -command "ChCustomState LUN" -state disabled
	$iconmenu add command -label "   [trans appearoff]" -command "ChCustomState HDN" -state disabled
	CreateStatesMenu .my_menu
}

proc statusicon_proc {status} {
	global systemtray_exist config statusicon user_info list_states user_stat iconmenu wintrayicon tcl_platform program_dir
	set cmdline ""

	if { $config(dock) != 4 } {

		set icon .si
		if { $systemtray_exist == 1 && $statusicon == 0 && $config(dock) == 3} {
			set pixmap "[GetSkinFile pixmaps doffline.xpm]"
			set statusicon [newti $icon -pixmap $pixmap -tooltip offline]
			bind $icon <Double-Button-1> iconify_proc
			bind $icon <Button3-ButtonRelease> "tk_popup $iconmenu %X %Y"
		}
	}

	set my_name [urldecode [lindex $user_info 4]]
   	
	if { $systemtray_exist == 1 && $statusicon != 0 && $status == "REMOVE" } {
		if {$tcl_platform(platform) == "windows"} {
			winico taskbar delete $wintrayicon
		} else {
			remove_icon $statusicon
		}
		set statusicon 0
	} elseif {$systemtray_exist == 1 && $statusicon != 0 && ( $config(dock) == 3 || $config(dock) == 4 ) && $status != "REMOVE"} {
		if { $status != "" } {
			if { $status == "FLN" } {
				$iconmenu entryconfigure 2 -state disabled
				$iconmenu entryconfigure 3 -state disabled
				$iconmenu entryconfigure 5 -state disabled
				$iconmenu entryconfigure 6 -state disabled
				$iconmenu entryconfigure 8 -state disabled
				$iconmenu entryconfigure 9 -state disabled
				$iconmenu entryconfigure 10 -state disabled
				$iconmenu entryconfigure 11 -state disabled
				$iconmenu entryconfigure 12 -state disabled
				$iconmenu entryconfigure 13 -state disabled
				$iconmenu entryconfigure 14 -state disabled
				$iconmenu entryconfigure 15 -state disabled
				$iconmenu entryconfigure 16 -state disabled 
				
				for {set id 17} {$id <= ([StateList size] + 16) } { incr id 1 } {
					$iconmenu entryconfigure $id -state disabled
					if { $id == 20 } { break }
				}

			} else {
				$iconmenu entryconfigure 2 -state normal
				$iconmenu entryconfigure 3 -state normal
				$iconmenu entryconfigure 5 -state normal
				$iconmenu entryconfigure 6 -state normal
				$iconmenu entryconfigure 8 -state normal
				$iconmenu entryconfigure 9 -state normal
				$iconmenu entryconfigure 10 -state normal
				$iconmenu entryconfigure 11 -state normal
				$iconmenu entryconfigure 12 -state normal
				$iconmenu entryconfigure 13 -state normal
				$iconmenu entryconfigure 14 -state normal
				$iconmenu entryconfigure 15 -state normal
				$iconmenu entryconfigure 16 -state normal
				
				for {set id 17} {$id <= ([StateList size] + 16) } { incr id 1 } {
					$iconmenu entryconfigure $id -state normal
					if { $id == 20 } { break }
				}
				
			}
				
			switch $status {
			  "FLN" {
				set pixmap "[GetSkinFile pixmaps doffline.xpm]"
				set tooltip "[trans offline]"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons offline.ico]]
				}
			  }
			
			  "NLN" {
				set pixmap "[GetSkinFile pixmaps donline.xpm]"
				set tooltip "$my_name ($config(login)): [trans online]"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons online.ico]]
				}
			  }
			  
			  "IDL" {
				set pixmap "[GetSkinFile pixmaps dinactive.xpm]"
				set tooltip "$my_name ($config(login)): [trans noactivity]"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons inactive.ico]]
				}
			  }
			  "BSY" {
				set pixmap "[GetSkinFile pixmaps dbusy.xpm]"
				set tooltip "$my_name ($config(login)): [trans busy]"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons busy.ico]]
				}
			  }
			  "BRB" {
				set pixmap "[GetSkinFile pixmaps dbrb.xpm]"
				set tooltip "$my_name ($config(login)): [trans rightback]"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons brb.ico]]
				}
			  }
			  "AWY" {
				set pixmap "[GetSkinFile pixmaps daway.xpm]"
				set tooltip "$my_name ($config(login)): [trans away]"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons away.ico]]
				}
			  }
			  "PHN" {
				set pixmap "[GetSkinFile pixmaps dphone.xpm]"
				set tooltip "$my_name ($config(login)): [trans onphone]"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons phone.ico]]
				}
			  }
			  "LUN" {
				set pixmap "[GetSkinFile pixmaps dlunch.xpm]"
				set tooltip "$my_name ($config(login)): [trans gonelunch]"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons lunch.ico]]
				}
			  }
			  "HDN" {
				set pixmap "[GetSkinFile pixmaps dhidden.xpm]"
				set tooltip "$my_name ($config(login)): [trans appearoff]"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons hidden.ico]]
				}
			  }
			  default {
				set pixmap "null"
				if { $config(dock) == 4 } {
					set trayicon [winico create [file join $program_dir icons winicons msn.ico]]
				}
			  }
			}

			$iconmenu entryconfigure 0 -label "$config(login)"

			if { $config(dock) != 4 } {
				if { $pixmap != "null"} {
					configureti $statusicon -pixmap $pixmap -tooltip $tooltip
				}
			} else {
				winico taskbar delete $wintrayicon
				set wintrayicon $trayicon
				winico taskbar add $wintrayicon -text $tooltip -callback "taskbar_icon_handler %m %x %y"
			}

		}
	}
}

proc taskbar_mail_icon_handler { msg x y } {
	global config password
	if { $msg=="WM_LBUTTONUP" } {
		hotmail_login $config(login) $password
	}
}

proc mailicon_proc {num} {
	# Workaround for bug in the traydock-plugin - statusicon added - BEGIN
	global systemtray_exist mailicon statusicon config password winmailicon program_dir
	# Workaround for bug in the traydock-plugin - statusicon added - END
	set icon .mi
	if {$systemtray_exist == 1 && $mailicon == 0 && ($config(dock) == 3 || $config(dock) == 4)  && $num >0} {
		set pixmap "[GetSkinFile pixmaps unread.gif]"
		if { $num == 1 } {
			set msg [trans onenewmail]
		} elseif { $num == 2 } {
			set msg [trans twonewmail 2]
		} else {
			set msg [trans newmail $num]
		}

		if { $config(dock) != 4 } {
			set mailicon [newti $icon -pixmap $pixmap -tooltip $msg]
			bind $icon <Button-1> "hotmail_login $config(login) $password"
		} else {
			set winmailicon [winico create [file join $program_dir icons winicons unread.ico]]
			winico taskbar add $winmailicon -text $msg -callback "taskbar_mail_icon_handler %m %x %y"
			set mailicon 1
		}

	} elseif {$systemtray_exist == 1 && $mailicon != 0 && $num ==0} {
		if { $config(dock) != 4 } {
			remove_icon $mailicon
			set mailicon 0
			# Workaround for bug in the traydock-plugin - simply re-initialize - BEGIN
			remove_icon $statusicon
			set statusicon 0	
			init_dock
			# Workaround for bug in the traydock-plugin - simply re-initialize - END
		} else {
			winico taskbar delete $winmailicon
			set mailicon 0
		}
	} elseif {$systemtray_exist == 1 && $mailicon != 0 && ($config(dock) == 3 || $config(dock) == 4)  && $num >0} {
		if { $num == 1 } {
			set msg [trans onenewmail]
		} elseif { $num == 2 } {
			set msg [trans twonewmail 2]
		} else {
			set msg [trans newmail $num]
		}
		if { $config(dock) != 4 } {
			configureti $mailicon -tooltip $msg
		} else {
			winico taskbar modify $winmailicon -text $msg
		}
	} 
}

proc remove_icon {icon} {
	global systemtray_exist config
	if {$systemtray_exist == 1 && $icon != 0} {
		removeti $icon
#                destroy $icon
	}
}

proc restart_tray { } {
    global user_stat

    puts "RESTARTING the traydock"

    statusicon_proc "REMOVE"
    statusicon_proc "$user_stat"
    
}
		
		
	
	
