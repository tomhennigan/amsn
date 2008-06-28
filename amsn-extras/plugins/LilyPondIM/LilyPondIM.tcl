# Copyright Andrei Barbu (abarbu@uwaterloo.ca)
# Copyright Boris FAURE (billiob@gmail.com)
# Based on the good work from Andrei Barbu (abarbu@uwaterloo.ca)
# This code is distributed under the GPL

#TODO, add translation support
namespace eval ::LilyPondIM {
	
	#############################################
	# ::LilyPondIM::Init                        #
	# ----------------------------------------- #
	# Initialization Procedure                  #
	# (Called by the Plugins System)            #
	#############################################
	proc Init { directory } {
		
		plugins_log "LilyPondIM" "LilyPond plugin has started"

		::plugins::RegisterPlugin "LilyPondIM"
		::plugins::RegisterEvent "LilyPondIM" PluginConfigured SaveTextW
		::plugins::RegisterEvent "LilyPondIM" chat_msg_send parseLilyPond	
		::plugins::RegisterEvent "LilyPondIM" chatwindowbutton AddLyButton

		array set ::LilyPondIM::config {
			path_lilypond {lilypond}
			path_dvips {dvips}
			path_convert {convert}
			resolution {70}
			header "\\version \"2.10.25\"\n\\include \"italiano.ly\"\n\
			        \\paper\{ragged-right=##t\}\n\\relative do' \{"	
			path_preamble {}
			footer "\}"
		}
		set ::LilyPondIM::dir $directory

		::skin::setPixmap buttonLy ly.png pixmaps [file join $directory pixmaps]
		::skin::setPixmap buttonLy_hover ly_hover.png pixmaps [file join $directory pixmaps]

		set ::LilyPondIM::configlist [list [list frame ::LilyPondIM::populateFrame ""] ]
	}
	
	proc populateFrame { win } {
		variable win_path
		set win_path $win
		#Path To Latex
		frame $win.lilypond -class Degt
		pack $win.lilypond -anchor w
		label $win.lilypond.lilypondpath -text "Path to lilypond binary :" -padx 5 -font sboldf
		entry $win.lilypond.path -bg #FFFFFF -width 45 -textvariable ::LilyPondIM::config(path_lilypond)
		button $win.lilypond.browse -text [trans browse] -command [list Browse_Dialog_file ::LilyPondIM::config(path_lilypond)] 
		grid $win.lilypond.lilypondpath -row 1 -column 1 -sticky w
		grid $win.lilypond.path -row 2 -column 1 -sticky w
		grid $win.lilypond.browse -row 2 -column 2 -sticky w

#		#Path To Dvips
#		frame $win.dvips -class Degt
#		pack $win.dvips -anchor w 
#		label $win.dvips.dvipspath -text "Path to dvips binary :" -padx 5 -font sboldf
#		entry $win.dvips.path -bg #FFFFFF -width 45 -textvariable ::LilyPondIM::config(path_dvips)
#		button $win.dvips.browse -text [trans browse] -command [list Browse_Dialog_file ::LilyPondIM::config(path_dvips)]
#		grid $win.dvips.dvipspath -row 1 -column 1 -sticky w
#		grid $win.dvips.path -row 2 -column 1 -sticky w
#		grid $win.dvips.browse -row 2 -column 2 -sticky w

		#Path To Convert
		frame $win.convert -class Degt
		pack $win.convert -anchor w 
		label $win.convert.convertpath -text "Path to convert binary :" -padx 5 -font sboldf
		entry $win.convert.path -bg #FFFFFF -width 45 -textvariable ::LilyPondIM::config(path_convert)
		button $win.convert.browse -text [trans browse] -command [list Browse_Dialog_file ::LilyPondIM::config(path_convert)]
		grid $win.convert.convertpath -row 1 -column 1 -sticky w
		grid $win.convert.path -row 2 -column 1 -sticky w
		grid $win.convert.browse -row 2 -column 2 -sticky w

		#Header
		frame $win.header -class Degt
		pack $win.header -anchor w
		label $win.header.label -text "Please enter here the header for the lilypond documents \n(add includes there) :"
		text $win.header.text -background white -borderwidth 1 -relief ridge -width 45 -height 7 -font sboldf
		button $win.header.default -text [trans default] -command [list ::LilyPondIM::MakeDefault $win.header.text header]
		$win.header.text insert end $::LilyPondIM::config(header)
		grid $win.header.label -row 1 -column 1 -sticky w
		grid $win.header.text -row 2 -column 1 -sticky w
		grid $win.header.default -row 3 -column 1 -sticky w
	
		#Path To PreambleFile
		frame $win.preamble -class Degt
		pack $win.preamble -anchor w 
		label $win.preamble.preamblepath -text "Path to a preamble file :" -padx 5 -font sboldf
		entry $win.preamble.path -bg #FFFFFF -width 45 -textvariable ::LilyPondIM::config(path_preamble)
		button $win.preamble.browse -text [trans browse] -command [list Browse_Dialog_file ::LilyPondIM::config(path_preamble)]
		grid $win.preamble.preamblepath -row 1 -column 1 -sticky w
		grid $win.preamble.path -row 2 -column 1 -sticky w
		grid $win.preamble.browse -row 2 -column 2 -sticky w


		#Footer
		frame $win.footer -class Degt
		pack $win.footer -anchor w
		label $win.footer.label -text "Please enter here the footer for the lilypond documents (default none)"
		text $win.footer.text -background white -borderwidth 1 -relief ridge -width 45 -height 2 -font sboldf
		button $win.footer.default -text [trans default] -command [list ::LilyPondIM::MakeDefault $win.footer.text footer]
		$win.footer.text insert end $::LilyPondIM::config(footer)
		grid $win.footer.label -row 1 -column 1 -sticky w
		grid $win.footer.text -row 2 -column 1 -sticky w
		grid $win.footer.default -row 3 -column 1 -sticky w
	
		#Resolution
		frame $win.res -class Degt
		pack $win.res -anchor w 
		label $win.res.label -text "Resolution (dots per inch) :" -padx 5 -font sboldf
		entry $win.res.value -bg #FFFFFF -width 45 -textvariable ::LilyPondIM::config(resolution)
		grid $win.res.label -row 1 -column 1 -sticky w
		grid $win.res.value -row 2 -column 1 -sticky w
	
	}

