#########################################################
#             FPSstats PLUGIN NAMESPACE                 #
# ----------------------------------------------------  #
# Maintainer: Boris FAURE (billiob) (billiob@gmail.com) #
# Created: 12/02/2005                                   #
#########################################################
# TODO :
#  -  do not use files to parse the informations
#DONE add the translation
#DONE add the auto-message feature
#  -  use the xml parser (should use sxml)
#DONE support many configs
#DONE add an icon in the contact list to behave like the custom states


namespace eval ::FPSstats {
	
	#############################################
	# ::FPSstats::Init                          #
	# ----------------------------------------- #
	# Initialization Procedure                  #
	# (Called by the Plugins System)            #
	#############################################
	proc Init { dir } {

		variable num
		set num 0


		::plugins::RegisterPlugin FPSstats

		#Load lang files
		set langdir $dir\/lang
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir
		
		::skin::setPixmap not_playing_pic_FPSstats not_playing.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap playing_pic_FPSstats playing.gif pixmaps [file join $dir pixmaps]

		set ::FPSstats::config(dir) $dir
		
		#create new vars only if needed
		if {![info exists ::FPSstats::config(qstat)]} {
			#array of variables which can be configured using the "plugin center"
			array set ::FPSstats::config {
				num -1
				max_num -1
				previous_status NLN
				latest_num 0
			}
			
			::FPSstats::AddConfig 0
			
			global tcl_platform
			if {[string tolower $tcl_platform(os)] == "linux"} {
				#linux
				set ::FPSstats::config(qstat) "/usr/bin/qstat"
			} elseif {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
				#MacOSX
				set ::FPSstats::config(qstat) "/usr/local/bin/qstat"
				} else {
				#Windows
				set ::FPSstats::config(qstat) "C:/Program Files/qstat/qstat.exe"
			}
		}
		set ::FPSstats::configlist [list [list frame ::FPSstats::populateFrame ""] ]
			
		#needed for the checkstate
		set endloopnick {1}
		::plugins::RegisterEvent FPSstats PluginConfigured FinishSavingConfig 
		::plugins::RegisterEvent FPSstats ContactListColourBarDrawn AddIconMenu
	}

