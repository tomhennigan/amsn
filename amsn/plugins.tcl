#Plugins system, preliminary version

namespace eval ::plugins {
    
    namespace export PostEvent
    
    if { $initialize_amsn == 1 } {
	# The id of the currently selected plugin (also it's it in teh listbox)
	set selection(id) ""            
	# Name of the current selected plugin
	set selection(name) ""          
	# The file that will be sourced of the currently selected plugin
	set selection(file) ""          
	# Currently selected plugin's description, default to 'No Plugin Selected'
	set selection(desc) "" 
	# The path to the plugin selector window
	variable w                      
	# List of currently loaded plugins
	variable loadedplugins [list]   
	# List of known plugins
	variable knownplugins [list]
	# Current plugin whole config is being loaded
	variable cur_plugin
	# Current config being edited, for backup purposes (ei: Cancel)
	variable cur_config
    }

    
    #################################################################
    # PostEvent (event argarray)
    #
    # This proc can be put anywhere within amsn to call a event.
    #
    # Arguments
    # event - the event that is being called
    # argarray - name of the array holding the arguments
    #
    # Return
    # none
    #
    proc PostEvent { event var} {
	variable pluginsevents 
	
	status_log "Plugins System: Calling event $event with variable $var\n"
	
	if { [info exists pluginsevents(${event}) ] } { # do we have any procs for the event?
	    foreach cmd $pluginsevents(${event}) { # let's call all of them
		status_log "Plugins System: Executing $cmd\n"
		catch { eval $cmd $event $var } res ; # call
		status_log "Plugins System: Return $res from event handler $cmd\n"
	    }
	}
    }
    
    #################################################################
    # RegisterPlugin (plugin)
    #
    # This proc registers a plugin into the system. It's only purpose is to let the system know of the plugin's existance.
    #
    # Arguments
    # plugin - name of the plugin
    #
    # Return
    # 0 - plugin already registered
    # 1 - first time plugin registered
    #    
    proc RegisterPlugin { plugin } {
	variable knownplugins
	
	status_log "Plugins System: RegisterPlugin called with $plugin\n"
	if { [lsearch $knownplugins "$plugin"] != -1} { # Already registered?
	    status_log "Plugin System: Trying to register a plugin twice..\n"
	    return 0 ; #Yup, no need to do it again.
	}
	
	lappend knownplugins [lindex $plugin 0] # Actual registration
	
	
	status_log "Plugins System: New plugin :\nName : [lindex $plugin 0]\n                            "
	return 1; # First timer :D
	
    }
    
    #################################################################
    # RegisterEvent (plugin event cmd)
    #
    # This proc registeres a command to a event
    #
    # Arguments
    # plugin - name of the plugin that the command belongs to
    # event - the event to register for
    # cmd - command to register
    #
    # Return
    # none
    #      
    proc RegisterEvent { plugin event cmd } {
	variable knownplugins
	variable pluginsevents
	status_log "Plugin Systems: RegisterEvent called with $plugin $event $cmd\n"
	if { [lsearch $knownplugins $plugin] == -1 } { # UnRegistered?
	    status_log "Plugins System: Registering an event for an unknown plugin...\n"
	    return; # Bye Bye
	}
	if {[array names pluginsevents -exact $event] == "$event"} { # Will error if I search with empty key
	    if {[lsearch $pluginsevents(${event}) "\:\:$plugin\:\:$cmd"] != -1 } { # Event already registered?
		status_log "Plugins System: Trying to register a event twice"
		return; # Bye Bye
	    }
	}
	status_log "Plugins System: Binding $event to $cmd\n"
	lappend pluginsevents(${event}) "\:\:$plugin\:\:$cmd"; # Add the command to the list
    }
    
