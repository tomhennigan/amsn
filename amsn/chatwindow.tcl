#########################################
#    Chat Window code abstraction       #
#           By Alberto D�z            #
#########################################

package require framec

namespace eval ::ChatWindow {

	#///////////////////////////////////////////////////////////////////////////////
	# Namespace variables, relative to chat windows' data. In the code are accessible
	# through '::namespace::variable' syntax (to avoid local instances of the variable
	# and have the scope more clear).

	# As ::ChatWindow::winid is the index used in the
	# window widgets for chat windows, we only initialize
	# it at the first time, to avoid problems with proc
	# reload_files wich will cause some bugs related to
	# winid being 0 after some windows have been created.
	if { $initialize_amsn == 1  } {
		variable chat_ids
		variable first_message
		variable msg_windows
		variable new_message_on
		variable recent_message
		variable titles
		variable windows [list]
		variable winid 0
		variable containers
		variable containerwindows
		variable tab2win
		variable win2tab
		variable containercurrent
		variable containerid 0
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
	# ::ChatWindow::GetTopFrame (window)
	# Returns the path to the top frame (containing "To: ...") for a given window 
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc GetTopFrame { window } {
		return $window.top
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::GetTopToText (window)
	# Returns the path to the text widget containing the "To:" in the top frame
	# for a given window 
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc GetTopToText { window } {
		return [[::ChatWindow::GetTopFrame $window] getinnerframe].to
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::GetTopText (window)
	# Returns the path to the text widget containing the names of the users in the top frame
	# for a given window 
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc GetTopText { window } {
		return [[::ChatWindow::GetTopFrame $window] getinnerframe].text
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::GetOutText (window)
	# Returns the path to the output text widget in a given window 
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc GetOutText { window } {
		return $window.f.out.scroll.text
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::GetInputText (window)
	# Returns the path to the input text widget in a given window 
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc GetInputText { window } {
		return [$window.f.bottom.left.in getinnerframe].text
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::GetStatusText (window)
	# Returns the path to the statusbar text widget in a given window 
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc GetStatusText { window } {
		return [$window.statusbar getinnerframe].status
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::GetStatusCharsTypedText (window)
	# Returns the path to the statusbar text widget in a given window 
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc GetStatusCharsTypedText { window } {
		return [$window.statusbar getinnerframe].charstyped
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Clear (window)
	# Deletes all the text in the chat window's input widget
	# Arguments:
	#  - window => Is the chat window widget (.msg_n - Where n is an integer)
	proc Clear { window } {
		set window [::ChatWindow::getCurrentTab $window]
		[::ChatWindow::GetOutText $window] configure -state normal
		[::ChatWindow::GetOutText $window] delete 0.0 end
		[::ChatWindow::GetOutText $window] configure -state disabled
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

	proc ContainerClose { window } {
		variable win2tab

		set current [GetCurrentWindow $window]
		set currenttab [set win2tab($current)]

		if { [::ChatWindow::CountTabs $window] == 1 } {
			::ChatWindow::CloseTab $currenttab
			return
		}
		
		set nodot [string map { "." "_"} $window]
		set w .close$nodot

		if { [winfo exists $w] } {
			raise $w
			return
		}

		toplevel $w
		#label $w.l -text "[trans detachall]"
		label $w.l -text "[trans closeall]"
		set f $w.f
		frame $f
		button $f.yes -text "[trans yes]" -command "::ChatWindow::CloseAll $window; destroy $window; destroy $w"
		button $f.no -text "[trans no]" -command "::ChatWindow::CloseTab $currenttab; destroy $w" 
		button $f.cancel -text "[trans cancel]" -command "destroy $w"
		pack $f.yes $f.no $f.cancel -side left
		pack $w.l $w.f -side top
	}

	proc DetachAll { w } {
		variable containerwindows
		variable containers
		variable containercurrent

		if {![info exists containerwindows($w)] || [winfo toplevel $w] != $w} {
			return
		}

		status_log "detaching containerwindows $w\n" red
		foreach window [set containerwindows($w)] {
			status_log "destroy $window\n" red
			DetachTab [set ::ChatWindow::win2tab($window)]
		}

		status_log "unsetting containerwindow and containercurrent\n" red
		unset containerwindows($w)
		unset containercurrent($w)

		status_log "unsetting containers array...\n" red
		foreach { key value } [array get containers] {
			if { $value == $w } {
				status_log "found containers $key $value\n" red
				unset containers($key)
			}
		}

		destroy $w
		
	}

	proc CountTabs { w } {
		return [llength [set ::ChatWindow::containerwindows($w)]]
	}

	proc CloseAll { w } {
		variable containerwindows
		variable containers
		variable containercurrent

		if {![info exists containerwindows($w)] || [winfo toplevel $w] != $w} {
			return
		}

		status_log "destroying containerwindows $w\n" red
		foreach window [set containerwindows($w)] {
			status_log "destroy $window\n" red
			destroy $window
		}

		status_log "unsetting containerwindow and containercurrent\n" red
		unset containerwindows($w)
		unset containercurrent($w)

		status_log "unsetting containers array...\n" red
		foreach { key value } [array get containers] {
			if { $value == $w } {
				status_log "found containers $key $value\n" red
				unset containers($key)
			}
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

	proc ContainerConfigured { window } {
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

			::config::setKey wincontainersize  [string range $geometry 0 [expr {$pos_start-1}]]
		}
		if { [winfo exists ${window}.bar] } {
			CheckForTooManyTabs $window
		}
	}

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
			if { [winfo exists $chatid] } { 
				set window $chatid
			} else {
				return 0
			}
		}

		set container [GetContainerFromWindow $window]
		if { $container != "" } {
			FlickerTab $window 
			Flicker $container
			return
		}

		if { [::config::getKey flicker] == 0 } {
			if { [string first $window [focus]] != 0 } {
				catch {wm title ${window} "*$::ChatWindow::titles($window)"} res
				set ::ChatWindow::new_message_on(${window}) "asterisk"
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
			set ::ChatWindow::new_message_on(${window}) "flicker"
			
		} else {

			catch {wm title ${window} "$::ChatWindow::titles($window)"} res
			catch {unset ::ChatWindow::new_message_on(${window})}
			
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
			$::ChatWindow::new_message_on(${window}) == "asterisk" } {
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
 	proc MacPosition { window } {
 		#To know where the window manager want to put the window in X and Y
 		set window [winfo toplevel $window]
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
			if { [UseContainer] == 0 } {
				set win_name [::ChatWindow::Open]
				::ChatWindow::SetFor $chatid $win_name
			} else {
				set container [::ChatWindow::GetContainerFor $chatid]
				set win_name [::ChatWindow::Open $container]
				::ChatWindow::SetFor $chatid $win_name
				::ChatWindow::NameTabButton $win_name [::abook::getDisplayNick $chatid]
				set_balloon $::ChatWindow::win2tab($win_name) "[::abook::getDisplayNick $chatid]"

			}
			#update idletasks
			::ChatWindow::TopUpdate $chatid

			if { [::config::getKey showdisplaypic] && $usr_name != ""} {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name]
			} else {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name] nopack
			}
		}

		set top_win [winfo toplevel $win_name]
		status_log "TopLevel window: $top_win, Name: $win_name, State: [wm state $top_win]\n"

		# PostEvent 'new_conversation' to notify plugins that the window was created
		if { $::ChatWindow::first_message($win_name) == 1 } {
			set evPar(chatid) $chatid
			set evPar(usr_name) $usr_name
			::plugins::PostEvent new_conversation evPar
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
					wm state ${top_win} withdraw
				} else {
					wm state ${top_win} normal
				}

				wm deiconify ${top_win}

				if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
					lower ${top_win}
					::ChatWindow::MacPosition ${top_win}
				} else {
					raise ${top_win}
				}

			} else {
				# Iconify the window unless it was raised by the user already.
				if { [wm state $top_win] != "normal" } {
					if { [winfo exists .bossmode] } {
						set ::BossMode(${top_win}) "iconic"
						wm state ${top_win} withdraw
					} else {
						wm state ${top_win} iconic
					}
				}
			}
		} elseif { $msg == "" } {
			#If it's not a message event, then it's a window creation (user joins to chat)
			if { [::config::getKey newchatwinstate] == 0 } {
				if { [winfo exists .bossmode] } {
					set ::BossMode(${top_win}) "normal"
					wm state ${top_win} withdraw
				} else {
					wm state ${top_win} normal
				}

				wm deiconify ${top_win}

				#To have the new window "behind" on Mac OS X
				if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
					lower ${top_win}
					::ChatWindow::MacPosition ${top_win}
				} else {
					raise ${top_win}
				}

			} else {
				#Container for tabs might be non-iconified
				if { [wm state $top_win] != "normal" } {
					if { [winfo exists .bossmode] } {
						set ::BossMode(${top_win}) "iconic"
						wm state ${top_win} withdraw
					} else {
						wm state ${top_win} iconic
					}
				}
			}
		}

		#If no focus, and it's a message event, do something to the window
		if { (([::config::getKey soundactive] == "1" && $usr_name != [::config::getKey login]) || \
			[string first ${win_name} [focus]] != 0) && $msg != "" } {
			status_log "Win name: $win_name. Focus: [focus]\n" white
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


	#TODO: Deprecated, remove?
	proc TabbedWindowsInfo { } {
		set w .tabbedinfo

		if { [winfo exists $w] } {
			tkwait window $w
			return
		}
		toplevel $w

		label $w.l -text "[trans newtabbedfeature]"
		set f $w.f
		frame $f 
		radiobutton $f.r1 -text "[trans tabbedglobal]" -variable [::config::getVar tabbedchat] -value 1
		radiobutton $f.r2 -text "[trans tabbedgroups]" -variable [::config::getVar tabbedchat] -value 2
		radiobutton $f.r3 -text "[trans nottabbed]" -variable [::config::getVar tabbedchat] -value 0
																							   

		button $w.ok -text "[trans ok]" -command "destroy $w"

		::config::setKey tabbedchat 2
		
		pack $f.r1 $f.r2 $f.r3 -side top -expand true -fill both -anchor nw
		pack $w.l $w.f $w.ok -side top -expand true -fill both
		
		tkwait window $w

		return
	}


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Open () 
	# Creates a new chat window and returns its name (.msg_n - Where n is winid)
	proc Open { {container ""} } {
		global  HOME tcl_platform


		if { [UseContainer] == 0 || $container == "" } {
			set w [CreateTopLevelWindow]
	
			set mainmenu [CreateMainMenu $w]
			$w conf -menu $mainmenu
			
			#Send a postevent for the creation of menu
			set evPar(window_name) "$w"
			set evPar(menu_name) "$mainmenu"
			::plugins::PostEvent chatmenu evPar

			#bind on configure for saving the window shape
			bind $w <Configure> "::ChatWindow::Configured %W"

			wm state $w withdraw
		} else {
			set w [CreateTabbedWindow $container]
		} 

		set copypastemenu [CreateCopyPasteMenu $w]
		set copymenu [CreateCopyMenu $w]

		# Test on Mac OS X(TkAqua) if ImageMagick is installed   
		if {$tcl_platform(os) == "Darwin"} {
			if { [::config::getKey getdisppic] != 0 } {
				check_imagemagick
			}
		}

		# Create the window's elements
		set top [CreateTopFrame $w]
		set statusbar [CreateStatusBar $w]
		set paned [CreatePanedWindow $w]

		# Pack them

		pack $top -side top -expand false -fill x -padx [::skin::getKey chat_top_padx]\
		 -pady [::skin::getKey chat_top_pady]
		pack $statusbar -side bottom -expand false -fill x -padx [::skin::getKey chat_status_padx] -pady [::skin::getKey chat_status_pady]
		pack $paned -side top -expand true -fill both -padx [::skin::getKey chat_paned_padx]\
		 -pady [::skin::getKey chat_paned_pady]
		
		focus $paned

		# Sets the font size to the one stored in our configuration file
		change_myfontsize [::config::getKey textsize] $w


		# Set the properties of this chat window in our ::ChatWindow namespace
		# variables to be accessible from other procs in the namespace
		set ::ChatWindow::titles($w) ""
		set ::ChatWindow::first_message($w) 1
		set ::ChatWindow::recent_message($w) 0
		lappend ::ChatWindow::windows "$w"


		# PostEvent 'new_chatwindow' to notify plugins that the window was created
		set evPar(win) "$w"
		::plugins::PostEvent new_chatwindow evPar

		if { !([UseContainer] == 0 || $container == "" )} {
			AddWindowToContainer $container $w
		}

		return "$w"
	}
	#///////////////////////////////////////////////////////////////////////////////


	proc CreateNewContainer { } { 
		
		set container [CreateContainerWindow]
		set mainmenu [CreateMainMenu $container]
		$container conf -menu $mainmenu
		
		#Send a postevent for the creation of menu
		set evPar(window_name) "$container"
		set evPar(menu_name) "$mainmenu"
		::plugins::PostEvent chatmenu evPar
		
		
		#bind on configure for saving the window shape
		bind $container <Configure> "::ChatWindow::ContainerConfigured %W"

		set tabbar [CreateTabBar $container] 
		pack $tabbar -side top -fill both -expand false

		return $container

	}


	proc CreateTabBar { w } {
		set bar $w.bar
		::skin::setPixmap tab tab.gif
		::skin::setPixmap tab_hover tab_hover.gif
		::skin::setPixmap tab_current tab_current.gif
		::skin::setPixmap tab_flicker tab_flicker.gif
		::skin::setPixmap moretabs moretabs.gif
		::skin::setPixmap lesstabs lesstabs.gif

		frame $bar -class Amsn -relief solid -bg [::skin::getKey tabbarbg] -bd 0

		return $bar
	}

	###################################################
	# CreateContainerWindow
	# This proc should create the toplevel window for a chat window
	# container and configure it and then return it's pathname
	#
	proc CreateContainerWindow { } {
		global tcl_platform
			
		set w ".container_$::ChatWindow::containerid"
		incr ::ChatWindow::containerid
			
		toplevel $w -class Amsn -background [::skin::getKey chatwindowbg]	-borderwidth 0
		
		# If there isn't a configured size for Chat Windows, use the default one and store it.
		if {[catch { wm geometry $w [::config::getKey wincontainersize] } res]} {
			wm geometry $w 350x390
			::config::setKey wincontainersize 350x390
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
			catch {wm iconbitmap $w @[::skin::GetSkinFile pixmaps amsn.xbm]}
			catch {wm iconmask $w @[::skin::GetSkinFile pixmaps amsnmask.xbm]}
		}


		# Create the necessary bindings
		bind $w <<Cut>> "status_log cut\n;tk_textCut \[::ChatWindow::GetCurrentWindow $w\]"
		bind $w <<Copy>> "status_log copy\n;tk_textCopy \[::ChatWindow::GetCurrentWindow $w\]"
		bind $w <<Paste>> "status_log paste\n;tk_textPaste \[::ChatWindow::GetCurrentWindow $w\]"

		#Change shortcut for history on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $w <Command-Option-h> \
			    "::amsn::ShowChatList \"[trans history]\" \[::ChatWindow::GetCurrentWindow $w\] ::log::OpenLogWin"
		} else {
			bind $w <Control-h> \
			    "::amsn::ShowChatList \"[trans history]\" \[::ChatWindow::GetCurrentWindow $w\] ::log::OpenLogWin"
		}

		bind $w <<Escape>> "::ChatWindow::ContainerClose $w; break"
		bind $w <Destroy> "::ChatWindow::DetachAll %W"

		#Different shortcuts on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $w <Command-,> "Preferences"
			bind all <Command-q> {
				close_cleanup;exit
			}
		}


		# These bindings are handlers for closing the window (Leave the SB, store settings...)
		wm protocol $w WM_DELETE_WINDOW "::ChatWindow::ContainerClose $w"


		return $w
	}


	proc CreateTabbedWindow { container } {
		global tcl_platform

		set w "${container}.msg_${::ChatWindow::winid}"
		incr ::ChatWindow::winid

		status_log "tabbed window is : $w\n" red

		frame $w -background [::skin::getKey chatwindowbg]

		# If the platform is NOT windows, set the windows' icon to our xbm
		if {$tcl_platform(platform) != "windows"} {
			catch {wm iconbitmap $w @[::skin::GetSkinFile pixmaps amsn.xbm]}
			catch {wm iconmask $w @[::skin::GetSkinFile pixmaps amsnmask.xbm]}
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


		return $w

	}
	###################################################
	# CreateTopLevelWindow
	# This proc should create the toplevel window for a chat window
	# configure it and then return it's pathname
	#
	proc CreateTopLevelWindow { } {
		global tcl_platform
		
		set w ".msg_$::ChatWindow::winid"
		incr ::ChatWindow::winid
			
		toplevel $w -class Amsn -background [::skin::getKey chatwindowbg]	
		
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
			catch {wm iconbitmap $w @[::skin::GetSkinFile pixmaps amsn.xbm]}
			catch {wm iconmask $w @[::skin::GetSkinFile pixmaps amsnmask.xbm]}
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
		$actionsmenu entryconfigure 8 -state normal


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
		    -command " ChooseFilename \[::ChatWindow::GetOutText \[::ChatWindow::getCurrentTab $w\]\] \[::ChatWindow::getCurrentTab $w\]"
		$msnmenu add separator
		$msnmenu add command -label "[trans sendfile]..." \
		    -command "::amsn::FileTransferSend \[::ChatWindow::getCurrentTab $w\]"
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
				-command "tk_textCut \[::ChatWindow::getCurrentTab $w\]" -accelerator "Command+X"
			$editmenu add command -label "[trans copy]" \
				-command "tk_textCopy \[::ChatWindow::getCurrentTab $w\]" -accelerator "Command+C"
			$editmenu add command -label "[trans paste]" \
				-command "tk_textPaste \[::ChatWindow::getCurrentTab $w\]" -accelerator "Command+V"
		} else {
			$editmenu add command -label "[trans cut]" \
				-command "tk_textCut \[::ChatWindow::getCurrentTab $w\]" -accelerator "Ctrl+X"
			$editmenu add command -label "[trans copy]" \
				-command "tk_textCopy \[::ChatWindow::getCurrentTab $w\]" -accelerator "Ctrl+C"
			$editmenu add command -label "[trans paste]" \
				-command "tk_textPaste \[::ChatWindow::getCurrentTab $w\]" -accelerator "Ctrl+V"
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

		$viewmenu add cascade -label "[trans style]" -menu [CreateStyleMenu $viewmenu]
		$viewmenu add cascade -label "[trans textsize]" -menu [CreateTextSizeMenu $viewmenu]
		$viewmenu add separator
		$viewmenu add checkbutton -label "[trans chatsmileys]" \
			-onvalue 1 -offvalue 0 -variable [::config::getVar chatsmileys]

		set ${w}_show_picture 0
		
		$viewmenu add checkbutton -label "[trans showdisplaypic]" \
			-command "::amsn::ShowOrHidePicture \[::ChatWindow::getCurrentTab $w\]" -onvalue 1 \
		    -offvalue 0 -variable "${w}_show_picture"
		$viewmenu add separator

		# Remove this menu item on Mac OS X because we "lost" the window instead
		# of just hide it
		if {[catch {tk windowingsystem} wsystem] || $wsystem != "aqua"} {
			$viewmenu add command -label "[trans hidewindow]" \
				-command "wm state \[::ChatWindow::getCurrentTab $w\] withdraw"
		}
		
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
			-command "::amsn::ShowAddList \"[trans addtocontacts]\" \[::ChatWindow::getCurrentTab $w\] ::MSN::addUser"
		$actionsmenu add command -label "[trans block]/[trans unblock]" \
			-command "::amsn::ShowChatList \"[trans block]/[trans unblock]\" \[::ChatWindow::getCurrentTab $w\] ::amsn::blockUnblockUser"
		$actionsmenu add separator
		$actionsmenu add command -label "[trans viewprofile]" \
			-command "::amsn::ShowChatList \"[trans viewprofile]\" \[::ChatWindow::getCurrentTab $w\] ::hotmail::viewProfile"
											
		$actionsmenu add command -label "[trans properties]" \
			-command "::amsn::ShowChatList \"[trans properties]\" \[::ChatWindow::getCurrentTab $w\] ::abookGui::showUserProperties"
		$actionsmenu add command -label "[trans note]..." \
			-command "::amsn::ShowChatList \"[trans note]\" \[::ChatWindow::getCurrentTab $w\] ::notes::Display_Notes"
		# Change accelerator for history on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			$actionsmenu add command -label "[trans history]" \
				-command "::amsn::ShowChatList \"[trans history]\" \[::ChatWindow::getCurrentTab $w\] ::log::OpenLogWin" \
				-accelerator "Command-Option-H"
		} else {
			$actionsmenu add command -label "[trans history]" \
				-command "::amsn::ShowChatList \"[trans history]\" \[::ChatWindow::getCurrentTab $w\] ::log::OpenLogWin" \
				-accelerator "Ctrl+H"
		}
		$actionsmenu add separator
		$actionsmenu add command -label "[trans invite]..." \
			-command "::amsn::ShowInviteList \"[trans invite]\" \[::ChatWindow::getCurrentTab $w\]"
		$actionsmenu add separator
		$actionsmenu add command -label "[trans sendmail]..." \
			-command "::amsn::ShowChatList \"[trans sendmail]\" \[::ChatWindow::getCurrentTab $w\] launch_mailer"
		$actionsmenu add command -label "[trans sendfile]..." \
		    -command "::amsn::FileTransferSend \[::ChatWindow::getCurrentTab $w\]"

			
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

		set menu $w.copy

		menu $menu -tearoff 0 -type normal

		$menu add command -label [trans copy] \
			-command "status_log copy\n;copy 0 $w"
			
		return $menu
	}

	###################################################
	# CreateTopFrame
	# This proc creates the top frame of a chatwindow
	#
	proc CreateTopFrame { w } {

		# Create our frame
		set top $w.top
		framec $top -class amsnChatFrame -relief solid\
				-borderwidth [::skin::getKey chat_top_border] \
				-bordercolor [::skin::getKey topbarborder] \
				-background [::skin::getKey topbarbg]
		
		# set our inner widget's names
		set to [$top getinnerframe].to
		set text [$top getinnerframe].text

		# Create the to widget
		text $to  -borderwidth 0 -width [string length "[trans to]:"] \
		    -relief solid -height 1 -wrap none -background [::skin::getKey topbarbg] \
		    -foreground [::skin::getKey topbartext] -highlightthickness 0 \
		    -selectbackground [::skin::getKey topbarbg_sel] -selectforeground [::skin::getKey topbartext] \
		    -selectborderwidth 0 -exportselection 0 -padx 5 -pady 3
		
		# Configure it
		$to configure -state normal -font bplainf
		$to insert end "[trans to]:"
		$to configure -state disabled

		# Create the text widget
		text $text  -borderwidth 0 -width 45 -relief flat -height 1 -wrap none \
			-background [::skin::getKey topbarbg] -foreground [::skin::getKey topbartext] \
			-highlightthickness 0 -selectbackground [::skin::getKey topbarbg_sel] -selectborderwidth 0 \
			-selectforeground [::skin::getKey topbartext] -exportselection 1
		
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
		
		#Create the frame
		set statusbar $w.statusbar
		framec $statusbar -class Amsn -relief solid\
				-borderwidth [::skin::getKey chat_status_border] \
				-bordercolor [::skin::getKey chat_status_border_color] \
				-background [::skin::getKey statusbarbg]

		# set our inner widget's names
		set status [$statusbar getinnerframe].status
		set charstyped [$statusbar getinnerframe].charstyped

		#Create text insert frame
		text $status  -width 5 -height 1 -wrap none \
			-font bplainf -borderwidth 0 -background [::skin::getKey statusbarbg] -foreground [::skin::getKey statusbartext]\
			-highlightthickness 0 -selectbackground [::skin::getKey statusbarbg_sel] -selectborderwidth 0 \
			-selectforeground [::skin::getKey statusbartext] -exportselection 1 -pady 4
		text $charstyped  -width 4 -height 1 -wrap none \
			-font splainf -borderwidth 0 -background [::skin::getKey statusbarbg] -foreground [::skin::getKey statusbartext]\
			-highlightthickness 0 -selectbackground [::skin::getKey statusbarbg_sel] -selectborderwidth 0 \
			-selectforeground [::skin::getKey statusbartext] -exportselection 1 -pady 4


		# Configure them
		$charstyped tag configure center -justify left
		$status configure -state disabled
		$charstyped configure -state disabled

		# Pack them
		pack $status -side left -expand true -fill x -padx 0 -pady 0 -anchor w

		if { [::config::getKey charscounter] } {
			pack $charstyped -side right -expand false -padx 0 -pady 0 -anchor e
		}

		return $statusbar
	}

	proc CreatePanedWindow { w } {
		
		set paned $w.f
		if { $::tcl_version >= 8.4 } {
			panedwindow $paned -background [::skin::getKey chatwindowbg] -borderwidth 0 -relief flat -orient vertical ;#-opaqueresize true -showhandle false
		} else {
			frame $paned -background [::skin::getKey chatwindowbg] -borderwidth 0 -relief flat 
		}
		set output [CreateOutputWindow $w $paned]
		set input [CreateInputWindow $w $paned]

		if { $::tcl_version >= 8.4 } {
			$paned add $output $input
			$paned paneconfigure $output -minsize 50 -height 200
			$paned paneconfigure $input -minsize 100 -height 120
			$paned configure -showhandle [::skin::getKey chat_sash_showhandle] -sashpad [::skin::getKey chat_sash_pady]
		} else {
			pack $output -expand true -fill both -padx 0 -pady 0
			pack $input -side top -expand false -fill both -padx [::skin::getKey chat_input_padx]\
			 -pady [::skin::getKey chat_input_pady]
		}

		# Bind on focus, so we always put the focus on the input window
		bind $paned <FocusIn> "focus $input"

		bind $input <Configure> "::ChatWindow::InputPaneConfigured $paned $input $output %W %h"
		if { $::tcl_version >= 8.4 } {
			bind $output <Configure> "::ChatWindow::OutputPaneConfigured $paned $input $output %W %h"
			bind $paned <Configure> "::ChatWindow::PanedWindowConfigured $paned $input $output %W %h"
		}

		return $paned
	}


	proc GetSashHeight { paned } {
		set sashheight [expr { [$paned cget -sashpad ] + [$paned cget -sashwidth]}]
		if { [ $paned cget -showhandle ] } {
			set handleheight [expr { [$paned cget -sashpad ] + (([$paned cget -sashwidth]+1)/2) + ([$paned cget -handlesize]/2) }]
			if { $handleheight > $sashheight } {
				set sashheight $handleheight
			}
		}

		return $sashheight
	}

	proc SetSashPos { paned input output } {
		set bottomsize [winfo height $input]
		if { $bottomsize < [$paned panecget $input -minsize] } {
			set bottomsize [$paned panecget $input -minsize]
		}

		set sashheight [::ChatWindow::GetSashHeight $paned]

		$paned sash place 0 0 [expr {[winfo height $paned] - ($bottomsize + $sashheight)}]
	}

	proc InputPaneConfigured { paned input output W newh } {
		#only run this if the window is the outer frame
		if { ![string equal $input $W]} { return }

		set win [string first "msg" $paned]
		set win [string first "." $paned $win]
		incr win -1
		set win [string range $paned 0 $win]
		status_log "window is : $win\n"
		if { [lindex [[::ChatWindow::GetOutText $win] yview] 1] == 1.0 } {
			set scrolling 1
		} else {
			set scrolling 0
		}

		if { $::tcl_version >= 8.4 } {
			#check that the drag adhered to minsize input pane
			#first checking that there is enough room otherwise you get an infinite loop
			if { ( [winfo height $input] < [$paned panecget $input -minsize] ) \
					&& ( [winfo height $output] > [$paned panecget $output -minsize] ) \
					&& ( [winfo height $paned] > [$paned panecget $output -minsize] ) } {

				::ChatWindow::SetSashPos $paned $input $output
			}
		}


		if { $scrolling } { after 100 "catch {[::ChatWindow::GetOutText $win] yview end}" }


		if { [::config::getKey savechatwinsize] } {
			::config::setKey winchatoutheight [winfo height $output]
		}
	}

	# this proc is only needed when the sash is moved manually
	# and the input pane is off the screen so the obove doesnt get called
	proc OutputPaneConfigured { paned input output W newh } {
		#only run this if the window is the outer frame
		if { ![string equal $output $W]} { return }

		#only run if input frame not visible
		if { [winfo height $paned] <= [lindex [$paned sash coord 0] 1] + [::ChatWindow::GetSashHeight $paned] } {
		
			#check that the drag adhered to minsize for the input pane
			if { ( [winfo height $input] < [$paned panecget $input -minsize] ) \
					&& ( [winfo height $output] > [$paned panecget $output -minsize] ) \
					&& ( [winfo height $paned] > [$paned panecget $output -minsize] ) } {

				::ChatWindow::SetSashPos $paned $input $output
			}
		}
	}
	
	proc PanedWindowConfigured { paned input output W newh } {
		#only run this if the window is the outer frame
		if { ![string equal $paned $W]} { return }

		#keep the input pane the same size, only change the output		
		#dont call the first time it is created
		#as the input size hasnt been set yet
		if {([winfo height $input] != 1) || ([winfo height $output] != 1) } {
			::ChatWindow::SetSashPos $paned $input $output
		}
	}

	proc CreateOutputWindow { w paned } {
		
		# Name our widgets
		set fr $paned.out
		set out $fr.scroll
		set text $out.text

		# Create the widgets
		frame $fr -class Amsn -borderwidth 0 -relief solid \
			-background [::skin::getKey chatwindowbg] -height [::config::getKey winchatoutheight]
		ScrolledWindow $out -auto vertical -scrollbar vertical
		framec $text -type text -relief solid -foreground white -background white -width 45 -height 3 \
			-setgrid 0 -wrap word -exportselection 1 -highlightthickness 0 -selectborderwidth 1 \
			-borderwidth [::skin::getKey chat_output_border] \
			-bordercolor [::skin::getKey chat_output_border_color]
		set textinner [$text getinnerframe]

		$out setwidget $text


		pack $out -expand true -fill both \
			-padx [::skin::getKey chat_output_padx] \
			-pady [::skin::getKey chat_output_pady]
		

		# Configure our widgets
		$text configure -state disabled
		$text tag configure green -foreground darkgreen -font sboldf
		$text tag configure red -foreground red -font sboldf
		$text tag configure blue -foreground blue -font sboldf
		$text tag configure gray -foreground #404040 -font splainf
		$text tag configure gray_italic -foreground #000000 -background white -font sbolditalf
		$text tag configure white -foreground white -background black -font sboldf
		$text tag configure url -foreground #000080 -font splainf -underline true

		# Create our bindings
		bind $textinner <<Button3>> "tk_popup $w.copy %X %Y"

		# Do not bind copy command on button 1 on Mac OS X 
		if {![catch {tk windowingsystem} wsystem] && $wsystem != "aqua"} {
			bind $textinner <Button1-ButtonRelease> "copy 0 $w"
		}

		# When someone type something in out.text, regive the focus to in.input and insert that key
		bind $textinner <KeyPress> "::ChatWindow::lastKeytyped %A $w"


		#Added to stop amsn freezing when control-up pressed in the output window
		#If you can find why it is freezing and can stop it remove this line
		bind $textinner <Control-Up> "break"

		return $fr
	}

	#lastkeytyped 
	#Force the focus to the input text box when someone try to write something in the output
	proc lastKeytyped {typed w} {
		if {[regexp \[a-zA-Z\] $typed]} {
			focus -force [::ChatWindow::GetInputText $w]
			[::ChatWindow::GetInputText $w] insert insert $typed
		}
	}

	proc CreateInputWindow { w paned } {

		status_log "Creating input frame\n"
		# Name our widgets
		set bottom $paned.bottom
		set leftframe $bottom.left

		# Create the bottom frame widget
		frame $bottom -class Amsn -borderwidth 0 -relief solid \
			-background [::skin::getKey chatwindowbg]
		

		# Create The left frame
		frame $leftframe -class Amsn -background [::skin::getKey chatwindowbg] -relief solid -borderwidth 0

		# Create the other widgets for the bottom frame
		set input [CreateInputFrame $w $leftframe]
		set buttons [CreateButtonBar $w $leftframe]
		set picture [CreatePictureFrame $w $bottom]

		pack $buttons -side top -expand false -fill x -anchor n \
				-padx [::skin::getKey chat_buttons_padx] \
				-pady [::skin::getKey chat_buttons_pady]
		pack $input -side top -expand true -fill both -anchor n \
				-padx [::skin::getKey chat_input_padx] \
				-pady [::skin::getKey chat_input_pady]
		pack $leftframe -side left -expand true -fill both \
				-padx [::skin::getKey chat_leftframe_padx] \
				-pady [::skin::getKey chat_leftframe_pady]
		pack $picture -side right -expand false -anchor ne \
				-padx [::skin::getKey chat_dp_padx] \
				-pady [::skin::getKey chat_dp_pady]

		# Bind the focus
		bind $bottom <FocusIn> "focus $input"

		return $bottom

	}

	proc CreateInputFrame { w bottom} { 
		global tcl_platform

		# Create The input frame
		set input $bottom.in
		framec $input -class Amsn -relief solid \
				-background [::skin::getKey sendbuttonbg] \
				-borderwidth [::skin::getKey chat_input_border] \
				-bordercolor [::skin::getKey chat_input_border_color]
		
		# set our inner widget's names
		set sendbutton [$input getinnerframe].send
		set text [$input getinnerframe].text

		# Create the text widget and the send button widget
		text $text -background white -width 15 -height 3 -wrap word -font bboldf \
			-borderwidth 0 -relief solid -highlightthickness 0 -exportselection 1
		
		# Send button in conversation window, specifications and command. Only
		# compatible with Tcl/Tk 8.4. Disable it on Mac OS X (TkAqua looks better)
		if { ($::tcl_version >= 8.4) && ($tcl_platform(os) != "Darwin") } {
			# New pixmap-skinnable button (For Windows and Unix > Tcl/Tk 8.3)
			button $sendbutton -image [::skin::loadPixmap sendbutton] \
				-command "::amsn::MessageSend $w $text" \
				-fg black -bg [::skin::getKey sendbuttonbg] -bd 0 -relief flat \
				-activebackground [::skin::getKey sendbuttonbg] -activeforeground black -text [trans send] \
				-font sboldf -highlightthickness 0 -pady 0 -padx 0 -overrelief flat -compound center
		} else {
			# Standard grey flat button (For Tcl/Tk < 8.4 and Mac OS X)
			button $sendbutton  -text [trans send] -width 6 -borderwidth 1 \
				-relief solid -command "::amsn::MessageSend $w $text" \
				-font bplainf -highlightthickness 0 -highlightbackground [::skin::getKey sendbuttonbg]
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
		#Don't fill y on Mac OS X
		if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
			pack $sendbutton -side left -padx [::skin::getKey chat_sendbutton_padx]\
			-pady [::skin::getKey chat_sendbutton_pady]
		} else {
			pack $sendbutton -fill y -side left -padx [::skin::getKey chat_sendbutton_padx]\
			-pady [::skin::getKey chat_sendbutton_pady]
		}
		
		return $input
	}

	proc CreateButtonBar { w bottom } {

		status_log "Creating button bar\n"
		# create the frame
		set buttons $bottom.buttons
		framec $buttons -class Amsn -relief solid \
				-borderwidth [::skin::getKey chat_buttons_border] \
				-bordercolor [::skin::getKey chat_buttons_border_color] \
				-background [::skin::getKey buttonbarbg]	

		# Name our widgets
		set buttonsinner [$buttons getinnerframe]
		set smileys $buttonsinner.smileys
		set fontsel $buttonsinner.fontsel
		set block $buttonsinner.block
		set sendfile $buttonsinner.sendfile
		set invite $buttonsinner.invite

		# widget name from another proc
		set input [::ChatWindow::GetInputText $w]


		# Create them along with their respective tooltips

		#Smiley button
		button $smileys  -image [::skin::loadPixmap butsmile] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg]  -activebackground [::skin::getKey buttonbarbg]
		set_balloon $smileys [trans insertsmiley]

		#Font button
		button $fontsel -image [::skin::loadPixmap butfont] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $fontsel [trans changefont]
		
		#Block button
		button $block -image [::skin::loadPixmap butblock] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $block [trans block]
		
		#Send file button
		button $sendfile -image [::skin::loadPixmap butsend] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $sendfile [trans sendfile]

		#Invite another contact button
		button $invite -image [::skin::loadPixmap butinvite] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $invite [trans invite]

		# Pack them
		pack $fontsel $smileys -side left -padx 0 -pady 0
		pack $block $sendfile $invite -side right -padx 0 -pady 0

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
		set evPar(bottom) $buttonsinner
		set evPar(window_name) "$w"
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
		frame $frame -class Amsn -borderwidth 0 -relief solid -background [::skin::getKey chatwindowbg]
		framec $picture -type label -relief solid -image [::skin::getNoDisplayPicture] \
				-borderwidth [::skin::getKey chat_dp_border] \
				-bordercolor [::skin::getKey chat_dp_border_color] \
				-background [::skin::getKey chatwindowbg]
		set pictureinner [$picture getinnerframe]

		set_balloon $pictureinner [trans nopic]
		button $showpic -bd 0 -padx 0 -pady 0 -image [::skin::loadPixmap imgshow] \
			-bg [::skin::getKey chatwindowbg] -highlightthickness 0 -font splainf \
			-command "::amsn::ToggleShowPicture $w; ::amsn::ShowOrHidePicture $w" \
			-highlightbackground [::skin::getKey chatwindowbg] -activebackground [::skin::getKey chatwindowbg]
		set_balloon $showpic [trans showdisplaypic]

		# Pack them 
		#pack $picture -side left -padx 0 -pady [::skin::getKey chatpady] -anchor w
		pack $showpic -side right -expand true -fill y -padx 0 -pady 0 -anchor e

		# Create our bindings
		bind $pictureinner <Button1-ButtonRelease> "::amsn::ShowPicMenu $w %X %Y\n"
		bind $pictureinner <<Button3>> "::amsn::ShowPicMenu $w %X %Y\n"


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

			[::ChatWindow::GetStatusText ${win_name}] configure -state normal
			[::ChatWindow::GetStatusText ${win_name}] delete 0.0 end

			if { "$icon"!=""} {
				[::ChatWindow::GetStatusText ${win_name}] image create end -image [::skin::loadPixmap $icon] -pady 0 -padx 1
			}

			[::ChatWindow::GetStatusText ${win_name}] insert end $msg
			[::ChatWindow::GetStatusText ${win_name}] configure -state disabled

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
		set toptext [::ChatWindow::GetTopText ${win_name}]

		if { [lindex [[::ChatWindow::GetOutText ${win_name}] yview] 1] == 1.0 } {
		   set scrolling 1
		} else {
		   set scrolling 0
		}

		$toptext configure -state normal -font sboldf -height 1 -wrap none
		$toptext delete 0.0 end

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
				set maxw [winfo width $toptext]

				if { "$user_state" != "" && "$user_state" != "online" } {
					incr maxw [expr 0-[font measure sboldf -displayof $toptext " \([trans $user_state]\)"]]
				}

				incr maxw [expr 0-[font measure sboldf -displayof $toptext " <${user_login}>"]]
				$toptext insert end "[trunc ${user_name} ${win_name} $maxw sboldf] <${user_login}>"
			} else {
				$toptext insert end "${user_name} <${user_login}>"
			}

			set title "${title}${user_name}, "

			#TODO: When we have better, smaller and transparent images, uncomment this
			#$toptext image create end -image [::skin::loadPixmap $user_image] -pady 0 -padx 2

			if { "$user_state" != "" && "$user_state" != "online" } {
				$toptext insert end "\([trans $user_state]\)"
			}
			$toptext insert end "\n"
		}
		
		#Change color of top background by the status of the contact
		ChangeColorState $user_list $user_state $state_code ${win_name}

		set title [string replace $title end-1 end " - [trans chat]"]

		#Calculate number of lines, and set top text size
		set size [$toptext index end]
		set posyx [split $size "."]
		set lines [expr {[lindex $posyx 0] - 2}]
		set ::ChatWindow::titles(${win_name}) ${title}
		
		$toptext delete [expr {$size - 1.0}] end
		$toptext configure -state normal -font sboldf -height $lines -wrap none
		$toptext configure -state disabled

		if { [GetContainerFromWindow $win_name] == "" } {
			if { [info exists ::ChatWindow::new_message_on(${win_name})] && $::ChatWindow::new_message_on(${win_name}) == "asterisk" } {
				wm title ${win_name} "*${title}"
			} else {
				wm title ${win_name} ${title}
			}
		} else {
			NameTabButton $win_name $chatid
		}

		if { $scrolling } { catch {[::ChatWindow::GetOutText ${win_name}] yview end} }

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
		set colour [::skin::getKey topbarbg]
		set scolour [::skin::getKey topbarbg_sel]
		set tcolour [::skin::getKey topbartext]
		set bcolour [::skin::getKey topbarborder]
		if { ([llength $user_list] == 1) && ("$user_state" != "" ) } {
			if { ($state_code == "IDL") || ($state_code == "BRB") || ($state_code == "AWY") || ($state_code == "LUN") } {
				set colour [::skin::getKey topbarawaybg]
				set scolour [::skin::getKey topbarawaybg_sel]
				set tcolour [::skin::getKey topbarawaytext]
				set bcolour [::skin::getKey topbarawayborder]
			} elseif { ($state_code == "PHN") || ($state_code == "BSY") } {
				set colour [::skin::getKey topbarbusybg]
				set scolour [::skin::getKey topbarbusybg_sel]
				set tcolour [::skin::getKey topbarbusytext]
				set bcolour [::skin::getKey topbarbusyborder]
			} elseif { ($state_code == "FLN") } {
				set colour [::skin::getKey topbarofflinebg]
				set scolour [::skin::getKey topbarofflinebg_sel]
				set tcolour [::skin::getKey topbarofflinetext]
				set bcolour [::skin::getKey topbarofflineborder]
			}
		}
		#set the areas to the colour
		[::ChatWindow::GetTopFrame ${win_name}] configure -background $colour -bordercolor $bcolour
		[::ChatWindow::GetTopToText ${win_name}] configure -background $colour -foreground $tcolour \
						-selectbackground $scolour -selectforeground $tcolour
		[::ChatWindow::GetTopText ${win_name}] configure -background $colour -foreground $tcolour \
						-selectbackground $scolour -selectforeground $tcolour
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

	proc FlickerTab { win {new 1}} {
		variable win2tab
		variable winflicker
		variable visibletabs

		if { $win == 0 || ![info exists win2tab($win)] } { return }

		if { $win == [GetCurrentWindow [winfo toplevel $win]] } { return }

		#if tab is not visible, then we should change the color of the < or > button
		#to let know there is an invisible tab flickering (an incoming message)
		#if { ![info exists visibletabs($win)] } {
			#${containercurrent}.bar.less
			#${containercurrent}.bar.more
		#}

		set tab $win2tab($win)

		after cancel "::ChatWindow::FlickerTab $win 0"
		if { $new == 1 || ![info exists winflicker($win)]} {
			set winflicker($win) 0
		}

		set count [set winflicker($win)]

		if { [expr $count % 2] == 0 } {
			$tab configure -image [::skin::loadPixmap tab_flicker]
		} else {
			$tab configure -image [::skin::loadPixmap tab]	
		}

		incr winflicker($win)

		#if { $count > 10 } {
		#	$tab configure -image [::skin::loadPixmap tab_flicker]
		#	return
		#}

		#Check if the container window lost focus, then make it flicker:
		set container [GetContainerFromWindow $win]
		if { $container != "" } {
			if { ![info exists ::ChatWindow::new_message_on(${container})] &&
			     [string first $container [focus]] != 0 } {
			     Flicker $container
			}	
		}
		
		
		after 300 "::ChatWindow::FlickerTab $win 0"

	}


	proc GetContainerFor { user } {
		variable containers
		 
		if { [::config::getKey tabbedchat] == 1 } {
			if { [info exists containers(global)] && $containers(global) != ""} {
				return $containers(global)
			} else {
				set containers(global) [CreateNewContainer]
				return $containers(global)
			}

		} elseif { [::config::getKey tabbedchat] == 2 } {
			set gid "group[lindex [::abook::getContactData $user group] 0]"
			if { [info exists containers($gid)] && $containers($gid) != ""} {
				return $containers($gid)
			} else {
				set containers($gid) [CreateNewContainer]
				return $containers($gid)
			}
		} else {
			return ""
		}
		

	}

	proc AddWindowToContainer { container win } {
		variable containerwindows

		if { ![info exists containerwindows($container)] } {

			set tab [CreateTabButton $container $win]
			pack $tab -side left -expand false -fill both -anchor e

			set containerwindows($container) $win
			SwitchToTab $container $win
		} else {
			if { [lsearch [set containerwindows($container)] $win] == -1 } {
				set tab [CreateTabButton $container $win]
				pack $tab -side left -expand false -fill both -anchor e

				lappend containerwindows($container) $win
			} else {
				return
			}
		}

		CheckForTooManyTabs $container
	}


	proc GetContainerFromWindow { win } {
		variable containerwindows

		if { ![info exists containerwindows] } {
			return ""
		} else {
			foreach container [array names containerwindows] {
				if { [lsearch [set containerwindows($container)] $win] != -1 } {
					return $container
				}
			}
		}

		return ""

	}

	proc CreateTabButton { container win} {
		variable tab2win
		variable win2tab

		set w [string map { "." "_"} $win]
		set tab $container.bar.$w

		button $tab -image [::skin::loadPixmap tab] \
		    -width [image width [::skin::loadPixmap tab]] \
		    -command "::ChatWindow::SwitchToTab $container $win" \
		    -fg black -bg [::skin::getKey tabbarbg] -bd 0 -relief flat \
		    -activebackground [::skin::getKey tabbarbg] -activeforeground black -text "$win" \
		    -font sboldf -highlightthickness 0 -pady 0 -padx 0
		if { $::tcl_version >= 8.4 } {
			$tab configure -overrelief flat -compound center
		}


		bind $tab <Enter> "::ChatWindow::TabEntered $tab $win"
		bind $tab <Leave> "::ChatWindow::TabLeft $tab"
		bind $tab <<Button2>> "::ChatWindow::CloseTab $tab"


		set tab2win($tab) $win
		set win2tab($win) $tab

		bind $tab <<Button3>> [list ::ChatWindow::createRightTabMenu $tab %X %Y]

		return $tab
		
	}

	proc CloseTab { tab } {
		variable containercurrent
		variable containerprevious
		variable containerwindows
		variable tab2win
		variable win2tab
		
		set win [set tab2win($tab)]

		set container [winfo toplevel $win]

		destroy $win
		destroy [set win2tab($win)]
		set idx [lsearch [set containerwindows($container)] $win]
		set containerwindows($container) [lreplace [set containerwindows($container)] $idx $idx]
		unset win2tab($win)
		unset tab2win($tab)

		if { [info exists containerprevious($container)] && [set containerprevious($container)] != "" } {
			set newwin [set containerprevious($container)]
			if { [GetContainerFromWindow $newwin] != $container } {
				set newwin [lindex [set containerwindows($container)] 0]
			}
		} else {
			set newwin [lindex [set containerwindows($container)] 0]	
		}

		CheckForTooManyTabs $container

		if { $newwin == "" } { 
			set containercurrent($container) ""
			destroy $container
		} else {
			SwitchToTab $container $newwin
		}
		
	}

	proc TabEntered { tab win } {
		after cancel "::ChatWindow::FlickerTab $win"; 
		set ::ChatWindow::oldpixmap($tab) [$tab cget -image] 
		$tab configure -image [::skin::loadPixmap tab_hover]
		
	}
	
	proc TabLeft {tab } {
		if { [info exists ::ChatWindow::oldpixmap($tab)] } { 
			set image [set ::ChatWindow::oldpixmap($tab)]
		} else {
			set image [::skin::loadPixmap tab]
		}

		set win [set ::ChatWindow::tab2win($tab)]
		if { $win == [GetCurrentWindow [winfo toplevel $win]] } { 
			set image [::skin::loadPixmap tab_current]
		}

		$tab configure -image $image
	 }

	#///////////////////////////////////////////////////////////////////////////////////
	# NameTabButton $win $chatid
	# This proc changes the name of the tab
	proc NameTabButton { win chatid } {
		variable win2tab
		
		set tab [set win2tab($win)]
		set users [::MSN::usersInChat $chatid]
		#status_log "naming tab $win with chatid info $chatid\n" red
		set max_w [image width [::skin::loadPixmap tab]]
		incr max_w -5
		if { $users == "" || [llength $users] == 1} {
			set nick [::abook::getContactData $chatid nick]
			if { $nick == "" || [::config::getKey tabtitlenick] == 0 } {
				#status_log "writing chatid\n" red
				$tab configure -text "[trunc $chatid $tab $max_w sboldf]"
			} else {
				#status_log "found nick $nick\n" red
				$tab configure -text "[trunc $nick $tab $max_w sboldf]"
			}
		} elseif { [llength $users] != 1 } {
			set number [llength $users]
			#status_log "Conversation with $number users\n" red
			$tab configure -text "[trunc [trans conversationwith $number] $tab $max_w sboldf]"
		}

		::ChatWindow::UpdateContainerTitle [winfo toplevel $win]
	}


	proc GetCurrentWindow { container } {
		variable containercurrent

		if { [info exists containercurrent($container)] && [set containercurrent($container)] != "" } {
			return [set containercurrent($container)]
		} else {
			return $container
		}

	}

	proc SwitchToTab { container win } {
		variable containercurrent
		variable win2tab
		variable containerprevious

		set title ""

		if { [info exists containercurrent($container)] && [set containercurrent($container)] != "" } {
			set w [set containercurrent($container)]
			pack forget $w
			set containerprevious($container) $w
			if { [info exists win2tab($w)] } {
				set tab $win2tab($w)
				$tab configure -image [::skin::loadPixmap tab]
			}
		}

		set  containercurrent($container) $win
		pack $win -side bottom -expand true -fill both

		if { ![info exists containerprevious($container)] } {
			set containerprevious($container) $win
		}

		if { [info exists win2tab($win)] } {
			set tab $win2tab($win)
			$tab configure -image [::skin::loadPixmap tab_current]
		}


		::ChatWindow::UpdateContainerTitle $container

		#make the focus
		focus [::ChatWindow::GetInputText $win]

	}

	proc UpdateContainerTitle { container } {

		set win [GetCurrentWindow $container]
		set chatid [::ChatWindow::Name $win]

		set title "[GetContainerName $container]"

		if { $chatid != 0 } {
	
			foreach user [::MSN::usersInChat $chatid] { 
				set nick [string map {"\n" " "} [::abook::getDisplayNick $user]]
				set title "${title}${nick}, "
			}
			
			set title [string replace $title end-1 end " - [trans chat]"]
		}

		set ::ChatWindow::titles($container) $title

		if { [info exists ::ChatWindow::new_message_on($container)] && [set ::ChatWindow::new_message_on($container)] == "asterisk" } {
			wm title $container "*$title"
		} else {
			wm title $container "$title"
		}
		
	}

	proc GetContainerName { container } {
		variable containers

		foreach type [array names containers] {
			if { $container == [set containers($type)] } {
				if { $type == "global" } {
					return "[trans globalcontainer] : "
				} elseif { [string first "group" $type] == 0} {
					set gid [string range $type 5 end]
					set name [::groups::GetName $gid]
					if {$name != "" } {
						return "$name : "
					} else {
						return "$type : "
					}
				} else {
					return "$type : "
				}
			}
		} 

		return ""
	}

	proc UseContainer { } {
		#set istabbed [::config::getKey tabbedchat]
		#if { $istabbed == -1} {
		#	TabbedWindowsInfo
		#} 

		set istabbed [::config::getKey tabbedchat]

		if { $istabbed == 1 || $istabbed == 2 } {
			return 1
		} else {
			return 0
		}

	}

	proc CheckForTooManyTabs { container } {
		variable containerwindows
		variable visibletabs
		variable win2tab

		set bar_w [winfo width ${container}.bar]
		set tab_w [image width [::skin::loadPixmap tab]]

		set less_w [font measure sboldf <]
		set more_w [font measure sboldf >]

		set bar_w [expr $bar_w - $less_w - $more_w]
		#[image width [::skin::loadPixmap moretabs]] 
		#- [image width [::skin::loadPixmap lesstabs]]]

		set max_tabs [expr int(floor($bar_w / $tab_w))]
		set number_tabs [llength [set containerwindows($container)]]
	
		set less ${container}.bar.less
		set more ${container}.bar.more
		destroy $less
		destroy $more

		status_log "Got $number_tabs tabs in $container that has a max of $max_tabs\n" red

		if { $number_tabs < 2 } {
			pack forget ${container}.bar
		} else {
			pack  ${container}.bar -side top -fill both -expand false
		}

		if { $max_tabs > 0 && $number_tabs > $max_tabs } {
			#-image [::skin::loadPixmap lesstabs] 
			#[image width [::skin::loadPixmap lesstabs]] 
			button $less -text "<" \
			    -width 1 \
			    -command "::ChatWindow::LessTabs $container $less $more" \
			    -fg black -bg [::skin::getKey sendbuttonbg] -bd 0 -relief flat \
			    -activebackground [::skin::getKey sendbuttonbg] -activeforeground black \
			    -highlightthickness 0 -pady 0 -padx 0

			#-image [::skin::loadPixmap moretabs] 
			#[image width [::skin::loadPixmap lesstabs]] 
			button $more -text ">" \
			    -width 1 \
			    -command "::ChatWindow::MoreTabs $container $less $more" \
			    -fg black -bg [::skin::getKey sendbuttonbg] -bd 0 -relief flat \
			    -activebackground [::skin::getKey sendbuttonbg] -activeforeground black \
			    -highlightthickness 0 -pady 0 -padx 0

			if { $::tcl_version >= 8.4 } {
				$less configure -overrelief flat -compound center
				$more configure -overrelief flat -compound center
			}
			
			pack $more -side right -expand false -fill both -anchor e
			pack $less -side right -expand false -fill both -anchor e

			UpdateVisibleTabs $container  $max_tabs
		
			UpdateLessMoreButtons $container $less $more


		} else {
			set visibletabs($container) [set containerwindows($container)]
		}

		foreach window [set containerwindows($container)] {
			set tab [set win2tab($window)]
			catch {pack forget $tab}
		}
		foreach window [set visibletabs($container)] {
			set tab [set win2tab($window)]
			pack $tab -side left -expand false -fill both -anchor e
		}

	}

	proc LessTabs { container less more} {
		variable visibletabs
		variable containerwindows
		variable win2tab

		set visible [set visibletabs($container)]
		set windows [set containerwindows($container)]

		set first [lindex $visible 0]
		set last [lindex $visible end]

		set idx [lsearch $windows $first]
		incr idx -1

		set new [lindex $windows $idx]
		if {$new != "" } {
			set tab [set win2tab($new)]
			catch {pack forget [set win2tab($last)]}
			if { $first != $last } {
				pack $tab -side left -expand false -fill both -anchor e -before [set win2tab($first)]
			} else {
				pack $tab -side left -expand false -fill both -anchor e
			}
			set visibletabs($container) [lrange $visible 0 end-1] 
			set visibletabs($container) [linsert [set visibletabs($container)] 0 $new]
		} else {
			$less conf -state disabled
		}
		$more conf -state normal	

		UpdateLessMoreButtons $container $less $more
		
	}

	proc MoreTabs { container less more} {
		variable visibletabs
		variable containerwindows
		variable win2tab

		set visible [set visibletabs($container)]
		set windows [set containerwindows($container)]

		set first [lindex $visible 0]
		set last [lindex $visible end]

		set idx [lsearch $windows $last]
		incr idx 

		set new [lindex $windows $idx]
		if {$new != "" } {
			set tab [set win2tab($new)]
			catch {pack forget [set win2tab($first)]}
			pack $tab -side left -expand false -fill both -anchor e
			set visibletabs($container) [lrange $visible 1 end]
			lappend visibletabs($container) $new
			
		} else {
			$more conf -state disabled
		}
		$less conf -state normal

		UpdateLessMoreButtons $container $less $more
	}

	proc UpdateVisibleTabs { container max } {
		variable visibletabs
		variable containerwindows

		set visible [set visibletabs($container)]
		set windows [set containerwindows($container)]

		set first_idx [lsearch $windows [lindex $visible 0]]
		if {$first_idx == -1 } {
			set first_idx [lsearch $windows [lindex $visible 0]]
		}
		
		set visible [lrange $windows $first_idx [expr $first_idx + $max - 1]]
		if { [llength $visible] < $max } {
			set visible [lrange $windows end-[expr $max -1] end]
		}

		set visibletabs($container) $visible

	}

	proc UpdateLessMoreButtons { container less more } {
		variable visibletabs
		variable containerwindows

		set visible [set visibletabs($container)]
		set windows [set containerwindows($container)]
		
		set first [lindex $visible 0]
		set last [lindex $visible end]
		
		set idx [lsearch $windows $first]
		incr idx -1
		
		set new [lindex $windows $idx]
		if {$new == "" } {
			$less conf -state disabled
		}
		
		set idx [lsearch $windows $last]
		incr idx 
		
		set new [lindex $windows $idx]
		if {$new == "" } {
			$more conf -state disabled
		}
	}

	proc getCurrentTab { win } {
		variable containercurrent

		if { [::config::getKey tabbedchat] == 0 } {
			return $win
		}

		return $containercurrent($win)
	}

	proc createRightTabMenu { tab x y} {
		if { [winfo exists .tabmenu] } { destroy .tabmenu }
		menu .tabmenu -tearoff 0 -type normal
		.tabmenu insert end command -command "::ChatWindow::CloseTab $tab; destroy .tabmenu" -label "[trans close]"
		.tabmenu insert end command -command "::ChatWindow::DetachTab $tab; destroy .tabmenu" -label "[trans detach]"
		tk_popup .tabmenu $x $y
		#return .tabmenu
	}

	proc DetachTab { tab } {
		set win [set ::ChatWindow::tab2win($tab)]
		set out [GetOutText $win]
		set in [GetInputText $win]
		set dump_out [$out dump 0.0 end]
		set dump_in [$in dump 0.0 end]

		foreach tag [$out tag names] {
			foreach option {-elide -foreground -font -background -underline} {
				lappend tags_out($tag) $option
				lappend tags_out($tag) [$out tag cget $tag $option]
			}
		}


		status_log "Got dumps : \n$dump_out\n\n$dump_in\n" red

		set chatid [Name $win]
		
		UnsetFor $chatid $win
		set new [RecreateWindow $chatid]

		set ::ChatWindow::titles(${new}) [set ::ChatWindow::titles(${win})]
		set ::ChatWindow::first_message(${new}) [set ::ChatWindow::first_message(${win})]
		set ::ChatWindow::recent_message(${new}) [set ::ChatWindow::recent_message(${win})]

		
		unset ::ChatWindow::titles(${win})
		unset ::ChatWindow::first_message(${win})
		unset ::ChatWindow::recent_message(${win})

		#Delete images if not in use
		catch {destroy $win.bottom.pic}

		CloseTab $tab

		set out [GetOutText $new]
		set in [GetInputText $new]

		$out configure -state normal -font bplainf -foreground black

		undump $out $dump_out [array get tags_out]
		undump $in $dump_in
		
		$out configure -state disabled
	}

	proc undump { w dump {tags_config ""}} {
		status_log "tags : $tags_config\n" red
		foreach {tag options} $tags_config {
			status_log "tag $tag has options $options" red
			foreach {option value} $options { 
				status_log "option $option of tag $tag is $value\n" red
				if {$value != "" } {
					status_log "setting tag option to $value\n" red
					$w tag configure $tag $option $value
				}
			}
		}

		foreach { key value index } $dump {
			#status_log "Undumping into $w, the key $key with value $value at index $index\n" red
			switch -- $key {
				text { 
					$w insert $index $value
				} 
				mark {
					$w mark set $value $index
				} 
				image {
					if { [string first "#" $value] != -1 } {
						set value [string range $value 0 [expr [string first "#" $value] -1]]
					}
					$w image create $index -image $value
				}
				window {
					if {[winfo exists $value] } {
						$w window create $index -window $value
					} else {
						status_log "undumping a window that doesn't exist\n" error
					}
				}
				tagon {
					set tags($value) $index
				}
				tagoff {
					$w tag add $value [set tags($value)] $index
				}
				default {
					status_log "Undumping to window $w an unknown key $key with value $value at index $index\n" red
				}
			}
		}
		
	}

	proc RecreateWindow { chatid } {
	
		set win_name [::ChatWindow::Open]
		::ChatWindow::SetFor $chatid $win_name
	
		set ::ChatWindow::first_message($win_name) 0
	
		# PostEvent 'new_conversation' to notify plugins that the window was created
		set evPar(chatid) $chatid
		set evPar(usr_name) [lindex [::MSN::usersInChat $chatid] 0]
		::plugins::PostEvent new_conversation evPar
		

		set top_win [winfo toplevel $win_name]

		if { [winfo exists .bossmode] } {
			set ::BossMode(${top_win}) "normal"
			wm state ${top_win} withdraw
		} else {
			wm state ${top_win} normal
		}
		
		wm deiconify ${top_win}
		

		update idletasks
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			::ChatWindow::MacPosition ${top_win}
		}
		::ChatWindow::TopUpdate $chatid

		#We have a window for that chatid, raise it
		raise ${top_win}

		focus [::ChatWindow::GetInputText ${win_name}]

		return $win_name

	}

}
