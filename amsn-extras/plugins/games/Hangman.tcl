#############################################################################
#  ::Games::Hangman															#
#  ======================================================================== #
#	Original author: JeeBee <jonne_z REM0VEatTH1S users.sourceforge.net>	#
#	Contributors:															#
#	- Thanks to Jeroen for drawing Hangman's images.						#
#############################################################################

# FIXME: Check all words in the sentence in an on-line dictionary?

# FIXME: Withdraw/resign round button?

# FIXME: Can also continue as 1-player game with random words?

# FIXME: Status bar can remain black, think when timer is cancelled or
# something?

namespace eval ::Games::Hangman {

  array set GameState {}
  array set HangmanImg [list \
	"big"	"[file join $::Games::dir images Hangman.gif]" \
	"small"	"[file join $::Games::dir images Hangman_small.gif]" ]

  # Defaults for challenges:
  variable __free_letters "none"

  ###########################################################################
  # config_array															#
  # ======================================================================= #
  # Return variables with default values that we want to store				#
  ###########################################################################
  proc config_array {} {
  }

  ###########################################################################
  # build_config															#
  # ======================================================================= #
  # Pack configuration items into pane.										#
  # Return 0 if you don't want a pane for this game.						#
  ###########################################################################
  proc build_config { pane } {
  }

  ###########################################################################
  # init_game																#
  # ======================================================================= #
  # Ask the user about the game configuration								#
  # Returns string that is sent in a challenge								#
  ###########################################################################
  proc init_game { gameID mychat oppchat } {
    variable GameState
	set win_name [string map {"." "" ":" ""} $gameID]
	return [game_configuration $win_name]
  }

  ###########################################################################
  # set_init_game															#
  # ======================================================================= #
  # Set or change game configuration										#
  # This proc is also called when starting a rematch						#
  ###########################################################################
  proc set_init_game { gameID game_init mychat oppchat } {
    variable GameState
	set win_name [string map {"." "" ":" ""} $gameID]
	set myname   [::Games::getNick $mychat]
	set oppname  [::Games::getNick $oppchat]

	# If rematching, disable all letter buttons, and unbind all letters
	if {[info exists GameState($gameID,win_name)]} {
	  for {set a 0} {$a < 26} {incr a} {
		set l [format "%c" [expr {[scan "a" %c] + $a}]]
		.$win_name.$l configure -state disabled
	  }
	}

    # First time, set non-changing GameState
    if {![info exists GameState($gameID,win_name)]} {
	  array set GameState [list 					\
		"$gameID,my_chatid"				"$mychat"	\
		"$gameID,my_name"				"$myname"	\
		"$gameID,my_score"				0			\
		"$gameID,opponent_chatid"		"$oppchat"	\
		"$gameID,opponent_name"			"$oppname"	\
		"$gameID,opponent_score"		0			\
		"$gameID,round"					1			\
		"$gameID,rematch_quick_move"	{}			\
		"$gameID,processing_guess"		0			\
		"$gameID,free_letters"			"none"		\
		"$gameID,status_blink"			""			\
		"$gameID,win_name"				"$win_name" ]
	}

	# Set or reset stuff that must happen each round
	array set GameState [list						\
	  "$gameID,round_started"			0			\
	  "$gameID,round_finished"			0			\
	  "$gameID,received_word"			{}			\
	  "$gameID,private_word"			{}			\
	  "$gameID,public_word"				{}			\
	  "$gameID,opp_error_letters"		{}			\
	  "$gameID,opp_errors"				0			\
	  "$gameID,my_errors"				0			]

	# Process game_init
	foreach rec [split $game_init ","] {
	  foreach {key value} [split $rec "="] {
		switch -exact $key {
		  "free_letters" { set GameState($gameID,free_letters) $value }
		}
	  }
	}

	return $game_init
  }

  proc quit {gameID} {
	variable GameState
	::Games::SendQuit $gameID
	destroy .$GameState($gameID,win_name)
  }

