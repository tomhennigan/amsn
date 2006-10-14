# Tcl package index file, version 1.0

if {[package vcompare [info tclversion] 8.4] < 0} return

package ifneeded tcl_siren 0.1 "[list load [file join $dir tcl_siren[info shared]] Siren];package provide tcl_siren 0.1"
