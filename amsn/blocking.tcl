#!/usr/bin/wish
#########################################################
# blocking.tcl v 1.0	2003/05/22   KaKaRoTo
#########################################################

# Set global variable
set emailBList(0) ""
set show_blocked_list 0


#///////////////////////////////////////////////////////////////////////////////
# show_blocked { }
# open a dialog box with a list of all people who are blocking you 
# and online at the moment
proc show_blocked { } {
    global emailBList show_blocked_list 

 
    set wname ".blocked_list"


    # Update window if exists
     if { [catch {toplevel ${wname} -borderwidth 0 -highlightthickness 0 } res ] } {
	 destroy ${wname}
	 toplevel ${wname} -borderwidth 0 -highlightthickness 0
     }
    
    set_show_blocked_list 1

    wm group ${wname} .
    wm title ${wname}  "[trans youblocked]"
    frame ${wname}.c -relief flat -highlightthickness 0
    pack ${wname}.c -expand true -fill both -padx 10 -pady 0
    
    label ${wname}.c.txt -text "[trans blockmessage] : "
    grid ${wname}.c.txt -row 1 -column 1 -sticky w -pady 10


    for {set idx [expr [array size emailBList] - 1]} {$idx >= 0} {incr idx -1} {
	set row [expr 2 + $idx]

	label ${wname}.c.txt${idx} -text "$emailBList($idx)"
	grid ${wname}.c.txt${idx} -row $row -column 1 -sticky w -pady 10
    } 
    
    
    button ${wname}.c.ok -text [trans ok] -command "destroy ${wname}"
    
    set row [expr [expr [array size emailBList]] + 2]
    grid ${wname}.c.ok -row $row -column 0 -pady 10

    button ${wname}.c.refresh -text [trans Refresh] -command "VerifyBlocked ; show_blocked"
    grid ${wname}.c.refresh -row $row -column 2 -pady 10

    bind ${wname} <Destroy>  "set_show_blocked_list 0"
    
}

#///////////////////////////////////////////////////////////////////////////////
# set_show_blocked_list { value }
# set the global variable show_blocked_list to the value $value 
# this variable lets us know if the dialog box showing the list of blockers 
# is visible or not...
proc set_show_blocked_list { value } {
    global show_blocked_list 

    set show_blocked_list $value
}

#///////////////////////////////////////////////////////////////////////////////
# warn_blocked { email }
# adds the user who blocked you to the blockers list
proc warn_blocked { email } {
    global emailBList show_blocked_list

    set tmp_list [array get emailBList]
    
    for {set idx [expr [array size emailBList] - 1]} {$idx >= 0} {incr idx -1} {
	set emailBList([expr $idx + 1]) $emailBList($idx)
    } 
    set emailBList(0) $email

    if { $show_blocked_list == 1} {
	show_blocked
    }

    cmsn_draw_online

}

#///////////////////////////////////////////////////////////////////////////////
# VerifyBlocked { }
# tests every offline user in your contact list
proc VerifyBlocked {} {
    global list_users list_states emailBList counter

    set counter 0

   for {set idx [expr [array size emailBList] - 1]} {$idx >= 0} {incr idx -1} {
       unset emailBList($idx)
    } 

    cmsn_draw_online
 

    foreach user $list_users {

	set user_state_no [lindex $user 2]
	set state [lindex $list_states $user_state_no]
	set state_code [lindex $state 0]

	#TODO : set a counter to test a limited amount of people to avoid flooding

 	set counter [expr $counter + 1 ]
 	if { $counter > 5 } {
 	    after 5000 reset_counter
	    vwait counter
  	}


	if { $counter < 6 } {
	    if { $state_code =="FLN" } {
		::MSN::chatTo "[lindex $user 0]"
	    }
	}
   }
}

proc reset_counter { } {
    global counter
    set counter 0
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