#
# Most of this code was pasted and modified from the chatwindow.tcl and gui.tcl files... 
# if the code was cleaner, this wouldn't have been necessary... 
#
# Many things TODO :
# multiple picture frames for multiple users in chat
# better switch from one image to another depending on user who joins, etc...  now there is a delay until 'user joins conversation'... 
#

namespace eval ::CWDoubleDP {

	proc Init { dir } {
		::plugins::RegisterPlugin CWDoubleDP
		::plugins::RegisterEvent CWDoubleDP new_chatwindow hookCW
		::plugins::RegisterEvent CWDoubleDP new_conversation hookDP
		::plugins::RegisterEvent CWDoubleDP user_joins_chat hookDP
	}

	proc hookDP {event evpar } {
		if { $event == "new_conversation" } {
			upvar 2 $evpar newvar
			upvar 2 win_name w
			
			after 100 "::CWDoubleDP::SetDPs $w $evpar(usr_name)"

		} elseif { $event == "user_joins_chat" } {
			upvar 2 $evpar newvar
			upvar 2 $newvar(usr_name) user
			upvar 2 $newvar(win_name) w
			::CWDoubleDP::SetDPs $w $user
		}
	}

	proc SetDPs { w user } {
		::amsn::ChangePicture $w displaypicture_std_self [trans mypic]
		if { $user != "" } {
			::CWDoubleDP::ChangeDoublePicture $w [::skin::getDisplayPicture $user] [trans showuserpic $user]
		} else {
			::CWDoubleDP::ChangeDoublePicture $w [::skin::getNoDisplayPicture] ""
		}

	}
	proc hookCW {event evpar } {
                upvar 2 $evpar newvar
		set w $newvar(win)
		set out $w.f.out

		set scroll_p [pack info $out.scroll]
		array set scroll $scroll_p
		set scroll(-side) left
		pack forget $out.scroll
		eval pack $out.scroll [array get scroll]
		set picture [CreateDoublePictureFrame $w $out]
		pack $picture -side right -expand false -anchor ne \
				-padx [::skin::getKey chat_dp_padx] \
				-pady [::skin::getKey chat_dp_pady]

		::CWDoubleDP::SetDPs $w ""
	

		
	}

