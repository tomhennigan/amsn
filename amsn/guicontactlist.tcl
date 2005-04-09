# TODO
#
# / translate individuals group and make it always first (DONE - ugly hack ? :|)
# * smiley substitution	
# * support for multiline nicks
# * nickname truncation
# * scrollbar should be removed when not used
# * fix problem when canvas' scrollablearea is smaller then window and you scroll up
# / drag 'n drop contacts for groupchange (DONE - needs some testing though so it's stable enough to not lose contacts :p)
# * make sure everything works on mac/windows (like mousevents on mac for example!)
# * change cursor while dragging



namespace eval ::guiContactList {
	namespace export drawCL
	
	#//////////////////////////////////////////////////////////////////////////////
	# guiContactList (action [id] [varlist])
	# Data Structure for Contact List elements, linked list style :
	# 1 - Element Type		(type) Can be GROUP or CONTACT
	# 4 - Next Element		(nextid)
	# 5 - Previous Element		(previousid)
	#
	# action can be :
	#	get : This method returns the wanted info, 0 if non existent
	#	set : This method sets the variables for the given id, takes 2 arguments (variableid newvalue).
	#	insert : Adds new element, if id = -1, adds at end of list, otherwise adds right after element with given id.
	#	unset : This method removes the given id variables
	#	last : Return id of last element
	#	first : Return id of first element
	#	
	proc guiContactList { action { id "" } { varlist "-1" } } {
		variable type
		variable nextId
		variable previousId

		switch $action {
			get {
				if { [info exists type($id)] } {
					switch $varlist {
						type {
							return $type($id)
						}
						nextId {
							return $nextId($id)
						}
						previousId {
							return $previousId($id)
						}
					}
					# found, return values
				} else {
					# id not found, return 0
					return 0
				}
			}

			set {
				# This overwrites previous vars
				switch [lindex $varlist 0] {
					type {
						set type($id) [lindex $varlist 1]
					} 
					nextId {
						set nextId($id) [lindex $varlist 1]
					} 
					previousId {
						set previousId($id) [lindex $varlist 1]
					} 
				}
			}

			insert {
				if { $id == -1 } {
					
				}
			}

			unset {
				# Lets connect previous and next together
				set nextId($previousId($id)) $nextId($id)
				set previousId($nextId($id)) $previousId($id)
				
				# Now remove it's items
				if { [info exists type($id)] } {
					unset type($id)
				} else {
					status_log "Trying to unset type($id) but do not exist\n" red
				}
				if { [info exists nextId($id)] } {
					unset nextId($id)
				} else {
					status_log "Trying to unset nextId($id) but dosent exist\n" red
				}
				if { [info exists previousId($id)] } {
					unset previousId($id)
				} else {
					status_log "Trying to unset previousId($id) but dosent exist\n" red
				}
			}
		}
	}

