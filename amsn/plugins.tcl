#Plugins system, preliminary verion

#List of available event types, and their parameters:
#
# chat_msg_received { userlogin userName msgText }
#
# chat_msg_sent

namespace eval ::plugins {
    
    namespace export PostEvent
    
    if { $initialize_amsn == 1 } {
	# list of registered plugins
	variable pluginslist [list]     
	# list of registred files
	variable registeredfiles [list] 
	# The id of the currently selected plugin (also it's it in teh listbox)
	set selection(id) ""            
	# Name of the current selected plugin
	set selection(name) ""          
	# The file that will be sourced of teh currently selected plugin
	set selection(file) ""          
	# Currently selected plugin's description, default to 'No Plugin Selected'
	set selection(desc) "No Plugin Selected" 
	# The path to the plugin selector window
	variable w                      
	# List of currently loaded plugins
	variable loadedplugins [list]   
    }

    proc PostEvent { event args } {
	variable pluginslist 
	variable pluginsevents 
	
	status_log "Plugin System: Calling event $event with $args\n"
	foreach plugin $pluginslist {
	    status_log "Next plugin: $plugin\n"
	    set plugin [lindex $plugin 0]
	    if { [info exists pluginsevents(${plugin}_${event}) ] } {
		catch { eval ::${plugin}::$pluginsevents(${plugin}_${event}) $args } res
		status_log "Return $res from event $event of plugin $plugin\n"
	    }
	}
	
    }
    
    proc RegisterPlugin { plugin  description } {
	variable pluginslist
	
	status_log "Plugin System: RegisterPlugin called with $plugin and $description"
	status_log "Plugin System: This is the pluginslist: $pluginslist"
	if { [lsearch $pluginslist "$plugin"] != -1} {
	    status_log "Trying to register a plugin twice..\n"
	    return 0
	}
	
	lappend plugin "$description"
	lappend pluginslist [lindex $plugin 0]
	
	
	status_log "New plugin :\nName : [lindex $plugin 0]\nDescription : $description\n"
	return 1
    }

    proc UnRegisterPlugin { plugin } {
	variable pluginslist
	variable pluginsevents
	
	status_log "Plugin System: UnRegisterPlugin called"
	if { [lsearch $pluginslist "$plugin"] == -1 } {
	    status_log "Trying to unregister an unregistered plugin..\n"
	    return 0
	}
	
	set pluginslist [lreplace $pluginslist [lsearch $pluginslist "$plugin"] [lsearch $pluginslist "$plugin"]]
	
	foreach event [array names pluginsevents] {
	    if { [string match "${plugin}_"  $event] } {
		status_log "Plugin System: unregistering $event"
		array unset pluginsevents $event
	    }
	}
	
    }
    
    
    proc RegisterEvent { plugin event cmd } {
	variable pluginslist
	variable pluginsevents
	status_log "Plugin System: RegisterEvent called with $plugin $event $cmd"
	set x [lsearch $pluginslist $plugin]
	status_log "Plugin System: The result of lsearch was $x"
	    if { $x != -1 } {
		status_log "Binding $event to $cmd\n"
		set pluginsevents(${plugin}_${event}) $cmd
	    } else {
		status_log "Registering an event for an unknown plugin...\n"
	    }
	status_log "Plugin System: Event registered"
    }
    
    proc findplugins { } {
	global HOME
	
	status_log "Plugin System: findplugins called"
	set search_path [list] 
	lappend search_path [file join [set ::program_dir plugins]]
	lappend search_path [file join $HOME plugins]
	
	set ret [list]
	foreach dir $search_path {
	    
	    foreach file [glob -nocomplain -directory $dir */plugin.tcl] {
		status_log "Found plugin files in $file\n"
		set plugin $file
		set dirname [string map [list "$dir/" ""] [file dirname $file] ]
		set desc ""
		if { [file readable [file join [file dirname $file] desc.txt] ] } {
		    set fd [open [file join [file dirname $file] desc.txt]]
		    set desc [string trim [read $fd]]
		    status_log "plugin $dirname has description : $desc\n"
		    close $fd
		}
		lappend plugin $dirname
		lappend plugin $desc
		lappend ret $plugin
		
	    }
	}
	
	return $ret
    }
    
