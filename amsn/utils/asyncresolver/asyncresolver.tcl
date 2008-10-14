
load [file join $dir libasyncresolver[info sharedlibextension]]

rename socket _socket

proc socket { args } {
	
	if { [ lsearch $args -server ] == -1} {
		
		if { ![info exists ::asyncresolver_request_number]} {
			set ::asyncresolver_request_number 0
		} else {
			incr ::asyncresolver_request_number
		}
		
		set varname ::asyncresolver_wait_$::asyncresolver_request_number
		asyncresolve [list asyncresolver_callback $varname] [lindex $args end-1]
	
		if {![info exists $varname]} {tkwait variable $varname}
		
		if { [set $varname] == "" } {
			error "couldn't open socket: host is unreachable (Name or service not known)"
		}
		set cmd [linsert [lreplace $args end-1 end-1  [set $varname]] 0 _socket ]

		unset $varname

		return [eval $cmd]
		
	} else {
	
		return [eval [linsert $args 0 _socket ] ]
		
	}
	
}

proc asyncresolver_callback { var {ip ""} } {
	set $var $ip
}
