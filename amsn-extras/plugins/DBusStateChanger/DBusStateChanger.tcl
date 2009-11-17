namespace eval ::DBusStateChanger {
	variable bus_fptr
	
	#
	#	Init proc
	#	Where it all begins
	#
	proc Init { pluginDir } {
		variable bus_fptr
		# register plugin
		::plugins::RegisterPlugin "DBusStateChanger"

		# set configurations
		::DBusStateChanger::config_array
		::DBusStateChanger::configlist_values
		
		# open dbus chanel
		set bus_fptr [open "|dbus-monitor --session \"type='signal',\
		interface='$::DBusStateChanger::config(dbus_interface)',\
		member='$::DBusStateChanger::config(dbus_member)'\"" r]
		fconfigure $bus_fptr -blocking false -buffering line
		fileevent $bus_fptr readable [list ::DBusStateChanger::fire $bus_fptr]
	}
	
	#
	#	fire 
	#	Fires when a D-Bus signal is recieved
	#
	proc fire {bus_fptr} {
		if { [::MSN::myStatusIs] == {HDN} } { 
			log "Offline mode -> do nothing"
			gets $bus_fptr
			return 0 
		}
		if {![eof $bus_fptr]} {
			set signal [gets $bus_fptr]
			log $signal
			#log [::MSN::myStatusIs]
			
			#rearrange expressions to compare
			set regAway [concat $::DBusStateChanger::config(dbus_away_signal)$]
			set regBack [concat $::DBusStateChanger::config(dbus_back_signal)$]

			#check if any expression matches and change states if so...
			if { [regexp $regAway $signal] } {
				log {Changing state to AWY}				
				
				#save current state before changing
				set ::DBusStateChanger::config(prevState) [::MSN::myStatusIs]
				
				#change state to away
				::MSN::changeStatus AWY	
			} else { 
				if { [regexp $regBack $signal] } {
					log "Changing state to previous one: $::DBusStateChanger::config(prevState)"
					#change state to previous one
					::MSN::changeStatus $::DBusStateChanger::config(prevState)			
				}			
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
	#	DeInit
	#	Plug-in was disabled
	#
	proc DeInit { } {
		variable bus_fptr
		fileevent $bus_fptr readable {}
		close $bus_fptr
		log "I'm dead!"
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
			prevState		{NLN}
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
			[list str "Away signal:		" dbus_away_signal ] \
			[list str "Back signal:		" dbus_back_signal ] \
    			]
	}

#	Init " "
}
