namespace eval ::winskin {
	variable config
	variable configlist
	variable skinned 0
	variable dir
	variable dset 0

	proc Init { dir } {
		set ::winskin::dir $dir

		::plugins::RegisterPlugin winskin
		::plugins::RegisterEvent winskin ContactListColourBarDrawn draw
		::plugins::RegisterEvent winskin ContactListDrawn cldrawn
		::plugins::RegisterEvent winskin OnConnect connected

		array set ::winskin::config {
			addbuttons {1}
			hidemenu {1}
			removetop {0}
			removeicons {0}
			removestates {0}
			startskinned {0}
			topmost {0}
			titleheight {19}
		}

		set ::winskin::configlist [list \
			[list bool "Add the buttons" addbuttons] \
			[list bool "Hide the menu bar" hidemenu] \
			[list bool "Remove the top section" removetop] \
			[list bool "Remove the icons at the start of each line (0.95b or later only)" removeicons] \
			[list bool "Remove the state (in brackets) at the end of each line (0.95b or later only)" removestates] \
			[list bool "Start Skinned (on connection)" startskinned] \
			[list bool "Always On Top" topmost] \
			[list str "Height of titlebar in pixels (should not need to be changed)" titleheight] \
		]

		::skin::setPixmap winskin_move move.gif
		::skin::setPixmap winskin_remove remove.gif
		::skin::setPixmap winskin_replace replace.gif
	}

	proc totalGeometry {{w .}} {
		set geom [wm geometry $w]
		regexp -- {([0-9]+)x([0-9]+)\+(-?[0-9]+)\+(-?[0-9]+)} $geom -> \
				width height decorationLeft decorationTop
		set contentsTop [winfo rooty $w]
		set contentsLeft [winfo rootx $w]

		# Measure left edge, and assume all edges except top are the
		# same thickness
		set decorationThickness [expr {$contentsLeft - $decorationLeft}]

		# Find titlebar and menubar thickness
		set menubarThickness [expr {$contentsTop - $decorationTop}]

		incr width [expr {2 * $decorationThickness}]
		incr height $decorationThickness
		incr height $menubarThickness

		return [list $width $height $decorationLeft $decorationTop]

		return $menubarThickness
	}

	# ::winskin::switchskin
	# Description:
	#	Either removes the borders or replaces them
	#	force   -> Force to go to skinned mode
	proc switchskin { {force 0} } {
		variable skinned
		variable contentsleft
		variable titleheight

		if { ($force == 1) && ($skinned == 1) } {
				return
		}

		if { $skinned == 0 } {
			if { $::winskin::config(topmost) == 1 } {
				#Some verions of tk don't support this
				catch { wm attributes . -topmost 1 }

				update idletasks
			}

			scan [wm geometry .] "%dx%d+%d+%d" width height wx wy
			set contentsleft [expr {[winfo rootx .] - ($wx)}]
			set titlemenuheight [expr {[winfo rooty .] - ($wy)}]
			set titleheight $::winskin::config(titleheight)
			if { $::winskin::config(hidemenu) == 1 } {
				set menuheight [expr {$titlemenuheight - $titleheight - $contentsleft}]
			} else {
				set menuheight 0
			}
			set width [expr {$width - (2 * $contentsleft)}]
			#contentsleft for bottom
			set height [expr {$height - $titleheight - $contentsleft}]
			set wx [expr {$wx + $contentsleft}]
			set wy [expr {$wy + $titleheight + $contentsleft}]
			wm geometry . "${width}x${height}+${wx}+${wy}"
			update idletasks

			if { [catch { plugins_log winskin [WinRemoveTitle . $menuheight] } ] } {
				load [file join $::winskin::dir winutils.dll]
				plugins_log winskin [WinRemoveTitle . $menuheight]
			}

			set skinned 1
		} else {
			WinReplaceTitle .
			set skinned 0

			update idletasks
			scan [wm geometry .] "%dx%d+%d+%d" width height wx wy
			set width [expr {$width + (2 * $contentsleft)}]
			set height [expr {$height + $titleheight + $contentsleft}]
			set wx [expr {$wx - $contentsleft}]
			set wy [expr {$wy - $titleheight - $contentsleft}]
			wm geometry . "${width}x${height}+${wx}+${wy}"

			#Some verions of tk don't support this
			#Remove topmost
			catch { wm attributes . -topmost 0 }
		}
		cmsn_draw_online
	}


	# ::winskin::connected
	# Description:
	#	On connection switches to skinned mode if set to start skinned
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#     evPar   -> The array of parameters (Supplied by Plugins System)
	proc connected {event evPar} {		
		if { $::winskin::config(startskinned) == 1 } {
			::winskin::switchskin 1
		}		
	}