	proc MakeDefault { widget var } {
		switch $var {
			header {
				$widget delete 0.0 end
				$widget insert end \
				"\\version \"2.10.25\"\n\\include \"italiano.ly\"\n\\paper\{ragged-right=##t\}\n\\relative do' \{"
			}
			footer {
				$widget delete 0.0 end
				$widget insert end "\}"		
			}
			default { }
		}
	}


	proc SaveTextW {event epvar} {
		upvar 2 evpar args
		upvar 2 name name
		variable win_path
		if { "$name" == "LilyPondIM"} {
			set ::LilyPondIM::config(header) [$win_path.header.text get 0.0 end]
			set ::LilyPondIM::config(footer) [$win_path.footer.text get 0.0 end]			
			#check if the user remove "\\begin\{document\}". users never read warnings !
			#regsub -all {\\begin\{document\}} $::LilyPondIM::config(header) {} ::LilyPondIM::config(header)
		}
	}

	#############################################
	# ::LilyPondIM::Deinit                           #
	# ----------------------------------------- #
	# Closing Procedure                         #
	# (Called by the Plugins System)            #
	#############################################
	proc DeInit { } {
		
		if { [info exists ::env(TEMP) ] } {
			if { [file exists [file join $::env(TEMP) LilyPondIM] ] }  {
				file delete -force [file join $::env(TEMP) LilyPondIM]
			}
		} else {
			if { [file exists [file join /tmp LilyPondIM] ] }  {
				file delete -force [file join /tmp LilyPondIM]
			}
		}
		plugins_log "LilyPondIM" "LilyPond plugin has closed"
	}
	
