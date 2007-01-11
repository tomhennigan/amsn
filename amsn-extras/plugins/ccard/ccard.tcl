##################################################
#  This plugin implements the "contact-cards"    #
#  as seen in MSN7                               #
#  (c) Karel Demeyer, 2005                       #
#   Thanks to  the aMSN developpers for all the  #
#   code I copied ;)                             #
#  ============================================  #
##################################################

#TODO:
#  * add more info as an option ?
#  * right-click on dp for "save as.." etc
#  * MSN Spaces support



############################
# ::ccard                  #
#  All ccard related code  #
############################
namespace eval ::ccard {


	variable dset 0
	variable bgcolor #ebf1fa

	################################################
	# Init( dir )                                  #
	#  Registration & initialization of the plugin #
	################################################
	proc Init { dir } {

		::plugins::RegisterPlugin "Contact Cards"

		#Register the events to the plugin system
		::ccard::RegisterEvents


		#This if is to have backwards-compatibility with aMSN 0.94.  Thanks to Arieh for pointing this out.
		if {[string equal $::version "0.94"]} {
			::skin::setPixmap ccard_bg [file join $dir pixmaps ccard_bg.gif]
			::skin::setPixmap ccard_close [file join $dir pixmaps ccard_close.gif]
			::skin::setPixmap ccard_close_hover [file join $dir pixmaps ccard_close_hover.gif]
			::skin::setPixmap ccard_left [file join $dir pixmaps ccard_left.gif]
			::skin::setPixmap ccard_left_hover [file join $dir pixmaps ccard_left_hover.gif]
			::skin::setPixmap ccard_right [file join $dir pixmaps ccard_right.gif]
			::skin::setPixmap ccard_right_hover [file join $dir pixmaps ccard_right_hover.gif]
			::skin::setPixmap ccard_back_line [file join $dir pixmaps ccard_line.gif]
			::skin::setPixmap ccard_chat [file join $dir pixmaps ccard_chat.gif]
			::skin::setPixmap ccard_chat_hover [file join $dir pixmaps ccard_chat_hover.gif]
			::skin::setPixmap ccard_email [file join $dir pixmaps ccard_email.gif]
			::skin::setPixmap ccard_email_hover [file join $dir pixmaps ccard_email_hover.gif]
			::skin::setPixmap ccard_nudge [file join $dir pixmaps ccard_nudge.gif]
			::skin::setPixmap ccard_nudge_hover [file join $dir pixmaps ccard_nudge_hover.gif]
			::skin::setPixmap ccard_mobile [file join $dir pixmaps ccard_mobile.gif]
			::skin::setPixmap ccard_mobile_hover [file join $dir pixmaps ccard_mobile_hover.gif]
			::skin::setPixmap ccard_bpborder [file join $dir pixmaps ccard_bpborder.gif]
		} else {
			::skin::setPixmap ccard_bg ccard_bg.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_close ccard_close.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_close_hover ccard_close_hover.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_left ccard_left.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_left_hover ccard_left_hover.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_right ccard_right.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_right_hover ccard_right_hover.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_back_line ccard_line.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_chat ccard_chat.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_chat_hover ccard_chat_hover.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_email ccard_email.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_email_hover ccard_email_hover.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_nudge ccard_nudge.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_nudge_hover ccard_nudge_hover.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_mobile ccard_mobile.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_mobile_hover ccard_mobile_hover.gif pixmaps [file join $dir pixmaps]
			::skin::setPixmap ccard_bpborder ccard_bpborder.gif pixmaps [file join $dir pixmaps]
		}

		

	}





	#####################################
	# RegisterEvents                    #
	#  Register events to plugin system #
	#####################################
	proc RegisterEvents {} {
		::plugins::RegisterEvent "Contact Cards" right_menu clmenu

	}



	##################################################
	# clmenu( event epvar )                          #
	#  This puts an entry in the rightclick-menu of  #
	#  the contactlist. When you click on it you get #
	#  the contactcard of the contact you right-     #
	#  clicked on.                                   #
	##################################################
	proc clmenu { event evpar } {
		upvar 2 $evpar newvar
		#Add a separator to the menu
		$newvar(menu_name) add separator
		#Add label in the menu
		$newvar(menu_name) add command -label "Show contact-card" \
		-command "::ccard::drawwindow $newvar(user_login) 1"

	}




