#######################################################
#               COUNTDOWN PLUGIN                      #
#######################################################
#######################################################


namespace eval ::countdown {
	variable config
	variable configlist
	variable language

	proc InitPlugin { dir } {
		variable config
		variable language
		variable configlist

		::plugins::RegisterPlugin Countdown
		::plugins::RegisterEvent Countdown PluginConfigured ConfigChanged
		array set config [list date "1/1/2008" \
				      method {3} \
				      prefixm {} \
				      suffixm { minutes remaining to 2008!} \
				      prefixd {J-} \
				      suffixd { to 2008!} \
				      after {HAPPY NEW YEAR!!!} \
				      valid 1]
	
		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir

		set configlist [list \
				    [list str "[trans date]" date] \
				    [list rbt "[trans showdays]" "[trans showminutes]" "[trans showboth]" method] \
				    [list str "[trans prefixd]" prefixd] \
				    [list str "[trans suffixd]" suffixd] \
				    [list str "[trans prefixm]" prefixm] \
				    [list str "[trans suffixm]" suffixm] \
				    [list str "[trans after]" after] \
				   ]
		ValidateDate
		AddAfter
		after idle ::countdown::DoCountdown
	}

	proc ConfigChanged { event evpar } {
		ValidateDate
		AddAfter
		after idle ::countdown::DoCountdown
	}
	
	proc ValidateDate {} {
		variable config
		if {[catch {clock scan $config(date)}] } {
			msg_box [trans invaliddate]
			set config(valid) 0
		} else {
			set config(valid) 1
		}
		plugins_log Countdown "Validated new date \"$config(date)\" : $config(valid)"
	}

	proc AddAfter { } {
		after cancel ::countdown::DoCountdown
		set remaining_secs [expr [clock scan "next minute" -base [clock scan [clock format [clock seconds] -format "%m/%d/%y %H:%M"]]]  - [clock seconds]]
		set next_minute [expr $remaining_secs * 1000]
		plugins_log Countdown "Next minute in $remaining_secs seconds"
		after $next_minute ::countdown::DoCountdown		
	}

	proc DoCountdown { } {
		variable config
		
		# Invalid date, don't even bother.
		if {$config(valid) == 0} {
			plugins_log Countdown "Invalid date so returning"
			return
		}

		set dest [clock scan $config(date)]
		set seconds [expr $dest - [clock seconds]]
		plugins_log Countdown "$seconds seconds remaining for countdown date"
		if {$seconds < 0 } {
			plugins_log Countdown "Countdown expired"
			::MSN::changePSM $config(after)
		} else {
			set minutes [expr $seconds / 60]
			if { $seconds % 60 > 30 } {
				incr minutes
			}
			plugins_log Countdown "$minutes minutes remaining for countdown date"
			set hours [expr $minutes / 60]
			if { $minutes % 60 > 0 } {
				incr hours
			}
			plugins_log Countdown "$hours hours remaining for countdown date"
			set days [expr $hours / 24]
			if { $hours % 24 > 0 } {
				incr days
			}
			plugins_log Countdown "$days days remaining for countdown date"
			switch -- $config(method) {
				1 {
					set msg $config(prefixd)
					append msg $days
					append msg $config(suffixd)
					::MSN::changePSM $msg
					plugins_log Countdown "Method 1 setting PSM to $msg"
				}
				2 {
					set msg $config(prefixm)
					append msg $
					append msg $config(suffixm)
					::MSN::changePSM $msg
					plugins_log Countdown "Method 2 setting PSM to $msg"
				} 
				3 {
					if {$days > 1} {
						set msg $config(prefixd)
						append msg $days
						append msg $config(suffixd)
						::MSN::changePSM $msg
					} else {
						set msg $config(prefixm)
						append msg $minutes
						append msg $config(suffixm)
						::MSN::changePSM $msg
					}
					plugins_log Countdown "Method 3 setting PSM to $msg"
				}
			}
		}

		AddAfter
	}
}
