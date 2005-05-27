lappend auto_path "./"
lappend auto_path "../"
package require pixmapoption


proc refresh_station { } {
	variable station
	variable bass
	set text "You're listening to BBC Radio $station with bass boost $bass"
	.label configure -text $text
}



label .label

image create photo check -file check.gif
image create photo checkhover -file checkhover.gif
image create photo checkpressed -file checkpress.gif

image create photo radio -file radio.gif
image create photo radiohover -file radiohover.gif
image create photo radiopressed -file radiopress.gif


pixmapoption .radio1 -buttontype radiobutton -text "Radio 1" -image radio -hoverimage radiohover \
	-selectimage radiopressed -variable station -value 1 -command "refresh_station"

pixmapoption .radio2 -buttontype radiobutton -text "Radio 2" -image radio -hoverimage radiohover \
	-selectimage radiopressed -variable station -value 2 -command "refresh_station"

pixmapoption .radio3 -buttontype radiobutton -text "Radio 3" -image radio -hoverimage radiohover \
	-selectimage radiopressed -variable station -value 3 -command "refresh_station"

pixmapoption .radio4 -buttontype radiobutton -text "Radio 4" -image radio -hoverimage radiohover \
	-selectimage radiopressed -variable station -value 4 -command "refresh_station"

pixmapoption .check1 -buttontype checkbutton -text "Bass boost" -image check \
	-hoverimage checkhover	-selectimage checkpressed -variable bass -command "refresh_station" -onvalue "on" -offvalue "off"

refresh_station

pack .label .radio1 .radio2 .radio3 .radio4 .check1 -side top -pady 2