	proc populateFrame { win } {
		variable num
		variable f

		#Path To Qstat
		frame $win.qstat -class Degt
		pack $win.qstat -anchor w
		label $win.qstat.label -text "[trans qstat]" -padx 5 -font sboldf
		entry $win.qstat.path -bg #FFFFFF -width 50 -textvariable ::FPSstats::config(qstat)
		button $win.qstat.browse -text [trans browse] -command "Browse_Dialog_file ::FPSstats::config(qstat)" 
		set qstat_checked [::FPSstats::checkQstat]
		if { $qstat_checked } {
			label $win.qstat.checklabel -text "[trans qstat_ok]" -font splainf -fg black -wraplength 400
		} else {
			label $win.qstat.checklabel -text "[trans qstat_error]" -font sboldf -fg red -wraplength 400
		}
		button $win.qstat.checkbutton -text "[trans check]" -command "::FPSstats::checkQstat $win" 
		grid $win.qstat.label -row 1 -column 1 -sticky w
		grid $win.qstat.path -row 2 -column 1 -sticky w
		grid $win.qstat.browse -row 2 -column 2 -sticky w
		grid $win.qstat.checkbutton -row 3 -column 1 -sticky w
		grid $win.qstat.checklabel -row 4 -column 1 -sticky w
		
		set values [list 0]
		for {set i 1} {$i<=$::FPSstats::config(max_num)} {incr i} {
			lappend values $i
		}
		status_log "values:=$values" blue
		ComboBox $win.num -editable false -highlightthickness 0 -width 5 -font splainf \
			-textvariable num -values $values \
			-modifycmd "::FPSstats::SwitchConfig $win"
		pack $win.num -anchor w -expand true -fill both
	

		#buttons_bar
		frame $win.top -class Degt
		pack $win.top -anchor w
		button $win.top.add -text "[trans addconfig]" -command "::FPSstats::AddConfig $win" 
		button $win.top.remove -text "[trans removeconfig]" -command "::FPSstats::RemoveConfig $win" 
		grid $win.top.add -row 1 -column 1 -sticky w		
		grid $win.top.remove -row 1 -column 2 -sticky w

		#frame around selections
		#set f [frame $win.c -bd 2 -bg black]
		framec $win.c -bc #678DB2
		set f [$win.c getinnerframe]
		pack $win.c -anchor n -padx 5

		#configname
		frame $f.statename
		pack $f.statename -anchor w
		label $f.statename.label -text "[trans configname]"
		entry $f.statename.entry -textvariable ::FPSstats::config(configname_$num) -bg white -width 50
		grid $f.statename.label -row 1 -column 1 -sticky w
		grid $f.statename.entry -row 2 -column 1 -sticky w

		#activepsm
		checkbutton $f.activepsm -text "[trans activepsm]" -variable ::FPSstats::config(activepsm_$num)
		pack $f.activepsm -anchor w
		#psm
		frame $f.psm
		pack $f.psm -anchor w
		label $f.psm.label -text "[trans psm]"
		entry $f.psm.entry -textvariable ::FPSstats::config(nickname_$num) -bg white -width 50 
		menubutton $f.psm.menubutton -font sboldf -text "<-" -menu $f.psm.menubutton.menu
		menu $f.psm.menubutton.menu -tearoff 0
			$f.psm.menubutton.menu add command -label [trans servername] -command "$f.psm.entry insert insert \\\$servername"
			$f.psm.menubutton.menu add command -label [trans ip_address] -command "$f.psm.entry insert insert \\\$ip"
			$f.psm.menubutton.menu add command -label [trans map] -command "$f.psm.entry insert insert \\\$map"
			$f.psm.menubutton.menu add command -label [trans score] -command "$f.psm.entry insert insert \\\$score"
			$f.psm.menubutton.menu add command -label [trans ping] -command "$f.psm.entry insert insert \\\$ping"
			$f.psm.menubutton.menu add command -label [trans numplayers] -command "$f.psm.entry insert insert \\\$numplayers"
			$f.psm.menubutton.menu add command -label [trans free] -command "$f.psm.entry insert insert \\\$free"
			$f.psm.menubutton.menu add command -label [trans maxplayers] -command "$f.psm.entry insert insert \\\$maxplayers"
			$f.psm.menubutton.menu add command -label [trans friendlyfire] -command "$f.psm.entry insert insert \\\$friendlyfire"
			$f.psm.menubutton.menu add command -label [trans team] -command "$f.psm.entry insert insert \\\$team"
			$f.psm.menubutton.menu add command -label [trans gamenick] -command "$f.psm.entry insert insert \\\$gamenick"
		pack $f.psm.label -anchor w -side top
		pack $f.psm.entry \
			$f.psm.menubutton \
			-anchor w -side left

		#activeautomessage
		checkbutton $f.activeautomessage -text "[trans activeautomessage]" -variable ::FPSstats::config(activeautomessage_$num)
		pack $f.activeautomessage -anchor w
		#automessage
		frame $f.automessage
		pack $f.automessage -anchor w
		label $f.automessage.label -text "[trans automessage]"
		text $f.automessage.text -bg white -width 50 -height 5
		$f.automessage.text delete 0.0 end
		$f.automessage.text insert end "$::FPSstats::config(automessage_$num)"
		menubutton $f.automessage.menubutton -font sboldf -text "<-" -menu $f.automessage.menubutton.menu
		menu $f.automessage.menubutton.menu -tearoff 0
			$f.automessage.menubutton.menu add command -label [trans servername] -command "$f.automessage.text insert insert \\\$servername"
			$f.automessage.menubutton.menu add command -label [trans ip_address] -command "$f.automessage.text insert insert \\\$ip"
			$f.automessage.menubutton.menu add command -label [trans map] -command "$f.automessage.text insert insert \\\$map"
			$f.automessage.menubutton.menu add command -label [trans score] -command "$f.automessage.text insert insert \\\$score"
			$f.automessage.menubutton.menu add command -label [trans ping] -command "$f.automessage.text insert insert \\\$ping"
			$f.automessage.menubutton.menu add command -label [trans numplayers] -command "$f.automessage.text insert insert \\\$numplayers"
			$f.automessage.menubutton.menu add command -label [trans free] -command "$f.automessage.text insert insert \\\$free"
			$f.automessage.menubutton.menu add command -label [trans maxplayers] -command "$f.automessage.text insert insert \\\$maxplayers"
			$f.automessage.menubutton.menu add command -label [trans friendlyfire] -command "$f.automessage.text insert insert \\\$friendlyfire"
			$f.automessage.menubutton.menu add command -label [trans team] -command "$f.automessage.text insert insert \\\$team"
			$f.automessage.menubutton.menu add command -label [trans gamenick] -command "$f.automessage.text insert insert \\\$gamenick"
		pack $f.automessage.label -anchor w -side top
		pack $f.automessage.text \
			$f.automessage.menubutton \
			-anchor w -side left

		#second
		frame $f.second
		pack $f.second -anchor w
		label $f.second.label -text "[trans second]"
		entry $f.second.entry -textvariable ::FPSstats::config(second_$num) -bg white -width 10
		grid $f.second.label -row 1 -column 1 -sticky w
		grid $f.second.entry -row 2 -column 1 -sticky w

		#game
		frame $f.game
		pack $f.game -anchor w
		label $f.game.label -text "[trans game]"
		set values []
		if { $qstat_checked } {
			set values [listGames]
		} 
		ComboBox $f.game.list -editable true -highlightthickness 0 -width 50 -font splainf\
				-textvariable $::FPSstats::config(game_$num) -values $values \
				-modifycmd "::FPSstats::checkGame $f.game.list"
		grid $f.game.label -row 1 -column 1 -sticky w
		grid $f.game.list -row 2 -column 1 -sticky w
		
		#CDKEY
		frame $f.cdkey
		pack $f.cdkey -anchor w
		label $f.cdkey.label -text "[trans cdkey]"
		entry $f.cdkey.entry -textvariable ::FPSstats::config(cdkey_$num) -bg white -width 50
		grid $f.cdkey.label -row 1 -column 1 -sticky w
		grid $f.cdkey.entry -row 2 -column 1 -sticky w

		#IP
		frame $f.ip
		pack $f.ip -anchor w
		label $f.ip.label -text "[trans ip_address]"
		entry $f.ip.entry -textvariable ::FPSstats::config(ip_$num) -bg white -width 50
		grid $f.ip.label -row 1 -column 1 -sticky w
		grid $f.ip.entry -row 2 -column 1 -sticky w

		#gamenick
		frame $f.gamenick
		pack $f.gamenick -anchor w
		label $f.gamenick.label -text "[trans gamenick]"
		entry $f.gamenick.entry -textvariable ::FPSstats::config(gamenick_$num) -bg white -width 50
		grid $f.gamenick.label -row 1 -column 1 -sticky w
		grid $f.gamenick.entry -row 2 -column 1 -sticky w


		#Chosen_state
		frame $f.chosen_state
		pack $f.chosen_state -anchor w
		label $f.chosen_state.label -text "[trans choose_state]"
		set liste [list]
		for {set i 1} {$i <= "6"} {incr i} {
			lappend liste "[trans [::MSN::stateToDescription [::MSN::numberToState $i]]]"
		}
		ComboBox $f.chosen_state.list -editable true -highlightthickness 0 -width 50 -font splainf\
			-textvariable ::FPSstats::config(chosen_state_$num) -values $liste \
			-modifycmd "::FPSstats::fillState"
		grid $f.chosen_state.label -row 1 -column 1 -sticky w
		grid $f.chosen_state.list -row 2 -column 1 -sticky w

		#help
		set lang [::config::getGlobalKey language]
		if {[file exists [file join $::FPSstats::config(dir) readme_${lang} ]]} {
			button $win.help -text "[trans help]" -command "::FPSstats::ShowFile [file join $::FPSstats::config(dir) readme_${lang} ] Readme" 
		} else {
			button $win.help -text "[trans help]" -command "::FPSstats::ShowFile [file join $::FPSstats::config(dir) readme ] Readme" 
		}
		pack $win.help -anchor w
	
		#Ugly :
		#to get, really the "0" config
		SwitchConfig $win 0	

	}

