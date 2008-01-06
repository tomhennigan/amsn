#
# Immediate loading of Snack because of item types etc.
#
# http://www.wjduquette.com/tcl/namespaces.html
#

if {[file exists [file join $dir [info tclversion] libsnack.dylib]]} {
	package ifneeded snack 2.2.10 "[list load [file join $dir [info tclversion] libsnack.dylib]];[list source [file join $dir snack.tcl]]"
} else {
	package ifneeded snack 2.2.10 "[list load [file join $dir libsnack.dylib]];[list source [file join $dir snack.tcl]]"
}

if {[file exists [file join $dir [info tclversion] libsound.dylib]]} {
	package ifneeded sound 2.2.10 [list load [file join $dir [info tclversion] libsound.dylib]]
} else {
	package ifneeded sound 2.2.10 [list load [file join $dir libsound.dylib]]
}