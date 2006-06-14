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
		variable musicpluginpath
		variable smallcoverfilename
		variable playersarray
		variable oldinfo

		set musicpluginpath $dir
		set smallcoverfilename [file join $musicpluginpath albumart.jpg]
		set oldinfo [list]

		#Load translation keys (lang files)
		::music::LoadLangFiles $dir
		
		::music::LoadPixmaps $dir

		#Verify the OS is supported before loading the plugin
		#And configure default players for each OS
		if {![::music::OsVerification]} { return }

		#RegisterPlugin
		::plugins::RegisterPlugin "Music"
		
		#Register events
		::music::RegisterEvent
		
		#Set default values for config
		::music::ConfigArray
		#Add items to configure window
		set ::music::configlist [list [list frame ::music::populateFrame_1st ""] ]
		
		#Start changing the nickname on loading
		::music::wait_load_newname
		#Register /showsong and /sendsong to 
		after 5000 ::music::add_command 0 0
	}

	
	proc populateFrame_1st { win_name } {
		variable playersarray
		frame $win_name.players -class Degt
		label $win_name.players.question -text "[trans musicplayer]" -padx 5 -font sboldf
		pack $win_name.players $win_name.players.question
		if { [llength [array names playersarray] ] > 1} {	
			ComboBox $win_name.players.selection -editable false -highlightthickness 0 -width 15 -font splainf \
				-textvariable ::music::config(player) -values [array names playersarray] \
				-modifycmd "::music::populateFrame_2nd ${win_name} "
			pack $win_name.players.selection -anchor w -expand true -fill both
		}
		
		populateFrame_2nd $win_name

	}

	proc populateFrame_2nd { win_name } {
		if {[winfo exists $win_name.sw]} {
			destroy $win_name.sw
		}
		
		#Scrollableframe that will contain config options
		ScrolledWindow $win_name.sw 
		ScrollableFrame $win_name.sw.sf -areaheight 0 -areawidth 0 
		$win_name.sw setwidget $win_name.sw.sf
		set mainFrame [$win_name.sw.sf getframe]	
		pack $win_name.sw -anchor n -side top -expand true -fill both

		#second
		frame $mainFrame.second -class degt
		label $mainFrame.second.label -text "[trans musictimeverify]" -padx 5 -font sboldf
		entry $mainFrame.second.entry -bg #ffffff -width 10 -textvariable ::music::config(second)
		pack $mainFrame.second.label -anchor w -side left
		pack $mainFrame.second.entry -anchor w -side left -fill x
		pack $mainFrame.second -anchor w -expand true -fill x

		if { [::config::getKey protocol] >= 11 } {
			#add to psm
			frame $mainFrame.psm -class degt
			pack $mainFrame.psm -anchor w -expand true -fill both
			checkbutton $mainFrame.psm.checkbutton -variable ::music::config(active) -text "[trans musicaddsongtopsm]"
			pack $mainFrame.psm.checkbutton -anchor w 
		} else {
			#add to nick
			frame $mainFrame.add2nick -class degt
			pack $mainFrame.add2nick -anchor w -expand true -fill both
			checkbutton $mainFrame.add2nick.checkbutton -variable ::music::config(active) -text "[trans musicaddsongtonick]"
			pack $mainFrame.add2nick.checkbutton -anchor w
				
			#nickname
			frame $mainFrame.nick -class degt
			label $mainFrame.nick.label -text "[trans musicnickname]" -padx 5 -font sboldf
			entry $mainFrame.nick.entry -bg #ffffff -width 45 -textvariable ::music::config(nickname)
			pack $mainFrame.nick.label -anchor w -side left
			pack $mainFrame.nick.entry -anchor w -side left -fill x
			pack $mainFrame.nick -anchor w -expand true -fill x

			#separator
			frame $mainFrame.separator -class degt
			label $mainFrame.separator.label -text "[trans musicseparator]" -padx 5 -font sboldf
			entry $mainFrame.separator.entry -bg #ffffff -width 10 -textvariable ::music::config(symbol)
			pack $mainFrame.separator.label -anchor w -side left
			pack $mainFrame.separator.entry -anchor w -side left -fill x
			pack $mainFrame.separator -anchor w -expand true -fill x

			#stop msg
			frame $mainFrame.stopmsg -class degt
			label $mainFrame.stopmsg.label -text "[trans musicstopmsg]" -padx 5 -font sboldf
			entry $mainFrame.stopmsg.entry -bg #ffffff -width 10 -textvariable ::music::config(stop)
			pack $mainFrame.stopmsg.label -anchor w -side left
			pack $mainFrame.stopmsg.entry -anchor w -side left -fill x
			pack $mainFrame.stopmsg -anchor w -expand true -fill x
		}
		
		FillFrame $mainFrame

		pack $win_name 
	}

	

	#####################################################
	# ::music::LoadLangFiles dir                        #
	# ------------------------------------------------- #
	# Load pixmaps files                                #
	#####################################################
	proc LoadPixmaps {dir} {
		::skin::setPixmap musicshown_pic notespic.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap musichidden_pic notesdispic.gif pixmaps [file join $dir pixmaps]
	}

	#####################################
	# ::music::RegisterEvent            #
	# --------------------------------- #
	# Register events to plugin system  #
	#####################################	
	proc RegisterEvent {} {
		::plugins::RegisterEvent "Music" OnConnect newname
		::plugins::RegisterEvent "Music" OnDisconnect stop
		::plugins::RegisterEvent "Music" ContactListColourBarDrawn draw
		::plugins::RegisterEvent "Music" new_chatwindow CreateMusicMenu
		::plugins::RegisterEvent "Music" AllPluginsLoaded add_command
	}
	
	#####################################################
	# ::music::LoadLangFiles dir                        #
	# ------------------------------------------------- #
	# Load lang files                                   #
	#####################################################
	proc LoadLangFiles {dir} {
		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir
	}
	########################################
	# ::music::ConfigArray                 #
	# -------------------------------------#
	# Add config array with default values #
	########################################	
	proc ConfigArray {} {
		variable playersarray
		
		#Use translation key for 0.95 users
		set stopmessage [trans musicstopdefault]
		array set ::music::config [list \
			player [lindex [array names playersarray] 0] \
			nickname {} \
			second {30} \
			symbol {-} \
			stop $stopmessage \
			active {0} \
			songart {1} \
			separator {-} \
			changepic {0} \
			mpd_ip {127.0.0.1} \
			mpd_port {6600} \
			mpd_music_directory {} \
		]
		
	}

	###########################################
	# ::music::OsVerification                 #
	# ----------------------------------------#
	# Verify the OS is supported by the plugin#
	# And define players supported            # 
	###########################################	
	proc OsVerification {} {
		global tcl_platform
		variable playersarray
		
		
		#Define values for supported player on darwin and linux
		array set OSes [list \
			"darwin" [list \
				"ITunes" [list GetSongITunes exec_applescript FillFrameLess] \
				"MPD" [list GetSongMPD TreatSongMPD FillFrameMPD] \
			] \
			"linux" [list \
				"XMMS" [list GetSongXMMS TreatSongXMMS FillFrameEmpty] \
				"Amarok" [list GetSongAmarok TreatSongAmarok FillFrameComplete] \
				"Rhythmbox" [list GetSongRhythmbox TreatSongRhythmbox FillFrameLess] \
				"Banshee" [list GetSongBanshee TreatSongBanshee FillFrameComplete] \
				"MPD" [list GetSongMPD TreatSongMPD FillFrameMPD] \
			]\
			"freebsd" [list \
				"XMMS" [list GetSongXMMS TreatSongXMMS FillFrameEmpty] \
				"Amarok" [list GetSongAmarok TreatSongAmarok FillFrameComplete] \
				"Rhythmbox" [list GetSongRhythmbox TreatSongRhythmbox FillFrameLess] \
				"Banshee" [list GetSongBanshee TreatSongBanshee FillFrameComplete] \
				"MPD" [list GetSongMPD TreatSongMPD FillFrameMPD] \
			] \
			"windows nt" [list \
				"WinAmp" [list GetSongWinamp TreatSongWinamp FillFrameLess] \
				"MPD" [list GetSongMPD TreatSongMPD FillFrameMPD] \
			] \
			"windows 95" [list \
				"WinAmp" [list GetSongWinamp TreatSongWinamp FillFrameLess] \
				"MPD" [list GetSongMPD TreatSongMPD FillFrameMPD] \
			] \
		]
		#Get current OS platform
		set os [string tolower $tcl_platform(os)]
		#If the OS is not supported show message box error and unload plugin
		if { ![info exists OSes($os) ] } {
			#Show message box error
			msg_box [trans musicoserr $os]
			#Unload plugin
			::plugins::UnLoadPlugin "Music"
			return 0
		}
		array set playersarray $OSes($os)
		return 1
	}
	


	###############################################
	# ::music::newname event epvar                #
	# ------------------------------------------- #
	# Main proc to change the nickname            #
	###############################################
	proc newname {event epvar} {
		variable musicpluginpath
		variable smallcoverfilename
		variable config
		variable activated
		variable oldinfo
		variable dppath
		
		
		#Get all song information from ::music::GetSong
		set info [::music::GetSong]

		set song [lindex $info 0]
		set file [lindex $info 1]
		set artfile [lindex $info 2]

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
			if {[::config::getKey protocol] == 11} {
				if { $song != "0"} {
					::MSN::changeCurrentMedia Music 1 "{0}" $song
				}
			} else {
				::music::changenick "$name"
			}
			set activated 1
		}

		if { !$config(active) && $activated } {
			set activated 0
			if {[::config::getKey protocol] == 11} {
				::MSN::changeCurrentMedia Music 0 "{0}" ""
			} else {
				::music::changenick "$config(nickname)"
			}
		}

		#Change the nickname if the user did'nt uncheck that config.
		if {$config(active) && $info != $oldinfo } {
			if {[::config::getKey protocol] == 11} {
				if { $song != "0"} {
					::MSN::changeCurrentMedia Music 1 "{0}" $song
				} else {
					::MSN::changeCurrentMedia Music 0 "{0}" ""
				}
			} else {
				::music::changenick "$name"
			}
		}

		if {$config(changepic) && $info != $oldinfo} {
			#set avatar to albumart if available
			if {[::config::getKey displaypic] != $smallcoverfilename} {
				#Picture changed so save the new name
				set dppath [::config::getKey displaypic]
				if { $dppath == "nopic.gif" } {
					set dppath ""
				}
			}
			if {$artfile != ""} {
				#create a photo called "smallcover" with the albumart of the played song
				::picture::ResizeWithRatio [image create photo smallcover -file $artfile] 96 96

				if {![catch {::picture::Save smallcover $smallcoverfilename cxjpg}]} {
					::music::log "Album art found, changing..."
					::music::set_dp $smallcoverfilename
				}

			} else {
				#if the album cover isn't available, set the dp the user set before changes by musicplugin
				::music::log "No album art found, use \"$dppath\""
				
				::music::set_dp $dppath

			}
		}
		if {!$config(changepic) && [string compare [::config::getKey displaypic] $smallcoverfilename] == 0} {
			#Config disabled : change the dp to the good one...
			::music::set_dp $dppath
		}


		set oldinfo $info

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
		::music::log "Change nickname for $email $name"
	}

	###############################################
	# ::music::set_dp dpfile                      #
	# ------------------------------------------- #
	# Protocol to change the displaypic           #
	###############################################
	proc set_dp {dp} {
		if {[::MSN::myStatusIs] != "FLN" } {
			set_displaypic $dp
		}
	}

	###############################################
	# ::music::GetSong                            #
	# ------------------------------------------- #
	# Gets the current playing song               #
	###############################################
	proc GetSong {} {
		variable config
		variable playersarray

		if {![info exists playersarray([lindex $config(player) 0])] } {
			::music::log "Player not supported by Music plugin"
			return 0
		}
		set songfunc $playersarray([lindex $config(player) 0])
		set retval 0
		catch {::music::[lindex $songfunc 0]} retval
		::music::log "Get song: $retval"
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

	proc FillFrame { mainFrame } {
		variable config
		variable playersarray
		if {![info exists playersarray([lindex $config(player) 0])] } {
			return 0
		}
		set songfunc $playersarray([lindex $config(player) 0])
		set retval 0
		catch {::music::[lindex $songfunc 2] $mainFrame} retval
		return $retval
	}

	#####################################################
	# ::music::exec_async                               #
	# ------------------------------------------------- #
	# Execute the specified path and store the result   #
	# in actualsong.                                    #
	# Use with after to make it asynchronous            #
	#####################################################
	proc exec_async {path} {
		if { [catch { eval [concat [list "exec"] $path]} result ] } {
			::music::log "Error retreiving song : $result"
		} else {
			set ::music::actualsong $result
			# whatever processing goes here
		}
	}
	
	#####################################################
	# ::music::exec_async_mac                           #
	# ------------------------------------------------- #
	# Execute the specified path with osascript			#
	# and store the result  in actualsong.				#
	# Use with after to make it asynchronous            #
	#####################################################
	proc exec_async_mac {path} {
		if { [catch { exec osascript $path} result ] } {
			::music::log "Error retreiving song : $result"
		} else {
			::music::log "Define variable in async_mac:\n$result"
			set ::music::actualsong $result
		}
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
		return $return
	}

		return 0
	}

	###############################################
	# ::music::FillFrameEmpty                     #
	# ------------------------------------------- #
	# Fills the config frame with nothing         #
	###############################################
	proc FillFrameEmpty {mainFrame} {

	}
	###############################################
	# ::music::TreatSongAmarok                    #
	# ------------------------------------------- #
	# Gets the current playing song in Amarok     #
	###############################################
	proc TreatSongAmarok {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "infoamarok"]] }
		return 0
	}

	###############################################
	# ::music::GetSongAmarok                      #
	# ------------------------------------------- #
	# Gets the current playing song in Amarok     #
	###############################################
	proc GetSongAmarok {} {

		#actualsong is filled asynchronously in TreatSongAmarok
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}

		#Get the 4 first lines
		set status [lindex $tmplst 0]
		set song [lindex $tmplst 1]
		set art [lindex $tmplst 2]
		set path [lindex $tmplst 3]
		set artpath [lindex $tmplst 4]
		
		if {[string first "nocover" [file tail $artpath]] != -1} { set artpath "" }


		if {$status == "0"} {
			return 0
		} else {
			#Define in which  order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
			if {$::music::config(songart) == 1} {
				append songart $song " " $::music::config(separator) " " $art
			} elseif {$::music::config(songart) == 2} {
				append songart $art " " $::music::config(separator) " " $song
			} elseif {$::music::config(songart) == 3} {
				append songart $song
			}
			lappend return $songart
			lappend return [urldecode [string range $path 5 end]]
			lappend return $artpath
		}
		return $return
	}

	###############################################
	# ::music::FillFrameComplete                  #
	# ------------------------------------------- #
	# Fills the config frame for complete support #
	###############################################
	proc FillFrameComplete {mainFrame} {
		#order for song and artist name
		frame $mainFrame.order -class degt
		pack $mainFrame.order -anchor w -expand true -fill both
		label $mainFrame.order.label -text "[trans choose_order]" -padx 5 -font sboldf
		radiobutton $mainFrame.order.1 -text "[trans songartist]" -variable ::music::config(songart) -value 1
		radiobutton $mainFrame.order.2 -text "[trans artistsong]" -variable ::music::config(songart) -value 2
		radiobutton $mainFrame.order.3 -text "[trans song]" -variable ::music::config(songart) -value 3
		label $mainFrame.order.separator_label -text "[trans separator]" -padx 5 -font sboldf
		entry $mainFrame.order.separator_entry -bg #ffffff -width 10 -textvariable ::music::config(separator)			
		pack $mainFrame.order.label \
			$mainFrame.order.1 \
			$mainFrame.order.2 \
			$mainFrame.order.3 \
				-anchor w -side top
		pack $mainFrame.order.separator_label \
				$mainFrame.order.separator_entry \
				-anchor w -side left
	
		#changepic
		frame $mainFrame.changepic -class degt
		pack $mainFrame.changepic -anchor w -expand true -fill both
		checkbutton $mainFrame.changepic.checkbutton -variable ::music::config(changepic) -text "[trans changepic]"
		pack $mainFrame.changepic.checkbutton -anchor w
	}

	###############################################
	# ::music::TreatSongBanshee                    #
	# ------------------------------------------- #
	# Gets the current playing song in Banshee     #
	###############################################
	proc TreatSongBanshee {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "infobanshee"]] }
		return 0
	}

	###############################################
	# ::music::GetSongBanshee                      #
	# ------------------------------------------- #
	# Gets the current playing song in Banshee     #
	###############################################
	proc GetSongBanshee {} {
		#actualsong is filled asynchronously in TreatSongBanshee
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}
		
		if {$tmplst == 0} {
			set Status 0
		} else {

			foreach infoline $tmplst {
				#find the index of the first ":"
				set dpntindex [string first ":" $infoline]
				#the name of the var is the label banshee gives it itself
				set label [string range $infoline 0 [expr {$dpntindex - 1}]]
				#save everything after the ": " as info under a var named after the label
				set ${label} [string range $infoline [expr {$dpntindex + 2}] end]
			}
		}

		if {$Status == "0"} {
			return 0
		} else {
			#Define in which order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
			if {$::music::config(songart) == 1} {
				append songart $Title " " $::music::config(separator) " " $Artist
			} elseif {$::music::config(songart) == 2} {
				append songart $Artist " " $::music::config(separator) " " $Title
			} elseif {$::music::config(songart) == 3} {
				append songart $Title
			}

			#First element in the returned list is the artist + song in desired format
			lappend return $songart
			#Second element is the path to the music-file
			lappend return [urldecode [string range $Uri 7 end]]
			#Third element is the path to the album cover-art (if available, else it is "")
			lappend return $CoverUri
		}

		return $return
	}

	###############################################
	# ::music::TreatSongRhythmbox                 #
	# ------------------------------------------- #
	# Gets the current playing song in Rhythmbox  #
	###############################################
	proc TreatSongRhythmbox {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "inforhythmbox"]] }
		return 0
	}

	###############################################
	# ::music::GetSongRhythmbox                   #
	# ------------------------------------------- #
	# Gets the current playing song in Rhythmbox  #
	###############################################
	proc GetSongRhythmbox {} {
		#actualsong is filled asynchronously in TreatSongRhythmbox
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}

		#Get the 4 first lines
		set song [lindex $tmplst 0]
		set art [lindex $tmplst 1]
		set path [lindex $tmplst 2]
		set songlength [lindex $tmplst 3]
		
		if {$songlength == "-1"} {
			return 0
		} else {
			#Define in which  order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
			if {$::music::config(songart) == 1} {
				append songart $song " " $::music::config(separator) " " $art
			} elseif {$::music::config(songart) == 2} {
				append songart $art " " $::music::config(separator) " " $song
			} elseif {$::music::config(songart) == 3} {
				append songart $song
			}
			lappend return $songart
			lappend return [urldecode [string range $path 5 end]]
		}

		return $return
	}
	
	##################################################
	# ::music::TreatSongMPD                          #
	# ---------------------------------------------- #
	# Not useful to MPD because no script to execute #
	##################################################
	proc TreatSongMPD {} {
		return 0
	}
	###############################################
	# ::music::GetSongMPD                         #
	# ------------------------------------------- #
	# Gets the current playing song in MPD        #
	###############################################
	proc GetSongMPD {} {
		set chan [socket -async $::music::config(mpd_ip) $::music::config(mpd_port)]
		if { [catch {gets $chan line} err] } {
			plugins_log Music "error : $err"
			return 0
		}
		if {[string range $line 0 1] != "OK" } {
			plugins_log Music "error : [MPD] no OK found "
			return 0
		}
		puts $chan "status"
		flush $chan
		if { [catch {gets $chan line} err] } {
			plugins_log Music "error : $err"
			return 0
		}
		while {[string range $line 0 1] != "OK" } {
			if { [string range $line 0 4] == "state" } {
				set state [string range $line 7 end]
				plugins_log Music "state of the player is $state"
				if { $state == "stop" || $state == "pause" } {
					return 0
				}
			}
			if { [catch {gets $chan line} err] } {
				plugins_log Music "error : $err"
				return 0
			}		
		}
		#Finish getting infos from status command
		while {[string range $line 0 1] != "OK" } {
			if { [catch {gets $chan line} err] } {
				plugins_log Music "error : $err"
				return 0
			}		
		}
		#now, get the currentsong
		puts $chan "currentsong"
		flush $chan
		if { [catch {gets $chan line} err] } {
			plugins_log Music "error : $err"
			return 0
		}		
		set Title ""
		set Artist ""
		set File ""
		#set Cover ""
		while {[string range $line 0 1] != "OK" } {
			if { [string range $line 0 5] == "Artist" } {
				set Artist [string range $line 8 end]
				plugins_log music "Artist is $Artist"
			}
			if { [string range $line 0 3] == "file" } {
				set File [string range $line 6 end]
				plugins_log music "file is $File"

			}
			if { [string range $line 0 4] == "Title" } {
				set Title [string range $line 7 end]
				plugins_log music "Title is $Title"

			}
			if { [catch {gets $chan line} err] } {
				plugins_log music "error : $err"
				return 0
			}		
		}
		#Define in which order we want to show the song (from the config)
		#Use the separator(from the conf) between song and artist
		if {$::music::config(songart) == 1} {
		append songart $Title " " $::music::config(separator) " " $Artist
		} elseif {$::music::config(songart) == 2} {
			append songart $Artist " " $::music::config(separator) " " $Title
		} elseif {$::music::config(songart) == 3} {
			append songart $Title
		}
		#First element in the returned list is the artist + song in desired format
		lappend return $songart
		#Second element is the path to the music-file
		#lappend return [file join $::music::config(mpd_music_directory) $File]
		#Third element is the path to the album cover-art (if available, else it is "")
		#lappend return $CoverUri
		
		close $chan
		return $return
	}

	###############################################
	# ::music::FillFrameMPD                       #
	# ------------------------------------------- #
	# Fills the config frame for MPD              #
	###############################################
	proc FillFrameMPD {mainFrame} {
		#order for song and artist name
		frame $mainFrame.order -class degt
		pack $mainFrame.order -anchor w -expand true -fill both
		label $mainFrame.order.label -text "[trans choose_order]" -padx 5 -font sboldf
		radiobutton $mainFrame.order.1 -text "[trans songartist]" -variable ::music::config(songart) -value 1
		radiobutton $mainFrame.order.2 -text "[trans artistsong]" -variable ::music::config(songart) -value 2
		radiobutton $mainFrame.order.3 -text "[trans song]" -variable ::music::config(songart) -value 3
		label $mainFrame.order.separator_label -text "[trans separator]" -padx 5 -font sboldf
		entry $mainFrame.order.separator_entry -bg #ffffff -width 10 -textvariable ::music::config(separator)			
		pack $mainFrame.order.label \
				$mainFrame.order.1 \
				$mainFrame.order.2 \
				$mainFrame.order.3 \
				-anchor w -side top
		pack $mainFrame.order.separator_label \
				$mainFrame.order.separator_entry \
				-anchor w -side left
				
		#ip
		frame $mainFrame.ip
		label $mainFrame.ip.label -text "[trans music_mpd_ip]"
		entry $mainFrame.ip.entry -textvariable ::music::config(mpd_ip) -bg white -width 15
		pack $mainFrame.ip -anchor w
		pack $mainFrame.ip.label $mainFrame.ip.entry -anchor w

		#port
		frame $mainFrame.port
		label $mainFrame.port.label -text "[trans music_mpd_port]"
		entry $mainFrame.port.entry -textvariable ::music::config(mpd_port) -bg white -width 10
		pack $mainFrame.port -anchor w
		pack $mainFrame.port.label $mainFrame.port.entry -anchor w
	}
	
	###############################################
	# ::music::TreatSongTotem                     #
	# ------------------------------------------- #
	# Gets the current playing song in Totem      #
	###############################################
	proc TreatSongTotem {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "infototem"]]}
		return 0
	}

	###############################################
	# ::music::GetSongTotem                       #
	# ------------------------------------------- #
	# Gets the current playing song in Totem      #
	###############################################
	proc GetSongTotem {} {

		#actualsong is filled asynchronously in TreatSongAmarok
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} song] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}



		if {$song == "0"} {
			return 0
		} else {
			#Define in which  order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
#			if {$::music::config(songart) == 1} {
#				append songart $song " " $::music::config(separator) " " $art
#			} elseif {$::music::config(songart) == 2} {
#				append songart $art " " $::music::config(separator) " " $song
#			} elseif {$::music::config(songart) == 3} {
#				append songart $song
#			}
#			lappend return $songart
#			lappend return [urldecode [string range $path 5 end]]
			return $song
		}
