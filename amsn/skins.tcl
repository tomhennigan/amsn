#!/usr/bin/wish
#########################################################
# skins.tcl v 1.0	2003/07/01   KaKaRoTo
# New skin selector by Alberto (yozko) on 01/19/2004
#########################################################


proc GetSkinFile { type filename } {
    global program_dir HOME2 HOME

    if { [catch { set skin "[::config::get skin]" } ] != 0 } {
	set skin "default"
    }
    set defaultskin "default"


    if { "[string range $filename 0 1]" == "/" && [file readable  $filename] } {
	return "$filename"
    } elseif { [file readable [file join $program_dir skins $skin $type $filename]] } {
	return "[file join $program_dir skins $skin $type $filename]"
    } elseif { [file readable [file join $HOME2 skins $skin $type $filename]] } {
	return "[file join $HOME2 skins $skin $type $filename]"
    } elseif { [file readable [file join $HOME $type $filename]] } {
	return "[file join $HOME $type $filename]"
    } elseif { [file readable [file join $program_dir skins $defaultskin $type $filename]] } {
	return "[file join $program_dir skins $defaultskin $type $filename]"
    } else {
#	status_log "File [file join $program_dir skins $skin $type $filename] not found!!!\n"
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

	status_log "Loading skins from [file join $program_dir skins]\n"

	set skinlist [list]

	foreach skin $skins {
		set dir [file dirname $skin]
		status_log "Skin: $dir\n"
		set desc ""

		if { [file readable [file join $dir desc.txt] ] } {
			set fd [open [file join $dir desc.txt]]
			set desc [string trim [read $fd]]
			status_log "$dir has description : $desc\n"
			close $fd
		}

		set lastslash [expr {[string last "/" $dir]+1}]
		set skinname [string range $dir $lastslash end]
		lappend skinname $desc
		lappend skinlist $skinname
	}
    
	return $skinlist
}

proc SelectSkinGui { } {
	global config bgcolor2

	set w .skin_selector
	toplevel $w
	wm geometry $w 450x250
	wm resizable $w 0 0
	wm title $w "[trans chooseskin]"

	label $w.choose -text "[trans chooseskin]" -font bboldf
	pack $w.choose -side top
    
	frame $w.main -relief solid -borderwidth 2
	frame $w.main.left -relief flat
	frame $w.main.right -relief flat
	frame $w.main.left.images -relief flat
	text $w.main.left.desc -height 5 -width 40 -relief flat -background $bgcolor2 -font sboldf -wrap word
	listbox $w.main.right.box -yscrollcommand "$w.main.right.ys set" -font splainf -background \
	white -relief flat -highlightthickness 0  -height 5 -width 30
	scrollbar $w.main.right.ys -command "$w.main.right.box yview" -highlightthickness 0 \
	-borderwidth 1 -elementborderwidth 2
    
	pack $w.main.left.images -in $w.main.left -side top -expand 1 -fill both
	pack $w.main.left.desc -in $w.main.left -side bottom -expand 1 -fill both
	pack $w.main.left -in $w.main -side left -expand 1 -fill both
	pack $w.main.right.ys -side right -fill both
	pack $w.main.right.box -side left -expand 0 -fill both
	pack $w.main.right -side right -expand 1 -fill both
	pack $w.main -expand 1 -fill both

	label $w.status -text ""
	pack $w.status -side bottom

	set select -1
	set idx 0

	button $w.ok -text "[trans ok]" -command "selectskinok $w" -font sboldf
	button $w.cancel -text "[trans cancel]" -command "destroy $w" -font sboldf

	pack $w.ok $w.cancel -side right

	foreach skin [findskins] {
		if { [lindex $skin 0] == $config(skin) } { set select $idx } 
		$w.main.right.box insert end "[lindex $skin 0]"
		incr idx
	}

	if { $select != -1 } {
		$w.main.right.box selection set $select
		$w.main.right.box itemconfigure $select -background #AAAAAA
	}
	applychanges
	bind $w <Destroy> "grab release $w"
	bind $w.main.right.box <Button1-ButtonRelease> "applychanges"
   
}

proc applychanges { } {
	variable program_dir
	set w .skin_selector

	set currentskin [lindex [lindex [findskins] [$w.main.right.box curselection]] 0]
	set currentdesc [lindex [lindex [findskins] [$w.main.right.box curselection]] 1]

	clear_exampleimg
	
	# If our skin hasn't the example images, take them from the default one
	if { [file exists [file join $program_dir skins $currentskin "pixmaps/prefpers.gif"]] } {
		image create photo preview1 -file [file join $program_dir skins $currentskin "pixmaps/prefpers.gif"]
	} else {
		image create photo preview1 -file [file join $program_dir skins "default/pixmaps/prefpers.gif"]
	}
	if { [file exists [file join $program_dir skins $currentskin "pixmaps/butblock.gif"]] } {
		image create photo preview2 -file [file join $program_dir skins $currentskin "pixmaps/butblock.gif"]
	} else {
		image create photo preview2 -file [file join $program_dir skins "default/pixmaps/butblock.gif"]
	}
	if { [file exists [file join $program_dir skins $currentskin "pixmaps/amsnicon.gif"]] } {
		image create photo preview3 -file [file join $program_dir skins $currentskin "pixmaps/amsnicon.gif"]
	} else {
		image create photo preview3 -file [file join $program_dir skins "default/pixmaps/amsnicon.gif"]
	}
	if { [file exists [file join $program_dir skins $currentskin "pixmaps/butsmile.gif"]] } {
		image create photo preview4 -file [file join $program_dir skins $currentskin "pixmaps/butsmile.gif"]
	} else {
		image create photo preview4 -file [file join $program_dir skins "default/pixmaps/butsmile.gif"]
	}
	if { [file exists [file join $program_dir skins $currentskin "pixmaps/butsend.gif"]] } {
		image create photo preview5 -file [file join $program_dir skins $currentskin "pixmaps/butsend.gif"]
	} else {
		image create photo preview5 -file [file join $program_dir skins "default/pixmaps/butsend.gif"]
	}
	
	label $w.main.left.images.1 -image preview1
	label $w.main.left.images.2 -image preview2
	label $w.main.left.images.3 -image preview3
	label $w.main.left.images.4 -image preview4
	label $w.main.left.images.5 -image preview5
	grid $w.main.left.images.1 -in $w.main.left.images -row 1 -column 1
	grid $w.main.left.images.2 -in $w.main.left.images -row 1 -column 2
	grid $w.main.left.images.3 -in $w.main.left.images -row 1 -column 3
	grid $w.main.left.images.4 -in $w.main.left.images -row 1 -column 4
	grid $w.main.left.images.5 -in $w.main.left.images -row 1 -column 5
	$w.main.left.desc configure -state normal
	$w.main.left.desc delete 0.0 end
	$w.main.left.desc insert end "[trans description]\n\n$currentdesc"
	$w.main.left.desc configure -state disabled

}

proc clear_exampleimg { } {
	if {[winfo exists .skin_selector.main.left.images]} {
		destroy .skin_selector.main.left.images
		frame .skin_selector.main.left.images -relief flat
		pack .skin_selector.main.left.images -in .skin_selector.main.left -side top -expand 1 -fill both
	}
}

proc selectskinok { w } {
    global config

    if { [$w.main.right.box curselection] == "" } {
	$w.status configure -text "[trans selectskin]"
    }  else {
	
	$w.status configure -text ""

	set skinidx [$w.main.right.box curselection]
	
	set skin [lindex [lindex [findskins] $skinidx] 0]
	status_log "Chose skin No $skinidx : $skin\n"
	set config(skin) $skin

	msg_box [trans mustrestart]

	destroy $w
    }
}


proc SetBackgroundColors {cstack cdata saved_data cattr saved_attr args} {
    global bgcolor bgcolor2
    upvar $saved_data sdata
    
    if { [info exists sdata(${cstack}:background1)] } { set bgcolor [string trim $sdata(${cstack}:background1)] }
    if { [info exists sdata(${cstack}:background2)] } { set bgcolor2 [string trim $sdata(${cstack}:background2)] }

    return 0
}
