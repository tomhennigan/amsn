# Copyright Andrei Barbu (abarbu@uwaterloo.ca)
# Copyright Boris FAURE (billiob@gmail.com)
# Based on the good work from Andrei Barbu (abarbu@uwaterloo.ca)
# This code is distributed under the GPL

#TODO, add translation support
namespace eval ::TeXIM {
	
	#############################################
	# ::TeXIM::Init                             #
	# ----------------------------------------- #
	# Initialization Procedure                  #
	# (Called by the Plugins System)            #
	#############################################
	proc Init { directory } {
		global HOME
		plugins_log "TeXIM" "LaTeX plugin has started"

		::plugins::RegisterPlugin "TeXIM"
		::plugins::RegisterEvent "TeXIM" PluginConfigured SaveTextW
		::plugins::RegisterEvent "TeXIM" chat_msg_send parseLaTeX	
		::plugins::RegisterEvent "TeXIM" chatwindowbutton AddTexButton

		#TODO, fix amsn string support, it doesn't put it by default to what it says in config
		#TODO, add a multiline input box for header and footer
		#TODO, make a real config window
		array set ::TeXIM::config {
			path_latex {latex}
			path_dvips {dvips}
			path_convert {convert}
			resolution {120}
			header "\\documentclass\[12pt\]\{article\}\n\
				\\pagestyle\{empty\}\n\
				\\begin\{document\}"	
			footer "\\end\{document\}"
			dir {}
		}
		set ::config(dir) $directory

		::skin::setPixmap buttonTex tex.png pixmaps [file join $directory pixmaps]

		set ::TeXIM::configlist [list [list frame ::TeXIM::populateFrame ""] ]

		if { [file exists [file join $HOME "TeXIM/"] ] == 0 }  {
			file mkdir [file join $HOME "TeXIM/"]
		}
	}
	
	proc populateFrame { win } {
		variable win_path
		set win_path $win
		#Path To Latex
		frame $win.latex -class Degt
		pack $win.latex -anchor w
		label $win.latex.latexpath -text "Path to latex binary :" -padx 5 -font sboldf
		entry $win.latex.path -bg #FFFFFF -width 45 -textvariable ::TeXIM::config(path_latex)
		button $win.latex.browse -text [trans browse] -command "Browse_Dialog_file ::TeXIM::config(path_latex)" 

		grid $win.latex.latexpath -row 1 -column 1 -sticky w
		grid $win.latex.path -row 2 -column 1 -sticky w
		grid $win.latex.browse -row 2 -column 2 -sticky w

		#Path To Dvips
		frame $win.dvips -class Degt
		pack $win.dvips -anchor w 
		label $win.dvips.dvipspath -text "Path to dvips binary :" -padx 5 -font sboldf
		entry $win.dvips.path -bg #FFFFFF -width 45 -textvariable ::TeXIM::config(path_dvips)
		button $win.dvips.browse -text [trans browse] -command "Browse_Dialog_file ::TeXIM::config(path_dvips)"
		grid $win.dvips.dvipspath -row 1 -column 1 -sticky w
		grid $win.dvips.path -row 2 -column 1 -sticky w
		grid $win.dvips.browse -row 2 -column 2 -sticky w

		#Path To Convert
		frame $win.convert -class Degt
		pack $win.convert -anchor w 
		label $win.convert.convertpath -text "Path to convert binary :" -padx 5 -font sboldf
		entry $win.convert.path -bg #FFFFFF -width 45 -textvariable ::TeXIM::config(path_convert)
		button $win.convert.browse -text [trans browse] -command "Browse_Dialog_File ::TeXIM::config(path_convert)"
		grid $win.convert.convertpath -row 1 -column 1 -sticky w
		grid $win.convert.path -row 2 -column 1 -sticky w
		grid $win.convert.browse -row 2 -column 2 -sticky w

		#Header
		frame $win.header -class Degt
		pack $win.header -anchor w
		label $win.header.label -text "Put here what is the header of the tex file"
		text $win.header.text -background white -borderwidth 1 -relief ridge -width 45 -height 5 -font splainf
		button $win.header.default -text [trans default] -command "::TeXIM::MakeDefault $win.header.text header"
		$win.header.text insert end $::TeXIM::config(header)
		grid $win.header.label -row 1 -column 1 -sticky w
		grid $win.header.text -row 2 -column 1 -sticky w
		grid $win.header.default -row 3 -column 1 -sticky w
		
		#Footer
		frame $win.footer -class Degt
		pack $win.footer -anchor w
		label $win.footer.label -text "Put here what is the footer of the tex file"
		text $win.footer.text -background white -borderwidth 1 -relief ridge -width 45 -height 5 -font splainf
		button $win.footer.default -text [trans default] -command "::TeXIM::MakeDefault $win.footer.text footer"
		$win.footer.text insert end $::TeXIM::config(footer)
		grid $win.footer.label -row 1 -column 1 -sticky w
		grid $win.footer.text -row 2 -column 1 -sticky w
		grid $win.footer.default -row 3 -column 1 -sticky w
	
		#Resolution
		frame $win.res -class Degt
		pack $win.res -anchor w 
		label $win.res.label -text "Resolution (dots per inch) :" -padx 5 -font sboldf
		entry $win.res.value -bg #FFFFFF -width 45 -textvariable ::TeXIM::config(resolution)
		grid $win.res.label -row 1 -column 1 -sticky w
		grid $win.res.value -row 2 -column 1 -sticky w
	
	}

