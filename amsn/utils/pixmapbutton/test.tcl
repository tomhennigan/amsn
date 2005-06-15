#!/usr/bin/env wish

lappend auto_path "../"
package require pixmapbutton

#wm attributes
wm title . "button test"
#wm geometry . 350x100
. config -bg white
update

font create plain -family helvetica -size 12 -weight normal
font create massive -family helvetica -size 32
image create photo icon -file icon.gif
image create photo icon2 -file icon2.gif

button .b1 -text "Buttons\ncan\nhave\nmultiline\ntext!" -foreground red -font massive -emblem icon2 -command [list puts "b1 clicked"]
button .b2 -text "Or they can have very long \nstupid text like this..." -font plain -command [list puts "b2 clicked"]
button .b3 -text "..or short :)" -emblem icon -anchor w -command [list puts "b3 clicked"]
button .b4 -text "This button invokes every second when you hold it down" -repeatdelay 1000 -repeatinterval 1000 -command [list puts repeat_button]
button .b5 -text "Disable above buttons" -command "disable_all"
button .b6 -text "Enable above buttons" -command "enable_all"
#canvas .b1
pack .b1 .b2 .b3 .b4 .b5 .b6 -padx 10 -pady 5 -side top
#button .b -text repeater -command "puts hey" -repeatdelay 10 -repeatinterval 100
#pack .b

proc disable_all { } {
	.b1 configure -state disabled
	.b2 configure -state disabled
	.b3 configure -state disabled
	.b4 configure -state disabled
}

proc enable_all { } {
	.b1 configure -state normal
	.b2 configure -state normal
	.b3 configure -state normal
	.b4 configure -state normal
}