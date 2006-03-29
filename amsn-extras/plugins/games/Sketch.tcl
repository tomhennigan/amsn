#############################################################################
#  ::Games::Sketch															#
#  ======================================================================== #
#	Original author: JeeBee <jonne_z REM0VEatTH1S users.sourceforge.net>	#
#	Contributors:															#
#   - Thanks to Bernd Breitenbach for letting me use his code that			#
#     implements the Hourglass (see bottom part of this file).				#
#############################################################################

# FIXME: support for automatically saving all drawings before
# clear canvas

# FIXME: Increase precision !!

# FIXME: Sketch: change statusbar into
# "Some player(s) have guessed the word correctly (displayed in green)."
# FIXME: When drawing while violate is clicked, drawing is still send when
# mouse is released later.

namespace eval ::Games::Sketch {

  variable HourGlass
  variable GameState
  variable Dict
  # Tolerance used for simplifying polylines
  variable eps 3
  variable eps2 9

  variable bkg_color "peach puff"
  variable err_bkg_color "firebrick3"
  variable eraser 0

  # Set round time (in seconds)
  set HourGlass(time_to_go)	180

  # Defaults for challenges
  variable __language "en"
  variable __languages
  variable __win_name

  ###########################################################################
  # config_array															#
  # ======================================================================= #
  # Return variables with default values that we want to store				#
  ###########################################################################
  proc config_array {} {
	return ""
  }

  ###########################################################################
  # build_config															#
  # ======================================================================= #
  # Pack configuration items into pane.										#
  # Return 0 if you don't want a pane for this game.						#
  ###########################################################################
  proc build_config { pane } {
	return 0
  }

  proc init_game { gameID host } {
	variable GameState
	set GameState($gameID,host) $host
	set challenge [game_configuration $gameID]
	return $challenge
  }

  proc set_init_game { gameID host game_init } {
	variable GameState

	set GameState($gameID,host) $host

	foreach rec [split $game_init ","] {
	  foreach {key value} [split $rec "="] {
		switch -exact $key {
		  "LANG" { set GameState($gameID,lang) $value }
		}
	  }
	}
  }

  proc quit {gameID} {
	variable GameState

	# Cancel possibly running hourglass
    if {$GameState($gameID,hg_animate) != ""} {
	  after cancel $GameState($gameID,hg_animate)
 	}

	::Games::SendQuit $gameID
	destroy .$GameState($gameID,win_name)
  }

  proc start_game { gameID } {
	variable GameState
	variable bkg_color

	set win_name [string map {"." "" ":" ""} $gameID]
	array set GameState [list \
	  "$gameID,round"			-1 \
	  "$gameID,scoredround"		[list] \
	  "$gameID,violations"		[list] \
	  "$gameID,old_x"			0 \
	  "$gameID,old_y"			0 \
	  "$gameID,sx"				0 \
	  "$gameID,sy"				0 \
	  "$gameID,current_color"	"sienna" \
	  "$gameID,current_pen"		4 \
	  "$gameID,drawing"			0 \
	  "$gameID,point_list"		{} \
	  "$gameID,spoint_list"		{} \
	  "$gameID,widget_list"		{} \
	  "$gameID,win_name"		$win_name ]

	toplevel .$win_name
    wm protocol .$win_name WM_DELETE_WINDOW "::Games::Sketch::quit $gameID"
    wm title .$win_name "[::Games::trans Sketch]"

	# The canvas
	canvas .$win_name.canvas -relief sunken -background $bkg_color \
	  -width 450 -height 400

	# Time
	labelframe .$win_name.time -text "[::Games::trans Time]"
	hourglass $gameID .$win_name.time.sandglass
	grid .$win_name.time.sandglass -in .$win_name.time

	# Wrong guesses of other players
	labelframe .$win_name.wrongguesses -text "[::Games::trans wrong_guesses]"
	for {set i 0} {$i < 10} {incr i} {
	  label .$win_name.wrongguesses.l$i -text ""
	  pack .$win_name.wrongguesses.l$i -in .$win_name.wrongguesses -anchor w
	}
	# Player list
	labelframe .$win_name.players -text "[::Games::trans players]"

	# Placekeeper to be filled with either draw options or guesses
	frame .$win_name.uc

	# Draw options
	labelframe .$win_name.uc.sk -text "[::Games::trans sketch_tools]"
	button .$win_name.uc.sk.selcolor -text "[::Games::trans Color]" \
	  -background $GameState($gameID,current_color) \
	  -command "::Games::Sketch::chooseColor $gameID .$win_name.uc.sk.selcolor"
	checkbutton .$win_name.uc.sk.eraser -text "[::Games::trans Eraser]" \
	  -variable ::Games::Sketch::eraser
	scale .$win_name.uc.sk.pensize -digit 1 -from 1 -to 41 -tickinterval 10 \
	  -orient h -variable ::Games::Sketch::GameState($gameID,current_pen)
	button .$win_name.uc.sk.clear -text "[::Games::trans Clear]" \
	  -command "::Games::Sketch::clearButton $gameID"
	button .$win_name.uc.sk.skip -text "[::Games::trans Skip]" \
	  -command "::Games::Sketch::skipButton $gameID"
	button .$win_name.uc.sk.btnsave1 -text "[::Games::trans Save]" \
	  -command "::Games::Sketch::save_canvas $gameID"
	pack .$win_name.uc.sk.selcolor .$win_name.uc.sk.eraser .$win_name.uc.sk.pensize \
	  .$win_name.uc.sk.clear .$win_name.uc.sk.skip \
	  .$win_name.uc.sk.btnsave1 -in .$win_name.uc.sk -side left -padx 20

	# Guesses
	labelframe .$win_name.uc.gr -text "[::Games::trans make_guesses]"
	entry .$win_name.uc.gr.guess
	bind .$win_name.uc.gr.guess <Return> ".$win_name.uc.gr.sendguess invoke"
	button .$win_name.uc.gr.sendguess -text "[::Games::trans Send]" \
	  -command "::Games::Sketch::sendGuess $gameID .$win_name.uc.gr.guess"
	button .$win_name.uc.gr.violates -text "[::Games::trans Violation]" \
	  -command "::Games::Sketch::violateButton $gameID"
	button .$win_name.uc.gr.btnsave2 -text "[::Games::trans Save]" \
	  -command "::Games::Sketch::save_canvas $gameID"
	pack .$win_name.uc.gr.guess .$win_name.uc.gr.sendguess .$win_name.uc.gr.violates \
	  .$win_name.uc.gr.btnsave2 -in .$win_name.uc.gr -side left -padx 20

	# Status
	labelframe .$win_name.status -text "[::Games::trans status]"
	label .$win_name.status.lbl -text "[::Games::trans wait_for_host]" -anchor w
	pack .$win_name.status.lbl -in .$win_name.status -fill both -expand 1
	# And a start button for the host only
	if {$GameState($gameID,host) == [::config::getKey login]} {
	  .$win_name.status.lbl configure -text "[::Games::trans wait_for_players]"
	  button .$win_name.start -text "[::Games::trans Start]" \
		-command "::Games::Sketch::start_now $gameID"
	  pack .$win_name.start -in .$win_name.status -side right
	}

	grid .$win_name.time -sticky news
	grid .$win_name.canvas -row 0 -column 1
	grid .$win_name.wrongguesses -row 0 -column 2 -sticky news
	grid ^ ^ .$win_name.players -sticky news
	grid .$win_name.uc - - -sticky news
	grid .$win_name.status - - -sticky news
	grid rowconfigure .$win_name {1 2 3} -weight 1
	grid columnconfigure .$win_name {0 2} -weight 1

	# Set initial width (wider for players list, higher for usercontrols)
	::Games::moveinscreen .$win_name

	# Check if players were already added before game start
	if {[info exists GameState($gameID,addplayers)]} {
	  foreach {player score} $GameState($gameID,addplayers) {
		update_scores $gameID $player $score
	  }
	}
  }

