#ToDo:
# loading images saved on HD
# save drawing on HD
# smileys as stamps / importing pencils
# improve: show sent image in chatwin


#Create our namespace
namespace eval ::draw {
	proc Init { dir } {
		
		#Register the plugin to the plugins-system
		::plugins::RegisterPlugin draw
		
		#Register events
		::plugins::RegisterEvent draw chatwindowbutton AddInkSwitchButton

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

		set smileybut $buttonbar.smileys
		set fontbut $buttonbar.fontsel

		#remove the text/smiley controls		
		pack forget $smileybut
		pack forget $fontbut

		set w $window	
		set inputframe $w.f.bottom.left.in.inner
		set textinput $inputframe.text
		
		pack forget $textinput

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

		#SENDBUTTON (if sendbutton in inputfield is not present
		set sendbuttonframe $w.f.bottom.left.in.inner.sbframe
		set sendbutton $sendbuttonframe.send


		if {![::skin::getKey chat_show_sendbuttonframe]} {
			#if no sendbutton, put a button in the buttonbar to send the drawing
			set senddraw $buttonbar.senddrawingbutton

			CreateToolButton $senddraw butsend [list ::draw::PressedSendDraw $window]


		} else {
			#bind the sendbutton
		
			if { ($::tcl_version >= 8.4) && [OnMac] } {
				$sendbutton configure -command "::draw::PressedSendDraw $window"
			} elseif { [OnMac] } {
				bind $sendbutton <<Button1>> "::draw::PressedSendDraw $window"
			} else {
				$sendbutton configure -command "::draw::PressedSendDraw $window"
			}
		}					

		bind $sendbutton <Return> "::draw::PressedSendDraw $window"
		bind $textinput <Return> "::draw::PressedSendDraw $window"
		bind $textinput <Key-KP_Enter> "::draw::PressedSendDraw $window; break"		


		#SWITCHBUTTON
		set inkswitch $buttonbar.inkswitchbut
		$inkswitch configure -image [::skin::loadPixmap buttext]
		bind $inkswitch  <<Button1>> "::draw::ResetTextInput $window $buttonbar"
		bind $inkswitch  <Enter> "$inkswitch configure -image [::skin::loadPixmap buttext_hover]"
		bind $inkswitch  <Leave> "$inkswitch configure -image [::skin::loadPixmap buttext]"	
		#needs to be repacked at last
		pack forget $inkswitch

		pack $inkswitch -side left -padx 0 -pady 0

		
	
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
status_log "reset to text mode"

		set smileybut $buttonbar.smileys
		set fontbut $buttonbar.fontsel
		
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
		#needs to be repacked at last
		pack forget $inkswitch

		#repack the text/smiley controls		
		pack $fontbut -side left -padx 0 -pady 0
		pack $smileybut -side left -padx 0 -pady 0
		pack $inkswitch -side left -padx 0 -pady 0
		
		
		set inputframe $window.f.bottom.left.in.inner
		set drawboardwidget $inputframe.draw
		set textinput $inputframe.text

		pack forget $drawboardwidget
		
		pack $textinput -side left -expand true -fill both -padx 1 -pady 1
		
		
		
		#rebind the sendbutton
		set inputframe $window.f.bottom.left.in
		set sendbuttonframe [$inputframe getinnerframe].sbframe
		set sendbutton $sendbuttonframe.send	
		if {[winfo exists $sendbutton]} {
status_log "reset sendbutton binding"
			if { ($::tcl_version >= 8.4) && [OnMac] } {
				$sendbutton configure -command "::amsn::MessageSend $window $textinput"
			} elseif { [OnMac] } {
				bind $sendbutton <<Button1>> "::amsn::MessageSend $window $textinput"
			} else {
				$sendbutton configure -command "::amsn::MessageSend $window $textinput"
			}
			bind $sendbutton <Return> "::amsn::MessageSend $window $textinput; break"
		}
		
		bind $textinput <Return> "window_history add %W; ::amsn::MessageSend $window %W; break"
		bind $textinput <Key-KP_Enter> "window_history add %W; ::amsn::MessageSend $window %W; break"		

	}
	


	#this hack is needed
	proc PressedSendDraw { window } {
		set widget $window.f.bottom.left.in.inner.draw
status_log "$widget SaveDrawing [pwd] inktosend.gif"
		$widget SaveDrawing "[pwd]" "inktosend.gif"

		#send the saved file
		::MSN::SendInk [lindex [::MSN::SBFor [::ChatWindow::Name $window]] 0] inktosend.gif
		$widget ClearDrawboard	


		#show the sent one in the chatwin
		#first the "xx says:" 
		
		::amsn::WinWrite [::ChatWindow::Name $window] "\n" ""
		

		set scrolling [::ChatWindow::getScrolling [::ChatWindow::GetOutText ${window}]]


		[::ChatWindow::GetOutText ${window}] configure -state normal
		[::ChatWindow::GetOutText ${window}] image create end -image [image create photo -file inktosend.gif]

		if { $scrolling } { ::ChatWindow::Scroll [::ChatWindow::GetOutText ${window}] }


		[::ChatWindow::GetOutText ${window}] configure -state disabled

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

