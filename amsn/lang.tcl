
if { $initialize_amsn == 1 } {
    global lang_list langenc langlong

    set lang_list [list]
    set langenc "iso8859-1"
    set langlong "English"
}

proc scan_languages {} {
   global lang_list
   set lang_list [list]

   set file_id [open "langlist" r]
   fconfigure $file_id -encoding utf-8


   while {[gets $file_id tmp_data] != "-1"} {
      set pos [string first " " $tmp_data]
      set langshort [string range $tmp_data 0 [expr {$pos -1}]]
      set pos [expr {$pos + 1}]
      set pos2 [string first " " $tmp_data $pos]
      set langenc [string range $tmp_data $pos [expr {$pos2 -1}]]
      set langlong [string range $tmp_data [expr {$pos2 +1}] [string length $tmp_data]]
      lappend lang_list "{$langshort} {$langlong} {$langenc}"
   }
   close $file_id

}

proc detect_language { {default "en"} } {
	global env
	if { ![info exists env(LANG)] } {
		status_log "No LANG environment variable. Using $default\n"
		return $default
	}
	
	set system_language [string tolower $env(LANG)]
	set idx [string first "@" $system_language]
	status_log "System language is $system_language\n"
	#Remove @euro thing or similar
	if { $idx != -1 } {
		incr idx -1
		set system_language [string range $system_language 0 $idx]
		status_log "Removed @ thing. Now system language is $system_language\n"
	}
	
	set language [language_in_list $system_language]
	if { $language != 0 } {
		status_log "Matching language $language!\n"
		return $language
	}
	
	set idx [string first "_" $system_language]
	#Remove _variant thing, like BR in pt_BR
	if { $idx != -1 } {
		incr idx -1
		set system_language [string range $system_language 0 $idx]
		status_log "Removed _ variant. Now system language is $system_language\n"
	}
	
	set language [language_in_list $system_language]
	if { $language != 0 } {
		status_log "Matching language $language!\n"
		return $language
	}
	status_log "NO matching language. Defaulting to $default\n"	
	return $default
}

proc language_in_list { lang_name } {
	global lang_list
	
	if {![info exists lang_list]} {
		scan_languages
	}
	
	foreach lang_desc $lang_list {
		set lang_short [string tolower [lindex $lang_desc 0]]
		if {[string compare $lang_short $lang_name] == 0 } {
			status_log "Language \"$lang_name\" is in available languages, using it\n" blue
			return [lindex $lang_desc 0]
		}
		
	}
	
	return 0
}

proc trans {msg args} {
	global lang
	for {set i 1} {$i <= [llength $args]} {incr i} {
		set $i [lindex $args [expr {$i-1}]]
	}
	if {[ catch {
			if { [string length $lang($msg)] > 0 } {
				return [subst -nocommands $lang($msg)]
			} else {
				if {[llength $args]>0} {
					return "$msg $args"
				} else {
					return "$msg"
				}
			}
		}  res] == 1} {
		if {[llength $args]>0} {
			return "$msg $args"
		} else {
			return "$msg"
		}
	} else {
		return $res
	}

}


#Lectura del idioma
proc load_lang { {langcode "en"} {plugindir ""} } {
   global lang lang_list langenc langlong

   if {[string equal $plugindir ""]} { set plugindir "lang" }
   if { [catch {set file_id [open "[file join $plugindir lang$langcode]" r]}] } {
   	return 0
   }

   set langenc ""

   foreach langdata $lang_list {
   	if { [string compare [lindex $langdata 0] $langcode] == 0 } {
	  set langenc [lindex $langdata 2]
	  set langlong [lindex $langdata 1]
	}
   }

   fconfigure $file_id -encoding $langenc

   gets $file_id tmp_data
   if {$tmp_data != "amsn_lang_version 2"} {	;# config version not supported!
      return 1
   }

   while {[gets $file_id tmp_data] != "-1"} {
      #If line is a comment, skip
      if {[string range $tmp_data 0 0] == "#"} {
          continue
      }
      set pos [string first " " $tmp_data]
      
      #Remove comments at end of line
      set posend [string first "#" $tmp_data]
      if { $posend == -1 } {
          set posend [expr {[string length $tmp_data]-1}]
      } else {
         incr posend -1
	  while {[string range $tmp_data $posend $posend] == " "} {
	  	incr posend -1
	  }
      }
      set l_msg [string range $tmp_data 0 [expr {$pos -1}]]
      set l_trans [string range $tmp_data [expr {$pos +1}] $posend]
      if { ![info exists lang($l_msg)] && ![string equal $plugindir "lang"] } {
      	  set lang($l_msg) $l_trans
      } elseif { [string equal $plugindir "lang"] } {
      	  set lang($l_msg) $l_trans
      }
   }
   close $file_id
   return 0
}


