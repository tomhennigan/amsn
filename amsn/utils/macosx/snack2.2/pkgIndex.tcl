#
# Immediate loading of Snack because of item types etc.
#
# http://www.wjduquette.com/tcl/namespaces.html
#

if {[file exists [file join $dir libsnack-[info tclversion].dylib]]} {
	package ifneeded snack 2.2.10 "[list load [file join $dir libsnack-[info tclversion].dylib]];[list source [file join $dir snack.tcl]]"
} else {
	package ifneeded snack 2.2.10 "[list load [file join $dir libsnack.dylib]];[list source [file join $dir snack.tcl]]"
}

if {[file exists [file join $dir libsound-[info tclversion].dylib]]} {
	package ifneeded sound 2.2.10 [list load [file join $dir libsound-[info tclversion].dylib]]
} else {
	package ifneeded sound 2.2.10 [list load [file join $dir libsound.dylib]]
}