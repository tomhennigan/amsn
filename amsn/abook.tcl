#	User Administration (Address Book data)
#	by: Alvaro Jose Iradier Muro
#	D�imo Emilio Grimaldo Tu�n
# $Id$
#=======================================================================

::snit::type Group {

	variable users {}
	option -name
	option -id

	method showInfo { } {
		status_log ----
		status_log id:$options(-id)
		status_log name:$options(-name)
		status_log users:$users
	}

	method addUser { user } {
		llappend users $user
	} 
}



namespace eval ::abook {
#::abook namespace is used to store all information related to users
#and contact lists.

	if { $initialize_amsn == 1 } {
		#
		# P R I V A T E
		#
		variable demographics;	# Demographic Information about user
		
		#When set to 1, the information is in safe state and can be
		#saved to disk without breaking anything
		
		variable consistent 0

		# This list stores the names of the fields about the visual representation of the buddy.
		# When this fields gets changed, we fire an event to redraw that contact on our CL.
		variable VisualData [list nick customnick customfnick cust_p4c_name customcolor]

		global pgc pcc
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
		set data(handle) [urldecode [getVolatileData $email nick]]
		set data(PHH) [urldecode [getVolatileData $email PHH]]
		set data(PHW) [urldecode [getVolatileData $email PHW]]
		set data(PHM) [urldecode [getVolatileData $email PHM]]
		set data(MOB) [urldecode [getVolatileData $email MOB]]
		set data(available) "Y"
	}

