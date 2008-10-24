############################################
#        ::Nudge => Nudges for aMSN        #
#  ======================================  #
# Nudge is  a kind of notification         #
# that was introduced in MSN 7             #
############################################

###########################
# All nudges related code #
###########################
namespace eval ::Nudge {
	###############################################
	# ::Nudge::Init (dir)                         #
	# ------------------------------------------- #
	# Registration & initialization of the plugin #
	###############################################
	proc Init { dir } {
		::plugins::RegisterPlugin Nudge

		#Register the events to the plugin system
		::Nudge::RegisterEvent

		#Save in a config key where is the Nudge plugin
		::config::setKey nudgepluginpath $dir

		#Get default value for config
		::Nudge::config_array

		#Loads language files
		::Nudge::load_nudge_languages $dir

		#Config to show in configuration window	
		::Nudge::configlist_values

		#Load the pictures
		::Nudge::setPixmap

		#Wait 5 seconds after all the plugins are loaded to register
		#the command /nudge to amsnplus plugin
		
		after 5000 "catch {::Nudge::add_command 0 0}"
		
	}
	
	#####################################
	# ::Nudge::RegisterEvent            #
	# --------------------------------- #
	# Register events to plugin system  #
	#####################################
	proc RegisterEvent {} {
		::plugins::RegisterEvent Nudge DataCastPacketReceived received
		::plugins::RegisterEvent Nudge PacketReceived received
		::plugins::RegisterEvent Nudge chatwindowbutton sendbutton
		::plugins::RegisterEvent Nudge chatmenu itemmenu
		::plugins::RegisterEvent Nudge right_menu clitemmenu
		::plugins::RegisterEvent Nudge AllPluginsLoaded add_command
		::plugins::RegisterEvent Nudge chatwindowbutton blockbutton
	}
	
	########################################
	# ::Nudge::config_array                #
	# -------------------------------------#
	# Add config array with default values #
	########################################
	proc config_array {} {
		array set ::Nudge::config {
			notify {1}
			notsentinwin {1}
			notrecdinwin {1}
			soundnotsend {1}
			soundnotrec {1}
			shake {0}
			shakes {10}
			shaketoo {0}
			addbutton {1}
			addblockbutton {0}
			addclmenuitem {0}
			limit {1}
			delay {60}
		}
	}
	
