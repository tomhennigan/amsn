lappend auto_path "../"
package require scalable-bg

wm geometry . 100x80

image create photo image1 -file "../pixmapbutton/button.gif"
scalable-bg bg -image image1 -n 6 -e 6 -s 6 -w 6 -width 100 -height 100

canvas .c -bg white -highlightthickness 0
.c create image 0 0 -anchor nw -image [bg getBase] -tag img
pack .c -expand true -fill both
bind .c <Configure> "bg configure -width %w -height %h"
