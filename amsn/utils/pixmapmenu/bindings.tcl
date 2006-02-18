variable MenuPosted
variable afterid
set MenuPosted {}
array set afterid {PostCascade {} UnpostCascade {}}

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
		}
	}
}

bind Pixmapmenu <Unmap> {
	grab release %W
	%W activate none
	%W postcascade none
}

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
			$containing activate $index 1
		}
		"normal" {
			if { [$containing type $index] == "cascade" } {
				$containing activate $index 0
				after cancel $afterid(UnpostCascade)
				set afterid(PostCascade) [after 500 "$containing postcascade $index"]
			} else {
				after cancel $afterid(PostCascade)
				$containing activate $index 1
				set afterid(UnpostCascade) [after 500 "$containing postcascade none"]
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
			if { $index == "none" && [$containing type active] == "cascade" } {
				break
			} else {
				if { [$containing type $index] == "cascade" } {
					$containing activate $index 0
					after cancel $afterid(UnpostCascade)
					set afterid(PostCascade) [after 500 "$containing postcascade $index"]
				} else {
					after cancel $afterid(PostCascade)
					$containing activate $index 1
					set afterid(UnpostCascade) [after 500 "$containing postcascade none"]
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
	switch $type {
		"menubar" {
			if { $MenuPosted == "" } {
				$containing activate $index 0
			} else {
				$containing activate $index 1
			}
		}
		"normal" {
			if { [$containing type $index] == "cascade" } {
				$containing activate $index 0
				after cancel $afterid(UnpostCascade)
				set afterid(PostCascade) [after 500 "$containing postcascade $index"]
			} else {
				after cancel $afterid(PostCascade)
				$containing activate $index 1
				set afterid(UnpostCascade) [after 500 "$containing postcascade none"]
			}
		}
	}
}

bind Pixmapmenu <Leave> {
	variable MenuPosted

	set type [%W cget -type]
	set active [%W index active]
	set atype [%W type $active]
	switch $type {
		"menubar" {
			if { $atype != "cascade" || $MenuPosted == "" } {
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



proc IsTopLevelMenu { w } {
	set parent [winfo parent $w]
	set ptype [$parent cget -type]
	switch $ptype {
		menubar {
			return 1
		}
		normal {
			return 0
		}
	}
}

proc MenuAtPoint { X Y } {
	set w [winfo containing $X $Y]
	set type {}
	catch { set type [$w cget -type] }
	if { $type == "" } {
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

proc MenuInvoke { w x y } {
	if { $w == "none" } {
		return
	}
	set index [$w index @${x},$y]
	set itype [$w type $index]
	$w activate $index
	$w invoke $index
	switch $itype {
		"command" {
			MenuUnpost $w
		}
		"checkbutton" {
			MenuUnpost $w
		}
		"radiobutton" {
			MenuUnpost $w
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
			default {
				$parent unpost
			}
		}
	}
	set MenuPosted {}
}