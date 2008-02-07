##################################################
#  This plugin implements the Search Contact on  #
#  the bottom of the contactlist, as seen in MSN #
#   ===========================================  #
#   Search Contact Plugin Square87 & Takeshi '07 #
#	refactored by Karel "scapor" Demeyer '08 #
#  ============================================  #
##################################################

#TODO: so a binding on the main menu for any-key that stores that keypress, focusses the bar and inserts the pressed key ?

namespace eval ::searchcontact {

	proc Init { dir } {

		::plugins::RegisterPlugin "Search Contact"
		::plugins::RegisterEvent "Search Contact" contactlistLoaded drawSearchBar
		::plugins::RegisterEvent "Search Contact" OnDisconnect removeSearchBar
		::plugins::RegisterEvent "Search Contact" Load pluginFullyLoaded



		#load language files
		set langdir [file join $dir "lang"]
		load_lang en $langdir
		load_lang [::config::getGlobalKey language] $langdir

		#Setting the default configuration
	#searchtypes:
	# 0 Everything
	# 1 Nickname/PSM
	# 2 Account
	# 3 Groups
	# 4 Notes (if plugin loaded)
		array set ::searchcontact::config {
			searchtype 0
			filter_blocked 0
			filter_removedme 0
			input ""
			historylist ""
			usewildcards 0
			enableoperators 0
			storelastinput 0
		}
		set ::searchcontact::configlist [list \
			[list bool "[trans usewildcards]" usewildcards] \
			[list bool "[trans enableoperators]" enableoperators] \
			[list bool "[trans storelastinput]" storelastinput] \
		]

		#load the icons
		::skin::setPixmap search search.png pixmaps [file join "$dir" pixmaps]
		::skin::setPixmap clear clear.png pixmaps [file join "$dir" pixmaps]

		#clearing some vars before use
		set ::searchcontact::firstcontact ""
		variable clblocked 0

		#History begin settings
		variable history [list ]
		variable stepsback 0		


	}

	proc pluginFullyLoaded {event evpar} {
		upvar 2 $evpar newvar
		if { $newvar(name) == "Search Contact" && $::contactlist_loaded} {
			::searchcontact::drawSearchBar
		}

	}

	proc focusInSearchbar {} {
		variable cluetextpresent
		set input .main.searchbar.sunkenframe.input

		if { $cluetextpresent == 1 } {
			$input configure -fg black
			$input delete 0 end
			set cluetextpresent 0
		}
		update idletasks
		after idle [list after 0 [list focus ${input}]]
	}

	proc focusOutSearchbar {} {
		variable cluetextpresent

		set input .main.searchbar.sunkenframe.input
		
		if { [$input get] == "" } {
			$input configure -fg grey
			$input insert 0 "[trans typeheretofilter]"
			set cluetextpresent 1
		}
	}

	proc removeSearchBar {event evPar} {
		set frame .main.searchbar.sunkenframe
		#remove bindings
		bind . <Control-f> ""
		bind .main <FocusIn> ""
		bind .main <FocusOut> ""		

		if { $event == "OnDisconnect" } { set ::contactlist_loaded 0 } ;# in aMNS 0.97.0 when we log out contactlist_loaded is still 1 
		after cancel ::searchcontact::drawSearchBar
		destroy .main.searchbar
		variable ::guiContactList::external_lock 0
	}

	proc clearSearch { } {
		.main.searchbar.sunkenframe.input delete 0 end
		set ::searchcontact::firstcontact ""
		pack forget .main.searchbar.sunkenframe.clearbutton
		::searchcontact::drawContacts
	}