  # 'player' says the drawer violates drawing rules
  proc addViolation {gameID player} {
	variable GameState

	if {$GameState($gameID,host) == [::config::getKey login]} {
	  # We are the host, player says drawer violated drawing rules
	  if {[lsearch -exact $GameState($gameID,violations) $player] == -1} {
	    lappend GameState($gameID,violations) $player
	    # Check whether this ends the current round
		set cnt_v [llength $GameState($gameID,violations)]
		set cnt_p [llength $GameState($gameID,players)]
		if {$cnt_v >= [expr {($cnt_p + 1)/2}]} {
		  # Majority of guessers clicked Violate button.
		  # Skipping round, no points for the drawer this round.
		  set GameState($gameID,scoredround) [list]
          skipButton $gameID
		}
	  }
	}
  }

  proc violateButton {gameID} {
	variable GameState
    addViolation $gameID [::config::getKey login]
	::Games::SendMove $gameID "VIOLATE=[::config::getKey login]"
  }

  proc save_canvas {gameID} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	# Ask user where to save the photo
	set filename [chooseFileDialog "" "[::Games::trans save_drawing]" .$win_name "" save \
	  [list [list "EPS" [list *.eps *.EPS]] [list [trans allfiles] *]]]
	# Save Encapsulated Postscript
	if {"$filename" != ""} {
	  ::Games::log "Saving canvas to $filename for game $gameID"
	  catch { .$win_name.canvas postscript -file $filename }
	}
  }

  proc loadDictionary {langKey} {
	variable Dict
	
	# Check if global dictionary already read.
	if {![info exists Dict($langKey)] || \
        [llength $Dict($langKey)] == 0} {

	  # Save plugin's lang
	  array set plugin_lang [array get ::Games::lang]
	  array unset ::Games::lang

	  set Dict($langKey) [list]
	  set langDir [file join $::Games::dir "lang"]
	  ::Games::load_lang $langKey $langDir

	  foreach {name value} [array get ::Games::lang] {
		if {[string first "word_" $name] == 0} {
		  lappend Dict($langKey) $value
		}
	  }

	  ::Games::log "Sketch dictionary for $langKey read, \
					contains [llength $Dict($langKey)] words."

	  # Restore plugin's lang
	  array unset ::Games::lang
	  array set ::Games::lang [array get plugin_lang]
	}

	return [llength $Dict($langKey)]
  }

  proc select_word {gameID} {
	variable GameState
	variable Dict

	set word_cnt [loadDictionary $GameState($gameID,lang)]
	if {$word_cnt > 0} {
	  # Select a word at random
	  set r [myRand 0 [expr {$word_cnt-1}]]
	  set GameState($gameID,word) [lindex $Dict($GameState($gameID,lang)) $r]
	} else {
	  ::Games::log "Update your language files for the Sketch dictionary! \
					(it is empty for the language that your are using in game ${gameID})"
	  set GameState($gameID,word) "error, my, dictionary, is, empty"
	}
  }

  # Next drawer is set to $r here. However, if that player left the game
  # we keep increasing
  proc select_next_drawer {gameID r} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	set next [expr {$r % [llength $GameState($gameID,players)]}]
	set nextp [lindex $GameState($gameID,players) $next]
	set stop $next
	
	# Check whether player is still in players
	while {[lsearch -exact $GameState($gameID,players) $nextp] == -1} {
	  set next [expr {($next + 1) % [llength $GameState($gameID,players)]}]
	  set nextp [lindex $GameState($gameID,players) $next]
	  if {$stop == $next} {
		# Everybody left???
		break
	  }
	}

	# Give the drawer 10 points for drawing
	set nexts [lsearch -exact $GameState($gameID,scores) $nextp]
	set score [lindex $GameState($gameID,scores) [expr {$nexts+1}]]
	set new_score [expr {$score + 10}]
	::Games::SendMove $gameID "PLAYER=$nextp,SCORE=$new_score"
	update_scores $gameID $nextp $new_score

	# Clearing the canvas for the next round
	clearButton $gameID

	set GameState($gameID,draweridx) $next
	set GameState($gameID,drawer) $nextp
  }

  proc reset_player_colors {gameID} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	set i 0
	while {[winfo exists .$win_name.player$i]} {
	  set pcol [.$win_name.player$i cget -foreground]
	  if {$pcol != "gray"} {
		.$win_name.player$i configure -foreground black
	  }
	  incr i ; incr i
	}
  }

  proc start_now {gameID} {
	variable GameState

	incr GameState($gameID,round)
	set GameState($gameID,credit) 10
	set GameState($gameID,scoredround) [list]
	set GameState($gameID,violations) [list]

	set round $GameState($gameID,round)
	set win_name $GameState($gameID,win_name)

	if {![winfo exists .$win_name]} {
	  # We closed the window already, so bye bye
	  return
	}
	reset_player_colors $gameID

	if { $GameState($gameID,round) == 0 && \
		 $GameState($gameID,host) == [::config::getKey login] } {

	  set r [myRand 0 [expr {[llength $GameState($gameID,players)]-1}]]
	  select_next_drawer $gameID $r
	  ::Games::SendMove $gameID "DRAWER=$GameState($gameID,drawer)"
	  pack forget .$win_name.start
	} elseif {$GameState($gameID,host) == [::config::getKey login]} {
	  select_next_drawer $gameID [expr {$GameState($gameID,draweridx) + 1}]
	  ::Games::SendMove $gameID "DRAWER=$GameState($gameID,drawer)"
	}

	if {$GameState($gameID,drawer) == [::config::getKey login]} {
	  select_word $gameID
	  catch { pack forget .$win_name.uc.gr }
	  pack .$win_name.uc.sk -in .$win_name.uc -fill both -expand 1
	  bind .$win_name.canvas <ButtonPress>   "::Games::Sketch::ButtonPress   $gameID %x.0 %y.0"
	  bind .$win_name.canvas <ButtonRelease> "::Games::Sketch::ButtonRelease $gameID %x.0 %y.0"
	  bind .$win_name.canvas <Motion>        "::Games::Sketch::MouseMotion   $gameID %x.0 %y.0"
	  bind .$win_name.canvas <Leave>         "::Games::Sketch::MouseLeave    $gameID %x.0 %y.0"
	  .$win_name.status.lbl configure -text \
		"[::Games::trans Round] ${round}: [::Games::trans you_draw $GameState($gameID,word)]"
	} else {
	  catch { pack forget .$win_name.uc.sk }
	  pack .$win_name.uc.gr -in .$win_name.uc -fill both -expand 1
	  set GameState($gameID,drawing) 0
 	  bind .$win_name.canvas <ButtonPress>   ""
	  bind .$win_name.canvas <ButtonRelease> ""
	  bind .$win_name.canvas <Motion>        ""
	  bind .$win_name.canvas <Leave>         ""
	  .$win_name.status.lbl configure -text \
		"[::Games::trans Round] ${round}: [::Games::trans you_guess $GameState($gameID,lang)]"
	}
	# Hourglass will be restarted when drawer starts drawing
	stop_hour_glass $gameID .$win_name.time.sandglass
	set GameState($gameID,hg_running) 0
  }

  proc opponent_moves { gameID sender move } {
	variable GameState

	# Could be we left already, then our window does not exist anymore
	set win_name $GameState($gameID,win_name)
	if {![winfo exists .$win_name]} {
	  return
	}

	#::Games::log "Received from $sender : $move"
	foreach rec [split $move ","] {
	  foreach {key value} [split $rec "="] {
		switch -exact $key {
		  "PEN"		{set opponent_pen $value}
		  "COLOR"	{set opponent_color $value}
		  "COORDS"	{ if {$GameState($gameID,hg_running) == 0} {
						start_hour_glass $gameID .$win_name.time.sandglass
						set GameState($gameID,hg_running) 1
					  }
					  .$GameState($gameID,win_name).canvas create line $value \
					    -smooth bezier -fill $opponent_color -width $opponent_pen
					}
		  "CLEAR"	{clearCanvas $gameID}
		  "DRAWER"	{set GameState($gameID,drawer) $value
					 start_now $gameID}
		  "GUESS"	{processGuess $gameID $sender $value}
		  "PLAYER"	{set player $value ; set sol ""}
		  "SOL"		{set sol $value}
		  "SCORE"	{update_scores $gameID $player $value $sol}
		  "WRONG"	{add_wrong_guess $gameID $value}
		  "SKIPPED" {roundSkipped $gameID}
		  "VIOLATE" {addViolation $gameID $sender}
		}
	  }
	}
  }

  proc guessOK {gameID guess word} {
	set s1 [string map {" " ""} $guess]
	set s1 [string tolower $s1]

	set s2 [string map {" " ""} $word]
	set s2 [string tolower $s2]

	# FIXME: Does Tcl has something as sounds_like?
	# FIXME: Is it ok if 95% of the chars match?
	if {$s1 == $s2} {
	  return 1
	} else {
	  return 0
	}
  }

  proc add_wrong_guess {gameID wrong} {
	variable GameState

	set win_name $GameState($gameID,win_name)

	# Move all wrong guesses one up
	for {set i 0} {$i < 9} {incr i} {
	  set j [expr {$i+1}]
	  set jlbl [.$win_name.wrongguesses.l$j cget -text]
	  .$win_name.wrongguesses.l$i configure -text "$jlbl"
	}

	# Put current wrong guess at the bottom
	.$win_name.wrongguesses.l9 configure -text "$wrong"
  }

  proc processGuess {gameID sender guess} {
	variable GameState

	set state 0
	if {$GameState($gameID,drawer) == [::config::getKey login]} {

	  if {[lsearch -exact $GameState($gameID,scoredround) $sender] > -1} {
	    # sender already scored in this round, ignore its guesses
		return
	  }

	  foreach word [split $GameState($gameID,word) ","] {
		if {[guessOK $gameID $guess $word]} {
		  set state 1
		  break
		}
	  }
	  if {$state} {
		foreach {player score} $GameState($gameID,scores) {
		  if {$player == $sender} {
			set score [expr {$score + $GameState($gameID,credit)}]
			set GameState($gameID,credit) [expr \
			  {($GameState($gameID,credit) + 1) / 2}]
			set sol [string map {{,} {}} $GameState($gameID,word)]
			::Games::SendMove $gameID "PLAYER=$player,SOL=$sol,SCORE=$score"
			update_scores $gameID $sender $score $sol
			break;
		  }
		}
	  } else {
		# Wrong guess, notify everyone
		::Games::SendMove $gameID "WRONG=$guess"
		add_wrong_guess $gameID $guess
	  }
	}
  }

  proc add_player { gameID player } {
	variable GameState
	if {[info exists GameState($gameID,win_name)]} {
	  update_scores $gameID $player -1
	} elseif {[info exists GameState($gameID,addplayers)]} {
	  set GameState($gameID,addplayers) \
		[concat $GameState($gameID,addplayers) [list $player -1]]
	} else {
	  set GameState($gameID,addplayers) [list $player -1]
	}
  }

  proc update_scores { gameID player score {sol ""}} {
	variable GameState

	set win_name $GameState($gameID,win_name)
	set nick [::Games::getNick $player]

	set scores {}
	if {[info exists GameState($gameID,scores)]} {
	  set scores $GameState($gameID,scores)
      set players $GameState($gameID,players)
	}

	if { [::config::getKey login] == $player && "$sol" != "" } {
	  .$win_name.status.lbl configure -text \
		"[::Games::trans correct_guess $sol]"
	}

	if {"$sol" != ""} {
	  lappend GameState($gameID,scoredround) $player
	}

	set i 0
	set found 0
	foreach {p s} $scores {
	  if {$p == $player} {
		set found 1
		if {$score > -1} {
		  .$win_name.player$i configure -text "$nick ([::Games::trans points $score])."
		  .$win_name.player$i configure -foreground "dark green"
		  set scores [lreplace $scores $i [expr {$i+1}] $player $score]
		  break
		}
	  }
	  incr i ; incr i
	}
	if {!$found} {
	  if {$score == -1} {set score 0}
	  label .$win_name.player$i -text "$nick ([::Games::trans points $score])."
	  pack .$win_name.player$i -in .$win_name.players -anchor w
	  lappend scores $player $score
	  lappend players $player
	}

	# Sort players by decreasing score
	for { set i 0 } { $i < [llength $scores] } { incr i ; incr i } {
	  set chat_i [lindex $scores $i]
	  set score_i [lindex $scores [expr {$i+1}]]
	  for { set j [expr {$i+2}] } { $j < [llength $scores] } { incr j ; incr j } {
		set chat_j [lindex $scores $j]
		set score_j [lindex $scores [expr {$j+1}]]
		if {$score_j > $score_i} {
		  # Swap i and j in $scores
		  set scores [lreplace $scores $i [expr {$i+1}] $chat_j $score_j]
		  set scores [lreplace $scores $j [expr {$j+1}] $chat_i $score_i]
		  # Swap i and j in player list
		  set fg_i [.$win_name.player$i cget -foreground]
		  set fg_j [.$win_name.player$j cget -foreground]
		  .$win_name.player$i configure \
			-text "[::Games::getNick $chat_j] ([::Games::trans points $score_j])."
		  .$win_name.player$i configure -foreground $fg_j
		  .$win_name.player$j configure \
			-text "[::Games::getNick $chat_i] ([::Games::trans points $score_i])."
		  .$win_name.player$j configure -foreground $fg_i
		}
	  }
	}

	set GameState($gameID,scores) $scores
	set GameState($gameID,players) $players
  }

  proc opponent_quits { gameID chatid } {
	variable GameState

	set win_name $GameState($gameID,win_name)
	if {![winfo exists .$win_name]} {
	  # We quitted first, lalala
	  return;
	}

	# Gray out label of the player that left.
	set i 0
	foreach {p s} $GameState($gameID,scores) {
	  if {$p == $chatid} {
		.$win_name.player$i configure -foreground gray
		break
	  }
	  incr i ; incr i
	}
	# Remove this player from players
	set pi [lsearch -exact $GameState($gameID,players) $chatid]
	if {$pi != -1} {
	  set GameState($gameID,players) \
		[lreplace $GameState($gameID,players) $pi $pi]
	}
  }

  proc time_elapsed {gameID} {
	variable GameState
	
	if {$GameState($gameID,host) == [::config::getKey login]} {
	  roundSkipped $gameID
	}
  }

  proc sendGuess {gameID entry} {
	variable GameState

	set guess [$entry get]
	$entry delete 0 end

	if {$GameState($gameID,drawer) != [::config::getKey login]} {
	  # FIXME: Verify that we are not sending illegal characters that will
	  # not arrive. Must work for different languages as well! This tag is
	  # related to the one about protecting against injected code!
	  set guess [string map {{,} {} {[} {} {]} {} {$} {} {=} {}} $guess]
	  ::Games::SendMove $gameID "GUESS=$guess"
	}
  }

  proc chooseColor {gameID widget} {
	variable GameState
	set new_color [tk_chooseColor -title "[::Games::trans choose_bkgcol]" \
	  -parent .$GameState($gameID,win_name)]
	if {"$new_color" != ""} {
	  set GameState($gameID,current_color) $new_color
	}
	$widget configure -background $GameState($gameID,current_color)
  }

  proc clearButton {gameID} {
	::Games::SendMove $gameID "CLEAR=ALL"
	clearCanvas $gameID
  }

  # Skip current round
  proc roundSkipped {gameID} {
	variable GameState

	if {$GameState($gameID,host) == [::config::getKey login]} {
	  # We are the host
	  if {[llength $GameState($gameID,scoredround)] == 0} {
		# Nobody guessed correctly this round
		# Subtract 10 points from the drawer!
		set idx [lsearch -exact $GameState($gameID,scores) $GameState($gameID,drawer)]
		set score [lindex $GameState($gameID,scores) [expr {$idx+1}]]
		set new_score [expr {$score - 10}]
		set player $GameState($gameID,drawer)
	    update_scores $gameID $player $new_score
	    ::Games::SendMove $gameID "PLAYER=$player,SCORE=$new_score"
	  }
	  start_now $gameID
	}
  }

  # Drawer pressed the Skip button
  # Also invoked due to violation
  proc skipButton {gameID} {
	variable GameState

	if {$GameState($gameID,host) == [::config::getKey login]} {
	  roundSkipped $gameID
	} else {
	  ::Games::SendMove $gameID "SKIPPED=1"
	}
  }

  proc clearCanvas {gameID} {
	variable GameState
    .$GameState($gameID,win_name).canvas delete all
  }

  proc MouseMotion {gameID x y} {
	variable GameState
	variable eps2
	variable eraser

	if {$eraser} {
	  set the_color $::Games::Sketch::bkg_color
	} else {
	  set the_color $GameState($gameID,current_color)
	}

	if {$GameState($gameID,drawing) && $GameState($gameID,old_x) != -1} {
	  lappend GameState($gameID,widget_list) \
    	[.$GameState($gameID,win_name).canvas create line \
		  $GameState($gameID,old_x) $GameState($gameID,old_y) $x $y \
		  -fill $the_color -width $GameState($gameID,current_pen)]

	  # Vertex reduction: 
	  # only add point_list if it's $eps away from sx,sy
	  if {[expr {($GameState($gameID,sx)-$x)*($GameState($gameID,sx)-$x) + \
                ($GameState($gameID,sy)-$y)*($GameState($gameID,sy)-$y) >= $eps2}]} {

		lappend GameState($gameID,point_list) $x $y
		set GameState($gameID,sx) $x
		set GameState($gameID,sy) $y
	  }
 	}
	set GameState($gameID,old_x) $x
	set GameState($gameID,old_y) $y
  }

  proc MouseLeave {gameID x y} {
	# Stop drawing by pretending a ButtonRelease
	ButtonRelease $gameID $x $y
  }

  proc ButtonPress {gameID x y} {
	variable GameState

	array set GameState [list \
	  "$gameID,drawing"			1 \
	  "$gameID,old_x"			$x \
	  "$gameID,old_y"			$y \
	  "$gameID,sx"				$x \
	  "$gameID,sy"				$y \
	  "$gameID,point_list"		[list $x $y] \
	  "$gameID,widget_list"		{} ]
  }

  proc ButtonRelease {gameID x y} {
	variable GameState
	variable eraser

	if {$GameState($gameID,drawing)} {
	  set win_name $GameState($gameID,win_name)
	  set GameState($gameID,drawing) 0

	  lappend GameState($gameID,point_list) $x $y

	  # Simplify polyline
	  simplify_polyline $gameID
	  
	  # Fixing a small problem that single points don't seem to get drawn
	  if {[llength $GameState($gameID,spoint_list)] == 4 && \
		  [lindex $GameState($gameID,spoint_list) 0] == \
		  [lindex $GameState($gameID,spoint_list) 2] && \
		  [lindex $GameState($gameID,spoint_list) 1] == \
		  [lindex $GameState($gameID,spoint_list) 3] } {
		set GameState($gameID,spoint_list) \
		  [lreplace $GameState($gameID,spoint_list) 0 0 \
		  [expr {[lindex $GameState($gameID,spoint_list) 0] + 1}]]
	  }

	  # Remove current drawing in widget_list
	  foreach w $GameState($gameID,widget_list) {
		.$win_name.canvas delete $w
	  }

	  if {$eraser} {
		set the_color $::Games::Sketch::bkg_color
	  } else {
		set the_color $GameState($gameID,current_color)
	  }

	  if {[llength $GameState($gameID,point_list)] >= 4} {
		# Draw squared spline approximation after Vertex Reduction
		#.$win_name.canvas create line $GameState($gameID,point_list) \
		#  -smooth bezier -fill $the_color -width $GameState($gameID,current_pen)
		# Draw squared spline approximation after Douglas-Peucker algorithm
		.$win_name.canvas create line $GameState($gameID,spoint_list) \
		  -smooth bezier -fill $the_color -width $GameState($gameID,current_pen)
	  }

	  # Send to other players
	  set info "PEN=$GameState($gameID,current_pen)"
	  set info "${info},COLOR=$the_color"
	  if {$GameState($gameID,hg_running) == 0} {
		start_hour_glass $gameID .$win_name.time.sandglass
		set GameState($gameID,hg_running) 1
	  }
	  ::Games::SendMove $gameID "${info},COORDS=$GameState($gameID,spoint_list)"
	}
  }

  # Simplifies the polyline in list point_list
  proc simplify_polyline {gameID} {
	variable GameState
	set GameState($gameID,spoint_list) {}

	set N [llength $GameState($gameID,point_list)]
	set pstart_x [lindex $GameState($gameID,point_list) 0]
	set pstart_y [lindex $GameState($gameID,point_list) 1]
	set pend_x   [lindex $GameState($gameID,point_list) [expr {$N-2}]]
	set pend_y   [lindex $GameState($gameID,point_list) [expr {$N-1}]]

	if {$N >= 4} {
	  set spoint_list_dot0 [concat \
		[list $pstart_x $pstart_y] \
		[DPsimplify $gameID 0 [expr {$N-2}]] \
		[list $pend_x $pend_y]]
	}
	foreach c $spoint_list_dot0 {
	  # Strip useless .0 now
	  set c [string range $c 0 [expr {[string length $c] - 3}]]
	  lappend GameState($gameID,spoint_list) $c
	}
  }

  # Douglas-Peucker recursive simplification routine
  # Returns list of new points
  proc DPsimplify {gameID pstart pend} {
	variable GameState
	# eps2 is the tolerance eps squared
	variable eps2

	set pstart_x [lindex $GameState($gameID,point_list) $pstart]
	set pstart_y [lindex $GameState($gameID,point_list) [expr {$pstart+1}]]
	set pend_x   [lindex $GameState($gameID,point_list) $pend]
	set pend_y   [lindex $GameState($gameID,point_list) [expr {$pend+1}]]
	set u_x      [expr {$pend_x - $pstart_x}]
	set u_y      [expr {$pend_y - $pstart_y}]
	set cu       [expr {$u_x * $u_x + $u_y * $u_y}]

	# maxi is the point farthest from line pstart - pend
	set maxi [expr {$pstart+2}]
	# maxd2 is distance squared from maxi to line pstart - pend
	set maxd2 0

    for {set i $maxi} {$i < $pend} {incr i ; incr i} {
	  # Compute distance from i to line
	  set i_x [lindex $GameState($gameID,point_list) $i]
	  set i_y [lindex $GameState($gameID,point_list) [expr {$i+1}]]
	  set w_x [expr {$i_x - $pstart_x}]
	  set w_y [expr {$i_y - $pstart_y}]
	  set cw  [expr {$w_x * $u_x + $w_y * $u_y}]
	  if { $cw <= 0 } {
		set dv2 [expr {($i_x - $pstart_x) * ($i_x - $pstart_x) + \
                      ($i_y - $pstart_y) * ($i_y - $pstart_y)}]
	  } elseif { $cu <= $cw } {
		set dv2 [expr {($i_x - $pend_x) * ($i_x - $pend_x) + \
                      ($i_y - $pend_y) * ($i_y - $pend_y)}]
	  } else {
		set b [expr {$cw / $cu}]
		set pb_x [expr {$pstart_x + $b * $u_x}]
		set pb_y [expr {$pstart_y + $b * $u_y}]
		set dv2 [expr {($i_x - $pb_x) * ($i_x - $pb_x) + \
                       ($i_y - $pb_y) * ($i_y - $pb_y)}]
	  }
	  # Test if i is farthest from line pstart - pend
	  if {$dv2 > $maxd2} {
		set maxi $i
		set maxd2 $dv2
	  }
	}

	# Check whether error is worse than eps2
	if { $maxd2 > $eps2 } {
	  # Do recursion
	  set maxi_x [lindex $GameState($gameID,point_list) $maxi]
	  set maxi_y [lindex $GameState($gameID,point_list) [expr {$maxi+1}]]
	  set result [concat \
		[DPsimplify $gameID $pstart $maxi] \
		[list $maxi_x $maxi_y] \
		[DPsimplify $gameID $maxi $pend]]
	} else {
	  # Ignoring all points in between
	  set result {}
	}

	return $result
  }

  # =================================================
  # game_configuration
  # -------------------------------------------------
  # Specify game configuration
  # =================================================
  proc game_configuration { gameID } {
	variable GameState
	variable __language
	variable __languages
	variable __win_name

	set win_name [string map {"." "" ":" ""} $gameID]
	set __win_name $win_name

	# Load languages (do this first, don't want a window yet if sourceforge is slow)
	set languages [list]
	::lang::LoadOnlineVersions

    toplevel .${win_name}_gc
    wm title .${win_name}_gc "[::Games::trans select_language]"
    wm protocol .${win_name}_gc WM_DELETE_WINDOW ".${win_name}_gc.cancel invoke"

	# Process languages
    foreach langcode $::lang::Lang {
      set name [::lang::ReadLang $langcode name]
      lappend languages [list "$name" "$langcode"]
    }
    set languages [lsort -index 0 -dictionary $languages]
	set __languages $languages
	
	# Language listbox
	frame .${win_name}_gc.langfrm
	listbox .${win_name}_gc.langfrm.items -yscrollcommand ".${win_name}_gc.langfrm.ys set" \
	  -font splainf -background white -relief flat -highlightthickness 0 -width 60
    scrollbar .${win_name}_gc.langfrm.ys -command ".${win_name}_gc.langfrm.items yview" \
	  -highlightthickness 0 -borderwidth 1 -elementborderwidth 1
    pack .${win_name}_gc.langfrm.ys -in .${win_name}_gc.langfrm -side right -fill y
    pack .${win_name}_gc.langfrm.items -in .${win_name}_gc.langfrm -side left -expand true -fill both

	set default_lang -1
	for { set i 0 } { $i < [llength $languages] } { incr i } {
	  set item [lindex $languages $i]
      .${win_name}_gc.langfrm.items insert end [lindex $item 0]
	  if {[lindex $item 1] == $__language} {
		set default_lang $i
	  }
	}
	if {$default_lang >= 0} {
	  .${win_name}_gc.langfrm.items selection set $default_lang
	}

	# Challenge and cancel button
    frame .${win_name}_gc.buttons
    button .${win_name}_gc.ok -text "[::Games::trans challenge]" -command {
	  set sel [.${::Games::Sketch::__win_name}_gc.langfrm.items curselection]
	  set sel_item [lindex $::Games::Sketch::__languages $sel]
      set ::Games::Sketch::__language [lindex $sel_item 1]
    }
    button .${win_name}_gc.cancel -text "[::Games::trans cancel]" -command {
      set ::Games::Sketch::__language ""
    }

    pack .${win_name}_gc.cancel .${win_name}_gc.ok -in .${win_name}_gc.buttons -side right
	pack .${win_name}_gc.langfrm -fill both -expand true -padx 4 -pady 4
	pack .${win_name}_gc.buttons -padx 4 -pady 4
    ::Games::moveinscreen .${win_name}_gc

    update idletask
    grab set .${win_name}_gc
    tkwait variable ::Games::Sketch::__language
    destroy .${win_name}_gc

	set GameState($gameID,lang) $__language
	if {"$__language" == ""} {
	  return ""
	} else {
	  set word_cnt [loadDictionary $GameState($gameID,lang)]
	  if {$word_cnt == 0} {
		::amsn::infoMsg "[::Games::trans empty_dictionary]" warning
		return ""
	  } else {
        return "LANG=$GameState($gameID,lang)"
	  }
	}
  }

