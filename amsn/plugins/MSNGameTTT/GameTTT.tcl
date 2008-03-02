################## GameTTT #######################
## This plugin is the game "Tic Tac Toe" of the ##
## MSN-Zone games. It is fully compatible.      ##
##                                              ##
## written by Mirko Hansen (BaaaZen)            ##
##################################################

namespace eval ::GameTTT {
	proc Init { dir } {
		variable pluginDir
		set pluginDir $dir
	
		::plugins::RegisterPlugin GameTTT

		# load language file		
		load_lang en [file join $dir "lang"]
		load_lang [::config::getGlobalKey language] [file join $dir "lang"]
	
		RegisterGame
	}
	
	proc DeInit {} {
		variable loadedImages
		
		set imgs [array names loadedImages]
		foreach img $imgs {
			image destroy $img
		}
	
		::MSNGamesPlugins::unregister "tictactoe"
	}

	proc RegisterGame {} {
		set name "tictactoe"
		set pVer 1
		set appId [list [list "1021" [trans gamettttitle]]]
		set funcs [list \
			"::GameTTT::onCreate" \
			"::GameTTT::onDestroy" \
			"::GameTTT::onRestart" \
			"::GameTTT::onStart" \
			"::GameTTT::onGameEnd" \
			"::GameTTT::onMessage" \
		]

		set ret [::MSNGamesPlugins::register $name $pVer $appId $funcs]
		if {$ret != $pVer} {
			#oops, seems like plugin has older protocol version or registering was unsuccessful so unregister again
			status_log "registering tictactoe was unsuccessful, return code: $ret" red
			::MSNGamesPlugins::unregister $name
		}
	}
	
	#called after game accepted, following loading phase of the game on WLM
	proc onCreate {sid {param ""}} {
		set w .game_ttt_$sid
		
		#create window
		toplevel $w
		wm geometry $w 228x300
		wm resizable $w 0 0
		wm title $w "[trans gametttgamesessionwith [trans gamettttitle] [::MSNGamesInterface::getSetting $sid opponentnick]]"
		wm protocol $w WM_DELETE_WINDOW "::GameTTT::CloseWindow $sid"
	
		#create "opponent loading" text
		set waiting $w.waiting
		label $waiting -wraplength 180 -text "[trans gametttopponentloading]"
		pack $waiting
		
		#set starting turn
		set startTurn [::MSNGamesInterface::getSetting $sid inviter 0]
		::MSNGamesInterface::setSetting $sid startTurn $startTurn
		::MSNGamesInterface::setSetting $sid turn $startTurn
	}
	
	#called after the opponent closed the game or we have successfully closed the game
	proc onDestroy {sid {param ""}} {
		if {[::MSNGamesInterface::getSetting $sid isCanceled 0] == 0} {
			::MSNGamesInterface::setSetting $sid isCanceled 1
			
			set w .game_ttt_$sid

			set playground $w.playground
			if {[winfo exists $playground] && [winfo ismapped $playground]} {
				pack forget $playground
			}
			
			set startbutton $w.startbutton
			if {[winfo exists $startbutton] && [winfo ismapped $startbutton]} {
				pack forget $startbutton
			}

			set waiting $w.waiting
			if {![winfo ismapped $waiting]} {
				pack $waiting
			}
			$waiting configure -text "[trans gametttgameclosed]"
		}
	}
	
	#called after both sides have accepted a restart
	proc onRestart {sid {param ""}} {
		#set correct turn
		set startTurn [expr [expr [::MSNGamesInterface::getSetting $sid startTurn 0] + 1] % 2]
		::MSNGamesInterface::setSetting $sid startTurn $startTurn
		::MSNGamesInterface::setSetting $sid turn $startTurn
		
		#reset all data
		::MSNGamesInterface::setSetting $sid isStartedLocal 0
		::MSNGamesInterface::setSetting $sid isStartedRemote 0
	}
	
