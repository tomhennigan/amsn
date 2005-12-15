namespace eval ::desktop_integration {
	variable current_desktop "kde"

	#################################################################
	#     Installing the plugin -> renames old procs to new ones    #
	#################################################################

	proc Init { dir } {
		global current_desktop
		global dlg_blocked
		#global dlgNum

		::plugins::RegisterPlugin "Desktop Integration"
		
		#Decide if we are using KDE or GNOME
		set current_desktop [WhichDesktop]
		#set current_desktop "gnome"
		#set current_desktop "kde"
		
		#If no program is installed, the plugin cannot work
		if {$current_desktop == "noone"} {
			#Show info: the plugin cannot be installed
			plugins_log "Desktop Integration" "User has neither kdialog nor zenity installed. Cannot use the plugin"
			msg_box "Sorry, you have neither \'kdialog\' nor \'zenity\' installed. Please, install one of them in order to use this plugin."
			#Unload the plugin
			::plugins::GUI_Unload
			#End this Init proc
			return 0
		} else { 		
			plugins_log "Desktop Integration" "Switching to [string toupper $current_desktop] dialogs\n"
		}

		#Set default prefs for filemanager and open file command
		#THEY WILL OVERWRITE USER PREFS!!
		if {$current_desktop == "kde"}	{
			plugins_log "Desktop Integration" "Setting filemanager and openfilecommand for KDE\n"
			::config::setKey filemanager "kfmclient openURL \$location"
			::config::setKey openfilecommand "kfmclient exec \$file"
			#Set the POS_Y property depending on the Panel Position and size
			#Inside a catch to avoid bad behaviour calling external procs
			catch {
				#See if panel is on bottom
				if {[exec dcop kicker Panel panelPosition] == 3 } {
					#Setting notify Y-offset avobe the panel
					::config::setKey notifyYoffset [expr {"[exec dcop kicker Panel panelSize]" +1 }]
				}
			}
		} elseif {$current_desktop == "gnome"}	{
			plugins_log "Desktop Integration" "Setting filemanager and openfilecommand for GNOME\n"
			::config::setKey filemanager "nautilus \$location"
			::config::setKey openfilecommand "gnome-open \$file"
		}
		
		
		# CHANGE: ::chooseFileDialog -> KchooseFileDialog
		rename ::chooseFileDialog old_chooseFileDialog		
		rename KchooseFileDialog ::chooseFileDialog 
		
		# CHANGE: ::tk_getSaveFile -> KgetSaveFile
		rename ::tk_getSaveFile old_getSaveFile
		rename KgetSaveFile ::tk_getSaveFile 
						
		# CHANGE: ::amsn::messageBox -> KmessageBox
		rename ::amsn::messageBox old_messageBox		
		rename KmessageBox ::amsn::messageBox

		#Starts a blocking variable if it's not yet setted
		if [catch { string toupper $dlg_blocked }] {
			set dlg_blocked 0
		}
	}

	#################################################################
	#     Uninstalling the plugin -> restores original dialogs      #
	#################################################################
	proc DeInit { } {
		global current_desktop
	
		if {$current_desktop == "noone"} {return 0}

		plugins_log "Desktop Integration" "Restoring original TCL/TK dialogs\n"
			
		#restoring chooseFileDialog (open file)
		rename ::chooseFileDialog KchooseFileDialog		
		rename old_chooseFileDialog ::chooseFileDialog 
		
		#restoring SaveAs dialog
		rename ::tk_getSaveFile KgetSaveFile
		rename  old_getSaveFile ::tk_getSaveFile

		#restoring MsgBoxes
		rename ::amsn::messageBox KmessageBox 		
		rename old_messageBox ::amsn::messageBox 
				
	}

	#######################################################################
	#   It says which desktop are we using, and so, what program          #
	#	KDE -> kdialog                                                #
	#	GNOME -> zenity                                               #
	#######################################################################
	proc WhichDesktop {} {
		global env

		plugins_log "Desktop Integration" "Guessing Desktop\n"

		# Find zenity and kdialog
		catch {exec which zenity} zenity_path
		catch {exec which kdialog} kdialog_path

 		#See which one of the programs do we have
		set has_zenity [file executable $zenity_path ]
		set has_kdialog [file executable $kdialog_path ]

		#If we only have one of them, we choose it
		if {$has_zenity && !$has_kdialog} {
			plugins_log "Desktop Integration" "Found only zenity\n"
			return "gnome"
		} elseif {!$has_zenity && $has_kdialog} {
			plugins_log "Desktop Integration" "Found only kdialog\n"
			return "kde"
		} elseif {!$has_zenity && !$has_kdialog} {
			#If no program is installed
			plugins_log "Desktop Integration" "Found neither zenity nor kdialog\n"
			return "noone"
		}
		
		#If both of them are installed, we guess the desktop
		plugins_log "Desktop Integration" "Found both zenity and kdialog\n"
		#First, see if environment var exists
		if [catch {set session_var $env(DESKTOP_SESSION)}] {
			plugins_log "Desktop Integration" "Variable DESKTOP_SESSION not present\n"
		} else {
			plugins_log "Desktop Integration" "Variable DESKTOP_SESSION is \"$session_var\"\n"
			if {$session_var == "gnome" || $session_var == "kde"} {
				return $session_var
			} elseif {$session_var == "xfce"} {
				#Xfce users like gnome dialogs?? 
				return "gnome"
			}
		}

		#If the variable doesn't help, let's see the number of processes
		if [catch {exec ps -A | grep gnome | wc -l} n_gnome] {
			set n_gnome 0
		}
		if [catch {exec ps -A | grep kde | wc -l} n_kde] {
			set n_kde 0
		}
		
		plugins_log "Desktop Integration" "Found $n_gnome \"gnome\" processes vs. $n_kde \"kde\" ones.\n"
		
		if {$n_gnome >= $n_kde} { 
			return "gnome"
		} else {
			return "kde"
		}
	}


	#########################################################
	#     New procedures that call kdialog are below        #
	#########################################################

	#### File Open Dialog ###################################
	set arglist [list {initialfile ""} {title ""} {parent ""} {entry ""} {operation "open"} {tktypes ""} ]
	
	proc KchooseFileDialog "$arglist" {
		global starting_dir
		global current_desktop
		global selfile

		if { ![file isdirectory $starting_dir] } {
			set starting_dir [pwd]
		}
		
		plugins_log "Desktop Integration" "aMSN called chooseFileDialog with operation=\'$operation\', types=\'$tktypes\'\n"
	
		set initialfile "$starting_dir/$initialfile"
		if { $tktypes == ""} {
			set filetypes ""
		} else {
			set filetypes "*[lindex $tktypes 0 1]|[lindex $tktypes 0 0]"
		}
	
		if { $operation == "open" } {
		
			if {$current_desktop == "kde"} {
				#KDE - kdialog open file dialog
				plugins_log "Desktop Integration" "Calling kDialog OpenFile with initialfile=\'$initialfile\', filetypes=\'$filetypes\'\n"
				set selfile [::desktop_integration::launch_dialog "kdialog --caption \"$title\" --getopenfilename \"$initialfile\" \"$filetypes\" "]
			
			} else {
				#GNOME - zenity open file dialog
				plugins_log "Desktop Integration" "Calling zenity OpenFile with filename=\'$initialfile\'\n"
				set selfile [::desktop_integration::launch_dialog "zenity --file-selection --filename \"$initialfile\" --title \"$title\""]			
			}

		#This is ACTUALLY NOT USED in aMSN but implemented just in case
		} else {
			
			if {$current_desktop == "kde"} {
				#KDE - kdialog save file dialog
				plugins_log "Desktop Integration" "Calling kDialog SaveFile with initialfile=\'$initialfile\', filetypes=\'$filetypes\'\n"
				set selfile [::desktop_integration::launch_dialog "kdialog --caption \"$title\" --getsavefilename \"$initialfile\" \"$filetypes\""]				
			
			} else {
				#GNOME - zenity save file dialog
				plugins_log "Desktop Integration" "Calling zenity SaveFile with filename=\'$initialfile\'\n"
				set selfile [::desktop_integration::launch_dialog "zenity --file-selection --save --filename \"$initialfile\" --title \"$title\""]	
			}
		
		}


		#If a file is selected (no Cancel button)
		if { $selfile != "" } {
			plugins_log "Desktop Integration" "File to $operation: $selfile\n"	
			#Remember last directory
			set starting_dir [file dirname $selfile]
			
			if { $entry != "" } {
				$entry delete 0 end
				$entry insert 0 $selfile
				$entry xview end
			}
		} else {
			plugins_log "Desktop Integration" "Cancel button pressed\n"
		}
		
		return $selfile
	}

	#### SaveAs Dialog #######################################
	proc KgetSaveFile  [list {args ""}] {
		global starting_dir
		global current_desktop

		#Remember last directory
		if { ![file isdirectory $starting_dir] } {
			set starting_dir [pwd]
		}
					
		#Extracting info from $args
		plugins_log "Desktop Integration" "Called tk_getSaveFile with args: $args\n"
		
		#Extracting title
		set idx [lsearch $args "-title"]
		if { $idx != -1 } {
			set title [lindex $args [expr {int($idx + 1)}]]
		} else {
			set title ""
		}

		#Extracting initialfile
		set idx [lsearch $args "-initialfile"]
		if { $idx != -1 } {
			set initialfile [lindex $args [expr {int($idx + 1)}]]
		} else {
			set initialfile "."
		}
		if { [file dirname $initialfile] == "." } {
			set initialfile "$starting_dir/$initialfile"
		}
		
		#Extracting filetypes (first one)
		set idx [lsearch $args "-filetypes"]
		if { $idx != -1 } {
			set filetypes "*[lindex $args [expr {int($idx + 1)}] 0 1]" 		
			set filetypes "$filetypes|[lindex $args [expr {int($idx + 1)}] 0 0]"	
		} else {
			set filetypes " "
		}			


		if {$current_desktop == "kde"} {
			#KDE - kdialog save file dialog
			plugins_log "Desktop Integration" "Calling kDialog SaveFile with initialfile=\'$initialfile\', filetypes=\'$filetypes\'\n"
			set selfile [::desktop_integration::launch_dialog "kdialog --caption \"$title\" --getsavefilename \"$initialfile\" \"$filetypes\""]

		} else {
			#GNOME - zenity save file dialog
			plugins_log "Desktop Integration" "Calling zenity SaveFile with filename=\'$initialfile\'\n"
			set selfile [::desktop_integration::launch_dialog "zenity --file-selection --save --filename \"$initialfile\" --title \"$title\""]
		}
		
		#If a file is selected
		if { $selfile != "" } {
			plugins_log "Desktop Integration" "File to save: $selfile\n"			
			#Remember last directory
			set starting_dir [file dirname $selfile]
		}
		
		return $selfile
	}	

	#### Message Box dialog: info boxes, error boxes and yes-no questions  #####
	proc KmessageBox [list {message "" } {type "ok"} {icon ""} {title ""} {parent ""}] {
		global current_desktop

		plugins_log "Desktop Integration" "aMSN called messageBox {type=\'$type\', icon=\'$icon\'}"	

		switch $type {
			
			"ok" {
				switch $icon {
					"info"	{set ktype "msgbox"}
					"error"   {set ktype "error"}
					default   {set ktype "msgbox"}
				}
				if {$current_desktop == "kde"} {
					plugins_log "Desktop Integration" "Calling \'kdialog --$ktype\'"	
					catch {exec kdialog --$ktype \"$message\" --caption \"$title\" &} answer
				} else {
					if { $ktype == "msgbox" } { set ktype "info" }
					plugins_log "Desktop Integration" "Calling \'zenity --$ktype\'"	
					catch {exec zenity --$ktype --$ktype-text=\"$message\" --title \"$title\" &} answer
				}
			}
			
			"yesno" {
				if {$current_desktop == "kde"} {
					#KDE yes-no dialog
					plugins_log "Desktop Integration" "Calling \'kdialog --yesno\'"
					set answer [::desktop_integration::launch_question "kdialog --yesno \"$message\" --caption \"$title\""]
				} else {
					#GNOME yes-no dialog
					plugins_log "Desktop Integration" "Calling \'zenity --question\'"
					set answer [::desktop_integration::launch_question "zenity --question --question-text \"$message\" --title \"$title\""]
				}
				plugins_log "Desktop Integration" "Answer=\'$answer\'"
			}

			default {
				plugins_log "Desktop Integration" "kDialog or zenity type not matching tk one ($type) -> default dialog"
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
		#global dlgNum
		#incr dlgNum
		global dlg_blocked

		global fileId
		global answer		

#		plugins_log "Desktop Integration" "Executing {$execline}"	
	
		if {$dlg_blocked} {
			plugins_log "Desktop Integration" "Another dialog is open."	
			return ""
		} else {
			set dlg_blocked 1
		}

		set fileId [open "|${execline} 2>/dev/null" r] 
		
		fileevent $fileId readable {
			if { [gets $fileId line] < 0 } {
				if [catch {close $fileId}] {
					#If the user pressed Cancel we get here
					set answer ""
					unset -nocomplain fileId 
				} else {
					set answer $temp
					unset -nocomplain fileId temp
				}
			} else {
				append temp $line
			}
		} 
		
		tkwait variable answer
		set dlg_blocked 0
		return $answer
	}

	##### This proc launch a yes-no dialog in a non-blocking way, and returns "yes" or "no" ####
	proc launch_question { execline } {
		#global dlgNum
		#incr dlgNum
		global dlg_blocked

		global fileId
		global answer
		
#		plugins_log "Desktop Integration" "Executing {$execline}"	

		#At the moment, we must prevent users from opening two or more dialogs at a time
		#Needs to be improved			
		if {$dlg_blocked} {
			plugins_log "Desktop Integration" "Another dialog is open."	
			return "no"
		} else {
			set dlg_blocked 1
		}


		set fileId [open "|${execline}" r]					
		fileevent $fileId readable {
			if [catch {close $fileId}] {
				set answer "no"
			} else {
				set answer "yes"
			}
			unset -nocomplain fileId
		} 
		
		tkwait variable answer
		set dlg_blocked 0
		return $answer
	}

}