# =========================================================================
# Hourglass code
#
# Original author: Bernd Breitenbach
#
# The following code is used with permission from the original author
# and slightly modified to fit in this game. The original version can be
# obtained at http://www.five-o-clock.de/fragments/
# =========================================================================

set HourGlass(hglass_full) {R0lGODlhUADwAOcAAAoOFHZ+jLa2tEZGRJqalF5iZGpyfNLSzCoqLIqOlKqqpMbGxIZ+hFJWVGJq
dDY6PHZydBoeJKKinN7e1L6+vJaOlLaurIKGjEpOVG5qbHZ6fH5+fC4yNIaGhN7W1NLKzGZiZF5a
XEI+RCYiLBIWHLKyrI6GjKKanGpyhH5+jL62tNra1M7OzGZqfKqipMa+vJaWlLKqrD5CRNrS1M7G
xFpeZD46PCImLFJOTHZ6hE5KTF5mdDIuNJKOjHZ2hCIeJDYyPIaKjJ6enCouLFpWXOrm5BoWHEZK
THJydNbW1K6urmpqb6amqObe3Lays25uf36ChGZmdBISGLq6uZqapF5idMrKyHZ2eh4iJ8LCwZaS
lF5eYnJyhH6CjL66u8bCwp6WnFJSV356hJKSlHqCjK6qtFZaXDo+P6airG5ucoaGlN7a1tLOzWZm
akJCRiYmKhYaH46KjqKeo2ZufKqmqpaWpD4+PzY2Oi4uPLayvJaSnA4SFXp+lLq2t0ZGVJ6anHJ2
fIaCh+Li3DI2NG52hH56fLKusNrW1M7KySIiJVpaXRoaImpudObi3nJ2hFZWZB4eLE5OXIqKlF5e
bL66xMbCzCYmNDY2RLKyvJKOnHJyfNbW3JKSnD4+THp+jEpGTGJiZW5yfNbS0C4qNI6Oka6qrMrG
xVZWW2ZqdDo6PR4eJKaipOLe3MK+vk5OUXp6fIJ+hDIyNYqGjBYWHJqWnHp6i2JmdHp2hIqKjC4u
MUpKTbqytIKChHp2fJqSlGJeZIKCjMK6vMrCxFZSWnJudOLa3NbOzWpmbEZCSSomLJKKj6aepGpu
fK6mrDo2PIqCjA4OFG5yhGpqfJ6apGJidLqyvJqSnLa2vEZGTJqanF5ibNLS1CoqNKqqrMbGzHZy
fKKipN7e3L6+xLautIKGlG5qdH5+hIaGjN7W3GZibF5aZLKytKKapH5+lL62vNra3M7O1KqirMa+
xJaWnLKqtM7GzFpebD46RFJOVHZ6jE5KVJKOlHZ2jJ6epCouNP///yH+Dk1hZGUgd2l0aCBHSU1Q
ACH5BAEKAP8ALAAAAABQAPAAAAj+AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNq3Mixo8eP
CCeBAmWLmklbzFKmfCKtpcuULaiB0kZzJCh1IBdOisJMWgtmLXyufEIUxZNoXJJGCxUtGgqVKVFF
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}