	#widget = 0 if there's no widget
	proc AddConfig {widget} {
		variable num
		
		incr ::FPSstats::config(max_num)
		set num $::FPSstats::config(max_num)
		
		set ::FPSstats::config(activepsm_$num) {1}
		set ::FPSstats::config(activeautomessage_$num) {1}
		set ::FPSstats::config(psm_$num) {Playing on map: $map score: $score team : $team}
		set ::FPSstats::config(automessage_$num) {This an auto-message to tell you i'm playing on $servername which IP address is $ip. Currently, we are on $map, my score is $score and i'm with the team $team. There are $free free places on the server.}
		set ::FPSstats::config(second_$num) {35}
		set ::FPSstats::config(game_$num) {}
		set ::FPSstats::config(cdkey_$num) {}
		set ::FPSstats::config(gameArg_$num) {}
		set ::FPSstats::config(ip_$num) {127.0.0.1:27960}
		set ::FPSstats::config(gamenick_$num) {Player}
		set ::FPSstats::config(configname_$num) "FPSstats_$num"
		set ::FPSstats::config(chosen_state_$num) [trans busy]
		set ::FPSstats::config(statecode_$num) BSY
		
		if {$widget != 0} {
			set values [list 0]
			for {set i 1} {$i<=$::FPSstats::config(max_num)} {incr i} {
				lappend values $i
			}
			$widget.num configure -values $values
			SwitchConfig $widget $num
		}
		
	}


	proc RemoveConfig {widget} {
		variable num
		if {$::FPSstats::config(max_num) == 0} {
			return
		}
		set values [list 0]
		for {set i 1} {$i<$::FPSstats::config(max_num)} {incr i} {
			lappend values $i
		}
		$widget.num configure -values $values

		for {set i $num} {$i<$::FPSstats::config(max_num)} {incr i} {
			CopyConfig [expr {$i + 1 }] $i
		}
		unset ::FPSstats::config(activepsm_$::FPSstats::config(max_num))
		unset ::FPSstats::config(activeautomessage_$::FPSstats::config(max_num))
		unset ::FPSstats::config(psm_$::FPSstats::config(max_num))
		unset ::FPSstats::config(automessage_$::FPSstats::config(max_num))
		unset ::FPSstats::config(second_$::FPSstats::config(max_num))
		unset ::FPSstats::config(game_$::FPSstats::config(max_num))
		unset ::FPSstats::config(cdkey_$::FPSstats::config(max_num))
		unset ::FPSstats::config(gameArg_$::FPSstats::config(max_num))
		unset ::FPSstats::config(ip_$::FPSstats::config(max_num))
		unset ::FPSstats::config(gamenick_$::FPSstats::config(max_num))
		unset ::FPSstats::config(configname_$::FPSstats::config(max_num))
		unset ::FPSstats::config(chosen_state_$::FPSstats::config(max_num))
		unset ::FPSstats::config(statecode_$::FPSstats::config(max_num))
		if {[info exists ::FPSstats::config(plays_TCE_$::FPSstats::config(max_num))]} {
			unset ::FPSstats::config(plays_TCE_$::FPSstats::config(max_num))
		}
		incr ::FPSstats::config(max_num) -1
		SwitchConfig $widget [expr {$num - 1 }]
	}


	proc CopyConfig {origin arrival} {

		set ::FPSstats::config(activepsm_$arrival) $::FPSstats::config(activepsm_$origin)
		set ::FPSstats::config(activeautomessage_$arrival) $::FPSstats::config(activeautomessage_$origin)
		set ::FPSstats::config(psm_$arrival) $::FPSstats::config(psm_$origin)
		set ::FPSstats::config(automessage_$arrival) $::FPSstats::config(automessage_$origin)
		set ::FPSstats::config(second_$arrival) $::FPSstats::config(second_$origin)
		set ::FPSstats::config(game_$arrival) $::FPSstats::config(game_$origin)
		set ::FPSstats::config(cdkey_$arrival) $::FPSstats::config(cdkey_$origin)
		set ::FPSstats::config(gameArg_$arrival) $::FPSstats::config(gameArg_$origin)
		set ::FPSstats::config(ip_$arrival) $::FPSstats::config(ip_$origin)
		set ::FPSstats::config(gamenick_$arrival) $::FPSstats::config(gamenick_$origin)
		set ::FPSstats::config(configname_$arrival) $::FPSstats::config(configname_$origin)
		set ::FPSstats::config(chosen_state_$arrival) $::FPSstats::config(chosen_state_$origin)
		set ::FPSstats::config(statecode_$arrival) $::FPSstats::config(statecode_$origin)

		if {[info exists ::FPSstats::config(plays_TCE_$arrival)]} {
			unset ::FPSstats::config(plays_TCE_$arrival)
		}
		if {[info exists ::FPSstats::config(plays_TCE_$origin)]} {
			set ::FPSstats::config(plays_TCE_$arrival) $::FPSstats::config(plays_TCE_$origin)
		}
	}

	proc SwitchConfig { widget {val -1}} {
		variable num
		variable f
		set ::FPSstats::config(automessage_$num) [$f.automessage.text get 0.0 end]
		
		if {$val == -1} {
			set num [expr {[$widget.num getvalue]}]
		} else {
			set num $val
			$widget.num setvalue @$num
		}
		
		$f.activepsm configure -variable ::FPSstats::config(activepsm_$num)
		$f.psm.entry configure -textvariable ::FPSstats::config(psm_$num)
		$f.activeautomessage configure -variable ::FPSstats::config(activeautomessage_$num)
		$f.automessage.text delete 0.0 end
		$f.automessage.text insert end $::FPSstats::config(automessage_$num)
		$f.second.entry configure -textvariable ::FPSstats::config(second_$num)
		$f.game.list configure -textvariable ::FPSstats::config(game_$num)
		$f.cdkey.entry configure -textvariable ::FPSstats::config(cdkey_$num)
		$f.ip.entry configure -textvariable ::FPSstats::config(ip_$num)
		$f.gamenick.entry configure -textvariable ::FPSstats::config(gamenick_$num)
		$f.statename.entry configure -textvariable ::FPSstats::config(configname_$num)
		$f.chosen_state.list configure -textvariable ::FPSstats::config(chosen_state_$num)
	}

	proc FinishSavingConfig {event epvar} {
		upvar 2 evpar args
		upvar 2 name name
		variable f
		variable num
		if { "$name" == "FPSstats"} {
			set ::FPSstats::config(automessage_$num) [$f.automessage.text get 0.0 end]

			for {set i 0 } {$i<=$max_num} {incr i} {
				if {![string is digit -strict $::FPSstats::config(second_$i)] || $::FPSstats::config(second_$i) < 35 } {
					set config(second_$i) "35"
				}
			}
		}
	}

