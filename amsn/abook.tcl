#	User Administration (Address Book data)
#	by: Alvaro Jose Iradier Muro
#	Dídimo Emilio Grimaldo Tuñón
# $Id$
#=======================================================================


namespace eval ::abook {
#::abook namespace is used to store all information related to users
#and contact lists.

	if { $initialize_amsn == 1 } {
		#
		# P R I V A T E
		#
		variable demographics;	# Demographic Information about user
		
		#When set to 1, the information is in safe state an can be
		#saven to disk without breaking anything
		
		variable consistent 0; 
	}
	
	#########################
	# P U B L I C
	#########################
	
	#An alias for "setContactData myself". Sets data for the "myself" user
	proc setPersonal { field value} {
		setContactData myself $field $value
	}
   
	#An alias for "getContactData myself". Gets data for the "myself" user	
	proc getPersonal { field } {
		return [getContactData myself $field]
	}
	
	#TODO: Remove this
	proc getContact { email cdata } {
		upvar $cdata data

		set groupName    [::groups::GetName [getContactData $email group]]
		set data(group)  [urldecode $groupName]
		set data(handle) [urldecode [getContactData $email nick]]
		set data(PHH) [urldecode [getContactData $email PHH]]
		set data(PHW) [urldecode [getContactData $email PHW]]
		set data(PHM) [urldecode [getContactData $email PHM]]
		set data(MOB) [urldecode [getContactData $email MOB]]
		set data(available) "Y"
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
	# TODO: Change this to use setVolatileData to user myself
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
		abook::getIPConfig
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

	# This proc will configure all ip settings, get private ip, see if firewalled or not, and set netid
	proc getIPConfig { } {
		variable demographics

		set demographics(localip) [getLocalIP]
		set demographics(upnpnat) "false"
		set demographics(conntype) [getConnectionType [getDemographicField localip] [getDemographicField clientip]]
		if { $demographics(conntype) == "Direct-Connect" || $demographics(conntype) == "Firewall" } {
			set demographics(netid) 0
			set demographics(upnpnat) "false"
		} else {
			set demographics(netid) [GetNetID [getDemographicField clientip]]
			if { [getFirewalled [::config::getKey initialftport]] == "Firewall" } {
				set demographics(upnpnat) "false"
			} else {
				set demographics(upnpnat) "true"	
			}
		}

		set demographics(listening) [getListening [getDemographicField conntype]]
	}

	# This proc will get the localip (private ip, NAT or not)
	proc getLocalIP { } {
		set sk [sb get ns sock]

		if { $sk != "" } {
			return [lindex [fconfigure $sk -sockname] 0]
		} else {
			return ""
		}
	}

	# This will return the connection type : ip-restrict-nat, direct-connect or firewall
	proc getConnectionType { localip clientip } {
 
		if { $localip == "" || $clientip == "" } { 
			return [getFirewalled [::config::getKey initialftport]]
		} 
		if { $localip != $clientip } {
			return "IP-Restrict-NAT"
		} else { 
			return [getFirewalled [::config::getKey initialftport]]
		}
	}

	# This will create a server, and try to connect to it in order to see if firewalled or not
	proc getFirewalled { port } {
		while { [catch {set sock [socket -server "abook::dummysocketserver" $port] } ] } {
			incr port
		}
		if { [catch {set clientsock [socket [getDemographicField clientip] $port]} ] } {
			close $sock
			return "Firewall"
		} else {
			close $sock
			close $clientsock
			return "Direct-Connect"
		}
	}

	proc getListening { conntype } {
		if {$conntype == "Firewall" } {
			return "false"
		} elseif { $conntype == "Direct-Connect" } {
		        return "true"
		} else { 
			return [abook::getDemographicField upnpnat]
		}
	}

	# This proc is a dummy socket server proc, because we need a command to be called which the client connects to the test server (if not firewalled)
	proc dummysocketserver { sock ip port } {
	}

	# This will transform the ip adress into a netID adress (which is the 32 bits unsigned integer represent the ip)
	proc GetNetID { ip } {
		set val 0
		set inverted_ip ""
		foreach x [split $ip .] { 
			set inverted_ip "${x} ${inverted_ip}"	
		}
		
		foreach x $inverted_ip { 
			set val [expr {($val << 8) | ($x & 0xff)}] 
		}
		return [format %u $val]
 
	}

	#Clears all ::abook stored information
	proc clearData {} {
		variable users_data
		array unset users_data *
		
		variable users_volatile_data
		array unset users_volatile_data *
		
		unsetConsistent
	}

	#Sets some data to a user.
	#user_login: the user_login you want to set data to
	#field: the field you want to set
	#data: the data that will be contained in the given field
	proc setContactData { user_login field data } {
		variable users_data
		
		set field [string tolower $field]
		
		# There can't be double arrays, so users_data(user) is just a
		# list like {entry1 data1 entry2 data2 ...}
		if { [info exists users_data($user_login)] } {
			#We convert the list to an array, to make it easier
			array set user_data $users_data($user_login)
		} else {
			array set user_data [list]
		}
		
		if { $data == "" } {
			if { [info exists user_data($field)] } {
				unset user_data($field)
			}
		} else { 
			set user_data($field) $data
		}
		
		#We store the array as a plain list, as we can't have an array of arrays
		set users_data($user_login) [array get user_data]
	}

	#Sets some volatile data to a user. Volatile data won't be written to disk
	#user_login: the user_login you want to set data to
	#field: the field you want to set
	#data: the data that will be contained in the given field
	proc setVolatileData { user_login field data } {
		variable users_volatile_data
		
		set field [string tolower $field]
		
		if { [info exists users_volatile_data($user_login)] } {
			array set volatile_data $users_volatile_data($user_login)
		} else {
			array set volatile_data [list]
		}
		
		if { $data == "" } {
			if { [info exists volatile_data($field)] } {
				unset volatile_data($field)
			}
		} else { 
			set volatile_data($field) $data
		}
		
		set users_volatile_data($user_login) [array get volatile_data]
	}
	
		
	#Returns some previously stored data from a user
	proc getContactData { user_login field {defaultval ""}} {
		variable users_data
		
		set field [string tolower $field]
		
		if { ![info exists users_data($user_login)] } {
			return $defaultval
		}

		array set user_data $users_data($user_login)

		if { ![info exists user_data($field)] } {
			return $defaultval
		}
		
		return $user_data($field)
		
	}

	#Returns some previously stored volatile data from a user		
	proc getVolatileData { user_login field {defaultval ""}} {
		variable users_volatile_data
		
		set field [string tolower $field]
		
		if { ![info exists users_volatile_data($user_login)] } {
			return $defaultval
		}

		array set user_data $users_volatile_data($user_login)	

		if { ![info exists user_data($field)] } {
			return $defaultval
		}
		
		return $user_data($field)
		
	}	
	
	#Return a list of all stored contacts
	proc getAllContacts { } {
		variable users_data
		return [array names users_data]
	}
	
	
	###########################################################################
	# Auxiliar functions, macros, or shortcuts
	###########################################################################

	#Returns the user nickname
	proc getNick { user_login } {
		set nick [::abook::getContactData $user_login nick]
		if { $nick == "" } {
			return $user_login
		}
		return $nick
	}
	
	#Returns the user nickname, or just email, or custom nick,
	#depending on configuration
	proc getDisplayNick { user_login } {
		if { [::config::getKey emailsincontactlist] } {
			return $user_login
		} else {
			set customnick [::abook::getContactData $user_login customnick]
			if { $customnick != ""} {
				return $customnick
			}  else {
				return [::abook::getNick $user_login]
			}
		}
	}
	
	# Used to fetch the groups ID so that the caller can order by
	# group if needed. Returns -1 on error.
	# ::abook::getGroups my@passport.com    : returns group ids
	proc getGroups {passport} {
		return [getContactData $passport group]
	}
   
	proc addContactToGroup { email grId } {
		set groups [getContactData $email group]
		set idx [lsearch $groups $grId]
		if { $idx == -1 } {
			setContactData $email group [linsert $groups 0 $grId]
		}
	}

	proc removeContactFromGroup { email grId } {
		set groups [getContactData $email group]
		set idx [lsearch $groups $grId]
		
		if { $idx != -1 } {
			setContactData $email group [lreplace $groups $idx $idx]
		}
	}	

	proc getLists {passport} {
		return [getContactData $passport lists]
	}
   
	proc addContactToList { email listId } {
		set lists [getContactData $email lists]
		set idx [lsearch $lists $listId]
		if { $idx == -1 } {
			setContactData $email lists [linsert $lists 0 $listId]
		}
	}

	proc removeContactFromList { email listId } {
		set lists [getContactData $email lists]
		set idx [lsearch $lists $listId]
		
		if { $idx != -1 } {
			setContactData $email lists [lreplace $lists $idx $idx]
		}
	}	
	
	proc setConsistent {} {
		variable consistent
		set consistent 1
	}
	
	proc unsetConsistent {} {
		variable consistent
		set consistent 0
	}
	
	
	proc isConsistent {} {
		variable consistent
		return $consistent
	}
	
	proc saveToDisk { {filename ""} } {
		
		if { ![isConsistent] } {
			return
		}
	
		global HOME
		variable users_data
		
		if { $filename == "" } {
			set filename [file join $HOME abook.xml]
		}
		
		set file_id [open $filename w]

		fconfigure $file_id -encoding utf-8

		puts $file_id "<?xml version=\"1.0\" standalone=\"yes\" encoding=\"UTF-8\"?>"
		puts $file_id "<AMSN_AddressBook time=\"[clock seconds]\">"
		foreach user [array names users_data] {
			puts $file_id "<contact name=\"[::sxml::xmlreplace $user]\">"

			array set temp_array $users_data($user)
			foreach field [array names temp_array] {
				puts -nonewline $file_id "\t<$field>"
				puts -nonewline $file_id "[::sxml::xmlreplace $temp_array($field)]"	
				puts $file_id "</$field>"				
			}
			puts $file_id "</contact>"
			array unset temp_array
		}
		puts $file_id "</AMSN_AddressBook>"
		close $file_id
	}
	
	proc loadFromDisk { {filename ""} } {
	
		global HOME
		
		if { $filename == "" } {
			set filename [file join $HOME abook.xml]
		}
		
		if {[file readable $filename] == 0} {
			return -1
		}
		
		status_log "Loading address book data...\n" blue
		set abook_id [::sxml::init $filename]
		sxml::register_routine $abook_id "AMSN_AddressBook:contact" "::abook::loadXMLContact"
				
		set ret -1
		
		clearData
		
		catch {
			set ret [sxml::parse $abook_id]
		}
	
		sxml::end $abook_id			
		if { $ret < 0 } {
			clearData
			status_log "::abook::loadFromDisk Error\n" red
			return $ret
		} else {			
			status_log "Address book data loaded...\n" green
			setConsistent
			return 0
		}
	}
	
	proc loadXMLContact {cstack cdata saved_data cattr saved_attr args } {
		variable users_data
		upvar $saved_data sdata 
		upvar $saved_attr sattr
		
		array set attr $cattr
		
		set parentlen [string length $cstack]
		foreach child [array names sattr] {
			if { $child == "_dummy_" } {
				continue
			}
			set fieldname [string range $child [expr {$parentlen+1}] end]
			#Remove this. Only leave it for some days to remove old ::abook stored data
			if { $fieldname == "field" } {
				continue
			}
			setContactData $attr(name) $fieldname $sdata($child)
		}
		
		return 0	
		
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
   
   proc showUserProperties { email } {
   	set w ".user_[::md5::md5 $email]_prop"
   	if { [winfo exists $w] } {
		raise $w
		return
	}
   	toplevel $w
	wm title $w [trans userproperties $email]
	
	NoteBook $w.nb
	$w.nb insert 0 userdata -text [trans userdata]
	$w.nb insert 1 alarms -text [trans alarms]
	
	#Userdata page
	set nbIdent [$w.nb getframe userdata]
	ScrolledWindow $nbIdent.sw
	set sw $nbIdent.sw
	ScrollableFrame $nbIdent.sw.sf -constrainedwidth 1
	$nbIdent.sw setwidget $nbIdent.sw.sf
	set nbIdent [$nbIdent.sw.sf getframe]


	label $nbIdent.title1 -text [trans identity] -font bboldunderf
	   	
	label $nbIdent.e -text "Email:"
   	label $nbIdent.e1 -text $email -font splainf -fg blue 
	
	label $nbIdent.h -text "[trans nick]:"
	label $nbIdent.h1 -text [::abook::getNick $email] -font splainf -fg blue 
	
	label $nbIdent.customnickl -text "[trans customnick]:"
	entry $nbIdent.customnickent -font splainf -bg white
	$nbIdent.customnickent insert end [::abook::getContactData $email customnick] 
	
	
	label $nbIdent.g -text "[trans group]:"
	set groups ""
	foreach gid [::abook::getGroups $email] {
		set groups "$groups[::groups::GetName $gid]\n"
	}
	set groups [string range $groups 0 end-1]
	label $nbIdent.g1 -text $groups -font splainf -fg blue -justify left

	
	label $nbIdent.titlephones -text [trans phones] -font bboldunderf
	
	set nbPhone $nbIdent
	label $nbPhone.phh -text "[trans home]:" 
	label $nbPhone.phh1 -font splainf -text [::abook::getContactData $email phh] -fg blue \
		-justify left
	label $nbPhone.phw -text "[trans work]:"
	label $nbPhone.phw1 -font splainf -text [::abook::getContactData $email phw] -fg blue \
		-justify left
	label $nbPhone.phm -text "[trans mobile]:" 
	label $nbPhone.phm1 -font splainf -text [::abook::getContactData $email phm] -fg blue \
		-justify left
	label $nbPhone.php -text "[trans pager]:" 
	label $nbPhone.php1 -font splainf -text [::abook::getContactData $email mob] -fg blue \
		-justify left
	

	label $nbIdent.titleothers -text [trans others] -font bboldunderf 
	
	label $nbIdent.lastlogin -text "[trans lastlogin]:"
	label $nbIdent.lastlogin1 -text [::abook::getContactData $email last_login] -font splainf -fg blue 
		
	label $nbIdent.lastlogout -text "[trans lastlogout]:"
	label $nbIdent.lastlogout1 -text [::abook::getContactData $email last_logout] -font splainf -fg blue 
				
	grid $nbIdent.title1 -row 0 -column 0 -pady 5 -padx 5 -columnspan 2 -sticky w 
	grid $nbIdent.e -row 1 -column 0 -sticky e
	grid $nbIdent.e1 -row 1 -column 1 -sticky w
	grid $nbIdent.h -row 2 -column 0 -sticky e
	grid $nbIdent.h1 -row 2 -column 1 -sticky w
	grid $nbIdent.customnickl -row 3 -column 0 -sticky en
	grid $nbIdent.customnickent -row 3 -column 1 -sticky wne
	grid $nbIdent.g -row 4 -column 0 -sticky en
	grid $nbIdent.g1 -row 4 -column 1 -sticky wn
	
	grid $nbIdent.titlephones -row 5 -column 0 -pady 5 -padx 5 -columnspan 2 -sticky w 
	grid $nbPhone.phh -row 6 -column 0 -sticky e
	grid $nbPhone.phh1 -row 6 -column 1 -sticky w
	grid $nbPhone.phw -row 7 -column 0 -sticky e
	grid $nbPhone.phw1 -row 7 -column 1 -sticky w
	grid $nbPhone.phm -row 8 -column 0 -sticky e
	grid $nbPhone.phm1 -row 8 -column 1 -sticky w
	grid $nbPhone.php -row 9 -column 0 -sticky e
	grid $nbPhone.php1 -row 9 -column 1 -sticky w

	grid $nbIdent.titleothers -row 15 -column 0 -pady 5 -padx 5 -columnspan 2 -sticky w 
	grid $nbPhone.lastlogin -row 16 -column 0 -sticky e
	grid $nbPhone.lastlogin1 -row 16 -column 1 -sticky w
	grid $nbPhone.lastlogout -row 17 -column 0 -sticky e
	grid $nbPhone.lastlogout1 -row 17 -column 1 -sticky w
		
	
	grid columnconfigure $nbIdent 1 -weight 1

	pack $sw -expand true -fill both
	
		
	#Alarms frame
	set nbIdent [$w.nb getframe alarms]
	ScrolledWindow $nbIdent.sw
	pack $nbIdent.sw -expand true -fill both
	ScrollableFrame $nbIdent.sw.sf
	$nbIdent.sw setwidget $nbIdent.sw.sf
	set nbIdent [$nbIdent.sw.sf getframe]
	
	#::alarms::configDialog $email $nbIdent
	
	$w.nb compute_size
	pack $w.nb -expand true -fill both -side top
	$w.nb raise userdata
	
	frame $w.buttons
	
	button $w.buttons.ok -text [trans accept] -command [list ::abookGui::PropOk $email $w]
	button $w.buttons.cancel -text [trans cancel] -command [list destroy $w]
	
	pack $w.buttons.ok $w.buttons.cancel -side right -padx 5 -pady 3
	
	pack $w.buttons -fill x -side top
	
   }

   proc PropOk { email w } {
	set nbIdent [$w.nb getframe userdata]
	set nbIdent [$nbIdent.sw.sf getframe]
   	::abook::setContactData $email customnick [$nbIdent.customnickent get]
   	destroy $w
	::MSN::contactListChanged
	cmsn_draw_online
   }
         
   proc showEntry { email {edit ""}} {
   		showUserProperties $email
		return
		
		variable bgcol

		set cd(available) "N"
		
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

	
	set last_login [::abook::getContactData $email last_login]
	set last_logout [::abook::getContactData $email last_logout]

	toplevel $w -class ABook
	wm title $w "[trans about] $email"
#	wm geometry $w 210x140
	set nbtIdent "[trans identity]"
	set nbtPhone "[trans phone]"
	set nbtOthers "[trans others]"
	frame $w.n -class ABook
	    pack [notebook $w.n.p $nbtIdent $nbtPhone $nbtOthers] \
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
	label $nbPhone.h1 -font splainf -text $cd(PHH) -fg blue \
		-justify left
	label $nbPhone.w -font bboldf -text "[trans work]:"
	label $nbPhone.w1 -font splainf -text $cd(PHW) -fg blue \
		-justify left
	label $nbPhone.m -font bboldf -text "[trans mobile]:" 
	label $nbPhone.m1 -font splainf -text $cd(PHM) -fg blue \
		-justify left
	label $nbPhone.p -font bboldf -text "[trans pager]:" 
	label $nbPhone.p1 -font splainf -text $cd(MOB) -fg blue \
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
	entry $nbPhone.h1 -font splainf -text cd(PHH) -fg blue
	$nbPhone.h1 insert 1 $cd(PHH)
	label $nbPhone.w -font bboldf -text "[trans work]:"
	entry $nbPhone.w1 -font splainf -text cd(PHW) -fg blue 
	$nbPhone.w1 insert 1 $cd(PHW)
	label $nbPhone.m -font bboldf -text "[trans mobile]:" 
	entry $nbPhone.m1 -font splainf -text cd(PHM) -fg blue 
	$nbPhone.m1 insert 1 $cd(PHM)
	label $nbPhone.p -font bboldf -text "[trans pager]:" 
	label $nbPhone.p1 -font splainf -text $cd(MOB) -fg blue \
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

	#  .----------.
	# _| Others |________________________________________________
	set nbOthers [getNote $w.n.p $nbtOthers]
	$nbOthers configure 
   	label $nbOthers.e -text "[trans lastlogin]:" -font bboldf 
   	label $nbOthers.e1 -text $last_login -font splainf -fg blue 
	label $nbOthers.h -text "[trans lastlogout]:" -font bboldf 
	label $nbOthers.h1 -text $last_logout -font splainf -fg blue 
	grid $nbOthers.e -row 0 -column 0 -sticky e
	grid $nbOthers.e1 -row 0 -column 1 -sticky w
	grid $nbOthers.h -row 1 -column 0 -sticky e
	grid $nbOthers.h1 -row 1 -column 1 -sticky w	
	
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
	bind $w <Control-c> "destroy $w"
   }
}
