namespace eval ::bugbuddy {
    variable timer ""
    variable config
    variable configlist
    variable language
    proc InitPlugin { dir } {
	variable configlist
	variable language
	array set ::bugbuddy::config {
            user {}
	    message {Hi}
            timeout {5000}
        }
	set langdir [file join $dir "lang"]
	set lang [::config::getGlobalKey language]
	load_lang en $langdir
	load_lang $lang $langdir
	::plugins::RegisterPlugin "bugbuddy" 
        set configlist [list \
                            [list str "[trans user]" user] \
			    [list str "[trans message]" message] \
                            [list str "[trans timeout]" timeout] \
			    [list ext "[trans activate]" activate] \
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