set HourGlass(hglass_empty) {R0lGODlhUADwAOcAAGVod2ZpemdqeWdqe2hremhrfGlse2lsfWRndmptfmtuf2xvgGptfG1wgW5x
gm9yg2NmdXBzhGtufW1xfWlqfGZpeGxvfm9ygW5xgG1wf2xwfGpse3BzgnF0g3J1hHJ1hnF0hW1v
fmttemxue2xufWttfGpseW1vfG5wfW9xfnByf3FzgHJ0gXN3g3R4hHV5hXZ5iHZ6hnd6iXd7h3h8
iHh6h3d5hnV4h3R3hnR3iGtve2tteWxuenN1gnJ2gnl9iXl7iHh7inN2h2ZsempseHF1gXB0gG5y
fnN2hXl8i3p9jHt+jXp+inZ5inV4iWdte2lreGlrd21ve29zf3h7jGlrenZ5jHl8jXp9jnx/kHt+
j3d6i2hqd3x/jn6Aj36AjX1/jmZqdmhqdn2Aj32BjX+Bjmdrd2hseHyAjHt/i31/jHd6jXh7jnJ1
iHBzhmFlcXN2iXF0h2JmcmlteX+BjX6AjHx+jWNnc4CCjn+Ci2VoeX6CjoGDj4CDjIGEjYCCj3V4
i3R3inl8j2BjcmFkc2JldG9yhW5xhH6CjWVpdWRodF9icWBkcF5ibltfa11gb3R2i3Z4jV5hcH2B
jHp9kHyAi4KFjm9xgHFzgnN1ilxfblxgbFtebWlsf4GEi3h+jHl/jXt9jF9jb3+DjoCEj3+Dj2Nm
d3h5jXl6jl1hbWRneHZ3i3Z8jHd9jX6BkGBjdGFkdWJldnx+i3+BkHp8i4GDkICEkIGFkHp8iYKE
kHV3hHt9in2AkXN5h3F3hXJ4hnB2hHV2ind4jHd9i3p+iXl/i3qAjGpuenp7jXd5iHV3hnZ4h3t/
im1wg2xvgoODjXuBjXh+jnl/j2tugYGBjYCAjH9/i3V5hH1/i3R2g3R2hXN1hHJ0g3Z4hf//////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////yH+Dk1hZGUgd2l0aCBHSU1Q
ACH5BAEKAP8ALAAAAABQAPAAAAj+AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNq3MhRogAC
BgwQGEkgwYIFClImWJnggMsCAQZUAJAIQBgCZzo+JMCgZYEDCX4CXdCgqAMHER48OMq0aEoGBQQE
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}

