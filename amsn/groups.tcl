#	Group Administration
#	by: Dídimo Emilio Grimaldo Tuñón
# $Id$
#=======================================================================
# TODO LIST
#  - Keep track of transactions pending completion
#  - Investigate what happens when a group is deleted, does the
#    server send a new list? obviously the upper groups get
#    a reasigned number (???). Remember that the entries in
#    the address book (::abook) contains the group IDs received
#    in the Forward List.
#	* group id is left unused until a new group is added.

namespace eval ::groups {
	namespace export Init Enable Disable Set Rename Delete Add \
		RenameCB DeleteCB AddCB \
		GetList ToggleStatus UpdateCount IsExpanded \
		menuCmdMove menuCmdCopy

	if { $initialize_amsn == 1 } {
	
		#
		# P R I V A T E
		#
		variable parent "";
		variable entryid -1;
		variable groupname "";	# Temporary variable for TCL crappiness
		variable bShowing;		# (array) Y=shown/expanded N=hidden/collapsed
		variable uMemberCnt;		# (array) member count for that group
		variable uMemberCnt_online;	# (array) member count for that group
		
	}

	#
	proc menuCmdDelete {gid {pars ""}} {
		::groups::Delete $gid dlgMsg
	}

	proc menuCmdCopy {newgid {paramlist ""}} {
		set passport [lindex $paramlist 0]
		set name [::abook::getNick $passport]
		::MSN::copyUser $passport $newgid $name
	}


	proc menuCmdMove {newgid currgid {paramlist ""}} {
		set passport [lindex $paramlist 0]
		set name [::abook::getNick $passport]
		::MSN::moveUser $passport $currgid $newgid $name
		#status_log "Moving user $passport from $currgid to $newgid\n" white
	}

	#<dlgMsg>
	proc dlgMsg {msg} {
		tk_messageBox -icon error -message $msg -type ok
	}
   
	#<dlgAddGroup> Dialog to add a group
	proc dlgAddGroup {} {
		if {[winfo exists .dlgag]} {
			return
		}
	
		set bgcol2 #ABC8D2
	
		toplevel .dlgag -highlightcolor $bgcol2
		wm title .dlgag "[trans groupadd]"
		frame .dlgag.d -bd 1 
		label .dlgag.d.lbl -text "[trans group]" -font sboldf
		entry .dlgag.d.ent -width 20 -bg #FFFFFF -font splainf
		pack .dlgag.d.lbl .dlgag.d.ent -side left
		bind .dlgag.d.ent <Return> { 
			::groups::Add "[.dlgag.d.ent get]" dlgMsg; 
			destroy .dlgag
		}
		frame .dlgag.b 
		button .dlgag.b.ok -text "[trans ok]"  -font sboldf \
			-command {
				::groups::Add "[.dlgag.d.ent get]" dlgMsg; 
				destroy .dlgag
			}
		button .dlgag.b.cancel -text "[trans cancel]"  -font sboldf \
			-command "destroy .dlgag"
		pack .dlgag.b.ok .dlgag.b.cancel -side left
		pack .dlgag.d .dlgag.b -side top
	}

	proc dlgRenGroup {} {
		if {[winfo exists .dlgrg]} {
		return
		}

		set bgcol2 #ABC8D2
	
		toplevel .dlgrg -highlightcolor $bgcol2
		wm title .dlgrg "[trans grouprename]"
		frame .dlgrg.d -bd 1 
		label .dlgrg.d.lbl -text "[trans groupoldname]:" -font sboldf
		::groups::updateMenu option .dlgrg.d.old
		.dlgrg.d.old configure 
		pack .dlgrg.d.lbl .dlgrg.d.old -side left -padx 10 -pady 5 
	
		frame .dlgrg.n -bd 1 
		label .dlgrg.n.lbl -text "[trans groupnewname]:" -font sboldf
		entry .dlgrg.n.ent -width 20 -bg #FFFFFF -font splainf
		pack .dlgrg.n.lbl .dlgrg.n.ent -side left
		
		frame .dlgrg.b 
		button .dlgrg.b.ok -text "[trans ok]" -font sboldf \
			-command { \
			::groups::Rename $::groups::groupname "[.dlgrg.n.ent get]" dlgMsg;\
			destroy .dlgrg }
		button .dlgrg.b.cancel -text "[trans cancel]" -font sboldf \
			-command "destroy .dlgrg"
		pack .dlgrg.b.ok .dlgrg.b.cancel -side left -pady 5
			
		pack .dlgrg.d .dlgrg.n .dlgrg.b -side top
	
	}

