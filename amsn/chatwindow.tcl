#########################################
#    Chat Window code abstraction       #
#           By Alberto Díaz             #
#########################################
namespace eval ::ChatWindow {

	#///////////////////////////////////////////////////////////////////////////////
	# Namespace variables, relative to chat windows' data. In the code are accessible
	# through '::namespace::variable' syntax (to avoid local instances of the variable
	# and have the scope more clear).
	variable chat_ids
	variable first_message
	variable msg_windows
	variable new_message_on
	variable recent_message
	variable titles
	variable windows [list]

	if { ![info exists ::ChatWindow::winid] } {
		# As ::ChatWindow::winid is the index used in the
		# window widgets for chat windows, we only initialize
		# it at the first time, to avoid problems with proc
		# reload_files wich will cause some bugs related to
		# winid being 0 after some windows have been created.
		variable winid 0
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Change (chatid, newchatid)
	# This proc is called from the protocol layer when a private chat changes into a
	# conference, right after a JOI command comes from the SB. It means that the window
	# assigned to $chatid should now be related to $newchatid. ::ChatWindow::Change 
	# will return the new chatid if the change is OK (no other window for that name 
	# exists), or the old chatid if the change is not right
	# Arguments:
	# - chatid => Is the name of the chat that was a single private before.
	# - newchatid => Is the new id of the chat for the conference
	proc Change { chatid newchatid } {
		set win_name [::ChatWindow::For $chatid]

		if { $win_name == 0 } {
			# Old window window does not exists, so just accept the change, no worries
			status_log "::ChatWindow::Change: Window doesn't exist (probably invited to a conference)\n"
			return $newchatid
		}

		if { [::ChatWindow::For $newchatid] != 0} {
			#Old window existed, probably a conference, but new one exists too, so we can't
			#just allow that messages shown in old window now are shown in a different window,
			#that wouldn't be nice, so don't allow change
			status_log "conference wants to become private, but there's already a window\n"
			return $chatid
		}

		#So, we had an old window for chatid, but no window for newchatid, so the window will
		#change it's assigned chat
		::ChatWindow::UnsetFor $chatid $win_name
		::ChatWindow::SetFor $newchatid $win_name

		status_log "::ChatWindow::Change: changing $chatid into $newchatid\n"

		return $newchatid
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Clear (window)
	# Deletes all the text in the chat window's input widget
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc Clear { window } {
		${window}.f.out.text configure -state normal
		${window}.f.out.text delete 0.0 end
		${window}.f.out.text configure -state disabled
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Close (window)
	# Called when a window is about to be closed, for example when we press ESC.
	# Arguments:
	#  - window => Is the window widget destroyed (.msg_n - Where n is an integer)
	proc Close { window } {
		if { $::ChatWindow::recent_message($window) == 1  && [::config::getKey recentmsg] == 1} {
			status_log "Recent message exists\n" white
			set ::ChatWindow::recent_message($window) 0
		} else {
			set idx [lsearch $::ChatWindow::windows $window]
			if { $idx != -1 } {
				set ::ChatWindow::windows [lreplace $::ChatWindow::windows $idx $idx]
			}
			destroy $window
		}
		
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Closed (window, path)
	# Called when a window and its children are destroyed. When the main window is
	# destroyed ($window == $path) then it tells the protocol layer to leave the
	# chat related to $window, and unsets variables used for that window.
	# Arguments:
	#  - window => Is the window widget destroyed (.msg_n - Where n is an integer)
	#  - path => Is the parent widget of the destroyed childrens (the window)
	proc Closed { window path } {
		#Only run when the parent window close event comes
		if { "$window" != "$path" } {
			return 0
		}

		set chatid [::ChatWindow::Name $window]

		if { $chatid == 0 } {
			status_log "VERY BAD ERROR in ::ChatWindow::Closed!!!\n" red
			return 0
		}

		if {[::config::getKey keep_logs]} {
			set user_list [::MSN::usersInChat $chatid]
			foreach user_login $user_list {
				::log::StopLog $user_login
			}
		}

		::ChatWindow::UnsetFor $chatid $window
		unset ::ChatWindow::titles(${window})
		unset ::ChatWindow::first_message(${window})
		unset ::ChatWindow::recent_message(${window})

		#Delete images if not in use
		catch {destroy $window.bottom.pic}
		set user_list [::MSN::usersInChat $chatid]
		foreach user_login $user_list {
			if {![catch {image inuse user_pic_$user_login}]} {

				if {![image inuse user_pic_$user_login]} {
					status_log "Image user_pic_$user_login not in use, deleting it\n"
					image delete user_pic_$user_login
				}
			}
		}
		::MSN::leaveChat $chatid
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Configured (window)
	# This proc is called when we resize the window, it stores the new size in config
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc Configured { window } {
		set chatid [::ChatWindow::Name $window]

		if { $chatid != 0 } {
			after cancel "::ChatWindow::TopUpdate $chatid"
			after 200 "::ChatWindow::TopUpdate $chatid"
		}

		set geometry [wm geometry $window]
		set pos_start [string first "+" $geometry]

		if { [::config::getKey savechatwinsize] } {
			::config::setKey winchatsize  [string range $geometry 0 [expr {$pos_start-1}]]
		}
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Flicker (chatid, [count])
	# Called when a window must flicker, and called by itself to produce the flickering
	# effect. It will flicker the window until it gets the focus.
	# Arguments:
	#  - chatid => Is the name of the chat to flicker (a passport login)
	#  - count => [NOT REQUIRED] Can be any number, it's just used in self calls
	proc Flicker {chatid {count 0}} {
		if { [::ChatWindow::For $chatid] != 0 } {
			set window [::ChatWindow::For $chatid]
		} else {
			return 0
		}

		if { [::config::getKey flicker] == 0 } {
			if { [string first $window [focus]] != 0 } {
				catch {wm title ${window} "*$::ChatWindow::titles($window)"} res
				set ::ChatWindow::new_message_on(${window}) 1
				bind ${window} <FocusIn> "::ChatWindow::GotFocus ${window}"
			}
			return 0
		}

		after cancel ::ChatWindow::Flicker $chatid 0
		after cancel ::ChatWindow::Flicker $chatid 1

		if { [string first $window [focus]] != 0 } {

			# If user uses Windows, call winflash to flash the window, this is done by
			# calling the winflash proc that should be created by the flash.dll extension
			# so we do it in a catch statement, if it fails. Then load the extension before
			# calling winflash. If this one or the first one were successful, we add a bind
			# on FocusIn to call the winflash with the -state 0 option to disable it and we return.
			if { [set ::tcl_platform(platform)] == "windows" } {
				if { [catch {winflash $window -count -1} ] } {
					if { ![catch { 
						load [file join plugins winflash flash.dll]
						winflash $window -count -1
					} ] } {
						bind $window <FocusIn> "catch \" winflash $window -state 0\"; bind $window <FocusIn> \"\""
						return
					}
				} else {
					bind $window <FocusIn> "catch \" winflash $window -state 0\"; bind $window <FocusIn> \"\""
					return
				}
			}

			set count  [expr {( $count +1 ) % 2}]

			if {![catch {
				if { $count == 1 } {
					wm title ${window} "[trans newmsg]"
				} else {
					wm title ${window} "$::ChatWindow::titles($window)"
				}
			} res]} {
				after 300 ::ChatWindow::Flicker $chatid $count
			}
		} else {

			catch {wm title ${window} "$::ChatWindow::titles($window)"} res
		}
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::For (chatid)
	# Returns the name of the window (.msg_n) that should show the messages and 
	# information related to the chat 'chatid'.
	# Arguments:
	#  - chatid => Is the chat id of the window, the passport account of the buddy
	proc For { chatid } {
		if { [info exists ::ChatWindow::msg_windows($chatid)]} {
			return $::ChatWindow::msg_windows($chatid)
		}
		return 0
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::GotFocus (window)
	# Called when a window with a new msg gets the focus and goes back to its title
	# Arguments:
	#  - window => Is the window widget focused (.msg_n - Where n is an integer)
	proc GotFocus { window } {
		if { [info exists ::ChatWindow::new_message_on(${window})] && \
			$::ChatWindow::new_message_on(${window}) == 1 } {
			unset ::ChatWindow::new_message_on(${window})
			catch {wm title ${window} "$::ChatWindow::titles(${window})"} res
			bind ${window} <FocusIn> ""
		}
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::MacPosition
	# To place the ::ChatWindow::Open at the right place on Mac OS X, because the
	# window manager will put all the windows in bottom left after some time.
	# Arguments:
	#  - chatid => Is the name of the chat to flicker (a passport login)
	#  - count => [NOT REQUIRED] Can be any number, it's just used in self calls
 	proc MacPosition { window } {
 		#To know where the window manager want to put the window in X and Y
 		set info1 [winfo x $window]
 		set info2 [winfo y $window]
 		#Determine the maximum place in Y to place a window
 		#Size of the screen (in y) - size of the window
 		set max [expr [winfo vrootheight $window] - [winfo height $window]]
 		#If the position of the window in y is superior to the maximum
 		#Then up the window by the size of the window
 		if { $info2 > $max } { 
			set info2 [expr {$info2 - [winfo height $window]}] 
		}
 		#If the result is smaller than 25 (on small screen) then use 25 
 		if { $info2 < 25 } {
			set info2 25
		}
 		#Replace the window to the new position on the screen 	
 		wm geometry $window +${info1}+${info2}
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::MakeFor (chatid, [msg ""], [usr_name ""])
	# Opens a window if it did not existed, and if it is the first message it adds
	# the message to a notify window (::amsn::notifyAdd), and plays sound if enabled
	# Arguments:
	#  - chatid => Is the chat id of the window, the passport account of the buddy
	#  - [msg ""] => [NOT REQUIRED] The message sent to us (first message)
	#  - [usr_name ""] => [NOT REQUIRED] Is the user who sends the message
	proc MakeFor { chatid {msg ""} {usr_name ""} } {
		set win_name [::ChatWindow::For $chatid]

		# If there wasn't a window created and assigned to $chatid, let's create one
		# through ::ChatWindow::Open and assign it to $chatid with ::ChatWindow::SetFor
		if { $win_name == 0 } {
			set win_name [::ChatWindow::Open]
			::ChatWindow::SetFor $chatid $win_name
			update idletasks
			::ChatWindow::TopUpdate $chatid

			if { [::config::getKey showdisplaypic] && $usr_name != ""} {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name]
			} else {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name] nopack
			}
		}

		# If this is the first message, and no focus on window, then show notify
		if { $::ChatWindow::first_message($win_name) == 1  && $msg!="" } {
			set ::ChatWindow::first_message($win_name) 0
			
			if { [string first ${win_name} [focus]] != 0} {
				if { ([::config::getKey notifymsg] == 1 && [::abook::getContactData $chatid notifymsg -1] != 0) ||
				[::abook::getContactData $chatid notifymsg -1] == 1 } {
					::amsn::notifyAdd "$msg" "::amsn::chatUser $chatid"
				}
			}
			
			if { [::config::getKey newmsgwinstate] == 0 } {
				if { [winfo exists .bossmode] } {
					set ::BossMode(${win_name}) "normal"
					wm state ${win_name} withdraw
				} else {
					wm state ${win_name} normal
				}

				wm deiconify ${win_name}

				if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
					lower ${win_name}
					::ChatWindow::MacPosition ${win_name}
				} else {
					raise ${win_name}
				}

			} else {
				# Iconify the window unless it was raised by the user already.
				if { [wm state $win_name] != "normal" } {
					if { [winfo exists .bossmode] } {
						set ::BossMode(${win_name}) "iconic"
						wm state ${win_name} withdraw
					} else {
						wm state ${win_name} iconic
					}
				}
			}
		} elseif { $msg == "" } {
			#If it's not a message event, then it's a window creation (user joins to chat)
			if { [::config::getKey newchatwinstate] == 0 } {
				if { [winfo exists .bossmode] } {
					set ::BossMode(${win_name}) "normal"
					wm state ${win_name} withdraw
				} else {
					wm state ${win_name} normal
				}

				wm deiconify ${win_name}

				#To have the new window "behind" on Mac OS X
				if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
					lower ${win_name}
					::ChatWindow::MacPosition ${win_name}
				} else {
					raise ${win_name}
				}

			} else {
				if { [winfo exists .bossmode] } {
					set ::BossMode(${win_name}) "iconic"
					wm state ${win_name} withdraw
				} else {
					wm state ${win_name} iconic
				}
			}
		}

		#If no focus, and it's a message event, do something to the window
		if { (([::config::getKey soundactive] == "1" && $usr_name != [::config::getKey login]) || \
			[string first ${win_name} [focus]] != 0) && $msg != "" } {
			play_sound type.wav
		}

		#Dock Bouncing on Mac OS X
		if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
			# tclCarbonNotification is in plugins, we have to require it
			package require tclCarbonNotification

			# Bounce unlimited of time when we are not in aMSN and receive a
			# message, until we re-click on aMSN icon (or get back to aMSN)
			if { (([::config::getKey dockbounce] == "unlimited" && $usr_name != [::config::getKey login]) \
				&& [focus] == "") && $msg != "" } {
				tclCarbonNotification 1 ""
			}

			# Bounce then stop bouncing after 1 second, when we are not
			# in aMSN and receive a message (default)
			if { (([::config::getKey dockbounce] == "once" && $usr_name != [::config::getKey login]) \
				&& [focus] == "") && $msg != "" } {
				tclCarbonNotification 1 ""
				after 1000 [list catch [list tclEndCarbonNotification]]
			}
		}
		return $win_name
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Name (window)
	# This proc returns the user login (chatid) of the buddy in that chat.
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc Name { window } {
		if { [info exists ::ChatWindow::chat_ids($window)]} {
			return $::ChatWindow::chat_ids($window)
		}
		return 0
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Open () 
	# Creates a new chat window and returns its name (.msg_n - Where n is winid)
	proc Open { } {
		global  HOME files_dir tcl_platform xmms

		set win_name "msg_$::ChatWindow::winid"
		incr ::ChatWindow::winid

		toplevel .${win_name} -class Amsn

		# If there isn't a configured size for Chat Windows, use the default one and store it.
		if {[catch { wm geometry .${win_name} [::config::getKey winchatsize] } res]} {
			wm geometry .${win_name} 350x390
			::config::setKey winchatsize 350x390
			status_log "No config(winchatsize). Setting default size for chat window\n" red
		}

		if {$tcl_platform(platform) == "windows"} {
		    wm geometry .${win_name} +0+0
		}

		if { [winfo exists .bossmode] } {
			set ::BossMode(.${win_name}) "iconic"
			wm state .${win_name} withdraw
		} else {
			wm state .${win_name} iconic
		}

		wm title .${win_name} "[trans chat]"
		wm group .${win_name} .

		# If the platform is NOT windows, set the windows' icon to our xbm
		if {$tcl_platform(platform) != "windows"} {
			catch {wm iconbitmap .${win_name} @[GetSkinFile pixmaps amsn.xbm]}
			catch {wm iconmask .${win_name} @[GetSkinFile pixmaps amsnmask.xbm]}
		}

		# Test on Mac OS X(TkAqua) if ImageMagick is installed and kill all sndplay processes      
		if {$tcl_platform(os) == "Darwin"} {
			if { [::config::getKey getdisppic] != 0 } {
				check_imagemagick
			}
		}

		menu .${win_name}.menu -tearoff 0 -type menubar -borderwidth 0 -activeborderwidth -0

		# Change MSN menu's caption on Mac for "File" to match the Apple UI Standard
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			.${win_name}.menu add cascade -label "[trans file]" -menu .${win_name}.menu.msn
		} else {
			.${win_name}.menu add cascade -label "[trans msn]" -menu .${win_name}.menu.msn
		}

		.${win_name}.menu add cascade -label "[trans edit]" -menu .${win_name}.menu.edit
		.${win_name}.menu add cascade -label "[trans view]" -menu .${win_name}.menu.view
		.${win_name}.menu add cascade -label "[trans actions]" -menu .${win_name}.menu.actions

		# Apple menu, only on Mac OS X for legacy reasons (Each OS X app have one Apple menu)
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			.${win_name}.menu add cascade -label "Apple" -menu .${win_name}.menu.apple
			menu .${win_name}.menu.apple -tearoff 0 -type normal
			.${win_name}.menu.apple add command -label "[trans about] aMSN" \
				-command ::amsn::aboutWindow
			.${win_name}.menu.apple add separator
			.${win_name}.menu.apple add command -label "[trans preferences]..." \
				-command Preferences -accelerator "Command-,"
			.${win_name}.menu.apple add separator
		}

		menu .${win_name}.menu.msn -tearoff 0 -type normal
		.${win_name}.menu.msn add command -label "[trans savetofile]..." \
			-command " ChooseFilename .${win_name}.f.out.text ${win_name} "
		.${win_name}.menu.msn add separator
		.${win_name}.menu.msn add command -label "[trans sendfile]..." \
			-command "::amsn::FileTransferSend .${win_name}"
		.${win_name}.menu.msn add command -label "[trans openreceived]..." \
			-command "launch_filemanager \"$files_dir\""
		.${win_name}.menu.msn add separator

		#Add accelerator label to "close" on Mac Version
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			.${win_name}.menu.msn add command -label "[trans close]" \
				-command "destroy .${win_name}" -accelerator "Command-W"
		} else {
			.${win_name}.menu.msn add command -label "[trans close]" \
				-command "destroy .${win_name}"
		}

		menu .${win_name}.menu.edit -tearoff 0 -type normal

		#Change the accelerator on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			.${win_name}.menu.edit add command -label "[trans cut]" \
				-command "tk_textCut .${win_name}" -accelerator "Command+X"
			.${win_name}.menu.edit add command -label "[trans copy]" \
				-command "tk_textCopy .${win_name}" -accelerator "Command+C"
			.${win_name}.menu.edit add command -label "[trans paste]" \
				-command "tk_textPaste .${win_name}" -accelerator "Command+V"
		} else {
			.${win_name}.menu.edit add command -label "[trans cut]" \
				-command "tk_textCut .${win_name}" -accelerator "Ctrl+X"
			.${win_name}.menu.edit add command -label "[trans copy]" \
				-command "tk_textCopy .${win_name}" -accelerator "Ctrl+C"
			.${win_name}.menu.edit add command -label "[trans paste]" \
				-command "tk_textPaste .${win_name}" -accelerator "Ctrl+V"
		}
		
		.${win_name}.menu.edit add separator
		.${win_name}.menu.edit add command -label "[trans clear]" -command [list ::ChatWindow::Clear .${win_name}]
		
		menu .${win_name}.menutextsize -tearoff 0 -type normal

		.${win_name}.menutextsize add command -label "+8" -command "change_myfontsize 8"
		.${win_name}.menutextsize add command -label "+6" -command "change_myfontsize 6"
		.${win_name}.menutextsize add command -label "+4" -command "change_myfontsize 4"
		.${win_name}.menutextsize add command -label "+2" -command "change_myfontsize 2"
		.${win_name}.menutextsize add command -label "+1" -command "change_myfontsize 1"
		.${win_name}.menutextsize add command -label "+0" -command "change_myfontsize 0"
		.${win_name}.menutextsize add command -label " -1" -command "change_myfontsize -1"
		.${win_name}.menutextsize add command -label " -2" -command "change_myfontsize -2"

		menu .${win_name}.menu.view -tearoff 0 -type normal

		.${win_name}.menu.view add cascade -label "[trans textsize]" -menu .${win_name}.menutextsize
		.${win_name}.menu.view add separator
		.${win_name}.menu.view add checkbutton -label "[trans chatsmileys]" \
			-onvalue 1 -offvalue 0 -variable [::config::getVar chatsmileys]

		global .${win_name}_show_picture
		set .${win_name}_show_picture 0
		
		.${win_name}.menu.view add checkbutton -label "[trans showdisplaypic]" \
			-command "::amsn::ShowOrHidePicture .${win_name}" -onvalue 1 \
			-offvalue 0 -variable ".${win_name}_show_picture"
		.${win_name}.menu.view add separator

		# Remove this menu item on Mac OS X because we "lost" the window instead
		# of just hide it and change accelerator for history on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			.${win_name}.menu.view add command -label "[trans history]" \
				-command "::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin" \
				-accelerator "Command-Option-H"
		} else {
			.${win_name}.menu.view add command -label "[trans history]" \
				-command "::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin" \
				-accelerator "Ctrl+H"
			.${win_name}.menu.view add separator
			.${win_name}.menu.view add command -label "[trans hidewindow]" \
				-command "wm state .${win_name} withdraw"
		}
		
		.${win_name}.menu.view add separator
		.${win_name}.menu.view add cascade -label "[trans style]" -menu .${win_name}.menu.view.style

		menu .${win_name}.menu.view.style -tearoff 0 -type normal

		.${win_name}.menu.view.style add radiobutton -label "[trans msnstyle]" \
			-value "msn" -variable [::config::getVar chatstyle]
		.${win_name}.menu.view.style add radiobutton -label "[trans ircstyle]" \
			-value "irc" -variable [::config::getVar chatstyle]
		.${win_name}.menu.view.style add radiobutton -label "[trans customstyle]..." \
			-value "custom" -variable [::config::getVar chatstyle] \
			-command "::amsn::enterCustomStyle"

		menu .${win_name}.menu.actions -tearoff 0 -type normal

		.${win_name}.menu.actions add command -label "[trans addtocontacts]" \
			-command "::amsn::ShowAddList \"[trans addtocontacts]\" .${win_name} ::MSN::addUser"
		.${win_name}.menu.actions add command -label "[trans block]/[trans unblock]" \
			-command "::amsn::ShowChatList \"[trans block]/[trans unblock]\" .${win_name} ::amsn::blockUnblockUser"
		.${win_name}.menu.actions add command -label "[trans viewprofile]" \
			-command "::amsn::ShowChatList \"[trans viewprofile]\" .${win_name} ::hotmail::viewProfile"
		.${win_name}.menu.actions add command -label "[trans properties]" \
			-command "::amsn::ShowChatList \"[trans properties]\" .${win_name} ::abookGui::showUserProperties"
		.${win_name}.menu.actions add separator
		.${win_name}.menu.actions add command -label "[trans invite]..." \
			-command "::amsn::ShowInviteList \"[trans invite]\" .${win_name}"
		.${win_name}.menu.actions add separator
		.${win_name}.menu.actions add command -label [trans sendmail] \
			-command "::amsn::ShowChatList \"[trans sendmail]\" .${win_name} launch_mailer"
			
		.${win_name} conf -menu .${win_name}.menu

		menu .${win_name}.copypaste -tearoff 0 -type normal

		.${win_name}.copypaste add command -label [trans cut] \
			-command "status_log cut\n;tk_textCut .${win_name}"
		.${win_name}.copypaste add command -label [trans copy] \
			-command "status_log copy\n;tk_textCopy .${win_name}"
		.${win_name}.copypaste add command -label [trans paste] \
			-command "status_log paste\n;tk_textPaste .${win_name}"

		menu .${win_name}.copy -tearoff 0 -type normal

		.${win_name}.copy add command -label [trans copy] \
			-command "status_log copy\n;copy 0 .${win_name}"

		# Creates de XMMS extension's menu if the plugin is loaded
		if { [info exist xmms(loaded)] } {
			.${win_name}.copy add cascade -label "XMMS" -menu .${win_name}.copy.xmms
			menu .${win_name}.copy.xmms -tearoff 0 -type normal
			.${win_name}.copy.xmms add command -label [trans xmmscurrent] -command "xmms ${win_name} 1"
			.${win_name}.copy.xmms add command -label [trans xmmssend] -command "xmms ${win_name} 2"
		}
		
		#Send a postevent for the creation of menu
		set evPar(window_name) ".${win_name}"
		set evPar(menu_name) ".${win_name}.menu"
		::plugins::PostEvent chatmenu evPar

		frame .${win_name}.f -class amsnChatFrame -background [::skin::getColor background1] -borderwidth 0 -relief flat
		ScrolledWindow .${win_name}.f.out -auto vertical -scrollbar vertical
		text .${win_name}.f.out.text -borderwidth 1 -foreground white -background white -width 45 -height 5 -wrap word \
			-exportselection 1  -relief flat -highlightthickness 0 -selectborderwidth 1

		.${win_name}.f.out setwidget .${win_name}.f.out.text

		frame .${win_name}.f.top -class Amsn -relief flat -borderwidth 0 -background [::skin::getColor background1]
		text .${win_name}.f.top.textto  -borderwidth 0 -width [string length "[trans to]:"] \
			-relief solid -height 1 -wrap none -background [::skin::getColor background1] \
			-foreground [::skin::getColor background2] -highlightthickness 0 \
			-selectbackground [::skin::getColor background1] -selectforeground [::skin::getColor background2] \
			-selectborderwidth 0 -exportselection 0 -padx 5

		.${win_name}.f.top.textto configure -state normal -font bplainf
		.${win_name}.f.top.textto insert end "[trans to]:"
		.${win_name}.f.top.textto configure -state disabled

		text .${win_name}.f.top.text  -borderwidth 0 -width 45 -relief flat -height 1 -wrap none \
			-background [::skin::getColor background1] -foreground [::skin::getColor background2] \
			-highlightthickness 0 -selectbackground [::skin::getColor background1] -selectborderwidth 0 \
			-selectforeground [::skin::getColor background2] -exportselection 1

		# Change color of border on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			frame .${win_name}.f.bottom -class Amsn -borderwidth 0 -relief solid \
				-background [::skin::getColor background2]
		} else {
			frame .${win_name}.f.bottom -class Amsn -borderwidth 0 -relief solid \
				-background [::skin::getColor background1]
		}

		set bottom .${win_name}.f.bottom

		frame $bottom.buttons -class Amsn -borderwidth 0 -relief solid -background [::skin::getColor background2]
		frame $bottom.in -class Amsn -background white -relief solid -borderwidth 0
		text $bottom.in.input -background white -width 15 -height 3 -wrap word -font bboldf \
			-borderwidth 0 -relief solid -highlightthickness 0 -exportselection 1
		frame $bottom.in.f -class Amsn -borderwidth 0 -relief solid -background white

		# Send button in conversation window, specifications and command. Only
		# compatible with Tcl/Tk 8.4. Disable it on Mac OS X (TkAqua looks better)
		if { $::tcl_version >= 8.4 && $tcl_platform(os) != "Darwin" } {
			# New pixmap-skinnable button (For Windows and Unix > Tcl/Tk 8.3)
			button $bottom.in.f.send -image [::skin::loadPixmap sendbutton] \
				-command "::amsn::MessageSend .${win_name} $bottom.in.input" \
				-fg black -bg white -bd 0 -relief flat -overrelief flat \
				-activebackground white -activeforeground #8c8c8c -text [trans send] \
				-font sboldf -compound center -highlightthickness 0
		} else {
			# Standard grey flat button (For Tcl/Tk < 8.4 and Mac OS X)
			button $bottom.in.f.send  -text [trans send] -width 6 -borderwidth 1 \
				-relief solid -command "::amsn::MessageSend .${win_name} $bottom.in.input" \
				-font bplainf -highlightthickness 0 -highlightbackground white
		}

		# This proc is called to load the Display Picture if exists and is readable
		load_my_pic

		label $bottom.pic -borderwidth 1 -relief solid -image [::skin::getNoDisplayPicture] -background #FFFFFF
		set_balloon $bottom.pic [trans nopic]
		button $bottom.showpic -bd 0 -padx 0 -pady 0 -image [::skin::loadPixmap imgshow] \
			-bg [::skin::getColor background1] -highlightthickness 0 -font splainf \
			-command "::amsn::ToggleShowPicture ${win_name}; ::amsn::ShowOrHidePicture .${win_name}"
		set_balloon $bottom.showpic [trans showdisplaypic]

		grid $bottom.showpic -row 0 -column 2 -padx 0 -pady 3 -rowspan 2 -sticky ns
		grid columnconfigure $bottom 3 -minsize 3
		bind $bottom.pic <Button1-ButtonRelease> "::amsn::ShowPicMenu .${win_name} %X %Y\n"
		bind $bottom.pic <<Button3>> "::amsn::ShowPicMenu .${win_name} %X %Y\n"

		frame .${win_name}.statusbar -class Amsn -borderwidth 0 -relief solid
		text .${win_name}.statusbar.status  -width 5 -height 1 -wrap none \
			-font bplainf -borderwidth 1
		text .${win_name}.statusbar.charstyped  -width 4 -height 1 -wrap none \
			-font splainf -borderwidth 1

		.${win_name}.statusbar.charstyped tag configure center -justify left

		button $bottom.buttons.smileys  -image [::skin::loadPixmap butsmile] -relief flat -padx 5 \
			-background [::skin::getColor background2] -highlightthickness 0 -borderwidth 0
		set_balloon $bottom.buttons.smileys [trans insertsmiley]
		button $bottom.buttons.fontsel -image [::skin::loadPixmap butfont] -relief flat -padx 5 \
			-background [::skin::getColor background2] -highlightthickness 0 -borderwidth 0
		set_balloon $bottom.buttons.fontsel [trans changefont]
		button $bottom.buttons.block -image [::skin::loadPixmap butblock] -relief flat -padx 5 \
			-background [::skin::getColor background2] -highlightthickness 0 -borderwidth 0
		set_balloon $bottom.buttons.block [trans block]
		button $bottom.buttons.sendfile -image [::skin::loadPixmap butsend] -relief flat -padx 3 \
			-background [::skin::getColor background2] -highlightthickness 0 -borderwidth 0
		set_balloon $bottom.buttons.sendfile [trans sendfile]
		button $bottom.buttons.invite -image [::skin::loadPixmap butinvite] -relief flat -padx 3 \
			-background [::skin::getColor background2] -highlightthickness 0 -borderwidth 0
		set_balloon $bottom.buttons.invite [trans invite]
		
		pack $bottom.buttons.fontsel $bottom.buttons.smileys -side left
		pack $bottom.buttons.block $bottom.buttons.sendfile $bottom.buttons.invite -side right
		
		#send chatwindowbutton postevent
		set evpar(bottom) $bottom.buttons
		set evpar(window_name) ".${win_name}"
		::plugins::PostEvent chatwindowbutton evPar
		
		# Remove thin border on Mac OS X to improve the appearance (padx)
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			pack .${win_name}.f.top -side top -fill x -padx 0 -pady 0
		} else {
			pack .${win_name}.f.top -side top -fill x -padx 3 -pady 0
		}
			
		pack .${win_name}.statusbar -side bottom -fill x
		grid .${win_name}.statusbar.status -row 0 -column 0 -padx 0 -pady 0 -sticky we

		if { [::config::getKey charscounter] } {
			grid .${win_name}.statusbar.charstyped -row 0 -column 0 -padx 0 -pady 0 -sticky e
		}

		grid columnconfigure .${win_name}.statusbar 0 -weight 1
		grid columnconfigure .${win_name}.statusbar 1
		grid $bottom.in -row 1 -column 0 -padx 3 -pady 3 -sticky nsew
		grid $bottom.buttons -row 0 -column 0 -padx 3 -pady 0 -sticky ewns
		grid column $bottom 0 -weight 1

		#Remove thin border on Mac OS X (padx)
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
				pack .${win_name}.f.out -expand true -fill both -padx 0 -pady 0
			} else {
				pack .${win_name}.f.out -expand true -fill both -padx 3 -pady 0
			}
		
