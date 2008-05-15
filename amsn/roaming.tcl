snit::type ContentRoaming {
	# GetProfile, UpdateProfile,
	# CreateDocument, FindDocuments,
	# CreateRelationships, DeleteRelationships

	# url : "https://storage.msn.com/storageservice/SchematizedStore.asmx"

	variable affinity_cache ""

	method GetProfile { callbk {email ""}} {
		$::sso RequireSecurityToken Contacts [list $self GetProfileSSOCB $callbk $email]
	}

	method GetProfileSSOCB { callbk email ticket} {
		set request [SOAPRequest create %AUTO% \
				 -url "https://storage.msn.com/storageservice/SchematizedStore.asmx" \
				 -action "http://www.msn.com/webservices/storage/w10/GetProfile" \
				 -header [$self getCommonHeaderXML Initial $ticket] \
				 -body [$self getGetProfileBodyXML $email] \
				 -callback [list $self GetProfileCallback $callbk $email]]
		
		$request SendSOAPRequest
		
	}


	method getGetProfileBodyXML { email } {
		if {$email == "" } {
			set cid [::abook::getPersonal cid]
		} else {
			set cid [::abook::getContactData $email cid]			
		}

		# LastModified tags are set to false since we don't need those and it will
		# decrease the bandwidth used... might be set to true later if needed...
		append xml {<GetProfile xmlns="http://www.msn.com/webservices/storage/w10">}
		append xml {<profileHandle>}
		append xml {<Alias>}
		append xml {<Name>}
		append xml $cid
		append xml {</Name>}
		append xml {<NameSpace>MyCidStuff</NameSpace>}
		append xml {</Alias>}
		append xml {<RelationshipName>MyProfile</RelationshipName>}
		append xml {</profileHandle>}
		append xml {<profileAttributes><}
		append xml {ResourceID>true</ResourceID>}
		append xml {<DateModified>false</DateModified>}
		append xml {<ExpressionProfileAttributes>}
		append xml {<ResourceID>true</ResourceID>}
		append xml {<DateModified>false</DateModified>}
		append xml {<DisplayName>true</DisplayName>}
		append xml {<DisplayNameLastModified>false</DisplayNameLastModified>}
		append xml {<PersonalStatus>true</PersonalStatus>}
		append xml {<PersonalStatusLastModified>false</PersonalStatusLastModified>}
		append xml {<StaticUserTilePublicURL>true</StaticUserTilePublicURL>}
		append xml {<Photo>true</Photo>}
		append xml {<PhotoLastModified>false</PhotoLastModified>}
		append xml {<Flags>true</Flags>}
		append xml {</ExpressionProfileAttributes><}
		append xml {/profileAttributes>}
		append xml {</GetProfile>}

		return $xml
	}
	
# 	<GetProfileResponse xmlns="http://www.msn.com/webservices/storage/w10">
#             <GetProfileResult>
#                 <ResourceID>
#                   resourceid1
#                 </ResourceID>
#                 <ExpressionProfile>
#                     <ResourceID>
#                       resourceid2
#                     </ResourceID>
#                     <Flags>
#                       0
#                     </Flags>
#                     <Photo>
#                         <ItemType>
#                           Photo
#                         </ItemType>
#                         <ResourceID>
#                           resourceid3
#                         </ResourceID>
#                         <DateModified>
#                           2008-04-19T12:56:58-07:00
#                         </DateModified>
#                         <Name>
#                           dp name
#                         </Name>
#                         <DocumentStreams>
#                             <DocumentStream xsi:type="PhotoStream">
#                                 <DocumentStreamType>
#                                   UserTileStatic
#                                 </DocumentStreamType>
#                                 <MimeType>
#                                   image/jpeg
#                                 </MimeType>
#                                 <DataSize>
#                                   1924
#                                 </DataSize>
#                                 <PreAuthURL>
#                                   /url
#                                 </PreAuthURL>
#                                 <PreAuthURLPartner>
#                                   http://tkfiles.pvt-storage.msn.com/url
#                                 </PreAuthURLPartner>
#                                 <SizeX>
#                                   0
#                                 </SizeX>
#                                 <SizeY>
#                                   0
#                                 </SizeY>
#                             </DocumentStream>
#                         </DocumentStreams>
#                     </Photo>
#                     <PersonalStatus>
#                       psm
#                     </PersonalStatus>
#                     <DisplayName>
#                       nick
#                     </DisplayName>
#                     <StaticUserTilePublicURL>
#                       /url
#                     </StaticUserTilePublicURL>
#                 </ExpressionProfile>
#             </GetProfileResult>
#         </GetProfileResponse>
	method GetProfileCallback { callbk email soap } {
		set nick ""
		set psm ""
		set dp ""
		#puts [$soap GetResponse]
		if { [$soap GetStatus] == "success" } {
			set fail 0
			set xml [$soap GetResponse]
			set cache [GetXmlEntry $xml "soap:Envelope:soap:Header:AffinityCacheHeader:CacheKey"]
			if {$cache != "" } {
				set affinity_cache $cache
			}

			set result [GetXmlNode $xml "soap:Envelope:soap:Body:GetProfileResponse:GetProfileResult"]
			if {$result != "" } {
				set rid [GetXmlEntry $result "GetProfileResult:ExpressionProfile:ResourceID"]
				if {$rid != "" } {
					if {$email == "" } {
						::abook::setPersonal profile_resourceid $rid
					} else {
						::abook::setContactData $email profile_resourceid $rid
					}
				}
				set nick [GetXmlEntry $result "GetProfileResult:ExpressionProfile:DisplayName"]
				set psm [GetXmlEntry $result "GetProfileResult:ExpressionProfile:PersonalStatus"]

				# TODO : DP is more complicated.. will look at it later...
			}
			
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "ItemDoesNotExist" ||
			    $errorcode == "InvalidObjectHandle"} {
				set fail 2
			} else {
				set fail 1				
			}
		} else {
			set fail 1
		}
		
		$soap destroy
		if {[catch {eval $callbk [list $nick $psm $dp $fail]} result]} {
			bgerror $result
		}
	}

	method UpdateProfile { callbk nickname psm } {
		$::sso RequireSecurityToken Contacts [list $self UpdateProfileSSOCB $callbk $nickname $psm]
	}

	method UpdateProfileSSOCB { callbk nickname psm ticket} {
		set rid [::abook::getPersonal profile_resourceid]
		if {$rid == "" } {
			if {[catch {eval $callbk [list -1]} result]} {
				bgerror $result
			}
		} else {
			set request [SOAPRequest create %AUTO% \
					 -url "https://storage.msn.com/storageservice/SchematizedStore.asmx" \
					 -action "http://www.msn.com/webservices/storage/w10/UpdateProfile" \
					 -header [$self getCommonHeaderXML RoamingIdentityChanged $ticket] \
					 -body [$self getUpdateProfileBodyXML $rid $nickname $psm] \
					 -callback [list $self UpdateProfileCallback $callbk]]
			
			$request SendSOAPRequest
		}
		
	}

	method getUpdateProfileBodyXML { rid nickname psm } {
		append xml {<UpdateProfile xmlns="http://www.msn.com/webservices/storage/w10">}
		append xml {<profile>}
		append xml {<ResourceID>}
		append xml [xmlencode $rid]
		append xml {</ResourceID>}
		append xml {<ExpressionProfile>}
		append xml {<FreeText>Update</FreeText>}
		append xml {<DisplayName>}
		append xml [encoding convertto utf-8 [xmlencode $nickname]]
		append xml {</DisplayName>}
		append xml {<PersonalStatus>}
		append xml [encoding convertto utf-8 [xmlencode $psm]]
		append xml {</PersonalStatus>}
		append xml {<Flags>0</Flags>}
		append xml {</ExpressionProfile>}
		append xml {</profile>}
		append xml {</UpdateProfile>}

		return $xml
	}

	method UpdateProfileCallback { callbk soap } {
		#puts [$soap GetResponse]
		if { [$soap GetStatus] == "success" } {
			set fail 0			
		} elseif { [$soap GetStatus] == "fault" } { 
			set errorcode [$soap GetFaultDetail]
			if {$errorcode == "AccessDenied" } {
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

	method FindDocuments { callbk } {
		$::sso RequireSecurityToken Contacts [list $self FindDocumentsSSOCB $callbk]
	}

	method FindDocumentsSSOCB { callbk ticket} {
		set request [SOAPRequest create %AUTO% \
				 -url "https://storage.msn.com/storageservice/SchematizedStore.asmx" \
				 -action "http://www.msn.com/webservices/storage/w10/FindDocuments" \
				 -header [$self getCommonHeaderXML RoamingIdentityChanged $ticket] \
				 -body [$self getFindDocumentsBodyXML] \
				 -callback [list $self FindDocumentsCallback $callbk]]
		
		$request SendSOAPRequest
	}

	method getFindDocumentsBodyXML { } {
		set cid [::abook::getPersonal cid]

		append xml {<FindDocuments xmlns="http://www.msn.com/webservices/storage/w10">}
		append xml {<objectHandle>}
		append xml {<RelationshipName>/UserTiles</RelationshipName>}
		append xml {<Alias>}
		append xml {<Name>}
		append xml [xmlencode $cid]
		append xml {</Name>}
		append xml {<NameSpace>MyCidStuff</NameSpace>}
		append xml {</Alias>}
		append xml {</objectHandle>}
		append xml {<documentAttributes>}
		append xml {<ResourceID>true</ResourceID>}
		append xml {<Name>true</Name>}
		append xml {</documentAttributes>}
		append xml {<documentFilter>}
		append xml {<FilterAttributes>None</FilterAttributes>}
		append xml {</documentFilter>}
		append xml {<documentSort>}
		append xml {<SortBy>DateModified</SortBy>}
		append xml {</documentSort>}
		append xml {<findContext>}
		append xml {<FindMethod>Default</FindMethod>}
		append xml {<ChunkSize>25</ChunkSize>}
		append xml {</findContext>}
		append xml {</FindDocuments>}

		return $xml
	}

	method FindDocumentsCallback { callbk soap } {
		#puts [$soap GetResponse]
		if { [$soap GetStatus] == "success" } {
			set fail 0

			set xml [$soap GetResponse]
			set documents [list]
			set i 0
			while {1} {
				set subxml [GetXmlNode $xml "soap:Envelope:soap:Body:FindDocumentsResponse:FindDocumentsResult:Document" $i]
				incr i
				if  { $subxml == "" } {
					break
				}
				set rid [GetXmlEntry $subxml "Document:ResourceID"]
				set name [GetXmlEntry $subxml "Document:Name"]
				lappend documents [list $rid $name]
			}
			
		} else {
			set documents [list]
		}
		
		$soap destroy
		if {[catch {eval $callbk [list $documents]} result]} {
			bgerror $result
		}
	}

	method getCommonHeaderXML { scenario ticket } {
		if {$affinity_cache != "" } {
			append xml {<AffinityCacheHeader xmlns="http://www.msn.com/webservices/storage/w10">}
			append xml {<CacheKey>}
			append xml [xmlencode $affinity_cache]
			append xml {</CacheKey>}
			append xml {</AffinityCacheHeader>}
		}

		append xml {<StorageApplicationHeader xmlns="http://www.msn.com/webservices/storage/w10">}
		append xml {<ApplicationID>Messenger Client 8.5</ApplicationID>}
		append xml {<Scenario>}
		append xml $scenario
		append xml {</Scenario>}
		append xml {</StorageApplicationHeader>}

		append xml {<StorageUserHeader xmlns="http://www.msn.com/webservices/storage/w10">}
		append xml {<Puid>0</Puid>}
		append xml {<TicketToken>}
		append xml [xmlencode $ticket]
		append xml {</TicketToken>}
		append xml {</StorageUserHeader>}
		
		return $xml

	}
}
