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

		frame .contactlist.fr
		
		canvas $clcanvas -width [lindex $clbox 2] -height [lindex $clbox 3] -background white \
			-scrollregion $clbox -xscrollcommand ".contactlist.fr.xs set" -yscrollcommand ".contactlist.fr.ys set"
		scrollbar .contactlist.fr.ys -command ".contactlist.fr.c yview" 
		scrollbar .contactlist.fr.xs -orient horizontal -command ".contactlist.fr.c xview"
				
		pack .contactlist.fr.ys -side right -fill y
		pack $clcanvas -expand true -fill both
		pack .contactlist.fr

		drawCL $clcanvas
	}

	# This is the main contactList drawing procedure, it clears the canvas and draws a brand new
	# contact list in it's place
	proc drawCL { canvas } {
		# First we delete all the canvas items
		$canvas addtag items all
		$canvas delete items

		#Background image goes here
		set bgimg [image create photo -file "" -format gif]
		
		$canvas create image 0 0 -image [::skin::loadPixmap back] -anchor nw

		# Now let's get a contact list
		set contactList [generateCL]

		# Let's draw each element of this list
		set curPos [list 20 20]
		foreach element $contactList {
			# We check the type, and call the appropriate draw function, these can be extended	
			# We got a contact
			if { [lindex $element 0] == "C" } {
				set curPos [drawContact $canvas $element $curPos]
			# It must be a group title
			} else {
				set curPos [drawGroup $canvas $element $curPos]
			}
		}
	}

	# Draw the contact on the canvas
	proc drawContact { canvas element curPos } {
		set xpos [expr [lindex $curPos 0] + 15]
		set ypos [lindex $curPos 1]
		
		set email [lindex $element 1]

		set state_code [::abook::getVolatileData $email state FLN]
		
		set colour [::MSN::stateToColor $state_code]

		set img [::skin::loadPixmap [::MSN::stateToImage $state_code]]
		
		set text "[::abook::getContactData $email nick] \([trans [::MSN::stateToDescription $state_code]]\)"
		
		$canvas create image $xpos $ypos -image $img -anchor nw \
			-tags [list contact icon $email]
		
		$canvas create text [expr $xpos + [image width $img] + 5] [expr $ypos + [image height $img]/2] -text $text -anchor w \
			-fill $colour -font splainf -tags [list contact $email]
		set grId [getGroupId $email]
		$canvas bind $email <<Button3>> "show_umenu $email $grId %X %Y;"
			
		return [list [expr $xpos - 15] [expr $ypos + [image height $img] + 3]]
	}

	
	# Draw the group title on the canvas
	proc drawGroup { canvas element curPos } {
		set xpos [lindex $curPos 0]
		set ypos [expr [lindex $curPos 1] + 20]
		
		# Let's setup the right image (expanded or contracted)
		if { [::groups::IsExpanded [lindex $element 0]] } {
			set xpad [::skin::getKey contract_xpad]
			set ypad [::skin::getKey contract_ypad]
			set img [::skin::loadPixmap contract]
		} else {
			set xpad [::skin::getKey expand_xpad]
			set ypad [::skin::getKey expand_ypad]
			set img [::skin::loadPixmap expand]
		}
		# First we draw our little group toggle button
		$canvas create image [expr $xpos + $xpad] $ypos -image $img -anchor nw \
			-tags [list group toggleimg [lindex $element 1]]

		$canvas create text [expr $xpos + [image width $img] + (2*$xpad)] $ypos -text [lindex $element 1] -anchor nw \
			-fill darkblue -font sboldf -tags [list group title [lindex $element 1]]
		
		set gid [lindex $element 1]
		$canvas bind $gid <Button1-ButtonRelease> "::groups::ToggleStatus [lindex $element 0];guiContactList::createCLWindow"
		return [list $xpos [expr $ypos + 20]]
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
			set groupList [list [list "online" "online"] [list "offline" "offline"]]
		
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
				set name [lindex $g_entries $idx]
				lappend groupList [list $gid $name]
			}
		}
		
		# Hybrid Mode, we add offline group
		if { $mode == 2 } {
			lappend groupList [list "offline" "offline"]
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
				return "offline"
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
				return "offline"
			} else {
				return [::abook::getGroups $email]
			}
		}
	}

	
}
