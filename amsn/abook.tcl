#	User Administration (Address Book data)
#	by: Dídimo Emilio Grimaldo Tuñón
# $Id$
#=======================================================================
namespace eval ::abook {
   namespace export setContact getContact getGroup getName \
   		    setPhone setDemographics getDemographics \
		    setPersonal getPersonal showPersonal

    if { $initialize_amsn == 1 } {

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
    }
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
	        status_log "setPersonal unknown field $field -> $value\n"
	    }
	}
   }
   
   proc getPersonal { cdata } {
   	variable myself 
	upvar $cdata data

	if { ![info exists myself] } {
	    status_log "ERROR: what happened to me?\n"
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

   proc showPersonal {} {
   	variable myself
	status_log "home : [urldecode [lindex $myself 0]]\nwork : [urldecode [lindex $myself 1]]\nmobile : [urldecode [lindex $myself 2]]"
   }

   proc setContact { email field value } {
   	variable contacts 

	if { ![info exists contacts($email)] } {
	  #                          group nick  PHH   PHW   PHM   MOB
	  set contacts($email) [list 0 "" "" "" "" ""]
	}

	# Phone numbers are countryCode%20areaCode%20subscriberNumber
        switch $field {
	    group {	;# From LST.FL command, contains email, groupId
		#set value [adjustGroup $value]
		set contacts($email) [lreplace $contacts($email) 0 0 $value]
		
		#status_log "Added groups $value for $email\n" white
		
	    }
	    nick {	;# From LST.FL (User handle)
		set contacts($email) [lreplace $contacts($email) 1 1 $value]
	    }
	    PHH {	;# From BPR.PHH (Home Phone Number)
		set contacts($email) [lreplace $contacts($email) 2 2 $value]
	    }
	    PHW {	;# From BPR.PHW (Work Phone Number)
		set contacts($email) [lreplace $contacts($email) 3 3 $value]
	    }
	    PHM {	;# From BPR.PHM (Mobile Phone Number)
		set contacts($email) [lreplace $contacts($email) 4 4 $value]
	    }
	    MOB {	;# From BPR.MOB (Mobile pager) Y|N
		set contacts($email) [lreplace $contacts($email) 5 5 $value]
	    }
	    default {
	        status_log "abook::setContact: setContact unknown field $field -> $value\n"
	    }
	}
   }

   proc getContact { email cdata } {
   	variable contacts 
	upvar $cdata data

	if { ![info exists contacts($email)] } {
	    status_log "getContact ERROR: unknown contact $email!\n"
	    return
	}
	
	set groupName    [::groups::GetName [lindex $contacts($email) 0]]
	set data(group)  [urldecode $groupName]
	set data(handle) [urldecode [lindex $contacts($email) 1]]
	set data(phh)    [urldecode [lindex $contacts($email) 2]]
	set data(phw)    [urldecode [lindex $contacts($email) 3]]
	set data(phm)    [urldecode [lindex $contacts($email) 4]]
	set data(mob)    [urldecode [lindex $contacts($email) 5]]
	set data(available) Y
   }

   proc getName {passport} {
	variable contacts
	if { ![info exists contacts($passport)] } {
	    status_log "getContact ERROR: unknown contact $passport!" red
	    return ""
	}

	return [urldecode [lindex $contacts($passport) 1]]
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
	    return $groupId
        }
	set groupName [::groups::GetName $groupId]
	return $groupName
   }
   
   proc addContactToGroup { email grId } {
      variable contacts
      set idx [lsearch [lindex $contacts($email) 0] $grId]
      if { $idx == -1 } {
         set contacts($email) [lreplace $contacts($email) 0 0 \
	    [linsert [lindex $contacts($email) 0] 0 $grId] ]
      }
   }

   proc removeContactFromGroup { email grId } {
      variable contacts
      
      set idx [lsearch [lindex $contacts($email) 0] $grId]
      
      if { $idx != -1 } {
         set contacts($email) [lreplace $contacts($email) 0 0 \
	   [lreplace [lindex $contacts($email) 0] $idx $idx]]
      }
   }
   
      
   # Sends a message to the notification server with the
   # new set of phone numbers. Notice this can only be done
   # for the user and not for the buddies!
   # The value is urlencoded by this routine
   proc setPhone { item value } {
	switch $item {
	    home { ::MSN::WriteSB ns PRP "PHH $value" }
	    work { ::MSN::WriteSB ns PRP "PHW $value" }
	    mobile { ::MSN::WriteSB ns PRP "PHM $value" }
	    pager { ::MSN::WriteSB ns PRP "MOB $value" }
	    default { status_log "setPhone error, unknown $item $value\n" }
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
	set demographics(kv) $data(kv)
        set demographics(sid) $data(sid)
	set demographics(sessionstart) $data(sessionstart)
	set demographics(clientip) $data(clientip)
	set demographics(valid) Y
    }

    proc getDemographicField { field } {
        variable demographics
        if { [info exists demographics($field)]} {
            return $demographics($field)
        } else {
            return ""
        }
    }

    proc getDemographics { cdata } {
        variable demographics 
	upvar $cdata d

	if {[info exists d(valid)]} {
	    set d(langpreference) $demographics(langpreference);# 1033 = English
	    set d(preferredemail) $demographics(preferredemail)
	    set d(country) $demographics(country)
	    set d(gender) $demographics(gender)
	    set d(kids) $demographics(kids)
	    set d(age) $demographics(age)
	    set d(mspauth) $demographics(mspauth)
            set d(kv) $demographics(kv)
            set d(sid) $demographics(sid)
	    set d(sessionstart) $demographics(sessionstart)
		 set d(clientip) $demographics(clientip)
	    set d(valid) Y
	} else {
	    set d(valid) N
	}
    }
    
	#Returns the user nickname
	proc getUserNickname { user_login } {
		return [lindex [::MSN::getUserInfo $user_login] 1]
	}
	
	#Returns the user nickname, or just email, depending on configuration
	proc getUserDisplayName { user_login } {
		if { [::config::getKey emailsincontactlist] } {
			return $user_login
		} else {
			return [getUserNickname $user_login]
		}
	}
}

namespace eval ::abookGui {
   namespace export Init showEntry

    if { $initialize_amsn == 1 } {

	#
	# P R I V A T E
	#
	variable bgcol #ABC8CE;	# Background color used in MSN Messenger
    }

   #
   # P R O T E C T E D
   #
    proc updatePhones { t h w m p} {
	set phome [urlencode [$t.$h get]]
	set pwork [urlencode [$t.$w get]]
	set pmobile [urlencode [$t.$m get]]
	::abook::setPhone home $phome
	::abook::setPhone work $pwork
	::abook::setPhone mobile $pmobile
	::abook::setPhone pager N
    }

   #
   # P U B L I C
   #
   proc Init {} {
       variable bgcol
       ::themes::AddClass ABook * {-background $bgcol} 90
       ::themes::AddClass ABook Label {-background $bgcol} 90
       ::themes::AddClass NoteBook * {-background $bgcol} 90
   }
   
   proc showEntry { email {edit ""}} {
        variable bgcol

	set cd(available) N
	::abook::getContact $email cd

	if { $cd(available) == "N" } {
	    msg_box "[trans nodataavailable $email]"
	    return
	}

	# Generate a unique (almost) toplevel so that we can
	# have several open info windows (for different users)
	set w [string tolower $email]
	set w [string trim $w]
	set ends  [string first @ $w]
	incr ends -1
	set w [string range $w 0 $ends]
	#set w [string map { @ "" _ "" - "" . "" } $w]
	set w [string map { "@" "" } $w]
	set w [string map { "_" "" } $w]
	set w [string map { "-" "" } $w]
	set w [string map { "." "" } $w]
 	set w ".a$w"	

	if {[winfo exists $w]} {
	    return 
	}


	toplevel $w -class ABook
	wm title $w "[trans about] $email"
#	wm geometry $w 210x140
	set nbtIdent "[trans identity]"
	set nbtPhone "[trans phone]"
	frame $w.n -class ABook
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

	frame $w.b -class ABook
	    button $w.b.ok -text "[trans close]" -command "destroy $w"

	    button $w.b.submit -text "Update" -state disabled \
		    -command "::abookGui::updatePhones $nbPhone h1 w1 m1 p1; destroy $w"
	    pack $w.b.ok $w.b.submit -side left
	    if {$edit != ""} {
		$w.b.submit configure -state normal
	    }

#	::themes::ApplyDeep $w {-background} $bgcol
	pack $w.n $w.b -side top
	bind $w <Control-c> { destroy $w }
   }
}
