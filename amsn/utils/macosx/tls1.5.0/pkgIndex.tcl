
# pkgIndex.tcl - 
#
#    A new manually generated "pkgIndex.tcl" file for tls to
#    replace the original which didn't include the commands from "tls.tcl".
#

package ifneeded tls 1.5.0 "[list load [file join $dir libtls1.5.0.dylib] ] ; [list source [file join $dir tls.tcl] ]"

