package require snit

snit::type SOAPRequest {
	
	option -url ""
	option -action ""
	option -xml ""
	option -callback ""
	option -headers [list]

	variable wait 0
	variable status ""
	variable last_error ""
	variable xml ""
		
	# TODO this doesn't handle proxy for SOAP requests going through HTTP (not HTTPS)... like for spaces... :s
	method SendSOAPRequest { } {
		if { $options(-url) == "" || $options(-xml) == "" } {
			error "SOAPRequest incomplete"
		}
		status_log "Sending SOAP request to $options(-url) with action $options(-action)" green

		set proxy [::config::getKey proxy]
		set proxy_host [lindex $proxy 0]
		set proxy_port [lindex $proxy 1]

		if {[::config::getKey connectiontype] == "direct" } {
			::http::config -proxyhost "" -proxyport ""
			http::register https 443 ::tls::socket
		} elseif {[::config::getKey connectiontype] == "http" } {
			error "NOT SUPPORTED"
			http::register https 443 HTTPsecureSocket
		} elseif { [::config::getKey connectiontype] == "proxy" && [::config::getKey proxytype] == "http" } {
			if {$proxy_host == "" } {
				::http::config -proxyhost "" -proxyport ""
			} else {
				if { $proxy_port == "" } {
					set proxy_port 8080
				}
				
				::http::config -proxyhost $proxy_host -proxyport $proxy_port
			}
			
			http::register https 443 HTTPsecureSocket
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
		} else {
			::config::setKey connectiontype "direct"
			
			::http::config -proxyhost "" -proxyport ""
			http::register https 443 ::tls::socket
		}
		
		::http::config -accept "*/*"   -useragent "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; Windows Live Messenger 8.1.0178)"

		if { $options(-action) != "" } {
			set headers [linsert $options(-headers) 0 SOAPAction $options(-action)]
		} else {
			set headers $options(-headers)
		}
		http::geturl $options(-url) -command [list $self GotSoapReply] -query $options(-xml) -type "text/xml; charset=utf-8" -headers $headers

		#puts "Sending HTTP request : $options(-url)\nSOAPAction: $options(-action)\n\n$options(-xml)"

		if { $options(-callback) == "" } {
			tkwait variable [myvar wait]
		}

		return $self
	}

	method GotSoapReply { token } {
		#puts "Received HTTP answer : [::http::code $token]  [::http::status $token]\n[::http::data $token]"
	
		set last_error [::http::error $token]
		if { [::http::status $token] == "ok" && [::http::ncode $token] >= 200 && [::http::ncode $token] < 300} {
			set status "success"
			if {[catch {set xml [xml2list [::http::data $token]] } res ] } {
				set status "InvalidXML"
				set last_error "$res"
			} else {
				set fault [GetXmlNode $xml "soap:Envelope:soap:Body:soap:Fault"]
				#puts "fault : $fault"
				if { $fault != "" } {
					set status [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:faultcode"]
					set last_error [GetXmlEntry $xml "soap:Envelope:soap:Body:soap:Fault:faultstring"]
				}
			}
		} elseif { [::http::status $token] == "ok" } {
			set last_error [::http::code $token]
			set status [::http::ncode $token]
		} else {
			set status [::http::code $token]
		}

		::http::cleanup $token
		incr [myvar wait]

		if {$options(-callback) != "" } {
			eval $options(-callback) $self
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
}