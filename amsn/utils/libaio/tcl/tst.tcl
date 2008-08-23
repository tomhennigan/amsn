#!/usr/bin/wish

proc rand { i } { 
  for {set j 0 } { $j < $i } { incr j } {
    append out [binary format s [expr { int(rand() * 65535)}]]
  }
  set out
}

#lappend auto_path [pwd]
lappend auto_path /usr/local/lib
lappend auto_path /home/kenshin/coding/libao2/aio/lib/libaio
package require Tclaio
wm withdraw .

set dev [::Aio::Open play -driver oss]
proc play { dev data } {
	if {$data == "" } {
		puts "no more data"
		set a [expr {int([::Aio::GetDelay $dev] * 1000)}]
		if {$a > 0} {
			puts "Playing in $a ms"
			after $a [list play $dev ""]
			return
		} else {
			::Aio::Close $dev 
			exit
		}
	}
	set space [::Aio::GetSpace $dev]
	puts "Delay1 = [::Aio::GetDelay $dev] | Space = [::Aio::GetSpace $dev]"
	if {[string length $data] < $space} { 
		puts "Final data"
		set written [::Aio::Play $dev -final $data]
	} else {
		set to_play [string range $data 0 [expr {$space -1}]]
		set written [::Aio::Play $dev $to_play]
	}
	puts "Written $written bytes"
	puts "Delay2 = [::Aio::GetDelay $dev] | Space = [::Aio::GetSpace $dev]"
	set a [expr {int([::Aio::GetDelay $dev] * 1000 / 2)}]
	set new_data [string range $data $written end]
	puts "Playing in $a ms - [string length $new_data]"
	after $a [list play $dev $new_data]
}
play $dev [rand 160000]
