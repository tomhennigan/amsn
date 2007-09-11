##################################################
#  This plugin implements the actions menu on    #
#  the bottom of the contactlist, as seen in MSN #
#   ===========================================  #
#   Originally written by  Karel Demeyer, 2005   #
#   Fixed by Takeshi, 2007                       #
#   Search Contact function by Takeshi, Square87 #
#  ============================================  #
##################################################


namespace eval ::actionsmenu {
	variable config

proc Init { dir } {
	
	::plugins::RegisterPlugin "ActionsMenu"
	::plugins::RegisterEvent "ActionsMenu" OnConnect draw
	::plugins::RegisterEvent "ActionsMenu" OnDisconnect hideframe
	
	set langdir [append dir "/lang"]
	load_lang en $langdir
	load_lang [::config::getGlobalKey language] $langdir

	



	array set ::actionsmenu::config {
		search 0
		show 0
		hide 0
	}
	
	set ::actionsmenu::configlist [list \
						[list frame ::actionsmenu::populatesearchframe ""] \
						[list frame ::actionsmenu::populateshowframe ""] \
						[list frame ::actionsmenu::populatehideframe ""] \
						]
	bind . <Control-g> "::actionsmenu::createsearchwindow"
	
	
	status_log "ActionsMenu loaded"
	
}

proc hideframe {event evPar} {
	destroy .main.actions
	destroy .searchwindow
}

proc draw {event evPar} {
	if {$::actionsmenu::config(hide) == 0 } {
	after 1000 ::actionsmenu::redraw
	} else { after 1000 ::actionsmenu::draw2 }
}
proc populatehideframe { win_name } {
	variable config
	variable hide
	frame $win_name.hide -class Degt
	label $win_name.hide.text1 -text "[trans startconf]" -padx 5 -font splainf
	pack $win_name.hide $win_name.hide.text1
	
	radiobutton $win_name.hide.1 -text "[trans minimized]" -variable ::actionsmenu::config(hide) -value 0
	radiobutton $win_name.hide.2 -text "[trans maximized]" -variable ::actionsmenu::config(hide) -value 1 
	pack $win_name.hide.1 $win_name.hide.2 -anchor w -side top
}
proc populatesearchframe { win_name } {
	variable config
	variable search
	frame $win_name.search -class Degt
	label $win_name.search.text1 -text "[trans searchdefault]" -padx 5 -font splainf
	pack $win_name.search $win_name.search.text1
	
	radiobutton $win_name.search.1 -text "[trans all]" -variable ::actionsmenu::config(search) -value 0
	radiobutton $win_name.search.2 -text "[trans nick]" -variable ::actionsmenu::config(search) -value 1
	radiobutton $win_name.search.3 -text "[trans email]" -variable ::actionsmenu::config(search) -value 2
	pack $win_name.search.1 $win_name.search.2 $win_name.search.3 -anchor w -side top
}

proc populateshowframe { win_name } {
	variable config
	variable show
	frame $win_name.show -class Degt
	label $win_name.show.text1 -text "[trans showdefault]" -padx 5 -font splainf
	pack $win_name.show $win_name.show.text1
	
	radiobutton $win_name.show.1 -text "[trans nick]" -variable ::actionsmenu::config(show) -value 0
	radiobutton $win_name.show.2 -text "[trans email]" -variable ::actionsmenu::config(show) -value 1
	pack $win_name.show.1 $win_name.show.2 -anchor w -side top
}
proc DeInit { } {
#When the plugin gets unloaded, remove the actions button if existing
	set actions .main.actions
	if { [winfo exists $actions]} {
		destroy $actions
	}
	destroy .searchwindow
}

proc ConfigList {} {
	
set ::actionsmenu::configlist [list \
			  [list bool "[trans notify1]" ] 
	
}
proc draw2 { } {
		global HOME HOME2
		::skin::setPixmap actionsbg actionsbg.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]
	::skin::setPixmap img_expcol actions_expcol.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]
	::skin::setPixmap img_addcontact actions_addcontact.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]
	::skin::setPixmap img_find actions_find.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]
	::skin::setPixmap img_collapsecol actions_collapsecol.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]
	
		set bgcolor [::skin::getKey mainwindowbg]
		set actions .main.actions
		if { [winfo exists $actions]} {
			destroy $actions
		}

		frame $actions -relief flat -borderwidth 0

		set acanvas .main.actions.canvas
		
		
		canvas $acanvas -bg $bgcolor -height 60 -highlightthickness 0 -relief flat -borderwidth 0
		$acanvas create image 0 0 -image [::skin::loadPixmap actionsbg] -anchor nw -tag expand
		$acanvas create image 0 0 -image [::skin::loadPixmap img_expcol] -anchor nw -tag expand
		$acanvas create text 30 3 -text "[trans iwantto]..." -anchor nw -tag expand -font sboldf -fill #102040
		$acanvas bind expand <ButtonPress-1> "::actionsmenu::redraw"

		#$acanvas bind expand <Enter> "+$acanvas create line 30 18 100 18 -tag exp_line; $acanvas configure -cursor hand2; $acanvas lower exp_line expand"
		#$acanvas bind expand <Leave> "+$acanvas delete exp_line; $acanvas configure -cursor left_ptr"

		AddActionButton $acanvas 15 27 [::skin::loadPixmap img_addcontact] "[trans addacontact] ..." "cmsn_draw_addcontact" addcontact
		AddSearchButton $acanvas 15 43 [::skin::loadPixmap img_find] "[trans searchcontact] ..." "::actionsmenu::createsearchwindow" searchcontact


		pack configure $acanvas -side top -fill both -expand true
		pack configure $actions -side bottom -fill x 

		update idletasks

	}



