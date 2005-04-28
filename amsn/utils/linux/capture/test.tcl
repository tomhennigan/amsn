#!/usr/bin/tclsh
 load [pwd]/capture.so
 ::Capture::Init /dev/video0
# ::Capture::SetBrightness 48000
# ::Capture::SetContrast 32767
set bright 0
set cont 0
image create photo
label .l -image image1
scale .b -from 0 -to 65535 -resolution 1 -showvalue 1 -label "B" -variable brighttmp -orient horizontal
scale .c -from 0 -to 65535 -resolution 1 -showvalue 1 -label "C" -variable conttmp -orient horizontal
pack .l
pack .b
pack .c
.b set 48000
.c set 32767
set ::sem 0
while { 1 } {
	if { $brighttmp != $bright } {
		set bright $brighttmp
		::Capture::SetBrightness $bright
	}
	if { $conttmp != $cont } {
		set cont $conttmp
		::Capture::SetContrast $cont
	}
	::Capture::Grab image1
	after 100 "incr ::sem"
	tkwait variable ::sem
}