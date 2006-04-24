namespace eval ::gename {
    variable config
    variable configlist
    variable try 0
	variable timer ""

    proc InitPlugin { dir } {

	variable configlist
	plugins_log gename "Welcome to Gename!\n"
	::plugins::RegisterPlugin gename
	::plugins::RegisterEvent gename ChangeState newname

	array set ::gename::config {
	    prefix {}
	    program {/usr/bin/fortune -s}
		onStateChange 0
		refreshRate 120
		usePSM 1
	}
	set configlist [list \
			    [list str "Prefix"  prefix] \
			    [list str "Program" program] \
				[list bool "Change on state change" onStateChange] \
				[list str "Refresh rate (seconds, 0 means only once)" refreshRate] \
				[list bool "use PSM (otherwise name is changed)" usePSM] \
			   ]

	after 5000 [list ::gename::newname "" "" 0]
    }
    
    proc newname {event epvar {stateChange 1}} {
	variable config
	variable timer
	set name [::gename::gename]
	if {$stateChange == 1 && $config(onStateChange) == 0} {
		return
	}
	if {$config(usePSM)} {
		::MSN::changePSM $name
	} else {
		::MSN::changeName [::gename::get_login] $name
	}
	plugins_log gename "New name is set to $name"
	if {$config(refreshRate) > 0} {
		set timer \
		[after [expr {1000*$config(refreshRate)}] [list ::gename::newname {} {} 0]]
	}
    }

	proc DeInitPlugin { } {
		variable timer
		# Cancel active timer
		catch { after cancel $timer }
	}

    proc gename { } {
	variable config
	variable try
	incr try
	if {[catch "exec $config(program)" ret] } {
	    plugins_log gename "Error executing $config(program) because $ret\n"
	    return
	}
	set name "$config(prefix) "
	append name $ret
	
	plugins_log gename "$config(program) returned $ret\n"

	if {[string length "$name"] > 129 } {
	    plugins_log gename "Damn! The new name is too long, regenerating...\n"
	    if {$try > 5} {
		plugins_log gename "Too many gename tries failed. Please check your configuration."
	    } else {
		set name [::gename::gename]
	    }
	}

	set try 0
	return $name
    }

    proc get_login {} {
	global config
	return $config(login)
    }
}
