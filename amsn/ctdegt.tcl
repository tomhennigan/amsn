# ***********************************************************
#            Emilio's Additions to CCMSN/AMSN
#        Copyright (c)2002 Coralys Technologies,Inc.
#	           http://www.coralys.com/
# ***********************************************************
#
# $Id$
#

###################### Protocol Debugging ###########################
if { $initialize_amsn == 1 } {
    global degt_protocol_window_visible degt_command_window_visible

    set degt_protocol_window_visible 0
    set degt_command_window_visible 0
}

proc degt_Init {} {
    set Entry {bg #FFFFFF foreground #0000FF}
    set Label {bg #AABBCC foreground #000000}
    set Text {bg #2200FF foreground #111111 font splainf}
    set Button {foreground #111111}
#    set Frame {background #111111}
    ::themes::AddClass Degt Entry $Entry 90
    ::themes::AddClass Degt Label $Label 90
    ::themes::AddClass Degt Text $Text 90
    ::themes::AddClass Degt Button $Button 90
#    ::themes::AddClass Degt Frame $Frame 90
}

proc degt_protocol { str {colour ""}} {
    global followtext_degt

   .degt.mid.txt insert end "[timestamp] $str\n" $colour
    if { $followtext_degt == 1} {
	.degt.mid.txt yview moveto 1.0
    }
    
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
    global followtext_degt

    set followtext_degt 1

    toplevel .degt
    wm title .degt "MSN Protocol Debug"
    wm iconname .degt "MSNProt"
    wm state .degt withdraw

    frame .degt.top -class Degt
        label .degt.top.name -text "Protocol" -justify left
	pack .degt.top.name -side left -anchor w

    #font create debug -family Verdana -size 24 -weight bold
    frame .degt.mid -class Degt
	text   .degt.mid.txt -height 20 -width 85 -font splainf \
		-wrap none -background white -foreground black \
	 	-yscrollcommand ".degt.mid.sy set" \
		-xscrollcommand ".degt.mid.sx set"
	scrollbar .degt.mid.sy -command ".degt.mid.txt yview"
	scrollbar .degt.mid.sx -orient horizontal -command ".degt.mid.txt xview"

   .degt.mid.txt tag configure error -foreground #ff0000 -background white
   .degt.mid.txt tag configure nssend -foreground #888888 -background white
   .degt.mid.txt tag configure nsrecv -foreground #000000 -background white
   .degt.mid.txt tag configure sbsend -foreground #006666 -background white
   .degt.mid.txt tag configure sbrecv -foreground #000088 -background white
   .degt.mid.txt tag configure msgcontents -foreground #004400 -background white
   .degt.mid.txt tag configure red -foreground red -background white
   .degt.mid.txt tag configure white -foreground white -background black
   .degt.mid.txt tag configure blue -foreground blue -background white


	pack .degt.mid.sy -side right -fill y
	pack .degt.mid.sx -side bottom -fill x
	pack .degt.mid.txt -anchor nw  -expand true -fill both

    pack .degt.mid -expand true -fill both

    checkbutton .degt.follow -text "[trans followtext]" -onvalue 1 -offvalue 0 -variable followtext_degt

    frame .degt.bot -relief sunken -borderwidth 1 -class Degt
    button .degt.bot.save -text "[trans savetofile]" -command degt_protocol_save
    	button .degt.bot.clear  -text "Clear" -font sboldf \
		-command ".degt.mid.txt delete 0.0 end"
    	button .degt.bot.close -text [trans close] -command degt_protocol_win_toggle -font sboldf
	pack .degt.bot.save .degt.bot.close .degt.bot.clear -side left

    pack .degt.top .degt.mid .degt.follow .degt.bot -side top

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

proc degt_protocol_save { } {
    set w .protocol_save
	
    toplevel $w
    wm title $w \"[trans savetofile]\"
    label $w.msg -justify center -text "Please give a filename"
    pack $w.msg -side top
    
    frame $w.buttons -class Degt
    pack $w.buttons -side bottom -fill x -pady 2m
    button $w.buttons.dismiss -text Cancel -command "destroy $w"
    button $w.buttons.save -text Save -command "degt_protocol_save_file $w.filename.entry; destroy $w"
    pack $w.buttons.save $w.buttons.dismiss -side left -expand 1
    
    frame $w.filename -bd 2 -class Degt
    entry $w.filename.entry -relief sunken -width 40
    label $w.filename.label -text "Filename:"
    pack $w.filename.entry -side right 
    pack $w.filename.label -side left
    pack $w.msg $w.filename -side top -fill x
    focus $w.filename.entry
    
    fileDialog $w $w.filename.entry save "protocol_log.txt"
    grab $w

}

proc degt_protocol_save_file { filename } {

    set fd [open [${filename} get] a+]
    fconfigure $fd -encoding utf-8
    puts $fd "[.degt.mid.txt get 0.0 end]"
    close $fd


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
	        ::MSN::WriteSB ns $nscmd $nspar
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

if { $initialize_amsn == 1 } {
    global myconfig proxy_server proxy_port
    
    ###################### Preferences Window ###########################
    array set myconfig {}   ; # configuration backup
    set proxy_server ""
    set proxy_port ""
    
}

proc PreferencesCopyConfig {} {
    global config myconfig proxy_server proxy_port

    set config_entries [array get config]
    set items [llength $config_entries]
    for {set idx 0} {$idx < $items} {incr idx 1} {
        set var_attribute [lindex $config_entries $idx]; incr idx 1
	set var_value [lindex $config_entries $idx]
	# Copy into the cache for modification. We will
	# restore it if users chooses "close"
	set myconfig($var_attribute) $var_value
    }

    # Now process certain exceptions. Should be reverted
    # in the RestorePreferences procedure
    set proxy_data [split $myconfig(proxy) ":"]
    set proxy_server [lindex $proxy_data 0]
    set proxy_port [lindex $proxy_data 1]
}

proc PreferencesMenu {m} {
    bind . <Control-p> { Preferences sound }

    $m add command -label [trans personal] -command "Preferences personal"
    $m add command -label [trans appearance] -command "Preferences appearance"
    $m add command -label [trans session] -command "Preferences session"
    $m add command -label [trans loging] -command "Preferences loging"
    $m add command -label [trans connection] -command "Preferences connection"
    $m add command -label [trans prefapps] -command "Preferences apps"
    $m add command -label [trans profiles] -command "Preferences profiles"
}

proc Preferences { { settings "personal"} } {
    global config myconfig proxy_server proxy_port images_folder temp_BLP list_BLP Preftabs

    set temp_BLP $list_BLP

    if {[ winfo exists .cfg ]} {
        return
    }

    PreferencesCopyConfig	;# Load current configuration

    toplevel .cfg

    if { [LoginList exists 0 $config(login)] == 1 } {
	wm title .cfg "[trans preferences] - [trans profiledconfig] - $config(login)"
    } else {
	wm title .cfg "[trans preferences] - [trans defaultconfig] - $config(login)"
    }

    wm iconname .cfg [trans preferences]

    # Frame to hold the preferences tabs/notebook
    frame .cfg.notebook -class Degt
    pack .cfg.notebook -side top -fill both -expand 1 -padx 5 -pady 5

    # Frame for common buttons (all preferences)
    frame .cfg.buttons -class Degt
    button .cfg.buttons.save -text [trans save] -font sboldf -command "SavePreferences; destroy .cfg"
    button .cfg.buttons.cancel -text [trans close] -font sboldf -command "RestorePreferences; destroy .cfg"
    pack .cfg.buttons.save .cfg.buttons.cancel -side left -padx 10 -pady 5
    pack .cfg.buttons -side top -fill x

    set nb .cfg.notebook.nn

	# Preferences Notebook
	# Modified Rnotebook to translate automaticly those keys in -tabs {}
	Rnotebook:create $nb -tabs {personal appearance session privacy loging blocking connection prefapps profiles} -borderwidth 2
        set Preftabs(personal) 1
        set Preftabs(appearance) 2
        set Preftabs(session) 3
        set Preftabs(privacy) 4
        set Preftabs(loging) 5
        set Preftabs(blocking) 6
        set Preftabs(connection) 7
        set Preftabs(prefapps) 8
        set Preftabs(profiles) 9


	pack $nb -fill both -expand 1 -padx 10 -pady 10

	#  .----------.
	# _| Personal |________________________________________________
	image create photo prefpers -file [file join ${images_folder} prefpers.gif]
	image create photo prefprofile -file [file join ${images_folder} prefprofile.gif]
	image create photo preffont -file [file join ${images_folder} preffont.gif]
	image create photo prefphone -file [file join ${images_folder} prefphone.gif]
	set frm [Rnotebook:frame $nb $Preftabs(personal)]

	## Nickname Selection Entry Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans prefname] -font splainf]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	label $lfname.pname -image prefpers
	label $lfname.1.lname -text "[trans enternick] :" -font sboldf -padx 10
	entry $lfname.1.name -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 45
	checkbutton $lfname.2.badwords -text "[trans allowbadwords]" -onvalue 1 -offvalue 0 -variable config(allowbadwords)
	pack $lfname.pname -anchor nw -side left
	pack $lfname.1 -side top -padx 0 -pady 5 -expand 1 -fill both
	pack $lfname.2 -side top -padx 0 -pady 5 -expand 1 -fill both
	pack $lfname.1.lname $lfname.1.name -side left
	pack $lfname.2.badwords -side left -padx 15
	
	## Public Profile Frame ##
	set lfname [LabelFrame:create $frm.lfname2 -text [trans prefprofile]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.pprofile -image prefprofile
	label $lfname.lprofile -text [trans prefprofile2] -padx 10
	button $lfname.bprofile -text [trans editprofile] -font sboldf -command "" -state disabled
	pack $lfname.pprofile $lfname.lprofile -side left
	pack $lfname.bprofile -side right -padx 15

	## Chat Font Frame ##
	set lfname [LabelFrame:create $frm.lfname3 -text [trans preffont]]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.pfont -image preffont
	label $lfname.lfont -text [trans preffont2] -padx 10
	button $lfname.bfont -text [trans changefont] -font sboldf -command "change_myfont cfg"
	pack $lfname.pfont $lfname.lfont -side left
	pack $lfname.bfont -side right -padx 15

	## Phone Numbers Frame ##
	set lfname [LabelFrame:create $frm.lfname4 -text [trans prefphone]]
	pack $frm.lfname4 -anchor n -side top -expand 1 -fill x 
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	label $lfname.1.pphone -image prefphone
	pack $lfname.1.pphone -side left -anchor nw
	label $lfname.1.lphone -text [trans prefphone2] -padx 10
	pack $lfname.1.lphone -fill both -side left
	label $lfname.2.lphone1 -text "[trans countrycode] :" -padx 10 -font sboldf
	entry $lfname.2.ephone1 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 5
	label $lfname.2.lphone21 -text "[trans areacode]" -pady 5
	label $lfname.2.lphone22 -text "[trans phone]" -pady 5
	label $lfname.2.lphone3 -text "[trans myhomephone] :" -padx 10 -font sboldf
	entry $lfname.2.ephone31 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 5	
	entry $lfname.2.ephone32 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20
	label $lfname.2.lphone4 -text "[trans myworkphone] :" -padx 10 -font sboldf
	entry $lfname.2.ephone41 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 5	
	entry $lfname.2.ephone42 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20
	label $lfname.2.lphone5 -text "[trans mymobilephone] :" -padx 10 -font sboldf
	entry $lfname.2.ephone51 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 5	
	entry $lfname.2.ephone52 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20
	pack $lfname.1 -expand 1 -fill both -side top
	pack $lfname.2 -expand 1 -fill both -side top
	grid $lfname.2.lphone1 -row 1 -column 1 -sticky w -columnspan 2
	grid $lfname.2.ephone1 -row 1 -column 3 -sticky w
	grid $lfname.2.lphone21 -row 2 -column 2 -sticky e
	grid $lfname.2.lphone22 -row 2 -column 3 -sticky e
	grid $lfname.2.lphone3 -row 3 -column 1 -sticky w
	grid $lfname.2.ephone31 -row 3 -column 2 -sticky w
	grid $lfname.2.ephone32 -row 3 -column 3 -sticky w
	grid $lfname.2.lphone4 -row 4 -column 1 -sticky w
	grid $lfname.2.ephone41 -row 4 -column 2 -sticky w
	grid $lfname.2.ephone42 -row 4 -column 3 -sticky w
	grid $lfname.2.lphone5 -row 5 -column 1 -sticky w
	grid $lfname.2.ephone51 -row 5 -column 2 -sticky w
	grid $lfname.2.ephone52 -row 5 -column 3 -sticky w
		
	frame $frm.dummy -class Degt
	pack $frm.dummy -anchor n -side top -expand 1 -fill both -pady 150
	
	#  .------------.
	# _| Appearance |________________________________________________
	image create photo preflook -file [file join ${images_folder} preflook.gif]
	image create photo prefemotic -file [file join ${images_folder} prefemotic.gif]
	image create photo prefalerts -file [file join ${images_folder} prefalerts.gif]	

	set frm [Rnotebook:frame $nb $Preftabs(appearance)]
	
	## General aMSN Look Options (Encoding, BGcolor, General Font)
	set lfname [LabelFrame:create $frm.lfname -text [trans preflook]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.plook -image preflook
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	frame $lfname.3 -class Degt
	label $lfname.1.llook -text "[trans encoding2]" -padx 10
	button $lfname.1.bencoding -text [trans encoding] -font sboldf -command "show_encodingchoose"
	pack $lfname.plook -anchor nw -side left
	pack $lfname.1 -side top -padx 0 -pady 1 -expand 1 -fill both
	pack $lfname.1.llook -side left
	pack $lfname.1.bencoding -side right -padx 15
	label $lfname.2.llook -text "[trans bgcolor]" -padx 10
	button $lfname.2.bbgcolor -text [trans choosebgcolor] -font sboldf -command "choose_theme"
	pack $lfname.2 -side top -padx 0 -pady 1 -expand 1 -fill both
	pack $lfname.2.llook -side left	
	pack $lfname.2.bbgcolor -side right -padx 15
	label $lfname.3.llook -text "[trans preffont3]" -padx 10
	button $lfname.3.bfont -text [trans changefont] -font sboldf -command "choose_basefont"
	pack $lfname.3 -side top -padx 0 -pady 1 -expand 1 -fill both
	pack $lfname.3.llook -side left	
	pack $lfname.3.bfont -side right -padx 15
        checkbutton $lfname.tooltips -text "[trans tooltips]" -onvalue 1 -offvalue 0 -variable config(tooltips)
        pack $lfname.tooltips -side left -padx 10
    
	
	## Emoticons Frame ##
	set lfname [LabelFrame:create $frm.lfname2 -text [trans prefemotic]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.pemotic -image prefemotic
	pack $lfname.pemotic -side left -anchor nw
	frame $lfname.1 -class Degt
	pack $lfname.1 -side left -padx 0 -pady 5 -expand 1 -fill both
	checkbutton $lfname.1.chat -text "[trans chatsmileys2]" -onvalue 1 -offvalue 0 -variable config(chatsmileys)
	checkbutton $lfname.1.list -text "[trans listsmileys2]" -onvalue 1 -offvalue 0 -variable config(listsmileys)
        checkbutton $lfname.1.sound -text "[trans emotisounds]" -onvalue 1 -offvalue 0 -variable config(emotisounds)
        checkbutton $lfname.1.animated -text "[trans animatedsmileys]" -onvalue 1 -offvalue 0 -variable config(animatedsmileys)
	checkbutton $lfname.1.log -text "[trans logsmileys]" -onvalue 1 -offvalue 0 -variable config(logsmileys) -state disabled
	pack $lfname.1.chat $lfname.1.list $lfname.1.sound  $lfname.1.animated $lfname.1.log -anchor w -side top -padx 10

	## Alerts and Sounds Frame ##
	set lfname [LabelFrame:create $frm.lfname3 -text [trans prefalerts]]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.palerts -image prefalerts
	pack $lfname.palerts -side left -anchor nw
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	label $lfname.2.loffset -text "[trans notifyoffset]" -padx 10
	label $lfname.2.lxoffset -text "[trans xoffset] :" -font sboldf -padx 10
	entry $lfname.2.xoffset -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 5 -textvariable config(notifyXoffset)
	label $lfname.2.lyoffset -text "[trans yoffset] :" -font sboldf -padx 10
	entry $lfname.2.yoffset -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 5 -textvariable config(notifyYoffset)
	pack $lfname.2.loffset -side top -anchor w
	pack $lfname.2.lxoffset $lfname.2.xoffset $lfname.2.lyoffset $lfname.2.yoffset -side left -anchor w
	checkbutton $lfname.1.alert1 -text "[trans notify1]" -onvalue 1 -offvalue 0 -variable config(notifyonline)
	checkbutton $lfname.1.alert2 -text "[trans notify2]" -onvalue 1 -offvalue 0 -variable config(notifymsg)
	checkbutton $lfname.1.alert3 -text "[trans notify3]" -onvalue 1 -offvalue 0 -variable config(notifyemail)
	checkbutton $lfname.1.sound -text "[trans sound2]" -onvalue 1 -offvalue 0 -variable config(sound)
	pack $lfname.2 -anchor w -side top -padx 10 -expand 1 -fill both
	pack $lfname.1 -anchor w -side top -padx 0 -pady 5 -expand 1 -fill both
	pack $lfname.1.alert1 $lfname.1.alert2 $lfname.1.alert3 $lfname.1.sound -anchor w -side top -padx 10
	frame $frm.dummy -class Degt
	pack $frm.dummy -anchor n -side top -expand 1 -fill both -pady 150
	
	#  .---------.
	# _| Session |________________________________________________
	image create photo prefstatus -file [file join ${images_folder} prefstatus.gif]
	image create photo prefaway -file [file join ${images_folder} prefaway.gif]
	image create photo prefmsg -file [file join ${images_folder} prefmsg.gif]	

	set frm [Rnotebook:frame $nb $Preftabs(session)]
	
	## Sign In and AutoStatus Options Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans prefsession]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.psession -image prefstatus
	pack $lfname.psession -anchor nw -side left
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	frame $lfname.3 -class Degt
	checkbutton $lfname.1.lautonoact -text "[trans autonoact]" -onvalue 1 -offvalue 0 -variable config(autoidle) -command UpdatePreferences
	entry $lfname.1.eautonoact -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 3 -textvariable config(idletime)
	label $lfname.1.lmins -text "[trans mins]" -padx 5
	pack $lfname.1 -side top -padx 0 -expand 1 -fill both
	pack $lfname.1.lautonoact $lfname.1.eautonoact $lfname.1.lmins -side left
	checkbutton $lfname.2.lautoaway -text "[trans autoaway]" -onvalue 1 -offvalue 0 -variable config(autoaway) -command UpdatePreferences
	entry $lfname.2.eautoaway -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 3 -textvariable config(awaytime)
	label $lfname.2.lmins -text "[trans mins]" -padx 5
	pack $lfname.2 -side top -padx 0 -expand 1 -fill both
	pack $lfname.2.lautoaway $lfname.2.eautoaway $lfname.2.lmins -side left
	checkbutton $lfname.3.lonstart -text "[trans autoconnect2]" -onvalue 1 -offvalue 0 -variable config(autoconnect)
	checkbutton $lfname.3.lstrtoff -text "[trans startoffline2]" -onvalue 1 -offvalue 0 -variable config(startoffline)
	pack $lfname.3 -side top -padx 0 -expand 1 -fill both
	pack $lfname.3.lonstart $lfname.3.lstrtoff -anchor w -side top

	## Away Messages Frame ##
	set lfname [LabelFrame:create $frm.lfname2 -text [trans prefawaymsg]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.psession -image prefaway
	pack $lfname.psession -anchor nw -side left
	frame $lfname.statelist -relief sunken -borderwidth 3
	listbox $lfname.statelist.box -yscrollcommand "$lfname.statelist.ys set" -font splainf -background \
	white -relief flat -highlightthickness 0 -height 5
	scrollbar $lfname.statelist.ys -command "$lfname.statelist.box yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
	pack $lfname.statelist.ys -side right -fill y
	pack $lfname.statelist.box -side left -expand true -fill both
	frame $lfname.buttons -borderwidth 0
	button $lfname.buttons.add -text [trans addstate] -font sboldf -command "EditNewState 0" -width 20
	button $lfname.buttons.del -text [trans delete] -font sboldf -command "DeleteState \[$lfname.statelist.box curselection\]" -width 20
	button $lfname.buttons.edit -text [trans edit] -font sboldf -command "EditNewState 2 \[$lfname.statelist.box curselection\]" -width 20
	pack $lfname.buttons.add -side top
	pack $lfname.buttons.del -side top
	pack $lfname.buttons.edit -side top
	pack $lfname.statelist -anchor w -side left -padx 10 -pady 10 -expand 1 -fill both
	pack $lfname.buttons -anchor w -side right -padx 10 -pady 10 -expand 1 -fill both

	## Messaging Interface Frame ##
	set lfname [LabelFrame:create $frm.lfname3 -text [trans prefmsging]]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.pmsging -image prefmsg
	pack $lfname.pmsging -anchor nw -side left
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	frame $lfname.3 -class Degt
	
	label $lfname.1.lchatmaxmin -text [trans chatmaxmin] -padx 10
	radiobutton $lfname.1.max -text [trans raised] -value 0 -variable config(newchatwinstate)
	radiobutton $lfname.1.min -text [trans minimised] -value 1 -variable config(newchatwinstate)
	pack $lfname.1.lchatmaxmin -anchor w -side top -padx 10
	pack $lfname.1.max $lfname.1.min -side left -padx 10
		
	label $lfname.2.lmsgmaxmin -text [trans msgmaxmin] -padx 10
	radiobutton $lfname.2.max -text [trans raised] -value 0 -variable config(newmsgwinstate)
	radiobutton $lfname.2.min -text [trans minimised] -value 1 -variable config(newmsgwinstate)
	pack $lfname.2.lmsgmaxmin -anchor w -side top -padx 10
	pack $lfname.2.max $lfname.2.min -side left -padx 10
	
	label $lfname.3.lmsgmode -text [trans msgmode] -padx 10
	radiobutton $lfname.3.normal -text [trans normal] -value 1 -variable config(msgmode) -state disabled
	radiobutton $lfname.3.tabbed -text [trans tabbed] -value 2 -variable config(msgmode) -state disabled	
	pack $lfname.3.lmsgmode -anchor w -side top -padx 10 
	pack $lfname.3.normal $lfname.3.tabbed -side left -padx 10
	
	pack $lfname.1 $lfname.2 $lfname.3 -anchor w -side top -pady 5

	frame $frm.dummy -class Degt
	pack $frm.dummy -anchor n -side top -expand 1 -fill both -pady 150

	#  .--------.
	# _| Loging |________________________________________________
	image create photo prefhist -file [file join ${images_folder} prefhist.gif]
	image create photo prefhist2 -file [file join ${images_folder} prefhist2.gif]
	image create photo prefhist3 -file [file join ${images_folder} prefhist3.gif]

	set frm [Rnotebook:frame $nb $Preftabs(loging)]

	## Loging Options Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans preflog1]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.plog1 -image prefhist
	pack $lfname.plog1 -anchor nw -side left
	checkbutton $lfname.log -text "[trans keeplog2]" -onvalue 1 -offvalue 0 -variable config(keep_logs)
	pack $lfname.log -anchor w -side top
	frame $lfname.2 -class Degt
	label $lfname.2.lstyle -text "[trans stylelog]" -padx 10
	radiobutton $lfname.2.hist -text [trans stylechat] -value 1 -variable config(logstyle) -state disabled
	radiobutton $lfname.2.chat -text [trans stylehist] -value 2 -variable config(logstyle) -state disabled
	pack $lfname.2.lstyle -anchor w -side top -padx 10
	pack $lfname.2.hist $lfname.2.chat -side left -padx 10
	pack $lfname.2 -anchor w -side top -expand 1 -fill x
	
	## Clear All Logs Frame ##
	set lfname [LabelFrame:create $frm.lfname2 -text [trans clearlog]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.plog1 -image prefhist2
	pack $lfname.plog1 -anchor nw -side left
	frame $lfname.1 -class Degt
	label $lfname.1.lclear -text "[trans clearlog2]" -padx 10
	button $lfname.1.bclear -text [trans clearlog3] -font sboldf -command "::log::ClearAllLogs"
	pack $lfname.1.lclear -side left	
	pack $lfname.1.bclear -side right -padx 15
	pack $lfname.1 -anchor w -side top -expand 1 -fill x

	## Logs Expiry Frame ##
	set lfname [LabelFrame:create $frm.lfname3 -text [trans logfandexp]]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.plog1 -image prefhist3
	pack $lfname.plog1 -anchor nw -side left
	frame $lfname.1 -class Degt
	checkbutton $lfname.1.lolder -text "[trans logolder]" -onvalue 1 -offvalue 0 -variable config(logexpiry) -state disabled
	entry $lfname.1.eolder -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 3 -state disabled
	label $lfname.1.ldays -text "[trans days]" -padx 5
	pack $lfname.1 -side top -padx 0 -expand 1 -fill both
	pack $lfname.1.lolder $lfname.1.eolder $lfname.1.ldays -side left
	frame $lfname.2 -class Degt
	checkbutton $lfname.2.lbigger -text "[trans logbigger]" -onvalue 1 -offvalue 0 -variable config(logmaxsize) -state disabled
	entry $lfname.2.ebigger -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 3 -state disabled
	label $lfname.2.lmbs -text "MBs" -padx 5
	pack $lfname.2 -side top -padx 0 -expand 1 -fill both
	pack $lfname.2.lbigger $lfname.2.ebigger $lfname.2.lmbs -side left
	frame $frm.dummy -class Degt
	pack $frm.dummy -anchor n -side top -expand 1 -fill both -pady 150
	
	#  .------------.
	# _| Connection |________________________________________________
	image create photo prefnat -file [file join ${images_folder} prefnat.gif]
	image create photo prefproxy -file [file join ${images_folder} prefproxy.gif]	
	image create photo prefremote -file [file join ${images_folder} prefpers.gif]

	set frm [Rnotebook:frame $nb $Preftabs(connection)]
	
	## Connection Frame ##
	set lfname [LabelFrame:create $frm.lfnameconnection -text [trans prefconnection]]
	pack $frm.lfnameconnection -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image prefproxy
	pack $lfname.pshared -side left -anchor nw	
	
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	frame $lfname.3 -class Degt
	frame $lfname.4 -class Degt
	frame $lfname.5 -class Degt
	radiobutton $lfname.1.direct -text "[trans directconnection]" -value direct -variable config(connectiontype) -command UpdatePreferences
	pack $lfname.1.direct -anchor w -side top -padx 10
	radiobutton $lfname.2.http -text "[trans httpconnection]" -value http -variable config(connectiontype) -command UpdatePreferences
	pack $lfname.2.http -anchor w -side top -padx 10
	radiobutton $lfname.3.proxy -text "[trans proxyconnection]" -value proxy -variable config(connectiontype) -command UpdatePreferences
	pack $lfname.3.proxy -anchor w -side top -padx 10
	
	#checkbutton $lfname.1.proxy -text "[trans proxy]" -onvalue 1 -offvalue 0 -variable config(withproxy)
	#pack $lfname.1.proxy -anchor w -side top -padx 10
	
	#radiobutton $lfname.2.http -text "HTTP" -value http -variable config(proxytype)
	#radiobutton $lfname.2.socks5 -text "SOCKS5" -value socks -variable config(proxytype) -state disabled
	#pack $lfname.2.http $lfname.2.socks5 -anchor w -side left -padx 10
	
	pack $lfname.1 $lfname.2 $lfname.3 $lfname.4 $lfname.5 -anchor w -side top -padx 0 -pady 0 -expand 1 -fill both
	
	radiobutton $lfname.4.post -text "HTTP (POST method)" -value http -variable config(proxytype)
	radiobutton $lfname.4.ssl -text "SSL (CONNECT method)" -value ssl -variable config(proxytype)
	radiobutton $lfname.4.socks5 -text "SOCKS5" -value socks5 -variable config(proxytype) -state disabled
	
	grid $lfname.4.post -row 1 -column 1 -sticky w -pady 5 -padx 10
	grid $lfname.4.ssl -row 1 -column 2 -sticky w -pady 5 -padx 10
	grid $lfname.4.socks5 -row 1 -column 3 -sticky w -pady 5 -padx 10

		
	label $lfname.5.lserver -text "[trans server] :" -padx 5 -font sboldf
	entry $lfname.5.server -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20 -textvariable proxy_server
	label $lfname.5.lport -text "[trans port] :" -padx 5 -font sboldf
	entry $lfname.5.port -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 5 -textvariable proxy_port
	label $lfname.5.luser -text "[trans user] :" -padx 5 -font sboldf
	entry $lfname.5.user -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20
	label $lfname.5.lpass -text "[trans pass] :" -padx 5 -font sboldf
	entry $lfname.5.pass -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20 -show "*"
	grid $lfname.5.lserver -row 2 -column 1 -sticky e
	grid $lfname.5.server -row 2 -column 2 -sticky w -pady 5
	grid $lfname.5.lport -row 2 -column 3 -sticky e
	grid $lfname.5.port -row 2 -column 4 -sticky w -pady 5
	grid $lfname.5.luser -row 3 -column 1 -sticky e
	grid $lfname.5.user -row 3 -column 2 -sticky w
	grid $lfname.5.lpass -row 3 -column 3 -sticky e
	grid $lfname.5.pass -row 3 -column 4 -sticky w

	## NAT (or similar) Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans prefshared]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image prefnat
	pack $lfname.pshared -side left -anchor nw
	frame $lfname.1 -class Degt
	pack $lfname.1 -side left -padx 0 -pady 5 -expand 1 -fill both
	checkbutton $lfname.1.keepalive -text "[trans natkeepalive]" -onvalue 1 -offvalue 0 -variable config(keepalive)
	checkbutton $lfname.1.ip -text "[trans ipdetect]" -onvalue 1 -offvalue 0 -variable config(natip)
	
	frame $lfname.1.ftport -class Deft
	label $lfname.1.ftport.text -text "[trans ftportpref] :" -padx 5 -font splainf
	entry $lfname.1.ftport.entry -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 5 -textvariable config(initialftport)
	grid $lfname.1.ftport.text -row 1 -column 1 -sticky w -pady 5 -padx 0
	grid $lfname.1.ftport.entry -row 1 -column 2 -sticky w -pady 5 -padx 3
	
	pack $lfname.1.keepalive $lfname.1.ip $lfname.1.ftport -anchor w -side top -padx 10
	
	    
        ## Remote Control Frame ##
        set lfname [LabelFrame:create $frm.lfname3 -text [trans prefremote]]
        pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image prefremote
	pack $lfname.pshared -side left -anchor nw
	frame $lfname.1 -class Degt
        frame $lfname.2 -class Degt
	pack $lfname.1 -side left -padx 0 -pady 5 -expand 1 -fill both
	checkbutton $lfname.1.eremote -text "[trans enableremote]" -onvalue 1 -offvalue 0 -variable config(enableremote) -command UpdatePreferences
	pack $lfname.1.eremote  -anchor w -side top -padx 10
	pack $lfname.1 $lfname.2  -anchor w -side top -padx 0 -pady 0 -expand 1 -fill both
	label $lfname.2.lpass -text "[trans pass] :" -padx 5 -font sboldf
	entry $lfname.2.pass -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20 -show "*"
	grid $lfname.2.lpass -row 2 -column 3 -sticky e
	grid $lfname.2.pass -row 2 -column 4 -sticky w

	frame $frm.dummy -class Degt
	pack $frm.dummy -anchor n -side top -expand 1 -fill both -pady 150

	#  .--------------.
	# _| Applications |________________________________________________
	image create photo prefapps -file [file join ${images_folder} prefpers.gif]

	set frm [Rnotebook:frame $nb $Preftabs(prefapps)]
	
	## Applications Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans prefapps]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image prefapps
	pack $lfname.pshared -side left -anchor nw
	frame $lfname.1 -class Degt
	pack $lfname.1 -anchor w -side left -padx 0 -pady 5 -expand 1 -fill both
	label $lfname.1.lbrowser -text "[trans browser] :" -padx 5 -font sboldf
	entry $lfname.1.browser -bg #FFFFFF -bd 1 -highlightthickness 0 -width 20 -textvariable config(browser)
	label $lfname.1.lfileman -text "[trans fileman] :" -padx 5 -font sboldf
	entry $lfname.1.fileman -bg #FFFFFF -bd 1 -highlightthickness 0 -width 20 -textvariable config(filemanager)
	label $lfname.1.lmailer -text "[trans mailer] :" -padx 5 -font sboldf
	entry $lfname.1.mailer -bg #FFFFFF -bd 1 -highlightthickness 0 -width 20 -textvariable config(mailcommand)
	label $lfname.1.lhot -text "[trans leaveblankforhotmail]" -font examplef -padx 5 
	label $lfname.1.lsound -text "[trans soundserver] :" -padx 5 -font sboldf
	entry $lfname.1.sound -bg #FFFFFF -bd 1 -highlightthickness 0 -width 20 -textvariable config(soundcommand)
	label $lfname.1.sound2 -text "[trans soundcommand]" -font examplef -padx 5

	grid $lfname.1.lbrowser -row 1 -column 1 -sticky w
	grid $lfname.1.browser -row 1 -column 2 -sticky w
	grid $lfname.1.lfileman -row 2 -column 1 -sticky w
	grid $lfname.1.fileman -row 2 -column 2 -sticky w
	grid $lfname.1.lmailer -row 3 -column 1 -sticky w
	grid $lfname.1.mailer -row 3 -column 2 -sticky w
	grid $lfname.1.lhot -row 3 -column 3 -sticky w
	grid $lfname.1.lsound -row 4 -column 1 -sticky w
	grid $lfname.1.sound -row 4 -column 2 -sticky w
	grid $lfname.1.sound2 -row 4 -column 3 -sticky w

	frame $frm.dummy -class Degt
	pack $frm.dummy -anchor n -side top -expand 1 -fill both -pady 150

	#  .----------.
	# _| Profiles |________________________________________________
	image create photo prefapps -file [file join ${images_folder} prefpers.gif]
	
	## Delete Profiles Frame ##
	set frm [Rnotebook:frame $nb $Preftabs(profiles)]
	set lfname [LabelFrame:create $frm.lfname -text [trans prefprofile3]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.pprofile -image prefapps
	pack $lfname.pprofile -side left -anchor nw
	label $lfname.ldelprofile -text "[trans delprofile2]" -padx 5
	frame $lfname.1 -class Degt
	combobox::combobox $lfname.1.profile -editable true -highlightthickness 0 -width 25 -bg #FFFFFF -font splainf 
	button $lfname.1.bdel -text [trans delprofile] -font sboldf -command "DeleteProfile \[${lfname}.1.profile get\] $lfname.1.profile"
	pack $lfname.ldelprofile -anchor w -side top
	pack $lfname.1.profile -anchor w -side left -padx 10
	pack $lfname.1.bdel -anchor e -side left -padx 15
	pack $lfname.1 -anchor w -side top -expand 1 -fill x

	#  .----------.
	# _| Privacy |________________________________________________
	set frm [Rnotebook:frame $nb $Preftabs(privacy)]

         # Allow/Block lists
	set lfname [LabelFrame:create $frm.lfname -text [trans prefprivacy]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill both
	label $lfname.pprivacy -image prefapps
	pack $lfname.pprivacy -anchor nw -side left

	frame $lfname.allowlist -relief sunken -borderwidth 3
        label $lfname.allowlist.label -text "[trans allowlist]"
	listbox $lfname.allowlist.box -yscrollcommand "$lfname.allowlist.ys set" -font splainf -background \
	white -relief flat -highlightthickness 0  -height 5
	scrollbar $lfname.allowlist.ys -command "$lfname.allowlist.box yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
        pack $lfname.allowlist.label $lfname.allowlist.box -side top -expand false
	pack $lfname.allowlist.ys -side right -fill y
        pack $lfname.allowlist.box -side left -expand true -fill both
 

        frame $lfname.blocklist -relief sunken -borderwidth 3
        label $lfname.blocklist.label -text "[trans blocklist]"
	listbox $lfname.blocklist.box -yscrollcommand "$lfname.blocklist.ys set" -font splainf -background \
	white -relief flat -highlightthickness 0  -height 5
	scrollbar $lfname.blocklist.ys -command "$lfname.blocklist.box yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
        pack $lfname.blocklist.label $lfname.blocklist.box -side top -expand false
	pack $lfname.blocklist.ys -side right -fill y
	pack $lfname.blocklist.box -side left -expand true -fill both


	frame $lfname.buttons -borderwidth 0
	button $lfname.buttons.right -text "[trans move] -->" -font sboldf -command "Allow_to_Block $lfname" -width 10
	button $lfname.buttons.left -text "<-- [trans move]" -font sboldf -command "Block_to_Allow $lfname" -width 10
	pack $lfname.buttons.right $lfname.buttons.left  -side top
    
        label $lfname.status -text ""
	frame $lfname.allowframe
        radiobutton $lfname.allowframe.allowallbutbl -text "[trans allowallbutbl]" -value 1 -variable temp_BLP
	radiobutton $lfname.allowframe.allowonlyinal -text "[trans allowonlyinal]" -value 0 -variable temp_BLP
	grid $lfname.allowframe.allowallbutbl -row 1 -column 1 -sticky w 
	grid $lfname.allowframe.allowonlyinal -row 2 -column 1 -sticky w 
        pack $lfname.status $lfname.allowframe -side bottom -anchor w -fill x
	pack $lfname.allowlist $lfname.buttons $lfname.blocklist -anchor w -side left -padx 10 -pady 10 -expand 1 -fill both

        bind $lfname.allowlist.box <Button3-ButtonRelease> "create_users_list_popup $lfname \"allow\" %X %Y"
        bind $lfname.blocklist.box <Button3-ButtonRelease> "create_users_list_popup $lfname \"block\" %X %Y"
    

        # Contact/Reverse lists
	set lfname [LabelFrame:create $frm.lfname2 -text [trans prefprivacy2]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill both
	label $lfname.pprivacy -image prefapps
	pack $lfname.pprivacy -anchor nw -side left

	frame $lfname.contactlist -relief sunken -borderwidth 3
        label $lfname.contactlist.label -text "[trans contactlist]"
	listbox $lfname.contactlist.box -yscrollcommand "$lfname.contactlist.ys set" -font splainf -background \
	white -relief flat -highlightthickness 0 -height 5
	scrollbar $lfname.contactlist.ys -command "$lfname.contactlist.box yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
        pack $lfname.contactlist.label $lfname.contactlist.box -side top -expand false
	pack $lfname.contactlist.ys -side right -fill y
	pack $lfname.contactlist.box -side left -expand true -fill both
  
	frame $lfname.reverselist -relief sunken -borderwidth 3
        label $lfname.reverselist.label -text "[trans reverselist]"
	listbox $lfname.reverselist.box -yscrollcommand "$lfname.reverselist.ys set" -font splainf -background \
	white -relief flat -highlightthickness 0  -height 5
	scrollbar $lfname.reverselist.ys -command "$lfname.reverselist.box yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
        pack $lfname.reverselist.label $lfname.reverselist.box -side top -expand false
	pack $lfname.reverselist.ys -side right -fill y
	pack $lfname.reverselist.box -side left -expand true -fill both

        frame $lfname.adding
        entry $lfname.adding.enter
        button $lfname.adding.addal -text "[trans addto AL]" -command "Add_To_List $lfname AL"
        button $lfname.adding.addbl -text "[trans addto BL]" -command "Add_To_List $lfname BL"
        button $lfname.adding.addfl -text "[trans addto FL]" -command "Add_To_List $lfname FL" 
        pack $lfname.adding.addal $lfname.adding.addbl $lfname.adding.addfl -side left
        pack $lfname.adding.enter -side top


	frame $lfname.buttons -borderwidth 0
	button $lfname.buttons.right -text "[trans delete] -->" -font sboldf -command "Remove_Contact $lfname" -width 10
	button $lfname.buttons.left -text "<-- [trans copy]" -font sboldf -command "Reverse_to_Contact $lfname" -width 10
	pack $lfname.adding  $lfname.buttons.right $lfname.buttons.left -side top


 #       pack $lfname.addal $lfname.addbl $lfname.addfl -side left

 #    	grid $lfname.enter -row 3 -column 1 -sticky w 
 #	grid $lfname.addal -row 4 -column 1 -sticky w 
 #	grid $lfname.addbl -row 4 -column 2 -sticky w 
 #	grid $lfname.addfl -row 4 -column 3 -sticky w 

        label $lfname.status -text ""

        pack $lfname.status -side bottom  -anchor w  -fill x
	pack $lfname.contactlist $lfname.buttons $lfname.reverselist -anchor w -side left -padx 10 -pady 10 -expand 1 -fill both

        bind $lfname.contactlist.box <Button3-ButtonRelease> "create_users_list_popup $lfname \"contact\" %X %Y"
        bind $lfname.reverselist.box <Button3-ButtonRelease> "create_users_list_popup $lfname \"reverse\" %X %Y"

  

	#  .----------.
	# _| Blocking |________________________________________________
	set frm [Rnotebook:frame $nb $Preftabs(blocking)]
	
	## Check on disconnect ##
	set lfname [LabelFrame:create $frm.lfname -text [trans prefblock1]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.ppref1 -image prefapps
	pack $lfname.ppref1 -side left -padx 5 -pady 5 
	checkbutton $lfname.enable -text "[trans checkonfln]" -onvalue 1 -offvalue 0 -variable config(checkonfln)
	pack $lfname.enable  -anchor w -side left -padx 0 -pady 5 

	## Continuously check ##
	set lfname [LabelFrame:create $frm.lfname2 -text [trans prefblock2]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.ppref2 -image prefapps
	pack $lfname.ppref2 -side left -padx 5 -pady 5 

	frame $lfname.enable -class Degt
	pack $lfname.enable -anchor w -side left 
	checkbutton $lfname.enable.cb -text "[trans checkblocking]" -onvalue 1 -offvalue 0 -variable config(checkblocking) -command UpdatePreferences
	grid $lfname.enable.cb -row 1 -column 1 -sticky w

	frame $lfname.check -class Degt
	pack $lfname.check -anchor w -side left -padx 0 -pady 5 

        label $lfname.check.linter1 -text "[trans blockinter1]"
        label $lfname.check.linter2 -text "[trans blockinter2]"
        label $lfname.check.linter3 -text "[trans blockinter3]"
        label $lfname.check.lusers -text "[trans blockusers]"
        entry $lfname.check.inter1 -validate all -vcmd "BlockValidateEntry %W %P 1" -invcmd "BlockValidateEntry %W %P 0 15" -width 4 -textvariable config(blockinter1)
        entry $lfname.check.inter2 -validate all -vcmd "BlockValidateEntry %W %P 2" -invcmd "BlockValidateEntry %W %P 0 30"  -width 4 -textvariable config(blockinter2)
        entry $lfname.check.inter3 -validate all -vcmd "BlockValidateEntry %W %P 3" -invcmd "BlockValidateEntry %W %P 0 2" -width 4 -textvariable config(blockinter3)
        entry $lfname.check.users -validate all -vcmd "BlockValidateEntry %W %P 4" -invcmd "BlockValidateEntry %W %P 0 5" -width 4 -textvariable config(blockusers)

        grid $lfname.check.linter1 -row 1 -column 1 -sticky w
        grid $lfname.check.linter2 -row 1 -column 3 -sticky w
        grid $lfname.check.linter3 -row 2 -column 3 -sticky w
        grid $lfname.check.lusers -row 2 -column 1 -sticky w
        grid $lfname.check.inter1 -row 1 -column 2 -sticky w
        grid $lfname.check.inter2 -row 1 -column 4 -sticky w
        grid $lfname.check.inter3 -row 2 -column 4 -sticky w
        grid $lfname.check.users -row 2 -column 2 -sticky w

	pack $lfname.enable $lfname.check -anchor w -side top 

    setCfgFonts $nb splainf

    Rnotebook:totalwidth $nb

    InitPref
    UpdatePreferences

    wm geometry .cfg [expr [Rnotebook:totalwidth $nb] + 50]x595

    catch { Rnotebook:raise $nb $Preftabs($settings) }

#    switch $settings {
#         personal { Rnotebook:raise $nb 1 }
# 	appearance { Rnotebook:raise $nb 2 }
#         session { Rnotebook:raise $nb 3 }
#         loging { Rnotebook:raise $nb 4 }
# 	connection { Rnotebook:raise $nb 5 }
#         apps { Rnotebook:raise $nb 6 }
#         profiles { Rnotebook:raise $nb 7 }
# 	privacy { Rnotebook:raise $nb 8 }
# 	default { return }
#     }
    
    bind .cfg <Destroy> "RestorePreferences"

    #tkwait visibility .cfg
    #grab set .cfg
}

# This is where we fill in the Entries of the Preferences
proc InitPref {} {
	global user_stat user_info config Preftabs
	set nb .cfg.notebook.nn

	# Insert nickname if online, disable if offline
	set lfname [Rnotebook:frame $nb $Preftabs(personal)]
	if { $user_stat == "FLN" } {
		$lfname.lfname.f.f.1.name configure -state disabled
	} else {
		$lfname.lfname.f.f.1.name configure -state normal
		$lfname.lfname.f.f.1.name delete 0 end
		$lfname.lfname.f.f.1.name insert 0 [urldecode [lindex $user_info 4]]
	}

	# Get My Phone numbers and insert them
	set lfname "$lfname.lfname4.f.f"
	if { $user_stat == "FLN" } {
		$lfname.2.ephone1 configure -state disabled
		$lfname.2.ephone31 configure -state disabled
		$lfname.2.ephone32 configure -state disabled
		$lfname.2.ephone41 configure -state disabled
		$lfname.2.ephone42 configure -state disabled
		$lfname.2.ephone51 configure -state disabled
		$lfname.2.ephone52 configure -state disabled
	} else {
		$lfname.2.ephone1 configure -state normal
		$lfname.2.ephone31 configure -state normal
		$lfname.2.ephone32 configure -state normal
		$lfname.2.ephone41 configure -state normal
		$lfname.2.ephone42 configure -state normal
		$lfname.2.ephone51 configure -state normal
		$lfname.2.ephone52 configure -state normal
		$lfname.2.ephone1 delete 0 end
		$lfname.2.ephone31 delete 0 end
		$lfname.2.ephone32 delete 0 end
		$lfname.2.ephone41 delete 0 end
		$lfname.2.ephone42 delete 0 end
		$lfname.2.ephone51 delete 0 end
		$lfname.2.ephone52 delete 0 end
		::abook::getPersonal phones
		$lfname.2.ephone1 insert 0 [lindex [split $phones(phh) " "] 0]
		$lfname.2.ephone31 insert 0 [lindex [split $phones(phh) " "] 1]
		$lfname.2.ephone32 insert 0 [join [lrange [split $phones(phh) " "] 2 end]]
		$lfname.2.ephone41 insert 0 [lindex [split $phones(phw) " "] 1]
		$lfname.2.ephone42 insert 0 [join [lrange [split $phones(phw) " "] 2 end]]
		$lfname.2.ephone51 insert 0 [lindex [split $phones(phm) " "] 1]
		$lfname.2.ephone52 insert 0 [join [lrange [split $phones(phm) " "] 2 end]]
	}

	# Lets fill our profile combobox
	set lfname [Rnotebook:frame $nb $Preftabs(profiles)]
	set lfname "$lfname.lfname.f.f"
   	set idx 0
   	set tmp_list ""
	$lfname.1.profile list delete 0 end
   	while { [LoginList get $idx] != 0 } {
		lappend tmp_list [LoginList get $idx]
		incr idx
	}
   	eval $lfname.1.profile list insert end $tmp_list
	$lfname.1.profile insert 0 [lindex $tmp_list 0]
   	unset idx
   	unset tmp_list
	$lfname.1.profile configure -editable false

	# Lets disable loging if on default profile
	if { [LoginList exists 0 $config(login)] == 0 } {
		set lfname [Rnotebook:frame $nb $Preftabs(loging)]
		set lfname "$lfname.lfname.f.f"
		$lfname.log configure -state disabled
	}

	# Let's fill our list of States
	set lfname [Rnotebook:frame $nb $Preftabs(session)]
	$lfname.lfname2.f.f.statelist.box delete 0 end
	for { set idx 0 } { $idx < [StateList size] } {incr idx } {
		$lfname.lfname2.f.f.statelist.box insert end [lindex [StateList get $idx] 0]
	}

        # Fill the user's lists
        set lfname [Rnotebook:frame $nb $Preftabs(privacy)]
        Fill_users_list "$lfname.lfname.f.f" "$lfname.lfname2.f.f"


        # Init remote preferences
        set lfname [Rnotebook:frame $nb $Preftabs(connection)]
        $lfname.lfname3.f.f.2.pass delete 0 end
        $lfname.lfname3.f.f.2.pass insert 0 "$config(remotepassword)"

}


# This is where the preferences entries get enabled disabled
proc UpdatePreferences {} {
	global config Preftabs
	
	set nb .cfg.notebook.nn
	
	# autoaway checkbuttons and entries
	set lfname [Rnotebook:frame $nb $Preftabs(session)]
	set lfname "${lfname}.lfname.f.f"
	if { $config(autoidle) == 0 } {
		$lfname.1.eautonoact configure -state disabled
	} else {
		$lfname.1.eautonoact configure -state normal
	}
	if { $config(autoaway) == 0 } {
		$lfname.2.eautoaway configure -state disabled
	} else {
		$lfname.2.eautoaway configure -state normal
	}

	# proxy connection entries and checkbuttons
	set lfname [Rnotebook:frame $nb $Preftabs(connection)]
	set lfname "${lfname}.lfnameconnection.f.f"
	if { $config(connectiontype) == "proxy" } {
		$lfname.4.post configure -state normal
		$lfname.4.ssl configure -state normal
		$lfname.4.socks5 configure -state normal
		$lfname.5.server configure -state normal
		$lfname.5.port configure -state normal
		$lfname.5.user configure -state normal
		$lfname.5.pass configure -state normal
	} else {
		$lfname.4.post configure -state disabled
		$lfname.4.ssl configure -state disabled
		$lfname.4.socks5 configure -state disabled
		$lfname.5.server configure -state disabled
		$lfname.5.port configure -state disabled
		$lfname.5.user configure -state disabled
		$lfname.5.pass configure -state disabled
	}

	# remote control
	set lfname [Rnotebook:frame $nb $Preftabs(connection)]
	set lfname "${lfname}.lfname3.f.f"
	if { $config(enableremote) == 1 } {
		$lfname.2.pass configure -state normal
	} else {
		$lfname.2.pass configure -state disabled
	}


	# blocking
 	set lfname [Rnotebook:frame $nb $Preftabs(blocking)]
 	set lfname "${lfname}.lfname2.f.f"
 	if { $config(checkblocking) == 1 } {
 		$lfname.check.inter1 configure -state normal
 		$lfname.check.inter2 configure -state normal
 		$lfname.check.inter3 configure -state normal
 		$lfname.check.users configure -state normal

 	} else {
 		$lfname.check.inter1 configure -state disabled
 		$lfname.check.inter2 configure -state disabled
 		$lfname.check.inter3 configure -state disabled
 		$lfname.check.users configure -state disabled

 	}

}
	

# This function sets all fonts to plain instead of bold,
# excluding the ones that are set to sboldf or examplef
proc setCfgFonts {path value} {
	catch {set res [$path cget -font]}
	if { [info exists res] } {
	        if { $res != "sboldf" && $res != "examplef" } {
		    catch { $path config -font $value }
        	}
	}
        foreach child [winfo children $path] {
            setCfgFonts $child $value
        }
}



proc SavePreferences {} {
    global config myconfig proxy_server proxy_port user_info user_stat list_BLP temp_BLP Preftabs 

    set nb .cfg.notebook.nn

    # I. Data Validation & Metavariable substitution
    # Proxy settings
    set p_server [string trim $proxy_server]
    set p_port [string trim $proxy_port]
    if { ($p_server != "") && ($p_port != "") && [string is digit $proxy_port] } {
       set config(proxy) [join [list $p_server $p_port] ":"]
    } else {
       #Let's just show the connect error
       set config(proxy) [join [list $p_server $p_port] ":"]
       #set config(proxy) ""
       #set config(withproxy) 0
    }

    # Make sure entries x and y offsets and idle time are digits, if not revert to old values
    if { [string is digit $config(notifyXoffset)] == 0 } {
    	set config(notifyXoffset) $myconfig(notifyXoffset)
    }
    if { [string is digit $config(notifyYoffset)] == 0 } {
    	set config(notifyYoffset) $myconfig(notifyYoffset)
    }
    if { [string is digit $config(idletime)] == 0 } {
    	set config(idletime) $myconfig(idletime)
    }
    if { [string is digit $config(awaytime)] == 0 } {
    	set config(awaytime) $myconfig(awaytime)
    }
    if { $config(idletime) >= $config(awaytime) } {
    	set config(awaytime) $myconfig(awaytime)
    	set config(idletime) $myconfig(idletime)
    }

    # Check and save phone numbers
    if { $user_stat != "FLN" } {
	    set lfname [Rnotebook:frame $nb $Preftabs(personal)]
	    set lfname "$lfname.lfname4.f.f"
 	   ::abook::getPersonal phones

	    set cntrycode [$lfname.2.ephone1 get]
	    if { [string is digit $cntrycode] == 0 } {
	    	set cntrycode [lindex [split $phones(phh) " "] 0]
	    }

	    append home [$lfname.2.ephone31 get] " " [$lfname.2.ephone32 get]
	    if { [string is digit [$lfname.2.ephone31 get]] == 0 } {
	    	set home [join [lrange [split $phones(phh) " "] 1 end]]
	    }
	    append work [$lfname.2.ephone41 get] " " [$lfname.2.ephone42 get]
	    if { [string is digit [$lfname.2.ephone41 get]] == 0 } {
	 	set work [join [lrange [split $phones(phw) " "] 1 end]]
	    }
	    append mobile [$lfname.2.ephone51 get] " " [$lfname.2.ephone52 get]
	    if { [string is digit [$lfname.2.ephone51 get]] == 0 } {
	  	set mobile [join [lrange [split $phones(phm) " "] 1 end]]
	    }

	    set home [urlencode [set home "$cntrycode $home"]]
	    set work [urlencode [set work "$cntrycode $work"]]
	    set mobile [urlencode [set mobile "$cntrycode $mobile"]]
	    if { $home != $phones(phh) } {
		::abook::setPhone home $home
	    }
	    if { $work != $phones(phw) } {
		::abook::setPhone work $work
	    }
	    if { $work != $phones(phm) } {
		::abook::setPhone mobile $mobile
	    }
	    if { $home != $phones(phh) || $work != $phones(phw) || $work != $phones(phm) } {
		::abook::setPhone pager N
	    }
    }

    # Change name
    set lfname [Rnotebook:frame $nb $Preftabs(personal)]
    set lfname "$lfname.lfname.f.f.1"
    set new_name [$lfname.name get]
    if {$new_name != "" && $new_name != [urldecode [lindex $user_info 4]] && $user_stat != "FLN"} {
	::MSN::changeName $config(login) $new_name
    }

    # Restore old configuration as if nothing happened
    set config_entries [array get config]
    set items [llength $config_entries]
    for {set idx 0} {$idx < $items} {incr idx 1} {
        set var_attribute [lindex $config_entries $idx]; incr idx 1
	set var_value [lindex $config_entries $idx]
	set myconfig($var_attribute) $var_value
#	puts "myCONFIG $var_attribute $var_value"
    }

    # Get remote controlling preferences
    set lfname [Rnotebook:frame $nb $Preftabs(connection)]
    set myconfig(remotepassword) "[$lfname.lfname3.f.f.2.pass get]"
    set config(remotepassword) "$myconfig(remotepassword)"


    # Save configuration of the BLP ( Allow all other users to see me online )
    if { $list_BLP != $temp_BLP } {
	AllowAllUsers $temp_BLP
    }

    # Blocking
    if { $config(blockusers) == "" } { set config(blockusers) 1}
    if { $config(checkblocking) == 1 } {
	BeginVerifyBlocked $config(blockinter1) $config(blockinter2) $config(blockusers) $config(blockinter3)
    } else {
	StopVerifyBlocked
    }


    # Save configuration.
    save_config

    if { $user_stat != "FLN" } {
       cmsn_draw_online
    }

}

proc RestorePreferences {} {
    global config myconfig proxy_server proxy_port user_info user_stat

    set nb .cfg.notebook.nn


    # Restore old configuration as if nothing happened
    set config_entries [array get myconfig]
    set items [llength $config_entries]
    for {set idx 0} {$idx < $items} {incr idx 1} {
        set var_attribute [lindex $config_entries $idx]; incr idx 1
	set var_value [lindex $config_entries $idx]
	set config($var_attribute) $var_value
#	puts "myCONFIG $var_attribute $var_value"
    }

#    ::MSN::WriteSB ns "SYN" "0"

    # Save configuration.
    #save_config

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

#/////////////////////////////////////////////////////////////
# A Labeled Frame widget for Tcl/Tk
# $Revision$
#
# Copyright (C) 1998 D. Richard Hipp
#
# Author contact information:
#   drh@acm.org
#   http://www.hwaci.com/drh/
proc LabelFrame:create {w args} {
  frame $w -bd 0
  label $w.l
  frame $w.f -bd 2 -relief groove
  frame $w.f.f
  pack $w.f.f
  set text {}
  set font {}
  set padx 3
  set pady 7
  set ipadx 2
  set ipady 9
  foreach {tag value} $args {
    switch -- $tag {
      -font  {set font $value}
      -text  {set text $value}
      -padx  {set padx $value}
      -pady  {set pady $value}
      -ipadx {set ipadx $value}
      -ipady {set ipady $value}
      -bd     {$w.f config -bd $value}
      -relief {$w.f config -relief $value}
    }
  }
  if {"$font"!=""} {
    $w.l config -font $font
  }
  $w.l config -text $text
  pack $w.f -padx $padx -pady $pady -fill both -expand 1
  place $w.l -x [expr $padx+10] -y $pady -anchor w
  pack $w.f.f -padx $ipadx -pady $ipady -fill both -expand 1
  raise $w.l
  return $w.f.f
}



proc BlockValidateEntry { widget data type {correct 0} } {

    switch  $type  {
	0 {
	    if { [string is integer  $data] } {
		global config
		$widget delete 0 end
		$widget insert 0 "$correct" 
		after idle "$widget config -validate all"
	    }    
	}
	1 {
	    if { [string is integer  $data] } {
		if { $data < 15 } {
		    return 0
		}
		return 1
	    } else {return 0}
	}
	2 {    
	    if { [string is integer $data] } {
		if { $data < 30 } {
		    return 0
		}
		return 1
	    } else {return 0}
	}
	3 {    
	    if { [string is integer   $data] } {
		if { $data < 2 } {
		    return 0
		}
		return 1
	    } else {return 0}
	}
	4 {    
	    if { [string is integer  $data] } {
		if { $data > 5 } {
		    return 0
		} 
		return 1 
	    } else {return 0}
	}
    }
	
}



###################### ****************** ###########################
# $Log$
# Revision 1.70  2003/08/09 10:03:54  kakaroto
# contact list cached!!! works :) now time for testing... :S
# corrected little bug with reload_files
#
# Revision 1.69  2003/08/09 04:42:39  kakaroto
# oufff, at last, the "reload_files" proc is working...
#
# Revision 1.68  2003/08/07 15:46:00  airadier
# Call cmsn_draw_online on preferences exit (if online)
#
# Revision 1.67  2003/08/03 18:21:45  burgerman
# Fixed profiles issues and cleaned them up:
#
# Revision 1.66  2003/07/25 09:41:35  kakaroto
# Added tooltips on user names and preferences option "enable tooltips"
#
# Revision 1.65  2003/07/22 15:46:13  airadier
# Added translation key to "Add to AL/FL/BL"
#
# Revision 1.64  2003/07/19 17:56:50  kakaroto
# added a "disabled animated smileys" option
# destroying smileys menu everytime
#
# Revision 1.63  2003/06/30 11:23:47  kakaroto
# added skin support and animated smileys
#
# Revision 1.62  2003/06/28 05:38:00  kakaroto
# added the boss mode
# added the gui for the blocking thing + using only one SB
# chnaged the way to access tabs in the preferences window (Preftabs array)
# added entry to add directly to FL/AL/BL lists
# "Execute : $command" in the status log when executing a command using it's entry...
# added a catch for the call of run_alarms .. we needed that..
#
# Revision 1.61  2003/06/16 09:21:14  kakaroto
# disabled the "SYN 0" ns command when the preferences window is closed : no reload of the contact list
#
# Revision 1.60  2003/06/15 21:28:57  burgerman
# pref
#
# Revision 1.59  2003/06/15 21:22:29  burgerman
# dynamique entries in pref
#
# Revision 1.58  2003/06/15 11:14:55  airadier
# Updated languages and minor changes in preferences window
#
# Revision 1.57  2003/06/15 10:11:40  kakaroto
# privacy listboxes resizable with the preferences window
#
# Revision 1.56  2003/06/15 09:59:34  kakaroto
# added support for the BLP command ( allow users not in my allow/block list to see me online)
#
# Revision 1.55  2003/06/15 07:31:38  kakaroto
# The user's list manipulation support (The privacy tab)
#
# Revision 1.54  2003/06/15 02:58:31  burgerman
# small bug in pref
#
# Revision 1.53  2003/06/14 23:27:50  kakaroto
# added the 3 buttons in the status log
#
# Revision 1.52  2003/06/14 02:17:42  kakaroto
# fixed bug in the save to file of the protocol window
#
# Revision 1.51  2003/06/14 02:16:28  kakaroto
# save to file option for the protocol window
#
# Revision 1.50  2003/06/14 02:06:05  kakaroto
# blocking thing support
# remote control support
#
# Revision 1.49  2003/06/14 01:24:53  kakaroto
# fixed the block thing support
# fixed bugs with the remote controler
#
# Revision 1.48  2003/06/12 00:07:08  burgerman
# Custom states are here, meaning you can create states with away auto messages. have fun
#
# Revision 1.47  2003/06/10 23:48:55  airadier
# Added option for initial file transfers port
#
# Revision 1.46  2003/06/07 08:14:01  kakaroto
# added color support for remote shell and added new functions
#
# Revision 1.45  2003/06/05 14:24:41  airadier
# Modified preferences por connections and proxy settings.
#
# Revision 1.44  2003/06/05 12:06:02  airadier
# Fixed a raise/minimize issue with chat windows, and added a new option for raising or iconifying window when a new chat starts
#
# Revision 1.43  2003/06/01 19:49:36  airadier
# Very alpha support of POST proxy method.
# Removed WriteNS, WriteNSRaw, and read_ns_sock, it was same code as WriteSB, WriteSBRaw and read_sb_sock, so now they're the same, always use SB procedures.
#
# Revision 1.42  2003/05/31 16:51:02  airadier
# Removed preferences cascade menu, some people asked for it.
#
# Revision 1.41  2003/05/31 07:35:40  kakaroto
# rcontroler shell and remote controling support
# added support for remote controlling and added the remote controler shell
#
# Revision 1.40  2003/05/24 05:50:04  burgerman
# fixed issues with autoaway autoidle
#
# Revision 1.39  2003/05/23 20:16:57  burgerman
# removed the blocking feature for now, could ban account for spaming, still to be tested further
# small features
#
# Revision 1.38  2003/05/22 21:49:39  burgerman
# autoidle + autoaway + preferences
#
# Revision 1.37  2003/05/22 20:40:10  burgerman
# 3 new notifies (on msg, on online, on email) now separate, removed old
# config(notifywin)
#
# Revision 1.36  2003/04/24 11:04:32  airadier
# Auto scrolling in protocol debug window
#
# Revision 1.35  2003/04/09 17:38:44  airadier
# Added a check in msgacks()
#
# Revision 1.34  2003/04/07 16:50:35  airadier
# Fixed font config saving issues (now we save a config backup in the preferences window, and restore it when window is destroyed, instead of modyfing a copy and saving it to $config when clicking "Save).
#
# Revision 1.33  2003/04/02 00:44:45  airadier
# Every NS or SB network operation is now done thru WriteSB, so everything is logged to the protocol window.
#
# Revision 1.32  2003/03/30 17:47:30  airadier
# Added timeouts to switchboard reconnections and invitations.
# Added (online/offline) number to group mode.
#
# Revision 1.31  2003/01/28 20:23:34  burgerman
# bah
#
# Revision 1.30  2003/01/28 08:36:05  burgerman
# New look for TODO :P cant help myself
# Fixed long messages < 400, now gets separated into small fragments and sends automaticly
# Fixed notify window clickable thing (still need to add X)
# Fixed notify on file transfer
# Made preferences dynamic, can login/logout while pref open, will adapt
# Lotsa small bug fixes for strange user inputs (empty usernames, password, etc)
#
# Revision 1.29  2003/01/26 03:02:31  burgerman
# +Preferences finished, Delete all Logs and Delete profile working.
# +Made new profiles use DEFAULT profile initially
# +Still problem on language changes, dosent notify you on create or use default profile, will be fixed after main window redraw is done and working.
# +duno what else i did cant remember...
#
# Revision 1.28  2003/01/25 05:36:22  burgerman
# Prefs nearly done, gotta work on clear all logs and delete profile
# updated TODO
#
# Revision 1.27  2003/01/23 06:38:14  burgerman
# more work on prefs
# reomved status_log from UsersInChat
#
# Revision 1.26  2003/01/22 06:50:55  burgerman
# More work on prefs...
# set user_stat to FLN on disconnect
#
# Revision 1.25  2003/01/21 18:30:07  burgerman
# more work on pref
# removed -nobackslashes from proc trans to allow /n in translations
# fixed couple of tiny bugs in login profile dialog
#
# Revision 1.24  2003/01/21 16:12:24  burgerman
# Some more work on pref, dkfont fix..
#
# Revision 1.23  2003/01/18 17:46:26  burgerman
# more pref work
#
# Revision 1.21  2003/01/12 23:33:03  burgerman
# more work on preferences, damn these things take long
# partial fix for windows launch_browser (now hotmail login dosent work on windows, will fix)
# fix on bg color selection
# think thats about it ...
#
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
