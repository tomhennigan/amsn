#!/usr/bin/wish
#########################################################
# blocking.tcl v 1.0	2003/05/22   KaKaRoTo
#########################################################

if { $initialize_amsn == 1 } {

    set VerifyEnd 1
}
#///////////////////////////////////////////////////////////////////////////////
# show_blocked { }
# open a dialog box with a list of all people who are blocking you 
# and online at the moment
proc show_blocked { } {
    global emailBList 
 
    set wname ".blocked_list"

    # Update window if exists
     if { [catch {toplevel ${wname} -borderwidth 0 -highlightthickness 0 } res ] } {
	 destroy ${wname}
	 toplevel ${wname} -borderwidth 0 -highlightthickness 0
     }
    

    wm group ${wname} .
    wm title ${wname}  "[trans youblocked]"
    frame ${wname}.c -relief flat -highlightthickness 0
    pack ${wname}.c -expand true -fill both -padx 10 -pady 0
    
    label ${wname}.c.txt -text "[trans blockmessage] : "
    grid ${wname}.c.txt -row 1 -column 1 -sticky w -pady 10



   set blockers [array get emailBList]
   set items [llength $blockers]
   for {set idx 0} {$idx < $items} {incr idx 1} {
      set emailB [lindex $blockers $idx]; incr idx 1

       set row [expr 2 + [expr $idx / 2]]

       label ${wname}.c.txt${idx} -text "$emailB"
       grid ${wname}.c.txt${idx} -row $row -column 1 -sticky w -pady 10
   }

#     for {set idx [expr [array size emailBList] - 1]} {$idx >= 0} {incr idx -1} {
# 	set row [expr 2 + $idx]

# 	label ${wname}.c.txt${idx} -text "$emailBList($idx)"
# 	grid ${wname}.c.txt${idx} -row $row -column 1 -sticky w -pady 10
#     } 
    
    
    button ${wname}.c.ok -text [trans ok] -command "destroy ${wname}"
    
    set row [expr [expr [array size emailBList]] + 2]
    grid ${wname}.c.ok -row $row -column 0 -pady 10

    button ${wname}.c.refresh -text [trans Refresh] -command "VerifyBlocked ; show_blocked"
    grid ${wname}.c.refresh -row $row -column 2 -pady 10
    
}

#///////////////////////////////////////////////////////////////////////////////
# warn_blocked { email }
# adds the user who blocked you to the blockers list
proc warn_blocked { email } {
    global emailBList 

    if { [info exists emailBList($email)] } {
	return 0
    }

    set emailBList($email) 1

    if {[winfo exists .blocked_list] } {
	show_blocked
    }

    cmsn_draw_online

}

#///////////////////////////////////////////////////////////////////////////////
# user_not_blocked { email }
# If the user is in the blockers list,erase him
proc user_not_blocked { email } {
    global emailBList
    
    if { [info exists emailBList($email)] == 0 } {
	return 0
    }

    unset emailBList($email)

    if {[winfo exists .blocked_list] } {
	show_blocked
    }

    cmsn_draw_online

} 


#///////////////////////////////////////////////////////////////////////////////
# BeginVerifyBlocked { interval }
# Starts the VerifyBlocked script every "interval" secondes
proc BeginVerifyBlocked { {interval 60} {interval2 300} {nbre_users 2} {interval3 5}} {
    global VerifyEnd user_stat stop_VerifyBlocked

    if { [info exists stop_VerifyBlocked] && $stop_VerifyBlocked == 0 } { return }

    set stop_VerifyBlocked 0


    set interval3 [expr $interval3 * 1000]

    while { 1 } {

	if { $stop_VerifyBlocked == 1 } {
	    break
	}

	if { "$user_stat" == "NLN" } {
	    after [expr $interval * 1000] "VerifyBlocked $nbre_users $interval3"
	} else {
	    after [expr $interval2 * 1000] "VerifyBlocked $nbre_users $interval3"
	}

	set VerifyEnd 2

	while { $VerifyEnd != 1 } {
	    vwait VerifyEnd
	}



    }


}

proc StopVerifyBlocked { } {
    global stop_VerifyBlocked VerifyEnd

#    after cancel VerifyBlocked
 
   set stop_VerifyBlocked 1
}

#///////////////////////////////////////////////////////////////////////////////
# VerifyBlocked { }
# tests every offline user in your contact list
proc VerifyBlocked { nbre_users interval } { 
    global sbn_blocking blocking_ready sb_list user_stat stop_VerifyBlocked

    if { $stop_VerifyBlocked == 1 } {return}

    if { "$user_stat" == "FLN" } {return}

    if { [info exists sbn_blocking] == 0  || [sb get $sbn_blocking stat] == "d" || [sb get $sbn_blocking stat] == "" } {
	set sbn_blocking [::MSN::GetNewSB]
	lappend sb_list "$sbn_blocking"
	::MSN::WriteSB ns "XFR" "SB" "create_sb_for_blocking $sbn_blocking"
	vwait blocking_ready
    } 

    ContinueVerifyBlocked $nbre_users $interval
       
}

 
proc ContinueVerifyBlocked { nbre_users interval } {
    global list_users list_states counter VerifyEnd sbn_blocking

    if { ([info exists VerifyEnd] && $VerifyEnd == 0) } {
	return
    }

    set VerifyEnd 0

    set counter 0

    foreach user $list_users {
	

  	if { $counter >= $nbre_users } {
  	    after $interval reset_counter
	    vwait counter
   	}

	set user_state_no [lindex $user 2]
	set state [lindex $list_states $user_state_no]
	set state_code [lindex $state 0]

	if { $state_code =="FLN" && ([sb get $sbn_blocking stat] != "d" && [sb get $sbn_blocking stat] != "") } {
	    set counter [expr $counter + 1 ]
	    ::MSN::WriteSB $sbn_blocking "CAL" "[lindex $user 0]" "CALReceived $sbn_blocking [lindex $user 0]"
	    
	}
   }

    set VerifyEnd 1
}


proc reset_counter { } {
    global counter
    set counter 0
}



proc create_sb_for_blocking { sbn_blocking recv} {
   global config


   if {[lindex $recv 0] == "913"} {
          status_log "Error: You can't see blocked people if you are offline\n" red
          return 1
   }

   if {[lindex $recv 4] != "CKI"} {
      status_log "$sbn_blocking: Unknown SP requested!\n" red
      return 1
   }
   
   status_log "create_sb_for_blocking: Opening SB $sbn_blocking\n" green

   sb set $sbn_blocking serv [split [lindex $recv 3] ":"]
   sb set $sbn_blocking connected "connect_blocking $sbn_blocking"
   sb set $sbn_blocking auth_cmd "USR"
   sb set $sbn_blocking auth_param "$config(login) [lindex $recv 5]"

   cmsn_socket $sbn_blocking
   return 0
}


proc connect_blocking {name } {
   status_log "connect_blocking $name (sock is [sb get $name sock])\n" green
   catch { fileevent [sb get $name sock] writable "" } res

   #Reset timeout timer
   sb set $name time [clock seconds]

   sb set $name stat "a"

   set cmd [sb get $name auth_cmd]
   set param [sb get $name auth_param]

   ::MSN::WriteSB $name $cmd $param "connected_blocking $name"

   

}

proc connected_blocking {name item} {
    global blocking_ready

    status_log "connected_blocking : Connected and ready to test \n"

    sb set $name time [clock seconds]
    sb set $name stat "i"

    set blocking_ready 1
}
