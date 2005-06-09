lappend auto_path ../
source pixmapprogbar.tcl
package require pixmapbutton

frame .top
pixmapprogbar .top.pb -height 20 -overfg blue -font [font create -family helvetica -size 12 -weight bold]

frame .bottom
button .bottom.1 -text "step 1" -command ".top.pb setprogress 0.2"
button .bottom.2 -text "step 2" -command ".top.pb setprogress 0.4"
button .bottom.3 -text "step 3" -command ".top.pb setprogress 0.6"
button .bottom.4 -text "step 4" -command ".top.pb setprogress 0.8"
button .bottom.5 -text "step 5" -command ".top.pb setprogress 1.0"

pack .top.pb -expand true -fill x
pack .bottom.1 .bottom.2 .bottom.3 .bottom.4 .bottom.5

pack .top .bottom -side top -pady 10

puts [.top.pb cget -foreground]