#	Group Administration
#	by: Dídimo Emilio Grimaldo Tuñón
# $Id$
#=======================================================================
# BUGS
#  - When a group from the middle is deleted, that id remains unused.
#    therefore the menu entry shows "". Currently Exists/GetName check
#    for this (to prevent error). That ID is reused next time a group
#    is added.
#  - Should invoke Enable from some other place, get too many.
# TODO LIST
#  - Finalize the message translations
#  - Keep track of transactions pending completion
#  - Update GUI menus when a callback is invoked
#  - Investigate what happens when a group is deleted, which
#    group inherits the orphans?
#  - Investigate what happens when a group is deleted, does the
#    server send a new list? obviously the upper groups get
#    a reasigned number (???). Remember that the entries in
#    the address book (::abook) contains the group IDs received
#    in the Forward List.
#  - If a user belongs to two groups the gid would be x,y that
#    causes an error. For now assume only one group.
#  - Move user from one group to another

# Test
#set program_dir [file dirname [info script]]
#source [file join $program_dir lang.tcl]
#set config(language) en
#scan_languages
#load_lang
# End Test Stub

namespace eval ::groups {
   namespace export Init Enable Disable Set Rename Delete Add \
   		    RenameCB DeleteCB AddCB

   #
   # P R I V A T E
   #
   variable parent "";
   variable entryid -1;
   variable groupname "";	# Temporary variable for TCL crappiness
   variable groupCnt 0;
   variable groups;		# Group names (array). Not URLEncoded!
				# indexed by ID. Message LSG
   
   #<dlgMsg>
   proc dlgMsg {msg} {
       tk_messageBox -icon error -message $msg -type ok
   }
   
   #<dlgAddGroup> Dialog to add a group
   proc dlgAddGroup {} {
        if [winfo exists .dlgag] {
            return
	}

	set bgcol #ABC8CE
	set bgcol2 #ABC8D2

	toplevel .dlgag -background $bgcol -highlightcolor $bgcol2
	wm title .dlgag "[trans groupadd]"
	frame .dlgag.d -bd 1 -background $bgcol
	    label .dlgag.d.lbl -text "[trans group]" -background $bgcol
	    entry .dlgag.d.ent -width 20
	    pack .dlgag.d.lbl .dlgag.d.ent -side left
	    bind .dlgag.d.ent <Return> { 
	    	::groups::Add "[.dlgag.d.ent get]" dlgMsg; 
		destroy .dlgag
	    }
	frame .dlgag.b -background $bgcol
	    button .dlgag.b.ok -text "[trans ok]" -background $bgcol \
	    	-command {
			::groups::Add "[.dlgag.d.ent get]" dlgMsg; 
			destroy .dlgag
		}
	    button .dlgag.b.cancel -text "[trans cancel]" -background $bgcol \
	    	-command "destroy .dlgag"
	    pack .dlgag.b.ok .dlgag.b.cancel -side left
	pack .dlgag.d .dlgag.b -side top
   }

   proc dlgRenGroup {} {
        if [winfo exists .dlgrg] {
            return
	}

	set bgcol #ABC8CE
	set bgcol2 #ABC8D2

	toplevel .dlgrg -background $bgcol -highlightcolor $bgcol2
	wm title .dlgrg "[trans groupadd]"
	frame .dlgrg.d -bd 1 -background $bgcol
	    label .dlgrg.d.lbl -text "[trans groupoldname]:" \
	    	-background $bgcol
#	    set oldmenu [tk_optionMenu .dlgrg.d.old ::groups::groupname {}]
#	    $oldmenu add radiobutton -label F -variable ::groups::groupname
	    ::groups::updateMenu option .dlgrg.d.old
	    .dlgrg.d.old configure -background $bgcol
	    pack .dlgrg.d.lbl .dlgrg.d.old -side left -padx 10 -pady 5 

	frame .dlgrg.n -bd 1 -background $bgcol
	    label .dlgrg.n.lbl -text "[trans groupnewname]:" \
	    	-background $bgcol
	    entry .dlgrg.n.ent -width 20
	    pack .dlgrg.n.lbl .dlgrg.n.ent -side left
	    
	frame .dlgrg.b -background $bgcol
	    button .dlgrg.b.ok -text "[trans ok]" -background $bgcol \
	    	-command { \
		::groups::Rename $::groups::groupname "[.dlgrg.n.ent get]" handler;\
		destroy .dlgrg }
	    button .dlgrg.b.cancel -text "[trans cancel]" -background $bgcol \
	    	-command "destroy .dlgrg"
	    pack .dlgrg.b.ok .dlgrg.b.cancel -side left -pady 5
		
	pack .dlgrg.d .dlgrg.n .dlgrg.b -side top

   }

   # Used to display the list of groups that are candidates for
   # deletion in the Delete Group... & Rename Group menus
   proc updateMenu {type path} {
       if {$type == "menu"} {
           $path delete 0 end
       }
       # The Unique Group ID (MSN) is sent with the RemoveGroup message.
       # The first group's ID is zero (0) (MSN)
       for {set i 0} {$i < $::groups::groupCnt} {incr i} {
	    set gname [::groups::GetName $i]
	    if {$type == "menu"} {
	        $path add command -label $gname -command "::groups::Delete $i"
	    } else {
	        if {$i == 0} {
	    	    set mpath [tk_optionMenu $path ::groups::groupname $gname]
		} else {
		    $mpath add radiobutton -label $gname -variable ::groups::groupname
		}
	    }
	}
   }

