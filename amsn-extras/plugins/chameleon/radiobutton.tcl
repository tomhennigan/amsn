namespace eval ::chameleon::radiobutton {
  proc radiobutton_customParseConfArgs {w parsed_options args } {
    array set options		$args
    array set ttk_options	$parsed_options

    if { [info exists options(-bd)] } {
      set ttk_options(-padding) $options(-bd)
    }

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

    if {$padx == 0 && $pady == 0 && [info exists options(-bd)] } {
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
    
    if { ![info exists options(-variable)] } {
      set options(-variable) "selectedButton"
    }

    set varname	$options(-variable)
    set value	""

    if { [info exists options(-value)] } {
      set value $options(-value)
    }

    if { [string range $varname 0 1] ne "::" } {
      set varname "::$varname"
    }

    if { ![info exists [set varname]] } {
      set [set varname] $value
    }

    set ttk_options(-variable) [set options(-variable)]

    return [array get ttk_options]
  }

  proc init_radiobuttonCustomOptions { } {
    variable radiobutton_widgetCommands 
    variable radiobutton_widgetOptions

    array set radiobutton_widgetOptions {
      -activebackground		-styleOption
      -activeforeground		-styleOption
      -anchor			-ignore
      -background		-styleOption
      -bd			-styleOption
      -bg			-styleOption
      -bitmap			-ignore
      -border			-styleOption
      -borderwidth		-styleOption
      -command			-command
      -compound			-compound
      -cursor			-cursor
      -disabledforeground	-styleOption
      -fg			-styleOption
      -font			-styleOption
      -foreground		-styleOption
      -height			-ignore
      -highlightbackground	-styleOption
      -highlightcolor		-styleOption
      -highlightthickness	-styleOption
      -image			-image
      -indicatoron		-ignore
      -justify			-ignore
      -offrelief		-styleOption
      -overrelief		-styleOption
      -padx			-toImplement
      -pady			-toImplement
      -relief			-styleOption
      -repeatdelay		-ignore
      -repeatinterval		-ignore
      -selectcolor		-styleOption
      -selectimage		-ignore
      -state			-state
      -takefocus		-takefocus
      -text			-text
      -textvariable		-textvariable
      -underline		-underline
      -value			-value
      -variable			-variable
      -width			-toImplement
      -wraplength		-ignore
    }
    # ignoring -width because we need to map 0 to "" and "" to 0 in cget/configure
    
    array set radiobutton_widgetCommands {
      deselect	{1 {radiobutton_deselect $w}}
      flash	{1 {radiobutton_flash $w}}
      invoke	{1 {$w invoke}}
      select	{1 {radiobutton_select $w}}
      toggle	{1 {radiobutton_toggle $w}}
    }
  }

  proc radiobutton_customCget { w option } {
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
      set width [$w cget -width]

      if {![string is digit -strict $width]} {
	return 0
      } else {
	return $width
      }
    }

    return ""
  }

  proc radiobutton_flash {w} {
    if { [lsearch [$w state] active] != -1 } {
      set old_state "active"
    } else {
      set old_state "!active"
    }
    
    radiobutton_flash_timer $w $old_state 0
  }
  
  proc radiobutton_flash_timer { w old_state i } {
    if { $i >= $::chameleon::flash_count } {
      $w state $old_state

      return
    }

    if {$i % 2} {
      $w state active
    } else {
      $w state !active
    }
    
      after 100 [list ::chameleon::radiobutton::radiobutton_flash_timer $w $old_state [expr {$i + 1}]]
  }

  proc radiobutton_select {w} {
    upvar \#0 [$w cget -variable] var

    set var [$w cget -onvalue]
  }

  proc radiobutton_deselect {w} {
    upvar \#0 [$w cget -variable] var

    set var [$w cget -offvalue]
  }

  proc radiobutton_toggle {w} {
    set on	[$w cget -onvalue]
    set off	[$w cget -offline]
    set var	[expr {$var == $on ? $off : $on}]
  }
}
