# ***********************************************************
#            Emilio's Additions to CCMSN/AMSN
#        Copyright (c)2002 Coralys Technologies,Inc.
#	           http://www.coralys.com/
# ***********************************************************
#
# $Id$
#

###################### Protocol Debugging ###########################
set degt_protocol_window_visible 0
set degt_command_window_visible 0

proc degt_Init {} {
    set Entry {bg #FFFFFF foreground #0000FF}
    set Label {bg #AABBCC foreground #000000}
    set Text {bg #2200FF foreground #111111}
    set Button {foreground #111111}
    set Frame {background #111111}
    ::themes::AddClass Degt Entry $Entry 90
    ::themes::AddClass Degt Label $Label 90
    ::themes::AddClass Degt Text $Text 90
    ::themes::AddClass Degt Button $Button 90
    ::themes::AddClass Degt Frame $Frame 90
}

proc degt_protocol { str } {
    .degt.mid.txt insert end "$str\n"
}

proc degt_protocol_win_toggle {} {
    global degt_protocol_window_visible

    if { $degt_protocol_window_visible } {
	wm state .degt withdraw
	set degt_protocol_window_visible 0
    } else {
	wm state .degt normal
	set degt_protocol_window_visible 1
    }
}

proc degt_protocol_win { } {
    toplevel .degt
    wm title .degt "MSN Protocol Debug"
    wm iconname .degt "MSNProt"
    wm state .degt withdraw

    frame .degt.top -class Degt
        label .degt.top.name -text "Protocol" -justify left
	pack .degt.top.name -side left -anchor w

    frame .degt.mid -class Degt
	text   .degt.mid.txt -height 20 -width 85 -font splainf \
		-wrap none -background white -foreground black \
	 	-yscrollcommand ".degt.mid.sy set" \
		-xscrollcommand ".degt.mid.sx set"
	scrollbar .degt.mid.sy -command ".degt.mid.txt yview"
	scrollbar .degt.mid.sx -orient horizontal -command ".degt.mid.txt xview"


	pack .degt.mid.sy -side right -fill y
	pack .degt.mid.sx -side bottom -fill x
	pack .degt.mid.txt -anchor nw

    frame .degt.bot -relief sunken -borderwidth 1 -class Degt
    	button .degt.bot.clear  -text "Clear" -font sboldf \
		-command ".degt.mid.txt delete 0.0 end"
    	button .degt.bot.close -text [trans close] -command degt_protocol_win_toggle -font sboldf
	pack .degt.bot.close .degt.bot.clear -side left

    pack .degt.top .degt.mid .degt.bot -side top

    bind . <Control-d> { degt_protocol_win_toggle }
    wm protocol .degt WM_DELETE_WINDOW { degt_protocol_win_toggle }
}

proc degt_ns_command_win_toggle {} {
    global degt_command_window_visible

    if { $degt_command_window_visible } {
	wm state .nscmd withdraw
	set degt_command_window_visible 0
    } else {
	wm state .nscmd normal
	set degt_command_window_visible 1
    }
}

# Ctrl-M to toggle raise/hide. This window is for developers only 
# to issue commands manually to the Notification Server
proc degt_ns_command_win {} {
    if {[winfo exists .nscmd]} {
        return
    }

    toplevel .nscmd
    wm title .nscmd "MSN Command"
    wm iconname .nscmd "MSNCmd"
    wm state .nscmd withdraw
    frame .nscmd.f -class Degt
    label .nscmd.f.l -text "NS Command:" -font bboldf 
    entry .nscmd.f.e -width 20
    pack .nscmd.f.l .nscmd.f.e -side left
    pack .nscmd.f

    bind .nscmd.f.e <Return> {
    	set cmd [string trim [.nscmd.f.e get]]
	if { [string length $cmd] > 0 } {
	    # There is actually a command typed. If %T found in
	    # the string replace it by a transaction ID
	    set nsclst [split $cmd]
	    set nscmd [lindex $nsclst 0]
	    set nspar [lreplace $nsclst 0 0]
	    if {[string range  $nscmd 0 0] == "!"} {
	    	debug_interpreter $nscmd $nspar
	    } else {
	        # Send command to the Notification Server
	        ::MSN::WriteNS $nscmd $nspar
	    }
	}
    }
    bind . <Control-m> { degt_ns_command_win_toggle }
    wm protocol .nscmd WM_DELETE_WINDOW { degt_ns_command_win_toggle }
}

proc debug_interpreter {cmd params} {
    switch $cmd {
	!sl { debug_cmd_lists -save }
	!Sl { debug_cmd_lists -gui }
    }
}

proc debug_cmd_lists {subcmd {basename ""}} {
    global tcl_platform HOME log_dir list_fl list_rl list_al list_bl

    set cmdVersion "1.0"
    # Forward Users List (those we have added to our buddy list)
    foreach user $list_fl {
        set ulogin [lindex $user 0]
	set allBuddies($ulogin) [list FL -- -- --]
    }
    # Reverse Users List (those who have added us, but we have not added them)
    foreach user $list_rl {
        set ulogin [lindex $user 0]
	if {![info exists allBuddies($ulogin)]} {
	    set allBuddies($ulogin) [list -- RL -- --]
	} else {
	    set allBuddies($ulogin) [lreplace $allBuddies($ulogin) 1 1 "RL"]
	}
    }
    # Allowed Users List (privacy: those allowed to contact us)
    foreach user $list_al {
        set ulogin [lindex $user 0]
	if {![info exists allBuddies($ulogin)]} {
	    set allBuddies($ulogin) [list -- -- AL --]
	} else {
	    set allBuddies($ulogin) [lreplace $allBuddies($ulogin) 2 2 "AL"]
	}
    }
    # Blocked Users List (privacy: those blocked from seeing us)
    foreach user $list_bl {
        set ulogin [lindex $user 0]
	if {![info exists allBuddies($ulogin)]} {
	    set allBuddies($ulogin) [list -- -- -- BL]
	} else {
	    set allBuddies($ulogin) [lreplace $allBuddies($ulogin) 3 3 "BL"]
	}
    }

    if {($subcmd == "-save") || ($subcmd == "-export")} {
	if {$basename == ""} { set basename "dbg-lists.txt"; }
	set save_dir $log_dir
	if {$subcmd == "-export"} { set save_dir $HOME; }
	set filepath [file join $save_dir $basename]
        if {$tcl_platform(platform) == "unix"} {
	    set file_id [open "$filepath.txt" w 00600]
	    set cttfile_id [open "$filepath.ctt" w 00600]
	} else {
	    set file_id [open "$filepath.txt" w]
	    set cttfile_id [open "$filepath.ctt" w]
	}
	set Date [clock format [clock seconds] -format %c]
	# This is for the enhanced (AMSN) contact list export
	puts $file_id "# AMSN-Contact-List version $cmdVersion"
	puts $file_id "# AMSN-Contact-List date $Date"
	puts $file_id "# AMSN-Contact-List info  FL(forward) RL(reverse) AL(allow) BL(block)"
	# This is for the crippled (MSN) contact list export, it is
	# compatible with Microsoft's MSN export/import functionality.
	puts $cttfile_id "<?xml version=\"1.0\"?>"
	puts $cttfile_id "<messenger>"
	puts $cttfile_id "  <service name=\".NET Messenger Service\">"
	puts $cttfile_id "    <contactlist>"
    }
    set user_entries [array get allBuddies]
    set items [llength $user_entries]
    for {set idx 0} {$idx < $items} {incr idx 1} {
        set vkey [lindex $user_entries $idx]; incr idx 1
	set gid [::abook::getGroup $vkey -id]
        set unick  [urlencode [::abook::getName $vkey]]
        if {($subcmd == "-save") || ($subcmd == "-export")} {
	    # This is for the enhanced (AMSN) contact list export
	    puts $file_id "$allBuddies($vkey) $vkey (gid $gid) $unick"
	    # This is for the crippled (MSN) contact list export
	    puts $cttfile_id "      <contact>$vkey</contact>"
	}
    }
    if {($subcmd == "-save") || ($subcmd == "-export")} {
        close $file_id
	# This is for the crippled (MSN) contact list export (XML format)
	puts $cttfile_id "    </contactlist>"
	puts $cttfile_id "  </service>"
	puts $cttfile_id "</messenger>"
        close $cttfile_id

	msg_box "$filepath\n$basename.ctt & $basename.txt"
    }
}

###################### Preferences Window ###########################
array set myconfig {}   ; # Cached configuration 
set proxy_server ""
set proxy_port ""

proc PreferencesCopyConfig {} {
    global config myconfig proxy_server proxy_port

    set config_entries [array get config]
    set items [llength $config_entries]
    for {set idx 0} {$idx < $items} {incr idx 1} {
        set var_attribute [lindex $config_entries $idx]; incr idx 1
	set var_value [lindex $config_entries $idx]
	# Copy into the cache for modification. We will only
	# copy back/save if the user chooses to accept new settings.
	set myconfig($var_attribute) $var_value
    }

    # Now process certain exceptions. Should be reverted
    # in the SavePreferences procedure
    set proxy_data [split $myconfig(proxy) ":"]
    set proxy_server [lindex $proxy_data 0]
    set proxy_port [lindex $proxy_data 1]
}

proc PreferencesMenu {m} {
    bind . <Control-p> { Preferences sound }

    $m add command -label [trans prefsound] -command "Preferences sound"
    $m add command -label [trans prefapps] -command "Preferences apps"
    $m add command -label [trans proxyconf] -command "Preferences proxy"
}

proc Preferences { settings } {
    global config myconfig proxy_server proxy_port

    if {[ winfo exists .cfg ]} {
        return
    }

    PreferencesCopyConfig	;# Load current configuration

    toplevel .cfg
    wm title .cfg [trans preferences]
    wm iconname .cfg [trans preferences]

    # Frame to hold the preferences tabs/notebook
    set nbtSounds [trans prefsound]
    set nbtApps   [trans prefapps]
    set nbtProxy  Proxy
    set nb .cfg.n
    frame .cfg.n -class Degt
	# Preferences Notebook
	pack [notebook $nb.p $nbtSounds $nbtApps $nbtProxy] \
		    -expand 1 -fill both -padx 1m -pady 1m
	#  .--------.
	# _| Sounds |________________________________________________
	set nbSounds [getNote $nb.p $nbtSounds]
	LabelEntry $nbSounds.play "[trans command]" myconfig(soundcommand) 20
	pack $nbSounds.play
        bind .cfg <Control-s> { pickNote $nb.p $nbtSounds }

	#  .--------------.
	# _| Applications |__________________________________________
	set nbApps   [getNote $nb.p $nbtApps]
	LabelEntry $nbApps.browser "[trans browser]" myconfig(browser) 20
	LabelEntry $nbApps.mailer "[trans mailer]" myconfig(mailcommand) 20
	label $nbApps.mailerhot -text "[trans leaveblankforhotmail]" -font splainf
	LabelEntry $nbApps.fileman "[trans filemanager]" myconfig(filemanager) 20
	pack $nbApps.browser $nbApps.mailer  $nbApps.mailerhot $nbApps.fileman -side top
        bind .cfg <Control-a> { pickNote $nb.p $nbtApps }

	#  .--------------.
	# _|   P r o x y  |__________________________________________
	set nbProxy [getNote $nb.p $nbtProxy]
	LabelEntry $nbProxy.server "[trans server]" proxy_server 20
	LabelEntry $nbProxy.port "[trans port]" proxy_port 5
	checkbutton $nbProxy.on -variable myconfig(withproxy) \
		-text "[trans enableproxy]"
	pack $nbProxy.server $nbProxy.port $nbProxy.on -side top
        bind .cfg <Control-p> { pickNote $nb.p $nbtProxy }

    # Frame for common buttons (all preferences)
    frame .cfg.b -class Degt
    	button .cfg.b.save -text [trans save] -command "SavePreferences; destroy .cfg"
    	button .cfg.b.cancel -text [trans close] -command "destroy .cfg" 
	pack .cfg.b.save .cfg.b.cancel -side left

    pack .cfg.n .cfg.b -side top

    switch $settings {
        sound { pickNote $nb.p $nbtSounds }
        apps  { pickNote $nb.p $nbtApps }
        proxy  { pickNote $nb.p $nbtProxy }
	default { return }
    }
}

proc SavePreferences {} {
    global config myconfig proxy_server proxy_port

    # I. Data Validation & Metavariable substitution
    # a) Proxy settings
    set p_server [string trim $proxy_server]
    set p_port [string trim $proxy_port]
    if { ($p_server != "") && ($p_port != "") } {
       set myconfig(proxy) [join [list $p_server $p_port] ":"]
    } else {
       set myconfig(proxy) ""
       set myconfig(withproxy) 0
    }

    # II. Copy back into current/active configuration. This
    #     means it will only be saved if user chose "Save".
    #	  Remember it is also saved during exit/cleanup
    set config_entries [array get myconfig]
    set items [llength $config_entries]
    for {set idx 0} {$idx < $items} {incr idx 1} {
        set var_attribute [lindex $config_entries $idx]; incr idx 1
	set var_value [lindex $config_entries $idx]
	set config($var_attribute) $var_value
#	puts "myCONFIG $var_attribute $var_value"
    }

    # Save configuration.
    save_config

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

     frame $w.buttons -class Degt
     pack $w.buttons -side bottom -fill x -pady 2m
      button $w.buttons.dismiss -text Cancel -command "destroy $w"
      button $w.buttons.save -text Save \
        -command "save_text_file $twn $w.filename.entry; destroy $w"
      pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

    frame $w.filename -bd 2 -class Degt
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
    if { "$file" != "" } {
	$ent delete 0 end
	$ent insert 0 $file
	$ent xview end
    }
}

# Usage: LabelEntry .mypath.mailer "Label:" config(mailcommand) 20
proc LabelEntry { path lbl value width } {
    upvar $value entvalue

    frame $path -class Degt
	label $path.lbl -text $lbl -justify left \
	    -font sboldf
	entry $path.ent -text $value -relief sunken \
	    -width $width -font splainf
	pack $path.lbl $path.ent -side left -anchor e -expand 1 -fill x
#	pack $path.ent $path.lbl -side right -anchor e -expand 1 -fill x
}

proc LabelEntryGet { path } {
    return [$path.ent get]
}

###################### ****************** ###########################
# $Log$
# Revision 1.17  2003/01/05 22:37:56  burgerman
# Save to File in loging implemented
#
# Revision 1.16  2002/12/16 02:42:52  airadier
# Some fixes.
# Syntax checking passed.
#
# Revision 1.15  2002/11/16 16:14:06  airadier
# Fixed colors (not visible under windows) in protocol debug window
#
# Revision 1.14  2002/09/30 12:45:36  lordofscripts
# - Now the contact list is saved in two formats:
#   contactlist.txt is our (AMSN) enhanced format with all the group info
#   contactlist.ctt is the Microsoft (MSN) format (XML) which only has the
#                   id (email address) but no group info. You have to
# 		  regroup yourself if you use that as import file
#
# Revision 1.13  2002/09/07 06:05:03  burgerman
# Cleaned up source files, removed all commented lines that seemed outdated or used for debugging (outputs)...
#
# Revision 1.12  2002/08/15 10:03:00  airadier
# Credits updated for the new banner.
# Adding file manager support (for opening received files)
#
# Revision 1.11  2002/07/09 23:31:12  lordofscripts
# - T-THEMES preparation for color themes
#
# Revision 1.10  2002/07/03 19:10:15  airadier
# Changes in colors (didn't look good on some systems)
#
# Revision 1.9  2002/07/01 00:50:31  airadier
# Proxy support in checkver, fixed a problem with proxy, if entered but "use proxy" not checked
#
# Revision 1.8  2002/07/01 00:06:55  airadier
# Translation
#
# Revision 1.7  2002/07/01 00:05:06  airadier
# Hotmail web mail used as mailer if field is left blank
#
# Revision 1.6  2002/06/27 19:17:00  lordofscripts
# -Added command interpreter for NSCommand Window (ctrl+m). The command
#  !sl dumps the contents of fl/rl/al/bl lists to a file in ~/.amsn/logs/
#  dbg-lists.txt. It is useful for testing validating some bugs
#
# Revision 1.5  2002/06/19 14:34:58  lordofscripts
# Added facility window (Ctrl+M) to enter commands to be issued to the
# Notification Server. Abook now allows to either show (read only)
# information about a buddy, or to publish (showEntry email -edit) the
# user's phone numbers so that other buddies can see them.
#
# Revision 1.4  2002/06/18 11:57:32  airadier
# Fixed bug when closing protocol_win not using the close button
#
# Revision 1.3  2002/06/15 20:38:13  lordofscripts
# Reworked preferences dialog using notebook megawidget
#
#
