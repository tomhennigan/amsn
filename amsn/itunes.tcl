# iTunes Plugin for Mac OS X, plz do not modify it if you're not a mac user!

	# Gets the current playing song.
	proc GetSong {} {
	#Osascript is a command on  Mac OS X to get result from an AppleScript
	catch {exec osascript utils/itunes.scpt} return
	#Try to find the path & the song in the result of osascript		
	set startpath [string first "?*" $return]
	set endpath [string first "*Z" $return]
	set path [string range $return [expr {$startpath+2}] [expr {$endpath-1}]]
	set song [string range $return 0 [expr {$startpath-1}]]
	#Incluse song and path in the list
	lappend returnsecond $song
	lappend returnsecond $path
	#Return the list for GetSong
	return $returnsecond
	}

	# Use this procedure to:
	# - Display current song. (1)
	# - Send current song. (2)
	proc itunes {win_name action} {
		global user_info
		#Get the list from GetSong {} and separate song and file(path)
		set info [GetSong]
		set song [lindex $info 0]
		set file [lindex $info 1]
		#If we receive nothing from the GetSong, that's because iTunes is not open or he do not play or he listen to URL streaming
		if {$info == "{} {}"} { ::amsn::MessageSend .${win_name} 0 "[trans playing "Nothing actually in iTunes"]"; return 0 }


		switch -- $action {
			1 {
			# - Display current song. (1)
				::amsn::MessageSend .${win_name} 0 "[trans playing $song]"
			}
			2 {
			#If the path is "iPod", don't try to send the file and show message_box to alert the user about that
			if {$file == "iPod"} { 
			status_log $file
			msg_box [trans You can't send file from the iPod];return 0
			#If the path is not iPod, send the file
			} else {
				::amsn::FileTransferSend .${win_name} $file
				return 0
				}
			}
		}
		return 1
	}

