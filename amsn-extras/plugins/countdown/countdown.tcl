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
		variable old_psm

		::plugins::RegisterPlugin Countdown
		::plugins::RegisterEvent Countdown PluginConfigured ConfigChanged
		::plugins::RegisterEvent Countdown contactlistLoaded Connected

		array set config [list date "1/1/2009" \
				      days {1} \
				      hours {1} \
				      minutes {1} \
				      prefixm {} \
				      suffixm { hours remaining to 2009!} \
				      prefixm {} \
				      suffixm { minutes remaining to 2009!} \
				      prefixd {J-} \
				      suffixd { days to 2009!} \
				      after {HAPPY NEW YEAR!!!} \
				      valid 1]
	
		set langdir [file join $dir "lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir

		set configlist [list \
				    [list str "[trans date]" date] \
				    [list label "[trans howtoshow1]"] \
				    [list label "[trans howtoshow2]"] \
				    [list bool "[trans showdays]" days] \
				    [list bool "[trans showhours]" hours] \
				    [list bool "[trans showminutes]" minutes] \
				    [list str "[trans prefixd]" prefixd] \
				    [list str "[trans suffixd]" suffixd] \
				    [list str "[trans prefixh]" prefixh] \
				    [list str "[trans suffixh]" suffixh] \
				    [list str "[trans prefixm]" prefixm] \
				    [list str "[trans suffixm]" suffixm] \
				    [list str "[trans after]" after] \
				   ]

		set old_psm [::abook::getPersonal PSM]

		ValidateDate
		AddAfter
		after idle ::countdown::DoCountdown
	}

	proc DeInit { } {
		variable old_psm
		after cancel ::countdown::DoCountdown
		
		::MSN::changePSM $old_psm
	}

	proc ConfigChanged { event evpar } {
		ValidateDate
		AddAfter
		after idle ::countdown::DoCountdown
	}
	
	proc Connected { event evpar } {
		::countdown::DoCountdown
	}

	proc ValidateDate {} {
		variable config
		if {[catch {clock scan $config(date)}] } {
			msg_box [trans invaliddate]
			set config(valid) 0
		} else {
			set config(valid) 1
		}

		if { $config(days) == 0 && $config(hours) == 0 && $config(minutes) == 0 } {
			msg_box [trans invalidshow]
			set config(days) 1
			set config(hours) 1
			set config(minutes) 1
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

			if {$config(days) && ($days > 1 || !$config(hours) && !$config(minutes)) } {
				set msg $config(prefixd)
				append msg $days
				append msg $config(suffixd)
				::MSN::changePSM $msg
			} elseif {$config(hours) && ($hours > 1 || !$config(minutes))} {
				set msg $config(prefixh)
				append msg $hours
				append msg $config(suffixh)
				::MSN::changePSM $msg
			} elseif { $config(minutes) } {
				set msg $config(prefixm)
				append msg $minutes
				append msg $config(suffixm)
				::MSN::changePSM $msg
			}
			
		}

		AddAfter
	}
}
