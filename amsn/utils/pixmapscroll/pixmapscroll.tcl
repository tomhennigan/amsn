#Pixmapscroll 0.9 by Arieh Schneier and Tom Jenkins
#A scrollbar widget that uses pixmaps so you can have pretty-fied tk scrollbars!

package require snit
package provide pixmapscroll 0.9

snit::widgetadaptor pixmapscroll {

	typevariable scrollbarlist {}

	typecomponent vertical_arrow1image
	typecomponent vertical_arrow2image
	typecomponent vertical_slidertopimage
	typecomponent vertical_sliderbodyimage
	typecomponent vertical_sliderbottomimage
	typecomponent vertical_troughsrcimage

	typecomponent vertical_arrow1image_hover
	typecomponent vertical_arrow2image_hover
	typecomponent vertical_slidertopimage_hover
	typecomponent vertical_sliderbodyimage_hover
	typecomponent vertical_sliderbottomimage_hover
	
	typecomponent vertical_arrow1image_pressed
	typecomponent vertical_arrow2image_pressed
	typecomponent vertical_slidertopimage_pressed
	typecomponent vertical_sliderbodyimage_pressed
	typecomponent vertical_sliderbottomimage_pressed

	typevariable vertical_arrow1width
	typevariable vertical_arrow1height
	typevariable vertical_arrow2width
	typevariable vertical_arrow2height


	typecomponent horizontal_arrow1image
	typecomponent horizontal_arrow2image
	typecomponent horizontal_slidertopimage
	typecomponent horizontal_sliderbodyimage
	typecomponent horizontal_sliderbottomimage
	typecomponent horizontal_troughsrcimage

	typecomponent horizontal_arrow1image_hover
	typecomponent horizontal_arrow2image_hover
	typecomponent horizontal_slidertopimage_hover
	typecomponent horizontal_sliderbodyimage_hover
	typecomponent horizontal_sliderbottomimage_hover
	
	typecomponent horizontal_arrow1image_pressed
	typecomponent horizontal_arrow2image_pressed
	typecomponent horizontal_slidertopimage_pressed
	typecomponent horizontal_sliderbodyimage_pressed
	typecomponent horizontal_sliderbottomimage_pressed

	typevariable horizontal_arrow1width
	typevariable horizontal_arrow1height
	typevariable horizontal_arrow2width
	typevariable horizontal_arrow2height


	component arrow1image
	component arrow2image
	component slidertopimage
	component sliderbodyimage
	component sliderbottomimage
	component troughsrcimage

	component arrow1image_hover
	component arrow2image_hover
	component slidertopimage_hover
	component sliderbodyimage_hover
	component sliderbottomimage_hover
	
	component arrow1image_pressed
	component arrow2image_pressed
	component slidertopimage_pressed
	component sliderbodyimage_pressed
	component sliderbottomimage_pressed

	variable arrow1width
	variable arrow1height
	variable arrow2width
	variable arrow2height

	component sliderimage
	component troughimage
	component sliderimage_hover
	component sliderimage_pressed

	variable canvas
	variable visible 1
	variable first 0
	variable last 1
	variable newsize 1
	variable active_element ""
	variable hidden 0
	variable packinfo ""
	variable packlist {}


	option -activebackground -default #ffffff
	option -background -default #eae7e4
	option -bg -default #eae7e4
	option -borderwidth -default 0
	option -bd -default 0
	option -cursor -default {}
	option -highlightbackground -default #eae7e4
	option -highlightcolor -default black
	option -highlightthickness -default 0
	option -jump -default 0
	option -orient -default "vertical" -readonly yes
	option -relief -default sunken
	option -repeatdelay -default 300
	option -repeatinterval -default 100
	option -takefocus -default {}
	option -troughcolor -default #d3d0ce

	option -activerelief -default raised
	option -command -default {}
	option -elementborderwidth -default -1
	option -width -default 14 -configuremethod SetWidth
	
	option -autohide -default 0 -configuremethod ChangeHide

	typeconstructor {
		$type reloadimages "" 1
	}

	constructor {args} {
		installhull using canvas -bg white -bd 0 -highlightthickness 0
		set canvas $hull

		$self configurelist $args

		#add abbreviations
		if { ($options(-orient) == "v") || ($options(-orient) == "vert") } {
			set options(-orient) "vertical"
		}

		if { $options(-orient) == "vertical" } {
			set orientation "vertical"
		} else {
			set orientation "horizontal"
		}

		set arrow1image [set ${orientation}_arrow1image]
		set arrow2image [set ${orientation}_arrow2image]
		set slidertopimage [set ${orientation}_slidertopimage]
		set sliderbodyimage [set ${orientation}_sliderbodyimage]
		set sliderbottomimage [set ${orientation}_sliderbottomimage]
		set troughsrcimage [set ${orientation}_troughsrcimage]

		set arrow1image_hover [set ${orientation}_arrow1image_hover]
		set arrow2image_hover [set ${orientation}_arrow2image_hover]
		set slidertopimage_hover [set ${orientation}_slidertopimage_hover]
		set sliderbodyimage_hover [set ${orientation}_sliderbodyimage_hover]
		set sliderbottomimage_hover [set ${orientation}_sliderbottomimage_hover]
		
		set arrow1image_pressed [set ${orientation}_arrow1image_pressed]
		set arrow2image_pressed [set ${orientation}_arrow2image_pressed]
		set slidertopimage_pressed [set ${orientation}_slidertopimage_pressed]
		set sliderbodyimage_pressed [set ${orientation}_sliderbodyimage_pressed]
		set sliderbottomimage_pressed [set ${orientation}_sliderbottomimage_pressed]
		

		set arrow1width [set ${orientation}_arrow1width]
		set arrow1height [set ${orientation}_arrow1height]
		set arrow2width [set ${orientation}_arrow2width]
		set arrow2height [set ${orientation}_arrow2height]


		set sliderimage [image create photo]
		set troughimage [image create photo]
		set sliderimage_hover [image create photo]
		set sliderimage_pressed [image create photo]

		# Draw components:
		$canvas create image 0 0 -anchor nw -image $troughimage -tag $troughimage
		$canvas create image 0 0 -anchor nw -image $sliderimage -activeimage $sliderimage_hover -tag $sliderimage
		$canvas create image 0 0 -anchor nw -image $arrow1image -activeimage $arrow1image_hover -tag $arrow1image

		if { $options(-orient) == "vertical" } {
			$canvas create image 0 $newsize -anchor sw -image $arrow2image -activeimage $arrow2image_hover -tag $arrow2image
		} else {
			$canvas create image $newsize 0 -anchor ne -image $arrow2image -activeimage $arrow2image_hover -tag $arrow2image
		}

		# Set width / height
		if { $options(-orient) == "vertical" } {
			$self configure -width $arrow1width
		} else {
			$self configure -width $arrow1height
		}

		# Set configure bindings:
		if { $options(-orient) == "vertical" } {
			bind $self <Configure> {
				%W Setnewsize %h
				%W DrawScrollbar
			}
		} else {
			bind $self <Configure> {
				%W Setnewsize %w
				%W DrawScrollbar
			}
		}

		bindtags $self "Pixmapscroll $self all"
		
		bind $self <Button-1> "$self PressedImage %x %y"
		bind $self <ButtonRelease-1> "$self ReleasedImage %x %y"
		
		lappend scrollbarlist $self
	}

	destructor {
		set ndx [lsearch $scrollbarlist $self]

		if {$ndx != -1} {
			set scrollbarlist [lreplace $scrollbarlist $ndx $ndx]
		}
	}

	method Setnewsize { news } {
		set newsize $news
	}

	method SetWidth {option value} {
		set options($option) $value
		if { $options(-orient) == "vertical" } {
			$canvas configure -width $value
		} else {
			$canvas configure -height $value
		}
	}

	method ChangeHide {option value} {
		set options($option) $value
		$self HideUnhide
	}

	method HideUnhide {} {
		if { ($visible == 1) && ($hidden == 0) && ($options(-autohide))} {
			if { ![catch { set packinfo [pack info $self] }] } {
				set packlist [pack slaves [winfo parent $self]]
				set packlist [lrange $packlist [expr {[lsearch $packlist $self] + 1}] end]
				pack forget $self
				set hidden 1
			}
		}
		
		if { ($hidden == 1) && ( ($visible != 1) || (!$options(-autohide)) ) } {
			#only pack if isn't currently packed
			if { [catch { pack info $self }] } {
				foreach child $packlist {
					if { ![catch { pack info $child } ] } {
						break
					}
				}
				eval pack $self $packinfo -before $child
			}
			set hidden 0
		}
	}

	method PressedImage { x y } {
		set element [$self identify $x $y]
		switch $element {
			"slider" { $canvas itemconfigure $sliderimage -image $sliderimage_pressed -activeimage $sliderimage_pressed }
			"arrow1" { $canvas itemconfigure $arrow1image -image $arrow1image_pressed -activeimage $arrow1image_pressed }
			"arrow2" { $canvas itemconfigure $arrow2image -image $arrow2image_pressed -activeimage $arrow2image_pressed }
			default { return }
		}
	}
	
	method ReleasedImage { x y } {
		$canvas itemconfigure $sliderimage -image $sliderimage -activeimage $sliderimage_hover
		$canvas itemconfigure $arrow1image -image $arrow1image -activeimage $arrow1image_hover
		$canvas itemconfigure $arrow2image -image $arrow2image -activeimage $arrow2image_hover
	}

	#Draw or redraw the scrollbar
	method DrawScrollbar { } {
	
	
		
		#Drawing Arrows:
		if { $options(-orient) == "vertical" } {
			$canvas coords $arrow2image 0 $newsize
		} else {
			$canvas coords $arrow2image $newsize 0
		}

		#Drawing Trough
		if { $options(-orient) == "vertical" } {
			$troughimage blank
			$troughimage copy $troughsrcimage -to 0 0 [image width $troughsrcimage] $newsize
		} else {
			$troughimage blank
			$troughimage copy $troughsrcimage -to 0 0 $newsize [image height $troughsrcimage]
		}

		#Drawing Slider
		if { $options(-orient) == "vertical" } {
			set slidersize [lindex [split [expr {$visible * ($newsize - ($arrow1height + $arrow2height))}] .] 0]

			#Make sure slider doesn't get negative size
			set minsize [expr {[image height $slidertopimage] + [image height $sliderbottomimage] + [image height $sliderbodyimage]}]
			if { $slidersize < $minsize } {
				set slidersize $minsize
			}

			$sliderimage blank
			$sliderimage copy $slidertopimage
			$sliderimage copy $sliderbodyimage -to 0 [image height $slidertopimage] [image width $sliderbodyimage] [expr {$slidersize - [image height $sliderbottomimage] }]
			$sliderimage copy $sliderbottomimage -to 0 [expr {$slidersize - [image height $sliderbottomimage]}] -shrink

			$sliderimage_hover blank
			$sliderimage_hover copy $slidertopimage_hover
			$sliderimage_hover copy $sliderbodyimage_hover -to 0 [image height $slidertopimage_hover] [image width $sliderbodyimage_hover] [expr {$slidersize - [image height $sliderbottomimage_hover] }]
			$sliderimage_hover copy $sliderbottomimage_hover -to 0 [expr {$slidersize - [image height $sliderbottomimage_hover]}] -shrink
			
			$sliderimage_pressed blank
			$sliderimage_pressed copy $slidertopimage_pressed
			$sliderimage_pressed copy $sliderbodyimage_pressed -to 0 [image height $slidertopimage_pressed] [image width $sliderbodyimage_pressed] [expr {$slidersize - [image height $sliderbottomimage_pressed] }]
			$sliderimage_pressed copy $sliderbottomimage_pressed -to 0 [expr {$slidersize - [image height $sliderbottomimage_pressed]}] -shrink

			# Set the slider's position:
			set sliderpos [expr {($first * ($newsize - ($arrow1height + $arrow2height))) + $arrow1height}]
			
			# Check to avoid slight moving of scrollbar during resizing when at top or bottom:
			if { [lindex [$self get] 0] == 0 } { set sliderpos $arrow1height }
			if { [lindex [$self get] 1] == 1 } { set sliderpos [expr $newsize - $arrow2height - $slidersize] }
			
			# Make sure the slider doesn't escape the trough!
			if { $sliderpos < $arrow1height } { set sliderpos $arrow1height }
			if { $sliderpos > [expr {$newsize - $arrow1height - $slidersize}] } { set sliderpos [expr {$newsize - $arrow1height - $slidersize}] }
			$canvas coords $sliderimage 0 $sliderpos

		} else {
			set slidersize [lindex [split [expr {$visible * ($newsize - ($arrow1width + $arrow2width))}] .] 0]

			#Make sure slider doesn't get negative size
			set minsize [expr {[image width $slidertopimage] + [image width $sliderbottomimage] + [image width $sliderbodyimage]}]

			if { $slidersize < $minsize } {
				set slidersize $minsize
			}


			$sliderimage blank
			$sliderimage copy $slidertopimage
			$sliderimage copy $sliderbodyimage -to [image width $slidertopimage] 0 [expr {$slidersize - [image width $sliderbottomimage]}] [image height $sliderbodyimage]
			$sliderimage copy $sliderbottomimage -to [expr {$slidersize - [image width $sliderbottomimage]}] 0 -shrink

			$sliderimage_hover blank
			$sliderimage_hover copy $slidertopimage_hover
			$sliderimage_hover copy $sliderbodyimage_hover -to [image width $slidertopimage_hover] 0 [expr {$slidersize - [image width $sliderbottomimage_hover]}] [image height $sliderbodyimage_hover]
			$sliderimage_hover copy $sliderbottomimage_hover -to [expr {$slidersize - [image width $sliderbottomimage_hover]}] 0 -shrink

			$sliderimage_pressed blank
			$sliderimage_pressed copy $slidertopimage_pressed
			$sliderimage_pressed copy $sliderbodyimage_pressed -to [image width $slidertopimage_pressed] 0 [expr {$slidersize - [image width $sliderbottomimage_pressed]}] [image height $sliderbodyimage_pressed]
			$sliderimage_pressed copy $sliderbottomimage_pressed -to [expr {$slidersize - [image width $sliderbottomimage_pressed]}] 0 -shrink

			set sliderpos [expr {($first * ($newsize - ($arrow1width + $arrow2width))) + $arrow1width}]

			if { $sliderpos < $arrow1width } { set sliderpos $arrow1width }
			if { $sliderpos > [expr {$newsize - $arrow1width - $slidersize}] } { set sliderpos [expr {$newsize - $arrow1width - $slidersize}] }
			$canvas coords $sliderimage $sliderpos 0
		}

		#Drawing "virtual troughs"
		$canvas delete trough1
		$canvas delete trough2
		if { $options(-orient) == "vertical" } {
			$canvas create rectangle 0 $arrow1height [image width $troughimage] $sliderpos -fill "" -outline "" -tag trough1
			$canvas create rectangle 0 [expr {$sliderpos + $slidersize}] [image width $troughimage] [expr {$newsize - $arrow2height}] -fill "" -outline "" -tag trough2
		} else {
			$canvas create rectangle $arrow1width 0 $sliderpos [image height $troughimage] -fill "" -outline "" -tag trough1
			$canvas create rectangle [expr {$sliderpos + $slidersize}] 0 [expr {$newsize - $arrow2width}] [image height $troughimage] -fill "" -outline "" -tag trough2
		}
	}

	method activate { {element "return"} } {
		if { $element == "return" } {
			return $active_element
		}

		if { ($element == "arrow1") || ($element == "arrow2") || ($element == "slider") } {
			set active_element $element
		} else {
			set active_element ""
		}
	}

	method delta { deltaX deltaY } {
		if {$options(-orient) == "vertical" } {
			set number [expr $deltaY.0 / ($newsize - ($arrow1height + $arrow2height))]
		} else {
			set number [expr $deltaX.0 / ($newsize - ($arrow1width + $arrow2width))]
		}

		return $number
	}

	method fraction { x y } {
		if { $options(-orient) == "vertical" } {
			set pos [expr 1 - ($newsize - $y) / $newsize.0]
		} else {
			set pos [expr 1 - ($newsize - $x) / $newsize.0]
		}
		return $pos
	}

	method get { } {
		return [list $first $last]
	}

	method identify { x y } {
		set sliderpos [$canvas coords $sliderimage]
		set trough1coords [$canvas coords trough1]
		set trough2coords [$canvas coords trough2]

		if { $options(-orient) == "vertical" } {
			set slidersize [image height $sliderimage]
			if { $y <= $arrow1height } { return "arrow1" }
			if { $y >= [expr {$newsize - $arrow2height}] } { return "arrow2" }

			if { $y >= [lindex $sliderpos 1] && $y <= [expr {[lindex $sliderpos 1] + $slidersize}] } { return "slider" }

			if { $y >= [lindex trough1coords 1] && $y <= [lindex $trough1coords 3] } { return "trough1" }
			if { $y >= [lindex trough2coords 1] && $y <= [lindex $trough2coords 3] } { return "trough2" }

		} else {
			set slidersize [image width $sliderimage]
			if { $x <= $arrow1width } { return "arrow1" }
			if { $x >= [expr {$newsize - $arrow2width}] } { return "arrow2" }

			if { $x >= [lindex $sliderpos 0] && $x <= [expr {[lindex $sliderpos 0] + $slidersize}] } { return "slider" }

			if { $x >= [lindex $trough1coords 0] && $x <= [lindex $trough1coords 2] } { return "trough1" }
			if { $x >= [lindex $trough2coords 0] && $x <= [lindex $trough2coords 2] } { return "trough2" }
		}
	}

	method set { ord1 ord2 } {
		set first $ord1
		set last $ord2

		set visible [expr {$last - $first}]
		$self DrawScrollbar

		$self HideUnhide
	}


	method moveto { fraction } {
		eval $options(-command) moveto $fraction
		$self DrawScrollbar
	}

	method scroll { number what } {
		set oldtop [lindex [eval $options(-command)] 0]
		eval "$options(-command) scroll $number $what"
		set newtop [lindex [eval $options(-command)] 0]

		if { $options(-orient) == "vertical" } {
			set sliderpos [lindex [$canvas coords $sliderimage] 1]
			$canvas coords $sliderimage 0 [expr {$sliderpos + [delta 0 [expr {$newtop - $oldtop}]]}]
		} else {
			set sliderpos [lindex [$canvas coords $sliderimage] 0]
			$canvas coords $sliderimage [expr {$sliderpos + [delta 0 [expr {$newtop - $oldtop}]]}] 0
		}

	}
	
	typemethod reloadimages { dir {force 0} } {
		foreach orientation {horizontal vertical} {
			foreach pic {arrow1 arrow2 slidertop sliderbody sliderbottom} {
				foreach hov {{} _hover _pressed} {
					if { [file exists [file join $dir $orientation/${pic}${hov}.gif]] || $force } {
						set ${orientation}_${pic}image${hov} [image create photo ${orientation}_${pic}image${hov} -file [file join $dir $orientation/${pic}${hov}.gif]]
					}
				}
			}
			if { [file exists [file join $dir $orientation/trough.gif]] || $force } {
				set ${orientation}_troughsrcimage [image create photo ${orientation}_troughsrcimage -file [file join $dir $orientation/trough.gif]]
			}

			set ${orientation}_arrow1width [image width [set ${orientation}_arrow1image]]
			set ${orientation}_arrow1height [image height [set ${orientation}_arrow1image]]
			set ${orientation}_arrow2width [image width [set ${orientation}_arrow2image]]
			set ${orientation}_arrow2height [image height [set ${orientation}_arrow2image]]
		}
		
		foreach scrollwidget $scrollbarlist {
			if { [$scrollwidget cget -orient] == "vertical" } {
				$scrollwidget configure -width [set ${orientation}_arrow1width]
			} else {
				$scrollwidget configure -width [set ${orientation}_arrow1height]
			}
			$scrollwidget DrawScrollbar
		}
	}
}


