#
# $Id$
#

proc ConfigDefaults {} {
	global config tcl_platform password
	set config(login) ""			;# These are defaults for users without
	set config(save_password) 0		;# a config file
	set config(keep_logs) 1
	set config(proxy) ""
	set config(withproxy) 0			;# 1 to enable proxy settings
	set config(proxytype) "http"		;# http|socks
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
	set config(autohotlogin) 1
	set config(autoidle) 1
	set config(idletime) 300	
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
	set config(notifywin) 1
	set config(natip) 0
	set config(dock) 0
	set config(autoconnect) 0
	set config(showtimestamps) 1
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
   global tcl_platform config HOME version password

   if {$tcl_platform(platform) == "unix"} {
		set file_id [open "[file join ${HOME} config]" w 00600]
   } else {
      		set file_id [open "[file join ${HOME} config]" w]
   }
   puts $file_id "amsn_config_version 1"
   set config(last_client_version) $version

   set config_entries [array get config]
   set items [llength $config_entries]
   for {set idx 0} {$idx < $items} {incr idx 1} {
      set var_attribute [lindex $config_entries $idx]; incr idx 1
      set var_value [lindex $config_entries $idx]
      puts $file_id "$var_attribute $var_value"
   }
   if {$config(save_password)} {
      puts $file_id "password ${password}"
   }
   close $file_id
}

proc load_config {} {
   global config HOME password

   if {([file readable "[file join ${HOME} config]"] == 0) ||
       ([file isfile "[file join ${HOME}/config]"] == 0)} {
      return 1
   }
   set file_id [open "${HOME}/config" r]
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
   if {[info exists config(password)]} {
      set password $config(password)
      unset config(password)
   }
   close $file_id
}


#///////////////////////////////////////////////////////////////////////////////
# LoadLoginList ()
# Loads the list of logins/profiles from the profiles file in the HOME dir
# sets up the first user in list as config(login)
proc LoadLoginList {{trigger 0}} {
	global HOME HOME2 config

	if { $trigger != 0 } {
	status_log "getting profiles"
	}

	if {([file readable "[file join ${HOME} profiles]"] != 0) || ([file isfile "[file join ${HOME}/profiles]"] != 0)} {
		set HOMEE $HOME
	} elseif {([file readable "[file join ${HOME2} profiles]"] != 0) || ([file isfile "[file join ${HOME2}/profiles]"] != 0)} {
		set HOMEE $HOME2
	} else {
		return 1
	}
		
	set file_id [open "${HOMEE}/profiles" r]
	gets $file_id tmp_data
	if {$tmp_data != "amsn_profiles_version 1"} {	;# config version not supported!
      		return 1
   	}

	# Clear all list, only seems to work this way
	set idx 0
	while { [LoginList get $idx] != 0 } {
		LoginList unset 0 [LoginList get $idx]
		incr idx
	}

	# Now add profiles from file to list
	while {[gets $file_id tmp_data] != "-1"} {
		LoginList add 0 $tmp_data
	}
	close $file_id
	
	
	# Modify HOME dir to current profile, chose a non locked profile, if none available go to default
	if { $trigger == 0 } {
		set HOME2 $HOME
		set flag 0
		for { set idx 0 } { $idx <= [LoginList size 0] } {incr idx 1} {
			set temp [LoginList get $idx]
			set dirname [split $temp "@ ."]
			set dirname [join $dirname "_"]
			if { [file exists [file join $HOME2 $dirname lock]] != 1 } {
				set flag 1
				break
			}
		}

		if { $flag == 1 } {
			set HOME "[file join $HOME2 $dirname]"
			open "${HOME}/lock" w
		}
		
		#if { [LoginList get 0] != 0 } {
		#	set temp [LoginList get 0]
		#	set dirname [split $temp "@ ."]
		#	set dirname [join $dirname "_"]
		#	set HOME "[file join $HOME2 $dirname]"
		#	set file_id [open "${HOME}/lock" w]
		#}
	}
}


#///////////////////////////////////////////////////////////////////////////////
# SaveLoginList ()
# Saves the list of logins/profiles to the profiles file in the HOME dir
proc SaveLoginList {} {
	global HOME2 tcl_platform

	if {$tcl_platform(platform) == "unix"} {
		set file_id [open "[file join ${HOME2} profiles]" w 00600]
	} else {
      		set file_id [open "[file join ${HOME2} profiles]" w]
	}
	puts $file_id "amsn_profiles_version 1"
	
	set idx [LoginList size 0]
	while { $idx >= 0 } {
		puts $file_id "[LoginList get $idx]"
		incr idx -1
	}
	close $file_id
}


