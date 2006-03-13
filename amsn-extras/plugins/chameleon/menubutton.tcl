namespace eval ::chameleon::menubutton {

	proc menubutton_customParseConfArgs {w parsed_options args } {
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
		variable menubutton_widgetOptions
		variable menubutton_widgetCommands 

		array set menubutton_widgetOptions {
			-activebackground -ignore
			-activeforeground -ignore
			-anchor -ignore
			-background -styleOption
			-bd -styleOption
			-bg -styleOption
			-bitmap -ignore
			-borderwidth -styleOption
			-cursor -cursor
			-direction -direction
			-disabledforeground -ignore
			-fg -styleOption
			-font -styleOption
			-foreground -styleOption
			-height -ignore
			-highlightbackground -ignore
			-highlightcolor -ignore
			-highlightthickness -ignore
			-image -image
			-indicatoron -ignore
			-justify -ignore
			-menu -menu
			-padx -ignore
			-pady -ignore
			-relief -styleOption
			-compound -compound
			-state -state
			-takefocus -takefocus
			-text -text
			-textvariable -textvariable
			-underline -underline
			-width -toImplement
			-wraplength -ignore
		}

		
	}

	proc menubutton_customCget { w option } {
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
