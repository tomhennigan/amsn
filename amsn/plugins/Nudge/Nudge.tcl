############################################
#        ::nudge => Nudges for aMSN        #
#  ======================================  #
# Nudge is  a kind of notification		   #
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
        	::plugins::RegisterEvent Nudge PacketReceived received
	        ::plugins::RegisterEvent Nudge chatwindowbutton sendbutton
        	::plugins::RegisterEvent Nudge chatmenu itemmenu
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
		
			#If the user choosed to have a notify window
			if { $::Nudge::config(notify) == 1 } {
				#Get a shorter nick-name for the notify window
				set maxw [expr {[::config::getKey notifwidth]-20}]
				set nickname [trunc $nick . $maxw splainf]
				::Nudge::notify $nickname $chatid
			}
			#If the user choosed to make the window shake
			if { $::Nudge::config(shake) == 1 } {
				#Get the name of the window from the people who sent the nudge
				set lowuser [string tolower $chatid]
				set win_name [::ChatWindow::For $lowuser]
				#Shake that window
				::Nudge::shake ${win_name} $::Nudge::config(shakes)
			}
		
		}
	
	}

	###############################################
	# ::Nudge::notify nickname email              #
	# ------------------------------------------- #
	# Pops-up a notification telling that         #
	# $email(sender) has sent you a nudge         #
	#                                             #
	###############################################
	proc notify { nickname email } {
		::amsn::notifyAdd "Nudge\n[trans nudge $nickname]." "::amsn::chatUser $email" "" plugins
	}


	###############################################
	# ::Nudge::shake window n                     #
	# ------------------------------------------- #
	# The window $window will 'shake' $n times.   #
	###############################################
	proc shake { window n } {
		set geometry [wm geometry $window]
		set index11 [string first "+" $geometry]
		set index12 [string first "-" $geometry]
		if {[expr $index11 > $index12 && $index12 != -1] || $index11 == -1} {set index1 $index12} {set index1 $index11}
		set index21 [string first "+" $geometry [expr $index1 + 1]]
		set index22 [string first "-" $geometry [expr $index1 + 1]]
		if {$index21 == -1} {set index2 $index22} {set index2 $index21}
		#set index2 [string last "+" $geometry]
		set x [string range $geometry [expr $index1 + 1] [expr $index2 -1]]
		set y [string range $geometry [expr $index2 + 1] end]
		for {set i 0} {$i < $n} {incr i} {
			wm geometry $window +[expr $x + 10]+[expr $y + 8]
			update
			after 100
			wm geometry $window +[expr $x + 15 ]+[expr $y + 1]
			update
			after 100
			wm geometry $window +$x+$y
			update
			after 100
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
		upvar 2 evpar newvar
		upvar 2 bottom bottom
		#Create the button with an actual Pixmal
		button $bottom.buttons.nudge -image [::skin::loadPixmap bell] -relief flat -padx 3 \
		-background [::skin::getColor background2] -highlightthickness 0 -borderwidth 0
		#Define baloon info
		set_balloon $bottom.buttons.nudge "Send Nudge"
		#Pack the button in the right area
		pack $bottom.buttons.nudge -side right
		#Call ::Nudge::sendprocedure when we click on the button
		bind  $bottom.buttons.nudge  <Button1-ButtonRelease> "::Nudge::sendprocedure $newvar(window_name)"
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
		#Add label in the menu (no translation yet)
		$newvar(menu_name).actions add command -label "Send Nudge" \
		-command "::Nudge::sendprocedure $newvar(window_name)"

	}
	
	################################################
	# ::Nudge::sendprocedure window_name           #
	# -------------------------------------------  #
	# Protocole code to send a nudge to someone    #
	# via the button or the menu Actions           #		
	################################################
	proc sendprocedure {window_name} {
		#Find the SB
		set chatid [::ChatWindow::Name $window_name]
		set sbn [::MSN::SBFor $chatid]
		#Write the packet
		set msg "MIME-Version: 1.0\r\nContent-Type: text/x-msnmsgr-datacast\r\n\r\nID: 1\r\n\r\n\r\n"
    	set msg_len [string length $msg]
    	#Send the packet
    	::MSN::WriteSBNoNL $sbn "MSG" "U $msg_len\r\n$msg"
	}
	

	
	
}
