#
# $Id$
#

proc ConfigDefaults {} {
	global config tcl_platform password
	set config(login) ""			;# These are defaults for users without
	set config(save_password) 0		;# a config file
	set config(keep_logs) 1
	set config(proxy) ""
	set config(connectiontype) direct	;# direct|http|proxy
	set config(proxytype) "http"		;# http|ssl|socks5
	set config(proxyuser) ""		;# SOCKS5
	set config(proxypass) ""		;# SOCKS5
	set config(proxyauthenticate) 0		;# SOCKS5 use username/password
	set config(start_ns_server) "messenger.hotmail.com:1863"
	set config(last_client_version) ""
	set config(sound) 1
	set config(mailcommand) ""


	if {$tcl_platform(platform) == "unix"} {
	   set config(soundcommand) "play"
	   set config(browser) "mozilla"
	   set config(notifyXoffset) 0
	   set config(notifyYoffset) 0
	   set config(filemanager) ""
	} elseif {$tcl_platform(platform) == "windows"} {
	   set config(soundcommand) "plwav.exe"
	   set config(browser) "explorer"
	   set config(notifyXoffset) 0
	   set config(notifyYoffset) 28
	   set config(filemanager) "start"
	} else {
	   set config(soundcommand) ""
	   set config(browser) ""
	   set config(notifyXoffset) 0
	   set config(notifyYoffset) 0
	   set config(filemanager) ""
	}

	set config(language) "en"
	set config(adverts) 0
	set config(autoidle) 1
	set config(idletime) 5
	set config(autoaway) 1
	set config(awaytime) 10
	set config(showonline) 1
	set config(showoffline) 1
	set config(listsmileys) 1
	set config(chatsmileys) 1
	set config(startoffline) 0
	set config(autoftip) 1
	set config(myip) "127.0.0.1"
	set config(wingeometry) 275x400-0+0
	set config(closingdocks) 0
	set config(backgroundcolor)  "#AABBCC"
	set config(encoding) auto
	set config(basefont) "Helvetica 11 normal"
	set config(backgroundcolor) #D8D8E0
	set config(textsize) 2
	set config(mychatfont) "{Helvetica} {} 000000"
	set config(orderbygroup) 0
	#Added by Trevor Feeney
	#Defaults group order to normal
	set config(ordergroupsbynormal) 0
	set config(withnotebook) 0
	set config(keepalive) 0
	#set config(notifywin) 1
	set config(notifymsg) 1
	set config(notifyonline) 1
	set config(notifyemail) 1
	set config(natip) 0
	set config(dock) 0
	set config(autoconnect) 0
	set config(showtimestamps) 1
	set config(allowbadwords) 1
	set config(newmsgwinstate) 1
        set config(newchatwinstate) 1
	set config(receiveddir) ""
	# automaticly change nick to custom state
	set config(autochangenick) 1
        set config(initialftport) 6891
        set config(remotepassword) ""
        set config(enableremote) 0
	set config(animatenotify) 1
        set config(checkonfln) 1
        set config(checkblocking) 0
        set config(blockinter1) 60
        set config(blockinter2) 300
        set config(blockinter3) 5
        set config(blockusers) 2
        set config(emotisounds) 1
        set config(animatedsmileys) 1
        set config(tooltips) 1
	set password ""
}

namespace eval ::config {
   proc get {key} {
     global config
     return $config($key)
   }

   proc set {key value} {
     global config
     set config($key) $value
   }
}

proc save_config {} {
   global tcl_platform config HOME HOME2 version password

   catch {
         if {$tcl_platform(platform) == "unix"} {
	    set file_id [open "[file join ${HOME} config]" w 00600]
         } else {
            set file_id [open "[file join ${HOME} config]" w]
         }
      } res

   set loginback $config(login)
   set passback $password

   # using default, make sure to reset config(login)
   if { $HOME == $HOME2 } {
   	set config(login) ""
	set password ""
   }

   puts $file_id "amsn_config_version 1"
   set config(last_client_version) $version

   set config_entries [array get config]
   set items [llength $config_entries]
   for {set idx 0} {$idx < $items} {incr idx 1} {
      set var_attribute [lindex $config_entries $idx]; incr idx 1
      set var_value [lindex $config_entries $idx]
       if { "$var_attribute" != "remotepassword" } {
	   puts $file_id "$var_attribute $var_value"
       }
   }

    set key [string range "${loginback}dummykey" 0 7]
    binary scan [::des::encrypt $key "${config(remotepassword)}\n"] h* encpass
    puts $file_id "remotepassword $encpass"
    
   if { ($config(save_password)) && ($password != "")} {
      
      set key [string range "${loginback}dummykey" 0 7]
      binary scan [::des::encrypt $key "${password}\n"] h* encpass
      puts $file_id "encpassword $encpass"
   }
   close $file_id
   
   set config(login) $loginback
   set password $passback
}