    ################################################################
    # UnRegisterEvent (plugin event cmd)
    # 
    # Unregisters a event from a plugin
    #
    # Arguments
    # plugin - the plugin to unregister for
    # event - the event to unregister from
    # cmd - the command to unregister
    #
    # Return
    # none
    #
    proc UnRegisterEvent {plugin event cmd} {
	# get the event list
	variable pluginsevents
	# do stuff only if there is a such a command for the event
	#TODO: do we need to check if such a event exists?
	if {[lsearch $pluginsevents(${event}) "\:\:$plugin\:\:$cmd"] != -1} {
	    # the long erase way to remove a item from the list
	    set pluginsevents(${event}) [lreplace $pluginsevents(${event}) [lsearch $pluginsevents(${event}) "\:\:$plugin\:\:$cmd"] [expr [lsearch $pluginsevents(${event}) "\:\:$plugin\:\:$cmd"] +1] ""]
	    status_log "Plugins System: Event \:\:$plugin\:\:$cmd on $event unregistered ...\n"
	} else {
	    status_log "Plugins System: Trying to unregister a unknown event...\n"
	}
    }
    
    ######################################################################
    # UnRegisterEvents (plugin)
    #
    # Unregistres all the events for a plugin. It is used when unloading a plugin
    #
    # Arguments
    # plugin - the plugin to unregister for
    #
    # Return
    # none
    #
    proc UnRegisterEvents {plugin} {
	# event list
	variable pluginsevents
	# go through each event
	foreach {event} [array names pluginsevents] {
	    # while there is a command in the list that belongs to the plugins namespace, give it's index to x and delete it
	    while { [set x [lsearch -regexp $pluginsevents(${event}) "\:\:$plugin\:\:*" ]] != -1 } {
		status_log "Plugins System: UnRegistering command $x from $pluginsevents(${event})...\n"
		# the long remove item procedure
		#TODO: move this into a proc?
		set pluginsevents(${event}) [lreplace $pluginsevents(${event}) $x [expr $x +1] ""]
	    }
	}
     }

    #################################################
    # findplugins ()
    #
    # searches possible plugin directories and returns a list of plugins it found. Each plugin in the list is a list also, with the following indexes
    # 0 - name
    # 1 - directory
    # 2 - description
    #
    # Arguments
    # none
    #
    # Return
    # a list of plugins
    #
    proc findplugins { } {
	global HOME HOME2
	# make a list of all the possible places to search
	#TODO: Allow user to choose where to search
	set search_path [list] 
	lappend search_path [file join [set ::program_dir plugins]]
	lappend search_path [file join $HOME plugins]
	lappend search_path [file join $HOME2 plugins]
	
	# decrare the list to return
	set ret [list]
	# loop through each directory to search
	foreach dir $search_path {
	    # for each file names plugin.tcl that is in any directory, do stuff
	    # -nocomplain is used to shut errors up if no plugins found
	    foreach file [glob -nocomplain -directory $dir */plugin.tcl] {
		status_log "Plugins System: Found plugin files in $file\n"
		#set plugin $file
		#calculate the dirname
		set dirname [string map [list "$dir/" ""] [file dirname $file] ]
		set desc ""
		# if desc.txt exists, create description
		if { [file readable [file join [file dirname $file] desc.txt] ] } {
		    set fd [open [file join [file dirname $file] desc.txt]]
		    set desc [string trim [read $fd]]
		    status_log "Plugins System: plugin $dirname has description : $desc\n"
		    close $fd
		}
		#lappend plugin $dirname
		#lappend plugin $desc
		#lappend ret $plugin
		lappend ret [list $file $dirname $desc]
	    }
	}
	
	return $ret
    }

