#!/usr/bin/wish
#########################################################
# skins.tcl v 1.0	2003/07/01   KaKaRoTo
#########################################################


proc GetSkinFile { type filename } {
    global program_dir env HOME

    if { [catch { set skin "[::config::get skin]" } ] != 0 } {
	set skin "default"
    }
    set defaultskin "default"


    if { [file readable [file join $program_dir skins $skin $type $filename]] } {
	return "[file join $program_dir skins $skin $type $filename]"
    } elseif { [file readable [file join $HOME skins $skin $type $filename]] } {
	return "[file join $HOME $type $filename]"
    } elseif { [file readable [file join $program_dir skins $defaultskin $type $filename]] } {
	return "[file join $program_dir skins $defaultskin $type $filename]"
    } else {
	return "[file join $program_dir skins $defaultskin $type null]"
    }

	 #Remove from this to the end
	 set pwd ""

    if { "[file normalize $filename]" == "$filename" && [file readable  $filename] } {
	return "$filename"
    } elseif { [file readable [file join $pwd $program_dir skins $skin $type $filename]] } {
	return "[file join $pwd $program_dir skins $skin $type $filename]"
    } elseif { [file readable [file join $HOME $type $filename]] } {
	return "[file join $pwd $HOME $type $filename]"
    } elseif { [file readable [file join $pwd $program_dir skins $defaultskin $type $filename]] } {
	return "[file join $pwd $program_dir skins $defaultskin $type $filename]"
    } else {
	puts "File [file join $pwd $program_dir skins $skin $type $filename] not found!!!"
	return "[file join $pwd $program_dir skins $defaultskin $type null]"
    }


}


proc skin_description {cstack cdata saved_data cattr saved_attr args} {
    global skin

    set skin(description) [string trim "$cdata"]
    return 0
}

proc findskins { } {
    variable program_dir

    set skins [glob -directory [file join $program_dir skins] */settings.xml]
    status_log "Found skin files in $skins\n"

    set skinlist [list]

    foreach skin $skins {
	set dir [file dirname $skin]

	set desc ""

	if { [file readable [file join $dir desc.txt] ] } {
	    set fd [open [file join $dir desc.txt]]
	    set desc [string trim [read $fd]]
	    status_log "$dir has description : $desc\n"
	    close $fd
	}

	set skinname [string map [list  "[file join $program_dir skins]/" "" ] $dir]
	lappend skinname $desc
	lappend skinlist $skinname
    }
    
    return $skinlist
}

proc SelectSkinGui { } {
    global config

    set w .skin_selector 
    toplevel $w
    wm geometry $w 500x300
    wm title $w "[trans chooseskin]"

    label $w.choose -text "[trans chooseskin]"
    pack $w.choose -side top
    
    frame $w.list -relief sunken -borderwidth 3
    text $w.list.label -height 1 -bd 0 -relief raised
    $w.list.label insert end "[trans skin]\t\t\t[trans description]" 
    $w.list.label configure -state disabled
    listbox $w.list.box -yscrollcommand "$w.list.ys set" -font splainf -background \
	white -relief flat -highlightthickness 0  -height 5
    scrollbar $w.list.ys -command "$w.list.box yview" -highlightthickness 0 \
	-borderwidth 1 -elementborderwidth 2
    pack $w.list.label $w.list.box -side top -expand false
    pack $w.list.ys -side right -fill y
    pack $w.list.box -side left -expand true -fill both
    pack $w.list.label -expand 0 -fill x
    pack $w.list -expand true -fill both

    label $w.status -text ""
    pack $w.status -side bottom

    set select -1
    set idx 0

    button $w.ok -text "[trans ok]" -command "selectskinok $w"
    button $w.cancel -text "[trans cancel]" -command "destroy $w"

    pack $w.ok $w.cancel -side right

    foreach skin [findskins] {
	if { [lindex $skin 0] == $config(skin) } { set select $idx } 
	$w.list.box insert end "[lindex $skin 0]            [lindex $skin 1]"
	incr idx
    }

    if { $select != -1 } {
	$w.list.box selection set $select
	$w.list.box itemconfigure $select -background #AAAAAA
    }

    bind $w <Destroy> "grab release $w"

    grab set $w
}


proc selectskinok { w } {
    global config

    if { [$w.list.box curselection] == "" } {
	$w.status configure -text "[trans selectskin]"
    }  else {
	
	$w.status configure -text ""

	set skinidx [$w.list.box curselection]
	
	set skin [lindex [lindex [findskins] $skinidx] 0]
	status_log "Chose skin No $skinidx : $skin\n"
	set config(skin) $skin

	msg_box [trans mustrestart]

	destroy $w
    }
}
