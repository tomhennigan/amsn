#///////////////////////////////////////////////////////////////////////////////
# Procedures concerning new personalised States with Auto Messaging features

#///////////////////////////////////////////////////////////////////////////////
# LoadStateList ()
# Loads the list of states from the file in the HOME dir
proc LoadStateList {} {
    global HOME

    set use_xml 1
    if {[file readable "[file join ${HOME} states.xml]"] == 0} {
	set use_xml 0
    }
    if { $use_xml == 0 && [file readable "[file join ${HOME} states]"] == 0} {
	return 1
    }
    
    if { $use_xml == 1 } {

	StateList clear

	set file_id [sxml::init [file join ${HOME} "states.xml"]]
	sxml::register_routine $file_id "states:newstate" "new_state"	    
	if { [sxml::parse $file_id] < 0 } { set use_xml 0 }
	sxml::end $file_id
    }

    if { $use_xml == 0 } {
	# open file and check version
	set file_id [open "${HOME}/states" r]
	fconfigure $file_id -encoding utf-8
	gets $file_id tmp_data
	if {$tmp_data != "amsn_states_version 1"} {	;# config version not supported!
	    msg_box [trans wrongstatesversion $HOME]
	    close $file_id
	    return -1
   	}

	# Now add states from file to list after reseting it
	StateList clear
	set idx 0
	while {[gets $file_id tmp_data] != "-1"} {
	    lappend new_data $tmp_data
	    incr idx 1
	    if { $idx == 3 } {
		if { $tmp_data == 0 } {
		    set tmp_data 1 
		}
		for { set idx2 0 } { $idx2 < $tmp_data } { incr idx2 1 } {
		    append message [gets $file_id]
		    if { $idx2 < [expr {$tmp_data - 1}] } {
			append message "\n"
		    }
		}
		lappend new_data $message
		StateList add $new_data
		set idx 0
		unset new_data
		unset message
	    }
	}
	close $file_id
    } 

}

#///////////////////////////////////////////////////////////////////////////////
# SaveStateList ()
# Saves the list of states to the file in the HOME dir
proc SaveStateList {} {
    global HOME tcl_platform 
    
    if {$tcl_platform(platform) == "unix"} {
	set file_id [open "[file join ${HOME} states]" w 00600]
    } else {
	set file_id [open "[file join ${HOME} states]" w]
    }
    fconfigure $file_id -encoding utf-8
    puts $file_id "amsn_states_version 1"
    
    set idx 0
    while { $idx <= [expr {[StateList size] - 1}] } {
	set tmp [StateList get $idx]
	puts $file_id "[lindex $tmp 0]"
	puts $file_id "[lindex $tmp 1]"
	puts $file_id "[lindex $tmp 2]"
	puts $file_id "[lindex $tmp 3]"
	incr idx 1
    }
    close $file_id

    if {$tcl_platform(platform) == "unix"} {
	set file_id [open "[file join ${HOME} states.xml]" w 00600]
    } else {
	set file_id [open "[file join ${HOME} states.xml]" w]
    }
    fconfigure $file_id -encoding utf-8
    puts $file_id "<?xml version=\"1.0\"?>\n\n<states>"
    
    set idx 0
    while { $idx <= [expr {[StateList size] - 1}] } {
	set tmp [StateList get $idx]
	puts $file_id "   <newstate>\n      <name>[lindex $tmp 0]</name>"
	puts $file_id "      <state>[lindex $tmp 1]</state>\n      <message>[lindex $tmp 3]</message>\n   </newstate>\n"
	incr idx 1
    }

    puts $file_id "</states>"
    close $file_id

}


