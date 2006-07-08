#DEPENDS ON:
#	* Snit
#	* protocol.tcl (events)
#	* abook.tcl (user data)
#	* gui.tcl: getpicturefornotification
#	* more stuff I forgot I guess

source contact.tcl
#TODO:
#	* visual appearance of a contact
#		- multiple themes
#		- all bindings ('bindtags' ?)
#		- balloon
#	* make the title of the individuals group not shown
#	* per contact "groupslist" to have a list of all the groups the contact is in 
#		instead of only where it resides in that object
#	* clself widget
#		- 
#	...

snit::widgetadaptor stategroup {
	delegate method * to hull
	delegate option * to hull
	
	option -state -readonly 1 ;# The state it represents
	option -color -readonly 1 ;# The color of the contacts, depends on the state
	option -group -configuremethod setConfig
	delegate option * to parent_group

	variable contacts [list]
	variable contacts_widgets -array [list]
	variable statecodes [list NLN IDL BRB PHN BSY AWY LUN MOB FLN]
	variable parent_group

	constructor { args } {
		installhull using frame -bg white -relief flat -highlightthickness 0

		$self configurelist $args
		
	}

	#######################################################################
	# Methods to be called from outside
	#######################################################################
	#add a contact to the widget
	method {contact add} {contact} {
		set contact_uid [$contact cget -uid]
		set widg $self.$contact_uid
		set contactstate [$contact cget -state]
		set contactnick [$contact cget -nick]

		#do not add a contact that already exists in this group
		if {[lsearch $contacts $contact] == -1} {
			lappend $contacts $contact
			set widget [clcontact $widg -contact $contact -group $self]
			set contacts_widgets($contact_uid) $widget

			$self reorder

			set pack_opts "-anchor w"
			if { [llength $contacts] > 1 } {
				set idx [lsearch $contacts $contact]
				if { $idx == 0 } {
					append pack_opts " -before "
					append pack_opts [lindex $contacts 1]
				} else { 
					append pack_opts " -after "
					append pack_opts [lindex $contacts [expr {$idx -1}]]
				}
			}
			eval pack $widget $pack_opts
		}

		$options(-group) contact added $contact
	}

	method {contact remove} {contact} {
		set idx [lsearch $contacts $contact]
		if { $idx != -1 } {
			set widget [$self getContactWidget $contact]
			set contacts [lreplace $contacts $idx $idx]
			pack forget $widget
		}
		$options(-group) contact removed $contact

	}

	method {contact count} { } {
		return [llength $contacts]
	}

	#######################################################################
	# Helper methods, only called within this object
	#######################################################################

	method reorder { } {
		set contacts [lsort -command "$self contact compare " $contacts]
	}

	method {contact compare} {contact1 contact2} {
		# TODO make it depend on how you want to sort your contacts
		return [string compare -nocase [$contact1 cget -email] [$contact2 cget -email]]
	}

	method getContactWidget { contact } {
		set contact_uid [$contact cget -uid]
		if { [info exists contacts_widgets($contact_uid)] } {
			return [set contacts_widgets($contact_uid)]
		}
		return {}
	}

	method getContacts {} {
		return $contacts
	}

	method setConfig {option value} {
		set options($option) $value
		if {$option == "-group" } { set parent_group $value }
	}
	
}