proc load_config {} {
    global config HOME password

    if {([file readable "[file join ${HOME} config]"] == 0) ||
	([file isfile "[file join ${HOME} config]"] == 0)} {
	return 1
    }
    
    ConfigDefaults
    
    set file_id [open "${HOME}/config" r ]
    
    gets $file_id tmp_data
    if {$tmp_data != "amsn_config_version 1"} {	;# config version not supported!
	return 1
    }
    
    while {[gets $file_id tmp_data] != "-1"} {
	set var_data [split $tmp_data]
	set var_attribute [lindex $var_data 0]
	set var_value [join [lrange $var_data 1 end]]
	set config($var_attribute) $var_value
    }

    #0.80 Compatibility
    if {[info exists config(password)]} {
	set password $config(password)
	unset config(password)
    }
    
        
    if {[info exists config(encpassword)]} {
	set key [string range "$config(login)dummykey" 0 7]
	set password $config(encpassword)
	catch {set encpass [binary format h* $config(encpassword)]}
	catch {set password [::des::decrypt $key $encpass]}
	#puts "Password length is: [string first "\n" $password]\n"
	set password [string range $password 0 [expr { [string first "\n" $password] -1 }]]
	#puts "Password is: $password\nHi\n"      
	unset config(encpassword)
    }
    
    if {[info exists config(remotepassword)]} {
 	set key [string range "$config(login)dummykey" 0 7]
 	catch {set encpass [binary format h* $config(remotepassword)]}
 	catch {set config(remotepassword) [::des::decrypt $key $encpass]}
 	#puts "Password length is: [string first "\n" $config(remotepassword)]\n"
 	set config(remotepassword) [string range $config(remotepassword) 0 [expr { [string first "\n" $config(remotepassword)] -1 }]]
 	#puts "Password is: $config(remotepassword)\nHi\n"      
     }
     
    close $file_id

	# Load up the personal states
	LoadStateList
    if { [winfo exists .my_menu] } {CreateStatesMenu .my_menu}
}


#///////////////////////////////////////////////////////////////////////////////
# LoadLoginList ()
# Loads the list of logins/profiles from the profiles file in the HOME dir
# sets up the first user in list as config(login)
proc LoadLoginList {{trigger 0}} {
	global HOME HOME2 config

	#puts stdout "called loadloginlist\n"
	
	if { $trigger != 0 } {
		status_log "getting profiles"
	} else {
		set HOME2 $HOME
	}

	if {([file readable "[file join ${HOME} profiles]"] != 0) && ([file isfile "[file join ${HOME}/profiles]"] != 0)} {
		set HOMEE $HOME
	} elseif {([file readable "[file join ${HOME2} profiles]"] != 0) && ([file isfile "[file join ${HOME2}/profiles]"] != 0)} {
		set HOMEE $HOME2
	} else {
		return 1
	}
	
	set file_id [open "${HOMEE}/profiles" r]
	gets $file_id tmp_data
	if {$tmp_data != "amsn_profiles_version 1"} {	;# config version not supported!
      		msg_box [trans wrongprofileversion $HOME]
		close $file_id
		return -1
   	}

	# Clear all list
	set top [LoginList size 0]
	for { set idx 0 } { $idx <= $top } {incr idx 1 } {
		LoginList unset 0 [LoginList get 0]
	}
	
	# Now add profiles from file to list
	while {[gets $file_id tmp_data] != "-1"} {
		set temp_data [split $tmp_data]
		set locknum [lindex $tmp_data 1]
#	    puts "temp data : $temp_data"
		if { $locknum == "" } {
		   #Profile without lock, give it 0
		   set locknum 0
		}
		LoginList add 0 [lindex $tmp_data 0] $locknum
	}
	close $file_id
	
	# Modify HOME dir to current profile, chose a non locked profile, if none available go to default
	if { $trigger == 0 } {
		set HOME2 $HOME
		set flag 0
		for { set idx 0 } { $idx <= [LoginList size 0] } {incr idx 1} {
			if { [CheckLock [LoginList get $idx]] != -1 } {
				LockProfile [LoginList get $idx]
				set flag 1
				break
			}
		}

		# if flag is 1 means we found a profile and we use it, if not defaults
		if { $flag == 1 } {
			set temp [LoginList get $idx]
			set dirname [split $temp "@ ."]
			set dirname [join $dirname "_"]
			set HOME "[file join $HOME2 $dirname]"
		} else {
			set config(login) ""
		}

		SaveLoginList
	}
}


