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
# proc is_true { data } {
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
       set name [format " %03i %s" "$emoticon_number" "$name"]
       set emoticon_number [expr $emoticon_number + 1]
   }
    
    lappend emotions_names "$name"
    if { [string match "config:emoticon" $cstack] } {
	puts "custom smiley"
	lappend config(customsmileys) "$name"
    }

    foreach x [array names sdata] {
	set x2 [string trim [string map [list "${cstack}:" "" ] $x]]
	if { $x2 == "_dummy_" } {continue}

	set emotions(${name}_${x2}) [string trim $sdata($x)]

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

     }

    return 0
}

#///////////////////////////////////////////////////////////////////////////////
# proc new_custom_emoticon_from_gui {}
#
# this saves what was entered in the GUI for creating new custom smiley

proc new_custom_emoticon_from_gui { } {
    global custom_emotions config

    set w .new_custom

    set name "[$w.name.entry get]"
    lappend config(customsmileys) "$name"

    set custom_emotions(${name}_name) "$name"
    set custom_emotions(${name}_file) "[string trim [$w.file.entry get]]"
    set custom_emotions(${name}_text) "[string trim [$w.text.entry get]]"

    load_smileys
}

#///////////////////////////////////////////////////////////////////////////////
# proc edit_custom_emoticon_from_gui {}
#
# this saves what was entered in the GUI for editing a custom smiley

proc edit_custom_emoticon_from_gui { name } {
    global custom_emotions emotions

    set w .new_custom
    set custom_emotions(${name}_file) "[string trim [$w.file.entry get]]"
    set custom_emotions(${name}_text) "[string trim [$w.text.entry get]]"
  

    load_smileys
}
#///////////////////////////////////////////////////////////////////////////////
# proc new_custom_emoticon_gui {}
#
# This is the GUI proc for adding custom smileys

proc new_custom_emoticon_gui { {edit 0} {name ""}} {
    set w .new_custom
    toplevel $w
    wm geometry $w

    frame $w.name
    label $w.name.label -text "name"
    entry $w.name.entry
    pack $w.name.label $w.name.entry -side left
    frame $w.text
    label $w.text.label -text "text"
    entry $w.text.entry
    pack $w.text.label $w.text.entry -side left
    frame $w.file
    label $w.file.label -text "file"
    entry $w.file.entry
    pack $w.file.label $w.file.entry -side left

    pack $w.name $w.text $w.file -side top

    if { $edit == 0 } {
	button $w.ok -text "OK" -command "new_custom_emoticon_from_gui;destroy $w"
    } else {
	button $w.ok -text "OK" -command "edit_custom_emoticon_from_gui \"$name\";destroy $w"
    }
    button $w.cancel -text "Cancel" -command "destroy $w"


    pack $w.ok $w.cancel -side top
    bind $w <Destroy> "grab release $w"

    grab set .new_custom
}

