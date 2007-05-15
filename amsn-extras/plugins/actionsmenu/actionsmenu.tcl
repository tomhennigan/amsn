##################################################
#  This plugin implements the actions menu on    #
#  the bottom of the contactlist, as seen in MSN #
# 								 #
# 	Originally written by  Karel Demeyer, 2005 #
#   Fixed by Takeshi, 2007				 #
#   Search Contact function by Takeshi, Square87 #
#  ============================================  #
##################################################

#TODO Translation 
#TODO Right click behavior
#TODO plugin update 

namespace eval ::actionmenu {
	variable dir

	
	proc Init { dir } {

		global HOME HOME2
		#set ::actionmenu::dir $dir
		set langdir [append dir "/lang"]
		load_lang en $langdir
		load_lang [::config::getGlobalKey language] $langdir

		
		::plugins::RegisterPlugin "actionmenu"

		::actionmenu::RegisterEvent
		

		#if {[string equal $::version "0.94"]} {

		#::skin::setPixmap actionsbg [file join $dir pixmaps actionsbg.png]
		
		#::skin::setPixmap img_expcol [file join $dir pixmaps actions_expcol.gif]

		#::skin::setPixmap img_addcontact [file join $dir pixmaps actions_addcontact.gif]

		#::skin::setPixmap img_find [file join $dir pixmaps actions_find.gif]

		#::skin::setPixmap img_collapsecol [file join $dir pixmaps actions_collapsecol.gif]
		#} else {
		::skin::setPixmap actionsbg actionsbg.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]

		::skin::setPixmap img_expcol actions_expcol.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]

		::skin::setPixmap img_addcontact actions_addcontact.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]

		::skin::setPixmap img_find actions_find.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]

		::skin::setPixmap img_collapsecol actions_collapsecol.png pixmaps [file join "$HOME2/plugins/actionsmenu" pixmaps]

		#}
		
		after 2000 "catch { ::actionmenu::redraw 0 }"
			}
	
	proc RegisterEvent {} {

		::plugins::RegisterEvent actionmenu ContactListColourBarDrawn draw		
	}
		
			proc DeInit { } {
		#When the plugin gets unloaded, remove the actions button if existing
		set actions .main.actions
		if { [winfo exists $actions]} {
			destroy $actions
		}
	}	

	proc draw { event evpar } {
		
		if { $event !=00 } { upvar 2 $evPar vars } {
	
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
		$acanvas create text 30 3 -text "[trans iwantto]..." -anchor nw -tag expand -font sboldf -fill #000075

		$acanvas bind expand <ButtonPress-1> "::actionmenu::redraw $actions"

		#$acanvas bind expand <Enter> "+$acanvas create line 30 18 100 18 -tag exp_line; $acanvas configure -cursor hand2; $acanvas lower exp_line expand"
		#$acanvas bind expand <Leave> "+$acanvas delete exp_line; $acanvas configure -cursor left_ptr"




		AddActionButton $acanvas 15 27 [::skin::loadPixmap img_addcontact] "[trans addacontact]..." "cmsn_draw_addcontact" addcontact

		AddSearchButton $acanvas 15 43 [::skin::loadPixmap img_find] "[trans searchcontact]..." "::actionmenu::createsearchwindow" searchcontact

	



		pack configure $acanvas -side top -fill both -expand true
		pack configure $actions -side bottom -fill x 
		update idletasks
	}
}

	proc redraw { actions } {
			destroy $actions
			
			set actions .main.actions
			#if { [winfo exists $actions]} {
			#destroy $actions
			#}
			frame $actions -relief flat -borderwidth 0
			set acanvas .main.actions.canvas
			set bgcolor [::skin::getKey mainwindowbg]
			canvas $acanvas -bg $bgcolor -height 20 -highlightthickness 0 -relief flat -borderwidth 0
			$acanvas  create image 0 0 -image [::skin::loadPixmap actionsbg] -anchor nw -tag expand
			$acanvas create image 0 0 -image [::skin::loadPixmap img_collapsecol] -anchor nw -tag expand
			$acanvas bind expand <ButtonPress-1> "::actionmenu::draw 0 0"
			pack configure $acanvas -side top -fill both -expand true
			pack configure $actions -side bottom -fill x
	}


	proc AddActionButton {acanvas xcoord ycoord img text command tag} {

		set font splainf
		$acanvas create image $xcoord $ycoord -image $img -anchor nw -tag $tag
		$acanvas create text [expr $xcoord + 15] [expr $ycoord -3] -text $text -anchor nw -tag $tag -font $font -fill #000075

		$acanvas bind $tag <ButtonPress-1> "$command"
		$acanvas bind $tag <Enter> "+$acanvas create line [expr $xcoord + 15] [expr $ycoord + 12] [expr $xcoord + [expr [font measure $font $text] + 15]]  [expr $ycoord + 12] -tag ${tag}_line; $acanvas configure -cursor hand2; $acanvas lower ${tag}_line $tag "
		$acanvas bind $tag <Leave> "+$acanvas delete ${tag}_line; $acanvas configure -cursor left_ptr"
	}
	
	proc AddSearchButton { acanvas xcoord ycoord img text command tag } {
		set font splainf
	
		$acanvas create image $xcoord $ycoord -image $img -anchor nw
		$acanvas create text [expr $xcoord + 15] [expr $ycoord -0] -text "[trans searchcontact]..." -anchor nw -tag $tag -font $font -fill #000075
		$acanvas bind $tag <ButtonPress-1> "$command"
		$acanvas bind $tag <Enter> " $acanvas configure -cursor hand2; $acanvas lower ${tag}_line $tag ; "
		$acanvas bind $tag <Enter> "+$acanvas create line [expr $xcoord + 15] [expr $ycoord + 14] [expr $xcoord + [expr [font measure $font $text] + 15]]  [expr $ycoord + 14] -tag ${tag}_line; $acanvas configure -cursor hand2; $acanvas lower ${tag}_line $tag "
		$acanvas bind $tag <Leave> "+$acanvas delete ${tag}_line; $acanvas configure -cursor left_ptr"
		
			}
			
	proc createsearchwindow { } {
		
		if { [winfo exists .searchwindow] } { destroy .searchwindow }
	
	
	toplevel .searchwindow
	wm group .searchwindow .
	wm title .searchwindow "[trans search]"
	
	label .searchwindow.l -font sboldf -text "[trans search]"
	entry .searchwindow.chars -width 50 -bg #FFFFFF -bd 0 -font splainf
	focus .searchwindow.chars 
	listbox .searchwindow.userbox -relief flat -borderwidth 0 -height 8 -width 55 -bg white

	frame .searchwindow.search
	label .searchwindow.search.label -text "[trans search]: " -anchor w
	
	combobox::combobox .searchwindow.search.combo -editable false -highlightthickness 0 -width 16 -bg #FFFFFF -font splainf 
	#foreach i { All Nick Email }�{ 
	#	.searchwindow.search.combo list insert end $i 
	#	}
	
	#radiobutton .searchwindow.search.r1 -highlightthickness 0 -width 5 -bg #FFFFFF -font splainf -text All 
	#radiobutton .searchwindow.search.r2 -highlightthickness 0 -width 10 -font splainf -text Nick
	#radiobutton .searchwindow.search.r3 -highlightthickness 0 -width 15 -font splainf -text Email
	
	#grid .r1 -row0 -column 2 
	#grid .r2 -row0 -column 1
	#grid .r3 -row0 -column 0
	
	foreach i {all nick email} {
		.searchwindow.search.combo list insert end "[trans $i]"
	}
	.searchwindow.search.combo select 0


	frame .searchwindow.show
	label .searchwindow.show.label -text "[trans show]: " -anchor w
	combobox::combobox .searchwindow.show.combo -editable false -highlightthickness 0 -width 16 -bg #FFFFFF -font splainf
	foreach i { Nick Email} {
		.searchwindow.show.combo list insert end $i
	}
	.searchwindow.show.combo select 1

	pack .searchwindow.userbox -side bottom
	frame .searchwindow.b
	button .searchwindow.b.ok -text "[trans ok]" 
	button .searchwindow.b.cancel -text [trans cancel]  -command "grab release .searchwindow;destroy .searchwindow"

	pack .searchwindow.b.ok .searchwindow.b.cancel -side right -padx 5		
	pack .searchwindow.l -side top -anchor sw -padx 10 -pady 3
	
	pack .searchwindow.search.combo -side right -anchor w
	#grid rowconfigure . { 0 } -weight 1
	#grid columnconfigure . { 0 1 2 } -weight 1
	
	pack .searchwindow.search.label -side left -anchor sw -padx 10 -pady 3
	pack .searchwindow.search -anchor w -padx 16
	pack .searchwindow.show.combo -side right -anchor w
	pack .searchwindow.show.label -side left -anchor sw -padx 10 -pady 3
	pack .searchwindow.show -anchor w -padx 10
	pack .searchwindow.chars -side top -expand true -fill x -padx 10 -pady 3
	pack .searchwindow.b -side top -pady 3 -expand true -anchor se

	
	bind .searchwindow.chars <Return> "::actionmenu::searchuser \"$[.searchwindow.chars get]\" "
	bind .searchwindow.b.ok <ButtonPress-1> "::actionmenu::searchuser \"$[.searchwindow.chars get]\" "
	

}