#///////////////////////////////////////////////////////////////////////////////
# SaveLoginList ()
# Saves the list of logins/profiles to the profiles file in the HOME dir
proc SaveLoginList {} {
	global HOME2 tcl_platform currentlock

	if {$tcl_platform(platform) == "unix"} {
		set file_id [open "[file join ${HOME2} profiles]" w 00600]
	} else {
      		set file_id [open "[file join ${HOME2} profiles]" w]
	}
	puts $file_id "amsn_profiles_version 1"
	
	set idx [LoginList size 0]
	while { $idx >= 0 } {
		puts $file_id "[LoginList get $idx] [LoginList getlock 0 [LoginList get $idx]]"
		incr idx -1
	}
	close $file_id
}


#///////////////////////////////////////////////////////////////////////////////
# LoginList (action age [email])
# Controls information for list of profiles read from the profiles file
# action can be :
#	add : Adds new user to list, or if exists makes this user the newest
#	      (age is ignored), lock must be given if new profile
#	get : Returns the email by age, returns 0 if no email for age exists
#	exists : Checks the email if exists returns 1, 0 if dosent (age is ignored)
#	getlock : Returns lock code for given email, if non existant returns -1.
#	changelock : changes lock for user given by email to lock port given by lock
#	lockexists : checks if lock exists for some profile, returns 1 if true, 0 if false
#	unset : Removes profile given by email from the list and moves 
#		all elements up by 1 (age is ignored)
#       size : Returns [array size ProfileList] - 1
#	show : Dumps list to status_log, for debugging purposes only
proc LoginList { action age {email ""} {lock ""} } {
	variable ProfileList
	#global ProfileList
	variable LockList
	global currentlock

	switch $action {
		add {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx == -1 } {
				# User dosen't exist, proceed normaly
				for {set idx [expr [array size ProfileList] - 1]} {$idx >= 0} {incr idx -1} {
					set ProfileList([expr $idx + 1]) $ProfileList($idx)
					set LockList([expr $idx + 1]) $LockList($idx)
				} 
				set ProfileList(0) $email
				set LockList(0) $lock
			} else {
				# This means user exists, and we make him newest
				set emaillock $LockList([expr [expr $idx-1] / 2])
				for {set idx [lindex $tmp_list [expr $idx - 1]]} {$idx > 0} {incr idx -1} {
					set ProfileList($idx) $ProfileList([expr $idx - 1])
					set LockList($idx) $LockList([expr $idx - 1])
				}
				set ProfileList(0) $email
				set LockList(0) $emaillock
			}
		}

		unset {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx != -1 } {
				for {set idx [lindex $tmp_list [expr $idx - 1]]} {$idx < [expr [array size ProfileList] - 1]} {incr idx} {
					set ProfileList($idx) $ProfileList([expr $idx + 1])
					set LockList($idx) $LockList([expr $idx + 1])
				}
			unset LockList([expr [array size ProfileList] - 1])
			unset ProfileList([expr [array size ProfileList] - 1])
			}
		}

		get {
			if { [info exists ProfileList($age)] } {
				return $ProfileList($age)
			} else {
				return 0
			}
		}
		
		exists {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx == -1 } {
				return 0
			} else {
				return 1
			}
		}
		
		getlock {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
#		    puts "$tmp_list donne --> $idx --- $email --- [expr [expr $idx-1] /2] --- $ProfileList([expr [expr $idx-1] /2])"
			if { $idx == -1 } {
				return -1
			} else {
			    	return $LockList([lindex $tmp_list [expr {$idx-1}]])
			}
		}

		changelock {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx == -1 } {
				status_log "changelock called on unexisting email : $email, shouldn't happen!\n" red
				return -1
			} else {
			    	set LockList([lindex $tmp_list [expr {$idx-1}]]) $lock
			}
		}

		lockexists {
			set tmp_list [array get LockList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx == -1 } {
				return 0
			} else {
				return 1
			}
		}
				
		size {
			return [expr [array size ProfileList] - 1]
		}

		show {
			for {set idx 0} {$idx < [array size ProfileList]} {incr idx} {
				#status_log "$idx : $ProfileList($idx)\n"
#				puts stdout "$idx : $ProfileList($idx) loclist is : $LockList($idx)\n"
			}
		}
	}
}


