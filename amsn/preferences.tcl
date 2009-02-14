
::Version::setSubversionId {$Id$}

package require BWidget

#TODO:
#Put items frame and listbox in scrollbars!!


namespace eval Preferences {

	proc Show {} {

		if [winfo exists .prefs] {
			raise .prefs
			catch {focus -force .prefs}
			return
		}
		
		#Set pixmaps
		::skin::setPixmap prefpers prefpers.gif
		::skin::setPixmap prefprofile prefprofile.gif
		::skin::setPixmap preffont preffont.gif
		::skin::setPixmap prefphone prefphone.gif

		::skin::setPixmap preflook preflook.gif
		::skin::setPixmap prefemotic prefemotic.gif
		::skin::setPixmap prefalerts prefalerts.gif
		
		
		if { [LoginList exists 0 [::config::getKey login]] == 1 } {
			PreferencesWindow .prefs -title "[trans preferences] - [trans profiledconfig] - [::config::getKey login]" -savecommand ::Preferences::Save
		} else {
			PreferencesWindow .prefs -title "[trans preferences] - [trans defaultconfig] - [::config::getKey login]" -savecommand ::Preferences::Save
		}
		
		#####################################################
		# Section "Personal"
		#####################################################
		set section [PreferencesSection .prefs.personal -text [trans personal]]
		
		set frame [ItemsFrame .prefs.personal.nicks -text [trans prefname] -icon prefpers]
		$frame addItem [TextEntry .prefs.personal.nicks.nick -width 40 -text "[trans enternick] :" \
			-storecommand ::Preferences::StoreNick -retrievecommand [list ::abook::getPersonal MFN]]
		$frame addItem [TextEntry .prefs.personal.nicks.chat -width 40 -text "[trans friendlyname] :" \
			-variable [::config::getVar p4c_name]]
		$section addItem $frame
		
		set frame [ItemsFrame .prefs.personal.preffont -text [trans preffont] -icon preffont]
		$frame addItem [Label .prefs.personal.preffont.lab -text [trans preffont2] -align center]
		$frame addItem [CommandButton .prefs.personal.preffont.changefont -text [trans changefont] \
			-variable [::config::getVar mychatfont] -buttoncommand ::Preferences::ChangeFont]
		$frame addItem [CommandButton .prefs.personal.preffont.changeincomingfont -text [trans changefont] \
			-variable [::config::getVar theirchatfont] -buttoncommand ::Preferences::ChangeFont]
		$section addItem $frame
	
		set frame [ItemsFrame .prefs.personal.prefphone -text [trans prefphone] -icon prefphone]
		#$frame addItem [Label create .prefs.personal.prefphone.lab -text [trans prefphone2]]
		$frame addItem [TextEntry .prefs.personal.prefphone.home -text "[trans myhomephone]:" -width 20 \
			-retrievecommand [list ::abook::getPersonal PHH]]
		$frame addItem [TextEntry .prefs.personal.prefphone.work -text "[trans myworkphone]:" -width 20 \
			-retrievecommand [list ::abook::getPersonal PHW]]
		$frame addItem [TextEntry .prefs.personal.prefphone.mobile -text "[trans mymobilephone]:" -width 20 \
			-retrievecommand [list ::abook::getPersonal PHM]]
		$frame addItem [CheckBox .prefs.personal.prefphone.allowsms -text [trans allow_sms] \
			-onvalue "Y" -offvalue "N" -storecommand [list ::abook::setPhone pager] -retrievecommand [list ::abook::getPersonal MOB]]
		$section addItem $frame
		

		.prefs addSection $section

		####################################################
		# Section Interface
		#####################################################
		set section [PreferencesSection interface -text [trans appearance]]
		.prefs addSection $section

		set frame [ItemsFrame look -text [trans preflook] -icon preflook]
		$frame addItem [Label preflook.labenc -text "[trans encoding2]:" -align left]
		$frame addItem [CommandButton preflook.encoding -text [trans encoding] -align left\
			-variable [::config::getVar encoding] -buttoncommand ::Preferences::ChangeEncoding]

		$frame addItem [Label preflook.labfont -text "[trans preffont3]:" -align left]
		$frame addItem [CommandButton preflook.font -text [trans changefont] -align left\
			-variable [::config::getGlobalVar basefont] -buttoncommand ::Preferences::ChangeBaseFont]

		$frame addItem [Label preflook.labdate -text "[trans dateformat]:" -align left]
		$frame addItem [RadioGroup preflook.date \
			-texts [list "[trans month]/[trans day]/[trans year]" "[trans day]/[trans month]/[trans year]" "[trans year]/[trans month]/[trans day]"] \
			-values [list MDY DMY YMD] -variable [::config::getVar dateformat]]

		$section addItem $frame
	
		####################################################
		# Section ...
		#####################################################
		set section [PreferencesSection .prefs.caca -text "Test"]
		$section addSection [PreferencesSection .prefs.caca2 -text "Test2"]
		$section addSection [PreferencesSection .prefs.caca3 -text "Test3"]
		
		.prefs addSection $section
			
		.prefs show .prefs_window
	
		Configure 1
		
	}

	proc Configure { {fullinit 0} } {

		if {![winfo exists .prefs]} {
			return
		} 

		if { $fullinit } {
	
			.prefs.personal.nicks.chat setValue [::config::getKey p4c_name]
			if { [::MSN::myStatusIs] == "FLN" } {
				.prefs.personal.nicks.nick configure -enabled 0
				.prefs.personal.prefphone.home configure -enabled 0
				.prefs.personal.prefphone.work configure -enabled 0
				.prefs.personal.prefphone.mobile configure -enabled 0
				.prefs.personal.prefphone.allowsms configure -enabled 0
				
			} else {
				.prefs.personal.nicks.nick configure -enabled 1
				.prefs.personal.prefphone.home configure -enabled 1
				.prefs.personal.prefphone.work configure -enabled 1
				.prefs.personal.prefphone.mobile configure -enabled 1
			}
			if { [::abook::getPersonal MBE] == "N" } {
				.prefs.personal.prefphone.allowsms -enabled 0
			}
		}

	
	}

	proc Save {} {

		set must_restart 0
		
		# Check and save phone numbers		
		if { [::MSN::myStatusIs] != "FLN" } {
			#set lfname [Rnotebook:frame $nb $Preftabs(personal)]
			set home [urlencode [.prefs.personal.prefphone.home getValue]]
			set work [urlencode [.prefs.personal.prefphone.work getValue]]
			set mobile [urlencode [.prefs.personal.prefphone.mobile getValue]]
			if { $home != [::abook::getPersonal PHH] } {
				::abook::setPhone home $home
			}
			if { $work != [::abook::getPersonal PHW] } {
				::abook::setPhone work $work
			}
			if { $mobile != [::abook::getPersonal PHM] } {
				::abook::setPhone mobile $mobile
			}
		}
		
		if { [preflook.font getValue] != [::config::getGlobalKey basefont]} {
			set must_restart 1
		}

		if { $must_restart } {
			msg_box [trans mustrestart]
		}

		::Event::fireEvent changedPreferences gui

	}


	proc ChangeFont { currentfont } {

		#Get current font configuration
		set fontname [lindex $currentfont 0] 
		set fontstyle [lindex $currentfont 1]
		set fontcolor [lindex $currentfont 2]
	
		if { [catch {
				set selfont_and_color [SelectFont .fontsel -parent .prefs_window -title [trans choosebasefont] -font [list $fontname 12 $fontstyle] -initialcolor "#$fontcolor"]
			}]} {
			
			set selfont_and_color [SelectFont .fontsel -parent .prefs_window -title [trans choosebasefont] -font [list "helvetica" 12 [list]] -initialcolor "#000000"]
			
		}
		
		set selfont [lindex $selfont_and_color 0]
		set selcolor [lindex $selfont_and_color 1]
	
		if { $selfont == ""} {
			return $currentfont
		}
		
		set sel_fontfamily [lindex $selfont 0]
		set sel_fontstyle [lrange $selfont 2 end]
		
		
		if { $selcolor == "" } {
			set selcolor $fontcolor
		} else {
			set selcolor [string range $selcolor 1 end]
		}
		
		return [list $sel_fontfamily $sel_fontstyle $selcolor]
	}

	proc ChangeBaseFont {currentfont} {
		if { [winfo exists .basefontsel] } {
			raise .basefontsel
			return
		}

	
		if { [catch {
			set font [SelectFont .basefontsel -parent .prefs_window -title [trans choosebasefont] -font $currentfont -styles [list]]
			}]} {
		
			set font [SelectFont .basefontsel -parent .prefs_window -title [trans choosebasefont] -font [list "helvetica" 12 [list]] -styles [list]]
		
		}

		set family [lindex $font 0]
		set size [lindex $font 1]
			
		if { $family == "" || $size == ""} {
			return $currentfont
		}

		return [list $family $size normal]
	}

	proc ChangeEncoding { currentenc } {
		::amsn::messageBox "TODO" yesno question "[trans confirm]" .prefs_window
	}

	proc StoreNick { nick } {
		if {$nick != "" && $nick != [::abook::getPersonal MFN] && [::MSN::myStatusIs] != "FLN"} {
			::MSN::changeName $nick
		}
	}
	proc StorePSM { psm } {
		if {$psm != "" && $psm != [::abook::getPersonal PSM] && [::MSN::myStatusIs] != "FLN"} {
			::MSN::changePSM $psm
		}
	}

}

#This object type is a generic and abstract preference item.
# OPTIONS
# -variable	The variable where the value will be stored/retrieved
# -retrievecommand	
#		A command that needs to be called to retrieve the initial value of the text entry
# -storecommand		
#		A command that needs to be called to store the value of the text entry when the "store"
#		method is called. The command will be appended one argument, the text entry value
# -enabled	Enables or disabled the item
# METHODS
# getValue()	Return the current value of the item
# setValue(val) Sets the value of the item
# draw(path)	Draws the item inside the specified container
# store()	Store the item value in the related variable
::snit::type PreferenceItem {
	
	#The variable where the items stores its data
	option -variable -readonly no -default ""
	#The command that must be executed to retrieve the value. This command should return the variable value
	option -retrievecommand -readonly no -default ""
	#The command that must be executed to store the command. The value in the widget will be appended as parameter to the command
	option -storecommand -readonly no -default ""
	
	#Enable or disable the item
	option -enabled -default true

	##########################################
	#Common methods for all preference items
	##########################################
	
	constructor {args} {
		$self configurelist $args
	}

	onconfigure -variable { val } {
		upvar $val var
		$self setValue $var
		set options(-variable) $val
	}
	onconfigure -retrievecommand { val } {	
		$self setValue [eval $val]
		set options(-retrievecommand) $val
	}

	variable value ""

	#Return the item value
	method getValue {} {
		return $value
	}
	
	#Set the item value
	method setValue {new_val} {
		set value $new_val
	}
	
	#Draw the element in the given widget path (path must be a container)
	method draw {path} {
		label $path.l -text "Preference item"
		pack $path.l
	}

	#Store the object values
	method store {} {
		if {!$options(-enabled)} {
			status_log "$self disabled, not storing\n" blue
			return
		}
		status_log "Storing $self, value [$self getValue]\n" blue
		if { $options(-variable) != "" } {
			status_log "   in variable $options(-variable)\n" blue
			upvar $options(-variable) var
			set var [$self getValue]
		}		
		if { $options(-storecommand) != "" } {
			status_log "   with command $options(-storecommand)\n" blue
			eval [concat $options(-storecommand) [list [$self getValue]]]
		}
		
	}

	method valueVar {} {
		return [myvar value]
	}
}

#This type is child of PreferenceItem. It groups some options under a 
#frame with a label and an icon.
#Usage:
# OPTIONS
# -text 	The text to be shown in the frame header
# -icon 	A picture to be shown at the left, inside the frame
# -expand 	The frame should expand in the container. Defaults to YES
# -fill		The frame should fill all available space in X, Y or BOTH. Defaults to X
# -enabled	The frame and contained items is enabled/disabled
# METHODS
# addItem(item)		Add a PreferenceItem inside this frame
::snit::type ItemsFrame {

	#Delegate to PreferenceItem by default
	delegate method * to preferenceitem
	delegate option * to preferenceitem

	#The widget path to this item
	variable itemPath ""
	#The items contained inside the frame
	variable items [list]

	constructor {args} {
		install preferenceitem using PreferenceItem %AUTO%
		$self configurelist $args
	}
	
	destructor {
		#Destroy the PreferenceItem object
		$preferenceitem destroy
		
		#Destroy child items
		foreach item $items {
			$item destroy
		}

		#Destroy the container frame
		if [winfo exists $itemPath.f] {
			destroy $itemPath.f
		}
		
	}
	
	#########################
	#Static options (creation time)
	#########################
	
	#Text for the item label
	option -text -readonly yes -default ""
	#Icon for the frame
	option -icon -readonly yes -default ""
	#Options for packing the frame
	option -expand -readonly yes -default true
	option -fill -readonly yes -default x

	#########################
	#Dinamic options
	#########################
	option -enabled -default true
		
	#Add a new PreferenceItem to the group
	method addItem {item} {
		lappend items $item
	}
	
	#Triggered when the -enabled option is changed
	onconfigure -enabled { val } {
		set options(-enabled) $val
		$preferenceitem configure -enabled $val
		#Now tell all the children to enable themshelves
		set num 0
		foreach item $items {
			$item configure -enabled $val
		}
	}
	
	
	#Create the label frame and icon, and tell all children items to draw themshelves
	method draw { path } {
	
		#Store the path for later usage
		set itemPath $path
		
		#Create and pack the labelframe
		set f [labelframe $path.f -text $options(-text) -font splainf] 
		pack $path.f -side top -fill x
		
		#If there is an icon, draw it
		if { $options(-icon) != "" } {
			frame $f.f
			label $f.icon -image [::skin::loadPixmap $options(-icon)]
			pack $f.icon -side left -padx 5 -pady 5
			pack $f.f -side left -fill x -expand true
			
			set f $f.f
		}
		
		#Now tell all the children to draw themshelves, and pack them
		set num 0
		foreach item $items {
			set f2 $f.f$num
			frame $f2
			$item draw $f2
			pack $f2 -side top -expand $options(-expand) -fill $options(-fill)
			
			incr num
		}
	}
	
	#Tell all children to store themselves
	method store {} {
		foreach item $items {
			$item store
		}
	}

}

#A text entry item. Child of PreferenceItem
#Usage:
# OPTIONS
# -text 	The text to be shown next to the text entry
# -width	The width of the text entry
# -onchange	A command that is called everytime the text entry changes to validate the input
# -enabled	Enables or disabled the text entry
# METHODS
::snit::type TextEntry {
	
	#Delegate to PrferenceItem!!
	delegate method * to preferenceitem
	delegate option * to preferenceitem
	
	#Enable or disable the item
	option -enabled -default true
		
	#The widget path
	variable itemPath ""
		
	constructor {args} {
		install preferenceitem using PreferenceItem %AUTO%
		$self configurelist $args
	}
	
	destructor {
		#Destroy the PreferenceItem instance
		$preferenceitem destroy
		#Destroy widgets
		destroy $itemPath.l
		destroy $itemPath.t
	}
	
	#########################
	#Static options (creation time)
	#########################
	#Command to be triggered when the item changes
	option -onchange -readonly yes -default ""
	
	#Text for the item label
	option -text -readonly yes -default ""
	#With of the textfield
	option -width -readonly yes -default ""
	
	#########################
	#Dinamic options
	#########################
	
	#Triggered when the -enabled option is changed
	onconfigure -enabled { val } {
		set options(-enabled) $val
		$preferenceitem configure -enabled $val
		if {[winfo exists $itemPath.t]} {
			if { $val } {
				$itemPath.t configure -state normal 
			} else {
				$itemPath.t configure -state disabled
			}
		}
	}
		
	#Draw the text box in the given path
	method draw { path } {

		set itemPath $path
		#Draw an input box
		
		#Composed by a label... and...
		label $path.l -text $options(-text) -font sboldf
		
		if { $options(-enabled) } {
			set state normal 
		} else {
			set state disabled
		}

		if { $options(-onchange) != "" } {
			set validatecommand [list $options(-onchange) $self %s %S]
		} else {
			set validatecommand ""
		}
		
		#...a text entry (can have defined width or not)
		if { [string is integer -strict $options(-width)] } {
			entry $path.t -width $options(-width) -state $state -textvariable [$self valueVar] \
				-validate all -validatecommand $validatecommand
			pack $path.t -side right -expand false -padx 5 -pady 3
			pack $path.l -side right -expand false -padx 5 -pady 3
		} else {
			entry $path.t -state $state -textvariable [$self valueVar] \
				-validate all -validatecommand $validatecommand
			pack $path.t -side right -expand true -fill x -padx 5 -pady 3
			pack $path.l -side right -expand false -padx 5 -pady 3
		}
	}
	
}

#A check box item. Child of PreferenceItem
#Usage:
# OPTIONS
# -text 	The text to be shown next to the check button
# -onchange	A command that is called everytime the check button value changes
# -enabled	Enables or disabled the checkbutton
# -onvalue	The value that the item will take when the checkbutton is checked. Defaults to 1
# -offvalue	The value that the item will take when the checkbutton is not checked. Defaults to 0
# METHODS
::snit::type CheckBox {
	
	#Delegate to PrferenceItem!!
	delegate method * to preferenceitem
	delegate option * to preferenceitem

	#Enable or disable the item
	option -enabled -default true
		
	#The widget path
	variable itemPath ""
		
	constructor {args} {
		install preferenceitem using PreferenceItem %AUTO%
		$self configurelist $args
	}
	
	destructor {
		#Destroy the PreferenceItem instance
		$preferenceitem destroy
		#Destroy widgets
		destroy $itemPath.c
	}
	
	#########################
	#Static options (creation time)
	#########################
	#Command to be triggered when the item changes
	option -onchange -readonly yes -default ""
	
	#Text for the item label
	option -text -readonly yes -default ""
	#ON/OFF values
	option -onvalue -readonly yes -default 1
	option -offvalue -readonly yes -default 0
	
	#########################
	#Dynamic options
	#########################
	
	#Triggered when the -enabled option is changed
	onconfigure -enabled { val } {
		set options(-enabled) $val
		$preferenceitem configure -enabled $val
		if {[winfo exists $itemPath.c]} {
			if { $val } {
				$itemPath.c configure -state normal 
			} else {
				$itemPath.c configure -state disabled
			}
		}
	}

	
	#Draw the text box in the given path
	method draw { path } {

		set itemPath $path
		#Draw an input box
		
		if { $options(-enabled) } {
			set state normal
		} else {
			set state disabled
		}

		if { $options(-onchange) != "" } {
			set changecommand [list $options(-onchange) $self %s %S]
		} else {
			set changecommand ""
		}
		
		#...a checkbutton entry
		checkbutton $path.c -text $options(-text) -font sboldf -state $state -variable [$self valueVar] \
			-command $changecommand -onvalue $options(-onvalue) -offvalue $options(-offvalue)

		pack $path.c -side right -expand false -padx 5 -pady 3
	}
	
}

