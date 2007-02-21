#############################################################################
#  ::Games => play games with aMSN.											#
#  ======================================================================== #
#   Play games with aMSN.													#
#																			#
#	Original author: JeeBee <jonne_z REM0VEatTH1S users.sourceforge.net>	#
#	Contributors:															#
#   - Thanks to Tjikkun for the many usefull tips about the protocol used	#
#     and for his time to discuss the plugin with me.						#
#   - Thanks to Scapor for testing with me, begin enthusiastic and having	#
#     such a long nickname I immediately knew I had to truncate this.		#
#   - Thanks to Billiob (and Tjikkun, who said just use 1500) for 			#
#	  determining the maximum packet size before the msn protocol fails		#
#	  (Billiob determined it to be slightly more than 1660). I use 1500		#
#	  to be on the safe side (and I'm not counting exact).					#
#	- Thanks to Mary for testing with me, Spanish translation, 				#
#	  and sharing ideas to improve this plugin.								#
#	- Thanks to Youness for a very impressive ten minutes of testing		#
#	  (Youness? You sure it was only 10 minutes???)							#
#	  in which he suggested to use x-clientcaps, advertising when opponent	#
#	  does not have the plugin and even tried playing with three players	#
#	  in which he addressed some *multi*-player issues.						#
#	- Thanks to Jeroen for drawing the Hangman images.						#
#############################################################################

# FIXME: Injecting code is not possible as I don't use eval/exec/file open etc on 
# incoming data. However, how can I verify that messages are not duplicated (whether 
# or not on purpose) or just that messages are sent that are valid but sended on 
# purpose by malicious opponents or intruders that by some reason know the $gameID? 
# E.g. it shouldn't be TOO easy to send a "PLAYER=me,SCORE=infinite" command.
# One way would be to implement a message counter that increments on both sides and
# must always be equal? Anyone reading this who thinks this is important?

# FIXME: In a conference, if 1 participant does not have the plugin loaded/installed,
# we do not get enough Pongs and do not send an invite. Should we set this to a minimum?
# Using x-clientcaps could solve this ...
#
#Youness: btw, JeeBee, how you know it's a user that supports it.. I (hoping the  
#even exists) propose you send a message at user JOIN just like the  
#x-clientcaps of type application/x-amsngames-init with games supportes,  
#version info, etc.. just so you know whether the user has it or not, and  
#which games /version he has... so you will always know (without need for  
#timeout) if user supports it..

# FIXME: Use version checking to avoid starting games that don't exist
# and other games-plugin incompatibilities.

namespace eval ::Games {
  # Where to obtain aMSN and the Games plugin?
  variable amsn_url  "http://amsn.sf.net"
  variable games_url "http://sf.net/tracker/index.php?func=detail&aid=1414743&group_id=54091&atid=733148"
  # games_url soon something like "http://amsn.sf.net/plugins.php#Games" or #games ?

  variable dir ""
  variable TwoPlayerGames {"Dots_and_Boxes" "Hangman" "Chess"}
  variable MultiPlayerGames {"Sketch"}
  variable version
  variable timeout_len 10000
  variable max_nick_len 30
  variable max_packet_size 1500

  array set CurrentGames {}
  array set OpenChallenges {} 
  # Game     - "$gameID,game"
  # GameInit - "$gameID,init"
  # Opponent - "$gameID,chatid"
  # Timeout  - "$gameID,timeout"

  ###########################################################################
  # ::Init (dir)  	                  										#
  # ----------------------------------------------------------------------- #
  # Registration & initialization of the plugin								#
  ###########################################################################
  proc Init { dir } {
    variable TwoPlayerGames
	variable MultiPlayerGames
    variable version

    set ::Games::dir $dir
	if {[catch {::plugins::pluginVersion} version]} {
	  # Setting version number manually for aMSN 0.95
	  # Make sure this value matches the one used in plugininfo.xml
	  set version "0.19"
	}

    ::plugins::RegisterPlugin "Games"

    # Register events
    ::plugins::RegisterEvent "Games" PacketReceived PacketReceived
    ::plugins::RegisterEvent "Games" chatmenu edit_menu

    # Load language files
    set langdir [file join $dir "lang"]
    set lang [::config::getGlobalKey language]
    load_lang en $langdir
    load_lang $lang $langdir

    # Source the games
    foreach game [concat $TwoPlayerGames $MultiPlayerGames] {
      if { [catch { source [file join $dir "$game.tcl"] } res] } {
        msg_box "[trans load_game_failed] ($game.tcl):\n$res"
        return 0
      }
    }

    # Handle plugin configuration
    ::Games::config_array
    ::Games::configlist_values

	log "Games plugin version $version loaded."
  }

