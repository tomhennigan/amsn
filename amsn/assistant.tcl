
######################################################################################
######################################################################################
#####                                                                            #####
#####          Here begins the code for the (HIG-compliant) assistant            #####
#####                                                                            #####
######################################################################################
######################################################################################

package require snit

snit::widget assistant {

#DESCRIPTION:
#  A Snit widget used to create easily assistants
#
#SYNOPSIS:
#  assistant pathNameToTopLevel ?options?
#
#WIDGET SPECIFIC OPTIONS
#  -steps            number of steps of the assistant
#  -curstep          number of the current step
#  -winname          name of the window
#  -displaystep      (boolean) show the current step. default is FALSE = 0
#  -displaystepfull  (boolean) Display current step and steps in the window's
#     title : $winname -  Step 4/5 . Override the previous option.
#  -titlepixmap      name of an image describing the assistant, will be given
#     to ::skin::loadPixmap. Ex: webcam, like in [::skin::loadPixmap webcam]
#  -titlebg          background color of the title frame (called titlef)
#     Defaut: [::skin::getKey menuactivebackground]
#  -titlefg          foreground color of the title frame (called titlef)
#     Default: [::skin::getKey menuactiveforeground]  
#  -titleheight      Height of the title frame (called titlef)
#  -titletext        Text describing the assistant or the current step
#     Default: Assistant
#
#WIDGET SPECIFIC COMMANDS
#  pathname configure ?option? ?value?
#  pathname cget option
#  pathname getContentFrame
#  pathname clearContentFrame
#    returns also the pathname to ContentFrame
#  pathname setTitleText string
#  pathname register button action
#    button can be either "back", "next", or "close".
#    Bind the considered button to the action.
#    For the close button, it take care of destroying the widget
#  pathname unregister button
#    button can be either "back", "next", or "close"
#    Unbind the considered button to every action.
#    The close button still destroys the widget.
#    Make considered button inactive.
#
#
#Name of the parts of the window
#
#   +-------------------------------+<--window
#   |+-----------------------------+|
#   ||+---------------------------+||
#   |||           titlef           ||<---bodyf
#   ||+---------------------------+||
#   ||+---------------------------+||
#   |||                           |||
#   |||        ContentFrame       |||
#   |||                           |||
#   ||+---------------------------+||
#   |+-----------------------------+|
#   |+-----------------------------+|
#   ||           buttonf           ||
#   |+-----------------------------+|
#   +-------------------------------+

	hulltype toplevel

	variable titlec
	variable titlef
	variable buttonf
	variable contentf

	option -steps -default 1 -cgetmethod getOption -configuremethod setOption
	option -curstep -default 1  -cgetmethod getOption -configuremethod setStep

	option -winname -default "Assistant" -cgetmethod getOption -configuremethod setOption
#TODO: for the 2 following options, we should change the configure method so that it also change the win name
#see setTitleText and/or setStep
	option -displaystep -default 0 -cgetmethod getOption -configuremethod setOption
	option -displaystepfull -default 0 -cgetmethod getOption -configuremethod setOption
	
	option -titlepixmap -cgetmethod getOption -configuremethod setOption
	option -titlebg -cgetmethod getOption -configuremethod setOption
	option -titlefg -cgetmethod getOption -configuremethod setOption
	
	#text describing the assistant : Ex : Webcam Setup Assistant
	option -titletext -default "Assistant" -cgetmethod getOption -configuremethod setOption; #TODO: s/sedOption/setTitleText/
	option -titleheight -default 50 -cgetmethod getOption -configuremethod setOption

	option -winwidth -default 600 -cgetmethod getOption -configuremethod setOption
	option -winheight -default 500 -cgetmethod getOption -configuremethod setOption
	
	constructor {args} {

		#Make some defaults options
		#TODO : have skin settings for those :
		set options(-titlebg) [::skin::getKey menuactivebackground]
		set options(-titlefg) [::skin::getKey menuactiveforeground]

		$self configurelist $args
		
		set winname $options(-winname)
		if {$options(-displaystepfull)} {
			append winname " - [trans step] $options(-curstep)/$options(-steps)"
		} else {
			if {$options(-displaystep)} {
				append winname " - [trans step] $options(-curstep)"
			}
		}
		wm title $win $winname
		wm geometry $win $options(-winwidth)x$options(-winheight)

		set bodyf $win.bodyf
		set titlef $bodyf.titlef
		set titlec $titlef.titlec
		set buttonf $win.buttonf
		set contentf $bodyf.contentf
		
		frame $bodyf -bd 1  -background $options(-titlebg) 
		#create title frame and first contents
		frame $titlef -height $options(-titleheight) -bd 0 -bg $options(-titlebg) 
		canvas $titlec -height $options(-titleheight) -bg $options(-titlebg)
		#set a default text for the title in the canvas that can be changed
		$titlec create text 10 [expr {$options(-titleheight) / 2}] -text $options(-titletext) \
			-anchor w -fill $options(-titlefg) -font bboldf -tag titletext
		set image [::skin::loadPixmap $options(-titlepixmap)]
		$titlec create image [expr {$options(-winwidth) - [image width $image]/2}] \
			[expr {$options(-titleheight)/2}] -image $image -anchor e -tag img
		pack $titlec -fill x
		pack $titlef -side top -fill x
		pack $bodyf -side top -fill both -padx 4 -pady 4 -expand 1

		frame $contentf -padx 1 -pady 1 ;#-background #ffffff ;#-height 300   ;#these pads make a 1 pixel border
		pack $contentf -side top -fill both -expand 1 
		
		frame $buttonf  -bd 0 
		pack $buttonf  -side top  -fill x -padx 4 -pady 4 ;#pads keep the stuff a bit away from windowborder
		#add the buttons
		button $buttonf.back -text [trans back] -state disabled ;#first step of assistant, back button is disabled
		button $buttonf.next -text [trans next]
		button $buttonf.close -text [trans close] -command "destroy $self"
		#pack 'm
		pack $buttonf.next $buttonf.back $buttonf.close -padx 10 -side right
		
		bind $win <Configure> "$self WindowResized"

	}


	method WindowResized {} {
		#TODO : add smthg so that it refreshes only when user stops resizing
		set newwidth [winfo width $self]
		set xAmout [expr {$newwidth - $options(-winwidth)}]
		$titlec move img $xAmout 0
		set options(-winwidth) $newwidth
		set options(-winheight) [winfo height $self]
	}

	method getOption {option} {
		return $options($option)
	}
	method setOption {option value} {
		set options($option) $value
	}

	method getContentFrame {} {
		return $contentf
	}
	method clearContentFrame {} {
		if {[winfo exists $contentf]} { destroy $contentf }
		frame $contentf -padx 1 -pady 1 ;#-background #ffffff ;#-height 300   ;#these pads make a 1 pixel border
		pack $contentf -side top -fill both -expand 1
		return $contentf
	}
	
	method setTitleText {text} {
		#TODO: when using this method as a configuremethod, $titlec is unknown !!
		set options(-titletext) $text
		$titlec delete titletext
		$titlec create text 10 [expr {$options(-titleheight) / 2}] -text $options(-titletext) \
			-anchor w -fill $options(-titlefg) -font bboldf -tag titletext
	}

	method setStep {option step} {
		set options(-curstep) $step
		
		set winname $options(-winname)
		if {$options(-displaystepfull)} {
			append winname " - [trans step] $options(-curstep)/$options(-steps)"
		} else {
			if {$options(-displaystep)} {
				append winname " - [trans step] $options(-curstep)"
			}
		}
		wm title $win $winname
	}

	method register { button action } {
		switch $button {
			back {
				$buttonf.back configure -state normal -command $action
			}
			next {
				$buttonf.next configure -state normal -command $action
			}
			close {
				#NOTE: this event takes care of destroying the widget
				#can be used to save settings for example
				$buttonf.close configure -command " $action; $self destroy"
			}
			default {
				status_log "\[ASSISTANT\] wrong arg ($button) while calling Register" red
			}
		}
	}

	method unregister { button } {
		switch $button {
			back {
				$buttonf.back configure -state disabled -command ""
			}
			next {
				$buttonf.next configure -state disabled -command ""
			}
			close {
				$buttonf.close configure -command "$self destroy"
			}
			default {
				status_log "\[ASSISTANT\] wrong arg ($button) while calling Unregister" red
			}
		}
	}
}

