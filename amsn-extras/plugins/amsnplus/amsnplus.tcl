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
		if {![::amsnplus::version_094]} {
			set langdir [append dir "/lang"]
			set lang [::config::getGlobalKey language]
			load_lang en $langdir
			load_lang $lang $langdir
		}
		#plugin config
		if {[::amsnplus::version_094]} {
			array set ::amsnplus::config {
				parse_nicks 1
				colour_nicks 0
				allow_commands 1
				allow_quicktext 1
			}
			set ::amsnplus::configlist [ list \
				[list bool "Do you want to parse nicks?" parse_nicks] \
				[list bool "Do you want to colour nicks? (not fully feature)" colour_nicks] \
				[list bool "Do you want to allow commands in the chat window?" allow_commands] \
				[list bool "Do you want to use the quick text feature?" allow_quicktext] \
				
			]
		} else {
			array set ::amsnplus::config {
				parse_nicks 1
				colour_nicks 0
				allow_commands 1
				allow_colours 1
				allow_quicktext 1
			}
			set ::amsnplus::configlist [ list \
				[list bool "[trans parsenicks]" parse_nicks] \
				[list bool "[trans colournicks]" colour_nicks] \
				[list bool "[trans allowcommands]" allow_commands] \
				[list bool "[trans allowcolours]" allow_colours] \
				[list bool "[trans allowquicktext]" allow_quicktext] \
			]
		}

		#creating the menus
		catch { after 100 ::amsnplus::add_plus_menu }
		catch { after 100 ::amsnplus::add_chat_menu }

		#register events
		::plugins::RegisterEvent "aMSN Plus" parse_nick parse_nick
		::plugins::RegisterEvent "aMSN Plus" chat_msg_send parseCommand
		::plugins::RegisterEvent "aMSN Plus" chat_msg_receive parse_colours_and_sounds
		::plugins::RegisterEvent "aMSN Plus" chatwindowbutton chat_color_button
		::plugins::RegisterEvent "aMSN Plus" chatmenu edit_menu
		
		if {![::amsnplus::version_094]} {
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

	####################################################
	# this proc removes every menu in every chat window
	# and also the pixmap of amsnplus to choose a color
	proc remove_from_chatwindow { } {
		#the path of the menu is always $w.menu
		foreach win $::ChatWindow::windows {
			if { [::ChatWindow::UseContainer] } {
				set win [split $win .]
				set win ".[lindex $win 1]"
			}
			catch { ${win}.menu delete last }
		}
	}



	#//////////////////////////////////////////////////////////////
	#            PLUS MENUS AND PREFERENCES
	#//////////////////////////////////////////////////////////////
	
	####################################################
	# creates the plus sub menu in the main gui menu
	proc add_plus_menu { } {
		catch {
			menu .main_menu.plusmenu -tearoff 0
			set plusmenu .main_menu.plusmenu

			#entries for the plus menu
			$plusmenu add command -label "[trans quicktext]" -command "::amsnplus::qtconfig"
			#$plusmenu add command -label "[trans preferences]" -command "::amsnplus::preferences"
		}
		.main_menu add cascade -label "Plus!" -menu .main_menu.plusmenu
	}

	###############################################
	# creates the menu on opened chats
	proc add_chat_menu { } {
		foreach win $::ChatWindow::windows {
			if { [::ChatWindow::UseContainer] } {
				set win [split $win .]
				set win ".[lindex $win 1]"
			}
			
			set bold [binary format c 2]
			set italic [binary format c 5]
			set underline [binary format c 31]
			set overstrike [binary format c 6]
			set reset [binary format c 15]
			set screenshot "/screenshot"
			#I think the catch is useless but it's in case someone close a chatwindow very fast, then we won't have a stupid bugreport
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
			catch { ${win}.menu add cascade -label "Plus!" -menu ${win}.menu.plusmenu }
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

	###############################################
	# this proc creates the preferences window
	proc preferences { } {
	}



	#//////////////////////////////////////////////////////////////////////////
	#                      GENERAL PURPOSE PROCEDURES
	#//////////////////////////////////////////////////////////////////////////

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
		if {[string equal $newstate "rightback"]} { return "BSY" }
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
		if {[::amsnplus::version_094]} {
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
		button $w.top.top.amsnplusbutton -image [::skin::loadPixmap amsnplusbutton] -relief flat -padx 3 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] \
			-command "after 1 ::amsnplus::choose_color $w $w.top.right.entry" -activebackground [::skin::getKey buttonbarbg]
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


	#//////////////////////////////////////////////////////////////////////////
	#                       PARSING AND COLORING NICKS
	#//////////////////////////////////////////////////////////////////////////

	################################################
	# this proc deletes $<num> codification
	# and colours nick if enabled
	# should parse ALSO MULTIPLE COLORS $(num,num,num)
	proc parse_nick {event epvar} {
		if {!$::amsnplus::config(parse_nicks)} {return}
		upvar 2 data data user_login user_login user_data user_data
		set strlen [string length $data]
		set i 0
		while {$i < $strlen} {
			set str [string range $data $i [expr $i + 1]]
			if {[string equal $str "·\$"]} {
				if {$::amsnplus::config(colour_nicks)} {
					if {[string equal [string index $data [expr $i + 2]] "#"]} {
						#The color is in RGB
						set last [expr $i + 8]

						set color [string tolower [string range $data [expr $i + 2] $last]]
						set user_data(customcolor) $color
					} else {
					#know if the number has 1 or 2 digits
					set last [expr $i + 3]
					set char [string index $data [expr $i + 3]]
					if {![::amsnplus::is_a_number $char]} {
						set last [expr $i + 2]
					}
					#obtain rbg color
					
						set num [string range $data [expr $i + 2] $last]
						set user_data(customcolor) [::amsnplus::getColor $num [::abook::getContactData $user_login customcolor]]
					}
					set data [string replace $data $i $last ""]
				} else {
					set last [expr $i + 3]
					set char [string index $data [expr $i + 3]]
					if {![::amsnplus::is_a_number $char]} {
						set last [expr $i + 2]
					}

					set data [string replace $data $i $last ""]
				}
			} elseif {[string equal $str "·\#"]} {
				#Bold text : as we can't render, we only remove
				set data [string replace $data $i [expr $i + 1] ""]
			} elseif {[string equal $str "·0"]} {
				#End of styles : as we render color for all the line and not bold, we only remove
				set data [string replace $data $i [expr $i + 1] ""]
			} else {
				incr i
			}
		}
	}
	
	####################################################
	# returns an rbg color with <num> code
	proc getColor { num default } {
		if {[string equal $num "0"]} {return "FFFFFF"}
		if {[string equal $num "1"]} {return "000000"}
		if {[string equal $num "2"]} {return "00FF00"}
		if {[string equal $num "3"]} {return "0000FF"}
		if {[string equal $num "4"]} {return "FF0000"}
		return $default
	}
	
	
	
	#//////////////////////////////////////////////////////////////////////////
	#                   MULTIPLE FORMATTING TEXT AND COLOR
	#//////////////////////////////////////////////////////////////////////////

	###############################################
	#This is the proc to be compatible with the new way 
	#in 0.95 to get path of input text (::ChatWindow::GetInputText)
	proc insert_text {win character {input ""} } {
		if {[::amsnplus::version_094]} {
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
		button $amsnplusbutton -image [::skin::loadPixmap amsnplusbutton] -relief flat -padx 3 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] \
			-command "after 1 ::amsnplus::choose_color $w" -activebackground [::skin::getKey buttonbarbg]
		set_balloon $amsnplusbutton "[trans multiplecolorsbutton]"

		#Configure hover button
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
		set color [::amsnplus::hexToRGB [string replace $color 0 0 ""]];
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
		if {[::amsnplus::version_094]} {
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
					if {$new_color < 15} {
						set color [::amsnplus::RGBToHex [::amsnplus::colourToRGB $new_color]]
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
		set customfont [list $font $style $color]
		::amsn::WinWrite $chatid $msg "user" $customfont
		set msg ""
	}

	###############################################
	# converts decimal digit into hex
	proc digitToHex { digit } {
		if {[string equal $digit "10"]} {
			return "a"
		} elseif {[string equal $digit "11"]} {
			return "b"
		} elseif {[string equal $digit "12"]} {
			return "c"
		} elseif {[string equal $digit "13"]} {
			return "d"
		} elseif {[string equal $digit "14"]} {
			return "e"
		} elseif {[string equal $digit "15"]} {
			return "f"
		} else { return $digit }
	}

	###############################################
	# converts decimal number into hex
	proc decToHex { number } {
		set hex ""
		while { $number > 16 } {
			set rest [expr $number % 16]
			set number [expr $number / 16]
			set rest [::amsnplus::digitToHex $rest]
			set hex "$hex$rest"
		}
		set number [::amsnplus::digitToHex $number]
		set hex "$hex$number"
		set hlen [expr [string length $hex] -1]
		set reversed_hex ""
		while {$hlen >= 0} {
			set reversed_hex "$reversed_hex[string index $hex $hlen]"
			set hlen [expr $hlen - 1]
		}
		if {[string length $reversed_hex] > 2} {
			set reversed_hex [string range $reversed_hex 1 2]
		}
		return $reversed_hex
	}

	###############################################
	# this proc converts rgb colours into hex colours
	proc RGBToHex { colour } {
		set red [::amsnplus::decToHex [string range $colour 1 3]]
		set green [::amsnplus::decToHex [string range $colour 5 7]]
		set blue [::amsnplus::decToHex [string range $colour 9 11]]
		set dec_colour "$red$green$blue"
		return $dec_colour
	}

	################################################
	# converts hex digit into decimal
	proc hexToDigit { digit } {
		if {[string equal $digit "a"]} {
			return "10"
		} elseif {[string equal $digit "b"]} {
			return "11"
		} elseif {[string equal $digit "c"]} {
			return "12"
		} elseif {[string equal $digit "d"]} {
			return "13"
		} elseif {[string equal $digit "e"]} {
			return "14"
		} elseif {[string equal $digit "f"]} {
			return "15"
		} else { return $digit }
	}

	################################################
	# converts hex number into decimal
	proc hexToDec { number } {
		set low [::amsnplus::hexToDigit [string index $number 1]]
		set high [::amsnplus::hexToDigit [string index $number 0]]
		set number [expr $high * 16]
		set number [expr $number + $low]
		if {[string length $number] == 1} {
			set number "0$number"
		}
		if {[string length $number] == 2} {
			set number "0$number"
		}
		return $number
	}

	################################################
	# this roc converts hex colours into rgb colours
	proc hexToRGB { colour } {
		set red [::amsnplus::hexToDec [string range $colour 0 1]]
		set green [::amsnplus::hexToDec [string range $colour 2 3]]
		set blue [::amsnplus::hexToDec [string range $colour 4 5]]
		set colour "($red,$green,$blue)"
		return $colour
	}

	################################################
	# this proc converts msn plus predef. colours
	# into rgb colours
	proc colourToRGB { colour } {
		if {[string equal $colour "0"]} {
			return "(255,255,255)"
		} elseif {[string equal $colour "1"]} {
			return "(000,000,000)"
		} elseif {[string equal $colour "2"]} {
			return "(000,000,255)"
		} elseif {[string equal $colour "3"]} {
			return "(000,255,000)"
		} elseif {[string equal $colour "4"]} {
			return "(255,000,000)"
		} elseif {[string equal $colour "5"]} {
			return "(127,000,000)"
		} elseif {[string equal $colour "6"]} {
			return "(156,000,156)"
		} elseif {[string equal $colour "7"]} {
			return "(252,127,000)"
		} elseif {[string equal $colour "8"]} {
			return "(255,255,000)"
		} elseif {[string equal $colour "9"]} {
			return "(000,252,000)"
		} elseif {[string equal $colour "10"]} {
			return "(000,147,147)"
		} elseif {[string equal $colour "11"]} {
			return "(000,255,255)"
		} elseif {[string equal $colour "12"]} {
			return "(000,000,252)"
		} elseif {[string equal $colour "13"]} {
			return "(255,000,255)"
		} elseif {[string equal $colour "14"]} {
			return "(127,127,127)"
		} elseif {[string equal $colour "15"]} {
			return "(210,210,210)"
		} else {
			return "(000,000,000)"
		}
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
		set incr 1
		while {$i<$strlen} {
			set char [::amsnplus::readWord $i $msg $strlen]
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
						}					}
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
				set strlen 0
				set incr 0
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
				set strlen 0
				set incr 0
			} elseif {[string equal $char "/shello"]} {
				set msg [append "" $sound "#" [binary format c 3] "7Hello!"]
				set incr 0
			} elseif {[string equal $char "/sbye"]} {
				set msg [append "" $sound "E" [binary format c 3] "12Bye"]
				set incr 0
			} elseif {[string equal $char "/sbrb"]} {
				set msg [append "" $sound "!" [binary format c 3] "10Be right back"]
				set incr 0			
			} elseif {[string equal $char "/sdoh"]} {
				set msg [append "" $sound "\$" [binary format c 3] "4I'm so " [binary format c 2] "stupid" [binary format c 2]]
				set incr 0
			} elseif {[string equal $char "/sboring"]} {
				set msg [append  "" $sound "2" [binary format c 3] "5You're boring! :)"]
				set incr 0
			} elseif {[string equal $char "/smad"]} {
				set msg [append "" $sound "5" [binary format c 3] "14Are you mad?!?"]
				set incr 0
			} elseif {[string equal $char "/somg"]} {
				set msg [append "" $sound "9" [binary format c 3] "4Oh my " [binary format c 2] "God" [binary format c 2]]
				set incr 0
			} elseif {[string equal $char "/skiss"]} {
				set msg [append "" $sound "%" [binary format c 3] "13XxxxXxxxX"]
				set incr 0
			} elseif {[string equal $char "/sevillaugh"]} {
				set msg [append "" $sound "\"" [binary format c 3] "4Mua" [binary format c 3] "5ha" [binary format c 3] "4ha" [binary format c 3] "5ha" [binary format c 3] "4ha" [binary format c 3] "5!"]
				set incr 0
			} elseif {[string equal $char "/sevil"]} {
				set msg [append "" $sound "J" [binary format c 3] "1:\[ :\[ :\["]
				set incr 0
			} elseif {[string equal $char "/scomeon"]} {
				set msg [append "" $sound "*" [binary format c 3] "7Come on!"]
				set incr 0
			} elseif {[string equal $char "/sright"]} {
				set msg [append "" $sound "L" [binary format c 3] "6Right..."]
				set incr 0
			} elseif {[string equal $char "/strek"]} {
				set msg [append "" $sound "&" [binary format c 3] "12Live long and prosper"]
				set incr 0
			} elseif {[string equal $char "/sdanger"]} {
				set msg [append "" $sound "@" [binary format c 3] "2My" [binary format c 3] "55patience " [binary format c 3] "2has its limits" [binary format c 3] "13..." ]
				set incr 0
			} elseif {[string equal $char "/sapplause"]} {
				set msg [append "" $sound "'(h5)(h5)(h5)(h5)(h5)"]
				set incr 0
			} elseif {[string equal $char "/swoow"]} {
				set msg [append "" $sound "+" [binary format c 3] "45" [binary format c 2] "Wooooow!"]
				set incr 0
			} elseif {[string equal $char "/syawn"]} {
				set msg [append "" $sound "," [binary format c 3] "57I'm tired |-)"]
				set incr 0
			} elseif {[string equal $char "/screenshot"]} {
				set msg [string replace $msg $i [expr $i + 11] ""]
				set strlen [string length $msg]
				global HOME
				set shot [append "" $HOME "/screenshot.wxd"]
				set time_wait [::amsnplus::readWord $i $msg $strlen]
				
				#wait if asked
				if {![string equal $time_wait ""]} {
					after [expr $time_wait*1000] 
				}
				
				#check platform and use utility form this one
				global tcl_platform
				status_log $tcl_platform(platform)
				if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
					set file ""
				} elseif {$tcl_platform(platform) == "windows"} {
					set file ""
				} elseif {$tcl_platform(platform) == "unix"} {
					exec xwd -out -root $shot
					set file [run_convert "$shot" "screenshot.png"]
				}
				
				#send the scheenshot if it had been done!
				if {![string equal $file ""]} {
					::amsn::FileTransferSend $win_name $file
					set msg ""
				} else { 
					set msg "You aren't not able to make screenshot! Sorry"
				}
				set strlen 0
				set incr 0
			} elseif {[string equal $char "/add"]} {
				set msg [string replace $msg $i [expr $i + 4] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				::MSN::addUser $userlogin
				set incr 0
			} elseif {[string equal $char "/addgroup"]} {
				set msg [string replace $msg $i [expr $i + 9] ""]
				set strlen [string length $msg]
				set groupname $msg
				set msg ""
				set strlen 0
				::groups::Add $groupname
				if {[::amsnplus::version_094]} {
					::amsnplus::write_window $chatid "\nAdded group $groupname" 0
				} else {
					::amsnplus::write_window $chatid "[trans groupadded $groupname]" 0
				}
				set incr 0
			} elseif {[string equal $char "/block"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				set nick [::abook::getNick $user_login]
				::MSN::blockUser $user_login [urlencode $nick]
				set incr 0
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
				set incr 0
			} elseif {[string equal $char "/color"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set fontcolor [::amsnplus::readWord $i $msg $strlen]
				::config::setKey mychatfont "$fontfamily $fontstyle $fontcolor"
				set flen [string length $fontcolor]
				set msg [string replace $msg $i [expr $i + $flen] ""]
				set strlen [string length $msg]
				set incr 0
			} elseif {[string equal $char "/config"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				Preferences
				set incr 0
			} elseif {[string equal $char "/delete"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				::MSN::deleteUser $user_login
				if {[::amsnplus::version_094]} {
					::amsnplus::write_window $chatid "\nDeleted contact $user_login" 0
				} else {
					::amsnplus::write_window $chatid "[trans groupdeleted $user_login]" 0
				}
				set incr 0
			} elseif {[string equal $char "/deletegroup"]} {
				set msg [string replace $msg $i [expr $i + 12] ""]
				set strlen [string length $msg]
				set groupname $msg
				set msg ""
				set strlen 0
				::groups::Delete [::groups::GetId $groupname]
				if {[::amsnplus::version_094]} {
					::amsnplus::write_window $chatid "\nDeleted group $groupname" 0
				} else {
					::amsnplus::write_window $chatid "[trans groupdeleted $groupname]" 0
				}
				set incr 0
			} elseif {[string equal $char "/font"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set fontfamily [::amsnplus::readWord $i $msg $strlen]
				::config::setKey mychatfont "$fontfamily $fontstyle $fontcolor"
				set flen [string length $fontfamily]
				set msg [string replace $msg $i [expr $i + $flen] ""]
				set strlen [string length $msg]
				set incr 0
			} elseif {[string equal $char "/help"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set help [::amsnplus::help]
				::amsnplus::write_window $chatid "\n$help" 0
				set incr 0
			} elseif {[string equal $char "/info"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set field [::amsnplus::readWord $i $msg $strlen]
				set lfield [string length $field]
				set msg [string replace $msg $i [expr $i + $lfield] ""]
				set strlen [string length $msg]
				if {[string equal $field "color"]} {
					if {[::amsnplus::version_094]} {
						::amsnplus::write_window $chatid "\nYour color is: $fontcolor" 0
					} else {
						::amsnplus::write_window $chatid "[trans ccolor $fontcolor]" 0
					}
				} elseif {[string equal $field "font"]} {
					if {[::amsnplus::version_094]} {
						::amsnplus::write_window $chatid "\nYour font is: $fontfamily" 0
					} else {
						::amsnplus::write_window $chatid "[trans cfont $fontfamily]" 0
					}
				} elseif {[string equal $field "nick"]} {
					set nick [::abook::getPersonal nick]
					if {[::amsnplus::version_094]} {
						::amsnplus::write_window $chatid "\nYour nick is: $nick" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnick $nick]" 0
					}
				} elseif {[string equal $field "state"]} {
					set status [::MSN::myStatusIs]
					set status [::MSN::stateToDescription $status]
					if {[::amsnplus::version_094]} {
						::amsnplus::write_window $chatid "\nYour status is: $status" 0
					} else {
						::amsnplus::write_window $chatid "[trans cstatus $status]" 0
					}
				} elseif {[string equal $field "style"]} {
					if {[::amsnplus::version_094]} {
						::amsnplus::write_window $chatid "\nYour style is: $fontstyle" 0
					} else {
						::amsnplus::write_window $chatid "[trans cstyle $fontstyle]" 0
					}
				}
				set incr 0
			} elseif {[string equal $char "/invite"]} {
				set msg [string replace $msg $i [expr $i + 7] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				::MSN::inviteUser $chatid $userlogin
				set incr 0
			} elseif {[string equal $char "/kill"]} {
				set msg ""
				set strlen 0
				close_cleanup;exit
			} elseif {[string equal $char "/leave"]} {
				set msg ""
				set strlen 0
				::MSN::leaveChat $chatid
				if {[::amsnplus::version_094]} {
					::amsnplus::write_window $chatid "\nYou've left this conversation" 0
				} else {
					::amsnplus::write_window $chatid "[trans cleave]" 0
				}
				set incr 0
			} elseif {[string equal $char "/login"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				::MSN::connect
				set incr 0
			} elseif {[string equal $char "/logout"]} {
				set msg ""
				set strlen 0
				::MSN::logout
				set incr 0
			} elseif {[string equal $char "/nick"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				set strlen [string length $msg]
				set nick $msg
				set nlen [string length $nick]
				set msg ""
				set strlen 0
				::MSN::changeName [::config::getKey login] $nick
				if {[string equal $::version "0.95"]} {
					::amsnplus::write_window $chatid "[trans cnewnick $nick]" 0
				} else {
					::amsnplus::write_window $chatid "\nYour new nick is: $nick" 0
				}
				set incr 0
			} elseif {[string equal $char "/qtconfig"]} {
				set msg [string replace $msg $i [expr $i + 9] ""]
				set strlen [string length $msg]
				::amsnplus::qtconfig
				set incr 0
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
				set strlen 0
				set incr 0
			} elseif {[string equal $char "/shell"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set command $msg
				set msg ""
				set strlen 0
				set catch [catch {exec $command}]
				if {[::amsnplus::version_094]} {
					::amsnplus::write_window $chatid "\nExecuting: $command" 0
				} else {
					::amsnplus::write_window $chatid "[trans cshell $command]" 0
				}
				if {[string equal $catch "1"]} {
					if {[::amsnplus::version_094]} {
						::amsnplus::write_window $chatid "\nYour command is not valid" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnotvalid]" 0
					}
				} else {
					if {[::amsnplus::version_094]} {
						::amsnplus::write_window $chatid "\nThis is the result of the command:\n$catch" 0
					} else {
						::amsnplus::write_window $chatid "[trans cresult $catch]" 0
					}
				}
				set incr 0
			} elseif {[string equal $char "/speak"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set userlogin [::amsnplus::readWord $i $msg $strlen]
				set llen [string length $userlogin]
				set msg [string replace $msg $i [expr $i + $llen] ""]
				set strlen [string length $msg]
				::amsn::chatUser $userlogin
				set incr 0
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
					if {[::amsnplus::version_094]} {
						::amsnplus::write_window $chatid "\nNew state is: $nstate" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnewstate $nstate]" 0
					}
				} else {
					if {[::amsnplus::version_094]} {
						::amsnplus::write_window $chatid "\n$nstate is not valid" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnewstatenotvalid $nstate]" 0
					}
				}
				set incr 0
			} elseif {[string equal $char "/style"]} {
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set fontstyle [::amsnplus::readWord $i $msg $strlen]
				::config::setKey mychatfont "$fontfamily $fontstyle $fontcolor"
				set flen [string length $fontstyle]
				set msg [string replace $msg $i [expr $i + $flen] ""]
				set strlen [string length $msg]
				set incr 0
			} elseif {[string equal $char "/text"]} {
				set msg [string replace $msg $i [expr $i + 5] ""]
				return $msg
			} elseif {[string equal $char "/unblock"]} {
				set msg [string replace $msg $i [expr $i + 8] ""]
				set strlen [string length $msg]
				set user_login [::amsnplus::readWord $i $msg $strlen]
				set ulen [string length $user_login]
				set msg [string replace $msg $i [expr $i + $ulen] ""]
				set strlen [string length $msg]
				set nick [::abook::getNick ${user_login}]
				::MSN::unblockUser ${user_login} [urlencode $nick]
				set incr 0
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
				if {[::amsnplus::version_094]} {
					::amsnplus::write_window $chatid "\n$user_login info: $nick $group $client $os" 0
				} else {
					::amsnplus::write_window $chatid "[trans cinfo $user_login $nick $group $client $os]" 0
				}
				set incr 0
			}
			#check for the quick texts
			if {$::amsnplus::config(allow_quicktext)} {
				foreach {key txt} $::amsnplus::config(quick_text) {
					if {[string equal $char "/$key"] && ![string equal $char "/"]} {
						set clen [string length $char]
						set msg [string replace $msg $i [expr $i + $clen] $txt]
						set strlen [string length $msg]
						set qtlen [string length $txt]
						set i [expr $i + $qtlen]
					}
				}
			}
			if {[string equal $incr "1"]} { incr i }
			set incr 1
		}
	}

	###################################################################
	# this returns the readme content in a variable
	proc help {} {
		set dir [::config::getKey amsnpluspluginpath]
		set channel [open "$dir/readme" "RDONLY"]
		return "[read $channel]"
	}
	
	############################################
	# ::amsnplus::version_094                  #
	# -----------------------------------------#
	# Verify if the version of aMSN is 0.94    #
	# Useful if we want to keep compatibility  #
	############################################
	proc version_094 {} {
		global version
		scan $version "%d.%d" y1 y2;
		if { $y2 == "94" } {
			return 1
		} else {
			return 0
		}
	}

}
