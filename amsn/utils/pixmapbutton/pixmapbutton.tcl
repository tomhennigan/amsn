package require snit
package provide pixmapbutton 0.1

snit::widgetadaptor pixmapbutton {
	
	#-------------------
	# Image components
	#-------------------
	variable img
	variable img_hover
	variable img_pressed
	variable img_disabled

	variable leftimg
	variable leftimg_hover
	variable leftimg_pressed
	variable leftimg_disabled

	variable centreimg
	variable centreimg_hover
	variable centreimg_pressed
	variable centreimg_disabled

	variable rightimg
	variable rightimg_hover
	variable rightimg_pressed
	variable rightimg_disabled

	variable topimg
	variable topimg_hover
	variable topimg_pressed
	variable topimg_disabled
	
	variable bottomimg
	variable bottomimg_hover
	variable bottomimg_pressed
	variable bottomimg_disabled
	
	variable srcimg
	variable srcimg_hover
	variable srcimg_pressed
	variable srcimg_disabled
	
	variable border_top
	variable border_left
	variable border_right
	variable border_bottom
	
	variable potent
	variable buttonwidth
	variable buttonheight
	

	component button

	#-------------------------
	# Define options
	#-------------------------
	option -borderwidth -default 0
	option -bd
	option -background -default white
	option -foreground -default black -cgetmethod getOption -configuremethod changeForeground
	option -fg -cgetmethod getOption -configuremethod changeForeground -default black
	option -text -configuremethod changeText -cgetmethod getText
	option -compound -default "center"
	option -font -default "" -configuremethod changeFont
	option -width -configuremethod NewSize
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
	option -default -default "normal" -configuremethod changeDefault
	option -state -default "normal"
	option -emblemimage -default ""
	option -emblempos -default [list right center]
	#-------------------------

	delegate option * to button except {-borderwidth -bd -class -width -height}


	#-------------------------
	# Create the widget
	#-------------------------
	constructor {args} {
		installhull using canvas -bd 0 -highlightthickness 0 -width 80 -height 25
		set button $hull

		$self configurelist $args

		# Setting various variables
		set buttonwidth 0
		set buttonheight 0
		set border_left 6
		set border_top 6
		set border_right 6
		set border_bottom 6
		set state $options(-state)
		set potent "no"

		set img [image create photo -width $buttonwidth -height $buttonheight]
		set leftimg [image create photo -width $border_left -height [expr $buttonheight - $border_top - $border_bottom]]
		set centreimg [image create photo -width [expr $buttonwidth - $border_left - $border_right] -height [expr $buttonheight - $border_top - $border_bottom]]
		set rightimg [image create photo -width $border_right -height [expr $buttonheight - $border_top - $border_bottom]]
		set topimg [image create photo -width [expr $buttonwidth - $border_right] -height $border_top]
		set bottomimg [image create photo -width [expr $buttonwidth - $border_right] -height $border_top]
		set srcimg [::skin::loadPixmap button]


		set img_hover [image create photo -width $buttonwidth -height $buttonheight]
		set leftimg_hover [image create photo -width $border_left -height [expr $buttonheight - $border_top - $border_bottom]]
		set centreimg_hover [image create photo -width [expr $buttonwidth - $border_left - $border_right] -height [expr $buttonheight - $border_top - $border_bottom]]
		set rightimg_hover [image create photo -width $border_right -height [expr $buttonheight - $border_top - $border_bottom]]
		set topimg_hover [image create photo -width [expr $buttonwidth - $border_right] -height $border_top]
		set bottomimg_hover [image create photo -width [expr $buttonwidth - $border_right] -height $border_bottom]
		set srcimg_hover [::skin::loadPixmap button_hover]


		set img_pressed [image create photo -width $buttonwidth -height $buttonheight]
		set leftimg_pressed [image create photo -width $border_left -height [expr $buttonheight - $border_top - $border_bottom]]
		set centreimg_pressed [image create photo -width [expr $buttonwidth - $border_left - $border_right] -height [expr $buttonheight - $border_top - $border_bottom]]
		set rightimg_pressed [image create photo -width $border_right -height [expr $buttonheight - $border_top - $border_bottom]]
		set topimg_pressed [image create photo -width [expr $buttonwidth - $border_right] -height $border_top]
		set bottomimg_pressed [image create photo -width [expr $buttonwidth - $border_right] -height $border_bottom]
		set srcimg_pressed [::skin::loadPixmap button_pressed]


		set img_disabled [image create photo -width $buttonwidth -height $buttonheight]
		set leftimg_disabled [image create photo -width $border_left -height [expr $buttonheight - $border_top - $border_bottom]]
		set centreimg_disabled [image create photo -width [expr $buttonwidth - $border_left - $border_right] -height [expr $buttonheight - $border_top - $border_bottom]]
		set rightimg_disabled [image create photo -width $border_right -height [expr $buttonheight - $border_top - $border_bottom]]
		set topimg_disabled [image create photo -width [expr $buttonwidth - $border_right] -height $border_top]
		set bottomimg_disabled [image create photo -width [expr $buttonwidth - $border_right] -height $border_bottom]
		set srcimg_disabled [::skin::loadPixmap button_disabled]
		
		set emblemimage_disabled [image create photo]
		
		#-------------------------


		#-------------------------
		# Create bindings
		#-------------------------
		#pack $self

		bind $self <Configure> "$self DrawButton %w %h"
		bind $self <B1-Enter> "$self ButtonHovered down"
		bind $self <Enter> "$self ButtonHovered up"
		bind $self <B1-Leave> "$self ButtonUnhovered down"
		bind $self <Leave> "$self ButtonUnhovered up"
		bind $self <Button-1> "$self ButtonPressed"
		bind $self <ButtonRelease-1> "$self ButtonReleased"
		bind $self <KeyPress-Return> "$self ButtonPressed;$self ButtonReleased"
		bind $self <KeyPress-KP_Enter> "$self ButtonPressed;$self ButtonReleased"
		
		#-------------------------

		
		
		$button create image 0 0 -anchor nw -image $img -tag img
		$button create text [expr $buttonwidth / 2] [expr $buttonheight / 2] -anchor c -text $options(-text) -fill $options(-foreground) -tag txt
		
		if { $options(-emblemimage) != "" } {
			$emblemimage_disabled copy $options(-emblemimage) -shrink
			$emblemimage_disabled configure -palette 32
			$button create image 0 0 -anchor nw -image $options(-emblemimage) -disabledimage $emblemimage_disabled -tag emblem
		}
		
		switch $options(-default) {
			"normal" {
				$button create rectangle $border_left $border_top \
				[expr $buttonwidth - $border_right] [expr $buttonheight - $border_bottom] \
				-outline $options(-fg) -dash "1 2" -state hidden -tag ring
			}
			"active" {
				$button create rectangle $border_left $border_top \
				[expr $buttonwidth - $border_right] [expr $buttonheight - $border_bottom] \
				-outline $options(-fg) -dash "1 2" -state normal -tag ring
			}
		}
		
		if { $options(-font) == "" } {
			font create font -family helvetica -size 11 -weight bold
			set $options(-font) "font"
			$self configure -font "font"
			$button itemconfigure txt -font font
		} else {
			$button itemconfigure txt -font $options(-font)
		}

		$self SetSize
		$self BuildImage $buttonwidth $buttonheight
	}

	method ButtonHovered { pressed } {

		if {$options(-state) != "disabled" } {
			if { $pressed == "down" } {
				set potent "yes"
				$button itemconfigure img -image $img_pressed
			} else {
				set potent "no"
				$button itemconfigure img -image $img_hover
			}
		}
	}
	
	method ButtonUnhovered { pressed } {

		if {$options(-state) != "disabled" } {
			$button itemconfigure img -image $img
			if { $pressed == "down" } {
				set potent "maybe"
			} else {
				
			}
		}
	}
	
	method ButtonPressed { } {

		if {$options(-state) != "disabled" } {
			$button itemconfigure img -image $img_pressed
			set potent "yes"
		}
	}
	
	method ButtonReleased { } {
		
		if {$options(-state) != "disabled" } {
			if { $potent == "yes" } {
				$button itemconfigure img -image $img_hover
				set potent "no"
				$self invoke
			} else {
				set potent "no"
				$button itemconfigure img -image $img
			}
		}
	}
	
	method DrawButton { width height } {
		$self SetSize
		$self BuildImage $width $height
		$button coords img 0 0
		set buttonwidth [winfo width $self]
		set buttonheight $height
		
		$button coords ring $border_left $border_top \
				[expr $buttonwidth - $border_right] [expr $buttonheight - $border_bottom]
				
		set txtposx [expr $buttonwidth / 2]
		set txtposy [expr $buttonheight / 2]
		
		if { $options(-emblemimage) != "" } {
			switch [lindex $options(-emblempos) 0] {
				"left" {
					set xpos $border_left
					set txtposx [expr ($buttonwidth + [image width $options(-emblemimage)]) / 2]
				}

				"center" {
					set txtposx [expr $buttonwidth / 2]
					set xpos [expr $width / 2 - ([image width $options(-emblemimage)] / 2)]
					set xpos [lindex [split $xpos .] 0]
				}

				"right" {
					set txtposx [expr ($buttonwidth - [image width $options(-emblemimage)]) / 2]
					set xpos [expr $width - $border_right - ([image width $options(-emblemimage)])]
					set xpos [lindex [split $xpos .] 0]
				}
			}
			switch [lindex $options(-emblempos) 1] {
				"top" {
					set ypos $border_top
				}
				"center" {
					set ypos [expr $height / 2 - ([image height $options(-emblemimage)] / 2)]
					set ypos [lindex [split $ypos .] 0]
				}
				"bottom" {
					set ypos [expr $height - $border_bottom - ([image height $options(-emblemimage)])]
				}
			}
			$button coords emblem $xpos $ypos
			if {$options(-state) == "disabled" } {
				$button itemconfigure emblem -state disabled
			} else {
				$button itemconfigure emblem -state normal
			}
		}
		
		$button coords txt $txtposx $txtposy
		

		switch $options(-state) {
			"normal" { $button itemconfigure img -image $img }
			"active" { $button itemconfigure img -image $img_hover }
			"disabled" { $button itemconfigure img -image $img_disabled }
			default { }
		}
	}
	
	method BuildImage { width height } {

		$img blank
		$img_hover blank
		$img_pressed blank
		$img_disabled blank
		set minwidth [expr 4 * 4]
		set minheight [image height $srcimg]
		
		if { $height < $minheight } { set height $minheight }
		if { $width < $minwidth } { set width $minwidth }

		#---------------------
		# Normal button
		#---------------------
		
		#Resize left section:
		$leftimg configure -width $border_left -height [expr [image height $srcimg] - $border_top - $border_bottom]
		$leftimg blank
		$leftimg copy $srcimg -from 0 $border_top $border_left [expr [image height $srcimg] - $border_bottom] -to 0 0
		::CxImage::Resize $leftimg $border_left [expr $height - $border_top - $border_bottom]
		
		#Resize middle section:
		$centreimg configure -width [expr $width - $border_left - $border_right] -height [expr [image height $srcimg] - $border_top - $border_bottom]
		$centreimg blank
		$centreimg copy $srcimg -from $border_left $border_top [expr [image width $srcimg] - $border_right] [expr [image height $srcimg] - $border_bottom] -to 0 0 [expr $width - $border_left - $border_right] [expr $height - $border_top - $border_bottom]
		::CxImage::Resize $centreimg [expr $width - $border_left - $border_right] [expr $height - $border_top - $border_bottom]

		#Resize right section:
		$rightimg configure -width $border_right -height [expr [image height $srcimg] - $border_top - $border_bottom]
		$rightimg blank
		$rightimg copy $srcimg -from [expr [image width $srcimg] - $border_right] $border_top [image width $srcimg] [expr [image height $srcimg] - $border_bottom] -to 0 0
		::CxImage::Resize $rightimg $border_right [expr $height - $border_top - $border_bottom]
		
		#Resize top section:
		$topimg configure -width [expr [image width $srcimg] - $border_left - $border_right] -height $border_top
		$topimg blank
		$topimg copy $srcimg -from $border_left 0 [expr [image width $srcimg] - $border_right] $border_top
		::CxImage::Resize $topimg [expr $width - $border_left - $border_right] $border_top
		
		#Resize bottom section:
		$bottomimg configure -width [expr [image width $srcimg] - $border_left - $border_right] -height $border_bottom
		$bottomimg blank
		$bottomimg copy $srcimg -from $border_left [expr [image height $srcimg] - $border_bottom] [expr [image width $srcimg] - $border_right] [image height $srcimg]
		::CxImage::Resize $bottomimg [expr $width - $border_left - $border_right] $border_bottom

		#Build up button image:
		$img configure -width $width -height $height
		$img copy $srcimg -from 0 0 $border_left $border_top -to 0 0
		$img copy $topimg -to $border_left 0 [expr $width - $border_right] $border_top
		$img copy $srcimg -from [expr [image width $srcimg] - $border_right] 0 [image width $srcimg] $border_top -to [expr $width - $border_right] 0
		$img copy $leftimg -to 0 $border_top
		$img copy $centreimg -to $border_left $border_top
		$img copy $rightimg -to [expr $width - $border_right] $border_top
		$img copy $srcimg -from 0 [expr [image height $srcimg] - $border_bottom] $border_left [image height $srcimg] -to 0 [expr $height - $border_bottom]
		$img copy $bottomimg -to $border_left [expr [image height $img] - $border_bottom]
		$img copy $srcimg -from [expr [image width $srcimg] - $border_right] [expr [image height $srcimg] - $border_bottom] [image width $srcimg] [image height $srcimg] -to [expr $width - $border_right] [expr $height - $border_bottom]


		#-----------------------------------------------
		# Hovered button
		#-----------------------------------------------
		
		#Resize left section:
		$leftimg_hover configure -width $border_left -height [expr [image height $srcimg_hover] - $border_top - $border_bottom]
		$leftimg_hover blank
		$leftimg_hover copy $srcimg_hover -from 0 $border_top $border_left [expr [image height $srcimg_hover] - $border_bottom] -to 0 0
		::CxImage::Resize $leftimg_hover $border_left [expr $height - $border_top - $border_bottom]
		
		#Resize middle section:
		$centreimg_hover configure -width [expr $width - $border_left - $border_right] -height [expr [image height $srcimg_hover] - $border_top - $border_bottom]
		$centreimg_hover blank
		$centreimg_hover copy $srcimg_hover -from $border_left $border_top [expr [image width $srcimg_hover] - $border_right] [expr [image height $srcimg_hover] - $border_bottom] -to 0 0 [expr $width - $border_left - $border_right] [expr $height - $border_top - $border_bottom]
		::CxImage::Resize $centreimg_hover [expr $width - $border_left - $border_right] [expr $height - $border_top - $border_bottom]

		#Resize right section:
		$rightimg_hover configure -width $border_right -height [expr [image height $srcimg_hover] - $border_top - $border_bottom]
		$rightimg_hover blank
		$rightimg_hover copy $srcimg_hover -from [expr [image width $srcimg_hover] - $border_right] $border_top [image width $srcimg_hover] [expr [image height $srcimg] - $border_bottom] -to 0 0
		::CxImage::Resize $rightimg_hover $border_right [expr $height - $border_top - $border_bottom]
		
		#Resize top section:
		$topimg_hover configure -width [expr [image width $srcimg_hover] - $border_left - $border_right] -height $border_top
		$topimg_hover blank
		$topimg_hover copy $srcimg_hover -from $border_left 0 [expr [image width $srcimg_hover] - $border_right] $border_top
		::CxImage::Resize $topimg_hover [expr $width - $border_left - $border_right] $border_top
		
		#Resize bottom section:
		$bottomimg_hover configure -width [expr [image width $srcimg_hover] - $border_left - $border_right] -height $border_bottom
		$bottomimg_hover blank
		$bottomimg_hover copy $srcimg_hover -from $border_left [expr [image height $srcimg_hover] - $border_bottom] [expr [image width $srcimg_hover] - $border_right] [image height $srcimg_hover]
		::CxImage::Resize $bottomimg_hover [expr $width - $border_left - $border_right] $border_bottom

		#Build up button image:
		$img_hover configure -width $width -height $height
		$img_hover copy $srcimg_hover -from 0 0 $border_left $border_top -to 0 0
		$img_hover copy $topimg_hover -to $border_left 0 [expr $width - $border_right] $border_top
		$img_hover copy $srcimg_hover -from [expr [image width $srcimg_hover] - $border_right] 0 [image width $srcimg_hover] $border_top -to [expr $width - $border_right] 0
		$img_hover copy $leftimg_hover -to 0 $border_top
		$img_hover copy $centreimg_hover -to $border_left $border_top
		$img_hover copy $rightimg_hover -to [expr $width - $border_right] $border_top
		$img_hover copy $srcimg_hover -from 0 [expr [image height $srcimg_hover] - $border_bottom] $border_left [image height $srcimg_hover] -to 0 [expr $height - $border_bottom]
		$img_hover copy $bottomimg_hover -to $border_left [expr [image height $img_hover] - $border_bottom]
		$img_hover copy $srcimg_hover -from [expr [image width $srcimg_hover] - $border_right] [expr [image height $srcimg_hover] - $border_bottom] [image width $srcimg_hover] [image height $srcimg_hover] -to [expr $width - $border_right] [expr $height - $border_bottom]


		#-----------------------------------------------
		# Pressed button
		#-----------------------------------------------
		
		#Resize left section:
		$leftimg_pressed configure -width $border_left -height [expr [image height $srcimg_pressed] - $border_top - $border_bottom]
		$leftimg_pressed blank
		$leftimg_pressed copy $srcimg_pressed -from 0 $border_top $border_left [expr [image height $srcimg_pressed] - $border_bottom] -to 0 0
		::CxImage::Resize $leftimg_pressed $border_left [expr $height - $border_top - $border_bottom]
		
		#Resize middle section:
		$centreimg_pressed configure -width [expr $width - $border_left - $border_right] -height [expr [image height $srcimg_pressed] - $border_top - $border_bottom]
		$centreimg_pressed blank
		$centreimg_pressed copy $srcimg_pressed -from $border_left $border_top [expr [image width $srcimg_pressed] - $border_right] [expr [image height $srcimg_pressed] - $border_bottom] -to 0 0 [expr $width - $border_left - $border_right] [expr $height - $border_top - $border_bottom]
		::CxImage::Resize $centreimg_pressed [expr $width - $border_left - $border_right] [expr $height - $border_top - $border_bottom]

		#Resize right section:
		$rightimg_pressed configure -width $border_right -height [expr [image height $srcimg_pressed] - $border_top - $border_bottom]
		$rightimg_pressed blank
		$rightimg_pressed copy $srcimg_pressed -from [expr [image width $srcimg_pressed] - $border_right] $border_top [image width $srcimg_pressed] [expr [image height $srcimg] - $border_bottom] -to 0 0
		::CxImage::Resize $rightimg_pressed $border_right [expr $height - $border_top - $border_bottom]
		
		#Resize top section:
		$topimg_pressed configure -width [expr [image width $srcimg_pressed] - $border_left - $border_right] -height $border_top
		$topimg_pressed blank
		$topimg_pressed copy $srcimg_pressed -from $border_left 0 [expr [image width $srcimg_pressed] - $border_right] $border_top
		::CxImage::Resize $topimg_pressed [expr $width - $border_left - $border_right] $border_top
		
		#Resize bottom section:
		$bottomimg_pressed configure -width [expr [image width $srcimg_pressed] - $border_left - $border_right] -height $border_bottom
		$bottomimg_pressed blank
		$bottomimg_pressed copy $srcimg_pressed -from $border_left [expr [image height $srcimg_pressed] - $border_bottom] [expr [image width $srcimg_pressed] - $border_right] [image height $srcimg_pressed]
		::CxImage::Resize $bottomimg_pressed [expr $width - $border_left - $border_right] $border_bottom

		#Build up button image:
		$img_pressed configure -width $width -height $height
		$img_pressed copy $srcimg_pressed -from 0 0 $border_left $border_top -to 0 0
		$img_pressed copy $topimg_pressed -to $border_left 0 [expr $width - $border_right] $border_top
		$img_pressed copy $srcimg_pressed -from [expr [image width $srcimg_pressed] - $border_right] 0 [image width $srcimg_pressed] $border_top -to [expr $width - $border_right] 0
		$img_pressed copy $leftimg_pressed -to 0 $border_top
		$img_pressed copy $centreimg_pressed -to $border_left $border_top
		$img_pressed copy $rightimg_pressed -to [expr $width - $border_right] $border_top
		$img_pressed copy $srcimg_pressed -from 0 [expr [image height $srcimg_pressed] - $border_bottom] $border_left [image height $srcimg_pressed] -to 0 [expr $height - $border_bottom]
		$img_pressed copy $bottomimg_pressed -to $border_left [expr [image height $img_pressed] - $border_bottom]
		$img_pressed copy $srcimg_pressed -from [expr [image width $srcimg_pressed] - $border_right] [expr [image height $srcimg_pressed] - $border_bottom] [image width $srcimg_pressed] [image height $srcimg_pressed] -to [expr $width - $border_right] [expr $height - $border_bottom]

		
		#-----------------------------------------------
		# Disabled button
		#-----------------------------------------------

		#Resize left section:
		$leftimg_disabled configure -width $border_left -height [expr [image height $srcimg_disabled] - $border_top - $border_bottom]
		$leftimg_disabled blank
		$leftimg_disabled copy $srcimg_disabled -from 0 $border_top $border_left [expr [image height $srcimg_disabled] - $border_bottom] -to 0 0
		::CxImage::Resize $leftimg_disabled $border_left [expr $height - $border_top - $border_bottom]
		
		#Resize middle section:
		$centreimg_disabled configure -width [expr $width - $border_left - $border_right] -height [expr [image height $srcimg_disabled] - $border_top - $border_bottom]
		$centreimg_disabled blank
		$centreimg_disabled copy $srcimg_disabled -from $border_left $border_top [expr [image width $srcimg_disabled] - $border_right] [expr [image height $srcimg_disabled] - $border_bottom] -to 0 0 [expr $width - $border_left - $border_right] [expr $height - $border_top - $border_bottom]
		::CxImage::Resize $centreimg_disabled [expr $width - $border_left - $border_right] [expr $height - $border_top - $border_bottom]

		#Resize right section:
		$rightimg_disabled configure -width $border_right -height [expr [image height $srcimg_disabled] - $border_top - $border_bottom]
		$rightimg_disabled blank
		$rightimg_disabled copy $srcimg_disabled -from [expr [image width $srcimg_disabled] - $border_right] $border_top [image width $srcimg_disabled] [expr [image height $srcimg] - $border_bottom] -to 0 0
		::CxImage::Resize $rightimg_disabled $border_right [expr $height - $border_top - $border_bottom]
		
		#Resize top section:
		$topimg_disabled configure -width [expr [image width $srcimg_disabled] - $border_left - $border_right] -height $border_top
		$topimg_disabled blank
		$topimg_disabled copy $srcimg_disabled -from $border_left 0 [expr [image width $srcimg_disabled] - $border_right] $border_top
		::CxImage::Resize $topimg_disabled [expr $width - $border_left - $border_right] $border_top
		
		#Resize bottom section:
		$bottomimg_disabled configure -width [expr [image width $srcimg_disabled] - $border_left - $border_right] -height $border_bottom
		$bottomimg_disabled blank
		$bottomimg_disabled copy $srcimg_disabled -from $border_left [expr [image height $srcimg_disabled] - $border_bottom] [expr [image width $srcimg_disabled] - $border_right] [image height $srcimg_disabled]
		::CxImage::Resize $bottomimg_disabled [expr $width - $border_left - $border_right] $border_bottom

		#Build up button image:
		$img_disabled configure -width $width -height $height
		$img_disabled copy $srcimg_disabled -from 0 0 $border_left $border_top -to 0 0
		$img_disabled copy $topimg_disabled -to $border_left 0 [expr $width - $border_right] $border_top
		$img_disabled copy $srcimg_disabled -from [expr [image width $srcimg_disabled] - $border_right] 0 [image width $srcimg_disabled] $border_top -to [expr $width - $border_right] 0
		$img_disabled copy $leftimg_disabled -to 0 $border_top
		$img_disabled copy $centreimg_disabled -to $border_left $border_top
		$img_disabled copy $rightimg_disabled -to [expr $width - $border_right] $border_top
		$img_disabled copy $srcimg_disabled -from 0 [expr [image height $srcimg_disabled] - $border_bottom] $border_left [image height $srcimg_disabled] -to 0 [expr $height - $border_bottom]
		$img_disabled copy $bottomimg_disabled -to $border_left [expr [image height $img_disabled] - $border_bottom]
		$img_disabled copy $srcimg_disabled -from [expr [image width $srcimg_disabled] - $border_right] [expr [image height $srcimg_disabled] - $border_bottom] [image width $srcimg_disabled] [image height $srcimg_disabled] -to [expr $width - $border_right] [expr $height - $border_bottom]
		

	}


	method invoke { } {
		eval $options(-command)
	}
	
	#Todo: implement this feature.
	method flash { }  {
		
	}

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
		
		#If we have a width set by button... set it. else resize to fit text and (optionally) emblem:
		if { $options(-width) != "" } {
			set buttonwidth $options(-width)
		} else {
			#Measure length of button text and add some padding to give width of button:
			set buttonwidth [expr [font measure $options(-font) -displayof $self $options(-text)] \
				+ [font measure $options(-font) -displayof $self "        "]]
			
			#Add extra room for emblem:
			if { $options(-emblemimage) != "" } {
				incr buttonwidth [image width $options(-emblemimage)]
			}
		}
		
		#If we have a height set by button... set it, else set it at the height of the button image, unless the font size is bigger... then set it to that plus the top and bottom border widths:
		if { $options(-height) != "" } {
			set buttonheight $options(-height)
		} else {
			set buttonheight [image height $img]
			if { [font configure $options(-font) -size] > [image height $img] } {
				set height [expr [font configure $options(-font) -size] + $border_top + $border_bottom]
			}
		}
		
		#Configure the button with the new width and height:
		$button configure -width $buttonwidth -height $buttonheight
	}

	method getText { option } {
		return [$button itemcget -text]
	}

	method changeText { option value } {
		set options(-text) $value
		$button itemconfigure txt -text $value
	}
	
	method changeFont { option value } {
		set options(-font) $value
		$button itemconfigure txt -font $value
	}
	
	method changeDefault { option value } {
		set $options(-default) $value
		switch $value {
			"normal" { $button itemconfigure ring -state hidden }
			"active" {
				focus $self
				$button itemconfigure ring -state normal
			}
		}
	}

		method getOption {option} {
		if { [string equal $option "-bd"] } {
			set option "-borderwidth"
		} elseif { [string equal $option "-fg"] } {
			set option "-foreground"
		}
		
		return $options($option)
	}

	method changeForeground { option value } {
		$button itemconfigure txt -fill $value
		set options(-foreground) $value
	}

}
