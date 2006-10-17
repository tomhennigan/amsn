############################################################################
# Author: JeeBee <jonne_z REM0VEatTH1S users.sourceforge.net>
#
# original author: Richard Suchenwirth 2002-09-14
# url: http://wiki.tcl.tk/4070
#
# Modifications by JeeBee,
# todo * Support for castling (and castling state as part of game state).
# todo * Support for en passent move (also added to game state).
# todo * Support for check.
# todo * Support for promotion of pieces
# todo * Movelist.
# todo * Running as an aMSN plugin
# todo * Tested with Tcl/Tk 8.4 and 8.5.

namespace eval ::Games::Chess {

  variable GameState
  variable Squares {}

  # Defaults for challenges:
  variable __my_color "random"

  ###########################################################################
  # config_array                                                            #
  # ======================================================================= #
  # Return variables with default values that we want to store              #
  ###########################################################################
  proc config_array {} {
	variable Squares
    foreach r {8 7 6 5 4 3 2 1} {
      foreach c {A B C D E F G H} {
		lappend Squares $c$r
	  }
	}

	set lst [list \
		::Games::Chess::square_color_white {} \
		::Games::Chess::square_color_black {} ]
	return $lst
  }

  ###########################################################################
  # build_config                                                            #
  # ======================================================================= #
  # Pack configuration items into pane.                                     #
  # Return 0 if you don't want a pane for this game.                        #
  ###########################################################################
  proc build_config { pane } {
	return 0;
  }

  ###########################################################################
  # init_game                                                               #
  # ======================================================================= #
  # Ask the user about the game configuration                               #
  # Returns string, e.g. "your_color=random,board_size=6",                  #
  # that is sent in a challenge                                             #
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

