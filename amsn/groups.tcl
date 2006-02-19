#	Group Administration
#	by: D�imo Emilio Grimaldo Tu�n
# $Id$
#=======================================================================
# TODO LIST
#  - Keep track of transactions pending completion
#  - Investigate what happens when a group is deleted, does the
#    server send a new list? obviously the upper groups get
#    a reassigned number (???). Remember that the entries in
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
		
		global pgc
	}

	#
	proc menuCmdDelete {gid {pars ""}} {
		::groups::Delete $gid dlgMsg
	}

	proc menuCmdRename {gid} {
		::groups::dlgRenameThis $gid
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
		::amsn::errorMsg $msg
	}
   
	#<dlgAddGroup> Dialog to add a group
	proc dlgAddGroup {} {

		global pgc

		set w .dlgag

		if {[winfo exists $w]} {
			set pgc 0
			return
		}
	
		set bgcol2 #ABC8D2
	
		toplevel $w -highlightcolor $bgcol2
		wm title $w "[trans groupadd]"

		frame $w.groupname -bd 1 
		label $w.groupname.lbl -text "[trans group]" -font sboldf
		entry $w.groupname.ent -width 20 -bg #FFFFFF -font splainf
		pack $w.groupname.lbl $w.groupname.ent -side left

		frame $w.groupcontact -bd 1
		label $w.groupcontact.lbl -text "[trans groupcontacts]" -font sboldf
		pack $w.groupcontact.lbl

		pack $w.groupname -side top -pady 3 -padx 5
		pack $w.groupcontact -side top -pady 3 -padx 5

		ScrolledWindow $w.groupcontacts -auto vertical -scrollbar vertical
		ScrollableFrame $w.groupcontacts.sf -constrainedwidth 1
		$w.groupcontacts setwidget $w.groupcontacts.sf
		pack $w.groupcontacts -anchor n -side top -fill both -expand true
		set gpcontactsframe [$w.groupcontacts.sf getframe]

		set contactlist [list]

		#Create a list with the contacts
		foreach contact [::abook::getAllContacts] {
			if { [lsearch [::abook::getLists $contact] "FL"] != -1 } {
				set contactname [::abook::getDisplayNick $contact]
				lappend contactlist [list $contactname $contact]
			}
		}

		set contactlist [lsort -dictionary -index 0 $contactlist]

		foreach contact $contactlist {
			set name [lindex $contact 0]
			set passport [lindex $contact 1]
			set passport2 [split $passport "@ ."]
			checkbutton $gpcontactsframe.w$passport2 -onvalue 1 -offvalue 0 -text " $name" -anchor w -variable [::config::getVar tempcontact_$passport2]
			pack configure $gpcontactsframe.w$passport2 -side top -fill x
		}

		frame $w.b 
		button $w.b.ok -text "[trans ok]"   \
			-command {
				::groups::Add "[.dlgag.groupname.ent get]" dlgMsg; 
				destroy .dlgag
			}
		button $w.b.cancel -text "[trans cancel]"   \
			-command {
				set pgc 0;
				foreach contact [::abook::getAllContacts] {
					if { [lsearch [::abook::getLists $contact] "FL"] != -1 } {
						set passport2 [split $contact "@ ."]
						::config::unsetKey tempcontact_$passport2
					}
				}
				destroy .dlgag
			}
		pack $w.b.ok .dlgag.b.cancel -side right -padx 5

		pack $w.groupcontacts -side top -pady 3 -padx 5
		pack $w.b -side top -anchor e -pady 3


		bind $w.groupname.ent <Return> { 
			::groups::Add "[$w.groupname.ent get]" dlgMsg; 
			destroy $w
		}

		bind $w <<Escape>> {
			set pgc 0
			foreach contact [::abook::getAllContacts] {
				if { [lsearch [::abook::getLists $contact] "FL"] != -1 } {
					set passport2 [split $contact "@ ."]
					::config::unsetKey tempcontact_$passport2
				}
			}
			destroy .dlgag;
		}

		moveinscreen $w 30
	}

	# Used to perform the group renaming without special dialogues
	proc ThisOkPressed { gid } {
		if [winfo exists .dlgthis] {
			set gname [GetName $gid]
			::groups::Rename $gname [.dlgthis.data.ent get] dlgMsg
			destroy .dlgthis
		}
	}
   
	# New simplified renaming dialog
	proc dlgRenameThis {gid} {
		global pgc
		
		if {[winfo exists .dlgthis]} {
			set pgc 0
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
		button .dlgthis.buttons.ok -text "[trans ok]" -command "::groups::ThisOkPressed $gid" 
		button .dlgthis.buttons.cancel -text "[trans cancel]" \
			-command "set pgc 0; destroy .dlgthis" 
		pack .dlgthis.buttons.ok .dlgthis.buttons.cancel -side left -pady 5
			
		pack .dlgthis.data .dlgthis.buttons -side top
		moveinscreen .dlgthis 30
	
	}
   
	# New group menu, for contact list only, no for management in toolbar
	# it avoids complex group selection when renaming or deleting groups
	proc GroupMenu {gid cx cy} {
		if [winfo exists .group_handler] {
			destroy .group_handler
		}
		# The submenu of standard group actions
		menu .group_handler -tearoff 0 -type normal
		.group_handler add command -label "[trans groupadd]..." -command ::groups::dlgAddGroup
		if {$gid != "online" & $gid != "offline"} {
			.group_handler add separator
			.group_handler add command -label "[trans delete]" -command "::groups::Delete $gid dlgMsg"
			.group_handler add command -label "[trans rename]..." -command "::groups::dlgRenameThis $gid"
			.group_handler add separator
			.group_handler add command -label "[trans block]" -command "::groups::blockgroup $gid"
			.group_handler add command -label "[trans unblock]" -command "::groups::unblockgroup $gid"
		}
		tk_popup .group_handler $cx $cy
	}


	#Block all the contacts into a group	
	proc blockgroup {gid} {
		#Ask confirmation for block all the users in the group
		set answer [::amsn::messageBox "[trans confirm]" yesno question [trans block]]
		#If yes
		if { $answer == "yes"} {
			#Get all the contacts
			set timer 0
			foreach user_login [::abook::getAllContacts] {
				#If the contact is not already blocked
				if { [lsearch [::abook::getLists $user_login] BL] == -1} {
					#Get the group for each contact
					foreach gp [::abook::getContactData $user_login group] {
						#If the group is the same at specified, block the user
						if {$gp == $gid} {
							set name [::abook::getNick ${user_login}]
							after $timer [list ::MSN::blockUser ${user_login} [urlencode $name]]
							set timer [expr $timer + 250]
						}
					}
				}
			}
		}
	}
	#Unblock all the contacts into a group
	proc unblockgroup {gid} {
		#For each user in all contacts
		set timer 0
		foreach user_login [::abook::getAllContacts] {
			#If the contact is blocked
			if { [lsearch [::abook::getLists $user_login] BL] != -1} {
				#Get the group for each contact
				foreach gp [::abook::getContactData $user_login group] {
					#Compare if the group of the user is the same that the group requested to be blocked
					if {$gp == $gid} {
						#If yes, unblock the user
						set name [::abook::getNick ${user_login}]
						after $timer [list ::MSN::unblockUser ${user_login} [urlencode $name]]
						set timer [expr $timer + 250]
					}
				}
			}
		}
	}
	

	# Used to display the list of groups that are candidates for
	# deletion in the Delete Group... & Rename Group menus
	proc updateMenu {type path {cb ""} {pars ""}} {
		if {$type == "menu"} {
			$path delete 0 end
		}
		# The Unique Group ID (MSN) is sent with the RemoveGroup message.
		# The first group's ID is zero (0) (MSN)
		set glist [lrange [::groups::GetList] 1 end]

		
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
	
		if { [::config::getKey protocol] == 11 } {
			set trid [lindex $pdu 1]
			set gid  [lindex $pdu 2]
			set gname [urldecode [lindex $pdu 3]]
		} else {
			set trid [lindex $pdu 1]
			set lmod [lindex $pdu 2]
			set gid  [lindex $pdu 3]
			set gname [urldecode [lindex $pdu 4]]
		}
	
		set groups($gid) $gname
	
		::abook::setContactData contactlist groups [array get groups]
		# Update the Delete Group... menu
		::groups::updateMenu menu .group_list_delete ::groups::menuCmdDelete
		::groups::updateMenu menu .group_list_rename ::groups::menuCmdRename
	}

	proc DeleteCB {pdu} {	# RMG 24 12065 15
		variable bShowing
		variable uMemberCnt
		variable uMemberCnt_online
		array set groups [abook::getContactData contactlist groups]
		
		if { [::config::getKey protocol] == 11 } {
			set trid [lindex $pdu 1]
			set gid  [lindex $pdu 2]
		} else {
			set trid [lindex $pdu 1]
			set lmod [lindex $pdu 2]
			set gid  [lindex $pdu 3]
		}
	
		# Update our local information
		unset groups($gid)
		unset uMemberCnt($gid)
		unset uMemberCnt_online($gid)
		unset bShowing($gid)
	
		# TODO: We are out of sync, maybe we should request
		# a new list
		abook::setContactData contactlist groups [array get groups]
		# Update the Delete Group... menu
		::groups::updateMenu menu .group_list_delete ::groups::menuCmdDelete
		::groups::updateMenu menu .group_list_rename ::groups::menuCmdRename
	}

	proc AddCB {pdu} {	# ADG 23 12064 New%20Group 15 =?�-CC
		#variable groups
		variable uMemberCnt
		variable uMemberCnt_online
		variable bShowing
		array set groups [abook::getContactData contactlist groups]

		if { [::config::getKey protocol] == 11 } {
			set trid [lindex $pdu 1]
			set gname [urldecode [lindex $pdu 2]]
			set gid  [lindex $pdu 3]
		} else {
			set trid [lindex $pdu 1]
			set lmod [lindex $pdu 2]
			set gname [urldecode [lindex $pdu 3]]
			set gid  [lindex $pdu 4]
		}
	
		set groups($gid) $gname
		set uMemberCnt($gid) 0
		set uMemberCnt_online($gid) 0
		set bShowing($gid) 1
		abook::setContactData contactlist groups [array get groups]	
		::groups::updateMenu menu .group_list_delete ::groups::menuCmdDelete
		::groups::updateMenu menu .group_list_rename ::groups::menuCmdRename
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
		if {![info exists uMemberCnt($gid)]} {
			set uMemberCnt($gid) 0
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
		if {![info exists bShowing($gid)]} {
			set bShowing($gid) 1	
		}
	
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
		menu .group_list_delete -tearoff 0 -type normal
		menu .group_list_rename -tearoff 0 -type normal
	
		# The submenu of standard group actions
		menu .group_menu -tearoff 0 -type normal
		.group_menu add command -label "[trans groupadd]..." \
			-command ::groups::dlgAddGroup
		.group_menu add cascade -label "[trans grouprename]" \
			-menu .group_list_rename
		.group_menu add cascade -label "[trans groupdelete]" \
			-menu .group_list_delete

	
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
	
		if { [::config::getKey expanded_group_online]!="" } {
			set bShowing(online) [::config::getKey expanded_group_online]
		}
		if { [::config::getKey expanded_group_offline]!="" } {
			set bShowing(offline) [::config::getKey expanded_group_offline]
		}
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
	
		::groups::updateMenu menu .group_list_delete ::groups::menuCmdDelete
		::groups::updateMenu menu .group_list_rename ::groups::menuCmdRename
		# The entryid of the parent is 0
		$parent entryconfigure $entryid -state normal
		$parent entryconfigure 6 -state normal
		#status_log "Groups: menu enabled\n" blue
	}

	# Call this one when going offline (disconnecting)
	proc Disable {} {
		variable parent 
		variable entryid
	
		$parent entryconfigure $entryid -state disabled
		$parent entryconfigure 6 -state disabled

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
		if { $nr == 0 } {
			#Special group "Individuals"
			return [trans nogroup]
		}
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
		global pgc
		
		set old [string trim $old]
		set new [string trim $new]
	
		if {$old == $new || $old == ""} { return 0 }
	
		if {![::groups::Exists $old]} {
		if {$ghandler != ""} {
			set retval [eval "$ghandler \"$old : [trans groupunknown]\""]
		}
		set pgc 0
		return 0
		}
	
		if {[::groups::Exists $new]} {
		if {$ghandler != ""} {
			set retval [eval "$ghandler \"$new : [trans groupexists]\""]
		}
		set pgc 0
		return 0
		}
	
		set currentGid [::groups::GetId $old]
		if {$currentGid == -1} {
		if {$ghandler != ""} {
			set retval [eval "$ghandler \"[trans groupmissing]: $old\""]
		}
		set pgc 0
		return 0
		}
	
		#TODO Keep track of transaction number
		set new [urlencode $new]
		::MSN::WriteSB ns "REG" "$currentGid $new 0"
		# RenameCB() should be called when we receive the REG
		# packet from the server

		# If an "add contact" window is open, actualise the group list
		if { [winfo exists .addcontact] == 1 } {
			after 500 cmsn_draw_grouplist
		}

		return 1
	}

	proc Add { gname {ghandler ""}} {
		global pgc
		
		if {[::groups::Exists $gname]} {
			if {$ghandler != ""} {
				set retval [eval "$ghandler \"[trans groupexists]!\""]
			}
			set pgc 0
			return 0
		}
	
		set gname2 [urlencode $gname]
		::MSN::WriteSB ns "ADG" "$gname2 0"
		# MSN sends back "ADG %T %M $gname gid junkdata"
		# AddCB() should be called when we receive the ADG
		# packet from the server

		after 2000 ::groups::AddContactsToGroup $gname

		# If an "add contact" window is open, actualise the group list
		if { [winfo exists .addcontact] == 1 } {
			after 500 cmsn_draw_grouplist
		}
		return 1
	}


	proc AddContactsToGroup { gname } {

		set timer 250
		set gid [::groups::GetId $gname]
		foreach contact [::abook::getAllContacts] {
			if { [lsearch [::abook::getLists $contact] "FL"] != -1 } {
				set passport2 [split $contact "@ ."]
				if { [::config::getKey tempcontact_$passport2] == 1 } {
					
					set timer [expr $timer + 250]
					after $timer ::MSN::copyUser $contact $gid
				}
				::config::unsetKey tempcontact_$passport2
			}
		}

	}

        
	proc Delete { gid {ghandler ""}} {
		global pgc
		
		set gname [::groups::GetName $gid]
		if {![::groups::Exists $gname]} {
		if {$ghandler != ""} {
		set retval [eval "$ghandler \"[trans groupunknown]!\""]
		}
		set pgc 0
		return 0
		}
	
		# Cannot and must not delete a group until it is empty
		if {$::groups::uMemberCnt($gid) != 0} {
		if {$ghandler != ""} {
		set retval [eval "$ghandler \"[trans groupnotempty]!\""]
		}
		set pgc 0
		return 0
		}
		
		::MSN::WriteSB ns "RMG" $gid
		# MSN sends back "RMG %T %M $gid"
		# DeleteCB() should be called when we receive the RMG
		# packet from the server

		# If an "add contact" window is open, actualise the group list
		if { [winfo exists .addcontact] == 1 } {
			after 500 cmsn_draw_grouplist
		}

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

	#Tests if a contact belong to a group or not
	proc Belongtogp {email gid} {

		if {[lsearch [::abook::getGroups $email] $gid] == -1} {
			return "0"
		} else {
			return "1"
		} 
	}

	proc Groupmanager {email {winpref ""}} {
		
		set w ".gpmanage_[::md5::md5 $email]"

		if {[winfo exists $w]} {
			raise $w
			return
		}

		toplevel $w
		wm title $w "[trans groups] ($email)"
		#wm geometry $w 350x200+30+30
		wm protocol $w WM_DELETE_WINDOW "::groups::GroupmanagerClose $email"

		label $w.txt -text "[trans groups] :"

		frame $w.box

		set gidlist [::groups::GetList]

		set thelistnames [list]

		#Create a list with the names of the groups the contact belong to
		foreach gid $gidlist {
			set thename [::groups::GetName $gid]
			lappend thelistnames [list "$thename" $gid]
		}

		#Sort the list by names (sortlist is a list of lists with name and gid of a group)
		set sortlist [lsort -dictionary -index 0 $thelistnames]
		set sortlist2 [list]

		foreach group $sortlist {
			set name [lindex $group 0]
			set gid [lindex $group 1]
			lappend glist $name
			lappend sortlist2 $gid
			checkbutton $w.box.w$gid -onvalue 1 -offvalue 0 -text " $name" -variable [::config::getVar tempgroup_[::md5::md5 $email]($gid)] -anchor w
			pack configure $w.box.w$gid -side top -fill x
			::config::setKey tempgroup_[::md5::md5 $email]($gid) [Belongtogp $email $gid]
		}

		frame $w.button

		button $w.button.ok -text [trans ok] -command "::groups::GroupmanagerOk $email $winpref"
		button $w.button.close -text [trans close] -command "::groups::GroupmanagerClose $email"
		bind $w <<Escape>> "::groups::GroupmanagerClose $email"
		pack configure $w.button.ok -side right
		pack configure $w.button.close -side right

		pack configure $w.txt -side top
		pack configure $w.box -side top -fill x
		pack configure $w.button -side bottom -fill x -ipady 10 -ipadx 10

		moveinscreen $w 30

	}

	proc GroupmanagerOk {email {winpref ""}} {

		set name [::abook::getNick $email]

		set gidlist [::groups::GetList]

		set gidlistyes [list]
		set gidlistno [list]

		#Check which groups the contact belong to (gidlistyes) and which he doesn't (gidlistno)
		foreach gid $gidlist {
			set state [::config::getKey tempgroup_[::md5::md5 $email]($gid)]
			if {$state == 1} {
				lappend gidlistyes $gid
			} elseif {$state == 0} {
				lappend gidlistno $gid
			}
			::config::unsetKey tempgroup_[::md5::md5 $email]($gid)
		}

		#If the contact doesn't belong to any groups, put it in the "Nogroup" group
		if {$gidlistyes == ""} {
			lappend gidlistyes 0
			set gidlistno [lrange $gidlistno 1 end]
		}

		set timer 0

		#First add the contact to the new groups
		foreach gid $gidlistyes {
			if {[lsearch [::abook::getGroups $email] $gid] == -1} {
				after $timer ::MSN::copyUser $email $gid
				set timer [expr $timer + 250]
			}
		}

		#Then remove their from the former groups
		foreach gid $gidlistno {
			if {[lsearch [::abook::getGroups $email] $gid] != -1} {
				after $timer ::MSN::deleteUser $email $gid
				set timer [expr $timer + 250]
			}
		}

		destroy .gpmanage_[::md5::md5 $email]

		#If the properties window is open, change the groups of the contact in it
		if {$winpref != ""} {
			set groups ""
			foreach gid $gidlistyes {
				set groups "$groups[::groups::GetName $gid], "
			}
			set groups [string range $groups 0 end-2]
			$winpref.g1 configure -text "$groups"
		}
	}


	proc GroupmanagerClose { email } {

		set gidlist [::groups::GetList]
		foreach gid $gidlist {
			::config::unsetKey tempgroup_[::md5::md5 $email]($gid)
		}

		destroy .gpmanage_[::md5::md5 $email]
	}


}

