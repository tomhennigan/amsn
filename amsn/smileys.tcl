#
# $Id$
#


proc compareSmileyLength { a b {c ""}} {

  if { [string length [lindex $a 0]] > [string length [lindex $b 0]] } {
    return -1
  } elseif { [string length [lindex $a 0]] < [string length [lindex $b 0]] } {
    return 1
  } else {
    return 0
  }

}

proc is_true { data } {

    set value [string trim $data]
    if { $value == 1 || $value  == "true" || $value == "yes" || $value == "y" } {return 1} else {return 0}
}

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


    set emotions_names($name) ""

    foreach x [array names sdata] {
	set x2 [string trim [string map { "smileys:emoticon:" "" } $x]]
	if { $x2 == "name" } {continue}
	if { $x2 == "_dummy_" } {continue}

	set emotions(${name}_${x2}) [string trim $sdata($x)]

     }

    return 0
}

proc load_smileys { } {
    global emoticon_number program_dir skin smileys_drawn emotions emotions_names smileys_folder

    set emoticon_number 0

    if { [info exists emotions_names] } {unset emotions_names}
    if { [info exists emotions] } {unset emotions}

    set skin_id [sxml::init [file join $program_dir skins $skin settings.xml]]

    sxml::register_routine $skin_id "smileys:emoticon" new_emoticon
    sxml::parse $skin_id
    sxml::end $skin_id

    #source [file join $program_dir skins $skin smileys.tcl]

    if { ! [info exists smileys_drawn] } {
	set smileys_drawn 0
    }

    #set sortedemotions [lsort -command compareSmileyLength $emotions]
    
    set emotion_files [list]
    
    foreach x [array names emotions_names] {
	lappend emotion_files $emotions(${x}_file)
    }

    
    foreach img_name $emotion_files {
	image create photo $img_name -file [file join ${smileys_folder} ${img_name}.gif]
    }

    if { [winfo exists .smile_selector]} {destroy .smile_selector} 
}

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

proc smile_subst {tw {start "0.0"} {enable_sound 0}} {
    global emotions emotions_names config smileys_folder smileys_drawn sounds_folder
    
  
    foreach emotion [array names emotions_names] {
	
	set file $emotions(${emotion}_file)
	
	foreach symbol $emotions(${emotion}_text) {
	    set chars [string length $symbol]

#	    puts "$symbol"
	    set animated [valueforemot "$emotion" animated]
	    set sound [valueforemot "$emotion" sound]
	    if { [valueforemot "$emotion" casesensitive] } {set nocase "-exact"} else {set nocase "-nocase"}

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
		    set emoticon $tw.animsmiley$smileys_drawn
		    set smileys_drawn [expr $smileys_drawn + 1]		      
		    
		    label $emoticon -bd 0 -background [$tw cget -background]
		    ::anigif::anigif  [file join $smileys_folder ${file}.gif] $emoticon
		    
		    $tw window create $pos -window $emoticon       
		    bind $emoticon <Destroy> "::anigif::destroy $emoticon"		    
#		    puts "animated gif"
		} else {
		    	    
		    $tw image create $pos -image $file -pady 1 -padx 1
#		    puts "normal gif"
		}

		#         $tw insert [expr $pos] ":)" 	       
		# 	  $tw tag add elided_smiley [expr $pos]
		# 	  $tw tag configure elided_smiley -elide true
		
		if { $config(emotisounds) == 1 && $enable_sound == 1 && $sound != "" } {
		    catch {eval exec $config(soundcommand) [file join $sounds_folder ${sound}.wav] &} res
		}

#		break

		
	    }
	}
    }
}


proc smile_menu { {x 0} {y 0} {text text}} {
    global emotions_names emotions

    set w .smile_selector

    if { ! [winfo exists $w]} {
	create_smile_menu $x $y
    }

    set x [expr $x - 10]
    set y [expr $y - 10]

    wm geometry $w +$x+$y
    
    wm state $w normal

    foreach emotion [lsort [array names emotions_names]] {
	set symbol [lindex $emotions(${emotion}_text) 0]
	set file $emotions(${emotion}_file)

	catch { 
	    if { [string match {(%)} $symbol] != 0 } {
		bind $w.text.$file <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; wm state $w withdrawn} res"
	    } else {
		bind $w.text.$file <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\;[list wm state $w withdrawn]} res"     
	    }
	}
    }

}

proc create_smile_menu { {x 0} {y 0} } {
    global emotions emotions_names smileys_folder
    
    set w .smile_selector
    if {[catch {[toplevel $w]} res]} {
	destroy $w
	toplevel $w     
    }
    set x [expr $x - 10]
    set y [expr $y - 10]
    set x_geo [calcul_geometry_smileys "x"]
    set y_geo [calcul_geometry_smileys "y"]
    
    wm geometry $w [expr 23*${x_geo}+8]x[expr 23*${y_geo}+8]+$x+$y
    wm title $w "[trans msn]"
    wm overrideredirect $w 1
    wm transient $w
    wm state $w normal
   
    
    text $w.text -background white -borderwidth 2 -relief ridge \
       -selectbackground white -selectborderwidth 0 -exportselection 0
    
    pack $w.text

    $w.text configure -state normal
    
    
    foreach emotion [lsort [array names emotions_names]] {
	set symbol [lindex $emotions(${emotion}_text) 0]
	set file $emotions(${emotion}_file)
	set chars [string length $symbol]
	set hiden [valueforemot "$emotion" hiden]
	set animated [valueforemot "$emotion" animated]

	if { $hiden} {continue}

	catch {
 	    if { $animated } {
 		label $w.text.$file -background [$w.text cget -background]
  		::anigif::anigif  [file join $smileys_folder ${file}.gif] $w.text.$file
 		bind $w.text.$file <Destroy> "::anigif::destroy $w.text.$file"	
 	    } else {
		label $w.text.$file -image $file
	    }

	    $w.text.$file configure -cursor hand2 -borderwidth 1 -relief flat
	   
	    
	    bind $w.text.$file <Enter> "$w.text.$file configure -relief raised"
	    bind $w.text.$file <Leave> "$w.text.$file configure -relief flat"
	    $w.text window create end -window $w.text.$file -padx 1 -pady 1
	}
	
	
    }
		     
		     
    $w.text configure -state disabled
    
 #   bind $w <Leave> "wm state $w withdrawn"
    bind $w <Enter> "bind $w <Leave> \"bind $w <Leave> \\\"wm state $w withdrawn\\\"\""
    
    wm state $w withdrawn

}


proc calcul_geometry_smileys { direction } {
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
	
	if { $direction == "x" } {return [lindex $x $min] } else {return [lindex $y $min]}
    }

}


load_smileys