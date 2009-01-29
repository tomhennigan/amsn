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
#  able) gui/protocol implementations. The functions here kind of extend
#  tcl/tk in it's capabilities or make our code work on different tcl/tk
#  versions without us having to worry about it.
#
#  Messing with this file is messing with the best (tm).  Keep it read-
#  able and clear!  You are warned :).
#
#  This file needs: Tk
#
#########################################################################


# The following functions were taken from TIP 268 http://www.tcl.tk/cgi-bin/tct/tip/268.html
# Their purpose is to compare version numbers while taking into account the alpha/beta versions.

proc version_intList {version} {
	# Convert a version number to an equivalent list of integers
	# Raise error for invalid version number
	
	if {$version eq {} || [string match *-* $version]} {
		# Reject literal negative numbers
		return -code error "invalid version number: \"$version\""
	}
	# Note only lowercase "a" and "b" accepted and only one
	if {[llength [split $version ab]] > 2} {
		return -code error "invalid version number: \"$version\""
	}
	set converted [string map {a .-2. b .-1.} $version]
	set list {}
	foreach element [split $converted .] {
		if {[scan $element %d%s i trash] != 1} {
			# Require decimal formatted numbers with no suffix
			return -code error "invalid version number: \"$version\""      
		}
		if {[catch {incr i 0}] || $i < -2 } {
			# Verify each component is integer >= -2
			return -code error "invalid version number: \"$version\""      
		}
		lappend list $i
	}
	return $list
}

proc version_compare {l1 l2} {
	# Compare lists of integers
	foreach i1 $l1 i2 $l2 {
		if {$i1 eq {}} {set i1 0}
		if {$i2 eq {}} {set i2 0}
		if {$i1 < $i2} {return -1}
		if {$i1 > $i2} {return 1}
	}
	return 0 
}

