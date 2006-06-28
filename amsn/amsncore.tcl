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

