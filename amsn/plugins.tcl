#Plugins system, preliminary verion

#List of available event types, and their parameters:
#
# chat_msg_received { userlogin userName msgText }
#
# chat_msg_sent

namespace eval ::plugins {

	namespace export PostEvent

	if { $initialize_amsn == 1 } {
		variable pluginslist [list]
		variable registeredfiles [list]
	}
	
	proc PostEvent { event args } {
	    variable pluginslist 
	    variable pluginsevents 
	    
	    status_log "Plugin System: Calling event $event with $args"
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
	    if { [lsearch $pluginslist "$plugin *"] == -1 } {
		status_log "Trying to unregister an unregistered plugin..\n"
			return 0
	    }
	    
	    set pluginslist [lreplace $pluginslist [lsearch $pluginslist "$plugin *"] [lsearch $pluginslist "$plugin *"]]
	    
	    foreach event [array names $pluginsevents] {
		if { [string match "${plugin}_*"  $event] } {
				unset pluginsevents($event)
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
	    variable pluginslist
	    variable plugins
	    
	    status_log "Plugin System: PluginGui called"

	    set w .plugin_selector 
	    toplevel $w
	    wm geometry $w 400x300
	    
	    label $w.choose -text "[trans selectplugins] : "
	    pack $w.choose -side top
	    
	    
	    set idx 0
	    
	    foreach plugin [findplugins] {
		
		if { [lsearch  $pluginslist "$plugin *"] != -1 } { 
		    set ::plugins::plugins($idx) 1
		} else {
		    set ::plugins::plugins($idx) 0
		}
		
		status_log "Got new plugin : $plugin --- [lindex $plugin 0] ;-; [lindex $plugin 1] ;-; [lindex $plugin 2]\n"
		
		checkbutton $w.$idx -text "[lindex $plugin 1]" -onvalue 1 -offvalue 0 -variable ::plugins::plugins($idx)
		label $w.l$idx -text "[lindex $plugin 2]"
		
		set plugins(${idx}_file) [lindex $plugin 0]
			set plugins(${idx}_name) [lindex $plugin 1]
		
		pack $w.$idx $w.l$idx -side left
		incr idx
	    }
	    
	    if { $idx == 0 } {
		label $w.status -text "[trans noneavailable]"
		pack $w.status
	    }
	    
	    status_log "[array get plugins]\n"
	    button $w.ok -text "[trans ok]" -command "::plugins::pluginsguiok $w $idx"
	    button $w.cancel -text "[trans cancel]" -command "destroy $w"
	    
	    pack $w.ok $w.cancel -side right
	    
	    
	    bind $w <Destroy> "grab release $w"
	    
	    grab set $w
	    
	}
	
	proc pluginsguiok { w idxmax } {
	    variable plugins
	    variable pluginslist
	    global config
	    
	    status_log "Plugin System: pluginguiok called with $w $idxmax"
	    status_log "Got ok from plugin selector --- [array get plugins]\n"
	    
	    for { set idx 0 } { $idx < $idxmax } { incr idx } {

		set state $plugins($idx)
		set file $plugins(${idx}_file)
		set plugin $plugins(${idx}_name)
		status_log "Plugin System: $plugin has state $state"
		if { $state == 1 && [lsearch $pluginslist "$file *"] == -1 } {
		    LoadPlugin $plugin $file
		    if {[lsearch $config(activeplugins) $plugin] == -1} {
			lappend config(activeplugins) $plugin
		    }
		} elseif { $state == 0 && [lsearch $pluginslist "$file *"] != -1 } {

		}
	    }
	    destroy $w
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
	    status_log "Plugin System: LoadPlugin called with $plugin $file"
	    status_log "Plugin System: Trying to source $file for $plugin"
	    catch { source $file }
	    lappend pluginslist $file
	    if {[info procs "InitPlugin"] == "InitPlugin"} {
		status_log "Plugin System: Initializing plugin with InitPlugin [file dirname $file]"
		InitPlugin [file dirname $file]
	    }
	}
    }
