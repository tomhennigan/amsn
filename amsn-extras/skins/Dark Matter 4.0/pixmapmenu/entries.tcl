# TODO: make -underline actually work.

snit::type command {
	option -id
	option -parent

	option -accelerator
	option -underline -default -1

	option -command
	option -fg
	option -foreground
	option -image -configuremethod SetImage
	option -label -configuremethod SetLabel
	option -state -configuremethod SetState -default normal

	method type { } {
		return "command"
	}

	method SetImage { option value } {
		set options(-image) $value
		$options(-parent) EntryConfigureImage $options(-id) $value
	}

	method SetLabel { option value } {
		set options(-label) $value
		$options(-parent) EntryConfigureLabel $options(-id) $value
	}

	method SetState { option value } {
		set options(-state) $value
		$options(-parent) EntryConfigureState $options(-id) $value
	}
}

snit::type cascade {
	option -id
	option -parent

	option -underline -default -1

	option -command
	option -fg
	option -foreground
	option -image -configuremethod SetImage
	option -label -configuremethod SetLabel
	option -menu
	option -state -configuremethod SetState -default normal

	method type { } {
		return "cascade"
	}

	method SetImage { option value } {
		set options(-image) $value
		$options(-parent) EntryConfigureImage $options(-id) $value
	}

	method SetLabel { option value } {
		set options(-label) $value
		$options(-parent) EntryConfigureLabel $options(-id) $value
	}

	method SetState { option value } {
		set options(-state) $value
		$options(-parent) EntryConfigureState $options(-id) $value
	}
}

snit::type menu_checkbutton {
	option -id
	option -parent

	option -accelerator
	option -underline -default -1

	option -canvas
	option -command
	option -fg
	option -foreground
	option -indicatoron -configuremethod SetIndicator -default 1
	option -offvalue -default 0
	option -onvalue -default 1
	option -padx -default 0
	option -pady -default 0
	option -state -configuremethod SetState -default normal
	option -label -configuremethod SetLabel
	option -variable -configuremethod SetVar

	variable selected

	constructor { args } {
		# Initial values
		set selected no

		$self configurelist $args

		# Update the button according to the value of it's variable
		$self UpdateButton
	}

	destructor {
		#  Remove the trace on the old variable
		catch {
			if { ![string e $options(-variable) ""] } {
				uplevel #0 [list trace remove variable $options(-variable) write "$self UpdateButton"]
			}
		}
	}

	method type { } {
		return "checkbutton"
	}
	# o-----------------------------------------------------+
	#  Methods to change the state of the widget            |
	# o-----------------------------------------------------+
	method toggle { } {
		if { $options(-state) != "disabled" } {
			switch $selected {
				no {
					$self select
				}
				yes {
					$self deselect
				}
			}
		}
	}

	method invoke { } {
		if { $options(-state) != "disabled" } {
			eval $options(-command)
		}
	}

	method select { } {
		set selected yes
		if { $options(-state) != "disabled" } {
			if { $options(-variable) != "" } {
				$self UpdateVariable $options(-onvalue)
			}
			$self invoke
		}
		# May have been caused by a set $var, so we can safely put this outside the above if statement
		$options(-parent) EntrySelectCheck $options(-id)
	}

	method deselect { } {
		set selected no
		if { $options(-state) != "disabled" } {
			if { $options(-variable) != "" } {
				$self UpdateVariable $options(-offvalue)
			}
		}
		# May have been caused by a set $var, so we can safely put this outside the above if statement
		$options(-parent) EntryDeselectCheck $options(-id)
	}

	# Method to change the -state option
	method SetState { option value } {
		set options(-state) $value
		$options(-parent) EntryConfigureState $options(-id) $value
	}
	# o-----------------------------------------------------+
	#  Methods to change the value of the widget's options  |
	# o-----------------------------------------------------+
	method SetIndicator { option value } {
		set options(-indicatoron) $value
		$options(-parent) EntryConfigureIndicator $options(-id) $value
	}

	method SetLabel { option value } {
		set options(-label) $value
		$options(-parent) EntryConfigureLabel $options(-id) $value
	}

	method SetVar { opt val } {
		#  Remove the trace on the old variable
		if { ![string e $options(-variable) ""] } {
			uplevel #0 [list trace remove variable $options(-variable) write "$self UpdateButton"]
		}
		#  Set the trace on the new variable and update the widget's state
		set options(-variable) $val
		uplevel #0 [list trace add variable $options(-variable) write "$self UpdateButton"]
		$self UpdateButton
	}

	# o---------------------------------------------------------------+
	#  Methods to update the widget's state and the variable's value  |
	# o---------------------------------------------------------------+
	method UpdateButton { args } {
		set var [$self getvar]
		if { $var == $options(-onvalue) } {
			$self select
		} else {
			$self deselect
		}
	}

	method UpdateVariable { value } {
		if { ![string e $options(-variable) ""] } {
			uplevel #0 "set $options(-variable) $value"
		}
	}

	method getvar { } {
		upvar #0 $options(-variable) var
		if { ![info exists var] } {
			return 0
		} else {
			return $var
		}
	}
}

