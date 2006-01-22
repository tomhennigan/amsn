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
		set topbgimg [image create photo -file background_top.png]
		set mypicbgimg [image create photo -file mypicbg.png]
		set mypicoverlayimg [image create photo -file mypicoverlay.png]
		set listbgimg [image create photo -file background_list.png]
		set groupbgimg [image create photo -file background_group.png]
		set selectbgimg [image create photo -file background_selected.png]
		set expandimg [image create photo -file expand.png]
		set contractimg [image create photo -file contract.png]
		set buddyimg [image create photo -file buddy.png]

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
	option -listpadx -default 5
	option -listpady -default 5
	option -topborder -default {12 12 2 12}
	option -listborder -default {20 20 20 20}
	option -groupbgborder -default { 5 5 5 5 }
	option -ipadx -default 5
	option -ipady -default 5
	option -grouppadx -default 5
	option -grouppady -default 5
	option -groupipadx -default 5
	option -groupipady -default 5
	option -buddypadx -default 2
	option -buddypady -default 2
	option -contractpadx -default 2
	option -contractpady -default 2
	option -expandpadx -default 2
	option -expandpady -default 2

	variable groups

	variable topbgid
	variable listbgid
	variable selectbgid
	variable mypicid
	variable mypicbgid
	variable mypicoverlayid
	variable mynickid
	variable mypsmid
	variable mymusicid
	variable mystateid

	variable nick

	variable groupbg
	variable groupbgid
	variable toggleid
	variable headid
	variable buddyid
	variable nickid
	variable psmid
	variable musicid
	variable stateid

	variable selectid

	variable selected

	variable dragX
	variable dragY
	variable dragXOffset
	variable dragYOffset

	variable afterid

	variable me
	variable cl

	option -grouporder

	constructor { args } {
		# Create canvases
		install top using canvas $self.top -bd 0 -highlightthickness 0 -insertontime 0 -height 100
		install toolbar using canvas $self.toolbar -bd 0 -highlightthickness 0 -insertontime 0
		install list using canvas $self.list -bd 0 -highlightthickness 0 -insertontime 0 -yscrollcommand "$self.listscroll set"
		# Create list scrollbar
		install listscrollbar using scrollbar $self.listscroll -command "$self Yview"

		# Create background images
		# Top (my nick & status etc)
		install topbg using scalable-bg $top.bg -source $topbgimg \
			-n [lindex $options(-topborder) 0] -e [lindex $options(-topborder) 1] \
			-s [lindex $options(-listborder) 2] -w [lindex $options(-topborder) 3] \
			-resizemethod scale
		# List (where contacts go!)
		install listbg using scalable-bg $list.bg -source $listbgimg \
			-n [lindex $options(-listborder) 0] -e [lindex $options(-listborder) 1] \
			-s [lindex $options(-listborder) 2] -w [lindex $options(-listborder) 3] \
			-resizemethod scale
		# Select (for showing a contact is selected)
		install selectbg using scalable-bg $list.selectbg -source $selectbgimg \
			-n [lindex $options(-listborder) 0] -e [lindex $options(-listborder) 1] \
			-s [lindex $options(-listborder) 2] -w [lindex $options(-listborder) 3] \
			-resizemethod scale
		# Create them on their canvases
		set topbgid [$top create image 0 0 -anchor nw -image [$topbg name]]
		set listbgid [$list create image 0 0 -anchor nw -image [$listbg name]]
		set selectbgid [$list create image 0 0 -anchor nw -image [$selectbg name] -state hidden]

		# Clicking on the list background should deselect the currently selected contact
		$list bind $listbgid <ButtonPress-1> "$self SelectContact none"

		# Pack the canvases and scrollbar
		pack $top -side top -anchor nw -expand false -fill both -padx $options(-toppadx) -pady $options(-toppady)
		pack $list $listscrollbar -side left -anchor nw -expand true -fill both -padx $options(-listpadx) -pady $options(-listpady)
		

		# Bind the canvases
		bind $top <Configure> "$self Config top %w %h"
		bind $list <Configure> "$self Config list %w %h"

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

		# Arrays to store nicknames, psms, music and states in (for the truncation procs to refer to)
		array set nick {{} {}}
		array set psm {{} {}}
		array set music {{} {}}
		array set state {{} {}}

		# Arrays to store initial drag positions for contacts
		array set dragX {{} {}}
		array set dragY {{} {}}

		# Afterid arrays. These are very important for speed! Because we bind to the <Configure> event,
		# we will get a lot of resize actions (especially on scalable-bgs) when the user resizes the window.
		# To stop this slowing us down, we do all resize and sort (and a few other eg truncate) actions with a:
		# after cancel $afterid($Action)
		# set afterid(Action) [after 1 "$doAction"]
		# So that we only do the last action called.
		array set afterid {sort.top {} sort.list {} config.top {} config.list {} trunc_me {} trunc_contacts {}}

		# No contacts selected yet..
		set selected none

		# Create container groups for top and list (these will sort/arrange the stuff inside them)
		set me $self.me
		set cl $self.cl
		contentmanager add container $me -orient horizontal
		contentmanager add container $cl -orient vertical
		contentmanager add group $cl nogroup

		# Draw the top stuff (My pic, nick, psm, music, state etc)
		$self DrawMe
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
		tk_messageBox -message "Successfully added group '$name'" -type ok
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

	method contactAdded { groupid id {name {}} {psm {}} {music {}} {state {}} } {
		if { [string equal $groupid {}] } {
			set groupid "nogroup"
		}
		$self AddContact $groupid $id $name $psm $music $state
		tk_messageBox -message "Successfully added contact '$id'" -type ok
	}

	method contactAddFailed { } {
		
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

	method contactCopiedTo { } {
		
	}

	method contactCopyFailed { } {
		
	}

	method contactMovedTo { } {
		
	}

	method contactMoveFailed { } {
		
	}

	method contactChangeNick { groupid id newnick } {
		$self ChangeContactNick $groupid $id $newnick
	}

	method contactChangePSM { groupid id newpsm } {
		$self ChangeContactPSM $groupid $id $newpsm
	}

	method contactChangeMusic { groupid id newmusic } {
		$self ChangeContactMusic $groupid $id $newmusic
	}

	method contactChangeState { groupid id newstate } {
		$self ChangeContactState $groupid $id $newstate
	}

	# o------------------------------------------------------------------------------------------------------------------------
	#  Methods to carry out GUI actions
	# o------------------------------------------------------------------------------------------------------------------------
	method DrawMe { } {
		# Create the canvas items
		set mypicbgid [$top create image 0 0 -anchor nw -image $mypicbgimg]
		set mypicoverlayid [$top create image 0 0 -anchor nw -image $mypicoverlayimg]
		set mypicid [$top create image 0 0 -anchor nw -image [image create photo -file dp.png]]
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

	method AddGroup { groupid name } {
		# Background image
		set groupbg($groupid) [scalable-bg $groupid.bg -source $groupbgimg -n [lindex $options(-groupbgborder) 0] -e [lindex $options(-groupbgborder) 1] -s [lindex $options(-groupbgborder) 2] -w [lindex $options(-groupbgborder) 3] -resizemethod scale]
		set groupbgid($groupid) [$list create image 0 0 -anchor nw -image [$groupbg($groupid) name]]
		# Heading
		set toggleid($groupid) [$list create image 0 0 -anchor nw -image $contractimg]
		set headid($groupid) [$list create text 0 0 -anchor nw -text $name]
		contentmanager add group $cl $groupid -widget $list -padx $options(-grouppadx) -pady $options(-grouppady) -ipadx $options(-groupipadx) -ipady $options(-groupipady)
		contentmanager add group $cl $groupid head -widget $list -orient horizontal -omnipresent yes
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
		$list delete $toggleid($groupid)
		$list delete $headid($groupid)
		set index [lsearch $groups $groupid]
		set list1 [lrange $groups 0 [expr {$index - 1}]]
		set list2 [lrange $groups [expr {$index + 1}] end]
		set groups [concat $list1 $list2]
		contentmanager delete $cl $groupid
		$self sort list
	}

	method AddContact { groupid id {name {}} {psm {}} {music {}} {state {}} } {
		set buddyid($groupid.$id) [$list create image 0 0 -anchor nw -image $buddyimg -tags buddy]
		set nickid($groupid.$id) [$list create text 0 0 -anchor nw -text $name -font $nickfont -fill $nickcol -tags nick]
		set psmid($groupid.$id) [$list create text 0 0 -anchor nw -text $psm -font $psmfont -fill $psmcol -tags psm]
		set stateid($groupid.$id) [$list create text 0 0 -anchor nw -text $state -font $statefont -fill $statecol -tags state]

		# Store the nick in array
		set nick($nickid($groupid.$id)) $name

		contentmanager add group $cl $groupid $id -widget $list -orient horizontal -padx $options(-buddypadx) -pady $options(-buddypady) -ipadx 0 -ipady 5
		contentmanager add group $cl $groupid $id icon -widget $list
		contentmanager add group $cl $groupid $id info -widget $list
		contentmanager add element $cl $groupid $id icon icon -widget $list -tag $buddyid($groupid.$id)
		contentmanager add element $cl $groupid $id info nick -widget $list -tag $nickid($groupid.$id)
		contentmanager add element $cl $groupid $id info psm -widget $list -tag $psmid($groupid.$id)
		contentmanager add element $cl $groupid $id info state -widget $list -tag $stateid($groupid.$id)

		contentmanager bind $cl $groupid $id <ButtonPress-1> "$self SelectContact $groupid $id"

		$self sort list
	}

	method ChangeContactNick { groupid id newnick } {
		$list itemconfigure $nickid($groupid.$id) -text $newnick
		# Store the new nick in array
		set nick($nickid($groupid.$id)) $newnick
	}

	method ChangeContactPSM { groupid id newpsm } {
		$list itemconfigure $psmid($groupid.$id) -text $newpsm
		# Store the new psm in array
		set psm($psmid($groupid.$id)) $newpsm
	}

	method ChangeContactMusic { groupid id newmusic } {
		$list itemconfigure $musicid($groupid.$id) -text $newmusic
		# Store the new music in array
		set music($musicid($groupid.$id)) $newmusic
	}

	method ChangeContactState { groupid id newstate } {
		$list itemconfigure $stateid($groupid.$id) -text $newstate
		# Store the new state in array
		set state($stateid($groupid.$id)) $newstate
	}

	method DeleteContact { groupid id } {
		contentmanager delete $cl $groupid $id
		foreach tag "$buddyid($groupid.$id) $nickid($groupid.$id) $psmid($groupid.$id) $stateid($groupid.$id)" {
			$list delete $tag
		}
		$self sort list
	}

	method BlockContact { groupid id } {
		
	}

	method UnBlockContact { groupid id } {
		
	}

	method CopyContact { groupid id groupid2 } {
		
	}

	method dragStart { groupid id x y } {
		set x [$list canvasx $x]
		set y [$list canvasy $y]
		set itemcoords [contentmanager getcoords $cl $groupid $id]
		set itemx [lindex $itemcoords 0]
		set itemy [lindex $itemcoords 1]
		set dx [expr {$x - $itemx}]
		set dy [expr {$y - $itemy}]
		set dragXOffset($groupid.$id) $dx
		set dragYOffset($groupid.$id) $dy
		set dragX($groupid.$id) [expr {$x - $dx}]
		set dragY($groupid.$id) [expr {$y - $dy}]
	}

	method dragMotion { groupid id x y } {
		set x [expr {[$list canvasx $x] - $dragXOffset($groupid.$id)}]
		set y [expr {[$list canvasy $y] - $dragYOffset($groupid.$id)}]
		set dx [string trimleft [expr {$x - $dragX($groupid.$id)}] "-"]
		set dy [string trimleft [expr {$y - $dragY($groupid.$id)}] "-"]
		if { $dx > 5 || $dy > 5 } {
			contentmanager coords $cl $groupid $id $x $y
		}
	}

	method dragStop { groupid id x y } {
		foreach group $groups {
			set groupcoords [contentmanager getcoords $cl $group]
			set groupx [lindex $groupcoords 0]
			set groupy [lindex $groupcoords 1]
			set groupwidth [contentmanager cget $cl $group -width]
			set groupheight [contentmanager cget $cl $group -height]
			if { $y >= $groupy && $y <= [expr {$groupy + $groupheight}] } {
				# Events::fire guiMovedContact $id $groupid $group
				return
			}
		}
	}

	method toggle { groupid } {
		contentmanager toggle $cl $groupid
		if { [string equal [contentmanager cget $cl $groupid -state] "normal"] } {
			if { [string first $groupid. $selected] != -1 } {
				$list itemconfigure $selectbgid -state normal
			}
			$list itemconfigure $toggleid($groupid) -image $contractimg
		} else {
			if { [string first $groupid. $selected] != -1 } {
				$list itemconfigure $selectbgid -state hidden
			}
			$list itemconfigure $toggleid($groupid) -image $expandimg
		}
		# Sort the group recursively then sort the contactlist at level 0.
		# (It's faster to recursively sort the group then sort the cl at level 0 than just recursively sort cl)
		contentmanager sort $cl $groupid r
		$self sort list 0
	}

	method SelectContact { args } {
		set groupid [lindex $args 0]
		if { [string equal $groupid "none"] } {
			set selected none
			$list itemconfigure $selectbgid -state hidden
			return
		}
		set id [lindex $args 1]
		if { [string equal $selected "none"] } {
			set selected $groupid.$id
			$selectbg configure -width [$self CalculateSelectWidth]
		}
		set selected $groupid.$id
		set x 7;#[lindex $options(-listborder) 0]
		set y [lindex [contentmanager getcoords $cl $groupid $id] 1]
		$list raise $selectbgid $groupbgid($groupid)
		$list coords $selectbgid $x $y
		$list itemconfigure $selectbgid -state normal
		$selectbg configure -height [contentmanager cget $cl $groupid $id -height]
	}

	method register { groupid {index ""} } {
		if { [string equal $index ""] } {
			lappend groups $groupid
		} else {
			set items [linsert $groups $index $groupid]
		}
	}

	method unregister { groupid } {
		set index [lsearch $groups $groupid]
		set list1 [lrange $groups 0 [expr {$index - 1}]]
		set list2 [lrange $groups [expr {$index + 1}] end]
		set groups [concat $list1 $list2]
	}

	method sort { component {level r} } {
		after cancel $afterid(sort.$component)
		set afterid(sort.$component) [after 1 "$self Sort $component $level"]
	}

	method Sort { component {level r} } {
		switch $component {
			top {
				contentmanager sort $me $level
				# Position displaypic bg and overlay
				set xy [$top coords $mypicid]
				eval $top coords $mypicbgid $xy
				eval $top coords $mypicoverlayid $xy
				$top raise $mypicoverlayid
			}
			list {
				contentmanager sort $cl $level
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
					eval $list coords $groupbgid($groupid) [contentmanager getcoords $cl $groupid]
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
		switch $component {
			top {
				$topbg configure -width $width -height $height
			}
			list {
				$listbg configure -width $width -height $height
				$selectbg configure -width [$self CalculateSelectWidth]
			}
		}
		incr width -[lindex $options(-listborder) 2]
		after cancel $afterid(trunc_me)
		set afterid(trunc_me) [after 1 "$self TruncateMyNick $width"]
		after cancel $afterid(trunc_contacts)
		set afterid(trunc_contacts) [after 1 "$self TruncateContactsNicks $width"]

		# Resize group backgrounds
		foreach groupid $groups {
			$self SetGroupBgWidth $groupid $width
		}
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
		$top itemconfigure $mynickid -text [$self CalcTruncatedString $mynickfont {Hobbes - All the colours of the rainbow!!!} [expr {$width - [lindex [$top coords $mynickid] 0]}]]
	}

	method TruncateContactsNicks { width } {
		foreach tag [$list find withtag nick] {
			$list itemconfigure $tag -text [$self CalcTruncatedString $nickfont $nick($tag) [expr {$width - [lindex [$list coords $tag] 0]}]]
		}
	}

	method CalcTruncatedString { font str width } {
		for { set i 0 } { 1 } { incr i 1 } {
			set strw [font measure $font -displayof $list [string range $str 0 $i]]
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
}
