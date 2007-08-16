namespace eval ::chameleon::button {
  proc button_customParseConfArgs {w parsed_options args } {
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

    array set button_widgetOptions {
      -activebackground		-ignore
      -activeforeground		-ignore
      -anchor			-styleOption
      -background		-styleOption
      -bd			-styleOption
      -bg			-styleOption
      -bitmap			-ignore
      -border			-styleOption
      -borderwidth		-styleOption
      -command			-command
      -compound			-compound
      -cursor			-cursor
      -default			-default
      -disabledforeground	-ignore
      -fg			-styleOption
      -font			-styleOption
      -foreground		-styleOption
      -height			-ignore
      -highlightbackground	-ignore
      -highlightcolor		-styleOption
      -highlightthickness	-styleOption
      -image			-image
      -justify			-styleOption
      -overrelief		-ignore
      -padx			-toImplement
      -pady			-toImplement
      -relief			-styleOption
      -repeatdelay		-ignore
      -repeatinterval		-ignore
      -state			-state
      -takefocus		-takefocus
      -text			-text
      -textvariable		-textvariable
      -underline		-underline
      -width			-toImplement
      -wraplength		-styleOption
    }
    # ignoring -width because we need to map 0 to "" and "" to 0 in cget/configure
    
    array set button_widgetCommands { 
      flash	{1 {button_flash $w}}
      invoke	{1 {$w invoke}}
    }

    array set button_styleOptions {}
  }

  proc init_buttonStyleOptions { } {
  }

  proc button_customCget { w option } {
    set padding [$w cget -padding]

    if { [llength $padding] > 0 } {
      foreach {padx pady} $padding break
    }

    if { $option eq "-padx" && [info exists padx] } {
      return $padx
    }

    if { $option eq "-pady" && [info exists pady] } {
      return $pady
    }

    if {$option eq "-width"} {
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

    if {$i % 2} {
      $w state active
    } else {
      $w state !active
    }

    after 100 [list ::chameleon::button::button_flash_timer $w $old_state [expr {$i + 1}]]
  }
}
