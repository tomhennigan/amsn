########################################################
#            GLogs plugin for aMSN
########################################################
# Author: Ignacio Larrain (ilarrain@gmail.com)
# Created: 23/11/2004
########################################################

namespace eval ::glogs {
	################################################
	# Initialization proc for the plugin.
	proc InitPlugin { dir } {
		package require mime
		if {[catch {package require smtp 1.4}]} {
			source $dir/smtp.tcl
		}
		#register plugin
		::plugins::RegisterPlugin "GLogs"
		#loading lang
		set langdir [append dir "/lang"]
		set lang [::config::getGlobalKey language]
		load_lang en $langdir
		load_lang $lang $langdir
		#plugin config
		array set ::glogs::config {
			smtp_server "smtp.gmail.com"
			smtp_port 25
			smtp_user ""
			smtp_pass ""
			send_to ""
			showfooter 1
			htmlformat 1
		}
		#Config gui.
		set ::glogs::configlist [ list  \
			[list label "[trans serverlabel]"] \
			[list str "[trans smtpserver]" smtp_server] \
			[list str "[trans smtpport]" smtp_port] \
			[list label ""] \
			[list label "[trans userlabel]"] \
			[list str "[trans smtpuser]" smtp_user] \
			[list pass "[trans smtppass]" smtp_pass] \
			[list label ""] \
			[list label "[trans sendtolabel]"] \
			[list str "[trans sendto]" send_to] \
			[list label ""] \
			[list label "[trans logslabel]"] \
			[list bool "[trans showfooter]" showfooter] \
			[list bool "[trans htmlformat] \[not implemented\]" htmlformat] \
		]
		
		# Funtion to set correct zone, because a problem on tcllib's mime packages on some locales.
		set clock [clock seconds]
		set gmt [clock format $clock -format "%Y-%m-%d %H:%M:%S" -gmt true]
		if {[set diff [expr {($clock-[clock scan $gmt])/60}]] < 0} {
			set s -
			set diff [expr {-($diff)}]
		} else {
			set s +
		}
		set zone [format %s%02d%02d $s [expr {$diff/60}] [expr {$diff%60}]]
		
		#register events
		::plugins::RegisterEvent "GLogs" chat_msg_received msg_received
#		::plugins::RegisterEvent "GLogs" chat_msg_sent msg_received
		::plugins::RegisterEvent "GLogs" user_leaves_chat user_leaves_chat
		::plugins::RegisterEvent "GLogs" user_joins_chat user_joins_chat
		::plugins::RegisterEvent "GLogs" ft_loged ft_loged
		::plugins::RegisterEvent "GLogs" OnDisconnect log_out
	}
	
	variable LogsArray
	
	#///////////////////////////////////////////////////////////////////////////////
	# ConfArray (email action [conf])
	# Controls information for array for chosen user for conference/conversation messages
	# action can be :
	#	newset : Sets new conf if doesn't exist already
	#	set : Sets new conf number for certain user only if never set before
	#	get : Returns conf number for certain user, returns 0 if no conf number set yet
	#	unset : Unsets conf number for certain user.
	
	proc ConfArray { email action {conf 0}} {
	
		variable ConfInfo
	
		switch $action {
			newset {
				if { [info exists ConfInfo($email)] == 0 } {
					set ConfInfo($email) $conf
				}
			}
	
			set {
				if { [info exists ConfInfo($email)] } {
					set ConfInfo($email) $conf
				}
			}
	
			unset {
				if { [info exists ConfInfo($email)] } {
					unset ConfInfo($email)
				} else {
					plugins_log "GLogs" "DEBUG: Calling unset on an unexisting variable\n"
				}
			}
	
			get {
				if { [info exists ConfInfo($email)] } {
					return $ConfInfo($email)
				} else {
					return 0
				}
			}
		}
	}
	
	#///////////////////////////////////////////////////////////////////////////////
	# msg_received (event evPar)
	# Gets variables from event and sends them to log_msg
	proc msg_received {event evPar} {
		upvar 2 chatid chatid
		upvar 2 nick nick
		upvar 2 msg msg
		upvar 2 user user
		log_msg $user $nick $msg $chatid
	}
	
	#///////////////////////////////////////////////////////////////////////////////
	# log_msg (user nick msg chatid)
	# Parses messages and send them to log_write for appropiate storage.
	# Checks for conferences and fixes conflicts if we have 2 windows for same user (1 private 1 conference)
	# chatid : the chatid where the message was typed/sent
	# user : user who sent message
	# nick : user's nick
	# msg : msg
	proc log_msg {user nick msg chatid} {
		set user_list [::MSN::usersInChat $chatid]
		foreach user_info $user_list {
			set user_login [lindex $user_info 0]
			if { [llength $user_list] > 1 } {
				::glogs::log_write $user_login "$nick ($user): $msg\n" 1 $user_list
			} else {
				# for 2 windows (1 priv 1 conf)
				# if conf exists for current user & current chatid is not a conf
				if { [ConfArray $user_login get] == 1 && $chatid == $user_login} {
					::glogs::log_write $user_login "\[[trans linprivate]\] $nick ($user): $msg\n" 2 $user_list
				} else {
					::glogs::log_write $user_login "$nick ($user): $msg\n" 0 $user_list
				}
			}
		}
	}

