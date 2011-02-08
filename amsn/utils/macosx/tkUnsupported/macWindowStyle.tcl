#	macWindowStyle.tcl
#	An API for accesing the unsupported window styles in Tk Aqua.
#	Thursday, 5th October 2006
#	By Tom Hennigan (tomhennigan[at]gmail[dot]com)
#	CF. http://wiki.tcl.tk/14518, http://wiki.tcl.tk/13428

::tk::unsupported::MacWindowStyle style . document [list closeBox verticalZoom collapseBox resizable]

rename toplevel Tk_toplevel

proc toplevel { pathname args } {
	set window [eval Tk_toplevel [list $pathname] $args]
	catch {::macWindowStyle::setBrushed $window}
	return $window
}

namespace eval macWindowStyle {
	# Cached variable storing the system version IE. 10.3.9, 10.4.10 or 10.5.1
	
	proc setBrushed {w} {
		if { [systemSupportsBrushed] && [::skin::getKey usebrushedmetal 0] && [::config::getKey allowbrushedmetal 1] } {
			catch [list ::tk::unsupported::MacWindowStyle style $w document [list closeBox horizontalZoom verticalZoom collapseBox resizable metal]]
		}
	}
	
	proc systemSupportsBrushed { } {
		set r 1
		set macos_version [exec sw_vers -productVersion]
		
		if { [package vcompare 10.5.0 $macos_version] == -1 } {
			status_log "::macWindowStyle::setBrushed - style disabled (os version: $macos_version)" white
			set r 0
		}
		
		# Cache the result of this call.
		rename ::macWindowStyle::systemSupportsBrushed {}
		proc ::macWindowStyle::systemSupportsBrushed {} [list return $r]
		
		return $r
	}
}
