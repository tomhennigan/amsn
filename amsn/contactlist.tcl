package require contentmanager

snit::widget contactlist {

	typevariable topbgimg
	typevariable mypicbgimg
	typevariable mypicoverlayimg
	typevariable listbgimg
	typevariable groupbgimg
	typevariable selectbgimg
	typevariable expandimg
	typevariable contractimg
	typevariable buddyimg

	typevariable mynickfont
	typevariable mypsmfont
	typevariable mymusicfont
	typevariable mystatefont
	typevariable nickfont
	typevariable psmfont
	typevariable musicfont
	typevariable statefont

	typevariable mynickcol
	typevariable mypsmcol
	typevariable mymusiccol
	typevariable mystatecol
	typevariable nickcol
	typevariable psmcol
	typevariable musiccol
	typevariable statecol

	typeconstructor {
		# Load images
		::skin::setPixmap topbgimg background_top.png
		::skin::setPixmap mypicbgimg mypicbg.png
		::skin::setPixmap mypicoverlayimg mypicoverlay.png
		::skin::setPixmap listbgimg background_list.png
		::skin::setPixmap groupbgimg background_group.png
		::skin::setPixmap selectbgimg background_selected.png
		::skin::setPixmap expandimg expand.png
		::skin::setPixmap contractimg contract.png
		::skin::setPixmap buddyimg buddy.png

		# Set fonts
		set mynickfont [font create -family helvetica -size 12 -weight bold]
		set mypsmfont [font create -family helvetica -size 12 -weight bold]
		set mymusicfont [font create -family helvetica -size 12 -weight bold]
		set mystatefont [font create -family helvetica -size 12 -weight bold]
		set nickfont [font create -family helvetica -size 11 -weight bold]
		set psmfont [font create -family helvetica -size 11 -weight bold -slant italic]
		set musicfont [font create -family helvetica -size 11 -weight bold]
		set statefont [font create -family helvetica -size 11 -weight bold]

		# Set colours
		# Top colours
		set mynickcol darkblue
		set mypsmcol #0000ee
		set mymusiccol purple
		set mystatecol darkgreen
		# List colours
		set nickcol darkblue
		set psmcol #0000ee
		set musiccol purple
		set statecol darkgreen
	}

	hulltype frame

	component top
	component topbg
	component toolbar
	component toolbarbg
	component list
	component listbg
	component listscrollbar
	component selectbg

	option -width -default 0
	option -height -default 0
	option -toppadx -default 5
	option -toppady -default 5
	option -topipadx -default 5
	option -topipady -default 5
	option -listpadx -default 5
	option -listpady -default 5
	option -topborder -default {12 12 12 12}
	option -listborder -default {20 20 20 20}
	option -groupbgborder -default {5 5 5 5}
	option -selectborder -default {5 5 5 5}
	option -ipadx -default 0
	option -ipady -default 0
	option -grouppadx -default 5
	option -grouppady -default 5
	option -groupipadx -default 5
	option -groupipady -default 5
	option -buddypadx -default 2
	option -buddypady -default 2
	option -buddyipadx -default 5
	option -buddyipady -default 5
	option -contractpadx -default 2
	option -contractpady -default 2
	option -expandpadx -default 2
	option -expandpady -default 2

	option -groupmode -default groups -configuremethod SetGroupMode

	variable groups {}

	# Variables to store the dimensions of our list
	variable listwidth
	variable listheight

	# Variables ending in 'id' denote canvas item ids
	variable topbgid
	variable mypicid
	variable mypicbgid
	variable mypicoverlayid
	variable mynickid
	variable mypsmid
	variable mymusicid
	variable mystateid
	variable listbgid
	variable selectbgid
	variable groupbgid
	variable toggleid
	variable headid
	variable buddyid
	variable nickid
	variable psmid
	variable musicid
	variable stateid
	variable statusiconid

	# Arrays to store contacts' info
	variable nick
	variable psm
	variable music
	variable state
	variable tags

	# Array to store name of group backgrounds
	variable groupbg

	# Variable to store selected contact
	variable selected

	variable dragX
	variable dragY
	variable dragXOffset
	variable dragYOffset

	# Array used for speeding up batch processing (using after and after cancel, see sort methid)
	variable afterid

	# Names for top-level contentmanager groups on top canvas and list canvas
	variable me
	variable cl

	constructor { args } {
		bindtags $self "Frame . all"
		# Create canvases
		install top using canvas $self.top -bd 0 -highlightthickness 0 -insertontime 0 -height 100
		install toolbar using canvas $self.toolbar -bd 0 -highlightthickness 0 -insertontime 0
		install list using canvas $self.list -bd 0 -highlightthickness 0 -insertontime 0 -yscrollcommand "$self.listscroll set"
		# Create list scrollbar
		install listscrollbar using scrollbar $self.listscroll -command "$self Yview"

		# Create background images
		# Top (my nick & status etc)
		install topbg using scalable-bg $top.bg -source [::skin::loadPixmap topbgimg] \
			-border $options(-topborder) \
			-resizemethod tile
		# List (where contacts go!)
		install listbg using scalable-bg $list.bg -source [::skin::loadPixmap listbgimg] \
			-border $options(-listborder) \
			-resizemethod tile
		# Select (for showing a contact is selected)
		install selectbg using scalable-bg $list.selectbg -source [::skin::loadPixmap selectbgimg] \
			-border $options(-selectborder) \
			-resizemethod tile
		# Create them on their canvases
		set topbgid [$top create image 0 0 -anchor nw -image [$topbg name]]
		set listbgid [$list create image 0 0 -anchor nw -image [$listbg name]]
		set selectbgid [$list create image 0 0 -anchor nw -image [$selectbg name] -state hidden]

		# Clicking on the list background should deselect the currently selected contact
		$list bind $listbgid <ButtonPress-1> "$self SelectContact none"

		# Pack the canvases and scrollbar
		pack $top -side top -anchor nw -expand false -fill x -padx $options(-toppadx) -pady $options(-toppady)
		pack $list -side left -anchor nw -expand true -fill both -padx $options(-listpadx) -pady $options(-listpady)
		pack $listscrollbar -after $list -expand true -fill y

		# Bind the canvases
		bindtags $top "Canvas ContactlistTop . all"
		bindtags $list "Canvas Contactlist . all"

		# Apply arguments
		$self configurelist $args

		# Create empty canvas id variables/arrays
		array set groupbg {{} {}}
		array set groupbgid {{} {}}
		array set toggleid {{} {}}
		array set headid {{} {}}
		array set buddyid {{} {}}
		array set nickid {{} {}}
		array set psmid {{} {}}
		array set musicid {{} {}}
		array set stateid {{} {}}

		# Arrays to store nicknames, psms, music and states in (for the truncation and other methods to refer to)
		array set nick {{} {}}
		array set psm {{} {}}
		array set music {{} {}}
		array set state {{} {}}
		array set tags {{} {}}

		# Arrays to store initial drag positions for contacts
		array set dragX {{} {}}
		array set dragY {{} {}}

		# Afterid arrays. These are very important for speed! Because we bind to the <Configure> event,
		# we will get a lot of resize actions (especially on scalable-bgs) when the user resizes the window.
		# To stop this slowing us down, we do all resize and sort (and a few other eg truncate) actions with a:
		# after cancel $afterid($Action)
		# set afterid(Action) [after 1 "$doAction"]
		# So that we only do the last action called.
		array set afterid {
			sort.top {}
			sort.list {}
			config.top {}
			config.list {}
			trunc_me {}
			trunc_contacts {}
			groupbg {}
			filter {}
		}

		# No contacts selected yet..
		set selected none

		# Initial dimensions are assumed to be zero
		set listwidth 0
		set listheight 0

		# Create container groups for top and list (these will sort/arrange the stuff inside them)
		set me $self.me
		set cl $self.cl
		contentmanager add group $me -orient horizontal -widget $top
		contentmanager add group $cl -orient vertical -ipadx $options(-ipadx) -ipady $options(-ipady) -widget $list

		$self AddGroup search "Search results"
		$self HideGroup search
		pack [label $self.searchlabel -anchor w -text "Search:"] [entry $self.search -bg white] -after $top -anchor w -expand false -fill x -side top
		bind $self.search <Return> "$self SubmitSearch"

		$self AddGroup nogroup nogroup

		$self AddGroup online Online
		$self AddGroup offline Offline

		# Draw the top stuff (My pic, nick, psm, music, state etc)
		$self DrawMe
		$self registerForEvents

		$self configurelist $args
	}

	method registerForEvents { } {
		::Event::registerEvent groupAdded all $self
		::Event::registerEvent groupDeleted all $self
		::Event::registerEvent groupRenamed all $self
		::Event::registerEvent contactAdded all $self
		::Event::registerEvent contactDeleted all $self
		::Event::registerEvent contactChangeNick all $self
		::Event::registerEvent contactChangePSM all $self
		::Event::registerEvent contactChangeState all $self
	}

	# o------------------------------------------------------------------------------------------------------------------------
	#  Methods to deal with protocol events
	# o------------------------------------------------------------------------------------------------------------------------
	method contactlistLoaded { } {

	}

	method groupAdded { groupid {name {}} } {
		if { [string equal $name {}] } {
			set name $groupid
		}
		$self AddGroup $groupid $name
		#tk_messageBox -message "Successfully added group '$name'" -type ok
	}

	method groupAddFailed { } {
		
	}

	method groupDeleted { groupid } {
		$self DeleteGroup $groupid
	}

	method groupDeleteFailed { } {
		
	}

	method groupRenamed { groupid newname } {
		$self RenameGroup $groupid $newname
	}

	method groupRenameFailed { } {
		
	}

	method contactAdded { groupid id {_nick {}} {_psm {}} {_music {}} {_state {}} } {
		if { [string equal $groupid {}] } {
			set groupid "nogroup"
		}
		$self AddContact $groupid $id $_nick $_psm $_music $_state
		#tk_messageBox -message "Successfully added contact '$id'" -type ok
	}

	method contactAddFailed { id } {
		
	}

	method contactDeleted { groupid id } {
		$self DeleteContact $groupid $id
	}

	method contactDeleteFailed { } {
		
	}

	method contactBlocked { } {
		
	}

	method contactBlockFailed { } {
		
	}

	method contactUnBlocked { } {
		
	}

	method contactUnBlockFailed { } {
		
	}

	method contactCopiedTo { groupid id groupid2 } {
		$self CopyContact $groupid $id $groupid2
	}

	method contactCopyFailed { } {
		
	}

	method contactMovedTo { } {
		
	}

	method contactMoveFailed { } {
		
	}

	method contactChangeNick { id newnick } {
		foreach groupid $groups {
			$self ChangeContactNick $groupid $id $newnick
		}
	}

	method contactChangePSM { id newpsm } {
		foreach groupid $groups {
			$self ChangeContactPSM $groupid $id $newpsm
		}
	}

	method contactChangeMusic { id newmusic } {
		foreach groupid $groups {
			$self ChangeContactMusic $groupid $id $newmusic
		}
	}

	method contactChangeState { id newstate } {
		foreach groupid $groups {
			$self ChangeContactState $groupid $id $newstate
		}
	}

	method contactChangePic { id newpic } {
		foreach groupid $groups {
			$self ChangeContactPic $groupid $id $newpic
		}
	}

	# o------------------------------------------------------------------------------------------------------------------------
	#  Methods to carry out GUI actions
	# o------------------------------------------------------------------------------------------------------------------------
	method ContactInGroup { id groupid } {
		set contacts [contentmanager children $cl $groupid]
		if { [lsearch $contacts $id] != -1 } {
			return 1
		} else {
			return 0
		}
	}

	method DrawMe { } {
		# Create the canvas items
		set mypicbgid [$top create image 0 0 -anchor nw -image [::skin::loadPixmap mypicbgimg]]
		set mypicoverlayid [$top create image 0 0 -anchor nw -image [::skin::loadPixmap mypicoverlayimg]]
		load_my_smaller_pic
		set mypicid [$top create image 0 0 -anchor nw -image my_pic_small]
		set mynickid [$top create text 0 0 -anchor nw -fill $mynickcol -font $mynickfont -text "Hobbes - all the colours of the rainbow!!!"]
		set mypsmid [$top create text 0 0 -anchor nw -fill $mypsmcol -font $mypsmfont -text "http://amsn.sf.net/"]
		set mymusicid [$top create text 0 0 -anchor nw -fill $mymusiccol -font $mymusicfont -text "Kate Bush - Aerial tal"]
		set mystateid [$top create text 0 0 -anchor nw -fill $mystatecol -font $mystatefont -text "Online"]
		# Add them to the layout
		contentmanager add group $me icon -widget $top -padx 5 -pady 5
		contentmanager add element $me icon icon -widget $top -tag $mypicid
		contentmanager add group $me info -widget $top -padx 5 -pady 5
		contentmanager add element $me info nick -widget $top -tag $mynickid
		contentmanager add element $me info psm -widget $top -tag $mypsmid
		contentmanager add element $me info music -widget $top -tag $mymusicid
		contentmanager add element $me info state -widget $top -tag $mystateid
		
		$self sort top
	}

	method SetGroupMode { option value } {
		set options(-groupmode) $value
		if { ![info exists cl] } {
			return $value
		}
		switch $value {
			status {
				foreach groupid $groups {
					if { ![string equal $groupid online] && ![string equal $groupid offline] } {
						$self HideGroup $groupid
					}
				}
				$self ShowGroup online
				$self ShowGroup offline
			}
			groups {
				foreach groupid $groups {
					if {
						![string equal $groupid online] && \
						![string equal $groupid offline] && \
						![string equal $groupid search]
					} {
						$self ShowGroup $groupid
					}
				}
				$self HideGroup online
				$self HideGroup offline
			}
			hybrid {
				foreach groupid $groups {
					if { 
						![string equal $groupid online] && \
						![string equal $groupid search]
					} {
						$self ShowGroup $groupid
					}
				}
				$self HideGroup online
			}
		}
	}

	method AddGroup { groupid name } {
		# Background image
		set groupbg($groupid) [scalable-bg $groupid.bg \
			-source [::skin::loadPixmap groupbgimg] \
			-border $options(-groupbgborder) \
			-resizemethod tile \
			-width [expr {$listwidth - (2 * $options(-ipadx)) - (2 * $options(-grouppadx))}]]
		# Background image canvas item
		set groupbgid($groupid) [$list create image 0 0 -anchor nw -image [$groupbg($groupid) name]]
		# Heading canvas items
		set toggleid($groupid) [$list create image 0 0 -anchor nw -image [::skin::loadPixmap contractimg]]
		
		set headid($groupid) [$list create text 0 0 -anchor nw -text $name]

		# Create groups and elements with contentmanager
		# Main group
		contentmanager add group $cl $groupid -widget $list -padx $options(-grouppadx) -pady $options(-grouppady) -ipadx $options(-groupipadx) -ipady $options(-groupipady)
		contentmanager add attachment $cl $groupid bg -widget $list -tag $groupbgid($groupid) -omnipresent yes
		# Heading group
		contentmanager add group $cl $groupid head -widget $list -orient horizontal -omnipresent yes
		# Heading elements
		contentmanager add element $cl $groupid head toggle -widget $list -tag $toggleid($groupid)
		contentmanager add element $cl $groupid head text -widget $list -tag $headid($groupid)

		# Bind heading
		contentmanager bind $cl $groupid head <ButtonPress-1> "$self toggle $groupid"

		# Store the group id in list
		lappend groups $groupid

		# Sort the cl
		$self sort list
	}

	method RenameGroup { groupid newname } {
		$list itemconfigure $headid($groupid) -text $newname
		$self sort list
	}

	method DeleteGroup { groupid } {
		# Delete group's heading canvas items
		$list delete $toggleid($groupid)
		$list delete $headid($groupid)
		# Find group in list of groups
		set index [lsearch $groups $groupid]
		# Get the groups before and after this group...
		set list1 [lrange $groups 0 [expr {$index - 1}]]
		set list2 [lrange $groups [expr {$index + 1}] end]
		# ...and join them together to make the new list
		set groups [concat $list1 $list2]
		# Remove the group from the contentmanager
		contentmanager delete $cl $groupid
		# Sort the list
		$self sort list
	}

	method HideGroup { groupid } {
		contentmanager hide $cl $groupid -force 1
		$list itemconfigure $groupbgid($groupid) -state hidden
		contentmanager sort $cl $groupid -level r
		$self sort list 0
	}

	method ShowGroup { groupid } {
		contentmanager show $cl $groupid
		contentmanager show $cl $groupid head
		$list itemconfigure $groupbgid($groupid) -state normal
		contentmanager sort $cl $groupid -level r
		$self sort list 0
	}

	method SubmitSearch { } {
		set pattern [$self.search get]
		after cancel $afterid(filter)
		set afterid(filter) [after 100 "$self FilterContacts $pattern"]
	}

	method FilterContacts { {pattern {}} } {
		# Empty search pattern
		if { [string equal $pattern {}] } {
			foreach groupid $groups {
				if { [string first "hidden" [contentmanager cget $cl $groupid -state]] == -1 } {
					$self ShowGroup $groupid
				}
			}
		# Non-empty search pattern
		} else {
			set results [$self SearchContacts $pattern]
			puts "results $results"
			set matches [lindex $results 0]
			set nonmatches [lindex $results 1]
			foreach { groupid id } $matches {
				$self ShowContact $groupid $id
			}
			foreach { groupid id } $nonmatches {
				$self HideContact $groupid $id
			}
		}
	}

	method SearchContacts { pattern } {
		set matches {}
		set nonmatches {}
		foreach groupid $groups {
			foreach id [contentmanager children $cl $groupid] {
				if { [string equal $id head] } {
					continue
				}
				if {
					[string first $pattern $nick($groupid.$id)] != -1 || \
					[string first $pattern $psm($groupid.$id)] != -1 || \
					[lsearch $tags($groupid.$id) $pattern] != -1
				} {
					lappend matches $groupid $id
				} else {
					lappend nonmatches $groupid $id
				}
			}
		}
		return [list $matches $nonmatches]
	}

	method ShowContact { groupid id } {
		if { [string first "hidden" [contentmanager cget $cl $groupid -state]] != -1 } {
			return
		}
		contentmanager show $cl $groupid $id
		after cancel "contentmanager sort $cl $groupid -level 0"
		after 1 "contentmanager sort $cl $groupid -level 0"
		$self sort list 0
	}

	method HideContact { groupid id } {
		contentmanager hide $cl $groupid $id -force yes
		after cancel "contentmanager sort $cl $groupid -level 0"
		after 1 "contentmanager sort $cl $groupid -level 0"
		$self sort list 0
	}

	method AddContact { groupid id {nicktext {}} {psmtext {}} {musictext {}} {statetext {}} } {
		if { [$self ContactInGroup $id $groupid] } {
			return {}
		}
		# Create canvas items (pic, nick, psm, music, state)
		set img [image create photo]
		$img copy [::skin::getDisplayPicture $id]
		::picture::ResizeWithRatio $img 32 32
		set buddyid($groupid.$id) [$list create image 0 0 -anchor nw -image $img]
		set nickid($groupid.$id) [$list create text 0 0 -anchor nw -text $nicktext -font $nickfont -fill $nickcol]
		set psmid($groupid.$id) [$list create text 0 0 -anchor nw -text $psmtext -font $psmfont -fill $psmcol]
		set stateid($groupid.$id) [$list create text 0 0 -anchor nw -text [$self StatusCodeToText $statetext] -font $statefont -fill $statecol]
		set statusiconid($groupid.$id) [$list create image 0 0 -anchor nw -image [$self StatusCodeToImage $statetext]]

		# Store the nick in array
		set nick($groupid.$id) $nicktext
		set psm($groupid.$id) $psmtext
		set music($groupid.$id) $musictext
		set state($groupid.$id) $statetext
		set tags($groupid.$id) $id

		# Create contentmanager objects
		# Main contact group
		contentmanager add group $cl $groupid $id -widget $list -orient horizontal -padx $options(-buddypadx) -pady $options(-buddypady) -ipadx $options(-buddyipadx) -ipady $options(-buddyipadx)
		# Buddy icon group & elements
		contentmanager add group $cl $groupid $id icon -widget $list
		contentmanager add element $cl $groupid $id icon icon -widget $list -tag $buddyid($groupid.$id)
		#contentmanager add element $cl $groupid $id icon status -widget $list -tag $statusiconid($groupid.$id)
		contentmanager add attachment $cl $groupid $id icon status -widget $list -tag $statusiconid($groupid.$id)
		# Information group & elements (nick, psm, etc)
		contentmanager add group $cl $groupid $id info -widget $list
		contentmanager add element $cl $groupid $id info nick -widget $list -tag $nickid($groupid.$id)
		contentmanager add element $cl $groupid $id info psm -widget $list -tag $psmid($groupid.$id)
		contentmanager add element $cl $groupid $id info state -widget $list -tag $stateid($groupid.$id)

		# Bind the contact
		contentmanager bind $cl $groupid $id <ButtonPress-1> "$self SelectContact $groupid $id"

		# Sort the list
		$self sort list
	}

	method ChangeContactNick { groupid id newnick } {
		if { [$self ContactInGroup $id $groupid] } {
			# Change the text of the canvas item
			$list itemconfigure $nickid($groupid.$id) -text $newnick
			# Store the new nick in array
			set nick($groupid.$id) $newnick
		}
	}

	method ChangeContactPSM { groupid id newpsm } {
		if { [$self ContactInGroup $id $groupid] } {
			# Change the text of the canvas item
			$list itemconfigure $psmid($groupid.$id) -text $newpsm
			# Store the new psm in array
			set psm($groupid.$id) $newpsm
		}
	}

	method ChangeContactMusic { groupid id newmusic } {
		if { [$self ContactInGroup $id $groupid] } {
			# Change the text of the canvas item
			$list itemconfigure $musicid($groupid.$id) -text $newmusic
			# Store the new music in array
			set music($groupid.$id) $newmusic
		}
	}

	method ChangeContactState { groupid id newstate } {
		if { [$self ContactInGroup $id $groupid] } {
			# Change the text of the canvas item
			$list itemconfigure $stateid($groupid.$id) -text $newstate
			$list itemconfigure $statusiconid($groupid.$id) -image [$self StatusCodeToImage $newstate]
			# Store the new state in array
			set state($groupid.$id) $newstate
		}
	}

	method ChangeContactPic { groupid id } {
		if { [$self ContactInGroup $id $groupid] } {
			# Change the image of the canvas item
			image delete [$list itemcget $buddyid($groupid.$id)]
			set img [image create photo]
			$img copy [::skin::getDisplayPicture $id]
			::picture::ResizeWithRatio $img 32 32
			$list itemconfigure $buddyid($groupid.$id) -image $img
		}
	}

	method DeleteContact { groupid id } {
		if { [$self ContactInGroup $id $groupid] } {
			# Remove the contact from the contentmanager
			contentmanager delete $cl $groupid $id
			# Delete it's canvas items
			foreach tag "$buddyid($groupid.$id) $nickid($groupid.$id) $psmid($groupid.$id) $stateid($groupid.$id)" {
				$list delete $tag
			}
			# Sort the list
			$self sort list
		}
	}

	method BlockContact { groupid id } {
		
	}

	method UnBlockContact { groupid id } {
		
	}

	method CopyContact { groupid id groupid2 } {
		if { ![$self ContactInGroup $id $groupid] } {
			return {}
		}
		status_log "CopyContact $nick($groupid.$id)"
		$self AddContact $groupid2 $id $nick($groupid.$id) $psm($groupid.$id) $music($groupid.$id) $state($groupid.$id)
	}

	method toggle { groupid } {
		# Toggle the group in contentmanager
		contentmanager toggle $cl $groupid
		# Do something, depending on whether we are showing or hiding the group
		if { [string equal [contentmanager cget $cl $groupid -state] "normal"] } {
			# Showing...
			if { [string first $groupid. $selected] != -1 } {
				# If the currently selected contact is in this group, re-show the selectbg (it will have been hidden when the group was)
				$list itemconfigure $selectbgid -state normal
			}
			# Change the toggle icon to the contract icon
			$list itemconfigure $toggleid($groupid) -image [::skin::loadPixmap contractimg]
		} else {
			# Hiding...
			if { [string first $groupid. $selected] != -1 } {
				# If the currently selected contact is in this group, hide the selectbg
				$list itemconfigure $selectbgid -state hidden
			}
			# Change the toggle icon to the expand icon
			$list itemconfigure $toggleid($groupid) -image [::skin::loadPixmap expandimg]
		}
		# Sort the group recursively then sort the contactlist at level 0.
		# (It's faster to recursively sort the group then sort the cl at level 0 than just recursively sort cl)
		contentmanager sort $cl $groupid -level r
		$self sort list 0
	}

	method SelectContact { args } {
		# Get the group id
		set groupid [lindex $args 0]

		# Have we been called with "none"?
		if { [string equal $groupid "none"] } {
			# Yes, set selected to none, hide the selectbg and return
			set selected none
			$list itemconfigure $selectbgid -state hidden
			return {}
		}

		# Get the contact's id
		set id [lindex $args 1]
		# Was any contact selected before?
		if { [string equal $selected "none"] } {
			# No, so we need to calculate the width of the selectbg
			set selected $groupid.$id
			$selectbg configure -width [$self CalculateSelectWidth]
		}
		# Set selected to this contact
		set selected $groupid.$id
		# Get coords of contact
		set xy [contentmanager getcoords $cl $groupid $id]
		set x [lindex $xy 0]
		set y [lindex $xy 1]
		# Raise selectbg to just above the group background in stacking order
		$list raise $selectbgid $groupbgid($groupid)
		# Place the selectbg
		$list coords $selectbgid $x $y
		# Show it if it isn't already shown
		$list itemconfigure $selectbgid -state normal
		# Set it to the height of the contact
		$selectbg configure -height [contentmanager cget $cl $groupid $id -height]
	}

	method sort { component {level r} } {
		after cancel $afterid(sort.$component)
		set afterid(sort.$component) [after 1 "$self Sort $component $level"]
	}

	method Sort { component {level r} } {
		switch $component {
			top {
				contentmanager sort $me -level $level
				# Position displaypic bg and overlay
				set xy [$top coords $mypicid]
				eval $top coords $mypicbgid $xy
				eval $top coords $mypicoverlayid $xy
				$top raise $mypicoverlayid
			}
			list {
				contentmanager sort $cl -level $level
				# Position selectbg
				if { ![string equal $selected "none"] } {
					set xy [eval contentmanager getcoords $cl $selected]
					set x [lindex $xy 0]
					set y [lindex $xy 1]
					$list coords $selectbgid $x $y
					if { ![string equal $selected "none"] } {
						$selectbg configure -height [eval contentmanager cget $cl $selected -height]
					}
				}

				# Resize group backgrounds
				foreach groupid $groups {
					#eval $list coords $groupbgid($groupid) [contentmanager getcoords $cl $groupid]
					$self SetGroupBgHeight $groupid [contentmanager cget $cl $groupid -height]
				}
				# Set canvas's scrollregion
				$list configure -scrollregion "0 0 0 [contentmanager cget $cl -height]"
			}
		}
	}

	method Config { component width height } {
		after cancel $afterid(config.$component)
		set afterid(config.$component) [after 1 "$self Configure $component $width $height"]
	}

	method Configure { component width height } {
		# Config'ing top or list?
		switch $component {
			top {
				$topbg configure -width $width -height $height
			}
			list {
				$listbg configure -width $width -height $height
				$selectbg configure -width [$self CalculateSelectWidth]
				# Resize group backgrounds
				foreach groupid $groups {
					$self SetGroupBgWidth $groupid [expr {$width - (2 * $options(-ipadx)) - (2 * $options(-grouppadx))}]
				}
				set listwidth $width
				set listheight $height
			}
		}

		# Truncate text items (nicks etc)
		after cancel $afterid(trunc_me)
		set afterid(trunc_me) [after 1 "$self TruncateMyNick $width"]
		after cancel $afterid(trunc_contacts)
		set afterid(trunc_contacts) [after 1 "$self TruncateContactsNicks $width"]
	}

	method Yview { args } {
		eval $list yview $args
		$list coords $listbgid 0 [$list canvasy 0]
	}

	method CalculateSelectWidth { } {
		set winw [winfo width $list]
		if { ![string equal $selected "none"] } {
			set width [expr { $winw - ( 2 * $options(-grouppadx)) - (2 * $options(-groupipadx)) - (2 * $options(-buddypadx))}]
		} else {
			set width 0
		}
		return $width
	}

	method SetGroupBgWidth { groupid width } {
		$groupbg($groupid) configure -width $width
	}

	method SetGroupBgHeight { groupid height } {
		$groupbg($groupid) configure -height $height
	}

	method TruncateMyNick { width } {
		set width [expr {$width - (2 * $options(-topipadx))}]
		$top itemconfigure $mynickid -text [$self CalcTruncatedString $top $mynickfont {Hobbes - All the colours of the rainbow!!!} [expr {$width - [lindex [$top coords $mynickid] 0]}]]
	}

	method TruncateContactsNicks { width } {
		set width [expr {$width - (2 * $options(-ipadx)) - (2 * $options(-grouppadx)) - (2 * $options(-groupipadx)) - (2 * $options(-buddypadx)) - (2 * $options(-buddyipadx))}]
		foreach groupid $groups {
			foreach id [contentmanager children $cl $groupid] {
				if { [string equal $id head] } {
					continue
				}
				set tag $nickid($groupid.$id)
				$list itemconfigure $tag -text [$self CalcTruncatedString $list $nickfont $nick($groupid.$id) [expr {$width - [lindex [$list coords $tag] 0]}]]
			}
		}
	}

	method CalcTruncatedString { w font str width } {
		for { set i 0 } { 1 } { incr i 1 } {
			set strw [font measure $font -displayof $w [string range $str 0 $i]]
			if { $strw >= $width } {
				incr i -3
				set newstr [string range $str 0 $i]...
				break
			} elseif { $i >= [string length $str] } {
				set newstr $str
				break
			}
		}
		return $newstr
	}

	# o------------------------------------------------------------------------------------------------------------------------
	#  Methods to convert state codes to state descriptions and images
	# o------------------------------------------------------------------------------------------------------------------------
	method StatusCodeToText { code } {
		switch $code {
			NLN { return online }
			FLN { return offline }
			AWY { return away }
			BRB { return "be right back" }
			LUN { return "gone to lunch" }
			BSY { return busy }
			PHN { return "on phone" }
			IDL { return "no activity" }

			Offline { return offline }
			default { return {} }
		}
	}

	method StatusCodeToImage { code } {
		switch $code {
			NLN { return [::skin::loadPixmap online] }
			FLN { return [::skin::loadPixmap offline] }
			AWY { return [::skin::loadPixmap away] }
			BRB { return [::skin::loadPixmap away] }
			LUN { return [::skin::loadPixmap away] }
			IDL { return [::skin::loadPixmap away] }
			BSY { return [::skin::loadPixmap busy] }
			PHN { return [::skin::loadPixmap busy] }

			Offline { return [::skin::loadPixmap offline] }
			default { return [::skin::loadPixmap offline] }
		}
	}
}

bind Contactlist <4> {
	[winfo parent %W] Yview scroll -5 units
}
bind Contactlist <5> {
	[winfo parent %W] Yview scroll 5 units
}

bind Contactlist <Configure> {
	[winfo parent %W] Config list %w %h
}

bind ContactlistTop <Configure> {
	[winfo parent %W] Config top %w %h
}

#pack forget .main;source contactlist.tcl;pack [contactlist .cl] -expand true -fill both

proc speedycontacts { } {
	.cl groupAdded grp1
	.cl groupAdded grp2
	.cl groupAdded grp3
	for { set i 0 } { $i < 25 } { incr i 1} {
		.cl contactAdded grp1 $i "test $i" "psm $i" FLN
		.cl contactAdded grp2 $i "test $i" "psm $i" FLN
		.cl contactAdded grp3 $i "test $i" "psm $i" FLN
	}
}