#	User Administration (Address Book data)
#	by: Dídimo Emilio Grimaldo Tuñón
# $Id$
#=======================================================================
namespace eval ::abook {
   namespace export setGroup getGroup setContact getContact \
   		    setPhone setDemographics getDemographics

   #
   # P R I V A T E
   #
   variable contacts;	# Array for contacts
   			# contacts(email) {		   BPR*
			#	handle			   LST
			#       groupId			   LST
			#	phone { home work mobile } BPR.PHH/PHW/PHM
			#	pager			   BPR.MOB
			# }
   variable groups;	# Array for groups
   			# groups(id) { name }		   LSG
   variable groupCnt 0
   variable demographics;	# Demographic Information about user

   #
   # P R O T E C T E D
   #

   #
   # P U B L I C
   #
   proc setGroup { nr name } {	# LSG <x> <trid> <cnt> <total> <nr> <name> 0
       variable groups
       variable groupCnt

       set groups($nr) $name
       incr groupCnt
#       puts "ABOOK: added group $nr ($name)"
   }
   
   proc getGroup {nr} {
       variable groupCnt
       variable groups

       if { $nr > $groupCnt } { 
       	   return "" 
       } else { 
           return $groups($nr) 
       }
   }

   proc setContact { email field value } {
   	variable contacts 

	# Phone numbers are countryCode%20areaCode%20subscriberNumber
	if { ![info exists contacts($email)] } {
	  set contacts($email) [list Dummy Dummy Dummy Dummy Dummy Dummy]
	}
        switch $field {
	    FL {	;# From LST.FL command, contains email, groupId
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
	    puts "ERROR: unknown contact!"
	    return
	}
	
#puts $contacts($email)
	set groupName    [::abook::getGroup [lindex $contacts($email) 0]]
	set data(group)  [urldecode $groupName]
	set data(handle) [urldecode [lindex $contacts($email) 1]]
	set data(phh)    [urldecode [lindex $contacts($email) 2]]
	set data(phw)    [urldecode [lindex $contacts($email) 3]]
	set data(phm)    [urldecode [lindex $contacts($email) 4]]
	set data(mob)    [urldecode [lindex $contacts($email) 5]]
	set data(available) Y
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
	wm geometry $w 185x140
	set nbtIdent "[trans identity]"
	set nbtPhone "[trans phone]"
	frame $w.n
	    pack [notebook $w.n.p $nbtIdent $nbtPhone] \
	    	-expand 1 -fill both -padx 1m -pady 1m
	#  .----------.
	# _| Identity |________________________________________________
	set nbIdent [getNote $w.n.p $nbtIdent]
   	label $nbIdent.e -text "Email:" -font bboldf
   	label $nbIdent.e1 -text $email -font splainf -foreground blue
	label $nbIdent.h -text "[trans handle]:" -font bboldf
	label $nbIdent.h1 -text $cd(handle) -font splainf -foreground blue
	label $nbIdent.g -text "[trans group]:" -font bboldf
	label $nbIdent.g1 -text $cd(group) -font splainf -foreground blue
	grid $nbIdent.e -row 0 -column 0 -sticky e
	grid $nbIdent.e1 -row 0 -column 1
	grid $nbIdent.h -row 1 -column 0 -sticky e
	grid $nbIdent.h1 -row 1 -column 1
	grid $nbIdent.g -row 2 -column 0 -sticky e
	grid $nbIdent.g1 -row 2 -column 1
        bind $w <Control-i> "pickNote $w.n.p $nbtIdent"

	#  .--------.
	# _| Phones |________________________________________________
	set nbPhone [getNote $w.n.p $nbtPhone]
	if { $edit == "" } {
	label $nbPhone.h -font bboldf -text "[trans home]:"
	label $nbPhone.h1 -font splainf -text $cd(phh) -foreground blue \
		-justify left
	label $nbPhone.w -font bboldf -text "[trans work]:"
	label $nbPhone.w1 -font splainf -text $cd(phw) -foreground blue \
		-justify left
	label $nbPhone.m -font bboldf -text "[trans mobile]:"
	label $nbPhone.m1 -font splainf -text $cd(phm) -foreground blue \
		-justify left
	label $nbPhone.p -font bboldf -text "[trans pager]:"
	label $nbPhone.p1 -font splainf -text $cd(mob) -foreground blue \
		-justify left
	grid $nbPhone.h -row 0 -column 0 -sticky e
	grid $nbPhone.h1 -row 0 -column 1
	grid $nbPhone.w -row 1 -column 0 -sticky e
	grid $nbPhone.w1 -row 1 -column 1
	grid $nbPhone.m -row 2 -column 0 -sticky e
	grid $nbPhone.m1 -row 2 -column 1
	grid $nbPhone.p -row 3 -column 0 -sticky e
	grid $nbPhone.p1 -row 3 -column 1
	} else {
	label $nbPhone.h -font bboldf -text "[trans home]:"
	entry $nbPhone.h1 -font splainf -text cd(phh) -foreground blue 
	$nbPhone.h1 insert 1 $cd(phh)
	label $nbPhone.w -font bboldf -text "[trans work]:"
	entry $nbPhone.w1 -font splainf -text cd(phw) -foreground blue 
	$nbPhone.w1 insert 1 $cd(phw)
	label $nbPhone.m -font bboldf -text "[trans mobile]:"
	entry $nbPhone.m1 -font splainf -text cd(phm) -foreground blue
	$nbPhone.m1 insert 1 $cd(phm)
	label $nbPhone.p -font bboldf -text "[trans pager]:"
	label $nbPhone.p1 -font splainf -text $cd(mob) -foreground blue \
		-justify left
	grid $nbPhone.h -row 0 -column 0 -sticky e
	grid $nbPhone.h1 -row 0 -column 1
	grid $nbPhone.w -row 1 -column 0 -sticky e
	grid $nbPhone.w1 -row 1 -column 1
	grid $nbPhone.m -row 2 -column 0 -sticky e
	grid $nbPhone.m1 -row 2 -column 1
	grid $nbPhone.p -row 3 -column 0 -sticky e
	grid $nbPhone.p1 -row 3 -column 1
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