	#called after opponent is ready after loading phase on WLM
	proc onStart {sid {param ""}} {
		#reset internal field and other settings
		array set fieldArray [list]
		for {set x 1} {$x <= 9} {incr x} {
			set fieldArray($x) "0"
		}
		::MSNGamesInterface::setSetting $sid field [array get fieldArray]

		#setup waiting screen on first round
		if {[::MSNGamesInterface::getSetting $sid firstRound 1] == 1} {
			set w .game_ttt_$sid
			set waiting $w.waiting
			$waiting configure -text "[trans gametttopponentready]"
			
			set startbutton $w.startbutton
			if {![winfo exists $startbutton]} {
				button $startbutton -text "[trans gametttstart]" -command "::GameTTT::StartClick $sid"
				pack configure $startbutton -side bottom -padx 5 -pady 5
			}
			
			::MSNGamesInterface::setSetting $sid firstRound 0
		} else {
			CheckStartRemote $sid
		}
	}

	#called once after opponent has clicked the restart button
	proc onGameEnd {sid {param ""}} {
		#simply ignore it here
	}

	#called whenever a game-messages is received
	proc onMessage {sid param} {
		set msg [split $param :]
		if {[lindex $msg 0] == "18"} {
			#in-game message
			if {[lindex $msg 1] == "-2"} {
				if {[::MSNGamesInterface::getSetting $sid isStartedRemote 0] == 0} {
					::MSNGamesInterface::setSetting $sid isStartedRemote 1
				}
			} elseif {[lindex $msg 1] == "-1"} {
				::MSNGamesInterface::setSetting $sid isStartedRemote 2
			} else {
				SetField $sid [lindex $msg 1]
			}
		} elseif {[lindex $msg 0] == "0"} {
			#system message
		}
	}
	
	proc CloseWindow {sid} {
		if {[::MSNGamesInterface::getSetting $sid isCanceled 0] == 0} {
			::MSNGamesInterface::setSetting $sid isCanceled 1
			::MSNGamesInterface::closeGame $sid
		}

		set w .game_ttt_$sid
		if {[winfo exists $w]} {
			destroy $w
			::MSNGamesInterface::destroyGame $sid
		}
	}
	
	proc StartClick {sid} {
		set w .game_ttt_$sid
		set waiting $w.waiting
		$waiting configure -text "[trans gametttopponentnotready]"

		set startbutton $w.startbutton
		$startbutton configure -state disabled -text "[trans gametttwait]"
		
		CheckStartRemote $sid
	}
	
	proc CheckStartRemote {sid} {
		if {[::MSNGamesInterface::getSetting $sid isStartedLocal 0] == 0 || [::MSNGamesInterface::getSetting $sid isStartedRemote 0] == 0} {
			::MSNGamesInterface::send $sid "18:-2"
			::MSNGamesInterface::setSetting $sid isStartedLocal 1
		} elseif {[::MSNGamesInterface::getSetting $sid isStartedLocal 0] == 1} {
			::MSNGamesInterface::send $sid "18:-1"
			::MSNGamesInterface::setSetting $sid isStartedLocal 2
		} elseif {[::MSNGamesInterface::getSetting $sid isStartedLocal 0] == 2} {
			::MSNGamesInterface::send $sid "18:-2"
			::MSNGamesInterface::setSetting $sid isStartedLocal 3
		}

		if {[::MSNGamesInterface::getSetting $sid isStartedLocal 0] == 3 && [::MSNGamesInterface::getSetting $sid isStartedRemote 0] == 2} {
			#ok, we can begin
			StartReady $sid
		} else {
			#retry starting again after a little break
			if {[::MSNGamesInterface::getSetting $sid isCanceled 0] == 0} {
				if {[::MSNGamesInterface::getSetting $sid isStartedRemote 0] == 0} {
					after 2000 "::GameTTT::CheckStartRemote $sid"
				} else {
					after 500 "::GameTTT::CheckStartRemote $sid"
				}
			}
		}
	}
	
