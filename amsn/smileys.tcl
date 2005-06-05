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
	#
	# array custom_emotions(NAME) - Similar to emotions_data, but used for
	#                          storing information about your custom smileys
	

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
			set realfile [::skin::GetSkinFile smileys $emotion(file) $::loading_skin]
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
			::skin::setPixmap $text $emotion(file) smileys
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
		global custom_emotions
		
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
		#Create the image now and store it
		set emotion(image_name) [image create photo -file $emotion(file)]
		
		#Add to the list of custom emoticons
		lappend [::config::getVar customsmileys] $emotion(name)
		#Store the emoticon data in the custom_emoticons array
		set custom_emotions($emotion(name)) [array get emotion]

		variable sortedemotions
		if {[info exists sortedemotions]} { unset sortedemotions }
		
		
		return 0
	}
	

	
	#///////////////////////////////////////////////////////////////////////////////
	# proc SortSmileys
	#
	# Create a list of available smileys, sorted by symbol length
	proc SortSmileys {} {
		global emotions
		global custom_emotions
			
		variable sortedemotions
		
		#If no sorted list exists, create it...
		if { ![info exists sortedemotions]} {
			set unsortedemotions [list]
			
			#Add standard smileys. We just add the symbol, and keyword "standard"
			foreach name [array names emotions] {
				lappend unsortedemotions [list $name standard]
			}
			
			#Add our custom smileys. For custom smileys we also add
			#the smiley name associated to that symbol
			foreach name [array names custom_emotions] {
			
				if { ![info exists custom_emotions($name)] } {
					status_log "substYourSmileys: Custom smiley $name doesn't exist in custom_emotions array!!\n" red
					continue
				}
			
				array set emotion $custom_emotions($name)
				foreach symbol $emotion(text) {
					lappend unsortedemotions [list $symbol custom $name]
				}
			}
			
#TODO: Add SB smileys?

			#Now, sort this list			
			set sortedemotions [lsort -command ::smiley::CompareSmileyLength $unsortedemotions]
		}
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
	proc substSmileys {tw {textbegin "0.0"} {end "end"} {contact_list 0} {include_custom 0}} {
		global emotions
		global custom_emotions
		variable sortedemotions
				
		SortSmileys
			
		#Search for all possible emotions, after they are sorted by symbol length
		foreach emotion_data $sortedemotions {
		
			#Symbol is first element
			set symbol [lindex $emotion_data 0]
			#Type is second element
			set smiley_type [lindex $emotion_data 1]
			
			if { $smiley_type == "custom" } {
				#If smiley type is custom, replace or ignore it depending on call parameter
				if { $include_custom == 0} {
					continue
				} else {
					#Get name. It will be 3rd element on the list
					set name [lindex $emotion_data 2]
					
					#Get all emoticon data from custom_emotions array
					array set emotion $custom_emotions($name)
					
					if { [info exists emotion(casesensitive)] && [is_true $emotion(casesensitive)]} {
						set nocase "-exact"
					} else {
						set nocase "-nocase"
					}
					
					set animated [expr {[info exists emotion(animated)] && [is_true $emotion(animated)]}]
					if { $contact_list == 0 && [info exists emotion(sound)] && $emotion(sound) != "" } {
						set sound $emotion(sound)
					} else { set sound "" }
					set image_name $emotion(image_name)
					set image_file $emotion(file)
					
					
					array unset emotion
				}
				
			} else {
				#Get the name for this symbol
				set emotion_name $emotions($symbol)
	
				if { [ValueForSmiley $emotion_name casesensitive 1] } {
					set nocase "-exact"
				} else {
					set nocase "-nocase"
				}
				
				set animated [ValueForSmiley $emotion_name animated 1]			
				if { $contact_list == 0 && [ValueForSmiley $emotion_name sound] != "" } {
					set sound [ValueForSmiley $emotion_name sound]
				} else { set sound "" }
				set image_name [::skin::loadPixmap $symbol smileys]
				set image_file [ValueForSmiley $emotion_name file]
				
				set start $textbegin

			}

			
			#Keep searching until no matches
			set start $textbegin
			while {[set pos [$tw search -exact $nocase -- $symbol $start $end]] != ""} {
			
				
				set start [::smiley::SubstSmiley $tw $pos $symbol $image_name $image_file $animated $sound]
				#If SubstSmiley returns -1, start from beggining.
				#See why in SubstSmiley. This is a fix
				if { $start == -1 } { set start $textbegin }
		
			}
			
			
			
			
		}
	
	}
	
	#//////////////////////////////////////////////////////////////////////
	# proc SubstSmiley {tw pos symbol image file animated sound }
	#
	# Replace one smiley in the given $tw (text window)
	proc SubstSmiley { tw pos symbol image file animated { sound "" }} {

		set chars [string length $symbol]

		set posyx [split $pos "."]
		set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $chars}]"
	
		if { [lsearch -exact [$tw tag names $pos] "dont_replace_smileys"] != -1 } {
			return $endpos
		}

		$tw tag configure smiley -elide true
		$tw tag add smiley $pos $endpos
	
		$tw image create $endpos -image $image -pady 0 -padx 0
		$tw tag remove smiley $endpos

		if { [::config::getKey emotisounds] == 1 && $sound != "" } {
			play_sound $sound
		}
		
		#If I return $pos and there's a smiley next to the replaced one,
		#it won't be replaced!! is this a tk error?? We return -1,
		#so we restart from beginning
		return -1
	}
		
	
	#///////////////////////////////////////////////////////////////////////////////
	# proc smileyMenu { {x 0} {y 0} {text text}}
	#
	# Displays the smileys menu at the position where the mouse is and refreshes
	# all the bindings on the smileys in the menu to the correct widget
	# so that when you click on a smiley, it inserts its symbol into your text 
	# if the smile menu doesn't exist it created it first with [create_smile_menu $x $y]
	proc smileyMenu { {x 0} {y 0} {text text}} {
		global emotions_names
		
		set w .smile_selector
		
		
		if { ! [winfo exists $w]} { CreateSmileyMenu }
		
		wm state $w normal
		set x [expr {$x - 15}]
		set y [expr {$y + 15 - [winfo height $w]}]
		wm geometry $w +$x+$y
		#It won't work on Windows without this
		update idletasks
		
		
		#It won't work on Windows without this
		raise $w
		
		#Add bindings for standard emotions
		set temp 0
		foreach name $emotions_names {
			if { [ValueForSmiley $name hiden 1] } {continue}
		
			#Get the first symbol for that smiley
			set symbol [lindex [ValueForSmiley $name symbols] 0]
			
			#This must be cached due to a race condition (if you double click
			#the smileys menu for first time, the second click can launch
			#this procedure without all smileys having been created
			catch { 
				#TODO: Improve this now we know about quoting a bit more?
				if { [string match {(%)} $symbol] != 0 } {
					bind $w.c.$temp <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; wm state $w withdrawn} res"
				} else {
					bind $w.c.$temp <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\; wm state $w withdrawn} res" 
				}
			}
			
			incr temp
		}
		
		#Now add custom emotions bindings
		global custom_emotions
		foreach name [::config::getKey customsmileys] {
			array set emotion $custom_emotions($name)
			set symbol [lindex $emotion(text) 0]
			
			#This must be cached due to a race condition (if you double click
			#the smileys menu for first time, the second click can launch
			#this procedure without all smileys having been created
			catch { 
				#TODO: Improve this now we know about quoting a bit more?
				if { [string match {(%)} $symbol] != 0 } {
					bind $w.c.$temp <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; wm state $w withdrawn} res"
				} else {
					bind $w.c.$temp <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\; wm state $w withdrawn} res" 
				}
				#Add binding for custom emoticons
				if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
					
					bind $w.c.$temp <Button2-ButtonRelease> [list ::smiley::editCustomEmotion $name]
					bind $w.c.$temp <Control-ButtonRelease> [list ::smiley::editCustomEmotion $name]
				} else {
					bind $w.c.$temp <Button3-ButtonRelease> [list ::smiley::editCustomEmotion $name]
				}
			}
			
			incr temp
		}
		
		event generate $w <Enter>
	
	}


	#//////////////////////////////////////////////////////////////////
	#proc that changes a string into a list with seperated text/smileys
	proc parseMessageToList { name {contact_list 0} {include_custom 0} } {
		global emotions
		global custom_emotions
		variable sortedemotions

		#This is a poor place for sort smileys should be done only when adding new smileys to the list?
		#SortSmileys

		set l [list [ list "text" "$name" ]]
		set llength 1

		#Search for all possible emotions, after they are sorted by symbol length
		foreach emotion_data [concat $sortedemotions [list [list "\n" "newline"]]] {

			#Symbol is first element
			set symbol [lindex $emotion_data 0]
			#Type is second element
			set smiley_type [lindex $emotion_data 1]

			if { $smiley_type == "custom" } {
				#If smiley type is custom, replace or ignore it depending on call parameter
				if { $include_custom == 0} {
					continue
				} else {
					#Get name. It will be 3rd element on the list
					set name [lindex $emotion_data 2]

					#Get all emoticon data from custom_emotions array
					array set emotion $custom_emotions($name)

					if { [info exists emotion(casesensitive)] && [is_true $emotion(casesensitive)]} {
						set nocase "-exact"
					} else {
						set nocase "-nocase"
					}
		
					set animated [expr {[info exists emotion(animated)] && [is_true $emotion(animated)]}]
					if { $contact_list == 0 && [info exists emotion(sound)] && $emotion(sound) != "" } {
						set sound $emotion(sound)
					} else {
						set sound ""
					}
					set image_name $emotion(image_name)
					set image_file $emotion(file)
		
		
					array unset emotion
				}
		
			} elseif { $smiley_type == "newline" } {
				set emotion_name "newline"
				set nocase "-exact"
				set animated 0
				set sound ""
				set image_name "__newline__"
				set image_file ""
			} else {
				#Get the name for this symbol
				set emotion_name $emotions($symbol)
	
				if { [ValueForSmiley $emotion_name casesensitive 1] } {
					set nocase "-exact"
				} else {
					set nocase "-nocase"
				}
	
				set animated [ValueForSmiley $emotion_name animated 1]
				if { $contact_list == 0 && [ValueForSmiley $emotion_name sound] != "" } {
					set sound [ValueForSmiley $emotion_name sound]
				} else {
					set sound ""
				}
				set image_name [::skin::loadPixmap $symbol smileys]
				set image_file [ValueForSmiley $emotion_name file]
			}

			set listpos 0
			#Keep searching until no matches
#TODO: make it not case sensitive
			while { $listpos < $llength } {
				if { ([lindex $l $listpos 0] != "text") } {
					incr listpos
					continue
				}
				
				if {[set pos [string first $symbol [lindex $l $listpos 1]]] != -1 } {
					set p1 [string range [lindex $l $listpos 1] 0 [expr {$pos - 1}]]
					set p2 $image_name
					set p3 [string range [lindex $l $listpos 1] [expr {$pos + [string length $symbol]}] end]

#TODO: #need to change for an 'in-place' lreplace (here and below)
					if { $p2 == "__newline__" } {
						set l [lreplace $l $listpos $listpos [list text $p1] [list "newline"] [list text $p3] ]
					} else {
						set l [lreplace $l $listpos $listpos [list text $p1] [list smiley $p2] [list text $p3] ]
					}

					incr llength 2
					
					if { $p3 == "" } {
						set listpos2 [expr {$listpos + 2}]
						set l [lreplace $l $listpos2 $listpos2]
						incr llength -1
					}
					if { $p1 == "" } {
						set l [lreplace $l $listpos $listpos]
						incr llength -1
						incr listpos -1
					}
				}
				#text can never be followed by another set of text
				incr listpos 2
			}
		}

#TODO: also parse newlines as [list newline]

		return $l
	}


	
	#Create ONE smiley in the smileys menu
	proc CreateSmileyInMenu {w cols rows smiw smih emot_num name symbol image file animated} {
		catch {

			label $w.$emot_num -image $image -background [$w cget -background]
	
			$w.$emot_num configure -cursor hand2 -borderwidth 1 -relief flat
			
			#Bindings for raise/flat on mouse over
			bind $w.$emot_num <Enter>  [list $w.$emot_num configure -relief raised]
			bind $w.$emot_num <Leave> [list $w.$emot_num configure -relief flat]

			#Toolstip
			if { [::config::getKey tooltips] } {set_balloon $w.$emot_num "$name $symbol"}
			set xpos [expr {($emot_num % $cols)* $smiw}]
			set ypos [expr {($emot_num / $cols) * $smih}]
			$w create window $xpos $ypos -window $w.$emot_num -anchor nw -width $smiw -height $smih
		}
	}

	#///////////////////////////////////////////////////////////////////////////////
	# proc CreateSmileyMenu { {x 0} {y 0} }
	#
	# Create the smile menu... it first calls [calcul_geometry_smileys]
	# To get the width and height of the menu, then it creates the menu withdrawn with 
	# the animated smileys and static smileys in the correct order
	proc CreateSmileyMenu { } {
		global emotions emotions_names custom_emotions

		set w .smile_selector
		if {[catch {[toplevel $w]} res]} {
			destroy $w
			toplevel $w
		}
		
		#Calculate the total number of smileys (including custom ones)
		set emoticon_number [llength $emotions_names]
		incr emoticon_number [llength [::config::getKey customsmileys]]
		
		#Fixed smiley size
		set smiw 26
		set smih 26
		
		#We want to keep a certain ratio:
		# cols/(rows+1) = 4/3
		# we know cols*rows>=emoticon_number
		#This is the solution of solving that equation system
		set ratio [expr {4.0/3.0}]
		set cols [expr {ceil(($ratio+sqrt(($ratio*$ratio)+4.0*$ratio*$emoticon_number))/2.0)}]
		set rows [expr {ceil(double($emoticon_number) / $cols)+1}]

		#status_log "Smileys: $emoticon_number. Cols: $cols. Rows: $rows\n" white
		set cols [expr {int($cols)}]
		set rows [expr {int($rows)}]
		
		set x_geo [expr {$smiw*$cols + 2} ]
		set y_geo [expr {$smih*$rows + 2} ]
		
		
		wm state $w withdrawn
		wm geometry $w ${x_geo}x${y_geo}
		wm title $w "[trans msn]"
		wm overrideredirect $w 1
		wm transient $w
		
		
		canvas $w.c -background white -borderwidth 0 -relief flat \
			-selectbackground white -selectborderwidth 0 
		pack $w.c -expand true -fill both
		
		#Add standard smileys
		set emot_num 0
		foreach name $emotions_names {
			set hiden [ValueForSmiley $name hiden 1]
			if { $hiden} {continue}
			
			set symbol [lindex [ValueForSmiley $name symbols] 0]
			set file [ValueForSmiley $name file]
			set animated [expr {[ValueForSmiley $name animated 1] && [::config::getKey animatedsmileys 0]}]
			
			CreateSmileyInMenu $w.c $cols $rows $smiw $smih \
				$emot_num $name $symbol [::skin::loadPixmap $symbol smileys] [::skin::GetSkinFile smileys ${file}] $animated

			incr emot_num
		
		}
		
		#Now add custom emotions
		global custom_emotions
		foreach name [::config::getKey customsmileys] {
		
			array set emotion $custom_emotions($name)
			if {![info exists emotion(animated)]} { set emotion(animated) 0 }
			set animated [expr {$emotion(animated) && [::config::getKey animatedsmileys 0]}]
			
			CreateSmileyInMenu $w.c $cols $rows $smiw $smih \
				$emot_num $name [lindex $emotion(text) 0] $emotion(image_name) $emotion(file) $animated
	
			incr emot_num
		}

		#Add the create custom smiley button	
		label $w.c.custom_new -text "[trans custom_new]"  -background [$w.c cget -background] -font sboldf
		bind $w.c.custom_new <Enter> [list $w.c.custom_new configure -relief raised]
		bind $w.c.custom_new <Leave> [list $w.c.custom_new configure -relief flat]
		bind $w.c.custom_new <Button1-ButtonRelease> "::smiley::newCustomEmoticonGUI; event generate $w <Leave>"
		
		set ypos [expr {(($rows-1)*$smih + ($smih/2))}]
		$w.c create window  0 $ypos -window $w.c.custom_new -width [expr {$x_geo - 2}] -height $smih -anchor w
		
		
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
		
		#After modifying, clear sortedemotions, could need sorting again
		variable sortedemotions
		if {[info exists sortedemotions]} { unset sortedemotions }
		
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
		
		catch { event generate .smile_selector <Leave> }
		
		array set emotion $custom_emotions($name)
		
		foreach element [list name file animated sound casesensitive] {
			if {[info exists emotion($element)]} {
				set new_custom_cfg($element) $emotion($element)
			} else {
				set new_custom_cfg($element) ""
			}
		}
		set new_custom_cfg(text) [join $emotion(text)]
		
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
		global custom_emotions new_custom_cfg HOME
		
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
			set filename [getfilename [::skin::GetSkinFile sounds $new_custom_cfg(sound)]]
			if { $filename == "null" } {
				#if { [info exists custom_emotions(${name}_sound)] } {unset custom_emotions(${name}_sound)}
				msg_box "[trans invalidfile [trans soundfile] \"$new_custom_cfg(sound)\"]"
				return -1
			} else {
				create_dir [file join $HOME sounds]
				catch { file copy [::skin::GetSkinFile sounds "$new_custom_cfg(sound)"] [file join $HOME sounds]}
			}
			set emotion(sound) $filename
			#set custom_emotions(${name}_sound) "$filename"
		} else {
			#if { [info exists custom_emotions(${name}_sound)] } {unset custom_emotions(${name}_sound)}
			#Delete sound settings if it existed before
			if { [info exists emotion(sound)] } { unset emotion(sound) }
		}
		
		set filename [getfilename [::skin::GetSkinFile smileys $new_custom_cfg(file)]]
		if { $filename == "null" } {
			msg_box "[trans invalidfile [trans smilefile] \"$new_custom_cfg(file)\"]"
			return -1
		} 
		
		create_dir [file join $HOME smileys]
		set file [convert_image_plus [::skin::GetSkinFile smileys "$new_custom_cfg(file)"] smileys 19x19]
		if { $file == "" } {
			return -1
		}
		
		set emotion(file) $file
		set emotion(name) $name
		
		#Create a list of symbols
		set emotion(text) [list]
		foreach symbol [split $new_custom_cfg(text)] {
			if { $symbol != "" } {
				lappend emotion(text) $symbol
			}
		}
		
		foreach element [list casesensitive animated] {
			if { $new_custom_cfg($element) == 1} {
				set emotion($element) 1
			} else {
				if { [info exist emotion($element)] } {unset emotion($element)}
			}
		}
		
		set emotion(image_name) [image create photo -file $emotion(file)]
		set custom_emotions($name) [array get emotion]
		if { $edit == 0} {
			if { [lsearch -exact [::config::getKey customsmileys] $name] == -1 } {
				lappend [::config::getVar customsmileys] $name
			}
		}

		#load_smileys
		#::skin::reloadSkinSettings [::config::getGlobalKey skin]
		if { [winfo exists .smile_selector]} {destroy .smile_selector}

		#After modifying, clear sortedemotions, could need sorting again
		variable sortedemotions
		if {[info exists sortedemotions]} { unset sortedemotions }
		
				
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
	
	#Get just the symbol (first element), not the type
	set a [lindex $a 0]
	set b [lindex $b 0]
	
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
	set symbol [string range $data $start [expr {$end - 1}]]
	set start [expr {$end + 1}]
	set end [string first "	" $data $start]
	set msnobj [string range $data $start [expr {$end - 1}]]
	set start [expr {$end + 1}]

	set smile($symbol) "$msnobj"
    }
	
    status_log "Got smileys : [array names smile]\n" 

}
proc process_custom_smileys_SB { txt } {
	global custom_emotions
	
	set msg ""
	
	set txt2 [string toupper $txt]

	#Try to find used smileys in the message	
	foreach name [::config::getKey customsmileys] {
	
		if { ![info exists custom_emotions($name)] } {
			status_log "process_custom_smileys_SB: Custom smiley $name doesn't exist in custom_emotions array!!\n" red
			continue
		}
		
		array set emotion $custom_emotions($name)
		foreach symbol $emotion(text) {
			set symbol2 [string toupper $symbol]
		
			set file $emotion(file)
		
			if { [info exists emotion(casesensitive] && [is_true $emotion(casesensitive)]} {
				if {  [string first $symbol $txt] != -1 } {
					set msg "$msg$symbol	[create_msnobj [::config::getKey login] 2 [::skin::GetSkinFile smileys [filenoext $file].png]]	"
				}
			} else {
				if {  [string first $symbol2 $txt2] != -1 } {
					set msg "$msg$symbol	[create_msnobj [::config::getKey login] 2 [::skin::GetSkinFile smileys [filenoext $file].png]]	"
				}
			}
		}
	}
	
	return $msg
}