proc redraw { } {
	global HOME HOME2
	set actions .main.actions
	if { [winfo exists $actions]} {
			destroy $actions
		}
		
	::skin::setPixmap actionsbg actionsbg.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]
	::skin::setPixmap img_collapsecol actions_collapsecol.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]
	

	frame $actions -relief flat -borderwidth 0

	set acanvas .main.actions.canvas
	set bgcolor [::skin::getKey mainwindowbg]

	canvas $acanvas -bg $bgcolor -height 20 -highlightthickness 0 -relief flat -borderwidth 0
	$acanvas  create image 0 0 -image [::skin::loadPixmap actionsbg] -anchor nw -tag expand
	$acanvas create image 0 0 -image [::skin::loadPixmap img_collapsecol] -anchor nw -tag expand
	$acanvas bind expand <ButtonPress-1> "::actionsmenu::draw2"

	pack configure $acanvas -side top -fill both -expand true
	pack configure $actions -side bottom -fill x

}


proc AddActionButton {acanvas xcoord ycoord img text command tag} {
	set font splainf
	
	$acanvas create image $xcoord $ycoord -image $img -anchor nw -tag $tag
	$acanvas create text [expr $xcoord + 15] [expr $ycoord -3] -text $text -anchor nw -tag $tag -font $font -fill #102040
	$acanvas bind $tag <ButtonPress-1> "$command"
	$acanvas bind $tag <Enter> "+$acanvas create line [expr $xcoord + 15] [expr $ycoord + 12] [expr $xcoord + [expr [font measure $font $text] + 15]]  [expr $ycoord + 12] -tag ${tag}_line; $acanvas configure -cursor hand2; $acanvas lower ${tag}_line $tag "
	$acanvas bind $tag <Leave> "+$acanvas delete ${tag}_line; $acanvas configure -cursor left_ptr"
}