	########################################
	# ::Nudge::configlist_values           #
	# -------------------------------------#
	# List of items for config window      #
	########################################
	proc configlist_values {} {
		set ::Nudge::configlist [list \
			[list bool "$::Nudge::language(shake_receive)" shake] \
			[list bool "$::Nudge::language(shake_send)" shaketoo] \
			[list str "\t$::Nudge::language(shake_nudge):" shakes] \
			[list bool "$::Nudge::language(popup_nudge)" notify] \
			[list bool "$::Nudge::language(notify_send)" notsentinwin] \
			[list bool "$::Nudge::language(notify_receive)" notrecdinwin] \
			[list bool "$::Nudge::language(sound_send)" soundnotsend] \
			[list bool "$::Nudge::language(sound_receive)" soundnotrec] \
			[list bool "$::Nudge::language(add_button)" addbutton] \
			[list bool "$::Nudge::language(add_blockbutton)" addblockbutton] \
			[list bool "$::Nudge::language(add_clmenuitem)" addclmenuitem] \
			[list bool "$::Nudge::language(limit)" limit] \
			[list str "\t$::Nudge::language(delay):" delay] \
		]
	}
	########################################
	# ::Nudge::load_nudge_languages dir    #
	# -------------------------------------#
	# Load languages files                 #
	# Compatible with aMSN >0.94           #
	########################################
	proc load_nudge_languages {dir} {
		#Verify if aMSN version is 0.94 or better
		if { [::Nudge::version_094] } {
			#If 0.94, use only english keys because 0.94 is not compatible with langfiles in plugins
			::Nudge::language_array_094
		} else {
			#Load lang files
			set langdir [file join $dir "lang"]
			set lang [::config::getGlobalKey language]
			load_lang en $langdir
			load_lang $lang $langdir
			#Create array ::Nudge::language
			::Nudge::language_array
		}
	}
	########################################
	# ::Nudge::language_array_094          #
	# -------------------------------------#
	# Load default english keys in array   #
	# For aMSN 0.94 only                   #
	########################################	
	proc language_array_094 {} {
		array set ::Nudge::language [list shake_receive "Shake the window when receiving a nudge" \
			shake_send "Shake the window when sending a nudge" \
			shake_nudge "Shakes per nudge" \
			popup_nudge "Notify nudges with popup-window" \
			notify_send "Notify sent nudges in the chatwindow" \
			notify_receive "Notify received nudges in the chatwindow" \
			sound_send "Play a sound upon sending a nudge" \
			sound_receive "Play a sound upon receiving a nudge." \
			add_button "Add a button to send a nudge in the chatwindow" \
			add_blockbutton "Add a button to block incoming nudges in the chatwindow" \
			add_clmenuitem "Add an item to the contactlist popup-menu" \
			send_nudge "Send nudge" \
			no_nudge_support "You cannot sent a nudge to your contact because he or she doesn't use a client that supports nudges" \
			nudge_sent "You have just sent a Nudge" \
			limit "Activate Nudge receive limitation" \
			delay "Minimum time between 2 nudge from the same contact (in seconds)" \
			block_nudge "Block/Unblock Nudges" \
			no_nudge_support "You cannot sent a nudge to your contact because he or she doesn't use a client that supports nudges" \
			nudge_sent "You have just sent a Nudge" \
		]
	}
	
	########################################
	# ::Nudge::language_array              #
	# -------------------------------------#
	# Create ::Nudge::language array       #
	# Compatible with lang files           #
	########################################
	proc language_array {} {
		array set ::Nudge::language [list shake_receive "[trans shake_receive]" \
			shake_send "[trans shake_send]" shake_nudge "[trans shake_nudge]" \
			popup_nudge "[trans popup_nudge]" notify_send "[trans notify_send]" \
			notify_receive "[trans notify_receive]" sound_send "[trans sound_send]" \
			sound_receive "[trans sound_receive]" add_button "[trans add_button]" \
			add_blockbutton "[trans add_blockbutton]" \
			add_clmenuitem "[trans add_clmenuitem]" send_nudge "[trans send_nudge]" \
			no_nudge_support "[trans no_nudge_support]" nudge_sent "[trans nudge_sent]" \
			limit "[trans limit]" delay "[trans delay]" block_nudge "[trans block_nudge]" \
		]
	}
	
