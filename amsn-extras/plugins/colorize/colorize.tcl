namespace eval ::colorize {
    variable config
    variable configlist
    variable at 0
    
    proc InitPlugin { dir } {
	variable configlist
	plugins_log gename "Welcome to Colorize!\n"
	::plugins::RegisterPlugin Colorize
	::plugins::RegisterEvent Colorize chat_msg_sent rotateColor
	array set ::colorize::config [list \
					  colors [list "FF0000" "006236" ] \
					  random 0 \
					 ]
	set configlist [list \
			    [list frame ::colorize::build_config] \
			    [list bool "Random colors" random] \
			   ]
    }
    
    proc rotateColor {event epvar} {
	variable at
	set current [::config::getKey mychatfont]
	if {$::colorize::config(random)==1} {
	    set r [expr int(rand()*255)]
	    set g [expr int(rand()*255)]
	    set b [expr int(rand()*255)]
	    set color [format "%02x%02x%02x" $r $g $b]
	    plugins_log "Colorize" "new color: $color"
	} else {
	    if {$at >= [llength $::colorize::config(colors)]} {
		set at 0
	    }
	    set color [lindex $::colorize::config(colors) $at]
	    incr at
	}
	::config::setKey mychatfont [list [lindex $current 0] [lindex $current 1] $color]
    }

    proc remove {lstbox} {
	set id [$lstbox curselection]
	if {$id!=""} {
	    $lstbox delete $id
	}
    }

    proc add {from} {
	set color [$from get]
	if {[string length $color]!=6} {
	    tk_messageBox -type ok -title "Invalid color!" -message "You didn't enter a valid color! It has to be in the format: RRGGBB. For example red would be FF0000" -icon error
	    return
	}
	if {[lsearch -exact $::colorize::config(colors) $color] >= 0} {
	    tk_messageBox -type ok -title "Duplicate color!" -message "$color already exists in the list!" -icon error
	    return
	}
	lappend ::colorize::config(colors) $color
	$from delete 0 end
    }

    proc build_config {w} {
	listbox $w.colors -listvariable ::colorize::config(colors)
	button $w.rem -text "Remove" -command "::colorize::remove $w.colors"
	entry $w.newcolor -text "#RRGGBB"
	button $w.add -text "Add" -command "::colorize::add $w.newcolor"
	pack $w.colors -fill x
	pack $w.rem -expand 1 -fill x
	pack $w.newcolor $w.add -side left -fill y
    }
}
