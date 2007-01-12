#
# Pre-condition :
# - Assumes BWidgets is loaded (for auto-scrolling DPs in a conference)
#
# Changes : 
# - 'hook' for real the needed procs... redefine them, so ChangePicture, 
#   when called acts on the DoublePicture widget while setting the lower DP 
#   to 'self'... this way, we always get called correctly.
# - Many DPs for many users in chat
# - Redefined the picture menus
# - Fixed some issues with show/hide DPs
# - Hiding lower DP doesn't set top DP to 'self'
# - etc..
#
# TODO : 
# - When we resize an image, we should also resize the [trunc $nickname] shown (for multi-user convos)
#

namespace eval ::DualDisplayPicture {

	array set myinfo {}

	proc Init { dir } {
		::plugins::RegisterPlugin DualDisplayPicture
		::plugins::RegisterEvent DualDisplayPicture new_chatwindow hookCW
		::plugins::RegisterEvent DualDisplayPicture user_joins_chat user_leaves_join_chat
		::plugins::RegisterEvent DualDisplayPicture user_leaves_chat user_leaves_join_chat


		rename ::amsn::ChangePicture ::DualDisplayPicture::ChangePicture_orig
		proc ::amsn::ChangePicture { win picture balloontext {nopack ""} } {
			if { ![info exists ::DualDisplayPicture::myinfo(text,$win)] || \
                 ![winfo exists $::DualDisplayPicture::myinfo(text,$win)] } {
				::DualDisplayPicture::ChangePicture_orig $win $picture $balloontext $nopack
			} else {
				::DualDisplayPicture::ChangePicture_orig $win displaypicture_std_self [trans mypic]
				::DualDisplayPicture::update_user_DPs $win
			}
		}

		rename ::amsn::ShowPicMenu ::DualDisplayPicture::ShowPicMenu_orig
		proc ::amsn::ShowPicMenu { win x y } {
			if { ![info exists ::DualDisplayPicture::myinfo(text,$win)] || \
                 ![winfo exists $::DualDisplayPicture::myinfo(text,$win)] } {
				::DualDisplayPicture::ShowPicMenu_orig $win $x $y
			} else {
				::DualDisplayPicture::ShowMyPicMenu $win $x $y
			}
		}
	}

	proc DeInit { } {
		if { [info procs ::DualDisplayPicture::ChangePicture_orig] != "" } {
			rename ::amsn::ChangePicture ""
			rename ::DualDisplayPicture::ChangePicture_orig ::amsn::ChangePicture
		}
		if { [info procs ::DualDisplayPicture::ShowPicMenu_orig] != "" } {
			rename ::amsn::ShowPicMenu ""
			rename ::DualDisplayPicture::ShowPicMenu_orig ::amsn::ShowPicMenu
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
		variable myinfo
		if { ![winfo exists $myinfo(text,$win)] } { return }
		
		set chatid [::ChatWindow::Name $win]
		set users [::MSN::usersInChat $chatid]

		# don't show user labels if there's only one user
		set show_user_labels 0
		if {[llength $users] > 1} {
			set show_user_labels 1
		}

		$myinfo(text,$win) configure -state normal
		$myinfo(text,$win) delete 0.0 end
		set maxwidth 0
		set idx 0
		foreach user $users {
			$myinfo(text,$win) tag bind user_$user \
				<Button1-ButtonRelease> [list ::DualDisplayPicture::ShowDoublePicMenu $win $user %X %Y]
			$myinfo(text,$win) tag bind user_$user \
				<<Button3>> [list ::DualDisplayPicture::ShowDoublePicMenu $win $user %X %Y]

			$myinfo(text,$win) mark set user_start [$myinfo(text,$win) index current]
			$myinfo(text,$win) mark gravity user_start left

			set trunced [trunc [::abook::getDisplayNick $user] $myinfo(text,$win) \
				[expr {[winfo width $myinfo(text,$win)]-10}] sitalf]

			if {$idx == 0 && $show_user_labels == 1} {
				$myinfo(text,$win) insert end "$trunced\n"
			} elseif {$show_user_labels == 1} {
				$myinfo(text,$win) insert end "\n$trunced\n"
			}

			$myinfo(text,$win) image create end \
				-image [::skin::getDisplayPicture $user]
			$myinfo(text,$win) tag add user_$user user_start end

			if {[image width [::skin::getDisplayPicture $user]] > $maxwidth} {
				set maxwidth [image width [::skin::getDisplayPicture $user]]
			}
			incr idx
		}
		set fontwidth [font measure splainf "0"]
		set char_maxwidth [expr {($maxwidth + 1) / $fontwidth}]
		$myinfo(text,$win) configure -state disabled \
									 -width $char_maxwidth
	}

	proc CreateDoublePictureFrame { w out } {
		variable myinfo
		# Name our widgets
		set frame $out.pic
		set showpic $frame.showpic

		# Create them
		frame $frame -class Amsn -borderwidth 0 \
			-relief solid -background [::skin::getKey chatwindowbg]
		
		ScrolledWindow $frame.sw -scrollbar vertical -auto vertical
		text $frame.sw.text -bg [::skin::getKey chatwindowbg] -padx 0 -pady 0 \
			-relief solid -bd 0 -font splainf -state disabled
		$frame.sw setwidget $frame.sw.text

		set myinfo(showpic,$w) $showpic
		set myinfo(sw,$w) $frame.sw
		set myinfo(text,$w) $frame.sw.text

		label $showpic -bd 0 -padx 0 -pady 0 -image [::skin::loadPixmap imgshow] \
			-bg [::skin::getKey chatwindowbg] -highlightthickness 0 -font splainf \
			-highlightbackground [::skin::getKey chatwindowbg] -activebackground [::skin::getKey chatwindowbg]
		bind $showpic <Enter> "$showpic configure -image [::skin::loadPixmap imgshow_hover]"
		bind $showpic <Leave> "$showpic configure -image [::skin::loadPixmap imgshow]"
		set_balloon $showpic [trans showdisplaypic]

		# Pack them 
		pack $frame.sw -side left -fill y -expand false -anchor ne
		pack $showpic -side right -anchor ne

		# Create our bindings
		bind $showpic <<Button1>> "::DualDisplayPicture::ToggleShowDoublePicture $w; ::DualDisplayPicture::ShowOrHideDoublePicture $w"
			
		ToggleShowDoublePicture $w
		ShowOrHideDoublePicture $w
		return $frame	
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
			::DualDisplayPicture::ShowDoublePicture $win
		} else {
			::DualDisplayPicture::HideDoublePicture $win
		}
	}

