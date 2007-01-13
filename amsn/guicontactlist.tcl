# New Contact List :: Based on canvas
#
# This module is still experimental, a lot of work is still needed.
#
# Things to be done (TODO):
#
# * set right mousewheel bindings (windows/mac) using [IsMac] etc procs
# * redraw on skinchange
# * scroll the canvas while dragging if you come near to the border (hard one :|)
# * change cursor while dragging (should we ?)
# * animated smileys on CL -> I hope this is possible easily with TkCxImage?
# * events when the groupview option is changed to redraw the whole list
# *
# *
# * ... cfr. "TODO:" msgs in code


namespace eval ::guiContactList {
	namespace export drawCL


	proc updateCL { } {
		variable clcanvas
		drawList $clcanvas
	}
			
	#/////////////////////////////////////////////////////////////////////
	# Function that draws a window where it embeds our contactlist canvas 
	#  (in a scrolledwindow) (this proc will nto be used if this gets
	#  embedded in the normal window
	#/////////////////////////////////////////////////////////////////////
	proc createCLWindow {} {
		#set easy names for the widgets
		set window .contactlist
		set clcontainer $window.sw
		set clscrollbar $clcontainer.vsb

		#check if the window already exists, ifso, raise it and redraw the CL
		if { [winfo exists $window] } {
			raise $window
			updateCL
			return
		}
	

		#create the window
		toplevel $window
		wm title $window "[trans title] - [::config::getKey login]"
		wm geometry $window 1000x1000



		# Set up the 'ScrolledWindow' container for the canvas
		#ScrolledWindow $clcontainer -auto vertical -scrollbar vertical -bg white -bd 0 -ipad 0
		frame $clcontainer
		# TODO: * ScrolledWindow should be feeded a command run on scroll (reset the image)
		#	* bgcolor should be skinnable

		#scrollbar $clscrollbar -command "::guiContactList::scrollCLsb $clcanvas"

		set clcanvas [createCLWindowEmbeded $clcontainer]

		# Embed the canvas in the ScrolledWindow
		#$clcontainer setwidget $clcanvas
		# Pack the scrolledwindow in the window
		pack $clcontainer -expand true -fill both

		#pack $clscrollbar -side right -fill y



		# Let's avoid the bug of window behind the bar menu on MacOS X
		catch {wm geometry $window [::config::getKey wingeometry]}
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			moveinscreen $window 30
		}

	}
	#/////////////////////////////////////////////////////////////////////
	# Function that draws a window where it embeds our contactlist canvas 
	#  (in a scrolledwindow) (this proc will nto be used if this gets
	#  embedded in the normal window
	#/////////////////////////////////////////////////////////////////////
	proc createCLWindowEmbeded { w } {
		#define global variables
		variable clcanvas
		global tcl_platform
		variable nicknameArray

		set clframe $w.cl
		set clcanvas $w.cl.cvs
		set clscrollbar $w.cl.vsb

		#here we load images used in this code:
		::skin::setPixmap back back.gif
		::skin::setPixmap upleft box_upleft.gif
		::skin::setPixmap up box_up.gif
		::skin::setPixmap upright box_upright.gif
		::skin::setPixmap left box_left.gif
		::skin::setPixmap body box_body.gif
		::skin::setPixmap right box_right.gif
		::skin::setPixmap downleft box_downleft.gif
		::skin::setPixmap down box_down.gif
		::skin::setPixmap downright box_downright.gif

		# Set beginning big width/height		
		set clbox [list 0 0 2000 1500]

		variable Xbegin
		variable Ybegin

		set Xbegin 10
		set Ybegin 10

		frame $w.cl -background [::skin::getKey contactlistbg]

		scrollbar $clscrollbar -command "::guiContactList::scrollCLsb $clcanvas"
		# Create a blank canvas
		canvas $clcanvas -background [::skin::getKey contactlistbg] -yscrollcommand "::guiContactList::setScroll $clscrollbar"

		if { $::contactlist_loaded } {
			# Parse the nicknames for smiley/newline substitution
			createNicknameArray
		}

		$clcanvas create image 0 0 -image [::skin::loadPixmap back] -anchor nw -tag backgroundimage
		after 1 ::guiContactList::drawList $clcanvas

		# Register events
		# TODO: * here we should register all needed events
		::Event::registerEvent contactStateChange all ::guiContactList::contactChanged
		::Event::registerEvent contactNickChange all ::guiContactList::contactChanged
		::Event::registerEvent contactDataChange all ::guiContactList::contactChanged
		::Event::registerEvent contactPSMChange all ::guiContactList::contactChanged
		::Event::registerEvent contactSpaceChange all ::guiContactList::contactChanged
		::Event::registerEvent contactSpaceFetched all ::guiContactList::contactChanged
		::Event::registerEvent contactListChange all ::guiContactList::contactChanged
		::Event::registerEvent contactBlocked all ::guiContactList::contactChanged
		::Event::registerEvent contactUnblocked all ::guiContactList::contactChanged
		::Event::registerEvent contactMoved all ::guiContactList::contactChanged
		::Event::registerEvent contactAdded all ::guiContactList::contactChanged
		::Event::registerEvent contactRemoved all ::guiContactList::contactRemoved
		::Event::registerEvent contactlistLoaded all ::guiContactList::contactlistLoaded
		::Event::registerEvent loggedOut all ::guiContactList::loggedOut
		::Event::registerEvent changedSorting all ::guiContactList::changedSorting
		::Event::registerEvent changedNickDisplay all ::guiContactList::changedNickDisplay
		::Event::registerEvent changedPreferences all ::guiContactList::changedPreferences
		::Event::registerEvent changedSkin all ::guiContactList::changedSkin

		# TODO: * create the bindings for scrolling (using procs "IsMac" etc)

		# TODO: scrollbindings: make 'm work for every platform!
		#	scrolledwindow should be feeded a command that moves the background 
		#	so it's also at the right place when the bar is dragged

		# MacOS Classic/OSX and Windows
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			#TODO: fix mac bindings -> Jerome's job ;)

			bind $clcanvas <MouseWheel> {
				%W yview scroll [expr {- (%D)}] units;

				# $canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]
				::guiContactList::moveBGimage $::guiContactList::clcanvas
			}
		} elseif {$tcl_platform(platform) == "windows"} {
			#TODO: test it with tcl8.5
			if {$::tcl_version >= 8.5} {
				bind $clcanvas <MouseWheel> {
					if {%D >= 0} {
						::guiContactList::scrollCL $::guiContactList::clcanvas up
					} else {
						::guiContactList::scrollCL $::guiContactList::clcanvas down
					}
				}
			} else {
				bind [winfo toplevel $clcanvas] <MouseWheel> {
					if {%D >= 0} {
						::guiContactList::scrollCL $::guiContactList::clcanvas up
					} else {
						::guiContactList::scrollCL $::guiContactList::clcanvas down
					}
				}
			}
		} else {
			# We're on X11! (I suppose ;))
			bind $clcanvas <ButtonPress-5> "::guiContactList::scrollCL $clcanvas down"
			bind $clcanvas <ButtonPress-4> "::guiContactList::scrollCL $clcanvas up"
			#bind [winfo parent $clcanvas].vscroll <ButtonPress-5> "::guiContactList::scrollCL $clcanvas down"
			#bind [winfo parent $clcanvas].vscroll <ButtonPress-4> "::guiContactList::scrollCL $clcanvas up"
		}


