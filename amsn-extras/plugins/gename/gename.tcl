namespace eval ::gename {
    variable config
    variable configlist

    proc InitPlugin { dir } {
	variable configlist
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
	variable config
	if {[catch {exec $config(program)} ret] } {
	    pluginss_log gename "Error executing $config(program)\n"
	    return $ret
	}
	set name "$config(prefix) "
	append name $ret
	plugins_log gename "$config(program) returned $ret\n"
	::MSN::changeName [::gename::get_login] $name
    }
    proc get_login {} {
	global config
	return $config(login)
    }
}