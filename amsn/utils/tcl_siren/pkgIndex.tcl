# Tcl package index file

if {[package vcompare [info tclversion] 8.4] < 0} return

package ifneeded tcl_siren 0.3 "[list load [file join $dir tcl_siren[info shared]] Siren];package provide tcl_siren 0.3"
