####################################################
#  This plugin makes aMSN remember any chats open  #
#  so after a crash, your chatwindows state will   #
#  be restored.                                    #
#   ===========================================    #
#  Karel Demeyer, 2008                             #
#  ============================================    #
####################################################


namespace eval ::restore {

##############################
# ::restore::InitPlugin dir   #
# ---------------------------#
# Load proc of restore Plugin #
##############################

	proc initPlugin { dir } {
		variable chatslist [list ]
		global HOME
		variable filename 

		set filename [file join $HOME storedchats]


		::plugins::RegisterPlugin "Restore Chats"
		::plugins::RegisterEvent "Restore Chats" new_conversation addChat
		::plugins::RegisterEvent "Restore Chats" chatwindow_closed delChat
		::plugins::RegisterEvent "Restore Chats" contactlistLoaded restoreChats
	}



	proc addChat { event evpar } {
		variable chatslist

		upvar 2 $evpar newvar
#		upvar 2 $newvar(chatid) chat
#somehow we can get the value like this without upvar'ing again .. I don't get it :| .. in chatwindow.tcl, the name of the var is passed/stored in the array, not the value.  When upvarring, the proc is not further evaluated
		set chat $newvar(chatid)
		set chatusers [::MSN::usersInChat $chat]
		if { $chatusers == "" } {
			set chatusers $chat
		}


		#Don't support groupchats
		if { [llength $chatusers] != 1 || $chatusers == "chatid"} { 
			return
		}

		lappend chatslist $chatusers

		updateOnDiskCopy

	}


	proc delChat { event evpar } {
		variable chatslist

		upvar 2 $evpar newvar
		upvar 2 $newvar(chatid) chat
		set chatusers [::MSN::usersInChat $chat]
		if { $chatusers == "" } {
			set chatusers $chat
		}



		#Don't support groupchats
		if { [llength $chatusers] != 1 } { 
			return
		}

		set userindex [lsearch $chatslist $chatusers]
		set chatslist [lreplace $chatslist $userindex $userindex]

		updateOnDiskCopy

	}

	proc updateOnDiskCopy { } {
		variable chatslist
		variable filename

		file delete $filename

		if { $chatslist == [list ] } {
			return
		}

		set diskcopy [open $filename w+]
		puts $diskcopy $chatslist
		close $diskcopy

	}
	
	proc restoreChats { { event ""} { evpar ""} } {
		variable filename
#		variable chatslist


		if { [file exists $filename] } {
			set diskcopy [open $filename r]
			set chatslist [read -nonewline $diskcopy]
			close $diskcopy

			file delete $filename
			foreach chat $chatslist {
				::amsn::chatUser $chat
			}

		}
	}
}