#///////////////////////////////////////////////////////////////////////////////
# ConfigChange ( window email)
# Called when the user selects a combobox item or enters new signin
# email : email of the new profile/login
proc ConfigChange { window email } {
	global HOME HOME2 password config log_dir proftrig lockSock
	#set proftrig 0
	if { $email != "" } {
		
	status_log "Called ChangeConfig with $email, old is $config(login)\n"
		
	if { $email != $config(login) } {
	if { [LoginList exists 0 $config(login)] == 1 } {
		save_config
	}

	if { [LoginList exists 0 $email] == 1 } {
		
		# Profile exists, make the switch
		set OLDHOME $HOME
		set proftrig 0
		set oldlang $config(language)

		set dirname [split $email "@ ."]
		set dirname [join $dirname "_"]
		set HOME "[file join $HOME2 $dirname]"
				
		if { [CheckLock $email] == -1 } { 
			msg_box [trans profileinuse]
			set proftrig 3
			set HOME $OLDHOME
			
			# Reselect previous element in combobox
			#set cb [$window list get 0 [LoginList size 0]]
			#set index [lsearch $cb $config(login)]
			#$window select $index
			$window delete 0 end
			$window insert 0 $config(login)
			
		} else {
			if { [info exists password] } {
				set password ""
			}

			# Make sure we delete old lock
			if { [info exists lockSock] } {
				if { $lockSock != 0 } {
					close $lockSock
					unset lockSock
				}
			}

			if { [LoginList exists 0 $config(login)] } {
				LoginList changelock 0 $config(login) 0
			}

			load_config
			
			LoginList add 0 $email
			set log_dir "[file join ${HOME} logs]"
		
			load_lang

			# port isn't taken or port taken by other program, meaning profile ain't locked
			# let's setup the new lock
			LockProfile $email
			
			### REPLACE THIS BY MAIN WINDOW REDRAW
			if { $config(language) != $oldlang } {
				msg_box [trans mustrestart]
			}

			# this tells the the program to close the login window on OK press
			set proftrig 2
		}
	} else {
		# Profile dosent exist, put proftrig to 1 so it asks to create

		# Make sure we delete old lock
		if { [info exists lockSock] } {
			if { $lockSock != 0 } {
				close $lockSock
				unset lockSock
			}
		}
		LoginList changelock 0 $config(login) 0 
		
		set proftrig 1
		set config(login) $email
		set config(save_password) 0
		set config(startoffline) 0
	}
	}
	
	if { [winfo exists .login] } {
		.login.c.password delete 0 end
		if { $proftrig != 1 && [info exists password] } {
			.login.c.password insert 0 $password
		}
	}
	}
	
	status_log "ConfigChange finished, HOME is now : $HOME and HOME2 is now : $HOME2\n"
}


#///////////////////////////////////////////////////////////////////////////////
# CreateProfile ( email value )
# Either creates a new profile or uses default profile
# Called from NewProfileAsk
# email : email of new profile
# value : If 1 create new profile, if 0 use default profile
proc CreateProfile { email value } {
	global HOME HOME2 config log_dir password proftrig lockSock
	set oldpass $password
	set oldoffline $config(startoffline)
	set oldlang $config(language)

	if { $value == 1 } {
		status_log "Creating new profile"
		# Create a new profile with $email
		# Set HOME dir and create it
		set dirname [split $email "@ ."]
		set dirname [join $dirname "_"]
		set HOME "[file join $HOME2 $dirname]"
		create_dir $HOME
		set log_dir "[file join ${HOME} logs]"
		create_dir $log_dir
		
		# Load default config initially
		set temphome $HOME
		set HOME $HOME2
		load_config
		set HOME $temphome
		
		# Set current variables and add the profiles list
		set config(login) $email
		set password $oldpass
		set config(startoffline) $oldoffline
		LoginList add 0 $email 0

		# Lock profile
		LockProfile $email
		
	} else {
		# Dosent want to save profile, use/load default config in this case
		set HOME $HOME2
		load_config
		set log_dir ""
				
		# Set variables for default profile
		set config(login) $email
		set password $oldpass
		set config(startoffline) $oldoffline
		set config(save_password) 0
		set config(keep_logs) 0
	}
	
	set proftrig 0

	load_lang
	### REPLACE THIS BY MAIN WINDOW REDRAW
	if { $config(language) != $oldlang } {
		msg_box [trans mustrestart]
	}

}