  ###########################################################################
  # ::edit_menu																#
  # ----------------------------------------------------------------------- #
  # Edit chat window menu													#
  ###########################################################################
  proc edit_menu { event evpar } {
    upvar 2 $evpar newvar
    set window_name $newvar(window_name)
    set menu_name $newvar(menu_name)

    # Add games menu
    menu ${menu_name}.gmenu -tearoff 0
    menu ${menu_name}.gmenu.gmenu_two -tearoff 0
    menu ${menu_name}.gmenu.gmenu_multi -tearoff 0
    ${menu_name} add cascade -label "[trans Games]" -menu ${menu_name}.gmenu
    ${menu_name}.gmenu add cascade -label "[trans TwoPlayerGames]" -menu ${menu_name}.gmenu.gmenu_two
    ${menu_name}.gmenu add cascade -label "[trans MultiPlayerGames]" -menu ${menu_name}.gmenu.gmenu_multi
    # Add two-player games
    foreach game $::Games::TwoPlayerGames {
      ${menu_name}.gmenu.gmenu_two add command -label "[trans $game]" \
        -command "::Games::StartGame \[::ChatWindow::getCurrentTab $window_name\] $game p2"
    }
    # Add multi-player games
    foreach game $::Games::MultiPlayerGames {
      ${menu_name}.gmenu.gmenu_multi add command -label "[trans $game]" \
        -command "::Games::StartGame \[::ChatWindow::getCurrentTab $window_name\] $game pn"
    }
	# 0 or 1 disables TwoPlayerGames or MultiPlayerGames respectively
	#${menu_name}.gmenu entryconfigure 1 -state disabled
  }

  ###########################################################################
  # ::trans																	#
  # ----------------------------------------------------------------------- #
  # Because the individual games are not registered as plugins, they use	#
  # this namespace's language files and have to call proc trans via this	#
  # proc, so ::plugins::calledFrom knows it should use our language file.	#
  ###########################################################################
  proc trans { key args } {
	# eval trans $key $args -->> DON'T USE THIS !!!
	# (could be exploited by Tcl-code in a nickname!!!)
	eval [linsert $args 0 ::trans $key]
  }

  ###########################################################################
  # ::load_lang																#
  # ----------------------------------------------------------------------- #
  # Some games want to have their own dictionaries and abuse language files	#
  # to achieve this. This function provides an easy wrapper to load a		#
  # language file (the issue here is the same als proc trans, see above).	#
  ###########################################################################
  proc load_lang {langKey langDir} {
	::load_lang $langKey $langDir
  }

  ###########################################################################
  # ::StartGame																#
  # ----------------------------------------------------------------------- #
  # Start selected game														#
  ###########################################################################
  proc StartGame { windowtab game gametype } {
    variable OpenChallenges
	variable timeout_len

    set chatid [::ChatWindow::Name $windowtab]
    set gameID [GenerateGameID $chatid $gametype]
	set user_list [::MSN::usersInChat $chatid]

	if {[string first "p2" $gameID] == 0 && \
        [string first "::MSN::SB" $chatid] == -1} {
	  # Two-player game
	  set game_init [::Games::${game}::init_game $gameID \
		[::config::getKey login] $chatid]
	} elseif {[string first "pn" $gameID] == 0 && \
              [string first "::MSN::SB" $chatid] > -1} {
	  # Multi-player game
	  set game_init [::Games::${game}::init_game $gameID [::config::getKey login]]
	} else {
	  WrongGameType $chatid
	  set game_init ""
    }

    if {"$game_init" != ""} {
	  # Set timers for Ping message to timeout_len milliseconds
	  set timeouts {}
	  foreach user $user_list {
		lappend timeouts $user
		lappend timeouts [after $timeout_len [list ::Games::pongReceived $gameID $user 0]]
	  }

      # Add this Invite to OpenChallenges
      array set OpenChallenges [list \
        "$gameID,game"     "$game" \
		"$gameID,host"     "[config::getKey login]" \
        "$gameID,init"     "$game_init" \
        "$gameID,chatid"   "$chatid" \
        "$gameID,timeouts" "$timeouts" ]

	  # First thing to do is sent a Ping to see if your opponent has our
	  # Games plugin loaded as well.
	  send_via_queue $gameID "Ping"
    }
  }

