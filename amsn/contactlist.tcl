package require contentmanager

snit::widget contactlist {

	typevariable topbgimg
	typevariable listbgimg
	typevariable expandimg
	typevariable contractimg
	typevariable buddyimg

	typevariable nickfont
	typevariable psmfont
	typevariable musicfont
	typevariable statefont

	typevariable nickcol
	typevariable psmcol
	typevariable musiccol
	typevariable statecol

	typeconstructor {
		# Load images
		::skin::setPixmap background_top background_top.png
		::skin::setPixmap background_list background_list.png
		::skin::setPixmap expand expand.png
		::skin::setPixmap contract contract.png
		::skin::setPixmap buddy buddy.png

		set topbgimg [::skin::loadPixmap background_top]
		set listbgimg [::skin::loadPixmap background_list]
		set expandimg [::skin::loadPixmap expand]
		set contractimg [::skin::loadPixmap contract]
		set buddyimg [::skin::loadPixmap buddy]

		# Set fonts
		set nickfont [font create -family helvetica -size 11 -weight bold]
		set psmfont [font create -family helvetica -size 11 -weight bold -slant italic]
		set musicfont [font create -family helvetica -size 11 -weight bold]
		set statefont [font create -family helvetica -size 11 -weight bold]

		# Set colours
		set nickcol darkblue
		set psmcol orange
		set musiccol purple
		set statecol darkgreen
	}

	component top
	component topbg
	component list
	component listbg

	option -width -default 0
	option -height -default 0
	option -topborder -default {14 14 14 14}
	option -listborder -default {11 11 11 11}
	option -ipadx -default 12
	option -ipady -default 12
	option -grouppadx -default 5
	option -grouppady -default 5
	option -buddypadx -default 2
	option -buddypady -default 2
	option -contractpadx -default 2
	option -contractpady -default 2
	option -expandpadx -default 2
	option -expandpady -default 2

	variable container
	variable groups

	variable toggleid
	variable headid
	variable buddyid
	variable nickid
	variable psmid
	variable musicid
	variable stateid

	variable dragX
	variable dragY
	variable dragXOffset
	variable dragYOffset

	variable afterid

	option -grouporder

	constructor { args } {
		# Create canvases
		install top using canvas $self.top -bd 0 -highlightthickness 0 -insertontime 0 -height 100
		install list using canvas $self.list -bd 0 -highlightthickness 0 -insertontime 0

		# Create background images
		install topbg using scalable-bg $top.bg -source $topbgimg \
			-n [lindex $options(-topborder) 0] -e [lindex $options(-topborder) 1] \
			-s [lindex $options(-listborder) 2] -w [lindex $options(-topborder) 3] \
			-resizemethod tile
		install listbg using scalable-bg $list.bg -source $listbgimg \
			-n [lindex $options(-listborder) 0] -e [lindex $options(-listborder) 1] \
			-s [lindex $options(-listborder) 2] -w [lindex $options(-listborder) 3] \
			-resizemethod tile
		$list create image 0 0 -anchor nw -image [$listbg name]
		$top create image 0 0 -anchor nw -image [$topbg name]

		# Pack them
		pack $top -side top -anchor nw -expand false -fill both
		pack $list -side top -anchor nw -expand true -fill both -pady 5

		# Bind them
		bind $top <Configure> "$self Configure top %w %h"
		bind $list <Configure> "$self Configure list %w %h"

		# Apply arguments
		$self configurelist $args

		# Create empty arrays
		array set toggleid {{} {}}
		array set headid {{} {}}
		array set buddyid {{} {}}
		array set nickid {{} {}}
		array set psmid {{} {}}
		array set musicid {{} {}}
		array set stateid {{} {}}
		array set dragX {{} {}}
		array set dragY {{} {}}

		array set afterid {sort {}}

		# Create container group
		set container c
		contentmanager add group $self $container -ipadx $options(-ipadx) -ipady $options(-ipady)

		$self registerForEvents
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

	# Methods to deal with protocol events
	method contactlistLoaded { } {
		
	}

	method groupAdded { id {name {}} } {
		set toggleid($id) [$list create image 0 0 -anchor nw -image $contractimg]
		set headid($id) [$list create text 0 0 -anchor nw -text $name]

		contentmanager add group $self $container $id -widget $list -padx $options(-grouppadx) -pady $options(-grouppady)
		contentmanager add group $self $container $id head -widget $list -orient horizontal -omnipresent yes
		contentmanager add element $self $container $id head toggle -widget $list -tag $toggleid($id)
		contentmanager add element $self $container $id head text -widget $list -tag $headid($id)
		#contentmanager bind $self $container $id head <ButtonPress> "contentmanager toggle $self $container $id;contentmanager sort $self $container"
		contentmanager bind $self $container $id head <ButtonPress> "$self toggle $id"

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
		contentmanager delete $self $container $id
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
		puts "$groupid $id $name $psm $music $state"
		set buddyid($groupid.$id) [$list create image 0 0 -anchor nw -image $buddyimg]
		set nickid($groupid.$id) [$list create text 0 0 -anchor nw -text $name -font $nickfont -fill $nickcol]
		set psmid($groupid.$id) [$list create text 0 0 -anchor nw -text $psm -font $psmfont -fill $psmcol]
		set stateid($groupid.$id) [$list create text 0 0 -anchor nw -text $state -font $statefont -fill $statecol]

		contentmanager add group $self $container $groupid $id -widget $list -orient horizontal -padx $options(-buddypadx) -pady $options(-buddypady)
		contentmanager add group $self $container $groupid $id icon -widget $list
		contentmanager add group $self $container $groupid $id info -widget $list
		contentmanager add element $self $container $groupid $id icon icon -widget $list -tag $buddyid($groupid.$id)
		contentmanager add element $self $container $groupid $id info nick -widget $list -tag $nickid($groupid.$id)
		contentmanager add element $self $container $groupid $id info psm -widget $list -tag $psmid($groupid.$id)
		contentmanager add element $self $container $groupid $id info state -widget $list -tag $stateid($groupid.$id)

		#contentmanager bind $self $container $groupid $id <ButtonPress-1> "$self dragStart $groupid $id %x %y"
		#contentmanager bind $self $container $groupid $id <B1-Motion> "$self dragMotion $groupid $id %x %y"
		#contentmanager bind $self $container $groupid $id <ButtonRelease-1> "$self dragStop $groupid $id %x %y"

		$self sort
	}

	method contactAddFailed { } {
		
	}

	method contactDeleted { groupid id } {
		contentmanager delete $self $container $groupid $id
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
		set itemcoords [contentmanager getcoords $self $container $groupid $id]
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
			contentmanager coords $self $container $groupid $id $x $y
		}
	}

	method dragStop { groupid id x y } {
		foreach group $groups {
			set groupcoords [contentmanager getcoords $self $container $group]
			set groupx [lindex $groupcoords 0]
			set groupy [lindex $groupcoords 1]
			set groupwidth [contentmanager cget $self $container $group -width]
			set groupheight [contentmanager cget $self $container $group -height]
			if { $y >= $groupy && $y <= [expr {$groupy + $groupheight}] } {
				# Events::fire guiMovedContact $id $groupid $group
				return
			}
		}
	}

	method toggle { groupid } {
		contentmanager toggle $self $container $groupid
		if { [string equal [$list itemcget $toggleid($groupid) -image] $expandimg] } {
			$list itemconfigure $toggleid($groupid) -image $contractimg
		} else {
			$list itemconfigure $toggleid($groupid) -image $expandimg
		}
		$self sort
	}

	method register { id {index ""} } {
		if { [string equal $index ""] } {
			lappend groups $id
		} else {
			set items [linsert $groups $index $id]
		}

		#$self sort
	}

	method unregister { } {
		
	}

	method sort { } {
		after cancel $afterid(sort)
		set afterid(sort) [after 1 "$self Sort"]
	}

	method Sort { } {
		contentmanager sort $self $container
	}

	method Aligngroups { } {
		set width $options(-width)
		set height $options(-height)
		foreach group $groups {
			set align [contentmanager cget $self $group -align]
			set w [contentmanager cget $self $group -width]
			switch $align {
				"left" {
				}
				"center" {
					contentmanager move $self $group [expr {($width / 2) - ($w / 2)}] 0
				}
				"right" {
					contentmanager move $self $group [expr {$width - $w}] 0
				}
			}
		}
	}

	method Configure { component width height } {
		switch $component {
			top {
				$topbg configure -width $width -height $height
			}
			list {
				$listbg configure -width $width -height $height
			}
		}
	}
}
