#####################################################
##                                                 ##
##   aMSN Plugins System - 0.94-Release Version    ##
##                                                 ##
#####################################################

namespace eval ::plugins {
	# Variable to list all plugins and their properties.
	# Do NOT access this variable directly, use ::plugins::findplugins
	variable found [list]
	namespace export PostEvent
    
	if { $initialize_amsn == 1 } {
		# The id of the currently selected plugin (also it's it in teh listbox)
		set selection(id) ""            
		# Name of the current selected plugin
		set selection(name) "" 
		# The version of aMSN required by the plugin to run
		set selection(required_version) ""         
		# The file that will be sourced of the currently selected plugin
		set selection(file) ""          
		# The namespace used by the currently selected plugin
		set selection(namespace) ""
		# The procedure used by the currently selected plugin for its initialization
		set selection(init_proc) ""
		# Currently selected plugin's description, default to 'No Plugin Selected'
		set selection(desc) "" 
		# Author of the currently selected plugin
		set selection(author) ""
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


	###############################################################
	# PostEvent (event, argarray)
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
	proc PostEvent { event var } {
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


	###############################################################
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
		lappend knownplugins [lindex $plugin 0]

		status_log "Plugins System: New plugin :\nName : [lindex $plugin 0]\n                            "
		return 1; # First timer :D
	}
    

	###############################################################
	# RegisterEvent (plugin, event, cmd)
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
		set pluginidx [lindex [lsearch -all $::plugins::found "*$plugin *"] 0]
		if { $pluginidx == "" } {
			return
		}
		set namespace [lindex $::plugins::found $pluginidx 6]

		if {[array names pluginsevents -exact $event] == "$event"} { # Will error if I search with empty key
			if {[lsearch $pluginsevents(${event}) "\:\:$namespace\:\:$cmd"] != -1 } { # Event already registered?
				status_log "Plugins System: Trying to register a event twice"
				return; # Bye Bye
			}
		}

		status_log "Plugins System: Binding $event to $cmd\n"
		lappend pluginsevents(${event}) "\:\:$namespace\:\:$cmd"; # Add the command to the list
	}


	###############################################################
	# UnRegisterEvent (plugin, event, cmd)
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
	proc UnRegisterEvent { plugin event cmd } {
		# get the event list
		variable pluginsevents

		set pluginidx [lindex [lsearch -all $::plugins::found "*$plugin *"] 0]
		if { $pluginidx == "" } {
			return
		}
		set namespace [lindex $::plugins::found $pluginidx 6]

		# do stuff only if there is a such a command for the event
		#TODO: do we need to check if such a event exists?
		if {[lsearch $pluginsevents(${event}) "\:\:$namespace\:\:$cmd"] != -1} {
			# the long erase way to remove a item from the list
			set pluginsevents(${event}) [lreplace $pluginsevents(${event}) \
				[lsearch $pluginsevents(${event}) "\:\:$namespace\:\:$cmd"] \
				[expr [lsearch $pluginsevents(${event}) "\:\:$namespace\:\:$cmd"] +1] ""]
			status_log "Plugins System: Event \:\:$namespace\:\:$cmd on $event unregistered ...\n"
		} else {
			status_log "Plugins System: Trying to unregister a unknown event...\n"
		}
	}
    
	###############################################################
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
	proc UnRegisterEvents { plugin } {
		# event list
		variable pluginsevents
		set pluginidx [lindex [lsearch -all $::plugins::found "*$plugin *"] 0]
		if { $pluginidx == "" } {
			return
		}
		set namespace [lindex $::plugins::found $pluginidx 6]

		# go through each event
		foreach {event} [array names pluginsevents] {
			# While there is a command in the list that belongs to the 
			# plugins namespace, give it's index to x and delete it
			while { [set x [lsearch -regexp $pluginsevents(${event}) "\:\:$namespace\:\:*" ]] != -1 } {
				status_log "Plugins System: UnRegistering command $x from $pluginsevents(${event})...\n"
				# the long remove item procedure
				# TODO: move this into a proc?
				set pluginsevents(${event}) [lreplace $pluginsevents(${event}) $x [expr $x +1] ""]
			}
		}
	}


