#///////////////////////////////////////////////////////////////////////////////
# Procedures concerning new personalised States with Auto Messaging features
# 27/12/2003 - Major rewrite by Alberto D�az: Now the system has options to store
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
	if { [file exists [file join ${HOME} "states.xml"]] } {
		if { [catch {

			set file_id [sxml::init [file join ${HOME} "states.xml"]]
			sxml::register_routine $file_id "states:newstate" "new_state"
			sxml::parse $file_id
			sxml::end $file_id
		} res] } {
			::amsn::errorMsg "[trans corruptstates [file join ${HOME} "states.xml.old"]]"
			file copy [file join ${HOME} "states.xml"] [file join ${HOME} "states.xml.old"]
		}
	}
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
		set tmp0 [::sxml::xmlreplace [lindex $tmp 0]]
		set tmp1 [::sxml::xmlreplace [lindex $tmp 1]]
		set tmp2 [::sxml::xmlreplace [lindex $tmp 2]]
		set tmp4 [::sxml::xmlreplace [lindex $tmp 4]]
		puts $file_id "   <newstate>\n      <name>$tmp0</name>\n      <nick>$tmp1</nick>"
		puts $file_id "      <state>$tmp2</state>\n      <message>$tmp4</message>\n   </newstate>\n"
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
	global automessage iconmenu
	# Delete old menu to create new one
	if { [$path index end] != 7 } {
		$path delete 8 end
	}
	if { [winfo exists $path.editstates] && [winfo exists $path.deletestates] } {
		$path.editstates delete 0 end
		$path.deletestates delete 0 end
	} else {
		menu $path.editstates -tearoff 0 -type normal
		menu $path.deletestates -tearoff 0 -type normal
	}
#	if { [::config::getKey dock] != 0 && [winfo exists $iconmenu] && [$iconmenu index end] != 16} {
#		$iconmenu delete 17 end
#	}
    
	# Create new menu
	if { [StateList size] >= 3 } {
		set limit 3
	} else {
		set limit [StateList size]
	}

	for {set idx 0} {$idx <= [expr {$limit - 1}] } { incr idx 1 } {
		$path.deletestates add command -label "[lindex [StateList get $idx] 0]" -command "DeleteState $idx $path"
		$path.editstates add command -label "[lindex [StateList get $idx] 0]" -command "EditNewState 2 $idx"
		$path add command -label "[lindex [StateList get $idx] 0]" -command "ChCustomState $idx"
#		if { [::config::getKey dock] != 0 && [winfo exists $iconmenu] } {
#			$iconmenu add command -label "   [lindex [StateList get $idx] 0]" -command "ChCustomState $idx" -state disabled
#		}
	}

	# Add cascade menu if there are more than 3 personal states
	if { [StateList size] > 3 } {
		if { ![winfo exists $path.otherstates] } {
			menu $path.otherstates -tearoff 0 -type normal
		} else {
			$path.otherstates delete 0 end
		}
#		if { [::config::getKey dock] != 0 && [winfo exists $iconmenu] && ![winfo exists $iconmenu.otherstates] } {
#			menu $iconmenu.otherstates -tearoff 0 -type normal
#		} elseif { [::config::getKey dock] != 0 && [winfo exists $iconmenu.otherstates] } {
#			$iconmenu.otherstates delete 0 end
#		}
		for {} { $idx <= [expr {[StateList size] - 1}] } { incr idx } {
			$path.deletestates add command -label "[lindex [StateList get $idx] 0]" -command "DeleteState $idx $path"
			$path.editstates add command -label "[lindex [StateList get $idx] 0]" -command "EditNewState 2 $idx"
			$path.otherstates add command -label "[lindex [StateList get $idx] 0]" -command "ChCustomState $idx"
#			if { [::config::getKey dock] != 0 && [winfo exists $iconmenu] } {
#				$iconmenu.otherstates add command -label "[lindex [StateList get $idx] 0]" -command "ChCustomState $idx"
#			}
		}
#		if { [::config::getKey dock] != 0 && [winfo exists $iconmenu.otherstates] } {
#			$iconmenu add cascade -label "   [trans morepersonal]" -menu $iconmenu.otherstates -state disabled
#			$iconmenu add separator
#			$iconmenu add command -label "[trans close]" -command "close_cleanup;exit"
#		}
		$path add cascade -label "[trans morepersonal]" -menu $path.otherstates
		$path add separator
		$path add command -label "[trans newstate]..." -command "EditNewState 0"
		$path add cascade -label "[trans editcustomstate]" -menu $path.editstates
		$path add cascade -label "[trans deletecustomstate]" -menu $path.deletestates
	} else {
		$path add separator
		$path add command -label "[trans newstate]" -command "EditNewState 0"
		if { [StateList size] != 0 } {
			$path add cascade -label "[trans editcustomstate]" -menu $path.editstates
			$path add cascade -label "[trans deletecustomstate]" -menu $path.deletestates
		}
#		if { [::config::getKey dock] != 0 && [winfo exists $iconmenu] } {
#			$iconmenu add separator
#			$iconmenu add command -label "[trans close]" -command "close_cleanup;exit"
#		}
	}
	$path add separator
	$path add command -label "[trans changenick]..." -command cmsn_change_name
	if { [::config::getKey getdisppic] == 1 } {
		$path add command -label "[trans changedisplaypic]..." -command pictureBrowser 
	} else {
		$path add command -label "[trans changedisplaypic]..." -command pictureBrowser -state disabled
	}
	$path add command -label "[trans cfgalarmall]..." -command "::alarms::configDialog all"
