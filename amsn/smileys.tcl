#
# $Id$
#


#///////////////////////////////////////////////////////////////////////////////
# proc compareSmileyLength { a_name b_name } 
#
# Is used to sort the smileys with the longuest length first
# this is necessary to avoid replacing smaller smileys that may be included inside longuer one
# for example <:o) (party) may be considered as a :o smiley between < and ) ... 
# Since I can't sort my array.. I'm just sorting the names 
# I use the emotions_names variable and get the first text element from the real smiley to compare it

proc compareSmileyLength { a_name b_name } {
    global emotions

    set a $emotions(${a_name}_text)
    set b $emotions(${b_name}_text)


    if { [string length [lindex $a 0]] > [string length [lindex $b 0]] } {
	return -1
    } elseif { [string length [lindex $a 0]] < [string length [lindex $b 0]] } {
	return 1
    } else {
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


#///////////////////////////////////////////////////////////////////////////////
# proc new_emoticon {cstack cdata saved_data cattr saved_attr args}
#
# This is the main procedure for creating our emoticons, it gets data from the XML
# parser (don't know what all args are made for) and retreives the data we need and 
# creates the arrays we need.
# For every new emoticon, we add it's name to emotions_names (preceded by a number for
# having the correct ordrer in the menu) then we add the elements in the array emotions

proc new_emoticon {cstack cdata saved_data cattr saved_attr args} {
    global emotions emotions_names emoticon_number
    upvar $saved_data sdata
    
    if { ! [info exists sdata(${cstack}:name)] } { return 0 }
    if { ! [info exists sdata(${cstack}:text)] } { return 0 }
    if { ! [info exists sdata(${cstack}:file)] } { return 0 }
    if { [info exists sdata(${cstack}:disabled)] && [is_true $sdata(${cstack}:disabled)] } { return 0 }

    set name [string trim $sdata(${cstack}:name)]
 
    if { ! ( [info exists sdata(${cstack}:hiden)] && 
	     [is_true $sdata(${cstack}:hiden)] ) } {
       set name [format "%03i %s" "$emoticon_number" "$name"]
       set emoticon_number [expr $emoticon_number + 1]
   }
    
    lappend emotions_names "$name"
    if { [string match "config:emoticon" $cstack] } {
	#status_log "custom smiley"
	lappend config(customsmileys) "$name"
    }

    foreach x [array names sdata] {
	set x2 [string trim [string map [list "${cstack}:" "" ] $x]]
	if { $x2 == "_dummy_" } {continue}

	set emotions(${name}_${x2}) [string trim $sdata($x)]
	set emotions(${name}_${x2}) [string map { \\ \\\\ } $emotions(${name}_${x2})]

     }

    return 0
}


#///////////////////////////////////////////////////////////////////////////////
# proc new_custom_emoticon {cstack cdata saved_data cattr saved_attr args}
#
# This is the same procedure as new_emoticon
# the only difference is that it is used for custom emoticons..
# we need to do it that way since after calling "load_smileys" it erases the 
# emotions list...

proc new_custom_emoticon {cstack cdata saved_data cattr saved_attr args} {
    global custom_emotions config
    upvar $saved_data sdata
    
    if { ! [info exists sdata(${cstack}:name)] } { return 0 }
    if { ! [info exists sdata(${cstack}:text)] } { return 0 }
    if { ! [info exists sdata(${cstack}:file)] } { return 0 }
    if { [info exists sdata(${cstack}:disabled)] && [is_true $sdata(${cstack}:disabled)] } { return 0 }

    set name [string trim $sdata(${cstack}:name)]
    lappend config(customsmileys) "$name"


    foreach x [array names sdata] {
	set x2 [string trim [string map [list "${cstack}:" "" ] $x]]
	if { $x2 == "_dummy_" } {continue}

	set custom_emotions(${name}_${x2}) [string trim $sdata($x)]
	set custom_emotions(${name}_${x2}) [string map { \\ \\\\ } $custom_emotions(${name}_${x2})]

     }

    return 0
}

#///////////////////////////////////////////////////////////////////////////////
# proc new_custom_emoticon_from_gui { edit}
#
# this saves what was entered in the GUI for creating new custom smiley or edits
# previously saved options

proc new_custom_emoticon_from_gui { {name ""} } {
    global custom_emotions config new_custom_cfg HOME


    set w .new_custom
    set quit 0

    if { [info exists new_custom_cfg(disabled)] && $new_custom_cfg(disabled) == 1 } {
	set idx [lsearch $config(customsmileys) $name]
	if { $idx != -1 } {
	    set config(customsmileys) [lreplace $config(customsmileys) $idx $idx]
	}
	load_smileys
	return
    }
    if { $name == "" } {
	set name "$new_custom_cfg(name)"
	set edit 0
    } else {
	set edit 1
    }

    if { "$name" == "" || "$new_custom_cfg(file)" == "" || "$new_custom_cfg(text)" == "" } {
	msg_box "[trans wrongfields [trans description] [trans triggers] [trans smilefile] ]"
	return
    }

    if { $new_custom_cfg(enablesound) && "$new_custom_cfg(sound)" != "" } {
	set filename [getfilename [GetSkinFile sounds $new_custom_cfg(sound)]]
	#status_log "sound : $filename\n"
	if { "$filename" == "null" } {
	    if { [info exists custom_emotions(${name}_sound)] } {unset custom_emotions(${name}_sound)}
	    msg_box "[trans invalidfile [trans soundfile] \"$new_custom_cfg(sound)\"]"
	    set quit 1
	} else {
	    create_dir [file join $HOME sounds]
	    catch { file copy [GetSkinFile sounds "$new_custom_cfg(sound)"] [file join $HOME sounds]}
	}
	set custom_emotions(${name}_sound) "$filename"
    } else {
	if { [info exists custom_emotions(${name}_sound)] } {unset custom_emotions(${name}_sound)}
    }

    set filename [getfilename [GetSkinFile smileys $new_custom_cfg(file)]]
    #status_log "smiley : $filename\n"
    if { "$filename" == "null" } {
	msg_box "[trans invalidfile [trans smilefile] \"$new_custom_cfg(file)\"]"
	return
    } else {
	if { $quit == 1 } { return }
	create_dir [file join $HOME smileys]
	set file [convert_image_plus [GetSkinFile smileys "$new_custom_cfg(file)"] smileys 19x19]
	if { $file == 0 } { return }
    }
    set custom_emotions(${name}_file) "$file.gif"
    set custom_emotions(${name}_name) "$name"
    set custom_emotions(${name}_text) "$new_custom_cfg(text)"

    if { $new_custom_cfg(hiden) } {
	set custom_emotions(${name}_hiden) 1
    } else {
	if { [info exists custom_emotions(${name}_hiden)] } {unset custom_emotions(${name}_hiden)}
    }
    if { $new_custom_cfg(casesensitive) } {
	set custom_emotions(${name}_casesensitive) 1
    } else {
	if { [info exists custom_emotions(${name}_casesensitive)] } {unset custom_emotions(${name}_casesensitive)}
    }
    
    if { $new_custom_cfg(animated) } {
	set custom_emotions(${name}_animated) 1
    } else {
	if { [info exists custom_emotions(${name}_animated)] } {unset custom_emotions(${name}_animated)}
    }

    if { $edit == 0} {
	lappend config(customsmileys) "$name"
    }

    load_smileys
}

#///////////////////////////////////////////////////////////////////////////////
# proc new_custom_emoticon_gui {}
#
# This is the GUI proc for adding custom smileys

proc new_custom_emoticon_gui {{name ""}} {
    global new_custom_cfg

    if { [info exists new_custom_cfg] } {unset new_custom_cfg}

    toplevel .new_custom
    wm group .new_custom .
    wm transient .new_custom .
    wm geometry .new_custom

    set w [LabelFrame:create .new_custom.lfname -text [trans smileconfig]]
    pack $w -anchor n -side top -expand 1 -fill x

    image create photo regular_smile -file [GetSkinFile smileys regular_smile.gif] 

    frame .new_custom.1 -class Degt
    label .new_custom.1.smile -image regular_smile
    pack .new_custom.1.smile -side left -anchor nw

    label $w.lname -text "[trans description]"
    entry $w.name -textvariable new_custom_cfg(name) -background white

    label $w.ltext -text "[trans triggers]"
    entry $w.text -textvariable new_custom_cfg(text)  -background white
 
    label $w.lfile -text "[trans smilefile]"
    entry $w.file -textvariable new_custom_cfg(file)  -background white
    button $w.browsefile -text "[trans browse]" -command "fileDialog2 .new_custom $w.file open \"\" {{\"Image Files\" {*.gif *.jpg *.jpeg *.bmp *.png} }} " -width 10
  
    label $w.lsound -text "[trans soundfile]"
    entry $w.sound -textvariable new_custom_cfg(sound)  -background white
    button $w.browsesound -text "[trans browse]" -command "fileDialog2 .new_custom $w.sound open \"\" {{\"Image Files\" {*.gif *.jpg *.jpeg *.bmp *.png} }} " -width 10
    checkbutton $w.enablesound -text "[trans enablesound]" -onvalue 1 -offvalue 0 -variable new_custom_cfg(enablesound) -command update_enabled_sound_smileys
    checkbutton $w.animated -text "[trans animatedemoticon]" -onvalue 1 -offvalue 0 -variable new_custom_cfg(animated)
    checkbutton $w.hiden -text "[trans hiden]" -onvalue 1 -offvalue 0 -variable new_custom_cfg(hiden)
    checkbutton $w.casesensitive -text "[trans casesensitive]" -onvalue 1 -offvalue 0 -variable new_custom_cfg(casesensitive)

    frame .new_custom.buttons -class Degt
    
    if { $name == "" } {
	wm title .new_custom "[trans custom_new]"
	label .new_custom.1.intro -text "[trans smileintro]"
	button .new_custom.buttons.ok -text "[trans ok]" -command "new_custom_emoticon_from_gui;destroy .new_custom" -width 15
	button .new_custom.buttons.delete -text "[trans delete]" -command "" -width 15 -state disabled
    } else {
	wm title .new_custom "[trans custom_edit]"
	label .new_custom.1.intro -text "[trans smileintro2]"
	button .new_custom.buttons.ok -text "[trans ok]" -command "new_custom_emoticon_from_gui \"$name\";destroy .new_custom" -width 15
	button .new_custom.buttons.delete -text "[trans delete]" -command "set new_custom_cfg(disabled) 1;new_custom_emoticon_from_gui \"$name\";destroy .new_custom" -width 15
	$w.name configure -state disabled
    }

    button .new_custom.buttons.cancel -text "[trans cancel]" -command "destroy .new_custom" -width 15


    grid .new_custom.buttons.ok -row 0 -column 0
    grid .new_custom.buttons.cancel -row 0 -column 1
    grid .new_custom.buttons.delete -row 0 -column 2
    pack .new_custom.buttons -side bottom -fill x -pady 10

    pack .new_custom.1.intro -fill both -side left

    grid $w.lname -row 1 -column 0 -padx 2 -pady 2
    grid $w.name -row 1 -column 1 -padx 2 -pady 2
    grid $w.ltext -row 1 -column 2 -padx 2 -pady 2
    grid $w.text -row 1 -column 3 -padx 2 -pady 2

    grid $w.lfile -row 2 -column 0 -padx 2 -pady 2
    grid $w.file -row 2 -column 1 -padx 2 -pady 2
    grid $w.browsefile -row 2 -column 2 -padx 2 -pady 2

    grid $w.lsound -row 3 -column 0 -padx 2 -pady 2
    grid $w.sound -row 3 -column 1 -padx 2 -pady 2
    grid $w.browsesound -row 3 -column 2 -padx 2 -pady 2


    grid $w.enablesound -row 4 -column 0 -padx 2 -pady 2
    grid $w.animated -row 4 -column 2 -padx 2 -pady 2

    grid $w.hiden -row 5 -column 0 -padx 2 -pady 2
    grid $w.casesensitive -row 5 -column 2 -padx 2 -pady 2

    
    pack .new_custom.1 -expand 1 -fill both -side top -pady 15
    pack .new_custom.lfname -expand 1 -fill both -side top
  
    update_enabled_sound_smileys

    bind .new_custom <Destroy> "grab release .new_custom"
    grab set .new_custom


    after 2000 "catch {wm state .new_custom normal}"
}

proc update_enabled_sound_smileys { } {
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
# proc new_custom_emoticon_gui {}
#
# This is the GUI proc for edditing custom smileys
proc edit_custom_emotion { emotion } {
    global emotions new_custom_cfg
    new_custom_emoticon_gui "[valueforemot $emotion name]"

    set new_custom_cfg(name) [valueforemot "$emotion" name]
    set new_custom_cfg(file) [valueforemot "$emotion" file]
    set new_custom_cfg(text) [valueforemot "$emotion" text]
    set new_custom_cfg(animated) [valueforemot "$emotion" animated]
    set new_custom_cfg(sound) [valueforemot "$emotion" sound]
    if { "$new_custom_cfg(sound)" != "" } {set new_custom_cfg(enablesound) 1 }
    set new_custom_cfg(casesensitive) [valueforemot "$emotion" casesensitive]
    set new_custom_cfg(hiden) [valueforemot "$emotion" hiden]
     
    update_enabled_sound_smileys 

}

#///////////////////////////////////////////////////////////////////////////////
# proc load_smileys { }
#
# Used to load the smileys.. I needed that procedure for testing when I change 
# the settings.xml file, I just had to call this proc to reload the smileys
# it will be necessary when changing skins between users (if we do it)
# it initializes all variables then parse the xml file, sort the emotions names
# and create the image for every smiley. If the menu exists, destroys it so that
# it will be refreshed

proc load_smileys { } {
    global custom_emotions emoticon_number sortedemotions program_dir smileys_drawn emotions emotions_names 

    set emoticon_number 0

    set emotions_names [list]
    if { [info exists emotions] } {unset emotions}

    set skin_id [sxml::init [GetSkinFile "" settings.xml]]

    sxml::register_routine $skin_id "skin:smileys:emoticon" new_emoticon
    sxml::register_routine $skin_id "skin:Description" skin_description
    sxml::register_routine $skin_id "skin:Colors" SetBackgroundColors
    sxml::parse $skin_id
    sxml::end $skin_id

    add_custom_emoticons


    if { ! [info exists smileys_drawn] } {
	set smileys_drawn 0
    }

    set sortedemotions [lsort -command compareSmileyLength $emotions_names]
    set emotion_files [list]
    
    foreach x $emotions_names {
	lappend emotion_files "$emotions(${x}_file)"
    }

    
    foreach img_name $emotion_files {
	image create photo $img_name -file [GetSkinFile smileys ${img_name}] 
    }

    if { [winfo exists .smile_selector]} {destroy .smile_selector} 
}

#///////////////////////////////////////////////////////////////////////////////
# proc add_custom_emoticon {}
#
# This adds the custom smileys to the general smileys

proc add_custom_emoticons { } {
    global custom_emotions emotions emotions_names emoticon_number config

    set config(customsmileys2) [list]
    foreach x $config(customsmileys) {

	if { ! ( [info exists custom_emotions(${x}_hiden)] && 
		 [is_true $custom_emotions(${x}_hiden)] ) } {
	    set name [format "%03i %s" "$emoticon_number" "$x"]
	    set emoticon_number [expr $emoticon_number + 1]
	} else {
	    set name "$x"
	}
    
	#status_log "new custom emoticon $name\n"
	lappend emotions_names "$name"
	lappend config(customsmileys2) "$name"

	foreach emotion [array names custom_emotions] {
	    if { [string match "${x}_*" $emotion ] } {
		set x2 [string trim [string map [list "${x}_" "" ] $emotion]]
		
		set emotions(${name}_${x2}) $custom_emotions($emotion)
	    }
	}
	set emotions(${name}_custom) "true"
    }
    
}


#///////////////////////////////////////////////////////////////////////////////
# proc valueforemot { emotion var } 
#
# A usefull function that we'll use to get every single variable for an emoticon
# you call it with the name of the emoticon you want and the variable you want 
# (for example [valueforemot "000 smile" text] and it returns ":) :-)" something like that..
# if the variable doesn't exist, it returns an empty string
# the way to use it is shown in the smile_subst function. for boolean variables, it returns 1
# if it is true, yes, y or 1 and it returns 0 otherwise... boolean variables are in the 
# variable values_on_off (so that the function knows if it should return an empty string or a 0
# if variable doesn't exist...

proc valueforemot { emotion var } {
    global emotions

    set values_on_off "animated casesensitive hiden custom"

    if { [lsearch $values_on_off $var] == -1 } {
	if { [info exists emotions(${emotion}_$var)] } {
	    return  $emotions(${emotion}_$var)
	} else { return "" }
	
    } else {
	if { [info exists emotions(${emotion}_${var})] } {
	    set var_   $emotions(${emotion}_${var})
	    if { $var_ == 1 || $var_ == "true" || $var_ == "yes" || $var_ == "y"} {
		return 1
	    } else {
		return 0
	    }
	} else { return 0 }
    }
}


#///////////////////////////////////////////////////////////////////////////////
# proc smile_subst { tw {start "0.0"} {end "end"} {contact_list 0} }
#
# Main function... it substitues smileys patterns into an image in any text widget
# tw variable is the text widget
# start is the starting point for wich we scan the text for any smiley to change
# contact_list is used to specify if we should play sounds if we find emotisound
# this is used to avoid playing sounds when contact list is refreshed
# the function scans the text widget (from the $start variable to the end) and
# replaces any smileys pattern by the appropriate image (animated or not) and plays
# a sound if necessary, etc... It scans the widget for every smiley that exists

proc smile_subst {tw {textbegin "0.0"} {end "end"} {contact_list 0}} {
	global emotions sortedemotions config smileys_drawn ;# smileys_end_subst

	foreach emotion $sortedemotions {

		foreach symbol $emotions(${emotion}_text) {
			set chars [string length $symbol]


			if { [valueforemot "$emotion" casesensitive] } {set nocase "-exact"} else {set nocase "-nocase"}
			set sound [valueforemot "$emotion" sound]
			set animated [valueforemot "$emotion" animated]
			set file [valueforemot "$emotion" file]

			set start $textbegin

			while {[set pos [$tw search -exact $nocase $symbol $start $end]] != ""} {

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

				if { $animated && $config(animatedsmileys) } {

					set filename [string map { " " "_" "/" "_" "." "_"} $file]
					set emoticon $tw.${smileys_drawn}_anigif_$filename
					set smileys_drawn [expr $smileys_drawn + 1]

					label $emoticon -bd 0 -background white
					::anigif::anigif [GetSkinFile smileys ${file}] $emoticon

					$tw window create $endpos -window $emoticon
					bind $emoticon <Destroy> "::anigif::destroy $emoticon"
					$tw tag remove smiley $endpos

					set tagname  [$tw tag names $endpos]
					if { [llength $tagname] == 1 } {
						bind $emoticon <Button3-ButtonRelease> "[$tw tag bind $tagname <Button3-ButtonRelease>]"
						bind $emoticon <Enter> "[$tw tag bind $tagname <Enter>]"
						bind $emoticon <Leave> "[$tw tag bind $tagname <Leave>]"
					}

				} else {
					$tw image create $endpos -image $file -pady 1 -padx 1
					$tw tag remove smiley $endpos
				}

				if { $config(emotisounds) == 1 && $contact_list == 0 && $sound != "" } {
					play_sound $sound
				}

				#status_log "Repaced $symbol from $start to $endpos\n" blue

				#set start $endpos

			}
		}
	}

}

proc process_custom_smileys_SB { txt } {
    global emotions config 
    

    if { $config(custom_smileys) == 0 } { return "" }

    set msg ""

    status_log "Parsing text for custom smileys : $txt\n\n"

    set txt2 [string toupper $txt]

    foreach emotion $config(customsmileys2) {
	
	status_log "Parsing for $emotion\n"
	foreach symbol $emotions(${emotion}_text) {
	    set symbol2 [string toupper $symbol]

	    set cases [valueforemot "$emotion" casesensitive] 
	    set file [valueforemot "$emotion" file]

	    if { $cases == 1} {
		if {  [string first $symbol $txt] != -1 } {
		    set msg "$msg$symbol	[create_msnobj $config(login) 2 [GetSkinFile smileys [filenoext $file]]]	"
		    
		}
	    } else {
		if {  [string first $symbol2 $txt2] != -1 } {
		    set msg "$msg$symbol	[create_msnobj $config(login) 2 [GetSkinFile smileys [filenoext $file]]]	"
		}
	    }
	}
    }

    return $msg
}




#///////////////////////////////////////////////////////////////////////////////
# proc smile_menu { {x 0} {y 0} {text text}}
#
# Displays the smileys menu at the position where the mouse is and refreshs
# all the bindings on the smileys in the menu to the correct widget
# so that when you click on a smiley, it inserts its symbol into your text 
# if the smile menu doesn't exist it created it first with [create_smile_menu $x $y]

proc smile_menu { {x 0} {y 0} {text text}} {
    global emotions_names emotions emoticonbinding

    set w .smile_selector

    if { ! [winfo exists $w]} {
	create_smile_menu $x $y
    }
    
    if { [info exists emoticonbinding ] } {unset emoticonbinding}

    set x [expr $x - 15]
    set y [expr $y + 15 - [winfo height $w]]
    wm geometry $w +$x+$y
    #It won't work on Windows without this
    update idletasks
    
    wm state $w normal
    
    #It won't work on Windows without this
    raise $w


    foreach emotion [lsort $emotions_names] {
	set symbol [lindex $emotions(${emotion}_text) 0]
	set file $emotions(${emotion}_file)
	set filename [string map { " " "_" "/" "_" "." "_"} $file]
	set temp 0
	
	while { [info exists emoticonbinding($filename) ] } {
	    set filename "${filename}$temp"
	    incr temp
	}
	unset temp

	set emoticonbinding($filename) 0
	catch { 
	    if { [string match {(%)} $symbol] != 0 } {
		bind $w.text.$filename <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; wm state $w withdrawn} res"
	    } else {
		bind $w.text.$filename <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\; wm state $w withdrawn} res" 
	    }
	    if { [valueforemot "$emotion" custom]  } {
		#status_log "creating binding for custom smiley : $emotion\n"
		bind $w.text.$filename <Button3-ButtonRelease> "edit_custom_emotion \"$emotion\"; event generate $w <Leave>"
	    }
	}
    }

    event generate $w <Enter>

}



#///////////////////////////////////////////////////////////////////////////////
# proc create_smile_menu { {x 0} {y 0} }
#
# Create the smile menu... it first calls [calcul_geometry_smileys] 
# To get the width and height of the menu, then it creates the menu withdrawn with 
# the animated smileys and static smielys in the correct order


proc create_smile_menu { {x 0} {y 0} } {
    global emotions emotions_names config
    
    set w .smile_selector
    if {[catch {[toplevel $w]} res]} {
	destroy $w
	toplevel $w     
    }
    set xy_geo [calcul_geometry_smileys]
    set x_geo [expr 23*[lindex $xy_geo 0]+8]
    set y_geo [expr 23*[lindex $xy_geo 1]+8]
    set x [expr $x - 15]
    set y [expr $y + 15 - $y_geo]
    
    wm geometry $w ${x_geo}x${y_geo}+$x+$y
    wm title $w "[trans msn]"
    wm overrideredirect $w 1
    wm transient $w
    wm state $w normal
   
    
    text $w.text -background white -borderwidth 2 -relief ridge \
       -selectbackground white -selectborderwidth 0 -exportselection 0
    
    pack $w.text

    $w.text configure -state normal
    
    
    foreach emotion [lsort $emotions_names] {
	set name $emotions(${emotion}_name)
	set symbol [lindex $emotions(${emotion}_text) 0]
	set file $emotions(${emotion}_file)
	set filename [string map { " " "_" "/" "_" "." "_"} $file]
	set temp 0
	
	while { [winfo exists $w.text.$filename ] } {
	    set filename "${filename}$temp"
	    incr temp
	}
	unset temp

	set chars [string length $symbol]
	set hiden [valueforemot "$emotion" hiden]
	set animated [valueforemot "$emotion" animated]
	if { $config(animatedsmileys) == 0 } {set animated 0}

	if { $hiden} {continue}

	catch {
 	    if { $animated } {
 		label $w.text.$filename -background [$w.text cget -background]
  		::anigif::anigif  [GetSkinFile smileys ${file}] $w.text.$filename
 		bind $w.text.$filename <Destroy> "::anigif::destroy $w.text.$filename"	
 	    } else {
		label $w.text.$filename -image $file -background [$w.text cget -background]
	    }

	    $w.text.$filename configure -cursor hand2 -borderwidth 1 -relief flat
	   
	    
	    bind $w.text.$filename <Enter> "$w.text.$filename configure -relief raised"
	    bind $w.text.$filename <Leave> "$w.text.$filename configure -relief flat"
	    if { $config(tooltips) } {set_balloon $w.text.$filename "$name $symbol"}
	    $w.text window create end -window $w.text.$filename -padx 1 -pady 1
	}
	
	
    }

    label $w.text.custom_new -text "[trans custom_new]"  -width [expr 1+[lindex $xy_geo 0]*3] -background [$w.text cget -background]
    bind $w.text.custom_new <Enter> "$w.text.custom_new configure -relief raised"
    bind $w.text.custom_new <Leave> "$w.text.custom_new configure -relief flat"
    bind $w.text.custom_new <Button1-ButtonRelease> "new_custom_emoticon_gui; event generate $w <Leave>"
 
    $w.text insert end "\n"
    $w.text window create end -window $w.text.custom_new -padx 1 -pady 1 
 
		     
		     
    $w.text configure -state disabled
    

    bind $w <Enter> "bind $w <Leave> \"bind $w <Leave> \\\"wm state $w withdrawn\\\"\""
}


#///////////////////////////////////////////////////////////////////////////////
# proc calcul_geometry_smileys {  } 
#
# This function is used to calculate the optimal width and height for the
# smileys menu. it calculs 5 different possibilities for width/height then searchs 
# for the lowest value and returns the values for width and height that are optimal for 
# the menu depending on the number of smileys to show


proc calcul_geometry_smileys {  } {
    global emoticon_number 

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

# after_info { } 
#
# Gives information about the pending timers 
proc after_info { } {
    
    foreach in [after info] {
	status_log "$in : [after info $in]\n"
    }
}

