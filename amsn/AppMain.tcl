#!/usr/bin/env wish
# MacOS X AMSN wrapper 

#Set variable program_dir
set program_dir [file dirname [info script]]
set program [file tail [info script]]

while {[catch {file readlink [file join $program_dir $program]} program]== 0} {
	if {[file pathtype $program] == "absolute"} {
		set program_dir [file dirname $program]
	} else {
		set program_dir [file join $program_dir [file dirname $program]]
	}

	set program [file tail $program]
}

unset program
#Source the main file, amsn
source [file join $program_dir amsn]