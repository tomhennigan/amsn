namespace eval ::winks {
	
	#----------------------------------------------------------------------------------
	# DeInit: free resources and unset winks capacity
	#----------------------------------------------------------------------------------
	proc DeInit { dir } {
		# unset tha winks arrays and destroy the menu
		global HOME winks_list winks_cache
		array unset winks_list
		array unset winks_cache
		::winks::WinksMenuDestroy 
		# unset the winks client cap 
		::MSN::setClientCap winks 0
		catch { ::MSN::changeStatus [::MSN::myStatusIs] }
		status_log "Winks plugin unloaded.\n" green
	}

	#----------------------------------------------------------------------------------
	# Init: bind events, load winks list, set config variables
	#----------------------------------------------------------------------------------
	proc Init { dir } {
		
		status_log "Loading Winks plugin...\n" green

		global HOME wink_unknown_thumbnail wink_readme_path cabextract_version

		set cabextract_version "undef"

		# this variables helps me to avoid playing two winks at the same time in a chatwindow
		global winks_f_playing_in
		array unset winks_f_playing_in

		# create the directory structure if it doesn't exists
		create_dir [file join "$HOME" winks]
		create_dir [file join "$HOME" winks cache]
		create_dir [file join "$HOME" winks cache tmp]
		
		# load winks arrays
		::winks::LoadWinks
		::winks::LoadCache
		# load language file		
		load_lang en [file join $dir "lang"]
		load_lang [::config::getGlobalKey language] [file join $dir "lang"]
	
		# register plugin events
		::plugins::RegisterPlugin Winks
		::plugins::RegisterEvent Winks WinkReceived ReceivedWink
		::plugins::RegisterEvent Winks chatwindowbutton AddWinksButton
		::plugins::RegisterEvent Winks DataCastPacketReceived ReceiveSomething
		::plugins::RegisterEvent Winks PacketReceived ReceiveSomething

		# load plugin pixmaps
		::skin::setPixmap unknown_wink unknown_wink.png pixmaps [file join $dir pixmaps]
		::skin::setPixmap butwinks winksbut.png pixmaps [file join $dir pixmaps]
		::skin::setPixmap butwinks_hover winksbut_hover.png pixmaps [file join $dir pixmaps]
		# remind the unknown wink thumbnail
		set wink_unknown_thumbnail [file join "$dir" pixmaps "unknown_wink.png"]
		# remind the README.txt path
		set wink_readme_path [file join "$dir" "README.txt"]

		# set plugin configuration
		array set ::winks::config {
#				show_add_wink 1
#				close_on_leave 1
				use_extrac32 0
				cabextractor ""
				flashplayer ""
				flashplayerargs ""
				play_inmediatly 1
				play_embed 0
				notify_in_one_line 0
				#use_queque_in 1
				#use_queque_out 1
		}
		set ::winks::configlist [ list \
#				[list bool "[trans winks_show_add_new_wink_in_menu]" show_add_wink] \
#				[list bool "[trans winks_close_menu_on_mouse_leave]" close_on_leave] \
				[list str "[trans winks_cabextract_command]" cabextractor] \
				[list bool "[trans winks_use_extrac32]" use_extrac32] \
				[list str "[trans winks_swf_player_command]" flashplayer] \
				[list str "[trans winks_swf_player_arguments]" flashplayerargs] \
				[list bool "[trans winks_play_wink_immediatly_when_recived]" play_inmediatly] \
				[list bool "[trans winks_play_embed]" play_embed] \
				[list bool "[trans winks_notify_in_one_line]" notify_in_one_line] \
				#[list bool "[trans winks_use_queque_in]" use_queque_in] \
				#[list bool "[trans winks_use_queque_out]" use_queque_out] \
				[list ext "[trans help]" {ShowReadme}] \
		]
	
		# set the clientcap
		::MSN::setClientCap winks
		if { "[::MSN::myStatusIs]" != "HDN" && "[::MSN::myStatusIs]" != "FLN" } {
			::MSN::changeStatus [::MSN::myStatusIs] 
		}

		# load plugin configuration NOW
		if {[array names ::plugins::config Winks] != ""} {
			if {$::plugins::config(Winks) != ""} {
				array set ::winks::config $::plugins::config(Winks)
			}
		}	
	
		# find out what cab extractor should we use
		if { "$::winks::config(cabextractor)" == "" && ! $::winks::config(use_extrac32) } {
			GuessCabextractor "$dir"
			set ::plugins::config(Winks) [array get ::winks::config]
		} elseif { ! $::winks::config(use_extrac32) } {
			CheckCabextractVersion
		}
		
		# if there's no flash player configured yet
		if { "$::winks::config(flashplayer)" == "" } {
			GuessFlashplayer "$dir"
			set ::plugins::config(Winks) [array get ::winks::config]
		}
		
		::plugins::save_config
		status_log $::winks::config(flashplayer) 
		status_log "Winks Loaded OK.\n" green
	}


	#----------------------------------------------------------------------------------
	# GuessFlashplayer: finds out what flashplayer command should we use.
	#----------------------------------------------------------------------------------
	proc GuessFlashplayer { dir } {
		status_log "Guessing flashplayer..."
		# see if there's any gnash over there in the system

		if { ! [catch { exec "gnash" "--version" } ver]  } {
			status_log "gnash found in system path." green
			set ::winks::config(flashplayer) "gnash"
			set ::winks::config(flashplayerargs) "-1"
			# see if there's any gnash over there in the system
			status_log [string range "$ver" 0 11]
			if { [string range "$ver" 0 11] != "Gnash 0.7.2" } {
				set ::winks::config(play_embed) 1
			} else {
				set ::winks::config(play_embed) 0
			}
		} else {
			# see if there's any flash player in the plugin directory
			if { [OnWin] } {
				if {[file exists [file join $dir "gnash.exe"]]} {
					status_log "gnash found in plugin path." green
					set ::winks::config(flashplayer) [file join $dir "gnash.exe"]
					set ::winks::config(flashplayerargs) "-1"
				} elseif {[file exists [file join utils windows gnash gnash.exe]] } {
					status_log "gnash found in utils path." green
					set ::winks::config(flashplayer) [file join utils windows gnash gnash.exe]
					set ::winks::config(flashplayerargs) "-1"
				} elseif {[file exists [file join $dir "flashplayer.exe"]]} {
					status_log "flashplayer in plugin path." green
					set ::winks::config(flashplayer) [file join $dir "flashplayer.exe"]
					set ::winks::config(flashplayerargs) ""
				} else {
					status_log "No player found." red
				}
			} else {
				if {[file exists [file join $dir "gnash"]]} {
					status_log "gnash found in plugin path." green
					set ::winks::config(flashplayer) [file join $dir "gnash"]
					set ::winks::config(flashplayerargs) "-1"
				} elseif {[file exists [file join $dir "flashplayer"]]} {
					status_log "flashplayer found in plugin path." green
					set ::winks::config(flashplayer) [file join $dir "flashplayer"]
					set ::winks::config(flashplayerargs) ""
				} else {
					status_log "No player found." red
				}
			}
		}
	}
	
	#----------------------------------------------------------------------------------
	# GuessCabextractor: finds out what cabextract command should we use.
	#----------------------------------------------------------------------------------
	proc GuessCabextractor { dir } {
		status_log "Guessing cabextractor..."
		# try first with extrac32 (for windows systems)
		if { ! [catch { exec "extrac32" } ver]  } {
			status_log "extrac32 found." green
			set ::winks::config(use_extrac32) 1
		} else {
			# see if cabextract is present in the system
			set ::winks::config(cabextractor) "cabextract"
			if { ! [CheckCabextractVersion] } {
				# ... see if there's one in the plugin directory
				if {[file exists [file join $dir "cabextract"]]} {
					set ::winks::config(cabextractor) [file join $dir "cabextract"]
					CheckCabextractVersion
					status_log "cabextract found in plugin path." green
				} else {
					set ::winks::config(cabextractor) ""
					status_log "No cabextractor found." red
				}
			} else {
				status_log "cabextract found in system path." green
			}
		}
	}
	
	#----------------------------------------------------------------------------------
	# CheckCabextractVersion: finds out what cabextract version do we have
	#                         for correct use of -F arguments
	#----------------------------------------------------------------------------------
	proc CheckCabextractVersion { } {
		global cabextract_version
		if { ! [catch { exec "[FixBars $::winks::config(cabextractor)]" "-v" } ver]  } {
			if { "$ver" == "cabextract version 0.1" || "$ver" == "cabextract version 0.2" 
			  || "$ver" == "cabextract version 0.3" || "$ver" == "cabextract version 0.4" 
			  || "$ver" == "cabextract version 0.5" || "$ver" == "cabextract version 0.6" 
			  || "$ver" == "cabextract version 1.0" || "$ver" == "cabextract version 1.1" } {
				set cabextract_version "old"
			} else {
				set cabextract_version "new"
			}
			return 1
		} else {
			set cabextract_version "undef"
			return 0
		}
	}
	
	#----------------------------------------------------------------------------------
	# ShowReadme: Shows a help window with the content of README.txt
	#----------------------------------------------------------------------------------
	proc ShowReadme { } {
	
		global wink_readme_path
		
		if {![file exists $wink_readme_path]} {
			status_log "Can't open \"$wink_readme_path\"." red
			msg_box "[trans winks_cant_open] README.txt"
			return
		}
				
		if { [winfo exists .wink_readme] } {
			raise .wink_readme
			return
		}

		toplevel .wink_readme
		wm title .wink_readme "Winks Plugin Help - README.txt"
		ShowTransient .wink_readme
		wm state .wink_readme withdrawn

		# show readme widget
		frame .wink_readme.middle
		frame .wink_readme.middle.list -class Amsn -borderwidth 0
		text .wink_readme.middle.list.text -background white -width 80 -height 10 -wrap word \
			-yscrollcommand ".wink_readme.middle.list.ys set" -font splainf
		scrollbar .wink_readme.middle.list.ys -command ".wink_readme.middle.list.text yview"
		pack .wink_readme.middle.list.ys -side right -fill y
		pack .wink_readme.middle.list.text -side left -expand true -fill both
		pack .wink_readme.middle.list -side top -expand true -fill both -padx 1 -pady 1

		# show close button
		frame .wink_readme.bottom -class Amsn
		button .wink_readme.bottom.close -text "[trans close]" -command "destroy .wink_readme"
		bind .wink_readme <<Escape>> "destroy .wink_readme"
		pack .wink_readme.bottom.close -side right
		
		pack .wink_readme.bottom -side bottom -fill x -pady 3 -padx 5
		pack .wink_readme.middle -expand true -fill both -side top

		#Insert the text from the file
		set id [open "$wink_readme_path" r]
		fconfigure $id

		.wink_readme.middle.list.text insert 1.0 [read $id]
		close $id

		.wink_readme.middle.list.text configure -state disabled

		update idletasks

		wm state .wink_readme normal
		set x [expr {([winfo vrootwidth .wink_readme] - [winfo width .wink_readme]) / 2}]
		set y [expr {([winfo vrootheight .wink_readme] - [winfo height .wink_readme]) / 2}]
		wm geometry .wink_readme +${x}+${y}
		moveinscreen .wink_readme 30

	}	

	#----------------------------------------------------------------------------------
	# GetAttrib: if cut a sub string (field value) from a piece of xml, or return an 
	#            empty string if the given key id not found
	#----------------------------------------------------------------------------------
	proc GetAttrib { list_data attrib { decoded 0 } } {
		set idx [lsearch $list_data "${attrib}=*"]
		if { $idx == -1 } { return "" }
		set temp [lindex $list_data $idx]
		# if there's more than one word, complete temp
		set temp2 $temp
		while { "[string index $temp2 end-1 ]" != "\"" && $idx != [llength $list_data]} {
			incr idx
			set temp2 [lindex $list_data $idx]
			set temp "$temp $temp2"
		}
		# crop the value and return it
		set temp [split $temp "\""]
		set temp [lindex $temp 1]
		if { $decoded == 0 } {
			return $temp
		} else {
			return [urldecode $temp]
		}
	}
	
	#----------------------------------------------------------------------------------
	# GetFirstAfterInNode: Looks for a field after another field in a node
	#----------------------------------------------------------------------------------
	proc GetFirstAfterInNode { text_data attrib1 attrib2 } {
		set id [string first $attrib1 "$text_data"]
		if { $id == -1 } {
			return ""
		}
		set temp [string range "$text_data" $id end]
		set $id [string first ">" "$temp"]
		if { $id != -1 } {
			set temp [string range "$temp" 0 $id]
		}
		set id [string first $attrib2 "$temp"]
		if { $id == -1 } {
			return ""
		}
		set temp [split [string range "$temp" $id end] "\""]
		return [lindex $temp 1]
	}
	
	#----------------------------------------------------------------------------------
	# FixMissingAttrib: if looks for the missing field in the given file and return it,
	#                   or the default value if it's not found
	#----------------------------------------------------------------------------------
	proc FixMissingAttrib { filename field default } {
		if { [file exists "$filename"] == 0 } { 
			status_log "Missing $filename" red
			return "$default"
		} else {
			set fd2 [open "$filename" r]
			fconfigure $fd2 -encoding utf-8
			set lista [split [read $fd2] " "]
			close $fd2
			set attrib [GetAttrib $lista "$field"]
			if { "$attrib" == "" } {
				return "$default"
			} else {
				return "$attrib"
			}
		}
	} 

	#----------------------------------------------------------------------------------
	# FindFileName: finds the correct file name for a given one
	#----------------------------------------------------------------------------------
	proc FindFileName { dir fil } {
		if { [file exists [file join $dir [string tolower $fil]]] } { return [file join $dir [string tolower $fil]] }
		if { [file exists [file join $dir [string toupper $fil]]] } { return [file join $dir [string toupper $fil]] }
		return [file join $dir $fil]
	}

	#----------------------------------------------------------------------------------
	# LoadWinks: read $HOME/winks/index.xml and put that information in winks_list 
	#----------------------------------------------------------------------------------
	proc LoadWinks { } {

		# reset winks array and winks menu
		global HOME winks_list
		array unset winks_list
		::winks::WinksMenuDestroy 
		set modified 0
		
		# open winks index
		if { [file exists [file join "$HOME" winks index.xml]] == 0 } { 
			return 
		}
		set fd [open [file join "$HOME" winks index.xml] r]
		set data [read $fd]
		close $fd
		
		# separate winks
		set lista [split $data "\n"]

		foreach data $lista {
			# check if the line is a wink
			set listb [split "$data" " "]
			set sha1d [GetAttrib $listb "sha1d"]
			if { "$sha1d" != "" } { 
				# read wink information
				set wink(sha1d) $sha1d
				set wink(name) [GetAttrib $listb "name" 1]
				set wink(swf) [GetAttrib $listb "swf" 1]
				set wink(cab) [GetAttrib $listb "cab" 1]
				set wink(img) [GetAttrib $listb "img" 1]
				set wink(stamp) [GetAttrib $listb "stamp"]
				set wink(sizex) [GetAttrib $listb "sizex"]
				set wink(sizey) [GetAttrib $listb "sizey"]
				# fix bugs in some fields
				if { [string index $wink(name) end] == "\x00" } { set wink(name) [string range $wink(name) 0 end-1] } 
				# fix missing information
				if { "$wink(sizex)" == "" } {
					set modified 1
					set wink(sizex) [FixMissingAttrib "[file join [file dirname $wink(swf)] content.xml]" "wink:sizex" "0"]
					set wink(sizey) [FixMissingAttrib "[file join [file dirname $wink(swf)] content.xml]" "wink:sizey" "0"]
				}
				if { "$wink(name)" == "" } {
					set modified 1
					set wink(name) [FixMissingAttrib "[file join [file dirname $wink(swf)] content.xml]" "wink:name" "[file rootname \"[file tail \"$wink(swf)\"]\"]"]
				}
				# add the wink to the list
				if { [file exists $wink(cab)] } {
					set winks_list($sha1d) [array get wink]
				} else {
					status_log "Winks Menu: Missing files: Dropped one wink: \"$wink(name)\"." red
				}
			}
		}
		
		if { $modified == 1 } { SaveWinks }
		status_log "Winks loaded: [expr {[llength [array names winks_list] ] }]\n" green

	}

	#------------------------------------------------------------------------------------
	# LoadCache: read $HOME/winks/cache/index.xml and put that information in winks_list 
	#------------------------------------------------------------------------------------
	proc LoadCache { } {
		
		# reset winks cache
		global HOME winks_cache
		array unset winks_cache
		set modified 0
		
		# open winks cache index
		if { [file exists [file join "$HOME" winks cache index.xml]] == 0 } { 
			return 
		}
		set fd [open [file join "$HOME" winks cache index.xml] r]
		set data [read $fd]
		close $fd
		
		# separate winks
		set lista [split $data "\n"]

		foreach data $lista {
			# check if the line is a wink
			set listb [split "$data" " "]
			set sha1d [GetAttrib $listb "sha1d"]
			if { "$sha1d" != "" } { 
				# read wink information
				set wink(sha1d) $sha1d
				set wink(name) [GetAttrib $listb "name" 1]
				set wink(swf) [GetAttrib $listb "swf" 1]
				set wink(cab) [GetAttrib $listb "cab" 1]
				set wink(img) [GetAttrib $listb "img" 1]
				set wink(stamp) [GetAttrib $listb "stamp"]
				set wink(sizex) [GetAttrib $listb "sizex"]
				set wink(sizey) [GetAttrib $listb "sizey"]
				# fix bugs in some fields
				if { [string index $wink(name) end] == "\x00" } { set wink(name) [string range $wink(name) 0 end-1] } 
				# fix missing information
				if { "$wink(sizex)" == "" } {
					set modified 1
					set wink(sizex) [FixMissingAttrib "[file join [file dirname $wink(swf)] content.xml]" "wink:sizex" "0"]
					set wink(sizey) [FixMissingAttrib "[file join [file dirname $wink(swf)] content.xml]" "wink:sizey" "0"]
				}
				if { "$wink(name)" == "" } {
					set modified 1
					set wink(name) [FixMissingAttrib "[file join [file dirname $wink(swf)] content.xml]" "wink:name" "[file tail \"$wink(swf)\"]"]
				}
				# add the wink to the list
				if { [file exists $wink(cab)] } {
					set winks_cache($sha1d) [array get wink]
				} else {
					status_log "Winks Cache: Missing files: Dropped one wink: \"$wink(name)\"." red
				}
				
			}
		}
		
		if { $modified == 1 } { SaveCache }
		status_log "Winks in cache: [expr {[llength [array names winks_cache] ] }]\n" green

	}

	#----------------------------------------------------------------------------------
	# SaveWinks: write winks_list in $HOME/winks/index.xml
	#----------------------------------------------------------------------------------
	proc SaveWinks { } {
		global HOME winks_list
	        set fileId [open [file join "$HOME" winks index.xml] "w"]
		foreach sha1d [array names winks_list] {
			array set wink $winks_list($sha1d)
			if { "$wink(swf)" != "none" } {
				puts $fileId "<Wink name=\"[urlencode $wink(name)]\" cab=\"[urlencode $wink(cab)]\" swf=\"[urlencode $wink(swf)]\" img=\"[urlencode $wink(img)]\" sizex=\"$wink(sizex)\" sizey=\"$wink(sizey)\" sha1d=\"$wink(sha1d)\" stamp=\"$wink(stamp)\" />"
			}
		}
	        close $fileId
	}

	#----------------------------------------------------------------------------------
	# SaveCache: write winks_list in $HOME/winks/index.xml
	#----------------------------------------------------------------------------------
	proc SaveCache { } {
		global HOME winks_cache
	        set fileId [open [file join "$HOME" winks cache index.xml] "w"]
		foreach sha1d [array names winks_cache] {
			array set wink $winks_cache($sha1d)
			if { "$wink(swf)" != "none" } {
				puts $fileId "<Wink name=\"[urlencode $wink(name)]\" cab=\"[urlencode $wink(cab)]\" swf=\"[urlencode $wink(swf)]\" img=\"[urlencode $wink(img)]\" sizex=\"$wink(sizex)\" sizey=\"$wink(sizey)\" sha1d=\"$wink(sha1d)\" stamp=\"$wink(stamp)\" />"
			}
		}
	        close $fileId
	}

	#----------------------------------------------------------------------------------
	# AddWinkButton: add the winks button to chat window
	#                - left click in wink button opens winks menu
	#                - unload the wink menu (for testing and debuging, force reload)
	#                - right click in wink button adds a new wink from an .mco file
	#----------------------------------------------------------------------------------
	proc AddWinksButton { event evpar } {
		
		upvar 2 $evpar newvar
			
		set buttonbar $newvar(bottom)		

		set winksbut $buttonbar.winksbut
                set window $newvar(window_name)
                set chatid [::ChatWindow::Name $window]
                set winks_f_playing_in($chatid) 0

		button $winksbut -image [::skin::loadPixmap butwinks] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg] \
			-command "::winks::WinksMenu $window \[winfo pointerx $window\] \[winfo pointery $window\] [::ChatWindow::GetInputText $window] \"\" 0"
		pack $winksbut -side left -padx 0 -pady 0

		bind $winksbut <<Button2>> "::winks::WinksMenuDestroy"
		bind $winksbut  <<Button3>> "::winks::AddWinkFromMCO $window"
		bind $winksbut  <Enter> "$winksbut configure -image [::skin::loadPixmap butwinks_hover]"
		bind $winksbut  <Leave> "$winksbut configure -image [::skin::loadPixmap butwinks]"	
		#bind $winksbut  <<Button1>> "::winks::WinksMenu $window \[winfo pointerx $window\] \[winfo pointery $window\] [::ChatWindow::GetInputText $window] \"\" 0"
	}
	
	
	#----------------------------------------------------------------------------------
	# WinksMenuDestroy: unload the winks menu. That happend when winks_list change
	#----------------------------------------------------------------------------------
	proc WinksMenuDestroy { } {
		if { [winfo exists .winksSelector]} {destroy .winksSelector}
	}

	#----------------------------------------------------------------------------------
	# winksCreateMenu: make the winks menu with the information in index.xml
	#----------------------------------------------------------------------------------
	proc winksCreateMenu { } {
	
		global winks_list

		set w .winksSelector

		if {[catch {[toplevel $w]} res]} {
			destroy $w
			toplevel $w
		}
		
		set winksNumber [expr {[llength [array names winks_list] ] }]

		# fixed icon size
		set smiw 52
		set smih 52
		
		#We want to keep a certain ratio:
		# cols/(rows+1) = 4/3
		# we know cols*rows>=winksNumber
		#This is the solution of solving that equation system
		set ratio [expr {4.0/3.0}]		
		set cols [expr {ceil(($ratio+sqrt(($ratio*$ratio)+4.0*$ratio*$winksNumber))/2.0)}]

		# that's fix is to see correctly the "Add new Wink..." label in other languages	
		if { $cols < 5 } { set cols 5 }

		set rows [expr {ceil(double($winksNumber) / $cols)}]

		set cols [expr {int($cols)}]
		set rows [expr {int($rows)}]
		
		set x_geo [expr {$smiw*$cols + 2} ]
		set y_geo [expr {$smih*$rows + 2} + 26 ]
		
		wm state $w withdrawn
		wm geometry $w ${x_geo}x${y_geo}
		wm title $w "[trans msn]"
		wm overrideredirect $w 1
		wm transient $w
		
		
		canvas $w.c -background white -borderwidth 0 -relief flat \
			-selectbackground white -selectborderwidth 0 
		pack $w.c -expand true -fill both
		
		set wink_num 0
		set wink_pos 0
		
		foreach sha1d [array names winks_list] {

			array set wink $winks_list($sha1d)

			if { "$wink(swf)" != "none" } {
				set img "0"
				catch { set img [image create photo $wink(name) -file "$wink(img)" -format cximage] }
				winksCreateInMenu $w.c $cols $rows $smiw $smih \
					$wink_num $wink_pos $wink(name) $wink(name) $img
			
				incr wink_pos
				incr wink_num
			}
		}

		# show the "add new wink button"
		label $w.c.new_but -text "[trans winks_add_new_wink]"  -background [$w.c cget -background] -font sboldf
		bind $w.c.new_but <Enter> [list $w.c.new_but configure -relief raised]
		bind $w.c.new_but <Leave> [list $w.c.new_but configure -relief flat]
		set ypos [expr {($rows)*$smih +13}]
		$w.c create window  0 $ypos -window $w.c.new_but -width [expr {$x_geo - 2}] -height 26 -anchor w

		# define how to close the menu (that's for compiz/baryl focus trouble)
		bind $w <Leave> "::smiley::handleLeaveEvent $w $x_geo $y_geo"
		#bind $w <Enter> "bind $w <Leave> \"bind $w <Leave> \\\"wm state $w withdrawn\\\"\""

	}
	
	#----------------------------------------------------------------------------------
	# winksCreateInMenu: add a wink button to the winks menu
	#----------------------------------------------------------------------------------
	proc winksCreateInMenu {w cols rows smiw smih wink_num wink_pos name symbol image} {
		global winks_list
		catch {
			set resized [image create photo]
			$resized copy $image
			if {[image width $image] > 44 && [image height $image] > 44} {
				::picture::ResizeWithRatio $resized 44 44
							}
			label $w.$wink_num -image $resized -background [$w cget -background]
			bind $w.$wink_num <Destroy> "image delete $resized"
	
			$w.$wink_num configure -cursor hand2 -borderwidth 1 -relief flat
			
			#Bindings for raise/flat on mouse over
			bind $w.$wink_num <Enter> [list $w.$wink_num configure -relief raised]
			bind $w.$wink_num <Leave> [list $w.$wink_num configure -relief flat]

			#Tooltip
			if { [::config::getKey tooltips] } {set_balloon $w.$wink_num "$name"}
			set xpos [expr {($wink_pos % $cols)* $smiw}]
			set ypos [expr {($wink_pos / $cols) * $smih}]
			$w create window $xpos $ypos -window $w.$wink_num -anchor nw -width $smiw -height $smih
		}
	}


	#----------------------------------------------------------------------------------
	# WinksMenu: bind events to the winks menu and shows it
	#----------------------------------------------------------------------------------
	proc WinksMenu { window_name {x 0} {y 0} {text text} categ categnum} {

		set chatid [::ChatWindow::Name $window_name]

		global winks_list
		
		set w .winksSelector
		
		if { ! [winfo exists $w]} { 
			winksCreateMenu
		}
		
		wm state $w normal
		set x [expr {$x - 15}]
		set y [expr {$y + 15 - [winfo height $w]}]
		wm geometry $w +$x+$y

		#It won't work on Windows without this
		update idletasks
		
		
		# It won't work on Windows without this
		raise $w
		
		set temp 0
		
		# add winks bindings
		foreach sha1d [array names winks_list] {
			
			array set wink $winks_list($sha1d)
				
			if { "$wink(swf)" != "none" } {
				set symbol [lindex $wink(name) 0]
				
				#This must be cached due to a race condition (if you double click
				#the winks menu for first time, the second click can launch
				#this procedure without all winks having been created
				catch { 
					bind $w.c.$temp <<Button1>> "wm state $w withdrawn; ::MSN::ChatQueue $chatid \[list ::winks::SendWink $window_name $wink(sha1d)]"
					bind $w.c.$temp <<Button2>> "::winks::PlayWink \"$wink(swf)\""
					bind $w.c.$temp <<Button3>> "wm state $w withdrawn; ::winks::EditWinkDialog $chatid \"$wink(sha1d)\""
				}
				incr temp
			}
		}
		bind $w.c.new_but <<Button1>> "wm state $w withdrawn; ::winks::AddWinkFromMCO $window_name"
		moveinscreen $w 5
		event generate $w <Enter>
	
	}

	#----------------------------------------------------------------------------------
	# EditWinkDialog: ask for new wink name, and also let you delete the wink
	#----------------------------------------------------------------------------------
	proc EditWinkDialog { chatid sha1d } {
			set w .editWink
			global winks_list
			array set wink $winks_list($sha1d)
			if { [winfo exists .editWink]} {destroy .editWink}
			toplevel $w
			wm group $w .
			wm title $w "Edit Wink: $wink(name)"
		
			frame $w.fn
			label $w.fn.label -font sboldf -text "[trans winks_introduce_new_wink_name]"
			entry $w.fn.name -width 40 -bg #FFFFFF -font splainf
		
			frame $w.fb
			button $w.fb.del -text [trans "delete"] -command "::winks::DeleteWink $chatid \"$sha1d\""
			button $w.fb.ok -text [trans "rename"] -command "::winks::RenameWink $chatid \"$sha1d\""
			button $w.fb.play -text [trans "winks_play"] -command [list ::winks::PlayWink $wink(swf)]
			button $w.fb.cancel -text [trans cancel] -command "destroy $w"
			bind $w <<Escape>> "destroy $w"
		
			label $w.fn.icon -image [image create photo .addNewWinkImg -file $wink(img) -format cximage] 
	
			pack $w.fn.icon -side left -fill x -expand true
			pack $w.fn.label $w.fn.name -side left -fill x -expand true
			pack $w.fb.ok $w.fb.cancel -side right -padx 5
			pack $w.fb.play $w.fb.cancel -side right -padx 5
			pack $w.fb.del -side left -padx 5
		
			bind $w.fn.name <Return> "::winks::RenameWink $chatid \"$sha1d\""
			pack $w.fn $w.fb -side top -fill x -expand true -padx 5
			$w.fn.name insert 0 "$wink(name)"
			
			update
			
			catch {
				raise $w
				focus -force $w.fn.name
			}
			moveinscreen $w 50
	}

	#----------------------------------------------------------------------------------
	# RenameWink: called from EditWinkDialog, changes a wink name
	#----------------------------------------------------------------------------------
	proc RenameWink { chatid sha1d } {
		global winks_list
		set wname [.editWink.fn.name get]
		array set wink $winks_list($sha1d)
		# if the name is empty, find a suitable one
		if { "$wname" == "" } {
			set wink(name) [FixMissingAttrib "[file join [file dirname $wink(swf)] content.xml]" "wink:name" "[file rootname \"[file tail \"$wink(swf)\"]\"]"]
		} else {
			set wink(name) $wname
		}
		# upadate wink information
		set winks_list($sha1d) [array get wink]
		::winks::WinksMenuDestroy
		SaveWinks
		msg_box "[trans winks_wink_renamed]"
		destroy .editWink
	}
	
	#----------------------------------------------------------------------------------
	# DeleteWink: called from EditWinkDialog, delete a wink from winks_list
	#----------------------------------------------------------------------------------
	proc DeleteWink { chatid sha1d } {
		global HOME winks_cache winks_list
		set wname [.editWink.fn.name get]
		array set wink $winks_list($sha1d)

		# relocate files in cache again
#		catch {
			set cab_folder [::md5::md5 $sha1d]
			if  { [file exists [file join "$HOME" winks cache $cab_folder]] } {
				file delete -force [file exists "$HOME" winks cache $cab_folder]
			}
			file rename -force [file dirname $wink(swf)] [file join "$HOME" winks cache $cab_folder]
			set wink(cab) [file join "$HOME" winks cache $cab_folder [file tail $wink(cab)]]
			set wink(swf) [file join "$HOME" winks cache $cab_folder [file tail $wink(swf)]]
			set wink(img) [file join "$HOME" winks cache $cab_folder [file tail $wink(img)]]
			status_log "Wink Moved to Cache." green
#		} errs
#		if { "$errs" != "" } {
#			status_log "While deleting wink: $errs" red
#		} 

		# update arrays
		set winks_cache($sha1d) [array get wink] 
		unset winks_list($sha1d)	
		SaveWinks
		SaveCache
		WinksMenuDestroy				

		status_log "Wink deleted from menu." green
		destroy .editWink

		msg_box "[trans winks_wink_deleted]"
		return

	}

	#----------------------------------------------------------------------------------
	# AddWinkFromMCO: lets you choos an MCO file. if its corrects adds this wink to 
	#                 cache and shows the dialog to preview it and to add it and add it 
	#                 to the winks menu
	#----------------------------------------------------------------------------------
	proc AddWinkFromMCO { window_name } {
		global HOME
		set chatid [::ChatWindow::Name $window_name]
		set mco_file [chooseFileDialog "" "" "" "" "open" [list [list "Messenger Content Objets" [list *.mco *.MCO]] ] ]
		if { "$mco_file" != "" } {
			if { [file exists "$mco_file"] == 0 } {
				msg_box "[trans winks_cant_open] $mco_file" 
				return 
			}
			
			
			# extract fisrt content.xml
			ExtractCab "$mco_file" "content.xml" [file join $HOME winks cache tmp]
			set filename [file join  "$HOME" winks cache tmp content.xml]
			if { [file exists "$filename"] == 0 } { 
				msg_box "[trans winks_cant_open] content.xml"
				return 
			}
			
			# read first content.xml information
			set fd1 [open "$filename" r]
			fconfigure $fd1 -encoding utf-8
			set data [read $fd1]
			set lista [split $data " "]
			close $fd1
			file delete $filename
			
			# verify that the object is a wink
			if { [string first "type=\"wink\"" "$data"] == "-1" } {
				msg_box "\n[trans winks_file_is_not_a_wink]"
				return 
			}
			
			# get mco information
			set wink(cab) [GetAttrib $lista "file"]
			set wink(stamp) [GetAttrib $lista "stamp"]
		
			# extract the cab file in temp folder
			set temp_folder [file join "$HOME" winks cache tmp]
			ExtractCab "$mco_file" "$wink(cab)" $temp_folder
			
			# get the sha1d 
			set filename [file join $temp_folder $wink(cab)]
			if { [file exists "$filename"] == 0 } { 
				amsn::WinWrite $chatid "\n[trans winks_cant_open] \"$filename\"." red 
				return 
			}
			set fd2 [open $filename r]
			fconfigure $fd2 -translation binary
			set data [read $fd2]
			close $fd2
			set wink(sha1d) [::base64::encode [binary format H* [::sha1::sha1 $data]]]
			
			# see if the wink is already in the winks menu
			global winks_list
			foreach wsha1d [array names winks_list] {
				if { "$wink(sha1d)" == "$wsha1d" } {
					status_log "The wink is already in winks menu!" red
					msg_box "[trans winks_the_wink_is_already_in_winks_menu]"
					file delete "$filename"
					return
				}
			}
			
			# get md5 and create dir in cache folder 
			set cab_folder [::md5::md5 $wink(sha1d)]
			create_dir [file join "$HOME" winks cache $cab_folder]
			
			# extract and read the cab content
			ExtractCab "$filename" "*" [file join "$HOME" winks cache $cab_folder]
			# move cab file to the correct location 
			set wink(cab) [file join "$HOME" winks cache $cab_folder $wink(cab)]
			file rename -force "$filename" "$wink(cab)"
			
			# read cabs's content.xml file
			set filename [file join "$HOME" winks cache $cab_folder content.xml]
			if { [file exists $filename] == 0 } { 
				amsn::WinWrite $chatid "\n[trans winks_cant_open] content.xml(2)." red 
				return 
			}
			set fd3 [open $filename r]
			fconfigure $fd3 -encoding utf-8
			set data [read $fd3]
			set listb [split $data " "]
			close $fd3
			
			# get wink information
			set wink(img) [FindFileName [file join "$HOME" winks cache $cab_folder] [GetFirstAfterInNode $data "thumbnail" "file"]]
			set wink(swf) [FindFileName [file join "$HOME" winks cache $cab_folder] [GetFirstAfterInNode $data "animation" "file"]]
			set wink(sizex) [GetAttrib $listb "wink:sizex"]
			set wink(sizey) [GetAttrib $listb "wink:sizey"]
			# fix missing information
			if { "$wink(sizex)" == "0" } {
				set wink(sizex) 0
				set wink(sizey) 0
			}
			set wink(name) [GetAttrib $listb "wink:name"]
			if { "$wink(name)" == "" } {
				set wink(name) [file rootname [file tail "$wink(swf)"]]
			}
			
			# copy information to cache
			global winks_cache
			set winks_cache($wink(sha1d)) [array get wink]
			SaveCache
			
			# show confirmation and name editing dialog
			AddWinkDialog $chatid $wink(sha1d) "$wink(img)" "$wink(swf)" "$wink(name)"
			
		}
		
	}


	#----------------------------------------------------------------------------------
	# AddWinkDialog: let you choose an .mco file and ask for a wink name for a new wink
	#----------------------------------------------------------------------------------
	proc AddWinkDialog { chatid sha1d img swf wname } {

		set w .addNewWink
		if { [winfo exists .addNewWink]} {destroy .addNewWink}
		toplevel $w
		wm group $w .
		wm title $w "[trans winks_add_new_wink]"
	
		frame $w.fn
		label $w.fn.label -font sboldf -text "[trans winks_introduce_new_wink_name]"
		entry $w.fn.name -width 40 -bg #FFFFFF -font splainf
	
		frame $w.fb
		button $w.fb.ok -text [trans ok] -command "::winks::AddWinkDialoOK $chatid $sha1d"
		button $w.fb.cancel -text [trans cancel] -command "destroy $w"
		button $w.fb.play -text [trans "winks_play"] -command [list ::winks::PlayWink $swf]
		bind $w <<Escape>> "destroy $w"

		label $w.fn.icon -image [image create photo .addNewWinkImg -file $img -format cximage] 
	
		pack $w.fn.icon -side left -fill x -expand true
		pack $w.fn.label $w.fn.name -side left -fill x -expand true
		pack $w.fb.ok $w.fb.cancel -side right -padx 5
		pack $w.fb.play -side left -padx 5
	
		bind $w.fn.name <Return> "::winks::AddWinkDialoOK $chatid $sha1d"
		pack $w.fn $w.fb -side top -fill x -expand true -padx 5

		$w.fn.name insert 0 "$wname"
	
		catch {
			raise $w
			focus -force $w.fn.name
		}
		moveinscreen $w 50
	}

	#----------------------------------------------------------------------------------
	# AddWinkDialoOK: change the wink name and moves it to winks menu 
	#----------------------------------------------------------------------------------
	proc AddWinkDialoOK { chatid sha1d } {
status_log "BOOGA"
		global winks_cache
status_log "BOOGA"
		array set wink $winks_cache($sha1d)
status_log "BOOGA"

		set wink_name [.addNewWink.fn.name get]
		if { "$wink_name" != "" } {
			set wink(name) "$wink_name"
			set winks_cache($sha1d) [array get wink]
		}
status_log "BOOGA"
		destroy .addNewWink
status_log "BOOGA"
		::winks::AddWinkFromCache $chatid $sha1d
status_log "BOOGA"
	}

	#----------------------------------------------------------------------------------
	# PlayWink: call an external swf player to show the wink animation 
	#----------------------------------------------------------------------------------
	proc PlayWinkFromSHA1D { chatid sha1d } {
		
		global winks_list winks_cache
		
		# see if the wink is in our winks menu to play it
		foreach wsha1d [array names winks_list] {
			if { "$sha1d" == "$wsha1d" } {
				array set wink $winks_list($sha1d)
				if { "$wink(img)" == "---unknown-wink---" } {
					msg_box "[trans winks_cant_play_now_wait_thumbnail]"
					return
				}
				if { $::winks::config(play_embed) } {
					::winks::PlayWinkInChatWindow "$wink(swf)" "$chatid" "$wink(sizex)" "$wink(sizey)"
				} else {
					::winks::PlayWink "$wink(swf)"
				}
				return
			}
		}

		# see if the wink is in our winks cache to play it
		foreach wsha1d [array names winks_cache] {
			if { "$sha1d" == "$wsha1d" } {
				array set wink $winks_cache($sha1d)
				if { "$wink(img)" == "---unknown-wink---" } {
					msg_box "[trans winks_cant_play_now_wait_thumbnail]"
					return
				}
				if { $::winks::config(play_embed) } {
					::winks::PlayWinkInChatWindow "$wink(swf)" "$chatid" "$wink(sizex)" "$wink(sizey)"
				} else {
					::winks::PlayWink "$wink(swf)"
				}
				return
			}
		}
		status_log "Wink not found: $sha1d" red
	}
	
	proc FixBars { path } {
		return [ string map {"\\" "\\\\"} [string map { "\\\\" "\\" } $path] ]
	}
	
	
	#----------------------------------------------------------------------------------
	# PlayWink: call an external swf player to show the wink animation.
	#           this is never played inside the chat window.
	#----------------------------------------------------------------------------------
	proc PlayWink { wfile } {

		# old play wink code
		status_log "Playing wink $wfile\n" green
		set command [concat "exec" "\"[FixBars $::winks::config(flashplayer)]\"" [split "$::winks::config(flashplayerargs)" " "] "\"$wfile\"" "&"]
		catch { eval $command } errs
		if { "$errs" != "" } {
			status_log "\nEval: $command\n" red
			status_log "\nOutput: $errs\n" red
		}
		
		return
	}

	#----------------------------------------------------------------------------------
	# PlayWink: play the wink inside the chatwindow. Only available for gnash.
	#----------------------------------------------------------------------------------
	proc PlayWinkInChatWindow { wfile chatid wkx wky } {

		global winks_f_playing_in
		if { ![info exists winks_f_playing_in($chatid)] } {
			set winks_f_playing_in($chatid) 0
		}

		if { $winks_f_playing_in($chatid) } {
			return 
		}

		# say that we are playing something now
		set winks_f_playing_in($chatid) 1
		
		set win [[::ChatWindow::GetOutText [::ChatWindow::For $chatid] ] getinnerframe]
		
		# wait if the window isn't open yet
		while {! [winfo ismapped $win]} {
			update
		}
		
		# scale the animation size to window size keeping the aspect ratio
		set wny [winfo height $win]
		set wnx [winfo width $win]
		if { "$wkx" == "0" } {
			set sx $wnx
			set sy $wny
		} else { 
			if { $wky*$wnx/$wkx <= $wny } {
				set sx [expr { $wnx }]
				set sy [expr { $wky*$wnx/$wkx }]
			} else {
				set sy [expr { $wny }]
				set sx [expr { $wkx*$wny/$wky }]
			}
		}

		# create the widget where the animation will be played
		set outtext [[::ChatWindow::GetOutText [::ChatWindow::For $chatid]] getinnerframe]
		set outframe [winfo parent $outtext]
		set wink_text_pack [pack info $outtext]
 		pack forget $outtext 
		canvas $outframe.wink_canvas -background [::skin::getKey chat_input_back_color] -borderwidth 0 -relief solid -width $sx -height $sy
		eval pack $outframe.wink_canvas -in $outframe.padding -anchor center  -side top 
		
		# wait if the canvas isn't visible yet
		while {! [winfo ismapped $outframe.wink_canvas]} {
			update
		}
		
        	# play the animation
		status_log "Playing wink $wfile\n" green
		set io [open "|[FixBars $::winks::config(flashplayer)] -1 -x [winfo id $outframe.wink_canvas] -j $sx -k $sy $wfile" r]
		fconfigure $io -blocking 0
		gets $io line

		while { ![eof $io] } { 
			gets $io line
			update
		}

		# delete the temp widget and show the text again
		destroy $outframe.wink_canvas
		eval pack $outtext $wink_text_pack
		
		# say that we finished playing
		set winks_f_playing_in($chatid) 0
			
	}

	

	#----------------------------------------------------------------------------------
	# ExtractCab: extracts files from a .cab into some folder 
	#----------------------------------------------------------------------------------
	proc ExtractCab { cab_file pattern folder } {

		if {$::winks::config(use_extrac32)} {
			if { "$pattern" == "*" } { set pattern "/E" }
			catch { exec "extrac32" "/Y" "$cab_file" "$pattern" "/L" "$folder" } errs
			if { "$errs" != "" } { 
				status_log "cabextract output: $errs" 
			}	
		} else {

			# check cabextract version for correct use of -F arguments
			global cabextract_version
			if { "$cabextract_version" == "undef" } {
				CheckCabextractVersion
			}	
		
			if { "$pattern" == "*" } {
				catch { exec "[FixBars $::winks::config(cabextractor)]" "$cab_file"  "-d" "$folder" "-q" } errs	
			} else {
				if { "$cabextract_version" == "old" } {
					catch { exec "[FixBars $::winks::config(cabextractor)]" "$cab_file" "-F" "$folder/$pattern" "-d" "$folder" "-q" } errs
				} else {
					catch { exec "[FixBars $::winks::config(cabextractor)]" "$cab_file" "-F" "$pattern" "-d" "$folder" "-q" } errs
				}	
			}
			if { "$errs" != "" } { 
				status_log "cabextract output: $errs" 
			}
		}
	}

	#----------------------------------------------------------------------------------
	# NotifyInChatWindow: write the message, the image and the link to play the wink 
	#----------------------------------------------------------------------------------
	proc NotifyInChatWindow	{ chatid sha1d wink_name texto { cache 0 } } {
		if {$::winks::config(notify_in_one_line)} {
			amsn::WinWrite $chatid "\n" green
			amsn::WinWriteIcon $chatid greyline 3
			amsn::WinWrite $chatid "\n[timestamp] ${texto} " green 
			WinWriteThumbnail "$chatid" "$sha1d" $cache
			amsn::WinWrite $chatid " \"$wink_name\".\n" green 
			amsn::WinWriteIcon $chatid greyline 3
		} else {
			amsn::WinWrite $chatid "\n[timestamp] ${texto}\n  " green 
			WinWriteThumbnail "$chatid" "$sha1d" $cache
			amsn::WinWrite $chatid "\n " green
			WinWritePlayLink "$chatid" "$sha1d" "$wink_name"
			amsn::WinWrite $chatid "\n" green
		}	
	}

	#----------------------------------------------------------------------------------
	# ReceiveSomething: when receives some message, checks if thats a wink. Then if 
	#                   the wink is in index.xml (see sha1d) plays it, if it's not 
	#                   there, ask for the cab file with an msnobject 
	#----------------------------------------------------------------------------------
	proc ReceiveSomething { event evpar } {

		global winks_list winks_cache HOME

		upvar 2 $evpar args
		upvar 2 $args(chatid) chatid
		upvar 2 $args(nick) nick
		upvar 2 $args(msg) msg
		
		set header "[$msg getHeader Content-Type]"
		set ID "[$msg getField ID]"
		
		if {$header == "text/x-msnmsgr-datacast" && $ID == "2"} {

			::ChatWindow::MakeFor $chatid
	
			#get the msnobj
			set data [$msg getBody]
			set lista [split $data " "]

			# extract the wink information from the msnobj
			set wink_name [FromUnicode [base64::decode [GetAttrib $lista "Friendly"]]]
			if { [string index $wink_name end] == "\x00" } { set wink_name [string range $wink_name 0 end-1] } 
 
			set sha1d [GetAttrib $lista "SHA1D"]
			set stamp [GetAttrib $lista "stamp"]
			set cab_file [GetAttrib $lista "Location"]
			set user [GetAttrib $lista "Creator"]

			status_log "Received Wink $wink_name $sha1d\n" green

			# see if the wink is in our winks menu to play it
			foreach wsha1d [array names winks_list] {
				if { "$sha1d" == "$wsha1d" } {
					array set wink $winks_list($sha1d)
					NotifyInChatWindow "$chatid" "$sha1d" "$wink(name)" "[::abook::getDisplayNick $user] [trans winks_yourcontact_winks]"
					if {$::winks::config(play_inmediatly)} {
						if { $::winks::config(play_embed) } {
							::winks::PlayWinkInChatWindow "$wink(swf)" "$chatid" "$wink(sizex)" "$wink(sizey)"
						} else {
							::winks::PlayWink "$wink(swf)"
						}
					}

					return
				}
			}

			# see if the wink is in our winks cache to play it
			foreach wsha1d [array names winks_cache] {
				if { "$sha1d" == "$wsha1d" } {
					array set wink $winks_cache($sha1d)
					NotifyInChatWindow "$chatid" "$sha1d" "$wink(name)" "[::abook::getDisplayNick $user] [trans winks_yourcontact_winks]" 1
					if {$::winks::config(play_inmediatly)} {
						if { $::winks::config(play_embed) } {
							::winks::PlayWinkInChatWindow "$wink(swf)" "$chatid" "$wink(sizex)" "$wink(sizey)"
						} else {
							::winks::PlayWink "$wink(swf)"
						}
					}

					return
				}
			}
			
			# if the wink is unknown ask for it

			# keep information about the wink
			set wink(name) "$wink_name"
			set wink(stamp) "$stamp"
			set wink(sha1d) "$sha1d"
			set wink(swf) "none"
			set wink(cab) "$cab_file"
			set wink(img) "---unknown-wink---"
			set winks_cache($sha1d) [array get wink]

			# request the msnobject
			set data [string range $data 13 [expr {[string first "stamp=" $data] -2 }] ]
			set data "$data/>"
			::MSNP2P::RequestObjectEx $chatid $user $data "wink"

			# notify 
			NotifyInChatWindow "$chatid" "$sha1d" "$wink(name)" "[::abook::getDisplayNick $user] [trans winks_yourcontact_winks]" 1
			status_log "asked for cab file\n" green	
		}
	}

	#----------------------------------------------------------------------------------
	# ReceiveWink: when an unknown wink cames, we ask for the cab file. This proc is 
	#              called when the cab file transfer is complete. It extracts the 
	#              content to a folder in cache and play its swf.
	#----------------------------------------------------------------------------------
	proc ReceivedWink { event evpar } {
		
		global HOME winks_cache

		upvar 2 $evpar args
		upvar 2 $args(chatid) chatid

		upvar 2 $evpar newvar
		set filename $newvar(filename)
		
		status_log "Received wink file: $filename from $chatid\n" green

		# read the cab file
		set fd1 [open $filename r]
		fconfigure $fd1 -translation binary
		set data [read $fd1]
		close $fd1

		# get sha1d and the partial wink data we had
		set sha1d [::base64::encode [binary format H* [::sha1::sha1 $data]]]
		array set wink $winks_cache($sha1d)

		# get the cab content
		set cab_folder [::md5::md5 $sha1d]
		create_dir [file join "$HOME" winks cache "$cab_folder"] 
		set wink(cab) [file join "$HOME" winks cache $cab_folder $wink(cab)]
		file rename -force "$filename" "$wink(cab)"
		ExtractCab "$wink(cab)" "*" [file join "$HOME" winks cache $cab_folder]

		# read cabs's content.xml file
		set filename [file join "$HOME" winks cache $cab_folder content.xml]
		if { [file exists $filename] == 0 } { 
			amsn::WinWrite $chatid "\n[trans winks_cant_open] \"content.xml\"." red 
			return "" 
		}
		set fd1 [open $filename r]
		fconfigure $fd1 -encoding utf-8
		set data [read $fd1]
		close $fd1
		
		set lista [split $data " "]
		
		# get wink information
		set wink(img) [FindFileName [file join "$HOME" winks cache $cab_folder] [GetFirstAfterInNode $data "thumbnail" "file"]]
		set wink(swf) [FindFileName [file join "$HOME" winks cache $cab_folder] [GetFirstAfterInNode $data "animation" "file"]]
		set wink(sizex) [GetAttrib $lista "wink:sizex"]
		set wink(sizey) [GetAttrib $lista "wink:sizey"]

		# fix missing information
		if { "$wink(name)" == "" || "$wink(name)" == "Unused" } {
			set wink(name) [GetAttrib $lista "wink:name"]
			if { "$wink(name)" == "" } {
				set wink(name) [file rootname [file tail "$wink(swf)"]]
			}
		}		
		if { "$wink(sizex)" == "" } {
			set wink(sizex) 0
			set wink(sizey) 0
		}

		set winks_cache($sha1d) [array get wink]

		SaveCache

		status_log "Wink added to cache succesfully.\n" reed

		set twTag "wink_[::md5::md5 $sha1d]"
		catch { image create photo $twTag -file $wink(img) -format cximage }

		# play the animation
		if {$::winks::config(play_inmediatly)} {
			if { $::winks::config(play_embed) } {
				::winks::PlayWinkInChatWindow "$wink(swf)" "$chatid" "$wink(sizex)" "$wink(sizey)"
			} else {
				::winks::PlayWink "$wink(swf)"
			}
		}
		
	}


	#-------------------------------------------------------------------------------------------
	# WinWritePlayLink: Write Play "winkname" in the chat window, and bind PlayWink on click.
	#-------------------------------------------------------------------------------------------
	proc WinWritePlayLink { chatid sha1d wink_name { cache 0 } } {
		set outText [::ChatWindow::GetOutText [::ChatWindow::For $chatid]]
		set twTag "wink_play_[::md5::md5 $sha1d]"
		$outText tag configure $twTag -foreground #000080 -font splainf -underline true
		$outText tag bind $twTag <Enter> "$outText tag conf $twTag -underline false; $outText conf -cursor hand2"
		$outText tag bind $twTag <Leave> "$outText tag conf $twTag -underline true; $outText conf -cursor xterm"
		$outText tag bind $twTag <<Button1>> "::winks::PlayWinkFromSHA1D \"$chatid\" \"$sha1d\""
		$outText roinsert end "[trans winks_play] \"$wink_name\"." $twTag
	}
	
	#-------------------------------------------------------------------------------------------
	# WinWriteThumbnail: Draws the wink thumbnail to let you play it again or add to your winks
	#-------------------------------------------------------------------------------------------
	proc WinWriteThumbnail { chatid sha1d { cache 0 } } {
		
		if { "$cache" == 1 } {
			global winks_cache
			array set wink $winks_cache($sha1d)
		} else {
			global winks_list
			array set wink $winks_list($sha1d)
		}

		set tw [::ChatWindow::GetOutText [::ChatWindow::For $chatid]]
		
		set twTag "wink_[::md5::md5 $sha1d]"

		set pos [[::ChatWindow::GetOutText [::ChatWindow::For $chatid]] index end-1c]

		if { [file exists $wink(img)] } {
			# if we have the thumbnail, show it
			set thumbnail [image create photo $twTag -file $wink(img) -format cximage]
		} else {
			# if we don't have the thumbnail yet, we'll show the "please wait..." one
			global wink_unknown_thumbnail
			set thumbnail [image create photo $twTag -file "$wink_unknown_thumbnail" -format cximage]
		}

		set chars [string length $twTag]

		set posyx [split $pos "."]

		set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $chars}]"
	

		$tw tag configure smiley -elide true
		$tw tag add smiley $pos $endpos

		$tw tag bind $twTag <Enter> "$tw configure -cursor hand2"
		$tw tag bind $twTag <Leave> "$tw configure -cursor xterm"
		
		
		# left click menu: "play" and "add to winks menu option"
		set copyMenu "${tw}.copy_$twTag"
		if { ![winfo exists $copyMenu] } {
			menu $copyMenu -tearoff 0 -type normal
			$copyMenu add command -label "[trans winks_play_animation]" -command "::winks::PlayWinkFromSHA1D $chatid $sha1d"
			# "add to winks menu" is only for cache winks
			if { $cache == 1 } {
					$copyMenu add command -label "[trans winks_add_to_winks_menu]" -command "::winks::AddWinkFromCache $chatid $sha1d"
			}
			$tw tag bind $twTag <Enter> "$tw configure -cursor hand2"
			$tw tag bind $twTag <Leave> "$tw configure -cursor xterm"
			$tw tag bind $twTag <<Button1>> "tk_popup $copyMenu %X %Y"
		}

		
