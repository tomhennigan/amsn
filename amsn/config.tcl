#
# $Id$
#

proc ConfigDefaults {} {
	global config tcl_platform password auto_path advanced_options

	set config(protocol) "9"		;# Which MSN Protocol do you prefer to use: 9
	set config(nossl) 0				;#Disable the use of SSL, so it doesn't requite TLS package: 0|1

	set config(login) ""				;# These are defaults for users without
	set config(save_password) 0	;# a config file: 0|1

	set config(keep_logs) 1			;#Save log files: 0|1

	set config(connectiontype) direct	;# Connection type: direct|http|proxy
	set config(proxy) ""						;# If using proxy, proxy host
	set config(proxytype) "http"			;# Proxy type: http|ssl|socks5
	set config(proxyauthenticate) 0		;# SOCKS5 use username/password
	set config(proxyuser) ""				;# user and password for SOCKS5 proxy
	set config(proxypass) ""				;#

	set config(sound) 1				;#Sound enabled: 0|1
	set config(mailcommand) ""		;#Command for checking mail. Blank for hotmail
        set config(notifytyping) 1		;#Send typing notifications
        set config(soundactive) 0               ;#Typing sound even on active window
	
	set config(chatstyle)	"msn"	;#Chat display style

	#Some Autodetected options
	if {$tcl_platform(os) == "Darwin"} {
		set osversion [string range "$tcl_platform(osVersion)" 0 0]
		if { $osversion == "6"} {
			set config(soundcommand) "utils/qtplay \$sound";#Soundplayer for Mac OS 10.2 Jaguar
		} else {
			set config(soundcommand) "./sndplay \$sound";#Soundplayer for Mac OS 10.3 Panther
		}
	   set config(browser) "open \$url"
	   set config(notifyXoffset) 100
	   set config(notifyYoffset) 75
	   set config(filemanager) "open \$location"   
	} elseif {$tcl_platform(platform) == "unix"} {
	   set config(soundcommand) "play \$sound"
	   set config(browser) "mozilla \$url"
	   set config(notifyXoffset) 0
	   set config(notifyYoffset) 0
	   set config(filemanager) "my_filemanager open \$location"
	} elseif {$tcl_platform(platform) == "windows"} {
	   set config(soundcommand) "utils/plwav.exe \$sound"
	   set config(browser) "explorer \$url"
	   set config(notifyXoffset) 0
	   set config(notifyYoffset) 28
	   set config(filemanager) "explorer \$location"
	} else {
	   set config(soundcommand) ""	;#Sound player command
	   set config(browser) ""			;#Browser command
	   set config(filemanager) ""		;#Filemanager command

	   set config(notifyXoffset) 0	;#Notify window offsets
	   set config(notifyYoffset) 0
	}
	
	set config(autoidle) 1				;#Enable/disable auto-idle feature: 0|1
	set config(idletime) 5				;#Minutes before setting status to idle
	set config(autoaway) 1				;#Enable/disable auto-away feature: 0|1
	set config(awaytime) 10				;#Minutes before setting status to away

	set config(orderbygroup) 0			;#Order contacts by group: 0=No | 1=Groups | 2=Hybrid
	set config(ordergroupsbynormal) 1;#Order groups normal or inverted

	set config(listsmileys) 1			;#Show smileys in contact list
	set config(chatsmileys) 1			;#Show smileys in chat window

	set config(startoffline) 0			;#Start session as offline (hidden)

	set config(autoftip) 1				;#Detect IP for file transfers automatically
	set config(myip) "127.0.0.1"		;#Your IP
	set config(manualip) "127.0.0.1"		;#Manual IP

	
	#Specific configs for Mac OS X (Aqua) first, and for others systems after
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		set config(wingeometry) 275x400-200+200		;#Main window geometry on Mac OS X
		set config(backgroundcolor)  #ECECEC		;#AMSN Mac OS X background color
		set config(dockbounce) once					;#Dock bouncing on Mac OS X
	} else {
		set config(wingeometry) 275x400-0+0			;#Main window geometry
		set config(backgroundcolor)  #D8D8E0		;#AMSN background color
	}
	
	set config(closingdocks) 0						;#Close button minimizes (or docks) main window
	
	
	
	set config(encoding) auto						;#ANSN encoding

	set config(textsize) 2							;#User text size
	set config(mychatfont) "{Helvetica} {} 000000"	;#User chat font
	set config(winchatsize) "350x320" ;#Default chat window size
	set config(savechatwinsize) 1 ;#Save chat window sizes when changed?

	set config(notifymsg) 1				;#Show notify window when a message arrives
	set config(notifyonline) 1			;#Show notify window when a user goes online
	set config(notifyoffline) 0			;#Show notify window when a user goes offline
	set config(notifystate) 0			;#Show notify window when a user changes status
	set config(notifyemail) 1			;#Show notify window when a new mail arrives

	set config(dock) 0					;#Docking type

	
	#Specific for Mac OS X, if newchatwinstate=1, new windows of message never appear
	if {$tcl_platform(os) == "Darwin"} {
		set config(newchatwinstate) 0		;#Iconify or restore chat window on new chat
		set config(newmsgwinstate) 0		;#Iconify or restore chat window on new message
	} else {
		set config(newchatwinstate) 1		;#Iconify or restore chat window on new chat
		set config(newmsgwinstate) 1		;#Iconify or restore chat window on new message
	}
	set config(flicker) 1				;#Flicker window on new message
	set config(showdisplaypic) 1		;#Show display picture as default


	set config(autochangenick) 1		;# automaticly change nick to custom state

	set config(initialftport) 6891	;#Initial for to be used when sending file transfers
	set config(ftautoaccept) 0

	set config(shownotify) 1 			;#Show notify window (in general, see advanced options)

	#Remote control options
	set config(enableremote) 0
	set config(remotepassword) ""

	#Blocking detection options
	set config(checkonfln) 0
	set config(checkblocking) 0
	set config(blockinter1) 60
	set config(blockinter2) 300
	set config(blockinter3) 5
	set config(blockusers) 2
	set config(showblockedgroup) 0

	set config(emotisounds) 1			;#Play sound on certain emoticons
	set config(animatedsmileys) 1		;#Show animated smileys

	#Custom smileys configuration
	set config(customsmileys) [list]
	set config(customsmileys2) [list]
	set config(custom_smileys) 1
	set config(logsbydate) 1
	set config(p4c_name) ""
	
	if {$tcl_platform(os) != "Darwin"} {
	set config(convertpath) "convert"								;#Path for convert (from imagemagick)
	} else {
	set config(convertpath) "/usr/local/bin/convert"		;#Path for convert (from imagemagick) on Mac OS X
	}

	#Advanced options, not in preferences window
	# Create the entry in the list and then, set
	# the variable at bottom
	
	#List like:
	#	"" trans_section_name_1
	#  optionname1 type1 trans_name1 trans_desc1(optional)
	#  optionname2 type2 trans_name2 trans_desc2(optional)
	#  ...
	#
	# type can be: bool | int | str | folder
	set advanced_options [list \
		[list title appearance] \
		[list local tooltips bool tooltips] \
		[list local emailsincontactlist bool emailsinlist] \
		[list local leavejoinsinchat bool leavejoinsinchat] \
		[list local animatenotify bool animatenotify] \
		[list local enablebanner bool enablebanner] \
		[list local truncatenames bool truncatenames1] \
		[list local truncatenicks bool truncatenames2] \
		[list local showtimestamps bool timestamps] \
		[list local savechatwinsize bool savechatwinsize] \
		[list local winchatsize str defchatwinsize] \
		[list local startontray bool startontray] \
		[list local charscounter bool charscounter] \
                [list local strictfonts bool strictfonts] \
		[list title notifyoffset] \
		[list local notifyXoffset int xoffset] \
		[list local notifyYoffset int yoffset] \
		[list title prefalerts] \
		[list local notifyonline bool notify1] \
		[list local notifyoffline bool notify1_5] \
		[list local notifystate bool notify1_75] \
		[list local notifymsg bool notify2] \
		[list local notifyemail bool notify3] \
                [list local soundactive bool soundactive] \
		[list local recentmsg bool recentmsg] \
		[list title connection] \
		[list local getdisppic bool getdisppic] \
		[list local checkemail bool checkemail] \
		[list local autoconnect bool autoconnect autoconnect2] \
		[list local keepalive bool keepalive natkeepalive]\
		[list local start_ns_server str notificationserver]\
		[list title MSN] \
		[list local displayp4context bool displayp4context] \
		[list local p4contextprefix str p4contextprefix] \
		[list title others] \
		[list local allowbadwords bool allowbadwords] \
		[list local receiveddir folder receiveddir] \
		[list local notifytyping bool notifytyping] \
		[list local lineflushlog bool lineflushlog] \
		[list local autocheckver bool autocheckver] \
		[list local storename bool storenickname] \
		[list local globaloverride bool globaloverride ] \
		[list global disableprofiles bool disableprofiles] \
	]
	set config(tooltips) 1				;#Enable/disable tooltips
	set config(animatenotify) 1		;#Animate notify window
	set config(disableuserfonts) 0	;#Disable custom fonts for other users (use always yours).
	set config(autoconnect) 0			;#Automatically connect when amsn starts
	set config(receiveddir) ""			;#Directory where received files are stored
	set config(lineflushlog) 1			;#Flush log files after each line
	set config(autocheckver) 1			;#Automatically check for newer versions on startup
	set config(truncatenames) 1		;#Truncate nicknames longer than window width in windows' title
	set config(truncatenicks) 0		;#Truncate nicknames longer than window width in chat windows
	set config(keepalive) 1				;#Keep alive connection (ping every minute)
	set config(showtimestamps) 1		;#Show timestamps on messages ("Yes" by default)
	set config(leftdelimiter) \[		;#Left Timestamps' delimiter  '[' by default
	set config(rightdelimiter) \]		;#Right Timestamps' delimiter ']' by default
	set config(start_ns_server) "messenger.hotmail.com:1863"
	set config(allowbadwords) 1		;#Disable censure on nicks
	set config(enablebanner) 1		;#Show or Hide AMSN Banner (By default Show)
	set config(startontray) 0		;#Start amsn on tray icon only (hide contact list)
	set config(storename) 1			;#Store original nick in a variable when go to custom states to revert it when go back
	set config(strictfonts) 0		;#Use strict fonts' size in _ALL_ AMSN's fonts (Disabled by default)
	set config(emailsincontactlist) 0	;#Display emails instead of nicks in the contact list
	set config(leavejoinsinchat)	1	;#Display leave/join notifications in chat text area
	set config(charscounter)	1	;#Display typed characters counter
	set config(checkemail)	1	;#Show inbox email notification line
	set config(recentmsg) 0		;#Recent message window closing protection
	set config(displayp4context) 1	;#Accept P4-Context fieds
	set config(p4contextprefix) "P4C: " ; #Prefix for P4-Context messages
	set config(globalnick) ""		;#The global custom nickname (pattern), disabled by default
	set config(globaloverride) 0		;# Sets whether Global nicknames pattern should override custom nicks, disabled by default

	#System options, not intended to be edited (unless you know what you're doing)
	set password ""
	set config(withnotebook) 0			;#Use notebook tabs in contact list

	set config(adverts) 0				;#Enable banner advertisements
	set config(displaypic) "amsn.png"                   ;# Display picture
	set config(getdisppic) 1
	set config(notifwidth) 150			;#Notify window width
	set config(notifheight) 100		;#Notify window height
}

