package require SOAP

if {[winfo exists .cl] == 0} {
	source contactlist.tcl
	pack [contactlist .cl] -expand true -fill both

#	Event::fireEvent groupAdded protocol online Online
#	Event::fireEvent groupAdded protocol offline Offline
}


proc getAddressbook {} {

	SOAP::create ABFindAll \
	  -uri "http://www.msn.com/webservices/AddressBook" \
	  -proxy "http://contacts.msn.com/abservice/abservice.asmx" \
	  -params {abId "" abView "" deltasOnly "" lastChange ""} \

	set d(valid) Y
	::abook::getDemographics d
	set mspauth $d(mspauth)

	set head [list "SOAPAction" "http://www.msn.com/webservices/AddressBook/ABFindAll"]
	lappend head "Cookie" "MSPAuth=$mspauth"

	SOAP::configure ABFindAll -httpheaders "$head"

	set cl [ABFindAll -headers {-subHeader ABApplicationHeader ApplicationId 09607671-1C32-421F-A6A6-CBFAA51AB5F4 IsMigration false PartnerScenario Initial -endSubHeader "" -subHeader ABAuthHeader ManagedGroupRequest false -endSubHeader ""} 00000000-0000-0000-0000-000000000000 Full false 0001-01-01T00:00:00.0000000-08:00]
	set contacts {}
	foreach { type data } $cl {
		if { $type == "contacts" } {
			foreach contact $data {
				foreach { head val } $contact {
					if { $head == "contactInfo" } {
						foreach { key value } $val {
							if { $key == "passportName" } {
								lappend contacts $value
							}
						}
					}								
				}
			}
		}
	}
	#puts contacts:$contacts
	sendADL $contacts
	foreach contact $contacts {
		Event::fireEvent contactAdded protocol {} $contact $contact psm music Offline
	}

#	set url "http://contacts.msn.com/abservice/abservice.asmx"

#	set d(valid) Y
#	::abook::getDemographics d
#	set mspauth $d(mspauth)

#	set head [list "SOAPAction" "http://www.msn.com/webservices/AddressBook/ABFindAll"]
#	lappend head [list "Content-Type" "text/xml; charset=utf-8"]
#	lappend head [list "Cookie" "MSPAuth=$mspauth"]
#	lappend head [list "Host" "contacts.msn.com"]
#	lappend head [list "Content-Length" "1045"]

#	status_log "getAddressbook: Getting $url\n" blue
#	if { [catch {::http::geturl $url -command "gotAddressbook $self [list $str]" -headers $head}] } {
#		eval [ns cget -autherror_handler]
		#msnp9_auth_error
#	}

}
#######################

proc blaat {} {
	set cl [ABFindAll -headers {-subHeader ABApplicationHeader ApplicationId 09607671-1C32-421F-A6A6-CBFAA51AB5F4 IsMigration false PartnerScenario Initial -endSubHeader "" -subHeader ABAuthHeader ManagedGroupRequest false -endSubHeader ""} 00000000-0000-0000-0000-000000000000 Full false 0001-01-01T00:00:00.0000000-08:00]
	puts $cl
	puts ---------
	set contacts {}
	foreach { type data } $cl {
		puts $type
		if { $type == "contacts" } {
			foreach contact $data {
				foreach { head val } $contact {
					puts $head
					puts val:
					puts $val
					puts |||
					if { $head == "contactInfo" } {
						foreach { key value } $val {
							if { $key == "passportName" } {
								lappend contacts $value
							}
						}
					}								
				}
			}
		}
	}
	puts contacts:$contacts
	sendADL $contacts
}

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

