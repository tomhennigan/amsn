#####     Transparent Plugin     #####

namespace eval ::transparent {
	variable config
	variable configlist

	variable fadelist
	variable enabled

	## Core plugin procedures ##
	proc transparentStart { dir } {
		variable ::transparent::config
		variable ::transparent::fadelist
		variable ::transparent::enabled

		::plugins::RegisterPlugin "Transparent"
		::plugins::RegisterEvent "Transparent" new_chatwindow handleNewCW
		loadLang $dir

		array set ::transparent::config [list \
			cl_alpha {0.9} \
			cw_alpha {0.67} \
			cw_noactive {1} \
			cw_opaque {1} \
			speed_in {1.5} \
			speed_out {0.15} \
		]
		set ::transparent::configlist [list \
			[list frame ::transparent::fillConfigFrame ""]
		]

		set fadelist ""
		
		createTickets "fadelock" 256

		if {!([OnWin]) && !([OnMac]) && ${::tk_patchLevel} < "8.5"} {
			set enabled 0
			msg_box "You need Tk 8.5 to be installed to run this plugin."
			::plugins::UnLoadPlugin "Transparent"
		} else {
			set enabled 1
			after 500 ::transparent::updateAll
		}
	}

	proc transparentStop { } {
		variable ::transparent::fadelist
		variable ::transparent::enabled
		set fadelist ""
		if {$enabled} {
			set enabled 0
			updateCLAlpha 1.0
			updateCWAlpha 1.0
			updateCWOpaque 0 0
		}
		destroyTickets "fadelock"
	}

	proc loadLang { dir } {
		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir
	}

	proc fillConfigFrame { w } {
		puts "drawing transparent config frame"
		label $w.cl_label -text "[trans cltransparency]" -padx 10
		scale $w.cl_slider -from 0.1 -to 1 -resolution 0.01 -variable ::transparent::config(cl_alpha) \
			-command {::transparent::updateCLAlpha} -orient horizontal
		pack $w.cl_label -anchor sw -side left
		pack $w.cl_slider -anchor w -side right -expand true -fill x

		label $w.cw_label -text "[trans cwtransparency]" -padx 10
		scale $w.cw_slider -from 0.1 -to 1 -resolution 0.01 -variable ::transparent::config(cw_alpha) \
			-command {::transparent::updateCWAlpha} -orient horizontal
		pack $w.cw_label -anchor sw -side left
		pack $w.cw_slider -anchor w -side right -expand true -fill x

		checkbutton $w.cw_noactive -text "[trans cwnoactive]" -variable ::transparent::config(cw_noactive) \
			-command {::transparent::updateCWOpaque}
		pack $w.cw_noactive -anchor sw -side left

		checkbutton $w.cw_opaque -text "[trans cwopaque]" -variable ::transparent::config(cw_opaque) \
			-command {::transparent::updateCWOpaque}
		pack $w.cw_opaque -anchor sw -side left

		label $w.sin_label -text "[trans cwspeedin]" -padx 10
		scale $w.sin_slider -from 0.1 -to 10 -resolution 0.01 -variable ::transparent::config(speed_in) \
			-orient horizontal
		pack $w.sin_label -anchor sw -side left
		pack $w.sin_slider -anchor w -side right -expand true -fill x

		label $w.sout_label -text "[trans cwspeedout]" -padx 10
		scale $w.sout_slider -from 0.1 -to 10 -resolution 0.01 -variable ::transparent::config(speed_out) \
			-orient horizontal
		pack $w.sout_label -anchor sw -side left
		pack $w.sout_slider -anchor w -side right -expand true -fill x


		grid $w.cl_label -row 0 -column 0 -sticky sw
		grid $w.cl_slider -row 0 -column 1 -sticky we
		grid $w.cw_label -row 1 -column 0 -sticky sw
		grid $w.cw_slider -row 1 -column 1 -sticky we
		grid $w.cw_noactive -row 2 -column 0 -columnspan 2 -sticky sw
		grid $w.cw_opaque -row 3 -column 0 -columnspan 2 -sticky sw
		grid $w.sin_label -row 4 -column 0 -sticky sw
		grid $w.sin_slider -row 4 -column 1 -sticky we
		grid $w.sout_label -row 5 -column 0 -sticky sw
		grid $w.sout_slider -row 5 -column 1 -sticky we
		grid columnconfigure $w 1 -weight 1

		pack $w

		bind $w <Destroy> "::transparent::updateAll"
	}

