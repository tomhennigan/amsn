
::Version::setSubversionId {$Id$}

package require BWidget

namespace eval ::autoupdate {

	proc installTLS {} {
		global tcl_platform
		global tlsplatform

		if { [OnLinux] } {
			if { ($tcl_platform(machine) == "ppc")} {
				set tlsplatform "linuxppc"
			} elseif { ($tcl_platform(machine) == "sparc")} {
				set tlsplatform "linuxsparc"
			} elseif { ($tcl_platform(machine) == "x86_64")} {
				set tlsplatform "linuxx86_64"
			} else {
				set tlsplatform "linuxx86"
			}
		} elseif { $tcl_platform(os) == "NetBSD"} {
			set tlsplatform "netbsdx86"
		} elseif { $tcl_platform(os) == "FreeBSD"} {
			set tlsplatform "freebsdx86"
		} elseif { $tcl_platform(os) == "Solaris"} {
			set tlsplatform "solaris28"
		} elseif { [OnWin] } {
			set tlsplatform "win32"
		} elseif { [OnDarwin] } {
			set tlsplatform "mac"
		} else {
			set tlsplatform "src"
		}

		toplevel .tlsdown
		wm group .tlsdown .
		wm title .tlsdown "[trans tlsinstall]"

		label .tlsdown.caption -text "[trans tlsinstallexp]" -anchor w -font splainf

		label .tlsdown.choose -text "[trans choosearq]:" -anchor w -font sboldf

		pack .tlsdown.caption -side top -expand true -fill x -padx 10 -pady 10
		pack .tlsdown.choose -side top -anchor w -padx 10 -pady 10

		combobox::combobox .tlsdown.os -editable false -width 60 -command ::autoupdate::TLS_OS_choosed
		.tlsdown.os list delete 0 end
		set trans_sourcecode [trans sourcecode]
		set trans_dontdownload [trans dontdownload]
		set list_os_name [list Linux-x86 Linux-x86_64 Linux-PowerPC Linux-SPARC NetBSD-x86 NetBSD-SPARC64 FreeBSD-x86 "Solaris 2.6 SPARC" "Solaris 2.8 SPARC" Windows "Mac OS X" $trans_sourcecode $trans_dontdownload ]
		eval .tlsdown.os list insert end $list_os_name
		.tlsdown.os select 0

		frame .tlsdown.f

		button .tlsdown.f.ok -text "[trans ok]" -command "::autoupdate::downloadTLS; bind .tlsdown <Destroy> {}; destroy .tlsdown"
		button .tlsdown.f.cancel -text "[trans cancel]" -command "destroy .tlsdown"

		pack .tlsdown.f.cancel -side right -padx 10 -pady 10
		pack .tlsdown.f.ok -side right -padx 10 -pady 10

		pack .tlsdown.os

		pack .tlsdown.f -side top

		bind .tlsdown <Destroy> {
			if {"%W" == ".tlsdown"} {
				::amsn::infoMsg "[trans notls]"
			} 
		}

		catch {grab .tlsdown}
	}

	proc TLS_OS_choosed {w value} {
		global tlsplatform
		set trans_sourcecode [trans sourcecode]
		set trans_dontdownload [trans dontdownload]
		set list_os_name [list Linux-x86 Linux-x86_64 Linux-PowerPC Linux-SPARC NetBSD-x86 NetBSD-SPARC64 FreeBSD-x86 "Solaris 2.6 SPARC" "Solaris 2.8 SPARC" Windows "Mac OS X" $trans_sourcecode $trans_dontdownload ]
		set list_os_value [list linuxx86 linuxx86_64 linuxppc linuxsparc netbsdx86 netbsdsparc64 freebsdx86 solaris26 solaris28 win32 mac src nodown]
		set t 0
		foreach x $list_os_name {
			if {$value eq $x} {
				set tlsplatform [lindex $list_os_value $t]
			}
			incr t
		}
	}