namespace eval ::config {

	proc GlobalDefaults {} {
		global gconfig tcl_platform
		
		setGlobalKey last_client_version ""		
		setGlobalKey language "en"			;#Default language
		setGlobalKey skin "default"			;#AMSN skin
		setGlobalKey disableprofiles 0 ;#Disable profiles (useful for cybercafes or similar)

		#Specific configs for Mac OS X (Aqua) first, and for others systems after
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			setGlobalKey basefont [list {Lucida Grande} 11 normal]	;#AMSN Mac OS X base font
		} elseif {$tcl_platform(platform) == "windows"} {
			setGlobalKey basefont [list Arial 10 normal]
		} else {
			setGlobalKey basefont [list Helvetica 11 normal]	;#AMSN base font
		}
	}

	proc get {key} {
		global config
		return [set config($key)]
	}

	proc getKey {key} {
		global config
		return [set config($key)]
	}
	
	proc getVar {key} {
		return "config($key)"
	}

	proc setKey {key value} {
		global config
		set config($key) $value
	}

	proc getGlobalKey {key} {
		global gconfig
		return [set gconfig($key)]
	}
	
	proc getGlobalVar {key} {
		return "gconfig($key)"
	}

	proc setGlobalKey {key value} {
		global gconfig
		set gconfig($key) $value
	}


	proc NewGConfigEntry  {cstack cdata saved_data cattr saved_attr args} {
		global gconfig
		upvar $saved_data sdata

		set gconfig($sdata(${cstack}:attribute)) $sdata(${cstack}:value)

		return 0

	}


	proc loadGlobal {} {
		global gconfig HOME2 HOME

		GlobalDefaults
		
		if { [info exists HOME2] } {
			set config_file [file join ${HOME2} "gconfig.xml"]
		} else {
			set config_file [file join ${HOME} "gconfig.xml"]
		}

		if { [file exists $config_file] } {

			if { [catch {
				set file_id [sxml::init $config_file]

				sxml::register_routine $file_id "config:entry" "::config::NewGConfigEntry"
				set val [sxml::parse $file_id]
				sxml::end $file_id
			} res] } {
				::amsn::errorMsg "[trans corruptconfig ${config_file}.old]"
				file copy "$config_file" "$config_file.old"
			}
		}
	}

	proc saveGlobal {} {
		global tcl_platform gconfig HOME2 version

		if { [catch {
				if {$tcl_platform(platform) == "unix"} {
			set file_id [open "[file join ${HOME2} gconfig.xml]" w 00600]
				} else {
					set file_id [open "[file join ${HOME2} gconfig.xml]" w]
				}
			} res]} {
			return 0
		}

		puts $file_id  "<?xml version=\"1.0\"?>\n\n<config>"
		::config::setGlobalKey last_client_version $version

		foreach var_attribute [array names gconfig] {
			set var_value $gconfig($var_attribute)
			set var_value [::sxml::xmlreplace $var_value]
			puts $file_id "   <entry>\n      <attribute>$var_attribute</attribute>\n      <value>$var_value</value>\n   </entry>"
		}

		puts $file_id "</config>"

		close $file_id

	}

}