set HourGlass(hglass_1) {R0lGODlhUADwAMYAAFpebLKyvIaKjHJ2hJqepHqCjGZqdJKWlNra5HZ+jKaqrG5yfI6SlM7O1Hp6
hKKmrIKCjG5ufJqWnGJmdI6OlHJ6hKKipGZufIqOlJaanPLu9H5+jIKGjGJidL6+xK6utNbW3F5i
bIqKnHZ2hJ6ipGpqdJaWpHp+lHJyfJKSlIaGjLq6vIqKlJ6epH6CjJaWnOrm7Hp+hKqutM7S1Jqa
nGZmdHZ6hKairGpufPr6/F5ebLa2vIaKlHJ2jGZqfJKWnKqqtG5yhI6SnHp6jKamrIKClG5uhI6O
nKKirIqOnJaapH5+lIKGlMLCzLKutNrW3F5idHZ2jGpqfHJyhJKSnIaGlJ6erH6ClOrq7Hp+jNLS
1JqapGZmfHZ6jGpuhP7+/P//////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////yH+
Dk1hZGUgd2l0aCBHSU1QACH5BAEKAH8ALAAAAABQAPAAAAf+gH+Cg4SFhoeIiYqLjI2Oj5CRkpOU
lZaXmJmam5ySIVAdHVCjPlIRETipUqusF1JcozohslAhnY8AXKypqlJGRgvBEUHExUFGXkG8Pj5c
BjU+ExM6AAC3iKkLQaunEUZTU9pTQQPlA1Pn5OjjxEbtqFwTIRMG1teEqagRCyhB/fsL0A2oYGNI
goMODnYZMmLEAGLmHqJbIOVZB3v3LvjAUSLCABTltBX7aC5KliwbhmTp0iVKlHM9uthgubBhOSk+
DFy89yengX3liPVDgW5El4EyE2QZQtNouR4uaapMaWMcDmYYO+E0YCrgOYHjpoyI6SCLiw0bXCxh
enRKjxH+BbvEOJFlSYEsDqoaSbXzFpecOPYF6RFzgMsoMlWqPOvi7pCZNoLGHDKkwJUNd21UGLDg
qo+smwww8+EFXY8BhKN2ObkYrVkXeG30IDe43AiVJzdEZsfRVqcQOUv4IObWLeKFC3GndcEc5dIR
4IJAH9uD8uqWnL1orAEaE7RoOIKdc3h89cksBVxAuLKEuYsTQ6KgixKTsOEuRumPo4iz+yVmBkxg
ikAvlWeeC1cUwUERRagHwVnYITaTfIe1JF8QqPTXiWgGcJXMAEYZhdxCJyXIAYLuQdhFBSSyNABL
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
vxevzHLLLr8Mc8wyz0xzzTbffHMgADs=}

