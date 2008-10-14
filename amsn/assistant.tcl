######################################################################################
######################################################################################
#####                                                                            #####
#####          Here begins the code for the (HIG-compliant) assistant            #####
#####                                                                            #####
######################################################################################
######################################################################################

::Version::setSubversionId {$Id$}

package require snit

snit::widget assistant {

# DESCRIPTION:
#  A Snit widget used to easily create assistants
#
# SYNOPSIS:
#  assistant pathName ?options?
#
# WIDGET SPECIFIC OPTION
#  -winname   name of the window
#  -winwidth  width of the window
#  -winheight height of the window
#
# WIDGET SPECIFIC COMMANDS
#  pathname configure ?option? ?value?
#  pathname cget option
#  pathname getContentFrame
#  pathname clearContentFrame
#  pathname getName
#  pathname setFinishProc
#  pathname getFinishProc
#  pathname setTitleText
#  pathname addCancelProc
#  pathname removeCancelProc
#  pathname cancel
#  pathname back
#  pathname next
#  pathname finish
#  pathname enableNextButton
#  pathname disableNextButton
#  pathname goToStep
#  pathname clearSteps
#  pathname addStepEnd
#  pathname removeStep
#  pathname insertStepBefore
#  pathname insertStepAfter
#  pathname modifyStep
#
# Name of the parts of the window
#
#   +-------------------------------+<--window
#   |+-----------------------------+|
#   ||+---------------------------+||
#   |||           titlef          ||<---bodyf
#   ||+---------------------------+||
#   ||+---------------------------+||
#   |||                           |||
#   |||        ContentFrame       |||
#   |||                           |||
#   ||+---------------------------+||
#   |+----------------------------+||
#   |+-----------------------------+|
#   ||           buttonf           ||
#   |+-----------------------------+|
#   +-------------------------------+

#TODO: add comments & improve documentation!
#TODO: turn some methods into procs
#TODO: add a listbox on the left where we diplay the steps once we've seen them
#      a bit like Office installation. (Phil's idea)
#      will be hard to implement

	hulltype toplevel


	#list describing the steps
	variable steps_l
	#each element of this list is a list of 6 elements describing a step
	#Those elements are :
	# 0) name: name/identifier of the step
	# 1) state: (boolean)
	#     1 => normal behaviour. those steps are called "official" steps
	#     0 => this step is displayed in the assistant, but don't count as a
	#	       step. Usefull for introduction and conclusion for example.
	# 2) mainProc: the main proc :). This proc displays the step.
	# 3) leavingProc: this proc is called when we leave that step, to go to next 
	#     or the previous, or closing, or to go to an other step. This proc is
	#     is called before nextProc or cancelProc, or backProc if they are
	#     called.
	# 4) nextProc: this proc is called just after the next button is pressed.
	#     This proc should not go to the next step, but may be used for saving
	#     configuration.
	# 5) cancelProc: proc called just after pressing the cancel or close button. 
	#     Should not take care of destroying the window.
	# 6) backProc: proc called just after the back button is pressed. This proc
	#     should not go to the previous step, but may be used for freeing smthg.
	# 7) titleText: the text of the title
	# 8) titlePixmap: the skin key referring to the image displayed in the title
	# 9) displayNumber: (boolean) show the number of the current step in the 
	#     title. default is FALSE = 0
	#10) displayFullNumber: (boolean) Display current step and steps in the window's
	#     title : $winname -  Step 4/5 . Override the previous option.

	#All those procedures must have 2 arguments :
	#     assistant : name of the assistant
	#     contentframe : path to the contentframe
	#If you don't need nextProc, or cancelProc or backProc, just set them as ""
#TODO: what about using an array instead of a list to describe a step ?

	#index in the list of steps
	variable steps_l_i

	#the text used as title of the current step
	variable titleText

	#number of "official" steps
	variable stepsNumber
	#list describing their respective number for each step
	#0 is that step has no "official" number
	variable stepNumber_l

	#some frames
	variable titlec
	variable titlef
	variable menuf
	variable buttonf
	variable contentf

	#variable used to know when we can display the total number of steps
	variable allStepsSeen

	#proc called when we click on the finish button at the last step
	variable finishProc

	#list of procs called when we cancel the assistant
	# it's different from the one from the step list since those ones are
	# called on everystep after they are registered
	variable cancelProcs

	option -winname -default "Assistant" -cgetmethod getOption -configuremethod setWinName
	
	option -winwidth -default 650 -cgetmethod getOption -configuremethod resize
	option -winheight -default 550 -cgetmethod getOption -configuremethod resize


	###########################################################################
	#The constructor.
	#    Called when creating the assistant
	constructor {args} {
		#init some vars
		set steps_l [list]
		set steps_l_i 0
		set titleText  "Some Text Here !"
		set stepsNumber 0
		set stepNumber_l [list]
		set finishProc ""
		set allStepsSeen 0
		set cancelProcs [list]

		$self configurelist $args
		
		wm title $win $options(-winname)
		wm geometry $win $options(-winwidth)x$options(-winheight)

		set bodyf $win.bodyf
		set titlef $bodyf.titlef
		set titlec $titlef.titlec
		set buttonf $win.buttonf
		set contentf $bodyf.contentf	
		
		set titlebg [::skin::getKey assistanttitlebg]
		set titleheight [::skin::getKey assistanttitleheight]
		set titlefg [::skin::getKey assistanttitlefg]

		frame $bodyf -bd 1 -background $titlebg
		
		#create title frame and first contents
		frame $titlef -height $titleheight -bd 0 -background $titlebg
		canvas $titlec -height $titleheight -background $titlebg
		
		#set a default text for the title in the canvas that can be changed
		$titlec create text 10 [expr {$titleheight / 2}] -text $titleText \
			-anchor w -fill $titlefg -font bboldf -tag titletext
		set image [::skin::loadPixmap assistant]
		$titlec create image 0 [expr {$titleheight/2}] -image $image -anchor e -tag img
		pack $titlec -fill x
		pack $titlef -side top -fill x
		pack $bodyf -side top -fill both -padx 4 -pady 4 -expand 1
		frame $contentf -padx 1 -pady 1;#these pads make a 1 pixel border
		pack $contentf -side top -fill both -expand 1 
		
		frame $buttonf  -bd 0 
		pack $buttonf  -side top  -fill x -padx 4 -pady 4;#pads keep the stuff a bit away from windowborder
		#add the buttons
		button $buttonf.back -text [trans back] -command [list $self back] \
			-state disabled ; #first step of assistant, back button is disabled
		if {[string length [trans finish]] > [string length [trans next]] } {
			set width [string length [trans finish]]
		} else {
			set width [string length [trans next]]
		}
		button $buttonf.next -text [trans next] -command [list $self next] -state disabled -width $width
		button $buttonf.cancel -text [trans cancel] -command [list $self cancel]
#TODO : maybe a button Help, and/or Defaults
		#pack 'em
		pack $buttonf.next $buttonf.back $buttonf.cancel -padx 10 -side right
		
		bind $win <Configure> [list $self windowResized]

	}

	###########################################################################
	# destructor
	#    Called when closing the assistant
	destructor {
		if { $steps_l != [list] } {
			#leavingProc
			set procToCall [lindex [lindex $steps_l $steps_l_i] 3]
			if { $procToCall != "" } {
				eval $procToCall $self $contentf
			}
			
			#cancelProc
			set procToCall [lindex [lindex $steps_l $steps_l_i] 5]
			if { $procToCall != "" } {
				eval $procToCall $self $contentf
			}
		}
	}

	###########################################################################
	# method resize (option value)
	#    Called by -configure winwidth/winheight
	#    Resize the window
	# Returns nothing
	method resize {option value} {
		if {![string is digit value]} {
			status_log "Assistant: trying to change $option to $value which is not a digit"
			return
		}
		if {[string equal -nocase $option "-winheight"]} {
			set options(-winheight) $value
		} else {
			set options(-winwidth) $value
		}
		wm geometry $win $options(-winwidth)x$options(-winheight)
	}

	###########################################################################
	# method windowResized()
	#    Called when the window is resized and takes care of displaying 
	#    objects in a right way
	# Returns nothing
	method windowResized {} {
#TODO : add smthg so that it refreshes only when user stops resizing
		#kind of "after 200 ....."
		set newwidth [winfo width $contentf]
		set xAmount [expr {$newwidth - $options(-winwidth)}]
		$titlec move img $xAmount 0
		set options(-winwidth) $newwidth
		set options(-winheight) [winfo height $self]
	}

	###########################################################################
	# method getOption (option)
	#    Called with $self -cget $option in order to get the value of that 
	#    option.
	# Argument:
	#    - option => the considered option
	# Returns the value of the option
	method getOption {option} {
		return $options($option)
	}

	###########################################################################
	# method setOption (option, value)
	#    Called with $self -configure $option $value to set the value to the 
	#    refered option.
	# Arguments:
	#    - option => the considered option
	#    - value => the value
	# Returns nothing
	method setOption {option value} {
		set options($option) $value
	}

	###########################################################################
	# method setWinName (option, value)
	#    Called with $self -configure -winname $value to change the name of the 
	#    window.
	# Arguments:
	#    - option => must be -winname
	#    - value => the value
	# Returns nothing
	method setWinName {option value} {
		if {$value != ""} {
			set options(-winname) $value
			wm title $win $options(-winname)
		}
	}

	###########################################################################
	# method getContentFrame()
	#    Return the path of the ContentFrame
	method getContentFrame {} {
		return $contentf
	}

	###########################################################################
	# method clearContentFrame()
	#    Returns the path of the ContentFrame once cleared
	method clearContentFrame {} {
		if {[winfo exists $contentf]} { destroy $contentf }
		frame $contentf -padx 1 -pady 1;#these pads make a 1 pixel border
		pack $contentf -side top -fill both -expand 1
		return $contentf
	}
	
	###########################################################################
	# method getName ()
	#    Returns the name of the current step, or "" if there's no step.
	method getName {} {
		set ret ""
		if {$steps_l != [list] } {
			set ret [lindex [lindex $steps_l $steps_l_i] 0] 
		}
		return $ret
	}

	###########################################################################
	# method setFinishProc (proc)
	#    set the proc called when we finish the assistant
	# Argument:
	#    - proc : name of the proc called when we finish the assistant
	# Returns nothing
	method setFinishProc {proc} {
		set finishProc $proc
	}
	
	###########################################################################
	# method getFinishProc ()
	#    Returns the name of the finish proc
	method getFinishProc {} {
		return $finishProc
	}

	###########################################################################
	# method setTitleText (text)
	#    Set the specified text as the new title. It shouldn't take care of
	#    displaying the steps.
	# Argument:
	#    - text : text of the new title
	# Returns nothing
	method setTitleText {text} {
		if { $titleText != $text } {
			set titleText $text
			$self updateTitle
		}
	}

	###########################################################################
	# method updateTitle
	#    Update the canvas titlec
	# Returns nothing
	method updateTitle {} {
		set newtitletext $titleText
		set step [lindex $steps_l $steps_l_i]
		set currentStep [lindex $stepNumber_l $steps_l_i]
		if {[lindex $step 1] == 1 && $currentStep != 0} {
			if {[lindex $step 10] == 1 && $allStepsSeen} {
				set newtitletext "$titleText - [trans step] $currentStep/$stepsNumber"
			} elseif {[lindex $step 9] == 1} {
				set newtitletext "$titleText - [trans step] $currentStep"
			}
		}
		$titlec delete titletext
		$titlec create text 10 [expr {[::skin::getKey assistanttitleheight] / 2}] -text $newtitletext \
			-anchor w -fill [::skin::getKey assistanttitlefg] -font bboldf -tag titletext
		set image [::skin::loadPixmap [lindex $step 8]]
		if { $image == "" } {
			set image [::skin::loadPixmap assistant]
		}
		$titlec delete img
		$titlec create image [expr {$options(-winwidth) - [image width $image]/2}] \
			[expr {[::skin::getKey assistanttitleheight]/2}] -image $image -anchor e -tag img
	}


	###########################################################################
	# method addCancelProc (name, proc)
	#    Add a proc called when the assistant is canceled
	# Arguments:
	#    - name => name used to refer to that proc if we want to remove it
	#    - procedure => the proc called when the assistant is canceld
	#        this proc should have 2 arguments : assistant and contentFrame
	# Returns
	#    1 if proc is added
	#    0 if not
	method addCancelProc {name procedure} {
		set done 1
		#search if the name is not already registered
		foreach proced $cancelProcs {
			if {[string equal $name [lindex $proced 0]]} {
				set done 0
				break
			}
		}
		if {$done == 1} {
			lappend cancelProcs [list $name $procedure]
		} else {
			status_log "Assistant: while calling addCancelProc, a proc identified by $name is already registered"
		}
		return $done
	}
	
	###########################################################################
	# method removeCancelProc (name)
	#    Remove the proc called by $name
	# Argument
	#    - name => name of the proc we want to remove from the Cancel procs
	# Returns
	#    1 if proc is removed
	#    0 if not
	method removeCancelProc {name} {
		set err 1
		set i 0
		#search the name in the list
		foreach proc $cancelProcs {
			if {[string equal $name [lindex $proc 0]]} {
				set err 0
				break
			} else {
				incr i
			}
		}
		if {err == 1} { 
			set $cancelProcs [lreplace $cancelProcs $i $i]
		} else {
			status_log "Assistant: while calling removeCancelProc, the proc identified by $name was not found"
		}
		return $err
	}

	###########################################################################
	# method cancel
	#    Called when the cancel button is pressed
	# Returns nothing
	method cancel {} {
		foreach procedure $cancelProcs {
			eval [lindex $procedure 1] $self $contentf
		}
		#calling leaving proc and cancelProc is done through the destructor
		destroy $self
	}

	###########################################################################
	# method back
	#    Called when the back button is pressed
	# Returns nothing
	method back {} {

		#leavingProc
		set procToCall [lindex [lindex $steps_l $steps_l_i] 3]
		if { $procToCall != "" } {
			eval $procToCall $self $contentf
		}
		
		#backProc
		set procToCall [lindex [lindex $steps_l $steps_l_i] 6]
		if { $procToCall != "" } {
			eval $procToCall $self $contentf
		}

		incr steps_l_i -1

		set titleText [lindex [lindex $steps_l $steps_l_i] 7]
		set currentStep [lindex $stepNumber_l $steps_l_i]
		$self updateTitle
		
		if { $steps_l_i == 0 } {
			# going to first step
			$buttonf.back configure -state disabled
		} else {
			$buttonf.back configure -state normal
		}
		$buttonf.next configure -state normal
		#remove the finish button
		$buttonf.next configure -text [trans next] -command [list $self next]


		#calling mainProc
		eval [lindex [lindex $steps_l $steps_l_i] 2] $self [$self clearContentFrame]
	}
	
	###########################################################################
	# method next
	#    Called when the next button is pressed
	# Returns nothing
	method next {} {

		#leavingProc
		set procToCall [lindex [lindex $steps_l $steps_l_i] 3]
		if { $procToCall != "" } {
			eval $procToCall $self $contentf
		}
		
		#nextProc
		set procToCall [lindex [lindex $steps_l $steps_l_i] 4]
		if { $procToCall != "" } {
			eval $procToCall $self $contentf
		}

		incr steps_l_i

		set titleText [lindex [lindex $steps_l $steps_l_i] 7]
		set currentStep [lindex $stepNumber_l $steps_l_i]
		$self updateTitle
		
		if { $steps_l_i == [expr {[llength $steps_l] - 1}] } {
			# going to last step
			$buttonf.next configure -state normal
			#add the finish button
			$buttonf.next configure -text [trans finish] -command [list $self finish]
			#we have seen all steps
			set allStepsSeen 1
		} else {
			$buttonf.next configure -state normal
			$buttonf.next configure -text [trans next] -command [list $self next]
		}
		$buttonf.back configure -state normal
		
		#calling mainProc
		eval [lindex [lindex $steps_l $steps_l_i] 2] $self [$self clearContentFrame]
	}
	
	###########################################################################
	# method finish
	#    Called when the finish button is pressed
	#    This method takes care of destroying the assistant
	# Returns nothing
	method finish {} {
		if {$finishProc != ""} {
			#calling the finish proc
			eval $finishProc $self [$self clearContentFrame]
			destroy $self
		}
	}
	
	###########################################################################
	# method enableNextButton()
	#    Make the Next Button active
	method enableNextButton {} {
		$buttonf.next configure -state normal
		$buttonf.next configure -text [trans next] -command [list $self next]
	}

	###########################################################################
	# method disableNextButton()
	#    Make the Next Button disabled
	method disableNextButton {} {
		$buttonf.next configure -state disabled
		$buttonf.next configure -text [trans next] -command [list $self next]

	}

	###########################################################################
	# method goToStepId (index)
	#    Display the step given by the index
	# Argument:
	#    - index => index refering to the step in the list of steps
	# Returns nothing
	method goToStepId { index } {
		#Checking whether the index given is valid
		if { $index < [llength $steps_l] && $index >= 0} {
			set steps_l_i $index
			set titleText [lindex [lindex $steps_l $steps_l_i] 7]
			set currentStep [lindex $stepNumber_l $steps_l_i]
			$self updateTitle
			if { $steps_l_i == 0 } {
				# going to first step
				$buttonf.back configure -state disabled
			} else {
				$buttonf.back configure -state normal
			}
			if {$steps_l_i == [expr {[llength $steps_l] - 1}] } {
				# going to last step
				$buttonf.next configure -state normal
				#add the finish button
				$buttonf.next configure -text [trans finish] -command [list $self finish]
				#we have seen all steps
				set allStepsSeen 1
			} else {
				$buttonf.next configure -state normal
				#remove the finish button
				$buttonf.next configure -text [trans next] -command [list $self next]
			}
			#calling leavingProc
			set leavingProc [lindex [lindex $steps_l $steps_l_i] 3]
			if { $leavingProc != "" } {
				eval $leavingProc $self $contentf
			}
			#calling mainProc
			eval [lindex [lindex $steps_l $steps_l_i] 2] $self [$self clearContentFrame]
		} else {
			status_log "Assistant: trying to go to step $index, which is invalid" red
		}
	}
	
	###########################################################################
	# method goToStep (Name)
	#    Go to step given by it's name
	# Argument
	#    - Name => name of the wanted step
	# Returns nothing
	method goToStep {Name} {
		$self goToStepId [$self searchStep $Name]
	}

	###########################################################################
	# method clearSteps()
	#    Remove all the steps and display an empty assistant
	# Returns nothing
	method clearSteps {} {
		$self clearContentFrame
		set steps_l [list]
		set steps_l_i 0
		set stepsNumber 0
		set stepNumber_l [list]
		$buttonf.back configure -state disabled
		$buttonf.next configure -state disabled
	}
	
	###########################################################################
	# method addStepEnd (Step)
	#    Add a step to the assistant
	# Arguments:
	#    - Step => (list) contains the ?? elements describing a step
	# Return:
	#     nothing  
	method addStepEnd { Step } {
		#don't add the step 2 times
		if {[string equal [lindex $Step 0] [lindex [lindex $steps_l [expr {$stepsNumber - 1}]] 0]]} {
			$self removeStepId [expr {$stepsNumber - 1}]
		}
		lappend steps_l $Step
		if {[lindex $Step 1] == 1} {
			#increase the number of "official" steps
			incr stepsNumber
			lappend stepNumber_l $stepsNumber
		} else {
			lappend stepNumber_l 0
		}
		#We're adding the first step, that's why we display it
		if {$steps_l == [list $Step]} {
			$self goToStepId 0
		} else {
			$self enableNextButton
		}
		#since we're adding a step at the end, we can't have seen all steps
		set allStepsSeen 0
	}
	
	###########################################################################
	# method removeStepId (id)
	#    Remove the given step
	# Argument:
	#    - id (int) => index of the step in the list of steps
	# Returns nothing
	method removeStepId { id } {
		if { $id != -1 } {
			#changing stepNumber_l
			set stepNumber_l [lreplace $stepNumber_l $id $id]
			if {[lindex [lindex $steps_l $id] 1]} {
				#we also have to do change stepNumber_l
				for {set i $id} {$i < [llength $stepNumber_l]} {incr i} {
					set value [lindex $stepNumber_l $i]
						if { $value != 0 } {
							incr value -1
							set stepNumber_l [lreplace $stepNumber_l $i $i $value]
						}
				}
				#decreasing the number of "official" steps
				incr stepsNumber -1
			}

			#now, remove it for real
			set steps_l [lreplace $steps_l $id $id]
			
			if { $id < $steps_l_i } {
				incr steps_l_i -1
			} elseif { $id == $steps_l_i } {
				if { $id != 1 } {
					incr steps_l_i -1
				}
				GoToStepId $steps_l_i
			}
		}
	}

	###########################################################################
	# method removeStep (Name)
	#    Remove the step called Name
	# Argument
	#    - Name => name of the wanted step
	# Returns nothing
	method removeStep {Name} {
		$self removeStepId [$self searchStep $Name]
	}

	###########################################################################
	# method insertStep (Step, id)
	#    Insert the given step after id
	# Arguments
	#    - Step (list) => contains the ?? elements describing a step
	#    - id (int) => index of the step in the list of steps
	#					The step will be inserted with that number (after id-1)
	# Returns nothing.
	method insertStep {Step id} {
		#don't insert the step 2 times
		if {[string equal [lindex $Step 0] [lindex [lindex $steps_l $id] 0]]} {
			$self removeStepId $id
		}

		#changing stepNumber_l
		if {[lindex $Step 1] == 1} {
			#searching the number for that step
			set stepNumber 1
			for {set i [expr {$id-1}]} {$i >= 0 } {incr i -1} {
				if { [lindex $stepNumber_l $i] != 0} {
					set stepNumber [expr {[lindex $stepNumber_l $i] +1}]
					break
				}
			}
			set stepNumber_l [linsert $stepNumber_l $id $stepNumber]
			#we also have to do change stepNumber_l
			for {set i [expr {$id+1}]} {$i < [llength $stepNumber_l]} {incr i} {
				set value [lindex $stepNumber_l $i]
					if { $value != 0 } {
						incr value
						set stepNumber_l [lreplace $stepNumber_l $i $i $value]
					}
			}
			#increasing the number of "official" steps
			incr stepsNumber
		} else {
			set stepNumber_l [linsert $stepNumber_l $id 0]
		}

		#now, insert it for real
		set steps_l [linsert $steps_l $id $Step]
	}

	###########################################################################
	# method insertStepBefore (Step, Name)
	#    Insert a step before the one called Name
	# Arguments:
	#    - Step (list) => contains the ?? elements describing a step
	#    - Name => name of the step which would be after the step we're adding
	#       If there's no step called by Name, insert on head.
	# Returns nothing
	method insertStepBefore {Step Name} {
		set id [$self searchStep $Name]
		if {$id == -1} {
			#insert on head of the list
			set id 0
		}
		$self insertStep $Step $id
	}
	
	###########################################################################
	# method insertStepAfter (Step, Name)
	#    Insert a step after the one called Name
	# Arguments:
	#    - Step (list) => contains the ?? elements describing a step
	#    - Name => name of the step which would be just before the step we're adding
	#       If there's no step called by Name, insert on queue.
	# Returns nothing
	method insertStepAfter {Step Name} {
		set id [expr {[$self searchStep $Name] + 1 }]
		if { $id == 0} {
			#inserting the step as the last one
			set id [llength $steps_l]
		}
		$self insertStep $Step $id
	}

	###########################################################################
	# method searchStep (Name)
	#    Search the Step called Name
	# Argument:
	#    - Name => name of the step we're searching
	# Returns
	#   the index of the step in the list of steps
	#	-1 if the step is not found
	method searchStep {Name} {
		set id -1
		set i -1
		foreach step $steps_l {
			incr i
			if {[string equal [lindex $step 0] $Name]} {
				set id $i
				break
			}
		}
		if {$id == -1} {
			status_log "Assistant: no step called $Name"
		}
		return $id
	}

	###########################################################################
	# method modifyStep (id, partName, newInfo)
	#    Change the value of one of the informations that describe a step
	# Arguments:
	#    - id (int) => index of the step in the list of steps
	#    - partName (string) => name of the part of the step to change
	#    - newInfo => the new value given to partName
	# Returns nothing
	method modifyStepId {id partName newInfo} {
		switch $partName {
		  "name" {set i 0}
		  "state" {set i 1}
		  "mainProc" {set i 2}
		  "leavingProc" {set i 3}
		  "nextProc" {set i 4}
		  "cancelProc" {set i 5}
		  "backProc" {set i 6}
		  "titleText" {set i 7}
		  "titlePixmap" {set i 8}
		  "displayNumber" {set i 9}
		  "displayFullNumber" {set i 10}
		  default {set i -1}
		}

		if {$i != -1 && $id != -1} {
			set step [lindex $steps_l $id]
			set step [lreplace $step $i $i $newInfo]
			set steps_l [lreplace $steps_l $id $id $step]
			
			if { $i == 1 } {
			#changing a state
				#/!\ roughly same code in method insertStep
				if { $newInfo == 1 && [lindex $stepNumber_l $id] == 0} {
					#searching the number for that step
					set stepNumber 1
					for {set i $id} {$i >= 0 } {incr i -1} {
						if { [lindex $stepNumber_l $i] != 0} {
							set stepNumber [expr {[lindex $stepNumber_l $i]+1}]
							break
						}
					}
					set stepNumber_l [lreplace $stepNumber_l $id $id $stepNumber]

					#increasing the number of "official" step
					for {set j [expr {$id+1}]} {$j < [llength $stepNumber_l]} {incr j} {
						set value [lindex $stepNumber_l $j]
							if { $value != 0 } {
								incr value
								set stepNumber_l [lreplace $stepNumber_l $j $j $value]
							}
					}
					#increasing the number of "official" steps
					incr stepsNumber
				} elseif {$newInfo == 0 && [lindex $stepNumber_l $id] > 0} {
					set stepNumber_l [lreplace $stepNumber_l $id $id 0]
					#decreasing the number of "official" step
					for {set j $id} {$j < [llength $stepNumber_l]} {incr j} {
						set value [lindex $stepNumber_l $j]
							if { $value != 0 } {
								incr value -1
								set stepNumber_l [lreplace $stepNumber_l $j $j $value]
							}
					}
					#increasing the number of "official" steps
					incr stepsNumber -1
				}

				$self updateTitle
			} elseif {$id == $steps_l_i && $i >= 7} {
			#changing the current titleText or titlePixmap or displayNumber or displayFullNumber
				$self updateTitle
			}
		} elseif {$i == -1} {
				status_log "Assistant: invalid partName $partName while calling modifyStepId\nCan only be: name, state, mainProc, leavingProc, nextProc, cancelProc, backProc, titleText, titlePixmap, displayNumber, displayFullNumber"
		}
	}

	###########################################################################
	# method modifyStep (Name, partName, newInfo)
	#    Modify the $partName of the step called $Name with $newInfo
	# Arguments:
	#    - Name (string) => name of the step we want to change
	#    - partName (string) => name of the part of the step to change
	#    - newInfo => the new value given to partName
	# Returns nothing
	method modifyStep {Name partName newInfo} {
		set id [$self searchStep $Name]
		$self modifyStepId $id $partName $newInfo
	}
#end of snit::widget assistant
}

