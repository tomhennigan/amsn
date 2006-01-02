namespace eval ::chameleon::button {

   proc button_customParseConfArgs {w parsed_options args } {
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
       
       if {$padx == 0 && $pady != 0 } {
	   set ttk_options(-padding) [list 2 $pady]
       } elseif {$padx != 0 && $pady == 0 } {
	   set ttk_options(-padding) [list $padx 2]
       } elseif {$padx != 0 && $pady != 0 } {
	   set ttk_options(-padding) [list $padx $pady]
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

    proc init_buttonCustomOptions { } {
 	variable button_widgetOptions
 	variable button_widgetCommands
 	variable button_styleOptions


 	array set button_widgetOptions {
	    -activebackground -ignore
 	    -activeforeground -ignore
 	    -anchor -styleOption
 	    -background -styleOption
	    -bg  -styleOption
 	    -bitmap -ignore
	    -border  -styleOption
 	    -bd -styleOption
	    -borderwidth -styleOption
 	    -compound -compound
 	    -cursor -cursor
 	    -disabledforeground -ignore
 	    -font -styleOption
 	    -foreground -styleOption
 	    -fg -styleOption
 	    -highlightbackground -ignore
 	    -image -image
 	    -overrelief -ignore
 	    -padx -toImplement
 	    -pady -toImplement
 	    -repeatdelay -ignore
 	    -repeatinterval -ignore
 	    -takefocus -takefocus
 	    -text -text
 	    -textvariable -textvariable
 	    -underline -underline
 	    -command -command
 	    -default -default
 	    -height -toImplement
 	    -state -state
 	    -width -toImplement
	    -relief  -styleOption
 	    -highlightcolor -styleOption
 	    -highlightthickness  -styleOption
 	    -justify -styleOption
 	    -wraplength -styleOption
	}
	# ignoring -width because we need to map 0 to "" and "" to 0 in cget/configure
	
 	array set button_widgetCommands { 
	    flash {1 {button_flash $w}}
	    invoke {1 {$w invoke}}}

 	array set button_styleOptions {}
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