#		return $return
	}

	###############################################
	# ::music::FillFrameLess                      #
	# ------------------------------------------- #
	# Fills the config frame for minimal support  #
	###############################################
	proc FillFrameLess {mainFrame} {
		#order for song and artist name
		frame $mainFrame.order -class degt
		pack $mainFrame.order -anchor w -expand true -fill both
		label $mainFrame.order.label -text "[trans choose_order]" -padx 5 -font sboldf
		radiobutton $mainFrame.order.1 -text "[trans songartist]" -variable ::music::config(songart) -value 1
		radiobutton $mainFrame.order.2 -text "[trans artistsong]" -variable ::music::config(songart) -value 2
		radiobutton $mainFrame.order.3 -text "[trans song]" -variable ::music::config(songart) -value 3
		label $mainFrame.order.separator_label -text "[trans separator]" -padx 5 -font sboldf
		entry $mainFrame.order.separator_entry -bg #ffffff -width 10 -textvariable ::music::config(separator)			
		pack $mainFrame.order.label \
				$mainFrame.order.1 \
				$mainFrame.order.2 \
				$mainFrame.order.3 \
				-anchor w -side top
		pack $mainFrame.order.separator_label \
				$mainFrame.order.separator_entry \
				-anchor w -side left
	}

	################################################
	# ::music::exec_applescript                    #
	# -------------------------------------------  #
	# Execute the applescript to get actual song   #
	# Osascript: Command to execute AppleScript    #
	# Find where's the plugin directory(by getKey) #
	################################################
	proc exec_applescript {} {
		after 0 {::music::exec_async_mac [file join $::music::musicpluginpath display_and_send.scpt]}
		return 0
	}

	###############################################
	# ::music::GetSongITunes                      #
	# ------------------------------------------- #
	# Gets the current playing song in ITunes     #
	###############################################
	proc GetSongITunes {} {
		
		#Get the variable we get in exec_async_mac and separate in multi lines
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			::music::log "Actualsong isn't yet defined by asynchronous exec"
			return 0
		}
		
		set status [lindex $tmplst 0]
		set song [lindex $tmplst 1]
		set art [lindex $tmplst 2]
		set path [lindex $tmplst 3]

		if {$status == "0"} {
			::music::log "Status is 0"
			return 0
		} else {
			#Define in which  order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
			if {$::music::config(songart) == 1} {
				append songart $song " " $::music::config(separator) " " $art
			} elseif {$::music::config(songart) == 2} {
				append songart $art " " $::music::config(separator) " " $song
			} elseif {$::music::config(songart) == 3} {
				append songart $song
			}
			lappend return $songart
			lappend return $path
		}
		return $return

	}

	###############################################
	# ::music::TreatSongWinamp                    #
	# ------------------------------------------- #
	# Gets the current playing song in WinAmp     #
	###############################################
	proc TreatSongWinamp {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list [file join $::music::musicpluginpath "MusicWA.exe"]]}
		return 0
	}

	###############################################
	# ::music::GetSongWinamp                      #
	# ------------------------------------------- #
	# Gets the current playing song in WinAmp     #
	###############################################
	proc GetSongWinamp {} {

		#actualsong is filled asynchronously in TreatSongWinamp
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}
		set status [lindex $tmplst 0]
		set song [lindex $tmplst 1]
		set art [lindex $tmplst 2]
		set path [lindex $tmplst 3]

		if {$status == "0"} {
			return 0
		} else {
			#Define in which  order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
			if {$::music::config(songart) == 1} {
				append songart $song " " $::music::config(separator) " " $art
			} elseif {$::music::config(songart) == 2} {
				append songart $art " " $::music::config(separator) " " $song
			} elseif {$::music::config(songart) == 3} {
				append songart $song
			}
			lappend return $songart
			lappend return $path
		}
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

		#Create label in submenu
		$copymenu.music add command -label [trans musiccurrent] -command "::music::menucommand $w 1"
		$copymenu.music add command -label [trans musicsend] -command "::music::menucommand $w 2"
		$copymenu.music add command -label [trans artsend] -command "::music::menucommand $w 3"

		::music::log "Music menu created"


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
		set artfile [lindex $info 2]

		if {$info == "0"} {
			msg_box [trans musicerr]
			return 0
		}


		switch -- $action {
			1 {
				#Send a message with the name of the current song
				::music::log "Send message with song name : [trans playing $song]"
				::amsn::MessageSend $win_name 0 "[trans playing $song]"	
			}
			2 {
				#Send the current song as a file
				::music::log "Send file with file $file"
				::amsn::FileTransferSend $win_name $file
				return 0
			}
			3 {
				#Send the full size version of the album cover as a file
				::music::log "Send file with file $artfile"				
				::amsn::FileTransferSend $win_name $artfile
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
		variable musicpluginpath
		variable smallcoverfilename
		variable dppath
		
		if {[array size ::music::playersarray]==0} {
			return
		}
		after cancel ::music::newname 0 0
		#Remove the song from the nick if we are online
		if {[::MSN::myStatusIs] != "FLN" && $activated } {
			if {[::config::getKey protocol] == 11} {
				::MSN::changeCurrentMedia Music 0 "{0}" ""
			} else {
				::music::changenick "$config(nickname)"
			}
	   	}

		#reset displaypicture
		if {$config(changepic) && [string compare [::config::getKey displaypic] $smallcoverfilename] == 0} {
			::music::set_dp $dppath
		}
	}

	proc DeInit {} {
		::music::stop 0 0
	}
	
	############################################
	# ::music::log message                     #
	# -----------------------------------------#
	# Add a log message to plugins-log window  #
	# Type Alt-P to get that window            #
	############################################
	proc log {message} {
		plugins_log Music $message
	}
	
	################################################
	# ::music::add_command                         #
	# -------------------------------------------  #
	# Add irc command /showsong and /sendsong      #
	# for amsnplus users						   #
	# Need last update of aMSNPlus plugin +/- 2.3  #
	# Verify first if amsnplus plugin is loaded    #
	################################################
	proc add_command {event evpar} {
		#If amsnplus plugin is loaded, register the command
		if { [info proc ::amsnplus::add_command] != "" } {
			#Avoid a bug if someone use an older version of aMSNPlus
			catch {::amsnplus::add_command showsong ::music::exec_show_command 0 1}
			catch {::amsnplus::add_command sendsong ::music::exec_send_command 0 1}
			catch {::amsnplus::add_command sendcover ::music::exec_sendcover_command 0 1}
		}
	}
	
	#Execute show current song via amsnplus plugin
	proc exec_show_command {win_name} {
		::music::menucommand $win_name 1
	}
	#Execute send current song via amsnplus plugin
	proc exec_send_command {win_name} {
		::music::menucommand $win_name 2
	}
	#Execute send current song via amsnplus plugin
	proc exec_sendcover_command {win_name} {
		::music::menucommand $win_name 3
	}

	#######################################################################
	# ::music::draw                                                       #
	# ------------------------------------------------------------------- #
	# Add an icon in the contact list to show/hide the song in the nick   #
	# Arguments:                                                          #
	#  event -> The event wich runs the proc (Supplied by Plugins System) #
	#  evPar -> The array of parameters (Supplied by Plugins System)      #
	#######################################################################
	proc draw {event evPar} {
		upvar 2 $evPar vars

		if {$::music::config(active)} {
			set icon musicshown_pic
		} else {
			set icon musichidden_pic
		}

		#TODO: add parameter to event and get rid of hardcoded variable
		set pgtop $::pgBuddyTop
		set clbar $::pgBuddyTop.colorbar

		set textb $pgtop.musicpic
		set notewidth [expr [image width [::skin::loadPixmap $icon]]/[font measure bboldf "0"]+1]
		set noteheight [expr [image height [::skin::loadPixmap $icon]]/[font metrics bboldf -linespace]+1]

		text $textb -font bboldf -height 1 -background [::skin::getKey topcontactlistbg] -borderwidth 0 -wrap none -cursor left_ptr \
			-relief flat -highlightthickness 0 -selectbackground white -selectborderwidth 0 \
			-exportselection 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0 -width $notewidth -height $noteheight

		pack $textb -expand false -after $clbar -side right -padx 0 -pady 0

		$textb configure -state normal

		clickableImage $textb musicpic $icon {set ::music::config(active) [expr !$::music::config(active)];::plugins::save_config;cmsn_draw_online} [::skin::getKey mailbox_xpad] [::skin::getKey mailbox_ypad]


		set balloon_message [trans musicballontext]

		$textb tag bind $textb.musicpic <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		$textb tag bind $textb.musicpic <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		$textb tag bind $textb.musicpic <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		$textb configure -state disabled
	}
	

}
