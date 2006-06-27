  #===========================================#
  #         AMSN's User Notes System          #
  #                By Fred                    #
  #         Started on May 1st 2004           #
  #===========================================#


# The ::notes namespace contains all the notes
# related functions
namespace eval ::notes {


#//////////////////////////////////////////////////////////////
# Get the available notes for a contact

	proc get_Note { email } {

		global HOME

		set ::notes::notes [list]

		set file [file join $HOME notes ${email}_note.xml]

		if { [file exists $file] } {

			set id [::sxml::init $file]
  			sxml::register_routine $id "notes:note" "::notes::XML_Note"
  			sxml::parse $id
  			sxml::end $id

		} else {
			set ::notes::notes ""
		}
  	 
  	}
  	 
  	 
  	proc XML_Note { cstack cdata saved_data cattr saved_attr args } {
  		upvar $saved_data sdata
  	 
  		set ::notes::notes [lappend ::notes::notes [list "$sdata(${cstack}:created)" "$sdata(${cstack}:modified)" "$sdata(${cstack}:subject)" "$sdata(${cstack}:content)"]]
  	 
  		return 0
  	 
  	}


#//////////////////////////////////////////////////////////////
# Display the notes

	proc Display_Notes { {email ""} } {

		global HOME

		set w ".notemanager"
  	 
  		if {[winfo exists $w]} {
  			raise $w
  			return
  		}
  	 
  		toplevel $w
  		wm title $w "[trans note]"
  		wm geometry $w 660x526+30+30
  		wm protocol $w DELETE_WINDOW "::notes::Display_Notes_Close"		


		# Create the frame containing the list of the contacts
		frame $w.contact -relief sunken -borderwidth 3 
  		listbox $w.contact.box -yscrollcommand "$w.contact.ys set" -font splainf -background white -relief flat -highlightthickness 0 -height 10 -width 20 -selectbackground gray
  		scrollbar $w.contact.ys -command "$w.contact.box yview" -highlightthickness 0 -borderwidth 1 -elementborderwidth 2
  		pack $w.contact.ys -side right -fill y
  		pack $w.contact.box -side left -expand true -fill both

		foreach contact [::abook::getAllContacts] {
			#Selects the contacts who are in our list
			if { [string last "FL" [::abook::getContactData $contact lists]] != -1 } {
				lappend contact_list $contact
			}
		}

		# Sorts contacts
		set sortedcontact_list [lsort -dictionary $contact_list]
		set ::notes::contacts $sortedcontact_list
		set ::notes::contactswithnotes [list]
		# Search contacts with notes
		foreach contact $sortedcontact_list {
			if { [file exists [file join $HOME notes ${contact}_note.xml]] == 1 } {
				lappend ::notes::contactswithnotes $contact
			}
		}
			
		
		foreach contact $sortedcontact_list {
			$w.contact.box insert end "$contact"
		}


		frame $w.right -borderwidth 30


		# Display the E-Mail of the contact
		frame $w.right.contact
		frame $w.right.contact.right
		label $w.right.contact.right.note -text "[trans contact]" -font bigfont
		set nickname "[trunc [::abook::getDisplayNick $email] $w 410 sboldf]"
		label $w.right.contact.right.txt -text "$email\n$nickname" -font sboldf
		pack configure $w.right.contact.right.note -expand false
		pack configure $w.right.contact.right.txt -expand true
		pack configure $w.right.contact.right -expand true -side right
		# Display the show/hide button
		frame $w.right.contact.left
		image create photo hide -file [::skin::GetSkinFile pixmaps contract.gif] -format cximage
		image create photo show -file [::skin::GetSkinFile pixmaps expand.gif] -format cximage
		label $w.right.contact.left.showhide
		pack configure $w.right.contact.left.showhide -side left
		pack configure $w.right.contact.left -side left


		# Create the listbox containing the notes
  		frame $w.right.notes -relief sunken -borderwidth 3
  		label $w.right.notes.current -text "[trans currentnotes]" -font sboldf
  		listbox $w.right.notes.box -yscrollcommand "$w.right.notes.ys set" -font splainf -background white -relief flat -highlightthickness 0 -height 5 -width 60
  		scrollbar $w.right.notes.ys -command "$w.right.notes.box yview" -highlightthickness 0 -borderwidth 1 -elementborderwidth 2
  		pack $w.right.notes.current -expand false -fill x
  		pack $w.right.notes.box -side left -expand true -fill both
			
		#We are not using pixmapscroll on Mac OS X
		if { ![OnMac] } {
			$w.right.notes.ys configure -height [winfo height $w.right.notes.box]
		}
  		pack $w.right.notes.ys -side right -fill y -expand false


		# Create the frame containing informations about the note
		frame $w.right.info -borderwidth 3
		label $w.right.info.date -text "[trans clicktoadd]"
		pack configure $w.right.info.date -side top -fill x


		# Display the subject of the note
		frame $w.right.subject -relief sunken -borderwidth 3
		label $w.right.subject.desc -text "[trans subject]" -font sboldf
		text $w.right.subject.txt -font splainf -background white -relief flat -highlightthickness 0 -height 1 -width 60 -state disabled
		pack $w.right.subject.desc -expand false -fill both
		pack $w.right.subject.txt -expand false -fill both
		

		# Display the note
		frame $w.right.note -relief sunken -borderwidth 3
		label $w.right.note.desc -text "[trans note]" -font sboldf
		text $w.right.note.txt -yscrollcommand "$w.right.note.ys set" -font splainf -background white -relief flat -highlightthickness 0 -height 5 -width 60 -state disabled -wrap word -exportselection 1
  		scrollbar $w.right.note.ys -command "$w.right.note.txt yview" -highlightthickness 0 -borderwidth 1 -elementborderwidth 2
  		pack $w.right.note.desc -expand false -fill x
  		pack $w.right.note.ys -side right -fill y
  		pack $w.right.note.txt -side left -expand true -fill both


		# Display a warning message when no subject is given to a note
		frame $w.right.warning
		label $w.right.warning.txt -text ""
		pack configure $w.right.warning.txt -fill x


		# Create the buttons
		frame $w.right.button
		button $w.right.button.edit -text "[trans edit]" -command "::notes::Note_Edit" -state disabled
		button $w.right.button.delete -text "[trans delete]" -command "::notes::Note_Delete" -state disabled
		button $w.right.button.new -text "[trans add]" -command "::notes::Note_New" -state disabled

		button $w.right.button.save_edit -text "[trans save]" -command "::notes::Note_SaveEdit"
		button $w.right.button.save -text "[trans save]" -command "::notes::Note_SaveNew"
		button $w.right.button.cancel -text "[trans cancel]" -command "::notes::Note_Cancel"

		pack configure $w.right.button.edit -side left -padx 3 -pady 3
		pack configure $w.right.button.delete -side right -padx 3 -pady 3
		pack configure $w.right.button.new -side right -padx 3 -pady 3
		# Create the close button
		frame $w.right.close
		button $w.right.close.button -text "[trans close]" -command "::notes::Display_Notes_Close"
		pack configure $w.right.close.button -side right -padx 3

		
		#If user click on a note, display the note
  		bind $w.right.notes.box <<ListboxSelect>> "::notes::Notes_Selected_Note"
  		#If user click on a contact at left
		bind $w.contact.box <<ListboxSelect>> "::notes::Notes_Selected_Contact"
		bind $w.right.subject.txt <Button1-ButtonRelease> "::notes::Note_New"
		bind $w.right.note.txt <Button1-ButtonRelease> "::notes::Note_New"
		
		
  		pack $w.contact -side left -fill y -expand false
		pack $w.right -side right -fill both -expand true

		pack $w.right.close $w.right.button -side bottom -fill x
		pack $w.right.contact -side top -fill x
		pack $w.right.notes -side top -fill both -expand true

		pack $w.right.info -side top -fill x
		pack $w.right.subject -side top -fill x
		pack $w.right.note -side top -fill both  -expand true
		pack $w.right.warning -side top -fill x


		bind $w.right.subject.txt <Tab> "focus $w.right.note.txt; break"

		# If the E-Mail is not given, display the first contact and show the contact list
		if { $email == "" } {
			::notes::ShowContact
			set email [lindex $::notes::contacts 0]
		
		} else {
			::notes::HideContact
		
		}
		set ::notes::email $email
		::notes::get_Note $email
  		foreach note $::notes::notes {
  			set subject [lindex $note 2]
  			$w.right.notes.box insert end "$subject"
  		}

		$w.right.button.new configure -state normal
		set ::notes::selectedcontact [lsearch $::notes::contacts $email]
		set ::notes::selected "-1"

		::notes::Update_Contact_Background

		bind $w <<Escape>> "::notes::Display_Notes_Close"
		
		bind $w <<Cut>> "tk_textCut $w.right.note.txt"
		bind $w <<Copy>> "tk_textCopy $w.right.note.txt"
		bind $w <<Paste>> "::notes::Paste"
		
	}


#//////////////////////////////////////////////////////////////