	# Draws the contact list, for now in a new windows
	proc createCLWindow {} {
	
		set clcanvas ".contactlist.fr.c"

		if { [winfo exists .contactlist] } {
			raise .contactlist
			drawCL $clcanvas
			return
		}

		set clbox [list 0 0 1000 1000]

		toplevel .contactlist
		wm title .contactlist "[trans title] - [::config::getKey login]"
		frame .contactlist.fr

		
		canvas $clcanvas -width [lindex $clbox 2] -height [lindex $clbox 3] -background white \
			-scrollregion [list 0 0 1000 1000] -xscrollcommand ".contactlist.fr.xs set" -yscrollcommand ".contactlist.fr.ys set"
		scrollbar .contactlist.fr.ys -command ".contactlist.fr.c yview" 
		scrollbar .contactlist.fr.xs -orient horizontal -command ".contactlist.fr.c xview"

		pack .contactlist.fr.ys -side right -fill y
		pack $clcanvas -expand true -fill both
		pack .contactlist.fr

		drawCL $clcanvas
		
		catch {wm geometry .contactlist [::config::getKey wingeometry]}
		#To avoid the bug of window behind the bar menu on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			moveinscreen .contactlist 30
		}
	}

	# This is the main contactList drawing procedure, it clears the canvas and draws a brand new
	# contact list in it's place
	proc drawCL { canvas } {
		# First we delete all the canvas items
		$canvas addtag items all
		$canvas delete items

		#this line should be done with the other skin::setpixmap's 
		::skin::setPixmap back back.gif
		$canvas create image 0 0 -image [::skin::loadPixmap back] -anchor nw -tag backgroundimage

		# Now let's get a contact list
		set contactList [generateCL]

		# Let's draw each element of this list
		set curPos [list 0 0]
		foreach element $contactList {
			# We check the type, and call the appropriate draw function, these can be extended	
			# We got a contact
			if { [lindex $element 0] == "C" } {
				set curPos [drawContact $canvas $element $curPos]
#			# It must be a group title
			} else {
				set curPos [drawGroup $canvas $element $curPos]
			}
		}
		
		#set height of canvas
		set canvaslength [expr [lindex $curPos 1] + 20]

		$canvas configure -scrollregion [list 0 0 1000 $canvaslength]

		#set scrolling bindings for canvas/scrollbar
		bind $canvas <ButtonPress-5> "::guiContactList::scrollCL down $canvaslength"		
		bind $canvas <ButtonPress-4> "::guiContactList::scrollCL up $canvaslength"

		bind .contactlist.fr.ys <ButtonPress-5> "::guiContactList::scrollCL down $canvaslength"
		bind .contactlist.fr.ys <ButtonPress-4> "::guiContactList::scrollCL up $canvaslength"

	}

	#scroll the canvas up/down
	proc scrollCL {direction canvaslength} {
#TODO: remove the implicit use of ".contactlist.fr..c" to make it work in other windows
		if {$direction == "down"} {
			.contactlist.fr.c yview scroll 1 units
			

		} else {
			.contactlist.fr.c yview scroll -1 units
		}
		#here we have to move the background-image
		.contactlist.fr.c coords backgroundimage 0 [expr int([expr [lindex [.contactlist.fr.c yview] 0] * $canvaslength])]

	}
			

	# Draw the contact on the canvas
	proc drawContact { canvas element curPos } {
		set xpos [expr [lindex $curPos 0] + 15]
		set ypos [lindex $curPos 1]
		
		set email [lindex $element 1]

		set state_code [::abook::getVolatileData $email state FLN]
		
		
		if { [::abook::getContactData $email customcolor] != "" } {
			set colour [::abook::getContactData $email customcolor] 
		} else {
			set colour [::MSN::stateToColor $state_code]
		}

		set img [::skin::loadPixmap [::MSN::stateToImage $state_code]]

		if { [::abook::getVolatileData $email MOB] == "Y" && $state_code == "FLN"} {
			set img [::skin::loadPixmap mobile]
		} else {
			set img [::skin::loadPixmap [::MSN::stateToImage $state_code]]
		}
		
		set nicktext [::abook::getDisplayNick $email]

		if {$state_code != "NLN"} {
			set statetext "\([trans [::MSN::stateToDescription $state_code]]\)"

		} else {
			set statetext ""
		}

		set fulltext "$nicktext $statetext"
		
		set xnickpos [expr $xpos + [image width $img] + 5]
		set ynickpos [expr $ypos + [image height $img]/2]

		#Set up underline co-ords
		set xuline1 $xnickpos
		set xuline2 [expr $xuline1 + [font measure splainf $fulltext]]
		set yuline [expr $ynickpos + 1 + [font configure splainf -size] / 2]
		
		$canvas create image $xpos $ypos -image $img -anchor nw \
			-tags [list contact icon $email]

		#if you are not on this contact's list, show the icon
		if {[expr {[lsearch [::abook::getLists $email] RL] == -1}]} {

			set icon [::skin::loadPixmap notinlist]

			$canvas create image [expr $xnickpos -3] $ynickpos -image $icon -anchor w \
				-tags [list contact icon $email]

			set nicknameXpos [expr $xnickpos + [image width $icon]]
		} else {
			set nicknameXpos $xnickpos
		}	


		#call the proc that draws the nickname
			#in the future, this should return the new $ypos or the change of $ypos
		drawNickname $canvas $nicknameXpos $ynickpos $nicktext $statetext $colour $email 


		set grId [getGroupId $email]
		
		#Remove previous bindings
		$canvas bind $email <Enter> ""
		$canvas bind $email <Motion> ""
		$canvas bind $email <Leave> ""
		
		#Add binding for balloon
		if { [::config::getKey tooltips] == 1 } {
			$canvas bind $email <Enter> +[list balloon_enter %W %X %Y "[getBalloonMessage $email $element]"]
			$canvas bind $email <Motion> +[list balloon_motion %W %X %Y "[getBalloonMessage $email $element]"]
			$canvas bind $email <Leave> "+set Bulle(first) 0; kill_balloon"
		}
		
		#Add binding for click / right click (remembering to get config key for single/dbl click on contacts to open chat)
		if { [::config::getKey sngdblclick] } {
			set singordblclick <Button-1>
		} else {
			set singordblclick <Double-Button-1>
		}
		 
		$canvas bind $email <<Button3>> "show_umenu $email $grId %X %Y;"
		$canvas bind $email $singordblclick "::amsn::chatUser $email"
		#Add binding for underline if the skinner use it
		if {[::skin::getKey underline_contact]} {
			$canvas bind $email <Enter> "+$canvas create line $xuline1 $yuline $xuline2 $yuline -fill $colour -tag uline ; $canvas lower uline \
				$email;$canvas configure -cursor hand2"
			$canvas bind $email <Leave> "+$canvas delete uline;$canvas configure -cursor left_ptr"
		} else {
			$canvas bind $email <Enter> "+$canvas configure -cursor hand2"
			$canvas bind $email <Leave> "+$canvas configure -cursor left_ptr"
		}

#TODO		#drag bindings; needs macification ;)
		$canvas bind $email <ButtonPress-2> "::guiContactList::contactPress $email $canvas"
		$canvas bind $email <B2-Motion> "::guiContactList::contactMove $email $canvas"
		$canvas bind $email <ButtonRelease-2> "::guiContactList::contactReleased $email $canvas"

		return [list [expr $xpos - 15] [expr $ypos + [image height $img] + [::skin::getKey buddy_ypad]]]
	}
	


	#procedure that draws the nickname, substitutes smileys/multilines, truncates
	# should return the new yposition (as it can be more because of multi-lines
	proc drawNickname {canvas xcoord ycoord nicktext statetext colour email} {
#TODO: a lot of work ;)
		#set maxwidth foo

		$canvas create text $xcoord $ycoord -text "$nicktext $statetext"\
			-anchor w -fill $colour -font splainf -tags [list contact $email]
	}





	#Contact dragging procs
	proc contactPress {email canvas} {
		global OldX
		global OldY
		#store old coordinates
		set OldX [winfo pointerx .]
		set OldY [winfo pointery .]
	}
	proc contactMove {email canvas} {
		global OldX
		global OldY
		#change coordinates 
		set NewX [winfo pointerx .]
		set NewY [winfo pointery .]
		set ChangeX [expr $OldX - $NewX]
		set ChangeY [expr $OldY - $NewY]

		$canvas move $email [expr $ChangeX * -1] [expr $ChangeY * -1]

		set OldX [winfo pointerx .]
		set OldY [winfo pointery .]

		}
	proc contactReleased {email canvas} {

		#kill the balloon if it came up, otherwise itjust stays
		set Bulle(first) 0; kill_balloon


		#first see what's the coordinates of the icon
		set iconYCoord [lindex [$canvas coords $email] 1]


		#now we have to find the group whose ycoord is the first less then this coord

		#beginsituation: group to move to is group where we began
		set groupID [getGroupId $email]

		set groupList [getGroupList]

		#cycle to the list of groups and select the group where the user drags to
		foreach group $groupList {
			#get the group ID
			set grId [lindex $group 0]

			#Only go for groups that are actually drawn on the list
			if { [$canvas coords gid_$grId] != ""} {
				#get the coordinates of the group
				set grYCoord [lindex [$canvas coords gid_$grId] 1]

				#this +5 is to make dragging a contact on a group's name\
				 or 5 pixels above the group's name possible
				if {$grYCoord <= [expr $iconYCoord + 5]} {
					set groupID $grId
				}
			}
		}

		#remove the contact from the canvas as it's gonna be redrawn on the right place
		$canvas delete $email

		#if user wants to move to a place that's not possible, just leave the contact\
		 in the current group (other words: "don't do anything")
		if {$groupID != "offline" && $groupID != "mobile" && $groupID != "" && $groupID != [getGroupId $email]} { 
			#move the contact
			set oldgrId [getGroupId $email]
			status_log "Gonna move $email from $oldgrId to $groupID"
			::groups::menuCmdMove $groupID $oldgrId $email
#TODO: how to code this better (without the 'after') ?
			after 1000 ::guiContactList::drawCL $canvas
		} else {
			::guiContactList::drawCL $canvas
		}

	}





	# Draw the group title on the canvas
	proc drawGroup { canvas element curPos } {
		set xpos [lindex $curPos 0]
		set ypos [lindex $curPos 1]
		if { ![::config::getKey nogap] } {
			set ypos [expr $ypos + 20]
		}
		
		# Let's setup the right image (expanded or contracted)
		if { [::groups::IsExpanded [lindex $element 0]] } {
			set xpad [::skin::getKey contract_xpad]
			set ypad [::skin::getKey contract_ypad]
			set img [::skin::loadPixmap contract]
			set groupcolor [::skin::getKey groupcolorextend]
		} else {
			set xpad [::skin::getKey expand_xpad]
			set ypad [::skin::getKey expand_ypad]
			set img [::skin::loadPixmap expand]
			set groupcolor [::skin::getKey groupcolorcontract]
		}
		#Get the number of user for this group
		set groupcount [getGroupCount $element]
		
		#Store group name and groupcount as string, for measuring length of underline
		set groupheader "[lindex $element 1] ($groupcount)"
		
		#Setup co-ords for underline on hover
		set xuline1 [expr $xpos + [image width $img] + (2*$xpad)]
		set xuline2 [expr $xuline1 + [font measure sboldf $groupheader]]
		set yuline [expr $ypos + [font configure sboldf -size] + 3 ]
		
		#set the group id, our ids are integers and tags can't be so add gid_ to start
		set gid gid_[lindex $element 0]
		
		# First we draw our little group toggle button
		$canvas create image [expr $xpos + $xpad] $ypos -image $img -anchor nw \
			-tags [list group toggleimg $gid]
		
		$canvas create text $xuline1 $ypos -text $groupheader -anchor nw \
			-fill $groupcolor -font sboldf -tags [list group title $gid]
		
		#Remove previous bindings
		$canvas bind $gid <Enter> ""
		$canvas bind $gid <Motion> ""
		$canvas bind $gid <Leave> ""

		#Create mouse event bindings
		$canvas bind $gid <<Button1>> "::groups::ToggleStatus [lindex $element 0];guiContactList::drawCL $canvas"
		$canvas bind $gid <<Button3>> "::groups::GroupMenu $gid %X %Y"


		$canvas bind $gid <Enter> "+$canvas create line $xuline1 $yuline $xuline2 $yuline -fill $groupcolor -tag uline ; $canvas lower uline \
			$gid;$canvas configure -cursor hand2"
		$canvas bind $gid <Leave> "+$canvas delete uline;$canvas configure -cursor left_ptr"
		
		return [list $xpos [expr $ypos + 20]]
	}
	
	#Get the group count
	#Depend if user in status/group/hybrid mode
	proc getGroupCount {element} {
		set mode [::config::getKey orderbygroup]
		if { $mode == 0} {
			#Status mode
			set groupcount $::groups::uMemberCnt([lindex $element 0])
		}  elseif { $mode == 1} {
			#Group mode
			set groupcount $::groups::uMemberCnt_online([lindex $element 0])/$::groups::uMemberCnt([lindex $element 0])
		} elseif { $mode == 2} {
			#Hybrid mode
			if {[lindex $element 0] == "offline" || [lindex $element 0] == "mobile"} {
				set groupcount $::groups::uMemberCnt([lindex $element 0])
			} else {
				set groupcount $::groups::uMemberCnt_online([lindex $element 0])	
			}
		}
		return $groupcount
	}
	# This procedure returns the contactList having a layout 
	# exactly as it should be drawn by the GUI
	proc generateCL {} {
		set contactList [list]
		
		# First let's get our groups
		set groupList [getGroupList]

		# Now our contacts
		set userList [::MSN::sortedContactList]
		# Create new list of lists with [email groupitsin]
		set userGroupList [list]
		foreach user $userList {
			lappend userGroupList [list $user [getGroupId $user]]
		}
		
		# Go through each group, and insert the contacts in a new list that will represent our GUI view
		foreach group $groupList {
			set grId [lindex $group 0]
			
			# if group is empty and remove empty groups is set (or this is Individuals group) then skip this group
			if { ($grId == 0 || ([::config::getKey removeempty] && $grId != "offline" && $grId != "mobile")) && [getGroupCount $group] == 0 } {
				continue
			}

			# First we append the group
			lappend contactList $group

			if { [::groups::IsExpanded [lindex $group 0]] != 1 } {
				continue
			}
			
			# We check for each contact
			set idx 0
			foreach user $userGroupList {
				set hisgroupslist [lindex $user 1]
				# If this contact matches this group, let's add him
				if { [lsearch $hisgroupslist [lindex $group 0]] != -1 } {
					lappend contactList [list "C" [lindex $user 0]]
					# If he only belongs to this group, remove him from initial list
					if { [llength $hisgroupslist] == 1 } {
						lreplace $userGroupList $idx $idx
					}
				}
				incr idx
			}
		}

		return $contactList
	}

	# Function that returns a list of the groups, depending on the selected view mode (Status, Group, Hybrid)
	# 
	# List looks something like this :
	# We have a list of these lists :
	# [group_state gid group_name [listofmembers]]
	# listofmembers is like this :
	# [email redraw_flag]
	proc getGroupList {} {
		set mode [::config::getKey orderbygroup]
		
		# Online/Offline mode
		if { $mode == 0 } {

			if {[::config::getKey showMobileGroup] == 1} {
				set groupList [list [list "online" [trans online]] [list "mobile" [trans mobile]] [list "offline" [trans offline]]]
			} else {
				set groupList [list [list "online" [trans online]] [list "offline" [trans offline]]]
			}
		# Group mode
		} elseif { $mode == 1 || $mode == 2} {
			set groupList [list]
			# We get the array of groups from abook
			array set groups [::abook::getContactData contactlist groups]
			#Convert to list
			set g_entries [array get groups]
			set items [llength $g_entries]
			for {set idx 0} {$idx < $items} {incr idx 1} {
				set gid [lindex $g_entries $idx]
				incr idx 1
				#jump over the individuals group as it should not be\
				 sorted alphabetically and allways be first
				if {$gid == 0} {
					continue
				} else {
					set name [lindex $g_entries $idx]
					lappend groupList [list $gid $name]
				}
			}
			#Sort the list alphabetically
			if {[::config::getKey ordergroupsbynormal]} {
				set groupList [lsort -dictionary -index 1 $groupList]
			} else {
				set groupList [lsort -decreasing -dictionary -index 1 $groupList]
			}

			#Now we have to add the "individuals" group, translated and as first
#TODO				#maybe someone should do this a better way, but I had\
				 problems with the 'linsert' command
			set groupList "\{0 \{[trans nogroup]\}\} $groupList"


		}
		
		# Hybrid Mode, we add mobile and offline group
		if { $mode == 2 } {
			if {[::config::getKey showMobileGroup] == 1} {
				lappend groupList [list "mobile" [trans mobile]]
			}
			lappend groupList [list "offline" [trans offline]]
		}
		
		return $groupList
	}

	# Function that returns the appropriate GroupID(s) for the user
	# this GroupID depends on the group view mode selected
	proc getGroupId { email } {
		set mode [::config::getKey orderbygroup]
		
		set status [::abook::getVolatileData $email state FLN]
		
		# Online/Offline mode
		if { $mode == 0 } {
			if { $status == "FLN" } {
				if { [::abook::getVolatileData $email MOB] == "Y" && [::config::getKey showMobileGroup] == 1} {
					return "mobile"
				} else {
					return "offline"
				}
			} else {
				return "online"
			}
		
		# Group mode
		} elseif { $mode == 1} {
			return [::abook::getGroups $email]
		}
		
		# Hybrid Mode, we add offline group
		if { $mode == 2 } {
			if { $status == "FLN" } {
				if { [::abook::getVolatileData $email MOB] == "Y" && [::config::getKey showMobileGroup] == 1} {
					return "mobile"
				} else {
					return "offline"
				}
			} else {
				return [::abook::getGroups $email]
			}
		}
	}
	
	#Here we create the balloon message
	#And we add the binding to the canvas item
	proc getBalloonMessage {email element} {
	 	
	 	#Get variables
	 	set not_in_reverse [expr {[lsearch [::abook::getLists $email] RL] == -1}]
	 	set state_code [::abook::getVolatileData $email state FLN]
	 	
	 	#If user is not in list, add it to the balloon
		if {$not_in_reverse} {
			set balloon_message2 "\n[trans notinlist]"
		} else {
			set balloon_message2 ""
		}
		
		#If order in status mode, show the group of the contact in the balloon
		if {[::config::getKey orderbygroup] == 0} {
			set groupname [::abook::getGroupsname $email]
			set balloon_message3 "\n[trans group] : $groupname"
		} else {
			set balloon_message3 ""
		}
		
		#If the status is offline, get the last time he was online
		if {$state_code == "FLN"} {
			set balloon_message4 "\n[trans lastseen] : [::abook::dateconvert "[::abook::getContactData $email last_seen]"]"
		} else {
			set balloon_message4 ""
		}
		
		#Define the final balloon message
		set balloon_message "[string map {"%" "%%"} [::abook::getNick $email]]\n$email\n[trans status] : [trans [::MSN::stateToDescription $state_code]] $balloon_message2 $balloon_message3 $balloon_message4\n[trans lastmsgedme] : [::abook::dateconvert "[::abook::getContactData $email last_msgedme]"]"
		return $balloon_message	
	}
	
}
