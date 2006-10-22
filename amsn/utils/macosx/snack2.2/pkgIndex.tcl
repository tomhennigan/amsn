#
# Immediate loading of Snack because of item types etc.
#
# http://www.wjduquette.com/tcl/namespaces.html
#

package ifneeded snack 2.2 "[list load [file join $dir libsnack.dylib]];[list source [file join $dir snack.tcl]]"

package ifneeded sound 2.2 [list load [file join $dir libsound.dylib]]