#///////////////////////////////////////////////////////////////////////////////
# StateList (action argument)
# Controls information for list of states
# action can be :
#	add : add a new state to the list (have to give a list with 3 elements)
#	promote : makes state given by argument (is an index) the last used (for aging)
#	get : Returns the state given by argument (is an index), returns 0 if dosen't exist
#	unset : Removes state given by argument (is an index)
#       size : Returns size
#	show : Dumps list to status_log, for debugging purposes only
#	clear : Clears the list
proc StateList { action { argument "" } {argument2 ""} } {
    variable StatesList
    switch $action {
	add {
	    set StatesList([array size StatesList]) $argument
	}

	edit {
	    set StatesList(${argument2}) $argument
	}

	promote {
	    set temp $StatesList($argument)
	    for {set idx $argument} {$idx > 0} {incr idx -1} {
		set StatesList($idx) $StatesList([expr {$idx - 1}])
	    }
	    set StatesList(0) $temp
	    unset temp
	}

	get {
	    return $StatesList($argument)
	}

	unset {
	    for {set idx $argument} {$idx < [expr {[array size StatesList] - 1}]} {incr idx} {
		set StatesList($idx) $StatesList([expr {$idx + 1}])
	    }
	    unset StatesList([expr {[array size StatesList] - 1}])
	}

	size {
	    return [array size StatesList]
	}

	show {
	    for {set idx 0} {$idx < [array size StatesList]} {incr idx} {
		#status_log "$idx : $StatesList($idx)\n"
		puts stdout "$idx : $StatesList($idx)\n"
	    }
	}
	clear {
	    if { [info exists StatesList] } {
		unset StatesList
	    }
	}
    }
}

#///////////////////////////////////////////////////////////////////////////////
# CreateStatesMenu (path)
# Creates the menu that will be added under the default states
# path points to the path of the menu where to add
proc CreateStatesMenu { path } {
    global automessage config
    #$path add separator
    # Delete old menu to create new one
    if { [$path index end] != 8 } {
	$path delete 9 end
    }
    if { [winfo exists .otherstates] } {
	.otherstates delete 0 end
    }
    
    # Create new menu
    if { [StateList size] >= 3 } {
	set limit 3
    } else {
	set limit [StateList size]
    }

    if { [StateList size] > 0 && [info exists automessage] &&
	 $automessage != -1} {
	$path add command -label "[trans editcurrentstate]..." -command "EditNewState 3"
    }

    for {set idx 0} {$idx <= [expr {$limit - 1}] } { incr idx 1 } {
	$path add command -label [lindex [StateList get $idx] 0] -command "ChCustomState $idx"
    }

    # Add cascade menu if there are more than 3 personal states
    if { [StateList size] > 3 } {
	#$path add cascade -label [trans morepersonal] -menu .otherstates
	$path add command -label [trans morepersonal] -command "tk_popup .otherstates \[winfo pointerx $path\] \[winfo pointery $path\]"
	if { [winfo exists .otherstates] != 1 } {
	    menu .otherstates -tearoff 0 -type normal
	}
	for {} { $idx <= [expr {[StateList size] - 1}] } { incr idx } {
	    .otherstates add command -label [lindex [StateList get $idx] 0] -command "ChCustomState $idx"
	}
	.otherstates add separator
	.otherstates add command -label "[trans other]..." -command "EditNewState 1"
    } else {
	$path add command -label "[trans other]..." -command "EditNewState 1"
    }
    $path add separator
    $path add command -label "[trans changenick]..." -command cmsn_change_name
    if { $config(getdisppic) == 1 } {
	$path add command -label "[trans changedisplaypic]..." -command pictureBrowser 
    } else {
	$path add command -label "[trans changedisplaypic]..." -command pictureBrowser -state disabled
    }
    $path add command -label "[trans cfgalarmall]..." -command "alarm_cfg all" 

}

#///////////////////////////////////////////////////////////////////////////////
# ChCustomState ( idx )
# Sets a new personal state with automessages
# idx indicates the index of the personal state in the StateList, 
# otherwise it indicates a normal state change (AWY, BSY, etc)
proc ChCustomState { idx } {
    global automessage user_info config automsgsent list_states user_stat
    set automessage "-1"
    set redraw 0
    if { [string is digit $idx] == 1 } {
	if { [lindex [StateList get $idx] 1] != "" } {
	    set new_state [lindex [lindex $list_states [lindex [StateList get $idx] 1]] 0]
	    if { $new_state == $user_stat } {
		set redraw 1
	    }
	    ::MSN::changeStatus $new_state
	    set automessage [StateList get $idx]
	    if { $config(autochangenick) == 1 } {
		#set newname "[urldecode [lindex $user_info 4]] - [lindex [StateList get $idx] 0]"
		#::MSN::changeName $config(login) $newname
	    }
	    StateList promote $idx
	}
    } else {
	if { $config(autochangenick) == 1 && $automessage != "-1" } {
	    #::MSN::changeName $config(login) [urldecode [lindex $user_info 4]]
	}
	set automessage "-1"
	if { $idx == $user_stat} {
	    set redraw 1
	}
	::MSN::changeStatus $idx
    }
    CreateStatesMenu .my_menu
    if { [info exists automsgsent] } {
	unset automsgsent
    }

    if { $redraw == 1 } {
	cmsn_draw_online
    }
}

