# iTunes Plugin for Mac OS X, plz do not modify it if you're not a mac user!
#Osascript is a command on  Mac OS X to get result from an AppleScript
	# Gets the current playing song.
	proc GetSong {} {

		catch {exec osascript utils/itunes.scpt} return
		status_log "Song is $return\n"
		return $return
	}

	# Use this procedure to:
	# - Display current song. (1)
	# - Send current song. (2)
	# - Change nick to $nick - song. (3)
	proc itunes {win_name action} {
		global user_info

		set info [GetSong]
		set song [GetSong]

		if {$info == "0"} { msg_box [trans xmmserr]; return 0 }


		switch -- $action {
			1 {
				::amsn::MessageSend .${win_name} 0 "[trans playing $song]"
			}
		}
		return 1
	}