	#############################################
	# ::FPSstats::listGames                     #
	# ----------------------------------------- #
	# Return a list of available games          #
	#############################################
	proc listGames { } {
		set qstat_help [exec $::FPSstats::config(qstat) --help]
		set qstat_help [split $qstat_help "\n"]
		set list2return []
		#now, parsing !
		for {set i 1} {$i<=[llength $qstat_help]} {incr i} {
			set text_line [lindex $qstat_help $i] 
			if { [string match *query* $text_line] && ![string match -noportoffset* $text_line] } {
				lappend list2return [string map {"\t" " "}  $text_line]
			}

		}
		return $list2return
	}

	#############################################
	# ::FPSstats::checkQstat                    #
	# ----------------------------------------- #
	# Check if Qstat is available               #	
	# Return 1 if it's the case                 #
	#############################################
	proc checkQstat {{widget 0}} {
		variable f
		if {[file executable $::FPSstats::config(qstat)]} {
			status_log "[exec $::FPSstats::config(qstat) --help]" red
			if {[string match *query* [exec $::FPSstats::config(qstat) --help] ]} {
				if {$widget != "0" } {	
					$widget.qstat.checklabel configure -text "[trans qstat_ok]" -font splainf -fg black
					$f.game.list configure -values [listGames]
				}
				return 1
			}
		}
		if {$widget != "0"} {	
			$widget.qstat.checklabel configure -text "[trans qstat_error]" -font sboldf -fg red
		}
		return 0
	}

	#################################################
	# ::FPSstats::FillState                         #
	# --------------------------------------------- #
	# Fill the config(statecode_$num) var with the  #
	# correct value                                 #
	#################################################
	proc fillState {} {
		variable num
		for {set i 1} {$i <= "6"} {incr i} {
			set state [::MSN::numberToState $i]
			set desc [trans [::MSN::stateToDescription $state]]
			if {[string equal "$desc" "$::FPSstats::config(chosen_state_$num)"] } {
				set ::FPSstats::config(statecode_$num) $state
				status_log ";$::FPSstats::config(statecode_$num);$state" green
			}
		}
	}

	#############################################
	# ::FPSstats::checkGame                     #
	# ----------------------------------------- #
	# Make config(gameArg) and check if more    #
	# information is needed                     #
	#############################################
	proc checkGame { widget } {
		variable num
		set ::FPSstats::config(gameArg_$num) [string range [$widget cget -text] 0 [expr {[string first \  [$widget cget -text]] - 1}] ]
		log "$::FPSstats::config(gameArg_$num);"
		switch " $::FPSstats::config(gameArg_$num)" {
			" -rws" {
				if {[tk_messageBox -message "[trans playingTCE]" -type yesno] == "yes" } {
					set ::FPSstats::config(plays_TCE_$num) 1
				}
			}
			default {}
		}
	}

	#######################################################################
	# ::FPSstats::AddIconMenu                                             #
	# ------------------------------------------------------------------- #
	# Add an icon in the contact list to show/hide the song in the nick   #
	#######################################################################	
	proc AddIconMenu {event evPar} {
		upvar 2 $evPar vars
		
		if {$::FPSstats::config(num) != -1} {
			set icon playing_pic_FPSstats
		} else {
			set icon not_playing_pic_FPSstats
		}

		#TODO: add parameter to event and get rid of hardcoded variable
		set pgtop $::pgBuddyTop
		set clbar $::pgBuddyTop.colorbar

		set mylabel $pgtop.picFPSstats
		if {[winfo exists $mylabel]} {
			destroy $mylabel			
		}
		set imgwidth [image width [::skin::loadPixmap $icon]]
		set imgheight [image height [::skin::loadPixmap $icon]]
		set ::FPSstats::config(label) $mylabel
		label $mylabel -image [::skin::loadPixmap $icon] -background [::skin::getKey topcontactlistbg] -borderwidth 0 -cursor left_ptr \
			-relief flat -highlightthickness 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0 -width $imgwidth -height $imgheight

		pack $mylabel -expand false -after $clbar -side right -padx 0 -pady 0

		if {$::FPSstats::config(num) != -1} {
			bind $mylabel <<Button1>> "::FPSstats::StopPlaying -1"
		} else {
			bind $mylabel <<Button1>> "::FPSstats::StartPlaying -1"
		}
		

		bind $mylabel <<Button3>> "+::FPSstats::Menu %X %Y"

		set balloon_message [trans balloon_message]
		bind $mylabel <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		bind $mylabel <Leave> "+set ::Bulle(first) 0; kill_balloon;"
		bind $mylabel <Motion> +[list balloon_motion %W %X %Y $balloon_message]



		#if {$::FPSstats::config(num) != -1} {
		#    if {$::FPSstats::config(num) <= $::FPSstats::config(max_num)} {
		#        set num $::FPSstats::config(num)
		#        StartPlaying $num
		#    } else {
		#        StartPlaying 0
		#    }
		#}
	}

	proc Menu {cx cy} {
		if [winfo exists .menuFPSstats] {
			destroy .menuFPSstats
		}
		
		set num $::FPSstats::config(num)
		
		menu .menuFPSstats -tearoff 0 -type normal
		.menuFPSstats add command -label "[trans chooseconfig]" 
		
		.menuFPSstats add separator
		for {set i 0 } {$i<=$::FPSstats::config(max_num)} {incr i} {
			if {$i == $num} {
				.menuFPSstats add command -label "[trans stopplaying $::FPSstats::config(configname_$i)]"\
					-command "::FPSstats::StopPlaying $i"
			} else {	
				.menuFPSstats add command -label "[trans startplaying $::FPSstats::config(configname_$i)]"\
					-command "::FPSstats::StartPlaying $i"
			}
		}
		tk_popup .menuFPSstats $cx $cy
	}

	proc StopPlaying {num} {
		log "Stop Playing"
		if {$num == -1} {
			set num $::FPSstats::config(latest_num)			
		}
		if {$::FPSstats::config(activeautomessage_$num)}  {
			::plugins::UnRegisterEvent FPSstats user_joins_chat sendstats
		}
		if {$::FPSstats::config(activepsm_$num)} {	
			::MSN::changeCurrentMedia Games 0 ""
		}
		set ::FPSstats::config(num) -1

		$::FPSstats::config(label) configure -image [::skin::loadPixmap not_playing_pic_FPSstats ]
		bind $::FPSstats::config(label) <<Button1>> "::FPSstats::StartPlaying -1"

		status_log "$::FPSstats::config(previous_status)" red	
		::MSN::changeStatus $::FPSstats::config(previous_status)
	}

