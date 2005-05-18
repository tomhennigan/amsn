namespace eval ::emotes {
	variable arguments ""

	proc Init { dir } {
	
		::plugins::RegisterPlugin emotes
	
		;# this will return  the  list of arguments a command can take
	        set args [info args ::amsn::PutMessageWrapped] 
        	set arglist ""
	        foreach arg $args {
	
	                if { [info default ::amsn::PutMessageWrapped $arg value] } {
				;# This  will return the default value of that argument,
				;#returns 1 if it has a default value and stores it in the  value variable,
				;#returns 0 if it doesn't have a default value
	                        set argument "\{$arg \"$value\"\}"
        	        } else {
                	        set argument $arg
	                }
	
	                set arglist "$arglist $argument"                        
			;# So here we get the list of  arguments of the proc just like it's written in the source code

	        }

		set ::emotes::arguments ""
		foreach arg $args {
			set ::emotes::arguments "[set ::emotes::arguments] \$$arg"
		}
	
	
        	# Original ::amsn::PutMessageWrapped
		;# We recreated the  ::amsn::PutMessageWrapped proc in here.
		;#The info body command returns the exxxact content of the  function    
		proc ::amsn::EmotesPutMessageWrapped "$arglist" "[info body ::amsn::PutMessageWrapped]"


		set body [info body ::amsn::PutMessageWrapped]
		set modified ""


		while { $body != "" } {
			set limit1 [string first "\n" $body]
			set limit2 [string first ";" $body]
			if { $limit1 == -1 } { set limit1 $limit2 }
			if { $limit2 == -1 } { set limit2 $limit1 }
			if { $limit1 < $limit2 } { set limit $limit1 } else { set limit $limit2 }

			if { $limit == -1 } { set limit "end" }

			set line [string range $body 0 $limit]
			if { [lsearch [list $line] "*WinWrite*"] != -1 && [lsearch [list $line] "*says*"] != -1} {       
				;# if the code contains the line  that writes the "KaKaRoTo says",
				;#remove that line from the code
			} else {                                         
				;#else make that line of the code part of the current proc
				set modified "${modified}$line"

			}
		
			set body [string replace $body 0 $limit]

		}


	        # Modified ::amsn::PutMessageWrapped that doesn't write the line with  the  "KaKaRoTo says" to the window
        	proc ::amsn::EmotesPutMessageWrappedModified "$arglist" "$modified"

	        proc ::amsn::PutMessageWrapped "$arglist" {

        	        if {[string first "/me " $msg] != 0 } {                
				;#  If the message doesn't  beguin with "/me" call the original proc
                        	eval ::amsn::EmotesPutMessageWrapped $::emotes::arguments
	                } else {                                                 
				;# else, remove the /me and change it to the nick and  call the modified proc
                	        set msg "\n[timestamp] $nick [string range $msg 4 end]"
                        	eval ::amsn::EmotesPutMessageWrappedModified $::emotes::arguments
	                }

        	}
	}


	proc DeInit { } {
	
		status_log "Restoring previous proc body\n"
	
		;# this will return  the  list of arguments a command can take
		set args [info args ::amsn::PutMessageWrapped] 
		set arglist ""
		foreach arg $args {
			
			if { [info default ::amsn::PutMessageWrapped $arg value] } {
				;# This  will return the default value of that argument,
				;#returns 1 if it has a default value and stores it in the  value variable,
				;#returns 0 if it doesn't have a default value
				set argument "\{$arg \"$value\"\}"
			} else {
				set argument $arg
			}
			
			set arglist "$arglist $argument"                        
			;# So here we get the list of  arguments of the proc just like it's written in the source code
			
		}

		
		# Original ::amsn::PutMessageWrapped
		;# We recreated the  ::amsn::PutMessageWrapped proc in here.
		;#The info body command returns the exxxact content of the  function    
		proc ::amsn::PutMessageWrapped "$arglist" "[info body ::amsn::EmotesPutMessageWrapped]"
		
		
	}
}
