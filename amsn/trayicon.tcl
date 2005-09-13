if { $initialize_amsn == 1 } {
    global statusicon mailicon systemtray_exist iconmenu ishidden

    set statusicon 0
    set mailicon 0
    set systemtray_exist 0
    set iconmenu 0
    set ishidden 0
}

proc iconify_proc {} {
	global statusicon systemtray_exist
	
	if { [OnWin] } {
		taskbar_icon_handler WM_LBUTTONDBLCLK 0 0
		return
	}

	if { [focus] == "."} {
		wm iconify .
		wm state . withdrawn
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

	if { [winfo exists .bossmode] } {
		if { $msg=="WM_LBUTTONDBLCLK" } {
			wm state .bossmode normal
			focus -force .bossmode
		}
		return
	}

	if { $msg=="WM_RBUTTONUP" } {
		#tk_popup $iconmenu $x $y

		#workaround for bug with the popup not unposting
		wm state .trayiconwin normal
		wm geometry .trayiconwin "+0+[expr 2 * [winfo screenheight .]]"
		focus -force .trayiconwin

		tk_popup $iconmenu [expr "$x + 85"] [expr "$y - 11"] [$iconmenu index end]

		#workaround for bug with the popup not unposting
		wm state .trayiconwin withdrawn
	}
	if { $msg=="WM_LBUTTONDBLCLK" } {
		if { $ishidden == 0 } {
			#wm iconify .
			if { [wm state .] == "zoomed" } {
				set ishidden 2
			} else {
				set ishidden 1
			}
			wm state . withdrawn
			#set ishidden 1
		} else {
			#wm deiconify .
			#wm state . normal
			#raise .
			if { $ishidden == 2 } {
				wm state . zoomed
			} else {
				wm state . normal
			}
			focus -force .
			set ishidden 0
		}
	}
}

proc trayicon_init {} {
	global systemtray_exist password iconmenu wintrayicon statusicon

	if { [WinDock] } {
		#added to stop creation of more than 1 icon
		if { $statusicon != 0 } {
			return
		}
		set ext "[file join utils windows winico05.dll]"
		if { [file exists $ext] != 1 } {
			msg_box "[trans needwinico2]"
			close_dock
			::config::setKey dock 0
			return
		}
		if { [catch {load $ext winico}] }	{
			::config::setKey dock 0
			close_dock
			return
		}
		set systemtray_exist 1
		set wintrayicon [winico create [::skin::GetSkinFile winicons msn.ico]]
		winico taskbar add $wintrayicon -text "[trans offline]" -callback "taskbar_icon_handler %m %x %y"
		set statusicon 1
	} else {
		set ext "[file join utils linux traydock libtray.so]"
		if { ![file exists $ext] } {
			::config::setKey dock 0
			msg_box "[trans traynotcompiled]"
			close_dock
			return
		}

		if { $systemtray_exist == 0 && [UnixDock]} {
			if { [catch {load $ext Tray}] }	{
				::config::setKey dock 0
				close_dock
				return
			}
	
			set  systemtray_exist [systemtray_exist]; #a system tray exist?
		}
	}

	#workaround for bug with the popup not unposting
	destroy .trayiconwin
	toplevel .trayiconwin -class Amsn
	wm overrideredirect .trayiconwin 1
	wm geometry .trayiconwin "+0+[expr 2 * [winfo screenheight .]]"
	wm state .trayiconwin withdrawn
	destroy .trayiconwin.immain
	set iconmenu .trayiconwin.immain

	#destroy .immain
	#set iconmenu .immain
	menu $iconmenu -tearoff 0 -type normal

	menu $iconmenu.imstatus -tearoff 0 -type normal
	$iconmenu.imstatus add command -label [trans online] -command "ChCustomState NLN"
	$iconmenu.imstatus add command -label [trans noactivity] -command "ChCustomState IDL"
	$iconmenu.imstatus add command -label [trans busy] -command "ChCustomState BSY"
	$iconmenu.imstatus add command -label [trans rightback] -command "ChCustomState BRB"
	$iconmenu.imstatus add command -label [trans away] -command "ChCustomState AWY"
	$iconmenu.imstatus add command -label [trans onphone] -command "ChCustomState PHN"
	$iconmenu.imstatus add command -label [trans gonelunch] -command "ChCustomState LUN"
	$iconmenu.imstatus add command -label [trans appearoff] -command "ChCustomState HDN"

	$iconmenu add command -label "[trans offline]" -command iconify_proc
	$iconmenu add separator
	if { [string length [::config::getKey login]] > 0 } {
	     if {$password != ""} {
	        #$iconmenu add command -label "[trans login] [::config::getKey login]" -command "::MSN::connect" -state normal
	     } else {
	     	#$iconmenu add command -label "[trans login] [::config::getKey login]" -command cmsn_draw_login -state normal
	     }
	} else {
	     #$iconmenu add command -label "[trans login]" -command "::MSN::connect" -state disabled
	}
	#$iconmenu add command -label "[trans login]..." -command cmsn_draw_login

#   	$iconmenu add command -label "[trans sendmsg]..." -command  [list ::amsn::ShowSendMsgList [trans sendmsg] ::amsn::chatUser ] -state disabled
#     	$iconmenu add command -label "[trans sendmail]..." -command [list ::amsn::ShowSendEmailList [trans sendmail] launch_mailer] -state disabled

#	$iconmenu add separator		

	$iconmenu add cascade -label "[trans mystatus]" -menu $iconmenu.imstatus -state disabled     	

	$iconmenu add separator

	$iconmenu add command -label "[trans changenick]..." -command cmsn_change_name -state disabled
	$iconmenu add checkbutton -label "[trans sound]" -onvalue 1 -offvalue 0 -variable [::config::getVar sound]	
#	$iconmenu add command -label "[trans preferences]..." -command Preferences

	$iconmenu add separator		

  	$iconmenu add command -label "[trans logout]" -command "::MSN::logout" -state disabled
	$iconmenu add command -label "[trans close]" -command "close_cleanup;exit"
	CreateStatesMenu .my_menu


   	#$iconmenu add command -label "[trans checkver]..." -command "::autoupdate::check_version"

#	$iconmenu add command -label "[trans mystatus]" -state disabled
#	$iconmenu add command -label "   [trans online]" -command "ChCustomState NLN" -state disabled
#	$iconmenu add command -label "   [trans noactivity]" -command "ChCustomState IDL" -state disabled
#	$iconmenu add command -label "   [trans busy]" -command "ChCustomState BSY" -state disabled
#	$iconmenu add command -label "   [trans rightback]" -command "ChCustomState BRB" -state disabled
#	$iconmenu add command -label "   [trans away]" -command "ChCustomState AWY" -state disabled
#	$iconmenu add command -label "   [trans onphone]" -command "ChCustomState PHN" -state disabled
#	$iconmenu add command -label "   [trans gonelunch]" -command "ChCustomState LUN" -state disabled
#	$iconmenu add command -label "   [trans appearoff]" -command "ChCustomState HDN" -state disabled


	## set icon to current status if added icon while already logged in
	if { [::MSN::myStatusIs] != "FLN" } {
		statusicon_proc [::MSN::myStatusIs]
		mailicon_proc [::hotmail::unreadMessages]
	}
}

proc statusicon_proc {status} {
	global systemtray_exist statusicon list_states iconmenu wintrayicon tcl_platform
	set cmdline ""

	if { ![WinDock] } {

		set icon .si
		if { $systemtray_exist == 1 && $statusicon == 0 && [UnixDock]} {
			set pixmap "[::skin::GetSkinFile pixmaps doffline.xpm]"
			set statusicon [newti $icon -pixmap $pixmap -tooltip offline]
			bind $icon <Button1-ButtonRelease> iconify_proc
			bind $icon <Button3-ButtonRelease> "tk_popup $iconmenu %X %Y"
		}
	}

	set my_name [::abook::getPersonal nick]
   	
	if { $systemtray_exist == 1 && $statusicon != 0 && $status == "REMOVE" } {
		if {$tcl_platform(platform) == "windows"} {
			winico taskbar delete $wintrayicon
		} else {
			remove_icon $statusicon
		}
		set statusicon 0
	} elseif {$systemtray_exist == 1 && $statusicon != 0 && ( [UnixDock] || [WinDock] ) && $status != "REMOVE"} {
		if { $status != "" } {
			if { $status == "FLN" } {
#Msg
#				$iconmenu entryconfigure 2 -state disabled
#E-mail
#				$iconmenu entryconfigure 3 -state disabled
#Status submenu
				$iconmenu entryconfigure 2 -state disabled
#Change nick
				$iconmenu entryconfigure 4 -state disabled
#Sound
#				$iconmenu entryconfigure 8 -state disabled
#Prefs
#				$iconmenu entryconfigure 9 -state disabled
#Logout
				$iconmenu entryconfigure 7 -state disabled


#				$iconmenu entryconfigure 10 -state disabled
#				$iconmenu entryconfigure 11 -state disabled
#				$iconmenu entryconfigure 12 -state disabled
#				$iconmenu entryconfigure 13 -state disabled
#				$iconmenu entryconfigure 14 -state disabled
#				$iconmenu entryconfigure 15 -state disabled
#				$iconmenu entryconfigure 16 -state disabled 
#				
#				for {set id 17} {$id <= ([StateList size] + 16) } { incr id 1 } {
#					$iconmenu entryconfigure $id -state disabled
#					if { $id == 20 } { break }
#				}

			} else {
#				$iconmenu entryconfigure 2 -state normal
#				$iconmenu entryconfigure 3 -state normal
				$iconmenu entryconfigure 2 -state normal
				$iconmenu entryconfigure 4 -state normal
				$iconmenu entryconfigure 7 -state normal
#				$iconmenu entryconfigure 9 -state normal
#				$iconmenu entryconfigure 10 -state normal
#				$iconmenu entryconfigure 11 -state normal
#				$iconmenu entryconfigure 12 -state normal
#				$iconmenu entryconfigure 13 -state normal
#				$iconmenu entryconfigure 14 -state normal
#				$iconmenu entryconfigure 15 -state normal
#				$iconmenu entryconfigure 16 -state normal
#				
#				for {set id 17} {$id <= ([StateList size] + 16) } { incr id 1 } {
#					$iconmenu entryconfigure $id -state normal
#					if { $id == 20 } { break }
#				}
				
			}
				
			switch $status {
			  "FLN" {
				set pixmap "[::skin::GetSkinFile pixmaps doffline.xpm]"
				set tooltip "[trans offline]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons offline.ico]]
				}
			  }
			
			  "NLN" {
				set pixmap "[::skin::GetSkinFile pixmaps donline.xpm]"
				set tooltip "$my_name ([::config::getKey login]): [trans online]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons online.ico]]
				}
			  }
			  
			  "IDL" {
				set pixmap "[::skin::GetSkinFile pixmaps dinactive.xpm]"
				set tooltip "$my_name ([::config::getKey login]): [trans noactivity]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons inactive.ico]]
				}
			  }
			  "BSY" {
				set pixmap "[::skin::GetSkinFile pixmaps dbusy.xpm]"
				set tooltip "$my_name ([::config::getKey login]): [trans busy]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons busy.ico]]
				}
			  }
			  "BRB" {
				set pixmap "[::skin::GetSkinFile pixmaps dbrb.xpm]"
				set tooltip "$my_name ([::config::getKey login]): [trans rightback]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons brb.ico]]
				}
			  }
			  "AWY" {
				set pixmap "[::skin::GetSkinFile pixmaps daway.xpm]"
				set tooltip "$my_name ([::config::getKey login]): [trans away]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons away.ico]]
				}
			  }
			  "PHN" {
				set pixmap "[::skin::GetSkinFile pixmaps dphone.xpm]"
				set tooltip "$my_name ([::config::getKey login]): [trans onphone]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons phone.ico]]
				}
			  }
			  "LUN" {
				set pixmap "[::skin::GetSkinFile pixmaps dlunch.xpm]"
				set tooltip "$my_name ([::config::getKey login]): [trans gonelunch]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons lunch.ico]]
				}
			  }
			  "HDN" {
				set pixmap "[::skin::GetSkinFile pixmaps dhidden.xpm]"
				set tooltip "$my_name ([::config::getKey login]): [trans appearoff]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons hidden.ico]]
				}
			  }
			  "BOSS" {   #for bossmode, only for win at the moment
				#set pixmap "[::skin::GetSkinFile pixmaps doffline.xpm]"
				set tooltip "[trans pass]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons bossmode.ico]]
				}
			  }
			  default {
				set pixmap "null"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons msn.ico]]
				}
			  }
			}

			$iconmenu entryconfigure 0 -label "[::config::getKey login]"
			if { ![WinDock] } {
				if { $pixmap != "null"} {
					configureti $statusicon -pixmap $pixmap -tooltip $tooltip
				}
			} else {
				if { ![winfo exists .bossmode] || $status == "BOSS" } {
					#skip if in bossmode and not setting to BOSS
					winico taskbar delete $wintrayicon
					set wintrayicon $trayicon
					winico taskbar add $wintrayicon -text $tooltip -callback "taskbar_icon_handler %m %x %y"
				}
			}

		}
	}
}