#///////////////////////////////////////////////////////////////////////////////
# EditNewState ( mode {idx} )
# GUI frontend for adding new states or editing old states
# mode is 0 for adding new one, no need for idx in this case
# mode is 1 for adding a temporary state
# mode is 2 for editing an old state, need to give idx of state to edit
proc EditNewState { mode { idx "" } } {

    if { $mode == 2 } {
	if { $idx != "" } {
	    if { [StateList get $idx] == 0 } {
		status_log "Opened EditNewState with invalid idx : $idx\n"
		return 0
	    }
	} else {
	    status_log "Called EditNewState mode 2 no idx\n"
	    return 0
	}
    }
    
    if {[winfo exists .editstate]} {
	raise .editstate
	return 0
    }

    image create photo prefaway -file [file join [GetSkinFile pixmaps prefaway.gif]]

    toplevel .editstate
    wm group .editstate .
    
    wm geometry .editstate
    if { $mode == 0 || $mode == 1 } {
	wm title .editstate "[trans editnewstate]"
    } else {
	wm title .editstate "[trans editstate]"
    }
    wm transient .editstate .

    set lfname [LabelFrame:create .editstate.lfname -text [trans stateinfo]]
    pack $lfname -anchor n -side top -expand 1 -fill x
    
    frame .editstate.1 -class Degt
    label .editstate.1.away -image prefaway
    pack .editstate.1.away -side left -anchor nw
    
    if { $mode == 0 || $mode == 1 } {
	label .editstate.1.laway -text [trans statenewtext] -padx 10 -justify left
    } else { 
	label .editstate.1.laway -text [trans stateedittext] -padx 10 -justify left
    }
    pack .editstate.1.laway -fill both -side left
    
    label $lfname.ldesc -text "[trans statename] :" -font splainf 
    entry $lfname.edesc -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 30
    label $lfname.lstate -text "[trans state] :" -font splainf
    combobox::combobox $lfname.statebox \
	-editable false \
	-highlightthickness 0 \
	-width 25 \
	-bg #FFFFFF \
	-font splainf \
	-command ""
    label $lfname.lmsg -text "[trans stateautomsg] :" -font splainf
    text $lfname.emsg -background white -borderwidth 2 -relief ridge -width 40 -height 5 -font splainf
    pack .editstate.1 -expand 1 -fill both -side top -pady 15
    pack .editstate.lfname -expand 1 -fill both -side top
    grid $lfname.ldesc -row 1 -column 1 -sticky w -pady 5 -padx 5
    grid $lfname.edesc -row 1 -column 2 -sticky w -pady 5 -padx 5
    grid $lfname.lstate -row 2 -column 1 -sticky w -pady 5 -padx 5
    grid $lfname.statebox -row 2 -column 2 -sticky w -pady 5 -padx 5
    grid $lfname.lmsg -row 3 -column 1 -sticky nw -pady 10 -padx 5
    grid $lfname.emsg -row 3 -column 2 -sticky w -pady 10 -padx 5


    # Frame for buttons
    frame .editstate.buttons -class Degt
    button .editstate.buttons.cancel -text [trans close] -font sboldf -command "destroy .editstate"

    # Insert states in the combobox
    eval $lfname.statebox list insert end [list [trans online] \
					       [trans noactivity] \
					       [trans rightback] \
					       [trans onphone] \
					       [trans busy] \
					       [trans away] \
					       [trans gonelunch]]

    # select online in combobox by default
    $lfname.statebox select 0
    
    # Fill all entries if editing an existing state
    if { $mode == 2 } {

    	$lfname.edesc insert end [lindex [StateList get $idx] 0]
	$lfname.statebox select [lindex [StateList get $idx] 1]
	$lfname.emsg insert end [lindex [StateList get $idx] 3]
	button .editstate.buttons.save -text [trans save] -font sboldf -command "ButtonSaveState $lfname $mode $idx; destroy .editstate"

    } elseif { $mode == 3 } {
	global automessage

	$lfname.edesc insert end [lindex $automessage 0]
	$lfname.statebox select [lindex $automessage 1]
	$lfname.emsg insert end [lindex $automessage 3]

	if { "$automessage" == "[StateList get 0]" } {
	    button .editstate.buttons.save -text [trans save] -font sboldf -command "ButtonSaveState $lfname 2 0; destroy .editstate"
	} else {
	    button .editstate.buttons.save -text [trans save] -font sboldf -command "ButtonSaveState $lfname 3 0; destroy .editstate"
	}
    } else {
	button .editstate.buttons.save -text [trans save] -font sboldf -command "ButtonSaveState $lfname $mode $idx; destroy .editstate"
    }

    pack .editstate.buttons.save .editstate.buttons.cancel -side left -padx 10 -pady 5
    pack .editstate.buttons -side top -fill x -pady 10

}