snit::type menu_radiobutton {
	typevariable selected

	option -id
	option -parent

	option -accelerator	
	option -underline -default -1

	option -canvas
	option -command
	option -fg
	option -foreground
	option -indicatoron -configuremethod SetIndicator -default 1 
	option -padx -default 0
	option -pady -default 2
	option -state -configuremethod SetState -default normal
	option -label -configuremethod SetLabel
	option -value -default 1 -configuremethod SetValue
	option -variable -configuremethod SetVar

	destructor {
		# If this radiobutton is the selected one for its variable, blank $selected($options(-variable)),
		# so that if another radiobutton is later selected it doesn't try to deselect this (now dead) one
		catch {
			if { $selected($options(-variable)) == $self } {
				set selected($options(-variable)) {}
			}
		}
		# Remove the trace from the radiobutton's variable
		catch {
			if { $options(-variable) != "" } {
				uplevel #0 [list trace remove variable $options(-variable) write "$self UpdateButton"]
			}
		}
	}

	method type { } {
		return "radiobutton"
	}

	method invoke { } {
		if { $options(-state) != "disabled" } {
			eval $options(-command)
		}
	}

	method select { } {
		if { $options(-state) != "disabled" && $options(-variable) != "" } {
			# Deselect the previously selected radiobutton
			if { [info exists selected($options(-variable))] } {
				if { $selected($options(-variable)) != "" && [$selected($options(-variable)) cget -value] != $options(-value) } {
					$selected($options(-variable)) deselect
				}
			}
			set selected($options(-variable)) $self
			if { $options(-variable) != "" } {
				$self UpdateVariable $options(-value)
			}
		}
		# May have been caused by a set $var, so we can safely put this outside the above if statement
		$options(-parent) EntrySelectRadio $options(-id)
	}

	method deselect { } {
		$options(-parent) EntryDeselectRadio $options(-id)
	}

	# o-----------------------------------------------------+
	#  Methods to change the value of the widget's options  |
	# o-----------------------------------------------------+
	method SetIndicator { option value } {
		set options(-indicatoron) $value
		$options(-parent) EntryConfigureIndicator $options(-id) $value
	}

	method SetLabel { option value } {
		set options(-label) $value
		$options(-parent) EntryConfigureLabel $options(-id) $value
	}

	method SetVar { opt val } {
		#  Remove the trace on the old variable
		if { $options(-variable) != "" } {
			uplevel #0 [list trace remove variable $options(-variable) write "$self UpdateButton"]
		}
		#  Set the trace on the new variable and update the widget's state
		set options(-variable) $val
		if { ![info exists selected($val)] } {
			array set selected [list $val ""]
		}

		uplevel #0 [list trace add variable $options(-variable) write "$self UpdateButton"]
		$self UpdateButton
	}

	method SetValue { option value } {
		set options(-value) $value
		$self UpdateButton
	}

	method SetState { option value } {
		set options(-state) $value
		$options(-parent) EntryConfigureState $options(-id) $value
	}

	# o---------------------------------------------------------------+
	#  Methods to update the widget's state and the variable's value  |
	# o---------------------------------------------------------------+
	method UpdateButton { args } {
		set val [$self getvar]
		if { $val == $options(-value) } {
			$self select
			$options(-parent) EntrySelectRadio $options(-id)
		} else {
			$self deselect
		}
	}

	method UpdateVariable { value } {
		if { $options(-variable) != "" } {
			uplevel #0 "set $options(-variable) $value"
		}
	}

	method getvar { } {
		upvar #0 $options(-variable) var
		if { ![info exists var] } {
			return 0
		} else {
			return $var
		}
	}
}

snit::type separator {
	option -id
	option -parent

	option -state

	method type { } {
		return "separator"
	}
}