    ###############################################################
    # PluginGui ()
    #
    # The Plugin Selector, allows users to load, unload, and configure plugins
    #
    # Arguments
    # none
    #
    # Return
    # none
    #
    proc PluginGui { } {
	# array that will hold information of plugins
	variable plugins
	# the variable that holds the path to the selection window
	variable w
	# list of all the loaded plugins
	variable loadedplugins
	# array that holds info about currently selected plugin
	variable selection
	# clear the selection
	set selection(id) ""
	set selection(name) ""
	set selection(file) ""
	set selection(desc) ""
	# set the window path
	set w .plugin_selector
	# if the window already exists, focus it, otherwise create it
	if {[winfo exists $w]==1} {
	    focus $w
	} else {
	    # create window and give it it's title
	    toplevel $w
	    wm title $w [trans pluginselector]
	    # create widgets
	    # frame that holds the selection dialog
	    frame $w.select
	    # listbox with all the plugins
	    listbox $w.select.plugin_list -background "white" -height 15
	    # frame that holds the plugins info like name and description
	    frame $w.desc
	    #TODO: translate "name"
	    label $w.desc.name_title -text "Name" -font sboldf
	    label $w.desc.name
	    label $w.desc.desc_title -text [trans description] -font sboldf
	    label $w.desc.desc -textvariable ::plugins::selection(desc) -width 40 -wraplength 250 -justify left -anchor w
	    # frame that holds the 'command center' buttons
	    frame $w.command
	    #TODO: translate "load"
	    button $w.command.load -text "Load" -command "::plugins::GUI_Load" -state disabled
	    button $w.command.config -text "Configure" -command "::plugins::GUI_Config" ;#-state disabled
	    button $w.command.close -text [trans close] -command "::plugins::GUI_Close"
	    
	    # add the plugins to the list
	    # idx will be used as a counter
	    set idx 0
	    # loop through all the found plugins
	    foreach plugin [findplugins] {
		# extract the info
		set file [lindex $plugin 0]
		set name [lindex $plugin 1]
		set desc [lindex $plugin 2]
		
		# add the info to our plugins array in the form counterid_infotype
		# the counterid is the same as the id of the plugin in the listbox
		set plugins(${idx}_file) $file
		set plugins(${idx}_name) $name
		set plugins(${idx}_desc) $desc
		
		# add the plugin name to the list at counterid position
		$w.select.plugin_list insert $idx $name
		# if the plugin is loaded, color it one color. otherwise use other colors
		#TODO: Why not use skins?
		if {[lsearch "$loadedplugins" $name] != -1} {
		    $w.select.plugin_list itemconfigure $idx -background #DDF3FE
		} else {
		    $w.select.plugin_list itemconfigure $idx -background #FFFFFF
		}
		# increase the counter
		incr idx
	    }
	    
	    #do the bindings
	    bind $w.select.plugin_list <<ListboxSelect>> "::plugins::GUI_NewSel"
	    bind $w <<Escape>> "::plugins::GUI_Close"
	    
	    # display the widgets
	    grid $w.select.plugin_list -row 1 -column 1 -sticky nsew
	    grid $w.desc.name_title -row 1 -column 1 -sticky w -padx 10
	    grid $w.desc.name -row 2 -column 1 -sticky w -padx 20
	    grid $w.desc.desc_title -row 3 -column 1 -sticky w -padx 10
	    grid $w.desc.desc -row 4 -column 1 -sticky w -padx 20
	    grid $w.command.load -column 1 -row 1 -sticky e -padx 5 -pady 5
	    grid $w.command.config -column 2 -row 1 -sticky e -padx 5 -pady 5
	    grid $w.command.close -column 3 -row 1 -sticky e -padx 5 -pady 5
	    #grid the frames
	    grid $w.select -column 1 -row 1 -rowspan 2 -sticky nw
	    grid $w.desc -column 2 -row 1 -sticky n
	    grid $w.command -column 1 -row 2 -columnspan 2 -sticky se
	}
	# not really sure what this does...
	moveinscreen $w 30
	return
    }

    ##########################################################
    # GUI_NewSel ()
    #
    # This handles new selections in the listbox aka updates the selection array
    #
    # Arguments
    # none
    #
    # Return
    # none
    #
    proc GUI_NewSel {} {
	# window path
	variable w
	# selection array
	variable selection
	# plugins' info
	variable plugins
	# the loaded plugins
	variable loadedplugins

	# find the id of the currently selected plugin
	set selection(id) [$w.select.plugin_list curselection]
	# if the selection is empty, end proc
	if { $selection(id) == "" } {
	    return
	}
	# get the info from plugins array using the current selection id
	set selection(name) $plugins(${selection(id)}_name)
	set selection(file) $plugins(${selection(id)}_file)
	set selection(desc) $plugins(${selection(id)}_desc)

	# update the description
	$w.desc.name configure -text $selection(name)

	# update the buttons
	if {[lsearch "$loadedplugins" $selection(name)] != -1 } {
	    # if the plugin is loaded, enable the Unload button
	    $w.command.load configure -state normal -text "Unload" -command "::plugins::GUI_Unload"
	    # if the plugin has a configlist, then enable configuration. Otherwise disable it
	    if {[info exists ::${selection(name)}::configlist] == 1} {
		$w.command.config configure -state normal
	    } else {
		$w.command.config configure -state disabled
	    }
	} else { # plugin is not loaded
	    # enable the load button and disable config button
	    $w.command.load configure -state normal -text "Load" -command "::plugins::GUI_Load"
	    $w.command.config configure -state disabled
	 }
    }

