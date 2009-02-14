######################################################
##                                                 ##
##   aMSN Plugins System - 0.96-Release Version    ##
##                                                 ##
#####################################################

::Version::setSubversionId {$Id$}

proc plugins_log {plugin msg} {
#return
	if {[info procs "::pluginslog::plugins_log"] == "::pluginslog::plugins_log"} {
		::pluginslog::plugins_log $plugin $msg
	} else {
		status_log "Plugins System: $plugin: $msg"
	}
}

namespace eval ::plugins {
	namespace export PostEvent

	if { $initialize_amsn == 1 } {
		# Name of the current selected plugin
		set selection "" 
		# The path to the plugin selector window
		variable w                      
		# Info about plugins
		array set plugins [list]
		# List of current plugins
		variable loadedplugins [list]
		# Holds the configuration of unloaded plugins
		array set config [list]

		# tmp variable to be used by the XML parser
		variable cur_plugin
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

		plugins_log core "Calling event $event with variable $var\n"
	
		if { [info exists pluginsevents(${event}) ] } { # do we have any procs for the event?
			foreach cmd $pluginsevents(${event}) { # let's call all of them
				plugins_log core "Executing $cmd\n"
				catch { eval $cmd $event $var } res ; # call
				plugins_log core "Return $res from event handler $cmd\n"
			}
		}
	}


