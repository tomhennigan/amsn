namespace eval ::camserv {
	variable plugin_name "Webcam Server"
	variable config
	variable configlist
	
	
	proc Init { dir } {
		variable plugin_name 
		variable config
		variable configlist

		::plugins::RegisterPlugin $plugin_name
	    	::plugins::RegisterEvent $plugin_name chat_msg_receive msgReceive
	    	
		array set config {
			contacts {my_allowed_contact@hotmail.com}			
			magicword {sendcamtome}
	    	}
	    	

	    	set configlist [list \
			[list str "Magic word"  magicword] \
			[list str "Contacts"  contacts] \
		]
	}
	
	proc msgReceive {event evpar} {
		variable config

		upvar 2 msg msg
		upvar 2 user user
	    	set email $user		

#TODO: first check should be if it is part of the string
		if { $config(contacts) == $email && $email != [::config::getKey login]} {
#TODO: check if it's the first word of the msg instead of is the msg
		    	if { $msg == $config(magicword)} {
				::MSNCAM::SendInviteQueue $email
			}

#TODO: a change magicword command (syntax: "change oldword newword" ?
#		    	if {[string first "magicword" $msg] == 0 )} {
#               	        set msg [string range $msg 10 end]
#               	        
#
#			}



		}
    	}


}
