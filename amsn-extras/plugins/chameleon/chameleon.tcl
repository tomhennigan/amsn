namespace eval ::chameleon {

    variable plugin_dir

    variable THEMELIST 
    variable THEMES
    variable flash_count 10

    variable wrapped 0
    variable wrapped_procs [list button frame labelframe label radiobutton checkbutton NoteBook scrollbar]
    variable wrapped_into
    variable wrapped_shortname
    
    proc ::NoteBook { args } { return [eval ::NoteBook::create $args] }

    array set wrapped_into [list frame frame \
				button button  \
				NoteBook notebook \
				labelframe labelframe \
				label label \
				radiobutton radiobutton \
				checkbutton checkbutton \
				scrollbar scrollbar]

    array set wrapped_shortname [list button button \
				     frame frame \
				     NoteBook notebook \
				     labelframe labelframe \
				     label label \
				     radiobutton radiobutton \
				     checkbutton checkbutton \
				     scrollbar scrollbar]
    


#     variable commands_list [list scale menubutton entry srollbar \
# 				\
# 				radiobutton checkbutton label \
# 				frame labelframe button]
#    
#     variable unsupported_commands_list [list separator treeview]
#    
#     variable renamed_commands_list [list {paned panedwindow} \
# 					{combobox ::combobox::combobox} \
# 					{progressbar ::dkfprogress} \
# 					{dialog tk_dialog/tk_messageBox} \
#                                       \
# 					{notebook NoteBook}]
#    
#     variable unexisting_commands_list [list canvas listbox menu message \
# 					   spinbox text tk_popup toplevel]
    


    ################################################
    # Init( dir )                                  #
    #  Registration & initialization of the plugin #
    ################################################
    proc Init { dir } {
	variable THEMELIST
	variable THEMES
	variable plugin_dir

	::plugins::RegisterPlugin "Chameleon"

	# Avoid having 100s of $dir in auto_path, in case user loads/unloads plugin many times..
	if { [lsearch $::auto_path $dir] == -1  } {
	    lappend ::auto_path $dir
	}
	
        # This forces an update of the available packages list.
        # let's hope it will fix the problem on Mac where the tile extension is not found
	# if placed in the plugin's dir.
        eval [package unknown] Tcl [package provide Tcl]


	if {[catch {package require tile 0.7}]} { 
	    msg_box "You need the tile extension to be installed to run this plugin"
	    ::plugins::GUI_Unload
	    set ::auto_path $autopath
	    return 0
	}

	foreach package [info loaded] { 
	    foreach {lib name} $package break
	    if {$name == "Tile" } {
		set tile_dir [file dirname $lib]
	    }
	} 
	if { [info exists tile_dir] } {
	    # Avoid having 100s of $dir in auto_path, in case user loads/unloads plugin many times..
	    if { [lsearch $::auto_path $tile_dir] == -1  } {
		lappend ::auto_path $tile_dir
	    }
	    if { [lsearch $::auto_path [file join $tile_dir demos]] == -1  } {
		lappend ::auto_path [file join $tile_dir demos]
	    }
	}

	# This forces an update of the available packages list.
	# It's required for package names to find the themes in demos/themes/*.tcl
	eval [package unknown] Tcl [package provide Tcl]

	array set ::chameleon::config {
		theme {default}
	}

	set THEMELIST {
	    default  	"Default"
	    classic  	"Classic"
	    alt      	"Revitalized"
	    winnative	"Windows native"
	    xpnative	"XP Native"
	    aqua	"Aqua"
	}
	    
	array unset THEMES
	array set THEMES $THEMELIST;

	# Add in any available loadable themes:
	#
	foreach name [tile::availableThemes] {
	    if {![info exists THEMES($name)]} {
		lappend THEMELIST $name [set THEMES($name) [string totitle $name]]
	    }
	}

	set ::chameleon::configlist [list [list frame ::chameleon::populateframe ""]]
	set plugin_dir $dir

	catch  {console show }

	if { [info exists ::Chameleon_cfg(theme)] } {
	    SetTheme $::Chameleon_cfg(theme)
	} else {
	    SetTheme $::chameleon::config(theme)
	}

	wrap 0

	    # need to reset the theme at idle so the option add will actually be effective!
	after idle {::chameleon::SetTheme  $::chameleon::config(theme) 1}
    }

    proc DeInit { } {
	    variable defaultBgColor 
	    variable lastSetBgColor 
	    wrap 1

	    set lastSetBgColor $defaultBgColor
	    option add *Toplevel.background $defaultBgColor
	    RecursivelySetBgColor . $defaultBgColor
    }

    proc SetTheme {theme {reset_defaultBg 0}} {
	    variable defaultBgColor 
	    variable lastSetBgColor 

	    if { ![info exists defaultBgColor] || $reset_defaultBg} {
		    toplevel .chameleon_test
		    set defaultBgColor [.chameleon_test cget -background]
		    destroy .chameleon_test
		    puts "Found $defaultBgColor and we have [option get . background Toplevel]"
	    }
	    if { ![info exists lastSetBgColor] } {
		    set lastSetBgColor $defaultBgColor
	    }

	    # TODO find a way to get the tile's frame's background more efficiently
	    tile::setTheme $theme
	    switch -- $theme {
		    "winnative" { set bgcolor \#d6d3ce }
		    "xpnative" { set bgcolor \#ece9d8}
		    "step" { set bgcolor \#a0a0a0 }
		    "clam" { set bgcolor \#dcdad5 }
		    "aqua" { set bgcolor \#ececec }
		    "alt" -
		    "classic" -
		    default  { set bgcolor \#d9d9d9 }
		    
	    }
	    if {[info exists tile::theme::${theme}::colors(-frame)] } {
		    set bgcolor [set tile::theme::${theme}::colors(-frame)]
	    }

	    option add *Toplevel.background $bgcolor
	    RecursivelySetBgColor . $bgcolor
	    
	    set lastSetBgColor $bgcolor
    }
    proc RecursivelySetBgColor { w color } {
	    variable defaultBgColor 
	    variable lastSetBgColor

	    if {[info commands $w] != "" && [winfo toplevel $w] == $w && 
		([$w cget -background] == $defaultBgColor ||
		[$w cget -background] == $lastSetBgColor)} {
		    $w configure -background $color
	    }
	    foreach child [winfo children $w] {
		    RecursivelySetBgColor $child $color
	    }
    }


    proc populateframe { win } {
	variable THEMELIST
	variable THEMES

	set themes $win.themes

	::ttk::labelframe $themes -text "Theme"
	status_log "$themes"
	foreach {theme name} $THEMELIST {
	    set b [::ttk::radiobutton $themes.s$theme -text $name \
		       -variable ::chameleon::config(theme) -value $theme \
		       -command [list chameleon::SetTheme $theme]]
	    pack $b -side top -expand false -fill x
	    if {[lsearch -exact [package names] tile::theme::$theme] == -1} {
		$themes.s$theme state disabled
	    }
	}
	
	pack $themes -expand true -fill both
	    bind $win <Destroy> {::chameleon::SetTheme $::chameleon::config(theme)}
    }
    
    proc wrap {{revert 0}} {
	variable wrapped
	variable wrapped_procs
	variable wrapped_into
	variable wrapped_shortname
	variable plugin_dir
	variable widget_type
	variable ttk_widget_type
	variable tk_widget_type	

	plugins_log "Chameleon" "In wrap $revert"
	if {$revert == 1 } {
	    if {$wrapped == 0 } {
		error "can't revert the wrapping : must wrap before"
	    }
	    
	    foreach command $wrapped_procs {
		set tk_widget_type $command
		set ttk_widget_type [set wrapped_into($command)]
		set widget_type [set wrapped_shortname($command)]


		if { [info commands ::tk::${tk_widget_type}] == "::tk::${tk_widget_type}" && 
		     [info procs ::${tk_widget_type}] == "::${tk_widget_type}" } {
		    plugins_log "Chameleon" "Unwrapping ${tk_widget_type}"
		    rename ::${tk_widget_type} ""
		    rename ::tk::${tk_widget_type} ::${tk_widget_type}
		} else {
		    plugins_log "Chameleon" "Not unwrapping ${tk_widget_type}"
		    plugins_log "Chameleon" "Because of : [info command ::tk::${tk_widget_type}] - [info procs ::${tk_widget_type}]"
		}
	    }

	    catch { destroy .chameleon_events_messages }
	    set wrapped 0
	    
	} else {
	    if {$wrapped == 1 } {
		error "can't wrap : already wrapped"
	    }

	    foreach command $wrapped_procs {
		set tk_widget_type $command
		set ttk_widget_type [set wrapped_into($command)]
		set widget_type [set wrapped_shortname($command)]

		source [file join $plugin_dir common.tcl]
		source [file join $plugin_dir ${widget_type}.tcl]


		if { [info commands ::tk::${tk_widget_type}] == "" && 
		     [info commands ::${tk_widget_type}] == "::${tk_widget_type}"  } {
		    plugins_log "Chameleon" "Wrapping ${tk_widget_type}"
		    rename ::${tk_widget_type} ::tk::${tk_widget_type}
		    proc ::${tk_widget_type} {w args} "eval ::chameleon::${widget_type}::${widget_type} \$w \$args"
		} else {
		    plugins_log "Chameleon" "Not wrapping ${tk_widget_type}"
		    plugins_log "Chameleon" "Because of : [info command ::tk::${tk_widget_type}] - [info command ::${tk_widget_type}] - [info procs ::${tk_widget_type}] - [info procs ::tk::${tk_widget_type}]"
		}
	    }

	    set wrapped 1
	}

    }

    proc widgetCreated { w w_name } {
	variable lastCreatedWidget
	variable widget2window

	set lastCreatedWidget $w
	set widget2window($w) $w_name
	
	generateEvent <<WidgetCreated>>

    }


    proc generateEvent { event } {
	variable listeners

	if { [info exists listeners($event)] } {
	    set list [set listeners($event)]

	    foreach script $list { 
		eval $script
	    }
	}
    }
    
    proc getLastCreatedWidget { } {
	variable lastCreatedWidget
	if {[info exists lastCreatedWidget]} {
	    return $lastCreatedWidget
	}
	return ""
    }
    
    proc getWidgetPath { w } {
	variable widget2window
	if { [info exists widget2window($w)]} {
	    return $widget2window($w)
	}
	return ""
    }

    proc widgetDestroyed { w } {
	variable lastDestroyedWidget
	set lastDestroyedWidget $w

	array unset widget2window $w

	catch {rename ::$w ""}

	generateEvent <<WidgetDestroyed>>
    }

    proc getLastDestroyedWidget { } {
	variable lastDestroyedWidget
	if {[info exists lastDestroyedWidget] } {
	    return $lastDestroyedWidget
	}
	return ""
    }
    
    proc addBinding { event script } {
	variable listeners

	if { [info exists listeners($event)] } {
	    set list [set listeners($event)]
	    if { [lsearch $list $script] == -1} {
		lappend listeners($event) $script
	    }
	} else {
	    set listeners($event) [list $script]
	}
   }
    


    proc ::chameleon::copyStyle { widget_type dest } {
	
	set src ""
	if {$widget_type == "scrollbar" } {
	    if { [catch {$dest cget -orient} orientation]} {
		set orientation "vertical"
	    }
	    append src [string toupper [string range $orientation 0 0]]
	    append src [string range $orientation 1 end]
	    append src "."
	}

	append src "T"
	append src [string toupper [string range ${widget_type} 0 0]]
	append src [string range ${widget_type} 1 end]

	#Copy parameters from one style to another
	eval style configure $dest [style configure $src]
	eval style layout $dest \{[style layout $src]\}
	eval style map $dest [style map $src]
    }

    proc printStackTrace { } {
	for { set i [info level] } { $i > 0 } { incr i -1} { 
	    puts "Level $i : [info level $i]"
	    puts "Called from within : "
	}
	puts ""
    }
    
}

