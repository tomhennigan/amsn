#!/usr/bin/tclsh

if {[llength $argv] < 4} {
	puts "  Use: convert source_file source_encoding dest_file dest_encoding"
	exit
}

set fsource [open "[lindex $argv 0]" r]
set fdest [open "[lindex $argv 2]" w]


fconfigure $fsource -encoding [lindex $argv 1]
fconfigure $fdest -encoding [lindex $argv 3]


while {[gets $fsource tmp_data] != "-1"} {
	puts $fdest "$tmp_data"
}

close $fsource
close $fdest