#
# $Id$
#


# Comments on this file were made at an early hour.. I'm tired... and my english is poor.. so sorry 
# if you don't understand a word.. at least it's better than having nothing at all ...
# KaKaRoTo ;)




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

#   puts "a : $a -- a_name : $a_name"
#   puts "b : $b -- b_name : $b_name"

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
    global emotions emotions_names emoticon emoticon_number
    upvar $saved_data sdata
    
    if { ! [info exists sdata(smileys:emoticon:name)] } { return 0 }
    if { ! [info exists sdata(smileys:emoticon:text)] } { return 0 }
    if { ! [info exists sdata(smileys:emoticon:file)] } { return 0 }
    if { [info exists sdata(smileys:emoticon:disabled)] && [is_true $sdata(smileys:emoticon:disabled)] } { return 0 }

    set name [string trim $sdata(smileys:emoticon:name)]
 
   if { ! ( [info exists sdata(smileys:emoticon:hiden)] && 
	    [is_true $sdata(smileys:emoticon:hiden)] ) } {
       set name [format " %03i %s" "$emoticon_number" "$name"]
       set emoticon_number [expr $emoticon_number + 1]
   }
    
#    puts "new emoticon : $name"


    lappend emotions_names "$name"

    foreach x [array names sdata] {
	set x2 [string trim [string map { "smileys:emoticon:" "" } $x]]
	if { $x2 == "_dummy_" } {continue}

	set emotions(${name}_${x2}) [string trim $sdata($x)]

     }

    return 0
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
    global emoticon_number sortedemotions program_dir skin smileys_drawn emotions emotions_names smileys_folder

    set emoticon_number 0

    set emotions_names [list]
    if { [info exists emotions] } {unset emotions}

    set skin_id [sxml::init [file join $program_dir skins $skin settings.xml]]

    sxml::register_routine $skin_id "smileys:emoticon" new_emoticon
    sxml::parse $skin_id
    sxml::end $skin_id

    #source [file join $program_dir skins $skin smileys.tcl]

    if { ! [info exists smileys_drawn] } {
	set smileys_drawn 0
    }

#    puts "$emotions_names"

    set sortedemotions [lsort -command compareSmileyLength $emotions_names]
    
#    puts "$sortedemotions"

    set emotion_files [list]
    
    foreach x $emotions_names {
	lappend emotion_files "$emotions(${x}_file)"
    }

    
    foreach img_name $emotion_files {
	image create photo $img_name -file [file join ${smileys_folder} ${img_name}]
    }

    if { [winfo exists .smile_selector]} {destroy .smile_selector} 
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

    set values_on_off "animated casesensitive hiden"

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
    global emotions sortedemotions config smileys_folder smileys_drawn sounds_folder ;# smileys_end_subst
    
  
    foreach emotion $sortedemotions {
	
	set file $emotions(${emotion}_file)
	set filename [string map { "." "_"} $file]

	foreach symbol $emotions(${emotion}_text) {
	    set chars [string length $symbol]

#	    puts "$symbol"
	    set animated [valueforemot "$emotion" animated]
	    set sound [valueforemot "$emotion" sound]
	    if { [valueforemot "$emotion" casesensitive] } {set nocase "-exact"} else {set nocase "-nocase"}
	    if { $config(animatedsmileys) == 0 } {set animated 0}

#	    puts "$symbol :  $animated -- $sound -- $nocase"

	    while {[set pos [$tw search -exact $nocase \
				 $symbol $start end]] != ""} {
		set posyx [split $pos "."]
		set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $chars}]"

#		$tw tag configure smiley ;# -elide true
#		$tw tag add smiley $pos $endpos
#		$tw tag bind smiley <<Selection>> "puts \"selected\""

		$tw delete $pos $endpos

		if { $animated } {
		    
# 		    if { [llength [$tw bbox $pos]] == 0 } {
# 			$tw image create $pos -name anigif_$file -image $file -pady 1 -padx 1
# 		    }
		    set emoticon $tw.${smileys_drawn}_anigif_$filename
		    set smileys_drawn [expr $smileys_drawn + 1]		      
		    
		    label $emoticon -bd 0 -background [$tw cget -background]
		    ::anigif::anigif  [file join $smileys_folder ${file}] $emoticon
		    
		    $tw window create $pos -window $emoticon       
		    bind $emoticon <Destroy> "::anigif::destroy $emoticon"		    
#		    bind $emoticon <Visibility> "VisibilityChangeEmot $emoticon 1 %s $tw $pos $file"

		    anigif_info set $emoticon 1

#		    puts "animated gif"
		} else {
		    	    
		    $tw image create $pos -image $file -pady 1 -padx 1
#		    puts "normal gif"
		}

		#         $tw insert [expr $pos] ":)" 	       
		# 	  $tw tag add elided_smiley [expr $pos]
		# 	  $tw tag configure elided_smiley -elide true
		
		if { $config(emotisounds) == 1 && $enable_sound == 1 && $sound != "" } {
		    catch {eval exec $config(soundcommand) [file join $sounds_folder ${sound}] &} res
		}

#		break

		
	    }
	}
    }


