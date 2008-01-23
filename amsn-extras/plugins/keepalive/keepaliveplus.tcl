 namespace eval ::keepalive {
  proc init { dir } {
	::plugins::RegisterPlugin KeepAlivePlus
	plugins_log KeepAlivePlus "Registered plugin"

	variable nickalive
	array set ::keepalive::nickalive [list]

	::plugins::RegisterEvent KeepAlivePlus user_joins_chat keepalive_plus_init
	::plugins::RegisterEvent KeepAlivePlus user_leaves_chat keepalive_plus_stop
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

	proc keepalive_plus {chatid} {
		set sb [::MSN::SBFor $chatid]
		if {$sb == 0} {
			after cancel "::keepalive::keepalive_plus ${chatid}"
			unset ::keepalive::nickalive($chatid)
			plugins_log KeepAlivePlus "YOU HAVE CLOSED THE CHAT"
			return 0
		}
		set last_activity [expr [clock seconds] - [$sb cget -last_activity]]
		if {$last_activity >47 } {
			set chat_temp $::keepalive::nickalive($chatid)
			set time_temp [lindex $chat_temp 0]
			if {$time_temp < 100} {

				set msg "MIME-Version: 1.0\r\nContent-Type: text/x-keepaliveamsn\r\n\r\n\r\n\r\n"
				set msg_len [string bytelength $msg]
				::MSN::WriteSBNoNL $sb "MSG" "U $msg_len\r\n$msg"

				after 50000 "::keepalive::keepalive_plus ${chatid}"
				unset ::keepalive::nickalive($chatid)
				incr time_temp 1
				set ::keepalive::nickalive($chatid) [list $time_temp]
				set chat_temp $::keepalive::nickalive($chatid)
				plugins_log KeepAlivePlus "ADD 1: $chatid - [lindex $chat_temp {}]"
			} else {
				plugins_log KeepAlivePlus "CANCEL: $chatid"
				after cancel "::keepalive::keepalive_plus ${chatid}"
				unset ::keepalive::nickalive($chatid)
				return
			}
		} else {
			set msg "MIME-Version: 1.0\r\nContent-Type: text/x-keepaliveamsn\r\n\r\n\r\n\r\n"
			set msg_len [string bytelength $msg]
			::MSN::WriteSBNoNL $sb "MSG" "U $msg_len\r\n$msg"

			unset ::keepalive::nickalive($chatid)
			set ::keepalive::nickalive($chatid) [list 0]
			plugins_log KeepAlivePlus "ACTIVITY FOR $chatid"
			after 50000 "::keepalive::keepalive_plus ${chatid}"
		}
	}

	proc keepalive_plus_stop {event evpar} {
		upvar 2 usr_name usr_name
		upvar 2 chatid chatid
		upvar 2 win_name win_name
		after cancel "::keepalive::keepalive_plus ${chatid}"
		unset ::keepalive::nickalive($chatid)
	}

  proc deinit { } {
    #Clean up?
  }
}