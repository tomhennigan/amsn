#Still on TODO:
#
# * set right mousewheel bindings (windows/mac) using [IsMac] etc procs
# * redraw on skinchange
# * scroll the canvas while dragging if you come near to the border (hard one :|)
# * change cursor while dragging (should we ?)
# * background doesn't move when using the scrollbar 
#        -> needs a FIX in ScrolledWindow code to have a command feeded run when scrolling
# * animated smileys on CL -> I hope this is possible easily with TkCxImage?
# * events when the groupview option is changed to redraw the whole list
# *
# *
# * ... cfr. "TODO:" msgs in code





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


	#/////////////////////////////////////////////////////////////////////
	# Function that draws a window where it embeds our contactlist canvas 
	#  (in a scrolledwindow) (this proc will nto be used if this gets
	#  embedded in the normal window
	#/////////////////////////////////////////////////////////////////////
	proc createCLWindow {} {
		global clcanvas
		#define global variables
		global tcl_platform
		global nicknameArray

		#here we load images used in this code:
		::skin::setPixmap back back.gif

		#set easy names for the widgets
		set window .contactlist
		set clcontainer .contactlist.sw
		set clcanvas .contactlist.sw.cvs

		#check if the window already exists, ifso, raise it and redraw the CL
		if { [winfo exists $window] } {
			raise $window
			drawList $clcanvas
			return
		}


		#create the window
		toplevel $window
		wm title $window "[trans title] - [::config::getKey login]"
		wm geometry $window 1000x1000
		#set up the 'ScrolledWindow' container for the canvas
		ScrolledWindow $clcontainer -auto vertical -scrollbar vertical -bg white -bd 0
#TODO:	* ScrolledWindow should be feeded a command run on scroll (reset the image)
#	* bgcolor should be skinnable

		#set beginning big width/height		
		set clbox [list 0 0 2000 1500]

		#create a blank canvas
		canvas $clcanvas -width [lindex $clbox 2] -height [lindex $clbox 3] -background white
#TODO:	* bgcolor should be skinnable:

		#embed the canvas in the ScrolledWindow
		$clcontainer setwidget $clcanvas
		#pack the scrolledwindow in the window
		pack $clcontainer
		#parse the nicknames for smiley/newline substitution
		createNicknameArray

		$clcanvas create image 0 0 -image [::skin::loadPixmap back] -anchor nw -tag backgroundimage
		after 1 ::guiContactList::drawList $clcanvas

		#register events
#TODO:	* here we should register all needed events
	 ::Event::registerEvent contactNickChange all ::guiContactList::contactChanged
	 ::Event::registerEvent contactStateChange all ::guiContactList::contactChanged
	 ::Event::registerEvent blockedContact all ::guiContactList::contactChanged
	 ::Event::registerEvent unblockedContact all ::guiContactList::contactChanged



#TODO:	* create the bindings for scrolling (using procs "IsMac" etc)





#TODO		#scrollbindings: make 'm work for every platform !
#		 scrolledwindow should be feeded a command that moves the background 
#		 so it's also at the right place when the bar is dragged

		#MAC classic/osx and windows
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
#TODO: fix mac bindings -> Jerome's job ;)
		
			bind $canvas <MouseWheel> {
				%W yview scroll [expr {- (%D)}] units ;
				$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]
			}
				bind [winfo parent $canvas].vscroll <MouseWheel> {
				%W yview scroll [expr {- (%D)}] units ;
				$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]  
			}

		} elseif {$tcl_platform(platform) == "windows"} {
#TODO: fix win bindings -> Arieh's job ;)
			#bind $clcanvas <MouseWheel> {
			#	::guiContactList::scrollCL $clcanvas [expr {- (%D)}]
			#}
			bind [winfo parent [winfo parent $clcanvas]] <MouseWheel> {
				if {%D >= 0} {
					::guiContactList::scrollCL .contactlist.sw.cvs up
				} else {
					::guiContactList::scrollCL .contactlist.sw.cvs down
				}
			}

		} else {
			#we're on X11 ! (I suppose ;))
			bind $clcanvas <ButtonPress-5> "::guiContactList::scrollCL $clcanvas down"		
			bind $clcanvas <ButtonPress-4> "::guiContactList::scrollCL $clcanvas up"
			bind [winfo parent $clcanvas].vscroll <ButtonPress-5> "::guiContactList::scrollCL $clcanvas down"
			bind [winfo parent $clcanvas].vscroll <ButtonPress-4> "::guiContactList::scrollCL $clcanvas up"
		}







		#Let's avoid the bug of window behind the bar menu on Mac OS X
		catch {wm geometry .contactlist [::config::getKey wingeometry]}
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			moveinscreen .contactlist 30
		}


		bind $clcanvas <Configure> "::guiContactList::drawList $clcanvas"

		#set the size
		wm geometry $window 300x600
	}




	#/////////////////////////////////////////////////////////////////////
	# Function that draws everything needed on the canvas
	#/////////////////////////////////////////////////////////////////////
	proc drawList {canvas} {
		global Xbegin
		global Ybegin

		set Xbegin 10
		set Ybegin 10

		::guiContactList::drawGroups $canvas
		::guiContactList::drawContacts $canvas
		::guiContactList::organiseList $canvas
	}


	proc moveBGimage { canvas } {
		set canvaslength [lindex [$canvas cget -scrollregion] 3]
		if {$canvaslength == ""} { set canvaslenght 0}
		$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]
		$canvas lower backgroundimage
	}




	proc drawGroups { canvas } {

		# Now let's get the actual whole contact list (also not shown users)
		set contactList [getContactList full]


		foreach element $contactList {
			# We check the type, and call the appropriate draw function

			if {[lindex $element 0] != "C" } {
				#draw the group title
				drawGroup $canvas $element
			}
		}
	}

	proc drawContacts { canvas } {

		set groupID "offline"

		# Now let's get the actual whole contact list (also not shown users)
		set contactList [getContactList full]


		foreach element $contactList {
			# We check the type, and call the appropriate draw function

			if {[lindex $element 0] == "C" } {
				#draw the group title
				drawContact $canvas $element $groupID
			} else {
				set groupID [lindex $element 0]
			}
		}
	}


	proc contactChanged { eventused email } {

	if { [winfo exists .contactlist] } {

		global nicknameArray
status_log "event triggered: $eventused with variable: $email"

		set usernick "[::abook::getDisplayNick $email]"
		set nicknameArray("$email") "[::smiley::parseMessageToList $usernick 1]"

		set groupslist [list [getGroupId $email]]
		foreach group $groupslist {
			set element [list "C" $email]
			::guiContactList::drawContact .contactlist.sw.cvs $element $group
		}
		::guiContactList::organiseList .contactlist.sw.cvs
	  }
	}




	proc toggleGroup { element canvas} {
		::groups::ToggleStatus [lindex $element 0]
		# Redraw group as it's state changed
		::guiContactList::drawGroup $canvas $element 
		::guiContactList::organiseList $canvas
	}





	# Move 'm to the right place
	proc organiseList { canvas } {
		global Xbegin
		global Ybegin
		global nickheightArray

		# First we move all the canvas items
		$canvas addtag items withtag group
		$canvas addtag items withtag contact
		# make sure we move 'm to an invisible place first
		$canvas move items 100000 100000

		# Now let's get an exact contact list
		set contactList [getContactList]

		#Before drawing we set the "we are draggin, sir" variable on 0
		set OnTheMove 0

		# Let's draw each element of this list
		set curPos [list $Xbegin $Ybegin]

# TODO:	* an option for a X-padding for buddies .. should be set here and for teh truncation 
#		in the nickdraw proc

		foreach element $contactList {
			# We check the type, and call the appropriate draw function, these can be extended	
			# We got a contact
			if { [lindex $element 0] == "C" } {
				#move it to it's place an set the new curPos
				set email [lindex $element 1]
				set gid $groupDrawn
				set tag "_$gid"; set tag $email$tag
				
				set currentPos [$canvas coords $tag]
#status_log "MOVING CONTACT WITH TAG: $tag ;  currentpos: $currentPos  ; curPos: $curPos"
				if { $currentPos == ""} {

			status_log "WARNING: contact NOT moved: $email"
					return
				}

				$canvas move $tag [expr [lindex $curPos 0] - [lindex $currentPos 0]] [expr [lindex $curPos 1] - [lindex $currentPos 1]]

				set curPos [list [lindex $curPos 0] [expr [lindex $curPos 1] + $nickheightArray("$email")] ]

			# It must be a group title
			} else {
				#move it to it's place an set the new curPos
				set gid [lindex $element 0]
				set groupDrawn $gid

				set tag "gid_"; set tag $tag$gid
				set currentPos [$canvas coords $tag]

				if { $currentPos == ""} {
			status_log "WARNING: group NOT moved: $gid"
					return
				}

				$canvas move $tag [expr [lindex $curPos 0] - [lindex $currentPos 0]] [expr [lindex $curPos 1] - [lindex $currentPos 1]]

				set curPos [list [lindex $curPos 0] [expr [lindex $curPos 1] + 20] ]
#TODO:	* change this '20' to the right value
			}
		}		

		#set height of canvas
		set canvaslength [expr [lindex $curPos 1] + 20]
		$canvas configure -scrollregion [list 0 0 2000 $canvaslength]

		#make sure after redrawing the bgimage is on the right place
		$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]

	}












	#/////////////////////////////////////////////////////////////////////////
	# Function that draws a group 
	#/////////////////////////////////////////////////////////////////////////
	proc drawGroup { canvas element} {

		#set the group id, our ids are integers and tags can't be so add gid_ to start
		set gid gid_[lindex $element 0]

#		$canvas addtag items withtag $gid

		#delete the group before redrawing
		$canvas delete $gid

		set xpos 0
		set ypos 0
		
		# Let's setup the right image (expanded or contracted)
		if { [::groups::IsExpanded [lindex $element 0]] } {
			#set padding between image and text
			set xpad [::skin::getKey contract_xpad]
			set img [::skin::loadPixmap contract]
			set groupcolor [::skin::getKey groupcolorextend]
		} else {
			#set padding between image and text
			set xpad [::skin::getKey expand_xpad]
			set img [::skin::loadPixmap expand]
			set groupcolor [::skin::getKey groupcolorcontract]
		}


		set groupnamecountpad 5

		#Get the number of user for this group
		set groupcount [getGroupCount $element]
		
		#Store group name and groupcount as string, for measuring length of underline
		set groupnametext "[lindex $element 1]"
		set groupcounttext "($groupcount)"
		
		#Set the begin-position for the groupnametext
		set textxpos [expr $xpos + [image width $img] + $xpad]

		# First we draw our little group toggle button
		$canvas create image $xpos $ypos -image $img -anchor nw \
			-tags [list group toggleimg $gid]

		# then the group's name
		$canvas create text $textxpos $ypos -text $groupnametext -anchor nw \
			-fill $groupcolor -font sboldf -tags [list group title name_$gid $gid]

		set text2xpos [expr {$textxpos + [font measure sboldf $groupnametext] + $groupnamecountpad}]

		# then the group's count
		$canvas create text $text2xpos $ypos\
		 -text $groupcounttext -anchor nw -fill $groupcolor -font sboldf\
		 -tags [list group title count_$gid $gid]



		#Setup co-ords for underline on hover
		set yuline [expr $ypos + [font configure sboldf -size] + 3 ]

		set underlinst [list [list $textxpos $yuline [font measure sboldf $groupnametext] $groupcolor] [list $text2xpos $yuline [font measure sboldf $groupcounttext] $groupcolor] ]

		
		#Create mouse event bindings

		#Remove previous bindings
		$canvas bind $gid <Enter> ""
		$canvas bind $gid <Motion> ""
		$canvas bind $gid <Leave> ""
		$canvas bind $gid <<Button1>> ""
		$canvas bind $gid <<Button3>> ""


		$canvas bind $gid <<Button1>> "+::guiContactList::toggleGroup [list $element] $canvas"
		$canvas bind $gid <<Button3>> "+::groups::GroupMenu $gid %X %Y"


		$canvas bind $gid <Enter> "+::guiContactList::underlineList $canvas [list $underlinst] $gid"
		$canvas bind $gid <Leave> "+$canvas delete uline_$gid"

		#change cursor bindings for contacts
		$canvas bind $gid <Enter> "+$canvas configure -cursor hand2"
		$canvas bind $gid <Leave> "+$canvas configure -cursor left_ptr"


	}






	#/////////////////////////////////////////////////////////////////////////
	# Function that draws a contact 
	#/////////////////////////////////////////////////////////////////////////
	proc drawContact { canvas element groupID} {
		#we are gonna store the height of the nicknames
		global nickheightArray
		global nicknameArray
		global Xbegin

		#set the place for drawing it (should be invisible)
		set xpos 0
		set ypos 0
		
		set email [lindex $element 1]
		set grId $groupID

		# the tag can't be just $email as users can be in more then one group
		set tag "_$grId"; set tag "$email$tag"

		$canvas delete $tag

		set state_code [::abook::getVolatileData $email state FLN]
		
		if { [::abook::getContactData $email customcolor] != "" } {
			set nickcolour [::abook::getContactData $email customcolor] 
		} else {
			set nickcolour [::MSN::stateToColor $state_code]
		}


		if { [::MSN::userIsBlocked $email] } {
			set img [::skin::loadPixmap blocked]
		} elseif { [::abook::getVolatileData $email MOB] == "Y" && $state_code == "FLN"} {
			set img [::skin::loadPixmap mobile]
		} else {
			set img [::skin::loadPixmap [::MSN::stateToImage $state_code]]
		}




#TODO:	* hovers for the status-icons
#	* skinsetting to have buddypictures in their place (this is default in MSN7!)
#	   with a pixmap border and also status-emblem overlay in bottom right corner		
					
		
		set parsednick $nicknameArray("$email")

		set nickstatespacing 5
#TODO:	* skinsetting for the spacing between nicknames and the status
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
#TODO:	* skinsetting for state-colour
		set statewidth [font measure splainf $statetext]


		#draw status-icon
		$canvas create image $xpos $ypos -image $img -anchor nw \
			-tags [list contact icon $tag]
#TODO: skin setting to draw buddypicture; statusicon should become icon + status overlay
#like:	draw icon or small buddypicture
#	overlay it with the status-emblem


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

		#reset the underlining's list
		set underlinst [list]

		set maxwidth [winfo width $canvas]

		set ellips "..."

		#leave some place for the statustext, the elipsis (...) and the spacing + spacing of border and - the beginningborder
		set maxwidth [expr $maxwidth - $statewidth - [font measure splainf $ellips] - $nickstatespacing - 5 - $Xbegin]

# TODO:	* an option for a X-padding for buddies .. should be set here and in the organising proc


		#we can draw as long as the line isn't full
		set linefull 0

		set textheight [expr [font configure splainf -size]/2 ]

		#this is the var for the y-change
		set ychange [image height $img]

		set relnickcolour $nickcolour
		set relxnickpos $xnickpos
		set relynickpos $ypos

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
				lappend underlinst [list [expr $relxnickpos - $xpos] [expr $yunderline - $ypos] $textwidth $relnickcolour]
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
					lappend underlinst [list [expr $relxnickpos - $xpos]  [expr $yunderline - $ypos] $textwidth $relnickcolour]

					continue
				}

				#draw the smiley
				$canvas create image $relxnickpos $ynickpos -image $smileyname -anchor w\
					-tags [list contact $tag smiley]

