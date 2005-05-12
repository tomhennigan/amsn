package require snit
package provide pixmapbutton 0.1

snit::widget pixmapbutton {
	
	#-------------------
	# Image components
	#-------------------
	component img
	component img_hover
	component img_pressed
	component img_disabled
	
	component srcimg
	component srcimg_hover
	component srcimg_pressed
	component srcimg_disabled
	#-------------------------
	component button
	
	#-------------------------
	# Define options
	#-------------------------
	option -borderwidth -default 0
	option -bd
	option -background -default white
	option -foreground -default black
	option -fg -cgetmethod getOption -configuremethod changeForeground
	option -text -cgetmethod getText -configuremethod changeText
	option -font
	option -width
	option -height
	option -bg
	option -class
	option -relief -default solid
	option -overrelief -default solid
	option -activeborderwidth -default 0
	option -activebackground -default white
	option -activeforeground -default darkgreen
	option -highlightthickness -default 0
	option -command -default ""
	option -state -default "normal"
	option -emblemimage -default ""
	option -emblempos -default [list right center]
	#-------------------------
	
	delegate option * to button except {-borderwidth -bd -background -bg -class -width -height}

	
	#-------------------------
	# Create the widget
	#-------------------------
	constructor {args} {
		
		#--------------------------------------------------
		# Creating and configuring the label
		#--------------------------------------------------
		#check for type and class
		set itstype canvas
		set itsclass ""
		foreach {option value} $args {
			if { [string equal $option "-class"] } {
				set itsclass $value
			}
		}

		$hull configure -background $options(-background) -relief solid -borderwidth 0
		
		# Apply any options passed at creation time.
		$self configurelist $args
		
		if { $itsclass == "" } {
			install button using label $win.button \
			-text $options(-text) \
			-compound center \
			-bg white \
			-padx 0 \
			-pady 0 \
			-highlightthickness 0 \
			-relief solid \
			-bd 0 \
			-fg $options(-foreground) \
			-activeforeground $options(-activeforeground)
		} else {
			install button using label $win.button -class $itsclass -borderwidth 0
		}
		
		if {  $options(-font) != "" } {
			$button configure -font $options(-font)
			puts 1
		} else {
			puts 2
			#$self configure -font [font create -family helvetica -size 11 -weight bold]
		}
		
		#--------------------------------------------------
		
		#-------------------------
		# Setting various variables
		#-------------------------
		set buttonsize [list 0 0]
		typevariable potent
		typevariable state
		global potent
		global state
		set state $options(-state)
		set potent "no"
		
		
		set img [image create photo -width [lindex $buttonsize 0] -height [lindex $buttonsize 1]]
		set srcimg [image create photo -file button.gif]

		set img_hover [image create photo -width [lindex $buttonsize 0] -height [lindex $buttonsize 1]]
		set srcimg_hover [image create photo -file button_hover.gif]

		set img_pressed [image create photo -width [lindex $buttonsize 0] -height [lindex $buttonsize 1]]
		set srcimg_pressed [image create photo -file button_pressed.gif]

		set img_disabled [image create photo -width [lindex $buttonsize 0] -height [lindex $buttonsize 1]]
		set srcimg_disabled [image create photo -file button_disabled.gif]

		#-------------------------


		#-------------------------
		# Create bindings
		#-------------------------
		pack $button

		bind $self <Configure> "$self DrawButton %w %h"

		bind $button <Enter> "$self ButtonHovered"
		bind $button <Leave> "$self ButtonUnhovered"
		bind $button <Button-1> "$self ButtonPressed"
		bind $button <ButtonRelease-1> "$self ButtonReleased"
		#-------------------------

		$self BuildImage [lindex $buttonsize 0] [lindex $buttonsize 1]
		$win.button configure -image $img
	}

	method ButtonHovered { } {
		global potent
		if {$options(-state) != "disabled" } {
			$self configure -image $img_hover
			if { $potent == "no" } { set $potent "yes" }
		}
	}
	
	method ButtonUnhovered { } {
		global potent
		if {$options(-state) != "disabled" } {
			$self configure -image $img
			set potent "no"
		}
	}
	
	method ButtonPressed { } {
		global potent
		if {$options(-state) != "disabled" } {
			$self configure -image $img_pressed
			set potent "yes"
		}
	}
	
	method ButtonReleased { } {
		global potent
		if {$options(-state) != "disabled" } {
			if { $potent == "yes" } {
				$self configure -image $img_hover
				$self invoke
			} elseif { $potent == "no" } {
				$self configure -image $img
			} else { }
		}
	}
	
	method DrawButton { width height } {
		variable img
		$self BuildImage $width $height
		switch $options(-state) {
			"normal" { $self configure -image $img }
			"active" { $self configure -image $img_hover }
			"disabled" { $self configure -image $img_disabled }
			default { }
		}
	}
	
	method BuildImage { width height } {
		variable img
		$img blank
		set minwidth [expr 4 * 4]
		set minheight [image height $srcimg]
		
		if { $height < $minheight } { set height $minheight }
		if { $width < $minwidth } { set width $minwidth }
		
		$img configure -width $width -height $height
		$img copy $srcimg -from 0 0 4 2 -to 0 0
		$img copy $srcimg -from 4 0 [expr 4 + 1] 2 -to 4 0 [expr $width - 4] 2
		$img copy $srcimg -from [expr [image width $srcimg] - 4] 0 [image width $srcimg] 2 -to [expr $width - 4] 0
		$img copy $srcimg -from 0 2 4 [expr [image height $srcimg] - 2] -to 0 2 4 [expr $height - 2]
		$img copy $srcimg -from 4 2 [expr [image width $srcimg] - 4] [expr [image height $srcimg] - 2] -to 4 2 [expr $width - 4] [expr $height - 2]
		$img copy $srcimg -from [expr [image width $srcimg] - 4] 2 [image width $srcimg] [expr [image height $srcimg] - 2] -to [expr $width - 4] 2 $width [expr $height - 2]
		$img copy $srcimg -from 0 [expr [image height $srcimg] - 2] 4 [image height $srcimg] -to 0 [expr $height - 2]
		$img copy $srcimg -from 4 [expr [image height $srcimg] - 2] [expr 4 + 1] [image height $srcimg] -to 4 [expr $height - 2] [expr $width - 4] $height
		$img copy $srcimg -from [expr [image width $srcimg] - 4] [expr [image height $srcimg] - 2] [image width $srcimg] [image height $srcimg] -to [expr $width - 4] [expr $height - 2]
		
		#Add emblem
		#if { $options(-emblemimage) != "" } {
		#	switch [lindex $options(-emblempos) 0] {
		#		"left" {
		#			set xpos 4
		#		}
		#		"center" {
		#			set xpos [expr $width / 2 - ([image width $options(-emblemimage)] / 2)]
		#			set xpos [lindex [split $xpos .] 0]
		#		}
		#		"right" {
		#			set xpos [expr $width - 4 - ([image width $options(-emblemimage)])]
		#			set xpos [lindex [split $xpos .] 0]
		#		}
		#	}

		#	switch [lindex $options(-emblempos) 1] {
		#		"top" {
		#			set ypos 2
		#		}
		#		"center" {
		#			set ypos [expr $height / 2 - ([image height $options(-emblemimage)] / 2)]
		#			set ypos [lindex [split $ypos .] 0]
		#		}
		#		"bottom" {
		#			set ypos [expr $height - 2 - ([image height $options(-emblemimage)] * 1.5)]
		#			set ypos [lindex [split $ypos .] 0]
		#		}
		#	}

		#	if { $xpos < 0 } { set xpos 0 }
		#	$img copy $options(-emblemimage) -to $xpos $ypos
		#}

		
		$img_hover configure -width $width -height $height
		$img_hover copy $srcimg_hover -from 0 0 4 2 -to 0 0
		$img_hover copy $srcimg_hover -from 4 0 [expr 4 + 1] 2 -to 4 0 [expr $width - 4] 2
		$img_hover copy $srcimg_hover -from [expr [image width $srcimg_hover] - 4] 0 [image width $srcimg_hover] 2 -to [expr $width - 4] 0
		$img_hover copy $srcimg_hover -from 0 2 4 [expr [image height $srcimg_hover] - 2] -to 0 2 4 [expr $height - 2]
		$img_hover copy $srcimg_hover -from 4 2 [expr [image width $srcimg_hover] - 4] [expr [image height $srcimg_hover] - 2] -to 4 2 [expr $width - 4] [expr $height - 2]
		$img_hover copy $srcimg_hover -from [expr [image width $srcimg_hover] - 4] 2 [image width $srcimg_hover] [expr [image height $srcimg_hover] - 2] -to [expr $width - 4] 2 $width [expr $height - 2]
		$img_hover copy $srcimg_hover -from 0 [expr [image height $srcimg_hover] - 2] 4 [image height $srcimg_hover] -to 0 [expr $height - 2]
		$img_hover copy $srcimg_hover -from 4 [expr [image height $srcimg_hover] - 2] [expr 4 + 1] [image height $srcimg_hover] -to 4 [expr $height - 2] [expr $width - 4] $height
		$img_hover copy $srcimg_hover -from [expr [image width $srcimg_hover] - 4] [expr [image height $srcimg_hover] - 2] [image width $srcimg_hover] [image height $srcimg_hover] -to [expr $width - 4] [expr $height - 2]

		#Add emblem
		#if { $options(-emblemimage) != "" } {
		#	switch [lindex $options(-emblempos) 0] {
		#		"left" {
		#			set xpos [image width 4]
		#		}
		#		"center" {
		#			set xpos [expr $width / 2 - ([image width $options(-emblemimage)] / 2)]
		#			set xpos [lindex [split $xpos .] 0]
		#		}
		#		"right" {
		#			set xpos [expr $width - 4 - ([image width $options(-emblemimage)])]
		#			set xpos [lindex [split $xpos .] 0]
		#		}
		#	}

		#	switch [lindex $options(-emblempos) 1] {
		#		"top" {
		#			set ypos [image height 2]
		#		}
		#		"center" {
		#			set ypos [expr $height / 2 - ([image height $options(-emblemimage)] / 2)]
		#			set ypos [lindex [split $ypos .] 0]
		#		}
		#		"bottom" {
		#			set ypos [expr $height - 2 - ([image height $options(-emblemimage)] * 1.5)]
		#			set ypos [lindex [split $ypos .] 0]
		#		}
		#	}

		#	if { $xpos < 0 } { set xpos 0 }
		#	$img_hover copy $options(-emblemimage) -to $xpos $ypos
		#}
		
		$img_pressed configure -width $width -height $height
		$img_pressed copy $srcimg_pressed -from 0 0 4 2 -to 0 0
		$img_pressed copy $srcimg_pressed -from 4 0 [expr 4 + 1] 2 -to 4 0 [expr $width - 4] 2
		$img_pressed copy $srcimg_pressed -from [expr [image width $srcimg_pressed] - 4] 0 [image width $srcimg_pressed] 2 -to [expr $width - 4] 0
		$img_pressed copy $srcimg_pressed -from 0 2 4 [expr [image height $srcimg_pressed] - 2] -to 0 2 4 [expr $height - 2]
		$img_pressed copy $srcimg_pressed -from 4 2 [expr [image width $srcimg_pressed] - 4] [expr [image height $srcimg_pressed] - 2] -to 4 2 [expr $width - 4] [expr $height - 2]
		$img_pressed copy $srcimg_pressed -from [expr [image width $srcimg_pressed] - 4] 2 [image width $srcimg_pressed] [expr [image height $srcimg_pressed] - 2] -to [expr $width - 4] 2 $width [expr $height - 2]
		$img_pressed copy $srcimg_pressed -from 0 [expr [image height $srcimg_pressed] - 2] 4 [image height $srcimg_pressed] -to 0 [expr $height - 2]
		$img_pressed copy $srcimg_pressed -from 4 [expr [image height $srcimg_pressed] - 2] [expr 4 + 1] [image height $srcimg_pressed] -to 4 [expr $height - 2] [expr $width - 4] $height
		$img_pressed copy $srcimg_pressed -from [expr [image width $srcimg_pressed] - 4] [expr [image height $srcimg_pressed] - 2] [image width $srcimg_pressed] [image height $srcimg_pressed] -to [expr $width - 4] [expr $height - 2]
		
		#Add emblem
		#if { $options(-emblemimage) != "" } {
		#	switch [lindex $options(-emblempos) 0] {
		#		"left" {
		#			set xpos 4
		#		}
		#		"center" {
		#			set xpos [expr $width / 2 - ([image width $options(-emblemimage)] / 2)]
		#			set xpos [lindex [split $xpos .] 0]
		#		}
		#		"right" {
		#			set xpos [expr $width - 4 - ([image width $options(-emblemimage)])]
		#			set xpos [lindex [split $xpos .] 0]
		#		}
		#	}

		#	switch [lindex $options(-emblempos) 1] {
		#		"top" {
		#			set ypos [image height 2]
		#		}
		#		"center" {
		#			set ypos [expr $height / 2 - ([image height $options(-emblemimage)] / 2)]
		#			set ypos [lindex [split $ypos .] 0]
		#		}
		#		"bottom" {
		#			set ypos [expr $height - 2 - ([image height $options(-emblemimage)] * 1.5)]
		#			set ypos [lindex [split $ypos .] 0]
		#		}
		#	}

		#	if { $xpos < 0 } { set xpos 0 }
		#	$img_pressed copy $options(-emblemimage) -to $xpos $ypos
		#}
		
		$img_disabled configure -width $width -height $height
		$img_disabled copy $srcimg_disabled -from 0 0 4 2 -to 0 0
		$img_disabled copy $srcimg_disabled -from 4 0 [expr 4 + 1] 2 -to 4 0 [expr $width - 4] 2
		$img_disabled copy $srcimg_disabled -from [expr [image width $srcimg_disabled] - 4] 0 [image width $srcimg_disabled] 2 -to [expr $width - 4] 0
		$img_disabled copy $srcimg_disabled -from 0 2 4 [expr [image height $srcimg_disabled] - 2] -to 0 2 4 [expr $height - 2]
		$img_disabled copy $srcimg_disabled -from 4 2 [expr [image width $srcimg_disabled] - 4] [expr [image height $srcimg_disabled] - 2] -to 4 2 [expr $width - 4] [expr $height - 2]
		$img_disabled copy $srcimg_disabled -from [expr [image width $srcimg_disabled] - 4] 2 [image width $srcimg_disabled] [expr [image height $srcimg_disabled] - 2] -to [expr $width - 4] 2 $width [expr $height - 2]
		$img_disabled copy $srcimg_disabled -from 0 [expr [image height $srcimg_disabled] - 2] 4 [image height $srcimg_disabled] -to 0 [expr $height - 2]
		$img_disabled copy $srcimg_disabled -from 4 [expr [image height $srcimg_disabled] - 2] [expr 4 + 1] [image height $srcimg_disabled] -to 4 [expr $height - 2] [expr $width - 4] $height
		$img_disabled copy $srcimg_disabled -from [expr [image width $srcimg_disabled] - 4] [expr [image height $srcimg_disabled] - 2] [image width $srcimg_disabled] [image height $srcimg_disabled] -to [expr $width - 4] [expr $height - 2]

	}
		
		
	method getOption {option} {
		if { [string equal $option "-bd"] } {
			set option "-borderwidth"
		} elseif { [string equal $option "-fg"] } {
			set option "-foreground"
		} elseif { [string equal $option "-bc"] } {
			set option "-bordercolor"
		}

		return $options($option)
	}

	method changeForeground {option value} {
		#$button configure -foreground $value
		set options(-foreground) $value
	}

	method invoke { } {
		eval $options(-command)
	}

	method getText { option } {
		set value [string range $options(-text) 2 end-2]
		return $value
	}

	method changeText {option value} {
		#$button configure -foreground $value
		set value "  $value  "
		puts "$value"
		set options(-text) $value
	}

}
