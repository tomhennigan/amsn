#ToDo:
# loading images saved on HD
# save drawing on HD
# smileys as stamps / importing pencils
# improve: show sent image in chatwin


#Create our namespace
namespace eval ::draw {

	variable ink_text_pack [list]

	proc Init { dir } {
		
		#Register the plugin to the plugins-system
		::plugins::RegisterPlugin "Inkdraw"
		
		#Register events
		::plugins::RegisterEvent "Inkdraw" chatwindowbutton AddInkSwitchButton

		#Load our pixmaps
		::skin::setPixmap grid grid.gif pixmaps [file join $dir pixmaps]

		::skin::setPixmap butdraw butdraw.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap butdraw_hover butdraw_hover.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap buttext buttext.gif pixmaps [file join $dir pixmaps]		
		::skin::setPixmap buttext_hover buttext_hover.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap butgridon butgridon.gif pixmaps [file join $dir pixmaps]		
		::skin::setPixmap butgridon_hover butgridon_hover.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap butgridoff butgridoff.gif pixmaps [file join $dir pixmaps]		
		::skin::setPixmap butgridoff_hover butgridoff_hover.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap butwipe butwipe.gif pixmaps [file join $dir pixmaps]		
		::skin::setPixmap butwipe_hover butwipe_hover.gif pixmaps [file join $dir pixmaps]			
		#load pencils
		::draw::LoadPencils [file join $dir pencils]
		
		package require drawboard

	}


	#This should load all pencils (image files) in a specified dir 
	proc LoadPencils {dir} {
		global pencilslist
		
		set pencilslist [list ]
		foreach file [glob -nocomplain -directory $dir *.{png,gif,jpg,jpeg} ] {
			if { [file readable $file] } {
				set filename [lindex [file split $file] end]
				::skin::setPixmap [file rootname $filename] $filename pixmaps $dir
				lappend pencilslist [file rootname $filename]
			}
		}
	}


	#for testing or maybe later "undocking" feature
	proc OpenWin {w width height} {

		if {[winfo exists $w]} {destroy $w}

		toplevel $w -background white -borderwidth 0
		wm geometry $w ${width}x${height}
		
		set drawwidget $w.draw
		
		drawboard $drawwidget -grid 0
		pack $drawwidget -side left -padx 0 -pady 0 -expand true -fill both
		
	}



	proc AddInkSwitchButton { event evpar } {
		upvar 2 $evpar newvar

		set buttonbar $newvar(bottom)		

		set inkswitch $buttonbar.inkswitchbut
		label $inkswitch -image [::skin::loadPixmap butdraw] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		pack $inkswitch -side left -padx 0 -pady 0

		set window $newvar(window_name)	
		
		bind $inkswitch  <<Button1>> "::draw::AddDrawboard $window $buttonbar"
		bind $inkswitch  <Enter> "$inkswitch configure -image [::skin::loadPixmap butdraw_hover]"
		bind $inkswitch  <Leave> "$inkswitch configure -image [::skin::loadPixmap butdraw]"	
	

	}



	proc AddDrawboard { window buttonbar} {
		variable ink_text_pack

		set smileybut $buttonbar.smileys
		set fontbut $buttonbar.fontsel
		set voice $buttonbar.voice
		
		#remove the text/smiley controls		
		$smileybut configure -state disabled
		$fontbut configure -state disabled
		# if { [winfo exists $voice] } { pack forget $voice }

		set w $window	
		set inputtext [::ChatWindow::GetInputText $w]
		set inputframe [winfo parent $inputtext]
		
		# Algorithm copied from chatwindow.tcl used for placing the voiceclip widget...
		set slaves [pack slaves $inputframe]
		set ink_text_pack [list]
		foreach slave $slaves {
			if {$slave != "$inputframe.sbframe" } {
				lappend ink_text_pack [list $slave [pack info $slave]]
				pack forget $slave
			}
		}
		

		set drawwidget $inputframe.draw

		if {[winfo exists $drawwidget]} {
			status_log "drawwidget already exists"
			pack $drawwidget -side left -padx 0 -pady 0 -expand true -fill both			
		} else {
			status_log "creating drawwidget"
			drawboard $drawwidget -pencil pencil1 -color black -drawmode free -grid 0;#-gridimg [::skin::loadPixmap grid]
			pack $drawwidget -side left -padx 0 -pady 0 -expand true -fill both
		}		


		#GRIDSWITCH
		set gridbut $buttonbar.gridswitchbutton
		CreateToolButton $gridbut butgridon [list ::draw::ToggleGrid $gridbut $drawwidget]



		#WIPE
		set wipebut $buttonbar.wipebutton
		CreateToolButton $wipebut butwipe [list $drawwidget ClearDrawboard]

		#INPUT TEXT
		bind $inputtext <Return> "::draw::PressedSendDraw $window"
		bind $inputtext <Key-KP_Enter> "::draw::PressedSendDraw $window; break"		


		#SWITCHBUTTON
		set inkswitch $buttonbar.inkswitchbut
		$inkswitch configure -image [::skin::loadPixmap buttext]
		bind $inkswitch  <<Button1>> "::draw::ResetTextInput $window $buttonbar"
		bind $inkswitch  <Enter> "$inkswitch configure -image [::skin::loadPixmap buttext_hover]"
		bind $inkswitch  <Leave> "$inkswitch configure -image [::skin::loadPixmap buttext]"	

		#SENDBUTTON (if sendbutton in inputfield is not present)
		set sendbuttonframe $w.f.bottom.left.in.inner.sbframe
		set sendbutton $sendbuttonframe.send
		bind $sendbutton <Return> "::draw::PressedSendDraw $window"

		if {![::skin::getKey chat_show_sendbuttonframe]} {
			#if no sendbutton, put a button in the buttonbar to send the drawing
			set senddraw $buttonbar.senddrawingbutton

			CreateToolButton $senddraw butsend [list ::draw::PressedSendDraw $window]


		} else {
			#bind the sendbutton
		
			if { ($::tcl_version >= 8.4) && ![OnMac] } {
				catch { $sendbutton configure -command "::draw::PressedSendDraw $window" }
			} elseif { [OnMac] } {
				bind $sendbutton <<Button1>> "::draw::PressedSendDraw $window"
			} else {
				$sendbutton configure -command "::draw::PressedSendDraw $window"
			}
		}					

	}


