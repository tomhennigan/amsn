#
#
# Changes : 
# 'hook' for real the needed procs... redefine them, so ChangePicture, when called acts on the DoublePicture widget while setting the lower DP to 'self'... this way, we always get called correctly.
# Many DPs for many users in chat
# Redefined the picture menus
# Fixed some issues with show/hide DPs
# Hiding lower DP doesn't set top DP to 'self'
# etc..
#
# TODO : When we resize an image, we should also resize the [trunc $nickname] shown (for multi-user convos)
#

namespace eval ::CWDoubleDP {

	array set CycleOffsets {}

	proc Init { dir } {
		::plugins::RegisterPlugin CWDoubleDP
		::plugins::RegisterEvent CWDoubleDP new_chatwindow hookCW
		::plugins::RegisterEvent CWDoubleDP user_joins_chat user_leaves_join_chat
		::plugins::RegisterEvent CWDoubleDP user_leaves_chat user_leaves_join_chat


		rename ::amsn::ChangePicture ::CWDoubleDP::ChangePicture_orig
		proc ::amsn::ChangePicture { win picture balloontext {nopack ""} } {
			if { ![winfo exists  $win.f.out.pic.images] } {
				::CWDoubleDP::ChangePicture_orig $win $picture $balloontext $nopack
			} else {
				::CWDoubleDP::ChangePicture_orig $win displaypicture_std_self [trans mypic]
				::CWDoubleDP::update_user_DPs $win
			}
		}

		rename ::amsn::ShowPicMenu ::CWDoubleDP::ShowPicMenu_orig
		proc ::amsn::ShowPicMenu { win x y } {
			if { ![winfo exists  $win.f.out.pic.images] } {
				::CWDoubleDP::ShowPicMenu_orig $win $x $y
			} else {
				::CWDoubleDP::ShowMyPicMenu $win $x $y
			}
		}
	}

	proc DeInit { } {
		if { [info procs ::CWDoubleDP::ChangePicture_orig] != "" } {
			rename ::amsn::ChangePicture ""
			rename ::CWDoubleDP::ChangePicture_orig ::amsn::ChangePicture
		}
		if { [info procs ::CWDoubleDP::ShowPicMenu_orig] != "" } {
			rename ::amsn::ShowPicMenu ""
			rename ::CWDoubleDP::ShowPicMenu_orig ::amsn::ShowPicMenu
		}
	}

	proc hookCW {event evpar } {
                upvar 2 $evpar newvar
		set w $newvar(win)
		set out $w.f.out

		# We need to pack info/pack forget/pack in order to make it display properly. 
		# Currently the scrolled window is packed with -side top, while we want it with -side left
		set scroll_p [pack info $out.scroll]
		array set scroll $scroll_p
		set scroll(-side) left
		pack forget $out.scroll
		eval pack $out.scroll [array get scroll]

		set picture [CreateDoublePictureFrame $w $out]
		pack $picture -side right -expand false -anchor ne \
				-padx [::skin::getKey chat_dp_padx] \
				-pady [::skin::getKey chat_dp_pady]
	
	}
	proc user_leaves_join_chat {event evpar } {
		upvar 2 $evpar newvar
		upvar 2 $newvar(win_name) win
		update_user_DPs $win
	}

	proc update_user_DPs { win } {
		variable CycleOffsets

		set images $win.f.out.pic.images
		if { ![winfo exists $images] } { return }
		# Remove existing user images
		foreach child [winfo children $images] {
			destroy $child
		}
		
		set chatid [::ChatWindow::Name $win]
		set users [::MSN::usersInChat $chatid]
		pack forget $win.f.out.pic.cyclepic
		if { [llength $users] == 0 } {
			CreateFrameForUser $images.nouser
		} elseif { [llength $users] == 1 } {
			CreateFrameForUser $images.user $users
			SetUserDP $images.user [::skin::getDisplayPicture $users] [trans showuserpic $users]

		} else {
			pack $win.f.out.pic.cyclepic
			set idx 0
			set offset 0
			if { [info exists CycleOffsets(${win})] } {
				set offset $CycleOffsets(${win})
			}
			# Add users, starting at correct offset
			for {set uidx $offset} \
				{[expr {$uidx < $offset + [llength $users]}]} {incr uidx} {
				set user [lindex $users [expr {$uidx % [llength $users]}]]

				label $images.user_name$idx \
				    -background [::skin::getKey chatwindowbg] \
				    -relief solid -font sitalf
				if { [catch {$images.user_name$idx configure  -text [trunc [::abook::getDisplayNick $user] $images.user_name$idx [image width [::skin::getDisplayPicture $user]] sitalf] } ] } {
					$images.user_name$idx -text [string range [::abook::getDisplayNick $user] 0 4]
				}
				pack $images.user_name$idx -side top -padx 0 -pady 0 -anchor n
				CreateFrameForUser $images.user_dp$idx $user
				SetUserDP $images.user_dp$idx [::skin::getDisplayPicture $user] [trans showuserpic $user]
				incr idx
			}

		}
	}

