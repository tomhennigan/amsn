# o-----------------------------------------------------
#  Search dialog widget.
#  By Tom Jenkins (bluetit) 31/01/06
#  Searches a given text widget for text.
#  -searchin w - specifies text widget to search
#  -title str - specifies window title for dialog
# o-----------------------------------------------------
snit::widget searchdialog {

	option -searchin -configuremethod SetSearchIn ;# The text widget to search
	option -title -default [trans find]

	delegate option * to hull

	# We want to create a toplevel to put stuff in
	hulltype toplevel

	# Various widget components
	component top
	component middle
	component bottom
	component entry
	component case
	component asyoutypeit
	component up
	component down
	component regexp
	component regexplabel
	component nextbutton
	component prevbutton
	component closebutton

	# Search options
	variable matchcase
	variable useasyoutype
	variable searchdirect
	variable useregexp

	# Index variable
	variable index
	variable curlength
	variable curpattern

	constructor { args } {
		# Initial values
		set index 0.0
		set curlength 0
		set pattern {}
		set curpattern {}
		set matchcase 0
		set useasyoutype 1
		set searchdirect down
		set useregexp 0

		$self configurelist $args

		wm title $win $options(-title)

		# Install widget components
		install top using labelframe $self.t -text [trans find]
		install middle using labelframe $self.m -text [trans options]
		install bottom using frame $self.b
		install entry using entry $top.e -bg white -fg black
		install asyoutypeit using checkbutton $middle.a -text [trans findasyoutype] -variable [myvar useasyoutype]
		install case using checkbutton $middle.c -text [trans casesensitive] -variable [myvar matchcase]
		install up using radiobutton $middle.u -text [trans searchup] -variable [myvar searchdirect] -value up
		install down using radiobutton $middle.d -text [trans searchdown] -variable [myvar searchdirect] -value down
		install regexp using checkbutton $middle.r -text [trans useasregexp] -variable [myvar useregexp]
		install regexplabel using label $middle.l -fg #ee0000
		install nextbutton using button $bottom.n -text [trans findnext] -command "$self findnext" -default active
		install prevbutton using button $bottom.p -text [trans findprev] -command "$self findprev"
		install closebutton using button $bottom.c -text [trans close] -command "$self hide"

		# Pack them
		pack $top $middle $bottom -side top -expand true -fill both -padx 3m -pady 2m
		pack $case $asyoutypeit $regexp $up $down -anchor w -side top -padx 3m -pady 1m
		pack $entry -anchor w -expand true -fill x -side left -padx 3m
		pack $nextbutton $prevbutton $closebutton -anchor w -padx 1m -side right

		bindtags $self "Toplevel SearchDialog . all"
		bind $entry <KeyRelease> "$self EntryChanged %K"
		bind $entry <Return> "$self findnext"
		bind $entry <<Escape>> "$self hide"
		bind $self <Map> "focus $entry"

		# We don't want the user to destroy the window by clicking close button, hide it instead
		wm protocol $self WM_DELETE_WINDOW "$self hide"
	}

	destructor {
		catch {
			# Delete the 'search' tag on the text widget
			$options(-searchin) tag delete search
		}
	}

	method bindwindow { w } {
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			bind $w <Command-f> "$self show"
			bind $w <Command-F> "$self show"
			bind $w <Command-G> "$self findnext"
			bind $w <Command-g> "$self findnext"
			bind $w <Command-Shift-g> "$self findprev"
			bind $w <Command-Shift-G> "$self findprev"
		} else {
			bind $w <Control-f> "$self show"
			bind $w <Control-F> "$self show"
			bind $w <F3> "$self findnext"
			bind $w <Shift-F3> "$self findnext"
		}

		# Shift-F* bindings are weird on some XFree86 versions, and instead of Shift-F(n), we get XF86_Switch_VT_(n)
		# We allow for this here
		if { ![catch {tk windowingsystem} wsystem] && $wsystem  == "x11" } {
			bind $w <XF86_Switch_VT_3> "$self findprev"
		}
	}

	method show { } {
		wm deiconify $self
		raise $self
	}
	
	method hide { } {
		wm withdraw $self
	}

	method SetSearchIn { option value } {
		# Delete the 'search' tag on the old text widget (catch it in case the widget got destroyed)
		catch {
			if { $options(-searchin) != {} } {
				$options(-searchin) tag remove search 0.0 end
				$options(-searchin) tag delete search
			}
		}
		set options(-searchin) $value
		# Create the 'search' tag on the text widget
		$value tag configure search -background [$value tag cget sel -background] -foreground white
		# Make sure when the text widget is clicked, the search highlight disappears
		bind $value <ButtonPress> "+$value tag remove search 0.0 end"
	}

	method EntryChanged { {key {}} } {
		set str [$entry get]
		if { $key == "Return" || $str == $curpattern } {
			return
		} elseif { $useasyoutype } {
			$self findnext
		}
	}

	method findnext { } {
		# Raise window and stop if we have an empty pattern
		if { [$entry get] == {} } {
			place forget $regexplabel
			$options(-searchin) tag remove search 0.0 end
			$self show
			return
		}
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
		if { $useregexp } {
			lappend args -regexp
		}

		# Do the search
		$self DoSearch $args
	}

	method findprev { } {
		# Raise window and stop if we have an empty pattern
		if { [string trim [$entry get]] == {} } {
			place forget $regexplabel
			$options(-searchin) tag remove search 0.0 end
			$self show
			return
		}
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
		if { $useregexp } {
			lappend args -regexp
		}

		# Do the search
		$self DoSearch $args
	}

	method DoSearch { argz } {
		# Un-highlight previous selection
		$options(-searchin) tag remove search 0.0 end
		$options(-searchin) tag remove sel 0.0 end
		# If we're searching backwards, we need to skip back BEFORE the last match found..
		if { [lsearch $argz -backwards] != -1 } {
			set index [$options(-searchin) index "$index - [expr {$curlength + 1}] char"]
		}
		# Get the search pattern
		set pattern [$entry get]
		# If the pattern changed, search from beginning
		if { $pattern != $curpattern } {
			set index 0.0
		}
		# Store pattern for the next search
		set curpattern $pattern
		# Get the index of the next occurence of the pattern in the text widget
		if { $useregexp } {
			if { [catch {set index [eval $options(-searchin) search -count length $argz -- {[set pattern]} $index]}] != 0 } {
				$regexplabel configure -text [trans invalidregexp]
				place $regexplabel -anchor w -in $regexp -relx 1.0 -x 5 -rely 0.5
				return
			} else {
				$regexplabel configure -text {}
				place forget $regexplabel
			}
		} else {
			set index [eval $options(-searchin) search -count length $argz -- {[set pattern]} $index]
		}
		# Store length for the next search
		if { [info exists length] && $length > 0 } {
			set curlength $length
		} else {
			# Stop if there's no matches (also reset index to 0.0)
			set index 0.0
			return
		}
		# Highlight and scroll to the match
		$options(-searchin) tag add search $index "$index + $length char"
		status_log "(searchdialog.tcl)index $index length $length"
		$options(-searchin) see search.first
		# Move the search index just past the current match, so we get the next match next time
		set index [$options(-searchin) index "$index + $length char"]
	}
}

	bind SearchDialog <<Escape>> {
		destroy %W
	}



bind SearchDialog <Return> {
	%W findnext
}
