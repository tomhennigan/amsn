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


proc new_emoticon {cstack cdata saved_data cattr saved_attr args} {
    global emotions emotions_names
    upvar $saved_data sdata
    
    if { ! [info exists sdata(smileys:emoticon:name)] } { return 0 }
    if { ! [info exists sdata(smileys:emoticon:text)] } { return 0 }
    if { ! [info exists sdata(smileys:emoticon:file)] } { return 0 }

    set name [string trim $sdata(smileys:emoticon:name)]

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
	
set skin_id [sxml::init [file join $program_dir skins $skin settings.xml]]

sxml::register_routine $skin_id "smileys:emoticon" new_emoticon
sxml::parse $skin_id
sxml::end $skin_id

#source [file join $program_dir skins $skin smileys.tcl]

set smileys_drawn 0

#set sortedemotions [lsort -command compareSmileyLength $emotions]
    
set emotion_files [list]
    
foreach x [array names emotions_names] {
    lappend emotion_files $emotions(${x}_file)
}

    
foreach img_name $emotion_files {
    image create photo $img_name -file [file join ${smileys_folder} ${img_name}.gif]
}

proc valueforemot { emotion var } {
    global emotions

    set values_on_off "animated casesensitive"

    if { [lsearch $values_on_off $var] == -1 } {
	if { [info exists emotions(${emotion}_$var)] } {
	    return  $emotions(${emotion}_$var)
	} else { return "" }
	
    } else {
	if { [info exists emotions(${emotion}_${var})] } {
	    set var_   $emotions(${emotion}_${var})
	    if { $var_ == 1 || $var_ == "true" || $var_ == "yes"} {
		return 1
	    } else {
		return 0
	    }
	} else { return 0 }
    }
}

proc smile_subst {tw {start "0.0"} {enable_sound 0}} {
    global emotions emotions_names config smileys_folder smileys_drawn sounds_folder
    
  
    foreach emotion [lsort [array names emotions_names]] {
	
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

		#	  $tw tag configure hiden 
		#	  $tw tag add hiden $pos $endpos
		#	  $tw tag bind hiden <<Select>> "puts \"selected\""
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
		
	    }
	}
    }
}


proc smile_menu { {x 0} {y 0} {text text}} {
   global emotions emotions_names

   set w .smile_selector
   if {[catch {[toplevel $w]} res]} {
      destroy $w
      toplevel $w     
   }
   set x [expr {$x-10}]
   set y [expr {$y-10}]
   wm geometry $w [expr 23*10+8]x[expr 23*8+8]+$x+$y
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

	catch {
	    label $w.text.$file -image $file
	    $w.text.$file configure -cursor hand2 -borderwidth 1 -relief flat
	    
	    if { [string match {(%)} $symbol] != 0 } {
		bind $w.text.$file <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; destroy $w} res"
	    } else {
		bind $w.text.$file <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\;[list destroy $w]} res"     
	    }
	    

	    
	    bind $w.text.$file <Enter> "$w.text.$file configure -relief raised"
	    bind $w.text.$file <Leave> "$w.text.$file configure -relief flat"
	    $w.text window create end -window $w.text.$file -padx 1 -pady 1
	}
	
	
    }
		     
		     
    $w.text configure -state disabled
    
    bind $w <Leave> "destroy $w"
    bind $w <Enter> "bind $w <Leave> \"bind $w <Leave> \\\"destroy $w\\\"\""
    
}
