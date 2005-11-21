##################################################
#  This plugin implements  ...                   #
#  (c) Karel Demeyer, 2005                       #
#  ============================================  #
##################################################


##############################
# ::camshoot                 #
#  All camshoot related code #
##############################
namespace eval ::camshoot {



	################################################
	# Init( dir )                                  #
	#  Registration & initialization of the plugin #
	################################################
	proc Init { dir } {
		::plugins::RegisterPlugin "Cam Shooter"

		#Register the events to the plugin system
		::plugins::RegisterEvent "Cam Shooter" xtra_choosepic_buttons CreateShootButton
	}



	proc CreateShootButton { event evpar } {
		upvar 2 $evpar newvar

		button $newvar(win).webcam -command "::camshoot::webcampicture" -text "[trans webcamshot]"
		grid $newvar(win).webcam -row 4 -column 3 -padx 3 -pady 3 -stick new
	
	
	}
	
	#Create .webcampicture window
	#With that window we can get a picture from our webcam and use it as a display picture
	#Actually only compatible with QuickTimeTcl, but support for TkVideo could be added
	proc webcampicture {} {
		if { ! [info exists ::capture_loaded] } { ::CAMGUI::CaptureLoaded }
		if { ! $::capture_loaded } { return }

		set source [::config::getKey "webcamDevice" "0"]
		set window .dp_preview

		if { [set ::tcl_platform(platform)] == "windows" } {
			if { [winfo exists $window] } {
				raise $window
				return
			}

			set grabber .dpgrabber
			set grabber [tkvideo $grabber]
			if { [catch {$grabber configure -source $source}] } {
				msg_box "[trans badwebcam]"
				destroy $grabber
				return
			}
			$grabber start

			set img [image create photo]
			toplevel $window
			wm title $window "[trans webcamshot]"
			label $window.l -image $img
			pack $window.l
			button $window.settings -command "::CAMGUI::ShowPropertiesPage $grabber $img" -text "[trans changevideosettings]"
			pack $window.settings -expand true -fill x
			button $window.shot -text "[trans takesnapshot]" -command "::camshoot::webcampicture_shot $window"
			pack $window.shot -expand true -fill x
			bind $window <Destroy> "destroy $grabber"
			after 0 "::CAMGUI::PreviewWindows $grabber $img"

		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			#Add grabber to the window
			set w .grabber
			if {![::CAMGUI::CreateGrabberWindowMac]} {
				return
			}

			#Action button to take the picture
			if {![winfo exists $w.shot]} {
				button $w.shot -text "[trans takesnapshot]" -command "::camshoot::webcampicture_shot $w"
				pack $w.shot
			}

		} elseif { [set ::tcl_platform(os)] == "Linux" } {
			if { [winfo exists $window] } {
				raise $window
				return
			}

			if {$source == "0" } { 
				set source "/dev/video0:0"
			}
			set pos [string last ":" $source]
			set dev [string range $source 0 [expr $pos-1]]
			set channel [string range $source [expr $pos+1] end]

			
			if { [catch {set grabber [::Capture::Open $dev $channel]}] } {
				msg_box "[trans badwebcam]"
				return
			}
			
			if { ![info exists ::webcam_settings_bug] || $::webcam_settings_bug == 0} {
				set init_b [::Capture::GetBrightness $grabber]
				set init_c [::Capture::GetContrast $grabber]
				set init_h [::Capture::GetHue $grabber]
				set init_co [::Capture::GetColour $grabber]
				
				set settings [::config::getKey "webcam$dev:$channel" "$init_b:$init_c:$init_h:$init_co"]
				set settings [split $settings ":"]
				set init_b [lindex $settings 0]
				set init_c [lindex $settings 1]
				set init_h [lindex $settings 2]
				set init_co [lindex $settings 3]
			
				::Capture::SetBrightness $grabber $init_b
				::Capture::SetContrast $grabber $init_c
				::Capture::SetHue $grabber $init_h
				::Capture::SetColour $grabber $init_co
			}

			set img [image create photo]
			toplevel $window
			wm title $window "[trans webcamshot]"
			label $window.l -image $img
			pack $window.l
			button $window.settings -command "::CAMGUI::ShowPropertiesPage $grabber $img" -text "[trans changevideosettings]"
			pack $window.settings -expand true -fill x
			button $window.shot -text "[trans takesnapshot]" -command "::camshoot::webcampicture_shot $window"
			pack $window.shot -expand true -fill x
			bind $window <Destroy> "catch {::Capture::Close $grabber}"
			after 0 "::CAMGUI::PreviewLinux $grabber $img"

		}
	}

