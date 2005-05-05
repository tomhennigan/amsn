#!/usr/bin/env wish

lappend auto_path "../"
package require pixmapscroll


#wm attributes
wm title . "scroll test"
wm geometry . 400x100
update

font create plain -family helvetica -size 11 -weight bold
. config -bg #ffffff


text .t -highlightthickness 0 -bd 0 -relief solid -bg white -wrap word
#scrollbar .s -command {.t yview}
pixmapscroll .s -command {.t yview}
.t configure -yscrollcommand {.s set}
pack .s -padx 0 -pady 0 -side right -fill y -expand true
pack .t -after .s -fill y -expand true
.t insert end "a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl\nm\no\np\nq\nr\ns\nt\nu\nv\nw\nx\ny\nz\n0\n1\n2\n3\n4\n5\n6\n7\n8\n9"