#TODO:	* smileys should be resized to fit in text-height
				#if {[image height $smileyname] >= $ychange} {
				#	set ychange [image height $smileyname]
				#}

				#change the coords
				set relxnickpos [expr $relxnickpos + [image width $smileyname]]
			} elseif {[lindex $unit 0] == "newline"} {

				set relxnickpos $xnickpos
				set ynickpos [expr $ynickpos + [image height $img]]
				set ychange [expr $ychange + [image height $img]]

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
#TODO:	* maybe a skin-option to have the spacing underlined

		#append underline coords
		set yunderline [expr $ynickpos + $textheight + 1]
		lappend underlinst [list [expr $relxnickpos - $xpos] [expr $yunderline - $ypos] $statewidth $statecolour]

		}


		#The bindings:


		#Remove previous bindings
		$canvas bind $tag <Enter> ""
		$canvas bind $tag <Motion> ""
		$canvas bind $tag <Leave> ""
		
		#Add binding for balloon
		if { [::config::getKey tooltips] == 1 } {
			$canvas bind $tag <Enter> +[list balloon_enter %W %X %Y "[getBalloonMessage $email $element]" [::skin::getDisplayPicture $email]]
			$canvas bind $tag <Motion> +[list balloon_motion %W %X %Y "[getBalloonMessage $email $element]" [::skin::getDisplayPicture $email]]
			$canvas bind $tag <Leave> "+set Bulle(first) 0; kill_balloon"
		}
		
		#Add binding for click / right click (remembering to get config key for single/dbl click on contacts to open chat)
		if { [::config::getKey sngdblclick] } {
			set singordblclick <Button-1>
		} else {
			set singordblclick <Double-Button-1>
		}


		#binding for left (double)click
		if { $state_code != "FLN" } {
			$canvas bind $tag $singordblclick "::amsn::chatUser $email"
		} elseif {[::abook::getVolatileData $email MOB] == "Y"} {
			#If the user is offline and support mobile (SMS)
			$canvas bind $tag $singordblclick "::MSNMobile::OpenMobileWindow ${email}"
		} else {
			$canvas bind $tag $singordblclick ""
		}

		#binding for right click		 
		$canvas bind $tag <<Button3>> "show_umenu $email $grId %X %Y"

		#bindings for dragging
		$canvas bind $tag <<Button2-Press>> "::guiContactList::contactPress $tag $canvas"
		$canvas bind $tag <<Button2-Motion>> "::guiContactList::contactMove $tag $canvas"
		$canvas bind $tag <<Button2>> "::guiContactList::contactReleased $tag $canvas"

		#Add binding for underline if the skinner use it
		if {[::skin::getKey underline_contact]} {
			$canvas bind $tag <Enter> "+::guiContactList::underlineList $canvas [list $underlinst] $tag"
			$canvas bind $tag <Leave> "+$canvas delete uline"
		}


		#change cursor bindings for contacts
		$canvas bind $tag <Enter> "+$canvas configure -cursor hand2"
		$canvas bind $tag <Leave> "+$canvas configure -cursor left_ptr"

		#now store the nickname [and] height in the nickarray
		set nickheight [expr $ychange + [::skin::getKey buddy_ypad] ]
		set nickheightArray("$email") $nickheight
