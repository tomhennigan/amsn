############################################
#            Colored Nicks                 #
#  ========================================#
#  Giuseppe "Square87" Bottiglieri         #
# =========================================#
############################################


namespace eval ::colorednicks {

proc init { dir } {
	::plugins::RegisterPlugin "ColoredNicks"
	::plugins::RegisterEvent "ColoredNicks" parse_contact parsed_nick2
	status_log "ColoredNicks loaded"

	set langdir [file join $dir "lang"]
	load_lang en $langdir
	load_lang [::config::getGlobalKey language] $langdir

	array set ::colorednicks::config {
		nostyle 0
	}

	set ::colorednicks::configlist [list \
		[list bool "[trans nostyle]" nostyle] \
	]
}

proc parsed_nick2 {event epvar} {
	upvar 2 $epvar evpar
	upvar 2 $evpar(variable) nickArray
	
	variable newparsednick ""

	set num_elem [llength $nickArray]
	set parsednick $nickArray
	set thereiscolour 0

	for {set element 0} {$element < $num_elem} {incr element} {
		variable unit [lindex $parsednick $element]
		if {[lindex $unit 0] ne "text"} {
			lappend newparsednick [lindex $unit]
		} else {
			set num_chars [string length [lindex $unit 1] ]
			variable buffer ""
			for {variable pos_char 0} {$pos_char<$num_chars} {incr pos_char} {
				set char [string index [lindex $unit 1] $pos_char ]
				if {$char ne "\["} {
					append buffer $char
				} else {
					set old_pos_char $pos_char
					set next_char1 [string range [lindex $unit 1] [expr $pos_char +1] [expr $pos_char +2] ]
					if {$next_char1 eq "c="} {
						checkcolor setcolour
					} elseif { $next_char1 eq "/c"} {
						checkfadedcolor unsetcolour setfadecolour
					} elseif {$next_char1 eq "C="} {
						checkcolor setcolour_UP
					} elseif { $next_char1 eq "/C"} {
						checkfadedcolor unsetcolour_UP setfadecolour_UP
					}

					if {$old_pos_char eq $pos_char} {
						append buffer $char
					} else {
						set thereiscolour 1
					}
				}
			}
			if {$buffer ne ""} {
				lappend newparsednick [list text $buffer]
			}
		}
	}

	if {$thereiscolour == 1} {
		colorortext
	}

	set parsednick $newparsednick
	variable newparsednick [list ]
	set num_elem [llength $parsednick]
	set thereisstyle 0
	set thereisIRCstyle 0

	for {set element 0} {$element < $num_elem} {incr element} {
		variable unit [lindex $parsednick $element]
		if {[lindex $unit 0] ne "text"} {
			lappend newparsednick [lindex $unit]
		} else {
			set num_chars [string length [lindex $unit 1] ]
			variable buffer ""
			for {variable pos_char 0} {$pos_char<$num_chars} {incr pos_char} {
				set char [string index [lindex $unit 1] $pos_char ]
				if {$char ne "\[" && $char != "\u00B7"} {
					append buffer $char
				} elseif {$char eq "\["} {
					set old_pos_char $pos_char
					set next_char1 [string range [lindex $unit 1] [expr $pos_char +1] [expr $pos_char +2] ]
					if { $next_char1 eq "b]" } {
						unbuffer
						lappend newparsednick [list style bold]
						incr pos_char 2
					} elseif { $next_char1 eq "/b" } {
						if {[string index [lindex $unit 1] [expr $pos_char +3]] eq "\]"} {
							unbuffer
							lappend newparsednick [list style unbold]
							incr pos_char 3
						}
					} elseif { $next_char1 eq "s]" } {
						unbuffer
						lappend newparsednick [list style overstrike]
						incr pos_char 2
					} elseif { $next_char1 eq "/s" } {
						if {[string index [lindex $unit 1] [expr $pos_char +3]] eq "\]"} {
							unbuffer
							lappend newparsednick [list style unoverstrike]
							incr pos_char 3
						}
					} elseif { $next_char1 eq "u]" } {
						unbuffer
						lappend newparsednick [list style underline]
						incr pos_char 2
					} elseif { $next_char1 eq "/u" } {
						if {[string index [lindex $unit 1] [expr $pos_char +3]] eq "\]"} {
							unbuffer
							lappend newparsednick [list style ununderline]
							incr pos_char 3
						}
					} elseif { $next_char1 eq "i]" } {
						unbuffer
						lappend newparsednick [list style slant]
						incr pos_char 2
					} elseif { $next_char1 eq "/i" } {
						if {[string index [lindex $unit 1] [expr $pos_char +3]] eq "\]"} {
							unbuffer
							lappend newparsednick [list style unslant]
							incr pos_char 3
						}
					} elseif { $next_char1 eq "a=" } {
						checkcolor bg
					} elseif { $next_char1 eq "/a"} {
						faded_background_nick
					} elseif {$next_char1 eq "B]"} {
						unbuffer
						lappend newparsednick [list style BOLD]
						incr pos_char 2
					} elseif { $next_char1 eq "/B" } {
						if {[string index [lindex $unit 1] [expr $pos_char +3]] eq "\]"} {
							unbuffer
							lappend newparsednick [list style UNBOLD]
							incr pos_char 3
						}
					} elseif { $next_char1 eq "S]" } {
						unbuffer
						lappend newparsednick [list style OVERSTRIKE]
						incr pos_char 2
					} elseif { $next_char1 eq "/S" } {
						if {[string index [lindex $unit 1] [expr $pos_char +3]] eq "\]"} {
							unbuffer
							lappend newparsednick [list style UNOVERSTRIKE]
							incr pos_char 3
						}
					} elseif { $next_char1 eq "U]" } {
						unbuffer
						lappend newparsednick [list style UNDERLINE]
						incr pos_char 2
					} elseif { $next_char1 eq "/U" } {
						if {[string index [lindex $unit 1] [expr $pos_char +3]] eq "\]"} {
							unbuffer
							lappend newparsednick [list style UNUNDERLINE]
							incr pos_char 3
						}
					} elseif { $next_char1 eq "I]" } {
						unbuffer
						lappend newparsednick [list style SLANT]
						incr pos_char 2
					} elseif { $next_char1 eq "/I" } {
						if {[string index [lindex $unit 1] [expr $pos_char +3]] eq "\]"} {
							unbuffer
							lappend newparsednick [list style UNSLANT]
							incr pos_char 3
						}
					} elseif { $next_char1 eq "A=" } {
						nick_background
					} elseif { $next_char1 eq "/A"} {
						faded_background_nick
					}

					if {$old_pos_char == $pos_char} {
						append buffer $char
					} else {
						set thereisstyle 1
					}
				} else {
					set next_char1 [string index [lindex $unit 1] [expr $pos_char+1]]
					if { $next_char1 eq "$"} {
						incr pos_char
						colored_nick_IRC_style
					} elseif {$next_char1 eq "#"} {
						unbuffer
						lappend newparsednick [list font "-weight bold"]
						incr pos_char 1
					} elseif {$next_char1 eq "@"} {
						unbuffer
						lappend newparsednick [list font "-underline 1"]
						incr pos_char 1
					} elseif {$next_char1 eq "'"} {
						unbuffer
						lappend newparsednick [list font "-overstrike 1"]
						incr pos_char 1
					} elseif {$next_char1 eq "&"} {
						unbuffer
						lappend newparsednick [list font "-slant italic"]
						incr pos_char 1
					} elseif {$next_char1 == "0"} {
						unbuffer
						lappend newparsednick [list ircstylereset]
						incr pos_char 1
					} else {
						append buffer $char
					}
					set thereisIRCstyle 1
				}
			}
			if {$buffer ne ""} {
				lappend newparsednick [list text $buffer]
			}
		}
	}

	if {$thereisstyle == 1} {
		styleortext
	}

	if { $thereiscolour == 0 && $thereisIRCstyle == 0} {
		set nickArray $newparsednick
	} elseif {$::colorednicks::config(nostyle) == 1} {
		set nickArray ""
		foreach unit $newparsednick {
			if {[lindex $unit 0] eq "text" || [lindex $unit 0] eq "smiley" || [lindex $unit 0] eq "newline"} {
				lappend nickArray [lindex $unit]
			}
		}
	} else {
		if {$thereiscolour == 1} {
			fading
		}
		if {$thereisIRCstyle == 1} {
			checkIRCcolour
			lappend newparsednick {font "reset"} {colour reset}
		}

		set nickArray ""
		foreach elem $newparsednick {
			set firstelem [lindex $elem 0]
			if {$firstelem eq "text"} {
				lappend nickArray [lindex $elem]
			} elseif {$firstelem eq "smiley"} {
				lappend nickArray [lindex $elem]
			} elseif {$firstelem eq "colour"} {
				lappend nickArray [lindex $elem]
			} elseif {$firstelem eq "font"} {
				lappend nickArray [lindex $elem]
			} elseif {$firstelem eq "bg"} {
				set cl [lindex $elem 1]
				if {$cl ne "reset" && [string range $cl 0 0] ne "#"} {
					set cl "#[getColor $cl]"
				}
				lappend nickArray [list bg $cl]
			} elseif {$firstelem eq "newline"} {
				lappend nickArray [lindex $elem]
			}
		}
	}

	lappend nickArray [list bg reset]

	unset newparsednick
	unset unit
	unset pos_char
	unset buffer
}


proc colorortext {} {
	variable newparsednick
	variable idnum 0

	for {set x [expr [llength $newparsednick] -1]} {$x >= 0} {incr x -1} {
		set unit [lindex $newparsednick $x]
		if {[lindex $unit 0] eq "unsetcolour"} {
			cot_unsetcolour $x
			set x [expr [llength $newparsednick] -1]
		} elseif {[lindex $unit 0] eq "setfadecolour"} {
			cot_setfadecolour $x
			set x [expr [llength $newparsednick] -1]
		} elseif {[lindex $unit 0] eq "unsetcolour_UP"} {
			cot_unsetcolour_UP $x
			set x [expr [llength $newparsednick] -1]
		} elseif {[lindex $unit 0] eq "setfadecolour_UP"} {
			cot_setfadecolour_UP $x
			set x [expr [llength $newparsednick] -1]
		}
	}
	
	unset idnum

	set list_colors [list ]
	set list_colors_UP [list ]
	set num_elem [llength $newparsednick]
	set up 0
	set noup 0

	for {set el 0} {$el < $num_elem} {incr el 1} {
		set unit [lindex $newparsednick $el]
		set fe [lindex $unit 0]
		if {$fe eq "text" || $fe eq "smiley"} {
		} elseif {$fe eq "colour"} {
			if {[lindex $unit 2] == 1} {
				if {$up > 0} {
					incr noup 1
				}
				lappend list_colors [lindex $unit 1]
				set newparsednick [lreplace $newparsednick $el $el [list colour [lindex $unit 1] 1]]
			} elseif {[lindex $unit 2] == 2} {
				set list_colors [lreplace $list_colors end end]
				if {$up > 0 && $up >= $noup} {
					set last_color [lindex $list_colors_UP end]
					set newparsednick [lreplace $newparsednick $el $el [list colour $last_color -4]]
				} else {
					set last_color [lindex $list_colors end]
					if {$last_color eq ""} {
						set last_color [lindex $list_colors_UP end]
						if {$last_color eq ""} {
							set last_color "reset"
						}
					}
					set newparsednick [lreplace $newparsednick $el $el [list colour $last_color 2]]
				}
				if {$noup > 0} {
					incr noup -1
				}
			} elseif {[lindex $unit 2] == 3} {
				incr up 1
				set newparsednick [lreplace $newparsednick $el $el [list colour [lindex $unit 1] 3]]
				lappend list_colors_UP [lindex $unit 1]
			} elseif {[lindex $unit 2] == 4} {
				set list_colors_UP [lreplace $list_colors_UP end end]
				if {$noup > 0 && $noup >= $up} {
					set newparsednick [lreplace $newparsednick $el $el]
					incr num_elem -1
					incr el -1
				} else {
					if {$noup >= $up} {
						set last_color [lindex $list_colors end]
					} else {
						set last_color [lindex $list_colors_UP end]
						if {$last_color eq ""} {
							set last_color [lindex $list_colors end]
							if {$last_color eq ""} {
								set last_color "reset"
							}
						}
					}
					set newparsednick [lreplace $newparsednick $el $el [list colour $last_color 4]]
				}
				incr up -1
			}
		} elseif {$fe eq "setcolour"} {
			set se [lindex $unit 1]
			set newparsednick [lreplace $newparsednick $el $el [list text "\[c=${se}\]"]]
		} elseif {$fe eq "setcolour_UP"} {
			set se [lindex $unit 1]
			set newparsednick [lreplace $newparsednick $el $el [list text "\[C=${se}\]"]]
		}
	}
}

proc cot_setfadecolour {x} {
	variable newparsednick
	variable idnum

	set count 0
	for {set y [expr $x -1]} {$y >= 0} {incr y -1} {
		set unit2 [lindex [lindex $newparsednick $y] 0]
		if {$unit2 eq "setcolour"} {
			if {$count == 0} {
				set numy [lindex [lindex $newparsednick $y] 1]
				set len_numy [string length $numy]
				if {[string range $numy 0 0] ne "#"} {
					set numy "#[getColor $numy]"
				}
				set in [list startfadecolour $numy 1]

				set numx [lindex [lindex $newparsednick $x] 1]
				set len_numx [string length $numx]
				if {[string range $numx 0 0] ne "#"} {
					set numx "#[getColor $numx]"
				}
				set out [list fadecolour $numx 2]

				if {$numy eq "#-1" || $numx eq "#-1"} {
					if {$numy eq "#-1"} {
						set in  "nothing"
						set out "nothing"
					} else {
						set in [list colour [lindex $in 1] 1]
						set out [list colour reset 2]
					}
				} elseif {[lindex $in 1] == [lindex $out 1]} {
					set in [list colour [lindex $in 1] 1]
					set out [list colour reset 2]
				}
	
				set newparsednick [lreplace [lreplace $newparsednick $y $y $in] $x $x $out]

				set newparsednick [linsert $newparsednick $y "startpost [expr $len_numy + 4] $idnum"]
				set newparsednick [linsert $newparsednick [expr $x + 2] "stoppost [expr $len_numx + 5] $idnum"]

				incr idnum

				return
			} else {
				incr count -1
			}
		} elseif {$unit2 eq "setfadecolour" || $unit2 eq "unsetcolour"} {
			incr count 1
		}
	}
	set col [lindex [lindex $newparsednick $x] 1]
	set newparsednick [lreplace $newparsednick $x $x [list text "\[/c=${col}\]"]]
}


proc cot_setfadecolour_UP {x} {
	variable newparsednick
	variable idnum

	set count 0
	for {set y [expr $x -1]} {$y >= 0} {incr y -1} {
		set unit2 [lindex [lindex $newparsednick $y] 0]
		if {$unit2 eq "setcolour_UP"} {
			if {$count == 0} {
				set numy [lindex [lindex $newparsednick $y] 1]
				set len_numy [string length $numy]
				if {[string range $numy 0 0] ne "#"} {
					set numy "#[getColor $numy]"
				}
				set in [list startfadecolour $numy 3]

				set numx [lindex [lindex $newparsednick $x] 1]
				set len_numx [string length $numx]
				if {[string range $numx 0 0] ne "#"} {
					set numx "#[getColor $numx]"
				}
				set out [list fadecolour $numx 4]

				if {$numy eq "#-1" || $numx eq "#-1"} {
					if {$numy eq "#-1"} {
						set in  "nothing"
						set out "nothing"
					} else {
						set in [list colour [lindex $in 1] 3]
						set out [list colour reset 4]
					}
				} elseif {[lindex $in 1] == [lindex $out 1]} {
					set in [list colour [lindex $in 1] 3]
					set out [list colour reset 4]
				}

				set newparsednick [lreplace [lreplace $newparsednick $y $y $in] $x $x $out]

				set newparsednick [linsert $newparsednick $y "startpost [expr $len_numy + 4] $idnum"]
				set newparsednick [linsert $newparsednick [expr $x + 2] "stoppost [expr $len_numx + 5] $idnum"]

				incr idnum

				return
			} else {
				incr count -1
			}
		} elseif {$unit2 eq "setfadecolour_UP" || $unit2 eq "unsetcolour_UP"} {
			incr count 1
		}
	}
	set col [lindex [lindex $newparsednick $x] 1]
	set newparsednick [lreplace $newparsednick $x $x [list text "\[/C=${col}\]"]]
}


proc cot_unsetcolour {x} {
	variable newparsednick
	variable idnum

	set count 0
	for {set y [expr $x -1]} {$y >= 0} {incr y -1} {
		set unit2 [lindex [lindex $newparsednick $y] 0]
		if {$unit2 eq "setcolour"} {
			if {$count == 0} {
				set num [lindex [lindex $newparsednick $y] 1]
				if {[string range $num 0 0] ne "#"} {
					set num "#[getColor $num]"
				}

				if { $num ne "#-1" } {
					set in  "colour $num 1"
					set out "colour reset 2"
				} else {
					set in  "nothing"
					set out "nothing"
				}

				set newparsednick [lreplace [lreplace $newparsednick $x $x $out] $y $y $in]

				set newparsednick [linsert $newparsednick $y "startpost [expr [string length $num] + 4] $idnum"]
				set newparsednick [linsert $newparsednick [expr $x + 2] "stoppost 4 $idnum" ]

				incr idnum
				return
			} else {
				incr count -1
			}
		} elseif {$unit2 eq "unsetcolour" || $unit2 eq "setfadecolour"} {
			incr count 1
		}
	}
	set newparsednick [lreplace $newparsednick $x $x [list text "\[/c\]"]]
}


proc cot_unsetcolour_UP {x} {
	variable newparsednick
	variable idnum

	set count 0
	for {set y [expr $x -1]} {$y >= 0} {incr y -1} {
		set unit2 [lindex [lindex $newparsednick $y] 0]
		if {$unit2 eq "setcolour_UP"} {
			if {$count == 0} {

				set num [lindex [lindex $newparsednick $y] 1]
				if {[string range $num 0 0] ne "#"} {
					set num "#[getColor $num]"
				}

				if { $num ne "#-1" } {
					set in  "colour $num 3"
					set out "colour reset 4"
				} else {
					set in  "nothing"
					set out "nothing"
				}

				set newparsednick [lreplace [lreplace $newparsednick $x $x $out] $y $y $in]

				set newparsednick [linsert $newparsednick $y "startpost [expr [string length $num] + 4] $idnum"]
				set newparsednick [linsert $newparsednick [expr $x + 2] "stoppost 4 $idnum" ]

				incr idnum
				return
			} else {
				incr count -1
			}
		} elseif {$unit2 eq "unsetcolour_UP" || $unit2 eq "setfadecolour_UP"} {
			incr count 1
		}
	}
	set newparsednick [lreplace $newparsednick $x $x [list text "\[/C\]"]]
}


proc styleortext {} {
	variable newparsednick

	set lung [expr [llength $newparsednick] -1]

	for {set elem $lung} {$elem >= 0} {incr elem -1} {
		if {[lindex [lindex $newparsednick $elem] 0] eq "style"} {
			set unstyle [lindex [lindex $newparsednick $elem] 1]
			set style [string range $unstyle 2 end]
			set origin_y [expr $elem - 1]
			set old_elem $elem
			for {set y $origin_y} {$y >= 0} {incr y -1} {
				set unit2 [lindex $newparsednick $y]
				if {[lindex $unit2 0] eq "style"} {
					if {[lindex $unit2 1] eq $style} {
						set style [string tolower $style]
						if {$style eq "bold"} {
							set in [list font "-weight bold"]
							set out [list font "-weight reset"]
						} elseif {$style eq "overstrike"} {
							set in [list font "-overstrike 1"]
							set out [list font "-overstrike reset"]
						} elseif {$style eq "underline"} {
							set in [list font "-underline 1"]
							set out [list font "-underline reset"]
						} elseif {$style eq "slant"} {
							set in [list font "-slant italic"]
							set out [list font "-slant reset"]
						}
			
						set newparsednick [lreplace $newparsednick $old_elem $old_elem $out]
						set newparsednick [lreplace $newparsednick $y $y $in]
						set y $origin_y

						if {$old_elem == $elem} { 
							break
						}
						set old_elem $elem
					} elseif {[lindex $unit2 1] eq $unstyle} {
						set old_elem $y
					}
				}
			}
		}
	}

	for {set x $lung} {$x >= 0} {incr x -1} {
		if {[lindex [lindex $newparsednick $x] 0] eq "style"} {
			set unit [lindex [lindex $newparsednick $x] 1]
			if {$unit eq "bold"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[b\]"]]
			} elseif {$unit eq "unbold"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[/b\]"]]
			} elseif {$unit eq "overstrike"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[s\]"]]
			} elseif {$unit eq "unoverstrike"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[/s\]"]]
			} elseif {$unit eq "underline"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[u\]"]]
			} elseif {$unit eq "ununderline"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[/u\]"]]
			} elseif {$unit eq "slant"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[i\]"]]
			} elseif {$unit eq "unslant"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[/i\]"]]
			} elseif {$unit eq "BOLD"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[B\]"]]
			} elseif {$unit eq "UNBOLD"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[/B\]"]]
			} elseif {$unit eq "OVERSTRIKE"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[S\]"]]
			} elseif {$unit eq "UNOVERSTRIKE"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[/S\]"]]
			} elseif {$unit eq "UNDERLINE"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[U\]"]]
			} elseif {$unit eq "UNUNDERLINE"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[/U\]"]]
			} elseif {$unit eq "SLANT"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[I\]"]]
			} elseif {$unit eq "UNSLANT"} {
				set newparsednick [lreplace $newparsednick $x $x [list text "\[/I\]"]]
			}
		}
	}
		
	set style [list 0 0 0 0]

	for {set x 0} {$x <= $lung} {incr x} {
		if {[lindex [lindex $newparsednick $x] 0] eq "font"} {
			set unit [lindex [lindex $newparsednick $x] 1]
			if {$unit eq "-weight bold"} {
				set style [lreplace $style 0 0 [expr [lindex $style 0] + 1]]
				if {[lindex $style 0] > 1} {
					set newparsednick [lreplace $newparsednick $x $x [list jump 3 wasstyle]]
				}
			} elseif {$unit eq "-weight reset"} {
				set style [lreplace $style 0 0 [expr [lindex $style 0] - 1]]
				if {[lindex $style 0] > 0} {
					set newparsednick [lreplace $newparsednick $x $x [list jump 4 wasstyle]]
				}
			} elseif {$unit eq "-overstrike 1"} {
				set style [lreplace $style 1 1 [expr [lindex $style 1] + 1]]
				if {[lindex $style 1] > 1} {
					set newparsednick [lreplace $newparsednick $x $x [list jump 3 wasstyle]]
				}
			} elseif {$unit eq "-overstrike reset"} {
				set style [lreplace $style 1 1 [expr [lindex $style 1] - 1]]
				if {[lindex $style 1] > 0} {
					set newparsednick [lreplace $newparsednick $x $x  [list jump 4 wasstyle]]
				}
			} elseif {$unit eq "-underline 1"} {
				set style [lreplace $style 2 2 [expr [lindex $style 2] + 1]]
				if {[lindex $style 2] > 1} {
					set newparsednick [lreplace $newparsednick $x $x [list jump 3 wasstyle]]
				}
			} elseif {$unit eq "-underline reset"} {
				set style [lreplace $style 2 2 [expr [lindex $style 2] - 1]]
				if {[lindex $style 2] > 0} {
					set newparsednick [lreplace $newparsednick $x $x [list jump 4 wasstyle]]
				}
			} elseif {$unit eq "-slant italic"} {
				set style [lreplace $style 3 3 [expr [lindex $style 3] + 1]]
				if {[lindex $style 3] > 1} {
					set newparsednick [lreplace $newparsednick $x $x  [list jump 3 wasstyle]]
				}
			} elseif {$unit eq "-slant reset"} {
				set style [lreplace $style 3 3 [expr [lindex $style 3] - 1]]
				if {[lindex $style 3] > 0} {
					set newparsednick [lreplace $newparsednick $x $x  [list jump 4 wasstyle]]
				}
			}
		}
	}
}


proc fading {} {
	variable newparsednick

	set list_colors [list ]
	set list_colors_UP [list ]
	set penultimate [list ]
	set penultimate_UP [list ]

	set newparsednick_temp $newparsednick
	set newparsednick ""
	set num_elem [llength $newparsednick_temp]

	set sfc 0
	set stopfadebyirc 0
	for {set element 0} {$element < $num_elem} {incr element} {
		set unit [lindex $newparsednick_temp $element]
		if {$unit eq "stopfadebyirc"} {set stopfadebyirc 1}
		if {[lindex $unit 0] eq "fadecolour"} {
			incr sfc -1
			if {[lindex $unit 2] == 2} {
				fade [lindex $penultimate end] [lindex $unit 1] 1
				set penultimate [lreplace $penultimate end end]
			} else {
				fade  [lindex $penultimate_UP end] [lindex $unit 1] 3
				set penultimate_UP [lreplace $penultimate_UP end end]
			}
			if {$sfc == 0 && !$stopfadebyirc} {
				set lc [lindex $list_colors end]
				if {$lc eq ""} {
					set lc [lindex $list_colors_UP end]
					if {$lc eq ""} {
						set lc "reset"
						lappend newparsednick [list colour $lc -2]
					}
				} else {
					if {[lindex $newparsednick end] ne "nocolour"} {
						lappend newparsednick [list colour $lc -2]
					}	
				}
			}
		} else {
			lappend newparsednick "[lindex $unit]"
			if {[lindex $unit 0] eq "startfadecolour"} {
				incr sfc 1
				if {[lindex $unit 2] == 1} {
					lappend penultimate [lindex $unit 1]
				} else {
					lappend penultimate_UP [lindex $unit 1]
				}
			} elseif {[lindex $unit 0] eq "colour"} {
				if {[lindex $unit 2] == 1} {
					lappend list_colors [lindex $unit 1]
				} elseif {[lindex $unit 2] == 2} {
					set list_colors [lreplace $list_colors end end]
				} elseif {[lindex $unit 2] == 3} {
					lappend list_colors_UP [lindex $unit 1]
				} elseif {[lindex $unit 2] == 4} {
					set list_colors_UP [lreplace $list_colors_UP end end]
				}
			}
		}
	}
}


proc unbuffer {} {
	variable buffer
	variable newparsednick
	if {$buffer ne ""} {
		lappend newparsednick [list text $buffer]
		set buffer ""
	}
}


proc checkcolor {type} {
	variable unit
	variable pos_char
	variable newparsednick

	set next_char2 [string index [lindex $unit 1] [expr $pos_char +3] ]

	if {[string match \[0-9\] $next_char2]} {
		set num [findnum]
		if {$num != -1} {
			lappend newparsednick "[list $type $num]"
			incr pos_char [expr [string length $num] + 3]
		}
	} elseif {$next_char2 eq "#"} {
		set next_char3 [string index [lindex $unit 1] [expr $pos_char +10] ]
		if {$next_char3 eq "\]"} {
			set num [string range [lindex $unit 1] [expr $pos_char+4] [expr $pos_char+9]]
			if { [catch {expr 0x${num}}] } { return }
			unbuffer
			lappend newparsednick "[list $type #$num]"
			incr pos_char 10
		}
	} else {
		set end [string first "\]" "[lindex $unit 1]" [expr $pos_char +3]]
		if {$end != -1} {
			set colorname [string range [lindex $unit 1] [expr $pos_char +3] [expr $end-1]]
			if {[IsColorName $colorname]} {
				unbuffer
				lappend newparsednick "[list $type $colorname]"
				incr pos_char [expr [string length $colorname] + 3]
			}
		}
	}
}


proc checkIRCcolour {} {
	variable newparsednick
	set list_colors [list ]
	set list_colors_UP [list ]

	set len [expr [llength $newparsednick] - 1]

	for {set x 0} {$x <= $len} {incr x 1} {
		set fe [lindex [lindex $newparsednick $x] 0]
		if {$fe eq "irccolour"} {
			set newparsednick [lreplace $newparsednick $x $x [list colour [lindex [lindex $newparsednick $x] 1]]]
			for {set y [expr $x +1]} {$y <= $len} {incr y 1} {
				set fe [lindex [lindex $newparsednick $y] 0]
				if {$fe eq "colour" || $fe eq "startfadecolour"} {
					set newparsednick [lreplace $newparsednick $y $y]
					incr len -1
					incr y -1
				} elseif { $fe eq "fadecolour" } {
					set newparsednick [linsert $newparsednick $x "stopfadebyirc"]
					incr len 1
					incr y 1
				} elseif {$fe eq "ircstylereset"} {
					break
				}
			}
		} elseif {$fe eq "colour"} {
			if {[lindex [lindex $newparsednick $x] 1] ne "reset"} {
				lappend list_colors [lindex [lindex $newparsednick $x] 1]
			} else {
				set list_colors [lreplace $list_colors end end]
			}
		} elseif {$fe eq "ircstylereset"} {
			set lc "colour [lindex $list_colors end]"
			if {$lc eq "colour "} {set lc "colour reset"}
			set list_colors [lreplace $list_colors end end]
			set newparsednick [lreplace $newparsednick $x $x {font "reset"} $lc]
			incr len 4
			incr x 3
		}
	}
}


proc checkfadedcolor {typeclose type} {
	variable unit
	variable pos_char
	variable newparsednick

	set next_char2 [string index [lindex $unit 1] [expr $pos_char +3] ]
	if { $next_char2 eq "\]" } {
		unbuffer
		lappend newparsednick [list $typeclose]
		incr pos_char 3
	} elseif { $next_char2 eq "=" } {
		set next_char3 [string index [lindex $unit 1] [expr $pos_char +4]]
		if {$next_char3 eq "#"} {
			set next_char4 [string index [lindex $unit 1] [expr $pos_char +11] ]
			if {$next_char4 eq "\]"} {
				set num [string range [lindex $unit 1] [expr $pos_char+5] [expr $pos_char+10]]
				if { [catch {expr 0x${num}}] } {
					return
				}
				unbuffer
				lappend newparsednick [list $type "#$num"]
				incr pos_char 11
			}
		} elseif {[string match \[0-9\] $next_char3]} {
			set num [findnum $up 1]
			if {$num != -1} {
				lappend newparsednick [list $type $num]
				incr pos_char [expr [string length $num] + 4]
			}
		} else {
			set end [string first "\]" "[lindex $unit 1]" [expr $pos_char +4]]
			if {$end != -1} {
				set colorname [string range [lindex $unit 1] [expr $pos_char +4] [expr $end-1]]
				if {[IsColorName $colorname]} {
					unbuffer
					lappend newparsednick [list $type $colorname]
					incr pos_char [expr [string length $colorname] + 4]
				}
			}
		}
	}
}


proc nick_background {} {
	variable unit
	variable pos_char
	variable newparsednick

	set next_char2 [string index [lindex $unit 1] [expr $pos_char +3] ]
	if {[string match \[0-9\] $next_char2]} {
		set next_char3 [string index [lindex $unit 1] [expr $pos_char +4] ]
		if { $next_char3 eq "\]" } {
			unbuffer
			set cl [getColor "0$next_char2"]
			lappend newparsednick [list bg "#$cl"]
			lappend newparsednick [list jump 5 wasbg]
			incr pos_char 4
		} else {
			set next_char4 [string index [lindex $unit 1] [expr $pos_char +5] ]
			if {$next_char4 eq "\]"} {
				unbuffer
				set cl [getColor "$next_char2$next_char3"]
				lappend newparsednick [list bg "#$cl"]
				lappend newparsednick [list jump 6 wasbg]
				incr pos_char 5
			}
		}
	} elseif {$next_char2 eq "#"} {
		set next_char3 [string index [lindex $unit 1] [expr $pos_char +10] ]
		if {$next_char3 eq "\]"} {
			set num [string range [lindex $unit 1] [expr $pos_char+4] [expr $pos_char+9]]
			if { [catch {expr 0x${num}}] } { return }
			unbuffer
			lappend newparsednick [list bg "#$num"]
			lappend newparsednick [list jump 11 wasbg]
			incr pos_char 10
		}
	}
}


proc faded_background_nick {} {
	variable unit
	variable pos_char
	variable newparsednick

	set next_char2 [string index [lindex $unit 1] [expr $pos_char +3] ]
	if { $next_char2 eq "\]" } {
		unbuffer
		lappend newparsednick [list bg reset]
		lappend newparsednick [list jump 4 wasbg]
		incr pos_char 3
	} elseif { $next_char2 eq "=" } {
		set next_char3 [string index [lindex $unit 1] [expr $pos_char +4]]
		if {$next_char3 eq "#"} {
			set next_char4 [string index [lindex $unit 1] [expr $pos_char +11] ]
			if {$next_char4 eq "\]"} {
				set num [string range [lindex $unit 1] [expr $pos_char+5] [expr $pos_char+10]]
				if { [catch {expr 0x${num}}] } { return }
				unbuffer
				lappend newparsednick [list bg reset]
				lappend newparsednick [list jump 12 wasbg]
				incr pos_char 11
			}
		} elseif {[string match \[0-9\] $next_char3]} {
			set next_char4 [string index [lindex $unit 1] [expr $pos_char +5] ]
			if { $next_char4 eq "\]" } {
				lappend list_colors 0
				unbuffer
				lappend newparsednick [list bg reset]
				lappend newparsednick [list jump 6 wasbg]
				incr pos_char 5
			} else {
				set next_char5 [string index [lindex $unit 1] [expr $pos_char +6] ]
				if {$next_char5 eq "\]"} {
					unbuffer
					lappend newparsednick [list bg reset]
					lappend newparsednick [list jump 7 wasbg]
					incr pos_char 6
				}
			}
		}
	}
}


proc colored_nick_IRC_style {} {
	variable unit
	variable pos_char
	variable newparsednick

	set old_pos_char $pos_char
	set next_char2 [string index [lindex $unit 1] [expr $pos_char +1] ]
	if {[string match \[0-9\] $next_char2]} {
		set next_char3 [string index [lindex $unit 1] [expr $pos_char +2] ]
		if {[string match \[0-9\] $next_char3]} {
			set colorcode ${next_char2}${next_char3}
			incr pos_char 2
		} else {
			set colorcode $next_char2
			incr pos_char 1
		}

		unbuffer

		if {$colorcode < 67} {
			set color "#[getColor $colorcode]"
			lappend newparsednick [list irccolour $color]
		} else {
			lappend newparsednick [list irccolour reset]
		}
	} elseif {$next_char2 eq "#"} {
		set num [string range [lindex $unit 1] [expr $pos_char + 2] [expr $pos_char +7]]
		if { [catch {expr 0x${num}}] } { return }
		unbuffer
		lappend newparsednick [list irccolour "#${num}"]
		incr pos_char 7
	} elseif {$next_char2 eq "("} {
		set color [string range [lindex $unit 1] [expr $pos_char +1] [expr $pos_char +13]]
		if {[string match "(\[0-9\]\[0-9\]\[0-9\],\[0-9\]\[0-9\]\[0-9\],\[0-9\]\[0-9\]\[0-9\])" $color] } {
			scan $color "(%3u,%3u,%3u)" red green blue
			unbuffer
			if {$red < 256 && $green < 256 && $blue < 256} {
				set color [format "#%02X%02X%02X" $red $green $blue]
				lappend newparsednick [list irccolour $color]
			}
			incr pos_char 13
		} elseif { [string match -nocase "(\[0-9a-z\]\[0-9a-z\]\[0-9a-z\],\[0-9a-z\]\[0-9a-z\]\[0-9a-z\],\[0-9a-z\]\[0-9a-z\]\[0-9a-z\])" $color] } {
			unbuffer
			incr pos_char 13
		}
	}

	if { "[string index [lindex $unit 1] [expr $pos_char +1] ]" eq "," } {
		set next_char5 [string index [lindex $unit 1] [expr $pos_char +2] ]
		if {[string match \[0-9\] $next_char5]} {
			set next_char6 [string index [lindex $unit 1] [expr $pos_char +3] ]
			if {[string match \[0-9\] $next_char6]} {
				incr pos_char 3
			} else {
				incr pos_char 2
			}
		} elseif {$next_char5 eq "#"} {
			set num [string range [lindex $unit 1] [expr $pos_char + 3] [expr $pos_char +8]]
			if { [catch {expr 0x${num}}] } { return }
			unbuffer
			incr pos_char 8
		} elseif {$next_char5 eq "("} {
			set color [string range [lindex $unit 1] [expr $pos_char +2] [expr $pos_char +14]]
			if {[string match -nocase "(\[0-9a-z\]\[0-9a-z\]\[0-9a-z\],\[0-9a-z\]\[0-9a-z\]\[0-9a-z\],\[0-9a-z\]\[0-9a-z\]\[0-9a-z\])" $color] } {
				unbuffer
				incr pos_char 14
			}
		}
	}
}


proc fade {penultimate_color last_color col} {
	variable newparsednick

	set num_chars 0
	set lung_newparsednick [llength $newparsednick]
	set pos -1

	for {set elem $lung_newparsednick} {$elem >= 0} {incr elem -1} {
		set unit [lindex $newparsednick $elem]
		if {[lindex $unit 0] eq "startfadecolour" && [lindex $unit 2] == $col} {
			if { [lindex $unit 1] == "$penultimate_color"} {
				set pos $elem
				break
			}
		}
	}

	if {$pos == -1} { ERROR_POS }
	set newparsednick [lreplace $newparsednick $pos $pos]

	for {set x $pos} {$x < $lung_newparsednick} {incr x} {
		set unit [lindex $newparsednick $x]
		switch [lindex $unit 0] {
			"smiley" { incr num_chars [string length [lindex $unit 2] ] }
			"text"   { incr num_chars [string length [lindex $unit 1] ] }
			"font"   {
					if {[lindex [lindex $unit 1] 1] eq "reset"} {
						incr num_chars 4
					} else {
						incr num_chars 3
					}
				}
			"stoppost" - "startpost" {
				set value [lindex $unit 1]
				if {$value ne ""} { incr num_chars $value }
			}
			"jump" { incr num_chars [lindex $unit 1] }
		}
	}

	set pen [list [expr 0x[string range $penultimate_color 1 2]] [expr 0x[string range $penultimate_color 3 4]] [expr 0x[string range $penultimate_color 5 6]]]
	set last [list [expr 0x[string range $last_color 1 2]] [expr 0x[string range $last_color 3 4]] [expr 0x[string range $last_color 5 6]]]
	set diff [list [expr [lindex $last 0] - [lindex $pen 0]] [expr [lindex $last 1] - [lindex $pen 1]] [expr [lindex $last 2] - [lindex $pen 2]]]

	if { $num_chars > 1} {
		set num_chars [expr $num_chars - 1.00]
	} elseif { $num_chars == 0} {
		return 2
	}
	set quantity [list ]
	for {set x 0} {$x<3} {incr x} {
		if {[lindex $diff $x] > 0} {
			lappend quantity [expr [lindex $diff $x] / $num_chars]
		} elseif {[lindex $diff $x] < 0} {
			lappend quantity [expr [expr [expr [lindex $diff $x] * -1 ] / $num_chars] * -1]
		} else {
			lappend quantity 0
		}
	}

	set tempparsednick [list ]
	for {set x 0} {$x<$pos} {incr x} {
		lappend tempparsednick [lindex $newparsednick $x]
	}

	set last_faded 1
	for {set x $pos} {$x < $lung_newparsednick} {incr x} {
		set unit [lindex $newparsednick $x]
		if {[lindex $unit 0] eq "smiley"} {
			lappend tempparsednick [lindex $unit]
			set lung_smiley [string length [lindex $unit 2] ]

			if {$last_faded != 0} {
				incr lung_smiley -1
				set last_faded 0
			}

			for {set z 0} {$z < 3} {incr z} {
				set pen [lreplace $pen $z $z [expr [lindex $pen $z] + [expr $lung_smiley * [lindex $quantity $z]]]]
			}
		} elseif {[lindex $unit 0] eq "text"} {
			set lung_text [string length [lindex $unit 1] ]
			for {set y 0} {$y < $lung_text} {incr y} {
				set color "#"
				for {set z 0} {$z < 3} {incr z} {
					if {$last_faded != 0} {
						set p [lindex $pen $z]
						if {$z == 2} { set last_faded 0 }
					} else {
						set p [expr [lindex $pen $z] + [lindex $quantity $z]]
						set pen [lreplace $pen $z $z $p]
					}
					set p [format "%0.0f" $p]
					if {$p < 16} {
						append color "0[format %x $p]"
					} else {
						append color [format %x $p]
					}
				}

				if {[string length $color] != 7} { ERRORE }

				set char [string index [lindex $unit 1] $y]
				if {$char ne " "} {
					lappend tempparsednick [list colour $color]
				}
				lappend tempparsednick [list text $char]
			}
		} elseif {[lindex $unit 0] eq "startpost"} {

			set identificator [lindex $unit 2]
			set q 1
			set tot 0
			for {set x $x} {$q > 0} {incr x} {
				lappend tempparsednick [lindex $newparsednick $x]
				set unit [lindex $newparsednick $x]
				if {[lindex $unit 0] == "text"} {
					incr tot [string length [lindex $unit 1] ]
				} elseif {[lindex $unit 0] == "smiley"} {
					incr tot [string length [lindex $unit 2] ]
				} elseif {[lindex $unit 0] == "font"} {
					if {[lindex [lindex $unit 1] 1] == "reset"} {
						incr tot 4
					} else {
						incr tot 3
					}
				} elseif {[lindex $unit 0] == "stoppost"} {
					incr tot [lindex $unit 1]

					if {$identificator == [lindex $unit 2]} {
						set q -1
						incr x -1
						if {$last_faded != 0} {
							incr tot -1
							set last_faded 0
						}
						for {set z 0} {$z < 3} {incr z} {
							set pen [lreplace $pen $z $z [expr [lindex $pen $z] + [expr $tot * [lindex $quantity $z]]]]
						}
					}
				} elseif {[lindex $unit 0] == "startpost" || [lindex $unit 0] == "jump"} {
					incr tot [lindex $unit 1]
				} elseif {[lindex $newparsednick $x] == ""} {
					set q -1
					incr x -1

					if {$last_faded != 0} {
						incr tot -1
						set last_faded 0
					}
					for {set z 0} {$z < 3} {incr z} {
						set pen [lreplace $pen $z $z [expr [lindex $pen $z] + [expr $tot * [lindex $quantity $z]]]]
					}

					set tempparsednick [lreplace $tempparsednick end end [list nocolour]]
				}
				incr q 1
				if {$q >= 150} { return -1 }
			}
		} elseif {[lindex $unit 0] eq "font"} {
			lappend tempparsednick [lindex $newparsednick $x]
			if {[lindex [lindex $unit 1] 1] eq "reset"} {
				set jump 4
			} else {
				set jump 3
			}

			if {$last_faded != 0} {
				incr jump -1
				set last_faded 0
			}

			for {set z 0} {$z < 3} {incr z} {
				set pen [lreplace $pen $z $z [expr [lindex $pen $z] + [expr $jump * [lindex $quantity $z]]]]
			}
		} elseif {[lindex $unit 0] eq "stoppost"} {
			lappend tempparsednick [lindex $newparsednick $x]
			set lung [lindex $unit 1]
			if {$last_faded != 0} {
				incr lung -1
				set last_faded 0
			}
			for {set z 0} {$z < 3} {incr z} {
				set pen [lreplace $pen $z $z [expr [lindex $pen $z] + [expr $lung * [lindex $quantity $z]]]]
			}
		} elseif {[lindex $unit 0] eq "jump"} {
			lappend tempparsednick [lindex $newparsednick $x]
			set lung [lindex $unit 1]
			if {$last_faded != 0} {
				incr lung -1
				set last_faded 0
			}
			for {set z 0} {$z < 3} {incr z} {
				set pen [lreplace $pen $z $z [expr [lindex $pen $z] + [expr $lung * [lindex $quantity $z]]]]
			}
		} elseif {$unit eq "stopfadebyirc"} {
			for {set x $x} {$x < $lung_newparsednick} {incr x} {
				lappend tempparsednick [lindex $newparsednick $x]
			}
			set newparsednick $tempparsednick
			return
		} else {
			lappend tempparsednick [lindex $newparsednick $x]
		}
	}

	set last_faded "#"
	for {set z 0} {$z < 3} {incr z} {
		set p [format "%0.0f" [lindex $pen $z]]
		if {$p < 16} {
			append last_faded "0[format %x $p]"
		} else {
			append last_faded [format %x $p]
		}
	}

	if {($last_faded != [string tolower $last_color]) && ($num_chars != 1)} {break}

	set newparsednick $tempparsednick
}


proc getColor { num } {
	if {[string length $num] == 1} { 
		set num 0${num}
	} elseif {![string match \[0-9\] [string range $num 0 0]]} {
		return [getColorFromName $num]
	}
 
	if {$num < 34} {
		array set colors [list  \
			00 "FFFFFF" 01 "000000" 02 "00007F" 03 "009300" 04 "FF0000" \
			05 "7F0000" 06 "9C009C" 07 "FC7F00" 08 "FFFF00" 09 "00FC00" \
			10 "009393" 11 "00FFFF" 12 "2020FC" 13 "FF00FF" 14 "7F7F7F" \
			15 "D2D2D2" 16 "E7E6E4" 17 "CFCDD0" 18 "FFDEA4" 19 "FFAEB9" \
			20 "FFA8FF" 21 "B4B4FC" 22 "BAFBE5" 23 "C1FFA3" 24 "FAFDA2" \
			25 "B6B4D7" 26 "A2A0A1" 27 "F9C152" 28 "FF6D66" 29 "FF62FF" \
			30 "6C6CFF" 31 "68FFC3" 32 "8EFF67" 33 "F9FF57" ]
	} else {
		array set colors [list  \
			34 "858482" 35 "6E6B7D" 36 "FFA01E" 37 "F92611" 38 "FF20FF" \
			39 "202BFF" 40 "1EFFA5" 41 "60F913" 42 "FFF813" 43 "5E6464" \
			44 "4B494C" 45 "D98812" 46 "EB0505" 47 "DE00DE" 48 "0000D3" \
			49 "03CC88" 50 "59D80D" 51 "D4C804" 52 "000268" 53 "18171C" \
			54 "944E00" 55 "9B0008" 56 "980299" 57 "01038C" 58 "01885F" \
			59 "389600" 60 "9A9E15" 61 "473400" 62 "4D0000" 63 "5F0162" \
			64 "000047" 65 "06502F" 66 "1C5300" 67 "544D05" ]
	}

	if { [info exists colors($num)] } {
		return [set colors($num)]
	} elseif {$num > 67 && $num < 100} {
		return "000000"
	} else {
		return -1
	}
}

proc getColorFromName {name} {
	array set colors [list  \
		white "FFFFFF" black "000000" marine "00007F" green "009300" red "FF0000" \
		brown "7F0000" purple "9C009C" orange "FC7F00" yellow "FFFF00" lime "00FC00" \
		teal "009393" aqua "00FFFF" blue "2020FC" pink "FF00FF" gray "7F7F7F" \
		silver "D2D2D2" ]
	set name_lower [string tolower $name]
	if { [info exists colors($name_lower)] } {
		return [set colors($name_lower)]
	} else {
		return -1
	}
}

proc IsColorName {txt} {
	switch [string tolower $txt] {
		white	{ return 1 }
		black	{ return 1 }
		marine	{ return 1 }
		green	{ return 1 }
		red	{ return 1 }
		brown	{ return 1 }
		purple	{ return 1 }
		orange	{ return 1 }
		yellow	{ return 1 }
		lime	{ return 1 }
		teal	{ return 1 }
		aqua	{ return 1 }
		blue	{ return 1 }
		pink	{ return 1 }
		gray	{ return 1 }
		silver	{ return 1 }
		default { return 0 }
	}
}


proc findnum {{opt 0}} {
	variable unit
	variable pos_char

	set pos_temp [expr 3 + $pos_char + $opt]
	set num [string index [lindex $unit 1] $pos_temp ]
	set num_buffer ""
	while { 1 } {
		if {[string match \[0-9\] $num]} {
			append num_buffer $num
			incr pos_temp 1
			set num [string index [lindex $unit 1] $pos_temp]
		} elseif {$num eq "\]"} {
			unbuffer
			return $num_buffer
		} else {
			return -1
		}
	}
}


proc deinit {} {
}

}

