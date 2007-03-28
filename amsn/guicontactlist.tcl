# New Contact List :: Based on canvas
#
# This module is still experimental, a lot of work is still needed.
#
# Things to be done (TODO):
#
# * change cursor while dragging (should we ?)
# *
# *
# * ... cfr. "TODO:" msgs in code

::Version::setSubversionId {$Id$}

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

		set clcanvas [createCLWindowEmbeded $clcontainer]

		# Embed the canvas in the ScrolledWindow
		#$clcontainer setwidget $clcanvas
		# Pack the scrolledwindow in the window
		pack $clcontainer -expand true -fill both

		#pack $clscrollbar -side right -fill y



		# Let's avoid the bug of window behind the bar menu on MacOS X
		catch {wm geometry $window [::config::getKey wingeometry]}
		if {[OnMac]} {
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
		variable GroupsRedrawQueue
		variable ContactsRedrawQueue
		variable NickReparseQueue
		variable contactAfterId
		variable resizeAfterId
		variable scrollAfterId
		variable displayCWAfterId
		variable external_lock
		variable OnTheMove

		set clframe $w.cl
		set clcanvas $w.cl.cvs
		set clscrollbar $w.cl.vsb
		
		set ContactsRedrawQueue [list]
		set GroupsRedrawQueue [list]
		set NickReparseQueue [list]
		
		set contactAfterId 0
		set resizeAfterId 0
		set scrollAfterId 0
		set displayCWAfterId 0

		#This means that the CL hasn't been locked by external code
		set external_lock 0

		#This means that we aren't currently dragging
		set OnTheMove 0

		#here we load images used in this code:
		::skin::setPixmap back back.gif
		::skin::setPixmap back2 back2.gif
		::skin::setPixmap upleft box_upleft.gif
		::skin::setPixmap up box_up.gif
		::skin::setPixmap upright box_upright.gif
		::skin::setPixmap left box_left.gif
		::skin::setPixmap body box_body.gif
		::skin::setPixmap right box_right.gif
		::skin::setPixmap downleft box_downleft.gif
		::skin::setPixmap down box_down.gif
		::skin::setPixmap downright box_downright.gif

		variable Xbegin
		variable Ybegin

		set Xbegin [::skin::getKey contactlist_xpad]
		set Ybegin [::skin::getKey contactlist_ypad]

		frame $w.cl -background [::skin::getKey contactlistbg] -borderwidth 0

		scrollbar $clscrollbar -command [list ::guiContactList::scrollCLsb $clcanvas] \
			-background [::skin::getKey contactlistbg]
		# Create a blank canvas
		canvas $clcanvas -background [::skin::getKey contactlistbg] \
			-yscrollcommand [list ::guiContactList::setScroll $clscrollbar] -borderwidth 0

		drawBG $clcanvas 1
		
		after 0 ::guiContactList::drawList $clcanvas

		# Register events
		::Event::registerEvent contactStateChange all ::guiContactList::contactChanged
		::Event::registerEvent contactNickChange all ::guiContactList::contactChanged
		::Event::registerEvent contactDataChange all ::guiContactList::contactChanged
		::Event::registerEvent contactPSMChange all ::guiContactList::contactChanged
		::Event::registerEvent contactAlarmChange all ::guiContactList::contactChanged
		::Event::registerEvent contactSpaceChange all ::guiContactList::contactChanged
		::Event::registerEvent contactSpaceFetched all ::guiContactList::contactChanged
		::Event::registerEvent contactListChange all ::guiContactList::contactChanged
		::Event::registerEvent contactBlocked all ::guiContactList::contactChanged
		::Event::registerEvent contactUnblocked all ::guiContactList::contactChanged
		::Event::registerEvent contactMoved all ::guiContactList::contactChanged
		::Event::registerEvent contactAdded all ::guiContactList::contactChanged
		::Event::registerEvent contactRemoved all ::guiContactList::contactRemoved
		::Event::registerEvent groupRenamed all ::guiContactList::groupChanged
		::Event::registerEvent groupAdded all ::guiContactList::groupChanged
		::Event::registerEvent groupRemoved all ::guiContactList::groupRemoved
		::Event::registerEvent contactlistLoaded all ::guiContactList::contactlistLoaded
		::Event::registerEvent loggedOut all ::guiContactList::loggedOut
		::Event::registerEvent changedSorting all ::guiContactList::changedSorting
		::Event::registerEvent changedNickDisplay all ::guiContactList::changedNickDisplay
		::Event::registerEvent changedPreferences all ::guiContactList::changedPreferences
		::Event::registerEvent changedSkin all ::guiContactList::changedSkin

		# MacOS Classic/OSX and Windows
		if {[OnMac]} {
			bind $clcanvas <MouseWheel> {
				%W yview scroll [expr {- (%D)}] units;

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
			bind $clcanvas <ButtonPress-5> [list ::guiContactList::scrollCL $clcanvas down]
			bind $clcanvas <ButtonPress-4> [list ::guiContactList::scrollCL $clcanvas up]
		}


		bind $clcanvas <Configure> "::guiContactList::clResized $clcanvas"

		pack $clscrollbar -side right -fill y

		pack $clcanvas -expand true -fill both

		return $clframe
	}

	proc lockContactList { } {
		#Here, only the calling proc should draw on the contact list. The contact list isn't drawn anymore.
		variable external_lock
		variable clcanvas
		variable contactAfterId

		if { $external_lock > 1 } { return "" }
		set external_lock 2
		catch {after cancel $contactAfterId}
		if { [winfo exists $clcanvas] } {
			$clcanvas addtag all_cl all
			$clcanvas delete all_cl
			$clcanvas configure -scrollregion [list 0 0 2000 0]
			return $clcanvas
		}
		return ""
	}

	proc semiUnlockContactList {} {
		# Here only external procs can write after grabbing a lock
		variable external_lock

		if { $external_lock != 2 } { return }
		set external_lock 1	
	}

	proc unlockContactList {} {
		#Here everybody can write to the CL (but external procs should grab a lock before writing)
		variable external_lock
		variable clcanvas

		if { !$external_lock } { return }
		set external_lock 0

		if { [winfo exists $clcanvas] } {
			$clcanvas addtag all_cl all
			$clcanvas delete all_cl
			drawBG $clcanvas 1

			if { $::contactlist_loaded } {
				::guiContactList::drawList $clcanvas
			}
		}
	}

	proc clResized { clcanvas } {
		#redraw the contacts as the width might have changed and reorganise
		variable resizeAfterId
#If, within 500 ms, another event for redrawing comes in, we redraw 'm together
		catch {after cancel $resizeAfterId}		
		set resizeAfterId [after 500 "::guiContactList::drawBG $clcanvas 0; \
			::guiContactList::drawContacts $clcanvas; \
			::guiContactList::organiseList $clcanvas;"]
		::guiContactList::centerItems $clcanvas
	}

	#/////////////////////////////////////////////////////////////////////
	# Function that draws everything needed on the canvas
	#/////////////////////////////////////////////////////////////////////
	proc drawList {canvas} {
		if { ${::guiContactList::external_lock} } { return }

		::guiContactList::drawGroups $canvas
		::guiContactList::drawContacts $canvas
		::guiContactList::organiseList $canvas
	}
	


	proc moveBGimage { canvas } {
		set canvaslength [lindex [$canvas cget -scrollregion] 3]
		if {$canvaslength == ""} { set canvaslength 0}
		$canvas coords backgroundimage 0 [expr {int([expr {[lindex [$canvas yview] 0] * $canvaslength}])}]
		$canvas lower backgroundimage
	}


	proc drawGroups { canvas } {

		if { ${::guiContactList::external_lock} } { return }

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

		if { ${::guiContactList::external_lock} } { return }
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

	proc drawBG { canvas create} {
		set bg_exists [llength [$canvas find withtag backgroundimage]]
		if { $bg_exists == 0 && !$create } { return }

		if {[catch {image type contactlist_background} imagetype] != 0 || $imagetype == ""} {
			image create photo contactlist_background
		}

		if { [::skin::getKey contactlistbgtile 0] != 0 } {
			contactlist_background configure -width [winfo width $canvas] -height [winfo height $canvas]
		} else {
			if { [::skin::getKey contactlistbgnontiled 1] != 0 } {
				set skin_image [::skin::loadPixmap back]
				contactlist_background configure -width [image width $skin_image] \
					-height [image height $skin_image]
			} else {
				contactlist_background configure -width 0 -height 0
			}
		}

		if { [::skin::getKey contactlistbgtile 0] != 0 } {
			set skin_image_tile [::skin::loadPixmap back2]
			contactlist_background copy $skin_image_tile \
				-to 0 0 [winfo width $canvas] [winfo height $canvas]
		}
		if { [::skin::getKey contactlistbgnontiled 1] != 0 } {
			set skin_image [::skin::loadPixmap back]
			contactlist_background copy $skin_image -to 0 0 \
				[image width $skin_image] [image height $skin_image]
		}

		if { $bg_exists == 0 } {
			$canvas create image 0 0 -image contactlist_background -anchor nw -tag backgroundimage
			$canvas configure -scrollregion [list 0 0 2000 [lindex [$canvas bbox backgroundimage] 3]]
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
			::guiContactList::drawList $clcanvas
		}
	}

	proc changedNickDisplay { eventused } {
		variable clcanvas
		if { [winfo exists $clcanvas] } {
			::guiContactList::drawList $clcanvas
		}
	}

	proc changedSkin { eventused } {
		variable clcanvas
		if { [winfo exists $clcanvas] } {
			catch { contactlist_background blank }
			drawBG $clcanvas 0
			::guiContactList::drawList $clcanvas
		}
	}

	proc loggedOut { eventused } {
		variable clcanvas

		if { ${::guiContactList::external_lock} } { return }

		if { [winfo exists $clcanvas] && !$::contactlist_loaded } {
			$clcanvas addtag all_cl all
			$clcanvas delete all_cl
			drawBG $clcanvas 1
		}

	}


	proc contactlistLoaded { eventused } {
		variable clcanvas

		if { [winfo exists $clcanvas] } {
			::guiContactList::drawList $clcanvas
		}

	}

	proc contactRemoved { eventused email { gidlist ""} } {
		variable GroupsRedrawQueue

		set grId [lindex $gidlist 0]
		if {[lsearch $GroupsRedrawQueue $grId] == -1 || [lsearch $GroupsRedrawQueue all] == -1} {
			lappend GroupsRedrawQueue $grId
		}

		catch {after cancel $contactAfterId}
		set contactAfterId [after 500 ::guiContactList::redrawFromQueue]
	}

	proc groupRemoved { eventused gid } {
		variable clcanvas
		if { [winfo exists $clcanvas] } {
			::guiContactList::organiseList $clcanvas
		}
	}

	proc groupChanged { eventused grId grName } {
		variable GroupsRedrawQueue
		if {[lsearch $GroupsRedrawQueue $grId] == -1 || [lsearch $GroupsRedrawQueue all] == -1} {
			lappend GroupsRedrawQueue $grId
		}
		catch {after cancel $contactAfterId}
		set contactAfterId [after 500 ::guiContactList::redrawFromQueue]
	}

	proc contactChanged { eventused emails { gidlist ""} } {
		variable clcanvas

		if { ![winfo exists $clcanvas] } {
			return
		}
		
		variable GroupsRedrawQueue
		variable ContactsRedrawQueue
		variable NickReparseQueue		
		variable contactAfterId
		
		#Check what has to be done and add to the redrawing queues
		foreach email $emails {
#			status_log "contactChanged :: $eventused $email $gidlist" green
			#Possible events:
			#contactStateChange
			#contactNickChange;
			#contactDataChange
			#contactPSMChange;
			#contactListChange
			#contactBlocked
			#contactUnblocked
			#contactMoved
			#contactAdded;



			if { $email == "contactlist" } {
				return
			}

			if { $email == "myself" } {
				return
			}

	#######################
	#Contacts (re)drawing #
	#######################

			if { $eventused == "contactNickChange" || $eventused == "contactAdded" || $eventused == "contactPSMChange" || $eventused == "contactDataChange"} {
				if {[lsearch $NickReparseQueue $email] == -1} {
					lappend NickReparseQueue $email
				}
			}
			
			# Redraw the contact for every group it's in
			#  Only for a contact that's simply moved, it doesn't have to be redrawn
			if {$eventused != "contactMoved"} {
				if {[lsearch $ContactsRedrawQueue $email]  == -1} {
					lappend ContactsRedrawQueue $email
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
				#redraw the old group
				set grId [lindex $gidlist 0]
				if {[lsearch $GroupsRedrawQueue $grId] == -1 || [lsearch $GroupsRedrawQueue all] == -1} {
					lappend GroupsRedrawQueue $grId
				}
#FIXME:				#remove the contact from the list
			}

			if { $eventused == "contactAdded" } {
				#redraw the old group
				set grId [lindex $gidlist 0]
				if {[lsearch $GroupsRedrawQueue $grId] == -1 || [lsearch $GroupsRedrawQueue all] == -1} {
					lappend GroupsRedrawQueue $grId
				}
			}

			if {$eventused == "contactStateChange" } {
				set GroupsRedrawQueue [list all]
			}

			#listchange/datachange: redraw everything as I don't really know what it's all for
			if {$eventused == "contactDataChange" || $eventused == "contactListChange"} {
				set GroupsRedrawQueue [list all]
			}
		
		}; #end of foreach

		#If, within 500 ms, another event for redrawing comes in, we redraw 'm together
		catch {after cancel $contactAfterId}

		# If toggleSpaceShown or contactAlarmChange is called, then free the drawing queue because we need user interaction to be spontanuous.
		if {$eventused == "toggleSpaceShown" || $eventused == "contactAlarmChange" } {
			::guiContactList::redrawFromQueue
		} else {
			set contactAfterId [after 500 ::guiContactList::redrawFromQueue]
		}

	}
	
	
	
	proc redrawFromQueue {} {
		variable clcanvas
		variable external_lock
		
		variable GroupsRedrawQueue
		variable ContactsRedrawQueue
		variable NickReparseQueue
		
		#copy queues and reset 'm so they can be filled again while the 
		#  redrawing is still busy : that's safer

		set contacts $ContactsRedrawQueue
		set groups $GroupsRedrawQueue

		set ContactsRedrawQueue [list]
		set GroupsRedrawQueue [list]

		if { $external_lock } { return }

		#redraw contacts
		foreach contact $contacts {
			set groupslist [getGroupId $contact]
			foreach group $groupslist {
				set contactelement [list "C" $contact]
				::guiContactList::drawContact $clcanvas $contactelement $group
			}
		}
		foreach group $groups {
			switch $group {
				"all" {
					::guiContactList::drawGroups $clcanvas
				}
				default {
					::guiContactList::drawGroup $clcanvas [list $group [::groups::GetName $group]]
				}
			}
		}
		
		#reorganise list
		::guiContactList::organiseList $clcanvas
#		status_log "contactChanged :: List redrawn for contacts $contacts, groups $groups, $nicks reparsed" green
					
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

		if { ${::guiContactList::external_lock} || !$::contactlist_loaded } { return }

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

		# Let's draw each element of this list
		set curPos [list $Xbegin $Ybegin]


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
					[expr [lindex $curPos 1] - [lindex $currentPos 1] + $ypad]

				set curPos [list [lindex $curPos 0] [expr {[lindex $curPos 1] + $nickheightArray($email) + $ypad}] ]
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
				set boXpad $Xbegin
				set width [expr {$maxwidth - ($boXpad*2)}]
				if {$width <= 30} {set width 300}

				# If we're not drawing the first group, we should draw the end of the box of the \
				# group before here and change the curPos
				if {!$DrawingFirstGroup} {
					set bodYend [expr {[lindex $curPos 1] + [::skin::getKey buddy_ypad]}]
					# Here we should draw the body
					set height [expr {$bodYend - $bodYbegin}]
					if {$height > [::skin::getKey buddy_ypad]} {
						image create photo boxbodysmall_$groupDrawn -height \
							[image height [::skin::loadPixmap left]] -width $width
						boxbodysmall_$groupDrawn copy [::skin::loadPixmap left] -to 0 0 \
							[image width [::skin::loadPixmap left]] \
							[image height [::skin::loadPixmap left]]
						boxbodysmall_$groupDrawn copy [::skin::loadPixmap body] -to \
							[image width [::skin::loadPixmap left]] 0 \
							[expr {$width -  [image width [::skin::loadPixmap right]]}] \
							[image height [::skin::loadPixmap body]]
						boxbodysmall_$groupDrawn copy [::skin::loadPixmap right] -to \
							[expr {$width - [image width [::skin::loadPixmap right]]}] 0 \
							$width [image height [::skin::loadPixmap right]]

						image create photo boxbody_$groupDrawn -height $height -width $width
						boxbody_$groupDrawn copy boxbodysmall_$groupDrawn -to 0 0 $width $height
						image delete boxbodysmall_$groupDrawn
					
						# Draw it
						$canvas create image $boXpad $bodYbegin -image boxbody_$groupDrawn \
							-anchor nw -tags [list box box_body $gid]
					} else {
						set bodYend $bodYbegin
					}

					# Create endbar of the box
					image create photo boxdownbar_$groupDrawn \
						-height [image height [::skin::loadPixmap down]] -width $width
					boxdownbar_$groupDrawn copy [::skin::loadPixmap downleft] -to 0 0 \
						[image width [::skin::loadPixmap downleft]] \
						[image height [::skin::loadPixmap downleft]]
					boxdownbar_$groupDrawn copy [::skin::loadPixmap down] -to \
						[image width [::skin::loadPixmap downleft]] 0 \
						[expr {$width -  [image width [::skin::loadPixmap downright]]}] \
						[image height [::skin::loadPixmap down]]
					boxdownbar_$groupDrawn copy [::skin::loadPixmap downright] -to \
						[expr {$width - [image width [::skin::loadPixmap downright]]}] 0 \
						$width [image height [::skin::loadPixmap downright]]
					$canvas create image $boXpad $bodYend -image boxdownbar_$groupDrawn -anchor nw \
						-tags [list box box_downbar $gid]

					set curPos [list [lindex $curPos 0] [expr {[lindex $curPos 1]+ $ypad}] ]
				} else {
					#set curPos [list [lindex $curPos 0] [lindex $curPos 1] ]
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
				boxupbar_$groupDrawn copy [::skin::loadPixmap upleft] -to 0 0 \
					[image width [::skin::loadPixmap upleft]] \
					[image height [::skin::loadPixmap upleft]]
				boxupbar_$groupDrawn copy [::skin::loadPixmap up] -to \
					[image width [::skin::loadPixmap upleft]] 0 \
					[expr {$width -  [image width [::skin::loadPixmap upright]]}] \
					[image height [::skin::loadPixmap up]]
				boxupbar_$groupDrawn copy [::skin::loadPixmap upright] -to \
					[expr {$width - [image width [::skin::loadPixmap upright]]}] 0 \
					$width [image height [::skin::loadPixmap upright]]

				# Draw it
				set topYbegin [lindex $curPos 1]
				$canvas create image $boXpad $topYbegin -image boxupbar_$groupDrawn -anchor nw \
					-tags [list box box_upbar $gid]

				# Save the endypos for next body drawing
				set bodYbegin [expr {$topYbegin + [image height [::skin::loadPixmap up]]}]

				set grpBbox [$canvas bbox $tag]
				#Here we center the group text in the up pixmap
				set ypos [expr {[lindex $curPos 1]+([image height [::skin::loadPixmap up]])/2 \
				- ([lindex $grpBbox 3] - [lindex $grpBbox 1])/2 }]
			
				$canvas move $tag [expr {[lindex $curPos 0] - [lindex $currentPos 0] + $xpad}] \
					[expr {$ypos - [lindex $currentPos 1]}]

				set curPos [list [lindex $curPos 0] \
					[expr {[lindex $curPos 1] + [image height [::skin::loadPixmap up]]}]]
				# 	as we already drew a group, the next won't be the first anymore
				set DrawingFirstGroup 0

				# END the "else it's a group"
			}
			# END of foreach
		}

		if { [llength $contactList] > 0 } {
			# Now do the body and the end for the last group:
			set bodYend [expr {[lindex $curPos 1] + [::skin::getKey buddy_ypad]}]
	
			# Here we should draw the body
			set height [expr {$bodYend - $bodYbegin}]
	
			if {$height > [::skin::getKey buddy_ypad]} {
				image create photo boxbodysmall_$groupDrawn \
					-height [image height [::skin::loadPixmap left]] -width $width
				boxbodysmall_$groupDrawn copy [::skin::loadPixmap left] -to 0 0 \
					[image width [::skin::loadPixmap left]] \
					[image height [::skin::loadPixmap left]]
				boxbodysmall_$groupDrawn copy [::skin::loadPixmap body] -to \
					[image width [::skin::loadPixmap left]] 0 \
					[expr {$width -  [image width [::skin::loadPixmap right]]}] \
					[image height [::skin::loadPixmap body]]
				boxbodysmall_$groupDrawn copy [::skin::loadPixmap right] -to \
					[expr {$width - [image width [::skin::loadPixmap right]]}] 0 \
					$width  [image height [::skin::loadPixmap right]]
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
			image create photo boxdownbar_$groupDrawn \
				-height [image height [::skin::loadPixmap down]] -width $width
			boxdownbar_$groupDrawn copy [::skin::loadPixmap downleft] -to 0 0 \
				[image width [::skin::loadPixmap downleft]] \
				[image height [::skin::loadPixmap downleft]]
			boxdownbar_$groupDrawn copy [::skin::loadPixmap down] -to \
				[image width [::skin::loadPixmap downleft]] 0 \
				[expr {$width -  [image width [::skin::loadPixmap downright]]}] \
				[image height [::skin::loadPixmap down]]
			boxdownbar_$groupDrawn copy [::skin::loadPixmap downright] -to \
				[expr {$width - [image width [::skin::loadPixmap downright]]}] 0 \
				$width [image height [::skin::loadPixmap downright]]

			$canvas create image $boXpad $bodYend -image boxdownbar_$groupDrawn -anchor nw \
				-tags [list box box_downbar $gid]
	
				# Get the group-boxes behind the groups and contacts
			$canvas lower box items
		}

		# Set height of canvas
		set canvaslength [expr {[lindex $curPos 1] + 20}]
		$canvas configure -scrollregion [list 0 0 2000 $canvaslength]
			# Make sure after redrawing the bgimage is on the right place
		$canvas coords backgroundimage 0 [expr {int([expr {[lindex [$canvas yview] 0] * $canvaslength}])}]
	}

	#/////////////////////////////////////////////////////////////////////////
	# Function that draws a group 
	#/////////////////////////////////////////////////////////////////////////
	proc drawGroup { canvas element} {
		if { ${::guiContactList::external_lock} || !$::contactlist_loaded } { 
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
		set textxpos [expr {$xpos + [image width $img] + $xpad}]

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
		$canvas bind $gid <Enter> [list ]
		$canvas bind $gid <Motion> [list ]
		$canvas bind $gid <Leave> [list ]
		$canvas bind $gid <<Button1>> [list ]
		$canvas bind $gid <<Button3>> [list ]

		$canvas bind $gid <<Button1>> +[list ::guiContactList::toggleGroup $element $canvas]
		$canvas bind $gid <<Button3>> +[list ::groups::GroupMenu [lindex $element 0] %X %Y]

		# Add binding for underline if the skinner use it
		if {[::skin::getKey underline_group]} {
			$canvas bind $gid <Enter> +[list ::guiContactList::underlineList $canvas $underlinst $gid]
			$canvas bind $gid <Leave> +[list $canvas delete uline_$gid]
		}

		#cursor change bindings
		if { [::skin::getKey changecursor_group] } {
			$canvas bind $gid <Enter> +[list ::guiContactList::configureCursor $canvas hand2]
			$canvas bind $gid <Leave> +[list ::guiContactList::configureCursor $canvas left_ptr]
		}
	}


	#/////////////////////////////////////////////////////////////////////////
	# Function that draws a contact 
	#/////////////////////////////////////////////////////////////////////////
	proc drawContact { canvas element groupID } {
	
		# We are gonna store the height of the nicknames
		variable nickheightArray

		#Xbegin is the padding between the beginning of the contact and the left edge of the CL
		variable Xbegin
		

		if { ${::guiContactList::external_lock} || !$::contactlist_loaded } { return }

		# Set the place for drawing it (should be invisible); these vars won't be changed
		set xpos 0
		set ypos 0
		
		set email [lindex $element 1]
		set grId $groupID

		################################################################
		# Set up names for tags to be put on different elements 
		################################################################

		# The tag can't be just $email as users can be in more then one group
		#$tag is a tag applied to all elements of the contact
		set tag "_$grId"; set tag "$email$tag"
		#$main_part is a tag applied to all elements that make a chatwindow open
		# if they are clicked
		set main_part "${tag}_click"
		#space_icon is a tag for the icon showing if the contact's MSN Space is updated
		set space_icon "${tag}_space_icon"
		set space_info "${tag}_space_info"
		
		#Delete elements of the contact if they still exist
		$canvas delete $tag



		################################################################
		# Set up some vars with info we'll use
		################################################################

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

		set psm [::abook::getpsmmedia $email 1]

		#@@@@@@@@@ Show webMSN buddy icon
		if { [::MSN::userIsBlocked $email] } {
			if { $state_code == "FLN" } { 
				set img [::skin::loadPixmap blocked_off] 
			} else {    
				set img [::skin::loadPixmap blocked] 
			}
		} elseif { [::abook::getContactData $email client] == "Webmessenger" && $state_code != "FLN" } {
			set img [::skin::loadPixmap webmsn]
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
		set parsednick [::abook::getDisplayNick $email 1]
		#the padding between nickname and state
		set nickstatespacing 5

		if { [::abook::getContactData $email client] == "Webmessenger" && $state_code != "FLN" } { 
			set statetext "\([trans web]\/[trans [::MSN::stateToDescription $state_code]]\)"
		} else {
			set statetext "\([trans [::MSN::stateToDescription $state_code]]\)"
			if {$state_code == "NLN" || $state_code == "FLN"} {
				set nickstatespacing 0
				set statetext ""
			}
			if {$grId == "mobile"} {
				set nickstatespacing 5
				set statetext "\([trans mobile]\)"
			}
		}

		# TODO: skinsetting for state-colour
		set statecolour grey

		set statewidth [font measure splainf $statetext]

		# Set the beginning coords for the drawings, these vars will change\
		 after every drawing so we know where to draw the next element
		set xnickpos $xpos
		#the first line will be drawn around the middle of the status icon
		set ynickpos [expr {$ypos + [image height $img]/2}]

		set update_img [::skin::loadPixmap space_update]
		set noupdate_img [::skin::loadPixmap space_noupdate]
		
		
		# Reset the underlining's list
		set underlinst [list]
		
		#this is when there is an update and we should show a star
		set space_update [::abook::getVolatileData $email space_updated 0]
		
		#is the space shown or not ?
		set space_shown [::abook::getVolatileData $email SpaceShowed 0]
		


		################################################################
		# Beginning of the drawing
		################################################################

		#--------------#
		###Space icon###
		#--------------#
		
		# Check if we need an icon to show an updated space/blog, and draw one if we do
		# We must create the icon and hide after else, the status icon will stick the border \
		# it's surely due to anchor parameter
		$canvas create image $xnickpos $ypos -anchor nw \
			 -image $noupdate_img -tags [list contact icon $tag $space_icon]
		if { [::abook::getVolatileData $email HSB 0] } {
			if {$space_update} {
				$canvas itemconfigure $space_icon -image $update_img
			}
		} else {
			$canvas itemconfigure  $space_icon -state hidden
		}

		#Update xnickpos
		set xnickpos [expr {$xnickpos + [image width $update_img]}]
		
		#---------------#
		###Status icon###
		#---------------#

		# Draw status-icon
		$canvas create image $xnickpos $ynickpos -image $img -anchor w -tags [list contact icon $tag $main_part]

		#Update xnickpos (5 pixels hardcoded padding between statusicon and nickname)
		set xnickpos [expr {$xnickpos + [image width $img] + 5}]

# TODO: skin setting to draw buddypicture; statusicon should become icon + status overlay
# 	like:	draw icon or small buddypicture overlay it with the status-emblem

		#--------------#
		###Alarm icon###
		#--------------#

		#Draw alarm icon if alarm is set
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
			
			$canvas create image [expr {$xnickpos -3}] $ypos -image \
				$icon -anchor nw -tags [list contact icon alarm_$email $tag $main_part]

			# Binding for right click		 
			$canvas bind alarm_$email <<Button3>> "::alarms::configDialog \"$email\"; break;"
			$canvas bind alarm_$email <Button1-ButtonRelease> "switch_alarm \"$email\"; \
				::guiContactList::switch_alarm \"$email\" \"$canvas\" \"alarm_$email\"; break"

			#Update xnickpos
			set xnickpos [expr {$xnickpos + [image width $icon]}]
		}
		
		#----------------------------#
		###Not-on-reverse-list icon###
		#----------------------------#	

		# If you are not on this contact's list, show the notification icon
		if {[expr {[lsearch [::abook::getLists $email] RL] == -1}]} {
			set icon [::skin::loadPixmap notinlist]
			$canvas create image [expr {$xnickpos -3}] $ypos -image \
				[::skin::loadPixmap notinlist] -anchor nw -tags \
				[list contact icon $tag $main_part]
			#Update xnickpos
			set xnickpos [expr {$xnickpos + [image width $icon]}]
		}
		

		# Now we're gonna draw the nickname itself

		#-----------------#
		###Draw Nickname###
		#-----------------#

		#store the x-coord of the beginning of a line
		set xlinestart $xnickpos

		#set up the maximum width to use according to trancution setting
		if { [::config::getKey truncatenames] } {
			set ellips "..."
			# Leave some place for the statustext, the elipsis (...) and the spacing + spacing
			# of border and - the beginningborder
			set maxwidth [expr {[winfo width $canvas] - $statewidth - [font measure splainf $ellips] - \
				$nickstatespacing - 5 - 2*$Xbegin - [::skin::getKey buddy_xpad]}]
		} else {
			#No ellipses when we don't truncates nicknames : ask to Vivia for that :p
			set ellips ""
			# Leave some place for the elipsis (...) and the spacing + spacing
			# of border and - the beginningborder
			set maxwidth [expr {[winfo width $canvas] - [font measure splainf $ellips] - 5 - 2*$Xbegin - [::skin::getKey buddy_xpad]}]
		}

		# We can draw as long as the line isn't full, reset var 
		set linefull 0
		set textheight [expr {[font configure splainf -size]/2} ]

		# This is the var for the y-change (beginning with the height of 1 line)
		set ychange [image height $img]
		set relnickcolour $nickcolour
		set font_attr [font configure splainf]
		set relxnickpos $xnickpos
		set relynickpos $ypos

		foreach unit $parsednick {
			if {[lindex $unit 0] == "text"} {
				# Check if we are still allowed to write text, a newline character resets this
				if { $linefull } {
					continue
				}

				# Store the text as a string
				set textpart [lindex $unit 1]

				# Check if it's really containing text, if not, do nothing
				if {$textpart == ""} {
					continue
				}

				# Check if text is not too long and should be truncated, then
				# first truncate it and restore it in $textpart and set the linefull
				if {[expr {$relxnickpos + [font measure $font_attr $textpart]}] > $maxwidth} {
					set textpart [::guiContactList::truncateText $textpart \
						[expr {$maxwidth - $relxnickpos}] $font_attr]

					#If we don't truncate we don't put ellipsis
					#!$maxwidth already left space for the ellipsis
					set textpart "$textpart$ellips"

					# This line is full, don't draw anything anymore before we start a new line
					set linefull 1
				}

				# Draw the text
				$canvas create text $relxnickpos $ynickpos -text $textpart -anchor w -fill \
					$relnickcolour -font $font_attr  -tags [list contact $tag nicktext $main_part]
				set textwidth [font measure $font_attr $textpart]

				# Append underline coords
				set yunderline [expr {$ynickpos + $textheight + 1}]
				lappend underlinst [list [expr {$relxnickpos - $xpos}] [expr {$yunderline - $ypos}] \
					$textwidth $relnickcolour]

				# Change the coords
				set relxnickpos [expr {$relxnickpos + $textwidth}]
			} elseif { [lindex $unit 0] == "smiley" } {
				# Check if we are still allowed to draw smileys
				if { $linefull } {
					continue
				}

				set smileyname [lindex $unit 1]

				if { [expr {$relxnickpos + [image width $smileyname]}] > $maxwidth } {
					# This line is full, don't draw anything anymore before we start a new line
					set linefull 1

					$canvas create text $relxnickpos $ynickpos -text $ellips -anchor w \
						-fill $relnickcolour -font $font_attr -tags [list contact $tag nicktext $main_part]
					set textwidth [font measure $font_attr $ellips]

					# Append underline coords
					set yunderline [expr {$ynickpos + $textheight + 1}]
					lappend underlinst [list [expr {$relxnickpos - $xpos}]  \
						[expr {$yunderline - $ypos}] $textwidth $relnickcolour]
					continue
				}

				# Draw the smiley
				$canvas create image $relxnickpos $ynickpos -image $smileyname -anchor w \
					-tags [list contact $tag smiley $main_part]

				# Change the coords
				set relxnickpos [expr {$relxnickpos + [image width $smileyname]}]
			} elseif {[lindex $unit 0] == "newline"} {
				set relxnickpos $xnickpos
				set ynickpos [expr {$ynickpos + [image height $img]}]
				set ychange [expr {$ychange + [image height $img]}]

				# New line, we can draw again !
				set linefull 0
			} elseif {[lindex $unit 0] == "colour" && !$force_colour} {
				# A plugin like aMSN Plus! could make the text lists
				# contain an extra variable for colourchanges
				set relnickcolour [lindex $unit 1]
				if {$relnickcolour == "reset"} {
					set relnickcolour $nickcolour
				}
			} elseif {[lindex $unit 0] == "font"} {
				array set current_format $font_attr
				array set modifications [lindex $unit 1]
				foreach key [array names modifications] {
					set current_format($key) [set modifications($key)]
					if { [set current_format($key)] == "reset" } {
						set current_format($key) [font configure splainf $key]
					}
				}
				set font_attr [array get current_format]
			} else {
				status_log "Unknown item in parsed nickname: $unit"
			}
		#END the foreach loop
		}


		#--------------------#
		###Draw Status-name###
		#--------------------#

		#We shouldn't take the status in account as we will draw it
		set maxwidth [expr {[winfo width $canvas] - [font measure splainf $ellips] - 5 - 2*$Xbegin - [::skin::getKey buddy_xpad]}]

		if { $statetext != "" } {
			# Set the spacing (if this needs to be underlined, we'll draw the state as
			# "  $statetext" and remove the spacing
			set relxnickpos [expr {$relxnickpos + $nickstatespacing}]

			if { ![::config::getKey truncatenames] } {

				if { $linefull } {
					set statewidth 0
				} else {
					# Check if text is not too long and should be truncated, then
					# first truncate it and restore it in $textpart and set the linefull
					if {[expr {$relxnickpos + [font measure splainf "$statetext"]}] > $maxwidth} {
						set statetext [::guiContactList::truncateText "$statetext" \
							[expr {$maxwidth - $relxnickpos}] splainf]
	
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

			if { $statewidth > 0 } {
				# Append underline coords
				set yunderline [expr {$ynickpos + $textheight + 1}]
				lappend underlinst [list [expr {$relxnickpos - $xpos}] [expr {$yunderline - $ypos}] \
					$statewidth $statecolour]

				set relxnickpos [expr {$relxnickpos + $statewidth}]
			}
		}
		
		#------------#
		###Draw PSM###
		#------------#

		if {$psm != "" && [::config::getKey emailsincontactlist] == 0 } {
			set relnickcolour $nickcolour
			set font_attr [font configure sitalf]

			if {[::config::getKey psmplace] == 1 } {
				set parsedpsm [linsert $psm 0 [list "text" " - "]]
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
						if {[expr {$relxnickpos + [font measure $font_attr $textpart]}] > $maxwidth} {
							set textpart [::guiContactList::truncateText $textpart \
								[expr {$maxwidth - $relxnickpos}] $font_attr]
							set textpart "$textpart$ellips"
		
							# This line is full, don't draw anything anymore before we start a new line
							set linefull 1
						}
		
						# Draw the text
						$canvas create text $relxnickpos $ynickpos -text $textpart -anchor w -fill \
							$relnickcolour -font $font_attr -tags [list contact $tag psmtext $main_part]
						set textwidth [font measure $font_attr $textpart]
		
						# Append underline coords
						set yunderline [expr {$ynickpos + $textheight + 1}]
						lappend underlinst [list [expr {$relxnickpos - $xpos}] [expr {$yunderline - $ypos}] \
							$textwidth $relnickcolour]
		
						# Change the coords
						set relxnickpos [expr {$relxnickpos + $textwidth}]
					} elseif { [lindex $unit 0] == "smiley" } {
						# Check if we are still allowed to draw smileys
						if { $linefull } {
							continue
						}
		
						set smileyname [lindex $unit 1]
		
						if { [expr {$relxnickpos + [image width $smileyname]}] > $maxwidth } {
							# This line is full, don't draw anything anymore before we start a new line
							set linefull 1
		
							$canvas create text $relxnickpos $ynickpos -text $ellips -anchor w \
								-fill $relnickcolour -font $font_attr -tags [list contact $tag psmtext $main_part]
							set textwidth [font measure $font_attr $ellips]
		
							# Append underline coords
							set yunderline [expr {$ynickpos + $textheight + 1}]
							lappend underlinst [list [expr {$relxnickpos - $xpos}]  \
								[expr {$yunderline - $ypos}] $textwidth $relnickcolour]
							continue
						}
		
						# Draw the smiley
						$canvas create image $relxnickpos $ynickpos -image $smileyname -anchor w \
							-tags [list contact $tag psmsmiley $main_part]
		
						# Change the coords
						set relxnickpos [expr {$relxnickpos + [image width $smileyname]}]
					} elseif {[lindex $unit 0] == "newline"} {
						set relxnickpos $xnickpos
						set ynickpos [expr {$ynickpos + [image height $img]}]
						set ychange [expr {$ychange + [image height $img]}]
		
						# New line, we can draw again !
						set linefull 0
					} elseif {[lindex $unit 0] == "colour" && !$force_colour} {
						# A plugin like aMSN Plus! could make the text lists
						# contain an extra variable for colourchanges
						set relnickcolour [lindex $unit 1]
						if {$relnickcolour == "reset"} {
							set relnickcolour $nickcolour
						}
					} elseif {[lindex $unit 0] == "font"} {
						array set current_format $font_attr
						array set modifications [lindex $unit 1]
						foreach key [array names modifications] {
							set current_format($key) [set modifications($key)]
							if { [set current_format($key)] == "reset" } {
								set current_format($key) [font configure sitalf $key]
							}
						}
						set font_attr [array get current_format]
					}
					# END the foreach loop
				}
			} elseif {[::config::getKey psmplace] == 2 } {
				set parsedpsm [linsert $psm 0 [list "newline" "\n"]]
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
						if {[expr {$relxnickpos + [font measure $font_attr $textpart]}] > $maxwidth} {
							set textpart [::guiContactList::truncateText $textpart \
								[expr {$maxwidth - $relxnickpos}] $font_attr]
							set textpart "$textpart$ellips"
		
							# This line is full, don't draw anything anymore before we start a new line
							set linefull 1
						}
		
						# Draw the text
						$canvas create text $relxnickpos $ynickpos -text $textpart -anchor w -fill \
							$relnickcolour -font $font_attr -tags [list contact $tag psmtext $main_part]
						set textwidth [font measure $font_attr $textpart]
		
						# Append underline coords
						set yunderline [expr {$ynickpos + $textheight + 1}]
						lappend underlinst [list [expr {$relxnickpos - $xpos}] [expr {$yunderline - $ypos}] \
							$textwidth $relnickcolour]
		
						# Change the coords
						set relxnickpos [expr {$relxnickpos + $textwidth}]
					} elseif { [lindex $unit 0] == "smiley" } {
						# Check if we are still allowed to draw smileys
						if { $linefull } {
							continue
						}
		
						set smileyname [lindex $unit 1]
		
						if { [expr {$relxnickpos + [image width $smileyname]}] > $maxwidth } {
							# This line is full, don't draw anything anymore before we start a new line
							set linefull 1
		
							$canvas create text $relxnickpos $ynickpos -text $ellips -anchor w \
								-fill $relnickcolour -font $font_attr -tags [list contact $tag psmtext $main_part]
							set textwidth [font measure $font_attr $ellips]
		
							# Append underline coords
							set yunderline [expr {$ynickpos + $textheight + 1}]
							lappend underlinst [list [expr {$relxnickpos - $xpos}]  \
								[expr {$yunderline - $ypos}] $textwidth $relnickcolour]
							continue
						}
		
						# Draw the smiley
						$canvas create image $relxnickpos $ynickpos -image $smileyname -anchor w \
							-tags [list contact $tag psmsmiley $main_part]
		
						# Change the coords
						set relxnickpos [expr {$relxnickpos + [image width $smileyname]}]
					} elseif {[lindex $unit 0] == "newline"} {
						set relxnickpos $xnickpos
						set ynickpos [expr {$ynickpos + [image height $img]}]
						set ychange [expr {$ychange + [image height $img]}]
		
						# New line, we can draw again !
						set linefull 0
					} elseif {[lindex $unit 0] == "colour" && !$force_colour} {
						# A plugin like aMSN Plus! could make the text lists
						# contain an extra variable for colourchanges
						set relnickcolour [lindex $unit 1]
						if {$relnickcolour == "reset"} {
							set relnickcolour $nickcolour
						}
					} elseif {[lindex $unit 0] == "font"} {
						array set current_format $font_attr
						array set modifications [lindex $unit 1]
						foreach key [array names modifications] {
							set current_format($key) [set modifications($key)]
							if { [set current_format($key)] == "reset" } {
								set current_format($key) [font configure sitalf $key]
							}
						}
						set font_attr [array get current_format]
					}
					# END the foreach loop
				}
			}
		} ; #end psm drawing



		#----------------------------------#
		##Controversial inline spaces info##
		#----------------------------------#

		#This is a technology demo, the default is not unchangeable
		# values for this variable can be "inline", "ccard" or "disabled"
		if {$space_shown && [::config::getKey spacesinfo "inline"] == "inline"} {
			#!$tag should be $tag for inline spaces
			incr ychange [::guiContactList::drawSpacesInfo $canvas $xlinestart $ychange $email [list $tag $space_info contact space_info]]
		}

		
		#-----------#
		##Bindings###
		#-----------#

		# First, remove previous bindings
		$canvas bind $tag <Enter> [list ]
		$canvas bind $tag <Motion> [list ]
		$canvas bind $tag <Leave> [list ]
		$canvas bind $main_part <Enter> [list ]
		$canvas bind $main_part <Motion> [list ]
		$canvas bind $main_part <Leave> [list ]
		$canvas bind $main_part <ButtonRelease-1> [list ]
		$canvas bind $main_part <Double-ButtonRelease-1> [list ]
		$canvas bind $space_icon <Enter> [list ]
		$canvas bind $space_icon <Motion> [list ]
		$canvas bind $space_icon <Leave> [list ]

		#Click binding for the "star" image for spaces
		$canvas bind $space_icon <Button-1> [list ::guiContactList::toggleSpaceShown "$canvas" "$email" \
			"$space_shown" "$space_update"]

		# balloon bindings
		if { [::config::getKey tooltips] == 1 } {
			$canvas bind $space_icon <Enter> +[list ::guiContactList::balloon_enter_CL \
				%W %X %Y "View space items" ]
			$canvas bind $space_icon <Motion> +[list ::guiContactList::balloon_motion_CL \
				%W %X %Y "View space items"]
			$canvas bind $space_icon <Leave> "+set ::Bulle(first) 0; kill_balloon"
		}

		# Add binding for underline if the skinner use it
		if {[::skin::getKey underline_contact]} {
			$canvas bind $main_part <Enter> \
				+[list ::guiContactList::underlineList $canvas $underlinst "$tag"]
			$canvas bind $main_part <Leave> +[list $canvas delete "uline_$tag"]
		}
		
		# Add binding for balloon
		if { [::config::getKey tooltips] == 1 } {
			$canvas bind $main_part <Enter> +[list ::guiContactList::balloon_enter_CL \
				%W %X %Y "[getBalloonMessage $email $element]" "[::skin::getDisplayPicture $email]"]
			$canvas bind $main_part <Motion> +[list ::guiContactList::balloon_motion_CL \
				%W %X %Y "[getBalloonMessage $email $element]" "[::skin::getDisplayPicture $email]"]
			$canvas bind $main_part <Leave> "+set ::Bulle(first) 0; kill_balloon"
		}

		# Add binding for click / right click (remembering to get config key for single/dbl
		# click on contacts to open chat)
		if { [::config::getKey sngdblclick] } {
			set singordblclick <ButtonRelease-1>
		} else {
			set singordblclick <Double-ButtonRelease-1>
		}

		# Binding for left (double)click
		if { $state_code == "FLN" && [::abook::getContactData $email msn_mobile] == "1"} {
			# If the user is offline and support mobile (SMS)
			$canvas bind $main_part $singordblclick \
				"set ::guiContactList::displayCWAfterId \
				\[after 0 [list ::MSNMobile::OpenMobileWindow \"$email\"]\]"
		} else {
			$canvas bind $main_part $singordblclick \
				"set ::guiContactList::displayCWAfterId \
				\[after 0 [list ::amsn::chatUser \"$email\"]\]"
		}

		# Binding for right click		 
		$canvas bind $main_part <<Button3>> [list show_umenu "$email" "$grId" %X %Y]

		# Bindings for dragging : applies to all elements even the star
		$canvas bind $tag <ButtonPress-1> [list ::guiContactList::contactPress $tag $canvas %s %x %y]

		#cursor change bindings
		if { [::skin::getKey changecursor_contact] } {
			$canvas bind $tag <Enter> +[list ::guiContactList::configureCursor $canvas hand2]
			$canvas bind $tag <Leave> +[list ::guiContactList::configureCursor $canvas left_ptr]
		}

		# Now store the nickname [and] height in the nickarray
		# set nickheight [expr $ychange + [::skin::getKey buddy_ypad] ]
		set nickheightArray($email) $ychange
		# status_log "nickheight $email: $nickheight"
	}


	
	proc toggleSpaceShown {canvas email space_shown space_update} {
		if { [::config::getKey spacesinfo "inline"] == "inline"} {
			if {$space_shown} {		
				::abook::setVolatileData $email SpaceShowed 0
			} else {
				#if an update is available, we'll have to fetch it
				if { $space_update || ([::abook::getContactData $email ccardlist [list]] == [list]) } {
					::abook::setVolatileData $email fetching_space 1
					after 0 ::guiContactList::fetchSpacedData $email
				}
				::abook::setVolatileData $email SpaceShowed 1
				#if not we'll just have to redraw so the data is shown
			}
			::guiContactList::contactChanged "toggleSpaceShown" $email
		} elseif { [::config::getKey spacesinfo "inline"] == "ccard" } {
			#if an update is available, we'll have to fetch it
			if { $space_update || ([::abook::getContactData $email ccardlist [list]] == [list]) } {
				::abook::setVolatileData $email fetching_space 1
				after 0 ::guiContactList::fetchSpacedData $email
			}
			::ccard::drawwindow $email 1
		}
	}
	
	
	proc fetchSpacedData { email } {
		global HOME
		variable token
		
		#fetch the ccard info
		set ccard [::MSNCCARD::getContactCard $email]
		::abook::setContactData $email ccardlist $ccard
#TODO: download photo thumbnails
		set photos [::MSNCCARD::getAllPhotos $ccard]
		set cachedir "[file join $HOME spaces $email]"
		create_dir $cachedir
		set count 0
#DL REQUIRES LOGIN ! HOW ?
#seems like once you logged in by opening an item the downloads do "just work" 
		foreach photolist $photos {
			#download the thumbnail
			set thumbnailurl [lindex $photolist 3]
			set data [::guiContactList::getPage  $thumbnailurl]
			set filename "[file join $cachedir $count.jpg]"
			set fid [open $filename w]
			fconfigure $fid -encoding binary
			puts -nonewline $fid "$data"
			close $fid


			
			
			incr count
			
		}		


		::abook::setVolatileData $email fetching_space 0
		
		#now we'll set the space as "read"
		::abook::setVolatileData $email space_updated 0

		if { [::config::getKey spacesinfo "inline"] == "inline"} {
			::guiContactList::contactChanged "toggleSpaceShown" $email
		} elseif { [::config::getKey spacesinfo "inline"] == "ccard" } {
			::ccard::drawwindow $email 1
		}

	}
	
	
	#///////////////////////////////////////////////////////////////////////////////
	#Draws info of MSN Spaces on chosen coordinate on a choosen canvas
	proc drawSpacesInfo { canvas xcoord ycoord email taglist } {


		#todo: use bbox or something to calculate height
		set height 0
		#todo: calculate height of a line the right way
		set lineheight 12

		if { [::abook::getVolatileData $email fetching_space 0] } {
			#draw a "please wait .." message, will be replaced when fetching is done
			$canvas create text $xcoord $ycoord -font sitalf -text "Fetching data ..." -tags $taglist -anchor nw -fill grey

			#adjust $height, adding 1 line
			set height [expr {$height + $lineheight + 4}]

		} else {
			#show the data we have in abook

			set ccard [::abook::getContactData $email ccardlist [list]]

			# Store the titles in a var
			foreach i [list SpaceTitle Blog Album Music] {
				set $i [::MSNCCARD::getTitleFor $ccard $i]
#				puts "$i = [set $i]"
			}
			
			#First show the spaces title:
			if {$SpaceTitle != ""} {
				$canvas create text $xcoord [expr {$ycoord + $height}] -font bitalf -text "$SpaceTitle" \
					-tags $taglist -anchor nw -fill black
				#adjust $ychange, adding 1 line
				set height [expr {$height + $lineheight + 4 }]
				#set everything after this title a bit to the right
				set xcoord [expr {$xcoord + 10}]
			}

			#blogposts
			if {$Blog != ""} {
				# seems like a blog without title doesn't exist, so we don't have to check if there are any posts
				set blogposts [::MSNCCARD::getAllBlogPosts $ccard]
				#add a title
				$canvas create text $xcoord [expr {$ycoord + $height}] -font sboldf -text "$Blog" \
					-tags $taglist -anchor nw -fill blue
				#adjust $ychange, adding 1 line
				set height [expr {$height + $lineheight}]

				set count 0
				foreach i $blogposts {
					set itemtag [lindex $taglist 0]_bpost_${count}
					$canvas create text [expr {$xcoord + 10}] [expr {$ycoord + $height} ] \
						-font sitalf -text "[lindex $i 1]" \
						-tags [linsert $taglist end $itemtag]  -anchor nw -fill grey
					$canvas bind $itemtag <Button-1> [list ::hotmail::gotURL "[lindex $i 2]"]

					#update ychange
					set height [expr {$height + $lineheight}]
					incr count
				}
			}

			
			#photos
			if {$Album != ""} {
				set photos [::MSNCCARD::getAllPhotos $ccard]
				#add a title
				$canvas create text $xcoord [expr {$ycoord + $height}] -font sboldf -text "$Album" \
					-tags $taglist -anchor nw -fill blue
				#adjust $ychange, adding 1 line
				set height [expr {$height + $lineheight}]

				set count 0
				foreach i $photos {
					set itemtag [lindex $taglist 0]_bpost_${count}
#puts "Photo: $i"
					if { [lindex $i 0] != "" } {

						$canvas create text [expr {$xcoord + 10}] [expr {$ycoord + $height}] \
							-font sitalf -text "[lindex $i 1]" \
							-tags [linsert $taglist end $itemtag] -anchor nw -fill grey
						$canvas bind $itemtag <Button-1> \
							[list ::hotmail::gotURL "[lindex $i 2]"]
						#update ychange
						set height [expr {$height + $lineheight } ]
						incr count
					}
				}
			}
			#for now show a message if no blogs or photos, for debugging purposes
			if {$Blog == "" && $Album == ""} {
				$canvas create text $xcoord [expr $ycoord + $height] -font sitalf \
					-text "Nothing to see here" -tags $taglist -anchor nw -fill grey

				#adjust $ychange, adding 1 line
				set height [expr {$height + $lineheight } ]
			}
		}
		
		
		
			
		return $height	
	}
	
	proc save_file { count cachedir } {
		variable token
		#download was succesfull
	#TODO: what if something other then an image is here ?
		set content [::http::data $token]	
		set filename "[file join $cachedir $count.jpg]"
		set fid [open $filename w]
		fconfigure $fid -encoding binary
		puts -nonewline $fid "$content"
		close $fid
		::http::cleanup $token
	
	
	
	}
	
	proc getPage { url } {
		set token [::http::geturl $url]
		set data [::http::data $token]
		::http::cleanup $token
		return $data
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
			if { $kind != "full" && ($grId == 0 || [::config::getKey removeempty]) } {
				if { [::config::getKey orderbygroup] == 1 } {
					#Group mode
					set grpCount [lindex [::groups::getGroupCount $grId] 1]
				} else {
					#Status/Hybrid : we can use the getGroupCount function
					set grpCount [getGroupCount $group]
				}
				if { $grpCount == 0 } {
					continue
				}
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

	##################################################
	# Get the group count
	# Depend if user in status/group/hybrid mode
	proc isGroupEmpty {element} {

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
					set groupList [list [list "online" [trans uonline]] \
						[list "mobile" [trans mobile]] \
						[list "offline" [trans uoffline]]]
				} else {
					set groupList [list [list "online" [trans uonline]] \
						[list "offline" [trans uoffline]]]
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
			if { !$realgroups } {
				set groupList "\{0 \{[trans nogroup]\}\} $groupList"
			}
		}
		
		# Hybrid Mode, we add mobile and offline group
		if { $mode == 2 && !$realgroups } {
			if {[::config::getKey showMobileGroup] == 1} {
				lappend groupList [list "mobile" [trans mobile]]
			}
			lappend groupList [list "offline" [trans uoffline]]
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

	proc getEmailFromTag { tag } {
		set pos [string last _ $tag]
		set email [string range $tag 0 [expr {$pos -1}]]
		return $email
	}


	proc getGrIdFromTag { tag } {
		set pos [string last _ $tag]
		set grId [string range $tag [expr {$pos + 1}] end]
		return $grId
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

		if {!$OnTheMove} {
			foreach line $lines {
				$canvas create line\
					[expr { [lindex $line 0] + $xpos } ] \
					[expr { [lindex $line 1] + $ypos } ] \
					[expr { [lindex $line 0] + [lindex $line 2] + $xpos } ]\
					[expr { [lindex $line 1] + $ypos } ] \
					-fill [lindex $line 3]\
					-tags [list uline_$nicktag $nicktag uline]
			}
		}
		$canvas lower uline_$nicktag $nicktag
	}

	proc centerItems { canvas } {
		set newX [expr {[winfo width $canvas]/2}]
		set newY [expr {[winfo height $canvas]/2}]
		
		set items [$canvas find withtag centerx]
		foreach item $items {
			$canvas coords $item $newX [lindex [$canvas coords $item] 1]
		}

		set items [$canvas find withtag centery]
		foreach item $items {
			$canvas coords $item [lindex [$canvas coords $item] 0] $newY
		}
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
	proc contactPress {tag canvas state x y} {
		variable DragDeltaX
		variable DragDeltaY
		variable OnTheMove
		variable DragStartCoords

		if {$OnTheMove} { return }

		set DragStartCoords [$canvas coords $tag]

		set DragDeltaX [expr {[$canvas canvasx $x] - [lindex $DragStartCoords 0]}]
		set DragDeltaY [expr {[$canvas canvasy $y] - [lindex $DragStartCoords 1]}]

		set OnTheMove 1
		grab -global $canvas
		focus $canvas

		bind $canvas <Button1-Motion> [list ::guiContactList::contactMove $tag $canvas %x %y]
		bind $canvas <<Button1>> [list ::guiContactList::contactReleased "$tag" "$canvas" %x %y]

		# 4 is the ControlMask for the state field
		# 16 is the Mod2Mask aka Option modifier for MacOS
		if { [OnMac] } {
			bind $canvas <KeyPress-Meta_L> "[list set ::guiContactList::modeCopy 1]; \
				[list ::guiContactList::contactMove $tag $canvas %x %y]"
			bind $canvas <KeyRelease-Meta_L> "set ::guiContactList::modeCopy 0; \
				[list ::guiContactList::contactMove $tag $canvas %x %y]"
			set mask 16
		} else {
			bind $canvas <KeyPress-Control_L> "[list set ::guiContactList::modeCopy 1]; \
				[list ::guiContactList::contactMove $tag $canvas %x %y]"
			bind $canvas <KeyRelease-Control_L> "[list set ::guiContactList::modeCopy 0]; \
				[list ::guiContactList::contactMove $tag $canvas %x %y]"
			bind $canvas <KeyPress-Control_R> "[list set ::guiContactList::modeCopy 1]; \
				[list ::guiContactList::contactMove $tag $canvas %x %y]"
			bind $canvas <KeyRelease-Control_R> "[list set ::guiContactList::modeCopy 0]; \
				[list ::guiContactList::contactMove $tag $canvas %x %y]"
			set mask 4
		}

		if { $state & $mask } {
			# Copy the contact between the groups if Ctrl key is pressed
			set ::guiContactList::modeCopy 1
			$canvas configure -cursor plus
		} else {
			# Move the contact between the groups
			set ::guiContactList::modeCopy 0
			$canvas configure -cursor left_ptr
		}

		set ::Bulle(first) 0; kill_balloon
		$canvas delete uline_$tag
	}


	proc contactMove {tag canvas x y} {
		variable DragDeltaX
		variable DragDeltaY
		variable DragStartCoords
		variable scrollAfterId
		variable OnTheMove

		if {!$OnTheMove} { return }

		#Move the contact, (New_X_Mouse_coord - Old_X_Mouse_coord) on the X-axis, same for Y
		set oldCoords [$canvas coords $tag]
		set coordX [expr {[$canvas canvasx $x] - $DragDeltaX}]
		set coordY [expr {[$canvas canvasy $y] - $DragDeltaY}]

		set ChangeX [expr {[lindex $DragStartCoords 0] - $coordX}]
		set ChangeY [expr {[lindex $DragStartCoords 1] - $coordY}]

		if { abs($ChangeX) <= 5 && abs($ChangeY) <= 5 } {
			set coordX [lindex $DragStartCoords 0]
			set coordY [lindex $DragStartCoords 1]
		}

		if { $::guiContactList::modeCopy } {
			$canvas configure -cursor plus
		} else {
			$canvas configure -cursor left_ptr
		}

		#We use move to affect all elements of tag
		$canvas move $tag [expr {$coordX - [lindex $oldCoords 0]}] [expr {$coordY - [lindex $oldCoords 1]}]

		if { ($y > [winfo height $canvas] - 75) || ($y < 75) } {
			#We are in the scrolling zone
			if { [catch {after info $scrollAfterId}] } {
				#No after exists yet : we create one
				set scrollAfterId [after 1000 [list ::guiContactList::draggingScroll $tag $canvas]]
			}
		} else {
			catch {after cancel $scrollAfterId}
		}

		$canvas delete uline_$tag
		
	}


	proc contactReleased {tag canvas x y} {
		variable OnTheMove
		variable DragDeltaX
		variable DragDeltaY
		variable DragStartCoords
		variable scrollAfterId

		if {!$OnTheMove} { return }

		catch {after cancel $scrollAfterId}

		set oldgrId [::guiContactList::getGrIdFromTag $tag]

		set iconXCoord [lindex [$canvas coords $tag] 0]
		set iconYCoord [lindex [$canvas coords $tag] 1]

		set ChangeX [expr {[lindex $DragStartCoords 0] - $iconXCoord}]
		set ChangeY [expr {[lindex $DragStartCoords 1] - $iconYCoord}]

		# Check if we're not dragging off the CL
		if { $iconXCoord < 0 || ( abs($ChangeX) <= 5 && abs($ChangeY) <= 5 ) } { 
			# TODO: Here we should trigger an event that can be used
			# 	by plugins. For example, the contact tray plugin
			# 	could create trays like this

			$canvas move $tag $ChangeX $ChangeY
		} else {

			# Now we have to find the group whose ycoord is the first
			# less then this coord

			# Beginsituation: group to move to is group where we began
			set newgrId $oldgrId

			# Cycle to the list of groups and select the group where
			# the user drags to
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
					if {$grYCoord <= [expr {$iconYCoord + 5}]} {
						set newgrId $grId
					}
				}
			}
	
			if { $newgrId == $oldgrId } {
				#if the contact was dragged to the group of origin, just move it back
				::guiContactList::organiseList $canvas
			} else {
				if { $::guiContactList::modeCopy } {
					# Copy the contact between the groups if Ctrl key is pressed
					::groups::menuCmdCopy $newgrId \
						[::guiContactList::getEmailFromTag $tag]
				} else {
					# Move the contact between the groups
					::groups::menuCmdMove $newgrId $oldgrId \
						[::guiContactList::getEmailFromTag $tag]
				}
				# Note: redraw is done by the protocol event
			} 
		}

		bind $canvas <Button1-Motion> ""
		bind $canvas <<Button1>> ""

		if { [OnMac] } {
			bind $canvas <KeyPress-Meta_L> ""
			bind $canvas <KeyRelease-Meta_L> ""
		} else {
			bind $canvas <KeyPress-Control_L> ""
			bind $canvas <KeyRelease-Control_L> ""
			bind $canvas <KeyPress-Control_R> ""
			bind $canvas <KeyRelease-Control_R> ""
		}

		grab release $canvas
		set OnTheMove 0
		# Remove those vars as they're not in use anymore
		unset DragDeltaX
		unset DragDeltaY

		if { abs($ChangeX) > 5 || abs($ChangeY) > 5 } {
			catch { after cancel $::guiContactList::displayCWAfterId }
		}
	}

	proc draggingScroll { tag canvas } {
		variable scrollAfterId

		set pointerX [winfo pointerx .]
		set pointerY [winfo pointery .]

		if { ($pointerY > [winfo rooty $canvas] + [winfo height $canvas] - 75) } {
			#We are here since some moves : do a scroll to the bottom
			set scrollAfterId [after 500 [list ::guiContactList::draggingScroll $tag $canvas]]
			scrollCL $canvas down
			#We force the moving of the tag to the right place
			contactMove $tag $canvas [expr {$pointerX - [winfo rootx $canvas]}] \
				[expr {$pointerY - [winfo rooty $canvas]}]

		} elseif { ($pointerY < [winfo rooty $canvas] + 75) } {
			#We are here since some moves : do a scroll to the bottom
			set scrollAfterId [after 500 [list ::guiContactList::draggingScroll $tag $canvas]]
			scrollCL $canvas up
			#We force the moving of the tag to the right place
			contactMove $tag $canvas [expr {$pointerX - [winfo rootx $canvas]}] \
				[expr {$pointerY - [winfo rooty $canvas]}]
		}
	}

	proc balloon_enter_CL { w x y msg {img ""} } {
		variable OnTheMove
		#When dragging don't show the tooltips
		if { !$OnTheMove } {
			balloon_enter $w $x $y $msg $img
		}
	}

	proc balloon_motion_CL { w x y msg {img ""} } {
		variable OnTheMove
		#When dragging don't show the tooltips
		if { !$OnTheMove } {
			balloon_motion $w $x $y $msg $img
		}
	}

	proc configureCursor { canvas cursor } {
		variable OnTheMove
		#When dragging don't show the tooltips
		if { !$OnTheMove } {
			$canvas configure -cursor $cursor
		}
	}
}

