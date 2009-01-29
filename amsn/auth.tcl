
::Version::setSubversionId {$Id$}

package require des

snit::type SecurityToken {
	option -name -default ""
	option -address -default ""
	option -policy -default ""
	option -type -default ""
	option -created -default ""
	option -expires -default ""
	option -ticket -default ""
	option -proof -default ""
	option -local_clock -default ""
	option -server_clock -default ""

	method IsExpired { } {
		if {$options(-ticket) == "" ||
		    $options(-local_clock) == "" ||
		    $options(-server_clock) == "" ||
		    $options(-expires) == ""} {
			return 1
		}
		set created_clock $options(-local_clock)
		set current_clock [clock seconds]
		set elapsed [expr {$current_clock - $created_clock}]
		
		set created 0
		set expires 0
		if { [regexp {(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})} $options(-server_clock) -> y m d h min s] } {
			set created [clock scan "${y}-${m}-${d} ${h}:${min}:${s}"]
		}
		if { [regexp {(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})} $options(-expires) -> y m d h min s] } {
			set expires [clock scan "${y}-${m}-${d} ${h}:${min}:${s}"]
		}
		if {$created == 0 || $expires == 0 } {
			return 1
		}
		set remaining [expr {$expires - $created}]
		if {$remaining < $elapsed} {
			return 1
		} else {
			return 0
		}
	}
}


