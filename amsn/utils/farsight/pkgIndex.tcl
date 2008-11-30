# Tcl package index file

if {[package vcompare [info tclversion] 8.4] < 0} return

# TEMP! fix for ppc macs while they aren't supported will be removed soon.
if { ![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" } {
    if { $::tcl_platform(byteOrder) == "bigEndian" } {
        set dir [file join $dir "disabled_on_ppc"]
    }
}

package ifneeded Farsight 0.1 "[list load [file join $dir tcl_farsight[info shared]] Farsight]; package provide Farsight 0.1"