	#################################################
	# drawwindow( email side )                      #
	#  draws the wiccardndow with the specified side#
	#################################################
	proc drawwindow { email side } {

		#set the name of the window to .ccarcwin_[numeric value of adres]
		set w .ccardwin_[::md5::md5 $email]


		#destroy the window if it already exists, with an animation
		#==========================================================
		set window_existed 0
		if { [winfo exists $w] } {
			set window_existed 1
			set geo [wm geometry $w]

			#animation for turning the card
				scan [wm geometry $w] "%dx%d%*1\[+-\]%d%*1\[+-\]%d" width height wx wy
				while { $width >= 50 } {
					set interval 12
					set width [expr $width - $interval]
					set wx [expr $wx + [expr $interval/2]]
					wm geometry $w ${width}x${height}+$wx+$wy
					after 1
					update
				}
			#end of animation, destroy the window
			destroy $w
		}





		#Define the window
		#=================
		set nocolor white
		toplevel $w -background $nocolor -borderwidth 0

		#set geometry		
		if { $window_existed == 1 } {
			#If the window already existed and we redraw it, redraw it at the same position
			wm geometry $w $geo
		} else {
			#if we draw the window for the first time, draw it at an intelligent position, with the right size (300x210)
			set winw 300
			set winh 210			
			set mouse_x [winfo pointerx $w]			
			set mouse_y [winfo pointery $w]
			set xpos [expr $mouse_x - [expr $winw/2]]
			set ypos [expr $mouse_y - [expr $winh/2]]
			#if the window gets out of the screen, move it inside the screen, $border away from the edge
			set border 10
			if {[expr $xpos + $winw] > [winfo vrootwidth $w]} {
				set xpos [expr [winfo vrootwidth $w] - $winw -$border]
			}
			if {[expr $ypos + $winh] > [winfo vrootheight $w]} {
				set ypos [expr [winfo vrootheight $w] - $winh -$border]
			}
			wm geometry $w ${winw}x${winh}+$xpos+$ypos
		}

		#close the window when ESC is pressed, set focus so it can be closed with ESC
		bind $w <<Escape>> "destroy $w"
		focus $w

		#the overrideredirect makes it have no border and not draggable etc (no wm stuff)
		wm overrideredirect $w 1





		#Define the content of the window
		#================================
		#create the canvas where we will draw our stuff on
		set canvas $w.card
		canvas $canvas -width 300 -height 210 -bg $nocolor -highlightthickness 0 -relief flat -borderwidth 0

		#draw the "backgroundpicture"
		$canvas create image 0 0 -anchor nw -image [::skin::loadPixmap ccard_bg]
		
		#make it draggable
		bind $canvas <ButtonPress-1> "::ccard::buttondown $w"
		bind $canvas <B1-Motion> "::ccard::drag $w"
		bind $canvas <ButtonRelease-1> "::ccard::release $w"


		#The top buttons
		#---------------		
		CreateTopButtons $w $canvas $email $side

		#The body
		#--------
		drawbody $canvas $email $side 

		#The bottom buttons
		#---------------		
		CreateBottomButtons $w $canvas $email $side

		#pack the canvas into the window
		pack $canvas -side top -fill x
	}



	########################################################
	# Procs used by drawwindow                             #
	#   CreateButtons, CreateTopButton, CreateBottomButton #   		
	########################################################

	#create a button in the contactcard
	proc CreateButton {canvas tagname image hover_image xcoord command tooltip place} {
		variable xbegin
		if {$place == "top"} {
			set xbegin [expr $xcoord - [image width $image]]
			set ycoord 0
		} else {
			set xbegin [expr $xcoord + [image width $image]]
			set ycoord 185
		}
		$canvas create image $xcoord $ycoord  -anchor nw -image $image -activeimage $hover_image -tag $tagname
		$canvas bind $tagname <ButtonPress-1> $command
		tooltip $canvas $tagname "$tooltip"

	}

	#create the buttons on top of the window
	proc CreateTopButtons {w canvas email side} {
		#Set the coordinate on the right where the buttons should be drawn form (to the left)
		variable xbegin 270

		CreateButton $canvas closebutton [::skin::loadPixmap ccard_close] \
			[::skin::loadPixmap ccard_close_hover] $xbegin \
			"kill_balloon; destroy $w" "[trans close]" top

		CreateButton $canvas rightbutton [::skin::loadPixmap ccard_right] \
			[::skin::loadPixmap ccard_right_hover] $xbegin \
			"::ccard::changeside $email $side" "Turn the card" top

		CreateButton $canvas leftbutton [::skin::loadPixmap ccard_left] \
			[::skin::loadPixmap ccard_left_hover] $xbegin \
			"::ccard::changeside $email $side" "Turn the card" top

	}