	#Create the window to accept or refuse the photo
	proc webcampicture_shot {window} {

		set w .webcampicturedoyoulikeit

		if { [winfo exists $w] } {
			destroy $w
		}
		toplevel $w

		set preview [image create photo]
		if { [set ::tcl_platform(platform)] == "windows" } {
			$preview copy [$window.l cget -image]
		} elseif { [set ::tcl_platform(os)] == "Darwin" } {
			.grabber.seq picture $preview
		} elseif { [set ::tcl_platform(os)] == "Linux" } {
			$preview copy [$window.l cget -image]
		}



		#Create upper informational frame
		set up $w.infotext
		frame $up
		label $up.label -text "[trans cutimagebox]"  -font sboldf
		pack $up.label
		

		#create middle frame
		set mid $w.mid
		frame $mid


		#create picture (middle-left)
		canvas $mid.stillpreview
		$mid.stillpreview create image 0 0 -anchor nw -image $preview
		::PrintBox::Create $mid.stillpreview


		#create the frame where the buttons are to resize the selection box (middle-right)
		frame $mid.resel -class Degt
		button $mid.resel.huge -text "[trans huge]" -command "set ::PrintBox::xy {0 0 192 192}; ::PrintBox::Resize $w.mid.stillpreview"
		button $mid.resel.large -text "[trans large]" -command "set ::PrintBox::xy {0 0 128 128}; ::PrintBox::Resize $w.mid.stillpreview"
		button $mid.resel.default -text "[trans default2]" -command "set ::PrintBox::xy {0 0 96 96}; ::PrintBox::Resize $w.mid.stillpreview"
		button $mid.resel.small -text "[trans small]" -command "set ::PrintBox::xy {0 0 64 64}; ::PrintBox::Resize $w.mid.stillpreview"
		label $mid.resel.text -text "[trans cutimageboxreset]"
		
		pack $mid.resel.text $mid.resel.small $mid.resel.default $mid.resel.large $mid.resel.huge -side top -pady 3

		pack $mid.stillpreview $mid.resel -side left -fill y


		#create lower frame
		set low $w.lowerframe
		frame $low 
		button $low.use -text "[trans useasdp]" -command "::camshoot::webcampicture_save $w $preview"
		button $low.saveas -text "[trans saveas]" -command "::camshoot::webcampicture_saveas $w $preview"
		button $low.cancel -text "[trans cancel]" -command "destroy $w"
		pack $low.use $low.saveas $low.cancel -side right -padx 5


		#pack everything in the window
		pack $up $mid $low -side top -fill both



		bind $w <Destroy> "destroy $preview"


		wm title $w "[trans changedisplaypic]"
		moveinscreen $w 30
		after 0 "$w.mid.resel.default invoke"

	}
	#Use the picture as a display picture
	proc webcampicture_save {w image} {
		global HOME selected_image

		set preview [image create photo]
		foreach {x0 y0 x1 y1} [::PrintBox::Done $w.mid.stillpreview] break
		if {$x1 > [image width $image]} { set x1 [image width $image]}
		if {$y1 > [image height $image]} { set y1 [image height $image]}
		$preview copy $image -from [expr int($x0)] [expr int($y0)] [expr int($x1)] [expr int($y1)]

		set idx 1
		while { [file exists [file join $HOME displaypic webcam$idx.png]] } { incr idx }
		set file "[file join $HOME displaypic webcam$idx.png]"

		#We first save it in PNG
		if {[catch {::picture::Save $preview $file cxpng} res]} {
			msg_box $res
		}
		destroy $preview
		destroy $w

		#Open pictureBrowser if user closed it
		if {![winfo exists .picbrowser]} {
			pictureBrowser
		}
		
		#Set image_name
		set image_name [image create photo -file [::skin::GetSkinFile displaypic $file] -format cximage]
		#Change picture in .mypic frame of .picbrowser
		.picbrowser.mypic configure -image $image_name

		#Set selected_image global variable
		set selected_image "[filenoext [file tail $file]].png"

		#Write inside .dat file
		set desc_file "[filenoext [file tail $file]].dat"
		set fd [open [file join $HOME displaypic $desc_file] w]
		#status_log "Writing description to $desc_file\n"
		puts $fd "[clock format [clock seconds] -format %x]\n[filenoext [file tail $file]].png"
		close $fd


		lappend image_names $image_name
		#status_log "Created $image_name\n"
		destroy .webcampicturedoyoulikeit
		raise .picbrowser

#		reloadAvailablePics
	}

