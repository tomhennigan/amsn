# o-----------------------------------------------------
#  Search dialog widget.
#  By Tom Jenkins (bluetit) 31/01/06
#  Searches a given text widget for text.
#  -searchin w - specifies text widget to search
# o-----------------------------------------------------
snit::widget searchdialog {

	# The text widget to search
	option -searchin -configuremethod SetSearchIn
	option -title -default Find

	# We want to create a toplevel to put stuff in
	hulltype toplevel

	# Various widget components
	component top
	component middle
	component bottom
	component entry
	component case
	component up
	component down
	component regexp
	component nextbutton
	component prevbutton
	component closebutton

	# Search optinos
	variable matchcase
	variable searchdirect
	variable useregexpsearch

	# Index variable
	variable index
	#variable length

	constructor { args } {
		# Initial values
		set index 0.0
		set matchcase 0
		set searchdirect down
		set regexp 0

		$self configurelist $args
		# Check we have a text widget
		if { $options(-searchin) == {} } {
			error "no text widget specified to search in"
		}

		wm title $win $options(-title)

		# Install widget components
		install top using labelframe $self.t -text Find
		install middle using labelframe $self.m -text Options
		install bottom using frame $self.b
		install entry using entry $top.e -bg white -fg black
		install case using checkbutton $middle.c -text "Case sensitive" -variable [myvar matchcase]
		install up using radiobutton $middle.u -text "Search up" -variable [myvar searchdirect] -value up
		install down using radiobutton $middle.d -text "Search down" -variable [myvar searchdirect] -value down
		install regexp using checkbutton $middle.r -text "Use as regular expression" -variable [myvar useregexpsearch]
		install nextbutton using button $bottom.n -text "Find next" -command "$self FindNext"
		install prevbutton using button $bottom.p -text "Find previous" -command "$self FindPrev"
		install closebutton using button $bottom.c -text "Close" -command "destroy $self"

		# Pack them
		pack $top $middle $bottom -side top -expand true -fill both -padx 3m -pady 2m
		pack $case $up $down $regexp -anchor w -side top -padx 3m -pady 1m
		pack $entry -anchor w -expand true -fill x -side left -padx 3m
		pack $nextbutton $prevbutton $closebutton -anchor w -padx 1m -side right

		bindtags $self "Toplevel SearchDialog . all"
		bind $entry <Return> "$self FindNext"
		bind $entry <Escape> "destroy $self"
	}

	destructor {
		catch {
			# Delete the 'search' tag on the text widget
			$options(-searchin) tag delete search
		}
	}

	method SetSearchIn { option value } {
		# Delete the 'search' tag on the old text widget
		if { $options(-searchin) != {} } {
			$options(-searchin) delete tag search
		}
		set options(-searchin) $value
		# Create the 'search' tag on the text widget
		$value tag configure search -background #447bcd -foreground white
		# Make sure when the text widget is clicked, the search highlight disappears
		bind $value <ButtonPress> "+$value tag remove search 0.0 end"
	}

	method FindNext { } {
		# What search options are we using?
		set args {}
		if { !$matchcase } {
			lappend args -nocase
		}
		if { [string equal $searchdirect up] } {
			lappend args -backwards
		} else {
			lappend args -forwards
		}
		if { $useregexpsearch } {
			lappend args -regexp
		}

		# Do the search
		$self DoSearch $args
	}

	method FindPrev { } {
		# What search options are we using?
		set args {}
		if { !$matchcase } {
			lappend args -nocase
		}
		if { [string equal $searchdirect up] } {
			lappend args -forwards
		} else {
			lappend args -backwards
		}
		if { $useregexpsearch } {
			lappend args -regexp
		}

		# Do the search
		$self DoSearch $args
	}

	method DoSearch { argz } {
		# Un-highlight previous selection
		$options(-searchin) tag remove search 0.0 end
		$options(-searchin) tag remove sel 0.0 end
		# Get the search pattern
		set pattern [$entry get]
		# Get the index of the next occurence of the pattern in the text widget
		set index [eval $options(-searchin) search -count length $argz -- $pattern $index]
		# Stop if there's no matches
		if { $index == {} } {
			return
		}
		# Highlight and scroll to the match
		$options(-searchin) tag add search $index "$index + $length char"
		$options(-searchin) see search.first
		# If we're searching forwards, move the search index just past the current match, so we get the next match next time
		if { [lsearch $argz -forwards] != -1 } {
			set index [$options(-searchin) index "$index + $length char"]
		}
	}
}

bind SearchDialog <Return> {
	%W FindNext
}

bind SearchDialog <Escape> {
	destroy %W
}

#  Amsn-specific code
# o-----------------------------------
#  CreateSearchDialog
#  Creates a search dialog for a chatwindow
#  w - path of the chatwindow's container
proc CreateChatSearchDialog { w } {
	if { [winfo exists $w.search] } {
		raise $w.search
	} else {
		searchdialog $w.search -searchin [::ChatWindow::GetOutText [::ChatWindow::GetCurrentWindow $w]]
	}
}

# o-----------------------------------
#  SearchDialogNext
#  Tells a chatwindow's search dialog to do a FindNext
#  w - path of the chatwindow's container
proc ChatSearchNext { w } {
	if { [winfo exists $w.search] } {
		$w.search FindNext
	} else {
		CreateChatSearchDialog $w
	}
}

# o-----------------------------------
#  SearchDialogPrev
#  Tells a chatwindow's search dialog to do a FindPrev
#  w - path of the chatwindow's container
proc ChatSearchPrev { w } {
	if { [winfo exists $w.search] } {
		$w.search FindPrev
	} else {
		CreateChatSearchDialog $w
	}
}