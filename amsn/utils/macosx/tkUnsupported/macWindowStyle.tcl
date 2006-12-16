#	macWindowStyle.tcl
#	An API for accesing the unsupported window styles in Tk Aqua.
#	Thursday, 5th October 2006
#	By Tom Hennigan (tomhennigan[at]gmail[dot]com)
#	CF. http://wiki.tcl.tk/14518, http://wiki.tcl.tk/13428
#catch {wm attributes . -alpha 0.9}
rename toplevel Tk_toplevel

proc toplevel { pathname args } {
	set window [eval Tk_toplevel \"$pathname\" $args]
	
	setBrushed $window "1"
	setAlpha $window "0.9"
	return $window
}

proc setAlpha { window alpha } {
	if {$window != ".balloon"} {
		# Balloons don't work with alpha values. This needs to be set in balloon.tcl when the window is made, after the tkunsupported command.
		catch {wm attributes $window -alpha [::config::getKey windowalpha "1.0"]}
	}
}

proc setBrushed {window brushed_bool} {
	if {$brushed_bool != 1 && $brushed_bool != 0} {
		return
	} else {
		if {[::skin::getKey usebrushedmetal "0"] && [::config::getKey allowbrushedmetal "1"]} {
			catch {
				::tk::unsupported::MacWindowStyle style $window document {closeBox horizontalZoom verticalZoom collapseBox resizable metal}
			}
		}
	}
}