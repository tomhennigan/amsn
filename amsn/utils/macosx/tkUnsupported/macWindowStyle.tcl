#	macWindowStyle.tcl
#	An API for accesing the unsupported window styles in Tk Aqua.
#	Thursday, 5th October 2006
#	By Tom Hennigan (tomhennigan[at]gmail[dot]com)
#	CF. http://wiki.tcl.tk/14518, http://wiki.tcl.tk/13428

rename toplevel Tk_toplevel

proc toplevel { pathname args } {
	set window [eval Tk_toplevel [list $pathname] $args]
	::macWindowStyle::setBrushed $window
	return $window
}

namespace eval macWindowStyle {
	# Cached variable storing the system version IE. 10.3.9, 10.4.10 or 10.5.1
	variable macos_version [exec sw_vers -productVersion]
	
	proc setBrushed {window} {
		variable macos_version
		
		if {[::skin::getKey usebrushedmetal "0"] && [::config::getKey allowbrushedmetal "1"]} {
			# Brushed style windows are buggy with 10.5, so we diable them for 10.5+
			if {[package vcompare 10.5.0 $macos_version] == 1} {
				catch {
		    		::tk::unsupported::MacWindowStyle style $window document {closeBox horizontalZoom verticalZoom collapseBox resizable metal}
		    	}
			} else {
				status_log "::macWindowStyle::setBrushed - style disabled for os version ($macos_version)" white
			}
		}
	}
}
