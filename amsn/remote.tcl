#########################################################
### remote.tcl v 1.0	2003/05/22   KaKaRoTo
#########################################################

if { $initialize_amsn == 1 } {
    global remote_port remote_auth remote_sock_lock remote_sock
   
    set remote_port 0
    set remote_auth 0
    set remote_sock_lock 0
    set remote_sock 0
}

namespace eval ::remote {

    # connect 
    # connects you to your account
    #
    proc connect { } {
	
	set username "null"
	set password "null"

	write_remote "[trans connecting] ..." 

	if { [string match "*@*" $username] == 0 } {
	    set username [split $username "@"]
	    set username "[lindex $username 0]@hotmail.com"
	}

	if { [catch { ::MSN::connect username password } res] } {
	    write_remote "[trans connecterror]"
	} else {
	    write_remote "[trans connected]"
	}
	
    }

    # logout
    # logs you out from the current session
    #
    proc logout { } {
	write_remote "[trans logout]"
	::MSN::logout
    }

    # help
    # prints the help message from the remote.help file
    #
    proc help { } {

	set fd [open "remote.help" r]
	set printhelp "[read $fd]"

	write_remote "$printhelp"
  
    }
    
    # online
    # Shows list of users connected
    #
    proc online { } {

	foreach username [::MSN::getList FL] {
	    
	    set state_code [::abook::getVolatileData $username state]	    

	    if { $state_code !="FLN" } {
		write_remote "[::abook::getNick $username] --- [trans status] : [trans [lindex $state 1]]"
	    }
	}

    }

    proc getstate { } {
	global user_stat

	set my_state [::MSN::stateToDescription "$user_stat *"]

	write_remote "Your state is currently on : $my_state"

    }

    proc setstate { state } {

	set state [string tolower $state]
	if { "$state" == "online" } {
	    ::MSN::changeStatus NLN
	} elseif { "$state" == "away" } {
	    ::MSN::changeStatus AWY
	} elseif { "$state" == "busy" } {
	    ::MSN::changeStatus BSY
	} elseif { "$state" == "noactivity" } {
	    ::MSN::changeStatus IDL
	} elseif { "$state" == "brb" } {
	    ::MSN::changeStatus BRB
	} elseif { "$state" == "onphone" } {
	    ::MSN::changeStatus PHN
	} elseif { "$state" == "lunch" } {
	    ::MSN::changeStatus LUN
	} elseif { "$state" == "appearoffline" } {
	    ::MSN::changeStatus HDN
	} else {
	    write_remote "Invalid state" error
	    return
	}
	write_remote "State changed"
    }

    proc setnick { nickname } {
	global config
	

	if {$nickname != ""} {
	    ::MSN::changeName $config(login) "$nickname" 0
	    write_remote "New nick set to : $nickname"
	} else {
	    write_remote "New nick not entered"
	}

    
    }

    proc amsn_close { } {
	close_cleanup
	exit
    }

    proc whois { user } {
    
	set found 0

	foreach username [::MSN::getList FL] {
	    if { "[::abook::getContactData $username nick]" == "$user" } {
		write_remote "$user is : [::abook::getContactData $username]" 
		set found 1
		break
	    }
	}
	if { $found == 0 } {
	    write_remote "$user was not found in your contact list..." error
	}
    }

    proc whatis { user } {
    
	set found 0

	if { [string match "*@*" $user] == 0 } {
	    set user [split $user "@"]
	    set user "[lindex $user 0]@hotmail.com"
	    set user [string tolower $user]
	}	

	foreach username [::MSN::getList FL] {
	    if { "$username" == "$user" } {
		write_remote "$user is known as : [::abook::getNick $user]" 
		set found 1
		break
	    }
	}
	if { $found == 0 } {
	    write_remote "$user was not found in your contact list..." error
	}
    }