	proc MakeDefault { widget var } {
		switch $var {
			header {
				$widget delete 0.0 end
				$widget insert end "\\documentclass\[12pt\]\{article\}\n\
							\\pagestyle\{empty\}\n\
							\\begin\{document\}"
			}
			footer {
				$widget delete 0.0 end
				$widget insert end "\\end\{document\}"		
			}
			default { }
		}
	}


	proc SaveTextW {event epvar} {
		upvar 2 evpar args
		upvar 2 name name
		variable win_path
		if { "$name" == "TeXIM"} {
			set ::TeXIM::config(header) [$win_path.header.text get 0.0 end]
			set ::TeXIM::config(footer) [$win_path.footer.text get 0.0 end]			
		}
	}

	#############################################
	# ::TeXIM::Deinit                           #
	# ----------------------------------------- #
	# Closing Procedure                         #
	# (Called by the Plugins System)            #
	#############################################
	proc DeInit { } {
		global HOME
		if { [file exists [file join $HOME "TeXIM/"] ] }  {
			file delete -force [file join $HOME "TeXIM/"]
		}
		plugins_log "TeXIM" "LaTeX plugin has closed"
	}
	
	#############################################
	# ::TeXIM::Create_GIF_from_Tex texText      #
	# ----------------------------------------- #
	# Turn the $texText into a GIF file         #
	# Returns the path to the image             #
	#############################################
	proc Create_GIF_from_Tex { texText } {
		global HOME
		set oldpwd [pwd]
		cd [file join $HOME "TeXIM/" ]
		
		plugins_log "TeXIM" "creating a GIF with the tex code:\n$texText"
		set fileXMLtex [open "TeXIM.tex" w]
		#puts $fileXMLtex "\\documentclass\[12pt\]\{article\}"
		#puts $fileXMLtex "\\pagestyle\{empty\}"
		#puts $fileXMLtex "\\begin\{document\}"
		puts $fileXMLtex "${::TeXIM::config(header)}"
		
		puts $fileXMLtex "${texText}"
		
		puts $fileXMLtex "${::TeXIM::config(footer)}"
		flush $fileXMLtex
		close $fileXMLtex
		catch { exec $::TeXIM::config(path_latex) -interaction=nonstopmode TeXIM.tex } msg
		variable tex_errors
		set tex_errors $msg
		if { [file exists TeXIM.dvi ] }  {
			if { [ catch { exec $::TeXIM::config(path_dvips) -f -E -o TeXIM.ps -q TeXIM.dvi } msg ] == 0 } { 
				catch {file delete [file join $HOME "TeXIM.dvi"]}
				if { [ catch { exec $::TeXIM::config(path_convert) -density $::TeXIM::config(resolution) \
							TeXIM.ps TeXIM.gif } msg ] == 0 } {
					set tmp [image create photo -file TeXIM.gif]
					if {[image height $tmp] > 1000} {
						set bool [::TeXIM::show_bug_dialog $tex_errors]
						if { $bool == 0 } { 
							image delete $tmp
							return 0 
						}
					}
					image delete $tmp
					catch {file delete TeXIM.dvi}
					cd $oldpwd
					return [file join $HOME "TeXIM/" "TeXIM.gif"]
				}
			}
		}
		plugins_log "TeXIM" $msg
		cd $oldpwd
		return 0
	}