snit::widgetadaptor clgroup {

	delegate method * to hull
	delegate option * to hull

	option -expanded -default 1 -configuremethod setConfig ;# 1 = expanded, 0 = collapsed
	option -name
	option -hoveredcolor -default skyblue -configuremethod setConfig
	option -collapsedcolor -default grey55 -configuremethod setConfig
	option -expandedcolor -default black -configuremethod setConfig
	option -hideifempty -default 1 -configuremethod setConfig
	option -group -readonly 1
	option -groupid

	variable count 0
	variable hideframe ;# widget with all elements, allows to not show the groups if empty
	variable title ;# widget with all title elements
	variable cwidg ;# widget where the contacts are packed in
	variable stategroups -array  [list]
  	variable hovered 0

	constructor { args } {
		installhull using frame -bg white -relief flat -highlightthickness 0

		set hideframe $self.hideframe
		frame $hideframe -bg white -relief flat -highlightthickness 0

		set title $hideframe.title
		set cwidg $hideframe.contacts
		
		frame $title -bg white -relief flat -highlightthickness 0
		frame $cwidg -bg white -relief flat -highlightthickness 0

		pack $title $cwidg -side top -fill x -anchor w

		# TODO : will depend on wheter we want to group users by status or have the different states mixed in a group
		foreach state [list NLN IDL BRB PHN BSY AWY LUN MOB FLN] {
			set stategroups($state) [stategroup $cwidg.stategroup_$state -group $self -state $state]
			pack [set stategroups($state)] -side top -fill x -anchor w
		}

		
		label $title.icon -image [::skin::loadPixmap contract] -bg white
		label $title.gname -textvariable options(-name) -fg black -bg white -font sboldf
		label $title.gcount -fg black -bg white -font sboldf
		pack $title.icon $title.gname $title.gcount -side left
		
		#bindings
		bind $title.icon <Button1-ButtonRelease> ";puts test ; $self toggleState"
		bind $title.gname <Button1-ButtonRelease> ";puts test ; $self toggleState"
		bind $title.gcount <Button1-ButtonRelease> ";puts test ; $self toggleState"
		bind $title <Enter> [list $self titlehover true]
		bind $title <Leave> [list $self titlehover false]
		

		$self updateCount

		$self configurelist $args
	}

	#######################################################################
	# Methods to be called from outside
	#######################################################################
	#add a contact to the widget
	method {contact add} {contact} {
		set contact_state [$contact cget -state]
		[set stategroups($contact_state)] contact add $contact
	}

	#remove a contact from the widget	
	method {contact remove} { address } {
		set contact_state [$contact cget -state]
		[set stategroups($contact_state)] contact remove $contact
	}	


	method {contact added} {contact} {
		incr count
		$self updateCount
	}
	method {contact removed} {contact} {
		incr count -1
		$self updateCount
	}
	
	#######################################################################
	# Helper methods, only called within this object
	#######################################################################

	method getContacts { } {
		set contactslist [list]
		foreach st [array names stategroups]  {
			lappend contactslist [$self getContactsWithState $st]
		}
		return $contactslist
	}

	method getContactsWithState {state} {
		if { $state == "ALL" } {
			return [$self getContactsInGroup]
		} else {
			return [[set stategroups($state)] getContacts]
		}
	}

	method getContactWidget { contact } {
		set contact_state [$contact cget -state]
		return [[set stategroups($contact_state)] getContactWidget $contact]
	}	

	method toggleState {} {
		$self configure -expanded [expr ! $options(-expanded)]
	}
	
	method titlehover {state} {
		set hovered $state

		if {$options(-expanded)} {
			set img_name "contract"
			set color $options(-expandedcolor)
		} else {
			set img_name "expand"
			set color $options(-collapsedcolor)
		}

		if {$state} {
			append img_name "_hover"
			set color $options(-hoveredcolor)
		}

		$title.icon configure -image [::skin::loadPixmap $img_name]
		$title.gcount configure -fg $color
		$title.gname configure -fg $color
	}

	method updateCount {} {
		$title.gcount configure -text "($count)"
		if {$options(-hideifempty) && $count < 1} {
			pack forget $hideframe
		} else {
			pack $hideframe
		}	
	}

	method setConfig {option value} {
		set options($option) $value

		puts "setting $option to $value"
		#actions after change of options
		#the space was added so the option isn't passed to the switch command
		switch -- $option {
			-expanded {
				if {$value == 1} {
					pack $cwidg
					set img [::skin::loadPixmap contract]
				} else {
					pack forget $cwidg
					set img [::skin::loadPixmap expand]
				}
				$title.icon configure -image $img
				::config::setKey expanded_group_[winfo name $self] $value
				$self titlehover $hovered
			}
			-collapsedcolor -
			-hoveredcolor -
			-expandedcolor {
				$self titlehover $hovered
			}
			-hideifempty {
				$self updateCount
			}
		
		}
			
	}
	
}