    # msg { args }
    # sends a message to a user
    #
    proc msg { args } {
	global userchatto

	if { [info exists userchatto] } {
	    set user "$userchatto"
	    set message "$args"
	} else {
	    set user [lindex $args 0]
	    set message "[lrange $args 1 end]"
	}
	    
	set message [string map { \{ "" \} ""} $message]

	if { [string match "*@*" $user] == 0 } {
	    set user [split $user "@"]
	    set user "[lindex $user 0]@hotmail.com"
	}

	set lowuser [string tolower $user]
   
	set win_name [::amsn::WindowFor $lowuser]

	if { $win_name == 0 } {
	    ::amsn::chatUser "$user"
	    
	    while { [set win_name [::amsn::WindowFor $lowuser]] == 0 } { }
	}

	set input "${win_name}.f.bottom.in.input"
	$input  insert end "${message}"
	
	::amsn::MessageSend $win_name $input 
	
	
    }

    proc chatto { user } { 
	global userchatto
	
	if { [string match "*@*" $user] == 0 } {
	    set user [split $user "@"]
	    set user "[lindex $user 0]@hotmail.com"
	}

	set userchatto "$user"

    }

    proc endchat { } {
	global userchatto
	if { [info exists userchatto] } {
	    unset userchatto
	}
    }

}

proc write_remote { dataout {colour "normal"} } {
    global remote_sock

    set dataout [string map [list "\n" " $colour\n"]  $dataout]
  
    puts $remote_sock "$dataout $colour"

}

proc read_remote { command sock } {
    global remote_auth remote_sock

    if { "$remote_sock" != "$sock" } {
	set remote_temp_sock $remote_sock
	init_remote $sock
	if {  $remote_auth == 1 } {
	    write_remote "Remote controlling is already active"
	    init_remote $remote_temp_sock
	    return 0
	}
    }
    

    if {$command != ""} {
	if { $remote_auth == 0 } {
	    authenticate "$command" "$sock"
	} elseif { [catch {eval "::remote::$command" } res] } {
	    write_remote "[trans syntaxerror] : $res" error
	}
    }
}


proc md5keygen { } { 
    set key [expr rand()]
    set key [expr $key * 1000000]

    return "$key"
}

proc authenticate { command sock } {
    global remotemd5key remote_auth config remote_sock_lock

    if { $command == "auth" } {
	set remotemd5key "[md5keygen]"
	write_remote "auth $remotemd5key"
    } elseif { [lindex $command 0] == "auth2" } {
	if { "[lindex $command 1]" ==  "[::md5::hmac $remotemd5key [list $config(remotepassword)]]" } {
	    if { $config(enableremote) == 1 } { 
		set remote_auth 1
		set remote_sock_lock $sock
		write_remote "Authentication successfull"
	    } else {
		write_remote "User disabled remote control"
		
	    } 
	} else {
	    if { $config(enableremote) == 1 } { 
		write_remote "Authentication failed"
	    } else { 
		write_remote "User disabled remote control"
	    }	
	}	
    }
}


proc init_remote { sock } {
    global remote_sock

    set remote_sock $sock

}

proc close_remote { sock } {
    global remote_sock_lock remote_auth

    if { $remote_sock_lock == $sock } {
	set remote_auth 0
    } 
}


proc init_remote_DS { } {
    catch {socket -server new_remote_DS 63251}
}

proc new_remote_DS { sock addr port } {

    fileevent $sock readable "remote_DS_Hdl $sock"
    fconfigure $sock -buffering line
}

proc remote_DS_Hdl { sock } {

    set email [gets $sock]
    if {[eof $sock]} {
	catch {close $sock}
    } else {
	grep $email $sock
    }
}

proc grep { pattern sock } {
    global HOME2


    set filename "[file join $HOME2 profiles]"

    if { [string match "*@*" $pattern] == 0 } {
	set pattern [split $pattern "@"]
	set pattern "[lindex $pattern 0]@hotmail.com"
    }

    if {([file readable "$filename"] != 0) && ([file isfile "$filename"] != 0)} {
	
	set file_id [open "$filename" r]
	gets $file_id tmp_data
	if {$tmp_data != "amsn_profiles_version 1"} {	;# config version not supported!
	    puts $sock "versionerror"
		close $file_id
		return 0
   	}


	# Now add profiles from file to list
	while {[gets $file_id tmp_data] != "-1"} {
	    set temp_data [split $tmp_data]
	    if { [lindex $temp_data 0] == "$pattern" }  {
		close $file_id
		puts $sock "[lindex $temp_data 1]"
		return 1
	    }
	}
	puts $sock "invalid"
	close $file_id
	return 0
    } else {
	puts $sock "noexist"
	return 0
    }

}
