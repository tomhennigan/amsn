#Plugins system, preliminary version

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
	# The file that will be sourced of the currently selected plugin
	set selection(file) ""          
	# Currently selected plugin's description, default to 'No Plugin Selected'
	set selection(desc) "No Plugin Selected" 
	# The path to the plugin selector window
	variable w                      
	# List of currently loaded plugins
	variable loadedplugins [list]   
    }

    proc PostEvent { event var level} {
	variable pluginslist 
	variable pluginsevents 
	
	status_log "Plugin System: Calling event $event with variable $var in the level $level\n"
	
	if { [info exists pluginsevents(${event}) ] } {
	    foreach cmd $pluginsevents(${event}) {
		status_log "Plugin System: Executing $cmd\n"
		catch { eval $cmd $var $level } res
		status_log "Plugin System: Return $res from event handler $cmd\n"
	    }
	}
    }
    
    proc RegisterPlugin { plugin  description } {
	variable pluginslist
	
	status_log "Plugin System: RegisterPlugin called with $plugin and $description\n"
	if { [lsearch $pluginslist "$plugin"] != -1} {
	    status_log "Plugin System: Trying to register a plugin twice..\n"
	    return 0
	}
	
	lappend plugin "$description"
	lappend pluginslist [lindex $plugin 0]
	
	
	status_log "Plugin System: New plugin :\nName : [lindex $plugin 0]\nDescription : $description\n"
	return 1
    }

    proc UnRegisterPlugin { plugin } {
	variable pluginslist
	variable pluginsevents
	
	status_log "Plugin System: UnRegisterPlugin called\n"
	if { [lsearch $pluginslist "$plugin"] == -1 } {
	    status_log "Plugin System: Trying to unregister an unregistered plugin..\n"
	    return 0
	}
	
	set pluginslist [lreplace $pluginslist [lsearch $pluginslist "$plugin"] [lsearch $pluginslist "$plugin"]]
	
	foreach event [array names pluginsevents] {
	    if { [string match "${plugin}_"  $event] } {
		status_log "Plugin System: unregistering $event\n"
		array unset pluginsevents $event
	    }
	}
	
    }
    
    
    proc RegisterEvent { plugin event cmd } {
	variable pluginslist
	variable pluginsevents
	status_log "Plugin System: RegisterEvent called with $plugin $event $cmd\n"
	set x [lsearch $pluginslist $plugin]
	    if { $x != -1 } {
		status_log "Plugin System: Binding $event to $cmd\n"
		lappend pluginsevents(${event}) "\:\:$plugin\:\:$cmd"
	    } else {
		status_log "Plugin System: Registering an event for an unknown plugin...\n"
	    }
    }
    
    proc findplugins { } {
	global HOME
	
	set search_path [list] 
	lappend search_path [file join [set ::program_dir plugins]]
	lappend search_path [file join $HOME plugins]
	
	set ret [list]
	foreach dir $search_path {
	    
	    foreach file [glob -nocomplain -directory $dir */plugin.tcl] {
		status_log "Plugin System: Found plugin files in $file\n"
		set plugin $file
		set dirname [string map [list "$dir/" ""] [file dirname $file] ]
		set desc ""
		if { [file readable [file join [file dirname $file] desc.txt] ] } {
		    set fd [open [file join [file dirname $file] desc.txt]]
		    set desc [string trim [read $fd]]
		    status_log "Plugin System: plugin $dirname has description : $desc\n"
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
        label $w.desc.desc_title -text [trans description]
        label $w.desc.desc -textvariable ::plugins::selection(desc) -width 40 -wraplength 250
        frame $w.command
        button $w.command.load -text "Load" -command "::plugins::GUI_Load" -state disabled
        button $w.command.config -text "Configure" -command "::plugins::GUI_Config" ;#-state disabled
        button $w.command.close -text [trans close] -command "::plugins::GUI_Close"
 
        #add the plugins
        set idx 0
        foreach plugin [findplugins] {
            set file [lindex $plugin 0]
            set name [lindex $plugin 1]
            set desc [lindex $plugin 2]
	    
            set plugins(${idx}_file) $file
            set plugins(${idx}_name) $name
            set plugins(${idx}_desc) $desc
	    
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
        if {[lsearch "$loadedplugins" $selection(name)] != -1 } {
	    $w.command.load configure -state active -text "Unload" -command "::plugins::GUI_Unload"
            if {[info exists ::${selection(name)}::configlist] == 1} {
                $w.command.config configure -state active
            } else {
		$w.command.config configure -state disabled
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
	 $w.select.plugin_list itemconfigure $selection(id) -background "$bgcolor"
	 UnLoadPlugin $selection(name)
	 GUI_NewSel
     }
    proc GUI_Config {} {
        variable selection
        variable w
        set name $selection(name)
        if {$name != ""} {
            status_log "Plugin System: Calling ConfigPlugin in the $name namespace\n"
	    if {[info exists ::${name}::configlist] == 0} {
		status_log "Plugin System: No Configuration variable for $name.\n"
                set x [toplevel $w.error]
                label $x.title -text "Error in Plugin!"
                label $x.label -text "No Configuration variable for $name.\n"
                button $x.ok -text [trans ok] -command "destroy $x"
                grid $x.title -column 1 -row 1
                grid $x.label -column 1 -row 2
                grid $x.ok -column 1 -row 3
	    } else {
		set confwin [toplevel $w.confwin]
		set i 0
		foreach confitem [set ::${name}::configlist] {
		    incr i
		    #status_log "confitem: $confitem\n"	
		    if {[lindex $confitem 0] == "label"} {
			label $confwin.$i -text [lindex $confitem 1]
			pack $confwin.$i -side top -anchor w -padx 10
		    } elseif {[lindex $confitem 0] == "bool"} {
			checkbutton $confwin.$i -text [lindex $confitem 1] -variable ::${name}::config([lindex $confitem 2])
			pack $confwin.$i -side top -anchor w -padx 20
		    } elseif {[lindex $confitem 0] == "ext"} {
			button $confwin.$i -text [lindex $confitem 1] -command ::${name}::[lindex $confitem 2]
			pack $confwin.$i -side top -anchor w -padx 20
		    } elseif {[lindex $confitem 0] == "str"} {
			entry $confwin.${i}e -textvariable ::${name}::config([lindex $confitem 2])
			label $confwin.${i}l -text [lindex $confitem 1]
			pack $confwin.${i}l -side top -anchor w -padx 20
			pack $confwin.${i}e -side top -anchor w -padx 40
		    }
		}
	    }
        }
    }
    proc GUI_Close {} {
        variable w
        destroy ".plugin_selector"
    }

    proc UnLoadPlugin {plugin} {
	variable loadedplugins
        status_log "Plugin System: Unloading plugin $plugin\n"
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
	status_log "Plugin System: LoadPlugin called with $plugin $file\n"
	catch { source $file }
	lappend loadedplugins $plugin
	lappend pluginslist $file
	if {[info procs "InitPlugin"] == "InitPlugin"} {
	    status_log "Plugin System: Initializing plugin with InitPlugin [file dirname $file]\n"
	    InitPlugin [file dirname $file]
	}
    }


    # The configuration fun starts bellow
    # TODO: Clean it of unwanted stuff.
    proc getKey {plugin key} {
	global ${plugin}_cfg
	return [set ${plugin}_cfg($key)]
    }
    
    proc getVar {plugin key} {
	return "${plugin}_cfg($key)"
    }
    
    proc setKey {plugin key value} {
	global ${plugin}_cfg plugins_config
	if {[lsearch plugins_config $plugin] == -1} {
	    lappend plugins_config $plugin
	}
	set ${plugin}_cfg($key) $value
    }
    
    proc save_config {} {
	global tcl_platform HOME HOME2 version password emotions
	
	status_log "save_config: saving plugin config for user [::config::getKey login] in $HOME]\n" black
	
	if { [catch {
	    if {$tcl_platform(platform) == "unix"} {
		set file_id [open "[file join ${HOME} plugins.xml]" w 00600]
	    } else {
		set file_id [open "[file join ${HOME} plugins.xml]" w]
	    }
	} res]} {
	    return 0
	}
	
	status_log "save_config: saving plugin config_file. Opening of file returned : $res\n"
	set loginback $config(login)
	set passback $password
	
	# using default, make sure to reset config(login)
	if { $HOME == $HOME2 } {
	    set config(login) ""
	    set password ""
	}
	
	
	puts $file_id  "<?xml version=\"1.0\"?>\n\n<config>"
	
	foreach plugin plugins_config {
	    puts $file_id "<plugin name=\"$plugin\">"
	    foreach var_attribute [array names ${plugin}_cfg] {
		set var_value ${plugin}_cfg($var_attribute)
		set var_value [::sxml::xmlreplace $var_value]
		puts $file_id "   <entry>\n      <attribute>$var_attribute</attribute>\n      <value>$var_value</value>\n   </entry>"
	    }
	    puts $file_id "</plugin>"
	}
	puts $file_id "</config>"
	
	close $file_id
	
	set config(login) $loginback
	set password $passback
	
	status_log "save_config: Plugins config saved\n" black
    }
    
    proc load_config {} {
	global HOME password protocol clientid tcl_platform

	set user_login [::config::getKey login]
	status_log "Plugins System: load_config: Started. HOME=$HOME, config(login)=$user_login\n"
	if { [file exists [file join ${HOME} "plugins.xml"]] } {
	    status_log "Plugins System: load_config: loading file [file join ${HOME} plugins.xml]\n" blue
	    
	    if { [catch {
		set file_id [sxml::init [file join ${HOME} "plugins.xml"]]
		
		sxml::register_routine $file_id "config:entry" "new_config_entry"
		sxml::register_routine $file_id "config:emoticon" "new_custom_emoticon"
		set val [sxml::parse $file_id]
		sxml::end $file_id
		status_log "Plugins System: load_config: Config loaded\n" green
		
	    } res] } {
		::amsn::errorMsg "[trans corruptconfig [file join ${HOME} "config.xml.old"]]"
		file copy [file join ${HOME} "plugins.xml"] [file join ${HOME} "plugins.xml.old"]
	    }
	}
    }
}