    ###############################################################
    # GUI_Load ()
    # 
    # This proc is called when the Load button is clicked. It loads a plugin
    #
    # Arguments
    # none
    #
    # Return
    # none
    #
    proc GUI_Load {} {
	# selected info, it will load this plugin
	variable selection
	# window path
	variable w
	# don't do anything is there is no selection
	if { $selection(file) != "" } {
	    # do the actual loading
	    LoadPlugin $selection(name) $selection(file)
	    # change the color in the listbox
	    $w.select.plugin_list itemconfigure $selection(id) -background #DDF3FE
	    # and upate other info
	    GUI_NewSel
	}
	# save the configuraion?
	#TODO: check if this is really needed
	::plugins::save_config
    }
    
    #################################################################
    # GUI_Unload ()
    #
    # Unload the currently selected plugin. Called by the Unload button
    #
    # Arguments
    # none
    #
    # Return
    # none
    #
    proc GUI_Unload {} {
	# the selection, will unload the plugin
	variable selection
	# window path
	variable w
	# change the color
	$w.select.plugin_list itemconfigure $selection(id) -background #FFFFFF
	# do the actual unloading
	UnLoadPlugin $selection(name)
	# update info in selection
	GUI_NewSel
	# save config
	#TODO: check if needed
	::plugins::save_config
    }
    
    ###################################################################
    # GUI_Config ()
    #
    # The Configure button is cliecked. Genereates the configure dialog
    #
    # Aruments
    # none
    #
    # Return
    # none
    #
    proc GUI_Config {} {
	# selection, will configure it
	variable selection
	# window path
	variable w
	# current config, see it's declaration for more info
	variable cur_config
	# get the name
	set name $selection(name)
	# continue if something is selected
	if {$name != ""} {
	    status_log "Plugins System: Calling ConfigPlugin in the $name namespace\n"
	    # is there a config list?
	    if {[info exists ::${name}::configlist] == 0} {
		# no config list, do a error.
		#TODO: instead a error, just put a label "Nothing to configure" in the configure dialog
		status_log "Plugins System: No Configuration variable for $name.\n"
		set x [toplevel $w.error]
		label $x.title -text "Error in Plugin!"
		label $x.label -text "No Configuration variable for $name.\n"
		button $x.ok -text [trans ok] -command "destroy $x"
		grid $x.title -column 1 -row 1
		grid $x.label -column 1 -row 2
		grid $x.ok -column 1 -row 3
	    } else { # configlist exists
		# backup the current config
		array set cur_config [array get ::${name}::config]
		# create the window
		set winconf [toplevel $w.winconf]
		set confwin [frame $winconf.area]
		# id used for the item name in the widget
		set i 0
		# row to be used
		set row 0
		# loop through all the items
		foreach confitem [set ::${name}::configlist] {
		    # incr both
		    incr i
		    incr row
		    #status_log "confitem: $confitem\n"	red
		    # check type and create it
		    if {[lindex $confitem 0] == "label"} { # label
			label $confwin.$i -text [lindex $confitem 1]
			grid $confwin.$i -column 1 -row $row -sticky w -padx 10
		    } elseif {[lindex $confitem 0] == "bool"} { # checkbox
			checkbutton $confwin.$i -text [lindex $confitem 1] -variable ::${name}::config([lindex $confitem 2])
			grid $confwin.$i -column 1 -row $row -sticky w -padx 20
		    } elseif {[lindex $confitem 0] == "ext"} { # button
			button $confwin.$i -text [lindex $confitem 1] -command ::${name}::[lindex $confitem 2]
			grid $confwin.$i -column 1 -row $row -sticky w -padx 20 -pady 5
		    } elseif {[lindex $confitem 0] == "str"} { # label
			entry $confwin.${i}e -textvariable ::${name}::config([lindex $confitem 2])
			label $confwin.${i}l -text [lindex $confitem 1]
			grid $confwin.${i}l -column 1 -row $row -sticky w -padx 20
			grid $confwin.${i}e -column 2 -row $row	-sticky w	    }
		}
	    }
	    # grid the frame
	    grid $confwin -column 1 -row 1
	    # create and grid the buttons
	    button $winconf.save -text [trans save] -command "::plugins::GUI_SaveConfig $winconf"
	    button $winconf.cancel -text [trans cancel] -command "::plugins::GUI_CancelConfig $winconf $name"
	    grid $winconf.save -column 1 -row 2 -sticky e -pady 5 -padx 5
	    grid $winconf.cancel -column 2 -row 2 -sticky e -pady 5 -padx 5
	    moveinscreen $winconf 30
	}
    }
    proc GUI_SaveConfig {w} {
	 ::plugins::save_config
	 destroy $w;
     }
    proc GUI_CancelConfig {w plugin} {
	 variable cur_config
	 array set ::${plugin}::config [array get cur_config]
	 destroy $w;
     }
     proc GUI_Close {} {
	 variable w
	 destroy ".plugin_selector"
     }
    