snit::widgetadaptor clcontact {

	delegate method * to hull
	delegate option * to hull

	#protocol given options
	option -contact
	option -group 
	option -address -configuremethod setConfig
	option -groupid -default 0
	option -nickname -default defaultnickname -configuremethod setConfig
	option -message -default "" -configuremethod setConfig ;#personnal message
	option -image -configuremethod setConfig
	option -state -default FLN -configuremethod setConfig
	option -blocked -default 0 -configuremethod setConfig
	option -mobile -default 0 ;# mobile capabilities ? (could be shown in UI)
	option -notinrl -default 0 -configuremethod setConfig

	#UI options
	option -color -default black
	#a theme could be specified for how the contact should look
	option -theme -default 1 ;#-configuremethod setConfig

	#amsn options
	option -alarm -default 0 ;#-configuremethod setConfig

	#widgets
	variable left
	variable right
	variable nick
	variable psm
	variable state

	variable iconw
	variable iconh

	constructor { args } {
		installhull using frame -bg white -relief flat -highlightthickness 0

		$self configurelist $args


		set options(-address) [$options(-contact) cget -email]
		set options(-nickname) [$options(-contact) cget -nick]
		set options(-message) [::abook::getpsmmedia $options(-address)]
		set options(-state) [$options(-contact) cget -state]

		if { [getpicturefornotification $options(-address)] } {
			set options(-image) displaypicture_not_$options(-address)			
		} else {
			set options(-image) none
		}
		set options(-groupid) [$options(-group) cget -groupid]
		set options(-blocked) [::MSN::userIsBlocked $options(-address)]
		set options(-notinrl) [expr {[lsearch [::abook::getLists $options(-address)] RL] == -1}]

		#####################
		#All UI for contact
		#####################
		set left $self.left
		set right $self.right
		set iconw 50 ; set iconh 50		

		canvas $left -height $iconh  -width $iconw -bg white

		$left create image 0 0 -anchor nw -tag dp
		$left create image $iconw $iconh -anchor se -tag statusemblem
		$left create image 0 $iconh -anchor sw -tag notinrlemblem
		$left create image $iconw 0 -anchor ne -tag blockedemblem


		frame $right -bg white -relief flat -highlightthickness 0
		pack $left $right -side left -anchor w
		
		frame $right.first -bg white -relief flat -highlightthickness 0 
		frame $right.2nd -bg white -relief flat -highlightthickness 0 
		frame $right.third -bg white -relief flat -highlightthickness 0 
#		pack $right.first $right.2nd $right.third -side top -anchor w
		pack $right.first $right.third -side top -anchor w
		
		set topline $right.first
		set nick $topline.nick ; set psm $topline.psm
		label $topline.nick -text $options(-nickname) -bg white
		label $topline.psm -text $options(-message) -font sitalf -bg white
		pack $topline.nick $topline.psm -side left -expand 1
		
		set third $right.third
		set state $third.state
		label $third.state -text "([trans [::MSN::stateToDescription $options(-state)]])" -bg white
		pack $third.state -anchor w
		
		
		#####################
		#UI Bindings
		#####################
		
#		#bindtags -> no succes ?
#		set tag contact_[::md5::md5 $options(-address)]
#		foreach widget [list $self $left $right $topline $topline.nick $topline.psm $#third] {
#			bindtags $widget {$tag $widget}
#		}
		
		proc bindContactAction { w action } {			
			if { [::config::getKey sngdblclick] } {
				set singordblclick <Button-1>
			} else {
				set singordblclick <Double-Button-1>
			}
			#TODO bind all widgets ... what about bindtags ?
			bind $w.left $singordblclick $action
		}

		if { $options(-state) != "FLN" } {
			bindContactAction $self "::amsn::chatUser $options(-address)"
		} elseif { $options(-mobile) == 1 } {
			bindContactAction $self "::MSNMobile::OpenMobileWindow $options(-address)"
		} else {
			#TODO: send mail action
			bindContactAction $self ""
		}
		bind $self.left <<Button3>> "show_umenu $options(-address) $options(-groupid) %X %Y"

		$self configure -address [$options(-contact) cget -email]
		$self configure -nickname [$options(-contact) cget -nick]
		$self configure -message [::abook::getpsmmedia $options(-address)]
		$self configure -state [$options(-contact) cget -state]

		if { [getpicturefornotification $options(-address)] } {
			$self configure -image displaypicture_not_$options(-address)			
		} else {
			$self configure -image none
		}
		$self configure -groupid [$options(-group) cget -groupid]
		$self configure -blocked [::MSN::userIsBlocked $options(-address)]
		$self configure -notinrl [expr {[lsearch [::abook::getLists $options(-address)] RL] == -1}]
		
	}
	

	method setConfig {option value} {
		set options($option) $value

		switch " $option" {
			" -state" {
				$state configure -text "([trans [::MSN::stateToDescription $value]])"
				$left itemconfigure statusemblem -image [::skin::loadPixmap [::MSN::stateToDescription $value]] 
				#reposition in list ($groupwidg position $contact)
				#[winfo parent [winfo parent [winfo parent $self]]] positionContact $options(-address)

			}
			" -image" {				
				if {![ImageExists $value]} {
					set value [::skin::loadPixmap nullimage]
				}
				$left itemconfigure dp -image $value
			}
			" -nickname" {
				$nick configure -text $value
			}
			" -message" {
				$psm configure -text $value
			}
			" -notinrl" {
				if {$value == 1} {
					$left itemconfigure notinrlemblem -image [::skin::loadPixmap notinlist]
				} else {
					$left itemconfigure notinrlemblem -image [::skin::loadPixmap nullimage]
				}
			}
			" -blocked" {
				if {$value == 1} {
					$left itemconfigure blockedemblem -image [::skin::loadPixmap blocked]
				} else {
					$left itemconfigure blockedemblem -image [::skin::loadPixmap nullimage]
				}			
			}
		}		
	
	
	
	}
}


