package require snit
package require TkCximage
package provide pixmapbutton 0.1

snit::widgetadaptor pixmapbutton {
	
	#-------------------
	# Image components
	#-------------------
	component img
	component img_hover
	component img_pressed
	component img_disabled

	component leftimg
	component leftimg_hover
	component leftimg_pressed
	component leftimg_disabled

	component centreimg
	component centreimg_hover
	component centreimg_pressed
	component centreimg_disabled

	component rightimg
	component rightimg_hover
	component rightimg_pressed
	component rightimg_disabled

	component topimg
	component topimg_hover
	component topimg_pressed
	component topimg_disabled
	
	component bottomimg
	component bottomimg_hover
	component bottomimg_pressed
	component bottomimg_disabled
	
	component srcimg
	component srcimg_hover
	component srcimg_pressed
	component srcimg_disabled
	

	component button

	#-------------------------
	# Define options
	#-------------------------
	option -borderwidth -default 0
	option -bd
	option -background -default white
	option -foreground -default black -cgetmethod getOption -configuremethod changeForeground
	option -fg -cgetmethod getOption -configuremethod changeForeground
	option -text -configuremethod changeText -cgetmethod getText
	option -compound -default "center"
	option -font -default "" -configuremethod changeFont
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
		installhull using canvas -bg #ffffff -bd 0 -highlightthickness 0 -width 80 -height 25
		set button $hull

		$self configurelist $args


		# Setting various variables
		global buttonsize
		set buttonsize [list 0 0]
		typevariable potent
		typevariable state
		global potent
		global state
		set state $options(-state)
		set potent "no"

		set img [image create photo -width [lindex $buttonsize 0] -height [lindex $buttonsize 1]]
		set leftimg [image create photo -width 4 -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set centreimg [image create photo -width [expr [lindex $buttonsize 0] - (4 * 2)] -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set rightimg [image create photo -width 4 -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set topimg [image create photo -width [expr [lindex $buttonsize 0] - 4] -height 2]
		set bottomimg [image create photo -width [expr [lindex $buttonsize 0] - 4] -height 2]
		set srcimg [image create photo -file button.gif]

		set img_hover [image create photo -width [lindex $buttonsize 0] -height [lindex $buttonsize 1]]
		set leftimg_hover [image create photo -width 4 -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set centreimg_hover [image create photo -width [expr [lindex $buttonsize 0] - (4 * 2)] -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set rightimg_hover [image create photo -width 4 -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set topimg_hover [image create photo -width [expr [lindex $buttonsize 0] - 4] -height 2]
		set bottomimg_hover [image create photo -width [expr [lindex $buttonsize 0] - 4] -height 2]
		set srcimg_hover [image create photo -file button_hover.gif]


		set img_pressed [image create photo -width [lindex $buttonsize 0] -height [lindex $buttonsize 1]]
		set leftimg_pressed [image create photo -width 4 -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set centreimg_pressed [image create photo -width [expr [lindex $buttonsize 0] - (4 * 2)] -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set rightimg_pressed [image create photo -width 4 -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set topimg_pressed [image create photo -width [expr [lindex $buttonsize 0] - 4] -height 2]
		set bottomimg_pressed [image create photo -width [expr [lindex $buttonsize 0] - 4] -height 2]
		set srcimg_pressed [image create photo -file button_pressed.gif]

		set img_disabled [image create photo -width [lindex $buttonsize 0] -height [lindex $buttonsize 1]]
		set leftimg_disabled [image create photo -width 4 -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set centreimg_disabled [image create photo -width [expr [lindex $buttonsize 0] - (4 * 2)] -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set rightimg_disabled [image create photo -width 4 -height [expr [lindex $buttonsize 1] - (2 * 2)]]
		set topimg_disabled [image create photo -width [expr [lindex $buttonsize 0] - 4] -height 2]
		set bottomimg_disabled [image create photo -width [expr [lindex $buttonsize 0] - 4] -height 2]
		set srcimg_disabled [image create photo -file button_disabled.gif]

		#-------------------------


		#-------------------------
		# Create bindings
		#-------------------------
		#pack $self

		bind $self <Configure> "$self DrawButton %w %h"

		bind $self <Enter> "$self ButtonHovered"
		bind $self <Leave> "$self ButtonUnhovered"
		bind $self <Button-1> "$self ButtonPressed"
		bind $self <ButtonRelease-1> "$self ButtonReleased"
		#-------------------------

		
		
		$button create image 0 0 -anchor nw -image $img -tag img
		$button create text [expr [lindex $buttonsize 0] / 2] [expr [lindex $buttonsize 1] / 2] -anchor c -text $options(-text) -fill $options(-foreground) -tag txt

		if { $options(-font) == "" } {
			font create font -family helvetica -size 11 -weight bold
			set $options(-font) "font"
			$self configure -font "font"
			$button itemconfigure txt -font font
		} else {
			$button itemconfigure txt -font $options(-font)
		}
		
		
		$self SetSize
		$self BuildImage [lindex $buttonsize 0] [lindex $buttonsize 1]
	}

	method ButtonHovered { } {
		global potent
		if {$options(-state) != "disabled" } {
			$button itemconfigure img -image $img_hover
			if { $potent == "no" } { set $potent "yes" }
		}
	}
	
	method ButtonUnhovered { } {
		global potent
		if {$options(-state) != "disabled" } {
			$button itemconfigure img -image $img
			set potent "no"
		}
	}
	
	method ButtonPressed { } {
		global potent
		if {$options(-state) != "disabled" } {
			$button itemconfigure img -image $img_pressed
			set potent "yes"
		}
	}
	
	method ButtonReleased { } {
		global potent
		if {$options(-state) != "disabled" } {
			if { $potent == "yes" } {
				$button itemconfigure img -image $img_hover
				$self invoke
			} elseif { $potent == "no" } {
				$button itemconfigure img -image $img
			} else { }
		}
	}
	
	method DrawButton { width height } {
		variable img
		global buttonsize
		$self SetSize
		$self BuildImage $width $height
		$button coords img 0 0
		set buttonsize [list [winfo width $self] $height]
		
		set txtposx [expr [lindex $buttonsize 0] / 2]
		set txtposy [expr [lindex $buttonsize 1] / 2]
		
		if { $options(-emblemimage) != "" } {
			switch [lindex $options(-emblempos) 0] {
				"left" {
					set txtposx [expr ([lindex $buttonsize 0] + [image width $options(-emblemimage)]) / 2]
				}

				"center" { set txtposx [expr [lindex $buttonsize 0] / 2] }

				"right" {
					set txtposx [expr ([lindex $buttonsize 0] - [image width $options(-emblemimage)]) / 2]
				}
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
		variable img
		$img blank
		set minwidth [expr 4 * 4]
		set minheight [image height $srcimg]
		
		if { $height < $minheight } { set height $minheight }
		if { $width < $minwidth } { set width $minwidth }

		#Resize left section:
		$leftimg configure -width 4 -height [expr [image height $srcimg] - (2 * 2)]
		$leftimg blank
		$leftimg copy $srcimg -from 0 2 4 [expr [image height $srcimg] - 2] -to 0 0
		::CxImage::Resize $leftimg 4 [expr $height - (2 * 2)]
		
		#Resize middle section:
		$centreimg configure -width [expr $width - (2 * 4)] -height [expr [image height $srcimg] - (2 * 2)]
		$centreimg blank
		$centreimg copy $srcimg -from 4 2 [expr [image width $srcimg] - 4] [expr [image height $srcimg] - 2] -to 0 0 [expr $width - (2 * 4)] [expr $height - (2 * 2)]
		::CxImage::Resize $centreimg [expr $width - (2 * 4)] [expr $height - (2 * 2)]

		#Resize right section:
		$rightimg configure -width 4 -height [expr [image height $srcimg] - (2 * 2)]
		$rightimg blank
		$rightimg copy $srcimg -from [expr [image width $srcimg] - 4] 2 [image width $srcimg] [expr [image height $srcimg] - 2] -to 0 0
		::CxImage::Resize $rightimg 4 [expr $height - (2 * 2)]
		
		#Resize top section:
		$topimg configure -width [expr [image width $srcimg] - (2 * 4)] -height 2
		$topimg blank
		$topimg copy $srcimg -from 4 0 [expr [image width $srcimg] - 4] 2
		::CxImage::Resize $topimg [expr $width - (4 * 2)] 2
		
		#Resize bottom section:
		$bottomimg configure -width [expr [image width $srcimg] - (2 * 4)] -height 2
		$bottomimg blank
		$bottomimg copy $srcimg -from 4 [expr [image height $srcimg] - 2] [expr [image width $srcimg] - 4] [image height $srcimg]
		::CxImage::Resize $bottomimg [expr $width - (4 * 2)] 2

		#Build up button image:
		$img configure -width $width -height $height
		$img copy $srcimg -from 0 0 4 2 -to 0 0
		$img copy $topimg -to 4 0 [expr $width - 4] 2
		$img copy $srcimg -from [expr [image width $srcimg] - 4] 0 [image width $srcimg] 2 -to [expr $width - 4] 0
		$img copy $leftimg -to 0 2
		$img copy $centreimg -to 4 2
		$img copy $rightimg -to [expr $width - 4] 2
		$img copy $srcimg -from 0 [expr [image height $srcimg] - 2] 4 [image height $srcimg] -to 0 [expr $height - 2]
		$img copy $bottomimg -to 4 [expr [image height $img] - 2]
		$img copy $srcimg -from [expr [image width $srcimg] - 4] [expr [image height $srcimg] - 2] [image width $srcimg] [image height $srcimg] -to [expr $width - 4] [expr $height - 2]
		
		#Add emblem (also calculate position for this and other states emblem)
		if { $options(-emblemimage) != "" } {
			switch [lindex $options(-emblempos) 0] {
				"left" {
					set xpos 4
				}
				"center" {
					set xpos [expr $width / 2 - ([image width $options(-emblemimage)] / 2)]
					set xpos [lindex [split $xpos .] 0]
				}
				"right" {
					set xpos [expr $width - 4 - ([image width $options(-emblemimage)])]
					set xpos [lindex [split $xpos .] 0]
				}
			}

			switch [lindex $options(-emblempos) 1] {
				"top" {
					set ypos 2
				}
				"center" {
					set ypos [expr $height / 2 - ([image height $options(-emblemimage)] / 2)]
					set ypos [lindex [split $ypos .] 0]
				}
				"bottom" {
					set ypos [expr $height - 2 - ([image height $options(-emblemimage)])]
					#set ypos [lindex [split $ypos .] 0]
				}
			}

			$img copy $options(-emblemimage) -to $xpos $ypos
		}

		
		#Resize left section:
		$leftimg_hover configure -width 4 -height [expr [image height $srcimg_hover] - (2 * 2)]
		$leftimg_hover blank
		$leftimg_hover copy $srcimg_hover -from 0 2 4 [expr [image height $srcimg_hover] - 2] -to 0 0
		::CxImage::Resize $leftimg_hover 4 [expr $height - (2 * 2)]
		
		#Resize middle section:
		$centreimg_hover configure -width [expr $width - (2 * 4)] -height [expr [image height $srcimg_hover] - (2 * 2)]
		$centreimg_hover blank
		$centreimg_hover copy $srcimg_hover -from 4 2 [expr [image width $srcimg_hover] - 4] [expr [image height $srcimg_hover] - 2] -to 0 0 [expr $width - (2 * 4)] [expr $height - (2 * 2)]
		::CxImage::Resize $centreimg_hover [expr $width - (2 * 4)] [expr $height - (2 * 2)]

		#Resize right section:
		$rightimg_hover configure -width 4 -height [expr [image height $srcimg_hover] - (2 * 2)]
		$rightimg_hover blank
		$rightimg_hover copy $srcimg_hover -from [expr [image width $srcimg_hover] - 4] 2 [image width $srcimg_hover] [expr [image height $srcimg_hover] - 2] -to 0 0
		::CxImage::Resize $rightimg_hover 4 [expr $height - (2 * 2)]
		
		#Resize top section:
		$topimg_hover configure -width [expr [image width $srcimg_hover] - (2 * 4)] -height 2
		$topimg_hover blank
		$topimg_hover copy $srcimg_hover -from 4 0 [expr [image width $srcimg_hover] - 4] 2
		::CxImage::Resize $topimg_hover [expr $width - (4 * 2)] 2
		
		#Resize bottom section:
		$bottomimg_hover configure -width [expr [image width $srcimg_hover] - (2 * 4)] -height 2
		$bottomimg_hover blank
		$bottomimg_hover copy $srcimg_hover -from 4 [expr [image height $srcimg_hover] - 2] [expr [image width $srcimg_hover] - 4] [image height $srcimg_hover]
		::CxImage::Resize $bottomimg_hover [expr $width - (4 * 2)] 2

		#Build up button image:
		$img configure -width $width -height $height
		$img_hover copy $srcimg_hover -from 0 0 4 2 -to 0 0
		$img_hover copy $topimg_hover -to 4 0 [expr $width - 4] 2
		$img_hover copy $srcimg_hover -from [expr [image width $srcimg_hover] - 4] 0 [image width $srcimg_hover] 2 -to [expr $width - 4] 0
		$img_hover copy $leftimg_hover -to 0 2 4 [expr $height - 2]
		$img_hover copy $centreimg_hover -to 4 2 [expr $width - 4] [expr $height - 2]
		$img_hover copy $rightimg_hover -to [expr $width - 4] 2 $width [expr $height - 2]
		$img_hover copy $srcimg_hover -from 0 [expr [image height $srcimg_hover] - 2] 4 [image height $srcimg_hover] -to 0 [expr $height - 2]
		$img_hover copy $bottomimg_hover -to 4 [expr [image height $img_hover] - 2]
		$img_hover copy $srcimg_hover -from [expr [image width $srcimg_hover] - 4] [expr [image height $srcimg_hover] - 2] [image width $srcimg_hover] [image height $srcimg_hover] -to [expr $width - 4] [expr $height - 2]

		#Add emblem
		if { $options(-emblemimage) != "" } {
			$img_hover copy $options(-emblemimage) -to $xpos $ypos
		}
		
		
		#Resize left section:
		$leftimg_pressed configure -width 4 -height [expr [image height $srcimg_pressed] - (2 * 2)]
		$leftimg_pressed blank
		$leftimg_pressed copy $srcimg_pressed -from 0 2 4 [expr [image height $srcimg_pressed] - 2] -to 0 0
		::CxImage::Resize $leftimg_pressed 4 [expr $height - (2 * 2)]
		
		#Resize middle section:
		$centreimg_pressed configure -width [expr $width - (2 * 4)] -height [expr [image height $srcimg_pressed] - (2 * 2)]
		$centreimg_pressed blank
		$centreimg_pressed copy $srcimg_pressed -from 4 2 [expr [image width $srcimg_pressed] - 4] [expr [image height $srcimg_pressed] - 2] -to 0 0 [expr $width - (2 * 4)] [expr $height - (2 * 2)]
		::CxImage::Resize $centreimg_pressed [expr $width - (2 * 4)] [expr $height - (2 * 2)]

		#Resize right section:
		$rightimg_pressed configure -width 4 -height [expr [image height $srcimg_pressed] - (2 * 2)]
		$rightimg_pressed blank
		$rightimg_pressed copy $srcimg_pressed -from [expr [image width $srcimg_pressed] - 4] 2 [image width $srcimg_pressed] [expr [image height $srcimg_pressed] - 2] -to 0 0
		::CxImage::Resize $rightimg_pressed 4 [expr $height - (2 * 2)]
		
		#Resize top section:
		$topimg_pressed configure -width [expr [image width $srcimg_pressed] - (2 * 4)] -height 2
		$topimg_pressed blank
		$topimg_pressed copy $srcimg_pressed -from 4 0 [expr [image width $srcimg_pressed] - 4] 2
		::CxImage::Resize $topimg_pressed [expr $width - (4 * 2)] 2
		
		#Resize bottom section:
		$bottomimg_pressed configure -width [expr [image width $srcimg_pressed] - (2 * 4)] -height 2
		$bottomimg_pressed blank
		$bottomimg_pressed copy $srcimg_pressed -from 4 [expr [image height $srcimg_pressed] - 2] [expr [image width $srcimg_pressed] - 4] [image height $srcimg_pressed]
		::CxImage::Resize $bottomimg_pressed [expr $width - (4 * 2)] 2

		#Build up button image:
		$img configure -width $width -height $height
		$img_pressed copy $srcimg_pressed -from 0 0 4 2 -to 0 0
		$img_pressed copy $topimg_pressed -to 4 0 [expr $width - 4] 2
		$img_pressed copy $srcimg_pressed -from [expr [image width $srcimg_pressed] - 4] 0 [image width $srcimg_pressed] 2 -to [expr $width - 4] 0
		$img_pressed copy $leftimg_pressed -to 0 2 4 [expr $height - 2]
		$img_pressed copy $centreimg_pressed -to 4 2 [expr $width - 4] [expr $height - 2]
		$img_pressed copy $rightimg_pressed -to [expr $width - 4] 2 $width [expr $height - 2]
		$img_pressed copy $srcimg_pressed -from 0 [expr [image height $srcimg_pressed] - 2] 4 [image height $srcimg_pressed] -to 0 [expr $height - 2]
		$img_pressed copy $bottomimg_pressed -to 4 [expr [image height $img_pressed] - 2]
		$img_pressed copy $srcimg_pressed -from [expr [image width $srcimg_pressed] - 4] [expr [image height $srcimg_pressed] - 2] [image width $srcimg_pressed] [image height $srcimg_pressed] -to [expr $width - 4] [expr $height - 2]
		
		#Add emblem
		if { $options(-emblemimage) != "" } {
			$img_pressed copy $options(-emblemimage) -to $xpos $ypos
		}


		#Resize left section:
		$leftimg_disabled configure -width 4 -height [expr [image height $srcimg_disabled] - (2 * 2)]
		$leftimg_disabled blank
		$leftimg_disabled copy $srcimg_disabled -from 0 2 4 [expr [image height $srcimg_disabled] - 2] -to 0 0
		::CxImage::Resize $leftimg_disabled 4 [expr $height - (2 * 2)]
		
		#Resize middle section:
		$centreimg_disabled configure -width [expr $width - (2 * 4)] -height [expr [image height $srcimg_disabled] - (2 * 2)]
		$centreimg_disabled blank
		$centreimg_disabled copy $srcimg_disabled -from 4 2 [expr [image width $srcimg_disabled] - 4] [expr [image height $srcimg_disabled] - 2] -to 0 0 [expr $width - (2 * 4)] [expr $height - (2 * 2)]
		::CxImage::Resize $centreimg_disabled [expr $width - (2 * 4)] [expr $height - (2 * 2)]

		#Resize right section:
		$rightimg_disabled configure -width 4 -height [expr [image height $srcimg_disabled] - (2 * 2)]
		$rightimg_disabled blank
		$rightimg_disabled copy $srcimg_disabled -from [expr [image width $srcimg_disabled] - 4] 2 [image width $srcimg_disabled] [expr [image height $srcimg_disabled] - 2] -to 0 0
		::CxImage::Resize $rightimg_disabled 4 [expr $height - (2 * 2)]
		
		#Resize top section:
		$topimg_disabled configure -width [expr [image width $srcimg_disabled] - (2 * 4)] -height 2
		$topimg_disabled blank
		$topimg_disabled copy $srcimg_disabled -from 4 0 [expr [image width $srcimg_disabled] - 4] 2
		::CxImage::Resize $topimg_disabled [expr $width - (4 * 2)] 2
		
		#Resize bottom section:
		$bottomimg_disabled configure -width [expr [image width $srcimg_disabled] - (2 * 4)] -height 2
		$bottomimg_disabled blank
		$bottomimg_disabled copy $srcimg_disabled -from 4 [expr [image height $srcimg_disabled] - 2] [expr [image width $srcimg_disabled] - 4] [image height $srcimg_disabled]
		::CxImage::Resize $bottomimg_disabled [expr $width - (4 * 2)] 2

		#Build up button image:
		$img configure -width $width -height $height
		$img_disabled copy $srcimg_disabled -from 0 0 4 2 -to 0 0
		$img_disabled copy $topimg_disabled -to 4 0 [expr $width - 4] 2
		$img_disabled copy $srcimg_disabled -from [expr [image width $srcimg_disabled] - 4] 0 [image width $srcimg_disabled] 2 -to [expr $width - 4] 0
		$img_disabled copy $leftimg_disabled -to 0 2 4 [expr $height - 2]
		$img_disabled copy $centreimg_disabled -to 4 2 [expr $width - 4] [expr $height - 2]
		$img_disabled copy $rightimg_disabled -to [expr $width - 4] 2 $width [expr $height - 2]
		$img_disabled copy $srcimg_disabled -from 0 [expr [image height $srcimg_disabled] - 2] 4 [image height $srcimg_disabled] -to 0 [expr $height - 2]
		$img_disabled copy $bottomimg_disabled -to 4 [expr [image height $img_disabled] - 2]
		$img_disabled copy $srcimg_disabled -from [expr [image width $srcimg_disabled] - 4] [expr [image height $srcimg_disabled] - 2] [image width $srcimg_disabled] [image height $srcimg_disabled] -to [expr $width - 4] [expr $height - 2]
		
		#Add emblem
		if { $options(-emblemimage) != "" } {
			$img_disabled copy $options(-emblemimage) -to $xpos $ypos
		}

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
		puts boo
		$button itemconfigure txt -fill $value
		set options(-foreground) $value
	}

	method invoke { } {
		eval $options(-command)
	}

	method SetSize { } {
		global buttonsize
		set width [expr [font measure $options(-font) -displayof $self $options(-text)] + [font measure $options(-font) -displayof $self "    "]]
		set height [image height $img]
		if { [font configure $options(-font) -size] > [image height $img] } { set height [expr [font configure $options(-font) -size] + (2 * 2)] }
		if { $options(-emblemimage) != "" } {
			incr width [image width $options(-emblemimage)]
		}
		
		set buttonsize "$width $height"
		
		$button configure -width $width -height $height
	}

	method getText { option } {
		return [$button itemcget -text]
	}

	method changeText {option value} {
		set options(-text) $value
		$button itemconfigure txt -text $value
	}
	
	method changeFont {option value} {
		set options(-font) $value
		$button itemconfigure txt -font $value
	}

	#Todo: implement this feature.
	method flash { }  {
		
	}
}
