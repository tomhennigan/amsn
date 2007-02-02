#
#		Address Book
#		Integrates aMSN with the Mac OS X address book.
#		Author: Tom Hennigan
#		Version: 0.1
#

namespace eval ::macabook {
	proc init { dir } {
		# Register the plugin.
		::plugins::RegisterPlugin "Address Book"

		# Store the plugin's path
		set ::macabook::config(path) $dir
		
		# Set our state to 1 (AddressBook names override Custom & Nick names).
		set ::macabook::config(state) 1
		
		# Bind our key stroke (Command-Shift-a) to switch the state of names in the CL.
		bind all <Command-A> "::macabook::switchState"
		
		# Load a list of all people with MSN handles
		set error1 [catch { set ::macabook::config(usableaddresses) [exec osascript [file join $dir addressbook.applescript] returnAllMSNAddresses] }]
		
		# Cache nicks.
		set error2 [catch { set ::macabook::config(cachednicks) [exec osascript [file join $dir addressbook.applescript] returnAllCustomNicks] }]
		
		# Quit Address Book
		set error3 [catch { exec killall Address\ Book }]
			
		# Check for errors.
		if { $error1 || $error2 || $error3 } {
			status_log "Error with osascript command. The log from the first command is: \"$error1\".\nThe second log is: \"$error2\".\nThe third log is: \"$error3\"." red
		}
		
		# Register for our post event.
		::plugins::RegisterEvent "Address Book" getDisplayNick parse_nick
	}

	# The abook deinit proc.
	proc deinit { } {
		unset ::macabook::config(usableaddresses)
		unset ::macabook::config(cachednicks)
		# Unbind our key-stroke.
		bind all <Command-A> ""
		test
	}

	# This is called when the post event occurs.
	proc parse_nick {event epvar} {
		if {$::macabook::config(state)} {
			# Get the pointer to the variables from the proc, so we can send feedback.
			upvar 2 user_login user_login customnick customnick
			
			# If the user has an address book entry, then lets go ahead and set their name.
			if {[::macabook::checkLogin $user_login]} {
	    		# Lookup the person's name in the abook.
				set customnick [::macabook::getABookName $user_login]
			}
		}
		return 1
	}
	
	proc checkLogin { user_login } {
		if {[lsearch $::macabook::config(usableaddresses) $user_login] != "-1"} {
			return 1
		} else {
			return 0
		}
	}
	
	proc getABookName { user_login } {
		# Return the users name from address book.
		return [lindex $::macabook::config(cachednicks) [lsearch $::macabook::config(usableaddresses) $user_login]]
	}
	
	proc switchState { } {
		# A logic switch to change between Address Book Mode and aMSN Mode.
		if {$::macabook::config(state)} {
			set ::macabook::config(state) 0
		} else {
			set ::macabook::config(state) 1
		}
		# Locate the correct proc to do this..
		#::guiContactList::updateCL
		cmsn_draw_online
	}
}
