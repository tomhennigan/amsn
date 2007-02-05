# Advanced configuration viewer.
# Version: 0.1; Released: 02/02/2007

namespace eval ::acv {
	################################################################
	# ::acv::init(dir)
	# Sets up the plugin. And binds our keystroke to draw the window.
	# Arguments:
	#	- dir => The path to the plugin folder. It is supplied by the plugins system.
	proc init { dir } {
		::plugins::RegisterPlugin "Advanced Configuration Viewer"
		if {[OnMac]} {
			bind all <Command-k> "::acv::drawACVWindow"
		} else {
			bind all <Control-k> "::acv::drawACVWindow"
		}	
	}
	
	################################################################
	# ::acv::deinit()
	# Called when the plugin is unloaded. Just clears up a few things.
	# Also unbinds the keystroke.
	proc deinit {} {
		if {[winfo exists .acvWindow]} {
			destroy .acvWindow
		}
		
		if {[OnMac]} {
			bind all <Command-k> ""
		} else {
			bind all <Control-k> ""
		}	
	}
	
	################################################################
	# ::acv::_alternate.listbox.colors(listWin, colList)
	# Taken from: http://wiki.tcl.tk/9561
	# Gives an alternating row background to a listbox.
	# Arguments:
	#	- listWin => The path to the list item.
	#	- colList => A list with the colors to alternate between.
	proc _alternate.listbox.colors {listWin colList} {
		if {![winfo exists $listWin]} {
			return -code error {invalid window path}
		}
		set listWinEnd [$listWin index end]
		set colCount 0
		set colListLength [llength $colList]
		for {set i 0} {$i < $listWinEnd} {incr i} {
			$listWin itemconfigure $i -background [lindex $colList $colCount]
			incr colCount
			if {$colCount >= $colListLength} {
				set colCount 0
			}
		}
	}
	
	################################################################
	# ::acv::_updateReadOnlyTextBox(textItemPath, newText)
	# Updates a read only text box item.
	# Arguments:
	#	- textItemPath => The path to the text box item.
	#	- newText => The text to replace the current text with.
	proc _updateReadOnlyTextBox {textItemPath newText} {
		${textItemPath} configure -state normal
		${textItemPath} delete 1.0 end
		${textItemPath} insert end $newText
		${textItemPath} configure -state disabled
	}
	
	################################################################
	# ::acv::_updateAlternatingList(listItemPath, newItems)
	# Helper function to update an alternating list box.
	# Arguments:
	#	- listItemPath => The path to the list box item.
	#	- newItems => A list of new items to set as the contents of the list item.
	proc _updateAlternatingList {listItemPath newItems} {
		${listItemPath} delete 0 end
		foreach {item} $newItems {
			${listItemPath} insert end $item
		}
		_alternate.listbox.colors ${listItemPath} [list white #edf3fe]
	}
	
	################################################################
	# ::acv::setCommandValue(newDescription)
	# Set the value of the text box to newDescription.
	# Arguments:
	# 	- newDescription => A string with the value of the current command.
	proc setCommandValue {newDescription} {
		upvar 1 w w
		_updateReadOnlyTextBox .acvWindow.t $newDescription
	}
	
	################################################################
	# ::acv::setCommandsList(newList)
	# Set the commands list box to the value of newList.
	# Arguments:
	# 	- newList => A list with the new values to set in the available commands list.
	proc setCommandsList {newList} {
		upvar 1 w w
		_updateAlternatingList ${w}.l $newList
	}

	################################################################
	# ::acv::drawACVWindow()
	# Draw the window for the application.
	proc drawACVWindow { } {
		if {[winfo exists .acvWindow]} {
			setCommandValue [::config::getKey [.acvWindow.l get active]]
			raise .acvWindow
			return
		}
		
		set w [toplevel .acvWindow]
		wm title $w "Advanced Configuration Viewer"
		listbox $w.l -listvariable theList -font LucidaGrande \
			-height 90 -width 30 -yscrollcommand "$w.listbox_scroll set"
		pack $w.l -side left
		scrollbar $w.listbox_scroll -command "$w.l yview" -width 16 -highlightthickness 0
		pack $w.listbox_scroll -side left -fill y
		bind $w.l <Double-B1-ButtonRelease> {::acv::setCommandValue [::config::getKey [.acvWindow.l get active]]}
		
		# Draw the text widget.
		text $w.t -yscrollcommand "$w.scroll set" \
		        -width 70 -height 100 -wrap word -font LucidaGrande -highlightthickness 0 
		scrollbar $w.scroll -command "$w.t yview" -width 16
		pack $w.scroll -side right -fill y
		pack $w.t -expand yes -fill both
		#bind $w.t <Double-B1-ButtonRelease> {::acv::editCommandValue [.acvWindow.l get active]}
		
		wm geometry $w 600x300+20+40
		
		# Set up the view in the listbox and text widget.
		setCommandValue "Please choose a variable from the list on the left."
		setCommandsList [lsort -dictionary [::config::getKeys]]
	}
}
