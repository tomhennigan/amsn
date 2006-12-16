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
    set Bulle(id) [after 1000 [list balloon ${win} $Bulle(${win}) $BullePic(${win}) %X %Y]]
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
        set Bulle(id) [after 1000 [list balloon ${win} $Bulle(${win}) $BullePic(${win}) %X %Y]]
    }
}

proc set_balloon {target message {pic ""}} {
    global Bulle
    global BullePic
    set Bulle(${target}) ${message}
    set BullePic(${target}) ${pic}
    bindtags ${target} "[bindtags ${target}] Bulle"
    bind $target <Destroy> "array unset Bulle ${target}; array unset BullePic ${target}"
}

proc change_balloon {target message {pic ""}} {
	kill_balloon
	global Bulle
    global BullePic
    set Bulle(${target}) ${message}
    set BullePic(${target}) ${pic}
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

proc balloon {target message pic {cx 0} {cy 0} {fonts ""} {mode "simple"} } {
    global Bulle
    #check that the mouse is over the target (fix a tk bug - in windows)
    if {[eval winfo containing  [winfo pointerxy .]]!=$target} {
    	set Bulle(first) 0
    	kill_balloon
   	return
    }
    
    #Last focus variable for "Mac OS X focus bug" with balloon
    set lastfocus [focus]
    
    after cancel "kill_balloon"
    if {$Bulle(first) == 1 } {
        set Bulle(first) 2
	
	if { $cx == 0 && $cy == 0 } {
	    set x [expr {[winfo rootx ${target}] + ([winfo width ${target}]/2)}]
	    set y [expr {[winfo rooty ${target}] + [winfo height ${target}] + 2}]
	} else {
	    set x [expr {$cx + 12}]
	    set y [expr {$cy + 2}]
	}
	
	if { [catch { toplevel .balloon -bg [::skin::getKey balloonborder]}] != 0 } {
		destroy .balloon
		toplevel .balloon -bg [::skin::getKey balloonborder]
	}
	
	#Standard way to show balloon on Mac OS X (aqua), show balloon in white for Mac OS X and skinnable balloons for others platforms
	if { [OnMac] } {
		destroy .balloon
		toplevel .balloon -relief flat -bg #C3C3C3 \
		-class Balloonhelp; ::tk::unsupported::MacWindowStyle\
		style .balloon help none
		#wm attributes .balloon -alpha [::config::getKey windowalpha "1.0"]
	} else {
		wm overrideredirect .balloon 1
	}

	frame .balloon.f -bg [::skin::getKey balloonbackground]
	
	if { [OnWin] } {
		set bw [::skin::getKey balloonborderwidth]
	} else {
		set bw [expr {[::skin::getKey balloonborderwidth] - 1 }]
		if {$bw < 0} {
			set bw 0
		}
	}
	pack .balloon.f -padx $bw -pady $bw
	
	if { [string equal -length 11 $pic "--command--"] } {
		set command [string range $pic 11 end]
		set pic [eval $command]
	}
	
	if { $pic != "" && ![catch {$pic cget -file}]} {
		label .balloon.f.pic -image $pic -bg [::skin::getKey balloonbackground]
		set iwidth [image width $pic]
		pack .balloon.f.pic -side left
	} else {
		set iwidth 0
	}

	
	set wlength [expr {[winfo screenwidth .] - $x - 15 - $iwidth }]
	#If available width is less than 200 pixels, make the balloon
	#200 pixels width, and move it to the left so it's inside the screen
	if { $wlength < 200 } {
	    #set offset [expr {$wlength - 200 - [image width $pic] - 10}]
	    #incr x $offset
		set x [expr { [winfo screenwidth . ] - 200 - 15 - $iwidth } ]
		set wlength 200
	}

	if { $mode == "complex" } {
		set i 1;
		foreach msg_part $message font_part $fonts {
			if { [string equal -length 11 $msg_part "--command--"] } {
				set command [string range $message 11 end]
				set message [eval $command]
			}
			if { $font_part == "" } {
				set font_part [::skin::getKey balloonfont]
			}
			
			label ".balloon.f.l$i" \
			-text ${msg_part} -relief flat \
			-bg [::skin::getKey balloonbackground] -fg [::skin::getKey balloontext] -padx 2 -pady 0 \
			-anchor w -font $font_part -justify left -wraplength $wlength
			pack ".balloon.f.l$i" -side top -fill x
			incr i
		}
	} elseif { $mode == "simple" } {
		if { [string equal -length 11 $message "--command--"] } {
			set command [string range $message 11 end]
			set message [eval $command]
		}
	        label .balloon.f.l \
		    -text ${message} -relief flat \
		    -bg [::skin::getKey balloonbackground] -fg [::skin::getKey balloontext] -padx 2 -pady 0 -anchor w \
		    -font [::skin::getKey balloonfont] -justify left -wraplength $wlength
		pack .balloon.f.l -side left
	} else {
		error "Optional parameter mode must be either \"simple\" or \"complex\"."
	}

	if { [OnWin] } {
		set bw [::skin::getKey balloonborderwidth]
	} else {
		set bw [expr {[::skin::getKey balloonborderwidth] - 1 }]
		if {$bw < 0} {
			set bw 0
		}
	}
	
        wm geometry .balloon +${x}+${y}
        
	#Focus last windows in AquaTK (to fix "Mac OS X focus bug")
	if { [OnMac] && $lastfocus!="" } {
		after 50 "catch {focus -force $lastfocus}"
	}
		
	set Bulle(set) 1
	after 10000 "kill_balloon"
    }
}

