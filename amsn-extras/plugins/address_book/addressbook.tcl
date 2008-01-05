#
#		Address Book
#		Integrates aMSN with the Mac OS X address book.
#		Author: Tom Hennigan
#		Version: 1.0
#

namespace eval ::macabook {
	proc init { dir } {
		# Register the plugin.
		::plugins::RegisterPlugin "Address Book"

		# This cache is used to speed things up.
		global array set ::macabook::cache {element value}
		
		# Tclx
		if {[catch {package require Tclx} res]} {
			tk_messageBox -parent .main -title "Warning" -icon warning -type ok -message "The Tclx extension couldn't be loaded. Please make sure that tcl/tx has been installed correctly. Reason: $res"
			return
		}
		
		# addressbook
		if {[catch {load [file join $dir "utils" "addressbook" "addressbook1.1.dylib"] addressbook} res]} {
			tk_messageBox -parent .main -title "Warning" -icon warning -type ok -message "The addressbook extension couldn't be loaded. Please make sure that the plugin has been installed correctly. Reason: $res"
			return
		}
		
		# Init lang...
		set langdir [file join $dir "lang"]
		load_lang en $langdir
		load_lang [::config::getGlobalKey language] $langdir
		
		# Set the config.
		initConfig
		
		# Register for our post event.
		::plugins::RegisterEvent "Address Book" parse_contact parseNick
	}

	# The abook deinit proc.
	proc deinit { } {
		unset ::macabook::cache
		namespace delete ::macabook
	}

	proc initConfig { } {
		array set ::macabook::config {
			stylestring {$first $last: }
    	}

		set ::macabook::configlist [list \
			[list str "[trans macabookstylestring]"  stylestring] \
		]
	}

	proc parseNick {event epvar} {
		upvar 2 $epvar evpar
		upvar 2 $evpar(variable) nickArray
		
		upvar 2 field field
		variable user_login $evpar(login)
		
		if {$field != "nick"} { return; }
		
		if {![info exists ::macabook::cache($user_login)]} {
			set ::macabook::cache($user_login) [getNickFromMSNHandle $user_login]
		}
		
		set name $::macabook::cache($user_login)
		if {$name != [list [list] [list]]} {
			set stylestring $::macabook::config(stylestring)
			set stylestring [string map [list "\$first" [lindex $name 0]] $stylestring]
			set stylestring [string map [list "\$last" [lindex $name 1]] $stylestring]
			
			lprepend nickArray [list "text" $stylestring]
		}
	}

	proc getNickFromMSNHandle {email} {
		set user_id [addressbook search -persons -ids MSNInstant [list ==] [list {} $email]]
		if {$user_id == [list]} {
			set user_id [addressbook search -persons -ids Email [list ==] [list {} $email]]
		}
		
		if {$user_id == [list]} { return [list [list] [list]]; }
			
		set record [addressbook record [lindex $user_id 0]]
		set first [list]
		set last [list]
		catch { set first [keylget record First] }
		catch { set last [keylget record Last] }
		return [list [list $first] [list $last]]
	}
}