	#Save the display picture somewhere on the hard disk
	proc webcampicture_saveas {w image} {
		set idx 1
		while { [file exists [file join $::files_dir webcam{$idx}.jpg]] } { incr idx }
		set file "webcam${idx}.jpg"
		if {[catch {set filename [tk_getSaveFile -initialfile $file -initialdir [set ::files_dir]]} res]} {
			status_log "Error in webcampicture_saveas: $res \n"
			set filename [tk_getSaveFile -initialfile $file -initialdir [set ::HOME]]
		}

		set preview [image create photo]
		foreach {x0 y0 x1 y1} [::PrintBox::Done $w.mid.stillpreview] break
		if {$x1 > [image width $image]} { set x1 [image width $image]}
		if {$y1 > [image height $image]} { set y1 [image height $image]}
		$preview copy $image -from [expr int($x0)] [expr int($y0)] [expr int($x1)] [expr int($y1)]

		if {$filename != ""} {
			if {[catch {::picture::Save $preview $filename cxjpg} res]} {
				msg_box $res
			}
		}

		destroy $preview
		destroy $w

	}






#END OF PLUGIN'S OWN CODE, CLOSE "namespace" BRACKET
}




#PrintBox to select the area of the cam to set as DP : got from wiki.tcl.tk
namespace eval ::PrintBox {
	variable xy {}                              ;# Coordinates of print box
	variable CURSORS                            ;# Cursors to use while resizing
	variable bxy {}                             ;# Button down location
	variable bdown 0                            ;# Button is down flag
	variable minSize 64                        ;# Minimum size of print box
	variable grabSize 1                        ;# Size of "grab" area
	variable debug 0
	
	if {$::tcl_platform(platform) == "windows"} {
		array set CURSORS {
		L size_we      R size_we
		B size_ns      T size_ns
		TL size_nw_se  BR size_nw_se
		TR size_ne_sw  BL size_ne_sw
		}
	} else {
		array set CURSORS {
		L sb_h_double_arrow      R sb_h_double_arrow
		B sb_v_double_arrow      T sb_v_double_arrow
		TL top_left_corner       BR bottom_right_corner
		TR top_right_corner      BL bottom_left_corner
		}
	}