    proc PluginGui { } {
	global bgcolor bgcolor2
	variable plugins
        variable w
	variable loadedplugins
        set w .plugin_selector
        toplevel $w
        #create widgets
        frame $w.select
        label $w.select.plugin_title -text "Plugins"
        listbox $w.select.plugin_list -background "white" -height 15
        frame $w.desc
        label $w.desc.name_title -text "Name"
        label $w.desc.name -text "No Plugin Selected"
        label $w.desc.desc_title -text "Description"
        label $w.desc.desc -textvariable ::plugins::selection(desc) -width 40 -wraplength 250
        frame $w.command
        button $w.command.load -text "Load" -command "::plugins::GUI_Load" -state disabled
        button $w.command.config -text "Configure" -command "::plugins::GUI_Config" -state disabled
        button $w.command.close -text "Close" -command "::plugins::GUI_Close"
 
        #add the plugins
        set idx 0
        foreach plugin [findplugins] {
            set file [lindex $plugin 0]
            set name [lindex $plugin 1]
            set desc [lindex $plugin 2]
	    
            set plugins(${idx}_file) $file
            set plugins(${idx}_name) $name
            set plugins(${idx}_desc) $desc
	    
            status_log "Adding plugin to selector: $name"
            $w.select.plugin_list insert $idx $name
            if {[lsearch "$loadedplugins" $name] != -1} {
                $w.select.plugin_list itemconfigure $idx -background "$bgcolor2"
            } else {
                $w.select.plugin_list itemconfigure $idx -background "$bgcolor"
            }
            incr idx
	}
	
        #do the bindings
        bind $w.select.plugin_list <<ListboxSelect>> "::plugins::GUI_NewSel"
	
        #display the widgets
        grid $w.select.plugin_title -row 1 -column 1
        grid $w.select.plugin_list -row 2 -column 1
        grid $w.desc.name_title -row 1 -column 1
        grid $w.desc.name -row 2 -column 1
        grid $w.desc.desc_title -row 3 -column 1
        grid $w.desc.desc -row 4 -column 1
        grid $w.select -column 1 -row 1 -sticky ne
        grid $w.desc -column 2 -row 1 -sticky n
        grid $w.command -column 1 -row 2 -columnspan 2
        grid $w.command.load -column 1 -row 1
        grid $w.command.config -column 2 -row 1
        grid $w.command.close -column 3 -row 1
        return
    }

    proc GUI_NewSel {} {
        variable w
        variable selection
        variable plugins
        variable loadedplugins
                                                                                                                             
        set selection(id) [$w.select.plugin_list curselection]
	if { $selection(id) == "" } {
	    return
	}
        set selection(name) $plugins(${selection(id)}_name)
        $w.desc.name configure -text $selection(name)
        set selection(file) $plugins(${selection(id)}_file)
        set selection(desc) $plugins(${selection(id)}_desc)
        status_log "Plugin System: these plugins are loaded: $loadedplugins"
        if {[lsearch "$loadedplugins" $selection(name)] != -1 } {
	    $w.command.load configure -state active -text "Unload" -command "::plugins::GUI_Unload"
            if {[info procs "::${selection(name)}::ConfigPlugin"] != ""} {
                $w.command.config configure -state active
            }
        } else {
	    $w.command.load configure -state active -text "Load" -command "::plugins::GUI_Load"
            $w.command.config configure -state disabled
        }
    }
    
    proc GUI_Load {} {
	global bgcolor2
        variable selection
        variable w
        status_log "Plugin System: Load Button clicked!"
        if { $selection(file) != "" } {
            LoadPlugin $selection(name) $selection(file)
            $w.select.plugin_list itemconfigure $selection(id) -background "$bgcolor2"
            GUI_NewSel
        }
    }

     proc GUI_Unload {} {
	 global bgcolor
	 variable selection
	 variable w
	 status_log "Plugin System: Unload Button clicked!"
	 $w.select.plugin_list itemconfigure $selection(id) -background "$bgcolor"
	 UnLoadPlugin $selection(name)
	 GUI_NewSel
     }
    proc GUI_Config {} {
        variable selection
        variable w
        status_log "Plugin System: GUI_Config called"
        set name $selection(name)
        if {$name != ""} {
            status_log "Calling ConfigPlugin in the $name namespace"
            if {[catch {eval "::${name}::ConfigPlugin"}]} {
                status_log "Plugin System: No Configuration procedure for $name or errors were returned"
                set x [toplevel $w.error]
                label $x.title -text "!!!Warning!!!"
                label $x.label -text "No Configuration procedure for $name or errors were returned!"
                button $x.ok -text "OK" -command "destroy $x"
                grid $x.title -column 1 -row 1
                grid $x.label -column 1 -row 2
                grid $x.ok -column 1 -row 3
                                                                                                                             
            }
        }
    }
    proc GUI_Close {} {
        variable w
        destroy ".plugin_selector"
    }

    proc UnLoadPlugin {plugin} {
	variable loadedplugins
        status_log "Unloading plugin $plugin"
	set loadedplugins [lreplace $loadedplugins [lsearch $loadedplugins "$plugin"] [lsearch $loadedplugins "$plugin"]]
	UnRegisterPlugin $plugin
	if {[info procs "::${plugin}::DeInitPlugin"] == "::${plugin}::DeInitPlugin"} {
	    ::${plugin}::DeInitPlugin
	}
    }
    
    proc LoadPlugins {} {
	global config
	variable pluginslist
	foreach plugin [findplugins] {
	    if {[lsearch $config(activeplugins) $plugin] != -1} {
		set file [lindex $plugin 0]
		set name [lindex $plugin 1]
		LoadPlugin $name $file
	    }
	}
    }
    proc LoadPlugin {plugin file} {
	variable pluginslist
	variable loadedplugins
	status_log "Plugin System: LoadPlugin called with $plugin $file"
	status_log "Plugin System: Trying to source $file for $plugin"
	catch { source $file }
	lappend loadedplugins $plugin
	lappend pluginslist $file
	if {[info procs "InitPlugin"] == "InitPlugin"} {
	    status_log "Plugin System: Initializing plugin with InitPlugin [file dirname $file]"
	    InitPlugin [file dirname $file]
	}
    }
}
