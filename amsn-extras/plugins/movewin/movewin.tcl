namespace eval ::movewin {
	variable config
	variable configlist

	proc Init { dir } {
		::plugins::RegisterPlugin movewin
		::plugins::RegisterEvent movewin new_chatwindow move
		::plugins::RegisterEvent movewin chat_msg_received message

		array set ::movewin::config {
			x {0}
			y {0}
			state {}
			make_normal 0
		}

		set ::movewin::configlist [list \
			[list str "x position" x] \
			[list str "y position" y] \
			[list bool "Deiconify window when messages are received" make_normal] \
			[list str "only in states (blank for any)" state] \
		]
	}

	proc ::movewin::on { } {
		global automessage

		if { $::movewin::config(state) == "" } {
			return 1
		}

		if { [info exists automessage] && $automessage != -1 \
			&& [lsearch $::movewin::config(state) [lindex $automessage 0]] >=0 \
		   } {
			return 1
		} else {
			return 0
		}		
	}

	proc ::movewin::move { event epvar } {
		upvar 2 $epvar vars

		set w [winfo toplevel $vars(win)]
		after idle [list ::movewin::move_delayed $w]
	}

	proc ::movewin::move_delayed {w } {
		if { [winfo exists $w] && [::movewin::on] } {
			wm geometry $w +$::movewin::config(x)+$::movewin::config(y)
			if { $::movewin::config(make_normal) } {
				wm state $w normal
			}
		}
	}

	proc ::movewin::message { event epvar } {
		upvar 2 $epvar vars
		upvar 2 $vars(chatid) chatid

		set w [winfo toplevel [::ChatWindow::For $chatid]]
		if { [::movewin::on] && $::movewin::config(make_normal)} {
			wm state $w normal
		}
	}
}