	proc Paste { } {
	
	set w ".notemanager"
	set text [clipboard get]
	$w.right.note.txt insert insert "$text"
	
	}


#//////////////////////////////////////////////////////////////
# When the window is closed



	proc Display_Notes_Close { } {



		unset -nocomplain ::notes::email

		unset -nocomplain ::notes::selected

		unset -nocomplain ::notes::selectedcontact

		unset -nocomplain ::notes::notes

		unset -nocomplain ::notes::contacts

		unset -nocomplain ::notes::contactswithnotes


		destroy .notemanager



	}


#//////////////////////////////////////////////////////////////
# Display the content of a note when its subject is selected

	proc Notes_Selected_Note { {selec current} {selection 0} } {

		set w ".notemanager"


		switch $selec {

			choose {
				$w.right.notes.box selection set $selection
			}

			current {
				set selection [$w.right.notes.box curselection]
				if { $selection == "" } {
					return
				}
			}

			last {
				set selection [expr {[.notemanager.right.notes.box size] - 1}]
				$w.right.notes.box selection set $selection
			}

		}


		set ::notes::selected $selection

		set note [lindex $::notes::notes $selection]

		set created [lindex $note 0]
		set modified [lindex $note 1]
		set subject [lindex $note 2]
		set text  [lindex $note 3]

		$w.right.note.txt configure -state normal
		$w.right.note.txt delete 0.0 end
		$w.right.note.txt insert end "$text"
		$w.right.note.txt configure -state disabled

		$w.right.subject.txt configure -state normal
		$w.right.subject.txt delete 0.0 end
		$w.right.subject.txt insert end "$subject"
		$w.right.subject.txt configure -state disabled
		
		#Show created and modified info only if it exists
		if { $created != "" & $modified != ""} {
			$w.right.info.date configure -text "[trans created] : [::abook::dateconvert $created]  -  [trans modified] : [::abook::dateconvert $modified]"
		} else {
			$w.right.info.date configure -text "[trans clicktoadd]"
		}

		$w.right.button.edit configure -state normal
		$w.right.button.delete configure -state normal
		$w.contact.box itemconfigure $::notes::selectedcontact -background gray

		
	}


#//////////////////////////////////////////////////////////////
# Display the notes of a contact when they are selected

