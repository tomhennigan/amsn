#///////////////////////////////////////////////////////////////////////////////
# Procedures concerning new personalised States with Auto Messaging features
# 27/12/2003 - Major rewrite by Alberto Díaz: Now the system has options to store
#		the states in states.xml or keep it temporal. Also created a cascading
#		menu-system to manage states. Removed non-xml status file.
#		Added options to switch or not to created state, option to have custom
#		nicknames for each status. We don't need backwards compatibility in 
#		custom status system because previous versions don't store them 

#///////////////////////////////////////////////////////////////////////////////
# LoadStateList ()
# Loads the list of states from the file in the HOME dir
proc LoadStateList {} {
	global HOME

	StateList clear

	set file_id [sxml::init [file join ${HOME} "states.xml"]]
	sxml::register_routine $file_id "states:newstate" "new_state"	    
	sxml::parse $file_id
	sxml::end $file_id
}

#///////////////////////////////////////////////////////////////////////////////
# SaveStateList ()
# Saves the list of states to the file in the HOME dir
proc SaveStateList {} {
	global HOME tcl_platform 
    
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
		puts $file_id "   <newstate>\n      <name>[lindex $tmp 0]</name>\n      <nick>[lindex $tmp 1]</nick>"
		puts $file_id "      <state>[lindex $tmp 2]</state>\n      <message>[lindex $tmp 4]</message>\n   </newstate>\n"
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
#	show : Dumps list to stdout, for debugging purposes only
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
	# Delete old menu to create new one
	if { [$path index end] != 8 } {
		$path delete 9 end
	}
	if { [winfo exists $path.otherstates] } {
		$path.otherstates delete 0 end
	}
    
	# Create new menu
	if { [StateList size] >= 3 } {
		set limit 3
	} else {
		set limit [StateList size]
	}

	for {set idx 0} {$idx <= [expr {$limit - 1}] } { incr idx 1 } {
		if { [winfo exists $path.$idx] } {
			$path.$idx delete 0 end
		} else {
			menu $path.$idx -tearoff 0 -type normal
		}
		$path.$idx add command -label "[trans changecustomstate ] [lindex [StateList get $idx] 0]" -command "ChCustomState $idx"
		$path.$idx add command -label "[trans editcustomstate] [lindex [StateList get $idx] 0]" -command "EditNewState 2 $idx"
		$path.$idx add command -label "[trans delete] [lindex [StateList get $idx] 0]" -command "DeleteState $idx $path"
		$path add cascade -label "[lindex [StateList get $idx] 0]" -menu $path.$idx
	}

	# Add cascade menu if there are more than 3 personal states
	if { [StateList size] > 3 } {
		if { [winfo exists $path.otherstates] != 1 } {
			menu $path.otherstates -tearoff 0 -type normal
		}
		for {} { $idx <= [expr {[StateList size] - 1}] } { incr idx } {
			if { [winfo exists $path.otherstates.$idx] } {
				$path.otherstates.$idx delete 0 end
			} else {
				menu $path.otherstates.$idx -tearoff 0 -type normal
			}
			$path.otherstates.$idx add command -label "[trans changecustomstate ] [lindex [StateList get $idx] 0]" -command "ChCustomState $idx"
			$path.otherstates.$idx add command -label "[trans editcustomstate] [lindex [StateList get $idx] 0]" -command "EditNewState 2 $idx"
			$path.otherstates.$idx add command -label "[trans delete] [lindex [StateList get $idx] 0]" -command "DeleteState $idx $path"
			$path.otherstates add cascade -label "[lindex [StateList get $idx] 0]" -menu $path.otherstates.$idx
		}
		$path.otherstates add separator
		$path.otherstates add command -label "[trans other]..." -command "EditNewState 0"
		$path add cascade -label [trans morepersonal] -menu $path.otherstates
	} else {
		$path add command -label "[trans other]..." -command "EditNewState 0"
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
		if { [lindex [StateList get $idx] 2] != "" } {
			set new_state [lindex [lindex $list_states [lindex [StateList get $idx] 2]] 0]
			if { $new_state == $user_stat } {
				set redraw 1
			}
			::MSN::changeStatus $new_state
			set automessage [StateList get $idx]
			set newname "[lindex [StateList get $idx] 1]"
			if { $newname != "" } {
				::MSN::changeName $config(login) $newname
				StateList promote $idx
			}
		}
	} else {
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
	global stemp chstate user_info
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
	entry $lfname.edesc -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 40
	label $lfname.lnick -text "[trans statenick] :" -font splainf
	entry $lfname.enick -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 40
	label $lfname.lstate -text "[trans state] :" -font splainf
	combobox::combobox $lfname.statebox -editable false -highlightthickness 0 -width 37 -bg #FFFFFF -font splainf -command ""
	label $lfname.lmsg -text "[trans stateautomsg] :" -font splainf
	text $lfname.emsg -background white -borderwidth 2 -relief ridge -width 40 -height 5 -font splainf
	pack .editstate.1 -expand 1 -fill both -side top -pady 15
	pack .editstate.lfname -expand 1 -fill both -side top
	grid $lfname.ldesc -row 1 -column 1 -sticky w -pady 5 -padx 5
	grid $lfname.edesc -row 1 -column 2 -sticky w -pady 5 -padx 5
	grid $lfname.lnick -row 2 -column 1 -sticky w -pady 5 -padx 5
	grid $lfname.enick -row 2 -column 2 -sticky w -pady 5 -padx 5
	grid $lfname.lstate -row 3 -column 1 -sticky w -pady 5 -padx 5
	grid $lfname.statebox -row 3 -column 2 -sticky w -pady 5 -padx 5
	grid $lfname.lmsg -row 4 -column 1 -sticky nw -pady 10 -padx 5
	grid $lfname.emsg -row 4 -column 2 -sticky w -pady 10 -padx 5

	# Frame for options
	frame .editstate.options -class Degt
	if { $mode != 2 } {
		if { [info exists stemp] } {
			unset stemp
		}
		checkbutton .editstate.options.stemp -text "[trans temp_state]" -onvalue 1 -offvalue 0
		pack .editstate.options.stemp -anchor w -side top -padx 10 -pady 0
	} elseif { $mode == 2 } {
		set stemp 2
	}
	if { [info exists chstate] } {
		unset chstate
	}
	checkbutton .editstate.options.chstate -text "[trans ch_to_state]" -onvalue 1 -offvalue 0
	pack .editstate.options.chstate -anchor w -side top -padx 10 -pady 0
	pack .editstate.options -fill both -side top
    
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
		$lfname.enick insert end [lindex [StateList get $idx] 1]
		$lfname.statebox select [lindex [StateList get $idx] 2]
		$lfname.emsg insert end [lindex [StateList get $idx] 4]
	} else {
		$lfname.enick insert end [urldecode [lindex $user_info 4]]
	}
	button .editstate.buttons.save -text [trans save] -font sboldf -command "ButtonSaveState $lfname $idx; destroy .editstate"
	pack .editstate.buttons.save .editstate.buttons.cancel -side left -padx 10 -pady 5
	pack .editstate.buttons -side top -fill x -pady 10

}

