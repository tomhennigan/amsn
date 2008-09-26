
set name "amsnextras"
set vers 0.1

package ifneeded $name $vers "[list source [file join $dir extras.tcl]]; [list ::extras::init $dir]; [list package provide $name $vers]"