	proc StartReady {sid} {
		#ready to go
		set w .game_ttt_$sid

		set waiting $w.waiting
		pack forget $waiting
		
		set startbutton $w.startbutton
		pack forget $startbutton
		
		set playground $w.playground
		if {![winfo exists $playground]} {
			canvas $playground -width 228 -height 300
			
			$playground create image 0 0 -anchor nw -image [GetImage "background.png"] -tags background
			$playground create text 114 260 -text "" -font bboldf -tags displayturn
			$playground create text 114 281 -text "" -font bboldf -fill #111111 -tags displayscore

			for {set x 1} {$x <= 9} {incr x} {
				set xpos [expr [expr $x - 1] % 3]
				set ypos [expr [expr [expr $x - 1] - $xpos] / 3]
				set px [expr [expr $xpos * 76] + 37]
				set py [expr [expr $ypos * 80] + 40]
				
				$playground create image $px $py -image [GetImage "empty_normal.png"] -state hidden -tags ${x}_empty_empty
				$playground create image $px $py -image [GetImage "empty_normal.png"] -activeimage [GetImage "x_hover.png"] -state hidden -tags ${x}_empty_x
				$playground create image $px $py -image [GetImage "empty_normal.png"] -activeimage [GetImage "o_hover.png"] -state hidden -tags ${x}_empty_o
				$playground create image $px $py -image [GetImage "x_normal.png"] -state hidden -tags ${x}_x_x
				$playground create image $px $py -image [GetImage "o_normal.png"] -state hidden -tags ${x}_o_o

				$playground bind ${x}_empty_x <Button1-ButtonRelease> "::GameTTT::SetField $sid $x 1"
				$playground bind ${x}_empty_o <Button1-ButtonRelease> "::GameTTT::SetField $sid $x 1"
			}
		}

		#setup visibility
		for {set x 1} {$x <= 9} {incr x} {
			set xpos [expr [expr $x - 1] % 3]
			set ypos [expr [expr [expr $x - 1] - $xpos] / 3]
			
			if {[::MSNGamesInterface::getSetting $sid turn 0] == 1} {
				$playground itemconfigure ${x}_empty_empty -state hidden
				$playground itemconfigure ${x}_empty_x -state normal
			} else {
				$playground itemconfigure ${x}_empty_empty -state normal
				$playground itemconfigure ${x}_empty_x -state hidden
			}
			$playground itemconfigure ${x}_empty_o -state hidden
			$playground itemconfigure ${x}_x_x -state hidden
			$playground itemconfigure ${x}_o_o -state hidden
		}
		
		#setup text
		if {[::MSNGamesInterface::getSetting $sid turn 0] == 1} {
			$playground itemconfigure displayturn -fill #FF0000 -text [trans gametttyourturn]
		} else {
			$playground itemconfigure displayturn -fill #FF0000 -text [trans gametttopponentsturn]
		}
		$playground itemconfigure displayscore -text "[trans gametttyou] - [::MSNGamesInterface::getSetting $sid score1 0]:[::MSNGamesInterface::getSetting $sid score0 0] - [trans gametttopponent]"
		
		pack $playground
	}
	