proc taskbar_mail_icon_handler { msg x y } {
	global password

	if { [winfo exists .bossmode] } {
		if { $msg=="WM_LBUTTONDBLCLK" } {
			wm state .bossmode normal
			focus -force .bossmode
		}
		return
	}

	if { $msg=="WM_LBUTTONUP" } {
		::hotmail::hotmail_login [::config::getKey login] $password
	}
}

proc mailicon_proc {num} {
	# Workaround for bug in the traydock-plugin - statusicon added - BEGIN
	global systemtray_exist mailicon statusicon password winmailicon tcl_platform
	# Workaround for bug in the traydock-plugin - statusicon added - END
	set icon .mi
	if {$systemtray_exist == 1 && $mailicon == 0 && ([UnixDock] || [WinDock])  && $num >0} {
		set pixmap "[::skin::GetSkinFile pixmaps unread_tray.gif]"
		if { $num == 1 } {
			set msg [trans onenewmail]
		} elseif { $num == 2 } {
			set msg [trans twonewmail 2]
		} else {
			set msg [trans newmail $num]
		}

		if { ![WinDock] } {
			set mailicon [newti $icon -pixmap $pixmap -tooltip $msg]
			bind $icon <Button-1> [list ::hotmail::hotmail_login [::config::getKey login] $password]
		} else {
			set winmailicon [winico create [::skin::GetSkinFile winicons unread.ico]]
			winico taskbar add $winmailicon -text $msg -callback "taskbar_mail_icon_handler %m %x %y"
			set mailicon 1
		}

	} elseif {$systemtray_exist == 1 && $mailicon != 0 && $num == 0} {
		if { $tcl_platform(platform) != "windows" } {
			remove_icon $mailicon
			set mailicon 0
		} else {
			winico taskbar delete $winmailicon
			set mailicon 0
		}
	} elseif {$systemtray_exist == 1 && $mailicon != 0 && ([UnixDock] || [WinDock])  && $num > 0} {
		if { $num == 1 } {
			set msg [trans onenewmail]
		} elseif { $num == 2 } {
			set msg [trans twonewmail 2]
		} else {
			set msg [trans newmail $num]
		}
		if { ![WinDock] } {
			configureti $mailicon -tooltip $msg
		} else {
			winico taskbar modify $winmailicon -text $msg
		}
	} 
}

proc remove_icon {icon} {
	global systemtray_exist
	if {$systemtray_exist == 1 && $icon != 0} {
		catch {removeti $icon}
#                destroy $icon
	}
}

proc restart_tray { } {

    puts "RESTARTING the traydock"

    statusicon_proc "REMOVE"
    statusicon_proc [::MSN::myStatusIs]
    
}
		
		
	
	