  # Opponent quits
  proc opponent_quits {gameID chatid} {
	variable GameState
	set win_name $GameState($gameID,win_name)

	# Test whether we already left
	if {![winfo exists .$win_name]} {
	  return
	}

	# Disable letter buttons
	for {set a 0} {$a < 26} {incr a} {
	  set l [format "%c" [expr {[scan "a" %c] + $a}]]
	  .$win_name.$l configure -state disabled
	}
	# Disable word sending
	.$win_name.setword configure -state disabled
	.$win_name.sendword configure -state disabled
	change_status $gameID \
	  "$GameState($gameID,opponent_name) [::Games::trans quits]"
	# Hide rematch button
	pack forget .$win_name.status.rematch
  }

  proc Rematch {gameID} {
	variable GameState
	set win_name $GameState($gameID,win_name)

	set_init_game $gameID "" "" ""
	SetWord $gameID ""
	set_my_image $gameID 0
	SetOpponentWord $gameID "" ""
	set_opp_image $gameID 0
	# Reset button background colors
	for {set a 0} {$a < 26} {incr a} {
	  set l [format "%c" [expr {[scan "a" %c] + $a}]]
	  .$win_name.$l configure -disabledforeground "gray"
	}
	# Enable word sending
	.$win_name.setword configure -state normal
	.$win_name.setword delete 0 end
	.$win_name.sendword configure -state normal
	# Reset status bar
	change_status $gameID "[::Games::trans send_word_to_guess]"
	# Forget Rematch button and increase round number
	pack forget .$win_name.status.rematch
	incr GameState($gameID,round)
	.$win_name.scores configure \
	  -text "[::Games::trans Scores] ([::Games::trans round] $GameState($gameID,round))"

	if {[string length $GameState($gameID,rematch_quick_move)] > 0} {
      opponent_moves $gameID "" $GameState($gameID,rematch_quick_move)
	  set GameState($gameID,rematch_quick_move) {}
	}
  }

  proc start_game {gameID} {
	variable GameState
	variable HangmanImg
	set win_name $GameState($gameID,win_name)

	# Preload Hangman images, if not yet done so
	if {![info exists HangmanImg(big,0)]} {
	  for {set i 0} {$i <= 12} {incr i} {
		foreach size {big small} {
		  # Loading Hangman frame $i
		  if {[catch {image create photo -file $HangmanImg($size) \
			-format [list gif -index $i]} tmpImg] != 0} {
			::Games::log "Error loading hangman image frame from $HangmanImg($size)."
			return
		  }
		  set HangmanImg($size,$i) [image create photo]
		  if {$i > 0 && $i < 12} { 
			$HangmanImg($size,$i) copy $HangmanImg($size,[expr {$i-1}]) 
		  }
		  $HangmanImg($size,$i) copy $tmpImg
		  image delete $tmpImg
		}
	  }
	}

	toplevel .$win_name
	wm protocol .$win_name WM_DELETE_WINDOW "::Games::Hangman::quit $gameID"
	wm title .$win_name "[::Games::trans Hangman]"

	# Our hangman
	labelframe .$win_name.my -text $GameState($gameID,my_name)
	label .$win_name.my_hman
	set_my_image $gameID 0
	frame .$win_name.my_word
	SetWord $gameID ""
	pack .$win_name.my_hman -in .$win_name.my -fill both -expand 1
	pack .$win_name.my_word -in .$win_name.my
	# Opponent progress
	labelframe .$win_name.opp -text $GameState($gameID,opponent_name)
	label .$win_name.opp_hman -anchor e
	set_opp_image $gameID 0
	frame .$win_name.opp_word
	SetOpponentWord $gameID "" ""
	pack .$win_name.opp_hman -in .$win_name.opp -fill both -expand 1
	pack .$win_name.opp_word -in .$win_name.opp -anchor w
	
	labelframe .$win_name.guess -text "[::Games::trans click_sends_guess]"
	# Add a button for each letter
	for {set a 0} {$a < 26} {incr a} {
	  set l [format "%c" [expr {[scan "a" %c] + $a}]]
	  set L [string toupper $l]
	  button .$win_name.$l -state disabled -text $L \
		-command "::Games::Hangman::LetterButton $gameID $L"
	  bind .$win_name <$l> ".$win_name.$l invoke"
	  grid .$win_name.$l -column [expr {$a % 6}] -row [expr {$a / 6}] \
		-padx 3 -pady 3 -in .$win_name.guess
	}
	# Your word
	labelframe .$win_name.word -text "[::Games::trans Word]"
	entry .$win_name.setword -width 40
	bind .$win_name.setword <Return> ".$win_name.sendword invoke"
	button .$win_name.sendword -text "Send" -command "::Games::Hangman::SendWord $gameID"
	pack .$win_name.setword .$win_name.sendword -in .$win_name.word -anchor w -side left -padx 10
	# Scores
	labelframe .$win_name.scores \
	  -text "[::Games::trans Scores] ([::Games::trans round] $GameState($gameID,round))"
	label .$win_name.scores.my_name -text $GameState($gameID,my_name) -anchor w
	label .$win_name.scores.my_score -text "0" -anchor w
	label .$win_name.scores.opp_name -text $GameState($gameID,opponent_name) -anchor w
	label .$win_name.scores.opp_score -text "0" -anchor w
	grid .$win_name.scores.my_name .$win_name.scores.my_score -in .$win_name.scores -sticky news
	grid .$win_name.scores.opp_name .$win_name.scores.opp_score -in .$win_name.scores -sticky news
	# Status bar
	labelframe .$win_name.status -text "[::Games::trans status]"
	label .$win_name.status.msg -text "[::Games::trans send_word_to_guess]"
	pack .$win_name.status.msg -in .$win_name.status -anchor w -side left
	# Rematch button
	button .$win_name.status.rematch -text "[::Games::trans click_rematch]" \
	  -command "::Games::Hangman::Rematch $gameID"

	grid .$win_name.my .$win_name.guess -sticky news -padx 10 -pady 10
	grid ^ .$win_name.opp -sticky news -padx 10 -pady 10
	grid .$win_name.word .$win_name.scores -sticky news -padx 10 -pady 10
	grid .$win_name.status - -sticky news -padx 10 -pady 10
	::Games::moveinscreen .$win_name
  }