	###############################################################
	# ::TeXIM::show_bug_dialog {info}                             #
	# ----------------------------------------------------------- #
	# display a kind of bug window                                #
	# info is the output of the latex command                     #
	# (called is the image is too big)                            #
	###############################################################
	proc show_bug_dialog {{info ''}} {
		set w .texim_bug
		destroy $w
		toplevel $w -class Dialog
		wm title $w "TeXIM Error"
		frame $w.f	
		pack $w.f
		label $w.f.msg -justify left -text "The image is too big.\nMaybe it's normal; but it can either be a bug in you TeX code" -wraplength 500 -font sboldf
	
		button $w.f.b1 -text "Ignore this error" -command "set ::TeXIM::kontinue 1 "
		button $w.f.b2 -text "Don't send or preview the image" -command "set ::TeXIM::kontinue 0 "
		button $w.f.b3 -text "Show me details" -command "::TeXIM::toggle_details "
		text $w.f.details -height 10 -width 10 -bg #FFFFFF
		$w.f.details insert 0.0 $info
		variable details
		set details 0
		pack $w.f.msg -side top -expand 1 -anchor nw -padx 3m -pady 3m
		pack $w.f.b1 $w.f.b2 $w.f.b3 -fill x
		pack $w.f
		update idletasks
		vwait ::TeXIM::kontinue
		destroy $w
		return $::TeXIM::kontinue
	}
	
    	###############################################################
	# ::TeXIM::toggle_details                                     #
	# ----------------------------------------------------------- #
	# Hide or display details of a latex error                    #
	# (called by ::TeXIM::show_bug_dialog)                        #
	###############################################################
	proc toggle_details { } {
		variable details
		if {$details == 0} {
			pack .texim_bug.f.details -fill both -expand 1
			set details 1
		} else {
			pack forget .texim_bug.f.details
			set details 0
		}
	}

	###############################################################
	# ::TeXIM::parseLaTeX event evPar                             #
	# ----------------------------------------------------------- #
	# Check if the text send via the chatwindow begins by "\tex"  #
	# then make an image from this text and send it using an Ink  #
	# (called via an event)                                       #
	###############################################################
	proc parseLaTeX {event evPar} {

		upvar 2 msg msg
		status_log "$msg" green
		upvar 2 win_name win_name
		if { [string range $msg 0 4] == "\\tex " } { 
			# Strip \tex out
			set texText [string range $msg 4 end]
			
			set GifFile [::TeXIM::Create_GIF_from_Tex $texText ]
			plugins_log "TeXIM" "GifFile=\n$GifFile"
			if {$GifFile != 0 } {
				::amsn::InkSend $win_name $GifFile
			} else {
				plugins_log "TeXIM" "ERROR WHILE CREATING THE GIF FILE FROM TEX : \n$texText"
			}
		set msg ""
		}
	}