	###############################################
	# ::Nudge::received event evpar               #
	# ------------------------------------------- #
	# Is the event handler. Simply checks our     #
	# config and do what it says.                 #
	###############################################
	proc received { event evpar } {
		upvar 2 $evpar args
		upvar 2 $args(chatid) chatid
		upvar 2 $args(nick) nick
		upvar 2 $args(msg) msg
		set timestamp [clock seconds]
		set lastnudge [::abook::getVolatileData $chatid last_nudge]
		set auth [::abook::getContactData $chatid auth_nudge]	
		
		if {$auth == ""} {
			set auth 1
		}
		if {$lastnudge == ""} {
			set lastnudge 0
		}
		
		set lastnudge [expr $timestamp-$lastnudge]

		#The way to get headers change on 0.95
		if {[::Nudge::version_094]} {
			set header "[::MSN::GetHeaderValue $msg Content-Type]"
			set ID "[::MSN::GetHeaderValue $msg ID]"
		} else {
			set header "[$msg getHeader Content-Type]"
			set ID "[$msg getField ID]"
		}
		
		#If the user choosed to desactivate nudge receive limitation
		if {$::Nudge::config(limit) == 0} {
			set lastnudge [expr $lastnudge+$::Nudge::config(delay)]
			set auth 1
		}

		if {$header == "text/x-msnmsgr-datacast" && $ID == "1" && $lastnudge > $::Nudge::config(delay) && $auth=="1"} {
			::Nudge::log "Start receiving nudge from <[::abook::getDisplayNick $chatid]>"
			#If the user choosed to have the nudge notified in the window
			if { $::Nudge::config(notsentinwin) == 1 } {
				::ChatWindow::MakeFor $chatid
				::Nudge::winwrite $chatid "[trans nudge $nick]!" nudge
			}
			
			#If the user choosed to have a sound-notify
			if { $::Nudge::config(soundnotrec) == 1 } {
				::Nudge::sound
			}
			
			#If the user choosed to have a notify window
			if { $::Nudge::config(notify) == 1 } {
				::Nudge::notify $nick $chatid
			}
			
			#If the user choosed to make the window shake
			if { $::Nudge::config(shake) == 1 } {
				#Get the name of the window from the people who sent the nudge
				set lowuser [string tolower $chatid]
				set win_name [::ChatWindow::For $lowuser]
				#Shake that window
				::Nudge::shake ${win_name} $::Nudge::config(shakes)
			}
			
			#If Growl plugin is loaded, show the notification, Mac OS X only
			if { [info commands ::growl::InitPlugin] != "" } {
				catch {growl post Nudge Nudge [trans nudge $nick] [::growl::getpicture $chatid]}
				::Nudge::log "Show growl notification"
			}
			
			::abook::setVolatileData $chatid last_nudge $timestamp
			::Nudge::log "Receiving nudge from <[::abook::getDisplayNick $chatid]> is finished"		
		
		}
	
	}

	###############################################
	# ::Nudge::notify nickname email              #
	# ------------------------------------------- #
	# Pops-up a notification telling that         #
	# someone has sent you a nudge                #
	###############################################
	proc notify { nick email } {
		#Get a shorter nick-name for the notify window
		set maxw [expr {[::skin::getKey notifwidth]-20}]
		set nickname [trunc $nick . $maxw splainf]
		#Show the notification
		::amsn::notifyAdd [trans nudge $nickname] "::amsn::chatUser $email" "" plugins
		::Nudge::log "Notify window created"
	}


	###############################################
	# ::Nudge::shake window n                     #
	# ------------------------------------------- #
	# The window $window will 'shake' $n times.   #
	###############################################
	proc shake { window n } {
		
		#Tab support on 0.95
		if {![::Nudge::version_094]} {
			if {[::ChatWindow::GetContainerFromWindow $window] != ""} {
				set window [::ChatWindow::GetContainerFromWindow $window]
			}
		}
		
		#If a strange user decide to use a letter, nothing, or 0, as a number of shake
		#Rechange the variable to 10 shakes
		if {![string is digit -strict $n]} {
			set n "10"
			set ::Nudge::config(shakes) 10
		}
		#Avoid a bug if the user close the chat window just after pressing the button
		if {[catch {set geometry [wm geometry $window]}]} {
			return
		}
		set index11 [string first "+" $geometry]
		set index12 [string first "-" $geometry]
		if {[expr $index11 > $index12 && $index12 != -1] || $index11 == -1} {set index1 $index12} {set index1 $index11}
		set index21 [string first "+" $geometry [expr $index1 + 1]]
		set index22 [string first "-" $geometry [expr $index1 + 1]]
		if {$index21 == -1} {set index2 $index22} {set index2 $index21}
		#set index2 [string last "+" $geometry]
		
		#Make the window shake until we have reached the number of times to shake
		#I added catch to avoid bug if we close the chatwindow before the end of the nudge
		#If catch is not called in the loop before functions dealing with the window then if
		#the window is closed while the window is still vibrating an error will be produced 
		for {set i 0} {$i < $n && [winfo exists $window] } {incr i} {
			catch {set geometry [wm geometry $window]}
			set x [string range $geometry [expr $index1 + 1] [expr $index2 -1]]
			set y [string range $geometry [expr $index2 + 1] end]
			catch {wm geometry $window +[expr $x+10]+[expr $y +8]}
			update
			after 10
			catch {set geometry [wm geometry $window]}
			set x [string range $geometry [expr $index1 + 1] [expr $index2 -1]]
			set y [string range $geometry [expr $index2 + 1] end]
			catch {wm geometry $window +[expr $x +5 ]+[expr $y-7]}
			update
			after 10
			catch {set geometry [wm geometry $window]}
			set x [string range $geometry [expr $index1 + 1] [expr $index2 -1]]
			set y [string range $geometry [expr $index2 + 1] end]
			catch {wm geometry $window +[expr $x -15]+[expr $y -1]}
			update
			after 10 
		}
		::Nudge::log "Window shook $n times"
	}

