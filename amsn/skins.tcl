#!/usr/bin/wish
#########################################################
# skins.tcl v 1.0	2003/07/01   KaKaRoTo
# New skin selector by Alberto (yozko) on 01/19/2004
#########################################################


proc GetSkinFile { type filename {skin_override ""} } {
    global HOME2 HOME

    if { [catch { set skin "[::config::getGlobalKey skin]" } ] != 0 } {
	set skin "default"
    }
    
    if { $skin_override != "" } {
    	set skin $skin_override
    }
    set defaultskin "default"


    if { "[string range $filename 0 1]" == "/" && [file readable  $filename] } {
	return "$filename"
    } elseif { [file readable [file join skins $skin $type $filename]] } {
	return "[file join skins $skin $type $filename]"
    } elseif { [file readable [file join $HOME2 skins $skin $type $filename]] } {
	return "[file join $HOME2 skins $skin $type $filename]"
    } elseif { [file readable [file join $HOME $type $filename]] } {
	return "[file join $HOME $type $filename]"
    } elseif { [file readable [file join skins $defaultskin $type $filename]] } {
	return "[file join skins $defaultskin $type $filename]"
    } else {
#	status_log "File [file join skins $skin $type $filename] not found!!!\n"
	return "[file join skins $defaultskin $type null]"
    }

}


proc skin_description {cstack cdata saved_data cattr saved_attr args} {
    global skin

    set skin(description) [string trim "$cdata"]
    return 0
}

