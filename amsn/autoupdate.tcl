package require AMSN_BWidget

namespace eval ::autoupdate {

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

		button .tlsdown.f.ok -text "[trans ok]" -command "::autoupdate::downloadTLS; bind .tlsdown <Destroy> {}; destroy .tlsdown"
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

			if {[ catch {set tok [::http::geturl $downloadurl -progress "::autoupdate::downloadTLSProgress $downloadurl" -command "::autoupdate::downloadTLSCompleted $downloadurl"]} res ]} {
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
	button $w.bottom.buttons.update -text "Update" -command "::autoupdate::amsn_update $tmp_data;destroy $w" -default active
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

#When the user cancel the update, we check if he clicked on "Don't ask update again for one week"
#If yes, save the actual time in seconds in the weekdate
proc dont_ask_before {} {
	if {$::dont_ask_for_one_week} {
		::config::setKey weekdate "[clock seconds]"
	}
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
			::autoupdate::update_window $tmp_data
		} else {
			status_log "Not yet 3 days\n" red 
		}


	} else {
		catch {status_log "check_web_ver: status=[::http::status $token] ncode=[::http::ncode $token]\n" blue}

	}
	::http::cleanup $token

	# Auto-update for language files
	if { [::config::getKey activeautoupdate] } {
		::lang::UpdateLang
	}

	return $newer
}

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
proc check_version_silent {} {
	global weburl

	catch {
		::http::geturl ${weburl}/amsn_latest -timeout 10000 -command check_web_version
	}

}

}
