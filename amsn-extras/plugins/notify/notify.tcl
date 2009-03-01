#
#	Notify plugin by Yoda-BZH (yodabzh gmail com)
#
#	Display contact's login/logout/state changes using notify-send
#
#	You need both libnotify-bin and notify-deamon packages installed
#
#	Conversion to UTF-8 is handled
#
#	TODO:
#		* find why there's no dp
#		* find why we get a wrong/unexistant dp
#		* handle user prefs', if s/he want contact's connection, contact's disco, contact's state changes (partially done)
#		* handle email notifications
#		* -- add more here --
#		* finally clean the code
#
#	2008-05-10
#
#	2008-10-19 :
#		* Added "dash hack", thanks to nico@nc - http://www.amsn-project.net/forums/profile.php?mode=viewprofile&u=5798
#		* Re-enable sounds on events: http://www.amsn-project.net/forums/viewtopic.php?t=5824&postdays=0&postorder=asc&start=15 , thanks to nico@nc too
#		* bumped to version 1.3
#	2009-03-01 :
#		* Don't show the event if the user is bloqued (and the "don't show blocked user notification" config is set)
#		* Added OS Check
#		* Code cleaning
#		* Bumped to version 1.4
#



namespace eval ::notify {
	# variables
	variable config
	variable configlist


	proc initPlugin { dir } {
		#log "::notify::initPlugin"
		# register the plugin
		if { [::OnLinux] || [::OnBSD] || [::OnX11] || [::OnUnix] } {
			::plugins::RegisterPlugin "Notify"

			# register events
			::notify::registerEvents

			::config::setKey notifyonlysound 1

			# set the default values for config
			::notify::configArray
			checkForBin "notify-send"
			log "Plugin Notify activated" 1
		} else {
			tk_messageBox -parent .main -title "Warning" -icon warning -type ok -message "This plugin is not aviable on this platform."
		}
	}

	proc deInit { } {
		#log "::notify::deInit"
		::config::setKey notifyonlysound 0
	        log "Plugin Notify disactivated" 1
	}

	proc registerEvents { } {
		# ::plugins::RegisterEvent "name" type localProc
		::plugins::RegisterEvent "Notify" ChangeState userChangeState
		#::plugins::RegisterEvent "Notify" contactStateChange userChangeState
		#::plugins::RegisterEvent "Notify" UserConnect userConnected
	}

	proc configArray { } {
		array set ::notify::config {
			notify_send {notify-send} 
			enable {}
			pic_size {32}
			notify_header {aMSN: %email}
			notify_busy {1}
			debug {0}
		}
		
		set ::notify::configlist [list \
			[list str "notify send path" notify_send] \
			[list bool "enable" enable] \
			[list str "Pic size" pic_size ] \
			[list str "Header" notify_header ] \
			[list bool "Show notifications when busy" notify_busy ] \
			[list bool "Debug" debug ] \
		]
	}

	proc log { mess {force 0}} {
		variable config
		if { $config(debug) == 1 || $force == 1} {
			plugins_log Notify $mess
			#status_log "Notify: $mess"
			# TODO: when finished, remove status_log, just keep plugins_log
		}
	}

	proc checkForBin { bin } {
		variable config
	        #log "::notify::checkForBin $bin"
		if {![catch {exec $bin -v}]} {
			set $config(notify_send) "$bin"
		} elseif {![catch {exec "/opt/local/bin/$bin" -v}]} {
			set $config(notify_send) "/opt/local/bin/$bin"
		} elseif {![catch {exec "/usr/bin/$bin" -v}]} {
			set $config(notify_send) "/usr/bin/$bin"
		} elseif {![catch {exec "/usr/local/bin/$bin" -v}]} {
			set $config(notify_send) "/usr/local/bin/$bin"
		} elseif {![catch {exec "/sw/bin/$bin" -v}]} {
			set $config(notify_send) "/sw/bin/$bin"
		} else {
			set $config(notify_send) "plop"
		}
	}

