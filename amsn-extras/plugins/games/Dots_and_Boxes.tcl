#############################################################################
#  ::Games::DotsAndBoxes													#
#  ======================================================================== #
#	Original author: JeeBee <jonne_z REM0VEatTH1S users.sourceforge.net>	#
#	Contributors:															#
#############################################################################

# FIXME: 
# Scapor told me he had some suggestions, maybe he'll send them by email.
# <scapor> but I thought about somthing like "typing notification" buit 
# when the player hovvers the board with the mouse etc
# <scapor> and some gui things
# Maybe change status to something like "Opponent seems to be thinking"
# after MouseMotion occured, and set a timeout to 10 secs or something to
# reset that state, unless another MouseMotion occurs.

namespace eval ::Games::Dots_and_Boxes {

  # GameState array per chatid (hack for 2-dimensional arrays used)
  array set GameState {}
  # Contains GameState("$gameID,X"), where X is one of
  # Board size      - X = N
  # Board           - X in {movelist, curmove, boxes, curboxes}
  # Player          - X in {my_chatid, my_name, my_color}
  # Current ply     - X = ply
  # Opponent        - X in {opponent_chatid, opponent_name, opponent_color}
  # Highlighting    - X in {hlx, hly, hld, hlc}
  # Quick move      - X = rematch_quick_move
  # Finished games  - X in {my_wins, opp_wins, draws}
  # Toplevel window - X = win_name

  # Defaults for challenges:
  variable __board_size 6
  variable __my_color "random"

  ###########################################################################
  # config_array															#
  # ======================================================================= #
  # Return variables with default values that we want to store				#
  ###########################################################################
  proc config_array {} {
	set lst [list \
	  ::Games::Dots_and_Boxes::BoardLayout(x0)	{10} \
	  ::Games::Dots_and_Boxes::BoardLayout(y0)	{10} \
	  ::Games::Dots_and_Boxes::BoardLayout(dx)	{75} \
	  ::Games::Dots_and_Boxes::BoardLayout(dy)	{75} \
	  ::Games::Dots_and_Boxes::BoardLayout(ds)	{15} \
	  ::Games::Dots_and_Boxes::BoardLayout(sp)	{3} ]
	return $lst
  }

  ###########################################################################
  # build_config															#
  # ======================================================================= #
  # Pack configuration items into pane.										#
  # Return 0 if you don't want a pane for this game.						#
  ###########################################################################
  proc build_config { pane } {
	label $pane.x0_lbl -text "[::Games::trans margin_width]"
	entry $pane.x0_var -textvar ::Games::config(::Games::Dots_and_Boxes::BoardLayout(x0))
	label $pane.y0_lbl -text "[::Games::trans margin_height]"
	entry $pane.y0_var -textvar ::Games::config(::Games::Dots_and_Boxes::BoardLayout(y0))
	label $pane.dx_lbl -text "[::Games::trans width_of_box]"
	entry $pane.dx_var -textvar ::Games::config(::Games::Dots_and_Boxes::BoardLayout(dx))
	label $pane.dy_lbl -text "[::Games::trans height_of_box]"
	entry $pane.dy_var -textvar ::Games::config(::Games::Dots_and_Boxes::BoardLayout(dy))
	label $pane.ds_lbl -text "[::Games::trans dot_size]"
	entry $pane.ds_var -textvar ::Games::config(::Games::Dots_and_Boxes::BoardLayout(ds))
	label $pane.sp_lbl -text "[::Games::trans space_around_dot]"
	entry $pane.sp_var -textvar ::Games::config(::Games::Dots_and_Boxes::BoardLayout(sp))
	grid $pane.x0_lbl $pane.x0_var -padx 10 -in $pane
	grid $pane.y0_lbl $pane.y0_var -padx 10 -in $pane
	grid [frame $pane.foo1 -height 10] - -padx 10 -in $pane
	grid $pane.dx_lbl $pane.dx_var -padx 10 -in $pane
	grid $pane.dy_lbl $pane.dy_var -padx 10 -in $pane
	grid [frame $pane.foo2 -height 10] - -padx 10 -in $pane
	grid $pane.ds_lbl $pane.ds_var -padx 10 -in $pane
	grid $pane.sp_lbl $pane.sp_var -padx 10 -in $pane
	return 1
  }

