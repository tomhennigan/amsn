#
# $Id$
#

package require http 2.3

proc checking_ver {} {
   global version weburl


   if {[catch {
         set token [::http::geturl {amsn.sourceforge.net/amsn_latest} -timeout 10000]
         set tmp_data [ ::http::data $token ]

         ::http::cleanup $token

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
     
         if {!$newer} {
            msg_box "[trans nonewver]"
         } else {
            msg_box "[trans newveravailable $tmp_data]\n$weburl"
         }
     
      } res ]} {
     
      msg_box "[trans connecterror]"
   }
	
   destroy .checking
}

proc check_version {} {


   toplevel .checking -width 250 -height 50

   wm title .checking "[trans title]"
   wm transient .checking .
   canvas .checking.c -width 250 -height 50 
   pack .checking.c -expand true -fill both

   .checking.c create text 125 25 -font splainf -anchor n \
	-text "[trans checkingver]..." -justify center -width 250

   tkwait visibility .checking
   grab set .checking
   
   after 1000 checking_ver

	
}
