namespace eval ::chameleon {
  variable ttk_widget_type
  variable widget_type

  namespace eval ::chameleon::$widget_type {}

  variable ::chameleon::${widget_type}::widget_type	$widget_type
  variable ::chameleon::${widget_type}::ttk_widget_type $ttk_widget_type

  proc ::chameleon::${widget_type}::$widget_type { w args } {
    variable widget_type
    variable [set widget_type]_widgetOptions
    variable ttk_widget_type

    #DebugPrint "Creating widget $widget_type : $w $args"
    #::chameleon::printStackTrace
    
    set evalargs [list ::chameleon::${widget_type}::${widget_type}_proc_$w]

    eval lappend evalargs $args

    set confargs	[if 1 "${widget_type}_parseConfArgs $evalargs"]
    set w_name		[eval [list ::ttk::$ttk_widget_type $w] $confargs]

    if { [info command ::chameleon::${widget_type}::${widget_type}_proc_$w_name] eq "::chameleon::${widget_type}::${widget_type}_proc_$w_name" } {
      rename ::chameleon::${widget_type}::${widget_type}_proc_$w_name ""
    }

    if { [info command ::$w_name] eq [list ::$w_name] } {
      rename ::$w_name ::chameleon::${widget_type}::${widget_type}_proc_$w_name
    }

    set namesp [namespace qualifiers ::$w_name]

    if {[string length $namesp] > 0 && ![namespace exists $namesp] } {
      namespace eval $namesp {}
    }

    proc ::$w_name { command args } \
      "set newargs \[list [list $w_name]\] ; lappend newargs \$command; eval lappend newargs \$args;eval ::chameleon::${widget_type}::${widget_type}_launchCommand \$newargs"

    bind $w_name <Destroy> [list ::chameleon::widgetDestroyed [string map {"%" "\\%"} ::chameleon::${widget_type}::${widget_type}_proc_$w_name]]

    ::chameleon::widgetCreated ::chameleon::${widget_type}::${widget_type}_proc_$w_name $w_name

    return $w_name
  }

  proc ::chameleon::${widget_type}::${widget_type}_parseCommand {w_name command args} {
    variable widget_type
    variable [set widget_type]_widgetCommands 

    if {![info exists [set widget_type]_widgetCommands] } {
      init_${widget_type}Options
    }

    foreach name [array names [set widget_type]_widgetCommands] {
      foreach {min execute} [set [set widget_type]_widgetCommands($name)] {break}

      set pattern	""

      for {set i 0} {$i < [string length $command] } {incr i} {
	if {$i < $min } {
	  append pattern [string index $command $i]
	} else {
	  append pattern "\[[string index $command $i]\]"
	}
      }

      append pattern "*"

      if {[string match $pattern $name] && [string length $command] >= $min} {
	set w ::chameleon::${widget_type}::${widget_type}_proc_$w_name

	#DebugPrint "Executing $execute -- $args"
	#::chameleon::printStackTrace

	if { [string range $execute 0 0] ne "\$" && [string range $execute 0 1] ne "::" } {
	  set execute ::chameleon::${widget_type}::$execute
	}
	
	#DebugPrint "Executing2 [subst $execute] $args"
	# We need to subst using espaced list so that the elements inside $execute are substituted each in a list element.
	set evalargs [subst "\[list $execute\]"]

	eval lappend evalargs $args

	return [uplevel 3 [list eval $evalargs]]
      }
    }

    error "Unknown command '$command'"
  }

  proc ::chameleon::${widget_type}::${widget_type}_parseConfArgs { w args } {
    variable widget_type
    variable [set widget_type]_widgetOptions

    if {![info exists [set widget_type]_widgetOptions] } {
      init_${widget_type}Options
    }
    
    foreach {name value} $args {
      if { ![info exists [set widget_type]_widgetOptions($name)] } {
	error "Unknown option '$name'"
      }
      
      set options([set [set widget_type]_widgetOptions($name)]) $value
    } 

    #DebugPrint "Chameleon" "Got configure options : [array get options]"
    
    array unset options -toImplement
    array unset options -ignore

    set evalargs [list $w]

    lappend evalargs [array get options]

    eval lappend evalargs $args

    array unset options
    array set options [eval ${widget_type}_customParseConfArgs $evalargs]

    if { [info exists options(-styleOption)] } {
      set newStyle ""

      catch { set newStyle [$w cget -style]}

      if { $newStyle eq "" } {
	set newStyle [::chameleon::copyStyle $widget_type $w [array get options]]
      } 

      eval [list style configure $newStyle] [eval ${widget_type}_parseStyleArgs $args]

      set options(-style) $newStyle
    }

    array unset options -styleOption

    return [array get options]
  }

