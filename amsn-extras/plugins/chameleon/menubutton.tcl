namespace eval ::chameleon::menubutton {
  proc menubutton_customParseConfArgs {w parsed_options args } {
    array set options		$args
    array set ttk_options	$parsed_options
    
    if { [info exists options(-padx)] && [string is digit -strict $options(-padx)]  } {
      set padx $options(-padx)
    } else {
      set padx 0
    }

    if { [info exists options(-pady)] && [string is digit -strict $options(-pady)] } {
      set pady $options(-pady)
    } else {
      set pady 0
    }
    
    if {$padx == 0 && $pady != 0 } {
      set ttk_options(-padding) [list 2 $pady]
    } elseif {$padx != 0 && $pady == 0 } {
      set ttk_options(-padding) [list $padx 2]
    } elseif {$padx != 0 && $pady != 0 } {
      set ttk_options(-padding) [list $padx $pady]
    }
    
    # 	if { [info exists options(-width)] } {
    # 			if {$options(-width) == 0} {
    # 				set ttk_options(-width) [list]
    # 			} else {
    # 				set ttk_options(-width) $options(-width)
    # 			}
    # 		}
    set ttk_options(-width) -1

    return [array get ttk_options]
  }
  
  proc init_menubuttonCustomOptions { } {
    variable menubutton_widgetCommands 
    variable menubutton_widgetOptions

    array set menubutton_widgetOptions {
      -activebackground		-ignore
      -activeforeground		-ignore
      -anchor			-ignore
      -background		-styleOption
      -bd			-styleOption
      -bg			-styleOption
      -bitmap			-ignore
      -borderwidth		-styleOption
      -compound			-compound
      -cursor			-cursor
      -direction		-direction
      -disabledforeground	-ignore
      -fg			-styleOption
      -font			-styleOption
      -foreground		-styleOption
      -height			-ignore
      -highlightbackground	-ignore
      -highlightcolor		-ignore
      -highlightthickness	-ignore
      -image			-image
      -indicatoron		-ignore
      -justify			-ignore
      -menu			-menu
      -padx			-ignore
      -pady			-ignore
      -relief			-styleOption
      -state			-state
      -takefocus		-takefocus
      -text			-text
      -textvariable		-textvariable
      -underline		-underline
      -width			-toImplement
      -wraplength		-ignore
    }
  }

  proc menubutton_customCget { w option } {
    set padding [$w cget -padding]

    if { [llength $padding] > 0 } {
      foreach {padx pady} $padding {break}
    }

    if { $option eq "-padx" && [info exists padx] } {
      return $padx
    }

    if { $option eq "-pady" && [info exists pady] } {
      return $pady
    }

    if {$option eq "-width"} {
      return 0

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
