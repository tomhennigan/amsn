########################################################
#              SCRIPT TO LOAD THE PLUGIN
########################################################
# Maintainer: markitus (markitus@catmail.homelinux.org)
# Created: 13/09/2004
# Last Modify: 10/10/2004
# Version: 0.02
########################################################

proc InitPlugin { dir } {
	#register plugin
	::plugins::RegisterPlugin amsnplus
	source [file join $dir amsnplus.tcl]
	#plugin config
	array set ::amsnplus::config {
		colour_nicks {0}
	}
	#set ::amsnplus::configlist [ \
	#	list [list bool "Colour Nicks?" colour_nicks] \
	#]
	#register events
	::plugins::RegisterEvent amsnplus UserNameWritten parse_nick
	::plugins::RegisterEvent amsnplus chat_msg_send parseCommand
}