  ###########################################################################
  # ::pongReceived	                  										#
  # ----------------------------------------------------------------------- #
  # Opponent also has this (or compatible) plugin loaded.					#
  # Do a version check, warn if version differs, then continue				#
  # by sending our invitation												#
  ###########################################################################
  proc pongReceived { gameID sender success {oppVersion ""} } {
    variable OpenChallenges

    if {[info exists OpenChallenges($gameID,chatid)] && \
        $OpenChallenges($gameID,host) == [config::getKey login]} {
	  if {$success} {
        # Turn off timer of sender
		set i 0
		foreach {user timer} $OpenChallenges($gameID,timeouts) {
		  if {"$user" == "$sender"} {
			after cancel $timer
			set OpenChallenges($gameID,timeouts) \
			  [lreplace $OpenChallenges($gameID,timeouts) $i [expr {$i+1}]]
			break
		  }
		  set i [expr {$i+2}]
		}
		# If all timeouts are gone, all Pongs are received correctly
		if {[llength $OpenChallenges($gameID,timeouts)] == 0} {
		  # Send the game invitation
		  send_via_queue $gameID "Invite" \
			"$OpenChallenges($gameID,game),$OpenChallenges($gameID,init)"
		  ::Games::InvitationSent $gameID
		}
		::Games::VersionConflict $gameID $sender $oppVersion
	  } else {
		# Timout occured, apparantly sender doesn't have plugin loaded
		::Games::PluginNotLoaded $gameID $sender $OpenChallenges($gameID,chatid)

		# Remove from OpenChallenges
        array unset OpenChallenges "$gameID,*"
	  }
    }
  }

  ###########################################################################
  # ::SendMove 		                  										#
  # ----------------------------------------------------------------------- #
  # Send move to opponent													#
  ###########################################################################
  proc SendMove { gameID move } {
    send_via_queue $gameID "Move" "$move"
  }

  ###########################################################################
  # ::SendQuit 		                  										#
  # ----------------------------------------------------------------------- #
  # Inform opponent that we quit our game									#
  ###########################################################################
  proc SendQuit { gameID } {
    send_via_queue $gameID "Quit"
  }

  ###########################################################################
  # ::DeInit (dir)                   										#
  # ----------------------------------------------------------------------- #
  # Plugin is unloaded														#
  ###########################################################################
  proc DeInit { } {
  }

  ###########################################################################
  # ::log message 		              										#
  # ----------------------------------------------------------------------- #
  # Add a log message to plugins-log window  								#
  # Type Alt-P to get that window            								#
  ###########################################################################
  proc log {message} {

    plugins_log Games $message
    #puts "log: $message"
  }

  ###########################################################################
  # ::config_array 	            											#
  # ----------------------------------------------------------------------- #
  # Add config array with default values 									#
  ###########################################################################
  proc config_array {} {
	variable TwoPlayerGames
	variable MultiPlayerGames

	array set ::Games::config {}
	foreach game [concat $TwoPlayerGames $MultiPlayerGames] {
	  set game_config [::Games::${game}::config_array]
	  foreach {key value} $game_config {
		set ::Games::config($key) $value
	  }
	}
  }

  ###########################################################################
  # ::configlist_values     		      									#
  # ----------------------------------------------------------------------- #
  # List of items for config window      									#
  ###########################################################################
  proc configlist_values {} {
	set ::Games::configlist \
	  [list [list frame ::Games::build_config_frame]]
  }

