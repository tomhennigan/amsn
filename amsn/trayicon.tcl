
::Version::setSubversionId {$Id$}

if { $initialize_amsn == 1 } {
    global statusicon mailicon systemtray_exist iconmenu ishidden defaultbackground use_tktray

    set statusicon 0
    set mailicon 0
    set systemtray_exist 0
    set iconmenu 0
    set ishidden 0
    set use_tktray 0
}

proc iconify_proc {} {
	global statusicon systemtray_exist
	
	if { [WinDock] } {
		taskbar_icon_handler WM_LBUTTONDBLCLK 0 0
	} else {
		if { [winfo exists .bossmode] } {
			wm state .bossmode normal
			raise .bossmode
			focus -force .bossmode
			return
		}
		set focus [focus]
		if {[winfo exists $focus] } {
			set focus [winfo toplevel $focus]
		}
		if {  $focus == "." && [wm state .] != "iconic" && [wm state .] != "withdrawn"} {
			wm iconify .
			wm state . withdrawn
		} else {
			wm deiconify .
			wm state . normal
			raise .
			focus -force .
		}
	}
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
	global systemtray_exist iconmenu wintrayicon statusicon use_tktray

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

		#workaround for bug with the popup not unposting on Windows
		destroy .trayiconwin
		toplevel .trayiconwin -class Amsn
		wm geometry .trayiconwin "+0+[expr {2 * [winfo screenheight .]}]"
		wm state .trayiconwin withdrawn
		destroy .trayiconwin.immain
		set iconmenu .trayiconwin.immain

	} elseif {[UnixDock]} {
               if { [catch {package require tktray} res] } {
		       if { [catch {package require libtray} res] } {
			       set systemtray_exist 0
			       status_log "[trans traynotcompiled] : $res"
			       close_dock
			       return
		       } else {
			       set use_tktray 0
		       }
	       } else {
		       set use_tktray 1
	       }

		if {$use_tktray} {
			set systemtray_exist 1
		} else {
			set systemtray_exist [systemtray_exist]; #a system tray exist?
		}

		destroy .immain
		set iconmenu .immain
	} elseif {[MacDock]} {
		if { [catch {package require statusicon} res] } {
			set systemtray_exist 0
			status_log "Mac statusicon package not found : $res"
			close_dock
			return
		}

		set systemtray_exist 1

		destroy .immain
		set iconmenu .immain
	}


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

	$iconmenu add command -label "[trans sendmsg]..." -command [list ::amsn::ShowUserList [trans sendmsg] ::amsn::chatUser] 

       $iconmenu add separator         
 
       $iconmenu add cascade -label "[trans mystatus]" -menu $iconmenu.imstatus -state disabled        
 
       $iconmenu add separator
 
       $iconmenu add command -label "[trans changenick]..." -command cmsn_change_name -state disabled
       $iconmenu add command -label "[trans changepsm]..." -command cmsn_change_name -state disabled
       $iconmenu add checkbutton -label "[trans sound]" -onvalue 1 -offvalue 0 -variable [::config::getVar sound]
       $iconmenu add checkbutton -label "[trans shownotify]" -onvalue 1 -offvalue 0 -variable [::config::getVar shownotify]
 #     $iconmenu add command -label "[trans preferences]..." -command Preferences
 
       $iconmenu add separator         

       $iconmenu add command -label "[trans gotoinbox]" -command ::hotmail::hotmail_login
       $iconmenu add separator
 
 #the login/logout one, defined later on (see below)
       $iconmenu add command
       $iconmenu add command -label "[trans quit]" -command "exit"
       CreateStatesMenu .my_menu

       statusicon_proc [::MSN::myStatusIs]

       ## set icon to current status if added icon while already logged in
       if { [::MSN::myStatusIs] != "FLN" } {
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
		# TODO: verify if this bug is only for old tk versions and/or if it happens on older windows versions
		# Tested with Win7 and Tk 8.5.7 and it seems just fine without the workaround!
		wm state .trayiconwin normal
		wm geometry .trayiconwin "+0+[expr {2 * [winfo screenheight .]}]"
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
       $imgDst copy $imgSrc -compositingrule set
       if { [image width $imgSrc] > $width || [image height $imgSrc] > $height} {
               ::picture::ResizeWithRatio $imgDst $width $height
       }
}

