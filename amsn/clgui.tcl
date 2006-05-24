#DEPENDS ON:
#	* Snit
#	* protocol.tcl (events)
#	* abook.tcl (user data)
#	* gui.tcl: getpicturefornotification


snit::widgetadaptor clgroup {

	delegate method * to hull
	delegate option * to hull

	option -state -default 1 -configuremethod setConfig ;# 1 = expanded, 0 = collapsed
	option -name -configuremethod setConfig
	option -color -configuremethod setConfig
	option -notitle -default 0
	option -hideifempty -default 1 -configuremethod setConfig

	variable count 0
	variable contactslist [list ] ;#lists addresses sorted by state and nick/email
	variable title ;#widget with all title elements
	variable cwidg ;#widget where the contacts are packed in
	variable statecodes [list NLN IDL BRB PHN BSY AWY LUN MOB FLN]
	variable ctperstate ;#array with all [list $email $nick] lists per state

	constructor { args } {
		installhull using frame -bg white -relief flat -highlightthickness 0

		set hidef $self.hideframe
		frame $hidef -bg white -relief flat -highlightthickness 0

		foreach state $statecodes {
			set ctperstate($state) [list ]
		}
		
		set title $hidef.title
		set cwidg $hidef.contacts
		
		frame $title -bg white -relief flat -highlightthickness 0
		frame $cwidg -bg white -relief flat -highlightthickness 0

		pack $title $cwidg -side top -fill x -anchor w

		label $title.icon -image [::skin::loadPixmap contract] -bg white
		label $title.gname -text "groupname" -fg black -bg white -font sboldf
		label $title.gcount -fg black -bg white -font sboldf
		pack $title.icon $title.gname $title.gcount -side left
		
		#bindings
		bind $title.icon <Button1-ButtonRelease> "$self toggleState"
		bind $title.gname <Button1-ButtonRelease> "$self toggleState"
		bind $title.gcount <Button1-ButtonRelease> "$self toggleState"
		bind $title <Enter> [list $self titlehover $title.icon on]
		bind $title <Leave> [list $self titlehover $title.icon off]
		
#		bind $title.gname <Button1-ButtonRelease> "$self toggleState"
#		bind $title.gcount <Button1-ButtonRelease> "$self toggleState"

		$self configurelist $args
		$self updateCount
	}
	#######################################################################
	# Methods to be called from outside
	#######################################################################
	#add a contact to the widget
	method addContact { address groupid} {
		set widg $cwidg.[::md5::md5 $address]
		set contactstate [::abook::getVolatileData $address state FLN]
		set contactnick [::abook::getNick $address]

		#do not add a contact that already exists in this group
		if {![winfo exists $widg]} {
			#get image
			if { [getpicturefornotification $address] } {
				set img displaypicture_not_$address
			} else {
				set img none
			}

			#create the contact's widget
			clcontact $widg -address $address -nickname $contactnick\
				-message [::abook::getpsmmedia $address] -state $contactstate\
				-image $img -groupid $groupid -blocked [::MSN::userIsBlocked $address]\
				-notinrl [expr {[lsearch [::abook::getLists $address] RL] == -1}]

			#pack it at the right position
			$self positionContact $address
			
			#update count
			$self updateCount 1
#			puts "added $address to $options(-name)"
		}

	}

	#remove a contact from the widget	
	method rmContact { address } {
		set widg $cwidg.[::md5::md5 $address]

		if {![winfo exists $widg] && [lsearch $contactslist $address] == -1} {
			#no contact to remove here, move on
			#puts "nothing to remove, $address is not in $options(-name)"
		} elseif {![winfo exists $widg]} {
			puts "ERR: contact widget doesn't exist though the contact is still in the lists"
			#remove the contact from the list of his/her state
			$self rmContFromLists $address
		} elseif { [lsearch $contactslist $address] == -1 } {
			puts "ERR: contact is not in the list for this groupwidget"
			#destroy widget
			destroy $widg
			$self updateCount -1		
#			puts "removed $address from $options(-name)"
		} else {
			set contactstate [::abook::getVolatileData $address state FLN]

			#remove the contact from the list of his/her state
			$self rmContFromLists $address
						
			#destroy widget
			destroy $widg
			
			$self updateCount -1		
#			puts "removed $address from $options(-name)"
		}

	}	

	#(re)packs the widget in on the right place
	method positionContact {address} {
		set id [::md5::md5 $address]
		set w $cwidg.$id

		#if the contact is already in the list, first remove it
		if {[lsearch $contactslist $address] != -1} {		
			$self rmContFromLists $address
		}
		#add the contact (again, at the right position)
		$self addContToLists $address [::abook::getVolatileData $address state FLN]
		#if it's the only item in the list, just pack it
		if {[llength $contactslist] == 1} {
			pack $w -anchor w
		#if it's the last item
		} elseif { [lindex $contactslist end] == $address } {
			set cid [::md5::md5 [lindex $contactslist end-1]]
			pack $w -after $cwidg.$cid -anchor w 
		#else, pack it before the next contact
		} else {
			set cid [::md5::md5 [lindex $contactslist\
				[expr {[lsearch $contactslist $address] + 1}]]]
			pack $w -before $cwidg.$cid -anchor w
		}	
	}
	
	#######################################################################
	# Helper methods, only called within this object
	#######################################################################

	method addContToLists { address state } {
		#add the contact to the list of his/her state,; only if it's not yet present in the group
		if {[lsearch $contactslist $address] == -1 } {
			#if we want contacts sorted by email change the index to 0 under here
			set ctperstate($state) [lsort -index 1 [lappend ctperstate($state) [list $address [::abook::getNick $address]]]]
		}
		$self updateCL
	}	

	method rmContFromLists { address } {
		foreach state $statecodes {
			set idx [lsearch -index 0 $ctperstate($state) $address]
			set ctperstate($state) [lreplace $ctperstate($state) $idx $idx]
		}		
		$self updateCL
	}


	method updateCL {} {
		set contactslist [list ]
		foreach state $statecodes {
			foreach contact [lindex [array get ctperstate $state] 1] {
				set contactslist [lappend contactslist [lindex $contact 0]]
				
			}
		}
	}
	method getContactsWithState {state} {
		if { $state == "ALL" } {
			return $contactslist		
		} else {
			set list [list ]
			foreach contact [lindex [array get ctperstate $state] 1] {
				lappend list [lindex $contact 0]
			}
			return $list
		}
	}

	method getContactWidget { address } {
		set id [::md5::md5 $address]
		set widg $cwidg.$id

		#check if the contact exists both in ui and memory
		if {([lsearch $contactslist $address] != -1) && [winfo exists $widg]} {
			return $widg
		} else {
			return ""
		}		
	}	

	method toggleState {} {
		if {$options(-state) == 1} {
			set newstate 0
#			$self configure -state 0
		} else {
			set newstate 1
#			$self configure -state 1
		}
		$self configure -state $newstate
		$self titlehover $title.icon on
	}
	
	method titlehover {w state} {
		if {$state == "on"} {
			if {$options(-state) == 1} {
				set img [::skin::loadPixmap contract_hover]
			} else {
				set img [::skin::loadPixmap expand_hover]
			}
		} else {
			if {$options(-state) == 1} {
				set img [::skin::loadPixmap contract]
			} else {
				set img [::skin::loadPixmap expand]
			}
		}
		$w configure -image $img
	}
	method updateCount {{addition 0 }} {
		incr count $addition
		$title.gcount configure -text "($count)"
		if {$options(-hideifempty) && $count < 1} {
			pack forget $self.hideframe
		} else {
			pack $self.hideframe
		}	
	}

	method setConfig {option value} {
		set options($option) $value

		#actions after change of options
		#the space was added so the option isn't passed to the switch command
		switch " $option" {
			" -name" {
				$title.gname configure -text "$options(-name)"
			}
			" -state" {
				if {$value == 1} {
					pack $cwidg
					set img [::skin::loadPixmap contract]
				} else {
					pack forget $cwidg
					set img [::skin::loadPixmap expand]			
				}
				$title.icon configure -image $img
				::config::setKey expanded_group_[winfo name $self] $value
			}
			" -color" {
				$title.gcount configure -fg $options(-color)
				$title.gname configure -fg $options(-color)
			}
			" -hideifempty" {
				$self updateCount
			}
		
		}
			
	}
	
}