	#create the buttons on the bottom of the window
	proc CreateBottomButtons {w canvas email side} {
		variable xbegin 1

		#only show the "send message" button if the contact is online
		if { [::abook::getVolatileData $email state FLN] != "FLN" } {
			CreateButton $canvas chatbutton [::skin::loadPixmap ccard_chat] \
				[::skin::loadPixmap ccard_chat_hover] $xbegin \
				"::amsn::chatUser ${email}" "[trans sendmsg]" bottom
		}

		CreateButton $canvas mailbutton [::skin::loadPixmap ccard_email] \
			[::skin::loadPixmap ccard_email_hover] $xbegin \
			"launch_mailer $email" "[trans sendmail]" bottom


		#if the user has a mobile set up, put a button to send mobile msgs
		if { [::abook::getContactData $email MOB] == "Y" } {

			CreateButton $canvas mobilebutton [::skin::loadPixmap ccard_mobile] \
			[::skin::loadPixmap ccard_mobile_hover] $xbegin  \
			"::MSNMobile::OpenMobileWindow ${email}" "[trans sendmobmsg]" bottom

		}


		#when a wink plugin is available, put a wink button here

		#nudge button only if plugin is loaded and the contact is online
		if { [::abook::getVolatileData $email state FLN] != "FLN" } {
			set pluginidx [lindex [lsearch -all $::plugins::loadedplugins "*Nudge*"] 0]
			if { $pluginidx != "" } {

				CreateButton $canvas nudgebutton [::skin::loadPixmap ccard_nudge] \
				[::skin::loadPixmap ccard_nudge_hover] $xbegin  \
				"::Nudge::ClSendNudge $email" "$::Nudge::language(send_nudge)" bottom

			}
		}



	}


	##################################################
	# drawbody( canvas email side )                  #
	#  defines the data that will be in the body of  #
	#  the contactcard, depending on the emailaddres #
	#  (id) of the contact and the side to display   #
	##################################################
	proc drawbody { canvas email side } {

		if {$side == 1} {
		#======================
		#This is the front side
		#======================
			set filename [::abook::getContactData $email displaypicfile ""]
			global HOME
			if { [file readable "[file join $HOME displaypic cache ${filename}].gif"] } {
				catch {image create photo user_pic_$email -file "[file join $HOME displaypic cache ${filename}].gif"}
			} else {
				image create photo user_pic_$email -file [::skin::GetSkinFile displaypic "nopic.gif"]
			}
			set bp_x 8
			set bp_y 26
			$canvas create image $bp_x $bp_y -anchor nw -image user_pic_$email
			$canvas create image [expr $bp_x -1 ]  [expr $bp_y -1 ] -anchor nw -image [::skin::loadPixmap ccard_bpborder] -tag tt
			$canvas create text 114 22 -text [::abook::getNick $email] -font bigfont -width 170 -justify left -anchor nw -fill black -tag dp
			tooltip $canvas tt "$email\n[trans status] : [trans [::MSN::stateToDescription [::abook::getVolatileData $email state]]]\n[trans lastmsgedme] : [::abook::dateconvert "[::abook::getContactData $email last_msgedme]"]"


			
		} else {
		#=====================
		#This is the back side
		#=====================
			set backtextcolor #616060
			set xcoord 12

			$canvas create text $xcoord 30 -text "[trans email]:\t$email" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor

			$canvas create image 10 66 -anchor nw -image [::skin::loadPixmap ccard_back_line]

			$canvas create text $xcoord 80 -text "[trans home]:\t[::abook::getContactData $email phh]" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor 
			$canvas create text $xcoord 100 -text "[trans work]:\t[::abook::getContactData $email phw]" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor
			$canvas create text $xcoord 120 -text "[trans mobile]:\t[::abook::getContactData $email phm]" -font bplainf -width 280 -justify left -anchor nw -fill $backtextcolor

		}
	}

	##################################################
	# changeside( email side )                       #
	#  redraws the window with the other side        #
	##################################################
	proc changeside {email side} {
		if {$side == 1} {
			drawwindow $email 2
		} else {
			drawwindow $email 1
		}
	}


	#Tooltips on canvas items, looked at guicontactlist.tcl
	proc tooltip {canvas item msg} {
		$canvas bind $item <Enter> [list balloon_enter %W %X %Y $msg]
		$canvas bind $item <Leave> "kill_balloon"
	}


	##################################################
	# Following procedures make the dragging of the  #
	# Contactcard possible.  Credits to the creator  #
	# of the winskin plugin, as the code was allmost #
	# integrally token from it                       #
	##################################################
	proc buttondown {w} {
		#define global vars
		variable dset
		variable dx
		variable dy
		variable width
		variable height
		#store the coords of the mouse
		set mousex [winfo pointerx $w]
		set mousey [winfo pointery $w]
		#set the coords/geometry of the window
		scan [wm geometry $w] "%dx%d%*1\[+-\]%d%*1\[+-\]%d" width height wx wy
		#set 'button is down'
		set dset 1
		#where is the mouse in the window ?
		set dx [expr {$wx-$mousex}]
		set dy [expr {$wy-$mousey}]
	}
	proc release {w} {
		variable dset
		#set 'button is released'
		set dset 0
	}
	proc drag {w} {
		variable dset
		variable dx
		variable dy
		variable width
		variable height
		if { $dset } {
			set x [winfo pointerx $w]
			set y [winfo pointery $w]
			wm geometry $w "${width}x${height}+[expr {$dx + $x}]+[expr {$dy + $y}]"
		}
	}
	#Thanks for this code to the winskin-plugin developper (Arieh)










#END OF PLUGIN, CLOSE "namespace" BRACKET
}