	proc StartPlaying {num} {
		log "Start Playing"
		if {$num == -1} {
			set num $::FPSstats::config(latest_num)			
		}
		set ::FPSstats::infos(oldmap) 0
		set ::FPSstats::infos(oldscore) 0
		set ::FPSstats::config(previous_status) [::MSN::myStatusIs]
		set ::FPSstats::config(latest_num) $num
		set ::FPSstats::config(num) $num
		status_log "$num;$::FPSstats::config(statecode_$num);" red
		::MSN::changeStatus $::FPSstats::config(statecode_$num)
		
		$::FPSstats::config(label) configure -image [::skin::loadPixmap playing_pic_FPSstats ]
		bind $::FPSstats::config(label) <<Button1>> "::FPSstats::StopPlaying -1"

		if {$::FPSstats::config(activeautomessage_$num)}  {
			::plugins::RegisterEvent FPSstats user_joins_chat sendstats
		}
		if {$::FPSstats::config(activepsm_$num)} {	
			after 100 ::FPSstats::loopchangepsm
		}
	}

	##############################################
	## ::FPSstats::checkstate                    #
	## ----------------------------------------- #
	## Check if users is on the FPSstats-state   #
	## In fact, just for testing RegisterEvent   #
	## procedures                                #
	##############################################
	#proc checkstate {event epvar} {
	#    variable num
	#    variable endloopnick
	#    variable automessageactivated
	#    upvar 2 evpar args
	#    upvar 2 idx idx
	#    
	#    
	#    set idx_FPSstats_state [search_idx [list $::FPSstats::config(configname_$num)]]
	#    #when the user wants to use the FPSstats functions
	#    if { $idx == $idx_FPSstats_state } {
	#        if { $::FPSstats::config(activepsm_$num) } {
	#            #launch the loop which display the stats in the nickname
	#            set endloopnick {0}
	#            set ::FPSstats::infos(oldmap) 0
	#            set ::FPSstats::infos(oldscore) 0
	#            after 1000 ::FPSstats::loopchangepsm
	#        }
	#        if { $::FPSstats::config(activeautomessage_$num) } {
	#            #register the event for auto-messaging
	#            ::plugins::RegisterEvent FPSstats user_joins_chat sendstats
	#            set automessageactivated {1}
	#        }
	#    } else {
	#        #deactivate the loop which change the nickname and unregister the event user_joins_chat
	#        #if the user stops using those functions.
	#        if { $::FPSstats::config(activepsm_$num) && !$endloopnick } {
	#            set endloopnick {1}
	#            if {[::config::getKey protocol] == 11} {
	#                ::MSN::changeCurrentMedia Games 0 ""
	#            }
	#        }
	#        if { $::FPSstats::config(activeautomessage_$num) && $automessageactivated } {
	#            ::plugins::UnRegisterEvent FPSstats user_joins_chat sendstats
	#            set automessageactivated {0}
	#        }
	#    }
	#}


	##############################################
	## ::FPSstats::add_state_1st_time            #
	## ----------------------------------------- #
	## Add the state when the plugin is loaded   #
	##############################################
	#proc add_state_1st_time {event epvar} {
	#    upvar 2 evpar args
	#    upvar 2 name name
	#    if { "$name" == "FPSstats"} {
	#        set i 0
	#        while {$i < "7"} {
	#            set configname "[::MSN::numberToState $i]"
	#            if { "$::FPSstats::config(chosen_state_0)" == "$configname" } {
	#                set state $i
	#                break
	#            }
	#        incr i
	#    }
	#    unset i
	#        addcustomstate $::FPSstats::config(configname_0) $state
	#        ::plugins::UnRegisterEvent FPSstats PluginConfigured add_state_1st_time
	#    }
	#}
	
	##################################################
	## ::FPSstats::search_idx customstatename        #
	## --------------------------------------------- #
	## Return the idx of the customstate             #
	##################################################
	#proc search_idx { customstatename } {
	#    set state_informations {}
	#    for {set i 0} {$i < [StateList size]} {incr i} {
	#        set state_informations [StateList get $i ]
	#        if {[string match *$customstatename* $state_informations]} {
	#            return $i
	#        }
	#    }
	#    return -1
	#}
	
	################################################
	## ::FPSstats::addcustomstate                  #
	## ------------------------------------------- #
	## Add a new custom state check if an other    #
	## already exist then delete it                #
	################################################
	#proc addcustomstate { customstatename state_number } {
	#    #check, and delete
	#    removecustomstate $customstatename
	#    #add the state without nick, automessage or a state
	#    #name
	#    lappend customstate [list $customstatename]
	#    #nickname
	#    lappend customstate []
	#    #state
	#    lappend customstate $state_number
	#    #number of lines
	#    lappend customstate "0"
	#    #message
	#    lappend customstate []
	#    StateList add $customstate
	#    #promote the state, usefull for the users ;-)
	#    set idx [search_idx $customstatename]
	#    StateList promote $idx
	#    #save and exit !
	#    CreateStatesMenu .my_menu
	#    SaveStateList
	#    LoadStateList
	#}
	
	##################################################
	## ::FPSstats::removecustomstate customstatename #
	## --------------------------------------------- #
	## Remove a customstate                          #
	##################################################
	#proc removecustomstate { customstatename } {
	#    set idx [search_idx $customstatename]
	#    if { $idx != -1 } {
	#            StateList unset $idx
	#    }
	#    CreateStatesMenu .my_menu
	#    SaveStateList
	#    LoadStateList
	#}


	
	##########################################
	## ::FPSstats::language_array            #
	## ------------------------------------- #
	## Create ::FPSstats::language array     #
	## Compatible with lang files            #
	##########################################
	#proc language_array {} {
	#    array set ::FPSstats::language [list \
	#        activepsm "[trans fpsstats_activepsm]" \
	#        activeautomessage "[trans fpsstats_activeautomessage]" \
	#        nickname "[trans fpsstats_nickname]" \
	#        automessage "[trans fpsstats_automessage]" \
	#        second "[trans fpsstats_second]" \
	#        game "[trans fpsstats_game]" \
	#        qstat "[trans fpsstats_qstat]" \
	#        ip "[trans fpsstats_ip]" \
	#        gamenick "[trans fpsstats_gamenick]" \
	#        statename "[trans fpsstats_statename]" \
	#        enabled "[trans fpsstats_enabled]" \
	#        disabled "[trans fpsstats_disabled]" \
	#        help "[trans fpsstats_help]" \
	#        choose_state "[trans fpsstats_choose_state]" \
	#        browse "[trans fpsstats_browse]" \
	#        choose_state "[trans fpsstats_choose_state]" \
	#        choose_state_button "[trans fpsstats_choose_state_button]" \
	#    ]
	#}
	
