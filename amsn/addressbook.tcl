
::Version::setSubversionId {$Id$}

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
		::MSN::clearList EL
		::MSN::clearList BL
		::MSN::clearList RL
		::MSN::clearList AL
		::groups::Reset
		::groups::Set 0 [trans nogroup]

		foreach username [::abook::getAllContacts] {
			#Remove user from all lists while receiving List data
			::abook::setContactData $username lists ""
		}

		set ab_done 0
		set fm_done 0

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
			if {$fm_done == 0 } {
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
		::MSN::contactListChanged
		if {[catch {eval $callback $error} result]} {
			bgerror $result
		}
	}

	method FindMembership { callbk} {
		$::sso RequireSecurityToken Contacts [list $self FindMembershipSSOCB $callbk]
	}

	method FindMembershipSSOCB {callbk ticket} {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/SharingService.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/FindMembership" \
				 -header [$self getCommonHeaderXML Initial $ticket] \
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
							update
							set member [GetXmlNode $membership "Membership:Members:Member" $k]
							incr k
							if {$member == ""} {
								break
							}
							set username [GetXmlEntry $member "Member:PassportName"]
							set username [string tolower $username]

							if {$username == "" } {
								continue
							}

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
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "ABDoesNotExist" } {
				$soap destroy
				if {[catch {eval $callbk [list 2]} result]} {
					bgerror $result
				}
			} else {
				$soap destroy
				if {[catch {eval $callbk [list 1]} result]} {
					bgerror $result
				}
			}
		} else { 
			$soap destroy
			if {[catch {eval $callbk [list 1]} result]} {
				bgerror $result
			}
		}
	}

	

	method ABFindAll { callbk} {
		$::sso RequireSecurityToken Contacts [list $self ABFindAllSSOCB $callbk]
	}

	method ABFindAllSSOCB { callbk ticket } {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABFindAll" \
				 -header [$self getCommonHeaderXML Initial $ticket] \
				 -body [$self getABFindAllBodyXML] \
				 -callback [list $self ABFindAllCallback $callbk]]

		$request SendSOAPRequest
	}

	method ABFindAllCallback { callbk soap } {
		status_log "ABFindALL Callback called : [$soap GetStatus] - [$soap GetLastError]"
		if { [$soap GetStatus] == "success" } {
			set xml  [$soap GetResponse]

			set ownercid [GetXmlEntry $xml "soap:Envelope:soap:Body:ABFindAllResponse:ABFindAllResult:ab:abInfo:OwnerCID"]
			if {$ownercid != "" } {
				::abook::setPersonal cid $ownercid
			}

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
				update
				set subxml [GetXmlNode $xml "soap:Envelope:soap:Body:ABFindAllResponse:ABFindAllResult:contacts:Contact" $i]
				incr i
				if  { $subxml == "" } {
					break
				}

				set username [GetXmlEntry $subxml "Contact:contactInfo:passportName"]
				set username [string tolower $username]
				set nickname [GetXmlEntry $subxml "Contact:contactInfo:displayName"]
				set contactguid [GetXmlEntry $subxml "Contact:contactId"]
				set contacttype [GetXmlEntry $subxml "Contact:contactInfo:contactType"]
				set cid [GetXmlEntry $subxml "Contact:contactInfo:CID"]
				set is_in_fl [GetXmlEntry $subxml "Contact:contactInfo:isMessengerUser"]
				set is_mobile [GetXmlEntry $subxml "Contact:contactInfo:isMobileIMEnabled"]

				# This is a generic addressbook so we can have in it contacts that have no passport..
				# These can be phone numbers or just emails without anything more associated to them...  
				if {$username == ""} {
					continue
				}

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

				set j 0
				while { 1 } {
					set phone_type [GetXmlEntry $subxml "Contact:contactInfo:phones:ContactPhone:contactPhoneType" $j]
					set phone_number [GetXmlEntry $subxml "Contact:contactInfo:phones:ContactPhone:number" $j]
					incr j
					if {$phone_type == "" } {
						break
					}

					if {$phone_type == "ContactPhonePersonal" } {
						if {$contacttype == "Me" } {
							::abook::setPersonal PHH $phone_number							
						} else {
							::abook::setContactData $username PHH $phone_number
						}
					} elseif {$phone_type == "ContactPhoneBusiness" } {
						if {$contacttype == "Me" } {
							::abook::setPersonal PHW $phone_number							
						} else {
							::abook::setContactData $username PHW $phone_number
						}
					} elseif {$phone_type == "ContactPhoneMobile"} {
						if {$contacttype == "Me" } {
							::abook::setPersonal PHM $phone_number							
						} else {
							::abook::setContactData $username PHM $phone_number
						}

					}
				}
			       
				if {$contacttype == "Me" } {
					set j 0
					while { 1 } {
						set annotation_k [GetXmlEntry $subxml "Contact:contactInfo:annotations:Annotation:Name" $j]
						set annotation_v [GetXmlEntry $subxml "Contact:contactInfo:annotations:Annotation:Value" $j]
						incr j
						if {$annotation_k == "" } {
							break
						}

						if {$annotation_k == "MSN.IM.BLP" } {
							global list_BLP
							set list_BLP annotation_v
						} elseif {$annotation_k == "MSN.IM.MPOP" } {
							::abook::setPersonal MPOP $annotation_v
						}
					}
				}
			       
				if {$contacttype == "Me" } {
					::abook::setPersonal info_lastchange [GetXmlEntry $subxml "Contact:lastChange"]
					::abook::setPersonal MFN $nickname
					::abook::setPersonal login $username
					::abook::setPersonal cid $cid
				} else {
					::abook::setContactData $username nick $nickname
					::abook::setContactData $username contactguid $contactguid
					::abook::setContactData $username cid $cid
					::abook::setContactForGuid $contactguid $username
				}

				if {$is_mobile} {
					set is_mobile Y
				} else {
					set is_mobile N
				}
				if {$contacttype == "Me" } {
					::abook::setPersonal MOB $is_mobile
					continue
				} else {
					::abook::setContactData $username MOB $is_mobile
				}

				if {$is_in_fl } {
					::abook::addContactToList $username "FL"
					::MSN::addToList "FL" $username
				} else {
					::abook::addContactToList $username "EL"
					::MSN::addToList "EL" $username
				}
				
				::abook::setContactData $username group $groups
				if {[::abook::getVolatileData $username state] == ""} {
					::abook::setVolatileData $username state "FLN"
				}

			}

			set i 0
			set users_with_space [list]
			while {1} {
				set subxml [GetXmlNode $xml "soap:Envelope:soap:Body:ABFindAllResponse:ABFindAllResult:DynamicItems:DynamicItem" $i]
				incr i
				if  { $subxml == "" } {
					break
				}
				set username [GetXmlEntry $subxml "DynamicItem:PassportName"]
				set username [string tolower $username]
				set space_status [GetXmlEntry $subxml "DynamicItem:SpaceStatus"]
				set last_modified [GetXmlEntry $subxml "DynamicItem:SpaceLastChanged"]
				set last_viewed [GetXmlEntry $subxml "DynamicItem:SpaceLastViewed"]
				set has_new [GetXmlEntry $subxml "DynamicItem:SpaceGleam"]
				set cid [GetXmlEntry $subxml "DynamicItem:CID"]

				set has_space 0
				foreach status [split $space_status " "] {
					if {$status == "Access" } {
						set has_space 1
					}
				}
				if {$has_space } {
					set last_modif 0
					if { [regexp {(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})} $last_modified -> y m d h min s] } {
						set last_modif [clock scan "${y}-${m}-${d} ${h}:${min}:${s}"]
					}
					# Apparently, we could receive a 'spacegleam' to 'false' but the lastviewed is < last_modified, and WLM
					# still shows the gleam...
					set last_view 0
					if { [regexp {(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})} $last_viewed -> y m d h min s] } {
						set last_view [clock scan "${y}-${m}-${d} ${h}:${min}:${s}"]
					}
					if {$last_modif > $last_view} {
						set has_new "true"
					}
					::abook::setContactData $username space_access 1
					if {$has_new == "true" } {
						::abook::setVolatileData $username space_updated 1
						::abook::setContactData $username spaces_info_xml [list]
						::abook::setContactData $username spaces_last_modif $last_modif
					} else {
						::abook::setVolatileData $username space_updated 0
						
						# Reset the known info if the last modified date has changed,
						# this means that the user fetched the spaces info from another client
						set old_date [::abook::getContactData $username spaces_last_modif 0]
						if { $last_modif > $old_date } {
							::abook::setContactData $username spaces_info_xml [list]
							::abook::setContactData $username spaces_last_modif $last_modif
						}
					}
				} else {
					::abook::setContactData $username space_access 0
				}
				::abook::setContactData $username cid $cid				
			}
			if {$users_with_space != [list] } {
				#fire event to redraw contacts with changed space
				::Event::fireEvent contactSpaceChange protocol $users_with_space
			}

			$soap destroy
			if {[catch {eval $callbk [list 0]} result]} {
				bgerror $result
			}

		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "ABDoesNotExist" } {
				$soap destroy
				if {[catch {eval $callbk [list 2]} result]} {
					bgerror $result
				}
			} else {
				$soap destroy
				if {[catch {eval $callbk [list 1]} result]} {
					bgerror $result
				}
			}
		} else {
			$soap destroy
			if {[catch {eval $callbk [list 1]} result]} {
				bgerror $result
			}
		}
			
	}



	method getABFindAllBodyXML {  } {
		set xml {<ABFindAll xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<abView>Full</abView>}
		append xml {<deltasOnly>false</deltasOnly>}
		append xml {<dynamicItemView>Gleam</dynamicItemView>}
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

	#########################MSNP15 SUPPORT by Takeshi###################################
	###############################ABAdd#################################################

	#Create an Addressbook Template
	method ABAdd { callbk email } {
		$::sso RequireSecurityToken Contacts [list $self ABAddSSOCB $callbk $email]
	}

	method ABAddSSOCB { callbk email ticket } {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABAdd" \
				 -header [$self getCommonHeaderXML Initial $ticket] \
				 -body [$self getABAddBodyXML $email] \
				 -callback [list $self ABAddCallback $callbk]]
		
		$request SendSOAPRequest
	
		
	}
	
	method getABAddBodyXML {email } {
		append xml {<ABAdd xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abInfo>}
		append xml {<name/>}
		append xml {<ownerPuid>0</ownerPuid>}
		append xml {<ownerEmail>}
		append xml $email
		append xml {</ownerEmail>}
		append xml {<fDefault>true</fDefault>}
		append xml {</abInfo>}
		append xml {</ABAdd>}

		return $xml
	}
	
	method ABAddCallback { callbk soap} {
		if { [$soap GetStatus] == "success" } {
			set fail 0
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "ABAlreadyExists" } {
				set fail 2
			} else {
				set fail 1				
			}
		} else {
			set fail 1
		}
		
		$soap destroy
		if {[catch {eval $callbk [list $fail]} result]} {
			bgerror $result
		}
	}


	###########################Add a contact#############################################
	
	method ABContactAdd { callbk email {yahoo 0}} {
		$::sso RequireSecurityToken Contacts [list $self ABContactAddSSOCB $callbk $email $yahoo]
	}

	method ABContactAddSSOCB { callbk email yahoo ticket} {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABContactAdd" \
				 -header [$self getCommonHeaderXML ContactSave $ticket] \
				 -body [$self getABContactAddBodyXML $email $yahoo] \
				 -callback [list $self ABContactAddCallback $callbk]]
		
		$request SendSOAPRequest
	
		
	}

	method getABContactAddBodyXML { email yahoo } {
		append xml {<ABContactAdd xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<contacts>}
		append xml {<Contact xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<contactInfo>}

		if {$yahoo} {
			append xml {<isMessengerUser>false</isMessengerUser>}
			append xml {<contactType>Regular</contactType>}
			append xml {<isMessengerEnabled>true</isMessengerEnabled>}
			append xml {<contactEmailType>account</contactEmailType>}
			append xml {<email>}
			append xml $email
			append xml {</email>}
		} else {
			append xml {<passportName>}
			append xml $email
			append xml {</passportName>}
			append xml {<isMessengerUser>true</isMessengerUser>}
			append xml {<contactType>LivePending</contactType>}
		}

		append xml {<MessengerMemberInfo>}
		append xml {<PendingAnnotations>}
		append xml {<Annotation>}
		append xml {<Name>MSN.IM.InviteMessage</Name>}
		append xml {<Value></Value>}
		append xml {</Annotation>}
		append xml {</PendingAnnotations>}
		append xml {</MessengerMemberInfo>}
		append xml {</contactInfo>}
		append xml {</Contact>}
		append xml {</contacts>}
		append xml {<options>}
		append xml {<EnableAllowListManagement>true</EnableAllowListManagement>}
		append xml {</options>}
		append xml {</ABContactAdd>}
		
		return $xml	
	}

	method ABContactAddCallback { callbk soap } {
		set guid ""
		if { [$soap GetStatus] == "success" } {
			set fail 0
			set xml [$soap GetResponse]
			set guid [GetXmlEntry $xml "soap:Envelope:soap:Body:ABContactAddResponse:ABContactAddResult:guid"]
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "ContactAlreadyExists" } {
				set xml [$soap GetResponse]
				set guid [string tolower [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:detail:additionalDetails:conflictObjectId"]]
				set fail 2
			} elseif {$errorcode == "InvalidPassportUser" } {
				set fail 3
			} elseif {$errorcode == "BadEmailArgument" } {
				set fail 4
			} elseif {$errorcode == "RequestLimitReached" } {
				set fail 5
			} else {
				set fail 1				
			}
		} else {
			set fail 1
		}
		
		$soap destroy
		if {[catch {eval $callbk [list $guid $fail]} result]} {
			bgerror $result
		}
	}

	#################Delete a contact#####################################
	#Delete a contact from both MSNAB and CL
	method ABContactDelete { callbk email} {
		$::sso RequireSecurityToken Contacts [list $self ABContactDeleteSSOCB $callbk $email]
	}

	method ABContactDeleteSSOCB { callbk email ticket} {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABContactDelete" \
				 -header [$self getCommonHeaderXML Timer $ticket] \
				 -body [$self getABContactDeleteBodyXML $email] \
				 -callback [list $self ABContactDeleteCallback $callbk]]
		
		$request SendSOAPRequest
		
	}


	method getABContactDeleteBodyXML { email } {
		set guid [::abook::getContactData $email contactguid]		
		append xml {<ABContactDelete xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<contacts>}
		append xml {<Contact>}
		append xml {<contactId>}
		append xml $guid
		append xml {</contactId>}
		append xml {</Contact>}
		append xml {</contacts>}
		append xml {</ABContactDelete>}

		return $xml
	}
		
	method ABContactDeleteCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
			set fail 0
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "ContactDoesNotExist" } {
				set fail 2
			} else {
				set fail 1				
			}
		} else {
			set fail 1
		}
		
		$soap destroy
		if {[catch {eval $callbk [list $fail]} result]} {
			bgerror $result
		}
	}
	
	########################AB Contact Update#########################################
	#update information for contact Type /possibly DisplayName
	#Accepted values are Regular Live LivePending LiveRejected LiveDropped Messenger2
	 
	method ABContactUpdate { callbk email changes properties } {
		$::sso RequireSecurityToken Contacts [list $self ABContactUpdateSSOCB $callbk $email $changes $properties]
	}

	method ABContactUpdateSSOCB { callbk email changes properties ticket} {
		set request [SOAPRequest create %AUTO% \
				-url "https://contacts.msn.com/abservice/abservice.asmx" \
				-action "http://www.msn.com/webservices/AddressBook/ABContactUpdate" \
				-header [$self getCommonHeaderXML BlockUnblock $ticket] \
				-body [$self getABContactUpdateBodyXML $email $changes $properties] \
				-callback [list $self ABContactUpdateCallback $callbk]]

		$request SendSOAPRequest
	}
	
	method getABContactUpdateBodyXML { email changes properties} {
		append xml {<ABContactUpdate xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<contacts>}
		append xml {<Contact xmlns="http://www.msn.com/webservices/AddressBook">}
		if {$email != ""} {
			append xml {<contactId>}
			append xml [::abook::getContactData $email contactguid]
			append xml {</contactId>}
		}
		append xml {<contactInfo>}
		foreach {tag value} $changes {
			append xml "<$tag>$value</$tag>"
		}
		append xml {</contactInfo>}
		append xml {<propertiesChanged>}
		append xml [join $properties " "]
		append xml {</propertiesChanged>}
		append xml {</Contact>}
		append xml {</contacts>}
		append xml {</ABContactUpdate>}
		
		return $xml
	}
	
	method ABContactUpdateCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
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
	
	################################Add Member##################################
	#Used for Allow Block
	
	method AddMember { callbk scenario email role } {
		$::sso RequireSecurityToken Contacts [list $self AddMemberSSOCB $callbk $scenario $email $role]
	}

	method AddMemberSSOCB { callbk scenario email role ticket } {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/SharingService.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/AddMember" \
				 -header [$self getCommonHeaderXML $scenario $ticket] \
				 -body [$self getAddMemberBodyXML $email $role] \
				 -callback [list $self AddMemberCallback $callbk]]

		$request SendSOAPRequest
	}
	
	method getAddMemberBodyXML { email role } {
		append xml {<AddMember xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<serviceHandle>}
		append xml {<Id>0</Id>}
		if {$role == "ProfileExpression" } {
			append xml {<Type>Profile</Type>}
			append xml {<ForeignId>MyProfile</ForeignId>}
		} else {
			append xml {<Type>Messenger</Type>}
			append xml {<ForeignId></ForeignId>}
		}
		append xml {</serviceHandle>}
		append xml {<memberships>}
		append xml {<Membership>}
		append xml {<MemberRole>}
		append xml $role
		append xml {</MemberRole>}
		append xml {<Members>}
		if {$role == "ProfileExpression" } {
			append xml {<Member xsi:type="RoleMember" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">}
			append xml {<Type>Role</Type>}
			append xml {<State>Accepted</State>}
			append xml {<Id>Allow</Id>}
			append xml {<DefiningService>}
			append xml {<Id>0</Id>}
			append xml {<Type>Messenger</Type>}
			append xml {<ForeignId></ForeignId>}
			append xml {</DefiningService>}
			append xml {<MaxRoleRecursionDepth>0</MaxRoleRecursionDepth>}
			append xml {<MaxDegreesSeparationDepth>0</MaxDegreesSeparationDepth>}
			append xml {</Member>}
		} else {
			foreach member $email {
				append xml {<Member xsi:type="PassportMember">}
				append xml {<Type>Passport</Type>}
				append xml {<State>Accepted</State>}
				append xml {<Deleted>false</Deleted>}
				append xml {<PassportName>}
				append xml $member
				append xml {</PassportName>}
				append xml {</Member>}
			}
		}
		append xml {</Members>}
		append xml {</Membership>}
		append xml {</memberships>}
		append xml {</AddMember>}
		
		return $xml
	}
	
	method AddMemberCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
			set fail 0
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "MemberAlreadyExists" } {
				set fail 2
			} else {
				set fail 1				
			}
		} else {
			set fail 1
		}
		
		$soap destroy
		if {[catch {eval $callbk [list $fail]} result]} {
			bgerror $result
		}
	}

	########################Delete Member###########################################
	#Used for Allow Block
	method DeleteMember { callbk scenario email role} {
		$::sso RequireSecurityToken Contacts [list $self DeleteMemberSSOCB $callbk $scenario $email $role]
	}

	method DeleteMemberSSOCB { callbk scenario email role ticket } {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/SharingService.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/DeleteMember" \
				 -header [$self getCommonHeaderXML $scenario $ticket] \
				 -body [$self getDeleteMemberBodyXML $email $role] \
				 -callback [list $self DeleteMemberCallback $callbk]]

		$request SendSOAPRequest
	}
	
	method getDeleteMemberBodyXML { email role } {
		
		append xml {<DeleteMember xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<serviceHandle>}
		append xml {<Id>0</Id>}
		if {$role == "ProfileExpression" } {
			append xml {<Type>Profile</Type>}
			append xml {<ForeignId>MyProfile</ForeignId>}
		} else {
			append xml {<Type>Messenger</Type>}
			append xml {<ForeignId></ForeignId>}
		}
		append xml {</serviceHandle>}
		append xml {<memberships>}
		append xml {<Membership>}
		append xml {<MemberRole>}
		append xml $role
		append xml {</MemberRole>}
		append xml {<Members>}
		if {$role == "ProfileExpression" } {
			append xml {<Member xsi:type="RoleMember" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">}
			append xml {<Type>Role</Type>}
			append xml {<State>Accepted</State>}
			append xml {<Id>Allow</Id>}
			append xml {<DefiningService>}
			append xml {<Id>0</Id>}
			append xml {<Type>Messenger</Type>}
			append xml {<ForeignId></ForeignId>}
			append xml {</DefiningService>}
			append xml {<MaxRoleRecursionDepth>0</MaxRoleRecursionDepth>}
			append xml {<MaxDegreesSeparationDepth>0</MaxDegreesSeparationDepth>}
			append xml {</Member>}
		} else {
			foreach member $email {
				append xml {<Member xsi:type="PassportMember">}
				append xml {<Type>Passport</Type>}
				append xml {<State>Accepted</State>}
				append xml {<PassportName>}
				append xml $member
				append xml {</PassportName>}
				append xml {</Member>}
			}
		}
		append xml {</Members>}
		append xml {</Membership>}
		append xml {</memberships>}
		append xml {</DeleteMember>}
		
		return $xml
	}
	
	method DeleteMemberCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
			set fail 0
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "MemberDoesNotExist" } {
				set fail 2
			} else {
				set fail 1				
			}
		} else {
			set fail 1
		}
		
		$soap destroy
		if {[catch {eval $callbk [list $fail]} result]} {
			bgerror $result
		}
	}

	########################Member Update#############################################
	#Allow Block Reverse Pending 
	#Must be fixed and should be used instead of delete add 
	method UpdateMember { callbk contactid role cstate deleted } {
		$::sso RequireSecurityToken Contacts [list $self UpdateMemberSSOCB $callbk $contactid $role $cstate $deleted]
	}

	method UpdateMemberSSOCB { callbk contactid role cstate deleted ticket } {
		set request [SOAPRequest create %AUTO% \
				 -url "https://contacts.msn.com/abservice/SharingService.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/UpdateMember" \
				 -header [$self getCommonHeaderXML ContactSave $ticket] \
				 -body [$self getUpdateMemberBodyXML $contactid $role $cstate $deleted] \
				 -callback [list $self UpdateMemberCallback $callbk]]

		$request SendSOAPRequest
	}
	
	method getUpdateMemberBodyXML { contactid role cstate deleted } {
		append xml {<UpdateMember xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<serviceHandle><Id>0</Id><Type>Messenger</Type><ForeignId></ForeignId></serviceHandle>}
		append xml {<memberships><Membership><MemberRole>}
		append xml $role
		append xml {</MemberRole>}
		append xml {<propertiesChanged/>}
		append xml {Changes}
		append xml {<Members>}
		append xml {<Member xsi:type="PassportMember">}
		append xml {<Type>Passport</Type>}
		#append xml {<State>}
		#append xml $cstate
		#append xml {</State>}
		#append xml {<Deleted>}
		#append xml $deleted
		#append xml {</Deleted>}
		append xml {<PassportName>}
		append xml $contactid
		append xml {</PassportName>}
		append xml {</Member>}
		append xml {</Members>}
		append xml {</Membership>}
		#append xml {<propertiesChanged>MemberRole</propertiesChanged>}
		append xml {</memberships>}
		append xml {</UpdateMember>}

		return $xml
	}
	
	method UpdateMemberCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
			$callbk $contactid
			$soap destroy
		} else {
			$soap destroy
		}
	}

	#######################Create a Group#################################################
	
	method ABGroupAdd { callbk groupname} {
		$::sso RequireSecurityToken Contacts [list $self ABGroupAddSSOCB $callbk $groupname]
	}

	method ABGroupAddSSOCB { callbk groupname ticket } {
		set request [SOAPRequest create %AUTO% \
				 -url "http://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABGroupAdd" \
				 -header [$self getCommonHeaderXML GroupSave $ticket] \
				 -body [$self getABGroupAddBodyXML $groupname] \
				 -callback [list $self ABGroupAddCallback $callbk]]
		$request SendSOAPRequest
	}
	
	method getABGroupAddBodyXML { groupname } {
		append xml {<ABGroupAdd xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<groupAddOptions>}
		append xml {<fRenameOnMsgrConflict>false</fRenameOnMsgrConflict>}
		append xml {</groupAddOptions>}
		append xml {<groupInfo>}
		append xml {<GroupInfo>}
		append xml {<name>}
		append xml [xmlencode $groupname]
		append xml {</name>}
		append xml {<groupType>C8529CE2-6EAD-434d-881F-341E17DB3FF8</groupType>}
		append xml {<fMessenger>false</fMessenger>}
		append xml {<annotations>}
		append xml {<Annotation>}
		append xml {<Name>MSN.IM.Display</Name>}
		append xml {<Value>1</Value>}
		append xml {</Annotation>}
		append xml {</annotations>}
		append xml {</GroupInfo>}
		append xml {</groupInfo>}
		append xml {</ABGroupAdd>}

		return $xml
	}
	
	method ABGroupAddCallback { callbk soap } {
		set guid ""
		if { [$soap GetStatus] == "success" } {
			set xml [$soap GetResponse]
			set fail 0
			set guid [GetXmlEntry $xml "soap:Envelope:soap:Body:ABGroupAddResponse:ABGroupAddResult:guid"]
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "GroupAlreadyExists" } {
				set xml [$soap GetResponse]
				set guid [string tolower [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:detail:additionalDetails:conflictObjectId"]]
				set fail 2
			} else {
				set fail 1
			}
		} else {
			set fail 1
		}

		$soap destroy
		if {[catch {eval $callbk [list $guid $fail]} result]} {
			bgerror $result
		}
	}	
	############################Remove a Group#################################################
	method ABGroupDelete { callbk gid } {
		$::sso RequireSecurityToken Contacts [list $self ABGroupDeleteSSOCB $callbk $gid]
	}

	method ABGroupDeleteSSOCB { callbk gid ticket} {
		set request [SOAPRequest create %AUTO% \
				 -url "http://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABGroupDelete" \
				 -header [$self getCommonHeaderXML GroupSave $ticket] \
				 -body [$self getABGroupDeleteBodyXML $gid] \
				 -callback [list $self ABGroupDeleteCallback $callbk]]
		$request SendSOAPRequest
		
	}
	
	method getABGroupDeleteBodyXML { gid } {
		append xml {<ABGroupDelete xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<groupFilter>}
		append xml {<groupIds>}
		append xml {<guid>}
		append xml $gid
		append xml {</guid>}
		append xml {</groupIds>}
		append xml {</groupFilter>}
		append xml {</ABGroupDelete>}
		
		return $xml
		
	}
	
	method ABGroupDeleteCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
			set fail 0
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "GroupDoesNotExist" } {
				set fail 2
			} else {
				set fail 1
			}
		} else {
			set fail 1
		}

		$soap destroy
		if {[catch {eval $callbk [list $fail]} result]} {
			bgerror $result
		}
	}


	##########################Rename a Group#####################################################
	method ABGroupUpdate { callbk gid newname } {
		$::sso RequireSecurityToken Contacts [list $self ABGroupUpdateSSOCB $callbk $gid $newname]
	}

	method ABGroupUpdateSSOCB { callbk gid newname ticket } {
		set request [SOAPRequest create %AUTO% \
				 -url "http://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABGroupUpdate" \
				 -header [$self getCommonHeaderXML GroupSave $ticket] \
				 -body [$self getABGroupUpdateBodyXML $gid $newname] \
				 -callback [list $self ABGroupUpdateCallback $callbk]]
		$request SendSOAPRequest
	}
	
	method getABGroupUpdateBodyXML { gid newname } {
		
		append xml {<ABGroupUpdate xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<groups>}
		append xml {<Group>}
		append xml {<groupId>}
		append xml $gid
		append xml {</groupId>}
		append xml {<groupInfo>}
		append xml {<name>}
		append xml [xmlencode $newname]
		append xml {</name>}
		append xml {</groupInfo>}
		append xml {<propertiesChanged>GroupName</propertiesChanged>}
		append xml {</Group>}
		append xml {</groups>}
		append xml {</ABGroupUpdate>}

		return $xml
	}
	
	method ABGroupUpdateCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
			set fail 0
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "GroupDoesNotExist" } {
				set fail 2
			} else {
				set fail 1
			}
		} else {
			set fail 1
		}

		$soap destroy
		if {[catch {eval $callbk [list $fail]} result]} {
			bgerror $result
		}
	}
	
	########################Add a contact to a group###############################
	method ABGroupContactAdd { callbk gid cid } {
		$::sso RequireSecurityToken Contacts [list $self ABGroupContactAddSSOCB $callbk $gid $cid]
	}

	method ABGroupContactAddSSOCB { callbk gid cid ticket } {
		set request [SOAPRequest create %AUTO% \
				 -url "http://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABGroupContactAdd" \
				 -header [$self getCommonHeaderXML GroupSave $ticket] \
				 -body [$self getABGroupContactAddBodyXML $gid $cid] \
				 -callback [list $self ABGroupContactAddCallback $callbk]]
		$request SendSOAPRequest
	}
	
	method getABGroupContactAddBodyXML { gid cid } {
		append xml {<ABGroupContactAdd xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<groupFilter>}
		append xml {<groupIds>}
		append xml {<guid>}
		append xml $gid
		append xml {</guid>}
		append xml {</groupIds>}
		append xml {</groupFilter>}
		append xml {<contacts>}
		append xml {<Contact>}
		append xml {<contactId>}
		append xml $cid
		append xml {</contactId>}
		append xml {</Contact>}
		append xml {</contacts>}
		append xml {</ABGroupContactAdd>}

		return $xml
	}
	
	method ABGroupContactAddCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
			set fail 0
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "ContactDoesNotExist" } {
				set fail 2
			} elseif {$errorcode == "GroupDoesNotExist" } {
				set fail 3
			} else {
				set fail 1
			}
		} else {
			set fail 1
		}

		$soap destroy
		if {[catch {eval $callbk [list $fail]} result]} {
			bgerror $result
		}
	}

	##################Remove a contact from a Group##############################################
	method ABGroupContactDelete { callbk gid cid } {
		$::sso RequireSecurityToken Contacts [list $self ABGroupContactDeleteSSOCB $callbk $gid $cid]
	}

	method ABGroupContactDeleteSSOCB { callbk gid cid ticket } {
		set request [SOAPRequest create %AUTO% \
				 -url "http://contacts.msn.com/abservice/abservice.asmx" \
				 -action "http://www.msn.com/webservices/AddressBook/ABGroupContactDelete" \
				 -header [$self getCommonHeaderXML GroupSave $ticket] \
				 -body [$self getABGroupContactDeleteBodyXML $gid $cid] \
				 -callback [list $self ABGroupContactDeleteCallback $callbk]]
		$request SendSOAPRequest
	}
	
	method getABGroupContactDeleteBodyXML { gid cid } {
		append xml {<ABGroupContactDelete xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<abId>00000000-0000-0000-0000-000000000000</abId>}
		append xml {<contacts>}
		append xml {<Contact>}
		append xml {<contactId>}
		append xml $cid
		append xml {</contactId>}
		append xml {</Contact>}
		append xml {</contacts>}
		append xml {<groupFilter>}
		append xml {<groupIds>}
		append xml {<guid>}
		append xml $gid
		append xml {</guid>}
		append xml {</groupIds>}
		append xml {</groupFilter>}
		append xml {</ABGroupContactDelete>}

		return $xml
	}
	
	method ABGroupContactDeleteCallback { callbk soap } {
		if { [$soap GetStatus] == "success" } {
			set fail 0
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "ContactDoesNotExist" } {
				set fail 2
			} elseif {$errorcode == "GroupDoesNotExist" } {
				set fail 3
			} else {
				set fail 1
			}
		} else {
			set fail 1
		}

		$soap destroy
		if {[catch {eval $callbk [list $fail]} result]} {
			bgerror $result
		}
		
	}
	################################Common Header####################################
	
	
	method getCommonHeaderXML { scenario ticket } {
		append xml {<ABApplicationHeader xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<ApplicationId xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {996CDE1E-AA53-4477-B943-2BE802EA6166}
		append xml {</ApplicationId>}
		append xml {<IsMigration xmlns="http://www.msn.com/webservices/AddressBook">false</IsMigration>}
		append xml {<PartnerScenario xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml $scenario
		append xml {</PartnerScenario>}
		append xml {</ABApplicationHeader>}
		append xml {<ABAuthHeader xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {<ManagedGroupRequest xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml {false}
		append xml {</ManagedGroupRequest>}
		append xml {<TicketToken xmlns="http://www.msn.com/webservices/AddressBook">}
		append xml [xmlencode $ticket]
		append xml {</TicketToken>}
		append xml {</ABAuthHeader>}
		
		return $xml

	}
}
#######################
