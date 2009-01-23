#!/usr/bin/env wish

lappend auto_path "../"
package require pixmapscroll


#wm attributes
wm title . "scroll test"
wm geometry . 100x100
update

font create plain -family helvetica -size 11 -weight bold
. config -bg #ffffff


text .t -highlightthickness 0 -bd 0 -relief solid -bg #eeddee -wrap none
scrollbar .sy -command {.t yview} -orient vertical -autohide 1
scrollbar .sx -command {.t xview} -orient horizontal -autohide 0
.t configure -yscrollcommand {.sy set} -xscrollcommand {.sx set}
pack .sx -padx 0 -pady 0 -side bottom -fill x
pack .sy -padx 0 -pady 0 -side right -fill y
pack .t -fill both -expand true
for {set x 0} {$x<10} {incr x} {
	.t insert end "$x abcdefghijklmnopqrstuvwxyz."
}
.t insert end "a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl\nm\no\np\nq\nr\ns\nt\nu\nv\nw\nx\ny\nz\n0\n1\n2\n3\n4\n5\n6\n7\n8\n9"