#Bindings copied straight from Scrollbar bindings
#Can't just use the Scrollbar tag as they aren't bound for windows or mac

bind Pixmapscroll <Enter> {
    if {$tk_strictMotif} {
	set tk::Priv(activeBg) [%W cget -activebackground]
	%W config -activebackground [%W cget -background]
    }
    %W activate [%W identify %x %y]
}
bind Pixmapscroll <Motion> {
    %W activate [%W identify %x %y]
}

# The "info exists" command in the following binding handles the
# situation where a Leave event occurs for a scrollbar without the Enter
# event.  This seems to happen on some systems (such as Solaris 2.4) for
# unknown reasons.

bind Pixmapscroll <Leave> {
    if {$tk_strictMotif && [info exists tk::Priv(activeBg)]} {
	%W config -activebackground $tk::Priv(activeBg)
    }
    %W activate {}
}
bind Pixmapscroll <1> {
    tk::ScrollButtonDown %W %x %y
}
bind Pixmapscroll <B1-Motion> {
    tk::ScrollDrag %W %x %y
}
bind Pixmapscroll <B1-B2-Motion> {
    tk::ScrollDrag %W %x %y
}
bind Pixmapscroll <ButtonRelease-1> {
    tk::ScrollButtonUp %W %x %y
}
bind Pixmapscroll <B1-Leave> {
    # Prevents <Leave> binding from being invoked.
}
bind Pixmapscroll <B1-Enter> {
    # Prevents <Enter> binding from being invoked.
}
bind Pixmapscroll <2> {
    tk::ScrollButton2Down %W %x %y
}
bind Pixmapscroll <B1-2> {
    # Do nothing, since button 1 is already down.
}
bind Pixmapscroll <B2-1> {
    # Do nothing, since button 2 is already down.
}
bind Pixmapscroll <B2-Motion> {
    tk::ScrollDrag %W %x %y
}
bind Pixmapscroll <ButtonRelease-2> {
    tk::ScrollButtonUp %W %x %y
}
bind Pixmapscroll <B1-ButtonRelease-2> {
    # Do nothing:  B1 release will handle it.
}
bind Pixmapscroll <B2-ButtonRelease-1> {
    # Do nothing:  B2 release will handle it.
}
bind Pixmapscroll <B2-Leave> {
    # Prevents <Leave> binding from being invoked.
}
bind Pixmapscroll <B2-Enter> {
    # Prevents <Enter> binding from being invoked.
}
bind Pixmapscroll <Control-1> {
    tk::ScrollTopBottom %W %x %y
}
bind Pixmapscroll <Control-2> {
    tk::ScrollTopBottom %W %x %y
}