	proc CreateDoublePictureFrame { w out } {
		# Name our widgets
		set frame $out.pic
		set picture $frame.image
		set showpic $frame.showpic

		# Create them
		frame $frame -class Amsn -borderwidth 0 -relief solid -background [::skin::getKey chatwindowbg]
		framec $picture -type label -relief solid -image [::skin::getNoDisplayPicture] \
				-borderwidth [::skin::getKey chat_dp_border] \
				-bordercolor [::skin::getKey chat_dp_border_color] \
				-background [::skin::getKey chatwindowbg]
		set pictureinner [$picture getinnerframe]

		set_balloon $pictureinner [trans nopic]
		label $showpic -bd 0 -padx 0 -pady 0 -image [::skin::loadPixmap imgshow] \
			-bg [::skin::getKey chatwindowbg] -highlightthickness 0 -font splainf \
			-highlightbackground [::skin::getKey chatwindowbg] -activebackground [::skin::getKey chatwindowbg]
		bind $showpic <Enter> "$showpic configure -image [::skin::loadPixmap imgshow_hover]"
		bind $showpic <Leave> "$showpic configure -image [::skin::loadPixmap imgshow]"
		set_balloon $showpic [trans showdisplaypic]

		# Pack them 
		#pack $picture -side left -padx 0 -pady [::skin::getKey chatpady] -anchor w
		pack $showpic -side right -expand true -fill y -padx 0 -pady 0 -anchor e

		# Create our bindings
		bind $showpic <<Button1>> "::CWDoubleDP::ToggleShowDoublePicture $w; ::CWDoubleDP::ShowOrHideDoublePicture $w"
		bind $pictureinner <Button1-ButtonRelease> "::CWDoubleDP::ShowDoublePicMenu $w %X %Y\n"
		bind $pictureinner <<Button3>> "::CWDoubleDP::ShowDoublePicMenu $w %X %Y\n"
			
		#For TkAqua: Disable temporary, crash issue with that line
		if { ![OnMac] } {
			bind $picture <Configure> "::ChatWindow::ImageResized $w %h [::skin::getKey chat_dp_pady]"
		}

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
			::CWDoubleDP::ChangeDoublePicture $win [$win.f.out.pic.image cget -image] ""
		} else {
			::CWDoubleDP::HideDoublePicture $win
		}
	}

	proc ShowDoublePicMenu { win x y } {
		catch {menu $win.picmenu -tearoff 0}
		$win.picmenu delete 0 end

		#Make the picture menu appear on the conversation window instead of having it in the bottom of screen (and sometime lost it if the conversation window is in the bottom of the window)
		if { [OnMac] } {
			incr x -50
			incr y -115
		}

		set chatid [::ChatWindow::Name $win]
		set users [::MSN::usersInChat $chatid]
		#Switch to "my picture" or "user picture"
		$win.picmenu add command -label "[trans showmypic]" \
			-command [list ::CWDoubleDP::ChangeDoublePicture $win displaypicture_std_self [trans mypic]]
		foreach user $users {
			$win.picmenu add command -label "[trans showuserpic $user]" \
				-command "::CWDoubleDP::ChangeDoublePicture $win \[::skin::getDisplayPicture $user\] \[trans showuserpic $user\]"
		}
		#Load Change Display Picture window
		$win.picmenu add separator
		$win.picmenu add command -label "[trans changedisplaypic]..." -command pictureBrowser

		set user [$win.f.out.pic.image cget -image]
		if { $user != "displaypicture_std_none" && $user != "displaypicture_std_self" } {
			#made easy for if we would change the image names
			set user [string range $user [string length "displaypicture_std_"] end]
			$win.picmenu add separator
			#Sub-menu to change size
			$win.picmenu add cascade -label "[trans changesize]" -menu $win.picmenu.size
			catch {menu $win.picmenu.size -tearoff 0 -type normal}
			$win.picmenu.size delete 0 end
			#4 possible size (someone can add something to let the user choose his size)
			$win.picmenu.size add command -label "[trans small]" -command "::skin::ConvertDPSize $user 64 64"
			$win.picmenu.size add command -label "[trans default2]" -command "::skin::ConvertDPSize $user 96 96"
			$win.picmenu.size add command -label "[trans large]" -command "::skin::ConvertDPSize $user 128 128"
			$win.picmenu.size add command -label "[trans huge]" -command "::skin::ConvertDPSize $user 192 192"
			#Get back to original picture
			$win.picmenu.size add command -label "[trans original]" -command "::MSNP2P::loadUserPic $chatid $user 1"
		}
		tk_popup $win.picmenu $x $y
	}

	proc ChangeDoublePicture {win picture balloontext {nopack ""}} {
		upvar #0 ${win}_show_double_picture show_pic

		set scrolling [::ChatWindow::getScrolling [::ChatWindow::GetOutText $win]]


		#Get the path to the image
		set pictureinner [$win.f.out.pic.image getinnerframe]
		if { $balloontext != "" } {
			#TODO: Improve this!!! Use some kind of abstraction!
			change_balloon $pictureinner $balloontext
		}
		if { [catch {$win.f.out.pic.image configure -image $picture}] } {
			$win.f.out.pic.image configure -image [::skin::getNoDisplayPicture]
			change_balloon $pictureinner [trans nopic]
		} elseif { $nopack == "" } {
			pack $win.f.out.pic.image -side left -padx 0 -pady 0 -anchor w
			$win.f.out.pic.showpic configure -image [::skin::loadPixmap imghide]
			bind $win.f.out.pic.showpic <Enter> "$win.f.out.pic.showpic configure -image [::skin::loadPixmap imghide_hover]"
			bind $win.f.out.pic.showpic <Leave> "$win.f.out.pic.showpic configure -image [::skin::loadPixmap imghide]"
			change_balloon $win.f.out.pic.showpic [trans hidedisplaypic]
			set show_pic 1
		}

		if { $scrolling } {
			update idletasks
			::ChatWindow::Scroll [::ChatWindow::GetOutText $win]
		}
	}

	proc HideDoublePicture { win } {
		global ${win}_show_picture
		pack forget $win.f.out.pic.image

		#Change here to change the icon, instead of text
		$win.f.out.pic.showpic configure -image [::skin::loadPixmap imgshow]
		bind $win.f.out.pic.showpic <Enter> "$win.f.out.pic.showpic configure -image [::skin::loadPixmap imgshow_hover]"
		bind $win.f.out.pic.showpic <Leave> "$win.f.out.pic.showpic configure -image [::skin::loadPixmap imgshow]"

		change_balloon $win.f.out.pic.showpic [trans showdisplaypic]

		set ${win}_show_double_picture 0

	}

}