namespace eval ::lang {


#///////////////////////////////////////////////////////////////////////
proc show_languagechoose {} {
	global lang_list

	set languages [list]
	set available [::lang::get_available_language]

	foreach langelem $lang_list {
		set langcode [lindex $langelem 0]
		if { [lsearch $available $langcode] != -1 } {
			set langlong [lindex $langelem 1]
			lappend languages [list "$langlong" "$langcode"]
		}
	}

	set wname ".langchoose"

	if {[winfo exists $wname]} {
		raise $wname
		return
	}

	toplevel $wname
	wm title $wname "[trans language]"
	wm geometry $wname 300x350

	frame $wname.notebook -borderwidth 3
	set nb $wname.notebook
	NoteBook $nb.nn
	$nb.nn insert end language -text [trans language]
	$nb.nn insert end manager -text [trans language_manager]

	#  .__________.
	# _| Language |____
	set frm [$nb.nn getframe language]

	frame $frm.list -class Amsn -borderwidth 0
	frame $frm.buttons -class Amsn

	listbox $frm.list.items -yscrollcommand "$frm.list.ys set" -font splainf \
			-background white -relief flat -highlightthickness 0 -width 60
	scrollbar $frm.list.ys -command "$frm.list.items yview" -highlightthickness 0 \
			-borderwidth 1 -elementborderwidth 1 

	button $frm.buttons.ok -text "[trans ok]" -command [list ::lang::show_languagechoose_Ok $languages]
	button $frm.buttons.cancel -text "[trans cancel]" -command [list destroy $wname]


	pack $frm.list.ys -side right -fill y
	pack $frm.list.items -side left -expand true -fill both
	pack $frm.list -side top -expand true -fill both -padx 4 -pady 4

	pack $frm.buttons.ok -padx 5 -side right
	pack $frm.buttons.cancel -padx 5 -side right
	pack $frm.buttons -side bottom -fill both -pady 3

	foreach item $languages {
		$frm.list.items insert end [lindex $item 0]
	}


	bind $frm.list.items <Double-Button-1> [list ::lang::show_languagechoose_Ok $languages]
	bind $frm <Return> [list ::lang::show_languagechoose_Ok languages]


	catch {
		raise $frm
		focus $frm.buttons.ok
	}

	pack $frm -fill both -expand true

	$nb.nn compute_size


	#  ._________.
	# _| Manager |____
	set frm [$nb.nn getframe manager]

	label $frm.text -text "[trans selectlanguage] :"
	pack configure $frm.text -side top -fill x

	# Create a list box where we will put the lang
	frame $frm.selection -class Amsn -borderwidth 0
	listbox $frm.selection.box -yscrollcommand "$frm.selection.ys set" -font splainf -background white -relief flat -highlightthickness 0
	scrollbar $frm.selection.ys -command "$frm.selection.box yview" -highlightthickness 0 -borderwidth 1 -elementborderwidth 2
	pack $frm.selection.ys -side right -fill y
	pack $frm.selection.box -side left -expand true -fill both

	# Add the lang into the previous list
	foreach lang $lang_list {
		set langcode [lindex $lang 0]
		set langname [lindex $lang 1]
		$frm.selection.box insert end "$langname"
		# Choose the background according to the fact lang is available or not
		if { [lsearch $available $langcode] != -1 } {
			$frm.selection.box itemconfigure end -background #DDF3FE
		} else {
			$frm.selection.box itemconfigure end -background #FFFFFF
		}
	}

	# When a language is selected, execute language_manager_selected
	bind $frm.selection.box <<ListboxSelect>> "::lang::language_manager_selected"

	frame $frm.txt
	label $frm.txt.text -text " "
	pack configure $frm.txt.text

	frame $frm.command
	button $frm.command.load -text "[trans load]" -command "::lang::language_manager_load" -state disabled
	pack configure $frm.command.load -side right

	button $frm.command.close -text "[trans close]" -command "destroy .langchoose"
	pack configure $frm.command.close -side right

	pack configure $frm.selection -side top -expand true -fill both -padx 4 -pady 4
	pack configure $frm.txt -side top -fill x
	pack configure $frm.command -side top -fill x -padx 10

	pack $frm -fill both -expand true

	$nb.nn compute_size

	$nb.nn raise language
	$nb.nn compute_size
	pack $nb.nn -fill both -expand true
	pack $wname.notebook -fill both -expand true


	bind $wname <<Escape>> [list destroy $wname]
	moveinscreen $wname 30


}


#///////////////////////////////////////////////////////////////////////
proc show_languagechoose_Ok { itemlist } {
	set sel [.langchoose.notebook.nn.flanguage.list.items curselection]
	if { $sel == "" } { return }
	destroy .langchoose	
	::lang::set_language [lindex [lindex $itemlist $sel] 1]
}


#///////////////////////////////////////////////////////////////////////
proc language_manager_selected { } {

	global gui_language lang_list

	set dir [get_language_dir]
	if { $dir == 0 } {
		return
	}

	set w ".langchoose.notebook.nn.fmanager"

	# Get the selected item
	set selection [$w.selection.box curselection]
	set langcode [lindex [lindex $lang_list $selection] 0]
	set lang "lang$langcode"

	set available [::lang::get_available_language]

	# If the lang selected is the used lang
	if { $langcode == [::config::getGlobalKey language]} {
		$w.command.load configure -state disabled -text "[trans unload]"
		$w.txt.text configure -text "[trans currentlanguage]" -foreground red
	# If the file is not available
	} elseif {[lsearch $available $langcode] == -1 } {
		$w.command.load configure -state normal -text "[trans load]" -command "[list ::lang::getlanguage "lang$langcode" $selection]"
		$w.txt.text configure -text " "
	# If the file is protected
	} elseif { ![file writable "$dir/$lang"] } {
		$w.command.load configure -state disabled -text "[trans unload]"
		$w.txt.text configure -text "[trans filenotwritable]" red
	# If the file is available
	} elseif {[lsearch $available $langcode] != -1 } {
		$w.command.load configure -state normal -text "[trans unload]" -command "[list ::lang::deletelanguage "lang$langcode" $selection]"
		$w.txt.text configure -text " "
	}


	.langchoose.notebook.nn.flanguage.list.items delete 0 end

	set languages [list]
	set available [::lang::get_available_language]

	foreach langelem $lang_list {
		set langcode [lindex $langelem 0]
		if { [lsearch $available $langcode] != -1 } {
			set langlong [lindex $langelem 1]
			lappend languages [list "$langlong" "$langcode"]
		}
	}

	foreach item $languages {
		.langchoose.notebook.nn.flanguage.list.items insert end [lindex $item 0]
	}


}


#///////////////////////////////////////////////////////////////////////
proc set_language { langname } {
	global gui_language

	load_lang $langname
	msg_box [trans mustrestart]
	
	#Reload english to overwrite any missing sentences
	load_lang en
	#Reload the current GUI language
	load_lang $gui_language

	::config::setGlobalKey language $langname
	::config::saveGlobal
	
	return
}


#///////////////////////////////////////////////////////////////////////
# Get the encoding of a language
proc get_language_encoding { lang } {

	global lang_list

	# Search in the lang_list list the lang we want, and return its encoding
	foreach langdata $lang_list {
		if { "lang[lindex $langdata 0]" == $lang } {
			set langenc [lindex $langdata 2]
			break
		}
	}

	return $langenc

}


#///////////////////////////////////////////////////////////////////////
# Return the directory of the lang files
proc get_language_dir { } {

	if { [file isdirectory "[pwd]/lang"] } {
		return "[pwd]/lang"
	} else {
		::amsn::errorMsg "[trans dirdontexist]"
		return "0"
	}

}


#///////////////////////////////////////////////////////////////////////
# Return the lang that are saved on the disk
proc get_available_language {} {

	global lang_list

	set dir [get_language_dir]
	if { $dir == 0 } {
		return
	}

	set available [list]

	# Search the files on the disk
	foreach lang $lang_list {
		set file [lindex $lang 0]
		if { [file exists "$dir/lang$file"] } {
			lappend available $file
		}
	}

	return $available
}


#///////////////////////////////////////////////////////////////////////
# Download the lang file
proc getlanguage { lang selection } {

	global lang_list weburl

	set dir [get_language_dir]
	if { $dir == 0 } {
		return
	}

	set file "[file join ${dir} $lang]"

	# If the file already exists, stop the proc
	if { [file exists $file] } {
		return
	}

	# Create a new file
	set fid [open $file w]

	# Choose the encoding of the file according to the encoding of the lang
	fconfigure $fid -encoding "[get_language_encoding $lang]"

	# Download the content of the file from the web
	set token [::http::geturl "http://cvs.sourceforge.net/viewcvs.py/*checkout*/amsn/msn/lang/$lang?rev=HEAD&content-type=text" -timeout 10000]
	set content [::http::data $token]

	# Puts the content into the file
	puts -nonewline $fid "$content"

	close $fid

	catch {
		.langchoose.notebook.nn.fmanager.selection.box itemconfigure $selection -background #DDF3FE
		::lang::language_manager_selected
	}
	

}


#///////////////////////////////////////////////////////////////////////
# Delete a lang file
proc deletelanguage { lang selection } {
	
	set dir [get_language_dir]
	if { $dir == 0 } {
		return
	}

	file delete "$dir/$lang"

	catch {
		.langchoose.notebook.nn.fmanager.selection.box itemconfigure $selection -background #FFFFFF
		::lang::language_manager_selected
	}
}



}