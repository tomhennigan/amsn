#
# $Id$
#

if { $initialize_amsn == 1 } {
	global smileys_drawn
	set smileys_drawn 0
}


namespace eval ::smiley {

	#Used variables:
	#---------------
	#
	# array emotions(SYMBOL) - contains the smiley NAME for every SYMBOL.
	#                          SYMBOL is the smiley trigger
	#
	# list emotions_names    - a list of all smiley NAMES, sorted as defined
	#                          in the settings.xml file
	#
	# array emotions_data(NAME) - an array containing an array with all info
	#                          about a given smiley NAME. To retrieve this
	#                          data, better use [ValueForSmiley NAME FIELD]
	#                          instead of accessing this variable
	

	#///////////////////////////////////////////////////////////////////////////////
	# proc newEmoticon {cstack cdata saved_data cattr saved_attr args}
	#
	# This is the main procedure for creating our emoticons, it gets data from the XML
	# parser (don't know what all args are made for) and retrieves the data we need and
	# creates the arrays we need.
	# For every new emoticon, we add it's name to emotions_names (preceded by a number for
	# having the correct order in the menu) then we add the elements in the array emotions
	proc newEmoticon {cstack cdata saved_data cattr saved_attr args} {
		
		global emotions emotions_data emotions_names
		upvar $saved_data sdata
		
		#Check if no important fields are missing, or emoticon is disabled
		#The fields name, text, and file must be present
		if { ! [info exists sdata(${cstack}:name)] } { return 0 }
		if { ! [info exists sdata(${cstack}:text)] } { return 0 }
		if { ! [info exists sdata(${cstack}:file)] } { return 0 }
		if { [info exists sdata(${cstack}:disabled)] && [is_true $sdata(${cstack}:disabled)] } { return 0 }
		
		#Get the smiley info: name, text and file, and other
		#existing fields, like sound or animated. Store them
		#in the local array emotion(field_name)
		foreach field [array names sdata] {
			set field_sort [string trim [string map [list "${cstack}:" "" ] $field]]
			if { $field_sort == "_dummy_" } {continue}
			set emotion($field_sort) [string trim $sdata($field)]
		}
		
		#Try to load the image. If we can't load the image, forget it
		#This is only checked if ::loading_skin is set. Otherwise we're
		#loading the default skin to get the standard smileys
		if { [info exists ::loading_skin] } {
			set realfile [GetSkinFile smileys $emotion(file) $::loading_skin]
			if { [file tail $realfile] == "null" } {
				status_log "Missing $emotion(file) from skin $::loading_skin. Using default\n" red
				return 0
			}
			#Mark this smiley as belonging to this skin
			set emotion(skin) $::loading_skin
		}
		
		#Text can be more then one symbol. Split and apply for all symbols
		set emotion(symbols) [list]
		set texts [split $emotion(text)]
		foreach text $texts {
			#Trim text (remove " ") and ignore empty strings
			if { $text == "" } { continue }
			set text [string trim $text \"]
			set text [string tolower $text]
			
			#Delete any previous ocurrence of this smiley if this existed and skin
			#propertie was set to "" (loaded when loading default skin first)
			if { [info exists emotions($text)] && [info exists emotions_data($emotions($text))] && [ValueForSmiley $emotions($text) skin] == "" } {
				#status_log "Replacing emoticon $emotions($text)\n" blue
				
				set name $emotions($text)
				#Remove all other symbols from that smiley
				array set emotion_data $emotions_data($name)
				set symbols $emotion_data(symbols)
				foreach symbol $symbols {
					if {[info exists emotions($symbol)]} {
						unset emotions($symbol)
					}
				}
				#Remove the old smiley daya
				unset emotions_data($name)
				
				#Remove from emotions_names
				set idx [lsearch -exact $emotions_names $name]
				set emotions_names [lreplace $emotions_names $idx $idx]
			}
			
			#Associate this symbol to this smiley name
			set emotions($text) $emotion(name)
			
			#Also add to the emotions data a list of triggers
			lappend emotion(symbols) $text
			
			
			#Associate this symbol to this file for skin reloading
			::skin::setSmiley $text $emotion(file)
		}
		
		#Store the smiley fields in the emotions_data array
		set emotions_data($emotion(name)) [array get emotion]
		

		#If it's not a hidden emoticon, add it to the emoticons list
		if { ! ([info exists sdata(${cstack}:hiden)] && [is_true $sdata(${cstack}:hiden)]) } {
			#incr emoticon_number
			lappend emotions_names $emotion(name)
		}
		
		variable sortedemotions
		if {[info exists sortedemotions]} { unset sortedemotions }
		
		return 0

	
	}
	
		
	#///////////////////////////////////////////////////////////////////////////////
	# proc newCustomEmoticonXML {cstack cdata saved_data cattr saved_attr args}
	#
	# This is the same procedure as newEmoticon
	# the only difference is that it is used for custom emoticons..
	# we need to do it that way since after calling "load_smileys" it erases the
	# emotions list...
	proc newCustomEmoticonXML {cstack cdata saved_data cattr saved_attr args} {
		global custom_emotions custom_images
		
		upvar $saved_data sdata
		
		#Check if no important fields are missing, or emoticon is disabled
		#The fields name, text, and file must be present		
		if { ! [info exists sdata(${cstack}:name)] } { return 0 }
		if { ! [info exists sdata(${cstack}:text)] } { return 0 }
		if { ! [info exists sdata(${cstack}:file)] } { return 0 }
		if { [info exists sdata(${cstack}:disabled)] && [is_true $sdata(${cstack}:disabled)] } { return 0 }
		
		#Get the smiley info: name, text and file, and other
		#existing fields, like sound or animated. Store them
		#in the local array emotion(field_name)
		foreach field [array names sdata] {
			set field_sort [string trim [string map [list "${cstack}:" "" ] $field]]
			if { $field_sort == "_dummy_" } {continue}
			set emotion($field_sort) [string trim $sdata($field)]
		}
		
		lappend [::config::getVar customsmileys] $emotion(name)
		set custom_emotions($emotion(name)) [array get emotion]
		set custom_images($emotion(name)) [image create photo -file $emotion(file) -format gif]

		
		return 0
	}
	


	#///////////////////////////////////////////////////////////////////////////////
	# proc substSmileys { tw {start "0.0"} {end "end"} {contact_list 0} }
	#
	# Main function... it substitutes smileys patterns into an image in any text widget
	# tw variable is the text widget
	# start is the starting point for which we scan the text for any smiley to change
	# contact_list is used to specify if we should play sounds if we find emotisound
	# this is used to avoid playing sounds when contact list is refreshed
	# the function scans the text widget (from the $start variable to the end) and
	# replaces any smileys pattern by the appropriate image (animated or not) and plays
	# a sound if necessary, etc... It scans the widget for every smiley that exists
	proc substSmileys {tw {textbegin "0.0"} {end "end"} {contact_list 0}} {
		global emotions
		variable sortedemotions
		
		if { ![info exists sortedemotions]} {
			set sortedemotions [lsort -command ::smiley::CompareSmileyLength [array names emotions]]
		}
		
		#Search for all possible emotions
		foreach symbol $sortedemotions {
			set chars [string length $symbol]
			
			#Get the name for this symbol
			set emotion_name $emotions($symbol)

			if { [ValueForSmiley $emotion_name casesensitive 1] } {set nocase "-exact"} else {set nocase "-nocase"}
			
			set start $textbegin
			
			#Keep searching umtil no matches
			while {[set pos [$tw search -exact $nocase -- $symbol $start $end]] != ""} {
		
				set posyx [split $pos "."]
				set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $chars}]"
				#status_log "Begin=$pos, end=$endpos\n" green
		
				if { [lsearch -exact [$tw tag names $pos] "dont_replace_smileys"] != -1 } {
					set start $endpos
					#status_log "Skipping in $pos\n"
					continue
				}
		
				$tw tag configure smiley -elide true
				$tw tag add smiley $pos $endpos
		
				if { [ValueForSmiley $emotion_name animated 1] && [::config::getKey animatedsmileys] } {
					global smileys_drawn
					set emoticon "$tw.${smileys_drawn}"
					incr smileys_drawn 
			
					label $emoticon -bd 0 -background white
					::anigif::anigif [GetSkinFile smileys [ValueForSmiley $emotion_name file]] $emoticon
			
					#TODO: I just added this to avoid a bug I can't find... someday we can fix it
					catch {
						$tw window create $endpos -window $emoticon
						bind $emoticon <Destroy> [list ::anigif::destroy $emoticon]
						$tw tag remove smiley $endpos
					}
			
					#Preserver replaced text tags
					set tagname  [$tw tag names $endpos]
					if { [llength $tagname] == 1 } {
						bind $emoticon <Button3-ButtonRelease> [$tw tag bind $tagname <Button3-ButtonRelease>]
						bind $emoticon <Enter> [$tw tag bind $tagname <Enter>]
						bind $emoticon <Leave> [$tw tag bind $tagname <Leave>]
					}
		
				} else {
					$tw image create $endpos -image [::skin::loadSmiley $symbol] -pady 0 -padx 0
					$tw tag remove smiley $endpos
				}
		
				if { [::config::getKey emotisounds] == 1 && $contact_list == 0 && [ValueForSmiley $emotion_name sound] != "" } {
					set sound [ValueForSmiley $emotion_name sound]
					play_sound $sound
				}
		
		
			}
		}
	
	}
	
	# proc substYourSmileys { tw {start "0.0"} {end "end"} {contact_list 0} }
	#
	# Similar to substSmileys, but replace only your custom smileys
	proc substYourSmileys {tw {textbegin "0.0"} {end "end"} {contact_list 0}} {
		global custom_emotions custom_images
		
		#Search for all possible emotions
		foreach name [::config::getKey customsmileys] {
	
			array set emotion $custom_emotions($name)
			set symbol $emotion(text)
			set chars [string length $symbol]
			
			if { [info exists emotion(casesensitive)] && [is_true $emotion(casesensitive)]} {set nocase "-exact"} else {set nocase "-nocase"}
			
			set start $textbegin
			
			#Keep searching umtil no matches
			while {[set pos [$tw search -exact $nocase -- $symbol $start $end]] != ""} {
		
				set posyx [split $pos "."]
				set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $chars}]"
				#status_log "Begin=$pos, end=$endpos\n" green
		
				if { [lsearch -exact [$tw tag names $pos] "dont_replace_smileys"] != -1 } {
					set start $endpos
					#status_log "Skipping in $pos\n"
					continue
				}
		
				$tw tag configure smiley -elide true
				$tw tag add smiley $pos $endpos
		
				if { [info exists emotion(animated)] && [is_true $emotion(animated)] && [::config::getKey animatedsmileys] } {
					global smileys_drawn
					set emoticon "$tw.${smileys_drawn}"
					incr smileys_drawn 
			
					label $emoticon -bd 0 -background white
					::anigif::anigif [GetSkinFile smileys $emotion(file)] $emoticon
			
					#TODO: I just added this to avoid a bug I can't find... someday we can fix it
					catch {
						$tw window create $endpos -window $emoticon
						bind $emoticon <Destroy> [list ::anigif::destroy $emoticon]
						$tw tag remove smiley $endpos
					}
			
					#Preserver replaced text tags
					set tagname  [$tw tag names $endpos]
					if { [llength $tagname] == 1 } {
						bind $emoticon <Button3-ButtonRelease> [$tw tag bind $tagname <Button3-ButtonRelease>]
						bind $emoticon <Enter> [$tw tag bind $tagname <Enter>]
						bind $emoticon <Leave> [$tw tag bind $tagname <Leave>]
					}
		
				} else {
					$tw image create $endpos -image $custom_images($name) -pady 0 -padx 0
					$tw tag remove smiley $endpos
				}
		
				if { [::config::getKey emotisounds] == 1 && $contact_list == 0 && [info exists emotion(sound)] && $emotion(sound) != "" } {
					play_sound $emotion(sound)
				}
		
		
			}
		}
	
	}
	
	
	#///////////////////////////////////////////////////////////////////////////////
	# proc smileyMenu { {x 0} {y 0} {text text}}
	#
	# Displays the smileys menu at the position where the mouse is and refreshes
	# all the bindings on the smileys in the menu to the correct widget
	# so that when you click on a smiley, it inserts its symbol into your text 
	# if the smile menu doesn't exist it created it first with [create_smile_menu $x $y]
	proc smileyMenu { {x 0} {y 0} {text text}} {
		global emotions_names emoticonbinding
		
		set w .smile_selector
		
		if { ! [winfo exists $w]} { CreateSmileyMenu $x $y }
		
		if { [info exists emoticonbinding ] } {unset emoticonbinding}
		
		set x [expr $x - 15]
		set y [expr $y + 15 - [winfo height $w]]
		wm geometry $w +$x+$y
		#It won't work on Windows without this
		update idletasks
		
		wm state $w normal
		
		#It won't work on Windows without this
		raise $w
		
		#Add bindings for standard emotions
		set temp 0
		foreach name $emotions_names {
		
			#Get the first symbol for that smiley
			set symbol [lindex [ValueForSmiley $name symbols] 0]	
			set file [ValueForSmiley $name file]
			set hiden [ValueForSmiley $name hiden 1]
			
			if { $hiden } {continue}
			
			catch { 
				#TODO: Improve this now we know about quoting a bit more?
				if { [string match {(%)} $symbol] != 0 } {
					bind $w.text.$temp <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; wm state $w withdrawn} res"
				} else {
					bind $w.text.$temp <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\; wm state $w withdrawn} res" 
				}
			}
			incr temp
		}
		
		#Now add custom emotions bindings
		global custom_emotions
		foreach name [::config::getKey customsmileys] {
			array set emotion $custom_emotions($name)
			set symbol $emotion(text)
			catch { 
				#TODO: Improve this now we know about quoting a bit more?
				if { [string match {(%)} $symbol] != 0 } {
					bind $w.text.$temp <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; wm state $w withdrawn} res"
				} else {
					bind $w.text.$temp <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\; wm state $w withdrawn} res" 
				}
			}
			
			if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
				bind $w.text.$temp <Button2-ButtonRelease> "[list ::smiley::editCustomEmotion $name]\; event generate $w <Leave>"
				bind $w.text.$temp <Control-ButtonRelease> "[list ::smiley::editCustomEmotion $name]\; event generate $w <Leave>"
			} else {
				bind $w.text.$temp <Button3-ButtonRelease> "[list ::smiley::editCustomEmotion $name]\; event generate $w <Leave>"
			}
			
			incr temp
		}
		
		event generate $w <Enter>
	
	}

	#///////////////////////////////////////////////////////////////////////////////
	# proc CreateSmileyMenu { {x 0} {y 0} }
	#
	# Create the smile menu... it first calls [calcul_geometry_smileys]
	# To get the width and height of the menu, then it creates the menu withdrawn with 
	# the animated smileys and static smileys in the correct order
	proc CreateSmileyMenu { {x 0} {y 0} } {
		global emotions emotions_names skinconfig custom_emotions custom_images
		
		set w .smile_selector
		if {[catch {[toplevel $w]} res]} {
			destroy $w
			toplevel $w
		}
		
		set xy_geo [calcul_geometry_smileys]
		
		#Smiley width and eight. Maybe we should load it from the skin settings
		set smiw $skinconfig(smilew)
		set smih $skinconfig(smileh)
	
		incr smiw 4
		incr smih 4
		
		set x_geo [expr $smiw*[lindex $xy_geo 0]+12]
		set y_geo [expr $smiw*[lindex $xy_geo 1]+12]
		set x [expr $x - 15]
		set y [expr $y + 15 - $y_geo]
		
		wm geometry $w ${x_geo}x${y_geo}+$x+$y
		wm title $w "[trans msn]"
		wm overrideredirect $w 1
		wm transient $w
		wm state $w normal
		
		
		text $w.text -background white -borderwidth 2 -relief flat \
			-selectbackground white -selectborderwidth 0 -exportselection 0
		
		pack $w.text
		
		$w.text configure -state normal
		
		#Add standard smileys
		set temp 0
		foreach name $emotions_names {
			set symbol [lindex [ValueForSmiley $name symbols] 0]
			set file [ValueForSmiley $name file]
			set hiden [ValueForSmiley $name hiden 1]
			set animated [expr {[ValueForSmiley $name animated 1] && [::config::getKey animatedsmileys 0]}]
			if { $hiden} {continue}
			
			catch {
				if { $animated } {
					label $w.text.$temp -background [$w.text cget -background]
					::anigif::anigif  [GetSkinFile smileys ${file}] $w.text.$temp
					bind $w.text.$temp <Destroy> [list ::anigif::destroy $w.text.$temp]
				} else {
					label $w.text.$temp -image [::skin::loadSmiley $symbol] -background [$w.text cget -background]
				}
		
				$w.text.$temp configure -cursor hand2 -borderwidth 1 -relief flat
				
				#Bindings for raise/flat on mouse over
				bind $w.text.$temp <Enter>  [list $w.text.$temp configure -relief raised]
				bind $w.text.$temp <Leave> [list $w.text.$temp configure -relief flat]

				#Toolstip
				if { [::config::getKey tooltips] } {set_balloon $w.text.$temp "$name $symbol"}
				$w.text window create end -window $w.text.$temp -padx 1 -pady 1
			}
			incr temp
		
		}
		
		#Now add custom emotions
		global custom_emotions
		foreach name [::config::getKey customsmileys] {
		
			array set emotion $custom_emotions($name)
			if {![info exists emotion(animated)]} { set emotion(animated) 0 }
			set animated [expr {$emotion(animated) && [::config::getKey animatedsmileys 0]}]
			
			#catch {
				if { $animated } {
					label $w.text.$temp -background [$w.text cget -background]
					::anigif::anigif  $emotion(file) $w.text.$temp
					bind $w.text.$temp <Destroy> [list ::anigif::destroy $w.text.$temp]
				} else {
					label $w.text.$temp -image $custom_images($name) -background [$w.text cget -background]
				}
		
				$w.text.$temp configure -cursor hand2 -borderwidth 1 -relief flat
				
				#Bindings for raise/flat on mouse over
				bind $w.text.$temp <Enter>  [list $w.text.$temp configure -relief raised]
				bind $w.text.$temp <Leave> [list $w.text.$temp configure -relief flat]

				#Toolstip
				if { [::config::getKey tooltips] } {set_balloon $w.text.$temp "$name $symbol"}
				$w.text window create end -window $w.text.$temp -padx 1 -pady 1
			#}
			incr temp
		}
		
		label $w.text.custom_new -text "[trans custom_new]"  -width [expr 1+[lindex $xy_geo 0]*3] -background [$w.text cget -background] -font splainf
		bind $w.text.custom_new <Enter> [list $w.text.custom_new configure -relief raised]
		bind $w.text.custom_new <Leave> [list $w.text.custom_new configure -relief flat]
		bind $w.text.custom_new <Button1-ButtonRelease> "::smiley::newCustomEmoticonGUI; event generate $w <Leave>"
		
		$w.text insert end "\n"
		$w.text window create end -window $w.text.custom_new -padx 1 -pady 1
		
		$w.text configure -state disabled
		
		
		bind $w <Enter> "bind $w <Leave> \"bind $w <Leave> \\\"wm state $w withdrawn\\\"\""
	}
	
	
	#///////////////////////////////////////////////////////////////////////////////
	# proc newCustomEmoticonGUI {}
	#
	# This is the GUI proc for adding custom smileys
	proc newCustomEmoticonGUI {{name ""}} {
		global new_custom_cfg
		
		if { [winfo exists .new_custom] } {
			raise .new_custom
			return
		}

		toplevel .new_custom
		
		set w [LabelFrame:create .new_custom.lfname -text [trans smileconfig] -font splainf]
		pack $w -anchor n -side top -expand 1 -fill x
		
		frame .new_custom.1 -class Degt
		label .new_custom.1.smile -image [::skin::loadPixmap smile]
		pack .new_custom.1.smile -side left -anchor nw
		
		label $w.lname -text "[trans description]" -font splainf
		entry $w.name -textvariable new_custom_cfg(name) -background white -font splainf
		
		label $w.ltext -text "[trans triggers]" -font splainf
		entry $w.text -textvariable new_custom_cfg(text)  -background white -font splainf
		
		label $w.lfile -text "[trans smilefile]" -font splainf
		entry $w.file -textvariable new_custom_cfg(file)  -background white -font splainf
		button $w.browsefile -text "[trans browse]" -command [list chooseFileDialog "" "" .new_custom $w.file open  \
				[list [list [trans imagefiles] [list *.gif *.GIF *.jpg *.JPG *.bmp *.BMP *.png *.PNG]] [list [trans allfiles] *]]] -width 10 
		
		label $w.lsound -text "[trans soundfile]" -font splainf
		entry $w.sound -textvariable new_custom_cfg(sound)  -background white -font splainf
		button $w.browsesound -text "[trans browse]" -command [list chooseFileDialog "" "" .new_custom $w.sound open \
			[list [list [trans soundfiles] [list *.wav *.mp3 *.au *.ogg]] [list [trans allfiles] *]]] -width 10 
		checkbutton $w.enablesound -text "[trans enablesound]" -onvalue 1 -offvalue 0 -variable new_custom_cfg(enablesound) -command ::smiley::UpdateEnabledSoundSmileys -font sboldf
		checkbutton $w.animated -text "[trans animatedemoticon]" -onvalue 1 -offvalue 0 -variable new_custom_cfg(animated) -font sboldf
		checkbutton $w.casesensitive -text "[trans casesensitive]" -onvalue 1 -offvalue 0 -variable new_custom_cfg(casesensitive) -font sboldf
		
		frame .new_custom.buttons -class Degt
		
		
		if { $name == "" } {
			wm title .new_custom "[trans custom_new]"
			label .new_custom.1.intro -text "[trans smileintro]" -font splainf
			button .new_custom.buttons.ok -text "[trans ok]" -command ::smiley::NewCustomEmoticonGUI_Ok -padx 10
			button .new_custom.buttons.delete -text "[trans delete]" -command "" -state disabled -padx 11
		} else {
			wm title .new_custom "[trans custom_edit]"
			label .new_custom.1.intro -text "[trans smileintro2]" -font splainf
			button .new_custom.buttons.ok -text "[trans ok]" -command [list ::smiley::NewCustomEmoticonGUI_Ok $name] -padx 10
			button .new_custom.buttons.delete -text "[trans delete]" -command [list ::smiley::NewCustomEmoticonGUI_Delete $name] -padx 11
			$w.name configure -state disabled
		}
		
		button .new_custom.buttons.cancel -text "[trans cancel]" -command [list destroy .new_custom] -padx 10

		pack .new_custom.buttons.ok -side right -padx 5
		pack .new_custom.buttons.cancel -side right -padx 5
		pack .new_custom.buttons.delete -side left -padx 5
		pack .new_custom.buttons -side bottom -fill x -expand true -padx 5 -pady 5

		pack .new_custom.1.intro -fill both -side left

		grid columnconfigure $w 1 -weight 1
		
		grid $w.lname -row 1 -column 0 -padx 2 -pady 2 -sticky w
		grid $w.name -row 1 -column 1 -padx 2 -pady 2 -sticky w
		
		grid $w.ltext -row 2 -column 0 -padx 2 -pady 2 -sticky w
		grid $w.text -row 2 -column 1 -padx 2 -pady 2 -sticky w
		
		grid $w.lfile -row 3 -column 0 -padx 2 -pady 2 -sticky w
		grid $w.file -row 3 -column 1 -padx 2 -pady 2 -sticky we
		grid $w.browsefile -row 3 -column 2 -padx 2 -pady 2 -sticky w
		
		grid $w.lsound -row 4 -column 0 -padx 2 -pady 2 -sticky w
		grid $w.sound -row 4 -column 1 -padx 2 -pady 2 -sticky we
		grid $w.browsesound -row 4 -column 2 -padx 2 -pady 2 -sticky w
		
		grid $w.enablesound -row 5 -column 1 -columnspan 2 -padx 2 -pady 2 -sticky w
		grid $w.animated -row 6 -column 1 -columnspan 2 -padx 2 -pady 2 -sticky w
		
		grid $w.casesensitive -row 7 -column 1 -columnspan 2 -padx 2 -pady 2 -sticky w
		
		
		pack .new_custom.1 -expand 1 -fill both -side top -pady 5 -padx 5
		pack .new_custom.lfname -expand 1 -fill both -side top
		
		UpdateEnabledSoundSmileys
		
		bind .new_custom <Destroy> "catch {unset new_custom_cfg}"
		moveinscreen .new_custom 30
		catch {[focus .new_custom]}
		
	}
	
	proc NewCustomEmoticonGUI_Ok { {name ""}} {
		if { [NewCustomEmoticonFromGUI $name] != -1 } {
			destroy .new_custom
		}
	}
	

	proc NewCustomEmoticonGUI_Delete { name } {
		global custom_emotions
		
		set idx [lsearch [::config::getKey customsmileys] $name]
		if { $idx != -1 } {
			::config::setKey customsmileys [lreplace [::config::getKey customsmileys] $idx $idx]
		}
		unset custom_emotions($name)
		if { [winfo exists .smile_selector]} {destroy .smile_selector}
		
		
		destroy .new_custom

	}

	proc UpdateEnabledSoundSmileys { } {
		global new_custom_cfg
		
		set w .new_custom.lfname.f.f
		
		if { $new_custom_cfg(enablesound) == 1 } {
			$w.sound configure -state normal
			$w.browsesound configure -state normal
		} else {
			$w.sound configure -state disabled
			$w.browsesound configure -state disabled
		}
	}
	
		
	#///////////////////////////////////////////////////////////////////////////////
	# proc editCustomEmotion {}
	#
	# This is the GUI proc for editing custom smileys
	proc editCustomEmotion { name } {
		global custom_emotions new_custom_cfg
		
		array set emotion $custom_emotions($name)
		
		foreach element [list name file text animated sound casesensitive] {
			if {[info exists emotion($element)]} {
				set new_custom_cfg($element) $emotion($element)
			} else {
				set new_custom_cfg($element) ""
			}
		}
		
		if { "$new_custom_cfg(sound)" != "" } {
			set new_custom_cfg(enablesound) 1
		} else {
			set new_custom_cfg(enablesound) 0
		}

		newCustomEmoticonGUI $name

	}
	
	#///////////////////////////////////////////////////////////////////////////////
	# proc NewCustomEmoticonFromGUI { edit}
	#
	# this saves what was entered in the GUI for creating new custom smiley or edits
	# previously saved options
	proc NewCustomEmoticonFromGUI { {name ""} } {
		global custom_emotions custom_images new_custom_cfg HOME
		
		set w .new_custom

		if { $name == "" } {
			set name $new_custom_cfg(name)
			#set name "[string map { "\[" "\\\[" "\]" "\\\]" } $new_custom_cfg(name)]"
			set edit 0
		} else {
			set edit 1
			array set emotion $custom_emotions($name)
		}

		#Check for needed fields
		if { $name == "" || $new_custom_cfg(file) == "" || $new_custom_cfg(text) == "" } {
			msg_box "[trans wrongfields [trans description] [trans triggers] [trans smilefile] ]"
			return -1
		}
		
		#Check for sound, and copy it
		if { $new_custom_cfg(enablesound) && $new_custom_cfg(sound) != "" } {
			set filename [getfilename [GetSkinFile sounds $new_custom_cfg(sound)]]
			if { $filename == "null" } {
				#if { [info exists custom_emotions(${name}_sound)] } {unset custom_emotions(${name}_sound)}
				msg_box "[trans invalidfile [trans soundfile] \"$new_custom_cfg(sound)\"]"
				return -1
			} else {
				create_dir [file join $HOME sounds]
				catch { file copy [GetSkinFile sounds "$new_custom_cfg(sound)"] [file join $HOME sounds]}
			}
			set emotion(sound) $filename
			#set custom_emotions(${name}_sound) "$filename"
		} else {
			#if { [info exists custom_emotions(${name}_sound)] } {unset custom_emotions(${name}_sound)}
			#Delete sound settings if it existed before
			if { [info exists emotion(sound)] } { unset emotion(sound) }
		}
		
		set filename [getfilename [GetSkinFile smileys $new_custom_cfg(file)]]
		if { $filename == "null" } {
			msg_box "[trans invalidfile [trans smilefile] \"$new_custom_cfg(file)\"]"
			return -1
		} 
		
		create_dir [file join $HOME smileys]
		set file [convert_image_plus [GetSkinFile smileys "$new_custom_cfg(file)"] smileys 19x19]
		if { $file == "" } { return -1}
		
		set emotion(file) "[filenoext $file].gif"
		set emotion(name) $name
		set emotion(text) $new_custom_cfg(text)
		
		foreach element [list casesensitive animated] {
			if { $new_custom_cfg($element) == 1} {
				set emotion($element) 1
			} else {
				if { [info exist emotion($element)] } {unset emotion($element)}
			}
		}
		
		set custom_emotions($name) [array get emotion]
		set custom_images($name) [image create photo -file $emotion(file) -format gif]
		if { $edit == 0} {
			lappend [::config::getVar customsmileys] $name
		}

		#load_smileys
		#::skin::reloadSkinSettings [::config::getGlobalKey skin]
		if { [winfo exists .smile_selector]} {destroy .smile_selector}
		
		#Immediately save settings.xml
		save_config
	}
	
			
	#///////////////////////////////////////////////////////////////////////////////
	# proc ValueForSmiley { emotion var } 
	#
	# A useful function that we'll use to get every single variable for an emoticon
	# you call it with the name of the emoticon you want and the variable you want 
	# (for example [ValueForSmiley "000 smile" text] and it returns ":) :-)" something like that..
	# if the variable doesn't exist, it returns an empty string
	# If the returned value must be boolean, set boolean parameter to 1
	proc ValueForSmiley { name var {boolean 0}} {
		global emotions_data
		
		set value ""
		
		#If the smiley is not defined
		if { ![info exists emotions_data($name)] } {
			status_log "Smiley $name is not defined!\n" red
		} else {
			array set emotion $emotions_data($name)	
			if { [info exists emotion($var)] } {
				set value $emotion($var)
			}
		}
		
		#The returned value must be boolean
		if { $boolean == 1 } {
			if { $value == 1 || $value == "true" || $value == "yes" || $value == "y"} {
				return 1
			} else {
				return 0
			}
		} else { return $value }
	}
	
	#///////////////////////////////////////////////////////////////////////////////
	# proc CompareSmileyLength { a_name b_name } 
	#
	# Is used to sort the smileys with the longest length first
	# this is necessary to avoid replacing smaller smileys that may be included inside longer one
	# for example <:o) (party) may be considered as a :o smiley between < and ) ... 
	proc CompareSmileyLength { a b } {
	
	if { [string length $a] > [string length $b] } {
		return -1
	} elseif { [string length $a] < [string length $b] } {
		return 1
	}
	return 0
	
	}
}




