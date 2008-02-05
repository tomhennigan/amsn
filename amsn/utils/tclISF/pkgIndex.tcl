# Tcl package index file, version 1.0

if {[package vcompare [info tclversion] 8.4] < 0} return

# Use TCLVER/tclISF.shared if it's available. Otherwise use tclISF.shared.
if {[file exists [file join $dir [info tclversion] tclISF[info shared]]]} {
	package ifneeded tclISF 0.2 "[list load [file join $dir [info tclversion] tclISF[info shared]] tclISF]; package provide tclISF 0.2"
} else {
	package ifneeded tclISF 0.2 "[list load [file join $dir tclISF[info shared]] tclISF]; package provide tclISF 0.2"
}
