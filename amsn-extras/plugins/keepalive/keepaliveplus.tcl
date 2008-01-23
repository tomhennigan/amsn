 namespace eval ::keepalive {
	variable config
	variable configlist

  proc init { dir } {
	::plugins::RegisterPlugin KeepAlivePlus
	plugins_log KeepAlivePlus "Registered plugin"

	::plugins::RegisterEvent KeepAlivePlus chat_msg_sent message_sent
	::plugins::RegisterEvent KeepAlivePlus chat_msg_received message_received
	::plugins::RegisterEvent KeepAlivePlus chatwindow_closed cw_closed
	::plugins::RegisterEvent KeepAlivePlus user_leaves_chat keepalive_plus_stop
	array set ::keepalive::config {
		only_fln {0}
	}

	set ::keepalive::configlist [ list [ list bool "Only keep SBs alive when we are or appear Offline" only_fln ] ]
}

	proc keepalive_plus_init {event epvar} {
		upvar 2 usr_name usr_name ;#is the user that joins email
		upvar 2 chatid chatid ;# is the chat name
		upvar 2 win_name win_name ;#

		if {![info exists ::keepalive::nickalive($chatid)]} {
			set ::keepalive::nickalive($chatid) [list 1]
			set chat_temp $::keepalive::nickalive($chatid)
			after 50000 "::keepalive::keepalive_plus ${chatid}"
			plugins_log KeepAlivePlus "NEW: $chatid - [lindex $chat_temp {}]"
		}
	}

	proc send_keepalive_msg {sb} {
		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-keepaliveamsn\r\n\r\n\r\n\r\n"
		set msg_len [string bytelength $msg]
		::MSN::WriteSBNoNL $sb "MSG" "U $msg_len\r\n$msg"
		return
	}

	proc message_sent {event evpar} {
		upvar 2 nick nick
		upvar 2 msg msg
		upvar 2 chatid chatid
		upvar 2 win_name win_name
		upvar 2 fontfamily fontfamily
		upvar 2 fontstyle fontstyle
		upvar 2 fontcolor fontcolor
		after 50000 "::keepalive::keepalive_timer ${chatid}"
	}

	proc message_received {event evpar} {
		upvar 2 user user
                upvar 2 msg msg
                upvar 2 chatid chatid
		upvar 2 fontformat fontformat
		upvar 2 message message
		after 50000 "::keepalive::keepalive_timer ${chatid}"
	}

	proc keepalive_timer {chatid} {
		after cancel "::keepalive::keepalive_timer $chatid"
		set sb [::MSN::SBFor $chatid]
		if {$sb == 0} {
			plugins_log KeepAlivePlus "YOU HAVE CLOSED THE CHAT"
			return
		} else {
			if { $::keepalive::config(only_fln) == 0 || [::MSN::myStatusIs] == "FLN" || [::MSN::myStatusIs] == "HDN" } {
				::keepalive::send_keepalive_msg $sb
			}
		}
		after 50000 "::keepalive::keepalive_timer $chatid"
	}

	proc cw_closed {event evpar} {
		upvar 2 chatid chatid
		after cancel "::keepalive::keepalive_timer ${chatid}"
	}

	proc keepalive_plus_stop {event evpar} {
		upvar 2 usr_name usr_name
		upvar 2 chatid chatid
		upvar 2 win_name win_name
		after cancel "::keepalive::keepalive_timer ${chatid}"
	}

  proc deinit { } {
    #Clean up?
  }
}