	# thx authors of the music plugin
	proc exec_notify { txt {email ""} {urgency "normal"} {expire -1} {category "im.received"} {hint ""} } {
		global HOME
		variable config
		#log "exec_notify lvl 1"
        
	        set status [::MSN::myStatusIs]
	        if { $status == "BSY" && $config(notify_busy) != 1} {
			log "You are busy, so not disturbing you"
			return
	        }
		
		set notify $config(notify_send)
		set urgency	"--urgency=$urgency"
		
		if { $expire == -1 } {
			set expire [::config::getKey notifytimeout]
		}
		set expire 	"--expire-time=$expire"


		set nopreview 0
		set icon 0
		#log "exec_notify lvl 2"
		if { $email != "" } {
			# see protocol.tcl line ~6500 for this code
			set filename [::abook::getContactData $email displaypicfile ""]
			set icon "[file join $HOME displaypic cache $email ${filename}].png"
			if { "$icon" == "" } {
				log "icon is empty, breaking"
				set icon "--icon="
				#continue;
				# TODO: try to find out why there's no DP, and set the NoDP pic
			} else {
				#log "email check 1: icon is $icon"

				set callid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"
				#log "email check 1.1"
				
				if { [catch {set filesize [file size $icon]} res] } {
					log "oops, set filesize returned $res, continue-ing"
					set icon "--icon="
					# TODO: try to find out why there's no DP, and set the NoDP pic (bis)
					#continue
				} else {
					#log "catch set filesize returned: $res"
					#log "email check 1.2"
					set context "[binary format i 574][binary format i 2][binary format i $filesize][binary format i 0][binary format i $nopreview]"
					#log "email check 2"
					set file [ToUnicode [getfilename $icon]]

					set file [binary format a550 $file]
					set context "${context}${file}\xFF\xFF\xFF\xFF"
					#log "email check 3"

					#Here we resize the picture and save it in /FT/cache for the preview (we send it and we see it)
					create_dir [file join [set ::HOME] notify cache]
					if {[catch {set image [image create photo [TmpImgName] -file $icon]}]} {
						set image [::skin::getNoDisplayPicture]
					}
					#log "email check 4"

					if {[catch {::picture::ResizeWithRatio $image $config(pic_size) $config(pic_size)} res]} {
						#status_log "$res"
					}
					#log "email check 5"

					set file  "[file join [set ::HOME] notify cache ${callid}.png]"
					if {[catch {::picture::Save $image $file cxpng} res] } {
						#status_log "$res"
					}
					#log "email check 6"

					if {$image != "displaypicture_std_none"} {
						image delete $image
					}
					#log "email check 7"

					::skin::setPixmap ${callid}.png $file

					#log "email check 8"
					if { [catch { open $file} fd] == 0 } {
						fconfigure $fd -translation {binary binary }
						set context "$context[read $fd]"
						close $fd
					}
					#log "email check 9"

					set icon	"--icon=$file"
					#log "email check 10"
				}
			}
		}
		#log "exec_notify after email check"
		if { "$category" != "" } {
			set category	"--category=$category"
		}
		if { "$hint" != "" } {
			set hint	"--hint=$hint"
		}

		if { $config(notify_header) == "" } {
			set config(notify_header) "aMSN"
		}
		set title [ string map [list "%email" "$email" ] $config(notify_header) ]
	        #log "plop 1"

	        #log "plop 2"
		#set txt   [ string map { "[" "\\[" "]" "\\]" "(" "\\(" ")" "\\)" "\$" "\\\$" "-" "\\\\-" ">" "\\\\>" "<" "\\\\<" } $txt ]
		#set title [ string map { "[" "\\[" "]" "\\]" "(" "\\(" ")" "\\)" "\$" "\\\$" "-" "\\\\-" ">" "\\\\>" "<" "\\\\<" } $title ]
	        set txt [ ::notify::protect $txt ]
        	set title [ ::notify::protect $title ]
		#log "plop 3"
		# libnotify WANTS them to be in utf8
		#log "We are in ${::env(LANG)}"
		if { [string match "*UTF*" $::env(LANG) ] == 0 } {
			set txt [encoding convertto utf-8 $txt]
			set title [encoding convertto utf-8 $title]
			#log "Converted to UTF8, because we are in ${::env(LANG)}"
		}
		#log "plop 4"
	
		# thanks music plugin
	        set cmd [concat [list "exec" $notify $urgency $expire $icon $category "--" "$title" "$txt"  ]]
	        #log "executing $notify $urgency $expire $icon $category $hint \"$title\" \"$txt\""
			#log "executing $notify $cmd"
	        #if { [catch { eval [concat [list "exec"] $notify $urgency $expire $icon $category $hint "\"$title\"" "\"$txt\"" ]} result ] } {}
	        if { [catch { eval $cmd } result ] } {
			log "Error lauching $notify : $result"
		} else {
			#log "exec_notify: seems good"
		}
		file delete $file
	}