	#########################################
	# ::FPSstats::language_array_094        #
	# ------------------------------------- #
	# Load default english keys in array    #
	# For aMSN 0.94 only                    #
	#########################################
	#proc language_array_094 {} {
	#    array set ::FPSstats::language [list \
	#        activepsm "Add your stats to your nickname" \
	#        activeautomessage "Add your stats to an auto-message" \
	#        nickname "Your nickname with the variables in (\$score for example)" \
	#        automessage "Your automessage with the variables in (\$map for example)" \
	#        second "Check if there are new informations each ? seconds" \
	#        game "Game you play (\"-rws\" for Enemy territory)" \
	#        qstat "Path to the Qstat executable" \
	#        ip "IP adress of the server" \
	#        gamenick "Your nickname, in the game" \
	#        statename "The name of the state with which would display your stats" \
	#        disabled "Disabled" \
	#        enabled "Enabled" \
	#        help "Help" \
	#        choose_state "The code of the state with which you would appear when playing :" \
	#        choose_state_button "About those codes" \
	#        browse "Browse" \
	#    ]
	#}

	#############################################
	# ::FPSstats::sendstats                     #
	# ----------------------------------------- #
	# Check if the user is on the FPSstats-state#
	# In fact, just for testing RegisterEvent   #
	# procedures                                #
	#############################################
	proc sendstats {event epvar} {
		upvar 2 evpar args
		upvar 2 win_name win_name
		set num $::FPSstats::config(num)
		if {$num != -1 } {
			::FPSstats::log "\nSending stats to $win_name\n"
			set message2send [::FPSstats::rewritestring $::FPSstats::config(automessage_$num)]
			::amsn::MessageSend $win_name 0 [list $message2send]
		}
	}
	
	#############################################
	# ::FPSstats::Deinit                        #
	# ----------------------------------------- #
	# Closing Procedure                         #
	# (Called by the Plugins System)            #
	#############################################
	proc Deinit { } {
		::FPSstats::log "\nClosing FPSstats\n"

		if {[winfo exists $::pgBuddyTop.picFPSstats]} {
			destroy $::pgBuddyTop.picFPSstats			
		}
		set ::FPSstats::config(num) -1
		::MSN::changeCurrentMedia Games 0 ""
#::MSN::changeStatus NLN
#This make a bug because when aMSN exits, the customstate is delete, so the user should remove himself the customstate.
#		removecustomstate $::FPSstats::config(statename)
	}
	
	
	###############################################
	# ::FPSstats::loopchangepsm                   #
	# ------------------------------------------- #
	# Protocol to change the nickname every ?     #
	# seconds                                     #
	###############################################
	proc loopchangepsm { } {
		plugins_log "FPSstats" "changing psm"
		set num $::FPSstats::config(num)
		if { $num != -1 } {
			set newpsm [::FPSstats::rewritestring $::FPSstats::config(psm_$num)]
			::MSN::changeCurrentMedia Games 1 "{0}" "$newpsm"
			#Take the second number we have from the plugin config and 
			#multiply by 1000 because "after" count in "ms" (1000ms=1s)
			set time [expr {int($::FPSstats::config(second_$num)*1000)}]
			#Reload changenick proc after this time (loop)
			after $time ::FPSstats::loopchangepsm
		}
	}
	
	################################################
	## ::FPSstats::changenick newnick              #
	## ------------------------------------------- #
	## Protocol to change the nickname             #
	################################################
	#proc changenick {newnick2apply} {
	#    #Check if the nick needs to be up to date in order not to flood logs
	#    if { ( $::FPSstats::infos(ping) != "xxx" ) && ( $::FPSstats::infos(oldmap) != $::FPSstats::infos(currentmap) ) ||\
	#        ( $::FPSstats::infos(oldscore) != $::FPSstats::infos(score) )} {
	#        if {[::config::getKey protocol] == 11} {
	#            ::MSN::changeCurrentMedia Games 1 "$newnick2apply"
	#        } else {
	#            set email [::config::getKey login]
	#            ::MSN::changeName $email "$newnick2apply"
	#        }
	#    }
	#    set ::FPSstats::infos(oldmap) $::FPSstats::infos(currentmap)
	#    set ::FPSstats::infos(oldscore) $::FPSstats::infos(score)
	#}
	
	###############################################
	# ::FPSstats::log message					  #
	# ------------------------------------------- #
	# Procedure to send a message to the plugins  #
	# log                                         #
	###############################################
	proc log {message} {
		plugins_log FPSstats $message
	}
	
	##############################################
	## ::FPSstats::version_094                   #
	## ----------------------------------------- #
	## Verify if the version of aMSN is 0.94     #
	## Useful if we want to keep compatibility   #
	##############################################
	#proc version_094 {} {
	#    global version
	#    scan $version "%d.%d" y1 y2;
	#    if { $y2 == "94" } {
	#        return 1
	#    } else {
	#        return 0
	#    }
	#}

	###############################################
	# ::FPSstats::rewritestring string2modify     #
	# ------------------------------------------- #
	# Rewrite the nick or the automessage with    #
	# the correct values and return it            #
	###############################################
	proc rewritestring { string2modify } {
		set num $::FPSstats::config(num)
		set string2return $string2modify
		::FPSstats::get_all_informations
		
		regsub -all {\$servername} $string2return $::FPSstats::infos(servername) string2return
		regsub -all {\$ip} $string2return $::FPSstats::config(ip_$num) string2return
		regsub -all {\$map} $string2return $::FPSstats::infos(currentmap) string2return
		regsub -all {\$score} $string2return $::FPSstats::infos(score) string2return
		regsub -all {\$ping} $string2return $::FPSstats::infos(ping) string2return
		regsub -all {\$numplayers} $string2return $::FPSstats::infos(numplayers) string2return
		regsub -all {\$free} $string2return $::FPSstats::infos(free) string2return
		regsub -all {\$maxplayers} $string2return $::FPSstats::infos(maxplayers) string2return
		regsub -all {\$friendlyfire} $string2return $::FPSstats::infos(friendlyfire) string2return
		regsub -all {\$team} $string2return $::FPSstats::infos(team) string2return
		
		regsub -all {\$gamenick} $string2return $::FPSstats::config(gamenick_$num) string2return
		
		return $string2return
	}

		######################
		#Not working as i want
		######################

