namespace eval ::changeit {
    variable config
    variable configlist
    

	proc InitPlugin { dir } {
    	::plugins::RegisterPlugin changeit
		source [file join $dir changeit.tcl]
    	
  

    	::plugins::RegisterEvent changeit chat_msg_receive msgReceive
 		::plugins::RegisterEvent changeit chat_msg_send msgSend
 
 
    	array set ::changeit::config {
		sent {0}
		received {1}
		filter {/usr/local/bin/pirate}
    	}
    	

    	set ::changeit::configlist [list \
				  [list bool "Filter sent messages"  sent] \
				  [list bool "Filter received messages"  received] \
				  [list str "Location to filter"  filter] \
				 ]
	}
	

proc msgReceive {event evpar} {
		variable config
    if { $config(received) } {
    	upvar 2 user user
    	set email $user
    	if { $email != [::config::getKey login] } {
    	upvar 2 msg msg
    	set msg [exec echo "$msg" | $config(filter)]
    	return $msg
    	}
    	}
}
 	
 	
	
	
        
    proc msgSend {event evpar} {
    	variable config
    	if { $config(sent) } {
    	upvar 2 msg msg
    	set msg [exec echo "$msg" | $config(filter)]
    	return $msg
    	}
}
 	
 	
}
	
        