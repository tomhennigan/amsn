# tkvideo pkgIndex
if {[info exists ::tcl_platform(debug)]} {
   package ifneeded tkvideo 1.1.0 [list load [file join $dir tkvideo110g.dll]]
} else {
   package ifneeded tkvideo 1.1.0 [list load [file join $dir tkvideo110.dll]]
}
