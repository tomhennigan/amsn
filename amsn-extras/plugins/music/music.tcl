namespace eval ::music {
	variable config
	variable configlist
	variable name ""
	variable activated 0
	variable playersarray
	variable musicpluginpath

	#############################################
	# ::music::InitPlugin dir                   #
	# ------------------------------------------#
	# Load proc of music Plugin                 #
	#############################################
	proc InitPlugin { dir } {
		global tcl_platform
		variable musicpluginpath
		variable playersarray
		set musicpluginpath $dir

		array set OSes [list \
			"darwin" [list \
				"ITunes" [list GetSongITunes exec_applescript] \
			] \
			"linux" [list \
				"XMMS" [list GetSongXMMS TreatSongXMMS] \
				"Amarok" [list GetSongAmarok TreatSongAmarok] \
			]
		]

		#loading lang - if version is 0.95b (keep compatibility with 0.94)

		if {![::music::version_094]} {
			set langdir [append dir "/lang"]
			set lang [::config::getGlobalKey language]
			load_lang $lang $langdir
		}

		set os [string tolower $tcl_platform(os)]

		if { ![info exists OSes($os) ] } {
			if { [::music::version_094] } {
				msg_box "Your Operating System ($os) isn't yet supported by the music plugin"
			} else {
				msg_box [trans musicoserr $os]
			}
			::plugins::UnLoadPlugin "Music"
			return
		}
		array set playersarray $OSes($os)

		#RegisterPlugin
		::plugins::RegisterPlugin "Music"

		#Register event
		::plugins::RegisterEvent "Music" OnConnect newname
		::plugins::RegisterEvent "Music" OnDisconnect stop
		::plugins::RegisterEvent "Music" new_chatwindow CreateMusicMenu

		if {[::music::version_094]} {
			array set ::music::config [list \
				player [lindex [array names playersarray] 0] \
				nickname {} \
				second {30} \
				symbol {-} \
				stop {Player stopped} \
				active {0} \
			]
			set ::music::configlist [list \
						#[list rbt [array names [array set OSes($os)]] player] \ How to do choices in 0.94 ?
						[list str "Verify new song each ? seconds" second] \
						[list bool "Add song to the nickname"  active] \
						[list str "Nickname"  nickname] \
						[list str "Symbol betwen nick and song"  symbol] \
						[list str "Stopped message"  stop] \
					]
		} else {
			array set ::music::config [list \
				player [lindex [array names playersarray] 0] \
				nickname {} \
				second {30} \
				symbol {-} \
				stop [trans musicstopdefault] \
				active {0} \
			]

			set ::music::configlist [list \
						[list label "[trans musicplayer]"] \
						[list lst [array names playersarray] player] \
						[list str "[trans musictimeverify]" second] \
						[list bool "[trans musicaddsongtonick]"  active] \
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
		variable config
		variable playersarray

		if {![info exists playersarray([lindex $config(player) 0])] } {
			return 0
		}
		set songfunc $playersarray([lindex $config(player) 0])
		set retval 0
		catch {::music::[lindex $songfunc 0]} retval
		return $retval
	}

	proc TreatSong {} {
		variable config
		variable playersarray
		if {![info exists playersarray([lindex $config(player) 0])] } {
			return 0
		}
		set songfunc $playersarray([lindex $config(player) 0])
		set retval 0
		catch {::music::[lindex $songfunc 1]} retval
		return $retval
	}

	#####################################################
	# ::music::TreatSongXMMS                            #
	# ------------------------------------------------- #
	# Not useful to XMMS because no script to execute   #
	#####################################################
	proc TreatSongXMMS {} {
		return 0
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
		if {![file exist $file]} {
			return 0
		}
		#Open file (read access)
		set gets [open $file {NONBLOCK RDONLY}]

		set timeout [clock clicks -milliseconds]

		#We wait the pipe to be filled by xmms-info or 1 seconds elapsed (in case of xmms is closed)
		set tmp [gets $gets]
		while { [eof $gets] && [expr [clock clicks -milliseconds]-$timeout]<1000 } {
			set tmp [gets $gets]
		}

		#Read lines
		while { ![eof $gets] } {
			#The pipe was filled by xmms-info
			if { $tmp != "" } {
			set pos [string first ":" $tmp]
				set index [string map { " " "_" } [string range $tmp 0 $pos]]
			set info($index) [string range $tmp [expr {$pos+2}] end]
			}
			unset tmp
			set tmp [gets $gets]
		}

		#Close acess to the file
		close $gets

		if {[info exists info(Status:)]} {
		switch -- $info(Status:) {
			"Playing" { lappend return $info(Title:); lappend return $info(File:) }
			"Paused" { lappend return $info(Title:); lappend return $info(File:) }
			"Stopped" { set return 0 }
			default { set return 0 }
		}
			#plugins_log music "Song is $return\n"
		return $return
	}

		return 0
	}

	###############################################
	# ::music::TreatSongAmarok                    #
	# ------------------------------------------- #
	# Gets the current playing song in Amarok     #
	###############################################
	proc TreatSongAmarok {} {
		variable musicpluginpath
		catch {exec sh $musicpluginpath/infoamarok $musicpluginpath/actualsong &}
		return 0
	}

	###############################################
	# ::music::GetSongAmarok                      #
	# ------------------------------------------- #
	# Gets the current playing song in Amarok     #
	###############################################
	proc GetSongAmarok {} {
		variable musicpluginpath

		#Find the file to read
		set file "$musicpluginpath/actualsong"
		#Verify that the file exist
		if {![file exist $file]} {return 0}
		#Open in "read" permission the file (SongIngo)
		set gets [open $file r]

		#Get the 3 first lines
		set status [gets $gets]
		set songart [gets $gets]
		set path [gets $gets]

		#Close the file
		close $gets

		if {$status == "0"} {
			return 0
		} else {
			lappend return $songart
			lappend return [urldecode [string range $path 5 end]]
		}
		#plugins_log music "Song is $return\n"
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
		return 0
	}

	###############################################
	# ::music::GetSongITunes                      #
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
		#plugins_log music "Song is $return\n"
		return $return

	}

	#######################################################################
	# ::music::CreateMusicMenu event evpar                                #
	# ----------------------------------------------                      #
	# This proc creates the music submenu shown when a user right clicks  #
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
	proc stop {event epvar} {
		variable config
		variable activated
		if {[array size ::music::playersarray]==0} {
			return
		}
		after cancel ::music::newname 0 0
		#Remove the song from the nick if we are online
		if {[::MSN::myStatusIs] != "FLN" && $activated } {
			::music::changenick "$config(nickname)"
	   	}
	}

	proc DeInit {} {
		::music::stop 0 0
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
