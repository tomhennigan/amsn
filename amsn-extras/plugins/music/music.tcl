namespace eval ::music {
	variable config
	variable configlist
	variable name ""
	variable activated 0
	variable songfunc [list "" ""]
	variable musicpluginpath

	#############################################
	# ::music::InitPlugin dir                   #
	# ------------------------------------------#
	# Load proc of music Plugin                 #
	#############################################
	proc InitPlugin { dir } {
		global tcl_platform
		variable musicpluginpath

		set musicpluginpath $dir

		array set OSes [list "darwin" [list GetSongITunes exec_applescript] "linux" [list GetSongXMMS TreatSongXMMS]]

		if {![::music::version_094]} {
			set langdir [append dir "/lang"]
			set lang [::config::getGlobalKey language]
			load_lang $lang $langdir
		}

		set os [string tolower $tcl_platform(os)]
		#status_log "OSes(darwin) $OSes($os)"
		if { ![info exists OSes($os) ] } {
			if { [::music::version_094] } {
				msg_box "Your Operating System ($os) isn't yet supported by the Music plugin"
			} else {
				msg_box [trans musicoserr $os]
			}
			::plugins::UnLoadPlugin music
			return
		}
		set ::music::songfunc $OSes($os)


		#RegisterPlugin
		::plugins::RegisterPlugin music

		#Register event
		::plugins::RegisterEvent music OnConnect newname
		::plugins::RegisterEvent music OnDisconnect stop
		::plugins::RegisterEvent music new_chatwindow CreateMusicMenu

		#loading lang - if version is 0.95b (keep compatibility with 0.94)

		if {[::music::version_094]} {
			array set ::music::config [list \
				nickname {} \
				second {30} \
				symbol {-} \
				stop {Player stopped} \
				active {0} \
			]
			set ::music::configlist [list \
						[list bool "Add song to the nickname"  active] \
						[list str "Verify new song each ? seconds" second] \
						[list str "Nickname"  nickname] \
						[list str "Symbol betwen nick and song"  symbol] \
						[list str "Stopped message"  stop] \
					]
		} else {
			array set ::music::config [list \
				nickname {} \
				second {30} \
				symbol {-} \
				stop {Player stopped} \
				active {0} \
			]
			set ::music::configlist [list \
						[list bool "[trans musicaddsongtonick]"  active] \
						[list str "[trans musictimeverify]" second] \
						[list str "[trans musicnickname]"  nickname] \
						[list str "[trans musicseparator]"  symbol] \
						[list str "[trans musicstopmsg]"  stop] \
					]
		}

		#Start changing the nickname on loading
		::music::wait_load_newname
	}

	###############################################
	# ::music::newname event epvar                #
	# ------------------------------------------- #
	# Main proc to change the nickname            #
	###############################################
	proc newname {event epvar} {
		variable config
		variable name
		variable activated

		#Get all song information from ::music::GetSong
		set info [::music::GetSong]
		set song [lindex $info 0]
		set file [lindex $info 1]

		set oldname $name

		#First add the nickname the user choosed in config to the name variable
		set name "$config(nickname)"
		#Symbol that will be betwen the nick and the song
		set separation " $config(symbol) "

		#Merge the nickname with the song name if a song is playing
		#Else, show the stop messsage
		if {$info != "0"} {
			#Merge the nickname with the symbol and the song name
			append name $separation
			append name $song
		} else {
			if {$config(stop) != ""} {
				#Modification to avoid the separator to be displayed if there is no text when XMMS is stopped
				#Merge the nickname with the symbol and the stop text ( modified from ITunes plugin)
				append name $separation
				append name $config(stop)
			}
		}

		#If the user uncheck the box in config, we must put the standard nickname
		#And if he checks, we must actualize the nickname
		if { $config(active) && !$activated } {
			::music::changenick "$name"
			set activated 1
		}

		if { !$config(active) && $activated } {
			set activated 0
			::music::changenick "$config(nickname)"
		}

		#Change the nickname if the user did'nt uncheck that config.
		if {$config(active) && $name != $oldname } {
			::music::changenick "$name"
		}

		#Execute the script which get the song from the player to have it immediatly
		::music::TreatSong

		#If a strange user decide to use a letter, nothing, or 0, as a number of shake
		#Rechange the variable to 30 seconds
		if {![string is digit -strict $config(second)]} {
			set config(second) "30"
		}
		#Take the second number we have from the plugin config and
		#multiply by 1000 because "after" count in "ms" (1000ms=1s)
		set time [expr {int($config(second)*1000)}]
		#Reload newname proc after this time (loop)
		after $time ::music::newname 0 0

	}
	###############################################
	# ::music::changenick name                    #
	# ------------------------------------------- #
	# Protocol to change the nickname             #
	###############################################
	proc changenick {name} {
		set email [::config::getKey login]
		::MSN::changeName $email $name
	}

	###############################################
	# ::music::GetSong                            #
	# ------------------------------------------- #
	# Gets the current playing song in XMMS       #
	###############################################
	proc GetSong {} {
		variable songfunc
		return [::music::[lindex $songfunc 0]]
	}

	proc TreatSong {} {
		variable songfunc
		return [::music::[lindex $songfunc 1]]
	}

	###############################################
	# ::music::GetSongXMMS                        #
	# ------------------------------------------- #
	# Gets the current playing song in XMMS       #
	###############################################
	proc TreatSongXMMS {} {
		return
	}

	###############################################
	# ::music::GetSongXMMS                        #
	# ------------------------------------------- #
	# Gets the current playing song in XMMS       #
	###############################################
	proc GetSongXMMS {} {
		#Get the file
		set file "/tmp/xmms-info"
		#If file is not there, stop
		if {![file exist $file]} {return 0}
		#Open file (read access)
		set gets [open $file r]
		#Read lines
		while {![eof $gets]} {
			set tmp [gets $gets]
			set pos [string first ":" $tmp]
			set index [string map {" " "_"} [string range $tmp 0 $pos]]
			set info($index) [string range $tmp [expr {$pos+2}] end]
			unset tmp
		}
		#Close acess to the file
		close $gets

		switch -- $info(Status:) {
			"Playing" { lappend return $info(Title:); lappend return $info(File:) }
			"Paused" { lappend return $info(Title:); lappend return $info(File:) }
			"Stopped" { set return 0 }
			default { set return 0 }
		}

		#plugins_log xmms "Song is $return\n"
		return $return
	}


	################################################
	# ::music::exec_applescript                    #
	# -------------------------------------------  #
	# Execute the applescript to get actual song   #
	# Osascript: Command to execute AppleScript    #
	# Find where's the plugin directory(by getKey) #
	################################################
	proc exec_applescript {} {
		variable musicpluginpath
		catch {exec osascript $musicpluginpath/display_and_send.scpt &}
	}

	###############################################
	# ::music::GetSong   ITunes                   #
	# ------------------------------------------- #
	# Gets the current playing song in ITunes     #
	###############################################
	proc GetSongITunes {} {

		#Find the file to read
		set file "~/Library/Application\ Support/amsn/plugins/actualsong"
		#Verify that the file exist
		if {![file exist $file]} {return 0}
		#Open in "read" permission the file (SongIngo)
		set gets [open $file r]

		#Get the 4 first lines
		set software [gets $gets]
		set status [gets $gets]
		set songart [gets $gets]
		set path [gets $gets]

		#Close the file
		close $gets

		if {$status == "0"} {
			return 0
		} else {
			lappend return $songart
			lappend return $path
		}

		return $return

	}

	#######################################################################
	# ::music::CreateMusicMenu event evpar                                #
	# ----------------------------------------------                      #
	# This proc creates the Music submenu shown when a user right clicks  #
	# on the output of the chat window if the plugin is loaded            #
	#######################################################################
	proc CreateMusicMenu { event evpar } {
		upvar 2 evPar newvar

		#Define variables
		set w $newvar(win)
		set copymenu $w.copy

		#Create submenu
		$copymenu add cascade -label "Music" -menu $copymenu.music
		menu $copymenu.music -tearoff 0 -type normal

		if {[::music::version_094]} {
			#Create label in submenu
			$copymenu.music add command -label [trans xmmscurrent] -command "::music::menucommand $w 1"
			$copymenu.music add command -label [trans xmmssend] -command "::music::menucommand $w 2"
		} else {
			#Create label in submenu
			$copymenu.music add command -label [trans musiccurrent] -command "::music::menucommand $w 1"
			$copymenu.music add command -label [trans musicsend] -command "::music::menucommand $w 2"
		}


	}


	################################################
	# ::music::menucommand win_name action         #
	# -------------------------------------------  #
	# Command from the submenu                     #
	# Display the current song in a message (1)    #
	# Or send the current song playing (2)         #
	################################################
	proc menucommand {win_name action} {
		global user_info

		set info [::music::GetSong]
		set song [lindex $info 0]
		set file [lindex $info 1]

		if {$info == "0"} {
			if {[::music::version_094]} {
				msg_box "Nothing is playing, or the plugin can't get the music playing."
			} else {
				msg_box [trans musicerr]
			}
			return 0
		}


		switch -- $action {
			1 {
				#Send a message with the name of the current song
				::amsn::MessageSend $win_name 0 "[trans playing $song]"
			}
			2 {
				#Send the current song as a file
				::amsn::FileTransferSend $win_name $file
				return 0
			}
		}
		return 1
	}


	###############################################
	# ::music::wait_load_newname                  #
	# ------------------------------------------- #
	# Wait 1 second before starting changing      #
	# the nickname. The plugin only use that proc #
	# when we load the plugin. To be sure that    #
	# the init proc is over                       #
	###############################################
	proc wait_load_newname {} {
		after 1000 ::music::load_newname 0 0
	}

	###############################################
	# ::music::load_newname  event epvar          #
	# ------------------------------------------- #
	# Start changing the nick                     #
	# If we load the plugin while we were already #
	# connected, start changing the nick, else do #
	# nothing                                     #
	###############################################
	proc load_newname {event epvar} {

		 #If we are online, start the loop
		if {[::MSN::myStatusIs] != "FLN" } {
			::music::newname 0 0
		}
	}

	###############################################
	# ::music::stop event epvar                   #
	# ------------------------------------------- #
	# Stop changing the nickname                  #
	# Happen when we disconnect or when we unload #
	# This is the Deinit proc                     #
	###############################################
	proc stop {{event 0} {epvar 0}} {
		variable config
		variable activated
		if {$::music::songfunc == ""} {
			return
		}
		after cancel ::music::newname 0 0
		#Remove the song from the nick if we are online
		if {[::MSN::myStatusIs] != "FLN" && $activated } {
			::music::changenick "$config(nickname)"
	   	}
	}

	############################################
	# ::music::version_094                     #
	# -----------------------------------------#
	# Verify if the version of aMSN is 0.94    #
	# Useful if we want to keep compatibility  #
	# Taken from AMsnPlus plugin               #
	############################################
	proc version_094 {} {
		global version
		scan $version "%d.%d" y1 y2;
		if { $y2 == "94" } {
			return 1
		} else {
			return 0
		}
	}
}
