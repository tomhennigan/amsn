package require AMSN_BWidget
if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
	#Use QuickeTimeTcl on Mac OS X to play sounds
	package require QuickTimeTcl
}

if { $initialize_amsn == 1 } {
	init_ticket putmessage
	
	::skin::setKey mainwindowbg #7979f2
	::skin::setKey chatwindowbg #EAEAEA
	::skin::setKey buttonbarbg #eeeeff
	::skin::setKey topbarbg #5050e5
	::skin::setKey topbartext #ffffff
	::skin::setKey topbarawaybg #00AB00
	::skin::setKey topbarawaytext #000000
	::skin::setKey topbarbusybg #CF0000
	::skin::setKey topbarbusytext #000000
	::skin::setKey topbarofflinebg #404040
	::skin::setKey topbarofflinetext #ffffff
	::skin::setKey statusbarbg #eeeeee
	::skin::setKey statusbartext #000000
	
	::skin::setKey chat_top_padx 0
	::skin::setKey chat_top_pady 0
	::skin::setKey chat_paned_padx 0
	::skin::setKey chat_paned_pady 0
	::skin::setKey chat_output_padx 0
	::skin::setKey chat_output_pady 0
	::skin::setKey chat_buttons_padx 0
	::skin::setKey chat_buttons_pady 0
	::skin::setKey chat_input_padx 0
	::skin::setKey chat_input_pady 0
	::skin::setKey chat_dp_padx 0
	::skin::setKey chat_dp_pady 0
	::skin::setKey chat_leftframe_padx 0
	::skin::setKey chat_leftframe_pady 0
	::skin::setKey chat_sendbutton_padx 0
	::skin::setKey chat_sendbutton_pady 0
	::skin::setKey chat_status_padx 0
	::skin::setKey chat_status_pady 0	
	
	::skin::setKey chat_top_border 0
	::skin::setKey chat_output_border 0
	::skin::setKey chat_buttons_border 0
	::skin::setKey chat_input_border 0
	::skin::setKey chat_status_border 0
	
	::skin::setKey menuforeground #000000 
	::skin::setKey menuactivebackground #565672
	::skin::setKey menuactiveforeground #ffffff
	::skin::setKey balloontext #000000 

	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		::skin::setKey balloonbackground #ffffca
		::skin::setKey menubackground #ECECEC 
	} else {
		::skin::setKey balloonbackground #ffffaa
		::skin::setKey menubackground #eae7e4
	}

	::skin::setKey balloonborder #000000

	#Virtual events used by Button-click
	#On Mac OS X, Control emulate the "right click button"
	#On Mac OS X, there's a mistake between button2 and button3
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		event add <<Button1>> <Button1-ButtonRelease>
		event add <<Button2>> <Button3-ButtonRelease>
		event add <<Button3>> <Control-ButtonRelease>
		event add <<Button3>> <Button2-ButtonRelease>
		event add <<Escape>> <Command-w> <Command-W>
		event add <<Paste>> <Command-v> <Command-V>
		event add <<Copy>> <Command-c> <Command-C>
		event add <<Cut>> <Command-x> <Command-X>
	} else {
		event add <<Button1>> <Button1-ButtonRelease>
		event add <<Button2>> <Button2-ButtonRelease>
		event add <<Button3>> <Button3-ButtonRelease>
		event add <<Escape>> <Escape>
		event add <<Paste>> <Control-v> <Control-V>
		event add <<Copy>> <Control-c> <Control-C>
		event add <<Cut>> <Control-x> <Control-X>
	}
}

namespace eval ::amsn {

	namespace export initLook aboutWindow showHelpFile errorMsg infoMsg \
		blockUnblockUser blockUser unblockUser deleteUser \
		fileTransferRecv fileTransferProgress \
		errorMsg notifyAdd initLook messageFrom userJoins userLeaves \
		updateTypers ackMessage nackMessage chatUser

	##PUBLIC

	proc initLook { family size bgcolor} {
		global tcl_platform

		font create menufont -family $family -size $size -weight normal
		font create sboldf -family $family -size $size -weight bold
		font create splainf -family $family -size $size -weight normal
		font create sbolditalf -family $family -size $size -weight bold -slant italic
		font create macfont -family [list {Lucida Grande}] -size 13 -weight normal

		if { [::config::getKey strictfonts] } {
			font create bboldf -family $family -size $size -weight bold
			font create bboldunderf -family $family -size $size -weight bold -underline true
			font create bplainf -family $family -size $size -weight normal
			font create bigfont -family $family -size $size -weight bold
			font create examplef -family $family -size $size -weight normal
		} else {
			font create bboldf -family $family -size [expr {$size+1}] -weight bold
			font create bboldunderf -family $family -size [expr {$size+1}] -weight bold -underline true
			font create bplainf -family $family -size [expr {$size+1}] -weight normal
			font create bigfont -family $family -size [expr {$size+2}] -weight bold
			font create examplef -family $family -size [expr {$size-2}] -weight normal
		}

		catch {tk_setPalette [::skin::getKey menubackground]}
		option add *Menu.font menufont
		
		option add *selectColor #DD0000

		if { ![catch {tk windowingsystem} wsystem] && $wsystem  == "x11" } {
			option add *background [::skin::getKey menubackground]
			
			option add *borderWidth 1 widgetDefault
			option add *activeBorderWidth 1 widgetDefault
			option add *selectBorderWidth 1 widgetDefault

			option add *Listbox.background white widgetDefault
			option add *Listbox.selectBorderWidth 0 widgetDefault
			option add *Listbox.selectForeground white widgetDefault
			option add *Listbox.selectBackground #4a6984 widgetDefault

			option add *Entry.background white widgetDefault
			option add *Entry.foreground black widgetDefault
			option add *Entry.selectBorderWidth 0 widgetDefault
			option add *Entry.selectForeground white widgetDefault
			option add *Entry.selectBackground #4a6984 widgetDefault
			option add *Entry.padX 2 widgetDefault
			option add *Entry.padY 4 widgetDefault

			option add *Text.background white widgetDefault
			option add *Text.selectBorderWidth 0 widgetDefault
			option add *Text.selectForeground white widgetDefault
			option add *Text.selectBackground #4a6984 widgetDefault
			option add *Text.padX 2 widgetDefault
			option add *Text.padY 4 widgetDefault

			option add *Menu.activeBorderWidth 0 widgetDefault
			option add *Menu.highlightThickness 0 widgetDefault
			option add *Menu.borderWidth 1 widgetDefault
			option add *Menu.background [::skin::getKey menubackground]
			option add *Menu.foreground [::skin::getKey menuforeground] 
			option add *Menu.activeBackground [::skin::getKey menuactivebackground]
			option add *Menu.activeForeground [::skin::getKey menuactiveforeground]

			option add *Menubutton.activeBackground #4a6984 widgetDefault
			option add *Menubutton.activeForeground white widgetDefault
			option add *Menubutton.activeBorderWidth 0 widgetDefault
			option add *Menubutton.highlightThickness 0 widgetDefault
			option add *Menubutton.borderWidth 0 widgetDefault
			option add *Menubutton.padX 2 widgetDefault
			option add *Menubutton.padY 4 widgetDefault

			option add *Labelframe.borderWidth 2 widgetDefault
			option add *Frame.borderWidth 2 widgetDefault
			option add *Labelframe.padY 8 widgetDefault
			option add *Labelframe.padX 12 widgetDefault

			option add *highlightThickness 0 widgetDefault
			option add *troughColor #c3c3c3 widgetDefault

			option add *Scrollbar.width		10
			option add *Scrollbar.borderWidth		1 
			option add *Scrollbar.highlightThickness	0 widgetDefault
			
			option add *Button.activeForeground #5b76c6 userDefault
		}
		option add *Font splainf userDefault
		#Use different width for scrollbar on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			option add *background #ECECEC
			option add *highlightbackground #ECECEC
			option add *Scrollbar.width 15 userDefault
			option add *Button.Font macfont userDefault		
		} elseif { $tcl_platform(platform) == "windows"} {
			option add *background [::skin::getKey menubackground]
			option add *Scrollbar.width 14 userDefault
			option add *Button.Font sboldf userDefault
		} else {
			option add *background [::skin::getKey menubackground]
			option add *Scrollbar.width 12 userDefault
			option add *Button.Font sboldf userDefault
		}
		
		
		

		#option add *Scrollbar.borderWidth 1 userDefault

