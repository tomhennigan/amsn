namespace eval ::bugbuddy {
    variable timer ""
    variable config
    variable configlist
    proc InitPlugin { dir } {
	variable configlist
	array set ::bugbuddy::config {
            user {}
	    message {Hi}
            timeout {5000}
        }
	::plugins::RegisterPlugin "bugbuddy" 
        set configlist [list \
                            [list str "User" user] \
			    [list str "Message" message] \
                            [list str "Timeout" timeout] \
			    [list ext "Start/Stop" activate] \
                           ]
    }

    proc DeInitPlugin { } {
	variable timer
	after cancel $timer
	set timer ""
    }

    proc activate {} {
	variable timer
	if {$timer == ""} {
	    plugins_log bugbuddy "Started"
	    set timer [after 500 ::bugbuddy::newname]
	} else {
	    plugins_log bugbuddy "Stopped"
	    after cancel $timer
	    set timer ""
	}
    }
    
    proc newname {} {
	variable timer
	variable config
	set timer [after $config(timeout) ::bugbuddy::newname]
	set win [::ChatWindow::For $config(user)]
	::amsn::MessageSend $win 0 $config(message)
	return 0
    }
}