#
# $Id$
#

proc checking_ver {} {
   global version weburl

   

   if [catch {
     set sock [socket -async amsn.sourceforge.net 80]
     fconfigure $sock -buffering none -translation {binary binary} -blocking 1
     status_log "Conected to web server\n" red
     puts $sock "GET /amsn_latest HTTP/1.0\nUser-Agent: amsn\nHost: amsn.sourceforge.net\n\n"
     status_log "Request sent, waiting response\n" red

     gets $sock tmp_data
     set end [string length $tmp_data]
     set ok [string range $tmp_data [expr $end -3] [expr $end -2]]

     if { $ok == "OK" } {
     	while { [string length $tmp_data] > 1 } {
	  gets $sock tmp_data
	}
        gets $sock tmp_data	
     }
     set lastver [split $tmp_data "."]
     set yourver [split $version "."]    

     if { [lindex $lastver 0] > [lindex $yourver 0] } {
         set newer 1
     } else {	
           # Major version is at least the same
	   if { [lindex $lastver 1] > [lindex $yourver 1] } {
	     set newer 1
	   } else {
	     set newer 0
	   }
     }
     
     if !$newer {
       msg_box "[trans nonewver]"
     } else {
       msg_box "[trans newveravailable $tmp_data]\n$weburl"
     }
     
  } res ] {
     msg_box "[trans connecterror]"
  }
	
  destroy .checking

}

proc check_version {} {


   toplevel .checking -width 250 -height 50

   wm title .checking "[trans title]"
   wm transient .checking .
   canvas .checking.c -width 250 -height 50 -bg #D0D0E0
   pack .checking.c -expand true -fill both

   .checking.c create text 125 25 -font splainf -anchor n \
	-text "[trans checkingver]..." -justify center -width 250

   tkwait visibility .checking
   grab set .checking
   
   after 1000 checking_ver

	
}