	#############################################
	# ::LilyPondIM::Create_GIF_from_ly lyInput      #
	# ----------------------------------------- #
	# Turn the $lyInput into a GIF file         #
	# Returns the path to the image             #
	#############################################
	proc Create_GIF_from_ly { lyInput {fortify 0}} {
		
		set oldpwd [pwd]

		if { [info exists ::env(TEMP) ] } {
			set tmp [file join $::env(TEMP) "LilyPondIM-[pid]"]
		} else {
			set tmp [file join /tmp "LilyPondIM-[pid]"]
		}
				catch {file mkdir $tmp}
		
		plugins_log "LilyPondIM" "creating a GIF with the ly code:\n$lyInput"
		set lyInputFile [open [file join $tmp "LilyPondIM.ly"] w]
		puts $lyInputFile "${::LilyPondIM::config(header)}"
		if { [file exists $::LilyPondIM::config(path_preamble) ] } {
			set chan_pre [open $::LilyPondIM::config(path_preamble) r]
			puts $lyInputFile [read $chan_pre]
			close $chan_pre
		}	
		#no document start like \begin{document} in LaTeX

		puts $lyInputFile "${lyInput}"
		
		puts $lyInputFile "${::LilyPondIM::config(footer)}"
		flush $lyInputFile
		close $lyInputFile
		#the following "cd" are needed due to a restriction of Lilypond :(
		#no way to use TEXMFOUTPUT on windows for example.
		cd $tmp	
		catch { exec ${::LilyPondIM::config(path_lilypond)} -fpng --preview \
			                     -dresolution=${::LilyPondIM::config(resolution)} \
			                     LilyPondIM.ly } msg
		cd $oldpwd
		variable ly_errors
		set ly_errors $msg
		if { [file exists [file join $tmp LilyPondIM.preview.png] ] } {
			if { [ catch { exec ${::LilyPondIM::config(path_convert)} -monochrome \
					[file join $tmp LilyPondIM.preview.png] -trim [file join $tmp LilyPondIM.gif] } msg ] == 0 } {
						catch {file delete [file join $tmp "LilyPondIM.png"]}
						catch {file delete [file join $tmp "LilyPondIM.ps"]}
						catch {file delete [file join $tmp "LilyPondIM.preview.png"]}
						catch {file delete [file join $tmp "LilyPondIM.preview.eps"]}
						set tempimg [image create photo -file [file join $tmp LilyPondIM.gif]]
						if {[image height $tempimg] > 1000} {
							set bool [::LilyPondIM::show_bug_dialog $ly_errors]
							if { $bool == 0 } { 
								image delete $tempimg
								return 0 
						}
					}
					image delete $tempimg
					if { $fortify && [package require tclISF 0.3]} {
						tclISF fortify [file join $tmp "LilyPondIM.gif"]
					}
					
					return [file join $tmp "LilyPondIM.gif"]	
				} else { append msg "\n^^Image conversion failed" }
		} else { append msg "\n^^LilyPond failed" }
		cd $oldpwd
		plugins_log "LilyPondIM" $msg
		return 0
	}


	###############################################################
	# ::LilyPondIM::show_bug_dialog {info}                             #
	# ----------------------------------------------------------- #
	# display a kind of bug window                                #
	# info is the output of the lilypond command                     #
	# (called is the image is too big)                            #
	###############################################################
	proc show_bug_dialog {{info ''}} {
		set w .lilypondim_bug
		destroy $w
		toplevel $w -class Dialog
		wm title $w "LilyPondIM Error"
		frame $w.f	
		pack $w.f
		label $w.f.msg -justify left -text "The image is too big.\nMaybe it's normal; but it can either be a bug in your Lilypond code" -wraplength 500 -font sboldf
	
		button $w.f.b1 -text "Ignore this error" -command [list set ::LilyPondIM::kontinue 1 ]
		button $w.f.b2 -text "Don't send or preview the image" -command [list set ::LilyPondIM::kontinue 0 ]
		button $w.f.b3 -text "Show me details" -command [list ::LilyPondIM::toggle_details ]
		text $w.f.details -height 10 -width 10 -bg #FFFFFF
		$w.f.details insert 0.0 $info
		variable details
		set details 0
		pack $w.f.msg -side top -expand 1 -anchor nw -padx 3m -pady 3m
		pack $w.f.b1 $w.f.b2 $w.f.b3 -fill x
		pack $w.f
		update idletasks
		vwait ::LilyPondIM::kontinue
		destroy $w
		return $::LilyPondIM::kontinue
	}
	
    	###############################################################
	# ::LilyPondIM::toggle_details                                     #
	# ----------------------------------------------------------- #
	# Hide or display details of a lilypond error                    #
	# (called by ::LilyPondIM::show_bug_dialog)                        #
	###############################################################
	proc toggle_details { } {
		variable details
		if {$details == 0} {
			pack .lilypondim_bug.f.details -fill both -expand 1
			set details 1
		} else {
			pack forget .lilypondim_bug.f.details
			set details 0
		}
	}