#///////////////////////////////////////////////////////////////////////////////
# proc new_custom_emoticon_gui {}
#
# This is the GUI proc for edditing custom smileys
proc edit_custom_emotion { emotion } {
    global emotions
    new_custom_emoticon_gui 1 "$emotions(${emotion}_name)"

    set w .new_custom

    $w.name.entry insert 0 $emotions(${emotion}_name)
    $w.text.entry insert 0 $emotions(${emotion}_text)
    $w.file.entry insert 0 $emotions(${emotion}_file)

    
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
    sxml::parse $skin_id
    sxml::end $skin_id

    add_custom_emoticon


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

proc add_custom_emoticon { } {
    global custom_emotions emotions emotions_names emoticon_number config

    foreach x $config(customsmileys) {

	if { ! ( [info exists custom_emotions(${x}_hiden)] && 
		 [is_true $custom_emotions(${x}_hiden)] ) } {
	    set name [format " %03i %s" "$emoticon_number" "$x"]
	    set emoticon_number [expr $emoticon_number + 1]
	}
    
	puts "new custom emoticon $name"
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
# proc smile_subst { tw {start "0.0"} {enable_sound 0} }
#
# Main function... it substitues smileys patterns into an image in any text widget
# tw variable is the text widget
# start is the starting point for wich we scan the text for any smiley to change
# enable_sound is used to specify if we should play sounds if we find emotisound
# this is used to avoid playing sounds when contact list is refreshed
# the function scans the text widget (from the $start variable to the end) and 
# replaces any smileys pattern by the appropriate image (animated or not) and plays
# a sound if necessary, etc... It scans the widget for every smiley that exists

proc smile_subst {tw {start "0.0"} {enable_sound 0}} {
    global emotions sortedemotions config smileys_drawn ;# smileys_end_subst
    
  
    foreach emotion $sortedemotions {
	
	set file $emotions(${emotion}_file)
	set filename [string map { " " "_" "/" "_" "." "_"} $file]

	foreach symbol $emotions(${emotion}_text) {
	    set chars [string length $symbol]


	    set animated [valueforemot "$emotion" animated]
	    set sound [valueforemot "$emotion" sound]
	    if { [valueforemot "$emotion" casesensitive] } {set nocase "-exact"} else {set nocase "-nocase"}
	    if { $config(animatedsmileys) == 0 } {set animated 0}


	    while {[set pos [$tw search -exact $nocase \
				 $symbol $start end]] != ""} {
		set posyx [split $pos "."]
		set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $chars}]"

#		$tw tag configure smiley ;# -elide true
#		$tw tag add smiley $pos $endpos
#		$tw tag bind smiley <<Selection>> "puts \"selected\""

		$tw delete $pos $endpos

		if { $animated } {
		    
		    set emoticon $tw.${smileys_drawn}_anigif_$filename	    
		    set smileys_drawn [expr $smileys_drawn + 1]		      
		    
		    label $emoticon -bd 0 -background white
		    ::anigif::anigif [GetSkinFile smileys ${file}] $emoticon
		    
		    $tw window create $pos -window $emoticon       
		    bind $emoticon <Destroy> "::anigif::destroy $emoticon"		    

		    set tagname  [$tw tag names $pos]
		    if { [llength $tagname] == 1 } {
		       #status_log "Replacing. Existing binding for $tagname: [$tw tag bind $tagname <Button3-ButtonRelease>]\n" blue
		       bind $emoticon <Button3-ButtonRelease> "[$tw tag bind $tagname <Button3-ButtonRelease>]"
		       bind $emoticon <Enter> "[$tw tag bind $tagname <Enter>]"
		       bind $emoticon <Leave> "[$tw tag bind $tagname <Leave>]"
		       
		    }

#		    bind $emoticon <Visibility> "VisibilityChangeEmot $emoticon 1 %s $tw $pos $file"



		} else {
		    $tw image create $pos -image $file -pady 1 -padx 1
		}

		
		if { $config(emotisounds) == 1 && $enable_sound == 1 && $sound != "" } {
		    play_sound $sound
		}

		
	    }
	}
    }

}


#///////////////////////////////////////////////////////////////////////////////
# proc smile_menu { {x 0} {y 0} {text text}}
#
# Displays the smileys menu at the position where the mouse is and refreshs
# all the bindings on the smileys in the menu to the correct widget
# so that when you click on a smiley, it inserts its symbol into your text 
# if the smile menu doesn't exist it created it first with [create_smile_menu $x $y]

proc smile_menu { {x 0} {y 0} {text text}} {
    global emotions_names emotions

    set w .smile_selector

    if { ! [winfo exists $w]} {
	create_smile_menu $x $y
    }

    set x [expr $x - 15]
    set y [expr $y - 15]
    wm geometry $w +$x+$y
    wm state $w normal


    foreach emotion [lsort $emotions_names] {
	set symbol [lindex $emotions(${emotion}_text) 0]
	set file $emotions(${emotion}_file)
	set filename [string map { " " "_" "/" "_" "." "_"} $file]

	catch { 
	    if { [string match {(%)} $symbol] != 0 } {
		bind $w.text.$filename <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; wm state $w withdrawn} res"
	    } else {
		bind $w.text.$filename <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\; wm state $w withdrawn} res" 
	    }
	    if { [valueforemot "$emotion" custom]  } {
		puts "creating binding for custom smiley : $emotion"
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
    set x [expr $x - 15]
    set y [expr $y - 15]
    set xy_geo [calcul_geometry_smileys]
    set x_geo [expr 23*[lindex $xy_geo 0]+8]
    set y_geo [expr 23*[lindex $xy_geo 1]+8]
    
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

