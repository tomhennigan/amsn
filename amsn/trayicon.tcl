set statusicon 0
set mailicon 0
set systemtray_exist 0
set iconmenu 0

proc iconify_proc {} {
	global statusicon
		if { [focus] == "."} {
		wm iconify .
	} else {
		wm deiconify .
		raise .
		focus -force .
	}
	#bind $statusicon <Button-1> deiconify_proc
}

proc trayicon_init {} {
	global program_dir config systemtray_exist password iconmenu
	set ext "[file join $program_dir plugins traydock libtray.so]"
	if { [file exists $ext] != 1 } {
		msg_box "[trans traynotcompiled]"
		close_dock
		return
	}
	
	if { $systemtray_exist == 0 && $config(dock) == 3} {
		load $ext Tray
		set  systemtray_exist [systemtray_exist]; #a system tray exist?
	}
	set iconmenu .immain           
#	menu .imstatus -tearoff 0 -type normal              #######     submenu in the icon menu won't work in my setup. why?
#	.imstatus add command -label [trans online] -command "::MSN::changeStatus NLN"
#	.imstatus add command -label [trans noactivity] -command "::MSN::changeStatus IDL"
#	.imstatus add command -label [trans busy] -command "::MSN::changeStatus BSY"
#	.imstatus add command -label [trans rightback] -command "::MSN::changeStatus BRB"
#	.imstatus add command -label [trans away] -command "::MSN::changeStatus AWY"
#	.imstatus add command -label [trans onphone] -command "::MSN::changeStatus PHN"
#	.imstatus add command -label [trans gonelunch] -command "::MSN::changeStatus LUN"
#	.imstatus add command -label [trans appearoff] -command "::MSN::changeStatus HDN"
#	.imstatus add separator
#	.imstatus add command -label "[trans changenick]..." -command cmsn_change_name
#	

	menu $iconmenu -tearoff 0 -type normal
#	$iconmenu add cascade -label "[trans offline]" -menu .imstatus
	$iconmenu add command -label "[trans offline]"
	$iconmenu add separator
	if { [string length $config(login)] > 0 } {
	     if {$password != ""} {
	        $iconmenu add command -label "[trans login] $config(login)" -command "::MSN::connect $config(login) $password" -state normal
	     } else {
	     	$iconmenu add command -label "[trans login] $config(login)" -command cmsn_draw_login -state normal
	     }
	   } else {
	     $iconmenu add command -label "[trans login]" -command "::MSN::connect $config(login) $password" -state disabled
	}
	$iconmenu add command -label "[trans login]..." -command cmsn_draw_login
  	$iconmenu add command -label "[trans logout]" -command "::MSN::logout; save_alarms" -state disabled
	$iconmenu add command -label "[trans changenick]..." -command cmsn_change_name -state disabled
	$iconmenu add separator
   	$iconmenu add command -label "[trans sendmsg]..." -command  "::amsn::ChooseList \"[trans sendmsg]\" online ::amsn::chatUser 1 0" -state disabled
   	$iconmenu add command -label "[trans sendmail]..." -command "::amsn::ChooseList \"[trans sendmail]\" both \"launch_mailer\" 1 0" -state disabled
   	$iconmenu add command -label "[trans checkver]..." -command "check_version"
	$iconmenu add separator
	$iconmenu add command -label "[trans mystatus]" -state disabled
	$iconmenu add command -label "   [trans online]" -command "::MSN::changeStatus NLN" -state disabled
	$iconmenu add command -label "   [trans noactivity]" -command "::MSN::changeStatus IDL" -state disabled
	$iconmenu add command -label "   [trans busy]" -command "::MSN::changeStatus BSY" -state disabled
	$iconmenu add command -label "   [trans rightback]" -command "::MSN::changeStatus BRB" -state disabled
	$iconmenu add command -label "   [trans away]" -command "::MSN::changeStatus AWY" -state disabled
	$iconmenu add command -label "   [trans onphone]" -command "::MSN::changeStatus PHN" -state disabled
	$iconmenu add command -label "   [trans gonelunch]" -command "::MSN::changeStatus LUN" -state disabled
	$iconmenu add command -label "   [trans appearoff]" -command "::MSN::changeStatus HDN" -state disabled
	$iconmenu add separator
   	$iconmenu add command -label "[trans close]" -command "close_cleanup;exit"
}

