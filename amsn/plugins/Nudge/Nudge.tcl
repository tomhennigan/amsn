############################################
#        ::nudge => Nudges for aMSN        #
#  ======================================  #
# Nudge is  a kind of notification	   	   #
# that was introduced in MSN 7             #
# TODO: Use lang system for keys		   #
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
        	::plugins::RegisterEvent Nudge PacketReceived received
	        ::plugins::RegisterEvent Nudge chatwindowbutton sendbutton
        	::plugins::RegisterEvent Nudge chatmenu itemmenu
        	::plugins::RegisterEvent Nudge right_menu clitemmenu
        	
        	#Save in a config key where is the Nudge plugin
    		::config::setKey nudgepluginpath $dir
    	
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
        	}
	        set ::Nudge::configlist [list \
			[list bool "Shake the window when receiving a nudge." shake] \
      		    	[list bool "Shake the window when sending a nudge." shaketoo] \
                	[list str "\tShakes per nudge:" shakes] \
                	[list bool "Notify nudges with popup-window." notify] \
        	        [list bool "Notify sent nudges in the chatwindow." notsentinwin] \
        	        [list bool "Notify received nudges in the chatwindow." notrecdinwin] \
	                [list bool "Play a sound upon sending a nudge." soundnotrec] \
	                [list bool "Play a sound upon receiving a nudge." soundnotsend] \
					[list bool "Add a button to send a nudge in the chatwindows." addbutton] \
        	]
	}


	###############################################
	# ::Nudge::received event evpar               #
	# ------------------------------------------- #
	# Is the event handler. Simply checks our     #
	# config and do what it says.                 #
	###############################################
	proc received { event evpar } {
		upvar 2 evpar args
		upvar 2 chatid chatid
		upvar 2 nick nick
		upvar 2 msg msg

		if {[::MSN::GetHeaderValue $msg Content-Type] == "text/x-msnmsgr-datacast" && [::MSN::GetHeaderValue $msg ID] == "1"} {
		
			#If the user choosed to have the nudge notified in the window
			if { $::Nudge::config(notsentinwin) == 1 } {
				::Nudge::winwrite $chatid "[trans nudge $nick]!" bell
			}
			
			#Todo: use the original shake sound of MSN 7
			#If the user choosed to have a sound-notify
			if { $::Nudge::config(soundnotrec) == 1 } {
				set dir [::config::getKey nudgepluginpath]
				play_sound $dir/nudge.wav 1
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
			set pluginidx [lindex [lsearch -all $::plugins::found "*growl*"] 0]
			if { $pluginidx != "" } {
				catch {growl post Nudge Nudge [trans nudge $nick]}
			}
					
		
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
		set maxw [expr {[::config::getKey notifwidth]-20}]
		set nickname [trunc $nick . $maxw splainf]
		#Show the notification
		::amsn::notifyAdd "Nudge\n[trans nudge $nickname]." "::amsn::chatUser $email" "" plugins
	}


	###############################################
	# ::Nudge::shake window n                     #
	# ------------------------------------------- #
	# The window $window will 'shake' $n times.   #
	###############################################
	proc shake { window n } {
		
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
		set x [string range $geometry [expr $index1 + 1] [expr $index2 -1]]
		set y [string range $geometry [expr $index2 + 1] end]
		
		#Make the window shake until we have reached the number of times to shake
		#I added catch to avoid bug if we close the chatwindow before the end of the nudge
		for {set i 0} {$i < $n && [winfo exists $window] } {incr i} {
			
			catch {wm geometry $window +[expr $x + 10]+[expr $y + 8]}
			update
			after 10
			catch {wm geometry $window +[expr $x + 15 ]+[expr $y + 1]}
			update
			after 10
			catch {wm geometry $window +$x+$y}
			update
			after 10

			
		}
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
			upvar 2 evpar newvar
			upvar 2 bottom bottom
			global version
			
			#Create the button with an actual Pixmal
			#Use after 1 to avoid a bug on Mac OS X when we close the chatwindow before the end of the nudge
			#Keep compatibility with 0.94 for the getColor
			scan $version "%d.%d" y1 y2;
			if { $y2 == "94" } {
				button $bottom.buttons.nudge -image [::skin::loadPixmap bell] -relief flat -padx 3 \
				-background [::skin::getColor background2] -highlightthickness 0 -borderwidth 0 \
				-highlightbackground [::skin::getColor background2] \
				-command "after 1 ::Nudge::send_via_queue $newvar(window_name)"
			} else {
				button $bottom.buttons.nudge -image [::skin::loadPixmap bell] -relief flat -padx 3 \
				-background [::skin::getColor buttonbarbg] -highlightthickness 0 -borderwidth 0 \
				-highlightbackground [::skin::getColor buttonbarbg] \
				-command "after 1 ::Nudge::send_via_queue $newvar(window_name)"
			}
			
			#Define baloon info
			set_balloon $bottom.buttons.nudge "Send Nudge"
		
			#Pack the button in the right area
			pack $bottom.buttons.nudge -side right
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
		upvar 2 evPar newvar
		#Add a separator to the menu
		$newvar(menu_name).actions add separator
		#Add label in the menu
		$newvar(menu_name).actions add command -label "Send Nudge" \
		-command "::Nudge::send_via_queue $newvar(window_name)"
	}
	
	################################################
	# ::Nudge::clitemmenu event epvar      	       #
	# -------------------------------------------  #
	# "Send nudge" item, in the rightclick-menu in #
	# in the contact-list.			   			   #
	# If you click on that menu item, you will send#
	# a nudge to the other contact.                #
	################################################	
	proc clitemmenu { event evpar } {
		upvar 2 evPar newvar
		#Add a separator to the menu
		$newvar(menu_name) add separator
		
		#Add label in the menu
		$newvar(menu_name) add command -label "Send Nudge" \
		-command "::Nudge::ClSendNudge $newvar(user_login)"
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
			#Start the conversation
			::amsn::chatUser $username
			#Now that we have a window, find the name of this new window
			set win_name [::ChatWindow::For $lowuser]
			#Send the nudge via the ChatQueue (to wait that connection is etablished before sending)
			::Nudge::send_via_queue $win_name
		} else {
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
		#Check if the user can accept the nudge (MSN 7 protocol needed), if not, stop here.
			if {![::Nudge::check_clientid $chatid]} {
				::Nudge::winwrite $chatid \
				"You cannot sent a Nudge to your contact because he or she doesn't use a client that supports Nudges." belloff red
				return
			}
	
		
		#If the user choosed to have the nudge notified in the window
		if { $::Nudge::config(notrecdinwin) == 1 } {
			::Nudge::winwrite $chatid "You have just sent a Nudge!" bell
		}
		
		#If the user choosed to have a sound-notify
		#Todo: have the same sound as MSN 7
		if { $::Nudge::config(soundnotrec) == 1 } {
				set dir [::config::getKey nudgepluginpath]
				play_sound $dir/nudge.wav 1
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
	}
	
	######################################################
	# ::Nudge::winwrite chatid text iconname             #
	# ---------------------------------------------------#
	# Use ::amsn::WinWrite to add text in a chat         #
	# window when we send/receive a nudge                #	
	# Add a seperation of "-" before and & after the text#	
	# 0.95 use the skinnable separation instead of "--"  # 
	######################################################
	proc winwrite {chatid text iconname {color "green"} } {
		#Look at the version of aMSN to know witch kind of separation we use
		scan $version "%d.%d" y1 y2;
		if { $y2 == "94" } {
			amsn::WinWrite $chatid "\n----------\n" $color 
			amsn::WinWriteIcon $chatid $iconname 3 2
			amsn::WinWrite $chatid "[timestamp] $text\n----------" $color
		} else {
			amsn::WinWrite $chatid "\n" $color
			amsn::WinWriteIcon $chatid greyline 3
			amsn::WinWrite $chatid "\n" $color
			amsn::WinWriteIcon $chatid $iconname 3 2
			amsn::WinWrite $chatid "[timestamp] $text\n" $color
			amsn::WinWriteIcon $chatid greyline 3
		}
	}
	
	############################################
	# ::Nudge::check_clientid email            #
	# -----------------------------------------#
	# Verify in abook if the other contact use #
	# protocol MSN 7                           #
	# Boolean answer                           #
	############################################
	proc check_clientid {email} {
		if {[::abook::getContactData $email clientid] == "MSN 7.0" } {
			return 1
		} else {
			return 0
		}
	}

}
