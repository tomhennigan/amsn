variable MenuPosted
variable afterid
set MenuPosted {}
array set afterid {PostCascade {} UnpostCascade {}}
set ::tk::Priv(cursor) left_ptr

# Alt binding for all
# TODO: handle things ok if when we restore focus, the window that we restore to has been destroyed...
bind all <Alt_L> {
	variable MenuPosted
	set fw [focus]
	set ftype {}
	if { $fw != "" && $fw != "." } {
		if { [winfo class [winfo parent $fw]] == "Menu" } {
			set ftype [$fw cget -type]
		}
	}

	switch $ftype {
		menubar {
			$fw activate none
			RestoreFocus
			set ::tk::Priv(menuBar) {}
		}
		normal {
			
		}
		default {
			if { $::tk::Priv(menuBar) == "" } {
				set ::tk::Priv(focus) $fw
				Alt [winfo toplevel %W]
			}
		}
	}
	
	#{} elseif { $MenuPosted == "" } {
		
	#} elseif { $ftype == "menubar" } {
		
	#}
}

# -----------------------------------------------------
#  Menubar and Menu bindings
#
# Jommetry
bind Pixmapmenu <Configure> {
	%W Configure %w %h
}

bind Pixmapmenu <Map> {
	variable MenuPosted
	switch [%W cget -type] {
		menubar {
			
		}
		normal {
			if { [IsTopLevelMenu [winfo parent %W]] } {
				# If no menu is posted, set MenuPosted to this menu
				if { $MenuPosted != "" } {
					set MenuPosted %W
				} else {
					set MenuPosted %W
				}
				set ::tk::Priv(focus) [focus -displayof .]
				set ::tk::Priv(oldGrab) [grab current]
				if { $::tk::Priv(oldGrab) != "" } {
					if { [grab status $::tk::Priv(oldGrab)] == "global" } {
						set ::tk::Priv(grabGlobal) -global
					}
				}
				grab -global %W
			}
			MenuFocus [winfo parent %W]
		}
	}
}

bind Pixmapmenu <Unmap> {
	grab release %W
	%W activate none
	%W postcascade none
	if { ![IsTopLevelMenu %W] } {
		MenuFocus [winfo parent [winfo parent %W]]
	}
}

# Mouse
bind Pixmapmenu <ButtonPress> {
	variable MenuPosted
	variable afterid

	set containing [MenuAtPoint %X %Y]
	if { $containing == "none" } {
		break
	}
	set type [$containing cget -type]
	set x [RootXToX $containing %X]
	set y [RootYToY $containing %Y]
	set index [$containing index @${x},$y]
	switch $type {
		"menubar" {
			if { $::tk::Priv(popup) == "" && $index != "none" } {
				if { $::tk::Priv(menuBar) == "" || $::tk::Priv(menuBar) == $containing } {
					$containing postcascade $index
					set ::tk::Priv(menuBar) $containing
					after 0 "$containing activate $index"
				}
			}
		}
		"normal" {
			after cancel $afterid(UnpostCascade)
			$containing postcascade $index
		}
	}
}

bind Pixmapmenu <B1-Motion> {
	variable MenuPosted
	variable afterid

	set containing [MenuAtPoint %X %Y]
	if { $containing == "none" } {
		break
	}
	set type [$containing cget -type]
	set x [RootXToX $containing %X]
	set y [RootYToY $containing %Y]
	set index [$containing index @${x},$y]
	switch $type {
		"menubar" {
			if { $::tk::Priv(popup) == "" && $index != "none" } {
				if { $::tk::Priv(menuBar) == "" || $::tk::Priv(menuBar) == $containing } {
					set ::tk::Priv(menuBar) $containing
					$containing activate $index 1
				}
			}
		}
		"normal" {
			# Don't "activate none" if a cascade is selected
			if { $index == "none" && [$containing type active] == "cascade" } {
				break
			} else {
				if { [$containing type $index] == "cascade" && [$containing entrycget $index -state] != "disabled" } {
					if { $index != [$containing index active] } {
						after cancel $afterid(UnpostCascade)
						set afterid(PostCascade) [after [%W cget -cascadedelay] "$containing postcascade $index"]
					}
					$containing activate $index 0
				} else {
					if { $index != [$containing index active] } {
						after cancel $afterid(PostCascade)
						set afterid(UnpostCascade) [after [%W cget -cascadedelay] "$containing postcascade none"]
					}
					$containing activate $index 1
				}
			}
		}
	}
}