#    set smileys_end_subst 1
}



#///////////////////////////////////////////////////////////////////////////////
# proc ScrollChange { from w args }
#
# This is a new function.. it's called whenever a chat window is scrolled..
# this means when you scroll or when new text is entered.. it's used to destroy 
# animated gifs when they aren't displayed and to recreate them when they are displayed
# First it checks if it's the text widget that called the function or the scrollbar
# depending on the result, it calls the appropriate function to synchronize text/scrollbar widgets
# then it verifies every window in the text widget (animated gifs) if it's not displayed,
# it destroys it and replaces it with a static image with a name begining with anigif_ 
# then the file it represents (to change it back).
# Then it scans every image (static smileys) in the text widget and every image
# whose name contains "anigif_" (animated gif transformed into static gif and that are displayed
# to the screen are destroyed then replaced with the appropriate animated gif


proc ScrollChange { from w args } {

#    puts "from :$from -- $w --  $args"



    # Update --- Sync the text and scrollbar widgets    

    if { $from == "text" } {
	.$w.f.out.ys set [lindex $args 0] [lindex $args 1]
    } elseif { $from == "scrollbar" } {    
	if { "[lindex $args 2]" != "" } {
	    .$w.f.out.text yview [lindex $args 0] [lindex $args 1] [lindex $args 2] 
	} else {
	    .$w.f.out.text yview [lindex $args 0] [lindex $args 1] 
	}
    }

    set tw .$w.f.out.text


    # Update gifs
    catch {
	
	# For every animated gif check if it's displayed
	foreach window [$tw window names] {
	    #	puts "$window"

	    set pos [$tw index $window]
	    set file [string range $window [expr [string first "anigif_" $window] + 7] end]   


	    if { [anigif_info get $window] && [llength [$tw bbox $window]] == 0 } {
		
		anigif_info set $window 0

#		puts "animated gif disappears -- pos : $pos --- file : $file "
		::anigif::stop $window	
			

# 		$tw image create $pos -name anigif_$file -image $file -pady 1 -padx 1

# 		destroy $window
# 		::anigif::destroy $window


	    } elseif { ![anigif_info get $window] && [llength [$tw bbox $window]] != 0 } {

		anigif_info set $window 1

#		puts "animated gif appears -- pos : $pos --- file : $file "

		::anigif::restart $window

	    }
	    
	}
	
	# For every static image, check if it was an animated one that is now displayed
# 	foreach window [$tw image names] {
# 	    #	puts "$window"
	    
	    
# 	    if { [string match "anigif_*" $window] == 0 } {continue}
	    
# 	    if { [llength [$tw bbox $window]] != 0 } {
# 		global smileys_drawn smileys_folder

# 		$tw configure -state normal

# 		set pos [$tw index $window]
# 		if { [string last "\#" $window] != -1 } {
# 		    set file [string range $window [expr [string first "anigif_" $window] + 7] [expr [string last "\#" $window] - 1]]
# 		} else {
# 		    set file [string range $window [expr [string first "anigif_" $window] + 7] end]
# 		}

		
		
# 		puts "animated gif appears -- pos : $pos --- file : $file "
		
# 		$tw delete $pos 
# 		set emoticon $tw.${smileys_drawn}_anigif_$file
# 		set smileys_drawn [expr $smileys_drawn + 1]		      
		
# 		label $emoticon -bd 0 -background [$tw cget -background]
# 		::anigif::anigif  [file join $smileys_folder ${file}] $emoticon
		
# 		$tw window create $pos -window $emoticon       
# 		bind $emoticon <Destroy> "::anigif::destroy $emoticon"
		
# 		$tw configure -state disabled
# 	    }
	    
# 	} 
    }
    
}


