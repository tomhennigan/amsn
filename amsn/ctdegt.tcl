# ***********************************************************
#            Emilio's Additions to CCMSN/AMSN
#        Copyright (c)2002 Coralys Technologies,Inc.
#	           http://www.coralys.com/
#		      Revision 1.2.2
# ***********************************************************
#
# $Id$
#

###################### Protocol Debugging ###########################
proc degt_protocol { str } {
    .degt.mid.txt insert end "$str\n"
}

proc degt_protocol_win { } {
#    global debug_id
    toplevel .degt
    wm title .degt "MSN Protocol Debug"
    wm iconname .degt "MSNProt"
    wm state .degt withdraw

#   .notify.c insert $debug_id 0 $notify_text
#   set debug_id [.degt.c create text 75 50 -font {Helvetica 10} \ -justify center]
    frame .degt.top
        label .degt.top.name -text "Protocol" -justify left
#        label .degt.top.lines -textvariable lineCnt -justify right
	pack .degt.top.name -side left -anchor w
#	pack .degt.top.lines -side right  -anchor e -fill x

    frame .degt.mid
	scrollbar .degt.mid.sy -orient vertical -command ".degt.mid.txt yview"
	scrollbar .degt.mid.sx -orient horizontal -command ".degt.mid.txt xview"
	text   .degt.mid.txt -relief sunken -height 20 -width 85 -font fixed \
		-wrap none \
	 	-yscrollcommand ".degt.mid.sy set" \
		-xscrollcommand ".degt.mid.sx set"
	pack .degt.mid.sy -side right -fill y
	pack .degt.mid.sx -side bottom -fill x
	pack .degt.mid.txt -anchor nw

    frame .degt.bot -relief sunken -borderwidth 1
    	button .degt.bot.clear  -text "Clear" \
		-command ".degt.mid.txt delete 0.0 end"
    	button .degt.bot.close -text [trans close] -command "wm withdraw .degt"
	pack .degt.bot.close .degt.bot.clear -side left

    pack .degt.top .degt.mid .degt.bot -side top

    bind . <Control-d> { wm state .degt normal }
    bind . <Control-t> { wm state .degt withdraw }
}    
###################### Preferences Window ###########################
proc PreferencesMenu {m} {
    $m add command -label [trans prefsound] -command "Preferences sound"
    $m add command -label [trans prefapps] -command "Preferences apps"
}

proc Preferences { settings } {
    if [ winfo exists .config ] {
        return
    }

    toplevel .config
    wm title .config [trans preferences]
    wm iconname .config [trans preferences]
    wm geometry .config 200x300-1+0

    # Add a tab for each of the preference groups.
    # TODO: If too many then consider using a Menu
    set f .config.tabs
    frame $f -bd 1 -relief raised
	label $f.label -text "" -justify center
	pack $f.label -side top
        button $f.sound -text [trans prefsound] -command ConfigSound
        button $f.apps -text [trans prefapps] -command ConfigApps
	pack $f.sound $f.apps -side left -fill x

    frame .config.body -bd 1 -relief sunken
	ConfigWorkarea new

    frame .config.buttons -bd 1 -relief raised
	button .config.buttons.save -text [trans save] -command save_config 
	button .config.buttons.quit -text [trans close] -command "destroy .config"
	pack .config.buttons.save .config.buttons.quit -side left -fill x

    pack .config.tabs .config.body -side top
    pack .config.buttons -side bottom

    # Display the appropriate settings tab in the body frame
    # Add one case for each of the preference groups
    switch $settings {
        sound { ConfigSound }
        apps  { ConfigApps }
	default { return }
    }
}

# ConfigWorkarea		clear	empty	new
#	destroy container	yes	yes	no
#	create container	yes	yes	yes
#	populate with label	yes	no	yes
# TODO Make pack forget <Slave> does it
proc ConfigWorkarea {action} {
    # Remove all widgets in the current workarea
    if {([string compare $action "clear"] == 0) || 
        ([string compare $action "empty"] == 0)} {
        destroy .config.body.c
    }

    # Recreate with an empty area
    if {([string compare $action "clear"] == 0) ||
        ([string compare $action "empty"] == 0) ||
        ([string compare $action "new"] == 0)} {
	frame .config.body.c -relief raised
    }

    if {([string compare $action "clear"] == 0) || 
        ([string compare $action "new"] == 0)} {
	    # FIXME: If the height is too big in comparison with the
	    #        size of the config window, the lower (Close) frame
	    #        may not be visible!
	    label .config.body.c.l -text "Nothing selected" \
	    	-justify center -height 15 -width 30
	    pack .config.body.c.l
	pack .config.body.c
    }

    return .config.body.c
}

