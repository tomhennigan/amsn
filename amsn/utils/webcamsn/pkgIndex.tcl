# Tcl package index file, version 1.0

if {[package vcompare [info tclversion] 8.4] < 0} return

if {[file exists [file join $dir [info tclversion] webcamsn[info shared]]]} {
	package ifneeded webcamsn 0.1 "package require Tk; [list load [file join $dir [info tclversion] webcamsn[info shared]] webcamsn];package provide webcamsn 0.1"
} else {
	package ifneeded webcamsn 0.1 "package require Tk; [list load [file join $dir webcamsn[info shared]] webcamsn];package provide webcamsn 0.1"
}