	proc Notes_Selected_Contact { } {

		global HOME

		set w ".notemanager"
		if {[$w.contact.box cget -state] == "disabled"} {
			return
		}


		$w.contact.box itemconfigure $::notes::selectedcontact -background white

		set selection [$w.contact.box curselection]
		set ::notes::selectedcontact $selection
		set ::notes::selected "-1"

		set contact [lindex $::notes::contacts $selection]

		$w.right.notes.box delete 0 end

		if { [file exists [file join $HOME notes ${contact}_note.xml]] } {
			::notes::get_Note $contact
			foreach note $::notes::notes {
  				set subject [lindex $note 2]
  				$w.right.notes.box insert end "$subject"
  			}
		} else {
			set ::notes::notes ""
		}

		set ::notes::email $contact
		set nickname "[trunc [::abook::getDisplayNick $contact] $w 410 sboldf]"
		$w.right.contact.right.txt configure -text "$contact\n$nickname" -font sboldf

		$w.right.button.new configure -state normal
		$w.right.note.txt configure -state normal
		$w.right.note.txt delete 0.0 end
		$w.right.note.txt configure -state disabled
		$w.right.subject.txt configure -state normal
		$w.right.subject.txt delete 0.0 end
		$w.right.subject.txt configure -state disabled
		$w.right.info.date configure -text "[trans clicktoadd]"

		$w.right.button.edit configure -state disabled
		$w.right.button.delete configure -state disabled
		
		#Add binding for the subject and note field
		bind $w.right.subject.txt <Button1-ButtonRelease> "::notes::Note_New"
		bind $w.right.note.txt <Button1-ButtonRelease> "::notes::Note_New"
		::notes::Update_Contact_Background

	}


#//////////////////////////////////////////////////////////////
# When we delete a note

