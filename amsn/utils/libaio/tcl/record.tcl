#!/usr/bin/wish

proc rand { i } {
  for {set j 0 } { $j < $i } { incr j } {
    append out [binary format s [expr { int(rand() * 65535)}]]
  }
  set out
}

lappend auto_path /usr/local/lib
lappend auto_path /home/kenshin/coding/libao2/aio/lib/libaio
package require Tclaio
wm withdraw .
set dev [::Aio::Open recplay -fmt 7 ]

while {1} {
	set data [::Aio::Record $dev 5000]
	::Aio::Play $dev $data
}
exit
