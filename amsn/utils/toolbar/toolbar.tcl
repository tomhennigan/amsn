# o----------------------o
# | name: toolbar.tcl    |
# | author: tom jenkins  |
# | date: 07/06/06       |
# o----------------------o

# --------------------------------------------------
#  toolbar - create and manipulate toolbar widgets
# --------------------------------------------------
snit::widget toolbar {

	typevariable backgroundimg
	typevariable buttonimg
	typevariable buttondownimg
	typevariable moreimg
	typevariable background_border
	typevariable button_border

	typeconstructor {
		# Load images
		::skin::setPixmap toolbar_background toolbar_background.png
		::skin::setPixmap toolbar_button toolbar_button.png
		::skin::setPixmap toolbar_button_down toolbar_button_down.png
		::skin::setPixmap toolbar_more toolbar_more.png
		set backgroundimg [::skin::loadPixmap toolbar_background]
		set buttonimg [::skin::loadPixmap toolbar_button]
		set buttondownimg [::skin::loadPixmap toolbar_button_down]
		set moreimg [::skin::loadPixmap toolbar_more]
		set background_border {5 5 5 5}
		set button_border {5 5 5 5}
	}

	# Options
	option -bgimage -configuremethod SetBgImage
	option -bgborder -default {5 5 5 5}
	option -buttonimage -configuremethod SetButtonImage
	option -buttonborder -default {5 5 5 5}
	option -activeforeground -configuremethod SetActiveForeground -default black
	option -activefg -configuremethod SetActiveForeground -default black
	option -disabledforeground -configuremethod SetDisabledForeground -default grey
	option -disabledfg -configuremethod SetDisabledForeground -default grey
	option -fg -configuremethod SetForeground -default black
	option -foreground -configuremethod SetForeground -default black
	option -itempadx -default 2 -configuremethod SetPadding
	option -itempady -default 2 -configuremethod SetPadding
	option -itemipadx -default 4 -configuremethod SetPadding
	option -itemipady -default 4 -configuremethod SetPadding
	option -ipadx -default 2 -configuremethod SetPadding
	option -ipady -default 2 -configuremethod SetPadding
	option -orient -default horizontal -configuremethod SetOrient
	option -viewmode -default 2 -configuremethod SetViewMode

	# Let canvas handle options
	delegate option * to canvas except { -bgimage -buttonimage -itempadx -itempady -orient }

	# Use a frame for our base
	hulltype frame

	# Canvas and menu components
	component canvas
	component viewmenu

	# Variables
	variable shell ;# outer contentmanager group
	variable items ;# list of items
	variable itemid ;# unique id for each item
	variable config ;# array to store names of config objects
	variable background ;# scalable-bg for background image
	variable backgroundid ;# id of background image on canvas
	variable button ;# scalable-bg for toolbar button
	variable buttondown ;# scalable-bg for toolbar button, pressed
	variable buttonid ;# id of toolbar button on canvas
	variable more ;# group to hold button to show toolbar items not visible (i.e. because toolbar is too small)
	variable moreid ;# id of more button image on canvas

	variable afterid ;# array used to process only the last in a batch of identical commands

	constructor { args } {
		$hull configure -relief flat -bd 0
		# Create canvas (we will draw everything on this) and menu
		install canvas using canvas $self.c -height 0 -highlightthickness 0 -relief flat -borderwidth 0
		install viewmenu using menu $self.view -tearoff 0
		# Add commands to view menu
		$viewmenu add command -label "Icons only" -command "$self configure -viewmode 0"
		$viewmenu add command -label "Text only" -command "$self configure -viewmode 1"
		$viewmenu add command -label "Text and icons" -command "$self configure -viewmode 2"
		# Create outer contentmanager group 'shell'
		set shell [contentmanager add group $self.shell -widget $canvas -orient horizontal -ipadx $options(-ipadx) -ipady $options(-ipady)]
		# Add group to hold the items, inside shell
		contentmanager add group $shell items \
			-widget $canvas -orient horizontal
		# Create background scalable-bg
		set background [scalable-bg $self.background \
			-source $backgroundimg -resizemethod scale\
			-border $options(-bgborder)]
		# Put it on the canvas
		set backgroundid [$canvas create image 0 0 -anchor nw -image [$background name]]
		# Create toolbar button scalable-bg
		set button [scalable-bg $self.button \
			-source $buttonimg -resizemethod scale \
			-border $options(-buttonborder)]
		set buttondown [scalable-bg $self.buttondown \
			-source $buttondownimg -resizemethod scale \
			-border $options(-buttonborder)]
		# Put it on the canvas (hidden for now, we aren't hovering any items)
		set buttonid [$canvas create image 0 0 -anchor nw -image [$button name] -state hidden]

		# Create 'more' button on canvas
		set moreid [$canvas create image 0 0 -anchor nw -image $moreimg]
		# Create the group and element for the 'more' button
		contentmanager add group $shell more -widget $canvas -valign center
		contentmanager add element $shell more button -widget $canvas -tag $moreid
		# Hide it for now (no items yet!)
		contentmanager hide $shell more button

		# Initial values for variables
		set items {}
		set itemid 0
		array set afterid {sort {}}

		# Parse and apply arguments given at creation time
		$self configurelist $args

		# Pack our canvas in the frame (hull)
		pack $canvas -expand true -fill both

		# Bind the canvas
		bind $canvas <Configure> "$self Configure %w %h" ;# When resizing, we want to do things like resize background image
		bind $canvas <ButtonPress-3> "tk_popup $viewmenu %X %Y" ;# Right mouse click on toolbar to pop up view menu
	}

	destructor {
		catch { contentmanager delete $self.shell }
		catch { after cancel $afterid(sort) } ;# Don't want it trying to do $w sort when $w doesn't exist anymore!
		catch { destroy $background } ;# Get rid of background scalable-bg
		catch { destroy $button } ;# Get rid of toolbar button scalable-bg
		catch { destroy $buttondown } ;# Get rid of toolbar button scalable-bg
	}

	# -----------------------------------------------------------------------------------------------
	#  Configure - called when the canvas changes size. Updates size of background images and checks 
	#  if we need to show the 'more' button
	#  w - width of canvas
	#  h - height of canvas
	# -----------------------------------------------------------------------------------------------
	method Configure { w h } {
		# Resize the background image
		$background configure -width $w -height $h
		# Check if we need to show the 'more' button, and hide items that don't completely fit
		set tw 0
		set i 0
		foreach item $items {
			set iw [contentmanager cget $shell items $item -width]
			set padx [contentmanager cget $shell items $item -padx]
			incr tw [expr {$iw + (2 * $padx)}]
			if { $tw > [expr {$w + $padx}] } {
				break
			}
			contentmanager show $shell items $item -level 0
			incr i 1
		}
		set outofview [lrange $items $i end]
		foreach item $outofview {
			contentmanager hide $shell items $item
		}
		# Position the 'more' button
		if { [llength $outofview] > 0 } {
			contentmanager show $shell more button
			$self sort
			contentmanager coords $shell more [expr {$w - [contentmanager cget $shell more -width] - $options(-itempadx)}] [lindex [contentmanager getcoords $shell more] 1]
		} else {
			contentmanager hide $shell more button
			$self sort
		}
	}

	# -------------------------------------------------
	# Methods to change options
	# -------------------------------------------------
	method SetBgImage { option value } {
		set options(-bgimage) $value
		$background configure -source $value
	}

	method SetButtonImage { option value } {
		set options(-buttonimage) $value
		$button configure -source $value
	}

	method SetActiveForeground { option value } {
		set options(-activeforeground) $value
		set options(-activefg) $value
		foreach item $items {
			$canvas itemconfigure [$config($item) cget -textid] -fill $value
		}
	}

	method SetDisabledForeground { option value } {
		set options(-disabledforeground) $value
		set options(-disabledfg) $value
	}

	method SetForeground { option value } {
		set options(-foreground) $value
		set options(-fg) $value
	}

	method SetOrient { option value } {
		set options(-orient) $value
		contentmanager configure $shell items -orient $value
	}

	method SetPadding { option value } {
		set options($option) $value
		foreach item $items {
			contentmanager configure $shell items $item -padx $options(-padx) -pady $options(-pady)
			contentmanager configure $shell items $item icon -padx $options(-itemipadx) -pady $options(-itemipady)
			contentmanager configure $shell items $item text -padx $options(-itemipadx) -pady $options(-itemipady)
		}
		$self sort
	}

	method SetViewMode { option value } {
		if { $value == $options(-viewmode) } {
			return
		}
		set options(-viewmode) $value
		$self ApplyViewMode
		$self sort
	}

	# -----------------------------------------------------------------------------------
	#  ApplyViewMode - Hides/shows text/icons depending on the view mode
	# -----------------------------------------------------------------------------------
	method ApplyViewMode { {item "all"} } {
		switch $options(-viewmode) {
			0 {
				# Icons only
				if { $item == "all" } {
					foreach item $items {
						contentmanager show $shell items $item icon
						contentmanager hide $shell items $item text
					}
				} else {
					contentmanager show $shell items $item icon
					contentmanager hide $shell items $item text
				}
			}
			1 {
				# Text only
				if { $item == "all" } {
					foreach item $items {
						contentmanager show $shell items $item text
						contentmanager hide $shell items $item icon
					}
				} else {
					contentmanager show $shell items $item text
					contentmanager hide $shell items $item icon
				}
			}
			2 {
				if { $item == "all" } {
					# Icons and text
					foreach item $items {
						contentmanager show $shell items $item text
						contentmanager show $shell items $item icon
					}
				} else {
					contentmanager show $shell items $item text
					contentmanager show $shell items $item icon
				}
			}
		}
	}
	

	# --------------------------------------------------------------
	#  add - adds an item to the toolbar
	#  _type - the type of item to add. can be command or cascade
	#  args - arguments to pass to the item
	# --------------------------------------------------------------
	method add { _type args } {
		lappend args -activefg $options(-activefg) -disabledfg $options(-disabledfg) -fg $options(-fg)
		switch $_type {
			command {
				eval $self CreateCommand end $args
			}
			cascade {
				
			}
		}
		lappend items $itemid
		$self ApplyViewMode $itemid
		incr itemid 1

		# Sort
		$self sort
	}

	method insert { index _type args } {
		lappend args -activefg $options(-activefg) -disabledfg $options(-disabledfg) -fg $options(-fg)
		switch $_type {
			command {
				eval $self CreateCommand $index $args
			}
			cascade {
				
			}
		}
		set items [linsert $items $index $itemid]
		$self ApplyViewMode $itemid
		incr itemid 1

		# Sort
		$self sort
	}

	method CreateCommand { index args } {
		contentmanager insert $index group $shell items $itemid -widget $canvas \
			-ipadx $options(-itemipadx) \
			-ipady $options(-itemipady) \
			-valign bottom
		set imgtag [$canvas create image 0 0 -anchor nw]
		set txttag [$canvas create text 0 0 -anchor nw]
		contentmanager add element $shell items $itemid icon -widget $canvas \
			-align center \
			-padx $options(-itemipadx) \
			-pady $options(-itemipady) \
			-tag $imgtag
		contentmanager add element $shell items $itemid text -widget $canvas \
			-align center \
			-padx $options(-itemipadx) \
			-pady $options(-itemipady) \
			-tag $txttag
		
		set config($itemid) [toolbarItemConfig $self.$itemid.config \
			-canvas $canvas \
			-tree [list $shell items $itemid] \
			-imageid $imgtag \
			-textid $txttag \
			-activefg $options(-activefg) \
			-disabledfg $options(-disabledfg) \
			-fg $options(-fg)]
		$config($itemid) configurelist $args
		
		if { [$config($itemid) cget -text] == {} } {
			contentmanager hide $shell items $itemid text
		}
		if { [$config($itemid) cget -image] == {} } {
			contentmanager hide $shell items $itemid icon
		}
		
		# Bind for showing button on hover
		contentmanager bind $shell items $itemid <Enter> "+$self Enter $itemid"
		contentmanager bind $shell items $itemid <B1-Enter> "+$self Enter $itemid 1"
		contentmanager bind $shell items $itemid <Leave> "+$self Leave $itemid"
		contentmanager bind $shell items $itemid <ButtonPress-1> "+$self Press $itemid"
		contentmanager bind $shell items $itemid <ButtonRelease-1> "+$self Release $itemid %x %y"
	}

	# ------------------------------------------------------------------------------------------------------------------------
	#  delete - deletes an item or range of items from the toolbar
	#  index - the index of either the item to delete, or the start of the range of items to delete (if index2 is specified)
	#  index2 - the index of the end of the range of items to delete
	# ------------------------------------------------------------------------------------------------------------------------
	method delete { index {index2 {}} } {
		if { $index == "all" } {
			set index 0
			set index2 end
		}
		if { $index2 == {} } {
			set index2 $index
		}
		set delrange [lrange $items $index $index2]
		foreach $item $delrange {
			contentmanager delete $shell items $item
		}
		$self sort
	}

	# --------------------------------------------------------------
	#  itemconfigure - pass arguments to an existing item
	#  index - the index of the item to configure
	#  args - the set of arguments to configure it with
	# --------------------------------------------------------------
	method itemconfigure { index args } {
		$config([lindex $items $index]) configurelist $args
		$self sort
	}

	# --------------------------------------------------------------
	#  itemcget - get the value of an option from an item
	#  index - the index of the item to query
	#  option - the option of which to get the value
	# --------------------------------------------------------------
	method itemcget { index option } {
		return [$config([lindex $items $index]) cget $option]
	}

	# --------------------------------------------------------------
	#  Select - select (show toolbar button behind) an item
	#  id - unique id for the item (NOT the index)
	# --------------------------------------------------------------
	method Enter { id {b 0} } {
		if { $b == 1 } {
			$canvas itemconfigure $buttonid -image [$buttondown name] -state normal
		} else {
			$canvas itemconfigure $buttonid -image [$button name] -state normal
		}
		$self Select $id
	}

	method Leave { id } {
		$self Select none
		if { [$config($id) cget -state] != "disabled" } {
			$canvas itemconfigure [$config($id) cget -imageid] -image [$config($id) cget -image]
			$canvas itemconfigure [$config($id) cget -textid] -fill [$config($id) cget -fg]
		}
	}

	method Select { id } {
		if { $id == "none" || [$config($id) cget -state] == "disabled" } {
			$canvas itemconfigure $buttonid -state hidden
			return
		}
		set xy [contentmanager getcoords $shell items $id]
		set w [contentmanager cget $shell items $id -width]
		set h [contentmanager cget $shell items $id -height]
		$buttondown configure -width $w -height $h
		$button configure -width $w -height $h
		eval $canvas coords $buttonid $xy
	}

	# --------------------------------------------------------------
	#  Select - select (show toolbar button behind) an item
	#  id - unique id for the item (NOT the index)
	# --------------------------------------------------------------
	method Press { id } {
		if { $id == "none" || [$config($id) cget -state] == "disabled" } {
			$canvas itemconfigure $buttonid -state hidden
			return
		}
		set xy [contentmanager getcoords $shell items $id]
		set w [contentmanager cget $shell items $id -width]
		set h [contentmanager cget $shell items $id -height]
		eval $canvas coords $buttonid $xy
		$buttondown configure -width $w -height $h
		$canvas itemconfigure $buttonid -image [$buttondown name] -state normal
	}

	method Release { id x y } {
	set coords [eval contentmanager getcoords $shell items $id]
	set cx [$canvas canvasx $x]
	set cy [$canvas canvasy $y]
	set ix0 [lindex $coords 0]
	set ix1 [expr {$ix0 + [eval contentmanager cget $shell items $id -width]}]
	set iy0 [lindex $coords 1]
	set iy1 [expr {$iy0 + [eval contentmanager cget $shell items $id -height]}]

	if { $cx >= $ix0 && $cx <= $ix1 && $cy >= $iy0 && $cy <= $iy1 && [$config($id) cget -state] != "disabled" } {
		$canvas itemconfigure $buttonid -image [$button name]
		eval [$config($id) cget -command]
	}
}

	# ------------------------------------------------------------------------------------------------
	#  sort - wraps SortItems, stops lots of SortItems being executed at once, only runs the last one
	# ------------------------------------------------------------------------------------------------
	method sort { } {
		after cancel $afterid(sort)
		set afterid(sort) [after 1 "$self SortItems"]
	}

	# --------------------------------------------------------------
	#  SortItems - sort the items and resize the toolbar to fit
	# --------------------------------------------------------------
	method SortItems { } {
		contentmanager sort $shell
		$canvas configure -height [contentmanager cget $shell -height]
	}
}