	proc drawSearchBar {{event none} {evPar ""} } {

		if {![winfo exists .main.searchbar]} {
			#we only register those now as otherwise it's already called during login while the bar isn't even drawn yet
			::plugins::RegisterEvent "Search Contact" ChangeState redoSearch
			::plugins::RegisterEvent "Search Contact" parse_contact redoSearch

			frame .main.searchbar -bg white -borderwidth 1 -highlightthickness 0
			label .main.searchbar.label -text "[trans filter]:" -bg white
			frame .main.searchbar.sunkenframe -relief sunken -bg white
			pack .main.searchbar.label -side left
			pack .main.searchbar.sunkenframe -side left -fill x -expand 1 -padx 20

			set frame .main.searchbar.sunkenframe

			label $frame.searchbutton -image [::skin::loadPixmap search] -bg white	
			entry $frame.input -relief flat -bg white -font splainf -selectbackground #b7d1ff -fg grey
			label $frame.clearbutton -image [::skin::loadPixmap clear]  -bg white

			pack $frame.searchbutton -side left
			pack $frame.input -side left -fill x -expand 1
			pack .main.searchbar -fill x -expand false
			bind $frame.clearbutton <<Button1>> ::searchcontact::clearSearch
			bind $frame.searchbutton <<Button1>> "::searchcontact::showFilterMenu %X %Y"
			bind $frame.input <Any-Key> "after cancel ::searchcontact::drawContacts;after 250 ::searchcontact::drawContacts;after 0 ::searchcontact::updateClearIcon"
			bind $frame.input <Return> ::searchcontact::enterPressed
			bind $frame.input <<Escape>> ::searchcontact::clearSearch
	#		binding to give focus
			bind . <Control-f> "focus $frame.input"
			
			#history bindings
			bind $frame.input <Key-Up> ::searchcontact::historyUp
			bind $frame.input <Key-Down> ::searchcontact::historyDown


			#insert the clue text
			variable cluetextpresent 1
			$frame.input insert 0 "[trans typeheretofilter]"
			

			#bindings to remove/add clue text
			bind .main <FocusIn> ::searchcontact::focusInSearchbar
			bind .main <FocusOut> ::searchcontact::focusOutSearchbar

			if { $::searchcontact::config(storelastinput) == 1 } {
				#set the stored input
				::searchcontact::restoreSavedInput
			}

		} else {
			variable output ""
			destroy .main.searchbar
			variable ::guiContactList::external_lock 0
			::guiContactList::organiseList .main.f.cl.cvs [::guiContactList::getContactList]
		}
	}

	proc enterPressed {} {
		variable history
		variable stepsback

		if {$::searchcontact::firstcontact != ""} { 
			::amsn::chatUser $::searchcontact::firstcontact
			#change history
			lappend history [::searchcontact::getInput]			
			set stepsback 0

			#now remove the filter
			::searchcontact::clearSearch
		}

	}

	proc historyUp {} {
		variable history
		variable stepsback

		set historysteps [llength $history]

		if { $stepsback < [expr { $historysteps } ] } {
			incr stepsback
			set input [lindex $history [expr { $historysteps - $stepsback} ]]
			set i .main.searchbar.sunkenframe.input
			$i delete 0 end
			$i insert 0 $input
			#now redo the search
			::searchcontact::redoSearch historyScroll
			::searchcontact::updateClearIcon
		} else { 
			::searchcontact::flashSearchBar
		}
	}

	proc historyDown {} {
		variable history
		variable stepsback

		set historysteps [llength $history]

		if { $stepsback > 0 } {
			incr stepsback -1
			set input [lindex $history [expr { $historysteps - $stepsback} ]]
			set i .main.searchbar.sunkenframe.input
			$i delete 0 end
			$i insert 0 $input
			#now redo the search
			::searchcontact::redoSearch historyScroll
			::searchcontact::updateClearIcon
		} else {
			::searchcontact::flashSearchBar
		}
	}

	proc flashSearchBar {} {
		set flashcolor #f4a3a3

		foreach widget [list .main.searchbar.sunkenframe.searchbutton .main.searchbar.sunkenframe.input .main.searchbar.sunkenframe.clearbutton ]  {
			$widget configure -bg $flashcolor
			after 100 $widget configure -bg white
		}

	}

