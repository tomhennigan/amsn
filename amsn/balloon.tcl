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
    set Bulle(id) [after 1000 [list balloon %W $Bulle(%W) %X %Y]]
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
        set Bulle(id) [after 1000 [list balloon %W $Bulle(%W) %X %Y]]
    }
}

proc set_balloon {target message} {
    global Bulle
    set Bulle($target) $message
    bindtags $target "[bindtags $target] Bulle"
}

proc change_balloon {target message} {
	kill_balloon
	global Bulle
	set Bulle($target) $message
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
    global Bulle
    #Last focus variable for "Mac OS X focus bug" with balloon
    set lastfocus [focus]
    
    after cancel "kill_balloon"
    if {$Bulle(first) == 1 } {
        set Bulle(first) 2
	if { $cx == 0 && $cy == 0 } {
	    set x [expr [winfo rootx $target] + ([winfo width $target]/2)]
	    set y [expr [winfo rooty $target] + [winfo height $target] + 2]
	} else {
	    set x [expr $cx + 12]
	    set y [expr $cy + 2]
	}
	if { [catch { toplevel .balloon -bg black}] != 0 } {
	    destroy .balloon
	    toplevel .balloon -bg black
	}

	#Standard way to show baloon on Mac OS X (aqua), show balloon in white for Mac OS X and yellow for others platforms
if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
	destroy .balloon
	toplevel .balloon -relief flat  \
    -class Balloonhelp ; ::tk::unsupported::MacWindowStyle\
    style .balloon help none
    set bg_balloon #ffffca
	} else {
	wm overrideredirect .balloon 1
	set bg_balloon #ffffaa
	}

	set wlength [expr {[winfo screenwidth .] - $x - 5}]
	if { $wlength < 100 } {
	   set wlength 100
	}

        label .balloon.l \
            -text $message -relief flat \
            -bg $bg_balloon -fg black -padx 2 -pady 0 -anchor w -font sboldf -justify left -wraplength $wlength
	pack .balloon.l -side left -padx 1 -pady 1
        wm geometry .balloon +${x}+${y}
        
   #Focus last windows , in AquaTK ("Mac OS X focus bug")
if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" && $lastfocus !="" } {
	after 50 "focus -force $lastfocus"  
	}

	set Bulle(set) 1
	after 10000 "kill_balloon"
    }
}