proc version_vcompare {v1 v2} {
	version_compare [version_intList $v1] [version_intList $v2]
}

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

		#status_log "Event --$eventName-- fired with caller -$caller-- and args : $args"

		#fire events registered for both the current caller and 'all'
		foreach call [list $caller "all"] {
			#first check there were some events registered to caller or it will fail
			if { [array names eventsArray "$eventName,$call"] == "$eventName,$call" } {
				foreach listener [set eventsArray($eventName,$call)] {
					eval $listener [linsert $args 0 $eventName]
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

#Test for Windows Vista
proc OnWinVista {} {
	global tcl_platform
	if { [OnWin] && $tcl_platform(os) == "Windows NT" && $tcl_platform(osVersion) == "6.0" } {
		return 1
	} else {
		return 0
	}
}

#Test for BSD
proc OnBSD {} {
	global tcl_platform
	if { $tcl_platform(os) == "OpenBSD" || 
             $tcl_platform(os) == "FreeBSD" ||
             $tcl_platform(os) == "NetBSD"} {
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
	} elseif { $tcl_platform(os) == "SunOS" } {
		# Really not correct at all, but closer than BSD.
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

#Test for Maemo (770/N800/N810)
proc OnMaemo {} {
	global tcl_platform
	if { [string first "arm" $tcl_platform(machine)] == 0 } {
		return 1
	} else {
		return 0
	}
}

proc GetPlatformModifier {} {
	if {[OnMac]} {
		return "Command"
	} else {
		return "Control"
	}
}

################################################
# 'Missing' image commands                     #
################################################
proc ImageExists {img} {
	return [expr {![catch {image type $img}]}]
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
if { [info commands ::tk::grab] == "" } {
	rename grab ::tk::grab
	proc grab { args } {
		if {[llength $args] == 1} {
			set command "set"
			set window [lindex $args 0]
			set global 0
		} elseif {[llength $args] == 2} {
			set command [lindex $args 0]
			set window [lindex $args 1]
			set global 0
			if {$command == "-global" } {
				set command "set"
				set global 1
			}
		} elseif {[llength $args] == 3} {
			set command [lindex $args 0]
			set window [lindex $args 2]
			set global 1
			if {$command == "set" &&
			    [lindex $args 2] == "-global" } {
				set global 1
			    }
		} else {
			set command "unknown"
		}
 		if {$command != "set"  } {
			eval [linsert $args 0 ::tk::grab]
		} else  {
			set retries 5
			while { $retries > 0 } {
				catch {focus -force $window}
				if {$global} {
					if {![catch {::tk::grab set -global $window} ret] } {
						return $ret
					}
				} else {
					if {![catch {::tk::grab set $window} ret] } {
						return $ret
					}
				}
				after 100
				incr retries -1
			}
		}
	}
}

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

if { [version_vcompare [info patchlevel] 8.4.13] == -1} {
proc ::tk::TextKeySelect {w new} {
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



################################################
# Commands for playing sounds                  #
################################################

proc play_sound {sound {absolute_path 0} {force_play 0}} {
	#If absolute_path == 1 it means we don't have to get the sound
	#from the skin, but just use it as an absolute path to the sound file

	#I suppose that, when you have a custom state with No Sounds on, you dont want to hear voice clips, right?
	global automessage
	if { [info exists automessage] && $automessage != -1 && [lindex $automessage 6] == 1} { return }

	if { [::config::getKey sound] == 1 || $force_play == 1} {
		#Activate snack on Mac OS X (remove that during 0.94 CVS)
		if { [OnMac] } {
			if { $absolute_path == 1 } {
				play_Sound_Mac $sound
			} else {
				play_Sound_Mac [::skin::GetSkinFile sounds $sound]
			}
		} elseif { [::config::getKey usesnack] } {
			snack_play_sound [::skin::loadSound $sound $absolute_path]
		} else {
			if { $absolute_path == 1 } {
				play_sound_other $sound
			} else {
				play_sound_other [::skin::GetSkinFile sounds $sound]
			}
		}
	}
}

proc snack_play_sound {snd {loop 0}} {
	if { $loop == 1 } {
		#When 2 sounds play at the same time callback doesnt get deleted unless both are stopped so requires a catch
		catch { $snd play -command [list snack_play_sound $snd 1] } { }
	} else {
		#This catch will avoid some errors is waveout is being used
		catch { $snd play }
	}
}

proc play_sound_other {sound} {
	if { [string first "\$sound" [::config::getKey soundcommand]] == -1 } {
		::config::setKey soundcommand "[::config::getKey soundcommand] \$sound"
	}

	set soundcommand [::config::getKey soundcommand]

	#Quote everything, or "eval" will fail
	set soundcommand [string map { "\\" "\\\\" "\[" "\\\[" "\$" "\\\$" "\[" "\\\[" } $soundcommand]
	set soundcommand [string map { "\\" "\\\\" "\[" "\\\[" "\$" "\\\$" "\[" "\\\[" } $soundcommand]
	#Unquote the $sound variable so it's replaced
	set soundcommand [string map { "\\\\\\\$sound" "\${sound}" } $soundcommand]

	catch {eval exec $soundcommand &} res
	
}

#Play sound in a loop
proc play_loop { sound_file {id ""} } {
	global looping_sound

	#Prepare the sound command for variable substitution
	set command [::config::getKey soundcommand]
	set command [string map {"\[" "\\\[" "\\" "\\\\" "\$" "\\\$" "\(" "\\\(" } $command]
	
	#Now, let's unquote the variables we want to replace
	set command "|[string map {"\\\$sound" "\${sound_file}" } $command]"
	set command [subst -nocommands $command]

	#Launch command, connecting stdout to a pipe
	set pipe [open $command r]

	if { ![info exists ::loop_id] } {
		set ::loop_id 0
	}

	#Get a new ID
	if { $id == "" } {
		set id [incr ::loop_id]
	}
	set looping_sound($id) $pipe
	fileevent $pipe readable [list play_finished $pipe $sound_file $id]
	return $id
}

proc cancel_loop { id {retry 1}} {
	global looping_sound
	if { ![info exists looping_sound($id)] } {
		if {$retry } {
			after 3000 [list cancel_loop $id 0]
		}
	} else {
		unset looping_sound($id)
	}
}

proc play_finished {pipe sound id} {
	global looping_sound

	if { [eof $pipe] } {
		fileevent $pipe readable {}
		catch {close $pipe}
		if { [info exist looping_sound($id)] } {

			update

			#after 1000 [list play_loop $sound $id]
			after 1000 [list replay_loop $sound $id]
		}
	} else {
		gets $pipe
	}
}

proc replay_loop {sound id} {
	global looping_sound

	if { ![info exist looping_sound($id)] } {
		return
	}

	play_loop $sound $id
}

#play_Sound_Mac Play sounds on Mac OS X with the extension "QuickTimeTcl"
proc play_Sound_Mac {sound} {
	set sound_name [file tail $sound]
	#Find the name of the sound without .wav or .mp3, etc
	set sound_small [string first "." "$sound_name"]
	incr sound_small -1
	set sound_small_name [string range $sound_name 0 $sound_small]
	#Necessary for Mac OS 10.2 compatibility
	#Find the path of the sound, begin with skins/.. or /..
	#/ = The sound has a real path, skin in Application Support (.amsn) or anywhere on hard disk
	#s = skins, the sound is inside aMSN Folder
	set sound_start [string range $sound 0 0]
	#Destroy previous song if he already play
	destroy .fake.$sound_small_name
	#Find the path of aMSN folder
	set pwd "[pwd]"
	#Create the sound in QuickTime TCL to play the sound
	if {$sound_start == "/"} {
		catch {movie .fake.$sound_small_name -file $sound -controller 0}
	} else {
		#This way we create real path for skins inside aMSN application
		catch {movie .fake.$sound_small_name -file $pwd/$sound -controller 0}
	}
	#Play the sound
	catch {.fake.$sound_small_name play}
	return
}


namespace eval ::Version {

	variable amsn_revision 0
	variable date "01/01/1970 00:00:00"
	variable last_file ""
	variable last_author ""

	proc setSubversionId { idstring } {
		variable amsn_revision
		variable date
		variable last_file
		variable last_author

		#Be careful with this line : the line break should be changed carefully if it needs
		set pattern {\$Id: (.*) ([[:digit:]]*) ([[:digit:]]{4})-([[:digit:]]{2})-([[:digit:]]{2})\
 ([[:digit:]]{2}):([[:digit:]]{2}):([[:digit:]]{2})Z (.*) \$}
	
		if { [regexp $pattern $idstring match file rev year month day hour minute second author] } {
			if { $amsn_revision < $rev } {
				set amsn_revision $rev
				set date "$month/$day/$year $hour:$minute:$second"
				set last_author $author
				set last_file $file
			}
		}
		
	}
}

::Version::setSubversionId {$Id$}


#Try to use async resolve if available
catch { package require asyncresolver }
