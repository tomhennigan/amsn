snit::type Addressbook {

	method ABContactDelete { callbk contactid } {
		set request [SOAPRequest create %AUTO% \
		  -url "https://contacts.msn.com/abservice/abservice.asmx" \
		  -action "http://www.msn.com/webservices/AddressBook/ABContactDelete" \
		  -xml [$self getABContactDeleteXML $contactid] \
		  -callback [list $self ABContactDeleteCallback $callbk]]

		$request SendSOAPRequest
	}

	method ABContactDeleteCallback { callbk soap } {
		eval $callbk
	}


	method ABFindAll { args } {
		set request [SOAPRequest create %AUTO% \
		  -url "https://contacts.msn.com/abservice/abservice.asmx" \
		  -action "http://www.msn.com/webservices/AddressBook/ABFindAll" \
		  -xml [$self getABFindAllXML] \
		  -callback [list $self ABFindAllCallback]]

		$request SendSOAPRequest
	}

	method ABFindAllCallback { soap } {
		global contactlist_loaded
		set contactlist_loaded 0
		#Make list unconsistent while receiving contact lists
		::abook::unsetConsistent

		set ::xml  [$soap GetResponse]

		status_log "Going to receive contact list\n" blue
		#First contact in list
		::MSN::clearList FL
		::MSN::clearList BL
		::MSN::clearList RL
		::MSN::clearList AL
		::groups::Reset
		::groups::Set 0 [trans nogroup]

		set i 0
		# can go later
		while {1} {
			set ::subxml [GetXmlNode $::xml "soap:Envelope:soap:Body:ABFindAllResponse:ABFindAllResult:groups:Group" $i]
			incr i
			if  { $::subxml == "" } {
				break
			}
			puts "$::subxml\n\n\n"
			set groupId [GetXmlEntry $::subxml "Group:groupId"]
			set groupName [GetXmlEntry $::subxml "Group:groupInfo:name"]
			::groups::Set $groupId $groupName
		}

		set i 0
		# can go later
		set contacts {}
		while {1} {
			set ::subxml [GetXmlNode $::xml "soap:Envelope:soap:Body:ABFindAllResponse:ABFindAllResult:contacts:Contact" $i]
			incr i
			if  { $::subxml == "" } {
				break
			}
			puts "$::subxml\n\n\n"
			set contact [GetXmlEntry $::subxml "Contact:contactInfo:passportName"]
			lappend contacts $contact
			
			set nickname [GetXmlEntry $::subxml "Contact:contactInfo:displayName"]
			set contactguid [GetXmlEntry $::subxml "Contact:contactId"]
			set list_names "11"
			#TODO: multiple groups
			set groups [GetXmlEntry $::subxml "Contact:contactInfo:groupIds:guid"]

			set username "$contact"

			set list_names [process_msnp11_lists $list_names]
			set groups [split $groups ,]

			if { $groups == "" } {
				set groups 0
			}

			#Remove user from all lists while receiving List data
			::abook::setContactData $username lists ""

			::abook::setContactData $username nick $nickname

			::abook::setContactData $username contactguid $contactguid
			::abook::setContactForGuid $contactguid $username

			foreach list_sort $list_names {

				::abook::addContactToList $username $list_sort
				::MSN::addToList $list_sort $username

				#No need to set groups and set offline state if command is not LST
				if { $list_sort == "FL" } {
					::abook::setContactData $username group $groups
					::abook::setVolatileData $username state "FLN"
				}
			}
	
			set lists [::abook::getLists $username]
			if { [lsearch $lists PL] != -1 } {
				if { [lsearch [::abook::getLists $username] "AL"] != -1 || [lsearch [::abook::getLists $username] "BL"] != -1 } {
					#We already added it we only move it from PL to RL
					#Just add to RL for now and let the handler remove it from PL... to be sure it's the correct order...
					::MSN::WriteSB ns "ADC" "RL N=$username"
				} else {
					newcontact $username $nickname
				}
			}
		}
		sendADL $contacts
		::MSN::contactListChanged
		ns authenticationDone
			
	}

	method getABContactDeleteXML { contactid args } {
		set xml [$self getCommonHeader Timer]
		append xml {<ABContactDelete xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>}
		append xml {00000000-0000-0000-0000-000000000000}
		append xml {</abId>}
		append xml {<contacts>}
		append xml {<Contact>}
		append xml {<contactId>}
		append xml $contactid
		append xml {</contactId>}
		append xml {</Contact>}
		append xml {</contacts>}
		append xml {</ABContactDelete>}

		return $xml
	}

	method getABFindAllXML { args } {
		set xml [$self getCommonHeader Initial]
		append xml {<soap:Body>}
		append xml {<ABFindAll xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<abView>Full</abView>}
		append xml {<deltasOnly>false</deltasOnly>}
		append xml {<lastChange>0001-01-01T00:00:00.0000000-08:00</lastChange>}
		append xml {</ABFindAll>}
		append xml {</soap:Body>}
		append xml {</soap:Envelope>}

		return $xml
	}

	method getCommonHeader { scenario } {
		set token [$::sso GetSecurityTokenByName Contacts]
		set mspauth [$token cget -ticket]

		set xml {<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">}
		append xml {<soap:Header>}
		append xml {<ABApplicationHeader xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<ApplicationId>996CDE1E-AA53-4477-B943-2BE802EA6166</ApplicationId>}
		append xml {<IsMigration>false</IsMigration>}
		append xml {<PartnerScenario>}
		append xml $scenario
		append xml {</PartnerScenario>}
		append xml {</ABApplicationHeader>}
		append xml {<ABAuthHeader xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<ManagedGroupRequest>false</ManagedGroupRequest>}
		append xml {<TicketToken>}
		append xml [xmlencode $mspauth]
		append xml {</TicketToken>}
		append xml {</ABAuthHeader>}
		append xml {</soap:Header>}

		return $xml
	}
}

#######################


proc sendADL {contacts {initial {0}}} {
	set xml "<ml l=\"1\">"
	array set domains {}
	foreach contact $contacts {
		set contact [split $contact "@"]
		set user [lindex $contact 0]
		set domain [lindex $contact 1]
		lappend domains($domain) $user
	}
	foreach {domain users} [array get domains] {
		append xml "<d n=\"$domain\">"
		foreach user $users {
			append xml "<c n=\"$user\" l=\"3\" t=\"1\" />"
		}
		append xml "</d>"
	}
	append xml "</ml>"
#	set xml "<ml l=\"1\"><d n=\"hotmail.com\"><c n=\"tjikkun\" l=\"3\" t=\"1\" /></d></ml>"
	set xmllen [string length $xml]
	::MSN::WriteSBNoNL ns "ADL" "$xmllen\r\n$xml"
}

