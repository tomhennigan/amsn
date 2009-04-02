################################################################
#        ::Invisibility by Anto Cvitic  #
#	 Version 0.5 by Kemal Ilgar Eroglu -- September 2008
#
# This code is released under the GNU Public License Version 3
#  =============================================================
# Invisibility will block contacts  when they go offline
# and unblock them when they change their state to online,
# with the exception of permanently allowed or blocked users.
################################################################


rename ::amsn::blockUser ::amsn::blockUserOrig
rename ::amsn::unblockUser ::amsn::unblockUserOrig
		
namespace eval ::Invisibility {

	proc Init { dir } {
		::plugins::RegisterPlugin "Invisibility"
		plugins_log "Invisibility"  "Registered plugin"

		::plugins::RegisterEvent "Invisibility" ChangeState blockContact
		::plugins::RegisterEvent "Invisibility" OnConnect dummy
		plugins_log "Invisibility"  "Registered events"

		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		#It's important to load the english file and then the current language lang file
		load_lang en $langdir
		load_lang $lang $langdir
		
		array set ::Invisibility::config {
			iblocklist {}
			iallowlist {}
			win {}
			oldbehav {0}
			waitingtime {4000}
			automat {1}
		}

		set ::Invisibility::configlist [list \
			[list frame ::Invisibility::populateFrame ] \
			[list bool [trans old_behav] oldbehav] \
			[list bool [trans otomat] automat] \
			]				

	}

######################################
# The proc that does the (un)blocking
######################################	
	proc blockContact { event evpar } {

		upvar 2 user user
		upvar 2 substate substate
		#plugins_log "Invisibility" "user is: $user and substate is: $substate"

		if { $substate == "FLN" && [lsearch -exact $::Invisibility::config(iallowlist) $user] == -1} {

			::MSN::blockUser ${user}
			after 500 ::Event::fireEvent contactStateChange protocol $user
			plugins_log "Invisibility"  "blocked $user"
		}

		# Old behaviour: Contacts are unblocked only when 
		# they switch to "Online" state
		
		if { $::Invisibility::config(oldbehav) } {
			if { $substate == "NLN" && [lsearch -exact $::Invisibility::config(iblocklist) $user] == -1 }  {

				::MSN::unblockUser ${user}
				after 500 ::Event::fireEvent contactStateChange protocol $user
				plugins_log "Invisibility"  "unblocked $user"			
			}
		# New behavior: Unblock contacts when they become visible		
		} else {
			if { $substate != "FLN" && [lsearch -exact $::Invisibility::config(iblocklist) $user] == -1 }  {

				::MSN::unblockUser ${user}
				after 500 ::Event::fireEvent contactStateChange protocol $user
				plugins_log "Invisibility"  "unblocked $user"			
			}		
		}

	}

######################################
# Add a permanently blocked user
######################################	
	proc AddPermBlock { } {

		set wind $::Invisibility::config(win)
		set user [$wind.clistbox get]

		# If user exists in allow list, we romeve it from there first		
		set rmin [lsearch -exact $::Invisibility::config(iallowlist) $user]
		if { $rmin !=-1 } {
			set ::Invisibility::config(iallowlist) [lreplace $::Invisibility::config(iallowlist) $rmin $rmin]
			::Invisibility::GenerateList "allow"
		}

		# If not already in the block list, we add		
		if { [lsearch -exact $::Invisibility::config(iblocklist) $user] == -1} {
			lappend ::Invisibility::config(iblocklist) $user
			$wind.status.block.blist insert end $user
		}

		# And we unblock the user:
		::MSN::blockUser $user
				
	}

######################################
# Add a permanently allowed user
######################################	

	proc AddPermUnBlock { } {

		set wind $::Invisibility::config(win)
		set user [$wind.clistbox get]

		# If user exists in block list, we romeve it from there first
		set rmin [lsearch -exact $::Invisibility::config(iblocklist) $user]
		if { $rmin !=-1 } {
			set ::Invisibility::config(iblocklist) [lreplace $::Invisibility::config(iblocklist) $rmin $rmin]
			::Invisibility::GenerateList "block"
		}

		# If not already in the allow list, we add
		if { [lsearch -exact $::Invisibility::config(iallowlist) $user] == -1} {
			lappend ::Invisibility::config(iallowlist) $user
			$wind.status.allow.alist insert end $user
		}
		
		# And we unblock the user:
		::MSN::unblockUser $user
		
		#puts "\n $user --> [::abook::getVolatileData $user state]"	
	}

######################################
# Remove a permanently blocked user
######################################	

