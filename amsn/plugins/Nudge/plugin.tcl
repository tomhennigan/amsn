##########################
# Nudge plugin info file #
##########################

proc InitPlugin { dir } {
	::plugins::RegisterPlugin Nudge
	source [file join $dir Nudge.tcl]
	::plugins::RegisterEvent Nudge PacketReceived received
	array set ::Nudge::config { 
		notify {1}
		shake {0}
		shakes {5} 
	} 
	set ::Nudge::configlist [list \
		[list bool "Notify nudges" notify] \
		[list bool "Shake the window:" shake] \
		[list str "Shakes per nudge:" shakes] \
	] 
}