	#############################################
	# ::TeXIM::CreateTexWindow win_name         #
	# ----------------------------------------- #
	# Create the TeXAdvancedWindow              #
	#############################################	
	proc CreateTexWindow { win_name } {
		if { [winfo exists .texAdvWin] } {
			raise .texAdvWin
			return
		}
		toplevel .texAdvWin
		wm title .texAdvWin "TeXIM advanced window"
		ShowTransient .texAdvWin
	
		frame .texAdvWin.tex_Example
		frame .texAdvWin.tex_Example.examples 
		frame .texAdvWin.tex_Example.examples.list -class Amsn -borderwidth 0 
		text .texAdvWin.tex_Example.examples.list.text  -background white -wrap word -yscrollcommand ".texAdvWin.tex_Example.examples.list.ys set" -font splainf  -width 30 -height 30
		scrollbar .texAdvWin.tex_Example.examples.list.ys -command ".texAdvWin.tex_Example.examples.list.text yview"
		pack .texAdvWin.tex_Example.examples.list.ys 	-side right -fill y
		pack .texAdvWin.tex_Example.examples.list.text -expand true -fill both -padx 1 -pady 1
		pack .texAdvWin.tex_Example.examples.list 		-side top -expand true -fill both -padx 1 -pady 1
		pack .texAdvWin.tex_Example.examples  -side left
		.texAdvWin.tex_Example.examples.list.text configure -state disabled
	
		frame .texAdvWin.tex_Example.listExamples
		frame .texAdvWin.tex_Example.listExamples.list -class Amsn -borderwidth 0
		text .texAdvWin.tex_Example.listExamples.list.text  -background white -wrap word -yscrollcommand ".texAdvWin.tex_Example.listExamples.list.ys set" -font splainf  -width 50 -height 30
		scrollbar .texAdvWin.tex_Example.listExamples.list.ys -command ".texAdvWin.tex_Example.listExamples.list.text yview"
		pack .texAdvWin.tex_Example.listExamples.list.ys 	-side right -fill y
		pack .texAdvWin.tex_Example.listExamples.list.text -expand true -fill both -padx 1 -pady 1
		pack .texAdvWin.tex_Example.listExamples.list 		-side top -expand true -fill both -padx 1 -pady 1
		pack .texAdvWin.tex_Example.listExamples  -side right
		.texAdvWin.tex_Example.listExamples.list.text configure -state disabled
		
		pack .texAdvWin.tex_Example
	
		frame .texAdvWin.tex_code
		frame .texAdvWin.tex_code.list -class Amsn -borderwidth 0
		text .texAdvWin.tex_code.list.text  -background white -wrap word -yscrollcommand ".texAdvWin.tex_code.list.ys set" -font splainf  -width 10 -height 2
		scrollbar .texAdvWin.tex_code.list.ys -command ".texAdvWin.tex_code.list.text yview"
		pack .texAdvWin.tex_code.list.ys 	-side right -fill y
		pack .texAdvWin.tex_code.list.text -expand true -fill both -padx 1 -pady 1
		pack .texAdvWin.tex_code.list 		-side top -expand true -fill both -padx 1 -pady 1
		pack .texAdvWin.tex_code 			-expand true -fill both -side bottom
	
		#Complete the two text frames above by parsing some xml files
		::TeXIM::ParseMenu ${::config(dir)}/datas/menu.xml .texAdvWin.tex_Example.examples.list.text .texAdvWin.tex_Example.listExamples.list.text .texAdvWin.tex_code.list.text
		
		button .texAdvWin.close -text "Close" -command "destroy .texAdvWin"
		bind .texAdvWin <<Escape>> "destroy .texAdvWin"
		
		button .texAdvWin.preview -text "Preview" -command "::TeXIM::MakePreview .texAdvWin.tex_code.list.text "
		button .texAdvWin.send -text "Send" -command "::TeXIM::SendFromGUI .texAdvWin .texAdvWin.tex_code.list.text $win_name"
		pack .texAdvWin.close -side right -anchor se -padx 5 -pady 3
		pack .texAdvWin.preview -side right -anchor se -padx 5 -pady 3
		pack .texAdvWin.send -side right -anchor se -padx 5 -pady 3
	
	
		.texAdvWin.tex_code.list.text configure -state normal
	
		update idletasks
		set x [expr {([winfo vrootwidth .texAdvWin] - [winfo width .texAdvWin]) / 2}]
		set y [expr {([winfo vrootheight .texAdvWin] - [winfo height .texAdvWin]) / 2}]
		wm geometry .texAdvWin +${x}+${y}	
	}


	####################################################################
	# ::TeXIM::SendFromGUI window tex_codeWidget win_name              #
	# ---------------------------------------------------------------- #
	# Send an Ink from the Tex's code which is on the tex_codeWidget   #
	# The destination user is guessed from $win_name                   #
	# (called by the button "Send" of the TeXAdvancedWindow)           #
	####################################################################
	proc SendFromGUI { window tex_codeWidget win_name } {
		set texText [$tex_codeWidget get 0.0 end]
		destroy $window
		if { [string first "\\tex " $texText] == 0 } { 
				set texText [string range $texText 4 end]
		}
		set GifFile [::TeXIM::Create_GIF_from_Tex $texText ]
		plugins_log "TeXIM" "GifFile=$GifFile"
		if {$GifFile != 0 } {
			 ::amsn::InkSend $win_name $GifFile
		} else {
			plugins_log "TeXIM" "ERROR WHILE CREATING THE GIF FILE FROM TEX : \n$texText"
		}
	}
	

