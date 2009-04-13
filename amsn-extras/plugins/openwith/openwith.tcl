namespace eval ::openwith {
	variable configlist

	proc InitPlugin { dir } {
		::plugins::RegisterPlugin "Open With"
		::plugins::RegisterEvent "Open With" new_chatwindow AddToMenu

		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir

		array set ::openwith::config [list separate {} ]

		for { set i 1 } { $i <= 5 } { incr i } {
			array set ::openwith::config [list \
				prog$i {} \
				cmd$i {}
			]
		}

		set ::openwith::configlist [list \
			[list label "[trans config_lbl1]" ] \
			[list frame ::openwith::ConfigFrame "" ] \
			[list bool "[trans config_bool]" separate ] \
			[list label "[trans config_lbl2]" ] \
		]
	}

	#Procedure to add the new menu entries
	proc AddToMenu { event epvar } {
		upvar 2 $epvar args
		set w $args(win)
		set menu $w.copy

		set loc 1
		#If the user wants the first entry separate, it is found and a menu command is created.
		if { $::openwith::config(separate) == 1 } {
			while { ( $::openwith::config(prog$loc) == "" || $::openwith::config(cmd$loc) == "" ) && $loc < 6 } {
				incr loc }
			if { $loc < 6 } {
				$menu add command -label "[trans open_with] $::openwith::config(prog$loc)" -command " ::openwith::RunProgram {$::openwith::config(cmd$loc)} {$w} "
				incr loc
			}
		}

		#The rest of the entries (if any) are added in a submenu.
		while { ( $::openwith::config(prog$loc) == "" || $::openwith::config(cmd$loc) == "" ) && $loc < 6 } {
			incr loc }
		if { $loc < 6 } {
			$menu add cascade -label "[trans open_with]..." -menu $menu.progs
			menu $menu.progs -tearoff 0 -type normal
			$menu.progs add command -label $::openwith::config(prog$loc) -command " ::openwith::RunProgram {$::openwith::config(cmd$loc)} {$w} "
			incr loc
			for { set i $loc } { $i <= 5 } { incr i } {
				if { $::openwith::config(prog$i) != "" && $::openwith::config(cmd$i) != "" } {
					$menu.progs add command -label $::openwith::config(prog$i) -command " ::openwith::RunProgram {$::openwith::config(cmd$i)} {$w}" }
			}
		}
	}

	proc ConfigFrame { win } {
		label $win.progl -text "[trans config_progl]"
		label $win.cmdl -text "[trans config_cmdl]"
		grid $win.progl -row 1 -column 1
		grid $win.cmdl -row 1 -column 2 -columnspan 2

		for { set i 1 } { $i <= 5 } { incr i } {
			entry $win.p{$i}box -width 23 -textvariable ::openwith::config(prog$i) -bg white
			entry $win.c{$i}box -width 23 -textvariable ::openwith::config(cmd$i) -bg white
			button $win.browse{$i} -text "[trans browse]" -command "::openwith::BrowseFile {$i}"
			grid $win.p{$i}box -row [expr $i + 1] -column 1
			grid $win.c{$i}box -row [expr $i + 1] -column 2
			grid $win.browse{$i} -row [expr $i + 1] -column 3
		}
	}

	proc RunProgram { cmd win } {
		set res [catch {set url [selection get -displayof $win]} ]
		if { $res == 0 && $url != "" } {
			set res [catch {eval "exec $cmd &"}]
				if { $res != 0 } {
					msg_box "[trans not_found_error]"
				}
		}
	}

	proc BrowseFile { cmdnum } {
		set selfile [tk_getOpenFile -title "[trans prog_select]"]
		if { $selfile != "" } {
			set ::openwith::config(cmd$cmdnum) "\"$selfile\" \$url"
		}
	}
}
