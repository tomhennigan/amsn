# Tcl package index file, version 1.0

if {[package vcompare [info tclversion] 8.4] < 0} return

package ifneeded linflash 0.1 "package require Tk; [list load [file join $dir flash.so] flash]; package provide linflash 0.1"