	## Generic procedures ##
	
	# Return the alpha value of a window
	proc getAlpha { w } {
		set a -1
		if {[winfo exists $w] && [winfo toplevel $w] == $w} {
			catch {set a [wm attributes $w -alpha]}
		}
		return $a
	}

	# Set the alpha value of a window to a given value
	proc setAlpha { w alpha } {
		if {[winfo exists $w] && [winfo toplevel $w] == $w} {
			variable ::transparent::enabled
			if { $enabled || $alpha == 1.0} {
				catch {wm attributes $w -alpha $alpha}
			}
		}
	}

	# Check if a procedure is bound to an event of a widget
	proc isbound { w event script } {
		set bindings [bind $w $event]
		set index [string first $script $bindings]
		if {$index != -1} {
			return 1
		} else {
			return 0
		}
	}

	# Unbind a procedure from an event of a widget
	proc unbind { w event script } {
		set bindings [bind $w $event]
		set index [string first $script $bindings]
		if {$index != -1} {
			set bindings [string replace $bindings $index [expr { $index + [string length $script]}] "" ]
			bind $w $event $bindings
		}
	}

	# Check if a window is focused
	proc isFocused { w } {
		if {[catch {set focused [winfo toplevel [focus]]}] || ($focused != $w) } {
			return 0
		} else {
			return 1
		}
	}

	# Return the list of all the open chat windows
	proc getCWList { } {
		set chatids [::ChatWindow::getAllChatIds]
		set cw_list ""
		foreach id $chatids {
			lappend cw_list [winfo toplevel [::ChatWindow::For $id]]
		}
		if {$cw_list != ""} {
			set cw_list [lsort -unique $cw_list]
		}
		return $cw_list
	}
	
	## Ticket system procedures ##
	
	# Create a new ticket system
	proc createTickets {name n} {
		variable ticket_$name
		variable now_serving_$name
		variable n_tickets_$name
		set ticket_$name 0
		set now_serving_$name 0
		set n_tickets_$name $n
	}
	
	# Destroy a ticket system
	proc destroyTickets {name} {
		variable ticket_$name
		variable now_serving_$name
		variable n_tickets_$name
		unset ticket_$name
		unset now_serving_$name
		unset n_tickets_$name
	}
	
	# Wait until your number is called
	proc waitTurn {name} {
		variable ticket_$name
		variable now_serving_$name
		variable n_tickets_$name
		set my_ticket [set ticket_$name]
		set ticket_$name [expr {($my_ticket + 1) % [set n_tickets_$name]}]
		while {[set now_serving_$name] != $my_ticket} {
			vwait now_serving_$name
		}
	}

	# Call next number
	proc nextTurn {name} {
		variable ticket_$name
		variable now_serving_$name
		variable n_tickets_$name
		set now_serving_$name [expr {([set now_serving_$name] + 1) % [set n_tickets_$name]}]
	}

	
	## Fade procedures ##
	
	# Perform a recursive step of the fade process of a window
	proc fadeWindow { index } {
		variable ::transparent::fadelist
		set entry [lindex $fadelist $index]
		if {$entry == ""} {
			return
		}
		set w [lindex $entry 0]
		set target_alpha [lindex $entry 1]
		set step [lindex $entry 2]
		set timestep 50
		set alpha [getAlpha $w]
		if { $alpha != -1 && $alpha != $target_alpha } {
			if { $alpha > $target_alpha } {
				set new_alpha [expr {$alpha - $step}]
				if { $new_alpha < $target_alpha } {
					set new_alpha $target_alpha
				}
			} else {
				set new_alpha [expr {$alpha + $step}]
				if { $new_alpha > $target_alpha } {
					set new_alpha $target_alpha
				}
			}
			setAlpha $w $new_alpha
			if {$new_alpha != $target_alpha} {
				after $timestep [list ::transparent::fadeWindow $index]
				return
			}
		}
		::transparent::removeFadeEntry $index
	}

	# Add a window to the fade list
	proc addFadeEntry { w alpha speed } {
		if {[winfo exists $w] && [winfo toplevel $w] == $w} {
			variable ::transparent::fadelist
			waitTurn "fadelock"
			variable ::transparent::config
			set timestep 50
			set step [expr { ( $speed * $timestep ) / 1000 }]
			set newentry [list $w $alpha $step]
			set l [llength $fadelist]
			if {$l==0} {
				list fadelist
			}
			set index 0
			foreach entry $fadelist {
				if {$entry != "" && [lindex $entry 0] == $w} {
					break
				}
				incr index
			}
			if { $index == $l } {
				set fadelist [lappend fadelist $newentry]
				nextTurn "fadelock"
				return $index
			} else {
				set fadelist [lreplace $fadelist $index $index $newentry]
				nextTurn "fadelock"
			}
		}
		return -1
	}
	
