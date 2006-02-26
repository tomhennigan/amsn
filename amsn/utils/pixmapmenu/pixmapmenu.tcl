package provide pixmapmenu 0.1
package require contentmanager

snit::widgetadaptor pixmapmenu {

	typevariable arrowdownimg 		;# Arrow image
	typevariable arrowrightimg 		;# Arrow image
	typevariable backgroundimg 		;# Background image
	typevariable backgroundborder 		;# Borders for scalable-bg for background
	typevariable selectimg 			;# Select image
	typevariable selectborder 		;# Borders for scalable-bg for select
	typevariable separatorborder
	typevariable checkboximg
	typevariable checktickimg
	typevariable radioboximg
	typevariable radiotickimg
	typevariable separatorimg

	typeconstructor {
		::skin::setPixmap menuarrowdown menu_arrow_down.png
		::skin::setPixmap menuarrowright menu_arrow_right.png
		::skin::setPixmap menubackground menu_background.png
		::skin::setPixmap menuselect menu_select.png
		::skin::setPixmap menuseparator menu_separator.png
		::skin::setPixmap checkbox checkbox.png
		::skin::setPixmap checktick checkmark.png
		::skin::setPixmap radiobox radiobox.png
		::skin::setPixmap radiotick radiomark.png
		set checkboximg [::skin::loadPixmap checkbox]
		set checktickimg [::skin::loadPixmap checktick]
		set radioboximg [::skin::loadPixmap radiobox]
		set radiotickimg [::skin::loadPixmap radiotick]
		set arrowdownimg [::skin::loadPixmap menuarrowdown]
		set arrowrightimg [::skin::loadPixmap menuarrowright]
		set backgroundimg [::skin::loadPixmap menubackground]
		set selectimg [::skin::loadPixmap menuselect]
		set separatorimg [::skin::loadPixmap menuseparator]
		set backgroundborder {1 1 1 1}
		set selectborder {1 1 1 1}
		set separatorborder {0 0 0 0}
	}

	option -activeforeground -configuremethod SetForeground -default black
	option -activefg -configuremethod SetForeground -default black
	option -cascadedelay -default 250
	option -disabledforeground -configuremethod SetForeground -default grey
	option -disabledfg -configuremethod SetForeground -default grey
	option -entrypadx -configuremethod SetPadding -default 4
	option -entrypady -configuremethod SetPadding -default 2
	option -foreground -configuremethod SetForeground -default black
	option -fg -configuremethod SetForeground -default black
	option -font -configuremethod SetFont -default "Helvetica 12"
	option -ipadx -configuremethod SetPadding -default 0
	option -ipady -configuremethod SetPadding -default 0
	option -orient -configuremethod SetOrient -default vertical
	option -tearoff -default 0 -readonly yes
	option -type -default normal


	variable canvas 	;# Canvas widget
	variable offx 		;# X-ord to create new stuff at so it's hidden
	variable offy 		;# Y-ord to create new stuff at so it's hidden
	variable main 		;# Main contentmanager group
	variable entries 	;# Stores entries
	variable entryid 	;# Unique id for each entry
	variable arrowid 	;# Array to store canvas ids of entries' arrows (cascade entries only)
	variable imageid 	;# Array to store canvas ids of entries' images
	variable textid 	;# Array to store canvas ids of entries' text
	variable checktickid	;# Array to store canvas ids of entries' check marks (checkbutton entries only)
	variable radiotickid	;# Array to store canvas ids of entries' radio marks (radiobutton entries only)
	variable backgroundid
	variable background
	variable select
	variable selectid
	variable separator
	variable afterid
	variable active
	variable config

	constructor { args } {
		# Initial values
		set entries {}
		set active "none"
		set entryid 0
		set offx -1000
		set offy -1000
		array set afterid {Sort {}}
		array set arrowid {{} {}}
		array set imageid {{} {}}
		array set textid {{} {}}
		array set checktickid {{} {}}
		array set radiotickid {{} {}}
		array set config {{} {}}

		# Create canvas
		installhull using canvas -borderwidth 0 -highlightthickness 0 -relief flat
		set canvas $hull
		# Parse and apply arguments
		$self configurelist $args

		# Create main contentmanager group
		set main [contentmanager add group $self.main \
			-widget $canvas \
			-ipadx $options(-ipadx) \
			-ipady $options(-ipady) \
			-orient $options(-orient)]

		# Create menu background & select
		set background [scalable-bg $self.background \
			-source $backgroundimg	-border $backgroundborder]
		set backgroundid [$canvas create image 0 0 -anchor nw -image [$background name]]
		set select [scalable-bg $self.select \
			-source $selectimg	-border $selectborder \
			-width 	1		-height 1]
		set selectid [$canvas create image 0 0 -anchor nw -image [$select name] -state hidden]
		# Create separator
		set separator [scalable-bg $self.separator -source $separatorimg -border $separatorborder]

		# Bindings
		bindtags $self "Pixmapmenu . all"

		# Update size
		$self UpdateSize
	}

	destructor {
		catch {after cancel $afterid(Sort)}
		catch {contentmanager delete $main}
		catch {$background destroy}
		catch {$select destroy}
		catch {$separator destroy}
		catch {
			foreach { key configobj } [array get config] {
				if { $configobj != "" } {
					$configobj destroy
				}
			}
		}
	}

	method Configure { width height } {
		switch $options(-orient) {
			horizontal {
				$background configure \
					-width	$width	-height	$height
				$separator configure \
					-width 	[image height $separatorimg] \
					-height	[expr {$height - (2 * $options(-ipady)) - (2 * $options(-entrypady))}]
			}
			vertical {
				$background configure \
					-width	$width	-height	$height
				$separator configure \
					-width 	[expr {$width - (2 * $options(-ipadx)) - (2 * $options(-entrypadx))}] \
					-height	[image height $separatorimg]
				$self AlignCascadeArrows
			}
		}
	}

	method UpdateSize { } {
		switch $options(-orient) {
			horizontal {
				set w 0
				set h 0
				foreach entry $entries {
					incr w [contentmanager width $main $entry]
					set entryh [contentmanager height $main $entry]
					if { $entryh > $h } {
						set h $entryh
					}
				}
				if { $options(-type) != "menubar" } {
					incr h [image height $arrowdownimg]
				}
				$hull configure -width [expr {$w + (2 * $options(-ipadx))}] -height [expr {$h + (2 * $options(-ipady))}]
			}
			vertical {
				set w 0
				set h 0
				foreach entry $entries {
					incr h [contentmanager height $main $entry]
					set entryw [contentmanager width $main $entry]
					if { $entryw > $w } {
						set w $entryw
					}
				}
				if { $options(-type) != "menubar" } {
					incr w [image width $arrowrightimg]
				}
				$hull configure -width [expr {$w + (2 * $options(-ipadx))}] -height [expr {$h + (2 * $options(-ipady))}]
			}
		}
	}

	method AlignCascadeArrows { } {
		foreach entry $entries {
			if { [info exists arrowid($entry)] } {
				switch $options(-orient) {
					horizontal {
						set x [expr {[$self xposition [lsearch $entries $entry]] + [contentmanager width $main $entry] / 2 - [image width $arrowdownimg] / 2}]
						set y [expr {[$hull cget -height] - $options(-ipady) - [image height $arrowdownimg] - $options(-entrypady)}]
					}
					vertical {
						set x [expr {[$hull cget -width] - $options(-ipadx) - [image width $arrowrightimg] - $options(-entrypadx)}]
						set y [expr {[$self yposition [lsearch $entries $entry]] + [contentmanager height $main $entry] / 2 - [image height $arrowrightimg] / 2}]
					}
				}
				$canvas coords $arrowid($entry) $x $y
			}
		}
	}

	method CreateEntry { index _type args } {
		switch -regexp $_type {
			com.* {
				# Create the canvas items
				set imageid($entryid) [$canvas create image $offx $offy -anchor nw]
				set textid($entryid) [$canvas create text $offx $offy -anchor nw -fill $options(-fg) -font $options(-font)]
				# Create the contentmanager items
				contentmanager insert $index group $main $entryid \
					-widget		$canvas			-orient 	horizontal \
					-ipadx 		$options(-entrypadx) 	-ipady 		$options(-entrypady)
				contentmanager add element $main $entryid icon \
					-widget	$canvas			-tag	$imageid($entryid) \
					-valign center
				contentmanager add element $main $entryid text \
					-widget	$canvas			-tag	$textid($entryid) \
					-padx $options(-entrypadx)	-pady 	$options(-entrypady) \
					-valign center
	
				# Create and configure the entry object
				set config($entryid) [uplevel #0 "$_type $self.$entryid -id $entryid -parent $self"]
				if { [lsearch $args -image] == -1 } {
					lappend args -image {}
				}
				if { [lsearch $args -label] == -1 } {
					lappend args -label {}
				}
				$config($entryid) configurelist $args
			}
			casc.* {
				# Create the canvas items
				set imageid($entryid) [$canvas create image $offx $offy -anchor nw]
				set textid($entryid) [$canvas create text $offx $offy -anchor nw -fill $options(-fg) -font $options(-font)]
				# Create the contentmanager items
				contentmanager insert $index group $main $entryid \
					-widget		$canvas			-orient 	horizontal \
					-ipadx 		$options(-entrypadx) 	-ipady 		$options(-entrypady)
				contentmanager add element $main $entryid icon \
					-widget	$canvas			-tag	$imageid($entryid) \
					-valign center
				contentmanager add element $main $entryid text \
					-widget	$canvas			-tag	$textid($entryid) \
					-padx $options(-entrypadx)	-pady 	$options(-entrypady) \
					-valign center
	
				# Create and configure the entry object
				set config($entryid) [uplevel #0 "$_type $self.$entryid -id $entryid -parent $self"]
				if { [lsearch $args -image] == -1 } {
					lappend args -image {}
				}
				if { [lsearch $args -label] == -1 } {
					lappend args -label {}
				}
				$config($entryid) configurelist $args

				# Add arrow
				if { $options(-type) != "menubar" } {
					switch $options(-orient) {
						horizontal {
							set arrowid($entryid) [$canvas create image $offx $offy -anchor nw -image $arrowdownimg]
						}
						vertical {
							set arrowid($entryid) [$canvas create image $offx $offy -anchor nw -image $arrowrightimg]
						}
					}
					contentmanager add element $main $entryid arrow \
					-widget	$canvas			-tag	$arrowid($entryid) \
					-valign center
				}
			}
			check.* {
				# Create the canvas items
				set imageid($entryid) [$canvas create image $offx $offy -anchor nw -image $checkboximg]
				set checktickid($entryid) [$canvas create image $offx $offy -anchor nw -image $checktickimg]
				set textid($entryid) [$canvas create text $offx $offy -anchor nw -fill $options(-fg) -font $options(-font)]
				# Create the contentmanager items
				contentmanager insert $index group $main $entryid \
					-widget		$canvas			-orient 	horizontal \
					-ipadx 		$options(-entrypadx) 	-ipady 		$options(-entrypady)
				contentmanager add element $main $entryid icon \
					-widget	$canvas			-tag	$imageid($entryid) \
					-padx $options(-entrypadx)	-pady 	$options(-entrypady) \
					-valign center
				contentmanager add attachment $main $entryid icon tick -widget $canvas -tag $checktickid($entryid)
				contentmanager add element $main $entryid text \
					-widget	$canvas			-tag	$textid($entryid) \
					-padx $options(-entrypadx)	-pady 	$options(-entrypady) \
					-valign center
	
				set _type menu_checkbutton
				# Create and configure the entry object
				set config($entryid) [uplevel #0 "$_type $self.$entryid -id $entryid -parent $self -canvas $canvas"]
				if { [lsearch $args -label] == -1 } {
					lappend args -label {}
				}
				$config($entryid) configurelist $args
			}
			radio.* {
				# Create the canvas item
				set imageid($entryid) [$canvas create image $offx $offy -anchor nw -image $radioboximg]
				set radiotickid($entryid) [$canvas create image $offx $offy -anchor nw -image $radiotickimg]
				set textid($entryid) [$canvas create text $offx $offy -anchor nw -fill $options(-fg) -font $options(-font)]
	
				# Create the contentmanager items
				contentmanager insert $index group $main $entryid \
					-widget		$canvas			-orient 	horizontal \
					-ipadx 		$options(-entrypadx) 	-ipady 		$options(-entrypady)
				contentmanager add element $main $entryid icon \
					-widget	$canvas			-tag	$imageid($entryid) \
					-padx $options(-entrypadx)	-pady 	$options(-entrypady) \
					-valign center
				contentmanager add attachment $main $entryid icon tick -widget $canvas -tag $radiotickid($entryid)
				contentmanager add element $main $entryid text \
					-widget	$canvas			-tag	$textid($entryid) \
					-padx $options(-entrypadx)	-pady 	$options(-entrypady) \
					-valign center
				set _type menu_radiobutton
				# Create and configure the entry object
				set config($entryid) [uplevel #0 "$_type $self.$entryid -id $entryid -parent $self -canvas $canvas"]
				if { [lsearch $args -label] == -1 } {
					lappend args -label {}
				}
				$config($entryid) configurelist $args
			}
			sep.* {
				# Create the canvas item
				set id [$canvas create image $offx $offy -anchor nw -image [$separator name]]
				# Create the contentmanager item
				contentmanager insert $index element $main $entryid \
					-widget	$canvas			-tag	$id \
					-ipadx	$options(-entrypadx)	-ipady $options(-entrypady)
				set config($entryid) [uplevel #0 "$_type $self.$entryid -id $entryid -parent $self"]
			}
		}
		#if { $_type == "command" || $_type == "cascade" } {
		#	
		#} elseif { $_type == "separator" } {
		#	
		#} elseif { $_type == "checkbutton" } {
		#	
		#} elseif { $_type == "radiobutton" } {
		#	
		#}

		incr entryid 1
		return [expr {$entryid - 1}]
	}

	method EntryConfigureImage { id value } {
		$canvas itemconfigure $imageid($id) -image $value
		if { $value == "" } {
			contentmanager hide $main $id icon
		} else {
			contentmanager show $main $id icon
		}
		$self sort
	}

	method EntryConfigureLabel { id value } {
		$canvas itemconfigure $textid($id) -text $value
		if { $value == "" } {
			contentmanager hide $main $id text
		} else {
			contentmanager show $main $id text
		}
		$self sort
	}

	method EntryDeselectCheck { id } {
		# Only works with an after, don't know why :(
		after 0 "$canvas itemconfigure $checktickid($id) -state hidden"
	}

	method EntryDeselectRadio { id } {
		$canvas itemconfigure $radiotickid($id) -state hidden
	}

	method EntrySelectCheck { id } {
		# Only works with an after, don't know why :(
		if { [$config($id) cget -indicatoron] } {
			after 0 "$canvas itemconfigure $checktickid($id) -state normal"
		}
	}

	method EntrySelectRadio { id } {
		if { [$config($id) cget -indicatoron] } {
			$canvas itemconfigure $radiotickid($id) -state normal
		}
	}

	method add { _type args } {
		# Create the entry
		set id [eval $self CreateEntry end $_type $args]
		# Append the entry to the list of entries
		lappend entries $id
	}

	method insert { index _type args } {
		# Create the entry
		set id [eval $self CreateEntry $index $_type $args]
		# Insert the entry in the list of entries
		set entries [linsert $entries $index $id]
	}

	method delete { index {index2 {}} } {
		if { $index2 == "" } {
			set index2 $index
		}
		foreach entry [lrange $entries $index $index2] {
			contentmanager delete $main $entry
			$config($entry) destroy
		}
		if { $index == "end" || $index == "last" } {
			set index [expr {[llength $entries] - 1}]
		}
		if { $index2 == "end" || $index2 == "last" } {
			set index2 [expr {[llength $entries] - 1}]
		}
		set entries [concat [lrange $entries 0 [expr {$index - 1}]] [lrange $entries [expr {$index2 + 1}] end]]
		$self sort
	}

	method entryconfigure { index args } {
		set nindex [$self index $index]
		if { $nindex == "none" } {
			return
		}
		set entry [lindex $entries $nindex]
		$config($entry) configurelist $args
	}

	method entrycget { index option } {
		set nindex [$self index $index]
		if { $nindex == "none" } {
			return
		}
		set entry [lindex $entries $nindex]
		return [$config($entry) cget $option]
	}

	method index { index } {
		# Given index as an integer
		if { [string is integer $index] } {
			if { $index >= 0 && $index <= [$self index last] } {
				return $index
			} else {
				return "none"
			}
		}
		# Given index in the form @x,y
		if { [string index $index 0] == "@" } {
			set index [string map {@ "" , " "} $index]
			return [eval $self EntryAtPoint $index]
		}

		# Given index as "start" or "end" or "last" or "none" or "active"
		switch $index {
			start { return 0 }
			end { return [expr {[llength $entries] - 1}] }
			last { return [expr {[llength $entries] - 1}] }
			active {
				if { $active != "" } {
					return $active
				} else {
					return "none"
				}
			}
			none { return "none" }
		}

		# If all else fails...
		return "none"
	}

	method invoke { index } {
		set nindex [$self index $index]
		if { $nindex == "none" || [$self entrycget $nindex -state] == "disabled" || [$self type $nindex] == "separator" } {
			return
		}
		set entry [lindex $entries $nindex]
		set _type [$config($entry) type]
		if { $_type == "checkbutton" } {
			$config($entry) toggle
			if { [$canvas itemcget $checktickid($entry) -state] == "hidden" && [$config($entry) cget -indicatoron] } {
				$canvas itemconfigure $checktickid($entry) -state normal
			} else {
				$canvas itemconfigure $checktickid($entry) -state hidden
			}
		} elseif { $_type == "radiobutton" } {
			$config($entry) select
			if { [$canvas itemcget $radiotickid($entry) -state] == "hidden" && [$config($entry) cget -indicatoron] } {
				$canvas itemconfigure $radiotickid($entry) -state normal
			}
		}
		eval [$config($entry) cget -command]
	}

	method EntryAtPoint { x y } {
		set id none
		foreach entry $entries {
			set coords 	[contentmanager	getcoords	$main	$entry]
			set width 	[contentmanager	width		$main	$entry]
			set height 	[contentmanager	height		$main	$entry]

			switch $options(-orient) {
				horizontal {
					set x0 [lindex $coords 0]
					set x1 [expr {$x0 + $width}]
					set y0 $options(-ipady)
					set y1 [expr {[winfo height $self] - $options(-ipady)}]
				}
				vertical {
					set x0 $options(-ipadx)
					set x1 [expr {[winfo width $self] - $options(-ipadx)}]
					set y0 [lindex $coords 1]
					set y1 [expr {$y0 + $height}]
				}
			}

			if { $x >= $x0 && $x <= $x1 && $y >= $y0 && $y <= $y1 } {
				set id $entry
				break
			}
		}

		if { $id == "none" } {
			return "none"
		} else {
			return [lsearch $entries $id]
		}
	}

	method activate { index {b 0} } {
		# Don't bother activating an entry that's already active
		if { $index == $active } {
			return
		}
		# Return the previously activated entry's state to normal
		if { $active != "none" } {
			$self EntryConfigureState [lindex $entries $active] normal
		}

		set nindex [$self index $index]
		# Don't activate separators or disabled entries, hide the select image
		if { $nindex == "none" || [$self entrycget $index -state] == "disabled" || [$self type $index] == "separator" } {
			set active "none"
			$canvas itemconfigure $selectid -state hidden
			return
		}

		# Work out coords dimensions for select image
		set entry [lindex $entries $nindex]
		set coords [contentmanager getcoords $main $entry]
		switch $options(-orient) {
			horizontal {
				set width [contentmanager width $main $entry]
				set height [expr {[winfo height $self] - (2 * $options(-ipady))}]
			}
			vertical {
				set width [expr {[winfo width $self] - (2 * $options(-ipadx))}]
				set height [contentmanager height $main $entry]
			}
		}

		# Configure the select image with those dimensions and place it at those coords
		$select configure -width $width -height $height
		eval $canvas coords $selectid $coords
		$canvas itemconfigure $selectid -state normal

		# Make the now-active entry's state active
		$self EntryConfigureState [lindex $entries $nindex] active
		# Store it as the active entry
		set active $nindex

		# Do we want to post the submenu (if entry is cascade) or not (yes when using mouse, no when using keyboard arrows)
		if { $b == 1 && [$self type $nindex] == "cascade" } {
			$self postcascade $nindex
		}
	}

	method postcascade { index } {
		set nindex [$self index $index]
		# If the submenu is already posted, don't bother
		if { [$self type $nindex] == "cascade" } {
			if { [winfo ismapped [$self entrycget $nindex -menu]] } {
				return
			}
		}
		# Unpost any posted cascades in this menu
		foreach entry $entries {
			if { [$self type [lsearch $entries $entry]] == "cascade" } {
				[$self entrycget [lsearch $entries $entry] -menu] unpost
			}
		}
		# Can't postcasade "none" or a non-cascade entry
		if { $nindex == "none" || [$self type $nindex] != "cascade" } {
			return
		}
		set entry [lindex $entries $nindex]
		set menu [$self entrycget $nindex -menu]
		# Set coords to post submenu at
		switch $options(-orient) {
			horizontal {
				set x [expr {[winfo rootx $self] + [$self xposition $nindex]}]
				set y [expr {[winfo rooty $self] + [winfo height $self]}]
			}
			vertical {
				set x [expr {[winfo rootx $self] + [winfo width $self] - $options(-entrypadx)}]
				set y [expr {[winfo rooty $self] + [$self yposition $nindex]}]
			}
		}
		# And, finally, post it :)
		$menu post $x $y
	}

	method type { index } {
		set nindex [$self index $index]
		if { $nindex == "none" } {
			return
		}
		set entry [lindex $entries $nindex]
		return [$config($entry) type]
	}

	method xposition { index } {
		set nindex [$self index $index]
		if { $nindex == "none" } {
			return
		}
		set entry [lindex $entries $nindex]
		return [lindex [contentmanager getcoords $main $entry] 0]
	}

	method yposition { index } {
		set nindex [$self index $index]
		if { $nindex == "none" } {
			return
		}
		set entry [lindex $entries $nindex]
		return [lindex [contentmanager getcoords $main $entry] 1]
	}

	method sort { } {
		after cancel $afterid(Sort)
		set afterid(Sort) [after 1 "$self Sort"]
	}

	method Sort { } {
		contentmanager sort $main
		$self UpdateSize
		$self AlignCascadeArrows
	}

	method SetOrient { option value } {
		set options(-orient) $value
		switch $value {
			horizontal {
				#set arrowimg [::skin::loadPixmap menuarrowdown]
			}
			vertical {
				#set arrowimg [::skin::loadPixmap menuarrowright]
			}
		}
	}

	method SetPadding { option value } {
		set options($option) $value
		contentmanager configure $main -ipadx $options(-ipadx) -ipady $options(-ipady)
		foreach entry $entries {
			contentmanager configure $main $entry -ipadx $options(-entrypadx) -ipady $options(-entrypady)
			contentmanager configure $main $entry icon -padx $options(-entrypadx) -pady $options(-entrypady)
			contentmanager configure $main $entry text -padx $options(-entrypadx) -pady $options(-entrypady)
		}
		$self Sort
	}

	method SetFont { option value } {
		set options(-font) $value
		foreach entry $entries {
			if { [$self type [lsearch $entries $entry]] != "separator" } {
				$self EntryConfigureFont $entry $value
			}
		}
	}

	method SetForeground { option value } {
		switch [string index $option 1] {
			a {
				set options(-activeforeground) $value
				set options(-activefg) $value
				foreach entry $entries {
					if { [$self type [lsearch $entries $entry]] != "separator"  && [$self entrycget $index -state] == "active"} {
						$self EntryConfigureForeground $entry $value
					}
				}
			}
			d {
				set options(-disabledforeground) $value
				set options(-disabledfg) $value
				foreach entry $entries {
					set index [lsearch $entries $entry]
					if { [$self type $index] != "separator" && [$self entrycget $index -state] == "disabled"} {
						$self EntryConfigureForeground $entry $value
					}
				}
			}
			f {
				set options(-foreground) $value
				set options(-fg) $value
				foreach entry $entries {
					if { [$self type [lsearch $entries $entry]] != "separator" && [$self entrycget $index -state] == "normal" } {
						$self EntryConfigureForeground $entry $value
					}
				}
			}
		}
	}

	method EntryConfigureFont { id value } {
		$canvas itemconfigure $textid($id) -font $value
		$self sort
	}

	method EntryConfigureForeground { id value } {
		$canvas itemconfigure $textid($id) -fill $value
	}

	method EntryConfigureIndicator { id value } {
			switch [$config($id) type] {
				"checkbutton" {
					if { $value } {
						$canvas itemconfigure $imageid($id) -state normal
						if { [set [$config($id) cget -variable]] == [$config($id) cget -onvalue] } {
							$canvas itemconfigure $checktickid($id) -state normal
						}
					} else {
						$canvas itemconfigure $imageid($id) -state hidden
						$canvas itemconfigure $checktickid($id) -state hidden
					}
				}
				"radiobutton" {
					if { $value } {
						$canvas itemconfigure $imageid($id) -state normal
						if { [set [$config($id) cget -variable]] == [$config($id) cget -value] } {
							$canvas itemconfigure $radiotickid($id) -state normal
						}
					} else {
						$canvas itemconfigure $imageid($id) -state hidden
						$canvas itemconfigure $radiotickid($id) -state hidden
					}
				}
			}
			$self sort
	}

	method EntryConfigureState { id value } {
		switch $value {
			active { $canvas itemconfigure $textid($id) -fill $options(-activeforeground) }
			disabled { $canvas itemconfigure $textid($id) -fill $options(-disabledforeground) }
			normal { $canvas itemconfigure $textid($id) -fill $options(-foreground) }
		}
	}
}







# ---------------------------------
global order
global mVar
set mVar one

proc menutest { } {
	. configure -bg darkgreen
	#menushell .m
	menubar .m
	pack forget .main
	pack .m -fill x -side top
	.m add cascade -label File -menu .m.file
	.m add cascade -label Edit -menu .m.edit
	.m add cascade -label View -menu .m.view
	.m add cascade -label Settings -menu .m.settings

	menushell .m.file
	.m.file add command -label "Add contact"
	.m.file add command -label "Delete contact"
	.m.file add cascade -label "Invite contact" -menu .m.file.invite
	.m.file add separator
	.m.file add radiobutton -label "Order by name" -state disabled
	.m.file add radiobutton -label "Order by email"
	.m.file add radiobutton -label "Order by state"
	.m.file add separator
	.m.file add command -label "Exit"

	menushell .m.file.invite
	.m.file.invite add command -label "capricious.falcon@gmail.com"
	.m.file.invite add command -label "antndecrmine@hotmail.com"

	foreach m { edit view settings } {
		menushell .m.$m
		.m.$m add command -label command
	}

	

	rename menu tk_menu
	rename menushell menu
	rename menubutton tk_menubutton
	rename menubut menubutton
	###################################
	destroy [tk_optionMenu .1 a b]
	destroy .1
	###################################
	rename tk_optionMenu tk_tk_optionMenu
	rename optmenu tk_optionMenu

	#menubutton .opt -textvariable mVar -menu .opt.m
	#menu .opt.m
	#.opt.m add radiobutton -label "One" -value "One" -variable mVar
	#.opt.m add radiobutton -label "Two" -value "Two" -variable mVar
	#.opt.m add radiobutton -label "Three" -value "Two" -variable mVar

	tk_optionMenu .opt mVar one two three

	pack .opt
}
