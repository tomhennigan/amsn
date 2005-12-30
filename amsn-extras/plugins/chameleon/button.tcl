namespace eval ::chameleon::button {

   proc button_customParseConfArgs { parsed_options args } {
	variable button_styleOptions
     	array set options $args
	array set ttk_options $parsed_options

 	if { [info exists options(-bd)] } {
 	    set ttk_options(-padding) $options(-bd)
 	}
 	set padx 0
 	if { [info exists options(-padx)] &&
 	     [string is digit -strict $options(-padx)]  } {
 	    set padx $options(-padx)
 	}
 	set pady 0
 	if { [info exists options(-pady)] &&
 	     [string is digit -strict $options(-pady)] } {
 	    set pady $options(-pady)
 	}
 	if {$padx == 0 && $pady == 0 && 
 	    [info exists options(-bd)] } {
 	    set ttk_options(-padding) $options(-bd)
 	} else {
 	    if {$padx == 0 && $pady != 0 } {
 		set ttk_options(-padding) [list 2 $pady]
 	    } elseif {$padx != 0 && $pady == 0 } {
 		set ttk_options(-padding) [list $padx 2]
 	    } elseif {$padx != 0 && $pady != 0 } {
 		set ttk_options(-padding) [list $padx $pady]
 	    }
 	}

       if { [info exists options(-width)] } {
	   if {$options(-width) == 0} {
	       set ttk_options(-width) [list]
	   } else {
	       set ttk_options(-width) $options(-width)
	   }
       }

	return [array get ttk_options]
    }

    proc init_buttonCustomOptions { } {
 	variable button_widgetOptions
 	variable button_widgetCommands
 	variable button_styleOptions
 	variable button_widgetLayout

 	set button_widgetLayout "TButton"

 	array set button_widgetOptions {-activebackground -ignore
 	    -activeforeground -ignore
 	    -anchor -ignore
 	    -background -ignore
 	    -bitmap -ignore
	    -border  -ignore
 	    -bd -ignore
 	    -compound -compound
 	    -cursor -cursor
 	    -disabledforeground -ignore
 	    -font -ignore
 	    -foreground -ignore
 	    -fg -ignore
 	    -highlightbackground -ignore
 	    -image -image
 	    -overrelief -ignore
 	    -padx -ignore
 	    -pady -ignore
 	    -repeatdelay -ignore
 	    -repeatinterval -ignore
 	    -takefocus -takefocus
 	    -text -text
 	    -textvariable -textvariable
 	    -underline -underline
 	    -command -command
 	    -default -default
 	    -height -ignore
 	    -state -state
 	    -width -ignore}
	# ignoring -width because we need to map 0 to "" and "" to 0 in cget/configure
	
 	array set button_widgetCommands [list flash {1 {button_flash $w}} \
					     invoke {1 {$w invoke}}]

 	array set button_styleOptions {-background -background
 	    -bg -background
 	    -borderwidth -borderwidth
 	    -relief -relief
 	    -highlightcolor -focuscolor
 	    -highlightthickness -focusthickness
 	    -justify -justify
 	    -wraplength -wraplength}
    }

    proc init_buttonStyleOptions { } {

    }

    proc button_customCget { w option } {
	set padding [$w cget -padding]
	if { [llength $padding] > 0 } {
 	    set padx [lindex $padding 0]
 	    set pady [lindex $padding 1]
	}
	if { $option == "-padx" && [info exists padx] } {
	    return $padx
	}
	if { $option == "-pady" && [info exists pady] } {
	    return $pady
	}
	if {$option == "-width"} {
	    set width [$w cget -width]
	    if {![string is digit -strict $width]} {
		return 0
	    } else {
		return $width
	    }
	}

	return ""
    }



     proc button_flash {w} {
 	if { [lsearch [$w state] active] != -1 } {
 	    set old_state "active"
 	} else {
 	    set old_state "!active"
 	}
	
 	button_flash_timer $w $old_state 0	

     }
     proc button_flash_timer { w old_state i } {

 	if { $i >= $::chameleon::flash_count } {
 	    $w state $old_state
 	    return
 	}

 	if {[expr $i % 2] } {
 	    $w state active
 	} else {
 	    $w state !active
 	}
	
 	incr i
 	after 100 "::chameleon::button::button_flash_timer $w $old_state $i"
     }

}