

#Init the ticket variable. Resources is the amount of processes
#that can run the given command at same time
proc init_ticket { ticket resources } {
	upvar ${ticket}_inputs ticket_inputs
	upvar ${ticket}_outputs ticket_outputs

	set ticket_inputs 0
	set ticket_outputs [expr {ticket_inputs + $resources}]
}


#Procedure used to avoid race conditions, using a ticket systems
proc run_exclusive { command ticket {ticket_val ""}} {
	upvar ${ticket}_inputs ticket_inputs
	upvar ${ticket}_outputs ticket_outputs

	#Use kind of mutex here (really a ticket counter)

	#Get my turn
	if { $ticket_val == "" } {
		set my_ticket [incr ticket_inputs]
	} else {
		set my_ticket $ticket_val
	}

	#Wait until it's my turn
	if {$my_ticket != $ticket_outputs } {
		after 100 [list run_exclusive $command $ticket $my_ticket]
		status_log "UPS! Another instance running. Avoid interleaving by waiting 100ms and try again\n" white
	} else {
		eval $command
		#Give next turn
		incr ticket_outputs
	}

}