	proc downloadTLS {} {
		global tlsplatform

		if { $tlsplatform == "nodown" } {
			::amsn::infoMsg [trans notls]
			return
		}

		set downloadurl "$::weburl/download-tls.php?arch=$tlsplatform"


		if {[ catch {set tok [::http::geturl $downloadurl -command "::autoupdate::downloadTLS2 $downloadurl"]} res ]} {
			::autoupdate::errorDownloadingTLS "" $res
			catch {::http::cleanup $tok}
		}
	}

	proc downloadTLS2 { downloadurl token } {
		status_log "status: [http::status $token]\n"
		if { [::http::ncode $token] == 302} {
			upvar #0 $token state
			array set meta $state(meta)
			set downloadurl $meta(Location)
			status_log "got referal to $downloadurl"
			catch {::http::cleanup $token}

			set w .tlsprogress

			if {[winfo exists $w]} {
				destroy $w
			}

			toplevel $w
			wm group $w .

			label $w.l -text "[trans downloadingtls $downloadurl]" -font splainf
			pack $w.l -side top -anchor w -padx 10 -pady 10
			pack [::dkfprogress::Progress $w.prbar] -fill x -expand 0 -padx 5 -pady 5 -side top
			label $w.progress -text "[trans receivedbytes 0 ?]" -font splainf
			pack $w.progress -side top -padx 10 -pady 3

			button $w.close -text "[trans cancel]" -command ""
			pack $w.close -side bottom -pady 5 -padx 10

			wm title $w "[trans tlsinstall]"

			::autoupdate::downloadTLSRedirect $w $downloadurl 

		} else {
			::autoupdate::errorDownloadingTLS "" [trans cantget $downloadurl]
			catch {::http::cleanup $token}
		}
	}
	proc downloadTLSRedirect { w downloadurl } {
		$w.l configure -text "[trans downloadingtls $downloadurl]" 
		$w.progress configure -text "[trans receivedbytes 0 ?]" 
		::dkfprogress::SetProgress $w.prbar 0
		
		if {[ catch {set tok [::http::geturl $downloadurl -progress "::autoupdate::downloadTLSProgress $w $downloadurl" -command "::autoupdate::downloadTLSCompleted $w $downloadurl"]} res ]} {
			::autoupdate::errorDownloadingTLS $w $res
			catch {::http::cleanup $tok}
		} else {
			$w.close configure -command "::http::reset $tok"
			wm protocol $w WM_DELETE_WINDOW "::http::reset $tok"
		}
	}
	proc downloadTLSCompleted { w downloadurl token } {
		global HOME2 tlsplatform
		status_log "status: [http::status $token]\n"
		if { [::http::status $token] == "reset" } {
			::http::cleanup $token

			destroy .tlsprogress
			return
		}

		if { [::http::status $token] == "ok" && ([::http::ncode $token] == 301 || [::http::ncode $token] == 302)} {
			upvar #0 $token state
			
			array set meta $state(meta)
			if {[info exists meta(Location)] } {
				after 100 [list ::autoupdate::downloadTLSRedirect $w $meta(Location)]
			} else {
				::autoupdate::errorDownloadingTLS $w [trans cantget $downloadurl]
			}

			::http::cleanup $token
			return
		} elseif { [::http::status $token] != "ok" || [::http::ncode $token] != 200} {
			::autoupdate::errorDownloadingTLS $w  [trans cantget $downloadurl]
			::http::cleanup $token
			return
		}

		set lastslash [expr {[string last "/" $downloadurl]+1}]
		set fname [string range $downloadurl $lastslash end]


		if { [string length [::http::data $token]] == 0 } {
			::autoupdate::errorDownloadingTLS $w [trans cantget $downloadurl]
			return
		}

		switch $tlsplatform {
			"solaris26" -
			"solaris28" -
			"linuxx86" -
			"linuxx86_64" -
			"linuxppc" -
			"linuxsparc" -
			"netbsdx86" -
			"netbsdsparc64" -
			"freebsdx86" -
			"mac" -
			"win32" {
				set olddir [pwd]
				if { [catch {
					set file_id [open [file join [::config::getKey receiveddir] $fname] w]
					fconfigure $file_id -translation {binary binary} -encoding binary
					puts -nonewline $file_id [::http::data $token]
					close $file_id

					cd [file join $HOME2 plugins]

					if { $tlsplatform == "win32" } {
						exec [file join [::config::getKey receiveddir] $fname] "x" "-o" "-y"
					} else {
						exec gzip -cd [file join [::config::getKey receiveddir] $fname] | tar xvf -
					}
					cd $olddir
					::amsn::infoMsg "[trans tlsinstcompleted]"
				} res ] } {
					cd $olddir

					::autoupdate::errorDownloadingTLS $w $res
				}
			}
			"src" {
			if { [catch {
					set file_id [open [file join [::config::getKey receiveddir] $fname] w]
					fconfigure $file_id -translation {binary binary} -encoding binary
					puts -nonewline $file_id [::http::data $token]
					close $file_id
					::amsn::infoMsg "[trans tlsdowncompleted $fname [::config::getKey receiveddir] [file join $HOME2 plugins]]"
				} res ] } {
					::autoupdate::errorDownloadingTLS $w $res
				}
			}
			default {
				::amsn::infoMsg "[trans tlsdowncompleted $fname [::config::getKey receiveddir] [file join $HOME2 plugins]]"
			}
		}

		destroy $w
		::http::cleanup $token
	}

