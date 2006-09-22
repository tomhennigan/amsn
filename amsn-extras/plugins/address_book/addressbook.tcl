#
#		Address Book
#		Integrates aMSN with the Mac OS X address book.
#		Author: Tom Hennigan
#		Version: 0.1
#

namespace eval ::macabook {
	proc macabookInit { dir } {
		# Register the plugin.
		::plugins::RegisterPlugin "Address Book"

		# Store the plugin's path
		::config::setKey macabookpluginpath $dir
		
		# Set our state to 1 (AddressBook names override Custom & Nick names).
		::config::setKey macabookstate 1
		
		# Bind our key stroke (Command-Shift-a) to switch the state of names in the CL.
		bind all <Command-A> "::macabook::switchState"
		
		# Load a list of all people with MSN handles
		::config::setKey macabookusableaddresses [exec osascript [file join $dir addressbook.applescript] returnAllMSNAddresses]
		
		# Cache nicks.
		::config::setKey macabookcachednicks [exec osascript [file join $dir addressbook.applescript] returnAllCustomNicks]
		
		# Quit Address Book
		exec killall Address\ Book
		
		# Register for our post event.
		::plugins::RegisterEvent "Address Book" getDisplayNick parse_nick
	}

	# The abook deinit proc.
	proc macabookDeInit { } {
		# Get rid of all our saved data.
		::macabook::unSetVars
		
		# Unbind our key-stroke.
		bind all <Command-A> ""
	}

	# This is called when the post event occurs.
	proc parse_nick {event epvar} {
		if {[::config::getKey macabookstate]} {
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
		if {[lsearch [::config::getKey macabookusableaddresses] $user_login] != "-1"} {
			return 1
		} else {
			return 0
		}
	}
	
	proc getABookName { user_login } {
		# Return the users name from address book.
		return [lindex [::config::getKey macabookcachednicks] [lsearch [::config::getKey macabookusableaddresses] $user_login]]
	}
	
	proc switchState { } {
		# A logic switch to change between Address Book Mode and aMSN Mode.
		if {[::config::getKey macabookstate]} {
			::config::setKey macabookstate 0
		} else {
			::config::setKey macabookstate 1
		}
		cmsn_draw_online
	}
	
	proc unSetVars { } {
		::config::unsetKey macabookdebug
		::config::unsetKey macabookpluginpath
		::config::unsetKey macabookusableaddresses
		::config::unsetKey macabookcachednicks
		::config::unsetKey macabookstate
		return 1
	}
}