	# ::winskin::cldrawn
	# Description:
	#	Adds a line in the contact list
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#     evPar   -> The array of parameters (Supplied by Plugins System)
	proc cldrawn {event evPar} {		
		upvar 2 $evPar vars
		variable skinned

		if { ($::winskin::config(removeicons) == 1) && ($skinned == 1) } {
			#remove icons
			foreach ic [$vars(text) window names] {
				if {     ([string first "$vars(text).img" "$ic"] == 0) \
					|| ([string first "$vars(text).contract" "$ic"] == 0) \
					|| ([string first "$vars(text).expand" "$ic"] == 0) \
					} {
					destroy $ic
				}
			}

			#remove spaces
			$vars(text) configure -state normal
			set pos 1.0
			while { [set pos [$vars(text) search -regexp "^    " $pos end]] != "" } {
				$vars(text) delete $pos $pos+4chars
			}
			$vars(text) configure -state disabled
		}

		if { ($::winskin::config(removestates) == 1) && ($skinned == 1) } {
			$vars(text) configure -state normal
			set x {}
			foreach a [set ::MSN::list_states] {lappend x (\\([trans [lindex $a 1]]\\)$)}
			set x [join $x "|"]
			while { [set start [$::pgBuddy.text search -regexp $x 1.0 end]] != "" } {
				set end [$::pgBuddy.text search -regexp "\\)" $start end]
				$vars(text) delete $start-1chars $end+1chars
			}
			$vars(text) configure -state disabled
		}
	}


	# ::winskin::draw
	# Description:
	#	Adds a line in the contact list
	# Arguments:
	#	event   -> The event wich runs the proc (Supplied by Plugins System)
	#     evPar   -> The array of parameters (Supplied by Plugins System)
	proc draw {event evPar} {		
		upvar 2 $evPar vars
		variable skinned

		if { ($::winskin::config(removetop) == 1) && ($skinned == 1) } {
			$vars(text) delete 1.0 end
		}

		if { $::winskin::config(addbuttons) == 1 } {
			set usedwidth 0

			set buttons $vars(text).winskinbuttons
			frame $buttons -class Amsn -relief solid \
					-width [winfo width $vars(text)]\
					-borderwidth 0 \
					-background #ffffff
			$vars(text) window create end -window $buttons -padx 0 -pady 0

			set imag $buttons.skin
			set imagm $buttons.move
			set imagc $buttons.close
			set filler $buttons.filler
			#destroy $imag $imagm $imagc
			if { $skinned == 1} {
				label $imag -image [image create photo -file [file join $::winskin::dir pixmaps remove.gif]]
				#label $imag -image [::skin::loadPixmap winskin_remove]
			} else {
				label $imag -image [image create photo -file [file join $::winskin::dir pixmaps replace.gif]]
				#label $imag -image [::skin::loadPixmap winskin_replace]
			}
			label $imagm -image [image create photo -file [file join $::winskin::dir pixmaps move.gif]]
			#label $imagm -image [::skin::loadPixmap winskin_move]
			label $imagc -image [image create photo -file [file join $::winskin::dir pixmaps close.gif]]

			$imag configure -cursor hand2 -borderwidth 0 -padx 0 -pady 0
			$imagm configure -cursor fleur -borderwidth 0 -padx 0 -pady 0
			$imagc configure -cursor hand2 -borderwidth 0 -padx 0 -pady 0

			#$vars(text) window create end -window $imag -padx 5 -pady 0
			#$vars(text) window create end -window $imagm -padx 5 -pady 0
			#$vars(text) window create end -window $imagc -padx 5 -pady 0
			pack $imagc -padx 5 -pady 0 -side right
			pack $imagm -padx 5 -pady 0 -side right
			pack $imag -padx 5 -pady 0 -side right
			update idletasks
			incr usedwidth [winfo width $imagc]
			incr usedwidth 10
			incr usedwidth [winfo width $imagm]
			incr usedwidth 10
			incr usedwidth [winfo width $imag]
			incr usedwidth 10
			frame $filler -width [expr {[winfo width $vars(text)] - $usedwidth}] \
					-borderwidth 0 \
					-background #ffffff
			pack $filler -padx 0 -pady 0 -side right -expand true

			bind $imag <1> "after 1 ::winskin::switchskin"
			bind $imagm <1> "::winskin::buttondown"
			bind $imagm <B1-Motion> "::winskin::drag"
			bind $imagm <ButtonRelease-1> "::winskin::release"
			bind $imagc <1> "::amsn::closeOrDock [::config::getKey closingdocks]"

			$vars(text) insert end "\n"
		}
	}

	proc buttondown { } {
		variable dset
		variable dx
		variable dy
		variable width
		variable height
		variable skinned
		variable contentsleft

		set x [winfo pointerx .]
		set y [winfo pointery .]

		bind . <Configure>
		rename ::cmsn_draw_online xxxxx
		proc ::cmsn_draw_online {{a ""}} {}

		scan [wm geometry .] "%dx%d+%d+%d" width height wx wy
		set dset 1
		set dx [expr {$wx-$x}]
		set dy [expr {$wy-$y}]

		#if skinned need to take borederwidth into account
		if { $skinned == 1 } {
			#set width [expr {$width - (2 * ([winfo rootx .] - ($wx)))}]
			set width [expr {$width - (2 * $contentsleft)}]
		}
	}

	proc drag { } {
		variable dset
		variable dx
		variable dy
		variable width
		variable height

		if { $dset } {
			set x [winfo pointerx .]
			set y [winfo pointery .]
			wm geometry . "${width}x${height}+[expr {$dx + $x}]+[expr {$dy + $y}]"
		}
	}

	proc release { } {
		variable dset
		set dset 0

		rename ::cmsn_draw_online ""
		rename xxxxx ::cmsn_draw_online
		cmsn_draw_online
	}
}