# Single Sign-On Authentication method (used by MSNP15+)
snit::type SSOAuthentication {
	variable security_tokens
	variable soap_req ""
	variable callbacks [list]
	option -username -default ""
	option -password -default ""
	option -nonce -default ""

	constructor { args } {
		$self configurelist $args

		set security_tokens [SecurityToken create %AUTO% -name Passport -address "http://Passport.NET/tb"]

		lappend security_tokens [SecurityToken create %AUTO% -name Contacts -address "contacts.msn.com" -policy "MBI"]
		lappend security_tokens [SecurityToken create %AUTO% -name Messenger -address "messenger.msn.com" -policy "?id=507"]
		lappend security_tokens [SecurityToken create %AUTO% -name MessengerClear -address "messengerclear.live.com" -policy "MBI_KEY_OLD"]
		lappend security_tokens [SecurityToken create %AUTO% -name MessengerSecure -address "messengersecure.live.com" -policy "MBI_SSL"]
		
		lappend security_tokens [SecurityToken create %AUTO% -name Spaces -address "spaces.live.com" -policy "MBI"]
		lappend security_tokens [SecurityToken create %AUTO% -name Storage -address "storage.msn.com" -policy "MBI"]

	}

	destructor {
		catch {
			foreach token $security_tokens {
				$token destroy
			}
			set security_tokens ""
		}
		if { $soap_req != "" } {
			catch { $soap_req destroy }
			set soap_req ""
		}
		
	}

	method RequireSecurityToken { name command {full 0} } {
		set token [$self GetSecurityTokenByName $name]
		if {$token == "" || [$token IsExpired] } {
			lappend callbacks [list $name $command $full]
			$self Authenticate [list $self RequireSecurityTokenCB ]
		} else {
			if {$full} {
				eval $command [list $token]
			} else {
				eval $command [list [$token cget -ticket]]
			}
		}
	}

	method RequireSecurityTokenCB {err} {
		set clbks $callbacks 
		set callbacks [list]
		
		foreach callback $clbks {
			foreach {name command full} $callback break
			set token [$self GetSecurityTokenByName $name]
			if {$full} {
				eval $command [list $token]
			} else {
				eval $command [list [$token cget -ticket]]
			}
		}
	}

	method GetSecurityTokenByName { name } {
		foreach token $security_tokens {
			set n [$token cget -name]
			if {$n == $name } {
				return $token
			}
		}
		return ""
	}
	method GetSecurityTokenByAddress { address } {
		foreach token $security_tokens {
			set addr [$token cget -address]
			if {$addr == $address } {
				return $token
			}
		}
		return ""
	}
	
	method AuthenticateCallback { callbk soap } {
		status_log "SSO::AuthenticateCallback : $soap - [$soap GetStatus]"
		if { [$soap GetStatus] == "success" } {
			set xml  [$soap GetResponse]
			set server_clock [GetXmlAttribute $xml "S:Envelope:S:Header:psf:pp:psf:serverInfo" "ServerTime"]
			set i 0
			while {1} {
				set subxml [GetXmlNode $xml "S:Envelope:S:Body:wst:RequestSecurityTokenResponseCollection:wst:RequestSecurityTokenResponse" $i]
				incr i
				if  { $subxml == "" } {
					break
				}
			
				set address [GetXmlEntry $subxml "wst:RequestSecurityTokenResponse:wsp:AppliesTo:wsa:EndpointReference:wsa:Address"]
				set token [$self GetSecurityTokenByAddress $address]
				#puts "$subxml\n\n\n"
				if {$token != "" } {
					$token configure -type [GetXmlEntry $subxml "wst:RequestSecurityTokenResponse:wst:TokenType"]
					$token configure -created [GetXmlEntry $subxml "wst:RequestSecurityTokenResponse:wst:LifeTime:wsu:Created"]
					$token configure -expires [GetXmlEntry $subxml "wst:RequestSecurityTokenResponse:wst:LifeTime:wsu:Expires"]
					$token configure -ticket [GetXmlEntry $subxml "wst:RequestSecurityTokenResponse:wst:RequestedSecurityToken:wsse:BinarySecurityToken"]
					if {[$token cget -ticket] == "" } {
						catch {$token configure -ticket [list2xml [GetXmlNode $subxml "wst:RequestSecurityTokenResponse:wst:RequestedSecurityToken:EncryptedData"]]}
					}
					$token configure -proof [GetXmlEntry $subxml "wst:RequestSecurityTokenResponse:wst:RequestedProofToken:wst:BinarySecret"]
					$token configure -local_clock [clock seconds]
					$token configure -server_clock $server_clock

					status_log "Found security token $token for address $address" green
				}
			}
			if {[catch {eval $callbk [list 0]} result]} {
				bgerror $result
			}
		} elseif  {[$soap GetStatus] == "fault" } {
			set faultcode [$soap GetFaultCode]
			set faultstring [$soap GetFaultString]
			
			status_log "Error authenticating : $faultcode - $faultstring" green
			if {$faultcode == "wsse:FailedAuthentication" } {
				set error 2
			} elseif {$faultcode == "psf:Redirect"} {
				set xml  [$soap GetResponse]
				set url [GetXmlEntry $xml "S:Envelope:S:Fault:psf:redirectUrl"]
				status_log "SSO Authentication redirected to $url"
				$soap configure -url $url
				if {[catch {$soap SendSOAPRequest} ] } {
					set error 3
				} else {
					return
				}
			} else {
				set error 1
			}
			if {[catch {eval $callbk [list $error]} result]} {
				bgerror $result
			}
		} else {
			$soap destroy
			set soap_req ""
			if {[catch {eval $callbk [list 1]} result]} {
				bgerror $result
			}
		}
	}
	
	method Authenticate { callbk } {
		if {$soap_req != "" } {
			$soap_req destroy
			set soap_req ""
		}
		set soap_req [SOAPRequest create %AUTO% \
				  -url "https://login.live.com/RST.srf" \
				  -xml [$self getSSOXml] \
				  -callback [list $self AuthenticateCallback $callbk]]
		$soap_req SendSOAPRequest
	}
	
	method getSSOXml { args } {

		set xml {<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsse="http://schemas.xmlsoap.org/ws/2003/06/secext" xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" xmlns:wsp="http://schemas.xmlsoap.org/ws/2002/12/policy" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/03/addressing" xmlns:wssc="http://schemas.xmlsoap.org/ws/2004/04/sc" xmlns:wst="http://schemas.xmlsoap.org/ws/2004/04/trust">}

		append xml {<Header>}
		append xml {<ps:AuthInfo xmlns:ps="http://schemas.microsoft.com/Passport/SoapServices/PPCRL" Id="PPAuthInfo">}
		append xml {<ps:HostingApp>{7108E71A-9926-4FCB-BCC9-9A9D3F32E423}</ps:HostingApp>}
		append xml {<ps:BinaryVersion>4</ps:BinaryVersion>}
		append xml {<ps:UIVersion>1</ps:UIVersion>}
		append xml {<ps:Cookies></ps:Cookies>}
		append xml {<ps:RequestParams>AQAAAAIAAABsYwQAAAA0MTA1</ps:RequestParams>}
		append xml {</ps:AuthInfo>}

		append xml {<wsse:Security xmlns:wsse="http://schemas.xmlsoap.org/ws/2003/06/secext">}
		append xml {<wsse:UsernameToken Id="user">}
		append xml "<wsse:Username>[xmlencode $options(-username)]</wsse:Username>"
		append xml "<wsse:Password>[xmlencode $options(-password)]</wsse:Password>"
		append xml {</wsse:UsernameToken>}
		append xml {</wsse:Security>}
		append xml {</Header>}
		
		append xml {<Body>}
		append xml {<ps:RequestMultipleSecurityTokens xmlns:ps="http://schemas.microsoft.com/Passport/SoapServices/PPCRL" Id="RSTS">}

		set id 0
		foreach token $security_tokens {
			set address [$token cget -address]
			set policy [$token cget -policy]

			append xml "<wst:RequestSecurityToken Id=\"RST${id}\">"
			append xml {<wst:RequestType>http://schemas.xmlsoap.org/ws/2004/04/security/trust/Issue</wst:RequestType>}
			append xml {<wsp:AppliesTo>}
			append xml {<wsa:EndpointReference xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/03/addressing">}
			append xml "<wsa:Address>${address}</wsa:Address>"
			append xml {</wsa:EndpointReference>}
			append xml {</wsp:AppliesTo>}

			# The http://Passport.NET/tb token doesn't have a policy reference
			if {$policy != ""} {
				append xml "<wsse:PolicyReference xmlns:wsse=\"http://schemas.xmlsoap.org/ws/2003/06/secext\" URI=\"[xmlencode ${policy}]\">"
				append xml {</wsse:PolicyReference>}
			}
			append xml {</wst:RequestSecurityToken>}
			
			incr id
		}

		append xml {</ps:RequestMultipleSecurityTokens>}
		append xml {</Body>}
		append xml {</Envelope>}

		return $xml
	}
}


snit::type MBIAuthentication {

	typemethod MBICrypt {nonce proof } {
		set key1 [base64::decode $proof]
		set key2 [MBIAuthentication deriveKey $key1 "WS-SecureConversationSESSION KEY HASH"]
		set key3 [MBIAuthentication deriveKey $key1 "WS-SecureConversationSESSION KEY ENCRYPTION"]

		set hash [binary format H* [::sha1::hmac $key2 $nonce]]

		set iv [MBIAuthentication rand 8]
		set des_message $nonce
		append des_message [string repeat "\x08" [expr {72 - [string length $nonce]}]]
		set cipher [::DES::des -mode cbc -dir encrypt -key $key3 -iv $iv $des_message]


		set header [binary format iiH8H8iii 28 1 03660000 04800000 [string length $iv] [string length $hash] [string length $cipher]]
		set data "${iv}${hash}${cipher}"

		return [string map {"\n" ""} [base64::encode "${header}${data}"]]
	}

	typemethod deriveKey { key magic } {
		set hash1 [binary format H* [::sha1::hmac $key $magic]]
		set hash2 [binary format H* [::sha1::hmac $key "${hash1}${magic}"]]

		set hash3 [binary format H* [::sha1::hmac $key $hash1]]
		set hash4 [binary format H* [::sha1::hmac $key "${hash3}${magic}"]]
		return "${hash2}[string range $hash4 0 3]"
	}

	typemethod rand { bytes } {
		set result ""
		for {set i 0 } { $i < $bytes } { incr i } {
			append result [binary format c [expr {int(rand() * 256)}]]
		}
		return $result
	}
}

snit::type LockKeyAuthentication {
	

	method CreateLockKey {chldata prodid prodkey} {
        
                # Create an MD5 hash out of the given data, then form 32 bit integers from it
                set md5hash [::md5::md5 $chldata$prodkey]
                set md5parts [$self MD5HashToInt $md5hash]
        

                # Then create a valid productid string, divisable by 8, then form 32 bit integers from it
                set nrPadZeros [expr {8 - [string length $chldata$prodid] % 8}]
                set padZeros [string repeat 0 $nrPadZeros]
                set chlprodid [$self CHLProdToInt $chldata$prodid$padZeros]

                # Create the key we need to XOR
                set key [$self KeyFromInt $md5parts $chlprodid]

                set low 0x[string range $md5hash 0 15]
                set high 0x[string range $md5hash 16 32]
                set low [expr {$low ^ $key}]
                set high [expr {$high ^ $key}]

                set p1 [format %8.8x [expr {($low / 0x100000000) % 0x100000000}]]
                set p2 [format %8.8x [expr {$low % 0x100000000}]]
                set p3 [format %8.8x [expr {($high / 0x100000000) % 0x100000000}]]
                set p4 [format %8.8x [expr {$high % 0x100000000}]]

                return $p1$p2$p3$p4
        }

        method KeyFromInt { md5parts chlprod } {
                # Create a new series of numbers
                set key_temp 0
                set key_high 0
                set key_low 0
        
                # Then loop on the entries in the second array we got in the parameters
                for {set i 0} {$i < [llength $chlprod]} {incr i 2} {

                        # Make $key_temp zero again and perform calculation as described in the documents
                        set key_temp [lindex $chlprod $i]
                        set key_temp [expr {(wide(0x0E79A9C1) * wide($key_temp)) % wide(0x7FFFFFFF)}]
                        set key_temp [expr {wide($key_temp) + wide($key_high)}]
                        set key_temp [expr {(wide([lindex $md5parts 0]) * wide($key_temp)) + wide([lindex $md5parts 1])}]
                        set key_temp [expr {wide($key_temp) % wide(0x7FFFFFFF)}]

                        set key_high [lindex $chlprod [expr {$i+1}]]
                        set key_high [expr {(wide($key_high) + wide($key_temp)) % wide(0x7FFFFFFF)}]
                        set key_high [expr {(wide([lindex $md5parts 2]) * wide($key_high)) + wide([lindex $md5parts 3])}]
                        set key_high [expr {wide($key_high) % wide(0x7FFFFFFF)}]

                        set key_low [expr {wide($key_low) + wide($key_temp) + wide($key_high)}]
                }

                set key_high [expr {(wide($key_high) + wide([lindex $md5parts 1])) % wide(0x7FFFFFFF)}]
                set key_low [expr {(wide($key_low) + wide([lindex $md5parts 3])) % wide(0x7FFFFFFF)}]

                set key_high 0x[$self byteInvert [format %8.8X $key_high]]
                set key_low 0x[$self byteInvert [format %8.8X $key_low]]

                set long_key [expr {(wide($key_high) << 32) + wide($key_low)}]

                return $long_key
        }

        # Takes an CHLData + ProdID + Padded string and chops it in 4 bytes. Then converts to 32 bit integers 
        method CHLProdToInt { CHLProd } {
                set hexs {}
                set result {}
                while {[string length $CHLProd] > 0} {
                        lappend hexs [string range $CHLProd 0 3]
                        set CHLProd [string range $CHLProd 4 end]
                }
                for {set i 0} {$i < [llength $hexs]} {incr i} {
                        binary scan [lindex $hexs $i] H8 int
                        lappend result 0x[$self byteInvert $int]
                }
                return $result
        }
                

        # Takes an MD5 string and chops it in 4. Then "decodes" the HEX and converts to 32 bit integers. After that it ANDs
        method MD5HashToInt { md5hash } {
                binary scan $md5hash a8a8a8a8 hash1 hash2 hash3 hash4
                set hash1 [expr {"0x[$self byteInvert $hash1]" & 0x7FFFFFFF}]
                set hash2 [expr {"0x[$self byteInvert $hash2]" & 0x7FFFFFFF}]
                set hash3 [expr {"0x[$self byteInvert $hash3]" & 0x7FFFFFFF}]
                set hash4 [expr {"0x[$self byteInvert $hash4]" & 0x7FFFFFFF}]
                
                return [list $hash1 $hash2 $hash3 $hash4]
        }

        method byteInvert { hex } {
                set hexs {}
                while {[string length $hex] > 0} {
                        lappend hexs [string range $hex 0 1]
                        set hex [string range $hex 2 end]
                }
                set hex ""
                for {set i [expr [llength $hexs] -1]} {$i >= 0} {incr i -1} {
                        append hex [lindex $hexs $i]
                }
                return $hex
        }

}