  proc game_configuration { win_name } {
	variable __challenge "none"
	variable __win_name $win_name
	variable __my_color ;# default, set above
	variable __opponent_color ""

	toplevel .${win_name}_gc
	wm title .${win_name}_gc "[::Games::trans specify_configuration]"
    wm protocol .${win_name}_gc WM_DELETE_WINDOW ".${win_name}_gc.cancel invoke"

    labelframe .${win_name}_gc.lbf2 -text "[::Games::trans select_color]"
    listbox .${win_name}_gc.lst -selectmode single -height 3
    .${win_name}_gc.lst insert end \
      "[::Games::trans white]" "[::Games::trans black]" "[::Games::trans random]"
    switch -exact $__my_color {
      "white"	{ .${win_name}_gc.lst selection set 0 }
      "black"	{ .${win_name}_gc.lst selection set 1 }
      "random"	{ .${win_name}_gc.lst selection set 2 }
    }
    pack .${win_name}_gc.lst -in .${win_name}_gc.lbf2 -anchor w

    frame .${win_name}_gc.buttons
    button .${win_name}_gc.ok -text "[::Games::trans challenge]" -command {
      switch -exact [.${::Games::Chess::__win_name}_gc.lst curselection] {
        0 { set ::Games::Chess::__my_color "red"
            set ::Games::Chess::__opponent_color "yellow" }
        1 { set ::Games::Chess::__my_color "yellow"
            set ::Games::Chess::__opponent_color "red" }
        2 { set ::Games::Chess::__my_color "random"
            set ::Games::Chess::__opponent_color "random" }
      }
      set ::Games::Chess::__challenge \
		"your_color=${::Games::Chess::__my_color},"
    }
    button .${win_name}_gc.cancel -text "[::Games::trans cancel]" -command {
      set ::Games::Chess::__challenge ""
    }
    pack .${win_name}_gc.ok .${win_name}_gc.cancel -in .${win_name}_gc.buttons -side left

    frame .${win_name}_gc.sep -width 5
    grid .${win_name}_gc.lbf2 -padx 10 -sticky news
    grid .${win_name}_gc.buttons -padx 10 -sticky news
    ::Games::moveinscreen .${win_name}_gc

    update idletask
    grab set .${win_name}_gc
    tkwait variable ::Games::Chess::__challenge
    destroy .${win_name}_gc

    # must return "your_color=<my color here>"
    # because this value is passed to set_init_game
    return $__challenge
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
      array set GameState [list                     \
        "$gameID,my_chatid"             "$mychat"   \
        "$gameID,my_name"               "$myname"   \
        "$gameID,opponent_chatid"       "$oppchat"  \
        "$gameID,opponent_name"         "$oppname"  \
        "$gameID,rematch_quick_move"    ""          \
        "$gameID,my_wins"               0           \
        "$gameID,opp_wins"              0           \
        "$gameID,draws"                 0           \
        "$gameID,win_name"              "$win_name" ]
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
        }
      }
    }

    array set GameState [list                   \
      "$gameID,movelist"        {}              \
      "$gameID,curmove"         {}              \
      "$gameID,my_color"        "$my_color"     \
      "$gameID,opponent_color"  "$opponent_color" ]

    return "your_color=${opponent_color}"
  }

  proc quit { gameID } {
    variable GameState
    ::Games::SendQuit $gameID
    destroy .$GameState($gameID,win_name)
  }

  proc start_game {gameID} {
    variable GameState

    # GameState
    set win_name        $GameState($gameID,win_name)
    set my_color        $GameState($gameID,my_color)
    set my_name         $GameState($gameID,my_name)
    set opponent_name   $GameState($gameID,opponent_name)

    toplevel .$win_name
    wm protocol .$win_name WM_DELETE_WINDOW "::Games::Chess::quit $gameID"
	wm title .$win_name "[::Games::trans Chess] ($GameState($gameID,opponent_name)"

	reset $gameID
    frame .$win_name.f
    label  .$win_name.f.e -width 30 -anchor w -textvar GameState($gameID,info) -relief sunken
    #button .$win_name.f.u -text Undo  \
		-command "::Games::Chess::undo $gameID;  ::Games::Chess::drawSetup $gameID .$win_name.c"
    #button .$win_name.f.r -text Reset \
		-command "::Games::Chess::reset $gameID; ::Games::Chess::drawSetup $gameID .$win_name.c"
    #button .$win_name.f.f -text Flip -command "::Games::Chess::flipSides $gameID .$win_name.c"
    eval pack [winfo children .$win_name.f] -side left -fill both
    pack .$win_name.f -fill x -side bottom
    pack [drawBoard $gameID .$win_name.c] -fill both -expand 1
    set GameState($gameID,info) "white to move"
    bind .$win_name <3> "::Games::Chess::usefont_toggle $gameID"
  }

  proc usefont_toggle {gameID} {
	variable GameState
	set win_name $GameState($gameID,win_name)
	set GameState($gameID,usefont) [expr {1-$GameState($gameID,usefont)}]
	event generate .$win_name.c <Configure>
  }

  ###########################################################################
  # Ok, now the chess stuff                                                 #
  # ======================================================================= #
  ###########################################################################

  proc moveinfo {gameID} {
	variable GameState
	set GameState($gameID,info) "$GameState($gameID,toMove) to move - [values $gameID]"
  }

  proc reset {gameID {setup ""}} {
	variable GameState
    if {$setup == ""} { set setup \
        "r n b q k b n r
         p p p p p p p p
         . . . . . . . .
         . . . . . . . .
         . . . . . . . .
         . . . . . . . .
         P P P P P P P P
         R N B Q K B N R"
    }
    foreach line [split [string trim $setup] \n] y {8 7 6 5 4 3 2 1} {
        foreach word $line x {A B C D E F G H} {
            set GameState($gameID,$x$y) $word
        }
    }
    set GameState($gameID,toMove) white
	moveinfo $gameID
    set GameState($gameID,history) {} ;# start a new history...
  }

  proc format gameID {
    # render current board into a well-readable string
	variable GameState
    foreach row {8 7 6 5 4 3 2 1} {
        foreach column {A B C D E F G H} {
            append res " " $GameState($gameID,$column$row)
        }
        append res \n
    }
    set res
  }

  proc move {gameID move} {
	variable GameState
    foreach {from to} [split $move -] break
    set fromMan $GameState($gameID,$from)
    if {$fromMan == "."} {error "no man to move at $from"}
    set toMan   $GameState($gameID,$to)
    if ![valid? $gameID $move] {error "invalid move for a [manName $fromMan]"}
    set GameState($gameID,$from) .
    set GameState($gameID,$to) $fromMan
    if {$toMan != "."} {append move -$toMan} ;# taken one
    lappend GameState($gameID,history) $move
    set GameState($gameID,toMove) [expr {$GameState($gameID,toMove) == "white"? "black": "white"}]
	moveinfo $gameID
    set toMan ;# report possible victim
  }
 
  proc color man {expr {[string is upper $man]? "white" : "black"}}

  proc valid? {gameID move} {
	variable GameState
    foreach {from to} [split $move -] break
    if {$to==""} {return 0}
    set fromMan $GameState($gameID,$from)
    if {[color $fromMan] != $GameState($gameID,toMove)} {return 0}
    set toMan   $GameState($gameID,$to)
    if [sameSide $fromMan $toMan] {return 0}
    foreach {x0 y0} [coords $from] {x1 y1} [coords $to] break
    set dx  [expr {$x1-$x0}]
    set adx [expr {abs($dx)}]
    set dy  [expr {$y1-$y0}]
    set ady [expr {abs($dy)}]
    if {[string tolower $fromMan] != "n" && (!$adx || !$ady || $adx==$ady)} {
        for {set x $x0; set y $y0} {($x!=$x1 || $y!=$y1)} \
          {incr x [sgn $dx]; incr y [sgn $dy]} {
            if {($x!=$x0 || $y!=$y0) && $GameState($gameID,[square $x $y])!="."} {
                return 0
            } ;# planned path is blocked
        }
    }
    switch -- $fromMan {
        K - k {expr $adx<2 && $ady<2}
        Q - q {expr $adx==0 || $ady==0 || $adx==$ady}
        B - b {expr $adx==$ady}
        N - n {expr ($adx==1 && $ady==2)||($adx==2 && $ady==1)}
        R - r {expr $adx==0 || $ady==0}
        P {
            expr {(($y0==2 && $dy==2) || $dy==1)
              && (($dx==0 && $toMan==".") ||
                ($adx==1 && $ady==1 && [sameSide p $toMan]))
            }
        }
        p {
            expr {(($y0==7 && $dy==-2) || $dy==-1)
              && (($dx==0 && $toMan==".") ||
                ($adx==1 && $ady==1 && [sameSide P $toMan]))
            }
        }
        default {return 0}
    }
  }

  proc validMoves {gameID from} {
	variable GameState
	variable Squares
    set res {}
    foreach to $Squares {
        set move $from-$to
        if [valid? $gameID $move] {
            if {$GameState($gameID,$to) != "."} {append move -$GameState($gameID,$to)}
            lappend res $move
        }
    }
    lsort $res
  }
 
  proc coords square {
    # translate square name to numeric coords: C5 -> {3 5}
    foreach {c y} [split $square ""] break
    list [lsearch {- A B C D E F G H} $c] $y
  }
 
  proc square {x y} {
    # translate numeric coords to sq uare name: {3 5} -> C5
    return [string map {1 A 2 B 3 C 4 D 5 E 6 F 7 G 8 H} $x]$y
  }

  proc undo gameID {
	variable GameState
    if ![llength $GameState($gameID,history)] {error "Nothing to undo"}
    set move [lindex $GameState($gameID,history) end]
    foreach {from to hit} [split $move -]  break
    set GameState($gameID,history) [lrange $GameState($gameID,history) 0 end-1]
    set GameState($gameID,$from)   $GameState($gameID,$to)
    if {$hit==""} {set hit .}
    set GameState($gameID,$to) $hit
    set GameState($gameID,toMove) [expr {$GameState($gameID,toMove) == "white"? "black": "white"}]
	moveinfo $gameID
  }
 
  proc sameSide {a b} {regexp {[a-z][a-z]|[A-Z][A-Z]} $a$b]}

  proc history gameID {
	variable GameState
	set $GameState($gameID,history)
  }

  proc manName man {
    set table {- k king q queen b bishop n knight r rook p pawn}
    set i [l search $table [string tolower $man]]
    lindex $table [incr i]
  }

  proc values gameID {
    # returns the current numeric value of white and black crews
	variable GameState
	variable Squares
    set white 0; set black 0
    foreach square $Squares {
		if {[string length $square] == 2} {
        	set man $GameState($gameID,$square)
        	switch -regexp -- $man {
        	    [A-Z] {set white [expr {$white + [manValue $man]}]}
        	    [a-z] {set black [expr {$black + [manValue $man]}]}
        	}
		}
    }
    list $white $black
  }

  proc manValue man {
    array set a {k 0 q 9 b 3 n 3 r 5 p 1}
    set a([string tolower $man])
  }
 