	###############################################################
	# findplugins ()
	#
	# searches possible plugin directories and returns a list of plugins it found.
	# Each plugin in the list is a list also, with the following indexes
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
		lappend search_path [file join [set ::program_dir] plugins]
		lappend search_path [file join $HOME plugins]
		lappend search_path [file join $HOME2 plugins]

		# decrare the list to return
		set ::plugins::found [list]
		set idx 0
		
		# loop through each directory to search
		foreach dir $search_path {
			# for each file names plugin.tcl that is in any directory, do stuff
			# -nocomplain is used to shut errors up if no plugins found
			foreach file [glob -nocomplain -directory $dir */plugininfo.xml] {
				status_log "Plugins System: Found plugin files in $file\n"
				if { [::plugins::LoadInfo $file] } {
					lset ::plugins::found $idx 5 [file join [file dirname $file] \
						[lindex $::plugins::found $idx 5]]
					incr idx
				}
			}
		}

		return $::plugins::found
	}


	###############################################################
	# LoadInfo ()
	#
	# Loads the XML information file of each plugin and parses it, registering
	# each new plugin with proc ::plugins::XMLInfo
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc LoadInfo { path } {
		if { [file readable [file join [file dirname $path] plugininfo.xml] ] } {
			set fd [file join [file dirname $path] plugininfo.xml]
			if { [catch {
				set plugin_info [sxml::init $fd]
				sxml::register_routine $plugin_info "plugin" "::plugins::XMLInfo"
				sxml::parse $plugin_info
				sxml::end $plugin_info
				status_log "PLUGINS INFO READ\n" green
			} res] } {
				msg_box "ERROR: PLUGIN HAS MALFORMED XML PLUGININFO"
				return 0
			}
		}
		return 1
	}


	###############################################################
	# XMLInfo (cstack, cdata, saved_data, cattr saved_attr, args)
	#
	# Raises the information parsed by the sxml component and appends
	# each new plugin to $::plugins::found list so findplugins can use it
	#
	# Arguments
	# supplied by the sxml component (its only executor)
	#
	# Return
	# none
	#
	proc XMLInfo { cstack cdata saved_data cattr saved_attr args } {
		upvar $saved_data sdata

		if { ! [info exists sdata(${cstack}:deinit_procedure)] } {
			set deinit "none"
		} else {
			set deinit $sdata(${cstack}:deinit_procedure)
		}

		lappend ::plugins::found [list $sdata(${cstack}:name) $sdata(${cstack}:author) $sdata(${cstack}:description) \
			$sdata(${cstack}:amsn_version) $sdata(${cstack}:plugin_version) $sdata(${cstack}:plugin_file) \
			$sdata(${cstack}:plugin_namespace) $sdata(${cstack}:init_procedure) $deinit]

		return 0
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
		set selection(required_version) ""   
		set selection(file) ""
		set selection(namespace) ""
		set selection(init_proc) ""
		set selection(author) ""
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
			label $w.desc.name_title -text [trans name] -font sboldf
			label $w.desc.name
			label $w.desc.author_title -text [trans author] -font sboldf
			label $w.desc.author
			label $w.desc.desc_title -text [trans description] -font sboldf
			label $w.desc.desc -textvariable ::plugins::selection(desc) -width 40 \
				-wraplength 250 -justify left -anchor w
			# frame that holds the 'command center' buttons
			frame $w.command
			#TODO: translate "load"
			button $w.command.load -text "[trans load]" -command "::plugins::GUI_Load" -state disabled
			button $w.command.config -text "[trans configure]" -command "::plugins::GUI_Config" ;#-state disabled
			button $w.command.close -text [trans close] -command "::plugins::GUI_Close"
 
			# add the plugins to the list
			# idx will be used as a counter
			set idx 0
			# loop through all the found plugins
			foreach plugin [findplugins] {
				# extract the info
				set name [lindex $plugin 0]
				set author [lindex $plugin 1]
				set desc [lindex $plugin 2]
				set required_amsn_version [lindex $plugin 3]
				set plugin_version [lindex $plugin 4]
				set plugin_file [lindex $plugin 5]
				set plugin_namespace [lindex $plugin 6]
				set init_proc [lindex $plugin 7]

				# add the info to our plugins array in the form counterid_infotype
				# the counterid is the same as the id of the plugin in the listbox
				set plugins(${idx}_name) $name
				set plugins(${idx}_author) $author
				set plugins(${idx}_desc) $desc
				set plugins(${idx}_required_amsn_version) $required_amsn_version
				set plugins(${idx}_plugin_version) $plugin_version
				set plugins(${idx}_plugin_file) $plugin_file
				set plugins(${idx}_plugin_namespace) $plugin_namespace
				set plugins(${idx}_init_proc) $init_proc
		
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
			grid $w.desc.author_title -row 3 -column 1 -sticky w -padx 10
			grid $w.desc.author -row 4 -column 1 -sticky w -padx 20
			grid $w.desc.desc_title -row 5 -column 1 -sticky w -padx 10
			grid $w.desc.desc -row 6 -column 1 -sticky w -padx 20
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

    
	###############################################################
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
	proc GUI_NewSel { } {
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
		set selection(required_version) $plugins(${selection(id)}_required_amsn_version)
		set selection(file) $plugins(${selection(id)}_plugin_file)
		set selection(namespace) $plugins(${selection(id)}_plugin_namespace)
		set selection(init_proc) $plugins(${selection(id)}_init_proc)
		set selection(author) $plugins(${selection(id)}_author)
		set selection(desc) $plugins(${selection(id)}_desc)

		# update the description
		$w.desc.name configure -text $selection(name)
		$w.desc.author configure -text $selection(author)
		
		# update the buttons
		if {[lsearch "$loadedplugins" $selection(name)] != -1 } {
			# if the plugin is loaded, enable the Unload button
			$w.command.load configure -state normal -text "Unload" -command "::plugins::GUI_Unload"
			# if the plugin has a configlist, then enable configuration. Otherwise disable it
			if {[info exists ::${selection(namespace)}::configlist] == 1} {
				$w.command.config configure -state normal
			} else {
				$w.command.config configure -state disabled
			}
		} else { # plugin is not loaded
			# enable the load button and disable config button
			$w.command.load configure -state normal -text "[trans load]" -command "::plugins::GUI_Load"
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
	proc GUI_Load { } {
		# selected info, it will load this plugin
		variable selection
		# window path
		variable w
		# don't do anything is there is no selection
		if { $selection(file) != "" } {
			# Do the actual loading and check if it loads properly
			set loaded [LoadPlugin $selection(name) $selection(required_version) $selection(file) \
				$selection(namespace) $selection(init_proc)]
			if { !$loaded } {
				return
			}
			# change the color in the listbox
			$w.select.plugin_list itemconfigure $selection(id) -background #DDF3FE
			#Call PostEvent Load
			#Keep in variable if we are online or not
			if {[sb get ns stat] == "o" } {
				set status online
			} else {
				set status offline
			}

			set evpar(status) status
			::plugins::PostEvent Load evpar
			# and upate other info
			GUI_NewSel
		}
		# save the configuraion?
		#TODO: check if this is really needed
		#::plugins::save_config
	}


	###############################################################
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
	proc GUI_Unload { } {
		# the selection, will unload the plugin
		variable selection
		# window path
		variable w
		# change the color
		$w.select.plugin_list itemconfigure $selection(id) -background #FFFFFF
		# Call PostEvent Unload
		# Verify if we are online or offline
		if {[sb get ns stat] == "o" } {	   
			set status online
		} else {
			set status offline
		}

		set evpar(status) status
		::plugins::PostEvent Unload evpar
		# do the actual unloading
		UnLoadPlugin $selection(name)
		# update info in selection
		GUI_NewSel
		# save config
		#TODO: check if needed
		::plugins::save_config
	}


	###############################################################
	# GUI_Config ()
	#
	# The Configure button is cliecked. Genereates the configure dialog
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc GUI_Config { } {
		# selection, will configure it
		variable selection
		# window path
		variable w
		# current config, see it's declaration for more info
		variable cur_config
		# get the name
		set name $selection(name)
		set namespace $selection(namespace)
		# continue if something is selected
		if {$name != "" && $namespace != ""} {
			status_log "Plugins System: Calling ConfigPlugin in the $name namespace\n"
			# is there a config list?
			if {[info exists ::${namespace}::configlist] == 0} {
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
				array set cur_config [array get ::${namespace}::config]
				# create the window
				set winconf [toplevel $w.winconf]
				set confwin [frame $winconf.area]
				# id used for the item name in the widget
				set i 0
				# row to be used
				set row 0
				# loop through all the items
				foreach confitem [set ::${namespace}::configlist] {
					# Increment both variables
					incr i
					incr row
					# Check the configuration item type and create it in the GUI
					switch [lindex $confitem 0] {
						label {
							# This configuration item is a label (Simply text to show)
							label $confwin.$i -text [lindex $confitem 1]
							grid $confwin.$i -column 1 -row $row -sticky w -padx 10
						}
						bool {
							# This configuration item is a checkbox (Boolean variable)
							checkbutton $confwin.$i -text [lindex $confitem 1] -variable \
								::${namespace}::config([lindex $confitem 2])
							grid $confwin.$i -column 1 -row $row -sticky w -padx 20
						}
						ext {
							# This configuration item is a button (Action related to key)
							button $confwin.$i -text [lindex $confitem 1] -command \
								::${namespace}::[lindex $confitem 2]
							grid $confwin.$i -column 1 -row $row -sticky w -padx 20 -pady 5
						}
						str {
							# This configuration item is a text input (Text string variable)
							entry $confwin.${i}e -textvariable \
								::${namespace}::config([lindex $confitem 2])
							label $confwin.${i}l -text [lindex $confitem 1]
							grid $confwin.${i}l -column 1 -row $row -sticky w -padx 20
							grid $confwin.${i}e -column 2 -row $row	-sticky w
						}
						pass {
							# This configuration item is a password input (Text string variable)
							entry $confwin.${i}e -show "*" -textvariable \
								::${namespace}::config([lindex $confitem 2])
							label $confwin.${i}l -text [lindex $confitem 1]
							grid $confwin.${i}l -column 1 -row $row -sticky w -padx 20
							grid $confwin.${i}e -column 2 -row $row	-sticky w
						}
					}
				}
			}

			# Grid the frame
			grid $confwin -column 1 -row 1
			# Create and grid the buttons
			button $winconf.save -text [trans save] -command "::plugins::GUI_SaveConfig $winconf"
			button $winconf.cancel -text [trans cancel] -command "::plugins::GUI_CancelConfig $winconf $namespace"
			grid $winconf.save -column 1 -row 2 -sticky e -pady 5 -padx 5
			grid $winconf.cancel -column 2 -row 2 -sticky e -pady 5 -padx 5
			moveinscreen $winconf 30
		}
	}


	###############################################################
	# GUI_SaveConfig (w)
	#
	# The Save button in Configuration Window is cliecked. Save the
	# plugins configuration and then destroy the Configuration Window
	#
	# Arguments
	# w - The configuration window widget path 
	#
	# Return
	# none
	#
	proc GUI_SaveConfig { w } {
		::plugins::save_config
		destroy $w;
	}


	###############################################################
	# GUI_CancelConfig (w, namespace)
	#
	# The Cancel button in Configuration Window is cliecked. Return to
	# original configuration and then destroy the Configuration Window
	#
	# Arguments
	# w - The configuration window widget path 
	# namespace - The namespace of the plugin not configured
	#
	# Return
	# none
	#
	proc GUI_CancelConfig { w namespace } {
		variable cur_config
		array set ::${namespace}::config [array get cur_config]
		destroy $w;
	}


	###############################################################
	# GUI_Close ()
	#
	# The Close button is cliecked. Simply destroy the Plugins Window
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc GUI_Close { } {
		variable w
		destroy ".plugin_selector"
	}


	###############################################################
	# UnLoadPlugins ()
	#
	# Unloads all loaded plugins (if any) and destroy their
	# configuration arrays in global namespace
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc UnLoadPlugins { } {
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


	###############################################################
	# UnLoadPlugin (plugin)
	#
	# Unloads the $plugin plugin, removes its events, executes its
	# destructor procedure (a.k.a. DeInit) and moves its config
	# array to global namespace (since its namespace will be removed)
	#
	# Arguments
	# plugin - The plugin to be removed
	#
	# Return
	# none
	#
	proc UnLoadPlugin { plugin } {
		variable loadedplugins
		status_log "Plugins System: Unloading plugin $plugin\n"
		set loadedplugins [lreplace $loadedplugins [lsearch $loadedplugins "$plugin"] [lsearch $loadedplugins "$plugin"]]
		UnRegisterEvents $plugin
		set pluginidx [lindex [lsearch -all $::plugins::found "*$plugin *"] 0]
		if { $pluginidx == "" } {
			return
		}
		set namespace [lindex $::plugins::found $pluginidx 6]
		set deinit [lindex $::plugins::found $pluginidx 8]
		if {[info procs "::${namespace}::${deinit}"] == "::${namespace}::${deinit}"} {
			::${namespace}::${deinit}
		}
		if {[array exists ::${namespace}::config] == 1} {
			array set ::${plugin}_cfg [array get ::${namespace}::config]
		}
	}


	###############################################################
	# LoadPlugins ()
	#
	# Loads all plugins that were previously loaded (stored in
	# configuration file plugins.xml) reading $loadedplugins
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc LoadPlugins {} {
		variable loadedplugins
		::plugins::UnLoadPlugins
		load_config
		foreach {plugin} [findplugins] {
			set name [lindex $plugin 0]
			set required_version [lindex $plugin 3]
			set file [lindex $plugin 5]
			set plugin_namespace [lindex $plugin 6]
			set init_proc [lindex $plugin 7]
			if {[lsearch $loadedplugins $name] != -1} {
				LoadPlugin $name $required_version $file $plugin_namespace $init_proc
			}
		}
	}


	###############################################################
	# LoadPlugin (plugin, required_version, file, namespace, init_proc)
	#
	# Loads the $plugin plugin and restore its configuration from
	# global namespace if existed.
	#
	# Arguments
	# plugin - The plugin to load (name)
	# file - The plugin's TCL main file
	# namespace - The plugin's main namespace
	# init_proc - The plugin's init procedure
	#
	# Return
	# none
	#
	proc LoadPlugin { plugin required_version file namespace init_proc } {
		variable loadedplugins

		if { ![CheckRequeriments $required_version] } {
			msg_box "[trans required_version $required_version]"
			return 0
		}

		catch { source $file }

		if {[lsearch "$loadedplugins" $plugin] == -1} {
			status_log "Plugins System: appending to loadedplugins\n"
			lappend loadedplugins $plugin
		}
		if {[info procs ::${namespace}::${init_proc}] == "::${namespace}::${init_proc}"} {
			status_log "Plugins System: Initializing plugin $plugin with ${namespace}::${init_proc}\n"
			::${namespace}::${init_proc} [file dirname $file]
			eval {proc ::${namespace}::${init_proc} {file} { return } }
		}
		if {[array exists ::${plugin}_cfg] == 1} {
			array set ::${namespace}::config [array get ::${plugin}_cfg]
		}
		return 1
	}


	###############################################################
	# CheckRequeriments (required_version)
	#
	# Checks if we satisfy requirements of the plugin (only version now)
	#
	# Arguments
	# required_version - Version of aMSN needed to run the plugin
	#
	# Return
	# 0 - We don't satisfy them
	# 1 - We satisfy them, we can load the plugin.
	#
	proc CheckRequeriments { required_version } {
		global version

		scan $required_version "%d.%d" r1 r2;
		scan $version "%d.%d" y1 y2;
		if { $r1 > $y1 } {
			return 0
		} elseif { $r2 > $y2 } {
			return 0
		}
		return 1
	}


	###############################################################
	# save_config ()
	#
	# Saves the configuration of plugins stored in $knownplugins
	# in plugins.xml. It stores namespace config or global config
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc save_config { } {
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
			set pluginidx [lindex [lsearch -all $::plugins::found "*$plugin *"] 0]
			if { $pluginidx != "" } {
				set namespace [lindex $::plugins::found $pluginidx 6]
				status_log "NAMESPACE: $namespace\n"
				puts $file_id "<plugin>\n<name>${plugin}</name>"
				if {[lsearch $loadedplugins $plugin]!=-1} {
					status_log "Plugins System: $plugin loaded...\n"
					puts $file_id "<loaded>true</loaded>"
				}
				if {[array exists ::${namespace}::config]==1} {
					status_log "Plugins System: save_config: Saving from $plugin's namespace\n" black
					array set aval [array get ::${namespace}::config];
				} else {
					status_log "Plugins System: save_config: Saving from $plugin's global place\n" black
					array set aval [array get ::${plugin}_cfg]
				}
				foreach var_attribute [array names aval] {
					set var_value $aval($var_attribute)
					set var_value [::sxml::xmlreplace $var_value]
					puts $file_id \
					"   <entry>\n      <key>$var_attribute</key>\n      <value>$var_value</value>\n   </entry>"
				}
				puts $file_id "</plugin>"
				array unset aval
			}
		}
		puts $file_id "</config>"
		close $file_id

		status_log "Plugins System: save_config: Plugins config saved\n" black
	}


	###############################################################
	# load_config ()
	#
	# Loads the configuration of plugins stored in plugin.xml
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
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
				::sxml::register_routine $file_id "config:plugin:name" "::plugins::new_plugin_config"
				::sxml::register_routine $file_id "config:plugin:loaded" "::plugins::new_plugin_loaded"
				::sxml::register_routine $file_id "config:plugin:entry" "::plugins::new_plugin_entry_config"
				::sxml::parse $file_id
				::sxml::end $file_id
				status_log "Plugins System: load_config: Config loaded\n" green
			} res] } {
				::amsn::errorMsg "[trans corruptconfig [file join ${HOME} "plugins.xml.old"]]"
				file copy [file join ${HOME} "plugins.xml"] [file join ${HOME} "plugins.xml.old"]
			}
		}
	}


	###############################################################
	# new_plugin_config (cstack, cdata, saved_data, cattr saved_attr, args)
	#
	# Raises the information parsed by the sxml component and appends
	# each new plugin from plugin.xml to $::plugins::knownplugins
	#
	# Arguments
	# supplied by the sxml component (its only executor)
	#
	# Return
	# none
	#
	proc new_plugin_config {cstack cdata saved_data cattr saved_attr args} {
		variable cur_plugin
		variable knownplugins
		set cur_plugin $cdata
		if {[lsearch $knownplugins $cur_plugin] == -1 } {
			lappend knownplugins $cur_plugin
		}
		return 0
	}


	###############################################################
	# new_plugin_loaded (cstack, cdata, saved_data, cattr saved_attr, args)
	#
	# Raises the information parsed by the sxml component and appends
	# each new plugin from plugin.xml that was loaded before to
	# $::plugins::loadedplugins
	#
	# Arguments
	# supplied by the sxml component (its only executor)
	#
	# Return
	# none
	#
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


	###############################################################
	# new_plugin_entry_config (cstack, cdata, saved_data, cattr saved_attr, args)
	#
	# Raises the information parsed by the sxml component and sets
	# an array in global namespace with the configuration of the plugin.
	#
	# Arguments
	# supplied by the sxml component (its only executor)
	#
	# Return
	# none
	#
	proc new_plugin_entry_config {cstack cdata saved_data cattr saved_attr args} {
		variable cur_plugin
		upvar $saved_data sdata
		set ::${cur_plugin}_cfg($sdata(${cstack}:key)) $sdata(${cstack}:value);
		return 0
	}
}
