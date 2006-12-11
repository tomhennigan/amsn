########################################################################
#  amsncore.tcl :: core aMSN API
#
#  In this file we put some functions that is aMSN core functionality.
#  This means it is not about the GUI as these should become pluggable,
#  not about the protocol (protocol/p2p/webcam/...), not about extra 
#  widgets or functionality (should be in utils as a package) or about
#  the contacts database.
#  Code in here shouldn't depend on anything of the used GUI or protocol
#  implementation.  All functions should be some kind of API that can be
#  used througout aMSN and functionality to glue together several (plugg
#  able) gui/protocol implementations.
#
#  Messing with this file is messing with the best (tm).  Keep it read-
#  able and clear!  You are warned :).
#
#########################################################################

################################################
# The events system, used to communicate       #
# between different components (UI / protocol  #
# ... )                                        #
################################################
namespace eval ::Event {

	variable eventsArray

	# sends to all interested listeners the event that occured
	# eventName: name of the event that happened
	# caller:    the object that fires the event, set to all to
	#            notify all listeners for all events with that name
	proc fireEvent { eventName caller args } {
		variable eventsArray
		#fire events registered for both the current caller and 'all'
		foreach call [list $caller "all"] {
			#first check there were some events registered to caller or it will fail
			if { [array names eventsArray "$eventName,$call"] == "$eventName,$call" } {
				foreach listener [set eventsArray($eventName,$call)] {
					set call [linsert $args 0 $listener $eventName]
					eval $call
				}
			}
		}
	}

	# registers a listener for an event
	# the listener has to have a method the same as the eventName
	# eventName: name of the event to listen to
	# caller:    the object that fires the event, set to all to
	#            register for all events with that name
	# listener:  the object that wants to receive the events
	proc registerEvent { eventName caller listener } {
		variable eventsArray
		lappend eventsArray($eventName,$caller) $listener
	}
	
	proc unregisterEvent { eventName caller listener } {
		variable eventsArray
		set idx [lsearch [lindex [array get eventsArray "$eventName,$caller"] 1] $listener]
		if { $idx != -1 } {
			set eventsArray($eventName,$caller) [lreplace $eventsArray($eventName,$caller) $idx $idx]
		} else {
			status_log "ERROR: tried to unregister an unexistant event: $eventName,$caller" white
		}
			
	}
}


################################################
# Functions to know which platform we're on    #
################################################

#Test for Aqua GUI
proc OnMac {} {
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		return 1
	} else {
		return 0
	}
}

#Test for Darwin OS
#Will return 1 for X11 on Mac, OnMac returns 0 in that case
proc OnDarwin {} {
	global tcl_platform
	if { $tcl_platform(os) == "Darwin" } {
		return 1
	} else {
		return 0
	}
}

#Test for Windows
proc OnWin {} {
	global tcl_platform
	if { $tcl_platform(platform) == "windows" } {
		return 1
	} else {
		return 0
	}
}

#Test for Linux
proc OnLinux {} {
	global tcl_platform
	if { $tcl_platform(os) == "Linux" } {
		return 1
	} else {
		return 0
	}
}

#Test for Unix platform (Linux/Mac/*BSD/etc.)
proc OnUnix {} {
	global tcl_platform
	if { $tcl_platform(platform) == "unix" } {
		return 1
	} else {
		return 0
	}
}

#Test for X11 windowing system
proc OnX11 {} {
	if { ![catch {tk windowingsystem} wsystem] && $wsystem  == "x11" } {
		return 1
	} else {
		return 0
	}
}

################################################
# 'Missing' image commands                     #
################################################
proc ImageExists {img} {
	return [expr {([catch {image type $img}]* -1) + 1}]
}

#Use this function to get a not-in-use temporary image name
proc TmpImgName {} {
	set idx 0
	while {[ImageExists tmp$idx]} {
		incr idx
	}
	return tmp$idx
}