	proc ToggleGrid { gridbut widget } {
#		set widget $window.f.bottom.left.in.inner.draw
		set gridstate [$widget cget -grid]
		if {$gridstate} {
			set butimg "butgridon"
			
		} else {
			set butimg "butgridoff"
		}
		
		$gridbut configure -image [::skin::loadPixmap $butimg]

		#bind $gridbut  <<Button1>> "::draw::SwitchGrid $gridbut $drawwidget"
		status_log "reconfigure gridbut with $butimg"
		bind $gridbut  <Enter> "$gridbut configure -image [::skin::loadPixmap ${butimg}_hover]"
		bind $gridbut  <Leave> "$gridbut configure -image [::skin::loadPixmap $butimg]"		

		$widget ToggleGrid
	}
		
		
		


	proc ResetTextInput { window buttonbar } {
		variable ink_text_pack
		status_log "reset to text mode"

		set smileybut $buttonbar.smileys
		set fontbut $buttonbar.fontsel
		set voice $buttonbar.voice
		
		set inkswitch $buttonbar.inkswitchbut
		set senddraw $buttonbar.senddrawingbutton
		set gridbut $buttonbar.gridswitchbutton
		set wipebut $buttonbar.wipebutton

		#remove the ink controls
		foreach control [list senddrawingbutton gridswitchbutton wipebutton] {
			if {[winfo exists $buttonbar.$control]} {pack forget $buttonbar.$control}
		}
	
#...
		#reconfigure inkswitch
		$inkswitch configure -image [::skin::loadPixmap butdraw]
		bind $inkswitch  <<Button1>> "::draw::AddDrawboard $window $buttonbar"
		bind $inkswitch  <Enter> "$inkswitch configure -image [::skin::loadPixmap butdraw_hover]"
		bind $inkswitch  <Leave> "$inkswitch configure -image [::skin::loadPixmap butdraw]"	
	

		#repack the text/smiley controls		
		$fontbut configure -state normal
		$smileybut configure -state normal
		
		
		set inputframe $window.f.bottom.left.in.inner
		set drawboardwidget $inputframe.draw
		set textinput $inputframe.text

		pack forget $drawboardwidget
		
		foreach slave $ink_text_pack {
			eval pack [lindex $slave 0] [lindex $slave 1]
		}
		unset ink_text_pack
		
		bind $textinput <Return> "window_history add %W; ::amsn::MessageSend $window %W; break"
		bind $textinput <Key-KP_Enter> "window_history add %W; ::amsn::MessageSend $window %W; break"
		
		#rebind the sendbutton
		set inputframe $window.f.bottom.left.in
		set sendbuttonframe [$inputframe getinnerframe].sbframe
		set sendbutton $sendbuttonframe.send	
		if {[winfo exists $sendbutton]} {
status_log "reset sendbutton binding"
			bind $sendbutton <Return> "::amsn::MessageSend $window $textinput; break"
			if { ($::tcl_version >= 8.4) && ![OnMac] } {
				catch { $sendbutton configure -command "::amsn::MessageSend $window $textinput" }
			} elseif { [OnMac] } {
				bind $sendbutton <<Button1>> "::amsn::MessageSend $window $textinput"
			} else {
				$sendbutton configure -command "::amsn::MessageSend $window $textinput"
			}
		}
		
	}
	


	#this hack is needed
	proc PressedSendDraw { window } {
		global HOME

		set widget $window.f.bottom.left.in.inner.draw
		#Put inktosend picture into a temp directory  to send it
		 if { [info exists ::env(TEMP) ] } {
			 $widget SaveDrawing $::env(TEMP) "inktosend-[pid].gif"
			 #send the saved file
			 ::amsn::InkSend $window [file join $::env(TEMP) "inktosend-[pid].gif"]
 		} else {
			$widget SaveDrawing "/tmp" "inktosend-[pid].gif"
			#send the saved file
			::amsn::InkSend $window [file join /tmp "inktosend-[pid].gif"]
		}
		
		$widget ClearDrawboard
	}


	proc CreateToolButton { widget imgname command } {
		if {![winfo exists $widget]} {
			label $widget -image [::skin::loadPixmap ${imgname}] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]

			bind $widget  <<Button1>> $command
			bind $widget  <Enter> "$widget configure -image [::skin::loadPixmap ${imgname}_hover]"
			bind $widget  <Leave> "$widget configure -image [::skin::loadPixmap ${imgname}]"
		}
		pack $widget -side left -padx 0 -pady 0
	}

}

