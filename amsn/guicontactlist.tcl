# TODO
#
# * set right mousewheel bindings (windows/mac)
#
# * better click-on-contact bindings, now in all cases a chatwindow comes up, also for offline/mobile users
#
# * redraw on skinchange
#
# * scroll the canvas while dragging if you come near to the border -> heavy one :|
#
# * change cursor while dragging (should we ?)
#
# * background doesn't move when using the scrollbar
#   FIX: add an input to scrolled window as a command that should be run after a scroll has been done (then we don't need to do this in scrollCL neither)
#
# * animated smileys on CL -> I hope this is possible easily with TkCxImage?
#
# * draw tooltips on creation
#
# ... check the "TODO" items in the comments ;) .. there are quite some ;)


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


	# Draws the contact list, for now in a new window
	proc createCLWindow {} {
	global tcl_platform

		set clcanvas ".contactlist.fr.c"

		if { [winfo exists .contactlist] } {
			raise .contactlist
			drawCL $clcanvas
			return
		}

		::Event::registerEvent contactDataChange abook ::guiContactList::userDataChanged

		set clbox [list 0 0 2000 1500]

		toplevel .contactlist
		wm title .contactlist "[trans title] - [::config::getKey login]"

		#color should be skinnable:
#TODO: feed ScrolledWindow a command for when scrolling
		ScrolledWindow .contactlist.fr -auto vertical -scrollbar vertical -bg white -bd 0

#TODO:		#color should be skinnable:
		canvas $clcanvas -width [lindex $clbox 2] -height [lindex $clbox 3] -background white

		.contactlist.fr setwidget $clcanvas
		pack .contactlist.fr

		#Before drawing the CLcanvas, we set up the array with the parsed nicknames
		createNicknameArray

		#'after' is needed so the window size can be measured right
		after 1 ::guiContactList::drawCL $clcanvas

#TODO		#scrollbindings: make 'm work for every platform !
#		 scrolledwindow should be feeded a command that moves the background 
#		 so it's also at the right place when the bar is dragged

		#MAC classic/osx and windows
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
#TODO: fox mac bindings -> Jerome's job ;)
		
		bind $canvas <MouseWheel> {
			%W yview scroll [expr {- (%D)}] units ;
			$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]
		}
			bind [winfo parent $canvas].vscroll <MouseWheel> {
			%W yview scroll [expr {- (%D)}] units ;
			$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]  
		}

		} elseif {$tcl_platform(platform) == "windows"} {
#TODO: fox mac bindings -> Arieh's job ;)
			bind $clcanvas <MouseWheel> "::guiContactList::scrollCL $clcanvas [expr {- (%D)}]"
			bind [winfo parent $clcanvas].vscroll <MouseWheel> "::guiContactList::scrollCL $clcanvas [expr {- (%D)}]"

		} else {
			bind $clcanvas <ButtonPress-5> "::guiContactList::scrollCL $clcanvas down"		
			bind $clcanvas <ButtonPress-4> "::guiContactList::scrollCL $clcanvas up"
#TODO: remove implicit use ..
			bind [winfo parent $clcanvas].vscroll <ButtonPress-5> "::guiContactList::scrollCL $clcanvas down"
			bind [winfo parent $clcanvas].vscroll <ButtonPress-4> "::guiContactList::scrollCL $clcanvas up"
		}

		catch {wm geometry .contactlist [::config::getKey wingeometry]}
		#To avoid the bug of window behind the bar menu on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			moveinscreen .contactlist 30
		}
	}

	# This is the main contactList drawing procedure, it clears the canvas and draws a brand 
	# new contact list in it's place
	proc drawCL { canvas } {
		#we don't need this anymore when drawing is finished .; so we'll unset it
		global groupDrawn
		global OnTheMove

		# First we delete all the canvas items
		$canvas addtag items all
		$canvas delete items

#TODO:		#this line should be done with the other skin::setpixmap's 
		::skin::setPixmap back back.gif
		$canvas create image 0 0 -image [::skin::loadPixmap back] -anchor nw -tag backgroundimage

		# Now let's get a contact list
		set contactList [generateCL]

		#Before drawing we set the "we are draggin, sir" variable on 0
		set OnTheMove 0

		# Let's draw each element of this list
		set curPos [list 0 10]
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
		
		#remove unused vars; groupDrawn only needed when drawing contacts
		unset groupDrawn

		#set height of canvas
		set canvaslength [expr [lindex $curPos 1] + 20]
		$canvas configure -scrollregion [list 0 0 2000 $canvaslength]

		#on resizing the canvas needs to be redrawn so the truncation is right
		bind $canvas <Configure> "::guiContactList::drawCL $canvas"

		#make sure after redrawing the bgimage is on the right place
		$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]

	}

		

	# Draw a contact on the canvas
	proc drawContact { canvas element curPos } {
		#we need to know what group we are drawing in
		global groupDrawn
		#we are gonna get the parsed nicknames out of the array created
		global nicknameArray

		#set all the info needed for drawing, $xpos and $ypos shouldn't be altered,
		# $xnickpos and $ynickpos are used for this purpose

		set xpos [expr [lindex $curPos 0] + 15]
		set ypos [lindex $curPos 1]
		
		set email [lindex $element 1]
		set grId $groupDrawn

		# the tag can't be just $email as users can be in more then one group
		set tag "_$email"; set tag "$grId$tag"

		set state_code [::abook::getVolatileData $email state FLN]
		
		if { [::abook::getContactData $email customcolor] != "" } {
			set nickcolour [::abook::getContactData $email customcolor] 
		} else {
			set nickcolour [::MSN::stateToColor $state_code]
		}

#TODO: hovers for these
		if { [::abook::getVolatileData $email MOB] == "Y" && $state_code == "FLN"} {
			set img [::skin::loadPixmap mobile]
		} else {
		

			set img [::skin::loadPixmap [::MSN::stateToImage $state_code]]
		}
#TODO: skinsetting to have buddypictures in their place (this is default in MSN7!)
#	with a pixmap border and also status-emblem overlay in bottom right corner

		
			
		
		
		set parsednick $nicknameArray("$email")

		set nickstatespacing 0
		set statetext ""
		if {$state_code != "NLN"} {
#TODO: skinsetting for the spacing between nicknames and the status
			set nickstatespacing 5
			set statetext "\([trans [::MSN::stateToDescription $state_code]]\)"
		}
#TODO: a skinsetting for state-colour
		set statecolour grey
		set statewidth [font measure splainf $statetext]



#TODO: skin setting to draw buddypicture; statusicon should become inoc + status overlay
#like:	draw icon or small puddypicture
#	overlay it with the status-emblem

		#draw status-icon
		$canvas create image $xpos $ypos -image $img -anchor nw \
			-tags [list contact icon $tag]

		set hoversquarex1 [expr $xpos + [image width $img] + 3]
		set hoversquarey1 [expr $ypos - 2]

		#set the beginning coords for the next drawings
		set xnickpos [expr $xpos + [image width $img] + 5]
		set ynickpos [expr $ypos + [image height $img]/2]

		#if you are not on this contact's list, show the notification icon
		if {[expr {[lsearch [::abook::getLists $email] RL] == -1}]} {

			set icon [::skin::loadPixmap notinlist]

			$canvas create image [expr $xnickpos -3] $ynickpos -image \
			 [::skin::loadPixmap notinlist] -anchor w -tags [list contact icon $tag]

			set xnickpos [expr $xnickpos + [image width $icon]]
		}

		#Now we're gonna draw the nickname itself

		set underlinst [list [list 0 0 0 black]]

		set maxwidth [winfo width .contactlist.fr.c]
		set hoversquarex2 [expr $maxwidth - 2]

		set ellips "..."

		#leave some place for the statustext, the elipsis (...) and the spacing + spacing of border
		set maxwidth [expr $maxwidth - $statewidth - [font measure splainf $ellips] - $nickstatespacing - 5]

		#we can draw as long as the line isn't full
		set linefull 0

		set textheight [expr [font configure splainf -size]/2 ]

		#this is the var for the y-change
		set ychange [image height $img]

		set relnickcolour $nickcolour
		set relxnickpos $xnickpos

		foreach unit $parsednick {
			if {[lindex $unit 0] == "text"} {

				#check if we are still allowed to write text
				if {$linefull} {continue}

				#store the text as a string
				set textpart [lindex $unit 1]

				#check if it's really containing text
				if {$textpart == ""} {continue}

				#check if text is not too long and should be truncated, then\
				 first truncate it and restore it in $textpart and set the linefull
				if {[expr $relxnickpos + [font measure splainf $textpart]] > $maxwidth} {
					set textpart [::guiContactList::truncateText $textpart [expr $maxwidth - $relxnickpos]]
					set textpart "$textpart$ellips"

					#This line is full, don't draw anything anymore before we start a new line
					set linefull 1
				}

				#draw the text
				$canvas create text $relxnickpos $ynickpos -text $textpart -anchor w\
				-fill $relnickcolour -font splainf -tags [list contact $tag nicktext]
				set textwidth [font measure splainf $textpart]

				#append underline coords
				set yunderline [expr $ynickpos + $textheight + 1]
				lappend underlinst [list $relxnickpos $yunderline $textwidth $relnickcolour]
				#change the coords
				set relxnickpos [expr $relxnickpos + $textwidth]

			} elseif {[lindex $unit 0] == "smiley"} {

				#check if we are still allowed to draw smileys
				if {$linefull} {continue}

				set smileyname [lindex $unit 1]


				if {[expr $relxnickpos + [image width $smileyname]] > $maxwidth} {
					#This line is full, don't draw anything anymore before we start a new line
					set linefull 1

					$canvas create text $relxnickpos $ynickpos -text $ellips -anchor w\
				-fill $relnickcolour -font splainf -tags [list contact $tag nicktext]
					set textwidth [font measure splainf $ellips]

					#append underline coords
					set yunderline [expr $ynickpos + $textheight + 1]
					lappend underlinst [list $relxnickpos $yunderline $textwidth $relnickcolour]

					continue
				}

				#draw the smiley
				$canvas create image $relxnickpos $ynickpos -image $smileyname -anchor w\
					-tags [list contact $tag smiley]

				#the next should come lower because this line is higher due to the smiley in it .. or not ? ;)
				if {[image height $smileyname] >= $ychange} {
					set ychange [image height $smileyname]
				}

				#change the coords
				set relxnickpos [expr $relxnickpos + [image width $smileyname]]
			} elseif {[lindex $unit 0] == "newline"} {

				set relxnickpos $xnickpos
				set ynickpos [expr $ynickpos + $ychange]
				set ypos [expr $ypos + $ychange]

				#new line, we can draw again !
				set linefull 0

			} elseif {[lindex $unit 0] == "colour"} {
				# a plugin like aMSN Plus! could make the text lists\
				 contain an extra variable for colourchanges
				set relnickcolour [lindex $unit 1]
				if {$relnickcolour == "reset"} {
					set relnickcolour $nickcolour
				}

			}

		#end the foreach loop
		}

		if {$statetext != ""} {

		#set the spacing (if this needs to be underlined, we'll draw the state as "  $statetext" and remove the spacing
		set relxnickpos [expr $relxnickpos + $nickstatespacing]

		$canvas create text $relxnickpos $ynickpos -text "$statetext" -anchor w\
			-fill $statecolour -font splainf -tags [list contact $tag statetext]


		#append underline coords
		set yunderline [expr $ynickpos + $textheight + 1]
		lappend underlinst [list $relxnickpos $yunderline $statewidth $statecolour]

		}

		set hoversquarey2 [expr $ypos + $ychange -2]

		#The bindings:
		
		#Remove previous bindings
		$canvas bind $tag <Enter> ""
		$canvas bind $tag <Motion> ""
		$canvas bind $tag <Leave> ""

		#Change cursor on nick hover - binding
		$canvas bind $tag <Enter> "+$canvas configure -cursor hand2"
		$canvas bind $tag <Leave> "+$canvas configure -cursor left_ptr"

		
		#Add binding for balloon
		if { [::config::getKey tooltips] == 1 } {
			$canvas bind $tag <Enter> +[list balloon_enter %W %X %Y "[getBalloonMessage $email $element]"]
			$canvas bind $tag <Motion> +[list balloon_motion %W %X %Y "[getBalloonMessage $email $element]"]
			$canvas bind $tag <Leave> "+set Bulle(first) 0; kill_balloon"
		}
		
		#Add binding for click / right click (remembering to get config key for single/dbl click on contacts to open chat)
		if { [::config::getKey sngdblclick] } {
			set singordblclick <Button-1>
		} else {
			set singordblclick <Double-Button-1>
		}

		#binding for right click		 
		$canvas bind $tag <<Button3>> "show_umenu $email $grId %X %Y"

#TODO: have the action depend on the 'state' (for mobile/offline contacts!)
		$canvas bind $tag $singordblclick "::amsn::chatUser $email"

		#bindings for dragging
		$canvas bind $tag <<Button2-Press>> "::guiContactList::contactPress $tag $canvas"
		$canvas bind $tag <<Button2-Motion>> "::guiContactList::contactMove $tag $canvas"
		$canvas bind $tag <<Button2>> "::guiContactList::contactReleased $tag $canvas"

		#Add binding for underline if the skinner use it
		if {[::skin::getKey underline_contact]} {
			$canvas bind $tag <Enter> "+::guiContactList::underlineList $canvas [list $underlinst] $tag"
			$canvas bind $tag <Leave> "+$canvas delete uline"
		}


#little fantasy with an error
#		$canvas bind $tag <Enter> "+$canvas create rectangle $hoversquarex1 $hoversquarey1 $hoversquarex2 $hoversquarey2 -tags rect"
#		$canvas bind $tag <Leave> "+$canvas delete rect"


		return [list [expr $xpos - 15] [expr $ypos + $ychange + [::skin::getKey buddy_ypad]]]
	}
	



	####################################
	#Contact dragging procs
	proc contactPress {tag canvas} {
		global OldX
		global OldY
		global OnTheMove
		#store old coordinates
		set OldX [winfo pointerx .]
		set OldY [winfo pointery .]
		set OnTheMove 1
		$canvas delete uline_$tag
	}

	proc contactMove {tag canvas} {
		global OldX
		global OldY

		#change coordinates 
		set NewX [winfo pointerx .]
		set NewY [winfo pointery .]
		set ChangeX [expr $OldX - $NewX]
		set ChangeY [expr $OldY - $NewY]

		$canvas move $tag [expr $ChangeX * -1] [expr $ChangeY * -1]

		set OldX [winfo pointerx .]
		set OldY [winfo pointery .]

#TODO: Make the canvas scroll if we hover the vertical edges of the canvas
#	Make the dragged contact stay under the cursor
#	Make it keep scrolling as long as we are in the area also if we don't move (extra proc)

		set canvaslength [lindex [$canvas cget -scrollregion] 3]

	#	if {[lindex [$canvas coords $email] 1] >= [expr [winfo height $canvas] - 20] } {
	#		after 300 
	#		::guiContactList::scrollCL down $canvaslength
	#	}  -> won't work this way
		$canvas delete uline_$tag
		
	}



	proc contactReleased {tag canvas} {
		global OldX
		global OldY
		global OnTheMove
#TODO: copying instead of moving when CTRL is pressed
		#first get the info out of the tag
		set email [::guiContactList::getEmailFromTag $tag]
		set grId [::guiContactList::getGrIdFromTag $tag]

		#kill the balloon if it came up, otherwise it just stays there
		set Bulle(first) 0; kill_balloon

		#check with Xcoord if we're still on the canvas
		set iconXCoord [lindex [$canvas coords $tag] 0]

#TODO		#if we drag off the list; now it's only on the left, make it also "if bigger then viewable area of canvas
		if {$iconXCoord < 0} { 
#TODO			#here we should trigger an event that can be used by plugins
			# for example, the contact tray plugin could create trays like this

			status_log "guiContactList: contact dragged off the CL"

			#trigger event

			::guiContactList::drawCL $canvas
		} else {
		

			#first see what's the coordinates of the icon
			set iconYCoord [lindex [$canvas coords $tag] 1]

			#now we have to find the group whose ycoord is the first less then this coord

			#beginsituation: group to move to is group where we began
			set oldgrId $grId
			set newgrId $oldgrId

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
					if {$grYCoord bind $canvas <MouseWheel> {<= [expr $iconYCoord + 5]} {
						set newgrId $grId
					}
				}
			}
	
			#remove the contact from the canvas as it's gonna be redrawn on the right place	
			$canvas delete $tag

			#if user wants to move from/to a place that's not possible, just leave the\
			 contact in the current group (other words: "don't do anything")

			if {[string is integer $newgrId] && $newgrId != $oldgrId && [string is integer $oldgrId]} {
				#move the contact
		
					status_log "Gonna move $email from $oldgrId to $newgrId"
					::groups::menuCmdMove $newgrId $oldgrId $email
					status_log "$email is now in [getGroupId $email]"
			} else {
				status_log "! Can't move $email from \"$oldgrId\" to \"$newgrId\""
				::guiContactList::drawCL $canvas
			}
		}
		set OnTheMove 0
		#remove those vars as they're not in use anymore
		unset OldX
		unset OldY
	}




	####################################
	# Draw the group title on the canvas
	proc drawGroup { canvas element curPos } {
		#the drawContact proc needs to know what group it is drawing in
		global groupDrawn
		set groupDrawn [lindex $element 0]

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


		$canvas bind $gid <Enter> "+$canvas create line $xuline1 $yuline $xuline2 $yuline -fill $groupcolor -tags [list [list uline_$gid uline $gid]]; $canvas lower uline_$gid \
			$gid;$canvas configure -cursor hand2"
		$canvas bind $gid <Leave> "+$canvas delete uline_$gid;$canvas configure -cursor left_ptr"
		
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
		# Group/Hybrid mode
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

	proc getEmailFromTag { tag } {
		set pos [string first _ $tag]
		set email [string range $tag [expr $pos + 1] end]
	return $email
	}

	proc getGrIdFromTag { tag } {
		set pos [string first _ $tag]
		set grId [string range $tag 0 [expr $pos -1]]
	return $grId
	}

	proc createNicknameArray {} {
		global nicknameArray

		array set nicknameArray { }	

		set userList [::MSN::sortedContactList]
		foreach user $userList {
			set usernick "[::abook::getDisplayNick $user]"
			set nicknameArray("$user") "[::smiley::parseMessageToList $usernick 1]"
		}

	}	

	#scroll the canvas up/down
	proc scrollCL {canvas direction} {
		set canvaslength [lindex [$canvas cget -scrollregion] 3]

		if {[winfo height $canvas] <= $canvaslength} {
			if {$direction == "down" || $direction == "-1"} {
				$canvas yview scroll 1 units
			

			} else {
				$canvas yview scroll -1 units
			}
		
			#here we have to move the background-image
			# this should be done as a command given to scrolledwindow, so it also
			# works when dragging the scrollbar
			$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]
		}
	}
	
	#proc that draws horizontal lines from this list of [list xcoord xcoord linelength] lists
	proc underlineList { canvas lines nicktag} {
		global OnTheMove
		if {!$OnTheMove} {
			foreach line $lines {
				$canvas create line [lindex $line 0] [lindex $line 1] [expr [lindex $line 0] + [lindex $line 2]] [lindex $line 1] -fill [lindex $line 3] -tags [list uline_$nicktag $nicktag uline]
			}
		}	
		$canvas lower uline_$nicktag $nicktag
	}

	#this proc gets called by an event in abook.tcl when a user's data is altering
	proc userDataChanged { contactDataChange user } {
#check if we are alive, if not don't do anything
#get explicit use out ...
		if {[winfo exists .contactlist.fr.c]} {

			global nicknameArray
			#Change the user's parsed nickname
			set usernick "[::abook::getDisplayNick $user]"
			set nicknameArray("$user") "[::smiley::parseMessageToList $usernick 1]"
#TODO: get this implicit use of ".contactlist.fr.c" out of here
			after 1000 ::guiContactList::drawCL .contactlist.fr.c

		}

	}

	proc truncateText { text maxwidth } {

		set shortened ""
		set stringlength [string length $text]

		#store stringlength
		for {set x 0} {$x < $stringlength} {incr x} {
			set nextchar [string range $text $x $x]
			set nextstring "$shortened$nextchar"
			if {[font measure splainf $nextstring] > $maxwidth} {
				break
			}
			set shortened "$nextstring"
		}
		return $shortened
	}
}
