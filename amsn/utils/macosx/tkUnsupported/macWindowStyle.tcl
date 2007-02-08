#	macWindowStyle.tcl
#	An API for accesing the unsupported window styles in Tk Aqua.
#	Thursday, 5th October 2006
#	By Tom Hennigan (tomhennigan[at]gmail[dot]com)
#	CF. http://wiki.tcl.tk/14518, http://wiki.tcl.tk/13428

rename toplevel Tk_toplevel

proc toplevel { pathname args } {
	set window [eval Tk_toplevel \"$pathname\" $args]
	setBrushed $window
	return $window
}

proc setBrushed {window} {
	if {[::skin::getKey usebrushedmetal "0"] && [::config::getKey allowbrushedmetal "1"]} {
	    catch {
	    	::tk::unsupported::MacWindowStyle style $window document {closeBox horizontalZoom verticalZoom collapseBox resizable metal}
	    }
	}
}