	proc resetSearchBarColor {} {
		foreach widget [list .main.searchbar.sunkenframe.searchbutton .main.searchbar.sunkenframe.input .main.searchbar.sunkenframe.clearbutton ]  {
			$widget configure -bg white
		}
	}

	proc updateClearIcon {} {
		if {[getInput] != ""} {
			#show icon to clear if input is not empty
			pack .main.searchbar.sunkenframe.clearbutton -side right
		} else {
			#remove icon if input is empty
			pack forget .main.searchbar.sunkenframe.clearbutton
		}
	}

	proc restoreSavedInput {} {
		variable clblocked
		variable history

		set input [lindex $::searchcontact::config(historylist) end]
		set history [lrange $::searchcontact::config(historylist) 0 end-1]

		#if there's some filter applied, block the cl redrawing
		if {$input != ""} {
			::searchcontact::focusInSearchbar
			#set the stored input
			.main.searchbar.sunkenframe.input insert 0 "$input"
			::searchcontact::updateClearIcon
			set clblocked 1
		} elseif { $::searchcontact::config(filter_blocked) || $::searchcontact::config(filter_removedme) } {
			set clblocked 1
		} else {
			set clblocked 0
			return
		}

		#search to have the filters applied
		after 1 ::searchcontact::redoSearch

	}

	proc showFilterMenu {x y} {
		set m .filtermenu
		set notesloaded [namespace exists ::notes]

		if { $notesloaded && $::searchcontact::config(searchtype) == 4 } {
			set ::searchcontact::config(searchtype) 0
		}	
		if { [winfo exists $m] } { destroy $m }
		menu $m -tearoff 0 -type normal
		$m add radiobutton -label "[trans all]" \
			-value 0 -variable ::searchcontact::config(searchtype) -command ::searchcontact::redoSearch
		$m add radiobutton -label "[trans nickandpsm]" \
			-value 1 -variable ::searchcontact::config(searchtype)  -command ::searchcontact::redoSearch
		$m add radiobutton -label "[trans account]" \
			-value 2 -variable ::searchcontact::config(searchtype)  -command ::searchcontact::redoSearch
		$m add radiobutton -label "[trans groupname]" \
			-value 3 -variable ::searchcontact::config(searchtype)  -command ::searchcontact::redoSearch
		if { $notesloaded }  {
			$m add radiobutton -label "[trans note]" \
				-value 4 -variable ::searchcontact::config(searchtype)  -command ::searchcontact::redoSearch
		}
		$m add separator
		$m add checkbutton -label "[trans filterblocked]" \
				-onvalue 1 -offvalue 0 -variable ::searchcontact::config(filter_blocked)  -command [list ::searchcontact::redoSearch filterChange]
		$m add checkbutton -label "[trans filterremovedme]" \
				-onvalue 1 -offvalue 0 -variable ::searchcontact::config(filter_removedme)  -command [list ::searchcontact::redoSearch filterChange]

		tk_popup $m $x $y
	}


	proc DeInit { } {
		variable cluetextpresent
		if { $::searchcontact::config(storelastinput) == 1} {
			variable history
			set history [lappend history [getInput]]
			set ::searchcontact::config(historylist) [lrange $history end-9 end]
		}
		::searchcontact::removeSearchBar deInit ""
		#redraw CL
		::guiContactList::organiseList .main.f.cl.cvs [::guiContactList::getContactList]
		variable clblocked
		unset clblocked
		#can't delete 'm as the skins system thinks it's still loaded afterwards
#		image delete [::skin::loadPixmap search]
#		image delete [::skin::loadPixmap clear]

	}


	proc getInput {} {
		variable cluetextpresent
		set input .main.searchbar.sunkenframe.input

		if {[winfo exists $input] && $cluetextpresent != 1} {                    
                        return [string tolower [$input get] ]
		} else {
			return ""
		}
	}