	proc SetUserDP { w img tooltip } {
		set pictureinner [$w getinnerframe]
		change_balloon $pictureinner $tooltip
		if { [catch {$w configure -image $img}] } {
			$w configure -image [::skin::getNoDisplayPicture]
			change_balloon $pictureinner [trans nopic]
		}
	}

	proc CreateDoublePictureFrame { w out } {
		# Name our widgets
		set frame $out.pic
		set picture $frame.images
		set showpic $frame.showpic
		set cyclepic $frame.cyclepic

		# Create them
		frame $frame -class Amsn -borderwidth 0 -relief solid -background [::skin::getKey chatwindowbg]
		
		frame $picture -class Amsn -borderwidth 0 -relief solid -background [::skin::getKey chatwindowbg]
		CreateFrameForUser $picture.nouser

		label $showpic -bd 0 -padx 0 -pady 0 -image [::skin::loadPixmap imgshow] \
			-bg [::skin::getKey chatwindowbg] -highlightthickness 0 -font splainf \
			-highlightbackground [::skin::getKey chatwindowbg] -activebackground [::skin::getKey chatwindowbg]
		bind $showpic <Enter> "$showpic configure -image [::skin::loadPixmap imgshow_hover]"
		bind $showpic <Leave> "$showpic configure -image [::skin::loadPixmap imgshow]"
		set_balloon $showpic [trans showdisplaypic]

		label $cyclepic -bd 0 -padx 0 -pady 0 -image [::skin::loadPixmap contract] \
			-bg [::skin::getKey chatwindowbg] -highlightthickness 0 -font splainf \
			-highlightbackground [::skin::getKey chatwindowbg] -activebackground [::skin::getKey chatwindowbg]
		bind $cyclepic <Enter> "$cyclepic configure -image [::skin::loadPixmap contract_hover]"
		bind $cyclepic <Leave> "$cyclepic configure -image [::skin::loadPixmap contract]"
		set_balloon $cyclepic [trans cycledisplaypic]

		# Pack them 
		pack $cyclepic -side top -padx 0 -pady 0 -anchor n
		pack $picture -side left -padx 0 -pady 0 -anchor w
		pack $showpic -side right -expand true -fill y -padx 0 -pady 0 -anchor e

		# Create our bindings
		bind $showpic <<Button1>> "::CWDoubleDP::ToggleShowDoublePicture $w; ::CWDoubleDP::ShowOrHideDoublePicture $w"
		bind $cyclepic <<Button1>> "::CWDoubleDP::IncreaseCycleOffset $w"
			
		ToggleShowDoublePicture $w
		ShowOrHideDoublePicture $w
		return $frame	
	}

	proc CreateFrameForUser { win {user ""}} {
		framec $win -type label -relief solid -image [::skin::getNoDisplayPicture] \
		    -borderwidth [::skin::getKey chat_dp_border] \
		    -bordercolor [::skin::getKey chat_dp_border_color] \
		    -background [::skin::getKey chatwindowbg]
		set pictureinner [$win getinnerframe]
		bind $pictureinner <Button1-ButtonRelease> [list ::CWDoubleDP::ShowDoublePicMenu $win $user %X %Y]
		bind $pictureinner <<Button3>> [list ::CWDoubleDP::ShowDoublePicMenu $win $user %X %Y]
		
		
		pack $win -side top -padx 0 -pady 0 -anchor n

		set_balloon $pictureinner [trans nopic]	
	}
	
