# Tcl package index file, version 1.0

if {[package vcompare [info tclversion] 8.4] < 0} return

package ifneeded TkCximage 0.2 "package require Tk; [list load [file join $dir TkCximage[info shared]] TkCximage]; package provide TkCximage 0.2"