  # A tab for each individual game (that wants one)
  proc build_config_frame { w } {
	variable TwoPlayerGames
	variable MultiPlayerGames

    set nb [NoteBook $w.nb -side top]
	set p 0
	set raised ""
	foreach game [concat $TwoPlayerGames $MultiPlayerGames] {
      $nb insert $p w$game -text [trans $game]
	  set pane [$w.nb getframe w$game]
	  if { [::Games::${game}::build_config $pane] == 1 } {
	    incr p
	    if {"$raised" == ""} {
		  set raised w$game
	    }
	  } else {
		# Oops, game did not want configuration items, remove pane
		$nb delete w$game
	  }
	}

    pack $nb -fill both -expand 1 -in $w
    $nb raise $raised
  }

  ###########################################################################
  # ::PacketReceived	     		      									#
  # ----------------------------------------------------------------------- #
  # Process incoming amsn-games packets    									#
  ###########################################################################
  proc PacketReceived { event evpar } {
    variable OpenChallenges
    variable CurrentGames

    upvar 2 $evpar args
    upvar 2 $args(chatid) chatid
    upvar 2 $args(msg) packet
	# Find out who sended the message
	if {[info exists evpar(typer)]} {
	  upvar 2 $args(typer) typer 
	} else { 
	  upvar 2 typer typer 
	}

    # Check for the correct Content-type
    set header "[$packet getHeader Content-Type]"
    if {[string first "text/x-amsngames" $header] == -1} {
      return
    }

	set oppVersion "[$packet getHeader VERSION]"
    set gameID     "[$packet getHeader GAMEID]"
    set msgType    "[encoding convertfrom utf-8 [$packet getHeader MSGTYPE]]"
    set msgBody    "[encoding convertfrom utf-8 [$packet getBody]]"

	#log "Game command $msgType -> $msgBody"

	if {[regexp {[a-zA-Z0-9 _,=@\.]*} $msgBody]} {
      # Incoming message matches regular expression, continue processing

	  # FIXME: add a Withdraw message? But what do we do then in case
	  # our opponent accepts our challenge while the Withdraw message is
	  # under way? Idea: send a Withdraw message to remove the pending
	  # Invite and a Quit message right after that?
      
      # FIXME: Unsupported msg not yet supported

      switch -exact $msgType {
		"Ping" {
		  # Ping()
		  # If a ping is received, send a pong back to inform opponent that we
		  # indeed have this (or compatible) plugin loaded

		  array set OpenChallenges [list \
			"$gameID,chatid"	$chatid \
			"$gameID,host"		$typer ]

		  send_via_queue $gameID "Pong"
		}
		"Pong" {
		  # Pong()
		  # Opponent sent a Pong, he has our (or compatible) plugin loaded.
		  pongReceived $gameID $typer 1 $oppVersion
		}
        "Invite" {
          # Invite(Game,GameInit)
          set idx [string first "," $msgBody]
          if { $idx == -1 } { return }
          set game [string range $msgBody 0 [expr {$idx-1}]]
          set game_init [string range $msgBody [expr {$idx+1}] end]

		  # Add this Invite to OpenChallenges
		  array set OpenChallenges [list \
			"$gameID,game"   "$game" \
			"$gameID,init"   "$game_init" \
			"$gameID,chatid" "$chatid" \
			"$gameID,host"   "$typer" ]

          AcceptOrRefuse $gameID $oppVersion
        }
        "Accept" {
          # Accept(Game,GameInit)
          set idx [string first "," $msgBody]
          if { $idx == -1 } { return }
          set game [string range $msgBody 0 [expr {$idx-1}]]
          set game_init [string range $msgBody [expr {$idx+1}] end]
          ::Games::InvitationResponse $gameID $typer 1 $game_init
        }
        "Decline" {
          # Decline(Game,GameInit)
          ::Games::InvitationResponse $gameID $typer 0
        }
        "Move" {
          # Move(TheMove)
          if {[info exists CurrentGames($gameID,chatid)]} {
			set game $CurrentGames($gameID,game)
			::Games::${game}::opponent_moves $gameID $typer $msgBody
          } else {
            log "Move $msgBody received for a non-existing game $gameID"
          }
        }
        "Quit" {
          # Quit()
          if {[info exists CurrentGames($gameID,chatid)]} {
			set game $CurrentGames($gameID,game)
			::Games::${game}::opponent_quits $gameID $typer
          } else {
            log "Quit message received for a non-existing game $gameID"
          }
        }
        default {
          log "Unknown command: $msgType"
        }
      }
    } else {
	  log "Message body does not match our regular expression: $msgBody"
	} 
  }

