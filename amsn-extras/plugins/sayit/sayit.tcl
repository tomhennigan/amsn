#TODO:
#
# * have an option to have URL's replaced by "URL" for reading
# * incomming messages should be queued, now they play through eachother (linux only?) 

namespace eval ::sayit {
	variable config
	variable configlist

	proc InitPlugin { dir } {
		if { $::tcl_platform(platform) == "windows" } {
			if {[string equal $::version "0.94"]} {
				load [file join $dir winutils.dll]
			} else {
				package require WinUtils
			}
		}

		::plugins::RegisterPlugin sayit
		::plugins::RegisterEvent sayit chat_msg_received newmessage
		if { [string equal $::version "0.95b"] } {
			::plugins::RegisterEvent sayit ContactListColourBarDrawn draw
		}


		array set ::sayit::config {
			voice {}
			linpath {festival}
			snd_server_lin {0}
			showswitch {0}
			sayiton {1}
			notonfocus {1}
		}

		set ::sayit::configlist [list \
			[list str "Voice (Mac only)"  voice] \
			[list str "Path to festival (Linux)"  linpath] \
			[list bool "Sound server running (Linux)" snd_server_lin] \
			[list bool "Don't say message for focussed windows" notonfocus] \
			[list bool "Show switch in contactlist (need 0.95b)" showswitch] \
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

		if { ($email != [::config::getKey login]) && \
			((!$config(notonfocus)) || ([focus] == "")) && \
			((!$config(showswitch)) || $config(sayiton)) && \
			($msg != "") \
		} {
			if { $::tcl_platform(platform) == "windows" } {
				after 0 [list WinSayit "$msg"]
			} elseif { $::tcl_platform(os)== "Linux" } {
				if {$config(snd_server_lin)==1} {
					exec echo "(Parameter.set 'Audio_Method 'Audio_Command)(Parameter.set 'Audio_Command \"esdplay \$FILE\")(Parameter.set 'Audio_Required_Format 'snd)(SayText \"$msg\")" | festival
				} else {
					exec echo \"$msg\" | $config(linpath) --tts &
				}
			} else {
				if {$config(voice)!=""} {
					exec say -v $config(voice) $msg
				} else {
					exec say $msg
				}
			}
		}
	}

	proc draw {event evPar} {		
		upvar 2 $evPar vars
		variable config
		if { $config(showswitch) } {
			set imag $::pgBuddyTop.mystatus.xxxsayit
			if { $config(sayiton) == 1} {
				label $imag -image [::skin::loadPixmap bell]
			} else {
				label $imag -image [::skin::loadPixmap belloff]
			}
			$imag configure -cursor hand2 -borderwidth 0 -padx 0 -pady 0
			$::pgBuddyTop.mystatus window create [$::pgBuddyTop.mystatus index "1.0 lineend"] -window $imag -padx 5 -pady 0

			bind $imag <Button1-ButtonRelease> "::sayit::togglespeach"
		}
	}

	proc togglespeach { } {
		variable config
		if { $config(sayiton) == 1 } {
			set config(sayiton) 0
		} else {
			set config(sayiton) 1
		}
		::cmsn_draw_online
	}
}