#///////////////////////////////////////////////////////////////////////////////
# proc is_true { data }
#
# is used to see if a value is true or false while creating the emoticon
# we need it to simplify the source code because we may need to see an XML value
# before we create our smiley (for example to verify if smiley is disabled) so we can't use
# the procedure "valueforemot"

proc is_true { data } {

    set value [string trim $data]
    if { $value == 1 || $value  == "true" || $value == "yes" || $value == "y" } {return 1} else {return 0}
}



proc custom_smile_subst { chatid tw {textbegin "0.0"} {end "end"} } {
    upvar #0 ${chatid}_smileys emotions

    if { ![info exists emotions] } { return }

    after 250 "custom_smile_subst2 $chatid $tw $textbegin $end"

} 

proc custom_smile_subst2 { chatid tw textbegin end } { 
    upvar #0 ${chatid}_smileys emotions

    if { ![info exists emotions] } { return }

    status_log "Parsing text for [array names emotions] with tw = $tw, textbegin = $textbegin and end = $end\n"

    foreach symbol [array names emotions] {
	set chars [string length $symbol]
	set file [::MSNP2P::GetFilenameFromMSNOBJ $emotions($symbol)]
	if { $file == "" } { continue }

	status_log "Got file $file for symbol -$symbol-\n" red

	set start $textbegin
	status_log "result $tw search -exact -nocase bb $start $end : [$tw search -exact -nocase bb $start $end]--- $start -- $textbegin\n"

	while {[set pos [$tw search -exact -nocase -- $symbol $start $end]] != ""} {
	    status_log "Found match at pos : $pos\n" red

	    set posyx [split $pos "."]
	    set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $chars}]"


	    $tw tag configure smiley -elide true
	    $tw tag add smiley $pos $endpos

	    $tw image create $endpos -image custom_smiley_$file -pady 0 -padx 0
	    $tw tag remove smiley $endpos
	    
	}
    }

    unset emotions
}