		set Entry {-bg #FFFFFF -foreground #000000}
		set Label {-bg #FFFFFF -foreground #000000}
		::themes::AddClass Amsn Entry $Entry 90
		::themes::AddClass Amsn Label $Label 90
		::abookGui::Init
	}

	proc installTLS {} {
		global tcl_platform
		global tlsplatform

		if { ($tcl_platform(os) == "Linux") && ($tcl_platform(machine) == "ppc")} {
			set tlsplatform "linuxppc"
		} elseif { ($tcl_platform(os) == "Linux") && ($tcl_platform(machine) == "sparc")} {
			set tlsplatform "linuxsparc"
		} elseif { $tcl_platform(os) == "Linux" } {
			set tlsplatform "linuxx86"
		} elseif { $tcl_platform(os) == "NetBSD"} {
			set tlsplatform "netbsdx86"
		} elseif { $tcl_platform(os) == "FreeBSD"} {
			set tlsplatform "freebsdx86"
		} elseif { $tcl_platform(os) == "Solaris"} {
			set tlsplatform "solaris26"
		} elseif { $tcl_platform(platform) == "windows"} {
			set tlsplatform "win32"
		} elseif { $tcl_platform(os) == "Darwin" } {
			set tlsplatform "mac"
		} else {
			set tlsplatform "src"
		}

		toplevel .tlsdown
		wm title .tlsdown "[trans tlsinstall]"

		label .tlsdown.caption -text "[trans tlsinstallexp]" -anchor w -font splainf

		label .tlsdown.choose -text "[trans choosearq]:" -anchor w -font sboldf

		pack .tlsdown.caption -side top -expand true -fill x -padx 10 -pady 10
		pack .tlsdown.choose -side top -anchor w -padx 10 -pady 10

		radiobutton .tlsdown.linuxx86 -text "Linux-x86" -variable tlsplatform -value "linuxx86" -font splainf
		radiobutton .tlsdown.linuxppc -text "Linux-PowerPC" -variable tlsplatform -value "linuxppc" -font splainf
		radiobutton .tlsdown.linuxsparc -text "Linux-SPARC" -variable tlsplatform -value "linuxsparc" -font splainf
		radiobutton .tlsdown.netbsdx86 -text "NetBSD-x86" -variable tlsplatform -value "netbsdx86" -font splainf
		radiobutton .tlsdown.netbsdsparc64 -text "NetBSD-SPARC64" -variable tlsplatform -value "netbsdsparc64" -font splainf
		radiobutton .tlsdown.freebsdx86 -text "FreeBSD-x86" -variable tlsplatform -value "freebsdx86" -font splainf
		radiobutton .tlsdown.solaris26 -text "Solaris 2.6 SPARC" -variable tlsplatform -value "solaris26" -font splainf
		radiobutton .tlsdown.win32 -text "Windows" -variable tlsplatform -value "win32" -font splainf
		radiobutton .tlsdown.mac -text "Mac OS X" -variable tlsplatform -value "mac" -font splainf
		radiobutton .tlsdown.src -text "[trans sourcecode]" -variable tlsplatform -value "src" -font splainf
		radiobutton .tlsdown.nodown -text "[trans dontdownload]" -variable tlsplatform -value "nodown" -font splainf


		frame .tlsdown.f

		button .tlsdown.f.ok -text "[trans ok]" -command "::amsn::downloadTLS; bind .tlsdown <Destroy> {}; destroy .tlsdown"
		button .tlsdown.f.cancel -text "[trans cancel]" -command "destroy .tlsdown"

		pack .tlsdown.f.cancel -side right -padx 10 -pady 10
		pack .tlsdown.f.ok -side right -padx 10 -pady 10

		pack .tlsdown.linuxx86 -side top -anchor w -padx 15
		pack .tlsdown.linuxppc -side top -anchor w -padx 15
		pack .tlsdown.linuxsparc -side top -anchor w -padx 15
		pack .tlsdown.netbsdx86 -side top -anchor w -padx 15
		pack .tlsdown.netbsdsparc64 -side top -anchor w -padx 15
		pack .tlsdown.freebsdx86 -side top -anchor w -padx 15
		pack .tlsdown.solaris26 -side top -anchor w -padx 15
		pack .tlsdown.mac -side top -anchor w -padx 15
		pack .tlsdown.win32 -side top -anchor w -padx 15
		pack .tlsdown.src -side top -anchor w -padx 15
		pack .tlsdown.nodown -side top -anchor w -padx 15

		pack .tlsdown.f -side top

		bind .tlsdown <Destroy> {
			if {"%W" == ".tlsdown"} {
				::amsn::infoMsg "[trans notls]"
			} 
		}

		catch {grab .tlsdown}
	}

	proc downloadTLS {} {
		global tlsplatform

		set baseurl "http://osdn.dl.sourceforge.net/sourceforge/amsn/tls1.4.1"

		if { $tlsplatform == "nodown" } {
			::amsn::infoMsg [trans notls]
			return
		} else {
			switch $tlsplatform {
				"linuxx86" {
					set downloadurl "$baseurl-linux-x86.tar.gz"
				}
				"linuxppc" {
					set downloadurl "$baseurl-linux-ppc.tar.gz"
				}
				"linuxsparc" {
					set downloadurl "$baseurl-linux-sparc.tar.gz"
				}
				"netbsdx86" {
					set downloadurl "$baseurl-netbsd-x86.tar.gz"
				}
				"netbsdsparc64" {
					set downloadurl "$baseurl-netbsd-sparc64.tar.gz"
				}
				"freebsdx86" {
					set downloadurl "$baseurl-freebsd-x86.tar.gz"
				}
				"solaris26" {
					set downloadurl "$baseurl-solaris26-sparc.tar.gz"
				}
				"win32" {
					set downloadurl "$baseurl.exe"
				}
				"mac" {
					set downloadurl "[string range $baseurl 0 end-3]5.0-mac.tar.gz"
				}				
				"src" {
					set downloadurl "$baseurl-src.tar.gz"
				}
				default {
					set downloadurl "none"
				}
			}

			set w .tlsprogress
			
			if {[winfo exists $w]} {
				destroy $w
			}
			
			toplevel $w
			wm group $w .
			#wm geometry $w 350x160

			label $w.l -text "[trans downloadingtls $downloadurl]" -font splainf
			pack $w.l -side top -anchor w -padx 10 -pady 10
			pack [::dkfprogress::Progress $w.prbar] -fill x -expand 0 -padx 5 -pady 5 -side top
			label $w.progress -text "[trans receivedbytes 0 ?]" -font splainf

			pack $w.progress -side top -padx 10 -pady 3

			button $w.close -text "[trans cancel]" -command ""
			pack $w.close -side bottom -pady 5 -padx 10

			wm title $w "[trans tlsinstall]"

			::dkfprogress::SetProgress $w.prbar 0

			if {[ catch {set tok [::http::geturl $downloadurl -progress "::amsn::downloadTLSProgress $downloadurl" -command "::amsn::downloadTLSCompleted $downloadurl"]} res ]} {
				errorDownloadingTLS $res
				catch {::http::cleanup $tok}
			} else {
				$w.close configure -command "::http::reset $tok"
				wm protocol $w WM_DELETE_WINDOW "::http::reset $tok"
				tkwait visibility $w
				catch {grab $w}
			}
		}
	}

	proc downloadTLSCompleted { downloadurl token } {
		global files_dir HOME2 tlsplatform

		status_log "status: [http::status $token]\n"
		if { [::http::status $token] == "reset" } {
			::http::cleanup $token

			destroy .tlsprogress
			return
		}

		if { [::http::status $token] != "ok" || [::http::ncode $token] != 200} {
			errorDownloadingTLS "Couldn't get $downloadurl"
			return
		}

		set lastslash [expr {[string last "/" $downloadurl]+1}]
		set fname [string range $downloadurl $lastslash end]


		switch $tlsplatform {
			"solaris26" -
			"linuxx86" -
			"linuxsparc" -
			"netbsdx86" -
			"netbsdsparc64" -
			"freebsdx86" -
			"mac" -
			"win32" {
				if { [catch {
					set file_id [open [file join $files_dir $fname] w]
					fconfigure $file_id -translation {binary binary} -encoding binary
					puts -nonewline $file_id [::http::data $token]
					close $file_id

					set olddir [pwd]
					cd [file join $HOME2 plugins]

					if { $tlsplatform == "win32" } {
						exec [file join $files_dir $fname] "x" "-o" "-y"
					} else {
						exec gzip -cd [file join $files_dir $fname] | tar xvf -
					}

					cd $olddir
					::amsn::infoMsg "[trans tlsinstcompleted]"
				} res ] } {

					errorDownloadingTLS $res
				}
			}
			default {
				::amsn::infoMsg "[trans tlsdowncompleted $fname $files_dir [file join $HOME2 plugins]]"
			}
		}

		destroy .tlsprogress
		::http::cleanup $token

	}

	proc downloadTLSProgress {url token {total 0} {current 0} } {

		if { $total == 0 } {
			errorDownloadingTLS "Couldn't get $url"
			return
		}
		::dkfprogress::SetProgress .tlsprogress.prbar [expr {$current*100/$total}]
		.tlsprogress.progress configure -text "[trans receivedbytes [sizeconvert $current] [sizeconvert $total]]"


	}

	proc errorDownloadingTLS { errormsg } {
		errorMsg "[trans errortls]: $errormsg"
		catch { destroy .tlsprogress }
	}

	#///////////////////////////////////////////////////////////////////////////////
	# Draws the about window
	proc aboutWindow {{localized 0}} {

		global tcl_platform langenc

		if { [winfo exists .about] } {
			raise .about
			return
		}


		if { $localized } {
			set filename "[file join docs README[::config::getGlobalKey language]]"
		} else {
			set filename README
		}
		if {![file exists $filename] } {
			status_log "File $filename NOT exists!!\n" red
			msg_box "[trans transnotexists]"
			return
		}

		toplevel .about
		wm title .about "[trans about] [trans title]"

		ShowTransient .about

		wm state .about withdrawn


		#Top frame (Picture and name of developers)
		set developers "\nDidimo Grimaldo\nAlvaro J. Iradier\nKhalaf Philippe\nAlaoui Youness\nDave Mifsud"
		frame .about.top -class Amsn
		label .about.top.i -image [::skin::loadPixmap msndroid]
		label .about.top.l -font splainf -text "[trans broughtby]:$developers"
		pack .about.top.i .about.top.l -side left

		#Middle frame (About text)
		frame .about.middle
		frame .about.middle.list -class Amsn -borderwidth 0
		text .about.middle.list.text -background white -width 80 -height 30 -wrap word \
			-yscrollcommand ".about.middle.list.ys set" -font splainf
		scrollbar .about.middle.list.ys -command ".about.middle.list.text yview"
		pack .about.middle.list.ys -side right -fill y
		pack .about.middle.list.text -side left -expand true -fill both
		pack .about.middle.list -side top -expand true -fill both -padx 1 -pady 1

		#Bottom frame (Close button)
		frame .about.bottom -class Amsn
		button .about.bottom.close -text "[trans close]" -command "destroy .about"
		bind .about <<Escape>> "destroy .about"
		button .about.bottom.credits -text "[trans credits]..." -command [list ::amsn::showHelpFile CREDITS [trans credits]]

		pack .about.bottom.close -side right
		pack .about.bottom.credits -side left
		
		pack .about.top -side top
		pack .about.bottom -side bottom -fill x -pady 3 -padx 5
		pack .about.middle -expand true -fill both -side top

		#Insert the text in .about.middle.list.text
		set id [open $filename r]
		if { $localized } {
			fconfigure $id -encoding $langenc
		}
		.about.middle.list.text insert 1.0 [read $id]
		close $id

		.about.middle.list.text configure -state disabled
		update idletasks
		wm state .about normal
		set x [expr {([winfo vrootwidth .about] - [winfo width .about]) / 2}]
		set y [expr {([winfo vrootheight .about] - [winfo height .about]) / 2}]
		wm geometry .about +${x}+${y}
		moveinscreen .about 30

		#Should we disable resizable? Since when we make the windows smaller (in y), we lost the "Close button"
		#wm resizable .about 0 0
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# showHelpFile(filename,windowsTitle)
	proc showTranslatedHelpFile {file title} {
		global langenc

		set filename [file join "docs" "${file}[::config::getGlobalKey language]"]

		if {[file exists $filename]} {
			status_log "File $filename exists!!\n" blue
			showHelpFile $filename "$title" $langenc
		} else {
			status_log "File $filename NOT exists!!\n" red
			msg_box "[trans transnotexists]"
		}
	}   

	#///////////////////////////////////////////////////////////////////////////////
	# showHelpFile(filename,windowsTitle)
	proc showHelpFile {file title {encoding "iso8859-1"}} {

		if { [winfo exists .show] } {
			raise .show
			return
		}

		toplevel .show
		wm title .show "$title"

		ShowTransient .show


		#Top frame (Help text area)
		frame .show.info
		frame .show.info.list -class Amsn -borderwidth 0
		text .show.info.list.text -background white -width 80 -height 30 -wrap word \
			-yscrollcommand ".show.info.list.ys set" -font   splainf
		scrollbar .show.info.list.ys -command ".show.info.list.text yview"
		pack .show.info.list.ys 	-side right -fill y
		pack .show.info.list.text -expand true -fill both -padx 1 -pady 1
		pack .show.info.list 		-side top -expand true -fill both -padx 1 -pady 1
		pack .show.info 			-expand true -fill both -side top

		#Bottom frame (Close button)
		button .show.close -text "[trans close]" -command "destroy .show"
		bind .show <<Escape>> "destroy .show"
		pack .show.close
		pack .show.close -side top -anchor e -padx 5 -pady 3

		#Insert FAQ text 
		set id [open $file r]
		fconfigure $id -encoding $encoding
		.show.info.list.text insert 1.0 [read $id]
		close $id

		.show.info.list.text configure -state disabled
		update idletasks

		set x [expr {([winfo vrootwidth .show] - [winfo width .show]) / 2}]
		set y [expr {([winfo vrootheight .show] - [winfo height .show]) / 2}]
		wm geometry .show +${x}+${y}

		#Should we disable resizable? Since when we make the windows smaller (in y), we lost the "Close button"
		#wm resizable .about 0 0
	}
	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////

	proc messageBox { message type icon {title ""} {parent ""}} {

		#If we are on MacOS X, don't put the box in the parent because there are some problems
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			set answer [tk_messageBox -message "$message" -type $type -icon $icon]
		} else {
			if { $parent == ""} {
				set parent [focus]
				if { $parent == ""} { set parent "."}
			}
				set answer [tk_messageBox -message "$message" -type $type -icon $icon -title $title -parent $parent]
		}
		return $answer
	}

	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////
	# Shows the error message specified by "msg"
	proc errorMsg { msg } {
		::amsn::messageBox $msg ok error "[trans title] Error"
	}
	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////
	# Shows the error message specified by "msg"
	proc infoMsg { msg {icon "info"} } {
		::amsn::messageBox $msg ok $icon [trans title]
	}
	#///////////////////////////////////////////////////////////////////////////////

	#///////////////////////////////////////////////////////////////////////////////
	proc blockUnblockUser { user_login } {
		if { [::MSN::userIsBlocked $user_login] } {
			unblockUser $user_login
		} else {
			blockUser $user_login
		}
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	proc blockUser {user_login} {
		set answer [::amsn::messageBox [trans confirmbl] yesno question [trans block]]
		if { $answer == "yes"} {
			set name [::abook::getNick ${user_login}]
			::MSN::blockUser ${user_login} [urlencode $name]
		}
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	proc unblockUser {user_login} {
		set name [::abook::getNick ${user_login}]
		::MSN::unblockUser ${user_login} [urlencode $name]
	}
	#///////////////////////////////////////////////////////////////////////////////   


	#///////////////////////////////////////////////////////////////////////////////
	#Delete user window, user can choose to delete user, cancel the action or block and delete the user
	proc deleteUser {user_login { grId ""} } {
		set w .deleteUserWindow
		
		#If the window was there before, destroy it and create the new one
		if {[winfo exists $w]} {
			destroy $w
		}
		
		#Create the window
		toplevel $w
		wm title $w "[trans delete]"

		#Create the three frames
		frame $w.top
		frame $w.buttons
		frame $w.block
		#Create the picture of warning (at left)
		label $w.top.bitmap -image [::skin::loadPixmap warning]
		pack $w.top.bitmap -side left -pady 5 -padx 15
		#Text to show to delete the user
		label $w.top.question -text "[trans confirmdu]" -font bigfont
		pack $w.top.question -pady 5 -padx 25
		#Create the three buttons, Yes and block / Yes / No
		button $w.block.yesblock -text "[trans yesblock]" -command "::amsn::deleteUserAction $w $user_login yes_block $grId" 
		button $w.buttons.yes -text "[trans yes]" -command "::amsn::deleteUserAction $w $user_login yes $grId" -default active -width 6
		button $w.buttons.no -text "[trans no]" -command "destroy $w" -width 6
		#Pack buttons
		pack $w.buttons.yes -pady 5 -padx 5 -side right
		pack $w.buttons.no -pady 5 -padx 5 -side left
		pack $w.block.yesblock -pady 5 -padx 5
		#Pack frames
		pack $w.top -pady 5 -padx 5 -side top
		pack $w.block -pady 5 -padx 5 -side left
		pack $w.buttons -pady 5 -padx 5 -side right
	
		moveinscreen $w 30
		bind $w <<Escape>> "destroy $w"
	}
	#///////////////////////////////////////////////////////////////////////////////
	# deleteUserAction {w user_login answer grId}
	# Action to do when someone click delete a user
	proc deleteUserAction {w user_login answer grId} {
		#If he wants to delete AND block a user
		if { $answer == "yes_block"} {
			set name [::abook::getNick ${user_login}]
			::MSN::blockUser ${user_login} [urlencode $name]
			::MSN::deleteUser ${user_login} $grId
			::abook::setContactData $user_login alarms ""
		#Just delete the user
		} elseif { $answer == "yes"} {
			::MSN::deleteUser ${user_login} $grId
			::abook::setContactData $user_login alarms ""
		}
		#Remove .deleteUserWindow window
		destroy $w
		return
	}

	#///////////////////////////////////////////////////////////////////////////////
	# FileTransferSend (chatid (filename))
	# Shows the file transfer window, for window win_name
	proc FileTransferSendOLD { win_name {filename ""}} {

		set w ${win_name}_sendfile
		if { [ winfo exists $w ] } {
			if {$filename == ""} { 
				chooseFileDialog "" "" $w $w.top.fields.file 
			} else { 
				$w.top.fields.file insert 0 $filename
			}
			return
		}

		toplevel $w
		wm group $w .
		wm title $w "[trans sendfile]"

		label $w.msg -justify center -text "[trans enterfilename]"
		pack $w.msg -side top -pady 5

		frame $w.buttons
		pack $w.buttons -side bottom -fill x -pady 2m
		button $w.buttons.dismiss -text [trans cancel] -command "destroy $w"
		button $w.buttons.save -text "[trans ok]" \
			-command "::amsn::FileTransferSendOk $w $win_name"
		pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

		frame $w.top

		frame $w.top.labels
		label $w.top.labels.file -text "[trans filename]:"
		label $w.top.labels.ip -text "[trans ipaddress]:"

		frame $w.top.fields
		entry $w.top.fields.file -width 40 -bg #FFFFFF
		entry $w.top.fields.ip -width 15 -bg #FFFFFF
		checkbutton $w.top.fields.autoip -text "[trans autoip]" -variable [::config::getVar autoftip]

		pack $w.top.fields.file -side top -anchor w
		pack $w.top.fields.ip $w.top.fields.autoip -side left -anchor w -pady 5
		pack $w.top.labels.file $w.top.labels.ip -side top -anchor e
		pack $w.top.fields -side right -padx 5
		pack $w.top.labels -side left -padx 5
		pack $w.top -side top

		$w.top.fields.ip insert 0 "[::config::getKey myip]"

		focus $w.top.fields.file

		if {$filename == ""} { 
			chooseFileDialog "" "" $w $w.top.fields.file
			::amsn::FileTransferSendOk $w $win_name
		} else {
			$w.top.fields.file insert 0 $filename 
		}
	}

	proc FileTransferSend { win_name {filename ""} } {
		global starting_dir

#		set filename [ $w.top.fields.file get ]
		if { $filename == "" } {
			set filename [chooseFileDialog "" [trans sendfile] $win_name]
			status_log $filename
		}
		
		if { $filename == "" } { return }
		
		#Remember last directory
		set starting_dir [file dirname $filename]
		
		if {![file readable $filename]} {
			msg_box "[trans invalidfile [trans filename] $filename]"
			return
		}


		#if {[::config::getKey autoftip] == 0 } {
		#	::config::setKey myip [ $w.top.fields.ip get ]
		#	set ipaddr [ $w.top.fields.ip get ]
		#	destroy $w
		#} else {
		#	set ipaddr [ $w.top.fields.ip get ]
		#	destroy $w
		#	if { $ipaddr != [::config::getKey myip] } {
		#		set ipaddr [ ::abook::getDemographicField clientip ]
		#	}
		#}
		if { [::config::getKey autoftip] } {
			set ipaddr [::config::getKey myip]
		} else {
			set ipaddr [::config::getKey manualip]
		}

		if { [catch {set filesize [file size $filename]} res]} {
			::amsn::errorMsg "[trans filedoesnotexist]"
			#::amsn::fileTransferProgress c $cookie -1 -1
			return 1
		}

		set chatid [::ChatWindow::Name $win_name]

		set users [::MSN::usersInChat $chatid]


		foreach chatid $users {
			chatUser $chatid

			#Calculate a random cookie
			set cookie [expr {([clock clicks]) % (65536 * 8)}]
			set txt "[trans ftsendinvitation [::abook::getDisplayNick $chatid] $filename [sizeconvert $filesize]]"

			status_log "Random generated cookie: $cookie\n"
			WinWrite $chatid "\n" green
			WinWriteIcon $chatid greyline 3
			WinWrite $chatid "\n" green
			WinWriteIcon $chatid fticon 3 2
			WinWrite $chatid "$txt " green
			WinWriteClickable $chatid "[trans cancel]" \
				"::amsn::CancelFTInvitation $chatid $cookie" ftno$cookie
			WinWrite $chatid "\n" green
			WinWriteIcon $chatid greyline 3

			::MSN::ChatQueue $chatid [list ::MSNFT::sendFTInvitation $chatid $filename $filesize $ipaddr $cookie]
			#::MSNFT::sendFTInvitation $chatid $filename $filesize $ipaddr $cookie

		::log::ftlog $chatid $txt		

		}
		return 0
	}

	proc CancelFTInvitation { chatid cookie } {

		#::MSNFT::acceptFT $chatid $cookie

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		::MSNFT::cancelFTInvitation $chatid $cookie

		[::ChatWindow::GetTopText ${win_name}] tag configure ftno$cookie \
			-foreground #808080 -background white -font bplainf -underline false
		[::ChatWindow::GetTopText ${win_name}] tag bind ftno$cookie <Enter> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftno$cookie <Leave> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftno$cookie <Button1-ButtonRelease> ""

		[::ChatWindow::GetTopText ${win_name}] conf -cursor left_ptr

		set txt [trans invitationcancelled]

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid ftreject 3 2
		WinWrite $chatid " $txt\n" green
		WinWriteIcon $chatid greyline 3

		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt

	}   

	proc acceptedFT { chatid who filename } {
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}   
		set txt [trans ftacceptedby [::abook::getDisplayNick $chatid] $filename]
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid fticon 3 2
		WinWrite $chatid " $txt\n" green
		WinWriteIcon $chatid greyline 3

		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt
	}   

	proc rejectedFT { chatid who filename } {
		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}   
		set txt [trans ftrejectedby [::abook::getDisplayNick $chatid] $filename]
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid ftreject 3 2
		WinWrite $chatid " $txt\n" green
		WinWriteIcon $chatid greyline 3
			
		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt
	}

	#////////////////////////////////////////////////////////////////////////////////
	#  GotFileTransferRequest ( chatid dest branchuid cseq uid sid filename filesize)
	#  This procedure is called when we receive an MSN6 File Transfer Request
	proc GotFileTransferRequest { chatid dest branchuid cseq uid sid filename filesize} {
		global files_dir

		set win_name [::ChatWindow::For $chatid]

		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		set fromname [::abook::getDisplayNick $dest]
		set txt [trans ftgotinvitation $fromname '$filename' [sizeconvert $filesize] $files_dir]
		set win_name [::ChatWindow::MakeFor $chatid $txt $dest]
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green

		if { [::skin::loadPixmap "FT_preview_${sid}"] != "" } {
			WinWriteIcon $chatid FT_preview_${sid} 5 5
			WinWrite $chatid "\n" green
		}

		WinWriteIcon $chatid fticon 3 2
		WinWrite $chatid $txt green
		WinWrite $chatid " - (" green
		WinWriteClickable $chatid "[trans accept]" [list ::amsn::AcceptFT $chatid -1 [list $dest $branchuid $cseq $uid $sid $filename]] ftyes$sid
		WinWrite $chatid " / " green
		WinWriteClickable $chatid "[trans saveas]" [list ::amsn::SaveAsFT $chatid -1 [list $dest $branchuid $cseq $uid $sid $filename]] ftsaveas$sid
		WinWrite $chatid " / " green
		WinWriteClickable $chatid "[trans reject]" [list ::amsn::RejectFT $chatid -1 [list $sid $branchuid $uid]] ftno$sid
		WinWrite $chatid ")\n" green
		WinWriteIcon $chatid greyline 3
	

		::log::ftlog $dest $txt

		if { ![file writable $files_dir]} {
			WinWrite $chatid "\n[trans readonlywarn $files_dir]\n" red
			WinWriteIcon $chatid greyline 3
			}

		if { [::config::getKey ftautoaccept] == 1 } {
			WinWrite $chatid "\n[trans autoaccepted]" green
			::amsn::AcceptFT $chatid -1 [list $dest $branchuid $cseq $uid $sid $filename]
		}
	}

	#Message shown when receiving a file
	proc fileTransferRecv {filename filesize cookie chatid fromlogin} {
		global files_dir

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		set fromname [::abook::getDisplayNick $fromlogin]
		set txt [trans ftgotinvitation $fromname '$filename' [sizeconvert $filesize] $files_dir]

		set win_name [::ChatWindow::MakeFor $chatid $txt $fromlogin]


		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid fticon 3 2
		WinWrite $chatid $txt green
		WinWrite $chatid " - (" green
		WinWriteClickable $chatid "[trans accept]" \
			"::amsn::AcceptFT $chatid $cookie" ftyes$cookie
		WinWrite $chatid " / " green
		WinWriteClickable $chatid "[trans saveas]" \
			"::amsn::SaveAsFT $chatid $cookie" ftsaveas$cookie
		WinWrite $chatid " / " green
		WinWriteClickable $chatid "[trans reject]" \
			"::amsn::RejectFT $chatid $cookie" ftno$cookie
		WinWrite $chatid ")\n" green
		WinWriteIcon $chatid greyline 3
		
		::log::ftlog $fromlogin $txt

		if { ![file writable $files_dir]} {
			WinWrite $chatid "\n[trans readonlywarn $files_dir]\n" red
			WinWriteIcon $chatid greyline 3
		}

		if { [::config::getKey ftautoaccept] == 1 } {
			WinWrite $chatid "\n[trans autoaccepted]" green
			::amsn::AcceptFT $chatid $cookie
		}
	}


	proc AcceptFT { chatid cookie {varlist ""} } {

		foreach var $varlist {
			status_log "Var: $var\n" red
		}

		#::amsn::RecvWin $cookie
		if { $cookie != -1 } {
			::MSNFT::acceptFT $chatid $cookie
		} else {
			::MSN6FT::AcceptFT $chatid [lindex $varlist 0] [lindex $varlist 1] [lindex $varlist 2] [lindex $varlist 3] [lindex $varlist 4] [lindex $varlist 5]
			set cookie [lindex $varlist 4]
		}

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		[::ChatWindow::GetTopText ${win_name}] tag configure ftyes$cookie \
			-foreground #808080 -background white -font bplainf -underline false
		[::ChatWindow::GetTopText ${win_name}] tag bind ftyes$cookie <Enter> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftyes$cookie <Leave> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftyes$cookie <Button1-ButtonRelease> ""

		[::ChatWindow::GetTopText ${win_name}] tag configure ftsaveas$cookie \
			-foreground #808080 -background white -font bplainf -underline false
		[::ChatWindow::GetTopText ${win_name}] tag bind ftsaveas$cookie <Enter> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftsaveas$cookie <Leave> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftsaveas$cookie <Button1-ButtonRelease> ""

		[::ChatWindow::GetTopText ${win_name}] tag configure ftno$cookie \
			-foreground #808080 -background white -font bplainf -underline false
		[::ChatWindow::GetTopText ${win_name}] tag bind ftno$cookie <Enter> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftno$cookie <Leave> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftno$cookie <Button1-ButtonRelease> ""

		[::ChatWindow::GetTopText ${win_name}] conf -cursor left_ptr

		set txt [trans ftaccepted]

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid fticon 3 2
		WinWrite $chatid " $txt\n" green
		WinWriteIcon $chatid greyline 3
		
		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt

	}


	proc SaveAsFT {chatid cookie {varlist ""} } {
		if {$cookie != -1} {
			set initialfile [::MSNFT::getFilename $cookie]
		} {
			set initialfile [lindex $varlist 5]
		}
		set filename [tk_getSaveFile -initialfile $initialfile -initialdir [set ::files_dir]]
		if {$filename != ""} {
			AcceptFT $chatid $cookie [list [lindex $varlist 0] [lindex $varlist 1] [lindex $varlist 2] [lindex $varlist 3] [lindex $varlist 4] "$filename"]
		} {return}
	}


	proc RejectFT {chatid cookie {varlist ""} } {

		if { $cookie != -1 && $cookie != -2 } {
			::MSNFT::rejectFT $chatid $cookie
		} elseif { $cookie == - 1 } {
			::MSN6FT::RejectFT $chatid [lindex $varlist 0] [lindex $varlist 1] [lindex $varlist 2]
			set cookie [lindex $varlist 0]
		} elseif { $cookie == -2 } {
			set cookie [lindex $varlist 0]
			set txt [trans filetransfercancelled]
		}

		set win_name [::ChatWindow::For $chatid]
		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		[::ChatWindow::GetTopText ${win_name}] tag configure ftyes$cookie \
		-foreground #808080 -background white -font bplainf -underline false
		[::ChatWindow::GetTopText ${win_name}] tag bind ftyes$cookie <Enter> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftyes$cookie <Leave> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftyes$cookie <Button1-ButtonRelease> ""

		[::ChatWindow::GetTopText ${win_name}] tag configure ftsaveas$cookie \
		-foreground #808080 -background white -font bplainf -underline false
		[::ChatWindow::GetTopText ${win_name}] tag bind ftsaveas$cookie <Enter> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftsaveas$cookie <Leave> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftsaveas$cookie <Button1-ButtonRelease> ""

		[::ChatWindow::GetTopText ${win_name}] tag configure ftno$cookie \
		-foreground #808080 -background white -font bplainf -underline false
		[::ChatWindow::GetTopText ${win_name}] tag bind ftno$cookie <Enter> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftno$cookie <Leave> ""
		[::ChatWindow::GetTopText ${win_name}] tag bind ftno$cookie <Button1-ButtonRelease> ""

		[::ChatWindow::GetTopText ${win_name}] conf -cursor left_ptr

		if { [info exists txt] == 0 } {
			set txt [trans ftrejected]
		}

		WinWrite $chatid "\n" green
		WinWriteIcon $chatid greyline 3
		WinWrite $chatid "\n" green
		WinWriteIcon $chatid ftreject 3 2
		WinWrite $chatid "$txt\n" green
		WinWriteIcon $chatid greyline 3
		
		set email [::MSN::usersInChat $chatid]
		::log::ftlog $email $txt

	}


	#PRIVATE: Opens Receiving Window
	proc FTWin {cookie filename user {chatid 0}} {
		status_log "Creating receive progress window\n"

		# Set appropriate Cancel command
		if { [::MSNP2P::SessionList get $cookie] == 0 } {
			set cancelcmd "::MSNFT::cancelFT $cookie"
		} else {
			set cancelcmd "::MSN6FT::CancelFT $chatid $cookie"
		}

		set w .ft$cookie
		toplevel $w
		wm group $w .
		wm geometry $w 360x170

		#frame $w.f -class amsnChatFrame -background [::skin::getKey chatwindowbg] -borderwidth 0 -relief flat
		#set w $ww.f

		label $w.user -text "[trans user]: $user" -font splainf
		pack $w.user -side top -anchor w
		label $w.file -text "[trans filename]: $filename" -font splainf
		pack $w.file -side top -anchor w

		pack [::dkfprogress::Progress $w.prbar] -fill x -expand 0 -padx 5 -pady 5 -side top

		label $w.progress -text "" -font splainf
		label $w.time -text "" -font splainf
		pack $w.progress $w.time -side top

		checkbutton $w.ftautoclose -text "[trans ftautoclose]" -onvalue 1 -offvalue 0 -variable [::config::getVar ftautoclose]
		pack $w.ftautoclose -side top

		button $w.close -text "[trans cancel]" -command $cancelcmd
		pack $w.close -side bottom -pady 5

		if { [::MSNFT::getTransferType $cookie] == "received" } {
			wm title $w "$filename - [trans receivefile]"
		} else {
			wm title $w "$filename - [trans sendfile]"
		}

		wm title $w "$filename - [trans filetransfer]"

		wm protocol $w WM_DELETE_WINDOW $cancelcmd
		moveinscreen $w 30
		

		::dkfprogress::SetProgress $w.prbar 0
	}


	#Updates filetransfer progress window/Bar
	#fileTransferProgress mode cookie filename bytes filesize
	# mode: a=Accepting invitation
	#       c=Connecting
	#       w=Waiting for connection
	#       e=Connect error
	#       i=Identifying/negotiating
	#       l=Connection lost
	#       ca=Cancel
	#       s=Sending
	#       r=Receiving
	#       fr=finish receiving
	#       fs=finish sending
	# cookie: ID for the filetransfer
	# bytes: bytes sent/received (-1 if cancelling)
	# filesize: total bytes in the file
	# chatid used for MSNP9 through server transfers
	#####
	proc FTProgress {mode cookie filename {bytes 0} {filesize 1000} {chatid 0}} {
	# -1 in bytes to transfer cancelled
	# bytes >= filesize for connection finished

		variable firsttimes    ;# Array. Times in ms when the FT started.
		variable ratetimer

		if { [info exists ratetimer($cookie)] } {
			after cancel $ratetimer($cookie)
		}

		set w .ft$cookie

		if { ([winfo exists $w] == 0) && ($mode != "ca")} {
			set filename2 [::MSNFT::getFilename $cookie]
			if { $filename2 != "" } {
				FTWin $cookie [::MSNFT::getFilename $cookie] [::MSNFT::getUsername $cookie] $chatid
			} else {
				FTWin $cookie $filename $bytes $chatid
			}
		}

		if {[winfo exists $w] == 0} {
			return -1
		}

		switch $mode {
			a {
				$w.progress configure -text "[trans ftaccepting]..."
				set bytes 0
				set filesize 1000
			}
			c {
				$w.progress configure -text "[trans ftconnecting $bytes $filesize]..."
				set bytes 0
				set filesize 1000
			}
			w {
				$w.progress configure -text "[trans listeningon $bytes]..."
				set bytes 0
				set filesize 1000
			}
			e {
				$w.progress configure -text "[trans ftconnecterror]"
				$w.close configure -text "[trans close]" -command "destroy $w"
				wm protocol $w WM_DELETE_WINDOW "destroy $w"
			}
			i {
				#$w.progress configure -text "[trans ftconnecting]"
			}
			l {
				$w.progress configure -text "[trans ftconnectionlost]"
				$w.close configure -text "[trans close]" -command "destroy $w"
				wm protocol $w WM_DELETE_WINDOW "destroy $w"
			}
			r -
			s {
				#Calculate how many seconds has transmission lasted
				if {![info exists firsttimes] || ![info exists firsttimes($cookie)]} {
					set firsttimes($cookie) [clock seconds]
					set difftime 0
				} else {
					set difftime  [expr {[clock seconds] - $firsttimes($cookie)}]
				}


				if { $difftime == 0 || $bytes == 0} {
					set rate "???"
					set timeleft "-"
				} else {
					#Calculate rate and time
					set rate [format "%.1f" [expr {(1.0*$bytes / $difftime) / 1024.0 } ]]
					set secleft [expr {int(((1.0*($filesize - $bytes)) / $bytes) * $difftime)} ]
					set t1 [expr {$secleft % 60 }] ;#Seconds
					set secleft [expr {int($secleft / 60)}]
					set t2 [expr {$secleft % 60 }] ;#Minutes
					set secleft [expr {int($secleft / 60)}]
					set t3 $secleft ;#Hours
					set timeleft [format "%02i:%02i:%02i" $t3 $t2 $t1]
				}

				if {$mode == "r"} {
					$w.progress configure -text \
						"[trans receivedbytes [sizeconvert $bytes] [sizeconvert $filesize]] ($rate KB/s)"
				} elseif {$mode == "s"} {
					$w.progress configure -text \
						"[trans sentbytes [sizeconvert $bytes] [sizeconvert $filesize]] ($rate KB/s)"
				}
				$w.time configure -text "[trans timeremaining] :  $timeleft"

				set ratetimer($cookie) [after 1000 [list ::amsn::FTProgress $mode $cookie $filename $bytes $filesize $chatid]]
			}
			ca {
				$w.progress configure -text "[trans filetransfercancelled]"
				$w.close configure -text "[trans close]" -command "destroy $w"
				wm protocol $w WM_DELETE_WINDOW "destroy $w"
			}
			fs -
			fr {
				::dkfprogress::SetProgress $w.prbar 100
				$w.progress configure -text "[trans filetransfercomplete]"
				$w.close configure -text "[trans close]" -command "destroy $w"
				wm protocol $w WM_DELETE_WINDOW "destroy $w"
				set bytes 1024
				set filesize 1024
			}
		}

		switch $mode {
			e - 
			l - 
			ca - 
			fs - 
			fr {
				# Whenever a file transfer is terminated in a way or in another,
				# remove the counters for this cookie.
				if {[info exists firsttimes($cookie)]} { unset firsttimes($cookie) }
				if {[info exists ratetimer($cookie)]} { unset ratetimer($cookie) }
			}
		}

		set bytes2 [expr {int($bytes/1024)}]
		set filesize2 [expr {int($filesize/1024)}]
		if { $filesize2 != 0 } {
			set percent [expr {int(($bytes2*100)/$filesize2)}]
			::dkfprogress::SetProgress $w.prbar $percent
		}

		# Close the window if the filetransfer is finished
		if {($mode == "fr" | $mode == "fs") & [::config::getKey ftautoclose]} {
			destroy $w
		}

	}

 	#Converts filesize in KBytes or MBytes
 	proc sizeconvert {filesize} {
 		#Converts in KBytes
 		set filesizeK [expr {int($filesize/1024)}]
 		#Converts in MBytes
 		set filesizeM [expr {int($filesize/1048576)}]
 		#If the sizefile is bigger than 1Mo
 		if {$filesizeM != 0} {
 			set filesizeM2 [expr {int((($filesize/1048576.) - $filesizeM)*100)}]
 			if {$filesizeM2 < 10} {
 				set filesizeM2 "0$filesizeM2"
 			}
 			set filesizeM "$filesizeM,$filesizeM2"
 			return "${filesizeM}M"
 		#Elseif the filesize is bigger than 1Ko
 		} elseif {$filesizeK != 0} {
 			return "${filesizeK}K"
 		} else {
 			return "$filesize"
 		}
 	}	

	#///////////////////////////////////////////////////////////////////////////////
	# PUBLIC messageFrom(chatid,user,msg,type,[fontformat])
	# Called by the protocol layer when a message 'msg' arrives from the chat
	# 'chatid'.'user' is the login of the message sender, and 'user' can be "msg" to
	# send special messages not prefixed by "XXX says:". 'type' can be a style tag as
	# defined in the ::ChatWindow::Open proc, or just "user". If the type is "user",
	# the 'fontformat' parameter will be used as font format.
	# The procedure will open a window if it does not exists, add a notifyWindow and
	# play a sound if it's necessary
	proc messageFrom { chatid user nick msg type {fontformat ""} {p4c 0} } {
		global remote_auth

		#if customfnick exists replace the nick with customfnick
		set customfnick [::abook::getContactData $user customfnick]
		if { $customfnick != "" } {
			set nick [::abook::getNick $user]
			set customnick [::abook::getContactData $user customnick]

			set nick [::abook::parseCustomNick $customfnick $nick $user $customnick]
		}
		

		set maxw [expr {[::config::getKey notifwidth]-20}]
		incr maxw [expr 0-[font measure splainf "[trans says [list]]:"]]
		set nickt [trunc $nick $maxw splainf]

		#if { ([::config::getKey notifymsg] == 1) && ([string first ${win_name} [focus]] != 0)} {
		#	notifyAdd "[trans says $nickt]:\n$msg" "::amsn::chatUser $chatid"
		#}
		set tmsg "[trans says $nickt]:\n$msg"

		set win_name [::ChatWindow::MakeFor $chatid $tmsg $user]


		if { $remote_auth == 1 } {
			if { "$user" != "$chatid" } {
				write_remote "To $chatid : $msg" msgsent
			} else {
				write_remote "From $chatid : $msg" msgrcv
			}
		}

		PutMessage $chatid $user $nick $msg $type $fontformat $p4c

#		set evPar [list $user [::abook::getDisplayNick $user] $msg]
		
	    
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# enterCustomStyle ()
	# Dialog window to edit the custom chat style
	proc enterCustomStyle {} {
	
		set w .change_custom_style
		if {[winfo exists $w]} {
			raise $w
			return 0
		}
	
		toplevel $w
		wm group $w .
		wm title $w "[trans customstyle]"
	
		frame $w.fn
		label $w.fn.label -font sboldf -text "[trans customstyle]:"
		entry $w.fn.ent -width 40 -bg #FFFFFF -bd 1 -font splainf
		menubutton $w.fn.help -font sboldf -text "<-" -menu $w.fn.help.menu
		menu $w.fn.help.menu -tearoff 0
		$w.fn.help.menu add command -label [trans nick] -command "$w.fn.ent insert insert \\\$nick"
		$w.fn.help.menu add command -label [trans timestamp] -command "$w.fn.ent insert insert \\\$tstamp"
		$w.fn.help.menu add separator
		$w.fn.help.menu add command -label [trans delete] -command "$w.fn.ent delete 0 end"
		$w.fn.ent insert end [::config::getKey customchatstyle]
		
		frame $w.fb
		button $w.fb.ok -text [trans ok] -command [list ::amsn::enterCustomStyleOk $w]
		button $w.fb.cancel -text [trans cancel] -command "destroy $w"
	
	
		pack $w.fn.label $w.fn.ent $w.fn.help -side left -fill x -expand true
		pack $w.fb.ok $w.fb.cancel -side right -padx 5
	
		pack $w.fn $w.fb -side top -fill x -expand true -padx 5
	
		bind $w.fn.ent <Return> [list ::amsn::enterCustomStyleOk $w]
		
		catch {
			raise $w
			focus -force $w.fn.ent
		}
		moveinscreen $w 30
	}
	
	proc enterCustomStyleOk {w} {
		::config::setKey customchatstyle [$w.fn.ent get]
		destroy $w
	}


	#///////////////////////////////////////////////////////////////////////////////
	# userJoins (chatid, user_name)
	# called from the protocol layer when a user JOINS a chat
	# It should be called after a JOI in the switchboard.
	# If a window exists, it will show "user joins conversation" in the status bar
	# - 'chatid' is the chat name
	# - 'usr_name' is the user that joins email
	proc userJoins { chatid usr_name } {


		set win_name [::ChatWindow::For $chatid]

		if { $win_name == 0 && [::config::getKey newchatwinstate]!=2 } {
			set win_name [::ChatWindow::MakeFor $chatid "" $usr_name]

			# PostEvent 'new_conversation' to notify plugins that the window was created
			set evPar(chatid) $chatid
			set evPar(usr_name) $usr_name
			::plugins::PostEvent new_conversation evPar
		}

		if { $win_name != 0 } {

			set statusmsg "[timestamp] [trans joins [::abook::getDisplayNick $usr_name]]\n"
			::ChatWindow::Status [ ::ChatWindow::For $chatid ] $statusmsg minijoins
			::ChatWindow::TopUpdate $chatid

			if { [::config::getKey showdisplaypic] && $usr_name != ""} {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name]
			} else {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name] nopack
			}

			if { [::config::getKey leavejoinsinchat] == 1 } {
				::amsn::WinWrite $chatid "\n" green "" 0
				::amsn::WinWriteIcon $chatid minijoins 5 0
				::amsn::WinWrite $chatid "[timestamp] [trans joins [::abook::getDisplayNick $usr_name]]" green "" 0
			}
		}

		if { [::config::getKey keep_logs] } {
			::log::JoinsConf $chatid $usr_name
		}
		#Postevent when user joins a chat
		set evPar(usr_name) usr_name
		set evPar(chatid) chatid
		set evPar(win_name) win_name
		::plugins::PostEvent user_joins_chat evPar

	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# userLeaves (chatid, user_name)
	# called from the protocol layer when a user LEAVES a chat.
	# It will show the status message. No need to show it if the window is already
	# closed, right?
	# - 'chatid' is the chat name
	# - 'usr_name' is the user email to show in the status message
	proc userLeaves { chatid usr_name closed } {

		global automsgsent

		set win_name [::ChatWindow::For $chatid]
		if { $win_name == 0} {
			return 0
		}

		set username [::abook::getDisplayNick $usr_name]

		if { $closed } {
			set statusmsg "[timestamp] [trans leaves $username]\n"
			set icon minileaves
			
			if { [::config::getKey leavejoinsinchat] == 1 } {
				::amsn::WinWrite $chatid "\n" green "" 0
				::amsn::WinWriteIcon $chatid minileaves 5 0
				::amsn::WinWrite $chatid "[timestamp] [trans leaves $username]" green "" 0
			}

		} else {
			set statusmsg "[timestamp] [trans closed $username]\n"
			set icon minileaves
		}
		
		#Check if the image that is currently showing is
		#from the user that left. Then, change it
		set current_image ""
		#Catch it, because the window might be closed
		catch {set current_image [$win_name.f.bottom.pic.image cget -image]}
		if { [string compare $current_image "user_pic_$usr_name"]==0} {
			set users_in_chat [::MSN::usersInChat $chatid]
			set new_user [lindex $users_in_chat 0]
			::amsn::ChangePicture $win_name user_pic_$new_user [trans showuserpic $new_user] nopack
		}

		::ChatWindow::Status $win_name $statusmsg $icon


		::ChatWindow::TopUpdate $chatid

		if { [::config::getKey keep_logs] } {
			::log::LeavesConf $chatid $usr_name
		}

		# Unset automsg if he leaves so that it sends again on next msg
		if { [info exists automsgsent($usr_name)] } {
			unset automsgsent($usr_name)
		}
		#Postevent when user leaves a chat
		set evPar(usr_name) usr_name
		set evPar(chatid) chatid
		set evPar(win_name) win_name
		::plugins::PostEvent user_leaves_chat evPar

	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# updateTypers (chatid)
	# Called from the protocol.
	# Asks the protocol layer to get a list of typing users in the chat, and shows
	# a message in the status bar.
	# - 'chatid' is the name of the chat
	proc updateTypers { chatid } {


		if {[::ChatWindow::For $chatid] == 0} {
			return 0
		}

		set typers_list [::MSN::typersInChat $chatid]

		set typingusers ""

		foreach login $typers_list {
			set user_name [::abook::getDisplayNick $login]
			set typingusers "${typingusers}${user_name}, "
		}

		set typingusers [string replace $typingusers end-1 end ""]

		set statusmsg ""
		set icon ""

		if {[llength $typers_list] == 0} {

			set lasttime [::MSN::lastMessageTime $chatid]
			if { $lasttime != 0 } {
				set statusmsg "[trans lastmsgtime $lasttime]"
			}

		} elseif {[llength $typers_list] == 1} {

			set statusmsg " [trans istyping $typingusers]."
			set icon typingimg

		} else {

			set statusmsg " [trans aretyping $typingusers]."
			set icon typingimg

		}

		::ChatWindow::Status [::ChatWindow::For $chatid] $statusmsg $icon

	}
	#///////////////////////////////////////////////////////////////////////////////

	if { $initialize_amsn == 1 } {
		variable clipboard ""
	}

	proc ToggleShowPicture { win_name } {
		upvar #0 ${win_name}_show_picture show_pic

		if { $show_pic } {
			set show_pic 0
		} else {
			set show_pic 1
		}
	}

	proc ShowPicMenu { win x y } {
		status_log "Show menu in window $win, position $x $y\n" blue
		catch {menu $win.picmenu -tearoff 0}
		$win.picmenu delete 0 end

		#Make the picture menu appear on the conversation window instead of having it in the bottom of screen (and sometime lost it if the conversation window is in the bottom of the window)
		global tcl_platform
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			set x [expr $x -50]
			set y [expr $y - 115]
		}

		set chatid [::ChatWindow::Name $win]
		set users [::MSN::usersInChat $chatid]
		#Switch to "my picture" or "user picture"
		$win.picmenu add command -label "[trans showmypic]" \
			-command [list ::amsn::ChangePicture $win my_pic [trans mypic]]
		foreach user $users {
			$win.picmenu add command -label "[trans showuserpic $user]" \
				-command [list ::amsn::ChangePicture $win user_pic_$user [trans showuserpic $user]]
		}
		#Load Change Display Picture window
		$win.picmenu add separator
		$win.picmenu add command -label "[trans changedisplaypic]..." -command pictureBrowser
		
		set user [$win.f.bottom.pic.image cget -image]
		if { $user != "no_pic" && $user != "my_pic" } {
			set user [string range $user 9 end]
			$win.picmenu add separator
			#Sub-menu to change size
			$win.picmenu add cascade -label "[trans changesize]" -menu $win.picmenu.size
			catch {menu $win.picmenu.size -tearoff 0 -type normal}
			$win.picmenu.size delete 0 end
			#4 possible size (someone can add something to let the user choose his size)
			$win.picmenu.size add command -label "64x64" -command "::amsn::convertsize $user $win 64x64"
			$win.picmenu.size add command -label "96x96" -command "::amsn::convertsize $user $win 96x96"
			$win.picmenu.size add command -label "128x128" -command "::amsn::convertsize $user $win 128x128"
			$win.picmenu.size add command -label "192x192" -command "::amsn::convertsize $user $win 192x192"
			#Get back to original picture
			$win.picmenu.size add command -label "[trans original]" -command "::MSNP2P::loadUserPic $chatid $user 1"
		}
		tk_popup $win.picmenu $x $y
	}
	
	#Convert a big/small picture to another size
	proc convertsize {user win size} {
		global HOME
		#Get the filename of the display picture of the user
		set filename [::abook::getContactData $user displaypicfile ""]
		#If he don't have any picture, end that
		if { $filename == "" } {
			status_log "No picture found to change size"
			return
		}
		#Convert the picture to the size requested
		convert_image_plus "[file join $HOME displaypic cache ${filename}].gif" displaypic/cache $size
		#Create the new photo with the new picture
		catch {image create photo user_pic_$user -file "[file join $HOME displaypic cache ${filename}].gif"}
		set h [image height user_pic_$user]
		if { $h < 100 } {
			set h 100
		}
		status_log "setting bottom pane misize to $h\n"
		if { $::tcl_version >= 8.4 } {                   
			$win.f paneconfigure $win.f.bottom -minsize $h	
		}
		
	}

	proc ChangePicture {win picture balloontext {nopack ""}} {
		#pack $win.bottom.pic.image -side left -padx 2 -pady 2
		upvar #0 ${win}_show_picture show_pic

		set yview [lindex [[::ChatWindow::GetTopText $win] yview] 1]


		if { $balloontext != "" } {
			#unset_balloon $win.f.bottom.pic.image
			change_balloon $win.f.bottom.pic.image $balloontext
		}
		if { [catch {$win.f.bottom.pic.image configure -image $picture}] } {
			status_log "Failed to set picture, using no_pic\n" red
			$win.f.bottom.pic.image configure -image [::skin::getNoDisplayPicture]
			#unset_balloon $win.f.bottom.pic.image
			change_balloon $win.f.bottom.pic.image [trans nopic]
		} elseif { $nopack == "" } {
			#grid $win.f.bottom.pic.image -row 0 -column 1 -padx 0 -pady 3 -rowspan 2
			pack $win.f.bottom.pic.image -side left -padx 0 -pady [::skin::getKey chat_dp_pady] -anchor w
			set h [image height $picture]
			if { $h < 100 } {
				set h 100
			}
			status_log "setting bottom pane misize to $h\n"
			if { $::tcl_version >= 8.4 } {                   
				$win.f paneconfigure $win.f.bottom -minsize $h
			}
			#grid forget $win.f.bottom.pic.showpic
			$win.f.bottom.pic.showpic configure -image [::skin::loadPixmap imghide]
			#unset_balloon $win.f.bottom.pic.showpic
			change_balloon $win.f.bottom.pic.showpic [trans hidedisplaypic]
			set show_pic 1
		}
		
		if {$yview == 1} {
			update idletasks
			[::ChatWindow::GetTopText $win] see end 
		}


	}

	proc HidePicture { win } {
		global ${win}_show_picture
		pack forget $win.f.bottom.pic.image

		#grid $win.f.bottom.pic.showpic -row 0 -column 1 -padx 0 -pady 0 -rowspan 2
		#Change here to change the icon, instead of text
		$win.f.bottom.pic.showpic configure -image [::skin::loadPixmap imgshow]
		change_balloon $win.f.bottom.pic.showpic [trans showdisplaypic]

		set ${win}_show_picture 0

	}

	proc ShowOrHidePicture { win } {
		upvar #0 ${win}_show_picture value
		if { $value == 1} {
			::amsn::ChangePicture $win [$win.f.bottom.pic.image cget -image] ""
		} else {
			::amsn::HidePicture $win
		}

	}


	#///////////////////////////////////////////////////////////////////////////////


	proc ShowSendMsgList {title command} {
		#Replace for"::amsn::ChooseList \"[trans sendmsg]\" online ::amsn::chatUser 1 0"
		
		set userlist [list]

		foreach user_login [::MSN::sortedContactList] {
			set user_state_code [::abook::getVolatileData $user_login state FLN]

			if { $user_state_code == "NLN" } {
				lappend userlist [list [::abook::getDisplayNick $user_login] $user_login]			
			} elseif { $user_state_code != "FLN" } {
				lappend userlist [list "[::abook::getDisplayNick $user_login] ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
			}
		}

		::amsn::listChoose $title $userlist $command 1 1
	}

		
	proc ShowSendEmailList {title command} {
		#Replace for "::amsn::ChooseList \"[trans sendmail]\" both \"launch_mailer\" 1 0"
		set userlist [list]

		foreach user_login [::MSN::sortedContactList] {
			set user_state_code [::abook::getVolatileData $user_login state FLN]

			if { $user_state_code == "NLN" } {
				lappend userlist [list [::abook::getDisplayNick $user_login] $user_login]			
			} else {
				lappend userlist [list "[::abook::getDisplayNick $user_login] ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
			}
		}

		::amsn::listChoose $title $userlist $command 1 1

	}
	
	proc ShowDeleteList {title command} {
		#Replace for -command  "::amsn::ChooseList \"[trans delete]\" both ::amsn::deleteUser 0 0"
		set userlist [list]

		foreach user_login [::MSN::sortedContactList] {
			set user_state_code [::abook::getVolatileData $user_login state FLN]

			if { $user_state_code == "NLN" } {
				lappend userlist [list [::abook::getDisplayNick $user_login] $user_login]			
			} else {
				lappend userlist [list "[::abook::getDisplayNick $user_login] ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
			}
		}

		::amsn::listChoose $title $userlist $command 0 0

	}
	
	proc ShowSeePropertiesList {title command} {
		#Replace for -command  "::amsn::ChooseList \"[trans delete]\" both ::amsn::deleteUser 0 0"
		set userlist [list]

		foreach user_login [::MSN::sortedContactList] {
			set user_state_code [::abook::getVolatileData $user_login state FLN]

			if { $user_state_code == "NLN" } {
				lappend userlist [list [::abook::getDisplayNick $user_login] $user_login]			
			} else {
				lappend userlist [list "[::abook::getDisplayNick $user_login] ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
			}
		}

		::amsn::listChoose $title $userlist $command 1 0

	}
	
	
	proc ShowAddList {title win_name command} {

		set userlist [list]
		set chatusers [::MSN::usersInChat [::ChatWindow::Name $win_name]]

		foreach user_login $chatusers {
			set user_state_code [::abook::getVolatileData $user_login state FLN]

			if { [lsearch [::abook::getLists $user_login] FL] == -1 } {
				if { $user_state_code != "NLN" } {
					lappend userlist [list "[::abook::getDisplayNick $user_login] ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
				} else {
					lappend userlist [list [::abook::getDisplayNick $user_login] $user_login]
				}
			}
		}

		if { [llength $userlist] > 0 } {
			::amsn::listChoose $title $userlist $command 1 1
		} else {
			msg_box "[trans useralreadyonlist]"
		}
	}


	proc ShowInviteList { title win_name } {

		set userlist [list]
		set chatusers [::MSN::usersInChat [::ChatWindow::Name $win_name]]

		foreach user_login [::MSN::sortedContactList] {			
			set user_state_code [::abook::getVolatileData $user_login state FLN]
			set user_state_no [::MSN::stateToNumber $user_state_code]
			
			if {($user_state_no < 7) && ([lsearch $chatusers $user_login] == -1)} {
				if { $user_state_code != "NLN" } {
					lappend userlist [list "[::abook::getDisplayNick $user_login] ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
				} else {
					lappend userlist [list "[::abook::getDisplayNick $user_login]" $user_login]
				}
			}
		}

		set chatid [::ChatWindow::Name $win_name]

		if { [llength $userlist] > 0 } {
			::amsn::listChoose $title $userlist "::amsn::queueinviteUser [::ChatWindow::Name $win_name]" 1 0

		} else {	        
			cmsn_draw_otherwindow $title "::amsn::queueinviteUser [::ChatWindow::Name $win_name]"
		}
	}

	proc ShowInviteMenu { win_name x y } {

		set menulength 0
		set chatid [::ChatWindow::Name $win_name]
		set chatusers [::MSN::usersInChat $chatid]

		foreach user_login [::MSN::sortedContactList] {			
			set user_state_code [::abook::getVolatileData $user_login state FLN]
			set user_state_no [::MSN::stateToNumber $user_state_code]
			if {($user_state_no < 7) && ([lsearch $chatusers $user_login] == -1)} {
				set menulength [expr $menulength + 1]
			}
		}

		if { $menulength > 10 } {
			::amsn::ShowInviteList "[trans invite]" $win_name
		} elseif { $menulength == 0 } {
			cmsn_draw_otherwindow [trans invite] "::amsn::queueinviteUser [::ChatWindow::Name $win_name]"
		} else {
			.menu_invite delete 0 end			
			foreach user_login [::MSN::sortedContactList] {			
				set user_state_code [::abook::getVolatileData $user_login state FLN]
				set user_state_no [::MSN::stateToNumber $user_state_code]
			
				if {($user_state_no < 7) && ([lsearch $chatusers $user_login] == -1)} {		
					if { $user_state_code != "NLN" } {
						.menu_invite add command -label [trunc "[::abook::getDisplayNick $user_login] ([trans [::MSN::stateToDescription $user_state_code]])" "" 50] -command "::amsn::queueinviteUser $chatid $user_login"
					} else {
						.menu_invite add command -label [trunc "[::abook::getDisplayNick $user_login]" "" 50] -command "::amsn::queueinviteUser $chatid $user_login"
					}
				}
			}

			.menu_invite add separator
			.menu_invite add command -label "[trans other]..." -command [list cmsn_draw_otherwindow [trans invite] "::amsn::queueinviteUser [::ChatWindow::Name $win_name]"]
			tk_popup .menu_invite $x $y
		}

	}
	

	proc queueinviteUser { chatid user } {
		::MSN::ChatQueue $chatid [list ::MSN::inviteUser $chatid $user]
	}

	proc ShowChatList {title win_name command} {

		set userlist [list]
		set chatusers [::MSN::usersInChat [::ChatWindow::Name $win_name]]

		foreach user_login $chatusers {
			set user_state_code [::abook::getVolatileData $user_login state FLN]

			if { $user_state_code != "NLN" } {
				lappend userlist [list "[::abook::getDisplayNick $user_login] ([trans [::MSN::stateToDescription $user_state_code]])" $user_login]
			} else {
				lappend userlist [list [::abook::getDisplayNick $user_login] $user_login]
			}
			
		}

		if { [llength $userlist] > 0 } {
			status_log "Here\n"
			::amsn::listChoose $title $userlist $command 0 1
		} else {
			status_log "No users\n"
		}

	}


	#///////////////////////////////////////////////////////////////////////////////
	#title: Title of the window
	#itemlist: Array,or list, with two columns and N rows. Column 0 is the one to be
	#shown in the list. Column 1 is the use used to parameter to the command
	proc listChoose {title itemlist command {other 0} {skip 1}} {
		global userchoose_req tcl_platform

		set itemcount [llength $itemlist]

		#If just 1 user, and $skip flag set to one, just run command on that user
		if { $itemcount == 1 && $skip == 1 && $other == 0} {
			eval $command [lindex [lindex $itemlist 0] 1]
			return 0
		}

		if { [focus] == ""  || [focus] =="." } {
			set wname "._listchoose"
		} else {
			set wname "[focus]._listchoose"
		}

		if { [catch {toplevel $wname -borderwidth 0 -highlightthickness 0 } res ] } {
			raise $wname
			focus $wname
			return 0
		} else {
			set wname $res
		}

		wm title $wname $title

#		wm geometry $wname 320x350
		#No ugly blue frame on Mac OS X, system already use a border around window
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			frame $wname.blueframe
		} else {
			frame $wname.blueframe -background [::skin::getKey mainwindowbg]
		}

		frame $wname.blueframe.list -class Amsn -borderwidth 0
		frame $wname.buttons -class Amsn

		listbox $wname.blueframe.list.items -yscrollcommand "$wname.blueframe.list.ys set" -font splainf \
			-background white -relief flat -highlightthickness 0 -height 20 -width 60
		scrollbar $wname.blueframe.list.ys -command "$wname.blueframe.list.items yview" -highlightthickness 0 \
			-borderwidth 1 -elementborderwidth 1 

		button  $wname.buttons.ok -text "[trans ok]" -command [list ::amsn::listChooseOk $wname $itemlist $command]
		button  $wname.buttons.cancel -text "[trans cancel]" -command [list destroy $wname]


		pack $wname.blueframe.list.ys -side right -fill y
		pack $wname.blueframe.list.items -side left -expand true -fill both
		pack $wname.blueframe.list -side top -expand true -fill both -padx 4 -pady 4
		pack $wname.blueframe -side top -expand true -fill both

		if { $other == 1 } {
			button  $wname.buttons.other -text "[trans other]..." -command [list ::amsn::listChooseOther $wname $title $command]
			pack $wname.buttons.ok -padx 5 -side right
			pack $wname.buttons.cancel -padx 5 -side right
			pack $wname.buttons.other -padx 5 -side left
		} else {
			pack $wname.buttons.ok -padx 5 -side right
			pack $wname.buttons.cancel -padx 5 -side right
		}

		pack $wname.buttons -side bottom -fill x -pady 3

		foreach item $itemlist {
			$wname.blueframe.list.items insert end [lindex $item 0]
		}


		bind $wname.blueframe.list.items <Double-Button-1> [list ::amsn::listChooseOk $wname $itemlist $command]

		catch {
			raise $wname
			focus $wname.buttons.ok
		}
		
		
		bind $wname <<Escape>> [list destroy $wname]
		bind $wname <Return> [list ::amsn::listChooseOk $wname $itemlist $command]
		moveinscreen $wname 30
	}
	#///////////////////////////////////////////////////////////////////////////////
	
	proc listChooseOther { wname title command } {
		destroy $wname
		cmsn_draw_otherwindow $title $command
	}
			
	proc listChooseOk { wname itemlist command} {
		set sel [$wname.blueframe.list.items curselection]
		if { $sel == "" } { return }
		destroy $wname		
		eval "$command [lindex [lindex $itemlist $sel] 1]"
	}

	#///////////////////////////////////////////////////////////////////////////////
	# TypingNotification (win_name inputbox)
	# Called by a window when the user types something into the text box. It tells
	# the protocol layer to send a typing notification to the chat that the window
	# 'win_name' is connected to
	proc TypingNotification { win_name inputbox} {
		global skipthistime

		set chatid [::ChatWindow::Name $win_name]


		if { $skipthistime } {
			set skipthistime 0
		} else {
			if { [string length [$inputbox get 0.0 end-1c]] == 0 } {
				CharsTyped $chatid ""
			} else {
				CharsTyped $chatid [string length [$inputbox get 0.0 end-1c]]
			}
		}

		#Works for tcl/tk 8.4 only...
		catch {
			bind $inputbox <<Modified>> ""
			$inputbox edit modified false
			bind $inputbox <<Modified>> "::amsn::TypingNotification ${win_name} $inputbox"
		}


		if { $chatid == 0 } {
			status_log "VERY BAD ERROR in ::amsn::TypingNotification!!!\n" red
			return 0
		}

		#Don't queue unless chat is ready, but try to reconnect
		if { [::MSN::chatReady $chatid] } {
			if { [::config::getKey notifytyping] } {
				sb_change $chatid
			}
		} else {
			::MSN::chatTo $chatid
		}
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# DeleteKeyPressed (win_name inputbox)
	# Called by a window when the user uses the delete key in a text box. It updates
	# the number of characters typed to be correct
	proc DeleteKeyPressed { win_name inputbox key} {
		global skipthistime

		set skipthistime 1

		set totallength [string length [$inputbox get 0.0 end-1c]]
		set x [$inputbox tag nextrange sel 0.0]
		if { $x != "" } {
			set y [string length [$inputbox get [lindex $x 0] [lindex $x 1]]]
		} elseif { $key == "Delete" && [string length [$inputbox get 0.0 insert]] == $totallength \
				|| $key == "BackSpace" && [string length [$inputbox get 0.0 insert]] == 0 } {
			set y 0
			set skipthistime 0
		} else {
			set y 1
		}
		set newlength [expr "$totallength - $y"]

		set chatid [::ChatWindow::Name $win_name]
		if { [string length [$inputbox get 0.0 end-1c]] == 0 } {
			CharsTyped $chatid ""
		} else {
			CharsTyped $chatid $newlength
		}

	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# UpKeyPressed (inputbox)
	# Called by a window when the user uses the up key in a text box. It returns
	# the index of the character 1 line above the insertion cursor
	proc UpKeyPressed { inputbox } {
		$inputbox see insert
		
		set bbox [$inputbox bbox insert]
		set xpos [expr [lindex $bbox 0]+[lindex $bbox 2]/2]
		set ypos [lindex $bbox 1]
		set height [lindex $bbox 3]
		if { $ypos > $height } {
			return [$inputbox index "@$xpos,[expr $ypos-$height]"]
		} else {
			$inputbox yview scroll -1 units
			update
			set ypos [lindex [$inputbox bbox insert] 1]
			set height [lindex [$inputbox bbox insert] 3]
			if { $ypos > $height } {
				return [$inputbox index "@$xpos,[expr $ypos-$height]"]
			}
		}
		return [$inputbox index insert]
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# DownKeyPressed (inputbox)
	# Called by a window when the user uses the down key in a text box. It returns
	# the index of the character 1 line below the insertion cursor
	proc DownKeyPressed { inputbox } {
		$inputbox see insert
		
		set bbox [$inputbox bbox insert]
		set xpos [expr [lindex $bbox 0]+[lindex $bbox 2]/2]
		set ypos [lindex $bbox 1]
		set height [lindex $bbox 3]
		set inputboxheight [lindex [$inputbox configure -height] end]
		if { [expr $ypos+$height] < [expr $inputboxheight*$height] } {
			return [$inputbox index "@$xpos,[expr $ypos+$height]"]
		} else {
			$inputbox yview scroll +1 units
			update
			set ypos [lindex [$inputbox bbox insert] 1]
			set height [lindex [$inputbox bbox insert] 3]
			set inputboxheight [lindex [$inputbox configure -height] end]
			if { [expr $ypos+$height] < [expr $inputboxheight*$height] } {
				return [$inputbox index "@$xpos,[expr $ypos+$height]"]
			}
		}
		return [$inputbox index insert]
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# MessageSend (win_name,input)
	# Called from a window the the user enters a message to send to the chat. It will
	# just queue the message to send in the chat associated with 'win_name', and set
	# a timeout for the message
	proc MessageSend { win_name input {custom_msg ""} {friendlyname ""}} {


		set chatid [::ChatWindow::Name $win_name]

		if { $chatid == 0 } {
			status_log "VERY BAD ERROR in ::amsn::MessageSend!!!\n" red
			return 0
		}

		if { $custom_msg != "" } {
			set msg $custom_msg
		} else {
			# Catch in case that $input is not a "text" control (ie: automessage).
			if { [catch { set msg [$input get 0.0 end-1c] }] } {
				set msg ""
			}
		}

		#Blank message
		if {[string length $msg] < 1} { return 0 }

		if { $input != 0 } {
			$input delete 0.0 end
			focus ${input}
		}

		set fontfamily [lindex [::config::getKey mychatfont] 0]
		set fontstyle [lindex [::config::getKey mychatfont] 1]
		set fontcolor [lindex [::config::getKey mychatfont] 2]


		if { $friendlyname != "" } {
			set nick $friendlyname
			set p4c 1
		} elseif { [::abook::getContactData [::ChatWindow::Name $win_name] cust_p4c_name] != ""} {
			set friendlyname [::abook::parseCustomNick [::abook::getContactData [::ChatWindow::Name $win_name] cust_p4c_name] [::abook::getPersonal nick] [::abook::getPersonal login] ""]
			set nick $friendlyname
			set p4c 1
		} elseif { [::config::getKey p4c_name] != ""} {
			set nick [::config::getKey p4c_name]
			set p4c 1
		} else {
			set nick [::abook::getPersonal nick]
			set p4c 0	
		}
		#Postevent when we send a message
		set evPar(nick) nick
		set evPar(msg) msg
		set evPar(chatid) chatid
		set evPar(win_name) win_name
		set evPar(fontfamily) fontfamily
		set evPar(fontstyle) fontstyle
		set evPar(fontcolor) fontcolor
		::plugins::PostEvent chat_msg_send evPar
		
		if {![string equal $msg ""]} {
			set first 0
			while { [expr {$first + 400}] <= [string length $msg] } {
				set msgchunk [string range $msg $first [expr {$first + 399}]]
				set ackid [after 60000 ::amsn::DeliveryFailed $chatid [list $msgchunk]]
				::MSN::messageTo $chatid "$msgchunk" $ackid $friendlyname
				incr first 400
			}
		
		set msgchunk [string range $msg $first end]
		set ackid [after 60000 ::amsn::DeliveryFailed $chatid [list $msgchunk]]

		#Draw our own message
		messageFrom $chatid [::abook::getPersonal login] $nick "$msg" user [list $fontfamily $fontstyle $fontcolor] $p4c

		::MSN::messageTo $chatid "$msgchunk" $ackid $friendlyname


		CharsTyped $chatid ""
		
		::plugins::PostEvent chat_msg_sent evPar
		}

	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# ackMessage (ackid)
	# Called from the protocol layer when ACK for a message is received. It Cancels
	# the timer for time outing the message 'ackid'.
	proc ackMessage { ackid } {
		after cancel $ackid
	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# nackMessage (ackid)
	# Called from the protocol layer when NACK for a message is received. It just
	# writes the delivery error message without waiting for the message to timeout,
	# and cancels the timer.
	proc nackMessage { ackid } {
		if {![catch {after info $ackid} command]} {
			set command [lindex $command 0]
			after cancel $ackid
			eval $command
		}
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# DeliveryFailed (chatid,msg)
	# Writes the delivery error message along with the timeouted 'msg' into the
	# window related to 'chatid'
	proc DeliveryFailed { chatid msg } {

		set win_name [::ChatWindow::For $chatid]

		if { [::ChatWindow::For $chatid] == 0} {
			chatUser $chatid
		}
		update idletasks
		set txt "[trans deliverfail]:\n $msg"
		WinWrite $chatid "\n[timestamp] [trans deliverfail]:\n" red
		WinWrite $chatid "$msg" gray

	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# PutMessage (chatid,user,msg,type,fontformat)
	# Writes a message into the window related to 'chatid'
	# - 'user' is the user login.
	# - 'msg' is the message itself to be displayed.
	# - 'type' can be red, gray... or any tag defined for the textbox when the window
	#   was created, or just "user" to use the fontformat parameter
	# - 'fontformat' is a list containing font style and color
	proc PutMessage { chatid user nick msg type fontformat {p4c ""}} {

		#Run it in mutual exclusion
		run_exclusive [list ::amsn::PutMessageWrapped $chatid $user $nick $msg $type $fontformat $p4c] putmessage
	}

	proc PutMessageWrapped { chatid user nick msg type fontformat {p4c 0 }} {

		
		if { [::config::getKey showtimestamps] } {
			set tstamp [timestamp]
		} else {
			set tstamp ""
		}

		
		switch [::config::getKey chatstyle] {
			msn {
				::config::setKey customchatstyle "\$tstamp [trans says \$nick]:\n"
			}
			
			irc {
				::config::setKey customchatstyle "\$tstamp <\$nick> "
			}
			- {
			}
		}
		
		#By default, quote backslashes and variables
		set customchat [string map {"\\" "\\\\" "\$" "\\\$" "\(" "\\\(" } [::config::getKey customchatstyle]]
		#Now, let's unquote the variables we want to replace
		set customchat [string map { "\\\$nick" "\${nick}" "\\\$tstamp" "\${tstamp}" } $customchat]
		
		if { [::abook::getContactData $user customcolor] != "" } {
			set color [string trim [::abook::getContactData $user customcolor] "#"]
		} else {
			set color 404040
		}
		
		if { $p4c == 1 } {
			if { $color == 404040 } { set color 000000 }
			set style [list "bold" "italic"]
		} else {
			set style {}
		}

		set font [lindex [::config::getGlobalKey basefont] 0]
		if { $font == "" } { set font "Helvetica"}		

		set customfont [list $font $style $color]
		
		if {[::config::getKey truncatenicks]} {
			set oldnick $nick
			set nick ""
			set says [subst -nocommands $customchat]
			
			set measurefont [list $font [lindex [::config::getGlobalKey basefont] 1] $style]
			
			set win_name [::ChatWindow::For $chatid]
			set maxw [winfo width [::ChatWindow::GetTopText $win_name]]
			status_log "Custom font is $customfont\n" red
			incr maxw [expr -10-[font measure $measurefont -displayof $win_name "$says"]]
			set nick [trunc $oldnick $win_name $maxw splainf]
		}

		#Return the custom nick, replacing backslashses and variables
		set customchat [subst -nocommands $customchat]
		WinWrite $chatid "\n$customchat" "says" $customfont
		#Postevent for chat_msg_receive	
		set evPar(user) user
		set evPar(msg) msg
		set evPar(chatid) chatid
		set evPar(fontformat) $fontformat
		set message $msg
		set evPar(message) message
		::plugins::PostEvent chat_msg_receive evPar
		
		if {![string equal $msg ""]} {
			WinWrite $chatid "$message" $type $fontformat 1 $user
			if {[::config::getKey keep_logs]} {
				::log::PutLog $chatid $nick $msg $fontformat
			}
		}
		
		::plugins::PostEvent chat_msg_received evPar
	}
	#///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# chatStatus (chatid,msg,[icon])
	# Called by the protocol layer to show some information about the chat, that
	# should be shown in the status bar. It parameter "ready" is different from "",
	# then it will only show it if the chat is not
	# ready, as most information is about connections/reconnections, and we don't
	# mind in case we have a "chat ready to chat".
	proc chatStatus {chatid msg {icon ""} {ready ""}} {

		if { $chatid == 0} {
			return 0
		} elseif { [::ChatWindow::For $chatid] == 0} {
			return 0
		} elseif { "$ready" != "" && [::MSN::chatReady $chatid] != 0 } {
			return 0
		} else {
			::ChatWindow::Status [::ChatWindow::For $chatid] $msg $icon
		}

	}
	#///////////////////////////////////////////////////////////////////////////////

	proc chatDisabled {chatid} {
		chatStatus $chatid ""
	}

	#///////////////////////////////////////////////////////////////////////////////
	# CharsTyped (chatid,msg)
	# Writes the message 'msg' (number of characters typed) in the window 'win_name' status bar.
	proc CharsTyped { chatid msg } {

		if { $chatid == 0} {
			return 0
		} elseif { [::ChatWindow::For $chatid] == 0} {
			return 0
		} else {
			set win_name [::ChatWindow::For $chatid]

			set msg [string map {"\n" " "} $msg]

			${win_name}.statusbar.charstyped configure -state normal
			${win_name}.statusbar.charstyped delete 0.0 end
			${win_name}.statusbar.charstyped insert end $msg center
			${win_name}.statusbar.charstyped configure -state disabled
		}

	}
	#///////////////////////////////////////////////////////////////////////////////


	#///////////////////////////////////////////////////////////////////////////////
	# chatUser (user)
	# Opens a chat for user 'user'. If a window for that user already exists, it will
	# use it and reconnect if necessary (will call to the protocol function chatUser),
	# and raise and focus that window. If the window doesn't exist it will open a new
	# one. 'user' is the mail address of the user to chat with.
	proc chatUser { user } {

		set lowuser [string tolower $user]

		set win_name [::ChatWindow::For $lowuser]

		if { $win_name == 0 } {

			set win_name [::ChatWindow::Open]
			::ChatWindow::SetFor $lowuser $win_name
			set ::ChatWindow::first_message($win_name) 0
			set chatid [::MSN::chatTo $lowuser]

			# PostEvent 'new_conversation' to notify plugins that the window was created
			set evPar(chatid) $chatid
			set evPar(usr_name) $user
			::plugins::PostEvent new_conversation evPar
		}

		set chatid [::MSN::chatTo $lowuser]

		if { "$chatid" != "${lowuser}" } {
			status_log "Error in ::amsn::chatUser, expected same chatid as user, but was different\n" red
			return 0
		}

		if { [winfo exists .bossmode] } {
			set ::BossMode(${win_name}) "normal"
			wm state ${win_name} withdraw
		} else {
			wm state ${win_name} normal
		}

		wm deiconify ${win_name}

		update idletasks
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		::ChatWindow::MacPosition ${win_name}
		}
		::ChatWindow::TopUpdate $chatid

		#We have a window for that chatid, raise it
		raise ${win_name}

		focus ${win_name}.f.bottom.left.in.text

	}
	#///////////////////////////////////////////////////////////////////////////////

	if { $initialize_amsn == 1 } {

		variable urlcount 0
		set urlstarts { "http://" "https://" "ftp://" "www." }
	}
	
	#///////////////////////////////////////////////////////////////////////////////
	# WinWrite (chatid,txt,tagid,[format])
	# Writes 'txt' into the window related to 'chatid'
	# It will use 'tagname' as style tag, unless 'tagname'=="user", where it will use
	# 'fontname', 'fontstyle' and 'fontcolor' as from fontformat, or 'tagname'=="says"
	# where it will use the same format as "user" but size 11.
	# The parameter "user" is used for smiley substitution.
	proc WinWrite {chatid txt tagname {fontformat ""} {flicker 1} {user ""}} {

		set win_name [::ChatWindow::For $chatid]

		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		#Avoid problems if the windows was closed
		if {![winfo exists $win_name]} {
			return
		}

		if { [lindex [[::ChatWindow::GetTopText ${win_name}] yview] 1] == 1.0 } {
			set scrolling 1
		} else {
			set scrolling 0
		}

		set fontname [lindex $fontformat 0]
		set fontstyle [lindex $fontformat 1]      
		set fontcolor [lindex $fontformat 2]

		[::ChatWindow::GetTopText ${win_name}] configure -state normal -font bplainf -foreground black

		#Store position for later smiley and URL replacement
		set text_start [[::ChatWindow::GetTopText ${win_name}] index end]
		set posyx [split $text_start "."]
		set text_start "[expr {[lindex $posyx 0]-1}].[lindex $posyx 1]"
		
		#Check if this is first line in the text, then ignore the \n
		#at the beginning of the line
		if { [[::ChatWindow::GetTopText ${win_name}] get 1.0 end] == "\n" } {
			if {[string range $txt 0 0] == "\n"} {
				set txt [string range $txt 1 end]
			}
		}
		

		#By default tagid=tagname unless we generate a new one
		set tagid $tagname

		if { $tagid == "user" || $tagid == "yours" || $tagid == "says" } {

			if { $tagid == "says" } {
				set size [lindex [::config::getGlobalKey basefont] 1]
			} else {
				set size [expr {[lindex [::config::getGlobalKey basefont] 1]+[::config::getKey textsize]}]
			}

			set font "\"$fontname\" $size $fontstyle"
			set tagid [::md5::md5 "$font$fontcolor"]

			if { ([string length $fontname] < 3 )
					|| ([catch {[::ChatWindow::GetTopText ${win_name}] tag configure $tagid -foreground #$fontcolor -font $font} res])} {
				status_log "Font $font or color $fontcolor wrong. Using default\n" red
				[::ChatWindow::GetTopText ${win_name}] tag configure $tagid -foreground black -font bplainf
			}
		}

		set evPar(tagname) tagname
		set evPar(winname) {win_name}
		set evPar(msg) txt
		::plugins::PostEvent WinWrite evPar

		[::ChatWindow::GetTopText ${win_name}] insert end "$txt" $tagid

		#TODO: Make an url_subst procedure, and improve this using regular expressions
		variable urlcount
		variable urlstarts

		set endpos $text_start

		foreach url $urlstarts {

			while { $endpos != [[::ChatWindow::GetTopText ${win_name}] index end] && [set pos [[::ChatWindow::GetTopText ${win_name}] search -forward -exact -nocase \
				$url $endpos end]] != "" } {


				set urltext [[::ChatWindow::GetTopText ${win_name}] get $pos end]

				set final 0
				set caracter [string range $urltext $final $final]
				while { $caracter != " " && $caracter != "\n" \
					&& $caracter != ")" && $caracter != "("} {
					set final [expr {$final+1}]
					set caracter [string range $urltext $final $final]
				}

				set urltext [string range $urltext 0 [expr {$final-1}]]

				set posyx [split $pos "."]
				set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $final}]"

				set urlcount "[expr {$urlcount+1}]"
				set urlname "url_$urlcount"

				[::ChatWindow::GetTopText ${win_name}] tag configure $urlname \
				-foreground #000080 -background white -font splainf -underline true
				[::ChatWindow::GetTopText ${win_name}] tag bind $urlname <Enter> \
				"[::ChatWindow::GetTopText ${win_name}] tag conf $urlname -underline false;\
				[::ChatWindow::GetTopText ${win_name}] conf -cursor hand2"
				[::ChatWindow::GetTopText ${win_name}] tag bind $urlname <Leave> \
				"[::ChatWindow::GetTopText ${win_name}] tag conf $urlname -underline true;\
				[::ChatWindow::GetTopText ${win_name}] conf -cursor left_ptr"
				[::ChatWindow::GetTopText ${win_name}] tag bind $urlname <Button1-ButtonRelease> \
				"[::ChatWindow::GetTopText ${win_name}] conf -cursor watch; launch_browser [string map {% %%} [list $urltext]]"

				[::ChatWindow::GetTopText ${win_name}] delete $pos $endpos
				[::ChatWindow::GetTopText ${win_name}] insert $pos "$urltext" $urlname

			}
		}

		update

		#Avoid problems if the windows was closed in the middle...
		if {![winfo exists $win_name]} {
			return
		}

		if {[::config::getKey chatsmileys]} {
			custom_smile_subst $chatid [::ChatWindow::GetTopText ${win_name}] $text_start end
			::smiley::substSmileys  [::ChatWindow::GetTopText ${win_name}] $text_start end 0
			if { $user == [::config::getKey login] } {
				::smiley::substYourSmileys [::ChatWindow::GetTopText ${win_name}] $text_start end 0
			}
		}


		#      vwait smileys_end_subst

		if { $scrolling } {
			[::ChatWindow::GetTopText ${win_name}] yview end
		}
		[::ChatWindow::GetTopText ${win_name}] configure -state disabled

		if { $flicker } {
			::ChatWindow::Flicker $chatid
		}

		after cancel [list set ::ChatWindow::recent_message($win_name) 0]
		set ::ChatWindow::recent_message(${win_name}) 1
		after 2000 [list set ::ChatWindow::recent_message($win_name) 0]
		
		::plugins::PostEvent WinWritten evPar
	}
	#///////////////////////////////////////////////////////////////////////////////


	proc WinWriteIcon { chatid imagename {padx 0} {pady 0}} {

		set win_name [::ChatWindow::For $chatid]

		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		if { [lindex [[::ChatWindow::GetTopText ${win_name}] yview] 1] == 1.0 } {
			set scrolling 1
		} else {
			set scrolling 0
		}


		[::ChatWindow::GetTopText ${win_name}] configure -state normal
		[::ChatWindow::GetTopText ${win_name}] image create end -image [::skin::loadPixmap $imagename] -pady $pady -padx $pady

		if { $scrolling } { [::ChatWindow::GetTopText ${win_name}] yview end }


		[::ChatWindow::GetTopText ${win_name}] configure -state disabled
	}

	proc WinWriteClickable { chatid txt command {tagid ""}} {

		set win_name [::ChatWindow::For $chatid]

		if { [::ChatWindow::For $chatid] == 0} {
			return 0
		}

		if { [lindex [[::ChatWindow::GetTopText ${win_name}] yview] 1] == 1.0 } {
			set scrolling 1
		} else {
			set scrolling 0
		}


		if { $tagid == "" } {
			set tagid [getUniqueValue]
		}

		[::ChatWindow::GetTopText ${win_name}] configure -state normal

		[::ChatWindow::GetTopText ${win_name}] tag configure $tagid \
		-foreground #000080 -background white -font bboldf -underline false

		[::ChatWindow::GetTopText ${win_name}] tag bind $tagid <Enter> \
		"[::ChatWindow::GetTopText ${win_name}] tag conf $tagid -underline true;\
		[::ChatWindow::GetTopText ${win_name}] conf -cursor hand2"
		[::ChatWindow::GetTopText ${win_name}] tag bind $tagid <Leave> \
		"[::ChatWindow::GetTopText ${win_name}] tag conf $tagid -underline false;\
		[::ChatWindow::GetTopText ${win_name}] conf -cursor left_ptr"
		[::ChatWindow::GetTopText ${win_name}] tag bind $tagid <Button1-ButtonRelease> "$command"

		[::ChatWindow::GetTopText ${win_name}] configure -state normal
		[::ChatWindow::GetTopText ${win_name}] insert end "$txt" $tagid

		if { $scrolling } { [::ChatWindow::GetTopText ${win_name}] yview end }

		[::ChatWindow::GetTopText ${win_name}] configure -state disabled
	}   

	if { $initialize_amsn == 1 } {
		variable NotifID 0
		variable NotifPos [list]

	}

	proc closeAmsn {} {

		set answer [::amsn::messageBox [trans exitamsn] yesno question [trans title]]
		if { $answer == "yes"} {
			close_cleanup
			exit
		}
	}

	proc closeOrDock { closingdocks } {
		global systemtray_exist statusicon ishidden
		if {$closingdocks} {
			wm iconify .
			if { $systemtray_exist == 1 && $statusicon != 0 && [::config::getKey closingdocks] } {
				status_log "Hiding\n" white
				wm state . withdrawn
				set ishidden 1
			}

		} else {
			::amsn::closeAmsn
		}
	}


	#Test if X was pressed in Notify Window
	proc testX {x y after_id w ypos command} {
		if {($x > 135) && ($y < 20)} {
			after cancel $after_id
			::amsn::KillNotify $w $ypos
		} else {
			after cancel $after_id; ::amsn::KillNotify $w $ypos; eval $command
		}
	}


	#Adds a message to the notify, that executes "command" when clicked, and
	#plays "sound"
	proc notifyAdd { msg command {sound ""} {type online}} {

		global tcl_platform
		if { [winfo exists .bossmode] } {
			return 
		}
		#Define lastfocus (for Mac OS X focus bug)
		set lastfocus [focus]

		if { [::config::getKey shownotify] == 0 } {
			return;
		}
		variable NotifID
		variable NotifPos

		#New name for the window
		set w .notif$NotifID
		incr NotifID

		toplevel $w -width 1 -height 1
		wm group $w .
		wm state $w withdrawn
		
		#To put the notify window in front of all, specific for Windows only
		if {$tcl_platform(platform) == "windows"} {
			#Some verions of tk don't support this
			catch { wm attributes $w -topmost 1 }
		}


		set xpos [::config::getKey notifyXoffset]
		set ypos [::config::getKey notifyYoffset]
		#Avoid a bugreport if someone removed his xpos or ypos variable in the preferences
		if {$xpos == ""} {
			::config::setKey notifyXoffset 100
			set xpos [::config::getKey notifyXoffset]
		}
		if {$ypos == ""} {
			::config::setKey notifyYoffset 75
			set ypos [::config::getKey notifyYoffset]
			
		}



		#Search for a free notify window position
		while { [lsearch -exact $NotifPos $ypos] >=0 } {
			set ypos [expr {$ypos+105}]
		}
		lappend NotifPos $ypos


		if { $xpos < 0 } { set xpos 0 }
		if { $ypos < 0 } { set ypos 0 }

		canvas $w.c -bg #EEEEFF -width [::config::getKey notifwidth] -height [::config::getKey notifheight] \
			-relief ridge -borderwidth 2
		pack $w.c

		switch $type {
			online {
				$w.c create image 75 50 -image [::skin::loadPixmap notifyonline]
			}
			offline {
				$w.c create image 75 50 -image [::skin::loadPixmap notifyoffline]
			}
			state {
				$w.c create image 75 50 -image [::skin::loadPixmap notifystate]
			}
			plugins {
				$w.c create image 75 50 -image [::skin::loadPixmap notifyplugins]
			}
			default {
				$w.c create image 75 50 -image [::skin::loadPixmap notifyonline]
			}
		}

		$w.c create image 17 22 -image [::skin::loadPixmap notifico]
		$w.c create image 142 12 -image [::skin::loadPixmap notifclose]

		if {[string length $msg] >100} {
			set msg "[string range $msg 0 100]..."
		}

		set notify_id [$w.c create text [expr [::config::getKey notifwidth]/2] 45 -font splainf \
		-justify center -width [expr [::config::getKey notifwidth]-20] -anchor n -text "$msg"]

		set after_id [after [::config::getKey notifytimeout] "::amsn::KillNotify $w $ypos"]

		bind $w.c <Enter> "$w.c configure -cursor hand2"
		bind $w.c <Leave> "$w.c configure -cursor left_ptr"
		#bind $w <ButtonRelease-1> "after cancel $after_id; ::amsn::KillNotify $w $ypos; $command"
		bind $w <ButtonRelease-1> [list ::amsn::testX %x %y $after_id $w $ypos $command]
		bind $w <ButtonRelease-3> "after cancel $after_id; ::amsn::KillNotify $w $ypos"


		wm title $w "[trans msn] [trans notify]"
		wm overrideredirect $w 1
		#wm transient $w
		wm state $w normal

		#Raise $w to correct a bug win "wm geometry" in AquaTK (Mac OS X)     
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			raise $w
		}

		#Disable Grownotify for Mac OS X Aqua/tk users
		if {![::config::getKey animatenotify] || (![catch {tk windowingsystem} wsystem] && $wsystem == "aqua") } {
			wm geometry $w -$xpos-$ypos		
		} else {
			wm geometry $w -$xpos-[expr {$ypos-100}]
			after 50 "::amsn::growNotify $w $xpos [expr {$ypos-100}] $ypos"
		}

		#Focus last windows , in AquaTK (Mac OS X)
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" && $lastfocus!="" } {
			after 50 "catch {focus -force $lastfocus}"
		}

		if { $sound != ""} {
			play_sound ${sound}.wav
		}


	}

	proc growNotify { w xpos currenty finaly } {

		if { [winfo exists $w] == 0 } { return 0}

		if { $currenty>$finaly} {
			wm geometry $w -$xpos-$finaly
			raise $w
			return 0
		}
		wm geometry $w -$xpos-$currenty
		after 50 "::amsn::growNotify $w $xpos [expr {$currenty+15}] $finaly"
	}

	proc KillNotify { w ypos} {
		variable NotifPos

		wm state $w withdrawn
		#Delay the destroying, to avoid a bug in tk 8.3
		after 5000 destroy $w
		set lpos [lsearch -exact $NotifPos $ypos]
		set NotifPos [lreplace $NotifPos $lpos $lpos]
	}

}


#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_main {} {
	global emotion_files date weburl lang_list \
	password HOME files_dir pgBuddy pgNews argv0 argv langlong tcl_platform

	#User status menu
	menu .my_menu -tearoff 0 -type normal
	.my_menu add command -label [trans online] -command "ChCustomState NLN"
	.my_menu add command -label [trans noactivity] -command "ChCustomState IDL"
	.my_menu add command -label [trans busy] -command "ChCustomState BSY"
	.my_menu add command -label [trans rightback] -command "ChCustomState BRB"
	.my_menu add command -label [trans away] -command "ChCustomState AWY"
	.my_menu add command -label [trans onphone] -command "ChCustomState PHN"
	.my_menu add command -label [trans gonelunch] -command "ChCustomState LUN"
	.my_menu add command -label [trans appearoff] -command "ChCustomState HDN"

	# Add the personal states to this menu
	CreateStatesMenu .my_menu

	#Preferences dialog/menu
	#menu .pref_menu -tearoff 0 -type normal

	menu .user_menu -tearoff 0 -type normal
	menu .user_menu.move_group_menu -tearoff 0 -type normal
	menu .user_menu.copy_group_menu -tearoff 0 -type normal
	menu .menu_invite -tearoff 0 -type normal

	#Main menu
	menu .main_menu -tearoff 0 -type menubar -borderwidth 0 -activeborderwidth -0

	#Change the name of the main menu on Mac OS X(TK Aqua) for "File"
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		.main_menu add cascade -label "[trans file]" -menu .main_menu.file
	} else {
		.main_menu add cascade -label "[trans msn]" -menu .main_menu.file
	}

	.main_menu add cascade -label "[trans actions]" -menu .main_menu.actions

	.main_menu add cascade -label "[trans tools]" -menu .main_menu.tools
	.main_menu add cascade -label "[trans help]" -menu .main_menu.helping


	#.main_menu.tools add separator

	#Apple menu, only on Mac OS X
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		.main_menu add cascade -label "Apple" -menu .main_menu.apple
		menu .main_menu.apple -tearoff 0 -type normal
		.main_menu.apple add command -label "[trans about] aMSN" -command ::amsn::aboutWindow
		.main_menu.apple add separator
		.main_menu.apple add command -label "[trans preferences]..." -command Preferences -accelerator "Command-,"
		.main_menu.apple add separator
	}


	#File menu
	menu .main_menu.file -tearoff 0 -type normal 
	if { [string length [::config::getKey login]] > 0 } {
		if {$password != ""} {
			.main_menu.file add command -label "[trans loginas]..." \
				-command ::MSN::connect -state normal
		} else {
			.main_menu.file add command -label "[trans loginas]..." \
				-command cmsn_draw_login -state normal
		}
	} else {
		.main_menu.file add command -label "[trans loginas]..." \
			-command cmsn_draw_login -state normal
	}
	.main_menu.file add command -label "[trans login]..." -command \
	cmsn_draw_login
	.main_menu.file add command -label "[trans logout]" -command "::MSN::logout"
	.main_menu.file add cascade -label "[trans mystatus]" \
		-menu .my_menu -state disabled
	.main_menu.file add separator
	.main_menu.file add command -label "[trans inbox]" -command \
	[list hotmail_login [::config::getKey login] $password]
	.main_menu.file add separator
	#Theses 2 features are not yet in aMSN that's why I remove them from the menu
	.main_menu.file add command -label "[trans savecontacts]..." \
		-command "saveContacts" -state disabled
	#.main_menu.file add command -label "[trans loadcontacts]..." -state disabled
	.main_menu.file add separator
	.main_menu.file add command -label "[trans sendfile]..." -state disabled
	.main_menu.file add command -label "[trans openreceived]" \
		-command "launch_filemanager \"$files_dir\""
	.main_menu.file add separator
	.main_menu.file add command -label "[trans close]" -command "close_cleanup;exit"

	#Actions menu
	menu .main_menu.actions -tearoff 0 -type normal
	.main_menu.actions add command -label "[trans sendmsg]..." -command [list ::amsn::ShowSendMsgList [trans sendmsg] ::amsn::chatUser]
		
	.main_menu.actions add command -label "[trans sendmail]..." -command [list ::amsn::ShowSendEmailList [trans sendmail] launch_mailer]
	#.main_menu.actions add command -label "[trans verifyblocked]..." -command "VerifyBlocked"
	#.main_menu.actions add command -label "[trans showblockedlist]..." -command "VerifyBlocked ; show_blocked"
	.main_menu.actions add command -label "[trans changenick]..." -command cmsn_change_name
	.main_menu.actions add separator
	.main_menu.actions add command -label "[trans checkver]..." -command "check_version"


	#Order Contacts By submenu
	menu .order_by -tearoff 0 -type normal 
	.order_by add radio -label "[trans status]" -value 0 \
		-variable [::config::getVar orderbygroup] -command "cmsn_draw_online"
	.order_by add radio -label "[trans group]" -value 1 \
		-variable [::config::getVar orderbygroup] -command "cmsn_draw_online"
	.order_by add radio -label "[trans hybrid]" -value 2 \
		-variable [::config::getVar orderbygroup] -command "cmsn_draw_online"

	#Order Groups By submenu
	#Added by Trevor Feeney
	menu .ordergroups_by -tearoff 0 -type normal
	.ordergroups_by add radio -label "[trans normal]" -value 1 \
		-variable [::config::getVar ordergroupsbynormal] -command "cmsn_draw_online"
	.ordergroups_by add radio -label "[trans reversed]" -value 0 \
		-variable [::config::getVar ordergroupsbynormal] -command "cmsn_draw_online"

	#Order Contacts By submenu
	menu .view_by -tearoff 0 -type normal 
	.view_by add radio -label "[trans nick]" -value 0 \
		-variable [::config::getVar emailsincontactlist] -command "cmsn_draw_online"
	.view_by add radio -label "[trans email]" -value 1 \
		-variable [::config::getVar emailsincontactlist] -command "cmsn_draw_online"
	.view_by add separator
	.view_by add command -label "[trans changeglobnick]" -command "::abookGui::SetGlobalNick"



	#Tools menu
	menu .main_menu.tools -tearoff 0 -type normal
	.main_menu.tools add command -label "[trans addacontact]..." -command cmsn_draw_addcontact
	.main_menu.tools add cascade -label "[trans admincontacts]" -menu .admin_contacts_menu

	menu .admin_contacts_menu -tearoff 0 -type normal
	.admin_contacts_menu add command -label "[trans delete]..." -command [list ::amsn::ShowDeleteList [trans delete] ::amsn::deleteUser]
	.admin_contacts_menu add command -label "[trans properties]..." -command [list ::amsn::ShowSeePropertiesList [trans properties] ::abookGui::showUserProperties]

	::groups::Init .main_menu.tools

	.main_menu.tools add separator
	.main_menu.tools add cascade -label "[trans ordercontactsby]" -menu .order_by

	.main_menu.tools add cascade -label "[trans viewcontactsby]" -menu .view_by

	#Added by Trevor Feeney
	#User to reverse group lists
	.main_menu.tools add cascade -label "[trans ordergroupsby]" -menu .ordergroups_by -state disabled

	#View the history and the event log
	.main_menu.tools add separator
	.main_menu.tools add command -label "[trans history]" -command ::log::OpenLogWin
	.main_menu.tools add command -label "[trans eventhistory]" -command "::log::OpenLogWin eventlog"

	#Unnecessary separator when you remove the 2 dockings items menu on Mac OS X
	if {$tcl_platform(os) != "Darwin"} {
		.main_menu.tools add separator
	}

	#.main_menu.tools add cascade -label "[trans options]" -menu .options

	#Options menu
	#menu .options -tearoff 0 -type normal
	#.options add command -label "[trans changenick]..." -state disabled \
	#   -command cmsn_change_name -state disabled
	#   .options add command -label "[trans publishphones]..." -state disabled \
	#   -command "::abookGui::showUserProperties [::config::getKey login] -edit"
	#.options add separator
	#.options add command -label "[trans preferences]..." -command Preferences

	#TODO: Move this into preferences window
	#.options add cascade -label "[trans docking]" -menu .dock_menu

	#Disable item menu for docking in Mac OS X(incompatible)
	if {$tcl_platform(os) != "Darwin"} {
		.main_menu.tools add cascade -label "[trans docking]" -menu .dock_menu
	}

	menu .dock_menu -tearoff 0 -type normal
	.dock_menu add radio -label "[trans dockingoff]" -value 0 -variable [::config::getVar dock] -command "init_dock"
	if { $tcl_platform(platform) == "windows"} {
		.dock_menu add radio -label "[trans dockfreedesktop]" -value 3 -variable [::config::getVar dock] -command "init_dock" -state disabled
		.dock_menu add radio -label "[trans dockgtk]" -value 1 -variable [::config::getVar dock] -command "init_dock" -state disabled
		#.dock_menu add radio -label "[trans dockkde]" -value 2 -variable [::config::getVar dock] -command "init_dock" -state disabled
		### need to add dockwindows to translation files
		.dock_menu add radio -label "Windows" -value 4 -variable [::config::getVar dock] -command "init_dock"
	} else {
		.dock_menu add radio -label "[trans dockfreedesktop]" -value 3 -variable [::config::getVar dock] -command "init_dock"
		.dock_menu add radio -label "[trans dockgtk]" -value 1 -variable [::config::getVar dock] -command "init_dock"
		#.dock_menu add radio -label "[trans dockkde]" -value 2 -variable [::config::getVar dock] -command "init_dock"
		### need to add dockwindows to translation files
		.dock_menu add radio -label "Windows" -value 4 -variable [::config::getVar dock] -command "init_dock" -state disabled

	}

	.main_menu.tools add separator
	#.options add checkbutton -label "[trans sound]" -onvalue 1 -offvalue 0 -variable [::config::getVar sound]
	#Let's disable adverts until it works, it's only problems for know
	::config::setKey adverts 0
	#.options add checkbutton -label "[trans adverts]" -onvalue 1 -offvalue 0 -variable [::config::getVar adverts] \
	#-command "msg_box \"[trans mustrestart]\""
	#.options add checkbutton -label "[trans closingdocks]" -onvalue 1 -offvalue 0 -variable [::config::getVar closingdocks]
	#.options add separator
	#.options add command -label "[trans language]..." -command "::lang::show_languagechoose"
	# .options add command -label "[trans skinselector]..." -command ::skinsGUI::SelectSkin


	.main_menu.tools add checkbutton -label "[trans sound]" -onvalue 1 -offvalue 0 -variable [::config::getVar sound]

	#Disable item menu for docking in Mac OS X(incompatible)
	if {$tcl_platform(os) != "Darwin"} {
		.main_menu.tools add checkbutton -label "[trans closingdocks]" -onvalue 1 -offvalue 0 -variable [::config::getVar closingdocks]
	}


	.main_menu.tools add separator
	.main_menu.tools add command -label "[trans language]..." -command "::lang::show_languagechoose"
 	.main_menu.tools add command -label "[trans pluginselector]..." -command ::plugins::PluginGui
	.main_menu.tools add command -label "[trans skinselector]..." -command ::skinsGUI::SelectSkin
	.main_menu.tools add command -label "[trans preferences]..." -command Preferences

	#Help menu
	menu .main_menu.helping -tearoff 0 -type normal

	if { [::config::getGlobalKey language] != "en" } {
		.main_menu.helping add command -label "[trans helpcontents] - $langlong..." \
			-command "::amsn::showTranslatedHelpFile HELP [list [trans helpcontents]]"
		.main_menu.helping add command -label "[trans helpcontents] - English..." \
			-command "::amsn::showHelpFile HELP [list [trans helpcontents]]"
	} else {
		.main_menu.helping add command -label "[trans helpcontents]..." \
			-command "::amsn::showHelpFile HELP [list [trans helpcontents]]"
	}
	.main_menu.helping add separator
	
	if { [::config::getGlobalKey language] != "en" } {
		.main_menu.helping add command -label "[trans faq] - $langlong..." \
			-command "::amsn::showTranslatedHelpFile FAQ [list [trans faq]]"
		.main_menu.helping add command -label "[trans faq] - English..." \
			-command "::amsn::showHelpFile FAQ [list [trans faq]]"
	} else {
		.main_menu.helping add command -label "[trans faq]..." \
			-command "::amsn::showHelpFile FAQ [list [trans faq]]"
	}
	.main_menu.helping add separator
	
	if { [::config::getGlobalKey language] != "en" } {
		.main_menu.helping add command -label "[trans about] - $langlong..." \
			-command "::amsn::aboutWindow 1"
		.main_menu.helping add command -label "[trans about] - English..." \
			-command ::amsn::aboutWindow
	} else {
		.main_menu.helping add command -label "[trans about]..." -command ::amsn::aboutWindow
	}
	.main_menu.helping add command -label "[trans version]..." -command \
	"msg_box \"[trans version]: $::version\n[trans date]: [::abook::dateconvert $date]\n$weburl\""


	. conf -menu .main_menu
	
	
	#image create photo mainback -file [::skin::GetSkinFile pixmaps back.gif]

	wm title . "[trans title] - [trans offline]"
	wm command . [concat $argv0 $argv]
	wm group . .

	#For All Platforms (except Mac)
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		frame .main -class Amsn -relief flat -background white
		#Create the frame for play_Sound_Mac
		frame .fake
	} else {
		#Put the color of the border around the contact list (from the skin)	
		frame .main -class Amsn -relief flat -background [::skin::getKey mainwindowbg]
	}
	
	
	
	frame .main.f -class Amsn -relief flat -background white
	pack .main -fill both -expand true 
	pack .main.f -expand true -fill both -padx 4 -pady 4 -side top
	#pack .main -expand true -fill both
	#pack .main.f -expand true  -fill both  -padx 4 -pady 4 -side top

	# Create the Notebook and initialize the page paths. These
	# page paths must be used for adding new widgets to the
	# notebook tabs.
	if {[::config::getKey withnotebook]} {
		NoteBook .main.f.nb -background white 
		.main.f.nb insert end buddies -text "Buddies"
		.main.f.nb insert end news -text "News"
		 set pgBuddy [.main.f.nb getframe buddies]
		 set pgNews  [.main.f.nb getframe news]
		 .main.f.nb raise buddies
		 .main.f.nb compute_size
		 pack .main.f.nb -fill both -expand true -side top
	} else {
		set pgBuddy .main.f
		set pgNews  ""
	}
	# End of Notebook Creation/Initialization

	#New image proxy system
	::skin::setPixmap msndroid msnbot.gif
	::skin::setPixmap online online.gif
	::skin::setPixmap offline offline.gif
	::skin::setPixmap away away.gif
	::skin::setPixmap busy busy.gif

	::skin::setPixmap bonline bonline.gif
	::skin::setPixmap boffline boffline.gif
	::skin::setPixmap baway baway.gif
	::skin::setPixmap bbusy bbusy.gif

	::skin::setPixmap mailbox unread.gif

	::skin::setPixmap contract contract.gif
	::skin::setPixmap expand expand.gif

	::skin::setPixmap globe globe.gif
	::skin::setPixmap download download.gif
	::skin::setPixmap warning warning.gif

	::skin::setPixmap typingimg typing.gif
	::skin::setPixmap miniinfo miniinfo.gif
	::skin::setPixmap miniwarning miniwarn.gif
	::skin::setPixmap minijoins minijoins.gif
	::skin::setPixmap minileaves minileaves.gif

	::skin::setPixmap butsmile butsmile.gif
	::skin::setPixmap butsmile_hover butsmile_hover.gif
	::skin::setPixmap butfont butfont.gif
	::skin::setPixmap butfont_hover butfont_hover.gif
	::skin::setPixmap butblock butblock.gif
	::skin::setPixmap butblock_hover butblock_hover.gif
	::skin::setPixmap butsend butsend.gif
	::skin::setPixmap butsend_hover butsend_hover.gif
	::skin::setPixmap butinvite butinvite.gif
	::skin::setPixmap butinvite_hover butinvite_hover.gif
	::skin::setPixmap butnewline newline.gif
	::skin::setPixmap sendbutton sendbut.gif
	::skin::setPixmap sendbutton_hover sendbut_hover.gif
 	::skin::setPixmap imgshow imgshow.gif
	::skin::setPixmap imghide imghide.gif

	::skin::setPixmap fticon fticon.gif
	::skin::setPixmap ftreject ftreject.gif
	
	::skin::setPixmap notifico notifico.gif
	::skin::setPixmap notifclose notifclose.gif
	::skin::setPixmap notifyonline notifyonline.gif
	::skin::setPixmap notifyoffline notifyoffline.gif
	::skin::setPixmap notifyplugins notifyplugins.gif
	::skin::setPixmap notifystate notifystate.gif
	
	::skin::setPixmap blocked blocked.gif
	::skin::setPixmap colorbar colorbar.gif
	
	::skin::setPixmap bell bell.gif
	::skin::setPixmap belloff belloff.gif

	::skin::setPixmap notinlist notinlist.gif
	::skin::setPixmap smile smile.gif
	
	::skin::setPixmap greyline greyline.gif
	
	::skin::setPixmap nullimage null
	#set the nullimage transparent
	[::skin::loadPixmap nullimage] blank
	if { $tcl_platform(os) == "Darwin" } {
		::skin::setPixmap logolinmsn logomacmsn.gif
	} else {
		::skin::setPixmap logolinmsn logolinmsn.gif
	}
		
	ScrolledWindow $pgBuddy.sw -auto vertical -scrollbar vertical
	pack $pgBuddy.sw -expand true -fill both
	set pgBuddy $pgBuddy.sw
	
	text $pgBuddy.text -background white -width 30 -height 0 -wrap none \
		-cursor left_ptr -font splainf \
		-selectbackground white -selectborderwidth 0 -exportselection 0 \
		-relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0
		
	$pgBuddy setwidget $pgBuddy.text

	# Initialize the event history
	frame .main.eventmenu
	combobox::combobox .main.eventmenu.list -editable false -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf -exportselection false

	# Initialize the banner for when the user wants to see aMSN Banner
	adv_initialize .main
	# Add the banner to main window when the user wants (By default "Yes")
	resetBanner

	#if {[::config::getKey enablebanner]} {

		# If user wants to see aMSN Banner, we add it to main window (By default "Yes")
	#	adv_initialize .main

		# This one is not a banner but a branding. When adverts are enabled
		# they share this space with the branding image. The branding image
		# is cycled in between adverts.
	#	if {$tcl_platform(os) == "Darwin"} {
	#		::skin::setPixmap banner logomacmsn.gif
			#adv_show_banner file [::skin::GetSkinFile pixmaps logomacmsn.gif]
	#	} else {
	#		::skin::setPixmap banner logolinmsn.gif
			#adv_show_banner file [::skin::GetSkinFile pixmaps logolinmsn.gif]
	#	}
	#}

	#Command-key for "key shortcut" in Mac OS X
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		bind . <Command-s> toggle_status
		bind . <Command-S> toggle_status
		bind . <Command-,> Preferences
		bind . <Command-Option-space> BossMode
	    bind . <Option-p> ::pluginslog::toggle
	    bind . <Option-P> ::pluginslog::toggle
	} else {
		bind . <Control-s> toggle_status
	    bind . <Alt-p> ::pluginslog::toggle
	    
		bind . <Control-p> Preferences
		bind . <Control-Alt-space> BossMode   
	}

	#Shortcut to Quit aMSN on Mac OS X
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		bind all <Command-q> {
			close_cleanup;exit
		}
		bind all <Command-Q> {
			close_cleanup;exit
		}
	}

	wm protocol . WM_DELETE_WINDOW {::amsn::closeOrDock [::config::getKey closingdocks]}

	cmsn_draw_status
	cmsn_draw_offline

	status_log "Proxy is : [::config::getKey proxy]\n"

	#wm iconname . "[trans title]"
	if {$tcl_platform(platform) == "windows"} {
		catch {wm iconbitmap . [::skin::GetSkinFile winicons msn.ico]}
		catch {wm iconbitmap . -default [::skin::GetSkinFile winicons msn.ico]}
	} else {
		catch {wm iconbitmap . @[::skin::GetSkinFile pixmaps amsn.xbm]}
		catch {wm iconmask . @[::skin::GetSkinFile pixmaps amsnmask.xbm]}
	}

		#Unhide main window now that it has finished being created
		update
		wm state . normal
		#Set the position on the screen and the size for the contact list, from config
		catch {wm geometry . [::config::getKey wingeometry]}
		#To avoid the bug of window behind the bar menu on Mac OS X
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		moveinscreen . 30
		}
	
	
	#allow for display updates so window size is correct
	update idletasks

}
#///////////////////////////////////////////////////////////////////////

proc choose_font { parent title {initialfont ""} {initialcolor ""}} {
	if { [winfo exists .fontsel] } {
		raise .fontsel
		return
	}
		
	set selected_font [SelectFont .fontsel -parent $parent -title $title -font $initialfont -initialcolor $initialcolor -nosizes 1]
	return $selected_font
}


#///////////////////////////////////////////////////////////////////////
proc change_myfont {win_name} {
	
	set basesize [lindex [::config::getGlobalKey basefont] 1]	
	
	#Get current font configuration
	set fontname [lindex [::config::getKey mychatfont] 0] 
	set fontsize [expr {$basesize + [::config::getKey textsize]}]
	set fontstyle [lindex [::config::getKey mychatfont] 1]	
	set fontcolor [lindex [::config::getKey mychatfont] 2]

	if { [catch {
			set selfont_and_color [choose_font .${win_name} [trans choosebasefont] [list $fontname $fontsize $fontstyle] "#$fontcolor"]
		}]} {
		
		set selfont_and_color [choose_font .${win_name} [trans choosebasefont] [list "helvetica" 12 [list]] #000000]
		
	}
	
	set selfont [lindex $selfont_and_color 0]
	set selcolor [lindex $selfont_and_color 1]

	if { $selfont == ""} {
		return
	}
	
	set sel_fontfamily [lindex $selfont 0]
	set sel_fontstyle [lrange $selfont 2 end]
	
	
	if { $selcolor == "" } {
		set selcolor $fontcolor
	} else {
		set selcolor [string range $selcolor 1 end]
	}
	
	::config::setKey mychatfont [list $sel_fontfamily $sel_fontstyle $selcolor]
	
	change_myfontsize [::config::getKey textsize]
	
}
#///////////////////////////////////////////////////////////////////////

proc change_myfontsize { size {windows ""}} {
	
	set basesize [lindex [::config::getGlobalKey basefont] 1]	
	
	#Get current font configuration
	set fontfamily [lindex [::config::getKey mychatfont] 0] 
	set fontsize [expr {$basesize + $size} ]
	set fontstyle [lindex [::config::getKey mychatfont] 1]	
	set fontcolor [lindex [::config::getKey mychatfont] 2]
	if { $fontcolor == "" } { set fontcolor "000000" }
	
	if { $windows == "" } {
		set windows $::ChatWindow::windows
	}
	
	foreach w  $windows {

		[::ChatWindow::GetTopText $w] tag configure yours -font [list $fontfamily $fontsize $fontstyle]
		$w.f.bottom.left.in.text configure -font [list $fontfamily $fontsize $fontstyle]
		$w.f.bottom.left.in.text configure -foreground "#$fontcolor"
	
		#Get old user font and replace its size
		catch {
			set font [lreplace [[::ChatWindow::GetTopText $w] tag cget user -font] 1 1 $fontsize]
			[::ChatWindow::GetTopText $w] tag configure user -font $font
		} res
	}
	
	::config::setKey textsize $size
	
}


#///////////////////////////////////////////////////////////////////////
proc cmsn_msgwin_sendmail {name} {
	upvar #0 [sb name $name users] users_list
	set win_name "msg_[string tolower ${name}]"

	if {[llength $users_list]} {
		set recipient ""
		foreach usrinfo $users_list {
			if { $recipient != "" } {
				set recipient "${recipient}, "
			}
			set user_login [lindex $usrinfo 0]
			set recipient "${recipient}${user_login}"
		}
	} else {
		set recipient "recipient@somewhere.com"
	}

	launch_mailer $recipient
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc play_sound {sound {absolute_path 0} {force_play 0}} {

	#If absolute_path == 1 it means we don't have to get the sound
	#from the skin, but just use it as an absolute path to the sound file

	if { [::config::getKey sound] == 1 || $force_play == 1} {
		#Activate snack on Mac OS X (remove that during 0.94 CVS)
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
			if { $absolute_path == 1 } {
			play_Sound_Mac $sound
			} else {
			play_Sound_Mac [::skin::GetSkinFile sounds $sound]
			}
		} elseif { [::config::getKey usesnack] } {
			if { $absolute_path == 1 } {
				snack_play_sound [::skin::loadSound $sound]
			} else {
				snack_play_sound [::skin::loadSound $sound]
			}
		} else {
			if { $absolute_path == 1 } {
				play_sound_other $sound
			} else {	
				play_sound_other [::skin::GetSkinFile sounds $sound]
			}
		}
	}
}

proc snack_play_sound {snd {loop 0}} {
	if { $loop == 1 } {
		#When 2 sounds play at the same time callback doesnt get deleted unless both are stopped so requires a catch
		catch { $snd play -command [list snack_play_sound $snd 1] } { }
	} else {
		#This catch will avoid some errors is waveout is being used
		catch { $snd play }
	}
}

proc play_sound_other {sound} {
	global tcl_platform

	if { [string first "\$sound" [::config::getKey soundcommand]] == -1 } {
		::config::setKey soundcommand "[::config::getKey soundcommand] \$sound"
	}

	set soundcommand [::config::getKey soundcommand]
	#Quote everything, or "eval" will fail
	set soundcommand [string map { "\\" "\\\\" "\[" "\\\[" "\$" "\\\$" "\[" "\\\[" } $soundcommand]
	set soundcommand [string map { "\\" "\\\\" "\[" "\\\[" "\$" "\\\$" "\[" "\\\[" } $soundcommand]
	#Unquote the $sound variable so it's replaced
	set soundcommand [string map { "\\\\\\\$sound" "\${sound}" } $soundcommand]
	
	catch {eval eval exec $soundcommand &} res
}

#Play sound in a loop
proc play_loop { sound_file {id ""} } {
	global looping_sound
	
	#Prepare the sound command for variable substitution
	set command [::config::getKey soundcommand]
	set command [string map {"\[" "\\\[" "\\" "\\\\" "\$" "\\\$" "\(" "\\\(" } $command]
	#Now, let's unquote the variables we want to replace
	set command "|[string map {"\\\$sound" "\${sound_file}" } $command]"
	set command [subst -nocommands $command]
	
	#Launch command, connecting stdout to a pipe
	set pipe [open $command r]
	
	if { ![info exists ::loop_id] } {
		set ::loop_id 0
	}
	
	#Get a new ID
	if { $id == "" } {
		set id [incr ::loop_id]
	}
	set looping_sound($id) $pipe
	fileevent $pipe readable [list play_finished $pipe $sound_file $id]
	return $id
}

proc cancel_loop { id } {
	global looping_sound
	if { ![info exists looping_sound($id)] } {
		after 3000 [list unset looping_sound($id)]
	} else {
		unset looping_sound($id)
	}
}

proc play_finished {pipe sound id} {
	global looping_sound
	
	if { [eof $pipe] } {
		fileevent $pipe readable {}
		catch {close $pipe}
		if { [info exist looping_sound($id)] } {
			update
			#after 1000 [list play_loop $sound $id]
			after 1000 [list replay_loop $sound $id]
		}
	} else {
		gets $pipe
	}
}

proc replay_loop {sound id} {
	global looping_sound

	if { ![info exist looping_sound($id)] } {
		return
	}
	
	play_loop $sound $id
}

#play_Sound_Mac Play sounds on Mac OS X with the extension "QuickTimeTcl"
proc play_Sound_Mac {sound} {
			set sound_name [file tail $sound]
			#Find the name of the sound without .wav or .mp3, etc
			set sound_small [string first "." "$sound_name"]
			set sound_small [expr {$sound_small -1}]
			set sound_small_name [string range $sound_name 0 $sound_small]
			#Necessary for Mac OS 10.2 compatibility
			#Find the path of the sound, begin with skins/.. or /..
			#/ = The sound has a real path, skin in Application Support (.amsn) or anywhere on hard disk
			#s = skins, the sound is inside aMSN Folder
			set sound_start [string range $sound 0 0]
			#Destroy previous song if he already play
			destroy .fake.$sound_small_name
			#Find the path of aMSN folder
			set pwd "[exec pwd]"
			#Create the sound in QuickTime TCL to play the sound
			if {$sound_start == "/"} {
				catch {movie .fake.$sound_small_name -file $sound -controller 0}
			} else {
				#This way we create real path for skins inside aMSN application
				catch {movie .fake.$sound_small_name -file $pwd/$sound -controller 0}
			}
			#Play the sound
			catch {.fake.$sound_small_name play}
			return
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc show_encodingchoose {} {
	set encodings [encoding names]
	set encodings [lsort $encodings]
	set enclist [list]
	foreach enc $encodings {
		lappend enclist [list $enc $enc]
	}
	set enclist [linsert $enclist 0 [list "Automatic" auto]]
	::amsn::listChoose "[trans encoding]" $enclist set_encoding 0 1
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc set_encoding {enc} {
	if {[catch {encoding system $enc} res]} {
		msg_box "Selected encoding not available, selecting auto"
		::config::setKey encoding auto
	} else {
		::config::setKey encoding $enc
	}
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_status {} {
	global followtext_status queued_status
	
	if { [winfo exists .status] } {return}
	toplevel .status
	wm group .status .
	wm state .status withdrawn
	wm title .status "status log - [trans title]"

	set followtext_status 1

	text .status.info -background white -width 60 -height 30 -wrap word \
		-yscrollcommand ".status.ys set" -font splainf
	scrollbar .status.ys -command ".status.info yview"
	entry .status.enter -background white
	checkbutton .status.follow -text "[trans followtext]" -onvalue 1 -offvalue 0 -variable followtext_status -font sboldf

	frame .status.bot -relief sunken -borderwidth 1
	button .status.bot.save -text "[trans savetofile]" -command status_save
	button .status.bot.clear  -text "Clear" \
		-command ".status.info delete 0.0 end"
	button .status.bot.close -text [trans close] -command toggle_status 
	pack .status.bot.save .status.bot.close .status.bot.clear -side left

	pack .status.bot .status.enter .status.follow -side bottom
	pack .status.enter  -fill x
	pack .status.ys -side right -fill y
	pack .status.info -expand true -fill both

	.status.info tag configure green -foreground darkgreen -background white
	.status.info tag configure red -foreground red -background white
	.status.info tag configure white -foreground white -background black
	.status.info tag configure blue -foreground blue -background white
	.status.info tag configure error -foreground white -background black

	bind .status.enter <Return> "window_history add %W; ns_enter"
	bind .status.enter <Key-Up> "window_history previous %W"
	bind .status.enter <Key-Down> "window_history next %W"
	wm protocol .status WM_DELETE_WINDOW { toggle_status }
	
	if { [info exists queued_status] && [llength $queued_status] > 0 } {
		foreach item $queued_status {
			status_log [lindex $item 0] [lindex $item 1]
		}
		unset queued_status
	}
}


proc status_save { } {
	set w .status_save

	toplevel $w
	wm title $w \"[trans savetofile]\"
	label $w.msg -justify center -text "Please give a filename"
	pack $w.msg -side top

	frame $w.buttons -class Degt
	pack $w.buttons -side bottom -fill x -pady 2m
	button $w.buttons.dismiss -text Cancel -command "destroy $w"
	button $w.buttons.save -text Save -command "status_save_file $w.filename.entry; destroy $w"
	pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

	frame $w.filename -bd 2 -class Degt
	entry $w.filename.entry -relief sunken -width 40
	label $w.filename.label -text "Filename:"
	pack $w.filename.entry -side right 
	pack $w.filename.label -side left
	pack $w.msg $w.filename -side top -fill x
	focus $w.filename.entry

	chooseFileDialog "status_log.txt" "" $w $w.filename.entry save

	catch {grab $w}
}

proc status_save_file { filename } {

	set fd [open [${filename} get] a+]
	fconfigure $fd -encoding utf-8
	puts $fd "[.status.info get 0.0 end]"
	close $fd
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_offline {} {

	bind . <Configure> ""

	after cancel "cmsn_draw_online"

	global sboldf password pgBuddy

	bind $pgBuddy.text <Configure>  ""

	wm title . "[trans title] - [trans offline]"

	$pgBuddy.text configure -state normal
	$pgBuddy.text delete 0.0 end
	
	
	#Send postevent "OnDisconnect" to plugin when we disconnect	
	::plugins::PostEvent OnDisconnect evPar
	
#Iniciar session

	$pgBuddy.text tag conf check_ver -fore #777777 -underline true \
		-font splainf -justify left
	$pgBuddy.text tag bind check_ver <Enter> \
		"$pgBuddy.text tag conf check_ver -fore #0000A0 -underline false;\
		$pgBuddy.text conf -cursor hand2"
	$pgBuddy.text tag bind check_ver <Leave> \
		"$pgBuddy.text tag conf check_ver -fore #000000 -underline true;\
		$pgBuddy.text conf -cursor left_ptr"
	$pgBuddy.text tag bind check_ver <Button1-ButtonRelease> \
		"check_version"

	$pgBuddy.text tag conf lang_sel -fore #777777 -underline true \
		-font splainf -justify left
	$pgBuddy.text tag bind lang_sel <Enter> \
		"$pgBuddy.text tag conf lang_sel -fore #0000A0 -underline false;\
		$pgBuddy.text conf -cursor hand2"
	$pgBuddy.text tag bind lang_sel <Leave> \
		"$pgBuddy.text tag conf lang_sel -fore #000000 -underline true;\
		$pgBuddy.text conf -cursor left_ptr"
	$pgBuddy.text tag bind lang_sel <Button1-ButtonRelease> \
		"::lang::show_languagechoose"


	$pgBuddy.text tag conf start_login -fore #000000 -underline true \
	-font sboldf -justify center
	$pgBuddy.text tag bind start_login <Enter> \
	"$pgBuddy.text tag conf start_login -fore #0000A0 -underline false;\
	$pgBuddy.text conf -cursor hand2"
	$pgBuddy.text tag bind start_login <Leave> \
	"$pgBuddy.text tag conf start_login -fore #000000 -underline true;\
	$pgBuddy.text conf -cursor left_ptr"
	$pgBuddy.text tag bind start_login <Button1-ButtonRelease> ::MSN::connect


	$pgBuddy.text tag conf start_loginas -fore #000000 -underline true \
		-font sboldf -justify center
	$pgBuddy.text tag bind start_loginas <Enter> \
		"$pgBuddy.text tag conf start_loginas -fore #0000A0 -underline false;\
		$pgBuddy.text conf -cursor hand2"
	$pgBuddy.text tag bind start_loginas <Leave> \
		"$pgBuddy.text tag conf start_loginas -fore #000000 -underline true;\
		$pgBuddy.text conf -cursor left_ptr"
	$pgBuddy.text tag bind start_loginas <Button1-ButtonRelease> \
		"cmsn_draw_login"

	$pgBuddy.text image create end -image [::skin::loadPixmap globe] -pady 5 -padx 5
	$pgBuddy.text insert end "[trans language]\n" lang_sel

	$pgBuddy.text insert end "\n\n\n\n"

	if { ([::config::getKey login] != "") && ([::config::getGlobalKey disableprofiles] != 1)} {
		if { $password != "" } {
			$pgBuddy.text insert end "[::config::getKey login]\n" start_login
			$pgBuddy.text insert end "[trans clicktologin]" start_login
		} else {
			$pgBuddy.text insert end "[::config::getKey login]\n" start_loginas
			$pgBuddy.text insert end "[trans clicktologin]" start_loginas
		}
		.main_menu.file entryconfigure 0 -label "[trans loginas] [::config::getKey login]"

		$pgBuddy.text insert end "\n\n\n\n\n"

		$pgBuddy.text insert end "[trans loginas]...\n" start_loginas
		$pgBuddy.text insert end "\n\n\n\n\n\n\n\n\n"

	} else {
		$pgBuddy.text insert end "[trans clicktologin]..." start_loginas

		$pgBuddy.text insert end "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

		.main_menu.file entryconfigure 0 -label "[trans loginas]..."
	}


	$pgBuddy.text insert end "   "
	$pgBuddy.text insert end "[trans checkver]...\n" check_ver

	$pgBuddy.text configure -state disabled


	#Log in
	.main_menu.file entryconfigure 0 -state normal
	.main_menu.file entryconfigure 1 -state normal
	#Log out
	.main_menu.file entryconfigure 2 -state disabled
	#My status
	.main_menu.file entryconfigure 3 -state disabled
	#Inbox
	.main_menu.file entryconfigure 5 -state disabled

	#Add a contact
	.main_menu.tools entryconfigure 0 -state disabled
	.main_menu.tools entryconfigure 1 -state disabled
	.main_menu.tools entryconfigure 4 -state disabled
	#Added by Trevor Feeney
	#Disables Group Order menu
	.main_menu.tools entryconfigure 5 -state disabled
	#Disables View Contacts by
	.main_menu.tools entryconfigure 6 -state disabled
	#Disable "View History"
	.main_menu.tools entryconfigure 8 -state disabled
	#Disable "View Event Logging"
	.main_menu.tools entryconfigure 9 -state disabled

	#Change nick
	configureMenuEntry .main_menu.actions "[trans changenick]..." disabled

	configureMenuEntry .main_menu.actions "[trans sendmail]..." disabled
	configureMenuEntry .main_menu.actions "[trans sendmsg]..." disabled

	configureMenuEntry .main_menu.actions "[trans sendmsg]..." disabled
	#configureMenuEntry .main_menu.actions "[trans verifyblocked]..." disabled
	#configureMenuEntry .main_menu.actions "[trans showblockedlist]..." disabled


	configureMenuEntry .main_menu.file "[trans savecontacts]..." disabled

	#Publish Phone Numbers
	#   configureMenuEntry .options "[trans publishphones]..." disabled

	#Initialize Preferences if window is open
	if { [winfo exists .cfg] } {
		InitPref
	}
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_reconnect { error_msg } {
	bind . <Configure> ""

	global pgBuddy

	$pgBuddy.text configure -state normal -font splainf
	$pgBuddy.text delete 0.0 end
	$pgBuddy.text tag conf signin -fore #000000 \
		-font sboldf -justify center
	$pgBuddy.text tag conf errormsg -fore #000000 \
		-font splainf -justify center -wrap word
	
	
	$pgBuddy.text insert end "\n\n\n\n\n"

	$pgBuddy.text tag conf cancel_reconnect -fore #000000 -underline true \
		-font splainf -justify center
	$pgBuddy.text tag bind cancel_reconnect <Enter> \
		"$pgBuddy.text tag conf cancel_reconnect -fore #0000A0 -underline false;\
		$pgBuddy.text conf -cursor hand2"
	$pgBuddy.text tag bind cancel_reconnect <Leave> \
		"$pgBuddy.text tag conf cancel_reconnect -fore #000000 -underline true;\
		$pgBuddy.text conf -cursor left_ptr"
	$pgBuddy.text tag bind cancel_reconnect <Button1-ButtonRelease> \
		"::MSN::cancelReconnect"
		
	catch {

		label .loginanim -background [$pgBuddy.text cget -background]
		::anigif::anigif [::skin::GetSkinFile pixmaps loganim.gif] .loginanim

		$pgBuddy.text insert end " " signin
		$pgBuddy.text window create end -window .loginanim
		$pgBuddy.text insert end " " signin

		bind .loginanim <Destroy> "::anigif::destroy .loginanim"
		tkwait visibility .loginanim

	}

	$pgBuddy.text insert end "\n\n"
	$pgBuddy.text insert end "$error_msg" errormsg
	$pgBuddy.text insert end "\n\n"
	$pgBuddy.text insert end "\n\n"
	$pgBuddy.text insert end "[trans reconnecting]..." signin
	$pgBuddy.text insert end "\n\n\n"
	$pgBuddy.text insert end "[trans cancel]" cancel_reconnect
	$pgBuddy.text configure -state disabled


}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_signin {} {
	bind . <Configure> ""

	global pgBuddy eventdisconnected

	set eventdisconnected 1

	wm title . "[trans title] - [::config::getKey login]"


	$pgBuddy.text configure -state normal -font splainf
	$pgBuddy.text delete 0.0 end
	$pgBuddy.text tag conf signin -fore #000000 \
		-font sboldf -justify center
	#$pgBuddy.text insert end "\n\n\n\n\n\n\n"
	$pgBuddy.text insert end "\n\n\n\n\n"

	catch {

		label .loginanim -background [$pgBuddy.text cget -background]
		::anigif::anigif [::skin::GetSkinFile pixmaps loganim.gif] .loginanim

		$pgBuddy.text insert end " " signin
		$pgBuddy.text window create end -window .loginanim
		$pgBuddy.text insert end " " signin

		bind .loginanim <Destroy> "::anigif::destroy .loginanim"
		tkwait visibility .loginanim

	}

	$pgBuddy.text insert end "\n\n"
	$pgBuddy.text insert end "[trans loggingin]..." signin
	$pgBuddy.text insert end "\n"
	$pgBuddy.text configure -state disabled


}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc login_ok {} {
	global password loginmode


	if { $loginmode == 0 } {
		::config::setKey login [string tolower [.login.main.f.f.loginentry get]]
		set password [.login.main.f.f.passentry get]
	} else {
		if { $password != [.login.main.f.f.passentry2 get] } {
			set password [.login.main.f.f.passentry2 get]
		}
	}

	catch {grab release .login}
	destroy .login

	if { $password != "" && [::config::getKey login] != "" } {
		::MSN::connect $password
	} else {
		cmsn_draw_login
	}

}
#///////////////////////////////////////////////////////////////////////

proc SSLToggled {} {
	if {[::config::getKey nossl] == 1 } {
		::amsn::infoMsg "[trans sslwarning]"
	}
}



#///////////////////////////////////////////////////////////////////////
# Main login window, separated profiled or default logins
# cmsn_draw_login {}
# 
proc cmsn_draw_login {} {

	global password loginmode HOME HOME2 protocol tcl_platform

	if {[winfo exists .login]} {
		raise .login
		return 0
	}

	LoadLoginList 1

	toplevel .login
	wm group .login .
#wm geometry .login 600x220
	wm title .login "[trans login] - [trans title]"
	ShowTransient .login
	set mainframe [LabelFrame:create .login.main -text [trans login] -font splainf]

	radiobutton $mainframe.button -text [trans defaultloginradio] -value 0 -variable loginmode -command "RefreshLogin $mainframe"
	label $mainframe.loginlabel -text "[trans user]: " -font sboldf
	entry $mainframe.loginentry -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 25
	if { [::config::getGlobalKey disableprofiles]!=1} { grid $mainframe.button -row 1 -column 1 -columnspan 2 -sticky w -padx 10 }
	grid $mainframe.loginlabel -row 2 -column 1 -sticky e -padx 10
	grid $mainframe.loginentry -row 2 -column 2 -sticky w -padx 10

	radiobutton $mainframe.button2 -text [trans profileloginradio] -value 1 -variable loginmode -command "RefreshLogin $mainframe"
	combobox::combobox $mainframe.box \
		-editable false \
		-highlightthickness 0 \
		-width 25 \
		-bg #FFFFFF \
		-font splainf \
		-command ConfigChange
	if { [::config::getGlobalKey disableprofiles]!=1} {
		grid $mainframe.button2 -row 1 -column 3 -sticky w
		grid $mainframe.box -row 2 -column 3 -sticky w
	}

	label $mainframe.passlabel -text "[trans pass]: " -font sboldf
	entry $mainframe.passentry -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 25 -show "*"
	entry $mainframe.passentry2 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 25 -show "*"
	checkbutton $mainframe.remember -variable [::config::getVar save_password] \
		-text "[trans rememberpass]" -font splainf -highlightthickness 0 -pady 5 -padx 10
	checkbutton $mainframe.offline -variable [::config::getVar startoffline] \
		-text "[trans startoffline]" -font splainf -highlightthickness 0 -pady 5 -padx 10

	#Set it, in case someone changes preferences...
	::config::setKey protocol 9

	checkbutton $mainframe.nossl -text "[trans disablessl]" -variable [::config::getVar nossl] -padx 10 -command SSLToggled

	label $mainframe.example -text "[trans examples] :\ncopypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com" -font examplef -padx 10

	set buttonframe [frame .login.buttons -class Degt]
	button $buttonframe.cancel -text [trans cancel] -command "ButtonCancelLogin .login"
	button $buttonframe.ok -text [trans ok] -command login_ok -default active
	button $buttonframe.addprofile -text [trans addprofile] -command AddProfileWin 
	if { [::config::getGlobalKey disableprofiles]!=1} {
		pack $buttonframe.ok $buttonframe.cancel $buttonframe.addprofile -side right -padx 10
	} else {
		pack $buttonframe.ok $buttonframe.cancel -side right -padx 10
	}

	grid $mainframe.passlabel -row 3 -column 1 -sticky e -padx 10
	grid $mainframe.passentry -row 3 -column 2 -sticky w -padx 10
	if { [::config::getGlobalKey disableprofiles]!=1} {
		grid $mainframe.passentry2 -row 3 -column 3 -sticky w
	}
	grid $mainframe.remember -row 5 -column 2 -sticky wn
	grid $mainframe.offline -row 6 -column 2 -sticky wn
	grid $mainframe.example -row 1 -column 4 -rowspan 4

	#if { [::config::getGlobalKey disableprofiles] != 1 } {
		grid $mainframe.nossl -row 7 -column 1 -sticky en -columnspan 4
	#}

	pack .login.main .login.buttons -side top -anchor n -expand true -fill both -padx 10 -pady 10

	# Lets fill our combobox
	#$mainframe.box insert 0 [::config::getKey login]
	set idx 0
	set tmp_list ""
	while { [LoginList get $idx] != 0 } {
		lappend tmp_list [LoginList get $idx]
		incr idx
	}
	eval $mainframe.box list insert end $tmp_list
	unset idx
	unset tmp_list

	# Select appropriate radio button
	if { $HOME == $HOME2 } {
		set loginmode 0
	} else {
		set loginmode 1
	}

	if { [::config::getGlobalKey disableprofiles]==1} {
		set loginmode 0
	}

	RefreshLogin $mainframe

	bind .login <Return> "login_ok"
	bind .login <<Escape>> "ButtonCancelLogin .login"

	#tkwait visibility .login
	catch {grab .login}
}

#///////////////////////////////////////////////////////////////////////
# proc RefreshLogin { mainframe }
# Called after pressing a radio button in the Login screen to enable/disable
# the appropriate entries
proc RefreshLogin { mainframe {extra 0} } {
	global loginmode

	if { $extra == 0 } {
		SwitchProfileMode $loginmode
	}

	if { $loginmode == 0 } {
		$mainframe.box configure -state disabled
		$mainframe.passentry2 configure -state disabled
		$mainframe.loginentry configure -state normal
		$mainframe.passentry configure -state normal
		$mainframe.remember configure -state disabled
		focus $mainframe.loginentry
		bind $mainframe.loginentry <Tab> "focus $mainframe.passentry; break"
	} elseif { $loginmode == 1 } {
		$mainframe.box configure -state normal
		$mainframe.passentry2 configure -state normal
		$mainframe.loginentry configure -state disabled
		$mainframe.passentry configure -state disabled
		$mainframe.remember configure -state normal
		focus $mainframe.passentry2
	}
}


#///////////////////////////////////////////////////////////////////////////////
# ButtonCancelLogin ()
# Function thats releases grab on .login and destroys it
proc ButtonCancelLogin { window {email ""} } {
	catch {grab release $window}
	destroy $window
	cmsn_draw_offline
}


#////////////////////////////////////////////////////////////////////// ///////// 
# AddProfileWin () 
# Small dialog window with entry to create new profile 
proc AddProfileWin {} { 

	global tcl_platform

	if {[winfo exists .add_profile]} { 
		raise .add_profile 
			return 0 
	} 

	toplevel .add_profile 
	wm group .add_profile .login 

	wm title .add_profile "[trans addprofile]" 

	ShowTransient .add_profile .login

	set mainframe [LabelFrame:create .add_profile.main -text [trans  addprofile] -font splainf] 
	label $mainframe.desc -text "[trans addprofiledesc]" -font splainf  -justify left 
	entry $mainframe.login -bg #FFFFFF -bd 1 -font splainf  -highlightthickness 0 -width 35 
	label $mainframe.example -text "[trans examples]  :\ncopypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com"  -font examplef -padx 10 
	grid $mainframe.desc -row 1 -column 1 -sticky w -columnspan 2 -padx 5  -pady 5 
	grid $mainframe.login -row 2 -column 1 -padx 5 -pady 5 
	grid $mainframe.example -row 2 -column 2 -sticky e 

	set buttonframe [frame .add_profile.buttons -class Degt] 
	button $buttonframe.cancel -text [trans cancel] -command "grab release  .add_profile; destroy .add_profile" 
	button $buttonframe.ok -text [trans ok] -command "AddProfileOk  $mainframe" 

	AddProfileOk $mainframe 

	pack  $buttonframe.cancel $buttonframe.ok -side right -padx 10 


	bind .add_profile <Return> "AddProfileOk $mainframe" 
	#Virtual binding for destroying the window
	bind .add_profile <<Escape>> "grab release .add_profile; destroy  .add_profile"
	

	pack .add_profile.main .add_profile.buttons -side top -anchor n -expand  true -fill both -padx 10 -pady 10 
	catch {grab .add_profile}
} 

#////////////////////////////////////////////////////////////////////// ///////// 
# AddProfileOk (mainframe) 
# 
proc AddProfileOk {mainframe} { 
	wm group .add_profile .login 
	set login [$mainframe.login get] 
	if { $login == "" } { 
		return 
	} 

	if { [CreateProfile $login] != -1 } { 
		catch {grab release .add_profile}
		destroy .add_profile 
	} 

}

#///////////////////////////////////////////////////////////////////////
proc toggleGroup {tw name image id {padx 0} {pady 0}} {
	label $tw.$name -image [::skin::loadPixmap $image]
	$tw.$name configure -cursor hand2 -borderwidth 0
	bind $tw.$name <Button1-ButtonRelease> "::groups::ToggleStatus $id; cmsn_draw_online"
	$tw window create end -window $tw.$name -padx $padx -pady $pady
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
proc clickableImage {tw name image command {padx 0} {pady 0}} {
	label $tw.$name -image [::skin::loadPixmap $image] -background white
	$tw.$name configure -cursor hand2 -borderwidth 0
	bind $tw.$name <Button1-ButtonRelease> $command
	$tw window create end -window $tw.$name -padx $padx -pady $pady -align center -stretch true
}
#///////////////////////////////////////////////////////////////////////

proc do_hotmail_login {} {
	global password
	hotmail_login [::config::getKey login] $password
}

if { $initialize_amsn == 1 } {
	init_ticket draw_online
}

#///////////////////////////////////////////////////////////////////////
# TODO: move into ::amsn namespace, and maybe improve it
proc cmsn_draw_online { {delay 0} } {

#Delay not forced redrawing (to avoid too many redraws)
	if { $delay } {
		after cancel "cmsn_draw_online"
		after 500 "cmsn_draw_online"
		return
	}
	
	#Run this procedure in mutual exclusion, to avoid procedure
	#calls due to events while still drawing. This fixes some bugs
	run_exclusive cmsn_draw_online_wrapped draw_online
}

proc cmsn_draw_online_wrapped {} {

	global login \
		password pgBuddy automessage emailBList tcl_platform

	set scrollidx [$pgBuddy.text yview]

	set my_name [::abook::getPersonal nick]
	set my_state_no [::MSN::stateToNumber [::MSN::myStatusIs]]
	set my_state_desc [trans [::MSN::stateToDescription [::MSN::myStatusIs]]]
	set my_colour [::MSN::stateToColor [::MSN::myStatusIs]]
	set my_image_type [::MSN::stateToBigImage [::MSN::myStatusIs]]

	#Clear every tag to avoid memory leaks:
	foreach tag [$pgBuddy.text tag names] {
		$pgBuddy.text tag delete $tag
	}

	# Decide which grouping we are going to use
	if {[::config::getKey orderbygroup]} {

		::groups::Enable

		#Order alphabetically
		set thelist [::groups::GetList]
		set thelistnames [list]

		foreach gid $thelist {
			#Ignore special group "Individuals" when sorting
			if { $gid != 0} {
				set thename [::groups::GetName $gid]
				lappend thelistnames [list "$thename" $gid]
			}
		}


		if {[::config::getKey ordergroupsbynormal]} {
			set sortlist [lsort -dictionary -index 0 $thelistnames ]
		} else {
			set sortlist [lsort -decreasing -dictionary -index 0 $thelistnames ]
		}

		#Make "Individuals" group (ID 0) always the first
		set glist [list 0] 

		foreach gdata $sortlist {
			lappend glist [lindex $gdata 1]
		}
		

		set gcnt [llength $glist]

		# Now setup each of the group's defaults
		for {set i 0} {$i < $gcnt} {incr i} {
			set gid [lindex $glist $i]
			::groups::UpdateCount $gid clear
		}

		if {[::config::getKey orderbygroup] == 2 } {
			lappend glist "offline"
			incr gcnt
		}

	} else {	# Order by Online/Offline
	# Defaults already set in setup_groups
		set glist [list online offline]
		set gcnt 2
		::groups::Disable
	}

	if { [::config::getKey showblockedgroup] == 1 && [llength [array names emailBList] ] != 0 } {
		lappend glist "blocked"
		incr gcnt
	}

	set list_users [::MSN::sortedContactList]

	$pgBuddy.text configure -state normal -font splainf
	$pgBuddy.text delete 0.0 end

	#Set up TAGS for mail notification
	$pgBuddy.text tag conf mail -fore black -underline true -font splainf
	$pgBuddy.text tag bind mail <Button1-ButtonRelease> "$pgBuddy.text conf -cursor watch; do_hotmail_login"
	$pgBuddy.text tag bind mail <Enter> \
	"$pgBuddy.text tag conf mail -under false;$pgBuddy.text conf -cursor hand2"
	$pgBuddy.text tag bind mail <Leave> \
	"$pgBuddy.text tag conf mail -under true;$pgBuddy.text conf -cursor left_ptr"

	# Configure bindings/tags for each named group in our scheme
	foreach gname $glist {

		if {$gname != "online" && $gname != "offline" && $gname != "blocked" } {
			set gtag  "tg$gname"
		} else {
			set gtag $gname
		}

		$pgBuddy.text tag conf $gtag -fore #000080 -font sboldf
		$pgBuddy.text tag bind $gtag <Button1-ButtonRelease> \
			"::groups::ToggleStatus $gname;cmsn_draw_online"
			
		#Don't add menu for "Individuals" group
		if { $gname != 0 } {
			#Specific for Mac OS X, Change button3 to button 2 and add control-click
			if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
				$pgBuddy.text tag bind $gtag <Button2-ButtonRelease> "::groups::GroupMenu $gname %X %Y"
				$pgBuddy.text tag bind $gtag <Control-ButtonRelease> "::groups::GroupMenu $gname %X %Y"
			} else {
				$pgBuddy.text tag bind $gtag <Button3-ButtonRelease> "::groups::GroupMenu $gname %X %Y"
			}
		}


		$pgBuddy.text tag bind $gtag <Enter> \
			"$pgBuddy.text tag conf $gtag -under true;$pgBuddy.text conf -cursor hand2"
		$pgBuddy.text tag bind $gtag <Leave> \
			"$pgBuddy.text tag conf $gtag -under false;$pgBuddy.text conf -cursor left_ptr"
	}

	#$pgBuddy.text insert end "\n"

	# Display MSN logo with user's handle. Make it clickable so
	# that the user can change his/her status that way
	clickableImage $pgBuddy.text bigstate $my_image_type {tk_popup .my_menu %X %Y} [::skin::getKey bigstate_xpad] [::skin::getKey bigstate_ypad]
	bind $pgBuddy.text.bigstate <<Button3>> {tk_popup .my_menu %X %Y}

	text $pgBuddy.text.mystatus -font bboldf -height 2 \
		-width [expr {([winfo width $pgBuddy.text]-45)/[font measure bboldf -displayof $pgBuddy.text "0"]}] \
		-background white -borderwidth 0 \
		-relief flat -highlightthickness 0 -selectbackground white -selectborderwidth 0 \
		-exportselection 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0
	pack $pgBuddy.text.mystatus -expand true -fill x

	$pgBuddy.text.mystatus configure -state normal

	$pgBuddy.text.mystatus tag conf mystatuslabel -fore gray -underline false \
		-font splainf

	$pgBuddy.text.mystatus tag conf mystatuslabel2 -fore gray -underline false \
		-font bboldf

	$pgBuddy.text.mystatus tag conf mystatus -fore $my_colour -underline false \
		-font bboldf

	$pgBuddy.text.mystatus tag bind mystatus <Enter> \
		"$pgBuddy.text.mystatus tag conf mystatus -under true;$pgBuddy.text.mystatus conf -cursor hand2"

	$pgBuddy.text.mystatus tag bind mystatus <Leave> \
		"$pgBuddy.text.mystatus tag conf mystatus -under false;$pgBuddy.text.mystatus conf -cursor left_ptr"

	$pgBuddy.text.mystatus tag bind mystatus <Button1-ButtonRelease> "tk_popup .my_menu %X %Y"
	#Change button mouse on Mac OS X
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		$pgBuddy.text.mystatus tag bind mystatus <Button2-ButtonRelease> "tk_popup .my_menu %X %Y"
		$pgBuddy.text.mystatus tag bind mystatus <Control-ButtonRelease> "tk_popup .my_menu %X %Y"
	} else {
		$pgBuddy.text.mystatus tag bind mystatus <Button3-ButtonRelease> "tk_popup .my_menu %X %Y"
	}
	$pgBuddy.text.mystatus insert end "[trans mystatus]: " mystatuslabel

	if { [info exists automessage] && $automessage != -1} {
		$pgBuddy.text.mystatus insert end "[lindex $automessage 0]\n" mystatuslabel2
	} else {
		$pgBuddy.text.mystatus insert end "\n" mystatuslabel
	}

	set maxw [expr [winfo width $pgBuddy.text] - 50]
	incr maxw [expr 0-[font measure bboldf -displayof $pgBuddy.text " ($my_state_desc)" ]]
	set my_short_name [trunc $my_name $pgBuddy.text.mystatus $maxw bboldf]
	$pgBuddy.text.mystatus insert end "$my_short_name " mystatus
	$pgBuddy.text.mystatus insert end "($my_state_desc)" mystatus

	set balloon_message "[string map {"%" "%%"} "$my_name\n [::config::getKey login]\n [trans status] : $my_state_desc"]"

	$pgBuddy.text.mystatus tag bind mystatus <Enter> +[list balloon_enter %W %X %Y $balloon_message]

	$pgBuddy.text.mystatus tag bind mystatus <Leave> \
		"+set Bulle(first) 0; kill_balloon"

	$pgBuddy.text.mystatus tag bind mystatus <Motion> +[list balloon_motion %W %X %Y $balloon_message]

	bind $pgBuddy.text.bigstate <Enter> +[list balloon_enter %W %X %Y $balloon_message]
	bind $pgBuddy.text.bigstate <Leave> \
		"+set Bulle(first) 0; kill_balloon;"
	bind $pgBuddy.text.bigstate <Motion> +[list balloon_motion %W %X %Y $balloon_message]

	if {[::config::getKey listsmileys]} {
		::smiley::substSmileys $pgBuddy.text.mystatus
	}
	#Calculate number of lines, and set my status size (for multiline nicks)
	set size [$pgBuddy.text.mystatus index end]
	set posyx [split $size "."]
	set lines [expr {[lindex $posyx 0] - 1}]
	if { [expr [llength [$pgBuddy.text.mystatus image names]] + [llength [$pgBuddy.text.mystatus window names]]] } { incr lines }

	$pgBuddy.text.mystatus configure -state normal -height $lines -wrap none
	$pgBuddy.text.mystatus configure -state disabled

	$pgBuddy.text window create end -window $pgBuddy.text.mystatus -padx [::skin::getKey mystatus_xpad] -pady [::skin::getKey mystatus_ypad] -align bottom -stretch false
	$pgBuddy.text insert end "\n"

	$pgBuddy.text image create end -image [::skin::getColorBar]
	$pgBuddy.text insert end "\n"

  	set evpar(text) $pgBuddy.text
  	::plugins::PostEvent ContactListColourBarDrawn evpar

	if { [::config::getKey checkemail] } {
		# Show Mail Notification status
		clickableImage $pgBuddy.text mailbox mailbox [list hotmail_login [::config::getKey login] $password] [::skin::getKey mailbox_xpad] [::skin::getKey mailbox_ypad]

		set unread [::hotmail::unreadMessages]

		if {$unread == 0} {
			set mailmsg "[trans nonewmail]\n"
		} elseif {$unread == 1} {
			set mailmsg "[trans onenewmail]\n"
		} elseif {$unread == 2} {
			set mailmsg "[trans twonewmail 2]\n"
		} else {
			set mailmsg "[trans newmail $unread]\n"
		}

	  	set evpar(text) pgBuddy.text
		set evpar(msg) mailmsg
  		::plugins::PostEvent ContactListEmailsDraw evpar	

		set maxw [expr [winfo width $pgBuddy.text] -30]
		set short_mailmsg [trunc $mailmsg $pgBuddy.text $maxw splainf]
		$pgBuddy.text insert end "$short_mailmsg\n" mail
		$pgBuddy.text tag add dont_replace_smileys mail.first mail.last
	}

  	set evpar(text) pgBuddy.text
  	::plugins::PostEvent ContactListEmailsDrawn evpar	


	# For each named group setup its heading where >><< image
	# appears together with the group name and total nr. of handles
	# [<<] My Group Name (n)
	for {set gidx 0} {$gidx < $gcnt} {incr gidx} {

		set gname [lindex $glist $gidx]
		set gtag  "tg$gname"
		

		if { [::groups::IsExpanded $gname] } {
			toggleGroup $pgBuddy.text contract$gname contract $gname [::skin::getKey contract_xpad] [::skin::getKey contract_ypad]
		} else {
			toggleGroup $pgBuddy.text expand$gname expand $gname [::skin::getKey expand_xpad] [::skin::getKey expand_ypad]
		}

		# Show the group's name/title
		if {[::config::getKey orderbygroup]} {

			# For user defined groups we don't have/need translations
			set gtitle [::groups::GetName $gname]

				if { [::config::getKey orderbygroup] == 2 } {
					if { $gname == "offline" } {
						set gtitle "[trans uoffline]"
						set gtag "offline"
					}
				}

			if { $gname == "blocked" } {
				set gtitle "[trans youblocked]"
				set gtag "blocked"
			}

		$pgBuddy.text insert end $gtitle $gtag

		} else {

			if {$gname == "online"} {
				$pgBuddy.text insert end "[trans uonline]" online
			} elseif {$gname == "offline" } {
				$pgBuddy.text insert end "[trans uoffline]" offline
			} elseif { [::config::getKey showblockedgroup] == 1 && [llength [array names emailBList] ] != 0 } {
				$pgBuddy.text insert end "[trans youblocked]" blocked
			}

		}
		
		if { [::config::getKey nogap] } {
			$pgBuddy.text insert end "\n"
		} else {
			$pgBuddy.text insert end "\n\n"
		}
	}

	::groups::UpdateCount online clear
	::groups::UpdateCount offline clear
	::groups::UpdateCount blocked clear

	#Draw the users in each group
	#Go thru list in reverse order, as every item is inserted at the beginning, not the end...
	for {set i [expr {[llength $list_users] - 1}]} {$i >= 0} {incr i -1} {
		set user_login [lindex $list_users $i]
		set user_name [::abook::getDisplayNick $user_login]
		
		set state_code [::abook::getVolatileData $user_login state FLN]		
		set colour [::MSN::stateToColor $state_code]
		if { [::abook::getContactData $user_login customcolor] != "" } {
			set colour [::abook::getContactData $user_login customcolor] 
		}
		set state_section [::MSN::stateToSection $state_code]; # Used in online/offline grouping

		if { $state_section == "online"} {
			::groups::UpdateCount online +1
		} elseif {$state_section == "offline"} {
			::groups::UpdateCount offline +1
		}


		set breaking ""

		if { [::config::getKey orderbygroup] } {
			foreach user_group [::abook::getGroups $user_login] {
				set section "tg$user_group"

				if { $section == "tgblocked" } {set section "blocked" }

				::groups::UpdateCount $user_group +1 $state_section

				if { [::config::getKey orderbygroup] == 2 } {
					if { $state_code == "FLN" } { set section "offline"}
					if { $breaking == "$user_login" } { continue }
				}
				
				set myGroupExpanded [::groups::IsExpanded $user_group]

				if { [::config::getKey orderbygroup] == 2 } {
					if { $state_code == "FLN" } {
						set myGroupExpanded [::groups::IsExpanded offline]
					}
				}

				if {$myGroupExpanded} {
					ShowUser $user_name $user_login $state_code $colour $section $user_group
				}

				#Why "breaking"? Why not just a break? Or should we "continue" instead of breaking?
				if { [::config::getKey orderbygroup] == 2 && $state_code == "FLN" } { set breaking $user_login}

			}
		} elseif {[::groups::IsExpanded $state_section]} {
				ShowUser $user_name $user_login $state_code $colour $state_section 0
		}

		if { [::config::getKey showblockedgroup] == 1 && [info exists emailBList($user_login)]} {
			::groups::UpdateCount blocked +1
			if {[::groups::IsExpanded blocked]} {
				ShowUser $user_name $user_login $state_code $colour "blocked" [lindex [::abook::getGroups $user_login] 0]
			}
		}
	}

	if {[::config::getKey orderbygroup]} {
		for {set gidx 0} {$gidx < $gcnt} {incr gidx} {
			set gname [lindex $glist $gidx]
			set gtag  "tg$gname"
			
			#If we're managing special group "Individuals" (ID == 0), then remove header if:
			# 1) we're in hybrid mode and there are no online contacts
			# 2) or we're in group mode and there're no contacts (online or offline)
			if { ($gname == 0 || ([::config::getKey removeempty] && $gname != "offline")) &&
				(($::groups::uMemberCnt_online($gname) == 0 && [::config::getKey orderbygroup] == 2) ||
				 ($::groups::uMemberCnt($gname) == 0 && [::config::getKey orderbygroup] == 1))} {
				set endidx [split [$pgBuddy.text index $gtag.last] "."]
				if { [::config::getKey nogap] } {
					$pgBuddy.text delete $gtag.first [expr {[lindex $endidx 0]+1}].0
				} else {
					$pgBuddy.text delete $gtag.first [expr {[lindex $endidx 0]+2}].0
				}
				if { [::groups::IsExpanded $gname] } {
					destroy $pgBuddy.text.contract$gname
				} else {
					destroy $pgBuddy.text.expand$gname
				}
				
				continue
			}
			
			if {[::config::getKey orderbygroup] == 2 } {
				if { $gname == "offline" } {
					$pgBuddy.text insert offline.last " ($::groups::uMemberCnt(offline))" offline
					$pgBuddy.text tag add dont_replace_smileys offline.first offline.last
				} elseif { $gname == "blocked" } {
					$pgBuddy.text insert blocked.last " ($::groups::uMemberCnt(blocked))" blocked
					$pgBuddy.text tag add dont_replace_smileys blocked.first blocked.last
				} else {
					$pgBuddy.text insert ${gtag}.last \
						" ($::groups::uMemberCnt_online(${gname}))" $gtag
					$pgBuddy.text tag add dont_replace_smileys $gtag.first $gtag.last
				}
			} else {
				if { $gname == "blocked" } {
					$pgBuddy.text insert blocked.last " ($::groups::uMemberCnt(blocked))" blocked
					$pgBuddy.text tag add dont_replace_smileys blocked.first blocked.last
				} else {
					$pgBuddy.text insert ${gtag}.last \
						" ($::groups::uMemberCnt_online(${gname})/$::groups::uMemberCnt($gname))" $gtag
					$pgBuddy.text tag add dont_replace_smileys $gtag.first $gtag.last
				}
			}
		}
	} else {
		$pgBuddy.text insert online.last " ($::groups::uMemberCnt(online))" online
		$pgBuddy.text insert offline.last " ($::groups::uMemberCnt(offline))" offline
		$pgBuddy.text tag add dont_replace_smileys online.first online.last
		$pgBuddy.text tag add dont_replace_smileys offline.first offline.last

		if { [::config::getKey showblockedgroup] == 1 && [llength [array names emailBList]] } {
			$pgBuddy.text insert blocked.last " ($::groups::uMemberCnt(blocked))" blocked
			$pgBuddy.text tag add dont_replace_smileys blocked.first blocked.last
		}
	}

	$pgBuddy.text configure -state disabled

	#Init Preferences if window is open
	if { [winfo exists .cfg] } {
		InitPref
	}

	global wingeom
	set wingeom [list [winfo width .] [winfo height .]]

	bind . <Configure> "configured_main_win"
	#wm protocol . WM_RESIZE_WINDOW "cmsn_draw_online"


	#Don't replace smileys in all text, to avoid replacing in mail notification
	if {[::config::getKey listsmileys]} {
		::smiley::substSmileys $pgBuddy.text 0.0 end
	}
	update idletasks
	$pgBuddy.text yview moveto [lindex $scrollidx 0]

	#Pack what is necessary for event menu
	if { [::log::checkeventdisplay] } {
		pack configure .main.eventmenu.list -fill x -ipadx 10
		pack configure .main.eventmenu -side bottom -fill x
		::log::eventlogin
		.main.eventmenu.list select 0
	} else {
		pack forget .main.eventmenu
	}


}
#///////////////////////////////////////////////////////////////////////

proc configured_main_win {{w ""}} {
	global wingeom
	set w [winfo width .]
	set h [winfo height .]
	if { [lindex $wingeom 0] != $w  || [lindex $wingeom 1] != $h} {
		set wingeom [list $w $h]
		cmsn_draw_online 1
	}
}

proc getUniqueValue {} {
	global uniqueValue

	if {![info exists uniqueValue]} {
		set uniqueValue 0
	}
	incr uniqueValue
	return $uniqueValue
}


#///////////////////////////////////////////////////////////////////////
proc ShowUser {user_name user_login state_code colour section grId} {
	global pgBuddy emailBList Bulle tcl_platform

	if {($state_code != "NLN") && ($state_code !="FLN")} {
		set state_desc " ([trans [::MSN::stateToDescription $state_code]])"
	} else {
		set state_desc ""
	}

	set user_unique_name "$user_login[getUniqueValue]"
	set user_ident "    "

	# If user is not in the Reverse List it means (s)he has not
	# yet added/approved us. Show their name in pink. A way
	# of knowing how has a) not approved you yet, or b) has
	# removed you from their contact list even if you still
	# have them... MOVED TO THE NEW ICON

	set image_type [::MSN::stateToImage $state_code]


	if { [info exists emailBList($user_login)]} {
		set colour #FF0000
		set image_type "blockedme"
	}


	if {[lsearch [::abook::getLists $user_login] BL] != -1} {
		set image_type "blocked"
		if {$state_desc == ""} {set state_desc " ([trans blocked])"}
	}
	

	$pgBuddy.text tag conf $user_unique_name -fore $colour


	$pgBuddy.text mark set new_text_start end

	if { [::config::getKey emailsincontactlist] } {
		set user_lines "$user_login"
	} else {
		set user_lines [split $user_name "\n"]
	}
	set last_element [expr {[llength $user_lines] -1 }]

	$pgBuddy.text insert $section.last " $state_desc" $user_unique_name

	#Set maximum width for nick string, with some margin
	set maxw [winfo width $pgBuddy.text]
	incr maxw -20
	#Decrement status text out of max line width
	set statew [font measure splainf -displayof $pgBuddy.text " $state_desc "]
	set blanksw [font measure splainf -displayof $pgBuddy.text $user_ident]
	incr maxw [expr {-25-$statew-$blanksw}]
	if { [::alarms::isEnabled $user_login] != "" } {
		incr maxw -25
	}

	for {set i $last_element} {$i >= 0} {set i [expr {$i-1}]} {
		if { $i != $last_element} {
			set current_line " [lindex $user_lines $i]\n"
		} else {
			set current_line " [lindex $user_lines $i]"
		}

		if {[::config::getKey truncatenames]} {
			if { $i == $last_element && $i == 0} {
				#First and only line
				set strw $maxw
			} elseif { $i == $last_element } {
				#Last line, not status icon
				set strw [expr {$maxw+25}]
			} elseif {$i == 0} {
				#First line of a multiline nick, so no status description
				set strw [expr {$maxw+$statew}]
			} else {
				#Middle line, no status description and no status icon
				set strw [expr {$maxw+$statew+25}]
			} 
			set current_line [trunc $current_line $pgBuddy $strw splainf]
		}

		$pgBuddy.text insert $section.last "$current_line" $user_unique_name
		if { $i != 0} {
			$pgBuddy.text insert $section.last $user_ident
		}
	}
	#$pgBuddy.text insert $section.last " $user_name$state_desc \n" $user_login

	#	Draw the not-in-reverse-list icon
	set not_in_reverse [expr {[lsearch [::abook::getLists $user_login] RL] == -1}]
	if {$not_in_reverse} {
		set imgname2 "img2_[getUniqueValue]"
		label $pgBuddy.text.$imgname2 -image [::skin::loadPixmap notinlist]
		$pgBuddy.text.$imgname2 configure -cursor hand2 -borderwidth 0
		$pgBuddy.text window create $section.last -window $pgBuddy.text.$imgname2 -padx 1 -pady 1
		bind $pgBuddy.text.$imgname2 <Enter> \
		"$pgBuddy.text tag conf $user_unique_name -under [::skin::getKey underline_contact]; $pgBuddy.text conf -cursor hand2"
		bind $pgBuddy.text.$imgname2 <Leave> \
			"$pgBuddy.text tag conf $user_unique_name -under false; $pgBuddy.text conf -cursor left_ptr"

	}
	
	#	Draw alarm icon if alarm is set
	if { [::alarms::isEnabled $user_login] != ""} {
		#set imagee [string range [string tolower $user_login] 0 end-8]
		#trying to make it non repetitive without the . in it
		#Patch from kobasoft
		set imagee "alrmimg_[getUniqueValue]"
		#regsub -all "\[^\[:alnum:\]\]" [string tolower $user_login] "_" imagee

		if { [::alarms::isEnabled $user_login] } {
			label $pgBuddy.text.$imagee -image [::skin::loadPixmap bell]
		} else {
			label $pgBuddy.text.$imagee -image [::skin::loadPixmap belloff]
		}

		$pgBuddy.text.$imagee configure -cursor hand2 -borderwidth 0
		$pgBuddy.text window create $section.last -window $pgBuddy.text.$imagee  -padx 1 -pady 1
		bind $pgBuddy.text.$imagee <Button1-ButtonRelease> "switch_alarm $user_login $pgBuddy.text.$imagee"

		bind $pgBuddy.text.$imagee <<Button3>> "::alarms::configDialog $user_login"
	}


	#set imgname "img[expr {$::groups::uMemberCnt(online)+$::groups::uMemberCnt(offline)}]"
	set imgname "img[getUniqueValue]"
	label $pgBuddy.text.$imgname -image [::skin::loadPixmap $image_type]
	$pgBuddy.text.$imgname configure -cursor hand2 -borderwidth 0
	if { $last_element > 0 } {
		$pgBuddy.text window create $section.last -window $pgBuddy.text.$imgname -padx 3 -pady 1 -align baseline
	} else {
		$pgBuddy.text window create $section.last -window $pgBuddy.text.$imgname -padx 3 -pady 1 -align center
	}

	$pgBuddy.text insert $section.last "\n$user_ident"


	$pgBuddy.text tag bind $user_unique_name <Enter> \
		"$pgBuddy.text tag conf $user_unique_name -under [::skin::getKey underline_contact]; $pgBuddy.text conf -cursor hand2"

	$pgBuddy.text tag bind $user_unique_name <Leave> \
		"$pgBuddy.text tag conf $user_unique_name -under false;	$pgBuddy.text conf -cursor left_ptr"

	bind $pgBuddy.text.$imgname <Enter> \
		"$pgBuddy.text tag conf $user_unique_name -under [::skin::getKey underline_contact]; $pgBuddy.text conf -cursor hand2"
	bind $pgBuddy.text.$imgname <Leave> \
		"$pgBuddy.text tag conf $user_unique_name -under false;	$pgBuddy.text conf -cursor left_ptr"




	if { [::config::getKey tooltips] == 1 } {
		if {$not_in_reverse} {
			set balloon_message2 "\n[trans notinlist]"
		} else {
			set balloon_message2 ""
		}
		if {[::config::getKey orderbygroup] == 0} {
			set gname ""
			set glist [::abook::getGroups $user_login]
			foreach i $glist {
				set gname "$gname [::groups::GetName $i]"
			}
			set balloon_message3 "\n[trans group] : $gname"
		} else {
			set balloon_message3 ""
		}
		if {$state_code == "FLN"} {
			set balloon_message4 "\n[trans lastseen] : [::abook::dateconvert "[::abook::getContactData $user_login last_seen]"]"
		} else {
			set balloon_message4 ""
		}
		set balloon_message "[string map {"%" "%%"} [::abook::getNick $user_login]]\n$user_login\n[trans status] : [trans [::MSN::stateToDescription $state_code]] $balloon_message2 $balloon_message3 $balloon_message4\n[trans lastmsgedme] : [::abook::dateconvert "[::abook::getContactData $user_login last_msgedme]"]"
		$pgBuddy.text tag bind $user_unique_name <Enter> +[list balloon_enter %W %X %Y $balloon_message]

		$pgBuddy.text tag bind $user_unique_name <Leave> \
			"+set Bulle(first) 0; kill_balloon"

		$pgBuddy.text tag bind $user_unique_name <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		bind $pgBuddy.text.$imgname <Enter> +[list balloon_enter %W %X %Y $balloon_message]
		bind $pgBuddy.text.$imgname <Leave> \
			"+set Bulle(first) 0; kill_balloon"

		bind $pgBuddy.text.$imgname <Motion> +[list balloon_motion %W %X %Y $balloon_message]

		if {$not_in_reverse} {
			bind $pgBuddy.text.$imgname2 <Enter> +[list balloon_enter %W %X %Y $balloon_message]
			bind $pgBuddy.text.$imgname2 <Leave> \
				"+set Bulle(first) 0; kill_balloon"
		
			bind $pgBuddy.text.$imgname2 <Motion> +[list balloon_motion %W %X %Y $balloon_message]
		}
	}
	#Change mouse button and add control-click on Mac OS X
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		$pgBuddy.text tag bind $user_unique_name <Button2-ButtonRelease> "show_umenu $user_login $grId %X %Y"
		$pgBuddy.text tag bind $user_unique_name <Control-ButtonRelease> "show_umenu $user_login $grId %X %Y"
	} else {
		$pgBuddy.text tag bind $user_unique_name <Button3-ButtonRelease> "show_umenu $user_login $grId %X %Y"
	}
	bind $pgBuddy.text.$imgname <<Button3>> "show_umenu $user_login $grId %X %Y"
	if {$not_in_reverse} {
		bind $pgBuddy.text.$imgname2 <<Button3>> "show_umenu $user_login $grId %X %Y"
	}
	
	if { [::config::getKey sngdblclick] } {
		set singordblclick <Button-1>
	} else {
		set singordblclick <Double-Button-1>
	}
	if { $state_code != "FLN" } {
		bind $pgBuddy.text.$imgname $singordblclick "::amsn::chatUser $user_login"
		if {$not_in_reverse} {
			bind $pgBuddy.text.$imgname2 $singordblclick "::amsn::chatUser $user_login"
		}
		$pgBuddy.text tag bind $user_unique_name $singordblclick \
			"::amsn::chatUser $user_login"
	} else {
		bind $pgBuddy.text.$imgname $singordblclick ""
		if {$not_in_reverse} {
			bind $pgBuddy.text.$imgname2 $singordblclick ""
		}
		$pgBuddy.text tag bind $user_unique_name $singordblclick ""
	}

}
#///////////////////////////////////////////////////////////////////////

proc balloon_enter {window x y msg} {
	global Bulle
	#"+set Bulle(set) 0;set Bulle(first) 1; set Bulle(id) \[after 1000 [list balloon %W [list $balloon_message)] %X %Y]\]"
	set Bulle(set) 0
	set Bulle(first) 1
	set Bulle(id) [after 1000 [list balloon ${window} ${msg} $x $y]]
}

proc balloon_motion {window x y msg} {
	global Bulle
	#"if {\[set Bulle(set)\] == 0} \{after cancel \[set Bulle(id)\]; \
	#         set Bulle(id) \[after 1000 [list balloon %W [list $balloon_message] %X %Y]\]\} "
	if {[set Bulle(set)] == 0} {
		after cancel [set Bulle(id)]
		set Bulle(id) [after 1000 [list balloon ${window} ${msg} $x $y]]
	}
}

# trunc(str, nchars)
#
# Truncates a string to at most nchars characters and places an ellipsis "..."
# at the end of it. nchars should include the three characters of the ellipsis.
# If the string is too short or nchars is too small, the ellipsis is not
# appended to the truncated string.
#
proc trunc {str {window ""} {maxw 0 } {font ""}} {
	if { $window == "" || $font == "" || [::config::getKey truncatenames]!=1} {
		return $str
	}

	for {set idx 0} { $idx <= [string length $str]} {incr idx} {
		if { [font measure $font -displayof $window "[string range $str 0 $idx]..."] > $maxw } {
			if { [string index $str end] == "\n" } {
				return "[string range $str 0 [expr {$idx-1}]]...\n"
			} else {
				return "[string range $str 0 [expr {$idx-1}]]..."
			}
		}
	}
	return $str

	set elen 3  ;# The three characters of "..."
	set slen [string length $str]

	if {$nchars <= $elen || $slen <= $elen || $nchars >= $slen} {
		set s [string range $str 0 [expr $nchars - 1]]
	} else {
		set s "[string range $str 0 [expr $nchars - $elen - 1]]..."
	}

	return $s
}

proc tk_textCopy { w } {
	copy 0 $w
}

proc tk_textCut { w } {
	copy 1 $w
}

proc tk_textPaste { w } {
	paste $w
}


#///////////////////////////////////////////////////////////////////////
proc copy { cut w } {

#Try this (for chat windows)
	set window $w.f.bottom.left.in.text

	if { [ catch {$window tag ranges sel}]} {
		set window $w
	}

	set index [$window tag ranges sel]

	if { $index == "" } {
		set window [::ChatWindow::GetTopText $w]
		catch {set index [$window tag ranges sel]}
		if { $index == "" } {  return }
	}

	#status_log "Copy: focus is [focus], window is $window\n" return

	clipboard clear

	set dump [$window dump -text [lindex $index 0] [lindex $index 1]]

	foreach { text output index } $dump {
		clipboard append "$output"
	}

#    selection clear
	if { $cut == "1" } { catch { $window delete sel.first sel.last } }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc paste { window {middle 0} } {
	if { [catch {selection get} res] != 0 } {
		catch {
			set contents [ selection get -selection CLIPBOARD ]
			$window.f.bottom.left.in.text insert insert $contents
		}
		#puts "CLIPBOARD selection enabled"
	} else {
		if { $middle == 0} {
			catch {
				set contents [ selection get -selection CLIPBOARD ]
				$window.f.bottom.left.in.text insert insert $contents
			}
			#puts "CLIPBOARD selection enabled"
		} else {
			#puts "PRIMARY selection enabled"
		}
	}
}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_addcontact {} {
	global lang pcc

	if {[winfo exists .addcontact]} {
		catch {
			raise .addcontact
			focus .addcontact.email
		}
		set pcc 0
		return 0
	}

	toplevel .addcontact
	wm group .addcontact .

	wm title .addcontact "[trans addacontact] - [trans title]"

	label .addcontact.l -font sboldf -text "[trans entercontactemail]:"
	entry .addcontact.email -width 50 -bg #FFFFFF -bd 1 -font splainf
	label .addcontact.example -font examplef -justify left \
		-text "[trans examples]:\ncopypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com"

	frame .addcontact.group
	combobox::combobox .addcontact.group.list -editable false -highlightthickness 0 -width 22 -bg #FFFFFF -font splainf -exportselection false
	set groups [::groups::GetList]
	foreach gid $groups {
		.addcontact.group.list list insert end "[::groups::GetName $gid]"
	}
	.addcontact.group.list select 0
	label .addcontact.group.l -font sboldf -text "[trans group] : "
	pack .addcontact.group.l -side left
	pack .addcontact.group.list -side left

	frame .addcontact.b	
	button .addcontact.b.next -text "[trans next]->" -command addcontact_next
	button .addcontact.b.cancel -text [trans cancel] \
		-command "set pcc 0; destroy .addcontact" 
	bind .addcontact <<Escape>> "set pcc 0; destroy .addcontact"
	pack .addcontact.b.next .addcontact.b.cancel -side right -padx 5

	
	pack .addcontact.l -side top -anchor sw -padx 10 -pady 3
	pack .addcontact.email -side top -fill x -padx 10 -pady 3
	pack .addcontact.example -side top -anchor nw -padx 10 -pady 3
	pack .addcontact.group -side top -fill x -padx 10 -pady 3
	pack .addcontact.b -side top -pady 3 -expand true -fill x -anchor se

	bind .addcontact.email <Return> "addcontact_next"
	catch {
		raise .addcontact
		focus .addcontact.email
	}

}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
# Check if the "add contact" window is open and then re-make the group list
proc cmsn_draw_grouplist {} {

	.addcontact.group.list list delete 0 end
	set groups [::groups::GetList]
	foreach gid $groups {
		.addcontact.group.list list insert end "[::groups::GetName $gid]"
	}

}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc addcontact_next {} {
	set tmp_email [.addcontact.email get]
	if { $tmp_email != ""} {
		set group [.addcontact.group.list curselection]
		set gid [lindex [::groups::GetList] $group]
		::MSN::addUser "$tmp_email" "" $gid
		catch {grab release .addcontact}
		destroy .addcontact
	}
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_otherwindow { title command } {

	if {[winfo exists .otherwindow] } {
		destroy .otherwindow
	}
	toplevel .otherwindow
	wm group .otherwindow .
	wm title .otherwindow "$title"
	
	label .otherwindow.l -font sboldf -text "[trans entercontactemail]:"
	entry .otherwindow.email -width 50 -bg #FFFFFF -bd 1 \
		-font splainf
		
	frame .otherwindow.b
	button .otherwindow.b.ok -text "[trans ok]" \
		-command "run_command_otherwindow \"$command\""
	button .otherwindow.b.cancel -text [trans cancel]  \
		-command "grab release .otherwindow;destroy .otherwindow" 
		
	pack .otherwindow.b.ok .otherwindow.b.cancel -side right -padx 5

	pack .otherwindow.l -side top -anchor sw -padx 10 -pady 3
	pack .otherwindow.email -side top -expand true -fill x -padx 10 -pady 3
	pack .otherwindow.b -side top -pady 3 -expand true -anchor se

	bind .otherwindow.email <Return> "run_command_otherwindow \"$command\""
	focus .otherwindow.email

	tkwait visibility .otherwindow
}
#///////////////////////////////////////////////////////////////////////





#///////////////////////////////////////////////////////////////////////
proc newcontact {new_login new_name} {
	global tcl_platform


	set login [split $new_login "@ ."]
	set login [join $login "_"]
	set wname ".newc_$login"

	if { [catch {toplevel ${wname} } ] } {
		return 0
	}
	wm group ${wname} .

	wm geometry ${wname} -0+100
	wm title ${wname} "$new_name - [trans title]"


	global newc_add_to_list_${wname}
	if {[lsearch [::abook::getLists $new_login] FL] != -1} {
		set add_stat "disabled"
		set newc_add_to_list_${wname} 0
	} else {
		set add_stat "normal"
		set newc_add_to_list_${wname} 1
	}
	global newc_allow_block_${wname}
	set newc_allow_block_${wname} 1

	label ${wname}.l1 -font splainf -justify left -wraplength 300 \
		-text "[trans addedyou $new_name $new_login]"
	label ${wname}.l2 -font splainf -text "[trans youwant]:"
	radiobutton ${wname}.allow  -value "1" -variable newc_allow_block_${wname} \
		-text [trans allowseen] \
		-highlightthickness 0 \
		-activeforeground #FFFFFF -selectcolor #FFFFFF -font sboldf
	radiobutton ${wname}.block -value "0" -variable newc_allow_block_${wname} \
		-text [trans avoidseen] \
		-highlightthickness 0 \
		-activeforeground #FFFFFF -selectcolor #FFFFFF  -font sboldf
	checkbutton ${wname}.add -var newc_add_to_list_${wname} -state $add_stat \
		-text [trans addtoo] -font sboldf \
		-highlightthickness 0 -activeforeground #FFFFFF -selectcolor #FFFFFF

	frame ${wname}.b
	button ${wname}.b.ok -text [trans ok]  \
		-command [list newcontact_ok ${wname} $new_login $new_name]
	button ${wname}.b.cancel -text [trans cancel]\
		-command [list destroy ${wname}]
	pack ${wname}.b.ok ${wname}.b.cancel -side right -padx 5
	
	pack ${wname}.l1 -side top -pady 3 -padx 5 -anchor nw
	pack ${wname}.l2 -side top -pady 3 -padx 5 -anchor w
	pack ${wname}.allow -side top -pady 0 -padx 15 -anchor w
	pack ${wname}.block -side top -pady 0 -padx 15 -anchor w
	pack ${wname}.add -side top -pady 3 -padx 5 -anchor w
	pack ${wname}.b -side top -pady 3 -anchor se -expand true -fill x

}
#///////////////////////////////////////////////////////////////////////

proc newcontact_ok { w x0 x1 } {
	
	global newc_allow_block_$w newc_add_to_list_$w
	set newc_allow_block [set newc_allow_block_$w]
	set newc_add_to_list [set newc_add_to_list_$w]
	
	if {$newc_allow_block == "1"} {
		::MSN::WriteSB ns "ADD" "AL $x0 [urlencode $x1]"
	} else {
		::MSN::WriteSB ns "ADD" "BL $x0 [urlencode $x1]"
	}
	if {$newc_add_to_list} {
		::MSN::addUser $x0 [urlencode $x1]
	}
	
	destroy $w
}


#///////////////////////////////////////////////////////////////////////
proc cmsn_change_name {} {

	set w .change_name
	if {[winfo exists $w]} {
		raise $w
		return 0
	}

	toplevel $w
	wm group $w .
	wm title $w "[trans changenick] - [trans title]"

	#ShowTransient $w


	frame $w.fn
	label $w.fn.label -font sboldf -text "[trans enternick]:"
	entry $w.fn.name -width 40 -bg #FFFFFF -bd 1 -font splainf
	button $w.fn.smiley -image [::skin::loadPixmap butsmile] -relief flat -padx 3 -highlightthickness 0
	button $w.fn.newline -image [::skin::loadPixmap butnewline] -relief flat -padx 3 -command "$w.fn.name insert end \"\n\""

	frame $w.p4c
	label $w.p4c.label -font sboldf -text "[trans friendlyname]:"
	entry $w.p4c.name -width 40 -bg #FFFFFF -bd 1 -font splainf
	button $w.p4c.smiley -image [::skin::loadPixmap butsmile] -relief flat -padx 3 -highlightthickness 0
	button $w.p4c.newline -image [::skin::loadPixmap butnewline] -relief flat -padx 3 -command "$w.p4c.name insert end \"\n\""

	frame $w.fb
	button $w.fb.ok -text [trans ok] -command change_name_ok 
	button $w.fb.cancel -text [trans cancel] -command "destroy $w"
	bind $w <<Escape>> "destroy $w"


	pack $w.fn.label $w.fn.name $w.fn.newline $w.fn.smiley -side left -fill x -expand true
	pack $w.p4c.label $w.p4c.name $w.p4c.newline $w.p4c.smiley -side left -fill x -expand true
	pack $w.fb.ok $w.fb.cancel -side right -padx 5

	pack $w.fn $w.p4c $w.fb -side top -fill x -expand true -padx 5

	bind $w.fn.name <Return> "change_name_ok"
	bind $w.p4c.name <Return> "change_name_ok"
	bind $w.fn.smiley  <Button1-ButtonRelease> "::smiley::smileyMenu %X %Y $w.fn.name"
	bind $w.p4c.smiley  <Button1-ButtonRelease> "::smiley::smileyMenu %X %Y $w.p4c.name"
	bind $w.fn.name <Tab> "focus $w.p4c.name; break"
	bind $w.p4c.name <Tab> "focus $w.fn.name; break"

	$w.fn.name insert 0 [::abook::getPersonal nick]
	$w.p4c.name insert 0 [::config::getKey p4c_name]

	catch {
		raise $w
		focus -force $w.fn.name
	}
	moveinscreen $w 30
}

#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc change_name_ok {} {

	set new_name [.change_name.fn.name get]
	if {$new_name != ""} {
		if { [string length $new_name] > 130} {
			set answer [::amsn::messageBox [trans longnick] yesno question [trans confirm]]
			if { $answer == "no" } {
				return
			}
		}
		::MSN::changeName [::config::getKey login] $new_name
	}

	set friendly [.change_name.p4c.name get]

	if { [string length $friendly] > 130} {
		set answer [::amsn::messageBox [trans longp4c [string range $friendly 0 129]] yesno question [trans confirm]]
		if { $answer == "no" } {
			return
		}
	}
	::config::setKey p4c_name $friendly
	


	destroy .change_name
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc Fill_users_list { path path2} {
	global emailBList


	# clearing the list boxes from there content
	$path.allowlist.box delete 0 end
	$path.blocklist.box delete 0 end
	$path2.contactlist.box delete 0 end
	$path2.reverselist.box delete 0 end


	foreach user [lsort [::MSN::getList AL]] {
		$path.allowlist.box insert end $user
		if {[lsearch [::abook::getLists $user] RL] == -1} {
			set colour #FF00FF
		} else {
			set colour #FFFFFF
		}

		$path.allowlist.box itemconfigure end -background $colour
	}

	foreach user [lsort [::MSN::getList BL]] {
		$path.blocklist.box insert end $user
			if {[lsearch [::abook::getLists $user] RL] == -1} {
				set colour #FF00FF
			} else {
				set colour #FFFFFF
			}

		$path.blocklist.box itemconfigure end -background $colour
	}

	foreach user [lsort [::MSN::getList FL]] {
		$path2.contactlist.box insert end $user

		if {[lsearch [::MSN::getList RL] $user] == -1} {
			set colour #FF00FF
		} elseif { [info exists emailBList($user)]} {
			set colour #FF0000
		} else {
			set colour #FFFFFF
		}

		$path2.contactlist.box itemconfigure end -background $colour
	}


	foreach user [lsort [::MSN::getList RL]] {
		$path2.reverselist.box insert end $user
		if {[lsearch [::MSN::getList FL] $user] == -1} {
			set colour #00FF00
		} else {
			set colour #FFFFFF
		}
		$path2.reverselist.box itemconfigure end -background $colour
	}

}


proc create_users_list_popup { path list x y} {

	if { [$path.${list}list.box curselection] == "" } {
		$path.status configure -text "[trans choosecontact]"
	}  else {

		$path.status configure -text ""

		set user [$path.${list}list.box get active]

		set add "normal"
		set remove "normal"

		if { "$list" == "contact" } {
			set add "disabled"
		} elseif { "$list" == "reverse" } {
			set remove "disabled"
		} elseif { "$list" == "allow" } {
			# Other config to add ???
		} elseif { "$list" == "block" } {
			# Other config to add ???
		}

		if { [winfo exists $path.${list}popup] } {
			destroy $path.${list}popup
		}

		menu $path.${list}popup -tearoff 0 -type normal
		$path.${list}popup add command -label "$user" -command "clipboard clear;clipboard append $user"
		$path.${list}popup add separator
		$path.${list}popup add command -label "[trans addtocontacts]" -command "AddToContactList \"$user\" $path" -state $add
		$path.${list}popup add command -label "[trans removefromlist]" -command "Remove_from_list $list $user" -state $remove
		$path.${list}popup add command -label "[trans properties]" -command "::abookGui::showUserProperties $user"

		tk_popup $path.${list}popup $x $y
	}
}

proc AddToContactList { user path } {

	if { [NotInContactList "$user"] } {
		::MSN::WriteSB ns "ADD" "FL $user $user 0"
	} else {
		$path.status configure -text "[trans useralreadyonlist]"
	}

}

proc Remove_from_list { list user } {

	if { "$list" == "contact" } {
		::MSN::WriteSB ns "REM" "FL $user"
	} elseif { "$list" == "allow" } {
		::MSN::WriteSB ns "REM" "AL $user"
	} elseif { "$list" == "block" } {
		::MSN::WriteSB ns "REM" "BL $user"
	}

}

proc Add_To_List { path list } {
	set username [$path.adding.enter get]

	if { [string match "*@*" $username] == 0 } {
		set username [split $username "@"]
		set username "[lindex $username 0]@hotmail.com"
	}

	if { $list == "FL" } {
		AddToContactList "$username" "$path"
	} else {
		::MSN::WriteSB ns "ADD" "$list $username $username"
	}
}

proc Reverse_to_Contact { path } {

	if { [VerifySelect $path "reverse"] } {

		$path.status configure -text ""

		set user [$path.reverselist.box get active]

		AddToContactList "$user" "$path"

	}

}

proc Remove_Contact { path } {

	if { [$path.contactlist.box curselection] == "" } {
		$path.status configure -text "[trans choosecontact]"
	}  else {

		$path.status configure -text ""

		set user [$path.contactlist.box get active]

		Remove_from_list "contact" $user
	}
}

proc Allow_to_Block { path } {

	if { [VerifySelect $path "allow"] } {

		$path.status configure -text ""

		set user [$path.allowlist.box get active]

		::MSN::blockUser "$user" [urlencode $user]

	}

}

proc Block_to_Allow  { path } {

	if { [VerifySelect $path "block"] } {

		$path.status configure -text ""

		set user [$path.blocklist.box get active]

		::MSN::unblockUser "$user" [urlencode $user]

	}

}


proc AllowAllUsers { state } {
	global list_BLP

	set list_BLP $state

	updateAllowAllUsers
}

proc updateAllowAllUsers { } {
	global list_BLP

	if { $list_BLP == 1 } {
		::MSN::WriteSB ns "BLP" "AL"
	} elseif { $list_BLP == 0} {
		::MSN::WriteSB ns "BLP" "BL"
	} else {
		return
	}
}

proc VerifySelect { path list } {

	if { [$path.${list}list.box curselection] == "" } {
		$path.status configure -text "[trans choosecontact]"
		return 0
	}  else {
		return 1
	}

}


proc NotInContactList { user } {

	if {[lsearch [::MSN::getList FL] $user] == -1} {
		return 1
	} else {
		return 0
	}

}

#saves the contactlist to a file
proc saveContacts { } {
	set types {
		{{Comma Seperated Values}       {.csv}        }
	}
	set filename [tk_getSaveFile -filetypes $types]
	if {$filename != ""} {
		::abook::saveToDisk $filename "csv"
	}
}

###TODO: Replace all this msg_box calls with ::amsn::infoMsg
proc msg_box {msg} {
	::amsn::infoMsg "$msg"
}

############################################################
### Extra procedures that go nowhere else
############################################################


#///////////////////////////////////////////////////////////////////////
# launch_browser(url)
# Launches the configured file manager
proc launch_browser { url {local 0}} {

	global tcl_platform

	if { ![regexp ^\[\[:alnum:\]\]+:// $url] && $local != 1 } {
		set url "http://$url"
	}

	if { $tcl_platform(platform)=="windows" && [string tolower [string range $url 0 6]] == "file://" } {
		set url [string range $url 7 end]
	}

	status_log "url is $url\n"

	#status_log "Launching browser for url: $url\n"
	if { $tcl_platform(platform) == "windows" } {

		#regsub -all -nocase {htm} $url {ht%6D} url
		#regsub -all -nocase {&} $url {^&} url

		#catch { exec rundll32 url.dll,FileProtocolHandler $url & } res
		#run WinLoadFile, if its not loaded yet then load it
		if { [catch { WinLoadFile $url } ] } {
			load [file join utils windows winutils winutils.dll]
			WinLoadFile $url
		}
	} else {

		if { [string first "\$url" [::config::getKey browser]] == -1 } {
			::config::setKey browser "[::config::getKey browser] \$url"
		}

		#if { [catch {eval exec [::config::getKey browser] [list $url] &} res ] } {}
		#status_log "Launching [::config::getKey browser]\n"		
		if { [catch {eval exec [::config::getKey browser] &} res ] } {
			::amsn::errorMsg "[trans cantexec [::config::getKey browser]]"
		}

	}

}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
# launch_filemanager(directory)
# Launches the configured file manager
proc launch_filemanager {location} {
	global tcl_platform

		if { [string length [::config::getKey filemanager]] < 1 } {
			msg_box "[trans checkfilman $location]"
		} else {
			#replace all / with \ for windows
			if { $tcl_platform(platform) == "windows" } {
				regsub -all {/} $location {\\} location
			}

			if { [string first "\$location" [::config::getKey filemanager]] == -1 } {
				::config::setKey filemanager "[::config::getKey filemanager] \$location"
			}


			if {[catch {eval exec [::config::getKey filemanager] &} res]} {
				::amsn::errorMsg "[trans cantexec [::config::getKey filemanager]]"
			}
		}

}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
# launch_mailer(directory)
# Launches the configured mailer program
proc launch_mailer {recipient} {
	global password

	if {[string length [::config::getKey mailcommand]]==0} {
		::hotmail::composeMail $recipient [::config::getKey login] $password
			return 0
	}

	if { [string first "\$recipient" [::config::getKey mailcommand]] == -1 } {
		::config::setKey mailcommand "[::config::getKey mailcommand] \$recipient"
	}


	if { [catch {eval exec [::config::getKey mailcommand] &} res]} {
		::amsn::errorMsg "[trans cantexec [::config::getKey mailcommand]]"
	}
	return 0
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
# toggle_status()
# Enabled/disables status window (for debugging purposes)
proc toggle_status {} {

	if {"[wm state .status]" == "normal"} {
		wm state .status withdrawn
		set status_show 0
	} else {
		wm state .status normal
		set status_show 1
		raise .status
		focus .status.enter
	}
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
# timestamp()
# Returns a timestamp like [HH:MM:SS]
proc timestamp {} {
	set stamp [clock format [clock seconds] -format %H:%M:%S]
	return "[::config::getKey leftdelimiter]$stamp[::config::getKey rightdelimiter]"
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////////////
# status_log (text,[color])
# Logs the given text with a timestamp using the given color
# to the status window
proc status_log {txt {colour ""}} {
	global followtext_status queued_status

	if { [catch {
		.status.info insert end "[timestamp] $txt" $colour
		.status.info delete 0.0 end-1000lines
		#puts "[timestamp] $txt"
		if { $followtext_status == 1 } {
			catch {.status.info yview end}
		}
	}]} {
		lappend queued_status [list $txt $colour]
	}
}
#///////////////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
#TODO: Improve menu enabling and disabling using short names, not long
#      and translated ones
# configureMenuEntry .main_menu.file "[trans addcontact]" disabled|normal
proc configureMenuEntry {m e s} {
	$m entryconfigure $e -state $s
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
# close_cleanup()
# Makes some cleanup and config save before closing
proc close_cleanup {} {
	global HOME lockSock
	catch { ::MSN::logout}
	::config::setKey wingeometry [wm geometry .]

	save_config
	::config::saveGlobal

	LoadLoginList 1
	# Unlock current profile
	LoginList changelock 0 [::config::getKey login] 0
	if { [info exists lockSock] } {
		if { $lockSock != 0 } {
			catch {close $lockSock} res
		}
	}
	SaveLoginList
	SaveStateList


	close_dock    ;# Close down the dock socket
	catch {file delete [file join $HOME hotlog.htm]} res
}
#///////////////////////////////////////////////////////////////////////


if { $initialize_amsn == 1 } {
	global idletime oldmousepos autostatuschange

	set idletime 0
	set oldmousepos [list]
	set autostatuschange 0
}
#///////////////////////////////////////////////////////////////////////
# idleCheck()
# Check idle every five seconds and reset idle if the mouse has moved
proc idleCheck {} {
	global idletime oldmousepos trigger autostatuschange

	set mousepos [winfo pointerxy .]
	if { $mousepos != $oldmousepos } {
		set oldmousepos $mousepos
		set idletime 0
	}


	# Check for empty fields and use 5min by default
	if {[::config::getKey awaytime] == ""} {
		::config::setKey awaytime 10
	}

	if {[::config::getKey idletime] == ""} {

		::config::setKey idletime 5
	}

	if { [string is digit [::config::getKey awaytime]] && [string is digit [::config::getKey idletime]] } {
	#Avoid running this if the settings are not digits, which can happen while changing preferences
		set second [expr {[::config::getKey awaytime] * 60}]
		set first [expr [::config::getKey idletime] * 60]
	
		if { $idletime >= $second && [::config::getKey autoaway] == 1 && \
			(([::MSN::myStatusIs] == "IDL" && $autostatuschange == 1) || \
			([::MSN::myStatusIs] == "NLN"))} {
			#We change to Away if time has passed, and if IDL was set automatically
			::MSN::changeStatus AWY
			set autostatuschange 1
		} elseif {$idletime >= $first && [::MSN::myStatusIs] == "NLN" && [::config::getKey autoidle] == 1} {
			#We change to idle if time has passed and we're online
			::MSN::changeStatus IDL
			set autostatuschange 1
		} elseif { $idletime == 0 && $autostatuschange == 1} {
			#We change to only if mouse movement, and status change was automatic
			::MSN::changeStatus NLN
			#Status change always resets automatic change to 0
		}
	}

	set idletime [expr {$idletime + 5}]
	after 5000 idleCheck
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc choose_theme { } {
	setColor . . background {-background -highlightbackground}
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc setColor {w button name options} {

	catch {grab $w}
	set initialColor [$button cget -$name]
	set color [tk_chooseColor -title "[trans choosebgcolor]" -parent $w \
		-initialcolor $initialColor]
	if { $color != "" } {
		::config::setKey backgroundcolor $color
		::themes::ApplyDeep $w $options $color
	}
	catch {grab release $w}
}
#///////////////////////////////////////////////////////////////////////






#///////////////////////////////////////////////////////////////////////
proc show_umenu {user_login grId x y} {

	set blocked [::MSN::userIsBlocked $user_login]
	.user_menu delete 0 end
	.user_menu add command -label "${user_login}" \
		-command "clipboard clear;clipboard append \"${user_login}\""

	.user_menu add separator
	.user_menu add command -label "[trans sendmsg]" \
		-command "::amsn::chatUser ${user_login}"
	.user_menu add command -label "[trans sendmail]" \
		-command "launch_mailer $user_login"
	.user_menu add command -label "[trans viewprofile]" \
		-command "::hotmail::viewProfile [list ${user_login}]"
	.user_menu add command -label "[trans history]" \
		-command "::log::OpenLogWin ${user_login}"
	.user_menu add separator
	if {$blocked == 0} {
		.user_menu add command -label "[trans block]" -command  "::amsn::blockUser ${user_login}"
	} else {
		.user_menu add command -label "[trans unblock]" \
			-command  "::amsn::unblockUser ${user_login}"
	}

	::groups::updateMenu menu .user_menu.move_group_menu ::groups::menuCmdMove [list $grId $user_login]
	::groups::updateMenu menu .user_menu.copy_group_menu ::groups::menuCmdCopy $user_login


	if {[::config::getKey orderbygroup]} {
		.user_menu add cascade -label "[trans movetogroup]" -menu .user_menu.move_group_menu
		.user_menu add cascade -label "[trans copytogroup]" -menu .user_menu.copy_group_menu
		.user_menu add command -label "[trans delete]" -command "::amsn::deleteUser ${user_login} $grId"
	} else {
		.user_menu add cascade -label "[trans movetogroup]"  -state disabled
		.user_menu add cascade -label "[trans copytogroup]"  -state disabled
		.user_menu add command -label "[trans delete]" -command "::amsn::deleteUser ${user_login}"
	}
	
	.user_menu add separator
	.user_menu add command -label "[trans properties]" \
	-command "::abookGui::showUserProperties $user_login"

	# Display Alarm Config settings
	#NOT NEEDED ANYMORE! Change it inside preferences!!
	#.user_menu add separator
	.user_menu add command -label "[trans cfgalarm]" -command "::abookGui::showUserProperties $user_login; .user_[::md5::md5 $user_login]_prop.nb raise alarms"
	# PostEvent 'right_menu'
	set evPar(menu_name) .user_menu
	set evPar(user_login) ${user_login}
	::plugins::PostEvent right_menu evPar
	
	tk_popup .user_menu $x $y
}

#///////////////////////////////////////////////////////////////////////
#Download window
proc amsn_update { new_version } {

	set w .downloadwindow
	if {[winfo exists $w]} {
		raise $w
		return
	}
	#Create the window .downloadwindow
	toplevel $w
	wm title $w "Download"
	
	#Create 2 frames
	frame $w.top
	frame $w.bottom
	
	#Add bitmap and text at the top
	label $w.top.bitmap -image [::skin::loadPixmap download]
	label $w.top.text -text "Downloading new amsn version. Please Wait..." -font bigfont
	#Get the download URL
	set amsn_url [get_download_link $new_version]
	
	#Add button at the bottom
	button $w.bottom.cancel -text "Cancel"
	
	#Pack all the stuff for the top
	pack $w.top.bitmap -pady 5
	pack $w.top.text -pady 10
	
	#Pack the progress bar and cancel button at the bottom
	pack [::dkfprogress::Progress $w.bottom.prbar] -fill x -expand 0 -padx 5 -pady 10
	pack $w.bottom.cancel -pady 5
	
	#Pack the frames
	pack $w.top -side top
	pack $w.bottom -side bottom -fill x
	
	#Start download
	set amsn_tarball [::http::geturl $amsn_url -progress "amsn_download_progress $amsn_url" -command "amsn_choose_dir $amsn_url"]
	
	moveinscreen $w 30
}
#Create the download link (change on the differents platforms)
proc get_download_link {new_version} {
	set new_version [string replace $new_version 1 1 "_"]
	#set new_version [string replace $new_version 1 1 "-"]
	append amsn_url "http://aleron.dl.sourceforge.net/sourceforge/amsn/amsn-" $new_version
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		append amsn_url ".dmg"
	} elseif { $::tcl_platform(platform)=="windows" } {
		append amsn_url ".exe"
	} else { 
		append amsn_url ".tar.gz"
	}
	
	return $amsn_url
}

#///////////////////////////////////////////////////////////////////////
proc amsn_download_progress { url token {total 0} {current 0} } {
	set w .downloadwindow
	#Config cancel button to cancel the download
	$w.bottom.cancel configure -command "::http::reset $token"
	bind $w <<Escape>> "::http::reset $token"
	bind $w <<Destroy>> "::http::reset $token"
	wm protocol $w WM_DELETE_WINDOW "::http::reset $token"
	#Check if url is valid
	if { $total == 0 } {
		$w.top.text configure -text "Couldn't get $url"
		$w.bottom.cancel configure -text "Close" -command "destroy $w"
		bind $w <<Escape>> "destroy $w"
		bind $w <<Destroy>> "destroy $w"
		wm protocol $w WM_DELETE_WINDOW "destroy $w"
		return
	}
	#Update progress bar and text bar, use size in KB and MB
	::dkfprogress::SetProgress $w.bottom.prbar [expr {$current*100/$total}]
	$w.top.text configure -text "$url\n[trans receivedbytes [::amsn::sizeconvert $current] [::amsn::sizeconvert $total]]"
}

#///////////////////////////////////////////////////////////////////////
proc amsn_choose_dir { url token } {
	set w .downloadwindow
	#If user cancel the download
	if { [::http::status $token] == "reset" } {
		::http::cleanup $token
		$w.top.text configure -text "Download canceled."
		$w.bottom.cancel configure -text "Close" -command "destroy $w"
		bind $w <<Escape>> "destroy $w"
		bind $w <<Destroy>> "destroy $w"
		wm protocol $w WM_DELETE_WINDOW "destroy $w"
		return
	}
	#If it's impossible to get the URL
	if { [::http::status $token] != "ok" || [::http::ncode $token] != 200 } {
		$w.top.text configure -text "Couldn't get $url"
		$w.bottom.cancel configure -text "Close" -command "destroy $w"
		bind $w <<Escape>> "destroy $w"
		bind $w <<Destroy>> "destroy $w"
		wm protocol $w WM_DELETE_WINDOW "destroy $w"
		return
	}
	#If the download is over, remove cancel button and progress bar
	destroy $w.bottom.prbar
	destroy $w.bottom.cancel
	
	#Get default location for each platform
	set location [get_default_location]
	set namelocation [lindex $location 0]
	set defaultlocation [lindex $location 1]
	
	$w.top.text configure -text "Save file on $namelocation?"
	#Create 2 buttons, save and save as
	button $w.bottom.save -command "amsn_save $url $token $defaultlocation" -text "Save" -default active
	button $w.bottom.saveas -command "amsn_save_as $url $token $defaultlocation" -text "Save in another directory" -default normal
	pack $w.bottom.save
	pack $w.bottom.saveas -pady 5
	#If user try to close the window, just save in default directory
	bind $w <<Escape>> "amsn_save $url $token $defaultlocation"
	bind $w <<Destroy>> "amsn_save $url $token $defaultlocation"
	wm protocol $w WM_DELETE_WINDOW "amsn_save $url $token $defaultlocation"
}

#When user click on save in another directory, he gets a window to choose the directory
proc amsn_save_as {url token defaultlocation} {
	set location [tk_chooseDirectory -initialdir $defaultlocation]
	if { $location !="" } {
		amsn_save $url $token $location
	} else {
		return
	}
}

#Define default directory on the three platforms 
#(It's ok For Mac OS X, change it on your platform if you feel it's not good)
proc get_default_location {} {
	global files_dir env
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		set namelocation "Desktop"
		set defaultlocation "[file join $env(HOME) Desktop]"
	} elseif { $::tcl_platform(platform)=="windows" } {
		set namelocation "Desktop"
		set defaultlocation "$files_dir"
	} else { 
		set namelocation "Home folder"
		set defaultlocation "[file join $env(HOME)]"
	}
	lappend location $namelocation
	lappend location $defaultlocation
	return $location
}

#///////////////////////////////////////////////////////////////////////
proc amsn_save { url token location} {
	
	set savedir $location
	set w .downloadwindow
	
	#Save the file
	set lastslash [expr {[string last "/" $url]+1}]
	set fname [string range $url $lastslash end]
	
	if { [catch {
		set file_id [open [file join $savedir $fname] w]
		fconfigure $file_id -translation {binary binary} -encoding binary
		puts -nonewline $file_id [::http::data $token]
		close $file_id
	}]} {
		#Can't save the file at this place
		#Get informations of the default location for this system
		set location [get_default_location]
		set namelocation [lindex $location 0]
		set defaultlocation [lindex $location 1]
		#Show the button to choose a new file location or use default location
		$w.top.text configure -text "File can't be saved at this place."
		$w.bottom.save configure -command "amsn_save $url $token $defaultlocation" -text "Save in default location" -default active
		$w.bottom.saveas configure -command "amsn_save_as $url $token $defaultlocation" -text "Choose new file location" -default normal
		
		bind $w <<Escape>> "amsn_save $url $token $defaultlocation"
		bind $w <<Destroy>> "amsn_save $url $token $defaultlocation"
		wm protocol $w WM_DELETE_WINDOW "amsn_save $url $token $defaultlocation"
	} else {
		#The saving is a sucess, show a button to open directory of the saved file and close button
		$w.top.text configure -text "Done\n Saved $fname in $savedir."
		$w.bottom.save configure -command "launch_filemanager \"$savedir\";destroy $w" -text "Open directory" -default normal
		$w.bottom.saveas configure -command "destroy $w" -text "Close" -default active
		#if { $::tcl_platform(platform)=="unix" } {
		#	button $w.bottom.install -text "Install" -command "amsn_install_linux $savedir $fname"
		#	pack $w.bottom.install
		#}
		#if { $::tcl_platform(platform)=="windows" } {
		#	button $w.bottom.install -text "Install" -command "amsn_install_windows $savedir $fname"
		#	pack $w.bottom.install
		#}
		bind $w <<Escape>> "destroy $w"
		bind $w <<Destroy>> "destroy $w"
		wm protocol $w WM_DELETE_WINDOW "destroy $w"
	}

}

#///////////////////////////////////////////////////////////////////////
proc amsn_install_windows { savedir fname } {
}

#///////////////////////////////////////////////////////////////////////
#proc amsn_install_linux { savedir fname } {
#	set old_dir [pwd]
#	cd $savedir
#	if { [catch { set shell [exec tar xzfp "$savedir/$fname"] }] } {
#		.update.q configure -text "Problems occurred during the installation (tar xzfp $savedir/$fname). Please report it."
#	} else {
#		catch { [exec mv "$savedir/amsn-*" "$savedir/msn"] }
#		#copiar els plugins
#		set success [catch { [exec cp "$::program_dir/plugins/*" "$savedir/msn/plugins"] }]
#		#copiar els skins
#		set success [catch { [exec cp "$::program_dir/skins/*" "$savedir/msn/skins"] }]
#		#moure la versi�nova a la carpeta on estava
#		if { !$success } {
#			if { [catch { [exec mv "$savedir/msn" "$::program_dir"] }] } {
#				#missatge d'error
#				.update.q configure -text "Problems occurred during the installation (tar xzfp $savedir/$fname). Please report it."
#			}
#		} else {
#			#missatge d'error
#			.update.q configure -text "Problems occurred during the installation (tar xzfp $savedir/$fname). Please report it."
#		}
#		.update.q configure -text "Installation complete: $shell"
#	}
#	cd $old_dir 
#}

#///////////////////////////////////////////////////////////////////////
package require http

proc check_web_version { token } {
	global version weburl

	set newer 0

	set tmp_data [ ::http::data $token ]

	if { [::http::status $token] == "ok" && [::http::ncode $token] == 200 } {
		set tmp_data [string map {"\n" "" "\r" ""} $tmp_data]
		set lastver [split $tmp_data "."]
		set yourver [split $version "."]

		if { [lindex $lastver 0] > [lindex $yourver 0] } {
			set newer 1
		} else {
			# Major version is at least the same
			if { [lindex $lastver 1] > [lindex $yourver 1] } {
				set newer 1
			}
		}

		catch {status_log "check_web_ver: Current= $yourver New=$lastver ($tmp_data)\n"}
		#Time in second when the user clicked to not have an alert before 3 days
		set weekdate [::config::getKey weekdate]
		#Actual time in seconds
		set actualtime "[clock seconds]"
		#Number of seconds for 3 days
		set three_days "[expr 60*60*24*3]"
		#If you tant to test just with 60 seconds, add # on the previous line and remove the # on the next one
		#set three_days "60"
		#Compare the difference betwen actualtime and the time when he clicked
		if {$weekdate != ""} {
			set diff_time "[expr {$actualtime-$weekdate}]"
		} else {
			set diff_time "[expr {$three_days + 1 } ]"
		}
		status_log "Three days (in seconds) :$three_days\n" blue
		status_log "Difference time (in seconds): $diff_time\n" blue
		#If new version and more than 3 days since the last alert (if user choosed that feature)
		#Open the update window
		if { $newer == 1 && $diff_time > $three_days} {
			update_window $tmp_data
		} else {
			status_log "Not yet 3 days\n" red 
		}


	} else {
		catch {status_log "check_web_ver: status=[::http::status $token] ncode=[::http::ncode $token]\n" blue}

	}
	::http::cleanup $token

	::lang::UpdateLang

	return $newer
}
#///////////////////////////////////////////////////////////////////////
proc update_window {tmp_data} {	
	set w .update
	#If the window was created before
	if {[winfo exists $w]} {
		raise $w
		return
	}
	#Create the update window
	toplevel $w
	wm title $w "[trans newveravailable $tmp_data]"
	set changeloglink "http://amsn.sourceforge.net/wiki/tiki-index.php?page=ChangeLog"
	set homepagelink "http://amsn.sourceforge.net/"
	#Create the frames
	frame $w.top
	frame $w.top.buttons
	frame $w.bottom
	frame $w.bottom.buttons
	
	#Top frame
	label $w.top.bitmap -image [::skin::loadPixmap warning]
	label $w.top.i -text "[trans newveravailable $tmp_data]" -font bigfont
	button $w.top.buttons.changelog -text "Change log" -command "launch_browser $changeloglink"
	button $w.top.buttons.homepage -text "aMSN homepage" -command "launch_browser $homepagelink"
	
	#Bottom frame
	label $w.bottom.bitmap -image [::skin::loadPixmap greyline]
	label $w.bottom.q -text "Would you like to update aMSN immediatly?" -font bigfont
	button $w.bottom.buttons.update -text "Update" -command "amsn_update $tmp_data;destroy $w" -default active
	button $w.bottom.buttons.cancel -text "Cancel" -command "dont_ask_before;destroy $w"
	label $w.bottom.lastbar -image [::skin::loadPixmap greyline]
	#Checkbox to verify if the user want to have an alert again or just in one week
	checkbutton $w.bottom.ignoreoneweek -text "Don't ask update again for one week" -variable "dont_ask_for_one_week" -font sboldf
	
	#Pack all the stuff for the top
	pack $w.top.bitmap -side top -padx 3m -pady 3m
	pack $w.top.i
	pack $w.top.buttons.changelog -side left
	pack $w.top.buttons.homepage -side right
	pack $w.top.buttons -fill x
	pack $w.top -side top -pady 5
	
	#Pack all the stuff for the bottom
	pack $w.bottom.bitmap
	pack $w.bottom.q
	pack $w.bottom.buttons.update -side left -padx 5
	pack $w.bottom.buttons.cancel -side right -padx 5
	pack $w.bottom.buttons
	pack $w.bottom.lastbar -pady 5
	pack $w.bottom.ignoreoneweek
	pack $w.bottom -side bottom -pady 15
	
	bind $w <<Escape>> "dont_ask_before;destroy .update"
	bind $w <<Destroy>> "dont_ask_before;destroy .update"
	wm protocol $w WM_DELETE_WINDOW "dont_ask_before;destroy .update"
	moveinscreen $w 30
}

#When the user cancel the update, we check if he clicked on "Don't ask update again for one week"
#If yes, save the actual time in seconds in the weekdate
proc dont_ask_before {} {

	if {$::dont_ask_for_one_week} {
		::config::setKey weekdate "[clock seconds]"
	}
}
#///////////////////////////////////////////////////////////////////////
proc check_version {} {
	global weburl tcl_platform


	if { [winfo exists .checking] } {
		raise .checking
		return
	}
	toplevel .checking

	wm title .checking "[trans title]"
	ShowTransient .checking
	canvas .checking.c -width 250 -height 50

	label .checking.d -image [::skin::loadPixmap download]
	.checking.c create text 125 25 -font splainf -anchor n \
		-text "[trans checkingver]..." -justify center -width 250
	pack .checking.d -expand true -side left
	pack .checking.c -expand true
	tkwait visibility .checking
	catch {grab .checking}

	update idletasks

	status_log "Getting ${weburl}/amsn_latest\n" blue
	if { [catch {
		set token [::http::geturl ${weburl}/amsn_latest -timeout 10000]
		if {[check_web_version $token]==0} {
			msg_box "[trans nonewver]"
		}
		} res ]} {
		msg_box "[trans connecterror]: $res"
	}

	destroy .checking


}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc check_version_silent {} {
	global weburl

	catch {
		::http::geturl ${weburl}/amsn_latest -timeout 10000 -command check_web_version
	}

}


#///////////////////////////////////////////////////////////////////////
proc run_command_otherwindow { command } {
	set tmp [.otherwindow.email get]
	if { $tmp != "" } {
		eval $command [list $tmp]
		destroy .otherwindow
	}
}
#///////////////////////////////////////////////////////////////////////

proc BossMode { } {
	global bossMode BossMode

	if { [info exists bossMode] == 0 } {
		set bossMode 0
	}

	#    puts "BossMode : $bossMode"


	if { $bossMode == 0 } {
		set children [winfo children .]

		if { [catch { toplevel .bossmode } ] } {
			set bossMode 0
			set children ""
		} else {

			wm title .bossmode "[trans pass]"

			label .bossmode.passl -text "[trans pass]"
			entry .bossmode.pass -show "*"
			pack .bossmode.passl .bossmode.pass -side left

			#updatebossmodetime
			bind .bossmode.pass <Return> "BossMode"

			if { [::config::getKey dock] == 4 } {
				wm state .bossmode withdraw
				wm protocol .bossmode WM_DELETE_WINDOW "wm state .bossmode withdraw"
				catch {wm iconbitmap .bossmode [::skin::GetSkinFile winicons bossmode.ico]}
				statusicon_proc "BOSS"
			} else {
				wm protocol .bossmode WM_DELETE_WINDOW "BossMode"
			}
		}

		foreach child $children {
			if { "$child" == ".bossmode" } {continue}

			if { [catch { wm state "$child" } res ] } {
				status_log "$res\n"
				continue
			}
			if { [wm overrideredirect "$child"] == 0 } {
				set BossMode($child) [wm state "$child"]
				wm state "$child" normal
				wm state "$child" withdraw
			}
		}

		if { "$children" != "" } {
			set BossMode(.) [wm state .]
			wm state . normal
			wm state . withdraw

			set bossMode 1

		}


	} elseif { $bossMode == 1 && [winfo exists .bossmode]} {
		if { [.bossmode.pass get] != [set ::password] } {
			return
		}
	
		set children [winfo children .]

		foreach child $children {
			if { [catch { wm state "$child" } res ] } {
				status_log "$res\n"
				continue
			}

			if { "$child" == ".bossmode" } {continue}

			if { [wm overrideredirect "$child"] == 0 } {
				wm state "$child" normal

				if { [info exists BossMode($child)] } {
					wm state "$child" "$BossMode($child)"
				} 		
			}
		}

		wm state . normal

		if { [info exists BossMode(.)] } {
			wm state . $BossMode(.)
		}

		set bossMode 0
		destroy .bossmode
		
		if { [::config::getKey dock] == 4 } {
			statusicon_proc [::MSN::myStatusIs]
		}
	}



}

proc updatebossmodetime { } {

	.bossmode.time configure -text "[string map { \" "" } [clock format [clock seconds] -format \"%T\"]]"
	#" Just to fix some editors syntax hilighting
	after 1000 updatebossmodetime
}

proc window_history { command w } {
	global win_history

	set HISTMAX 100

	set new [info exists win_history(${w}_count)]

	catch {
		if { [winfo class $w] == "Text" } {
			set zero 0.0
		} else {
			set zero 0
		}
	}

	switch $command {
		add {
			if { [winfo class $w] == "Text" } {
				set msg "[$w get 0.0 end-1c]"
			} else  {
				set msg "[$w get]"
			}

			if { $msg != "" } {
				if { $new } {
					set idx $win_history(${w}_count)
				} else {
					set idx 0
				}

				if { $idx == $HISTMAX } {
					set win_history(${w}) [lrange $win_history(${w}) 1 end]
					lappend win_history(${w}) "$msg"
					set win_history(${w}_index) $HISTMAX
					return
				}

				set win_history(${w}_count) [expr {$idx + 1}]
				set win_history(${w}_index) [expr {$idx + 1}]
				#		set win_history(${w}_${idx}) "$msg"
				lappend win_history(${w}) "$msg"

			}	
		}
		clear {

			if {! $new } { return -1}

			# 	    foreach histories [array names win_history] {
			# 		if { [string match "${w}*" $histories] } {
			# 		    unset win_history($histories)
			# 		}
			# 	    }
			catch {
				unset win_history(${w}_count)
				unset win_history(${w}_index)
				unset win_history(${w})
				unset win_history(${w}_temp)
			}
		}
		previous {
			if {! $new } { return -1}
			set idx $win_history(${w}_index)
			if { $idx ==  0 } { return -1}


			if { $idx ==  $win_history(${w}_count) } {
				if { [winfo class $w] == "Text" } {
					set msg "[$w get 0.0 end-1c]"
				} else  {
					set msg "[$w get]"
				}
				set win_history(${w}_temp) "$msg"
			}

			incr idx -1
			#set idx [expr {$idx - 1}]
			set win_history(${w}_index) $idx

			$w delete $zero end
			#	    $w insert $zero "$win_history(${w}_${idx})"
			$w insert $zero "[lindex $win_history(${w}) $idx]"
		}
		next {
			if {! $new } { return -1}
			set idx $win_history(${w}_index)
			if { $idx ==  $win_history(${w}_count) } { return -1}

			incr idx
			#set idx [expr $idx +1]
			set win_history(${w}_index) $idx
			$w delete $zero end
			#	    if {! [info exists win_history(${w}_${idx})] } { }
			if { $idx ==  $win_history(${w}_count) } { 
					$w insert $zero "$win_history(${w}_temp)"
			} else {
				#		$w insert $zero "$win_history(${w}_${idx})"
				$w insert $zero "[lindex $win_history(${w}) $idx]"
			}

		}
	}
}



########################################################################
#### ALL ABOUT CONVERTING AND CHOOSING DISPLAY PICTURES 
########################################################################

# Converts the given $filename to the given size, and leaves 
# xx.png and xxx.gif in the given destination directory
proc convert_image { filename destdir size } {

	global tcl_platform
	
	set filetail [file tail $filename]
	set filetail_noext [filenoext $filetail]

	set tempfile [file join $destdir $filetail]
	set destfile [file join $destdir $filetail_noext]
	
	if { ![file exists $filename] } {
		status_log "Tring to convert file $filename that does not exist\n" error
		return ""
	}

	status_log "converting $filename to $tempfile with size $size\n"

	#IMPORTANT: If convertpath is blank, set it to "convert"
	if { [::config::getKey convertpath] == "" } {
		::config::setKey convertpath "convert"
	}

	#First conversion, no size, only .gif
	if { [catch { exec [::config::getKey convertpath] "${filename}" "${tempfile}.gif" } res] } {
		status_log "CONVERT ERROR IN CONVERSION 1: $res" white
		return ""
	}

	#Now analyze the resulting .gif file to check aspect ratio
	set img [image create photo -file "${tempfile}.gif"]
	set origw [image width $img]
	set origh [image height $img]
	status_log "Image size is $origw $origh\n" blue
	image delete $img

	set sizexy [split $size "x" ]
	if { [lindex $sizexy 1] == "" } {
		set sizexy [list [lindex $sizexy 0] [lindex $sizexy 0]]
		set ratio 1.0
	} else {
		set ratio [expr { 1.0*[lindex $sizexy 1] / [lindex $sizexy 0] } ]
	}
	set origratio [expr { 1.0*$origw / $origh } ]
	status_log "Original ratio is $origratio, desired ratio is $ratio\n" blue

	#Depending on ratio, resize to keep smaller dimension to XX pixels
	if { $origratio > $ratio} {
		set resizeh [lindex $sizexy 1]
		set resizew [expr {round($resizeh*$origratio)}]
	} else {
		set resizew [lindex $sizexy 0]
		set resizeh [expr {round($resizew/$origratio)}]
	}



	if { $origw != [lindex $sizexy 0] || $origh != [lindex $sizexy 1] } {
		status_log "Will resize to $resizew x $resizeh \n" blue		
		catch { file delete ${tempfile}.gif}
		if { [catch { exec [::config::getKey convertpath] "${filename}" -resize "${resizew}x${resizeh}" "${tempfile}.gif"} res] } {
			status_log "CONVERT ERROR IN CONVERSION 2: $res" white
			return ""
		}
	}


	if { [file exists ${tempfile}.png.0] } {
		status_log "convert_image: HEY!! CHECK THIS!!" white
		set idx 1
		while { 1 } {
			if { [file exists ${tempfile}.png.$idx] } {
				catch {file delete ${tempfile}.png.$idx}
				incr idx
			} else { break }
		}
		file rename ${tempfile}.png.0 ${tempfile}.png
	}

	
	#Now let's crop image, from the center
	set img [image create photo -file "${tempfile}.gif"]
	set centerx [expr { [image width $img] /2 } ]
	set centery [expr { [image height $img] /2 } ]
	set halfw [expr [lindex $sizexy 0] / 2]
	set halfh [expr [lindex $sizexy 1] / 2]
	set x1 [expr {$centerx-$halfw}]
	set y1 [expr {$centery-$halfh}]
	if { $x1 < 0 } {
		set x1 0
	}
	if { $y1 < 0 } {
		set y1 0
	}

	set x2 [expr {$x1+[lindex $sizexy 0]}]
	set y2 [expr {$y1+[lindex $sizexy 1]}]

	set neww [image width $img]
	set newh [image height $img]
	status_log "Resized image size is $neww $newh\n" blue

	status_log "Center of image is $centerx,$centery, will crop from $x1,$y1 to $x2,$y2 \n" blue
	if {[catch {$img write "${destfile}.gif" -from $x1 $y1 $x2 $y2 -format gif}]} {
		#To fix an strange bug when the image is badly resized
		$img write "${destfile}.gif" -format gif
	}
	image delete $img

	catch {file delete ${tempfile}.gif}
	
	
	if { [catch { exec [::config::getKey convertpath] "${destfile}.gif" "${destfile}.png"}] } {
		status_log "CONVERT ERROR IN CONVERSION 3: $res" white
		catch {[file delete ${destfile}.gif]}
		return ""
	}

	if { [file exists ${destfile}.png.0] } {
		set idx 1
		while { 1 } {
			if { [file exists "${destfile}.png.$idx"] } {
				catch {file delete "${destfile}.png.$idx"}
				incr idx
			} else { break }
		}
		catch {file delete ${destfile}.png}
		file rename "${destfile}.png.0" "${destfile}.png"
	}


	return ${destfile}.gif

}


proc run_convert { sourcefile destfile } {

	global tcl_platform
	
	if { ![file exists $sourcefile] } {
		status_log "Tring to convert file $sourcefile that does not exist\n" error
		return ""
	}

	status_log "run_convert: converting $sourcefile to $destfile\n"

	#IMPORTANT: If convertpath is blank, set it to "convert"
	if { [::config::getKey convertpath] == "" } {
		::config::setKey convertpath "convert"
	}

	if { [catch { exec [::config::getKey convertpath] "$sourcefile" "$destfile" } res] } {
		status_log "run_convert CONVERT ERROR IN CONVERSION: $res" white
		return ""
	}

	return $destfile

}


proc png_to_gif { pngfile } {

	global tcl_platform
	
	set file_noext [filenoext $pngfile]

	if { ![file exists $pngfile] } {
		status_log "Tring to convert file $pngfile that does not exist\n" error
		return ""
	}

	status_log "png_to_gif: converting $pngfile to ${file_noext}.gif\n"

	#IMPORTANT: If convertpath is blank, set it to "convert"
	if { [::config::getKey convertpath] == "" } {
		::config::setKey convertpath "convert"
	}

	if { [catch { exec [::config::getKey convertpath] "${pngfile}" "${file_noext}.gif" } res] } {
		status_log "png_to_gif CONVERT ERROR IN CONVERSION: $res" white
		return ""
	}

	return ${file_noext}.gif

}
proc convert_file { in out {size ""} } {

	global tcl_platform
	
	if { ![file exists $in] } {
		status_log "Tring to convert file $in that does not exist\n" error
		return ""
	}

	status_log "convert_file: converting $in to $out with size $size\n"

	#IMPORTANT: If convertpath is blank, set it to "convert"
	if { [::config::getKey convertpath] == "" } {
		::config::setKey convertpath "convert"
	}

	if {$size == "" } {
		if { [catch { exec [::config::getKey convertpath] "${in}" "${out}" } res] } {
			status_log "convert_file : CONVERT ERROR IN CONVERSION: $res" white
			return ""
		}
	} else {
		if { [catch {exec [::config::getKey convertpath] -size $size -resize $size "${in}" "${out}" } res] } {
			status_log "convert_file CONVERT ERROR IN CONVERSION : $res" white
			return ""
		}
	}

	return $out

}

proc convert_image_plus { filename type size } {

	global HOME
	catch { create_dir [file join $HOME $type]}
	return [convert_image $filename [file join $HOME $type] $size]

}




proc load_my_pic {} {
	status_log "load_my_pic: Trying to set display picture [::config::getKey displaypic]\n" blue
	if {[file readable [filenoext [::skin::GetSkinFile displaypic [::config::getKey displaypic]]].gif]} {
		image create photo my_pic -file "[filenoext [::skin::GetSkinFile displaypic [::config::getKey displaypic]]].gif"
	} else {
		status_log "load_my_pic: Picture not found!!\n" red
		clear_disp
	}
}

proc pictureBrowser {} {
	global selected_image

	if { [winfo exists .picbrowser] } {
		raise .picbrowser
		return
	}

	toplevel .picbrowser

	set selected_image [::config::getKey displaypic]

	ScrolledWindow .picbrowser.pics -auto vertical -scrollbar vertical
	text .picbrowser.pics.text -width 40 -font sboldf -background white \
		-cursor left_ptr -font splainf -selectbackground white -selectborderwidth 0 -exportselection 0 \
		-relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0 -wrap none
	.picbrowser.pics setwidget .picbrowser.pics.text

	load_my_pic

	label .picbrowser.mypic -image my_pic -background white -borderwidth 2 -relief solid
	label .picbrowser.mypic_label -text "[trans mypic]" -font splainf

	button .picbrowser.browse -command "set selected_image \[pictureChooseFile\]; reloadAvailablePics" -text "[trans browse]..." 
	button .picbrowser.delete -command "pictureDeleteFile ;reloadAvailablePics" -text "[trans delete]"
	button .picbrowser.purge -command "purgePictures; reloadAvailablePics" -text "[trans purge]..." 
	button .picbrowser.ok -command "set_displaypic \${selected_image};destroy .picbrowser" -text "[trans ok]" 
	button .picbrowser.cancel -command "destroy .picbrowser" -text "[trans cancel]" 
	
	checkbutton .picbrowser.showcache -command "reloadAvailablePics" -variable show_cached_pics\
		-font sboldf -text [trans showcachedpics]

	grid .picbrowser.pics -row 0 -column 0 -rowspan 4 -columnspan 3 -padx 3 -pady 3 -sticky nsew

	grid .picbrowser.showcache -row 4 -column 0 -columnspan 3 -sticky w
	
	grid .picbrowser.browse -row 5 -column 0 -padx 3 -pady 3 -sticky ewn
	grid .picbrowser.delete -row 5 -column 1 -padx 3 -pady 3 -sticky ewn
	grid .picbrowser.purge -row 5 -column 2 -padx 5 -pady 3 -sticky ewn

	grid .picbrowser.mypic_label -row 0 -column 3 -padx 3 -pady 3 -sticky s
	grid .picbrowser.mypic -row 1 -column 3 -padx 3 -pady 3 -sticky n
	grid .picbrowser.ok -row 2 -column 3 -padx 3 -pady 3 -sticky sew
	grid .picbrowser.cancel -row 3 -column 3 -padx 3 -pady 3 -sticky new

	grid column .picbrowser 0 -weight 1	
	grid column .picbrowser 1 -weight 1	
	grid column .picbrowser 2 -weight 1	
	grid row .picbrowser 3 -weight 1		


	#Free ifmages:
	bind .picbrowser <Destroy> {
		if {"%W" == ".picbrowser"} {
			global image_names
			foreach img $image_names {
				image delete $img
			}
			unset image_names
			unset selected_image
		} 
	}

	tkwait visibility .picbrowser.pics.text
	reloadAvailablePics	

	.picbrowser.pics.text configure -state disabled

	wm title .picbrowser "[trans picbrowser]"
	moveinscreen .picbrowser 30
}

proc purgePictures {} {
	global HOME

	set answer [::amsn::messageBox [trans confirmpurge] yesno question [trans purge] .picbrowser]
	if { $answer == "yes"} {
		foreach filename [glob -nocomplain -directory [file join $HOME displaypic cache] *.png] {
			catch { file delete $filename }
			catch { file delete "[filenoext $filename].gif" }
			catch { file delete "[filenoext $filename].dat" }
		}

	}

}

proc getPictureDesc {filename} {
	if { [file readable "[filenoext $filename].dat"] } {
		set f [open "[filenoext $filename].dat"]
		set desc ""
		while {![eof $f]} {
			gets $f data
			if { $desc != "" } {
				set desc "$desc\n$data"
			} else {
				set desc $data
			}
		}
		close $f
		return $desc
	}
	return ""
}

proc addPicture {the_image pic_text filename} {
	frame .picbrowser.pics.text.$the_image -borderwidth 0 -highlightthickness 0 -background white -highlightbackground black
	label .picbrowser.pics.text.$the_image.pic -image $the_image -relief flat -borderwidth 0 -highlightthickness 2 \
		-background black -highlightbackground black -highlightcolor black
	label .picbrowser.pics.text.$the_image.desc -text "$pic_text" -font splainf -background white
	pack .picbrowser.pics.text.$the_image.pic -side left -padx 3 -pady 0
	pack .picbrowser.pics.text.$the_image.desc -side left -padx 5 -pady 0
	bind .picbrowser.pics.text.$the_image <Enter> ".picbrowser.pics.text.$the_image.pic configure -highlightbackground red -background red"
	bind .picbrowser.pics.text.$the_image <Leave> ".picbrowser.pics.text.$the_image.pic configure -highlightbackground black -background black"
	bind .picbrowser.pics.text.$the_image <Button1-ButtonRelease> "[list .picbrowser.mypic configure -image $the_image];[list set selected_image $filename]"
	bind .picbrowser.pics.text.$the_image.pic <Button1-ButtonRelease> "[list .picbrowser.mypic configure -image $the_image];[list set selected_image $filename]"
	.picbrowser.pics.text window create end -window .picbrowser.pics.text.$the_image -padx 3 -pady 3
	.picbrowser.pics.text insert end "\n"

}

proc reloadAvailablePics { } {
	global HOME image_names show_cached_pics skin

	set scrollidx [.picbrowser.pics.text yview]

	#Destroy old embedded windows
	set windows [.picbrowser.pics.text window names]
	foreach window $windows {
		destroy $window
	}

	#Delete all picture	
	if { [info exists image_names] } {
		foreach img $image_names {
			if { $img != [.picbrowser.mypic cget -image] } {
				image delete $img
			} else {
				lappend images_in_use $img
			}
		}
		unset image_names
	}


	.picbrowser.pics.text configure -state normal
	.picbrowser.pics.text delete 0.0 end

#	set files [list]
	set files [glob -nocomplain -directory [file join skins default displaypic] *.png]
	set myfiles [glob -nocomplain -directory [file join $HOME displaypic] *.png]
	set cachefiles [glob -nocomplain -directory [file join $HOME displaypic cache] *.png]

	addPicture [::skin::getNoDisplayPicture] "[trans nopic]" ""


	if { [info exists images_in_use]	} {
		set image_names $images_in_use
		unset images_in_use
	} else {
		set image_names [list]	
	}


	foreach filename [lsort -dictionary $files] {
		set skin_file "[::skin::GetSkinFile displaypic [file tail [filenoext $filename].gif]]"
		if { [file exists $skin_file] } {
			set the_image [image create photo -file $skin_file ]	
			addPicture $the_image "[getPictureDesc $filename]" [file tail $filename]
			lappend image_names $the_image
		}
	}
	.picbrowser.pics.text insert end "___________________________\n\n"	

	foreach filename [lsort -dictionary $myfiles] {
		if { [file exists "[filenoext $filename].gif"] } {
			set the_image [image create photo -file "[filenoext $filename].gif" ]	
			addPicture $the_image "[getPictureDesc $filename]" [file tail $filename]
			lappend image_names $the_image
		}
	}

	.picbrowser.pics.text insert end "___________________________\n\n"	

	if { $show_cached_pics } {
		foreach filename $cachefiles {
			if { [file exists "[filenoext $filename].gif"] } {
				set the_image [image create photo -file "[filenoext $filename].gif" ]
				addPicture $the_image "[getPictureDesc $filename]" "cache/[file tail $filename]"
				lappend image_names $the_image
			}
		}
	} else {
		.picbrowser.pics.text tag configure morepics -font bplainf -underline true
		.picbrowser.pics.text tag bind morepics <Enter> ".picbrowser.pics.text conf -cursor hand2"
		.picbrowser.pics.text tag bind morepics <Leave> ".picbrowser.pics.text conf -cursor left_ptr"
		.picbrowser.pics.text tag bind morepics <Button1-ButtonRelease> "global show_cached_pics; set show_cached_pics 1; reloadAvailablePics"

		.picbrowser.pics.text insert end "  "
		.picbrowser.pics.text insert end "[trans cachedpics [llength $cachefiles]]..." morepics
		.picbrowser.pics.text insert end "\n"
	
	}

	update idletasks

	.picbrowser.pics.text yview moveto [lindex $scrollidx 0]

	.picbrowser.pics.text configure  -state disabled



}


#proc chooseFileDialog {basename {initialfile ""} {types {{"All files"         *}} }} {}
proc chooseFileDialog { {initialfile ""} {title ""} {parent ""} {entry ""} {operation "open"} {types {{ "All Files" {*} }} }} {

	if { $parent == "" } {
		set parent "."
		catch {set parent [focus]}
	}
	
	global  starting_dir
	
	if { ![file isdirectory $starting_dir] } {
		set starting_dir [pwd]
	}
	
	if { $operation == "open" } {
		if {![file exists $initialfile]} {
			set initialfile ""
		}
		set selfile [tk_getOpenFile -filetypes $types -parent $parent -initialdir $starting_dir -initialfile $initialfile -title $title]
	} else {
		set selfile [tk_getSaveFile -filetypes $types -parent $parent -initialdir $starting_dir -initialfile $initialfile -title $title]
	}
	if { $selfile != "" } {
		#Remember last directory
		set starting_dir [file dirname $selfile]
		
		if { $entry != "" } {
			$entry delete 0 end
			$entry insert 0 $selfile
			$entry xview end
		}
	}
	
	return $selfile
}


proc pictureDeleteFile {} {
	global selected_image HOME

	if { $selected_image!="" && [file exists [file join $HOME displaypic $selected_image]]} {
		set answer [::amsn::messageBox [trans confirm] yesno question [trans delete]]
		if { $answer == "yes"} {
			set filename [file join $HOME displaypic $selected_image]
			catch {file delete $filename}
			catch {file delete [filenoext $filename].gif}
			catch {file delete [filenoext $filename].dat}
			set selected_image ""
			.picbrowser.mypic configure -image [::skin::getNoDisplayPicture]
			if { [file exists $filename] == 1 } {
				::amsn::messageBox [trans faileddelete] ok error [trans failed]
				status_log "Failed: file $filename could not be deleted.\n";
			}
		}

	} else {
		::amsn::messageBox [trans faileddeleteperso] ok error [trans failed]
		status_log "Failed: file [file join $HOME displaypic $selected_image] does not exists.\n";
	}
}

proc pictureChooseFile { } {
	global selected_image image_names

	if { [catch { exec [::config::getKey convertpath] } res] } {
		msg_box "[trans installconvert]"
		status_log "ImageMagick not installed got error $res\n Disabling display pictures\n"
		return [::config::getKey displaypic]

	}


	set file [chooseFileDialog "" "" "" "" open [list [list [trans imagefiles] [list *.gif *.GIF *.jpg *.JPG *.bmp *.BMP *.png *.PNG]] [list [trans allfiles] *]]]

	if { $file != "" } {
		if { ![catch {convert_image_plus $file displaypic "96x96"} res]} {
			set image_name [image create photo -file [::skin::GetSkinFile "displaypic" "[filenoext [file tail $file]].gif"]]
			.picbrowser.mypic configure -image $image_name
			set selected_image "[filenoext [file tail $file]].png"

			global HOME
			set desc_file "[filenoext [file tail $file]].dat"
			set fd [open [file join $HOME displaypic $desc_file] w]
			status_log "Writing description to $desc_file\n"
			puts $fd "[clock format [clock seconds] -format %x]\n[filenoext [file tail $file]].png"
			close $fd

			lappend image_names $image_name
			status_log "Created $image_name\n"
			return "[filenoext [file tail $file]].png"
		} else {
			status_log "Error converting $file: $res\n"
		}
	}

	return ""

}

proc set_displaypic { file } {

	if { $file != "" } {
		::config::setKey displaypic $file
		status_log "set_displaypic: File set to $file\n" blue
		load_my_pic
		::MSN::changeStatus [set ::MSN::myStatus]
	} else {
		status_log "set_displaypic: Setting displaypic to no_pic\n" blue
		clear_disp
	}
}

proc clear_disp { } {

	::config::setKey displaypic ""

	catch {image create photo my_pic -file "[::skin::GetSkinFile displaypic nopic.gif]"}
	::MSN::changeStatus [set ::MSN::myStatus]

}


###################### Protocol Debugging ###########################
if { $initialize_amsn == 1 } {
	global degt_protocol_window_visible degt_command_window_visible
	
	set degt_protocol_window_visible 0
	set degt_command_window_visible 0
}

proc degt_protocol { str {colour ""}} {
	global followtext_degt
	
	.degt.mid.txt insert end "[timestamp] $str\n" $colour
#	puts "$str"
	.degt.mid.txt delete 0.0 end-1000lines
	if { $followtext_degt == 1} {
		.degt.mid.txt yview end
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
		raise .degt
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
		label .degt.top.name -text "Protocol" -justify left -font sboldf
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
	
	checkbutton .degt.follow -text "[trans followtext]" -onvalue 1 -offvalue 0 -variable followtext_degt -font sboldf
	
	frame .degt.bot -relief sunken -borderwidth 1 -class Degt
	button .degt.bot.save -text "[trans savetofile]" -command degt_protocol_save 
		button .degt.bot.clear  -text "Clear" \
			-command ".degt.mid.txt delete 0.0 end"
		button .degt.bot.close -text [trans close] -command degt_protocol_win_toggle 
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
	
	chooseFileDialog "protocol_log.txt" "" $w $w.filename.entry save 
	catch {grab $w}

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
		# Send command to the Notification Server
		::MSN::WriteSB ns $nscmd $nspar
		}
	}
	bind . <Control-m> { degt_ns_command_win_toggle }
	wm protocol .nscmd WM_DELETE_WINDOW { degt_ns_command_win_toggle }
}



proc bgerror { args } {
	global errorInfo errorCode HOME2 tcl_platform tk_version tcl_version
	
	if { [lindex $args 0] == [list] } {
		return
	}
	
	if { [info exists ::dont_give_bug_reports] && $::dont_give_bug_reports == 1 } {
		return
	}

	set posend [split [.status.info index end] "."]
	set pos "[expr {[lindex $posend 0]-25}].[lindex $posend 1]"
	set posend "[lindex $posend 0].[lindex $posend 1]"

	set prot_posend [split [.degt.mid.txt index end] "."]
	set prot_pos "[expr {[lindex $prot_posend 0]-25}].[lindex $prot_posend 1]"
	set prot_posend "[lindex $prot_posend 0].[lindex $prot_posend 1]"
	
		
	status_log "-----------------------------------------\n" error
	status_log ">>> GOT TCL/TK ERROR : $args\n>>> Stack:\n$errorInfo\n>>> Code: $errorCode\n" error
	status_log "-----------------------------------------\n" error
	catch { status_log ">>> AMSN version: $::version - AMSN date: $::date\n" error }
	catch { status_log ">>> TCL version : $tcl_version - TK version : $tk_version\n" error } 
	catch { status_log ">>> tcl_platform array content : [array get tcl_platform]\n" error }
	status_log "-----------------------------------------\n\n" error

	set fd [open [file join $HOME2 bugreport.amsn] a]

	puts $fd "Bug generated at [clock format [clock seconds] -format "%D - %T"]"
	puts $fd "-----------------------------------------"
	puts $fd ">>> TCL/TK Error: $args\n>>> Stack:\n$errorInfo\n\n>>> Code : $errorCode"
	puts $fd "-----------------------------------------"
	puts $fd ">>> AMSN version: $::version - AMSN date: $::date"
	catch { puts $fd ">>> TCL version : $tcl_version - TK version : $tk_version"}
	catch { puts $fd ">>> tcl_platform array content : [array get tcl_platform]" }

	set tclfiles [glob -nocomplain *.tcl]
	set latestmtime 0
	set latestfile ""
	foreach tclfile $tclfiles {
		file stat $tclfile filestat
		set mtime $filestat(mtime)
		if { $mtime > $latestmtime } {
			set latestmtime $mtime
			set latestfile $tclfile
		}
	}
	puts $fd ">>> Latest modification time file: $latestfile: [clock format $latestmtime -format %y/%m/%d-%H:%M]"
	puts $fd "-----------------------------------------"
	puts $fd ">>> Status_log:\n[.status.info get $pos $posend]\n"
	puts $fd "-----------------------------------------"
	puts $fd ">>> Protocol debug:\n[.degt.mid.txt get $prot_pos $prot_posend]\n"
	puts $fd "==========================================================================\n\n"


	close $fd

	show_bug_dialog
	#msg_box "[trans tkerror [file join $HOME2 bugreport.amsn]]"
}


proc show_bug_dialog {} {

	set w ".bug_dialog"

	catch {destroy $w}
	toplevel $w -class Dialog
	wm title $w "AMSN Error"
	wm iconname $w Dialog
	wm protocol $w WM_DELETE_WINDOW "set closed_bug_window 1"

	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		#Empty, NO TRANSIENT ON MAC OS X!!! Plz use ShowTransient when it's possible
	} else {
		if {[winfo viewable [winfo toplevel [winfo parent $w]]] } {
			wm transient $w [winfo toplevel [winfo parent $w]]
		}
	}

	frame $w.bot
	frame $w.med
	frame $w.top
	pack $w.bot -side bottom -fill both
	pack $w.med -side bottom -fill both
	pack $w.top -side top -fill both -expand 1

	label $w.msg -justify left -text [trans tkerror [file join $::HOME2 bugreport.amsn]] -wraplength 300 -font sboldf
	pack $w.msg -in $w.top -side right -expand 1 -fill both -padx 3m -pady 3m

	label $w.bitmap -image [::skin::loadPixmap warning]
	pack $w.bitmap -in $w.top -side left -padx 3m -pady 3m

	checkbutton $w.ignoreerrors -text [trans ignoreerrors] -variable "dont_give_bug_reports" -font sboldf
	pack $w.ignoreerrors -in $w.med -side left -padx 10 -pady 5

	button $w.button -text [trans ok] -command "set closed_bug_window 1" -default active -highlightbackground #e8e8e8 -activeforeground #5b76c6 -pady 1
	pack $w.button -in $w.bot
	
	#Execute script on Mac OS X to create a mail in "Mail" application and attach the bugreport to the mail
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		button $w.mail -text [trans sendmail] -command "exec osascript utils/applescript/mail-bugreport.scpt &" -highlightbackground #e8e8e8 -activeforeground #5b76c6  -pady 1
		pack $w.mail -in $w.bot
	}

	bind $w <Return> "set closed_bug_window 1"

	wm withdraw $w
	update idletasks
	set x [expr {[winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
		- [winfo vrootx [winfo parent $w]]}]
	set y [expr {[winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
		- [winfo vrooty [winfo parent $w]]}]
	# Make sure that the window is on the screen and set the maximum
	# size of the window is the size of the screen.  That'll let things
	# fail fairly gracefully when very large messages are used. [Bug 827535]
	if {$x < 0} {
		set x 0
	}
	if {$y < 0} {
		set y 0
	}
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w]
	wm geom $w +$x+$y
	wm deiconify $w

	# 7. Set a grab and claim the focus too.

	set oldFocus [focus]
	set oldGrab [grab current $w]
	if {[string compare $oldGrab ""]} {
		set grabStatus [grab status $oldGrab]
	}
	grab $w
	raise $w
	focus $w.button

	# 8. Wait for the user to respond, then restore the focus and
	# return the index of the selected button.  Restore the focus
	# before deleting the window, since otherwise the window manager
	# may take the focus away so we can't redirect it.  Finally,
	# restore any grab that was in effect.

	vwait closed_bug_window
	catch {focus $oldFocus}
	catch {
		bind $w <Destroy> {}
		destroy $w
	}
}


#ShowTransient ?{wintransient}
#The function try to know if the operating system is Mac OS X or not. If no, enable window in transient. Else,
#don't change nothing.
proc ShowTransient {win {parent "."}} {
	global tcl_platform
		if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
		#Empty	
		} else {
			wm transient $win $parent
		}
}


#lastkeytyped 
#Force the focus to bottom.in.input when someone try to write something in out.text
proc lastKeytyped {typed bottom} {

		if {[regexp \[a-zA-Z\] $typed]} {
			
			focus -force $bottom.left.in.text;$bottom.left.in.text insert insert $typed
		}
}

# taken from ::tk::TextSetCursor
# Move the insertion cursor to a given position in a text.  Also
# clears the selection, if there is one in the text, and makes sure
# that the insertion cursor is visible.  Also, don't let the insertion
# cursor appear on the dummy last line of the text.
#
# Arguments:
# w -		The text window.
# pos -		The desired new position for the cursor in the window.

proc my_TextSetCursor {w pos} {

    if {[$w compare $pos == end]} {
	set pos {end - 1 chars}
    }
    $w mark set insert $pos
    $w tag remove sel 1.0 end
    $w see insert
    #removed incase not supported for tk8.3
    #if {[$w cget -autoseparators]} {$w edit separator}
}

# taken from ::tk::TextKeySelect
# This procedure is invoked when stroking out selections using the
# keyboard.  It moves the cursor to a new position, then extends
# the selection to that position.
#
# Arguments:
# w -		The text window.
# new -		A new position for the insertion cursor (the cursor hasn't
#		actually been moved to this position yet).

proc my_TextKeySelect {w new} {

    if {[string equal [$w tag nextrange sel 1.0 end] ""]} {
	if {[$w compare $new < insert]} {
	    $w tag add sel $new insert
	} else {
	    $w tag add sel insert $new
	}
	$w mark set anchor insert
    } else {
	if {[$w compare $new < anchor]} {
	    set first $new
	    set last anchor
	} else {
	    set first anchor
	    set last $new
	}
	$w tag remove sel 1.0 $first
	$w tag add sel $first $last
	$w tag remove sel $last end
    }
    $w mark set insert $new
    $w see insert
    update idletasks
}


