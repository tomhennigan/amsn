
load [file join $dir libasyncresolver[info sharedlibextension]]

namespace eval ::asyncresolver {
	
	variable request_number 0

	proc resolve { original arguments } {
		variable request_number

		if { [ lsearch $arguments -server ] == -1} {
			incr request_number
		
			set varname ::asyncresolver::_wait_$request_number
			::asyncresolver::asyncresolve [list ::asyncresolver::_resolve_callback $varname] [lindex $arguments end-1]
	
			if {![info exists $varname]} {tkwait variable $varname}
		
			if { [set $varname] == "" } {
				error "couldn't open socket: host is unreachable (Name or service not known)"
			}
			set cmd [linsert [lreplace $arguments end-1 end-1  [set $varname]] 0 $original ]

			unset $varname

			return [eval $cmd]
		
		} else {
			return [eval [linsert $arguments 0 $original ] ]
		}
	
	}

	proc _resolve_callback { var {ip ""} } {
		set $var $ip
	}

}

rename fconfigure _fconfigure
proc fconfigure { channel args } {
	if { [llength $args] == 1 && [lindex $args 0] == "-sockname" } {
		set sockname [::asyncresolver::sockname $channel]
		foreach {ip port} $sockname break
		return [list $ip [info hostname] $port]
	} else {
		return [eval [linsert $args 0 _fconfigure $channel] ]
	}
}


# rename socket _socket
# proc socket { args } {
# 	return [::asyncresolver::resolve _socket $args]	
# }


# package require tls
# if {[info commands ::tls::socket] == "::tls::socket"} {
# 	rename ::tls::socket ::tls::_socket
# 	proc ::tls::socket { args } {
# 		return [::asyncresolver::resolve ::tls::_socket $args]	
# 	}

# }