proc save_config {} {
   global tcl_platform config HOME HOME2 version password emotions

   status_log "save_config: saving config for user [::config::getKey login] in $HOME]\n" black
   
   if { [catch {
         if {$tcl_platform(platform) == "unix"} {
	    set file_id [open "[file join ${HOME} config.xml]" w 00600]
         } else {
            set file_id [open "[file join ${HOME} config.xml]" w]
         }
      } res]} {
		return 0
	}

    status_log "save_config: saving config_file. Opening of file returned : $res\n"
   set loginback $config(login)
   set passback $password

   # using default, make sure to reset config(login)
   if { $HOME == $HOME2 } {
   	set config(login) ""
	set password ""
   }


    puts $file_id  "<?xml version=\"1.0\"?>\n\n<config>"

    foreach var_attribute [array names config] {
      set var_value $config($var_attribute)
       if { "$var_attribute" != "remotepassword" && "$var_attribute" != "customsmileys" && "$var_attribute" != "customsmileys2"} {
		set var_value [::sxml::xmlreplace $var_value]
	   puts $file_id "   <entry>\n      <attribute>$var_attribute</attribute>\n      <value>$var_value</value>\n   </entry>"
       }
    }

    if { ($config(save_password)) && ($password != "")} {

	set key [string range "${loginback}dummykey" 0 7]
	binary scan [::des::encrypt $key "${password}\n"] h* encpass
	puts $file_id "   <entry>\n      <attribute>encpassword</attribute>\n      <value>$encpass</value>\n   </entry>"
    }

    set key [string range "${loginback}dummykey" 0 7]
    binary scan [::des::encrypt $key "${config(remotepassword)}\n"] h* encpass
    puts $file_id "   <entry>\n      <attribute>remotepassword</attribute>\n      <value>$encpass</value>\n   </entry>\n"

    foreach custom $config(customsmileys2) {
	puts $file_id "   <emoticon>"
	foreach attribute [array names emotions] {
	    if { [string match "${custom}_*" $attribute ] } {
		set var_attribute [::sxml::xmlreplace [string map [list "${custom}_" ""] $attribute ]]
		set var_value [::sxml::xmlreplace $emotions($attribute)]
		puts $file_id "      <$var_attribute>$var_value</$var_attribute>"
	    }
	}
	puts $file_id "   </emoticon>\n"
    }

    puts $file_id "</config>"

    close $file_id

    set config(login) $loginback
    set password $passback

    status_log "save_config: Config saved\n" black
    

}