#Skin-things added:
#* "Yes" emblem
#* "No" emblem
#* Webcam-icon

###################################################################################################
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
###################################################################################################

namespace eval ::CamAssistant {

	variable assistant

	######################################################################################
	#Procedure that starts the assistant.  It creates the window's framework etc         #
	######################################################################################
	
	proc WebcamAssistant {} {
		variable assistant
		#if we already have this window openend, raise it and quit this code (as there should only be 1 running)
		if {[winfo exists .wcassistantwindow]} {raise .wcassisstantwindow; return}
		
		#set the name of the window
		set assistant [assistant .wcassistantwindow -curstep 0 -steps 2 -winname "Webcam Setup Assistant" -titlepixmap webcam -titletext "Webcam Setup Assistant"]
			
		Step0
	}

	################################
	################################
	##                            ##
	##   CODE TO FILL THE PAGES:  ##
	##                            ##
	################################
	################################
	
	######################################################################################
	#Step 0 (intro-page)                                                                 #
	######################################################################################	
	proc Step0 {} {
		variable assistant
		status_log "entered step 0 of Webcam-Assistant"

		set contentf [$assistant clearContentFrame]
		
		#Remove displaysetfull since it can be set to 1 in Step1. Accessed here via back button
		$assistant configure -displaystepfull 0
		
		#add the Content
		label $contentf.text -justify left -anchor nw -font bplainf -text "This assistant will guide you through the setup of your webcam \nfor aMSN.\n\nIt will check if the required extensions are present and loaded \nand you'll be able to choose the device and channel, set the \npicture settings and resolution."
		#pack it
		pack $contentf.text -padx 20 -pady 20 -side left -fill both -expand 1
		
		$assistant register "next" ::CamAssistant::Step1
	}



