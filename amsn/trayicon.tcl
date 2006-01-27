if { $initialize_amsn == 1 } {
    global statusicon mailicon systemtray_exist iconmenu ishidden defaultbackground

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


proc isWinicoLoaded {} {
	foreach lib [info loaded] {
		if {[lindex $lib 1] == "Winico" } {
			return 1
		}
	}
	return 0
}

# Load the needed library (platform dependent) and create the context-menu
proc trayicon_init {} {
	global systemtray_exist password iconmenu wintrayicon statusicon

	if { [WinDock] } {
		#added to stop creation of more than 1 icon
		if { $statusicon != 0 } {
			return
		}
		catch {package require Winico}
		if {![isWinicoLoaded] } {
			set ext "[file join utils windows winico05.dll]"
			if { [file exists $ext] != 1 } {
				msg_box "[trans needwinico2]"
				close_dock
				return
			}
			if { [catch {load $ext winico}] }	{
				close_dock
				return
			}
		}

		set systemtray_exist 1
		set wintrayicon [winico create [::skin::GetSkinFile winicons msn.ico]]
		#add the icon
		winico taskbar add $wintrayicon -text "[trans offline]" -callback "taskbar_icon_handler %m %x %y"
		set statusicon 1
	} else {
		if { [catch {package require libtray} res] } {
			set systemtray_exist 0
			puts "[trans traynotcompiled] : $res"
			close_dock
			return
		}

		set systemtray_exist [systemtray_exist]; #a system tray exist?
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



 #     $iconmenu add separator         
 
       $iconmenu add cascade -label "[trans mystatus]" -menu $iconmenu.imstatus -state disabled        
 
       $iconmenu add separator
 
       $iconmenu add command -label "[trans changenick]..." -command cmsn_change_name -state disabled
       $iconmenu add checkbutton -label "[trans sound]" -onvalue 1 -offvalue 0 -variable [::config::getVar sound]      
 #     $iconmenu add command -label "[trans preferences]..." -command Preferences
 
       $iconmenu add separator         
 
 #the login/logout one, defined later on (see below)
       $iconmenu add command
       $iconmenu add command -label "[trans close]" -command "exit"
       CreateStatesMenu .my_menu

       ## set icon to current status if added icon while already logged in
       if { [::MSN::myStatusIs] != "FLN" } {
               statusicon_proc [::MSN::myStatusIs]
               mailicon_proc [::hotmail::unreadMessages]
       }

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

proc trayicon_callback {imgSrc imgDst width height} {
	$imgDst copy $imgSrc
	if { [image width $imgSrc] > $width || [image height $imgSrc] > $height} {
		::picture::ResizeWithRatio $imgDst $width $height
	}
}

proc statusicon_proc {status} {
	global systemtray_exist statusicon list_states iconmenu wintrayicon tcl_platform defaultbackground
	set cmdline ""

	if { ![WinDock] } {

		set icon .si
		if { $systemtray_exist == 1 && $statusicon == 0 && [UnixDock]} {
			set pixmap "[::skin::GetSkinFile pixmaps doffline.png]"
			image create photo statustrayicon -file $pixmap
			image create photo statustrayiconres
			#add the icon
			set statusicon [newti $icon -tooltip offline -pixmap statustrayiconres -command "::trayicon_callback statustrayicon statustrayiconres"]

			bind $icon <Button1-ButtonRelease> iconify_proc
			bind $icon <Button3-ButtonRelease> "tk_popup $iconmenu %X %Y"
		}
	}

	set my_name [::abook::getPersonal MFN]
   	
	if { $systemtray_exist == 1 && $statusicon != 0 && $status == "REMOVE" } {
		if {$tcl_platform(platform) == "windows"} {
			winico taskbar delete $wintrayicon
		} else {
			remove_icon $statusicon
			destroy trayicon
		}
		set statusicon 0
	} elseif {$systemtray_exist == 1 && $statusicon != 0 && ( [UnixDock] || [WinDock] ) && $status != "REMOVE"} {
		if { $status != "" } {
			if { $status == "FLN" } {
#Status submenu
				$iconmenu entryconfigure 2 -state disabled
#Change nick
				$iconmenu entryconfigure 4 -state disabled

#Login/Logout
				$iconmenu entryconfigure 7 -label "[trans login]" -command "::MSN::connect" -state normal

			} else {

				$iconmenu entryconfigure 2 -state normal
				$iconmenu entryconfigure 4 -state normal

				$iconmenu entryconfigure 7 -label "[trans logout]" -command "::MSN::logout"

				
			}
				
			switch $status {
			  "FLN" {
				set pixmap "[::skin::GetSkinFile pixmaps doffline.png]"
				set tooltip "[trans offline]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons offline.ico]]
				}
			  }
			
			  "NLN" {
				set pixmap "[::skin::GetSkinFile pixmaps donline.png]"
				set tooltip "$my_name ([::config::getKey login]): [trans online]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons online.ico]]
				}
			  }
			  
			  "IDL" {
				set pixmap "[::skin::GetSkinFile pixmaps dinactive.png]"
				set tooltip "$my_name ([::config::getKey login]): [trans noactivity]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons inactive.ico]]
				}
			  }
			  "BSY" {
				set pixmap "[::skin::GetSkinFile pixmaps dbusy.png]"
				set tooltip "$my_name ([::config::getKey login]): [trans busy]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons busy.ico]]
				}
			  }
			  "BRB" {
				set pixmap "[::skin::GetSkinFile pixmaps dbrb.png]"
				set tooltip "$my_name ([::config::getKey login]): [trans rightback]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons brb.ico]]
				}
			  }
			  "AWY" {
				set pixmap "[::skin::GetSkinFile pixmaps daway.png]"
				set tooltip "$my_name ([::config::getKey login]): [trans away]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons away.ico]]
				}
			  }
			  "PHN" {
				set pixmap "[::skin::GetSkinFile pixmaps dphone.png]"
				set tooltip "$my_name ([::config::getKey login]): [trans onphone]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons phone.ico]]
				}
			  }
			  "LUN" {
				set pixmap "[::skin::GetSkinFile pixmaps dlunch.png]"
				set tooltip "$my_name ([::config::getKey login]): [trans gonelunch]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons lunch.ico]]
				}
			  }
			  "HDN" {
				set pixmap "[::skin::GetSkinFile pixmaps dhidden.png]"
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
			if { [WinDock] } {
				if { ![winfo exists .bossmode] || $status == "BOSS" } {
					#skip if in bossmode and not setting to BOSS
					winico taskbar delete $wintrayicon
					set wintrayicon $trayicon
					winico taskbar add $wintrayicon -text $tooltip -callback "taskbar_icon_handler %m %x %y"
				}

			} else {
				if { $pixmap != "null"} {
					configureti $statusicon -tooltip $tooltip
					image create photo statustrayicon -file $pixmap
					image create photo statustrayiconres
					#if { [image width statustrayicon] > [winfo width $icon] || [image height statustrayicon] > [winfo height $icon]} {
					#	::picture::ResizeWithRatio statustrayicon [winfo width $icon] [winfo height $icon]
					#}
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
		::hotmail::hotmail_login 
	}
}

proc mailicon_proc {num} {
	# Workaround for bug in the traydock-plugin - statusicon added - BEGIN
	global systemtray_exist mailicon statusicon password winmailicon tcl_platform mailtrayicon defaultbackground
	# Workaround for bug in the traydock-plugin - statusicon added - END

	if { [::config::getKey showmailicon] == 0 } {
		return
	}

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

		if { [WinDock] } {
			set winmailicon [winico create [::skin::GetSkinFile winicons unread.ico]]
			winico taskbar add $winmailicon -text $msg -callback "taskbar_mail_icon_handler %m %x %y"
			set mailicon 1
		} else {
			image create photo mailtrayicon -file $pixmap
			image create photo mailtrayiconres
			set mailicon [newti $icon -tooltip offline -pixmap mailtrayiconres -command "::trayicon_callback mailtrayicon mailtrayiconres"]

			bind $icon <Button-1> "::hotmail::hotmail_login"
		}

	} elseif {$systemtray_exist == 1 && $mailicon != 0 && $num == 0} {
		if { $tcl_platform(platform) != "windows" } {
			remove_icon $mailicon
			destroy mailtrayicon
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
		if { [WinDock] } {
			winico taskbar modify $winmailicon -text $msg
		} else {
			configureti $mailicon -tooltip $msg
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
		





#Begin of a clean, platform independent trayicon API that could be made a plugin, maybe a snit object
	
#TODO: tooltips, windows testing, possibility to query the names of all tray-icons available



#######################################################################
# loadTrayLib {}                                                      #
#     This procedure tries to load the trayicon library, depending    #
#     on the platform it is used on.  It returns 1 if it succeeded,   #
#     0 on failure.  Errors are printed to stdout.                    #
#     Depends on:                                                     #
#       - OnWin / OnUnix / trans                                      #
#######################################################################
proc loadTrayLib {} {
	
	if { [OnWin] } {

		# First try with the package winico (for the 0.6 version)
		catch {package require Winico}
		if {[isWinicoLoaded] } {
			return 1
		}

		#set file name of the lib
		set ext "[file join utils windows winico05.dll]"

		#if the lib is not available, print an error on the console and return
		if { ![file exists $ext] } {
			puts "[trans needwinico2]"
			return 0
		}

		#if there is a problem loading the lib, print the error on the console and return
		if { [catch {load $ext winico} errormsg] } {
			puts "$errormsg"
			return 0
		}

	} elseif { [OnUnix] } {
		#if there is a problem loading the lib, print the error on the console and return
		if { [catch {package require libtray} errormsg] } {
			puts "[trans traynotcompiled] : $errormsg"
			return 0
		}
	
		#check if a systemtray is available, ifnot, set the "lib loaded" state off so no icons will be made
		if { ![systemtray_exist] } {
			puts "[trans nosystemtray]"
			return 0
		}
		
	}

	#no errors where encountered at this point, the library should be loaded and a tray available; return 1:
	return 1	
}

#######################################################################
# addTrayIcon {name xiconpath winiconpath {tooltip ""}                #
#                                    {winactionhandler "nohandler"}}  #
#     This procedure tries to add an icon to the tray.                #
#     Vars:                                                           #
#       - name: the internal specific name of the icon (as widget)    #
#       - xiconpath: the path to the pixmap for X11 systems           #
#       - winiconpath: the path to the .ico-file for windows systems  #
#       - tooltip:  text to show when hovered by the mousepointer     #
#       - tooltip:  handler proc for communication on windows         #
#     Depends on:                                                     #
#       - loadTrayLib / OnWin / OnUnix / tray lib  /                  #
#         balloon_enter / balloon_motion / kill_balloon               #
#######################################################################
proc addTrayIcon {name xiconpath winiconpath {tooltip ""} {winactionhandler "nohandler"}} {
	if {[loadTrayLib]} {
		global defaultbackground

		if { $name == "" } { set name "trayicon" }
			
		#Windows specific code
		if { [OnWin] && $winiconpath != ""} {
			set ${name} [winico create $winiconpath]
			#add the icon
			winico taskbar add $name -text "$tooltip" -callback "$winactionhandler %m %x %y"
			return 1


		#X11/Freedesktop (linux) specific code
		} elseif { [OnUnix] && $xiconpath != ""} {
			if { [winfo exists .$name] } {
				puts "trayicon.tcl: won't add icon $name as it already exists"
			} else {
				if { [loadTrayLib] } {
					#add the icon     !! name => .name
					set name [newti .$name -pixmap [image create photo dest_$name] -command "::trayIcon_Configure [image create photo source_$name -file $xiconpath] dest_$name"]

	#TODO: balloon bindings
	#bind .$name <Motion> [list status_log "motion"]
	status_log $name
	bind $name <Enter> +[list balloon_enter %W %X %Y "Test!" [::skin::loadPixmap dbusy]]
	bind $name <Motion> +[list balloon_motion %W %X %Y "Test!" [::skin::loadPixmap dbusy]]
	bind $name <Leave> "+set Bulle(first) 0; kill_balloon"
				}
			}
			return 1
		} else {
			puts "Error creating trayicon."
			return 0
		}

	} else {
		return 0
	}
}

#######################################################################
# addTrayIcon {name }                                                 #
#     This procedure removes an existing icon from the tray.          #
#     Vars:                                                           #
#       - name: the internal specific name of the icon (as widget)    #
#     Depends on:                                                     #
#       - loadTrayLib / OnWin / OnUnix / tray lib                     #
#######################################################################
proc rmTrayIcon {name} {
	if {[loadTrayLib]} {
		#Windows specific code
		if { [OnWin] } {
			winico taskbar delete $name
		#X11/Freedesktop (linux) specific code
		} elseif { [OnUnix] } {
			if { [catch {removeti .$name} errormsg] } {
				puts "$errormsg\n"
			}
			if { [catch {destroy .$name} errormsg] } {
				puts "$errormsg\n"
			}
		}
	}
}


proc confTrayIcon {name xiconpath winiconpath {tooltip ""} {winactionhandler "nohandler"}} {
	if {[loadTrayLib]} {
		#Windows specific code
		if { [OnWin] } {
			#remove the icon
			winico taskbar delete $name
			set ${name} [winico create $winiconpath]
			#readd the icon
			winico taskbar add $name -text "$tooltip" -callback "$winactionhandler %m %x %y"			

		#X11/Freedesktop (linux) specific code
		} elseif { [OnUnix] } {
			configureti .$name
			image create photo source_$name -file $xiconpath
			image create photo dest_$name
			
			#TODO: Change tooltip
		}


	}
}


#######################################################################
# Aid procedures                                                      #
#     These are no part of the API itself                             #
#######################################################################
#Linux only aid proc:
proc trayIcon_Configure {imgSrc imgDst width height} {
	$imgDst copy $imgSrc
	if { [image width $imgSrc] > $width || [image height $imgSrc] > $height} {
		::picture::ResizeWithRatio $imgDst $width $height
	}
}
#Windows only aid proc:
proc nohandler {win x y} {
	puts "Err: No icon handler given"
}