	proc RemPermBlock { } {

		set wind $::Invisibility::config(win)
		
		set rm [$wind.status.block.blist curselection]
		
		if { [llength $rm] != 0 } {
			set rmin [lindex $rm 0]
			set user [$wind.status.block.blist get $rmin]
			$wind.status.block.blist delete $rmin $rmin
			set rmin2 [lsearch -exact $::Invisibility::config(iblocklist) $user]
			if { $rmin2 != -1 } {
				set ::Invisibility::config(iblocklist) [lreplace $::Invisibility::config(iblocklist) $rmin2 $rmin2]
			}
		}
		
	}

######################################
# Remove a permanently allowed user
######################################	

	proc RemPermUnBlock { } {

		set wind $::Invisibility::config(win)
		
		set rm [$wind.status.allow.alist curselection]
		
		if { [llength $rm] != 0 } {
			set rmin [lindex $rm 0]
			set user [$wind.status.allow.alist get $rmin]
			$wind.status.allow.alist delete $rmin $rmin
			set rmin2 [lsearch -exact $::Invisibility::config(iallowlist) $user]
			if { $rmin2 != -1 } {
				set ::Invisibility::config(iallowlist) [lreplace $::Invisibility::config(iallowlist) $rmin2 $rmin2]
			}
		}
		
	}		

######################################
# Generate the permanent allow/block
# listboxes in the config window.
######################################	

	proc GenerateList { listname } {
	
		set wind $::Invisibility::config(win)
		
		if { $listname eq "allow" } {
			$wind.status.allow.alist delete 0 end
			foreach entry [lsort -dictionary $::Invisibility::config(iallowlist)] {
				$wind.status.allow.alist insert end $entry
			}			
		} elseif { $listname eq "block" } {
			$wind.status.block.blist delete 0 end
			foreach entry [lsort -dictionary $::Invisibility::config(iblocklist)] {
				$wind.status.block.blist insert end $entry
			}
		}
			
	}
######################################
# The proc to populate the frame
# in the config window
######################################	

	proc populateFrame { win } {
		variable win_path
		set win_path $win
		set ::Invisibility::config(win) $win

		frame $win.status -class Degt
		pack $win.status -anchor w
		
		frame $win.status.block
		pack $win.status.block -anchor w
		label $win.status.block.blocklabel -text "[trans pblist]"
		listbox $win.status.block.blist -selectmode single -width 32 -yscrollcommand "$win.status.block.sb set"
		scrollbar $win.status.block.sb -command "$win.status.block.blist yview"
		
		
		button $win.status.block.rempb -text "[trans rempb]" -command ::Invisibility::RemPermBlock
		
		grid $win.status.block.blocklabel -row 1 -column 1 -columnspan 2 -sticky w
		grid $win.status.block.sb -row 2 -column 2 -sticky e
		grid $win.status.block.blist -row 2 -column 1 -sticky wns
		grid $win.status.block.rempb -row 3 -column 1 -columnspan 2 -sticky ew
	
		frame $win.status.allow -padx 15
		pack $win.status.allow -anchor w
		
		label $win.status.allow.allowlabel -text "[trans palist]"
		listbox $win.status.allow.alist -selectmode single -width 32 -yscrollcommand "$win.status.allow.sb set"
		scrollbar $win.status.allow.sb -command "$win.status.allow.alist yview"
		button $win.status.allow.rempa -text "[trans rempa]" -command ::Invisibility::RemPermUnBlock
		
		grid $win.status.allow.allowlabel -row 1 -column 1 -columnspan 2 -sticky w
		grid $win.status.allow.sb -row 2 -column 2 -sticky e
		grid $win.status.allow.alist -row 2 -column 1 -sticky wns
		grid $win.status.allow.rempa -row 3 -column 1 -columnspan 2 -sticky ew
		
		grid $win.status.allow -row 1 -column 2
		grid $win.status.block -row 1 -column 1	
		
		::Invisibility::GenerateList "allow"
		::Invisibility::GenerateList "block"
		
		label $win.clist -text "[trans allcont]" -pady 5
		combobox::combobox $win.clistbox -width 30 -editable 0
		$win.clistbox list delete 0 end
		set conlist [::abook::getAllContacts]
		set rem_ind [lsearch -exact $conlist "myself"]
		set conlist [lreplace $conlist $rem_ind $rem_ind]
		set rem_ind [lsearch -exact $conlist "contactlist"]
		set conlist [lreplace $conlist $rem_ind $rem_ind]
		foreach entry [lsort -dictionary $conlist] {
			$win.clistbox list insert end $entry
		}
		$win.clistbox select 0
		
		button $win.addpb -text "[trans addpb]" -command ::Invisibility::AddPermBlock 
		button $win.addpa -text "[trans addpa]" -command ::Invisibility::AddPermUnBlock
		
		pack $win.clist -anchor c
		pack $win.clistbox -anchor n -pady 5
		pack $win.addpb -anchor n -pady 5
		pack $win.addpa -anchor n
		
		frame $win.waittime
		pack $win.waittime -anchor c
		label $win.waittime.waittext -text "[trans waittext]"
		spinbox $win.waittime.spin -from 2000 -to 30000 -increment 500 -textvariable ::Invisibility::config(waitingtime)
		grid $win.waittime.waittext -row 1 -column 1
		grid $win.waittime.spin -row 1 -column 2
	}

#####################################
# dummy proc. Very useful :).
#####################################	