#----------------------------------------------------------- Tk UI
# Now we create a "real" chess board on a canvas. The shapes of men 
# are extremely simple (maybe good for the visually impaired). 
# Clicking on a man highlights the valid moves in green 
# (possible takes in red) for a second. Only valid moves are accepted, 
# else the man snaps back to where he stood. 
# As bindings execute in global scope, 
# the board array has to be global for the UI.

  proc drawBoard {gameID w args} {
    variable GameState
    array set opt {-width 300 -colors {bisque tan3} -side white -usefont 0}
    array set opt $args
    if {![winfo exists $w]} {
        canvas $w -width $opt(-width) -height $opt(-width)
        bind $w <Configure> "::Games::Chess::drawBoard $gameID $w $args"
        set GameState($gameID,usefont) $opt(-usefont)
        $w bind mv <1> [list ::Games::Chess::click1 $gameID $w %x %y]
        $w bind mv <B1-Motion> {
            %W move current [expr {%x-$::Games::Chess::x}] [expr {%y-$::Games::Chess::y}]
            set ::Games::Chess::x %x; set ::Games::Chess::y %y
        }
        $w bind mv <ButtonRelease-1> "::Games::Chess::release1 $gameID $w %x %y"
    } else {
        $w delete all
    }
    set GameState($gameID,side)   $opt(-side)
    set dim [min [winfo height $w] [winfo width $w]]
    if {$dim<2} {set dim $opt(-width)}
    set GameState($gameID,sqw) [set sqw [expr {($dim - 20) / 8}]]
    set x0 15
    set x $x0; set y 5; set colorIndex 0
    set rows {8 7 6 5 4 3 2 1}
    set cols {A B C D E F G H}
    if {$GameState($gameID,side) != "white"} {
        set rows [lrevert $rows]
        set cols [lrevert $cols]
    }
    foreach row $rows {
        $w create text 5 [expr {$y+$sqw/2}] -text $row
        foreach col $cols {
            $w create rect $x $y [incr x $sqw] [expr $y+$sqw] \
                -fill [lindex $opt(-colors) $colorIndex] \
                -tag [list square $col$row]
            set colorIndex [expr {1-$colorIndex}]
        }
        set x $x0; incr y $sqw
        set colorIndex [expr {1-$colorIndex}]
    }
    set x [expr {$x0 - $sqw/2}]
    incr y 8 ;# letters go below chess board
    foreach col $cols {$w create text [incr x $sqw] $y -text $col}
    drawSetup $gameID $w
    set w
  }

  proc click1 {gameID w cx cy} {
	variable GameState
    variable x $cx y $cy from
    $w raise current
    regexp {@(..)} [$w gettags current] -> from
    foreach move [validMoves $gameID $from] {
        foreach {- to victim} [split $move -] break
        set fill [$w itemcget $to -fill]
        if {$fill != "green" && $fill != "red"} {
            set newfill [expr {$victim==""? "green" : "red"}]
            $w itemconfig $to -fill $newfill
            after 1000 $w itemconfig $to -fill $fill
        }
    }
  }

  proc release1 {gameID w cx cy} {
	variable GameState
    variable from
    set to ""
    foreach i [$w find overlap $cx $cy $cx $cy] {
        set tags [$w gettags $i]
        if {[lsearch $tags square]>=0} {
            set to [lindex $tags end]
            break
        }
    }
    if [valid? $gameID $from-$to] {
        set victim [move $gameID $from-$to]
        if {[string tolower $victim]=="k"} {set GameState($gameID,info) Checkmate.}
        $w delete @$to
        set target $to
        $w dtag current @$from
        $w addtag @$to withtag current
    } else {set target $from} ;# go back on invalid move
    foreach {x0 y0 x1 y1}     [$w bbox $target] break
    foreach {xm0 ym0 xm1 ym1} [$w bbox current] break
    set dx [expr {($x0+ $x1-$xm0-$xm1)/2}]
    set dy [expr {($y0+$y1-$ym0-$ym1)/2}]
    $w move current $dx $dy
  }

  proc drawSetup {gameID w} {
	variable GameState
	variable Squares
    $w delete mv
    foreach square $Squares {
        drawMan $gameID $w $square $GameState($gameID,$square)
    }
  }

  proc drawMan {gameID w where what} {
	variable GameState
    if {$what=="."} return
    set fill [expr {[regexp {[A-Z]} $what]? "white": "black"}]
    if $GameState($gameID,usefont) {
        set unicode [string map {
            k \u265a q \u265b r \u265c b \u265d n \u265e p \u265f
          k K q Q r R b B n N p P
        } [string tolower $what]]
        set font [list Helvetica [expr {$GameState($gameID,sqw)/2}] bold]
        $w create text 0 0 -text $unicode -font $font \
            -tag [list mv @$where] -fill $fill
    } else {
        $w create poly [manPolygon $what] -fill $fill \
            -tag [list mv @$where] -outline gray
        set f [expr {$GameState($gameID,sqw)*0.035}]
        $w scale @$where 0 0 $f $f
    }
    foreach {x0 y0 x1 y1} [$w bbox $where] break
    $w move  @$where [expr {($x0+$x1)/2}] [expr {($y0+$y1)/2}]
  }

  proc manPolygon what {
    # very simple shapes of the chess men - feel free to improve!
    switch -- [string tolower $what] {
     b {list -10 8  -5 5  -9 0  -6 -6  0 -10  6 -6  9 0  5 5  10 8\
        6 10  0 6  -6 10}
     k {list -8 10  -10 1  -3 -1  -3 -3  -6 -3  -6 -7  -3 -7  -3 -10\
        3 -10  3 -7  6 -7  6 -3  3 -3  3 -1  10 1  8 10}
     n {list -8 10  -1 -1  -7 0  -10 -4  0 -10  6 -10  10 10}
     p {list -8 10  -8 7  -5 7  -2 -1  -4 -5  -2 -10  2 -10  4 -5 \
          2 -1  5 7  8 7  8 10}
     q {list -6 10  -10 -10  -3 0  0 -10  3 0  10 -10  6 10}
     r {list -10 10  -7 1  -10 0  -10 -10  -5 -10  -5 -6  -3 -6  -3 -10\
          3 -10  3 -6  5 -6  5 -10  10 -10 10 0  7 1  10 10}
    }
  }

  proc flipSides {gameID w} {
	variable GameState
    $w delete all
    set side [expr {$GameState($gameID,side)=="white"? "black": "white"}]
    drawBoard $gameID $w -side $side
  }

#------------------------------------- some general utilities:

  proc lrevert list {
    set res {}
    set i [llength $list]
    while {$i} {lappend res [lindex $list [incr i -1]]}
    set res
  }
  
  proc min args {lindex [lsort -real $args] 0}
  proc sgn x {expr {$x>0? 1: $x<0? -1: 0}}

}