	######################################################################################
	#Step 1: check for extensions                                                        #
	######################################################################################	
	proc Step1 {} {
		variable assistant

		status_log "entered step 1 of Webcam-Assistant"

		$assistant configure -displaystepfull 1
		$assistant configure -curstep 1
		
		#Set the title-text
		$assistant setTitleText "Check for required extensions (Step 1 of 2)"

		#clear the content and optionsframe
		set contentf [$assistant clearContentFrame]
		
		$assistant register "back" ::CamAssistant::Step0
		$assistant register "next" ::CamAssistant::Step2Ex
		
		##Webcam extension check##
		if {[::CAMGUI::ExtensionLoaded]} {
			set ::CamAssistant::infoarray(wcextloaded) 1
			set wcextpic [::skin::loadPixmap yes-emblem]
		} else {
			set ::CamAssistant::infoarray(wcextloaded) 0
			set wcextpic [::skin::loadPixmap no-emblem]
		}

		##Capture extension check
		#set the name for the capture extension
		set capextname "grab"
		if { [OnWin] } { set capextname "tkvideo"}\
		 elseif { [OnDarwin] } { set capextname "QuickTimeTcl"}\
		 elseif { [OnLinux] } { set capextname "capture" }
		
		#check if loaded
		if {[::CAMGUI::CaptureLoaded]} { 
			set ::CamAssistant::infoarray(capextloaded) 1
			set capextpic [::skin::loadPixmap yes-emblem]	
		} else {
			set ::CamAssistant::infoarray(capextloaded) 0
			set capextpic [::skin::loadPixmap no-emblem]
		}		

		#maybe we should do better checks like "you can receive but not send if the grabber is unavailable ...
		if { $capextpic == [::skin::loadPixmap no-emblem] ||$wcextpic == [::skin::loadPixmap no-emblem] } {
			$buttonf.next configure -state disabled
		}
		
		
		#pack a frame inside where we put our stuff in so it's away from theedges of the window
		set frame $contentf.innerframe		
		frame $frame -bd 0 
		pack $frame -padx 20 -pady 50

		#create frames for the both lines (I want the emblem on the right)		
		set wcextbox $frame.wcextbox
		set capextbox $frame.capextbox
		frame $wcextbox -bd 0 
		frame $capextbox -bd 0 
		pack $wcextbox $capextbox -side top -padx 10 -pady 10 -fill y
		
		set wcexttext $wcextbox.wcexttext
		set wcextpicl $wcextbox.wcextpicl

		set capexttext $capextbox.capexttext
		set capextpicl $capextbox.capextpicl

		label $wcexttext -justify left -anchor nw -font bboldf -text "Check if webcam extension is loaded ..." ;#-fg $wcexttextcolor
		label $capexttext -justify left -anchor nw -font bboldf -text "Check if '$capextname' extension is loaded ..." ;#-fg $wcexttextcolor
		

		label $wcextpicl -image $wcextpic -bg [::skin::getKey menubackground]
		label $capextpicl -image $capextpic -bg [::skin::getKey menubackground]

		pack $wcexttext -side left -expand 1	
		pack $wcextpicl -side right				
		pack $capexttext -side left
		pack $capextpicl -side right
	}
	
	#THIS PROC IS ONLY AN EXAMPLE
	proc Step2Ex {} {
		variable assistant

		$assistant configure -curstep 2
		
		#Set the title-text
		$assistant setTitleText "Finished, or not ... (Step 2 of 2)"

		#clear the content and optionsframe
		set contentf [$assistant clearContentFrame]
		
		$assistant register "back" ::CamAssistant::Step1
		$assistant unregister "next" 
	
		#add the Content
		label $contentf.text -justify left -anchor nw -font bplainf -text "To be continued ....."
		#pack it
		pack $contentf.text -padx 20 -pady 20 -side left -fill both -expand 1
		
	}


#	TODO: add stuff from msncam.tcl

#Close the ::CamAssistant namespace
}



::CamAssistant::WebcamAssistant