	proc IncreaseCycleOffset { win_name } {
		variable CycleOffsets
		if { [info exists CycleOffsets(${win_name})] } {
			incr CycleOffsets(${win_name})
		} else {
			set CycleOffsets(${win_name}) 1
		}
		update_user_DPs $win_name
	}

	proc ToggleShowDoublePicture { win_name } {
		upvar #0 ${win_name}_show_double_picture show_pic

		if { [info exists show_pic] && $show_pic } {
			set show_pic 0
		} else {
			set show_pic 1
		}
	}

	proc ShowOrHideDoublePicture { win } {
		upvar #0 ${win}_show_double_picture value
		if { $value == 1} {
			::CWDoubleDP::ShowDoublePicture $win
		} else {
			::CWDoubleDP::HideDoublePicture $win
		}
	}

	proc ShowDoublePicMenu { win user x y } {
		catch {menu $win.picmenu -tearoff 0}
		$win.picmenu delete 0 end

		#Make the picture menu appear on the conversation window instead of having it in the bottom of screen (and sometime lost it if the conversation window is in the bottom of the window)
		if { [OnMac] } {
			incr x -50
			incr y -115
		}

		set chatid [::ChatWindow::Name $win]
		set pic [$win cget -image]
		if { $pic != "displaypicture_std_none" && $user != ""} {
			$win.picmenu add command -label "[trans changesize]" -command [list ::CWDoubleDP::ShowDoublePicMenu $win $user $x $y]
			#4 possible size (someone can add something to let the user choose his size)
			$win.picmenu add command -label " -> [trans small]" -command "::skin::ConvertDPSize $user 64 64"
			$win.picmenu add command -label " -> [trans default2]" -command "::skin::ConvertDPSize $user 96 96"
			$win.picmenu add command -label " -> [trans large]" -command "::skin::ConvertDPSize $user 128 128"
			$win.picmenu add command -label " -> [trans huge]" -command "::skin::ConvertDPSize $user 192 192"
			#Get back to original picture
			$win.picmenu add command -label " -> [trans original]" -command "::MSNP2P::loadUserPic $chatid $user 1"
			tk_popup $win.picmenu $x $y
		}
	}

	proc ShowMyPicMenu { win x y} {
		status_log "Show menu in window $win, position $x $y\n" blue
		catch {menu $win.picmenu -tearoff 0}
		$win.picmenu delete 0 end

		#Make the picture menu appear on the conversation window instead of having it in the bottom of screen (and sometime lost it if the conversation window is in the bottom of the window)
		if { [OnMac] } {
			incr x -50
			incr y -115
		}
	
		#Load Change Display Picture window
		$win.picmenu add command -label "[trans changedisplaypic]..." -command pictureBrowser

		tk_popup $win.picmenu $x $y

	}


	proc ShowDoublePicture {win } {
		upvar #0 ${win}_show_double_picture show_pic

		set scrolling [::ChatWindow::getScrolling [::ChatWindow::GetOutText $win]]


		pack $win.f.out.pic.images -side left -padx 0 -pady 0 -anchor w
		$win.f.out.pic.showpic configure -image [::skin::loadPixmap imghide]
		bind $win.f.out.pic.showpic <Enter> "$win.f.out.pic.showpic configure -image [::skin::loadPixmap imghide_hover]"
		bind $win.f.out.pic.showpic <Leave> "$win.f.out.pic.showpic configure -image [::skin::loadPixmap imghide]"
		change_balloon $win.f.out.pic.showpic [trans hidedisplaypic]
		set show_pic 1
		
		if { $scrolling } {
			update idletasks
			::ChatWindow::Scroll [::ChatWindow::GetOutText $win]
		}
	}

	proc HideDoublePicture { win } {
		upvar #0 ${win}_show_double_picture show_pic
		pack forget $win.f.out.pic.images

		#Change here to change the icon, instead of text
		$win.f.out.pic.showpic configure -image [::skin::loadPixmap imgshow]
		bind $win.f.out.pic.showpic <Enter> "$win.f.out.pic.showpic configure -image [::skin::loadPixmap imgshow_hover]"
		bind $win.f.out.pic.showpic <Leave> "$win.f.out.pic.showpic configure -image [::skin::loadPixmap imgshow]"

		change_balloon $win.f.out.pic.showpic [trans showdisplaypic]

		set show_pic 0

	}

}