  ###########################################################################
  # init_game																#
  # ======================================================================= #
  # Ask the user about the game configuration								#
  # Returns string, e.g. "your_color=random,board_size=6", 					#
  # that is sent in a challenge												#
  ###########################################################################
  proc init_game { gameID mychat oppchat } {

	set win_name [string map {"." "" ":" ""} $gameID]
	set myname   [::Games::getNick $mychat]
	set oppname  [::Games::getNick $oppchat]
    set challenge [game_configuration $win_name]
	if {"$challenge" != ""} {
      return [set_init_game $gameID $challenge $mychat $oppchat]
	} else {
	  return ""
	}
  }

  # Set or change game configuration
  # This proc is also called when starting a rematch
  # game_init looks like "your_color=random,board_size=6"
  proc set_init_game { gameID game_init mychat oppchat } {
    variable GameState
	set win_name [string map {"." "" ":" ""} $gameID]
	set myname   [::Games::getNick $mychat]
	set oppname  [::Games::getNick $oppchat]

    # If we are rematching we must not overwrite the complete GameState
    if {![info exists GameState($gameID,N)]} {
	  array set GameState [list 					\
		"$gameID,my_chatid"				"$mychat"	\
		"$gameID,my_name"				"$myname"	\
		"$gameID,opponent_chatid"		"$oppchat"	\
		"$gameID,opponent_name"			"$oppname"	\
		"$gameID,hlx"					-1			\
		"$gameID,hly"					-1			\
		"$gameID,hld"					none		\
		"$gameID,hlc"					none		\
		"$gameID,rematch_quick_move"	""			\
		"$gameID,my_wins"				0			\
		"$gameID,opp_wins"				0			\
		"$gameID,draws"					0			\
		"$gameID,win_name"				"$win_name" ]
    }

    # Process game_init
    foreach rec [split $game_init ","] {
      foreach {name value} [split $rec "="] {
        switch -exact $name {
          "your_color" { set my_color $value
                         if {$my_color == "red"} {
                           set opponent_color "yellow"
                         } elseif {$my_color == "yellow" } {
                           set opponent_color "red"
                         } else {
                           # Random colors are used, compute actual values now
                           if {[expr {rand() > 0.5}]} {
                             set my_color "red"
                             set opponent_color "yellow"
                           } else {
                             set my_color "yellow"
                             set opponent_color "red"
                           }
                         }
                       }
          "board_size" { if {$value > 0 && $value < 20} {
                           set N $value 
                         } 
                       }
        }
      }
    }

	resetMovelist $win_name

    # If rematching, set names correctly
    set my_name $GameState($gameID,my_name)
    set opponent_name $GameState($gameID,opponent_name)
    set my_wins $GameState($gameID,my_wins)
    set opp_wins $GameState($gameID,opp_wins)
    set draws $GameState($gameID,draws)

    if { $my_color == "red" && [winfo exists ".$win_name.redname"] } {
	  .$win_name.redname configure \
        -text "$my_name ($my_wins [::Games::trans wins], $draws [::Games::trans draws])"
	  .$win_name.yellowname configure -text \
        "$opponent_name ($opp_wins [::Games::trans wins], $draws [::Games::trans draws])"
    } elseif {[winfo exists ".$win_name.redname"]} {
	  .$win_name.redname configure -text \
        "$opponent_name ($opp_wins [::Games::trans wins], $draws [::Games::trans draws])"
	  .$win_name.yellowname configure \
        -text "$my_name ($my_wins [::Games::trans wins], $draws [::Games::trans draws])"
    }

    array set GameState [list 					\
      "$gameID,N"				$N				\
      "$gameID,ply"				0				\
	  "$gameID,movelist"		{}				\
	  "$gameID,curmove"			{}				\
	  "$gameID,boxes"			{}				\
	  "$gameID,curboxes"		{}				\
      "$gameID,my_color"		"$my_color"		\
      "$gameID,opponent_color"	"$opponent_color" ]

    return "your_color=${opponent_color},board_size=$N"
  }

  proc resetMovelist { win_name } {
    if {[winfo exists .$win_name.movelist]} {
	  # Destroy all old movelist labels
	  set ply 0
	  while {[winfo exists .$win_name.mlist$ply]} {
	    destroy .$win_name.mlist$ply
		incr ply
	  }
	  label .$win_name.mlist0 -text "1. "
	  pack .$win_name.mlist0 -in .$win_name.movelist -anchor w
    }
  }

