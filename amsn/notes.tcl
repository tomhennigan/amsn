  #===========================================#
  #         AMSN's User Notes System          #
  #     By Alberto Díaz Hernández (yozko)     #
  #   Contact at yozko@users.sourceforge.net  #
  #         Started on May 1st 2004           #
  #===========================================#


# The ::notes namespace contains all the notes
# related functions, the NoteBox and so on...
namespace eval ::notes {


	# This proc reads the current user's notes.xml, where all his notes
	# are stored. It binds each parsed note with the 'InjectNote' proc
	# throught the XML parser. 
	proc LoadBox { } {
		global HOME

		if { [file exists [file join ${HOME} "notes.xml"]] } {
			NoteBox clear
			set file [file join ${HOME} "notes.xml"]
			set nbox [sxml::init $file]
			sxml::register_routine $nbox "AMSN_UsersNotes:note" "::notes::InjectNote"
			sxml::parse $nbox
			sxml::end $nbox
			status_log "NOTES: [NoteBox count total] notes loaded\n" green
		}
		return 0
	}


	# This proc creates (or override) the current user's notes.xml to store all his
	# notes. After putting the xml tag and the identifier tag (AMSN_UsersNotes) the
	# proc puts each note's block, replacing the values of the fields with their
	# encoded ones. Finally, it closes the file with the identifier tag.
	proc StoreBox { } {
		global HOME
		
		set nbox [open [file join $HOME notes.xml] w]

		fconfigure $nbox -encoding utf-8
		puts $nbox "<?xml version=\"1.0\" standalone=\"yes\" encoding=\"UTF-8\"?>"
		puts $nbox "<AMSN_UsersNotes>"
		foreach note [NoteBox get all] {
			puts $nbox "<note>"
				puts $nbox "\t<date>[::sxml::xmlreplace [lindex $note 0]]</date>"
				puts $nbox "\t<for>[::sxml::xmlreplace [lindex $note 1]]</for>"
				puts $nbox "\t<subject>[::sxml::xmlreplace [lindex $note 2]]</subject>"
				puts $nbox "\t<body>[::sxml::xmlreplace [lindex $note 3]]</body>"
				puts $nbox "\t<reminder>[::sxml::xmlreplace [lindex $note 4]]</reminder>"
			puts $nbox "</note>"
		}
		puts $nbox "</AMSN_UsersNotes>"
		close $nbox
		status_log "NOTES: [NoteBox count total] notes stored in notes.xml\n" green
		return 0
	}


	# This proc gives us a note with the NoteBox's required format from a group
	# of arguments. So, giving to this proc a date, an owner, a subject, a body
	# and a reminder arguments it will return a Tcl list with the note.
	proc FormatNote { Date For Subject Body Reminder } {
		set note [list $Date $For $Subject $Body $Reminder]
		return $note
	}


	# This proc is called by the XML parser and receives all the XML data from
	# notes.xml. It checks if all the fields are present in the XML output, if
	# one of them is missing, it kills the function returning 0 (NOTE: If you
	# don't return 0, the parsing will fail). Once It's checked, we store in a
	# variable the output of proc 'FormatNote' called with our received XML data
	# and finally we store it in the NoteBOx trought 'NoteBox store', returning
	# 0 at the end (this is mandatory for the parser).
	proc InjectNote { cstack cdata saved_data cattr saved_attr args } {
		upvar $saved_data sdata
		
		if { ! [info exists sdata(${cstack}:date)] } { return 0 }
		if { ! [info exists sdata(${cstack}:for)] } { return 0 }
		if { ! [info exists sdata(${cstack}:subject)] } { return 0 }
		if { ! [info exists sdata(${cstack}:body)] } { return 0 }
		if { ! [info exists sdata(${cstack}:reminder)] } { return 0 }
		
		set note [FormatNote "$sdata(${cstack}:date)" "$sdata(${cstack}:for)" "$sdata(${cstack}:subject)" "$sdata(${cstack}:body)" "$sdata(${cstack}:reminder)"]
		NoteBox store $note
		
		return 0
	}

	
	# This proc should be used as a 'virtual object' to store the current user's
	# notes, something like a MailBox. We can store notes in the NoteBox, detele
	# or edit them, get them by ID (index of the note in the list), by contact
	# (the note's owner) or get all the notes in the NoteBox, get the number of
	# notes in the NoteBox or the number of notes that a user owns... 
	proc NoteBox { Action {Argument1 ""} {Argument2 ""} } {
		variable notebox

		switch $Action {
			clear {
				if { [info exists notebox] } {
					unset notebox
				}
			}
			store {
				lappend notebox $Argument1
			}
			delete {
				set notebox [lreplace $notebox $Argument1 $Argument1]
			}
			edit {
				lset notebox $Argument1 $Argument2
			}
			get {
				if { $Argument1 == "ID" } {
					return [lindex $notebox $Argument2]
				} elseif { $Argument1 == "contact" } {
					foreach idx [lsearch -all $notebox "* $Argument2 *"] {
						lappend contactbox [lindex $notebox $idx]
					}
					return $contactbox
				} elseif { $Argument1 == "all" } {
					return $notebox
				}
			}
			count {
				if { $Argument1 == "total" } {
					return [llength $notebox]
				} elseif { $Argument1 == "contact" && $Argument2 != "" } {
					set buffer [lsearch -all $notebox "* $Argument2 *"]
					return [llength $buffer]
				}
			}
		}
	}
	
	
	# -- INCOMPLETE --
	# This proc should draw the notes GUI in the specified parent widget,
	# the GUI will be a listbox, wich will act as an 'Inbox list' and an
	# entry or text widget for editable fields (like Title and Body) and
	# labels for informative fields (like date, for, and so on).
	proc GUI { widget } {
		frame $widget.noteslist -relief sunken -borderwidth 3
        	label $widget.noteslist.header -text "NOTAS"
		listbox $widget.noteslist.box -yscrollcommand "$widget.noteslist.scroll set" -font splainf -background \
		white -relief flat -highlightthickness 0 -height 7 -width 70
		scrollbar $widget.noteslist.scroll -command "$widget.noteslist.box yview" -highlightthickness 0 \
        	-borderwidth 1 -elementborderwidth 2
        	frame $widget.viewer
		label $widget.viewer.ltitle -text "Title:" -font splainf
		entry $widget.viewer.etitle -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 65
		label $widget.viewer.lnote -text "Note:" -font splainf
		text $widget.viewer.enote -background white -borderwidth 2 -relief ridge -width 65 -height 7 -font splainf
		
		pack $widget.noteslist.header $widget.noteslist.box -side top -expand false
		pack $widget.noteslist.scroll -side right -fill y
		pack $widget.noteslist.box -side left -expand true -fill both
		pack $widget.noteslist -side top -anchor center -expand false -fill both
		grid $widget.viewer.ltitle -row 1 -column 1 -sticky w -pady 5 -padx 3
		grid $widget.viewer.etitle -row 1 -column 2 -sticky w -pady 5 -padx 3
		grid $widget.viewer.lnote -row 2 -column 1 -sticky w -pady 5 -padx 3
		grid $widget.viewer.enote -row 2 -column 2 -sticky w -pady 5 -padx 3
		pack $widget.viewer -side top -anchor center -expand false -fill both
	}
	
}