	# Used to perfom the group renaming without special dialogues
	proc ThisOkPressed { gid } {
		if [winfo exists .dlgthis] {
			set gname [GetName $gid]
			::groups::Rename $gname [.dlgthis.data.ent get] dlgMsg
			destroy .dlgthis
		}
	}
   
	# New simplified renaming dialog
	proc dlgRenameThis {gid} {
	
		if {[winfo exists .dlgthis]} {
			destroy .dlgthis
		}
		set bgcol2 #ABC8D2
	
		toplevel .dlgthis -highlightcolor $bgcol2
		wm title .dlgthis "[trans grouprename]"
		frame .dlgthis.data -bd 1 
		label .dlgthis.data.lbl -text "[trans groupnewname]:" -font sboldf
		entry .dlgthis.data.ent -width 20 -bg #FFFFFF -font splainf
		.dlgthis.data.ent insert end [GetName $gid]
		bind .dlgthis.data.ent <Return> "::groups::ThisOkPressed $gid"
		pack .dlgthis.data.lbl .dlgthis.data.ent -side left
		
		frame .dlgthis.buttons 
		button .dlgthis.buttons.ok -text "[trans ok]" -command "::groups::ThisOkPressed $gid" -font sboldf
		button .dlgthis.buttons.cancel -text "[trans cancel]" -command "destroy .dlgthis" -font sboldf
		pack .dlgthis.buttons.ok .dlgthis.buttons.cancel -side left -pady 5
			
		pack .dlgthis.data .dlgthis.buttons -side top
	
	}
   
	# New group menu, for contact list only, no for management in toolbar
	# it avoids complex group selection when renaming or deleting groups
	proc GroupMenu {gid cx cy} {
		if [winfo exists .group_handler] {
			destroy .group_handler
		}
		# The submenu of standard group actions
		menu .group_handler -tearoff 0 -type normal
		.group_handler add command -label "[trans delete]" -command "::groups::Delete $gid dlgMsg"
		.group_handler add command -label "[trans rename]..." -command "::groups::dlgRenameThis $gid"
		.group_handler add separator
		.group_handler add command -label "[trans groupadd]..." -command ::groups::dlgAddGroup
		tk_popup .group_handler $cx $cy
	}
   
	# Used to display the list of groups that are candidates for
	# deletion in the Delete Group... & Rename Group menus
	proc updateMenu {type path {cb ""} {pars ""}} {
		if {$type == "menu"} {
			$path delete 0 end
		}
		# The Unique Group ID (MSN) is sent with the RemoveGroup message.
		# The first group's ID is zero (0) (MSN)
		set glist [::groups::GetList]
		
		#Let's sort the groups by name
		set thelistnames [list]
		
		foreach gid $glist {
			set thename [::groups::GetName $gid]
			lappend thelistnames [list "$thename" $gid]
		}
		
		set sortlist [lsort -dictionary -index 0 $thelistnames ]
		set glist [list]
		
		foreach gdata $sortlist {
			lappend glist [lindex $gdata 1]
		}              
		
		set gcnt [llength $glist]
		
		for {set i 0} {$i < $gcnt} {incr i} {
			set gid   [lindex $glist $i]	;# Group ID
			set gname [::groups::GetName $gid]	;# Group Name (unencoded)
			
			if {$type == "menu"} {
				$path add command -label $gname -command "$cb $gid $pars"
			} else {
				if {$i == 0} {
				set mpath [tk_optionMenu $path ::groups::groupname $gname]
				} else {
				$mpath add radiobutton -label $gname -variable ::groups::groupname
				}
			}
			# To obtain the label of the i'th menu entry
			# set ithLabel [$path entrycget $i -label]
		}
	}

	#
	# P R O T E C T E D
	#
	# ----------------- Callbacks -------------------
	proc RenameCB {pdu} {  # REG 25 12066 15 New%20Name 0
		#variable groups
		array set groups [::abook::getContactData contactlist groups]
	
		set trid [lindex $pdu 1]
		set lmod [lindex $pdu 2]
		set gid  [lindex $pdu 3]
		set gname [urldecode [lindex $pdu 4]]
	
		set groups($gid) $gname
	
		::abook::setContactData contactlist groups [array get groups]
		# Update the Delete Group... menu
		::groups::updateMenu menu .group_list ::groups::menuCmdDelete
	}