	####################################################################
	# ::TeXIM::MakePreview tex_codeWidget                              #
	# ---------------------------------------------------------------- #
	# Display a GIF file from the Tex's code from the tex_codeWidget   #
	# Create a new window to display it                                #
	# (called by the button "Preview" of the TeXAdvancedWindow)        #
	####################################################################
	proc MakePreview { tex_codeWidget } {
		plugins_log "TeXIM" "$tex_codeWidget"
		set texText [$tex_codeWidget get 0.0 end]
		if { [string first "\\tex " $texText] == 0 } { 
				set texText [string range $texText 4 end]
		}
		plugins_log "TeXIM" "$texText"
		set GifFile [::TeXIM::Create_GIF_from_Tex $texText ]
		plugins_log "TeXIM" "GifFile=$GifFile"
		if {$GifFile != 0 } {
			if { [winfo exists .texPreviewWin] } {
				raise .texPreviewWin
				return
			}
			toplevel .texPreviewWin
			wm title .texPreviewWin "TeXIM Preview window"
			ShowTransient .texPreviewWin
		
			frame .texPreviewWin.preview
			frame .texPreviewWin.preview.list -class Amsn -borderwidth 0 
			text .texPreviewWin.preview.list.text  -background white -wrap word -font splainf
			scrollbar .texPreviewWin.preview.list.ys -command {.texPreviewWin.preview.list.text yview} -orient vertical -autohide 1
			scrollbar .texPreviewWin.preview.list.xs -command {.texPreviewWin.preview.list.text xview} -orient horizontal -autohide 1
	
			set imagename [image create photo -file $GifFile -format gif]
	
			.texPreviewWin.preview.list.text configure -state normal -font bplainf -foreground black -yscrollcommand {.texPreviewWin.preview.list.ys set} -xscrollcommand {.texPreviewWin.preview.list.xs set}
			.texPreviewWin.preview.list.text image create end -name TeXIM_Preview -image $imagename -padx 0 -pady 0 
	
			pack .texPreviewWin.preview.list.ys 	-side right -fill y
			pack .texPreviewWin.preview.list.xs 	-side bottom -fill x
			pack .texPreviewWin.preview.list.text -expand true -fill both -padx 1 -pady 1
			pack .texPreviewWin.preview.list 		-side top -expand true -fill both -padx 1 -pady 1
			pack .texPreviewWin.preview -fill both
			.texPreviewWin.preview.list.text configure -state disabled
		
			pack .texPreviewWin.preview
			button .texPreviewWin.show_errors -text "Show TeX errors" -command "::TeXIM::show_error "
			button .texPreviewWin.close -text "Close" -command "destroy .texPreviewWin"
			bind .texPreviewWin <<Escape>> "destroy .texPreviewWin"
			pack .texPreviewWin.close -side right -anchor se -padx 5 -pady 3
			pack .texPreviewWin.show_errors -side right
			update idletasks
			set x [expr {([winfo vrootwidth .texPreviewWin] - [winfo width .texPreviewWin]) / 2}]
			set y [expr {([winfo vrootheight .texPreviewWin] - [winfo height .texPreviewWin]) / 2}]
			wm geometry .texPreviewWin +${x}+${y}	
		} else {
			plugins_log "TeXIM" "ERROR WHILE CREATING THE GIF FILE FROM TEX : \n$texText"
		}
	}

	proc show_error { } {
		.texPreviewWin.preview.list.text configure -state normal
		.texPreviewWin.preview.list.text insert end \n$::TeXIM::tex_errors
		.texPreviewWin.preview.list.text configure -state disabled 
	}
	
	###################################################################
	# ::TeXIM::AddTexButton event evpar                               #
	# --------------------------------------------------------------- #
	# Add a button in the chatwindow in order to have an easy access  #
	# to the TeXAdvancedWindow                                        #
	# (called by an event when a ChatWindow is created                #
	###################################################################
	proc AddTexButton { event evpar } {
		upvar 2 $evpar newvar

		set texButton $newvar(bottom).texButton
		label $texButton -image [::skin::loadPixmap buttonTex] -relief flat -padx 0 \
			-background [::skin::getKey buttonbarbg] -highlightthickness 0 -borderwidth 0 \
			-highlightbackground [::skin::getKey buttonbarbg] -activebackground [::skin::getKey buttonbarbg]
		
		bind $texButton  <<Button1>> "::TeXIM::CreateTexWindow $newvar(window_name)"
		bind $texButton  <Enter> "$texButton configure -image [::skin::loadPixmap buttonTex]"
		bind $texButton  <Leave> "$texButton configure -image [::skin::loadPixmap buttonTex]"	
		pack $texButton -side left -padx 0 -pady 0	
		plugins_log "TeXIM" "TeXIM button added the new window: $newvar(window_name)"
		
	}