bind Pixmapmenu <Motion> {
	variable MenuPosted
	variable afterid

	set containing [MenuAtPoint %X %Y]
	if { $containing == "none" } {
		break
	}
	set type [$containing cget -type]
	set x [RootXToX $containing %X]
	set y [RootYToY $containing %Y]
	set index [$containing index @${x},$y]
	switch $type {
		"menubar" {
			if { $::tk::Priv(popup) == "" && $index != "none" } {
				if { $::tk::Priv(menuBar) == "" || $::tk::Priv(menuBar) == $containing } {
					if { $MenuPosted == "" } {
						$containing activate $index 0
					} else {
						$containing activate $index 1
						set ::tk::Priv(menuBar) $containing
					}
				}
			}
		}
		"normal" {
			# Don't "activate none" if a cascade is selected
			if { $index == "none" && [$containing type active] == "cascade" } {
				break
			} else {
				if { [$containing type $index] == "cascade" && [$containing entrycget $index -state] != "disabled" } {
					if { $index != [$containing index active] } {
						after cancel $afterid(PostCascade)
						after cancel $afterid(UnpostCascade)
						set afterid(PostCascade) [after [%W cget -cascadedelay] "$containing postcascade $index"]
					}
					$containing activate $index 0
				} else {
					if { $index != [$containing index active] } {
						after cancel $afterid(PostCascade)
						set afterid(UnpostCascade) [after [%W cget -cascadedelay] "$containing postcascade none"]
					}
					$containing activate $index 1
				}
			}
		}
	}
}

bind Pixmapmenu <Enter> {
	variable MenuPosted
	variable afterid

	set containing [MenuAtPoint %X %Y]
	if { $containing == "none" } {
		break
	}
	set type [$containing cget -type]
	set x [RootXToX $containing %X]
	set y [RootYToY $containing %Y]
	set index [$containing index @${x},$y]

	set parent [winfo parent [winfo parent %W]]
	set ptype {}
	catch {set ptype [$parent cget -type]}

	switch $type {
		"menubar" {

		}
		"normal" {

		}
	}
}

bind Pixmapmenu <Leave> {
	if { [%W cget -type] == "menubar" && [MenuAtPoint %X %Y] != "%W" } {
		%W activate none
	}
}

bind Pixmapmenu <B1-Leave> {
	variable MenuPosted
	variable afterid

	after cancel $afterid(PostCascade)

	set type [%W cget -type]
	set active [%W index active]
	set atype [%W type @%x,%y]
	switch $type {
		"menubar" {
			if { $MenuPosted == "" } {
				%W activate none
			}
		}
		"normal" {
			if { $atype != "cascade" } {
				%W activate none
			}
		}
	}
}

bind Pixmapmenu <ButtonRelease> {
	variable MenuPosted

	set containing [MenuAtPoint %X %Y]
	if { $containing == "none" } {
		MenuUnpost %W
		break
	}
	set x [RootXToX $containing %X]
	set y [RootYToY $containing %Y]
	set index [$containing index @${x},$y]
	set type [$containing cget -type]
	switch $type {
		menubar {
			if { $index == "none" && $MenuPosted != "" } {
				MenuUnpost $MenuPosted
			}
		}
		normal {
			MenuInvoke $containing [RootXToX $containing %X] [RootYToY $containing %Y]
		}
	}
}

# Keyboard
bind Pixmapmenu <Up> {
	set type [%W cget -type]
	switch $type {
		menubar {
			%W postcascade active
			set m [%W entrycget active -menu]
			if { $m != "" } {
				set ::tk::Priv(menuBar) [winfo parent %W]
				MenuLastEntry $m
			}
		}
		normal {
			MenuNextEntry %W -1
		}
	}
}

