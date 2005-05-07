#Pixmapscroll 0.9 by Arieh Schneier and Tom Jenkins
#A scrollbar widget that uses pixmaps so you can have pretty-fied tk scrollbars!

package require snit
package provide pixmapscroll 0.9

snit::widgetadaptor pixmapscroll {

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

	variable arrow1width
	variable arrow1height
	variable arrow2width
	variable arrow2height

	component sliderimage
	component troughimage
	component sliderimage_hover

	variable canvas
	variable visible 1
	variable first 0
	variable last 1
	#TODO: needs to be initialised for first use (can we initialise in a better spot?)
	variable newsize 1000
	variable active_element ""


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
	option -width -default 14

	typeconstructor {
		foreach orientation {horizontal vertical} {
			set ${orientation}_arrow1image [image create photo -file $orientation/arrow1.gif]
			set ${orientation}_arrow2image [image create photo -file $orientation/arrow2.gif]
			set ${orientation}_slidertopimage [image create photo -file $orientation/slidertop.gif]
			set ${orientation}_sliderbodyimage [image create photo -file $orientation/sliderbody.gif]
			set ${orientation}_sliderbottomimage [image create photo -file $orientation/sliderbottom.gif]
			set ${orientation}_troughsrcimage [image create photo -file $orientation/trough.gif]

			set ${orientation}_arrow1image_hover [image create photo -file $orientation/arrow1_hover.gif]
			set ${orientation}_arrow2image_hover [image create photo -file $orientation/arrow2_hover.gif]
			set ${orientation}_slidertopimage_hover [image create photo -file $orientation/slidertop_hover.gif]
			set ${orientation}_sliderbodyimage_hover [image create photo -file $orientation/sliderbody_hover.gif]
			set ${orientation}_sliderbottomimage_hover [image create photo -file $orientation/sliderbottom_hover.gif]

			set ${orientation}_arrow1width [image width [set ${orientation}_arrow1image]]
			set ${orientation}_arrow1height [image height [set ${orientation}_arrow1image]]
			set ${orientation}_arrow2width [image width [set ${orientation}_arrow2image]]
			set ${orientation}_arrow2height [image height [set ${orientation}_arrow2image]]
		}
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

		set arrow1width [set ${orientation}_arrow1width]
		set arrow1height [set ${orientation}_arrow1height]
		set arrow2width [set ${orientation}_arrow2width]
		set arrow2height [set ${orientation}_arrow2height]


		set sliderimage [image create photo]
		set troughimage [image create photo]
		set sliderimage_hover [image create photo]

		$canvas configure -width $arrow1width -height $arrow1height

		$canvas create image 0 0 -anchor nw -image $troughimage -tag $troughimage

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

		bindtags $self "Scrollbar $self all"
	}

	method Setnewsize { news } {
		set newsize $news
	}

	#Draw or redraw the scrollbar
	method DrawScrollbar { } {
	
		#Drawing Trough
		if { $options(-orient) == "vertical" } {
			$troughimage blank
			$troughimage copy $troughsrcimage -to 0 0 [image width $troughsrcimage] $newsize -zoom 1 [expr { $newsize / [image height $troughsrcimage] }]
		} else {
			$troughimage blank
			$troughimage copy $troughsrcimage -to 0 0 $newsize [image height $troughsrcimage] -zoom [expr { $newsize / [image width $troughsrcimage] }] 1
		}

		#Drawing Arrows
		$canvas delete $arrow1image
		$canvas delete $arrow2image
		$canvas create image 0 0 -anchor nw -image $arrow1image -activeimage $arrow1image_hover -tag $arrow1image

		if { $options(-orient) == "vertical" } {
			$canvas create image 0 $newsize -anchor sw -image $arrow2image -activeimage $arrow2image_hover -tag $arrow2image
		} else {
			$canvas create image $newsize 0 -anchor ne -image $arrow2image -activeimage $arrow2image_hover -tag $arrow2image
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

			set sliderpos [expr {($first * ($newsize - ($arrow1height + $arrow2height))) + $arrow1height}]
			if { $sliderpos < $arrow1height } { set sliderpos $arrow1height }
			if { $sliderpos > [expr {$newsize - $arrow1height - $slidersize}] } { set sliderpos [expr {$newsize - $arrow1height - $slidersize}] }
			$canvas delete $sliderimage
			$canvas create image 0 $sliderpos -anchor nw -image $sliderimage -activeimage $sliderimage_hover -tag $sliderimage

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

			set sliderpos [expr {($first * ($newsize - ($arrow1width + $arrow2width))) + $arrow1width}]

			if { $sliderpos < $arrow1width } { set sliderpos $arrow1width }
			if { $sliderpos > [expr {$newsize - $arrow1width - $slidersize}] } { set sliderpos [expr {$newsize - $arrow1width - $slidersize}] }
			$canvas delete $sliderimage
			$canvas create image $sliderpos 0 -anchor nw -image $sliderimage -activeimage $sliderimage_hover -tag $sliderimage
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
			set pos [expr {1 - ($newsize - $y) / $newsize.0}]
		} else {
			set pos [expr {1 - ($newsize - $x) / $newsize.0}]
		}
		return $pos
	}

	method get { } {
		return [list $first $last]
	}

	method identify { x y } {
		set sliderpos [$canvas coords $sliderimage]
		set slidersize [image height $sliderimage]
		set trough1coords [$canvas coords trough1]
		set trough2coords [$canvas coords trough2]

		if { $options(-orient) == "vertical" } {
			if { $y <= $arrow1height } { return "arrow1" }
			if { $y >= [expr {$newsize - $arrow2height}] } { return "arrow2" }

			if { $y >= [lindex $sliderpos 1] && $y <= [expr {[lindex $sliderpos 1] + $slidersize}] } { return "slider" }

			if { $y >= [lindex trough1coords 1] && $y <= [lindex $trough1coords 3] } { return "trough1" }
			if { $y >= [lindex trough2coords 1] && $y <= [lindex $trough2coords 3] } { return "trough2" }

		} else {
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
}

