namespace eval ::chameleon {
    variable widget_type
    variable ttk_widget_type

    namespace eval ::chameleon::${widget_type} {}

    variable ::chameleon::${widget_type}::widget_type ${widget_type}
    variable ::chameleon::${widget_type}::ttk_widget_type ${ttk_widget_type}

    proc  ::chameleon::${widget_type}::${widget_type} { w args } {
	variable widget_type
	variable ttk_widget_type
	variable ${widget_type}_widgetOptions

	    #puts "Creating widget $widget_type : $w $args"
	    #::chameleon::printStackTrace

	if { ${widget_type} == "scrollbar" && $w == "reloadimages" } {
	    return
	}

	set w_name [eval ::ttk::${ttk_widget_type} $w [eval ${widget_type}_parseConfArgs ::chameleon::${widget_type}::${widget_type}_proc_$w $args]]

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
	
	bind ${w_name} <Destroy> "::chameleon::widgetDestroyed [string map {"%" "\\%"} ::chameleon::${widget_type}::${widget_type}_proc_${w_name}]"

	::chameleon::widgetCreated ::chameleon::${widget_type}::${widget_type}_proc_${w_name} ${w_name} 

	return ${w_name}
    }

    proc ::chameleon::${widget_type}::${widget_type}_parseCommand {w_name command args } {
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


	    if {[string match $pattern $name] &&
		[string length $command] >= $min} {
		    set w ::chameleon::${widget_type}::${widget_type}_proc_${w_name}
		    #puts "Executing $execute -- $args"
		    #::chameleon::printStackTrace

		    if { [string range $execute 0 0] != "\$" &&
			 [string range $execute 0 1] != "::" } {
			    set execute ::chameleon::${widget_type}::$execute
		    }
		    
		    #puts "Executing2 [subst $execute] $args"
		    return [uplevel 3 "eval [subst $execute] [list $args]"]
	    }
	}

	error "Unknown command \"$command\""

    }

    proc ::chameleon::${widget_type}::${widget_type}_parseConfArgs { w args } {
	variable widget_type
	variable ${widget_type}_widgetOptions

	if {![info exists ${widget_type}_widgetOptions] } {
	    init_${widget_type}Options
	}
	
	foreach {name value} $args {
	    if { ![info exists ${widget_type}_widgetOptions($name)] } {
		error "Unknown option \"$name\""
	    }
	    
	    set options([set ${widget_type}_widgetOptions($name)]) $value
	} 

#	plugins_log "Chameleon" "Got configure options : [array get options]"
	if { [info exists options(-styleOption)] } {
		set newStyle ""
		catch { set newStyle [$w cget -style]}
		if { $newStyle == "" } {
			set newStyle [::chameleon::copyStyle ${widget_type} $w]
		} 
		eval style configure $newStyle [eval ${widget_type}_parseStyleArgs $args]
		set options(-style) $newStyle
	}
	
	array unset options -toImplement
	array unset options -styleOption
	array unset options -ignore

	return [eval ${widget_type}_customParseConfArgs $w [list [array get options]] $args]
    }

    proc ::chameleon::${widget_type}::${widget_type}_parseStyleArgs { args } {
	variable widget_type
	variable ${widget_type}_styleOptions
	variable ${widget_type}_widgetOptions

	foreach {name value} $args {
	    if { ![info exists ${widget_type}_widgetOptions($name)] } {
		error "Unknown option \"$name\""
	    }

# && $value != ""
	    if { [set ${widget_type}_widgetOptions($name)] == "-styleOption" && $value != ""} {
		if { [info exists ${widget_type}_styleOptions($name)] } {
		    set options([set ${widget_type}_styleOptions($name)]) $value
		} else {
		    set options($name) $value
		}
	    }
	}

	#plugins_log "Chameleon" "Returning style options [array get options]"

	return [array get options]
    }

    proc ::chameleon::${widget_type}::init_${widget_type}Options { } {
	variable widget_type
	variable ${widget_type}_widgetOptions
	variable ${widget_type}_styleOptions
	variable ${widget_type}_widgetCommands 

	array set ${widget_type}_widgetOptions {
	    -style -ignore 
	    -class -class 
	    -padding -padding
	    -cursor -cursor
	    -takefocus -takefocus
	}

	array set ${widget_type}_widgetCommands {
		cget {2 {::chameleon::${widget_type}::${widget_type}_cget $w}}
		configure {2 {::chameleon::${widget_type}::${widget_type}_configure $w}}
		state {1 {$w state}}
		instate {3 {$w instate}}
	}

	array set ${widget_type}_styleOptions {
	    -bg -background
	    -fg -foreground
	    -bd -borderwidth
	    -borderwidth -borderwidth
	    -border -borderwidth
 	    -highlightcolor -focuscolor
 	    -highlightthickness -focusthickness
	}

	init_${widget_type}CustomOptions
	
    }

    proc ::chameleon::${widget_type}::${widget_type}_getOriginal { } {
	variable widget_type
	variable dummy_${widget_type}

	if {![info exists dummy_${widget_type}] || ![winfo exists [set dummy_${widget_type}]] } {
		if {${widget_type} != "NoteBook" } {
			set dummy_${widget_type} [::tk::${widget_type} .chameleon_plugin_dummy_${widget_type}]
		} else {
			set dummy_${widget_type} [::NoteBook::create .chameleon_plugin_dummy_${widget_type}]	
		}
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
	    error "Unknown option \"$option\""
	}

	switch -- [set ${widget_type}_widgetOptions($option)] {
	    "-toImplement" {
		set value [eval ${widget_type}_customCget $w $option]
	    }
	    "-ignore" {
		set value [eval [${widget_type}_getOriginal] cget $option]
	    } 
	    "-styleOption" {
		    set style [$w cget -style] 
		    if {$style == "" } {
			    set style [::chameleon::widgetToStyle $widget_type]
		    }
		    
		    set conf [eval style configure $style]
		    set ind [lsearch $conf [list $option *]]
		    if {$ind != -1 } {
			    set value [lindex [lindex $conf $ind] end]
		    } else {
			    set value [eval [${widget_type}_getOriginal] cget $option]
		    }
	    } 
	    default {
		set value [eval $w cget $option]
	    }
	}

	return $value
    }

    proc ::chameleon::${widget_type}::${widget_type}_configure { w args } {
	variable widget_type
	variable ${widget_type}_widgetLayout

	if {[llength $args] == 0 } {
	    set conf [[${widget_type}_getOriginal] configure]
	    lappend conf [$w configure]
	    return $conf
	} elseif {[llength $args] == 1 } {
		set conf [[${widget_type}_getOriginal] configure $args]
		foreach {opt dbname dbclass def cur} $conf break
		set value [eval ${widget_type}_cget $w $args]
		return [list $opt $dbname $dbclass $def $value]
	} else {
	    set options [eval ${widget_type}_parseConfArgs $w $args]
	    return [eval $w configure $options]
	}
    }

    proc ::chameleon::${widget_type}::${widget_type}_launchCommand { w_name command args } {
	variable widget_type

	    #puts "Accessing widget $widget_type : $w_name $command $args"
	    #::chameleon::printStackTrace

	if {![winfo exists ${w_name}] } {
	    if { [info procs ::${w_name}] == "::${w_name}" } {
		rename ::${w_name} ""
	    }
	    error "invalid command name \"${w_name}\""
	}
	return [eval ${widget_type}_parseCommand ${w_name} $command $args]
    }
}
