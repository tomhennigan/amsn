namespace eval ::chameleon::frame {
    proc frame_customParseConfArgs {w parsed_options args } {
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
	if { [info exists options(-height)] } {
	   if {$options(-height) == 0} {
	       set ttk_options(-height) [list]
	   } else {
	       set ttk_options(-height) $options(-height)
	   }
	}
	
	return [array get ttk_options]
    }

    proc init_frameCustomOptions { } {
	variable frame_widgetOptions
	
 	array set frame_widgetOptions {
	    -bd -borderwidth
 	    -borderwidth -borderwidth
	    -border  -borderwidth
 	    -class -class
 	    -relief -styleOption
 	    -background -styleOption
 	    -bg -styleOption
 	    -colormap  -ignore
 	    -container -ignore
 	    -cursor -cursor
 	    -height -toImplement
	    -highlightbackground -styleOption
	    -highlightcolor -styleOption
	    -highlightthickness -styleOption
 	    -padx -toImplement
 	    -pady -toImplement
 	    -takefocus -takefocus
 	    -visual -ignore
 	    -width -toImplement
	}
    }

    proc frame_customCget { w option } {
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

	if {$option == "-height"} {
	    set height [$w cget -height]
	    if {![string is digit -strict $height]} {
		return 0
	    } else {
		return $height
	    }
	}


	return ""

    }
}