#///////////////////////////////////////////////////////////////////////////////
# DeleteProfile ( email )
# Delete profile given by email, has to be different than the current profile
# entrypath : Path to the combobox containing the profiles list in preferences
proc DeleteProfile { email entrypath } {
	global config HOME2
	if { $email == $config(login) } {
		msg_box [trans cannotdeleteprofile]
		return
	} else {
	
	      set answer [tk_messageBox -message "[trans confirmdelete ${email}]" -type yesno -icon question]

	      if {$answer == "no"} {
	      	return
	      }
	
	
		set dir [split $email "@ ."]
		set dir [join $dir "_"]
		
		# Make sure profile isn't locked
		if { [CheckLock $email] == -1 } {
			msg_box [trans cannotdeleteprofile]
			return
		}
		
		catch { file delete -force [file join $HOME2 $dir] }
		$entrypath list delete [$entrypath curselection]
		$entrypath select 0
		LoginList unset 0 $email
		
		# Lets save it into the file
		SaveLoginList
	}
}

#///////////////////////////////////////////////////////////////////////////////
# CheckLock ( email )
# Check Lock of profile given by email
# Return -1 if profile is already locked, returns 0 otherwise
proc CheckLock { email } {
	global response LockList
	set Port [LoginList getlock 0 $email]
    puts "cheking lock for $email ... got $Port"
    puts "[array get LockList]"
	if { $Port != 0 } {
	if { [catch {socket -server phony $Port} newlockSock] != 0  } {
		# port is taken, let's make sure it's a profile lock
		if { [catch {socket localhost $Port} clientSock] == 0 } {
			fileevent $clientSock readable "lockcltHdl $clientSock"
			fconfigure $clientSock -buffering line
			puts $clientSock "AMSN_LOCK_PING"
			vwait response
			
			#set response [gets $clientSock]
			puts "\n$response\n"
			if { $response == "AMSN_LOCK_PONG" } {
				# profile is locked
				close $clientSock
				return -1
			} else {
				# other non amsn program is using the lock port, we better reset the lock to 0
				LoginList changelock 0 $email 0
			}
		}
	} else {
		close $newlockSock
	}
	}
	return 0
}

proc lockcltHdl { sock } {
	global response
	set response [gets $sock]
}

#///////////////////////////////////////////////////////////////////////////////
# GetRandomProfilePort ()
# Returns a random port in range 60535-65335
proc GetRandomProfilePort { } {

	set trigger 0
	
	while { $trigger == 0 } {
		# Generate random port between 60535 and 65535
		set Port [expr rand()]
		set Port [expr $Port * 10000]
		set Port [expr int($Port)]
		set Port [expr $Port + 60535]
		# Check if port isn't on another profile already
		if { [LoginList lockexists 0 $Port] != 1 } {
			set trigger 1
		}
	}

	return $Port
}
#///////////////////////////////////////////////////////////////////////////////
# LockProfile ( email )
# Creates a new lock for given profile, tries random ports until one works
proc LockProfile { email } {
	global lockSock
	set trigger 0
	while { $trigger == 0 } {
		set Port [GetRandomProfilePort]
		if { [catch {socket -server lockSvrNew $Port} newlockSock] == 0  } {
			# Got one
			LoginList changelock 0 $email $Port
			set lockSock $newlockSock
			set trigger 1
		}
	}
	if { $trigger == 1 } {
		#vwait events
	}
}


proc lockSvrNew { sock addr port} {
#	if { $addr == "127.0.0.1" } {
		fileevent $sock readable "lockSvrHdl $sock"
		fconfigure $sock -buffering line
#	}
}

proc lockSvrHdl { sock } {
	set command [gets $sock]
	if {[eof $sock]} {
	    catch {close $sock}
	    close_remote $sock
	} else {
		if { $command == "AMSN_LOCK_PING" } {
			puts $sock "AMSN_LOCK_PONG"
		} else {
		    read_remote $command $sock
		}
	   
	}
}


