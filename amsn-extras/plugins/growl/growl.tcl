namespace eval ::growl {
    variable config
    variable configlist
	
	#Online notification
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
    
    #New message notification
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
    #Change State notification
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
	
	#Return the path for the contact's avatar to notifications requests
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