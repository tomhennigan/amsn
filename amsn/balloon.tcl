##############################################################################
# $Id$
#
# balloon.tcl - procedures used by balloon help
#
# Copyright (C) 1996-1997 Stewart Allen
# 
# This is part of vtcl source code Adapted for 
# general purpose by Daniel Roche <dan@lectra.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

##############################################################################
#

bind Bulle <Enter> {
    set Bulle(set) 0
    set Bulle(first) 1
    set win %W 
    set Bulle(id) [after 1000 [list balloon ${win} $Bulle(${win}) %X %Y]]
}

bind Bulle <Button> {
    set Bulle(first) 0
    kill_balloon
}

bind Bulle <Leave> {
    set Bulle(first) 0
    kill_balloon
}

bind Bulle <Motion> {
    if {$Bulle(set) == 0} {
        after cancel $Bulle(id)
	set win %W
        set Bulle(id) [after 1000 [list balloon ${win} $Bulle(${win}) %X %Y]]
    }
}

proc set_balloon {target message} {
    global Bulle
    set Bulle(${target}) ${message}
    bindtags ${target} "[bindtags ${target}] Bulle"
}

proc change_balloon {target message} {
	kill_balloon
	global Bulle
    set Bulle(${target}) ${message}
}

proc kill_balloon {} {
    global Bulle
    catch {
	after cancel $Bulle(id)
	if {[winfo exists .balloon] == 1} {
	    destroy .balloon
	}
	set Bulle(set) 0
    }
}

proc balloon {target message {cx 0} {cy 0} } {
    global Bulle tcl_platform
    #Last focus variable for "Mac OS X focus bug" with balloon
    set lastfocus [focus]
    
    after cancel "kill_balloon"
    if {$Bulle(first) == 1 } {
        set Bulle(first) 2
	if { $cx == 0 && $cy == 0 } {
	    set x [expr [winfo rootx ${target}] + ([winfo width ${target}]/2)]
	    set y [expr [winfo rooty ${target}] + [winfo height ${target}] + 2]
	} else {
	    set x [expr $cx + 12]
	    set y [expr $cy + 2]
	}
	
	if { [catch { toplevel .balloon -bg [::skin::getKey balloonborder]}] != 0 } {
		destroy .balloon
		toplevel .balloon -bg [::skin::getKey balloonborder]
	}
	
	#Standard way to show balloon on Mac OS X (aqua), show balloon in white for Mac OS X and skinnable balloons for others platforms
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		destroy .balloon
		toplevel .balloon -relief flat -bg #C3C3C3 \
		-class Balloonhelp ; ::tk::unsupported::MacWindowStyle\
		style .balloon help none
	} else {
		wm overrideredirect .balloon 1
	}
	
	set wlength [expr {[winfo screenwidth .] - $x - 5}]
	#If available width is less than 200 pixels, make the balloon
	#200 pixels width, and move it to the left so it's inside the screen
	if { $wlength < 200 } {
	    set offset [expr {$wlength - 200}]
	    incr x $offset
	    set wlength 200
	}

        label .balloon.l \
	    -text ${message} -relief flat \
	    -bg [::skin::getKey balloonbackground] -fg [::skin::getKey balloontext] -padx 2 -pady 0 -anchor w -font [::skin::getKey balloonfont] -justify left -wraplength $wlength
	pack .balloon.l -side left -padx 1 -pady 1
        wm geometry .balloon +${x}+${y}
        
	#Focus last windows , in AquaTK ("Mac OS X focus bug")
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" && $lastfocus!="" } {
		after 50 "catch {focus -force $lastfocus}"
	}
		
	set Bulle(set) 1
	after 10000 "kill_balloon"
    }
}