#status_log "nickheight $email: $nickheight"

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
		
		# Go through each group, and insert the contacts in a new list that will represent our GUI view
		foreach group $groupList {
			set grId [lindex $group 0]
			
			# if group is empty and remove empty groups is set (or this is Individuals group) then skip this group
			if { ($grId == 0 || ([::config::getKey removeempty] && $grId != "offline" && $grId != "mobile")) && [getGroupCount $group] == 0} {
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


	#proc that draws horizontal lines from this list of [list xcoord xcoord linelength] lists
	proc underlineList { canvas lines nicktag} {
		set poslist [$canvas coords $nicktag]
		set xpos [lindex $poslist 0]
#	status_log "poslist: $lines"
		set ypos [lindex $poslist 1]
		global OnTheMove

		#if {!$OnTheMove} {
			foreach line $lines {
				$canvas create line [expr [lindex $line 0] + $xpos]  [expr  [lindex $line 1] + $ypos] [expr [lindex $line 0] + [lindex $line 2] + $xpos] [expr [lindex $line 1] + $ypos] -fill [lindex $line 3] -tags [list uline_$nicktag $nicktag uline]
			}
		#}	
		$canvas lower uline_$nicktag $nicktag
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
			moveBGimage $canvas
#			$canvas coords backgroundimage 0 [expr int([expr [lindex [$canvas yview] 0] * $canvaslength])]
		}
	}


	proc createNicknameArray {} {
		global nicknameArray

		array set nicknameArray { }	

		set userList [::MSN::sortedContactList]
		foreach user $userList {
			set usernick "[::abook::getDisplayNick $user]"
			set nicknameArray("$user") "[::smiley::parseMessageToList $usernick 1]"
		}

#TODO: plugin-event for aMSN plus for example
		set evpar(array) nicknameArray
		::plugins::PostEvent NickArrayCreated evpar

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

			::guiContactList::drawList $canvas
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
					if {$grYCoord <= [expr $iconYCoord + 5]} {
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
#TODO:	* This redrawing should be deleted once the right events are set as the event will know when a group is changed and we don't want to redraw twice !
			after 1000 ::guiContactList::drawList $canvas

			} else {
				status_log "! Can't move $email from \"$oldgrId\" to \"$newgrId\""
				::guiContactList::drawList $canvas
			}
		}
		set OnTheMove 0
		#remove those vars as they're not in use anymore
		unset OldX
		unset OldY
	}



	proc getEmailFromTag { tag } {
		set pos [string first _ $tag]
		set email [string range $tag 0 [expr $pos -1]]
	return $email
	}

	proc getGrIdFromTag { tag } {
		set pos [string first _ $tag]
		set grId [string range $tag [expr $pos + 1] end]
	return $grId
	}

}