proc trayicon_resize {w} {
	catch {
		set width [expr {[lindex [$w bbox] 2] - [lindex [$w bbox] 0] + 1}]
		set height [expr {[lindex [$w bbox] 2] - [lindex [$w bbox] 0] + 1}]
		puts "Resizing icon to $width x $height"
	
		set img [$w cget -image]
		if { [image width $img] != $width || [image height $img] != $height} {
			::picture::ResizeWithRatio $img $width $height
		}
	}
}

proc statusicon_callback { action } {
	global statusicon_callback_afterid

	if { [info exists statusicon_callback_afterid] } {
		catch { after cancel $statusicon_callback_afterid }
	}
	set statusicon_callback_afterid [after 250 [list statusicon_callback_delayed $action [winfo pointerx .] [winfo pointery .]]]
}

proc statusicon_callback_delayed { action x y} {
	global iconmenu

	if { $action == "ACTION" } {
		tk_popup $iconmenu $x $y
	}
	if { $action == "DOUBLE_ACTION" } {
		iconify_proc
	}
}

proc statusicon_proc {status} {
	global systemtray_exist statusicon list_states iconmenu wintrayicon defaultbackground use_tktray
	set cmdline ""

	if { [::config::getKey use_tray] == 0 && $status != "REMOVE"} { return }

	if { ![WinDock] } {

		if { $systemtray_exist == 1 && $statusicon == 0 && $status != "REMOVE" && [UnixDock]} {
			set pixmap "[::skin::GetSkinFile pixmaps doffline.png]"
			image create photo statustrayicon -file $pixmap
			set statusicon .si

			#add the icon
			if {$use_tktray} {
				tktray::icon .si -class "amsn-tray" -image statustrayicon
				after 1000 { trayicon_resize .si}
				bind $statusicon <<IconCreate>> {puts "tray created"}
				bind $statusicon <Configure> {puts "tray configured2"}
				bind $statusicon <<IconConfigure>> {puts "tray configured"; trayicon_resize .si}
				bind $statusicon <<IconDestroy>> {puts "tray destroyed"}
			} else {
				image create photo statustrayiconres
				set statusicon [newti .si -pixmap statustrayiconres -command "::trayicon_callback statustrayicon statustrayiconres"]
			}

			bind $statusicon <<Button1>> iconify_proc
			bind $statusicon <<Button3>> "tk_popup $iconmenu %X %Y"
		}
		if { $systemtray_exist == 1 && $statusicon == 0 && $status != "REMOVE" && [MacDock]} {
			set pixmap "[::skin::GetSkinFile pixmaps doffline.png]"
			#add the icon
			set statusicon [::statusicon::create statusicon_callback]
			::statusicon::setTooltip $statusicon "[trans offline]"
			::statusicon::setImage $statusicon $pixmap
		}
	} else {
		if { $systemtray_exist == 1 && $statusicon == 0 && $status != "REMOVE" } {
			trayicon_init
		}
	}

	set my_name [::abook::getPersonal MFN]
   	
	if { $systemtray_exist == 1 && $statusicon != 0 && $status == "REMOVE" } {
		if { [WinDock] } {
			winico taskbar delete $wintrayicon
		} else {
			remove_icon $statusicon
			if {[UnixDock] } {
				catch {
					image delete statustrayicon
					if {!$use_tktray} {
						image delete statustrayiconres
					}
				}
			}
		}
		set statusicon 0
	} elseif {$systemtray_exist == 1 && $statusicon != 0 && $status != "REMOVE"} {
		if { $status != "" } {
			if { $status == "FLN" } {
				# Send message 
				$iconmenu entryconfigure 2 -state disabled
				#Status submenu
				$iconmenu entryconfigure 4 -state disabled
				#Change nick/psm
				$iconmenu entryconfigure 6 -state disabled
				$iconmenu entryconfigure 7 -state disabled

				#Login/Logout
				$iconmenu entryconfigure 13 -label "[trans login]" -command "::MSN::connect" -state normal

			} else {

				$iconmenu entryconfigure 2 -state normal
				$iconmenu entryconfigure 4 -state normal
				$iconmenu entryconfigure 6 -state normal
				$iconmenu entryconfigure 7 -state normal

				$iconmenu entryconfigure 13 -label "[trans logout]" -command "preLogout \"::MSN::logout\""

				
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
			  "BOSS" {   
				#for bossmode
				set pixmap "[::skin::GetSkinFile pixmaps dboss.png]"
				set tooltip "[trans pass]"
				if { [WinDock] } {
					set trayicon [winico create [::skin::GetSkinFile winicons bossmode.ico]]
				}
			  }
			  default {
				set pixmap "null"
				set tooltip ""
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
					set statusicon 1
				}

			} elseif {[UnixDock] } {
				if { $pixmap != "null"} {
					image create photo statustrayicon -file $pixmap
					if {!$use_tktray} {
						image create photo statustrayiconres
					}
				}
			} elseif {[MacDock] } {
				if { $pixmap == "null"} {
					::statusicon::setVisible $statusicon 0
				} else {
					::statusicon::setImage $statusicon $pixmap
					::statusicon::setTooltip $statusicon $tooltip
				}
			}

		}
	}
}