    proc UnLoadPlugins {} {
	variable loadedplugins
	variable knownplugins
	foreach {plugin} "$loadedplugins" {
	    ::plugins::UnLoadPlugin $plugin
	}
	foreach {plugin} $knownplugins {
	    if {[array exists ::${plugin}_cfg] == 1 } {
		array unset ::${plugin}_cfg
	    }
	}
    }
    
    proc UnLoadPlugin {plugin} {
	variable loadedplugins
	status_log "Plugins System: Unloading plugin $plugin\n"
	set loadedplugins [lreplace $loadedplugins [lsearch $loadedplugins "$plugin"] [lsearch $loadedplugins "$plugin"]]
	UnRegisterEvents $plugin
	if {[info procs "::${plugin}::DeInitPlugin"] == "::${plugin}::DeInitPlugin"} {
	    ::${plugin}::DeInitPlugin
	}
	if {[array exists ::${plugin}::config] == 1} {
	    array set ::${plugin}_cfg [array get ::${plugin}::config]
	}
    }
    
    proc LoadPlugins {} {
	variable loadedplugins
	::plugins::UnLoadPlugins
	load_config
	foreach {plugin} [findplugins] {
	    set file [lindex $plugin 0]
	    set name [lindex $plugin 1]
	    if {[lsearch $loadedplugins $name] != -1} {
		LoadPlugin $name $file
	    }
	}
    }
    proc LoadPlugin {plugin file} {
	variable loadedplugins
	status_log "Plugins System: LoadPlugin called with $plugin $file\n"
	catch { source $file }
	 
	if {[lsearch "$loadedplugins" $plugin] == -1} {
	     status_log "Plugins System: appending to loadedplugins\n"
	    lappend loadedplugins $plugin
	}
	if {[info procs "InitPlugin"] == "InitPlugin"} {
	    status_log "Plugins System: Initializing plugin with InitPlugin [file dirname $file]\n"
	    InitPlugin [file dirname $file]
	    eval {proc InitPlugin {file} { return } }
	 }
	 if {[array exists ::${plugin}_cfg] == 1} {
	     array set ::${plugin}::config [array get ::${plugin}_cfg]
	 }
    }
    
    
    # The configuration fun starts bellow
    # TODO: Clean it of unwanted stuff.
    proc save_config {} {
	global tcl_platform HOME HOME2 version 
	variable knownplugins
	variable loadedplugins
	
	status_log "Plugins System: save_config: saving plugin config for user [::config::getKey login] in $HOME]\n" black
	
	if { [catch {
	    if {$tcl_platform(platform) == "unix"} {
		set file_id [open "[file join ${HOME} plugins.xml]" w 00600]
	    } else {
		set file_id [open "[file join ${HOME} plugins.xml]" w]
	    }
	} res]} {
	    return 0
	}
	
	status_log "Plugins System: save_config: saving plugin config_file. Opening of file returned : $res\n"
	
	puts $file_id  "<?xml version=\"1.0\"?>\n\n<config>"
	status_log "Plugins System: I will save the folowing: $knownplugins\n"
	foreach {plugin} $knownplugins {
	    puts $file_id "<plugin>\n<name>${plugin}</name>"
	    if {[lsearch $loadedplugins $plugin]!=-1} {
		status_log "Plugins System: $plugin loaded...\n"
		puts $file_id "<loaded>true</loaded>"
	    }
	    if {[array exists ::${plugin}::config]==1} {
		status_log "Plugins System: save_config: Saving from $plugin's namespace\n" black
		#TODO: Find a better way to copy arrays
		array set aval [array get ::${plugin}::config];
	    } else {
		status_log "Plugins System: save_config: Saving from $plugin's global place\n" black
		array set aval [array get ::${plugin}_cfg]
	    }
	    foreach var_attribute [array names aval] {
		set var_value $aval($var_attribute)
		set var_value [::sxml::xmlreplace $var_value]
		
		puts $file_id "   <entry>\n      <key>$var_attribute</key>\n      <value>$var_value</value>\n   </entry>"
	    }
	    puts $file_id "</plugin>"
	    array unset aval
	}
	puts $file_id "</config>"
	
	close $file_id
	
	status_log "Plugins System: save_config: Plugins config saved\n" black
    }

