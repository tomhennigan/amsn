# Tcl package index file

if {[package vcompare [info tclversion] 8.4] < 0} return

package ifneeded gupnp 0.1 "[list load [file join $dir gupnp[info shared]]]; package provide gupnp 0.1"