proc statusicon_proc {status} {
	global systemtray_exist images_folder config statusicon user_info list_states user_stat iconmenu
	set cmdline ""
	set icon .si
	if { $systemtray_exist == 1 && $statusicon == 0 && $config(dock) == 3} {
		set pixmap "[file join $images_folder doffline.xpm]"
		set statusicon [newti $icon -pixmap $pixmap -tooltip offline]
		bind $icon <Button-1> iconify_proc
		bind $icon <Button3-ButtonRelease> "tk_popup $iconmenu %X %Y"
	}
	set my_name [urldecode [lindex $user_info 4]]
   	
	if {$systemtray_exist == 1 && $statusicon != 0 && $config(dock) == 3 && $status != "REMOVE"} {
		if { $status != "" } {
			if { $status == "FLN" } {
				set pixmap "[file join $images_folder doffline.xpm]"
				set tooltip "[trans offline]"
				$iconmenu entryconfigure 0 -label $tooltip -state disabled
				$iconmenu entryconfigure 2 -state normal
				$iconmenu entryconfigure 3 -state normal
				$iconmenu entryconfigure 4 -state disabled
				$iconmenu entryconfigure 5 -state disabled
				$iconmenu entryconfigure 7 -state disabled
				$iconmenu entryconfigure 8 -state disabled
				$iconmenu entryconfigure 12 -state disabled
				$iconmenu entryconfigure 13 -state disabled
				$iconmenu entryconfigure 14 -state disabled
				$iconmenu entryconfigure 15 -state disabled
				$iconmenu entryconfigure 16 -state disabled
				$iconmenu entryconfigure 17 -state disabled
				$iconmenu entryconfigure 18 -state disabled
				$iconmenu entryconfigure 19 -state disabled

			} elseif { $status == "NLN" } {
				set pixmap "[file join $images_folder donline.xpm]"
				set tooltip "$my_name ($config(login)): [trans online]"
				$iconmenu entryconfigure 2 -state disabled
				$iconmenu entryconfigure 3 -state disabled
				$iconmenu entryconfigure 4 -state normal  
				$iconmenu entryconfigure 5 -state normal  
				$iconmenu entryconfigure 7 -state normal
				$iconmenu entryconfigure 8 -state normal
				$iconmenu entryconfigure 12 -state normal
				$iconmenu entryconfigure 13 -state normal
				$iconmenu entryconfigure 14 -state normal
				$iconmenu entryconfigure 15 -state normal
				$iconmenu entryconfigure 16 -state normal
				$iconmenu entryconfigure 17 -state normal
				$iconmenu entryconfigure 18 -state normal
				$iconmenu entryconfigure 19 -state normal
			} elseif { $status == "IDL" } {
				set pixmap "[file join $images_folder dinactive.xpm]"
				set tooltip "$my_name ($config(login)): [trans noactivity]"
				$iconmenu entryconfigure 0 -label $tooltip
			} elseif { $status == "BSY" } {
				set pixmap "[file join $images_folder dbusy.xpm]"
				set tooltip "$my_name ($config(login)): [trans busy]"
				$iconmenu entryconfigure 0 -label $tooltip
			} elseif { $status == "BRB" } {
				set pixmap "[file join $images_folder dbrb.xpm]"
				set tooltip "$my_name ($config(login)): [trans rightback]"
				$iconmenu entryconfigure 0 -label $tooltip
			} elseif { $status == "AWY" } {
				set pixmap "[file join $images_folder daway.xpm]"
				set tooltip "$my_name ($config(login)): [trans away]"
				$iconmenu entryconfigure 0 -label $tooltip
			} elseif { $status == "PHN" } {
				set pixmap "[file join $images_folder dphone.xpm]"
				set tooltip "$my_name ($config(login)): [trans onphone]"
				$iconmenu entryconfigure 0 -label $tooltip
			} elseif { $status == "LUN" } {
				set pixmap "[file join $images_folder dlunch.xpm]"
				set tooltip "$my_name ($config(login)): [trans gonelunch]"
				$iconmenu entryconfigure 0 -label $tooltip
			} elseif { $status == "HDN" } {
				set pixmap "[file join $images_folder dhidden.xpm]"
				set tooltip "$my_name ($config(login)): [trans appearoff]"
				$iconmenu entryconfigure 0 -label $tooltip
			} else {
				set pixmap "null"
			}

			if { $pixmap != "null"} {
				configureti $statusicon -pixmap $pixmap -tooltip $tooltip
			}
		}
	} elseif {$systemtray_exist == 1 && $statusicon != 0 && $status == "REMOVE"} {
		remove_icon $statusicon
		set statusicon 0
	}
}

proc mailicon_proc {num} {
	global systemtray_exist images_folder mailicon config password
	set icon .mi
	if {$systemtray_exist == 1 && $mailicon == 0 && $config(dock) == 3  && $num >0} {
		set pixmap "[file join $images_folder unread.gif]"
		if { $num == 1 } {
			set msg [trans onenewmail]
		} elseif { $num == 2 } {
			set msg [trans twonewmail 2]
		} else {
			set msg [trans newmail $num]
		}			
		set mailicon [newti $icon -pixmap $pixmap -tooltip $msg]
		bind $icon <Button-1> "hotmail_login $config(login) $password"
	} elseif {$systemtray_exist == 1 && $mailicon != 0 && $num ==0} {
		remove_icon $mailicon
		set mailicon 0
	} elseif {$systemtray_exist == 1 && $mailicon != 0 && $config(dock) == 3  && $num >0} {
		if { $num == 1 } {
			set msg [trans onenewmail]
		} elseif { $num == 2 } {
			set msg [trans twonewmail 2]
		} else {
			set msg [trans newmail $num]
		}
		configureti $mailicon -tooltip $msg
	} 
}

proc remove_icon {icon} {
	global systemtray_exist images_folder config
	if {$systemtray_exist == 1 && $icon != 0} {
                destroy $icon
		removeti $icon
	}
}


		
		
	
	