	proc DeleteCB {pdu} {	# RMG 24 12065 15
		variable bShowing
		variable uMemberCnt
		variable uMemberCnt_online
		array set groups [abook::getContactData contactlist groups]
		
		set trid [lindex $pdu 1]
		set lmod [lindex $pdu 2]
		set gid  [lindex $pdu 3]
	
		# Update our local information
		unset groups($gid)
		unset uMemberCnt($gid)
		unset uMemberCnt_online($gid)
		unset bShowing($gid)
	
		# TODO: We are out of sync, maybe we should request
		# a new list
		abook::setContactData contactlist groups [array get groups]
		# Update the Delete Group... menu
		::groups::updateMenu menu .group_list ::groups::menuCmdDelete
	}

	proc AddCB {pdu} {	# ADG 23 12064 New%20Group 15 =?Ñ?-CC
		#variable groups
		variable uMemberCnt
		variable uMemberCnt_online
		variable bShowing
		array set groups [abook::getContactData contactlist groups]
	
		set trid [lindex $pdu 1]
		set lmod [lindex $pdu 2]
		set gname [urldecode [lindex $pdu 3]]
		set gid  [lindex $pdu 4]
	
		set groups($gid) $gname
		set uMemberCnt($gid) 0
		set uMemberCnt_online($gid) 0
		set bShowing($gid) 1
		abook::setContactData contactlist groups [array get groups]	
		::groups::updateMenu menu .group_list ::groups::menuCmdDelete
	}
   
	proc ToggleStatus {gid} {
		variable bShowing
	
		if {![info exists bShowing($gid)]} {
			return 0
		}
	
		if { $bShowing($gid) == 1 } {
			set bShowing($gid) 0
		} else {
			set bShowing($gid) 1
		}
		
		::config::setKey expanded_group_$gid $bShowing($gid)
	
		return $bShowing($gid)
	}
   
	proc UpdateCount {gid rel_qty {online ""}} {
		variable uMemberCnt
		variable uMemberCnt_online
		variable bShowing
	
		if {![info exists bShowing($gid)]} {
			return -1
		}
		if {($rel_qty == 0) || ($rel_qty == "clear")} {
			set uMemberCnt($gid) 0
			set uMemberCnt_online($gid) 0
		} elseif {("$online" == "online")} {
			incr uMemberCnt($gid) $rel_qty
			incr uMemberCnt_online($gid) $rel_qty
		} else {
			incr uMemberCnt($gid) $rel_qty
		}
		return $uMemberCnt($gid)
	}

	proc IsExpanded {gid} {
		variable bShowing
	
		return $bShowing($gid)
	}

	#
	# P U B L I C
	#
	#<Init> Initialize the non-mutable part of the menus and the
	#	   core of the group administration. At this point we do not
	#	   have any information about the groups (we are not connected)
	proc Init {p} {
		variable parent
		variable entryid
	
		# The submenu with the list of defined groups (to be filled)
		menu .group_list -tearoff 0 -type normal
	
		# The submenu of standard group actions
		menu .group_menu -tearoff 0 -type normal
		.group_menu add command -label "[trans groupadd]..." \
			-command ::groups::dlgAddGroup
		.group_menu add cascade -label "[trans groupdelete]" \
			-menu .group_list
		.group_menu add command -label "[trans grouprename]..." \
			-command ::groups::dlgRenGroup
	
		# Attach the Group Administration entry to the parent menu
		$p add cascade -label "[trans admingroups]" -state disabled \
			-menu .group_menu
	
		set parent $p		;# parent menu where we attach
		# We need the next to dynamically enable/disable the menu widget
		set entryid [$p index "[trans admingroups]"]
	
	
	}

	proc Reset {} {
	
		#variable groups
		variable bShowing
		variable uMemberCnt
	
	
		# These are the default groups. Used when not sorting the
		# display by user-defined groups
		set uMemberCnt(online)	0
		set uMemberCnt(offline) 0
		set uMemberCnt(blocked) 0
		set bShowing(online)	1
		set bShowing(offline)	1
		set bShowing(blocked)   1
	
		::abook::setContactData contactlist groups ""
		::abook::unsetConsistent
		#Clear list of groups
		#set g_entries [array names groups]
		#foreach gr $g_entries {
		#   unset groups($gr)
		#}
	
	}

	# Must only Enable it when the list of groups is already available!
	# That's because from here we rebuild the group submenu (list)
	proc Enable {} {
		variable parent
		variable entryid
	
		::groups::updateMenu menu .group_list ::groups::menuCmdDelete
		# The entryid of the parent is 0
		$parent entryconfigure $entryid -state normal
		#status_log "Groups: menu enabled\n" blue
	}

	# Call this one when going offline (disconnecting)
	proc Disable {} {
		variable parent 
		variable entryid
	
		$parent entryconfigure $entryid -state disabled
	}

