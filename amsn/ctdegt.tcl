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
    set Text {bg #2200FF foreground #111111 font splainf}
    set Button {foreground #111111}
#    set Frame {background #111111}
    ::themes::AddClass Degt Entry $Entry 90
    ::themes::AddClass Degt Label $Label 90
    ::themes::AddClass Degt Text $Text 90
    ::themes::AddClass Degt Button $Button 90
#    ::themes::AddClass Degt Frame $Frame 90
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

    $m add command -label [trans personal] -command "Preferences personal"
    $m add command -label [trans appearance] -command "Preferences appearance"
    $m add command -label [trans session] -command "Preferences session"
    $m add command -label [trans loging] -command "Preferences loging"
    $m add command -label [trans connection] -command "Preferences connection"
    $m add command -label [trans prefapps] -command "Preferences apps"
    $m add command -label [trans profiles] -command "Preferences profiles"
}

proc Preferences { settings } {
    global config myconfig proxy_server proxy_port images_folder

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
    button .cfg.buttons.cancel -text [trans close] -font sboldf -command "destroy .cfg" 
    pack .cfg.buttons.save .cfg.buttons.cancel -side left -padx 10 -pady 5
    pack .cfg.buttons -side top -fill x
   
    set nb .cfg.notebook.nn

	# Preferences Notebook
	# Modified Rnotebook to translate automaticly those keys in -tabs {}
	Rnotebook:create $nb -tabs {personal appearance session loging connection prefapps profiles} -borderwidth 2
	pack $nb -fill both -expand 1 -padx 10 -pady 10

	#  .----------.
	# _| Personal |________________________________________________
	image create photo prefpers -file [file join ${images_folder} prefpers.gif]
	image create photo prefprofile -file [file join ${images_folder} prefprofile.gif]
	image create photo preffont -file [file join ${images_folder} preffont.gif]
	image create photo prefphone -file [file join ${images_folder} prefphone.gif]
	set frm [Rnotebook:frame $nb 1]

	## Nickname Selection Entry Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans prefname] -font splainf]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.pname -image prefpers
	label $lfname.lname -text "[trans enternick] :" -font sboldf -padx 10
	entry $lfname.name -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 45
	pack $lfname.pname $lfname.lname $lfname.name -side left
	
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

	set frm [Rnotebook:frame $nb 2]
	
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
	pack $lfname.1 -side top -padx 0 -pady 5 -expand 1 -fill both
	pack $lfname.1.llook -side left
	pack $lfname.1.bencoding -side right -padx 15
	label $lfname.2.llook -text "[trans bgcolor]" -padx 10
	button $lfname.2.bbgcolor -text [trans choosebgcolor] -font sboldf -command "choose_theme"
	pack $lfname.2 -side top -padx 0 -pady 5 -expand 1 -fill both
	pack $lfname.2.llook -side left	
	pack $lfname.2.bbgcolor -side right -padx 15
	label $lfname.3.llook -text "[trans preffont3]" -padx 10
	button $lfname.3.bfont -text [trans changefont] -font sboldf -command "choose_basefont"
	pack $lfname.3 -side top -padx 0 -pady 5 -expand 1 -fill both
	pack $lfname.3.llook -side left	
	pack $lfname.3.bfont -side right -padx 15
	
	## Emoticons Frame ##
	set lfname [LabelFrame:create $frm.lfname2 -text [trans prefemotic]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.pemotic -image prefemotic
	pack $lfname.pemotic -side left -anchor nw
	frame $lfname.1 -class Degt
	pack $lfname.1 -side left -padx 0 -pady 5 -expand 1 -fill both
	checkbutton $lfname.1.chat -text "[trans chatsmileys2]" -onvalue 1 -offvalue 0 -variable myconfig(chatsmileys)
	checkbutton $lfname.1.list -text "[trans listsmileys2]" -onvalue 1 -offvalue 0 -variable myconfig(listsmileys)
	checkbutton $lfname.1.log -text "[trans logsmileys]" -onvalue 1 -offvalue 0 -variable myconfig(logsmileys) -state disabled	
	pack $lfname.1.chat $lfname.1.list $lfname.1.log -anchor w -side top -padx 10
	
	## Alerts and Sounds Frame ##
	set lfname [LabelFrame:create $frm.lfname3 -text [trans prefalerts]]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.palerts -image prefalerts
	pack $lfname.palerts -side left -anchor nw
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	label $lfname.2.loffset -text "[trans notifyoffset]" -padx 10
	label $lfname.2.lxoffset -text "[trans xoffset] :" -font sboldf -padx 10
	entry $lfname.2.xoffset -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 5 -textvariable myconfig(notifyXoffset)
	label $lfname.2.lyoffset -text "[trans yoffset] :" -font sboldf -padx 10
	entry $lfname.2.yoffset -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 5 -textvariable myconfig(notifyYoffset)
	pack $lfname.2.loffset -side top -anchor w
	pack $lfname.2.lxoffset $lfname.2.xoffset $lfname.2.lyoffset $lfname.2.yoffset -side left -anchor w
	checkbutton $lfname.1.alert1 -text "[trans notify1]" -onvalue 1 -offvalue 0 -variable myconfig(notifywin)
	checkbutton $lfname.1.alert2 -text "[trans notify2]" -onvalue 1 -offvalue 0 -variable myconfig(notifywin)
	checkbutton $lfname.1.alert3 -text "[trans notify3]" -onvalue 1 -offvalue 0 -variable myconfig(notifywin)
	checkbutton $lfname.1.sound -text "[trans sound2]" -onvalue 1 -offvalue 0 -variable myconfig(sound)	
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

	set frm [Rnotebook:frame $nb 3]
	
	## Sign In and AutoStatus Options Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans prefsession]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.psession -image prefstatus
	pack $lfname.psession -anchor nw -side left
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	frame $lfname.3 -class Degt
	checkbutton $lfname.1.lautonoact -text "[trans autonoact]" -onvalue 1 -offvalue 0 -variable myconfig(autoidle)
	entry $lfname.1.eautonoact -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 3 -state disabled
	label $lfname.1.lmins -text "[trans mins]" -padx 5
	pack $lfname.1 -side top -padx 0 -expand 1 -fill both
	pack $lfname.1.lautonoact $lfname.1.eautonoact $lfname.1.lmins -side left
	checkbutton $lfname.2.lautoaway -text "[trans autoaway]" -onvalue 1 -offvalue 0 -variable myconfig(autoaway) -state disabled
	entry $lfname.2.eautoaway -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 3 -state disabled
	label $lfname.2.lmins -text "[trans mins]" -padx 5
	pack $lfname.2 -side top -padx 0 -expand 1 -fill both
	pack $lfname.2.lautoaway $lfname.2.eautoaway $lfname.2.lmins -side left
	checkbutton $lfname.3.lonstart -text "[trans autoconnect2]" -onvalue 1 -offvalue 0 -variable myconfig(autoconnect)
	checkbutton $lfname.3.lstrtoff -text "[trans startoffline2]" -onvalue 1 -offvalue 0 -variable myconfig(startoffline)
	pack $lfname.3 -side top -padx 0 -expand 1 -fill both
	pack $lfname.3.lonstart $lfname.3.lstrtoff -anchor w -side top

	## Away Messages Frame ##
	set lfname [LabelFrame:create $frm.lfname2 -text [trans prefawaymsg]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.psession -image prefaway
	pack $lfname.psession -anchor nw -side left
	radiobutton $lfname.awaymsg1 -text [trans awaymsg1] -value 1 -variable myconfig(awaymsg) -state disabled
	radiobutton $lfname.awaymsg2 -text [trans awaymsg2] -value 2 -variable myconfig(awaymsg) -state disabled
	text $lfname.awayentry -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 60 -height 3 -state disabled
	pack $lfname.awaymsg1 $lfname.awaymsg2 -anchor w -side top
	pack $lfname.awayentry -anchor w -side top -padx 10

	## Messaging Interface Frame ##
	set lfname [LabelFrame:create $frm.lfname3 -text [trans prefmsging]]
	pack $frm.lfname3 -anchor n -side top -expand 1 -fill x
	label $lfname.pmsging -image prefmsg
	pack $lfname.pmsging -anchor nw -side left
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	label $lfname.1.lmsgmaxmin -text [trans msgmaxmin] -padx 10
	radiobutton $lfname.1.max -text [trans maximised] -value 1 -variable myconfig(msgmaxmin) -state disabled
	radiobutton $lfname.1.min -text [trans minimised] -value 2 -variable myconfig(msgmaxmin) -state disabled
	pack $lfname.1.lmsgmaxmin -anchor w -side top -padx 10
	pack $lfname.1.max $lfname.1.min -side left -padx 10
	label $lfname.2.lmsgmode -text [trans msgmode] -padx 10
	radiobutton $lfname.2.normal -text [trans normal] -value 1 -variable myconfig(msgmode) -state disabled
	radiobutton $lfname.2.tabbed -text [trans tabbed] -value 2 -variable myconfig(msgmode) -state disabled
	pack $lfname.2.lmsgmode -anchor w -side top -padx 10
	pack $lfname.2.normal $lfname.2.tabbed -side left -padx 10
	pack $lfname.1 $lfname.2 -anchor w -side top

	frame $frm.dummy -class Degt
	pack $frm.dummy -anchor n -side top -expand 1 -fill both -pady 150

	#  .--------.
	# _| Loging |________________________________________________
	image create photo prefhist -file [file join ${images_folder} prefhist.gif]
	image create photo prefhist2 -file [file join ${images_folder} prefhist2.gif]
	image create photo prefhist3 -file [file join ${images_folder} prefhist3.gif]

	set frm [Rnotebook:frame $nb 4]

	## Loging Options Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans preflog1]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.plog1 -image prefhist
	pack $lfname.plog1 -anchor nw -side left
	checkbutton $lfname.log -text "[trans keeplog2]" -onvalue 1 -offvalue 0 -variable myconfig(keep_logs)
	pack $lfname.log -anchor w -side top
	frame $lfname.2 -class Degt
	label $lfname.2.lstyle -text "[trans stylelog]" -padx 10
	radiobutton $lfname.2.hist -text [trans stylechat] -value 1 -variable myconfig(logstyle) -state disabled
	radiobutton $lfname.2.chat -text [trans stylehist] -value 2 -variable myconfig(logstyle) -state disabled
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
	checkbutton $lfname.1.lolder -text "[trans logolder]" -onvalue 1 -offvalue 0 -variable myconfig(logexpiry) -state disabled
	entry $lfname.1.eolder -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0  -width 3 -state disabled
	label $lfname.1.ldays -text "[trans days]" -padx 5
	pack $lfname.1 -side top -padx 0 -expand 1 -fill both
	pack $lfname.1.lolder $lfname.1.eolder $lfname.1.ldays -side left
	frame $lfname.2 -class Degt
	checkbutton $lfname.2.lbigger -text "[trans logbigger]" -onvalue 1 -offvalue 0 -variable myconfig(logmaxsize) -state disabled
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

	set frm [Rnotebook:frame $nb 5]
	
	## NAT Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans prefshared]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image prefnat
	pack $lfname.pshared -side left -anchor nw
	frame $lfname.1 -class Degt
	pack $lfname.1 -side left -padx 0 -pady 5 -expand 1 -fill both
	checkbutton $lfname.1.keepalive -text "[trans natkeepalive]" -onvalue 1 -offvalue 0 -variable myconfig(keepalive)
	checkbutton $lfname.1.ip -text "[trans ipdetect]" -onvalue 1 -offvalue 0 -variable myconfig(natip)
	pack $lfname.1.keepalive $lfname.1.ip -anchor w -side top -padx 10
	
	## Proxy Frame ##
	set lfname [LabelFrame:create $frm.lfname2 -text [trans prefproxy]]
	pack $frm.lfname2 -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image prefproxy
	pack $lfname.pshared -side left -anchor nw	
	frame $lfname.1 -class Degt
	frame $lfname.2 -class Degt
	frame $lfname.3 -class Degt
	checkbutton $lfname.1.proxy -text "[trans proxy]" -onvalue 1 -offvalue 0 -variable myconfig(withproxy)
	pack $lfname.1.proxy -anchor w -side top -padx 10
	radiobutton $lfname.2.http -text "HTTP" -value http -variable myconfig(proxytype)
	radiobutton $lfname.2.socks5 -text "SOCKS5" -value socks -variable myconfig(proxytype) -state disabled	
	pack $lfname.2.http $lfname.2.socks5 -anchor w -side left -padx 10
	pack $lfname.1 $lfname.2 $lfname.3 -anchor w -side top -padx 0 -pady 0 -expand 1 -fill both
	label $lfname.3.lserver -text "[trans server] :" -padx 5 -font sboldf
	entry $lfname.3.server -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20 -textvariable proxy_server
	label $lfname.3.lport -text "[trans port] :" -padx 5 -font sboldf
	entry $lfname.3.port -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 5 -textvariable proxy_port
	label $lfname.3.luser -text "[trans user] :" -padx 5 -font sboldf
	entry $lfname.3.user -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20
	label $lfname.3.lpass -text "[trans pass] :" -padx 5 -font sboldf
	entry $lfname.3.pass -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 20 -show "*"
	grid $lfname.3.lserver -row 1 -column 1 -sticky e
	grid $lfname.3.server -row 1 -column 2 -sticky w -pady 5
	grid $lfname.3.lport -row 1 -column 3 -sticky e
	grid $lfname.3.port -row 1 -column 4 -sticky w -pady 5
	grid $lfname.3.luser -row 2 -column 1 -sticky e
	grid $lfname.3.user -row 2 -column 2 -sticky w
	grid $lfname.3.lpass -row 2 -column 3 -sticky e
	grid $lfname.3.pass -row 2 -column 4 -sticky w

	frame $frm.dummy -class Degt
	pack $frm.dummy -anchor n -side top -expand 1 -fill both -pady 150

	#  .--------------.
	# _| Applications |________________________________________________
	image create photo prefapps -file [file join ${images_folder} prefpers.gif]

	set frm [Rnotebook:frame $nb 6]
	
	## Applications Frame ##
	set lfname [LabelFrame:create $frm.lfname -text [trans prefapps]]
	pack $frm.lfname -anchor n -side top -expand 1 -fill x
	label $lfname.pshared -image prefapps
	pack $lfname.pshared -side left -anchor nw
	frame $lfname.1 -class Degt
	pack $lfname.1 -anchor w -side left -padx 0 -pady 5 -expand 1 -fill both
	label $lfname.1.lbrowser -text "[trans browser] :" -padx 5 -font sboldf
	entry $lfname.1.browser -bg #FFFFFF -bd 1 -highlightthickness 0 -width 20 -textvariable myconfig(browser)
	label $lfname.1.lfileman -text "[trans fileman] :" -padx 5 -font sboldf 
	entry $lfname.1.fileman -bg #FFFFFF -bd 1 -highlightthickness 0 -width 20 -textvariable myconfig(filemanager)
	label $lfname.1.lmailer -text "[trans mailer] :" -padx 5 -font sboldf
	entry $lfname.1.mailer -bg #FFFFFF -bd 1 -highlightthickness 0 -width 20 -textvariable myconfig(mailcommand)
	label $lfname.1.lhot -text "[trans leaveblankforhotmail]" -font examplef -padx 5 
	label $lfname.1.lsound -text "[trans soundserver] :" -padx 5 -font sboldf
	entry $lfname.1.sound -bg #FFFFFF -bd 1 -highlightthickness 0 -width 20 -textvariable myconfig(soundcommand)
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
	set frm [Rnotebook:frame $nb 7]
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
	
    setCfgFonts $nb splainf

    Rnotebook:totalwidth $nb

    InitPref

    wm geometry .cfg [expr [Rnotebook:totalwidth $nb] + 50]x595
 
    switch $settings {
        personal { Rnotebook:raise $nb 1 }
	appearance { Rnotebook:raise $nb 2 }
        session { Rnotebook:raise $nb 3 }
        loging { Rnotebook:raise $nb 4 }
	connection { Rnotebook:raise $nb 5 }
        apps { Rnotebook:raise $nb 6 }
        profiles { Rnotebook:raise $nb 7 }
	default { return }
    }

    tkwait visibility .cfg
    grab set .cfg
}

# This is where we fill in the Entries of the Preferences
proc InitPref {} {
	global user_stat user_info
	set nb .cfg.notebook.nn
	
	# Insert nickname if online, disable if offline
	set lfname [Rnotebook:frame $nb 1]
	if { $user_stat == "FLN" } {
		$lfname.lfname.f.f.name configure -state disabled
	} else {
		$lfname.lfname.f.f.name insert 0 [urldecode [lindex $user_info 4]]
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
	set lfname [Rnotebook:frame $nb 7]
	set lfname "$lfname.lfname.f.f"
   	set idx 0
   	set tmp_list ""
   	while { [LoginList get $idx] != 0 } {
		lappend tmp_list [LoginList get $idx]
		incr idx
	}
   	eval $lfname.1.profile list insert end $tmp_list
	$lfname.1.profile insert 0 [lindex $tmp_list 0]
   	unset idx
   	unset tmp_list
	$lfname.1.profile configure -editable false
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
    global config myconfig proxy_server proxy_port user_info user_stat

    set nb .cfg.notebook.nn

    # I. Data Validation & Metavariable substitution
    # Proxy settings
    set p_server [string trim $proxy_server]
    set p_port [string trim $proxy_port]
    if { ($p_server != "") && ($p_port != "") && [string is digit $proxy_port] } {
       set myconfig(proxy) [join [list $p_server $p_port] ":"]
    } else {
       set myconfig(proxy) ""
       set myconfig(withproxy) 0
    }

    # Make sure x and y offsets are digits, if not revert to old values
    if { [string is digit $myconfig(notifyXoffset)] == 0 } {
    	set myconfig(notifyXoffset) $config(notifyXoffset)
    }
    if { [string is digit $myconfig(notifyYoffset)] == 0 } {
    	set myconfig(notifyYoffset) $config(notifyYoffset)
    }
    
    # Check and save phone numbers
    if { $user_stat != "FLN" } {
	    set lfname [Rnotebook:frame $nb 1]
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
    set lfname [Rnotebook:frame $nb 1]
    set lfname "$lfname.lfname.f.f"
    set new_name [$lfname.name get]
    if {$new_name != "" && $new_name != [urldecode [lindex $user_info 4]]} {
	::MSN::changeName $config(login) $new_name
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

###################### ****************** ###########################
# $Log$
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