proc AddSearchButton { acanvas xcoord ycoord img text command tag } {
	set font splainf
	
	$acanvas create image $xcoord $ycoord -image $img -anchor nw
	$acanvas create text [expr $xcoord + 15] [expr $ycoord -0] -text "[trans searchcontact]..." -anchor nw -tag $tag -font $font -fill #102040
	$acanvas bind $tag <ButtonPress-1> "$command"
	$acanvas bind $tag <Enter> " $acanvas configure -cursor hand2; $acanvas lower ${tag}_line $tag ; "
	$acanvas bind $tag <Enter> "+$acanvas create line [expr $xcoord + 15] [expr $ycoord + 14] [expr $xcoord + [expr [font measure $font $text] + 15]]  [expr $ycoord + 14] -tag ${tag}_line; $acanvas configure -cursor hand2; $acanvas lower ${tag}_line $tag "
	$acanvas bind $tag <Leave> "+$acanvas delete ${tag}_line; $acanvas configure -cursor left_ptr"
}
proc OnMac {} {
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		return 1
	} else {
		return 0
	}
}

proc createsearchwindow { } {
	variable output [list]
	variable config
	if { [winfo exists .searchwindow] } { destroy .searchwindow }

	toplevel .searchwindow
	
	wm group .searchwindow .
	wm transient .searchwindow .
	#wm withdraw .searchwindow
	update
	set x [winfo rootx .main]
	set y [expr {([winfo rooty .main]+100)}]
	
	
	
	set max_x [expr {[winfo screenwidth .] - 525 }]
	set max_y [expr {[winfo screenheight .] - 300 }]
	if { $x > $max_x } {
		set x $max_x
	}
	if { $y > $max_y } {
		set y $max_y
	}

	 	

	
	if { [OnMac] } {
		wm resizable .searchwindow 0 0
		wm geometry .searchwindow 525x300+$x+$y
		
	} else {
		wm resizable .searchwindow 1 1
		wm geometry  .searchwindow +$x+$y
	}
	wm title .searchwindow "[trans search]"
	wm deiconify .searchwindow 
#	label .searchwindow.l -font sboldf -text "[trans search]"
	
	
	entry .searchwindow.chars -width 50 -bg #FFFFFF -font splainf -selectbackground #b7d1ff
	
	listbox .searchwindow.userbox -borderwidth 0 -takefocus 1 -bg white -highlightthickness 1 -yscrollcommand ".searchwindow.userbox.ys set"
	
	scrollbar .searchwindow.userbox.ys -command ".searchwindow.userbox yview" -highlightthickness 0 -borderwidth 0 -elementborderwidth 0
	
	frame .searchwindow.selector
	label .searchwindow.selector.search_label -text "[trans search]: " -anchor w
	combobox::combobox .searchwindow.selector.search_combo -editable false -highlightthickness 0 -width 15 -bg #FFFFFF -font splainf 

	foreach i {all nick email} {
		.searchwindow.selector.search_combo list insert end "[trans $i]"
	}
	
	
	if { $config(search) == 0 } {
	.searchwindow.selector.search_combo select 0
	} elseif { $config(search) == 1 } {
		.searchwindow.selector.search_combo select 1
		} elseif { $config(search) == 2 } {
			.searchwindow.selector.search_combo select 2
		}
	label .searchwindow.selector.show_label -text "[trans show]: " -anchor w
	combobox::combobox .searchwindow.selector.show_combo -editable false -highlightthickness 0 -width 15 -bg #FFFFFF -font splainf
	foreach i { Nick Email} {
		.searchwindow.selector.show_combo list insert end $i
	}
	if { $config(show) == 0 } {
	.searchwindow.selector.show_combo select 0
	} elseif { $config(show) == 1 } {
		.searchwindow.selector.show_combo select 1
	}

	
	frame .searchwindow.b
	button .searchwindow.b.search -text "[trans search]"
	button .searchwindow.b.close -text [trans close]  -command "::actionsmenu::closewindow"
	button .searchwindow.b.copycontact -text [trans copycontact] -command "::actionsmenu::copycontact"
	button .searchwindow.b.sendmsg -text [trans sendmsg] -command "::actionsmenu::openwindow"
	
	#############################################################
	# Automatic search by char input			    #
	#############################################################
	bind .searchwindow.chars <Any-Key> "after cancel ::actionsmenu::searchuser;after 200 ::actionsmenu::searchuser"
	

	#############################################################
	
	pack .searchwindow.userbox.ys -side right -fill both
	pack .searchwindow.b.search .searchwindow.b.close -side right -padx 5		
#	pack .searchwindow.l -side top -anchor sw -padx 10 -pady 3
	pack .searchwindow.selector.search_label -side left -anchor sw -padx 10 -pady 3
	pack .searchwindow.selector.search_combo -side left -anchor w
	pack .searchwindow.selector.show_label -side left -anchor sw -padx 10 -pady 3
	pack .searchwindow.selector.show_combo -side left -anchor w
	pack .searchwindow.selector -side top -anchor center -padx 10
	pack .searchwindow.chars -side top -expand false -fill x -padx 10 -pady 3
	pack .searchwindow.userbox -expand true -fill both -padx 10 -pady 10
	pack .searchwindow.b.copycontact -side right -padx 5
	pack .searchwindow.b.sendmsg -side right -padx 5
	pack .searchwindow.b -side bottom -pady 3 -expand false -anchor se
	
	
	bind .searchwindow.userbox <<Button3>> "::actionsmenu::resolve %X %Y"
#	bind .searchwindow.b.close <Escape> "grab release .searchwindow;destroy .searchwindow"
	bind .searchwindow.chars <Return> "::actionsmenu::searchuser"
	bind .searchwindow.b.search <ButtonPress-1> "::actionsmenu::searchuser"
	bind .searchwindow <Escape> "::actionsmenu::closewindow"
	catch {
		raise .searchwindow
		focus .searchwindow.chars
	}
}

