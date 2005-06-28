#!/usr/bin/env wish

lappend auto_path "../"
package require TkCximage
package require pixmapbutton
source checkbutton.tcl
source radiobutton.tcl

#wm attributes
wm title . "button test"
#wm geometry . 350x100
. config -bg white
update

font create plain -family helvetica -size 12 -weight normal
font create massive -family helvetica -size 32
image create photo icon -file icon.gif
image create photo icon2 -file icon2.gif

pixmapbutton .b1 -text "Buttons can\nhave multiline\ntext!" \
	-foreground red \
	-font massive \
	-command [list puts "b1 clicked"] \
	-activeforeground blue
	
pixmapbutton .b2 -text "Or they can have very long \nstupid text like this..." \
	-font plain \
	-command [list puts "b2 clicked"]
	
pixmapbutton .b3 -text "..or short :)" \
	-anchor w \
	-command [list puts "b3 clicked"]
pixmapbutton .b4 -text "This button invokes every second when you hold it down" \
	-repeatdelay 1000 \
	-repeatinterval 1000 \
	-command [list puts repeat_button]
	
pixmapradiobutton .b5 -text "Disable buttons" \
	-command "disable_all"
pixmapradiobutton .b6 -text "Enable buttons" \
	-command "enable_all"


pack .b1 .b2 .b3 .b4 .b5 .b6 -padx 10 -pady 5 -side top

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