#///////////////////////////////////////////////////////////////////////////////
# ButtonSaveState ( lfname idx )
# GUI frontend for adding new states or editing old states
# this procedure is called when save is pressed, so it does what it needs
# mode is 0 for adding new one, no need for idx in this case
# mode is 1 for adding a temporary state
# mode is 2 for editing an old state, need to give idx of state to edit
proc ButtonSaveState { lfname { idx "" } } {
	# Global variables for temp status and changin the new state, from checkbutton on EditNewState
	global stemp chstate
	set mode $stemp
	lappend gui_info [$lfname.edesc get]
	lappend gui_info [$lfname.enick get]
	lappend gui_info [$lfname.statebox curselection]
	set message [$lfname.emsg get 0.0 end]
	set message [string range $message 0 end-1]
	set numlines [llength [split $message "\n"]]
	lappend gui_info $numlines
	lappend gui_info $message
	switch $mode {
		0 {
			StateList add $gui_info
			if { $chstate == 1 } {
				ChCustomState [expr {[StateList size] - 1}]
			}
			}
		1 {
			StateList add $gui_info
			ChCustomState [expr {[StateList size] - 1}]
			StateList unset 0
			}
		2 {
			StateList edit $gui_info $idx
			if { $chstate == 1 } {
				ChCustomState $idx
			}
			}
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
	SaveStateList
}

#///////////////////////////////////////////////////////////////////////////////
# DeleteState ( idx path )
# Deletes a state from the listbox in preferences
# idx is index of state to delete
proc DeleteState  { { idx "" } path} {
	if { $idx == "" } {
		return 0
	} elseif { $idx >= 2 } {
		StateList unset $idx
		if { [winfo exists $path.otherstates.$idx] } {
			destroy $path.otherstates.$idx
		}
	} else {
		StateList unset $idx
		if { [winfo exists $path.$idx] } {
			destroy $path.$idx
		}
	}
	# reset menus and listbox
	CreateStatesMenu .my_menu
}

#///////////////////////////////////////////////////////////////////////////////
# new_state {cstack cdata saved_data cattr saved_attr args}
#
# Adds a new state to the states list

proc new_state {cstack cdata saved_data cattr saved_attr args} {
	global user_info
	upvar $saved_data sdata

	if { ! [info exists sdata(${cstack}:name)] } { return 0 }	
	if { ! [info exists sdata(${cstack}:nick)] } { return 0 }
	if { ! [info exists sdata(${cstack}:state)] } { return 0 }
	if { ! [info exists sdata(${cstack}:message)] } { return 0 }

	lappend newstate "$sdata(${cstack}:name)"
	lappend newstate "$sdata(${cstack}:nick)"
	lappend newstate "$sdata(${cstack}:state)"
	set message "$sdata(${cstack}:message)"
	set numlines [llength [split $message "\n"]]
	lappend newstate $numlines
	lappend newstate $message
	StateList add $newstate
	return 0
}