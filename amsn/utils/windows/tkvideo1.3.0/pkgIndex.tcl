# tkvideo pkgIndex
if {[info exists ::tcl_platform(debug)]} {
   package ifneeded tkvideo 1.3.0 [list load [file join $dir tkvideo130g.dll]]
} else {
   package ifneeded tkvideo 1.3.0 [list load [file join $dir tkvideo130.dll]]
}
