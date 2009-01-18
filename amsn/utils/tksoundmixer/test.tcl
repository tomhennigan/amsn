#!/usr/bin/env wish

lappend auto_path "../"
package require tksoundmixer


#wm attributes
wm title . "tksoundmixer test"
wm geometry . 200x200
update

variable var

set var 0.75

tksoundmixer .sm -variable var -width 10 -height 100

pack .sm -expand 1 -fill both


proc timer {sm limit delay {value 0}} {
	variable var
	puts $var
    $sm SetProgress $value $limit
    incr value
    if {$value >= $limit} {set value 0}
    after $delay [list timer $sm $limit $delay $value]
}

timer .sm 62 200

