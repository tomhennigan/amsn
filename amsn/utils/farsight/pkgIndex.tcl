# Tcl package index file

if {[package vcompare [info tclversion] 8.4] < 0} return

package ifneeded Farsight 0.1 "[list load [file join $dir tcl_farsight[info shared]] Farsight];package provide Farsight 0.1"
