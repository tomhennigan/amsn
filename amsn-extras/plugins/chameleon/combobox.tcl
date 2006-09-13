namespace eval ::chameleon::combobox {

	proc combobox_customParseConfArgs {w parsed_options args } {
		variable combobox_commands
		variable combobox_commandstates
		variable combobox_editable
		variable combobox_state

		array set options $args
		array set ttk_options $parsed_options
		
		if { [info exists options(-editable)] } {
			set combobox_editable($w) $options(-editable)
		}
		if { [info exists options(-state)] } {
			set combobox_state($w) $options(-state)
		}

		if { [info exists combobox_editable($w)] } {
			if { [info exists combobox_state($w)] } {
				if {[set combobox_editable($w)]} {
					set ttk_options(-state) [set combobox_state($w)]
				} else {
					if { [set combobox_state($w)] == "normal" } {
						set ttk_options(-state) readonly
					} else {
						set ttk_options(-state) disabled
					}
				}
			} else {
				if {![set combobox_editable($w)]} {
					set ttk_options(-state) readonly
				}
			}
		}
		

		if { [info exists options(-state)] } {
			if {[set options(-state)] == "disabled"} {
				set ttk_options(-state) "disabled"
			} else {
				if { ([info exists options(-editable)] && !$options(-editable)) || 
				     (![catch {$w cget -state} res] && $res == "readonly") } {
					set ttk_options(-state) "readonly"
				} else {
					set ttk_options(-state) "normal"	
				}
			}
		}

		if { [info exists options(-command)] } {
			set combobox_commands($w) $options(-command)
		}
		if { [info exists options(-commandstate)] } {
			if {$options(-commandstate) != "normal" && $options(-commandstate) != "disabled"} {
				set message "bad state value \"$options(-commandstate)\";"
				append message " must be normal or disabled"
				error $message
			}
			set combobox_commandstates($w) $options(-commandstate)
		}
		
		if { [info exists options(-value)] } {
			catch { $w set $options(-value)}
		}
		
		return [array get ttk_options]
	}
	
	proc init_comboboxCustomOptions { } {
		variable combobox_widgetOptions
		variable combobox_widgetCommands 

		array set combobox_widgetOptions {
			-background -styleOption
			-bd -borderwidth
			-bg -styleOption
			-borderwidth -styleOption
			-buttonbackground -styleOption
			-command -toImplement
			-commandstate -toImplement
			-cursor -cursor
			-disabledbackground -ignore
			-disabledforeground -ignore
			-dropdownwidth -ignore
			-editable -toImplement
			-elementborderwidth -ignore
			-exportselection -exportselection
			-fg -styleOption
			-font -styleOption
			-foreground -styleOption
			-height -ignore
			-highlightbackground -ignore
			-highlightcolor -ignore
			-highlightthickness -ignore
			-image -ignore
			-listvar -values
			-maxheight -ignore
			-opencommand -postcommand
			-postcommand -postcommand
			-relief -styleOption
			-selectbackground -ignore
			-selectborderwidth -ignore
			-selectforeground -ignore
			-state -toImplement
			-takefocus -takefocus
			-textvariable -textvariable
			-value -value
			-values -values
			-width -width
			-xscrollcommand -ignore
		}

		
		array set combobox_widgetCommands {
			bbox {1 {$w bbox}}
			close {2 {combobox_close $w}}
			curselection {4 {combobox_curselection $w}}
			current {4 {$w current}}
			delete {1 {$w delete}}
			get {1 {$w get}}
			icursor {2 {$w icursor}}
			identify {2 {$w identify}}
			index {3 {$w index}}
			insert {3 {$w insert}}
			list {1 {combobox_list $w}}
			open {1 {combobox_open $w}}
			scan {2 {combobox_scan $w}}
			set {3 {$w set}}
			select {5 {combobox_select $w}}
			selection {6 {$w selection}}
			subwidget {2 {combobox_subwidget $w}}
			toggle {1 {combobox_toggle $w}}
			xview {1 {$w xview}}
		}

		::chameleon::addBinding <<WidgetCreated>> {::chameleon::combobox::combobox_widgetCreated}
		::chameleon::addBinding <<WidgetDestroyed>> {::chameleon::combobox::combobox_widgetDestroyed}
		
	}

	proc combobox_customCget { w option } {
		variable combobox_commands
		variable combobox_commandstates
		variable combobox_editable
		variable combobox_state


		if { $option == "-editable" } {
			if { [info exists combobox_editable($w)] } {
				return [set combobox_editable($w)]
			} else {
				return 1
			}
		}
		if { $option == "-state" } {
			if { [info exists combobox_state($w)] } {
				return [set combobox_state($w)]
			} else {
				return "normal"
			}	
		}

		if { $option == "-command" } {
			if { [info exists combobox_commands($w)] } {
				return [set combobox_commands($w)]
			}
		}
		if { $option == "-commandstate" } {
			if { [info exists combobox_commandstates($w)] } {
				return [set combobox_commandstates($w)]
			}
		}
		
		if { $option == "-value" } {
			return [$w get]
		}
		
		return ""
	}


	proc combobox_widgetCreated { } {
		set cb [::chameleon::getLastCreatedWidget]
		if {[string first "::chameleon::combobox::combobox" $cb] == 0 } {
			#puts "combobx $cb is created"
			bind $cb <<ComboboxSelected>> "::chameleon::combobox::combobox_selected $cb"
			bind [::chameleon::getWidgetPath $cb] <<ComboboxSelected>> "::chameleon::combobox::combobox_selected $cb"
		}
	}

	proc combobox_selected {w args } {
		variable combobox_commands
		variable combobox_commandstates
	    if { [info exists combobox_commands($w)] && [set combobox_commands($w)] != ""} {
			if {![info exists combobox_commandstates($w)] || 
			    ([info exists combobox_commandstates($w)] && [set combobox_commandstates($w)] == "normal")} {
			    eval [set combobox_commands($w)] [list [::chameleon::getWidgetPath $w]] [list [$w get]]
			}
		}
	}
	
	proc combobox_widgetDestroyed { } {
		variable combobox_commands
		variable combobox_commandstates
		
		set cb [::chameleon::getLastDestroyedWidget]
		if {[string first "::chameleon::combobox::combobox" $cb] == 0 } {
			#puts "Combobox $cb is destroyed"
			array unset combobox_commands [::chameleon::getWidgetPath $cb]
			array unset combobox_commandstates [::chameleon::getWidgetPath $cb]
		}
	}

	proc combobox_select {w args} {
		if {[llength $args] == 1 } {
			$w current $args		 
		} else {
			error "Usage [::chameleon::getWidgetPath $w] select index"
		}
	}

	proc combobox_curselection {w} {
		set ret [$w current]
		if {$ret == -1} {
			return ""
		} else {
			return $ret
		}
	}

	proc combobox_list {w command args} {
		set values [$w cget -values]
		switch -- $command {
			delete {
				if {[llength $args] == 1} {
					set first [lindex $args 0]
					set last $first
				} else {
					set first [lindex $args 0]
					set last [lindex $args 1]
				}
				set values [lreplace $values $first $last]
				$w configure -values $values
			} 
			get {
				if {[llength $args] == 1} {
					return [eval lindex [list $values] $args]
				} else {
					return [eval lrange [list $values] $args]
				}
			}
			index {
			    return [eval [list $w] index $args]
			}
			insert {
				if {[llength $args] < 1} {
					error "Usage : [::chameleon::getWidgetPath $w] list insert index ?element element ... ?"
				} elseif {[llength $args] >= 2} {
					set values [eval linsert [list $values] $args]
					$w configure -values $values
				}
			}
			size {
				return [llength $values]
			}
			
		}
		
	}
	
	proc combobox_open {w} {
		# TODO implement in some way...
	}
	
	proc combobox_close {w} {
		# TODO implement in some way...
	}

	proc combobox_toggle {w} {
		# TODO not quite right..
		if {[winfo ismapped $w]} {
			return [combobox_close $w]
		} else {
			return [combobox_open $w]
		}
		
	}

	proc combobox_subwidget {w args} {
		return ""
	}

	proc combobox_scan {w args} {
		# TODO to implement in the same way as 'entry'.. although probably not necessary..
	}
	

}