	################################################
	# ::Nudge::sendbutton event epvar              #
	# -------------------------------------------  #
	# Button to add in the chat window             #
	# When we click on that button, we send a nudge#
	# to the other contact                         #
	################################################	
	proc sendbutton { event evpar } {
		if { $::Nudge::config(addbutton) == 1 } {
			upvar 2 $evpar newvar
			set nudgebutton $newvar(bottom).nudge
			#Create the button with an actual Pixmal
			#Use after 1 to avoid a bug on Mac OS X when we close the chatwindow before the end of the nudge
			#Keep compatibility with 0.94 for the getColor
			if {[::Nudge::version_094]} {
				label $nudgebutton -image [::skin::loadPixmap nudgebutton] -relief flat -padx 0 \
				-background [::skin::getColor background2] -highlightthickness 0 -borderwidth 0 \
				-highlightbackground [::skin::getColor background2] -activebackground [::skin::getColor background2]\
			} else {
				button $nudgebutton -image [::skin::loadPixmap nudgebutton] -relief flat -padx 0 \
				-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
				-command "after 1 ::Nudge::send_via_queue $newvar(window_name)" \
				-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]\
			}
			if {[::Nudge::version_094]} {
				bind $nudgebutton <<Button1>> "after 1 ::Nudge::send_via_queue $newvar(window_name)"
			}
			#Configure hover button
			bind $nudgebutton <Enter> "$nudgebutton configure -image [::skin::loadPixmap nudgebutton_hover]"
			bind $nudgebutton <Leave> "$nudgebutton configure -image [::skin::loadPixmap nudgebutton]"
			#Define baloon info
			set_balloon $nudgebutton "$::Nudge::language(send_nudge)"
		
			#Pack the button in the right area
			pack $nudgebutton -side right
			::Nudge::log "Nudge button added the new window: $newvar(window_name)"
		}
	}
	
	################################################
	# ::Nudge::itemmenu event epvar                #
	# -------------------------------------------  #
	# "Send nudge" item, in the menu Actions       #
	# If you click on that menu item, you will send#
	# a nudge to the other contact                 #
	################################################	
	proc itemmenu { event evpar } {
		upvar 2 $evpar newvar
		#Add a separator to the menu
#		$newvar(menu_name).actions add separator
		#Add label in the menu
		$newvar(menu_name).actions add command -label "$::Nudge::language(send_nudge)" \
		-command "::Nudge::send_via_queue \[::ChatWindow::getCurrentTab $newvar(window_name)\]"
		::Nudge::log "Item Send Nudge added to actions menu of window $newvar(window_name)"
	}
	
	################################################
	# ::Nudge::add_command                         #
	# -------------------------------------------  #
	# Add irc command /nudge for amsnplus users    #
	# Need last update of aMSNPlus plugin +/- 2.3  #
	# Verify first if amsnplus plugin is loaded    #
	################################################
	proc add_command {event evpar} {
	
		#If amsnplus plugin is loaded, register the command
		if { [info commands ::amsnplus::add_command] != "" } {
			#Avoid a bug if someone use an older version of aMSNPlus
			catch {::amsnplus::add_command nudge ::Nudge::SendNudge 0 1}
			::Nudge::log "Register command nudge to amsnplus plugin"
		}
	}
	
	################################################
	# ::Nudge::clitemmenu event epvar      	       #
	# -------------------------------------------  #
	# "Send nudge" item, in the rightclick-menu in #
	# in the contact-list.                         #
	# If you click on that menu item, you will send#
	# a nudge to the other contact.                #
	################################################	
	proc clitemmenu { event evpar } {
		upvar 2 $evpar newvar

		if { $::Nudge::config(addclmenuitem) == 1 } {
			#Add separator and label in the menu
			if { [winfo exists ${newvar(menu_name)}.actions] } {
				${newvar(menu_name)}.actions add separator
				${newvar(menu_name)}.actions add command -label "$::Nudge::language(send_nudge)" \
				-command "::Nudge::ClSendNudge $newvar(user_login)"
			} else {
				

				$newvar(menu_name) insert [trans viewprofile] command -label "$::Nudge::language(send_nudge)" \
				-command "::Nudge::ClSendNudge $newvar(user_login)"
			}
			::Nudge::log "Create Send Nudge item in right click menu"
		}
	}

	################################################  
	# ::Nudge::ClSendNudge username                # 
	# -------------------------------------------  # 
	# Open the chatwindow to $username and send    # 
	# this contact a Nudge                         # 
	################################################
	proc ClSendNudge { username } {

		set lowuser [string tolower $username]
		set win_name [::ChatWindow::For $lowuser]	
		#Determine if a window with that user already exist (0=no window)
		if { $win_name == 0 } {
			::Nudge::log "We don't have any window with <[::abook::getDisplayNick $lowuser]> yet(via right-click menu)"
			#Start the conversation
			::amsn::chatUser $username
			#Now that we have a window, find the name of this new window
			set win_name [::ChatWindow::For $lowuser]
			#Send the nudge via the ChatQueue (to wait that connection is etablished before sending)
			::Nudge::send_via_queue $win_name
		} else {
			::Nudge::log "We already have a window with <[::abook::getDisplayNick $lowuser]> (via right click menu)"
			#If the window with the contact was already open
			#Send the nudge via the ChatQueue to reactive the conversation if it was closed
			::Nudge::send_via_queue $win_name
		}

		
	}
	
		
	############################################
	# ::Nudge::send_via_queue window_name      #
	# -----------------------------------------#
	# Send the Nudge via the ChatQueue         #
	# So, aMSN reconnect on user to send the   #
	# Nudge if the conversation was closed     #
	############################################
	proc send_via_queue {window_name} {
		set chatid [::ChatWindow::Name $window_name]
		::MSN::ChatQueue $chatid [list ::Nudge::SendNudge $window_name]
	}

	################################################
	# ::Nudge::SendNudge window_name               #
	# -------------------------------------------  #
	# Protocole code to send a nudge to someone    #
	# via the button or the menu Actions           #
	################################################
	proc SendNudge {window_name} {
	
		#Find the SB
		set chatid [::ChatWindow::Name $window_name]
		::Nudge::log "\nStart sending Nudge to <[::abook::getDisplayNick $chatid]>\n"
		#Check if the user can accept the nudge (MSN 7 protocol needed), if not, stop here.
		set theysupport 0

		set users [::MSN::usersInChat $chatid]
	
		foreach chatid2 $users {
			if {[::Nudge::check_clientid $chatid2]} {
				#This is what the official client does...
				#sends nudge to a multi-convo even when
				#not everyone supports it
				set theysupport 1
				break
			}
		}

		if { $theysupport == 0 } {
				::Nudge::winwrite $chatid \
				"$::Nudge::language(no_nudge_support)" nudgeoff red
				::Nudge::log "Can't send a Nudge to <[::abook::getDisplayNick $chatid]> because he doesn't use MSN 7 protocol"
				return
			}
	
		
		#If the user choosed to have the nudge notified in the window
		if { $::Nudge::config(notrecdinwin) == 1 } {
			::Nudge::winwrite $chatid "$::Nudge::language(nudge_sent)!" nudge
		}
		
		#If the user choosed to have a sound-notify
		if { $::Nudge::config(soundnotsend) == 1 } {
			::Nudge::sound
		}
		
		#Shake the window on sending if the user choosed it
		if { $::Nudge::config(shaketoo) == 1 } {
			::Nudge::shake $window_name $::Nudge::config(shakes)
		}
		
		#Send the packet of the nudge
		::Nudge::SendPacket $chatid
	}
	
	################################################
	# ::Nudge::SendPacket chatid                   #
	# -------------------------------------------  #
	# Protocole code to send a nudge to someone    #
	# via the button or the menu Actions           #		
	################################################
	proc SendPacket {chatid} {
		set sbn [::MSN::SBFor $chatid]
		
		#Write the packet
		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msnmsgr-datacast\r\n\r\nID: 1\r\n\r\n\r\n"
		set msg_len [string length $msg]

		#Send the packet
		::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"
		::Nudge::log "Nudge packet sent"
		::Nudge::log "Finished sending Nudge to <[::abook::getDisplayNick $chatid]>"
	}
	
	######################################################
	# ::Nudge::winwrite chatid text iconname (color)     #
	# ---------------------------------------------------#
	# Use ::amsn::WinWrite to add text in a chat         #
	# window when we send/receive a nudge                #	
	# Add a seperation of "-" before and & after the text#	
	# 0.95 use the skinnable separation instead of "--"  # 
	######################################################
	proc winwrite {chatid text iconname {color "green"} } {
		#Look at the version of aMSN to know witch kind of separation we use
		if {[::Nudge::version_094]} {
			amsn::WinWrite $chatid "\n----------\n" $color 
			amsn::WinWriteIcon $chatid $iconname 3 2
			amsn::WinWrite $chatid "[timestamp] $text\n----------" $color
		} else {
			SendMessageFIFO [list ::Nudge::winwriteWrapped $chatid $text $iconname $color] "::amsn::messages_stack($chatid)" "::amsn::messages_flushing($chatid)"
		}
	}

	proc winwriteWrapped {chatid text iconname {color "green"} } {
		amsn::WinWrite $chatid "\n" $color
		amsn::WinWriteIcon $chatid greyline 3
		amsn::WinWrite $chatid " \n" $color
		amsn::WinWriteIcon $chatid $iconname 3 2
		amsn::WinWrite $chatid "[timestamp] $text\n" $color
		amsn::WinWriteIcon $chatid greyline 3
		::Nudge::log "Seperation and message wrote in chatwindow"
	}
	
	############################################
	# ::Nudge::check_clientid email            #
	# -----------------------------------------#
	# Verify in abook if the other contact use #
	# protocol MSN 7                           #
	# Boolean answer                           #
	############################################
	proc check_clientid {email} {
		::Nudge::log "Verify if contact is using MSN 7.0 protocol"

		set clientid [::abook::getContactData $email clientid]

		::Nudge::log "Clientid is $clientid"

		# If a user chats with you while being as "Appear offline", his client ID will be empty, and we don't want a crash in that case.
		# We assume the user supports new nudge because only WLM 8.1+ allows you to chat while being as appear offline.
		if { $clientid == [list] } {
			::Nudge::log "Attempt to nudge offline user"
			return 1
		}
		
		if { ($clientid & 0xF0000000) < 0x40000000 } {
			return 0
		} else {
			return 1
		}
	}
	
	############################################
	# ::Nudge::log message                     #
	# -----------------------------------------#
	# Add a log message to plugins-log window  #
	# Type Alt-P to get that window            #
	# Not compatible with 0.94                 #
	############################################
	proc log {message} {
		if {[::Nudge::version_094]} {
			return
		} else {
			plugins_log Nudge $message
		}
	}
		
	############################################
	# ::Nudge::sound                           #
	# -----------------------------------------#
	# Play sound message                       #
	# When we send and/or receive a nudge      #
	# Real sound from MSN 7                    #
	############################################
	proc sound {} {
		set dir [::config::getKey nudgepluginpath]
		play_sound $dir/nudge.wav 1
		::Nudge::log "Play sound for nudge, Directory: [::config::getKey nudgepluginpath]"
	}
	
	############################################
	# ::Nudge::version_094                     #
	# -----------------------------------------#
	# Verify if the version of aMSN is 0.94    #
	# Useful if we want to keep compatibility  #
	############################################
	proc version_094 {} {
		global version
		scan $version "%d.%d" y1 y2;
		if { $y2 == "94" } {
			return 1
		} else {
			return 0
		}
	}
	############################################
	# ::Nudge::setPixmap                       #
	# -----------------------------------------#
	# Define the nudge pixmaps from the skin   #
	############################################	
	proc setPixmap {} {
			::skin::setPixmap nudge nudge.gif
			::skin::setPixmap nudgeoff nudgeoff.gif
			::skin::setPixmap nudgebutton nudgebutton.gif
			::skin::setPixmap nudgebutton_hover nudgebutton_hover.gif
	}

	################################################
	# ::Nudge::blockbutton event epvar             #
	# -------------------------------------------  #
	# Button to add in the chat window             #
	# When we click on that button,we block/deblock#
	# Nudge ability for that contact               #
	################################################	
	proc blockbutton { event evpar } {
		if { $::Nudge::config(addblockbutton) == 1 } {
			upvar 2 $evpar newvar
			set nudgebutton $newvar(bottom).nudgeblock
			set chatid [::ChatWindow::Name $newvar(window_name)]
			if {[::abook::getContactData $chatid auth_nudge] == "0"} {
				set nudgeimg "nudgeoff"
			} else {
				set nudgeimg "nudge"
			}
			#Create the button with an actual Pixmap
			#Use after 1 to avoid a bug on Mac OS X when we close the chatwindow before the end of the nudge
			#Keep compatibility with 0.94 for the getColor
			if {[::Nudge::version_094]} {
				label $nudgebutton -image [::skin::loadPixmap $nudgeimg] -relief flat -padx 0 \
				-background [::skin::getColor background2] -highlightthickness 0 -borderwidth 0 \
				-highlightbackground [::skin::getColor background2] -activebackground [::skin::getColor background2]\
			} else {
				button $nudgebutton -image [::skin::loadPixmap $nudgeimg] -relief flat -padx 0 \
				-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
				-command  "after 1 ::Nudge::blocknudge $chatid $nudgebutton" \
				-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]\
			}
			if {[::Nudge::version_094]} {
				bind $nudgebutton <<Button1>> "after 1 ::Nudge::blocknudge $chatid $nudgebutton"
			}
			
			#Define baloon info
			set_balloon $nudgebutton "$::Nudge::language(block_nudge)"
		
			#Pack the button in the right area
			pack $nudgebutton -side right
			::Nudge::log "Nudge block button added the new window: $newvar(window_name)"
		}
	}

	##############################################
	# ::Nudge::blocknudge                        #
	# -------------------------------------------#
	# Set/Unset nudge authorization for a contact#
	# Change picture in the chat window according#
	# to the state.                              #
	##############################################
	proc blocknudge {chatid button} {
			if {[::abook::getContactData $chatid auth_nudge] == "1"} {
				::abook::setContactData $chatid auth_nudge 0
				$button configure -image [::skin::loadPixmap nudgeoff]
			} else {
				::abook::setContactData $chatid auth_nudge 1
				$button configure -image [::skin::loadPixmap nudge]
			}			
		}
}
