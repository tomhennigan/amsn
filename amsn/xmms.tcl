# XMMS Plugin for aMSN

set paths [split $env(PATH) ":"]

foreach path $paths { if {[file exist $path/xmms]} { set found 1 } }

if {[info exist found]} {

	set xmms(loaded) 1

	# Gets the current playing song.
	proc GetSong {} {
		set file "/tmp/xmms-info"
		if {![file exist $file]} {return 0}

		set gets [open $file r]

		while {![eof $gets]} {
			set tmp [gets $gets]
			set pos [string first ":" $tmp]
			set index [string map {" " "_"} [string range $tmp 0 $pos]]
			set info($index) [string range $tmp [expr {$pos+2}] end]
			unset tmp
		}

		close $gets

		switch -- $info(Status:) {
			"Playing" { lappend return $info(Title:); lappend return $info(File:) }
			"Paused" { lappend return $info(Title:); lappend return $info(File:) }
			"Stopped" { set return 0 }
			default { set return 0 }
		}

		status_log "Song is $return\n"
		return $return
	}

	# Use this procedure to:
	# - Display current song. (1)
	# - Send current song. (2)
	# - Change nick to $nick - song. (3)
	proc xmms {win_name action} {
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
			3 {
				# This stage should be improved, how should we do it?
				# - Should it be a "custom state" where we can set the "songnick" ?
				# - Should it set the nick to "$currentnick - $song" ? if so, we need to make a nick. cache.
				# Can someone make the gui for this ? :)

				set newnick [::config::getKey songnick]
				if { $newnick == "" } {
					# should this tell the user to set a nick? or shall it set the nick to the song??
					::MSN::changeName [lindex $user_info 3] $song
				} else {
					# We must find a solution to remove the song if someone use this function twice!
					::MSN::changeName [lindex $user_info 3] "$newnick - $song"
				}
			}
		}
		return 1
	}
}