#A group of radio buttons. Child of PreferenceItem
#Usage:
# OPTIONS
# -texts	A list with one text for every checkbutton
# -values	A list of values corresponding to every selection. Defaults to 0, 1, 2...
# -onchange	A command that is called everytime the radio button value changes
# -enabled	Enables or disabled the radio buttons
# METHODS
::snit::type RadioGroup {
	
	#Delegate to PrferenceItem!!
	delegate method * to preferenceitem
	delegate option * to preferenceitem

	#Enable or disable the item
	option -enabled -default true
		
	#The widget path
	variable itemPath ""
		
	constructor {args} {
		install preferenceitem using PreferenceItem %AUTO%
		$self configurelist $args
	}
	
	destructor {
		#Destroy the PreferenceItem instance
		$preferenceitem destroy
		#Destroy widgets
		destroy $itemPath.f
	}
	
	#########################
	#Static options (creation time)
	#########################
	#Command to be triggered when the item changes
	option -onchange -readonly yes -default ""
	
	#Text for the item label
	option -texts -readonly yes -default [list]
	option -values -readonly yes -default [list]
	
	#########################
	#Dynamic options
	#########################
	
	#Triggered when the -enabled option is changed
	onconfigure -enabled { val } {
		set options(-enabled) $val
		$preferenceitem configure -enabled $val
		if {[winfo exists $itemPath.f]} {
			foreach child [winfo children $itemPath.f] {
				if { $val } {
					$child configure -state normal 
				} else {
					$child configure -state disabled
				}
			}
		}
	}

	
	#Draw the text box in the given path
	method draw { path } {

		set itemPath $path
		#Draw an input box
		
		if { $options(-enabled) } {
			set state normal
		} else {
			set state disabled
		}

		if { $options(-onchange) != "" } {
			set changecommand [list $options(-onchange) $self %s %S]
		} else {
			set changecommand ""
		}
		
		frame $path.f

		set i 0
		foreach text $options(-texts) {
			radiobutton $path.f.rb$i -text $text -font sboldf -state $state -variable [$self valueVar] \
				-command $changecommand -value [lindex $options(-values) $i]
			pack $path.f.rb$i -side top -anchor nw
			incr i
		}

		pack $path.f -side left -expand false -padx 5 -pady 3
	}
	
}


#A command button. Child of PreferenceItem
#Usage:
# OPTIONS
# -text 	The text to be shown in the button
# -buttoncommand
#		The command that will be launched when the button is pressed. When this happens, the current item value will be appended as
#		a parameter to this command. The return value of the command is then stored as new item value
# -enabled	Enables or disabled the checkbutton
# METHODS
::snit::type CommandButton {
	
	#Delegate to PrferenceItem!!
	delegate method * to preferenceitem
	delegate option * to preferenceitem

	#The variable where the items stores its data
	option -buttoncommand -readonly yes -default ""
	
	#Enable or disable the item
	option -enabled -default true
		
	#The widget path
	variable itemPath ""
		
	constructor {args} {
		install preferenceitem using PreferenceItem %AUTO%
		$self configurelist $args
	}
	
	destructor {
		#Destroy the PreferenceItem instance
		$preferenceitem destroy
		#Destroy widgets
		destroy $itemPath.b
	}
	
	#########################
	#Static options (creation time)
	#########################
	#Text for the item label
	option -text -readonly yes -default ""
	option -align -readonly yes -default center
	
	#########################
	#Dynamic options
	#########################
	
	#Triggered when the -enabled option is changed
	onconfigure -enabled { val } {
		set options(-enabled) $val
		$preferenceitem configure -enabled $val
		if {[winfo exists $itemPath.b]} {
			if { $val } {
				$itemPath.b configure -state normal 
			} else {
				$itemPath.b configure -state disabled
			}
		}
	}
	
	#Draw the button in the given path
	method draw { path } {

		set itemPath $path
		#Draw an input box
		
		if { $options(-enabled) } {
			set state normal
		} else {
			set state disabled
		}

		switch $options(-align) {
			left {
				set anchor w
			}
			right {
				set anchor e
			}
			default {
				set anchor center
			}

		}
	
		button $path.b -text $options(-text) -font sboldf -state $state -command [mymethod buttonPressed]
		pack $path.b -expand false -padx 5 -pady 3 -anchor $anchor
	}
	

	method buttonPressed {} {
		if { $options(-buttoncommand) != "" } {
			set the_command [concat $options(-buttoncommand) [list [$self getValue]]]
			set value [eval $the_command]
			$self setValue $value
		}

	}
}



#A text entry item. Child of PreferenceItem
#Usage:
# OPTIONS
# -text		The text that is shown in the label
# -align	right | left | center
::snit::type Label {
	
	#Delegate to PrferenceItem!!
	delegate method * to preferenceitem
	delegate option * to preferenceitem

	#The widget path
	variable itemPath ""
		
	constructor {args} {
		install preferenceitem using PreferenceItem %AUTO%
		$self configurelist $args
		
	}
	
	destructor {
		#Destroy the PreferenceItem instance
		$preferenceitem destroy
		#Destroy widgets
		destroy $itemPath.l
	}
	
	#########################
	#Static options (creation time)
	#########################
	
	#Text for the item label
	option -text -readonly yes -default ""
	option -align -readonly yes -default center
	
	#########################
	#Dinamic options
	#########################
	
	#Draw the text box in the given path
	method draw { path } {

		switch $options(-align) {
			left {
				set anchor w
			}
			right {
				set anchor e
			}
			default {
				set anchor center
			}

		}
		

		set itemPath $path
		label $path.l -text $options(-text) -font splainf
		pack $path.l -anchor $anchor
	}
}


::snit::widget PreferencesWindow {
	
	#Object is a children of PreferencesSection
	delegate method * to preferencessection
	
	#Window title
	option -title ""
	option -savecommand ""
	
	constructor {args} {
		install preferencessection using PreferencesSection %AUTO%
		$self configurelist $args
	}
	
	destructor {
		#Destroy the instance of the parent.
		#This will destroy subsections too
		$preferencessection destroy
		
		#Destroy the window
		if { [winfo exists $wname] } {
			destroy $wname
		}
		
	}

	#A list with section objects, one per listbox element
	variable sectionNames [list]
	variable wname ""
	
	#Show the preferences window
	method show { path } {
	
		#Create a window name and remember it
		set wname $path
		
		#Create the toplevel window
		toplevel $wname
		wm title $wname $options(-title)
    		bind $wname <Destroy> [list $self destroyWindow %W]
		bind $wname <<Escape>> [list destroy $wname]
		
		#Create the buttons
		set w [frame $wname.buttons]
		button $w.save -text [trans save] -default active -command [list $self savePressed]
		button $w.cancel -text [trans close] -command [list destroy $wname]
		pack $w.save $w.cancel -side right -padx 10 -pady 5
		pack $w -side bottom -fill x -expand false

		#Create the sections listbox and items area
		set w [frame $wname.top]

		#Create the sections listbox 
		listbox $w.sections -width 15
		#Create the items frame
		frame $w.items
		
		#Do the packing
		pack $w.sections -side left -fill y
		pack $w.items -side right -fill both -expand true
		bind $w.sections <<ListboxSelect>> [list $self sectionSelected]
		pack $w -side top -fill both -expand true

		#Add sections to the listbox
		foreach section [$self getSectionsList] {
			set sectionNames [concat $sectionNames [$section insertIntoList $w.sections 0]]
		}
		
		wm geometry $wname 625x450
	}
	
	#Invoked when a section is selected in the listbox
	method sectionSelected { } {

		#Get the section object name from the sectionNames list	
		set idx [$wname.top.sections curselection]
		set section [lindex $sectionNames $idx]
		
		#Create a new frames item, destroying previous one
		set items "$wname.top.items.f"
		if {[winfo exists $items]} {
			destroy $items
		}
		frame $items
		pack $items -anchor nw -fill both
		
		#Show the selected section
		$section show $items
		
	}
	
	method destroyWindow { w } {
		if { $w == $wname } {
			destroy $self
		}
	}

	method savePressed { } {
		if { $options(-savecommand) != "" } {
			$options(-savecommand)
		}

		$self storeItems

		destroy $wname
	}
	
}

#A section that contains zero, one or more preference items
::snit::type PreferencesSection {
	
	#List of items in this section
	variable items_list [list]
	#List of subsections
	variable sections_list [list]
	
	option -text -readonly yes -default ""
	
	destructor {
		#Destroy child items
		foreach item $items_list {
			$item destroy
		}
		#Destroy child sections
		foreach section $sections_list {
			$section destroy
		}
	}	
	
	method getSectionsList { } {
		return $sections_list
	}
	
	method addItem { item } {
		lappend items_list $item
	}

	method addSection {section} {
		lappend sections_list $section
	}
	
	#Insert this section and all subsections in the given listbox.
	#Retuns a list of this section and all subsections names (recursive calls)
	method insertIntoList { lb level } {
	
		#Append instance to sections list
		set sectionNames $self
	
		#Set identation
		set ident ""
		for { set idx 0 } { $idx < $level } {incr idx } {
			set ident "$ident   "
		}
		
		#Add current section to the listbox
		$lb insert end "$ident$options(-text)"
		
		#Add all subsections and append the result of the function call to the sections list
		foreach subsection $sections_list {
			set sectionNames [concat $sectionNames [$subsection insertIntoList $lb [expr {$level + 1}]]]
		}
		
		#Return the sections list for this section and all subsections
		return $sectionNames
	}
	
	#Show the items in this section in the given path
	method show { path } {
	
		set idx 0
		
		foreach item $items_list {
			set f [frame $path.f$idx]
			$item draw $f
			pack $f -side top -fill x
			incr idx

		}
	}

	method storeItems { } {
		#Add all subsections and append the result of the function call to the sections list
		foreach subsection $sections_list {
			$subsection storeItems
		}
		foreach item $items_list {
			$item store
		}
	}

}


proc test2 {item oldval newval} {
	status_log "$item: old=$oldval new=$newval\n" blue
	return [string is integer $newval]
}

proc new_preferences {} {
	PreferencesWindow create .prefs
	
	PreferencesSection create .prefs.personal
	PreferencesSection create .prefs.personal.nick
	
	.prefs.personal addItem 
	
	.pref_win 
}



if { $initialize_amsn == 1 } {
	global myconfig proxy_server proxy_port proxy_user proxy_pass rbsel rbcon pgc
	
	###################### Preferences Window ###########################
	array set myconfig {}   ; # configuration backup
	set proxy_server ""
	set proxy_port ""
	set proxy_pass ""
	set proxy_user ""
    	
	set pgc 1
}

proc PreferencesCopyConfig {} {
	global myconfig proxy_server proxy_port
	
	array set myconfig [::config::getAll]
	
	set proxy_server ""
	set proxy_port ""
	
	# Now process certain exceptions. Should be reverted
	# in the RestorePreferences procedure
	catch {
		set proxy_data $myconfig(proxy)
		set proxy_server [lindex $proxy_data 0]
		set proxy_port [lindex $proxy_data 1]
	}
}

## Function that makes the group list in the preferences ##
proc MakeGroupList { lfgroup lfcontact } {
	
	array set groups [::abook::getContactData contactlist groups]
	
	frame $lfgroup.lbgroup.fix
	pack $lfgroup.lbgroup.fix -side left -anchor n -expand 1 -fill x -padx 5 -pady 5
	label $lfgroup.lbgroup.fix.l -text \"[trans groups]\" -font sboldf
	pack $lfgroup.lbgroup.fix.l -side top -anchor w -pady 5
	
	frame $lfgroup.lbgroup.fix.list
	## create the listbox ##
	listbox $lfgroup.lbgroup.fix.list.lb -yscrollcommand "$lfgroup.lbgroup.fix.list.sb set"
	scrollbar $lfgroup.lbgroup.fix.list.sb -command "$lfgroup.lbgroup.fix.list.lb yview" -highlightthickness 0 \
		-borderwidth 1 -elementborderwidth 2

	pack $lfgroup.lbgroup.fix.list.lb -side left -anchor w -pady 0 -padx 0 -expand true -fill both
	pack $lfgroup.lbgroup.fix.list.sb -side left -anchor w -pady 0 -padx 0 -fill y
	pack $lfgroup.lbgroup.fix.list -side top -expand true -fill both
	

	## entries ##
	$lfgroup.lbgroup.fix.list.lb insert end "[trans nogroup]"
	foreach gr [lsort [array names groups]] {
		if { $groups($gr) != "Individuals" } {
			$lfgroup.lbgroup.fix.list.lb insert end $groups($gr)
		}
	}
	## make binding ##
	bind $lfgroup.lbgroup.fix.list.lb <<ListboxSelect>> "GroupSelectedIs $lfgroup $lfcontact"
}

## Function to be called when <<ListboxSelect>> event occurs to change rbsel value ##
proc GroupSelectedIs { lfgroup lfcontact } {
	global rbsel
	if {[$lfgroup.lbgroup.fix.list.lb curselection] != "" } {
		set rbsel [$lfgroup.lbgroup.fix.list.lb curselection]
		#Get the rbsel-th group. Note that groups must be inserted same order
		array set groups [::abook::getContactData contactlist groups]
		set rbsel [lindex [lsort [array names groups]] $rbsel]
		MakeContactList $lfcontact 
	}
}

## Function to be called after pressing delete/rename/add group button ##
proc RefreshGroupList { lfgroup lfcontact } {
	global pgc pgcd
	if { $pgc == 1 } {
		vwait pgc
	}
	set pgc 1
	destroy $lfgroup.lbgroup.fix
	MakeGroupList $lfgroup $lfcontact
}

## Function to be called when a group is selected ##
proc MakeContactList { lfcontact } {
	global rbsel rbcon
	catch {DeleteContactList $lfcontact}
	
	if {![info exists rbsel]} { return; }
	if { ![::groups::Exists [::groups::GetName $rbsel]] || $rbsel == 0 } {
		if { $rbsel == 0 } {
			## fix the name of the group ##
			label $lfcontact.lbcontact.fix.l -text "[trans nogroup]" -font sboldf
			pack $lfcontact.lbcontact.fix.l -side top -pady 5 -padx 5  -anchor w
			frame $lfcontact.lbcontact.fix.list
			
			## create the listbox ##
			listbox $lfcontact.lbcontact.fix.list.lb -yscrollcommand "$lfcontact.lbcontact.fix.list.sb set"
			scrollbar $lfcontact.lbcontact.fix.list.sb -command "$lfcontact.lbcontact.fix.list.lb yview" -highlightthickness 0 \
				-borderwidth 1 -elementborderwidth 2
			
			pack $lfcontact.lbcontact.fix.list.lb -side left -anchor w -expand true -fill both
			pack $lfcontact.lbcontact.fix.list.sb -side left -anchor w -fill y
			pack $lfcontact.lbcontact.fix.list -side top -anchor w -pady 5 -padx 5 -expand true -fill both
			## list contacts that don't have a group ##
			set contacts [::MSN::getList FL]
			set contacts [concat $contacts [::MSN::getList EL]]
			set i 0
			while { $i < [llength $contacts] } {
				set contact [lindex $contacts $i]
				set g [::abook::getGroups $contact]
				if { [lindex $g 0] == 0 } {
					$lfcontact.lbcontact.fix.list.lb insert end $contact
				}
				incr i
			}
		## make the binding ##
		bind $lfcontact.lbcontact.fix.list.lb <<ListboxSelect>> "ContactSelectedIs $lfcontact"
		}
	} else {
		label $lfcontact.lbcontact.fix.l -text "[::groups::GetName $rbsel]" -font sboldf
		pack $lfcontact.lbcontact.fix.l -side top -pady 5 -padx 5 -anchor w
		frame $lfcontact.lbcontact.fix.list
		
		## create the listbox ##
		listbox $lfcontact.lbcontact.fix.list.lb -yscrollcommand "$lfcontact.lbcontact.fix.list.sb set"
		scrollbar $lfcontact.lbcontact.fix.list.sb -command "$lfcontact.lbcontact.fix.list.lb yview" -highlightthickness 0 \
			-borderwidth 1 -elementborderwidth 2

		pack $lfcontact.lbcontact.fix.list.lb -side left -anchor w -expand true -fill both
		pack $lfcontact.lbcontact.fix.list.sb -side left -anchor w -fill y
		pack $lfcontact.lbcontact.fix.list -side top -anchor w -pady 5 -padx 5 -expand true -fill both

		set groups [::abook::getContactData contactlist groups]
		set contacts [::MSN::getList FL]
		set contacts [concat $contacts [::MSN::getList EL]]
		set i 0
		while { $i < [llength $contacts] } {
			set contact [lindex $contacts $i]
			set group [::abook::getGroups $contact]
			set j 0
			while { $j < [llength $group] } {
				set g [lindex $group $j]
				if { $g == $rbsel } {
					$lfcontact.lbcontact.fix.list.lb insert end $contact
				}
				incr j
			}
			incr i
		}
		## make the binding ##
		bind $lfcontact.lbcontact.fix.list.lb <<ListboxSelect>> "ContactSelectedIs $lfcontact"
	}
}

## Function to be called when <<ListboxSelect>> event occurs to change rbsel value ##
proc ContactSelectedIs { lfcontact } {
	global rbcon
	if {[$lfcontact.lbcontact.fix.list.lb curselection] != "" } {
		set rbcon [$lfcontact.lbcontact.fix.list.lb get [$lfcontact.lbcontact.fix.list.lb curselection]]
	} else {
		set rbcon ""
	}
}

## Function to be called when the selected group becomes unvalid ##
proc DeleteContactList { lfcontact } {
	destroy $lfcontact.lbcontact.fix
	frame $lfcontact.lbcontact.fix
	pack $lfcontact.lbcontact.fix -side left -anchor n -expand 1 -fill x
}

