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

tksoundmixer .sm -volumevariable var -volumecommand [list showValue]

place .sm -width 10 -relheight 1

update

puts "[winfo width .sm] [winfo height .sm]"
puts "[winfo width .sm.volumeframe] [winfo height .sm.volumeframe]"
puts "[winfo width .sm.mute] [winfo height .sm.mute]"

proc timer {sm limit delay {value 0}} {
	variable var
	variable var2
	puts "var=$var\tvar2=$var2"
	$sm setVolume $value $limit
	incr value
	if {$value >= $limit} {set value 0}
	after $delay [list timer $sm $limit $delay $value]
}

timer .sm 62 200