#		$tw tag bind $twTag <<Button1>> "::winks::PlayWink \"$wink(swf)\""
		if { $cache == 1 } {
			$tw tag bind $twTag <<Button3>> ""
		}

		set cosa [$tw image create $endpos -image $thumbnail -padx 0 -pady 0]
		$tw tag add $twTag $cosa
		$tw tag remove smiley $endpos

	}

	#----------------------------------------------------------------------------------
	# SendWink: Send a wink to the other client. (right click in winks menu) 
	#----------------------------------------------------------------------------------
	proc SendWink { window_name sha1d } {
		
		global winks_list
		array set wink $winks_list($sha1d)

		set chatid [::ChatWindow::Name $window_name]

		# avoid multi-converstation bug
		if { "[::abook::getContactData $chatid clientid]" != "" } {
			# check if the other client support winks
			if { [expr {[::abook::getContactData $chatid clientid] & 0x008000}] == 0 } {
				amsn::WinWrite $chatid "\n[::abook::getDisplayNick $chatid] [trans winks_yourcontact_amsn_client_doesnt_supports_winks] " green 
				return
			}
		}

		status_log "Sending wink... $wink(cab) $chatid\n"

		#  read cab file
		if { [file exists $wink(cab)] == 0 } { 
			return "" 
			amsn::WinWrite $chatid "\n[trans winks_cant_open] \"$wink(cab)\"." red 
		}
		set fd [open $wink(cab) r]
		fconfigure $fd -translation binary
		set data [read $fd]
		close $fd

		#prepare wink name
		set friendly [::base64::encode [ToUnicode $wink(name)] ]

		#  build the msnobj
		set sbn [::MSN::SBFor $chatid]
		create_msnobj [::config::getKey login] 8 $wink(cab) $friendly
		set msnobj [create_msnobj [::config::getKey login] 8 $wink(cab) $friendly $wink(stamp)]

		#  send chunks
		set maxchars 1202
		set sb [::MSN::SBFor $chatid]
		if { $sb == 0 } { return }
		set data "ID: 2\r\nData: $msnobj\r\n"
		set chunks [expr {int( [string length $data] / $maxchars) + 1 } ]
		for {set i 0 } { $i < $chunks } { incr i } {
			set chunk [string range $data [expr $i * $maxchars] [expr ($i * $maxchars) + $maxchars - 1]]
			set msg ""
			if { $i == 0 } {
				set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msnmsgr-datacast\r\n"
				if { $chunks == 1 } {
					set msg "${msg}\r\n$chunk"
				} else { 
					set msgid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr { int([expr {rand() * 1000000}])%65450 } ] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
					set msg "${msg}Message-ID: \{$msgid\}\r\nChunks: $chunks\r\n\r\n$chunk"
				}
			} else {
				set msg "${msg}Message-ID: \{$msgid\}\r\nChunk: $i\r\n\r\n$chunk"
			}
			set msglen [string length $msg]
	
			::MSN::WriteSBNoNL $sbn "MSG" "U $msglen\r\n$msg"
			
		}

		#  notify
		NotifyInChatWindow "$chatid" "$sha1d" "$wink(name)" "[trans winks_sent_wink]"
		status_log "Wink Sent.\n"

	}

	#----------------------------------------------------------------------------------
	# AddWinkFromCache: moves a wink from cache to the wink menu 
	#----------------------------------------------------------------------------------
	proc AddWinkFromCache { chatid sha1d } { 
		
		global HOME winks_cache winks_list
		
		# see if the wink is in our wink menu
		foreach wsha1d [array names winks_list] {
			if { "$sha1d" == "$wsha1d" } {
				status_log "The wink is already in winks menu!" red
				msg_box "[trans winks_the_wink_is_already_in_winks_menu]"
				return
			}
		}

		# see if the wink is in our cache
		foreach wsha1d [array names winks_cache] {
			if { "$sha1d" == "$wsha1d" } {
				array set wink $winks_cache($sha1d)
				
				# check if the wink transfer isn't still in progress
				if { "$wink(img)" == "---unknown-wink---" } {
					msg_box "[trans winks_cant_add_now_wait_thumbnail]"
					return
				}
	
				# relocate files out of cache
				catch {
					set cab_folder [::md5::md5 $sha1d]
					file rename -force [file dirname $wink(swf)] [file join "$HOME" winks $cab_folder]
					if { [file exists $wink(cab)] } {
						file rename -force $wink(cab) [file join "$HOME" winks $cab_folder [file tail $wink(cab)]]
					}
					set wink(cab) [file join "$HOME" winks $cab_folder [file tail $wink(cab)]]
					set wink(swf) [file join "$HOME" winks $cab_folder [file tail $wink(swf)]]
					set wink(img) [file join "$HOME" winks $cab_folder [file tail $wink(img)]]
				} errs
				if { "$errs" != "" } {
					status_log "While deleting wink: $errs" red
				} 

				# update memory arrays
				set winks_list($sha1d) [array get wink] 
				unset winks_cache($sha1d)	
				SaveWinks
				SaveCache
				WinksMenuDestroy				
				
				# notify
				status_log "Wink Added!" green
				msg_box "[trans winks_wink_added]"
				return
			}
		}
	
	}

}