bind Pixmapmenu <Down> {
	set type [%W cget -type]
	switch $type {
		menubar {
			%W postcascade active
			set m [%W entrycget active -menu]
			if { $m != "" } {
				set ::tk::Priv(menuBar) [winfo parent %W]
				MenuFirstEntry $m
			}
		}
		normal {
			MenuNextEntry %W 1
		}
	}
}

bind Pixmapmenu <Left> {
	set type [%W cget -type]
	switch $type {
		menubar {
			MenuNextEntry %W -1
		}
		normal {
			MenuNextMenu [winfo parent %W] -1
		}
	}
}

bind Pixmapmenu <Right> {
	set type [%W cget -type]
	switch $type {
		menubar {
			MenuNextEntry %W 1
		}
		normal {
			MenuNextMenu [winfo parent %W] 1
		}
	}
}

bind Pixmapmenu <Return> {
	variable MenuPosted
	set type [%W cget -type]
	if { [%W type active] == "cascade" } {
		%W postcascade active
	} else {
		%W invoke active
	}
	MenuUnpost $MenuPosted
}

bind Pixmapmenu <space> {
	variable MenuPosted
	if { [%W type active] == "cascade" } {
		%W postcascade active
	} else {
		%W invoke active
	}
	MenuUnpost $MenuPosted
}

bind Pixmapmenu <Escape> {
	set shell [winfo parent %W]
	set parent [winfo parent $shell]
	set type {}
	catch {set type [$shell cget -type]}
	set ptype {}
	catch {set ptype [$parent cget -type]}
	set active {}
	catch {set active [$parent index active]}
	switch $type {
		normal {
			if { [IsTopLevelMenu $shell] } {
				MenuUnpost $MenuPosted
			} else {
				$shell unpost
			}
			# Activate the entry the menu was posted from (but don't post the menu again, obviously)
			if { $ptype != "" } {
				$parent activate $active
			}
		}
		menubar {
			set ::tk::Priv(menuBar) {}
			# Restore focus
			if { $::tk::Priv(focus) == "" } {
				focus [winfo toplevel %W]
			} else {
				RestoreFocus
			}
			set ::tk::Priv(focus) {}
			# Activate none
			%W activate none
		}
	}
}

# Procs
proc IsTopLevelMenu { w } {
	set parent [winfo parent $w]
	set ptype {}
	catch { set ptype [$parent cget -type] }
	switch $ptype {
		menubar {
			return 1
		}
		menubutton {
			return 1
		}
		normal {
			return 0
		}
		default {
			if { $::tk::Priv(popup) == $w } {
				return 1
			} else {
				return 0
			}
		}
	}
}

proc MenuAtPoint { X Y } {
	set w [winfo containing $X $Y]
	set type {}
	catch { set type [$w cget -type] }
	if { $type == "" || $type == "menubutton" } {
		return none
	} else {
		return $w
	}
}

proc RootXToX { w X } {
	if { $w == "none" } {
		return
	}
	return [expr {$X - [winfo rootx $w]}]
}

proc RootYToY { w Y } {
	if { $w == "none" } {
		return
	}
	return [expr {$Y - [winfo rooty $w]}]
}

proc MenuFocus { w } {
	if { [winfo exists $w.m] } {
		set ::tk::Priv(focus) [focus]
		focus $w.m
	}
}

proc MenuFirstEntry { w } {
	$w activate none
	MenuNextEntry $w 1
}

proc MenuLastEntry { w } {
	$w activate none
	MenuNextEntry $w -1
}

proc MenuNextEntry { w direction } {
	variable MenuPosted

	set type [$w cget -type]
	set index [$w index active]
	set last [$w index last]
	if { $index == "none" } {
		if { $direction == 1 } {
			set index -1
		} elseif { $direction == -1 } {
			set index [incr last 1]
		}
	}
	set newindex [incr index $direction]
	while { 1 } {
		set itype [$w type $newindex]
		set state [$w entrycget $newindex -state]
		if { $newindex > $last } {
			set newindex 0
		} elseif { $newindex < 0 } {
			set newindex $last
		}
		if { $state == "disabled" || $itype == "separator" } {
			incr newindex $direction
			continue
		} else {
			if { $type == "menubar" && $MenuPosted != "" } {
				$w activate $newindex 1
			} else {
				$w activate $newindex
			}
			break
		}
	}
}