	##+##########################################################################
	#
	# ::PrintBox::Create -- creates the print box on top of canvas W
	#
	proc Create {W} {
		variable xy
		variable CURSORS
		variable bdown 0
		
		# Get initial location
		set w [winfo width $W]
		set h [winfo height $W]
		
		set x0 [$W canvasx 0]
		set y0 [$W canvasy 0]
		set x1 [expr {int($x0 + $w - $w / 8)}]
		set y1 [expr {int($y0 + $h - $h / 8)}]
		set x0 [expr {int($x0 + $w / 8)}]
		set y0 [expr {int($y0 + $h / 8)}]
		set xy [list $x0 $y0 $x1 $y1]
		
		# Create stubs items that ::PrintBox::Resize will size correctly
		$W delete pBox
#		$W create line 0 0 1 1 -tag {pBox diag1} -width 2 -fill red
#		$W create line 0 1 1 $y0 -tag {pBox diag2} -width 2 -fill red
		$W create rect 0 0 1 1 -tag {pBox pBoxx} -width 1 -outline red \
			-fill gray -stipple gray25
		$W bind pBoxx <Enter> [list $W config -cursor hand2]
		$W bind pBoxx <ButtonPress-1> [list ::PrintBox::PBDown $W box %x %y]
		$W bind pBoxx <B1-Motion> [list ::PrintBox::PBMotion $W box %x %y]
		
		foreach {color1 color2} {{} {}} break
		if {$::PrintBox::debug} {
			foreach {color1 color2} {yellow blue} break
		}
		
		# Hidden rectangles that we bind to for resizing
		$W create rect 0 0 0 1 -fill $color1 -stipple gray25 -width 0 -tag {pBox L}
		$W create rect 1 0 1 1 -fill $color1 -stipple gray25 -width 0 -tag {pBox R}
		$W create rect 0 0 1 0 -fill $color1 -stipple gray25 -width 0 -tag {pBox T}
		$W create rect 0 1 1 1 -fill $color1 -stipple gray25 -width 0 -tag {pBox B}
		$W create rect 0 0 0 0 -fill $color2 -stipple gray25 -width 0 -tag {pBox TL}
		$W create rect 1 0 1 0 -fill $color2 -stipple gray25 -width 0 -tag {pBox TR}
		$W create rect 0 1 0 1 -fill $color2 -stipple gray25 -width 0 -tag {pBox BL}
		$W create rect 1 1 1 1 -fill $color2 -stipple gray25 -width 0 -tag {pBox BR}
		
		foreach tag [array names CURSORS] {
			$W bind $tag <Enter> [list ::PrintBox::PBEnter $W $tag]
			$W bind $tag <Leave> [list ::PrintBox::PBLeave $W $tag]
			$W bind $tag <B1-Motion> [list ::PrintBox::PBMotion $W $tag %x %y]
			$W bind $tag <ButtonRelease-1> [list ::PrintBox::PBUp $W $tag]
			$W bind $tag <ButtonPress-1> [list ::PrintBox::PBDown $W $tag %x %y]
		}
		
		::PrintBox::Resize $W
	}
	##+##########################################################################
	#
	# ::PrintBox::Done -- kills the print box and returns its coordinates
	#
	proc Done {W} {
		variable xy
		$W delete pBox
		return $xy
	}
	##+##########################################################################
	#
	# ::PrintBox::Resize -- resizes the print box to ::PrintBox::xy size
	#
	proc Resize {W} {
		variable xy
		variable grabSize
		
		foreach {x0 y0 x1 y1} $xy break
		$W coords pBoxx $x0 $y0 $x1 $y1
		$W coords diag1 $x0 $y0 $x1 $y1
		$W coords diag2 $x1 $y0 $x0 $y1
		
		set w1 [$W itemcget pBoxx -width]           ;# NB. width extends outward
		set w2 [expr {-1 * ($w1 + $grabSize)}]
		
		foreach {x0 y0 x1 y1} [::PrintBox::GrowBox $x0 $y0 $x1 $y1 $w1] break
		foreach {x0_ y0_ x1_ y1_} [::PrintBox::GrowBox $x0 $y0 $x1 $y1 $w2] break
		$W coords L $x0 $y0_ $x0_ $y1_
		$W coords R $x1 $y0_ $x1_ $y1_
		$W coords T $x0_ $y0 $x1_ $y0_
		$W coords B $x0_ $y1 $x1_ $y1_
		$W coords TL $x0 $y0 $x0_ $y0_
		$W coords TR $x1 $y0 $x1_ $y0_
		$W coords BL $x0 $y1 $x0_ $y1_
		$W coords BR $x1 $y1 $x1_ $y1_
	}
	##+##########################################################################
	#
	# ::PrintBox::GrowBox -- grows (or shrinks) rectangle coordinates
	#
	proc GrowBox {x0 y0 x1 y1 d} {
		list [expr {$x0-$d}] [expr {$y0-$d}] [expr {$x1+$d}] [expr {$y1+$d}]
	}
	##+##########################################################################
	#
	# ::PrintBox::PBDown -- handles button down in a print box
	#
	proc PBDown {W tag x y} {
		variable bxy [list $x $y]
		variable bdown 1
	}
	##+##########################################################################
	#
	# ::PrintBox::PBUp -- handles button up in a print box
	#
	proc PBUp {W tag} {
		variable bdown 0
	}
	##+##########################################################################
	#
	# ::PrintBox::PBEnter -- handles <Enter> in a print box
	#
	proc PBEnter {W tag} {
		$W config -cursor $::PrintBox::CURSORS($tag)
	}
	##+##########################################################################
	#
	# ::PrintBox::PBLeave -- handles <Leave> in a print box
	#
	proc PBLeave {W tag} {
		variable bdown
		if {! $bdown} {
			$W config -cursor {}
		}
	}
	##+##########################################################################
	#
	# ::PrintBox::PBMotion -- handles button motion, moving or resizing as needed
	#
	proc PBMotion {W tag x y} {
		variable bxy
		variable xy
		variable minSize
		
		foreach {x0 y0 x1 y1} $xy break
		foreach {dx dy} $bxy break
		set dx [expr {$x - $dx}]
		set dy [expr {$y - $dy}]
		
		set w [winfo width $W]
		set h [winfo height $W]
		set wx0 [$W canvasx 0]
		set wy0 [$W canvasy 0]
		set wx1 [$W canvasx $w]
		set wy1 [$W canvasy $h]
		
		if {$tag eq "box"} {                        ;# Move the print box
			if {$x0 + $dx < $wx0} {set dx [expr {$wx0 - $x0}]}
			if {$x1 + $dx > $wx1} {set dx [expr {$wx1 - $x1}]}
			if {$y0 + $dy < $wy0} {set dy [expr {$wy0 - $y0}]}
			if {$y1 + $dy > $wy1} {set dy [expr {$wy1 - $y1}]}
		
			set x0 [expr {$x0 + $dx}]
			set x1 [expr {$x1 + $dx}]
			set y0 [expr {$y0 + $dy}]
			set y1 [expr {$y1 + $dy}]
		
			set xy [list $x0 $y0 $x1 $y1]
			set bxy [list $x $y]
		} else {                                    ;# Resize the print box
			if {$tag eq "L" || $tag eq "TL" || $tag eq "BL"} {
				set x0_ [expr {$x0 + $dx}]
				if {$x0_ < $wx0} {
					lset xy 0 $wx0
					lset bxy 0 0
				} elseif {$x1 - $x0_ >= $minSize} {
					lset xy 0 $x0_
					lset bxy 0 $x
				}
			}
			if {$tag eq "R" || $tag eq "TR" || $tag eq "BR"} {
				set x1_ [expr {$x1 + $dx}]
				if {$x1_ > $wx1} {
					lset xy 2 $wx1
					lset bxy 0 $w
				} elseif {$x1_ - $x0 >= $minSize} {
					lset xy 2 $x1_
					lset bxy 0 $x
				}
			}
			if {$tag eq "T" || $tag eq "TR" || $tag eq "TL"} {
				set y0_ [expr {$y0 + $dy}]
				if {$y0_ < $wy0} {
					lset xy 1 $wy0
					lset bxy 1 0
				} elseif {$y1 - $y0_ >= $minSize} {
					lset xy 1 $y0_
					lset bxy 1 $y
				}
			}
			if {$tag eq "B" || $tag eq "BR" || $tag eq "BL"} {
				set y1_ [expr {$y1 + $dy}]
				if {$y1_ > $wy1} {
					lset xy 3 $wy1
					lset bxy 1 $h
				} elseif {$y1_ - $y0 > $minSize} {
					lset xy 3 $y1_
					lset bxy 1 $y
				}
			}
		}
		::PrintBox::Resize $W
	}
}

