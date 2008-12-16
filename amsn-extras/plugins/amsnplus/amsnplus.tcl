########################################################
#             AMSNPLUS PLUGIN NAMESPACE
########################################################
# Maintainer: markitus (markitus@catmail.homelinux.org)
# Created: 13/09/2004
########################################################

namespace eval ::amsnplus {


	#//////////////////////////////////////////////////////////////////////////
	#                          CORE PROCEDURES
	#//////////////////////////////////////////////////////////////////////////

	################################################
	# this starts amsnplus
	proc amsnplusStart { dir } {
		#global vars
		variable external_commands
		array set ::amsnplus::external_commands [list]
		#register plugin
		::plugins::RegisterPlugin "aMSN Plus"
		#set the amsnplus dir in config
		::config::setKey amsnpluspluginpath $dir
		#loading lang - if version is 0.95b (keep compatibility with 0.94)
		if {[::amsnplus::amsn_version] > 94} {
			set langdir [file join $dir "lang"]
			set lang [::config::getGlobalKey language]
			load_lang en $langdir
			load_lang $lang $langdir
		}
		#plugin config
		if {[::amsnplus::amsn_version] <= 94} {
			array set ::amsnplus::config {
				allow_commands 1
				allow_quicktext 1
				quick_text [list]
			}
			set ::amsnplus::configlist [ list \
				[list bool "Do you want to allow commands in the chat window?" allow_commands] \
				[list bool "Do you want to use the quick text feature?" allow_quicktext] \

			]
		} else {
			array set ::amsnplus::config {
				allow_commands 1
				allow_colours 1
				allow_quicktext 1
				quick_text [list]
			}
			set ::amsnplus::configlist [ list \
				[list bool "[trans allowcommands]" allow_commands] \
				[list bool "[trans allowcolours]" allow_colours] \
				[list bool "[trans allowquicktext]" allow_quicktext] \
			]
		}

		#creating the menus
		catch { after 100 ::amsnplus::add_plus_menu }
		catch { after 100 ::amsnplus::add_chat_menu }

		#register events
		::plugins::RegisterEvent "aMSN Plus" chat_msg_send parseCommand
		::plugins::RegisterEvent "aMSN Plus" chat_msg_receive parse_colours_and_sounds
		::plugins::RegisterEvent "aMSN Plus" chatwindowbutton chat_color_button
		::plugins::RegisterEvent "aMSN Plus" chatmenu edit_menu

		if {[::amsnplus::amsn_version] > 94} {
			::amsnplus::setPixmap
		}
	}

	####################################################
	# deinit procedure, all to do when unloading the plugin
	proc amsnplusStop { } {
		#removing the plus menu and chat window pixmap
		.main_menu delete last
		::amsnplus::remove_from_chatwindow
	}



	#//////////////////////////////////////////////////////////////
	#            PLUS MENUS AND PREFERENCES
	#//////////////////////////////////////////////////////////////

	####################################################
	# this proc removes every menu in every chat window
	# and also the pixmap of amsnplus to choose a color
	proc remove_from_chatwindow { } {
		#the path of the menu is always $w.menu
		if { [::ChatWindow::UseContainer] } {
			set cont [array get ::ChatWindow::containers]
			foreach container $cont {
				catch { ${container}.menu delete last }
			}
		} else {
			foreach win $::ChatWindow::windows {
				catch { ${win}.menu delete last }
			}
		}
	}

	####################################################
	# creates the plus sub menu in the main gui menu
	proc add_plus_menu { } {
		catch {
			menu .main_menu.plusmenu -tearoff 0
			set plusmenu .main_menu.plusmenu

			#entries for the plus menu
			$plusmenu add command -label "[trans quicktext]" -command "::amsnplus::qtconfig"
		}
		.main_menu add cascade -label "Plus!" -menu .main_menu.plusmenu
	}

	###############################################
	# creates the chat window menu
	proc create_chat_menu { win } {
		set bold [binary format c 2]
		set italic [binary format c 5]
		set underline [binary format c 31]
		set overstrike [binary format c 6]
		set reset [binary format c 15]
		set screenshot "/screenshot"
		
		catch {
			menu ${win}.menu.plusmenu -tearoff 0
			set plusmenu ${win}.menu.plusmenu
		
			if { $::amsnplus::config(allow_colours) } {
				$plusmenu add command -label "[trans choosecolor]" -command "::amsnplus::choose_color $win"
				$plusmenu add command -label "[trans bold]" -command "::amsnplus::insert_text $win $bold"
				$plusmenu add command -label "[trans italic]" -command "::amsnplus::insert_text $win $italic"
				$plusmenu add command -label "[trans underline]" -command "::amsnplus::insert_text $win $underline"
				$plusmenu add command -label "[trans overstrike]" -command "::amsnplus::insert_text $win $overstrike"
				$plusmenu add command -label "[trans reset]" -command "::amsnplus::insert_text $win $reset"
				$plusmenu add separator
			}
				$plusmenu add command -label "[trans screenshot]" -command "::amsnplus::insert_text $win $screenshot"
			if {$::amsnplus::config(allow_quicktext)} {
				$plusmenu add separator
				#Menu item to edit the currents quick texts
				$plusmenu add command -label "[trans quicktext]" -command "::amsnplus::qtconfig"
				set i 0
				#Show all the currents quick texts in the menu
				foreach {key txt} $::amsnplus::config(quick_text) {
					$plusmenu add command -label $txt -command "::amsnplus::insert_text $win /$key"
				}
			}
		}
		set plusmenu ${win}.menu.plusmenu
		return $plusmenu
	}