#///////////////////////////////////////////////////////////////////////////////
# ButtonSaveState ( lfname mode )
# GUI frontend for adding new states or editing old states
# this procedure is called when save is pressed, so it does what it needs
# mode is 0 for adding new one, no need for idx in this case
# mode is 1 for adding a temporary state
# mode is 2 for editing an old state, need to give idx of state to edit
proc ButtonSaveState { lfname mode { idx "" } } {
    lappend gui_info [$lfname.edesc get]
    lappend gui_info [$lfname.statebox curselection]
    set message [$lfname.emsg get 0.0 end]
    set message [string range $message 0 end-1]
    set numlines [llength [split $message "\n"]]
    lappend gui_info $numlines
    lappend gui_info $message
    if { $mode == 0 } {
	StateList add $gui_info
    } elseif { $mode == 1 } {
	StateList add $gui_info
	ChCustomState [expr {[StateList size] - 1}]
	StateList unset 0
	CreateStatesMenu .my_menu
    } elseif { $mode == 2 } {
	StateList edit $gui_info $idx
	ChCustomState 0
	CreateStatesMenu .my_menu
    } elseif { $mode == 3 } {
	StateList add $gui_info
	ChCustomState [expr {[StateList size] - 1}]
	StateList unset 0
	CreateStatesMenu .my_menu
    }

    # reset menus and listbox
    CreateStatesMenu .my_menu

    if { ($mode == 0 || $mode == 2) && [winfo exists .cfg] } {
	set cfgname [Rnotebook:frame .cfg.notebook.nn 3]
	$cfgname.lfname2.f.f.statelist.box delete 0 end
	for { set idx 0 } { $idx < [StateList size] } {incr idx } {
	    $cfgname.lfname2.f.f.statelist.box insert end [lindex [StateList get $idx] 0]
	}
    }

}

#///////////////////////////////////////////////////////////////////////////////
# DeleteState ( idx )
# Deletes a state from the listbox in preferences
# idx is index of state to delete
proc DeleteState { { idx "" } } {
    if { $idx == "" } {
	return 0
    }

    StateList unset $idx
    
    # reset menus and listbox
    CreateStatesMenu .my_menu
    set cfgname [Rnotebook:frame .cfg.notebook.nn 3]
    $cfgname.lfname2.f.f.statelist.box delete 0 end
    for { set idx 0 } { $idx < [StateList size] } {incr idx } {
	$cfgname.lfname2.f.f.statelist.box insert end [lindex [StateList get $idx] 0]
    }
}

#///////////////////////////////////////////////////////////////////////////////
# new_state {cstack cdata saved_data cattr saved_attr args}
#
# Adds a new state to the states list

proc new_state {cstack cdata saved_data cattr saved_attr args} {
    upvar $saved_data sdata
    
    if { ! [info exists sdata(${cstack}:name)] } { return 0 }
    if { ! [info exists sdata(${cstack}:state)] } { return 0 }
    if { ! [info exists sdata(${cstack}:message)] } { return 0 }

    lappend newstate "$sdata(${cstack}:name)"
    lappend newstate "$sdata(${cstack}:state)"
    set message "$sdata(${cstack}:message)"
    set numlines [llength [split $message "\n"]]
    lappend newstate $numlines
    lappend newstate $message
    StateList add $newstate
    return 0
}
