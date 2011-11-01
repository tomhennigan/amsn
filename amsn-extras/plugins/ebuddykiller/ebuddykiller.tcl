namespace eval ::ebuddykiller {
	variable loaded

	proc Init { dir } {
		variable loaded

		if {[info exists loaded] && $loaded == 1} {
			return
		}

		if { [info commands ::NS::Snit_methodsetInitialNicknameCB] != "" && [info commands ::NS::Snit_methodsetInitialNicknameKilled] == "" } {
			rename ::NS::Snit_methodsetInitialNicknameCB ::NS::Snit_methodsetInitialNicknameKilled
		} else {
			return
		}

		::plugins::RegisterPlugin eBuddyKiller
		plugins_log "eBuddyKiller" "We are being executed"

		proc ::NS::Snit_methodsetInitialNicknameCB { type selfns win self newstate newstate_custom nickname last_modif psm fail } {
			plugins_log "eBuddyKiller" "Callback called"
			set force 0
			if { [string first "- on eBuddy Mobile Messenger http://get.ebuddy.com" $psm] >= 0 || [string first "on www.ebuddy.com Web Messenger" $psm] >= 0 || [string first "- on eBuddy Lite Messenger http://m.ebuddy.com" $psm] >= 0 || [string first "ebuddyxms" $psm] >= 0 } {
				plugins_log "eBuddyKiller" "eBuddy PSM killed!!!"
				set psm [::abook::getPersonal PSM]
				set force 1

				if { [xmldecode $nickname] != $nickname } {
					#eBuddy xmlencoded our nickname... got to change it back
					set nickname [xmldecode $nickname]
				}
			}
			eval ::NS::Snit_methodsetInitialNicknameKilled [list $type $selfns $win $self $newstate $newstate_custom $nickname $last_modif $psm $fail]
			if { $force == 1 } {
				#Update our stuff on the server
				::MSN::changeName $nickname 1
				::MSN::changePSM $psm [::MSN::myStatusIs] 1 1
			}
		}

		set loaded 1
	}


	proc DeInit { } {
		variable loaded
		
		status_log "Restoring previous proc body\n"
	
		;# this will return  the  list of arguments a command can take
		if { [info commands ::NS::Snit_methodsetInitialNicknameKilled] != "" } {
			rename ::NS::Snit_methodsetInitialNicknameCB ""
			rename ::NS::Snit_methodsetInitialNicknameKilled ::NS::Snit_methodsetInitialNicknameCB
		}
	
		set loaded 0
		
	}
}
