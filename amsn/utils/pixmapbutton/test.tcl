#!/usr/bin/env wish

lappend auto_path "../"
package require pixmapbutton


#wm attributes
wm title . "button test"
wm geometry . 150x45
. config -bg white
update

font create plain -family helvetica -size 12 -weight normal
font create massive -family helvetica -size 32
image create photo icon -file icon.gif
image create photo icon2 -file icon2.gif

pixmapbutton .b1 -command "puts ok" -font plain -emblemimage icon2 -emblempos "left center"

pixmapbutton .b2 -command "puts cancel" -font plain -emblemimage icon -emblempos "left center" -fg red

pack .b1 -side left -padx 5 -pady 5 -fill none -expand false
pack .b2 -side right -padx 5 -pady 5 -fill none -expand false
.b1 configure -text "Ok"
.b2 configure -text "Cancel"
#.ok configure -font massive
#.b1 configure -state disabled
.b2 configure -fg black
