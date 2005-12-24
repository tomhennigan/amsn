namespace eval ::desktop_integration {
	variable current_desktop "noone"
	variable dlg_blocked 0
	variable plugin_name "Desktop Integration"

	variable users_filemanager ""
	variable users_openfilecommand ""
	variable loaded 0


	variable renamed_choosefiledialog_proc desktop_integration_chooseFileDialog
	variable renamed_getsavefile_proc desktop_integration_getSaveFile
	variable renamed_messagebox_proc desktop_integraton_messageBox


	#################################################################
	#     Installing the plugin -> renames old procs to new ones    #
	#################################################################

	proc Init { dir } {
		variable current_desktop
		variable dlg_blocked
		variable plugin_name 
		variable users_filemanager
		variable users_openfilecommand
		variable loaded 

		variable renamed_choosefiledialog_proc
		variable renamed_getsavefile_proc
		variable renamed_messagebox_proc


		if { $loaded == 1 } {
			return 0
		}

		::plugins::RegisterPlugin $plugin_name
		
		# Decide if we are using KDE or GNOME
		set current_desktop [WhichDesktop]
		
		# If no program is installed, the plugin cannot work
		if {$current_desktop == "noone"} {
			# Show info: the plugin cannot be installed
			plugins_log $plugin_name "User has neither kdialog nor zenity installed. Cannot use the plugin"
			msg_box "Sorry, you have neither \'kdialog\' nor \'zenity\' installed. Please, install one of them in order to use this plugin."
			# Unload the plugin
			::plugins::GUI_Unload
			# End this Init proc
			return 0
		} else { 		
			plugins_log $plugin_name "Switching to [string toupper $current_desktop] dialogs"
		}


		set users_filemanager [::config::getKey filemanager]
		set users_openfilecommand [::config::getKey openfilecommand]

		# Set default desktop-dependant filemanager and open file command
		if {$current_desktop == "kde"}	{
			plugins_log "Desktop Integration" "Setting filemanager and openfilecommand for KDE"
			::config::setKey filemanager "kfmclient openURL \$location"
			::config::setKey openfilecommand "kfmclient exec \$file"


			# Set the POS_Y property depending on the Panel Position and size
			# Inside a catch to avoid bad behaviour calling external procs
			catch {
				# Check panel's position -> must be in the bottom
				if {[exec dcop kicker Panel panelPosition] == 3 } {
					# Set the notify Y-offset above the panel
					::config::setKey notifyYoffset [expr {"[exec dcop kicker Panel panelSize]" +1 }]
				}
			}
		} elseif {$current_desktop == "gnome"}	{
			plugins_log "Desktop Integration" "Setting filemanager and openfilecommand for GNOME\n"
			::config::setKey filemanager "nautilus \$location"
			::config::setKey openfilecommand "gnome-open \$file"
		}
		
		
		# CHANGE: ::chooseFileDialog -> KchooseFileDialog
		if { [info proc "::chooseFileDialog"] == "::chooseFileDialog"} {
			rename ::chooseFileDialog $renamed_choosefiledialog_proc	
			proc ::chooseFileDialog {args } {
				return [eval ::desktop_integration::KchooseFileDialog $args]
			}
		}
		
		# CHANGE: ::tk_getSaveFile -> KgetSaveFile
		if { [info proc "::tk_getSaveFile"] == "::tk_getSaveFile"} {
			rename ::tk_getSaveFile $renamed_getsavefile_proc
			proc ::tk_getSaveFile  {args } {
				return [eval ::desktop_integration::KgetSaveFile $args]
			}
		}
		
		# CHANGE: ::amsn::messageBox -> KmessageBox
		if { [info proc "::amsn::messageBox"] == "::amsn::messageBox"} {
			rename ::amsn::messageBox $renamed_messagebox_proc
			proc ::amsn::messageBox  {args } {
				return [eval ::desktop_integration::KmessageBox $args]
			}
		}

		# Initialize the blocking variable if it's not yet set
		if { ![info exists dlg_blocked] } {
			set dlg_blocked 0
		}

		set loaded 1
		return 1
	}

	#################################################################
	#     Uninstalling the plugin -> restores original dialogs      #
	#################################################################
	proc DeInit { } {
		variable current_desktop
		variable plugin_name 
		variable users_filemanager
		variable users_openfilecommand
		variable loaded 

		variable renamed_choosefiledialog_proc
		variable renamed_getsavefile_proc
		variable renamed_messagebox_proc

		if {$loaded == 0} { 
			return 0 
		}

		plugins_log $plugin_name  "Restoring original TCL/TK dialogs\n"
			

		::config::setKey filemanager $users_filemanager
		::config::setKey openfilecommand $users_openfilecommand


		# restoring chooseFileDialog (open file)
		if { [info proc "$renamed_choosefiledialog_proc"] == "$renamed_choosefiledialog_proc"} {
			rename ::chooseFileDialog ""		
			rename $renamed_choosefiledialog_proc ::chooseFileDialog 
		}

		# restoring SaveAs dialog
		if { [info proc "$renamed_getsavefile_proc"] == "$renamed_getsavefile_proc"} {
			rename ::tk_getSaveFile ""
			rename  $renamed_getsavefile_proc ::tk_getSaveFile
		}

		# restoring MsgBoxes
		if { [info proc "$renamed_messagebox_proc"] == "$renamed_messagebox_proc"} {
			rename ::amsn::messageBox ""		
			rename $renamed_messagebox_proc ::amsn::messageBox 
		}
				
	}

	#######################################################################
	#   It says which desktop are we using, and so, what program          #
	#	KDE -> kdialog                                                #
	#	GNOME -> zenity                                               #
	#######################################################################
	proc WhichDesktop {} {
		variable plugin_name 
		global env

		plugins_log $plugin_name "Guessing Desktop\n"

		# Find zenity and kdialog
		catch {exec which zenity} zenity_path
		catch {exec which kdialog} kdialog_path

 		#See which one of the programs do we have
		set has_zenity [file executable $zenity_path ]
		set has_kdialog [file executable $kdialog_path ]

		#If we only have one of them, we choose it
		if {$has_zenity && !$has_kdialog} {
			plugins_log $plugin_name "Found only zenity\n"
			return "gnome"
		} elseif {!$has_zenity && $has_kdialog} {
			plugins_log $plugin_name "Found only kdialog\n"
			return "kde"
		} elseif {!$has_zenity && !$has_kdialog} {
			# If no program is installed, we return 'noone'
			plugins_log $plugin_name "Found neither zenity nor kdialog\n"
			return "noone"
		}
		
		# If both of them are installed, we guess the desktop
		plugins_log $plugin_name "Found both zenity and kdialog\n"
		# First, see if environment var exists
		if  { [info exists env(DESKTOP_SESSION)] } {
			set session_var $env(DESKTOP_SESSION)
			plugins_log $plugin_name "Variable DESKTOP_SESSION is \"$session_var\"\n"

			if {$session_var == "gnome" || $session_var == "kde"} {
				return $session_var
			} elseif {$session_var == "xfce"} {
				# We assume Xfce users like gnome dialogs 
				return "gnome"
			}
		} else {
			plugins_log $plugin_name "Variable DESKTOP_SESSION not present\n"
		}


		# If the variable doesn't help, let's see the number of processes
		if { [catch {exec ps -A | grep gnome | wc -l} n_gnome] } {
			set n_gnome 0
		}

		if { [catch {exec ps -A | grep kde | wc -l} n_kde] } {
			set n_kde 0
		}
		
		plugins_log $plugin_name "Found $n_gnome \"gnome\" processes vs. $n_kde \"kde\" ones.\n"

		if {$n_gnome > $n_kde} { 
			return "gnome"
		} else {
			return "kde"
		}
	}


	#########################################################
	#     New procedures that call kdialog are below        #
	#########################################################

	#### File Open Dialog ###################################

	proc KchooseFileDialog {{initialfile ""} {title ""} {parent ""} {entry ""} {operation "open"} {tktypes ""}}  {
		global starting_dir
		variable plugin_name
		variable current_desktop

		if { ![file isdirectory $starting_dir] } {
			set starting_dir [pwd]
		}
		
		plugins_log $plugin_name "aMSN called chooseFileDialog with operation=\'$operation\', types=\'$tktypes\'\n"

		set selfile ""
	
		set initialfile "$starting_dir/$initialfile"
		if { $tktypes == ""} {
			set filetypes ""
		} else {
			set filetypes "*[lindex $tktypes 0 1]|[lindex $tktypes 0 0]"
		}
	
		if { $operation == "open" } {
			if {$current_desktop == "kde"} {
				# KDE - kdialog open file dialog
				plugins_log $plugin_name "Calling kDialog OpenFile with initialfile=\'$initialfile\', filetypes=\'$filetypes\'\n"
				set selfile [::desktop_integration::launch_dialog "kdialog --caption \"$title\" --getopenfilename \"$initialfile\" \"$filetypes\" "]
			
			} else {
				# GNOME - zenity open file dialog
				plugins_log $plugin_name "Calling zenity OpenFile with filename=\'$initialfile\'\n"
				set selfile [::desktop_integration::launch_dialog "zenity --file-selection --filename \"$initialfile\" --title \"$title\""]			
			}

		} else {
			# This is ACTUALLY NOT USED in aMSN but implemented just in case
			if {$current_desktop == "kde"} {
				# KDE - kdialog save file dialog
				plugins_log $plugin_name "Calling kDialog SaveFile with initialfile=\'$initialfile\', filetypes=\'$filetypes\'\n"
				set selfile [::desktop_integration::launch_dialog "kdialog --caption \"$title\" --getsavefilename \"$initialfile\" \"$filetypes\""]				
			
			} else {
				# GNOME - zenity save file dialog
				plugins_log $plugin_name "Calling zenity SaveFile with filename=\'$initialfile\'\n"
				set selfile [::desktop_integration::launch_dialog "zenity --file-selection --save --filename \"$initialfile\" --title \"$title\""]	
			}
		
		}


		# Make sure the cancel button wasn't pressed
		if { $selfile != "" } {
			plugins_log $plugin_name "File to $operation: $selfile\n"
	
			# Remember last directory
			set starting_dir [file dirname $selfile]
			
			if { $entry != "" } {
				$entry delete 0 end
				$entry insert 0 $selfile
				$entry xview end
			}
		} else {
			plugins_log $plugin_name "Cancel button pressed\n"
		}
		
		return $selfile
	}

	#### SaveAs Dialog #######################################
	proc KgetSaveFile  {{args ""}} {
		global starting_dir
		variable current_desktop
		variable plugin_name

		# Remember last directory
		if { ![file isdirectory $starting_dir] } {
			set starting_dir [pwd]
		}
					
		# Extracting info from $args
		plugins_log $plugin_name "Called tk_getSaveFile with args: $args\n"
		
		# Extracting title
		set idx [lsearch $args "-title"]
		if { $idx != -1 } {
			set title [lindex $args [expr {int($idx + 1)}]]
		} else {
			set title ""
		}

		# Extracting initialfile
		set idx [lsearch $args "-initialfile"]
		if { $idx != -1 } {
			set initialfile [lindex $args [expr {int($idx + 1)}]]
		} else {
			set initialfile "."
		}
		if { [file dirname $initialfile] == "." } {
			set initialfile "$starting_dir/$initialfile"
		}
		
		# Extracting filetypes (first one)
		set idx [lsearch $args "-filetypes"]
		if { $idx != -1 } {
			set filetypes "*[lindex $args [expr {int($idx + 1)}] 0 1]" 		
			set filetypes "$filetypes|[lindex $args [expr {int($idx + 1)}] 0 0]"	
		} else {
			set filetypes " "
		}			


		if {$current_desktop == "kde"} {
			# KDE - kdialog save file dialog
			plugins_log $plugin_name "Calling kDialog SaveFile with initialfile=\'$initialfile\', filetypes=\'$filetypes\'\n"
			set selfile [::desktop_integration::launch_dialog "kdialog --caption \"$title\" --getsavefilename \"$initialfile\" \"$filetypes\""]

		} else {
			# GNOME - zenity save file dialog
			plugins_log $plugin_name "Calling zenity SaveFile with filename=\'$initialfile\'\n"
			set selfile [::desktop_integration::launch_dialog "zenity --file-selection --save --filename \"$initialfile\" --title \"$title\""]
		}
		
		# If a file is selected
		if { $selfile != "" } {
			plugins_log $plugin_name "File to save: $selfile\n"			
			# Remember last directory
			set starting_dir [file dirname $selfile]
		}
		
		return $selfile
	}	

	#### Message Box dialog: info boxes, error boxes and yes-no questions  #####
	proc KmessageBox { {message "" } {type "ok"} {icon ""} {title ""} {parent ""}} {
		variable current_desktop
		variable plugin_name

		
		plugins_log $plugin_name "aMSN called messageBox {type=\'$type\', icon=\'$icon\'}"	

		switch $type {
			
			"ok" {
				switch $icon {
					"info"	{set ktype "msgbox"}
					"error"   {set ktype "error"}
					default   {set ktype "msgbox"}
				}
				if {$current_desktop == "kde"} {
					plugins_log $plugin_name "Calling \'kdialog --$ktype\'"	
					catch {exec kdialog --$ktype \"$message\" --caption \"$title\" &} answer
				} else {
					if { $ktype == "msgbox" } { set ktype "info" }
					plugins_log $plugin_name "Calling \'zenity --$ktype\'"	
					catch {exec zenity --$ktype --text $message --title $title &} answer
				}
			}
			
			"yesno" {
				if {$current_desktop == "kde"} {
					# KDE yes-no dialog
					plugins_log $plugin_name "Calling \'kdialog --yesno\'"
					set answer [::desktop_integration::launch_question "kdialog --yesno \"$message\" --caption \"$title\""]
				} else {
					# GNOME yes-no dialog
					plugins_log $plugin_name "Calling \'zenity --question\'"
					set answer [::desktop_integration::launch_question "zenity --question --text \"$message\" --title \"$title\""]
				}
				plugins_log $plugin_name "Answer=\'$answer\'"
			}

			default {
				plugins_log $plugin_name "kDialog or zenity type not matching tk one ($type) -> default dialog"
				if { $parent == ""} {
					set parent [focus]
					if { $parent == ""} { set parent "."}
				}
				set answer [tk_messageBox -message "$message" -type $type -icon $icon -title $title -parent $parent]
			}
		}

		return $answer

	}


	#########################################################
	#     Procs to exec dialogs w/o freezing amsn           #
	#########################################################

	##### This proc launch a dialog in a non-blocking way, and returns the file the user selects ####
	proc launch_dialog { execline } {
		variable dlg_blocked
		variable plugin_name

		# At the moment, we must prevent users from opening two or more dialogs at a time
		# Needs to be improved	
		if {$dlg_blocked} {
			plugins_log $plugin_name "Another dialog is open."	
			return ""
		} else {
			set dlg_blocked 1
		}

		set fileId [open "|${execline} 2>/dev/null" r] 
		
		fileevent $fileId readable "::desktop_integration::dialog_event $fileId"
		
		tkwait variable ::desktop_integration::answer
		set dlg_blocked 0
		return $::desktop_integration::answer
	}

	##### This proc launch a yes-no dialog in a non-blocking way, and returns "yes" or "no" ####
	proc launch_question { execline } {
		variable dlg_blocked
		variable plugin_name


		# At the moment, we must prevent users from opening two or more dialogs at a time
		# Needs to be improved			
		if {$dlg_blocked} {
			plugins_log $plugin_name "Another dialog is open."	
			return "no"
		} else {
			set dlg_blocked 1
		}


		set fileId [open "|${execline}" r]					
		fileevent $fileId readable "::desktop_integration::question_event $fileId"

		tkwait variable ::desktop_integration::answer

		set dlg_blocked 0
		return $::desktop_integration::answer
	}

	proc dialog_event { fileId } {
		fileevent $fileId readable ""
		set temp ""
		if { [gets $fileId line] < 0 } {
			if [catch {close $fileId}] {
				#If the user pressed Cancel we get here
				set ::desktop_integration::answer ""
			} else {
				set ::desktop_integration::answer $temp
			}
		} else {
			append temp $line
		}
	} 

	proc question_event { fileId } {
		if [catch {close $fileId}] {
			set ::desktop_integration::answer "no"
		} else {
			set ::desktop_integration::answer "yes"
		}
	}
}

