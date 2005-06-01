#!/usr/bin/env wish

lappend auto_path "../"
#package require pixmapbutton
source pixmapbutton2.tcl

#wm attributes
wm title . "button test"
#wm geometry . 350x100
. config -bg white
update

font create plain -family helvetica -size 12 -weight normal
font create massive -family helvetica -size 32
image create photo icon -file icon.gif
image create photo icon2 -file icon2.gif

pixmapbutton .b1 -text "Buttons\ncan\nhave\nmultiline\ntext!" -foreground red -font massive -emblem icon2
pixmapbutton .b2 -text "Or they can have very long \nstupid text like this..." -font plain -underline 1
pixmapbutton .b3 -text "..or short :)" -emblem icon -anchor w
pixmapbutton .b4 -text "This button invokes every second when you hold it down" -repeatdelay 1000 -repeatinterval 1000 -command [list puts repeat_button]
#canvas .b1
pack .b1 .b2 .b3 .b4 -padx 10 -pady 5 -expand false -fill none -side top
#button .b -text repeater -command "puts hey" -repeatdelay 10 -repeatinterval 100
#pack .b