	proc protect { txt } {
		#return [ string map { "[" "\\[" "]" "\\]" "(" "\\(" ")" "\\)" "\$" "\\\$" "-" "\\\\-" ">" "\\\\>" "<" "\\\\<" } $txt ]
		return [ string map { "<" "&lt;" ">" "&gt;" "&" "&amp;" } $txt ]
		#return htmlentities $txt
	}

	proc userChangeState { event epvar } {
		#log "userChangeState called"
		#upvar 2 $epvar args
		#log "userChangeState lvl 1"
		#upvar 2 $args(user) user
		#log "userChangeState lvl 2"
		#upvar 2 $args(substate) substate
		#log "userChangeState lvl 3"
		upvar 2 user user
		#log "userChangeState lvl 1"
		upvar 2 substate substate
		#log "userChangeState lvl 2"
		#upvar 2 oldsubstate oldsubstate
		#log "userChangeState lvl 2.1 old substate: $oldsubstate"

		# Ignore user if blocked and we don't want blocked notifs
		log "Checking if $user is blocked"
		if {[::config::getKey no_blocked_notif 0] == 1 && [::MSN::userIsBlocked $user]} {
			log "User $user is blocked !"
			return
		}

		# yeah, getting old state !
		# Should be FLN for disconnected
		set oldstate [::abook::getVolatileData $user state]
		#log "Old status is : $oldstate"

		set email $user
		set username [::abook::getNick $email]

		set state [::MSN::stateToDescription $substate]
		set state [ trans $state ]
		#log "userChangeState email: $email, username: $username, state: $state ($substate)"
		
		switch -- $substate {
			"FLN" {
				if { [::config::getKey notifyoffline] == 0 } {
					log "Preferences says that disconnections should not make an event"
					return
				}
				log "Ok, preferences says that disconnections can be displayed [::config::getKey display_event_disconnect]"
				set txt "[trans disconnect $username]"
			}
			default {
				if { $oldstate == "FLN" } {
					if { [::config::getKey notifyonline] == 0 } {
						log "Preferences says that connections should not make an event"
						return
					}
					set txt "$username [trans logsin]"
				} else {
					if { [::config::getKey notifystate] == 0 } {
						log "Preferences says that states changes should not make an event"
						return
					}
					set txt "[trans changestate $username $state]"
				}
			}
		}
		#log "going to exec"
		exec_notify "$txt" "$email"
	}

	# UNUSED
	#proc userConnected { event epvar } {
	#	log "userConnected called"
	#	#upvar 2 $epvar args
	#	upvar 2 user user
	#	log "userConnected lvl 1"
	#	#upvar 2 $args(user) user
	#	upvar 2 user_name user_name
	#	log "userConnected lvl 2"
	#	#upvar 2 $args(user_name) user_name
	#	#log "userConnected lvl 3"
#
	#	set email $user
	#	set username [::abook::getNick $user_name]
	#	set username [lindex 1 $username]
	#	#exec_notify "$username [trans logsin]" "aMSN: $email" "$email"
	#	exec_notify "$username [trans logsin]" "$email"
	#}
}