## Function to be called when the selected group is deleted/renamed or a contact deleted/moved/copied/added ##
proc RefreshContactList { lfcontact } {
	global pcc
	if { $pcc == 1 } {
		vwait pcc
	}
	set pcc 1
	DeleteContactList $lfcontact
	MakeContactList $lfcontact
}

proc dlgMoveUser {} {
	global rbcon rbsel gsel pcc
	if {![info exists rbcon]} {return;}
	if {![info exists rbsel]} {return;}
	## check if window exists ##
	if { [winfo exists .dlgmu] } {
		set pcc 0
		return 0
	}
	## if no contact is selected -- return ##
	if { $rbcon == "" } {
		set pcc 0
		return 0
	}
	## calculate oldgid - now we get the first group int the group list - we have to improve it ##
	set oldgid [::abook::getGroups $rbcon]
	set oldgid [lindex $oldgid 0]
	## variable for the selected group -- we set to oldgid to avoid bugs ##
	set gsel $oldgid
	
	set bgcol2 #ABC8D2
	toplevel .dlgmu -highlightcolor $bgcol2
	wm title .dlgmu "[trans moveuser]"
	## radiobuttons for newgid ##
	frame .dlgmu.d
	array set groups [::abook::getContactData contactlist groups]
	foreach gr [array names groups] {
		if { $groups($gr) != "Individuals" } {
			radiobutton .dlgmu.d.$gr -text "$groups($gr)" -value $gr -variable gsel
			pack .dlgmu.d.$gr -side left
		}
	}
	pack .dlgmu.d -side top -pady 3 -padx 5
	## button options ##
	frame .dlgmu.b 
	button .dlgmu.b.ok -text "[trans ok]"  -font sboldf \
		-command " if {![info exists gsel]} {return;}; \
			::MSN::moveUser \$rbcon $oldgid \$gsel; \
			unset gsel; \
			destroy .dlgmu; "
	button .dlgmu.b.cancel -text "[trans cancel]"  -font sboldf \
		-command "destroy .dlgmu; set pcc 0;"
	pack .dlgmu.b.ok .dlgmu.b.cancel -side right -padx 5
	pack .dlgmu.b  -side top -anchor e -pady 3
}

proc dlgCopyUser {} {
	global rbcon rbsel gsel pcc
	if {![info exists rbcon]} {return;}
	if {![info exists rbsel]} {return;}
	if { [winfo exists .dlgcu] } {
		set pcc 0
		return 0
	}
	## if no contact is selected -- return ##
	if { $rbcon == "" } {
		set pcc 0
		return 0
	}
	## calculate oldgid - now we get the first group int the group list - we have to improve it ##
	set oldgid [::abook::getGroups $rbcon]
	set oldgid [lindex $oldgid 0]
	## protection --> the contacts who are in 'nogroup' will be moved, not copied ##
	set move 0
	if { $oldgid == 0 } {
		set move 1
	}
	## variable for the selected group -- we set to oldgid to avoid bugs ##
	set gsel $oldgid
	
	set bgcol2 #ABC8D2
	toplevel .dlgcu -highlightcolor $bgcol2
	wm title .dlgcu "[trans moveuser]"
	## radiobuttons for newgid ##
	frame .dlgcu.d
	array set groups [::abook::getContactData contactlist groups]
	foreach gr [array names groups] {
		if { $groups($gr) != "Individuals" } {
			radiobutton .dlgcu.d.$gr -text "$groups($gr)" -value $gr -variable gsel
			pack .dlgcu.d.$gr -side left
		}
	}
	pack .dlgcu.d -side top -pady 3 -padx 5
	## button options ##
	frame .dlgcu.b 
	if { $move == 0 } {
		button .dlgcu.b.ok -text "[trans ok]"  -font sboldf \
			-command " if {![info exists gsel]} {return;}; \
				::MSN::copyUser \$rbcon \$gsel; \
				unset gsel; \
				destroy .dlgcu; "
	}
	if { $move == 1 } {
		button .dlgcu.b.ok -text "[trans ok]" -font sboldf \
			-command " if {![info exists gsel]} {return;}; \
				::MSN::moveUser \$rbcon $oldgid \$gsel; \
				unset gsel; \
				destroy .dlgcu; "
	}
	button .dlgcu.b.cancel -text "[trans cancel]"  -font sboldf \
		-command "destroy .dlgcu; set pcc 0;"
	pack .dlgcu.b.ok .dlgcu.b.cancel -side right -padx 5
	pack .dlgcu.b  -side top -anchor e -pady 3
}

proc connection_check { lfname } {
	$lfname.1.ftport.bttest configure -state disabled
	$lfname.1.ftport.test configure -text [trans connecting]
	::abook::getIPConfig
	if {[winfo exists $lfname]} {
		if { [::abook::getDemographicField conntype] == "" } {
			$lfname.1.listening configure -text "[trans connectfirst]" -fg [::skin::getKey extrastderrcolor]
			$lfname.1.ftport.test configure -text "[trans connectfirst]" -fg [::skin::getKey extrastderrcolor]
		} else {
			if { [::abook::getDemographicField listening] == "false"} {
				$lfname.1.listening configure -text "[trans firewalled]" -fg [::skin::getKey extrastderrcolor]
				$lfname.1.ftport.test configure -text "[trans firewalled]" -fg [::skin::getKey extrastderrcolor]
			} else {
				$lfname.1.listening configure -text "[trans portswellconfigured]" -fg [::skin::getKey extrastdokcolor]
				$lfname.1.ftport.test configure -text "[trans ok]" -fg [::skin::getKey extrastdokcolor]
			}
		}
		$lfname.1.ftport.bttest configure -state normal
	}

}

# hide an option from the advanced preferences pane
proc hide_option { w {w_exp ""} } {
	if {!([catch {pack info $w}])} {
		pack forget $w
	}
	if {$w_exp != "" && !([catch {pack info $w_exp}])} {
		pack forget $w_exp
	}
}

# show an option from the advanced preferences pane
proc show_option { w name oldw {w_exp ""}} {
	if {$w_exp != "" && [catch {pack info $w_exp}]} {
		if {$oldw != ""} {
			pack $w_exp -anchor w -padx 15 -before $oldw
		} else {
			pack $w_exp -anchor w -padx 15
		}
		set oldw $w_exp
	}
	if {[catch {pack info $w}]} {
		set command [list pack $w]
		# pack options courtesy of advanced_options_reload procedure
		switch -glob $name {
			[0-9]* {
				lappend command -side top -padx 0 -fill x
			}
			cb* {
				lappend command -anchor w
			}
			le* -
			fr* {
				lappend command -anchor w -expand true -fill x
			}
			sp* {
				lappend command -anchor w -side top -anchor w -pady 4
			}
			l* {
				lappend command -anchor w -side top -anchor w -pady 4
			}
			default {
				return
			}
		}
		# oldw is the option *below* the current one
		if {$oldw != ""} {
			lappend command -before $oldw
		}
		eval $command
	}
}

proc filter_prefs { frm str action } {
	# action = -1 -> search box focused (do nothing)
	if {$action == -1} { return 1 }
	
	set optionlist [winfo children $frm]
	set oldoption ""
	# isempty means "there are no options visible below the current one"
	# as we go through the options from bottom to top, it's initialized to 1
	set isempty 1
	# isglobalempty means "the frame is completely empty"
	set isglobalempty 1
	# cycles through the list in reverse order
	set l [llength $optionlist]
	for {set i $l} {$i >= 0} {incr i -1} {
		set option [lindex $optionlist $i]
		set option_exp ""
		set text ""
		set name [regexp -inline -- (?:cb|exp|le|fr|l|sp)?\[0-9\]+$ $option]
		switch -glob $name {
			[0-9]* {
				# workaround for the date delimitators option
				catch {set text [$option.delimiters cget -text]}
			}
			cb* {
				catch {set text [$option cget -text]}
			}
			exp* {
				continue
			}
			le* {
				catch {set text [$option.lbl cget -text]}
			}
			fr* {
				catch {set text [$option.le.lbl cget -text]}
			}
			l* {
				if {$isempty} {
					# hide the title if there are no options below it
					hide_option $option
				} else {
					show_option $option $name $oldoption
					set oldoption $option
				}
				continue
			}
			sp* {
				if {$isempty} {
					hide_option $option
				} else {
					show_option $option $name $oldoption
					set oldoption $option
					# here begins a new section, so isempty is initialized
					set isempty 1
				}
				continue
			}
			default {
				set oldoption $option
				continue
			}
		}
		set j [regsub -all \[^0-9\] $name ""]
		set option_exp [regsub $name\$ $option exp$j]
		if {[winfo exists $option_exp]} {
			set text [join [list $text " " [$option_exp cget -text]]]
		} else {
			set option_exp ""
		}
		if {$text != ""} {
			if {$str == "" || [string first [string tolower $str] [string tolower $text]] != -1} {
				show_option $option $name $oldoption $option_exp
				set oldoption $option
				if {$isglobalempty} {
					set isglobalempty 0
				}
				if {$isempty} {
					set isempty 0
				}
			} else {
				hide_option $option $option_exp
			}
		}
	}
	# hide leading space
	if {[regexp -- sp\[0-9\]+$ $oldoption]} {
		hide_option $oldoption
	}
	# if the frame is empty, add a spacer to avoid the scrollbar bug
	# the name of the spacer MUST NOT begin with "sp" or it will be handled
	# as a normal spacer
	if {$isglobalempty} {
		catch {label $frm.bugfix_spacer -font bboldf}
		pack $frm.bugfix_spacer -side top -anchor w -pady 4
	} else {
		destroy $frm.bugfix_spacer
	}
	return 1
}