#///////////////////////////////////////////////////////////////////////////////
# proc anigif_info { w } 
#
# simple function to verify if an animated gif is animated or stoped
# returns 1 if animated and 0 if not

proc anigif_info { command w args} {
    global anigif_info

    switch  $command {
	set {
	    set anigif_info($w) [lindex $args 0]
	} 
	get {
	    if { [info exists anigif_info($w)] } {
		return $anigif_info($w)
	    } else { return 0 }
		 
	}
    }
	    


#     if { [catch { after info [set ${window}(loop)] }] != 0 } {
# 	return 0
#     } else {return 1}

    
}




# proc VisibilityChangeEmot { emoticon emstate state tw pos file } {

#     puts "$emoticon -- $emstate -- $state -- $pos --- $file"

#     if { $emstate == 1 } {
# 	if { $state != "VisibilityFullyObscured" } {return}

# 	$tw delete $pos
# 	destroy $emoticon

	
# 	$tw image create $pos -image $file -pady 1 -padx 1
# 	$tw tag configure aniimages
# 	$tw tag add aniimages $pos
# 	$tw tag bind aniimages <Visibility> "VisibilityChangeEmot $emoticon 0 %s $tw $pos $file"
#     }

# }




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

#     set x [expr $x - 15]
#     set y [expr $y - 15]

#     wm geometry $w +$x+$y
    
#    wm state $w normal

    foreach emotion [lsort $emotions_names] {
	set symbol [lindex $emotions(${emotion}_text) 0]
	set file $emotions(${emotion}_file)
	set filename [string map { "." "_"} $file]

	catch { 
	    if { [string match {(%)} $symbol] != 0 } {
#		bind $w.text.$filename <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; wm state $w withdrawn} res"
		bind $w.text.$filename <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; destroy $w} res"
	    } else {
#		bind $w.text.$filename <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\;[list wm state $w withdrawn]} res"     
		bind $w.text.$filename <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\;[list destroy $w]} res"     
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
    global emotions emotions_names smileys_folder config
    
    set w .smile_selector
    if {[catch {[toplevel $w]} res]} {
	destroy $w
	toplevel $w     
    }
    set x [expr $x - 15]
    set y [expr $y - 15]
    set xy_geo [calcul_geometry_smileys]
    set x_geo [lindex $xy_geo 0]
    set y_geo [lindex $xy_geo 1]
    
    wm geometry $w [expr 23*${x_geo}+8]x[expr 23*${y_geo}+8]+$x+$y
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
	set filename [string map { "." "_"} $file]
	set chars [string length $symbol]
	set hiden [valueforemot "$emotion" hiden]
	set animated [valueforemot "$emotion" animated]
	if { $config(animatedsmileys) == 0 } {set animated 0}

	if { $hiden} {continue}

	catch {
 	    if { $animated } {
 		label $w.text.$filename -background [$w.text cget -background]
  		::anigif::anigif  [file join $smileys_folder ${file}] $w.text.$filename
 		bind $w.text.$filename <Destroy> "::anigif::destroy $w.text.$file"	
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
		     
		     
    $w.text configure -state disabled
    
 #   bind $w <Leave> "wm state $w withdrawn"
#    bind $w <Enter> "bind $w <Leave> \"bind $w <Leave> \\\"wm state $w withdrawn\\\"\""
    bind $w <Enter> "bind $w <Leave> \"bind $w <Leave> \\\"destroy $w\\\"\""

#    wm state $w withdrawn

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
	
	return "[lindex $x $min] [lindex $y $min]"
    }

}



# Init smileys
load_smileys