snit::widgetadaptor clwidget {
#TODO: scrollbars ! -> or should they be given by the parent widget ?

	delegate method * to hull
	delegate option * to hull

	option -groupoffline -default 1 -configuremethod setConfig
	option -groupmobile -default 1 -configuremethod setConfig
	option -orderbygroup -default 1 -configuremethod setConfig
	option -orderdecreasing -default 0 -configuremethod setConfig
	option -hideemptygroups -default 1 -configuremethod setConfig
	
	#vars
	variable contacts -array [list]
	variable groupnames [list ] ;#sorted list of all groups in UI
	variable widg ;#widget were the groups are packed in

	constructor { args } {
		installhull using ScrollableFrame -bg white -constrainedwidth 1
		set widg [$self getframe]

		#Create a sorted list of the groups:
		$self redrawCL
		
		#register all needed events
		::Event::registerEvent contactStateChange protocol $self
		::Event::registerEvent contactNickChange protocol $self
		::Event::registerEvent contactPSMChange protocol $self		

		::Event::registerEvent contactAdded protocol $self
		::Event::registerEvent contactMoved protocol $self
		::Event::registerEvent contactRemoved protocol $self

		::Event::registerEvent contactBlocked protocol $self
		::Event::registerEvent contactUnblocked protocol $self
		
		::Event::registerEvent groupAdded groups $self
		::Event::registerEvent groupRemoved groups $self
		::Event::registerEvent groupRenamed groups $self

		::Event::registerEvent loggedOut protocol $self
		
		$self configurelist $args
	}
	
	destructor {
		#unregister all used events
		::Event::unregisterEvent contactStateChange protocol $self
		::Event::unregisterEvent contactNickChange protocol $self
		::Event::unregisterEvent contactPSMChange protocol $self		

		::Event::unregisterEvent contactAdded protocol $self
		::Event::unregisterEvent contactMoved protocol $self
		::Event::unregisterEvent contactRemoved protocol $self

		::Event::unregisterEvent contactBlocked protocol $self
		::Event::unregisterEvent contactUnblocked protocol $self
		
		::Event::unregisterEvent groupAdded groups $self
		::Event::unregisterEvent groupRemoved groups $self
		::Event::unregisterEvent groupRenamed groups $self

		::Event::unregisterEvent loggedOut protocol $self
	}

	method groupAdded {gid} {
		$self updateGroups
		set idx [lsearch -index 1 $groupnames $gid]
		set group [lindex $groupnames $idx]

		set exp [::config::getKey expanded_group_$gid]
		if { $exp == "" } { set exp 1 }
			
		clgroup $widg.$gid -expanded $exp -name [lindex $group 0] -hideifempty $options(-hideemptygroups) -groupid $gid

		if {$idx != 0} {
			set after [lindex [lindex $groupnames [expr {$idx - 1} ] ] 1]
			pack $widg.$gid -anchor w -side top -after $widg.$after

		} else {
			set before [lindex [lindex $groupnames 1 ] 1]
			pack $widg.$gid -anchor w -side top -after $widg.$before
		}

	}

	method groupRemoved {gid} {
		if {[winfo exists $widg.$gid]} {
			destroy $widg.$gid
		}	
	}

	method groupRenamed {args} {
		foreach {gid gname} $args {break}
		if {[winfo exists $widg.$gid]} {
			$widg.$gid configure -name $gname
		}
	}

		
	method loggedOut {} {
		foreach group [winfo children $widg] {
			destroy $group
		}	
	}
	method contactBlocked {contact_email} {
		set contact [$self emailToContact $contact_email]
		set groups [$self getContactGroups $contact]
		foreach group $groups {
			set cwidg [$widg.$group getContactWidget $contact]
			if {$cwidg == ""} { return }
			$cwidg configure -blocked 1
		}		
	}

	method contactUnblocked {contact_email} {
		set contact [$self emailToContact $contact_email]
		set groups [$self getContactGroups $contact]
		foreach group $groups {
			set cwidg [$widg.$group getContactWidget $contact]
			if {$cwidg == ""} { return }
			$cwidg configure -blocked 0
		}		
	}

	method emailToContact { contact_email } {
		if { [info exists contacts($contact_email)] } {
			return [set contacts($contact_email)]
		} else {
			set contact [contact create %AUTO% -email $contact_email]
			set contacts($contact_email) $contact
			return $contact
		}
	}

	method contactMoved {contact_email oldgid newgid} {
		#if not ordered by group, moving a contact doesn't do anything in the UI
		if { !$options(-orderbygroup) } {
			set contact [$self emailToContact $contact_email]

			#remove from the former group
			$widg.$oldgid contact remove $contact

			#add to the new group
			set altgid [$self getContactGroups $contact 1]
			if {$altgid == ""} {
				$widg.$newgid contact add $contact
			} else {
				$widg.$altgid contact add $contact
			}
		}
	}

	method contactRemoved {contact_email gid} {
		set contact [$self emailToContact $contact_email]

		#if gid exists, remove from that group, otherwise, remove from all groups
		if {[winfo exists $widg.$gid]} {
			$widg.$gid contact remove $contact
		} else {
			#remove from all groups where it resides
			foreach gid [$self getContactGroups $contact] {
				$widg.$gid contact remove $contact
			}
		}

	}
	
	method contactAdded {contact_email newgid} {
		set contact [$self emailToContact $contact_email]

		#add to the new group (only this group!)
		set altgid [$self getContactGroups $contact 1]
		if {$altgid == ""} {
			$widg.$newgid contact add $contact
		} else {
			$widg.$altgid contact add $contact
		}			

	}

	method contactNickChange { contact_email } {
		set contact [$self emailToContact $contact_email]

		set groups [$self getContactGroups $contact]
		foreach group $groups {
			set cwidg [$widg.$group getContactWidget $contact]
			if {$cwidg == ""} { return }
			$cwidg configure -nickname [::abook::getNick $contact_email]
		}
	}	

	method contactPSMChange { contact_email } {
		set contact [$self emailToContact $contact_email]

		set groups [$self getContactGroups $contact]
		foreach group $groups {
			set cwidg [$widg.$group getContactWidget $contact]
			if {$cwidg == ""} { return }
			$cwidg configure -message [::abook::getpsmmedia $contact_email]
		}
	}

	method contactStateChange { contact_email } {
		set contact [$self emailToContact $contact_email]

		#change state
		set state [::abook::getVolatileData $contact_email state FLN]
		set groups [::abook::getGroups $contact_email]
		set offgroup [$self getContactGroups $contact 1]

		if { $options(-orderbygroup) } {
			set uigroups $groups
		} else {
			set uigroups "online"
		}


		foreach gid $uigroups {
			set cwidg [$widg.$gid getContactWidget $contact]
			#if the contact is in the group
			if {$cwidg != ""} {
				#if the contact should go in the mobile or offline group
				if {$offgroup != ""} {
#					puts "Contact $contact goes offline, moving from group to mobile/offline group"
					#remove from this group
					$widg.$gid contact remove $contact
					#add contact to the mobile/offline group
					if { $gid == "online" } { set gid [lindex $groups 0] }
					$widg.$offgroup contact add $contact
				} else {
#					puts "Contact $contact changes status and stays in the same group"
					#change status
					$cwidg configure -state $state
				}
			#the contact is currently not in this group (thus in mobile/offline)
			} else {

				#if it shouldn't be in offline/mobile
				if {$offgroup == ""} {
#					puts "Contact $contact comes online, was not in group \nremoving from offline/mobile and adding in this group"
					#remove it from the offline/mobile groups
					if {[winfo exists $widg.offline]} {
						$widg.offline contact remove $contact
					}
					if {[winfo exists $widg.mobile]} {
						$widg.mobile contact remove $contact
					}

					if { $gid == "online" } { set gid_ [lindex $groups 0] } else { set gid_ $gid }
					$widg.$gid contact add $contact
				} else {
					puts "ERR ! $contact should be in $offgroup but it is not here nor in it's group"
				}
			}
		}

			
	}

	method redrawCL {} {
		#remove all groups
		foreach group [winfo children $widg] {
			destroy $group
		}	

		#Create a sorted list of the groups:
		$self updateGroups
		
		#put the groups in the lists	
		foreach group $groupnames {
			set gid [lindex $group 1]
			set exp [::config::getKey expanded_group_$gid]
			if { $exp == "" } { set exp 1 }
			clgroup $widg.$gid -expanded $exp -name [lindex $group 0] -hideifempty $options(-hideemptygroups) -groupid $gid
			pack $widg.$gid -anchor w -side top
		}


		foreach contact_email [::MSN::sortedContactList] { 
			foreach gid [::abook::getGroups $contact_email] {
				set contact [$self emailToContact $contact_email]

				set altgid [$self getContactGroups $contact 1]
				if {$altgid == ""} {
					if {!$options(-orderbygroup)} {
						set altgid "online"
					} else {
						set altgid $gid
					}
				}
				$widg.$altgid contact add $contact
			}
		}	
	}
	
	method updateGroups {} {
		set groupnames [list ]
		if { $options(-orderbygroup) } {
			set groupids [::groups::GetList]

			foreach gid $groupids {
				#Ignore special group "Individuals" when sorting
				if { $gid != 0} {
					lappend groupnames [list [::groups::GetName $gid] $gid]
				}
			}

			if { $options(-orderdecreasing) } {
				set groupnames [lsort -decreasing -dictionary -index 0 $groupnames ]
			} else {
				set groupnames [lsort -dictionary -index 0 $groupnames ]
			}



			#begin with the "individuals" group
			set groupnames [concat [list [list individuals 0]] $groupnames]

			#add mobile
			if {$options(-groupmobile)} {
				set groupnames [lappend groupnames [list [trans mobile] mobile] ]
			}			
			#add offline 
			if {$options(-groupoffline)} {
				set groupnames [lappend groupnames [list [trans uoffline] offline] ]
			}
		

		} else {
			set groupnames [list [list [trans online] online ]]

			if {$options(-groupmobile)} {
				set groupnames [lappend groupnames [list [trans mobile] mobile]]
			}
			set groupnames [lappend groupnames [list [trans uoffline] offline]]

		}
	}
		
	method getContactGroups { contact_obj {offonly 0}} {
		set contact [$contact_obj cget -email]
		set status [::abook::getVolatileData $contact state FLN]
		# Online/Offline mode
		if { !$options(-orderbygroup) } {
			if { $status == "FLN" } {
				if { [::abook::getContactData $contact msn_mobile] == "1" \
					&& $options(-groupmobile)} {
					return "mobile"
				} else {
					return "offline"
				}
			} else {
				if { !$offonly } {
					return "online"
				} else {
					return ""
				}
			}

		# Group mode
		} else {
			if { $status == "FLN" && $options(-groupoffline)} {
				if { [::abook::getContactData $contact msn_mobile] == "1" && $options(-groupmobile)} {
					return "mobile"
				} else {
					return "offline"
				}
			} else {
				if { !$offonly } {
					return [::abook::getGroups $contact]
				} else {
					return ""
				}
			}
			
		}	
	
	}
	
	method getGroupWidgets {} {
		return [winfo children $widg]
	}

	method setConfig {option value} {
		set oldvalue $options($option)
		set options($option) $value

		if { $oldvalue == $value } {
			return
		}

#TODO: instead of redraw, try to only do what's needed		

		switch " $option" {
			" -groupoffline" {
				if {!$options(-orderbygroup)} {
					#if we are ordered by statutus this doesn't do anything
					return
				}

				$self updateGroups
				#group offline contacts
				if {$value == 1} {

					#add offline groups
					set exp [::config::getKey expanded_group_offline]
					if { $exp == "" } { set exp 1 }
					clgroup $widg.offline -expanded $exp -name [trans offline] -hideifempty $options(-hideemptygroups) -groupid 0
					pack $widg.offline -anchor w -side top

					#foreach group, get the offline contacts and move 'm to the offline group
					foreach groupwidg [$self getGroupWidgets] {
						set group [winfo name $groupwidg]
						foreach contact [$widg.$group getContactsWithState FLN] {
							#don't change for mobile group
							if {$group != "mobile" } {
								$widg.$group contact remove $contact
								$widg.offline contact add $contact
							}
						}
					}
				#UNgroup offline contacts
				} else {
					#move all contacts from the offline group to their respective groups
					foreach contact [$widg.offline getContactsWithState FLN] {
						foreach group [::abook::getGroups $contact] {
							$widg.offline contact remove $contact
							$widg.$group contact add $contact
						}
					}				
				destroy $widg.offline
				}
			}
			" -groupmobile" {				
				$self updateGroups
				if {$value == 1} {
					#add mobile group
					set exp [::config::getKey expanded_group_mobile]
					if { $exp == "" } { set exp 1 }
					clgroup $widg.mobile -expanded $exp -name [trans mobile] -hideifempty $options(-hideemptygroups) -groupid 0
					if { [winfo exists $widg.offline] } {
						pack $widg.mobile -anchor w -side top -before $widg.offline
					} else {
						pack $widg.mobile -anchor w -side top
					}

					#move all mobile contacts to mobiule group
					foreach contact_email [::MSN::sortedContactList] { 
						set contact [$self emailToContact $contact_email]
						#if it's a mobile contact
						if { [::abook::getContactData $contact_email msn_mobile] == "1" && [::abook::getVolatileData $contact_email state FLN] == "FLN" } {
							
							set contactgroups [::abook::getGroups $contact_email]
							#see in what groups the contact is now
							if {$options(-orderbygroup) && !$options(-groupoffline)} {
								set groups $contactgroups
							} else {
								set groups offline
							}
							
							#remove it from each of these groups
							foreach group $groups {
								$widg.$group contact remove $contact
							}

							#listen carefully, I'm gonna add this only once
							if {[$self getContactGroups $contact 1] == "mobile"} {
								$widg.mobile contact add $contact
							}
						}
					}
				} else {
					#remove all mobile users, add 'm to their groups
					foreach contact_email [$widg.mobile getContactsWithState FLN] {
						set contact [$self emailToContact $contact_email]
						$widg.mobile contact remove $contact
						foreach gid [::abook::getGroups $contact_email] {
							set altgid [$self getContactGroups $contact 1]
							if {$altgid == ""} {
								if {!$options(-orderbygroup)} {
									set altgid "online"
								} else {
									set altgid $gid
								}
							}
							$widg.$altgid contact add $contact
						}
					}
					#remove mobile group
					destroy $widg.mobile
				
				}				
			}
			" -orderbygroup" {
				$self redrawCL
			}
			" -orderdecreasing" {
				$self updateGroups
				#now repack allgroups
				foreach group $groupnames {
					set gid [lindex $group 1]
					pack forget $widg.$gid
					set exp [::config::getKey expanded_group_$gid]
					if { $exp == "" } { set exp 1 }
					pack $widg.$gid -anchor w -side top
				}
			}
			" -hideemptygroups" {
				foreach group [winfo children $widg] {
					$group configure -hideifempty $value

				}	
			}
		}
	}	
}


