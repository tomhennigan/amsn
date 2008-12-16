#	User Administration (Address Book data)
#	by: Alvaro Jose Iradier Muro
#	D�imo Emilio Grimaldo Tu�n
#=======================================================================

::Version::setSubversionId {$Id$}

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
		variable VisualData [list nick customnick customfnick cust_p4c_name customcolor customdp]

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
				if { $value eq "Y" } {
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

    		array set demographics [array get data]
		set demographics(valid) Y
		after 0 {::abook::getIPConfig}
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
			array set d [array get demographics]
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
		if { [getDemographicField localip] eq ""  && [getDemographicField clientip] eq "" } {
			#Not connected
			set demographics(conntype) ""
			return
		} else {
			set demographics(conntype) [getConnectionType [getDemographicField localip] [getDemographicField clientip]]
		}
		if { $demographics(conntype) eq "Direct-Connect" || $demographics(conntype) eq "Firewall" } {
			set demographics(netid) 0
			set demographics(upnpnat) "false"
		} else {
			set demographics(netid) [GetNetID [getDemographicField clientip]]
			if { [getFirewalled [::config::getKey initialftport]] eq "Firewall" } {
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

		if { $sk ne "" } {
			foreach ip [fconfigure $sk -sockname] {break}
			return $ip
		} else {
			return ""
		}
	}

	# This will return the connection type : ip-restrict-nat, direct-connect or firewall
	proc getConnectionType { localip clientip } {
 
		if { $localip eq "" || $clientip eq "" } { 
			return [getFirewalled [::config::getKey initialftport]]
		} 
		if { $localip ne $clientip } {
			return "IP-Restrict-NAT"
		} else { 
			return [getFirewalled [::config::getKey initialftport]]
		}
	}

	# This will create a server, and try to connect to it in order to see if firewalled or not
	proc getFirewalled { {port ""} } {
		global connection_success
		variable random_id

		set random_id [expr rand()]
		set random_id [expr {$random_id * 10000}]
		set random_id [expr {int($random_id)}]

		if { $port eq "" } { set port $::config(initialftport) }

		if { ![string is integer -strict $port] || $port < 0 || $port > 65535 } {
			status_log "Invalid port" red
			return "Firewall"
		}

		while { [catch {set sock [socket -server "abook::dummysocketserver" $port] } ] } {
			incr port
		}
		status_log "::abook::getFirewalled: Connecting to [getDemographicField clientip] port $port\n" blue
		
		#Need this timeout thing to avoid the socket blocking...
		set connection_success -2
		
		status_log "Connecting to http://firewall.amsn-project.net/check_connectivity.php?port=$port&id=$random_id" blue
		if { [catch { ::http::geturl "http://firewall.amsn-project.net/check_connectivity.php?port=$port&id=$random_id" -command "::abook::gotConnectivityReply" -timeout 9500 } res] } { 
			after 500 [list set ::connection_success -1]
			status_log "::abook::getFirewalled failed: $res" red
		}
		after 6000 [list set ::connection_success -3]
		tkwait variable connection_success

		if { $connection_success == -1 } {
			status_log "::abook::getFirewalled: connection_success ($connection_success), trying old method\n" blue
			set connection_success -2
			if {[catch {set clientsock [socket -async [getDemographicField clientip] $port]}] == 0} {
				fileevent $clientsock readable [list ::abook::connectionHandler $clientsock]
				after 1000 ::abook::connectionTimeout
				tkwait variable connection_success
				catch { close $clientsock }
			}
		}
		
		status_log "::abook::getFirewalled: connection_success ($connection_success)\n" blue
		catch {close $sock}

		if { $connection_success == 1 } {
			return "Direct-Connect"
		} else {
			return "Firewall"
		}
	}

	proc gotConnectivityReply { token} {
		global connection_success
		if { [::http::status $token] ne "ok" || [::http::ncode $token ] != 200 } {
			set connection_success -1
			status_log "::abook::gotConnectivityReply error : [http::status $token] - [::http::ncode $token]" green
		}
		::http::cleanup $token
	}

	proc connectionTimeout {} {
		global connection_success
		status_log "::abook::connectionTimeout\n"
		if { $connection_success == -2 } {
			set connection_success -1
		} else {
			set connection_success $connection_success
		}
	}
	
	proc connectionHandler { sock } {
		#CHECK FOR AN ERROR
		global connection_success
		after cancel ::abook::connectionTimeout
		fileevent $sock readable ""
		if { [fconfigure $sock -error] ne ""} {
			status_log "::abook::connectionHandler: connection failed\n" red
			set connection_success 0
		} else {
			# TODO : We need to check here byte per byte because we might connect to an emule server for example which sends binary data
			# and the [gets] will be blocking until there is a newline in the data... which might never happen... 
			# this will cause amsn to hang...
			gets $sock server_data
			if { [string first "AMSNPING" "$server_data"] == 0 } {
				status_log "::abook::connectionHandler: port in use by another application!\n" red
				set connection_success 0
			} else {
				status_log "::abook::connectionHandler: connection succesful\n" green
				set connection_success 1
			}
		}
	}

	proc getListening { conntype } {
		if {$conntype eq "Firewall" } {
			return "false"
		} elseif { $conntype eq "Direct-Connect" } {
		        return "true"
		} else { 
			return [abook::getDemographicField upnpnat]
		}
	}

	# This proc is a dummy socket server proc, because we need a command to be called which the client connects to the test server (if not firewalled)
	proc dummysocketserver { sock ip port } {
		global connection_success
		variable random_id
		if {[catch {
			#puts $sock "AMSNPING"
			if { [info exists random_id] } {
				puts $sock "AMSNPING${random_id}"
			} else {
				puts $sock "AMSNPING"
			}
			flush $sock
			close $sock
			set connection_success 1
			status_log "::abook::dummysocketserver: Received connection on $sock" blue
		} res]} {
			status_log "::abook::dummysocketserver: Error writing to socket: $res\n"
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
		#if { [lsearch -exact $::abook::VisualData $field] > -1 } {
		#	if { [info exists user_data($field)] && $user_data($field) ne $data } {
		#		#puts stdout "ATTENTION! Visual Data has changed! Redraw CL! $field - $data"
		#		::Event::fireEvent contactDataChange abook $user_login
		#	} elseif { ![info exists user_data($field)] && $data ne ""} {
		#		#puts stdout "ATTENTION! Visual Data has changed! Redraw CL! $field - $data"
		#		::Event::fireEvent contactDataChange abook $user_login
		#	}
		#}

		if { $data eq "" } {
			if { [info exists user_data($field)] } {
				unset user_data($field)
			}
		} else {
			set user_data($field) $data
		}
		
		if { $field eq "nick" || $field eq "mfn" || $field eq "psm" || $field eq "customnick" || $field eq "customfnick" } {
			set data [::smiley::parseMessageToList [list [ list "text" "$data" ]] 1]
			set evpar(variable) data
			set evpar(login) $user_login
			::plugins::PostEvent parse_contact evpar

			::abook::setVolatileData $user_login "parsed_$field" $data
		}

		set users_data($user_login) [array get user_data]
		
		#We make this to notify preferences > groups to be refreshed
		set pgc 1
	}

	proc setContactForGuid { guid user_login } {
		variable guid_contact
		if { $user_login eq "" } {
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
				if { [info exists user_data($field)] && $user_data($field) ne $data } {
					#puts stdout "ATTENTION! Visual Data has changed! Redraw CL! $field - $data"
					::Event::fireEvent contactDataChange abook $user_login
					break
				} elseif { ![info exists user_data($field)] && $data ne ""} {
					#puts stdout "ATTENTION! Visual Data has changed! Redraw CL! $field - $data"
					::Event::fireEvent contactDataChange abook $user_login
					break
				}
			}
		}

		# This other loop iterates over the entire lists, replacing the value in user_data(array)
		# if needed. There are two different loops because this one cannot be broke.
		foreach field $fields_list data $data_list {
			if { $data eq "" } {
				if { [info exists user_data($field)] } {
					unset user_data($field)
				}
			} else {
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
		
		if { $data eq "" } {
			if { [info exists volatile_data($field)] } {
				unset volatile_data($field)
			}
		} else {
			set volatile_data($field) $data
		}

		if { $field eq "psm" } {
			set data [::smiley::parseMessageToList [list [ list "text" "$data" ]] 1]
			set evpar(variable) data
			set evpar(login) $user_login
			::plugins::PostEvent parse_contact evpar
			set volatile_data(parsed_$field) $data
		}
		
		set users_volatile_data($user_login) [array get volatile_data]
	}

	#clears all volatile date of a user
	proc clearVolatileData { user_login } {
		variable users_volatile_data

		unset users_volatile_data($user_login)
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
	
	proc setEndPoint {machineguid epname } {
		variable endpoints
		set endpoints($machineguid) $epname
	}

	proc getEndPoints { } {
		variable endpoints
		return [array names endpoints]
	}

	proc getEndPointName { machineguid } {
		variable endpoints
		if {[info exists endpoints($machineguid)] } {
			return [set endpoints($machineguid)]
		} else {
			return ""
		}
	}

	proc clearEndPoints { } {
		variable endpoints
		array unset endpoints
	}
	
	###########################################################################
	# Auxiliary functions, macros, or shortcuts
	###########################################################################

	proc getPassportfromContactguid { contactguid } {
		foreach contact [::abook::getAllContacts] {
			if { [::abook::getContactData $contact contactguid] eq $contactguid } {
				return $contact
			}
		}
	}

	proc lastSeen { } {
		foreach contact [::abook::getAllContacts] {
			set user_state_code [::abook::getVolatileData $contact state FLN]
			if {$user_state_code ne "FLN"} {
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
		if {$time eq ""} {
			return ""
		} else {
			set delm [string first " " $time]
			if { $delm == -1 } { set delm [string length $time]}
			if {![catch {clock scan [string range $time 0 $delm]}]} {
				#Checks if the time is today, and in this case puts today instead of the date
				if {[clock scan $date] == [clock scan [string range $time 0 $delm]]} {
					return "[trans today][string range $time $delm end]"
					#Checks if the time is yesterday, and in this case puts yesterday instead of the date
				} elseif { [expr { [clock scan $date] - [clock scan [string range $time 0 $delm]] }] == 86400} {
					return "[trans yesterday][string range $time $delm end]"
				} else {
					#set month [string range $time 0 1]
					#set day [string range $time 3 4]
					#set year [string range $time 6 7]
					#set end [string range $time 8 end]
					set dateoftime [string range $time 0 $delm]
					set timeTicks [clock scan $dateoftime]
					set month [clock format $timeTicks -format %m]
					set day [clock format $timeTicks -format %d]
					set year [clock format $timeTicks -format %Y]
					set end [string range $time $delm end]
					#Month/Day/Year
					if {[::config::getKey dateformat] eq "MDY"} {
						return $time
					#Day/Month/Year
					} elseif {[::config::getKey dateformat] eq "DMY"} {
						return "$day/$month/$year$end"
					#Year/Month/Day
					} elseif {[::config::getKey dateformat] eq "YMD"} {
						return "$year/$month/$day$end"
					}
				}
			} else {
				return $time
			}
		}
	}

	proc parseCurrentMedia {currentMedia} {
		if {$currentMedia eq ""} { return "" }
	
		set currentMedia [string map {"\\0" "\0"} $currentMedia]
		set infos [split $currentMedia "\0"]
	
		if {[lindex $infos 2] eq "0"} { return "" }
	
		if {[lindex $infos 1] eq "Music"} {
			set out [list [list "smiley" [::skin::loadPixmap note] "-"] [list "text" " "]]
		} else {
			set out [list [list "text" "- "]]
		}
	
		set pattern [lindex $infos 3]
	
		set nrParams [expr {[llength $infos] - 4}]
		set lstMap [list]
		for {set idx 0} {$idx < $nrParams} {incr idx} {
			lappend lstMap "\{$idx\}"
			lappend lstMap [lindex $infos [expr {$idx + 4}]]
		}
	
		lappend out [list "text" "[string map $lstMap $pattern]"]
	
		return $out
	}

	# Get PSM and currentMedia
	proc getpsmmedia { { user_login "" } { use_styled_psm 0}} {
		if { [::config::getKey protocol] < 11 } { return [list ]}
		set psmmedia [list ]
		if { $user_login eq "" } {
			set psm [::abook::getVolatileData myself parsed_psm]
			set currentMedia [::abook::parseCurrentMedia [::abook::getVolatileData myself currentMedia]]
		} else {
			set psm [::abook::getVolatileData $user_login parsed_psm]
			set currentMedia [::abook::parseCurrentMedia [::abook::getVolatileData $user_login currentMedia]]
		}
		if {$psm ne ""} {
			set psmmedia [concat $psmmedia $psm]
		}
		if {$currentMedia ne ""} {
			if { $psm ne ""} {
				lappend psmmedia [list "colour" "reset"]
				lappend psmmedia [list "font" "reset"]
				lappend psmmedia [list "text" " "]
			}
			set psmmedia [concat $psmmedia $currentMedia]
		}
		if { !$use_styled_psm } {
			set psmmedia [::abook::removeStyles $psmmedia]
		}

		return $psmmedia
	}

	#Returns the user nickname
	proc getNick { user_login {use_styled_nick 0}} {
		set nick [::abook::getVolatileData $user_login parsed_nick]
		if { $nick eq "" } {
			return [list [list "text" $user_login]]
		}
		if { !$use_styled_nick } {
			set nick [::abook::removeStyles $nick]
		}
		return $nick
	}

	#Parser to replace special characters and variables in the right way
	proc parseCustomNick { input nick user_login customnick {psm ""} } {
		#If there's no customnick set, default to user_login
		if { $customnick eq "" } {
			set customnick $user_login
		}
		#By default, quote backslashes, angle brackets and variables
		set input [string map { "\\" "\\\\" "\$" "\\\$" "\(" "\\\(" } $input]
		#Now, let's unquote the variables we want to replace
		set input [string map { "\\\$nick" "\${nick}" "\\\$user_login" "\${user_login}" "\\\$customnick" "\${customnick}" "\\\$psm" "\${psm}" } $input]
		#Return the custom nick, replacing backslashses and variables
		return [subst -nocommands $input]
	}

	#Parser to replace special characters and variables in the right way
	proc parseCustomNickStyled { input nick user_login customnick } {

		set psm [::abook::getpsmmedia $user_login 1]

		#If there's no customnick set, default to user_login
		if { [::abook::removeStyles $customnick] eq "" } {
			set customnick [list [list "text" "$user_login"]]
		}

		set user_login [list [list "text" "$user_login"]]

		set l $input
		set llength [llength $l]
		set listpos 0
		set npos 0
		#Keep searching until no matches
		while { $listpos < $llength } {
			if { ([lindex $l $listpos 0] ne "text") } {
				incr listpos
				continue
			}
			set txt [lindex $l $listpos 1]
			if { [set pos [string first "\$" $txt $npos]] == -1 } {
				set npos 0
				incr listpos
			} else {
				#in case the $ isn't a matching $ we will search for the next in the same list item
				set npos [expr {$pos + 1}]
				foreach substitute { "\$nick" "\$user_login" "\$customnick" "\$psm" } {
					if { [string range $txt $pos [expr {$pos + [string length $substitute] - 1}]] eq $substitute } {
						set content [set [string range $substitute 1 end]]
						set p1 [string range $txt 0 [expr {$pos - 1}]]
						set p3 [string range $txt [expr {$pos + [string length $substitute]}] end]
		
						set l [lreplace $l $listpos $listpos]
						incr llength -1
		
						if { $p1 ne "" } {
							set l [linsert $l $listpos [list text $p1]]
							incr llength 1
							incr listpos 1
						}
		
						foreach unit $content {
							set l [linsert $l $listpos $unit]
							incr listpos 1
							incr llength 1
						}
		
						if { $p3 ne "" } {
							set l [linsert $l $listpos [list text $p3]]
							incr llength 1
							#We must parse p3
						}
						#We will search from the begining of p3
						set npos 0
						break
					}
				}
			}
		}
		#Return the custom nick, replacing backslashses and variables
		return $l
	}
	
	#Returns the user nickname, or just email, or custom nick,
	#depending on configuration
	proc getDisplayNick { user_login {use_styled_nick 0}} {
		if { [::config::getKey emailsincontactlist] } {
			set out [list [list "text" $user_login]]
		} else {
			set nick [::abook::getNick $user_login 1]
			set customnick [::abook::getVolatileData $user_login parsed_customnick]

			set customnicktxt [::abook::removeStyles $customnick]
			set globalnicktxt [::abook::removeStyles $::globalnick]

			if { [::config::getKey globaloverride] == 0 } {
				if { $customnicktxt ne "" } {
					set out [parseCustomNickStyled $customnick $nick $user_login $customnick]
				} else {
					if { $globalnicktxt ne "" } {
						set out [parseCustomNickStyled $::globalnick $nick $user_login $customnick]
					} else {
						set out $nick
					}
				}
			} elseif { [::config::getKey globaloverride] == 1 } {
				if { $customnicktxt ne "" && $globalnicktxt eq "" } {
					set out [parseCustomNickStyled $customnick $nick $user_login $customnick]
				} elseif { $globalnicktxt ne "" } {
					set out [parseCustomNickStyled $::globalnick $nick $user_login $customnick]
				} else {
					set out $nick
				}
			}
		}
		if { !$use_styled_nick } {
			set out [::abook::removeStyles $out]
		}
		return $out
	}
	
	#Used to remove styles from the nickname/psm and returns full text
	proc removeStyles {list_styles} {
		set output ""
		foreach unit $list_styles {
			switch [lindex $unit 0] {
				"text" {
					# Store the text as a string
					append output [lindex $unit 1]
				}
				"smiley" {
					append output [lindex $unit 2]
				}
				"newline" {
					append output "\n"
				}
				"colour" -
				"font" -
				"bg" {
				}
				default {
					status_log "Unknown item in parsed nickname: $unit"
				}
			}
		}
		return $output
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

	proc emptyUserGroups { email } {
		global pcc

		setContactData $email group [list ]

		set pcc 1
	}

	proc removeContactFromGroup { email grId } {
		global pcc
		
		set groups [getContactData $email group]
		set idx [lsearch $groups $grId]
		
		if { $idx != -1 } {
			#The last group -> we move to nogroup
			if { [llength $groups] == 1 } {
				setContactData $email group [lreplace $groups $idx $idx 0]
			} else {
				setContactData $email group [lreplace $groups $idx $idx]
			}
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
		
		if { ![isConsistent] || ![LoginList lockexists "" [::config::getKey login]] } {
			return
		}
	
		global HOME
		variable users_data
		
		if { $filename eq "" } {
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
		
		if { $filename eq "" } {
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
			if { $child eq "_dummy_" } {
				continue
			}
			set fieldname [string range $child [expr {$parentlen+1}] end]
			#Remove this. Only leave it for some days to remove old ::abook stored data
			if { $fieldname eq "field" } {
				continue
			}
			setContactData $attr(name) $fieldname $sdata($child)

			#To set up the reverse search array
			if { $fieldname eq "contactguid" } {
				setContactForGuid $sdata($child) $attr(name)
			}
		}
		
		return 0	
		
	}
	
	
	proc importContact { } {
	
		set filename [chooseFileDialog]

		if { $filename ne "" } {
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
			::MSN::addUser $contact
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
		set nbUserDPs [$nb getframe userDPs]

#		set browser $nbUserDPs.otherdpscontainer.browser
#		set actions $nbUserDPs.otherdpscontainer.actions
#
#		if { ![winfo exists $browser]} {
#			::dpbrowser $browser -user $email -mode "selector" -width 6 -command [list\
#				::abookGui::activate_dpbrowser_actions $nbUserDPs.otherdpscontainer $email]
#
#			pack $browser -side left -expand true -fill both\
#				-before $nbUserDPs.otherdpscontainer.actions
#		}

		if { ![winfo exists $nbUserDPs.otherpics]} {
			::dpbrowser $nbUserDPs.otherpics  -width 7 -user $email -mode "properties"
			pack $nbUserDPs.otherpics -expand true -fill both
		}
	}

#	proc activate_dpbrowser_actions {widget email} {
#
#		set browser $widget.browser
#		set actions $widget.actions
#
#		set filepath [lindex [$browser getSelected] 1]
#		#activate the action buttons now an image is selected
#		if {$filepath ne ""} {
#			$actions.setasmine configure -state normal -command [list set_displaypic $filepath ]
#			$actions.setascustom configure -state normal -command [list ::abookGui::setCustomDp $email $filepath $widget ]
#			$actions.copyfileuri configure -state normal -command [list ::abookGui::copyDpToClipboard $filepath]
#		} else {
#			$actions.setasmine configure -state disabled
#			$actions.setascustom configure -state disabled
#			$actions.copyfileuri configure -state disabled
#		}
#	}

	#menu when right-clicking the user's dp on the first tab
	proc dp_mypicpopup_menu { X Y filename user} {
		
		#if user is self have another menu ?		
		
		# Create pop-up menu if it doesn't yet exists
		set the_menu .userDPs_menu
		catch {destroy $the_menu}
		menu $the_menu -tearoff 0 -type normal
		$the_menu add command \
			-label "[trans copytoclipboard [string tolower [trans filename]]]" \
			-command [list ::abookGui::copyDpToClipboard $filename]
		$the_menu add command -label "[trans setasmydp]" \
			-command [list set_displaypic $filename]
		$the_menu add command -label "[trans save]" \
			-command [list saveFile $filename]
		tk_popup $the_menu $X $Y
	}

	proc showUserProperties { email } {
		global colorval_$email customdp_$email showcustomsmileys_$email autoacceptft_$email autoacceptwc_$email ignorecontact_$email HOME customdp_img_$email dontshowdp_$email
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
		bind $nbIdent.fBasicInfo.displaypic <<Button3-Press>> \
			[list ::abookGui::dp_mypicpopup_menu %X %Y\
			[file join $HOME displaypic cache $email [filenoext [::abook::getContactData $email displaypicfile ""]].png] $email]
		
		set nick [::abook::getNick $email]
		set h [expr {[string length $nick]/50 +1}]
		text $nbIdent.fBasicInfo.h1 -font bigfont -bg [::skin::getKey extrastdwindowcolor] -height $h -wrap word -bd 0
		$nbIdent.fBasicInfo.h1 delete 0.0 end
		$nbIdent.fBasicInfo.h1 insert 0.0 $nick
		$nbIdent.fBasicInfo.h1 configure -state disabled
		set h1copymenu [::abook::CreateCopyMenu $nbIdent.fBasicInfo.h1]
		bind $nbIdent.fBasicInfo.h1 <<Button3>> "tk_popup $h1copymenu %X %Y"
		
		if { [::config::getKey protocol] >= 11 } {
			set psm [::abook::getpsmmedia $email]
			set h [expr {[string length $psm]/50 +1}]
			text $nbIdent.fBasicInfo.psm1 -font sitalf -bg [::skin::getKey extrastdwindowcolor] -height $h -wrap word -bd 0
			$nbIdent.fBasicInfo.psm1 delete 0.0 end
			$nbIdent.fBasicInfo.psm1 insert 0.0 $psm
			$nbIdent.fBasicInfo.psm1 configure -state disabled
			set psm1copymenu [::abook::CreateCopyMenu $nbIdent.fBasicInfo.psm1]
			bind $nbIdent.fBasicInfo.psm1 <<Button3>> "tk_popup $psm1copymenu %X %Y"
		}

		set h [expr {[string length $email]/50 +1}]
		text $nbIdent.fBasicInfo.e1 -font splainf -bg [::skin::getKey extrastdwindowcolor] -height $h -wrap word -bd 0
		$nbIdent.fBasicInfo.e1 delete 0.0 end
		$nbIdent.fBasicInfo.e1 insert 0.0 $email
		$nbIdent.fBasicInfo.e1 configure -state disabled
		set e1copymenu [::abook::CreateCopyMenu $nbIdent.fBasicInfo.e1]
		bind $nbIdent.fBasicInfo.e1 <<Button3>> "tk_popup $e1copymenu %X %Y"
		
		frame $nbIdent.fBasicInfo.fGroup
		label $nbIdent.fBasicInfo.fGroup.g -text "[trans group]:" -font splainf
		label $nbIdent.fBasicInfo.fGroup.g1 -text "[::abook::getGroupsname $email]" -font splainf -justify left -wraplength 300
		pack $nbIdent.fBasicInfo.fGroup.g -side left
		pack $nbIdent.fBasicInfo.fGroup.g1 -side left
		
		grid $nbIdent.fBasicInfo.displaypic -row 0 -column 0 -sticky nwe -rowspan 4 -padx [list 0 8]
		grid $nbIdent.fBasicInfo.h1 -row 0 -column 1 -sticky w
		if { [::config::getKey protocol] >= 11 } {
			grid $nbIdent.fBasicInfo.psm1 -row 1 -column 1 -sticky w
		}
		grid $nbIdent.fBasicInfo.e1 -row 2 -column 1 -sticky w
		grid $nbIdent.fBasicInfo.fGroup -row 3 -column 1 -sticky w
		grid columnconfigure $nbIdent.fBasicInfo 1 -weight 1

		labelframe $nbIdent.fPhone -text [trans phones]
		label $nbIdent.fPhone.phh -text "[trans home]:" 
		label $nbIdent.fPhone.phh1 -font splainf -text [::abook::getContactData $email phh] \
		-justify left -wraplength 300 
		label $nbIdent.fPhone.phw -text "[trans work]:"
		label $nbIdent.fPhone.phw1 -font splainf -text [::abook::getContactData $email phw] \
			-justify left -wraplength 300 
		label $nbIdent.fPhone.phm -text "[trans mobile]:" 
		label $nbIdent.fPhone.phm1 -font splainf -text [::abook::getContactData $email phm] \
		-justify left -wraplength 300 
		label $nbIdent.fPhone.php -text "[trans pager]:" 
		label $nbIdent.fPhone.php1 -font splainf -text [::abook::getContactData $email mob] \
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
		label $nbIdent.fStats.lastlogin1 -text [::abook::dateconvert "[::abook::getContactData $email last_login]"] -font splainf
		
		label $nbIdent.fStats.lastlogout -text "[trans lastlogout]:"
		label $nbIdent.fStats.lastlogout1 -text [::abook::dateconvert "[::abook::getContactData $email last_logout]"] -font splainf

		label $nbIdent.fStats.lastseen -text "[trans lastseen]:"
		if { [::abook::getVolatileData $email state] eq "FLN" || 
		     ([lsearch [::abook::getContactData $email lists] "FL"] == -1 &&
		      [lsearch [::abook::getContactData $email lists] "EL"] != -1)} {
			label $nbIdent.fStats.lastseen1 -text [::abook::dateconvert "[::abook::getContactData $email last_seen]"] -font splainf
		} elseif { [::abook::getContactData $email last_seen] eq "" } {		
			label $nbIdent.fStats.lastseen1 -text "" -font splainf
		} else {
			label $nbIdent.fStats.lastseen1 -text [trans online] -font splainf
		}
		
		label $nbIdent.fStats.lastmsgedme -text "[trans lastmsgedme]:"
		label $nbIdent.fStats.lastmsgedme1 -text [::abook::dateconvert "[::abook::getContactData $email last_msgedme]"] -font splainf
		#Client-name of the user (from Gaim, dMSN, etc)
		label $nbIdent.fStats.clientname -text "[trans clientname]:"
		label $nbIdent.fStats.clientname1 -text "[::abook::getContactData $email clientname] ([::abook::getContactData $email client])" -font splainf
		
		#Does the user record the conversation or not
		if { [::abook::getContactData $email chatlogging] eq "Y" } {
			set chatlogging [trans yes]
		} elseif { [::abook::getContactData $email chatlogging] eq "N" } {
			set chatlogging [trans no]
		} else {
			set chatlogging [trans unknown]
		}
		
		label $nbIdent.fStats.chatlogging -text "[trans logschats]:"
		label $nbIdent.fStats.chatlogging1 -text $chatlogging -font splainf
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
		grid $nbIdent.fPhone -row 1 -column 0 -sticky nwse -padx [list 0 4] -pady [list 8 0]
		grid $nbIdent.fStats -row 1 -column 1 -sticky nwse -padx [list 4 0] -pady [list 8 0]
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
		entry $nbSettings.fNick.customnick.ent -font splainf
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
		entry $nbSettings.fNick.customfnick.ent -font splainf
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
		entry $nbSettings.fNick.ycustomfnick.ent -font splainf
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
		set autoacceptft_$email [::abook::getContactData $email autoacceptft]
		set autoacceptwc_$email [::abook::getContactData $email autoacceptwc]
		set ignorecontact_$email [::abook::getContactData $email ignored]
		set dontshowdp_$email [::abook::getContactData $email dontshowdp]

		frame $nbSettings.fNick.fColor.col -width 96 -bd 1 -relief flat -highlightbackground black -highlightcolor black
		if { [set colorval_$email] ne "" } {
			if { [string index [set colorval_$email] 0] eq "#" } {
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
		
		# The custom display pic frame
		label $nbSettings.fNick.lDispl -text "[trans customdp]:"
		frame $nbSettings.fNick.fDispl -relief flat
		
		set customdp_$email [::abook::getContactData $email customdp ""] 
		if {[set customdp_$email] ne "" && [file readable [set customdp_$email]]} {
			image create photo customdp_img_$email -file [set customdp_$email]
			label $nbSettings.fNick.fDispl.dp -height 96 -width 96 -image customdp_img_$email -borderwidth 0 -relief flat
		} else {
			label $nbSettings.fNick.fDispl.dp -height 96 -width 96 -image [::skin::loadPixmap nullimage] -borderwidth 0 -relief flat
		}
		
		button $nbSettings.fNick.fDispl.bset -text "[trans change]" -command "::abookGui::ChangeCustomDp $email $nbSettings" 
		button $nbSettings.fNick.fDispl.brem -text "[trans delete]" -command "::abookGui::RemoveCustomDp $email $nbSettings" 
		pack $nbSettings.fNick.fDispl.dp -side left -pady 5 -padx 8
		pack $nbSettings.fNick.fDispl.bset -side left -padx 3 -pady 2
		pack $nbSettings.fNick.fDispl.brem -side left -padx 3 -pady 2
		
		grid $nbSettings.fNick.customnickl -row 0 -column 0 -sticky e
		grid $nbSettings.fNick.customnick -row 0 -column 1 -sticky we
		grid $nbSettings.fNick.customfnickl -row 1 -column 0 -sticky e
		grid $nbSettings.fNick.customfnick -row 1 -column 1 -sticky we
		grid $nbSettings.fNick.ycustomfnickl -row 2 -column 0 -sticky e
		grid $nbSettings.fNick.ycustomfnick -row 2 -column 1 -sticky we
		grid $nbSettings.fNick.lColor -row 3 -column 0 -sticky e
		grid $nbSettings.fNick.fColor -row 3 -column 1 -sticky w
		grid $nbSettings.fNick.lDispl -row 4 -column 0 -sticky e
		grid $nbSettings.fNick.fDispl -row 4 -column 1 -sticky w
		grid columnconfigure $nbSettings.fNick 1 -weight 1
		
		labelframe $nbSettings.fChat -relief groove -text [trans chat]
		checkbutton $nbSettings.fChat.showcustomsmileys -variable showcustomsmileys_$email -text "[trans custshowcustomsmileys]" -anchor w
		checkbutton $nbSettings.fChat.ignoreuser -variable ignorecontact_$email -text "[trans ignorecontact]" -anchor w
		checkbutton $nbSettings.fChat.dontshowdp -variable dontshowdp_$email -text "[trans dontshowdp]" -anchor w
		checkbutton $nbSettings.fChat.autoacceptft -variable autoacceptft_$email -text "[trans autoacceptft]" -anchor w
		checkbutton $nbSettings.fChat.autoacceptwc -variable autoacceptwc_$email -text "[trans autoacceptwc]" -anchor w
		pack $nbSettings.fChat.showcustomsmileys -side top -fill x
		pack $nbSettings.fChat.ignoreuser -side top -fill x
		pack $nbSettings.fChat.dontshowdp -side top -fill x
		pack $nbSettings.fChat.autoacceptft -side top -fill x
		pack $nbSettings.fChat.autoacceptwc -side top -fill x
		
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
		
		grid $nbSettings.fNick -row 0 -column 0 -sticky nwse -columnspan 2 -pady [list 0 4]
		grid $nbSettings.fChat -row 1 -column 0 -sticky nwse -padx [list 0 4] -pady 4
		grid $nbSettings.fGroup -row 1 -column 1 -sticky nwse -padx [list 4 0] -pady 4
		grid $nbSettings.fNotify -row 2 -column 0 -sticky nwse -columnspan 2 -pady [list 4 0]
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
#		label $nbUserDPs.titlepic1 -text "[trans curdisplaypic]" -font bboldunderf
#		label $nbUserDPs.displaypic -image [::skin::getDisplayPicture $email]
#		bind $nbUserDPs.displaypic <<Button3-Press>> \
			[list ::abookGui::dp_mypicpopup_menu %X %Y\
			[file join $HOME displaypic cache $email [filenoext [::abook::getContactData $email displaypicfile ""]].png] $email]

		# Other display pictures of user
		label $nbUserDPs.titlepic2 -text "[trans otherdisplaypic]" 

#		frame $nbUserDPs.otherdpscontainer
#		set actions $nbUserDPs.otherdpscontainer.actions
#		#$nbUserDPs.otherdpscontainer.browser is created in userDPs_raise_cmd
#
#		frame $actions
#		label $actions.titlepic1 -text "[trans curdisplaypic]" -font bboldunderf -anchor n
#		label $actions.displaypic -image [::skin::getDisplayPicture $email] -anchor n
#		
#		button $actions.setasmine -text "[trans setasmydp]" -state disabled -justify left
#		button $actions.setascustom -text "[trans setascustom]" -state disabled
#		if {[::abook::getContactData $email customdp ""] ne ""} {
#			button $actions.removecustom -text "[trans removecustom]" -state normal -command [list ::abookGui::unsetCustomDp $email $w]
#		} else {
#			button $actions.removecustom -text "[trans removecustom]" -state disabled
#		}
#		button $actions.copyfileuri -text "[trans copytoclipboard [string tolower [trans filename]]]" -state disabled
#		pack $actions.titlepic1 $actions.displaypic -fill x
#		pack $actions.setasmine $actions.setascustom $actions.removecustom $actions.copyfileuri  -anchor w -fill x
#		pack $actions -side left -fill y


		#Other display pictures get loaded when the dp tab is raised
		#See proc userDPs_raise_cmd
		
#		pack $nbUserDPs.titlepic1 -anchor w -padx 5 -pady 5
#		pack $nbUserDPs.displaypic -anchor w -padx 7 -pady 5
		pack $nbUserDPs.titlepic2 -anchor w -padx 5 -pady 5
#		pack $nbUserDPs.otherdpscontainer -anchor w -padx 5 -pady 5 -fill both -expand true

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
		if { [OnMac] } {
			wm protocol $w WM_DELETE_WINDOW "[list ::abookGui::closeProperties $email $w]"
			bind $w <<Escape>> "[list ::abookGui::closeProperties $email $w]"
		} else {
			bind $w <<Escape>> "[list ::abookGui::PropCancel $email $w]"
		}

		bind $w <Destroy> [list ::abookGui::PropDestroyed $email $w %W]
		
		moveinscreen $w 30
	}
	
	proc showUserAlarmSettings { email } {
		showUserProperties $email
		.user_[::md5::md5 $email]_prop.nb raise alarms
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
		entry $w.customnick.ent -font splainf
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
		entry $w.customfnick.ent -font splainf
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
		if {$answer eq "yes"} {
			::abookGui::PropOk $email $w
		#When the user do not answer yes (no), then Restore previous preferences and close the window
		} else {
			::abookGui::PropCancel $email $w
		}
	}
	
	proc PropDestroyed { email w win } {
		global colorval_$email showcustomsmileys_$email autoacceptft_$email autoacceptwc_$email ignorecontact_$email dontshowdp_$email

		if { $w eq $win } {
			#Clean temporal variables
			unset ::notifyonline($email)
			unset ::notifyoffline($email)
			unset ::notifystatus($email)
			unset ::notifymsg($email)
			catch {unset colorval_$email}
			catch {unset showcustomsmileys_$email}
			catch {unset autoacceptft_$email}
			catch {unset autoacceptwc_$email}
			catch {unset ignorecontact_$email}
			catch {unset dontshowdp_$email}
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
		set color  [SelectColor $w.customcolordialog  -type dialog  -title "[trans customcolor]" -parent $w]
		if { $color eq "" } { return }

		set colorval_$email $color
		$w.fNick.fColor.col configure -background [set colorval_${email}] -highlightthickness 1 
	}
	
	proc RemoveCustomColor { email w } {	
	   	global colorval_$email	
		set colorval_$email ""
		$w.fNick.fColor.col configure -background [$w.fNick.fColor cget -background] -highlightthickness 0
	}

#	proc setCustomDp { email path widget } {
#		# Backup old custom dp
#		set old_customdp [::abook::getContactData $email customdp ""]	
#		# Store custom display information options
#		::abook::setAtomicContactData $email customdp $path
#		# Update display picture
#		if {$path ne $old_customdp} {
#			::skin::getDisplayPicture $email 1
#			::skin::getLittleDisplayPicture $email 1
#			$widget.actions.displaypic configure -image [::skin::getDisplayPicture $email]
#		}
#		if {$old_customdp eq ""} {
#			$widget.actions.removecustom configure -state normal -command [list ::abookGui::unsetCustomDp $email $widget]
#		}
#	}

#	proc unsetCustomDp { email widget } {
#		# Backup old custom dp
#		set old_customdp [::abook::getContactData $email customdp ""]	
#		# Store custom display information options
#		::abook::setAtomicContactData $email customdp ""
#		# Update display picture
#		if {$old_customdp ne ""} {
#			::skin::getDisplayPicture $email 1
#			::skin::getLittleDisplayPicture $email 1
#			$widget.actions.displaypic configure -image [::skin::getDisplayPicture $email]
#		}
#		$widget.actions.removecustom configure -state disabled
#	}

	proc copyDpToClipboard { file } {
		clipboard clear
		clipboard append $file
	}


	# These procedures change the custom DP. They need to be launched from within the properties screen,
	# as the actual change is done through the PropOk procedure
	proc ChangeCustomDp { email w } {
		global customdp_$email
		set customdp_$email [::abook::getContactData $email customdp ""]
		dpBrowser $email
		tkwait window .dpbrowser
		if {[file readable [set customdp_$email]]} {
			catch {image delete customdp_img_$email}
			image create photo customdp_img_$email -file [set customdp_$email]
			$w.fNick.fDispl.dp configure -image customdp_img_$email
		} else {
			status_log "Can not open file [set customdp_$email]" red
		}
	}


	proc RemoveCustomDp { email w } {
	   	global customdp_$email
		set customdp_$email ""
		$w.fNick.fDispl.dp configure -image [::skin::loadPixmap nullimage]
	}

	proc SetGlobalNick { } {
		
		if {[winfo exists .globalnick]} {
			return
		}
	
		toplevel .globalnick
		wm title .globalnick "[trans globalnicktitle]"
		frame .globalnick.frm -bd 1 
		label .globalnick.frm.lbl -text "[trans globalnick]" -font sboldf -justify left -wraplength 400
		entry .globalnick.frm.nick -width 50
		menubutton .globalnick.frm.help -bd 1 -text "<-" -menu .globalnick.frm.help.menu
		menu .globalnick.frm.help.menu -tearoff 0
		.globalnick.frm.help.menu add command -label [trans nick] -command ".globalnick.frm.nick insert insert \\\$nick"
		.globalnick.frm.help.menu add command -label [trans email] -command ".globalnick.frm.nick insert insert \\\$user_login"
		.globalnick.frm.help.menu add command -label [trans psm] -command ".globalnick.frm.nick insert insert \\\$psm"
		.globalnick.frm.help.menu add command -label [trans customnick] -command ".globalnick.frm.nick insert insert \\\$customnick"
		.globalnick.frm.help.menu add separator
		.globalnick.frm.help.menu add command -label [trans delete] -command ".globalnick.frm.nick delete 0 end"

		pack .globalnick.frm.lbl -pady 2 -side top
		pack .globalnick.frm.nick -pady 2 -side left
		pack .globalnick.frm.help -padx 5 -side left
		bind .globalnick.frm.nick <Return> [list .globalnick.btn.ok invoke]
		frame .globalnick.btn -bg [::skin::getKey extrastdwindowcolor]
		button .globalnick.btn.ok -text "[trans ok]"  \
			-command {
			set nick [.globalnick.frm.nick get]
			set data [::smiley::parseMessageToList [list [ list "text" $nick ]] 1]
			set evpar(variable) data
			set evpar(login) ""
			::plugins::PostEvent parse_contact evpar

			set ::globalnick $data
		
			::config::setKey globalnick $nick;
			::MSN::contactListChanged;
			::Event::fireEvent changedNickDisplay gui
			destroy .globalnick
			}
		button .globalnick.btn.cancel -text "[trans cancel]"  \
			-command {destroy .globalnick}
		bind .globalnick <<Escape>> [list .globalnick.btn.cancel invoke]
		pack .globalnick.btn.ok .globalnick.btn.cancel -side right -padx 5
		pack .globalnick.frm -side top -pady 3 -padx 5
		pack .globalnick.btn  -side top -anchor e -pady 3

		.globalnick.frm.nick insert end [::config::getKey globalnick]
	}

	proc PropOk { email w } {
		global colorval_$email customdp_$email showcustomsmileys_$email autoacceptft_$email autoacceptwc_$email ignorecontact_$email dontshowdp_$email
		
		if {[::alarms::SaveAlarm $email] != 0 } {
			return
		}
	
		set nbSettings [$w.nb getframe usersettings]
		set nbSettings [$nbSettings.sw.sf getframe]
		
		# Backup old custom dp
		set old_customdp [::abook::getContactData $email customdp ""]

		# Store custom display information options
		::abook::setAtomicContactData $email [list cust_p4c_name customcolor customdp showcustomsmileys autoacceptft autoacceptwc ignored dontshowdp] \
			[list [$nbSettings.fNick.ycustomfnick.ent get] [set colorval_$email] [set customdp_$email] [set showcustomsmileys_$email] [set autoacceptft_$email] [set autoacceptwc_$email] [set ignorecontact_$email] [set dontshowdp_$email]]
		
		::abook::setContactData $email customnick [$nbSettings.fNick.customnick.ent get]
		::abook::setContactData $email customfnick [$nbSettings.fNick.customfnick.ent get]
		# Update display picture
		if {[set customdp_$email] ne $old_customdp} {
			::skin::getDisplayPicture $email 1
			::skin::getLittleDisplayPicture $email 1
		}
		
		# Store groups
		::groups::GroupmanagerOk $email
		
		# Store custom notification options
		::abook::setAtomicContactData $email [list notifyonline notifyoffline notifystatus notifymsg] \
			[list [set ::notifyonline($email)] [set ::notifyoffline($email)] [set ::notifystatus($email)] [set ::notifymsg($email)]]
		
		catch {image delete customdp_img_$email}
		destroy $w
		::MSN::contactListChanged
		::Event::fireEvent contactDataChange gui $email

		::abook::saveToDisk
	}
	
	proc PropCancel { email w } {
		::groups::GroupmanagerClose $email
		catch {image delete customdp_img_$email}
		destroy $w
	}

}
