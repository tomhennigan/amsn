namespace eval ::colorize {
    variable config
    variable configlist
    variable language
    variable at 0
    
    proc InitPlugin { dir } {
	variable configlist
	variable language
	plugins_log gename "Welcome to Colorize!\n"
	::plugins::RegisterPlugin Colorize
	::plugins::RegisterEvent Colorize chat_msg_sent rotateColor

	set langdir [file join $dir "lang"]
	set lang [::config::getGlobalKey language]
	load_lang en $langdir
	load_lang $lang $langdir

	array set ::colorize::config [list \
					  colors [list "FF0000" "00FF00" "0000FF" ] \
					  random 1 \
					 ]
	set configlist [list \
			    [list frame ::colorize::build_config] \
			    [list bool "[trans random]" random] \
			   ]
    }
    
    proc rotateColor {event epvar} {
	variable at
	set current [::config::getKey mychatfont]
	if {$::colorize::config(random)==1} {
	    set r [expr int(rand()*255)]
	    set g [expr int(rand()*255)]
	    set b [expr int(rand()*255)]
	    set total [expr $r + $g + $b]
	    if {$total>400} {
		set darken [expr (400-$total)/3]
		set r [expr $r+$darken]
		set g [expr $g+$darken]
		set b [expr $b+$darken]
	    }

	    if {$r < 0 } { set r 0 }
	    if {$g < 0 } { set g 0 }
	    if {$b < 0 } { set b 0 }

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
	    tk_messageBox -type ok -title "[trans invalid_t]" -message "[trans invalid_m]" -icon error
	    return
	}
	if {[lsearch -exact $::colorize::config(colors) $color] >= 0} {
	    tk_messageBox -type ok -title "[trans dup_t]" -message "$color [trans dup_m]" -icon error
	    return
	}
	lappend ::colorize::config(colors) $color
	$from delete 0 end
    }

    proc build_config {w} {
	listbox $w.colors -listvariable ::colorize::config(colors)
	button $w.rem -text "[trans delete]" -command "::colorize::remove $w.colors"
	entry $w.newcolor -text "#RRGGBB"
	button $w.add -text "[trans add]" -command "::colorize::add $w.newcolor"
	pack $w.colors -fill x
	pack $w.rem -expand 1 -fill x
	pack $w.newcolor $w.add -side left -fill y
    }
}
