#!/usr/bin/wish
#########################################################
# blocking.tcl v 1.0	2003/05/22   KaKaRoTo
#########################################################


set VerifyEnd 1

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
proc BeginVerifyBlocked { {interval 30} {interval2 120}} {
    global VerifyEnd user_stat

    while { true } {
	if { "$user_stat" == "NLN" } {
	    after [expr $interval * 1000] "VerifyBlocked 5 15000"
	} else {
	    after [expr $interval2 * 1000] "VerifyBlocked 5 15000"
	}

	set VerifyEnd 2

	while { $VerifyEnd != 1 } {
	    vwait VerifyEnd
	}



    }


}

#///////////////////////////////////////////////////////////////////////////////
# VerifyBlocked { }
# tests every offline user in your contact list
proc VerifyBlocked { {nbre_users 10} {interval 5000} } {
    global list_users list_states emailBList counter VerifyEnd

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

	if { $state_code =="FLN" } {
	    set counter [expr $counter + 1 ]
	    ::MSN::chatTo  "[lindex $user 0]"
	    
	}
   }

    set VerifyEnd 1
}

 
proc reset_counter { } {
    global counter
    set counter 1
}

proc show_RL { } {
    global list_rl list_users

    set list(0) ""
    unset list(0)

   puts "$list_rl ----- $list_users"

    foreach user $list_rl {

	puts "$user"
	if {[lsearch $list_users "$user *"] == -1} {
	    set tmp_list [array get list]
    
	    for {set idx [expr [array size list] - 1]} {$idx >= 0} {incr idx -1} {
		set list([expr $idx + 1]) $list($idx)
	    } 
	    set list(0) $user    
	}
	
    }
    set wname ".reverse_list"


    # Update window if exists
     if { [catch {toplevel ${wname} -borderwidth 0 -highlightthickness 0 } res ] } {
	 destroy ${wname}
	 toplevel ${wname} -borderwidth 0 -highlightthickness 0
     }
    
    wm group ${wname} .
    wm title ${wname}  "reverse list"
    frame ${wname}.c -relief flat -highlightthickness 0
    pack ${wname}.c -expand true -fill both -padx 10 -pady 0
    
    label ${wname}.c.txt -text "These people have added you to their list and are no longer in yours "
    grid ${wname}.c.txt -row 1 -column 1 -sticky w -pady 10


    for {set idx [expr [array size list] - 1]} {$idx >= 0} {incr idx -1} {
	set row [expr 2 + $idx]

	label ${wname}.c.txt${idx} -text "$list($idx)"
	grid ${wname}.c.txt${idx} -row $row -column 1 -sticky w -pady 10
    } 
    
    
    button ${wname}.c.ok -text [trans ok] -command "destroy ${wname}"
    
    set row [expr [expr [array size list]] + 2]
    grid ${wname}.c.ok -row $row -column 0 -pady 10

}