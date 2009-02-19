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
		::skin::setPixmap plain_emblem plain_emblem.gif		
		::skin::setPixmap away_emblem away_emblem.gif
		::skin::setPixmap busy_emblem busy_emblem.gif
		::skin::setPixmap blocked_emblem blocked_emblem.gif
		::skin::setPixmap blocked_emblem_detailedview blocked_emblem_detailedview.gif
		::skin::setPixmap notinlist_emblem notinlist_emblem.gif


		variable Xbegin
		variable Ybegin

		set Xbegin [::skin::getKey contactlist_xpad]
		set Ybegin [::skin::getKey contactlist_ypad]

		frame $w.cl -background [::skin::getKey contactlistborderbg] -borderwidth [::skin::getKey contactlistbd]

		scrollbar $clscrollbar -command [list ::guiContactList::scrollCLsb $clcanvas] \
			-background [::skin::getKey contactlistbg]
		# Create a blank canvas
		canvas $clcanvas -background [::skin::getKey contactlistbg] \
			-yscrollcommand [list ::guiContactList::setScroll $clscrollbar] -borderwidth 0

		drawBG $clcanvas 1
		
		after 0 ::guiContactList::drawList $clcanvas

		# Register events
		::Event::registerEvent contactStateChange all ::guiContactList::contactChanged
		if {[::config::getKey show_contactdps_in_cl] == "1"} {
			::Event::registerEvent contactDPChange all ::guiContactList::contactChanged
		}
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
			::guiContactList::organiseList $clcanvas \[::guiContactList::getContactList\];"]
		::guiContactList::centerItems $clcanvas
	}

	#/////////////////////////////////////////////////////////////////////
	# Function that draws everything needed on the canvas
	#/////////////////////////////////////////////////////////////////////
	proc drawList {canvas} {
		if { ${::guiContactList::external_lock} } { return }

		::guiContactList::drawGroups $canvas
		::guiContactList::drawContacts $canvas
		::guiContactList::organiseList $canvas [getContactList]
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

		contactlist_background blank

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
			$canvas lower backgroundimage
			if {[$canvas bbox backgroundimage] != ""} {
				$canvas configure -scrollregion [list 0 0 2000 [lindex [$canvas bbox backgroundimage] 3]]
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
			::guiContactList::organiseList $clcanvas [getContactList]
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
		::guiContactList::organiseList $clcanvas [getContactList]
#		status_log "contactChanged :: List redrawn for contacts $contacts, groups $groups, $nicks reparsed" green
					
	}

	proc toggleGroup { element canvas } {
		::groups::ToggleStatus [lindex $element 0]
		# Redraw group as it's state changed
		::guiContactList::drawGroup $canvas $element 
		::guiContactList::organiseList $canvas [getContactList]
	}


	# Move 'm to the right place
	proc organiseList { canvas contactList } {
		variable Xbegin
		variable Ybegin
		variable nickheightArray
	
		if { ${::guiContactList::external_lock} || !$::contactlist_loaded } { return }

		#We remove the underline and others things
		$canvas delete uline border backgnd

		# First we move all the canvas items
		$canvas addtag items withtag group
		$canvas addtag items withtag contact
		# Make sure we move 'm to an invisible place first
		$canvas move items 100000 100000
		$canvas delete box

		# Let's draw each element of this list
		set curPos [list $Xbegin $Ybegin]
		
		set maxwidth [winfo width $canvas]
		set boXpad $Xbegin
		set width [expr {$maxwidth - ($boXpad*2)}]
		if {$width <= 30} {set width 300}
		
		if {[::skin::getKey topgroupbg] ne "" } {
			package require scalable-bg
			
			set topimg [image create photo [TmpImgName]] ;#gets destroyed
			set style [::skin::getKey topgroupbg_style]
			if {$style eq "light"} {
				$topimg copy [::skin::loadPixmap grouptopback_light]
			} elseif {$style eq "dark"} {
				$topimg copy [::skin::loadPixmap grouptopback_dark]
			} else {
				::skin::setKey topgroupbg ""
				organiseList $canvas [getContactList]
				return
			}
			::picture::Colorize $topimg [::skin::getKey topgroupbg]
			
			set bg topgroupsbg
			
			scalable-bg $bg -source $topimg \
				-n [::skin::getKey topbarpady] -e [::skin::getKey topbarpadx] \
				-s [::skin::getKey topbarpady] -w [::skin::getKey topbarpadx] \
				-width $width -height [image height [::skin::loadPixmap up]] \
				-resizemethod [::skin::getKey chat_top_resize "tile"]
			
			set bg_name [$bg name]
			
			set topimg [image create photo [TmpImgName]]
			$topimg copy $bg_name
			
			rename $bg {}
		}


		# Create upbar of the box
		image create photo boxupbar -height [image height [::skin::loadPixmap up]] \
			-width $width
		boxupbar copy [::skin::loadPixmap upleft] -to 0 0 \
			[image width [::skin::loadPixmap upleft]] \
			[image height [::skin::loadPixmap upleft]]
		boxupbar copy [::skin::loadPixmap up] -to \
			[image width [::skin::loadPixmap upleft]] 0 \
			[expr {$width -  [image width [::skin::loadPixmap upright]]}] \
			[image height [::skin::loadPixmap up]]
		boxupbar copy [::skin::loadPixmap upright] -to \
			[expr {$width - [image width [::skin::loadPixmap upright]]}] 0 \
			$width [image height [::skin::loadPixmap upright]]


		# Create the body of the box
		image create photo boxbodysmall -height \
			[image height [::skin::loadPixmap left]] -width $width
		boxbodysmall copy [::skin::loadPixmap left] -to 0 0 \
			[image width [::skin::loadPixmap left]] \
			[image height [::skin::loadPixmap left]]
		boxbodysmall copy [::skin::loadPixmap body] -to \
			[image width [::skin::loadPixmap left]] 0 \
			[expr {$width -  [image width [::skin::loadPixmap right]]}] \
			[image height [::skin::loadPixmap body]]
		boxbodysmall copy [::skin::loadPixmap right] -to \
			[expr {$width - [image width [::skin::loadPixmap right]]}] 0 \
			$width [image height [::skin::loadPixmap right]]


		# Create endbar of the box
		image create photo boxdownbar \
			-height [image height [::skin::loadPixmap down]] -width $width
			boxdownbar copy [::skin::loadPixmap downleft] -to 0 0 \
			[image width [::skin::loadPixmap downleft]] \
			[image height [::skin::loadPixmap downleft]]
		boxdownbar copy [::skin::loadPixmap down] -to \
			[image width [::skin::loadPixmap downleft]] 0 \
			[expr {$width -  [image width [::skin::loadPixmap downright]]}] \
			[image height [::skin::loadPixmap down]]
		boxdownbar copy [::skin::loadPixmap downright] -to \
			[expr {$width - [image width [::skin::loadPixmap downright]]}] 0 \
			$width [image height [::skin::loadPixmap downright]]


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
				set currentPos [$canvas bbox $tag]
				#status_log "MOVING CONTACT WITH TAG: $tag ;  currentpos: $currentPos  ; curPos: $curPos"

				if { $currentPos == [list ] } {
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

				# If we're not drawing the first group, we should draw the end of the box of the \
				# group before here and change the curPos
				if {!$DrawingFirstGroup} {
					set bodYend [expr {[lindex $curPos 1] + [::skin::getKey buddy_ypad]}]
					# Here we should draw the body
					set height [expr {$bodYend - $bodYbegin}]
					if {$height > [::skin::getKey buddy_ypad]} {
						image create photo boxbody_$groupDrawn -height $height -width $width
						boxbody_$groupDrawn copy boxbodysmall -to 0 0 $width $height
					
						# Draw it
						$canvas create image $boXpad $bodYbegin -image boxbody_$groupDrawn \
							-anchor nw -tags [list box box_body $gid]
							
						set y2 "body"
						
					} else {
						set bodYend $bodYbegin
						set y2 ""
					}

					$canvas create image $boXpad $bodYend -image boxdownbar -anchor nw \
						-tags [list box box_downbar $gid]

					set curPos [list [lindex $curPos 0] [expr {[lindex $curPos 1]+ $ypad}] ]
					
					if {$y2 ne "" && [::skin::getKey "groupcolorborder"] ne ""} {
						$canvas create rect \
							$boXpad $bodYbegin $width [expr {$bodYbegin + $height}] \
							-outline [::skin::getKey "groupcolorborder"] -width 3 \
							-tags [list box box_body $gid border]
					}
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
					
				set topYbegin [lindex $curPos 1]
					
				set x1 $boXpad
				set y1 $topYbegin
				set x2 $width
				set y2 [expr {$topYbegin + [image height [::skin::loadPixmap up]]}]
				$canvas create rect $x1 $y1 $x2 $y2 -outline [::skin::getKey "groupcolorborder"] -width 3 -tags [list box box_body $gid border]
				
				
				if {[::skin::getKey topgroupbg] ne "" } {
					$canvas create image $x1 $y1 -image $topimg -anchor nw -tag backgnd
					
					$canvas lower backgnd box
					$canvas lower backgnd toggleimg
				} else {
					;# Draw boxupbar_$groupDrawn image
					$canvas create image $boXpad $topYbegin -image boxupbar -anchor nw \
					-tags [list box box_upbar $gid]
				}

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
		
		image delete boxbodysmall
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

		set text2xpos [expr {$textxpos + [font measure sboldf -displayof $canvas $groupnametext] + \
			$groupnamecountpad}]

		# Then the group's count
		$canvas create text $text2xpos $ypos -text $groupcounttext -anchor nw \
			-fill $groupcolor -font splainf -tags [list group title count_$gid $gid]



		#Setup co-ords for underline on hover
		set yuline [expr {$ypos + [font configure splainf -size] + 3 }]

		set underlinst [list [list $textxpos $yuline [font measure sboldf -displayof $canvas $groupnametext] \
			$groupcolor] [list $text2xpos $yuline [font measure splainf -displayof $canvas $groupcounttext] \
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
	# Function that renders a contact according to its style string
	#/////////////////////////////////////////////////////////////////////////
	proc adaptSizes {linewidth truncable tofill maxwidth} {
		set size 0
		set ellipsissize 0

		foreach sz $linewidth {
			incr size $sz
		}
		set delta [expr {$size-$maxwidth}]
		if {$delta > 0} {
			#Too bad we need to trunc
			#Tricky part here
			while {[llength $truncable] > 0 && $delta > 0} {
				set truncitem [lindex $truncable end]
				if { [lindex $truncitem 0] == "size" } {
					set ellipsissize [lindex $truncitem 1]
				} elseif { [lindex $truncitem 0] == "id" } {
					set sz [lindex $linewidth [lindex $truncitem 1]]
					if {$sz-$delta-$ellipsissize < 0} {
						lset linewidth [lindex $truncitem 1] 0
						incr delta [expr {-$sz}]
					} else {
						#We don't substract ellipsis as the renderer will draw them in the current block
						lset linewidth [lindex $truncitem 1] [expr $sz-$delta]
						set delta 0
					}
				}
				set truncable [lreplace $truncable end end]
			}
			set i [expr {[llength $linewidth] - 1 }]
			while {$delta > 0 && $i > 0} {
				#Still not enough place : we now remove from the end
				set sz [lindex $linewidth $i]
				if {$sz-$delta-$ellipsissize < 0} {
					lset linewidth $i 0
					incr delta [expr {-$sz}]
				} else {
					lset linewidth $i [expr $sz-$delta]
					set delta 0
				}
				incr i -1
			}
		} elseif {$delta < 0 && [llength $tofill] > 0} {
			#We have space : we can fill remaining spaces
			set delta [expr {-$delta/[llength $tofill]}]
			foreach id $tofill {
				lset linewidth $id $delta
			}
		}
		return $linewidth
	}

	proc renderContact { canvas main_tag maxwidth text detailed_view} {
		set defaultcolour #000000
		set defaultfont splainf
		set defaultellips ""

		set font_attr [font configure $defaultfont]
		set ellips $defaultellips

		set lineswidth [list ]
		set linesheight [list ]

		set marginx 0
		set marginy 0
		set truncflag 0
		set linewidth [list $marginx]
		set truncable [list [list "size" [font measure $font_attr -displayof $canvas $ellips]]]
		set tofill [list ]
		set max_height [expr {[font metrics $font_attr -linespace]+$marginy}]
		set max_height_image 0

		lappend text [list "newline" "\n"]
		foreach unit $text {
			switch -exact [lindex $unit 0] {
				"text" {
					if {$truncflag} {
						lappend truncable [list "id" [llength $linewidth]]
					}
					lappend linewidth [font measure $font_attr -displayof $canvas [lindex $unit 1]]
					set height [expr {[font metrics $font_attr -linespace] + $marginy}]
					if {$height > $max_height} {
						set max_height $height
					}
				}
				"image" {
					if {$truncflag} {
						lappend truncable [list "id" [llength $linewidth]]
					}
					lappend linewidth [image width [lindex $unit 1]]
					set height [image height [lindex $unit 1]]
					if {$height > $max_height_image} {
						set max_height_image $height
					}
				}
				"smiley" {
					if {$truncflag} {
						lappend truncable [list "id" [llength $linewidth]]
					}
					lappend linewidth [image width [lindex $unit 1]]
					set height [expr {[image height [lindex $unit 1]] + $marginy}]
					if { $height > $max_height} {
						set max_height $height
					}
				}
				"space" {
					if {$truncflag} {
						lappend truncable [list "id" [llength $linewidth]]
					}
					lappend linewidth [lindex $unit 1]
				}
				"fill" {
					lappend tofill [llength $linewidth]
					#We will modify it at the end
					lappend linewidth 0
				}
				"tag" {
				}
				"colour" {
				}
				"bg" {
					#background
				}
				"font" {
					#We add to the list the size of ellipsis for last format
					lappend truncable [list "size" [font measure $font_attr -displayof $canvas $ellips]]
					#We must take in account fonts as they modifies the width of text
					if { [llength [lindex $unit 1]] == 1 } {
						if { [lindex $unit 1] == "reset" } {
							set font_attr [font configure $defaultfont]
						} else {
							set font_attr [font configure [lindex $unit 1]]
						}
					} else {
						array set current_format $font_attr
						array set modifications [lindex $unit 1]
						foreach key [array names modifications] {
							set current_format($key) [set modifications($key)]
							if { [set current_format($key)] == "reset" } {
								set current_format($key) \
									[font configure $defaultfont $key]
							}
						}
						set font_attr [array get current_format]
					}
				}
				"default" {
					set defaultcolour [lindex $unit 1]
					set defaultfont [lindex $unit 2]
				}
				"trunc" {
					set truncflag [expr {[lindex $unit 1]?1:0}]
					if {$truncflag && [llength $unit] > 2} {
						set ellips [lindex $unit 2]
					} else {
						set ellips $defaultellips
					}
				}
				"underline" {
				}
				"margin" {
					set marginx [lindex $unit 1]
				}
				"mark" {
				}
				"newline" {
					lappend linesheight $max_height
					set max_height [expr {[font metrics $font_attr -linespace]+$marginy}]
					lappend truncable [list "size" [font measure $font_attr -displayof $canvas $ellips]]
					lappend lineswidth [adaptSizes $linewidth $truncable $tofill $maxwidth]
					set linewidth [list $marginx]
					set truncable [list [list "size" [font measure $font_attr -displayof $canvas $ellips]]]
					set tofill [list ]
				}
				default {
					status_log "Unknown item in parsed nickname: $unit"
				}
			}
		}

		lappend linesheight 0

		set defaultcolour #000000
		set defaultfont splainf

		set underlinename ""

		set xpos 0
		#Because anchor is w
		set yori [expr {[lindex $linesheight 0]/2}]
		set yposimage $yori

		if {$detailed_view} {
			set ypos [expr {[lindex $linesheight 0] - ($max_height_image/2)}]
		} else {
			set ypos $yori
		}

		set marginx 0
		set marginy 0
		set colour $defaultcolour
		set colourignore 0
		set bg_x ""
		set bg_cl ""
		set list_bg [list ]
		set underline_yes 0
		set list_underline [list ]
		set overstrike_yes 0
		set list_overstrike [list ]
		set font_attr [font configure $defaultfont]
		#The text is placed at the middle of coords because anchor is w so we use only the half of the size
		set textheight [expr {[font metrics $font_attr -displayof $canvas -linespace]/2}]

		set ellips $defaultellips

		set tags $main_tag
		
		set i 0
		set j 1

		set linewidth [lindex $lineswidth $i]

		foreach unit $text {
			set size [lindex $linewidth $j]
			set nosize 0
			switch -exact [lindex $unit 0] {
				"text" {
					# Store the text as a string
					set textpart [lindex $unit 1]
	
					# Check if it's really containing text or has a good size, if not, do nothing
					if {$textpart != "" && $size != 0} {
	
						# Check if text is not too long and should be truncated, then
						# first truncate it and restore it in $textpart and set the linefull
						if {[font measure $font_attr -displayof $canvas $textpart] > $size} {
							set textpart [::guiContactList::truncateText $textpart \
								[expr {$size-[font measure $font_attr -displayof $canvas $ellips]}] \
								$font_attr]

							set textpart "$textpart$ellips"
						}
	
						# Draw the text
						$canvas create text $xpos [expr {$ypos + $marginy}] -text $textpart \
							-anchor w -fill $colour -font $font_attr -tags $tags

						set textwidth [font measure $font_attr -displayof $canvas $textpart]

						if {$underlinename != ""} {
							# Append underline coords
							set yunderline [expr {$ypos - $yori + $marginy + $textheight + 1}]
							lappend underlinearr($underlinename) \
								[list $xpos $yunderline $textwidth $colour]
						}
						
						if {$underline_yes} {
							set yunderline [expr {$ypos - $yori + $marginy + $textheight + 1}]
							lappend list_underline [list $xpos $yunderline $textwidth $colour]
						}

						if {$overstrike_yes} {
							set yunderline [expr {$ypos - $yori + $marginy + $textheight + 1}]
							set yunderline [expr { $yunderline / 2}]
							lappend list_overstrike [list $xpos $yunderline $textwidth $colour]
						}

						# Change the coords
						incr xpos $textwidth
					}
				}
				"smiley" {
					set imagename [lindex $unit 1]
					if { [image width $imagename] <= $size } {
						# Draw the image
						$canvas create image $xpos [expr {$ypos + $marginy}] \
							-image $imagename -anchor w -tags $tags
						# Change the coords
						incr xpos [image width $imagename]
					} elseif { $size > 0 } {
						$canvas create text $xpos [expr {$ypos + $marginy}] -text $ellips \
							-anchor w -fill $colour -font $font_attr -tags $tags
						set textwidth [font measure $font_attr -displayof $canvas $ellips]

						if {$underlinename != ""} {
							# Append underline coords
							set yunderline [expr {$ypos - $yori + $marginy + $textheight + 1}]
							lappend underlinearr($underlinename) \
								[list $xpos $yunderline $textwidth $colour]
						}
						# Change the coords
						incr xpos $textwidth
					}
				}
				"bg" {
					set nosize 1
					if {$bg_x eq ""} {
						if {[lindex $unit 1] ne "reset"} {
							set bg_x $xpos
							set bg_cl [lindex $unit 1]
						}
					} else {
						set yunder [expr {$ypos - $yori + $marginy + $textheight}]
						lappend list_bg [list $bg_x $ypos $xpos $yunder $textheight $bg_cl]

						set bg_cl [lindex $unit 1]
						if {$bg_cl eq "reset"} {
							set bg_x ""
						} else {
							set bg_x $xpos
						}
					}
				}
				"image" {
					set imagename [lindex $unit 1]
					set anchor [lindex $unit 2]
	
					if { [image width $imagename] <= $size } {
						# Draw the image
						$canvas create image $xpos [expr {$yposimage + $marginy}] \
							-image $imagename -anchor $anchor -tags $tags
						# Change the coords
						incr xpos [image width $imagename]
					} elseif { $size > 0 } {
						$canvas create text $xpos [expr {$ypos + $marginy}] -text $ellips \
							-anchor w -fill $colour -font $font_attr -tags $tags
						set textwidth [font measure $font_attr -displayof $canvas $ellips]

						if {$underlinename != ""} {
							# Append underline coords
							set yunderline [expr {$ypos - $yori + $marginy + $textheight + 1}]
							lappend underlinearr($underlinename) \
								[list $xpos $yunderline $textwidth $colour]
						}
						# Change the coords
						incr xpos $textwidth
					}
				}
				"space" {
					incr xpos $size
				}
				"fill" {
					incr xpos $size
				}
				"tag" {
					set nosize 1
					if {[string index [lindex $unit 1] 0] == "-" } {
						#Remove tag
						set tag [string range [lindex $unit 1] 1 end]
						set id [lsearch -exact $tags $tag]
						if {$id >= [llength $main_tag]} {
							#We don't want to remove the first tags
							set tags [lreplace $tags $id $id]
						}
					} else {
						if {[lsearch -exact $tags [lindex $unit 1]] == -1} {
							lappend tags [lindex $unit 1]
						}
					}
				}
				"colour" {
					set nosize 1
					# A plugin like aMSN Plus! could make the text lists
					# contain an extra variable for colourchanges
					switch -exact [lindex $unit 1] {
						"reset" {
							if {!$colourignore} {
								set colour $defaultcolour
							}
						}
						"ignore" {
							set colourignore 1
						}
						"unignore" {
							set colourignore 0
						}
						default {
							if {!$colourignore} {
								set colour [lindex $unit 1]
							}
						}
					}
				}
				"font" {
					set nosize 1

					if {[lindex [lindex $unit 1] 0] eq "-underline"} {
						if {[lindex [lindex $unit 1] 1] == 1} {
							set underline_yes 1
						} else {
							set underline_yes 0
						}
					}
					
					if {[lindex [lindex $unit 1] 0] eq "-overstrike"} {
						if {[lindex [lindex $unit 1] 1] == 1} {
							set overstrike_yes 1
						} else {
							set overstrike_yes 0
						}
					}
					
					
					if { [llength [lindex $unit 1]] == 1 } {
						if { [lindex $unit 1] == "reset" } {
							set font_attr [font configure $defaultfont]
							set underline_yes 0
							set overstrike_yes 0
						} else {
							set font_attr [font configure [lindex $unit 1]]
						}
					} else {
						array set current_format $font_attr
						array set modifications [lindex $unit 1]
						foreach key [array names modifications] {
							set current_format($key) [set modifications($key)]
							if { [set current_format($key)] == "reset" } {
								set current_format($key) \
									[font configure $defaultfont $key]
							}
						}
						set font_attr [array get current_format]
					}
					#The text is placed at the middle of coords because anchor is w so we use only the half of the size
					set textheight [expr {[font metrics $font_attr -displayof $canvas -linespace]/2}]
				}
				"default" {
					set nosize 1
					set defaultcolour [lindex $unit 1]
					set defaultfont [lindex $unit 2]
				}
				"trunc" {
					set nosize 1
					set truncflag [expr {[lindex $unit 1]?1:0}]
					if {$truncflag && [llength $unit] > 2} {
						set ellips [lindex $unit 2]
					} else {
						set ellips $defaultellips
					}
					#We already took care of this flag
				}
				"underline" {
					set nosize 1
					set underlinename [lindex $unit 1]
					set underlinearr($underlinename) [list ]
				}
				"margin" {
					set nosize 1
					set marginx [lindex $unit 1]
					set marginy [lindex $unit 2]
				}
				"mark" {
					set nosize 1
					$canvas create text $xpos [expr {$ypos + $marginy}] -anchor w -tags $tags
				}
				"newline" {
					set nosize 1
					set xpos $marginx
					#As coords are relative to middle we need to put a half of finished line and half of new one
					set ypos [expr {$ypos + [lindex $linesheight $i]/2 + \
						[lindex $linesheight [expr {$i+1}]]/2}]

					incr i
					set linewidth [lindex $lineswidth $i]
					set j 1
				}
				default {
					set nosize 1
				}
			}
			if {!$nosize} {
				incr j
			}
		#END the foreach loop
		}

		if {$list_underline ne ""} {
			underline_overstrike $canvas $list_underline $main_tag "un"
		}

		if {$list_overstrike ne ""} {
			underline_overstrike $canvas $list_overstrike $main_tag "ov"
		}
		
		if {$list_bg ne ""} {
			background_text $canvas $list_bg $main_tag
		}
		
		return [array get underlinearr]
	}

	proc trimInfo { varName } {
		upvar 1 $varName text
		while {1} {
			set unit [lindex $text end]
			set nosize 0
			switch -exact [lindex $unit 0] {
				"text" {
					set unit [lreplace $unit 1 1 [string trimright [lindex $unit 1]]]
					lset text end $unit
				}
				"smiley" {
				}
				"image" {
				}
				"space" {
				}
				"fill" {
				}
				"bg" {
				}
				default {
					set nosize 1
				}
			}
			if {$nosize} {
				set text [lreplace $text end end]
			} else {
				break
			}
		}
	}

	#/////////////////////////////////////////////////////////////////////////
	# Function that draws a contact 
	#/////////////////////////////////////////////////////////////////////////
	proc drawContact { canvas element groupID } {
		if { ${::guiContactList::external_lock} || !$::contactlist_loaded } { return }
	
		# We are gonna store the height of the nicknames
		variable nickheightArray

		#Xbegin is the padding between the beginning of the contact and the left edge of the CL
		variable Xbegin

		set stylestring [list ]

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
		set undock_space "${tag}_undock_space"
		set space_info "${tag}_space_info"

		################################################################
		# Set up some vars with info we'll use
		################################################################
		
		if {[::config::getKey show_detailed_view] && [::config::getKey show_contactdps_in_cl]} {
			set show_detailed_view 1
		} else {
			set show_detailed_view 0
		}

		set state_code [::abook::getVolatileData $email state FLN]

		set nickcolour [::abook::getContactData $email customcolor]
		if { $nickcolour != "" } {
			if { [string index $nickcolour 0] == "#" } {
				set nickcolour [string range $nickcolour 1 end]
			}
			set nickcolour [string tolower $nickcolour]
			set nickcolour "#[string repeat 0 [expr {6-[string length $nickcolour]}]]$nickcolour"
		}

		if { $nickcolour == "" || $nickcolour == "#" } {
			if { $state_code == "FLN" && [::abook::getContactData $email MOB] == "Y" } {
				set nickcolour [::skin::getKey "contact_mobile"]
				set statecolour [::skin::getKey "state_mobile" $nickcolour]
			} else {
				set nickcolour [::MSN::stateToColor $state_code "contact"]
				set statecolour [::MSN::stateToColor $state_code "state"]
			}
			set force_colour 0
		} else {
			if { $state_code == "FLN" && [::abook::getContactData $email MOB] == "Y" } {
				set statecolour [::skin::getKey "state_mobile" [::skin::getKey "contact_mobile"]]
			} else {
				set statecolour [::MSN::stateToColor $state_code "state"]
			}
			set force_colour 1
		}

		set psm [::abook::getpsmmedia $email 1]

		if {[::MSN::userIsNotIM $email]} {
			set img [::skin::loadPixmap nonim]
		} elseif {[::config::getKey show_contactdps_in_cl] == "1" &&
		    !([::abook::getContactData $email MOB] == "Y" && $state_code == "FLN")} {
			set img [::skin::getLittleDisplayPictureName $email]_cl

			image create photo $img
			
			if {!$show_detailed_view} {
				$img copy [::skin::getLittleDisplayPicture $email [image height [::skin::loadPixmap plain_emblem ]]]
				
				# We can get a user "hidden" if you have yourself on your own CL and you use MSNP18+ with mpop
				if { $state_code == "FLN" || $state_code == "HDN"} {
					::picture::Colorize $img grey 0.5
					$img copy [::skin::loadPixmap plain_emblem]
				} elseif { $state_code == "NLN" } {
					$img copy [::skin::loadPixmap plain_emblem]
				} else {
					$img copy [::skin::loadPixmap [::MSN::stateToImage $state_code]_emblem]
				}

				#set the blocked emblem if the user is blocked
				if { [::MSN::userIsBlocked $email] } {
					$img copy [::skin::loadPixmap blocked_emblem]
				}

				# If you are not on this contact's list, show the notinlist emblem
				if {[expr {[lsearch [::abook::getLists $email] RL] == -1}]} {
					$img copy [::skin::loadPixmap notinlist_emblem]
				}
			} else {
				$img copy [::skin::getLittleDisplayPicture $email 60]
				
				#set the blocked emblem if the user is blocked
				if { [::MSN::userIsBlocked $email] } {
					$img copy [::skin::loadPixmap blocked_emblem_detailedview]
				}
			}

		} else {

			if { [::MSN::userIsBlocked $email] } {
				if { $state_code == "FLN" } { 
					set img [::skin::loadPixmap blocked_off] 
				} else {
					set img [::skin::loadPixmap blocked] 
				}
			} elseif { [::abook::getContactData $email client] == "Webmessenger" && $state_code != "FLN" } {
				#Show webMSN buddy icon
				set img [::skin::loadPixmap webmsn]
			} elseif { [::abook::getContactData $email MOB] == "Y" && $state_code == "FLN"} {
				set img [::skin::loadPixmap mobile]
			} else {
				set img [::skin::loadPixmap [::MSN::stateToImage $state_code]]
			}
		}
		

		# TODO: hovers for the status-icons
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
		
		set maxwidth [expr {[winfo width $canvas] - 2*$Xbegin - [::skin::getKey buddy_xpad] - 5}]

		################################################################
		# Beginning of the drawing
		################################################################

		set marginx 0
		set marginy 0

		#Delete elements of the contact if they still exist
		$canvas delete $tag

		lappend stylestring [list "underline" "ul"]
		lappend stylestring [list "default" $nickcolour splainf]
		lappend stylestring [list "colour" "reset"]
		lappend stylestring [list "font" "reset"]

		#To mark the begin of the bbox
		lappend stylestring [list "mark" ""]

		lappend stylestring [list "tag" "icon"]
		#--------------#
		###Space icon###
		#--------------#
		
		set showspaces [::config::getKey showspaces 1]
		if {$showspaces} {

			#this is when there is an update and we should show a star
			set space_update [::abook::getVolatileData $email space_updated 0]
			
			#is the space shown or not ?
			set space_shown [::abook::getVolatileData $email SpaceShowed 0]

			set update_img [::skin::loadPixmap space_update]
			set noupdate_img [::skin::loadPixmap space_noupdate]

			# Check if we need an icon to show an updated space/blog, and draw one if we do
			# We must create the icon and hide after else, the status icon will stick the border
			    # it's surely due to anchor parameter
			if { [::MSNSPACES::hasSpace $email] } {
				lappend stylestring [list "tag" "$space_icon"]
				if { $space_update } {
					lappend stylestring [list "image" "$update_img" "w"]
				} else {
					lappend stylestring [list "image" "$noupdate_img" "w"]
				}
				lappend stylestring [list "tag" "-$space_icon"]
			} else {
				# TODO : uncomment this line to get back the space needed for the support of MSN spaces.
				lappend stylestring [list "space" [image width $noupdate_img]]
			}

			incr marginx [image width $noupdate_img]
		}
		
		#---------------#
		###Status icon###
		#---------------#

		# Draw status-icon
		lappend stylestring [list "margin" $marginx $marginy]
		lappend stylestring [list "tag" "$main_part"]
		lappend stylestring [list "image" "$img" "w"]
		lappend stylestring [list "space" 2]
		incr marginx [expr {2+[image width $img]}]

# TODO: skin setting to draw buddypicture; statusicon should become icon + status overlay
# 	like:	draw icon or small buddypicture overlay it with the status-emblem

		#--------------#
		###Alarm icon###
		#--------------#

		#Draw alarm icon if alarm is set
		if { [::alarms::isEnabled $email] != ""} {
	
			if { [::alarms::isEnabled $email] } {
				set icon [::skin::loadPixmap bell]
			} else {
				set icon [::skin::loadPixmap belloff]
			}
			
			lappend stylestring [list "tag" "-$main_part"]
			lappend stylestring [list "tag" "alarm_$email"]
			lappend stylestring [list "image" "$icon" "w"]
			lappend stylestring [list "tag" "-alarm_$email"]
			lappend stylestring [list "tag" "$main_part"]

			incr marginx [image width $icon]

			# Binding for right click		 
			$canvas bind alarm_$email <<Button3>> "::alarms::configDialog \"$email\"; break;"
			$canvas bind alarm_$email <<Button1>> "switch_alarm \"$email\"; \
				::guiContactList::switch_alarm \"$email\" \"$canvas\" \"alarm_$email\"; break"

		}

		#----------------------------#
		###Not-on-reverse-list icon###
		#----------------------------#	


		if {$show_detailed_view || (![::config::getKey show_contactdps_in_cl] && !([::abook::getContactData $email MOB] == "Y" && $state_code == "FLN"))} {
			# If you are not on this contact's list, show the notification icon
			if {![::MSN::userIsNotIM $email] && [expr {[lsearch [::abook::getLists $email] RL] == -1}]} {
				set icon [::skin::loadPixmap notinlist]
				lappend stylestring [list "image" "$icon" "w"]
				incr marginx [image width $icon]
			}
		}

		lappend stylestring [list "space" 3]
		incr marginx 3

		# Now we're gonna draw the nickname itself
		lappend stylestring [list "tag" "-icon"]
		#-----------------#
		###Draw Nickname###
		#-----------------#
		lappend stylestring [list "margin" $marginx $marginy]

		if {$force_colour} {
			lappend stylestring [list "colour" "ignore"]
		}

		lappend stylestring [list "tag" "nick"]

		if { [::config::getKey truncatenames] } {
			lappend stylestring [list "trunc" 1 "..."]
		}

		set evpar(nick) $parsednick
		set evpar(login) $email
		::plugins::PostEvent guicl_drawnick evpar

		#Here we place nickname !!
		set stylestring [concat $stylestring $parsednick]

		if { [::config::getKey truncatenames] } {
			lappend stylestring [list "trunc" 0]
		}

		lappend stylestring [list "tag" "-nick"]
		#--------------------#
		###Draw Status-name###
		#--------------------#

		if { $statetext != "" } {

			lappend stylestring [list "space" $nickstatespacing]

			if {$force_colour} {
				lappend stylestring [list "colour" "unignore"]
			}

			lappend stylestring [list "colour" $statecolour]
			lappend stylestring [list "font" "reset"]

			lappend stylestring [list "tag" "state"]
			lappend stylestring [list "text" $statetext]
			lappend stylestring [list "tag" "-state"]

		#	lappend stylestring [list "colour" "reset"]

			if {$force_colour} {
				lappend stylestring [list "colour" "ignore"]
			}

		}
		
		#------------#
		###Draw PSM###
		#------------#

		if {[::abook::removeStyles $psm] != "" && [::config::getKey emailsincontactlist] == 0 } {

			lappend stylestring [list "default" [::skin::getKey buddypsmcolor $nickcolour] \
				[::skin::getFont buddypsmfont "sitalf"]]

			lappend stylestring [list "colour" "reset"]
			lappend stylestring [list "font" "reset"]
			
			if {$show_detailed_view} {
				set pos [lsearch -exact $psm [list smiley uiElement_std_note -]]
				if {$pos != -1} {
					set psm [linsert $psm $pos [list "newline" "\n"]]
				}
				set parsedpsm [linsert $psm 0 [list "newline" "\n"]]
			} elseif {[::config::getKey psmplace] == 1 } {
				set parsedpsm [linsert $psm 0 [list "text" " - "]]
			} elseif {[::config::getKey psmplace] == 2 } {
				set parsedpsm [linsert $psm 0 [list "newline" "\n"]]
			} else {
				set parsedpsm ""
			}


			#Here we place the PSM !!
			lappend stylestring [list "tag" "psm"]

			if { [::config::getKey truncatenames] } {
				lappend stylestring [list "trunc" 1 "..."]
			}

			set stylestring [concat $stylestring $parsedpsm]
			
			lappend stylestring [list "font" "reset"]
			lappend stylestring [list "colour" "reset"]
			
			if { [::config::getKey truncatenames] } {
				lappend stylestring [list "trunc" 0]
			}
			lappend stylestring [list "tag" "-psm"]

		}

		lappend stylestring [list "tag" "-$main_part"]

		if {$force_colour} {
			lappend stylestring [list "colour" "unignore"]
		}

		#----------------------------------#
		##Controversial inline spaces info##
		#----------------------------------#

		#This is a technology demo, the default is not unchangeable
		# values for this variable can be "inline", "ccard" or "disabled"
		if {$showspaces && $space_shown && \
			([::config::getKey spacesinfo "inline"] == "inline" || \
			[::config::getKey spacesinfo "inline"] == "both") } {

			lappend stylestring [list "newline" "\n"]
			if {[::config::getKey spacesinfo "inline"] == "both" } {
				#image to show the ccard
				lappend stylestring [list "tag" "icon"]
				lappend stylestring [list "tag" "$undock_space"]
				lappend stylestring [list "image" [::skin::loadPixmap spaces_undock] "w"]
				lappend stylestring [list "tag" "-$undock_space"]
				lappend stylestring [list "tag" "-icon"]
			}

			lappend stylestring [list "tag" "$space_info"]
			lappend stylestring [list "tag" "space_info"]

			set stylestring [concat $stylestring [::ccard::drawSpacesCL $canvas $email $tag \
				$marginx $marginy]]

			lappend stylestring [list "tag" "-space_info"]
			lappend stylestring [list "tag" "-$space_info"]
		}

		#---------------#
		##Rendering !! ##
		#---------------#

	#	trimInfo stylestring
		set renderInfo [renderContact $canvas [list $tag "contact"] $maxwidth $stylestring $show_detailed_view]
		array set underlinst $renderInfo


		#-----------#
		##Bindings###
		#-----------#

		# First, remove previous bindings
		cleanBindings $canvas $tag
		cleanBindings $canvas $main_part
		cleanBindings $canvas $space_icon

		#Click binding for the "star" image for spaces
		$canvas bind $space_icon <Button-1> [list ::guiContactList::toggleSpaceShown $email]

		$canvas bind $undock_space <Button-1> [list ::ccard::drawwindow $email 1]
		##TODO# not sure about this one:
		$canvas bind $undock_space <Button-1> +[list ::guiContactList::toggleSpaceShown $email]

		# balloon bindings
		if { [::config::getKey tooltips] == 1 } {
			$canvas bind $space_icon <Enter> +[list ::guiContactList::balloon_enter_CL %W %X %Y [trans viewspace] ]
			$canvas bind $space_icon <Motion> +[list ::guiContactList::balloon_motion_CL %W %X %Y [trans viewspace] ]
			$canvas bind $space_icon <Leave> "+set ::Bulle(first) 0; kill_balloon"
		}

		# Add binding for underline if the skinner use it
		if {[::skin::getKey underline_contact]} {
			$canvas bind $main_part <Enter> \
				+[list ::guiContactList::underlineList $canvas [set underlinst(ul)] "$tag"]
			$canvas bind $main_part <Leave> +[list $canvas delete "uline_$tag"]
		}
		
		# Add binding for balloon
		if { [::config::getKey tooltips] == 1 } {
			set b_content [getBalloonMessage $email $element]
			set b_fonts [list "sboldf" "sitalf" "splainf" "splainf"]
			$canvas bind $main_part <Enter> +[list ::guiContactList::balloon_enter_CL %W %X %Y $b_content [::skin::getDisplayPicture $email] $b_fonts complex]
			$canvas bind $main_part <Motion> +[list ::guiContactList::balloon_motion_CL %W %X %Y $b_content [::skin::getDisplayPicture $email] $b_fonts complex]
			$canvas bind $main_part <Leave> "+set ::Bulle(first) 0; kill_balloon"
		}


		# Binding for left (double)click
		if {[::MSN::userIsNotIM $email] } {
			# If the user is a non IM user, send email.
			$canvas bind $main_part <ButtonRelease-1> [list ::guiContactList::contactCheckDoubleClick \
				"set ::guiContactList::displayCWAfterId \
				\[after 0 \[list launch_mailer \"$email\"\]\]" $main_part %X %Y %t]
		} elseif { $state_code == "FLN" && [::abook::getContactData $email MOB] == "Y"} {
			# If the user is offline and support mobile (SMS)
			$canvas bind $main_part <ButtonRelease-1> [list ::guiContactList::contactCheckDoubleClick \
				"set ::guiContactList::displayCWAfterId \
				\[after 0 \[list ::MSNMobile::OpenMobileWindow \"$email\"\]\]" $main_part %X %Y %t]
		} else {
			$canvas bind $main_part <ButtonRelease-1> [list ::guiContactList::contactCheckDoubleClick \
				"set ::guiContactList::displayCWAfterId \
				\[after 0 \[list ::amsn::chatUser \"$email\"\]\]" $main_part %X %Y %t]
		}

		# Binding for right click		 
		$canvas bind $main_part <<Button3>> [list show_umenu "$email" "$grId" %X %Y]
		if {[OnMac]} {
			# Control click also acts as a right click.
			$canvas bind $main_part <Control-ButtonPress-1> [list show_umenu "$email" "$grId" %X %Y]
		}
		
		# Bindings for dragging : applies to all elements even the star
		$canvas bind $tag <ButtonPress-1> [list ::guiContactList::contactPress $tag $canvas %s %x %y]

		#cursor change bindings
		if { [::skin::getKey changecursor_contact] } {
			$canvas bind $tag <Enter> +[list ::guiContactList::configureCursor $canvas hand2]
			$canvas bind $tag <Leave> +[list ::guiContactList::configureCursor $canvas left_ptr]
		}
		
		#create mouse hover bind to select the background and showing a background selector
		if { [::skin::getKey contact_hover_box] ne "" } {
			$canvas bind $tag <Enter> +[list ::guiContactList::user_background $canvas "$tag" $maxwidth ]
			$canvas bind $tag <Leave> +[list $canvas delete contact_box ]
		}

		# Now store the nickname [and] height in the nickarray
		if {[llength [$canvas find withtag $tag]] > 0 } {
			set bbox [$canvas bbox $tag]
			set nickheightArray($email) [expr {[lindex $bbox 3]-[lindex $bbox 1]}]
		} else {
			set nickheightArray($email) 0
		}
	}
	
	proc user_background {canvas tag maxwidth} {
		set bbox [$canvas bbox $tag]
		set coords [$canvas coords $tag]
		$canvas create rect \
			[expr { [lindex $bbox 0] + [lindex $coords 0] - [::skin::getKey contactlist_xpad] - (2* [::skin::getKey buddy_xpad])}] \
			[lindex $bbox 1] \
			[expr { $maxwidth + [::skin::getKey contactlist_xpad] + [::skin::getKey buddy_xpad] + 4}] \
			[lindex $bbox 3] \
			-fill [::skin::getKey contact_hover_box] -tags [list contact_box$tag contact_box]
		$canvas lower contact_box$tag $tag
	}

	proc cleanBindings {canvas tag} {
		foreach seq [$canvas bind $tag] {
			$canvas bind $tag $seq [list ]
		}
	}
	
	proc toggleSpaceShown {email} {
		if { [::config::getKey spacesinfo "inline"] == "inline" || [::config::getKey spacesinfo "inline"] == "both" } {
			if {[::abook::getVolatileData $email SpaceShowed 0]} {
				::abook::setVolatileData $email SpaceShowed 0
			} else {
				::MSNSPACES::fetchSpace $email
				::abook::setVolatileData $email SpaceShowed 1
			}
			::guiContactList::contactChanged "toggleSpaceShown" $email
		} elseif { [::config::getKey spacesinfo "inline"] == "ccard" } {
			::MSNSPACES::fetchSpace $email
			::ccard::drawwindow $email 1
		}
	}
	
	
	proc getContactList { {kind "normal"} } {
		set contactList [list]
		
		# First let's get our groups
		if { $kind == "full" } {
			set groupList [getGroupList 0 1] ;# Get the offline group as well if the full cl is requested.
		} else {
			set groupList [getGroupList]
		}

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
			foreach user $userGroupList {
				# If this contact matches this group, let's add him
				# set hisgroupslist [lindex $user 1]
				if { [lsearch [lindex $user 1] [lindex $group 0]] != -1 } {
					lappend contactList [list "C" [lindex $user 0]]
				}
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
		if { $mode == 0 || $mode == 2 || [lindex $element 0] == "nonim" } {
			# Status mode or Hybrid mode
			set groupcount [lindex $groupcounts $mobileidx]
		}  elseif { $mode == 1} {
			# Group mode
			set groupcount "[lindex $groupcounts 0]/[lindex $groupcounts 1]"
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
	proc getGroupList { {realgroups 0} {forceoffline 0} } {
		set mode [::config::getKey orderbygroup]
		
		set drawOfflineGroup [::config::getKey showOfflineGroup 1]
		set drawMobileGroup [::config::getKey showMobileGroup 0]
		set drawNoimGroup [::config::getKey groupnonim 0]
		
		# We need to draw the offline group even if the config key is set. We can then hide the group if requested.
		if { $forceoffline == 1 } {
			set drawOfflineGroup 1
		}
		
		# Online/Offline mode
		if { $mode == 0 } {
			if { $realgroups } {
				set groupList [list ]
			} else {
				set groupList [list ]
				
				lappend groupList [list "online" [trans uonline]]
				if {$drawMobileGroup == 1} {
					# We need to draw the mobile group.
					lappend groupList [list "mobile" [trans mobile]]
				}
				if {$drawOfflineGroup == 1} {
					lappend groupList [list "offline" [trans uoffline]]
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
			set groupList [linsert $groupList 0 [list 0 [trans nogroup]]]
		}
		
		# Hybrid Mode, we add mobile and offline group
		if { $mode == 2 && !$realgroups } {
			if {$drawMobileGroup == 1} {
				lappend groupList [list "mobile" [trans mobile]]
			}
			if {$drawOfflineGroup == 1} {
				lappend groupList [list "offline" [trans uoffline]]
			}
		}

		if {$drawNoimGroup == 1} {
			lappend groupList [list "nonim" [trans nonimgroup]]
		}

		return $groupList
	}


	################################################################
	# Function that returns the appropriate GroupID(s) for the user
	# this GroupID depends on the group view mode selected
	proc getGroupId { email } {
		if { [lsearch [::abook::getLists $email] "FL"] == -1 &&
		     [lsearch [::abook::getLists $email] "EL"] == -1 } {
			#The contact isn't in the contact list
			return [list ]
		}
		if {[lsearch [::abook::getLists $email] "EL"] != -1 } {
			if { [::config::getKey shownonim] == 0} {
				return [list]
			}
			if { [::config::getKey groupnonim] == 1} {
				return [list "nonim"]
			}
		} 

		set mode [::config::getKey orderbygroup]
		set status [::abook::getVolatileData $email state FLN]
		
		# Online/Offline mode
		if { $mode == 0 } {
			if { $status == "FLN" } {
				if { [::abook::getContactData $email MOB] == "Y" \
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
				if { [::abook::getContactData $email MOB] == "Y" && [::config::getKey showMobileGroup] == 1} {
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
		set state_code [::abook::getVolatileData $email state FLN]
		set psmmedia [::abook::getpsmmedia $email]

		# Define the final balloon message
		set balloon_message [list [string map { "%" "%%" } [::abook::getNick $email]]]
		lappend balloon_message [string map { "%" "%%" } $psmmedia]
		lappend balloon_message "$email"
		if {[::MSN::userIsNotIM $email] } {
			lappend balloon_message "[trans notimcontact]"
		} else {
			lappend balloon_message "[trans status]: [trans [::MSN::stateToDescription $state_code]]"
			if {[expr {[lsearch [::abook::getLists $email] RL] == -1}]} {
				lappend balloon_message "[trans notinlist]"
			}
			if {[::abook::getContactData $email webcam_shared] == 1} {
				lappend balloon_message "[trans shareswebcam]"
			}	
			return $balloon_message	
		}
	}


	proc truncateText { text maxwidth font {ellipsis ""}} {

		set shortened ""
		set stringlength [string length $text]
		set ellipsislenght [font measure $font -displayof . $ellipsis]

		set maxwidth [expr {$maxwidth - $ellipsislenght}]

		# Store stringlength
		for {set x 0} {$x < $stringlength} {incr x} {
			set nextchar [string range $text $x $x]
			set nextstring "$shortened$nextchar"
			if {[font measure $font -displayof . $nextstring] > $maxwidth} {
				break
			}
			set shortened "$nextstring"
		}
		return "$shortened$ellipsis"
	
	}


	proc background_text { canvas lines nicktag} {
		set poslist [$canvas coords [lindex $nicktag 0]]
		set xpos [lindex $poslist 0]
		set ypos [lindex $poslist 1]

		#if we are using the detailed view
		if {[lindex [lindex $lines 0] 1] < 0} {
			set margin_y [expr {[lindex [lindex $lines 0] 1] * -2 + 1}]
		} else {
			set margin_y 0
		}

		set tag [lindex $nicktag 0]
		set bgtag "bg$tag"
		
		foreach line $lines {
			set textheight [lindex $line 4]
			$canvas create rect\
				[expr { [lindex $line 0] + $xpos } ] \
				[expr { [lindex $line 1] - ($textheight*2) + $ypos + $margin_y} ] \
				[lindex $line 2]\
				[expr { [lindex $line 3] + $ypos + $margin_y} ] \
				-fill [lindex $line 5] \
				-outline "" \
				-tags [list $bgtag $tag contact bg]
		}
		
		$canvas lower $bgtag "$tag"
	}


	#######################################################
	# Procedure that draws horizontal lines from this list
	# of [list xcoord xcoord linelength] lists
	proc underline_overstrike { canvas lines nicktag opt} {
	
		set poslist [$canvas coords [lindex $nicktag 0]]
		set xpos [lindex $poslist 0]
		if {$opt eq "ov"} {
			if {$nicktag ne "all"} {
				set ypos [expr {[lindex $poslist 1] / 2} ]
			} else {
				set ypos [expr {[lindex $poslist 1] + 5} ]
			}
		} else {
			set ypos [expr {[lindex $poslist 1] - 2}]
		}
		# status_log "poslist: $lines"

		if {$opt ne "ov"} {
			#if we are using the detailed view
			if {[lindex [lindex $lines 0] 1] < 0} {
				set margin_y [expr {[lindex [lindex $lines 0] 1] * -2 + 1}]
			} else {
				set margin_y 0
			}
		} else {
			set margin_y 0
		}

		foreach line $lines {
			$canvas create line\
				[expr { [lindex $line 0] + $xpos } ] \
				[expr { [lindex $line 1] + $ypos + $margin_y} ] \
				[expr { [lindex $line 0] + [lindex $line 2] + $xpos} ]\
				[expr { [lindex $line 1] + $ypos + $margin_y} ] \
				-fill [lindex $line 3] \
				-tags "$nicktag $opt"
		}

		#$canvas lower unline_$nicktag $nicktag
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

		#if we are using the detailed view
		if {[lindex [lindex $lines 0] 1] < 0} {
			set margin_y [expr {[lindex [lindex $lines 0] 1] * -2 + 1}]
		} else {
			set margin_y 0
		}

		if {!$OnTheMove} {
			foreach line $lines {
				$canvas create line\
					[expr { [lindex $line 0] + $xpos } ] \
					[expr { [lindex $line 1] + $ypos + $margin_y} ] \
					[expr { [lindex $line 0] + [lindex $line 2] + $xpos } ]\
					[expr { [lindex $line 1] + $ypos + $margin_y} ] \
					-fill [lindex $line 3]\
					-tags [list uline_$nicktag $nicktag uline]
			}
			$canvas lower uline_$nicktag $nicktag
		}
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
		$canvas raise $tag
	}

	proc contactCheckDoubleClick { callback tag x y t } {
		if {[OnMac]} {
			# With TkAqua,the default double click interval is too weak, so we increase it here to 800ms.
			set doubleClickInterval 800
		} else {
			# Tk default (500ms).
			set doubleClickInterval 500
		}
		variable lastClickCoords
		if { [::config::getKey sngdblclick] } {
			#No need to check as a single click is enough
			eval $callback
			return
		}
		if { [info exists lastClickCoords] } {
			if { abs([lindex $lastClickCoords 0]-$x) <= 5 && abs([lindex $lastClickCoords 1]-$y) <= 5 && \
				abs($t-[lindex $lastClickCoords 2]) <= $doubleClickInterval && \
				[lindex $lastClickCoords 3] == $tag } {
				eval $callback
				unset lastClickCoords
				return
			}
		}
		set lastClickCoords [list $x $y $t $tag]
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

		set coordX [expr {[$canvas canvasx $x] - $DragDeltaX}]
		set coordY [expr {[$canvas canvasy $y] - $DragDeltaY}]

		set ChangeX [expr {[lindex $DragStartCoords 0] - $coordX}]
		set ChangeY [expr {[lindex $DragStartCoords 1] - $coordY}]

		# Check if we're not dragging off the CL
		if { $coordX < 0 || ( abs($ChangeX) <= 5 && abs($ChangeY) <= 5 ) } { 
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
			foreach group [getGroupList 0] {
				# Get the group ID
				set grId [lindex $group 0]
				set grCoords [$canvas coords gid_$grId]
				# Only go for groups that are actually drawn on the list
				if { $grCoords != ""} {
					# Get the coordinates of the group
					set grYCoord [lindex $grCoords 1]
					# This +5 is to make dragging a contact on a group's name
					# or 5 pixels above the group's name possible
					if {$grYCoord <= [expr {$coordY + 5}]} {
						set newgrId $grId
					}
				}
			}

			set newgrIdV 0
			set oldgrIdV 0
			#Now, we check if groups selected are real
			#We mustn't drag to nogroup but we can drag from it
			if { $newgrId != 0 } {
				foreach group [getGroupList 1] {
					# Get the group ID
					set grId [lindex $group 0]
					if { $grId == $newgrId } {
						set newgrIdV 1
					}
					if { $grId == $oldgrId } {
						set oldgrIdV 1
					}
				}
			}

			if { $newgrId == $oldgrId || !$newgrIdV || !$oldgrIdV } {
				#if the contact was dragged to the group of origin or is from/to an fake group, just move it back
				::guiContactList::organiseList $canvas [getContactList]
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

	proc balloon_enter_CL { w x y msg {img ""} {fonts ""} {mode "simple"} } {
		variable OnTheMove
		#When dragging don't show the tooltips
		if { !$OnTheMove } {
			balloon_enter $w $x $y $msg $img $fonts $mode
		}
	}

	proc balloon_motion_CL { w x y msg {img ""} {fonts ""} {mode "simple"} } {
		variable OnTheMove
		#When dragging don't show the tooltips
		if { !$OnTheMove } {
			balloon_motion $w $x $y $msg $img $fonts $mode
		}
	}

	proc configureCursor { canvas cursor } {
		variable OnTheMove
		#When dragging don't show the tooltips
		if { !$OnTheMove } {
			$canvas configure -cursor $cursor
		}
	}
	
	proc DetailedView {} {
		if {[::config::getKey show_detailed_view]} {
			foreach element [getContactList full] {
				if {[lindex $element 0] eq "C" } {
					::skin::getLittleDisplayPicture [lindex $element 1] 60 1
				}
			}
		} else {
			set dim [image height [::skin::loadPixmap plain_emblem ]]
			foreach element [getContactList full] {
				if {[lindex $element 0] eq "C" } {
					::skin::getLittleDisplayPicture [lindex $element 1] $dim 1
				}
			}
		}
		updateCL
	}

}

