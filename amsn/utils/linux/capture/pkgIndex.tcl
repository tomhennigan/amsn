# Tcl package index file, version 1.0

if {[package vcompare [info tclversion] 8.4] < 0} return

package ifneeded capture 0.1 "[list load [file join $dir capture.so] capture]; package provide capture 0.1"
