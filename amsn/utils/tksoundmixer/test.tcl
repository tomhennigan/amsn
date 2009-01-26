#!/usr/bin/env wish

lappend auto_path "../"
package require tksoundmixer


#wm attributes
wm title . "tksoundmixer test"
wm geometry . 200x200
update

variable var

set var 0.75
set var2 0.75

proc showValue {value} {
	puts "value=$value"
}

tksoundmixer .sm -volumevariable var -volumecommand [list showValue] -width 10 -height 100
tksoundmixer .sm2 -volumevariable var2 -width 100 -height 10 -orient "horizontal"

pack .sm
pack .sm2 -expand 1 -fill both


proc timer {sm limit delay {value 0}} {
	variable var
	variable var2
	#puts "var=$var\tvar2=$var2"
    $sm SetVolume $value $limit
    incr value
    if {$value >= $limit} {set value 0}
    after $delay [list timer $sm $limit $delay $value]
}

timer .sm 62 200
timer .sm2 50 200

