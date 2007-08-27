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
		
		#package require addressbook
		if {[catch {load [file join $dir "utils" "addressbook" "addressbook1.1.dylib"] addressbook} res]} {
			tk_messageBox -parent .main -title "Warning" -icon warning -type ok -message "The addressbook extension couldn't be loaded. Please make sure that the plugin has been installed correctly. Reason: $res"
			return
		}
		
		# Register for our post event.
		::plugins::RegisterEvent "Address Book" parse_contact parse_nick
	}

	# The abook deinit proc.
	proc deinit { } {
		unset ::macabook::cache
	}

	proc parse_nick {event epvar} {
		upvar 2 $epvar evpar
		upvar 2 $evpar(variable) nickArray
		
		upvar 2 field field
		variable user_login $evpar(login)
		
		if {$field != "nick"} { return }
		
		if {![info exists ::macabook::cache($user_login)]} {
			set name [getNickFromMSNHandle $user_login]
			set ::macabook::cache($user_login) "[lindex $name 0] [lindex $name 1]"
		}
		
		if {$::macabook::cache($user_login) != "" && $::macabook::cache($user_login) != " "} {
			# Put this on first so we get:		": $NICK"
			set nickArray [linsert $nickArray 0 [list "text" ": "]]
			# Now the name so we get:			"FIRST LAST: $NICK"
			set nickArray [linsert $nickArray 0 [list "text" $::macabook::cache($user_login)]]
		}
	}

	proc getNickFromMSNHandle {email} {
		set user_id [addressbook search -persons -ids MSNInstant == [list {} $email]]
		if {$user_id == [list]} {
			set user_id [addressbook search -persons -ids Email == [list {} $email]]
		}
		
		if {$user_id == [list]} { return ""; }
			
		set record [addressbook record [lindex $user_id 0]]
		set first ""
		set last ""
		catch { set first [keylget record First] }
		catch { set last [keylget record Last] }
		return [list $first $last]
	}
}
