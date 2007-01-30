#########################################
#    Chat Window code abstraction       #
#           By Alberto D�z            #
#########################################

package require framec
package require scalable-bg

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
		variable scrolling

	}
	#///////////////////////////////////////////////////////////////////////////////


 	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::rotext -- Read Only text widget via snit
	# Changes must be made by "ins" and "del", not "insert" and "delete".
	# Leave the window state as "normal" so cut and paste work on all platforms.
	# From example on http://wiki.tcl.tk/3963
	::snit::widgetadaptor rotext {
		constructor {args} {
			# Turn off the insert cursor
			#installhull using text $self -insertwidth 0
			# DDG the $self gaves an error at least with 0.97 onwards
			installhull using text -insertwidth 0

			# Apply an options passed at creation time.
			$self configurelist $args
		}

		# Disable the insert and delete methods, to make this readonly.
		method insert {args} {}
		method delete {args} {}

		# Enable roinsert and rodelete as synonyms, so the program can insert and
		# delete.
		delegate method roinsert to hull as insert
		delegate method rodelete to hull as delete

		# Pass all other methods and options to the real text widget, so
		# that the remaining behavior is as expected.
		delegate method * to hull
		delegate option * to hull
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
		[::ChatWindow::GetOutText $window] rodelete 0.0 end
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
		        ChatWindowDestroyed $window

		}
		
	}

	proc ContainerClose { window } {
		variable win2tab
		
		set current [GetCurrentWindow $window]
		set currenttab [set win2tab($current)]
		#If there is just one tab OR user choosed to always close one tab when clicking the close button
		if { [::ChatWindow::CountTabs $window] == 1 || [::config::getKey ContainerCloseAction] == 2} {
			::ChatWindow::CloseTab $currenttab
			return
		}
		#If user choosed to always close all tabs when clicking the close button
		if {[::config::getKey ContainerCloseAction] == 1} {
			::ChatWindow::CloseAll $window; destroy $window
		        ChatWindowDestroyed $window
			return
		}
		
		
		set nodot [string map { "." "_"} $window]
		set w .close$nodot

		if { [winfo exists $w] } {
			raise $w
			return
		}

		toplevel $w
		wm title $w "[trans closeall]"
		
		#Create the 2 frames
		frame $w.top
		frame $w.buttons
		
		#Create the picture of warning (at left)
		label $w.top.bitmap -image [::skin::loadPixmap warning]
		pack $w.top.bitmap -side left -pady 5 -padx 10
		
		label $w.top.question -text "[trans closeall]" -font bigfont
		pack $w.top.question -pady 5 -padx 10
		
	
		checkbutton $w.top.remember -text [trans remembersetting] -variable [::config::getVar remember]
		pack $w.top.remember -pady 5 -padx 10 -side left
		
		#Create the buttons
		button $w.buttons.yes -text "[trans yes]" -command "::ChatWindow::ContainerCloseAction yes $window $w"
		button $w.buttons.no -text "[trans no]" -command "::ChatWindow::ContainerCloseAction no $currenttab $w" -default active
		button $w.buttons.cancel -text "[trans cancel]" -command "destroy $w"
		pack $w.buttons.yes -pady 5 -padx 5 -side right
		pack $w.buttons.cancel -pady 5 -padx 5 -side left
		pack $w.buttons.no -pady 5 -padx 5 -side right
		
		#Pack frames
		pack $w.top -pady 5 -padx 5 -side top
		pack $w.buttons -pady 5 -padx 5 -fill x

		moveinscreen $w 30
		bind $w <<Escape>> "destroy $w"
		
		
	}
	
	#Action to do when someone chooses yes/or inside ContainerClose
	proc ContainerCloseAction {action window w} {
		
		if {$action == "yes"} {
			::ChatWindow::CloseAll $window; destroy $window; destroy $w
		        ChatWindowDestroyed $window
			if {[::config::getKey remember]} {
				::config::setKey ContainerCloseAction 1
			}
		} else {
			::ChatWindow::CloseTab $window; destroy $w
			if {[::config::getKey remember]} {
				::config::setKey ContainerCloseAction 2
			}
		}	
	
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
	        ChatWindowDestroyed $w
		
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


		set chatid [::ChatWindow::Name $window]
		if { [::OIM_GUI::IsOIM $chatid] == 1} {
			::log::StopLog $chatid
		}

		#Only run when the parent window close event comes
		if { "$window" != "$path" } {
			return 0
		}


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
		
		#Could be cleaner, but this works, destroying unused vars, saving mem		
		catch {
			global ${window}_show_picture ${window}.f.bottom.left.in.inner.text
			unset ${window}_show_picture
			unset ${window}.f.bottom.left.in.inner.text
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

		set geometry [wm geometry $window]
		set pos_start [string first "+" $geometry]
		#Look if the window changed size with the configure

		if {[::config::getKey wincontainersize] != "[string range $geometry 0 [expr {$pos_start-1}]]"} {
			set sizechanged 1
		} else {
			set sizechanged 0
		}

		#Save size of current container
		if { [::config::getKey savechatwinsize] } {
			::config::setKey wincontainersize  [string range $geometry 0 [expr {$pos_start-1}]]
		}
	
		#If the window changed size use checkfortoomanytabs
		if { [winfo exists ${window}.bar] && $sizechanged} {
			CheckForTooManyTabs $window 0
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

		set ::ChatWindow::titles($window) [EscapeTitle [set ::ChatWindow::titles($window)]] 


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
			if { [OnWin] } {
				if { [catch {linflash $window -count -1} ] } {
					if { ![catch { 
						package require winflash
						winflash $window -count -1
					} ] } {
						bind $window <FocusIn> "catch \" winflash $window -state 0\"; bind $window <FocusIn> \"\""
						return
					}
				} else {
					bind $window <FocusIn> "catch \" winflash $window -state 0\"; bind $window <FocusIn> \"\""
					return
				}
			#if on the X window system
			} elseif { [OnLinux] } {
				if { [catch {linflash $window}] } {
					if { ![catch { 
						package require linflash
						linflash $window
					} ] } {
						bind $window <FocusIn> "catch \" linunflash $window \"; bind $window <FocusIn> \"\""
						return
					}
				} else {
					bind $window <FocusIn> "catch \" linunflash $window \"; bind $window <FocusIn> \"\""
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
			catch {wm title ${window} "[EscapeTitle $::ChatWindow::titles(${window})]"} res
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
 		set max [expr {[winfo vrootheight $window] - [winfo height $window]}]
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
		set lastfocus [focus]
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
	
				::ChatWindow::NameTabButton $win_name $chatid

				set_balloon $::ChatWindow::win2tab($win_name) "--command--::ChatWindow::SetNickText $chatid"
				::ChatWindow::SwitchToTab $container [::ChatWindow::GetCurrentWindow $container]


			}
			#update idletasks

			::ChatWindow::TopUpdate $chatid

			if { [::config::getKey showdisplaypic] && $usr_name != ""} {
		
				::amsn::ChangePicture $win_name [::skin::getDisplayPicture $usr_name] [trans showuserpic $usr_name]
				
			} else {
				::amsn::ChangePicture $win_name [::skin::getDisplayPicture $usr_name] [trans showuserpic $usr_name] nopack
				
			}
		}

		set top_win [winfo toplevel $win_name]

		# PostEvent 'new_conversation' to notify plugins that the window was created
		if { $::ChatWindow::first_message($win_name) == 1 } {
			set evPar(chatid) chatid
			set evPar(usr_name) usr_name
			::plugins::PostEvent new_conversation evPar
		}

		# If this is the first message, and no focus on window, then show notify
		if { $::ChatWindow::first_message($win_name) == 1  && $msg!="" } {
			set ::ChatWindow::first_message($win_name) 0
	

		
			if { [::config::getKey newmsgwinstate] == 0 } {
				if { [winfo exists .bossmode] } {
					set ::BossMode(${win_name}) "normal"
					wm state ${top_win} withdraw
				} else {
					wm state ${top_win} normal
				}

				wm deiconify ${top_win}

				if { [OnMac] } {
					::ChatWindow::MacPosition ${top_win}
				} else {
					raise ${top_win}
				}
				
			} else {
				# Iconify the window unless it was raised by the user already.
				if { [wm state $top_win] != "normal" && [wm state $top_win] != "zoomed" } {
					if { [winfo exists .bossmode] } {
						set ::BossMode(${top_win}) "iconic"
						wm state ${top_win} withdraw
					} else {
						wm state ${top_win} iconic
					}
				}
			}
			if { [string first ${win_name} [focus]] != 0} {
				if { ([::config::getKey notifymsg] == 1 && [::abook::getContactData $chatid notifymsg -1] != 0) ||
				[::abook::getContactData $chatid notifymsg -1] == 1 } {
					::amsn::notifyAdd "$msg" "::amsn::chatUser $chatid"
					#Regive focus on Mac OS X / TkAqua
					if { [OnMac] } {
						after 1000 "catch {focus -force $lastfocus}"
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

				if { [OnMac] } {
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
			play_sound type.wav
		}

		#Dock Bouncing on Mac OS X
		if { [OnMac] } {
			# tclCarbonNotification is in plugins, we have to require it
			package require tclCarbonNotification

			# Bounce unlimited of time when we are not in aMSN and receive a
			# message, until we re-click on aMSN icon (or get back to aMSN)
			if { (([::config::getKey dockbounce] == "unlimited" && $usr_name != [::config::getKey login]) \
				&& [focus] == "") && $msg != "" } {
				if {[catch {carbon::notification "" 1} res]} {
					status_log $res
				}
			}

			# Bounce then stop bouncing after 1 second, when we are not
			# in aMSN and receive a message (default)
			if { (([::config::getKey dockbounce] == "once" && $usr_name != [::config::getKey login]) \
				&& [focus] == "") && $msg != "" } {
				if {[catch {carbon::notification "" 1} res]} {
					status_log $res
				}
				after 1000 [list catch [list carbon::endNotification]]
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

	# ::ChatWindow::getAllChatIds
	# Returns a list of all chatids of all open windows

	proc getAllChatIds { } {

		set chatids ""
		foreach win_name [array names ::ChatWindow::chat_ids] {
			lappend chatids [::ChatWindow::Name $win_name]
		}
		return $chatids
	}


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::Open () 
	# Creates a new chat window and returns its name (.msg_n - Where n is winid)
	proc Open { {container ""} } {

		if { [UseContainer] == 0 || $container == "" } {
			set w [CreateTopLevelWindow]
	
			set mainmenu [CreateMainMenu $w]
			$w conf -menu $mainmenu

		     	if { ![OnMac] } {
			    # Bind, add new container to list of CWs and restore old setting for the show/hide CW menus
			    bind $w <Control-m> "::ChatWindow::ShowHideChatWindowMenus $w 1"
			    NewChatWindowCreated $w $mainmenu
			    ShowHideChatWindowMenus $w 0
			}

			#Send a postevent for the creation of menu
			set evPar(window_name) "$w"
			set evPar(menu_name) "$mainmenu"
			::plugins::PostEvent chatmenu evPar

			#bind on configure for saving the window shape
			bind $w <Configure> "::ChatWindow::Configured %W"

			wm state $w withdraw

			searchdialog $w.search 
			$w.search hide 
			$w.search bindwindow $w
			$w.search configure -searchin [::ChatWindow::GetOutText $w]

		} else {
			set w [CreateTabbedWindow $container]
		} 

		set copypastemenu [CreateCopyPasteMenu $w]
		set copymenu [CreateCopyMenu $w]


		# Create the window's elements
		set top [CreateTopFrame $w]
		set statusbar [CreateStatusBar $w]
		set paned [CreatePanedWindow $w]

		# Pack them

		if {[::skin::getKey chat_show_topframe]} {
			pack $top -side top -expand false -fill x -padx [::skin::getKey chat_top_padx]\
				 -pady [::skin::getKey chat_top_pady]
		}

		if {[::skin::getKey chat_show_statusbarframe]} {
			pack $statusbar -side bottom -expand false -fill x\
				-padx [::skin::getKey chat_status_padx] -pady [::skin::getKey chat_status_pady]
		}
		pack $paned -side top -expand true -fill both -padx [::skin::getKey chat_paned_padx]\
		 -pady [::skin::getKey chat_paned_pady]

		# Tabbed chatwindows have focus by themselves, the focus thing
		# seems to mess them up
		if { [::config::getKey tabbedchat] != 0 } { 
			focus $paned
		}

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
		} else {
			if { ![OnMac] } {
				lower $w
				::ChatWindow::MacPosition $w
			}
		}

		return "$w"
	}
	#///////////////////////////////////////////////////////////////////////////////

	
	proc CloseTabInContainer { container } {
		set win [::ChatWindow::GetCurrentWindow $container]
		set tab [set ::ChatWindow::win2tab($win)]
		::ChatWindow::CloseTab $tab
		
	}

	proc CreateNewContainer { } { 
		set container [CreateContainerWindow]
		set mainmenu [CreateMainMenu $container]
		$container configure -menu $mainmenu

		if { ![OnMac] } {
		    # Bind, add new container to list of CWs and restore old setting for the show/hide CW menus
		    bind $container <Control-m> "::ChatWindow::ShowHideChatWindowMenus $container 1"
		    NewChatWindowCreated $container $mainmenu
		    ShowHideChatWindowMenus $container 0
		}

		#Change Close item menu because the behavior is not the same with tabs
		$container.menu.msn delete "[trans close]"
		if { [OnMac] } {
			$container.menu.msn add command -label "[trans close]" \
				-command "::ChatWindow::CloseTabInContainer $container" -accelerator "Command-W"
		} else {
			$container.menu.msn add command -label "[trans close]" \
				-command "::ChatWindow::CloseTabInContainer $container"
		}
		

		#we bind <Escape> to close the current tab
		#set current [GetCurrentWindow $container]
		#set currenttab [set win2tab($current)]
		#bind $container <<Escape>> "::ChatWindow::CloseTab \[set ::ChatWindow::win2tab(\[::ChatWindow::GetCurrentWindow $container\])\]"
		bind $container <<Escape>> [list ::ChatWindow::CloseTabInContainer $container]
		
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
		::skin::setPixmap tab_close tab_close.gif

		::skin::setPixmap tab_close_hover tab_close_hover.gif
		::skin::setPixmap tab_hover tab_hover.gif

		::skin::setPixmap tab_current tab_current.gif
		::skin::setPixmap tab_flicker tab_flicker.gif
		::skin::setPixmap moretabs moretabs.gif
		::skin::setPixmap lesstabs lesstabs.gif

		frame $bar -class Amsn -relief solid -bg [::skin::getKey tabbarbg] -bd 0

		if { $::tcl_version >= 8.4 } {
			$bar configure  -padx [::skin::getKey chat_tabbar_padx] -pady [::skin::getKey chat_tabbar_pady]
		}

		return $bar
	}

	###################################################
	# CreateContainerWindow
	# This proc should create the toplevel window for a chat window
	# container and configure it and then return it's pathname
	#
	proc CreateContainerWindow { } {
		set w ".container_$::ChatWindow::containerid"
		incr ::ChatWindow::containerid
			
		chatwindow $w -background [::skin::getKey chatwindowbg]	-borderwidth 0
#		::Event::registerEvent messageReceived all $w
		
		# If there isn't a configured size for Chat Windows, use the default one and store it.
		if {[catch { wm geometry $w [::config::getKey wincontainersize] } res]} {
			wm geometry $w 350x390
			::config::setKey wincontainersize 350x390
			status_log "No config(winchatsize). Setting default size for chat window\n" red
		}

		if { [OnWin] } {
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
		if { ![OnWin] } {
			catch {wm iconbitmap $w @[::skin::GetSkinFile pixmaps amsn.xbm]}
			catch {wm iconmask $w @[::skin::GetSkinFile pixmaps amsnmask.xbm]}
		}


		# Create the necessary bindings
		bind $w <<Cut>> "status_log cut\n;tk_textCut \[::ChatWindow::GetCurrentWindow $w\]"
		bind $w <<Copy>> "status_log copy\n;tk_textCopy \[::ChatWindow::GetCurrentWindow $w\]"
		bind $w <<Paste>> "status_log paste\n;tk_textPaste \[::ChatWindow::GetCurrentWindow $w\]"

		# Different shortcuts for MacOS
		if { [OnMac] } {
			bind $w <Command-,> "Preferences"
			bind $w <Command-Option-h> \
				"::amsn::ShowChatList \"[trans history]\" \[::ChatWindow::GetCurrentWindow $w\] ::log::OpenLogWin"
			# Control-w for closing current tab not implemented on Mac (germinator)
                        bind $w <Command-Right> "::ChatWindow::GoToNextTab $w"
                        bind $w <Command-Left> "::ChatWindow::GoToPrevTab $w"
                        
                        bind $w <Control-Tab> "::ChatWindow::GoToNextTab $w"
                        bind $w <Control-Shift-Tab> "::ChatWindow::GoToPrevTab $w"
			#Implement bindings for webcam, see below?
		} else {
			bind $w <Control-h> \
				"::amsn::ShowChatList \"[trans history]\" \[::ChatWindow::GetCurrentWindow $w\] ::log::OpenLogWin"
			bind $w <Control-H> \
				"::amsn::ShowChatList \"[trans history]\" \[::ChatWindow::GetCurrentWindow $w\] ::log::OpenLogWin"
			bind $w <Control-w> "::ChatWindow::CloseTab \[set ::ChatWindow::win2tab(\[::ChatWindow::GetCurrentWindow $w\])\]"
			bind $w <Control-W> "::ChatWindow::CloseTab \[set ::ChatWindow::win2tab(\[::ChatWindow::GetCurrentWindow $w\])\]"
			bind $w <Control-Next> "::ChatWindow::GoToNextTab $w"
			bind $w <Control-Prior> "::ChatWindow::GoToPrevTab $w"
			bind $w <Control-n> "::CAMGUI::WebcamWizard"
			bind $w <Control-N> "::CAMGUI::WebcamWizard"
		}

		searchdialog $w.search
		$w.search hide
		$w.search bindwindow $w

		bind $w <<Escape>> "::ChatWindow::ContainerClose $w; break"
		bind $w <Destroy> "::ChatWindow::DetachAll %W; global ${w}_show_picture; catch {unset ${w}_show_picture}"

		# These bindings are handlers for closing the window (Leave the SB, store settings...)
		wm protocol $w WM_DELETE_WINDOW "::ChatWindow::ContainerClose $w"


		return $w
	}


	proc CreateTabbedWindow { container } {

		set w "${container}.msg_${::ChatWindow::winid}"
		incr ::ChatWindow::winid

		status_log "tabbed window is : $w\n" red

		frame $w -background [::skin::getKey chatwindowbg] -relief solid -bd 0
    
    if { $::tcl_version >= 8.4 } {
        $w configure -padx 0 -pady 0
    }

		# If the platform is NOT windows, set the windows' icon to our xbm
		if { ![OnWin] } {
			catch {wm iconbitmap $w @[::skin::GetSkinFile pixmaps amsn.xbm]}
			catch {wm iconmask $w @[::skin::GetSkinFile pixmaps amsnmask.xbm]}
		}


		# Create the necessary bindings
		bind $w <<Cut>> "status_log cut\n;tk_textCut $w"
		bind $w <<Copy>> "status_log copy\n;tk_textCopy $w"
		bind $w <<Paste>> "status_log paste\n;tk_textPaste $w"

		#Change shortcut for history on Mac OS X
		if { [OnMac] } {
			bind $w <Command-Option-h> \
				"::amsn::ShowChatList \"[trans history]\" $w ::log::OpenLogWin"
		} else {
			bind $w <Control-h> \
				"::amsn::ShowChatList \"[trans history]\" $w ::log::OpenLogWin"
		}
		#I think it's not needed because the container already have <<escape>> binding
		#bind $w <<Escape>> "::ChatWindow::Close $w; break"
		bind $w <Destroy> "window_history clear %W; ::ChatWindow::Closed $w %W"


		return $w
	
	}
	###################################################
	# CreateTopLevelWindow
	# This proc should create the toplevel window for a chat window
	# configure it and then return it's pathname
	#
	proc CreateTopLevelWindow { } {
	
		set w ".msg_$::ChatWindow::winid"
		incr ::ChatWindow::winid
			
		toplevel $w -class Amsn -background [::skin::getKey chatwindowbg]	
		
		# If there isn't a configured size for Chat Windows, use the default one and store it.
		if {[catch { wm geometry $w [::config::getKey winchatsize] } res]} {
			wm geometry $w 350x390
			::config::setKey winchatsize 350x390
			status_log "No config(winchatsize). Setting default size for chat window\n" red
		}

		if { [OnWin] } {
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
		if { ![OnWin] } {
			catch {wm iconbitmap $w @[::skin::GetSkinFile pixmaps amsn.xbm]}
			catch {wm iconmask $w @[::skin::GetSkinFile pixmaps amsnmask.xbm]}
		}

		# Create the necessary bindings
		bind $w <<Cut>> "status_log cut\n;tk_textCut $w"
		bind $w <<Copy>> "status_log copy\n;tk_textCopy $w"
		bind $w <<Paste>> "status_log paste\n;tk_textPaste $w"

		#Change shortcut for history on Mac OS X
		if { [OnMac] } {
			bind $w <Command-Option-h> \
				"::amsn::ShowChatList \"[trans history]\" $w ::log::OpenLogWin"
		} else {
			bind $w <Control-h> \
				"::amsn::ShowChatList \"[trans history]\" $w ::log::OpenLogWin"
		}

		bind $w <<Escape>> "::ChatWindow::Close $w; break"
		bind $w <Destroy> "window_history clear %W; ::ChatWindow::Closed $w %W"

		#Different shortcuts on Mac OS X
		if { [OnMac] } {
			bind $w <Command-,> "Preferences"
		}


		# These bindings are handlers for closing the window (Leave the SB, store settings...)
		wm protocol $w WM_DELETE_WINDOW "::ChatWindow::Close $w"


		return $w

	}

	proc NewChatWindowCreated { window menu }  {
	    variable chatWindowMenus
	    set chatWindowMenus($window) $menu
	}
	proc ChatWindowDestroyed { window }  {
	    variable chatWindowMenus
	    array unset chatWindowMenus $window
	}

	proc ShowHideChatWindowMenus { {window .} {toggle 0} } {
	    variable chatWindowMenus

	    if {$toggle} { 
		if { [::config::getKey showcwmenus -1] == -1 } {
		    if { [ShowFirstTimeMenuHidingFeature $window] == 0 } {
			return
		    }
		}
		::config::setKey showcwmenus [expr ![::config::getKey showcwmenus -1]] 
		
	    } 
	    
	    if { [::config::getKey showcwmenus -1]} {
		foreach win [array names chatWindowMenus] {
		    if { [winfo exists $win] } {
			$win configure -menu [set chatWindowMenus($win)]
		    }
		}
	    } else {
		foreach win [array names chatWindowMenus] {
		    if { [winfo exists $win] } {
			$win configure -menu {}
		    }
		}
	    }

	}

	#############################################
	# CreateMainMenu $w
	# This proc should create the main menu of the chat window
	# it only creates the menu supposed to appear in the menu bar actually
	#
	proc CreateMainMenu { w } {
		set mainmenu $w.menu	

		if {[package provide pixmapmenu] != "" && \
			[info commands pixmapmenu_isEnabled] != "" && [pixmapmenu_isEnabled]} {
			pack [menubar $mainmenu] -fill x -side top
		} else {
			menu $mainmenu -tearoff 0 -type menubar -borderwidth 0 -activeborderwidth -0
		}

		# App menu, only on Mac OS X (see Mac Interface Guidelines)
		if { [OnMac] } {
			set applemenu [CreateAppleMenu $mainmenu]
			$mainmenu add cascade -label "aMSN" -menu $applemenu
		}

		set chatmenu [CreateChatMenu $w $mainmenu]
		set editmenu [CreateEditMenu $w $mainmenu]
		set viewmenu [CreateViewMenu $w $mainmenu]
		set actionsmenu [CreateActionsMenu $w $mainmenu]
		set contactmenu [CreateContactMenu $w $mainmenu]
		set helpmenu [CreateHelpMenu $w $mainmenu]

		#no need to call it "file"
		# http://developer.apple.com/documentation/UserExperience/Conceptual/OSXHIGuidelines/index.html
		$mainmenu add cascade -label "[trans chat]" -menu $chatmenu
		$mainmenu add cascade -label "[trans edit]" -menu $editmenu
		$mainmenu add cascade -label "[trans view]" -menu $viewmenu
		$mainmenu add cascade -label "[trans actions]" -menu $actionsmenu		
		$mainmenu add cascade -label "[trans contact]" -menu $contactmenu
		$mainmenu add cascade -label "[trans help]" -menu $helpmenu

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
	proc CreateChatMenu { w menu } {
		set chatmenu $menu.msn
		menu $chatmenu -tearoff 0 -type normal

		#new chat
		$chatmenu add command -label "[trans newchat]..." \
			-command [list ::amsn::ShowUserList [trans sendmsg] ::amsn::chatUser]
			
		if { [OnMac] } {
			#----------------------
			$chatmenu add separator
			
			$chatmenu add command -label "[trans close]" \
				-command "::ChatWindow::Close $w" -accelerator "Command-W"
		} 
		
		#Save
		$chatmenu add command -label "[trans savetofile]..." \
			-command " ChooseFilename \[::ChatWindow::GetOutText \[::ChatWindow::getCurrentTab $w\]\] \[::ChatWindow::getCurrentTab $w\]"		

		#----------------------
		$chatmenu add separator
		
		#Invite a user to the chat
		$chatmenu add command -label "[trans invite]..." \
			-command "::amsn::ShowInviteList \"[trans invite]\" \[::ChatWindow::getCurrentTab $w\]"

			

#TODO:		#powertool should add the "hide window" thing here	
#		if { ![OnMac] } {
#			$chatmenu add command -label "[trans hidewindow]" \
#				-command "wm state \[winfo toplevel \[::ChatWindow::getCurrentTab $w\]\] withdraw"
#		}


		if { ![OnMac] } {
			#----------------------
			$chatmenu add separator

			$chatmenu add command -label "[trans close]" \
				-command "::ChatWindow::Close $w"
		}
		
		return $chatmenu
		
	}

	#############################################
	# CreateEditMenu $menu
	# This proc should create the Edit submenu of the chat window
	#
	proc CreateEditMenu { w menu } {

		set editmenu $menu.edit

		menu $editmenu -tearoff 0 -type normal

		#Change the accelerator on Mac OS X
		if { [OnMac] } {
			$editmenu add command -label "[trans cut]" \
				-command "tk_textCut \[::ChatWindow::getCurrentTab $w\]" -accelerator "Command+X"
			$editmenu add command -label "[trans copy]" \
				-command "tk_textCopy \[::ChatWindow::getCurrentTab $w\]" -accelerator "Command+C"
			$editmenu add command -label "[trans paste]" \
				-command "tk_textPaste \[::ChatWindow::getCurrentTab $w\]" -accelerator "Command+V"
			$editmenu add separator
			$editmenu add command \-label "[trans find]" \
				-command "$w.search show" -accelerator "Command+F"
			$editmenu add command -label "[trans findnext]" -command "$w.search findnext" -accelerator "Command+G"
			$editmenu add command -label "[trans findprev]" -command "$w.search findprev" -accelerator "Command+Shift+G"
			$editmenu add separator
			$editmenu add command -label "[trans editavsettings]" \
				 -command "::CAMGUI::WebcamWizard" ;#Accelerator?
		} else {
			$editmenu add command -label "[trans cut]" \
				-command "tk_textCut \[::ChatWindow::getCurrentTab $w\]" -accelerator "Ctrl+X"
			$editmenu add command -label "[trans copy]" \
				-command "tk_textCopy \[::ChatWindow::getCurrentTab $w\]" -accelerator "Ctrl+C"
			$editmenu add command -label "[trans paste]" \
				-command "tk_textPaste \[::ChatWindow::getCurrentTab $w\]" -accelerator "Ctrl+V"
			$editmenu add separator
			$editmenu add command -label "[trans find]" \
				-command "$w.search show" -accelerator "Ctrl+F"
			$editmenu add command -label "[trans findnext]" -command "$w.search findnext" -accelerator "F3"
			$editmenu add command -label "[trans findprev]" -command "$w.search findprev" -accelerator "Shift+F3"
			$editmenu add separator
			$editmenu add command -label "[trans editavsettings]" \
				-command "::CAMGUI::WebcamWizard"  -accelerator "Ctrl+N"
		}

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

		#show emoticons check
		$viewmenu add checkbutton -label "[trans chatsmileys]" \
			-onvalue 1 -offvalue 0 -variable [::config::getVar chatsmileys]

		#show dp check
		$viewmenu add checkbutton -label "[trans showdisplaypic]" \
			-command "::amsn::ShowOrHidePicture \[::ChatWindow::getCurrentTab $w\]"\
			-onvalue 1 -offvalue 0 -variable "${w}_show_picture"
		
		#----------------------
		$viewmenu add separator			
		
		#chatstyle
		$viewmenu add cascade -label "[trans style]" -menu [CreateStyleMenu $viewmenu]

		#textstyle
		$viewmenu add cascade -label "[trans textsize]" -menu [CreateTextSizeMenu $viewmenu]

		#----------------------
		$viewmenu add separator

		#Clear
		$viewmenu add command -label "[trans clear]" -command [list ::ChatWindow::Clear $w]



		set ${w}_show_picture 0
	
		

		
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

		foreach size {" 8" " 6" " 4" " 2" " 1" "   0" " -2" " -4" } { 
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
	# CreateActionsMenu $w $menu
	# This proc should create the Actions submenu of the chat window
	#
	proc CreateActionsMenu { w menu } {
		set actionsmenu $menu.actions

		menu $actionsmenu -tearoff 0 -type normal

		$actionsmenu add command -label "[trans sendfile]..." \
			-command "::amsn::FileTransferSend \[::ChatWindow::getCurrentTab $w\]"

		$actionsmenu add command -label "[trans askcam]..." \
			-command "::amsn::ShowChatList \"[trans askcam]\" \[::ChatWindow::getCurrentTab $w\] ::MSNCAM::AskWebcamQueue"

		$actionsmenu add command -label "[trans sendcam]..." \
			-command "::amsn::ShowChatList \"[trans sendcam]\" \[::ChatWindow::getCurrentTab $w\] ::MSNCAM::SendInviteQueue"

		#nudge to add item here
	
		return $actionsmenu
	}


	#############################################
	# Createcontactmenu $menu
	# This proc should create the Contact submenu of the chat window
	#
	proc CreateContactMenu { w menu } {
		set contactmenu $menu.contact

		menu $contactmenu -tearoff 0 -type normal


		#Chat history
		if { [OnMac] } {
			$contactmenu add command -label "[trans history]" \
				-command "::amsn::ShowChatList \"[trans history]\" \[::ChatWindow::getCurrentTab $w\] ::log::OpenLogWin" \
				-accelerator "Command-Option-H"
		} else {
			$contactmenu add command -label "[trans history]" \
				-command "::amsn::ShowChatList \"[trans history]\" \[::ChatWindow::getCurrentTab $w\] ::log::OpenLogWin" \
				-accelerator "Ctrl+H"
		}

		#webcam history
		$contactmenu add command -label "[trans webcamhistory]" \
		    -command "::amsn::ShowChatList \"[trans webcamhistory]\" \[::ChatWindow::getCurrentTab $w\] ::log::OpenCamLogWin" 

		#received files
		$contactmenu add command -label "[trans openreceived]..." \
			-command {launch_filemanager "[::config::getKey receiveddir]"}


		#-------------------------
		$contactmenu add separator
		
		#profile
		$contactmenu add command -label "[trans viewprofile]" \
			-command "::amsn::ShowChatList \"[trans viewprofile]\" \[::ChatWindow::getCurrentTab $w\] ::hotmail::viewProfile"		
		
		#email
		$contactmenu add command -label "[trans sendmail]..." \
			-command "::amsn::ShowChatList \"[trans sendmail]\" \[::ChatWindow::getCurrentTab $w\] launch_mailer"		
		
		#sms
		$contactmenu add command -label "[trans sendmobmsg]..." \
			-command "::amsn::ShowChatList \"[trans sendmobmsg]\" \[::ChatWindow::getCurrentTab $w\] ::MSNMobile::OpenMobileWindow"

		#-------------------------
		$contactmenu add separator
		
		#block/unblock
		$contactmenu add command -label "[trans block]/[trans unblock]" \
			-command "::amsn::ShowChatList \"[trans block]/[trans unblock]\" \[::ChatWindow::getCurrentTab $w\] ::amsn::blockUnblockUser"		
		
		#add to list
		$contactmenu add command -label "[trans addtocontacts]" \
			-command "::amsn::ShowAddList \"[trans addtocontacts]\" \[::ChatWindow::getCurrentTab $w\] ::MSN::addUser"


		#-------------------------
		$contactmenu add separator

		#alarm
		$contactmenu add command -label "[trans cfgalarm]" \
			-command "::amsn::ShowChatList \"[trans cfgalarm]\" \[::ChatWindow::getCurrentTab $w\] ::abookGui::showUserAlarmSettings"

		
		#notes
		$contactmenu add command -label "[trans note]..." \
			-command "::amsn::ShowChatList \"[trans note]\" \[::ChatWindow::getCurrentTab $w\] ::notes::Display_Notes"


		#-------------------------
		$contactmenu add separator

		#properties							
		$contactmenu add command -label "[trans properties]" \
			-command "::amsn::ShowChatList \"[trans properties]\" \[::ChatWindow::getCurrentTab $w\] ::abookGui::showUserProperties"

		
		return $contactmenu
	}
	
	#############################################
	# CreateHelpMenu $w $menu
	# This proc should create the Actions submenu of the chat window
	#
	proc CreateHelpMenu { w menu } {
		set helpmenu $menu.helpmenu

		menu $helpmenu -tearoff 0 -type normal

		$helpmenu add command -label "[trans helpcontents]" \
			-command "::amsn::showHelpFileWindow HELP [list [trans helpcontents]]"

		$helpmenu add separator

		$helpmenu add command -label "[trans about]" -command ::amsn::aboutWindow

		return $helpmenu
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
		set top [GetTopFrame $w]
		
		framec $top -type canvas -relief solid -borderwidth [::skin::getKey chat_top_border] -bordercolor [::skin::getKey topbarborder] -background [::skin::getKey topbarbg] -state disabled
		
		if { [::skin::getKey chat_top_pixmap] } {
			set bg "::$top.bg"
			set topimg [image create photo [TmpImgName]] ;#gets destroyed
			$topimg copy [::skin::loadPixmap cwtopback]
			::picture::Colorize $topimg [::skin::getKey topbarbg]
			scalable-bg $bg -source $topimg -n [::skin::getKey topbarpady] -e [::skin::getKey topbarpadx] -s [::skin::getKey topbarpady] -w [::skin::getKey topbarpadx] -width 0 -height 0
			$top create image 0 0 -image [$bg name] -anchor nw -tag backgnd
			bind $w <Configure> "$bg configure -width %w -height %h"
			bind $top <Destroy> "$bg destroy; image delete $topimg"
		}
		
		set toX [::skin::getKey topbarpadx]
		set usrsX [expr {$toX + [font measure bplainf "[trans to]:"] + 5}]
		set txtY [::skin::getKey topbarpady]
		
		$top create text $toX $txtY -fill [::skin::getKey topbartext] -state disabled -font bplainf -text "[trans to]:" -anchor nw -tag to

		$top create text $usrsX $txtY -fill [::skin::getKey topbartext] -state disabled -font sboldf -anchor nw -tag text
		
		#As the contact list isn't filled we set the height to fit with the To field
		$top configure -height [expr {[::ChatWindow::MeasureTextCanvas $top "to" [$top itemcget to -text] "h"] + 2*[::skin::getKey topbarpady]}]

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
		
		panedwindow $paned \
			-background [::skin::getKey chatwindowbg] \
			-borderwidth 0 \
			-relief flat \
			-orient vertical
		
		set output [CreateOutputWindow $w $paned]
		set input [CreateInputWindow $w $paned]

		$paned add $output $input
		$paned paneconfigure $output -minsize 50 -height 200
		$paned paneconfigure $input -minsize 100 -height 120
		$paned configure \
			-showhandle [::skin::getKey chat_sash_showhandle] \
			-sashpad [::skin::getKey chat_sash_pady] \
			-sashwidth [::skin::getKey chat_sash_width] \
			-sashrelief [::skin::getKey chat_sash_relief]

		# Bind on focus, so we always put the focus on the input window
		bind $paned <FocusIn> "focus $input"

		bind $input <Configure> "::ChatWindow::InputPaneConfigured $paned $input $output %W %h"
		bind $output <Configure> "::ChatWindow::OutputPaneConfigured $paned $input $output %W %h"
		bind $paned <Configure> "::ChatWindow::PanedWindowConfigured $paned $input $output %W %h"

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
		update idletasks

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

		set scrolling [getScrolling [::ChatWindow::GetOutText $win]]

		#check that the drag adhered to minsize input pane
		#first checking that there is enough room otherwise you get an infinite loop
		if { ( [winfo height $input] < [$paned panecget $input -minsize] ) \
			&& ( [winfo height $output] > [$paned panecget $output -minsize] ) \
			&& ( [winfo height $paned] > [$paned panecget $output -minsize] ) } {
			::ChatWindow::SetSashPos $paned $input $output
		}

		if { $scrolling } { after 100 "catch {::ChatWindow::Scroll [::ChatWindow::GetOutText $win]}" }

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
		ScrolledWindow $out -auto vertical -scrollbar vertical -ipad 0
		framec $text -type ::ChatWindow::rotext -relief solid -foreground white \
			-background [::skin::getKey chat_output_back_color] -width 45 -height 3 \
			-setgrid 0 -wrap word -exportselection 1 -highlightthickness 0 -selectborderwidth 1 \
			-borderwidth [::skin::getKey chat_output_border] \
			-bordercolor [::skin::getKey chat_output_border_color]
		set textinner [$text getinnerframe]

		$out setwidget $text


		pack $out -expand true -fill both \
			-padx [::skin::getKey chat_output_padx] \
			-pady [::skin::getKey chat_output_pady]
		

		# Configure our widgets
		$text configure -state normal
		$text tag configure green -foreground darkgreen -font sboldf
		$text tag configure red -foreground red -font sboldf
		$text tag configure blue -foreground blue -font sboldf
		$text tag configure gray -foreground #404040 -font splainf
		$text tag configure gray_italic -foreground #000000 -font sbolditalf
		$text tag configure white -foreground white -background black -font sboldf
		$text tag configure url -foreground #000080 -font splainf -underline true

		# Create our bindings
		bind $textinner <<Button3>> "tk_popup $w.copy %X %Y"

		# Do not bind copy command on button 1 on Mac OS X 
		if { ![OnMac] } {
			bind $textinner <Button1-ButtonRelease> "copy 0 $w"
		}

		# When someone type something in out.text, regive the focus to in.input and insert that key,
		bind $textinner <KeyPress> "::ChatWindow::lastKeytyped %A %K $w"
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $textinner <Command-KeyPress> ";"
			bind $textinner <Command-KeyPress-v> "::ChatWindow::pasteToInput $w"
		}

		#Added to stop amsn freezing when control-up pressed in the output window
		#If you can find why it is freezing and can stop it remove this line
		bind $textinner <Control-Up> "break"

		return $fr
	}
	
	#pasteToInput -- text pasted in output window goes to input window
	#This is processed before the paste occurs, so this is sufficient.
	proc pasteToInput {w} {
		focus -force [::ChatWindow::GetInputText $w]
	}

	#lastkeytyped 
	#Force the focus to the input text box when someone try to write something in the output
	proc lastKeytyped {typed keysym w} {
		if {[regexp {^[ -~]$} $typed]} {
			focus -force [::ChatWindow::GetInputText $w]
			[::ChatWindow::GetInputText $w] insert insert $typed
		} elseif {$keysym == "BackSpace"} {
			focus -force [::ChatWindow::GetInputText $w]
			[::ChatWindow::GetInputText $w] delete "insert - 1 char" insert
		} elseif {$keysym == "Delete"} {
			focus -force [::ChatWindow::GetInputText $w]
			[::ChatWindow::GetInputText $w] delete insert "insert + 1 char"
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

		#send chatwininput postevent
		set evPar(input) $input
		set evPar(buttons) $buttons
		set evPar(picture) $picture
		set evPar(window) "$w"

		::plugins::PostEvent chatwininput evPar		

		return $bottom

	}

	proc CreateInputFrame { w bottom} { 
		# Create The input frame
		set input $bottom.in
		framec $input -class Amsn -relief solid \
				-background [::skin::getKey sendbuttonbg] \
				-borderwidth [::skin::getKey chat_input_border] \
				-bordercolor [::skin::getKey chat_input_border_color]
		
		# set our inner widget's names
		set sendbuttonframe [$input getinnerframe].sbframe
		set sendbutton $sendbuttonframe.send
		set text [$input getinnerframe].text

		# Create the text widget and the send button widget
		text $text -background [::skin::getKey chat_input_back_color] -width 15 -wrap word -font bboldf \
			-borderwidth 0 -relief solid -highlightthickness 0 -exportselection 1
		
		frame $sendbuttonframe -borderwidth 0 -bg [::skin::getKey sendbuttonbg]
		
		# Send button in conversation window, specifications and command.
		if { ![OnMac] } {
			button $sendbutton -image [::skin::loadPixmap sendbutton] \
				-command "::amsn::MessageSend $w $text" \
				-fg black -bg [::skin::getKey sendbuttonbg] -bd 0 -relief flat \
				-activebackground [::skin::getKey sendbuttonbg] -activeforeground black \
				-text [trans send] -font sboldf -highlightthickness 0 -pady 0 -padx 0 \
				-overrelief flat -compound center
		} else {
			label $sendbutton -image [::skin::loadPixmap sendbutton] \
				-fg black -bg [::skin::getKey sendbuttonbg] -bd 0 -relief flat \
				-activebackground [::skin::getKey sendbuttonbg] -activeforeground black \
				-text [trans send] -font sboldf -highlightthickness 0 -pady 0 -padx 0 \
				-relief flat -compound center
			bind $sendbutton <<Button1>> "::amsn::MessageSend $w $text"
		}

		# Configure my widgets
		$sendbutton configure -state normal
		$text configure -state normal

		# Create my bindings
		bind $sendbutton <Return> "::amsn::MessageSend $w $text; break"
		bind $sendbutton <Enter> "$sendbutton configure -image [::skin::loadPixmap sendbutton_hover]"
		bind $sendbutton <Leave> "$sendbutton configure -image [::skin::loadPixmap sendbutton]"
		bind $text <Shift-Return> {%W insert insert "\n"; %W see insert; break}
		bind $text <Control-KP_Enter> {%W insert insert "\n"; %W see insert; break}
		bind $text <Shift-KP_Enter> {%W insert insert "\n"; %W see insert; break}

		# Change shortcuts on Mac OS X (TKAqua). ALT=Option Control=Command on Mac
		if { [OnMac] } {
			bind $text <Command-Return> {%W insert insert "\n"; %W see insert; break}
			bind $text <Command-Shift-space> BossMode
			bind $text <Command-a> {%W tag add sel 1.0 {end - 1 chars};break}
			bind $text <Command-A> {%W tag add sel 1.0 {end - 1 chars};break}
		} else {
			bind $text <Control-Return> {%W insert insert "\n"; %W see insert; break}
			bind $text <Control-Alt-space> BossMode
			bind $text <Control-a> {%W tag add sel 1.0 {end - 1 chars};break}
			bind $text <Control-A> {%W tag add sel 1.0 {end - 1 chars};break}
			bind $text <Tab> "focus $sendbutton; break"
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
		bind $text <Shift-Key-Up> {::tk::TextKeySelect %W [::amsn::UpKeyPressed %W]; break}
		bind $text <Shift-Key-Down> {::tk::TextKeySelect %W [::amsn::DownKeyPressed %W]; break}

		global skipthistime
		set skipthistime 0

		bind $text <Control-S> "window_history add %W; ::amsn::MessageSend $w %W; break"
		bind $text <Return> "window_history add %W; ::amsn::MessageSend $w %W; break"
		bind $text <Key-KP_Enter> "window_history add %W; ::amsn::MessageSend $w %W; break"

		#Different shortcuts on Mac OS X / TkAqua
		if { [OnMac] } {
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
		pack $sendbutton -side top
		if {[::skin::getKey chat_show_sendbuttonframe]} {
			pack $sendbuttonframe -side right -padx [::skin::getKey chat_sendbutton_padx]\
				-pady [::skin::getKey chat_sendbutton_pady]
		}

		#send chatsendbutton postevent
		set evPar(window_name) "$w"
		set evPar(bottomleft) [$input getinnerframe]
		::plugins::PostEvent chatsendbutton evPar

		# Drag and Drop file sending
		::dnd bindtarget [::ChatWindow::GetInputText $w] Files <Drop> "::ChatWindow::HandleFileDrop $w %D"
		#::dnd bindtarget [::ChatWindow::GetInputText $w] UniformResourceLocator <Drop> "%W insert end %D"
		::dnd bindtarget [::ChatWindow::GetInputText $w] Text <Drop> {%W insert end %D}

		return $input
	}


	###############################################################
	# HandleFileDrop window data                          	      #
	# ------------------------------------------------------------#
	# Proc called when a file is dropped to the input text widget #
	# All Drag and Drop code based on plugin by MeV :             #
	# chrystalyst@free.fr                                         #
	###############################################################
	proc HandleFileDrop {window data} {
		#Send the name of the file to the ::amsn::FileTransferSend proc (for windows $data is like this "{filename}")
		status_log "Drag and Drop: Send filename: "
		set data [string map {\r "" \n "" \x00 ""} $data]
		set data [urldecode $data]
		if { [OnWin] } {
			if { [string index $data 0] == "{" && [string index $data end] == "}" } {
				set data [string range $data 1 end-1]
			}
			status_log $data
		        ::amsn::FileTransferSend $window $data
		} else {

#TODO: improve this ???
			#(VFS pseudo-)protocol: if we can't send it as a file we just paste its URI
			foreach type [list smb http https ftp sftp floppy cdrom dvd] {
				if {[string first $type $data] == 0} { 
					[::ChatWindow::GetInputText $window] insert insert $data
					return 
				}
			}

			#If the data begins with "file://", strip this off
			if { [string range $data 0 6] == "file://" } {
				set data [string range $data 7 [string length $data]]
			} 
			status_log "We got a filedrop: $data.  Sending FT request ..."
	        	::amsn::FileTransferSend $window $data
		}
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
		set voice $buttonsinner.voice
		set block $buttonsinner.block
		set sendfile $buttonsinner.sendfile
		set invite $buttonsinner.invite
		set webcam $buttonsinner.webcam

		# widget name from another proc
		set input [::ChatWindow::GetInputText $w]


		#Buttons are now labels, to get nicer interface on Mac OS X
		
		#Smiley button
		label $smileys  -image [::skin::loadPixmap butsmile] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg]  -activebackground [::skin::getKey buttonbarbg]
		set_balloon $smileys [trans insertsmiley]
	       	#Font button
		label $fontsel -image [::skin::loadPixmap butfont] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $fontsel [trans changefont]

		label $voice -image [::skin::loadPixmap butvoice] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $voice [trans sendvoice]
		
		#Block button
		label $block -image [::skin::loadPixmap butblock] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $block "--command--::ChatWindow::SetBlockText $w"
		
		#Send file button
		label $sendfile -image [::skin::loadPixmap butsend] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $sendfile [trans sendfile]
	
		#Invite another contact button
		label $invite -image [::skin::loadPixmap butinvite] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0\
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $invite [trans invite]

		#Webcam button
		label $webcam -image [::skin::loadPixmap butwebcam] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0\
			 -borderwidth 0	-highlightbackground [::skin::getKey buttonbarbg]\
			 -activebackground [::skin::getKey buttonbarbg]
		set_balloon $webcam "--command--::ChatWindow::SetWebcamText"		

		# Pack them
		pack $fontsel $smileys $voice -side left -padx 0 -pady 0
		pack $block $webcam $sendfile $invite -side right -padx 0 -pady 0
	
		bind $smileys  <<Button1>> "::smiley::smileyMenu \%X \%Y $input"
		bind $fontsel  <<Button1>> "after 1 change_font [string range $w 1 end] mychatfont"
		bind $block    <<Button1>> "::amsn::ShowChatList \"[trans block]/[trans unblock]\" $w ::amsn::blockUnblockUser"
		bind $sendfile <<Button1>> "::amsn::FileTransferSend $w"
		bind $invite   <<Button1>> "::amsn::ShowInviteMenu $w \[winfo pointerx $w\] \[winfo pointery $w\]"

		bind $voice    <ButtonPress-1> "::ChatWindow::start_voice_clip $w"
		bind $voice    <Button1-ButtonRelease> "::ChatWindow::stop_and_send_voice_clip $w"

		#if we have a webcam configured, have a "send webcam" button, else, use the button to open the wizard
		bind $webcam   <<Button1>> "::ChatWindow::webcambuttonAction $w"


		# Create our bindings
		bind  $smileys  <Enter> "$smileys configure -image [::skin::loadPixmap butsmile_hover]"
		bind  $smileys  <Leave> "$smileys configure -image [::skin::loadPixmap butsmile]"
		bind  $fontsel  <Enter> "$fontsel configure -image [::skin::loadPixmap butfont_hover]"
		bind  $fontsel  <Leave> "$fontsel configure -image [::skin::loadPixmap butfont]"
		bind  $voice  <Enter> "$voice configure -image [::skin::loadPixmap butvoice_hover]"
		bind  $voice  <Leave> "$voice configure -image [::skin::loadPixmap butvoice]"
		bind $block <Enter> "$block configure -image [::skin::loadPixmap butblock_hover]"
		bind $block <Leave> "$block configure -image [::skin::loadPixmap butblock]"
		
		bind $sendfile <Enter> "$sendfile configure -image [::skin::loadPixmap butsend_hover]"
		bind $sendfile <Leave> "$sendfile configure -image [::skin::loadPixmap butsend]"
		bind $invite <Enter> "$invite configure -image [::skin::loadPixmap butinvite_hover]"
		bind $invite <Leave> "$invite configure -image [::skin::loadPixmap butinvite]"
		bind $webcam <Enter> "$webcam configure -image [::skin::loadPixmap butwebcam_hover]"
		bind $webcam <Leave> "$webcam configure -image [::skin::loadPixmap butwebcam]"
		
		#send chatwindowbutton postevent
		set evPar(bottom) $buttonsinner
		set evPar(window_name) "$w"
		::plugins::PostEvent chatwindowbutton evPar

		return $buttons
	}


	proc webcambuttonAction { w } {
		if {[::config::getKey webcamDevice] != ""} {
			::amsn::ShowChatList \"[trans sendwebcaminvite]\" $w ::MSNCAM::SendInviteQueue
		} elseif {[OnMac] } {
			# On mac webcamDevice always returns 0. So we need to check manually if the grabber is open. If the grabber isn't open then we create it.
			# The behaviour of the grabber window opening without the user configuring the cam first is default for most OS X applications, and a lot of users have requested this.
			if {[winfo exists .grabber]} {
				::amsn::ShowChatList \"[trans sendwebcaminvite]\" $w ::MSNCAM::SendInviteQueue
			} else {
				::CAMGUI::CreateGrabberWindowMac
				::amsn::ShowChatList \"[trans sendwebcaminvite]\" $w ::MSNCAM::SendInviteQueue
			}
		} else {
			::CAMGUI::WebcamWizard
		}
	}

	proc start_voice_clip { w } {
		variable voice_sound
		variable voice_text_pack

		set chatid [Name $w]
		if { [llength  [::MSN::usersInChat $chatid]] > 0 } {
			if { [catch {require_snack} ] || [package vcompare [set ::snack::patchLevel] 2.2.9] < 0 || [catch {package require tcl_siren }] } {
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid greyline 3
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid butvoice 3 2
				amsn::WinWrite $chatid "[timestamp] [trans snackneeded]\n" red
				amsn::WinWriteIcon $chatid greyline 3
				return
			}

			catch { $voice_sound destroy }

			set sound_available 1
			if {[OnLinux] } {
				# on unix, libsnack segfaults (on the next record)
				# if it can't record because the device is used, so we
				# detect that by trying to open /dev/dsp
				if {[catch {open /dev/dsp "RDONLY NONBLOCK"} f]} {
					set sound_available 0
				} else {
					close $f
				}
			}

			if { $sound_available == 0 } {
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid greyline 3
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid butvoice 3 2
				amsn::WinWrite $chatid "[timestamp] [trans soundnoavail]\n" red
				amsn::WinWriteIcon $chatid greyline 3
				return
			}

			set voice_sound [::snack::sound]
			if { [catch {$voice_sound record} res]} {
				
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid greyline 3
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid butvoice 3 2
				amsn::WinWrite $chatid "[timestamp] [trans recorderror $res]\n" red
				amsn::WinWriteIcon $chatid greyline 3
				$voice_sound destroy
			} else {
				set inputtext [GetInputText $w]
				set inputframe [winfo parent $inputtext]
				set voice_text_pack [pack info $inputtext]
				pack forget $inputtext
				canvas $inputframe.wave -background [::skin::getKey chat_input_back_color] -borderwidth 0 -relief solid
				eval pack $inputframe.wave $voice_text_pack

				# This update here is necessary because it seems if we don't update, the waveform won't appear...
				# this is because we depend on the [winfo width] and [winfo height] for the waveform size
				update

				$inputframe.wave create waveform 0 0 -sound $voice_sound -zerolevel 0 -width [winfo width $inputframe.wave] -height [winfo height $inputframe.wave] -pixelspersecond [expr {[winfo width $inputframe.wave] / 15}]

								
				
				::MSN::SendRecordingUserNotification $chatid
				after 15000 "::ChatWindow::stop_and_send_voice_clip $w"
			}
		}
	}

	# This proc is not needed because I found the undocumented 'datasamples' subcommand...
	proc SoundToWave { sound filename } {
		$sound convert -rate 16000 -channels 2
		
		set input [$sound data]
		
		binary scan $input @0a4ia4 riff size wave
		set offset 12
		puts "found size $size"
		while { $offset < $size } {
			binary scan $input @${offset}a4i id chunk_size
			incr offset 8
			puts "found chunk $id $chunk_size"
			if {$id == "data" } {
				set data [string range $input $offset [expr {$offset + $chunk_size - 1}]]
			} 
			incr offset $chunk_size
			
		}
		
		if { [info exists data] } {
			set enc [::Siren::NewEncoder]
			puts "encoding"
			if { [catch {set out [::Siren::Encode $enc $data] } res] } {
				::Siren::Close $enc    		
				status_log "Error Encoding : $res"
				return 0
			}
			puts "res"
			::Siren::WriteWav $enc $filename $out 
			::Siren::Close $enc
		}
		return 1
	}
		
	proc DecodeWave { file_in file_out } {
		if { [catch {require_snack} ] || [package vcompare [set ::snack::patchLevel] 2.2.9] < 0 || [catch {package require tcl_siren 0.3}] } {
			return -1
		} else {
			set fd [open $file_in r]
			fconfigure $fd -translation binary
			set input [read $fd]
			close $fd
			
			set riff ""
			set wave ""
			binary scan $input @0a4ia4 riff size wave
			set offset 12
			if { $riff == "RIFF" && $wave == "WAVE" } {
				while { $offset < $size } {
					binary scan $input @${offset}a4i id chunk_size
					incr offset 8
					if {$id == "fmt " } {
						binary scan $input @${offset}ssiiss format channels sampleRate byteRate blockAlign bitsPerSample
					}
					if {$id == "data" } {
						set data [string range $input $offset [expr {$offset + $chunk_size - 1}]]
					} 
					incr offset $chunk_size
					
				}
			}
			
			if {![info exists format] } {
				set format 1
			}
			
			if { [info exists data] && [expr {$format == 0x028E}] } {
				set dec [::Siren::NewDecoder]
				if { [catch {set out [::Siren::Decode $dec $data] } res] } {
					::Siren::Close $dec    		
					status_log "Error Decoding : $res"
					return 0
				}
				::Siren::WriteWav $dec $file_out $out 
				::Siren::Close $dec
				return 1
			} else {
				return 0
			}
		}
	}
	

	proc stop_and_send_voice_clip { w } {
		variable voice_sound
		variable voice_text_pack
		global HOME

		after cancel "::ChatWindow::stop_and_send_voice_clip $w"

		set chatid [Name $w]
		if { [info exists voice_text_pack] } {
			set inputtext [GetInputText $w]
			set inputframe [winfo parent $inputtext]
			
			# This update is here to prevent a race condition. if you click very fast ont he voice button the first time
			# the 'pressed' event will get called, and the 'unpressed' event will be called too right after it, but if we do 
			# a 'package require snack', etc.. it might take some time for it to load, etc, so we could get the stop_voice_clip
			# proc being called before the start_voice_clip has finished processing, so we can get here, destroy the wave form before 
			# the start_voice_clip proc finished using it, which would result in a bug.
			# 
			update
			
			destroy $inputframe.wave
			eval pack $inputtext $voice_text_pack
			unset voice_text_pack
		}

		# Should we remove the usersInChat ? I know I added it for some reason.. can't remember what.. 
		# think about you send a voice clip and the user closes your window at the same time? should the message be lost ?
		if { [llength  [::MSN::usersInChat $chatid]] > 0 && [catch {$voice_sound stop}] == 0} {
			
			set timestamp [clock format [clock seconds] -format "%d %b %Y @ %H_%m_%S"]
			set user [lindex [::MSN::usersInChat $chatid] 0]
			
			create_dir [file join $HOME voiceclips]
			set filename [file join $HOME voiceclips ${user}_${timestamp}.wav]
			set filename_siren [file join $HOME voiceclips ${user}_${timestamp}_encoded.wav]

			if { [$voice_sound min] > -1000 && [$voice_sound max] < 1000 } {
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid greyline 3
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid butvoice 3 2
				if { [$voice_sound length -unit seconds] < 2 } {
					amsn::WinWrite $chatid "[timestamp] [trans nosound_or_hold]\n" red					
				} else {
					amsn::WinWrite $chatid "[timestamp] [trans nosound]\n" red
				}
			} else {
				set enc [::Siren::NewEncoder]
				# We need to add the -byteorder littleEndian because on Mac, the datasamples are in big endian and tcl_siren expects little endian
				# since WAV file contents are in little endian.
				if { [catch {set out [::Siren::Encode $enc [$voice_sound datasamples -byteorder littleEndian]] } res] } {
					::Siren::Close $enc    		
					status_log "Error Encoding voice clip to Siren codec : $res" red
					return 0
				}
				::Siren::WriteWav $enc $filename_siren $out 
				::Siren::Close $enc
				
				$voice_sound write $filename
				
				
				::MSN::ChatQueue $chatid [list ::MSNP2P::SendVoiceClip $chatid $filename_siren]
				
				set uid [getUniqueValue]
				
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid greyline 3
				amsn::WinWrite $chatid "\n" red
				amsn::WinWriteIcon $chatid butvoice 3 2
				amsn::WinWrite $chatid "[timestamp] [trans sentvoice]\n  " green
				amsn::WinWriteClickable $chatid "[trans play]" [list ::ChatWindow::playVoiceClip $w $filename $uid] play_voice_clip_$uid
				amsn::WinWriteClickable $chatid "[trans stop]" [list ::ChatWindow::stopVoiceClip $w $filename $uid] stop_voice_clip_$uid
				[::ChatWindow::GetOutText $w] tag configure play_voice_clip_$uid -elide false
				[::ChatWindow::GetOutText $w] tag configure stop_voice_clip_$uid -elide true
				amsn::WinWrite $chatid " - " green
				amsn::WinWriteClickable $chatid "[trans saveas]" [list ::ChatWindow::saveVoiceClip $filename] 
				amsn::WinWriteIcon $chatid greyline 3
			}
		}
		catch {$voice_sound destroy}
	}

	proc playVoiceClip { w filename uid} {
		variable play_snd_$uid

		set sound_available 1
		if {[OnLinux] } {
			# on unix, libsnack segfaults (on the next record)
			# if it can't record because the device is used, so we
			# detect that by trying to open /dev/dsp
			if {[catch {open /dev/dsp "WRONLY NONBLOCK"} f]} {
				set sound_available 0
			} else {
				close $f
			}
		}

		if { $sound_available && [file exists $filename]} {
			set snd [snack::sound]
			set play_snd_$uid $snd
			$snd read $filename
			$snd play -command [list ::ChatWindow::stopVoiceClipDelayed $w $filename $uid]	
			[::ChatWindow::GetOutText $w] tag configure play_voice_clip_$uid -elide true
			[::ChatWindow::GetOutText $w] tag configure stop_voice_clip_$uid -elide false	
		}
	}

	proc stopVoiceClipDelayed { w filename uid} {
		# We need this little hack because it looks like snack (at least on my PC) calls our callback 1 second before the audio
		# really finished playing.
		after 1200 [list ::ChatWindow::stopVoiceClip $w $filename $uid]
	}

	proc stopVoiceClip { w filename uid} {
		variable play_snd_$uid

		if { [info exists play_snd_$uid] } {
			set snd [set play_snd_$uid]
			catch { $snd stop }
			catch { $snd destroy }
			unset play_snd_$uid
		}
		set text [::ChatWindow::GetOutText $w]
		if { [winfo exists $text] } {
			$text tag configure play_voice_clip_$uid -elide false
			$text tag configure stop_voice_clip_$uid -elide true	
		}
	}

	proc ReceivedVoiceClip {chatid filename } {
		set filename_decoded "[filenoext $filename]_decoded.wav"
		
		# This proc should be uncommented once tcl_siren implements the decoder
		if { [DecodeWave $filename $filename_decoded] == -1 } {
			amsn::WinWrite $chatid "\n" red
			amsn::WinWriteIcon $chatid greyline 3
			amsn::WinWrite $chatid "\n" red
			amsn::WinWriteIcon $chatid butvoice 3 2
			amsn::WinWrite $chatid "[timestamp] [trans snackneeded]\n" red
			amsn::WinWriteIcon $chatid greyline 3
			return
		} else {
			set uid [getUniqueValue]
			set w [::ChatWindow::For $chatid]
			
			amsn::WinWrite $chatid "\n" red
			amsn::WinWriteIcon $chatid greyline 3
			amsn::WinWrite $chatid "\n" red
			amsn::WinWriteIcon $chatid butvoice 3 2
			amsn::WinWrite $chatid "[timestamp] [trans receivedvoice]\n  " green
			amsn::WinWriteClickable $chatid "[trans play]" [list ::ChatWindow::playVoiceClip $w $filename_decoded $uid] play_voice_clip_$uid
			amsn::WinWriteClickable $chatid "[trans stop]" [list ::ChatWindow::stopVoiceClip $w $filename_decoded $uid] stop_voice_clip_$uid
			[::ChatWindow::GetOutText $w] tag configure play_voice_clip_$uid -elide false
			[::ChatWindow::GetOutText $w] tag configure stop_voice_clip_$uid -elide true
			amsn::WinWrite $chatid " - " green
			amsn::WinWriteClickable $chatid "[trans saveas]" [list ::ChatWindow::saveVoiceClip $filename_decoded] 
			amsn::WinWriteIcon $chatid greyline 3
			
			if { [::config::getKey autolisten_voiceclips 1] } {
				playVoiceClip $w $filename_decoded $uid
			}
		}
	}

	proc saveVoiceClip { filename } {
		if {[file exists $filename] } {
			set file [chooseFileDialog "" "Save Voice Clip" "" "" save [list [list [trans soundfiles] [list *.wav]] [list [trans allfiles] *]]]
			
			if { $file != "" } {
				if { ![string equal -nocase [file extension $file] ".wav"] } {
					append file ".wav"
				}
				file copy -force $filename $file
			}
		}
	}

	proc SetWebcamText {} {
	 if {[::config::getKey webcamDevice] != "" || [OnMac]} {
			return "[trans sendwebcaminvite]"

		} else {
			return "[trans webcamconfigure]"
		}
	}


	#Show a different ballon if the user is currently blocked or unblocked
	proc SetBlockText {win_name} {
		set Chatters [::MSN::usersInChat [::ChatWindow::Name $win_name]]
		set NrOfChatters [llength $Chatters]

		if { $NrOfChatters == 0 || $NrOfChatters > 1} {
			return "[trans block]/[trans unblock]"
		} else {
			if {[::MSN::userIsBlocked [lindex $Chatters 0]] == 0} {
				return "[trans block]"
			} else {
				return "[trans unblock]"
			}
		}
	}
	#Show the nickname of someone in the balloon
	#If someone changed nick, the new nick appear in the new balloon
	proc SetNickText {chatid} {
		return [::abook::getDisplayNick $chatid]
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
		label $showpic -bd 0 -padx 0 -pady 0 -image [::skin::loadPixmap imgshow] \
			-bg [::skin::getKey chatwindowbg] -highlightthickness 0 -font splainf \
			-highlightbackground [::skin::getKey chatwindowbg] -activebackground [::skin::getKey chatwindowbg]
		bind $showpic <Enter> "$showpic configure -image [::skin::loadPixmap imgshow_hover]"
		bind $showpic <Leave> "$showpic configure -image [::skin::loadPixmap imgshow]"
		set_balloon $showpic [trans showdisplaypic]

		# Pack them 
		#pack $picture -side left -padx 0 -pady [::skin::getKey chatpady] -anchor w
		pack $showpic -side right -expand true -fill y -padx 0 -pady 0 -anchor e

		# Create our bindings
		bind $showpic <<Button1>> "::amsn::ToggleShowPicture $w; ::amsn::ShowOrHidePicture $w"
		bind $pictureinner <Button1-ButtonRelease> "::amsn::ShowPicMenu $w %X %Y\n"
		bind $pictureinner <<Button3>> "::amsn::ShowPicMenu $w %X %Y\n"
			
		#For TkAqua: Disable temporary, crash issue with that line
		if { ![OnMac] } {
			bind $picture <Configure> "::ChatWindow::ImageResized $w %h [::skin::getKey chat_dp_pady]"
		}

		# This proc is called to load the Display Picture if exists and is readable
		#load_my_pic

		return $frame

	}

        #///////////////////////////////////////////////////////////////////////////////
        # ::ChatWindow::GoToPrevTab ( container )
        # Used to switch to the next tab in a container. Called by the binding for the
        # <ctrl>+<PageUp> key combination. The list of windows in the container is used to
        # determine the next tab. ::ChatWindow::SwitchToTab is used for switching.
        # Arguments:
        # - container => The container window in which the current tab is located.
        proc GoToPrevTab { container } {
            set currentWin [::ChatWindow::getCurrentTab $container]
            set windows [set ::ChatWindow::containerwindows($container)]
            set tabPos [lsearch $windows $currentWin]

            # If the current tab is the last go the the first, else go to the next.
            if { $tabPos == 0 } {
                set nextTab [expr {[llength $windows] - 1}]
            } else {
                set nextTab [expr {$tabPos - 1}]
            }

            SwitchToTab $container [lindex $windows $nextTab]
        }
        #///////////////////////////////////////////////////////////////////////////////


        #///////////////////////////////////////////////////////////////////////////////
        # ::ChatWindow::GoToNextTab ( container )
        # Used to switch to the next tab in a container. Called by the binding for the
        # <ctrl>+<pagedown> key combination. The list of windows in the container is used to
        # determine the next tab. ::ChatWindow::SwitchToTab is used for switching.
        # Arguments:
        # - container => The container window in which the current tab is located.
        proc GoToNextTab { container } {
            set currentWin [::ChatWindow::getCurrentTab $container]
            set windows [set ::ChatWindow::containerwindows($container)]
            set tabPos [lsearch $windows $currentWin]

            # If the current tab is the last go the the first, else go to the next.
            if { $tabPos == [expr {[llength $windows] - 1}] } {
                set nextTab 0
            } else {
                set nextTab [expr {$tabPos + 1}]
            }

            SwitchToTab $container [lindex $windows $nextTab]
        }
        #///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# ::ChatWindow::ImageResized (win, height, padding)
	# Resets the minsize for the bottom frame when the image size changes
	# Arguments:
	#  - win => Is the window where the image has been changed
	#  - height => Is the new height of the image
	#  - padding => Is the padding around the image
	proc ImageResized { win height padding} {
		#TODO: need to remove hard coding here
		set picheight [image height [$win.f.bottom.pic.image cget -image]]
		if { $height < $picheight } {
			set height $picheight
		}

		set h [expr {$height + ( 2 * $padding ) }]
		if { $h < 100 } {
			set h 100
		}
		
		status_log "setting bottom pane misize for $win to $h\n"
		$win.f paneconfigure $win.f.bottom -minsize $h	
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

	
	proc MeasureTextCanvas { widget id text dimension } {
		set font [$widget itemcget $id -font]
		if { $dimension == "w" } {
			if { $font != "" } {
				set idx [expr {[string first "\n" $text] - 1}] 
				if { $idx < 0 } { set idx end }
				set m [font measure $font -displayof $widget [string range $text \
					0 $idx]]
				return $m
			} else {
				set idx [expr {[string first "\n" $text] - 1}] 
				if { $idx < 0 } { set idx end }
				set f [font create -family helvetica -size 12 -weight normal]
				set m [font measure $f -displayof $widget [string range $text \
					0 $idx]]
				font delete $f
				return $m
			}
		} elseif { $dimension == "h" } {
			if { $font != "" } {
				#Get number of lines
				set n [llength [split $text "\n"]]
				#Multiply font size by no. lines and add gap between lines * (no. lines - 1).
				return [expr {$n * [font configure $font -size] + (($n - 1) * 7)}]
			} else {
				#Get number of lines
				set n [llength [split $text "\n"]]
				#Multiply font size by no. lines and add gap between lines * (no. lines - 1).
				return [expr {($n * 12) + (($n - 1) * 7)}]
			}
		}
	}

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
			#return 0
			#We have a chatwindow, but no SB for it.
			#Check if the chatid is a valid user...
			if { [lsearch [::abook::getAllContacts] $chatid] != -1 } {
				set user_list $chatid
			} else {
				return 0
			}
		}

		set win_name [::ChatWindow::For $chatid]
		
		set top [::ChatWindow::GetTopFrame ${win_name}]

		set scrolling [getScrolling [::ChatWindow::GetOutText ${win_name}]]

		$top dchars text 0 end

		#remove the camicon(s)
		$top delete camicon
		
		set nroflines 0

		set camicon [::skin::loadPixmap camicon]

		foreach user_login $user_list {

			set shares_cam [::abook::getContactData $user_login webcam_shared]
			
			if { [::config::getKey emailsincontactlist] == 1 } {
				set user_name ""
			} else {
				set user_name [string map {"\n" " "} [::abook::getDisplayNick $user_login]]
			}
			set state_code [::abook::getVolatileData $user_login state]

			set psmmedia [::abook::getpsmmedia $user_login]
			set customnick [::abook::getContactData $user_login customnick]
			set globalnick [::config::getKey globalnick]

			if { [::config::getKey psmplace] == 0 } {
				set psmmedia ""
			}

			#Space added so it doesn't stick next to the status
			if { $psmmedia != "" } {
				append psmmedia " "
			}

			if { $state_code == "" } {
				set user_state ""
				set state_code FLN
			} else {
				set user_state [::MSN::stateToDescription $state_code]
			}

			set user_image [::MSN::stateToImage $state_code]

			if {[::config::getKey truncatenames]} {

				#Calculate maximum string width
				set maxw [expr {[winfo width $top] - [::skin::getKey topbarpadx] - [expr {int([lindex [$top coords text] 0])} ] } ]
				if { $shares_cam == 1} {
					incr maxw [expr { 0 - [image width $camicon] - 10 }]
				}

				if { "$user_state" != "" && "$user_state" != "online" } {
					incr maxw [expr { 0 - [font measure sboldf -displayof $top " \([trans $user_state]\)"] } ]
				}


				incr maxw [expr { 0 - [font measure sboldf -displayof $top " <${user_login}>"] } ]

				if { [font measure sboldf -displayof $top "${user_name}"] > $maxw } {
					set nicktxt "[trunc ${user_name} ${win_name} $maxw sboldf] <${user_login}>"
				} else {
					incr maxw [expr { 0 - [font measure sboldf -displayof $top " ${user_name}"] } ]
				 	set nicktxt "${user_name} <${user_login}> [trunc ${psmmedia} ${win_name} $maxw sboldf]"
				}
				
			} else {

				set nicktxt "${user_name} <${user_login}> $psmmedia"
		
			}

	
			$top insert text end $nicktxt			

			if { $user_name != "" } {
				set title "${title}${user_name}, "
			} else {
				set title "${title}${user_login}, "
			}
	
			if { "$user_state" != "" && "$user_state" != "online" } {
				set statetxt "\([trans $user_state]\)"
				$top insert text end $statetxt
			}

			$top insert text end "\n"
			
			incr nroflines			
			
			if { $shares_cam == 1 } {

				#the image aligned-right to the text
				set Xcoord [expr {[winfo width $top] - [image width $camicon]}]

				set Ycoord [expr {[lindex [$top coords text] 1] + ([font configure splainf -size]/2) + ([font configure splainf -size]*($nroflines-1))}]

	
				$top create image $Xcoord $Ycoord -anchor w -image $camicon -tags [list camicon camicon_$user_login] -state normal

				#If clicked, invite the user to send webcam
				$top bind camicon_$user_login <Button-1> "::MSNCAM::AskWebcamQueue $user_login" 

				#add the balloon-binding
				$top bind camicon <Enter> [list balloon_enter %W %X %Y "[trans askwebcam]"]
				$top bind camicon <Motion> [list balloon_motion %W %X %Y "[trans askwebcam]"]
				$top bind camicon <Leave> "set Bulle(first) 0; kill_balloon"				
				#change the cursor
				$top bind camicon <Enter> "+$top configure -cursor hand2"
				$top bind camicon <Leave> "+$top configure -cursor left_ptr"
			}
		}

		bind $top <Configure> "::ChatWindow::TopUpdate $chatid"

		#Change color of top background by the status of the contact
		ChangeColorState $user_list $user_state $state_code ${win_name}

		set title [EscapeTitle [string replace $title end-1 end " - [trans chat]"]]

		#Calculate number of lines, and set top text size

		set size [$top index text end]

		set ::ChatWindow::titles(${win_name}) ${title}
		
		$top dchars text [expr {$size - 1}] end
		
		$top configure -height [expr {[MeasureTextCanvas $top "text" [$top itemcget text -text] "h"] + 2*[::skin::getKey topbarpady]}]

		if { [GetContainerFromWindow $win_name] == "" } {
			if { [info exists ::ChatWindow::new_message_on(${win_name})] && $::ChatWindow::new_message_on(${win_name}) == "asterisk" } {
				wm title ${win_name} "*${title}"
			} else {
				wm title ${win_name} ${title}
			}
		} else {
			NameTabButton $win_name $chatid
		}

		if { $scrolling } { catch {::ChatWindow::Scroll [::ChatWindow::GetOutText ${win_name}]} }

		#PostEvent 'TopUpdate'
		set evPar(chatid) "chatid"
		set evPar(win_name) "win_name"
		set evPar(user_list) "user_list"
		::plugins::PostEvent TopUpdate evPar
		

		update idletasks

		after cancel "::ChatWindow::TopUpdate $chatid"

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
				set tcolour [::skin::getKey topbarawaytext]
				set bcolour [::skin::getKey topbarawayborder]
			} elseif { ($state_code == "PHN") || ($state_code == "BSY") } {
				set colour [::skin::getKey topbarbusybg]
				set tcolour [::skin::getKey topbarbusytext]
				set bcolour [::skin::getKey topbarbusyborder]
			} elseif { ($state_code == "FLN") } {
				set colour [::skin::getKey topbarofflinebg]
				set tcolour [::skin::getKey topbarofflinetext]
				set bcolour [::skin::getKey topbarofflineborder]
			}
		}
		#set the areas to the colour
		
		set top [GetTopFrame ${win_name}]
		$top configure -bg $colour -bordercolor $bcolour
		$top itemconfigure text -fill $tcolour
		$top itemconfigure to -fill $tcolour
		
		set bg "::$top.bg"

		if { [::skin::getKey chat_top_pixmap] && [info procs $bg] != ""} {
			set topimg [$bg cget -source]
			$topimg copy [::skin::loadPixmap cwtopback]
			::picture::Colorize $topimg $colour
			$bg BuildImage
			bind $top <Configure> "[bind $top <Configure>]; $bg configure -width %w -height %h" 
		}
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
		if {![winfo exists $win]} { return }
		if { $win == [GetCurrentWindow [winfo toplevel $win]] } { return }

		set tab $win2tab($win)
		set container [string range $tab 0 [expr {[string last "." $tab] - 1}] ]
		set container [string range $container 0 [expr {[string last "." $container] -1}] ]

		#if tab is not visible, then we should change the color of the < or > button
		#to let know there is an invisible tab flickering (an incoming message)
		if { [info exists visibletabs($container)] } {
			foreach window containerwindows($container)] {
				set visible 0
				foreach winvisible [set visibletabs($container)] {
					if { ![string equal $window $winvisible] } {
					if { !$visible && [string equal $window $win] } {
							set right 0
						} elseif { [string equal $window $win] } {
							set right 1
						}
					} else {
						set visible 1
					}
				}
			}
			if { [info exists right] } {
				if { $right == 0 } {
					#we change the less color
					status_log ">>>>>>>>>>> coloring button less: ${container}.bar.less\n"
					catch { ${container}.bar.less configure -bg green }
				} else {
					#we flicker the more button
					status_log ">>>>>>>>>>> coloring button more: ${container}.bar.more\n"
					catch { ${container}.bar.more configure -bg green }
				}
			}
		}

		if { [::picture::IsAnimated [::skin::GetSkinFile pixmaps tab_flicker.gif]] } {
			$tab itemconfigure tab_bg -image [::skin::loadPixmap tab_flicker]
		} else {			


			after cancel "::ChatWindow::FlickerTab $win 0"
			if { $new == 1 || ![info exists winflicker($win)]} {
				set winflicker($win) 0
			}

			set count [set winflicker($win)]


			if { [expr {$count % 2}] == 0 } {
				$tab itemconfigure tab_bg -image [::skin::loadPixmap tab_flicker]
			} else {
				$tab itemconfigure tab_bg -image [::skin::loadPixmap tab]	
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
			
			if { [OnMac] } {
				lower $container
			}
			
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

		#New canvas-based tab
		canvas $tab -bg [::skin::getKey tabbarbg] -bd 0 -relief flat -width [image width [::skin::loadPixmap tab]] \
			-height [image height [::skin::loadPixmap tab]] -highlightthickness 0

		$tab create image 0 0 -anchor nw -image [::skin::loadPixmap tab] -tag tab_bg

		set nick [string trim $win] ;# to avoid havng a blank tab if the user has  a nick like "\n\n\n my nick"
		set idx [string first "\n" $nick]
		if { $idx != -1 } {
		        set nick [string range $nick 0 [expr {$idx -1}]]
		}

		$tab create text [::skin::getKey tab_text_x] [::skin::getKey tab_text_y] -anchor nw -text "$nick" -fill [::skin::getKey tabfg] -tag tab_text -font sboldf -width [::skin::getKey tab_text_width]
		$tab create image [::skin::getKey tab_close_x] [::skin::getKey tab_close_y] -anchor nw -image [::skin::loadPixmap tab_close] -activeimage [::skin::loadPixmap tab_close_hover] -tag tab_close


		bind $tab <Enter> "::ChatWindow::TabEntered $tab $win"
		bind $tab <Leave> "::ChatWindow::TabLeft $tab"
		bind $tab <<Button2>> "::ChatWindow::CloseTab $tab"
		$tab bind tab_close <ButtonRelease-1> [list after 0 "::ChatWindow::CloseTab $tab"]
		$tab bind tab_bg <ButtonRelease-1> "::ChatWindow::SwitchToTab $container $win"
		$tab bind tab_text <ButtonRelease-1> "::ChatWindow::SwitchToTab $container $win"

		set tab2win($tab) $win
		set win2tab($win) $tab

		bind $tab <<Button3>> [list ::ChatWindow::createRightTabMenu $tab %X %Y]

		return $tab
		
	}

	proc CloseTab { tab {detach 0}} {
		variable win_history
		variable containercurrent
		variable containerprevious
		variable containerwindows
		variable tab2win
		variable win2tab
		
		set win [set tab2win($tab)]

		set container [winfo toplevel $win]

		if {!$detach} {
			array unset win_history [GetInputText $win]
		}
		
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
		        ChatWindowDestroyed $container
		} else {
			SwitchToTab $container $newwin
		}
		
	}

	proc TabEntered { tab win } {
		
		after cancel "::ChatWindow::FlickerTab $win"; 
		set ::ChatWindow::oldpixmap($tab) [$tab itemcget tab_bg -image] 
		$tab itemconfigure tab_bg -image [::skin::loadPixmap tab_hover]
		
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

		$tab itemconfigure tab_bg -image $image
	 }

	#///////////////////////////////////////////////////////////////////////////////////
	# NameTabButton $win $chatid
	# This proc changes the name of the tab
	proc NameTabButton { win chatid } {
		variable win2tab
		
		set tab [set win2tab($win)]
		set users [::MSN::usersInChat $chatid]
		# We have two ways of changing a tab button text
		if { $::tcl_version >= 8.4 } {
			set tabvar $tab
		} else {
			set tabvar ${tab}_lbl
		}
		#status_log "naming tab $win with chatid info $chatid\n" red
		set max_w [::skin::getKey tab_text_width]
		
		if { $users == "" || [llength $users] == 1} {
			set nick [::abook::getDisplayNick $chatid]
			if { $nick == "" || [::config::getKey tabtitlenick] == 0 } {
				#status_log "writing chatid\n" red
				$tabvar itemconfigure tab_text -text "[trunc $chatid $tab $max_w sboldf]"
			} else {
				#status_log "found nick $nick\n" red
				$tabvar itemconfigure tab_text -text "[trunc $nick $tab $max_w sboldf]"
			}
		} elseif { [llength $users] != 1 } {
			set number [llength $users]
			#status_log "Conversation with $number users\n" red
			$tabvar itemconfigure tab_text -text "[trunc [trans conversationwith $number] $tab $max_w sboldf]"
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
		variable containerwindows

		set title ""
		
		if { [info exists containerwindows($container)] &&
		     [lsearch [set containerwindows($container)] $win] == -1 } { 
			status_log "can't switch to a window that doesn't belong to the correct container"
			return 
		}
		
#TODO:		# Don't switch if tab clicked is already current tab. > 2 used because otherwise windows for new mesages dont appear. this means this is only effective with three or more tabs open. hope someone can find how to fix this.
		if { [info exists containercurrent($container)] == 1 && [set containercurrent($container)] == $win && [llength [set containerwindows($container)]] > 2  } { return }

		if { [info exists containercurrent($container)] && [set containercurrent($container)] != "" } {
			set w [set containercurrent($container)]
			pack forget $w
			set containerprevious($container) $w
			if { [info exists win2tab($w)] } {
				set tab $win2tab($w)
				$tab itemconfigure tab_bg -image [::skin::loadPixmap tab]
			}
		}
		

		
		set  containercurrent($container) $win
		pack $win -side bottom -expand true -fill both

		# Tell search dialog we've changed tabs
		if { [winfo exists $container.search] } {
			$container.search configure -searchin [::ChatWindow::GetOutText $win]
		}

		if { ![info exists containerprevious($container)] } {
			set containerprevious($container) $win
		}

		if { [info exists win2tab($win)] } {
			set tab $win2tab($win)
			$tab itemconfigure tab_bg -image [::skin::loadPixmap tab_current]
		}

		$container.menu.view entryconfigure [trans showdisplaypic] -variable "${win}_show_picture"

		::ChatWindow::UpdateContainerTitle $container

		bind $win <Map> [list focus [::ChatWindow::GetInputText $win] ]


	}

	proc UpdateContainerTitle { container } {
		#get the name of the "window" which is hte name of the tab in fact
		set win [GetCurrentWindow $container]
		#get the ID of the chat (email if only one user)
		set chatid [::ChatWindow::Name $win]

		#we'll set a title for the container-window, beginning from scratch
		set title ""

#TODO: have the titled made up with a template with vars like $nicknames, $groupname and [trans chat] etc
		if { $chatid != 0 } {
			#append all nicknames in the chat first to the title	
			foreach user [::MSN::usersInChat $chatid] { 
				#strip out newlines and tabs
				set nick [string map {"\n" " " "\t" " "} [::abook::getDisplayNick $user]]
				set title "${title}${nick}, "
			}

			#replace the last ", " with " : <name of the containerwindow> - chat"
			set title [string replace $title end-1 end " : [GetContainerName $container] - [trans chat]"]
		}

		if { $title == "" &&  [::OIM_GUI::IsOIM $chatid] == 1 } {
			set title "$chatid - [trans oim]"
		}
		#don't think this proc does much .. anyway ;)
		set title [EscapeTitle $title]
		#store our generated title in the array which is needed to reset the title after out "blink"
		set ::ChatWindow::titles($container) $title

		#put an asterisk for the title if a new message has arrived
		if { [info exists ::ChatWindow::new_message_on($container)] && [set ::ChatWindow::new_message_on($container)] == "asterisk" } {
			wm title $container "*$title"
		} else {
			wm title $container "$title"
		}
		
	}

	#this proc is to get the name of the containerwindow, like groupname for groupchats
	proc GetContainerName { container } {
		variable containers

		foreach type [array names containers] {
			if { $container == [set containers($type)] } {
				if { $type == "global" } {
					return ""
				} elseif { [string first "group" $type] == 0} {
					set gid [string range $type 5 end]
					set name [::groups::GetName $gid]
					if {$name != "" } {
						return "$name"
					} else {
						return "$type"
					}
				} else {
					return "$type"
				}
			}
		} 

		return ""
	}

	proc UseContainer { } {
		set istabbed [::config::getKey tabbedchat]

		if { $istabbed == 1 || $istabbed == 2 } {
			return 1
		} else {
			return 0
		}

	}

	proc CheckForTooManyTabs { container {dorepack "1"}} {
		variable containerwindows
		variable visibletabs
		variable win2tab
		set bar_w [winfo width ${container}.bar]
		set tab_w [image width [::skin::loadPixmap tab]]

		set less_w [image width [::skin::loadPixmap moretabs]] 
		set more_w [image width [::skin::loadPixmap lesstabs]]

		#set less_w [font measure sboldf <]
		#set more_w [font measure sboldf >]

		set bar_w [expr {$bar_w - $less_w - $more_w}]
		

		set max_tabs [expr int(floor($bar_w / $tab_w))]
		set number_tabs [llength [set containerwindows($container)]]
	
		set less ${container}.bar.less
		set more ${container}.bar.more
		destroy $less
		destroy $more

#		status_log "Got $number_tabs tabs in $container that has a max of $max_tabs\n" red

		if { $number_tabs < 2 } {
			pack forget ${container}.bar
		} else {
			#Fix  hidden tabs problem, thanks to Le philousophe
			pack ${container}.bar -side top -fill both -expand false
			
			#These lines are absolutely necessary on Mac OS X to fix a crash problem
			if { [OnMac] && [winfo exists [GetCurrentWindow $container]] && $dorepack } {
				pack forget [GetCurrentWindow $container]
				pack [GetCurrentWindow $container] -side bottom -expand true -fill both
			}

		}
		if { $max_tabs > 0 && $number_tabs > $max_tabs } {
			#-image [::skin::loadPixmap lesstabs] 
			#[image width [::skin::loadPixmap lesstabs]] 
			label $less -image [::skin::loadPixmap lesstabs] \
			    -width $less_w \
			    -fg black -bg [::skin::getKey tabbarbg] -bd 0 -relief flat \
			    -activebackground [::skin::getKey tabbarbg] -activeforeground black \
			    -highlightthickness 0 -pady 0 -padx 0
			bind $less <<Button1>> "::ChatWindow::LessTabs $container $less $more"
			#-image [::skin::loadPixmap moretabs] 
			#[image width [::skin::loadPixmap lesstabs]] 
			label $more -image [::skin::loadPixmap moretabs] \
			    -width $more_w \
			    -fg black -bg [::skin::getKey tabbarbg] -bd 0 -relief flat \
			    -activebackground [::skin::getKey tabbarbg] -activeforeground black \
			    -highlightthickness 0 -pady 0 -padx 0
			bind $more <<Button1>> "::ChatWindow::MoreTabs $container $less $more"
			if { $::tcl_version >= 8.4 } {
				$less configure -compound center
				$more configure -compound center
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
		
		set visible [lrange $windows $first_idx [expr {$first_idx + $max - 1}]]
		if { [llength $visible] < $max } {
			set visible [lrange $windows end-[expr {$max -1}] end]
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
		global win_history
		set win [set ::ChatWindow::tab2win($tab)]
		set out [GetOutText $win]
		set in [GetInputText $win]
		set dump_out [$out dump 0.0 end]
		set dump_in [$in dump 0.0 end]

		foreach tag [$out tag names] {
			foreach option [$out tag configure $tag] {
				if { ([llength $option] == 5) && ([lindex $option 4] != {}) } {
					lappend tags_out($tag) [lindex $option 0]
					lappend tags_out($tag) [lindex $option 4]
				}
			}
		}


		status_log "Got dumps : \n$dump_out\n\n$dump_in\n" red

		set chatid [Name $win]
		
		UnsetFor $chatid $win
		set new [RecreateWindow $chatid]

		set ::ChatWindow::titles(${new}) [set ::ChatWindow::titles(${win})]
		set ::ChatWindow::first_message(${new}) [set ::ChatWindow::first_message(${win})]
		set ::ChatWindow::recent_message(${new}) [set ::ChatWindow::recent_message(${win})]
		set ::ChatWindow::containercurrent(${new}) ${new}

		#We now copy the history of what we said
		set winhisto [GetInputText $win]
		set newhisto [GetInputText $new]
		if { [info exists win_history(${winhisto}_count)] } {
			set win_history(${newhisto}_count) $win_history(${winhisto}_count)
			set win_history(${newhisto}_index) $win_history(${winhisto}_index)
			set win_history(${newhisto}) $win_history(${winhisto})
			if { [info exists win_history(${winhisto}_temp)] } {
				set win_history(${newhisto}_temp) $win_history(${winhisto}_temp)
			}
		}
		
		unset ::ChatWindow::titles(${win})
		unset ::ChatWindow::first_message(${win})
		unset ::ChatWindow::recent_message(${win})

		#Delete images if not in use
		catch {destroy $win.bottom.pic}

		CloseTab $tab 1

		#We now clean the old history
		if { [info exists win_history(${winhisto}_count)] } {
			unset win_history(${winhisto}_count)
			unset win_history(${winhisto}_index)
			unset win_history(${winhisto})
			if { [info exists win_history(${winhisto}_temp)] } {
				unset win_history(${winhisto}_temp)
			}
		}
		
		set out [GetOutText $new]
		set in [GetInputText $new]

		$out configure -state normal -font bplainf -foreground black

		undump $out $dump_out 1 [array get tags_out]
		#We dumped an invisible new line due to end index so remove it now
		$out delete "end - 1 lines"
		undump $in $dump_in 0
		$in delete "end - 1 lines"
		
	}

	proc undump { w dump rotext {tags_config ""}} {
		status_log "tags : $tags_config\n" red
		if { $rotext } { set insert_cmd roinsert } else { set insert_cmd insert }
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
					$w $insert_cmd $index $value
				} 
				mark {
					$w mark set $value $index
				} 
				image {
					if { [catch {image width $value} ]} {
						if { [string first "#" $value] != -1 } {
							set value [string range $value 0 [expr {[string last "#" $value] -1}]]
						} else {
							set value ""
						}
						if { [catch {image width $value} ]} {
							set value ""
						}
						
					}
					if { $value != "" } {
						$w image create $index -image $value
					}
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

		if { [OnMac] } {
			::ChatWindow::MacPosition ${top_win}
		}
		::ChatWindow::TopUpdate $chatid

		set usr_name [lindex [::MSN::usersInChat $chatid] 0]
		if { [::config::getKey showdisplaypic] && $usr_name != ""} {
	
			::amsn::ChangePicture $win_name [::skin::getDisplayPicture $usr_name] [trans showuserpic $usr_name]
			
		} else {
			::amsn::ChangePicture $win_name [::skin::getDisplayPicture $usr_name] [trans showuserpic $usr_name] nopack
			
		}
		
		#We have a window for that chatid, raise it
		raise ${top_win}

		focus [::ChatWindow::GetInputText ${win_name}]

		return $win_name

	}

	###################################################
	# proc getScrolling : gets the scrolling status of
	# textwidget $tw. Returns 1 to scroll, 0 not to.
	
	proc getScrolling { tw } {
		variable scrolling
		
		#status_log "getScrolling: $tw\n"
		
		if { [info exists scrolling($tw)] } {
		#We are scrolling to the bottom so we are obviously stuck to the end
			return 1
		} elseif { [winfo exists $tw] } {
			if { [lindex [$tw yview] 1] == 1.0 } {
				#We are at the bottom of the tw so we are stuck to the end
				return 1
			} else {
				#The tw doesn't exist
				return 0
			}
		} else {
			return 0
		}
	}
	
	#########################################################
	# proc Scroll : Scrolls down the textwidget $tw

	proc Scroll { tw } {
		variable scrolling

		if { ![winfo exists $tw] } { return }
		
		if { ![info exists scrolling($tw)] } {
			set scrolling($tw) 0
		}
		#status_log "Scroll: $tw "
		incr scrolling($tw)
		$tw yview end

		after 100 "catch {incr ::ChatWindow::scrolling($tw) -1; if {\$::ChatWindow::scrolling($tw) == 0 } {unset ::ChatWindow::scrolling($tw) }}"
		
	}
}

::snit::widget chatwindow {

	hulltype toplevel
	delegate option * to hull

	constructor {args} {
#		button $win.open -text Open -command [mymethod open]
#		button $win.save -text Save -command [mymethod save]

		# ....

		$self configurelist $args

	}

	method messageReceived { message } {
		status_log "(chatwindow.tcl)[$message getBody]"
	}
}


proc EscapeTitle { title } {
	
        return $title

	# This RE is just a character class for everything "bad"
	set RE {[\u0080-\uffff]}
	
	# We will substitute with a fragment of Tcl script in brackets
	set substitution "?" ;#{[format \\\\u%04x [scan "\\&" %c]]}
	
	# Now we apply the substitution to get a subst-string that
	# will perform the computational parts of the conversion.
	return [regsub -all $RE $title $substitution]

}