bind Pixmapscroll <Up> {
    tk::ScrollByUnits %W v -1
}
bind Pixmapscroll <Down> {
    tk::ScrollByUnits %W v 1
}
bind Pixmapscroll <Control-Up> {
    tk::ScrollByPages %W v -1
}
bind Pixmapscroll <Control-Down> {
    tk::ScrollByPages %W v 1
}
bind Pixmapscroll <Left> {
    tk::ScrollByUnits %W h -1
}
bind Pixmapscroll <Right> {
    tk::ScrollByUnits %W h 1
}
bind Pixmapscroll <Control-Left> {
    tk::ScrollByPages %W h -1
}
bind Pixmapscroll <Control-Right> {
    tk::ScrollByPages %W h 1
}
bind Pixmapscroll <Prior> {
    tk::ScrollByPages %W hv -1
}
bind Pixmapscroll <Next> {
    tk::ScrollByPages %W hv 1
}
bind Pixmapscroll <Home> {
    tk::ScrollToPos %W 0
}
bind Pixmapscroll <End> {
    tk::ScrollToPos %W 1
}

if {![string equal [tk windowingsystem] "x11"]} {
    bind Pixmapscroll <MouseWheel> {
        tk::ScrollByUnits %W v [expr {- (%D)}]
    }
    bind Pixmapscroll <Option-MouseWheel> {
        tk::ScrollByUnits %W v [expr {-10 * (%D)}]
    }
    bind Pixmapscroll <Shift-MouseWheel> {
        tk::ScrollByUnits %W h [expr {- (%D)}]
    }
    bind Pixmapscroll <Shift-Option-MouseWheel> {
        tk::ScrollByUnits %W h [expr {-10 * (%D)}]
    }
} else {
    bind Pixmapscroll <ButtonPress-5> {
        tk::ScrollByUnits %W v 1
    }
    bind Pixmapscroll <ButtonPress-4> {
        tk::ScrollByUnits %W v -1
    }

    bind Pixmapscroll <Option-ButtonPress-5> {
        tk::ScrollByUnits %W v 10
    }
    bind Pixmapscroll <Option-ButtonPress-4> {
        tk::ScrollByUnits %W v -10
    }

    bind Pixmapscroll <Shift-ButtonPress-5> {
        tk::ScrollByUnits %W h 1
    }
    bind Pixmapscroll <Shift-ButtonPress-4> {
        tk::ScrollByUnits %W h -1
    }

    bind Pixmapscroll <Shift-Option-ButtonPress-5> {
        tk::ScrollByUnits %W h 10
    }
    bind Pixmapscroll <Shift-Option-ButtonPress-4> {
        tk::ScrollByUnits %W h -10
    }
}