		pack .${win_name}.f.top.textto -side left -fill y -anchor nw -padx 0 -pady 3
		pack .${win_name}.f.top.text -side left -expand true -fill x -padx 4 -pady 3

		pack .${win_name}.f.bottom -side top -expand false -fill x -padx 0 -pady 0

		pack $bottom.in.f.send -fill both -expand true
		pack $bottom.in.input -side left -expand true -fill both -padx 1 -pady 1
		pack $bottom.in.f -side left -fill y -padx 3 -pady 4

		pack .${win_name}.f -expand true -fill both -padx 0 -pady 0

		.${win_name}.f.top.text configure -state disabled
		.${win_name}.f.out.text configure -state disabled
		.${win_name}.statusbar.status configure -state disabled
		.${win_name}.statusbar.charstyped configure -state disabled
		.${win_name}.f.out.text tag configure green -foreground darkgreen -background white -font sboldf
		.${win_name}.f.out.text tag configure red -foreground red -background white -font sboldf
		.${win_name}.f.out.text tag configure blue -foreground blue -background white -font sboldf
		.${win_name}.f.out.text tag configure gray -foreground #404040 -background white -font splainf
		.${win_name}.f.out.text tag configure gray_italic -foreground #000000 -background white -font sbolditalf
		.${win_name}.f.out.text tag configure white -foreground white -background black -font sboldf
		.${win_name}.f.out.text tag configure url -foreground #000080 -background white -font splainf -underline true
		$bottom.in.f.send configure -state disabled
		$bottom.in.input configure -state normal
		