	proc downloadTLSProgress {w url token {total 0} {current 0} } {
		if {$total > 0 } {
			::dkfprogress::SetProgress $w.prbar [expr {$current*100/$total}]
			$w.progress configure -text "[trans receivedbytes [::amsn::sizeconvert $current] [::amsn::sizeconvert $total]]"
		}

	}

	proc errorDownloadingTLS { w errormsg } {
		::amsn::errorMsg "[trans errortls]: $errormsg"
		if {$w != "" } {
			catch { destroy $w }
		}
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
		wm title $w [trans download]
		
		#Create 2 frames
		frame $w.top
		frame $w.bottom
		
		#Add bitmap and text at the top
		label $w.top.bitmap -image [::skin::loadPixmap download]
		label $w.top.text -text [trans downloadingwait] -font bigfont
		#Get the download URL
		set amsn_url [::autoupdate::get_download_link $new_version]
		
		#Add button at the bottom
		button $w.bottom.cancel -text [trans cancel]
		
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
		set amsn_tarball [::http::geturl $amsn_url -progress "::autoupdate::amsn_download_progress $amsn_url" -command "::autoupdate::amsn_choose_dir $amsn_url"]
		
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
		set homepagelink "$::weburl/"
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
		#label $w.bottom.q -text "Would you like to update aMSN immediatly?" -font bigfont
		#button $w.bottom.buttons.update -text "Update" -command "::autoupdate::amsn_update $tmp_data;destroy $w" -default active
		#button $w.bottom.buttons.cancel -text "Cancel" -command "::autoupdate::dont_ask_before;destroy $w"
		#label $w.bottom.lastbar -image [::skin::loadPixmap greyline]
		#Checkbox to verify if the user want to have an alert again or just in one week
		checkbutton $w.bottom.ignoreoneweek -text "[trans dontaskweek]" -variable "dont_ask_for_one_week" -font sboldf
		
		#Pack all the stuff for the top
		pack $w.top.bitmap -side top -padx 3m -pady 3m
		pack $w.top.i
		pack $w.top.buttons.changelog -side left
		pack $w.top.buttons.homepage -side right
		pack $w.top.buttons -fill x
		pack $w.top -side top -pady 5
		
		#Pack all the stuff for the bottom
		pack $w.bottom.bitmap
		#pack $w.bottom.q
		#pack $w.bottom.buttons.update -side left -padx 5
		#pack $w.bottom.buttons.cancel -side right -padx 5
		pack $w.bottom.buttons
		#pack $w.bottom.lastbar -pady 5
		pack $w.bottom.ignoreoneweek
		pack $w.bottom -side bottom -pady 15
		
		bind $w <<Escape>> "::autoupdate::dont_ask_before;destroy .update"
		bind $w <<Destroy>> "::autoupdate::dont_ask_before;destroy .update"
		wm protocol $w WM_DELETE_WINDOW "::autoupdate::dont_ask_before;destroy .update"
		moveinscreen $w 30
	}