	proc dummy {event evpar} {
		after $::Invisibility::config(waitingtime) ::Invisibility::unblockNeutrals $event $evpar
	}
######################################
# The proc that unblocks neutral users
# at login time.
######################################	
	proc unblockNeutrals { event evpar } {

		
		plugins_log "Invisibility" "unblocking neutrals"

		set conlist [::abook::getAllContacts]
		set rem_ind [lsearch -exact $conlist "myself"]
		set conlist [lreplace $conlist $rem_ind $rem_ind]
		set rem_ind [lsearch -exact $conlist "contactlist"]
		set conlist [lreplace $conlist $rem_ind $rem_ind]
		
		foreach user $conlist {
		
			set userstate [::abook::getVolatileData $user state]
			
			if { $::Invisibility::config(oldbehav) } {
				if { $userstate == "NLN" && [lsearch -exact $::Invisibility::config(iblocklist) $user] == -1 } {
					after 25
					::MSN::unblockUser ${user}
					after 25 ::Event::fireEvent contactStateChange protocol $user
					plugins_log "Invisibility"  "unblocked $user"			
				}							
			} else {
				if { $userstate != "" && $userstate != "FLN" && [lsearch -exact $::Invisibility::config(iblocklist) $user] == -1 } {
					after 25
					::MSN::unblockUser ${user}
					after 25 ::Event::fireEvent contactStateChange protocol $user
					plugins_log "Invisibility"  "unblocked $user"			
				}
			}
		#plugins_log "Invisibility" "\n $user --> [::abook::getVolatileData $user state]"
		}
	}	

######################################
# We need this so that when trans is 
# called in the new lock/unblock 
# procs (created in ::amsn) it returns
# the translated keys defined in this
# plugin.
######################################

	proc localtrans {key} {
		return [trans $key]
	}
######################################
# Restore the original block/unblock
# and say bye-bye.
######################################
	proc deInit { } {
		plugins_log "Invisibility" "deleting new definitions"
		rename ::amsn::unblockUser ""
		rename ::amsn::blockUser ""
		plugins_log "Invisibility" "restoring definitions"
		rename ::amsn::unblockUserOrig ::amsn::unblockUser
		rename ::amsn::blockUserOrig ::amsn::blockUser
		plugins_log "Invisibility" "restored definitions"
		::plugins::UnRegisterEvents "Invisibility"
		plugins_log "Invisibility" "plugin unregistered"
	}



######################################
# The new block proc.
######################################

	proc ::amsn::blockUser {user_login} {
		
		set answer [::amsn::messageBox "[trans confirmbl] ($user_login)" yesno question [trans block]]
		if { $answer == "yes"} {

			::MSN::blockUser ${user_login}
		
		
			if { $::Invisibility::config(automat) } {
				set answer "yes"
			} else {
				set answer [::amsn::messageBox "[::Invisibility::localtrans invconfirmbl] ($user_login)" yesno question [::Invisibility::localtrans invblock]]
			}
			
			if { $answer == "yes"} {
				
				# If user exists in allow list, we romeve it from there first		
				set rmin [lsearch -exact $::Invisibility::config(iallowlist) $user_login]
				if { $rmin !=-1 } {
					set ::Invisibility::config(iallowlist) [lreplace $::Invisibility::config(iallowlist) $rmin $rmin]
				}

				# If not already in the block list, we add		
				if { [lsearch -exact $::Invisibility::config(iblocklist) $user_login] == -1} {
					lappend ::Invisibility::config(iblocklist) $user_login
				}

			}
		}	
	}
	######################################
	# The new unblock proc.
	######################################

	proc ::amsn::unblockUser {user_login} {
		
		::MSN::unblockUser ${user_login}

		set rmin2 [lsearch -exact $::Invisibility::config(iblocklist) $user_login]
		if { $rmin2 != -1 } {	
			if { $::Invisibility::config(automat) } {
				set answer "yes"
			} else {
				set answer [::amsn::messageBox "[::Invisibility::localtrans invconfirmunbl] ($user_login)" yesno question [::Invisibility::localtrans invblock]]
			}
			
			if { $answer == "yes"} {
				set ::Invisibility::config(iblocklist) [lreplace $::Invisibility::config(iblocklist) $rmin2 $rmin2]
			}
		}
	}

}