	###############################################################
	# RegisterPlugin (plugin)
	#
	# Dummy proc, not needed any more. Is replaced by "loadedplugins"
	#
	# Arguments
	# plugin - name of the plugin
	#
	# Return
	# 0 - plugin already registered
	# 1 - first time plugin registered
	#    
	proc RegisterPlugin { plugin } {
	    
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
	# -1 - error registering event
	# 1 - all good!
	#      
	proc RegisterEvent { plugin event cmd } {
		variable pluginsevents

		plugins_log core "Plugin Systems: RegisterEvent called with $plugin $event $cmd\n"

	    #check if the plugin is loaded, if not don't register the event and return 0 for false
		if { [lsearch $::plugins::loadedplugins "$plugin"] == -1 } { 
			plugins_log core "Registering an event for an unloaded plugin...\n"
			return -1; # Bye Bye
		}

		#get the namespace of the plugin via it's data in loadedplugins
		set namespace [getInfo $plugin plugin_namespace]

		#Check if the given proc is already registered to the given event
		if {[array names pluginsevents $event] != ""} { 
			if {[lsearch $pluginsevents(${event}) "\:\:$namespace\:\:$cmd"] != -1 } { # Event already registered?
				plugins_log core "Trying to register a event twice"
				return -1; # Bye Bye
			}
		}

		plugins_log core "Binding $event to $cmd\n"
		lappend pluginsevents(${event}) "\:\:$namespace\:\:$cmd"; # Add the command to the list

		return 1
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
	# -1 - on error
	# 1 - on success
	#
	proc UnRegisterEvent { plugin event cmd } {
		variable pluginsevents

		if { [lsearch $::plugins::loadedplugins $plugin] == -1 } {
			return -1
		}
		
		set namespace [getInfo $plugin plugin_namespace]

		# do stuff only if there is a such a command for the event
		if { [info exists pluginsevents(${event})] == 0 } {
			plugins_log core "Trying to unregister a unknown event...\n"
			return -1
		} 
		set pos [lsearch $pluginsevents(${event}) "\:\:$namespace\:\:$cmd"]
		if {$pos != -1} {
			# the long erase way to remove a item from the list
			set pluginsevents(${event}) [lreplace $pluginsevents(${event}) $pos $pos]
			plugins_log core "Event \:\:$namespace\:\:$cmd on $event unregistered ...\n"
		} else {
			plugins_log core "Trying to unregister a unknown event...\n"
		}
		return 1
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
		if { [lsearch $::plugins::loadedplugins $plugin] == -1 } {
			return
		}
		set namespace [getInfo $plugin plugin_namespace]

		# go through each event
       		foreach {event} [array names pluginsevents] {
			# While there is a command in the list that belongs to the 
			# plugins namespace, give it's index to x and delete it
			while { [set x [lsearch -regexp $pluginsevents(${event}) "\:\:$namespace\:\:*" ]] != -1 } {
				plugins_log core "UnRegistering command $x from $pluginsevents(${event})...\n"
				# the long remove item procedure
				# TODO: move this into a proc?
				set pluginsevents(${event}) [lreplace $pluginsevents(${event}) $x $x]
			}
		}
	}

	###############################################################
        # calledFrom ()
        #
        # Finds out if a proc was called by a plugin.
	#
        # Arguments
        # none
        #
        # Return
        # -1 - not called by a plugin
	# $pluginnamespace - the namespace of the plugin calling the proc
        #

	proc calledFrom {} {
	    set namespace [string trimleft "[uplevel 2 namespace current]" "::"]
	    
	    if {[::plugins::namespaceExists $namespace] == 1} {
		return $namespace
	    } else {
		#this namespace dosn't belong to any plugin
		return -1
	    }
	}

	###############################################################
        # namespaceExists (namespace)
        #
	# finds out if a namespace belongs to a plugin
        #
        # Arguments
        # namespace - namespace to check for (without ::)
        #
        # Return
	# -1 - nope
	# 1 - yup
        #

	proc namespaceExists {namespace} {
		variable plugins
		# go through each namespace
       		foreach {current} [array names plugins *_plugin_namespace] {
		    if { $plugins(${current}) == $namespace } {
			return 1
		    }
		}
		return -1
	}


	###############################################################
	# getInfo (plugin,param)
	#
	# Checks the plugins array and return the parameter in the 
	# plugininfo.xml file that is symbolized by param
	#
	# Arguments
	# plugin - name of plugin
	# param - name of parameter to check for
	#
	# Return
	# string - the value of the parameter, empty if not found
	#
	
	proc getInfo {plugin param} {
		variable plugins
		plugins_log core "Getting $plugin and $param"
		plugins_log core [array names ::plugins::plugins ${plugin}_${param}]
		if {[array names ::plugins::plugins ${plugin}_${param}] != ""} {
			return $plugins(${plugin}_${param})
		}
		return ""
	}

	proc getVarInfo {plugin param} {
		return "::plugins::plugins(${plugin}_${param})"
	}

	###############################################################
        # getPlugins ()
        #
	# Returns a list of existing plugins
        #
	# Arguments
	# none
	#
	# Return
	# list of plugins
	#
	proc getPlugins {} {
		set plugins [list]
		foreach {key plugin} [array get ::plugins::plugins *_name] {
			lappend plugins $plugin
		}
		return $plugins
	}

	###############################################################
        # updatePluginsArray ()
        #
        # Updates the plugins array which holds info about plugins
	# by searching possible plugin directories
        #
        # Arguments
        # none
        #
        # Return
        # none
        #
	
	proc updatePluginsArray { } {

	       	global HOME HOME2 program_dir

		#clear the current array
		array set ::plugins::plugins [list]

		# make a list of all the possible places to search
		#TODO: Allow user to choose where to search
		set search_path [list] 
		lappend search_path [file join $program_dir plugins]
		lappend search_path [file join $HOME plugins]
		if { $HOME != $HOME2} {
			lappend search_path [file join $HOME2 plugins]
		}
		lappend search_path [file join $HOME2 amsn-extras plugins]
	    
		# loop through each directory to search
		foreach dir $search_path {
			# for each file names plugininfo.xml that is in any directory, do stuff
			# -nocomplain is used to shut errors up if no plugins found
			foreach file [glob -nocomplain -directory $dir */plugininfo.xml] {
				plugins_log core "Found plugin files in $file\n"
				::plugins::LoadInfo $file
				::plugins::LoadInfoAutoupdate $file
			}
		}

       	}


	###############################################################
	# LoadInfo ()
	#
	# Loads the XML information file of each plugin and parses it, registering
	# each new plugin with proc ::plugins::XMLInfo
	#
	# Arguments
	# path - the path to the pluginsinfo.xml containing the information in XML format
	#
	# Return
	# list containng the information
	#
	proc LoadInfo { path } {

		set fd [file join [file dirname $path] plugininfo.xml]

		if { [file readable $fd] } {
			
			if { [catch {
				set plugin_info [sxml::init $fd]
				sxml::register_routine $plugin_info "plugin" "::plugins::XMLInfo"
				sxml::parse $plugin_info
				sxml::end $plugin_info
				plugins_log core "PLUGINS INFO READ\n"
			} res] } {
				msg_box "ERROR: PLUGIN HAS MALFORMED XML PLUGININFO ($path)"
				return 0
			}
		}

		return 1

	}

	###############################################################
	# XMLInfo (cstack, cdata, saved_data, cattr saved_attr, args)
	#
	# Raises the information parsed by the sxml component and appends
	# each new plugin to $::plugins::plugins array
	#
	# Arguments
	# supplied by the sxml component (its only executor)
	#
	# Return
	# none
	#

	proc XMLInfo { cstack cdata saved_data cattr saved_attr args } {

		variable plugins
		upvar $saved_data sdata
		#get the path from 2 levels up (::plugins::LoadInfo -> ::sxml::parse -> thisproc)
		#dir is used to set the full path of the file
		upvar 2 path dir

		set name $sdata(${cstack}:name)
		set cur_plugin $name
		set author $sdata(${cstack}:author)

		#Now plugins have an other field in plugininfo.xml in which the description can be translated.
		#It should be used as
		#<description_fr>the description in french</description_fr>
		#The defaut description must be written in english
		#The file should be encoded in utf-8
		set langcode [string tolower [::config::getGlobalKey language]]
		if { ($langcode != "en") && [info exists sdata(${cstack}:description_${langcode}) ] } {
			set desc $sdata(${cstack}:description_${langcode})
		} else {
			set desc $sdata(${cstack}:description)
		}

		set amsn_version $sdata(${cstack}:amsn_version)
		set plugin_version $sdata(${cstack}:plugin_version)
		set plugin_file $sdata(${cstack}:plugin_file)
		set plugin_namespace $sdata(${cstack}:plugin_namespace)
		set init $sdata(${cstack}:init_procedure)

		if { ![info exists sdata(${cstack}:deinit_procedure)] } {
			set deinit ""
		} else {
			set deinit $sdata(${cstack}:deinit_procedure)
		}
		
		set plugins(${name}_name) $name
		set plugins(${name}_author) $author
		set plugins(${name}_description) $desc
		set plugins(${name}_amsn_version) $amsn_version
		set plugins(${name}_plugin_version) $plugin_version
		#dir is the path to pluginsinfo.xml, so we need to use [file dirname] to get the actual dir path
		set plugins(${name}_plugin_file) [file join [file dirname $dir] $plugin_file]
		set plugins(${name}_plugin_dir) [file dirname $dir]
		set plugins(${name}_plugin_namespace) $plugin_namespace
		set plugins(${name}_init_proc) $init
		set plugins(${name}_deinit_proc) $deinit

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
		# the path to the frame where are displayed pieces of information for a plugin
		variable mF

		# clear the selection
		set selection ""
		# set the window path
		set w .plugin_selector

		# if the window already exists, focus it, otherwise create it
		if {[winfo exists $w]} {
			raise $w
			return
		}

		# update the information and list of plugins
		::plugins::updatePluginsArray
		# create window and give it it's title
		toplevel $w
		wm title $w [trans pluginselector]
		wm geometry $w 500x400
		# create widgets
		# listbox with all the plugins
		listbox $w.plugin_list -height 15 -yscrollcommand "$w.ys set" -highlightthickness 0
		scrollbar $w.ys -command "$w.plugin_list yview"

		#Scrollableframe that will contain pieces of information about a plugin
		ScrolledWindow $w.sw 
		ScrollableFrame $w.sw.sf -areaheight 0 -areawidth 0 
		$w.sw setwidget $w.sw.sf
		set mF [$w.sw.sf getframe]	
			
		# holds the plugins info like name and description
		label $mF.name_title -text [trans name] -font sboldf
		label $mF.name  -wraplength 280 
		label $mF.version_title -text [trans version] -font sboldf
		label $mF.version
		label $mF.author_title -text [trans author] -font sboldf
		label $mF.author  -wraplength 280 
		label $mF.desc_title -text [trans description] -font sboldf
		# TODO make the -wraplength fit the label's width
		label $mF.desc -wraplength 280 -justify left -anchor w
		# holds the 'command center' buttons
		label $w.getmore -text "[trans getmoreplugins]" -cursor hand2 -font splainf \
			-background [::skin::getKey extrastdwindowcolor] -foreground [::skin::getKey extralinkcolor]
 
		bind $w.getmore <Enter> "$w.getmore configure -font sunderf -cursor hand2 \
			-background [::skin::getKey extralinkbgcoloractive] -foreground [::skin::getKey extralinkcoloractive]"
		bind $w.getmore <Leave> "$w.getmore configure -font splainf -cursor left_ptr \
			-background [::skin::getKey extrastdwindowcolor] -foreground [::skin::getKey extralinkcolor]"

		set lang [::config::getGlobalKey language]
		bind $w.getmore <ButtonRelease> "launch_browser $::weburl/plugins.php?lang=$lang"


		button $w.load -text "[trans load]" -command "::plugins::GUI_Load" -state disabled
		button $w.config -text "[trans configure]" -command "::plugins::GUI_Config" -state disabled
		button $w.close -text [trans close] -command "::plugins::GUI_Close"
 
		#loop through all the plugins and add them to the list
		foreach {plugin} [lsort -dictionary [array names ::plugins::plugins *_name]] {
		    set name $plugins(${plugin})
		    # add the plugin name to the list at counterid position
		    $w.plugin_list insert end $name
		    # if the plugin is loaded, color it one color. otherwise use other colors
		    if {[lsearch "$loadedplugins" $plugins(${name}_name)] != -1} {
				$w.plugin_list itemconfigure end \
					-bg [::skin::getKey extralistboxselectedbg] -fg [::skin::getKey extralistboxselected] \
					-selectforeground [::skin::getKey extralistboxselected]
			}
		}
		if {[$w.plugin_list size] > "15"} {
			$w.plugin_list configure -height [$w.plugin_list size]
		}
		#do the bindings
		bind $w.plugin_list <<ListboxSelect>> "::plugins::GUI_NewSel"
		bind $w <<Escape>> "::plugins::GUI_Close"

		pack $w.plugin_list -fill both -side left
		pack $w.ys -fill both -side left
		pack $mF.name_title -padx 5 -anchor w
		pack $mF.name -padx 5 -anchor w
		pack $mF.version_title -padx 5 -anchor w
		pack $mF.version -padx 5 -anchor w 
		pack $mF.author_title -padx 5 -anchor w
		pack $mF.author -padx 5 -anchor w
		pack $mF.desc_title -padx 5 -anchor w
		pack $mF.desc -anchor nw -expand true -fill x -padx 5
		pack $w.sw -anchor w -side top -expand true -fill both
		pack $w.getmore -side top -anchor e -padx 5
		pack $w.close $w.config $w.load -padx 5 -pady 5 -side right -anchor se

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
		# the path to the frame where are displayed pieces of information for a plugin
		variable mF

		# find the id of the currently selected plugin
		if { [ $w.plugin_list curselection ] == "" } {
			return
		}
		set selection [$w.plugin_list get [$w.plugin_list curselection]]
		# if the selection is empty, end proc
		if { $selection == "" } {
			return
		}

		# update the description
		$mF.name configure -text $selection
		$mF.author configure -text [getInfo $selection author]
		$mF.version configure -text [getInfo $selection plugin_version]
		$mF.desc configure -text [getInfo $selection description]
		
		# update the buttons

		$w.config configure -state normal

		if {[lsearch "$loadedplugins" $selection] != -1 } {
			# if the plugin is loaded, enable the Unload button and update the colors
			$w.load configure -state normal -text [trans unload] -command "::plugins::GUI_Unload"
			$w.plugin_list itemconfigure [$w.plugin_list curselection] \
				-bg [::skin::getKey extralistboxselectedbg] -fg [::skin::getKey extralistboxselected] \
				-selectforeground [::skin::getKey extralistboxselected]

			# if the plugin has a configlist, then enable configuration.
			# Otherwise disable it
			if {[info exists ::[getInfo $selection plugin_namespace]::configlist] == 1} {
				$w.config configure -state normal
			} else {
				$w.config configure -state disabled
			}
		} else { # plugin is not loaded
			# enable the load button and disable config button and update color
			$w.load configure -state normal -text "[trans load]" -command "::plugins::GUI_Load"
			$w.plugin_list itemconfigure [$w.plugin_list curselection] \
				-bg [::skin::getKey extrastdbgcolor] -fg [::skin::getKey extrastdtxtcolor] \
				-selectforeground [::skin::getKey extraselectedtxtcolor]

			$w.config configure -state disabled
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
		#info about the plugins
		variable plugins
		# don't do anything is there is no selection
		if { $selection == "" } {
			plugins_log core "Cannot load plugin, none selected"
			return
		}

		# Do the actual loading and check if it loads properly
		if { [LoadPlugin $selection] == -1 } {
			return
		}

		#update the buttons and colors in the plugins dialog
		GUI_NewSel
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

		if {$selection==""} {
		    return;
		}

		# close configure dialog
		if {[winfo exists ${w}.winconf_$selection]} {
			destroy ${w}.winconf_$selection
		}

		
		# do the actual unloading
		UnLoadPlugin $selection
		# update the buttons and colors in the dialog
		GUI_NewSel
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
	    #info about the plugins
	    variable plugins

	    #the standard "check for selection"
	    if { $selection == "" } {
		return
	    }

	    #name of the configuration window
	    set confw ${w}.winconf_$selection

	    #If the window is already here, just raise it to the front
	    if { [winfo exists $confw] } {
		raise $confw
		return
	    } else {
		#create the configuration window
		set winconf [toplevel $confw]
	    }

	    # list of callbacks for pressing save of frame types
	    variable saveframelist 
	    set saveframelist {}
	    
	    # get the name
	    set name $selection
	    set namespace [getInfo $selection plugin_namespace]

	    plugins_log core "Calling ConfigPlugin in the $name namespace\n"

	    # is there a config list?
	    if {[info exists ::${namespace}::configlist] == 0} {
	    	# no config list, just put a label "Nothing to configure" in the configure dialog
		plugins_log core "No Configuration variable for $name.\n"
		label $winconf.label -text "No Configuration variable for $name.\n"
		button $winconf.ok -text [trans ok] -command "destroy $winconf"
		pack $winconf.label
		pack $winconf.ok
	    } else { # configlist exists
		    # backup the current config
		    array set ::${namespace}::old_config [array get ::${namespace}::config]
		    # create the frame where the configuration is gonna get packed
		    set confwin [frame $winconf.area]
		    # id used for the item name in the widget
		    set i 0
		    # loop through all the items
		    foreach confitem [set ::${namespace}::configlist] {
			# Increment both variables
			incr i
			# Check the configuration item type and create it in the GUI
			switch [lindex $confitem 0] {
			    label {
				# This configuration item is a label (Simply text to show)
				label $confwin.$i -text [lindex $confitem 1]
				pack $confwin.$i -anchor w -padx 10
			    }
			    bool {
				# This configuration item is a checkbox (Boolean variable)
				checkbutton $confwin.$i -text [lindex $confitem 1] -variable \
				    ::${namespace}::config([lindex $confitem 2])
				pack $confwin.$i -anchor w -padx 20
			    }
			    ext {
				# This configuration item is a button (Action related to key)
				button $confwin.$i -text [lindex $confitem 1] -command \
				    ::${namespace}::[lindex $confitem 2]
				pack $confwin.$i -anchor w -padx 20 -pady 5
			    }
			    str {
				# This configuration item is a text input (Text string variable)
				set frame [frame $confwin.f$i]
				entry $frame.${i}e -textvariable \
				    ::${namespace}::config([lindex $confitem 2])
				label $frame.${i}l -text [lindex $confitem 1]
				pack $frame.${i}l -anchor w -side left -padx 20
				pack $frame.${i}e -anchor w -side left -fill x
				pack $frame -fill x
			    }
			    pass {
				# This configuration item is a password input (Text string variable)
				set frame [frame $confwin.f$i]
				entry $frame.${i}e -show "*" -textvariable \
				    ::${namespace}::config([lindex $confitem 2])
				label $frame.${i}l -text [lindex $confitem 1]
				pack $frame.${i}l -anchor w -side left -padx 20
				pack $frame.${i}e -anchor w -side left -fill x
				pack $frame -fill x -anchor w
			    }
			    lst {
				# This configuration item is a listbox that stores the selected item.
				set height [llength [lindex $confitem 1]]
				listbox $confwin.$i -height $height -width 0
				foreach item [lindex $confitem 1] {
				    $confwin.$i insert end $item
				}
				bind $confwin.$i <<ListboxSelect>> "::plugins::lst_refresh $confwin.$i ::${namespace}::config([lindex $confitem 2])"
				pack $confwin.$i -anchor w -padx 40
			    }
			    rbt {
				# This configuration item contains radiobutton
				set buttonlist [lrange $confitem 1 end-1]
				set value 0
				foreach item $buttonlist {
				    incr value
				    radiobutton $confwin.$i -text "$item" -variable ::${namespace}::config([lindex $confitem end]) -value $value
				    pack $confwin.$i -anchor w -padx 40
				    incr i
				}
				incr i -1
			    }
			    frame {
			    	# This configureation item creates a frame so the plugin can place whatever it like inside
				frame $confwin.$i
				[lindex $confitem 1] $confwin.$i
				if { "[lindex $confitem 2]" != "" } {
					lappend saveframelist "[lindex $confitem 2] $confwin.$i"
				}
				pack $confwin.$i -fill x -anchor w
			    }
			}
		    }
		}
		
		# set the name of the winconf
		wm title $confw [trans configureplugin $selection]
		
		# Grid the frame
		pack $confwin -fill x
		# Create and grid the buttons
		button $winconf.save -text [trans save] -command "[list ::plugins::GUI_SaveConfig $winconf $name]"
		button $winconf.cancel -text [trans cancel] -command "[list ::plugins::GUI_CancelConfig $winconf $namespace]"
		pack $winconf.save -anchor se -pady 5 -padx 5 -side right
		pack $winconf.cancel -anchor se -pady 5 -padx 5 -side right
		bind $winconf <<Escape>> "destroy $winconf"
		moveinscreen $winconf 30
	}


	###############################################################
	# lst_refresh (path, config)
	#
	# The list box on config window changes its selected value, so
	# this proc refresh the associated variable with the new value
	#
	# Arguments
	# path - The listbox widget path 
	# config - The complete config entry (with plugin namespace)
	#
	# Return
	# none
	#
	proc lst_refresh { path config } {
		set ${config} [$path get [$path curselection] [$path curselection]]	
	}


	###############################################################
	# GUI_SaveConfig (w)
	#
	# The Save button in Configuration Window is clicked. Save the
	# plugins configuration and then destroy the Configuration Window
	#
	# Arguments
	# w - The configuration window widget path
	# name - The name of the plugin that was changed (if any)
	#
	# Return
	# none
	#
	proc GUI_SaveConfig { w {name ""}} {
		variable saveframelist
		
		if { $name != "" } {
			#add a postevent to warn the plugin when it is configured
			set evPar(name) $name
			::plugins::PostEvent PluginConfigured evPar
		}
		
		foreach call $saveframelist {
			eval $call
		}

		set saveframelist {}

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
		array set ::${namespace}::config [array get ::${namespace}::old_config]
		#unset the old array to save space
		unset ::${namespace}::old_config

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
		destroy $w
	}


	###############################################################
	# UnLoadPlugins ()
	#
	# Unloads all loaded plugins (if any) 
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc UnLoadPlugins { {saveBefore 1} } {
		variable loadedplugins

		if {$saveBefore} {
			::plugins::save_config
		}

		foreach {plugin} "$loadedplugins" {
			# the "0" is to tell UnLoadPlugin not to save the config
			::plugins::UnLoadPlugin $plugin 0
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
	proc UnLoadPlugin { plugin {save 1}} {

		variable loadedplugins
		plugins_log core "Unloading plugin $plugin\n"

		#unregister events
		UnRegisterEvents $plugin

		#get the namespace and deinit proc and if it exists, call it
		set namespace [getInfo $plugin plugin_namespace]
		set deinit [getInfo $plugin deinit_proc]
		if {[info procs "::${namespace}::${deinit}"] == "::${namespace}::${deinit}"} {
			if { [catch {::${namespace}::${deinit}} res] } {
				plugins_log core "Error in deinit proc : $res"
			}
		}

		#copy the config array to a config plugin
		if {[array exists ::${namespace}::config]} {
			set ::plugins::config($plugin) [array get ::${namespace}::config]
		}

		#remove it from the loadedplugins list
		set loadedplugins [lreplace $loadedplugins [lsearch $loadedplugins "$plugin"] [lsearch $loadedplugins "$plugin"]]

		if {$save} { ::plugins::save_config }

	}


	###############################################################
	# LoadPlugins ()
	#
	# Loads all plugins that were previously loaded (stored in
	# configuration file plugins.xml) reading $loadedplugins
	# Also it loads all the core plugins
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc LoadPlugins {} {

	    variable loadedplugins
		# the "0" is to tell UnLoadPlugins not to save the config before unloading plugins
	    ::plugins::UnLoadPlugins 0
	    
	    #resets the loadedplugins list to plugins that were loaded before
	    load_config

	    #update the list of installed plugins because this proc is usually 
	    #called when a new user logs in, so he migh have diff plugins in
	    # his ~/.amsn/{user}/plugins
	    ::plugins::updatePluginsArray

	    foreach plugin $loadedplugins {
		status_log "PLUGIN : $plugin\n" red
		#check if the plugin exists, then load it
		#TODO: what should we do if it doesn't exist?
		# - remove it from loadedplugins, but how to we know to load it if it exists
		# - (current) keep it and hope nothing calls a proc that depends on this plugin to be loaded (and checks if it is loaded)
		if {[array names ::plugins::plugins ${plugin}_name] != ""} {
			LoadPlugin $plugin
		}
	    }

	}


	###############################################################
	# LoadPlugin (plugin)
	#
	# Loads the $plugin plugin and restore its configuration from
	# global namespace if existed.
	#
	# The reason for all the arguments is developemnt testing,
	# we can test different files via the status_log window
	#
	# Arguments
	# plugin - The plugin to load (name)
	# required_version - Required aMSN version for the plugin to load
	# file - The plugin's TCL main file
        # namespace - The plugin's main namespace
        # init_proc - The plugin's init procedure
	#
	# Return
	# 1 - success
	# -1 - failiture
	#
	proc LoadPlugin { plugin } {

		variable loadedplugins

		set required_version [getInfo $plugin amsn_version]
		set file [getInfo $plugin plugin_file]
		set namespace [getInfo $plugin plugin_namespace]
		set init_proc [getInfo $plugin init_proc]

		#error checking
		if { ![CheckRequirements $required_version] } {
			msg_box "$plugin: [trans required_version $required_version]"
			return -1
		}

		if { [catch { source $file } res] } {
			msg_box "$plugin: Failed to load source with result:\n\n$res"
			return -1
		}

		#copy the config if it exists
		if {[array names ::plugins::config $plugin] != ""} {
			if {$::plugins::config(${plugin}) != ""} {
				array set ::${namespace}::config $::plugins::config(${plugin})
			}
		}
	    
		#add it to loadedplugins, if it's not there already
		#we need to add it before the init_proc is called!
		if {[lsearch "$loadedplugins" $plugin] == -1} {
			plugins_log core "appending to loadedplugins\n"
			lappend loadedplugins $plugin
		}

		#call the init proc if it exists
		if {[info procs ::${namespace}::${init_proc}] == "::${namespace}::${init_proc}"} {
			plugins_log core "Initializing plugin $plugin with ${namespace}::${init_proc}\n"
	
			#check for Tcl/Tk errors
			if {[catch {::${namespace}::${init_proc} [file dirname $file]} res] } {
				plugins_log core "Initialization of plugin $plugin with ${namespace}::${init_proc} failed\n$res\n$::errorInfo"
				msg_box "Plugins System: Can't initialize plugin:init procedure caused an internal error"
				UnLoadPlugin $plugin
				return -1
			#If proc returns -1, end because it failed because it's own reasons
			} elseif {$res == -1} {
				UnLoadPlugin $plugin
				return -1
			}
			#can someone explain what this is for?
			eval {proc ::${namespace}::${init_proc} {file} { return } }
		} else {
			msg_box "Plugins System: Can't initialize plugin:init procedure not found"
			return -1
		}

	    	if {[array names ::plugins::config $plugin] != ""} {
			if {$::plugins::config(${plugin}) != ""} {
				array set ::${namespace}::config $::plugins::config(${plugin})
			}
			unset ::plugins::config(${plugin})
		} else {
			plugins_log core "Plugins System: no config for plug-in $plugin\n"
		}
				
		#Call PostEvent Load
		#Keep in variable if we are online or not
		#TODO: dosn't exist on start?
		if { [catch { set stat [ns cget -stat] } ] } {
			set status offline
		} elseif { $stat == "o" } {
	      		set status online
		} else {
			set status offline
		}
		set evpar(name) $plugin
		set evpar(status) $status
		::plugins::PostEvent Load evpar
		::plugins::save_config
		return 1
	}


	###############################################################
	# CheckRequirements (required_version)
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
	proc CheckRequirements { required_version } {
		global version
		plugins_log core "Plugin needs $required_version"
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
	# Saves the configuration of loaded plugins and ::plugins::config
	# in plugins.xml.
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc save_config { } {
		global HOME HOME2
		variable loadedplugins

		plugins_log core "save_config: saving plugin config for user [::config::getKey login] in $HOME\n"
	
		# check if this is the default profile
		if { $HOME == $HOME2 } { 
			plugins_log core "save_config: Default profile, no plugin configuration saved!\n"
			catch {file delete -force [file join ${HOME} plugins.xml]}
			return 0
		}

		if { [catch {
			if { [OnUnix] } {
				set file_id [open "[file join ${HOME} plugins.xml]" w 00600]
			} else {
				set file_id [open "[file join ${HOME} plugins.xml]" w]
			}
		} res]} {
			return 0
		}


		plugins_log core "save_config: saving plugin config_file. Opening of file returned : $res\n"

		puts $file_id  "<?xml version=\"1.0\"?>\n\n<config>"

		#save the loaded plugins
		foreach {plugin} $loadedplugins {
			set namespace [getInfo $plugin plugin_namespace]
			puts $file_id "\t<plugin>"
			puts $file_id "\t\t<name>${plugin}</name>"
			puts $file_id "\t\t<loaded>true</loaded>"
			if {[array exists ::${namespace}::config]==1} {
				plugins_log core "save_config: Saving from $plugin's namespace: $namespace\n"
				foreach var_attribute [array names ::${namespace}::config] {
					#TODO: a better way to do this
					#set var_value $::${namespace}::config(${var_attribute})
					set var_value ::${namespace}::config
					set var_value [lindex [array get $var_value $var_attribute] 1]
					set var_value [::sxml::xmlreplace $var_value]
					puts $file_id "\t\t<entry>"
					puts $file_id "\t\t\t<key>$var_attribute</key>"
					puts $file_id "\t\t\t<value>$var_value</value>"
					puts $file_id "\t\t</entry>"
				}
			}
			puts $file_id "\t</plugin>"
		}
		
		#save the other plugins
		foreach {plugin} [array names ::plugins::config] {
			puts $file_id "\t<plugin>"
			puts $file_id "\t\t<name>${plugin}</name>"
			puts $file_id "\t\t<loaded>false</loaded>"
			foreach {var_attribute var_value} $plugins::config($plugin) {
				set var_value [::sxml::xmlreplace $var_value]
				puts $file_id "\t\t<entry>\n"
				puts $file_id "\t\t\t<key>$var_attribute</key>\n"
				puts $file_id "\t\t\t<value>$var_value</value>\n"
				puts $file_id "\t\t</entry>"
			}
			puts $file_id "\t</plugin>"
			
		}

		puts $file_id "</config>"
		close $file_id

		plugins_log core "save_config: Plugins config saved\n"
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
		global HOME password
		variable loadedplugins
		foreach {plugin} $loadedplugins {
			::plugins::UnLoadPlugin $plugin
		}
		set loadedplugins [list]

		if { [file exists [file join ${HOME} "plugins.xml"]] } {
			plugins_log core "load_config: loading file [file join ${HOME} plugins.xml]\n"
			if { [catch {
				set file_id [::sxml::init [file join ${HOME} "plugins.xml"]]
				::sxml::register_routine $file_id "config:plugin:name" "::plugins::new_plugin_config"
				::sxml::register_routine $file_id "config:plugin:loaded" "::plugins::new_plugin_loaded"
				::sxml::register_routine $file_id "config:plugin:entry" "::plugins::new_plugin_entry_config"
				::sxml::parse $file_id
				::sxml::end $file_id
				plugins_log core "load_config: Config loaded\n"
			} res] } {
				::amsn::errorMsg "[trans corruptconfig [file join ${HOME} "plugins.xml.old"]]"
				file copy [file join ${HOME} "plugins.xml"] [file join ${HOME} "plugins.xml.old"]
			}
		} else {

			#"HACK" to load 'core' plugins for the 0.95 release
			#HERE WE HAVE A LIST OF PLUGINS THAT ARE SHIPPED WITH AMSN AND SHOULD BE LOADED IF THE USER SEES 'M FOR THE FIRST TIME
			#logic: if this is the first time the user logged in, then 
			#the configuration list is empty which means load_config
			#makes loadedplugins empty
			set loadedplugins [list "Nudge" "Winks" "Cam Shooter" "remind" "Notes"]

			status_log "Plugins System: load_config: No plugins.xml]\n" red
		}
	}


	###############################################################
	# new_plugin_config (cstack, cdata, saved_data, cattr saved_attr, args)
	#
	# Raises the information parsed by the sxml component and appends
	# each new plugin from plugin.xml to config
	#
	# Arguments
	# supplied by the sxml component (its only executor)
	#
	# Return
	# none
	#
	proc new_plugin_config {cstack cdata saved_data cattr saved_attr args} {
		variable cur_plugin
		set cur_plugin $cdata
		set ::plugins::config(${cur_plugin}) [list]
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
		plugins_log core "$cur_plugin has a loaded tag with $yes in it...\n"
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
		lappend ::plugins::config(${cur_plugin}) $sdata(${cstack}:key) $sdata(${cstack}:value);
		return 0
	}


	###############################################################
	# LoadInfoAutoupdate (plugin)
	#
	# Load the XML information of a plugin for autoupdate
	#
	# Arguments
	# The name of the plugin
	#
	# Return
	# 0 if an error occured, 1 else
	#
	proc LoadInfoAutoupdate { plugin } {

		variable plugins
		variable cur_plugin $plugin

		set plugins(${plugin}_lang) ""
		set plugins(${plugin}_file) ""

		set fd [file join [getInfo $plugin plugin_dir] plugininfo.xml]

		if { [file readable $fd] } {
			
			if { [catch {
				set plugin_info [sxml::init $fd]
				sxml::register_routine $plugin_info "plugin" "::plugins::XMLInfoCVS"
				sxml::register_routine $plugin_info "plugin:lang" "::plugins::XMLInfoLang"
				sxml::register_routine $plugin_info "plugin:file" "::plugins::XMLInfoFile"
				sxml::register_routine $plugin_info "plugin:URL" "::plugins::XMLInfoURLplugininfo"
				sxml::parse $plugin_info
				sxml::end $plugin_info
				plugins_log core "PLUGINS INFO READ\n"
			} res] } {
				msg_box "ERROR: PLUGIN $plugin HAS MALFORMED XML PLUGININFO for autoupdate"
				return 0
			}
		}

		return 1

	}


	###############################################################
	# XMLInfoCVS (cstack, cdata, saved_data, cattr saved_attr, args)
	# XMLInfoLang (cstack, cdata, saved_data, cattr saved_attr, args)
	# XMLInfoFile (cstack, cdata, saved_data, cattr saved_attr, args)
	# XMLInfoURL (cstack, cdata, saved_data, cattr saved_attr, args)
	#
	# Raises the information parsed by the sxml component and appends
	# each new plugin to $::plugins::plugins array
	#
	# Arguments
	# supplied by the sxml component (its only executor)
	#
	# Return
	# none
	#
	proc XMLInfoCVS { cstack cdata saved_data cattr saved_attr args } {

		upvar $saved_data sdata
		variable plugins
		variable cur_plugin

		if { ![info exists sdata(${cstack}:cvs_version)] } {
			set cvs_version ""
		} else {
			set cvs_version $sdata(${cstack}:cvs_version)
		}

		set plugins(${cur_plugin}_cvs_version) $cvs_version

		return 0

	}


	proc XMLInfoLang { cstack cdata saved_data cattr saved_attr args } {

		upvar $saved_data sdata
		variable plugins
		variable cur_plugin

		if { ![info exists sdata(${cstack}:langcode)] || ![info exists sdata(${cstack}:version)] } {
			set  langcode ""
			set version ""
		} else {
			set langcode $sdata(${cstack}:langcode)
			set version $sdata(${cstack}:version)
		}

		lappend plugins(${cur_plugin}_lang) [list $langcode $version]

		return 0

	}


	proc XMLInfoFile { cstack cdata saved_data cattr saved_attr args } {

		upvar $saved_data sdata
		variable plugins
		variable cur_plugin

		if { ![info exists sdata(${cstack}:path)] || ![info exists sdata(${cstack}:version)] } {
			set  path ""
			set version ""
		} else {
			set path $sdata(${cstack}:path)
			set version $sdata(${cstack}:version)
		}

		lappend plugins(${cur_plugin}_file) [list $path $version]

		return 0

	}
	
	
	proc XMLInfoURLplugininfo { cstack cdata saved_data cattr saved_attr args } {
	
		upvar $saved_data sdata
		variable plugins
		variable cur_plugin
		
		if { ![info exists sdata(${cstack}:plugininfo)] } {
			set URL_plugininfo ""
		} else {
			set URL_plugininfo $sdata(${cstack}:plugininfo)
		}

		set plugins(${cur_plugin}_URL_plugininfo) $URL_plugininfo

		return 0
		
	}


	###############################################################
	# LoadInfoAutoupdate_Online (plugin)
	#
	# Get the plugininfo.xml on the website, and load it
	#
	# Arguments
	# The name of the plugin
	#
	# Return
	# 0 if an error occured, 1 else
	#
	proc LoadInfoAutoupdate_Online { plugin } {

		global HOME2
		variable plugins
		variable cur_plugin $plugin

		set plugins(${plugin}_lang_online) ""
		set plugins(${plugin}_file_online) ""
		
		set URL [getInfo $plugin URL_plugininfo]
		
		if { [catch {
			
			# If no URL is given, look at the CVS URL
			if { $URL == "" } {
				
				set token [::http::geturl "${::weburl}/autoupdater/plugins/$plugin/plugininfo.xml" -timeout 120000 -binary 1]
				set content [::http::data $token]
				::http::cleanup $token
				
				if { [string first "<html>" "$content"] == -1 } {
					set plugins(${plugin}_URL_place) 1
				} else {
					set token [::http::geturl "${::weburl}/autoupdater/plugins2/$plugin/plugininfo.xml" -timeout 120000 -binary 1]
					set content [::http::data $token]
					if { [string first "<html>" "$content"] == -1 } {
						set plugins(${plugin}_URL_place) 2
					} else {
						::http::cleanup $token
						return 0
					}
					
				}

				
				# Else, look at the URL given
			} else {
				
				set token [::http::geturl "$URL" -timeout 120000 -binary 1]
				set content [::http::data $token]
				if { [string first "<html>" "$content"] != -1 } {
					::http::cleanup $token
					return 0
				}
				set plugins(${plugin}_URL_place) 3
				
			}
			
			set status [::http::status $token]
			if { $status != "ok" } {
				status_log "Can't get plugininfo.xml for $plugin (place [getInfo $plugin URL_place] - URL $URL): $status (http token: $token)\n" red
				::http::cleanup $token
				return 0
			}
			
			set filename "[file join $HOME2 $plugin.xml]"
			set fid [open $filename w]
			fconfigure $fid -encoding binary
			puts -nonewline $fid "$content"
			close $fid
			::http::cleanup $token
		
			set id [::sxml::init $filename]
			sxml::register_routine $id "plugin" "::plugins::XMLInfoCVS_Online"
			sxml::register_routine $id "plugin:lang" "::plugins::XMLInfoLang_Online"
			sxml::register_routine $id "plugin:file" "::plugins::XMLInfoFile_Online"
			sxml::register_routine $id "plugin:URL" "::plugins::XMLInfoURL_Online"
			sxml::parse $id
			sxml::end $id
			
		} ] } {
			if {[info exists token] } {
				status_log "Can't get online plugininfo.xml for $plugin (place [getInfo $plugin URL_place] - URL $URL)(token: $token)\n" red
				::http::cleanup $token
			}
			return 0
			
		}
		
		return 1

	}


	###############################################################
	# XMLInfoCVS_Online (cstack, cdata, saved_data, cattr saved_attr, args)
	# XMLInfoLang_Online (cstack, cdata, saved_data, cattr saved_attr, args)
	# XMLInfoFile_Online (cstack, cdata, saved_data, cattr saved_attr, args)
	# XMLInfoURL_Online (cstack, cdata, saved_data, cattr saved_attr, args)
	#
	# Raises the information parsed by the sxml component and appends
	# each new plugin to $::plugins::plugins array
	#
	# Arguments
	# supplied by the sxml component (its only executor)
	#
	# Return
	# none
	#
	proc XMLInfoCVS_Online { cstack cdata saved_data cattr saved_attr args } {

		upvar $saved_data sdata
		variable plugins
		variable cur_plugin

		if { ![info exists sdata(${cstack}:amsn_version)] || ![info exists sdata(${cstack}:cvs_version)] } {
			set amsn_version ""
			set cvs_version ""
		} else {
			set amsn_version $sdata(${cstack}:amsn_version)
			set cvs_version $sdata(${cstack}:cvs_version)
		}

		set plugins(${cur_plugin}_amsn_version_online) $amsn_version
		set plugins(${cur_plugin}_cvs_version_online) $cvs_version

		return 0

	}


	proc XMLInfoLang_Online { cstack cdata saved_data cattr saved_attr args } {

		upvar $saved_data sdata
		variable plugins
		variable cur_plugin

		if { ![info exists sdata(${cstack}:langcode)] || ![info exists sdata(${cstack}:version)] } {
			set  langcode ""
			set version ""
		} else {
			set langcode $sdata(${cstack}:langcode)
			set version $sdata(${cstack}:version)
		}

		lappend plugins(${cur_plugin}_lang_online) [list $langcode $version]

		return 0

	}


	proc XMLInfoFile_Online { cstack cdata saved_data cattr saved_attr args } {

		upvar $saved_data sdata
		variable plugins
		variable cur_plugin

		if { ![info exists sdata(${cstack}:path)] || ![info exists sdata(${cstack}:version)] } {
			set  path ""
			set version ""
		} else {
			set path $sdata(${cstack}:path)
			set version $sdata(${cstack}:version)
		}

		lappend plugins(${cur_plugin}_file_online) [list $path $version]

		return 0

	}


	proc XMLInfoURL_Online { cstack cdata saved_data cattr saved_attr args } {

		upvar $saved_data sdata
		variable plugins
		variable cur_plugin
		
		if { ![info exists sdata(${cstack}:main)] } {
			set URL_main ""
		} else {
			set URL_main $sdata(${cstack}:main)
		}

		if { ![info exists sdata(${cstack}:plugininfo)] } {
			set URL_plugininfo ""
		} else {
			set URL_plugininfo $sdata(${cstack}:plugininfo)
		}

		if { ![info exists sdata(${cstack}:lang)] } {
			set URL_lang ""
		} else {
			set URL_lang $sdata(${cstack}:lang)
		}

		if { ![info exists sdata(${cstack}:file)] } {
			set URL_file ""
		} else {
			set URL_file $sdata(${cstack}:file)
		}


		set plugins(${cur_plugin}_URL_main_online) $URL_main
		set plugins(${cur_plugin}_URL_plugininfo_online) $URL_plugininfo
		set plugins(${cur_plugin}_URL_lang_online) $URL_lang
		set plugins(${cur_plugin}_URL_file_online) $URL_file

		return 0

	}


	###############################################################
	# DownloadMain (plugin)
	#
	# Download the main file of a plugin
	#
	# Arguments
	# The name of the plugin
	#
	# Return
	# 0 if there was a problem, 1 else
	#
	proc DownloadMain { plugin } {
	
		variable plugins

		set version [getInfo $plugin cvs_version_online]

		set w ".updatelangplugin"
		
		if { [winfo exists $w] } {
			$w.update.txt configure -text "[trans updating] $plugin..."
		}

		set place [getInfo $plugin URL_place]
		set URL [getInfo $plugin URL_main_online]	
		
		if { $place == 1 } {
			set token [::http::geturl "${::weburl}/autoupdater/plugins/$plugin/[getInfo $plugin plugin_file]" -timeout 120000 -binary 1]
		} elseif { $place == 2 } {
			set token [::http::geturl "${::weburl}/autoupdater/plugins2/$plugin/[getInfo $plugin plugin_file]" -timeout 120000 -binary 1]
		} elseif { $place == 3 && $URL != "" } {
			set URL "[subst $URL]"
			set token [::http::geturl "$URL" -timeout 120000 -binary 1]
		} else {
			return -1
		}

		set status [::http::status $token]
		if { $status != "ok" } {
			::http::cleanup $token
			return -2
		}

		set content [::http::data $token]
		
		if { [string first "<html>" "$content"] != -1 } {
			::http::cleanup $token
			return -3
		}

		set filename [file join [getInfo $plugin plugin_dir] [getInfo $plugin plugin_file]]
		set fid [open $filename w]
		fconfigure $fid -encoding binary
		puts -nonewline $fid "$content"
		close $fid
		::http::cleanup $token		
		
		return 1

	}

	###############################################################
	# DownloadLangs (plugin langs)
	#
	# Download the lang files of a plugin
	#
	# Arguments
	# The name of the plugin
	# The langs we want to download, which is a list of items "{langcode version}"
	#
	# Return
	# 0 if there was a problem, 1 else
	#
	proc DownloadLangs { plugin langs } {

		variable plugins

		set w ".updatelangplugin"
		
		foreach lang $langs {

			set langcode [lindex $lang 0]
			set version [lindex $lang 1]
		
			if { [winfo exists $w] } {
				$w.update.txt configure -text "[trans updating] $plugin : lang$langcode..."
			}

			set place [getInfo $plugin URL_place]
			set URL [getInfo $plugin URL_lang_online]

			if { $place == 1 } {
				set token [::http::geturl "${::weburl}/autoupdater/plugins/$plugin/lang/lang$langcode" -timeout 120000 -binary 1]
			} elseif { $place == 2 } {
				set token [::http::geturl "${::weburl}/autoupdater/plugins2/$plugin/lang/lang$langcode" -timeout 120000 -binary 1]
			} elseif { $place == 3 && $URL != "" } {
				set URL "[subst $URL]"
				set token [::http::geturl "$URL" -timeout 120000 -binary 1]
			} else {
				return 0
			}

			set status [::http::status $token]
			if { $status != "ok" } {
				::http::cleanup $token
				return 0
			}

			set content [::http::data $token]
			
			if { [string first "<html>" "$content"] != -1 } {
				::http::cleanup $token
				return 0
			}

			set filename [file join [getInfo $plugin plugin_dir] "lang" lang$langcode]
			set dir [file join [getInfo $plugin plugin_dir] "lang"]

			if { ![file isdirectory $dir] } {
				file mkdir $dir
				status_log "Auto-update ($plugin) : create dir $dir\n" red
			}

			set fid [open $filename w]
			fconfigure $fid -encoding binary
			puts -nonewline $fid "$content"
			close $fid
			::http::cleanup $token

		}
		
		return 1
		
	}


	###############################################################
	# DownloadFiles (plugin files)
	#
	# Download the other files of a plugin
	#
	# Arguments
	# The name of the plugin
	# The files we want to download, which is a list of items "{path version}"
	#
	# Return
	# 0 if there was a problem, 1 else
	#
	proc DownloadFiles { plugin files } {

		variable plugins
		
		set w ".updatelangplugin"
		
		foreach file_version $files {

			set file [lindex $file_version 0]
			set version [lindex $file_version 1]

			if { [winfo exists $w] } {
				$w.update.txt configure -text "[trans updating] $plugin : $file..."
			}

			set place [getInfo $plugin URL_place]
			set URL [getInfo $plugin URL_file_online]

			if { $place == 1 } {
				set token [::http::geturl "${::weburl}/autoupdater/plugins/$plugin/$file" -timeout 120000 -binary 1]
			} elseif { $place == 2} {
				set token [::http::geturl "${::weburl}/autoupdater/plugins2/$plugin/$file" -timeout 120000 -binary 1]
			} elseif { $place == 3 && $URL != "" } {
				set URL "[subst $URL]"
				set token [::http::geturl "$URL" -timeout 120000 -binary 1]
			} else {
				return 0
			}

			set status [::http::status $token]
			if { $status != "ok" } {
				::http::cleanup $token
				return 0
			}

			set content [::http::data $token]
			
			if { [string first "<html>" "$content"] != -1 } {
				::http::cleanup $token
				return 0				
			}

			set filename [file join [getInfo $plugin plugin_dir] $file]
			set dir [file join [getInfo $plugin plugin_dir] [file dirname $file]]

			if { ![file isdirectory $dir] } {
				file mkdir $dir
				status_log "Auto-update ($plugin) : create dir $dir\n" red
			}

			set fid [open $filename w]
			fconfigure $fid -encoding binary -translation {binary binary}
			puts -nonewline $fid "$content"
			close $fid
			::http::cleanup $token
			
		}
		
		return 1

	}


	###############################################################
	# UpdatePlugin (plugin)
	#
	# Update a plugin
	#
	# Arguments
	# The name of the plugin
	#
	# Return
	# none
	#
	proc UpdatePlugin { plugin } {
	
		variable plugins
		variable loadedplugins

		set error 0
		set mainstate 0
		set langstate 0
		set filestate 0

		# if no error occurs while updating the plugin, save the plugininfo.xml file		
		#if { [catch {

			if { [getInfo $plugin updated_main] == 1 } {
				set mainstate [DownloadMain $plugin]
			} else {
				set mainstate 1
			}

			if { [getInfo $plugin updated_lang] == 1 } {
				set langstate [DownloadLangs $plugin [getInfo $plugin updated_langs]]
			} else { 
				set langstate 1
			}

			if { [getInfo $plugin updated_file] == 1 } {
				set filestate [DownloadFiles $plugin [getInfo $plugin updated_files]]
			} else {
				set filestate 1
			}

		#	}] } {

		#	status_log "Error while updating $plugin\n" red
		#	set error 1

		#}

		if { $mainstate == 1 && $langstate == 1 && $filestate == 1 && $error == 0 } {

			SavePlugininfo $plugin
			
			# Reload the plugin if it was loaded
			if { [lsearch $loadedplugins $plugin] != -1 } {
				UnLoadPlugin $plugin
				LoadPlugin $plugin
			}
			
		} else {
			status_log "Error while updating $plugin : main $mainstate, lang $langstate, file $filestate, error $error\n" red
		}
		
	}


	###############################################################
	# UpdatedPlugins ()
	#
	# Look for updated files for every plugins
	#
	# Arguments
	# none
	#
	# Return
	# 1 if a plugin has been updated, 0 else
	#

	proc UpdatedPlugins { } {

		variable plugins

		set updatedplugins 0

		foreach plugin [getPlugins] {

			set updated 0
			set protected 0

			LoadInfoAutoupdate $plugin

			set path [getInfo $plugin plugin_dir]

			# If the file is protected
			if { ![file writable [file join $path plugininfo.xml]] } {
				continue
			}

			if { [LoadInfoAutoupdate_Online $plugin] == 0 } {
				continue
			}

			if { [getInfo $plugin amsn_version_online] == ""} {
				continue
			}

			# If the online plugin is not compatible with the current version of aMSN
			if { ![::plugins::CheckRequirements [getInfo $plugin amsn_version_online]] } {
				status_log "Can't update $plugin : required version [getInfo $plugin amsn_version_online]\n" red
				continue
			}

			# If the main file has been updated
			if { [DetectNew [getInfo $plugin cvs_version] [getInfo $plugin cvs_version_online]] } {

				set file [file join $path [getInfo $plugin plugin_file]]
				
				if { ![file writable $file] } {
					status_log "File $file is protected"
					set protected 1
				} else {
					set plugins(${plugin}_updated_main) 1
					set updated 1
				}
				
			} else {
				set plugins(${plugin}_updated_main) 0
			}
				

			# Check each language file

			set plugins(${plugin}_updated_langs) ""
			
			foreach lang_online [getInfo $plugin lang_online] {

				set langcode_online [lindex $lang_online 0]
				set version_online [lindex $lang_online 1]

				if { [::lang::LangExists $langcode_online] } {
					
					foreach lang [getInfo $plugin lang] {
						set langcode [lindex $lang 0]
						set version [lindex $lang 1]
						if { $langcode == $langcode_online } {
							break
						}
					}

					# If $version doesn't exist or if the langcode is different, it means it's a new language
					# that wasn't in the currently installed version. So it needs to be updated.
					if { ![info exists version] || 
					     $langcode != $langcode_online ||
					     [::plugins::DetectNew $version $version_online] } {
					
						set file [file join $path "lang" lang$langcode_online]
						
						if { [file exists $file] && ![file writable $file] } {
							status_log "File $file is protected"
							set protected 1
						} else {
							lappend plugins(${plugin}_updated_langs) [list $langcode_online $version_online] 
							set plugins(${plugin}_updated_lang) 1
							set updated 1
						}
						
					}
				}
			}


			# Check each other file

			set plugins(${plugin}_updated_files) ""
			
			foreach file_online [getInfo $plugin file_online] {

				set pathfile_online [lindex $file_online 0]
				set version_online [lindex $file_online 1]

				foreach file [getInfo $plugin file] {
					set pathfile [lindex $file 0]
					set version [lindex $file 1]
					if { $pathfile == $pathfile_online } {
						break
					}
				}

				# If $version doesn't exist or if the pathfile is different, it means it's a new file
				# that wasn't in the currently installed version. So it needs to be updated.
				if { ![info exists version] || 
				     $pathfile != $pathfile_online ||
				     [::plugins::DetectNew $version $version_online] } {
					set file [file join $path $pathfile_online]
					if { [file exists $file] && ![file writable $file] } {
						status_log "File $file is protected"
						set protected 1
					} else {
						lappend plugins(${plugin}_updated_files) [list $pathfile_online $version_online]
						set plugins(${plugin}_updated_file) 1
						set updated 1
					}
				}
			}

			# If the plugin has been updated and no file is protected, add it to the updated plugin list
			if { $updated == 1 && $protected == 0 } {
				set plugins(${plugin}_updated) 1
				set updatedplugins 1
			} elseif { $updated == 1 } {
				set plugins(${plugin}_updated) 0	
				status_log "Can't update $plugin : files protected\n" red
			} else {
				set plugins(${plugin}_updated) 0
			}
			
		}

		return $updatedplugins

	}


	###############################################################
	# DetectNew (version onlineversion)
	#
	# Tell if the onlineversion is upper the version
	#
	# Arguments
	# The version and the onlineversion
	#
	# Return
	# 1 if onlineversion > version, 0 else
	#
	proc DetectNew { version onlineversion } {

		set current [split $version "."]
		set new [split $onlineversion "."]
		if { $version == "" || $onlineversion == ""} {
			return 0
		} elseif { [lindex $new 0] > [lindex $current 0] } {
			return 1
		} elseif { [lindex $new 0] == [lindex $current 0] && [lindex $new 1] > [lindex $current 1] } {
			return 1
		} else {
			return 0
		}

	}


	###############################################################
	# SavePlugininfo (plugin)
	#
	# Save the plugininfo.xml file of a plugin
	#
	# Arguments
	# The name of the plugin
	#
	# Return
	# none
	#
	proc SavePlugininfo { plugin } {

		global HOME2
		
		set file "[file join $HOME2 $plugin.xml]"
		set pathplugininfo [file join [getInfo $plugin plugin_dir] plugininfo.xml]

		if { [file exists $file] } {
			file copy -force $file $pathplugininfo
			file delete $file
		} else {
			status_log "Error while updating $plugin : can't find plugininfo.xml\n"
		}

	}



	###############################################################
	# getOnlinePluginsList ()
	#
	# Get the list of the plugins which are online
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	proc getOnlinePluginsList { } {

		global HOME2

		set token [::http::geturl "${::weburl}/autoupdater/pluginslist.xml" -timeout 120000 -binary 1]

		set status [::http::status $token]
		if { $status != "ok" } {
			::http::cleanup $token
			return 0
		}

		set content [::http::data $token]

		set filename [file join $HOME2 "pluginslist.xml"]
		set fid [open $filename w]
		fconfigure $fid -encoding binary
		puts -nonewline $fid "$content"
		close $fid
		::http::cleanup $token
	}


	###############################################################
	# OnlinePluginGui ()
	#
	# Display the plugins which are online
	#
	# Arguments
	# none
	#
	# Return
	# none
	#
	# NOT YET FINISHED
	#
	proc OnlinePluginGui { } {

		set w .onlinepluginlist

		if { [winfo exists $w] } {
			raise $w
			return
		}

		::plugins::getOnlinePluginsList

		toplevel $w
		wm title $w [trans getonlineplugins]
		wm geometry $w 500x400

	}


}