snit::widgetadaptor clself {

	delegate method * to hull
	delegate option * to hull

	option -state -default FLN -configuremethod setConfig
	option -nickname -default 1 -configuremethod setConfig
	option -message -default 1 -configuremethod setConfig
	option -image -default 0 -configuremethod setConfig
	
	constructor { args } {
		installhull using canvas -bg white -constrainedwidth 1

	}
}


#create a demo window

catch {destroy .test}
toplevel .test
::gui::stdbind .test

ScrolledWindow .test.sw

clwidget .test.sw.cl ;#-groupoffline 0 -orderbygroup 1 -groupmobile 1 -orderdecreasing 1 -hideemptygroups 1

.test.sw setwidget .test.sw.cl

pack .test.sw  -anchor nw -side top -expand true -fill both

.test.sw.cl configure -height 1000 -width 300

if {[OnMac]} {
    bind .test <MouseWheel> {
	    set w .test.sw.cl
	    if { [winfo exists $w] } {
		    $w yview scroll [expr {- (%D)}] units   
	    }
    } 
} elseif {[OnWin]} {
    bind .test <MouseWheel> {
	    set w .test.sw.cl
	    if { [winfo exists $w] } {
		    $w yview scroll %D units   
	    }
    }
} else {
    bind .test <5> {
	    set w .test.sw.cl
	    if { [winfo exists $w] } {
		    $w yview scroll +1 units
	    }
    }
    bind .test <4> {
	    set w .test.sw.cl
	    if { [winfo exists $w] } {
		    $w yview scroll -1 units 
	    }
    }
}