  proc InvitationSent { gameID } {
	variable OpenChallenges
	variable version

    if {![info exists OpenChallenges($gameID,chatid)]} {
      log "InvitationSent called with unknown gameID $gameID"
    } else {
	  set chatid    $OpenChallenges($gameID,chatid)
	  set game      $OpenChallenges($gameID,game)
	  set game_init $OpenChallenges($gameID,init)

	  ::amsn::WinWrite $chatid "\n" green
	  ::amsn::WinWriteIcon $chatid greyline 3
	  ::amsn::WinWrite $chatid "\n" green
	  ::amsn::WinWriteIcon $chatid butinvite 3 2
	  ::amsn::WinWrite $chatid "[timestamp] [trans invite_sent] " green
	  ::amsn::WinWrite $chatid "[trans $game] " red
	  ::amsn::WinWrite $chatid "(${game_init})\n" green
	  ::amsn::WinWriteIcon $chatid greyline 3
    }
  }

  proc VersionConflict { gameID opponent oppVersion } {
	variable OpenChallenges
	variable version

    if {![info exists OpenChallenges($gameID,chatid)]} {
      log "VersionConflict called with unknown gameID $gameID"
    } else {
	  set chatid    $OpenChallenges($gameID,chatid)

	  if {$version != $oppVersion} {
		::amsn::WinWrite $chatid \
		  "[trans incompatible_version $version $opponent $oppVersion]\n" red
	  }
	}
  }

  proc WrongGameType {chatid} {
	::amsn::WinWrite $chatid "\n[trans wrong_game_type]\n" red
  }

  # Accept or Decline message received
  proc InvitationResponse { gameID sender response { game_init "" } } {
	variable OpenChallenges
    variable CurrentGames

    if {![info exists OpenChallenges($gameID,chatid)]} {
      log "InvitationResponse called with unknown gameID $gameID"
    } else {
	  set chatid    $OpenChallenges($gameID,chatid)
	  set game      $OpenChallenges($gameID,game)
	  set started   [info exists CurrentGames($gameID,chatid)]

	  ::amsn::WinWrite $chatid "\n" green
	  ::amsn::WinWriteIcon $chatid greyline 3
	  ::amsn::WinWrite $chatid "\n" green
	  ::amsn::WinWriteIcon $chatid butinvite 3 2
	  if {$response == 1} {
		# chatid accepted the invitation
		::amsn::WinWrite $chatid "[timestamp] [trans accepted_invitation [getNick $sender]] " green
		::amsn::WinWrite $chatid "[trans $game] " red
		::amsn::WinWrite $chatid "(${game_init})\n" green
		if {$OpenChallenges($gameID,host) == [::config::getKey login]} {

		  # Add game to CurrentGames
		  array set CurrentGames [list \
			"$gameID,game"   "$game" \
			"$gameID,init"   "$game_init" \
			"$gameID,chatid" "$chatid" ]

		  if {[string first "p2" $gameID] == 0} {
			# Two-player game
			array unset OpenChallenges "$gameID,*"
			# Process opponent's init string
			::Games::${game}::set_init_game $gameID $game_init \
			  [::config::getKey login] $chatid 
			::Games::${game}::start_game $gameID
		  } elseif {!$started} {
			# Multi-player game (this is our first Accept)
			::Games::${game}::start_game $gameID
			::Games::${game}::add_player $gameID [::config::getKey login]
			::Games::${game}::add_player $gameID $sender
		  } else {
			# Multi-player game (already started)
			::Games::${game}::add_player $gameID $sender
		  }
		} else {
		  # We are not the host of the game
		  if {[string first "pn" $gameID] == 0} {
			::Games::${game}::add_player $gameID $sender
		  }
		}
	  } else {
		# chatid declined the invitation
		::amsn::WinWrite $chatid "[timestamp] [trans declined_invitation [getNick $sender]] " green
		::amsn::WinWrite $chatid "[trans $game] " red
		::amsn::WinWrite $chatid "($OpenChallenges($gameID,init))\n" green
	  }
	  ::amsn::WinWriteIcon $chatid greyline 3
    }
  }

