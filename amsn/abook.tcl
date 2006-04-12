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
		if { [::config::getKey protocol] != 11 } { return }
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
			set ip ""
			catch {set ip [lindex [fconfigure $sk -sockname] 0]}
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

		#We store the array as a plain list, as we can't have an array of arrays
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
			if { [::config::getKey protocol] == 11 && $psm != "" } {
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
			if { [::config::getKey protocol] == 11 } {
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
   
	proc userDPs_popup_menu { X Y filename widget } {
	  # Create pop-up menu if it doesn't yet exists
	  set the_menu .userDPs_menu
	  catch {destroy $the_menu}
	  menu $the_menu -tearoff 0 -type normal
	  $the_menu add command \
		-label "[trans copytoclipboard [string tolower [trans filename]]]" \
		-command "clipboard clear ; clipboard append $filename"
	  $the_menu add command -label "[trans delete]" \
		-command "pictureDeleteFile $filename $widget"
	  $the_menu add command -label "Set as custom display picture for this user" \
		-command [list ::amsn::messageBox "Sorry, not yet implemented" ok error [trans failed]]
	  $the_menu add command -label "Set as my display picture" \
		-command [list set_displaypic $filename]
		#-command [list ::abookGui::set_userDP_as_mine $filename]
	  tk_popup $the_menu $X $Y
	}

	proc userDPs_raise_cmd { nb email } { 

		  set nbIdent [$nb getframe userDPs]
		  set mainFrame [$nbIdent.otherpics.sf getframe]

		  #don't try to redraw the dps if they already are drawed (changing tab)
		  if {![winfo exists $mainFrame.0]} {
#			  ::amsn::notifyAdd [trans loadotherdisplaypic $email] ""


			  global HOME
			  set cachefiles [glob -nocomplain -directory [file join $HOME displaypic cache] *.dat]
			  proc grep { fd re } {
				  set result 0
				  while {[gets $fd s] >= 0} {
					  if [regexp $re $s] { set result 1 }
				  }
				  return $result
			  }

			  set i 0
			  set dps_per_row 4
			  set pic_in_use [::abook::getContactData $email displaypicfile ""]
			  foreach f $cachefiles {
				if {[string first $pic_in_use $f] == -1} {
				  set fd [open $f]
				  if { [grep $fd $email] == 1 } {
					  if { [catch {set img [image create photo userDP_${email}_$i -file [filenoext $f].png -format cximage]}] } { continue }
					  button $mainFrame.$i -image $img
					  bind $mainFrame.$i <Destroy> "catch { image delete userDP_${email}_$i }"
					  bind $mainFrame.$i <ButtonPress-1> \
						[list ::abookGui::userDPs_popup_menu %X %Y [filenoext $f].png $mainFrame.$i]
					  grid $mainFrame.$i \
						  -row [expr {$i / $dps_per_row}] -column [expr {$i % $dps_per_row}] \
						  -pady 5 -padx 5
					  incr i
				  }
				  close $fd
				}

			  }
			  if {$i == 0} {
			  	if {![winfo exists $mainFrame.nodps]} {label $mainFrame.nodps -text "\tNo displaypictures in cache for this user" }
			  	pack $mainFrame.nodps
			 }
		}
	}

	proc showUserProperties { email } {
		global colorval_$email
		set w ".user_[::md5::md5 $email]_prop"
		if { [winfo exists $w] } {
			raise $w
			return
		}
		toplevel $w
		wm title $w [trans userproperties $email]
		
		NoteBook $w.nb
		$w.nb insert 0 userdata -text [trans userdata]
		$w.nb insert 1 notify -text [trans notifywin]
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
		
		label $nbIdent.title1 -text [trans identity] -font bboldunderf
		
		label $nbIdent.e -text "[trans email]:" -wraplength 300 
		label $nbIdent.e1 -text $email -font splainf -fg blue 
		
		label $nbIdent.h -text "[trans nick]:"
		label $nbIdent.h1 -text [::abook::getNick $email] -font splainf -fg blue -wraplength 300 -justify left
		
		label $nbIdent.customnickl -text "[trans customnick]:"
		frame $nbIdent.customnick
		entry $nbIdent.customnick.ent -font splainf -bg white
		menubutton $nbIdent.customnick.help -font sboldf -text "<-" -menu $nbIdent.customnick.help.menu
		menu $nbIdent.customnick.help.menu -tearoff 0
		$nbIdent.customnick.help.menu add command -label [trans nick] -command "$nbIdent.customnick.ent insert insert \\\$nick"
		$nbIdent.customnick.help.menu add command -label [trans email] -command "$nbIdent.customnick.ent insert insert \\\$user_login"
		if { [::config::getKey protocol] == 11 } {
			$nbIdent.customnick.help.menu add command -label [trans psm] -command "$nbIdent.customnick.ent insert insert \\\$psm"
		}
		$nbIdent.customnick.help.menu add separator
		$nbIdent.customnick.help.menu add command -label [trans delete] -command "$nbIdent.customnick.ent delete 0 end"
		$nbIdent.customnick.ent insert end [::abook::getContactData $email customnick]
		pack $nbIdent.customnick.ent -side left -expand true -fill x
		pack $nbIdent.customnick.help -side left
		label $nbIdent.customfnickl -text "[trans friendlyname]:"
		frame $nbIdent.customfnick
		entry $nbIdent.customfnick.ent -font splainf -bg white
		menubutton $nbIdent.customfnick.help -font sboldf -text "<-" -menu $nbIdent.customfnick.help.menu
		menu $nbIdent.customfnick.help.menu -tearoff 0
		$nbIdent.customfnick.help.menu add command -label [trans nick] -command "$nbIdent.customfnick.ent insert insert \\\$nick"
		$nbIdent.customfnick.help.menu add command -label [trans email] -command "$nbIdent.customfnick.ent insert insert \\\$user_login"
                if { [::config::getKey protocol] == 11 } {
                        $nbIdent.customfnick.help.menu add command -label [trans psm] -command "$nbIdent.customfnick.ent insert insert \\\$psm"
                }
		$nbIdent.customfnick.help.menu add separator
		$nbIdent.customfnick.help.menu add command -label [trans delete] -command "$nbIdent.customfnick.ent delete 0 end"
		$nbIdent.customfnick.ent insert end [::abook::getContactData $email customfnick]
		pack $nbIdent.customfnick.ent -side left -expand true -fill x
		pack $nbIdent.customfnick.help -side left
	
		label $nbIdent.ycustomfnickl -text "[trans myfriendlyname]:"
		frame $nbIdent.ycustomfnick
		entry $nbIdent.ycustomfnick.ent -font splainf -bg white
		menubutton $nbIdent.ycustomfnick.help -font sboldf -text "<-" -menu $nbIdent.ycustomfnick.help.menu
		menu $nbIdent.ycustomfnick.help.menu -tearoff 0
		$nbIdent.ycustomfnick.help.menu add command -label [trans nick] -command "$nbIdent.ycustomfnick.ent insert insert \\\$nick"
		$nbIdent.ycustomfnick.help.menu add command -label [trans email] -command "$nbIdent.ycustomfnick.ent insert insert \\\$user_login"
                if { [::config::getKey protocol] == 11 } {
                        $nbIdent.ycustomfnick.help.menu add command -label [trans psm] -command "$nbIdent.ycustomfnick.ent insert insert \\\$psm"
                }
		$nbIdent.ycustomfnick.help.menu add separator
		$nbIdent.ycustomfnick.help.menu add command -label [trans delete] -command "$nbIdent.ycustomfnick.ent delete 0 end"
		$nbIdent.ycustomfnick.ent insert end [::abook::getContactData $email cust_p4c_name]
		pack $nbIdent.ycustomfnick.ent -side left -expand true -fill x
		pack $nbIdent.ycustomfnick.help -side left
		# The custom color frame
		label $nbIdent.customcolor -text "[trans customcolor]:"
		frame $nbIdent.customcolorf -relief groove -borderwidth 2
		set colorval_$email [::abook::getContactData $email customcolor] 

		#frame $nbIdent.customcolorf.col -width 40 -bd 0 -relief flat\
		#	-highlightthickness 1 -takefocus 0 \
		#	-highlightbackground black \
		#	-highlightcolor black
		frame $nbIdent.customcolorf.col -width 40 -bd 0 -relief flat -highlightbackground black -highlightcolor black
		if { [set colorval_$email] != "" } {
			if { [string index [set colorval_$email] 0] == "#" } {
				set colorval_$email [string range [set colorval_$email] 1 end]
			}
			set colorval_$email "#[string repeat 0 [expr 6-[string length [set colorval_$email]]]][set colorval_$email]"
			#If the color is white we can't see the contact on the list : we ignore the custom color
			$nbIdent.customcolorf.col configure -background [set colorval_${email}] -highlightthickness 1 
		} else {
			$nbIdent.customcolorf.col configure -background [$nbIdent.customcolorf cget -background] -highlightthickness 0
		}
		button $nbIdent.customcolorf.bset -text "[trans change]" -command "::abookGui::ChangeColor $email $nbIdent" 
		button $nbIdent.customcolorf.brem -text "[trans delete]" -command "::abookGui::RemoveCustomColor $email $nbIdent" 
		pack $nbIdent.customcolorf.col -side left -expand true -fill y -pady 5 -padx 8
		pack $nbIdent.customcolorf.bset -side left -padx 3 -pady 2
		pack $nbIdent.customcolorf.brem -side left -padx 3 -pady 2
		
		label $nbIdent.g -text "[trans group]" -font bboldunderf
		label $nbIdent.g1 -text "[::abook::getGroupsname $email]" -font splainf -fg blue -justify left -wraplength 300
		button $nbIdent.g2 -text [trans change] -command "::groups::Groupmanager $email $nbIdent"
		
		label $nbIdent.titlephones -text [trans phones] -font bboldunderf
		
		set nbPhone $nbIdent
		label $nbPhone.phh -text "[trans home]:" 
		label $nbPhone.phh1 -font splainf -text [::abook::getVolatileData $email phh] -fg blue \
		-justify left -wraplength 300 
		label $nbPhone.phw -text "[trans work]:"
		label $nbPhone.phw1 -font splainf -text [::abook::getVolatileData $email phw] -fg blue \
			-justify left -wraplength 300 
		label $nbPhone.phm -text "[trans mobile]:" 
		label $nbPhone.phm1 -font splainf -text [::abook::getVolatileData $email phm] -fg blue \
		-justify left -wraplength 300 
		label $nbPhone.php -text "[trans pager]:" 
		label $nbPhone.php1 -font splainf -text [::abook::getVolatileData $email mob] -fg blue \
		-justify left -wraplength 300 
		label $nbIdent.titleothers -text [trans others] -font bboldunderf 
		
		label $nbIdent.lastlogin -text "[trans lastlogin]:"
		label $nbIdent.lastlogin1 -text [::abook::dateconvert "[::abook::getContactData $email last_login]"] -font splainf -fg blue 
		
		label $nbIdent.lastlogout -text "[trans lastlogout]:"
		label $nbIdent.lastlogout1 -text [::abook::dateconvert "[::abook::getContactData $email last_logout]"] -font splainf -fg blue 

		label $nbIdent.lastseen -text "[trans lastseen]:"
		if { [::abook::getVolatileData $email state] == "FLN" || [lsearch [::abook::getContactData $email lists] "FL"] == -1} {
			label $nbIdent.lastseen1 -text [::abook::dateconvert "[::abook::getContactData $email last_seen]"] -font splainf -fg blue
		} elseif { [::abook::getContactData $email last_seen] == "" } {		
			label $nbIdent.lastseen1 -text "" -font splainf -fg blue
		} else {
			label $nbIdent.lastseen1 -text [trans online] -font splainf -fg blue
		}
		
		label $nbIdent.lastmsgedme -text "[trans lastmsgedme]:"
		label $nbIdent.lastmsgedme1 -text [::abook::dateconvert "[::abook::getContactData $email last_msgedme]"] -font splainf -fg blue
		#Client-name of the user (from Gaim, dMSN, etc)
		label $nbIdent.clientname -text "[trans clientname]:"
		label $nbIdent.clientname1 -text [::abook::getContactData $email clientname] -font splainf -fg blue
		label $nbIdent.clientid -text "([::abook::getContactData $email client])" -font splainf -fg blue
		#Does the user record the conversation or not
		label $nbIdent.chatlogging -text "[trans loging]:"
		label $nbIdent.chatlogging1 -text [::abook::getContactData $email chatlogging] -font splainf -fg blue

		label $nbIdent.titlepic -text "[trans displaypic]" -font bboldunderf
		label $nbIdent.displaypic -image [::skin::getDisplayPicture $email] -highlightthickness 2 -highlightbackground black -borderwidth 0
				
		grid $nbIdent.title1 -row 0 -column 0 -pady 5 -padx 5 -columnspan 3 -sticky w 
		grid $nbIdent.e -row 1 -column 0 -sticky e
		grid $nbIdent.e1 -row 1 -column 1 -sticky w -columnspan 3
		grid $nbIdent.h -row 2 -column 0 -sticky e
		grid $nbIdent.h1 -row 2 -column 1 -sticky w -columnspan 3
		grid $nbIdent.customnickl -row 3 -column 0 -sticky en
		grid $nbIdent.customnick -row 3 -column 1 -sticky wne -columnspan 3
		grid $nbIdent.customfnickl -row 4 -column 0 -sticky en
		grid $nbIdent.customfnick -row 4 -column 1 -sticky wne -columnspan 3
		grid $nbIdent.ycustomfnickl -row 5 -column 0 -sticky en
		grid $nbIdent.ycustomfnick -row 5 -column 1 -sticky wne -columnspan 3
		grid $nbIdent.customcolor -row 6 -column 0 -sticky e
		grid $nbIdent.customcolorf -row 6 -column 1 -sticky w -columnspan 3
	
		grid $nbIdent.g -row 7 -column 0 -pady 5 -padx 5 -sticky w
		grid $nbIdent.g1 -row 8 -column 0 -sticky e
		grid $nbIdent.g2 -row 8 -column 1 -sticky w
		
		grid $nbIdent.titlephones -row 9 -column 0 -pady 5 -padx 5 -columnspan 2 -sticky w 
		grid $nbPhone.phh -row 10 -column 0 -sticky e
		grid $nbPhone.phh1 -row 10 -column 1 -sticky w
		grid $nbPhone.phw -row 11 -column 0 -sticky e
		grid $nbPhone.phw1 -row 11 -column 1 -sticky w
		grid $nbPhone.phm -row 12 -column 0 -sticky e
		grid $nbPhone.phm1 -row 12 -column 1 -sticky w
		grid $nbPhone.php -row 13 -column 0 -sticky e
		grid $nbPhone.php1 -row 13 -column 1 -sticky w
		
		grid $nbIdent.titleothers -row 18 -column 0 -pady 5 -padx 5 -columnspan 2 -sticky w 
		grid $nbPhone.lastlogin -row 19 -column 0 -sticky e
		grid $nbPhone.lastlogin1 -row 19 -column 1 -sticky w
		grid $nbPhone.lastlogout -row 19 -column 2 -sticky e
		grid $nbPhone.lastlogout1 -row 19 -column 3 -sticky w
		grid $nbPhone.lastmsgedme -row 21 -column 0 -sticky e
		grid $nbPhone.lastmsgedme1 -row 21 -column 1 -sticky w
		grid $nbPhone.lastseen -row 21 -column 2 -sticky e
		grid $nbPhone.lastseen1 -row 21 -column 3 -sticky w
		grid $nbPhone.clientname -row 22 -column 0 -sticky e
		grid $nbPhone.clientname1 -row 22 -column 1 -sticky w
		grid $nbPhone.clientid -row 22 -column 1 -sticky e
		grid $nbPhone.chatlogging -row 22 -column 2 -sticky e
		grid $nbPhone.chatlogging1 -row 22 -column 3 -sticky w
		
		grid $nbPhone.titlepic -row 28 -column 0 -sticky w -columnspan 2 -pady 5 -padx 5
		grid $nbPhone.displaypic -row 29 -column 0 -sticky w -columnspan 2 -padx 8
		#grid columnconfigure $nbIdent.fothers 1 -weight 1
		
		grid columnconfigure $nbIdent 1 -weight 1
		
		pack $sw -expand true -fill both
		
		##############
		#Notify page
		#############
		set nbIdent [$w.nb getframe notify]
		ScrolledWindow $nbIdent.sw
		pack $nbIdent.sw -expand true -fill both
		ScrollableFrame $nbIdent.sw.sf
		$nbIdent.sw setwidget $nbIdent.sw.sf
		set nbIdent [$nbIdent.sw.sf getframe]
		
		label $nbIdent.default -font sboldf -text "*" -justify center
		label $nbIdent.yes -font sboldf -text [trans yes] -justify center
		label $nbIdent.no -font sboldf -text [trans no] -justify center
		
		#Set default values
		set ::notifyonline($email) [::abook::getContactData $email notifyonline ""]
		set ::notifyoffline($email) [::abook::getContactData $email notifyoffline ""]
		set ::notifystatus($email) [::abook::getContactData $email notifystatus ""]
		set ::notifymsg($email) [::abook::getContactData $email notifymsg ""]
		
		#Add the checkboxes
		AddOption $nbIdent notifyonline notifyonline($email) [trans custnotifyonline] 1
		AddOption $nbIdent notifyoffline notifyoffline($email) [trans custnotifyoffline] 2
		AddOption $nbIdent notifystatus notifystatus($email) [trans custnotifystatus] 3
		AddOption $nbIdent notifymsg notifymsg($email) [trans custnotifymsg] 4
		
		grid $nbIdent.default -row 0 -column 0 -sticky we -padx 5
		grid $nbIdent.yes -row 0 -column 1 -sticky we -padx 5
		grid $nbIdent.no -row 0 -column 2 -sticky we -padx 5
		
			
		##############
		#Alarms frame
		##############
		
		set nbIdent [$w.nb getframe alarms]
		
		ScrolledWindow $nbIdent.sw
		
		pack $nbIdent.sw -expand true -fill both
		
		ScrollableFrame $nbIdent.sw.sf
	
		$nbIdent.sw setwidget $nbIdent.sw.sf
		
		set nbIdent [$nbIdent.sw.sf getframe]
		
		::alarms::configDialog $email $nbIdent
		##############
		#UserDPs page
		##############
		set nbIdent [$w.nb getframe userDPs]
		# User's current display picture
		label $nbIdent.titlepic1 -text "[trans curdisplaypic]" -font bboldunderf
		label $nbIdent.displaypic -image [::skin::getDisplayPicture $email]
		# Other display pictures of user
		label $nbIdent.titlepic2 -text "[trans otherdisplaypic]" \
			-font bboldunderf
		ScrolledWindow $nbIdent.otherpics
		ScrollableFrame $nbIdent.otherpics.sf
		set mainFrame [$nbIdent.otherpics.sf getframe]
		$nbIdent.otherpics setwidget $nbIdent.otherpics.sf

		pack $nbIdent.titlepic1 -anchor w -padx 5 -pady 5
		pack $nbIdent.displaypic -anchor w -padx 7 -pady 5
		pack $nbIdent.titlepic2 -anchor w -padx 5 -pady 5
		pack $nbIdent.otherpics -expand true -fill both

		##########
		#Common
		##########
		$w.nb compute_size
		[$w.nb getframe userdata].sw.sf compute_size
		[$w.nb getframe alarms].sw.sf compute_size
		$w.nb compute_size
		$w.nb raise userdata
		
		frame $w.buttons
		
		button $w.buttons.ok -text [trans accept] -command [list ::abookGui::PropOk $email $w]
		button $w.buttons.cancel -text [trans cancel] -command [list destroy $w]
		
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
			bind $w <<Escape>> "destroy $w"
		}

		bind $w <Destroy> [list ::abookGui::PropDestroyed $email $w %W; unset colorval_$email]
		
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
			destroy $w
		}
	}
	
	proc PropDestroyed { email w win } {
		if { $w == $win } {
			#Clean temporal variables
			unset ::notifyonline($email)
			unset ::notifyoffline($email)
			unset ::notifystatus($email)
			unset ::notifymsg($email)
		}
	}
	
	proc AddOption { nbIdent name var text row} {
		radiobutton $nbIdent.${name}_default -value "" -variable $var
		radiobutton $nbIdent.${name}_yes -value 1 -variable $var
		radiobutton $nbIdent.${name}_no -value 0 -variable $var
		label $nbIdent.${name} -font splainf -text $text -justify left
		
		grid $nbIdent.${name}_default -row $row -column 0 -sticky we
		grid $nbIdent.${name}_yes -row $row -column 1 -sticky we
		grid $nbIdent.${name}_no -row $row -column 2 -sticky we
		
		grid $nbIdent.${name} -row $row -column 3 -sticky w
	}

	
	proc ChangeColor { email w } {
		global colorval_$email
		set color  [SelectColor $w.customcolor.dialog  -type dialog  -title "[trans customcolor]" -parent $w]
		if { $color == "" } { return }

		set colorval_$email $color
		$w.customcolorf.col configure -background [set colorval_${email}] -highlightthickness 1 
		
	}
	
	proc RemoveCustomColor { email w } {	
	   	global colorval_$email	
		set colorval_$email ""
		$w.customcolorf.col configure -background [$w.customcolorf cget -background] -highlightthickness 0
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
		global colorval_$email
		
		if {[::alarms::SaveAlarm $email] != 0 } {
			return
		}
	
		set nbIdent [$w.nb getframe userdata]
		set nbIdent [$nbIdent.sw.sf getframe]

		# Store custom display information options
		::abook::setAtomicContactData $email [list customnick customfnick cust_p4c_name customcolor] \
			[list [$nbIdent.customnick.ent get] [$nbIdent.customfnick.ent get] [$nbIdent.ycustomfnick.ent get] [set colorval_$email]]

		# Store custom notification options
		::abook::setAtomicContactData $email [list notifyonline notifyoffline notifystatus notifymsg] \
			[list [set ::notifyonline($email)] [set ::notifyoffline($email)] [set ::notifystatus($email)] [set ::notifymsg($email)]]
		
		destroy $w
		unset colorval_$email
		::MSN::contactListChanged
		cmsn_draw_online
		::abook::saveToDisk
	}

}
