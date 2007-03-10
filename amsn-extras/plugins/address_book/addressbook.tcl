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

		global array set ::macabook {element value}
		
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
		::plugins::RegisterEvent "Address Book" getDisplayNick parse_nick
	}

	# The abook deinit proc.
	proc deinit { } {
		;
	}

	# This is called when the post event occurs.
	proc parse_nick {event epvar} {
		upvar 2 user_login user_login customnick customnick
		
		set user_id [addressbook search -persons -ids MSNInstant == [list {} $user_login]]
		if {$user_id == [list]} {
			set user_id [addressbook search -persons -ids Email == [list {} $user_login]]
		}
		
		if {$user_id == [list]} { return; }
		
		set record [addressbook record [lindex $user_id 0]]
		set first ""
		set last ""
		catch { set first [keylget record First] }
		catch { set last [keylget record Last] }
		set customnick "$first $last"
	}
}