###################### Preferences:Sound  ###########################
proc ConfigSound {} {
    global config

    set f [ConfigWorkarea empty]

    set w $f.data
    frame $w -relief sunken
	label $w.title -text [trans prefsound] -justify center -fore red
	pack $w.title -side top
	label $w.slbl -text "Command:" -justify left -font sboldf
	entry $w.sent -text config(soundcommand) -relief sunken \
	    -width 20 -font splainf 
	pack $w.slbl $w.sent -side left
    set w $f.cmd
    frame $w
        button $w.ok -text [trans ok] \
		-command "ConfigSoundApply [$f.data.sent get]"
	button $w.cancel -text [trans cancel] -command "ConfigWorkarea clear"
	pack $w.ok $w.cancel -side left -fill x

    pack $f.data $f.cmd -side top
    pack $f
}

proc ConfigSoundApply {e} {
    global config

    ConfigWorkarea clear

    set config(soundcommand) $e
}
###################### Preferences:Applications #####################
proc ConfigApps {} {
    global config

    set f [ConfigWorkarea empty]

    frame $f.b -relief sunken -bd 1
	label $f.b.title -text [trans prefapps] -justify center -fore red
	pack $f.b.title -side top
    	label $f.b.l -text "Browser:" -justify left -font sboldf
	entry $f.b.e -text config(browser) -relief sunken \
	    -width 20 -font splainf 
        pack $f.b.l $f.b.e -side left 
    frame $f.m -relief sunken -bd 1
    	label $f.m.l -text "Mailer:" -justify left -font sboldf
	set mailer "$config(browser) http://www.hotmail.com"
	entry $f.m.e -text mailer -relief sunken \
	    -width 20 -font splainf 
        pack $f.m.l $f.m.e -side left 

    frame $f.x
        button $f.x.ok -text [trans ok] \
		-command "ConfigAppsApply $f"
	button $f.x.cancel -text [trans cancel] -command "ConfigWorkarea clear"
	pack $f.x.ok $f.x.cancel -side left -fill x

    pack $f.b $f.m $f.x -side top
    pack $f
}

proc ConfigAppsApply {e} {
    global config

    set browser [$e.b.e get]
    set mailer [$e.m.e get]
    ConfigWorkarea clear

    set config(browser) $browser
    set config(mailcommand) $mailer
}
###################### Other Features     ###########################
proc ChooseFilename { twn title } {
    puts $title

    # TODO File selection box, use nickname as filename (caller)
    set w .form$title
    toplevel $w
    wm title $w "Save chat session"
     label $w.msg -justify center -text "Please give a filename"
     pack $w.msg -side top

     frame $w.buttons
     pack $w.buttons -side bottom -fill x -pady 2m
      button $w.buttons.dismiss -text Cancel -command "destroy $w"
      button $w.buttons.save -text Save \
        -command "save_text_file $twn $w.filename.entry; destroy $w"
      pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

    frame $w.filename -bd 2
     entry $w.filename.entry -relief sunken -width 40 
     label $w.filename.label -text "Filename:"
     pack $w.filename.entry -side right
     pack $w.filename.label -side left
    pack $w.msg $w.filename -side top -fill x
    focus $w.filename.entry

    fileDialog $w $w.filename.entry save Untitled
}

proc save_text_file { w ent } {
    set content [ $w get 1.0 end ]
    set dstfile [ $ent get ]
    set f [ open $dstfile w ]
    puts $f $content
    close $f
    puts "Saved $dstfile"
    puts "Content $content"
}

proc fileDialog {w ent operation basename} {
    #   Type names		Extension(s)	Mac File Type(s)
    #
    #---------------------------------------------------------
    set types {
	{"Text files"		{.txt .doc}	}
	{"Text files"		{}		TEXT}
	{"Tcl Scripts"		{.tcl}		TEXT}
	{"C Source Files"	{.c .h}		}
	{"All Source Files"	{.tcl .c .h}	}
	{"Image Files"		{.gif}		}
	{"Image Files"		{.jpeg .jpg}	}
	{"Image Files"		""		{GIFF JPEG}}
	{"All files"		*}
    }
    if {$operation == "open"} {
	set file [tk_getOpenFile -filetypes $types -parent $w]
    } else {
	set file [tk_getSaveFile -filetypes $types -parent $w \
	    -initialfile $basename -defaultextension .txt]
    }
    if [string compare $file ""] {
	$ent delete 0 end
	$ent insert 0 $file
	$ent xview end
    }
}

###################### ****************** ###########################
