package require snit

snit::type SOAPRequest {
	
	option -url ""
	option -action ""
	option -xml ""
	option -callback ""
	option -headers [list]
	option -header ""
	option -body ""

	variable wait 0
	variable status ""
	variable last_error ""
	variable xml ""
	variable redirected 0
	variable http_req ""

	destructor {
		set status "canceled"
		if { $http_req != "" } {
			catch {::http::reset $http_req}
			catch {::http::cleanup $http_req}
			set http_req ""			
		}
	}

	method SendSOAPRequest { } {
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

		# Catch it in case we have no internet.. 
		# TODO : maybe fix this somehow since we'll never get the callback...
		if { ![catch { set http_req [http::geturl $options(-url) -command [list $self GotSoapReply] -query $xml -type "text/xml; charset=utf-8" -headers $headers] }] } {
			#puts "Sending HTTP request : $options(-url)\nSOAPAction: $options(-action)\n\n$xml"
			if { $options(-callback) == "" && $redirected } {
				tkwait variable [myvar wait]
			}
		}

		return $self
	}

	method GotSoapReply { token } {
		#puts "Received HTTP answer : [::http::code $token]  [::http::status $token]\n[::http::data $token]"
	
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
				if {$fault == "" } {
					set fault [GetXmlNode $xml "S:Envelope:S:Fault"]
					set faultcode [GetXmlEntry $xml "S:Envelope:S:Fault:faultcode"]
				}

				if { $fault != "" } {
					set status "fault"
					set last_error $faultcode
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
				$self SendSOAPRequest
				::http::cleanup $token
				return
			} else {
				set last_error [::http::code $token]
				set status [::http::ncode $token]
			}
		} else {
			set status [::http::code $token]
		}

		incr [myvar wait]
		if {[::http::status $token] != "reset"} {
			if {$options(-callback) != "" } {
				if {[catch {eval $options(-callback) $self} result]} {
					bgerror $result
				}
			}
		}
		::http::cleanup $token

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
}
