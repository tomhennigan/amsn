#######################################################
#             aMSN POP3 Checker Plugin                #
#        By Alberto Díaz and Arieh Schneier           #
#          POP3 Code from Tclib project               #
#######################################################
proc InitPlugin { dir } {
	source [file join $dir pop3.tcl]
	::plugins::RegisterPlugin pop3
	::plugins::RegisterEvent pop3 OnConnect start
	::plugins::RegisterEvent pop3 Load start
	::plugins::RegisterEvent pop3 OnDisconnect stop
	::plugins::RegisterEvent pop3 ContactListColourBarDrawn draw
	::plugins::RegisterEvent pop3 ContactListEmailsDraw addhotmail


	array set ::pop3::config {
		host {"your.mailserver.here"}
		user {"user_login@here"}
		pass {""}
		port {110}
		minute {5}
		notify {1}
	}

	set ::pop3::configlist [list \
		[list str "Check for new messages every ? minutes" minute] \
		[list str "POP3 Server"  host] \
		[list str "Your user login" user] \
		[list pass "Your password" pass] \
		[list str "Port (optional)" port] \
		[list bool "Show notify window" notify] \
	]
}