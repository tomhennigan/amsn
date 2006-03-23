# Tcl package index file, version 1.0

if {[package vcompare [info tclversion] 8.4] < 0} return

package ifneeded winflash 0.1 "package require Tk; [list load [file join $dir flash.dll] flash]; package provide winflash 0.1"
