
::Version::setSubversionId {$Id$}

if { $initialize_amsn == 1 } {
	global lang_list langenc langlong
	set lang_list [list]
	set langenc "iso8859-1"
	set langlong "English"
}

proc scan_languages { } {

	global lang_list
	set lang_list [list]

	::lang::LoadVersions	 

	foreach langcode $::lang::Lang {
		set name [::lang::ReadLang $langcode name]
		set encoding [::lang::ReadLang $langcode encoding]
		lappend lang_list "{$langcode} {$name} {$encoding}"
	}

}


proc detect_language { {default "en"} } {
	global env
	
	if { [OnDarwin] } {
		if { [catch { set system_language [string tolower [exec defaults read NSGlobalDomain AppleLocale]]}]} {
			set system_language en
		} else {
			set system_language [string tolower [exec defaults read NSGlobalDomain AppleLocale]]
		}
	} elseif { ![info exists env(LANG)] } {
		status_log "No LANG environment variable. Using $default\n"
		return $default
	} else {
		set system_language [string tolower $env(LANG)]
	}
	
	
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
	
	set idx [string first "." $system_language]
	status_log "System language is $system_language\n"
	#Remove .UTF-8 thing or similar
	if { $idx != -1 } {
		incr idx -1
		set system_language [string range $system_language 0 $idx]
		status_log "Removed . thing. Now system language is $system_language\n"
	}
	
	set language [language_in_list $system_language]
	if { $language != 0 } {
		status_log "Matching language $language!\n"
		return $language
	}
	
	set idx [string first "_" $system_language]
	# Remove _variant thing, like US in en_US
	# This will remove _BR from pt_BR but only if it pt_BR doesn't exist in our language list.
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

	set plugin [::plugins::calledFrom]

	for {set i 1} {$i <= [llength $args]} {incr i} {
		set $i [lindex $args [expr {$i-1}]]
	}

	if {[ catch {
		if { ($plugin != -1) && ([array names ::${plugin}::lang $msg] == "$msg") } {
			return [subst -nocommands [set ::${plugin}::lang($msg)]]
		} elseif { [string length $lang($msg)] > 0 } {
			return [subst -nocommands $lang($msg)]
		} else {
			if {[llength $args]>0} {
				return "$msg $args"
			} else {
				return "$msg"
			}
		}
	} res] == 1} {
		status_log "Catch in proc trans ($msg $args): $res" red
		if {[llength $args]>0} {
			return "$msg $args"
		} else {
			return "$msg"
		}
	} else {
		return $res
	}
}


#Read language file
proc load_lang { {langcode "en"} {plugindir ""} } {
	global lang lang_list langenc langlong

	if {[string equal $plugindir ""]} { set plugindir "lang" }
	if { [catch {set file_id [open "[file join $plugindir lang$langcode]" r]}] } {
		return 0
	}

	#check if this is called from a plugin
	set plugin [::plugins::calledFrom]
	if {$plugin != -1} {
		status_log "load_lang called from a plugin"
		variable ::${plugin}::lang
	}
	set current_enc ""

	foreach langdata $lang_list {
		if { [lindex $langdata 0] == $langcode } {

			set current_enc  [lindex $langdata 2]
			if { $plugin == -1 } {
				set langenc [lindex $langdata 2]
				set langlong [lindex $langdata 1]
			} 

			
		}
	}

	fconfigure $file_id -encoding $current_enc

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
		if { ![info exists lang($l_msg)] && ![string match "*lang*" $plugindir] } {
			set lang($l_msg) $l_trans
		} elseif { [string match "*lang*" $plugindir] } {
			set lang($l_msg) $l_trans
		}
	}
	close $file_id
	#load translations for BWidgets
	if {[info exists ::BWIDGET::LIBRARY]} {
		catch {option read [file join $::BWIDGET::LIBRARY lang ${langcode}.rc]}
	} else {
		catch {option read [file join utils bwidget1.8.0 lang ${langcode}.rc]}
	}
	return 0
}


namespace eval ::lang {


