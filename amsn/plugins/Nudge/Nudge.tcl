############################################
#        ::nudge => Nudges for aMSN        #
#  ======================================  #
# Nudges are a kind of notification		   #
# that was introduced in MSN 7             #
############################################

###########################
# All nudges related code #
###########################
namespace eval ::Nudge {

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
		::amsn::notifyAdd "Nudge\n[trans nudge $nickname]." "::amsn::chatUser $email" "" offline
	}


	###############################################
	# ::Nudge::shake window n                     #
	# ------------------------------------------- #
	# The window $window will 'shake' $n times.   #
	###############################################
	proc shake { window n } {
		set x [winfo x $window]
		set y [winfo y $window]
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
}