  proc AcceptOrRefuse { gameID oppVersion } {
	variable OpenChallenges

    if {![info exists OpenChallenges($gameID,chatid)]} {
      log "AcceptOrRefuse called with unknown gameID $gameID"
    } else {
	  set chatid    $OpenChallenges($gameID,chatid)
	  set host      $OpenChallenges($gameID,host)
	  set game      $OpenChallenges($gameID,game)
	  set game_init $OpenChallenges($gameID,init)

	  # Check whether we have our conversation window open for WinWrites
	  set win_name [::ChatWindow::For $chatid]
	  if { [::ChatWindow::For $chatid] == 0 || ![winfo exists $win_name]} {
		set win_name [::ChatWindow::MakeFor $chatid]
	  }

	  ::MSN::ChatQueue $chatid \
		[list ::Games::AcceptOrRefuse_wrapped $gameID $chatid $host $game $game_init $oppVersion]
    }
  }

  proc AcceptOrRefuse_wrapped { gameID chatid host game game_init oppVersion } {
    variable version

    # Grey line
    ::amsn::WinWrite $chatid "\n" green
    ::amsn::WinWriteIcon $chatid greyline 3
    ::amsn::WinWrite $chatid "\n" green

    ::amsn::WinWriteIcon $chatid butinvite 3 2
    # Show invitation
    ::amsn::WinWrite $chatid "[trans wants_to_play [getNick $host]] " green
    ::amsn::WinWrite $chatid "[trans $game] " red
    ::amsn::WinWrite $chatid "(${game_init})" green

    # Accept and refuse actions
    ::amsn::WinWrite $chatid " - (" green
    ::amsn::WinWriteClickable $chatid "[trans Accept]" \
      [list ::Games::InvitationAnswered $gameID $host 1] \
      "acceptgame$gameID"
    ::amsn::WinWrite $chatid " / " green
    ::amsn::WinWriteClickable $chatid "[trans Reject]" \
      [list ::Games::InvitationAnswered $gameID $host 0] \
      "rejectgame$gameID"
    ::amsn::WinWrite $chatid ")\n" green

    # Grey line
    ::amsn::WinWriteIcon $chatid greyline 3

	if {$version != $oppVersion} {
	  ::amsn::WinWrite $chatid \
		"\n[trans incompatible_version $version $host $oppVersion]\n" red
	}
  }

  proc PluginNotLoaded { gameID sender chatid } {
	variable timeout_len
	variable amsn_url
	variable games_url

    # Grey line
    ::amsn::WinWrite $chatid "\n" green
    ::amsn::WinWriteIcon $chatid greyline 3
    ::amsn::WinWrite $chatid "\n" green

    ::amsn::WinWriteIcon $chatid butinvite 3 2
    # Show invitation
    ::amsn::WinWrite $chatid "[trans missing_plugin [getNick $sender]] " green
    ::amsn::WinWrite $chatid "([trans timeout [expr {$timeout_len/1000}]])." green

    # Grey line
    ::amsn::WinWriteIcon $chatid greyline 3

	# Send aMSN/Games plugin advertisement
	::MSN::messageTo $chatid \
      "[trans advertise [getNick [::config::getKey login]] [getNick $sender] $amsn_url $games_url]" 0 ""
  }

