#Plugins system, preliminary version

#List of available event types, and their parameters:
#
# chat_msg_received { userlogin userName msgText }
#
# chat_msg_sent

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

    proc PostEvent { event var} {
	variable pluginsevents 
	
	status_log "Plugins System: Calling event $event with variable $var\n"
	
	if { [info exists pluginsevents(${event}) ] } {
	    foreach cmd $pluginsevents(${event}) {
		status_log "Plugins System: Executing $cmd\n"
		catch { eval $cmd $var } res
		status_log "Plugins System: Return $res from event handler $cmd\n"
	    }
	}
    }
    
    proc RegisterPlugin { plugin  description } {
	variable knownplugins
	
	status_log "Plugins System: RegisterPlugin called with $plugin and $description\n"
	if { [lsearch $knownplugins "$plugin"] != -1} {
	    status_log "Plugin System: Trying to register a plugin twice..\n"
	    return 0
	}
	
	lappend plugin "$description"
	lappend knownplugins [lindex $plugin 0]
	
	
	status_log "Plugins System: New plugin :\nName : [lindex $plugin 0]\nDescription : $description\n"
	return 1
	
    }

    proc RegisterEvent { plugin event cmd } {
	variable knownplugins
	variable pluginsevents
	status_log "Plugin Systems: RegisterEvent called with $plugin $event $cmd\n"
	set x [lsearch $knownplugins $plugin]
	    if { $x != -1 } {
		status_log "Plugins System: Binding $event to $cmd\n"
		lappend pluginsevents(${event}) "\:\:$plugin\:\:$cmd"
	    } else {
		status_log "Plugins System: Registering an event for an unknown plugin...\n"
	    }
    }

    proc UnRegisterEvent {plugin event cmd} {
	variable pluginevents
	if {[lsearch $pluginevents(${event}) "\:\:$plugin\:\:$cmd"] != -1} {
	    set $pluginevents(${event}) [lreplace $pluginevents(${event}) [lsearch $pluginevents(${event}) "\:\:$plugin\:\:$cmd"] [expr [lsearch $pluginevents(${event}) "\:\:$plugin\:\:$cmd"] +1] ""]
	    status_log "Plugins System: Event \:\:$plugin\:\:$cmd on $event unregistered ...\n"
	} else {
	    status_log "Plugins System: Trying to unregister a unknown event...\n"
	}
    }
    
    proc UnRegisterEvents {plugin} {
	variable pluginsevents
	foreach {event} [array names pluginevents] {
	    while { [set x [lsearch -regexp $pluginsevents(${event}) "\:\:$plugin\:\:*" ]] !=1 } {
		status_log "Plugins System: UnRegistering command $x from $pluginevents(${event})...\n"
		set $pluginevents(${event}) [lreplace $pluginevents(${event}) $x [expr $x +1] ""]
	    }
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
		 status_log "Plugins System: Found plugin files in $file\n"
		 set plugin $file
		 set dirname [string map [list "$dir/" ""] [file dirname $file] ]
		 set desc ""
		 if { [file readable [file join [file dirname $file] desc.txt] ] } {
		     set fd [open [file join [file dirname $file] desc.txt]]
		     set desc [string trim [read $fd]]
		     status_log "Plugins System: plugin $dirname has description : $desc\n"
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
	 variable selection
	 set selection(id) ""
	 set selection(name) ""
	 set selection(file) ""
	 set selection(desc) ""
	 set w .plugin_selector
	 if {[winfo exists $w]==1} {
	     focus $w
	 } else {
	     toplevel $w
	     wm title $w [trans pluginselector]
	     #create widgets
	     frame $w.select
	     listbox $w.select.plugin_list -background "white" -height 15
	     frame $w.desc
	     label $w.desc.name_title -text "Name" -font sboldf
	     label $w.desc.name
	     label $w.desc.desc_title -text [trans description] -font sboldf
	     label $w.desc.desc -textvariable ::plugins::selection(desc) -width 40 -wraplength 250 -justify left -anchor w
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
	 variable cur_config
	 set name $selection(name)
	 if {$name != ""} {
	     status_log "Plugins System: Calling ConfigPlugin in the $name namespace\n"
	     if {[info exists ::${name}::configlist] == 0} {
		 status_log "Plugins System: No Configuration variable for $name.\n"
		 set x [toplevel $w.error]
		 label $x.title -text "Error in Plugin!"
		 label $x.label -text "No Configuration variable for $name.\n"
		 button $x.ok -text [trans ok] -command "destroy $x"
		 grid $x.title -column 1 -row 1
		 grid $x.label -column 1 -row 2
		 grid $x.ok -column 1 -row 3
	     } else {
		 array set cur_config [array get ::${name}::config]
		 set winconf [toplevel $w.winconf]
		 set confwin [frame $winconf.area]
		 set i 0
		 set row 0
		 foreach confitem [set ::${name}::configlist] {
		     incr i
		     incr row
		     #status_log "confitem: $confitem\n"	red
		     if {[lindex $confitem 0] == "label"} {
			 label $confwin.$i -text [lindex $confitem 1]
			 grid $confwin.$i -column 1 -row $row -sticky w -padx 10
		     } elseif {[lindex $confitem 0] == "bool"} {
			 checkbutton $confwin.$i -text [lindex $confitem 1] -variable ::${name}::config([lindex $confitem 2])
			 grid $confwin.$i -column 1 -row $row -sticky w -padx 20
		     } elseif {[lindex $confitem 0] == "ext"} {
			 button $confwin.$i -text [lindex $confitem 1] -command ::${name}::[lindex $confitem 2]
			 grid $confwin.$i -column 1 -row $row -sticky w -padx 20 -pady 5
		     } elseif {[lindex $confitem 0] == "str"} {
			 entry $confwin.${i}e -textvariable ::${name}::config([lindex $confitem 2])
			 label $confwin.${i}l -text [lindex $confitem 1]
			 grid $confwin.${i}l -column 1 -row $row -sticky w -padx 20
			 grid $confwin.${i}e -column 2 -row $row	-sticky w	    }
		 }
	     }
	     grid $confwin -column 1 -row 1
	     button $winconf.save -text [trans save] -command "::plugins::GUI_SaveConfig $winconf"
	     button $winconf.cancel -text [trans cancel] -command "::plugins::GUI_CancelConfig $winconf $name"
	     grid $winconf.save -column 1 -row 2 -sticky e -pady 5 -padx 5
	     grid $winconf.cancel -column 2 -row 2 -sticky e -pady 5 -padx 5
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
	 ::plugins::save_config
     }

     proc LoadPlugins {} {
	 variable loadedplugins
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
	 ::plugins::save_config
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
		# TODO: Find a better way to copy arrays
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
	    append knownplugins $cur_plugin
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