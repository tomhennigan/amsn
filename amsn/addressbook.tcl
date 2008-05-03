snit::type Addressbook {
	variable contacts [list]
	variable groups [list]
	variable ab_done 0
	variable fm_done 0

	method Synchronize { callback } {
		global contactlist_loaded
		set contactlist_loaded 0
		#Make list unconsistent while receiving contact lists
		::abook::unsetConsistent

		status_log "Going to receive contact list\n" blue
		#First contact in list
		::MSN::clearList FL
		::MSN::clearList BL
		::MSN::clearList RL
		::MSN::clearList AL
		::groups::Reset
		::groups::Set 0 [trans nogroup]

		foreach username [::abook::getAllContacts] {
			#Remove user from all lists while receiving List data
			::abook::setContactData $username lists ""
		}

		$self FindMembership [list $self FindMembershipDone $callback]
		$self ABFindAll [list $self ABFindAllDone $callback]

	}

	method FindMembershipDone { callback error } {
		set fm_done 1
		if {$error } {
			if {$ab_done == 0 } {
				$self SynchronizeDone $callback $error
			}
		} else {
			if {$ab_done == 1 } {
				$self SynchronizeDone $callback $error
			}
		}
	}

	method ABFindAllDone {callback error } {
		set ab_done 1
		if {$error } {
			if {$ab_done == 0 } {
				$self SynchronizeDone $callback $error
			} 
		} else {
			if {$fm_done == 1 } {
				$self SynchronizeDone $callback $error
			}
		}
	}

	method SynchronizeDone {callback error } {
		status_log "Synchronization done"
		if {[catch {eval $callback $error} result]} {
			bgerror $result
		}
	}


	method ABContactDelete { callbk contactid } {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABContactDelete" \
				 -header [$self getCommonHeaderXML Timer] \
				 -xml [$self getABContactDeleteBodyXML $contactid] \
				 -callback [list $self ABContactDeleteCallback $callbk]]

		$request SendSOAPRequest
	}

	method ABContactDeleteCallback { callbk soap } {
		eval $callbk
	}

	method FindMembership { callbk } {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/SharingService.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/FindMembership" \
				 -header [$self getCommonHeaderXML Initial] \
				 -body [$self getFindMembershipBodyXML] \
				 -callback [list $self FindMembershipCallback $callbk]]
		$request SendSOAPRequest
	}	

	method FindMembershipCallback { callbk soap } {
		status_log "FindMembership Callback called : [$soap GetStatus] - [$soap GetLastError]"
		if { [$soap GetStatus] == "success" } {
			set xml  [$soap GetResponse]
			set i 0
			while {1} {
				set service [GetXmlNode $xml "soap:Envelope:soap:Body:FindMembershipResponse:FindMembershipResult:Services:Service" $i]
				incr i
				if {$service == "" } {
					break
				}
				set type [GetXmlEntry $service "Service:Info:Handle:Type"]
				if {$type == "Messenger" } {
					set j 0
					while {1} {
						set membership [GetXmlNode $service "Service:Memberships:Membership" $j]
						incr j
						if {$membership == "" } {
							break
						}
						set role [GetXmlEntry $membership "Membership:MemberRole"]
						if {$role == "Allow" } {
							set member_list "AL"
						} elseif { $role == "Block" } {
							set member_list "BL"
						} elseif { $role == "Reverse" } {
							set member_list "RL"
						} elseif { $role == "Pending" } {
							set member_list "PL"
						}
						set k 0
						while {1} {
							set member [GetXmlNode $membership "Membership:Members:Member" $k]
							incr k
							if {$member == ""} {
								break
							}
							set username [GetXmlEntry $member "Member:PassportName"]

							::abook::addContactToList $username $member_list 
							::MSN::addToList $member_list $username
						}

					}
				}
			}

			$soap destroy
			if {[catch {eval $callbk [list 0]} result]} {
				bgerror $result
			}
		} else {
			$soap destroy
			if {[catch {eval $callbk [list 1]} result]} {
				bgerror $result
			}
		}
	}

	

	method ABFindAll { callbk } {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABFindAll" \
				 -header [$self getCommonHeaderXML Initial] \
				 -body [$self getABFindAllBodyXML] \
				 -callback [list $self ABFindAllCallback $callbk]]

		$request SendSOAPRequest
	}

	method ABFindAllCallback { callbk soap } {
		status_log "ABFindALL Callback called : [$soap GetStatus] - [$soap GetLastError]"
		if { [$soap GetStatus] == "success" } {
			set xml  [$soap GetResponse]

			set i 0
			# can go later
			while {1} {
				set subxml [GetXmlNode $xml "soap:Envelope:soap:Body:ABFindAllResponse:ABFindAllResult:groups:Group" $i]
				incr i
				if  { $subxml == "" } {
					break
				}
				set groupId [GetXmlEntry $subxml "Group:groupId"]
				set groupName [GetXmlEntry $subxml "Group:groupInfo:name"]
				::groups::Set $groupId $groupName
			}

			set i 0
			while {1} {
				set subxml [GetXmlNode $xml "soap:Envelope:soap:Body:ABFindAllResponse:ABFindAllResult:contacts:Contact" $i]
				incr i
				if  { $subxml == "" } {
					break
				}

				set username [GetXmlEntry $subxml "Contact:contactInfo:passportName"]
				set username [string tolower $username]
				set nickname [GetXmlEntry $subxml "Contact:contactInfo:displayName"]
				set contactguid [GetXmlEntry $subxml "Contact:contactId"]
				set is_in_fl [GetXmlEntry $subxml "Contact:contactInfo:isMessengerUser"]

				set groups [list]
				set j 0
				while { 1 } {
					set group [GetXmlEntry $subxml "Contact:contactInfo:groupIds:guid" $j]
					incr j
					if {$group == "" } {
						break
					}
					lappend groups $group
				}

				if { $groups == [list] } {
					set groups 0
				}
				
				::abook::setContactData $username nick $nickname
				::abook::setContactData $username contactguid $contactguid
				::abook::setContactForGuid $contactguid $username

				if {$is_in_fl } {
					
					::abook::addContactToList $username "FL"
					::MSN::addToList "FL" $username

					::abook::setContactData $username group $groups
					::abook::setVolatileData $username state "FLN"
				}

			}

			$soap destroy
			if {[catch {eval $callbk [list 0]} result]} {
				bgerror $result
			}

		} else {
			$soap destroy
			if {[catch {eval $callbk [list 1]} result]} {
				bgerror $result
			}
		}
			
	}


	method getCommonHeaderXML { scenario } {
		set token [$::sso GetSecurityTokenByName Contacts]
		set mspauth [$token cget -ticket]

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

		return $xml

	}
	method getABFindAllBodyXML {  } {
		set xml {<ABFindAll xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<abView>Full</abView>}
		append xml {<deltasOnly>false</deltasOnly>}
		append xml {<lastChange>0001-01-01T00:00:00.0000000-08:00</lastChange>}
		append xml {</ABFindAll>}

		return $xml
	}

	method getFindMembershipBodyXML {  } {
		append xml {<FindMembership xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<serviceFilter xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<Types xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<ServiceType xmlns="http://www.msn.com/webservices/AddressBook">Messenger</ServiceType>}
		append xml {</Types>}
		append xml {</serviceFilter>}
		append xml {<View xmlns="http://www.msn.com/webservices/AddressBook">Full</View>}
		append xml {<deltasOnly xmlns="http://www.msn.com/webservices/AddressBook">false</deltasOnly>}
		append xml {<lastChange xmlns="http://www.msn.com/webservices/AddressBook">2006-03-29T07:29:42.5200000-08:00</lastChange>}
		append xml {</FindMembership>}

		return $xml
	}

	method getABContactDeleteBodyXML { contactid } {
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

}

#######################
