#	User Administration (Address Book data)
#	by: Dídimo Emilio Grimaldo Tuñón
# $Id$
#=======================================================================
namespace eval ::abook {
   namespace export setContact getContact getGroup\
   		    setPhone setDemographics getDemographics \
		    setPersonal getPersonal

   #
   # P R I V A T E
   #
   variable myself "unknown";
   variable contacts;	# Array for contacts. Same struct for myself
   			# contacts(email) {		   BPR*
			#	handle			   LST
			#       groupId			   LST
			#	phone { home work mobile } BPR.PHH/PHW/PHM
			#	pager			   BPR.MOB
			# }
   variable demographics;	# Demographic Information about user

   #
   # P R O T E C T E D
   #
   proc adjustGroup {g} {
       set i [string first , $g]
       if {$i == -1} {
           return $g
       }
       # If we get here this one had multiple groups (g1,g2...) so
       # we only use the first (TODO this is temporary workaround!)
       incr i -1
       set ag [string range $g 0 $i]
       return $ag
   }

   #
   # P U B L I C
   #
   proc setPersonal { field value} {
   	variable myself 

        if {$myself == "unknown"} {
	    set myself [list Dummy Dummy Dummy Dummy Dummy]
	}
	
	# Phone numbers are countryCode%20areaCode%20subscriberNumber
        switch $field {
	    PHH {	;# From PRP.PHH (Home Phone Number)
		set myself [lreplace $myself 0 0 $value]
	    }
	    PHW {	;# From PRP.PHW (Work Phone Number)
		set myself [lreplace $myself 1 1 $value]
	    }
	    PHM {	;# From PRP.PHM (Mobile Phone Number)
		set myself [lreplace $myself 2 2 $value]
	    }
	    MOB {	;# From PRP.MOB (Mobile pager) Y|N
		set myself [lreplace $myself 3 3 $value]
	    }
	    MBE {	;# From PRP.MBE (?) Y|N
		set myself [lreplace $myself 4 4 $value]
	    }
	    default {
	        puts "setPersonal unknown field $field -> $value"
	    }
	}
   }
   
   proc getPersonal { cdata } {
   	variable myself 
	upvar $cdata data

	if { ![info exists myself] } {
	    puts "ERROR: what happened to me?"
	    return
	}
	
	set data(group)  "n.a."
	set data(handle) "You know that";#  FIXME
	set data(phh)    [urldecode [lindex $myself 0]]
	set data(phw)    [urldecode [lindex $myself 1]]
	set data(phm)    [urldecode [lindex $myself 2]]
	set data(mob)    [urldecode [lindex $myself 3]]
	set data(mbe)    [urldecode [lindex $myself 4]]
	set data(available) Y
   }

   proc setContact { email field value } {
   	variable contacts 

	if { ![info exists contacts($email)] } {
	  #                          group nick  PHH   PHW   PHM   MOB
	  set contacts($email) [list Dummy Dummy Dummy Dummy Dummy Dummy]
	}

	# Phone numbers are countryCode%20areaCode%20subscriberNumber
        switch $field {
	    FL {	;# From LST.FL command, contains email, groupId
		set value [adjustGroup $value]
		set contacts($email) [list  $value "" "" "" "" "" ]
#		puts "ABOOK: creating $email GroupId $value"
#		puts "size [llength $contacts($email)]"
	    }
	    nick {	;# From LST.FL (User handle)
		set contacts($email) [lreplace $contacts($email) 1 1 $value]
#		puts "ABOOK: $email Home $value"
	    }
	    PHH {	;# From BPR.PHH (Home Phone Number)
		set contacts($email) [lreplace $contacts($email) 2 2 $value]
#		puts "ABOOK: $email Home $value"
	    }
	    PHW {	;# From BPR.PHW (Work Phone Number)
		set contacts($email) [lreplace $contacts($email) 3 3 $value]
#		puts "ABOOK: $email Work $value"
	    }
	    PHM {	;# From BPR.PHM (Mobile Phone Number)
		set contacts($email) [lreplace $contacts($email) 4 4 $value]
#		puts "ABOOK: $email Mobile $value"
	    }
	    MOB {	;# From BPR.MOB (Mobile pager) Y|N
		set contacts($email) [lreplace $contacts($email) 5 5 $value]
#		puts "ABOOK: $email MobileSet $value"
	    }
	    default {
	        puts "setContact unknown field $field -> $value"
	    }
	}
#puts "$field -> $contacts($email)"
   }