set HourGlass(hglass_2) {R0lGODlhUADwAMYAAFpebLKytIaKjHJ2hJqenHqCjGZqdJKWlNra3HZ+jHJyfI6SlG5yfHp6hKqq
tIKCjG5ufGJmdMLGzI6OlJqanPLy/HJ6hGZufLq6vIqOlKamrJaanIKGjGJidKKirH5+jF5ibIqK
nHZ2hJ6erGpqdJaWpN7i5JKSlPr6/IaGjLa2vIqKlJ6epH6CjJaWnHp+jHZyhKqutGZmdHZ6hGpu
fLq+xObm7F5ebLKyvIaKlHJ2jJqepGZqfJKWnHJyhI6SnG5yhHp6jIKClG5uhNLS1I6OnJqapPb2
/IqOnJaapIKGlH5+lF5idHZ2jGpqfJKSnP7+/IaGlH6ClHp+lK6utGZmfHZ6jGpuhP//////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////yH+
Dk1hZGUgd2l0aCBHSU1QACH5BAEKAH8ALAAAAABQAPAAAAf+gH+Cg4SFhoeIiYqLjI2Oj5CRkpOU
lZaXmJmam5ySIEwdHUyjPE4QEDSpTqusF05VozcgskwgnY8AVaypqk5DQwzBEEDExUBDV0C8PDxV
BjI8ERE3AAC3iKkMQKunEEM+Pto+QAPlAz7n5OjjxEPtqFURIBEG1teEqagQDApA/fsM0A2wMCNI
goMNDloJIkLEAGLmHqJj4ORZB3v3LvCgQQLCAAXltBX7aE7EixcfgrywYqVJk3M6rMxgubBhOSc8
DFy89yengX3liPVTgE6ElYEsE7wIItOK0XI6XNJUmXLGOBrMMHbCacBUwHMCx/kQEVNliw8fWixh
etSHDhH+BWe8mPJiSYEXDawOSbXzVpWcNPYB0RFzgMsmMhssfSEl7d0gM2cE1TGjQZACje/OsDCA
AVYeWjcZYMbjCjodAwhLtXJSZeMPjFvgnaGDHLlyTVSe/CCZHUdbnUDkJMGDmFu3iBcu1J22RQsp
KJeKAAdk+ssBQSC/mOGQwRWNMkJjghaNRrBzDpOzPjmlQIsHjZ3LZoiuCWXChlu21DGOIk7xlzBj
QASmCPSSeus9JwQHDzzwnoMftGRYZE2MJZVL46DyXyejGdBVMgMYZZRyC530nhLyPSfFEixZUCJL
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}