proc Preferences { { settings "personal"} } {
	global myconfig proxy_server proxy_port temp_BLP list_BLP Preftabs libtls proxy_user proxy_pass rbsel rbcon pager
	
	set temp_BLP $list_BLP
	::config::setKey libtls_temp $libtls
	set pager "N"
	if {[ winfo exists .cfg ]} {
		raise .cfg
	
		# This should raise the settings tab depending on the arg..
		catch {.cfg.notebook.nn raise $settings}
	
		return
	}
	
	PreferencesCopyConfig	;# Load current configuration
	
	toplevel .cfg
	wm state .cfg withdraw
	
	if { [LoginList exists 0 [::config::getKey login]] == 1 } {
		wm title .cfg "[trans preferences] - [trans profiledconfig] - [::config::getKey login]"
	} else {
		wm title .cfg "[trans preferences] - [trans defaultconfig] - [::config::getKey login]"
	}
	
	wm iconname .cfg [trans preferences]
	
	# Frame to hold the preferences tabs/notebook
	frame .cfg.notebook
	
	#set nb .cfg.notebook.nn
	set nb .cfg.notebook

	# Preferences Notebook
	# Modified Rnotebook to translate automaticly those keys in -tabs {}
	#Rnotebook:create $nb -tabs {personal appearance session privacy loging connection others advanced} -borderwidth 2
	    #set Preftabs(personal) 1
        #set Preftabs(appearance) 2
        #set Preftabs(session) 3
        #set Preftabs(privacy) 4
        #set Preftabs(loging) 5
        ##BLOCKING
	#set Preftabs(blocking) 6
        #set Preftabs(connection) 6 
        #set Preftabs(others) 7 
        #set Preftabs(advanced) 8 
	NoteBook $nb.nn
	$nb.nn insert end personal -text [trans personal]
	$nb.nn insert end appearance -text [trans appearance]
	$nb.nn insert end session -text [trans session]
	$nb.nn insert end groups -text [trans groups]
	$nb.nn insert end privacy -text [trans privacy]
	$nb.nn insert end loging -text [trans loging]
	$nb.nn insert end connection -text [trans connection]
	$nb.nn insert end others -text [trans others]
	$nb.nn insert end advanced -text [trans advanced]


	#  .----------.
	# _| Personal |________________________________________________
	::skin::setPixmap prefpers prefpers.gif
	::skin::setPixmap prefprofile prefprofile.gif
	::skin::setPixmap preflocale globe.png
	::skin::setPixmap preffont preffont.gif
	::skin::setPixmap prefphone prefphone.gif
	#set frm [Rnotebook:frame $nb $Preftabs(personal)]
	set frm [$nb.nn getframe personal]
	#Scrollable frame that will contain options
	ScrolledWindow $frm.sw
	ScrollableFrame $frm.sw.sf -constrainedwidth 1
	$frm.sw setwidget $frm.sw.sf
	pack $frm.sw -anchor n -side top -expand true -fill both
	set frm [$frm.sw.sf getframe]	

	## Nickname Selection Entry Frame ##
	set lfname [labelframe $frm.lfname -text [trans prefname] -font splainf]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x

	label $lfname.pname -image [::skin::loadPixmap prefpers]
	pack $lfname.pname -anchor nw -side left

	frame $lfname.1
	frame $lfname.1.name

	label $lfname.1.name.label -text "[trans enternick] :" -font sboldf -padx 10
	entry $lfname.1.name.entry -font splainf -width 45
	frame $lfname.1.psm
	label $lfname.1.psm.label -text "[trans psm] :" -font sboldf -padx 10
	entry $lfname.1.psm.entry -font splainf -width 45
	frame $lfname.1.p4c
	label $lfname.1.p4c.label -text "[trans friendlyname] :" -font sboldf -padx 10
	entry $lfname.1.p4c.entry -font splainf -width 45
	frame $lfname.1.ep
	label $lfname.1.ep.label -text "[trans renamelocation] :" -font sboldf -padx 10
	entry $lfname.1.ep.entry -font splainf -width 45
	pack $lfname.1 -side top -padx 0 -pady 3 -expand 1 -fill both
	pack $lfname.1.name.label $lfname.1.name.entry -side left
	pack $lfname.1.psm.label $lfname.1.psm.entry -side left
	pack $lfname.1.p4c.label $lfname.1.p4c.entry -side left
	pack $lfname.1.ep.label $lfname.1.ep.entry -side left
	if {[::config::getKey protocol] >= 11} {
		if {[::config::getKey protocol] >= 18} {
			pack $lfname.1.name $lfname.1.psm $lfname.1.p4c $lfname.1.ep -side top -anchor nw
		} else {
			pack $lfname.1.name $lfname.1.psm $lfname.1.p4c -side top -anchor nw
		}
	} else {
		pack $lfname.1.name $lfname.1.p4c -side top -anchor nw
	}

	## Public Profile Frame ##
	set lfname [labelframe $frm.lfname2 -text [trans prefprofile] -font splainf]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.pprofile -image [::skin::loadPixmap prefprofile]
	label $lfname.lprofile -text [trans prefprofile2] -padx 10
	button $lfname.bprofile -text [trans editprofile] -command "::hotmail::hotmail_profile"
	pack $lfname.pprofile $lfname.lprofile -side left
	pack $lfname.bprofile -side right -padx 15


	## Internationalization Frame ##
	set lfname [labelframe $frm.lfname2a -text [trans preflocale] -font splainf]
	pack $frm.lfname2a -anchor n -side top -expand 1 -fill x
	label $lfname.plocale -image [::skin::loadPixmap preflocale]
	label $lfname.llocale -text [trans preflocale2] -padx 10
	combobox::combobox $lfname.clocale -editable true -width 20
	pack $lfname.plocale $lfname.llocale -side left
	pack $lfname.clocale -side right -padx 15


	## Chat Font Frame ##
	set lfname [labelframe $frm.lfname3 -text [trans preffont] -font splainf]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.pfont -image [::skin::loadPixmap preffont]
	label $lfname.lfontout -text [trans preffont2]
	button $lfname.bfontout -text [trans changefont] -command "change_font cfg mychatfont"
	checkbutton $lfname.disableuserfonts -text "[trans disableuserfonts]" \
		-onvalue 1 -offvalue 0 -variable [::config::getVar disableuserfonts] -command UpdatePreferences
	label $lfname.lfontin -text [trans preffont4]
	button $lfname.bfontin -text [trans changefont] -command "change_font cfg theirchatfont; UpdatePreferences"
	button $lfname.bfontinreset -text [trans resetincomingfont] \
		-command "::config::setKey theirchatfont {}; UpdatePreferences"

	pack $lfname.pfont -side left
	pack $lfname.lfontout $lfname.bfontout $lfname.disableuserfonts \
		$lfname.lfontin $lfname.bfontin $lfname.bfontinreset -anchor w -pady 3 -padx 15 -side top

	## Phone Numbers Frame ##
	set lfname [labelframe $frm.lfname4 -text [trans prefphone] -font splainf]
	pack $frm.lfname4 -anchor n -side top -expand 1 -fill x 
	frame $lfname.1
	frame $lfname.2
	label $lfname.1.pphone -image [::skin::loadPixmap prefphone]
	pack $lfname.1.pphone -side left -anchor nw
	label $lfname.1.lphone -text [trans prefphone2] -padx 10
	pack $lfname.1.lphone -fill both -side left
	label $lfname.2.lphone1 -text "[trans countrycode] :" -padx 10 -font sboldf
	entry $lfname.2.ephone1 -font splainf  -width 5
	label $lfname.2.lphone21 -text "[trans areacode]" -pady 3
	label $lfname.2.lphone22 -text "[trans phone]" -pady 3
	label $lfname.2.lphone3 -text "[trans myhomephone] :" -padx 10 -font sboldf
	entry $lfname.2.ephone31 -font splainf  -width 5	
	entry $lfname.2.ephone32 -font splainf  -width 20
	label $lfname.2.lphone4 -text "[trans myworkphone] :" -padx 10 -font sboldf
	entry $lfname.2.ephone41 -font splainf  -width 5	
	entry $lfname.2.ephone42 -font splainf  -width 20
	label $lfname.2.lphone5 -text "[trans mymobilephone] :" -padx 10 -font sboldf
	entry $lfname.2.ephone51 -font splainf  -width 5	
	entry $lfname.2.ephone52 -font splainf  -width 20
	checkbutton $lfname.2.mobphone -text "[trans allow_sms]" -onvalue "Y" -offvalue "N" -variable pager
	button $lfname.2.person -text "[trans change_account_info]" -command "::hotmail::hotmail_changeAccountInfo"
    button $lfname.2.chgmob -text "[trans change_mobile]" -command "::hotmail::hotmail_changeMobile"

    
	pack $lfname.1 -expand 1 -fill both -side top
	pack $lfname.2 -expand 1 -fill both -side top
	grid $lfname.2.lphone1 -row 1 -column 1 -sticky w -columnspan 2
	grid $lfname.2.ephone1 -row 1 -column 3 -sticky w
	grid $lfname.2.lphone21 -row 2 -column 2 -sticky e
	grid $lfname.2.lphone22 -row 2 -column 3 -sticky e
	grid $lfname.2.lphone3 -row 3 -column 1 -sticky w
	grid $lfname.2.ephone31 -row 3 -column 2 -sticky w
	grid $lfname.2.ephone32 -row 3 -column 3 -sticky w
	grid $lfname.2.lphone4 -row 4 -column 1 -sticky w
	grid $lfname.2.ephone41 -row 4 -column 2 -sticky w
	grid $lfname.2.ephone42 -row 4 -column 3 -sticky w
	grid $lfname.2.lphone5 -row 5 -column 1 -sticky w
	grid $lfname.2.ephone51 -row 5 -column 2 -sticky w
	grid $lfname.2.ephone52 -row 5 -column 3 -sticky w
    grid $lfname.2.mobphone	-row 6 -column 1 -sticky w
	grid $lfname.2.chgmob -row 7 -column 1 -sticky w
	grid $lfname.2.person -row 8 -column 1 -sticky w

	$nb.nn compute_size
	[$nb.nn getframe personal].sw.sf compute_size
	
	#  .------------.
	# _| Appearance |________________________________________________
	::skin::setPixmap preflook preflook.gif
	::skin::setPixmap prefemotic prefemotic.gif
	::skin::setPixmap prefalerts prefalerts.gif
	#set frm [Rnotebook:frame $nb $Preftabs(appearance)]
	set frm [$nb.nn getframe appearance]
	#Scrollable frame that will contain options
	ScrolledWindow $frm.sw
	ScrollableFrame $frm.sw.sf -constrainedwidth 1
	$frm.sw setwidget $frm.sw.sf
	pack $frm.sw -anchor n -side top -expand true -fill both
	set frm [$frm.sw.sf getframe]	
	
	## General aMSN Look Options (Encoding, BGcolor, General Font, Clock Format)
	set lfname [labelframe $frm.lfname -text [trans preflook]]
	pack $frm.lfname -anchor n -side top -expand 0 -fill x
	label $lfname.plook -image [::skin::loadPixmap preflook]
	frame $lfname.0
	frame $lfname.1
#	frame $lfname.2
	frame $lfname.3
	frame $lfname.4
	frame $lfname.5
	frame $lfname.6
	frame $lfname.7

#	button $lfname.0.skinbutton -text [trans skinselector]  -command ::skinsGUI::SelectSkin
#	pack $lfname.0.skinbutton -side left

	label $lfname.1.llook -text "[trans encoding2]" -padx 10
	button $lfname.1.bencoding -text [trans encoding] -command "show_encodingchoose"
	pack $lfname.plook -anchor nw -side left
	pack $lfname.0 $lfname.1 -side top -padx 0 -pady 0 -expand 1 -fill both
	pack $lfname.1.llook -side left
	pack $lfname.1.bencoding -side right -padx 15
#	label $lfname.2.llook -text "[trans bgcolor]" -padx 10
#	button $lfname.2.bbgcolor -text [trans choosebgcolor] -font sboldf -command "choose_theme"
#	pack $lfname.2 -side top -padx 0 -pady 0 -expand 1 -fill both
#	pack $lfname.2.llook -side left	
#	pack $lfname.2.bbgcolor -side right -padx 15
	label $lfname.3.llook -text "[trans preffont3]" -padx 10
	button $lfname.3.bfont -text [trans changefont] -command "choose_basefont"
	pack $lfname.3 -side top -padx 0 -pady 0 -expand 1 -fill both
	pack $lfname.3.llook -side left
	pack $lfname.3.bfont -side right -padx 15
	label $lfname.4.llook -text "[trans dateformat]" -padx 10
	pack $lfname.4 -side top -padx 0 -pady 0 -expand 1 -fill both
	pack $lfname.4.llook -anchor w -side top -padx 10
	radiobutton $lfname.4.mdy -text "[trans month]/[trans day]/[trans year]" -value MDY -variable [::config::getVar dateformat]
	radiobutton $lfname.4.dmy -text "[trans day]/[trans month]/[trans year]" -value DMY -variable [::config::getVar dateformat]
	radiobutton $lfname.4.ymd -text "[trans year]/[trans month]/[trans day]" -value YMD -variable [::config::getVar dateformat]
	pack $lfname.4.mdy $lfname.4.dmy $lfname.4.ymd -side left -padx 10

	# Systray doesn't exist on Mac
	if { ![OnMac] } {
		checkbutton $lfname.5.dock -text "[trans trayicon]" -onvalue 1 -offvalue 0 -variable [::config::getVar use_tray]
		pack $lfname.5.dock -anchor w -side top -padx 10 -pady 0
	}

	checkbutton $lfname.5.show_contactdps_in_cl -text "[trans show_contactdps_in_cl]" -onvalue 1 -offvalue 0 -variable [::config::getVar show_contactdps_in_cl]
	checkbutton $lfname.5.show_spaces -text "[trans enablespaces]" -onvalue 1 -offvalue 0 -variable [::config::getVar showspaces]
	pack $lfname.5.show_contactdps_in_cl $lfname.5.show_spaces -anchor w -side top -padx 10 -pady 0

	pack $lfname.5 -side top -padx 0 -pady 10 -expand 1 -fill both

	label $lfname.6.llook -text "[trans psmplace]" -padx 10
	pack $lfname.6 -side top -padx 0 -pady 0 -expand 1 -fill both
	pack $lfname.6.llook -anchor w -side top -padx 10
	radiobutton $lfname.6.dontshow -text "[trans psmdontshow]" -value 0 -variable [::config::getVar psmplace]
	radiobutton $lfname.6.atend -text "[trans psmatend]" -value 1 -variable [::config::getVar psmplace]
	radiobutton $lfname.6.newline -text "[trans psmnewline]" -value 2 -variable [::config::getVar psmplace]
	pack $lfname.6.dontshow $lfname.6.atend $lfname.6.newline -anchor w -side top -padx 10
	checkbutton $lfname.7.cam_in_cw -text "[trans cam_in_cw]" -onvalue 1 -offvalue 0 -variable [::config::getVar cam_in_cw]
	pack $lfname.7 -side top -padx 0 -pady 0 -expand 1 -fill both
	pack $lfname.7.cam_in_cw -anchor w -side top -padx 10


	## Emoticons Frame ##
	set lfname [labelframe $frm.lfname2 -text [trans prefemotic]]
	pack $frm.lfname2 -anchor n -side top -expand 0 -fill x
	label $lfname.pemotic -image [::skin::loadPixmap prefemotic]
	pack $lfname.pemotic -side left -anchor nw
	frame $lfname.1
	pack $lfname.1 -side left -padx 0 -pady 0 -expand 1 -fill x
	checkbutton $lfname.1.chat -text "[trans chatsmileys2]" -onvalue 1 -offvalue 0 -variable [::config::getVar chatsmileys]
	checkbutton $lfname.1.list -text "[trans listsmileys2]" -onvalue 1 -offvalue 0 -variable [::config::getVar listsmileys]
        checkbutton $lfname.1.sound -text "[trans emotisounds]" -onvalue 1 -offvalue 0 -variable [::config::getVar emotisounds]
        checkbutton $lfname.1.animated -text "[trans animatedsmileys]" -onvalue 1 -offvalue 0 -variable [::config::getVar animatedsmileys] -command [list destroy .smile_selector]
	checkbutton $lfname.1.customsmileys -text "[trans customsmileys]" -onvalue 1 -offvalue 0 -variable [::config::getVar customsmileys]
	#checkbutton $lfname.1.log -text "[trans logsmileys]" -onvalue 1 -offvalue 0 -variable [::config::getVar logsmileys] -state disabled
	#pack $lfname.1.chat $lfname.1.list $lfname.1.sound  $lfname.1.animated $lfname.1.log -anchor w -side top -padx 10
	pack $lfname.1.chat $lfname.1.list $lfname.1.sound  $lfname.1.animated $lfname.1.customsmileys -anchor w -side top -padx 10 -pady 0

	## Alerts and Sounds Frame ##
	set lfname [labelframe $frm.lfname3 -text [trans prefalerts]]
	pack $frm.lfname3 -anchor n -side top -expand 0 -fill x
	label $lfname.palerts -image [::skin::loadPixmap prefalerts]
	pack $lfname.palerts -side left -anchor nw
	frame $lfname.1
	checkbutton $lfname.1.alert1 -text "[trans shownotify]" -onvalue 1 -offvalue 0 -variable [::config::getVar shownotify]
	checkbutton $lfname.1.sound -text "[trans sound2]" -onvalue 1 -offvalue 0 -variable [::config::getVar sound]
	pack $lfname.1 -anchor w -side top -padx 0 -pady 5 -expand 1 -fill both
	pack $lfname.1.alert1 $lfname.1.sound -anchor w -side top -padx 10 -pady 0
	
	#Bounce icon in the dock preference for Mac OS X
	if { [OnMac] } {
		label $lfname.1.bouncedock -text "[trans bouncedock]" -padx 10
		pack $lfname.1.bouncedock -anchor w -side top -padx 10
		radiobutton $lfname.1.unlimited -text "[trans continuously]" -value unlimited -variable [::config::getVar dockbounce]
		radiobutton $lfname.1.once -text "[trans justonce]" -value once -variable [::config::getVar dockbounce]
		radiobutton $lfname.1.never -text "[trans never]" -value never -variable [::config::getVar dockbounce]
		pack $lfname.1.unlimited $lfname.1.once $lfname.1.never -side left -padx 10
	}
	$nb.nn compute_size
	[$nb.nn getframe appearance].sw.sf compute_size
	

	#  .---------.
	# _| Session |________________________________________________
	::skin::setPixmap prefstatus prefstatus.gif
	::skin::setPixmap prefaway prefaway.gif
	::skin::setPixmap prefmsg prefmsg.gif

	#set frm [Rnotebook:frame $nb $Preftabs(session)]
	set frm [$nb.nn getframe session]
	#Scrollable frame that will contain options
	ScrolledWindow $frm.sw
	ScrollableFrame $frm.sw.sf -constrainedwidth 1
	$frm.sw setwidget $frm.sw.sf
	pack $frm.sw -anchor n -side top -expand true -fill both
	set frm [$frm.sw.sf getframe]	
	
	## Sign In and AutoStatus Options Frame ##
	set lfname [labelframe $frm.lfname -text [trans prefsession]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.psession -image [::skin::loadPixmap prefstatus]
	pack $lfname.psession -anchor nw -side left
	frame $lfname.1
	frame $lfname.2
	frame $lfname.3
	checkbutton $lfname.1.lautonoact -text "[trans autonoact]" -onvalue 1 -offvalue 0 -variable [::config::getVar autoidle] -command UpdatePreferences
	entry $lfname.1.eautonoact -font splainf -width 3 -textvariable [::config::getVar idletime]
	label $lfname.1.lmins -text "[trans mins]" -padx 5
	pack $lfname.1 -side top -padx 0 -expand 1 -fill both
	pack $lfname.1.lautonoact $lfname.1.eautonoact $lfname.1.lmins -side left
	checkbutton $lfname.2.lautoaway -text "[trans autoaway]" -onvalue 1 -offvalue 0 -variable [::config::getVar autoaway] -command UpdatePreferences
	entry $lfname.2.eautoaway -font splainf -width 3 -textvariable [::config::getVar awaytime]
	label $lfname.2.lmins -text "[trans mins]" -padx 5
	pack $lfname.2 -side top -padx 0 -expand 1 -fill both
	pack $lfname.2.lautoaway $lfname.2.eautoaway $lfname.2.lmins -side left
	checkbutton $lfname.3.lreconnect -text "[trans reconnect2]" -onvalue 1 -offvalue 0 -variable [::config::getVar reconnect]
	checkbutton $lfname.3.lonstart -text "[trans autoconnect2]" -onvalue 1 -offvalue 0 -variable [::config::getVar autoconnect]
		
	if { [OnWin] } { 
		set ::start_on_windows_boot [WinDetectBoot]
		checkbutton $lfname.3.startonboot -text "[trans startonboot]" -onvalue 1 -offvalue 0 -variable ::start_on_windows_boot
	}
	
	pack $lfname.3 -side top -padx 0 -expand 1 -fill both

	if { [OnWin] } { 
		pack $lfname.3.lreconnect $lfname.3.lonstart $lfname.3.startonboot  -anchor w -side top
	} else {
		pack $lfname.3.lreconnect $lfname.3.lonstart -anchor w -side top       
	}

	## Away Messages Frame ##
	set lfname [labelframe $frm.lfname2 -text [trans prefawaymsg]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.psession -image [::skin::loadPixmap prefaway]
	pack $lfname.psession -anchor nw -side left
	frame $lfname.statelist -relief sunken -borderwidth 3
	listbox $lfname.statelist.box -yscrollcommand "$lfname.statelist.ys set" \
		-font splainf -highlightthickness 0 -height 4
	scrollbar $lfname.statelist.ys -command "$lfname.statelist.box yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
	pack $lfname.statelist.ys -side right -fill y
	pack $lfname.statelist.box -side left -expand true -fill both
	frame $lfname.buttons -borderwidth 0
	button $lfname.buttons.add -text [trans addstate] -command "EditNewState 0" -width 20
	button $lfname.buttons.del -text [trans delete]  -command "DeleteStateListBox \[$lfname.statelist.box curselection\] $lfname.statelist.box" -width 20
	button $lfname.buttons.edit -text [trans edit]  -command "EditNewState 2 \[$lfname.statelist.box curselection\]" -width 20
	pack $lfname.buttons.add -side top
	pack $lfname.buttons.del -side top
	pack $lfname.buttons.edit -side top
	pack $lfname.statelist -anchor w -side left -padx 10 -pady 10 -expand 1 -fill both
	pack $lfname.buttons -anchor w -side right -padx 10 -pady 10 -expand 1 -fill both

	## Messaging Interface Frame ##
	set lfname [labelframe $frm.lfname3 -text [trans prefmsging]]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.pmsging -image [::skin::loadPixmap prefmsg]
	pack $lfname.pmsging -anchor nw -side left
	frame $lfname.1
	frame $lfname.2
	frame $lfname.3
	frame $lfname.4
	frame $lfname.5
	
	label $lfname.1.lchatmaxmin -text [trans chatmaxmin]
	radiobutton $lfname.1.max -text [trans raised] -value 0 -variable [::config::getVar newchatwinstate] -padx 17
	grid $lfname.1.lchatmaxmin -row 1 -column 1 -sticky w
	
	#Don't show the minimised option on Mac OS X because that does'nt work in TkAqua
	if { ![OnMac] } {
		radiobutton $lfname.1.min -text [trans minimised] -value 1 -variable [::config::getVar newchatwinstate] -padx 17
	}
	
	radiobutton $lfname.1.no -text [trans dontshow] -value 2 -variable [::config::getVar newchatwinstate]  -padx 17
	
	#Don't pack the minimised option on Mac OS X because that does'nt work in TkAqua
	if { [OnMac] } {
		grid $lfname.1.max -row 2 -column 1 -sticky w
		grid $lfname.1.no -row 3 -column 1 -sticky w
	} else {
		grid $lfname.1.max -row 2 -column 1 -sticky w
		grid $lfname.1.min -row 3 -column 1 -sticky w
		grid $lfname.1.no -row 4 -column 1 -sticky w
	}
	
	#Don't enable this option on Mac OS X because we can't minimized window this way with TkAqua
	if { ![OnMac] } {
		label $lfname.2.lmsgmaxmin -text [trans msgmaxmin]
		radiobutton $lfname.2.max -text [trans raised] -value 0 -variable [::config::getVar newmsgwinstate] -padx 17
		radiobutton $lfname.2.min -text [trans minimised] -value 1 -variable [::config::getVar newmsgwinstate] -padx 17
		
		grid $lfname.2.lmsgmaxmin -row 1 -column 1 -sticky w
		grid $lfname.2.max -row 2 -column 1 -sticky w
		grid $lfname.2.min -row 3 -column 1 -sticky w
	}
	
	label $lfname.3.lmsgmode -text [trans msgmode] 
	radiobutton $lfname.3.nottabbed -text [trans nottabbed] -value 0 -variable [::config::getVar tabbedchat] -padx 17
	radiobutton $lfname.3.tabbedglobal -text [trans tabbedglobal] -value 1 -variable [::config::getVar tabbedchat] -padx 17
	radiobutton $lfname.3.tabbedgroups -text [trans tabbedgroups] -value 2 -variable [::config::getVar tabbedchat] -padx 17
	
	label $lfname.4.containermode -text [trans closelabel]
	radiobutton $lfname.4.containerask -text [trans askeachtime] -value 0 -variable [::config::getVar ContainerCloseAction] -padx 17
	radiobutton $lfname.4.containercloseall -text [trans closealltabs] -value 1 -variable [::config::getVar ContainerCloseAction] -padx 17
	radiobutton $lfname.4.containerclosetab -text [trans closeonly] -value 2 -variable [::config::getVar ContainerCloseAction] -padx 17
	
	label $lfname.5.logoutwinclosemode -text [trans logoutwincloselabel]
	radiobutton $lfname.5.logoutwincloseask -text [trans askeachtime] -value 0 -variable [::config::getVar closeChatWindowsAfterLogout] -padx 17
	radiobutton $lfname.5.logoutwinclosealways -text [trans always] -value 1 -variable [::config::getVar closeChatWindowsAfterLogout] -padx 17
	radiobutton $lfname.5.logoutwinclosenever -text [trans never] -value 2 -variable [::config::getVar closeChatWindowsAfterLogout] -padx 17
	
	grid $lfname.3.lmsgmode  -row 1 -column 1 -sticky w
	grid $lfname.3.nottabbed -row 2 -column 1 -sticky w
	grid $lfname.3.tabbedglobal -row 3 -column 1 -sticky w
	grid $lfname.3.tabbedgroups -row 4 -column 1 -sticky w
	
	grid $lfname.4.containermode  -row 1 -column 1 -sticky w
	grid $lfname.4.containerask -row 2 -column 1 -sticky w
	grid $lfname.4.containercloseall -row 3 -column 1 -sticky w
	grid $lfname.4.containerclosetab -row 4 -column 1 -sticky w	
	
	grid $lfname.5.logoutwinclosemode -row 1 -column 1 -sticky w
	grid $lfname.5.logoutwincloseask -row 2 -column 1 -sticky w
	grid $lfname.5.logoutwinclosealways -row 3 -column 1 -sticky w
	grid $lfname.5.logoutwinclosenever -row 4 -column 1 -sticky w	
	
	checkbutton $lfname.winflicker -text "[trans msgflicker]" -onvalue 1 -offvalue 0 -variable [::config::getVar flicker]
	checkbutton $lfname.showdisplaypic -text "[trans showdisplaypic2]" -onvalue 1 -offvalue 0 -variable [::config::getVar showdisplaypic]

	pack $lfname.1 $lfname.2 $lfname.3 $lfname.4 $lfname.5 $lfname.winflicker $lfname.showdisplaypic -anchor w -side top

	$nb.nn compute_size
	[$nb.nn getframe session].sw.sf compute_size

	
	#  .------------------.
	# _| Group Management |_______________________________________
	
	::skin::setPixmap prefpersc prefpers.gif
	::skin::setPixmap prefprofilec prefprofile.gif
	::skin::setPixmap prefmobile prefmobile.gif	
		
	set frm [$nb.nn getframe groups]
	ScrolledWindow $frm.sw
	ScrollableFrame $frm.sw.sf -constrainedwidth 1
	$frm.sw setwidget $frm.sw.sf
	pack $frm.sw -anchor n -side top -expand true -fill both
	set frm [$frm.sw.sf getframe]

	## Mobile group ##
	set lfmobile [labelframe $frm.lfmobile -text [trans mobilegrp1]]
	pack $frm.lfmobile -anchor n -side top -expand 1 -fill x
	label $lfmobile.lbmobile -image [::skin::loadPixmap prefmobile]
	pack $lfmobile.lbmobile -side left -padx 5 -pady 5 
	checkbutton $lfmobile.btmobile -text "[trans mobilegrp2]" -onvalue 1 -offvalue 0 \
		-variable [::config::getVar showMobileGroup]
	pack $lfmobile.btmobile  -anchor w -side left -padx 0 -pady 5 

	#compute_size
	$nb.nn compute_size
	[$nb.nn getframe groups].sw.sf compute_size


	#  .--------.
	# _| Loging |________________________________________________
	::skin::setPixmap prefhist prefhist.gif
	::skin::setPixmap prefhist2 prefhist2.gif
#	::skin::setPixmap prefhist3 prefhist3.gif

	#set frm [Rnotebook:frame $nb $Preftabs(loging)]
	set frm [$nb.nn getframe loging]
	ScrolledWindow $frm.sw
	ScrollableFrame $frm.sw.sf -constrainedwidth 1
	$frm.sw setwidget $frm.sw.sf
	pack $frm.sw -anchor n -side top -expand true -fill both
	set frm [$frm.sw.sf getframe]	

	## Loging Options Frame ##
	set lfname [labelframe $frm.lfname -text [trans preflog1]]
	pack $frm.lfname -anchor n -side top -expand 0 -fill x
	label $lfname.plog1 -image [::skin::loadPixmap prefhist]
	pack $lfname.plog1 -anchor nw -side left
	checkbutton $lfname.log -text "[trans keeplog2]" -onvalue 1 -offvalue 0 -variable [::config::getVar keep_logs]
	checkbutton $lfname.date -text "[trans logsbydate]" -onvalue 1 -offvalue 0 -variable [::config::getVar logsbydate]
	checkbutton $lfname.camlog -text "[trans logwebcam]" -onvalue 1 -offvalue 0 -variable [::config::getVar webcamlogs]
	pack $lfname.log -anchor w
	pack $lfname.camlog -anchor w
	pack $lfname.date -anchor w

#/////////TODO Add style log feature
#	frame $lfname.2 -class Degt
#	label $lfname.2.lstyle -text "[trans stylelog]" -padx 10
#	radiobutton $lfname.2.hist -text [trans stylechat] -value 1 -variable [::config::getVar logstyle] -state disabled
#	radiobutton $lfname.2.chat -text [trans stylehist] -value 2 -variable [::config::getVar logstyle] -state disabled
#	pack $lfname.2.lstyle -anchor w -side top -padx 10
#	pack $lfname.2.hist $lfname.2.chat -side left -padx 10
#	pack $lfname.2 -anchor w -side top -expand 1 -fill x
	
	## Clear All Logs Frame ##
	set lfname [labelframe $frm.lfname2 -text [trans clearlog]]
	pack $frm.lfname2 -anchor n -side top -expand 0 -fill x
	label $lfname.plog1 -image [::skin::loadPixmap prefhist2]
	pack $lfname.plog1 -anchor nw -side left
	frame $lfname.1
	label $lfname.1.lclear -text "[trans clearlog2]" -padx 10
	button $lfname.1.bclear -text [trans clearlog3]  -command "::log::ClearAllLogs"
	button $lfname.1.camclear -text [trans clearwebcamlogs] -command "::log::ClearAllCamLogs"
	pack $lfname.1.lclear -side left	
	pack $lfname.1.bclear -side right -padx 15
	pack $lfname.1.camclear -side right -padx 15
	pack $lfname.1 -anchor w -side top -expand 0 -fill x
#////////TODO: Add logs expiry feature
	## Logs Expiry Frame ##
#	set lfname [labelframe $frm.lfname3 -text [trans logfandexp]]
#	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
#	label $lfname.plog1 -image [::skin::loadPixmap prefhist3]
#	pack $lfname.plog1 -anchor nw -side left
#	frame $lfname.1 -class Degt
#	checkbutton $lfname.1.lolder -text "[trans logolder]" -onvalue 1 -offvalue 0 -variable [::config::getVar logexpiry] -state disabled
#	entry $lfname.1.eolder -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 3 -state disabled
#	label $lfname.1.ldays -text "[trans days]" -padx 5
#	pack $lfname.1 -side top -padx 0 -expand 1 -fill both
#	pack $lfname.1.lolder $lfname.1.eolder $lfname.1.ldays -side left
#	frame $lfname.2 -class Degt
#	checkbutton $lfname.2.lbigger -text "[trans logbigger]" -onvalue 1 -offvalue 0 -variable [::config::getVar logmaxsize] -state disabled
#	entry $lfname.2.ebigger -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 3 -state disabled
#	label $lfname.2.lmbs -text "MBs" -padx 5
#	pack $lfname.2 -side top -padx 0 -expand 1 -fill both
#	pack $lfname.2.lbigger $lfname.2.ebigger $lfname.2.lmbs -side left


	## Eventlogging frame ## ***
	set lfname [labelframe $frm.lfname3 -text [trans preflogevent]]
	pack $frm.lfname3 -anchor n -side top -expand 0 -fill x
	label $lfname.plog1
	grid $lfname.plog1 -columnspan 2
	checkbutton $lfname.displayconnect -text "[trans displayeventconnect]" -onvalue 1 -offvalue 0 -variable [::config::getVar display_event_connect]
	checkbutton $lfname.displaydisconnect -text "[trans displayeventdisconnect]" -onvalue 1 -offvalue 0 -variable [::config::getVar display_event_disconnect]
	checkbutton $lfname.displayemail -text "[trans displayeventemail]" -onvalue 1 -offvalue 0 -variable [::config::getVar display_event_email]
	checkbutton $lfname.displaystate -text "[trans displayeventstate]" -onvalue 1 -offvalue 0 -variable [::config::getVar display_event_state]
	checkbutton $lfname.displaynick -text "[trans displayeventnick]" -onvalue 1 -offvalue 0 -variable [::config::getVar display_event_nick]
	checkbutton $lfname.displaypsm -text "[trans displayeventpsm]" -onvalue 1 -offvalue 0 -variable [::config::getVar display_event_psm]
	checkbutton $lfname.logconnect -text "[trans logeventconnect]" -onvalue 1 -offvalue 0 -variable [::config::getVar log_event_connect]
	checkbutton $lfname.logdisconnect -text "[trans logeventdisconnect]" -onvalue 1 -offvalue 0 -variable [::config::getVar log_event_disconnect]
	checkbutton $lfname.logemail -text "[trans logeventemail]" -onvalue 1 -offvalue 0 -variable [::config::getVar log_event_email]
	checkbutton $lfname.logstate -text "[trans logeventstate]" -onvalue 1 -offvalue 0 -variable [::config::getVar log_event_state]
	checkbutton $lfname.lognick -text "[trans logeventnick]" -onvalue 1 -offvalue 0 -variable [::config::getVar log_event_nick]
	checkbutton $lfname.logpsm -text "[trans logeventpsm]" -onvalue 1 -offvalue 0 -variable [::config::getVar log_event_psm]
	grid $lfname.displayconnect -row 0 -column 0 -sticky w
	grid $lfname.displaydisconnect -row 1 -column 0 -sticky w
	grid $lfname.displayemail -row 2 -column 0 -sticky w
	grid $lfname.displaystate -row 3 -column 0 -sticky w
	grid $lfname.displaynick -row 4 -column 0 -sticky w
	grid $lfname.displaypsm -row 5 -column 0 -sticky w
	grid $lfname.logconnect -row 0 -column 1 -sticky w
	grid $lfname.logdisconnect -row 1 -column 1 -sticky w
	grid $lfname.logemail -row 2 -column 1 -sticky w
	grid $lfname.logstate -row 3 -column 1 -sticky w
	grid $lfname.lognick -row 4 -column 1 -sticky w
	grid $lfname.logpsm -row 5 -column 1 -sticky w


	#  .------------.
	# _| Connection |________________________________________________
	
	::skin::setPixmap prefnat prefnat.gif
	::skin::setPixmap prefproxy prefproxy.gif
	::skin::setPixmap prefremote prefpers.gif

	#set frm [Rnotebook:frame $nb $Preftabs(connection)]
	set frm [$nb.nn getframe connection]
	#Scrollable frame that will contain options
	ScrolledWindow $frm.sw
	ScrollableFrame $frm.sw.sf -constrainedwidth 1
	$frm.sw setwidget $frm.sw.sf
	pack $frm.sw -anchor n -side top -expand true -fill both
	set frm [$frm.sw.sf getframe]	
	
	## Connection Frame ##
	set lfname [labelframe $frm.lfnameconnection -text [trans prefconnection]]
	pack $frm.lfnameconnection -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image [::skin::loadPixmap prefproxy]
	pack $lfname.pshared -side left -anchor nw	
	
	frame $lfname.1
	frame $lfname.2
	frame $lfname.3
	frame $lfname.4
	frame $lfname.5
	radiobutton $lfname.1.direct -text "[trans directconnection]" -value direct -variable [::config::getVar connectiontype] -command UpdatePreferences
	pack $lfname.1.direct -anchor w -side top -padx 10
	radiobutton $lfname.2.http -text "[trans httpconnection]" -value http -variable [::config::getVar connectiontype] -command UpdatePreferences
	pack $lfname.2.http -anchor w -side top -padx 10
	radiobutton $lfname.3.proxy -text "[trans proxyconnection]" -value proxy -variable [::config::getVar connectiontype] -command UpdatePreferences
	pack $lfname.3.proxy -anchor w -side top -padx 10

	#checkbutton $lfname.1.proxy -text "[trans proxy]" -onvalue 1 -offvalue 0 -variable [::config::getVar withproxy]
	#pack $lfname.1.proxy -anchor w -side top -padx 10

	#radiobutton $lfname.2.http -text "HTTP" -value http -variable [::config::getVar proxytype]
	#radiobutton $lfname.2.socks5 -text "SOCKS5" -value socks -variable [::config::getVar proxytype] -state disabled
	#pack $lfname.2.http $lfname.2.socks5 -anchor w -side left -padx 10

	pack $lfname.1 $lfname.2 $lfname.3 $lfname.4 $lfname.5 -anchor w -side top -padx 0 -pady 0 -expand 1 -fill both

	radiobutton $lfname.4.post -text "HTTP (POST method)" -value http -variable [::config::getVar proxytype] -command UpdatePreferences
	radiobutton $lfname.4.ssl -text "SSL (CONNECT method)" -value ssl -variable [::config::getVar proxytype] -command UpdatePreferences
	radiobutton $lfname.4.socks5 -text "SOCKS5" -value socks5 -variable [::config::getVar proxytype] -command UpdatePreferences 

	grid $lfname.4.post -row 1 -column 1 -sticky w -pady 5 -padx 10
	grid $lfname.4.ssl -row 1 -column 2 -sticky w -pady 5 -padx 10
	grid $lfname.4.socks5 -row 1 -column 3 -sticky w -pady 5 -padx 10

		
	label $lfname.5.lserver -text "[trans server] :" -padx 5 -font sboldf
	entry $lfname.5.server -font splainf  -width 20 -textvariable proxy_server
	label $lfname.5.lport -text "[trans port] :" -padx 5 -font sboldf
	entry $lfname.5.port -font splainf  -width 5 -textvariable proxy_port
	label $lfname.5.luser -text "[trans user] :" -padx 5 -font sboldf
	entry $lfname.5.user -font splainf  -width 20 -textvariable proxy_user
	label $lfname.5.lpass -text "[trans pass] :" -padx 5 -font sboldf
	entry $lfname.5.pass -font splainf  -width 20 -show "*" -textvariable proxy_pass
	grid $lfname.5.lserver -row 2 -column 1 -sticky e
	grid $lfname.5.server -row 2 -column 2 -sticky w -pady 5
	grid $lfname.5.lport -row 2 -column 3 -sticky e
	grid $lfname.5.port -row 2 -column 4 -sticky w -pady 5
	grid $lfname.5.luser -row 3 -column 1 -sticky e
	grid $lfname.5.user -row 3 -column 2 -sticky w
	grid $lfname.5.lpass -row 3 -column 3 -sticky e
	grid $lfname.5.pass -row 3 -column 4 -sticky w

	## NAT (or similar) Frame ##
	set lfname [labelframe $frm.lfname -text [trans prefft]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image [::skin::loadPixmap prefnat]
	pack $lfname.pshared -side left -anchor nw
	frame $lfname.1
	pack $lfname.1 -side left -padx 0 -pady 5 -expand 1 -fill both

	label $lfname.1.conntype -padx 5 -font splainf -text "[trans type]: [::abook::getDemographicField conntype]"
	label $lfname.1.listening -padx 5 -font splainf
	if { [::abook::getDemographicField conntype] == "" } {
		$lfname.1.listening configure -text  "[trans connectfirst]" -fg [::skin::getKey extrastderrcolor]
	} else {
		if { [::abook::getDemographicField listening] == "false"} {
			$lfname.1.listening configure -text "[trans firewalled]" -fg [::skin::getKey extrastderrcolor]
		} else {
			$lfname.1.listening configure -text "[trans portswellconfigured]" -fg [::skin::getKey extrastdokcolor]

		}
	}
	pack $lfname.1.conntype $lfname.1.listening -anchor w -side top -padx 10

	frame $lfname.1.ftport
	label $lfname.1.ftport.text -text "[trans ftportpref2] :" -padx 5 -font splainf
	entry $lfname.1.ftport.entry -font splainf  -width 5 -textvariable [::config::getVar initialftport]
	button $lfname.1.ftport.bttest -text "[trans ftporttest]" -padx 5 -font splainf -command [list after 0 connection_check $lfname] 
	label $lfname.1.ftport.test -text "" -padx 5 -font splainf
	grid $lfname.1.ftport.text -row 1 -column 1 -sticky w -pady 5 -padx 0 -columnspan 3
	grid $lfname.1.ftport.entry -row 2 -column 1 -sticky w -pady 5 -padx [list 20 3]
	grid $lfname.1.ftport.bttest -row 2 -column 2 -sticky w -pady 5 -padx 3
	grid $lfname.1.ftport.test -row 2 -column 3 -sticky w -pady 5 -padx 3

	checkbutton $lfname.1.autoip -text "[trans autodetectip]" -onvalue 1 -offvalue 0 -variable [::config::getVar autoftip] -command UpdatePreferences
	frame $lfname.1.ipaddr
	label $lfname.1.ipaddr.text -text "[trans ipaddress] :" -padx 5 -font splainf
	entry $lfname.1.ipaddr.entry -font splainf  -width 15 -textvariable [::config::getVar manualip]
	grid $lfname.1.ipaddr.text -row 1 -column 1 -sticky w -pady 5 -padx 0
	grid $lfname.1.ipaddr.entry -row 1 -column 2 -sticky w -pady 5 -padx 3	
		
	checkbutton $lfname.1.autoaccept -text "[trans autoacceptft]" -onvalue 1 -offvalue 0 -variable [::config::getVar ftautoaccept]

	pack $lfname.1.ftport $lfname.1.autoip $lfname.1.ipaddr $lfname.1.autoaccept -anchor w -side top -padx 10
	
	    
	## Remote Control Frame ##
	set lfname [labelframe $frm.lfname3 -text [trans prefremote]]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image [::skin::loadPixmap prefremote]
	pack $lfname.pshared -side left -anchor nw
	frame $lfname.1
	frame $lfname.2
	pack $lfname.1 -side left -padx 0 -pady 5 -expand 1 -fill both
	checkbutton $lfname.1.eremote -text "[trans enableremote]" -onvalue 1 -offvalue 0 -variable [::config::getVar enableremote] -command UpdatePreferences
	pack $lfname.1.eremote  -anchor w -side top -padx 10
	pack $lfname.1 $lfname.2  -anchor w -side top -padx 0 -pady 0 -expand 1 -fill both
	label $lfname.2.lpass -text "[trans pass] :" -padx 5 -font sboldf
	entry $lfname.2.pass -font splainf  -width 20 -show "*"
	grid $lfname.2.lpass -row 2 -column 3 -sticky e
	grid $lfname.2.pass -row 2 -column 4 -sticky w

	$nb.nn compute_size
	[$nb.nn getframe connection].sw.sf compute_size

	#  .--------.
	# _| Others |________________________________________________
	::skin::setPixmap prefapps prefpers.gif

	#set frm [Rnotebook:frame $nb $Preftabs(others)]
	set frm [$nb.nn getframe others]
	
	#Scrollable frame that will contain options
	ScrolledWindow $frm.sw
	ScrollableFrame $frm.sw.sf -constrainedwidth 1
	$frm.sw setwidget $frm.sw.sf
	pack $frm.sw -anchor n -side top -expand true -fill both
	set frm [$frm.sw.sf getframe]	
	
	## Delete Profiles Frame ##
	set lfname [labelframe $frm.lfname3 -text [trans prefprofile3]]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.pprofile -image [::skin::loadPixmap prefapps]
	pack $lfname.pprofile -side left -anchor nw
	frame $lfname.1
	label $lfname.1.ldelprofile -text "[trans delprofile2]" -font sboldf -padx 5
	combobox::combobox $lfname.1.profile -editable true -width 22 
	button $lfname.1.bdel -text [trans delprofile] -command "DeleteProfile \[${lfname}.1.profile get\] $lfname.1.profile"
	grid $lfname.1.ldelprofile -row 1 -column 1 -sticky w
	grid $lfname.1.profile -row 1 -column 2 -sticky w
	grid $lfname.1.bdel -row 1 -column 3 -padx 5 -sticky w
	pack $lfname.1 -anchor w -side top -expand 0 -fill none
		
	## Applications Frame ##
	set lfname [labelframe $frm.lfname -text [trans prefapps]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image [::skin::loadPixmap prefapps]
	pack $lfname.pshared -side left -anchor nw
	frame $lfname.1
	pack $lfname.1 -anchor w -side left -padx 0 -pady 5 -expand 0 -fill both
	
	#Don't change filemanager and open file manager on Mac OS X
	if { ![OnMac] } {
		label $lfname.1.lbrowser -text "[trans browser] :" -padx 5 -font sboldf
		entry $lfname.1.browser -width 40 -textvariable [::config::getVar browser]
		label $lfname.1.lbrowserex -text "[trans browserexample]" -font examplef
		#file manager
		label $lfname.1.lfileman -text "[trans fileman] :" -padx 5 -font sboldf
		entry $lfname.1.fileman -width 40 -textvariable [::config::getVar filemanager]
		label $lfname.1.lfilemanex -text "[trans filemanexample]" -font examplef
		#open file command
		label $lfname.1.lopenfile -text "[trans openfilecommand] :" -padx 5 -font sboldf
		entry $lfname.1.openfile -width 40 -textvariable [::config::getVar openfilecommand]
		label $lfname.1.lopenfileex -text "(Gnome: gnome-open \$file) (KDE: kfmclient exec \$file)" -font examplef
	}
	
	label $lfname.1.lmailer -text "[trans mailer] :" -padx 5 -font sboldf
	entry $lfname.1.mailer -width 40 -textvariable [::config::getVar mailcommand]
	label $lfname.1.lmailerex -text "[trans mailerexample]" -font examplef
	
	#aMSN for Mac OS X always use "QuickTimeTCL" (except in Alarms) so don't let mac user choose sound player
	if { ![OnMac] } {
		label $lfname.1.lsound -text "[trans soundserver] :" -padx 5 -font sboldf
		frame $lfname.1.sound
	
		radiobutton $lfname.1.sound.snack -text "[trans usesnack]" -value 1 -variable [::config::getVar usesnack] -command UpdatePreferences
		pack $lfname.1.sound.snack -anchor w -side top -padx 10
		radiobutton $lfname.1.sound.other -text "[trans useother]" -value 0 -variable [::config::getVar usesnack] -command UpdatePreferences
		pack $lfname.1.sound.other -anchor w -side top -padx 10
		entry $lfname.1.sound.sound -width 40 -textvariable [::config::getVar soundcommand]
		pack $lfname.1.sound.sound -anchor w -side top -padx 10
		label $lfname.1.sound.lsoundex -text "[trans soundexample]" -font examplef
		pack $lfname.1.sound.lsoundex -anchor w -side top -padx 10
		grid $lfname.1.lbrowser -row 1 -column 1 -sticky w
		grid $lfname.1.browser -row 1 -column 2 -sticky w
		grid $lfname.1.lbrowserex -row 2 -column 2 -columnspan 1 -sticky w

	}
	

	#aMSN for Mac OS X always use "QuickTimeTCL" (except in Alarms) so don't let mac user choose sound player
	#because we don't change filemanager and open file manager on Mac OS X
	if { [OnMac] } {
		grid $lfname.1.lmailer -row 7 -column 1 -sticky w
		grid $lfname.1.mailer -row 7 -column 2 -sticky w
		grid $lfname.1.lmailerex -row 8 -column 2 -columnspan 1 -sticky w
	} else {
		grid $lfname.1.lfileman -row 3 -column 1 -sticky w
		grid $lfname.1.fileman -row 3 -column 2 -sticky w
		grid $lfname.1.lfilemanex -row 4 -column 2 -columnspan 1 -sticky w
	
		grid $lfname.1.lopenfile -row 5 -column 1 -sticky w
		grid $lfname.1.openfile -row 5 -column 2 -sticky w
		grid $lfname.1.lopenfileex -row 6 -column 2 -columnspan 1 -sticky w
			
		grid $lfname.1.lmailer -row 7 -column 1 -sticky w
		grid $lfname.1.mailer -row 7 -column 2 -sticky w
		grid $lfname.1.lmailerex -row 8 -column 2 -columnspan 1 -sticky w
		
		grid $lfname.1.lsound -row 9 -column 1 -sticky nw
		grid $lfname.1.sound -row 9 -column 2 -sticky w
		#grid $lfname.1.lsoundex -row 10 -column 2 -columnspan 1 -sticky w
	}
	

	## File transfert directory frame ##
	set lfname [labelframe $frm.lfname4 -text [trans receiveddir]]
	pack $frm.lfname4 -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image [::skin::loadPixmap prefapps]
	pack $lfname.pshared -side left -anchor nw

	frame $lfname.1
	pack $lfname.1 -anchor w -side left -padx 0 -pady 5 -fill none
	label $lfname.1.receivedpath -text [trans receiveddir] -padx 5 -font sboldf
	entry $lfname.1.receiveddir -width 45  -textvariable [::config::getVar receiveddir]
	button $lfname.1.browse -text [trans browse] -command "Browse_Dialog_dir [::config::getVar receiveddir]"

	grid $lfname.1.receivedpath -row 1 -column 1 -sticky w
	grid $lfname.1.receiveddir -row 1 -column 2 -sticky w
	grid $lfname.1.browse -row 1 -column 3 -sticky w
	
	set lfname [labelframe $frm.lfname5 -text [trans audiovideo]]
	pack $frm.lfname5 -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image [::skin::loadPixmap webcam]
	pack $lfname.pshared -side left -anchor nw
	
	frame $lfname.1
	pack $lfname.1 -anchor w -side left -padx 0 -pady 5 -fill none
	button $lfname.1.webcam -text [trans editavsettings] -command [list ::AVAssistant::AVAssistant] -padx 20
	grid $lfname.1.webcam -row 1 -column 3 -sticky w -padx 20

	$nb.nn compute_size
	[$nb.nn getframe others].sw.sf compute_size

	#  .----------.
	# _| Advanced |________________________________________________

	#set frm [Rnotebook:frame $nb $Preftabs(advanced)]
	set frm [$nb.nn getframe advanced]
	
	set lfname [labelframe $frm.lfname -text [trans advancedprefs]]
	
	#Scrollable frame that will contain advanced optoins
	ScrolledWindow $lfname.sw
	ScrollableFrame $lfname.sw.sf -constrainedwidth 1
	$lfname.sw setwidget $lfname.sw.sf
	set path [$lfname.sw.sf getframe]	

	# search box
	set searchfrm [frame $frm.searchframe]
	label $searchfrm.searchlabel -text "[trans searchadvprefs]" -anchor ne
	entry $searchfrm.searchfield -bg #FFFFFF -width 20 -validate key -vcmd "filter_prefs $path %P %d"

	pack $searchfrm.searchfield -anchor ne -side right
	pack $searchfrm.searchlabel -anchor ne -side right
	pack $searchfrm -anchor n -side top -fill x

	pack $frm.lfname -anchor n -side top -expand true -fill both
	pack $lfname.sw -anchor n -side top -expand true -fill both
	
	advanced_options_reload $path

	#add bindings to scroll with mousewheel
	#can not use local variables in bind scripts with {}. 
	#and with "", can not use %D  :(
	# Mac OS X and Windows
	if { [OnMac] } {
	    bind .cfg <MouseWheel> {
		    set w [.cfg.notebook.nn getframe [.cfg.notebook.nn raise]]
		    if { [winfo exists $w.sw.sf] } {
			    $w.sw.sf yview scroll [expr {- (%D)}] units   
		    } elseif { [winfo exists $w.lfname.sw.sf] } {
			    $w.lfname.sw.sf yview scroll [expr {- (%D)}] units
		    }
	    } 
	} elseif { [OnWin] } {
	    bind .cfg <MouseWheel> {
		    set w [.cfg.notebook.nn getframe [.cfg.notebook.nn raise]]
		    if { [winfo exists $w.sw.sf] } {
			    $w.sw.sf yview scroll [expr {%D/-120}] units  
		    } elseif { [winfo exists $w.lfname.sw.sf] } {
			    $w.lfname.sw.sf yview scroll [expr {%D/-120}] units
		    }
	    }
	} elseif { [OnX11] } {
	    bind .cfg <5> {
		    set w [.cfg.notebook.nn getframe [.cfg.notebook.nn raise]]
		    if { [winfo exists $w.sw.sf] } {
			    $w.sw.sf yview scroll +1 units   
		    } elseif { [winfo exists $w.lfname.sw.sf] } {
			    $w.lfname.sw.sf yview scroll +1 units
		    }
	    }
	    bind .cfg <4> {
		    set w [.cfg.notebook.nn getframe [.cfg.notebook.nn raise]]
		    if { [winfo exists $w.sw.sf] } {
			    $w.sw.sf yview scroll -1 units   
		    } elseif { [winfo exists $w.lfname.sw.sf] } {
			    $w.lfname.sw.sf yview scroll -1 units
		    }
	    }
	}

	frame $path.2
	label $path.2.delimiters -text "[trans delimiters]" -padx 5
	entry $path.2.ldelimiter -font splainf -width 3 -textvariable [::config::getVar leftdelimiter]
	label $path.2.example -text "HH:MM:SS" -padx 5
	entry $path.2.rdelimiter -font splainf -width 3 -textvariable [::config::getVar rightdelimiter]
	pack $path.2 -side top -padx 0 -fill x
	pack $path.2.delimiters $path.2.ldelimiter $path.2.example $path.2.rdelimiter -side left

	$nb.nn compute_size
	$lfname.sw.sf compute_width
	
	
	#  .---------.
	# _| Privacy |________________________________________________
	#set frm [Rnotebook:frame $nb $Preftabs(privacy)]
	set frm [$nb.nn getframe privacy]
	ScrolledWindow $frm.sw
	ScrollableFrame $frm.sw.sf -constrainedwidth 1
	$frm.sw setwidget $frm.sw.sf
	pack $frm.sw -anchor n -side top -expand true -fill both
	set frm [$frm.sw.sf getframe]	

         # Allow/Block lists
	set lfname [labelframe $frm.lfname -text [trans prefprivacy]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill both
	label $lfname.pprivacy -image [::skin::loadPixmap prefapps]
	pack $lfname.pprivacy -anchor nw -side left

	frame $lfname.allowlist -relief sunken -borderwidth 3
    label $lfname.allowlist.label -text "[trans allowlist]" \
		-foreground [::skin::getKey extraprivacy_intoal_fg] -font sboldf
	listbox $lfname.allowlist.box -yscrollcommand "$lfname.allowlist.ys set" \
		-relief flat -highlightthickness 0 -height 5
	scrollbar $lfname.allowlist.ys -command "$lfname.allowlist.box yview" -highlightthickness 0 \
        -borderwidth 1 -elementborderwidth 2
	pack $lfname.allowlist.label $lfname.allowlist.box -side top -expand false -fill x
	pack $lfname.allowlist.box -side left -expand true -fill both
	pack $lfname.allowlist.ys -side right -fill y -expand false


	frame $lfname.blocklist -relief sunken -borderwidth 3
	label $lfname.blocklist.label -text "[trans blocklist]" -foreground [::skin::getKey extraprivacy_intobl_fg] -font sboldf
	listbox $lfname.blocklist.box -yscrollcommand "$lfname.blocklist.ys set" \
		-relief flat -highlightthickness 0  -height 5

	scrollbar $lfname.blocklist.ys -command "$lfname.blocklist.box yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
	pack $lfname.blocklist.label $lfname.blocklist.box -side top -expand false -fill x
	pack $lfname.blocklist.box -side left -expand true -fill both
	pack $lfname.blocklist.ys -side right -fill y -expand false


	frame $lfname.buttons -borderwidth 0
	button $lfname.buttons.right -text "[trans move] -->"  -command "Allow_to_Block $lfname" -width 13
	button $lfname.buttons.left -text "<-- [trans move]"  -command "Block_to_Allow $lfname" -width 13
	pack $lfname.buttons.right $lfname.buttons.left  -side top

	label $lfname.status -text ""
	frame $lfname.allowframe
	radiobutton $lfname.allowframe.allowallbutbl -text "[trans allowallbutbl]" -value 1 -variable temp_BLP
	radiobutton $lfname.allowframe.allowonlyinal -text "[trans allowonlyinal]" -value 0 -variable temp_BLP
	grid $lfname.allowframe.allowallbutbl -row 1 -column 1 -sticky w
	grid $lfname.allowframe.allowonlyinal -row 2 -column 1 -sticky w
	pack $lfname.status $lfname.allowframe -side bottom -anchor w -fill x
	pack $lfname.allowlist $lfname.buttons $lfname.blocklist -anchor w -side left -padx 10 -pady 10 -expand 1 -fill both

	bind $lfname.allowlist.box <<Button3>> "create_users_list_popup $lfname \"allow\" %X %Y"
	bind $lfname.blocklist.box <<Button3>> "create_users_list_popup $lfname \"block\" %X %Y"


	# Contact/Reverse lists
	set lfname [labelframe $frm.lfname2 -text [trans prefprivacy2]]
	set framePrivacyReverseList $lfname.reverselist
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill both
	label $lfname.pprivacy -image [::skin::loadPixmap prefapps]
	pack $lfname.pprivacy -anchor nw -side left

	frame $lfname.contactlist -relief sunken -borderwidth 3
	label $lfname.contactlist.label -text "[trans contactlist]" -background [::skin::getKey extraprivacy_notfl_bg] -font sboldf
	listbox $lfname.contactlist.box -yscrollcommand "$lfname.contactlist.ys set" \
		-relief flat -highlightthickness 0 -height 5

	scrollbar $lfname.contactlist.ys -command "$lfname.contactlist.box yview" -highlightthickness 0 \
		-borderwidth 1 -elementborderwidth 2
	pack $lfname.contactlist.label $lfname.contactlist.box -side top -expand false -fill x
	pack $lfname.contactlist.ys -side right -fill y -expand false
	pack $lfname.contactlist.box -side left -expand true -fill both
  
	frame $lfname.reverselist -relief sunken -borderwidth 3
	label $lfname.reverselist.label -text "[trans reverselist]" -background [::skin::getKey extraprivacy_notrl_bg] -font sboldf
	listbox $lfname.reverselist.box -yscrollcommand "$lfname.reverselist.ys set" \
		-relief flat -highlightthickness 0  -height 5
	scrollbar $lfname.reverselist.ys -command "$lfname.reverselist.box yview" -highlightthickness 0 \
		-borderwidth 1 -elementborderwidth 2
	pack $lfname.reverselist.label $lfname.reverselist.box -side top -expand false -fill x
	pack $lfname.reverselist.ys -side right -fill y -expand false
	pack $lfname.reverselist.box -side left -expand true -fill both

	frame $lfname.adding
	entry $lfname.adding.enter
	button $lfname.adding.addal -text "[trans addto AL]" -command "Add_To_List $lfname AL"
	button $lfname.adding.addbl -text "[trans addto BL]" -command "Add_To_List $lfname BL"
	button $lfname.adding.addfl -text "[trans addto FL]" -command "Add_To_List $lfname FL" 
	pack $lfname.adding.addal $lfname.adding.addbl $lfname.adding.addfl -side left
	pack $lfname.adding.enter -side top


	frame $lfname.buttons -borderwidth 0
	button $lfname.buttons.right -text "[trans delete] -->"  -command "Remove_Contact $lfname" -width 13
	button $lfname.buttons.left -text "<-- [trans copy]"  -command "Reverse_to_Contact $lfname" -width 13
	pack $lfname.adding  $lfname.buttons.right $lfname.buttons.left -side top
	

 #       pack $lfname.addal $lfname.addbl $lfname.addfl -side left

 #    	grid $lfname.enter -row 3 -column 1 -sticky w 
 #	grid $lfname.addal -row 4 -column 1 -sticky w 
 #	grid $lfname.addbl -row 4 -column 2 -sticky w 
 #	grid $lfname.addfl -row 4 -column 3 -sticky w 

	label $lfname.status -text ""

	pack $lfname.status -side bottom  -anchor w  -fill x
	pack $lfname.contactlist $lfname.buttons $lfname.reverselist -anchor w -side left -padx 10 -pady 10 -expand 1 -fill both

	bind $lfname.contactlist.box <<Button3>> "create_users_list_popup $lfname \"contact\" %X %Y"
	bind $lfname.reverselist.box <<Button3>> "create_users_list_popup $lfname \"reverse\" %X %Y"
	
  
	::Event::registerEvent contactRemoved protocol [list Fill_users_list_event $frm.lfname $frm.lfname2]
	::Event::registerEvent contactListChange all [list Fill_users_list_event $frm.lfname $frm.lfname2]
	::Event::registerEvent contactBlocked all [list Fill_users_list_event $frm.lfname $frm.lfname2]
	::Event::registerEvent contactUnblocked all [list Fill_users_list_event $frm.lfname $frm.lfname2]
	::Event::registerEvent contactMoved all [list Fill_users_list_event $frm.lfname $frm.lfname2]
	::Event::registerEvent contactAdded all [list Fill_users_list_event $frm.lfname $frm.lfname2]
	::Event::registerEvent contactRemoved all [list Fill_users_list_event $frm.lfname $frm.lfname2]
	::Event::registerEvent contactlistLoaded all [list Fill_users_list_event $frm.lfname $frm.lfname2]

	#  .----------.
	# _| Blocking |________________________________________________
	#set frm [Rnotebook:frame $nb $Preftabs(blocking)]
	
	## Check on disconnect ##
	#set lfname [labelframe $frm.lfname -text [trans prefblock1]]
	#pack $frm.lfname -anchor n -side top -expand 1 -fill x
	#label $lfname.ppref1 -image [::skin::loadPixmap prefapps]
	#pack $lfname.ppref1 -side left -padx 5 -pady 5 
	#checkbutton $lfname.enable -text "[trans checkonfln]" -onvalue 1 -offvalue 0 -variable [::config::getVar checkonfln]
	#pack $lfname.enable  -anchor w -side left -padx 0 -pady 5 

	## "You have been blocked" group ##
	#set lfname [labelframe $frm.lfname3 -text [trans prefblock3]]
	#pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	#label $lfname.ppref3 -image [::skin::loadPixmap prefapps]
	#pack $lfname.ppref3 -side left -padx 5 -pady 5 
	#checkbutton $lfname.group -text "[trans blockedyougroup]" -onvalue 1 -offvalue 0 -variable [::config::getVar showblockedgroup]
	#pack $lfname.group  -anchor w -side left -padx 0 -pady 5 

	## Continuously check ##
	#set lfname [labelframe $frm.lfname2 -text [trans prefblock2]]
	#pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	#label $lfname.ppref2 -image [::skin::loadPixmap prefapps]
	#pack $lfname.ppref2 -side left -padx 5 -pady 5 

	#frame $lfname.enable -class Degt
	#pack $lfname.enable -anchor w -side left 
	#checkbutton $lfname.enable.cb -text "[trans checkblocking]" -onvalue 1 -offvalue 0 -variable [::config::getVar checkblocking] -command UpdatePreferences
	#grid $lfname.enable.cb -row 1 -column 1 -sticky w

	#frame $lfname.check -class Degt
	#pack $lfname.check -anchor w -side left -padx 0 -pady 5 

        #label $lfname.check.linter1 -text "[trans blockinter1]"
        #label $lfname.check.linter2 -text "[trans blockinter2]"
        #label $lfname.check.linter3 -text "[trans blockinter3]"
        #label $lfname.check.linter4 -text "[trans blockinter4]"
        #label $lfname.check.lusers -text "[trans blockusers]"
        #entry $lfname.check.inter1 -validate all -vcmd "BlockValidateEntry %W %P 1" -invcmd "BlockValidateEntry %W %P 0 15" -width 4 -textvariable [::config::getVar blockinter1]
        #entry $lfname.check.inter2 -validate all -vcmd "BlockValidateEntry %W %P 2" -invcmd "BlockValidateEntry %W %P 0 30"  -width 4 -textvariable [::config::getVar blockinter2]
        #entry $lfname.check.inter3 -validate all -vcmd "BlockValidateEntry %W %P 3" -invcmd "BlockValidateEntry %W %P 0 2" -width 4 -textvariable [::config::getVar blockinter3]
        #entry $lfname.check.users -validate all -vcmd "BlockValidateEntry %W %P 4" -invcmd "BlockValidateEntry %W %P 0 5" -width 4 -textvariable [::config::getVar blockusers]

        #grid $lfname.check.linter1 -row 1 -column 1 -sticky w
        #grid $lfname.check.linter2 -row 1 -column 3 -sticky w
        #grid $lfname.check.linter3 -row 2 -column 3 -sticky w
        #grid $lfname.check.linter4 -row 2 -column 5 -sticky w
        #grid $lfname.check.lusers -row 2 -column 1 -sticky w
        #grid $lfname.check.inter1 -row 1 -column 2 -sticky w
        #grid $lfname.check.inter2 -row 1 -column 4 -sticky w
        #grid $lfname.check.inter3 -row 2 -column 4 -sticky w
        #grid $lfname.check.users -row 2 -column 2 -sticky w

	#pack $lfname.enable $lfname.check -anchor w -side top 

	#frame $frm.dummy -class Degt
	#pack $frm.dummy -anchor n -side top -expand 1 -fill both -pady 150

    # Frame for common buttons (all preferences)
    frame .cfg.buttons
    button .cfg.buttons.save -text [trans save] -default active -command "wm withdraw .cfg; SavePreferences; destroy .cfg"
    button .cfg.buttons.cancel -text [trans close] -command "destroy .cfg"
    bind .cfg <<Escape>> "destroy .cfg"
    pack .cfg.buttons.save .cfg.buttons.cancel -side right -padx 10 -pady 5
    pack .cfg.buttons -side bottom -fill x

    
    #Rnotebook:totalwidth $nb
    $nb.nn raise personal
    $nb.nn compute_size
    pack $nb.nn -expand true -fill both
    #pack $nb -fill both -expand 1 -padx 10 -pady 10

    pack .cfg.notebook -side bottom -fill both -expand true -padx 5 -pady 5
    
    
    InitPref 1
    UpdatePreferences

    #wm geometry .cfg [expr [Rnotebook:totalwidth $nb] + 50]x595

    #catch { Rnotebook:raise $nb $Preftabs($settings) }
	
	# This should raise the settings tab depending on the arg..
	catch {$nb.nn raise $settings}
    
    bind .cfg <Destroy> "UnregisterPrivacyEvents; RestorePreferences %W; array unset myconfig"

    wm state .cfg normal

    
    moveinscreen .cfg 60

    # Show requested page
    $nb.nn raise $settings
}

proc UnregisterPrivacyEvents {} {
	set nb .cfg.notebook
	if {[winfo exists $nb]} {
		set lfname [$nb.nn getframe privacy]
		set frm [$lfname.sw.sf getframe]
		::Event::unregisterEvent contactRemoved protocol [list Fill_users_list_event $frm.lfname $frm.lfname2]
		::Event::unregisterEvent contactListChange all [list Fill_users_list_event $frm.lfname $frm.lfname2]
		::Event::unregisterEvent contactBlocked all [list Fill_users_list_event $frm.lfname $frm.lfname2]
		::Event::unregisterEvent contactUnblocked all [list Fill_users_list_event $frm.lfname $frm.lfname2]
		::Event::unregisterEvent contactMoved all [list Fill_users_list_event $frm.lfname $frm.lfname2]
		::Event::unregisterEvent contactAdded all [list Fill_users_list_event $frm.lfname $frm.lfname2]
		::Event::unregisterEvent contactRemoved all [list Fill_users_list_event $frm.lfname $frm.lfname2]
		::Event::unregisterEvent contactlistLoaded all [list Fill_users_list_event $frm.lfname $frm.lfname2]
	}
}

proc Fill_users_list_event { path1 path2 args} {
        Fill_users_list $path1 $path2
}


proc getTaskbarHeight {{w .taskBarSize}} {
	global taskbarHeight 

	return [list 30 0 0 0]

	catch {destroy $w}
	# the -bg {} is used as a trick, it's some kind of bug with tk, where the background of the window becomes transparent
	toplevel $w
	wm attributes $w -alpha 0 -disabled 1
	wm state $w zoomed
 	update
 	set taskbarBottom [expr {[winfo screenheight $w] - [winfo height $w] - [winfo rooty $w]}]
 	set taskbarRight [expr {[winfo screenwidth $w] - [winfo width $w] - [winfo rootx $w]}]

 	set taskbarTop [expr {[winfo y $w] + 4}]
 	set taskbarLeft [expr {[winfo x $w] + 4}]
 	destroy $w
	
 	return [list $taskbarTop $taskbarRight $taskbarBottom $taskbarLeft]
}


#check if a window is outside the screen and move it in
proc moveinscreen {window {mindist 0}} {

	update

	#Small check to verify the window really exist
	if { ![winfo exists $window] } {
 		return
 	}
 	
	#set winx [winfo width $window]
	#set winy [winfo height $window]

	set scrx [winfo screenwidth .]
	set scry [winfo screenheight .]

 	if {[OnWin] } {
 		set tb [getTaskbarHeight]
 		set scry [expr {$scry - [lindex $tb 0] - [lindex $tb 2]}]
 		set scrx [expr {$scrx - [lindex $tb 1] - [lindex $tb 3]}]
 	}

	#set wi_geometry [winfo geometry $window]
	#scan $wi_geometry "%dx%d+%d+%d" winx winy winpx winpy

	set winpx [winfo rootx $window]
	set winpy [winfo rooty $window]
    
	set geom [wm geometry $window]
	scan $geom "%dx%d%c%d%c%d" winx winy sign1 decorationLeft sign2 decorationTop

	# Measure left edge, and assume all edges except top are the
	# same thickness
	if { $sign1 == 45} { ;#'-' character
		#Get size from right decoration
		set decorationThickness [expr {($scrx - $decorationLeft) - ($winpx + $winx)}]
		status_log "Minus: dec=$decorationThickness --> ($scrx + $decorationLeft) - ($winpx + $winx)\n"
	} else {
		set decorationThickness [expr {$winpx - $decorationLeft}]
	}

	# Find titlebar and menubar thickness
	if { $sign2 == 45 } { ;#'-' character
		set menubarThickness [expr {($scry - $decorationLeft) - ($winpy + $winy)}]
	} else {
		set menubarThickness [expr {$winpy - $decorationTop}]
	}


	#status_log "Window information: $window\n" white
	#status_log "Geometry: $geom\n (menuThickness= $menubarThickness, dec=$decorationThickness)\n"
	#status_log "Width, height: [winfo width $window]x[winfo height $window]\n"
	#status_log "winPx, winPy: $winpx,$winpy\n"
	#status_log "decLeft=$decorationLeft / decTop=$decorationTop\n"
	#status_log "-------------------\n" white


    	# Add this decoration size when checking size and limits
	incr winx [expr {2 * $decorationThickness}]
	incr winy $decorationThickness
	incr winy $menubarThickness
	incr winpx [expr {0 - $decorationThickness}]
	incr winpy [expr {0 - $menubarThickness}]

	#check if the window is too large to fit on the screen
	if { [expr {$winx > ($scrx-(2*$mindist))}] } {
		set winx [expr {$scrx-(2*$mindist)}]
	}
	if { [expr {$winy > ($scry-(2*$mindist))}] } {
		set winy [expr {$scry-(2*$mindist)}]
	}
	
	#check if the window is positioned off the screen
	if { [expr {$winpx + $winx > ($scrx-$mindist)}] } {
		set winpx [expr {$scrx-$mindist-$winx}]
	}
	if { [expr {$winpx < $mindist}] } {
		set winpx $mindist
	}
	if { [expr {$winpy + $winy > ($scry-(2*$mindist))}] } {
		set winpy [expr {$scry-$mindist-$winy}]
	}
	if { [expr {$winpy < $mindist}] } {
		set winpy $mindist
	}

    	# Substract decoration size, as wm geometry needs the window geometry
    	# without decoration
	incr winx [expr {0 - 2 * $decorationThickness}]
	incr winy [expr {0 - $decorationThickness}]
	incr winy [expr {0 - $menubarThickness }]

	catch {wm geometry $window "${winx}x${winy}+${winpx}+${winpy}"}
}

proc advanced_options_reload {path} {
	global advanced_options

	set i 0
	foreach opt $advanced_options {
		incr i	
		#For each advanced option, check if it's a title, it's local config, or global configs
		if {[lindex $opt 0] == "title" } {
			if { $i != 1 } {
				label $path.sp$i -font bboldf
				label $path.l$i -font bboldf -text "[trans [lindex $opt 1]]"
				pack $path.sp$i $path.l$i -side top -anchor w -pady 4
			} else {
				label $path.l$i -font bboldf -text "[trans [lindex $opt 1]]"
				pack $path.l$i -side top -anchor w -pady 4
			}
		} else {
			if {[lindex $opt 0] == "local"} {
				set config_var [::config::getVar [lindex $opt 1]]
			} elseif {[lindex $opt 0] == "global"} {
				set config_var [::config::getGlobalVar [lindex $opt 1]]
			} else {
				label $path.l$i -text "ERROR: Unknown advanced option type: \"[lindex $opt 0]\""
				pack $path.l$i -side top -anchor w
				continue
			}
			
			switch [lindex $opt 2] {
				bool {
					checkbutton $path.cb$i -text [trans [lindex $opt 3]] -font splainf -variable $config_var
					pack $path.cb$i -side top -anchor w
				}
				bool_inv {
					checkbutton $path.cb$i -text [trans [lindex $opt 3]] -font splainf -variable $config_var -onvalue 0 -offvalue 1
					pack $path.cb$i -side top -anchor w	
				}
				folder {
					frame $path.fr$i
					button $path.fr$i.browse -text [trans browse] -command "Browse_Dialog_dir [::config::getVar [lindex $opt 1]]"
					LabelEntry $path.fr$i.le "[trans [lindex $opt 3]]:" $config_var 20
					pack $path.fr$i.le -side left -anchor w -expand true -fill x
					pack $path.fr$i.browse -side left
					pack $path.fr$i -side top -anchor w -expand true -fill x
				}
				int {
					LabelEntry $path.le$i "[trans [lindex $opt 3]]:" $config_var 20
					$path.le$i.ent configure -validate focus -validatecommand "check_int %W" -invalidcommand "$path.le$i.ent delete 0 end; $path.le$i.ent insert end [set $config_var]"
					pack $path.le$i -side top -anchor w -expand true -fill x
				}
				default {
					LabelEntry $path.le$i "[trans [lindex $opt 3]]:" $config_var 20
					pack $path.le$i -side top -anchor w -expand true -fill x
				}
			}
			
			if { [lindex $opt 4] != "" } {
				label $path.exp$i -text "[trans [lindex $opt 4]]\n" -font examplef
				pack $path.exp$i -side top -anchor w -padx 15
			}
			
		}

	}

}



proc check_int {text} {
	set int_val "0"
	catch { expr {int([$text get])} } int_val
	if { $int_val != [$text get] } {
		status_log "Bad!!\n"
		return false
	}
	status_log "Good!!\n"
	return true
}

# This is where we fill in the Entries of the Preferences
proc InitPref { {fullinit 0} } {
	global Preftabs proxy_user proxy_pass pager locale_codes
	set nb .cfg.notebook

	if { $fullinit } {
		set proxy_user [::config::getKey proxyuser]
		set proxy_pass [::config::getKey proxypass]
	        set pager [::abook::getPersonal MOB]
		# Insert nickname if online, disable if offline
		#set lfname [Rnotebook:frame $nb $Preftabs(personal)]
		set lfname [$nb.nn getframe personal]
		set lfname [$lfname.sw.sf getframe]

		if { [::MSN::myStatusIs] == "FLN" } {
			$lfname.lfname.1.name.entry configure -state disabled
			$lfname.lfname4.2.chgmob configure -state disabled
			$lfname.lfname4.2.person configure -state disabled
		} else {
			$lfname.lfname.1.name.entry configure -state normal
			$lfname.lfname.1.name.entry delete 0 end
			$lfname.lfname.1.name.entry insert 0 [::abook::getPersonal MFN]


			$lfname.lfname4.2.chgmob configure -state normal
			$lfname.lfname4.2.person configure -state normal
		}
		
		if {[::config::getKey protocol] >= 11} {
			$lfname.lfname.1.psm.entry delete 0 end
			$lfname.lfname.1.psm.entry insert 0 [::abook::getPersonal PSM]
		}
	
		$lfname.lfname.1.p4c.entry delete 0 end
		$lfname.lfname.1.p4c.entry insert 0 [::config::getKey p4c_name]
		
		if {[::config::getKey protocol] >= 18} {
			$lfname.lfname.1.ep.entry delete 0 end
			$lfname.lfname.1.ep.entry insert 0 [::config::getKey epname aMSN]
		}
	
		
		# Get My Phone numbers and insert them
		set lfname "$lfname.lfname4"
	    if { [::abook::getPersonal MBE] == "N" } {
		 $lfname.2.mobphone configure -state disabled
	    }
		if { [::MSN::myStatusIs] == "FLN" } {
			$lfname.2.ephone1 configure -state disabled
			$lfname.2.ephone31 configure -state disabled
			$lfname.2.ephone32 configure -state disabled
			$lfname.2.ephone41 configure -state disabled
			$lfname.2.ephone42 configure -state disabled
			$lfname.2.ephone51 configure -state disabled
			$lfname.2.ephone52 configure -state disabled
		        $lfname.2.mobphone configure -state disabled
		} else {
			$lfname.2.ephone1 configure -state normal
			$lfname.2.ephone31 configure -state normal
			$lfname.2.ephone32 configure -state normal
			$lfname.2.ephone41 configure -state normal
			$lfname.2.ephone42 configure -state normal
			$lfname.2.ephone51 configure -state normal
			$lfname.2.ephone52 configure -state normal
			$lfname.2.ephone1 delete 0 end
			$lfname.2.ephone31 delete 0 end
			$lfname.2.ephone32 delete 0 end
			$lfname.2.ephone41 delete 0 end
			$lfname.2.ephone42 delete 0 end
			$lfname.2.ephone51 delete 0 end
			$lfname.2.ephone52 delete 0 end
			
			$lfname.2.ephone1 insert 0 [lindex [split [::abook::getPersonal PHH] " "] 0]
			$lfname.2.ephone31 insert 0 [lindex [split [::abook::getPersonal PHH] " "] 1]
			$lfname.2.ephone32 insert 0 [join [lrange [split [::abook::getPersonal PHH] " "] 2 end]]
			$lfname.2.ephone41 insert 0 [lindex [split [::abook::getPersonal PHW] " "] 1]
			$lfname.2.ephone42 insert 0 [join [lrange [split [::abook::getPersonal PHW] " "] 2 end]]
			$lfname.2.ephone51 insert 0 [lindex [split [::abook::getPersonal PHM] " "] 1]
			$lfname.2.ephone52 insert 0 [join [lrange [split [::abook::getPersonal PHM] " "] 2 end]]
		        
		    #$lframe.2.mobphone configure -variable [::abook::getPersonal MOB]
		}
		
		# Init remote preferences
		#set lfname [Rnotebook:frame $nb $Preftabs(connection)]
		set lfname [$nb.nn getframe connection]	
		set lfname [$lfname.sw.sf getframe]
		$lfname.lfname3.2.pass delete 0 end
		$lfname.lfname3.2.pass insert 0 "[::config::getKey remotepassword]"
		
	}

	#fill the locales combobox
	set lfname [$nb.nn getframe personal]
	set lfname "[$lfname.sw.sf getframe].lfname2a"
	$lfname.clocale list delete 0 end
	set loc_item_id 0
	set loc_item_selected 0
	foreach loc_item $locale_codes {
		set loc_name [lindex $loc_item 0]
		set loc_id [lindex $loc_item 1]
		$lfname.clocale list insert end $loc_name
		if {$loc_id == [::config::getKey localecode [::config::getKey localecode_autodetect 1033]]} {
			set loc_item_selected $loc_item_id
		}
		incr loc_item_id
	}
	$lfname.clocale select $loc_item_selected
	$lfname.clocale configure -editable false
		
	# Lets fill our profile combobox
	#set lfname [Rnotebook:frame $nb $Preftabs(others)]
	set lfname [$nb.nn getframe others]
	set lfname "[$lfname.sw.sf getframe].lfname3"
   	set idx 0
   	set tmp_list ""
	$lfname.1.profile list delete 0 end
   	while { [LoginList get $idx] != 0 } {
		lappend tmp_list [LoginList get $idx]
		incr idx
	}
   	eval $lfname.1.profile list insert end $tmp_list
	$lfname.1.profile insert 0 [lindex $tmp_list 0]
   	unset idx
   	unset tmp_list
	$lfname.1.profile configure -editable false

	# Lets disable loging if on default profile
	if { [LoginList exists 0 [::config::getKey login]] == 0 } {
		#set lfname [Rnotebook:frame $nb $Preftabs(loging)]
		set lfname [$nb.nn getframe loging]
		set lfname [$lfname.sw.sf getframe]
		set lfname "$lfname.lfname"
		$lfname.log configure -state disabled
		$lfname.camlog configure -state disabled
		set lfname [$nb.nn getframe loging]
		set lfname [$lfname.sw.sf getframe]
		set lfname "$lfname.lfname3"
		$lfname.logconnect configure -state disabled
		$lfname.logdisconnect configure -state disabled
		$lfname.logemail configure -state disabled
		$lfname.logstate configure -state disabled
		$lfname.lognick configure -state disabled
		$lfname.logpsm configure -state disabled
	}

	# Let's fill our list of States
	#set lfname [Rnotebook:frame $nb $Preftabs(session)]
	set lfname [$nb.nn getframe session]
	set lfname [$lfname.sw.sf getframe]
	$lfname.lfname2.statelist.box delete 0 end
	for { set idx 0 } { $idx < [StateList size] } {incr idx } {
		$lfname.lfname2.statelist.box insert end [lindex [StateList get $idx] 0]
	}

        # Fill the user's lists
        #set lfname [Rnotebook:frame $nb $Preftabs(privacy)]
	set lfname [$nb.nn getframe privacy]
	set lfname [$lfname.sw.sf getframe]
        Fill_users_list "$lfname.lfname" "$lfname.lfname2"

}


# This is where the preferences entries get enabled disabled
proc UpdatePreferences {} {
	global Preftabs

	set nb .cfg.notebook

	#fonts
	set lfname [$nb.nn getframe personal]
	set lfname [$lfname.sw.sf getframe]
	set lfname "${lfname}.lfname3"
	if { [::config::getKey disableuserfonts] } {
			$lfname.bfontin configure -state disabled
			$lfname.bfontinreset configure -state disabled
	} else {
		$lfname.bfontin configure -state normal
		if { [::config::getKey theirchatfont] == "" } {
			$lfname.bfontinreset configure -state disabled
		} else {
			$lfname.bfontinreset configure -state normal
		}
	}
	
	# autoaway checkbuttons and entries
	#set lfname [Rnotebook:frame $nb $Preftabs(session)]
	set lfname [$nb.nn getframe session]
	set lfname [$lfname.sw.sf getframe]
	set lfname "${lfname}.lfname"
	if { [::config::getKey autoidle] == 0 } {
		$lfname.1.eautonoact configure -state disabled
	} else {
		$lfname.1.eautonoact configure -state normal
	}
	if { [::config::getKey autoaway] == 0 } {
		$lfname.2.eautoaway configure -state disabled
	} else {
		$lfname.2.eautoaway configure -state normal
	}

	# proxy connection entries and checkbuttons
	#set lfname [Rnotebook:frame $nb $Preftabs(connection)]
	set lfname [$nb.nn getframe connection]
	set lfname [$lfname.sw.sf getframe]
	set lfname "${lfname}.lfnameconnection"
	if { [::config::getKey connectiontype] == "proxy" } {
		$lfname.4.post configure -state normal
		$lfname.4.ssl configure -state disable
		$lfname.4.socks5 configure -state normal
		$lfname.5.server configure -state normal
		$lfname.5.port configure -state normal
		if { [::config::getKey proxytype] == "socks5" || [::config::getKey proxytype] == "http"} {
			$lfname.5.user configure -state normal
			$lfname.5.pass configure -state normal
		} else {
			$lfname.5.user configure -state disabled
			$lfname.5.pass configure -state disabled
		}
	} else {
		$lfname.4.post configure -state disabled
		$lfname.4.ssl configure -state disabled
		$lfname.4.socks5 configure -state disabled
		$lfname.5.server configure -state disabled
		$lfname.5.port configure -state disabled
		$lfname.5.user configure -state disabled
		$lfname.5.pass configure -state disabled
	}
	#set lfname [Rnotebook:frame $nb $Preftabs(connection)]
	set lfname [$nb.nn getframe connection]
	set lfname [$lfname.sw.sf getframe]
	set lfname "${lfname}.lfname"
	if { [::config::getKey autoftip] } {
		$lfname.1.ipaddr.entry configure -textvariable "" -text "Hola"
		$lfname.1.ipaddr.entry delete 0 end
		$lfname.1.ipaddr.entry insert end [::config::getKey myip]
		$lfname.1.ipaddr.entry configure -state disabled
	} else {
		$lfname.1.ipaddr.entry configure -state normal -textvariable [::config::getVar manualip]
	}

	# remote control
	#set lfname [Rnotebook:frame $nb $Preftabs(connection)]
	set lfname [$nb.nn getframe connection]
	set lfname [$lfname.sw.sf getframe]
	set lfname "${lfname}.lfname3"
	if { [::config::getKey enableremote] == 1 } {
		$lfname.2.pass configure -state normal
	} else {
		$lfname.2.pass configure -state disabled 
	}

	# sound
	set lfname [$nb.nn getframe others]
	set lfname [$lfname.sw.sf getframe]
	set lfname "${lfname}.lfname"
	#Disabled that if we are on Mac OS X because we can't choose Snack
	if { ![OnMac] } {
		if { [::config::getKey usesnack] == 1 } {
			#load Snack when being used
			if {![catch {require_snack}]} {
				$lfname.1.sound.sound configure -state disabled
				snack::audio playLatency 750
			} else {
				::config::setKey usesnack 0
				$lfname.1.sound.sound configure -state normal
				msg_box [trans snackfailed]
			}
		} else {
			$lfname.1.sound.sound configure -state normal 
		}
	}

}
	

# This function sets all fonts to plain instead of bold,
# excluding the ones that are set to sboldf or examplef
proc setCfgFonts {path value} {
	catch {set res [$path cget -font]}
	if { [info exists res] } {
		if { $res != "sboldf" && $res != "examplef" && $res != "bboldf"} {
		    catch { $path configure -font $value }
		}
	}
        foreach child [winfo children $path] {
            setCfgFonts $child $value
        }
}



proc SavePreferences {} {
	global auto_path HOME2 tlsinstalled
	global myconfig proxy_server proxy_port list_BLP temp_BLP Preftabs libtls proxy_user proxy_pass pager locale_codes

	set nb .cfg.notebook

	# If the default ns server changed, change the start_ns_server too.
	if { [::config::getKey default_ns_server] != [set myconfig(default_ns_server)] } {
		::config::setKey start_ns_server [::config::getKey default_ns_server]
	}
	
	# I. Data Validation & Metavariable substitution
	# Proxy settings
	set p_server [string trim $proxy_server]
	set p_port [string trim $proxy_port]
	if { ![string is integer -strict $p_port] } {
		set p_port 8080
	}
	set p_user [string trim $proxy_user]
	set p_pass [string trim $proxy_pass]

	::config::setKey proxy [list $p_server $p_port]

	if { ($p_pass != "") && ($p_user != "")} {
		::config::setKey proxypass $p_pass
		::config::setKey proxyuser $p_user
		::config::setKey proxyauthenticate 1
	} else {
		::config::setKey proxypass ""
		::config::setKey proxyuser ""
		::config::setKey proxyauthenticate 0
	}

	if {![string is digit [::config::getKey initialftport]] || [string length [::config::getKey initialftport]] == 0 } {
		::config::setKey initialftport 6891
	}

	# Make sure entries x and y offsets and idle time are digits, if not revert to old values
	if { [string is digit [::config::getKey notifyXoffset]] == 0 } {
		::config::setKey notifyXoffset $myconfig(notifyXoffset)
	}
	if { [string is digit [::config::getKey notifyYoffset]] == 0 } {
		::config::setKey notifyYoffset $myconfig(notifyYoffset)
	}
	if { [string is digit [::config::getKey idletime]] == 0 } {
		::config::setKey idletime $myconfig(idletime)
	}
	if { [string is digit [::config::getKey awaytime]] == 0 } {
		::config::setKey awaytime $myconfig(awaytime)
	}
	if { [::config::getKey idletime] >= [::config::getKey awaytime] } {
		::config::setKey awaytime $myconfig(awaytime)
		::config::setKey idletime $myconfig(idletime)
	}

	# write correct locale code to config
	set lfname [$nb.nn getframe personal]
	set lfname "[$lfname.sw.sf getframe].lfname2a"
	set loc_item_selected [$lfname.clocale curselection]
	status_log "selected item: $loc_item_selected" red
	::config::setKey localecode [lindex [lindex $locale_codes $loc_item_selected] 1]
	
	# Check and save phone numbers
        
	if { [::MSN::myStatusIs] != "FLN" } {
		#set lfname [Rnotebook:frame $nb $Preftabs(personal)]
		set lfname [$nb.nn getframe personal]
		set lfname [$lfname.sw.sf getframe]
		set lfname "$lfname.lfname4"
	
		set cntrycode [$lfname.2.ephone1 get]
		if { [string is digit $cntrycode] == 0 } {
			set cntrycode [lindex [split [::abook::getPersonal PHH] " "] 0]
		}
	
		append home [$lfname.2.ephone31 get] " " [$lfname.2.ephone32 get]
		if { [string is digit [$lfname.2.ephone31 get]] == 0 } {
			set home [join [lrange [split [::abook::getPersonal PHH] " "] 1 end]]
		}
		append work [$lfname.2.ephone41 get] " " [$lfname.2.ephone42 get]
		if { [string is digit [$lfname.2.ephone41 get]] == 0 } {
			set work [join [lrange [split [::abook::getPersonal PHW] " "] 1 end]]
		}
		append mobile [$lfname.2.ephone51 get] " " [$lfname.2.ephone52 get]
		if { [string is digit [$lfname.2.ephone51 get]] == 0 } {
			set mobile [join [lrange [split [::abook::getPersonal PHM] " "] 1 end]]
		}
	
		set home [urlencode [set home "$cntrycode $home"]]
		set work [urlencode [set work "$cntrycode $work"]]
		set mobile [urlencode [set mobile "$cntrycode $mobile"]]
		if { $home != [::abook::getPersonal PHH] } {
			::abook::setPhone home $home
		}
		if { $work != [::abook::getPersonal PHW] } {
			::abook::setPhone work $work
		}
		if { $mobile != [::abook::getPersonal PHM] } {
			::abook::setPhone mobile $mobile
		}
		if {$pager != [::abook::getPersonal MOB] } {
			::abook::setPhone pager $pager
		}

		::abook::getIPConfig
	}

	# Change name
	#set lfname [Rnotebook:frame $nb $Preftabs(personal)]
	set lfname [$nb.nn getframe personal]
	set lfname [$lfname.sw.sf getframe]
	set lfname "$lfname.lfname.1"
	set new_name [$lfname.name.entry get]
	if {$new_name != "" && $new_name != [::abook::getPersonal MFN] && [::MSN::myStatusIs] != "FLN"} {
		::MSN::changeName $new_name
	}
	if {[::config::getKey protocol] >= 11} {
		set new_psm [$lfname.psm.entry get]
		if {$new_psm != "" && $new_psm != [::abook::getPersonal PSM] && [::MSN::myStatusIs] != "FLN"} {
			::MSN::changePSM $new_psm
		}
	}
	::config::setKey p4c_name [$lfname.p4c.entry get]

	if {[::config::getKey protocol] >= 18} {
		::MSN::changeEndPointName [$lfname.ep.entry get]
	}

	# Get remote controlling preferences
	#set lfname [Rnotebook:frame $nb $Preftabs(connection)]
	set lfname [$nb.nn getframe connection]
	set lfname [$lfname.sw.sf getframe]
	set myconfig(remotepassword) "[$lfname.lfname3.2.pass get]"
	::config::setKey remotepassword $myconfig(remotepassword)

	#Copy to myconfig array, because when the window is closed, these will be restored (RestorePreferences)
	array set myconfig [::config::getAll]

	# Save configuration of the BLP ( Allow all other users to see me online )
	if { $list_BLP != $temp_BLP } {
		AllowAllUsers $temp_BLP
	}


	# Save tls package configuration
	if { [::config::getKey libtls_temp] != $libtls } {
		set libtls [::config::getKey libtls_temp]
		if { $libtls != "" && [lsearch $auto_path $libtls] == -1 } {
			lprepend auto_path $libtls
		}
	
		if { $tlsinstalled == 0 && [catch {package require tls}] } {
			# Either tls is not installed, or $auto_path does not point to it.
			# Should now never happen; the check for the presence of tls is made
			# before this point.
			status_log "Could not find the package tls on this system.\n"
			set tlsinstalled 0
		} else {
			set tlsinstalled 1
		}
	
		set fd [open [file join $HOME2 tlsconfig.tcl] w]
		puts $fd "set libtls [list $libtls]"
		close $fd
	}


	# Blocking
	#if { [::config::getKey blockusers] == "" } { ::config::setKey blockusers 1}
	#if { [::config::getKey checkblocking] == 1 } {
		#BeginVerifyBlocked [::config::getKey blockinter1] [::config::getKey blockinter2] [::config::getKey blockusers] [::config::getKey blockinter3]
	#} else {
		#StopVerifyBlocked
	#}

	# Save configuration.
	save_config
	::MSN::contactListChanged
	::config::saveGlobal

	if { [::MSN::myStatusIs] != "FLN" } {
		cmsn_draw_online 0 1
	}

	if { [info exists ::start_on_windows_boot] } {
		WinRegKey $::start_on_windows_boot
        }

	::Event::fireEvent changedPreferences gui
    
	#Reset the banner incase the option changed
	resetBanner

	#Reload the trayicon in case it got changed
	init_dock
	

}

proc RestorePreferences { {win ".cfg"} } {
	
	if { $win != ".cfg" } { return }

	global myconfig proxy_server proxy_port
	
	::config::setAll [array get myconfig]

	# Save configuration.
	save_config
	::MSN::contactListChanged
	::config::saveGlobal

	if { [::MSN::myStatusIs] != "FLN" } {
		cmsn_draw_online 0 1
	}

	::Event::fireEvent changedPreferences gui
	
	#::MSN::WriteSB ns "SYN" "0"

	# Save configuration.
	#save_config

}

###################### Other Features     ###########################

# Usage: LabelEntry .mypath.mailer "Label:" config(mailcommand) 20
proc LabelEntry { path lbl variable width } {
    

    frame $path
	label $path.lbl -text $lbl -justify left \
	    -font splainf
	entry $path.ent -textvariable $variable  \
	    -width $width -font splainf
	pack $path.lbl -side left -anchor e
	pack $path.ent -side left -anchor e -expand 1 -fill x -padx 3
#	pack $path.ent $path.lbl -side right -anchor e -expand 1 -fill x
}

proc LabelEntryGet { path } {
    return [$path.ent get]
}


proc BlockValidateEntry { widget data type {correct 0} } {

    switch  $type  {
	0 {
	    if { [string is integer  $data] } {
		$widget delete 0 end
		$widget insert 0 "$correct" 
		after idle "$widget configure -validate all"
	    }    
	}
	1 {
	    if { [string is integer  $data] } {
		if { $data < 15 } {
		    return 0
		}
		return 1
	    } else {return 0}
	}
	2 {    
	    if { [string is integer $data] } {
		if { $data < 30 } {
		    return 0
		}
		return 1
	    } else {return 0}
	}
	3 {    
	    if { [string is integer   $data] } {
		if { $data < 2 } {
		    return 0
		}
		return 1
	    } else {return 0}
	}
	4 {    
	    if { [string is integer  $data] } {
		if { $data > 5 } {
		    return 0
		} 
		return 1 
	    } else {return 0}
	}
    }
	
}


#proc Browse_Dialog {}
#Browse dialog function (used in TLS directory and convert file), first show the dialog (choose folder or choose file), after check if user choosed something, if yes, set the new variable
proc Browse_Dialog_dir {configitem {initialdir ""}} {
	
	if { $initialdir == "" } {
		set initialdir [set $configitem]
	}
	
	if { ![file isdirectory $initialdir]} {
		set initialdir [pwd]
	}
	
	catch { set parent [focus]}
	if {![info exists parent] || $parent == "" } {
		set parent .
	}
	set browsechoose [tk_chooseDirectory -parent $parent -initialdir $initialdir]
	if { $browsechoose !="" } {
		set $configitem $browsechoose
	}
}

proc Browse_Dialog_file {configitem {initialfile ""}} {

	if { $initialfile == "" } {
		set initialfile [set $configitem]
	}

	if { ![file exists $initialfile] } {
		set initialfile ""
	}

	catch { set parent [focus]}
	if {![info exists parent] || $parent == "" } {
		set parent .
	}
	set browsechoose [tk_getOpenFile -parent $parent -initialfile $initialfile]
	if { $browsechoose !="" } {
		set $configitem $browsechoose
	}
}

#///////////////////////////////////////////////////////////////////////
proc choose_basefont { } {
	if { [winfo exists .basefontsel] } {
		raise .basefontsel
		return
	}

	
	if { [catch {
			set font [SelectFont .basefontsel -parent .cfg -title [trans choosebasefont] -font [::config::getGlobalKey basefont] -styles [list]]
		}]} {
		
		set font [SelectFont .basefontsel -parent .cfg -title [trans choosebasefont] -font [list "helvetica" 12 [list]] -styles [list]]
		
	}

	set family [lindex $font 0]
	set size [lindex $font 1]
			
	if { $family == "" || $size == ""} {
		return
	}

	set newfont [list $family $size normal]

	if { $newfont != [::config::getGlobalKey basefont]} {
		::config::setGlobalKey basefont $newfont
		focus .cfg
		msg_box [trans mustrestart]
	}

}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
# Since Tk 8.4.14 the Preferences AppleMenu item is hardcoded by TkAqua.
# When the menu item is pressed, it calls ::tk::mac::ShowPreferences.
if {[OnMac] && [version_vcompare [info patchlevel] 8.4.14] >= 0 } {
    proc ::tk::mac::ShowPreferences {} {
        after 0 { [list Preferences] }
    }
}
#///////////////////////////////////////////////////////////////////////