	proc Note_Delete { } {

		global HOME

		set w ".notemanager"

		set selection $::notes::selected

		set ::notes::notes [lreplace $::notes::notes $selection $selection]

		::notes::Notes_Save
		::notes::Update_Notes

		$w.right.notes.box selection set $selection
		
		if { $selection == [.notemanager.right.notes.box size] } {
			$w.right.button.edit configure -state disabled
			$w.right.button.delete configure -state disabled
		}
		
		if { [.notemanager.right.notes.box size] == 0 } {
			file delete [file join $HOME notes ${::notes::email}_note.xml]
			set idx [lsearch $::notes::contactswithnotes $::notes::email]
			set ::notes::contactswithnotes [lreplace $::notes::contactswithnotes $idx $idx]
		}

	}


#//////////////////////////////////////////////////////////////
# When we edit a note

	proc Note_Edit { } {

		set w ".notemanager"
		
		#Remove binding on theses 2 textbox
		bind $w.right.subject.txt <Button1-ButtonRelease> ""
		bind $w.right.note.txt <Button1-ButtonRelease> ""
		
		$w.right.notes.box configure -state disabled
		$w.contact.box configure -state disabled

		$w.right.note.txt configure -state normal
		$w.right.subject.txt configure -state normal
		$w.right.info.date configure -text "[trans editcontent]"

		pack forget $w.right.button.delete
		pack forget $w.right.button.new
		pack forget $w.right.button.edit

		pack configure $w.right.button.save_edit -side right -padx 3 -pady 3
		pack configure $w.right.button.cancel -side right -padx 3 -pady 3


	}


	proc Note_SaveEdit { } {

		set w ".notemanager"

		set selection $::notes::selected

		set contact $::notes::email

		set created "[lindex [lindex $::notes::notes $selection] 0]"
		set modified "[clock format [clock seconds] -format "%D - %T"]"
		set subject "[.notemanager.right.subject.txt get 1.0 1.end]"
		set note "[.notemanager.right.note.txt get 0.0 {end - 1 chars}]"

		if { $subject == "" } {
			$w.right.warning.txt configure -text "[trans subjectrequired]" -foreground red
		} else {

			set ::notes::notes [lreplace $::notes::notes $selection $selection [list "$created" "$modified" "$subject" "$note"]]

			::notes::Notes_Save
			::notes::Update_Notes
			::notes::Notes_Selected_Note choose $::notes::selected

		}
		
		bind $w.right.subject.txt <Button1-ButtonRelease> "::notes::Note_New"
		bind $w.right.note.txt <Button1-ButtonRelease> "::notes::Note_New"

	}


#//////////////////////////////////////////////////////////////
# When we create a new note

	proc Note_New { } {

		set w ".notemanager"
		#Remove binding on theses 2 textbox
		bind $w.right.subject.txt <Button1-ButtonRelease> ""
		bind $w.right.note.txt <Button1-ButtonRelease> ""
		
		$w.right.notes.box configure -state disabled
		$w.contact.box configure -state disabled

		$w.right.note.txt configure -state normal
		$w.right.note.txt delete 0.0 end
		$w.right.subject.txt configure -state normal
		$w.right.subject.txt delete 0.0 end
		$w.right.info.date configure -text "[trans inserttextnote]"

		pack forget $w.right.button.delete
		pack forget $w.right.button.new
		pack forget $w.right.button.edit

		pack configure $w.right.button.save -side right -padx 3 -pady 3
		pack configure $w.right.button.cancel -side right -padx 3 -pady 3
		
		focus $w.right.subject.txt

	}


	proc Note_SaveNew { } {

		set w ".notemanager"

		set contact $::notes::email

		set time "[clock format [clock seconds] -format "%D - %T"]"
		set subject "[$w.right.subject.txt get 1.0 1.end]"
		set note "[.notemanager.right.note.txt get 0.0 {end - 1 chars}]"

		if { $subject == "" } {
			$w.right.warning.txt configure -text "[trans subjectrequired]" -foreground red -font sboldf

		} else {

			set ::notes::notes [lappend ::notes::notes [list "$time" "$time" "$subject" "$note"]]

			::notes::Notes_Save
			::notes::Update_Notes
			::notes::Notes_Selected_Note last

			if { [lsearch $::notes::contactswithnotes $::notes::email] == -1 } {
				set ::notes::contactswithnotes [lappend ::notes::contactswithnotes $::notes::email]
			}

		}

		bind $w.right.subject.txt <Button1-ButtonRelease> "::notes::Note_New"
		bind $w.right.note.txt <Button1-ButtonRelease> "::notes::Note_New"

	}


#//////////////////////////////////////////////////////////////
# When we cancel what we were doing (editing or creating a note)

