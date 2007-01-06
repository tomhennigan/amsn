#	macWindowStyle.tcl
#	An API for accesing the unsupported window styles in Tk Aqua.
#	Thursday, 5th October 2006
#	By Tom Hennigan (tomhennigan[at]gmail[dot]com)
#	CF. http://wiki.tcl.tk/14518, http://wiki.tcl.tk/13428

rename toplevel Tk_toplevel

proc toplevel { pathname args } {
	set window [eval Tk_toplevel \"$pathname\" $args]
	setBrushed $window
	setAlpha $window "0.9"
	return $window
}

proc setAlpha { window alpha } {
	if {$window != ".balloon"} {
		# Balloons don't work with alpha values. This needs to be set in balloon.tcl when the window is made, after the tkunsupported command.
		
		# I know this looks weird and wrong, but this is called before config.tcl is loaded.
		set setAlpha "0"
		catch {set setAlpha [::config::isSet windowalpha]}
		
		if {$setAlpha} {
			catch {wm attributes $window -alpha [::config::getKey windowalpha "1.0"]}
		}
	}
}

proc setBrushed {window} {
	if {[::skin::getKey usebrushedmetal "0"] && [::config::getKey allowbrushedmetal "1"]} {
	    catch {
	    	::tk::unsupported::MacWindowStyle style $window document {closeBox horizontalZoom verticalZoom collapseBox resizable metal}
	    }
	}
}