proc statusicon_blink_proc {status} {
    global systemtray_exist statusicon iconmenu wintrayicon use_tktray

    if { [::config::getKey use_tray] == 0 || $systemtray_exist == 0 || $statusicon == 0 } { return }

    set my_name [::abook::getPersonal MFN]
    
    if { $status != "" } {
        switch $status {
          "FLN" {
            set pixmap "[::skin::GetSkinFile pixmaps dofflineb.png]"
            set tooltip "[trans offline]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons offlineb.ico]]
            }
          }
        
          "NLN" {
            set pixmap "[::skin::GetSkinFile pixmaps donlineb.png]"
            set tooltip "$my_name ([::config::getKey login]): [trans online]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons onlineb.ico]]
            }
          }
          
          "IDL" {
            set pixmap "[::skin::GetSkinFile pixmaps dinactiveb.png]"
            set tooltip "$my_name ([::config::getKey login]): [trans noactivity]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons inactiveb.ico]]
            }
          }
          "BSY" {
            set pixmap "[::skin::GetSkinFile pixmaps dbusyb.png]"
            set tooltip "$my_name ([::config::getKey login]): [trans busy]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons busyb.ico]]
            }
          }
          "BRB" {
            set pixmap "[::skin::GetSkinFile pixmaps dbrbb.png]"
            set tooltip "$my_name ([::config::getKey login]): [trans rightback]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons brbb.ico]]
            }
          }
          "AWY" {
            set pixmap "[::skin::GetSkinFile pixmaps dawayb.png]"
            set tooltip "$my_name ([::config::getKey login]): [trans away]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons awayb.ico]]
            }
          }
          "PHN" {
            set pixmap "[::skin::GetSkinFile pixmaps dphoneb.png]"
            set tooltip "$my_name ([::config::getKey login]): [trans onphone]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons phoneb.ico]]
            }
          }
          "LUN" {
            set pixmap "[::skin::GetSkinFile pixmaps dlunchb.png]"
            set tooltip "$my_name ([::config::getKey login]): [trans gonelunch]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons lunchb.ico]]
            }
          }
          "HDN" {
            set pixmap "[::skin::GetSkinFile pixmaps dhiddenb.png]"
            set tooltip "$my_name ([::config::getKey login]): [trans appearoff]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons hiddenb.ico]]
            }
          }
          "BOSS" {   
            #for bossmode
            set pixmap "[::skin::GetSkinFile pixmaps dboss.png]"
            set tooltip "[trans pass]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons bossmode.ico]]
            }
          }
          default {
            set pixmap "null"
            set tooltip ""
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons msn.ico]]
            }
          }
        }

	if {[::skin::getKey trayblink_by_status] == 0} {
            set pixmap "[::skin::GetSkinFile pixmaps trayblink.png]"
            if { [WinDock] } {
                set trayicon [winico create [::skin::GetSkinFile winicons trayblink.ico]]
            }
	}

        $iconmenu entryconfigure 0 -label "[::config::getKey login]"
        if { [WinDock] } {
            if { ![winfo exists .bossmode] || $status == "BOSS" } {
                #skip if in bossmode and not setting to BOSS
                winico taskbar delete $wintrayicon
                set wintrayicon $trayicon
                winico taskbar add $wintrayicon -text $tooltip -callback "taskbar_icon_handler %m %x %y"
                set statusicon 1
            }

        } elseif {[UnixDock] } {
            if { $pixmap != "null"} {
                image create photo statustrayicon -file $pixmap
		if {!$use_tktray} {
			image create photo statustrayiconres
		}
            }
        } elseif {[MacDock] } {
            if { $pixmap == "null"} {
                ::statusicon::setVisible $statusicon 0
            } else {
                ::statusicon::setImage $statusicon $pixmap
                ::statusicon::setTooltip $statusicon $tooltip
            }
        }

    }
}

