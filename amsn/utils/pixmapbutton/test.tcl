#!/usr/bin/env wish

lappend auto_path "../"
package require pixmapbutton


#wm attributes
wm title . "button test"
wm geometry . 200x100
. config -bg white
update

font create plain -family helvetica -size 11 -weight bold


pixmapbutton .ok -text Ok -font plain -activeforeground darkgreen -command "puts ok"
pixmapbutton .cancel -text Cancel -font plain -activeforeground darkgreen -command "puts cancel"
puts [.cancel cget -text]
pack .ok .cancel -side left -padx 10 -fill x -expand true
.ok configure -state disabled
