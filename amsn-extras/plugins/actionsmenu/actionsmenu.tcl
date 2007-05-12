##################################################
#  This plugin implements the actions menu on    #
#  the bottom of the contactlist, as seen in MSN #
# 								                 #
# 	Originally written by  Karel Demeyer, 2005	 #
#   Fixed by Takeshi, 2007						 #
#	Search Contact function by Takeshi			 #
#  ============================================  #
##################################################

#TODO On click collapse 
#

namespace eval ::actionmenu {


	
	proc Init { dir } {
		
		::plugins::RegisterPlugin "actionmenu"
		::actionmenu::RegisterEvent
		::skin::setPixmap actionsbg actionsbg.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap img_expcol actions_expcol.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap img_addcontact actions_addcontact.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap img_find actions_find.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap img_collapsecol actions_collapsecol.gif pixmaps [file join $dir pixmaps]
		after 1000 "catch { ::actionmenu::draw 0 0 }"
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
		$acanvas create text 30 3 -text "I want to..." -anchor nw -tag expand -font sboldf -fill #000075

		$acanvas bind expand <ButtonPress-1> "::actionmenu::redraw $actions"

		#$acanvas bind expand <Enter> "+$acanvas create line 30 18 100 18 -tag exp_line; $acanvas configure -cursor hand2; $acanvas lower exp_line expand"
		#$acanvas bind expand <Leave> "+$acanvas delete exp_line; $acanvas configure -cursor left_ptr"




		AddActionButton $acanvas 15 27 [::skin::loadPixmap img_addcontact] "[trans addacontact]..." "cmsn_draw_addcontact" addcontact

		AddSearchButton $acanvas 15 43 [::skin::loadPixmap img_find] "Search a contact..." "::actionmenu::createsearchwindow" searchcontact

	



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
		$acanvas create text [expr $xcoord + 15] [expr $ycoord -0] -text "Search a contact..." -anchor nw -tag $tag -font $font -fill #000075
		$acanvas bind $tag <ButtonPress-1> "$command"
		$acanvas bind $tag <Enter> " $acanvas configure -cursor hand2; $acanvas lower ${tag}_line $tag ; "
		$acanvas bind $tag <Enter> "+$acanvas create line [expr $xcoord + 15] [expr $ycoord + 14] [expr $xcoord + [expr [font measure $font $text] + 15]]  [expr $ycoord + 14] -tag ${tag}_line; $acanvas configure -cursor hand2; $acanvas lower ${tag}_line $tag "
		$acanvas bind $tag <Leave> "+$acanvas delete ${tag}_line; $acanvas configure -cursor left_ptr"
		
			}
			
	proc createsearchwindow { } {
		
		if { [winfo exists .searchwindow] } { destroy .searchwindow }
	
	
	toplevel .searchwindow
	wm group .searchwindow .
	wm title .searchwindow "Search"
	
	label .searchwindow.l -font sboldf -text "Search"
	entry .searchwindow.chars -width 50 -bg #FFFFFF -bd 0 -font splainf
	focus .searchwindow.chars
	set email [.searchwindow.chars get]
	listbox .searchwindow.userbox -relief flat -borderwidth 0 -height 8 -width 55 -bg white

	pack .searchwindow.userbox -side bottom
	frame .searchwindow.b
	button .searchwindow.b.ok -text "[trans ok]" 
	button .searchwindow.b.cancel -text [trans cancel]  -command "grab release .searchwindow;destroy .searchwindow"

	pack .searchwindow.b.ok .searchwindow.b.cancel -side right -padx 5		
	pack .searchwindow.l -side top -anchor sw -padx 10 -pady 3
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
					set charstyped [string tolower [.searchwindow.chars get] ]
					set contact [::abook::getAllContacts]
				foreach n $charstyped { if { [set result [string last "$charstyped" [::abook::getAllContacts] ] ] != -1} {
					
					
					set rawres [string range "$contact" [expr $result -10] [expr $result +50] ]

					set purgeres [expr [string first "\ " $rawres]+1]
					
					set purgeresbef [string range "$rawres" $purgeres 35 ]
					set aftindex [expr [string last "." $purgeresbef]+3]	
					set res [string range $purgeresbef 0 $aftindex]
					set completeres [::abook::getNick $res]
					#set rawtemp [list]
					.searchwindow.userbox delete "0" "10"
					#.searchwindow.userbox insert end $rawres
					#.searchwindow.userbox insert end $result
					.searchwindow.userbox insert end $res
					
					#searchuser($charstyped)
					.searchwindow.userbox insert end $completeres
					} else { [ .searchwindow.userbox delete "0" "10" ].searchwindow.userbox insert end "No Contact Found" }
				}
			}

}