	###############################################
	# attaches the menu on chat window
	proc add_chat_menu { } {
		if { [::ChatWindow::UseContainer] } {
			set cont [array get ::ChatWindow::containers]
			foreach container $cont {
				if { [string equal [string index $container 0] "."] } {
					catch {
						set plusmenu [::amsnplus::create_chat_menu $container]
						${container}.menu add cascade -label "Plus!" -menu $plusmenu
					}
				}
			}
		} else {

			foreach win $::ChatWindow::windows {
				#I think the catch is useless but it's in case someone close a chatwindow very fast, then we won't have a stupid bugreport
				catch {
					set plusmenu [::amsnplus::create_chat_menu $win]
					${win}.menu add cascade -label "Plus!" -menu $plusmenu
				}
			}
		}

	}

	###############################################
	# this creates some commands for editing in the
	# chat window packed in the edit menu
	proc edit_menu {event epvar} {
		upvar 2 evPar newvar
		set bold [binary format c 2]
		set italic [binary format c 5]
		set underline [binary format c 31]
		set overstrike [binary format c 6]
		set reset [binary format c 15]
		set screenshot "/screenshot"

		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			set key "Command"
		} else {
			set key "Ctrl"
		}

		set menu_name $newvar(menu_name)
		menu ${menu_name}.plusmenu -tearoff 0
		$newvar(menu_name) add cascade -label "Plus!" -menu ${menu_name}.plusmenu
		set plusmenu ${menu_name}.plusmenu

		if { $::amsnplus::config(allow_colours) } {
			$plusmenu add command -label "[trans choosecolor]" -command "::amsnplus::choose_color $newvar(window_name)"
			$plusmenu add command -label "[trans bold]" -command "::amsnplus::insert_text $newvar(window_name) $bold" -accelerator "${key}+B"
			$plusmenu add command -label "[trans italic]" -command "::amsnplus::insert_text $newvar(window_name) $italic" -accelerator "${key}+I"
			$plusmenu add command -label "[trans underline]" -command "::amsnplus::insert_text $newvar(window_name) $underline" -accelerator "${key}+U"
			$plusmenu add command -label "[trans overstrike]" -command "::amsnplus::insert_text $newvar(window_name) $overstrike" -accelerator "${key}+O"
			$plusmenu add command -label "[trans reset]" -command "::amsnplus::insert_text $newvar(window_name) $reset" -accelerator "${key}+R"
		}