	#Create the download link (change on the differents platforms)
	proc get_download_link {new_version} {
		set new_version [string replace $new_version 1 1 "_"]
		#set new_version [string replace $new_version 1 1 "-"]
		append amsn_url "http://aleron.dl.sourceforge.net/sourceforge/amsn/amsn-" $new_version
		if { [OnDarwin] } {
			append amsn_url ".dmg"
		} elseif { [OnWin] } {
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
			$w.top.text configure -text [trans cantget $url]
			$w.bottom.cancel configure -text [trans close] -command "destroy $w"
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
			$w.top.text configure -text [trans downloadcanceled]
			$w.bottom.cancel configure -text [trans close] -command "destroy $w"
			bind $w <<Escape>> "destroy $w"
			bind $w <<Destroy>> "destroy $w"
			wm protocol $w WM_DELETE_WINDOW "destroy $w"
			return
		}
		#If it's impossible to get the URL
		if { [::http::status $token] != "ok" || [::http::ncode $token] != 200 } {
			$w.top.text configure -text [trans cantget $url]
			$w.bottom.cancel configure -text [trans close] -command "destroy $w"
			bind $w <<Escape>> "destroy $w"
			bind $w <<Destroy>> "destroy $w"
			wm protocol $w WM_DELETE_WINDOW "destroy $w"
			return
		}
		#If the download is over, remove cancel button and progress bar
		destroy $w.bottom.prbar
		destroy $w.bottom.cancel
		
		#Get default location for each platform
		set location [::autoupdate::get_default_location]
		set namelocation [lindex $location 0]
		set defaultlocation [lindex $location 1]
		
		$w.top.text configure -text [trans savelocation $namelocation]
		#Create 2 buttons, save and save as
		button $w.bottom.save -command "::autoupdate::amsn_save $url $token $defaultlocation" -text [trans save] -default active
		button $w.bottom.saveas -command "::autoupdate::amsn_save_as $url $token $defaultlocation" -text [trans saveotherdirectory] -default normal
		pack $w.bottom.save
		pack $w.bottom.saveas -pady 5
		#If user try to close the window, just save in default directory
		bind $w <<Escape>> "::autoupdate::amsn_save $url $token $defaultlocation"
		bind $w <<Destroy>> "::autoupdate::amsn_save $url $token $defaultlocation"
		wm protocol $w WM_DELETE_WINDOW "::autoupdate::amsn_save $url $token $defaultlocation"
	}

	#When user click on save in another directory, he gets a window to choose the directory
	proc amsn_save_as {url token defaultlocation} {
		set location [tk_chooseDirectory -initialdir $defaultlocation]
		if { $location !="" } {
			::autoupdate::amsn_save $url $token $location
		} else {
			return
		}
	}