	###############################################################
	# ::LilyPondIM::parseLilyPond event evPar                             #
	# ----------------------------------------------------------- #
	# Check if the text send via the chatwindow begins by "\ly"  #
	# then make an image from this text and send it using an Ink  #
	# (called via an event)                                       #
	###############################################################
	proc parseLilyPond {event evPar} {

		upvar 2 msg msg
		upvar 2 win_name win_name
		if { [string range $msg 0 3] == "\\ly " } { 
			# Strip \ly out
			set lyInput [string range $msg 3 end]
			
			set GifFile [::LilyPondIM::Create_GIF_from_ly $lyInput 1]
			plugins_log "LilyPondIM" "GifFile=\n$GifFile"
			if {$GifFile != 0 } {
				::amsn::InkSend $win_name $GifFile
			} else {
				plugins_log "LilyPondIM" "ERROR WHILE CREATING THE GIF FILE FROM LY : \n$lyInput"
			}
		set msg ""
		}
	}

	#############################################
	# ::LilyPondIM::CreateLyWindow win_name         #
	# ----------------------------------------- #
	# Create the LilypondAdvancedWindow              #
	#############################################	
	proc CreateLyWindow { win_name } {
		if { [winfo exists .lyAdvWin] } {
			raise .lyAdvWin
			return
		}
		toplevel .lyAdvWin
		wm title .lyAdvWin "LilyPondIM advanced window"
		ShowTransient .lyAdvWin
	
		frame .lyAdvWin.ly_Example
		frame .lyAdvWin.ly_Example.examples 
		frame .lyAdvWin.ly_Example.examples.list -class Amsn -borderwidth 0 
		text .lyAdvWin.ly_Example.examples.list.text  -background white -wrap word -yscrollcommand [list .lyAdvWin.ly_Example.examples.list.ys set] -font splainf  -width 30 -height 15
		scrollbar .lyAdvWin.ly_Example.examples.list.ys -command [list .lyAdvWin.ly_Example.examples.list.text yview]
		pack .lyAdvWin.ly_Example.examples.list.ys 	-side right -fill y
		pack .lyAdvWin.ly_Example.examples.list.text -expand true -fill both -padx 1 -pady 1
		pack .lyAdvWin.ly_Example.examples.list 		-side top -expand true -fill both -padx 1 -pady 1
		pack .lyAdvWin.ly_Example.examples  -side left
		.lyAdvWin.ly_Example.examples.list.text configure -state disabled
	
		frame .lyAdvWin.ly_Example.listExamples
		frame .lyAdvWin.ly_Example.listExamples.list -class Amsn -borderwidth 0
		text .lyAdvWin.ly_Example.listExamples.list.text  -background white -wrap word -yscrollcommand [list .lyAdvWin.ly_Example.listExamples.list.ys set] -font splainf  -width 50 -height 15
		scrollbar .lyAdvWin.ly_Example.listExamples.list.ys -command [list .lyAdvWin.ly_Example.listExamples.list.text yview]
		pack .lyAdvWin.ly_Example.listExamples.list.ys 	-side right -fill y
		pack .lyAdvWin.ly_Example.listExamples.list.text -expand true -fill both -padx 1 -pady 1
		pack .lyAdvWin.ly_Example.listExamples.list 		-side top -expand true -fill both -padx 1 -pady 1
		pack .lyAdvWin.ly_Example.listExamples  -side right
		.lyAdvWin.ly_Example.listExamples.list.text configure -state disabled
		
		pack .lyAdvWin.ly_Example
	
		frame .lyAdvWin.ly_code
		frame .lyAdvWin.ly_code.list -class Amsn -borderwidth 0
		text .lyAdvWin.ly_code.list.text  -background white -wrap word -yscrollcommand [list .lyAdvWin.ly_code.list.ys set] -font splainf  -width 10 -height 2
		scrollbar .lyAdvWin.ly_code.list.ys -command [list .lyAdvWin.ly_code.list.text yview]
		pack .lyAdvWin.ly_code.list.ys 	-side right -fill y
		pack .lyAdvWin.ly_code.list.text -expand true -fill both -padx 1 -pady 1
		pack .lyAdvWin.ly_code.list 		-side top -expand true -fill both -padx 1 -pady 1
		pack .lyAdvWin.ly_code 			-expand true -fill both -side bottom
	
		#Complete the two text frames above by parsing some xml files
		::LilyPondIM::ParseMenu ${::LilyPondIM::dir}/datas/menu.xml .lyAdvWin.ly_Example.examples.list.text .lyAdvWin.ly_Example.listExamples.list.text .lyAdvWin.ly_code.list.text
		
		button .lyAdvWin.close -text "Close" -command [list destroy .lyAdvWin]
		bind .lyAdvWin <<Escape>> [list destroy .lyAdvWin]
		
		button .lyAdvWin.preview -text "Preview" -command [list ::LilyPondIM::MakePreview .lyAdvWin.ly_code.list.text]
		button .lyAdvWin.send -text "Send" -command [list ::LilyPondIM::SendFromGUI .lyAdvWin .lyAdvWin.ly_code.list.text $win_name]
		pack .lyAdvWin.close -side right -anchor se -padx 5 -pady 3
		pack .lyAdvWin.preview -side right -anchor se -padx 5 -pady 3
		pack .lyAdvWin.send -side right -anchor se -padx 5 -pady 3
	
	
		.lyAdvWin.ly_code.list.text configure -state normal
	
		update idletasks
		set x [expr {([winfo vrootwidth .lyAdvWin] - [winfo width .lyAdvWin]) / 2}]
		set y [expr {([winfo vrootheight .lyAdvWin] - [winfo height .lyAdvWin]) / 2}]
		wm geometry .lyAdvWin +${x}+${y}	
	}