snit::widgetadaptor clcontact {

	delegate method * to hull
	delegate option * to hull

	#protocol given options
	option -address -default defaultaddress -configuremethod setConfig
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
		
		$self configurelist $args
		
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
		
	}
	

	method setConfig {option value} {
		set options($option) $value

		switch " $option" {
			" -state" {
				$state configure -text "([trans [::MSN::stateToDescription $value]])"
				$left itemconfigure statusemblem -image [::skin::loadPixmap [::MSN::stateToDescription $value]] 
				#reposition in list ($groupwidg position $contact)
				[winfo parent [winfo parent [winfo parent $self]]] positionContact $options(-address)

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
			
		clgroup $widg.$gid -state $exp -color black -name [lindex $group 0] -hideifempty $options(-hideemptygroups)

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
	method contactBlocked {contact} {
		set groups [$self getContactGroups $contact]
		foreach group $groups {
			set cwidg [$widg.$group getContactWidget $contact]
			if {$cwidg == ""} { return }
			$cwidg configure -blocked 1
		}		
	}

	method contactUnblocked {contact} {
		set groups [$self getContactGroups $contact]
		foreach group $groups {
			set cwidg [$widg.$group getContactWidget $contact]
			if {$cwidg == ""} { return }
			$cwidg configure -blocked 0
		}		
	}

	method contactMoved {args} {
		#if not ordered by group, moving a contact doesn't do anything in the UI
		if { !$options(-orderbygroup) } {
			foreach {contact oldgid newgid} $args {break}

			#remove from the former group
			$widg.$oldgid rmContact $contact

			#add to the new group
			set altgid [$self getContactGroups $contact 1]
			if {$altgid == ""} {
				$widg.$newgid addContact $contact $newgid
			} else {
				$widg.$altgid addContact $contact $newgid
			}
		}
	}

	method contactRemoved {args} {
		foreach {contact gid} $args {break}
		#if gid exists, remove from that group, otherwise, remove from all groups
		if {[winfo exists $widg.$gid]} {
			$widg.$gid rmContact $contact
		} else {
			#remove from all groups where it resides
			foreach gid [$self getContactGroups $contact] {
				$widg.$gid rmContact $contact
			}
		}

	}
	
	method contactAdded {args} {
		foreach {contact newgid} $args {break}
		#add to the new group (only this group!)
		set altgid [$self getContactGroups $contact 1]
		if {$altgid == ""} {
			$widg.$newgid addContact $contact $newgid
		} else {
			$widg.$altgid addContact $contact $newgid
		}			

	}

	method contactNickChange { contact } {
		set groups [$self getContactGroups $contact]
		foreach group $groups {
			set cwidg [$widg.$group getContactWidget $contact]
			if {$cwidg == ""} { return }
			$cwidg configure -nickname [::abook::getNick $contact]
		}
	}	

	method contactPSMChange { contact } {
		set groups [$self getContactGroups $contact]
		foreach group $groups {
			set cwidg [$widg.$group getContactWidget $contact]
			if {$cwidg == ""} { return }
			$cwidg configure -message [::abook::getpsmmedia $contact]
		}
	}

	method contactStateChange { contact } {
		#change state
		set state [::abook::getVolatileData $contact state FLN]
		set groups [::abook::getGroups $contact]
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
					$widg.$gid rmContact $contact
					#add contact to the mobile/offline group
					if { $gid == "online" } { set gid [lindex $groups 0] }
					$widg.$offgroup addContact $contact $gid
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
						$widg.offline rmContact $contact
					}
					if {[winfo exists $widg.mobile]} {
						$widg.mobile rmContact $contact
					}

					if { $gid == "online" } { set gid_ [lindex $groups 0] } else { set gid_ $gid }
					$widg.$gid addContact $contact $gid_
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
			clgroup $widg.$gid -state $exp -color black -name [lindex $group 0] -hideifempty $options(-hideemptygroups)
			pack $widg.$gid -anchor w -side top
		}


		foreach contact [::MSN::sortedContactList] { 
			foreach gid [::abook::getGroups $contact] {
				set altgid [$self getContactGroups $contact 1]
				if {$altgid == ""} {
					if {!$options(-orderbygroup)} {
						set altgid "online"
					} else {
						set altgid $gid
					}
				}
				$widg.$altgid addContact $contact $gid
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
		
	method getContactGroups { contact {offonly 0}} {
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
					clgroup $widg.offline -state $exp -color black -name [trans offline] -hideifempty $options(-hideemptygroups)
					pack $widg.offline -anchor w -side top

					#foreach group, get the offline contacts and move 'm to the offline group
					foreach groupwidg [$self getGroupWidgets] {
						set group [winfo name $groupwidg]
						foreach contact [$widg.$group getContactsWithState FLN] {
							#don't change for mobile group
							if {$group != "mobile" } {
								$widg.$group rmContact $contact
								$widg.offline addContact $contact $group
							}
						}
					}
				#UNgroup offline contacts
				} else {
					#move all contacts from the offline group to their respective groups
					foreach contact [$widg.offline getContactsWithState FLN] {
						foreach group [::abook::getGroups $contact] {
							$widg.offline rmContact $contact
							$widg.$group addContact $contact $group
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
					clgroup $widg.mobile -state $exp -color black -name [trans mobile] -hideifempty $options(-hideemptygroups)
					if { [winfo exists $widg.offline] } {
						pack $widg.mobile -anchor w -side top -before $widg.offline
					} else {
						pack $widg.mobile -anchor w -side top
					}

					#move all mobile contacts to mobiule group
					foreach contact [::MSN::sortedContactList] { 
						#if it's a mobile contact
						if { [::abook::getContactData $contact msn_mobile] == "1" && [::abook::getVolatileData $contact state FLN] == "FLN" } {
							
							set contactgroups [::abook::getGroups $contact]
							#see in what groups the contact is now
							if {$options(-orderbygroup) && !$options(-groupoffline)} {
								set groups $contactgroups
							} else {
								set groups offline
							}
							
							#remove it from each of these groups
							foreach group $groups {
								$widg.$group rmContact $contact
							}

							#listen carefully, I'm gonna add this only once
							if {[$self getContactGroups $contact 1] == "mobile"} {
								$widg.mobile addContact $contact [lindex $contactgroups 0]
							}
						}
					}
				} else {
					#remove all mobile users, add 'm to their groups
					foreach contact [$widg.mobile getContactsWithState FLN] {
						$widg.mobile rmContact $contact
						foreach gid [::abook::getGroups $contact] {
							set altgid [$self getContactGroups $contact 1]
							if {$altgid == ""} {
								if {!$options(-orderbygroup)} {
									set altgid "online"
								} else {
									set altgid $gid
								}
							}
							$widg.$altgid addContact $contact $gid
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
