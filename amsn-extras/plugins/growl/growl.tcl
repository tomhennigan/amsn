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
		source [file join $dir growl.tcl]
    	
    	#Package require Growl extension
    	if {![catch {package require growl}]} {
			#Continue..
    	} else {
   		 	status_log "Plugin system: Growl missing\n"
   			return 0
    	}
    	
    	#Command to Growl, register application aMSN with 4 kinds of notification
    	#Use default icon inside the growl folder
    	catch {growl register aMSN "Online Newstate Offline Newmessage" $dir/growl.png}
    	#Register events for witch Growl, when someone come online and when we receive a message
    	::plugins::RegisterEvent growl UserConnect online
    	::plugins::RegisterEvent growl chat_msg_received newmessage
    	::plugins::RegisterEvent growl ChangeState changestate
    	#Default config for the plugin
    	array set ::growl::config {
		userconnect {1}
		lastmessage {0}
		changestate {0}
		offline {0}
    	}
    	#Config dialog with 4 variables in bolean, choose to keep notifications or not
    	set ::growl::configlist [list \
				  [list bool "[trans notify1]"  userconnect] \
				  [list bool "[trans notify2]" lastmessage] \
				  [list bool "[trans notify1_75]" changestate] \
				  [list bool "[trans notify1_5]" offline] \
				 ]
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
    	#Define the 3 variables, email, nickname and message
    	set email $user
    	set nickname [::abook::getDisplayNick $user]
    		#Only show the notification if we are not in aMSN and the message is not from us
    		#Use contact's avatar as picture if possible (via getpicture)
    		if { (($email != [::config::getKey login]) && [focus] == "") && $msg != "" && $config(lastmessage)} {
    			catch {growl post Newmessage $nickname $msg [::growl::getpicture $email]}
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
			catch {growl post Newstate $nickname "[trans changestate $nickname [trans away]]" [::growl::getpicture $email]}
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
			return "icons/growl.png"
		}
	}
	


}