#Skin-things added:
#* "Yes" emblem
#* "No" emblem
#* Webcam-icon

###################################################################################################
#\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\#
###################################################################################################

namespace eval ::AVAssistant {

	variable video_configured
	variable audio_configured
		
	set video_configured 0
	set audio_configured 0

	######################################################################################
	#Procedure that starts the assistant.  It creates the window's framework etc         #
	######################################################################################
	proc AVAssistant {} {

		#set the name of the window
		set assistant [assistant create .%AUTO% -winname [trans assistanttitle]]
		#introduction
		set Step [list "Step0" 0 ::AVAssistant::Step0 "" "" "" "" [trans assistantstarting] "" 0 0]
		$assistant addStepEnd $Step

		#check extensions for video
		set Step [list "Step0W" 0 ::AVAssistant::Step0W "" "" "" "" [trans checkingextensions] assistant_webcam 0 0]
		$assistant addStepEnd $Step

		#here, we'll insert some steps

		#check for audio extensions, and configure it
		set Step [list "Step1A" 1 ::AVAssistant::Step1A ::AVAssistant::stopSound "" "" ""  [trans configuringaudio] assistant_audio 1 1]
		$assistant addStepEnd $Step

		#check for audio extensions, and configure it
		set Step [list "StepFarsight" 1 ::AVAssistant::StepFarsight "" "" "" ""  "Farsight" assistant_audio 1 1]
		$assistant addStepEnd $Step

		#Finishing, greetings
		set Step [list "LastStep" 0 ::AVAssistant::LastStep "" "" "" "" [trans congrats] "" 0 0]
		$assistant addStepEnd $Step

	}

