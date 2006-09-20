# tkvideo pkgIndex
if {[info exists ::tcl_platform(debug)]} {
   package ifneeded tkvideo 1.2.1 [list load [file join $dir tkvideo121g.dll]]
} else {
   package ifneeded tkvideo 1.2.1 [list load [file join $dir tkvideo121.dll]]
}
