variable MenuPosted
variable afterid
set MenuPosted {}
array set afterid {PostCascade {} UnpostCascade {}}

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
				set MenuPosted %W
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
			$containing postcascade $index
			set ::tk::Priv(menuBar) $containing
			#after 0 "$containing activate $index"
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
	if { $index == [$containing index active] } {
		break
	}
	switch $type {
		"menubar" {
			$containing activate $index 1
			set ::tk::Priv(menuBar) $containing
		}
		"normal" {
			# Don't "activate none" if a cascade is selected
			if { $index == "none" && [$containing type active] == "cascade" } {
				break
			} else {
				if { [$containing type $index] == "cascade" } {
					$containing activate $index 0
					after cancel $afterid(UnpostCascade)
					set afterid(PostCascade) [after [%W cget -cascadedelay] "$containing postcascade $index"]
				} else {
					after cancel $afterid(PostCascade)
					$containing activate $index 1
					set afterid(UnpostCascade) [after [%W cget -cascadedelay] "$containing postcascade none"]
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
	if { $index == [$containing index active] } {
		break
	}
	switch $type {
		"menubar" {
			if { $MenuPosted == "" } {
				$containing activate $index 0
			} else {
				$containing activate $index 1
			}
		}
		"normal" {
			# Don't "activate none" if a cascade is selected
			if { $index == "none" && [%W type active] == "cascade" } {
				break
			} else {
				if { [$containing type $index] == "cascade" } {
					$containing activate $index 0
					after cancel $afterid(UnpostCascade)
					set afterid(PostCascade) [after [%W cget -cascadedelay] "$containing postcascade $index"]
				} else {
					after cancel $afterid(PostCascade)
					$containing activate $index 1
					set afterid(UnpostCascade) [after [%W cget -cascadedelay] "$containing postcascade none"]
				}
			}
		}
	}
}

#bind Pixmapmenu <Enter> {
#	variable MenuPosted
#	variable afterid
#
#	set containing [MenuAtPoint %X %Y]
#	if { $containing == "none" } {
#		break
#	}
#	set type [$containing cget -type]
#	set x [RootXToX $containing %X]
#	set y [RootYToY $containing %Y]
#	set index [$containing index @${x},$y]
#
#	switch $type {
#		"menubar" {
#			if { $MenuPosted == "" } {
#				$containing activate $index 0
#			} else {
#				$containing activate $index 1
#			}
#		}
#		"normal" {
#			if { [$containing type $index] == "cascade" } {
#				$containing activate $index 0
#				after cancel $afterid(UnpostCascade)
#				set afterid(PostCascade) [after 500 "$containing postcascade $index"]
#			} else {
#				after cancel $afterid(PostCascade)
#				$containing activate $index 1
#				set afterid(UnpostCascade) [after 500 "$containing postcascade none"]
#			}
#		}
#	}
#}

bind Pixmapmenu <Leave> {
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
			if { $index == "none" } {
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
			[%W entrycget active -menu] activate last
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
			[%W entrycget active -menu] activate 0
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
	if { $type != "menubar" } {
		$::tk::Priv(menuBar) activate none
	}
	MenuUnpost $MenuPosted
	if { [%W type active] == "cascade" } {
		%W postcascade active
	} else {
		%W invoke active
	}
}

bind Pixmapmenu <space> {
	variable MenuPosted
	MenuUnpost $MenuPosted
	if { $type != "menubar" } {
		$::tk::Priv(menuBar) activate none
	}
	if { [%W type active] == "cascade" } {
		%W postcascade active
	} else {
		%W invoke active
	}
}

bind Pixmapmenu <Escape> {
	[winfo parent %W] unpost
}

# Procs
proc IsTopLevelMenu { w } {
	set parent [winfo parent $w]
	set ptype [$parent cget -type]
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
			return 1
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
	focus $w.m
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
	set ptype [$parent cget -type]
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
	if { $w == "none" } {
		return
	}
	set index [$w index @${x},$y]
	set itype [$w type $index]
	$w activate $index
	switch $itype {	
		"command" {
			MenuUnpost $w
			$w invoke $index
		}
		"checkbutton" {
			MenuUnpost $w
			$w invoke $index
		}
		"radiobutton" {
			MenuUnpost $w
			$w invoke $index	
		}
		"cascade" {
			$w postcascade $index
		}
	}
}

proc MenuUnpost { w } {
	variable MenuPosted

	if { $w == "" } {
		return
	}

	while {1} {
		set parent [winfo parent $w]
		set w $parent
		set ptype {}
		catch {set ptype [$parent cget -type]}
		switch $ptype {
			"" {
				break
			}
			"menubar" {
				$parent activate none
				break
			}
			"menubutton" {
				set ::tk::Priv(postedMb) {}
				$parent configure -state normal
				break
			}
			default {
				$parent unpost
			}
		}
	}
	set MenuPosted {}
}