	#///////////////////////////////////////////////////////////////////////
	proc show_languagechoose {} {

		global HOME2

		set languages [list]

		::lang::LoadOnlineVersions

		foreach langcode $::lang::Lang {
			set name [::lang::ReadLang $langcode name]
			lappend languages [list "$name" "$langcode"]
		}
		
		set languages [lsort -index 0 -dictionary $languages] 

		set wname ".langchoose"

		if {[winfo exists $wname]} {
			raise $wname
			return
		}

		toplevel $wname
		wm title $wname "[trans language]"
		wm geometry $wname 300x400
		wm protocol $wname WM_DELETE_WINDOW "::lang::language_manager_close"

		frame $wname.notebook -borderwidth 3

		set nb $wname.notebook
		NoteBook $nb.nn
		$nb.nn insert end language -text [trans language]
		$nb.nn insert end manager -text [trans language_manager]


		#  .__________.
		# _| Language |____

		set frm [$nb.nn getframe language]

		frame $frm.list -borderwidth 0
		frame $frm.buttons

		listbox $frm.list.items -yscrollcommand "$frm.list.ys set" -font splainf \
				-background white -relief flat -highlightthickness 0 -width 60
		scrollbar $frm.list.ys -command "$frm.list.items yview" -highlightthickness 0 \
				-borderwidth 1 -elementborderwidth 1 

		button $frm.buttons.ok -text "[trans ok]" -command [list ::lang::show_languagechoose_Ok $languages]
		button $frm.buttons.cancel -text "[trans cancel]" -command "::lang::language_manager_close"


		pack $frm.list.ys -side right -fill y
		pack $frm.list.items -side left -expand true -fill both
		pack $frm.list -side top -expand true -fill both -padx 4 -pady 4

		pack $frm.buttons.ok -padx 5 -side right
		pack $frm.buttons.cancel -padx 5 -side right
		pack $frm.buttons -side bottom -fill both -pady 3

		foreach item $languages {
			set langname [lindex $item 0]
			set langcode [lindex $item 1]
 
			$frm.list.items insert end "$langname"
			if { $langcode == [::config::getGlobalKey language]} {
				$frm.list.items itemconfigure end \
					-bg [::skin::getKey extralistboxselectedbg] -fg [::skin::getKey extralistboxselected] \
					-selectforeground [::skin::getKey extralistboxselected]
			}
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

		if { $::lang::LoadOk == 1 && [file writable [file join $HOME2 langlist.xml]]} {		

		# Create a list box where we will put the lang
		frame $frm.selection -borderwidth 0
		listbox $frm.selection.box -yscrollcommand "$frm.selection.ys set" 
		scrollbar $frm.selection.ys -command "$frm.selection.box yview" -highlightthickness 0 -borderwidth 1 -elementborderwidth 2
		pack $frm.selection.ys -side right -fill y
		pack $frm.selection.box -side left -expand true -fill both

		# Add the lang into the previous list
		set languages2 [list]
		foreach langcode $::lang::OnlineLang {
			set name [::lang::ReadOnlineLang $langcode name]
			lappend languages2 [list "$name" "$langcode"]
		}
		set languages2 [lsort -index 0 -dictionary $languages2]
		
		set ::lang::OnlineLang [list]
		
		foreach lang $languages2 {
			set langcode [lindex $lang 1]
			set ::lang::OnlineLang [lappend ::lang::OnlineLang $langcode]
		}		
		
		foreach item $languages2 {
			set langname [lindex $item 0]
			set langcode [lindex $item 1]
			$frm.selection.box insert end "$langname"
			# Choose the background according to the fact lang is available or not
			if { [lsearch $::lang::Lang $langcode] != -1 } {
				if { $langcode == [::config::getGlobalKey language]} {
					$frm.selection.box itemconfigure end  \
						-bg [::skin::getKey extralistboxselectedbg] -fg [::skin::getKey extralistboxselected] \
						-selectforeground [::skin::getKey extralistboxselected]
				}
			} else {
				$frm.selection.box itemconfigure end \
					-fg [::skin::getKey extrastderrcolor] \
					-selectforeground [::skin::getKey extrastderrcolor]
			}
		}


		# When a language is selected, execute language_manager_selected
		bind $frm.selection.box <<ListboxSelect>> "::lang::language_manager_selected"

		frame $frm.txt
		label $frm.txt.text -text " "
		pack configure $frm.txt.text

		frame $frm.command1
		
		button $frm.command1.deleteall -text "[trans deleteall]" -command "::lang::language_manager_deleteall"
		pack configure $frm.command1.deleteall -side left -padx 5
		
		button $frm.command1.load -text "[trans download]" -command "::lang::language_manager_load" -state disabled
		pack configure $frm.command1.load -side right -padx 5
		
		frame $frm.command2

		button $frm.command2.close -text "[trans close]" -command "::lang::language_manager_close"
		pack configure $frm.command2.close -side right -padx 5

		pack configure $frm.selection -side top -expand true -fill both -padx 4 -pady 4
		pack configure $frm.txt -side top -fill x
		pack configure $frm.command1 -side top -fill x -padx 10
		pack configure $frm.command2 -side top -fill x -padx 10


		} else {

		frame $frm.txt
		label $frm.txt.text -text "[trans cantloadonlineversion]" -wraplength 200
		pack configure $frm.txt.text

		frame $frm.command
		button $frm.command.close -text "[trans close]" -command "::lang::language_manager_close"
		pack configure $frm.command.close -side right -padx 5

		pack configure $frm.txt -side top -fill x
		pack configure $frm.command -side bottom -fill x -padx 10

		}

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
	proc language_manager_close { } {

		catch {::lang::SaveVersions}
		destroy .langchoose

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

		set dir [get_language_dir]
		if { $dir == 0 } {
			return
		}

		set w ".langchoose.notebook.nn.fmanager"

		# Get the selected item
		set selection [$w.selection.box curselection]
		set langcode [lindex $::lang::OnlineLang $selection]
		set lang "lang$langcode"
		
		# No selection, we shouldn't crash..
		if {$selection == ""} {
			return
		}

		# If the lang selected is the current lang
		if { $langcode == [::config::getGlobalKey language]} {
			$w.command1.load configure -state disabled -text "[trans delete]"
			$w.txt.text configure -text "[trans currentlanguage]" \
				-fg [::skin::getKey extrastderrcolor]

		# If the file is not available
		} elseif {[lsearch $::lang::Lang $langcode] == -1 } {
			$w.command1.load configure -state normal -text "[trans download]" -command "[list ::lang::downloadlanguage "$langcode" $selection]"
			$w.txt.text configure -text ""
		# If the file is protected
		} elseif { ![file writable "$dir/$lang"] | $langcode == "en" } {
			$w.command1.load configure -state disabled -text "[trans delete]"
			$w.txt.text configure -text "[trans filenotwritable]" -foreground red
			$w.txt.text configure -text "[trans filenotwritable]" \
				-fg [::skin::getKey extrastderrcolor]
		# If the file is available
		} elseif {[lsearch $::lang::Lang $langcode] != -1 } {
			$w.command1.load configure -state normal -text "[trans delete]" -command "[list ::lang::deletelanguage "$langcode" $selection]"
			$w.txt.text configure -text ""
		}


		.langchoose.notebook.nn.flanguage.list.items delete 0 end

		set languages [list]


		foreach langcode $::lang::Lang {
			set name [::lang::ReadLang $langcode name]
			lappend languages [list "$name" "$langcode"]
		}


		foreach item $languages {
			set langname [lindex $item 0]
			set langcode [lindex $item 1]

			.langchoose.notebook.nn.flanguage.list.items insert end "$langname"
			if { $langcode == [::config::getGlobalKey language]} {
				.langchoose.notebook.nn.flanguage.list.items itemconfigure end  \
					-bg [::skin::getKey extralistboxselectedbg] -fg [::skin::getKey extralistboxselected] \
					-selectforeground [::skin::getKey extralistboxselected]
			}

			.langchoose.notebook.nn.flanguage.list.items insert end [lindex $item 0]
		}
	}
	
	
	#///////////////////////////////////////////////////////////////////////
	proc language_manager_deleteall { } {
		
		global lang_list
		
		set dir [::lang::get_language_dir]
		
		set k 0
		
		foreach lang $lang_list {
			set langcode [lindex $lang 0]
			# If the lang selected is the current lang, the file is protected, or it is English, don't delete the lang
			if { $langcode != [::config::getGlobalKey language] && [file writable "$dir/lang$langcode"] && $langcode != "en" } {
				::lang::deletelanguage "$langcode" "$k"
			}
			incr k
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
	proc get_lang_encoding { langcode } {

		global lang_list

		# Search in the lang_list list the lang we want, and return its encoding
		foreach langdata $lang_list {
			if { [lindex $langdata 0] == $langcode } {
				set langenc [lindex $langdata 2]
				break
			}
		}

		return $langenc

	}

	#///////////////////////////////////////////////////////////////////////
	# Get the name of a language
	proc get_lang_name { langcode } {

		global lang_list

		# Search in the lang_list list the lang we want, and return its encoding
		foreach langdata $lang_list {
			if { [lindex $langdata 0] == $langcode } {
				set langname [lindex $langdata 1]
				break
			}
		}

		return $langname

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
	# Download the lang file
	proc downloadlanguage { langcode { selection "" } } {

		global lang_list weburl

		set lang "lang$langcode"
		
		set dir [get_language_dir]

		if { $dir == 0 } {
			return
		}

		# Get the information from the online version
		set name [::lang::ReadOnlineLang $langcode name]
		set version [::lang::ReadOnlineLang $langcode version]
		set encoding [::lang::ReadOnlineLang $langcode encoding]

		# Download the content of the file from the web
		if { [catch {
			set token [::http::geturl "$::weburl/autoupdater/lang/$lang" -timeout 120000 -binary 1]
			set content [::http::data $token]
			set status [::http::status $token]
		} ] } {
			catch {::http::cleanup $token}
			status_log "Error while uploading lang : $langcode\n" red
			return
		}

		#If an error occured, stop the process
		if { $status != "ok" } {
			::http::cleanup $token
			status_log "Error while uploading lang : $langcode ($status)\n" red
			return
		}

		# Puts the content into the file
		set file "[file join ${dir} $lang]"
		if { ![file writable $file] && [file exists $file] } {
			::http::cleanup $token
			status_log "Error while updating $file : file is protected\n" red
			return
		}

		if { [catch {
			set fid [open $file w]
			fconfigure $fid -encoding binary
			puts -nonewline $fid "$content"
			close $fid
		} ] } {
			status_log "Error while updating $file : file is protected\n" red
			return
		}
		::http::cleanup $token

		# Add the language into the language list
		::lang::AddLang "$langcode" "$name" "$version" "$encoding"

		if { $selection != "" } {
			catch {
				.langchoose.notebook.nn.fmanager.selection.box itemconfigure $selection \
					-fg [::skin::getKey extrastdtxtcolor] \
					-selectforeground [::skin::getKey extraselectedtxtcolor]

				::lang::language_manager_selected
			}
		}
	}


	#///////////////////////////////////////////////////////////////////////
	# Delete a lang file
	proc deletelanguage { langcode {selection ""} } {

		set dir [get_language_dir]
		if { $dir == 0 } {
			return
		}

		file delete "$dir/lang$langcode"

		::lang::RemoveLang $langcode

		if { $selection != "" } {
			catch {
				.langchoose.notebook.nn.fmanager.selection.box itemconfigure $selection -background #FFFFFF
				::lang::language_manager_selected
			}
		}
	}


	#///////////////////////////////////////////////////////////////////////
	# Load the language versions

	proc LoadVersions { } {

		global HOME2

		# Reinitialise all the versions
		if { [info exists ::lang::Lang] } {
			foreach langcode $::lang::Lang {
				::lang::RemoveLang $langcode
			}
		}

		set ::lang::Lang ""

		set check 0

		set filename "[file join $HOME2 langlist.xml]"

		# If langlist.xml doesn't exist, or if langlist was modified after langlist.xml
		if { ![file exists $filename] || [file mtime $filename] < [file mtime "langlist"] } {
			file copy -force "langlist" "$filename"
			set check 1
		}

		set id [::sxml::init $filename]
		sxml::register_routine $id "version:lang" "::lang::XMLLang"
		sxml::parse $id
		sxml::end $id

		if { $check == 1 } {
			::lang::CheckLangList
		}

	}


	#///////////////////////////////////////////////////////////////////////
	proc XMLLang { cstack cdata saved_data cattr saved_attr args } {
		upvar $saved_data sdata

		set langcode $sdata(${cstack}:langcode)
		set name $sdata(${cstack}:name)
		set version $sdata(${cstack}:version)
		set encoding $sdata(${cstack}:encoding)
		::lang::AddLang $langcode $name $version $encoding

		return 0

	}


	#///////////////////////////////////////////////////////////////////////
	# Read the properties a lang (version, name, encoding)

	proc ReadLang { langcode array } {

		set list [array get ::lang::Lang$langcode]
		set index [lsearch $list $array]
		if { $index != -1 } {
			return [lindex $list [expr {$index + 1}]]
		} else {
			return ""
		}

	}

	proc ReadOnlineLang { langcode array } {

		set list [array get ::lang::OnlineLang$langcode]
		set index [lsearch $list $array]
		if { $index != -1 } {
			return [lindex $list [expr {$index + 1}]]
		} else {
			return ""
		}

	}


	#///////////////////////////////////////////////////////////////////////
	# Initialize the langlist.xml file

	proc CheckLangList { } {

		foreach langcode $::lang::Lang {
			if { ![file exists [file join lang lang$langcode]] } {
				::lang::RemoveLang $langcode
			}
		}

		::lang::SaveVersions

	}

	#///////////////////////////////////////////////////////////////////////
	# Check if a lang is loaded

	proc LangExists { langcode } {

		if {[lsearch $::lang::Lang $langcode] != -1 } {
			return 1
		} else {
			return 0
		}

	}


	#///////////////////////////////////////////////////////////////////////
	# Add a new lang

	proc AddLang { langcode name version encoding } {
		if {$langcode == "" } {
			return
		}

		array set ::lang::Lang$langcode [list name "$name" version $version encoding $encoding]

		if { ![::lang::LangExists $langcode] } {
			set ::lang::Lang [lappend ::lang::Lang $langcode]
			set ::lang::Lang [lsort $::lang::Lang]
		}

	}


	#///////////////////////////////////////////////////////////////////////
	# Delete a lang from the XML file and delete all the information about it that are in memory

	proc RemoveLang { langcode } {
		
		if { [::lang::LangExists $langcode] } {
			set index [lsearch $::lang::Lang $langcode]
			set ::lang::Lang [lreplace $::lang::Lang $index $index]
		}

		unset -nocomplain ::lang::Lang$langcode

	}

			
	#///////////////////////////////////////////////////////////////////////
	# Save the XML file

	proc SaveVersions {} {

		global HOME2
	
		set file_id [open "[file join $HOME2 langlist.xml]" w]

		fconfigure $file_id -encoding utf-8

		puts $file_id "<?xml version=\"1.0\"?>\n\n<version>"

		foreach langcode $::lang::Lang {
			set name [::lang::ReadLang $langcode name]
			set version [::lang::ReadLang $langcode version]
			set encoding [::lang::ReadLang $langcode encoding]
			puts $file_id "\t<lang>\n\t\t<langcode>$langcode</langcode>\n\t\t<name>$name</name>\n\t\t<version>$version</version>\n\t\t<encoding>$encoding</encoding>\n\t</lang>"
		}

		puts $file_id "</version>"

		close $file_id
	}


	#///////////////////////////////////////////////////////////////////////
	# Load the online version and read the XML file

	proc LoadOnlineVersions { } {

		global HOME2

		if { [catch {

			set ::lang::OnlineLang ""

			set filename "[file join $HOME2 langlistnew.xml]"

			set fid [open $filename w]
			set token [::http::geturl "$::weburl/autoupdater/langlist" -timeout 120000 -binary 1]
			set content [::http::data $token]
			fconfigure $fid -encoding binary
			puts -nonewline $fid "$content"
			close $fid
			::http::cleanup $token

			set id [::sxml::init $filename]
			sxml::register_routine $id "version:lang" "::lang::XMLOnlineLang"
			sxml::register_routine $id "version:plugin" "::lang::XMLOnlinePlugin"
			sxml::parse $id
			sxml::end $id

			file delete $filename

		}]} {
			set ::lang::LoadOk 0
		} else {
			set ::lang::LoadOk 1
		}

	}


	#///////////////////////////////////////////////////////////////////////

	proc XMLOnlineLang { cstack cdata saved_data cattr saved_attr args } {

		upvar $saved_data sdata

		set langcode $sdata(${cstack}:langcode)
		set name $sdata(${cstack}:name)
		set version $sdata(${cstack}:version)
		set encoding $sdata(${cstack}:encoding)
		array set ::lang::OnlineLang$langcode [list name $name version $version encoding $encoding]

		lappend ::lang::OnlineLang $langcode

		return 0
	}



	#///////////////////////////////////////////////////////////////////////
	# This proc is called to check if a new version of lang files exists, and put it into the ::lang::UpdatedLang list

	proc UpdatedLang { } {
	
		set dir [get_language_dir]

		set ::lang::UpdatedLang [list]

		set langcode [::config::getGlobalKey language]
		set lang "lang$langcode"

		if { $langcode == "en" || ([::lang::keyscounter "en"] <= [::lang::keyscounter "$langcode"]) } {
			return
		}

		::lang::LoadVersions
		::lang::LoadOnlineVersions

		if { $::lang::LoadOk == 0 } {
			status_log "Unable to update language\n" red
			return
		}

		
		# Check if the current language is not English,
		# if the number of keys is different in this language and in English
		# and if the file is writable before
		if { [file writable "$dir/$lang"] } {
			set version [::lang::ReadLang $langcode version]
			set onlineversion [::lang::ReadOnlineLang $langcode version]
			set current [split $version "."]
			set new [split $onlineversion "."]
			set newer 0
				
			if { [lindex $new 0] > [lindex $current 0] } {
				set newer 1
			} elseif { [lindex $new 1] > [lindex $current 1] } {
				set newer 1
			}
				
			if { $newer == 1 } {
				lappend ::lang::UpdatedLang $langcode
			}
				
		}

		::lang::SaveVersions
	}


	#///////////////////////////////////////////////////////////////////////
	# This proc is called to update a lang
	
	proc UpdateLang { langcodes } {
		
		set w ".updatelangplugin"
	
		foreach langcode $langcodes {			
			
			set langname [::lang::ReadLang $langcode name]
			if { [winfo exists $w] } {
				$w.update.txt configure -text "[trans updating] $langname..."
			}

			set onlineversion [::lang::ReadOnlineLang $langcode version]
			set name $::lang::OnlineLang"$langcode"(name)
			set encoding $::lang::OnlineLang"$langcode"(encoding)

			::lang::downloadlanguage $langcode
				
			set ::lang::Lang"$langcode"(version) $onlineversion
			set ::lang::Lang"$langcode"(name) $name
			set ::lang::Lang"$langcode"(encoding) $encoding
			
		}
		
		::lang::SaveVersions
	
	}


	#///////////////////////////////////////////////////////////////////////
	# This proc counts the number of keys of a language

	proc keyscounter { langcode } {

		set dir [get_language_dir]
		set lang "lang$langcode"

		set file [open "[file join ${dir} ${lang}]" r]
		set keys [split [read $file] "\n"]
		set keysnumber [llength $keys]

		return $keysnumber

	}

}


