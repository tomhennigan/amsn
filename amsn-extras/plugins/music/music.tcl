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
		variable playersarray
		set musicpluginpath $dir

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
		::music::ConfigList

		#Start changing the nickname on loading
		::music::wait_load_newname
		#Register /showsong and /sendsong to 
		after 5000 ::music::add_command 0 0
	}
	
	#####################################################
	# ::music::LoadLangFiles dir                        #
	# ------------------------------------------------- #
	# Load pixmaps files                                #
	#####################################################
	proc LoadPixmaps {dir} {
		if {[string equal $::version "0.94"]} {
			::skin::setPixmap musicshown_pic [file join $dir pixmaps notespic.gif]
		} else {
			::skin::setPixmap musicshown_pic notespic.gif pixmaps [file join $dir pixmaps]
		}
		if {[string equal $::version "0.94"]} {
			::skin::setPixmap musichidden_pic [file join $dir pixmaps notesdispic.gif]
		} else {
			::skin::setPixmap musichidden_pic notesdispic.gif pixmaps [file join $dir pixmaps]
		}
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
	# ::music::LoadLangFiles dir       					#
	# ------------------------------------------------- #
	# Load lang files, only if version is 0.95			#
	# Because 0.94 do not support lang keys for plugins #
	#####################################################
	proc LoadLangFiles {dir} {
		if {![::music::version_094]} {
			set langdir [append dir "/lang"]
			set lang [::config::getGlobalKey language]
			load_lang en $langdir
			load_lang $lang $langdir
		}
	}
	########################################
	# ::music::ConfigArray                 #
	# -------------------------------------#
	# Add config array with default values #
	########################################	
	proc ConfigArray {} {
		variable playersarray
		
		#Use translation key for 0.95 users
		if {[::music::version_094]} {
			set stopmessage "Player stopped"
		} else {
			set stopmessage [trans musicstopdefault]
		}
		array set ::music::config [list \
			player [lindex [array names playersarray] 0] \
			nickname {} \
			second {30} \
			symbol {-} \
			stop $stopmessage \
			active {0} \
			songart {1} \
			separator {-} \
		]
		
	}
	########################################
	# ::music::ConfigList                  #
	# -------------------------------------#
	# Add items to configure window        #
	########################################		
	proc ConfigList {} {
	variable playersarray
	
		if {[::music::version_094]} {
			set ::music::configlist [list \
				[list str "Verify new song each ? seconds" second] \
				[list bool "Add song to the nickname"  active] \
				[list str "Nickname"  nickname] \
				[list str "Symbol betwen nick and song"  symbol] \
				[list str "Stopped message"  stop] \
				[list str "Separator" separator] \
			]
		} else {
			if { [::config::getKey protocol] == 11 } {
				set ::music::configlist [list \
					[list label "[trans musicplayer]"] \
					[list lst [array names playersarray] player] \
					[list str "[trans musictimeverify]" second] \
					[list bool "[trans musicaddsongtopsm]"  active] \
					[list label "[trans choose_order]"] \
					[list rbt "[trans songartist]" "[trans artistsong]" songart] \
					[list str "[trans separator]" separator] \
				]
			} else {
				set ::music::configlist [list \
					[list label "[trans musicplayer]"] \
					[list lst [array names playersarray] player] \
					[list str "[trans musictimeverify]" second] \
					[list bool "[trans musicaddsongtonick]"  active] \
					[list str "[trans musicnickname]"  nickname] \
					[list str "[trans musicseparator]"  symbol] \
					[list str "[trans musicstopmsg]"  stop] \
					[list label "[trans choose_order]"] \
					[list rbt "[trans songartist]" "[trans artistsong]" songart] \
					[list str "[trans separator]" separator] \
				]
			}
		}
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
				"ITunes" [list GetSongITunes exec_applescript] \
			] \
			"linux" [list \
				"XMMS" [list GetSongXMMS TreatSongXMMS] \
				"Amarok" [list GetSongAmarok TreatSongAmarok] \
				"Totem" [list GetSongTotem TreatSongTotem] \
			] \
			"windows nt" [list \
				"WinAmp" [list GetSongWinamp TreatSongWinamp] \
			] \
			"windows 95" [list \
				"WinAmp" [list GetSongWinamp TreatSongWinamp] \
			] \
		]
		#Get current OS platform
		set os [string tolower $tcl_platform(os)]
		#If the OS is not supported show message box error and unload plugin
		if { ![info exists OSes($os) ] } {
			#Show message box error
			if { [::music::version_094] } {
				msg_box "Your Operating System ($os) isn't yet supported by the music plugin"
			} else {
				msg_box [trans musicoserr $os]
			}
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
		if {$config(active) && $name != $oldname } {
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


		if {$status == "0"} {
			return 0
		} else {
			#Define in witch order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
			if {$::music::config(songart) == 1} {
				append songart $song " " $::music::config(separator) " " $art
			} elseif {$::music::config(songart) == 2} {
				append songart $art " " $::music::config(separator) " " $song
			}
			lappend return $songart
			lappend return [urldecode [string range $path 5 end]]
		}
		return $return
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
			#Define in witch order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
#			if {$::music::config(songart) == 1} {
#				append songart $song " " $::music::config(separator) " " $art
#			} elseif {$::music::config(songart) == 2} {
#				append songart $art " " $::music::config(separator) " " $song
#			}
#			lappend return $songart
#			lappend return [urldecode [string range $path 5 end]]
			return $song
		}
#		return $return
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
			#Define in witch order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
			if {$::music::config(songart) == 1} {
				append songart $song " " $::music::config(separator) " " $art
			} elseif {$::music::config(songart) == 2} {
				append songart $art " " $::music::config(separator) " " $song
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
			#Define in witch order we want to show the song (from the config)
			#Use the separator(from the cong) betwen song and artist
			if {$::music::config(songart) == 1} {
				append songart $song " " $::music::config(separator) " " $art
			} elseif {$::music::config(songart) == 2} {
				append songart $art " " $::music::config(separator) " " $song
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

		if {[::music::version_094]} {
			#Create label in submenu
			$copymenu.music add command -label [trans xmmscurrent] -command "::music::menucommand $w 1"
			$copymenu.music add command -label [trans xmmssend] -command "::music::menucommand $w 2"
		} else {
			#Create label in submenu
			$copymenu.music add command -label [trans musiccurrent] -command "::music::menucommand $w 1"
			$copymenu.music add command -label [trans musicsend] -command "::music::menucommand $w 2"
		}
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
				::music::log "Send message with song name : [trans playing $song]"
				::amsn::MessageSend $win_name 0 "[trans playing $song]"	
			}
			2 {
				#Send the current song as a file
				::music::log "Send file with file $file"
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
			if {[::config::getKey protocol] == 11} {
				::MSN::changeCurrentMedia Music 0 "{0}" ""
			} else {
				::music::changenick "$config(nickname)"
			}
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
	
	############################################
	# ::music::log message                     #
	# -----------------------------------------#
	# Add a log message to plugins-log window  #
	# Type Alt-P to get that window            #
	# Not compatible with 0.94                 #
	############################################
	proc log {message} {
		if {[::music::version_094]} {
			return
		} else {
			plugins_log Music $message
		}
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

		if {[string equal $::version "0.94"]} {
			set textb $vars(text)

			clickableImage $textb musicpic $icon {set ::music::config(active) [expr !$::music::config(active)];::plugins::save_config;cmsn_draw_online} 5 0
		} else {
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

		}

		if {[::music::version_094]} {
			set balloon_message "Click here to show/hide the song in your nick"
		} else {
			set balloon_message [trans musicballontext]
		}

		bind $textb.musicpic <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		bind $textb.musicpic <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		bind $textb.musicpic <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		$textb configure -state disabled
	}

}
