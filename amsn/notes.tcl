  #===========================================#
  #         AMSN's User Notes System          #
  #     By Alberto Díaz Hernández (yozko)     #
  #   Contact at yozko@users.sourceforge.net  #
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
  		wm title $w "[trans notes]"
  		wm geometry $w 700x500+30+30


		# Create the frame containing the list of the contacts
		frame $w.contact -relief sunken -borderwidth 3
  		listbox $w.contact.box -yscrollcommand "$w.contact.ys set" -font splainf -background white -relief flat -highlightthickness 0 -height 10 -width 25
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
		
		foreach contact $sortedcontact_list {
			$w.contact.box insert end "$contact"
		}


		frame $w.right -borderwidth 3


		# Display the E-Mail of the contact
		frame $w.right.contact
		label $w.right.contact.txt -text "$email"
		pack configure $w.right.contact.txt -expand true -fill x


		# Create the listbox containing the notes
  		frame $w.right.notes -relief sunken -borderwidth 3
  		listbox $w.right.notes.box -yscrollcommand "$w.right.notes.ys set" -font splainf -background white -relief flat -highlightthickness 0 -height 10 -width 60
  		scrollbar $w.right.notes.ys -command "$w.right.notes.box yview" -highlightthickness 0 -borderwidth 1 -elementborderwidth 2
  		pack $w.right.notes.ys -side right -fill y
  		pack $w.right.notes.box -side left -expand true -fill both


		# Create the frame containing informations about the note
		frame $w.right.info -borderwidth 3
		label $w.right.info.date -text ""
		pack configure $w.right.info.date -side top -fill x


		# Display the subject of the note
		frame $w.right.subject -relief sunken -borderwidth 3
		text $w.right.subject.txt -font splainf -background white -relief flat -highlightthickness 0 -height 1 -width 60
		pack $w.right.subject.txt -expand true -fill both


		# Display the note
		frame $w.right.note -relief sunken -borderwidth 3
		text $w.right.note.txt -yscrollcommand "$w.right.note.ys set" -font splainf -background white -relief flat -highlightthickness 0 -height 10 -width 60
  		scrollbar $w.right.note.ys -command "$w.right.note.txt yview" -highlightthickness 0 -borderwidth 1 -elementborderwidth 2
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

  		bind $w.right.notes.box <<ListboxSelect>> "::notes::Notes_Selected_Note"
		bind $w.contact.box <<ListboxSelect>> [list "::notes::Notes_Selected_Contact" "$sortedcontact_list"]
  	   	 
  		pack configure $w.contact -side left -fill y
		pack configure $w.right.contact -side top -fill x
		pack configure $w.right.notes -side top -fill y
		pack configure $w.right.info -side top -fill x
		pack configure $w.right.subject -side top -fill x
		pack configure $w.right.note -side top -fill y
		pack configure $w.right.warning -side top -fill x
		pack configure $w.right.button -side top -fill x
		pack configure $w.right -side right -fill y


		# If the E-Mail is given, display its notes
		set ::notes::email $email
		if { $email != "" } {
			::notes::get_Note $email

  			foreach note $::notes::notes {
  				set subject [lindex $note 2]
  				$w.right.notes.box insert end "$subject"
  			}

			$w.right.button.new configure -state normal

		}

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
				set selection [expr [.notemanager.right.notes.box size] - 1]
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

		$w.right.info.date configure -text "[trans created] : $created  -  [trans modified] : $modified"

		$w.right.button.edit configure -state normal
		$w.right.button.delete configure -state normal

		
	}


#//////////////////////////////////////////////////////////////
# Display the notes of a contact when they are selected

	proc Notes_Selected_Contact { list } {

		global HOME

		set w ".notemanager"

		set selection [$w.contact.box curselection]

		set contact [lindex $list $selection]

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

		$w.right.contact.txt configure -text "$contact"

		$w.right.button.new configure -state normal
		$w.right.note.txt configure -state normal
		$w.right.note.txt delete 0.0 end
		$w.right.note.txt configure -state disabled
		$w.right.subject.txt configure -state normal
		$w.right.subject.txt delete 0.0 end
		$w.right.subject.txt configure -state disabled
		$w.right.info.date configure -text ""

		$w.right.button.edit configure -state disabled
		$w.right.button.delete configure -state disabled

	}


#//////////////////////////////////////////////////////////////
# When we delete a note

	proc Note_Delete { } {

		set selection $::notes::selected

		set ::notes::notes [lreplace $::notes::notes $selection $selection]

		::notes::Notes_Save
		::notes::Update_Notes

		.notemanager.right.notes.box selection set $selection

	}


#//////////////////////////////////////////////////////////////
# When we edit a note

	proc Note_Edit { } {

		set w ".notemanager"

		$w.right.notes.box configure -state disabled
		$w.contact.box configure -state disabled

		$w.right.note.txt configure -state normal
		$w.right.subject.txt configure -state normal
		$w.right.info.date configure -text ""

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

	}


#//////////////////////////////////////////////////////////////
# When we create a new note

	proc Note_New { } {

		set w ".notemanager"

		$w.right.notes.box configure -state disabled
		$w.contact.box configure -state disabled

		$w.right.note.txt configure -state normal
		$w.right.note.txt delete 0.0 end
		$w.right.subject.txt configure -state normal
		$w.right.subject.txt delete 0.0 end
		$w.right.info.date configure -text ""

		pack forget $w.right.button.delete
		pack forget $w.right.button.new
		pack forget $w.right.button.edit

		pack configure $w.right.button.save -side right -padx 3 -pady 3
		pack configure $w.right.button.cancel -side right -padx 3 -pady 3

	}


	proc Note_SaveNew { } {

		set w ".notemanager"

		set contact $::notes::email

		set time "[clock format [clock seconds] -format "%D - %T"]"
		set subject "[$w.right.subject.txt get 1.0 1.end]"
		set note "[.notemanager.right.note.txt get 0.0 {end - 1 chars}]"

		if { $subject == "" } {
			$w.right.warning.txt configure -text "[trans titlerequired]" -foreground red

		} else {

			set ::notes::notes [lappend ::notes::notes [list "$time" "$time" "$subject" "$note"]]

			::notes::Notes_Save
			::notes::Update_Notes
			::notes::Notes_Selected_Note last

		}

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


}