  proc set_my_image {gameID i} {
	variable GameState
	variable HangmanImg
	set win_name $GameState($gameID,win_name)

    .$win_name.my_hman configure -image $HangmanImg(big,$i)

	# Display number of guesses remaining
	set rem [expr {11-$GameState($gameID,my_errors)}]
	.$win_name.my configure -text \
	  "$GameState($gameID,my_name) ($rem [::Games::trans guesses_remaining])"
  }

  proc set_opp_image {gameID i} {
	variable GameState
	variable HangmanImg
	set win_name $GameState($gameID,win_name)

    .$win_name.opp_hman configure -image $HangmanImg(small,$i)

	# Display number of guesses remaining
	set rem [expr {11-$GameState($gameID,opp_errors)}]
	.$win_name.opp configure \
	  -text "$GameState($gameID,opponent_name) ($rem [::Games::trans guesses_remaining])"
  }

  proc LetterButton {gameID L} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	set l [string tolower $L]

	if {$GameState($gameID,processing_guess) == 0} {
	  set GameState($gameID,processing_guess) 1
	  .$win_name.$l configure -state disabled
	  .$win_name.$l configure -disabledforeground "dark green"
	  ::Games::SendMove $gameID "GUESS=$l"
	}
  }

  # Opponent clicked 'letter'
  proc ProcessGuess {gameID letter} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	set public_word $GameState($gameID,public_word)
	set private_word $GameState($gameID,private_word)

	# Copy all occurrences of 'letter' from private to public word
	set match 0
	for {set i 0} {$i < [string length $private_word]} {incr i} {
	  set l [string index $private_word $i]
	  if {[string toupper $l] == [string toupper $letter] && \
          [string index $public_word $i] == "_"} {
		set match 1
		set public_word [string replace $public_word $i $i $l]
	  }
	}
	if {$match == 1} {
	  set GameState($gameID,public_word) $public_word
	  ::Games::SendMove $gameID "GOOD=$public_word"
	} else {
	  ::Games::SendMove $gameID "BAD=$letter"
	  incr GameState($gameID,opp_errors)
	  if {$GameState($gameID,opp_errors) < 12} {
		set_opp_image $gameID $GameState($gameID,opp_errors)
	  }
	  set GameState($gameID,opp_error_letters) \
		"$GameState($gameID,opp_error_letters) [string toupper $letter]"
	}
    SetOpponentWord $gameID $public_word $GameState($gameID,opp_error_letters)
	CheckGameState $gameID
  }

  proc SendWord {gameID} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	set private_word [.$win_name.setword get]
	# Replace our alphabet to underscores
	set public_word [regsub -nocase -all {([a-z])} $private_word "_"]
	# Apply free letter method
	switch -exact $GameState($gameID,free_letters) {
	  "none"	{}
	  "first"	{ set first [string first "_" $public_word]
				  if {$first != -1} {
					set l [string index $private_word $first]
					set public_word [string replace $public_word $first $first $l]
				  }
				}
	  "random"	{ set lst [regexp -all -indices -inline "_" $public_word]
				  if {[llength $lst] > 0} {
				    set r [myRand 0 [expr {[llength $lst]-1}]]
					set l [string index $private_word [lindex [lindex $lst $r] 0]]
					set public_word [string replace $public_word \
					  [lindex [lindex $lst $r] 0] [lindex [lindex $lst $r] 1] $l]
				  }
				}
	}
	# public_word must contain underscores
	# private_word must *not* contain underscores
	if {[string first "_" $public_word] == -1 || \
        [string first "_" $private_word] >= 0} {
	  change_status $gameID "[::Games::trans invalid_word]"
	  return
	}
	set GameState($gameID,private_word) $private_word
	set GameState($gameID,public_word) $public_word
	::Games::SendMove $gameID "WORD=$public_word"
	# Disable word sending
	.$win_name.setword configure -state disabled
	.$win_name.sendword configure -state disabled
	SetOpponentWord $gameID "$public_word" ""
	change_status $gameID "[::Games::trans wait_for_word]"
	CheckGameState $gameID
  }

  # Opponent sended us a word
  proc SetWord {gameID word} {
	variable GameState
	set win_name $GameState($gameID,win_name)

	# Add spaces everywhere
	set word [join [split $word {}] " "]

	if {![winfo exists .$win_name.my_word1]} {
      label .$win_name.my_word1 -text $word
	  pack .$win_name.my_word1 -in .$win_name.my_word -pady 2
	} else {
	  .$win_name.my_word1 configure -text "$word"
	}
  }

  proc SetOpponentWord {gameID word errors} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	# Add spaces everywhere
	set word [join [split $word {}] " "]
	set errors [join [split $errors {}] " "]
	# Word opponent has to guess
	if {![winfo exists .$win_name.opp_word1]} {
	  label .$win_name.opp_word1 -text "$word" -anchor w
	  pack .$win_name.opp_word1 -in .$win_name.opp_word -pady 2 -anchor w
	} else {
	  .$win_name.opp_word1 configure -text "$word"
	}
	# Errors
	if {![winfo exists .$win_name.opp_word2]} {
	  label .$win_name.opp_word2 -foreground red -text "$errors" -anchor w
	  pack .$win_name.opp_word2 -in .$win_name.opp_word -pady 2 -anchor w
	} else {
	  .$win_name.opp_word2 configure -text "$errors"
	}
  }

  proc opponent_moves {gameID sender move} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	
	set idx [string first "=" $move]
	if {$idx != -1} {
	  set key   [string range $move 0 [expr {$idx - 1}]]
	  set value [string range $move [expr {$idx + 1}] end]

	  switch -exact $key {
		"WORD"  {	if {$GameState($gameID,round_finished) == 1} {
					  # Opponent set word, but we still have to click Rematch
					  set GameState($gameID,rematch_quick_move) $move
					  change_status $gameID "[::Games::trans rematch_quick]"
					  return
					} else {
					  set GameState($gameID,received_word) $value
					  SetWord $gameID $value
					}
				}
		"GUESS" {	ProcessGuess $gameID $value
				}
		"GOOD"	{	set GameState($gameID,processing_guess) 0
					set GameState($gameID,received_word) $value
					SetWord $gameID $value
				}
		"BAD"	{	set GameState($gameID,processing_guess) 0
					incr GameState($gameID,my_errors)
					if {$GameState($gameID,my_errors) < 12} {
					  set_my_image $gameID $GameState($gameID,my_errors)
					}
					.$win_name.$value configure -disabledforeground red
				}
	  }
	}

	CheckGameState $gameID
  }

  proc CheckGameState {gameID} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	set new_status ""

	# If we (1) did not yet start, (2) received a word in this round and
	# (3) sended a word, we enable the letter buttons here
	if {$GameState($gameID,round_started) == 0 && \
        [string length $GameState($gameID,received_word)] > 0 && \
        [string length $GameState($gameID,private_word)] > 0} {
	  set GameState($gameID,round_started) 1
	  # Enable letter buttons
	  for {set a 0} {$a < 26} {incr a} {
		set l [format "%c" [expr {[scan "a" %c] + $a}]]
		.$GameState($gameID,win_name).$l configure -state normal
	  }
	  set new_status "[::Games::trans game_started]"
	} elseif {$GameState($gameID,round_finished) == 0} {
	  set our_state 0
	  set opp_state 0
	  ########################################################
	  # Individual check for us
	  ########################################################
	  if {$GameState($gameID,my_errors) > 10} {
		# We hang
		set our_state -1
		set new_status "[::Games::trans you_hang]"
	  } elseif {[string length $GameState($gameID,received_word)] > 0 && \
                [string first "_" $GameState($gameID,received_word)] == -1} {
		# We have found the solution
		set_my_image $gameID 12
		set our_state 1
		set new_status "[::Games::trans word_found]"
	  }
	  if {$our_state != 0} {
		# We are done, disable buttons
		for {set a 0} {$a < 26} {incr a} {
		  set l [format "%c" [expr {[scan "a" %c] + $a}]]
		  .$win_name.$l configure -state disabled
		}
	  }
	  ########################################################
	  # Individual check for opponent
	  ########################################################
	  if {$GameState($gameID,opp_errors) > 10} {
		# Opponent hangs
		set opp_state -1
	  } elseif {[string length $GameState($gameID,public_word)] > 0 && \
                [string first "_" $GameState($gameID,public_word)] == -1} {
		# Opponent found the solution
		set_opp_image $gameID 12
		set opp_state 1
	  }
	  ########################################################
	  # Joint check whether game is finished
	  ########################################################
	  if {$our_state == -1 && $opp_state == 1} {
		# Game over, 0-2
		set new_status "[::Games::trans game_over_02]"
		incr GameState($gameID,opponent_score)
		incr GameState($gameID,opponent_score)
	  } elseif {$our_state == 1 && $opp_state == -1} {
		# Game over, 2-0
		set new_status "[::Games::trans game_over_20]"
		incr GameState($gameID,my_score)
		incr GameState($gameID,my_score)
	  } elseif {$our_state == -1 && $opp_state == -1} {
		# Game over, 0-0
		set new_status "[::Games::trans game_over_00]"
	  } elseif {$our_state == 1 && $opp_state == 1 && \
                $GameState($gameID,my_errors) < $GameState($gameID,opp_errors)} {
		# Game over, 2-1
		set new_status "[::Games::trans game_over_21]"
		incr GameState($gameID,my_score)
		incr GameState($gameID,my_score)
		incr GameState($gameID,opponent_score)
	  } elseif {$our_state == 1 && $opp_state == 1 && \
                $GameState($gameID,my_errors) > $GameState($gameID,opp_errors)} {
		# Game over, 1-2
		set new_status "[::Games::trans game_over_12]"
		incr GameState($gameID,my_score)
		incr GameState($gameID,opponent_score)
		incr GameState($gameID,opponent_score)
	  } elseif {$our_state == 1 && $opp_state == 1} {
		# Game over, 1-1
		set new_status "[::Games::trans game_over_11]"
		incr GameState($gameID,my_score)
		incr GameState($gameID,opponent_score)
	  }
	  if {$our_state != 0 && $opp_state != 0} {
		pack .$win_name.status.rematch -in .$win_name.status -anchor w -side right
		set GameState($gameID,round_finished) 1
	  }
	}
	if {$new_status != ""} {
	  change_status $gameID "$new_status"
	}
	# Update player scores
	.$win_name.scores.my_score configure -text $GameState($gameID,my_score)
	.$win_name.scores.opp_score configure -text $GameState($gameID,opponent_score)
  }

  proc game_configuration {win_name} {
	variable __challenge "none"
	variable __win_name $win_name
	variable __free_letters

	toplevel .${win_name}_gc
	wm title .${win_name}_gc "[::Games::trans specify_configuration]"
	wm protocol .${win_name}_gc WM_DELETE_WINDOW ".${win_name}_gc.cancel invoke"

	# Methods for providing free letters
	labelframe .${win_name}_gc.lbf1 -text "[::Games::trans fl_method]"
	listbox .${win_name}_gc.lst -selectmode single -height 3
	.${win_name}_gc.lst insert end \
	  "[::Games::trans fl_none]" "[::Games::trans fl_first]" "[::Games::trans fl_random]"
	switch -exact $__free_letters {
	  "none"    { .${win_name}_gc.lst selection set 0 }
	  "first"	{ .${win_name}_gc.lst selection set 1 }
	  "random"	{ .${win_name}_gc.lst selection set 2 }
	}
	pack .${win_name}_gc.lst -in .${win_name}_gc.lbf1 -anchor w

	# Challenge and cancel button
    frame .${win_name}_gc.buttons
    button .${win_name}_gc.ok -text "[::Games::trans challenge]" -command {
      switch -exact [.${::Games::Hangman::__win_name}_gc.lst curselection] {
        0 { set ::Games::Hangman::__free_letters "none" }
        1 { set ::Games::Hangman::__free_letters "first" }
        2 { set ::Games::Hangman::__free_letters "random" }
      }
      set ::Games::Hangman::__challenge \
		"free_letters=${::Games::Hangman::__free_letters}"
    }
    button .${win_name}_gc.cancel -text "[::Games::trans cancel]" -command {
      set ::Games::Hangman::__challenge ""
    }
    pack .${win_name}_gc.ok .${win_name}_gc.cancel -in .${win_name}_gc.buttons -side left

	# Pack game configuration window
    grid .${win_name}_gc.lbf1 -padx 10 -sticky news
    grid .${win_name}_gc.buttons -padx 10 -sticky news
    ::Games::moveinscreen .${win_name}_gc

	# Wait for user to specify game configuration
	update idletask
	grab set .${win_name}_gc
	tkwait variable ::Games::Hangman::__challenge
	destroy .${win_name}_gc

	return $__challenge
  }

  proc change_status {gameID new_msg} {
	variable GameState
	set win_name $GameState($gameID,win_name)

	# Ignore if state did not change
	set old_msg [.$win_name.status.msg cget -text]
	if {$old_msg == $new_msg} {
	  return
	}

	.$win_name.status.msg configure -text "$new_msg"

	# If status is blinking already, cancel it
	if {$GameState($gameID,status_blink) != ""} {
	  after cancel $GameState($gameID,status_blink)
	}

	set GameState($gameID,status_blink) \
	  [after idle [list ::Games::Hangman::status_blink $gameID 250 12]]
  }

  proc status_blink {gameID t c} {
	variable GameState
	set win_name $GameState($gameID,win_name)

	if {[winfo exists .$win_name.status.msg] && $c > 0} {
      set fg [.$win_name.status.msg cget -foreground]
      set bg [.$win_name.status.msg cget -background]
      .$win_name.status.msg configure -foreground $bg -background $fg
	  set GameState($gameID,status_blink) \
        [after $t [list ::Games::Hangman::status_blink $gameID $t [expr {$c-1}]]]
	} else {
	  set GameState($gameID,status_blink) ""
	}
  }
}