  proc Rematch { gameID } {
    variable GameState

    set N $GameState($gameID,N)
    set my_chatid $GameState($gameID,my_chatid)
    set my_name $GameState($gameID,my_name)
    set opponent_chatid $GameState($gameID,opponent_chatid)
    set opponent_name $GameState($gameID,opponent_name)
    set opponent_color $GameState($gameID,opponent_color)
    set rematch_quick_move $GameState($gameID,rematch_quick_move)
    set win_name $GameState($gameID,win_name)

    set_init_game $gameID "your_color=${opponent_color},board_size=$N" \
                  "$my_chatid" "$opponent_chatid"
    pack forget .$win_name.status.rematch
    draw_board $gameID

    set my_color $GameState($gameID,my_color)
    if {$my_color == "red"} {
      .$win_name.status.lbl configure -text "[::Games::trans your_turn]"
	  # Bind mouse
	  bind .$win_name.canvas <ButtonRelease> "::Games::Dots_and_Boxes::MouseRelease $gameID %x %y"
	  bind .$win_name.canvas <Motion> "::Games::Dots_and_Boxes::MouseMotion $gameID %x %y"
    } else {
      .$win_name.status.lbl configure -text "[::Games::trans not_your_turn]"
      # If our opponent rematched faster than us, he might already have moved ...
      if {"$rematch_quick_move" != ""} {
        opponent_moves $gameID {} $rematch_quick_move
        set GameState($gameID,rematch_quick_move) ""
      }
    }
  }

  proc quit { gameID } {
    variable GameState
    ::Games::SendQuit $gameID
    destroy .$GameState($gameID,win_name)
  }

