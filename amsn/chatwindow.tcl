#########################################
#    Chat Window code abstraction       #
#           By Alberto D�z             #
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
	# ::ChatWindow::GetTopText (window)
	# Returns the path to the output text widget in a given window 
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc GetTopText { window } {
		return $window.f.out.scroll.text
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Clear (window)
	# Deletes all the text in the chat window's input widget
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc Clear { window } {
		[::ChatWindow::GetTopText $window] configure -state normal
		[::ChatWindow::GetTopText $window] delete 0.0 end
		[::ChatWindow::GetTopText $window] configure -state disabled
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
		#only run this if the window is the outer window
		if { ![string equal $window [winfo toplevel $window]]} { return }

		set chatid [::ChatWindow::Name $window]

		if { $chatid != 0 } {
			after cancel "::ChatWindow::TopUpdate $chatid"
			after 200 "::ChatWindow::TopUpdate $chatid"
		}

		if { [::config::getKey savechatwinsize] } {
			set geometry [wm geometry $window]
			set pos_start [string first "+" $geometry]

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
						load [file join utils windows winflash flash.dll]
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
		global  HOME tcl_platform

		set w [CreateTopLevelWindow]

		# Test on Mac OS X(TkAqua) if ImageMagick is installed   
		if {$tcl_platform(os) == "Darwin"} {
			if { [::config::getKey getdisppic] != 0 } {
				check_imagemagick
			}
		}

		set mainmenu [CreateMainMenu $w]
		$w conf -menu $mainmenu

		set copypastemenu [CreateCopyPasteMenu $w]
		set copymenu [CreateCopyMenu $w]

		
		#Send a postevent for the creation of menu
		set evPar(window_name) "$w"
		set evPar(menu_name) "$mainmenu"
		::plugins::PostEvent chatmenu evPar

		# Create the window's elements
		set top [CreateTopFrame $w]
		set statusbar [CreateStatusBar $w]
		set paned [CreatePanedWindow $w]

		# Pack them

		# Remove thin border on Mac OS X to improve the appearance (padx)
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			pack $top -side top -expand false -fill x -padx 0 -pady 0
			pack $statusbar -side bottom -expand false -fill x
			pack $paned -side top -expand true -fill both -padx 0 -pady 0
		} else {
			pack $top -side top -expand false -fill x -padx [::skin::getColor chatpadx] -pady [::skin::getColor chatpady]
			pack $statusbar -side bottom -expand false -fill x
			pack $paned -side top -expand true -fill both -padx [::skin::getColor chatpadx] -pady 0
		}

		focus $paned

		# Sets the font size to the one stored in our configuration file
		change_myfontsize [::config::getKey textsize] $w


		# Set the properties of this chat window in our ::ChatWindow namespace
		# variables to be accessible from other procs in the namespace
		set ::ChatWindow::titles($w) ""
		set ::ChatWindow::first_message($w) 1
		set ::ChatWindow::recent_message($w) 0
		lappend ::ChatWindow::windows "$w"

		#bind on configure for saving the window shape
		bind $w <Configure> "::ChatWindow::Configured %W"

		# PostEvent 'new_chatwindow' to notify plugins that the window was created
		set evPar(win) "$w"
		::plugins::PostEvent new_chatwindow evPar

		wm state $w withdraw
		return "$w"
	}
	#///////////////////////////////////////////////////////////////////////////////


	###################################################
	# CreateTopLevelWindow
	# This proc should create the toplevel window for a chat window
	# configure it and then return it's pathname
	#
	proc CreateTopLevelWindow { } {
		global tcl_platform
		set w ".msg_$::ChatWindow::winid"
		incr ::ChatWindow::winid

		toplevel $w -class Amsn

		# If there isn't a configured size for Chat Windows, use the default one and store it.
		if {[catch { wm geometry $w [::config::getKey winchatsize] } res]} {
			wm geometry $w 350x390
			::config::setKey winchatsize 350x390
			status_log "No config(winchatsize). Setting default size for chat window\n" red
		}

		if {$tcl_platform(platform) == "windows"} {
		    wm geometry $w +0+0
		}

		if { [winfo exists .bossmode] } {
			set ::BossMode($w) "iconic"
			wm state $w withdraw
		} else {
			wm state $w iconic
		}

		wm title $w "[trans chat]"
		wm group $w .

		# If the platform is NOT windows, set the windows' icon to our xbm
		if {$tcl_platform(platform) != "windows"} {
			catch {wm iconbitmap $w @[GetSkinFile pixmaps amsn.xbm]}
			catch {wm iconmask $w @[GetSkinFile pixmaps amsnmask.xbm]}
		}


		# Create the necessary bindings
		bind $w <<Cut>> "status_log cut\n;tk_textCut $w"
		bind $w <<Copy>> "status_log copy\n;tk_textCopy $w"
		bind $w <<Paste>> "status_log paste\n;tk_textPaste $w"

		#Change shortcut for history on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $w <Command-Option-h> \
				"::amsn::ShowChatList \"[trans history]\" $w ::log::OpenLogWin"
		} else {
			bind $w <Control-h> \
				"::amsn::ShowChatList \"[trans history]\" $w ::log::OpenLogWin"
		}

		bind $w <<Escape>> "::ChatWindow::Close $w; break"
		bind $w <Destroy> "window_history clear %W; ::ChatWindow::Closed $w %W"

		#Different shortcuts on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $w <Command-,> "Preferences"
			bind all <Command-q> {
				close_cleanup;exit
			}
		}


		# These bindings are handlers for closing the window (Leave the SB, store settings...)
		wm protocol $w WM_DELETE_WINDOW "::ChatWindow::Close $w"


		return $w

	}


	#############################################
	# CreateMainMenu $w
	# This proc should create the main menu of the chat window
	# it only creates the menu supposed to appear in the menu bar actually
	#
	proc CreateMainMenu { w } {

		set mainmenu $w.menu	

		menu $mainmenu -tearoff 0 -type menubar -borderwidth 0 -activeborderwidth -0

		set msnmenu [CreateMsnMenu $w $mainmenu]
		set editmenu [CreateEditMenu $w $mainmenu]
		set viewmenu [CreateViewMenu $w $mainmenu]
		set actionsmenu [CreateActionsMenu $w $mainmenu]
		set applemenu [CreateAppleMenu $mainmenu]


		# Change MSN menu's caption on Mac for "File" to match the Apple UI Standard
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			$mainmenu add cascade -label "[trans file]" -menu $msnmenu
		} else {
			$mainmenu add cascade -label "[trans msn]" -menu $msnmenu
		}

		$mainmenu add cascade -label "[trans edit]" -menu $editmenu
		$mainmenu add cascade -label "[trans view]" -menu $viewmenu
		$mainmenu add cascade -label "[trans actions]" -menu $actionsmenu

		# Apple menu, only on Mac OS X for legacy reasons (Each OS X app have one Apple menu)
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			$mainmenu add cascade -label "Apple" -menu $applemenu
		}

		#TODO: We always want these menus and bindings enabled? Think it!!
		$msnmenu entryconfigure 3 -state normal
		$actionsmenu entryconfigure 5 -state normal


		return $mainmenu
	}


	#############################################
	# CreateAppleMenu $menu
	# This proc should create the Apple submenu of the chat window
	#
	proc CreateAppleMenu { menu } {
		set applemenu $menu.apple
		menu $applemenu -tearoff 0 -type normal
		$applemenu add command -label "[trans about] aMSN" \
		    -command ::amsn::aboutWindow
		$applemenu add separator
		$applemenu add command -label "[trans preferences]..." \
		    -command Preferences -accelerator "Command-,"
		$applemenu add separator

		return $applemenu
	}

	#############################################
	# CreateMsnMenu $menu
	# This proc should create the Amsn submenu of the chat window
	#
	proc CreateMsnMenu { w menu } {
		global files_dir

		set msnmenu $menu.msn
		menu $msnmenu -tearoff 0 -type normal

		$msnmenu add command -label "[trans savetofile]..." \
		    -command " ChooseFilename [::ChatWindow::GetTopText $w] $w"
		$msnmenu add separator
		$msnmenu add command -label "[trans sendfile]..." \
		    -command "::amsn::FileTransferSend $w"
		$msnmenu add command -label "[trans openreceived]..." \
		    -command "launch_filemanager \"$files_dir\""
		$msnmenu add separator
		
		#Add accelerator label to "close" on Mac Version
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			$msnmenu add command -label "[trans close]" \
			    -command "destroy $w" -accelerator "Command-W"
		} else {
			$msnmenu add command -label "[trans close]" \
			    -command "destroy $w"
		}

		return $msnmenu
		
	}
	

	#############################################
	# CreateEditMenu $menu
	# This proc should create the Edit submenu of the chat window
	#
	proc CreateEditMenu { w menu } {

		set editmenu $menu.edit

		menu $editmenu -tearoff 0 -type normal

		#Change the accelerator on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			$editmenu add command -label "[trans cut]" \
				-command "tk_textCut $w" -accelerator "Command+X"
			$editmenu add command -label "[trans copy]" \
				-command "tk_textCopy $w" -accelerator "Command+C"
			$editmenu add command -label "[trans paste]" \
				-command "tk_textPaste $w" -accelerator "Command+V"
		} else {
			$editmenu add command -label "[trans cut]" \
				-command "tk_textCut $w" -accelerator "Ctrl+X"
			$editmenu add command -label "[trans copy]" \
				-command "tk_textCopy $w" -accelerator "Ctrl+C"
			$editmenu add command -label "[trans paste]" \
				-command "tk_textPaste $w" -accelerator "Ctrl+V"
		}
		
		$editmenu add separator
		$editmenu add command -label "[trans clear]" -command [list ::ChatWindow::Clear $w]

		return $editmenu
	}


	#############################################
	# CreateViewMenu $menu
	# This proc should create the View submenu of the chat window
	#
	proc CreateViewMenu { w menu } {
		global ${w}_show_picture

		set viewmenu $menu.view
		menu $viewmenu -tearoff 0 -type normal

		$viewmenu add cascade -label "[trans textsize]" -menu [CreateTextSizeMenu $viewmenu]
		$viewmenu add separator
		$viewmenu add checkbutton -label "[trans chatsmileys]" \
			-onvalue 1 -offvalue 0 -variable [::config::getVar chatsmileys]

		set ${w}_show_picture 0
		
		$viewmenu add checkbutton -label "[trans showdisplaypic]" \
			-command "::amsn::ShowOrHidePicture $w" -onvalue 1 \
		    -offvalue 0 -variable "${w}_show_picture"
		$viewmenu add separator

		# Remove this menu item on Mac OS X because we "lost" the window instead
		# of just hide it and change accelerator for history on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			$viewmenu add command -label "[trans history]" \
				-command "::amsn::ShowChatList \"[trans history]\" $w ::log::OpenLogWin" \
				-accelerator "Command-Option-H"
		} else {
			$viewmenu add command -label "[trans history]" \
				-command "::amsn::ShowChatList \"[trans history]\" $w ::log::OpenLogWin" \
				-accelerator "Ctrl+H"
			$viewmenu add separator
			$viewmenu add command -label "[trans hidewindow]" \
				-command "wm state $w withdraw"
		}
		
		$viewmenu add separator
		$viewmenu add cascade -label "[trans style]" -menu [CreateStyleMenu $viewmenu]

		return $viewmenu
	}

	#############################################
	# CreateTextSizeMenu $menu
	# This proc should create the TextSize submenu of the View menu
	# of the chat window
	#
	proc CreateTextSizeMenu { menu } {
		set textsizemenu $menu.textsize
		menu $textsizemenu -tearoff 0 -type normal

		foreach size {8 6 4 2 1 0 -0 -2 } { 
			if {$size > 0 } {
				$textsizemenu add command -label "+$size" -command "change_myfontsize $size"
			} else {
				$textsizemenu add command -label "$size" -command "change_myfontsize $size"
			}
		}
		
		return $textsizemenu
	}

	#############################################
	# CreateStyleMenu $menu
	# This proc should create the Style submenu of the View menu
	# of the chat window
	#
	proc CreateStyleMenu { menu } { 

		set stylemenu $menu.style
		menu $stylemenu -tearoff 0 -type normal

		$stylemenu add radiobutton -label "[trans msnstyle]" \
			-value "msn" -variable [::config::getVar chatstyle]
		$stylemenu add radiobutton -label "[trans ircstyle]" \
			-value "irc" -variable [::config::getVar chatstyle]
		$stylemenu add radiobutton -label "[trans customstyle]..." \
			-value "custom" -variable [::config::getVar chatstyle] \
			-command "::amsn::enterCustomStyle"

		return $stylemenu

	}

	#############################################
	# CreateActionsMenu $menu
	# This proc should create the Actions submenu of the chat window
	#
	proc CreateActionsMenu { w menu } {
		set actionsmenu $menu.actions

		menu $actionsmenu -tearoff 0 -type normal

		$actionsmenu add command -label "[trans addtocontacts]" \
			-command "::amsn::ShowAddList \"[trans addtocontacts]\" $w ::MSN::addUser"
		$actionsmenu add command -label "[trans block]/[trans unblock]" \
			-command "::amsn::ShowChatList \"[trans block]/[trans unblock]\" $w ::amsn::blockUnblockUser"
		$actionsmenu add command -label "[trans viewprofile]" \
			-command "::amsn::ShowChatList \"[trans viewprofile]\" $w ::hotmail::viewProfile"
		$actionsmenu add command -label "[trans properties]" \
			-command "::amsn::ShowChatList \"[trans properties]\" $w ::abookGui::showUserProperties"
		$actionsmenu add separator
		$actionsmenu add command -label "[trans invite]..." \
			-command "::amsn::ShowInviteList \"[trans invite]\" $w"
		$actionsmenu add separator
		$actionsmenu add command -label [trans sendmail] \
			-command "::amsn::ShowChatList \"[trans sendmail]\" $w launch_mailer"

		return $actionsmenu
	}


	################################################
	# CreateCopyPasteMenu
	# This proc creates the menu shown when a user right clicks 
	# on the input of the chat window
	#
	proc CreateCopyPasteMenu { w } {
		set menu $w.copypaste

		menu $menu -tearoff 0 -type normal

		$menu add command -label [trans cut] \
			-command "status_log cut\n;tk_textCut $w"
		$menu add command -label [trans copy] \
			-command "status_log copy\n;tk_textCopy $w"
		$menu add command -label [trans paste] \
			-command "status_log paste\n;tk_textPaste $w"

		return $menu
	}
	
	################################################
	# CreateCopyMenu
	# This proc creates the menu shown when a user right clicks 
	# on the output of the chat window
	#
	proc CreateCopyMenu { w } {
		global xmms

		set menu $w.copy

		menu $menu -tearoff 0 -type normal

		$menu add command -label [trans copy] \
			-command "status_log copy\n;copy 0 $w"

		# Creates de XMMS extension's menu if the plugin is loaded
		if { [info exist xmms(loaded)] } {
			$menu add cascade -label "XMMS" -menu [CreateXmmsMenu $w $menu]

		}

		return $menu
	}

	################################################
	# CreateCopyMenu
	# This proc creates the Xmms submenu shown when a user right clicks 
	# on the output of the chat window if the plugin is loaded
	#
	proc CreateXmmsMenu { w menu } {
		set xmmsmenu $menu.xmms

		menu $xmmsmenu -tearoff 0 -type normal
		$xmmsmenu add command -label [trans xmmscurrent] -command "xmms $w 1"
		$xmmsmenu add command -label [trans xmmssend] -command "xmms $w 2"	
		return $xmmsmenu
	}

	###################################################
	# CreateTopFrame
	# This proc creates the top frame of a chatwindow
	#
	proc CreateTopFrame { w } {

		# set our widget's names
		set top $w.top
		set to $top.to
		set text $top.text

		# Create our frame
		frame $top -class amsnChatFrame -relief solid -borderwidth [::skin::getColor chatborders] -background [::skin::getColor topbarbg]
		
		# Create the to widget
		text $to  -borderwidth 0 -width [string length "[trans to]:"] \
		    -relief solid -height 1 -wrap none -background [::skin::getColor topbarbg] \
		    -foreground [::skin::getColor topbartext] -highlightthickness 0 \
		    -selectbackground [::skin::getColor topbarbg] -selectforeground [::skin::getColor topbartext] \
		    -selectborderwidth 0 -exportselection 0 -padx 5 -pady 3
		
		# Configure it
		$to configure -state normal -font bplainf
		$to insert end "[trans to]:"
		$to configure -state disabled

		# Create the text widget
		text $text  -borderwidth 0 -width 45 -relief flat -height 1 -wrap none \
			-background [::skin::getColor topbarbg] -foreground [::skin::getColor topbartext] \
			-highlightthickness 0 -selectbackground [::skin::getColor topbarbg] -selectborderwidth 0 \
			-selectforeground [::skin::getColor topbartext] -exportselection 1
		
		# Configure it
		$text configure -state disabled


		# Pack our widgets
		pack $to -side left -expand false -anchor w -padx 0 -pady 3
		pack $text -side right -expand true -fill x -anchor e -padx 4 -pady 3

		return $top
	}


	###################################################
	# CreateStatusBar
	# This proc creates the status bar of a chatwindow
	#
	proc CreateStatusBar { w } {
		
		# Name our widgets
		set statusbar $w.statusbar
		set status $statusbar.status
		set charstyped $statusbar.charstyped

		#Create the frame
		frame $statusbar -class Amsn -borderwidth [::skin::getColor chatborders] -relief solid -background [::skin::getColor statusbarbg]

		#Create text insert frame
		text $status  -width 5 -height 1 -wrap none \
			-font bplainf -borderwidth 0 -background [::skin::getColor statusbarbg] -foreground [::skin::getColor statusbartext]\
			-highlightthickness 0 -selectbackground [::skin::getColor statusbarbg] -selectborderwidth 0 \
			-selectforeground [::skin::getColor statusbartext] -exportselection 1 -pady 4
		text $charstyped  -width 4 -height 1 -wrap none \
			-font splainf -borderwidth 0 -background [::skin::getColor statusbarbg] -foreground [::skin::getColor statusbartext]\
			-highlightthickness 0 -selectbackground [::skin::getColor statusbarbg] -selectborderwidth 0 \
			-selectforeground [::skin::getColor statusbartext] -exportselection 1 -pady 4


		# Configure them
		$charstyped tag configure center -justify left
		$status configure -state disabled
		$charstyped configure -state disabled

		# Pack them
		pack $w.statusbar.status -side left -expand true -fill x -padx 0 -pady 0 -anchor w

		if { [::config::getKey charscounter] } {
			pack $charstyped -side right -expand false -padx 0 -pady 0 -anchor e
		}

		return $statusbar
	}

	proc CreatePanedWindow { w } {
		
		set paned $w.f
		if { $::tcl_version >= 8.4 } {
			panedwindow $paned -background [::skin::getColor chatwindowbg] -borderwidth 0 -relief flat -orient vertical ;#-opaqueresize true -showhandle false
		} else {
			frame $paned -background [::skin::getColor chatwindowbg] -borderwidth 0 -relief flat 
		}
		set output [CreateOutputWindow $w $paned]
		set input [CreateInputWindow $w $paned]

		if { $::tcl_version >= 8.4 } {
			$paned add $output $input
			$paned paneconfigure $output -minsize 50 -height 200
			$paned paneconfigure $input -minsize 100 -height 120
		} else {
			#Remove thin border on Mac OS X (padx)
			if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
				pack $output -expand true -fill both -padx 0 -pady 0
			} else {
				pack $output -expand true -fill both -padx 3 -pady 0
			}

			pack $input -side top -expand true -fill both -padx 0 -pady [::skin::getColor chatpady]
		}

		# Bind on focus, so we always put the focus on the input window
		bind $paned <FocusIn> "focus $input"
		if { $::tcl_version >= 8.4 } {
			bind $input <Configure> "::ChatWindow::InputPaneConfigured $paned $input $output %W %h"
			bind $paned <Configure> "::ChatWindow::PanedWindowConfigured $paned $input $output %W %h"
		}

		return $paned

	}

	proc InputPaneConfigured { paned input output W newh } {
		#only run this if the window is the outer frame
		if { ![string equal $input $W]} { return }

		if { [::config::getKey savechatwinsize] } {
			::config::setKey winchatoutheight [winfo height $output]
		}
	}

	proc PanedWindowConfigured { paned input output W newh } {
		#only run this if the window is the outer frame
		if { ![string equal $paned $W]} { return }

		#keep the input pane the same size, only change the output		
		#dont call the first time it is created
		#as the input size hasnt been checked yet
		if { [info exists ::panedsize($paned)] } {
			#ensure that the input window is minimum size if there is room for it
			if { [winfo height $input] < [$paned panecget $input -minsize] } {
				$paned sash mark 0 0 [$paned panecget $input -minsize]
				$paned sash dragto 0 0 [winfo height $input]
				incr ::panedsize($paned) [$paned panecget $input -minsize]
				incr ::panedsize($paned) -[winfo height $input]
			}
			$paned sash mark 0 0 $::panedsize($paned)
			$paned sash dragto 0 0 $newh
		}
		
		set ::panedsize($paned) $newh
	}

	proc CreateOutputWindow { w paned } {
		
		# Name our widgets
		set fr $paned.out
		set out $fr.scroll
		set text $out.text
		
		# Widget name from another proc
		set bottom $paned.bottom

		# Create the widgets
		frame $fr -class Amsn -borderwidth 0 -relief solid \
			-background [::skin::getColor chatwindowbg] -height [::config::getKey winchatoutheight]
		ScrolledWindow $out -auto vertical -scrollbar vertical
		text $text -borderwidth [::skin::getColor chatborders] -foreground white -background white -width 45 -height 3 \
			-setgrid 0 -wrap word -exportselection 1  -relief solid -highlightthickness 0 -selectborderwidth 1

		$out setwidget $text
		pack $out -expand true -fill both -padx 0 -pady 0

		# Configure our widgets
		$text configure -state disabled
		$text tag configure green -foreground darkgreen -background white -font sboldf
		$text tag configure red -foreground red -background white -font sboldf
		$text tag configure blue -foreground blue -background white -font sboldf
		$text tag configure gray -foreground #404040 -background white -font splainf
		$text tag configure gray_italic -foreground #000000 -background white -font sbolditalf
		$text tag configure white -foreground white -background black -font sboldf
		$text tag configure url -foreground #000080 -background white -font splainf -underline true

		# Create our bindings
		bind $text <<Button3>> "tk_popup $w.copy %X %Y"

		# Do not bind copy command on button 1 on Mac OS X 
		if {![catch {tk windowingsystem} wsystem] && $wsystem != "aqua"} {
			bind $text <Button1-ButtonRelease> "copy 0 $w"
		}

		# When someone type something in out.text, regive the focus to in.input and insert that key
		bind $text <KeyPress> "lastKeytyped %A $bottom"


		#Added to stop amsn freezing when control-up pressed in the output window
		#If you can find why it is freezing and can stop it remove this line
		bind $text <Control-Up> "break"

		return $fr
	}

	proc CreateInputWindow { w paned } {

		status_log "Creating input frame\n"
		# Name our widgets
		set bottom $paned.bottom
		set leftframe $bottom.left

		# Create the bottom frame widget
		frame $bottom -class Amsn -borderwidth 0 -relief solid \
			-background [::skin::getColor chatwindowbg]
		

		# Create The left frame
		frame $leftframe -class Amsn -background [::skin::getColor chatwindowbg] -relief solid -borderwidth 0

		# Create the other widgets for the bottom frame
		set buttons [CreateButtonBar $w $leftframe]
		set input [CreateInputFrame $w $leftframe]
		set picture [CreatePictureFrame $w $bottom]

		pack $buttons -side top -expand false -fill x -padx [::skin::getColor chatpadx] -pady 0 -anchor n
		pack $input -side top -expand true -fill both -padx [::skin::getColor chatpadx] -pady [::skin::getColor chatpady] -anchor n
		pack $leftframe -side left -expand true -fill both -padx [::skin::getColor chatpadx] -pady [::skin::getColor chatpady]
		pack $picture -side right -expand false -padx [::skin::getColor chatpadx] -pady 0 -anchor ne

		# Bind the focus
		bind $bottom <FocusIn> "focus $input"

		return $bottom

	}

	proc CreateInputFrame { w bottom} { 
		global tcl_platform

		# Name our widgets
		set input $bottom.in
		set sendbutton $input.send
		set text $input.text


		# Create The input frame
		frame $input -class Amsn -background [::skin::getColor buttonbarbg] -relief solid -borderwidth [::skin::getColor chatborders]
		
		# Create the text widget and the send button widget
		text $text -background white -width 15 -height 3 -wrap word -font bboldf \
			-borderwidth 0 -relief solid -highlightthickness 0 -exportselection 1
		
		# Send button in conversation window, specifications and command. Only
		# compatible with Tcl/Tk 8.4. Disable it on Mac OS X (TkAqua looks better)
		if { $::tcl_version >= 8.4 && $tcl_platform(os) != "Darwin" } {
			# New pixmap-skinnable button (For Windows and Unix > Tcl/Tk 8.3)
			button $sendbutton -image [::skin::loadPixmap sendbutton] \
				-command "::amsn::MessageSend $w $text" \
				-fg black -bg white -bd 0 -relief flat -overrelief flat \
				-activebackground white -activeforeground #8c8c8c -text [trans send] \
				-font sboldf -compound center -highlightthickness 0 -height 2
		} else {
			# Standard grey flat button (For Tcl/Tk < 8.4 and Mac OS X)
			button $sendbutton  -text [trans send] -width 6 -borderwidth 1 \
				-relief solid -command "::amsn::MessageSend $w $text" \
				-font bplainf -highlightthickness 0 -highlightbackground [::skin::getColor chatwindowbg] -height 2
		}


		# Configure my widgets
		$sendbutton configure -state normal
		$text configure -state normal

		# Create my bindings
		bind $text <Tab> "focus $sendbutton; break"
		bind $sendbutton <Return> "::amsn::MessageSend $w $text; break"
		#Don't insert picture if TCL 8.3 or Mac OS X because it's the old-style button
		if { $::tcl_version >= 8.4 && $tcl_platform(os) != "Darwin" } {
			bind $sendbutton <Enter> "$sendbutton configure -image [::skin::loadPixmap sendbutton_hover]"
			bind $sendbutton <Leave> "$sendbutton configure -image [::skin::loadPixmap sendbutton]"
		}
		bind $text <Shift-Return> {%W insert insert "\n"; %W see insert; break}
		bind $text <Control-KP_Enter> {%W insert insert "\n"; %W see insert; break}
		bind $text <Shift-KP_Enter> {%W insert insert "\n"; %W see insert; break}

		# Change shortcuts on Mac OS X (TKAqua). ALT=Option Control=Command on Mac
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $text <Command-Return> {%W insert insert "\n"; %W see insert; break}
			bind $text <Command-Option-space> BossMode
			bind $text <Command-a> {%W tag add sel 1.0 {end - 1 chars};break}
		} else {
			bind $text <Control-Return> {%W insert insert "\n"; %W see insert; break}
			bind $text <Control-Alt-space> BossMode
			bind $text <Control-a> {%W tag add sel 1.0 {end - 1 chars};break}
		}

		bind $text <<Button3>> "tk_popup $w.copypaste %X %Y"
		bind $text <<Button2>> "paste $w 1"

		#Better binding, works for Tk 8.4 only (see proc tification too)
		if { [catch {
			$text edit modified false
			bind $text <<Modified>> "::amsn::TypingNotification $w $text"
		} res]} {
			#If fails, fall back to 8.3
			bind $text <Key> "::amsn::TypingNotification $w $text"
			bind $text <Key-Meta_L> "break;"
			bind $text <Key-Meta_R> "break;"
			bind $text <Key-Alt_L> "break;"
			bind $text <Key-Alt_R> "break;"
			bind $text <Key-Control_L> "break;"
			bind $text <Key-Control_R> "break;"
			bind $text <Key-Return> "break;"
		}

		bind $text <Key-Delete> "::amsn::DeleteKeyPressed $w $text %K"
		bind $text <Key-BackSpace> "::amsn::DeleteKeyPressed $w $text %K"
		bind $text <Key-Up> {my_TextSetCursor %W [::amsn::UpKeyPressed %W]; break}
		bind $text <Key-Down> {my_TextSetCursor %W [::amsn::DownKeyPressed %W]; break}
		bind $text <Shift-Key-Up> {my_TextKeySelect %W [::amsn::UpKeyPressed %W]; break}
		bind $text <Shift-Key-Down> {my_TextKeySelect %W [::amsn::DownKeyPressed %W]; break}

		global skipthistime
		set skipthistime 0

		bind $text <Return> "window_history add %W; ::amsn::MessageSend $w %W; break"
		bind $text <Key-KP_Enter> "window_history add %W; ::amsn::MessageSend $w %W; break"

		#Different shortcuts on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $text <Control-s> "window_history add %W; ::amsn::MessageSend $w %W; break"
			bind $text <Command-Up> "window_history previous %W; break"
			bind $text <Command-Down> "window_history next %W; break"
		} else {
			bind $text <Alt-s> "window_history add %W; ::amsn::MessageSend $w %W; break"
			bind $text <Control-Up> "window_history previous %W; break"
			bind $text <Control-Down> "window_history next %W; break"
		}

		bind $input <FocusIn> "focus $text"


		# Pack My input frame widgets
		pack $text -side left -expand true -fill both -padx 1 -pady 1
		if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
			pack $sendbutton -side left -padx [::skin::getColor chatpadx] -pady 4	
		} else {
			pack $sendbutton -fill y -side left -padx [::skin::getColor chatpadx] -pady 4	
		}
		
		return $input
	}

	proc CreateButtonBar { w bottom } {

		status_log "Creating button bar\n"
		# Name our widgets
		set buttons $bottom.buttons
		set smileys $buttons.smileys
		set fontsel $buttons.fontsel
		set block $buttons.block
		set sendfile $buttons.sendfile
		set invite $buttons.invite

		# widget name from another proc
		set input $bottom.in.text


		# Create them along with their respective tooltips
		frame $buttons -class Amsn -borderwidth [::skin::getColor chatborders] -relief solid -background [::skin::getColor buttonbarbg]	

		#Smiley button
		button $smileys  -image [::skin::loadPixmap butsmile] -relief flat -padx 5 \
			-background [::skin::getColor buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getColor buttonbarbg]  -activebackground [::skin::getColor buttonbarbg]
		set_balloon $smileys [trans insertsmiley]

		#Font button
		button $fontsel -image [::skin::loadPixmap butfont] -relief flat -padx 5 \
			-background [::skin::getColor buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getColor buttonbarbg] -activebackground [::skin::getColor buttonbarbg]
		set_balloon $fontsel [trans changefont]
		
		#Block button
		button $block -image [::skin::loadPixmap butblock] -relief flat -padx 5 \
			-background [::skin::getColor buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getColor buttonbarbg] -activebackground [::skin::getColor buttonbarbg]
		set_balloon $block [trans block]
		
		#Send file button
		button $sendfile -image [::skin::loadPixmap butsend] -relief flat -padx 5 \
			-background [::skin::getColor buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getColor buttonbarbg] -activebackground [::skin::getColor buttonbarbg]
		set_balloon $sendfile [trans sendfile]

		#Invite another contact button
		button $invite -image [::skin::loadPixmap butinvite] -relief flat -padx 5 \
			-background [::skin::getColor buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getColor buttonbarbg] -activebackground [::skin::getColor buttonbarbg]
		set_balloon $invite [trans invite]

		# Pack them
		pack $fontsel $smileys -side left -pady 2
		pack $block $sendfile $invite -side right -pady 2

		# Configure our commands for onclick
		$smileys  configure -command "::smiley::smileyMenu \[winfo pointerx $w\] \[winfo pointery $w\] $input"
		$fontsel  configure -command "after 1 change_myfont [string range $w 1 end]"
		$block    configure -command "::amsn::ShowChatList \"[trans block]/[trans unblock]\" $w ::amsn::blockUnblockUser"
		$sendfile configure -command "::amsn::FileTransferSend $w"
		$invite   configure -command "::amsn::ShowInviteMenu $w \[winfo pointerx $w\] \[winfo pointery $w\]"

		# Create our bindings
		bind  $smileys  <Enter> "$smileys configure -image [::skin::loadPixmap butsmile_hover]"
		bind  $smileys  <Leave> "$smileys configure -image [::skin::loadPixmap butsmile]"
		bind  $fontsel  <Enter> "$fontsel configure -image [::skin::loadPixmap butfont_hover]"
		bind  $fontsel  <Leave> "$fontsel configure -image [::skin::loadPixmap butfont]"
		bind $block <Enter> "$block configure -image [::skin::loadPixmap butblock_hover]"
		bind $block <Leave> "$block configure -image [::skin::loadPixmap butblock]"
		bind $sendfile <Enter> "$sendfile configure -image [::skin::loadPixmap butsend_hover]"
		bind $sendfile <Leave> "$sendfile configure -image [::skin::loadPixmap butsend]"
		bind $invite <Enter> "$invite configure -image [::skin::loadPixmap butinvite_hover]"
		bind $invite <Leave> "$invite configure -image [::skin::loadPixmap butinvite]"
		
		#send chatwindowbutton postevent
		set evpar(bottom) $buttons
		set evpar(window_name) "$w"
		::plugins::PostEvent chatwindowbutton evPar

		return $buttons
	}

	proc CreatePictureFrame { w bottom } {

		status_log "Creating picture frame\n"
		# Name our widgets
		set frame $bottom.pic
		set picture $frame.image
		set showpic $frame.showpic

		# Create them
		frame $frame -class Amsn -borderwidth 0 -relief solid -background [::skin::getColor chatwindowbg]
		label $picture -borderwidth 1 -relief solid -image [::skin::getNoDisplayPicture] -background [::skin::getColor chatwindowbg]

		set_balloon $picture [trans nopic]
		button $showpic -bd 0 -padx 0 -pady 0 -image [::skin::loadPixmap imgshow] \
			-bg [::skin::getColor chatwindowbg] -highlightthickness 0 -font splainf \
			-command "::amsn::ToggleShowPicture $w; ::amsn::ShowOrHidePicture $w" \
			-highlightbackground [::skin::getColor chatwindowbg] -activebackground [::skin::getColor chatwindowbg]
		set_balloon $showpic [trans showdisplaypic]

		# Pack them 
		#pack $picture -side left -padx 0 -pady [::skin::getColor chatpady] -anchor w
		pack $showpic -side right -expand true -fill y -padx 0 -pady [::skin::getColor chatpady] -anchor e

		# Create our bindings
		bind $picture <Button1-ButtonRelease> "::amsn::ShowPicMenu $w %X %Y\n"
		bind $picture <<Button3>> "::amsn::ShowPicMenu $w %X %Y\n"


		# This proc is called to load the Display Picture if exists and is readable
		load_my_pic

		return $frame

	}

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

		if { [lindex [[::ChatWindow::GetTopText ${win_name}] yview] 1] > 0.95 } {
		   set scrolling 1
		} else {
		   set scrolling 0
		}

		${win_name}.top.text configure -state normal -font sboldf -height 1 -wrap none
		${win_name}.top.text delete 0.0 end

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
				set maxw [winfo width ${win_name}.top.text]

				if { "$user_state" != "" && "$user_state" != "online" } {
					incr maxw [expr 0-[font measure sboldf -displayof ${win_name}.top.text " \([trans $user_state]\)"]]
				}

				incr maxw [expr 0-[font measure sboldf -displayof ${win_name}.top.text " <${user_login}>"]]
				${win_name}.top.text insert end "[trunc ${user_name} ${win_name} $maxw sboldf] <${user_login}>"
			} else {
				${win_name}.top.text insert end "${user_name} <${user_login}>"
			}

			set title "${title}${user_name}, "

			#TODO: When we have better, smaller and transparent images, uncomment this
			#${win_name}.top.text image create end -image [::skin::loadPixmap $user_image] -pady 0 -padx 2

			if { "$user_state" != "" && "$user_state" != "online" } {
				${win_name}.top.text insert end "\([trans $user_state]\)"
			}
			${win_name}.top.text insert end "\n"
		}
		
		#Change color of top background by the status of the contact
		ChangeColorState $user_list $user_state $state_code ${win_name}

		set title [string replace $title end-1 end " - [trans chat]"]

		#Calculate number of lines, and set top text size
		set size [${win_name}.top.text index end]
		set posyx [split $size "."]
		set lines [expr {[lindex $posyx 0] - 2}]
		set ::ChatWindow::titles(${win_name}) ${title}
		
		${win_name}.top.text delete [expr {$size - 1.0}] end
		${win_name}.top.text configure -state normal -font sboldf -height $lines -wrap none
		${win_name}.top.text configure -state disabled

		if { [info exists ::ChatWindow::new_message_on(${win_name})] && $::ChatWindow::new_message_on(${win_name}) == 1 } {
			wm title ${win_name} "*${title}"
		} else {
			wm title ${win_name} ${title}
		}

		if { $scrolling } { [::ChatWindow::GetTopText ${win_name}] yview end }

		#PostEvent 'TopUpdate'
		set evPar(chatid) "chatid"
		set evPar(win_name) "win_name"
		set evPar(user_list) "user_list"
		::plugins::PostEvent TopUpdate evPar

		update idletasks

		after cancel "::ChatWindow::TopUpdate $chatid"
		after 5000 "::ChatWindow::TopUpdate $chatid"

	}
	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::ChangeColorState {user_list user_state state_code win_name}
	# Change the color of the top window when the other contact is in another status
	proc ChangeColorState {user_list user_state state_code win_name} {
		#get the colour for the state
		set colour [::skin::getColor topbarbg]
		set tcolour [::skin::getColor topbartext]
		if { ([llength $user_list] == 1) && ("$user_state" != "" ) } {
			if { ($state_code == "IDL") || ($state_code == "BRB") || ($state_code == "AWY") || ($state_code == "LUN") } {
				set colour [::skin::getColor topbarawaybg]
				set tcolour [::skin::getColor topbarawaytext]
			} elseif { ($state_code == "PHN") || ($state_code == "BSY") } {
				set colour [::skin::getColor topbarbusybg]
				set tcolour [::skin::getColor topbarbusytext]
			} elseif { ($state_code == "FLN") } {
				set colour [::skin::getColor topbarofflinebg]
				set tcolour [::skin::getColor topbarofflinetext]
			}
		}
		#set the areas to the colour
		${win_name}.top configure -background $colour
		${win_name}.top.to configure -background $colour -foreground $tcolour \
						-selectbackground $colour -selectforeground $tcolour
		${win_name}.top.text configure -background $colour -foreground $tcolour \
						-selectbackground $colour -selectforeground $tcolour
	}

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