proc findskins { } {
	global HOME2

	set skins [glob -directory skins */settings.xml]
	set skins_in_home [glob -nocomplain -directory [file join $HOME2 skins] */settings.xml]

	set skins [concat $skins $skins_in_home]


	set skinlist [list]

	foreach skin $skins {
		set dir [file dirname $skin]
		set desc ""

		if { [file readable [file join $dir desc.txt] ] } {
			set fd [open [file join $dir desc.txt]]
			set desc [string trim [read $fd]]
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

	if { [winfo exists $w] } {
		focus $w
		raise $w
		return
	}
	toplevel $w
#	wm geometry $w 450x250
	wm resizable $w 0 0
	wm title $w "[trans chooseskin]"

	label $w.choose -text "[trans chooseskin]" -font bboldf
	pack $w.choose -side top
    
	frame $w.main -relief solid -borderwidth 2
	frame $w.main.left -relief flat
	frame $w.main.right -relief flat
	frame $w.main.left.images -relief flat
	text $w.main.left.desc -height 6 -width 40 -relief flat -background $bgcolor2 -font sboldf -wrap word
	listbox $w.main.right.box -yscrollcommand "$w.main.right.ys set" -font splainf -background \
	white -relief flat -highlightthickness 0  -height 8 -width 30
	scrollbar $w.main.right.ys -command "$w.main.right.box yview" -highlightthickness 0 \
	-borderwidth 1 -elementborderwidth 2
    
	pack $w.main.left.images -in $w.main.left -side top -expand 0 -fill both
	pack $w.main.left.desc -in $w.main.left -side bottom -expand 1 -fill both
	pack $w.main.left -in $w.main -side left -expand 1 -fill both
	pack $w.main.right.ys -side right -fill both
	pack $w.main.right.box -side left -expand 0 -fill both
	pack $w.main.right -side right -expand 1 -fill both
	pack $w.main -expand 1 -fill both

	label $w.status -text ""
	pack $w.status -side bottom

	image create photo blank -width 1 -height 75
	label $w.main.left.images.blank -image blank

	image create photo blank2 -width 400 -height 1
	label $w.main.left.images.blank2 -image blank2

	set select -1
	set idx 0

	button $w.ok -text "[trans ok]" -command "selectskinok $w" -font sboldf
	button $w.cancel -text "[trans cancel]" -command "destroy $w" -font sboldf

	pack $w.ok  $w.cancel -side right -pady 5 -padx 5

	foreach skin [findskins] {
		if { [lindex $skin 0] == [::config::getGlobalKey skin] } { set select $idx } 
		$w.main.right.box insert end "[lindex $skin 0]"
		incr idx
	}

	if { $select == -1 } {
	    set select 0
	} 

    	status_log "select = $select --- [::config::getGlobalKey skin]\n"

        $w.main.right.box selection set $select
        $w.main.right.box itemconfigure $select -background #AAAAAA

	applychanges
	bind $w <Destroy> "grab release $w"
	bind $w.main.right.box <Button1-ButtonRelease> "applychanges"
   
}

proc applychanges { } {
	set w .skin_selector
	
	set the_skins [findskins]

	set currentskin [lindex [lindex $the_skins [$w.main.right.box curselection]] 0]
	set currentdesc [lindex [lindex $the_skins [$w.main.right.box curselection]] 1]

	clear_exampleimg
	
	# If our skin hasn't the example images, take them from the default one
	image create photo preview1 -file [GetSkinFile pixmaps prefpers.gif $currentskin]
	image create photo preview2 -file [GetSkinFile pixmaps bonline.gif $currentskin]		
	image create photo preview3 -file [GetSkinFile pixmaps offline.gif $currentskin]		
	image create photo preview4 -file [GetSkinFile pixmaps baway.gif $currentskin]		
	image create photo preview5 -file [GetSkinFile pixmaps amsnicon.gif $currentskin]
	image create photo preview6 -file [GetSkinFile pixmaps butblock.gif $currentskin]	
	image create photo preview7 -file [GetSkinFile pixmaps butsmile.gif $currentskin]
	image create photo preview8 -file [GetSkinFile pixmaps butsend.gif $currentskin]
	
	label $w.main.left.images.1 -image preview1
	label $w.main.left.images.2 -image preview2
	label $w.main.left.images.3 -image preview3
	label $w.main.left.images.4 -image preview4
	label $w.main.left.images.5 -image preview5
	label $w.main.left.images.6 -image preview6
	label $w.main.left.images.7 -image preview7
	label $w.main.left.images.8 -image preview8
	grid $w.main.left.images.1 -in $w.main.left.images -row 1 -column 1
	grid $w.main.left.images.2 -in $w.main.left.images -row 1 -column 2
	grid $w.main.left.images.3 -in $w.main.left.images -row 1 -column 3
	grid $w.main.left.images.4 -in $w.main.left.images -row 1 -column 4
	grid $w.main.left.images.5 -in $w.main.left.images -row 1 -column 5
	grid $w.main.left.images.6 -in $w.main.left.images -row 1 -column 6
	grid $w.main.left.images.7 -in $w.main.left.images -row 1 -column 7
	grid $w.main.left.images.8 -in $w.main.left.images -row 1 -column 8

	grid $w.main.left.images.blank -in $w.main.left.images -row 1 -column 10

	grid $w.main.left.images.blank2 -in $w.main.left.images -row 2 -column 1 -columnspan 8


	$w.main.left.desc configure -state normal
	$w.main.left.desc delete 0.0 end
	$w.main.left.desc insert end "[trans description]\n\n$currentdesc"
	$w.main.left.desc configure -state disabled

}

proc clear_exampleimg { } {
	if {[winfo exists .skin_selector.main.left.images]} {
		destroy .skin_selector.main.left.images.1
		destroy .skin_selector.main.left.images.2
		destroy .skin_selector.main.left.images.3
		destroy .skin_selector.main.left.images.4
		destroy .skin_selector.main.left.images.5
		destroy .skin_selector.main.left.images.6
		destroy .skin_selector.main.left.images.7
		destroy .skin_selector.main.left.images.8
		
		#frame .skin_selector.main.left.images -relief flat
		#pack .skin_selector.main.left.images -in .skin_selector.main.left -side top -expand 1 -fill both
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
	config::setGlobalKey skin $skin
	save_config
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


proc init_skindefaults { } {
    global skinconfig

    set skinconfig(smilew) 22      ;# Smiley width
    set skinconfig(smileh) 22      ;# Smiley height
}