	# Get PSM and currentMedia
	proc getpsmmedia { { user_login "" } } {
		if { [::config::getKey protocol] < 11 } { return }
		set psmmedia ""
		if { $user_login == "" } {
	                set psm [::abook::getPersonal PSM]
        	        set currentMedia [parseCurrentMedia [::abook::getPersonal currentMedia]]
		} else {
                	set psm [::abook::getVolatileData $user_login PSM]
                	set currentMedia [parseCurrentMedia [::abook::getVolatileData $user_login currentMedia]]
		}
                if {$psm != ""} {
                        append psmmedia "$psm"
                }
                if {$currentMedia != ""} {
                        if { $psm != ""} {
                                append psmmedia " "
                        }
                        append psmmedia "$currentMedia"
                }
		return $psmmedia
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
			pager { 
				::MSN::WriteSB ns PRP "MOB $value"
				if { $value == "Y" } {
					::MSN::setClientCap paging
				} else {
					::MSN::setClientCap paging 0
				}
				::MSN::changeStatus [::MSN::myStatusIs]
			 }
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

	################################################################################################################################
	################################################################################################################################
	################################################################################################################################
	############## MOVE ALL PROTOCOL/IP CHECK RELATED PROCEDURES OUT OF ABOOK!! ABOOK SHOULD CARE ONLY ABOUT #######################
	############## DATA STORAGE, NOT ABOUT SERVERS/IPS/CONNECTIONS OR WHATEVER !!                            #######################
	
	# This proc will configure all ip settings, get private ip, see if firewalled or not, and set netid
	proc getIPConfig { } {
		variable demographics

		status_log "Getting local IP\n"
		set demographics(localip) [getLocalIP]
		status_log "Finished\n"
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
		set sk [ns cget -sock]

		if { $sk != "" } {
			foreach ip $sk {break}
			return $ip
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
		global connection_success
		while { [catch {set sock [socket -server "abook::dummysocketserver" $port] } ] } {
			incr port
		}
		status_log "::abook::getFirewalled: Connecting to [getDemographicField clientip] port $port\n" blue
		
		#Need this timeout thing to avoid the socket blocking...
		set connection_success 0
		if {[catch {set clientsock [socket -async [getDemographicField clientip] $port]}]} {
			catch {close $sock}
			return "Firewall"
		}

		fileevent $clientsock readable [list ::abook::connectionHandler $clientsock]
		after 1000 ::abook::connectionTimeout
		vwait connection_success
		if { $connection_success == 0 } {
			catch {close $sock}
			catch { close $clientsock }
			return "Firewall"
		} else {
			catch {close $sock}
			catch { close $clientsock }
			return "Direct-Connect"
		}
	}
	
	proc connectionTimeout {} {
		global connection_success
		status_log "::abook::connectionTimeout\n"
		set connection_success 0
	}
	
	proc connectionHandler { sock } {
		#CHECK FOR AN ERROR
		global connection_success
		after cancel ::abook::connectionTimeout
		fileevent $sock readable ""
		if { [fconfigure $sock -error] != ""} {
			status_log "::abook::connectionHandler: connection failed\n" red
			set connection_success 0
		} else {
			gets $sock server_data
			if { "$server_data" != "AMSNPING" } {
				status_log "::abook::connectionHandler: port in use by another application!\n" red
				set connection_success 0
			} else {
				status_log "::abook::connectionHandler: connection succesful\n" green
				set connection_success 1
			}
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
		if {[catch {
			puts $sock "AMSNPING"
			flush $sock
			close $sock
		}]} {
			status_log "::abook::dummysocketserver: Error writing to socket\n"
		}
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
	################################################################################################################################
	################################################################################################################################
	################################################################################################################################

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
		global pgc
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

		# An event used by guicontactlist to know when a user changed his nick (or state)
		if { [lsearch -exact $::abook::VisualData $field] > -1 } {
			if { [info exists user_data($field)] && $user_data($field) != $data } {
				#puts stdout "ATTENTION! Visual Data has changed! Redraw CL! $field - $data"
				::Event::fireEvent contactDataChange abook $user_login
			} elseif { ![info exists user_data($field)] && $data != ""} {
				#puts stdout "ATTENTION! Visual Data has changed! Redraw CL! $field - $data"
				::Event::fireEvent contactDataChange abook $user_login
			}
		}

		if { $data == "" } {
			if { [info exists user_data($field)] } {
				unset user_data($field)
			}
		} else {
			#post event for amsnplus
			set evPar(data) data
			::plugins::PostEvent parse_nick evPar

			set user_data($field) $data
		}
		
		set users_data($user_login) [array get user_data]
		
		#We make this to notify preferences > groups to be refreshed
		set pgc 1
	}

	proc setContactForGuid { guid user_login } {
		variable guid_contact
		if { $user_login == "" } {
			if { [info exists guid_contact($guid)] } {
				unset guid_contact($guid)
			}
		} else {
			set guid_contact($guid) $user_login
		}
	}

	proc getContactForGuid { guid } {
		variable guid_contact
		if { [info exists guid_contact($guid)] } {
			return $guid_contact($guid)
		} else {
			return ""
		}
	}

	proc setAtomicContactData { user_login fields_list data_list } {
		global pgc
		variable users_data

		set fields_list [string tolower $fields_list]

		if { [info exists users_data($user_login)] } {
			array set user_data $users_data($user_login)
		} else {
			array set user_data [list]
		}

		# This loop iterates over the lists of fields and data, so when it finds that one of
		# the fields has to do with visual information, it throws an event and breaks the loop
		foreach field $fields_list data $data_list {
			if { [lsearch -exact $::abook::VisualData $field] > -1 } {
				if { [info exists user_data($field)] && $user_data($field) != $data } {
					#puts stdout "ATTENTION! Visual Data has changed! Redraw CL! $field - $data"
					::Event::fireEvent contactDataChange abook $user_login
					break
				} elseif { ![info exists user_data($field)] && $data != ""} {
					#puts stdout "ATTENTION! Visual Data has changed! Redraw CL! $field - $data"
					::Event::fireEvent contactDataChange abook $user_login
					break
				}
			}
		}

		# This other loop iterates over the entire lists, replacing the value in user_data(array)
		# if needed. There are two different loops because this one cannot be broke.
		foreach field $fields_list data $data_list {
			if { $data == "" } {
				if { [info exists user_data($field)] } {
					unset user_data($field)
				}
			} else {
				#post event for amsnplus
				set evPar(data) data
				::plugins::PostEvent parse_nick evPar
				set user_data($field) $data
			}
		}

		set users_data($user_login) [array get user_data]
		set pgc 1
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
	# Auxiliary functions, macros, or shortcuts
	###########################################################################

	#Returns the user nickname
	proc getNick { user_login } {
		set nick [::abook::getContactData $user_login nick]
		if { $nick == "" } {
			return $user_login
		}
		return $nick
	}

	proc getPassportfromContactguid { contactguid } {
		foreach contact [::abook::getAllContacts] {
			if { [::abook::getContactData $contact contactguid] == $contactguid } {
				return $contact
			}
		}
	}

	proc lastSeen { } {
		foreach contact [::abook::getAllContacts] {
			set user_state_code [::abook::getVolatileData $contact state FLN]
			if {$user_state_code != "FLN"} {
				::abook::setContactData $contact last_seen [clock format [clock seconds] -format "%D - %H:%M:%S"]
			}
		}
	}

	proc CreateCopyMenu { w } {
		set menu $w.copy
		menu $menu -tearoff 0 -type normal
		$menu add command -label [trans copy] \
			-command "::abook::copyFromText $w"

		return $menu
	}

	proc copyFromText { w } {

		set index [$w tag ranges sel]
		clipboard clear

		if { [llength $index] < 2 } {
			set index [list 0.0 end]
		}

		set dump [$w dump -text [lindex $index 0] [lindex $index 1]]
		foreach { text output index } $dump {
			clipboard append "$output"
		}

	}

	proc dateconvert {time} {
		set date [clock format [clock seconds] -format "%D"]
		if {$time == ""} {
			return ""
		} else {
			if {![catch {clock scan [string range $time 0 7]}]} {
				#Checks if the time is today, and in this case puts today instead of the date
				if {[clock scan $date] == [clock scan [string range $time 0 7]]} {
					return "[trans today][string range $time 8 end]"
					#Checks if the time is yesterday, and in this case puts yesterday instead of the date
				} elseif { [expr { [clock scan $date] - [clock scan [string range $time 0 7]] }] == "86400"} {
					return "[trans yesterday][string range $time 8 end]"
				} else {
					set month [string range $time 0 1]
					set day [string range $time 3 4]
					set year [string range $time 6 7]
					set end [string range $time 8 end]
					#Month/Day/Year
					if {[::config::getKey dateformat]=="MDY"} {
						return $time
					#Day/Month/Year
					} elseif {[::config::getKey dateformat]=="DMY"} {
						return "$day/$month/$year$end"
					#Year/Month/Day
					} elseif {[::config::getKey dateformat]=="YMD"} {
						return "$year$end/$month/$day"
					}
				}
			} else {
				return $time
			}
		}
	}


	#Parser to replace special characters and variables in the right way
	proc parseCustomNick { input nick user_login customnick {psm ""} } {
		#If there's no customnick set, default to user_login
		if { $customnick == "" } {
			if { [::config::getKey protocol] >= 11 && $psm != "" } {
				set customnick $user_login\n$psm
			} else {
				set customnick $user_login
			}
		}
		#By default, quote backslashes, angle brackets and variables
		set input [string map {"\\" "\\\\" "\$" "\\\$" "\(" "\\\("} $input]
		#Now, let's unquote the variables we want to replace
		set input [string map {"\\\$nick" "\${nick}" "\\\$user_login" "\${user_login}" "\\\$customnick" "\${customnick}" "\\\$psm" "\${psm}"} $input]
		#Return the custom nick, replacing backslashses and variables
		return [subst -nocommands $input]
	}
	
	#Returns the user nickname, or just email, or custom nick,
	#depending on configuration
	proc getDisplayNick { user_login } {
		if { [::config::getKey emailsincontactlist] } {
			return $user_login
		} else {
			set nick [::abook::getNick $user_login]
			set customnick [::abook::getContactData $user_login customnick]
			set globalnick [::config::getKey globalnick]
			set psm [::abook::getpsmmedia $user_login]
			
			if { [::config::getKey globaloverride] == 0 } {
				if { $customnick != "" } {
					return [parseCustomNick $customnick $nick $user_login $customnick $psm]
				} elseif { $globalnick != "" && $customnick == "" } {
					return [parseCustomNick $globalnick $nick $user_login $customnick $psm]
				} else {
					return $nick
				}
			} elseif { [::config::getKey globaloverride] == 1 } {
				if { $customnick != "" && $globalnick == "" } {
					return [parseCustomNick $customnick $nick $user_login $customnick $psm]
				} elseif { $globalnick != "" } {
					return [parseCustomNick $globalnick $nick $user_login $customnick $psm]
				} else {
					return $nick
				}
			}
		}
	}
	
	# Used to fetch the groups ID so that the caller can order by
	# group if needed. Returns -1 on error.
	# ::abook::getGroups my@passport.com    : returns group ids
	proc getGroups {passport} {
		return [getContactData $passport group]
	}

	proc getGroupsname {passport} {

		set groups ""
                foreach gid [::abook::getGroups $passport] {
                        set groups "$groups[::groups::GetName $gid], "
                }
                
                set groups [string range $groups 0 end-2]
		return $groups
	}

	

   
	proc addContactToGroup { email grId } {
		global pcc
		
		set groups [getContactData $email group]
		set idx [lsearch $groups $grId]
		if { $idx == -1 } {
			setContactData $email group [linsert $groups 0 $grId]
		}
		#we make this to notify preferences > groups to be refreshed
		set pcc 1
	}

	proc removeContactFromGroup { email grId } {
		global pcc
		
		set groups [getContactData $email group]
		set idx [lsearch $groups $grId]
		
		if { $idx != -1 } {
			setContactData $email group [lreplace $groups $idx $idx]
		}
		set pcc 1
	}	

	proc getLists {passport} {
		return [getContactData $passport lists]
	}
   
	proc addContactToList { email listId } {
		global pcc
		
		set lists [getContactData $email lists]
		set idx [lsearch $lists $listId]
		if { $idx == -1 } {
			setContactData $email lists [linsert $lists 0 $listId]
		}
		set pcc 1
	}

	proc removeContactFromList { email listId } {
		global pcc
		
		set lists [getContactData $email lists]
		set idx [lsearch $lists $listId]
		
		if { $idx != -1 } {
			setContactData $email lists [lreplace $lists $idx $idx]
		}
		set pcc 1
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
	
	#Save the contactlist to disk
	#filename - the filename to save to
	#type - the type to save as
	#possible types: csv, amsn
	proc saveToDisk { {filename ""} {type "amsn"} } {
		
		if { ![isConsistent] } {
			return
		}
	
		global HOME
		variable users_data
		
		if { $filename == "" } {
			set filename [file join $HOME abook.xml]
		}
		
		if {[catch { set file_id [open $filename w]} res ]} {
			status_log "::saveToDisk $res"
			msg_box "Can't save contact list, $res"
			return
		}
		
		
		fconfigure $file_id -encoding utf-8

		if { [string equal $type "amsn"] } {
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
		} elseif { [string equal $type "csv"] } {
			puts $file_id "email,name"
			foreach contact [::abook::getAllContacts] {
				if { [string last "FL" [::abook::getContactData $contact lists]] != -1 } {
					array set temp_array $users_data($contact)
					if { [info exists temp_array([array names temp_array "nick"])] } {
						puts $file_id "$contact,$temp_array([array names temp_array "nick"])"
					} else {
						puts $file_id "$contact,"
					}
				}
			}
		} elseif { [string equal $type "ctt"] } {
			puts $file_id "<?xml version=\"1.0\"?>\n<messenger>\n\t<service name=\".NET Messenger Service\">\n\t\t<contactlist>"
			foreach contact [::abook::getAllContacts] {
				if { [string last "FL" [::abook::getContactData $contact lists]] != -1 } {
					puts $file_id "\t\t\t<contact>$contact</contact>"
				}
			}
			puts $file_id "\t\t</contactlist>\n\t</service>\n</messenger>"
		}
			

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
	
	
	proc importContact { } {
	
		set filename [chooseFileDialog]

		if { $filename != "" } {
			if { [string match -nocase "*.ctt" "$filename"] } {
				::abook::importContactctt $filename
			} elseif { [string match -nocase "*.csv" "$filename"] } {
				::abook::importContactcsv $filename
			}
		}
		
	}
	
	proc importContactcsv { filename } {
	
		set ImportedContact [list]
		
		set file_id [open $filename r]
		fconfigure $file_id -encoding utf-8
		set content [read $file_id]
		close $file_id
		set lines [split $content "\n"]
		
		foreach line $lines {
			if { [string first "@" $line] != -1 } {
				set coma [string first "," $line]
				set contact [string range $line 0 [expr {$coma - 1}]]
				set ImportedContact [lappend ImportedContact $contact]
			}
		}
		
		::abook::importContactList $ImportedContact
		
	}
	
	proc importContactctt { filename } {
	
		status_log "Salut\n" red
	
		set ImportedContact [list]
		
		set file_id [open $filename r]
		fconfigure $file_id -encoding utf-8
		set content [read $file_id]
		close $file_id
		set lines [split $content "\n"]
		
		status_log "$lines"
		
		foreach line $lines {
			set id1 [string first "<contact>" $line]
			set id2 [string first "</contact>" $line]
			if { $id1 != -1 && $id2 != -1 } {
				incr id1 9
				incr id2 -1
				set contact [string range "$line" $id1 $id2]
				set ImportedContact [lappend ImportedContact $contact]
			}
		}
		
		::abook::importContactList $ImportedContact

	}
	
	proc importContactList { ImportedContact } {
	
		foreach contact $ImportedContact {
			status_log "Importation of contacts : $contact\n" red
			if { [::config::getKey protocol] >= 11 } {
				::MSN::WriteSB ns "ADC" "FL N=$contact F=$contact"
			} else {
				::MSN::WriteSB ns "ADD" "FL $contact $contact 0"
			}
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
   

	proc userDPs_raise_cmd { nb email } { 
		package require dpbrowser
		set nbIdent [$nb getframe userDPs]
		
		if { ![winfo exists $nbIdent.otherpics]} {
			::dpbrowser $nbIdent.otherpics -user $email
			pack $nbIdent.otherpics -expand true -fill both
		}
	}
		  



	proc showUserProperties { email } {
		global colorval_$email showcustomsmileys_$email ignorecontact_$email
		set w ".user_[::md5::md5 $email]_prop"
		if { [winfo exists $w] } {
			raise $w
			return
		}
		toplevel $w
		wm title $w [trans userproperties $email]
		
		NoteBook $w.nb
		$w.nb insert 0 userdata -text [trans userdata]
		$w.nb insert 1 usersettings -text [trans usersettings]
		$w.nb insert 2 alarms -text [trans alarms]
		$w.nb insert 3 userDPs -text [trans userdps] \
			-raisecmd [list ::abookGui::userDPs_raise_cmd $w.nb $email]

		##############
		#Userdata page
		##############
		set nbIdent [$w.nb getframe userdata]
		ScrolledWindow $nbIdent.sw
		set sw $nbIdent.sw
		ScrollableFrame $nbIdent.sw.sf -constrainedwidth 1
		$nbIdent.sw setwidget $nbIdent.sw.sf
		set nbIdent [$nbIdent.sw.sf getframe]
		
		labelframe $nbIdent.fBasicInfo -relief groove -text [trans identity]
		
		label $nbIdent.fBasicInfo.displaypic -image [::skin::getDisplayPicture $email] -highlightthickness 2 -highlightbackground black -borderwidth 0
		
		set nick [::abook::getNick $email]
		set h [expr {[string length $nick]/50 +1}]
		text $nbIdent.fBasicInfo.h1 -font bigfont -fg blue -height $h -wrap word -bd 0
		$nbIdent.fBasicInfo.h1 delete 0.0 end
		$nbIdent.fBasicInfo.h1 insert 0.0 $nick
		$nbIdent.fBasicInfo.h1 configure -state disabled
		set h1copymenu [::abook::CreateCopyMenu $nbIdent.fBasicInfo.h1]
		bind $nbIdent.fBasicInfo.h1 <Button3-ButtonRelease> "tk_popup $h1copymenu %X %Y"
		
		if { [::config::getKey protocol] >= 11 } {
			set psm [::abook::getVolatileData $email PSM]
			set h [expr {[string length $psm]/50 +1}]
			text $nbIdent.fBasicInfo.psm1 -font sitalf -fg blue -height $h -wrap word -bd 0
			$nbIdent.fBasicInfo.psm1 delete 0.0 end
			$nbIdent.fBasicInfo.psm1 insert 0.0 $psm
			$nbIdent.fBasicInfo.psm1 configure -state disabled
			set psm1copymenu [::abook::CreateCopyMenu $nbIdent.fBasicInfo.psm1]
			bind $nbIdent.fBasicInfo.psm1 <Button3-ButtonRelease> "tk_popup $psm1copymenu %X %Y"
		}

		set h [expr {[string length $email]/50 +1}]
		text $nbIdent.fBasicInfo.e1 -font splainf -fg blue -height $h -wrap word -bd 0
		$nbIdent.fBasicInfo.e1 delete 0.0 end
		$nbIdent.fBasicInfo.e1 insert 0.0 $email
		$nbIdent.fBasicInfo.e1 configure -state disabled
		set e1copymenu [::abook::CreateCopyMenu $nbIdent.fBasicInfo.e1]
		bind $nbIdent.fBasicInfo.e1 <Button3-ButtonRelease> "tk_popup $e1copymenu %X %Y"
		
		frame $nbIdent.fBasicInfo.fGroup
		label $nbIdent.fBasicInfo.fGroup.g -text "[trans group]:" -font splainf
		label $nbIdent.fBasicInfo.fGroup.g1 -text "[::abook::getGroupsname $email]" -font splainf -fg blue -justify left -wraplength 300
		pack $nbIdent.fBasicInfo.fGroup.g -side left
		pack $nbIdent.fBasicInfo.fGroup.g1 -side right
		
		grid $nbIdent.fBasicInfo.displaypic -row 0 -column 0 -sticky nwe -rowspan 4 -padx {0 8}
		grid $nbIdent.fBasicInfo.h1 -row 0 -column 1 -sticky w
		grid $nbIdent.fBasicInfo.e1 -row 1 -column 1 -sticky w
		if { [::config::getKey protocol] >= 11 } {
			grid $nbIdent.fBasicInfo.psm1 -row 2 -column 1 -sticky w
		}
		grid $nbIdent.fBasicInfo.fGroup -row 3 -column 1 -sticky w
		grid columnconfigure $nbIdent.fBasicInfo 1 -weight 1

		labelframe $nbIdent.fPhone -text [trans phones]
		label $nbIdent.fPhone.phh -text "[trans home]:" 
		label $nbIdent.fPhone.phh1 -font splainf -text [::abook::getVolatileData $email phh] -fg blue \
		-justify left -wraplength 300 
		label $nbIdent.fPhone.phw -text "[trans work]:"
		label $nbIdent.fPhone.phw1 -font splainf -text [::abook::getVolatileData $email phw] -fg blue \
			-justify left -wraplength 300 
		label $nbIdent.fPhone.phm -text "[trans mobile]:" 
		label $nbIdent.fPhone.phm1 -font splainf -text [::abook::getVolatileData $email phm] -fg blue \
		-justify left -wraplength 300 
		label $nbIdent.fPhone.php -text "[trans pager]:" 
		label $nbIdent.fPhone.php1 -font splainf -text [::abook::getVolatileData $email mob] -fg blue \
		-justify left -wraplength 300 

		grid $nbIdent.fPhone.phh -row 0 -column 0 -sticky e
		grid $nbIdent.fPhone.phh1 -row 0 -column 1 -sticky w
		grid $nbIdent.fPhone.phw -row 1 -column 0 -sticky e
		grid $nbIdent.fPhone.phw1 -row 1 -column 1 -sticky w
		grid $nbIdent.fPhone.phm -row 2 -column 0 -sticky e
		grid $nbIdent.fPhone.phm1 -row 2 -column 1 -sticky w
		grid $nbIdent.fPhone.php -row 3 -column 0 -sticky e
		grid $nbIdent.fPhone.php1 -row 3 -column 1 -sticky w
		grid columnconfigure $nbIdent.fPhone 1 -weight 1

		labelframe $nbIdent.fStats -text [trans others]
		label $nbIdent.fStats.lastlogin -text "[trans lastlogin]:"
		label $nbIdent.fStats.lastlogin1 -text [::abook::dateconvert "[::abook::getContactData $email last_login]"] -font splainf -fg blue 
		
		label $nbIdent.fStats.lastlogout -text "[trans lastlogout]:"
		label $nbIdent.fStats.lastlogout1 -text [::abook::dateconvert "[::abook::getContactData $email last_logout]"] -font splainf -fg blue 

		label $nbIdent.fStats.lastseen -text "[trans lastseen]:"
		if { [::abook::getVolatileData $email state] == "FLN" || [lsearch [::abook::getContactData $email lists] "FL"] == -1} {
			label $nbIdent.fStats.lastseen1 -text [::abook::dateconvert "[::abook::getContactData $email last_seen]"] -font splainf -fg blue
		} elseif { [::abook::getContactData $email last_seen] == "" } {		
			label $nbIdent.fStats.lastseen1 -text "" -font splainf -fg blue
		} else {
			label $nbIdent.fStats.lastseen1 -text [trans online] -font splainf -fg blue
		}
		
		label $nbIdent.fStats.lastmsgedme -text "[trans lastmsgedme]:"
		label $nbIdent.fStats.lastmsgedme1 -text [::abook::dateconvert "[::abook::getContactData $email last_msgedme]"] -font splainf -fg blue
		#Client-name of the user (from Gaim, dMSN, etc)
		label $nbIdent.fStats.clientname -text "[trans clientname]:"
		label $nbIdent.fStats.clientname1 -text "[::abook::getContactData $email clientname] ([::abook::getContactData $email client])" -font splainf -fg blue
		
		#Does the user record the conversation or not
		if { [::abook::getContactData $email chatlogging] eq "Y" } {
			set chatlogging [trans yes]
		} elseif { [::abook::getContactData $email chatlogging] eq "N" } {
			set chatlogging [trans no]
		} else {
			set chatlogging [trans unknown]
		}
		
		label $nbIdent.fStats.chatlogging -text "[trans logschats]:"
		label $nbIdent.fStats.chatlogging1 -text $chatlogging -font splainf -fg blue
		grid $nbIdent.fStats.lastlogin -row 0 -column 0 -sticky e
		grid $nbIdent.fStats.lastlogin1 -row 0 -column 1 -sticky w
		grid $nbIdent.fStats.lastlogout -row 1 -column 0 -sticky e
		grid $nbIdent.fStats.lastlogout1 -row 1 -column 1 -sticky w
		grid $nbIdent.fStats.lastmsgedme -row 2 -column 0 -sticky e
		grid $nbIdent.fStats.lastmsgedme1 -row 2 -column 1 -sticky w
		grid $nbIdent.fStats.lastseen -row 3 -column 0 -sticky e
		grid $nbIdent.fStats.lastseen1 -row 3 -column 1 -sticky w
		grid $nbIdent.fStats.clientname -row 4 -column 0 -sticky e
		grid $nbIdent.fStats.clientname1 -row 4 -column 1 -sticky w
		grid $nbIdent.fStats.chatlogging -row 5 -column 0 -sticky e
		grid $nbIdent.fStats.chatlogging1 -row 5 -column 1 -sticky w
		grid columnconfigure $nbIdent.fStats 1 -weight 1
		
		grid $nbIdent.fBasicInfo -row 0 -column 0 -sticky nwse -columnspan 2 -ipadx 4 -ipady 4
		grid $nbIdent.fPhone -row 1 -column 0 -sticky nwse -padx { 0 4 } -pady { 8 0 }
		grid $nbIdent.fStats -row 1 -column 1 -sticky nwse -padx { 4 0 } -pady { 8 0 }
		grid columnconfigure $nbIdent { 0 1 } -weight 1
		
		pack $sw -expand true -fill both
		
		##############
		#User settings page
		#############
		set nbSettings [$w.nb getframe usersettings]
		ScrolledWindow $nbSettings.sw
		set sw $nbSettings.sw
		ScrollableFrame $nbSettings.sw.sf -constrainedwidth 1
		$nbSettings.sw setwidget $nbSettings.sw.sf
		set nbSettings [$nbSettings.sw.sf getframe]
		
		labelframe $nbSettings.fNick -relief groove -text [trans nick]
		label $nbSettings.fNick.customnickl -text "[trans customnick]:"
		frame $nbSettings.fNick.customnick
		entry $nbSettings.fNick.customnick.ent -font splainf -bg white
		menubutton $nbSettings.fNick.customnick.help -font sboldf -text "<-" -menu $nbSettings.fNick.customnick.help.menu
		menu $nbSettings.fNick.customnick.help.menu -tearoff 0
		$nbSettings.fNick.customnick.help.menu add command -label [trans nick] -command "$nbSettings.fNick.customnick.ent insert insert \\\$nick"
		$nbSettings.fNick.customnick.help.menu add command -label [trans email] -command "$nbSettings.fNick.customnick.ent insert insert \\\$user_login"
		if { [::config::getKey protocol] >= 11 } {
			$nbSettings.fNick.customnick.help.menu add command -label [trans psm] -command "$nbSettings.fNick.customnick.ent insert insert \\\$psm"
		}
		$nbSettings.fNick.customnick.help.menu add separator
		$nbSettings.fNick.customnick.help.menu add command -label [trans delete] -command "$nbSettings.fNick.customnick.ent delete 0 end"
		$nbSettings.fNick.customnick.ent insert end [::abook::getContactData $email customnick]
		pack $nbSettings.fNick.customnick.ent -side left -expand true -fill x
		pack $nbSettings.fNick.customnick.help -side left
		label $nbSettings.fNick.customfnickl -text "[trans friendlyname]:"
		frame $nbSettings.fNick.customfnick
		entry $nbSettings.fNick.customfnick.ent -font splainf -bg white
		menubutton $nbSettings.fNick.customfnick.help -font sboldf -text "<-" -menu $nbSettings.fNick.customfnick.help.menu
		menu $nbSettings.fNick.customfnick.help.menu -tearoff 0
		$nbSettings.fNick.customfnick.help.menu add command -label [trans nick] -command "$nbSettings.fNick.customfnick.ent insert insert \\\$nick"
		$nbSettings.fNick.customfnick.help.menu add command -label [trans email] -command "$nbSettings.fNick.customfnick.ent insert insert \\\$user_login"
                if { [::config::getKey protocol] >= 11 } {
                        $nbSettings.fNick.customfnick.help.menu add command -label [trans psm] -command "$nbSettings.fNick.customfnick.ent insert insert \\\$psm"
                }
		$nbSettings.fNick.customfnick.help.menu add separator
		$nbSettings.fNick.customfnick.help.menu add command -label [trans delete] -command "$nbSettings.fNick.customfnick.ent delete 0 end"
		$nbSettings.fNick.customfnick.ent insert end [::abook::getContactData $email customfnick]
		pack $nbSettings.fNick.customfnick.ent -side left -expand true -fill x
		pack $nbSettings.fNick.customfnick.help -side left
	
		label $nbSettings.fNick.ycustomfnickl -text "[trans myfriendlyname]:"
		frame $nbSettings.fNick.ycustomfnick
		entry $nbSettings.fNick.ycustomfnick.ent -font splainf -bg white
		menubutton $nbSettings.fNick.ycustomfnick.help -font sboldf -text "<-" -menu $nbSettings.fNick.ycustomfnick.help.menu
		menu $nbSettings.fNick.ycustomfnick.help.menu -tearoff 0
		$nbSettings.fNick.ycustomfnick.help.menu add command -label [trans nick] -command "$nbSettings.fNick.ycustomfnick.ent insert insert \\\$nick"
		$nbSettings.fNick.ycustomfnick.help.menu add command -label [trans email] -command "$nbSettings.fNick.ycustomfnick.ent insert insert \\\$user_login"
                if { [::config::getKey protocol] >= 11 } {
                        $nbSettings.fNick.ycustomfnick.help.menu add command -label [trans psm] -command "$nbSettings.fNick.ycustomfnick.ent insert insert \\\$psm"
                }
		$nbSettings.fNick.ycustomfnick.help.menu add separator
		$nbSettings.fNick.ycustomfnick.help.menu add command -label [trans delete] -command "$nbSettings.fNick.ycustomfnick.ent delete 0 end"
		$nbSettings.fNick.ycustomfnick.ent insert end [::abook::getContactData $email cust_p4c_name]
		pack $nbSettings.fNick.ycustomfnick.ent -side left -expand true -fill x
		pack $nbSettings.fNick.ycustomfnick.help -side left
		
		# The custom color frame
		label $nbSettings.fNick.lColor -text "[trans customcolor]:"
		frame $nbSettings.fNick.fColor -relief flat
		set colorval_$email [::abook::getContactData $email customcolor] 
		set showcustomsmileys_$email [::abook::getContactData $email showcustomsmileys]
		set ignorecontact_$email [::abook::getContactData $email ignored]

		frame $nbSettings.fNick.fColor.col -width 40 -bd 0 -relief flat -highlightbackground black -highlightcolor black
		if { [set colorval_$email] != "" } {
			if { [string index [set colorval_$email] 0] == "#" } {
				set colorval_$email [string range [set colorval_$email] 1 end]
			}
			set colorval_$email "#[string repeat 0 [expr {6-[string length [set colorval_$email]]}]][set colorval_$email]"
			#If the color is white we can't see the contact on the list : we ignore the custom color
			$nbSettings.fNick.fColor.col configure -background [set colorval_${email}] -highlightthickness 1 
		} else {
			$nbSettings.fNick.fColor.col configure -background [$nbSettings.fNick.fColor cget -background] -highlightthickness 0
		}
		button $nbSettings.fNick.fColor.bset -text "[trans change]" -command "::abookGui::ChangeColor $email $nbSettings" 
		button $nbSettings.fNick.fColor.brem -text "[trans delete]" -command "::abookGui::RemoveCustomColor $email $nbSettings" 
		pack $nbSettings.fNick.fColor.col -side left -expand true -fill y -pady 5 -padx 8
		pack $nbSettings.fNick.fColor.bset -side left -padx 3 -pady 2
		pack $nbSettings.fNick.fColor.brem -side left -padx 3 -pady 2
		
		grid $nbSettings.fNick.customnickl -row 0 -column 0 -sticky e
		grid $nbSettings.fNick.customnick -row 0 -column 1 -sticky we
		grid $nbSettings.fNick.customfnickl -row 1 -column 0 -sticky e
		grid $nbSettings.fNick.customfnick -row 1 -column 1 -sticky we
		grid $nbSettings.fNick.ycustomfnickl -row 2 -column 0 -sticky e
		grid $nbSettings.fNick.ycustomfnick -row 2 -column 1 -sticky we
		grid $nbSettings.fNick.lColor -row 3 -column 0 -sticky e
		grid $nbSettings.fNick.fColor -row 3 -column 1 -sticky w
		grid columnconfigure $nbSettings.fNick 1 -weight 1
		
		labelframe $nbSettings.fChat -relief groove -text [trans chat]
		checkbutton $nbSettings.fChat.showcustomsmileys -variable showcustomsmileys_$email -text "[trans custshowcustomsmileys]" -anchor w
		checkbutton $nbSettings.fChat.ignoreuser -variable ignorecontact_$email -text "[trans ignorecontact]" -anchor w
		pack $nbSettings.fChat.showcustomsmileys -side top -fill x
		pack $nbSettings.fChat.ignoreuser -side top -fill x
		
		labelframe $nbSettings.fGroup -relief groove -text [trans groups]
		::groups::Groupmanager $email $nbSettings.fGroup

		labelframe $nbSettings.fNotify -relief groove -text [trans notifywin]
		label $nbSettings.fNotify.default -font sboldf -text "*" -justify center
		label $nbSettings.fNotify.yes -font sboldf -text [trans yes] -justify center
		label $nbSettings.fNotify.no -font sboldf -text [trans no] -justify center
		
		#Set default values
		set ::notifyonline($email) [::abook::getContactData $email notifyonline ""]
		set ::notifyoffline($email) [::abook::getContactData $email notifyoffline ""]
		set ::notifystatus($email) [::abook::getContactData $email notifystatus ""]
		set ::notifymsg($email) [::abook::getContactData $email notifymsg ""]
		
		#Add the checkboxes
		AddOption $nbSettings.fNotify notifyonline notifyonline($email) [trans custnotifyonline] 1
		AddOption $nbSettings.fNotify notifyoffline notifyoffline($email) [trans custnotifyoffline] 2
		AddOption $nbSettings.fNotify notifystatus notifystatus($email) [trans custnotifystatus] 3
		AddOption $nbSettings.fNotify notifymsg notifymsg($email) [trans custnotifymsg] 4
		
		grid $nbSettings.fNotify.default -row 0 -column 0 -sticky we -padx 5
		grid $nbSettings.fNotify.yes -row 0 -column 1 -sticky we -padx 5
		grid $nbSettings.fNotify.no -row 0 -column 2 -sticky we -padx 5
		grid columnconfigure $nbSettings.fNotify 3 -weight 1
		
		grid $nbSettings.fNick -row 0 -column 0 -sticky nwse -columnspan 2 -pady { 0 4 }
		grid $nbSettings.fChat -row 1 -column 0 -sticky nwse -padx { 0 4 } -pady 4
		grid $nbSettings.fGroup -row 1 -column 1 -sticky nwse -padx { 4 0 } -pady 4
		grid $nbSettings.fNotify -row 2 -column 0 -sticky nwse -columnspan 2 -pady { 4 0 }
		grid columnconfigure $nbSettings { 0 1 } -weight 1
		
		pack $sw -expand true -fill both

		##############
		#Alarms frame
		##############
		set nbAlarm [$w.nb getframe alarms]
		ScrolledWindow $nbAlarm.sw
		pack $nbAlarm.sw -expand true -fill both
		ScrollableFrame $nbAlarm.sw.sf
		$nbAlarm.sw setwidget $nbAlarm.sw.sf

		set nbAlarm [$nbAlarm.sw.sf getframe]
		::alarms::configDialog $email $nbAlarm

		##############
		#UserDPs page
		##############
		set nbUserDPs [$w.nb getframe userDPs]
		# User's current display picture
		label $nbUserDPs.titlepic1 -text "[trans curdisplaypic]" -font bboldunderf
		label $nbUserDPs.displaypic -image [::skin::getDisplayPicture $email]
		# Other display pictures of user
		label $nbUserDPs.titlepic2 -text "[trans otherdisplaypic]" \
			-font bboldunderf

#		ScrolledWindow $nbUserDPs.otherpics
#		ScrollableFrame $nbUserDPs.otherpics.sf
#		set mainFrame [$nbUserDPs.otherpics.sf getframe]
#		$nbUserDPs.otherpics setwidget $nbUserDPs.otherpics.sf

		pack $nbUserDPs.titlepic1 -anchor w -padx 5 -pady 5
		pack $nbUserDPs.displaypic -anchor w -padx 7 -pady 5
		pack $nbUserDPs.titlepic2 -anchor w -padx 5 -pady 5
#		pack $nbUserDPs.otherpics -expand true -fill both

		##########
		#Common
		##########
		$w.nb compute_size
		[$w.nb getframe userdata].sw.sf compute_size
		[$w.nb getframe usersettings].sw.sf compute_size
		[$w.nb getframe alarms].sw.sf compute_size
		$w.nb compute_size
		$w.nb raise userdata
		
		frame $w.buttons
		
		button $w.buttons.ok -text [trans accept] -command [list ::abookGui::PropOk $email $w]
		button $w.buttons.cancel -text [trans cancel] -command [list ::abookGui::PropCancel $email $w]
		
		pack $w.buttons.ok $w.buttons.cancel -side right -padx 5 -pady 3
		
		pack $w.buttons -fill x -side bottom
		pack $w.nb -expand true -fill both -side bottom -padx 3 -pady 3
		#pack $w.nb
		
		#Ask to save or not to save when we close the user properties window on Mac OS X
		#Request from users with 800X600 screen (they can't see accept/cancel button)
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			wm protocol $w WM_DELETE_WINDOW "[list ::abookGui::closeProperties $email $w]"
			bind $w <<Escape>> "[list ::abookGui::closeProperties $email $w]"
		} else {
			bind $w <<Escape>> "[list ::abookGui::PropCancel $email $w]"
		}

		bind $w <Destroy> [list ::abookGui::PropDestroyed $email $w %W]
		
		moveinscreen $w 30
	}
	
	proc showCustomNickScreen { email } {
		set w ".user_[::md5::md5 $email]_cnick"
		if { [winfo exists $w] } {
			raise $w
			return
		}
		toplevel $w
		wm title $w "[trans customnick]: $email"
	
		label $w.customnickl -text "[trans customnick]:"
		frame $w.customnick
		entry $w.customnick.ent -font splainf -bg white
		menubutton $w.customnick.help -font sboldf -text "<-" -menu $w.customnick.help.menu
		menu $w.customnick.help.menu -tearoff 0
		$w.customnick.help.menu add command -label [trans nick] -command "$w.customnick.ent insert insert \\\$nick"
		$w.customnick.help.menu add command -label [trans email] -command "$w.customnick.ent insert insert \\\$user_login"
		$w.customnick.help.menu add separator
		$w.customnick.help.menu add command -label [trans delete] -command "$w.customnick.ent delete 0 end"
		$w.customnick.ent insert end [::abook::getContactData $email customnick]
		pack $w.customnick.ent -side left -expand true -fill x
		pack $w.customnick.help -side left
		label $w.customfnickl -text "[trans friendlyname]:"
		frame $w.customfnick
		entry $w.customfnick.ent -font splainf -bg white
		menubutton $w.customfnick.help -font sboldf -text "<-" -menu $w.customfnick.help.menu
		menu $w.customfnick.help.menu -tearoff 0
		$w.customfnick.help.menu add command -label [trans nick] -command "$w.customfnick.ent insert insert \\\$nick"
		$w.customfnick.help.menu add command -label [trans email] -command "$w.customfnick.ent insert insert \\\$user_login"
		$w.customfnick.help.menu add separator
		$w.customfnick.help.menu add command -label [trans delete] -command "$w.customfnick.ent delete 0 end"
		$w.customfnick.ent insert end [::abook::getContactData $email customfnick]
		pack $w.customfnick.ent -side left -expand true -fill x
		pack $w.customfnick.help -side left
		
		grid $w.customnickl -row 0 -column 0 -sticky ne
		grid $w.customnick -row 0 -column 1 -sticky we -padx 6
		grid $w.customfnickl -row 1 -column 0 -sticky ne
		grid $w.customfnick -row 1 -column 1 -sticky we -padx 6
		
		grid columnconfigure $w 1 -weight 1
	}
	
	#Ask the user if he wants to save or not the user properties window
	proc closeProperties {email w} {
		#Ask the user yes/no if he wants to save, parent=window to attach the question, title= totally useless on Mac
		set answer [::amsn::messageBox "[trans save] ?" yesno question "[trans save] ?"]
		#When the user answer yes, save preferences and close the window
		if {$answer == "yes"} {
			::abookGui::PropOk $email $w
		#When the user do not answer yes (no), then Restore previous preferences and close the window
		} else {
			::abookGui::PropCancel $email $w
		}
	}
	
	proc PropDestroyed { email w win } {
		global colorval_$email showcustomsmileys_$email ignorecontact_$email

		if { $w == $win } {
			#Clean temporal variables
			unset ::notifyonline($email)
			unset ::notifyoffline($email)
			unset ::notifystatus($email)
			unset ::notifymsg($email)
			catch {unset colorval_$email}
			catch {unset showcustomsmileys_$email}
			catch {unset ignorecontact_$email}
		}
	}
	
	proc AddOption { nbNotify name var text row} {
		radiobutton $nbNotify.${name}_default -value "" -variable $var
		radiobutton $nbNotify.${name}_yes -value 1 -variable $var
		radiobutton $nbNotify.${name}_no -value 0 -variable $var
		label $nbNotify.${name} -font splainf -text $text -justify left
		
		grid $nbNotify.${name}_default -row $row -column 0 -sticky we
		grid $nbNotify.${name}_yes -row $row -column 1 -sticky we
		grid $nbNotify.${name}_no -row $row -column 2 -sticky we
		
		grid $nbNotify.${name} -row $row -column 3 -sticky w
	}

	
	proc ChangeColor { email w } {
		global colorval_$email
		set color  [SelectColor $w.customcolor.dialog  -type dialog  -title "[trans customcolor]" -parent $w]
		if { $color == "" } { return }

		set colorval_$email $color
		$w.fNick.fColor.col configure -background [set colorval_${email}] -highlightthickness 1 
	}
	
	proc RemoveCustomColor { email w } {	
	   	global colorval_$email	
		set colorval_$email ""
		$w.fNick.fColor.col configure -background [$w.customcolorf cget -background] -highlightthickness 0
	}

	proc SetGlobalNick { } {
		
		if {[winfo exists .globalnick]} {
			return
		}
	
		toplevel .globalnick
		wm title .globalnick "[trans globalnicktitle]"
		frame .globalnick.frm -bd 1 
		label .globalnick.frm.lbl -text "[trans globalnick]" -font sboldf -justify left -wraplength 400
		entry .globalnick.frm.nick -width 50 -bg #FFFFFF -font splainf
		menubutton .globalnick.frm.help -font splainf -text "<-" -menu .globalnick.frm.help.menu
		menu .globalnick.frm.help.menu -tearoff 0
		.globalnick.frm.help.menu add command -label [trans nick] -command ".globalnick.frm.nick insert insert \\\$nick"
		.globalnick.frm.help.menu add command -label [trans email] -command ".globalnick.frm.nick insert insert \\\$user_login"
		.globalnick.frm.help.menu add command -label [trans psm] -command ".globalnick.frm.nick insert insert \\\$psm"
		.globalnick.frm.help.menu add command -label [trans customnick] -command ".globalnick.frm.nick insert insert \\\$customnick"
		.globalnick.frm.help.menu add separator
		.globalnick.frm.help.menu add command -label [trans delete] -command ".globalnick.frm.nick delete 0 end"

		pack .globalnick.frm.lbl -pady 2 -side top
		pack .globalnick.frm.nick -pady 2 -side left
		pack .globalnick.frm.help -side left
		bind .globalnick.frm.nick <Return> {
			::config::setKey globalnick "[.globalnick.frm.nick get]";
			::MSN::contactListChanged;
			cmsn_draw_online 0 2;
			destroy .globalnick
		}
		frame .globalnick.btn 
		button .globalnick.btn.ok -text "[trans ok]"  \
			-command {
			::config::setKey globalnick "[.globalnick.frm.nick get]";
			::MSN::contactListChanged;
			cmsn_draw_online 0 2;
			destroy .globalnick
			}
		button .globalnick.btn.cancel -text "[trans cancel]"  \
			-command "destroy .globalnick"
		bind .globalnick <<Escape>> "destroy .globalnick"
		pack .globalnick.btn.ok .globalnick.btn.cancel -side right -padx 5
		pack .globalnick.frm -side top -pady 3 -padx 5
		pack .globalnick.btn  -side top -anchor e -pady 3

		.globalnick.frm.nick insert end [::config::getKey globalnick]
	}

	proc PropOk { email w } {
		global colorval_$email showcustomsmileys_$email ignorecontact_$email
		
		if {[::alarms::SaveAlarm $email] != 0 } {
			return
		}
	
		set nbSettings [$w.nb getframe usersettings]
		set nbSettings [$nbSettings.sw.sf getframe]

		# Store custom display information options
		::abook::setAtomicContactData $email [list customnick customfnick cust_p4c_name customcolor showcustomsmileys ignored] \
			[list [$nbSettings.fNick.customnick.ent get] [$nbSettings.fNick.customfnick.ent get] [$nbSettings.fNick.ycustomfnick.ent get] [set colorval_$email] [set showcustomsmileys_$email] [set ignorecontact_$email]]

		# Store groups
		::groups::GroupmanagerOk $email
		
		# Store custom notification options
		::abook::setAtomicContactData $email [list notifyonline notifyoffline notifystatus notifymsg] \
			[list [set ::notifyonline($email)] [set ::notifyoffline($email)] [set ::notifystatus($email)] [set ::notifymsg($email)]]
		
		destroy $w
		::MSN::contactListChanged
		cmsn_draw_online
		::abook::saveToDisk
	}
	
	proc PropCancel { email w } {
		::groups::GroupmanagerClose $email
		destroy $w
	}

}