	#///////////////////////////////////////////////////////////////////////////////
	# log_write (email txt (conf) (userlist))
	# Writes txt to log of user given by email
	# conf 1 is used for conference messages
	proc log_write { email txt {conf 0} {user_list ""}} {
		
		after cancel "::glogs::send_log [set email]"
		after 300000 "::glogs::send_log [set email]"
		
		ConfArray $email newset $conf
		set last_conf [ConfArray $email get]
		
		foreach user_info $user_list {
			if { [info exists users] } {
				set users "$users, [lindex $user_info 0]"
			} else {
				set users [lindex $user_info 0]
			}
		}	
	
		if {[info exists ::glogs::LogsArray($email)]} {
			if { $last_conf != $conf && $conf != 2} {
				if { $conf == 1 } {
					append ::glogs::LogsArray($email) "\[[trans lprivtoconf ${users}]\]\n"
					ConfArray $email set $conf
				} elseif { [llength $user_list] == 1 } {
					append ::glogs::LogsArray($email) "\[[trans lconftopriv ${users}]\]\n"
					ConfArray $email set $conf
				}
			}
		} else {
			if { $conf == 0 } {
				set ::glogs::LogsArray($email) "\[[trans lconvstarted [clock format [clock seconds] -format "%d %b %Y %T"]]\]\n"
			} else {
				set ::glogs::LogsArray($email) "\[[trans lenteredconf $email [clock format [clock seconds] -format "%d %b %Y %T"]] \(${users}\) \]\n"
			}
		}
		append ::glogs::LogsArray($email) "[timestamp] $txt"
	}

	proc log_out {event evPar} {
		foreach {who txt} [array get ::glogs::LogsArray] {
			send_log $who
		}
	}
	
	proc user_joins_chat {event evPar} {
	
		upvar 2 chatid chatid
		upvar 2 usr_name usr_name
		
		set user_list [::MSN::usersInChat $chatid]
		# If there is already 1 user in chat
		if { [llength $user_list] > 1  } {
			foreach user_info $user_list {
				set login [lindex $user_info 0]
				if { $login != $usr_name && [info exists ::glogs::LogsArray($login)]} {
					log_write $login "\[[trans ljoinedconf $usr_name]\]\n"
				}
			}
		}
		if {[info exists ::glogs::LogsArray($usr_name)]} {
			append ::glogs::LogsArray($usr_name) "\[[trans lconvstarted [clock format [clock seconds] -format "%d %b %Y %T"]]\]\n"
		}
	}	
	
	proc user_leaves_chat {event evPar} {
	
		upvar 2 chatid chatid
		upvar 2 usr_name usr_name
		
		set user_list [::MSN::usersInChat $chatid]
		# If was in conference before this user leaves
		if { [llength $user_list] >= 1 && $usr_name != [lindex [lindex $user_list 0] 0] } {
			foreach user_info $user_list {
				if {[info exists ::glogs::LogsArray([lindex $user_info 0])]} {
					 log_write [lindex $user_info 0] "\[[trans lleftconf $usr_name]\]\n"
				}
				if { [llength $user_list] == 1 } {
					ConfArray [lindex $user_info 0] set 3
				}
			}
		}
		if {[info exists ::glogs::LogsArray($usr_name)]} {
			append ::glogs::LogsArray($usr_name) "\[[trans lclosedwin $usr_name [clock format [clock seconds] -format "%d %b %Y %T"]]\]\n\n"
		}
	}	
	
	proc ft_loged {event evPar} {
	
		upvar 2 email email
		upvar 2 txt txt
		
		write_log $email "[timestamp] $txt\n"
		
	}	
	
	proc send_log {email} {
		after cancel "::glogs::send_log $email"
		plugins_log "GLogs" "Sending log for $email to $::glogs::config(send_to)\n"
		if {$::glogs::config(showfooter)} {
			set footer "\n[trans footer]"
		} else {
			set footer ""
		}
		set body $::glogs::LogsArray($email)
		set subject "[trans defaultprefix]$email"
		append body $footer
		set tok [mime::initialize -canonical text/plain -string $body]
		::smtp::sendmessage $tok \
			-servers [list $::glogs::config(smtp_server)] -ports [list $::glogs::config(smtp_port)] \
			-username  $::glogs::config(smtp_user)\
			-password  $::glogs::config(smtp_pass)\
			-header [list From $email] \
			-header [list To $::glogs::config(send_to)] \
			-header [list Reply-To $email] \
			-header [list Subject $subject] \
			-header [list Date "[::glogs::date_mailformat]"] \
			-header [list X-GLog Yes]
		mime::finalize $tok
		unset ::glogs::LogsArray($email)
	}
	
	proc date_mailformat { } {
		switch "[clock format [clock seconds] -format "%w"]" {
			"0"
				{ set weekday "Sun" }
			"1"
				{ set weekday "Mon" }
			"2"
				{ set weekday "Tue" }
			"3"
				{ set weekday "Wed" }
			"4"
				{ set weekday "Thu" }
			"5"
				{ set weekday "Fri" }
			default
				{ set weekday "Sat" }
		}
		switch "[clock format [clock seconds] -format "%m"]" {
			"01"
				{ set month "Jan" }
			"02"
				{ set month "Feb" }
			"03"
				{ set month "Mar" }
			"04"
				{ set month "Apr" }
			"05"
				{ set month "May" }
			"06"
				{ set month "Jun" }
			"07"
				{ set month "Jul" }
			"08"
				{ set month "Aug" }
			"09"
				{ set month "Sep" }
			"10"
				{ set month "Oct" }
			"11"
				{ set month "Nov" }
			default
				{ set month "Dec" }
		}
		return "$weekday, [clock format [clock seconds] -format "%d $month %Y %H:%M:%S"] $::glogs::zone"
	}
}
