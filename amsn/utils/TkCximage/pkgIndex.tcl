# Tcl package index file, version 1.0

if {[package vcompare [info tclversion] 8.4] < 0} return

# Use TkCximage-TCLVER.shared if it's available. Otherwise use TkCximage.shared.
if {[file exists [file join $dir [info tclversion] TkCximage[info shared]]]} {
	package ifneeded TkCximage 0.2 "package require Tk; [list load [file join $dir [info tclversion] TkCximage[info shared]] TkCximage]; package provide TkCximage 0.2"
} else {
	package ifneeded TkCximage 0.2 "package require Tk; [list load [file join $dir TkCximage[info shared]] TkCximage]; package provide TkCximage 0.2"
}
