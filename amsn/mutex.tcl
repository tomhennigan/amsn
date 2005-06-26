

#Init the ticket variable. Resources is the amount of processes
#that can run the given command at same time
proc init_ticket { ticket { resources 1 }} {
	upvar #0 ${ticket}_inputs ticket_inputs
	upvar #0 ${ticket}_outputs ticket_outputs

	set ticket_inputs 0
	set ticket_outputs [expr {$ticket_inputs + $resources}]
}


#Procedure used to avoid race conditions, using a ticket systems
proc run_exclusive { command ticket {ticket_val ""}} {
	upvar #0 ${ticket}_inputs ticket_inputs
	upvar #0 ${ticket}_outputs ticket_outputs

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
		status_log "UPS! Another instance of command $command. Avoid interleaving by waiting 100ms and try again\n" white
	} else {
		eval $command
		#Give next turn
		incr ticket_outputs
	}

}

proc SendMessageFIFO { command stack lock } {
	if { ![info exists $stack] } {
		set $stack [list ]
	}
	# Add message to queue
	lappend $stack $command
	FlushMessageFIFO $stack $lock
}

proc FlushMessageFIFO { stack lock } {

	# Make sure only one "person" is writing to the window
	if { [info exists $lock] } { return }
	set $lock 1
	#do the job until there's no message to send in the stack
	while { [set $stack] != [list]} {
		#sending the message
		#the first message to send is the first element of the stack
		set command [lindex [set $stack] 0]
		
		eval $command

		# remove the message from the stack
		set $stack [lreplace [set $stack] 0 0]
	}
	unset $stack
	unset $lock
}