proc autosearch { } {
	after 100 "catch { ::actionsmenu::searchuser } "
}

proc searchuser { } {
	variable output [list]

	.searchwindow.userbox delete 0 end
	set charstyped [string tolower [.searchwindow.chars get] ]
	set search [.searchwindow.selector.search_combo get]
	set show [.searchwindow.selector.show_combo get]
	set contacts_FL [list]

	foreach contact [::abook::getAllContacts] {
		if { [string last "FL" [::abook::getContactData $contact lists]] != -1 } {
			lappend contacts_FL $contact
		}
	}

	foreach contact $contacts_FL {
		set y 0
		if {$search == "[trans email]" || $search == "[trans all]"} {
			if { [set result [string last "$charstyped" $contact ] ] != -1} {
				lappend output $contact
				set y 1
			}
		}
		if {$search == "[trans nick]" || ($search == "[trans all]" && $y == 0)} {
			if {[string last "$charstyped" [string tolower [::abook::getNick $contact]]] != -1} {
				lappend output $contact
			}
		}
	}
	if {[llength $output] == 0} {
		 .searchwindow.userbox insert end "[trans nocontact]"
	} else {
		foreach contact $output {
			if {$show == "[trans email]"} {
#				.searchwindow.userbox insert end $contact
				.searchwindow.userbox insert end "$contact ([trans [::MSN::stateToDescription [::abook::getVolatileData $contact State]]])"
			} else {
#				.searchwindow.userbox insert end [::abook::getNick $contact]
				.searchwindow.userbox insert end "[::abook::getNick $contact] ([trans [::MSN::stateToDescription [::abook::getVolatileData $contact State]]])"
			}
		}
	}
}



proc openwindow {} {
	variable output
	set num [.searchwindow.userbox curselection]
	if { [llength $output] != 0 } {
		::amsn::chatUser "[lindex $output $num]"
	}
}


proc resolve { X Y } {
	variable output
	
	set num [.searchwindow.userbox curselection]
	set groupid [ ::guiContactList::getGroupId "[lindex $output $num]" ]
	 
	if { ([llength $output] != 0) && ($num != "")} {
		
		show_umenu [lindex $output $num] $groupid $X $Y
	}
}


proc copycontact {} {
	variable output
	set num [.searchwindow.userbox curselection]
	if { [llength $output] != 0 } {
		clipboard clear
		clipboard append "[lindex $output $num]"
	}
}


proc closewindow {} {
	variable output

	unset output
	grab release .searchwindow
	destroy .searchwindow
}


}
