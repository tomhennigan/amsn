#!/usr/bin/env wish

lappend auto_path "../"
package require pixmapbutton


#wm attributes
wm title . "button test"
wm geometry . 400x45
. config -bg white
update

font create plain -family helvetica -size 12 -weight normal
font create massive -family helvetica -size 32
image create photo icon -file icon.gif

pixmapbutton .b1 -command "puts ok" -font plain

pixmapbutton .b2 -command "puts cancel" -font plain -emblemimage icon -emblempos "left center" -fg red

pack .b1 -side left -padx 5 -pady 5 -fill both -expand true
pack .b2 -side right -padx 5 -pady 5 -fill none -expand false
.b1 configure -text "Fill both, disabled"
.b2 configure -text "Fill none, with emblem"
#.ok configure -font massive
.b1 configure -state disabled
.b2 configure -fg white
