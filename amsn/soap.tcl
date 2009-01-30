
::Version::setSubversionId {$Id$}


package require snit

snit::type SOAPRequest {
	
	option -url ""
	option -action ""
	option -xml ""
	option -callback ""
	option -headers [list]
	option -header ""
	option -body ""
	option -ttl 5

	variable wait 0
	variable status ""
	variable last_error ""
	variable fault_code ""
	variable fault_string ""
	variable fault_detail ""
	variable xml ""
	variable redirected 0
	variable http_req ""
	variable ttl 0

	destructor {
		set status "canceled"
		if { $http_req != "" } {
			catch {::http::reset $http_req}
			catch {::http::cleanup $http_req}
			set http_req ""			
		}
	}

	method SendSOAPRequest { } {
		if {$ttl > $options(-ttl)} {
			error "Too many retried"
		}
		if { $options(-url) == "" || ($options(-xml) == "" && ($options(-header) == "" || $options(-body) == "")) } {
			error "SOAPRequest incomplete"
		}
		status_log "Sending SOAP request to $options(-url) with action $options(-action)" green

		if { $options(-action) != "" } {
			set headers [linsert $options(-headers) 0 SOAPAction $options(-action)]
		} else {
			set headers $options(-headers)
		}

		set proxy [::config::getKey proxy]
		set proxy_host [lindex $proxy 0]
		set proxy_port [lindex $proxy 1]

		if {[::config::getKey connectiontype] == "direct" } {
			::http::config -proxyhost "" -proxyport ""
			http::register https 443 ::tls::socket
			http::register http 80 ::socket
		} elseif {[::config::getKey connectiontype] == "http" } {
			# haha, ok, this is easy, http connection means the http gateway, which means no need to set up a proxy! :D
			::http::config -proxyhost "" -proxyport ""
			http::register https 443 ::tls::socket
			http::register http 80 ::socket
		} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "http" } {
			if {$proxy_host == "" } {
				::http::config -proxyhost "" -proxyport ""
			} else {
				if { $proxy_port == "" } {
					set proxy_port 8080
				}
				
				::http::config -proxyhost $proxy_host -proxyport $proxy_port
			}
			
			if { [::config::getKey proxyauthenticate] } {
				set proxy_user [::config::getKey proxyuser]
				set proxy_pass [::config::getKey proxypass]
				set auth [string map {"\n" "" } [base64::encode ${proxy_user}:${proxy_pass}]]
				set headers [linsert $headers 0 "Proxy-Authorization" "Basic $auth"]
			}
			http::register https 443 HTTPsecureSocket
			http::register http 80 ::socket
		} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "socks5" } {
			if {$proxy_host == "" } {
				::http::config -proxyhost "" -proxyport ""
			} else {
				if { $proxy_port == "" } {
					set proxy_port 1080
				}
				::http::config -proxyhost $proxy_host -proxyport $proxy_port
			}
			
			http::register https 443 SOCKSsecureSocket
			http::register http 80 SOCKSSocket
		} else {
			::config::setKey connectiontype "direct"
			
			::http::config -proxyhost "" -proxyport ""
			http::register https 443 ::tls::socket
			http::register http 80 ::socket
		}
		
		::http::config -accept "*/*"  -useragent "MSMSGS"

		if { $http_req != "" } {
			catch {::http::reset $http_req}
			catch {::http::cleanup $http_req}
			set http_req ""			
		}

		if {$options(-header) != "" && $options(-body) != ""} {
			set xml {<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/">}
			append xml {<soap:Header>}
			append xml $options(-header)
			append xml {</soap:Header>}
			append xml {<soap:Body>}
			append xml $options(-body)
			append xml {</soap:Body>}
			append xml {</soap:Envelope>}

		} else {
			set xml $options(-xml)
		}

		set xml [encoding convertto utf-8 $xml]

		# Catch it in case we have no internet.. 
		if { ![catch { set http_req [http::geturl $options(-url) -timeout 600000 -command [list $self GotSoapReply] -query $xml -type "text/xml; charset=utf-8" -headers $headers] } res] } {
			#puts "Sending HTTP request : $options(-url)\nSOAPAction: $options(-action)\n\n$xml"
			if {[info exists ::soap_debug] && $::soap_debug != ""} {
				set filename "[$self GetDebugFilename]_req.xml"
				catch {set fd [open [file join $::soap_debug $filename] w]}
				catch {puts $fd [xml2prettyxml $xml]}
				catch {close $fd}
			}
			incr ttl
			if { $options(-callback) == "" && $redirected } {
				tkwait variable [myvar wait]
			}
		} else if {[catch {$self configure}] == 0} {
			# In case of an error, report it back.. make sure that our object wasn't destroyed...
			set status "PostFailed"
			set last_error $res
			status_log "Failed to send SOAP request to $options(-url) with action $options(-action) : ..." green
			status_log "... status=$status, LastError=$last_error" green
			if {$options(-callback) != "" } {
				if {[catch {eval $options(-callback) $self} result]} {
					bgerror $result
				}
			}
		} else {
			# If our object was destroyed, don't return our name.
			return ""
		}

		return $self
	}

	method GotSoapReply { token } {
		#puts "Received HTTP answer : [::http::code $token]  [::http::status $token]\n[::http::data $token]"
	
		if {[info exists ::soap_debug] && $::soap_debug != ""} {
			set filename "[$self GetDebugFilename]_resp.xml"
			catch {set fd [open [file join $::soap_debug $filename] w]}
			#catch {puts $fd [$self configure]}
			catch {puts $fd [xml2prettyxml [::http::data $token]]}
			catch {close $fd}
		}

		set last_error [::http::error $token]
		#shouldn't work if ncode == 500, MS servers ...
		if { [::http::status $token] == "ok" && [::http::ncode $token] >= 200 && [::http::ncode $token] < 300 || [::http::ncode $token] == 500} {
			set status "success"
			if {[catch {set xml [xml2list [::http::data $token]] } res ] } {
				set status "InvalidXML"
				set last_error "$res"
			} else {
				set fault [GetXmlNode $xml "soap:Envelope:soap:Body:soap:Fault"]
				set faultcode [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:faultcode"]
				set faultstring [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:faultstring"]
				set faultdetail [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:detail:errorcode"]
				if {$fault == "" } {
					set fault [GetXmlNode $xml "S:Envelope:S:Fault"]
					set faultcode [GetXmlEntry $xml "S:Envelope:S:Fault:faultcode"]
					set faultstring [GetXmlEntry $xml "S:Envelope:S:Fault:faultstring"]
					set faultdetail [GetXmlEntry $xml "S:Envelope:S:Fault:detail:errorcode"]
				}

				if { $fault != "" } {
					set status "fault"
					set last_error $faultcode
					set fault_code $faultcode
					set fault_string $faultstring
					set fault_detail $faultdetail
				}
			}
		} elseif { [::http::status $token] == "ok" } {
			upvar #0 $token state
			set meta $state(meta)

			array set meta_array $meta 
			if {[info exists meta_array(Location)]} {
				set options(-url) $meta_array(Location)
				::http::cleanup $token

				set redirected 1
				if {[catch {$self SendSOAPRequest} err] } {
					set last_error $err
					set status [::http::ncode $token]	
				} else {
					return
				}
			} else {
				set last_error [::http::code $token]
				set status [::http::ncode $token]
			}
		} else {
			set status [::http::code $token]
		}

		set http_stat [::http::status $token]
		::http::cleanup $token

		incr [myvar wait]
		if {$http_stat  != "reset"} {
			status_log "Received answer to SOAP request sent to $options(-url) with action $options(-action) : ..." green
			status_log "... status=$status, LastError=$last_error, FaultDetail=$fault_detail" green
			if {$options(-callback) != "" } {
				if {[catch {eval $options(-callback) $self} result]} {
					bgerror $result
				}
			}
		}

	}

	method GetResponse { } {
		return $xml
	}
	
	method GetStatus { } {
		return $status
	}

	method GetLastError { } {
		return $last_error
	}

	method GetFaultCode { } {
		return $fault_code
	}
	method GetFaultString { } {
		return $fault_string
	}
	method GetFaultDetail { } {
		return $fault_detail
	}
	method GetDebugFilename {} {
		if {$options(-action) != ""} {
			set filename $options(-action)
		} else {
			set filename $options(-url)
		} 
		return [file tail $filename]
		
	}
}