# ----------------------------------------------------------------------
#  toolbarItemConfig - stores and processes options for toolbar items
# ----------------------------------------------------------------------
snit::type toolbarItemConfig {

	option -activefg
	option -activeimage -configuremethod SetActiveImage
	option -canvas
	option -command -configuremethod SetCommand
	option -disabledfg
	option -disabledimage
	option -fg
	option -image -configuremethod SetImage
	option -imageid
	option -state -configuremethod SetState
	option -text -configuremethod SetText
	option -textid
	option -tree

	method SetActiveImage { option value } {
		set options(-activeimage) $value
		eval contentmanager bind $options(-tree) <Enter> [list "+$self Enter"]
	}

	method SetCommand { option value } {
		set options(-command) $value
	}

	method SetImage { option value } {
		set options(-image) $value
		set tag [eval contentmanager cget $options(-tree) icon -tag]
		$options(-canvas) itemconfigure $tag -image $value
		if { $value == {} } {
			eval contentmanager hide $options(-tree) icon
		} else {
			eval contentmanager show $options(-tree) icon
		}
		eval contentmanager bind $options(-tree) <Leave> [list "+$self Leave"]
	}

	method SetState { option value } {
		set options(-state) $value
		switch $value {
			active {
				$options(-canvas) itemconfigure $options(-imageid) -image $options(-activeimage)
				$options(-canvas) itemconfigure $options(-textid) -fill $options(-activefg)
			}
			disabled {
				$options(-canvas) itemconfigure $options(-imageid) -image $options(-disabledimage)
				$options(-canvas) itemconfigure $options(-textid) -fill $options(-disabledfg)
			}
			normal {
				$options(-canvas) itemconfigure $options(-imageid) -image $options(-image)
				$options(-canvas) itemconfigure $options(-textid) -fill $options(-fg)
			}
		}
	}

	method SetText { option value } {
		set options(-text) $value
		set tag [eval contentmanager cget $options(-tree) text -tag]
		$options(-canvas) itemconfigure $tag -text $value
		if { $value == {} } {
			eval contentmanager hide $options(-tree) text
		} else {
			eval contentmanager show $options(-tree) text
		}
	}

	method Leave { } {
		if { $options(-state) != "disabled" } {
			$self configure -state normal
		}
	}

	method Enter { } {
		if { $options(-state) != "disabled" } {
			$self configure -state active
		}
	}
}