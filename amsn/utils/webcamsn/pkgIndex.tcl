# Tcl package index file, version 1.0

if {[package vcompare [info tclversion] 8.4] < 0} return

package ifneeded webcamsn 0.1 "package require Tk; [list load [file join $dir webcamsn.so] webcamsn];package provide webcamsn 0.1"