proc new_config_entry  {cstack cdata saved_data cattr saved_attr args} {
    global config
    upvar $saved_data sdata

    set config($sdata(${cstack}:attribute)) $sdata(${cstack}:value)

    return 0

}

proc load_config {} {
	global config HOME password protocol clientid tcl_platform

	create_dir "[file join ${HOME} smileys]"

	set user_login [::config::getKey login]
	status_log "load_config: Started. HOME=$HOME, config(login)=$user_login\n"
	ConfigDefaults

	if { [file exists [file join ${HOME} "config.xml"]] } {
		status_log "load_config: loading file [file join ${HOME} config.xml]\n" blue

		if { [catch {
			set file_id [sxml::init [file join ${HOME} "config.xml"]]

			sxml::register_routine $file_id "config:entry" "new_config_entry"
			sxml::register_routine $file_id "config:emoticon" "new_custom_emoticon"
			set val [sxml::parse $file_id]
			sxml::end $file_id
			status_log "load_config: Config loaded\n" green
			
		} res] } {
			::amsn::errorMsg "[trans corruptconfig [file join ${HOME} "config.xml.old"]]"
			file copy [file join ${HOME} "config.xml"] [file join ${HOME} "config.xml.old"]
		}
		
		#Force the change of the default background color
		
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			set bgcolormac [::config::getKey backgroundcolor]
			if { $bgcolormac=="#D8D8E0" } {
				::config::setKey backgroundcolor #ECECEC
				}
			#Force the change of new window to be raised, not iconified (not supported on TkAqua)
			::config::setKey newmsgwinstate 0
			#Force the change to not start amsn on tray if someone choosed that in advanced preferences
			::config::setKey startontray 0
			# Force the change of the default sound command
			# For Mac OS X users who used aMSN 0.90 at the beggining
			set soundmac [string range "[::config::getKey soundcommand]" 1 11]
				if { $soundmac=="program_dir" } {
					set osversion [string range "$tcl_platform(osVersion)" 0 0]
					if { $osversion == "6"} {
						set config(soundcommand) "utils/qtplay \$sound"
					} else {
						set config(soundcommand) "./sndplay \$sound"
					}
				}			
			}
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

    # WebCam: clientid is 268435508, but since we dont support webcam, this is the default:
    set clientid "268435500"

	# Load up the personal states
	LoadStateList
    if { [winfo exists .my_menu] } {CreateStatesMenu .my_menu}
    if { [::config::getKey login] == "" } {
	status_log "load_config: Empty login !!! FIXING\n" red
	::config::setKey login $user_login
    }
    
    if { $config(enableremote) } {
	init_remote_DS
    } 
    
}


