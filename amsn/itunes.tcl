# iTunes Plugin for Mac OS X, plz do not modify it if you're not a mac user!
#Osascript is a command on  Mac OS X to get result from an AppleScript
	# Gets the current playing song.
	proc GetSong {} {

		catch {exec osascript utils/itunes.scpt} return
			
	set startpath [string first "?*" $return]
	set endpath [string first "*Z" $return]
	set path [string range $return [expr {$startpath+2}] [expr {$endpath-1}]]
	set song [string range $return 0 [expr {$startpath-1}]]
	
	
	lappend returnsecond $song
	lappend returnsecond $path
	return $returnsecond
	status_log "Song is $returnsecond\n"
	}

	# Use this procedure to:
	# - Display current song. (1)
	# - Send current song. (2)
	# - Change nick to $nick - song. (3)
	proc itunes {win_name action} {
		global user_info

		set info [GetSong]
		set song [lindex $info 0]
		set file [lindex $info 1]

		if {$info == "0"} { msg_box [trans xmmserr]; return 0 }


		switch -- $action {
			1 {
				::amsn::MessageSend .${win_name} 0 "[trans playing $song]"
			}
			2 {
				::amsn::FileTransferSend .${win_name} $file
				return 0
			}
		}
		return 1
	}

