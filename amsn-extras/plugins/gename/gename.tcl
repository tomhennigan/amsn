namespace eval ::gename {
    variable config
    variable configlist
    variable try 0

    proc InitPlugin { dir } {
	variable configlist
	plugins_log gename "Welcome to Gename!\n"
	::plugins::RegisterPlugin gename
	::plugins::RegisterEvent gename ChangeState newname
	array set ::gename::config {
	    prefix {}
	    program {/usr/bin/fortune}
	}
	set configlist [list \
			    [list str "Prefix"  prefix] \
			    [list str "Program" program] \
			   ]
    }
    
    proc newname {event epvar} {
	set name [::gename::gename]
	::MSN::changeName [::gename::get_login] $name
	plugins_log gename "New name is set to $name"
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