	# Remove a window to the fade list
	proc removeFadeEntry { index } {
		variable ::transparent::fadelist

		waitTurn "fadelock"

		set fadelist [lreplace $fadelist $index $index ""]

		set l [llength $fadelist]
		set i [expr {$l - 1}]
		while {$i >= 0 && [lindex $fadelist $i] == ""} {
			set i [expr {$i - 1}]
		}
		incr i
		if {$i != $l} {
			set fadelist [lreplace $fadelist $i end]
		}
		nextTurn "fadelock"
	}

	## Event handlers ##
	
	# Handle the creation of a new chat window
	proc handleNewCW { event epvar } {
		variable ::transparent::config
		upvar 2 $epvar args
		set win [winfo toplevel $args(win)]
		setAlpha $win $config(cw_alpha)
		updateBindings $win $config(cw_opaque) $config(cw_noactive)
	}

	# Make a window opaque
	proc fadeIn { w } {
		# Workaround for the "black flash" under Windows XP
		if {[OnWin]} {
			set max 0.999
		} else {
			set max 1.0
		}
		variable ::transparent::config
		set index [addFadeEntry $w $max $config(speed_in)]
		if { $index != -1 } {
			fadeWindow $index
		}
	}

	# Make a window transparent
	proc fadeOut { w } {
		variable ::transparent::config
		if { $config(cw_noactive) && [isFocused $w]} {
			return
		}
		set index [addFadeEntry $w $config(cw_alpha) $config(speed_out)]
		if { $index != -1 } {
			fadeWindow $index
		}
	}

	## Helper procedures ##
	
	# Update the alpha value of all the windows
	proc updateAll { } {
		variable ::transparent::config
		updateCLAlpha $config(cl_alpha)
		updateCWAlpha $config(cw_alpha)
		updateCWOpaque $config(cw_opaque) $config(cw_noactive)
	}

	# Update the alpha value of the contact list
	proc updateCLAlpha { cl_alpha } {
		setAlpha . $cl_alpha
	}

	# Update the alpha value of all the chat windows
	proc updateCWAlpha { cw_alpha } {
		set cw_list [getCWList]
		foreach cw $cw_list {
			setAlpha $cw $cw_alpha
		}
	}

	# Update the bindings of the windows according to the plugin configuration
	proc updateCWOpaque { { cw_opaque -1 } { cw_noactive -1 }} {
		variable ::transparent::config
		if {$cw_opaque == -1} {
			set cw_opaque $config(cw_opaque)
		}
		if {$cw_noactive == -1} {
			set cw_noactive $config(cw_noactive)
		}
		set cw_list [getCWList]
		foreach cw $cw_list {
			updateBindings $cw $cw_opaque $cw_noactive
		}
	}

	proc updateBindings { w opaque noactive } {
		if {[isbound $w <Enter> "::transparent::fadeIn %W"] != $opaque} {
			if {$opaque} {
				bind $w <Enter> "+::transparent::fadeIn %W"
			} else {
				unbind $w <Enter> "::transparent::fadeIn %W"
			}
		}
		if {[isbound $w <Leave> "::transparent::fadeOut %W"] != $opaque} {
			if {$opaque} {
				bind $w <Leave> "+::transparent::fadeOut %W"
			} else {
				unbind $w <Leave> "::transparent::fadeOut %W"
				::transparent::fadeOut $w
			}
		}
		if {[isbound $w <FocusIn> "::transparent::fadeIn %W"] != $noactive} {
			if {$noactive} {
				bind $w <FocusIn> "+::transparent::fadeIn %W"
			} else {
				unbind $w <FocusIn> "::transparent::fadeIn %W"
			}
		}
		if {[isbound $w <FocusOut> "::transparent::fadeOut %W"] != $noactive} {
			if {$noactive} {
				bind $w <FocusOut> "+::transparent::fadeOut %W"
			} else {
				unbind $w <FocusOut> "::transparent::fadeOut %W"
				::transparent::fadeOut $w
			}
		}

	}
}
