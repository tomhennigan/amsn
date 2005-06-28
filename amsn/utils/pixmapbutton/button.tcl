package require snit
package require scalable-bg
package provide pixmapbutton 0.8

snit::widget pixmapbutton {

	typevariable widgetlist
	typevariable loadimagecommand

	typevariable normal
	typevariable hover
	typevariable pressed
	typevariable disabled
	typevariable focus

	variable afterid
	variable potent

	option -activeforeground
	option -background -configuremethod SetBackground -default #fff
	option -bg -configuremethod SetBackground
	option -command
	option -default -configuremethod SetDefault
	option -drawbg
	option -drawbgonhover
	option -foreground -configuremethod SetForeground
	option -fg -configuremethod SetForeground
	option -repeatdelay
	option -repeatinterval
	option -state -configuremethod SetState
	option -text -configuremethod SetText -cgetmethod GetText

	#Let Tk's button handle all options except these:
	delegate option * to button except {
						-image
						-highlightthickness
						-borderwidth
						-bd -relief
						-bg
						-padx
						-pady
					}

	typeconstructor {
		set widgetlist ""
		$type SetImageCommand "$type loadimage"
		$type reloadimages 1
	}

	constructor { args } {
		#Create scalable backgrounds for the button:
		scalable-bg $self.normal -source $normal -n 6 -e 6 -s 6 -w 6 -width 1 -height 1 -resizemethod scale
		scalable-bg $self.hover -source $hover -n 6 -e 6 -s 6 -w 6 -width 1 -height 1 -resizemethod scale
		scalable-bg $self.pressed -source $pressed -n 6 -e 6 -s 6 -w 6 -width 1 -height 1 -resizemethod scale
		scalable-bg $self.disabled -source $disabled -n 6 -e 6 -s 6 -w 6 -width 1 -height 1 -resizemethod scale
		scalable-bg $self.focus -source $focus -n 6 -e 6 -s 6 -w 6 -width 1 -height 1 -resizemethod scale

		#Record the button's name in the list of good, law abiding buttons:
		lappend widgetlist $self

		#Create the 'button' component, using a label (no movement on click)
		install button using label $self.l -image [$self.normal name] \
			-highlightthickness 0 \
			-borderwidth 0 \
			-relief sunken \
			-compound center -padx 0 -pady 0

		#Parse and apply arguments
		$self configurelist $args

		#Button is not potent yet:
		set potent 0

		#Pack 'button' component
		pack $self.l
		
		# Bindings:
		# <Configure> binding is used to check when text/packing resizes the widget, and calls the Resize method to update the size of the scalable backgrounds. 
		bind $self <Configure> "$self Resize %w %h"
		bind $self.l <Enter> "$self ButtonHovered"
		bind $self.l <Leave> "$self ButtonUnhovered"
		bind $self.l <Button-1> "$self ButtonPressed"
		bind $self.l <ButtonRelease-1> "$self ButtonReleased"
		bind $self.l <Button-2> "focus $self.l"
		bind $self.l <Button-3> "focus $self.l"
		bind $self.l <FocusIn> "$self DrawFocus"
		bind $self.l <FocusOut> "$self RemoveFocus"
		bind $self.l <Return> "$self invoke"
		#Not sure how this should be properly implemented yet...
		#bind $self <KeyPress-space> "$self invoke"
	}

	method invoke { } {
		if { $options(-state) != "disabled" } {
			eval $options(-command)
		}
	}

	method CancelRepeat { } {
		after cancel $afterid
	}

	method RepeatInvoke { repeat } {
		eval $options(-command)

		if { $repeat == "initial" } {
			set afterid [after $options(-repeatdelay) $self RepeatInvoke again]
		} elseif { $repeat == "again" } {
			set afterid [after $options(-repeatinterval) $self RepeatInvoke again]
		}
	}

	method DrawFocus { } {
		if { $options(-state) != "disabled" } {
			[$self.normal name] copy [$self.focus name] -to 0 0
			[$self.hover name] copy [$self.focus name] -to 0 0
			[$self.pressed name] copy [$self.focus name] -to 0 0
			#$self ReassociateImages
			#$self.l configure -image [$self.normal name]
		}
	}

	method RemoveFocus { } {
		$type reloadimages 0
	}

	method ButtonHovered { } {
		if { $options(-state) == "disabled" } {
			return
		}

		if { $options(-activeforeground) != "" } {
			$self.l configure -foreground $options(-activeforeground)
		}

		if { $potent == "maybe" } {
			set potent "yes"
			$self.l configure -image [$self.pressed name]
		} else { 
			$self.l configure -image [$self.hover name]
		}
	}

	method ButtonUnhovered { } {
		if { $options(-state) == "disabled" } {
			return
		}

		if { $options(-activeforeground) != "" } {
			$self.l configure -foreground $options(-foreground)
		}

		if { $potent == "yes" } {
			set potent "maybe"
		} else {
			set potent "no"
		}
		$self.l configure -image [$self.normal name]
	}

	method ButtonPressed { } {
		if { $options(-state) == "disabled" } {
			return
		}
		set potent "yes"
		$self.l configure -image [$self.pressed name]
		if { $options(-repeatdelay) != "" && $options(-repeatinterval) != "" } {
			set afterid [after $options(-repeatdelay) $self RepeatInvoke again]
		}
	}

	method ButtonReleased { } {
		if { $options(-state) == "disabled" } {
			return
		}

		if { $options(-repeatdelay) != "" && $options(-repeatinterval) != "" } {
			$self CancelRepeat
		}

		if { $potent == "yes" } {
			$self.l configure -image [$self.hover name]
			set potent "no"
			if { $options(-repeatdelay) == "" && $options(-repeatinterval) == "" } {
				$self invoke
			}
		} else {
			set potent "no"
			$self.l configure -image [$self.normal name]
		}
	}

	method SetBackground { option value } {
		set options(-background) $value
		set options(-bg) $value
		$self.l configure -bg $value
		$self.l configure -activebackground $value
		$self.l configure -highlightbackground $value
		$self.l configure -highlightcolor $value
	}

	method SetDefault { option value } {
		set options(-default) $value
		switch $value {
			"normal" { $self SetState -state normal }
			"active" { focus $self }
			"disabled" { $self SetState -state disabled }
		}
	}

	method SetForeground { option value } {
		set options(-foreground) $value
		set options(-fg) $value
		$self.l configure -foreground $value
	}

	method SetState { option value } {
		set options(-state) $value
		switch $value {
			normal { $self.l configure -image [$self.normal name] }
			active { $self.l configure -image [$self.hover name] }
			disabled { $self.l configure -image [$self.disabled name] }
		}
		$self.l configure -state $value
	}

	method GetText { option } {
		return [string range $options(-text) 2 end-2]
	}

	method SetText { option value } {
		set value "  $value  "
		set options(-text) $value
		$self.l configure -text $value
	}

	#/////////////////////////////////////////////////
	# Resize method.
	# Makes sure the button isn't too small, then
	# configures the scalable backgrounds' widths and heights
	#/////////////////////////////////////////////////
	method Resize { w h } {
		set iw [image width $normal]
		set ih [image height $normal]
		if { $w < $iw } {
			set w $iw
			unset iw
		}
		if { $h < $ih } {
			set h $ih
			unset ih
		}

		$self.normal configure -width $w -height $h
		$self.hover configure -width $w -height $h
		$self.pressed configure -width $w -height $h
		$self.disabled configure -width $w -height $h
		$self.focus configure -width $w -height $h
	}

	#//////////////////////////////////////////////////
	# ReassociateImages method.
	# Links the loaded background images with the 
	# scalable-bg image objects. Called by reloadimages.
	#//////////////////////////////////////////////////
	method ReassociateImages { } {
		$self.normal configure -source $normal
		$self.hover configure -source $hover
		$self.pressed configure -source $pressed
		$self.disabled configure -source $disabled
		$self.focus configure -source $focus
	}

	#//////////////////////////////////////////////////
	# Reloading images methods
	#/////////////////////////////////////////////////
	typemethod loadimage { imagename } {
		return [image create photo -file $imagename.gif]
	}

	typemethod SetImageCommand { command } {
		set loadimagecommand $command
	}

	typemethod reloadimages { init } {
		set normal [eval "$loadimagecommand button"]
		set hover [eval "$loadimagecommand button_hover"]
		set pressed [eval "$loadimagecommand button_pressed"]
		set disabled [eval "$loadimagecommand button_disabled"]
		set focus [eval "$loadimagecommand button_focus"]

		foreach widget $widgetlist {
			#$widget Resize
			$widget ReassociateImages
		}             
	}
}

#rename button ::tk::button
#rename pixmapbutton button