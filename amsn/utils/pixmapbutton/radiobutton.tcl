package require snit

snit::widgetadaptor pixmapradiobutton {

	typevariable widgetlist
	typevariable loadimagecommand
	
	typevariable normal
	typevariable hover
	typevariable disabled

	typevariable normalpress
	typevariable hoverpress
	typevariable disabledpress

	typevariable selected

	option -activeforeground -configuremethod SetActiveForeground
	option -activefg -configuremethod SetActiveForeground
	option -command
	option -font -configuremethod SetFont
	option -foreground -configuremethod SetForeground
	option -fg -configuremethod SetForeground
	option -indicatoron -default 1 -configuremethod SetIndicatorOn
	option -offvalue
	option -onvalue
	option -state -default normal -configuremethod SetState
	option -takefocus -default 1
	option -text -configuremethod SetText
	option -variable


	typeconstructor {
		$type SetImageCommand "$type loadimage"
		$type reloadimages 1
	}

	constructor { args } {
		lappend widgetlist $self

		installhull using canvas -bg white -relief flat -highlightthickness 0

		$hull create image 0 0 -image $normal -disabledimage $disabled -anchor nw -tag button
		$hull create text 0 0 -anchor w -tag label
		$hull coords label [image width $normal] [expr [image height $normal] / 2]

		$self configure -variable [lindex $args [expr [lsearch $args -variable] + 1]]
		set selected($options(-variable)) ""

		$self configurelist $args
		$self UpdateVariable 0
		
		$hull configure -width [expr [$self MeasureText $options(-text) w] + [image width $normal]]
		
		set ih [image height $normal]
		set th [$self MeasureText $options(-text) h]
		if { $ih > $th } {
			$hull configure -height $ih
		} else {
			$hull configure -height $th
		}
			
		bind $self <Enter> "$self ButtonHovered"
		bind $self <Leave> "$self ButtonUnhovered"
		bind $self <Button-1> "$self select"
		bind $self <KeyPress-space> "$self select"
		bind $self <KeyPress-plus> "$self select"
		bind $self <KeyPress-equal> "$self select"
	}

	#////////////////////////////////////////////////////////////////
	# PUBLIC COMMANDS						/
	# deselect							/
	# flash								/
	# invoke								/
	# select								/
	# toggle								/
	#////////////////////////////////////////////////////////////////
	method invoke { } {
		if { $options(-state) != "disabled" } {
			eval $options(-command)
		}
	}

	method flash { } {
		if { $options(-state) != "disabled" } {
			after 250 $self toggle
			after 500 $self toggle
			after 750 $self toggle
			after 1000 $self toggle
		}
	}

	method select { } {
		if { $selected($options(-variable)) != $self } {
			if { $selected($options(-variable)) != "" } {
				$selected($options(-variable)) deselect
			}
			set selected($options(-variable)) $self
		}
		if { $options(-state) != "disabled" } {
			if { $options(-variable) != "" } {
				$self UpdateVariable $options(-onvalue)
			}
			$hull itemconfigure button -image $normalpress -disabledimage $disabledpress
			$self invoke
		}
	}

	method deselect { } {
		if { $options(-state) != "disabled" } {
			if { $options(-variable) != "" } {
				$self UpdateVariable $options(-offvalue)
			}
			$hull itemconfigure button -image $normal -disabledimage $disabled
		}
	}

	#////////////////////////////////////////////////////////
	# PRIVATE COMMANDS					/
	#////////////////////////////////////////////////////////
	method ButtonHovered { } {
		if { $options(-state) != "disabled" } {
			$self configure -state active
		}
	}
	
	method ButtonUnhovered { } {
		if { $options(-state) != "disabled" } {
			$self configure -state normal
		}
	}
	
	method SetActiveForeground { option value } {
		set options(-activeforeground) $value
		set options(-activefg) $value
		$hull itemconfigure label -activefill $value
	}
	
	method SetForeground { option value } {
		set options(-foreground) $value
		set options(-fg) $value
		$hull itemconfigure label -fill $value
	}
		
	method SetFont { option value } {
		set options(-font) $value
		$hull itemconfigure label -font $value
	}
	
	method SetIndicatorOn { option value } {
		set options(-indicatoron) $value
		if { !$value } {
			$hull delete button
			$hull coords label 0 [expr [image height $normal] / 2]
		} else {
			switch $selected($options(-variable)) {
				$self {
					$hull create image 0 0 -image $normalpress -disabledimage $disabledpress -anchor nw -tag button
				}
				default {
					$hull create image 0 0 -image $normal -disabledimage $disabled -anchor nw -tag button
				}
			}
			$hull coords label [image width $normal] [expr [image height $normal] / 2]
			switch $options(-state) {
				disabled { $hull itemconfigure button -state disabled }
				default { $hull itemconfigure button -state normal }
			}
		}
	}
	
	method SetState { option value } {
		set options(-state) $value
		switch $value {
			normal {
				if { $selected($options(-variable)) == $self } {
					$hull itemconfigure button -image $normalpress
				} else {
					$hull itemconfigure button -image $normal
				}
			}
			active {
				if { $selected($options(-variable)) == $self } {
					$hull itemconfigure button -image $hoverpress
				} else {
					$hull itemconfigure button -image $hover
				}
			}
			disabled {
				$hull itemconfigure button -state disabled
			}
		}
		
	}
	
	method SetText { option value } {
		set options(-text) $value
		$hull itemconfigure label -text $value
	}

	method UpdateVariable { value } {
		uplevel #0 "set $options(-variable) $value"
	}

	method MeasureText { text dimension } {
		if { $dimension == "w" } {
			if { $options(-font) != "" } {
				set idx [expr [string first "\n" $text] - 1] 
				if { $idx < 0 } { set idx end }
				set m [font measure $options(-font) -displayof $self [string range $text \
					0 $idx]]
				return $m
			} else {
				set idx [expr [string first "\n" $text] - 1] 
				if { $idx < 0 } { set idx end }
				set f [font create -family helvetica -size 12 -weight normal]
				set m [font measure $f -displayof $self [string range $text \
					0 $idx]]
				font delete $f
				return $m
			}
		} elseif { $dimension == "h" } {
			if { $options(-font) != "" } {
				#Get number of lines
				set n [$self NumberLines $text]
				#Multiply font size by no. lines and add gap between lines * (no. lines - 1).
				return [expr $n * [font configure $options(-font) -size] + (($n - 1) * 7)]
			} else {
				#Get number of lines
				set n [$self NumberLines $text]
				#Multiply font size by no. lines and add gap between lines * (no. lines - 1).
				return [expr ($n * 12) + (($n - 1) * 7)]
			}
		}
	}

	method NumberLines { string } {
		for { set n 0; set idx 0 } { [string first "\n" $string $idx] != -1} { incr n 1 } {
					set idx [expr [string first "\n" $string $idx] +1]
				}
		if { $n < 1 } { set n 1 }
		return $n
	}


	#/////////////////////////////////////////////////////

	#/////////////////////////////////////////////////////
	# Image (re)loading methods
	# 
	# 
	# 
	#/////////////////////////////////////////////////////
	
	typemethod loadimage { imagename } {
		return [image create photo -file $imagename.gif]
	}
	
	typemethod SetImageCommand { command } {
		set loadimagecommand $command
	}
	
	typemethod reloadimages { init } {
		if { !$init } {
			image delete $normal
			image delete $hover
			image delete $disabled
			image delete $normalpress
			image delete $hoverpress
			image delete $disabledpress
		}
	
		set normal [eval "$loadimagecommand radio"]
		set hover [eval "$loadimagecommand radiohover"]
		set disabled [eval "$loadimagecommand radiodisabled"]

		set normalpress [eval "$loadimagecommand radiopress"]
		set hoverpress [eval "$loadimagecommand radiohoverpress"]
		set disabledpress [eval "$loadimagecommand radiodisabledpress"]

		if { !$init } {
			foreach widget $widgetlist {
				if { $selected([$widget cget -variable]) == $widget } {
					::hull1$widget itemconfigure button -image $normalpress -disabledimage $disabledpress
				} else {
					::hull1$widget itemconfigure button -image $normal -disabledimage $disabled
				}
			$widget configure -width [expr [$widget MeasureText [$widget cget -text] w] + [image width $normal]]
			set ih [image height $normal]
			set th [$self MeasureText $options(-text) h]
			if { $ih > $th } {
				$hull configure -height $ih
			} else {
				$hull configure -height $th
			}
			}
		}
	}
}