  proc InvitationAnswered { gameID host answer } {
	variable OpenChallenges
    variable CurrentGames

    if {![info exists OpenChallenges($gameID,chatid)]} {
      log "InvitationAnswered called with unknown gameID $gameID"
    } else {
	  set chatid    $OpenChallenges($gameID,chatid)
	  set game      $OpenChallenges($gameID,game)
	  set game_init $OpenChallenges($gameID,init)

	  # Get the chatwindow name
	  set win_name [::ChatWindow::For $chatid]
	  if { [::ChatWindow::For $chatid] == 0} {
		return 0
	  }

	  # Disable items in the chatwindow
	  [::ChatWindow::GetOutText ${win_name}] tag configure "acceptgame$gameID" \
		-foreground #808080 -font bplainf -underline false
	  [::ChatWindow::GetOutText ${win_name}] tag bind "acceptgame$gameID" <Enter> ""
	  [::ChatWindow::GetOutText ${win_name}] tag bind "acceptgame$gameID" <Leave> ""
	  [::ChatWindow::GetOutText ${win_name}] tag bind "acceptgame$gameID" <Button1-ButtonRelease> ""

	  [::ChatWindow::GetOutText ${win_name}] tag configure "rejectgame$gameID" \
		-foreground #808080 -font bplainf -underline false
	  [::ChatWindow::GetOutText ${win_name}] tag bind "rejectgame$gameID" <Enter> ""
	  [::ChatWindow::GetOutText ${win_name}] tag bind "rejectgame$gameID" <Leave> ""
	  [::ChatWindow::GetOutText ${win_name}] tag bind "rejectgame$gameID" <Button1-ButtonRelease> ""

	  [::ChatWindow::GetOutText ${win_name}] conf -cursor left_ptr

	  if {$answer == 1} {
        # Add game to CurrentGames
		array set CurrentGames [list \
		  "$gameID,game"   "$game" \
		  "$gameID,host"   "$host" \
		  "$gameID,init"   "$game_init" \
		  "$gameID,chatid" "$chatid" ]
		if {[string first "p2" $gameID] == 0} {
          # Remove from OpenChallenges
          array unset OpenChallenges "$gameID,*"
	  	  # Two-player game
		  set game_init [::Games::${game}::set_init_game \
			$gameID $game_init [::config::getKey login] $chatid]
		} else {
		  # Multi-player game
		  ::Games::${game}::set_init_game $gameID $host $game_init
		  ::Games::${game}::add_player $gameID [::config::getKey login]
		  ::Games::${game}::add_player $gameID $host
		}
		# Invitation accepted
		send_via_queue $gameID "Accept" "${game},${game_init}"
		::Games::${game}::start_game $gameID
	  } else {
		# Invitation rejected
		send_via_queue $gameID "Decline" "${game},${game_init}"
      }
    }
  }

  proc getNick { chatid } {
    variable max_nick_len

	if {$chatid == [::config::getKey login]} {
	  set nick [::abook::getPersonal MFN]
	} else {
	  set nick [::abook::getDisplayNick $chatid]
	}
	
	# Now truncate nick so it is no longer than max_nick_len
	if {[expr {[string length $nick] > $max_nick_len}]} {
	  set nick [string range $nick 0 [expr {$max_nick_len - 3}]]
	  set nick "$nick..."
	}

	return $nick
  }

  ###########################################################################
  # ::send_via_queue	     		      									#
  # ----------------------------------------------------------------------- #
  # Send a message to the opponent	      									#
  ###########################################################################
  proc send_via_queue { gameID msgType {msgBody ""} } {
    variable OpenChallenges
    variable CurrentGames

    if {[info exists CurrentGames($gameID,chatid)]} {
      set chatid $CurrentGames($gameID,chatid)
    } elseif {[info exists OpenChallenges($gameID,chatid)]} {
      set chatid $OpenChallenges($gameID,chatid)
    } else {
      log "send_via_queue called with non-existing gameID $gameID"
    }

    ::MSN::ChatQueue $chatid \
      [list ::Games::send_packet $chatid $gameID $msgType $msgBody]
  }