#TODO: only update when the window is resized, not during resizing
		#update the 
		bind $clcanvas <Configure> "::guiContactList::clResized $clcanvas"

		pack $clscrollbar -side right -fill y

		pack $clcanvas -expand true -fill both

		return $clframe
	}


	proc clResized { clcanvas } {
		#redraw the contacts as the width might have changed and reorganise
		::guiContactList::drawContacts $clcanvas
		::guiContactList::organiseList $clcanvas	
	}

	#/////////////////////////////////////////////////////////////////////
	# Function that draws everything needed on the canvas
	#/////////////////////////////////////////////////////////////////////
	proc drawList {canvas} {
		::guiContactList::drawGroups $canvas
		::guiContactList::drawContacts $canvas
		::guiContactList::organiseList $canvas
	}
	


	proc moveBGimage { canvas } {
		set canvaslength [lindex [$canvas cget -scrollregion] 3]
		if {$canvaslength == ""} { set canvaslength 0}
		$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]
		$canvas lower backgroundimage
	}


	proc drawGroups { canvas } {
		# Now let's get the actual whole contact list (also not shown users)
		set contactList [getContactList full]

		foreach element $contactList {
			# We check the type, and call the appropriate draw function
			if {[lindex $element 0] != "C" } {
				# Draw the group title
				drawGroup $canvas $element
			}
		}
	}


	proc drawContacts { canvas } {
		#if a contact is found before a group, assign it to "offline"; this shouldn't happen though, I think
		set groupID "offline"
		foreach element [getContactList full] {
			# We check the type, and call the appropriate draw function
			if {[lindex $element 0] == "C" } {
				# Draw the contact
				drawContact $canvas $element $groupID
			} else {
				set groupID [lindex $element 0]
			}
		}
	}

	proc changedSorting { eventused } {
		variable clcanvas
		if { [winfo exists $clcanvas] } {
			::guiContactList::drawList $clcanvas
		}
	}

	proc changedPreferences { eventused } {
		variable clcanvas
		if { [winfo exists $clcanvas] } {
			::guiContactList::createNicknameArray
			::guiContactList::drawList $clcanvas
		}
	}

	proc changedNickDisplay { eventused } {
		variable clcanvas
		if { [winfo exists $clcanvas] } {
			::guiContactList::createNicknameArray
			::guiContactList::drawList $clcanvas
		}
	}

	proc changedSkin { eventused } {
		variable clcanvas
		if { [winfo exists $clcanvas] } {
			::guiContactList::drawList $clcanvas
		}
	}

	proc loggedOut { eventused } {
		variable clcanvas

		if { [winfo exists $clcanvas] && !$::contactlist_loaded } {
			$clcanvas addtag all_cl all
			$clcanvas delete all_cl
			$clcanvas create image 0 0 -image [::skin::loadPixmap back] -anchor nw -tag backgroundimage
		}

	}


	proc contactlistLoaded { eventused } {
		variable clcanvas

		if { [winfo exists $clcanvas] } {
			::guiContactList::createNicknameArray
			::guiContactList::drawList $clcanvas
		}

	}

	proc contactRemoved { eventused email { gidlist ""} } {
		variable clcanvas
		if { [winfo exists $clcanvas] } {
			::guiContactList::organiseList $clcanvas
		}
	}

	proc contactChanged { eventused email { gidlist ""} } {
		variable clcanvas


		status_log "contactChanged :: $eventused $email $gidlist" white
		#Possible events:
		#contactStateChange
		#contactNickChange
		#contactDataChange
		#contactPSMChange
		#contactListChange
		#contactBlocked
		#contactUnblocked
		#contactMoved
		#contactAdded


		if { ![winfo exists $clcanvas] } {
			return
		}

		variable nicknameArray


		if { $email == "contactlist" } {
			return
		}

		if { $email == "myself" } {
			return
		}

#######################
#Contacts (re)drawing #
#######################

		if { $eventused == "contactNickChange" || $eventused == "contactAdded" || $eventused == "contactPSMChange" } {
			#We must update the nick array
			set usernick [::abook::getDisplayNick $email 1]
			set nicknameArray($email) [::smiley::parseMessageToList $usernick 1]
			set evpar(array) nicknameArray
			set evpar(login) $email
			::plugins::PostEvent NickArray evpar

		}
		
		# Redraw the contact for every group it's in
		#  Only for a contact that's simply moved, it doesn't have to be redrawn
		if {$eventused != "contactMoved"} {
			set groupslist [getGroupId $email]

			foreach group $groupslist {
				set contactelement [list "C" $email]
				::guiContactList::drawContact $clcanvas $contactelement $group
			}
		}		
		
		

#######################
#Groups (re)drawing   #
#######################

		#A contact that is being moved creates 2 events fired:
		#	-the contactMoved event
		#	-a contactAdded event because the contact is added to a new group
		#This means for this event we only have to update the group we were moved from and
		# remove the appeareance of the contact there as the group we are moved to will be 
		# changed with the "added" event
		if { $eventused == "contactMoved" } {
			set grId [lindex $gidlist 0]
			#redraw the old group
			::guiContactList::drawGroup $clcanvas [list $grId [::groups::GetName $grId]]
#TODO:			#remove the contact from the list
		
		}

		if { $eventused == "contactAdded" } {
			set grId [lindex $gidlist 0]
			#redraw the old group
			::guiContactList::drawGroup $clcanvas [list $grId [::groups::GetName $grId]]		
		}


		if {$eventused == "contactStateChange" } {
#TODO:			#only redraw groups if from/to offline/mobile
			::guiContactList::drawGroups $clcanvas
		}

		#listchange/datachange: redraw everything as I don't really know what it's all for
		if {$eventused == "contactDataChange" || $eventused == "contactListChange"} {
#TODO: maybe we don't have to redraw anything here ?
			::guiContactList::drawGroups $clcanvas
		}

		# Reorganise the list
		::guiContactList::organiseList $clcanvas

	}


	proc toggleGroup { element canvas } {
		::groups::ToggleStatus [lindex $element 0]
		# Redraw group as it's state changed
		::guiContactList::drawGroup $canvas $element 
		::guiContactList::organiseList $canvas
	}


	# Move 'm to the right place
	proc organiseList { canvas } {
		variable Xbegin
		variable Ybegin
		variable nickheightArray

		if { !$::contactlist_loaded } { return }

		#We remove the underline
		$canvas delete uline

		# First we move all the canvas items
		$canvas addtag items withtag group
		$canvas addtag items withtag contact
		# Make sure we move 'm to an invisible place first
		$canvas move items 100000 100000
		$canvas delete box

		# Now let's get an exact contact list
		set contactList [getContactList]

		# Before drawing we set the "we are draggin, sir" variable on 0
		set OnTheMove 0

		# Let's draw each element of this list
		set curPos [list $Xbegin $Ybegin]

		# TODO: an option for a X-padding for buddies .. should be set here and for teh truncation 
		# 	in the nickdraw proc


		################################
		#  First line for the "boxes"  #
		set DrawingFirstGroup 1
		################################

		foreach element $contactList {
			# We check the type, and call the appropriate draw function, these can be extended	
			# We got a contact
			if { [lindex $element 0] == "C" } {
				# Move it to it's place an set the new curPos
				set email [lindex $element 1]
				set gid $groupDrawn
				set tag "_$gid"; set tag $email$tag
				set currentPos [$canvas coords $tag]
				#status_log "MOVING CONTACT WITH TAG: $tag ;  currentpos: $currentPos  ; curPos: $curPos"

				if { $currentPos == "" } {
					status_log "WARNING: contact NOT moved: $email"
					return
				}

				set xpad [::skin::getKey buddy_xpad]
				set ypad [::skin::getKey buddy_ypad]

				$canvas move $tag [expr [lindex $curPos 0] - [lindex $currentPos 0] + $xpad] \
					[expr [lindex $curPos 1] - [lindex $currentPos 1]]

				set curPos [list [lindex $curPos 0] [expr [lindex $curPos 1] + $nickheightArray($email) + $ypad] ]
			} else {
				# It must be a group title
				if { [::groups::IsExpanded [lindex $element 0]] } {
					set xpad [::skin::getKey contract_xpad]
					set ypad [::skin::getKey contract_ypad]
				} else {
					set xpad [::skin::getKey expand_xpad]
					set ypad [::skin::getKey expand_ypad]
				}

				set maxwidth [winfo width $canvas]
				set boXpad 10
				set width [expr $maxwidth - ($boXpad*2)]
				if {$width <= 30} {set width 300}

				# If we're not drawing the first group, we should draw the end of the box of the \
				# group before here and change the curPos
				if {!$DrawingFirstGroup} {
					set bodYend [expr [lindex $curPos 1] + [::skin::getKey buddy_ypad]]
					# Here we should draw the body
					set height [expr $bodYend - $bodYbegin]
					if {$height >0} {
						image create photo boxbodysmall_$groupDrawn -height [image height [::skin::loadPixmap left]] \
							-width $width
						boxbodysmall_$groupDrawn copy [::skin::loadPixmap left] -to 0 0 [image width \
							[::skin::loadPixmap left]]  [image height [::skin::loadPixmap left]]
						boxbodysmall_$groupDrawn copy [::skin::loadPixmap body] -to  [image width \
							[::skin::loadPixmap left]] 0 [expr $width -  [image width \
							[::skin::loadPixmap right]]]  [image height [::skin::loadPixmap body]]
						boxbodysmall_$groupDrawn copy [::skin::loadPixmap right] -to [expr $width - \
							[image width [::skin::loadPixmap right]]] 0 $width  \
							[image height [::skin::loadPixmap right]]
						image create photo boxbody_$groupDrawn -height $height -width $width
						boxbody_$groupDrawn copy boxbodysmall_$groupDrawn -to 0 0 $width $height
						image delete boxbodysmall_$groupDrawn
					
						# Draw it
						$canvas create image $boXpad $bodYbegin -image boxbody_$groupDrawn -anchor nw \
							-tags [list box box_body $gid]
					} else {
						set bodYend $bodYbegin
					}

					# Create endbar of the box
					image create photo boxdownbar_$groupDrawn -height [image height [::skin::loadPixmap down]] \
						-width $width
					boxdownbar_$groupDrawn copy [::skin::loadPixmap downleft] -to 0 0 [image width \
						[::skin::loadPixmap downleft]]  [image height [::skin::loadPixmap downleft]]
					boxdownbar_$groupDrawn copy [::skin::loadPixmap down] -to  [image width \
						[::skin::loadPixmap downleft]] 0 [expr $width -  [image width \
						[::skin::loadPixmap downright]]]  [image height [::skin::loadPixmap down]]
					boxdownbar_$groupDrawn copy [::skin::loadPixmap downright] -to [expr $width - \
						[image width [::skin::loadPixmap downright]]] 0 $width \
						[image height [::skin::loadPixmap downright]]
					$canvas create image $boXpad $bodYend -image boxdownbar_$groupDrawn -anchor nw \
						-tags [list box box_downbar $gid]

					set curPos [list [lindex $curPos 0] [expr [lindex $curPos 1]+ $ypad] ]
				} else {
					set curPos [list [lindex $curPos 0] [lindex $curPos 1] ]
				}

				# Move it to it's place an set the new curPos
				set gid [lindex $element 0]
				set groupDrawn $gid
				set tag "gid_"; set tag $tag$gid
				set currentPos [$canvas coords $tag]

				if { $currentPos == "" } {
					status_log "WARNING: group NOT moved: $gid"
					return
				}

				# Create upbar of the box
				image create photo boxupbar_$groupDrawn -height [image height [::skin::loadPixmap up]] \
					-width $width
				boxupbar_$groupDrawn copy [::skin::loadPixmap upleft] -to 0 0 [image width \
					[::skin::loadPixmap upleft]]  [image height [::skin::loadPixmap upleft]]
				boxupbar_$groupDrawn copy [::skin::loadPixmap up] -to  [image width \
					[::skin::loadPixmap upleft]] 0 [expr $width -  [image width \
					[::skin::loadPixmap upright]]]  [image height [::skin::loadPixmap up]]
				boxupbar_$groupDrawn copy [::skin::loadPixmap upright] -to [expr $width - \
					[image width [::skin::loadPixmap upright]]] 0 $width \
					[image height [::skin::loadPixmap upright]]

				# Draw it
				set topYbegin [expr [lindex $curPos 1] -5]
				$canvas create image $boXpad $topYbegin -image boxupbar_$groupDrawn -anchor nw \
					-tags [list box box_upbar $gid]

				# Save the endypos for next body drawing
				set bodYbegin [expr $topYbegin + [image height [::skin::loadPixmap up]]]
			
				$canvas move $tag [expr [lindex $curPos 0] - [lindex $currentPos 0] + $xpad] \
					[expr [lindex $curPos 1] - [lindex $currentPos 1]]
				set curPos [list [lindex $curPos 0] [expr [lindex $curPos 1] + 20] + $ypad]
				# TODO: * change this '20' (height of the title) to the right value
				# 	as we already drew a group, the next won't be the first anymore
				set DrawingFirstGroup 0

				# END the "else it's a group"
			}
			# END of foreach
		}

		# Now do the body and the end for the last group:
		set bodYend [expr [lindex $curPos 1] + [::skin::getKey buddy_ypad] ]

		# Here we should draw the body
		set height [expr $bodYend - $bodYbegin]

		if {$height > 0} {
			image create photo boxbodysmall_$groupDrawn -height [image height [::skin::loadPixmap left]] \
				-width $width
			boxbodysmall_$groupDrawn copy [::skin::loadPixmap left] -to 0 0 [image width \
				[::skin::loadPixmap left]]  [image height [::skin::loadPixmap left]]
			boxbodysmall_$groupDrawn copy [::skin::loadPixmap body] -to  [image width \
				[::skin::loadPixmap left]] 0 [expr $width -  [image width \
				[::skin::loadPixmap right]]]  [image height [::skin::loadPixmap body]]
			boxbodysmall_$groupDrawn copy [::skin::loadPixmap right] -to [expr $width - \
				[image width [::skin::loadPixmap right]]] 0 $width  [image height \
				[::skin::loadPixmap right]]
			image create photo boxbody_$groupDrawn -height $height -width $width
			boxbody_$groupDrawn copy boxbodysmall_$groupDrawn -to 0 0 $width $height
			image delete boxbodysmall_$groupDrawn
				
			# Draw it
			$canvas create image $boXpad $bodYbegin -image boxbody_$groupDrawn -anchor nw \
				-tags [list box box_body $gid]
		} else {
			set bodYend $bodYbegin
		}

		# Create endbar of the box
		image create photo boxdownbar_$groupDrawn -height [image height [::skin::loadPixmap down]] \
			-width $width
		boxdownbar_$groupDrawn copy [::skin::loadPixmap downleft] -to 0 0 [image width \
			[::skin::loadPixmap downleft]]  [image height [::skin::loadPixmap downleft]]
		boxdownbar_$groupDrawn copy [::skin::loadPixmap down] -to  [image width \
			[::skin::loadPixmap downleft]] 0 [expr $width -  [image width \
			[::skin::loadPixmap downright]]]  [image height [::skin::loadPixmap down]]
		boxdownbar_$groupDrawn copy [::skin::loadPixmap downright] -to [expr $width - \
			[image width [::skin::loadPixmap downright]]] 0 $width \
			[image height [::skin::loadPixmap downright]]
		$canvas create image $boXpad $bodYend -image boxdownbar_$groupDrawn -anchor nw \
			-tags [list box box_downbar $gid]

			# Get the group-boxes behind the groups and contacts
		$canvas lower box items
			# Set height of canvas
		set canvaslength [expr [lindex $curPos 1] + 20]
		$canvas configure -scrollregion [list 0 0 2000 $canvaslength]
			# Make sure after redrawing the bgimage is on the right place
		$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]
	}

	#/////////////////////////////////////////////////////////////////////////
	# Function that draws a group 
	#/////////////////////////////////////////////////////////////////////////
	proc drawGroup { canvas element} {
		if { !$::contactlist_loaded } { 
			return
		}

		# Set the group id, our ids are integers and tags can't be so add gid_ to start
		set gid gid_[lindex $element 0]

		# $canvas addtag items withtag $gid

		# Delete the group before redrawing
		$canvas delete $gid

		set xpos 0
		set ypos 0
		
		# Let's setup the right image (expanded or contracted)
		if { [::groups::IsExpanded [lindex $element 0]] } {
			# Set padding between image and text
			set xpad [::skin::getKey contract_xpad]
			set img [::skin::loadPixmap contract]
			set img_hover [::skin::loadPixmap contract_hover]
			set groupcolor [::skin::getKey groupcolorextend]
		} else {
			# Set padding between image and text
			set xpad [::skin::getKey expand_xpad]
			set img [::skin::loadPixmap expand]
			set img_hover [::skin::loadPixmap expand_hover]
			set groupcolor [::skin::getKey groupcolorcontract]
		}

		set groupnamecountpad 5

		# Get the number of user for this group
		set groupcount [getGroupCount $element]
		
		# Store group name and groupcount as string, for measuring length of underline
		set groupnametext [lindex $element 1]
		set groupcounttext "($groupcount)"
		
		# Set the begin-position for the groupnametext
		set textxpos [expr $xpos + [image width $img] + $xpad]

		# First we draw our little group toggle button
		$canvas create image $xpos $ypos -image $img -activeimage $img_hover -anchor nw \
			-tags [list group toggleimg $gid img$gid]

		# Then the group's name
		$canvas create text $textxpos $ypos -text $groupnametext -anchor nw \
			-fill $groupcolor -font sboldf -tags [list group title name_$gid $gid]

		set text2xpos [expr {$textxpos + [font measure sboldf $groupnametext] + \
			$groupnamecountpad}]

		# Then the group's count
		$canvas create text $text2xpos $ypos -text $groupcounttext -anchor nw \
			-fill $groupcolor -font splainf -tags [list group title count_$gid $gid]



		#Setup co-ords for underline on hover
		set yuline [expr {$ypos + [font configure splainf -size] + 3 }]

		set underlinst [list [list $textxpos $yuline [font measure sboldf $groupnametext] \
			$groupcolor] [list $text2xpos $yuline [font measure splainf $groupcounttext] \
			$groupcolor]]

		# Create mouse event bindings

		# First, remove previous bindings
		$canvas bind $gid <Enter> ""
		$canvas bind $gid <Motion> ""
		$canvas bind $gid <Leave> ""
		$canvas bind $gid <<Button1>> ""
		$canvas bind $gid <<Button3>> ""

		$canvas bind $gid <<Button1>> "+::guiContactList::toggleGroup [list $element] $canvas"
		$canvas bind $gid <<Button3>> "+::groups::GroupMenu $gid %X %Y"

		$canvas bind $gid <Enter> "+::guiContactList::underlineList $canvas [list $underlinst] $gid"
		$canvas bind $gid <Leave> "+$canvas delete uline_$gid"

		# Change cursor bindings for contacts
		$canvas bind $gid <Enter> "+$canvas configure -cursor hand2"
		$canvas bind $gid <Leave> "+$canvas configure -cursor left_ptr"
	}


	#/////////////////////////////////////////////////////////////////////////
	# Function that draws a contact 
	#/////////////////////////////////////////////////////////////////////////
	proc drawContact { canvas element groupID } {
	
		# We are gonna store the height of the nicknames
		variable nickheightArray
		variable nicknameArray
		variable Xbegin

		if { !$::contactlist_loaded } { return }

		# Set the place for drawing it (should be invisible)
		set xpos 0
		set ypos 0
		
		set email [lindex $element 1]
		set grId $groupID

		# The tag can't be just $email as users can be in more then one group
		set tag "_$grId"; set tag "$email$tag"
		set main_part "${tag}_click"
		set space_icon "${tag}_space_icon"
		
		$canvas delete $tag

		set state_code [::abook::getVolatileData $email state FLN]

		set nickcolour [string tolower [::abook::getContactData $email customcolor]]
		if { $nickcolour != "" } {
			if { [string index $nickcolour 0] == "#" } {
				set nickcolour [string range $nickcolour 1 end]
			}
			set nickcolour "#[string repeat 0 [expr {6-[string length $nickcolour]}]]$nickcolour"
		}

		if { $nickcolour == "" || $nickcolour == "#" } {
			if { $state_code == "FLN" && [::abook::getContactData $email msn_mobile] == "1" } {
				set nickcolour [::skin::getKey "contact_mobile"]
			} else {
				set nickcolour [::MSN::stateToColor $state_code]
			}
			set force_colour 0
		} else {
			set force_colour 1
		}

		set psm [::abook::getpsmmedia $email]

		if { [::MSN::userIsBlocked $email] } {
			if { $state_code == "FLN" } { 
				set img [::skin::loadPixmap blocked_off] 
			} else {    
				set img [::skin::loadPixmap blocked] 
			}
		} elseif {[::config::getKey show_contactdps_in_cl] == "1" } {
			set img [::skin::getLittleDisplayPicture $email [image height [::skin::loadPixmap [::MSN::stateToImage $state_code]]] ]
		} elseif { [::abook::getContactData $email msn_mobile] == "1" && $state_code == "FLN"} {
			set img [::skin::loadPixmap mobile]
		} else {
			set img [::skin::loadPixmap [::MSN::stateToImage $state_code]]
		}

		

		# TODO: hovers for the status-icons
		# 	skinsetting to have buddypictures in their place (this is default in MSN7!)
		# 	with a pixmap border and also status-emblem overlay in bottom right corner		
		set parsednick $nicknameArray($email)
		set nickstatespacing 5
		# TODO: skinsetting for the spacing between nicknames and the status
		set statetext "\([trans [::MSN::stateToDescription $state_code]]\)"

		if {$state_code == "NLN" || $state_code == "FLN"} {
			set nickstatespacing 0
			set statetext ""
		}

		if {$grId == "mobile"} {
			set nickstatespacing 5
			set statetext "\([trans mobile]\)"
		}

		set statecolour grey
		# TODO: skinsetting for state-colour
		set statewidth [font measure splainf $statetext]

		# Set the beginning coords for the next drawings
		set xnickpos $xpos
		set ynickpos [expr $ypos + [image height $img]/2]

		set update_img [::skin::loadPixmap space_update]
		# Check if we need an icon to show an updated space/blog, and draw one if we do
		#We must create the icon and hide after else, the status icon will stick the border : it's surely due to anchor parameter
		$canvas create image $xnickpos $ypos -anchor nw \
			-image $update_img -tags [list contact icon $tag $space_icon]
		if { [::abook::getVolatileData $email space_updated 0]} {
			$canvas itemconfigure $space_icon -state normal
		} else {
			$canvas itemconfigure $space_icon -state hidden
		}

		#All the status icons are aligned
		set xnickpos [expr $xnickpos + [image width $update_img]]

		# Draw status-icon, we use ypos because it refers to the top and not to the middle of the line
		$canvas create image $xnickpos $ypos -image $img -anchor nw -tags [list contact icon $tag $main_part]

		set xnickpos [expr $xnickpos + [image width $img] + 5]

		# TODO: skin setting to draw buddypicture; statusicon should become icon + status overlay
		# 	like:	draw icon or small buddypicture overlay it with the status-emblem

		#	Draw alarm icon if alarm is set
		if { [::alarms::isEnabled $email] != ""} {
			#set imagee [string range [string tolower $user_login] 0 end-8]
			#trying to make it non repetitive without the . in it
			#Patch from kobasoft
			#set imagee "alrmimg_[getUniqueValue]"
			#regsub -all "\[^\[:alnum:\]\]" [string tolower $user_login] "_" imagee
	
			if { [::alarms::isEnabled $email] } {
				set icon [::skin::loadPixmap bell]
			} else {
				set icon [::skin::loadPixmap belloff]
			}
			
			$canvas create image [expr $xnickpos -3] $ypos -image \
				$icon -anchor nw -tags [list contact icon alarm_$email $tag $main_part]

			# Binding for right click		 
			$canvas bind alarm_$email <<Button3>> "::alarms::configDialog $email; break;"
			$canvas bind alarm_$email <Button1-ButtonRelease> "switch_alarm $email; ::guiContactList::switch_alarm $email $canvas alarm_$email; break;"

			set xnickpos [expr $xnickpos + [image width $icon]]
		}

		# If you are not on this contact's list, show the notification icon
		if {[expr {[lsearch [::abook::getLists $email] RL] == -1}]} {
			set icon [::skin::loadPixmap notinlist]
			$canvas create image [expr $xnickpos -3] $ypos -image \
				[::skin::loadPixmap notinlist] -anchor nw -tags \
				[list contact icon $tag $main_part]
			set xnickpos [expr $xnickpos + [image width $icon]]
		}

		# Now we're gonna draw the nickname itself
#TODO: From TK 8.5 up, underlined text should be possible on the canvas without this trick though in my
#	alpha release this doesn't work
		# Reset the underlining's list
		set underlinst [list]
		#set maxwidth [winfo width $canvas]

		if { [::config::getKey truncatenames] } {
			set ellips "..."
			# Leave some place for the statustext, the elipsis (...) and the spacing + spacing
			# of border and - the beginningborder
			set maxwidth [expr [winfo width $canvas] - $statewidth - [font measure splainf $ellips] - \
				$nickstatespacing - 5 - 2*$Xbegin - [::skin::getKey buddy_xpad]]
		} else {
			#No ellipses when we don't truncates nicknames : ask to Vivia for that :p
			set ellips ""
			# Leave some place for the elipsis (...) and the spacing + spacing
			# of border and - the beginningborder
			set maxwidth [expr [winfo width $canvas] - [font measure splainf $ellips] - 5 - 2*$Xbegin - [::skin::getKey buddy_xpad]]
		}

		# TODO: An option for a X-padding for buddies .. should be set here and in the organising proc

		# We can draw as long as the line isn't full
		set linefull 0
		set textheight [expr [font configure splainf -size]/2 ]

		# This is the var for the y-change
		set ychange [image height $img]
		set relnickcolour $nickcolour
		set relxnickpos $xnickpos
		set relynickpos $ypos

		foreach unit $parsednick {
			if {[lindex $unit 0] == "text"} {
				# Check if we are still allowed to write text
				if { $linefull } {
					continue
				}

				# Store the text as a string
				set textpart [lindex $unit 1]

				# Check if it's really containing text
				if {$textpart == ""} {
					continue
				}

				# Check if text is not too long and should be truncated, then
				# first truncate it and restore it in $textpart and set the linefull
				if {[expr $relxnickpos + [font measure splainf $textpart]] > $maxwidth} {
					set textpart [::guiContactList::truncateText $textpart \
						[expr $maxwidth - $relxnickpos] splainf]

						#If we don't truncate we don't put ellipsis
						set textpart "$textpart$ellips"

					# This line is full, don't draw anything anymore before we start a new line
					set linefull 1
				}

				# Draw the text
				$canvas create text $relxnickpos $ynickpos -text $textpart -anchor w -fill \
					$relnickcolour -font splainf -tags [list contact $tag nicktext $main_part]
				set textwidth [font measure splainf $textpart]

				# Append underline coords
				set yunderline [expr $ynickpos + $textheight + 1]
				lappend underlinst [list [expr $relxnickpos - $xpos] [expr $yunderline - $ypos] \
					$textwidth $relnickcolour]

				# Change the coords
				set relxnickpos [expr $relxnickpos + $textwidth]
			} elseif { [lindex $unit 0] == "smiley" } {
				# Check if we are still allowed to draw smileys
				if { $linefull } {
					continue
				}

				set smileyname [lindex $unit 1]

				if { [expr $relxnickpos + [image width $smileyname]] > $maxwidth } {
					# This line is full, don't draw anything anymore before we start a new line
					set linefull 1

					$canvas create text $relxnickpos $ynickpos -text $ellips -anchor w \
						-fill $relnickcolour -font splainf -tags [list contact $tag nicktext $main_part]
					set textwidth [font measure splainf $ellips]

					# Append underline coords
					set yunderline [expr $ynickpos + $textheight + 1]
					lappend underlinst [list [expr $relxnickpos - $xpos]  \
						[expr $yunderline - $ypos] $textwidth $relnickcolour]
					continue
				}

				# Draw the smiley
				$canvas create image $relxnickpos $ynickpos -image $smileyname -anchor w \
					-tags [list contact $tag smiley $main_part]

				# TODO: smileys should be resized to fit in text-height
				# if {[image height $smileyname] >= $ychange} {
				# 	set ychange [image height $smileyname]
				# }

				# Change the coords
				set relxnickpos [expr $relxnickpos + [image width $smileyname]]
			} elseif {[lindex $unit 0] == "newline"} {
				set relxnickpos $xnickpos
				set ynickpos [expr $ynickpos + [image height $img]]
				set ychange [expr $ychange + [image height $img]]

				# New line, we can draw again !
				set linefull 0
			} elseif {[lindex $unit 0] == "colour" && !$force_colour} {
				# A plugin like aMSN Plus! could make the text lists
				# contain an extra variable for colourchanges
				set relnickcolour [lindex $unit 1]
				if {$relnickcolour == "reset"} {
					set relnickcolour $nickcolour
				}
			} else {
				status_log "Unknown item in parsed nickname: $unit"
			}
		#END the foreach loop
		}

		#We mustn't take the status in account as we will draw it
		set maxwidth [expr [winfo width $canvas] - [font measure splainf $ellips] - 5 - 2*$Xbegin - [::skin::getKey buddy_xpad]]

		if { $statetext != "" } {
			# Set the spacing (if this needs to be underlined, we'll draw the state as
			# "  $statetext" and remove the spacing
			set relxnickpos [expr $relxnickpos + $nickstatespacing]

			if { ![::config::getKey truncatenames] } {

				if { $linefull } {
					set statewidth 0
				} else {
					# Check if text is not too long and should be truncated, then
					# first truncate it and restore it in $textpart and set the linefull
					if {[expr $relxnickpos + [font measure splainf "$statetext"]] > $maxwidth} {
						set statetext [::guiContactList::truncateText "$statetext" \
							[expr $maxwidth - $relxnickpos] splainf]
	
							#If we don't truncate we don't put ellipsis
							set statetext "$statetext$ellips"
							set statewidth [font measure splainf $statetext]
	
						# This line is full, don't draw anything anymore before we start a new line
						set linefull 1
					}
	
					$canvas create text $relxnickpos $ynickpos -text "$statetext" -anchor w\
						-fill $statecolour -font splainf -tags [list contact $tag statetext $main_part]
				}
			} else {

				$canvas create text $relxnickpos $ynickpos -text "$statetext" -anchor w\
					-fill $statecolour -font splainf -tags [list contact $tag statetext $main_part]
			}

			# TODO: Maybe a skin-option to have the spacing underlined

			if { $statewidth > 0 } {
				# Append underline coords
				set yunderline [expr $ynickpos + $textheight + 1]
				lappend underlinst [list [expr $relxnickpos - $xpos] [expr $yunderline - $ypos] \
					$statewidth $statecolour]

				set relxnickpos [expr $relxnickpos + $statewidth]
			}
		}

		if {$psm != "" && [::config::getKey emailsincontactlist] == 0 } {

			set relnickcolour $nickcolour

			if {[::config::getKey psmplace] == 1 } {
				set parsedpsm [::smiley::parseMessageToList " - $psm" 1]
				foreach unit $parsedpsm {
					if {[lindex $unit 0] == "text"} {
						# Check if we are still allowed to write text
						if { $linefull } {
							continue
						}
		
						# Store the text as a string
						set textpart [lindex $unit 1]
		
						# Check if it's really containing text
						if {$textpart == ""} {
							continue
						}
		
						# Check if text is not too long and should be truncated, then
						# first truncate it and restore it in $textpart and set the linefull
						if {[expr $relxnickpos + [font measure sitalf $textpart]] > $maxwidth} {
							set textpart [::guiContactList::truncateText $textpart \
								[expr $maxwidth - $relxnickpos] sitalf]
							set textpart "$textpart$ellips"
		
							# This line is full, don't draw anything anymore before we start a new line
							set linefull 1
						}
		
						# Draw the text
						$canvas create text $relxnickpos $ynickpos -text $textpart -anchor w -fill \
							$relnickcolour -font sitalf -tags [list contact $tag psmtext $main_part]
						set textwidth [font measure sitalf $textpart]
		
						# Append underline coords
						set yunderline [expr $ynickpos + $textheight + 1]
						lappend underlinst [list [expr $relxnickpos - $xpos] [expr $yunderline - $ypos] \
							$textwidth $relnickcolour]
		
						# Change the coords
						set relxnickpos [expr $relxnickpos + $textwidth]
					} elseif { [lindex $unit 0] == "smiley" } {
						# Check if we are still allowed to draw smileys
						if { $linefull } {
							continue
						}
		
						set smileyname [lindex $unit 1]
		
						if { [expr $relxnickpos + [image width $smileyname]] > $maxwidth } {
							# This line is full, don't draw anything anymore before we start a new line
							set linefull 1
		
							$canvas create text $relxnickpos $ynickpos -text $ellips -anchor w \
								-fill $relnickcolour -font sitalf -tags [list contact $tag psmtext $main_part]
							set textwidth [font measure sitalf $ellips]
		
							# Append underline coords
							set yunderline [expr $ynickpos + $textheight + 1]
							lappend underlinst [list [expr $relxnickpos - $xpos]  \
								[expr $yunderline - $ypos] $textwidth $relnickcolour]
							continue
						}
		
						# Draw the smiley
						$canvas create image $relxnickpos $ynickpos -image $smileyname -anchor w \
							-tags [list contact $tag psmsmiley $main_part]
		
						# TODO: smileys should be resized to fit in text-height
						# if {[image height $smileyname] >= $ychange} {
						# 	set ychange [image height $smileyname]
						# }
		
						# Change the coords
						set relxnickpos [expr $relxnickpos + [image width $smileyname]]
					} elseif {[lindex $unit 0] == "newline"} {
						set relxnickpos $xnickpos
						set ynickpos [expr $ynickpos + [image height $img]]
						set ychange [expr $ychange + [image height $img]]
		
						# New line, we can draw again !
						set linefull 0
					} elseif {[lindex $unit 0] == "colour" && !$force_colour} {
						# A plugin like aMSN Plus! could make the text lists
						# contain an extra variable for colourchanges
						set relnickcolour [lindex $unit 1]
						if {$relnickcolour == "reset"} {
							set relnickcolour $nickcolour
						}
					}
					# END the foreach loop
				}
			} elseif {[::config::getKey psmplace] == 2 } {
				set parsedpsm [::smiley::parseMessageToList "\n$psm" 1]

				foreach unit $parsedpsm {
					if {[lindex $unit 0] == "text"} {
						# Check if we are still allowed to write text
						if { $linefull } {
							continue
						}
		
						# Store the text as a string
						set textpart [lindex $unit 1]
		
						# Check if it's really containing text
						if {$textpart == ""} {
							continue
						}
		
						# Check if text is not too long and should be truncated, then
						# first truncate it and restore it in $textpart and set the linefull
						if {[expr $relxnickpos + [font measure sitalf $textpart]] > $maxwidth} {
							set textpart [::guiContactList::truncateText $textpart \
								[expr $maxwidth - $relxnickpos] sitalf]
							set textpart "$textpart$ellips"
		
							# This line is full, don't draw anything anymore before we start a new line
							set linefull 1
						}
		
						# Draw the text
						$canvas create text $relxnickpos $ynickpos -text $textpart -anchor w -fill \
							$relnickcolour -font sitalf -tags [list contact $tag psmtext $main_part]
						set textwidth [font measure sitalf $textpart]
		
						# Append underline coords
						set yunderline [expr $ynickpos + $textheight + 1]
						lappend underlinst [list [expr $relxnickpos - $xpos] [expr $yunderline - $ypos] \
							$textwidth $relnickcolour]
		
						# Change the coords
						set relxnickpos [expr $relxnickpos + $textwidth]
					} elseif { [lindex $unit 0] == "smiley" } {
						# Check if we are still allowed to draw smileys
						if { $linefull } {
							continue
						}
		
						set smileyname [lindex $unit 1]
		
						if { [expr $relxnickpos + [image width $smileyname]] > $maxwidth } {
							# This line is full, don't draw anything anymore before we start a new line
							set linefull 1
		
							$canvas create text $relxnickpos $ynickpos -text $ellips -anchor w \
								-fill $relnickcolour -font sitalf -tags [list contact $tag psmtext $main_part]
							set textwidth [font measure sitalf $ellips]
		
							# Append underline coords
							set yunderline [expr $ynickpos + $textheight + 1]
							lappend underlinst [list [expr $relxnickpos - $xpos]  \
								[expr $yunderline - $ypos] $textwidth $relnickcolour]
							continue
						}
		
						# Draw the smiley
						$canvas create image $relxnickpos $ynickpos -image $smileyname -anchor w \
							-tags [list contact $tag psmsmiley $main_part]
		
						# TODO: smileys should be resized to fit in text-height
						# if {[image height $smileyname] >= $ychange} {
						# 	set ychange [image height $smileyname]
						# }
		
						# Change the coords
						set relxnickpos [expr $relxnickpos + [image width $smileyname]]
					} elseif {[lindex $unit 0] == "newline"} {
						set relxnickpos $xnickpos
						set ynickpos [expr $ynickpos + [image height $img]]
						set ychange [expr $ychange + [image height $img]]
		
						# New line, we can draw again !
						set linefull 0
					} elseif {[lindex $unit 0] == "colour" && !$force_colour} {
						# A plugin like aMSN Plus! could make the text lists
						# contain an extra variable for colourchanges
						set relnickcolour [lindex $unit 1]
						if {$relnickcolour == "reset"} {
							set relnickcolour $nickcolour
						}
					}
					# END the foreach loop
				}
			}
		} ; #end psm drawing



		set space_showed [::abook::getContactData $email SpaceShowed 0]
		set space_fetched [::abook::getContactData $email SpaceDataIsFetched 0]

		#Drawing of inline spaces data, can be prohibited by setting the config key to 0
		# (a possible ccard plugin should do this)
		if {$space_showed && [::config::getKey drawspaces 1] == 1} {
			if {$space_fetched} {
#TODO: Code me !
				#draw the data
				puts "Positions: $ychange "
				#adjust $ychange etc

			} else {
#TODO: Code me !
				#draw a "please wait .." message

				#adjust $ychange etc
			}
		}

		# First, remove previous bindings
		$canvas bind $tag <Enter> ""
		$canvas bind $tag <Motion> ""
		$canvas bind $tag <Leave> ""
		$canvas bind $main_part <Enter> ""
		$canvas bind $main_part <Motion> ""
		$canvas bind $main_part <Leave> ""
		$canvas bind $space_icon <Enter> ""
		$canvas bind $space_icon <Motion> ""
		$canvas bind $space_icon <Leave> ""

		#Bindings for the "star" image for spaces
		#Click binding
		$canvas bind $space_icon <Button-1> "::guiContactList::toggleSpaceShown $canvas $email $space_showed $space_fetched"

		# balloon bindings
		if { [::config::getKey tooltips] == 1 } {
			$canvas bind $space_icon <Enter> +[list balloon_enter %W %X %Y "View space items" ]
			$canvas bind $space_icon <Motion> +[list balloon_motion %W %X %Y "View space items"]
			$canvas bind $space_icon <Leave> "+set Bulle(first) 0; kill_balloon"
		}

		# Add binding for underline if the skinner use it
		if {[::skin::getKey underline_contact]} {
			$canvas bind $main_part <Enter> \
				"+::guiContactList::underlineList $canvas [list $underlinst] $tag"
			$canvas bind $main_part <Leave> "+$canvas delete uline_$tag"
		}
		
		# Add binding for balloon
		if { [::config::getKey tooltips] == 1 } {
			$canvas bind $main_part <Enter> +[list balloon_enter %W %X %Y [getBalloonMessage \
				$email $element] [::skin::getDisplayPicture $email]]
			$canvas bind $main_part <Motion> +[list balloon_motion %W %X %Y [getBalloonMessage \
				$email $element] [::skin::getDisplayPicture $email]]
			$canvas bind $main_part <Leave> "+set Bulle(first) 0; kill_balloon"
		}

		# Add binding for click / right click (remembering to get config key for single/dbl
		# click on contacts to open chat)
		if { [::config::getKey sngdblclick] } {
			set singordblclick <Button-1>
		} else {
			set singordblclick <Double-Button-1>
		}

		# Binding for left (double)click
		if { $state_code == "FLN" && [::abook::getContactData $email msn_mobile] == "1"} {
			# If the user is offline and support mobile (SMS)
			$canvas bind $main_part $singordblclick "::MSNMobile::OpenMobileWindow ${email}"
		} else {
			$canvas bind $main_part $singordblclick "::amsn::chatUser $email"
		}

		# Binding for right click		 
		$canvas bind $main_part <<Button3>> "show_umenu $email $grId %X %Y"

		# Bindings for dragging : applies to all elements even the star
		$canvas bind $tag <<Button2-Press>> "::guiContactList::contactPress $tag $canvas"
		$canvas bind $tag <<Button2-Motion>> "::guiContactList::contactMove $tag $canvas"
		$canvas bind $tag <<Button2>> "::guiContactList::contactReleased $tag $canvas"

		#cursor change bindings
		$canvas bind $tag <Enter> "+$canvas configure -cursor hand2"
		$canvas bind $tag <Leave> "+$canvas configure -cursor left_ptr"

		# Now store the nickname [and] height in the nickarray
		# set nickheight [expr $ychange + [::skin::getKey buddy_ypad] ]
		set nickheightArray($email) $ychange
		# status_log "nickheight $email: $nickheight"
	}
	
	proc toggleSpaceShown {canvas email space_showed space_fetched} {
puts "toggling space appearance"
		# when the star is pressed, the "SpaceShowed" boolean is toggled,
		# if SpaceIsFetched is 0, the fetching procs are called and these fire an event when the data is fetched
		# which redraws the contact
		# if it's already fetched, the binding calls the contactChanged proc to redraw the contact with the spaces
		# info underneath
		if {$space_showed} {
puts "::abook::setContactData $email SpaceShowed 0"
			::abook::setContactData $email SpaceShowed 0		
		} else {
puts "::abook::setContactData $email SpaceShowed 1"
			::abook::setContactData $email SpaceShowed 1
			if {!$space_fetched} {
				#Fetch the spaces info (thumbnails etc)
				#these procs will fire an event when ready so the contact can be redrawn with the info
				#now we'll redraw the contact so a "please wait..." message appears
			
				#after fetching, the star should dissapear, thus the var should be set to read in teh volatile data
#TODO:  Call the fetching procs and make sure they fire an event when fetching is done
			
			} else {
				#Spaces info is already fetched and will be shown with a contact redraw
				#nothing more to do here			
			}
		}
		#redraw contact
		::guiContactList::contactChanged "toggleSPaceShown" $email
	}


	proc getContactList { {kind "normal"} } {
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
		
		# Go through each group, and insert the contacts in a new list
		# that will represent our GUI view
		foreach group $groupList {
			set grId [lindex $group 0]
			
			# if group is empty and remove empty groups is set (or this is
			# Individuals group) then skip this group
			if { $kind != "full" && ($grId == 0 || [::config::getKey removeempty]) && [getGroupCount $group] == 0} {
				continue
			}

			# First we append the group
			lappend contactList $group

			if { [::groups::IsExpanded [lindex $group 0]] != 1 && $kind == "normal"} {
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

	##################################################
	# Get the group count
	# Depend if user in status/group/hybrid mode
	proc getGroupCount {element} {
		set groupcounts [::groups::getGroupCount [lindex $element 0]]

		if { [lindex $element 0] == "offline" && [::config::getKey showMobileGroup] != 1} {
			set mobileidx 1
		} else {
			set mobileidx 0
		}

		set mode [::config::getKey orderbygroup]
		if { $mode == 0} {
			# Status mode
			set groupcount [lindex $groupcounts $mobileidx]
		}  elseif { $mode == 1} {
			# Group mode
			set groupcount "[lindex $groupcounts 0]/[lindex $groupcounts 1]"
		} elseif { $mode == 2} {
			# Hybrid mode
			set groupcount [lindex $groupcounts $mobileidx]
		}

		return $groupcount
	}


	# Function that returns a list of the groups, depending on the selected view mode (Status, Group, Hybrid)
	#
	# List looks something like this :
	# We have a list of these lists :
	# [group_state gid group_name [listofmembers]]
	# listofmembers is like this :
	# [email redraw_flag]
	proc getGroupList { {realgroups 0} } {
		set mode [::config::getKey orderbygroup]
		
		# Online/Offline mode
		if { $mode == 0 } {
			if { $realgroups } {
				set groupList [list ]
			} else {
				if {[::config::getKey showMobileGroup] == 1} {
					set groupList [list [list "online" [trans online]] \
						[list "mobile" [trans mobile]] \
						[list "offline" [trans offline]]]
				} else {
					set groupList [list [list "online" [trans online]] \
						[list "offline" [trans offline]]]
				}
			}

		# Group/Hybrid mode
		} elseif { $mode == 1 || $mode == 2} {
			set groupList [list]
			# We get the array of groups from abook
			array set groups [::abook::getContactData contactlist groups]
			# Convert to list
			set g_entries [array get groups]
			set items [llength $g_entries]

			for {set idx 0} {$idx < $items} {incr idx 1} {
				set gid [lindex $g_entries $idx]
				incr idx 1
				# Jump over the individuals group as it should not be
				# sorted alphabetically and allways be first
				if {$gid == 0} {
					continue
				} else {
					set name [lindex $g_entries $idx]
					lappend groupList [list $gid $name]
				}
			}

			# Sort the list alphabetically
			if {[::config::getKey ordergroupsbynormal]} {
				set groupList [lsort -dictionary -index 1 $groupList]
			} else {
				set groupList [lsort -decreasing -dictionary -index 1 $groupList]
			}

			# Now we have to add the "individuals" group, translated and as first

			# TODO: Maybe someone should do this a better way, but I had problems
			#	 with the 'linsert' command
			set groupList "\{0 \{[trans nogroup]\}\} $groupList"
		}
		
		# Hybrid Mode, we add mobile and offline group
		if { $mode == 2 && !$realgroups } {
			if {[::config::getKey showMobileGroup] == 1} {
				lappend groupList [list "mobile" [trans mobile]]
			}
			lappend groupList [list "offline" [trans offline]]
		}
		
		return $groupList
	}


	################################################################
	# Function that returns the appropriate GroupID(s) for the user
	# this GroupID depends on the group view mode selected
	proc getGroupId { email } {
		if { [lsearch [::abook::getLists $email] "FL"] == -1 } {
			#The contact isn't in the contact list
			return [list ]
		}

		set mode [::config::getKey orderbygroup]
		set status [::abook::getVolatileData $email state FLN]
		
		# Online/Offline mode
		if { $mode == 0 } {
			if { $status == "FLN" } {
				if { [::abook::getContactData $email msn_mobile] == "1" \
					&& [::config::getKey showMobileGroup] == 1} {
					return [list "mobile"]
				} else {
					return [list "offline"]
				}
			} else {
				return [list "online"]
			}

		# Group mode
		} elseif { $mode == 1} {
			return [::abook::getGroups $email]
		}
		
		# Hybrid Mode, we add offline group
		if { $mode == 2 } {
			if { $status == "FLN" } {
				if { [::abook::getContactData $email msn_mobile] == "1" && [::config::getKey showMobileGroup] == 1} {
					return [list "mobile"]
				} else {
					return [list "offline"]
				}
			} else {
				return [::abook::getGroups $email]
			}
		}
	}

	###############################################	
	# Here we create the balloon message
	# and we add the binding to the canvas item.
	proc getBalloonMessage {email element} {
		# Get variables
		set not_in_reverse [expr {[lsearch [::abook::getLists $email] RL] == -1}]
		set state_code [::abook::getVolatileData $email state FLN]

		# If user is not in list, add it to the balloon
		if { $not_in_reverse } {
			set balloon_message2 "\n[trans notinlist]"
		} else {
			set balloon_message2 ""
		}

		# If order in status mode, show the group of the contact in the balloon
		if { [::config::getKey orderbygroup] == 0 } {
			set groupname [::abook::getGroupsname $email]
			set balloon_message3 "\n[trans group] : $groupname"
		} else {
			set balloon_message3 ""
		}

		# If the status is offline, get the last time he was online
		if { $state_code == "FLN" } {
			set balloon_message4 "\n[trans lastseen] : [::abook::dateconvert \
				[::abook::getContactData $email last_seen]]"
		} else {
			set balloon_message4 ""
		}

		set psmmedia [::abook::getpsmmedia $email]

		# Define the final balloon message
		set ballon_message [::abook::getNick $email]
		append ballon_message "\n$psmmedia"
		append ballon_message "\n$email\n"
		append ballon_message "[trans status] : "
		append ballon_message [trans [::MSN::stateToDescription $state_code]]
		append ballon_message "$balloon_message2 $balloon_message3 $balloon_message4\n[trans lastmsgedme] : "
		append ballon_message [::abook::dateconvert [::abook::getContactData $email last_msgedme]]
		set balloon_message [string map {"%" "%%"} $ballon_message]
		return $balloon_message	
	}


	proc truncateText { text maxwidth font } {
		set shortened ""
		set stringlength [string length $text]

		# Store stringlength
		for {set x 0} {$x < $stringlength} {incr x} {
			set nextchar [string range $text $x $x]
			set nextstring "$shortened$nextchar"
			if {[font measure $font $nextstring] > $maxwidth} {
				break
			}
			set shortened "$nextstring"
		}
		return $shortened
	}


	#######################################################
	# Procedure that draws horizontal lines from this list
	# of [list xcoord xcoord linelength] lists
	proc underlineList { canvas lines nicktag} {
		set poslist [$canvas coords $nicktag]
		set xpos [lindex $poslist 0]
		set ypos [lindex $poslist 1]
		# status_log "poslist: $lines"
		variable OnTheMove

		# if {!$OnTheMove} {
			foreach line $lines {
				$canvas create line [expr [lindex $line 0] + $xpos] \
					[expr [lindex $line 1] + $ypos] [expr [lindex $line 0] \
					+ [lindex $line 2] + $xpos] [expr [lindex $line 1] + $ypos] \
					-fill [lindex $line 3] -tags [list uline_$nicktag $nicktag uline]
			}
		# }
		$canvas lower uline_$nicktag $nicktag
	}

	proc setScroll { scrollbar first last } {
		variable clcanvas
		set visible [expr {$last - $first}]
		if { $visible < 1 && ![winfo ismapped $scrollbar] } {
			pack $scrollbar -side right -fill y -before $clcanvas
		} elseif { $visible >= 1 && [winfo ismapped $scrollbar] } {
			pack forget $scrollbar
		}
		$scrollbar set $first $last
	}

	#######################################################
	# Procedure which scrolls the canvas up/down
	proc scrollCL {canvas direction} {
		set canvaslength [lindex [$canvas cget -scrollregion] 3]

		if {[winfo height $canvas] <= $canvaslength} {
			if {$direction == "down" || $direction == "-1"} {
				$canvas yview scroll 1 units
			} else {
				$canvas yview scroll -1 units
			}
		
			# Here we have to move the background-image. This should
			# be done as a command given to scrolledwindow, so it also
			# works when dragging the scrollbar
			moveBGimage $canvas

			# $canvas coords backgroundimage 0 [expr int([expr \
			#	[lindex [$canvas yview] 0] * $canvaslength])]
		}
	}

	#######################################################
	# Procedure which scrolls the canvas up/down
	proc scrollCLsb {canvas args} {
			
			eval [linsert $args 0 $canvas yview]
		
			# Here we have to move the background-image. This should
			# be done as a command given to scrolledwindow, so it also
			# works when dragging the scrollbar
			moveBGimage $canvas

	}


	proc createNicknameArray {} {
		variable nicknameArray
		array set nicknameArray {}

		set userList [::MSN::sortedContactList]

		foreach user $userList {
			set usernick [::abook::getDisplayNick $user 1]
			set nicknameArray($user) [::smiley::parseMessageToList $usernick 1]
		}

		# TODO: Review this event, maybe it would fit better in other place
		set evpar(array) nicknameArray
		set evpar(login) ""
		::plugins::PostEvent NickArray evpar
	}

	proc switch_alarm { email canvas alarm_image } {
		if { [::alarms::getAlarmItem $email enabled] == 1 } {
			$canvas itemconfigure $alarm_image -image [::skin::loadPixmap bell]
		} else {
			$canvas itemconfigure $alarm_image -image [::skin::loadPixmap belloff]
		}
	}


	#####################################
	#    Contact dragging procedures    #
	#####################################
	proc contactPress {tag canvas} {
		variable OldDragX
		variable OldDragY
		variable OnTheMove
		variable DragStartX
		variable DragStartY

		# Store old coordinates
		set DragStartX [winfo pointerx .]
		set DragStartY [winfo pointery .]
		set OldDragX $DragStartX
		set OldDragY $DragStartY

		set OnTheMove 1

		$canvas delete uline_$tag
	}


	proc contactMove {tag canvas} {
		variable OldDragX
		variable OldDragY

		#Move the contact, (New_X_Mouse_coord - Old_X_Mouse_coord) on the X-axis, same for Y
		$canvas move $tag [expr {[winfo pointerx .] - $OldDragX}] [expr {[winfo pointery .] - $OldDragY}]

		set OldDragX [winfo pointerx .]
		set OldDragY [winfo pointery .]

		# TODO: * Make the canvas scroll if we hover the vertical edges of the canvas
		# 	* Make the dragged contact stay under the cursor
		# 	* Make it keep scrolling as long as we are in the area also if we don't move (extra proc)

#		set canvaslength [lindex [$canvas cget -scrollregion] 3]

		# if {[lindex [$canvas coords $email] 1] >= [expr [winfo height $canvas] - 20] } {
		# 	after 300 
		# 	::guiContactList::scrollCL down $canvaslength
		# }
		# !!! Won't work this way
		$canvas delete uline_$tag
		
	}


	proc contactReleased {tag canvas} {
		variable OnTheMove
		variable OldDragX
		variable OldDragY
		variable DragStartX
		variable DragStartY

		set oldgrId [::guiContactList::getGrIdFromTag $tag]

		# Kill the balloon if it came up, otherwise it just stays there
		set Bulle(first) 0; kill_balloon


		set iconXCoord [lindex [$canvas coords $tag] 0]
		set iconYCoord [lindex [$canvas coords $tag] 1]

		set ChangeX [expr {$DragStartX - [winfo pointerx .]}]
		set ChangeY [expr {$DragStartY - [winfo pointery .]}]


		# TODO: If we drag off the list; now it's only on the left, make 
		# 	it also "if bigger then viewable area of canvas and on top
		#       and down sides
		# Check if we're not dragging off the CL
		if {$iconXCoord < 0 } { 
			# TODO: Here we should trigger an event that can be used
			# 	by plugins. For example, the contact tray plugin
			# 	could create trays like this

			status_log "guiContactList: contact dragged off the CL\n\t\tTODO: add event"

			$canvas move $tag $ChangeX $ChangeY
		} else {

			# Now we have to find the group whose ycoord is the first
			# less then this coord

			# Beginsituation: group to move to is group where we began
			set newgrId $oldgrId

			# Cycle to the list of groups and select the group where
			# the user drags to
#TODO: remove the group of origin, the mobile and the offline group from this list ?
			foreach group [getGroupList 1] {
				# Get the group ID
				set grId [lindex $group 0]
				set grCoords [$canvas coords gid_$grId]
				# Only go for groups that are actually drawn on the list
				if { $grCoords != ""} {
					# Get the coordinates of the group
					set grYCoord [lindex $grCoords 1]
					# This +5 is to make dragging a contact on a group's name
					# or 5 pixels above the group's name possible
					if {$grYCoord <= [expr $iconYCoord + 5]} {
						set newgrId $grId
					}
				}
			}
	
			if { $newgrId == $oldgrId } {
				#if the contact was dragged to the group of origin, just move it back
#				$canvas move $tag $ChangeX $ChangeY	
				
				#To be sure everything is right, reorganise, because the contact doesn't always
				#  stay under the cursor
				::guiContactList::organiseList $canvas				
			} else {
# TODO: copying instead of moving when CTRL is pressed

				# Move the contact between the groups
				::groups::menuCmdMove $newgrId $oldgrId [::guiContactList::getEmailFromTag $tag]
				# Note: redraw is done by the protocol event

			} 
		}

		set OnTheMove 0

		# Remove those vars as they're not in use anymore
		unset OldDragX
		unset OldDragY
	}


	proc getEmailFromTag { tag } {
		set pos [string last _ $tag]
		set email [string range $tag 0 [expr $pos -1]]
		return $email
	}


	proc getGrIdFromTag { tag } {
		set pos [string last _ $tag]
		set grId [string range $tag [expr $pos + 1] end]
		return $grId
	}
}