#	statusicon_proc [MSN::myStatusIs]

	if { [::config::getKey dock] != 0 && [winfo exists $iconmenu.imstatus] && $path != "$iconmenu.imstatus" } {
		CreateStatesMenu $iconmenu.imstatus
	}
	if { [::config::getKey dock] != 0 && [winfo exists $iconmenu.imstatus] && $path == "$iconmenu.imstatus" } {
		$path delete [expr "[$path index end] - 3"] end
	}
}

#///////////////////////////////////////////////////////////////////////////////
# ChCustomState ( idx )
# Sets a new personal state with automessages
# idx indicates the index of the personal state in the StateList, 
# otherwise it indicates a normal state change (AWY, BSY, etc)
proc ChCustomState { idx } {
	global HOME automessage automsgsent original_nick
	set automessage "-1"
	set redraw 0
	if { [string is digit $idx] == 1 } {
		if { [lindex [StateList get $idx] 2] != "" } {
			if {![info exists original_nick] && [::config::getKey storename]} {
				set original_nick [::abook::getPersonal nick]
			}
			#set new_state [lindex [lindex $list_states [lindex [StateList get $idx] 2]] 0]
			set new_state [::MSN::numberToState [lindex [StateList get $idx] 2]]
			if { $new_state == [::MSN::myStatusIs] } {
				set redraw 1
			}
			set automessage [StateList get $idx]
			set newname "[lindex [StateList get $idx] 1]"
			if { $newname != "" } {
					catch {
						set nickcache [open [file join ${HOME} "nick.cache"] w]
						fconfigure $nickcache -encoding utf-8
						puts $nickcache $original_nick
						puts $nickcache $newname
						puts $nickcache [::abook::getPersonal login]
						close $nickcache
					}
				set newname [string map { "\\" "\\\\" "\$" "\\\$" } $newname]
				set newname [string map { "\\\$nick" "\${original_nick}" } $newname]
				set newname [subst -nocommands $newname]
				::MSN::changeName [::config::getKey login] $newname
				StateList promote $idx
			}
		}
	} else {
		set automessage "-1"
		if { $idx == [::MSN::myStatusIs]} {
			set redraw 1
		}
		if {[info exists original_nick] && [::config::getKey storename]} {
			::MSN::changeName [::config::getKey login] $original_nick
			unset original_nick
			catch { file delete [file join ${HOME} "nick.cache"] }
		}
		set new_state $idx
	}

	if { [info exists new_state] } {
		::MSN::changeStatus $new_state

		#PostEvent 'ChangeMyState' when the user changes his/her state
		set evPar(automessage) $automessage
		set evPar(idx) $new_state
		::plugins::PostEvent ChangeMyState evPar
	} else {
		status_log "ChCustomState where state didnt exist !!!" red
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
	global stemp chstate
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

	::skin::setPixmap prefaway [file join [::skin::GetSkinFile pixmaps prefaway.gif]]

	toplevel .editstate
	#wm group .editstate .
    
	#wm geometry .editstate
	if { $mode == 0 || $mode == 1 } {
		wm title .editstate "[trans editnewstate]"
	} else {
		wm title .editstate "[trans editstate]"
	}
	#ShowTransient .editstate

	set lfname [LabelFrame:create .editstate.lfname -text [trans stateinfo] -font splainf]
	pack $lfname -anchor n -side top -expand 1 -fill x
    
	frame .editstate.1 -class Degt
	label .editstate.1.away -image [::skin::loadPixmap prefaway]
	pack .editstate.1.away -side left -anchor nw
    
	if { $mode == 0 || $mode == 1 } {
		label .editstate.1.laway -text [trans statenewtext] -padx 10 -justify left -font splainf
	} else { 
		label .editstate.1.laway -text [trans stateedittext] -padx 10 -justify left -font splainf
	}
	pack .editstate.1.laway -fill both -side left
    
	label $lfname.ldesc -text "[trans statename] :" -font splainf 
	entry $lfname.edesc -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 40
	label $lfname.lnick -text "[trans statenick] :" -font splainf
	entry $lfname.enick -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 40
	menubutton $lfname.nickhelp -font sboldf -text "<-" -menu $lfname.nickhelp.menu
	menu $lfname.nickhelp.menu -tearoff 0
	$lfname.nickhelp.menu add command -label [trans nick] -command "$lfname.enick insert insert \\\$nick"
	$lfname.nickhelp.menu add separator
	$lfname.nickhelp.menu add command -label [trans delete] -command "$lfname.enick delete 0 end"
	
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
	grid $lfname.nickhelp -row 2 -column 3 -sticky w -pady 5 -padx 5
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
		checkbutton .editstate.options.stemp -text "[trans temp_state]" -onvalue 1 -offvalue 0 -font sboldf
		pack .editstate.options.stemp -anchor w -side top -padx 10 -pady 0
	} elseif { $mode == 2 } {
		set stemp 2
	}
	if { [info exists chstate] } {
		unset chstate
	}
	checkbutton .editstate.options.chstate -text "[trans ch_to_state]" -onvalue 1 -offvalue 0 -font sboldf
	pack .editstate.options.chstate -anchor w -side top -padx 10 -pady 0
	pack .editstate.options -fill both -side top
    
	# Frame for buttons
	frame .editstate.buttons -class Degt
	button .editstate.buttons.cancel -text [trans cancel] -command "destroy .editstate"

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
	}
	#else {
	#	$lfname.enick insert end [::abook::getPersonal nick]
	#}
	button .editstate.buttons.save -text [trans ok] -command "ButtonSaveState $lfname $idx; destroy .editstate"
	pack .editstate.buttons.save .editstate.buttons.cancel -side right -padx 10 -pady 5
	pack .editstate.buttons -side top -fill x -pady 10
	moveinscreen .editstate
	catch {focus .editstate}
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
			StateList unset [expr {[StateList size] - 1}]
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
	#REMOVE THAT WHEN MAC OS X WILL MOVE TO BWIDGET IN PREFERENCES
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		set cfgname [Rnotebook:frame .cfg.notebook.nn 3]
		} else {
		set cfgname [[.cfg.notebook.nn getframe session].sw.sf getframe]
		}
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

proc DeleteStateListBox  { { idx "" } path} {
	if { $idx == "" } {
		return 0
	} else {
		StateList unset $idx
		if { [winfo exists $path] } {
			$path delete $idx
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
	upvar $saved_data sdata

	if { ! [info exists sdata(${cstack}:name)] } { return 0 }	
	if { ! [info exists sdata(${cstack}:state)] } { return 0 }
	if { ! [info exists sdata(${cstack}:message)] } { return 0 }

	lappend newstate "$sdata(${cstack}:name)"
	
	# This if, for compatibility with previous versions of amsn
	# that doesn't support custom nicknames per custom status:
	# If the states:newstate contains :nick, append it to the
	# matrix, else append "", as a non-change nick
	if { [info exists sdata(${cstack}:nick)] } {
		lappend newstate "$sdata(${cstack}:nick)"
	} else {
		lappend newstate ""
	}
	
	lappend newstate "$sdata(${cstack}:state)"
	set message "$sdata(${cstack}:message)"
	set numlines [llength [split $message "\n"]]
	lappend newstate $numlines
	lappend newstate $message
	StateList add $newstate
	return 0
}