	#    proc loadXML {cstack cdata saved_data cattr saved_attr args } {
	#        variable users_data
	#        upvar $saved_data sdata 
	#        upvar $saved_attr sattr
	#        
	#        upvar $cdata c_data 
	#        upvar $cattr c_attr
	#
	#        array set attr $cattr
	#        
	#        status_log "[array get sattr]" green
	#
	#        status_log "[array get c_data]" green
	#        status_log "[array get c_attr]" green
	#
	#        status_log "[array get sdata]" blue
	#        status_log "[array names sdata]" blue
	#        status_log "$sdata(qstat:server:numplayers);$sdata(qstat:server:hostname)" green
	#        status_log "$sdata(qstat:server:players:player:ping);$sdata(qstat:server:players);$sdata(qstat:server:players:player); $sdata(qstat:server:players:player:name)" green
	#        
	#
	#        foreach name [array names sdata] {
	#            status_log "$name:=$sdata($name)" green
	#        }
	#        return 0	
	#
	##qstat:server:numplayers qstat:server:rules:rule qstat:server:map qstat:server:maxplayers qstat:server qstat:server:players qstat:server:name _dummy_ qstat:server:players:player:name qstat:server:rules qstat:server:gametype qstat:server:players:player:score qstat:server:ping qstat:server:retries qstat:server:players:player:ping qstat:server:hostname qstat:server:players:player
	#    }

	
	######################################################
	# ::FPSstats::get_all_informations                   #
	# -------------------------------------------------- #
	# Get the informations from the server using Qstat   #
	# and copy them to stats.xml and parse/sort them.    #
	# This is the main procedure but the ugliest one :'( #
	######################################################
	proc get_all_informations { } {
		global HOME
		set num $::FPSstats::config(num)
		set temp {}
		set textline {}
		set endloop 0
		variable num_player
		set num_player 0
		set allies {}
		set axis {}
		array set ::FPSstats::infos {
			servername {}
			currentmap {}
			score {x}
			ping xxx
			numplayers {0}
			maxplayers {0}
			free {0}
			friendlyfire {0}
			team {Spectators}
			gamenick {}
			gameArg_cdkey ""
		}	
		set ::FPSstats::infos(gameArg_cdkey) $::FPSstats::config(gameArg_$num)
		set ::FPSstats::infos(gamenick) $::FPSstats::config(gamenick_$num)
		regsub -all {\[} $::FPSstats::infos(gamenick) {\\[} ::FPSstats::infos(gamenick)
		regsub -all {\]} $::FPSstats::infos(gamenick) {\\]} ::FPSstats::infos(gamenick)
		regsub -all {=} $::FPSstats::infos(gamenick) {\\=} ::FPSstats::infos(gamenick)
		
		#make the argument about the game we're playing at : add or not the cdkey
		if {$::FPSstats::config(cdkey_$num) != ""} {
			append ::FPSstats::infos(gameArg_cdkey) "," "cdkey=" "$::FPSstats::config(cdkey_$num)"
		} 

		#write on the file stats.xml
		if {[catch {open ${HOME}/stats.xml "w"} file_]} {
			::FPSstats::log "\nerror: $file_\n"
		} else {
			plugins_log "FPSstats" "executing : $::FPSstats::config(qstat) -P -R -xml $::FPSstats::infos(gameArg_cdkey) $::FPSstats::config(ip_$num)"
			if { [catch {exec $::FPSstats::config(qstat) -P -R -xml $::FPSstats::infos(gameArg_cdkey) $::FPSstats::config(ip_$num) } res] } {
				::FPSstats::log "\nerror: $res\n"
			} else {
				puts $file_ $res
			}
			close $file_
		}
		
		if {[catch {open ${HOME}/stats.xml "r"} file_]} {
			::FPSstats::log "\nerror: $file_\n"
		}


		######################
		#Not working as i want
		######################
		#set statsxml_id [::sxml::init [file join ${HOME} stats.xml]]
		#sxml::register_routine $statsxml_id "qstat" "::FPSstats::loadXML"
		#
		#set ret [sxml::parse $statsxml_id]
		#status_log "ret:=$ret" red
	
		#sxml::end $statsxml_id

		
		gets $file_ textline
		while {[eof $file_] != 1 && $endloop != 1} {
			if {[string match *<name>*</name> $textline]} {
				regexp {<name>([\ \#\.\[\]\@\|\-\=\^\&\_[:alnum:]]+)</name>} $textline -> ::FPSstats::infos(servername)
				set endloop 1
			}		
			gets $file_ textline
		}
		#get the name of the current map
		set endloop 0
		while {[eof $file_] != 1 && $endloop != 1} {
			if {[string match *<map>*</map> $textline]} {
				regexp {<map>([\ \#\.\[\]\@\|\-\=\^\&\_[:alnum:]]+)</map>} $textline -> ::FPSstats::infos(currentmap)
				set endloop 1
			}
			gets $file_ textline             
		}
		#get the number of the players
		set endloop 0
		while {[eof $file_] != 1 && $endloop != 1} {
			if {[string match *<numplayers>*</numplayers> $textline]} {
				regexp {<numplayers>(\d+)</numplayers>} $textline -> ::FPSstats::infos(numplayers)
				set endloop 1
			}
			gets $file_ textline
		}
		#get the number of the players allowed on the server
		set endloop 0
		while {[eof $file_] != 1 && $endloop != 1} {
			if {[string match *<maxplayers>*</maxplayers> $textline]} {
				regexp {<maxplayers>(\d+)</maxplayers>} $textline -> ::FPSstats::infos(maxplayers)
				set endloop 1
			}
			gets $file_ textline
		}
			
		if {$::FPSstats::config(game_$num) == "-rws"} {
			set endloop 0
				gets $file_ textline
			while {[eof $file_] != 1 && $endloop != 1} {
				if {[string match *<player>* $textline]} {
					set endloop 1
				} else {
					regexp {<rule\ name=\"(\w+)\">} $textline -> temp
					switch $temp {
					
						"friendlyFire" { 
							regexp {<rule\ name=\"friendlyFire\">(\d+)</rule>} $textline -> ::FPSstats::infos(friendlyfire) 
							if { $::FPSstats::infos(friendlyfire) } {
							set ::FPSstats::infos(friendlyfire) [trans enabled]
							} else {
							set ::FPSstats::infos(friendlyfire) [trans disabled]
							}
						}
						
						"Players_Allies" {
							regexp {<rule\ name=\"Players_Allies\">([\ \d]+)</rule>} $textline -> allies
							set allies \ $allies\ 
						}
							
						"Players_Axis" {
							regexp {<rule\ name=\"Players_Axis\">([\ \d]+)</rule>} $textline -> axis
							set axis \ $axis\ 
						}
					}
					gets $file_ textline
				}
			}
		}
	
		# Get informations about the player
		set endloop 0
		while {[eof $file_] != 1 && $endloop != 1} {
			if {[string match *<player>* $textline]} {
				incr num_player
				gets $file_ textline
				if {[string match  *$::FPSstats::infos(gamenick)* $textline]} {
					gets $file_ textline
					regexp {<score>(\d+)</score>} $textline -> ::FPSstats::infos(score)
					gets $file_ textline
					regexp {<ping>(\d+)</ping>} $textline -> ::FPSstats::infos(ping)
					set endloop 1
				}
			}
			gets $file_ textline              
		}
	
		if {$::FPSstats::config(game_$num) == "-rws"} {
			#get the team of the player (only with Enemy Territory)
			if {$::FPSstats::infos(ping) == "xxx"} {
				set num_player 0
				set ::FPSstats::infos(team) No\ Team
			} else {
				set num_player \ $num_player\ 
				if {[string match *$num_player* $allies]} {
					if {[info exists ::FPSstats::config(plays_TCE_$num)]} {
						set ::FPSstats::infos(team) specops
					} else {
						set ::FPSstats::infos(team) allies
					}
				} elseif {[string match *$num_player* $axis]} {
					if {[info exists ::FPSstats::config(plays_TCE_$num)]} {
						set ::FPSstats::infos(team) terros
					} else {
						set ::FPSstats::infos(team) axis
					}
				} 
			}
		}
		close $file_
		set ::FPSstats::infos(free) [expr {int($::FPSstats::infos(maxplayers) - $::FPSstats::infos(numplayers))}]
	
	}

	###############################################
	# ::FPSstats::ShowFile                        #
	# ------------------------------------------- #
	# Show a file ;-)                             #
	###############################################
	proc ShowFile { file title {encoding "utf-8"}} {
		if { [winfo exists .showfile] } {
			raise .showfile
			return
		}

		toplevel .showfile
		wm title .showfile "$title"
		ShowTransient .showfile

		#Top frame (Help text area)
		frame .showfile.info
		frame .showfile.info.list -class Amsn -borderwidth 0
		text .showfile.info.list.text -background white -width 80 -height 30 -wrap word \
			-yscrollcommand ".showfile.info.list.ys set" -font   splainf
		scrollbar .showfile.info.list.ys -command ".showfile.info.list.text yview"
		pack .showfile.info.list.ys 	-side right -fill y
		pack .showfile.info.list.text -expand true -fill both -padx 1 -pady 1
		pack .showfile.info.list 		-side top -expand true -fill both -padx 1 -pady 1
		pack .showfile.info 			-expand true -fill both -side top

		#Bottom frame (Close button)
		button .showfile.close -text "[trans close]" -command "destroy .showfile"
		bind .showfile <<Escape>> "destroy .showfile"
		pack .showfile.close
		pack .showfile.close -side top -anchor e -padx 5 -pady 3
		
		#Insert FAQ text 
		set id [open $file r]
		fconfigure $id -encoding $encoding
		.showfile.info.list.text insert 1.0 [read $id]
		close $id

		.showfile.info.list.text configure -state disabled
		update idletasks

		set x [expr {([winfo vrootwidth .showfile] - [winfo width .showfile]) / 2}]
		set y [expr {([winfo vrootheight .showfile] - [winfo height .showfile]) / 2}]
		wm geometry .showfile +${x}+${y}
	}
		
	##############################################
	## ::FPSstats::Browse_Dialog_file            #
	##############################################
	#proc Browse_Dialog_file {configitem {initialfile ""}} {
	#    if { $initialfile == "" } {
	#        set initialfile [set $configitem]
	#    }
	#    if { ![file exists $initialfile] } {
	#        set initialfile ""
	#    }
	#    set browsechoose [tk_getOpenFile -parent [focus] -initialfile $initialfile]
	#    if { $browsechoose !="" } {
	#        set $configitem $browsechoose
	#    }
	#}
	
	#####################################################
	## ::FPSstats::ShowInfosStates                      #
	## ------------------------------------------------ #
	## Display the informations about digits and states #
	#####################################################
	#proc ShowInfosStates { } {
	#    if { [winfo exists .showinfos] } {
	#        raise .showinfos
	#        return
	#    }
	#    toplevel .showinfos
	#    wm title .showinfos "$::FPSstats::language(choose_state_button)"
	#    ShowTransient .showinfos
	#
	#    #Top frame (Help text area)
	#    frame .showinfos.info
	#    frame .showinfos.info.list -class Amsn -borderwidth 0
	#    text .showinfos.info.list.text  -background white -width 35 -height 8 -wrap word -yscrollcommand ".showinfos.info.list.ys set" -font splainf
	#    scrollbar .showinfos.info.list.ys -command ".showinfos.info.list.text yview"
	#    pack .showinfos.info.list.ys 	-side right -fill y
	#    pack .showinfos.info.list.text -expand true -fill both -padx 1 -pady 1
	#    pack .showinfos.info.list 		-side top -expand true -fill both -padx 1 -pady 1
	#    pack .showinfos.info 			-expand true -fill both -side top
	#
	#    #Bottom frame (Close button)
	#    button .showinfos.close -text "[trans close]" -command "destroy .showinfos"
	#    bind .showinfos <<Escape>> "destroy .showinfos"
	#    pack .showinfos.close
	#    pack .showinfos.close -side top -anchor e -padx 5 -pady 3
	#
	#    #make toshow
	#    set toshow ""
	#    set i 0
	#    while {$i < "7"} {
	#        set configname "[::MSN::numberToState $i]"
	#        set description "[trans [::MSN::stateToDescription $configname]]"
	#        append toshow "$configname => $description \n"
	#        incr i
	#    }
	#    unset i
	#    .showinfos.info.list.text insert 1.0 "$toshow"
	#    unset toshow
	#    .showinfos.info.list.text configure -state disabled
	#    update idletasks
	#    set x [expr {([winfo vrootwidth .showinfos] - [winfo width .showinfos]) / 2}]
	#    set y [expr {([winfo vrootheight .showinfos] - [winfo height .showinfos]) / 2}]
	#    wm geometry .showinfos +${x}+${y}
	#    
	#}
	#
#end of FPSstats namespace
}