   #
   # P R O T E C T E D
   #
   # ----------------- Callbacks -------------------
   proc RenameCB {pdu} {  # REG 25 12066 15 New%20Name 0
        variable groups

   	set trid [lindex $pdu 1]
	set lmod [lindex $pdu 2]
	set gid  [lindex $pdu 3]
	set gname [urldecode [lindex $pdu 4]]

	set groups($gid) $gname

	# Update the Delete Group... menu
	::groups::updateMenu menu .group_list
   }

   proc DeleteCB {pdu} {	# RMG 24 12065 15
	variable groupCnt
	variable groups

   	set trid [lindex $pdu 1]
	set lmod [lindex $pdu 2]
	set gid  [lindex $pdu 3]

	# Update our local information
	unset groups($gid)
	incr groupCnt -1

	# TODO: We are out of sync, maybe we should request
	# a new list

	# Update the Delete Group... menu
	::groups::updateMenu menu .group_list
   }

   proc AddCB {pdu} {	# ADG 23 12064 New%20Group 15 =?Ñ?-CC
	variable groupCnt
	variable groups

   	set trid [lindex $pdu 1]
	set lmod [lindex $pdu 2]
	set gname [urldecode [lindex $pdu 3]]
	set gid  [lindex $pdu 4]

 	set groups($gid) $gname
	incr groupCnt
#	puts "Group $gid ($gname) added.Trans #$trid"
	# Update the Delete Group... menu
#	::groups::Disable
#	::groups::Enable
	::groups::updateMenu menu .group_list
   }
   
   #
   # P U B L I C
   #
   #<Init> Initialize the non-mutable part of the menus and the
   #	   core of the group administration. At this point we do not
   #	   have any information about the groups (we are not connected)
   proc Init {p entrynr} {
   	variable parent 
	variable entryid

	# The submenu with the list of defined groups (to be filled)
	menu .group_list -tearoff 0 -type normal -background #D0D0E0

	# The submenu of standard group actions
	menu .group_menu -tearoff 0 -type normal -background #D0D0E0
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
	set entryid $entrynr	;# needed to enable/disable widget
   }

   # Must only Enable it when the list of groups is already available!
   # That's because from here we rebuild the group submenu (list)
   proc Enable {} {
   	variable parent
	variable entryid

	::groups::updateMenu menu .group_list
	# The entryid of the parent is 0
	$parent entryconfigure $entryid -state normal
	puts "groups:enable"
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
       variable groups
       variable groupCnt

       set name [urldecode $name]
       set groups($nr) $name
       incr groupCnt
       puts "groups: added group $nr ($name)"
   }

   # Get a group's name (decoded) given its ID (0..n)
   proc GetName {nr} {
       variable groupCnt
       variable groups

       if {![info exists groups($nr)]} {
#           puts "TODO: Empty slot in groups"
           return ""
       }
       if { $nr < $groupCnt } { 
           return $groups($nr) 
       } else { 
       	   return "" 
       }
   }

   # Does a reverse lookup from group name to find it's id. 
   # Returns: -1 on error (not found), otherwise 0..n
   proc GetId {gname} {
        variable groups
	# Groups are stored here in decoded state. When sent to
	# the server we must urlencode them!
	for {set i 0} {$i < $::groups::groupCnt} {incr i} {
	    if {$groups($i) == $gname} {
	    	return $i
	    }
	}
	return -1
   }

   proc Exists {gname} {
        variable groups

        set gname [string trim $gname]
	for {set i 0} {$i < $::groups::groupCnt} {incr i} {
	    if [info exists groups($i)] {
		if {$groups($i) == $gname} {
		    return 1
		}
	    }
	}
	return 0
    }

    proc Rename { old new {ghandler ""}} {
        set old [string trim $old]
	set new [string trim $new]

	if {$old == $new} { return 0 }

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
#        puts "MSN-> REG %T $currentGid $new 0"; #TODO ::MSN::WriteNS
	set new [urlencode $new]
	::MSN::WriteNS "REG" "$currentGid $new 0"
	# RenameCB() should be called when we receive the REG
	# packet from the server
        return 1
    }

    proc Add { gname {ghandler ""}} {
	if [::groups::Exists $gname] {
	   if {$ghandler != ""} {
	       set retval [eval "$ghandler \"[trans groupexists]!\""]
	   }
	    return 0
	}

	set gname [urlencode $gname]
	::MSN::WriteNS "ADG" "$gname 0"
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

#        puts "MSN-> RMG %T $gid";	#TODO ::MSN::WriteNS
	::MSN::WriteNS "RMG" $gid
	# MSN sends back "RMG %T %M $gid"
	# DeleteCB() should be called when we receive the RMG
	# packet from the server
        return 1
    }
}

proc TestInitGroups {} {	# ONLY FOR TESTING
    set ::groups::groups(0) "Dummy-0"
    set ::groups::groups(1) "Dummy-1"
    set ::groups::groups(2) "Dummy-2"
    set ::groups::groups(3) "Dummy-3"
    set ::groups::groupCnt 4
}

# Test
#set w .menu
#catch {destroy $w}
#toplevel $w
#wm title $w "Test groups.tcl"
#menu $w.menu -tearoff 0
#set m $w.menu.test
#menu $m -tearoff 0
#$w.menu add cascade -label "Test" -menu $m -underline 0
## -accelerator Meta+x
#$m add command -label "Quit" -command "destroy ."
#$m add separator
#$m add command -label "Enable" -command ::groups::Enable
#$m add command -label "Disable" -command ::groups::Disable
#$w configure -menu $w.menu
#::groups::Init $m 4
#TestInitGroups
#::groups::Enable
## End Test Stub