proc MenuNextMenu { w direction } {
	set parent [winfo parent $w]
	set ptype {}
	catch {set ptype [$parent cget -type]}
	if { $ptype == "" } {
		return
	}
	if { [IsTopLevelMenu $w] } {
		if { [$w type active] == "cascade" } {
			if { $direction == 1 } {
				$w postcascade active
			} elseif { $direction == -1 } {
				$w unpost
			}
		} else {
			switch $ptype {
				menubar {
					set active [$parent index active]
					MenuNextEntry $parent $direction
				}
			}
		}
	} else {
		if { [$w type active] == "cascade" } {
			if { $direction == 1 } {
				$w postcascade active
			} elseif { $direction == -1 } {
				$w postcascade none
			}
		} elseif { $direction == -1 } {
			$w unpost
		}
	}
}

proc MenuInvoke { w x y } {
	variable MenuPosted
	variable afterid

	if { $w == "none" || $w == "" } {
		return
	}
	set index [$w index @${x},$y]
	set itype [$w type $index]
	$w activate $index
	switch $itype {	
		"command" {
			if { $MenuPosted != "" } {
				MenuUnpost $MenuPosted
			} else {
				MenuUnpost $w
			}
			$w invoke $index
		}
		"checkbutton" {
			if { $MenuPosted != "" } {
				MenuUnpost $MenuPosted
			} else {
				MenuUnpost $w
			}
			$w invoke $index
		}
		"radiobutton" {
			if { $MenuPosted != "" } {
				MenuUnpost $MenuPosted
			} else {
				MenuUnpost $w
			}
			$w invoke $index	
		}
		"cascade" {
			$w postcascade $index
		}
	}
	after cancel $afterid(PostCascade)
}

proc MenuUnpost { w } {
	variable MenuPosted

	if { $w == "" } {
		return
	}

	# Restore focus immediately
	status_log "(MenuUnpost $w) restoring focus to $::tk::Priv(focus)"
	RestoreFocus

	while {1} {
		set parent [winfo parent $w]
		set ptype {}
		catch {set ptype [$parent cget -type]}
		switch $ptype {
			"" {
				if { $MenuPosted == $w } {
					break
				} else {
					set ptype {}
					catch {set ptype [[winfo parent $MenuPosted] cget -type]}
					if { $ptype == "normal" && $MenuPosted != "" } {
						[winfo parent $MenuPosted] unpost
					}
					break
				}
			}
			"menubar" {
				$parent activate none
				set ::tk::Priv(menuBar) {}
				break
			}
			"menubutton" {
				set ::tk::Priv(postedMb) {}
				$parent configure -state normal
				break
			}
			normal {
				if { $MenuPosted != "" } {
					[winfo parent $MenuPosted] unpost
				}
			}
			default {
				if { $ptype == "normal" } {
					$parent unpost
				}
			}
		}
		# Move up to next menu
		set w $parent
	}

	# Blank 'menu posted'-related variables
	set ::tk::Priv(popup) {}
	set MenuPosted {}
	# Restore grab
	if { $::tk::Priv(oldGrab) != "" } {
		if { [winfo ismapped $::tk::Priv(oldGrab)] && [winfo class $::tk::Priv(oldGrab)] != "Menubutton"} {
			grab $::tk::Priv(grabGlobal) $::tk::Priv(oldGrab)
		}
		set ::tk::Priv(oldGrab) {}
		set ::tk::Priv(grabGlobal) {}
	}
}

proc Alt { w } {
	set windowlist [winfo child $w]
	foreach child $windowlist {
		# Don't descend into other toplevels
		if {[string compare [winfo toplevel $w] [winfo toplevel $child]]} {
		continue
		}
		if {[string equal [winfo class $child] "Menu"] && [string equal [$child cget -type] "menubar"]} {
			set ::tk::Priv(menuBar) $child
			MenuFirstEntry $child
			MenuFocus $child
			break
		}
	}
}

proc RestoreFocus { } {
	if { [winfo exists $::tk::Priv(focus)] } {
		focus $::tk::Priv(focus)
	} else {
		focus .
	}
}