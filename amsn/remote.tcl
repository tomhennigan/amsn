#########################################################
### remote.tcl v 1.0	2003/05/22   KaKaRoTo
#########################################################

set remote_port 0
set remote_auth 0
set remote_sock_lock 0
set remote_sock 0

namespace eval ::remote {

    #// connect { username password }
    #// connects you to an account with the username and password entered
    #//
    proc connect { username password } {
	
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

    #// logout
    #// logs you out from the current session
    #//
    proc logout { } {
	write_remote "[trans logout]"
	::MSN::logout
    }

    #// help
    #// prints this help 
    #//
    proc help { } {
	global program_dir

	set fd [open "[file join $program_dir remote.help]" r]
	set printhelp "[read $fd]"

	write_remote "$printhelp"
  
    }
    
    proc online { } {
	global list_users list_states

	foreach user $list_users {
	    
	    set user_state_no [lindex $user 2]
	    set state [lindex $list_states $user_state_no]
	    set state_code [lindex $state 0]
	    

	    if { $state_code !="FLN" } {
		write_remote "[lindex $user 1] --- [trans status] : [trans [lindex $state 1]]"
	    }
	}

    }
  

}

proc write_remote { dataout } {
    global remote_sock

    puts $remote_sock $dataout

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
	    write_remote "[trans syntaxerror] : $res\n" 
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