#Called from the protocol layer to parse a x-mms-emoticon message
proc parse_x_mms_emoticon { data chatid } {
    upvar #0 ${chatid}_smileys smile


    if { [::config::getKey getdisppic] != 1 } { return }

    set start 0
    while { $start < [string length $data]} {
	set end [string first "	" $data $start]
	set symbol [string range $data $start [expr $end - 1]]
	set start [expr $end + 1]
	set end [string first "	" $data $start]
	set msnobj [string range $data $start [expr $end - 1]]
	set start [expr $end + 1]

	set smile($symbol) "$msnobj"
    }
	
    status_log "Got smileys : [array names smile]\n" 

}
proc process_custom_smileys_SB { txt } {
    global custom_emotions
    

    #    if { [::config::getKey custom_smileys] == 0 } { return "" }

    set msg ""

    #status_log "Parsing text for custom smileys : $txt\n\n"

    set txt2 [string toupper $txt]

    foreach name [::config::getKey customsmileys] {
	
	array set emotion $custom_emotions($name)
	#foreach symbol $emotion(text) {
	set symbol $emotion(text)
	set symbol2 [string toupper $symbol]

	set cases [expr {[info exists emotion(casesensitive] && [is_true $emotion(casesensitive)]}]
	set file $emotion(file)

	if { $cases == 1} {
		if {  [string first $symbol $txt] != -1 } {
			set msg "$msg$symbol	[create_msnobj [::config::getKey login] 2 [GetSkinFile smileys [filenoext $file].png]]	"
		}
	} else {
		if {  [string first $symbol2 $txt2] != -1 } {
			set msg "$msg$symbol	[create_msnobj [::config::getKey login] 2 [GetSkinFile smileys [filenoext $file].png]]	"
		}
	}
	#}
    }

    return $msg
}




#///////////////////////////////////////////////////////////////////////////////
# proc calcul_geometry_smileys {  }
#
# This function is used to calculate the optimal width and height for the
# smileys menu. it calculs 5 different possibilities for width/height then searches
# for the lowest value and returns the values for width and height that are optimal for 
# the menu depending on the number of smileys to show


proc calcul_geometry_smileys {  } {
	global emotions_names

	set emoticon_number [llength $emotions_names]
	incr emoticon_number [llength [::config::getKey customsmileys]]
	set min [expr int(sqrt($emoticon_number))]
	
	set values [list]
	set x [list]
	set y [list]
	
	lappend values [expr ($min - 1) * ($min + 1)]
	lappend x [expr $min - 1]
	lappend y [expr $min - 1]
	
	lappend values [expr ($min) * ($min)]
	lappend x $min
	lappend y $min
	
	lappend values [expr ($min) * ($min + 1)]
	lappend x [expr $min + 1]
	lappend y $min 
	
	lappend values [expr ($min) * ($min + 2)]
	lappend x [expr $min + 2]
	lappend y $min 
	
	lappend values [expr ($min + 1) * ($min + 1)]
	lappend x [expr $min + 1]
	lappend y [expr $min + 1]
	
	set diff [list]
	
	foreach val $values { 
	
		if {$val < $emoticon_number} {
		lappend diff 1000
		} else {
		lappend diff [expr $val - $emoticon_number]
		}
	}
	
	set min_val 0
	
	while { 1 } {
		if { [lsearch $diff "$min_val"] == -1 } {
		set min_val [expr $min_val + 1]
		continue
		} 
		
		set min [lsearch $diff "$min_val" ]
		
		return "[lindex $x $min] [expr [lindex $y $min] + 1]"
	}

}


