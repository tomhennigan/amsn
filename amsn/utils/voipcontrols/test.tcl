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
puts "============"
puts "[winfo width .sm2] [winfo height .sm2]"

proc timer {sm limit delay {value 0}} {
	variable var
	variable var2
	puts "var=$var\tvar2=$var2"
	$sm setLevel $value 
	incr value
	if {$value >= $limit} {set value -20}
	after $delay [list timer $sm $limit $delay $value]
}

timer .sm  0 200 -20
timer .sm2 0 200 -20


