# STANDARD OPTIONS
#	-anchor *
#	-background *
#	-cursor *
#	-font *
#	-foreground *
#	-justify
#	-padx *
#	-pady *
#	-repeatdelay *
#	-repeatinterval *
#	-takefocus *
#	-text *
#	-textvariable
#	-underline
#	-wraplength
# WIDGET-SPECIFIC OPTIONS
#	-command *
#	-default
#	-emblem
#	-emblemanchor
#	-height *
#	-state
#	-width *


package require snit
package require scalable-bg
package provide pixmapbutton 0.1

snit::widgetadaptor button {

	variable potent
	variable focused
	variable Priv
	
	variable bdn
	variable bde
	variable bds
	variable bdw
	
	variable buttonwidth
	variable buttonheight
	
	typevariable normal
	typevariable hover
	typevariable pressed
	typevariable disabled
	typevariable focus
######### UNUSED OPTIONS ###################
	option -bd
	option -bg
	option -compound
	option -relief
	option -highlightthickness
	option -highlightbackground
	option -highlightcolor
	option -activebackground
	option -activebg
	option -activeforeground
	option -activefg
	option -disabledforeground
	option -activeborderwidth
	option -bitmap
	option -borderwidth
	option -image
	option -overrelief
############################################	

	option -anchor -default "c" -configuremethod setAnchor -cgetmethod getAnchor
	option -background -configuremethod setOption -cgetmethod getOption
	option -cursor -configuremethod setOption -cgetmethod getOption
	option -font -configuremethod setFont -cgetmethod getFont
	option -foreground -configuremethod setForeground -cgetmethod getForeground
	option -justify -default "left"
	option -padx -default "20"
	option -pady -default "10"
	option -repeatdelay
	option -repeatinterval
	option -state -default normal -configuremethod setState
	option -takefocus -default 1 -configuremethod setOption -cgetmethod getOption
	option -text -configuremethod setText -cgetmethod getText
	option -textvariable
	option -underline -default 0 -configuremethod setUnderline
	option -wraplength

	option -command
	option -default -default "normal"
	option -emblem
	option -emblemanchor -default "e" -configuremethod setEmblemAnchor
	option -height -configuremethod NewSize -cgetmethod getOption
	option -state -default "normal"
	option -width -configuremethod NewSize -cgetmethod getOption

	
	typeconstructor {
		$type reloadimages
	}

	constructor { args } {
		installhull using canvas -relief solid -highlightthickness 0 -width 80 -height 30
		set potent "no"
		set buttonwidth 0
		set buttonheight 0

		set bdn 6
		set bde 6
		set bds 6
		set bdw 6

		set fbdn 6
		set fbde 6
		set fbds 6
		set fbdw 6

		scalable-bg $self.normal -source $normal -n $bdn -e $bde -s $bds -w $bdw \
			-width 1 -height 1 -resizemethod tile
		scalable-bg $self.hover -source $hover -n $bdn -e $bde -s $bds -w $bdw \
			-width 1 -height 1 -resizemethod tile
		scalable-bg $self.pressed -source $pressed -n $bdn -e $bde -s $bds -w $bdw \
			-width 1 -height 1 -resizemethod tile
		scalable-bg $self.disabled -source $disabled -n $bdn -e $bde -s $bds -w $bdw \
			-width 1 -height 1 -resizemethod tile
		scalable-bg $self.focus -source $focus -n $fbdn -e $fbde -s $fbds -w $fbdw \
			-width 1 -height 1 -resizemethod tile

		$hull create image 0 0 -anchor nw -image [$self.normal name] -tag button
		$hull create text 0 0 -anchor c -text $options(-text) -tag txt
		
		$self configurelist $args
		if { $options(-emblem) != "" } {
			$hull create image 0 0 -anchor $options(-emblemanchor) -image $options(-emblem) -tag emblem
		}
		
		bind $self <Configure> "$self DrawButton %w %h"
		bind $self <Enter> "$self ButtonHovered"
		bind $self <Leave> "$self ButtonUnhovered"
		bind $self <Button-1> "$self ButtonPressed"
		bind $self <ButtonRelease-1> "$self ButtonReleased"
		bind $self <FocusIn> "$self DrawFocus"
		bind $self <FocusOut> "$self RemoveFocus"
		bind $self <Return> "$self invoke"
		bind $self <KeyPress-space> "$self invoke"

		$self SetSize
	}

	#---------------------------------------------------------------------------------------
	# Private methods
	# ~~~~~~~~~~~~~~~~~~~
	# NewSize: called when the widget gets resized. Resizes the button's images to
	#          width w and height h, and places text and emblem in correct places.
	#
	# ButtonHovered: called when the mouse enters the widget. If the button is pressed,
	#                 changes the button's image to pressed, else to hovered.
	#
	# ButtonUnhovered: called when the mouse leaves the widget. Changes the button's
	#                   image to normal
	#
	# ButtonPressed: called when the button is pressed. Changes the button;s image to 
	#                pressed.
	#
	# ButtonReleased: called when the button is released. If the mouse is over the 
	#                  widget, it calls invoke and changes image to active. Otherwise it
	#                  changes the image to normal and invoke is not called.
	#---------------------------------------------------------------------------------------

	method NewSize { option value } {
		if { $options(-width) == "" } {
			set options(-width) 0
		}
		
		if { $options(-height) == "" } {
			set options(-height) 0
		}
		
		set options($option) $value
		$self SetSize
	}

	method SetSize { } {
		if { $options(-width) != "" } {
			set buttonwidth $options(-width)
		} else {
			#Measure length of button text and add some padding to give width of button:
			set buttonwidth [expr [$self MeasureText w] + $options(-padx)]
			
			#Add extra room for emblem:
			if { $options(-emblem) != "" } {
				incr buttonwidth [expr [image width $options(-emblem)]]
			}
		}
		
		#If we have a height set by button... set it, else set it at the height of the button image, unless the text's height (inc newlines) is bigger, in which case we set it to that plus the top and bottom border widths:
		if { $options(-height) != "" } {
			set buttonheight $options(-height)
		} else {
			set buttonheight [image height $normal]
			if { [$self MeasureText h] > [image height $normal] } {
				set buttonheight [expr [$self MeasureText h] + $options(-pady)]
			}
		}
		# else {
		#	set buttonheight [image height $normal]
		#}
		
		#Configure the button with the new width and height:
		$hull configure -width $buttonwidth -height $buttonheight
	}
	
	method MeasureText { dimension } {
		if { $dimension == "w" } {
			if { $options(-font) != "" } {
				set idx [expr [string first "\n" $options(-text)] - 1] 
				if { $idx < 0 } { set idx end }
				set m [font measure $options(-font) -displayof $self [string range $options(-text) \
					0 $idx]]
				return $m
			} else {
				set idx [expr [string first "\n" $options(-text)] - 1] 
				if { $idx < 0 } { set idx end }
				set f [font create -family helvetica -size 12 -weight normal]
				set m [font measure $f -displayof $self [string range $options(-text) \
					0 $idx]]
				font delete $f
				return $m
			}
		} elseif { $dimension == "h" } {
			if { $options(-font) != "" } {
				#Get number of lines
				set n [$self NumberLines $options(-text)]
				#Multiply font size by no. lines and add gap between lines * (no. lines - 1).
				return [expr $n * [font configure $options(-font) -size] + (($n - 1) * 7)]
			} else {
				#Get number of lines
				set n [$self NumberLines $options(-text)]
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

	method setState { option value } {
		set options(-state) $value
		switch $value {
			normal { $hull itemconfigure button -image [$self.normal name] }
			active { $hull itemconfigure button -image [$self.active name] }
			pressed { $hull itemconfigure button -image [$self.pressed name] }
			disabled { $hull itemconfigure button -image [$self.disabled name] }
		}
	}

	method DrawFocus { } {
		$hull create image 0 0 -anchor nw -image [$self.focus name] -tag focus
		$hull lower focus text
		$self DrawButton $buttonwidth $buttonheight
	}

	method RemoveFocus { } {
		$hull delete focus
		$self DrawButton $buttonwidth $buttonheight
	}

	method DrawButton { w h } {
		set buttonwidth $w
		set buttonheight $h
		$hull configure -width $w -height $h
		$self.normal configure -width $w -height $h
		$self.hover configure -width $w -height $h
		$self.pressed configure -width $w -height $h
		$self.disabled configure -width $w -height $h
		$self.focus configure -width $w -height $h


		switch $options(-emblemanchor) {
			"nw" {
				$hull itemconfigure emblem -anchor nw
				$hull coords emblem $bdw $bdn
			}
			"w" {
				$hull itemconfigure emblem -anchor w
				$hull coords emblem $bdw [expr $h / 2]
			}
			"sw" {
				$hull itemconfigure emblem -anchor sw
				$hull coords emblem $bdw [expr $h - $bds]
			}
			"s" {
				$hull itemconfigure emblem -anchor s
				$hull coords emblem [expr $w / 2] [expr $h - $bds]
			}
			"se" {
				$hull itemconfigure emblem -anchor se
				$hull coords emblem [expr $w - $bde] [expr $h - $bds]
			}
			"e" {
				$hull itemconfigure emblem -anchor e
				$hull coords emblem [expr $w - $bde] [expr $h / 2]
			}
			"ne" {
				$hull itemconfigure emblem -anchor ne
				$hull coords emblem [expr $w - $bde] $bdn
			}
			"n" {
				$hull itemconfigure emblem -anchor n
				$hull coords emblem [expr $w / 2] $bdn
			}
			"c" {
				$hull itemconfigure emblem -anchor c
				$hull coords emblem [expr $w / 2] [expr $h / 2]
			}
			default {
				$hull itemconfigure emblem -anchor c
				$hull coords emblem [expr $w / 2] [expr $h / 2]
			}
		}
		
		switch $options(-anchor) {
			"nw" {
				$hull itemconfigure txt -anchor nw
				$hull coords txt $bdw $bdn
			}
			"w" {
				$hull itemconfigure txt -anchor w
				$hull coords txt $bdw [expr $h / 2]
			}
			"sw" {
				$hull itemconfigure txt -anchor sw
				$hull coords txt $bdw [expr $h - $bds]
			}
			"s" {
				$hull itemconfigure txt -anchor s
				$hull coords txt [expr $w / 2] [expr $h - $bds]
			}
			"se" {
				$hull itemconfigure txt -anchor se
				$hull coords txt [expr $w - $bde] [expr $h - $bds]
			}
			"e" {
				$hull itemconfigure txt -anchor e
				$hull coords txt [expr $w - $bde] [expr $h / 2]
			}
			"ne" {
				$hull itemconfigure txt -anchor ne
				$hull coords txt [expr $w - $bde] $bdn
			}
			"n" {
				$hull itemconfigure txt -anchor n
				$hull coords txt [expr $w / 2] $bdn
			}
			"c" {
				$hull itemconfigure txt -anchor c
				$hull coords txt [expr $w / 2] [expr $h / 2]
			}
			default {
				$hull itemconfigure txt -anchor c
				$hull coords txt [expr $w / 2] [expr $h / 2]
			}
		}
		
			if { $options(-emblem) != "" } {
				if { [string first "w" $options(-emblemanchor)] != -1 } {
					if {
						[string first "n" $options(-anchor) ] != "" ||
						[string first "c" $options(-anchor) ] != "" ||
						[string first "s" $options(-anchor) ] != ""
					} {
						$hull move txt [expr round(0.5 * [image width $options(-emblem)])] 0
				} elseif { [string first "e" $options(-emblemanchor)] != -1 } {
					#if {
					#	[string first "n" $options(-anchor) ] != "" ||
					#	[string first "c" $options(-anchor) ] != "" ||
					#	[string first "s" $options(-anchor) ] != ""
					#} {
						$hull move txt [expr round(-0.5 * [image width $options(-emblem)])] 0
					#}
				}
			}
		}
	
	}

	method ButtonHovered { } {
		if { $options(-state) == "disabled" } {
			return
		}
		if { $potent == "maybe" } {
			set potent "yes"
			$hull itemconfigure button -image [$self.pressed name]
		} else { 
			$hull itemconfigure button -image [$self.hover name]
		}
	}

	method ButtonUnhovered { } {
		if { $options(-state) == "disabled" } {
			return
		}
		if { $potent == "yes" } {
			set potent "maybe"
		} else {
			set potent "no"
		}
		$hull itemconfigure button -image [$self.normal name]
	}

	method ButtonPressed { } {
		if { $options(-state) == "disabled" } {
			return
		}
		set potent "yes"
		$hull itemconfigure button -image [$self.pressed name]
		if { $options(-repeatdelay) != "" && $options(-repeatinterval) != "" } {
			set Priv(afterId) [after $options(-repeatdelay) $self RepeatInvoke initial]
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
			$hull itemconfigure button -image [$self.hover name]
			if { $options(-repeatdelay) == "" && $options(-repeatinterval) == "" } {
				$self invoke
			}
			set potent "no"
		} else {
			set potent "no"
			$hull itemconfigure button -image [$self.normal name]
		}
	}

	method CancelRepeat { } {
		after cancel $Priv(afterId)
	}

	method RepeatInvoke { repeat } {
		eval $options(-command)

		if { $repeat == "initial" } {
			set Priv(afterId) [after $options(-repeatdelay) $self RepeatInvoke again]
		} else {
			set Priv(afterId) [after $options(-repeatinterval) $self RepeatInvoke again]
		}
	}

	method getOption { option } {
		return $options($option)
	}

	method setOption { option value } {
		set options($option) $value
		$hull configure $option $value
	}

	method getFont { option } {
		return [$hull itemcget txt -font]
	}

	method setFont { option value } {
		set options(-font) $value
		$hull itemconfigure txt -font $value
	}

	method setForeground { option value } {
		set options(-foreground) $value
		$hull itemconfigure txt -fill $value
	}

	method setEmblem { option value } {
		set options(-emblem) $value
		$hull itemconfigure emblem -image $value
	}

	method getAnchor { option } {
		return $options(-anchor)
	}

	method setAnchor { option value } {
		set options(-anchor) $value
	}
	
	method setEmblemAnchor { option value } {
		set options(-emblemanchor) $value
	}

	method setText { option value } {
		set options(-text) $value
		$hull itemconfigure txt -text $value
	}

	method setUnderline { option value } {
		set options(-underline) $value
	}

	#-------------------------------------------------------------------------------
	# Public methods
	# ~~~~~~~~~~~~~~~~~
	# invoke: invokes the command associated with the button
	# flash: makes the button alternate between active and normal state n times,
	#	 with a delay of ms
	#-------------------------------------------------------------------------------
	method invoke { } {
		eval $options(-command)
	}

	method flash { } {
		
	}

	typemethod reloadimages { } {
		set normal [::skin::getPixmap button]
		set hover [::skin::getPixmap button_hover]
		set pressed [::skin::getPixmap button_pressed]
		set disabled [::skin::getPixmap button_disabled]
		set focus [::skin::getPixmap button_focus]
	}
}