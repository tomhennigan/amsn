namespace eval ::sayit {
	variable config
	variable configlist

	proc InitPlugin { dir } {
		if { $::tcl_platform(platform) == "windows" } {
			load [file join $dir winsayit.dll]
		}

		::plugins::RegisterPlugin sayit
		::plugins::RegisterEvent sayit chat_msg_received newmessage

		array set ::sayit::config {
			voice {}
		}

		set ::sayit::configlist [list \
			[list str "Voice (Mac only)"  voice] \
		]
	}

	proc newmessage {event evpar} {
		variable config
		upvar 2 $evpar newvar
		upvar 2 $newvar(msg) msg
		upvar 2 $newvar(user) user

		#Define the 3 variables, email, nickname and message
		set email $user
		set nickname [::abook::getDisplayNick $user]

		if { (($email != [::config::getKey login]) && [focus] == "") && $msg != "" } {
			if { $::tcl_platform(platform) == "windows" } {
				WinSayit $msg
			} else {
				if {$config(voice)!=""} {
					exec say -v $config(voice) $msg
				} else {
					exec say $msg
				}
			}
		}
	}
}