	proc SetField {sid field {local 0}} {
		set w .game_ttt_$sid
		set playground $w.playground

		set fieldList [::MSNGamesInterface::getSetting $sid field [list]]
		array set fieldArray $fieldList
		if {![info exists fieldArray($field)]} {
			#this field seems to be invalid
			return
		} elseif {[set fieldArray($field)] != "0"} {
			#this field was already set
			return
		}
		
		if {$local == 1} {
			if {[::MSNGamesInterface::getSetting $sid turn 0] == 0} {
				return
			}
		
			#disable fields
			for {set x 1} {$x <= 9} {incr x} {
				if {[set fieldArray($x)] == "0"} {
					$playground itemconfigure ${x}_empty_x -state hidden
					$playground itemconfigure ${x}_empty_o -state hidden
					$playground itemconfigure ${x}_empty_empty -state normal
				}
			}

			#send field information
			::MSNGamesInterface::send $sid "18:$field"
			
			::MSNGamesInterface::setSetting $sid turn 0
			set player [::abook::getPersonal "MFN"]
		} else {
			::MSNGamesInterface::setSetting $sid turn 1
			set player [::MSNGamesInterface::getSetting $sid opponentnick "?"]
		}
		
		if {[::MSNGamesInterface::getSetting $sid startTurn 0] != [::MSNGamesInterface::getSetting $sid turn 0]} {
			set sign "x"
			set color "#00B900"
			set oppsign "o"
		} else {
			set sign "o"
			set oppsign "x"
			set color "#FF0000"
		}
		
		#set field
		$playground itemconfigure ${field}_empty_empty -state hidden
		$playground itemconfigure ${field}_${sign}_${sign} -state normal
		
		set fieldArray($field) $sign

		if {$local == 0} {
			#enable fields
			for {set x 1} {$x <= 9} {incr x} {
				if {[set fieldArray($x)] == "0"} {
					$playground itemconfigure ${x}_empty_empty -state hidden
					$playground itemconfigure ${x}_empty_${oppsign} -state normal
				}
			}
			
			#set text
			$playground itemconfigure displayturn -fill $color -text [trans gametttyourturn]
		} else {
			#set text
			$playground itemconfigure displayturn -fill $color -text [trans gametttopponentsturn]
		}
		
		#check for winner
		if {($fieldArray(1) == $fieldArray(2) && $fieldArray(2) == $fieldArray(3) && $fieldArray(1) != "0") \
			|| ($fieldArray(4) == $fieldArray(5) && $fieldArray(5) == $fieldArray(6) && $fieldArray(4) != "0") \
			|| ($fieldArray(7) == $fieldArray(8) && $fieldArray(8) == $fieldArray(9) && $fieldArray(7) != "0") \
			|| ($fieldArray(1) == $fieldArray(4) && $fieldArray(4) == $fieldArray(7) && $fieldArray(1) != "0") \
			|| ($fieldArray(2) == $fieldArray(5) && $fieldArray(5) == $fieldArray(8) && $fieldArray(2) != "0") \
			|| ($fieldArray(3) == $fieldArray(6) && $fieldArray(6) == $fieldArray(9) && $fieldArray(3) != "0") \
			|| ($fieldArray(1) == $fieldArray(5) && $fieldArray(5) == $fieldArray(9) && $fieldArray(1) != "0") \
			|| ($fieldArray(3) == $fieldArray(5) && $fieldArray(5) == $fieldArray(7) && $fieldArray(3) != "0")} {
			#somebody has a row
			
			#update score
			set score0 [::MSNGamesInterface::getSetting $sid score0 0]
			set score1 [::MSNGamesInterface::getSetting $sid score1 0]
			incr score${local}
			::MSNGamesInterface::setSetting $sid score0 $score0
			::MSNGamesInterface::setSetting $sid score1 $score1

			#show winner and score
			set playground $w.playground
			pack forget $playground
			
			set waiting $w.waiting
			$waiting configure -text "[trans gametttwinner $player $score1 $score0]"
			pack $waiting
			
			set startbutton $w.startbutton
			$startbutton configure -state normal -text "[trans gametttrestart]" -command "::GameTTT::RestartGame $sid"
			pack $startbutton
		} elseif {$fieldArray(1) != "0" && $fieldArray(2) != "0" && $fieldArray(3) != "0" && $fieldArray(4) != "0" \
				&& $fieldArray(5) != "0" && $fieldArray(6) != "0" && $fieldArray(7) != "0" && $fieldArray(8) != "0" \
				&& $fieldArray(9) != "0"} {
			#nobody wins

			#read score
			set score0 [::MSNGamesInterface::getSetting $sid score0 0]
			set score1 [::MSNGamesInterface::getSetting $sid score1 0]

			#show winner and score
			set playground $w.playground
			pack forget $playground
			
			set waiting $w.waiting
			$waiting configure -text "[trans gametttnowinner $score1 $score0]"
			pack $waiting
			
			set startbutton $w.startbutton
			$startbutton configure -state normal -text "[trans gametttrestart]" -command "::GameTTT::RestartGame $sid"
			pack $startbutton
		} else {
			::MSNGamesInterface::setSetting $sid field [array get fieldArray]
		}
	}
	
	proc RestartGame {sid} {
		set w .game_ttt_$sid

		set startbutton $w.startbutton
		$startbutton configure -state disabled -text "[trans gametttwait]"
	
		::MSNGamesInterface::restartGame $sid
	}
	
	proc GetImage {imgfile} {
		variable pluginDir 
		variable loadedImages
		
		if {![info exists loadedImages]} {
			array set loadedImages [list]
		}
		
		if {[info exists loadedImages($imgfile)]} {
			return [set loadedImages($imgfile)]
		}

		if {[catch {set img [image create photo -file [file join $pluginDir "pixmaps" $imgfile] -format cximage]} res]} {
				status_log "::GameTTT::LoadImage - Error loading $imgfile : $res" red
				set img [image create photo]
		}
		
		set loadedImages($imgfile) $img
		
		return $img
	}
}