	####################################################################
	# ::LilyPondIM::SendFromGUI window ly_codeWidget win_name              #
	# ---------------------------------------------------------------- #
	# Send an Ink from the Lilypond code which is on the ly_codeWidget   #
	# The destination user is guessed from $win_name                   #
	# (called by the button "Send" of the LilypondAdvancedWindow)           #
	####################################################################
	proc SendFromGUI { window ly_codeWidget win_name } {
		set lyInput [$ly_codeWidget get 0.0 end]
		destroy $window
		if { [string first "\\ly " $lyInput] == 0 } { 
				set lyInput [string range $lyInput 3 end]
		}
		set GifFile [::LilyPondIM::Create_GIF_from_ly $lyInput 1]
		plugins_log "LilyPondIM" "GifFile=$GifFile"
		if {$GifFile != 0 } {
			 ::amsn::InkSend $win_name $GifFile
		} else {
			plugins_log "LilyPondIM" "ERROR WHILE CREATING THE GIF FILE FROM LY : \n$lyInput"
		}
	}
	

	####################################################################
	# ::LilyPondIM::MakePreview ly_codeWidget                              #
	# ---------------------------------------------------------------- #
	# Display a GIF file from the Lilypond code from the ly_codeWidget   #
	# Create a new window to display it                                #
	# (called by the button "Preview" of the LilypondAdvancedWindow)        #
	####################################################################
	proc MakePreview { ly_codeWidget } {
		plugins_log "LilyPondIM" "$ly_codeWidget"
		set lyInput [$ly_codeWidget get 0.0 end]
		if { [string first "\\ly " $lyInput] == 0 } { 
				set lyInput [string range $lyInput 3 end]
		}
		plugins_log "LilyPondIM" "$lyInput"
		set GifFile [::LilyPondIM::Create_GIF_from_ly $lyInput 0]
		plugins_log "LilyPondIM" "GifFile=$GifFile"
		if {$GifFile != 0 } {
			if { [winfo exists .lyPreviewWin] } {
				raise .lyPreviewWin
				return
			}
			toplevel .lyPreviewWin
			wm title .lyPreviewWin "LilyPondIM Preview window"
			ShowTransient .lyPreviewWin
		
			frame .lyPreviewWin.preview
			frame .lyPreviewWin.preview.list -class Amsn -borderwidth 0 
			text .lyPreviewWin.preview.list.text  -background white -wrap word -font splainf
			scrollbar .lyPreviewWin.preview.list.ys -command {.lyPreviewWin.preview.list.text yview} -orient vertical -autohide 1
			scrollbar .lyPreviewWin.preview.list.xs -command {.lyPreviewWin.preview.list.text xview} -orient horizontal -autohide 1
	
			set imagename [image create photo -file $GifFile -format gif]
	
			.lyPreviewWin.preview.list.text configure -state normal -font bplainf -foreground black -yscrollcommand {.lyPreviewWin.preview.list.ys set} -xscrollcommand {.lyPreviewWin.preview.list.xs set}
			.lyPreviewWin.preview.list.text image create end -name LilyPondIM_Preview -image $imagename -padx 0 -pady 0 
			variable show_errors
			set show_errors 0
			.lyPreviewWin.preview.list.text insert end \n$::LilyPondIM::ly_errors tag_errors
			.lyPreviewWin.preview.list.text tag configure tag_errors -elide true
			.lyPreviewWin.preview.list.text configure -state disabled

			pack .lyPreviewWin.preview.list.ys 	-side right -fill y
			pack .lyPreviewWin.preview.list.xs 	-side bottom -fill x
			pack .lyPreviewWin.preview.list.text -expand true -fill both -padx 1 -pady 1
			pack .lyPreviewWin.preview.list 		-side top -expand true -fill both -padx 1 -pady 1
			pack .lyPreviewWin.preview -fill both
		
			pack .lyPreviewWin.preview
			button .lyPreviewWin.show_errors -text "Show/Hide Lilypond errors" -command [list ::LilyPondIM::show_hide_error_Preview ]
			button .lyPreviewWin.close -text "Close" -command [list destroy .lyPreviewWin]
			bind .lyPreviewWin <<Escape>> [list destroy .lyPreviewWin]
			pack .lyPreviewWin.close -side right -anchor se -padx 5 -pady 3
			pack .lyPreviewWin.show_errors -side right
			update idletasks
			set x [expr {([winfo vrootwidth .lyPreviewWin] - [winfo width .lyPreviewWin]) / 2}]
			set y [expr {([winfo vrootheight .lyPreviewWin] - [winfo height .lyPreviewWin]) / 2}]
			wm geometry .lyPreviewWin +${x}+${y}	
		} else {
			plugins_log "LilyPondIM" "ERROR WHILE CREATING THE GIF FILE FROM LY : \n$lyInput"
		}
	}

