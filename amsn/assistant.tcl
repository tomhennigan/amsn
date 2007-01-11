
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

	#list describing the steps
	variable steps_l
	#index in the list of steps
	variable steps_l_i

	variable titlec
	variable titlef
	variable buttonf
	variable contentf

	option -steps -default 1 -cgetmethod getOption -configuremethod setOption
	option -curstep -default 1  -cgetmethod getOption -configuremethod setCurStep

	option -winname -default "Assistant" -cgetmethod getOption -configuremethod setOption
#TODO: for the 2 following options, we should change the configure method so that it also change the win name
#see setTitleText and/or setStep
	option -displaystep -default 0 -cgetmethod getOption -configuremethod setOption
	option -displaystepfull -default 0 -cgetmethod getOption -configuremethod setOption
	
	option -titlepixmap -cgetmethod getOption -configuremethod setOption
	option -titlebg -cgetmethod getOption -configuremethod setOption
	option -titlefg -cgetmethod getOption -configuremethod setOption
	
	#text describing the assistant : Ex : Webcam Setup Assistant
	option -titletext -default "Assistant" -cgetmethod getOption -configuremethod setOption; #TODO: s/setOption/setTitleText/
	option -titleheight -default 50 -cgetmethod getOption -configuremethod setOption

	option -winwidth -default 600 -cgetmethod getOption -configuremethod setOption
	option -winheight -default 500 -cgetmethod getOption -configuremethod setOption
	
	constructor {args} {

		#
		set steps_l [list]

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
		set xAmount [expr {$newwidth - $options(-winwidth)}]
		$titlec move img $xAmount 0
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

	method setCurStep {option step} {
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

	method incrCurStep {} {
		incr options(-curstep)
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

	method Back {} {
		incr options(-curstep) -1

		$self register next [lindex $steps_l $steps_l_i]
		
		incr steps_l_i -1
		
		if {$steps_l_i == 0} {
			$self unregister back	
		} else {
			$self register back [lindex $steps_l [expr {$steps_l_i - 1}]]
		}

		eval [lindex $steps_l $steps_l_i] [$self clearContentFrame] 
	}
	method Next {} {
		incr options(-curstep)

		$self register back [lindex $steps_l $steps_l_i]
		
		incr steps_l_i
		
		if {$steps_l_i == [llength $steps_l]} {
			$self unregister next
		} else {
			$self register next [lindex $steps_l [expr {$steps_l_i + 1}]]
		}

		eval [lindex $steps_l $steps_l_i] [$self clearContentFrame] 
	}

	method ClearSteps {} {
		set steps_l [list]
		set steps_l_i 0
	}

	method AddSteps { Steps } {
		if { $steps_l == [list] } {
			lappend steps_l $Steps
			eval [lindex $steps_l 0] [$self clearContentFrame]
		} else {
			lappend steps_l $Steps
		}
		set options(-steps) [llength $steps]
	}

}

#Skin-things added:
#* "Yes" emblem
#* "No" emblem
#* Webcam-icon

###################################################################################################
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
###################################################################################################

namespace eval ::AVAssistant {

	variable assistant

	######################################################################################
	#Procedure that starts the assistant.  It creates the window's framework etc         #
	######################################################################################
	
	proc AVAssistant {} {
		variable assistant
		#if we already have this window openend, raise it and quit this code (as there should only be 1 running)
		if {[winfo exists .wcassistantwindow]} {raise .wcassisstantwindow; return}
		
		#set the name of the window
		set assistant [assistant .wcassistantwindow -curstep 0 -steps 3 -winname "Audio and Video Setup Assistant" -titlepixmap webcam -titletext "Audio and Video Setup Assistant"]
			
		::AVAssistant::Step0
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
		status_log "entered step 0 of AudioVideo-Assistant"

		set contentf [$assistant clearContentFrame]
		
		#Remove displaysetfull since it can be set to 1 in Step1. Accessed here via back button
		$assistant configure -displaystepfull 0
		
		#add the Content
		label $contentf.text -justify left -anchor nw -font bplainf -text "This assistant will guide you through the setup of your audio and video settings \nfor aMSN.\n\nIt will check if the required extensions are present and loaded \nand you'll be able to choose the device and channel, set the \npicture settings and resolution."
		#pack it
		pack $contentf.text -padx 20 -pady 20 -side left -fill both -expand 1
		
		$assistant register "next" ::AVAssistant::Step0W
	}



	######################################################################################
	#Step 1: check for extensions for Webcam setup                                       #
	######################################################################################	
	proc Step0W {} {
		variable assistant

		status_log "entered step 1 of Webcam-Assistant"
		
		#Set the title-text
		$assistant setTitleText "Check for required extensions"

		#clear the content and optionsframe
		set contentf [$assistant clearContentFrame]
		
		$assistant register "back" ::AVAssistant::Step0
		
		##Webcam extension check##
		if {[::CAMGUI::ExtensionLoaded]} {
			set ::AVAssistant::infoarray(wcextloaded) 1
			set wcextpic [::skin::loadPixmap yes-emblem]
		} else {
			set ::AVAssistant::infoarray(wcextloaded) 0
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
			set ::AVAssistant::infoarray(capextloaded) 1
			set capextpic [::skin::loadPixmap yes-emblem]	
		} else {
			set ::AVAssistant::infoarray(capextloaded) 0
			set capextpic [::skin::loadPixmap no-emblem]
		}		

		if {$::AVAssistant::infoarray(wcextloaded) && $::AVAssistant::infoarray(capextloaded)} {
			::AVAssistant::Step1W
		} else {
			#maybe we should do better checks like "you can receive but not send if the grabber is unavailable ...
			if { $capextpic == [::skin::loadPixmap no-emblem] || $wcextpic == [::skin::loadPixmap no-emblem] } {
				$buttonf.next configure -state disabled
			}
			
			$contentf configure -padx 20 -pady 35

			#create frames for the both lines (I want the emblem on the right)		
			set wcextbox $contentf.wcextbox
			set capextbox $contentf.capextbox
			frame $wcextbox -bd 0 
			frame $capextbox -bd 0 
			pack $wcextbox $capextbox -side top -padx 10 -pady 10 -fill y
			
			set wcexttext $wcextbox.wcexttext
			set wcextpicl $wcextbox.wcextpicl

			set capexttext $capextbox.capexttext
			set capextpicl $capextbox.capextpicl

			label $wcexttext -justify left -anchor nw -font bboldf -text "Check if webcam extension is loaded ..." ;#-fg $wcexttextcolor
			if {!$::AVAssistant::infoarray(wcextloaded)} {
				label $wcextbox.wcextwarn -justify left -anchor nw -text "You won't be able to view your contacts'webcams. You may find answers on how to install that extension on our Wiki : "
				#TODO: fill the url
				label $wcextbox.wcextwarnurl -justify left -anchor nw -text "$::weburl/userwiki/" -fg blue
			}
			label $capexttext -justify left -anchor nw -font bboldf -text "Check if '$capextname' extension is loaded ..." ;#-fg $wcexttextcolor
			if {!$::AVAssistant::infoarray(capextloaded)} {
				label $capextbox.capextwarn -justify left -anchor nw -text "You won't be able to send your webcam if you have one. If not, it's normal. You may find answers on how to install that extension on our Wiki : "
				#TODO: fill the url
				label $capextbox.capextwarnurl -justify left -anchor nw -text "$::weburl/userwiki/" -fg blue
			}
			

			label $wcextpicl -image $wcextpic -bg [::skin::getKey menubackground]
			label $capextpicl -image $capextpic -bg [::skin::getKey menubackground]

			pack $wcexttext -side left -expand 1
			pack $wcextpicl -side right
			if {!$::AVAssistant::infoarray(wcextloaded)} {
				pack $wcextbox.wcextwarn $wcextbox.wcextwarnurl
				bind $wcextbox.wcextwarnurl <Enter> "$wcextbox.wcextwarnurl configure -font sunderf"
				bind $wcextbox.wcextwarnurl <Leave> "$wcextbox.wcextwarnurl configure -font splainf"
				bind $wcextbox.wcextwarnurl <ButtonRelease> "launch_browser $::weburl/userwiki"
			}
			pack $capexttext -side left
			pack $capextpicl -side right
			if {!$::AVAssistant::infoarray(capextloaded)} {
				pack $capextbox.capextwarn $capextbox.capextwarnurl
				bind $capextbox.capextwarnurl <Enter> "$capextbox.capextwarnurl configure -font sunderf"
				bind $capextbox.capextwarnurl <Leave> "$capextbox.capextwarnurl configure -font splainf"
				bind $capextbox.capextwarnurl <ButtonRelease> "launch_browser $::weburl/userwiki"
			}
			
			$assistant register "next" ::AVAssistant::Step1W
		}
	}
	
	######################################################################################
	#Step 2:  Set device/channel                                                         #
	######################################################################################	
	proc Step1W {} {
		variable assistant
		#we should be able to alter this vars in other procs
		variable chanswidget
		variable previmc
		variable selecteddevice
		variable selectedchannel	
		variable channels
		variable previmg

		status_log "entered step 2 of Webcam-Assistant, or 2&3 for mac"
		$assistant configure -curstep 1
		$assistant configure -displaystepfull 1
		
		#clear the content and optionsframe
		set contentf [$assistant clearContentFrame]
		
		$assistant register "back" ::AVAssistant::Step0
		$assistant register "next" ::AVAssistant::Step2W
	
		#when running on mac, this will be step 2 and 3 with only 1 button to open the QT prefs
		if { [OnDarwin] } {
			$assistant configure -steps 2
			#Set the title-text
			$assistant setTitleText "Set up webcamdevice and channel and finetune picture"

			#add the buttons
			$assistant register "next" ::AVAssistant::Step0A
			
			$contentf configure -padx 10 -pady 10
			
			button $contentf.button -text "Open camsettings window" -command "::CAMGUI::ChooseDeviceMac"
			pack $contentf.button
		} else {
			#Set the title-text
			$assistant setTitleText "Set up webcamdevice and channel (Step 2 of 5)"

			$assistant register "close" ::AVAssistant::stopPreviewGrabbing

			##Here comes the content:##

			#build the GUI framework (same for windows/linux)
				
# +-------------------------+
# |+----------+ +---------+ |--innerframe ($contenf)
# ||          | |         | |
# ||          | |         | |
# ||          | |         |----rightframe (a canvas $rightframe))
# ||          | |         | |
# ||          | |         | |
# ||          |-|---------|----leftframe
# |+----------+ +---------+ |
# +-------------------------+

			#create the left frame (for the comboboxes)
			set leftframe $contentf.left
			frame $leftframe -bd 0
			pack $leftframe -side left -padx 10

			#create the 'rightframe' canvas where the preview-image will be shown
			set rightframe $contentf.right

			if { [::config::getKey lowrescam] == 1 } {
				set camwidth 160
				set camheight 120
			} else {
				set camwidth 320
				set camheight 240
			}

			#this is a canvas so we can have a border and put some OSD-like text on it too
			canvas $rightframe -background #000000 -width $camwidth -height $camheight -bd 0
			pack $rightframe -side right -padx 10

			#draw the border image that will be layed ON the preview-img
			$rightframe create image 0 0 -image [::skin::loadPixmap camempty] -anchor nw -tag border
			#give the canvas a clear name
			set previmc $rightframe

			##First "if on unix" (linux -> v4l), then for windows##
			if {[OnLinux]} {

				#first clear the grabber var
				set ::CAMGUI::webcam_preview ""

				#ask the list of devices on the system

				set devices [::Capture::ListDevices]

				#check if we have devices available, if not we're gonne show a msg instead of the 
				# comboboxes
				if { [llength $devices] == 0 } {
					status_log "Webcam-Assistant: No devices available"
					#have some message showing no device and go further with
					#we have minimum 1 device available
				} else {
				
					#First line, device-chooser title
					label $leftframe.devstxt -text "Choose device:"
					pack $leftframe.devstxt -side top
				
					#create and pack the devices-combobox
					combobox::combobox $leftframe.devs -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf -exportselection true -editable false -command "::AVAssistant::FillChannelsLinux" 

					#make sure the devs-combobox is empty first
					$leftframe.devs list delete 0 end
					
					#get the already set device from the config (if there is one set)
					set setdev [lindex [split [::config::getKey "webcamDevice"] ":"] 0]
					#set the count to see which nr this device has in the list on -1 to begin,
					# so it becomes 0 if it's the first element in the list ([lindex $foo 0])
					set count -1
					#set a start-value for the device's nr
					set setdevnr -1
						
					#insert the device-names in the widget
					foreach device $devices {
status_log "device=$device"
						set dev [lindex $device 0]
						set name [lindex $device 1]

						#it will allways set the last one, which is a bit weird to the
						# user though if he has like /dev/video0 that come both as V4L 
						# and V4L2 device
						incr count
						#store which nr the setdev has in the combobox
						if { $dev == $setdev} {
							set setdevnr $count
						}

						#if we can't get the name, show it the user
						if {$name == "" } {
							#TODO: is this the right cause ?
							set name "$dev (Err: busy?)"
							status_log "Webcam-Assistant: No name found for $dev ... busy ?"
						}
						#put the name of the device in the widget
						$leftframe.devs list insert end $name
					}
					#pack the dev's combobox
					pack $leftframe.devs -side top

					#create and pack the chans-txt
					label $leftframe.chanstxt -text "\n\nChoose channel:"
					pack $leftframe.chanstxt -side top

					#create and pack the chans-combobox
					set chanswidget $leftframe.chans
					combobox::combobox $leftframe.chans -highlightthickness 0 -width 22 -font splainf -exportselection true -command "after 1 ::AVAssistant::StartPreviewLinux" -editable false -bg #FFFFFF
					pack $leftframe.chans -side top 

					#Select the device if in the combobox (won't select anything if -1)
					catch {$leftframe.devs select $setdevnr}
			
				
				#close the "if no devices avaliable / else" statement
				}
				
			#If on windows
			} else {
			
				#TODO ... (tobe continued ... :))
				status_log "we are on windows, in developpement"
									
			
			#End the platform checks
			# we're sure it's win, lin or mac.  maybe a check for unsupported platform on teh 1st page ?
			} 

		#end the "if on mac / else" statement
		}		
	#end the Step2 proc
	}


	######################################################################################
	#Step 2 - Auxilary procs                                                             #
	######################################################################################	

	proc FillChannelsLinux {devswidget value} {
		variable chanswidget
		variable selecteddevice
		variable channels
		
		if { $value == "" } {
			status_log "No device selected; CAN'T BE POSSIBLE ?!?"
		} else {
	
			#get the nr of the selected device
			set devnr [lsearch [$devswidget list get 0 end] $value]
			#get that device out of the list and the first element is the device itself ([list /dev/foo "name"])
			set selecteddevice [lindex [lindex [::Capture::ListDevices] $devnr] 0]

			if { [catch {set channels [::Capture::ListChannels $selecteddevice]} errormsg] } {
				status_log "Webcam-Assistant: Couldn't list chans for device $selecteddevice: $errormsg"
				return
			}

			#make sure the chanswidget is empty before filling it
			$chanswidget list delete 0 end


			#search the already set channel (cfr devices)
			set setchan [lindex [split [::config::getKey "webcamDevice"] ":"] 1]
			set count -1
			set setchannr -1

			foreach channel $channels {
				set chan [lindex $channel 0] ;#this is a nr
				set channame [lindex $channel 1]
				incr count

				if { $chan == $setchan} {
					set setchannr $count
				}

				$chanswidget list insert end $channame
			}
	
			#select the already set chan if possible
			catch {$chanswidget select $setchannr}
			
		}

	}	
	
	
	proc StartPreviewLinux {chanswidget value} {
		variable selecteddevice
		variable selectedchannel
		variable channels
		variable previmc
		variable previmg
		variable cam_res

#		WcAssistant_stopPreviewGrab
		
	
		if { $value == "" } {
			status_log "No channel selected; IS THIS POSSIBLE ?"
		} else {

			#get the nr of the selected channel
			set channr [lsearch [$chanswidget list get 0 end] $value]
			#get that channel out of the list and the first element is the chan itself ([list 0 "television"])
			set selectedchannel [lindex [lindex $channels $channr] 0]
			status_log "Will preview: $selecteddevice on channel $selectedchannel"

			
			#close the device if open
			if { [::Capture::IsValid $::CAMGUI::webcam_preview] } {
				::Capture::Close $::CAMGUI::webcam_preview
			}

			if { [catch {set ::CAMGUI::webcam_preview [::Capture::Open $selecteddevice $selectedchannel]} errormsg] } {
				status_log "problem opening device: $errormsg"
				return
			}

			set previmg [image create photo [TmpImgName]]

					
			$previmc create image 0 0 -image $previmg -anchor nw 

			$previmc create text 10 10 -anchor nw -font bboldf -text "Preview $selecteddevice:$selectedchannel" -fill #FFFFFF -anchor nw -tag device


			after 2 "catch { $previmc delete device }"

			#put the border-pic on top
			$previmc raise border
			setPic $::CAMGUI::webcam_preview
			
			set semaphore ::CAMGUI::sem_$::CAMGUI::webcam_preview
			set $semaphore 0
			if { [::config::getKey lowrescam] == 1 } {
				set cam_res "LOW"
			} else {
				set cam_res "HIGH"
			}
			while { [::Capture::IsValid $::CAMGUI::webcam_preview] && [ImageExists $previmg] } {
				if {[catch {::Capture::Grab $::CAMGUI::webcam_preview $previmg $cam_res} res ]} {
					status_log "Problem grabbing from the device:\n\t \"$res\""
					$previmc create text 10 215 -anchor nw -font bboldf -text "ERROR: $res" -fill #FFFFFF -anchor nw -tag errmsg
				after 2000 "catch { $previmc delete errmsg }"
					
				}
				after 1000 "incr $semaphore"
				tkwait variable $semaphore
			}
			
		
		}
	
	
	}
	###proc to stop the grabber###
	proc stopPreviewGrabbing {} {
		variable previmg
		
		if { [info exists ::CAMGUI::webcam_preview]} {
			if { [::Capture::IsValid $::CAMGUI::webcam_preview] } {
				::Capture::Close $::CAMGUI::webcam_preview
			}
		}
		catch {image delete $previmg}
		status_log "Webcam-Assistant: Stopped grabbing"
	}
	#proc to store the values when we go from step 2 to step 3
	proc step2_to_step3 {} {
		variable selecteddevice
		variable selectedchannel

		stopPreviewGrabbing
		

		#save settings
		::config::setKey "webcamDevice" "$selecteddevice:$selectedchannel"
		
		Step3
	}
	
	
	#proc to set the picture settings
	proc setPic { grabber } {
		variable selecteddevice
		variable selectedchannel

		variable brightness
		variable contrast
		variable hue
		variable color

		status_log "grabber=$grabber"
		
		#First set the values to the one the cam is on when we start preview
		set brightness [::Capture::GetBrightness $grabber]
		set contrast [::Capture::GetContrast $grabber]	
		set hue [::Capture::GetHue $grabber]	
		set color [::Capture::GetColour $grabber]	


		#Then, if there are valid settings in our config, overwrite the values with these
		set colorsettings [split [::config::getKey "webcam$selecteddevice:$selectedchannel"] ":"]
		set set_b [lindex $colorsettings 0]
		set set_c [lindex $colorsettings 1]
		set set_h [lindex $colorsettings 2]
		set set_co [lindex $colorsettings 3]
		
		if {[string is integer -strict $set_b]} {
				set brightness $set_b
		}
		if {[string is integer -strict $set_c]} {
				set contrast $set_c
		}
		if {[string is integer -strict $set_h]} {
				set hue $set_h
		}
		if {[string is integer -strict $set_co]} {
				set color $set_co
		}
		
		#Set 'm	
		::Capture::SetBrightness $grabber $brightness
		::Capture::SetContrast $grabber $contrast
		::Capture::SetHue $grabber $hue
		::Capture::SetColour $grabber $color		
	}


	######################################################################################
	#Step 2W:  Finetune picture settings                                                  #
	######################################################################################	

	proc Step2W {} {
		variable assistant
		#Only linux for now ...
		variable selecteddevice
		variable selectedchannel
		variable cam_res

		variable brightness
		variable contrast
		variable hue
		variable color
		
		
		status_log "entered step 3 of Webcam-Assistant"

		#Set the title-text
		$assistant setTitleText "Finetune picture settings"
		#clear the content and optionsframe
		set contentf [$assistant clearContentFrame]

		#add the buttons
		$assistant register "back" "::AVAssistant::stopPreviewGrabbing; ::AVAssistant::Step1W" ;#save the thing ?
		$assistant register "next" "::AVAssistant::step3_to_step4 $::CAMGUI::webcam_preview" ;#needs to save the thing !
		$assistant register "close" ::AVAssistant::stopPreviewGrabbing
		
		#create the innerframe
		set frame $contentf.innerframe
		frame $frame -bd 0
		pack $frame -padx 10 -pady 10 -side left
		#create the left frame (for the comboboxes)
		set leftframe $frame.left
		#frame $leftframe -bd 0
		#pack $leftframe -side left -padx 10

		if { [::config::getKey lowrescam] == 1 } {
			set camwidth 160
			set camheight 120
		} else {
			set camwidth 320
			set camheight 240
		}


		#create the 'rightframe' canvas where the preview-image will be shown
		set rightframe $frame.right
		#this is a canvas so we gcan have a border and put some OSD-like text on it too
		canvas $rightframe -background #000000 -width $camwidth -height $camheight -bd 0
		pack $rightframe -side right -padx 10

		#draw the border image that will be layed ON the preview-img
		$rightframe create image 0 0 -image [::skin::loadPixmap camempty] -anchor nw -tag border
		#give the canvas a clear name
		set previmc $rightframe



		#close the device if open
		if { [::Capture::IsValid $::CAMGUI::webcam_preview] } {
			::Capture::Close $::CAMGUI::webcam_preview
		}

		if { [catch {set ::CAMGUI::webcam_preview [::Capture::Open $selecteddevice $selectedchannel]} errormsg] } {
			status_log "problem opening device: $errormsg"
			return
		}

		set previmg [image create photo [TmpImgName]]

					
		$previmc create image 0 0 -image $previmg -anchor nw 
		$previmc create text 10 10 -anchor nw -font bboldf -text "Preview $selecteddevice:$selectedchannel" -fill #FFFFFF -anchor nw -tag device


		after 2000 "catch { $previmc delete device }"

		#put the border-pic on top
		$previmc raise border


		#First set the values to the one the cam is on when we start preview
		set brightness [::Capture::GetBrightness $::CAMGUI::webcam_preview]
		set contrast [::Capture::GetContrast $::CAMGUI::webcam_preview]	
		set hue [::Capture::GetHue $::CAMGUI::webcam_preview]	
		set color [::Capture::GetColour $::CAMGUI::webcam_preview]	
status_log "Device: $brightness, $contrast, $hue, $color"


		#Then, if there are valid settings in our config, overwrite the values with these
		set colorsettings [split [::config::getKey "webcam$selecteddevice:$selectedchannel"] ":"]
		set set_b [lindex $colorsettings 0]
		set set_c [lindex $colorsettings 1]
		set set_h [lindex $colorsettings 2]
		set set_co [lindex $colorsettings 3]
		
		if {[string is integer -strict $set_b]} {
				set brightness $set_b
		}
		if {[string is integer -strict $set_c]} {
				set contrast $set_c
		}
		if {[string is integer -strict $set_h]} {
				set hue $set_h
		}
		if {[string is integer -strict $set_co]} {
				set color $set_co
		}
status_log "Config'ed: $brightness, $contrast, $hue, $color"


		set slides $leftframe
		frame $slides
		scale $slides.b -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Brightness" -command "::AVAssistant::Properties_SetLinux $slides.b b $::CAMGUI::webcam_preview" -orient horizontal
		scale $slides.c -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Contrast" -command "::AVAssistant::Properties_SetLinux $slides.c c $::CAMGUI::webcam_preview" -orient horizontal
		scale $slides.h -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Hue" -command "::AVAssistant::Properties_SetLinux $slides.h h $::CAMGUI::webcam_preview" -orient horizontal
		scale $slides.co -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Colour" -command "::AVAssistant::Properties_SetLinux $slides.co co $::CAMGUI::webcam_preview" -orient horizontal

		pack $slides.b $slides.c $slides.h $slides.co -expand true -fill x
		pack $leftframe -side right -padx 10

		#set the sliders right
		Properties_SetLinux $slides.b b $::CAMGUI::webcam_preview $brightness
		Properties_SetLinux $slides.c c $::CAMGUI::webcam_preview $contrast
		Properties_SetLinux $slides.h h $::CAMGUI::webcam_preview $hue
		Properties_SetLinux $slides.co co $::CAMGUI::webcam_preview $color

		
		set semaphore ::CAMGUI::sem_$::CAMGUI::webcam_preview
		set $semaphore 0
		while { [::Capture::IsValid $::CAMGUI::webcam_preview] && [ImageExists $previmg] } {
			if {[catch {::Capture::Grab $::CAMGUI::webcam_preview $previmg $cam_res} res ]} {
				status_log "Problem grabbing from the device:\n\t \"$res\""
				$previmc create text 10 215 -anchor nw -font bboldf -text "ERROR: $res" -fill #FFFFFF -anchor nw -tag errmsg
				after 2000 "catch { $previmc delete errmsg }"				
				
			}
			after 100 "incr $semaphore"
			tkwait variable $semaphore
		}

#TODO: Add a key-combo to reread the device settings and set these and go to next step (to adjust to settings of other programs)

	}

	######################################################################################
	#Step 3 - Auxilary procs                                                             #
	######################################################################################	
	proc Properties_SetLinux { w property capture_fd new_value } {
		variable selecteddevice
		variable selectedchannel
		
		variable brightness
		variable contrast
		variable hue
		variable color		


#		set b [::Capture::GetBrightness $capture_fd]
#		set c [::Capture::GetContrast $capture_fd]
#		set h [::Capture::GetHue $capture_fd]
#		set co [::Capture::GetColour $capture_fd]

		
		switch $property {
			b {
				::Capture::SetBrightness $capture_fd $new_value
				set brightness [::Capture::GetBrightness $capture_fd]
				$w set $brightness
			}
			c {
				::Capture::SetContrast $capture_fd $new_value
				set contrast [::Capture::GetContrast $capture_fd]
				$w set $contrast
			}
			h
			{
				::Capture::SetHue $capture_fd $new_value
				set hue [::Capture::GetHue $capture_fd]
				$w set $hue
			}
			co
			{
				::Capture::SetColour $capture_fd $new_value
				set color [::Capture::GetColour $capture_fd]
				$w set $color
			}
		}
#	::config::setKey "webcam$selecteddevice:$selectedchannel" "$b:$c:$h:$co"

	}
	#proc to store the values when we go from step 2 to step 3
	proc step3_to_step4 {grabber} {
		variable selecteddevice
		variable selectedchannel

		variable brightness
		variable contrast
		variable hue
		variable color

		#save settings
		::config::setKey "webcam$selecteddevice:$selectedchannel" "$brightness:$contrast:$hue:$color"

		stopPreviewGrabbing
		
		
		Step4
	}	

	
	
	
	######################################################################################
	#Step 4:  Network stuff                                                              #
	######################################################################################		
	proc Step4 {} {
#Step 4
		status_log "entered step 4 of Webcam-Assistant"

		#Set the title-text
		SetTitlecText "Network settings (Step 4 of 5)"
		#clear the content and optionsframe
		set contentf [ClearContentFrame]
		set buttonf [ClearButtonsFrame]

		#add the buttons
		button $buttonf.back -text "Back" -command "::CAMSETUP::Step3"
		button $buttonf.next -text "Next" -command "::CAMSETUP::Step5" ;#needs to save the thing !
		button $buttonf.cancel -text "Close" -command "destroy $::CAMSETUP::window"
		#pack 'm
		pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right


		#create the innerframe
		set frame $contentf.innerframe
		frame $frame -bd 0
		pack $frame -padx 10 -pady 10

		if {[::abook::getDemographicField conntype] == "IP-Restrict-NAT" && [::abook::getDemographicField listening] == "false"} {
			label $frame.abookresult -text "[trans firewalled]" -font bboldf
		} else {
			label $frame.abookresult -text "[trans portswellconfigured]" -font bboldf
		}
		
		pack $frame.abookresult

	}



	######################################################################################
	#Step 5:  Congrats                                                                   #
	######################################################################################		
	proc Step5 {} {
#Step 4
		status_log "entered step 5 of Webcam-Assistant"

		#Set the title-text
		SetTitlecText "Done (Step 5 of 5)"
		#clear the content and optionsframe
		set contentf [ClearContentFrame]
		set buttonf [ClearButtonsFrame]

		#add the buttons
		button $buttonf.back -text "Back" -command "::CAMSETUP::Step4"
		button $buttonf.next -text "Done" -command "destroy $::CAMSETUP::window"
		button $buttonf.cancel -text "Close" -command "destroy $::CAMSETUP::window"
		#pack 'm
		pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right


		#create the innerframe
		set frame $contentf.innerframe
		frame $frame -bd 0
		pack $frame -padx 10 -pady 10


		label $frame.txt -text "Done" -font bboldf

		
		pack $frame.txt

	}



#	TODO: add stuff from msncam.tcl

#Close the ::AVAssistant namespace
}



::AVAssistant::AVAssistant