################################################
# Other added/update commands for tcl/tk       #
################################################

# Find out what has the focus and assing it to $w, then after $w is
# destroyed, focus the original.
#
# Arguments:
# w -		Window to focus
proc my_focus { w } {
	set oldFocus [focus]
	set oldGrab [grab current $w]
	if {[string compare $oldGrab ""]} {
		set grabStatus [grab status $oldGrab]
	}
	grab $w
	raise $w
	focus $w
	
	# Wait for the user to respond, then restore the focus and
	# return the index of the selected button.  Restore the focus
	# before deleting the window, since otherwise the window manager
	# may take the focus away so we can't redirect it.  Finally,
	# restore any grab that was in effect.
	
	bind $w <Destroy> "catch {focus $oldFocus; grab $oldGrab}"
}

#ShowTransient ?{wintransient}
#The function try to know if the operating system is Mac OS X or not. If no, enable window in transient. Else,
#don't change nothing.
proc ShowTransient {win {parent "."}} {
	if { ![OnMac] } {
		wm transient $win $parent
	}
}

# taken from ::tk::TextSetCursor
# Move the insertion cursor to a given position in a text.  Also
# clears the selection, if there is one in the text, and makes sure
# that the insertion cursor is visible.  Also, don't let the insertion
# cursor appear on the dummy last line of the text.
#
# Arguments:
# w -		The text window.
# pos -		The desired new position for the cursor in the window.
proc my_TextSetCursor {w pos} {
    if {[$w compare $pos == end]} {
	set pos {end - 1 chars}
    }
    $w mark set insert $pos
    $w tag remove sel 1.0 end
    $w see insert
    #removed incase not supported for tk8.3
    #if {[$w cget -autoseparators]} {$w edit separator}
}

# taken from ::tk::TextKeySelect
# This procedure is invoked when stroking out selections using the
# keyboard.  It moves the cursor to a new position, then extends
# the selection to that position.
#
# Arguments:
# w -		The text window.
# new -		A new position for the insertion cursor (the cursor hasn't
#		actually been moved to this position yet).

proc my_TextKeySelect {w new} {
	if {[string equal [$w tag nextrange sel 1.0 end] ""]} {
		if {[$w compare $new < insert]} {
			$w tag add sel $new insert
		} else {
			$w tag add sel insert $new
		}
		$w mark set anchor insert
	} else {
		if {[$w compare $new < anchor]} {
			set first $new
			set last anchor
		} else {
			set first anchor
			set last $new
		}
		$w tag remove sel 1.0 $first
		$w tag add sel $first $last
		$w tag remove sel $last end
	}
	$w mark set insert $new
	$w see insert
	
	update idletasks
}


#///////////////////////////////////////////////////////////////////////////////
# highlight_selected_tags (text, tags)
# This proc will go through the text widget 'text' add an extra tag to any characters that are
# selected and have a certain tag. This is used to highlight coloured text.
# (Use in conjunction with the <<Selection>> event)
# Arguments:
# - text => Is the path to the text widget
# - tags => an even length list containing pairs of tags and their associated extra tags
proc highlight_selected_tags { text tags } {
	#first remove all that were previously set
	foreach { tag tagadd } $tags {
		$text tag remove $tagadd 1.0 end
	}

	#add highlight tags for selected text
	if { [scan [$text tag ranges sel] "%s %s" selstart selend] == 2 } {
		foreach { tag tagadd } $tags {
			set cur $selstart
			#add for chars at the start of the selection
			while { ( [lsearch [$text tag names $cur] $tag] != -1 ) && ( $cur != $selend )} {
				$text tag add $tagadd $cur
				set cur [$text index $cur+1chars]
			}
			while { [scan [$text tag nextrange $tag $cur $selend] "%s %s" st en] == 2 } {
				if { $en > $selend } {
					set en $selend
				}
				$text tag add $tagadd $st $en
				set cur $en
			}
		}
	}
}
