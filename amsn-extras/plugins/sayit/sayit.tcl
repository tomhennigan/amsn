namespace eval ::sayit {
    variable config
    variable configlist
    

	proc InitPlugin { dir } {
    	::plugins::RegisterPlugin sayit
		source [file join $dir sayit.tcl]
    	
  

    	::plugins::RegisterEvent sayit chat_msg_received newmessage
  
 
 
    	array set ::sayit::config {
		voice {}
		
    	}
    	

    	set ::sayit::configlist [list \
				  [list str "Voice"  voice] \
				 ]
	}
	

    proc newmessage {event evpar} {
    	variable config
    	upvar 2 evpar newvar
    	upvar 2 msg msg
    	upvar 2 user user
    	#Define the 3 variables, email, nickname and message
    	set email $user
    	set nickname [::abook::getDisplayNick $user]
    	
    	

    		if { (($email != [::config::getKey login]) && [focus] == "") && $msg != "" } {
    			if {$config(voice)!=""} {
    			exec say -v $config(voice) $msg
    			
    			} else {
    			exec say $msg
    			
    			}
    		}
 	}
	}
	
        
