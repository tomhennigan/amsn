################## GameTTT #######################
## This plugin is the game "Tic Tac Toe" of the ##
## MSN-Zone games. It is fully compatible.      ##
##                                              ##
## written by Mirko Hansen (BaaaZen)            ##
##################################################

# TODO:
#  -use pixmaps instead of buttons and make it look nicer
#  -implement scoring

namespace eval ::GameTTT {
	proc Init { dir } {
		::plugins::RegisterPlugin GameTTT

		# load language file		
		load_lang en [file join $dir "lang"]
		load_lang [::config::getGlobalKey language] [file join $dir "lang"]
	
		RegisterGame
	}
	
	proc DeInit {} {
		::MSNGamesPlugins::unregister "tictactoe"
	}

	proc RegisterGame {} {
		set name "tictactoe"
		set pVer 1
		set appId [list [list "10311021" "Tic Tac Toe (de)"] [list "10401021" "Tic Tac Toe (it)"]]
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
		wm geometry $w 200x200
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
		set w .game_ttt_$sid
		
		set waiting $w.waiting
		$waiting configure -text "[trans gametttopponentready]"
		
		set startbutton $w.startbutton
		if {[winfo exists $startbutton]} {
			$startbutton configure -text "[trans gametttstart]" -state normal -command "::GameTTT::StartClick $sid"
		} else {
			button $startbutton -text "[trans gametttstart]" -command "::GameTTT::StartClick $sid"
			pack configure $startbutton -side bottom -padx 5 -pady 5
		}
		
		#reset internal field and other settings
		array set fieldArray [list]
		for {set x 1} {$x <= 9} {incr x} {
			set fieldArray($x) "0"
		}
		::MSNGamesInterface::setSetting $sid field [array get fieldArray]
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
			frame $playground
		}
		
		for {set x 1} {$x <= 9} {incr x} {
			set button $w.field_$x
			set xpos [expr [expr $x - 1] % 3]
			set ypos [expr [expr [expr $x - 1] - $xpos] / 3]
			
			#set px [expr $xpos * 60]
			#set py [expr $ypos * 60]
			
			if {[winfo exists $button]} {
				$button configure -text "  " -background white -state normal
			} else {
				button $button  -text "  " -background white -padx 2 -pady 2 -command "::GameTTT::SetField $sid $x 1"
				grid $button -column [expr $xpos + 1] -row [expr $ypos + 1] -in $playground
			}
		}
		pack $playground
	}
	
	proc SetField {sid field {local 0}} {
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
		
			#send field information
			::MSNGamesInterface::send $sid "18:$field"
			
			::MSNGamesInterface::setSetting $sid turn 0
			set player [::abook::getPersonal "MFN"]
		} else {
			::MSNGamesInterface::setSetting $sid turn 1
			set player [::MSNGamesInterface::getSetting $sid opponentnick "?"]
		}
		
		if {[::MSNGamesInterface::getSetting $sid startTurn 0] != [::MSNGamesInterface::getSetting $sid turn 0]} {
			set sign "X"
			set color "orange"
		} else {
			set sign "O"
			set color "green"
		}
		
		#set field
		set w .game_ttt_$sid
		set button $w.field_$field
		$button configure -state disabled -disabledforeground black -background $color -text "$sign"
	
		set fieldArray($field) $sign

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
			
			set playground $w.playground
			pack forget $playground
			
			set waiting $w.waiting
			$waiting configure -text "[trans gametttwinner $player]"
			pack $waiting
			
			set startbutton $w.startbutton
			$startbutton configure -state normal -text "[trans gametttrestart]" -command "::GameTTT::RestartGame $sid"
			pack $startbutton
		} elseif {$fieldArray(1) != "0" && $fieldArray(2) != "0" && $fieldArray(3) != "0" && $fieldArray(4) != "0" \
				&& $fieldArray(5) != "0" && $fieldArray(6) != "0" && $fieldArray(7) != "0" && $fieldArray(8) != "0" \
				&& $fieldArray(9) != "0"} {
			#nobody wins

			set playground $w.playground
			pack forget $playground
			
			set waiting $w.waiting
			$waiting configure -text "[trans gametttwinner [trans gametttnobody]]"
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
}
