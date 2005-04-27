#!/usr/bin/tclsh
 load [pwd]/capture.so
 ::Capture::Init /dev/video0
 image create photo
label .l -image image1
pack .l
set ::sem 0
while { 1 } {
::Capture::Grab image1
after 100 "incr ::sem"
tkwait variable ::sem
}
