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
		if {![string equal $::version "0.94"]} {
			set langdir [append dir "/lang"]
			set lang [::config::getGlobalKey language]
			load_lang $lang $langdir
		}
		#plugin config
		array set ::amsnplus::config {
			parse_nicks 1
			colour_nicks 0
			allow_commands 1
			allow_colours 1
			allow_quicktext 1
			quick_text_0 [list]
			quick_text_1 [list]
			quick_text_2 [list]
			quick_text_3 [list]
			quick_text_4 [list]
			quick_text_5 [list]
			quick_text_6 [list]
			quick_text_7 [list]
			quick_text_8 [list]
			quick_text_9 [list]
		}
		if {[string equal $::version "0.94"]} {
			set ::amsnplus::configlist [ list \
				[list bool "Do you want to parse nicks?" parse_nicks] \
				[list bool "Do you want to colour nicks? (not fully feature)" colour_nicks] \
				[list bool "Do you want to allow commands in the chat window?" allow_commands] \
				[list bool "Do you want to allow multiple colours in the chat window?" allow_colours] \
				[list bool "Do you want to use the quick text feature?" allow_quicktext] \
			]
		} else {
			set ::amsnplus::configlist [ list \
				[list bool "[trans parsenicks]" parse_nicks] \
				[list bool "[trans colournicks]" colour_nicks] \
				[list bool "[trans allowcommands]" allow_commands] \
				[list bool "[trans allowcolours]" allow_colours] \
				[list bool "[trans allowquicktext]" allow_quicktext] \
			]
		}
		#register events
		::plugins::RegisterEvent "aMSN Plus" parse_nick parse_nick
		::plugins::RegisterEvent "aMSN Plus" chat_msg_send parseCommand
		::plugins::RegisterEvent "aMSN Plus" chat_msg_receive parse_colours
		::plugins::RegisterEvent "aMSN Plus" chatwindowbutton chat_color_button
		::plugins::RegisterEvent "aMSN Plus" chatmenu edit_menu
		::plugins::RegisterEvent "aMSN Plus" chatmenu add_quicktext
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
		return 0	
	}

	###################################################################
	# this procs writes msg to the window with chatid and checks the
	# the config if its a received command (env)
	proc write_window { chatid msg env {colour "green"} } {
		::amsn::WinWrite $chatid $msg $colour
	}



	#//////////////////////////////////////////////////////////////////////////
	#                          ALL ABOUT QUICK TEXT
	#//////////////////////////////////////////////////////////////////////////

	################################################
	# this adds the quick text configured entries
	# in the chat window menu
	proc add_quicktext {event epvar} {
		if {!$::amsnplus::config(allow_quicktext)} { return }
		upvar 2 evPar newvar
		$newvar(menu_name).actions add separator
		set i 0
		while {$i < 10} {
			set str [lindex $::amsnplus::config(quick_text_$i) 1]
			set keyword "/[lindex $::amsnplus::config(quick_text_$i) 0]"
			if { ![string equal $str ""] && ![string equal $keyword ""] } {
				$newvar(menu_name).actions add command -label $str -command "$newvar(window_name).f.bottom.left.in.text insert end $keyword"
			}
			incr i
		}
	}
	
	################################################
	# this proc lets configure the quick texts
	proc qtconfig { } {
		#create the window
		toplevel .qtconfig -width 600 -height 400
		wm title .qtconfig "[trans quicktext]"
		#add an explanation
		if {[string equal $::version "0.94"]} {
			label .qtconfig.help -text "Here you should configure your quick text, the keyword and the text.\nThen in the chat window, if you do /keyword, \
				you'll see the text\n"
		} else {
			label .qtconfig.help -text "[trans qthelp]\n"
		}
		pack .qtconfig.help -side top
		#entries
		set i 0
		while {$i < 10} {
			labelframe .qtconfig.label$i -relief flat
			entry .qtconfig.label$i.keyword
			entry .qtconfig.label$i.text
			pack .qtconfig.label$i -side top
			pack .qtconfig.label$i.keyword -side left
			.qtconfig.label$i.keyword insert end [lindex $::amsnplus::config(quick_text_$i) 0]
			pack .qtconfig.label$i.text -side left
			.qtconfig.label$i.text insert end [lindex $::amsnplus::config(quick_text_$i) 1]
			incr i
		}
		#save button
		button .qtconfig.save -text "[trans save]" -command "::amsnplus::save_qtconfig .qtconfig"
		pack .qtconfig.save -side bottom
	}
	
	###############################################
	# this proc saves the quick text configuration
	proc save_qtconfig { win } {
		set i 0
		while {$i < 10} {
			set keyword [$win.label$i.keyword get]
			set str [$win.label$i.text get]
			set ::amsnplus::config(quick_text_$i) [list $keyword $str]
			incr i
		}
	}



	#//////////////////////////////////////////////////////////////////////////
	#                 ALL ABOUT PARSING AND COLORING NICKS
	#//////////////////////////////////////////////////////////////////////////

	################################################
	# this proc deletes ·$<num> codification
	# and colours nick if enabled
	# should parse ALSO MULTIPLE COLORS ·$(num,num,num)
	proc parse_nick {event epvar} {
		if {!$::amsnplus::config(parse_nicks)} {return}
		upvar 2 data data
		#upvar 2 colour colour
		set strlen [string length $data]
		set i 0
		while {$i < $strlen} {
			set str [string range $data $i [expr $i + 1]]
			if {[string equal $str "·\$"]} {
				if {$::amsnplus::config(colour_nicks)} {
					#know if the number has 1 or 2 digits
					set last [expr $i + 3]
					set char [string index $data [expr $i + 3]]
					if {![::amsnplus::is_a_number $char]} {
						set last [expr $i + 2]
					}
					#obtain rbg color
					set num [string range $data [expr $i + 2] $last]
					set colour [::amsnplus::getColor $num $colour]
					
					incr i
				} else {
					set last [expr $i + 3]
					set char [string index $data [expr $i + 3]]
					if {![::amsnplus::is_a_number $char]} {
						set last [expr $i + 2]
					}
					set data [string replace $data $i $last ""]
				}
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
	#                ALL ABOUT MULTIPLE COLOURS IN CHAT WINDOW
	#//////////////////////////////////////////////////////////////////////////

	###############################################
	# this creates some commands for editing in the
	# chat window packed in the edit menu
	proc edit_menu {event epvar} {
		if { !$::amsnplus::config(allow_colours) } { return }
		upvar 2 evPar newvar
		set bold "(!FB)"
		set italic "(!FI)"
		set underline "(!FU)"
		set overstrike "(!FS)"
		set reset "(!FR)"
		$newvar(menu_name).actions add separator
		$newvar(menu_name).actions add command -label "[trans bold]" -command "$newvar(window_name).f.bottom.left.in.text insert end $bold"
		$newvar(menu_name).actions add command -label "[trans italic]" -command "$newvar(window_name).f.bottom.left.in.text insert end $italic"
		$newvar(menu_name).actions add command -label "[trans underline]" -command "$newvar(window_name).f.bottom.left.in.text insert end $underline"
		$newvar(menu_name).actions add command -label "[trans overstrike]" -command "$newvar(window_name).f.bottom.left.in.text insert end $overstrike"
		$newvar(menu_name).actions add command -label "[trans reset]" -command "$newvar(window_name).f.bottom.left.in.text insert end $reset"
	}

	###############################################
	# this adds a button to choose color for our
	# multi-color text in the chatwindow
	# now add buttons for multi-format text too
	proc chat_color_button {event epvar} {
		if { !$::amsnplus::config(allow_colours) } { return }
		#get the event vars
		upvar 2 bottom bottom
		upvar 2 w w
		#set the path to pixmaps
		set amsnpluspath [::config::getKey "amsnpluspluginpath"]
		#set the path to each pixmap
		append pixmap1 $amsnpluspath "/pixmaps/multiple_colors.gif"
		#create the imgages
		set img1 [image create photo -file $pixmap1 -format gif]
		#create the texts
		set bold "(!FB)"
		#create the widgeds
		button $bottom.buttons.multiple_colors -image $img1 -relief flat -padx 3 \
			-background [::skin::getColor buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getColor buttonbarbg] \
			-command "after 1 ::amsnplus::choose_color $w"
		if {[string equal $::version "0.94"]} {
			set_balloon $bottom.buttons.multiple_colors "Add a new color"
		} else {
			set_balloon $bottom.buttons.multiple_colors "[trans multiplecolorsbutton]"
		}
		#pack the widgeds
		pack $bottom.buttons.multiple_colors -side left
	}

	###############################################
	# this opens a tk_color_palette to choose an
	# rgb color in (rrr,ggg,bbb) format
	proc choose_color { win } {
		set color [tk_chooseColor -parent $win];
		if {[string equal $color ""]} { return }
		set color [::amsnplus::hexToRGB [string replace $color 0 0 ""]];
		$win.f.bottom.left.in.text insert end $color
	}
	
	###############################################
	# this colours received messages
	# there are two ways to colorize text:
	#   - preset colors -> (!FC<num>) or (!FG<num>) for background -> there are from 0 to 15
	#   - any colour -> (r,g,b) or (r,g,b),(r,g,b) to add background -> palette to choose (take a look at tk widgeds)
	proc parse_colours {event epvar} {
		if { !$::amsnplus::config(allow_colours) } { return }
		upvar 2 msg msg
		upvar 2 chatid chatid
		set fontformat [::config::getKey mychatfont]
		set color [lindex $fontformat 2]
		set style [lindex $fontformat 1]
		set font [lindex $fontformat 0]
		set strlen [string length $msg]
		set i 0
		while {$i<$strlen} {
			set char [string range $msg $i [expr $i + 4]]
			if {[string equal $char "(!FB)"]} {
				set msg [string replace $msg $i [expr $i + 3] ""]
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
			if {[string equal $char "(!FI)"]} {
				set msg [string replace $msg $i [expr $i + 3] ""]
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
			if {[string equal $char "(!FU)"]} {
				set msg [string replace $msg $i [expr $i + 3] ""]
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
			if {[string equal $char "(!FS)"]} {
				set msg [string replace $msg $i [expr $i + 3] ""]
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
			if {[string equal $char "(!FR)"]} {
				set msg [string replace $msg $i [expr $i + 3] ""]
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
			set char [string range $msg $i [expr $i + 3]]
			if {[string equal $char "(!FC"]} {
				if {[::amsnplus::is_a_number [string index $msg [expr $i + 5]]]} {
					set new_color [string range $msg [expr $i + 4] [expr $i + 5]]
					set msg [string replace $msg $i [expr $i + 5] ""]
					set strlen [string length $msg]
				} else {
					set new_color [string index $msg [expr $i + 4]]
					set msg [string replace $msg $i [expr $i + 4] ""]
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
			}
			set char [string index $msg $i]
			if {[string equal $char "("]} {
				if {[::amsnplus::is_a_number [string range $msg [expr $i + 1] [expr $i + 3]]]} {
					if {[::amsnplus::is_a_number [string range $msg [expr $i + 5] [expr $i + 7]]]} {
						if {[::amsnplus::is_a_number [string range $msg [expr $i + 9] [expr $i + 11]]]} {
							set rgb [string range $msg $i [expr $i + 11]]
							set msg [string replace $msg $i [expr $i + 11] ""]
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
	#                      ALL ABOUT SENDING COMMANDS
	#//////////////////////////////////////////////////////////////////////////

	################################################
	# this proc add external commands to amsnplus
	# (useful for other plugins)
	proc add_command { keyword proc parameters } {
		set ::amsnplus::external_commands($keyword) [list $proc $parameters]
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
				set result [$proc $values]
				status_log "$proc $values -> $result\n"
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
				if {[string equal $::version "0.94"]} {
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
				set msg [string replace $msg $i [expr $i + 6] ""]
				set strlen [string length $msg]
				set chat_win $::ChatWindow::msg_windows($chatid)
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
				if {[string equal $::version "0.94"]} {
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
				if {[string equal $::version "0.94"]} {
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
					if {[string equal $::version "0.94"]} {
						::amsnplus::write_window $chatid "\nYour color is: $fontcolor" 0
					} else {
						::amsnplus::write_window $chatid "[trans ccolor $fontcolor]" 0
					}
				} elseif {[string equal $field "font"]} {
					if {[string equal $::version "0.94"]} {
						::amsnplus::write_window $chatid "\nYour font is: $fontfamily" 0
					} else {
						::amsnplus::write_window $chatid "[trans cfont $fontfamily]" 0
					}
				} elseif {[string equal $field "nick"]} {
					set nick [::abook::getPersonal nick]
					if {[string equal $::version "0.94"]} {
						::amsnplus::write_window $chatid "\nYour nick is: $nick" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnick $nick]" 0
					}
				} elseif {[string equal $field "state"]} {
					set status [::MSN::myStatusIs]
					set status [::MSN::stateToDescription $status]
					if {[string equal $::version "0.94"]} {
						::amsnplus::write_window $chatid "\nYour status is: $status" 0
					} else {
						::amsnplus::write_window $chatid "[trans cstatus $status]" 0
					}
				} elseif {[string equal $field "style"]} {
					if {[string equal $::version "0.94"]} {
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
				if {[string equal $::version "0.94"]} {
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
				if {[string equal $::version "0.94"]} {
					::amsnplus::write_window $chatid "\nExecuting: $command" 0
				} else {
					::amsnplus::write_window $chatid "[trans cshell $command]" 0
				}
				if {[string equal $catch "1"]} {
					if {[string equal $::version "0.94"]} {
						::amsnplus::write_window $chatid "\nYour command is not valid" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnotvalid]" 0
					}
				} else {
					if {[string equal $::version "0.94"]} {
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
					if {[string equal $::version "0.94"]} {
						::amsnplus::write_window $chatid "\nNew state is: $nstate" 0
					} else {
						::amsnplus::write_window $chatid "[trans cnewstate $nstate]" 0
					}
				} else {
					if {[string equal $::version "0.94"]} {
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
				if {[string equal $user_login ""]} {
					if {[string equal $::version "0.94"]} {
						::amsnplus::write_window $chatid "\mYou must specify a contact" 0
					} else {
						::amsnplus::write_window $chatid "[trans cspecify]" 0
					}
				} else {
					set ulen [string length $user_login]
					set msg [string replace $msg $i [expr $i + $ulen] ""]
					set strlen [string length $msg]
					set group [::groups::GetName [::abook::getContactData $user_login group]]
					set nick [::abook::getContactData $user_login nick]
					if {[string equal $::version "0.94"]} {
						::amsnplus::write_window $chatid "\n$user_login info: $nick $group" 0
					} else {
						::amsnplus::write_window $chatid "[trans cinfo $user_login $nick $group]" 0
					}
				}
				set incr 0
			}
			#check for the quick texts
			if {$::amsnplus::config(allow_quicktext)} {
				set k 0
				while {$k < 10} {
					set word [lindex $::amsnplus::config(quick_text_$k) 0]
					if {[string equal $char "/$word"]} {
						set qt [lindex $::amsnplus::config(quick_text_$k) 1]
						set clen [string length $char]
						set msg [string replace $msg $i [expr $i + $clen] $qt]
						set strlen [string length $msg]
						set qtlen [string length $qt]
						set i [expr $i + $qtlen]
					}
					incr k
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

}