set HourGlass(hglass_3) {R0lGODlhUADwAMYAAFpebK6ytIaKjHJ2hJqenHqCjGZqdJKWnN7e3HZ+jG5yfMLGzJKSlKaqrIKC
jI6SlHp6hG5ufJqWnGJmdKamrI6OlHJ6hGZufPr6/IKGjMLCxKKipNbW3GJidLq6vIqOlJaanObm
7H5+jM7O1F5ibLa2vHZ2hJ6ipGpqdHJyfMrK1K6utJqanIaGjIqKlJ6epH6CjJaWnOLi5Hp+jMbG
xJaSnKqqrIaClGZmdHZ6hGpufJ6apF5ebLKytIaKlHJ2jJqepGZqfN7e5G5yhJKSnIKClI6SnHp6
jG5uhKqmrI6OnP7+/IKGlKKirIqOnJaapOrm7H5+lF5idLq2vHZ2jGpqfHJyhJqapIaGlH6ClJaW
pHp+lMbGzKqqtGZmfHZ6jGpuhP//////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////yH+
Dk1hZGUgd2l0aCBHSU1QACH5BAEKAH8ALAAAAABQAPAAAAf+gH+Cg4SFhoeIiYqLjI2Oj5CRkpOU
lZaXmJmam5ySJFIdHVKjQVURETqpVausF1VeozwkslIknY8AXqypqlVISArBEUPExUNIYEO8QUFe
BjhBExM8AAC3iKkKQ6unEUhWVtpWQwPlA1bn5OjjxEjtqF4TJBMG1teEqagRCilD/fsK0A2wkONI
goMQDn45YsLEAGLmHqJTUOVZB3v3LgTRgSLCgBTltBX7aM7EjBkijsz48oUKlXM/vuRgubBhuSpB
DFy89yengX3liPVLgc7El4EsE8w4IvOL0XI/XNJUmTLHOB3MMHbCacBUwHMCx1kxEVMlDBEiYERh
etTKDxP+BXPM2DIjSoEZEKwiSbXzlpecOvYN+RFzgEsqMiEsnZEl7d0jM3ME/ZEDwpECje/msDBA
AdYgWjcZYBYEDLofAwhL/XJSZWMRjGHgzfGDHLlyVFSeFCGZHUdbnUjkRBGEmFu3iBcu1J0WBows
KJeaADdk+ssBRyDPyOFQARiNOEJjghZNR7BzDpOzPrmlAAwHjZ3LZoiOCmXChlu2/DGOIk7xlzBj
wASmCPSSeus9V0QGDjjwnoMitGRYZFSMJZVL46DyXyejGdBVMgMYZZRyC530HhPyPZdFFCxZUCJL
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
km6/BrDmZb8CD0xwwQYfjHDCCi/McMOtBQIAOw==}

set HourGlass(hglass_4) {R0lGODlhUADwAMYAAFpebLKytIaKjG52hJqepHqCjGZqdNre5JKWnHp6hMLGzG5yfI6SlIaClHZ+
jKqqrGJmdHZ2hG5ufJqanM7O1I6OlKKmrIKCjGZufP76/GJibHp+jLq6vIqOlHJ6hKKipOrq7Jaa
nF5ibGpqdMrKzHJyfJKSlIaGjHZ6hNbS3IKGjH5+jLK2vIqKlHJ2hJ6ipH6CjOLi5JaWnK6utGZm
dJ6apM7S1GpufIqGlF5ebIaKlJ6epGZqfN7e5Hp6jMbGzG5yhI6SnK6qtHZ2jG5uhJqapI6OnKam
rIKClP7+/GJidHp+lL6+xIqOnHJ6jKKirO7u9JaapF5idGpqfMrK1HJyhJKSnIaGlHZ6jIKGlH5+
lLa2vHJ2jH6ClJaWpGZmfNLS1GpuhP//////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////yH+
Dk1hZGUgd2l0aCBHSU1QACH5BAEKAH8ALAAAAABQAPAAAAf+gH+Cg4SFhoeIiYqLjI2Oj5CRkpOU
lZaXmJmam5ySIlJKSlKjPFMSEjepU6usGFNfozkislIinY8AX6ypqlNERAvBEkDExUBEYUC8PDxf
BjQ8EBA5AAC3iKkLQKunEkRVVdpVQC7lLlXnVQPq48RE7qhfECIQBtbXhKmoEgslQP78FqBz4QGF
DwcIEyDE4iNCBBdABpaL6GLBFB40lNzDh4HHjRESXJQop40YupHlImzYsMLHBiwohjyswgUmlpsN
Hw64aEAjvj88DBjg52IAsRJVkLqIgIUgTAcbfNxE4YKqiyFYbzJk6QPFuBvMNnbiaUpguongXNRM
sAHGihX+brui4IKOadcNSzZoKfDSQwkiqXze+hL0Bj+aNdVmNRh1Qxe4BVqiQNH0HBcUCXwUeMwX
hYeKYHmI3WSAGY9kA7io5ZLVZWMYWla0hbFhMhcgRs0Ncb0yAURiH211EhF0BA+T59TiZOh6RRcY
MPjK9l0sQpUh5Xx0dYAF+4IwHWmMxgQt2g1i57BzkYplJd4CMC48hk7bxxB0Qy5zUT2kOxaH41h0
0XiXMGMABKYAsZ9M62m1EnRIZHEBdF0g0cVL/FEWUxUR5NcdXUCgMmAnpZWW4FJYcOEEe1u1hYQK
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
Tnjhhh8ueCAAOw==}

set HourGlass(hglass_5) {R0lGODlhUADwAMYAAFpebK6ytIaKjG52hJqenHqCjGZqdNra3JKWnHp6hKaqrMLGzG5yfI6SlHZ+
jGJmdHZ2hKampIKCjG5ufL6+xJqWnIJ+jI6OlGZufPLy9Hp+hGJibLq6vKKipIKGjIqOlHJ6hJaa
nK6utM7O1Hp+lF5ibLa2vIqKjJ6ipGpqdOrq7HJyfJKSlHZ6hIaGjLKytHJ2hJ6epH6CjOLi5JaW
nKqutMrKzGZmdKqmrJqanGpufPr6/H5+jF5ebIaKlJqepGZqfNra5Hp6jKqqtMbGzG5yhI6SnHZ2
jKamrIKClG5uhMLCxI6OnHp+jGJidLq6xKKirIKGlHJ6jJaapLKutNLS1H5+lF5idIqKlGpqfHJy
hJKSnHZ6jIaGlLKyvHJ2jH6ClJaWpGZmfJqapGpuhP7+/P//////////////////////////////
/////////////////////////////////////////////////////////////////////////yH+
Dk1hZGUgd2l0aCBHSU1QACH5BAEKAH8ALAAAAABQAPAAAAf+gH+Cg4SFhoeIiYqLjI2Oj5CRkpOU
lZaXmJmam5ySJVdOTlejQFkTEzqpWausGFlioz0lslclnY8AYqypqllKSgzBE0XExUVKZEW8QEBi
BjdADw89AAC3iKkMRaunE0paWtpaRTDlMFrnWgPq48RK7qhiDyUPBtbXhKmoEwwrRf78GKCDAaKF
EAcIEyDkIgQCBBhFBpaLCINBFiA3nNzDhwGIjhQTYKwop40YupHljjRpwkNIEy5cjjzU8oVLC5gM
HcIYcNGARnx/gBgwwG8nsRVakMKAwAWGFJsOmgjBCaNFyiNHcLps2WKcDmYbO/U0JTDdRHAwarqU
wYOHDCv+Qm5+Qcd0qgYSTawUeAlihZJUP2+JEaqDH82aabHadLnWbYGWNpueUyukABgee1uAqPgV
SNhNBpgBSTbgS9ovil1qaMyjCRgZL7l8KTKgiOmlLlc2SQCR2EdbnUoITQHE5Lm0MKcKye1Whoy9
rYX0LgJBy8Mvy7k4aHGkIpmONz5jghZNB7Fz3bHD1N2kgAwJYKw4h90Q3RHEKWPGrF7E4kXxlzBj
wAOm2IYaBOqt14QMYCThQRKvNQibbDBkBdMRWmBV033joPJfJ6GFVuBSskkxVXIrNeiBDBA6lwRk
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}

