#!/usr/bin/tclsh
load [pwd]/capture.so
puts "[::Capture::ListDevices]"
set grabber [::Capture::Open /dev/video 0]

wm protocol . WM_DELETE_WINDOW {::Capture::Close $grabber; exit}

set bright 0
set cont 0
image create photo
label .l -image image1
scale .b -from 0 -to 65535 -resolution 1 -showvalue 1 -label "B" -command "::Capture::SetBrightness $grabber" -orient horizontal
scale .c -from 0 -to 65535 -resolution 1 -showvalue 1 -label "C" -command "::Capture::SetContrast $grabber" -orient horizontal
pack .l
pack .b
pack .c
.b set 48000
.c set 32767
set ::sem 0
while { 1 } {
	::Capture::Grab $grabber image1
	after 100 "incr ::sem"
	tkwait variable ::sem
}