#///////////////////////////////////////////////////////////////////////////////
# LoginList (action age [email])
# Controls information for list of profiles read from the profiles file
# action can be :
#	add : Adds new user to list, or if exists makes this user the newest
#	      (age is ignored)
#	get : Returns the email by age, returns 0 if no email for age exists
#	exists : Checks the email if exists returns 1, 0 if dosent (age is ignored)
#	unset : Removes profile given by email from the list and moves 
#		all elements up by 1 (age is ignored)
#       size : Returns [array size ProfileList] - 1
#	show : Dumps list to status_log, for debugging purposes only
proc LoginList { action age {email ""} } {
	variable ProfileList
	#global ProfileList

	switch $action {
		add {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx == -1 } {
				# User dosen't exist, proceed normaly
				for {set idx [expr [array size ProfileList] - 1]} {$idx >= 0} {incr idx -1} {
					set ProfileList([expr $idx + 1]) $ProfileList($idx)
				} 
				set ProfileList(0) $email
			} else {
				# This means user exists, and we make him newest
				for {set idx [lindex $tmp_list [expr $idx - 1]]} {$idx > 0} {incr idx -1} {
					set ProfileList($idx) $ProfileList([expr $idx - 1])
				}
				set ProfileList(0) $email
			}
		}

		unset {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx != -1 } {
				for {set idx [lindex $tmp_list [expr $idx - 1]]} {$idx < [expr [array size ProfileList] - 1]} {incr idx} {
					set ProfileList($idx) $ProfileList([expr $idx + 1])
				}
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
		
		size {
			return [expr [array size ProfileList] - 1]
		}

		show {
			puts stdout "List is\n"
			for {set idx 0} {$idx < [array size ProfileList]} {incr idx} {
				#status_log "$idx : $ProfileList($idx)\n"
				puts stdout "$idx : $ProfileList($idx)\n"
			}
		}
	}
}


#///////////////////////////////////////////////////////////////////////////////
# ConfigChange ( window email)
# Called when the user selects a combobox item or enters new signin
# email : email of the new profile/login
proc ConfigChange { window email } {
	global HOME HOME2 password config log_dir proftrig
	set proftrig 0
	if { $email != "" } {
		if { [LoginList exists 0 $config(login)] == 1 } {
			save_config
		}

	#if { [info exists password] } {
	#	set password ""
	#}

	status_log "Called ChangeConfig with $email, old is $config(login)\n"
		
	if { $email != $config(login) } {
	if { [LoginList exists 0 $email] == 1 } {
		# Profile exists, make the switch

		set OLDHOME $HOME
		set proftrig 0
		set oldlang $config(language)

		set dirname [split $email "@ ."]
		set dirname [join $dirname "_"]
		set HOME "[file join $HOME2 $dirname]"

		if { [file exists "${HOME}/lock"] == 1 } {
			status_log "lock exists\n"
			msg_box [trans profileinuse]
			set HOME $OLDHOME
			
			# Reselect previous element in combobox
			set cb [$window list get 0 [LoginList size 0]]
			set index [lsearch $cb $config(login)]
			$window select $index
		} else {
			status_log "lock dosent exist\n"
			if { [info exists password] } {
				set password ""
			}

			load_config
			
			if { [file exists "${OLDHOME}/lock"] == 1 } {
				file delete "${OLDHOME}/lock"
			}
			
			open "${HOME}/lock" w

			LoginList add 0 $email
			set log_dir "[file join ${HOME} logs]"
		
			load_lang
			### REPLACE THIS BY MAIN WINDOW REDRAW
			if { $config(language) != $oldlang } {
				msg_box [trans mustrestart]		
			}
		}
	} else {
		# Profile dosent exist, put proftrig to 1 so it asks to create

		# Make sure we delete old lock
		if { [file exists "${HOME}/lock"] == 1 } {
			file delete "${HOME}/lock"
		}

		set proftrig 1
		set config(login) $email
		set config(save_password) 0
		set config(startoffline) 0
	}
	}
	
	if { [winfo exists .login] } {
		.login.c.password delete 0 end
		.login.c.password insert 0 $password
	}
	}
}


#///////////////////////////////////////////////////////////////////////////////
# CreateProfile ( email value )
# Either creates a new profile or uses default profile
# Called from NewProfileAsk
# email : email of new profile
# value : If 1 create new profile, if 0 use default profile
proc CreateProfile { email value } {
	global HOME HOME2 config log_dir password proftrig
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
		LoginList add 0 $email

		# Lock profile
		open "${HOME}/lock" w
	} else {
		status_log "not creating new profile"
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
		set dir [split $email "@ ."]
		set dir [join $dir "_"]
		
		# Make sure profile isn't locked
		if { [file exists [file join $HOME2 $dir lock]] == 1 } {
			msg_box [trans cannotdeleteprofile]
			return
		}
		
		catch { file delete -force [file join $HOME2 $dir] }
		$entrypath list delete [$entrypath curselection]
		$entrypath select 0
		LoginList unset 0 $email
		LoginList show 0

		# Lets save it into the file
		SaveLoginList
	}
}