  proc ::chameleon::${widget_type}::${widget_type}_parseStyleArgs { args } {
    variable widget_type
    variable [set widget_type]_styleOptions
    variable [set widget_type]_widgetOptions

    foreach {name value} $args {
      if { ![info exists [set widget_type]_widgetOptions($name)] } {
	error "Unknown option '$name'"
      }

      # && $value != ""
      if { [set [set widget_type]_widgetOptions($name)] eq "-styleOption" && $value ne ""} {
	if { [info exists [set widget_type]_styleOptions($name)] } {
	  set options([set [set widget_type]_styleOptions($name)]) $value
	} else {
	  set options($name) $value
	}
      }
    }

    #DebugPrint "Chameleon" "Returning style options [array get options]"

    return [array get options]
  }

  proc ::chameleon::${widget_type}::init_${widget_type}Options { } {
    variable widget_type
    variable [set widget_type]_styleOptions
    variable [set widget_type]_widgetCommands 
    variable [set widget_type]_widgetOptions

    array set [set widget_type]_widgetOptions {
      -class		-class 
      -cursor		-cursor
      -padding		-padding
      -style		-ignore 
      -takefocus	-takefocus
    }

    array set [set widget_type]_widgetCommands {
      cget	{2 {::chameleon::${widget_type}::${widget_type}_cget $w}}
      configure	{2 {::chameleon::${widget_type}::${widget_type}_configure $w}}
      instate	{3 {$w instate}}
      state	{1 {$w state}}
    }

    array set [set widget_type]_styleOptions {
      -bd			-borderwidth
      -bg			-background
      -border			-borderwidth
      -borderwidth		-borderwidth
      -fg			-foreground
      -highlightcolor		-focuscolor
      -highlightthickness	-focusthickness
    }

    init_${widget_type}CustomOptions
  }

  proc ::chameleon::${widget_type}::${widget_type}_getOriginal { } {
    variable widget_type
    variable dummy_$widget_type

    if {![info exists dummy_$widget_type] || ![winfo exists [set dummy_$widget_type]] } {
      if {$widget_type ne "NoteBook" } {
	set dummy_$widget_type [::tk::$widget_type .chameleon_plugin_dummy_$widget_type]
      } else {
	set dummy_$widget_type [::NoteBook::create .chameleon_plugin_dummy_$widget_type]	
      }
    }

    return [set dummy_$widget_type]
  }

  proc ::chameleon::${widget_type}::${widget_type}_cget { w option } {
    variable widget_type
    variable [set widget_type]_widgetOptions

    if {![info exists [set widget_type]_widgetOptions] } {
      init_${widget_type}Options
    }

    if { ![info exists [set widget_type]_widgetOptions($option)]} {
      error "Unknown option '$option'"
    }

    switch -- [set [set widget_type]_widgetOptions($option)] {
      "-toImplement" {
	set value [eval [list ${widget_type}_customCget $w $option]]
      }

      "-ignore" {
	set value [eval [list [${widget_type}_getOriginal] cget $option]]
      } 

      "-styleOption" {
	set style [$w cget -style]

	if {$style eq "" } {
	  set style [::chameleon::widgetToStyle $widget_type $w {}]
	}
	
	set conf [eval [list style configure $style]]
	#set ind [lsearch $conf [list $option *]]
	set ind	 [lsearch $conf $option]

	if {$ind != -1 && $ind + 1 < [llength $conf]} {
	  set value [lindex $conf [expr {$ind + 1}]]
	  #set value [lindex [lindex $conf $ind] end]
	} else {
	  set value [eval [list [${widget_type}_getOriginal] cget $option]]
	}
      }

      default {
	set value [eval [list $w cget $option]]
      }
    }

    return $value
  }

  proc ::chameleon::${widget_type}::${widget_type}_configure { w args } {
    variable widget_type
    variable [set widget_type]_widgetLayout

    set evalargs [list $w]

    eval lappend evalargs $args

    if {[llength $args] == 0 } {
      set conf [[${widget_type}_getOriginal] configure]

      lappend conf [$w configure]

      return $conf
    } elseif {[llength $args] == 1 } {
      set conf [[${widget_type}_getOriginal] configure $args]

      foreach {opt dbname dbclass def cur} $conf break

      set value [eval ${widget_type}_cget $evalargs]

      return [list $opt $dbname $dbclass $def $value]
    } else {
      set options [eval ${widget_type}_parseConfArgs $evalargs]

      return [eval [list $w configure] $options]
    }
  }

  proc ::chameleon::${widget_type}::${widget_type}_launchCommand { w_name command args } {
    variable widget_type

    #DebugPrint "Accessing widget $widget_type : $w_name $command $args"
    #::chameleon::printStackTrace

    if {![winfo exists $w_name] } {
      if { [info procs ::$w_name] eq "::$w_name" } {
	rename ::$w_name ""
      }

      error "invalid command name '$w_name'"
    }
    
    set evalargs [list $w_name]

    lappend evalargs $command

    eval lappend evalargs $args

    return [eval ${widget_type}_parseCommand $evalargs]
  }
}
