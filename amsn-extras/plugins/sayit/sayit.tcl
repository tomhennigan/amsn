#TODO:
#
# * have an option to have URL's replaced by "URL" for reading
# * a button or something in the gui to disable/enable the plugin (Arieh said he made this for him locally ?)
# * incomming messages should be queued, now they play through eachother (linux only?) 

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
			linpath {festival}
		}

		set ::sayit::configlist [list \
			[list str "Voice (Mac only)"  voice] \
			[list str "Path to festival (Linux)"  linpath] \
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
				after 0 "WinSayit \"$msg\""
			} elseif { $::tcl_platform(os)== "Linux" } {
				exec echo \"$msg\" | $config(linpath) --tts &
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
