#!/usr/bin/env wish

lappend auto_path "../"
package require voipcontrols


#wm attributes
wm title . "voipcontrol test"
wm geometry . 200x200
update

variable var

set var 0.75
set var2 0.15

proc showValue {value} {
	puts "value=$value"
}

voipcontrol .sm -volumevariable var -volumecommand [list showValue]
voipcontrol .sm2 -orient horizontal -height 25

place .sm -width 25 -relheight 1
place .sm2 -height 25 -relwidth 1 -width -25 -x 25

update

puts "[winfo width .sm] [winfo height .sm]"
puts "[winfo width .sm.volumeframe] [winfo height .sm.volumeframe]"
puts "[winfo width .sm.buttonframe] [winfo height .sm.buttonframe]"
puts "============"
puts "[winfo width .sm2] [winfo height .sm2]"
puts "[winfo width .sm2.volumeframe] [winfo height .sm2.volumeframe]"
puts "[winfo width .sm2.buttonframe] [winfo height .sm2.buttonframe]"

proc timer {sm limit delay {value 0}} {
	variable var
	variable var2
	puts "var=$var\tvar2=$var2"
	$sm setVolume $value $limit
	incr value
	if {$value >= $limit} {set value 0}
	after $delay [list timer $sm $limit $delay $value]
}

timer .sm  100 200
timer .sm2 100 200