		$plusmenu add command -label "[trans screenshot]" -command "::amsnplus::insert_text $newvar(window_name) $screenshot"
		if {$::amsnplus::config(allow_quicktext)} {
			$plusmenu add separator
			#Menu item to edit the currents quick texts
			$plusmenu add command -label "[trans quicktext]" -command "::amsnplus::qtconfig"
			set i 0
			#Show all the currents quick texts in the menu
			foreach {key txt} $::amsnplus::config(quick_text) {
				$plusmenu add command -label $txt -command "::amsnplus::insert_text $newvar(window_name) /$key"
			}
		}
	}



	#//////////////////////////////////////////////////////////////////////////
	#                      GENERAL PURPOSE PROCEDURES
	#//////////////////////////////////////////////////////////////////////////

	###################################################################
	# this returns the readme content in a variable
	proc help {} {
		set dir [::config::getKey amsnpluspluginpath]
		set channel [open "$dir/readme" "RDONLY"]
		return "[read $channel]"
	}

	############################################
	# ::amsnplus::amsn_version                 #
	# -----------------------------------------#
	# Verify if the version of aMSN is 0.94    #
	# Useful if we want to keep compatibility  #
	############################################
	proc amsn_version {} {
		global version
		scan $version "%u.%u" y1 y2
		return [expr {$y1 * 100 + $y2}]
	}

	####################################################
	# returns 1 if the char is a numbar, otherwise 0
	proc is_a_number { char } {
		set clen [string length $char]
		set i 0
		while {$i < $clen} {
			set digit [string index $char $i]
			if {![string match \[0-9\] $digit]} { return 0 }
			incr i
		}
		return 1
	}

	#####################################################
	# this returns the first word read in a string
	proc readWord { i msg strlen } {
		set a $i
		set str ""
		while {$a<$strlen} {
			set char [string index $msg $a]
			if {[string equal $char " "]} {
				return $str
			}
			set str "$str$char"
			incr a
		}
		return $str
	}

	####################################################################
	# this is a proc to parse description to state in order to make
	# more easier to the user to change the state
	proc descriptionToState { newstate } {
		if {[string equal $newstate "online"]} { return "NLN" }
		if {[string equal $newstate "away"]} { return "AWY" }
		if {[string equal $newstate "busy"]} { return "BSY" }
		if {[string equal $newstate "rightback"]} { return "BRB" }
		if {[string equal $newstate "onphone"]} { return "PHN" }
		if {[string equal $newstate "gonelunch"]} { return "LUN" }
		if {[string equal $newstate "appearoff"]} { return "HDN" }
		return $newstate
	}

	###################################################################
	# this detects if the state user want to change is valid
	proc stateIsValid { state } {
		if {[string equal $state "online"]} { return 1 }
		if {[string equal $state "away"]} { return 1 }
		if {[string equal $state "busy"]} { return 1 }
		if {[string equal $state "rightback"]} { return 1 }
		if {[string equal $state "onphone"]} { return 1 }
		if {[string equal $state "gonelunch"]} { return 1 }
		if {[string equal $state "appearoff"]} { return 1 }
		return 0
	}

	###################################################################
	# this procs writes msg to the window with chatid and checks the
	# the config if its a received command (env)
	proc write_window { chatid msg env {colour "green"} } {
		::amsn::WinWrite $chatid $msg $colour
	}



	#//////////////////////////////////////////////////////////////////////////
	#                               QUICK TEXT
	#//////////////////////////////////////////////////////////////////////////

	################################################
	# this proc lets configure the quick texts
	proc qtconfig { } {

		set w .qtconfig
		#Verify if the window is already opened
		if {[winfo exists $w]} {
			raise $w
			return
		}
		#Create the window
		toplevel $w -width 600 -height 400
		wm title $w "[trans quicktext]"

		#Text explanation, in frame top.help
		frame $w.top
		if {[::amsnplus::amsn_version] <= 94} {
			label $w.top.help -text "Here you should configure your quick text, the keyword and the text. \n Then in the chat window, if you do /keyword, \
				you'll see the text" -height 2
		} else {
			label $w.top.help -text "[trans qthelp]\n"
		}
		pack $w.top.help -side top -expand true
		pack $w.top -side top -fill y

		frame $w.middle
		listbox $w.middle.box -yscrollcommand "$w.middle.ys set" -font splainf -background white -relief flat -highlightthickness 0 -height 10 -width 20 -selectbackground gray
		scrollbar $w.middle.ys -command "$w.middle.box yview" -highlightthickness 0 -borderwidth 1 -elementborderwidth 2
		pack $w.middle.ys -side right -fill y
		pack $w.middle.box -side left -expand true -fill both

		pack $w.middle -side top -fill both -expand true

		if { [info exists ::amsnplus::config(quick_text)] } {

			foreach {key txt} $::amsnplus::config(quick_text) {
				$w.middle.box insert end "/$key -> $txt"
			}

		}

		frame $w.bottom
		button $w.bottom.close -text "[trans close]" -command "destroy .qtconfig"
		button $w.bottom.add -text "[trans add]" -command "::amsnplus::qtconfig_add"
		button $w.bottom.delete -text "[trans delete]" -command "::amsnplus::qtconfig_delete"

		pack $w.bottom.close -side right -padx 10 -pady 10
		pack $w.bottom.add -side left -padx 10 -pady 10
		pack $w.bottom.delete -side left -padx 10 -pady 10

		pack $w.bottom -side top -fill y -expand true

		moveinscreen $w 30

	}


	proc qtconfig_add { } {

		set w .qtconfig_add
		#Verify if the window is already opened
		if {[winfo exists $w]} {
			raise $w
			return
		}
		#Create the window
		toplevel $w -width 340 -height 270
		wm title $w "[trans quicktext]"

		frame $w.top

		frame $w.top.left
		frame $w.top.right

		label $w.top.txt -text "[trans edit]"
		pack $w.top.txt -side top

		frame $w.top.top
		label $w.top.top.amsnplusbutton -image [::skin::loadPixmap amsnplusbutton] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] \
			-activebackground [::skin::getKey buttonbarbg]
		button $w.top.top.boldbutton -text "B" -command "::amsnplus::insert_text $w [binary format c 2] $w.top.right.entry"
		button $w.top.top.italicbutton -text "I" -command "::amsnplus::insert_text $w [binary format c 5] $w.top.right.entry"
		button $w.top.top.overstrikebutton -text "S" -command "::amsnplus::insert_text $w [binary format c 6] $w.top.right.entry"
		button $w.top.top.underlinebutton -text "U" -command "::amsnplus::insert_text $w [binary format c 31] $w.top.right.entry"
		button $w.top.top.resetbutton -text "R" -command "::amsnplus::insert_text $w [binary format c 15] $w.top.right.entry"
		pack $w.top.top.amsnplusbutton -side left -padx 5
		pack $w.top.top.boldbutton -side left -padx 5
		pack $w.top.top.italicbutton -side left -padx 5
		pack $w.top.top.overstrikebutton -side left -padx 5
		pack $w.top.top.underlinebutton -side left -padx 5
		pack $w.top.top.resetbutton -side left -padx 5
		pack $w.top.top -side top

		label $w.top.left.txt -text "[trans keyword]"
		label $w.top.right.txt -text "[trans text]"
		pack $w.top.left.txt -side top
		pack $w.top.right.txt -side top

		entry $w.top.left.entry -background #FFFFFF
		entry $w.top.right.entry -background #FFFFFF
		pack $w.top.left.entry -side top
		pack $w.top.right.entry -side top

		pack $w.top.left -side left -fill x -expand true
		pack $w.top.right -side right -fill x -expand true

		pack $w.top -side top -fill x -expand true

		frame $w.bottom

		button $w.bottom.save -text "[trans save]" -command "::amsnplus::qtconfig_add_save"
		button $w.bottom.cancel -text "[trans cancel]" -command "destroy $w"
		pack $w.bottom.save -side right -padx 10 -padx 10
		pack $w.bottom.cancel -side right -padx 10 -padx 10

		pack $w.bottom -side top -fill x -expand true

	}


	proc qtconfig_add_save { } {

		set w .qtconfig_add

		set key [$w.top.left.entry get]
		set txt [$w.top.right.entry get]

		if { [string equal $key ""] || [string equal $txt ""] } {

		} else {
			set ::amsnplus::config(quick_text) [lappend ::amsnplus::config(quick_text) "$key" "$txt"]
			.qtconfig.middle.box insert end "/$key -> $txt"
			destroy $w
			::plugins::save_config
		}

	}


	proc qtconfig_delete { } {

		set w .qtconfig

		set selection [$w.middle.box curselection]

		if { $selection != "" } {
			.qtconfig.middle.box delete $selection $selection
			set selection [expr $selection * 2 ]
			set ::amsnplus::config(quick_text) [lreplace $::amsnplus::config(quick_text) $selection [expr $selection + 1]]
			::plugins::save_config
		}

	}

	####################################################
	# returns an rbg color with <num> code
	proc getColor { num default } {
		array set colors [list  0  "FFFFFF" \
					1  "000000" \
					2  "00007F" \
					3  "009300" \
					4  "FF0000" \
					5  "7F0000" \
					6  "9C009C" \
					7  "FC7F00" \
					8  "FFFF00" \
					9  "00FC00" \
					10 "009393" \
					11 "00FFFF" \
					12 "2020FC" \
					13 "FF00FF" \
					14 "7F7F7F" \
					15 "D2D2D2" \
					16 "E7E6E4" \
					17 "CFCDD0" \
					18 "FFDEA4" \
					19 "FFAEB9" \
					20 "FFA8FF" \
					21 "B4B4FC" \
					22 "BAFBE5" \
					23 "C1FFA3" \
					24 "FAFDA2" \
					25 "B6B4D7" \
					26 "A2A0A1" \
					27 "F9C152" \
					28 "FF6D66" \
					29 "FF62FF" \
					30 "6C6CFF" \
					31 "68FFC3" \
					32 "8EFF67" \
					33 "F9FF57" \
					34 "858482" \
					35 "6E6B7D" \
					36 "FFA01E" \
					37 "F92611" \
					38 "FF20FF" \
					39 "202BFF" \
					40 "1EFFA5" \
					41 "60F913" \
					42 "FFF813" \
					43 "5E6464" \
					44 "4B494C" \
					45 "D98812" \
					46 "EB0505" \
					47 "DE00DE" \
					48 "0000D3" \
					49 "03CC88" \
					50 "59D80D" \
					51 "D4C804" \
					52 "000268" \
					53 "18171C" \
					54 "944E00" \
					55 "9B0008" \
					56 "980299" \
					57 "01038C" \
					58 "01885F" \
					59 "389600" \
					60 "9A9E15" \
					61 "473400" \
					62 "4D0000" \
					63 "5F0162" \
					64 "000047" \
					65 "06502F" \
					66 "1C5300" \
					67 "544D05" ]
		if { [info exists colors($num)] } {
			return [set colors($num)]
		} else {
			return $default
		}
	}



	#//////////////////////////////////////////////////////////////////////////
	#                   MULTIPLE FORMATTING TEXT AND COLOR
	#//////////////////////////////////////////////////////////////////////////

	###############################################
	#This is the proc to be compatible with the new way
	#in 0.95 to get path of input text (::ChatWindow::GetInputText)
	proc insert_text {win character {input ""} } {
		if {[::amsnplus::amsn_version] <= 94} {
			$win.f.bottom.left.in.text insert end $character
		} else {
			#if we use tabs then...
			if { [::ChatWindow::UseContainer] == 1 } {
				set win [::ChatWindow::GetCurrentWindow $win]
			}
			if { [string equal $input ""] } {
				set input [::ChatWindow::GetInputText $win]
			}
			$input insert end $character
		}
	}

	###############################################
	# this adds a button to choose color for our
	# multi-color text in the chatwindow
	# now add buttons for multi-format text too
	proc chat_color_button {event epvar} {
		if { !$::amsnplus::config(allow_colours) } { return }

		#get the event vars
		upvar 2 evPar newvar
		set amsnplusbutton $newvar(bottom).amsnplus
		set w $newvar(window_name)

		#create the widgeds
		label $amsnplusbutton -image [::skin::loadPixmap amsnplusbutton] -relief flat -padx 3 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		set_balloon $amsnplusbutton "[trans multiplecolorsbutton]"

		#Configure hover button
		bind $amsnplusbutton <<Button1>> "after 1 ::amsnplus::choose_color $w"
		bind $amsnplusbutton <Enter> "$amsnplusbutton configure -image [::skin::loadPixmap amsnplusbutton_hover]"
		bind $amsnplusbutton <Leave> "$amsnplusbutton configure -image [::skin::loadPixmap amsnplusbutton]"

		#pack the widgeds
		pack $amsnplusbutton -side left
	}

	############################################
	# ::amsnplus::setPixmap                    #
	# -----------------------------------------#
	# Define the amsnplus pixmaps from the skin#
	############################################
	proc setPixmap {} {
			::skin::setPixmap amsnplusbutton amsnplusbutton.gif
			::skin::setPixmap amsnplusbutton_hover amsnplusbutton_hover.gif
	}

	###############################################
	# this opens a tk_color_palette to choose an
	# rgb color in (rrr,ggg,bbb) format
	# and insert the color code inside the input text
	proc choose_color { win {input ""} } {
		set color [tk_chooseColor -parent $win];
		if {[string equal $color ""]} { return }
		set color [::amsnplus::hexToRGB [string range $color 1 end]];
		set code "[binary format c 3]$color"
		if { [string equal $input ""] } {
			::amsnplus::insert_text $win $code
		} else {
			::amsnplus::insert_text $win $code $input
		}
	}

	###############################################
	# this colours received messages
	# there are two ways to colorize text:
	#   - preset colors -> (!FC<num>) or (!FG<num>) for background -> there are from 0 to 15
	#   - any colour -> (r,g,b) or (r,g,b),(r,g,b) to add background -> palette to choose (take a look at tk widgeds)
	proc parse_colours_and_sounds {event epvar} {
		if { !$::amsnplus::config(allow_colours) } { return }
		upvar 2 message msg
		upvar 2 chatid chatid
		if {[::amsnplus::amsn_version] <= 94} {
			set fontformat [::config::getKey mychatfont]
		} else {
			upvar 2 evPar newvar
			set fontformat $newvar(fontformat)
		}
		set color [lindex $fontformat 2]
		set style [lindex $fontformat 1]
		set font [lindex $fontformat 0]
		set strlen [string length $msg]
		set i 0
		while {$i<$strlen} {
			set char [string index $msg $i]
			if {[string equal $char [binary format c 2]]} {
				set msg [string replace $msg $i [expr $i - 1] ""]
				set strlen [string length $msg]
				set str [string range $msg 0 [expr $i - 1]]
				set slen [string length $str]
				set msg [string replace $msg 0 $slen ""]
				set i -1
				set strlen [string length $msg]
				set customfont [list $font $style $color]
				::amsn::WinWrite $chatid $str "user" $customfont
				set index [lsearch $style "bold"]
				if {![string equal "-1" $index]} {
					set style [lreplace $style $index $index]
				} else {
					set style [linsert $style end "bold"]
				}
			}
			if {[string equal $char [binary format c 4]]} {
				#predefined sounds
				set soundsdir [::config::getKey amsnpluspluginpath]/sounds
				set next_char [string index $msg [expr $i + 1]]
				if {[string equal "#" $next_char]} {
					play_sound $soundsdir/shello.wav
				} elseif {[string equal "E" $next_char]} {
					play_sound $soundsdir/sbye.wav
				} elseif {[string equal "!" $next_char]} {
					play_sound $soundsdir/sbrb.wav
				} elseif {[string equal "\$" $next_char]} {
					play_sound $soundsdir/sdoh.wav
				} elseif {[string equal "2" $next_char]} {
					play_sound $soundsdir/sboring.wav
				} elseif {[string equal "5" $next_char]} {
					play_sound $soundsdir/smad.wav
				} elseif {[string equal "9" $next_char]} {
					play_sound $soundsdir/somg.wav
				} elseif {[string equal "%" $next_char]} {
					play_sound $soundsdir/skiss.wav
				} elseif {[string equal "\"" $next_char]} {
					play_sound $soundsdir/sevillaugh.wav
				} elseif {[string equal "J" $next_char]} {
					play_sound $soundsdir/sevil.wav
				} elseif {[string equal "*" $next_char]} {
					play_sound $soundsdir/scomeon.wav
				} elseif {[string equal "L" $next_char]} {
					play_sound $soundsdir/sright.wav
				} elseif {[string equal "&" $next_char]} {
					play_sound $soundsdir/strek.wav
				} elseif {[string equal "@" $next_char]} {
					play_sound $soundsdir/sdanger.wav
				} elseif {[string equal "'" $next_char]} {
					play_sound $soundsdir/sapplause.wav
				} elseif {[string equal "+" $next_char]} {
					play_sound $soundsdir/swoow.wav
				} elseif {[string equal "," $next_char]} {
					play_sound $soundsdir/syawnt.wav
				}
				set msg [string replace $msg $i [expr $i + 1] ""]
				set i -1
			}
			if {[string equal $char [binary format c 5]]} {
				set msg [string replace $msg $i [expr $i - 1] ""]
				set strlen [string length $msg]
				set str [string range $msg 0 [expr $i - 1]]
				set slen [string length $str]
				set msg [string replace $msg 0 $slen ""]
				set i -1
				set strlen [string length $msg]
				set customfont [list $font $style $color]
				::amsn::WinWrite $chatid $str "user" $customfont
				set index [lsearch $style "italic"]
				if {![string equal "-1" $index]} {
					set style [lreplace $style $index $index]
				} else {
					set style [linsert $style end "italic"]
				}
			}
			if {[string equal $char [binary format c 31]]} {
				set msg [string replace $msg $i [expr $i - 1] ""]
				set strlen [string length $msg]
				set str [string range $msg 0 [expr $i - 1]]
				set slen [string length $str]
				set msg [string replace $msg 0 $slen ""]
				set i -1
				set strlen [string length $msg]
				set customfont [list $font $style $color]
				::amsn::WinWrite $chatid $str "user" $customfont
				set index [lsearch $style "underline"]
				if {![string equal "-1" $index]} {
					set style [lreplace $style $index $index]
				} else {
					set style [linsert $style end "underline"]
				}
			}
			if {[string equal $char [binary format c 6]]} {
				set msg [string replace $msg $i [expr $i - 1] ""]
				set strlen [string length $msg]
				set str [string range $msg 0 [expr $i - 1]]
				set slen [string length $str]
				set msg [string replace $msg 0 $slen ""]
				set i -1
				set strlen [string length $msg]
				set customfont [list $font $style $color]
				::amsn::WinWrite $chatid $str "user" $customfont
				set index [lsearch $style "overstrike"]
				if {![string equal "-1" $index]} {
					set style [lreplace $style $index $index]
				} else {
					set style [linsert $style end "overstrike"]
				}
			}
			if {[string equal $char [binary format c 15]]} {
				set msg [string replace $msg $i [expr $i - 1] ""]
				set strlen [string length $msg]
				set str [string range $msg 0 [expr $i - 1]]
				set slen [string length $str]
				set msg [string replace $msg 0 $slen ""]
				set i -1
				set strlen [string length $msg]
				set customfont [list $font $style $color]
				::amsn::WinWrite $chatid $str "user" $customfont
				set style [list]
			}
			if {[string equal $char [binary format c 3]]} {
				#predefined colors format
				if {[::amsnplus::is_a_number [string index $msg [expr $i + 1]]]} {
					if {[::amsnplus::is_a_number [string index $msg [expr $i + 2]]]} {
						set new_color [string range $msg [expr $i + 1] [expr $i + 2]]
						set msg [string replace $msg $i [expr $i + 1] ""]
						set strlen [string length $msg]
					} else {
						set new_color [string index $msg [expr $i + 1]]
						set msg [string replace $msg $i $i ""]
						set strlen [string length $msg]
					}
					set str [string range $msg 0 [expr $i - 1]]
					set slen [string length $str]
					set msg [string replace $msg 0 $slen ""]
					set i -1
					set strlen [string length $msg]
					set customfont [list $font $style $color]
					::amsn::WinWrite $chatid $str "user" $customfont
					if {$new_color < 68 && $new_color >= 0} {
						set color [::amsnplus::getColor $new_color $color]
					}
				#(rrr,ggg,bbb) format
				}  elseif {[::amsnplus::is_a_number [string range $msg [expr $i + 2] [expr $i + 4]]]} {
					if {[::amsnplus::is_a_number [string range $msg [expr $i + 6] [expr $i + 8]]]} {
						if {[::amsnplus::is_a_number [string range $msg [expr $i + 10] [expr $i + 12]]]} {
							set rgb [string range $msg [expr $i + 1] [expr $i + 12]]
							set msg [string replace $msg $i [expr $i + 12] ""]
							set strlen [string length $msg]
							set str [string range $msg 0 [expr $i - 1]]
							set slen [string length $str]
							set msg [string replace $msg 0 $slen ""]
							set i -1
							set strlen [string length $msg]
							set customfont [list $font $style $color]
							::amsn::WinWrite $chatid $str "user" $customfont
							set color [::amsnplus::RGBToHex $rgb]
						}
					}
				}
			}
			incr i
		}
		if {[::amsnplus::amsn_version] <= 94} {
			set customfont [list $font $style $color]
			::amsn::WinWrite $chatid $msg "user" $customfont
			set msg ""
		} else {
			set newvar(fontformat) [list $font $style $color]
		}
	}

	###############################################
	# this proc converts rgb colours into hex colours
	proc RGBToHex { colour } {
		scan $colour "(%3u,%3u,%3u)" red green blue
		return [format "%02X%02X%02X" \
			$red $green $blue]
	}

	################################################
	# this roc converts hex colours into rgb colours
	proc hexToRGB { colour } {
		scan $colour "%2x%2x%2x" red green blue
		return "($red,$green,$blue)"
	}

	#//////////////////////////////////////////////////////////////////////////
	#                            SENDING COMMANDS
	#//////////////////////////////////////////////////////////////////////////

	################################################
	# this proc add external commands to amsnplus
	# (useful for other plugins)
	proc add_command { keyword proc parameters {win_name 0} {chatid 0} } {
		set ::amsnplus::external_commands($keyword) [list $proc $parameters $win_name $chatid]
	}

	#####################################################
	# this looks chat text for a command
	# if found, executes what command is supposed to do
	proc parseCommand {event epvar} {
		if { !$::amsnplus::config(allow_commands) } { return 0 }
		upvar 2 nick nick
		upvar 2 msg msg
		upvar 2 chatid chatid
		upvar 2 win_name win_name
		upvar 2 fontfamily fontfamily
		upvar 2 fontcolor fontcolor
		upvar 2 fontstyle fontstyle
		set strlen [string length $msg]
		set sound [binary format c 4]
		set i 0

		if { [string equal [string index $msg 0] "/"] } {
			set char [::amsnplus::readWord $i $msg $strlen]
			#check for the quick texts
			if {$::amsnplus::config(allow_quicktext)} {
				foreach {key txt} $::amsnplus::config(quick_text) {
					if {[string equal $char "/$key"] && ![string equal $char "/"]} {
						set clen [string length $char]
						set msg [string replace $msg $i [expr $i + $clen] $txt]
						set strlen [string length $msg]
						set qtlen [string length $txt]
						set i [expr $i + $qtlen]
						return
					}
				}
			}
			#check for the external_commands
			set keyword [string replace $char 0 0 ""]
			if {[info exists ::amsnplus::external_commands($keyword)]} {
				set clen [string length $char]
				set msg [string replace $msg $i [expr $i + $clen]]
				set strlen [string length $msg]
				set kwdlist $::amsnplus::external_commands($keyword)
				set proc [lindex $kwdlist 0]
				set parameters [lindex $kwdlist 1]
				set values ""
				set j 0
				while { $j < $parameters } {
					set values [append values [::amsnplus::readWord $i $msg $strlen]]
					incr j
				}
				if {[string equal $values ""]} {
					if {[lindex $kwdlist 2]} {
						if {[lindex $kwdlist 3]} {
							$proc $win_name $chatid
						} else {
							$proc $win_name
						}
					} else {
						if {[lindex $kwdlist 3]} {
							$proc $chatid
						} else {
							$proc
						}
					}
				} else {
					if {[lindex $kwdlist 2]} {
						if {[lindex $kwdlist 3]} {
							$proc $win_name $chatid $values
						} else {
							$proc $win_name $values
						}
					} else {
						if {[lindex $kwdlist 3]} {
							$proc $chatid $values
						} else {
							$proc $values
						}
					}
				}
				set msg ""
			}
			#amsnplus commands
			if {[string equal $char "/all"]} {
				set msg [string replace $msg $i [expr $i + 4] ""]
				set strlen [string length $msg]
				foreach window $::ChatWindow::windows {
					set chat_id [::ChatWindow::Name $win_name]
					::amsn::MessageSend $window 0 $msg
				}
				set msg ""
			} elseif {[string equal $char "/shello"]} {
				set msg [append "" $sound "#" [binary format c 3] "7Hello!"]
			} elseif {[string equal $char "/sbye"]} {
				set msg [append "" $sound "E" [binary format c 3] "12Bye"]
			} elseif {[string equal $char "/sbrb"]} {
				set msg [append "" $sound "!" [binary format c 3] "10Be right back"]
			} elseif {[string equal $char "/sdoh"]} {
				set msg [append "" $sound "\$" [binary format c 3] "4I'm so " [binary format c 2] "stupid" [binary format c 2]]
			} elseif {[string equal $char "/sboring"]} {
				set msg [append  "" $sound "2" [binary format c 3] "5You're boring! :)"]
			} elseif {[string equal $char "/smad"]} {
				set msg [append "" $sound "5" [binary format c 3] "14Are you mad?!?"]
			} elseif {[string equal $char "/somg"]} {
				set msg [append "" $sound "9" [binary format c 3] "4Oh my " [binary format c 2] "God" [binary format c 2]]
			} elseif {[string equal $char "/skiss"]} {
				set msg [append "" $sound "%" [binary format c 3] "13XxxxXxxxX"]
			} elseif {[string equal $char "/sevillaugh"]} {
				set msg [append "" $sound "\"" [binary format c 3] "4Mua" [binary format c 3] "5ha" [binary format c 3] "4ha" [binary format c 3] "5ha" [binary format c 3] "4ha" [binary format c 3] "5!"]
			} elseif {[string equal $char "/sevil"]} {
				set msg [append "" $sound "J" [binary format c 3] "1:\[ :\[ :\["]
			} elseif {[string equal $char "/scomeon"]} {
				set msg [append "" $sound "*" [binary format c 3] "7Come on!"]
			} elseif {[string equal $char "/sright"]} {
				set msg [append "" $sound "L" [binary format c 3] "6Right..."]
			} elseif {[string equal $char "/strek"]} {
				set msg [append "" $sound "&" [binary format c 3] "12Live long and prosper"]
			} elseif {[string equal $char "/sdanger"]} {
				set msg [append "" $sound "@" [binary format c 3] "2My" [binary format c 3] "55patience " [binary format c 3] "2has its limits" [binary format c 3] "13..." ]
			} elseif {[string equal $char "/sapplause"]} {
				set msg [append "" $sound "'(h5)(h5)(h5)(h5)(h5)"]
			} elseif {[string equal $char "/swoow"]} {
				set msg [append "" $sound "+" [binary format c 3] "45" [binary format c 2] "Wooooow!"]
			} elseif {[string equal $char "/syawn"]} {
				set msg [append "" $sound "," [binary format c 3] "57I'm tired |-)"]
			} elseif {[string equal $char "/screenshot"]} {
				set msg [string replace $msg $i [expr $i + 11] ""]
				set strlen [string length $msg]
				global HOME
				set shotpng [file join $HOME "screenshot.png"]
				set time_wait [::amsnplus::readWord $i $msg $strlen]

				#wait if asked
				if {![string equal $time_wait ""]} {
					after [expr $time_wait*1000]
				}

				#check platform and use utility form this one
				global tcl_platform
				if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
					set file ""
				} elseif {$tcl_platform(platform) == "windows"} {
					set shotbmp [file nativename [file join $HOME "screenshot.bmp"]]
					plugins_log "aMSN Plus" "BMP is $shotbmp"	
					if { [catch {exec [file join [::config::getKey amsnpluspluginpath] "snapshot.exe"] "$shotbmp"} res] } {
						plugins_log "aMSN Plus"  "execution failed : $res"
						set file ""
					}
					set file [::picture::Convert $shotbmp $shotpng]
					file delete $shotbmp
				} elseif {$tcl_platform(platform) == "unix"} {
					set file "$shotpng"
					if { [catch {exec [file join [::config::getKey amsnpluspluginpath] "snapshot"] "$shotpng"} res] } {
						plugins_log "aMSN Plus"  "execution failed : $res"
						set file ""
					}
				}

				#send the scheenshot if it had been done!
				if {![string equal $file ""]} {
					::amsn::FileTransferSend $win_name $file
				} else {
					::amsnplus::write_window $chatid "[trans screenshoterr]"
				}
				set msg ""
			} elseif {[string equal $char "/add"]} {
				set msg [string replace $msg $i [expr $i + 4] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				::MSN::addUser $userlogin
			} elseif {[string equal $char "/addgroup"]} {
				set msg [string replace $msg $i [expr $i + 9] ""]
				set strlen [string length $msg]
				set groupname $msg
				set msg ""
				::groups::Add $groupname
				if {[::amsnplus::amsn_version] <= 94} {
					::amsnplus::write_window $chatid "\nAdded group $groupname" 0
				} else {
					::amsnplus::write_window $chatid "[trans groupadded $groupname]" 0
				}
			} elseif {[string equal $char "/block"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				set nick [::abook::getNick $user_login]
				::MSN::blockUser $user_login [urlencode $nick]
			} elseif {[string equal $char "/clear"]} {
				set container [split ::$ChatWindow::msg_windows($chatid) "."]
				set container ".[lindex $container 1]"
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				if { [::ChatWindow::UseContainer] } {
					set chat_win $container
				} else {
					set chat_win $::ChatWindow::msg_windows($chatid)
				}
				::ChatWindow::Clear $chat_win
			} elseif {[string equal $char "/delete"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				::MSN::deleteUser $user_login
				if {[::amsnplus::amsn_version] <= 94} {
					::amsnplus::write_window $chatid "\nDeleted contact $user_login" 0
				} else {
					::amsnplus::write_window $chatid "[trans groupdeleted $user_login]" 0
				}
			} elseif {[string equal $char "/deletegroup"]} {
				set msg [string replace $msg $i [expr $i + 12] ""]
				set strlen [string length $msg]
				set groupname $msg
				set msg ""
				::groups::Delete [::groups::GetId $groupname]
				if {[::amsnplus::amsn_version] <= 94} {
					::amsnplus::write_window $chatid "\nDeleted group $groupname" 0
				} else {
					::amsnplus::write_window $chatid "[trans groupdeleted $groupname]" 0
				}
			} elseif {[string equal $char "/help"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set help [::amsnplus::help]
				::amsnplus::write_window $chatid "\n$help" 0
			} elseif {[string equal $char "/info"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set field [::amsnplus::readWord $i $msg $strlen]
				set lfield [string length $field]
				set msg [string replace $msg $i [expr $i + $lfield] ""]
				set strlen [string length $msg]
				if {[string equal $field "color"]} {
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\nYour color is: $fontcolor" 0
					} else {
						::amsnplus::write_window $chatid "[trans ccolor $fontcolor]" 0
					}
				} elseif {[string equal $field "font"]} {
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\nYour font is: $fontfamily" 0
					} else {
						::amsnplus::write_window $chatid "[trans cfont $fontfamily]" 0
					}
				} elseif {[string equal $field "nick"]} {
					set nick [::abook::getPersonal nick]
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\nYour nick is: $nick" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnick $nick]" 0
					}
				} elseif {[string equal $field "state"]} {
					set status [::MSN::myStatusIs]
					set status [::MSN::stateToDescription $status]
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\nYour status is: $status" 0
					} else {
						::amsnplus::write_window $chatid "[trans cstatus $status]" 0
					}
				} elseif {[string equal $field "style"]} {
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\nYour style is: $fontstyle" 0
					} else {
						::amsnplus::write_window $chatid "[trans cstyle $fontstyle]" 0
					}
				}
			} elseif {[string equal $char "/invite"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				::MSN::inviteUser $chatid $userlogin
			} elseif {[string equal $char "/kill"]} {
				set msg ""
				close_cleanup;exit
			} elseif {[string equal $char "/leave"]} {
				set msg ""
				::MSN::leaveChat $chatid
				if {[::amsnplus::amsn_version] <= 94} {
					::amsnplus::write_window $chatid "\nYou've left this conversation" 0
				} else {
					::amsnplus::write_window $chatid "[trans cleave]" 0
				}
			} elseif {[string equal $char "/login"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				::MSN::connect
			} elseif {[string equal $char "/logout"]} {
				set msg ""
				::MSN::logout
			} elseif {[string equal $char "/nick"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set nick $msg
				set nlen [string length $nick]
				set msg ""
				if {[info args ::MSN::changeName] == [list "newname" "update"] } {
					::MSN::changeName $nick
				} else {
					::MSN::changeName [::config::getKey login] $nick
				}
				if {[string equal $::version "0.95"]} {
					::amsnplus::write_window $chatid "[trans cnewnick $nick]" 0
				} else {
					::amsnplus::write_window $chatid "\nYour new nick is: $nick" 0
				}
			} elseif {[string equal $char "/pm"]} {
			set msg [string replace $msg $i [expr $i + 3] ""]
			if { [::config::getKey protocol] >= 11} {
				if { [string length $msg] > 130} {
					set answer [::amsn::messageBox [trans longpsm] yesno question [trans confirm]]
					if { $answer == "no" } {
						set msg ""
						return
					}
				}			
				::MSN::changePSM $msg
				::amsnplus::write_window $chatid "\n[trans newpsm $msg]" 0
				set msg ""
			}
			} elseif {[string equal $char "/pm0"]} {
			if { [::config::getKey protocol] >= 11} {
				::MSN::changePSM ""
				::amsnplus::write_window $chatid "\n[trans newpsmnone]" 0
				set msg ""
			}
			} elseif {[string equal $char "/qtconfig"]} {
				set msg [string replace $msg $i [expr $i + 9] ""]
				set strlen [string length $msg]
				::amsnplus::qtconfig
			} elseif {[string equal $char "/sendfile"]} {
				set msg [string replace $msg $i [expr $i + 9] ""]
				set strlen [string length $msg]
				set file [::amsnplus::readWord $i $msg $strlen]
				if {[string equal $file ""]} {
					::amsn::FileTransferSend $win_name
				}
				if {![string equal $file ""]} {
					::amsn::FileTransferSend $win_name $file
				}
				set msg ""
			} elseif {[string equal $char "/shell"]} {
				set command [string replace $msg $i [expr $i + 6] ""]
				set msg ""
				if {[::amsnplus::amsn_version] <= 94} {
					::amsnplus::write_window $chatid "\nExecuting: $command" 0
				} else {
					::amsnplus::write_window $chatid "[trans cshell $command]" 0
				}
				set command [linsert [split $command " "] 0 "exec" "--"]
				if {[catch { eval $command } result]} {
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\nYour command is not valid\n$result" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnotvalid]\n$result" 0
					}
				} else {
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\nThis is the result of the command:\n$result" 0
					} else {
						::amsnplus::write_window $chatid "[trans cresult $result]" 0
					}
				}
			} elseif {[string equal $char "/shells"]} {
				set command [string replace $msg $i [expr $i + 7] ""]
				set msg ""
				if {[::amsnplus::amsn_version] <= 94} {
					::amsnplus::write_window $chatid "\nExecuting: $command" 0
				} else {
					::amsnplus::write_window $chatid "[trans cshell $command]" 0
				}
				set command [linsert [split $command " "] 0 "exec" "--"]
				if {[catch { eval $command } result]} {
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\nYour command is not valid\n$result" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnotvalid]\n$result" 0
					}
				} else {
					set msg $result
				}
			} elseif {[string equal $char "/speak"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				set strlen [string length $msg]
				::amsn::chatUser $userlogin
			} elseif {[string equal $char "/state"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set nstate [::amsnplus::readWord $i $msg $strlen]
				set slen [string length $nstate]
				set msg [string replace $msg $i [expr $i + $slen]]
				set strlen [string length $nick]
				if {[::amsnplus::stateIsValid $nstate]} {
					set cstate [::amsnplus::descriptionToState $nstate]
					::MSN::changeStatus $cstate
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\nNew state is: $nstate" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnewstate $nstate]" 0
					}
				} else {
					if {[::amsnplus::amsn_version] <= 94} {
						::amsnplus::write_window $chatid "\n$nstate is not valid" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnewstatenotvalid $nstate]" 0
					}
				}
			} elseif {[string equal $char "/unblock"]} {
				set msg [string replace $msg $i [expr $i + 8] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				set nick [::abook::getNick ${user_login}]
				::MSN::unblockUser ${user_login} [urlencode $nick]
			} elseif {[string equal $char "/whois"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				if {[string equal $user_login ""] || [string equal [::abook::getContactData $user_login nick] ""]} {
					set user_login [::ChatWindow::Name $win_name]
				}
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				set group [::groups::GetName [::abook::getContactData $user_login group]]
				set nick [::abook::getContactData $user_login nick]
				set client [::abook::getContactData $user_login clientname]
				set os [::abook::getContactData $user_login operatingsystem]
				if {[::amsnplus::amsn_version] <= 94} {
					::amsnplus::write_window $chatid "\n$user_login info: $nick $group $client $os" 0
				} else {
					::amsnplus::write_window $chatid "[trans cinfo $user_login $nick $group $client $os]" 0
				}
			} else {
				::amsnplus::write_window $chatid "[trans nosuchcommand $char]"
				set msg ""
			}
		}
	}

}