	#return a list of contacts filtered according to $searchtype
	proc filterContacts {input} { 
		set type $::searchcontact::config(searchtype)

		#Parse $input to backslash some chars
		set input [string map -nocase { "[" "\\[" "]" "\\]" "\\" "\\\\" } $input]

		if { $::searchcontact::config(usewildcards) != 1 } {
			set input [string map -nocase [list {?} {\?} {*} {\*}] $input ]
		}
		
		#set default operator
		set operator "EX"
		
		if { $::searchcontact::config(enableoperators) == 1 } {
			#check for OR or EX at the beginning
			if { [string first "& " $input ] == 0 } {
				#exact phrase matching
				set operator "AND"
				set input [string range $input 2 end]
			} elseif { [string first "| " $input] == 0} {
				#if only one of the keywords match
				set operator "OR"
				set input [string range $input 2 end]
			}

			if {$operator == "AND" || $operator == "OR" } {
				set inputs [split $input " ,\n\t;"]
				#remove empty list items
				foreach index [lsort -decreasing [lsearch -all $inputs ""]] {
					set input [lreplace $inputs $index $index]
				}
			}
		}
		if { $operator == "EX" } {
			set input [list "$input"]
		}

	#searchtypes:
	# 0 Everything
	# 1 Nickname/PSM
	# 2 Account
	# 3 Groups	
	# 4 Notes


		#make it possible to search without input
		if {$input == ""} {
			set input [list ""]
		}

		if {[namespace exists ::notes]} {
			set searchnotes 1
		} else {
			set searchnotes 0
		}

		#search for every input item for matches
		set matches [list ]
		foreach item $input {
			set output [list ]
			foreach contact [::MSN::sortedContactList] {
		#Filters:
		#filter_blocked
		#filter_removedme
				#don't think about adding not blocked/removedme contacts if the filter is on
				if {	($::searchcontact::config(filter_blocked) == 1 && [string last "BL" [::abook::getContactData $contact lists]] == -1) ||\
					($::searchcontact::config(filter_removedme) == 1 && [string last "RL" [::abook::getContactData $contact lists]] != -1)
				} { continue }


				#if no input, add all users that passed the filters
				if {$input == ""} { 
					lappend output $contact
					continue
				}



				#filter per searchtype
				#we search first in the email because there isn't the need to call a proc. So it's more speed.
				if {$type == 2 || $type == 0} {
					if { [string match "*$item*" $contact] == 1 } {
						if { [lsearch output $contact] == -1 } {
							lappend output $contact
							continue
						}
					}
				}
				if {$type == 1 || $type == 0} {
					if {	[string match "*$item*" [string tolower [::abook::getNick $contact]]] == 1 || \
						[string match "*$item*" [string tolower [::abook::getVolatileData $contact PSM]]] == 1 ||\
						[string match "*$item*" [string tolower [::abook::getContactData $contact customnick]]] == 1
					} {

						if { [lsearch output $contact] == -1 } {
							lappend output $contact
							continue
						}
					}
				}
				if {$type == 3 || $type == 0} {

					foreach group [::abook::getGroupsname $contact] {
						if { [string match -nocase "*$item*" $group] == 1 } {
							if { [lsearch output $contact] == -1 } {lappend output $contact}
						}
					}			
				}
				if {$searchnotes == 1 && ($type == 4 || $type == 0)} {

					if {[::notes::get_Note $contact] != ""} {
						catch {
							if { [lsearch -regexp [string tolower $::notes::notes] [string tolower $item]] != -1 } {
								if { [lsearch output $contact] == -1 } {lappend output $contact}
							} 
						}
					}
				}

			}
			lappend matches [lsort -unique $output]
		}

		#now calc what to do for each operator
		switch $operator {
			"EX" {
				return $matches
			}
			"AND" {
				if {[llength $matches] == 1} {
					return  [lindex $matches 0]
				} else {
					#if we have more match-lists we have to retun a list with items that are in ALL match-lists				
					set nrmatches [llength $matches]
					#search for the shortest list
					set shortest [lindex [lsort -unique -command ::searchcontact::shortestList $matches] 0]
					set matches [join $matches]

					#go through each item of the first (shortest) list and check how many times it is in the whole list of matches
					set output [list ]
					foreach item $shortest {
						set indices [lsearch -all $matches $item]
						if {[llength $indices] == $nrmatches} {
							lappend output $item
						}
					}
					return $output
					
				}			
			}
			"OR" {
				#add all elements to the output but remove doubles
				set output [lsort -unique [join $matches]]
				return $output
				
			}

		}

	}