  proc start_game { gameID } {
    variable GameState

    # GameState
    set N				$GameState($gameID,N)
    set my_color		$GameState($gameID,my_color)
    set my_name			$GameState($gameID,my_name)
    set opponent_name	$GameState($gameID,opponent_name)
    set win_name 		$GameState($gameID,win_name)
    # BoardLayout
    set x0 ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(x0))}
	set y0 ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(y0))}
    set dx ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(dx))}
	set dy ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(dy))}
    set ds ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(ds))}
	set sp ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(sp))}

	toplevel .$win_name
    wm protocol .$win_name WM_DELETE_WINDOW "::Games::Dots_and_Boxes::quit $gameID"
    wm title .$win_name "${N}x${N} [::Games::trans Dots_and_Boxes]"
	#wm minsize .$win_name [expr {150 + 2*$x0+($N-1)*$dx+$ds}] ...height...
	# The board
	canvas .$win_name.canvas -relief sunken -background "peach puff" \
	  -width [expr {2*$x0+($N-1)*$dx+$ds}] \
	  -height [expr {2*$y0+($N-1)*$dy+$ds}]
	# Vertical coordinates
	frame .$win_name.vcor
	frame .$win_name.vcor.0 -height $y0
	pack .$win_name.vcor.0 -in .$win_name.vcor
	for {set y 1} {$y < $N} {incr y} {
	  frame .$win_name.vcor.$y
	  label .$win_name.vcor.${y}.lbl -text "[expr {2*($N-$y)}]"
	  pack .$win_name.vcor.${y}.lbl -in .$win_name.vcor.$y -fill both -expand true
	  pack .$win_name.vcor.$y -in .$win_name.vcor -fill both -expand true -pady [expr {$ds/2}]
	}
	frame .$win_name.vcor.$N -height $y0
	pack .$win_name.vcor.$N -in .$win_name.vcor
	# Horizontal coordinates
	frame .$win_name.hcor
	frame .$win_name.hcor.0 -width $x0
	pack .$win_name.hcor.0 -in .$win_name.hcor -side left
	for {set x 1} {$x < $N} {incr x} {
	  frame .$win_name.hcor.$x
	  label .$win_name.hcor.${x}.lbl -text "[format "%c" [expr {[scan "a" %c]+2*$x-1}]]"
	  pack .$win_name.hcor.${x}.lbl -in .$win_name.hcor.$x
	  pack .$win_name.hcor.$x -in .$win_name.hcor -side left -fill both -expand true -padx [expr {$ds/2}]
	}
	frame .$win_name.hcor.$N -width $x0
	pack .$win_name.hcor.$N -in .$win_name.hcor -side left
	# Movelist
	labelframe .$win_name.movelist -text "[::Games::trans movelist]"
	resetMovelist $win_name
	# Player info
	labelframe .$win_name.players -text "[::Games::trans players]"
	frame .$win_name.playerswrap
	label .$win_name.redplayer -text "[::Games::trans red]"
	label .$win_name.redscore -text "0"
	label .$win_name.yellowplayer -text "[::Games::trans yellow]"
	label .$win_name.yellowscore -text "0"
    if {$my_color == "red"} {
	  label .$win_name.redname -text "$my_name"
	  label .$win_name.yellowname -text "$opponent_name"
    } else {
	  label .$win_name.redname -text "$opponent_name"
	  label .$win_name.yellowname -text "$my_name"
    }
	grid .$win_name.redplayer .$win_name.redscore .$win_name.redname \
      -in .$win_name.playerswrap -sticky w
	grid .$win_name.yellowplayer .$win_name.yellowscore .$win_name.yellowname \
      -in .$win_name.playerswrap -sticky w
	pack .$win_name.playerswrap -in .$win_name.players -side left
	# Status line
	labelframe .$win_name.status -text "[::Games::trans status]"
	label .$win_name.status.lbl -text "[::Games::trans initializing]"
	pack .$win_name.status.lbl -in .$win_name.status -side left
	# Packing
	frame .$win_name.dummy
	grid .$win_name.vcor .$win_name.canvas .$win_name.movelist -sticky news
	grid .$win_name.dummy .$win_name.hcor -sticky news
	grid .$win_name.players - - -sticky news
	grid .$win_name.status - - -sticky news
	grid rowconfigure .$win_name {2 3} -weight 1
	grid columnconfigure .$win_name 2 -weight 1
    ::Games::moveinscreen .$win_name

    draw_board $gameID

    if {$my_color == "red"} {
      .$win_name.status.lbl configure -text "[::Games::trans your_turn]"
	  # Bind mouse
	  bind .$win_name.canvas <ButtonRelease> "::Games::Dots_and_Boxes::MouseRelease $gameID %x %y"
	  bind .$win_name.canvas <Motion> "::Games::Dots_and_Boxes::MouseMotion $gameID %x %y"
    } else {
      .$win_name.status.lbl configure -text "[::Games::trans not_your_turn]"
    }
  }

  proc MouseRelease { gameID mx my } {
    variable GameState

    # GameState
    set N				$GameState($gameID,N)
    set my_color		$GameState($gameID,my_color)
    set my_name			$GameState($gameID,my_name)
    set opponent_chatid	$GameState($gameID,opponent_chatid)
    set opponent_name	$GameState($gameID,opponent_name)
    set opponent_color	$GameState($gameID,opponent_color)
	set hlx 			$GameState($gameID,hlx)
	set hly 			$GameState($gameID,hly)
	set hld 			$GameState($gameID,hld)
    set win_name 		$GameState($gameID,win_name)

	if {$hlx >= 0} {
	  unset_highlight $gameID
	  draw_board $gameID
	  lappend GameState($gameID,curmove) "$hlx $hly $hld"
	  draw_element $gameID $hlx $hly $hld $my_color

	  if {[check_new_boxes $gameID $hlx $hly $hld $my_color] == 0} {
		# No new boxes means end of move

        # Unbind mouse as it is not our turn anymore
        bind .$win_name.canvas <ButtonRelease> ""
        bind .$win_name.canvas <Motion> ""

		set movestr [update_board_info $gameID \
                       $GameState($gameID,curmove) $GameState($gameID,curboxes)]
		set GameState($gameID,movelist) \
          [concat $GameState($gameID,movelist) $GameState($gameID,curmove)]
		set GameState($gameID,curmove) {}
		set GameState($gameID,boxes) \
          [concat $GameState($gameID,boxes) $GameState($gameID,curboxes)]
		set GameState($gameID,curboxes) {}
        
        # Send move to opponent
        ::Games::SendMove $gameID $movestr
        .$win_name.status.lbl configure -text "[::Games::trans not_your_turn]"
	  } elseif {[expr {[llength $GameState($gameID,boxes)] + \
                      [llength $GameState($gameID,curboxes)] == ($N-1)*($N-1)}]} {
		# Game finished
		set movestr [update_board_info $gameID \
                       $GameState($gameID,curmove) $GameState($gameID,curboxes)]
		set GameState($gameID,movelist) \
          [concat $GameState($gameID,movelist) $GameState($gameID,curmove)]
		set GameState($gameID,curmove) {}
		set GameState($gameID,boxes) \
          [concat $GameState($gameID,boxes) $GameState($gameID,curboxes)]
		set GameState($gameID,curboxes) {}
        # update_board_info is just called, we can use current player scores
        # do determine the winner
        if {$my_color == "red"} {
  	      set my_score [.$win_name.redscore cget -text]
	      set opp_score [.$win_name.yellowscore cget -text]
        } else {
  	      set my_score [.$win_name.yellowscore cget -text]
	      set opp_score [.$win_name.redscore cget -text]
        }
        if {$my_score > $opp_score} {
          .$win_name.status.lbl configure -text "[::Games::trans game_over_win]"
          incr GameState($gameID,my_wins)
        } elseif {$my_score < $opp_score} {
          .$win_name.status.lbl configure -text "[::Games::trans game_over_lose]"
          incr GameState($gameID,opp_wins)
        } else {
          .$win_name.status.lbl configure -text "[::Games::trans game_over_draw]"
          incr GameState($gameID,draws)
        }
        # Unbind mouse
        bind .$win_name.canvas <ButtonRelease> ""
        bind .$win_name.canvas <Motion> ""
        # Create rematch button
        if {![winfo exists .$win_name.status.rematch]} {
          button .$win_name.status.rematch -text "[::Games::trans click_rematch]" \
            -command "::Games::Dots_and_Boxes::Rematch $gameID"
        }
	    pack .$win_name.status.rematch -in .$win_name.status -side right
        # Send move to opponent
        ::Games::SendMove $gameID $movestr
	  }
	}
  }

  proc opponent_moves { gameID sender the_move } {
    variable GameState

    set N				$GameState($gameID,N)
    set my_color		$GameState($gameID,my_color)
    set opponent_color	$GameState($gameID,opponent_color)
    set win_name 		$GameState($gameID,win_name)

    if {[expr {[llength $GameState($gameID,boxes)] == ($N-1)*($N-1)}]} {
      # Opponent moved, but game finished already.
      # This means we play red at the moment, our opponent
      # rematched hence plays red in the new game, and moved,
      # all before we clicked rematch.
      set GameState($gameID,rematch_quick_move) $the_move
      return
    }

    # FIXME: While parsing check that the_move is a valid move

    draw_board $gameID
    foreach m [split $the_move " "] {
      set x [expr {[scan [string index $m 0] %c] - [scan "a" %c]}]
      set y [expr {[string range $m 1 end]-1}]
      if {[expr {$x % 2}] == 0} {
        # vertical move
        set d "ver"
        set x [expr {$x/2}]
        set y [expr {$N-(($y+1)/2)-1}]
      } else {
        # horizontal move
        set d "hor"
        set x [expr {($x-1)/2}]
        set y [expr {$N-($y/2)-1}]
      }
	  lappend GameState($gameID,curmove) "$x $y $d"
	  draw_element $gameID $x $y $d $opponent_color
	  check_new_boxes $gameID $x $y $d $opponent_color
    }
	if {[expr {[llength $GameState($gameID,boxes)] + \
              [llength $GameState($gameID,curboxes)] == ($N-1)*($N-1)}]} {
      # Opponent took all remaining boxes, update_board_info is called below,
      # but our score is correct already.
      if {$my_color == "red"} {
  	    set my_score [.$win_name.redscore cget -text]
      } else {
  	    set my_score [.$win_name.yellowscore cget -text]
      }
      if {[expr {$my_score > ($N-1)*($N-1)/2.0}]} {
        .$win_name.status.lbl configure -text "[::Games::trans game_over_win]"
        incr GameState($gameID,my_wins)
      } elseif {[expr {$my_score < ($N-1)*($N-1)/2.0}]} {
        .$win_name.status.lbl configure -text "[::Games::trans game_over_lose]"
        incr GameState($gameID,opp_wins)
      } else {
        .$win_name.status.lbl configure -text "[::Games::trans game_over_draw]"
        incr GameState($gameID,draws)
      }
	  # Create rematch button
      if {![winfo exists .$win_name.status.rematch]} {
		button .$win_name.status.rematch -text "[::Games::trans click_rematch]" \
		  -command "::Games::Dots_and_Boxes::Rematch $gameID"
      }
	  pack .$win_name.status.rematch -in .$win_name.status -side right
    } else {
      # Now it's our turn again, enable the mouse
      .$win_name.status.lbl configure -text "[::Games::trans your_turn]"
	  bind .$win_name.canvas <ButtonRelease> "::Games::Dots_and_Boxes::MouseRelease $gameID %x %y"
	  bind .$win_name.canvas <Motion> "::Games::Dots_and_Boxes::MouseMotion $gameID %x %y"
    }
    update_board_info $gameID $GameState($gameID,curmove) $GameState($gameID,curboxes)
	set GameState($gameID,movelist) \
      [concat $GameState($gameID,movelist) $GameState($gameID,curmove)]
	set GameState($gameID,curmove) {}
	set GameState($gameID,boxes) \
      [concat $GameState($gameID,boxes) $GameState($gameID,curboxes)]
	set GameState($gameID,curboxes) {}
  }

  proc opponent_quits { gameID chatid } {
    variable GameState
    set opponent_name $GameState($gameID,opponent_name)
    set win_name $GameState($gameID,win_name)

    # Check whether our toplevel is gone already
    if {![winfo exists .$win_name]} {
      return
    }

    .$win_name.status.lbl configure -text "$opponent_name [::Games::trans quits]"

    # Unbind mouse
    bind .$win_name.canvas <ButtonRelease> ""
    bind .$win_name.canvas <Motion> ""
  }

  proc MouseMotion { gameID mx my } {
    # BoardLayout
    set x0 ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(x0))}
	set y0 ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(y0))}
    set dx ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(dx))}.0
	set dy ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(dy))}.0
    set ds ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(ds))}
	set sp ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(sp))}

	set x [expr {($mx-$x0)/$dx}]
	set y [expr {($my-$y0)/$dy}]

	# Check for vertical highlighting
	if {[expr {$x>=0.0 && ($x-int($x)) <= ($ds/$dx)}] &&
		[expr {$y>=0.0 && ($y-int($y))  > ($ds/$dy)}]} {
	  set_highlight $gameID [expr {int($x)}] [expr {int($y)}] ver green
	# Check for horizontal highlighting
	} elseif {[expr {$x>=0.0 && ($x-int($x))  > ($ds/$dx)}] &&
			  [expr {$y>=0.0 && ($y-int($y)) <= ($ds/$dy)}]} {
	  set_highlight $gameID [expr {int($x)}] [expr {int($y)}] hor green
	} else {
	  unset_highlight $gameID
	}
  }

  proc update_board_info { gameID curmove curboxes } {
    variable GameState

    set N 			$GameState($gameID,N)
    set boxes		$GameState($gameID,boxes)
    set ply			$GameState($gameID,ply)
    set	win_name	$GameState($gameID,win_name)

    # Convert curmove to move string
	set ms ""
	foreach move $curmove {
	  foreach {x y d} $move {
		if {$d == "hor"} {
		  set ms "${ms}[format "%c" [expr {[scan "b" %c] + 2*$x}]]"
		  set ms "${ms}[expr {2*($N-$y)-1}] "
		} else {
		  set ms "${ms}[format "%c" [expr {[scan "a" %c] + 2*$x}]]"
		  set ms "${ms}[expr {2*($N-$y)-2}] "
		}
	  }
	}
    set ms [string trimright $ms]

    # Update movelist
	if {[expr {$ply % 2 == 0}]} {
	  # Update red move
	  set m [.$win_name.mlist[expr {$ply/2}] cget -text]
	  .$win_name.mlist[expr {$ply/2}] configure -text "$m$ms"
    } else {
	  # Update yellow move
	  set m [.$win_name.mlist[expr {$ply/2}] cget -text]
	  .$win_name.mlist[expr {$ply/2}] configure -text "$m - $ms"
	  label .$win_name.mlist[expr {$ply/2+1}] -text "[expr {$ply/2+2}]. "
	  pack .$win_name.mlist[expr {$ply/2+1}] -in .$win_name.movelist -anchor w
    }

    # Update player scores
    set red_score 0
    set yellow_score 0
	foreach box [concat $boxes $curboxes] {
	  foreach {x y c} $box {
		if { $c == "red" } {
          incr red_score
        } else {
          incr yellow_score
        }
      }
    }
	.$win_name.redscore configure -text $red_score
	.$win_name.yellowscore configure -text $yellow_score

    # Increase ply number
	incr GameState($gameID,ply)
    return $ms
  }

  # Move (x y d) has just been played.
  # At most two new boxes can be constructed
  proc check_new_boxes {gameID x y d c} {
    variable GameState
	set N 			$GameState($gameID,N)
    set movelist	$GameState($gameID,movelist)
    set curmove 	$GameState($gameID,curmove)
    set curboxes	$GameState($gameID,curboxes)

	set new_box 0

	if {$d == "hor"} {
	  # Check box above
	  if {[lsearch -exact [concat $movelist $curmove] "$x [expr {$y-1}] hor"] > -1 &&
		  [lsearch -exact [concat $movelist $curmove] "$x [expr {$y-1}] ver"] > -1 &&
		  [lsearch -exact [concat $movelist $curmove] "[expr {$x+1}] [expr {$y-1}] ver"] > -1} {
		lappend curboxes "$x [expr {$y-1}] $c"
		draw_element $gameID $x [expr {$y-1}] box $c
		incr new_box
	  }
	  # Check box below
	  if {[lsearch -exact [concat $movelist $curmove] "$x [expr {$y+1}] hor"] > -1 &&
		  [lsearch -exact [concat $movelist $curmove] "$x $y ver"] > -1 &&
		  [lsearch -exact [concat $movelist $curmove] "[expr {$x+1}] $y ver"] > -1} {
		lappend curboxes "$x $y $c"
		draw_element $gameID $x $y box $c
		incr new_box
	  }
	} else {
	  # Check box to the left
	  if {[lsearch -exact [concat $movelist $curmove] "[expr {$x-1}] $y ver"] > -1 &&
		  [lsearch -exact [concat $movelist $curmove] "[expr {$x-1}] $y hor"] > -1 &&
		  [lsearch -exact [concat $movelist $curmove] "[expr {$x-1}] [expr {$y+1}] hor"] > -1} {
		lappend curboxes "[expr {$x-1}] $y $c"
		draw_element $gameID [expr {$x-1}] $y box $c
		incr new_box
	  }
	  # Check box to the right
	  if {[lsearch -exact [concat $movelist $curmove] "[expr {$x+1}] $y ver"] > -1 &&
		  [lsearch -exact [concat $movelist $curmove] "$x $y hor"] > -1 &&
		  [lsearch -exact [concat $movelist $curmove] "$x [expr {$y+1}] hor"] > -1} {
		lappend curboxes "$x $y $c"
		draw_element $gameID $x $y box $c
		incr new_box
	  }
	}

    set GameState($gameID,curboxes) $curboxes
	return $new_box
  }

  proc set_highlight {gameID x y d c} {
    variable GameState

    set N			$GameState($gameID,N)
    set movelist	$GameState($gameID,movelist)
    set curmove 	$GameState($gameID,curmove)

	# Remove old higlighting
	unset_highlight $gameID

	# Check board size constraints
	if {$x >= 0 && $y >= 0 &&
		$x < $N && $y < $N &&
		($d == "ver" || [expr {$x < ($N-1)}]) &&
		($d == "hor" || [expr {$y < ($N-1)}])} {

	  # Do not allow an already played move to be highlighted
	  if {[lsearch -exact [concat $movelist $curmove] "$x $y $d"] == -1} {
		set GameState($gameID,hlx) $x
		set GameState($gameID,hly) $y
		set GameState($gameID,hld) $d
		set GameState($gameID,hlc) $c
		draw_element $gameID $x $y $d $c
	  }
	}
  }

  proc unset_highlight { gameID } {
    variable GameState

	set hlx $GameState($gameID,hlx)
    set hly $GameState($gameID,hly)
    set hld $GameState($gameID,hld)

	if {$hlx >= 0} {
      # FIXME: should actually use canvas delete here
	  draw_element $gameID $hlx $hly $hld "peach puff"
	  set GameState($gameID,hlx) -1
	}
  }

  proc draw_element {gameID x y d c} {
    variable GameState

    set	win_name $GameState($gameID,win_name)
    # BoardLayout
    set x0 ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(x0))}
	set y0 ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(y0))}
    set dx ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(dx))}
	set dy ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(dy))}
    set ds ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(ds))}
	set sp ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(sp))}

	if {$d == "hor"} {
	  # Horizontal move at (x, y)
	  .$win_name.canvas create rectangle \
		[expr {$x0+$x*$dx+$ds+$sp}] [expr {$y0+$y*$dy}] \
		[expr {$x0+($x+1)*$dx-$sp}] [expr {$y0+$y*$dy+$ds}] \
		-fill $c -outline $c
	} elseif {$d == "ver"} {
	  # Vertical move at (x, y)
	  .$win_name.canvas create rectangle \
		[expr {$x0+$x*$dx}]     [expr {$y0+$y*$dy+$ds+$sp}] \
		[expr {$x0+$x*$dx+$ds}] [expr {$y0+($y+1)*$dy-$sp}] \
		-fill $c -outline $c
	} else {
	  # Box at (x, y)
	  .$win_name.canvas create rectangle \
		[expr {$x0+$x*$dx+$ds+$sp}] [expr {$y0+$y*$dy+$ds+$sp}] \
		[expr {$x0+($x+1)*$dx-$sp}] [expr {$y0+($y+1)*$dy-$sp}] \
		-fill $c -outline $c
	}
  }

  proc draw_board { gameID } {
    variable GameState

    # BoardLayout
    set x0 ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(x0))}
	set y0 ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(y0))}
    set dx ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(dx))}
	set dy ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(dy))}
    set ds ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(ds))}
	set sp ${::Games::config(::Games::Dots_and_Boxes::BoardLayout(sp))}

    # GameState
	set N 			$GameState($gameID,N)
    set movelist 	$GameState($gameID,movelist)
    set curmove 	$GameState($gameID,curmove)
    set my_color 	$GameState($gameID,my_color)
    set boxes 		$GameState($gameID,boxes)
    set curboxes 	$GameState($gameID,curboxes)
    set	win_name	$GameState($gameID,win_name)

	.$win_name.canvas delete all

	# The dots
	for {set y 0} {$y < $N} {incr y} {
	  for {set x 0} {$x < $N} {incr x} {
		.$win_name.canvas create rectangle \
		  [expr {$x0+$x*$dx}]     [expr {$y0+$y*$dy}] \
		  [expr {$x0+$x*$dx+$ds}] [expr {$y0+$y*$dy+$ds}] \
		  -fill "sienna" -outline "sienna"
	  }
	}
	# The moves
	foreach move $movelist {
	  foreach {x y d} $move {
		draw_element $gameID $x $y $d "sienna"
	  }
	}
	# The current move
	foreach move $curmove {
	  foreach {x y d} $move {
		draw_element $gameID $x $y $d $my_color
	  }
	}
	# The boxes
	foreach box [concat $boxes $curboxes] {
	  foreach {x y c} $box {
		draw_element $gameID $x $y box $c
	  }
	}
  }

  proc game_configuration { win_name } {
	variable __challenge "none"
	variable __win_name  $win_name
	variable __board_size
	variable __my_color
	variable __opponent_color ""

    toplevel .${win_name}_gc
    wm title .${win_name}_gc "[::Games::trans specify_configuration]"
    wm protocol .${win_name}_gc WM_DELETE_WINDOW ".${win_name}_gc.cancel invoke"

    labelframe .${win_name}_gc.lbf1 -text "[::Games::trans select_size]"
    scale .${win_name}_gc.scl -digit 1 -from 4 -to 16 -orient h -tickinterval 4 \
	  -variable ::Games::Dots_and_Boxes::__board_size
    pack .${win_name}_gc.scl -in .${win_name}_gc.lbf1

    labelframe .${win_name}_gc.lbf2 -text "[::Games::trans select_color]"
    listbox .${win_name}_gc.lst -selectmode single -height 3
    .${win_name}_gc.lst insert end \
	  "[::Games::trans red]" "[::Games::trans yellow]" "[::Games::trans random]"
    switch -exact $__my_color {
      "red"    { .${win_name}_gc.lst selection set 0 }
      "yellow" { .${win_name}_gc.lst selection set 1 }
      "random" { .${win_name}_gc.lst selection set 2 }
    }
    pack .${win_name}_gc.lst -in .${win_name}_gc.lbf2 -anchor w

    frame .${win_name}_gc.buttons
    button .${win_name}_gc.ok -text "[::Games::trans challenge]" -command {
      switch -exact [.${::Games::Dots_and_Boxes::__win_name}_gc.lst curselection] {
        0 { set ::Games::Dots_and_Boxes::__my_color "red" 
            set ::Games::Dots_and_Boxes::__opponent_color "yellow" }
        1 { set ::Games::Dots_and_Boxes::__my_color "yellow" 
            set ::Games::Dots_and_Boxes::__opponent_color "red" }
        2 { set ::Games::Dots_and_Boxes::__my_color "random" 
            set ::Games::Dots_and_Boxes::__opponent_color "random" }
      }
	  set str1 "your_color=${::Games::Dots_and_Boxes::__my_color},"
	  set str2 "board_size=${::Games::Dots_and_Boxes::__board_size}"
	  set ::Games::Dots_and_Boxes::__challenge "$str1$str2"
    }
    button .${win_name}_gc.cancel -text "[::Games::trans cancel]" -command {
	  set ::Games::Dots_and_Boxes::__challenge ""
	}
    pack .${win_name}_gc.ok .${win_name}_gc.cancel -in .${win_name}_gc.buttons -side left

    frame .${win_name}_gc.sep -width 5
    grid .${win_name}_gc.lbf1 .${win_name}_gc.lbf2 -padx 10 -sticky news
    grid x .${win_name}_gc.buttons -padx 10 -sticky news
    ::Games::moveinscreen .${win_name}_gc

    update idletask
    grab set .${win_name}_gc
    tkwait variable ::Games::Dots_and_Boxes::__challenge
    destroy .${win_name}_gc

    # must return "your_color=<my color here>,board_size=<board size here>"
	# because this value is passed to set_init_game
	return $__challenge
  }

}
