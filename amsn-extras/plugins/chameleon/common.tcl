namespace eval ::chameleon {
    variable widget_type
    variable ttk_widget_type

    namespace eval ::chameleon::${widget_type} {}

    variable ::chameleon::${widget_type}::widget_type ${widget_type}
    variable ::chameleon::${widget_type}::ttk_widget_type ${ttk_widget_type}

    proc  ::chameleon::${widget_type}::$widget_type { w args } {
	variable widget_type
	variable ttk_widget_type
	variable ${widget_type}_widgetOptions
	
	set w_name [eval ::ttk::${ttk_widget_type} $w [eval ${widget_type}_parseConfArgs $args]]
	
	if { [info command ::chameleon::${widget_type}::${widget_type}_proc_${w_name}] == "::chameleon::${widget_type}::${widget_type}_proc_${w_name}" } {
	    rename ::chameleon::${widget_type}::${widget_type}_proc_${w_name} ""
	}
	if { [info command ::${w_name}] == "::${w_name}" } {
	    rename ::$w_name ::chameleon::${widget_type}::${widget_type}_proc_${w_name}
	}

	set namesp [namespace qualifiers ::${w_name}]
	if {[string length $namesp] > 0 && 
	    ![namespace exists $namesp] } {
	    namespace eval $namesp {}
	}

	proc ::${w_name} { command args } \
	    "eval ::chameleon::${widget_type}::${widget_type}_launchCommand ${w_name} \$command \$args"
	
	bind ${w_name} <Destroy> [list catch [list rename ::${w_name} ""]]
	
	return ${w_name}
    }

    proc ::chameleon::${widget_type}::${widget_type}_parseCommand {w command args } {
	variable widget_type
	variable ${widget_type}_widgetCommands 

	if {![info exists ${widget_type}_widgetCommands] } {
	    init_${widget_type}Options
	}

	foreach name [array names ${widget_type}_widgetCommands] {
	    set min [lindex [set ${widget_type}_widgetCommands($name)] 0]
	    set execute [lindex [set ${widget_type}_widgetCommands($name)] 1]

	    set pattern ""
	    for {set i 0} {$i < [string length $command] } {incr i} {
		if {$i < $min } {
		    append pattern [string index $command $i]
		} else {
		    append pattern "\[[string index $command $i]\]"
		}
	    }
	    append pattern "*"


	    if {[string match $pattern $name]} {
		set w ${widget_type}_proc_$w
		return [eval [subst $execute]]
	    }
	}

	error "Unknown command \"$command\""

    }

    proc ::chameleon::${widget_type}::${widget_type}_parseConfArgs { args } {
	variable widget_type
	variable ${widget_type}_widgetOptions

	if {![info exists ${widget_type}_widgetOptions] } {
	    init_${widget_type}Options
	}
	
	array set args_array $args
	foreach name [array names args_array] {
	    if { ![info exists ${widget_type}_widgetOptions($name)]} {
		error "Unknown option \"$name\""
	    }
	    
	    set options([lindex [set ${widget_type}_widgetOptions($name)] 0]) $args_array($name)
	} 
	
	array unset options -ignore

	return [eval ${widget_type}_customParseConfArgs [list [array get options]] $args]
    }

    proc ::chameleon::${widget_type}::init_${widget_type}Options { } {
	variable widget_type
	variable ${widget_type}_widgetOptions
	variable ${widget_type}_widgetCommands 

	array set ${widget_type}_widgetOptions {
	    -style -style 
	    -class -class 
	    -padding -padding
	    -cursor -cursor
	    -takefocus -takefocus}

	array set ${widget_type}_widgetCommands {cget {2 {${widget_type}_cget $w $args}}
	    configure {2 {${widget_type}_configure $w $args}}
	    state {1 {
		if { [llength $args] == 0 } {
		    $w state
		} else {
		    $w state $args
		}
	    }}
	    instate {3 {$w instate $args}}
	}

	init_${widget_type}CustomOptions
	
    }

    proc ::chameleon::${widget_type}::${widget_type}_getOriginal { } {
	variable widget_type
	variable dummy_${widget_type}

	if {![info exists dummy_${widget_type}] || ![winfo exists [set dummy_${widget_type}]] } {
	    set dummy_${widget_type} [::tk::${widget_type} .chameleon_plugin_dummy_${widget_type}]
	}
	return [set dummy_${widget_type}]
    }

    proc ::chameleon::${widget_type}::${widget_type}_cget { w option } {
	variable widget_type
	variable ${widget_type}_widgetOptions

	if {![info exists ${widget_type}_widgetOptions] } {
	    init_${widget_type}Options
	}

	if { ![info exists ${widget_type}_widgetOptions($option)]} {
	    error "Unknown option \"$name\""
	}

	if {[set ${widget_type}_widgetOptions($option)] == "-ignore" } {
	    set value [eval ${widget_type}_customCget $w $option]
	    if { $value == "" } {
		set value [eval [${widget_type}_getOriginal] cget $option]
	    }
	} else {
	    set value [eval $w cget $option]
	} 

	return $value
    }

    proc ::chameleon::${widget_type}::${widget_type}_configure { w args } {
	variable widget_type

	if {[llength $args] == 0 } {
	    set tk_conf [[${widget_type}_getOriginal] configure]
	    set ttk_conf [$w configure]

	    set conf ${tk_conf}
	    lappend conf ${ttk_conf}
	    return $conf
	} elseif {[llength $args] == 1 } {
	    return [eval ${widget_type}_cget $w $args]
	} else {
	    set options [eval ${widget_type}_parseConfArgs $args]
	    return [eval $w configure $options]
	}
    }



    proc ::chameleon::${widget_type}::${widget_type}_launchCommand { w_name command args } {
	variable widget_type

	if {![winfo exists ${w_name}] } {
	    if { [info procs ::${w_name}] == "::${w_name}" } {
		rename ::${w_name} ""
	    }
	    error "invalid command name \"${w_name}\""
	}
	return [eval ${widget_type}_parseCommand ${w_name} $command $args]
    }
    
}