#	brushedmetal.tcl
#	Applys a brushed metal theme to all toplevel windows on Mac OS X.
#	Thursday, 5th October 2006
#	By Tom Hennigan (tomhennigan[at]gmail[dot]com)
#	CF. http://wiki.tcl.tk/14518, http://wiki.tcl.tk/13428

rename toplevel Tk_toplevel
proc toplevel { pathname args } {
	set window [eval Tk_toplevel $pathname $args]
	
	catch {
		::tk::unsupported::MacWindowStyle style $window document {closeBox horizontalZoom verticalZoom collapseBox resizable metal}
	}
	
	return $window
}