	################################
	################################
	##                            ##
	##   CODE TO FILL THE PAGES:  ##
	##                            ##
	################################
	################################
	
	######################################################################################
	# Step 0 (intro-page)                                                                #
	######################################################################################	
	proc Step0 {assistant contentf} {
		
		#add the Content
		label $contentf.text -justify left -font bplainf -text [trans assistantwelcome]
		#pack it
		pack $contentf.text -padx 20 -pady 20 -side left -fill both -expand 1
		#to get a nice wrapping
		bind $contentf.text <Configure> [list %W configure -wraplength %w]
	}


	######################################################################################
	# Step 0 Video: check for extensions for Webcam setup                                #
	######################################################################################	
	proc Step0W {assistant contentf} {

		##Webcam extension check##
		if {[::CAMGUI::ExtensionLoaded]} {
			set ::AVAssistant::infoarray(wcextloaded) 1
		} else {
			set ::AVAssistant::infoarray(wcextloaded) 0
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
		} else {
			set ::AVAssistant::infoarray(capextloaded) 0
		}
		
		set camPresent [::CAMGUI::camPresent]

		if {$::AVAssistant::infoarray(capextloaded) && $::AVAssistant::infoarray(wcextloaded) && $camPresent == 1} {
			#ok, we can add steps to configure video settings
			$assistant modifyStep "Step0W" state 1
			$assistant modifyStep "Step0W" displayNumber 1
			$assistant modifyStep "Step0W" displayFullNumber 1
			if {[OnDarwin]} {
				#webcam device + finetune picture
				$assistant modifyStep "Step0W" titleText [trans setupcamfinetune] 
				$contentf configure -padx 10 -pady 10
				button $contentf.button -text [trans changevideosettings] -command "::CAMGUI::ChooseDeviceMac"
				pack $contentf.button
				
				# There is no easy way to know if a cam is available OnMac so set video configured to true in all cases..
				variable video_configured
				set video_configured 1
			} elseif {[OnLinux]} {
				#OnLinux,
				#webcam device + channel
				
				#Finetune picture
				set Step [list "Step2W" 1 ::AVAssistant::Step2WLinux ::AVAssistant::stopPreviewGrabbing "" "" "" [trans finetunesettings] assistant_webcam 1 1]
				$assistant insertStepAfter $Step "Step0W"

				variable video_configured
				set video_configured 0

				::AVAssistant::Step1WLinux $assistant $contentf
			} elseif {[OnWin]} {
				variable video_configured
				set video_configured 1
				::AVAssistant::Step1WWin $assistant $contentf
			}
		} else {
			#we won't be able to configure the video settings

			$contentf configure -padx 20 -pady 35
		
			#First part: the webcam extension
			if {!$::AVAssistant::infoarray(wcextloaded)} {
				label $contentf.wcextlabel -justify left -anchor nw -font bboldf \
					-text [trans webcamextchecking]\
					-image [::skin::loadPixmap no-emblem] -compound right

				label $contentf.wcextwarn -justify left -text [trans webcamextwarn]
				label $contentf.wcextwarnurl -justify left -text "$::weburl/webcamfaq.php" -fg blue
				pack $contentf.wcextlabel
				pack $contentf.wcextwarn 
				pack $contentf.wcextwarnurl

				bind $contentf.wcextwarnurl <Enter> [list %W configure -font sunderf]
				bind $contentf.wcextwarnurl <Leave> [list %W configure -font splainf]
				bind $contentf.wcextwarnurl <ButtonRelease> [list launch_browser "$::weburl/webcamfaq.php"]
				#to get a nice wrapping
				bind $contentf.wcextwarn <Configure> [list %W configure -wraplength %w]
			}

			#Second part: the capture extension
			if {!$::AVAssistant::infoarray(capextloaded)} {
				label $contentf.capextlabel -justify left -anchor nw -font bboldf \
					-text [trans checkingcapext $capextname]\
					-image [::skin::loadPixmap no-emblem] -compound right
				label $contentf.capextwarn -justify left -text [trans capturewarn]
				label $contentf.capextwarnurl -justify left -text "$::weburl/webcamfaq.php" -fg blue

				pack $contentf.capextlabel -pady [list 20 0]

				pack $contentf.capextwarn
				pack $contentf.capextwarnurl
				bind $contentf.capextwarnurl <Enter> [list %W configure -font sunderf]
				bind $contentf.capextwarnurl <Leave> [list %W configure -font splainf]
				bind $contentf.capextwarnurl <ButtonRelease> [list launch_browser "$::weburl/webcamfaq.php"]
				#to get a nice wrapping
				bind $contentf.capextwarn <Configure> [list %W configure -wraplength %w]
			}

			#Third part: we can't find a cam
			if {$::AVAssistant::infoarray(capextloaded) && $::AVAssistant::infoarray(wcextloaded) && !$camPresent } {
				label $contentf.nocamlabel -justify left -anchor nw -font bboldf \
					-text [trans checkingcam]\
					-image [::skin::loadPixmap no-emblem] -compound right
				label $contentf.nocamwarn -justify left -text [trans nocamwarn]
				label $contentf.nocamwarnurl -justify left -text "$::weburl/webcamfaq.php" -fg blue

				pack $contentf.nocamlabel -pady [list 20 0]

				pack $contentf.nocamwarn
				pack $contentf.nocamwarnurl
				bind $contentf.nocamwarnurl <Enter> [list %W configure -font sunderf]
				bind $contentf.nocamwarnurl <Leave> [list %W configure -font splainf]
				bind $contentf.nocamwarnurl <ButtonRelease> [list launch_browser "$::weburl/webcamfaq.php"]
				#to get a nice wrapping
				bind $contentf.nocamwarn <Configure> [list %W configure -wraplength %w]
			}

		}
	}



