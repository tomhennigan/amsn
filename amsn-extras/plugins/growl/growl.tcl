namespace eval ::growl {
    variable config
    variable configlist
    
    ###############################################
	# ::growl::InitPlugin dir                     #
	# ------------------------------------------- #
	# Load proc of Growl Plugin                   #
	###############################################	
	proc InitPlugin { dir } {
    	::plugins::RegisterPlugin growl

    	#Package require Growl extension
    	if {![catch {package require growl}]} {
			#Continue..
    	} else {
   		 	plugins_log growl "Growl Tcl Binding is missing from aMSN, compatible with Mac OS X only\n"
   		 	msg_box "Growl Tcl Binding is missing from aMSN, compatible with Mac OS X only\n"
   		 	::plugins::UnLoadPlugin "growl"
   			return 0
    	}
    	
    	#Command to Growl, register application aMSN with 6 kinds of notification
    	#Use default icon inside the growl folder
    	catch {growl register aMSN "Online Newstate Offline Newmessage Pop Nudge" $dir/growl.png}
    	
    	#Register events for growl plugin
		::growl::RegisterEvent
		
		#Load lang files
		::growl::LoadLangFiles $dir
		
    	#Default config for the plugin
		::growl::ConfigArray
		
    	#Add items to configure window
		::growl::ConfigList
	}
	#####################################
	# ::growl::RegisterEvent            #
	# --------------------------------- #
	# Register events to plugin system  #
	#####################################	
	proc RegisterEvent {} {
	   	::plugins::RegisterEvent growl UserConnect online
    	::plugins::RegisterEvent growl chat_msg_received newmessage
    	::plugins::RegisterEvent growl ChangeState changestate
	}
	
	#####################################################
	# ::growl::LoadLangFiles dir       					#
	# ------------------------------------------------- #
	# Load lang files, only if version is 0.95			#
	# Because 0.94 do not support lang keys for plugins #
	#####################################################
	proc LoadLangFiles {dir} {
		if {![::growl::version_094]} {
			set langdir [append dir "/lang"]
			set lang [::config::getGlobalKey language]
			load_lang $lang $langdir
		}
	}
	########################################
	# ::growl::ConfigArray                 #
	# -------------------------------------#
	# Add config array with default values #
	########################################	
	proc ConfigArray {} {
	    array set ::growl::config {
			userconnect {1}
			lastmessage {1}
			lastmessage_outside {1}
			changestate {0}
			offline {0}
    	}
	}
	########################################
	# ::growl::ConfigList                  #
	# -------------------------------------#
	# Add items to configure window        #
	########################################			
	proc ConfigList {} {
	#Use lang items only on aMSN 0.95
	if {[::growl::version_094]} {
	   	set ::growl::configlist [list \
			  [list bool "[trans notify1]"  userconnect] \
			  [list bool "[trans notify2]" lastmessage] \
			  [list bool "Show notification for last message received only if focus is outside aMSN" lastmessage_outside] \
			  [list bool "[trans notify1_75]" changestate] \
			  [list bool "[trans notify1_5]" offline] \
			 ]
		} else {
			set ::growl::configlist [list \
			  [list bool "[trans notify1]"  userconnect] \
			  [list bool "[trans notify2]" lastmessage] \
			  [list bool "[trans growl_lastmessage_outside]" lastmessage_outside] \
			  [list bool "[trans notify1_75]" changestate] \
			  [list bool "[trans notify1_5]" offline] \
			 ]
		}
	}
	
    ###############################################
	# ::growl::online event evpar                 #
	# ------------------------------------------- #
	# Show the online notification                #
	###############################################
    proc online {event evpar} {
    	#Get config from plugin.tcl file
    	variable config
    	#Upvar 2 is necessary most of times
		upvar 2 evpar newvar
    	upvar 2 user user
		#Define nickname and email variables
		set nickname [::abook::getDisplayNick $user]
		set email $user
		#Send notification to Growl
		#Use contact's avatar as picture if possible (via getpicture)
		if {$config(userconnect)} {
			catch {growl post Online $nickname "[trans logsin]." [::growl::getpicture $email]}
		}
    }
    
    ###############################################
	# ::growl::newmessage event evpar             #
	# ------------------------------------------- #
	# Show a notification when we receive         #
	# a message and we are not in aMSN app.       #
	###############################################
    proc newmessage {event evpar} {
    	variable config
    	upvar 2 evpar newvar
    	upvar 2 msg msg
    	upvar 2 user user
    	upvar 2 chatid chatid
    	#Define the 3 variables, email, nickname and message
    	set email $user
    	set nickname [::abook::getDisplayNick $user]
    		
    		#Verify the config. Show newmessage if we are outside aMSN or just in another chatwindow
    		#Only show the notification if the message is not from us
    		#Use contact's avatar as picture if possible (via getpicture)

    		if { $config(lastmessage_outside) } {
    			if { (($email != [::config::getKey login]) && [focus] == "") && $msg != "" && $config(lastmessage)} {
    				catch {growl post Newmessage $nickname $msg [::growl::getpicture $email]}
    			}
    		} else {
    			#Verify if we are using 0.95
    			if {![version_094]} {
    				#Support for tab window
    				if {[::ChatWindow::UseContainer]} {
    					if { (($email != [::config::getKey login]) && ".[lindex [split [focus] .] 1].[lindex [split [focus] .] 2]" != "[::ChatWindow::For $chatid]") && $msg != "" && $config(lastmessage)} {
    						catch {growl post Newmessage $nickname $msg [::growl::getpicture $email]}
    					}
    				#Support for non-tab window
    				} else {
    		  			if { (($email != [::config::getKey login]) && ".[lindex [split [focus] .] 1]" != "[::ChatWindow::For $chatid]") && $msg != "" && $config(lastmessage)} {
    						catch {growl post Newmessage $nickname $msg [::growl::getpicture $email]}
    					}
    				}
    			#Support for 0.94
    			} else {
    					if { (($email != [::config::getKey login]) && ".[lindex [split [focus] .] 1]" != "[::ChatWindow::For $chatid]") && $msg != "" && $config(lastmessage)} {
    						catch {growl post Newmessage $nickname $msg [::growl::getpicture $email]}
    					}
    			}
    		}
 	}
        
    ###############################################
	# ::growl::changestate event evpar            #
	# ------------------------------------------- #
	# Show a notification when                    #
	# a contact change state or go offline        #
	###############################################
	proc changestate {event evpar} {
		variable config
		upvar 2 evpar newvar
		upvar 2 user user
		upvar 2 substate substate
		#Define the 3 variables
		set newstate $substate
		set email $user
		set nickname [::abook::getDisplayNick $email]
		
		#Show notification if someone change state
		#In order -Online -Idle - Busy -Be Right Back -Away -Out to phone -Lunch
		#Get contact's avatar from getpicture if possible
		if {$config(changestate)} {
			switch -exact $newstate {
			"NLN" {
			catch {growl post Newstate $nickname "[trans changestate $nickname [trans online]]" [::growl::getpicture $email]}
			}
			"IDL" {
			catch {growl post Newstate $nickname "[trans changestate $nickname [trans noactivity]]" [::growl::getpicture $email]}
			}
			"BSY" {
			catch {growl post Newstate $nickname "[trans changestate $nickname [trans busy]]" [::growl::getpicture $email]}
			}
			"BRB" {
			catch {growl post Newstate $nickname "[trans changestate $nickname [trans rightback]]" [::growl::getpicture $email]}
			}
			"AWY" {
			catch {growl post Newstate $nickname "[trans changestate $nickname [trans away]]" [::growl::getpicture $email]}
			}
			"PHN" {
			catch {growl post Newstate $nickname "[trans changestate $nickname [trans onphone]]" [::growl::getpicture $email]}
			}
			"LUN" {
			catch {growl post Newstate $nickname "[trans changestate $nickname [trans gonelunch]]" [::growl::getpicture $email]}
			}
			}
		}
		#If someone change state to Offline, this notification use a different register (Offline) than others notifications (NewState)
		if {$config(offline) && $newstate == "FLN"} {
			catch {growl post Offline $nickname "[trans changestate $nickname [trans offline]]" [::growl::getpicture $email]}
		}
	}
	
    ######################################################
	# ::growl::getpicture email                          #
	# ---------------------------------------------------#
	# Return the path to the actual avatar of the contact#
	# for the picture of the notification. If no         #
	# picture exists, just show aMSN icon                #
	######################################################
	proc getpicture {email} {
		global HOME
		#Get displaypicfile from the abook, so we don't get the actual picture but the picture we received from that user previously
		set filename [::abook::getContactData $email displaypicfile ""]
		#If the picture already exist, return the path to that picture, if the picture do not exist, return the default icon of aMSN
		if { [file readable "[file join $HOME displaypic cache ${filename}].gif"] } {
			return "[file join $HOME displaypic cache ${filename}].gif"
		} else {
			return
		}
	}
	
	############################################
	# ::growl::version_094                     #
	# -----------------------------------------#
	# Verify if the version of aMSN is 0.94    #
	# Useful if we want to keep compatibility  #
	############################################
	proc version_094 {} {
		global version
		scan $version "%d.%d" y1 y2;
		if { $y2 == "94" } {
			return 1
		} else {
			return 0
		}
	}
	


}