	# Gets called whenever we receive a List Group (LSG) packet,
	# this happens in the early stages of the connection.
	# MSN Packet: LSG <x> <trid> <cnt> <total> <gid> <name> 0
	proc Set { nr name } {	# There is a new group in the list
		#variable groups
		variable uMemberCnt
		variable uMemberCnt_online
		variable bShowing
		array set groups [abook::getContactData contactlist groups]
		
		set name [urldecode $name]
		set groups($nr) $name
		set uMemberCnt($nr) 0
		set uMemberCnt_online($nr) 0
		set bShowing($nr)   1
		
		abook::setContactData contactlist groups [array get groups]       
		
		#status_log "Groups: added group $nr ($name)\n" blue
	}

	# Get a group's name (decoded) given its ID (0..n)
	proc GetName {nr} {
		#variable groups
		array set groups [abook::getContactData contactlist groups]
		
		if {![info exists groups($nr)]} {
			return ""
		}
		return $groups($nr)
	}

	# Does a reverse lookup from group name to find it's id.
	# Returns: -1 on error (not found), otherwise 0..n
	proc GetId {gname} {
		#variable groups
		array set groups [abook::getContactData contactlist groups]
		# Groups are stored here in decoded state. When sent to
		# the server we must urlencode them!
		set gname [string trim $gname]
		foreach group [array names groups] {
			if {$groups($group) == $gname} {
				return $group
			}
		}
		return -1
	}

	proc Exists {gname} {
		#variable groups
		array set groups [abook::getContactData contactlist groups]
	
		set gname [string trim $gname]
		foreach group [array names groups] {
			if {$groups($group) == $gname} {
				return 1
			}
		}
		return 0
	}

	proc Rename { old new {ghandler ""}} {
		set old [string trim $old]
		set new [string trim $new]
	
		if {$old == $new || $old == ""} { return 0 }
	
		if {![::groups::Exists $old]} {
		if {$ghandler != ""} {
			set retval [eval "$ghandler \"$old : [trans groupunknown]\""]
		}
		return 0
		}
	
		if {[::groups::Exists $new]} {
		if {$ghandler != ""} {
			set retval [eval "$ghandler \"$new : [trans groupexists]\""]
		}
		return 0
		}
	
		set currentGid [::groups::GetId $old]
		if {$currentGid == -1} {
		if {$ghandler != ""} {
			set retval [eval "$ghandler \"[trans groupmissing]: $old\""]
		}
		return 0
		}
	
		#TODO Keep track of transaction number
		set new [urlencode $new]
		::MSN::WriteSB ns "REG" "$currentGid $new 0"
		# RenameCB() should be called when we receive the REG
		# packet from the server
		return 1
	}

	proc Add { gname {ghandler ""}} {
		if {[::groups::Exists $gname]} {
		if {$ghandler != ""} {
		set retval [eval "$ghandler \"[trans groupexists]!\""]
		}
		return 0
		}
	
		set gname [urlencode $gname]
		::MSN::WriteSB ns "ADG" "$gname 0"
		# MSN sends back "ADG %T %M $gname gid junkdata"
		# AddCB() should be called when we receive the ADG
		# packet from the server
		return 1
	}
        
	proc Delete { gid {ghandler ""}} {
		set gname [::groups::GetName $gid]
		if {![::groups::Exists $gname]} {
		if {$ghandler != ""} {
		set retval [eval "$ghandler \"[trans groupunknown]!\""]
		}
		return 0
		}
	
		# Cannot and must not delete a group until it is empty
		if {$::groups::uMemberCnt($gid) != 0} {
		if {$ghandler != ""} {
		set retval [eval "$ghandler \"[trans groupnotempty]!\""]
		}
		return 0
		}
		
		::MSN::WriteSB ns "RMG" $gid
		# MSN sends back "RMG %T %M $gid"
		# DeleteCB() should be called when we receive the RMG
		# packet from the server
		return 1
	}

	proc GetList {{opt ""}} {
		#variable groups
		array set groups [abook::getContactData contactlist groups]

		set g_list [list]
		set g_entries [array get groups]
		set items [llength $g_entries]
		for {set idx 0} {$idx < $items} {incr idx 1} {
		set var_pk [lindex $g_entries $idx]
		incr idx 1
		set var_value [lindex $g_entries $idx]
		if {$opt != "-names"} {
			lappend g_list $var_pk	;# Return the key only
		} else {
			lappend g_list $var_value;# Return the value only
		}
		}
		set g_list [lsort -increasing $g_list]
		return $g_list
	    }
}