proc searchuser { charstyped } {
	global result		
				
	trysearch result
	#set result [expr $result +1]
	#trysearch result	
	
	#	update 
}

proc trysearch { result } {
	.searchwindow.userbox delete 0 end
	set charstyped [string tolower [.searchwindow.chars get] ]
	set search [.searchwindow.search.combo get]
	set show [.searchwindow.show.combo get]
	set s 0
	set y 0
	set contacts_FL [list]

	foreach contact [::abook::getAllContacts] {
		if { [string last "FL" [::abook::getContactData $contact lists]] != -1 } {
			lappend contacts_FL $contact
		}
	}

	foreach contact [lindex $contacts_FL] {
		if {$search == "[trans email]" || $search == "[trans all]"} {
			if { [set result [string last "$charstyped" $contact ] ] != -1} {
	
				if {$show == "[trans email]"} {
					.searchwindow.userbox insert end $contact
				} else {
					.searchwindow.userbox insert end [::abook::getNick $contact]
				}
				set s 1
				set y 1
			}
		}
		if {$search == "[trans nick]" || ($search == "[trans all]" && $y == 0)} {
			if {[string last "$charstyped" [string tolower [::abook::getNick $contact]]] != -1} {
				if {$show == "[trans email]"} {
					.searchwindow.userbox insert end $contact
				} else {
					.searchwindow.userbox insert end [::abook::getNick $contact]
				}
				set s 1
			}
		}
		set y 0
	}
	if {$s == 0} {
		 .searchwindow.userbox insert end "[trans nocontact]"
	}
}

}