namespace eval ::chameleon::label {
    proc label_customParseConfArgs {parsed_options args } {
	array set options $args
	array set ttk_options $parsed_options
	
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

    proc init_labelCustomOptions { } {
	variable label_widgetOptions
	
 	array set label_widgetOptions {
	    -activebackground -ignore
	    -activeforeground -ignore
	    -anchor -anchor
	    -background -background
	    -bd  -styleOption
	    -bg -background
	    -bitmap -ignore
	    -border  -styleOption
	    -borderwidth  -styleOption
	    -class -class
	    -compound  -compound
	    -cursor  -cursor
	    -disabledforeground -ignore
	    -fg  -foreground
	    -font -font
	    -foreground -foreground
	    -height -ignore
	    -highlightbackground -ignore
	    -highlightcolor  -ignore
	    -highlightthickness -ignore
	    -image  -image
	    -justify -justify
	    -padx  -toImplement
	    -pady  -toImplement
	    -relief -relief
	    -state  -state
	    -takefocus -takefocus
	    -text  -text
	    -textvariable -textvariable
	    -underline  -underline
	    -width  -toImplement
	    -wraplength -wraplength
	}    
	
    }

	    
    proc label_customCget { w option } {
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

}