	proc shortestList {list1 list2} {
		set length1 [llength $list1]
		set length2 [llength $list2]
		if { $length1 > $length2 } {
			return 1
		} elseif { $length1 == $length2 } {
			return 0
		} else {
			return -1
		}
	}


	#Do the drawing of the CL.main.searchbar.sunkenframe.input
	proc drawContacts {} {
		variable cluetextpresent
		if {$cluetextpresent == 1} {
			return
		}

		variable ::guiContactList::external_lock
		set input [getInput]
		set ::searchcontact::firstcontact ""

		#if any filter is applied, block the drawing
		if {$input == "" && $::searchcontact::config(filter_blocked) == 0 && $::searchcontact::config(filter_removedme) == 0} {
			::searchcontact::resetSearchBarColor
			set ::guiContactList::external_lock 0
			::guiContactList::drawContacts .main.f.cl.cvs
			#redraw CL
			::guiContactList::organiseList .main.f.cl.cvs [::guiContactList::getContactList]
			
			variable clblocked 0
			return ""
		}

		set filtered [filterContacts $input]

		set output_element [list]
		if {$filtered != [list "" ] } {
			::searchcontact::resetSearchBarColor
			foreach element [::guiContactList::getContactList full] {
				#if the element is not a contact
				if {[lindex $element 0] != "C"} {
					#if the latest item in $output_element is not a contact (thus is a group)
					if {[lindex [lindex $output_element end] 0] != "C"} {
						#replace the latest element (the group) with this element (this group)
						#this removes empty groups
						set output_element [lreplace $output_element end end]
					}
					#append every element (groups here only) to $output_element
					lappend output_element [lindex $element]
				#if the element is a contact, and is in the filtered list, add it to $output_element
				} elseif {[string first [lindex $element 1] $filtered] != -1} {
					lappend output_element [lindex $element]
				}
			}

			#if the latest item is not a contact (thus a group), remove it
			if {[lindex [lindex $output_element end] 0] != "C"} {
				set output_element [lreplace $output_element end end]
			}

			set ::searchcontact::firstcontact [lindex [lsearch -regexp -inline $output_element [list "C" *]] 1]

			set groupID "offline"
			set ::guiContactList::external_lock 0

			foreach element $output_element {
				#draw each contact according to it's group
				if {[lindex $element 0] == "C" } {
					::guiContactList::drawContact .main.f.cl.cvs $element $groupID
				} else {
					set groupID [lindex $element 0]
				}
			}
		} else {
			foreach widget [list .main.searchbar.sunkenframe.searchbutton .main.searchbar.sunkenframe.input .main.searchbar.sunkenframe.clearbutton ]  {
				$widget configure -bg red
			}
		}

		set ::guiContactList::external_lock 0
		::guiContactList::organiseList .main.f.cl.cvs $output_element
		variable clblocked 1
		set ::guiContactList::external_lock $clblocked


	}


	proc redoSearch {{event ""} {evPar ""}} {
		if {!$::contactlist_loaded} { return }
		variable clblocked

		if { $event == "filterChange" || $event == "historyScroll" } {
			set clblocked 1
		}
		
		if { $event == "ChangeState" } {
			set tick 100
		} else {
			set tick 250
		}

		if {$clblocked && [winfo exists .main.searchbar]} {
			after $tick ::searchcontact::drawContacts
		}
	}

	#proc to time our filter proc 
	proc timeSearch { input {loops 100} } {
		set sum 0
		for {set i 0} {$i<$loops} {incr i} { 
			set sum [expr  { $sum + [lindex [time { ::searchcontact::filterContacts $input }] 0]}]
		}
		return [expr { $sum / $loops } ]
	}


}
