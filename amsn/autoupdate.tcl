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

}