	proc show_hide_error_Preview { } {
		variable show_errors
		if {$show_errors == 1 } {
			.lyPreviewWin.preview.list.text tag configure tag_errors -elide true
			set show_errors 0
		} else {
			.lyPreviewWin.preview.list.text tag configure tag_errors -elide false
			set show_errors 1
		}
	}
	
	###################################################################
	# ::LilyPondIM::AddLyButton event evpar                               #
	# --------------------------------------------------------------- #
	# Add a button in the chatwindow in order to have an easy access  #
	# to the LilypondAdvancedWindow                                        #
	# (called by an event when a ChatWindow is created                #
	###################################################################
	proc AddLyButton { event evpar } {
		upvar 2 $evpar newvar

		set lyButton $newvar(bottom).lyButton
		label $lyButton -image [::skin::loadPixmap buttonLy] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		
		bind $lyButton  <<Button1>> [list ::LilyPondIM::CreateLyWindow $newvar(window_name)]
		bind $lyButton  <Enter> [list $lyButton configure -image [::skin::loadPixmap buttonLy_hover]]
		bind $lyButton  <Leave> [list $lyButton configure -image [::skin::loadPixmap buttonLy]]
		pack $lyButton -side left -padx 0 -pady 0	
		plugins_log "LilyPondIM" "LilyPondIM button added the new window: $newvar(window_name)"
		
	}


