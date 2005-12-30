namespace eval ::chameleon {

    variable plugin_dir

    variable THEMELIST 
    variable THEMES
    variable flash_count 10

    variable wrapped 0
    variable wrapped_procs [list button frame labelframe label radiobutton checkbutton NoteBook]
    variable wrapped_into
    variable wrapped_shortname
    
    proc ::NoteBook { args } { return [eval ::NoteBook::create $args] }

    array set wrapped_into [list frame frame \
				button button  \
				NoteBook notebook \
				labelframe labelframe \
				label label \
				radiobutton radiobutton \
				checkbutton checkbutton]

    array set wrapped_shortname [list button button \
				     frame frame \
				     NoteBook notebook \
				     labelframe labelframe \
				     label label \
				     radiobutton radiobutton \
				     checkbutton checkbutton]
    


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
	

	if {[catch {package require tile}]} { 
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
	
	wrap 0

	tile::setTheme ${::chameleon::config(theme)}
    }

    proc DeInit { } {
	wrap 1
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
		       -command [list tile::setTheme $theme]]
	    pack $b -side top -expand false -fill x
	    if {[lsearch -exact [package names] tile::theme::$theme] == -1} {
		$themes.s$theme state disabled
	    }
	}
	
	pack $themes -expand true -fill both
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

	if {$revert == 1 } {
	    if {$wrapped == 0 } {
		error "can't revert the wrapping : must wrap before"
	    }
	    
	    foreach command $wrapped_procs {
		set tk_widget_type $command
		set ttk_widget_type [set wrapped_into($command)]
		set widget_type [set wrapped_shortname($command)]

		if { [info command ::tk::${tk_widget_type}] == "::tk::${tk_widget_type}"&& 
		     [info command ::${tk_widget_type}] == "" && 
		     [info procs ::${tk_widget_type}] == "::${tk_widget_type}" } {
		    rename ::${tk_widget_type} ""
		    rename ::tk::${tk_widget_type} ::${tk_widget_type}
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

		if { [info command ::tk::${tk_widget_type}] == "" && 
		     [info procs ::tk::${tk_widget_type}] == "" && 
		     ([info command ::${tk_widget_type}] == "::${tk_widget_type}"  ||
		      [info procs ::${tk_widget_type}] == "::${tk_widget_type}" ) } {
		    rename ::${tk_widget_type} ::tk::${tk_widget_type}
		    proc ::${tk_widget_type} {w args} "eval ::chameleon::${widget_type}::${widget_type} \$w \$args"
		}
	    }

	    message .chameleon_events_messages

	    set wrapped 1
	}

    }

    proc printStackTrace { } {
	for { set i [info level] } { $i > 0 } { incr i -1} { 
	    puts "Level $i : [info level $i]"
	    puts "Called from within : "
	}
	puts ""
    }

}