	#Define default directory on the three platforms 
	#(It's ok For Mac OS X, change it on your platform if you feel it's not good)
	proc get_default_location {} {
		global env
		if { [OnDarwin] } {
			set namelocation "Desktop"
			set defaultlocation "[file join $env(HOME) Desktop]"
		} elseif { [OnWin] } {
			set namelocation "Received files folder"
			set defaultlocation "[::config::getKey receiveddir]"
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
			#re-check again in a week
			set wait_period [expr {60*60*24*7}]
		} else {
			#just wait one day
			set wait_period [expr {60*60*24*1}]
		}
		set current_time [clock seconds]
		set next_check [expr {$current_time + $wait_period}]
		::config::setGlobalKey next_update_check $next_check
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
			set location [::autoupdate::get_default_location]
			set namelocation [lindex $location 0]
			set defaultlocation [lindex $location 1]
			#Show the button to choose a new file location or use default location
			$w.top.text configure -text [trans savelocationerror]
			$w.bottom.save configure -command "::autoupdate::amsn_save $url $token $defaultlocation" -text [trans savedefaultloc] -default active
			$w.bottom.saveas configure -command "::autoupdate::amsn_save_as $url $token $defaultlocation" -text [trans chooselocation] -default normal
			
			bind $w <<Escape>> "::autoupdate::amsn_save $url $token $defaultlocation"
			bind $w <<Destroy>> "::autoupdate::amsn_save $url $token $defaultlocation"
			wm protocol $w WM_DELETE_WINDOW "::autoupdate::amsn_save $url $token $defaultlocation"
		} else {
			#The saving is a sucess, show a button to open directory of the saved file and close button
			$w.top.text configure -text [trans updatesaved $fname $savedir]
			$w.bottom.save configure -command "launch_filemanager \"$savedir\";destroy $w" -text [trans opendir] -default normal
			$w.bottom.saveas configure -command "destroy $w" -text [trans close] -default active
			#if { [OnLinux] } {
			#	button $w.bottom.install -text "Install" -command "amsn_install_linux $savedir $fname"
			#	pack $w.bottom.install
			#}
			#if { [OnWin] } {
			#	button $w.bottom.install -text "Install" -command "amsn_install_windows $savedir $fname"
			#	pack $w.bottom.install
			#}
			bind $w <<Escape>> "destroy $w"
			bind $w <<Destroy>> "destroy $w"
			wm protocol $w WM_DELETE_WINDOW "destroy $w"
		}
	}

	#///////////////////////////////////////////////////////////////////////
	package require -exact http 2.4.4

	proc check_web_version { token } {
		global version rcversion weburl
		if { ![info exists rcversion] } { set rcversion $version }

		set newer 0

		set tmp_data [ ::http::data $token ]

		if { [::http::status $token] == "ok" && [::http::ncode $token] == 200 } {
			set tmp_data [string map {"\n" "" "\r" ""} $tmp_data]
			set lastver [split $tmp_data "."]
			set yourver [split $rcversion "."]

			for {set x 0} {$x<[llength "$lastver"]} {incr x} {
				if {[lindex $lastver $x] > [lindex $yourver $x]} {
					set newer 1
					break
				} elseif {[lindex $lastver $x] < [lindex $yourver $x]} {
					break
				}
			}

			catch {status_log "check_web_ver: Current= $rcversion New=$tmp_data\n"}
			#Open the update window if newer version
			if { $newer == 1 } {
				::autoupdate::update_window $tmp_data
			} else {
				status_log "No new version\n" red 

				#no new version, so re-check in a week
				set current_time [clock seconds]
				set wait_period [expr {60*60*24*7}]
				set next_check [expr {$current_time + $wait_period}]
				::config::setGlobalKey next_update_check $next_check
			}
		} else {
			catch {status_log "check_web_ver: status=[::http::status $token] ncode=[::http::ncode $token]\n" blue}
			
			#checking for new version failed, so retry in 1 day
			set current_time [clock seconds]
			set wait_period [expr {60*60*24*1}]
			set next_check [expr {$current_time + $wait_period}]
			::config::setGlobalKey next_update_check $next_check
			
			#abort it, don't even try to update the plugins as it seems that the server has an error
			::http::cleanup $token
			return 0
		}
		::http::cleanup $token

		# Auto-update for language files
		if { [::config::getKey activeautoupdate] } {
			set langpluginupdated [::autoupdate::UpdateLangPlugin]
		}

		# Even if langpluginupdated is supposed to exists, prevents a "race" problem
		if { ![info exists langpluginupdated] } {
			return $newer
		} elseif {$newer == 0 && $langpluginupdated == 1} {
			return 1
		} else {
			return $newer
		}
		
	}

	proc check_version {} {
		global weburl

		if { [winfo exists .checking] } {
			raise .checking
			return
		}
		toplevel .checking

		wm title .checking "[trans title]"
		ShowTransient .checking
		canvas .checking.c -width 300 -height 50

		.checking.c create image 25 10 -anchor n -image [::skin::loadPixmap download]
		.checking.c create text 155 20 -font splainf -anchor n \
		    -text "[trans checkingver]..." -justify center -width 250
		pack .checking.c -expand true
		tkwait visibility .checking
		catch {grab .checking}

		update idletasks

		status_log "Getting ${weburl}/amsn_latest\n" blue
		if { [catch {
			set token [::http::geturl ${weburl}/amsn_latest -timeout 5000]
			if {[::autoupdate::check_web_version $token]==0} {
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

		#check if check for new version is necessary
		set next_check [::config::getGlobalKey next_update_check]
		set current_time [clock seconds]
		if {$next_check == "" || $next_check < $current_time} {
			catch {
				::http::geturl ${weburl}/amsn_latest -timeout 10000 -command ::autoupdate::check_web_version
			}
		}
	}


	#///////////////////////////////////////////////////////////////////////
	proc UpdateLangPlugin {} {

		set w ".updatelangplugin"
		if { [winfo exists $w] } {
			raise $w
			return 1
		}

		::lang::UpdatedLang
		set updatedplugins [::plugins::UpdatedPlugins]

		if { ($::lang::UpdatedLang == "") && ($updatedplugins == 0) } {
			::autoupdate::UpdateLangPlugin_close
			return 0
		}



		toplevel $w
		wm title $w "[trans update]"
		#wm geometry $w 320x400
		wm protocol $w WM_DELETE_WINDOW "::autoupdate::UpdateLangPlugin_close"
		
		bind $w <<Escape>> "::autoupdate::UpdateLangPlugin_close"

		frame $w.text
		label $w.text.img -image [::skin::loadPixmap download]
		label $w.text.txt -text [trans newupdate] -font sboldf
		pack configure $w.text.img -side left
		pack configure $w.text.txt -expand true -side right
		pack $w.text -side top -fill x

		ScrolledWindow $w.list -auto vertical -scrollbar vertical
		ScrollableFrame $w.list.sf -constrainedwidth 1
		$w.list setwidget $w.list.sf
		pack $w.list -anchor n -side top -fill both -expand true
		set frame [$w.list.sf getframe]
		

		#Language label
		if {$::lang::UpdatedLang != ""} {
			label $frame.langtext -text "[trans language]" -font sboldf
			pack configure $frame.langtext -side top -fill x -expand true
		}

		#Checkbox for each language
		foreach langcode $::lang::UpdatedLang {
			set langname [::lang::ReadLang $langcode name]
			checkbutton $frame.lang$langcode -onvalue 1 -offvalue 0 -text " $langname" -variable ::autoupdate::lang($langcode) -anchor w
			pack configure $frame.lang$langcode -side top -fill x -expand true
		}

		#Plugin label
		if {$updatedplugins == 1} {
			label $frame.plugintext -text "[trans pluginselector]" -font sboldf
			pack configure $frame.plugintext -side top -fill x
		}

		#Checkbox for each plugin
		foreach plugin [::plugins::getPlugins] {
			if { [::plugins::getInfo $plugin updated] == 1 } {
				checkbutton $frame.plugin$plugin -onvalue 1 -offvalue 0 -text " $plugin" -variable ::plugins::plugins(${plugin}_updated_selected) -anchor w
				pack configure $frame.plugin$plugin -side top -fill x
			}
		}
		
		# Create a frame that will contain the progress of the update
		frame $w.update
		label $w.update.txt -text ""
		pack configure $w.update.txt -fill x
		pack configure $w.update -side top -fill x

		frame $w.button
		button $w.button.selectall -text "[trans selectall]" -command "::autoupdate::UpdateLangPlugin_selectall"
		button $w.button.unselectall -text "[trans unselectall]" -command "::autoupdate::UpdateLangPlugin_unselectall"
		pack configure $w.button.selectall -side left -padx 3 -pady 3
		pack configure $w.button.unselectall -side left -padx 3 -pady 3

		
		frame $w.button2
		button $w.button2.close -text "[trans close]" -command "::autoupdate::UpdateLangPlugin_close"
		button $w.button2.update -text "[trans update]" -command "::autoupdate::UpdateLangPlugin_update" -default active
		pack configure $w.button2.update -side left -padx 3 -pady 3
		pack configure $w.button2.close -side right -padx 3 -pady 3

		pack configure $w.button2 -side bottom -fill x
		pack configure $w.button -side bottom -fill x
		
		return 1

	}


	#///////////////////////////////////////////////////////////////////////
	proc UpdateLangPlugin_update { } {
	
		set w ".updatelangplugin"
	
		pack forget $w.list
		pack forget $w.button
		pack forget $w.button2.update

		wm geometry $w 300x100

		set langcodes [list]

		if { [info exists ::lang::UpdatedLang] && $::lang::UpdatedLang != "" } {
			foreach langcode $::lang::UpdatedLang {
				if { [::autoupdate::ReadLangSelected $langcode] == 1} {
					set langcodes [lappend langcodes $langcode]
				}
			}
			::lang::UpdateLang $langcodes
		}

		foreach plugin [::plugins::getPlugins] {
			if { [::plugins::getInfo $plugin updated] == 1 && [::plugins::getInfo $plugin updated_selected] == 1 } {
				::plugins::UpdatePlugin $plugin
			}
		}
		
		::autoupdate::UpdateLangPlugin_close

	}


	#///////////////////////////////////////////////////////////////////////
	proc UpdateLangPlugin_close { } {
	
		global HOME2
		
		if { [winfo exists ".updatelangplugin"] } {
			destroy ".updatelangplugin"
		}
	
		foreach plugin [::plugins::getPlugins] {
			file delete [file join $HOME2 $plugin.xml]
		}
		
		unset -nocomplain ::lang::UpdatedLang
		
	}


	#///////////////////////////////////////////////////////////////////////
	proc UpdateLangPlugin_selectall { } {
	
		set frame [.updatelangplugin.list.sf getframe]
	
		foreach langcode $::lang::UpdatedLang {
			set ::autoupdate::lang($langcode) 1
		}

		foreach plugin [::plugins::getPlugins] {
			if { [::plugins::getInfo $plugin updated] == 1 } {
				set ::plugins::plugins(${plugin}_updated_selected) 1
			}
		}
		
	}
		

	#///////////////////////////////////////////////////////////////////////
	proc UpdateLangPlugin_unselectall { } {
	
		set frame [.updatelangplugin.list.sf getframe]
	
		foreach langcode $::lang::UpdatedLang {
			set ::autoupdate::lang($langcode) 0
		}

		foreach plugin [::plugins::getPlugins] {
			if { [::plugins::getInfo $plugin updated] == 1 } {
				set ::plugins::plugins(${plugin}_updated_selected) 0
			}
		}
		
	}


	#///////////////////////////////////////////////////////////////////////
	proc ReadLangSelected { langcode } {

		set lang [array get ::autoupdate::lang]
		set id [expr {[lsearch $lang $langcode] + 1}]
		return [lindex $lang $id]

	}
}