	proc ShowDoublePicMenu { win user x y } {
		catch {menu $win.picmenu -tearoff 0}
		$win.picmenu delete 0 end

		#Make the picture menu appear on the conversation window instead of having it in the bottom of screen (and sometime lost it if the conversation window is in the bottom of the window)
		if { [OnMac] } {
			#Cursor at the top right hand corner (NE) of the popup.
			incr x -123
			incr y +2
		}

		set chatid [::ChatWindow::Name $win]
		set pic [::skin::getDisplayPicture $user]
		if { $pic != "displaypicture_std_none" && $user != ""} {
			$win.picmenu add command -label "[trans changesize]" -command [list ::DualDisplayPicture::ShowDoublePicMenu $win $user $x $y]
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
			#Cursor in the bottom right hand corner (SE) of the popup.
			incr x -212
			incr y -25
		}
	
		#Load Change Display Picture window
		$win.picmenu add command -label "[trans changedisplaypic]..." -command dpBrowser

		tk_popup $win.picmenu $x $y

	}


	proc ShowDoublePicture {win } {
		upvar #0 ${win}_show_double_picture show_pic
		variable myinfo

		set scrolling [::ChatWindow::getScrolling [::ChatWindow::GetOutText $win]]

		pack $myinfo(sw,$win) -side left -fill y -expand false -anchor ne
		#pack $myinfo(showpic,$win) -side left
		#pack $myinfo(text,$win) -side left -padx 0 -pady 0 -anchor w

		$myinfo(showpic,$win) configure -image [::skin::loadPixmap imghide]
		bind $myinfo(showpic,$win) <Enter> "$myinfo(showpic,$win) configure -image [::skin::loadPixmap imghide_hover]"
		bind $myinfo(showpic,$win) <Leave> "$myinfo(showpic,$win) configure -image [::skin::loadPixmap imghide]"
		change_balloon $myinfo(showpic,$win) [trans hidedisplaypic]
		set show_pic 1
		
		if { $scrolling } {
			update idletasks
			::ChatWindow::Scroll [::ChatWindow::GetOutText $win]
		}
	}

	proc HideDoublePicture { win } {
		upvar #0 ${win}_show_double_picture show_pic
		variable myinfo

		pack forget $myinfo(sw,$win)

		#Change here to change the icon, instead of text
		$myinfo(showpic,$win) configure -image [::skin::loadPixmap imgshow]
		bind $myinfo(showpic,$win) <Enter> "$myinfo(showpic,$win) configure -image [::skin::loadPixmap imgshow_hover]"
		bind $myinfo(showpic,$win) <Leave> "$myinfo(showpic,$win) configure -image [::skin::loadPixmap imgshow]"

		change_balloon $myinfo(showpic,$win) [trans showdisplaypic]

		set show_pic 0

	}

}
