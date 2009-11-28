namespace eval ::DBusStateChanger {
	variable bus_fptr
	variable isLoaded
	variable pluginName
	variable prevStatus
	#
	#	Init proc
	#	Where it all begins
	#
	proc Init { pluginDir } {
		variable bus_fptr
		variable isLoaded
		variable pluginName		
		variable prevStatus
	
		set isLoaded 0
		set pluginName "DBusStateChanger"
		set prevStatus "NLN"
		
		# register plugin
		::plugins::RegisterPlugin $pluginName

		# set configurations
		::DBusStateChanger::config_array
		::DBusStateChanger::configlist_values
		
		#register events
		::plugins::RegisterEvent $pluginName Load pluginLoad
		::plugins::RegisterEvent $pluginName PluginConfigured userConfiguredPlugin
	}
	
	#
	#	DeInit
	#	Plug-in was disabled
	#
	proc DeInit { } {
		variable isLoaded
		if {$isLoaded == 1} {
			::DBusStateChanger::stopDBusMonitor
		}
		log "I'm (successfully) dead!"
	}
	
	#
	#	pluginLoad
	#	runs when the plugin is loaded
	#
	proc pluginLoad { event epvar } {
		variable isLoaded
		variable pluginName
	
		upvar 2 $epvar args
		set loadPlugName $args(name)
		
		log "Plugin $loadPlugName loading"		
		if {$isLoaded == 0} {
			if { [string compare $loadPlugName $pluginName] == 0} {
				if { [::DBusStateChanger::startDBusMonitor] == 1 } {
					set isLoaded 1
					log "Plugin loaded fine"
				}
			}
		}
	}
	
	#
	#	userConfiguredPlugin
	#	runs when the plugin is configured
	#
	proc userConfiguredPlugin { event epvar } {
		variable pluginName
	
		upvar 2 $epvar args
		set cfgPlugName $args(name)
		
		if { [string compare $cfgPlugName $pluginName] == 0} {
			log "Config changed -> Restarting dbus-monitor"
			::DBusStateChanger::stopDBusMonitor
			::DBusStateChanger::startDBusMonitor
		}
		
	}
	
	#
	#	startDBusMonitor
	#	starts DBus Monitor
	#
	proc startDBusMonitor { } {
		variable bus_fptr
		variable pluginName
		# open dbus channel
		log "Trying to open dbus channel. \
		Interface='$::DBusStateChanger::config(dbus_interface)' \
		Member='$::DBusStateChanger::config(dbus_member)'"
		
		if { [catch {open "|dbus-monitor --session \"type='signal',\
		interface='$::DBusStateChanger::config(dbus_interface)',\
		member='$::DBusStateChanger::config(dbus_member)'\"" r} bus_fptr] } {
			log "Failed to start dbus-monitor"
			tk_messageBox -parent .main -title "Warning" -icon warning -type ok -message "Failed to start dbus-monitor."
			log "Unloading plugin"
			::plugins::UnLoadPlugin $pluginName
			return 0
		} else {
		 	fconfigure $bus_fptr -blocking false -buffering line
			fileevent $bus_fptr readable [list ::DBusStateChanger::fire $bus_fptr]
			log "Dbus-monitor OK"
		}
		return 1
	}
	
	#
	#	stopDBusMonitor
	#	stops DBus Monitor closing the channel
	#
	proc stopDBusMonitor { } {
		variable bus_fptr
		log "Closing dbus"
		fileevent $bus_fptr readable {}
		close $bus_fptr
		log "DBus channel closed"
	}
	
	#
	#	fire 
	#	Fires when a D-Bus signal is recieved
	#
	proc fire {bus_fptr} {
		variable prevStatus
		variable pluginName

		if { [eof $bus_fptr] } {
			tk_messageBox -parent .main -title "Warning" -icon warning -type ok -message "DBus EOF: something wrong with dbus."
			::plugins::UnLoadPlugin $pluginName
			return -1
		}
		if { [::MSN::myStatusIs] == {HDN} } { 
			log "Hidden state -> do nothing"
			gets $bus_fptr
			return 0 
		}
		if { [::MSN::myStatusIs] == {FLN} } { 
			log "Offline -> do nothing"
			gets $bus_fptr
			return 0 
		}

		set signal [gets $bus_fptr]
		log $signal
		#log [::MSN::myStatusIs]
		
		#rearrange expressions to compare
		set regAway "$::DBusStateChanger::config(dbus_away_signal)\$"
		set regBack "$::DBusStateChanger::config(dbus_back_signal)\$"

		#check if any expression matches and change states if so...
		if { [regexp $regAway $signal] } {
			log "Changing state to AWY"
			
			#save current state before changing
			set prevStatus [::MSN::myStatusIs]
			
			#change state to away
			::MSN::changeStatus AWY	
		} else { 
			if { [regexp $regBack $signal] } {
				log "Changing state to previous one: $prevStatus"
				#change state to previous one
				::MSN::changeStatus $prevStatus			
			}			
		}		
	}
	
	#
	#	log
	#	Logs message to aMSN plugins log system
	#	
	proc log {message} {
   		plugins_log DBusStateChanger $message
	}
	
	#
	#	config_array
	#	Setup configurations array with defaults
	#
	proc config_array {} {
		array set ::DBusStateChanger::config {
			dbus_interface		{org.gnome.ScreenSaver}
			dbus_member		{ActiveChanged}
			dbus_away_signal	{boolean true}
			dbus_back_signal	{boolean false}
		}
	}
	
	#
	#	configlist_values
	#	Create items list for configuration window
	#
	proc configlist_values {} {
		set ::DBusStateChanger::configlist [list \
			[list str "D-Bus interface:	" dbus_interface ] \
			[list str "D-Bus member:	" dbus_member ] \
			[list str "Away value:		" dbus_away_signal ] \
			[list str "Back value:		" dbus_back_signal ] \
    			]
	}


}