	######################################################################################
	# Step 1 Video for Linux:  Set device/channel                                        #
	######################################################################################	
	proc Step1WLinux {assistant contentf} {
		#extensions are present, we can change some settings	
		$assistant modifyStep "Step0W" titleText [trans setupcam]
		$assistant modifyStep "Step0W" leavingProc ::AVAssistant::stopPreviewGrabbing 

		#we should be able to alter this vars in other procs
		variable chanswidget
		variable previmc
		variable selecteddevice
		variable channels
		variable previmg
		variable lowrescam

		##Here comes the content:##

		#build the GUI framework (same for windows/linux)
			
# +-------------------------+
# |       descrition        |
# |+----------+ +---------+ |--innerframe ($contenf)
# ||          | |         | |
# ||          | |         | |
# ||          | |         |----rightframe (a canvas $rightframe))
# ||          | |         | |
# ||          | |         | |
# ||          |-|---------|----leftframe
# |+----------+ +---------+ |
# +-------------------------+

		label $contentf.desc -justify left -text [trans assistantselectcam]
		pack $contentf.desc -pady 20 
		#to get a nice wrapping
		bind $contentf.desc <Configure> [list %W configure -wraplength %w]

		if {![info exists lowrescam]} {
			set lowrescam [::config::getKey lowrescam]
		}
		checkbutton $contentf.lowrescam -text "[trans lowrescam]" -font sboldf -variable \
			::AVAssistant::lowrescam -onvalue 1 -offvalue 0
		pack $contentf.lowrescam -pady 10
		
		#create the left frame (for the comboboxes)
		set leftframe $contentf.left
		frame $leftframe -bd 0
		pack $leftframe -side left -padx 10

		#create the 'rightframe' canvas where the preview-image will be shown
		set rightframe $contentf.right

		if { $lowrescam == 1 } {
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

		#first clear the grabber var
		set ::CAMGUI::webcam_preview ""
		
		#First line, device-chooser title
		label $leftframe.devstxt -text [trans choosedevice]
		pack $leftframe.devstxt -side top
		
		#create and pack the devices-combobox
		combobox::combobox $leftframe.devs -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf -exportselection true -editable false -command [list ::AVAssistant::FillChannelsLinux]
		
		#make sure the devs-combobox is empty first
		$leftframe.devs list delete 0 end
		
		#get the already set device from the config (if there is one set)
		if {![info exists selecteddevice]} {
			set setdev [lindex [split [::config::getKey "webcamDevice"] ":"] 0]
		} else { 
			set setdev $selecteddevice
		}
		#set the count to see which nr this device has in the list on -1 to begin,
		# so it becomes 0 if it's the first element in the list ([lindex $foo 0])
		set count 0
		#set a start-value for the device's nr
		set setdevnr 0
		
		#insert the device-names in the widget
		foreach device [::Capture::ListDevices] {
			set dev [lindex $device 0]
			set name [lindex $device 1]
			
			#it will allways set the last one, which is a bit weird to the
			# user though if he has like /dev/video0 that come both as V4L 
			# and V4L2 device
			#store which nr the setdev has in the combobox
			if { $dev == $setdev} {
				set setdevnr $count
			}
			incr count
			
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
		label $leftframe.chanstxt -text "\n\n[trans choosechannel]:"
		pack $leftframe.chanstxt -side top
		
		#create and pack the chans-combobox
		set chanswidget $leftframe.chans
		combobox::combobox $leftframe.chans -highlightthickness 0 -width 22 -font splainf -exportselection true \
		    -command [list ::AVAssistant::StartPreviewLinuxDelayed] -editable false -bg #FFFFFF

		pack $leftframe.chans -side top 
		
		#Select the device if in the combobox (won't select anything if -1)
		catch {$leftframe.devs select $setdevnr}

		#now, configure the checkbutton in order to change the size of the preview when needed
		$contentf.lowrescam configure -command [list ::AVAssistant::StartPreviewLinux $leftframe.chans [$leftframe.chans get]]
		#end the Step1WLinux proc
	}


	######################################################################################
	# Step 1 Video Linux - Auxilary procs                                                #
	######################################################################################	
	###
	# Fills the Channels on Linux
	proc FillChannelsLinux {devswidget value} {
		variable chanswidget
		variable selecteddevice
		variable selecteddevicename
		variable selectedchannel
		variable channels
		
		if { $value == "" } {
			status_log "No device selected; CAN'T BE POSSIBLE ?!?"
		} else {
	
			#get the nr of the selected device
			set devnr [lsearch [$devswidget list get 0 end] $value]
			#get that device out of the list and the first element is the device itself ([list /dev/foo "name"])
			set selecteddevice [lindex [lindex [::Capture::ListDevices] $devnr] 0]
			#name is used at the end of the assistant to tell the user what he choosed
			set selecteddevicename $value

			if { [catch {set channels [::Capture::ListChannels $selecteddevice]} errormsg] } {
				status_log "Webcam-Assistant: Couldn't list chans for device $selecteddevice: $errormsg"
				return
			}

			#make sure the chanswidget is empty before filling it
			$chanswidget list delete 0 end

			#search the already set channel (cfr devices)	
			if {![info exists selectedchannel]} {		
				set setchan [lindex [split [::config::getKey "webcamDevice"] ":"] 1]
			} else {
				set setchan $selectedchannel
			}
			

			set count 0
			set setchannr 0

			foreach channel $channels {
				set chan [lindex $channel 0];#this is a nr
				set channame [lindex $channel 1]

				if { $chan == $setchan} {
					set setchannr $count
				}

				incr count
				$chanswidget list insert end $channame
			}
			#select the already set chan if possible
			catch {$chanswidget select $setchannr}
		}
	}

	proc StartPreviewLinuxDelayed {chanswidget value} {
		after 0 [list ::AVAssistant::StartPreviewLinux $chanswidget $value]
	}

	###
	# Start the Preview on Linux
	proc StartPreviewLinux {chanswidget value} {
		variable selecteddevice
		variable selectedchannel
		variable selectedchannelname
		variable channels
		variable previmc
		variable previmg
		variable lowrescam

		if {![winfo exists $chanswidget] } {
			status_log "StartPreviewLinux : Assistant destroyed, returning"
			return
		}

		if { $value == "" } {
			status_log "No channel selected; IS THIS POSSIBLE ?"
		} else {

			#get the nr of the selected channel
			set channr [lsearch [$chanswidget list get 0 end] $value]
			#get that channel out of the list and the first element is the chan itself ([list 0 "television"])
			set selectedchannel [lindex [lindex $channels $channr] 0]
			#name is used at the end of the assistant to tell the user what he choosed
			set selectedchannelname $value
			status_log "Will preview: $selecteddevice on channel $selectedchannel"
			
			#close the device if open
			::AVAssistant::stopPreviewGrabbing 0 0
	
			if { $lowrescam } {
				set cam_res "QSIF"
				set camwidth 160
				set camheight 120
			} else {
				set cam_res "SIF"
				set camwidth 320
				set camheight 240
			}

			$previmc configure -width $camwidth -height $camheight

			if { [catch {set ::CAMGUI::webcam_preview [::Capture::Open $selecteddevice $selectedchannel $cam_res]} errormsg] } {
				status_log "problem opening device: $errormsg"
				return
			}

			set previmg [image create photo [TmpImgName]]

			$previmc create image 0 0 -image $previmg -anchor nw 

			$previmc create text 10 10 -anchor nw -font bboldf -text "[trans preview]: $selecteddevice:$selectedchannel" -fill #FFFFFF -anchor nw -tag device

			after 3000 "catch { $previmc delete device }"

			#put the border-pic on top
			$previmc raise border
			setPic $::CAMGUI::webcam_preview
			
			set semaphore ::CAMGUI::sem_$::CAMGUI::webcam_preview
			set $semaphore 0
			while { [::Capture::IsValid $::CAMGUI::webcam_preview] && [ImageExists $previmg] } {
				if {[catch {::Capture::Grab $::CAMGUI::webcam_preview $previmg} res ]} {
					status_log "Problem grabbing from the device:\n\t \"$res\""
					set errorheight [expr {$camheight-25}]
					$previmc create text 5 $errorheight -anchor nw -font bboldf -text "$res" -fill #FF0000 -anchor nw -tag errmsg
					after 3000 "catch { $previmc delete errmsg }"
				}
				after 100 [list incr $semaphore]
				tkwait variable $semaphore
			}
		}
	}

	###
	# Stop the grabber
	proc stopPreviewGrabbing {assistant contentf} {
		variable previmg
		
		if { [info exists ::CAMGUI::webcam_preview]} {
			if { [::Capture::IsValid $::CAMGUI::webcam_preview] } {
				::Capture::Close $::CAMGUI::webcam_preview
			}
		}
		catch {image delete $previmg}
		status_log "Webcam-Assistant: Stopped grabbing"
	}


	###
	# Set the picture settings
	proc setPic { grabber } {
		variable selecteddevice
		variable selectedchannel

		variable brightness
		variable contrast
		variable hue
		variable color

		#Then, if there are valid settings in our config, overwrite the values with these
		set colorsettings [split [::config::getKey "webcam$selecteddevice:$selectedchannel"] ":"]
		set set_b [lindex $colorsettings 0]
		set set_c [lindex $colorsettings 1]
		set set_h [lindex $colorsettings 2]
		set set_co [lindex $colorsettings 3]
		
		if {![info exists brightness] && [string is integer -strict $set_b]} {
			set brightness $set_b
		}
		if {![info exists contrast] && [string is integer -strict $set_c]} {
			set contrast $set_c
		}
		if {![info exists hue] && [string is integer -strict $set_h]} {
			set hue $set_h
		}
		if {![info exists color] && [string is integer -strict $set_co]} {
			set color $set_co
		}
		
		#Set them
		if {[info exists brightness]} {
			::Capture::SetBrightness $grabber $brightness
		}
		if {[info exists contrast]} {
			::Capture::SetContrast $grabber $contrast
		}
		if {[info exists hue]} {
			::Capture::SetHue $grabber $hue
		}
		if {[info exists color]} {
			::Capture::SetColour $grabber $color
		}
	}


	######################################################################################
	# Step 2 Video Linux:  Finetune picture settings                                     #
	######################################################################################	
	proc Step2WLinux {assistant contentf} {
		variable selecteddevice
		variable selectedchannel

		variable brightness
		variable contrast
		variable hue
		variable color
		variable lowrescam

		$contentf configure -padx 10 -pady 10

		label $contentf.desc -justify left -text [trans assistantfinetunepic] 
		pack $contentf.desc -pady 10
		#to get a nice wrapping
		bind $contentf.desc <Configure> [list %W configure -wraplength %w]

		#create the left frame (for the comboboxes)
		set leftframe $contentf.left
		#frame $leftframe -bd 0
		#pack $leftframe -side left -padx 10

		if { $lowrescam } {
			set camwidth 160
			set camheight 120
			set cam_res "QSIF"
		} else {
			set camwidth 320
			set camheight 240
			set cam_res "SIF"
		}

		#create the 'rightframe' canvas where the preview-image will be shown
		set rightframe $contentf.right
		#this is a canvas so we gcan have a border and put some OSD-like text on it too
		canvas $rightframe -background #000000 -width $camwidth -height $camheight -bd 0
		pack $rightframe -side right -padx 10

		#draw the border image that will be layed ON the preview-img
		$rightframe create image 0 0 -image [::skin::loadPixmap camempty] -anchor nw -tag border
		#give the canvas a clear name
		set previmc $rightframe

		#close the device if open
		if { [info exists ::CAMGUI::webcam_preview] && [::Capture::IsValid $::CAMGUI::webcam_preview] } {
			::Capture::Close $::CAMGUI::webcam_preview
		}

		if { [catch {set ::CAMGUI::webcam_preview [::Capture::Open $selecteddevice $selectedchannel $cam_res]} errormsg] } {
			status_log "problem opening device: $errormsg"
			return
		}

		set previmg [image create photo [TmpImgName]]
					
		$previmc create image 0 0 -image $previmg -anchor nw 
		$previmc create text 10 10 -anchor nw -font bboldf -text "[trans preview]: $selecteddevice:$selectedchannel" -fill #FFFFFF -anchor nw -tag device

		after 3000 "catch { $previmc delete device }"

		#put the border-pic on top
		$previmc raise border

		#First set the values to the one the cam is on when we start preview
		set brightness [::Capture::GetBrightness $::CAMGUI::webcam_preview]
		set contrast [::Capture::GetContrast $::CAMGUI::webcam_preview]	
		set hue [::Capture::GetHue $::CAMGUI::webcam_preview]	
		set color [::Capture::GetColour $::CAMGUI::webcam_preview]

		#Then, if there are valid settings in our config, overwrite the values with these
		set colorsettings [split [::config::getKey "webcam$selecteddevice:$selectedchannel"] ":"]
		set set_b [lindex $colorsettings 0]
		set set_c [lindex $colorsettings 1]
		set set_h [lindex $colorsettings 2]
		set set_co [lindex $colorsettings 3]
		
		if {![info exists brightness] && [string is integer -strict $set_b]} {
				set brightness $set_b
		}
		if {![info exists contrast] && [string is integer -strict $set_c]} {
				set contrast $set_c
		}
		if {![info exists hue] && [string is integer -strict $set_h]} {
				set hue $set_h
		}
		if {![info exists color] &&[string is integer -strict $set_co]} {
				set color $set_co
		}

		set slides $leftframe
		frame $slides -background #ffffff

		scale $slides.b -from [::Capture::GetBrightness $::CAMGUI::webcam_preview MIN] -to [::Capture::GetBrightness $::CAMGUI::webcam_preview MAX] \
			-resolution 1 -showvalue 1 -label "[trans brightness]" -orient horizontal \
			-command [list ::AVAssistant::Properties_SetLinux $slides.b b $::CAMGUI::webcam_preview]
		scale $slides.c -from [::Capture::GetContrast $::CAMGUI::webcam_preview MIN] -to [::Capture::GetContrast $::CAMGUI::webcam_preview MAX] \
			-resolution 1 -showvalue 1 -label "[trans contrast]" -orient horizontal\
			-command [list ::AVAssistant::Properties_SetLinux $slides.c c $::CAMGUI::webcam_preview]
		scale $slides.h -from [::Capture::GetHue $::CAMGUI::webcam_preview MIN] -to [::Capture::GetHue $::CAMGUI::webcam_preview MAX] \
			-resolution 1 -showvalue 1 -label "[trans hue]" -orient horizontal \
			-command [list ::AVAssistant::Properties_SetLinux $slides.h h $::CAMGUI::webcam_preview]
		scale $slides.co -from [::Capture::GetColour $::CAMGUI::webcam_preview MIN] -to [::Capture::GetColour $::CAMGUI::webcam_preview MAX] \
			-resolution 1 -showvalue 1 -label "[trans color]" -orient horizontal \
			-command [list ::AVAssistant::Properties_SetLinux $slides.co co $::CAMGUI::webcam_preview]

		pack $slides.b $slides.c $slides.h $slides.co -expand true -fill x
		pack $leftframe -side left -padx 10 -expand true -fill x

		#set the sliders right
		Properties_SetLinux $slides.b b $::CAMGUI::webcam_preview $brightness
		Properties_SetLinux $slides.c c $::CAMGUI::webcam_preview $contrast
		Properties_SetLinux $slides.h h $::CAMGUI::webcam_preview $hue
		Properties_SetLinux $slides.co co $::CAMGUI::webcam_preview $color
		
		set semaphore ::CAMGUI::sem_$::CAMGUI::webcam_preview
		set $semaphore 0
		while { [::Capture::IsValid $::CAMGUI::webcam_preview] && [ImageExists $previmg] } {
			if {[catch {::Capture::Grab $::CAMGUI::webcam_preview $previmg } res ]} {
				status_log "Problem grabbing from the device:\n\t \"$res\""
				set errorheight [expr {$camheight-25}]
				$previmc create text 5 $errorheight -anchor nw -font bboldf -text "$res" -fill #FF0000 -anchor nw -tag errmsg
				after 3000 "catch { $previmc delete errmsg }"
			}
			after 100 "incr $semaphore"
			tkwait variable $semaphore
		}

		#TODO: Add a key-combo to reread the device settings and set these and go to next step (to adjust to settings of other programs)

	}

	######################################################################################
	#Step 2 Video Linux - Auxilary procs                                                 #
	######################################################################################	
	###
	# Set properties on Linux
	proc Properties_SetLinux { w property capture_fd new_value } {
		variable selecteddevice
		variable selectedchannel
		
		variable brightness
		variable contrast
		variable hue
		variable color		
		
		switch $property {
			b {
				::Capture::SetBrightness $capture_fd $new_value
				#::Capture::GetBrightness doesn't work with my cam
				#set brightness [::Capture::GetBrightness $capture_fd]
				set brightness $new_value
				$w set $brightness
			}
			c {
				::Capture::SetContrast $capture_fd $new_value
				#::Capture::GetContrast doesn't work with my cam
				#set contrast [::Capture::GetContrast $capture_fd]
				set contrast $new_value
				$w set $contrast
			}
			h
			{
				::Capture::SetHue $capture_fd $new_value
				#::Capture::GetContrast doesn't work with my cam
				#set hue [::Capture::GetHue $capture_fd]
				set hue $new_value
				$w set $hue
			}
			co
			{
				::Capture::SetColour $capture_fd $new_value
				#::Capture::GetContrast doesn't work with my cam
				#set color [::Capture::GetColour $capture_fd]
				set color $new_value
				$w set $color
			}
		}
		variable video_configured
		set video_configured 1
	}

	######################################################################################
	# Step 1 Video for Windows:  Set device/channel                                      #
	######################################################################################	
	proc Step1WWin {assistant contentf} {
		#we should be able to alter this vars in other procs
		variable chanswidget
		variable previmc
		variable selecteddevice
		variable selecteddevicename
		variable previmg

		#extensions are present, we can change some settings	
		$assistant modifyStep "Step0W" titleText [trans setupcam]
		$assistant modifyStep "Step0W" leavingProc ::AVAssistant::stopPreviewWindows 

		##Here comes the content:##

		#build the GUI framework (same for windows/linux)
			
# +-------------------------+
# |       descrition        |
# |+----------+ +---------+ |--innerframe ($contenf)
# ||          | |         | |
# ||          | |         | |
# ||          | |         |----rightframe (a canvas $rightframe))
# ||          | |         | |
# ||          | |         | |
# ||          |-|---------|----leftframe
# |+----------+ +---------+ |
# +-------------------------+

		label $contentf.desc -justify left -text [trans assistantselectcam]
		pack $contentf.desc -pady 20 
		#to get a nice wrapping
		bind $contentf.desc <Configure> [list %W configure -wraplength %w]
		
		#create the left frame (for the comboboxes)
		set leftframe $contentf.left
		frame $leftframe -bd 0
		pack $leftframe -side left -padx 10

		#create the 'rightframe' canvas where the preview-image will be shown
		set rightframe $contentf.right


		#this is a canvas so we can have a border and put some OSD-like text on it too
		canvas $rightframe -background #000000 -width 320 -height 240 -bd 0
		pack $rightframe -side right -padx 10

		#draw the border image that will be layed ON the preview-img
		$rightframe create image 0 0 -image [::skin::loadPixmap camempty] -anchor nw -tag border
		#give the canvas a clear name
		set previmc $rightframe

		#First line, device-chooser title
		label $leftframe.devstxt -text [trans choosedevice]
		pack $leftframe.devstxt -side top
		
		#create and pack the devices-combobox
		combobox::combobox $leftframe.devs -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf -exportselection true -editable false -command [list ::AVAssistant::startPreviewWindows]
		
		#make sure the devs-combobox is empty first
		$leftframe.devs list delete 0 end

		destroy .webcam_preview
		tkvideo .webcam_preview
		set devices [.webcam_preview devices]

		#insert the device-names in the widget
		foreach device $devices {
			$leftframe.devs list insert end $device
		}
		#pack the dev's combobox
		pack $leftframe.devs -side top
		
		#get the already set device from the config (if there is one set)
		if {![info exists selecteddevice]} {
			if {[::config::getKey webcamDevice] != ""} {
				set selecteddevice [::config::getKey webcamDevice]
			} else {
				set selecteddevice 0
			}
		}
		#select the device set if possible
		catch {$leftframe.devs select $selecteddevice}
		
		button $leftframe.settings -text "[trans changevideosettings]" -command [list .webcam_preview propertypage filter]
		pack $leftframe.settings -pady 10
	#end the Step1WWin proc
	}
	
	proc stopPreviewWindows {assistant contentf} {
		variable previmg
		destroy .webcam_preview

		if {[info exists previmg]} {
			catch {image delete $previmg}
		}
	}

	proc startPreviewWindows { dev_widget value } {
		variable selecteddevice
		variable selecteddevicename
		variable previmc
		variable previmg
		
		if { $value == "" } {
			status_log "No channel selected; IS THIS POSSIBLE ?"
		} else {
			set selecteddevicename $value
			#get the nr of the selected device
			set selecteddevice [lsearch [$dev_widget list get 0 end] $value]

			#stop previewing if needed
			::AVAssistant::stopPreviewWindows 0 0
			#launching tkvideo again
			tkvideo .webcam_preview

			if { [catch { .webcam_preview configure -source $selecteddevice } res] } {
				$previmc create text 5 215 -anchor nw -font bboldf -text "$res" -fill #FF0000 -anchor nw -tag errmsg
				after 3000 "catch { $previmc delete errmsg }"
				return
			}
			if { [catch { .webcam_preview start } res] } {
				$previmc create text 5 215 -anchor nw -font bboldf -text "$res" -fill #FF0000 -anchor nw -tag errmsg
				after 3000 "catch { $previmc delete errmsg }"
				return
			}
			if { [catch { .webcam_preview format 320x240 } res] } {
				$previmc create text 5 215 -anchor nw -font bboldf -text "$res" -fill #FF0000 -anchor nw -tag errmsg
				after 3000 "catch { $previmc delete errmsg }"
				return
			}
			
			set previmg [image create photo [TmpImgName]]

			$previmc create image 0 0 -image $previmg -anchor nw 

			$previmc create text 10 10 -anchor nw -font bboldf -text "[trans preview] $selecteddevicename" -fill #FFFFFF -anchor nw -tag device

			after 3000 "catch { $previmc delete device }"

			after 1 [list ::CAMGUI::PreviewWindows .webcam_preview $previmg]
		}
	}

	######################################################################################
	# Step 1 Audio:  Configuring output settings                                         #
	######################################################################################
	proc Step1A {assistant contentf} {
		$contentf configure -padx 10 -pady 10

		##Here comes the content:##
		#build the GUI framework 

		if {[catch {require_snack}]} {
			#can't load the package, warn the user
			label $contentf.audiolabel -justify left -anchor nw -font bboldf \
				-text [trans checkingaudio]\
				-image [::skin::loadPixmap no-emblem] -compound right
			label $contentf.audiowarn -justify left -text [trans assistantawarn]
#TODO: fill the url
			label $contentf.audiowarnurl -justify left -text "$::weburl/wiki/" -fg blue

			pack $contentf.audiolabel
			pack $contentf.audiowarn 
			pack $contentf.audiowarnurl

			bind $contentf.audiowarnurl <Enter> [list %W configure -font sunderf]
			bind $contentf.audiowarnurl <Leave> [list %W configure -font splainf]
			bind $contentf.audiowarnurl <ButtonRelease> [list launch_browser "$::weburl/wiki"]
			#to get a nice wrapping
 			bind $contentf.audiowarn <Configure> [list %W configure -wraplength %w]

			#remove the saving of audio settings*
			$assistant modifyStep "Step1A" nextProc ""

		} else {
		#succeed in loading snack
			variable audio_configured
			variable sound

			set audio_configured 1

			#add the second step of the audio assistant
			set step [list "Step2A" 1 ::AVAssistant::Step2A ::AVAssistant::stopSound "" "" "" [trans configuremic] assistant_audio 1 1]
			$assistant insertStepAfter $step "Step1A"

			#when we leave, but not for saving, set mixers and all as default
			$assistant addCancelProc resetAudio ::AVAssistant::resetAudio

#       leftframe                                             rightframe
#+------|-----------------------------------------------------|--------+
#|                           $desc                                     |
#|+---------------------------++--------------------------------------+|
#||  Choose output device:    || Volume :   {scale}                   ||
#||      {ComboBox}           || {Button Record} {Button PlayRecord}  ||
#||  Choose mixer device:     || {Button PlayTestFile}                ||
#||      {ComboBox}           || {Canvas Wave}                        ||--- contentf
#|+---------------------------++--------------------------------------+|
#+---------------------------------------------------------------------+

			label $contentf.desc -justify left -text [trans assistantaoutput]
			pack $contentf.desc -pady [list 20 0]
			#to get a nice wrapping
			bind $contentf.desc <Configure> [list %W configure -wraplength %w]

			#create the left frame (for the comboboxes)
			set leftframe $contentf.left
			frame $leftframe -bd 0
			pack $leftframe -side left -padx 10 -fill x
				
			#Output devices
			label $leftframe.outtxt -text "\n\n[trans chooseoutputdev]"

			#create and pack the output-combobox
			combobox::combobox $leftframe.out -highlightthickness 0 -width 22 -font splainf \
				-exportselection true -command [list ::AVAssistant::wrapSetOutputDevice] \
				-editable false -bg #FFFFFF
			$leftframe.out list delete 0 end
			foreach output [::audio::getOutputDevices] {
				$leftframe.out list insert end $output
			}

			#select the already set mix if possible
			set devnr [lsearch [$leftframe.out list get 0 end] [::audio::getOutputDevice]]
			catch {$leftframe.out select $devnr}
			pack $leftframe.outtxt \
			     $leftframe.out -side top

			set rightframe $contentf.right
			frame $rightframe -bd 0
			pack $rightframe -side right -fill x -padx 10


			#Volume
			# we must create the volume scale BEFORE the mixer combobox because it depends on it, but we'll pack it afterwards...
			set volf $rightframe.volumef
			frame $volf
			label $volf.voltxt -text "[trans volume]:" -padx 10

			scale $volf.volscale -from 0 -to 100 -resolution 1 -showvalue 1 \
				-orient horizontal -command [list ::AVAssistant::wrapSetVolume]
			$volf.volscale set [::audio::getVolume]


			#Mixer devices
			label $leftframe.mixtxt -text [trans choosemixerdev]
		
			#create and pack the input-combobox
			combobox::combobox $leftframe.mix -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf \
			    -exportselection true -editable false -command [list ::AVAssistant::wrapSetMixerDevice $volf.volscale]
			$leftframe.mix list delete 0 end
			foreach mixer [::audio::getMixerDevices] {
				$leftframe.mix list insert end $mixer
			}

			#select the already set mix if possible
			set devnr [lsearch [$leftframe.mix list get 0 end] [::audio::getMixerDevice]]
			catch {$leftframe.mix select $devnr}

			pack $leftframe.mixtxt $leftframe.mix -side top

			# We pack the volume widgets after the mixer widgets
			pack $volf -side top -pady 5
			pack $volf.voltxt $volf.volscale -side left
			
			#Test file area
			frame $rightframe.testf
			set testf $rightframe.testf
			pack $testf -side top -pady 5
			label $testf.testtxt -text [trans playtest] -padx 10
			label $testf.playtest -image [::skin::loadPixmap playbut]
			label $testf.stoptest -image [::skin::loadPixmap stopbut] -state disabled
			
			bind $testf.playtest <ButtonPress-1> [list ::AVAssistant::playTest $rightframe]
			bind $testf.playtest <Enter> [list %W configure -image [::skin::loadPixmap playbuth]]
			bind $testf.playtest <Leave> [list %W configure -image [::skin::loadPixmap playbut]]
			
			bind $testf.stoptest <ButtonPress-1> ""
			bind $testf.stoptest <Enter> [list %W configure -image [::skin::loadPixmap stopbuth]]
			bind $testf.stoptest <Leave> [list %W configure -image [::skin::loadPixmap stopbut]]

			pack $testf.testtxt \
			     $testf.playtest \
			     $testf.stoptest -fill both -side left -padx 5
		
			frame $rightframe.wavef
			set wavef $rightframe.wavef
			pack $wavef -side top -pady 5
			canvas $wavef.wave -borderwidth 0 -relief solid -width 250 -height 150
			pack $wavef.wave -side left

		
		}
	#end the Step1A proc
	}

	######################################################################################
	#Step 1 Audio - Auxilary procs                                                       #
	######################################################################################
	###
	# change all audio settings to their defaults ones without saving them
	proc resetAudio {assistant contentf} {
		::audio::setInputDevice [::config::getKey snackInputDevice]
		::audio::setOutputDevice [::config::getKey snackOutputDevice]
		::audio::setMixerDevice [::config::getKey snackMixerDevice]
	}

	###
	# Stop playing sound from Assistant
	proc stopSound {assistant contentf} {
		variable sound
		if {[info exists sound] } {
			catch { $sound stop }
			catch { $sound destroy }
			unset sound
		}
	}

	###
	# some proc to wrap
	proc wrapSetVolume { vol } {
		::audio::setVolume $vol
	}
	proc wrapSetOutputDevice { w dev } {
		::audio::setOutputDevice $dev 0
	}
	proc wrapSetMixerDevice { scale w dev } {
		::audio::setMixerDevice $dev 0
		$scale set [::audio::getVolume]
	}

	###
	# Play the test file
	proc playTest {w} {
		variable sound

		# We need to destroy the sound and recreate it otherwise the sound will not play from the start if we press 'play' more than once
		::AVAssistant::stopSound "" ""
		
		#use the alarm as test file
		set sound [::snack::sound -file [::skin::GetSkinFile sounds alarm.wav] ]
		if {[winfo exists $w.wavef] && [winfo exists $w.testf]} {
			catch { $w.wavef.wave delete waveform }
			catch { $w.wavef.wave delete errmsg }
			if { [catch {$sound play -command [list ::AVAssistant::endPlayTestDelayed $w]} res]} {
				$w.wavef.wave create text 5 5 -anchor nw -font bboldf -width [winfo width $w.wavef.wave] -text "[trans playerror $res]" -fill #FF0000 -anchor nw -tag errmsg
				after 3000 "catch { $w.wavef.wave delete errmsg }"
			} else {
				#TODO: have a progression on the waveform while listening
				$w.wavef.wave create waveform 0 0 -sound $sound -width 250 -height 75 -tags [list waveform]	
				
				bind $w.testf.stoptest <ButtonPress-1> [list ::AVAssistant::stopTest $w]
				bind $w.testf.playtest <ButtonPress-1> [list ::AVAssistant::pauseTest $w]
				bind $w.testf.playtest <Enter> [list %W configure -image [::skin::loadPixmap pausebuth]]
				bind $w.testf.playtest <Leave> [list %W configure -image [::skin::loadPixmap pausebut]]
				
				$w.testf.playtest configure -image [::skin::loadPixmap pausebut]
				$w.testf.stoptest configure -state normal
			}
		}
	
	}
	###
	# called when reached the end when playing the test file or stopped
	proc endPlayTestDelayed {w} {
		# We need this little hack because it looks like snack (at least on my PC) calls our callback 1 second before the audio
		# really finished playing.
		after 1200 [list ::AVAssistant::endPlayTest $w]
	}

	proc endPlayTest {w} {
		if {[winfo exists $w.testf]} {
			bind $w.testf.stoptest <ButtonPress-1> ""
			bind $w.testf.playtest <ButtonPress-1> [list ::AVAssistant::playTest $w]
			bind $w.testf.playtest <Enter> [list %W configure -image [::skin::loadPixmap playbuth]]
			bind $w.testf.playtest <Leave> [list %W configure -image [::skin::loadPixmap playbut]]
			$w.testf.playtest configure -image [::skin::loadPixmap playbut]
			$w.testf.stoptest configure -state disabled
		}
	}

	###
	# Pause the test file
	proc pauseTest {w} {
		variable sound
		if { [info exists sound] } {
			$sound pause 
			if {[winfo exists $w.testf]} {
				bind $w.testf.playtest <ButtonPress-1> [list ::AVAssistant::playTest $w]
				bind $w.testf.playtest <Enter> [list %W configure -image [::skin::loadPixmap playbuth]]
				bind $w.testf.playtest <Leave> [list %W configure -image [::skin::loadPixmap playbut]]
				$w.testf.playtest configure -image [::skin::loadPixmap playbut]
			}
		}
	}
	###
	# Stop playing the test file
	proc stopTest {w} {
		variable sound
		if { [info exists sound] } {
			$sound stop
		}
		::AVAssistant::endPlayTest $w
	}


	######################################################################################
	#Step 2 Audio: Configuring input settings                                            #
	######################################################################################
	proc Step2A {assistant contentf} {
		variable haveMic
		variable sound

		set haveMic 1

		label $contentf.desc -justify left -text [trans assistantainput]
		pack $contentf.desc -pady [list 20 0]
		#to get a nice wrapping
		bind $contentf.desc <Configure> [list %W configure -wraplength %w]

		#create the left frame (for the comboboxes)
		set leftframe $contentf.left
		frame $leftframe -bd 0
		pack $leftframe -side left -padx 10 -fill x

		#First line, select input devices
		label $leftframe.intxt -text [trans chooseinputdev]

		#create and pack the input-combobox
		combobox::combobox $leftframe.in -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf \
			-exportselection true -editable false -command [list ::AVAssistant::wrapSetInputDevice]
		$leftframe.in list delete 0 end
		foreach input [::audio::getInputDevices] {
			$leftframe.in list insert end $input
		}

		#select the already set mix if possible
		set devnr [lsearch [$leftframe.in list get 0 end] [::audio::getInputDevice]]
		catch {$leftframe.in select $devnr}
		pack $leftframe.intxt $leftframe.in -side top

		button $leftframe.nomic -text [trans havenomic] -command [list ::AVAssistant::disableMicrophone $assistant]
		pack $leftframe.nomic -pady 20

		set rightframe $contentf.right
		frame $rightframe -bd 0
		pack $rightframe -side right -fill x -padx 10


		#Record area
		frame $rightframe.recf
		set recf $rightframe.recf
		pack $recf -side top -pady 5
		label $recf.recordtxt -text "[trans record]:" -padx 10
		label $recf.record -image [::skin::loadPixmap recordbut]
		label $recf.playrecorded -image [::skin::loadPixmap playbut] -state disabled
		label $recf.stoprecorded -image [::skin::loadPixmap stopbut] -state disabled

		bind $recf.record <ButtonPress-1> [list ::AVAssistant::record $rightframe]
		bind $recf.record <Enter> [list %W configure -image [::skin::loadPixmap recordbuth]]
		bind $recf.record <Leave> [list %W configure -image [::skin::loadPixmap recordbut]]

		bind $recf.playrecorded <Enter> [list %W configure -image [::skin::loadPixmap playbuth]]
		bind $recf.playrecorded <Leave> [list %W configure -image [::skin::loadPixmap playbut]]

		bind $recf.stoprecorded <ButtonPress-1> ""
		bind $recf.stoprecorded <Enter> [list %W configure -image [::skin::loadPixmap stopbuth]]
		bind $recf.stoprecorded <Leave> [list %W configure -image [::skin::loadPixmap stopbut]]

		pack $recf.recordtxt \
		     $recf.record \
		     $recf.playrecorded \
		     $recf.stoprecorded -fill both -side left -padx 5

		frame $rightframe.wavef
		set wavef $rightframe.wavef
		pack $wavef -side top -pady 5
		canvas $wavef.wave -borderwidth 0 -relief solid -width 250 -height 150
		pack $wavef.wave -side left

		#use the alarm as test file for the moment
		::AVAssistant::stopSound 0 0
		set sound [::snack::sound]
	}

	proc disableMicrophone { assistant } {
		variable haveMic 
		set haveMic 0
		$assistant next
	}


	proc wrapSetInputDevice { w dev } {
		::audio::setInputDevice $dev 0
	}
	
	###
	# Record
	proc record { w } {
		variable sound

		if { [info exists sound] } {
			$sound destroy
		}

		set sound [::snack::sound]

		if { [catch {$sound record} res]} {
			$w.wavef.wave create text 5 5 -anchor nw -font bboldf -width [winfo width $w.wavef.wave] -text "[trans recorderror $res]" -fill #FF0000 -anchor nw -tag errmsg
			after 3000 "catch { $w.wavef.wave delete errmsg }"
		} else {
			#don't press on the play button while recording
			bind $w.recf.playrecorded <ButtonPress-1> ""
			#and don't try to record while recording :)
			bind $w.recf.record <ButtonPress-1> ""
			$w.recf.playrecorded configure -state disabled
			$w.recf.record configure -state disabled

			bind $w.recf.stoprecorded <ButtonPress-1> [list ::AVAssistant::stopRecordPlay $w]
			$w.recf.stoprecorded configure -state normal

			$w.wavef.wave delete waveform
			$w.wavef.wave create waveform 0 0 -sound $sound -zerolevel 0 -width 250 -height 75 -pixelspersecond 15 -tags [list waveform] 
		}
	}
	###
	# Stop recording/playing from GUI
	proc stopRecordPlay {w} {
		variable sound
		if { [info exists sound] } {
			$sound stop 
		}
		::AVAssistant::endPlayRecord $w
	}
	###
	# Play the record
	proc playRecord {w} {
		variable sound
		
		$w.wavef.wave delete waveform
		$w.wavef.wave create waveform 0 0 -sound $sound -zerolevel 0 -width 250 -height 75 -pixelspersecond 15 -tags [list waveform]
		
		if { [info exists sound] } {
			$sound play -command [list ::AVAssistant::endPlayRecordDelayed $w]
			#while playing, turn the play button into a pause one
			bind $w.recf.playrecorded <Enter> [list %W configure -image [::skin::loadPixmap pausebuth]]
			bind $w.recf.playrecorded <Leave> [list %W configure -image [::skin::loadPixmap pausebut]]
			bind $w.recf.playrecorded <ButtonPress-1> [list ::AVAssistant::pauseRecord $w]
			bind $w.recf.stoprecorded <ButtonPress-1> [list ::AVAssistant::stopRecordPlay $w]
			$w.recf.playrecorded configure -image [::skin::loadPixmap pausebut] -state normal
			$w.recf.record configure -state disabled
			$w.recf.stoprecorded configure -state normal
		}
	}
	###
	# Pause recording
	proc pauseRecord {w} {
		variable sound
		if { [info exists sound] } {
			$sound pause 
		}
		#get back to the play button
		bind $w.recf.playrecorded <Enter> [list %W configure -image [::skin::loadPixmap playbuth]]
		bind $w.recf.playrecorded <Leave> [list %W configure -image [::skin::loadPixmap playbut]]
		bind $w.recf.playrecorded <ButtonPress-1> [list ::AVAssistant::playRecord $w]
		$w.recf.playrecorded configure -image [::skin::loadPixmap playbut]
	}
	###
	# called when reached the end when playing the record or stopped
	proc endPlayRecordDelayed {w} {
		# We need this little hack because it looks like snack (at least on my PC) calls our callback 1 second before the audio
		# really finished playing.
		after 1200 [list ::AVAssistant::endPlayRecord $w]
	}
	###
	# called when reached the end when playing the record or stopped
	proc endPlayRecord {w} {
		if {[winfo exists $w.recf]} {
			#get back to the play button
			bind $w.recf.playrecorded <Enter> [list %W configure -image [::skin::loadPixmap playbuth]]
			bind $w.recf.playrecorded <Leave> [list %W configure -image [::skin::loadPixmap playbut]]
			$w.recf.playrecorded configure -image [::skin::loadPixmap playbut] -state normal
			bind $w.recf.playrecorded <ButtonPress-1> [list ::AVAssistant::playRecord $w]

			#we can record again
			bind $w.recf.record <ButtonPress-1> [list ::AVAssistant::record $w]
			bind $w.recf.stoprecorded <ButtonPress-1> ""

			$w.recf.playrecorded configure -state normal
			$w.recf.record configure -state normal
			$w.recf.stoprecorded configure -state disabled
		}
	}


	######################################################################################
	# Step 3 : Farsight                                                                  #
	######################################################################################
	proc StepFarsight {assistant contentf} {
		variable cf
		set cf $contentf

		$contentf configure -padx 20 -pady 20
		label $contentf.fslabel -justify left -anchor nw -font bboldf \
			-text [trans farsightextchecking]
		pack $contentf.fslabel
		
		label $contentf.fsmsg -justify left -text ""
		label $contentf.fsurl -justify left -text "" -fg blue

		pack $contentf.fsmsg
		pack $contentf.fsurl

		button $contentf.details -text [trans showdetails] -command [list ::AVAssistant::ShowHideDetails $assistant $contentf 1]
		pack $contentf.details -pady 15
		
		text $contentf.ftxt -width 60 -height 6

		if {[catch {package require Farsight} res]} {
			::AVAssistant::appendFarsightDetails "$res\n"
			::AVAssistant::StepFarsightClBk $assistant $contentf 0
		} else {
			::AVAssistant::appendFarsightDetails "Using package Farsight version $res\n"
			::MSNSIP::TestFarsight [list ::AVAssistant::StepFarsightClBk $assistant $contentf] "::AVAssistant::appendFarsightDetails"
		}
	}

	proc ShowHideDetails {assistant contentf showOrHide} {
		if {$showOrHide == 0} {
			$contentf.details configure -text [trans showdetails] -command [list ::AVAssistant::ShowHideDetails $assistant $contentf 1]
			pack forget $contentf.ftxt
		} else {
			$contentf.details configure -text [trans hidedetails] -command [list ::AVAssistant::ShowHideDetails $assistant $contentf 0]
			pack $contentf.ftxt
		}
	}

	proc appendFarsightDetails {txt} {
		variable cf
		puts $txt
		#ensure txt ends in a newline
		if { [string index $txt end] != "\n" } {
			set txt "$txt\n"
		}

		$cf.ftxt insert end $txt
	}

	proc StepFarsightClBk {assistant contentf result} {
		variable farsight_details

		if {![winfo exists $contentf.fslabel]} {
			return
		}
		if { $result == 1} {
			$contentf.fslabel configure -image [::skin::loadPixmap yes-emblem] -compound right
			set txt [trans farsightinfook]
		} else {
			#display error message
			$contentf.fslabel configure -image [::skin::loadPixmap no-emblem] -compound right
			set txt [trans farsightextwarn]
		}
		$contentf.fsmsg configure -justify left -text $txt 
		$contentf.fsurl configure -justify left -text "$::weburl/wiki/Farsight" -fg blue

		bind $contentf.fsurl <Enter> [list %W configure -font sunderf]
		bind $contentf.fsurl <Leave> [list %W configure -font splainf]
		bind $contentf.fsurl <ButtonRelease> [list launch_browser "$::weburl/wiki/Farsight"]
		#to get a nice wrapping
		bind $contentf.fsmsg <Configure> [list %W configure -wraplength %w]
	}



	######################################################################################
	# Last Step (closing-page)                                                           #
	######################################################################################	
	proc LastStep {assistant contentf} {
		variable audio_configured
		variable video_configured
		variable selecteddevicename
		variable selectedchannelname
		variable haveMic

		set sharecamState "disabled"

		if {$video_configured} {
			if {[OnMac]} {
				set text [trans webcamconfiguredMac]
				set sharecamState "normal"
			} elseif {[OnWin]} {
				set text [trans webcamconfiguredWin $selecteddevicename]
				set sharecamState "normal"
			} elseif {[OnLinux]} {
				set text [trans webcamconfiguredLinux $selecteddevicename $selectedchannelname]
				set sharecamState "normal"
			} else {
#TODO: translation ??? (for freebsd users)
				set text "hum, i don't know how you reached that step :), but i hope you have configured your webcam."
			}

			#add the Content
			label $contentf.textvideo -justify left -font bplainf -text $text
			#pack it
			pack $contentf.textvideo -padx 20 -pady 10 -fill both -expand 1
			#to get a nice wrapping
			bind $contentf.textvideo <Configure> [list %W configure -wraplength %w]

			#add connection entry only if with have a webcam
			abook::getIPConfig
			
			# Window can be closed while we do the IPConfig stuff..
			if {![winfo exists $contentf] } {
				return
			}

			if { [::abook::getDemographicField listening] == "false"} {
				label $contentf.connection -justify left -font bplainf -text [trans firewalled2]
				#pack it
				pack $contentf.connection -padx 20 -pady 10 -fill both -expand 1
				#to get a nice wrapping
				bind $contentf.connection <Configure> [list %W configure -wraplength %w]
			}
		}

		if {$audio_configured} {
			#snack should work for everyone
			if {$haveMic} {
				set text [trans audioconfigured [::audio::getOutputDevice] [::audio::getInputDevice]]
			} else {
				set text [trans audioconfigured [::audio::getOutputDevice] [trans nomic]]
			}
			#add the Content
			label $contentf.textaudio -justify left -font bplainf -text $text
			#pack it
			pack $contentf.textaudio -padx 20 -pady 10 -fill both -expand 1
			#to get a nice wrapping
			bind $contentf.textaudio <Configure> [list %W configure -wraplength %w]
		}

		#click on the finish button to save settings.
		label $contentf.textfinish -justify left -font bplainf -text [trans finish2apply]
		#pack it
		pack $contentf.textfinish -padx 20 -pady 10 -fill both -expand 1
		#to get a nice wrapping
		bind $contentf.textfinish <Configure> [list %W configure -wraplength %w]

		$assistant addCancelProc resetSharecam [list ::AVAssistant::resetSharecam [::config::getKey wanttosharecam] ]

		checkbutton $contentf.wanttosharecam -text "[trans wanttosharecam]" -font sboldf -variable [::config::getVar wanttosharecam] -onvalue 1 -offvalue 0 -state $sharecamState
		pack $contentf.wanttosharecam -pady 10

		$assistant setFinishProc ::AVAssistant::finish
	}

	proc resetSharecam { old_value assistant contentf} {
		::config::setKey wanttosharecam $old_value
	}

	######################################################################################
	# Finish: Saving settings                                                            #
	######################################################################################
	proc finish {assistant contentf} {
		variable video_configured
		variable audio_configured
		#video settings has been configured
		if {$video_configured} {
			#currently, only useful for linux users
			if {[OnLinux]} {
				#saving device + channel
				variable selecteddevice
				variable selectedchannel
				::config::setKey "webcamDevice" "$selecteddevice:$selectedchannel"

				#saving finetune settings
				variable brightness
				variable contrast
				variable hue
				variable color
				::config::setKey "webcam$selecteddevice:$selectedchannel" "$brightness:$contrast:$hue:$color"

				#saving lowrescam setting
				variable lowrescam
				::config::setKey lowrescam $lowrescam
			} elseif {[OnWin]} {
				variable selecteddevice
				::config::setKey "webcamDevice" "$selecteddevice"
			}

			if { [::config::getKey wanttosharecam] } {
				::MSN::setClientCap webcam
			} else {
				::MSN::setClientCap webcam 0
			}
			#Refresh clientid if connected
			if { [::MSN::myStatusIs] != "FLN" } {
				::MSN::changeStatus [set ::MSN::myStatus]
			}
		}
		#audio settings has been configured
		if {$audio_configured} {
			variable haveMic
			#saving through the audio API

			::config::setKey userHasMicrophone $haveMic
			::audio::setInputDevice [::audio::getInputDevice]
			::audio::setOutputDevice [::audio::getOutputDevice]
			::audio::setMixerDevice [::audio::getMixerDevice]
		}

		#save the configs
		if {$audio_configured || $video_configured} {
			save_config
		}
	}

#Close the ::AVAssistant namespace
}