########################################################################

  proc animate {gameID widget} {
	variable GameState
	variable HourGlass

	incr GameState($gameID,hg_wc)
	if { $GameState($gameID,hg_wc) > 5 } { set GameState($gameID,hg_wc) 1 }

	set time_gone [expr {[clock seconds] - $GameState($gameID,hg_tstart)}]
	if { $time_gone <= $GameState($gameID,hg_time_to_go) } {
	  $widget itemconfigure $GameState($gameID,hg_secs) \
		-text [expr {$GameState($gameID,hg_time_to_go) - $time_gone}]
	  set new_fallen [expr {int($time_gone * $HourGlass(quantity) / \
		double($GameState($gameID,hg_time_to_go)))}]
  
	  if { $new_fallen > $GameState($gameID,hg_sand_fallen) } {
		set GameState($gameID,hg_sand_fallen) $new_fallen
		if { $GameState($gameID,hg_sand_fallen) < $HourGlass(above_cone) } {
		  set upper_mark [expr {$HourGlass(cone_start) - $HourGlass(above_cone) + \
			$GameState($gameID,hg_sand_fallen)}]
		} else {
		  set h [expr {($GameState($gameID,hg_sand_fallen) - $HourGlass(above_cone))}]
		  set ch [expr {$HourGlass(cone_end) - $HourGlass(cone_start)}]
		  set hx [expr {( 9 * $h * $h ) / $ch} ]
		  set upper_mark [expr {$HourGlass(cone_start) + $hx}]
		}
		set GameState($gameID,hg_lower_mark) \
		  [expr {$HourGlass(bottom_mark) - $GameState($gameID,hg_sand_fallen)}]
		$GameState($gameID,hg_img_current) copy $HourGlass(img_empty) \
		  -from 0 0 $HourGlass(width) $upper_mark -to 0 0 
		$GameState($gameID,hg_img_current) copy $HourGlass(img_full) \
		  -from 0 $upper_mark $HourGlass(width) $HourGlass(half_mark) -to 0 $upper_mark
		$GameState($gameID,hg_img_current) copy $HourGlass(img,$GameState($gameID,hg_wc)) \
		  -from 0 $HourGlass(half_mark) $HourGlass(width) $GameState($gameID,hg_lower_mark) \
		  -to 0 $HourGlass(half_mark)
		$GameState($gameID,hg_img_current) copy $HourGlass(img_full) \
		  -from 0 $GameState($gameID,hg_lower_mark) $HourGlass(width) $HourGlass(height) \
		  -to 0 $GameState($gameID,hg_lower_mark)
	  } else {
		$GameState($gameID,hg_img_current) copy $HourGlass(img,$GameState($gameID,hg_wc)) \
		  -from 0 $HourGlass(half_mark) $HourGlass(width) $GameState($gameID,hg_lower_mark) \
		  -to 0 $HourGlass(half_mark)
	  }
	} elseif { [expr {$GameState($gameID,hg_ready) % 2 == 0}] } {
	  $GameState($gameID,hg_img_current) copy $HourGlass(img_empty) -from 0 0 $HourGlass(width) \
		$GameState($gameID,hg_lower_mark) -to 0 0 
	  $GameState($gameID,hg_img_current) copy $HourGlass(img_full) \
		-from 0 $GameState($gameID,hg_lower_mark) $HourGlass(width) $HourGlass(height) \
		-to 0 $GameState($gameID,hg_lower_mark)
	  incr GameState($gameID,hg_ready)
	} elseif { $GameState($gameID,hg_ready) == 1 } {
	  time_elapsed $gameID
	  $GameState($gameID,hg_img_current) blank
	  set GameState($gameID,hg_ready) 2
	} else {
	  $GameState($gameID,hg_img_current) blank
	  incr GameState($gameID,hg_ready)
	}
	if {[expr {$GameState($gameID,hg_ready) % 2 == 1}] || \
        $time_gone <= [expr {$GameState($gameID,hg_time_to_go) + $HourGlass(blink_time)}]} {
	  set GameState($gameID,hg_animate) \
	    [after $HourGlass(ani_delay) "::Games::Sketch::animate $gameID $widget"]
    } else {
	  set GameState($gameID,hg_ready) -1
	  set GameState($gameID,hg_animate) ""
    }
  }

  proc hourglass {gameID widget} {
	variable HourGlass
	variable GameState
	variable bkg_color

	set HourGlass(width)            79
	set HourGlass(height)           239

	set HourGlass(half_mark)        120
	#set HourGlass(upper_full_mark)  30
	set HourGlass(lower_full_mark)  160
	set HourGlass(cone_start)       90
	set HourGlass(cone_end)         115
	set HourGlass(bottom_mark)      230

	set HourGlass(ani_delay)        300
	set HourGlass(blink_time)		5

	set GameState($gameID,hg_img_current) \
	  [image create photo -width $HourGlass(width) -height $HourGlass(height)]
	#
	# quantity that filled the upper cone
	#
	set HourGlass(cone_fill)  [expr {($HourGlass(cone_end) - $HourGlass(cone_start)) / 3}]
	set HourGlass(quantity)   [expr {$HourGlass(bottom_mark) - $HourGlass(lower_full_mark)}]
	set HourGlass(above_cone) [expr {$HourGlass(quantity) - $HourGlass(cone_fill)}]

	set HourGlass(img_full)  [image create photo -data $HourGlass(hglass_full)]
	set HourGlass(img_empty) [image create photo -data $HourGlass(hglass_empty)]
	set HourGlass(img,1)     [image create photo -data $HourGlass(hglass_1)]
	set HourGlass(img,2)     [image create photo -data $HourGlass(hglass_2)]
	set HourGlass(img,3)     [image create photo -data $HourGlass(hglass_3)]
	set HourGlass(img,4)     [image create photo -data $HourGlass(hglass_4)]
	set HourGlass(img,5)     [image create photo -data $HourGlass(hglass_5)]

	init_hour_glass $gameID $widget
	set GameState($gameID,hg_ready) -1
    set GameState($gameID,hg_animate) ""

	canvas $widget -width $HourGlass(width) -height $HourGlass(height) -bg $bkg_color
	$widget create image 0 0 -image $GameState($gameID,hg_img_current) -anchor nw

	set balloon_msg "[::Games::trans hourglass_courtesy]"
	bind $widget <Enter> +[list balloon_enter %W %X %Y $balloon_msg]
    bind $widget <Leave> "+set Bulle(first) 0; kill_balloon"

	set GameState($gameID,hg_secs) [$widget create text 8 8 -font 12x24 \
	  -text "$GameState($gameID,hg_time_to_go)" -fill red -anchor nw]
  }

  proc init_hour_glass {gameID widget} {
	variable GameState
	variable HourGlass

    set GameState($gameID,hg_time_to_go)	$HourGlass(time_to_go)
	set GameState($gameID,hg_wc)			1
	set GameState($gameID,hg_ready)			0

	set GameState($gameID,hg_sand_fallen) 0

	$GameState($gameID,hg_img_current) blank

	set upper_mark [expr {$HourGlass(cone_start) - \
	  ( $HourGlass(quantity) - $HourGlass(cone_fill) ) + $GameState($gameID,hg_sand_fallen)}]
	set GameState($gameID,hg_lower_mark) \
	  [expr {$HourGlass(bottom_mark) - $GameState($gameID,hg_sand_fallen)}]

	$GameState($gameID,hg_img_current) copy $HourGlass(img_empty) \
	  -from 0 0 $HourGlass(width) $upper_mark -to 0 0 
	$GameState($gameID,hg_img_current) copy $HourGlass(img_full) \
	  -from 0 $upper_mark $HourGlass(width) $HourGlass(half_mark) -to 0 $upper_mark
	$GameState($gameID,hg_img_current) copy $HourGlass(img,$GameState($gameID,hg_wc)) \
	  -from 0 $HourGlass(half_mark) $HourGlass(width) $GameState($gameID,hg_lower_mark) \
	  -to 0 $HourGlass(half_mark)
	$GameState($gameID,hg_img_current) copy $HourGlass(img_full) \
	  -from 0 $GameState($gameID,hg_lower_mark) $HourGlass(width) $HourGlass(height) \
	  -to 0 $GameState($gameID,hg_lower_mark)
  }

  proc stop_hour_glass {gameID widget} {
	variable GameState
	variable bkg_color
	variable err_bkg_color

	# Cancel possibly running hourglass
    if {$GameState($gameID,hg_animate) != ""} {
	  after cancel $GameState($gameID,hg_animate)
 	}
	$widget configure -bg $err_bkg_color
  }

  proc start_hour_glass {gameID widget} {
	variable GameState
	variable bkg_color

	# Cancel possibly running hourglass
    if {$GameState($gameID,hg_animate) != ""} {
	  after cancel $GameState($gameID,hg_animate)
 	}

	$widget configure -bg $bkg_color
    init_hour_glass $gameID $widget
	set GameState($gameID,hg_tstart) [clock seconds]
    animate $gameID $widget
  }
}