   proc getContact { email cdata } {
   	variable contacts 
	upvar $cdata data

	if { ![info exists contacts($email)] } {
	    puts "getContact ERROR: unknown contact $email!"
	    return
	}
	
#puts $contacts($email)
	set groupName    [::groups::GetName [lindex $contacts($email) 0]]
	set data(group)  [urldecode $groupName]
	set data(handle) [urldecode [lindex $contacts($email) 1]]
	set data(phh)    [urldecode [lindex $contacts($email) 2]]
	set data(phw)    [urldecode [lindex $contacts($email) 3]]
	set data(phm)    [urldecode [lindex $contacts($email) 4]]
	set data(mob)    [urldecode [lindex $contacts($email) 5]]
	set data(available) Y
   }

   # Used to fetch the group ID so that the caller can order by
   # group if needed. Returns -1 on error.
   # ::abook::getGroup my@passport.com -id    : returns group id
   # ::abook::getGroup my@passport.com -name  : return group name
   proc getGroup {passport how} {
   	variable contacts 

	if { ![info exists contacts($passport)] } {
	    status_log "E: Group: unknown contact $passport!\n" red
	    return -1
	}
	
	set groupId [lindex $contacts($passport) 0]
	if {$how == "-id"} {
#puts "ID $groupId"
	    return $groupId
        }
	set groupName [::groups::GetName $groupId]
#puts "Name $groupId $groupName"
	return $groupName
   }
   
   # Sends a message to the notification server with the
   # new set of phone numbers. Notice this can only be done
   # for the user and not for the buddies!
   # The value is urlencoded by this routine
   proc setPhone { item value } {
#   	set value [urlencode $value]
	switch $item {
	    home { ::MSN::WriteNS PRP "PHH $value" }
	    work { ::MSN::WriteNS PRP "PHW $value" }
	    mobile { ::MSN::WriteNS PRP "PHM $value" }
	    pager { ::MSN::WriteNS PRP "MOB $value" }
	    default { puts "setPhone error, unknown $item $value" }
	}
   }

    # This information is sent to us during the initial connection
    # with the server. It comes in a MSG content "text/x-msmsgsprofile"
    proc setDemographics { cdata } {
        variable demographics 
	upvar $cdata data

    	set demographics(langpreference) $data(langpreference);# 1033 = English
	set demographics(preferredemail) $data(preferredemail)
	set demographics(country) [string toupper $data(country)];# NL
	set demographics(gender) [string toupper $data(gender)]
	set demographics(kids) $data(kids);	  # Number of kids
	set demographics(age) $data(age)
	set demographics(mspauth) $data(mspauth); # MS Portal Authorization?
	set demographics(valid) Y
    }

    proc getDemographics { cdata } {
        variable demographics 
	upvar $cdata d

	if [info exists data(valid)] {
	    set demographics(langpreference) $data(langpreference);# 1033 = English
	    set d(preferredemail) $demographics(preferredemail)
	    set d(country) $demographics(country)
	    set d(gender) $demographics(gender)
	    set d(kids) $demographics(kids)
	    set d(age) $demographics(age)
	    set d(mspauth) $demographics(mspauth)
	    set d(valid) Y
	} else {
	    set demographics(valid) N
	}
    }
}

namespace eval ::abookGui {
   namespace export showEntry

   #
   # P R I V A T E
   #

   #
   # P R O T E C T E D
   #
    proc updatePhones { t h w m p} {
	set phome [urlencode [$t.$h get]]
	set pwork [urlencode [$t.$w get]]
	set pmobile [urlencode [$t.$m get]]
    #    set ppager [urlencode [$t.$p get]]
	::abook::setPhone home $phome
	::abook::setPhone work $pwork
	::abook::setPhone mobile $pmobile
	::abook::setPhone pager N
    }