proc taskbar_mail_icon_handler { msg x y } {
	if { $msg=="WM_LBUTTONUP" } {
		::hotmail::hotmail_login 
	}
}

proc mailicon_callback { action } {
	if { $action == "DOUBLE_ACTION" } {
		::hotmail::hotmail_login
	}   
}

proc mailicon_proc {num} {
	# Workaround for bug in the traydock-plugin - statusicon added - BEGIN
	global systemtray_exist mailicon statusicon winmailicon defaultbackground use_tktray
	# Workaround for bug in the traydock-plugin - statusicon added - END

	if { [::config::getKey showmailicon] == 0 } {
		return
	}

	if {$systemtray_exist == 1 && $mailicon == 0 && $num >0} {
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
		} elseif {[UnixDock] } {
			image create photo mailtrayicon -file $pixmap
			if {$use_tktray} {
				catch {destroy .mi}
				set mailicon .mi
				tktray::icon .mi -image mailtrayicon
				after 1000 { trayicon_resize .mi}

				bind .mi <<IconCreate>> {puts "mail tray created"}
				bind .mi <Configure> {puts "mail tray configured2"}
				bind .mi <<IconConfigure>> {puts "mail tray configured"; trayicon_resize .mi}
				bind .mi <<IconDestroy>> {puts "mail tray destroyed"}
			} else {
				image create photo mailtrayiconres
				set mailicon [newti .mi -pixmap mailtrayiconres -command "::trayicon_callback mailtrayicon mailtrayiconres"]
			} 

			bind .mi <Button-1> "::hotmail::hotmail_login"
			bind .mi <Enter> [list balloon_enter %W %X %Y $msg]
			bind .mi <Motion> [list balloon_motion %W %X %Y $msg]
			bind .mi <Leave> "+set Bulle(first) 0; kill_balloon"
		} elseif {[MacDock] } {
			#add the icon
			set mailicon [::statusicon::create mailicon_callback]
			::statusicon::setTooltip $mailicon "[trans onenewmail]"
			::statusicon::setImage $mailicon $pixmap
		}

	} elseif {$systemtray_exist == 1 && $mailicon != 0 && $num == 0} {
		if { [WinDock] } {
			winico taskbar delete $winmailicon
		} else {
			remove_icon $mailicon
			if {[UnixDock] } {
				catch {
					image delete mailtrayicon
					if {!$use_tktray} {
						image delete mailtrayiconres
					}
				}
			}
		}
		set mailicon 0
	} elseif {$systemtray_exist == 1 && $mailicon != 0 && $num > 0} {
		set froms [::hotmail::getFroms]
		set fromsText ""
		foreach {from frommail} $froms {
			append fromsText "\n[trans newmailfrom $from $frommail]"
		}

		if { $num == 1 } {
			set msg "[trans onenewmail]\n$fromsText"
		} elseif { $num == 2 } {
			set msg "[trans twonewmail 2]\n$fromsText"
		} else {
			set msg "[trans newmail $num]\n$fromsText"
		}
		if { [WinDock] } {
			winico taskbar modify $winmailicon -text $msg
		} elseif {[UnixDock] } {
			bind $mailicon <Enter> [list balloon_enter %W %X %Y $msg]
			bind $mailicon <Motion> [list balloon_motion %W %X %Y $msg]
		} elseif {[MacDock] } {
			::statusicon::setTooltip $mailicon $msg
		}
	} 
}

proc remove_icon {icon} {
	global systemtray_exist use_tktray
	if {$icon != 0} {
		# Can't use UnixDock and MacDock because if we remove the icon
		# it might be because the user disabled the 'use_tray' option
		# so those functions would always return false...
		if {[OnLinux] || [OnBSD]} {
			if {$use_tktray} {
				catch {destroy $icon}
			} else {
				catch {removeti $icon}
			}
		} elseif {[OnMac] } {
			catch { ::statusicon::destroy $icon}
		}
	}
}

proc restart_tray { } {

    status_log "RESTARTING the traydock"

    statusicon_proc "REMOVE"
    statusicon_proc [::MSN::myStatusIs]
    
}
