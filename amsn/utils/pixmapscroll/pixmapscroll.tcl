package require snit
package provide pixmapscroll 0.9

snit::widgetadaptor pixmapscroll {

	typecomponent arrow1image
	typecomponent arrow2image
	typecomponent slidertopimage
	typecomponent sliderbodyimage
	typecomponent sliderbottomimage
	typecomponent troughsrcimage

	typecomponent arrow1image_hover
	typecomponent arrow2image_hover
	typecomponent slidertopimage_hover
	typecomponent sliderbodyimage_hover
	typecomponent sliderbottomimage_hover

	typevariable arrow1width
	typevariable arrow1height
	typevariable arrow2width
	typevariable arrow2height

	component sliderimage
	component troughimage
	component sliderimage_hover

	variable canvas
	variable visible 1
	variable first 0
	variable last 1
	#TODO: needs to be initialised for first use (can we initialise in a better spot?)
	variable newsize 1000


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

#TODO: remove this hardcoding and allow for both
#set orientation horizontal
set orientation vertical

		set arrow1image [image create photo -file $orientation/arrow1.gif]
		set arrow2image [image create photo -file $orientation/arrow2.gif]
		set slidertopimage [image create photo -file $orientation/slidertop.gif]
		set sliderbodyimage [image create photo -file $orientation/sliderbody.gif]
		set sliderbottomimage [image create photo -file $orientation/sliderbottom.gif]
		set troughsrcimage [image create photo -file $orientation/trough.gif]

		set arrow1image_hover [image create photo -file $orientation/arrow1_hover.gif]
		set arrow2image_hover [image create photo -file $orientation/arrow2_hover.gif]
		set slidertopimage_hover [image create photo -file $orientation/slidertop_hover.gif]
		set sliderbodyimage_hover [image create photo -file $orientation/sliderbody_hover.gif]
		set sliderbottomimage_hover [image create photo -file $orientation/sliderbottom_hover.gif]

		set arrow1width [image width $arrow1image]
		set arrow1height [image height $arrow1image]
		set arrow2width [image width $arrow2image]
		set arrow2height [image height $arrow2image]

	}


	constructor {args} {
		installhull using canvas -bg white -bd 0 -highlightthickness 0 -width $arrow1width -height $arrow1height
		set canvas $hull

		$self configurelist $args

		set sliderimage [image create photo]
		set troughimage [image create photo]
		set sliderimage_hover [image create photo]

		$canvas create image 0 0 -anchor nw -image $troughimage -tag $troughimage

		if { $options(-orient) == "vertical" } {
			bind $self <Configure> {
				%W Setnewsize %h
				%W DrawScrollbar
			}
		} else {
			bind $canvas <Configure> {
				%W Setnewsize %h
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
			set slidersize [lindex [split [expr ($visible * ($newsize - ($arrow1height + $arrow2height)))] .] 0]
		
			#Make sure slider doesn't get negative size
			set minsize [expr [image height $slidertopimage] + [image height $sliderbottomimage] + [image height $sliderbodyimage]]
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
			if { $sliderpos > [expr $newsize - $arrow1height - $slidersize] } { set sliderpos [expr $newsize - $arrow1height - $slidersize] }
			$canvas delete $sliderimage
			$canvas create image 0 $sliderpos -anchor nw -image $sliderimage -activeimage $sliderimage_hover -tag $sliderimage
		
		} else {
			set slidersize [lindex [split [expr ($visible * ($newsize - ($arrow1width + $arrow2width)))] .] 0]
		
			#Make sure slider doesn't get negative size
			set minsize [expr {[image height $slidertopimage] + [image height $sliderbottomimage] + [image height $sliderbodyimage]}]
		
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
			if { $sliderpos > [expr $newsize - $arrow1width - $slidersize] } { set sliderpos [expr $newsize - $arrow1width - $slidersize] }
			$canvas delete $sliderimage
			$canvas create image $sliderpos 0 -anchor nw -image $sliderimage -activeimage $sliderimage_hover -tag $sliderimage
		}
	
		#Drawing "virtual troughs"
		$canvas delete trough1
		$canvas delete trough2
		if { $options(-orient) == "vertical" } {
			#puts hi
			puts $sliderpos
			$canvas create rectangle 0 $arrow1height [image width $troughimage] $sliderpos -fill "" -outline "" -tag trough1
			$canvas create rectangle 0 [expr $sliderpos + $slidersize] [image width $troughimage] [expr $newsize - $arrow2height] -fill "" -outline "" -tag trough2
		} else {
			$canvas create rectangle $arrow1width 0 $sliderpos [image height $troughimage] -fill "" -outline "" -tag trough1
			$canvas create rectangle [expr $sliderpos + $slidersize] 0 [expr $newsize - $arrow2width] [image height $troughimage] -fill "" -outline "" -tag trough2
		}
	}

	method activate { {element ""} } {
		return ""
	}

	method delta { deltaX deltaY } {
puts $newsize
		if {$options(-orient) == "vertical" } {
			set number [expr $deltaY.0 / ($newsize - ($arrow1height + $arrow2height))]
		} else {
			set number [expr $deltaX.0 / ($newsize - ($arrow1width + $arrow2width) - [image width $sliderimage])]
		}
	
		puts $number
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
		set slidersize [image height $sliderimage]
		set trough1coords [$canvas coords trough1]
		set trough2coords [$canvas coords trough2]

		if { $options(-orient) == "vertical" } {
			if { $y <= $arrow1height } { return "arrow1" }
			if { $y >= [expr $newsize - $arrow2height] } { return "arrow2" }
	
			if { $y >= [lindex $sliderpos 1] && $y <= [expr [lindex $sliderpos 1] + $slidersize] } { return "slider" }
	
			if { $y >= [lindex trough1coords 1] && $y <= [lindex $trough1coords 3] } { return "trough1" }
			if { $y >= [lindex trough2coords 1] && $y <= [lindex $trough2coords 3] } { return "trough2" }

		} else {
			if { $x <= $arrow1width } { return "arrow1" }
			if { $x >= [expr $newsize - $arrow2width] } { return "arrow2" }
	
			if { $x >= [lindex $sliderpos 0] && $x <= [expr [lindex $sliderpos 0] + $slidersize] } { return "slider" }
	
			if { $x >= [lindex trough1coords 0] && $x <= [lindex $trough1coords 2] } { return "trough1" }
			if { $x >= [lindex trough2coords 0] && $x <= [lindex $trough2coords 2] } { return "trough2" }
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
			$canvas coords $sliderimage 0 [expr $sliderpos + [delta 0 [expr $newtop - $oldtop]]]
		} else {
			set sliderpos [lindex [$canvas coords $sliderimage] 0]
			$canvas coords $sliderimage [expr $sliderpos + [delta 0 [expr $newtop - $oldtop]]] 0
		}

	}
}

