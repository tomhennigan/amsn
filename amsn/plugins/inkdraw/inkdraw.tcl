#To not forget:
# loading images saved on HD
# save drawing on HD
# smileys as stamps / importing pencils



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

		drawboard $drawwidget -pencil pencil1 -color black -drawmode free -grid 0;#-gridimg [::skin::loadPixmap grid]
		pack $drawwidget -side left -padx 0 -pady 0 -expand true -fill both
		

		#GRIDSWITCH
		set gridbut $buttonbar.gridswitchbutton
		set gridstate [$drawwidget cget -grid]
#		if {$gridstate} {
status_log "adding gridbutton"
			label $gridbut -image [::skin::loadPixmap butgridon] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]

			pack $gridbut -side left -padx 0 -pady 0

			bind $gridbut  <<Button1>> "::draw::ToggleGrid $gridbut $drawwidget"
			bind $gridbut  <Enter> "$gridbut configure -image [::skin::loadPixmap butgridon_hover]"
			bind $gridbut  <Leave> "$gridbut configure -image [::skin::loadPixmap butgridon]"
#		}


		#SENDBUTTON (if sendbutton in inputfield is not present
		if {![::skin::getKey chat_show_sendbuttonframe]} {
			#if no sendbutton, put a button in the buttonbar to send the drawing
			set senddraw $buttonbar.senddrawingbutton
			label $senddraw -image [::skin::loadPixmap butsend] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]

			pack $senddraw -side left -padx 0 -pady 0

			bind $senddraw  <<Button1>> "after 1 ::draw::PressedSendDraw $window"
			bind $senddraw  <Enter> "$senddraw configure -image [::skin::loadPixmap butsend_hover]"
			bind $senddraw  <Leave> "$senddraw configure -image [::skin::loadPixmap butsend]"		
		} else {
			#rebind the sendbutton

			set sendbuttonframe $w.f.bottom.left.in.inner.sbframe
			set sendbutton $sendbuttonframe.send
				
			if { ($::tcl_version >= 8.4) && [OnMac] } {
				$sendbutton configure -command "::draw::PressedSendDraw $window"
			} elseif { [OnMac] } {
				bind $sendbutton <<Button1>> "::draw::PressedSendDraw $window"
			} else {
				$sendbutton configure -command "::draw::PressedSendDraw $window"
			}
		}					


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
		set inkswitch $buttonbar.inkswitchbut
		set senddraw $buttonbar.senddrawingbutton
		set gridbut $buttonbar.gridswitchbutton

		set smileybut $buttonbar.smileys
		set fontbut $buttonbar.fontsel

		#remove the ink controls
		if {[winfo exists $senddraw]} {destroy $senddraw}
		if {[winfo exists $gridbut]} {destroy $gridbut}		
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

		destroy $drawboardwidget
		
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
		}
	}
	


	#this hack is needed
	proc PressedSendDraw { window } {
		set widget $window.f.bottom.left.in.inner.draw
status_log "$widget SaveDrawing [pwd] inktosend.gif"
		$widget SaveDrawing "[pwd]" "inktosend.gif"

		#send the saved file
		::MSN::SendInk [lindex [::MSN::SBFor [::ChatWindow::Name $window]] 0] inktosend.gif
		$widget ClearDrawboard	
	}
}

