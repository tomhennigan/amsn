#########################################################################
#  This plugin is meant to be home for some more advanced features that #
#   shouldn't be in aMSN's core or where removed from the core to have  #
#   a cleaner experience for novice users.                              #
#########################################################################


namespace eval ::Powertool {
	###############################################
	# ::Powertool::Init (dir)                     #
	# ------------------------------------------- #
	# Registration & initialization of the plugin #
	###############################################
	proc Init { dir } {
		::plugins::RegisterPlugin Powertool

		#Register the events to the plugin system
		::Powertool::RegisterEvents

#		#Get default value for config
#		::Powertool::config_array

		#Loads language files
		::Powertool::load_Powertool_languages $dir

		#Config to show in configuration window	
		::Powertool::configlist_values
	}
	
	#####################################
	# ::Powertool::RegisterEvents       #
	# --------------------------------- #
	# Register events to plugin system  #
	#####################################
	proc RegisterEvents {} {
		::plugins::RegisterEvent Powertool right_menu clitemmenu
	}
	
	########################################
	# ::Powertool::config_array            #
	# -------------------------------------#
	# Add config array with default values #
	########################################
#	proc config_array {} {
#		array set ::Powertool::config {
#			option {"default value"}
#		}
#	}
	
	########################################
	# ::Powertool::configlist_values       #
	# -------------------------------------#
	# List of items for config window      #
	########################################
#	proc configlist_values {} {
#		set ::Powertool::configlist [list \
#			[list bool "option 1" option] \
#		]
#	}

	########################################
	# ::Powertool::load_Powertool_languages dir
	# -------------------------------------#
	# Load languages files                 #
	########################################
	proc load_Powertool_languages {dir} {
		#Load lang files
		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir
	}



	################################################
	# ::Powertool::clitemmenu event epvar          #
	# -------------------------------------------  #
	# Adds entries to the contactlist-context-menu #
	################################################	
	proc clitemmenu { event evpar } {
		upvar 2 $evpar newvar
		
		#Add it at the first position and add a separator afterwards
		$newvar(menu_name) insert 0 separator
		$newvar(menu_name) insert 0 command -label "[trans copytoclipboard \"$newvar(user_login)\"]" \
	-command "clipboard clear;clipboard append \"$newvar(user_login)\""

	}

}
