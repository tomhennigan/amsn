##+##########################################################################
#
# Parallel Geturl -- package (and demo) that efficiently downloads large
# numbers of web pages while also handling timeout failures. Web requests
# are queued up and a set number are simultaneously fired off. As requests
# complete, new ones of popped off the queue and launched.
# by Keith Vetter, March 5, 2004

package require Tk
package require http

namespace eval PGU {
	if { $initialize_amsn == 1 } {
		variable options                            ;# User tweakable values
		variable queue                              ;# Request queue
		variable qhead 1                            ;# First empty slot
		variable qtail 0                            ;# Last in use slot
		variable stats                              ;# Array of statistics
		variable wait 0                             ;# For vwait
		variable tokens
		array set options {-degree 50 -timeout 60000 -maxRetries 3}
	}

	proc ::PGU::Reset {} {
		variable queue
		variable stats
		variable qhead 1
		variable qtail 0
		variable wait 0
		variable tokens

		catch {unset queue}
		array set queue {}
		array set stats {qlen 0 pending 0 done 0 timeouts 0}
		foreach id [array names tokens] {
			set token [set tokens($id)]
			catch {::http::reset $token}
			catch {::http::cleanup $token}
		}
		array unset tokens
	}
	if { $initialize_amsn == 1 } {
		::PGU::Reset
	}

	#############################################################################
	#
	# ::PGU::Config -- allow user to configure some parameters
	#
	proc ::PGU::Config {args} {
		variable options
		set o [lsort [array names options]]

		if {[llength $args] == 0} {                 ;# Return all results
			set result {}
			foreach name $o {
				lappend result $name $options($name)
			}
			return $result
		}
		foreach {flag value} $args {                ;# Get one or set some
			if {[lsearch $o $flag] == -1} {
				return -code error "Unknown option $flag, must be: [join $o ", "]"
			}
			if {[llength $args] == 1} {             ;# Get one config value
				return $options($flag)
			}
			set options($flag) $value               ;# Set the config value
		}
	}
	##+##########################################################################
	#
	# ::PGU::Add -- adds a url and callback command to are request queue
	#
	proc ::PGU::Add {url cmd query type headers {nolaunch 0}} {
		variable queue
		variable qtail
		variable stats

		set id [incr qtail]
		set queue($id) [list $url $cmd $query $type $headers 0]
		incr stats(qlen)
		status_log "PGU: Queueing $id for $url : [::PGU::Status]"
		if {!$nolaunch} {
			::PGU::Launch
		}

		return $id
	}
	##+##########################################################################
	#
	# ::PGU::Launch -- launches web requests if we have the capacity
	#
	proc ::PGU::Launch {} {
		variable queue
		variable qtail
		variable qhead
		variable options
		variable stats
		variable tokens

		while {1} {
			if {$qtail < $qhead} return             ;# Empty queue
			if {$stats(pending) >= $options(-degree)} return ;# No slots open

			set id $qhead
			incr qhead

			if {![info exists queue($id)] } continue ; # canceled request

			incr stats(pending)
			incr stats(qlen) -1

			foreach {url cmd query type headers cnt} $queue($id) break
			status_log "PGU: Getting URL $id : [::PGU::Status]"
			set tokens($id) [::http::geturl $url -timeout $options(-timeout) \
					     -command [list ::PGU::_HTTPCommand $id] \
					     -query $query -type $type -headers $headers]
		}
	}
	##+##########################################################################
	#
	# ::PGU::_HTTPCommand -- our geturl callback command that handles
	# queue maintenance, timeout retries and user callbacks.
	#
	proc ::PGU::_HTTPCommand {id token} {
		variable queue
		variable stats
		variable options
		variable wait
		variable tokens

		foreach {url cmd query type headers cnt} $queue($id) break

		set status [::http::status $token]
		if {$status == "timeout"} {
			incr stats(timeouts)
			incr cnt -1
			if {abs($cnt) < $options(-maxRetries)} {
				::http::cleanup $token
				array unset tokens $id

				lset queue($id) 5 $cnt              ;# Remember retry attempts
				set tokens($id) [::http::geturl $url -timeout \
						     $options(-timeout) \
						     -command [list ::PGU::_HTTPCommand $id] \
						     -query $query -type $type \
						     -headers $headers]
				return
			}
		}

		incr stats(pending) -1                      ;# One less outstanding request
		incr stats(done)
		status_log "PGU: Request $id done : [::PGU::Status]"
		::PGU::Launch                               ;# Try launching another request

		if {[catch {eval $cmd $token} emsg]} {
			status_log "PGU Callback error : $emsg\n" red
		}
		::http::cleanup $token
		array unset queue $id
		array unset tokens $id
	}

	proc ::PGU::Cancel {id} {
		variable tokens
		variable queue
		
		if {[info exists tokens($id)] } {
			set token [set tokens($id)]
			catch {::http::reset $token}
			catch {::http::cleanup $token}
			array unset tokens $id
		}
		array unset queue $id
	}

	##+##########################################################################
	#
	# ::PGU::Status -- returns some statistics of the current state
	#
	proc ::PGU::Status {} {
		variable stats
		return [list $stats(qlen) $stats(pending) $stats(done) $stats(timeouts)]
	}

}