	##################################################################
	# ::LilyPondIM::ParseMenu xmlfile textWidget1 textWidget2 textWidget3 #
	# -------------------------------------------------------------- #
	# Complete the textWidget1 by datas parsed from the xml file     #
	# textWidget2 and textWidget3 are used by ParseLyAndImages      #
	# (called when the LilypondAdvancedWindow is created)                 #
	##################################################################
	proc ParseMenu { xmlfile textWidget1 textWidget2 textWidget3} {

		set textline {}
		set dir {}
		set title {}
		set pos1 {}
		set pos2 {}

		if {[catch {open $xmlfile "r"} fileXML]} {
			plugins_log "LilyPondIM" "error when reading $xmlfile : $fileXML"
		}
		$textWidget1 configure -state normal
		#1st line
		gets $fileXML textline
		while {[eof $fileXML] != 1} {
			if {[string match *<ITEM>* $textline]} {
				gets $fileXML textline
				set pos1 [expr [string first <DIR> $textline] + 5]
				set pos2 [expr [string first </DIR> $textline] - 1]
				set dir [string range $textline $pos1 $pos2]
				gets $fileXML textline
				set pos1 [expr [string first <TITLE> $textline] + 7]
				set pos2 [expr [string first </TITLE> $textline] - 1]
				set title [string range $textline $pos1 $pos2]
				$textWidget1 tag configure $dir -foreground black -font splainf -underline true
				$textWidget1 tag bind $dir <Enter> [list $textWidget1 tag conf $dir -underline true; $textWidget1 conf -cursor hand2]
				$textWidget1 tag bind $dir <Leave> [list $textWidget1 tag conf $dir -underline false; $textWidget1 conf -cursor xterm]
				$textWidget1 tag bind $dir <Button1-ButtonRelease> [list ::LilyPondIM::ParseLyAndImages $dir $textWidget2 $textWidget3]
				$textWidget1 insert end "$title\n" $dir
			}
			gets $fileXML textline
		}
		$textWidget1 configure -state disabled
		close $fileXML
	}

	##################################################################
	# ::LilyPondIM::ParseLyAndImages dir textWidget1 textWidget2         #
	# -------------------------------------------------------------- #
	# Complete the textWidget1 by datas parsed from the xml file :   #
	#  ${::LilyPondIM::dir}/datas/${dir}.xml                             #
	# dir is the directory where the GIF files are.                  #
	# textWidget2 is the text widget where some datas would be added #
	# if the user clic in the textWidget2                            #
	# (called from ParseMenu)                                        #
	##################################################################
	proc ParseLyAndImages { dir textWidget2 textWidget3} {
		set xmlfile ${::LilyPondIM::dir}/datas/${dir}.xml
		set path2dir ${::LilyPondIM::dir}/datas/${dir}/
		set label {}
		set textline {}
		set ly {}
		set img {}
		set pos1 {}
		set pos2 {}

		if {[catch {open $xmlfile "r"} fileXML]} {
			plugins_log "LilyPondIM" "error when reading $xmlfile : $fileXML"
		}
		$textWidget2 configure -state normal
		$textWidget2 delete 0.0 end
		#1st line
		gets $fileXML textline
		#2nd line
		gets $fileXML textline
		set pos1 [string first <label> $textline]
		if {$pos1 != -1} {
			set pos2 [expr [string first </label> $textline] - 1]
			set pos1 [expr $pos1 + 7 ]
			set label [string range $textline $pos1 $pos2]
			$textWidget2 tag configure a_label -foreground red -font splainf -underline false
			$textWidget2 insert end "$label\n" a_label
		}
		$textWidget2 configure -font bplainf -foreground black
		while {[eof $fileXML] != 1} {
			if {[string match *<item>* $textline]} {
				gets $fileXML textline
				set pos1 [expr [string first <ly> $textline] + 4]
				set pos2 [expr [string first </ly> $textline] - 1]
				set ly [string range $textline $pos1 $pos2]
				gets $fileXML textline
				set pos1 [expr [string first <img> $textline] + 5]
				set pos2 [expr [string first </img> $textline] - 1]
				set img [string range $textline $pos1 $pos2]
				set imagename [image create photo -file ${path2dir}${img}.gif -format gif]
				$textWidget2 image create end -name img_$img -image $imagename -padx 0 -pady 0 
				$textWidget2 tag configure $img -foreground black -font splainf -underline true
				$textWidget2 tag bind $img <Enter> [list $textWidget2 tag conf $img -underline true; $textWidget2 conf -cursor hand2 ]
				$textWidget2 tag bind $img <Leave> [list $textWidget2 tag conf $img -underline false; $textWidget2 conf -cursor xterm]
				$textWidget2 tag bind $img <Button1-ButtonRelease> [list $textWidget3 insert end $ly]
				$textWidget2 insert end "\n$ly\n" $img
				$textWidget2 image create end -image [::skin::loadPixmap greyline]
				$textWidget2 insert end "\n\n" $img
			}
			gets $fileXML textline
		}
		$textWidget2 configure -state disabled
		close $fileXML
	}


}
