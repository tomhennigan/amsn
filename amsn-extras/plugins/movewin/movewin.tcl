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
		}

		set ::movewin::configlist [list \
			[list str "x position" x] \
			[list str "y position" y] \
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

		if { [::movewin::on] } {
			wm geometry $vars(win) +$::movewin::config(x)+$::movewin::config(y)
			wm state $vars(win) normal
		}
	}

	proc ::movewin::message { event epvar } {
		upvar 2 $epvar vars
		upvar 2 $vars(chatid) chatid

		if { [::movewin::on] } {
			wm state [::ChatWindow::For $chatid] normal
		}
	}
}