#///////////////////////////////////////////////////////////////////////////////
# LoadLoginList ()
# Loads the list of logins/profiles from the profiles file in the HOME dir
# sets up the first user in list as config(login)
proc LoadLoginList {{trigger 0}} {
	global HOME HOME2 config

	#puts stdout "called loadloginlist\n"
	status_log "LoadLoginList: starting\n" blue
	
	if { $trigger != 0 } {
		status_log "LoadLoginList: getting profiles\n" blue
	} else {
		set HOME2 $HOME
	}
		

	if {([file readable "[file join ${HOME} profiles]"] != 0) && ([file isfile "[file join ${HOME} profiles]"] != 0)} {
		set HOMEE $HOME
	} elseif {([file readable "[file join ${HOME2} profiles]"] != 0) && ([file isfile "[file join ${HOME2} profiles]"] != 0)} {
		set HOMEE $HOME2
	} else {
		return 1
	}

	status_log "LoadLoginList: HOME=$HOME, HOME2=$HOME2, HOMEE=$HOMEE\n" blue
	
	
	set file_id [open "[file join ${HOMEE} profiles]" r]
	gets $file_id tmp_data
	if {$tmp_data != "amsn_profiles_version 1"} {	;# config version not supported!
		msg_box [trans wrongprofileversion $HOME]
		close $file_id
		
		status_log "LoadLoginList: Recreating profiles file\n" blue

		if { [catch {set file_id [open "[file join ${HOMEE} profiles]" w]}]} {
			return -1
		}

		puts $file_id "amsn_profiles_version 1"
		#Recreate profiles file
		if { [catch {set folders [glob -directory ${HOMEE} -tails -types d *]}] } {
			return -1
		}
		foreach folder $folders {
			if {[file readable [file join ${HOMEE} $folder config.xml]]} {
				puts $file_id "$folder 0"
			}
		}
		close $file_id

		return -1
		set file_id [open "[file join ${HOMEE} profiles]" r]
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
		status_log "LoadLoginList: adding profile [lindex $tmp_data 0] with lock num $locknum\n" blue
	}
	close $file_id

	
	# Modify HOME dir to current profile, chose a non locked profile, if none available go to default
	if { $trigger == 0 } {
		
		#If profiles are disabled, don't load one
		if { [::config::getGlobalKey disableprofiles] == 1 } {
			status_log "LoadLoginList: profiles disabled, ignoring\n" blue		
			::config::setKey login ""
			set HOME2 $HOME
			return
		}		
		
		status_log "LoadLoginList: getting an initial profile\n" blue
		set HOME2 $HOME
		set flag 0
		for { set idx 0 } { $idx <= [LoginList size 0] } {incr idx 1} {
			if { [CheckLock [LoginList get $idx]] != -1 } {
				LockProfile [LoginList get $idx]
				status_log "LoadLoginList: profile [LoginList get $idx] is free, locking\n"
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
			set config(login) "$temp"
			status_log "LoadLoginList: we found a free profile: $temp\n" green		
		} else {
			status_log "LoadLoginList: using default profile\n" green			
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
				# User dosen't exist, proceed normally
				for {set idx [expr {[array size ProfileList] - 1}]} {$idx >= 0} {incr idx -1} {
					set ProfileList([expr {$idx + 1}]) $ProfileList($idx)
					set LockList([expr {$idx + 1}]) $LockList($idx)
				} 
				set ProfileList(0) $email
				set LockList(0) $lock
			} else {
				# This means user exists, and we make him newest
				#set emaillock $LockList([expr {[expr {$idx-1}] / 2}])
				set emaillock $LockList([expr {($idx-1) / 2}])
				for {set idx [lindex $tmp_list [expr {$idx - 1}]]} {$idx > 0} {incr idx -1} {
					set ProfileList($idx) $ProfileList([expr {$idx - 1}])
					set LockList($idx) $LockList([expr {$idx - 1}])
				}
				set ProfileList(0) $email
				set LockList(0) $emaillock
			}
		}

		unset {
			set tmp_list [array get ProfileList]
			set idx [lsearch $tmp_list "$email"]
			if { $idx != -1 } {
				for {set idx [lindex $tmp_list [expr {$idx - 1}]]} {$idx < [expr {[array size ProfileList] - 1}]} {incr idx} {
					set ProfileList($idx) $ProfileList([expr {$idx + 1}])
					set LockList($idx) $LockList([expr {$idx + 1}])
				}
			unset LockList([expr {[array size ProfileList] - 1}])
			unset ProfileList([expr {[array size ProfileList] - 1}])
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
			return [expr {[array size ProfileList] - 1}]
		}

		show {
			for {set idx 0} {$idx < [array size ProfileList]} {incr idx} {
				status_log "$idx : $ProfileList($idx)\n"
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
	status_log "ConfigChange: $email\n" blue
	global HOME HOME2 password config log_dir lockSock

	if { $email != "" } {
		status_log "ConfigChange: Valid email\n" green
		
		if { $email != $config(login) } {
			status_log "ConfigChange: Email changed\n" blue
			
			if { [LoginList exists 0 $config(login)] == 1 } {
				save_config
			}
		
			if { [LoginList exists 0 $email] == 1 } {
			
				status_log "ConfigChange: Login exists\n" blue
				
				# Profile exists, make the switch
				set OLDHOME $HOME
		
				set dirname [split $email "@ ."]
				set dirname [join $dirname "_"]
				set HOME "[file join $HOME2 $dirname]"
						
				if { [CheckLock $email] == -1 } { 
					status_log "ConfigChange: Profile is locked\n" blue
					
					msg_box [trans profileinuse]
					set HOME $OLDHOME
					
					# Reselect previous element in combobox
					set cb [$window list get 0 [LoginList size 0]]
					set index [lsearch $cb $config(login)]
					$window select $index
				} else {
					status_log "ConfigChange: Profile is free\n" green
				
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
					
					config::setKey login $email
					load_config
		
					set config(protocol) 9
		
					LoginList add 0 $email
					set log_dir "[file join ${HOME} logs]"
				
					# port isn't taken or port taken by other program, meaning profile ain't locked
					# let's setup the new lock
					LockProfile $email
					SaveLoginList
					cmsn_draw_offline
					
				}
			}
		}
		
		if { [winfo exists .login] } {
			.login.main.f.f.passentry2 delete 0 end
			if { [info exists password] } {
				.login.main.f.f.passentry2 insert 0 $password
			}
		}
	} 
}


#///////////////////////////////////////////////////////////////////////////////
# SwitchProfileMode ( value )
# Switches between default and profiled mode, called from radiobuttons
# value : If 1 use profiles, if 0 use default profile
proc SwitchProfileMode { value } {
	global lockSock HOME HOME2 config log_dir loginmode

	if { $value == 1 } {
		if { $HOME == $HOME2 } {
			for { set idx 0 } { $idx <= [LoginList size 0] } { incr idx } {
				if { [CheckLock [LoginList get $idx]] != -1 } {
					set window .login.main.f.f.box
					set cb [$window list get 0 [LoginList size 0]]
					set index [lsearch $cb [LoginList get $idx]]
					$window select $index
					break
				}
			}

			if { [LoginList size 0] == -1 } {
				msg_box [trans noprofileexists]
				set loginmode 0
				# Going back to default profile
				set loginmode 0
				RefreshLogin .login.main.f.f 1
			} elseif { $idx > [LoginList size 0] } { 
				msg_box [trans allprofilesinuse] 
				# Going back to default profile
				set loginmode 0
				RefreshLogin .login.main.f.f 1
			}
		# Else we are already in a profile, select that profile in combobox
		} else {
			set window .login.main.f.f.box
			set cb [$window list get 0 [LoginList size 0]]
			set index [lsearch $cb $config(login)]
			$window select $index
			unset window
		}
	} else {
		# Switching to default profile, remove lock on previous profiles if needed
		
		# Make sure we delete old lock
		if { [info exists lockSock] } {
			if { $lockSock != 0 } {
				close $lockSock
				unset lockSock
			}
		}
		if { $config(login) != "" } {
			LoginList changelock 0 $config(login) 0
			SaveLoginList
		}

		# Load default config 
		set HOME $HOME2
		
		config::setKey login ""
		load_config
		set log_dir ""
				
		# Set variables for default profile
		set config(save_password) 0
		set config(keep_logs) 0
	}
}


#///////////////////////////////////////////////////////////////////////////////
# CreateProfile ( email )
# Creates a new profile
# email : email of new profile
proc CreateProfile { email } {
	global HOME HOME2 config log_dir password lockSock loginmode
	
	if { [LoginList exists 0 $email] == 1 } {
		msg_box [trans profileexists]
		return -1
	}

	# If first time loading from default profile, make sure .amsn/config exists
	if { ($HOME == $HOME2) && ([file exists [file join $HOME2 config.xml]] == 0) } {
		save_config
	}
	
	set oldlogin $config(login)

	status_log "Creating new profile for $email\n" blue
	# Create a new profile with $email
	# Set HOME dir and create it
	set dirname [split $email "@ ."]
	set dirname [join $dirname "_"]
	set newHOMEdir "[file join $HOME2 $dirname]"
	create_dir $newHOMEdir
	set log_dir "[file join ${newHOMEdir} logs]"
	create_dir $log_dir
	
	# Load default config initially
	file copy -force [file join $HOME2 config.xml] $newHOMEdir
	
	set oldhome $HOME
	set HOME $newHOMEdir
	
	::config::setKey login $email
	load_config
	save_config
	
	::config::setKey login $oldlogin
	set HOME $oldhome
	load_config
	unset oldhome
	unset newHOMEdir
		
	# Add to login list
	LoginList add 0 $email 0
	SaveLoginList

	# Redraw combobox with new profile
	if { [winfo exists .login] } {
		set loginmode 1
		RefreshLogin .login.main.f.f 1
		.login.main.f.f.box list delete 0 end
		set idx 0
		set tmp_list ""
		while { [LoginList get $idx] != 0 } {
			lappend tmp_list [LoginList get $idx]
			incr idx
		}
		eval .login.main.f.f.box list insert end $tmp_list
		unset idx
		unset tmp_list

		# Select the new profile in combobox
		set window .login.main.f.f.box
		set cb [$window list get 0 [LoginList size 0]]
		set index [lsearch $cb $email]
		$window select $index
	}
	return 0
}

proc gethomes {} {
	global HOME HOME2 config log_dir
	status_log "HOME = $HOME \nHOME2 = $HOME2\nlogin = $config(login)\nlog_dir = $log_dir\n"
}

#///////////////////////////////////////////////////////////////////////////////
# DeleteProfile ( email )
# Delete profile given by email, has to be different than the current profile
# entrypath : Path to the combobox containing the profiles list in preferences
proc DeleteProfile { email entrypath } {
	global config HOME2
	if { $email == "" } {
		return
	}
	#Reload profiles file
	LoadLoginList 1
	# Make sure profile isn't locked
	if { $email == $config(login) } {
		msg_box [trans cannotdeleteprofile]
		return
	}
	if { [CheckLock $email] == -1 } {
		msg_box [trans cannotdeleteprofile]
		return
	}
	
	set focus [focus]
	if { $focus == "" } {
		set focus ".cfg"
	}
	set answer [tk_messageBox -message "[trans confirmdelete ${email}]" -type yesno -icon question -parent $focus]

	if {$answer == "no"} {
	return
	}


	set dir [split $email "@ ."]
	set dir [join $dir "_"]
	

	set entryidx [$entrypath curselection]
	if {$entryidx == "" } {
		set entryidx 0
	}
	
	catch { file delete -force [file join $HOME2 $dir] }
	$entrypath list delete $entryidx
	$entrypath select 0
	LoginList unset 0 $email
       
	# Lets save it into the file
	SaveLoginList

}

#///////////////////////////////////////////////////////////////////////////////
# CheckLock ( email )
# Check Lock of profile given by email
# Return -1 if profile is already locked, returns 0 otherwise
proc CheckLock { email } {
	global response LockList
	set response ""
	set Port [LoginList getlock 0 $email]
	status_log "CheckLock: LoginList getlock called. Lock=$Port\n" blue
	if { $Port != 0 } {
		if { [catch {socket -server phony $Port} newlockSock] != 0  } {
			status_log "CheckLock Port is already in use: $newlockSock\n" red
			# port is taken, let's make sure it's a profile lock
			if { [catch {socket localhost $Port} clientSock] == 0 } {
				status_log "CheckLock: Can connect to port. Sending PING\n" blue
				fileevent $clientSock readable "lockcltHdl $clientSock"
				fconfigure $clientSock -buffering line
				puts $clientSock "AMSN_LOCK_PING"
				vwait response
				
				#set response [gets $clientSock]
				if { $response == "AMSN_LOCK_PONG" } {
					status_log "CheckLock: Got PONG response\n" green
					# profile is locked
					close $clientSock
					return -1
				} else {
					status_log "CheckLock: another program using port $Port. Reseting to 0\n" blue
					# other non amsn program is using the lock port, we better reset the lock to 0
					LoginList changelock 0 $email 0
				}
			}
		} else {
			status_log "CheckLock: Port $Port is free!!\n" green
			close $newlockSock
		}
	} else {
		status_log "CheckLock: Port is zero\n" blue
		
	}
	return 0
}

proc phony { sock } {
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
		set Port [expr {$Port * 5000}]
		set Port [expr {int($Port)}]
		set Port [expr {$Port + 60535}]
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
	status_log "LockProfile: Locking $email\n" blue
	global lockSock
	set trigger 0
	while { $trigger == 0 } {
		set Port [GetRandomProfilePort]
		status_log "LockProfile: Got random port $Port\n" blue
		if { [catch {socket -server lockSvrNew $Port} newlockSock] == 0  } {
			# Got one
			LoginList changelock 0 $email $Port
			set lockSock $newlockSock
			set trigger 1
		} else {
			status_log "Failed to use port $Port: $newlockSock\n" red
		}
	
	}
	if { $trigger == 1 } {
		#vwait events
	}
}


proc lockSvrNew { sock addr port} {
	status_log "lockSvrNew: Accepting connection on port $port\n" blue

#	if { $addr == "127.0.0.1" } {
		fileevent $sock readable "lockSvrHdl $sock"
		fconfigure $sock -buffering line
#	}
}

proc lockSvrHdl { sock } {
	status_log "lockSvrHdl: handling connection\n" blue
	
	set command [gets $sock]
	
	if {[eof $sock]} {
	    catch {close $sock}
	    close_remote $sock
	} else {
		if { $command == "AMSN_LOCK_PING" } {
			status_log "lockSvrHdl: PING - PONG\n" blue
			
			catch {puts $sock "AMSN_LOCK_PONG"}
		} else {
		    read_remote $command $sock
		}
	   
	}
}

#///////////////////////////////////////////////////////////////////////
# create_dir(path)
# Creates a directory
proc create_dir {path} {
   global tcl_platform

   if {[file isdirectory $path] == 0} {
      if { [catch {file mkdir $path} res]} {
         return -1
      }
      if {$tcl_platform(platform) == "unix"} {
         file attributes $path -permissions 00700
      }
      return 0
   } else {
      return 1
   }
}
#///////////////////////////////////////////////////////////////////////

if { $initialize_amsn == 1 } {
	###############################################################
	create_dir $HOME
	create_dir $HOME/plugins
	create_dir $HOME/skins
	#create_dir $log_dir
	#create_dir $files_dir
	ConfigDefaults
	::config::loadGlobal
	
	
	;# Load of logins/profiles in combobox
	;# Also sets the newest login as config(login)
	;# and modifies HOME with the newest user
	if { [LoadLoginList]==-1 } {
		exit
	}

	load_lang ;#Load default english language
	scan_languages
	load_lang [::config::getGlobalKey language]

	global gui_language
	set gui_language [::config::getGlobalKey language]

	load_config		;# So this loads the config of this newest dude

	# Init smileys
	load_smileys
}