  ###########################################################################
  # ::send_packet		     		      									#
  # ----------------------------------------------------------------------- #
  # Here we send a packet to our opponent(s). Also, we make sure here that	#
  # packets do not exceed the maximum length. For some types of messages	#
  # we split the message to multiple messages.								#
  ###########################################################################
  proc send_packet { chatid gameID msgType msgBody } {
	variable version
	variable max_packet_size
    set sbn [::MSN::SBFor $chatid]

	set done 0
	set msg ""

	while {!$done} {

	  if {[string length $msgBody] < $max_packet_size} {
		set done 1
		set msg $msgBody
	  } else {
		# Try to split the packet up in smaller ones
		set coords_idx [string last "COORDS=" $msgBody]
		if {$coords_idx > -1} {
		  # Rest of this message is space separated x y coordinates
		  set msg [string range $msgBody 0 [expr {$coords_idx + 6}]]
		  set coords [string range $msgBody [expr {$coords_idx + 7}] end]
		  set msgBody $msg
		  set state 0
		  foreach {x y} $coords {
			if {$state == 0 && [string length $msg] < $max_packet_size} {
			  # We can still send more
			  set msg "${msg}${x} ${y} "
			  set last_x $x ; set last_y $y
			} else {
			  # To be send later
			  if {$state == 0} {
				set state 1
				# Duplicate last coordinate
				set msgBody "${msgBody}${last_x} ${last_y} "
			  }
			  set msgBody "${msgBody}${x} ${y} "
			}
		  }
		} else {
		  log "Packet (size [string length $msgBody]) to large to send and I do not know \
               how to split it up, packet type is $msgType."
		  return
		}
	  }

	  set packet "MIME-Version: 1.0\r\n"
	  set packet "${packet}Content-Type: text/x-amsngames; charset=utf-8\r\n"
	  set packet "${packet}VERSION: $version\r\n"
	  set packet "${packet}GAMEID: $gameID\r\n"
	  set packet "${packet}MSGTYPE: [encoding convertto utf-8 $msgType]\r\n\r\n"
	  set packet "${packet}[encoding convertto utf-8 $msg]"
	  set packet_len [string length $packet]

	  ::MSN::WriteSBNoNL $sbn "MSG" "U $packet_len\r\n$packet"
	  #log "Sending (size $packet_len): $packet"
	}
  }

  ###########################################################################
  # ::GenerateGameID	     		      									#
  # ----------------------------------------------------------------------- #
  # Generate a world-wide unique gameID										#
  ###########################################################################
  proc GenerateGameID { chatid gametype } {
    # FIXME: I'm afraid this is tcl 8.4 specific
    set gameID "$gametype$chatid[clock clicks -milliseconds]"
    return $gameID
  }

  proc myRand {min max} {
    return [expr {int($min + rand() * (1+$max-$min))}]
  }

  # Here's my resize-less version of aMSN's moveinscreen.
  # I need this because the original version's resizing seems to
  # interfere with "pack forget" and repack statements I want to use.
  proc moveinscreen {window {mindist 0}} {
	update
	# Check whether window exists
	if {![winfo exists $window]} {
	  return
	}
	set winx [winfo width $window]
	set winy [winfo height $window]
	set scrx [winfo screenwidth .]
	set scry [winfo screenheight .]
	set winpx [winfo x $window]
	set winpy [winfo y $window]

	# Check if the window is too large to fit on the screen
	if { [expr {$winx > ($scrx-(2*$mindist))}] } {
	  set winx [expr {$scrx-(2*$mindist)}]
	}
	if { [expr {$winy > ($scry-(2*$mindist))}] } {
	  set winy [expr {$scry-(2*$mindist)}]
	}

	# Check if the window is positioned off the screen
	if { [expr {$winpx + $winx > ($scrx-$mindist)}] } {
	  set winpx [expr {$scrx-$mindist-$winx}]
	}
	if { [expr {$winpx < $mindist}] } {
	  set winpx $mindist
	}
	if { [expr {$winpy + $winy > ($scry-$mindist)}] } {
	  set winpy [expr {$scry-$mindist-$winy}]
	}
	if { [expr {$winpy < $mindist}] } {
	  set winpy $mindist
	}

	wm geometry $window "+${winpx}+${winpy}"
  }
}
