namespace eval ::music {
	variable config
	variable configlist
	variable name ""
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
		variable dppath
		variable playersarray
		variable oldinfo
		variable lastafter
		variable lasterror

		set musicpluginpath $dir
		
		global tcl_platform
		switch $tcl_platform(platform) {
		unix {
			set tmpdir /tmp
		} macintosh {
			set tmpdir $::env(TRASH_FOLDER)
		} default {
			set tmpdir [pwd]
			catch {set tmpdir $::env(TMP)}
			catch {set tmpdir $::env(TEMP)}
		}
		}
		set smallcoverfilename [file join $tmpdir amsn_albumart.jpg]
		set dppath ""
		set oldinfo [list]
		set lastafter ""

		#Load translation keys (lang files)
		::music::LoadLangFiles $dir
		
		::music::LoadPixmaps $dir

		::music::PrepareDLL $dir

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

		set lasterror ""

		#Start changing the nickname on loading
		after 1000 ::music::load_newname 0 0
		#Register /showsong and /sendsong to 
		after 5000 ::music::add_command 0 0

	}

	
	proc populateFrame_1st { win_name } {
		variable playersarray
		frame $win_name.players -class Degt
		label $win_name.players.question -text "[trans musicplayer]" -padx 5 -font sboldf
		pack $win_name.players $win_name.players.question
		if { [llength [array names playersarray] ] > 1} {	
			ComboBox $win_name.players.selection -editable false -highlightthickness 0 \
				-width 15 -font splainf -textvariable ::music::config(player) \
				-values [array names playersarray] -modifycmd "::music::populateFrame_2nd ${win_name}"
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

		#error
		frame $mainFrame.lasterror -class degt
		label $mainFrame.lasterror.label -text "[trans lasterror] :" -padx 5 -font sboldf
		label $mainFrame.lasterror.errorval -textvariable ::music::lasterror -font splainf
		pack $mainFrame.lasterror.label -anchor w -side left
		pack $mainFrame.lasterror.errorval -anchor w -side left -fill x
		pack $mainFrame.lasterror -anchor w -expand true -fill x

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
			checkbutton $mainFrame.psm.checkbutton -variable ::music::config(display) -text "[trans musicaddsongtopsm]"
			pack $mainFrame.psm.checkbutton -anchor w 
		} else {
			#add to nick
			frame $mainFrame.add2nick -class degt
			pack $mainFrame.add2nick -anchor w -expand true -fill both
			checkbutton $mainFrame.add2nick.checkbutton -variable ::music::config(display) -text "[trans musicaddsongtonick]"
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

	proc PrepareDLL {dir} {
		global tcl_platform
		set os [string tolower $tcl_platform(os)]
		if { $os == "windows 95" || $os == "windows nt" } {
			catch {file copy -force [file join $dir "MusicWin.dll"] [file join $dir "MusicWin.tmp"]}
		}
	}

	#####################################
	# ::music::RegisterEvent            #
	# --------------------------------- #
	# Register events to plugin system  #
	#####################################	
	proc RegisterEvent {} {
		::plugins::RegisterEvent "Music" OnConnect newname
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
			oldnickname {}\
			nickname {} \
			second {30} \
			symbol {-} \
			stop $stopmessage \
			activated {1} \
			display {1} \
			songart {1} \
			display_style {%title - %artist} \
			changepic {0} \
			mpd_ip {127.0.0.1} \
			mpd_port {6600} \
			mpd_music_directory {} \
			mpd_password {} \
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
		if {[OnMac]} {
			array set playersarray [list \
				"ITunes" [list GetSongITunes TreatSongITunes FillFrameComplete] \
				"Cog" [list GetSongCog TreatSongCog FillFrameLess] \
			]
		} else {
			if {[OnUnix]} {
				array set playersarray [list \
					"Amarok" [list GetSongAmarok TreatSongAmarok FillFrameComplete] \
					"Amarok2" [list GetSongAmarok2 TreatSongAmarok2 FillFrameComplete] \
					"Audacious" [list GetSongAudacious TreatSongAudacious FillFrameLess] \
					"Banshee" [list GetSongBanshee TreatSongBanshee FillFrameComplete] \
					"Exaile" [list GetSongExaile TreatSongExaile FillFrameLess] \
					"Juk" [list GetSongJuk TreatSongJuk FillFrameLess] \
					"Juk-KDE4" [list GetSongJuk2 TreatSongJuk2 FillFrameLess] \
					"LastFM" [list GetSongLastFM TreatSongLastFM FillFrameLess] \
					"Listen" [list GetSongListen TreatSongListen FillFrameLess] \
					"MPD" [list GetSongMPD return FillFrameMPD] \
					"QuodLibet" [list GetSongQL TreatSongQL FillFrameLess] \
					"Rhythmbox" [list GetSongRhythmbox TreatSongRhythmbox FillFrameLess] \
					"Songbird" [list GetSongSongbird TreatSongSongbird FillFrameLess] \
					"XMMS" [list GetSongXMMS return FillFrameEmpty] \
				]
			} else {
				if {[OnWin]} {
					array set playersarray [list \
						"iTunes" [list GetSongiTunesWin return FillFrameLess] \
						"WinAmp" [list GetSongWinamp return FillFrameLess] \
						"Windows Media Player" [list GetSongWMP return FillFrameLess] \
						"MPD" [list GetSongMPD return FillFrameMPD] \
					]
				} else {
					#Show message box error
					msg_box [trans musicoserr $os]
					#Unload plugin
					::plugins::UnLoadPlugin "Music"
					return 0
				}
			}
		}

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
		variable oldinfo
		variable dppath
		variable lastafter
		if { $::music::config(activated) } {
			#Get all song information from ::music::GetSong
			set info [::music::GetSong]

			set song [lindex $info 0]
			set artist [lindex $info 1]
			set file [lindex $info 2]
			set artfile [lindex $info 3]
			set album [lindex $info 4]

			#First add the nickname the user choosed in config to the name variable
			set name "$config(nickname)"

			# xmms only gives us a string describing song+artist
			if { $config(player)== "XMMS" } {
				set config(display_style) {%title}
			}

			#Change the nickname if the user didn't uncheck that config.
			if {$config(display) && ![string equal $info $oldinfo] } {
				if {[::config::getKey protocol] >= 11} {
					if { $song != "0"} {
						# Convert our formatting string into the .NET-format one.
						set style [string map {"%title" "{0}" "%artist" "{1}" "%album" "{2}"} $config(display_style)]
						#::music::log $style
						::MSN::changeCurrentMedia Music 1 $style $song $artist $album
					} else {
						::MSN::changeCurrentMedia Music 0 "{0}" ""
					}
				} else {
					set style [string map {"%title" "$song" "%artist" "$artist" "%album" "$album"} $config(display_style)]
					set style [subst $style]
					append name $style
					::music::changenick "$name"
				}
			}

			if {$config(changepic) && ![string equal $info $oldinfo]} {
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
					if { [catch {::picture::ResizeWithRatio [image create photo smallcover -file $artfile] 96 96} err]} {
						::music::log "error while resing $artfile : $err"
					}

					if {[catch {::picture::Save smallcover $smallcoverfilename cxjpg} err]} {
						::music::log "error while saving small cover to $smallcoverfilename : $err"
					} else {
						::music::log "Album art found, changing..."
						::music::set_dp $smallcoverfilename
					}

				} else {
					#if the album cover isn't available, set the dp the user set before changes by musicplugin
					::music::log "No album art found, use \"$dppath\""
					
					::music::set_dp $dppath

				}
			}
			if {!$config(changepic) && \
				[string compare [::config::getKey displaypic] $smallcoverfilename] == 0} {
				#Config disabled : change the dp to the good one...
				::music::set_dp $dppath
			}

			set oldinfo $info

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

		if { [catch {after info $lastafter}] } {
			#Reload newname proc after this time (loop)
			set lastafter [after $time ::music::newname 0 0]
		}

	}

	###############################################
	# ::music::changenick name                    #
	# ------------------------------------------- #
	# Protocol to change the nickname             #
	###############################################
	proc changenick {name} {
		if {[info args ::MSN::changeName] == [list "newname" "update"] } {
			::MSN::changeName $name
		} else {
			set email [::config::getKey login]
			::MSN::changeName $email $name
		}
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
		variable lasterror
		if {![info exists playersarray($config(player))] } {
			::music::log "Player not supported by Music plugin"
			return 0
		}
		set songfunc $playersarray($config(player))
		set error [catch {::music::[lindex $songfunc 0]} retval]
		::music::log "Get song: $retval"
		if { $error } {
			set lasterror $retval
			return 0
		} else {
			set lasterror [trans noerror]
			return $retval
		}
	}

	proc TreatSong {} {
		variable config
		variable playersarray
		if {![info exists playersarray($config(player))] } {
			return 0
		}
		set songfunc $playersarray($config(player))
		set retval 0
		catch {::music::[lindex $songfunc 1]}
	}

	proc FillFrame { mainFrame } {
		variable config
		variable playersarray
		if {![info exists playersarray($config(player))] } {
			return 0
		}
		set songfunc $playersarray($config(player))
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
	# Execute the specified path with osascript         #
	# and store the result  in actualsong.              #
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
		set artist [lindex $info 1]
		set file [lindex $info 2]
		set artfile [lindex $info 3]
		set album [lindex $info 4]

		if {$info == "0"} {
			msg_box [trans musicerr]
			return 0
		}


		switch -- $action {
			1 {
				#Send a message with the name of the current song
				set msg [string map {"%title" "$song" "%artist" "$artist" "%album" "$album"} $::music::config(display_style)]
				set msg [subst $msg]
				::music::log "Send message with song name : [trans playing $msg]"
				::amsn::MessageSend $win_name 0 "[trans playing $msg]"	
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
	# ::music::load_newname  event epvar          #
	# ------------------------------------------- #
	# Start changing the nick                     #
	# If we load the plugin while we were already #
	# connected, start changing the nick, else do #
	# nothing                                     #
	###############################################
	proc load_newname {event epvar} {
		variable oldinfo
		variable lastafter
		#If we are online, start the loop
		if {[::MSN::myStatusIs] != "FLN" } {
			if { $::music::config(display) } {
				if {[::config::getKey protocol] >= 11} {
					::MSN::changeCurrentMedia Music 0 "{0}" ""
				} else {
					set nick [::abook::getPersonal MFN]
					if { ![string equal $nick $::music::config(oldnickname)] && !$::music::config(activated)} {
						set config(oldnickname) $nick
					}
				}
			}
			set ::music::config(activated) 1
			set oldinfo ""
			::music::draw 0 0
			::plugins::save_config
			after cancel $lastafter
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
	proc stop {event epvar {deinit 0}} {
		variable config
		variable musicpluginpath
		variable smallcoverfilename
		variable dppath
		variable oldinfo
		variable lastafter

		if {[array size ::music::playersarray]==0} {
			return
		}

		#Remove the song from the nick if we are online
		if {[::MSN::myStatusIs] != "FLN" && $::music::config(activated) } {
			if {[::config::getKey protocol] >= 11} {
				::MSN::changeCurrentMedia Music 0 "{0}" ""
			} else {
				::music::changenick "$config(oldnickname)"
			}
	   	}

		#reset displaypicture
		if {$config(changepic) && [string compare [::config::getKey displaypic] $smallcoverfilename] == 0} {
			::music::set_dp $dppath
		}
		if {!$deinit} {
			set ::music::config(activated) 0
			::music::draw 0 0
			::plugins::save_config
		}

		if {$deinit} {
			after cancel $lastafter
		}

		set oldinfo ""
	}

	proc DeInit {} {
		::music::stop 0 0 1
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
		if {$event != 0} { upvar 2 $evPar vars }

		if {$::music::config(display)} {
			set icon musicshown_pic
		} else {
			set icon musichidden_pic
		}
		

		#TODO: add parameter to event and get rid of hardcoded variable
		set pgtop $::pgBuddyTop
		set clbar $::pgBuddyTop.colorbar

		set mylabel $pgtop.picmusic
		if {[winfo exists $mylabel]} {
			destroy $mylabel			
		}
		
		set notewidth [image width [::skin::loadPixmap $icon]]
		set noteheight [image height [::skin::loadPixmap $icon]]

		label $mylabel -image [::skin::loadPixmap $icon] -background [::skin::getKey topcontactlistbg] -borderwidth 0 -cursor left_ptr \
			-relief flat -highlightthickness 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0 -width $notewidth -height $noteheight

		pack $mylabel -expand false -after $clbar -side right -padx 0 -pady 0

		if {$::music::config(display)} {
			bind $mylabel <<Button1>> "set ::music::config(display) 0; ::music::stop 0 0"
		} else {
			bind $mylabel <<Button1>> "set ::music::config(display) 1; ::music::load_newname 0 0"
		}

		#bind $mylabel <<Button1>> "set ::music::config(activated) [expr !$::music::config(activated)];::plugins::save_config;::music::draw 0 0"

		set balloon_message [trans musicballontext]
		
		bind $mylabel <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		bind $mylabel <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		bind $mylabel <Motion> +[list balloon_motion %W %X %Y $balloon_message]
	}	
	
	proc encrypt { password } {
		if {[info proc "::DES::des"] == "::DES::des"} {
			binary scan [::DES::des -mode ecb -dir encrypt -key pasencky "${password}\n"] h* encpass
		} else {
			binary scan [::des::encrypt pasencky "${password}\n"] h* encpass
		}
		return $encpass
	}

	proc decrypt { key } {
		if {[info proc "::DES::des"] == "::DES::des"} {
			set password [::DES::des -mode ecb -dir decrypt -key pasencky [binary format h* $key]]
		} else {
			set password [::des::decrypt pasencky [binary format h* $key]]
		}
		set password [string range $password 0 [expr { [string first "\n" $password] -1 }]]
		return $password
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
		menubutton $mainFrame.order.menubutton -font sboldf -text "<-" -menu $mainFrame.order.menubutton.menu
		menu $mainFrame.order.menubutton.menu -tearoff 0
			$mainFrame.order.menubutton.menu add command -label "%artist" -command "$mainFrame.order.style_entry insert insert %artist"
			$mainFrame.order.menubutton.menu add command -label "%title" -command "$mainFrame.order.style_entry insert insert %title"
			$mainFrame.order.menubutton.menu add command -label "%album" -command "$mainFrame.order.style_entry insert insert %album"
		label $mainFrame.order.style_label -text "[trans style]" -padx 5 -font sboldf
		entry $mainFrame.order.style_entry -bg #ffffff -width 20 -textvariable ::music::config(display_style)
		pack $mainFrame.order.style_label \
				$mainFrame.order.style_entry \
				$mainFrame.order.menubutton \
				-anchor w -side left
	
		#changepic
		frame $mainFrame.changepic -class degt
		pack $mainFrame.changepic -anchor w -expand true -fill both
		checkbutton $mainFrame.changepic.checkbutton -variable ::music::config(changepic) -text "[trans changepic]"
		pack $mainFrame.changepic.checkbutton -anchor w
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
		menubutton $mainFrame.order.menubutton -font sboldf -text "<-" -menu $mainFrame.order.menubutton.menu
		menu $mainFrame.order.menubutton.menu -tearoff 0
			$mainFrame.order.menubutton.menu add command -label "%artist" -command "$mainFrame.order.style_entry insert insert %artist"
			$mainFrame.order.menubutton.menu add command -label "%title" -command "$mainFrame.order.style_entry insert insert %title"
			$mainFrame.order.menubutton.menu add command -label "%album" -command "$mainFrame.order.style_entry insert insert %album"
		label $mainFrame.order.style_label -text "[trans style]" -padx 5 -font sboldf
		entry $mainFrame.order.style_entry -bg #ffffff -width 20 -textvariable ::music::config(display_style)
		pack $mainFrame.order.style_label \
				$mainFrame.order.style_entry \
				$mainFrame.order.menubutton \
				-anchor w -side left
	}

	###############################################
	# ::music::FillFrameEmpty                     #
	# ------------------------------------------- #
	# Fills the config frame with nothing         #
	###############################################
	proc FillFrameEmpty {mainFrame} {

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
		menubutton $mainFrame.order.menubutton -font sboldf -text "<-" -menu $mainFrame.order.menubutton.menu
		menu $mainFrame.order.menubutton.menu -tearoff 0
			$mainFrame.order.menubutton.menu add command -label "%artist" -command "$mainFrame.order.style_entry insert insert %artist"
			$mainFrame.order.menubutton.menu add command -label "%title" -command "$mainFrame.order.style_entry insert insert %title"
			$mainFrame.order.menubutton.menu add command -label "%album" -command "$mainFrame.order.style_entry insert insert %album"
		label $mainFrame.order.style_label -text "[trans style]" -padx 5 -font sboldf
		entry $mainFrame.order.style_entry -bg #ffffff -width 20 -textvariable ::music::config(display_style)
		pack $mainFrame.order.style_label \
				$mainFrame.order.style_entry \
				$mainFrame.order.menubutton \
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

		#password
		frame $mainFrame.password
		label $mainFrame.password.label -text "[trans music_mpd_password]"
		entry $mainFrame.password.entry -show "*" -bg white -width 15 -validate all \
			-validatecommand {
				set ::music::config(mpd_password) [::music::encrypt %P]
				return 1
			}
		$mainFrame.password.entry insert end [::music::decrypt $::music::config(mpd_password)]
		pack $mainFrame.password -anchor w
		pack $mainFrame.password.label $mainFrame.password.entry -anchor w

	}

	################################################
	# ::music::TreatSongAmarok 2                   #
	# -------------------------------------------  #
	# Gets the current playing song in Amarok 2    #
	################################################
	proc TreatSongAmarok2 {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "bash" [file join $::music::musicpluginpath "infoamarok2"]] }
	}
	
	################################################
	# ::music::GetSongAmarok2                      #
	# -------------------------------------------  #
	# Gets the current playing song in Amarok2     #
	################################################
	proc GetSongAmarok2 {} {

		#actualsong is filled asynchronously in TreatSongAmarok
		#Split the lines into a list and set the variables as appropriate
		
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}

		#Get the information
		set status [lindex $tmplst 0]
		set art [lindex $tmplst 1]
		set song [lindex $tmplst 2]
	        set path [lindex $tmplst 3]
		set artpath [lindex $tmplst 4]
		set album [lindex $tmplst 5]
		if {[string first "nocover" [file tail $artpath]] != -1} {set artpath "" }	
		if {$status == "0"} {
			return 0
		}



		return [list $song $art $path $artpath $album]
	}

	###############################################
	# ::music::TreatSongAmarok                    #
	# ------------------------------------------- #
	# Gets the current playing song in Amarok     #
	###############################################
	proc TreatSongAmarok {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "infoamarok"]] }
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

		#Get the information
		set status [lindex $tmplst 0]
		set song [lindex $tmplst 1]
		set art [lindex $tmplst 2]
		set path [lindex $tmplst 3]
		set artpath [lindex $tmplst 4]
		set album [lindex $tmplst 5]
		
		if {[string first "nocover" [file tail $artpath]] != -1} { set artpath "" }

		if {$status == "0"} {
			return 0
		}
		
		if { ![string compare -nocase [string range $path 0 4] "file:"] } {
			set path [urldecode [string range $path 7 end]]
		} else {
			set path ""
		}

		return [list $song $art $path $artpath $album]
	}

	###############################################
	# ::music::TreatSongAudacious                 #
	# ------------------------------------------- #
	# Gets the current playing song in Audacious  #
	###############################################
	proc TreatSongAudacious {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "infoaudacious"]] }
	}

	###############################################
	# ::music::GetSongAudacious                   #
	# ------------------------------------------- #
	# Gets the current playing song in Audacious  #
	###############################################
	proc GetSongAudacious {} {
		#actualsong is filled asynchronously in TreatSongAudacious
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

		if {$status == "0" || $status == "stopped"} {
			return 0
		}
		
		if { ![file exists $path] } {
			set path ""
		}
		
		return [list $song $art $path "" ""]
	}

	###############################################
	# ::music::TreatSongBanshee                   #
	# ------------------------------------------- #
	# Gets the current playing song in Banshee    #
	###############################################
	proc TreatSongBanshee {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "infobanshee"]] }
	}

	###############################################
	# ::music::GetSongBanshee                     #
	# ------------------------------------------- #
	# Gets the current playing song in Banshee    #
	###############################################
	proc GetSongBanshee {} {
		#actualsong is filled asynchronously in TreatSongBanshee
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}
		
		if {[lindex $tmplst 0] == 0} {
			return 0
		}

		append Title [lindex $tmplst 1]
		append Artist [lindex $tmplst 2]
		append Uri [lindex $tmplst 3]
		append CoverUri [lindex $tmplst 4]

		set Uri [urldecode [string range $Uri 7 end]]

		return [list $Title $Artist $Uri $CoverUri ""]
	}

	###########################################################
	# ::music::TreatSongLastFM                                #
	# ------------------------------------------------------- #
	# Gets the current playing song in LastFM                 #
	###########################################################
	proc TreatSongLastFM {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "infolastfm"]] }
	}

	###########################################################
	# ::music::GetSongLastFM                                  #
	# ------------------------------------------------------- #
	# Gets the current playing song in LastFM                 #
	###########################################################
	proc GetSongLastFM {} {
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}

		#Get the 4 first lines
		set status [lindex $tmplst 0]
		set artist [lindex $tmplst 1]
		set song [lindex $tmplst 2]
		
		#$artist=="Last.fm" when lastfm is stopped
		if { $status == "0" || ($song == "" && $artist == "Last.fm") } {	
			return 0
		}
	
		return [list $song $artist "" "" ""]
	}

	  ###########################################################
	  # ::music::TreatSongJuk2                                  #
	  # ------------------------------------------------------- #
	  # Gets the current playing song in KDE4 version of Juk    #
	  ###########################################################
	  proc TreatSongJuk2 {} {
		  #Grab the information asynchronously : thanks to copyleft
		  after 0 {::music::exec_async [list "bash" [file join $::music::musicpluginpath "infojuk2"]] }
	  }
	  
	  ###########################################################
	  # ::music::GetSongJuk2                                    #
	  # ------------------------------------------------------- #
	  # Gets the current playing song in KDE4 version of Juk    #
	  ###########################################################
	  proc GetSongJuk2 {} {
		  #Split the lines into a list and set the variables as appropriate
		  if { [catch {split $::music::actualsong "\n"} tmplst] } {
			  #actualsong isn't yet defined by asynchronous exec
			  return 0
		  }

		  #Get the 4 first lines
		  set status [lindex $tmplst 0]
		  set artist [lindex $tmplst 1]
		  set title [lindex $tmplst 2]
		  
		  if {$status == "0"} {
			  return 0
		  }
		  if {$status == "1"} {
			  append title " (Paused)"
		  }

		  # !!! Was this unneeded in the first place?
		  #append newPath "file://" $path ;
		  #lappend return  [urldecode [string range $newPath 5 end]]

		  # !!! This is bad.
		  return [list $title $artist]
	  }

	 ###########################################################
	 # ::music::TreatSongJuk                                   #
	 # ------------------------------------------------------- #
	 # Gets the current playing song in Juk                    #
	 ###########################################################
	 proc TreatSongJuk {} {
		#Grab the information asynchronously : thanks to copyleft
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "infojuk"]] }
	}

	###########################################################
	# ::music::GetSongJuk                                     #
	# ------------------------------------------------------- #
	# Gets the current playing song in juk                    #
	###########################################################
	proc GetSongJuk {} {
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}

		#Get the 4 first lines
		set status [lindex $tmplst 0]
		set songart [lindex $tmplst 1]
		set path [lindex $tmplst 2]
		
		if {$status == "0"} {
			return 0
		}
		if {$status == "1"} {
			append songart "Paused"
		}

		# !!! Was this unneeded in the first place?
		#append newPath "file://" $path ;
		#lappend return  [urldecode [string range $newPath 5 end]]

		# !!! This is bad.
		return [list $songart "" $path "" ""]
	}

	###############################################
	# ::music::TreatSongExaile                    #
	# ------------------------------------------- #
	# Gets the current playing song in Exaile     #
	###############################################
	proc TreatSongExaile {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "infoexaile"]] }
	}

	###############################################
	# ::music::GetSongExaile                      #
	# ------------------------------------------- #
	# Gets the current playing song in Exaile     #
	###############################################
	proc GetSongExaile {} {
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}

		#Get the 6 first lines
		set path "none"
		set status [lindex $tmplst 0]
		set song [lindex $tmplst 1]
		set art [lindex $tmplst 2]
		set album [lindex $tmplst 3]
		set songlength [lindex $tmplst 4]
		set position [lindex $tmplst 5]

		# Path not available in exile
		#append newPath "file://" $path
		
		if {$status != "playing"} {
			return 0
		}
		
		return [list $song $art $path "" ""]
	}

	###############################################
	# ::music::TreatSongListen                    #
	# ------------------------------------------- #
	# Gets the current playing song in Listen     #
	###############################################
	proc TreatSongListen {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [file join $::music::musicpluginpath "infolisten"]}
	}

	###############################################
	# ::music::GetSongListen                      #
	# ------------------------------------------- #
	# Gets the current playing song in Listen     #
	###############################################
	proc GetSongListen {} {
		#check if actualsong is already defined by asynchronous exec
		if {![info exists ::music::actualsong]} {
			return 0
		}

		plugins_log music "Actual song is :$::music::actualsong"
		set return [list]
		set Title ""
		set Artist ""
		if {[regexp {(.*) \- \(.* \- (.*)\)} $::music::actualsong -> Title Artist]} {
			return [list $Title $Artist "" "" ""]
		}
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
			close $chan
			return 0
		}
		if {[string range $line 0 1] != "OK" } {
			plugins_log Music "error : [MPD] no OK found "
			close $chan
			return 0
		}

		if { [string length [::music::decrypt $::music::config(mpd_password)]] > 0 } {
			puts $chan "password [::music::decrypt $::music::config(mpd_password)]"
			flush $chan
			
			if { [catch {gets $chan line} err] } {
				plugins_log Music "error : $err"
				close $chan
				return 0
			}
			if { [string range $line 0 1] != "OK" } {
				plugins_log Music "error: $line"
				close $chan
				return 0
			}
		}

		puts $chan "status"
		flush $chan
		if { [catch {gets $chan line} err] } {
			plugins_log Music "error : $err"
			close $chan
			return 0
		}
		if { [string range $line 0 2] == "ACK"} {
		    plugins_log Music "error: $line"
		    close $chan
		    return 0
		}

		while {[string range $line 0 1] != "OK" } {
			if { [string range $line 0 4] == "state" } {
				set state [string range $line 7 end]
				plugins_log Music "state of the player is $state"
				if { $state == "stop" || $state == "pause" } {
					close $chan
					return 0
				}
			}
			if { [catch {gets $chan line} err] } {
				plugins_log Music "error : $err"
				close $chan
				return 0
			}		
		}
		#Finish getting infos from status command
		while {[string range $line 0 1] != "OK" } {
			if { [catch {gets $chan line} err] } {
				plugins_log Music "error : $err"
				close $chan
				return 0
			}		
		}
		#now, get the currentsong
		puts $chan "currentsong"
		flush $chan
		if { [catch {gets $chan line} err] } {
			plugins_log Music "error : $err"
			close $chan
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
				close $chan
				return 0
			}		
		}
		
		return [list $Title $Artist "" "" ""]
		
		close $chan
		return $return
	}

	##################################################
	# ::music::TreatSongQL                           #
	# ---------------------------------------------- #
	# Gets the current playing song in Totem         #
	##################################################
	proc TreatSongQL {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "quodlibet" "--status"]}
	}

	###############################################
	# ::music::GetSongQL                          #
	# ------------------------------------------- #
	# Gets the current playing song in QL         #
	###############################################
	proc GetSongQL {} {
		if {![info exists ::music::actualsong]} {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}
		if { [string compare "playing " [string range $::music::actualsong 0 8]]} {
			if { [catch {open ~/.quodlibet/current "r"} file_]} {
				plugins_log music "\nerror: $file_\n"
				return 0
			}
			set Title ""
			set Artist ""
			set File ""
			set textline ""
			gets $file_ textline
			while {[eof $file_] != 1} {
				regexp {title=(.*)} $textline -> Title
				regexp {artist=(.*)} $textline -> Artist
				regexp {~filename=(.*)} $textline -> File
				gets $file_ textline
			}
			close $file_
			if {$Title == "" && $File != ""} {
				set Title [getfilename $File]
			}
			
			return [list $Title $Artist $File "" ""]
		} else {
			return 0
		}
	}

	###############################################
	# ::music::TreatSongRhythmbox                 #
	# ------------------------------------------- #
	# Gets the current playing song in Rhythmbox  #
	###############################################
	proc TreatSongRhythmbox {} {
		#Grab the information asynchronously : thanks to Tjikkun
		after 0 {::music::exec_async [list "sh" [file join $::music::musicpluginpath "inforhythmbox"]] }
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
		if { [llength $tmplst] == 3 } {
			set song [lindex $tmplst 0]
			set art ""
			set path [lindex $tmplst 1]
			if { $song == "" } {
				set songlength "-1"
			} else {
				set songlength "0"
			}
		} else {
			set song [lindex $tmplst 0]
			set art [lindex $tmplst 1]
			set path [lindex $tmplst 2]
			set songlength [lindex $tmplst 3]
		}
		
		#$song=="Not playing" if rhythmbox has reached the end of the playlist
		if {$songlength == "-1" || $song == "Not playing"} {
			return 0
		}
		
		set path [urldecode [string range $path 5 end]]
		
		return [list $song $art $path "" ""]
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
				"Playing" { set return_lst [list $info(Title:) "" $info(File:) "" ""] }
				"Paused" { set return_lst [list $info(Title:); "" return $info(File:) "" ""] }
				"Stopped" { set return_lst 0 }
				default { set return_lst 0] }
			}
			return $return_lst
		}
		return 0
	}

	################################################
	# ::music::TreatSongITunes                     #
	# -------------------------------------------  #
	# Execute the applescript to get actual song   #
	# Osascript: Command to execute AppleScript    #
	# Find where's the plugin directory(by getKey) #
	################################################
	proc TreatSongITunes {} {
		after 0 {::music::exec_async_mac [file join $::music::musicpluginpath display_and_send.scpt]}
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
		set artfile [lindex $tmplst 4]

		if {$status == "0"} {
			::music::log "Status is 0"
			return 0
		}
		
		return [list $song $art $path $artfile ""]
	}
	

	###############################################
	# ::music::GetSongWinamp                      #
	# ------------------------------------------- #
	# Gets the current playing song in WinAmp     #
	###############################################
	proc GetSongWinamp {} {
		variable musicpluginpath
		load [file join $musicpluginpath MusicWin.tmp]
		set tmplst [::music::TreatSongWinamp]

		set status [lindex $tmplst 0]
		set song [lindex $tmplst 1]
		set art [lindex $tmplst 2]
		set path [lindex $tmplst 3]

		if {$status == "0"} {
			return 0
		}
		
		return [list $song $art $path "" ""]
	}

	###############################################
	# ::music::GetSongiTunesWin                   #
	# ------------------------------------------- #
	# Gets the current playing song in iTunes(Win)#
	###############################################
	proc GetSongiTunesWin {} {
		variable musicpluginpath
		load [file join $musicpluginpath MusicWin.tmp]
		set tmplst [::music::TreatSongiTunes]

		set status [lindex $tmplst 0]
		set art [lindex $tmplst 1]
		set song [lindex $tmplst 2]
		set album [lindex $tmplst 3]

		if {$status == "0"} {
			return 0
		}
		
		return [list $song $art "" "" $album]
	}

	###############################################
	# ::music::GetSongWMP                         #
	# ------------------------------------------- #
	# Gets the current playing song in WinAmp     #
	###############################################
	proc GetSongWMP {} {
		variable musicpluginpath
		load [file join $musicpluginpath MusicWin.tmp]
		set tmplst [string map {"\\0" "\0"} [::music::TreatSongWMP]]
		set tmplst [split $tmplst "\0"]

		set type [lindex $tmplst 1]
		set art [lindex $tmplst 4]
		set song [lindex $tmplst 5]

		if { [string compare -nocase $type "Music"] || ($art == "" && $song == "") } {
			return 0
		}
		
		return [list $song $art "" "" ""]
	}



	###############################################
	# ::music::TreatSongSongbird                  #
	# ------------------------------------------- #
	# Gets the current playing song in Amarok     #
	###############################################
	proc TreatSongSongbird {} {
		after 0 {::music::exec_async [list [file join $::music::musicpluginpath "infosongbird"]] }
		return 0
	}

	###############################################
	# ::music::GetSongSongbird                    #
	# ------------------------------------------- #
	# Gets the current playing song in Amarok     #
	###############################################
	proc GetSongSongbird {} {
		#actualsong is filled asynchronously in TreatSongAmarok
		#Split the lines into a list and set the variables as appropriate
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			#actualsong isn't yet defined by asynchronous exec
			return 0
		}

		set status [lindex $tmplst 0]

		if {$status != "playing"} {
			return 0
		} else {
			set song [lindex $tmplst 1]
			set art [lindex $tmplst 2]
			set artpath ""

			return [list $song $art "" "" ""]
		}
	}


	################################################
	# ::music::TreatSongCog                        #
	# -------------------------------------------  #
	# Execute the applescript to get actual song   #
	# Osascript: Command to execute AppleScript    #
	# Find where's the plugin directory(by getKey) #
	################################################
	proc TreatSongCog {} {
		after 0 {::music::exec_async_mac [file join $::music::musicpluginpath infocog.scpt]}
	}

	###############################################
	# ::music::GetSongCog                         #
	# ------------------------------------------- #
	# Gets the current playing song in Cog        #
	###############################################
	proc GetSongCog {} {

		#Get the variable we get in exec_async_mac and separate in multi lines
		if { [catch {split $::music::actualsong "\n"} tmplst] } {
			::music::log "Actualsong isn't yet defined by asynchronous exec"
			return 0
		}

		set status [lindex $tmplst 0]
		set song [lindex $tmplst 1]
		set art [lindex $tmplst 2]

		if {$status == "0"} {
			::music::log "Status is 0"
			return 0
		}

		return [list $song $art ""]
	}
}