   #
   # P U B L I C
   #
   proc showEntry { email {edit ""}} {
	set cd(available) N
	::abook::getContact $email cd

	if { $cd(available) == "N" } {
	    msg_box "No data available yet"
	    return
	}

	# Generate a unique (almost) toplevel so that we can
	# have several open info windows (for different users)
	set w [string tolower $email]
	set w [string trim $w]
	set ends  [string first @ $w]
	incr ends -1
	set w [string range $w 0 $ends]
	set w [string map { @ "" _ "" - "" . "" } $w]
 	set w ".a$w"	

	if [winfo exists $w] {
	    return 
	}


	toplevel $w 
	wm title $w "[trans about] $email"
	wm geometry $w 210x140
	set nbtIdent "[trans identity]"
	set nbtPhone "[trans phone]"
	frame $w.n 
	    pack [notebook $w.n.p $nbtIdent $nbtPhone] \
	    	-expand 1 -fill both -padx 1m -pady 1m
	#  .----------.
	# _| Identity |________________________________________________
	set nbIdent [getNote $w.n.p $nbtIdent]
	$nbIdent configure 
   	label $nbIdent.e -text "Email:" -font bboldf 
   	label $nbIdent.e1 -text $email -font splainf -fg blue 
	label $nbIdent.h -text "[trans handle]:" -font bboldf 
	label $nbIdent.h1 -text $cd(handle) -font splainf -fg blue 
	label $nbIdent.g -text "[trans group]:" -font bboldf 
	label $nbIdent.g1 -text $cd(group) -font splainf -fg blue 
#	set group_names [::groups::GetList -names]
#	set group_total [llength $group_names]
#set cd(newgroup) $cd(group)
#	set om [tk_optionMenu $nbIdent.g1 $cd(newgroup) [lindex $group_names 0]]
#	for {set xxx 1} {$xxx < $group_total} {incr xxx} {
#	  $om add radiobutton -label [lindex $group_names $xxx] \
#	  	-variable $cd(newgroup)
#	}
#set cd(newgroup) $cd(group)
#	$om configure -font splainf -fg blue -bg $bgcol
	grid $nbIdent.e -row 0 -column 0 -sticky e
	grid $nbIdent.e1 -row 0 -column 1 -sticky w
	grid $nbIdent.h -row 1 -column 0 -sticky e
	grid $nbIdent.h1 -row 1 -column 1 -sticky w
	grid $nbIdent.g -row 2 -column 0 -sticky e
	grid $nbIdent.g1 -row 2 -column 1 -sticky w
        bind $w <Control-i> "pickNote $w.n.p $nbtIdent"

	#  .--------.
	# _| Phones |________________________________________________
	set nbPhone [getNote $w.n.p $nbtPhone]
	$nbPhone configure 
	if { $edit == "" } {
	label $nbPhone.h -font bboldf -text "[trans home]:" 
	label $nbPhone.h1 -font splainf -text $cd(phh) -fg blue \
		-justify left
	label $nbPhone.w -font bboldf -text "[trans work]:"
	label $nbPhone.w1 -font splainf -text $cd(phw) -fg blue \
		-justify left
	label $nbPhone.m -font bboldf -text "[trans mobile]:" 
	label $nbPhone.m1 -font splainf -text $cd(phm) -fg blue \
		-justify left
	label $nbPhone.p -font bboldf -text "[trans pager]:" 
	label $nbPhone.p1 -font splainf -text $cd(mob) -fg blue \
		-justify left
	grid $nbPhone.h -row 0 -column 0 -sticky e
	grid $nbPhone.h1 -row 0 -column 1 -sticky w
	grid $nbPhone.w -row 1 -column 0 -sticky e
	grid $nbPhone.w1 -row 1 -column 1 -sticky w
	grid $nbPhone.m -row 2 -column 0 -sticky e
	grid $nbPhone.m1 -row 2 -column 1 -sticky w
	grid $nbPhone.p -row 3 -column 0 -sticky e
	grid $nbPhone.p1 -row 3 -column 1 -sticky w
	} else {
	label $nbPhone.h -font bboldf -text "[trans home]:"
	entry $nbPhone.h1 -font splainf -text cd(phh) -fg blue
	$nbPhone.h1 insert 1 $cd(phh)
	label $nbPhone.w -font bboldf -text "[trans work]:"
	entry $nbPhone.w1 -font splainf -text cd(phw) -fg blue 
	$nbPhone.w1 insert 1 $cd(phw)
	label $nbPhone.m -font bboldf -text "[trans mobile]:" 
	entry $nbPhone.m1 -font splainf -text cd(phm) -fg blue 
	$nbPhone.m1 insert 1 $cd(phm)
	label $nbPhone.p -font bboldf -text "[trans pager]:" 
	label $nbPhone.p1 -font splainf -text $cd(mob) -fg blue \
		-justify left
	grid $nbPhone.h -row 0 -column 0 -sticky e
	grid $nbPhone.h1 -row 0 -column 1 -sticky w
	grid $nbPhone.w -row 1 -column 0 -sticky e
	grid $nbPhone.w1 -row 1 -column 1 -sticky w
	grid $nbPhone.m -row 2 -column 0 -sticky e
	grid $nbPhone.m1 -row 2 -column 1 -sticky w
	grid $nbPhone.p -row 3 -column 0 -sticky e
	grid $nbPhone.p1 -row 3 -column 1 -sticky w
	}
        bind $w <Control-p> "pickNote $w.n.p $nbtPhone"

	frame $w.b 
	    button $w.b.ok -text "[trans close]" -command "destroy $w"

	    button $w.b.submit -text "Update" -state disabled \
		    -command "::abookGui::updatePhones $nbPhone h1 w1 m1 p1; destroy $w"
	    pack $w.b.ok $w.b.submit -side left
	    if {$edit != ""} {
		$w.b.submit configure -state normal
	    }

	pack $w.n $w.b -side top
	bind $w <Control-c> { destroy $w }
   }
}
# $Log$
# Revision 1.12  2002/07/01 23:03:27  airadier
# Standard background for all widgets
#
# Revision 1.11  2002/07/01 21:30:30  lordofscripts
# - Now it is possible to move buddies from one group to another. Had to
#   post a 2nd popup because tk_popup cannot handle cascaded menus
#
# Revision 1.10  2002/06/25 23:17:56  lordofscripts
# -Added handling and keeping info of PRP messages (get/setPersonal)
#
# Revision 1.9  2002/06/24 15:15:48  lordofscripts
# Added getGroup function needed for ordering by groups
#
# Revision 1.8  2002/06/24 12:34:56  lordofscripts
# Use color scheme for showEntry dialog and sticky w for the rightmost
# column of the notebook tabs to align them to the left side. Increased
# width of dialog so that it shows all the info when data is too long.
#
# Revision 1.7  2002/06/20 17:46:14  lordofscripts
# Moved group-related handling to the "groups" namespace (new)
#
# Revision 1.6  2002/06/19 17:49:22  lordofscripts
# Added setDemographics and getDemographics as handled by text/x-msmsgsprofile
#
# Revision 1.5  2002/06/19 14:34:58  lordofscripts
# Added facility window (Ctrl+M) to enter commands to be issued to the
# Notification Server. Abook now allows to either show (read only)
# information about a buddy, or to publish (showEntry email -edit) the
# user's phone numbers so that other buddies can see them.
#
# Revision 1.4  2002/06/18 14:28:12  lordofscripts
# Implemented dialog for address book. Namespace abookGui
#
# Revision 1.3  2002/06/17 12:31:32  airadier
# Quick hack to avoid a bug when adding contacts (var contacts($email) non existing)
#
# Revision 1.2  2002/06/17 00:10:53  lordofscripts
# *** empty log message ***
#
# Revision 1.1  2002/06/17 00:01:57  lordofscripts
# Handles Address Book containing data about users in the forward list
#
