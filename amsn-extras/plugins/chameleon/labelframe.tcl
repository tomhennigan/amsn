namespace eval ::chameleon::labelframe {
  proc labelframe_customParseConfArgs {w parsed_options args } {
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

    if { [info exists options(-height)] } {
      if {$options(-height) == 0} {
	set ttk_options(-height) [list]
      } else {
	set ttk_options(-height) $options(-height)
      }
    }
    
    return [array get ttk_options]
  }

  proc init_labelframeCustomOptions { } {
    variable labelframe_widgetOptions
    
    array set labelframe_widgetOptions {
      -background		-styleOption
      -bd			-styleOption
      -bg			-styleOption
      -border			-styleOption
      -borderwidth		-styleOption
      -class			-class
      -colormap			-ignore
      -container		-ignore
      -cursor			-cursor
      -fg			-styleOption
      -font			-styleOption
      -foreground		-styleOption
      -height			-toImplement
      -highlightbackground	-ignore
      -highlightcolor		-ignore
      -highlightthickness	-ignore
      -labelanchor		-labelanchor 
      -labelwidget		-labelwidget 
      -padx			-toImplement
      -pady			-toImplement
      -relief			-styleOption
      -takefocus		-takefocus
      -text			-text
      -visual			-ignore
      -width			-toImplement
    }
  }

  proc labelframe_customCget { w option } {
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

    if {$option eq "-height"} {
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