    proc load_config {} {
	global HOME password protocol clientid tcl_platform
	variable loadedplugins
	foreach {plugin} $loadedplugins {
	    ::plugins::UnLoadPlugin $plugin
	}
	set loadedplugins [list]

	if { [file exists [file join ${HOME} "plugins.xml"]] } {
	    status_log "Plugins System: load_config: loading file [file join ${HOME} plugins.xml]\n" blue
	    
	    if { [catch {
		set file_id [::sxml::init [file join ${HOME} "plugins.xml"]]
#		::sxml::set_attr $file_id silent 0
#		::sxml::set_attr $file_id trace 2
		::sxml::register_routine $file_id "config:plugin:name" "::plugins::new_plugin_config"
		::sxml::register_routine $file_id "config:plugin:loaded" "::plugins::new_plugin_loaded"
		::sxml::register_routine $file_id "config:plugin:entry" "::plugins::new_plugin_entry_config"
		set val [::sxml::parse $file_id]
		::sxml::end $file_id
		status_log "Plugins System: load_config: Config loaded\n" green
		
	    } res] } {
		::amsn::errorMsg "[trans corruptconfig [file join ${HOME} "plugins.xml.old"]]"
		file copy [file join ${HOME} "plugins.xml"] [file join ${HOME} "plugins.xml.old"]
	    }
	}
    }

    proc new_plugin_config {cstack cdata saved_data cattr saved_attr args} {
	variable cur_plugin
	variable knownplugins
	set cur_plugin $cdata
	if {[lsearch $knownplugins $cur_plugin] == -1 } {
	    lappend knownplugins $cur_plugin
	}
	return 0
    }
    
    proc new_plugin_loaded {cstack cdata saved_data cattr saved_attr args} {
	variable cur_plugin
	variable loadedplugins
	set yes $cdata
	status_log "Plugins System: $cur_plugin has a loaded tag with $yes in it...\n" black
	if {$yes == "true"} {
	    if {[lsearch $loadedplugins $cur_plugin] == -1 } {
		lappend loadedplugins $cur_plugin
	    }
	}
	return 0
    }
    
    proc new_plugin_entry_config {cstack cdata saved_data cattr saved_attr args} {
	variable cur_plugin
	upvar $saved_data sdata
	set ::${cur_plugin}_cfg($sdata(${cstack}:key)) $sdata(${cstack}:value);
	return 0
    }
    
}
