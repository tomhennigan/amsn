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
	component list
	component listbg
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
		install list using canvas $self.list -bd 0 -highlightthickness 0 -insertontime 0

		# Create background images
		install topbg using scalable-bg $top.bg -source $topbgimg \
			-n [lindex $options(-topborder) 0] -e [lindex $options(-topborder) 1] \
			-s [lindex $options(-listborder) 2] -w [lindex $options(-topborder) 3] \
			-resizemethod scale
		install listbg using scalable-bg $list.bg -source $listbgimg \
			-n [lindex $options(-listborder) 0] -e [lindex $options(-listborder) 1] \
			-s [lindex $options(-listborder) 2] -w [lindex $options(-listborder) 3] \
			-resizemethod scale
		install selectbg using scalable-bg $list.selectbg -source $selectbgimg \
			-n [lindex $options(-listborder) 0] -e [lindex $options(-listborder) 1] \
			-s [lindex $options(-listborder) 2] -w [lindex $options(-listborder) 3] \
			-resizemethod scale
		set topbgid [$top create image 0 0 -anchor nw -image [$topbg name]]
		set listbgid [$list create image 0 0 -anchor nw -image [$listbg name]]
		set selectbgid [$list create image 0 0 -anchor nw -image [$selectbg name] -state hidden]

		# Pack them
		pack $top -side top -anchor nw -expand false -fill both -padx $options(-toppadx) -pady $options(-toppady)
		pack $list -side top -anchor nw -expand true -fill both -padx $options(-listpadx) -pady $options(-listpady)

		# Bind them
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

		array set nick {{} {}}
		
		array set dragX {{} {}}
		array set dragY {{} {}}

		array set afterid {sort {} config.top {} config.list {} trunc_me {} trunc_contacts {}}

		set selected none

		# Create container group for list
		#set container c
		#contentmanager add group $self $list -ipadx $options(-ipadx) -ipady $options(-ipady)
		#contentmanager add group $self $top -ipadx $options(-ipadx) -ipady $options(-ipady) -orient horizontal
		set me $self.me
		set cl $self.cl
		contentmanager add container $me -orient horizontal
		contentmanager add container $cl -orient vertical
		contentmanager add group $cl nogroup

		
	}

	# Methods to deal with protocol events
	
	method contactlistLoaded { } {
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

		$self sort
	}

	method groupAdded { id {name {}} } {
		if { [string equal $name {}] } {
			set name $id
		}
		# Background image
		set groupbg($id) [scalable-bg $id.bg -source $groupbgimg -n [lindex $options(-groupbgborder) 0] -e [lindex $options(-groupbgborder) 1] -s [lindex $options(-groupbgborder) 2] -w [lindex $options(-groupbgborder) 3] -resizemethod scale]
		set groupbgid($id) [$list create image 0 0 -anchor nw -image [$groupbg($id) name]]
		# Heading
		set toggleid($id) [$list create image 0 0 -anchor nw -image $contractimg]
		set headid($id) [$list create text 0 0 -anchor nw -text $name]
		contentmanager add group $cl $id -widget $list -padx $options(-grouppadx) -pady $options(-grouppady) -ipadx $options(-groupipadx) -ipady $options(-groupipady)
		contentmanager add group $cl $id head -widget $list -orient horizontal -omnipresent yes
		contentmanager add element $cl $id head toggle -widget $list -tag $toggleid($id)
		contentmanager add element $cl $id head text -widget $list -tag $headid($id)

		# Bind heading
		contentmanager bind $cl $id head <ButtonPress> "$self toggle $id"

		# Store the group id in list
		lappend groups $id

		# Sort the cl
		$self sort
	}

	method groupAddFailed { } {
		
	}

	method groupDeleted { id } {
		$list delete $toggleid($id)
		$list delete $headid($id)
		set index [lsearch $groups $id]
		set list1 [lrange $groups 0 [expr {$index - 1}]]
		set list2 [lrange $groups [expr {$index + 1}] end]
		set groups [concat $list1 $list2]
		contentmanager delete $cl $id
		$self sort
	}

	method groupDeleteFailed { } {
		
	}

	method groupRenamed { groupid newname } {
		$list itemconfigure $headid($id) -text $newname
		$self sort
	}

	method groupRenameFailed { } {
		
	}

	method contactAdded { groupid id {name {}} {psm {}} {music {}} {state {}} } {
		if { [string equal $groupid {}] } {
			set groupid "nogroup"
		}
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

		$self sort
	}

	method contactAddFailed { } {
		
	}

	method contactDeleted { groupid id } {
		contentmanager delete $cl $groupid $id
		foreach tag "$buddyid($groupid.$id) $nickid($groupid.$id) $psmid($groupid.$id) $stateid($groupid.$id)" {
			$list delete $tag
		}
		$self sort
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

	method contactChangeNick { id newnick } {
		foreach groupid $groups {
			if { [info exists nickid($groupid.$id)] } {
				$list itemconfigure $nickid($groupid.$id) -text $newnick
				# Store the new nick in array
				set nick($i) $newnick
			}
		}
	}

	method contactChangePSM { id newpsm } {
		foreach groupid $groups {
			if { [info exists psmid($groupid.$id)] } {
				$list itemconfigure $psmid($groupid.$id) -text $newpsm
			}
		}
	}

	method contactChangeMusic { id newmusic } {
		foreach groupid $groups {
			if { [info exists musicid($groupid.$id)] } {
				$list itemconfigure $musicid($groupid.$id) -text $newmusic
			}
		}
	}

	method contactChangeState { id newstate } {
		foreach groupid $groups {
			if { [info exists stateid($groupid.$id)] } {
				$list itemconfigure $stateid($groupid.$id) -text $newstate
			}
		}
	}

	# Methods to carry out GUI actions
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
		$self sort 0
	}

	method SelectContact { args } {
		set groupid [lindex $args 0]
		if { [string equal $groupid "none"] } {
			$list itemconfigure $selectbgid -state hidden
			return
		}
		set id [lindex $args 1]
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

	method sort { {level r} } {
		after cancel $afterid(sort)
		set afterid(sort) [after 1 "$self Sort $level"]
	}

	method Sort { {level r} } {
		contentmanager sort $me $level
		contentmanager sort $cl $level

		# Position displaypic bg and overlay (top canvas)
		set xy [$top coords $mypicid]
		eval $top coords $mypicbgid $xy
		eval $top coords $mypicoverlayid $xy
		$top raise $mypicoverlayid

		# Position selectbg (list canvas)
		if { ![string equal $selected "none"] } {
			set x 7;#[lindex $options(-listborder) 0]
			set y [lindex [eval contentmanager getcoords $cl $selected] 1]
			$list coords $selectbgid $x $y
			$selectbg configure -height [eval contentmanager cget $cl $selected -height]
		}
		# Resize group bg
		foreach groupid $groups {
			eval $list coords $groupbgid($groupid) [contentmanager getcoords $cl $groupid]
			$self SetGroupBgHeight $groupid [contentmanager cget $cl $groupid -height]
		}
	}

	method Config { component width height } {
		after cancel $afterid(config.$component)
		set afterid(config.$component) [after 1 "$self Configure $component $width $height"]
	}

	method Configure { component width height } {
		puts configure.$component
		switch $component {
			top {
				$topbg configure -width $width -height $height
			}
			list {
				$listbg configure -width $width -height $height
				$selectbg configure -width [expr {$width - 14}];#[expr {$width - [lindex $options(-listborder) 0] - [lindex $options(-listborder) 2]}]
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
