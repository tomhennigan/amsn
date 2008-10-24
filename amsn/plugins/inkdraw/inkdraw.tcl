#ToDo:
# loading images saved on HD
# save drawing on HD
# smileys as stamps / importing pencils


#Create our namespace
namespace eval ::draw {

	variable ink_text_pack [list]
	variable window ""

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
		::skin::setPixmap ink_tiny ink_tiny.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap ink_normal ink_normal.gif pixmaps [file join $dir pixmaps]
		::skin::setPixmap ink_huge ink_huge.gif pixmaps [file join $dir pixmaps]
		
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
		set window $newvar(window_name)

		button $inkswitch -image [::skin::loadPixmap butdraw] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg] \
			-command "::draw::AddDrawboard $window $buttonbar"
		pack $inkswitch -side left -padx 0 -pady 0

		#bind $inkswitch  <<Button1>> "::draw::AddDrawboard $window $buttonbar"
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
			drawboard $drawwidget -pencil pencil_7 -color black -drawmode free -grid 0;#-gridimg [::skin::loadPixmap grid]
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

		#PencilSelector
		CreatePencilWidget $drawwidget $buttonbar.pencilselector

		#ColorSelector
		CreateColorWidget $drawwidget $buttonbar.colorselector

		if {![::skin::getKey chat_show_sendbuttonframe]} {
			#if no sendbutton, put a button in the buttonbar to send the drawing
			set senddraw $buttonbar.senddrawingbutton

			CreateToolButton $senddraw butsend [list ::draw::PressedSendDraw $window]


		} else {
			#bind the sendbutton
			#watch for buttons2labels...
			if { ![catch {$sendbutton cget -command} ] } {
				$sendbutton configure -command "::draw::PressedSendDraw $window"
			} else {
				bind $sendbutton <<Button1>> "::draw::PressedSendDraw $window"
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
		foreach control [list senddrawingbutton gridswitchbutton wipebutton pencilselector colorselector ] {
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
		set ink_text_pack [list]
		
		bind $textinput <Return> "window_history add %W; ::amsn::MessageSend $window %W; break"
		bind $textinput <Key-KP_Enter> "window_history add %W; ::amsn::MessageSend $window %W; break"
		
		#rebind the sendbutton
		set inputframe $window.f.bottom.left.in
		set sendbuttonframe [$inputframe getinnerframe].sbframe
		set sendbutton $sendbuttonframe.send	
		if {[winfo exists $sendbutton]} {
status_log "reset sendbutton binding"
			bind $sendbutton <Return> "::amsn::MessageSend $window $textinput; break"
			if { ![catch {$sendbutton cget -command}] } {
				$sendbutton configure -command "::amsn::MessageSend $window $textinput"
			} else {
				bind $sendbutton <<Button1>> "::amsn::MessageSend $window $textinput"
			}
		}
		
	}
	


	#this hack is needed
	proc PressedSendDraw { window } {
		global HOME

		set widget $window.f.bottom.left.in.inner.draw
		#Put inktosend picture into a temp directory  to send it
		 if { [info exists ::env(TEMP) ] } {
			 $widget SaveDrawing [file join $::env(TEMP) "inktosend-[pid].gif"] 1
			 #send the saved file
			 ::amsn::InkSend $window [file join $::env(TEMP) "inktosend-[pid].gif"]
 		} else {
			$widget SaveDrawing [file join "/tmp" "inktosend-[pid].gif"] 1
			#send the saved file
			::amsn::InkSend $window [file join /tmp "inktosend-[pid].gif"]
		}
		
		$widget ClearDrawboard
	}



	proc CreatePencilWidget { drawwidget widget } {
		if {![winfo exists $widget]} {
			label $widget -image [::skin::loadPixmap ink_huge] -relief flat -padx 0 \
				-bg [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
				-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
			bind $widget  <<Button1>> [list ::draw::PencilMenu $drawwidget $widget %X %Y]
		}
		pack $widget -side left -padx 0 -pady 0
	}

	proc PencilMenu {drawwidget pencilbutton {x 0} {y 0}} {
		set w .pencil_selector	
		if {[catch {[toplevel $w]} res]} {
			destroy $w
			toplevel $w
		}
		wm state $w withdrawn
		wm geometry $w "20x30+${x}+${y}"
		wm title $w "[trans msn]"
		wm overrideredirect $w 1
		wm transient $w

		label $w.tiny -image [::skin::loadPixmap ink_tiny] -relief flat -padx 0 \
				-bg [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
				-highlightbackground [::skin::getKey buttonbarbg] \
				-activebackground [::skin::getKey buttonbarbg]
		bind $w.tiny <<Button1>> [list ::draw::ChangePencil $drawwidget 1 $pencilbutton]

		label $w.normal -image [::skin::loadPixmap ink_normal] -relief flat -padx 0 \
				-bg [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
				-highlightbackground [::skin::getKey buttonbarbg] \
				-activebackground [::skin::getKey buttonbarbg]
		bind $w.normal <<Button1>> [list ::draw::ChangePencil $drawwidget 3 $pencilbutton]

		label $w.huge -image [::skin::loadPixmap ink_huge] -relief flat -padx 0 \
				-bg [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
				-highlightbackground [::skin::getKey buttonbarbg] \
				-activebackground [::skin::getKey buttonbarbg]
		bind $w.huge <<Button1>> [list ::draw::ChangePencil $drawwidget 7 $pencilbutton]
		
		pack $w.tiny $w.normal $w.huge

		wm state $w normal
		bind $w <Leave> "::draw::handleLeaveEvent $w 20 30"
	}

	#from smileys.tcl
	proc handleLeaveEvent { w x_geo y_geo } {
		# Get the pointer and the window coordinates
		set pointer_x [winfo pointerx $w]
		set pointer_y [winfo pointery $w]
		set window_x [winfo rootx $w]
		set window_y [winfo rooty $w]
		# Calculate pointer coordinates relative to the menu
		set x [expr {$pointer_x-$window_x}]
		set y [expr {$pointer_y-$window_y}]
		# Check if the pointer is outside the menu
		# The first two conditions refers to the case in which the pointe is no
		# more on the same screen of the menu (and is therefore outside of it)
		if { $pointer_x == -1 || $pointer_y==-1 || $x < 0 || $x > $x_geo || $y < 0 || $y > $y_geo } {
			wm state $w withdrawn
		}
	}

	proc ChangePencil {drawwidget pencil_id pencilbutton} {
		switch $pencil_id {
			1 {
				$pencilbutton configure -image [::skin::loadPixmap ink_tiny]
			}	
			3 {
				$pencilbutton configure -image [::skin::loadPixmap ink_normal]
			}
			7 {
				$pencilbutton configure -image [::skin::loadPixmap ink_huge]
			}
		}
		$drawwidget configure -pencil pencil_${pencil_id}
	}




	proc CreateColorWidget {drawwidget widget} {
		if {![winfo exists $widget]} {
			label $widget -padx 0 -width 5 -height 1 \
				-bg black -highlightthickness 0 -borderwidth 1 \
				-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
			bind $widget  <<Button1>> [list ::draw::ChangeColor $drawwidget $widget]
		}
		pack $widget -side left -padx 0 -pady 0
	}

	proc ChangeColor {drawwidget colorbutton} {
		set color [tk_chooseColor]
		if {[string first "#" $color] == 0 } {
			$colorbutton configure -bg $color
			$drawwidget configure -color $color
		}
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

