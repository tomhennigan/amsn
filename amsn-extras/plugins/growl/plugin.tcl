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