	proc Note_Cancel { } {

		set w ".notemanager"

		pack forget $w.right.button.save
		pack forget $w.right.button.save_edit
		pack forget $w.right.button.cancel

		pack configure $w.right.button.edit -side left -padx 3 -pady 3
		pack configure $w.right.button.delete -side right -padx 3 -pady 3
		pack configure $w.right.button.new -side right -padx 3 -pady 3

		$w.right.notes.box configure -state normal
		$w.contact.box configure -state normal
		$w.right.warning.txt configure -text ""
		bind $w.right.subject.txt <Button1-ButtonRelease> "::notes::Note_New"
		bind $w.right.note.txt <Button1-ButtonRelease> "::notes::Note_New"

		::notes::Update_Notes
		::notes::Notes_Selected_Note choose $::notes::selected
		
	}


#//////////////////////////////////////////////////////////////
# Save all the notes of a contact

	proc Notes_Save { } {

		global HOME

		set email $::notes::email

		set w ".notemanager"

		set file [file join $HOME notes ${email}_note.xml]

		if { ![file isdirectory [file join $HOME notes]] } {
			file mkdir [file join $HOME notes]
		}

		set file_id [open $file w]

		fconfigure $file_id -encoding utf-8

		puts $file_id "<?xml version=\"1.0\"?>\n\n<notes>\n"

		foreach note $::notes::notes {
			set created [lindex $note 0]
			set modified [lindex $note 1]
			set subject [lindex $note 2]
			set content [lindex $note 3]
			puts -nonewline $file_id "\t<note>\n\t\t<created>$created</created>\n\t\t<modified>$modified</modified>\n\t\t<subject>$subject</subject>\n\t\t<content>$content</content>\n\t</note>\n"
		}

		puts $file_id "</notes>"

		close $file_id

		$w.right.subject.txt configure -state disabled
		$w.right.note.txt configure -state disabled

		pack forget $w.right.button.save
		pack forget $w.right.button.save_edit
		pack forget $w.right.button.cancel

		pack configure $w.right.button.edit -side left -padx 3 -pady 3
		pack configure $w.right.button.delete -side right -padx 3 -pady 3
		pack configure $w.right.button.new -side right -padx 3 -pady 3

		$w.right.notes.box configure -state normal
		$w.contact.box configure -state normal

		$w.right.warning.txt configure -text ""

		::notes::Notes_Selected_Note

	}


#//////////////////////////////////////////////////////////////
# Update the display of the notes

	proc Update_Notes { } {

		global HOME

		set w ".notemanager"

		set contact $::notes::email

		$w.right.notes.box delete 0 end

		if { [file exists [file join $HOME notes ${contact}_note.xml]] } {
			::notes::get_Note $contact
			foreach note $::notes::notes {
  				set subject [lindex $note 2]
  				$w.right.notes.box insert end "$subject"
  			}
		} else {
			set ::notes::notes ""
		}

	}


#//////////////////////////////////////////////////////////////

# Update the background of the items of the contact list

proc Update_Contact_Background { } {

	for {set i 0} {$i< [llength $::notes::contacts]} {incr i} {
		if { $i == $::notes::selectedcontact } {
			.notemanager.contact.box itemconfigure $i -background gray
		} elseif { [lsearch $::notes::contactswithnotes [lindex $::notes::contacts $i]] != -1 } {
			.notemanager.contact.box itemconfigure $i -background #DDF3FE
		} else {
			.notemanager.contact.box itemconfigure $i -background white
		}

	}
	
}


#//////////////////////////////////////////////////////////////
#

proc HideContact { } {

	set w ".notemanager"
	pack forget $w.contact
	#pack configure $w.right -side right -fill both -expand true
#	wm geometry $w 550x526
	$w.right.contact.left.showhide configure -image show
	bind $w.right.contact.left.showhide <Button1-ButtonRelease> "::notes::ShowContact"
	
}


proc ShowContact { } {

	set w ".notemanager"
	pack configure $w.contact -side left -fill y
#	wm geometry $w 660x526
	$w.right.contact.left.showhide configure -image hide
	bind $w.right.contact.left.showhide <Button1-ButtonRelease> "::notes::HideContact"
	
}

}