		bind $bottom.in.input <Tab> "focus $bottom.in.f.send; break"
		bind  $bottom.buttons.smileys  <Button1-ButtonRelease> "::smiley::smileyMenu %X %Y $bottom.in.input"
		bind  $bottom.buttons.fontsel  <Button1-ButtonRelease> "after 1 change_myfont ${win_name}"
		bind  $bottom.buttons.block  <Button1-ButtonRelease> \
			"::amsn::ShowChatList \"[trans block]/[trans unblock]\" .${win_name} ::amsn::blockUnblockUser"
		bind $bottom.buttons.sendfile <Button1-ButtonRelease> "::amsn::FileTransferSend .${win_name}"
		bind $bottom.buttons.invite <Button1-ButtonRelease> "::amsn::ShowInviteMenu .${win_name} %X %Y"
		bind $bottom.in.f.send <Return> "::amsn::MessageSend .${win_name} $bottom.in.input; break"
		bind $bottom.in.input <Shift-Return> {%W insert insert "\n"; %W see insert; break}
		bind $bottom.in.input <Control-KP_Enter> {%W insert insert "\n"; %W see insert; break}
		bind $bottom.in.input <Shift-KP_Enter> {%W insert insert "\n"; %W see insert; break}

		# Change shortcuts on Mac OS X (TKAqua). ALT=Option Control=Command on Mac
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $bottom.in.input <Command-Return> {%W insert insert "\n"; %W see insert; break}
			bind $bottom.in.input <Command-Option-space> BossMode
			bind $bottom.in.input <Command-a> {%W tag add sel 1.0 {end - 1 chars};break}
		} else {
			bind $bottom.in.input <Control-Return> {%W insert insert "\n"; %W see insert; break}
			bind $bottom.in.input <Control-Alt-space> BossMode
			bind $bottom.in.input <Control-a> {%W tag add sel 1.0 {end - 1 chars};break}
		}

		bind $bottom.in.input <<Button3>> "tk_popup .${win_name}.copypaste %X %Y"
		bind $bottom.in.input <<Button2>> "paste .${win_name} 1"
		bind .${win_name}.f.out.text <<Button3>> "tk_popup .${win_name}.copy %X %Y"

		# Do not bind copy command on button 1 on Mac OS X 
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			# Do nothing
		} else {
			bind .${win_name}.f.out.text <Button1-ButtonRelease> "copy 0 .${win_name}"
		}

		# When someone type something in out.text, regive the focus to in.input and insert that key
		bind .${win_name}.f.out.text <KeyPress> "lastKeytyped %A $bottom"

		#Define this events, in case they were not defined by Tk
		event add <<Paste>> <Control-v> <Control-V>
		event add <<Copy>> <Control-c> <Control-C>
		event add <<Cut>> <Control-x> <Control-X>

		bind .${win_name} <<Cut>> "status_log cut\n;tk_textCut .${win_name}"
		bind .${win_name} <<Copy>> "status_log copy\n;tk_textCopy .${win_name}"
		bind .${win_name} <<Paste>> "status_log paste\n;tk_textPaste .${win_name}"

		#Change shortcut for history on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind .${win_name} <Command-Option-h> \
				"::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin"
		} else {
			bind .${win_name} <Control-h> \
				"::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin"
		}

		bind .${win_name} <Destroy> "window_history clear %W; ::ChatWindow::Closed .${win_name} %W"
		focus $bottom.in.input

		# Sets the font size to the one stored in our configuration file
		change_myfontsize [::config::getKey textsize] .${win_name}

		#TODO: We always want these menus and bindings enabled? Think it!!
		$bottom.in.input configure -state normal
		$bottom.in.f.send configure -state normal
		.${win_name}.menu.msn entryconfigure 3 -state normal
		.${win_name}.menu.actions entryconfigure 5 -state normal

		#Better binding, works for Tk 8.4 only (see proc tification too)
		if { [catch {
			$bottom.in.input edit modified false
			bind $bottom.in.input <<Modified>> "::amsn::TypingNotification .${win_name} $bottom.in.input"
		} res]} {
			#If fails, fall back to 8.3
			bind $bottom.in.input <Key> "::amsn::TypingNotification .${win_name} $bottom.in.input"
			bind $bottom.in.input <Key-Meta_L> "break;"
			bind $bottom.in.input <Key-Meta_R> "break;"
			bind $bottom.in.input <Key-Alt_L> "break;"
			bind $bottom.in.input <Key-Alt_R> "break;"
			bind $bottom.in.input <Key-Control_L> "break;"
			bind $bottom.in.input <Key-Control_R> "break;"
			bind $bottom.in.input <Key-Return> "break;"
		}

		bind $bottom.in.input <Key-Delete> "::amsn::DeleteKeyPressed .${win_name} $bottom.in.input %K"
		bind $bottom.in.input <Key-BackSpace> "::amsn::DeleteKeyPressed .${win_name} $bottom.in.input %K"
		bind $bottom.in.input <Key-Up> {my_TextSetCursor %W [::amsn::UpKeyPressed %W]; break}
		bind $bottom.in.input <Key-Down> {my_TextSetCursor %W [::amsn::DownKeyPressed %W]; break}
		bind $bottom.in.input <Shift-Key-Up> {my_TextKeySelect %W [::amsn::UpKeyPressed %W]; break}
		bind $bottom.in.input <Shift-Key-Down> {my_TextKeySelect %W [::amsn::DownKeyPressed %W]; break}

		global skipthistime
		set skipthistime 0

		bind $bottom.in.input <Return> "window_history add %W; ::amsn::MessageSend .${win_name} %W; break"
		bind $bottom.in.input <Key-KP_Enter> "window_history add %W; ::amsn::MessageSend .${win_name} %W; break"
		bind .${win_name} <<Escape>> "::ChatWindow::Close .${win_name}; break"

		#Different shortcuts on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $bottom.in.input <Control-s> "window_history add %W; ::amsn::MessageSend .${win_name} %W; break"
			bind .${win_name} <Command-,> "Preferences"
			bind all <Command-q> {
				close_cleanup;exit
			}
			bind $bottom.in.input <Command-Up> "window_history previous %W; break"
			bind $bottom.in.input <Command-Down> "window_history next %W; break"
		} else {
			bind $bottom.in.input <Alt-s> "window_history add %W; ::amsn::MessageSend .${win_name} %W; break"
			bind $bottom.in.input <Control-Up> "window_history previous %W; break"
			bind $bottom.in.input <Control-Down> "window_history next %W; break"
		}

		#Added to stop amsn freezing when control-up pressed in the output window
		#If you can find why it is freezing and can stop it remove this line
		bind .${win_name}.f.out.text <Control-Up> "break"

		# Set the properties of this chat window in our ::ChatWindow namespace
		# variables to be accessible from other procs in the namespace
		set ::ChatWindow::titles(.${win_name}) ""
		set ::ChatWindow::first_message(.${win_name}) 1
		set ::ChatWindow::recent_message(.${win_name}) 0
		lappend ::ChatWindow::windows ".${win_name}"

		# These bindings are handlers for closing the window (Leave the SB, store settings...)
		bind .${win_name} <Configure> "::ChatWindow::Configured .${win_name}"
		wm protocol .${win_name} WM_DELETE_WINDOW "::ChatWindow::Close .${win_name}"
 
		# PostEvent 'new_chatwindow' to notify plugins that the window was created
		set evPar(win) ".${win_name}"
		::plugins::PostEvent new_chatwindow evPar

		wm state .${win_name} withdraw
		return ".${win_name}"
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::SetFor (chatid, window)
	# Sets the specified window to be the one which will show messages and information
	# for the chat names 'chatid'
	# Arguments:
	#  - chatid => Is the chat id of the window, the passport account of the buddy
	#  - window => Is the window widget to be assigned (.msg_n - Where n is an integer)
	proc SetFor { chatid window } {
		if {$chatid != ""} {
			set ::ChatWindow::msg_windows($chatid) $window
			set ::ChatWindow::chat_ids($window) $chatid
		}
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Status (window, msg, [icon ""])
	# Writes the message $msg in the status bar of the window $window. It will add
	# the icon $icon at the beginning of the message, if specified.
	# Arguments:
	#  - window => Is the window widget focused (.msg_n - Where n is an integer)
	#  - msg => The status message that will be showed in the status bar of $window
	#  - [icon ""] => [NOT REQUIRED] The icon that will be at left of the message
	proc Status { win_name msg {icon ""}} {
		set msg [string map {"\n" " "} $msg]

		if { [winfo exists $win_name] } {

			${win_name}.statusbar.status configure -state normal
			${win_name}.statusbar.status delete 0.0 end

			if { "$icon"!=""} {
				${win_name}.statusbar.status image create end -image [::skin::loadPixmap $icon] -pady 0 -padx 1
			}

			${win_name}.statusbar.status insert end $msg
			${win_name}.statusbar.status configure -state disabled

		}
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::TopUpdate (chatid)
	# Gets the users in 'chatid' from the protocol layer, and updates the top of the
	# window with the user names and states.
	# Arguments:
	#  - chatid => Is the chat id of the window, the passport account of the buddy
	proc TopUpdate { chatid } {
		if { [::ChatWindow::For $chatid] == 0 } {
			return 0
		}

		set title ""
		set user_list [::MSN::usersInChat $chatid]

		if {[llength $user_list] == 0} {
			return 0
		}

		set win_name [::ChatWindow::For $chatid]

		if { [lindex [${win_name}.f.out.text yview] 1] > 0.95 } {
		   set scrolling 1
		} else {
		   set scrolling 0
		}

		${win_name}.f.top.text configure -state normal -font sboldf -height 1 -wrap none
		${win_name}.f.top.text delete 0.0 end

		foreach user_login $user_list {
			set user_name [string map {"\n" " "} [::abook::getDisplayNick $user_login]]
			set state_code [::abook::getVolatileData $user_login state]
			
			if { $state_code == "" } {
				set user_state ""
				set state_code FLN
			} else {
				set user_state [::MSN::stateToDescription $state_code]
			}

			set user_image [::MSN::stateToImage $state_code]

			if {[::config::getKey truncatenames]} {
				#Calculate maximum string width
				set maxw [winfo width ${win_name}.f.top.text]

				if { "$user_state" != "" && "$user_state" != "online" } {
					incr maxw [expr 0-[font measure sboldf -displayof ${win_name}.f.top.text " \([trans $user_state]\)"]]
				}

				incr maxw [expr 0-[font measure sboldf -displayof ${win_name}.f.top.text " <${user_login}>"]]
				${win_name}.f.top.text insert end "[trunc ${user_name} ${win_name} $maxw sboldf] <${user_login}>"
			} else {
				${win_name}.f.top.text insert end "${user_name} <${user_login}>"
			}

			set title "${title}${user_name}, "

			#TODO: When we have better, smaller and transparent images, uncomment this
			#${win_name}.f.top.text image create end -image [::skin::loadPixmap $user_image] -pady 0 -padx 2

			if { "$user_state" != "" && "$user_state" != "online" } {
				${win_name}.f.top.text insert end "\([trans $user_state]\)"
			}
			${win_name}.f.top.text insert end "\n"
		}

		set title [string replace $title end-1 end " - [trans chat]"]

		#Calculate number of lines, and set top text size
		set size [${win_name}.f.top.text index end]
		set posyx [split $size "."]
		set lines [expr {[lindex $posyx 0] - 2}]
		set ::ChatWindow::titles(${win_name}) ${title}
		
		${win_name}.f.top.text delete [expr {$size - 1.0}] end
		${win_name}.f.top.text configure -state normal -font sboldf -height $lines -wrap none
		${win_name}.f.top.text configure -state disabled

		if { [info exists ::ChatWindow::new_message_on(${win_name})] && $::ChatWindow::new_message_on(${win_name}) == 1 } {
			wm title ${win_name} "*${title}"
		} else {
			wm title ${win_name} ${title}
		}

		if { $scrolling } { ${win_name}.f.out.text yview end }

		update idletasks

		after cancel "::ChatWindow::TopUpdate $chatid"
		after 5000 "::ChatWindow::TopUpdate $chatid"

	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::UnsetFor (chatid, window)
	# Tells the GUI system that window $window is no longer available for $chatid
	# Arguments:
	#  - chatid => Is the chat id of the window, the passport account of the buddy
	#  - window => Is the window widget assigned (.msg_n - Where n is an integer)
	proc UnsetFor {chatid window} {
		if {[info exists ::ChatWindow::msg_windows($chatid)]} {
			unset ::ChatWindow::msg_windows($chatid)
			unset ::ChatWindow::chat_ids($window)
		}
	}
	#///////////////////////////////////////////////////////////////////////////////
}