	##################################################################
	# ::TeXIM::ParseMenu xmlfile textWidget1 textWidget2 textWidget3 #
	# -------------------------------------------------------------- #
	# Complete the textWidget1 by datas parsed from the xml file     #
	# textWidget2 and textWidget3 are used by ParseTexAndImages      #
	# (called when the TeXAdvancedWindow is created)                 #
	##################################################################
	proc ParseMenu { xmlfile textWidget1 textWidget2 textWidget3} {

		set textline {}
		set dir {}
		set title {}
		set pos1 {}
		set pos2 {}

		if {[catch {open $xmlfile "r"} fileXML]} {
			plugins_log "TeXIM" "error when reading $xmlfile : $fileXML"
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
				$textWidget1 tag bind $dir <Enter> "$textWidget1 tag conf $dir -underline true; $textWidget1 conf -cursor hand2"
				$textWidget1 tag bind $dir <Leave> "$textWidget1 tag conf $dir -underline false; $textWidget1 conf -cursor xterm"
				$textWidget1 tag bind $dir <Button1-ButtonRelease> "$textWidget1 conf -cursor watch; ::TeXIM::ParseTexAndImages $dir $textWidget2 $textWidget3"
				$textWidget1 insert end "$title\n" $dir
			}
			gets $fileXML textline
		}
		$textWidget1 configure -state disabled
		close $fileXML
	}

	##################################################################
	# ::TeXIM::ParseTexAndImages dir textWidget1 textWidget2         #
	# -------------------------------------------------------------- #
	# Complete the textWidget1 by datas parsed from the xml file :   #
	#  ${::config(dir)}/datas/${dir}.xml                             #
	# dir is the directory where the GIF files are.                  #
	# textWidget2 is the text widget where some datas would be added #
	# if the user clic in the textWidget2                            #
	# (called from ParseMenu)                                        #
	##################################################################
	proc ParseTexAndImages { dir textWidget1 textWidget2} {
		set xmlfile ${::config(dir)}/datas/${dir}.xml
		set path2dir ${::config(dir)}/datas/${dir}/
		set label {}
		set textline {}
		set tex {}
		set img {}
		set pos1 {}
		set pos2 {}

		if {[catch {open $xmlfile "r"} fileXML]} {
			plugins_log "TeXIM" "error when reading $xmlfile : $fileXML"
		}
		$textWidget1 configure -state normal
		$textWidget1 delete 0.0 end
		#1st line
		gets $fileXML textline
		#2nd line
		gets $fileXML textline
		set pos1 [string first <label> $textline]
		if {$pos1 != -1} {
			set pos2 [expr [string first </label> $textline] - 1]
			set pos1 [expr $pos1 + 7 ]
			set label [string range $textline $pos1 $pos2]
			$textWidget1 tag configure a_label -foreground red -font splainf -underline false
			$textWidget1 insert end "$label\n" a_label
		}
		$textWidget1 configure -font bplainf -foreground black
		while {[eof $fileXML] != 1} {
			if {[string match *<item>* $textline]} {
				gets $fileXML textline
				set pos1 [expr [string first <tex> $textline] + 5]
				set pos2 [expr [string first </tex> $textline] - 1]
				set tex [string range $textline $pos1 $pos2]
				gets $fileXML textline
				set pos1 [expr [string first <img> $textline] + 5]
				set pos2 [expr [string first </img> $textline] - 1]
				set img [string range $textline $pos1 $pos2]
				set imagename [image create photo -file ${path2dir}${img}.gif -format gif]
				$textWidget1 image create end -name img_$img -image $imagename -padx 0 -pady 0 
				$textWidget1 tag configure $img -foreground black -font splainf -underline true
				$textWidget1 tag bind $img <Enter> "$textWidget1 tag conf $img -underline true; $textWidget1 conf -cursor hand2"
				$textWidget1 tag bind $img <Leave> "$textWidget1 tag conf $img -underline false; $textWidget1 conf -cursor xterm"
				$textWidget1 tag bind $img <Button1-ButtonRelease> "$textWidget1 conf -cursor watch; $textWidget2 insert end {$tex}"
				$textWidget1 insert end "  $tex\n\n" $img
			}
			gets $fileXML textline
		}
		$textWidget1 configure -state disabled
		close $fileXML
	}


}
