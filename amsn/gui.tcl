
if { $initialize_amsn == 1 } {
    global bgcolor bgcolor2 putmessage_inputs putmessage_outputs

	 set putmessage_inputs 0
	 set putmessage_outputs 1

    if { ![info exists bgcolor] } {
	set bgcolor #0050C0
    }
    if { ![info exists bgcolor2] } {
	set bgcolor2 #D0D0F0
    }
    
#Virtual events used by Button-click
#On Mac OS X, Control emulate the "right click button"
#On Mac OS X, there's a mistake betwen button2 and button3
if {$tcl_platform(os) == "Darwin"} {
event add <<Button1>> <Button1-ButtonRelease>
event add <<Button2>> <Button3-ButtonRelease>
event add <<Button3>> <Control-ButtonRelease>
event add <<Button3>> <Button2-ButtonRelease>
} else {
event add <<Button1>> <Button1-ButtonRelease>
event add <<Button2>> <Button2-ButtonRelease>
event add <<Button3>> <Button3-ButtonRelease>
}
}

namespace eval ::amsn {

   namespace export initLook aboutWindow showHelpFile errorMsg infoMsg\
   blockUnblockUser blockUser unblockUser deleteUser\
   fileTransferRecv fileTransferProgress\
   errorMsg notifyAdd initLook messageFrom chatChange userJoins\
   userLeaves updateTypers ackMessage nackMessage closeWindow \
   chatStatus chatUser

   ##PUBLIC

   proc initLook { family size bgcolor} {
      global config

      font create menufont -family $family -size $size -weight normal
      font create sboldf -family $family -size $size -weight bold
      font create splainf -family $family -size $size -weight normal

      if { $config(strictfonts) } {
          font create bboldf -family $family -size $size -weight bold
          font create bplainf -family $family -size $size -weight normal
          font create bigfont -family $family -size $size -weight bold
          font create examplef -family $family -size $size -weight normal
      } else {
          font create bboldf -family $family -size [expr {$size+1}] -weight bold
          font create bplainf -family $family -size [expr {$size+1}] -weight normal
          font create bigfont -family $family -size [expr {$size+2}] -weight bold
          font create examplef -family $family -size [expr {$size-2}] -weight normal
      }

      catch {tk_setPalette $bgcolor}
      option add *Menu.font menufont
      option add *background $bgcolor
      option add *selectColor #DD0000

      set Entry {-bg #FFFFFF -foreground #0000FF}
      set Label {-bg #FFFFFF -foreground #000000}
      ::themes::AddClass Amsn Entry $Entry 90
      ::themes::AddClass Amsn Label $Label 90
      ::abookGui::Init
   }

	proc installTLS {} {
		global tcl_platform
		global tlsplatform

		if { $tcl_platform(os) == "Linux" } {
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

		button .tlsdown.f.ok -text "[trans ok]" -command "::amsn::downloadTLS; bind .tlsdown <Destroy> {}; destroy .tlsdown" -font sboldf
		button .tlsdown.f.cancel -text "[trans cancel]" -command "destroy .tlsdown" -font sboldf

		pack .tlsdown.f.cancel -side right -padx 10 -pady 10
		pack .tlsdown.f.ok -side right -padx 10 -pady 10

		pack .tlsdown.linuxx86 -side top -anchor w -padx 15
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
      	} }

		grab .tlsdown
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
			toplevel $w
			wm group $w .
			#wm geometry $w 350x160

			label $w.l -text "[trans downloadingtls $downloadurl]" -font splainf
			pack $w.l -side top -anchor w -padx 10 -pady 10
			pack [::dkfprogress::Progress $w.prbar] -fill x -expand 0 -padx 5 -pady 5 -side top
			label $w.progress -text "[trans receivedbytes 0 ?]" -font splainf

			pack $w.progress -side top -padx 10 -pady 3

			button $w.close -text "[trans cancel]" -command "" -font sboldf
			pack $w.close -side bottom -pady 5 -padx 10

			wm title $w "[trans tlsinstall]"

			::dkfprogress::SetProgress $w.prbar 0

			if {[ catch {set tok [::http::geturl $downloadurl -progress "::amsn::downloadTLSProgress $downloadurl" -command "::amsn::downloadTLSCompleted $downloadurl"]} res ]} {
				errorDownloadingTLS $res $tok
			} else {
				$w.close configure -command "::http::reset $tok"
				wm protocol $w WM_DELETE_WINDOW "::http::reset $tok"
				grab $w
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
			errorDownloadingTLS "Couldn't get $url"
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
						exec gzip -cd [file join $files_dir $fname] | tar xv
					}

					cd $olddir
					::amsn::infoMsg "[trans tlsinstcompleted]"
					} res ] } {

					errorDownloadingTLS $res $token
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
			errorDownloadingTLS "Couldn't get $url" $token
			return
		}
		::dkfprogress::SetProgress .tlsprogress.prbar [expr {$current*100/$total}]
		.tlsprogress.progress configure -text "[trans receivedbytes $current $total]"


	}

	proc errorDownloadingTLS { errormsg token} {
		errorMsg "[trans errortls]: $errormsg"
		catch { destroy .tlsprogress }
		catch {::http::cleanup $token}
	}

   #///////////////////////////////////////////////////////////////////////////////
   # Draws the about window
   proc aboutWindow {} {

      global program_dir tcl_platform

      toplevel .about
      wm title .about "[trans about] [trans title]"
      
   	  ShowTransient .about
    
      wm state .about withdrawn
      
      
#Top frame (Picture and name of developers)
      set developers "\nDidimo Grimaldo\nAlvaro J. Iradier\nKhalaf Philippe\nDave Mifsud"
      frame .about.top -class Amsn
      label .about.top.i -image msndroid
      label .about.top.l -font splainf -text "[trans broughtby]:$developers"
      pack .about.top.i .about.top.l -side left
      pack .about.top

#Middle frame (About text)
	 frame .about.middle
	 frame .about.middle.list -class Amsn -borderwidth 0
     text .about.middle.list.text -background white -width 60 -height 30 -wrap word \
         -yscrollcommand ".about.middle.list.ys set" -font examplef
      scrollbar .about.middle.list.ys -command ".about.middle.list.text yview"
      pack .about.middle.list.ys -side right -fill y
      pack .about.middle.list.text -side left -expand true -fill both
      pack .about.middle.list -side top -expand true -fill both -padx 1 -pady 1
      pack .about.middle -expand true -fill both -side top

#Bottom frame (Close button)
  	  frame .about.bottom -class Amsn
      button .about.bottom.close -text "[trans close]" -font splainf -command "destroy .about"
      pack .about.bottom.close
      pack .about.bottom -side bottom -fill x -pady 3
      
#Insert the text in .about.middle.list.text
      set id [open "[file join $program_dir README]" r]
      .about.middle.list.text insert 1.0 [read $id]
	  close $id
	  
      .about.middle.list.text configure -state disabled
      update idletasks
      wm state .about normal
      set x [expr {([winfo vrootwidth .about] - [winfo width .about]) / 2}]
      set y [expr {([winfo vrootheight .about] - [winfo height .about]) / 2}]
      wm geometry .about +${x}+${y}
      
      #Should we disable resizable? Since when we make the windows smaller (in y), we lost the "Close button"
      #wm resizable .about 0 0

   }
   #///////////////////////////////////////////////////////////////////////////////

   
   #///////////////////////////////////////////////////////////////////////////////
   # showHelpFile(filename,windowsTitle)
   proc showTranslatedHelpFile {file title} {
      global program_dir config
      
      set filename [file join "docs" "${file}$config(language)"]
      set fullfilename [file join $program_dir $filename]
      
      if {[file exists $fullfilename]} { 
         status_log "File $filename exists!!\n" blue
	 showHelpFile $filename "$title"
      } else {
           status_log "File $filename NOT exists!!\n" red
	   msg_box "[trans transnotexists]"
      }
   }   
   
   #///////////////////////////////////////////////////////////////////////////////
   # showHelpFile(filename,windowsTitle)
   proc showHelpFile {file title} {
      global program_dir
      toplevel .show
      wm title .show "$title"
      
    ShowTransient .show
	
	
#Top frame (Help text area)
	  frame .show.info
	  frame .show.info.list -class Amsn -borderwidth 0
	  text .show.info.list.text -background white -width 60 -height 30 -wrap word \
         -yscrollcommand ".show.info.list.ys set" -font   examplef
      scrollbar .show.info.list.ys -command ".show.info.list.text yview"
      pack .show.info.list.ys 	-side right -fill y
      pack .show.info.list.text -expand true -fill both -padx 1 -pady 1
      pack .show.info.list 		-side top -expand true -fill both -padx 1 -pady 1
      pack .show.info 			-expand true -fill both -side top

#Bottom frame (Close button)
      frame .show.bottom -class Amsn
      button .show.bottom.close -text "[trans close]" -font splainf -command "destroy .show"
      pack .show.bottom.close
      pack .show.bottom -expand 1

#Insert FAQ text 
      set id [open "[file join $program_dir $file]" r]
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
   # Shows the error message specified by "msg"
   proc errorMsg { msg } {
		set parent [focus]
		if { $parent == ""} { set parent "."}
      tk_messageBox -type ok -icon error -message $msg -title "[trans title] Error" -parent $parent
   }
   #///////////////////////////////////////////////////////////////////////////////

   #///////////////////////////////////////////////////////////////////////////////
   # Shows the error message specified by "msg"
   proc infoMsg { msg {icon "info"} } {
		set parent [focus]
		if { $parent == ""} { set parent "."}      
		tk_messageBox -type ok -icon $icon -message $msg -title "[trans title]" -parent $parent
   }
   #///////////////////////////////////////////////////////////////////////////////

   #///////////////////////////////////////////////////////////////////////////////
   proc blockUnblockUser { user_login } {
      global list_bl
      if { [::MSN::userIsBlocked $user_login] } {
         unblockUser $user_login
      } else {
         blockUser $user_login
      }
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   proc blockUser {user_login} {
		set parent [focus]
		if { $parent == ""} { set parent "."}

       set answer [tk_messageBox -message "[trans confirm]" -type yesno -icon question -title [trans block] -parent $parent]
       if {$answer == "yes"} {
          set name [::abook::getName ${user_login}]
          ::MSN::blockUser ${user_login} [urlencode $name]
       }
   }
   #///////////////////////////////////////////////////////////////////////////////


   #///////////////////////////////////////////////////////////////////////////////
   proc unblockUser {user_login} {
      set name [::abook::getName ${user_login}]
      ::MSN::unblockUser ${user_login} [urlencode $name]
   }
   #///////////////////////////////////////////////////////////////////////////////   
   
   
   #///////////////////////////////////////////////////////////////////////////////
   proc deleteUser { user_login { grId ""} } {

      global alarms
		set parent [focus]
		if { $parent == ""} { set parent "."}
		
      set answer [tk_messageBox -message "[trans confirmdelete ${user_login}]" -type yesno -icon question -parent $parent]

      if {$answer == "yes"} {

         ::MSN::deleteUser ${user_login} $grId
         if { [info exists alarms($user_login)] } {
            unset alarms($user_login) alarms(${user_login}_sound) alarms(${user_login}_pic) \
               alarms(${user_login}_sound_st) alarms(${user_login}_pic_st) alarms(${user_login}_loop)
         }
      }
   }
   #///////////////////////////////////////////////////////////////////////////////


   #///////////////////////////////////////////////////////////////////////////////
   # FileTransferSend (chatid (filename))
   # Shows the file transfer window, for window win_name
   proc FileTransferSend { win_name {filename ""}} {
      global config

      set w ${win_name}_sendfile
      if { [ winfo exists $w ] } {
         if {$filename == ""} { fileDialog2 $w $w.top.fields.file open "" }\
         else { $w.top.fields.file insert 0 $filename }
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
      checkbutton $w.top.fields.autoip -text "[trans autoip]" -variable config(autoftip)

      pack $w.top.fields.file -side top -anchor w
      pack $w.top.fields.ip $w.top.fields.autoip -side left -anchor w -pady 5
      pack $w.top.labels.file $w.top.labels.ip -side top -anchor e
      pack $w.top.fields -side right -padx 5
      pack $w.top.labels -side left -padx 5
      pack $w.top -side top

      $w.top.fields.ip insert 0 "$config(myip)"

      focus $w.top.fields.file

      if {$filename == ""} { fileDialog2 $w $w.top.fields.file open "" }\
      else { $w.top.fields.file insert 0 $filename }
   }

   #PRIVATE: called by the FileTransferSend Dialog
   proc FileTransferSendOk { w win_name } {
      global config

      set filename [ $w.top.fields.file get ]
      
      if {![file readable $filename]} {
      	msg_box "[trans invalidfile [trans filename] $filename]"
      	return
      }


      if {$config(autoftip) == 0 } {
        set config(myip) [ $w.top.fields.ip get ]
        set ipaddr [ $w.top.fields.ip get ]
        destroy $w

      } else {
        set ipaddr [ $w.top.fields.ip get ]
        destroy $w
		  if { $ipaddr != $config(myip) } {
           set ipaddr [ ::abook::getDemographicField clientip ]
        }
      }

      if { [catch {set filesize [file size $filename]} res]} {
	::amsn::errorMsg "[trans filedoesnotexist]"
	#::amsn::fileTransferProgress c $cookie -1 -1
	return 1
      }

      set chatid [ChatFor $win_name]

      set users [::MSN::usersInChat $chatid]


      foreach chatid $users {

         chatUser $chatid


         #Calculate a random cookie
         set cookie [expr {([clock clicks]) % (65536 * 8)}]

         set txt "[trans ftsendinvitation [lindex [::MSN::getUserInfo $chatid] 1] $filename $filesize]"

         status_log "Random generated cookie: $cookie\n"
         WinWrite $chatid "----------\n" green
         WinWriteIcon $chatid fticon 3 2
         WinWrite $chatid "$txt " green
         WinWriteClickable $chatid "[trans cancel]" \
         "::amsn::CancelFTInvitation $chatid $cookie" ftno$cookie
         WinWrite $chatid "\n" green
         WinWrite $chatid "----------\n" green

         ::MSN::ChatQueue $chatid "::MSNFT::sendFTInvitation $chatid [list $filename] $filesize $ipaddr $cookie"
         #::MSNFT::sendFTInvitation $chatid $filename $filesize $ipaddr $cookie
      }
      
      return 0
   }

   proc CancelFTInvitation { chatid cookie } {
   
      #::MSNFT::acceptFT $chatid $cookie

      set win_name [WindowFor $chatid]
      if { [WindowFor $chatid] == 0} {
         return 0
      }

     ::MSNFT::cancelFTInvitation $chatid $cookie

     ${win_name}.f.out.text tag configure ftno$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.out.text tag bind ftno$cookie <Enter> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Leave> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.out.text conf -cursor left_ptr

     set txt [trans invitationcancelled]

     WinWrite $chatid "----------\n" green
     WinWriteIcon $chatid ftreject 3 2
     WinWrite $chatid " $txt\n" green
     WinWrite $chatid "----------\n" green
     
     

   }   

   proc acceptedFT { chatid who filename } {
      set win_name [WindowFor $chatid]
      if { [WindowFor $chatid] == 0} {
         return 0
      }   
     set txt [trans ftacceptedby $who $filename]
     WinWrite $chatid "----------\n" green
     WinWriteIcon $chatid fticon 3 2
     WinWrite $chatid " $txt\n" green
     WinWrite $chatid "----------\n" green
     
   }   
   
   proc rejectedFT { chatid who filename } {
      set win_name [WindowFor $chatid]
      if { [WindowFor $chatid] == 0} {
         return 0
      }   
     set txt [trans ftrejectedby $who $filename]
     WinWrite $chatid "----------\n" green
     WinWriteIcon $chatid ftreject 3 2
     WinWrite $chatid " $txt\n" green
     WinWrite $chatid "----------\n" green

   }

   #////////////////////////////////////////////////////////////////////////////////
   #  GotFileTransferRequest ( chatid dest branchuid cseq uid sid filename filesize)
   #  This procedure is called when we receive an MSN6 File Transfer Request
   proc GotFileTransferRequest { chatid dest branchuid cseq uid sid filename filesize} {
	global config files_dir
	 
	set win_name [WindowFor $chatid]
 	 
	if { [WindowFor $chatid] == 0} {
		return 0
  	}

	set fromname [lindex [::MSN::getUserInfo $dest] 1]
  	set txt [trans ftgotinvitation $fromname '$filename' $filesize $files_dir]
  	set win_name [MakeWindowFor $chatid $txt $dest]
  	WinWrite $chatid "----------\n" green
  	WinWriteIcon $chatid fticon 3 2
  	WinWrite $chatid $txt green
  	WinWrite $chatid " - (" green
  	WinWriteClickable $chatid "[trans accept]" [list ::amsn::AcceptFT $chatid -1 [list $dest $branchuid $cseq $uid $sid $filename]] ftyes$sid
  	WinWrite $chatid " / " green
  	WinWriteClickable $chatid "[trans reject]" [list ::amsn::RejectFT $chatid -1 [list $sid $branchuid $uid]] ftno$sid
  	WinWrite $chatid ")\n" green
  	WinWrite $chatid "----------\n" green
  	if { ![file writable $files_dir]} {
  		WinWrite $chatid "[trans readonlywarn $files_dir]\n" red
  	        WinWrite "----------\n" green
  	}
  	 
  	if { $config(ftautoaccept) == 1 } {
  		WinWrite $chatid "[trans autoaccepted]\n" green
  	        ::amsn::AcceptFT $chatid -1 [list $dest $branchuid $cseq $uid $sid $filename]
  	}
   }

   #Message shown when receiving a file
   proc fileTransferRecv {filename filesize cookie chatid fromlogin} {
      global files_dir config

      set win_name [WindowFor $chatid]
      if { [WindowFor $chatid] == 0} {
         return 0
      }

      set fromname [lindex [::MSN::getUserInfo $fromlogin] 1]
      set txt [trans ftgotinvitation $fromname '$filename' $filesize $files_dir]

      set win_name [MakeWindowFor $chatid $txt $fromlogin]
      
      
     WinWrite $chatid "----------\n" green
     WinWriteIcon $chatid fticon 3 2
     WinWrite $chatid $txt green
     WinWrite $chatid " - (" green
     WinWriteClickable $chatid "[trans accept]" \
       "::amsn::AcceptFT $chatid $cookie" ftyes$cookie
     WinWrite $chatid " / " green
     WinWriteClickable $chatid "[trans reject]" \
       "::amsn::RejectFT $chatid $cookie" ftno$cookie
     WinWrite $chatid ")\n" green
     WinWrite $chatid "----------\n" green
     if { ![file writable $files_dir]} {
        WinWrite $chatid "[trans readonlywarn $files_dir]\n" red
        WinWrite $chatid "----------\n" green
     }

       if { $config(ftautoaccept) == 1 } {
	   WinWrite $chatid "[trans autoaccepted]\n" green
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
   		::MSNP2P::AcceptFT $chatid [lindex $varlist 0] [lindex $varlist 1] [lindex $varlist 2] [lindex $varlist 3] [lindex $varlist 4] [lindex $varlist 5]
  	       	set cookie [lindex $varlist 4]
      }

      set win_name [WindowFor $chatid]
      if { [WindowFor $chatid] == 0} {
         return 0
      }
      
     ${win_name}.f.out.text tag configure ftyes$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.out.text tag bind ftyes$cookie <Enter> ""
     ${win_name}.f.out.text tag bind ftyes$cookie <Leave> ""
     ${win_name}.f.out.text tag bind ftyes$cookie <Button1-ButtonRelease> ""


     ${win_name}.f.out.text tag configure ftno$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.out.text tag bind ftno$cookie <Enter> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Leave> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.out.text conf -cursor left_ptr

     set txt [trans ftaccepted]

     WinWrite $chatid "----------\n" green
     WinWriteIcon $chatid fticon 3 2
     WinWrite $chatid " $txt\n" green
     WinWrite $chatid "----------\n" green
     

   }

   proc RejectFT {chatid cookie {varlist ""} } {

      if { $cookie != -1 && $cookie != -2 } {
      	::MSNFT::rejectFT $chatid $cookie
      } elseif { $cookie == - 1 } {
  	::MSNP2P::RejectFT $chatid [lindex $varlist 0] [lindex $varlist 1] [lindex $varlist 2]
        set cookie [lindex $varlist 0]
      }	elseif { $cookie == -2 } {
      	set cookie [lindex $varlist 0]
	set txt [trans filetransfercancelled]
      }
   
      set win_name [WindowFor $chatid]
      if { [WindowFor $chatid] == 0} {
         return 0
      }
      
     ${win_name}.f.out.text tag configure ftyes$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.out.text tag bind ftyes$cookie <Enter> ""
     ${win_name}.f.out.text tag bind ftyes$cookie <Leave> ""
     ${win_name}.f.out.text tag bind ftyes$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.out.text tag configure ftno$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.out.text tag bind ftno$cookie <Enter> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Leave> ""
     ${win_name}.f.out.text tag bind ftno$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.out.text conf -cursor left_ptr

     if { [info exists txt] == 0 } {
     	set txt [trans ftrejected]
     }
     
     WinWrite $chatid  "----------\n" green
     WinWriteIcon $chatid ftreject 3 2
     WinWrite $chatid "$txt\n" green
     WinWrite $chatid "----------\n" green

   }


   #PRIVATE: Opens Receiving Window
   proc FTWin {cookie filename user {chatid 0}} {
      global bgcolor
   
     status_log "Creating receive progress window\n"
      
      # Set appropriate Cancel command
      if { [::MSNP2P::SessionList get $cookie] == 0 } {
      	set cancelcmd "::MSNFT::cancelFT $cookie"
      } else {
      	set cancelcmd "::MSNP2P::CancelFT $chatid $cookie"
      }
      
      set w .ft$cookie
      toplevel $w
      wm group $w .
      wm geometry $w 350x160

      #frame $w.f -class amsnChatFrame -background $bgcolor -borderwidth 0 -relief flat
      #set w $ww.f

      label $w.user -text "[trans user]: $user" -font splainf
      pack $w.user -side top -anchor w
      label $w.file -text "[trans filename]: $filename" -font splainf
      pack $w.file -side top -anchor w

      pack [::dkfprogress::Progress $w.prbar] -fill x -expand 0 -padx 5 -pady 5 -side top

      label $w.progress -text "" -font splainf
      label $w.time -text "" -font splainf
      pack $w.progress $w.time -side top


      button $w.close -text "[trans cancel]" -command $cancelcmd -font sboldf
      pack $w.close -side bottom -pady 5

      if { [::MSNFT::getTransferType $cookie] == "received" } {
         wm title $w "$filename - [trans receivefile]"
      } else {
         wm title $w "$filename - [trans sendfile]"
      }
      wm protocol $w WM_DELETE_WINDOW $cancelcmd

       ::dkfprogress::SetProgress $w.prbar 0
   }



	#Updates filetransfer progress window/baar
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
	####
	#
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
			FTWin $cookie [::MSNFT::getFilename $cookie] [::MSNFT::getUsername $cookie] $chatid
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
						"[trans receivedbytes $bytes $filesize] ($rate KB/s)"
				} elseif {$mode == "s"} {
					$w.progress configure -text \
						"[trans sentbytes $bytes $filesize] ($rate KB/s)"
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
			e - l  - ca - fs - fr {
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

	}


   #///////////////////////////////////////////////////////////////////////////////
   # ChatFor (win_name)
   # Returns the name of the chat assigned to window 'win_name'
   proc ChatFor { win_name } {

         variable chat_ids
	 if { [info exists chat_ids($win_name)]} {
	    return $chat_ids($win_name)
	 }

	 return 0
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # WindowFor (chatid)
   # Returns the name of the window that should show the messages and information
   # related to the chat 'chatid'
   proc WindowFor { chatid } {
         variable msg_windows
	  if { [info exists msg_windows($chatid)]} {
	     return $msg_windows($chatid)
	  }
	  return 0
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # SetWindowFor (chatid)
   # Sets the specified window 'win_name' to be the one which will show messages
   # and information for the chat names 'chatid'
   proc SetWindowFor { chatid win_name } {
      variable msg_windows
      variable chat_ids
      set msg_windows($chatid) $win_name
      set chat_ids($win_name) $chatid
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # UnserWindowFor (chatid,win_name)
   # Tells the GUI system that window 'win_name' is no longer available for 'chatid'
   proc UnsetWindowFor {chatid win_name} {
      variable msg_windows
      variable chat_ids
      if {[info exists msg_windows($chatid)]} {
         unset msg_windows($chatid)
         unset chat_ids($win_name)
      }
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # PUBLIC messageFrom(chatid,user,msg,type,[fontformat])
   # Called by the protocol layer when a message 'msg' arrives from the chat
   # 'chatid'.'user' is the login of the message sender, and 'user' can be "msg" to
   # send special messages not prefixed by "XXX says:". 'type' can be a style tag as
   # defined in the OpenChatWindow proc, or just "user". If the type is "user",
   # the 'fontformat' parameter will be used as font format.
   # The procedure will open a window if it does not exists, add a notifyWindow and
   # play a sound if it's necessary
	proc messageFrom { chatid user msg type {fontformat ""} } {
		global remote_auth config
		variable first_message


		#If this is the first message, and no focus on window, then show notify
		#if { $first_message($win_name) == 1 } {

			set maxw [expr {$config(notifwidth)-20}]
			incr maxw [expr 0-[font measure splainf "[trans says [list]]:"]]
			set nickt [trunc [lindex [::MSN::getUserInfo $user] 1] . $maxw splainf]

			#if { ($config(notifymsg) == 1) && ([string first ${win_name} [focus]] != 0)} {
			#	notifyAdd "[trans says $nickt]:\n$msg" "::amsn::chatUser $chatid"
			#}
			set tmsg "[trans says $nickt]:\n$msg"

		#}

		set win_name [MakeWindowFor $chatid $tmsg $user]


		if { $remote_auth == 1 } {

			if { "$user" != "$chatid" } {
				write_remote "To $chatid : $msg" msgsent
			} else {
				write_remote "From $chatid : $msg" msgrcv
			}

		}

		PutMessage $chatid $user $msg $type $fontformat

		set evPar [list $user [lindex [::MSN::getUserInfo $user] 1] $msg]
		if { "$user" != "$chatid" } {
			::plugins::PostEvent chat_msg_sent $evPar
		} else {
			::plugins::PostEvent chat_msg_received $evPar
		}

	}
	#///////////////////////////////////////////////////////////////////////////////


	#Opens a window if it did not existed, and if it's first message it
	#adds msg to notify, and plays sound if enabled
	proc MakeWindowFor { chatid {msg ""} {usr_name ""} } {

		global config
		variable first_message

		set win_name [WindowFor $chatid]

		if { $win_name == 0 } {

			set win_name [OpenChatWindow]
			SetWindowFor $chatid $win_name
			update idletasks
			WinTopUpdate $chatid

			if { $config(showdisplaypic) && $usr_name != ""} {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name]
			} else {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name] nopack
			}

		}


		#If this is the first message, and no focus on window, then show notify
		if { $first_message($win_name) == 1  && $msg!="" } {

			set first_message($win_name) 0

			if { ($config(notifymsg) == 1) && ([string first ${win_name} [focus]] != 0)} {
				notifyAdd "$msg" "::amsn::chatUser $chatid"
			}

			if { $config(newmsgwinstate) == 0 } {
				wm state ${win_name} normal
				wm deiconify ${win_name}
				raise ${win_name}
			} else {
				# Iconify the window unless it was raised by the user already.
				if {[wm state $win_name] != "normal"} {
					wm state ${win_name} iconic
				}
			}

		#If it's not a message event, then it's a window creation (user joins to chat)
		} elseif { $msg == "" } {
			if { $config(newchatwinstate) == 0 } {
				wm state ${win_name} normal
				wm deiconify ${win_name}
				raise ${win_name}
			} else {
				wm state ${win_name} iconic
			}
		}

		#If no focus, and it's a message event, do something to the window
		if { [string first ${win_name} [focus]] != 0 && $msg != ""} {
			play_sound type.wav
		}


		return $win_name
   }

   #///////////////////////////////////////////////////////////////////////////////
   # WinTopUpdate { chatid }
   # Gets the users in 'chatid' from the protocol layer, and updates the top of the
   # window with the user names and states.
   proc WinTopUpdate { chatid } {

      if { [WindowFor $chatid] == 0 } {
         return 0
      }

      variable window_titles
		variable new_message_on
      global list_states config

      #set topmsg ""
      set title ""

      set user_list [::MSN::usersInChat $chatid]

      if {[llength $user_list] == 0} {
         return 0
      }

      set win_name [WindowFor $chatid]

      if { [lindex [${win_name}.f.out.ys get] 1] == 1.0 } {
         set scrolling 1
      } else {
         set scrolling 0
      }


      ${win_name}.f.top.text configure -state normal -font sboldf -height 1 -wrap none
      ${win_name}.f.top.text delete 0.0 end


      foreach user_login $user_list {

         #set user_name [lindex $user_info 1]
	 set user_name [stringmap {"\n" " "} [lindex [::MSN::getUserInfo $user_login] 1]]
	 set user_state_no [lindex [::MSN::getUserInfo $user_login] 2]

	  if { "$user_state_no" == "" } {
	     set user_state_no 0
	  }

	  set user_state [lindex [lindex $list_states $user_state_no] 1]
          set user_image [lindex [lindex $list_states $user_state_no] 4]

      if {$config(truncatenames)} {
	     #Calculate maximum string width
	     set maxw [winfo width ${win_name}.f.top.text]
	     if { "$user_state" != "" && "$user_state" != "online" } {
	        incr maxw [expr 0-[font measure sboldf -displayof ${win_name}.f.top.text " \([trans $user_state]\)"]]
	     }
		  incr maxw [expr 0-[font measure sboldf -displayof ${win_name}.f.top.text " <${user_login}>"]]
		  
	     ${win_name}.f.top.text insert end "[trunc ${user_name} ${win_name} $maxw sboldf] <${user_login}>"
      } else {
	     ${win_name}.f.top.text insert end "${user_name} <${user_login}>"
      }
     set title "${title}${user_name}, "

			  
	  #TODO: When we have better, smaller and transparent images, uncomment this
	  #${win_name}.f.top.text image create end -image $user_image -pady 0 -padx 2

 	  #set topmsg "${topmsg}${user_name} <${user_login}> "
	  #${win_name}.f.top.text insert end "${user_name} <${user_login}>"

	  if { "$user_state" != "" && "$user_state" != "online" } {
            #set topmsg "${topmsg} \([trans $user_state]\) "
	    ${win_name}.f.top.text insert end " \([trans $user_state]\)"
	  }
	  ${win_name}.f.top.text insert end "\n"
	  #set topmsg "${topmsg}\n"

      }

      set title [string replace $title end-1 end " - [trans chat]"]
      #set topmsg [string replace $topmsg end-1 end]
      
      #set win_name [WindowFor $chatid]

      #${win_name}.f.top.text configure -state normal -font sboldf -height 1 -wrap none
      #${win_name}.f.top.text delete 0.0 end
      #${win_name}.f.top.text insert end $topmsg
      
      #Calculate number of lines, and set top text size
      set size [${win_name}.f.top.text index end]
      set posyx [split $size "."]
      set lines [expr {[lindex $posyx 0] - 2}]
      
      ${win_name}.f.top.text delete [expr {$size - 1.0}] end
            
      ${win_name}.f.top.text configure -state normal -font sboldf -height $lines -wrap none

      ${win_name}.f.top.text configure -state disabled

      set window_titles(${win_name}) ${title}
		if { [info exists new_message_on(${win_name})] && $new_message_on(${win_name}) == 1 } {
			wm title ${win_name} "*${title}"
		} else {
			wm title ${win_name} ${title}
		}

      update idletasks
      if { $scrolling } { ${win_name}.f.out.text yview moveto 1.0 }

      after cancel "::amsn::WinTopUpdate $chatid"
      after 5000 "::amsn::WinTopUpdate $chatid"

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # chatChange (chatid, newchatid)
   # this is called from the protocol layer when a private chat changes into a
   # conference, right after a JOI command comes from the SB. It mean that the window
   # assigned to $chatid should now be related to $newchatid. chatChange will return
   # the new chatid if the change is OK (no other window for that name exists), or the
   # old chatid if the change is not right
   # - 'chatid' is the name of the chat that was a single private before
   # - 'newchatid' is the new id of the chat for the conference
   proc chatChange { chatid newchatid } {

      set win_name [WindowFor $chatid]

      if { $win_name == 0 } {

          #Old window window does not exists, so just accept the change, no worries
	  status_log "chatChange: Window doesn't exist (probably invited to a conference)\n"
	  return $newchatid

      }

      if { [WindowFor $newchatid] != 0} {
         #Old window existed, probably a conference, but new one exists too, so we can't
	 #just allow that messages shown in old window now are shown in a different window,
	 #that wouldn't be nice, so don't allow change
         status_log "conference wants to become private, but there's already a window\n"
	 return $chatid
      }
      
      #So, we had an old window for chatid, but no window for newchatid, so the window will
      #change it's assigned chat

      UnsetWindowFor $chatid $win_name
      SetWindowFor $newchatid $win_name

      status_log "chatChange: changing $chatid into $newchatid\n"

      return $newchatid

   }
   #///////////////////////////////////////////////////////////////////////////////



	#///////////////////////////////////////////////////////////////////////////////
	# userJoins (charid, user_login)
	# called from the protocol layer when a user JOINS a chat
	# It should be called after a JOI in the switchboard.
	# If a window exists, it will show "user joins conversation" in the status bar
	# - 'chatid' is the chat name
	# - 'usr_login' is the user that joins email
	proc userJoins { chatid usr_name } {

		global config

		set win_name [WindowFor $chatid]
		if { $win_name == 0 && $config(newchatwinstate)!=2 } {
			set win_name [MakeWindowFor $chatid "" $usr_name]
		}

		if { $win_name != 0 } {

			set statusmsg "[timestamp] [trans joins [lindex [::MSN::getUserInfo $usr_name] 1]]\n"
			WinStatus [ WindowFor $chatid ] $statusmsg minijoins
			WinTopUpdate $chatid

			if { $config(showdisplaypic) && $usr_name != ""} {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name]
			} else {
				::amsn::ChangePicture $win_name user_pic_$usr_name [trans showuserpic $usr_name] nopack
			}

			::amsn::WinWriteIcon $chatid minijoins 5 0
 			::amsn::WinWrite $chatid " [trans joins [lindex [::MSN::getUserInfo $usr_name] 1]]\n" green "" 0
#			set statusmsg2 "[timestamp] [trans joins $usr_name]\n"
#			${win_name}.f.out.text insert end "$statusmsg2" red

		}

		if { $config(keep_logs) } {
			::log::JoinsConf $chatid $usr_name
		}

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

      global config automsgsent

		set win_name [WindowFor $chatid]
      if { $win_name == 0} {
         return 0
      }

      set username [lindex [::MSN::getUserInfo $usr_name] 1]

      if { $closed } {
	  set statusmsg "[timestamp] [trans leaves $username]\n"
	  set icon minileaves
			::amsn::WinWriteIcon $chatid minileaves 5 0
		::amsn::WinWrite $chatid " [trans leaves $username]\n" green "" 0


      } else {
	  set statusmsg "[timestamp] [trans closed $username]\n"
	  set icon minileaves
      }
      WinStatus [ WindowFor $chatid ] $statusmsg $icon
      WinTopUpdate $chatid

	if { $config(keep_logs) } {
		::log::LeavesConf $chatid $usr_name
	}

	# Unset automsg if he leaves so that it sends again on next msg
	if { [info exists automsgsent($usr_name)] } {
		unset automsgsent($usr_name)
	}

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # updateTypers (chatid)
   # Called from the protocol.
   # Asks the protocol layer to get a list of typing users in the chat, and shows
   # a message in the status bar.
   # - 'chatid' is the name of the chat
   proc updateTypers { chatid } {
      global config


      if {[WindowFor $chatid] == 0} {
         return 0
      }

      set typers_list [::MSN::typersInChat $chatid]

      set typingusers ""

      foreach login $typers_list {
         set user_name [lindex [::MSN::getUserInfo $login] 1]
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

      WinStatus [WindowFor $chatid] $statusmsg $icon

   }
   #///////////////////////////////////////////////////////////////////////////////


	  if { $initialize_amsn == 1 } {

	      #///////////////////////////////////////////////////////////////////////////////
	      # Auto incremented variable to name the windows
	      variable winid 0
	      #///////////////////////////////////////////////////////////////////////////////
	      variable clipboard ""
	  }


   #///////////////////////////////////////////////////////////////////////////////
   # OpenChatWindow ()
   # Opens a new hidden chat window and returns its name.
   proc OpenChatWindow {} {

      variable winid
      variable window_titles
      variable first_message
      global  config HOME files_dir bgcolor bgcolor2 tcl_platform xmms

      set win_name "msg_$winid"
      incr winid

      toplevel .${win_name} -class Amsn

		if {[catch { wm geometry .${win_name} [::config::getKey winchatsize] } res]} {
			wm geometry .${win_name} 350x390
			::config::setKey winchatsize 350x390
			status_log "No config(winchatsize). Setting default size for chat window\n" red
		}
      #wm state .${win_name} withdrawn
      wm state .${win_name} iconic
      wm title .${win_name} "[trans chat]"
      wm group .${win_name} .
      wm iconbitmap .${win_name} @[GetSkinFile pixmaps amsn.xbm]
      wm iconmask .${win_name} @[GetSkinFile pixmaps amsnmask.xbm]

 
#Test on Mac OS X(Darwin) if imagemagick is installed and kill all sndplay processes      
if {$tcl_platform(os) == "Darwin"} {
if { $config(getdisppic) != 0 } {
	check_imagemagick
}
catch {exec killall -c sndplay}
}
      menu .${win_name}.menu -tearoff 0 -type menubar  \
         -borderwidth 0 -activeborderwidth -0
         
         if {$tcl_platform(os) != "Darwin"} {
         .${win_name}.menu add cascade -label "[trans msn]" -menu .${win_name}.menu.msn
} else {
		.${win_name}.menu add cascade -label "[trans file]" -menu .${win_name}.menu.msn
}
      
      .${win_name}.menu add cascade -label "[trans edit]" -menu .${win_name}.menu.edit
      .${win_name}.menu add cascade -label "[trans view]" -menu .${win_name}.menu.view
      .${win_name}.menu add cascade -label "[trans actions]" -menu .${win_name}.menu.actions

	#Apple menu, only on Mac OS X
	if {$tcl_platform(os) == "Darwin"} {
   	.${win_name}.menu add cascade -label "Apple" -menu .${win_name}.menu.apple
	menu .${win_name}.menu.apple -tearoff 0 -type normal
	.${win_name}.menu.apple add command -label "[trans about] aMSN" -command ::amsn::aboutWindow
	.${win_name}.menu.apple add separator
	.${win_name}.menu.apple add command -label "[trans preferences]..." -command Preferences -accelerator "Command-,"
	.${win_name}.menu.apple add separator
	
	}
	
      menu .${win_name}.menu.msn -tearoff 0 -type normal
      .${win_name}.menu.msn add command -label "[trans savetofile]..." \
         -command " ChooseFilename .${win_name}.f.out.text ${win_name} "
      .${win_name}.menu.msn add separator
      .${win_name}.menu.msn add command -label "[trans sendfile]..." \
         -command "::amsn::FileTransferSend .${win_name}"
      .${win_name}.menu.msn add command -label "[trans openreceived]..." \
         -command "launch_filemanager \"$files_dir\""
      .${win_name}.menu.msn add separator
      #Add accelerator label to "close" on Mac Version
      if {$tcl_platform(os) == "Darwin"} {
      .${win_name}.menu.msn add command -label "[trans close]" \
         -command "destroy .${win_name}" -accelerator "Command-W"
         } else {
         .${win_name}.menu.msn add command -label "[trans close]" \
         -command "destroy .${win_name}"
         }

	menu .${win_name}.menu.edit -tearoff 0 -type normal
#Change the accelerator on Mac OS X
	if {$tcl_platform(os) == "Darwin"} {
      .${win_name}.menu.edit add command -label "[trans cut]" -command "tk_textCut .${win_name}" -accelerator "Command+X"
      .${win_name}.menu.edit add command -label "[trans copy]" -command "tk_textCopy .${win_name}" -accelerator "Command+C"
      .${win_name}.menu.edit add command -label "[trans paste]" -command "tk_textPaste .${win_name}" -accelerator "Command+V"
	} else {
      .${win_name}.menu.edit add command -label "[trans cut]" -command "tk_textCut .${win_name}" -accelerator "Ctrl+X"
      .${win_name}.menu.edit add command -label "[trans copy]" -command "tk_textCopy .${win_name}" -accelerator "Ctrl+C"
      .${win_name}.menu.edit add command -label "[trans paste]" -command "tk_textPaste .${win_name}" -accelerator "Ctrl+V"
      }

      menu .${win_name}.menutextsize -tearoff 0 -type normal
      .${win_name}.menutextsize add command -label "+8" -command "change_myfontsize 8 ${win_name}"
      .${win_name}.menutextsize add command -label "+6" -command "change_myfontsize 6 ${win_name}"
      .${win_name}.menutextsize add command -label "+4" -command "change_myfontsize 4 ${win_name}"
      .${win_name}.menutextsize add command -label "+2" -command "change_myfontsize 2 ${win_name}"
      .${win_name}.menutextsize add command -label "+1" -command "change_myfontsize 1 ${win_name}"
      .${win_name}.menutextsize add command -label "+0" -command "change_myfontsize 0 ${win_name}"
      .${win_name}.menutextsize add command -label "-1" -command "change_myfontsize -1 ${win_name}"
      .${win_name}.menutextsize add command -label "-2" -command "change_myfontsize -2 ${win_name}"

      menu .${win_name}.menu.view -tearoff 0 -type normal
      .${win_name}.menu.view add cascade -label "[trans textsize]" \
         -menu .${win_name}.menutextsize
      .${win_name}.menu.view add separator
      .${win_name}.menu.view add checkbutton -label "[trans chatsmileys]" \
        -onvalue 1 -offvalue 0 -variable config(chatsmileys)
		  global .${win_name}_show_picture
		  set .${win_name}_show_picture 0
		  	.${win_name}.menu.view add checkbutton -label "[trans showdisplaypic]" -command "::amsn::ShowOrHidePicture .${win_name}" -onvalue 1 -offvalue 0 -variable ".${win_name}_show_picture"
      .${win_name}.menu.view add separator

      #Remove this menu item on Mac OS X because we "lost" the window instead of just hide it and change accelerator for history on mac os x
      if {$tcl_platform(os) == "Darwin"} {
       .${win_name}.menu.view add command -label "[trans history]" -command "::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin" -accelerator "Command-Option-H"
		} else {
      .${win_name}.menu.view add command -label "[trans history]" -command "::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin" -accelerator "Ctrl+H"
	  .${win_name}.menu.view add separator
      .${win_name}.menu.view add command -label "[trans hidewindow]" -command "wm state .${win_name} withdraw"
		}
		
      menu .${win_name}.menu.actions -tearoff 0 -type normal
      .${win_name}.menu.actions add command -label "[trans addtocontacts]" \
         -command "::amsn::ShowAddList \"[trans addtocontacts]\" .${win_name} ::MSN::addUser"
      .${win_name}.menu.actions add command -label "[trans block]/[trans unblock]" \
         -command "::amsn::ShowChatList \"[trans block]/[trans unblock]\" .${win_name} ::amsn::blockUnblockUser"
      .${win_name}.menu.actions add command -label "[trans viewprofile]" \
         -command "::amsn::ShowChatList \"[trans viewprofile]\" .${win_name} ::hotmail::viewProfile"
      .${win_name}.menu.actions add command -label "[trans properties]" \
         -command "::amsn::ShowChatList \"[trans properties]\" .${win_name} ::abookGui::showEntry"
      .${win_name}.menu.actions add separator
      .${win_name}.menu.actions add command -label "[trans invite]..." -command "::amsn::ShowInviteList \"[trans invite]\" .${win_name}"
      .${win_name}.menu.actions add separator
      .${win_name}.menu.actions add command -label [trans sendmail] \
          -command "::amsn::ShowChatList \"[trans sendmail]\" .${win_name} launch_mailer"
      .${win_name} conf -menu .${win_name}.menu

      menu .${win_name}.copypaste -tearoff 0 -type normal
      .${win_name}.copypaste add command -label [trans cut] -command "status_log cut\n;tk_textCut .${win_name}"
      .${win_name}.copypaste add command -label [trans copy] -command "status_log copy\n;tk_textCopy .${win_name}"
      .${win_name}.copypaste add command -label [trans paste] -command "status_log paste\n;tk_textPaste .${win_name}"

      menu .${win_name}.copy -tearoff 0 -type normal
      .${win_name}.copy add command -label [trans copy] -command "status_log copy\n;copy 0 .${win_name}"

      if {[info exist xmms(loaded)]} {
       .${win_name}.copy add cascade -label "XMMS" -menu .${win_name}.copy.xmms

       menu .${win_name}.copy.xmms -tearoff 0 -type normal
       .${win_name}.copy.xmms add command -label [trans xmmscurrent] -command "xmms ${win_name} 1"
       .${win_name}.copy.xmms add command -label [trans xmmssend] -command "xmms ${win_name} 2"
      }

      frame .${win_name}.f -class amsnChatFrame -background $bgcolor -borderwidth 0 -relief flat

      frame .${win_name}.f.out -class Amsn -background white -borderwidth 0 -relief flat

      text .${win_name}.f.out.text -borderwidth 3 -foreground white -background white -width 45 -height 5 -wrap word \
	  -yscrollcommand "adjust_yscroll .${win_name}.f.out.text .${win_name}.f.out.ys" -exportselection 1  \
	  -relief flat -highlightthickness 0 \
	  -selectborderwidth 1


      frame .${win_name}.f.top -class Amsn -relief flat -borderwidth 0 -background $bgcolor


      text .${win_name}.f.top.textto  -borderwidth 0 -width [string length "[trans to]:"] -relief solid \
         -height 1 -wrap none -background $bgcolor -foreground $bgcolor2 -highlightthickness 0 \
	  -selectbackground $bgcolor -selectforeground $bgcolor2 -selectborderwidth 0 -exportselection 0
      .${win_name}.f.top.textto configure -state normal -font bplainf
      .${win_name}.f.top.textto insert end "[trans to]:"
      .${win_name}.f.top.textto configure -state disabled

      text .${win_name}.f.top.text  -borderwidth 0 -width 45 -relief flat \
         -height 1 -wrap none -background $bgcolor -foreground $bgcolor2 -highlightthickness 0 \
	  -selectbackground $bgcolor -selectborderwidth 0 -selectforeground $bgcolor2 -exportselection 1

#-yscrollcommand ".${win_name}.f.top.ys set"



		frame .${win_name}.f.bottom -class Amsn -borderwidth 0 -relief solid -background $bgcolor
		set bottom .${win_name}.f.bottom

		frame $bottom.buttons -class Amsn -borderwidth 0 -relief solid -background $bgcolor2


      frame $bottom.in -class Amsn -background white -relief solid -borderwidth 0

      text $bottom.in.input -background white -width 15 -height 3 -wrap word\
         -font bboldf -borderwidth 0 -relief solid -highlightthickness 0 -exportselection 1
	#Send button in conversation window, specifications and command
      frame $bottom.in.f -class Amsn -borderwidth 0 -relief solid -background white
      button $bottom.in.f.send  -text [trans send] -width 6 -borderwidth 1 -relief solid \
         -command "::amsn::MessageSend .${win_name} $bottom.in.input" -font bplainf -highlightthickness 0



		load_my_pic

		label $bottom.pic  -borderwidth 1 -relief solid -image no_pic -background #FFFFFF
		set_balloon $bottom.pic [trans nopic]
		button $bottom.showpic -bd 0 -padx 0 -pady 0 -image imgshow -bg $bgcolor -highlightthickness 0 \
			-command "::amsn::ToggleShowPicture ${win_name}; ::amsn::ShowOrHidePicture .${win_name}" -font splainf
		set_balloon $bottom.showpic [trans showdisplaypic]
		grid $bottom.showpic -row 0 -column 2 -padx 0 -pady 3 -rowspan 2 -sticky ns
		grid columnconfigure $bottom 3 -minsize 3

		bind $bottom.pic <Button1-ButtonRelease> "::amsn::ShowPicMenu .${win_name} %X %Y\n"
		bind $bottom.pic <<Button3>> "::amsn::ShowPicMenu .${win_name} %X %Y\n"


		#scrollbar .${win_name}.f.top.ys -command ".${win_name}.f.top.text yview"

      scrollbar .${win_name}.f.out.ys -command ".${win_name}.f.out.text yview" \
         -highlightthickness 0 -borderwidth 1 -elementborderwidth 1 

      text .${win_name}.status  -width 30 -height 1 -wrap none\
         -font bplainf -borderwidth 1



      button $bottom.buttons.smileys  -image butsmile -relief flat -padx 5 -background $bgcolor2 -highlightthickness 0
		set_balloon $bottom.buttons.smileys [trans insertsmiley]      
		button $bottom.buttons.fontsel -image butfont -relief flat -padx 5 -background $bgcolor2 -highlightthickness 0
		set_balloon $bottom.buttons.fontsel [trans changefont]
      button $bottom.buttons.block -image butblock -relief flat -padx 5 -background $bgcolor2 -highlightthickness 0
		set_balloon $bottom.buttons.block [trans block]
      button $bottom.buttons.sendfile -image butsend -relief flat -padx 3 -background $bgcolor2 -highlightthickness 0
		set_balloon $bottom.buttons.sendfile [trans sendfile]
      button $bottom.buttons.invite -image butinvite -relief flat -padx 3 -background $bgcolor2 -highlightthickness 0
      set_balloon $bottom.buttons.invite [trans invite]
		pack $bottom.buttons.fontsel $bottom.buttons.smileys -side left
      pack $bottom.buttons.block $bottom.buttons.sendfile $bottom.buttons.invite -side right

      pack .${win_name}.f.top -side top -fill x -padx 3 -pady 0
      pack .${win_name}.status -side bottom -fill x

		#pack $bottom.in -side bottom -fill x -pady 3 -padx 3
      #pack $bottom.buttons -side bottom -fill x -padx 3 -pady 0
		#pack $bottom.pic -side left -padx 2 -pady 2
		grid $bottom.in -row 1 -column 0 -padx 3 -pady 3 -sticky nsew
		grid $bottom.buttons -row 0 -column 0 -padx 3 -pady 0 -sticky ewns
		grid column $bottom 0 -weight 1

		pack .${win_name}.f.out -expand true -fill both -padx 3 -pady 0
      pack .${win_name}.f.out.text -side right -expand true -fill both -padx 2 -pady 2
      pack .${win_name}.f.out.ys -side right -fill y -padx 0

      pack .${win_name}.f.top.textto -side left -fill y -anchor nw -padx 0 -pady 3
      pack .${win_name}.f.top.text -side left -expand true -fill x -padx 4 -pady 3

		pack .${win_name}.f.bottom -side top -expand false -fill x -padx 0 -pady 0

      pack $bottom.in.f.send -fill both -expand true
      pack $bottom.in.input -side left -expand true -fill both -padx 1 -pady 1
      pack $bottom.in.f -side left -fill y -padx 3 -pady 4

      pack .${win_name}.f -expand true -fill both -padx 0 -pady 0

      .${win_name}.f.top.text configure -state disabled
      .${win_name}.f.out.text configure -state disabled
      .${win_name}.status configure -state disabled
      $bottom.in.f.send configure -state disabled
      $bottom.in.input configure -state normal


      .${win_name}.f.out.text tag configure green -foreground darkgreen -background white -font sboldf
      .${win_name}.f.out.text tag configure red -foreground red -background white -font sboldf
      .${win_name}.f.out.text tag configure blue -foreground blue -background white -font sboldf
      .${win_name}.f.out.text tag configure gray -foreground #404040 -background white -font splainf
      .${win_name}.f.out.text tag configure white -foreground white -background black -font sboldf
      .${win_name}.f.out.text tag configure url -foreground #000080 -background white -font splainf -underline true


      #bind .${win_name}.f.out.text <Configure> "adjust_yscroll .${win_name}.f.out.text .${win_name}.f.out.ys 0 1"

      bind $bottom.in.input <Tab> "focus $bottom.in.f.send; break"

      bind  $bottom.buttons.smileys  <Button1-ButtonRelease> "smile_menu %X %Y $bottom.in.input"
      bind  $bottom.buttons.fontsel  <Button1-ButtonRelease> "change_myfont ${win_name}"
      bind  $bottom.buttons.block  <Button1-ButtonRelease> "::amsn::ShowChatList \"[trans block]/[trans unblock]\" .${win_name} ::amsn::blockUnblockUser"
      bind $bottom.buttons.sendfile <Button1-ButtonRelease> "::amsn::FileTransferSend .${win_name}"
      bind $bottom.buttons.invite <Button1-ButtonRelease> "::amsn::ShowInviteList \"[trans invite]\" .${win_name}"


      bind $bottom.in.f.send <Return> \
         "::amsn::MessageSend .${win_name} $bottom.in.input; break"
      bind $bottom.in.input <Shift-Return> {%W insert insert "\n"; %W see insert; break}
      bind $bottom.in.input <Control-KP_Enter> {%W insert insert "\n"; %W see insert; break}
      bind $bottom.in.input <Shift-KP_Enter> {%W insert insert "\n"; %W see insert; break}
      #Change shorcuts on Mac OS X and ALT=Option on Mac
      if {$tcl_platform(os) == "Darwin"} {
      bind $bottom.in.input <Command-Return> {%W insert insert "\n"; %W see insert; break}
      bind $bottom.in.input <Command-Option-space> BossMode
      } else {
      bind $bottom.in.input <Control-Return> {%W insert insert "\n"; %W see insert; break}
      bind $bottom.in.input <Control-Alt-space> BossMode
      }

      bind $bottom.in.input <<Button3>> "tk_popup .${win_name}.copypaste %X %Y"
      bind $bottom.in.input <<Button2>> "paste .${win_name} 1"
      bind .${win_name}.f.out.text <<Button3>> "tk_popup .${win_name}.copy %X %Y"
      bind .${win_name}.f.out.text <Button1-ButtonRelease> "copy 0 .${win_name}"
      
		#Define this events, in case they were not defined by Tk
		event add <<Paste>> <Control-v> <Control-V>
		event add <<Copy>> <Control-c> <Control-C>
		event add <<Cut>> <Control-x> <Control-X>
		 
	  bind .${win_name} <<Cut>> "status_log cut\n;tk_textCut .${win_name}"
	  bind .${win_name} <<Copy>> "status_log copy\n;tk_textCopy .${win_name}"
	  bind .${win_name} <<Paste>> "status_log paste\n;tk_textPaste .${win_name}"

      #Change shorcut for history on Mac OS X
      if {$tcl_platform(os) == "Darwin"} {
		bind .${win_name} <Command-Option-h> "::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin"
      } else {
		bind .${win_name} <Control-h> "::amsn::ShowChatList \"[trans history]\" .${win_name} ::log::OpenLogWin"
      }
      

      bind .${win_name} <Destroy> "window_history clear %W; ::amsn::closeWindow .${win_name} %W"

      focus $bottom.in.input

      change_myfontsize $config(textsize) ${win_name}



      #TODO: We always want these menus and bindings enabled? Think it!!
      $bottom.in.input configure -state normal
      $bottom.in.f.send configure -state normal

      .${win_name}.menu.msn entryconfigure 3 -state normal
      .${win_name}.menu.actions entryconfigure 5 -state normal

		#Better binding, works for tk 8.4 only (see proc  tification too)
		if { [catch {
		   $bottom.input edit modified false
		   bind $bottom.in.input <<Modified>> "::amsn::TypingNotification .${win_name} $bottom.in.input"
			} res]} {
			#If fails, fall back to 8.3
         bind $bottom.in.input <Key> "::amsn::TypingNotification .${win_name} $bottom.in.input"
		   bind $bottom.in.input <Key-Meta_L> "break;"
         bind $bottom.in.input <Key-Meta_R> "break;"
         bind $bottom.in.input <Key-Alt_L> "break;"
         bind $bottom.in.input <Key-Alt_R> "break;"
         bind $bottom.in.input <Key-Control_L> "break;"
         bind $bottom.in.input <Key-Control_R> "break;"
		}

		bind $bottom.in.input <Return> "window_history add %W; ::amsn::MessageSend .${win_name} %W; break"
		bind $bottom.in.input <Key-KP_Enter> "window_history add %W; ::amsn::MessageSend .${win_name} %W; break"
		
		
		#Differents shorcuts on Mac OS X
		if {$tcl_platform(os) == "Darwin"} {
		bind $bottom.in.input <Control-s> "window_history add %W; ::amsn::MessageSend .${win_name} %W; break"
		bind .${win_name} <Command-w> "destroy .${win_name} %W; break"
		bind .${win_name} <Command-,> "Preferences"
		bind all <Command-q> {
	 	close_cleanup;exit
	 	}
	 	bind $bottom.in.input <Command-Up> "window_history previous %W; break"
		bind $bottom.in.input <Command-Down> "window_history next %W; break"
		} else {
		bind $bottom.in.input <Alt-s> "window_history add %W; ::amsn::MessageSend .${win_name} %W; break"
		bind $bottom.in.input <Escape> "destroy .${win_name} %W; break"
		bind $bottom.in.input <Control-Up> "window_history previous %W; break"
		bind $bottom.in.input <Control-Down> "window_history next %W; break"
		}

		set window_titles(.${win_name}) ""
		set first_message(.${win_name}) 1

		bind .${win_name} <Configure> "::amsn::ConfiguredChatWin .${win_name}"


		wm state .${win_name} withdraw

		return ".${win_name}"
	}

	proc ConfiguredChatWin {win} {
		set chatid [ChatFor $win]
		if { $chatid != 0 } {
			after cancel "::amsn::WinTopUpdate $chatid"
			after 200 "::amsn::WinTopUpdate $chatid"

		}
      set geom [wm geometry $win]
      set pos_start [string first "+" $geom]

		if { [::config::getKey savechatwinsize] } {
      	::config::setKey winchatsize  [string range $geom 0 [expr {$pos_start-1}]]
		}
      #status_log "$config(winchatsize)\n"

	}


	proc ToggleShowPicture { win_name } {
		upvar #0 .${win_name}_show_picture show_pic

		status_log "show pic is $show_pic\n" white

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
		if {$tcl_platform(os) == "Darwin"} {
			set x [expr $x -50]
			set y [expr $y - 115]
		}

		set chatid [::amsn::ChatFor $win]
		set users [::MSN::usersInChat $chatid]

		$win.picmenu add command -label "[trans showmypic]" \
         -command [list ::amsn::ChangePicture $win my_pic [trans mypic]]
		foreach user $users {
			$win.picmenu add command -label "[trans showuserpic $user]" \
   	      -command [list ::amsn::ChangePicture $win user_pic_$user [trans showuserpic $user]]

		}
		$win.picmenu add separator
		$win.picmenu add command -label "[trans changedisplaypic]..." -command pictureBrowser

		tk_popup $win.picmenu $x $y


	}

	proc ChangePicture {win picture balloontext {nopack ""}} {
		global config
		#pack $win.bottom.pic -side left -padx 2 -pady 2
		upvar #0 ${win}_show_picture show_pic

		if { $balloontext != "" } {
			#unset_balloon $win.f.bottom.pic
			change_balloon $win.f.bottom.pic $balloontext
		}
		if { [catch {$win.f.bottom.pic configure -image $picture}] } {
			status_log "Failed to set picture, using no_pic\n" red
			$win.f.bottom.pic configure -image no_pic
			#unset_balloon $win.f.bottom.pic
			change_balloon $win.f.bottom.pic [trans nopic]
		} elseif { $nopack == "" } {
			grid $win.f.bottom.pic -row 0 -column 1 -padx 0 -pady 3 -rowspan 2
			#grid forget $win.f.bottom.showpic
			$win.f.bottom.showpic configure -image imghide
			#unset_balloon $win.f.bottom.showpic
			change_balloon $win.f.bottom.showpic [trans hidedisplaypic]
			set show_pic 1
		}
	}

	proc HidePicture { win } {
		global ${win}_show_picture
		grid forget $win.f.bottom.pic

		#grid $win.f.bottom.showpic -row 0 -column 1 -padx 0 -pady 0 -rowspan 2
		#Change here to change the icon, instead of text
		$win.f.bottom.showpic configure -image imgshow
		set_balloon $win.f.bottom.showpic [trans showdisplaypic]

		set ${win}_show_picture 0

	}

	proc ShowOrHidePicture { win } {
		upvar #0 ${win}_show_picture value
		if { $value == 1} {
			::amsn::ChangePicture $win [$win.f.bottom.pic cget -image] ""
		} else {
			::amsn::HidePicture $win
		}

	}


	#///////////////////////////////////////////////////////////////////////////////


   proc ShowAddList {title win_name command} {
      global list_users

      set userlist [list]
      set chatusers [::MSN::usersInChat [ChatFor $win_name]]

      foreach user_login $chatusers {
         set user_state_no [lindex [::MSN::getUserInfo $user_login] 2]

	 if {([lsearch $list_users "$user_login *"] == -1)} {
	     set user_name [lindex [::MSN::getUserInfo $user_login] 1]
	     lappend userlist [list $user_login $user_name $user_state_no]
         }
      }

      if { [llength $userlist] > 0 } {
   	   ChooseList $title both $command 1 1 $userlist
      } else {
   	   msg_box "[trans useralreadyonlist]"
      }
   }


   proc ShowInviteList { title win_name } {
	global list_users


	#if {![::MSN::chatReady [ChatFor $win_name]]} {
	#   return 0
	#}

	set userlist [list]
	set chatusers [::MSN::usersInChat [ChatFor $win_name]]

	foreach user_info $list_users {
	        set user_login [lindex $user_info 0]
		set user_state_no [lindex [::MSN::getUserInfo $user_login] 2]
      		if {($user_state_no < 7) && ([lsearch $chatusers "$user_login"] == -1)} {
          		set user_name [lindex [::MSN::getUserInfo $user_login] 1]
	  		lappend userlist [list $user_login $user_name $user_state_no]
      		}
   	}
	
	set chatid [ChatFor $win_name]

	if { [llength $userlist] > 0 } {
   		#ChooseList $title both "::MSN::inviteUser [ChatFor $win_name]" 1 0 $userlist
		ChooseList $title both "::amsn::queueinviteUser [ChatFor $win_name]" 1 0 $userlist
  	} else {	        
		#cmsn_draw_otherwindow $title "::MSN::inviteUser [ChatFor $win_name]"
		cmsn_draw_otherwindow $title "::amsn::queueinviteUser [ChatFor $win_name]"
	}
   }

   proc queueinviteUser { chatid user } {
      ::MSN::ChatQueue $chatid "::MSN::inviteUser $chatid $user"
   }
   
   proc ShowChatList {title win_name command} {
      global list_users

      set userlist [list]
      set chatusers [::MSN::usersInChat [ChatFor $win_name]]

      foreach user_login $chatusers {
         set user_state_no [lindex [::MSN::getUserInfo $user_login] 2]
			status_log "user_state_no: $user_state_no\n"

      	set user_name [lindex [::MSN::getUserInfo $user_login] 1]
   	     lappend userlist [list $user_login $user_name $user_state_no]
      }

      if { [llength $userlist] > 0 } {
   	   ChooseList $title both $command 0 1 $userlist
      } else {
			status_log "No users\n"
		}

   }



	#///////////////////////////////////////////////////////////////////////////////
	proc ChooseList {title online command other skip {userslist ""}} {
		global list_users list_bl list_states userchoose_req bgcolor tcl_platform

		if { $userslist == "" } {
			set userslist $list_users
		}

		set usercount 0

		#Count users. Ignore offline ones if $online=="online"
		foreach user $userslist {
		
			set user_login [lindex $user 0]
			set user_state_no [lindex $user 2]
			
			if { "$user_state_no" == "" } {
				set user_state_no 0
			}
			
			set state [lindex $list_states $user_state_no]
			set state_code [lindex $state 0]

			if {($online != "online") || ($state_code != "FLN")} {
				set usercount [expr {$usercount + 1}]
			}

		}

		#If just 1 user, and $skip flag set to one, just run command on that user
		if { $usercount == 1 && $skip == 1} {
			eval $command $user_login
			return 0
		}

		if { [focus] == ""  || [focus] =="." } {
			set wname "._userchoose"
		} else {
			set wname "[focus]._userchoose"
		}

		if { [catch {toplevel $wname -borderwidth 0 -highlightthickness 0 } res ] } {
			raise $wname
			focus $wname
			return 0
		} else {
			set wname $res
		}

		wm group $wname .
		wm title $wname $title

		#ShowTransient $wname
                  
		wm geometry $wname 280x300

		frame $wname.blueframe -background $bgcolor

		frame $wname.blueframe.list -class Amsn -borderwidth 0
		frame $wname.buttons -class Amsn


		listbox $wname.blueframe.list.userlist -yscrollcommand "$wname.blueframe.list.ys set" -font splainf \
			-background white -relief flat -highlightthickness 0 -height 1
		scrollbar $wname.blueframe.list.ys -command "$wname.blueframe.list.userlist yview" -highlightthickness 0 \
			-borderwidth 1 -elementborderwidth 1 

		button  $wname.buttons.ok -text "[trans ok]" -command "$command \[string range \[lindex \[$wname.blueframe.list.userlist get active\] end\] 1 end-1\]\n;destroy $wname" -font sboldf
		button  $wname.buttons.cancel -text "[trans cancel]" -command [list destroy $wname] -font sboldf


		pack $wname.blueframe.list.ys -side right -fill y
		pack $wname.blueframe.list.userlist -side left -expand true -fill both
		pack $wname.blueframe.list -side top -expand true -fill both -padx 4 -pady 4
		pack $wname.blueframe -side top -expand true -fill both

		if { $other == 1 } {
			button  $wname.buttons.other -text "[trans other]..." -command "cmsn_draw_otherwindow \"$title\" \"$command\"; destroy $wname" -font sboldf
			pack $wname.buttons.ok -padx 0 -side left
			pack $wname.buttons.cancel -padx 0 -side right
			pack $wname.buttons.other -padx 10 -side left
		} else {
			pack $wname.buttons.ok -padx 0 -side left
			pack $wname.buttons.cancel -padx 0 -side right
		}

		pack $wname.buttons -side bottom -fill x -pady 3

		foreach user $userslist {
			set user_login [lindex $user 0]
			set user_name [lindex $user 1]
			set user_state_no [lindex $user 2]
			if { "$user_state_no" == "" } {
				set user_state_no 0
			}
			set state [lindex $list_states $user_state_no]
			set state_code [lindex $state 0]

			if {($online != "online") || ($state_code != "FLN")} {
				if {[lsearch $list_bl "$user_login *"] != -1} {
					$wname.blueframe.list.userlist insert end "([trans blocked]) $user_name <$user_login>"

				} else {
					$wname.blueframe.list.userlist insert end "$user_name <$user_login>"
				}
			}

		}

		bind $wname.blueframe.list.userlist <Double-Button-1> "$command \[string range \[lindex \[$wname.blueframe.list.userlist get active\] end\] 1 end-1\]\n;destroy $wname"
		focus $wname.buttons.ok
		bind $wname <Escape> "destroy $wname"
		bind $wname <Return> "$command \[string range \[lindex \[$wname.blueframe.list.userlist get active\] end\] 1 end-1\]\n;destroy $wname"

	}
	#///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # TypingNotification (win_name inputbox)
   # Called by a window when the user types something into the text box. It tells
   # the protocol layer to send a typing notificacion to the chat that the window
   # 'win_name' is connected to
   proc TypingNotification { win_name inputbox} {
      global config

      set chatid [ChatFor $win_name]

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
         if { $config(notifytyping) } {
            sb_change $chatid
         }
      } else {
         ::MSN::chatTo $chatid
      }


   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # MessageSend (win_name,input)
   # Called from a window the the user enters a message to send to the chat. It will
   # just queue the message to send in the chat associated with 'win_name', and set
   # a timeout for the message
   proc MessageSend { win_name input {custom_msg ""}} {

      global user_info config

      set chatid [ChatFor $win_name]
      
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

      set fontfamily [lindex $config(mychatfont) 0]
      set fontstyle [lindex $config(mychatfont) 1]
      set fontcolor [lindex $config(mychatfont) 2]	
	
      if { [string length $msg] > 400 } {
      	set first 0
	while { [expr {$first + 400}] <= [string length $msg] } {
		set msgchunk [string range $msg $first [expr {$first + 399}]]
		set ackid [after 60000 ::amsn::DeliveryFailed $chatid [list $msgchunk]]
		::MSN::messageTo $chatid "$msgchunk" $ackid
		incr first 400
	}
	set msgchunk [string range $msg $first end]
	set ackid [after 60000 ::amsn::DeliveryFailed $chatid [list $msgchunk]]

         #Draw our own message
         messageFrom $chatid [lindex $user_info 3] "$msg" user [list $fontfamily $fontstyle $fontcolor]      	
	
	::MSN::messageTo $chatid "$msgchunk" $ackid
      } else {
      	set ackid [after 60000 ::amsn::DeliveryFailed $chatid [list $msg]]
      	#::MSN::chatQueue $chatid [list ::MSN::messageTo $chatid "$msg" $ackid]
	
         #Draw our own message
         messageFrom $chatid [lindex $user_info 3] "$msg" user [list $fontfamily $fontstyle $fontcolor]      	
      
	::MSN::messageTo $chatid "$msg" $ackid
      }



   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # ackMessage (ackid)
   # Called from the protocol layer when ACK for a message is received. It Cancels
   # the timer for timeouting the message 'ackid'.
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

      set win_name [WindowFor $chatid]

      if { [WindowFor $chatid] == 0} {
	      chatUser $chatid
		}
      set txt "[trans deliverfail]:\n $msg"
      WinWrite $chatid "[timestamp] [trans deliverfail]:\n" red
      WinWrite $chatid "$msg\n" gray

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # closeWindow (win_name,path)
   # Called when a window and its children are destroyed. When the main window is
   # detroyed ('win_name'=='path') then it tells the protocol layer to leave the
   # chat related to 'win_name', and unsets variables used for that window
   proc closeWindow { win_name path } {

      #Only run when the parent window close event comes
      if { "$win_name" != "$path" } {
        return 0
      }


      global config
      variable window_titles
      variable first_message


      set chatid [ChatFor $win_name]

      if { $chatid == 0 } {
         status_log "VERY BAD ERROR in ::amsn::closeWindow!!!\n" red
	 return 0
      }

      if {$config(keep_logs)} {
		set user_list [::MSN::usersInChat $chatid]
		foreach user_login $user_list {
			::log::StopLog $user_login
		}
      }

      UnsetWindowFor $chatid $win_name
      unset window_titles(${win_name})
      unset first_message(${win_name})

		#Delete images if not in use
		catch {destroy $win_name.bottom.pic}
		set user_list [::MSN::usersInChat $chatid]
		foreach user_login $user_list {
			if {![catch {image inuse user_pic_$user_login}]} {

				if {![image inuse user_pic_$user_login]} {
					status_log "Image user_pic_$user_login not in use, deleting it\n"
					image delete user_pic_$user_login
				}
			}
		}
      ::MSN::leaveChat $chatid

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # PutMessage (chatid,user,msg,type,fontformat)
   # Writes a message into the window related to 'chatid'
   # - 'user' is the user login.
   # - 'msg' is the message itself to be displayed.
   # - 'type' can be red, gray... or any tag defined for the textbox when the windo
   #   was created, or just "user" to use the fontformat parameter
   # - 'fontformat' is a list containing font style and color
   proc PutMessage { chatid user msg type fontformat {ticket ""}} {

	global config
	set tstamp [timestamp]
	if {$config(truncatenicks)} {
		if {$config(showtimestamps)} {
			set says "$tstamp [trans says [list]]:"
		} else {
			set says "[trans says [list]]:"
		}
		set win_name [WindowFor $chatid]
		set maxw [winfo width $win_name.f.out.text]
		incr maxw [expr -10-[font measure splainf -displayof $win_name "$says"]]
		set user [trunc [lindex [::MSN::getUserInfo $user] 1] $win_name $maxw splainf]
	} else {
		set user [lindex [::MSN::getUserInfo $user] 1]
	}

	#Use kind of mutex here (really a ticket counter)
	global putmessage_inputs putmessage_outputs
	#Get my turn
	if { $ticket == "" } {
		set my_ticket [incr putmessage_inputs]
	} else {
		set my_ticket $ticket
	}
	#Wait until it's my turn
	#while { $my_ticket != $putmessage_outputs } {
#		incr putmessage_outputs
#		return 0
#	}
	if {$my_ticket != $putmessage_outputs } {
		after 100 [list ::amsn::PutMessage $chatid $user $msg $type $fontformat $my_ticket]
		status_log "UPS! Another PutMessage running. Avoid interleaving by waiting 100ms and try again\n" white

		return 0
	}


	if {$config(showtimestamps)} {
		WinWrite $chatid "$tstamp [trans says $user]:\n" gray
	} else {
		WinWrite $chatid "[trans says $user]:\n" gray
	}

#	global tiempo_out
#	tkwait variable tiempo_out
#	set tiempo_out 0

	WinWrite $chatid "$msg\n" $type $fontformat

	#Give next turn
	incr putmessage_outputs

	if {$config(keep_logs)} {
		::log::PutLog $chatid $user $msg
	}
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
      } elseif { [WindowFor $chatid] == 0} {
         return 0
      } elseif { "$ready" != "" && [::MSN::chatReady $chatid] != 0 } {
         return 0
      } else {
           WinStatus [WindowFor $chatid] $msg $icon
      }

   }
   #///////////////////////////////////////////////////////////////////////////////


   proc chatDisabled {chatid} {
   	chatStatus $chatid ""
   }

   #///////////////////////////////////////////////////////////////////////////////
   # WinStatus (win_name,msg,[icon])
   # Writes the message 'msg' in the window 'win_name' status bar. It will add the
   # icon 'icon' at the beginning of the message, if specified.
   proc WinStatus { win_name msg {icon ""}} {

      set msg [stringmap {"\n" " "} $msg]
   
      ${win_name}.status configure -state normal
      ${win_name}.status delete 0.0 end
      if { "$icon"!=""} {
	  ${win_name}.status image create end -image $icon -pady 0 -padx 1
      }
      ${win_name}.status insert end $msg
      ${win_name}.status configure -state disabled

   }
   #///////////////////////////////////////////////////////////////////////////////


	proc GotFocus { win_name } {
      variable window_titles
		variable new_message_on

		if { [info exists new_message_on(${win_name})] && $new_message_on(${win_name}) == 1 } {
			unset new_message_on(${win_name})
			catch {wm title ${win_name} "$window_titles(${win_name})"} res
			bind ${win_name} <FocusIn> ""
			status_log "Here win_name=$win_name\n"
		}
	}

   #///////////////////////////////////////////////////////////////////////////////
   # WinFlicker (chatid,[count])
   # Called when a window must flicker, and called by itself to produce the flickering
   # effect. It will flicker the window until it gots the focus.
   # - 'chatid' is the name of the chat to flicker.
   # - 'count' can be any number, it's just used in self calls
   proc WinFlicker {chatid {count 0}} {

      global config
      variable window_titles
		variable new_message_on


      if { [WindowFor $chatid] != 0} {
         set win_name [WindowFor $chatid]
      } else {
         return 0
      }


      if { $config(flicker) == 0 } {
			if { [string first $win_name [focus]] != 0 } {
				catch {wm title ${win_name} "*$window_titles($win_name)"} res
				set new_message_on(${win_name}) 1
				bind ${win_name} <FocusIn> "::amsn::GotFocus ${win_name}"
			}
      	return 0
      }

      after cancel ::amsn::WinFlicker $chatid 0
      after cancel ::amsn::WinFlicker $chatid 1

      if { [string first $win_name [focus]] != 0 } {

      set count  [expr {( $count +1 ) % 2}]

      if {![catch {
	     if { $count == 1 } {
  	        wm title ${win_name} "[trans newmsg]"
  	     } else {
	        wm title ${win_name} "$window_titles($win_name)"
	     }
	  } res]} {
 	     after 300 ::amsn::WinFlicker $chatid $count
      }
      } else {

	  catch {wm title ${win_name} "$window_titles($win_name)"} res
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

      set win_name [WindowFor $lowuser]

      if { $win_name == 0 } {

         variable first_message
	  set win_name [OpenChatWindow]
         SetWindowFor $lowuser $win_name
	 set first_message($win_name) 0
	 }

      set chatid [::MSN::chatTo $lowuser]

      if { "$chatid" != "${lowuser}" } {
         status_log "Error in ::amsn::chatUser, expected same chatid as user, but was different\n" red
         return 0
      }

      wm state $win_name normal
      wm deiconify ${win_name}
		
		update idletasks

      WinTopUpdate $chatid

      #We have a window for that chatid, raise it
      raise ${win_name}
      focus -force ${win_name}.f.bottom.in.input

   }
	  #///////////////////////////////////////////////////////////////////////////////

	  if { $initialize_amsn == 1 } {

	      variable urlcount 0
	      set urlstarts { "http://" "https://" "ftp://" "www." }
	  }
   #///////////////////////////////////////////////////////////////////////////////
   # WinWrite (chatid,txt,tagid,[format])
   # Writes 'txt' into the window related to 'chatid'
   # It will use 'tagname' as style tag, unles 'tagname'=="user", where it will use
   # 'fontname', 'fontstyle' and 'fontcolor' as from fontformat
   proc WinWrite {chatid txt tagname {fontformat ""} {flicker 1}} {
   
       global emotions config ;#smileys_end_subst

      set win_name [WindowFor $chatid]

      if { [WindowFor $chatid] == 0} {
         return 0
      }
		

       if { [lindex [${win_name}.f.out.ys get] 1] == 1.0 } {
	   set scrolling 1
       } else {
	   set scrolling 0
       }
		 

      set fontname [lindex $fontformat 0]
      set fontstyle [lindex $fontformat 1]      
      set fontcolor [lindex $fontformat 2]

      ${win_name}.f.out.text configure -state normal -font bplainf -foreground black

      set text_start [${win_name}.f.out.text index end]
      set posyx [split $text_start "."]
      set text_start "[expr {[lindex $posyx 0]-1}].[lindex $posyx 1]"

      #By default tagid=tagname unless we generate a new one
      set tagid $tagname
      
      if { $tagid == "user" || $tagid == "yours" } {

#      	set txt " $txt"
      
         set size [expr {[lindex $config(basefont) 1]+$config(textsize)}]
         set font "\"$fontname\" $size $fontstyle"

         set tagid [::md5::md5 "$font$fontcolor"]

         if { ([string length $fontname] < 3 )
	      || ([catch {${win_name}.f.out.text tag configure $tagid -foreground #$fontcolor -font $font} res])} {
            status_log "Font $font or color $fontcolor wrong. Using default\n" red
            ${win_name}.f.out.text tag configure $tagid -foreground black -font bplainf
         }
      }

      ${win_name}.f.out.text insert end "$txt" $tagid
      
      
      #TODO: Make an url_subst procedure, and improve this using regular expressions
      variable urlcount
      variable urlstarts

      set endpos $text_start
      
      foreach url $urlstarts {

         while { $endpos != [${win_name}.f.out.text index end] && [set pos [${win_name}.f.out.text search -forward -exact -nocase \
                                 $url $endpos end]] != "" } {


	   set urltext [${win_name}.f.out.text get $pos end]

	   set final 0
	   set caracter [string range $urltext $final $final]
	   while { $caracter != " " && $caracter != "\n" && $caracter != "," \
	   	&& $caracter != ")" && $caracter != "("} {
		set final [expr {$final+1}]
		set caracter [string range $urltext $final $final]
	   }

	   set urltext [string range $urltext 0 [expr {$final-1}]]

           set posyx [split $pos "."]
           set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $final}]"

	   set urlcount "[expr {$urlcount+1}]"
	   set urlname "url_$urlcount"

	   ${win_name}.f.out.text tag configure $urlname \
	      -foreground #000080 -background white -font splainf -underline true
	      ${win_name}.f.out.text tag bind $urlname <Enter> \
	      "${win_name}.f.out.text tag conf $urlname -underline false;\
	      ${win_name}.f.out.text conf -cursor hand2"
	   ${win_name}.f.out.text tag bind $urlname <Leave> \
	      "${win_name}.f.out.text tag conf $urlname -underline true;\
	      ${win_name}.f.out.text conf -cursor left_ptr"
	   ${win_name}.f.out.text tag bind $urlname <Button1-ButtonRelease> \
	      "${win_name}.f.out.text conf -cursor watch; launch_browser [string map {% %%} [list $urltext]]"
	   
  	   ${win_name}.f.out.text delete $pos $endpos
	   ${win_name}.f.out.text insert $pos "$urltext" $urlname
	   
       }
     }
		  
	  update

	  #Avoid problems if the windows was closed in the middle...
	  if {![winfo exists $win_name]} {
			return
	  }

      if {$config(chatsmileys)} {
          custom_smile_subst $chatid ${win_name}.f.out.text $text_start end
          smile_subst ${win_name}.f.out.text $text_start end 0
      }


#      vwait smileys_end_subst

      if { $scrolling } {
         ${win_name}.f.out.text yview moveto 1.0
         set ys $win_name.f.out.ys
         $ys set [lindex [$ys get] 0] 1.0
      }
      ${win_name}.f.out.text configure -state disabled

		if { $flicker } {
      	WinFlicker $chatid
		}
		

   }
   #///////////////////////////////////////////////////////////////////////////////
	  
   proc WinWriteIcon { chatid imagename {padx 0} {pady 0}} {
      
      set win_name [WindowFor $chatid]

      if { [WindowFor $chatid] == 0} {
         return 0
      }

       if { [lindex [${win_name}.f.out.ys get] 1] == 1.0 } {
	   set scrolling 1
       } else {
	   set scrolling 0
       }


      ${win_name}.f.out.text configure -state normal
      ${win_name}.f.out.text image create end -image $imagename -pady $pady -padx $pady

      if { $scrolling } { ${win_name}.f.out.text yview moveto 1.0 }


      ${win_name}.f.out.text configure -state disabled
   }

   proc WinWriteClickable { chatid txt command {tagid ""}} {
      
      set win_name [WindowFor $chatid]

      if { [WindowFor $chatid] == 0} {
         return 0
      }

       if { [lindex [${win_name}.f.out.ys get] 1] == 1.0 } {
	   set scrolling 1
       } else {
	   set scrolling 0
       }


      if { $tagid == "" } {
         set tagid [getUniqueValue]
      }
      
      ${win_name}.f.out.text configure -state normal
      
      ${win_name}.f.out.text tag configure $tagid \
        -foreground #000080 -background white -font bboldf -underline false
	
      ${win_name}.f.out.text tag bind $tagid <Enter> \
        "${win_name}.f.out.text tag conf $tagid -underline true;\
         ${win_name}.f.out.text conf -cursor hand2"
     ${win_name}.f.out.text tag bind $tagid <Leave> \
       "${win_name}.f.out.text tag conf $tagid -underline false;\
        ${win_name}.f.out.text conf -cursor left_ptr"
     ${win_name}.f.out.text tag bind $tagid <Button1-ButtonRelease> "$command"
                   
      ${win_name}.f.out.text configure -state normal
      ${win_name}.f.out.text insert end "$txt" $tagid

      if { $scrolling } { ${win_name}.f.out.text yview moveto 1.0 }

      ${win_name}.f.out.text configure -state disabled
   }   

   if { $initialize_amsn == 1 } {
       variable NotifID 0
       variable NotifPos [list]
       
   }

   proc closeAmsn {} {
		set parent [focus]
		if { $parent == ""} { set parent "."}
	
      set answer [tk_messageBox -message "[trans exitamsn]" -type yesno -icon question -title [trans title] -parent $parent]
      if {$answer == "yes"} {
	close_cleanup
	exit
      }
   }

   proc closeOrDock { closingdocks } {
     global systemtray_exist statusicon config
     if {$closingdocks} {
        wm iconify .
	if { $systemtray_exist == 1 && $statusicon != 0 && $config(closingdocks) } {
		 status_log "Hiding\n" white
		  wm state . withdrawn
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

      global config
	#Define lastfocus (for Mac OS X focus bug)
	set lastfocus [focus]

      if { $config(shownotify) == 0 } {
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
      

      set xpos $config(notifyXoffset)
      set ypos $config(notifyYoffset)

      #Search for a free notify window position
      while { [lsearch -exact $NotifPos $ypos] >=0 } {
        set ypos [expr {$ypos+105}]
      }
      lappend NotifPos $ypos


      if { $xpos < 0 } { set xpos 0 }
      if { $ypos < 0 } { set ypos 0 }

      canvas $w.c -bg #EEEEFF -width $config(notifwidth) -height $config(notifheight) \
         -relief ridge -borderwidth 2
      pack $w.c

      switch $type {
	  online {
	      $w.c create image 75 50 -image notifyonline
	  }
	  offline {
	      $w.c create image 75 50 -image notifyoffline
	  }
	  state {
	      $w.c create image 75 50 -image notifystate
	  }
	  default {
	      $w.c create image 75 50 -image notifyonline
	  }
      }

      $w.c create image 17 22 -image notifico
      $w.c create image 80 97 -image notifybar
      $w.c create image 142 12 -image notifclose

      if {[string length $msg] >100} {
         set msg "[string range $msg 0 100]..."
      }

      set notify_id [$w.c create text [expr $config(notifwidth)/2] 45 -font splainf \
         -justify center -width [expr $config(notifwidth)-20] -anchor n -text "$msg"]

      set after_id [after 8000 "::amsn::KillNotify $w $ypos"]

      bind $w.c <Enter> "$w.c configure -cursor hand2"
      bind $w.c <Leave> "$w.c configure -cursor left_ptr"
      #bind $w <ButtonRelease-1> "after cancel $after_id; ::amsn::KillNotify $w $ypos; $command"
      bind $w <ButtonRelease-1> "::amsn::testX %x %y $after_id $w $ypos \"$command\""
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
      if {![catch {tk windowingsystem} wsystem] && $wsystem != "aqua" && $config(animatenotify) } {
         wm geometry $w -$xpos-[expr {$ypos-100}]
	 after 50 "::amsn::growNotify $w $xpos [expr {$ypos-100}] $ypos"
      } else {
         wm geometry $w -$xpos-$ypos
      }

#Focus last windows , in AquaTK (Mac OS X)
if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua" && $lastfocus!="" } {
	after 50 "focus -force $lastfocus"
	}
	
      if { $sound != ""} {
	  play_sound ${sound}.wav
      }


   }

   proc growNotify { w xpos currenty finaly } {
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


proc clean_yscroll_variable { bar } {
	global scrollbar_packed_$bar

	catch { unset scrollbar_packed_$bar }
}

proc adjust_yscroll {text bar begin end } {

  global scrollbar_packed_$bar

  set scrolling 0

  if { $begin == 0 && $end == 1 } {

	  #if { [lindex [$bar get] 1] == 1.0 } {
     #   set scrolling 1
     #}

     if {[info exists scrollbar_packed_$bar]} {
     	pack forget $bar
		  unset scrollbar_packed_$bar
     }


  } else {

     if { ![info exists scrollbar_packed_$bar ]} {

        if { [lindex [$bar get] 1] == 1.0 } {
           set scrolling 1
        }

        pack forget $text
        pack $bar -side right -fill y -padx 0 -pady 0
        pack $text -side right -expand true -fill both
        set scrollbar_packed_$bar 1
		  #set command [list bind $bar <Destroy> "status_log \"Destroyed\n\"" white]
		  #status_log "$command\n" white
        #eval $command

        update idletasks


     }

  }



  $bar set $begin $end

}

#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_main {} {
   global program_dir emotion_files version date weburl lang_list \
     password config HOME files_dir pgBuddy pgNews bgcolor bgcolor2 argv0 argv langlong tcl_platform

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
   #PreferencesMenu .pref_menu

   menu .user_menu -tearoff 0 -type normal
   menu .move_group_menu -tearoff 0 -type normal
   menu .copy_group_menu -tearoff 0 -type normal

   #Main menu
   menu .main_menu -tearoff 0 -type menubar  -borderwidth 0 -activeborderwidth -0
   
   if {$tcl_platform(os) != "Darwin"} {
    .main_menu add cascade -label "[trans msn]" -menu .main_menu.file
	} else {
 	.main_menu add cascade -label "[trans file]" -menu .main_menu.file
 	}
  
   .main_menu add cascade -label "[trans actions]" -menu .main_menu.actions

   .main_menu add cascade -label "[trans tools]" -menu .main_menu.tools
   .main_menu add cascade -label "[trans help]" -menu .main_menu.helping
   
	   	
	#.main_menu.tools add separator
	
	#Apple menu, only on Mac OS X
	if {$tcl_platform(os) == "Darwin"} {
	.main_menu add cascade -label "Apple" -menu .main_menu.apple
	menu .main_menu.apple -tearoff 0 -type normal
	.main_menu.apple add command -label "[trans about] aMSN" -command ::amsn::aboutWindow
	.main_menu.apple add separator
	.main_menu.apple add command -label "[trans preferences]..." -command Preferences -accelerator "Command-,"
	.main_menu.apple add separator
	}


   #File menu
   menu .main_menu.file -tearoff 0 -type normal 
   if { [string length $config(login)] > 0 } {
     if {$password != ""} {
        .main_menu.file add command -label "[trans loginas] $config(login)" \
          -command "::MSN::connect [list $config(login)] [list $password]" -state normal
     } else {
     	.main_menu.file add command -label "[trans loginas] $config(login)" \
          -command cmsn_draw_login -state normal
     }
   } else {
     .main_menu.file add command -label "[trans loginas]..." \
       -command cmsn_draw_login -state normal
   }
   .main_menu.file add command -label "[trans login]..." -command \
     cmsn_draw_login
   .main_menu.file add command -label "[trans logout]" -command "::MSN::logout; save_alarms"
   .main_menu.file add cascade -label "[trans mystatus]" \
     -menu .my_menu -state disabled
   .main_menu.file add separator
   .main_menu.file add command -label "[trans inbox]" -command \
     "hotmail_login [list $config(login)] [list $password]"
   .main_menu.file add separator
   .main_menu.file add command -label "[trans savecontacts]..." \
   	-command "debug_cmd_lists -export" -state disabled
   .main_menu.file add command -label "[trans loadcontacts]..." -state disabled
   .main_menu.file add separator
   .main_menu.file add command -label "[trans sendfile]..." -state disabled
   .main_menu.file add command -label "[trans openreceived]" \
      -command "launch_filemanager \"$files_dir\""
   .main_menu.file add separator
   .main_menu.file add command -label "[trans close]" -command "close_cleanup;exit"

   #Actions menu
   set dummy_user "recipient@somewhere.com"
   menu .main_menu.actions -tearoff 0 -type normal
   .main_menu.actions add command -label "[trans sendmsg]..." -command \
     "::amsn::ChooseList \"[trans sendmsg]\" online ::amsn::chatUser 1 0"
   .main_menu.actions add command -label "[trans sendmail]..." -command \
     "::amsn::ChooseList \"[trans sendmail]\" both \"launch_mailer\" 1 0"
    #.main_menu.actions add command -label "[trans verifyblocked]..." -command "VerifyBlocked"
    #.main_menu.actions add command -label "[trans showblockedlist]..." -command "VerifyBlocked ; show_blocked"
   .main_menu.actions add command -label "[trans changenick]..." -command cmsn_change_name
   .main_menu.actions add separator
   .main_menu.actions add command -label "[trans checkver]..." -command "check_version"
   

   #Order Contacts By submenu
   menu .order_by -tearoff 0 -type normal 
   .order_by add radio -label "[trans status]" -value 0 \
   	-variable config(orderbygroup) -command "cmsn_draw_online"
   .order_by add radio -label "[trans group]" -value 1 \
   	-variable config(orderbygroup) -command "cmsn_draw_online"
  .order_by add radio -label "[trans hybrid]" -value 2 \
   	-variable config(orderbygroup) -command "cmsn_draw_online"

   #Order Groups By submenu
   #Added by Trevor Feeney
   menu .ordergroups_by -tearoff 0 -type normal
   .ordergroups_by add radio -label "[trans normal]" -value 1 \
   	-variable config(ordergroupsbynormal) -command "cmsn_draw_online"
   .ordergroups_by add radio -label "[trans reversed]" -value 0 \
   	-variable config(ordergroupsbynormal) -command "cmsn_draw_online"



   #Tools menu
   menu .main_menu.tools -tearoff 0 -type normal
   .main_menu.tools add command -label "[trans addacontact]..." -command cmsn_draw_addcontact
   .main_menu.tools add cascade -label "[trans admincontacts]" -menu .admin_contacts_menu

   menu .admin_contacts_menu -tearoff 0 -type normal
   .admin_contacts_menu add command -label "[trans delete]..." \
      -command  "::amsn::ChooseList \"[trans delete]\" both ::amsn::deleteUser 0 0"
   .admin_contacts_menu add command -label "[trans properties]..." \
      -command "::amsn::ChooseList \"[trans properties]\" both ::abookGui::showEntry 0 1"

   ::groups::Init .main_menu.tools

   .main_menu.tools add separator
   .main_menu.tools add cascade -label "[trans ordercontactsby]" \
     -menu .order_by

   #Added by Trevor Feeney
   #User to reverese group lists
   .main_menu.tools add cascade -label "[trans ordergroupsby]" \
     -menu .ordergroups_by
     
#Unecessary separator when you remove the 2 dockings items menu on Mac OS X
   	if {$tcl_platform(os) != "Darwin"} {
	.main_menu.tools add separator
	}
	
   #.main_menu.tools add cascade -label "[trans options]" -menu .options

   #Options menu
   #menu .options -tearoff 0 -type normal
   #.options add command -label "[trans changenick]..." -state disabled \
   #   -command cmsn_change_name -state disabled
#   .options add command -label "[trans publishphones]..." -state disabled \
   #   -command "::abookGui::showEntry $config(login) -edit"
   #.options add separator
   #.options add command -label "[trans preferences]..." -command Preferences

   #TODO: Move this into preferences window
   #.options add cascade -label "[trans docking]" -menu .dock_menu

#Disable item menu for docking in Mac OS X(incompatible)
   	if {$tcl_platform(os) != "Darwin"} {
	.main_menu.tools add cascade -label "[trans docking]" -menu .dock_menu
	}
	
   menu .dock_menu -tearoff 0 -type normal
   .dock_menu add radio -label "[trans dockingoff]" -value 0 -variable config(dock) -command "init_dock"
   .dock_menu add radio -label "[trans dockfreedesktop]" -value 3 -variable config(dock) -command "init_dock"
   .dock_menu add radio -label "[trans dockgtk]" -value 1 -variable config(dock) -command "init_dock"
   #.dock_menu add radio -label "[trans dockkde]" -value 2 -variable config(dock) -command "init_dock"

   .main_menu.tools add separator
   #.options add checkbutton -label "[trans sound]" -onvalue 1 -offvalue 0 -variable config(sound)
   #Let's disable adverts until it works, it's only problems for know
   set config(adverts) 0
   #.options add checkbutton -label "[trans adverts]" -onvalue 1 -offvalue 0 -variable config(adverts) \
   #-command "msg_box \"[trans mustrestart]\""
   #.options add checkbutton -label "[trans closingdocks]" -onvalue 1 -offvalue 0 -variable config(closingdocks)
   #.options add separator
   #.options add command -label "[trans language]..." -command show_languagechoose
   # .options add command -label "[trans skinselector]..." -command SelectSkinGui
#    .options add command -label "[trans pluginselector]..." -command ::plugins::PluginGui

	.main_menu.tools add checkbutton -label "[trans sound]" -onvalue 1 -offvalue 0 -variable config(sound)
	
	#Disable item menu for docking in Mac OS X(incompatible)
	if {$tcl_platform(os) != "Darwin"} {
	.main_menu.tools add checkbutton -label "[trans closingdocks]" -onvalue 1 -offvalue 0 -variable config(closingdocks)
	}
	

	.main_menu.tools add separator
   .main_menu.tools add command -label "[trans language]..." -command show_languagechoose
    .main_menu.tools add command -label "[trans skinselector]..." -command SelectSkinGui
   .main_menu.tools add command -label "[trans preferences]..." -command Preferences

   #Help menu
   menu .main_menu.helping -tearoff 0 -type normal

   if { $config(language) != "en" } {
      .main_menu.helping add command -label "[trans helpcontents] - $langlong..." \
         -command "::amsn::showTranslatedHelpFile HELP [list [trans helpcontents]]"
      .main_menu.helping add command -label "[trans helpcontents] - English..." \
         -command "::amsn::showHelpFile HELP [list [trans helpcontents]]"
   } else {
      .main_menu.helping add command -label "[trans helpcontents]..." \
         -command "::amsn::showHelpFile HELP [list [trans helpcontents]]"
   }
   .main_menu.helping add separator
   if { $config(language) != "en" } {
      .main_menu.helping add command -label "[trans faq] - $langlong..." \
         -command "::amsn::showTranslatedHelpFile FAQ [list [trans faq]]"
      .main_menu.helping add command -label "[trans faq] - English..." \
         -command "::amsn::showHelpFile FAQ [list [trans faq]]"
   } else {
      .main_menu.helping add command -label "[trans faq]..." \
         -command "::amsn::showHelpFile FAQ [list [trans faq]]"
   }
   .main_menu.helping add separator
   .main_menu.helping add command -label "[trans about]..." -command ::amsn::aboutWindow
   .main_menu.helping add command -label "[trans version]..." -command \
     "msg_box \"[trans version]: $version\n[trans date]: $date\n$weburl\""


   #image create photo mainback -file [GetSkinFile pixmaps back.gif]

   wm title . "[trans title] - [trans offline]"
   wm command . [concat $argv0 $argv]
   wm group . .
   
 #Make mainwindow in AquaTK always start at the same place
   if {![catch {tk windowingsystem} wsystem] && $wsystem != "aqua"} {
   catch {wm geometry . $config(wingeometry)}
   } else {
   catch {wm geometry . $config(wingeometry)}
   wm geometry . +0+30
   }
   
   frame .main -class Amsn -relief flat -background $bgcolor
   frame .main.f -class Amsn -relief flat -background white
   #pack .main -expand true -fill both
   #pack .main.f -expand true  -fill both  -padx 4 -pady 4 -side top

   # Create the Notebook and initialize the page paths. These
   # page paths must be used for adding new widgets to the
   # notebook tabs.
   if {$config(withnotebook)} {
   	notebook:create .main.nb -bgcolor #AABBCC -font sboldf \
		-pappend "Buddies" -pappend "News"
       set pgBuddy [notebook:getpage .main.nb 0]
       set pgNews  [notebook:getpage .main.nb 1]
       pack .main.nb -fill both -expand 1
   } else {
       set pgBuddy .main.f
       set pgNews  ""
       pack .main -fill both -expand true
   	pack .main.f -expand true -fill both -padx 4 -pady 4 -side top
   }
   # End of Notebook Creation/Initialization

   image create photo msndroid -file [GetSkinFile pixmaps msnbot.gif]
   image create photo online -file [GetSkinFile pixmaps online.gif]
   image create photo offline -file [GetSkinFile pixmaps offline.gif]
   image create photo away -file [GetSkinFile pixmaps away.gif]
   image create photo busy -file [GetSkinFile pixmaps busy.gif]

   image create photo bonline -file [GetSkinFile pixmaps bonline.gif]
   image create photo boffline -file [GetSkinFile pixmaps boffline.gif]
   image create photo baway -file [GetSkinFile pixmaps baway.gif]
   image create photo bbusy -file [GetSkinFile pixmaps bbusy.gif]

   image create photo mailbox -file [GetSkinFile pixmaps unread.gif]

   image create photo contract -file [GetSkinFile pixmaps contract.gif]
   image create photo expand -file [GetSkinFile pixmaps expand.gif]

   image create photo globe -file [GetSkinFile pixmaps globe.gif]

   image create photo typingimg -file [GetSkinFile pixmaps typing.gif]
   image create photo miniinfo -file [GetSkinFile pixmaps miniinfo.gif]
   image create photo miniwarning -file [GetSkinFile pixmaps miniwarn.gif]
   image create photo minijoins -file [GetSkinFile pixmaps minijoins.gif]
   image create photo minileaves -file [GetSkinFile pixmaps minileaves.gif]


   image create photo butsmile -file [GetSkinFile pixmaps butsmile.gif]
   image create photo butfont -file [GetSkinFile pixmaps butfont.gif]
   image create photo butblock -file [GetSkinFile pixmaps butblock.gif]
   image create photo butsend -file [GetSkinFile pixmaps butsend.gif]
   image create photo butinvite -file [GetSkinFile pixmaps butinvite.gif]


   image create photo fticon -file [GetSkinFile pixmaps fticon.gif]
   image create photo ftreject -file [GetSkinFile pixmaps ftreject.gif]

   image create photo notifico -file [GetSkinFile pixmaps notifico.gif]
   image create photo notifclose -file [GetSkinFile pixmaps notifclose.gif]
       image create photo notifyonline -file [GetSkinFile pixmaps notifyonline.gif] -format gif
       image create photo notifyoffline -file [GetSkinFile pixmaps notifyoffline.gif] -format gif
       image create photo notifystate -file [GetSkinFile pixmaps notifystate.gif] -format gif


   image create photo blocked -file [GetSkinFile pixmaps blocked.gif]

   image create photo colorbar -file [GetSkinFile pixmaps colorbar.gif]

   image create photo imgshow -file [GetSkinFile pixmaps imgshow.gif]
   image create photo imghide -file [GetSkinFile pixmaps imghide.gif]

   set barwidth [image width colorbar]
   set barheight [image height colorbar]

   image create photo mainbar -width 1280 -height $barheight
   image create photo notifybar -width 140 -height $barheight

   notifybar copy colorbar -from 0 0 5 $barheight
   notifybar copy colorbar -from 5 0 15 $barheight -to 5 0 64 $barheight
   notifybar copy colorbar -from [expr {$barwidth-125}] 0 $barwidth $barheight -to 64 0 139 $barheight

   image create photo bell -file [GetSkinFile pixmaps bell.gif]
   image create photo belloff -file [GetSkinFile pixmaps belloff.gif]

   image create photo blockedme -file [GetSkinFile pixmaps blockedme.gif]

   image create photo blockedme -file [GetSkinFile pixmaps blockedme.gif]
   image create photo no_pic -file [GetSkinFile displaypic nopic.gif]


	text $pgBuddy.text -background white -width 30 -height 0 -wrap none \
      -yscrollcommand "adjust_yscroll $pgBuddy.text $pgBuddy.ys" -cursor left_ptr -font splainf \
      -selectbackground white -selectborderwidth 0 -exportselection 0 \
      -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0

   scrollbar $pgBuddy.ys -command "$pgBuddy.text yview" -highlightthickness 0 \
      -borderwidth 1 -elementborderwidth 1


   #This shouldn't go here
   #if {$config(withproxy)} {

     #::Proxy::Init $config(proxy) "http"
     #::Proxy::Init $config(proxy) "post"
     #::Proxy::Init $config(proxy) $config(proxytype)
     #::Proxy::LoginData $config(proxyauthenticate) $config(proxyuser) $config(proxypass)
   #}

   if {$config(enablebanner)} {

	# If user wants to see aMSN Banner, we add it to main window (By default "Yes")
	adv_initialize .main

	# This one is not a banner but a branding. When adverts are enabled
	# they share this space with the branding image. The branding image
	# is cycled in between adverts.
	if {$tcl_platform(os) == "Darwin"} {
	adv_show_banner file [GetSkinFile pixmaps logomacmsn.gif]
	} else {
	adv_show_banner file [GetSkinFile pixmaps logolinmsn.gif]
	}
   }

   pack $pgBuddy.text -side right -expand true -fill both -padx 0 -pady 0   
   #pack $pgBuddy.ys -side left -fill y -padx 0 -pady 0
#Command-key for "key shorcut" in Mac OS X
if {$tcl_platform(os) == "Darwin"} {
   bind . <Command-s> toggle_status
   bind . <Command-,> Preferences
   bind . <Command-Option-space> BossMode
   } else {
   bind . <Control-s> toggle_status
   bind . <Control-p> Preferences
   bind . <Control-Alt-space> BossMode   
   }

#Shorcut to Quit aMSN on Mac OS X
if {$tcl_platform(os) == "Darwin"} {
bind all <Command-q> {
	 close_cleanup;exit
 
}
}

   wm protocol . WM_DELETE_WINDOW {::amsn::closeOrDock $config(closingdocks)}

   cmsn_draw_status
   cmsn_draw_offline

   status_log "Proxy is : $config(proxy)\n"

   #image create photo amsnicon -file [GetSkinFile pixmaps amsnicon.gif]
   #toplevel .caca
   #label .caca.winicon -image amsnicon
   #pack .caca.winicon
   #wm iconwindow . .caca

   #wm iconname . "[trans title]"
   wm iconbitmap . @[GetSkinFile pixmaps amsn.xbm]
   wm iconmask . @[GetSkinFile pixmaps amsnmask.xbm]
   . conf -menu .main_menu


}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
proc change_myfont {win_name} {
  global config

  set fontsize [expr {[lindex $config(basefont) end-1] + $config(textsize)}]
  set fontcolor [lindex $config(mychatfont) 2]

  set selfont [tk_chooseFont -title [trans choosebasefont] -initialfont "\{[lindex $config(mychatfont) 0]\} $fontsize \{[lindex $config(mychatfont) 1]\}"]

  if { [string length $selfont] <1} {
    return
  }

  set config(textsize) [expr {[lindex $selfont 1]- [lindex $config(basefont) 1]}]
  set config(mychatfont) "\{[lindex $selfont 0]\} \{[lindex $selfont 2]\} $fontcolor"

  set color [tk_chooseColor -title "[trans choosefontcolor]" -parent .${win_name} \
    -initialcolor #$fontcolor]

  if { [string length $color] <1} {
    set color $fontcolor
  } else {
    set color [string range $color 1 end]
  }

  set config(mychatfont) [lreplace $config(mychatfont) 2 2 $color]

  status_log "color selected: $color\n"

  change_myfontsize $config(textsize) ${win_name}

}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc change_myfontsize {size name} {
  global config

  set config(textsize) $size

  set fontfamily \{[lindex $config(mychatfont) 0]\}
  set fontstyle \{[lindex $config(mychatfont) 1]\}

    if { [llength $config(basefont)] < 3 } { set config(basefont) "Helvetica 11 normal" }
  set fontsize [expr {[lindex $config(basefont) end-1]+$config(textsize)}]

  catch {.${name}.f.out.text tag configure yours -font "$fontfamily $fontsize $fontstyle"} res
  catch {.${name}.f.bottom.in.input configure -font "$fontfamily $fontsize $fontstyle"} res
  catch {.${name}.f.bottom.in.input configure -foreground "#[lindex $config(mychatfont) end]"} res

  #Get old user font and replace its size
  catch {
     set font [lreplace [.${name}.f.out.text tag cget user -font] 1 1 $fontsize]
     .${name}.f.out.text tag configure user -font $font
  } res
}
#///////////////////////////////////////////////////////////////////////



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
proc play_sound {sound_name} {
    global config program_dir

	if { [string first "\$sound" $config(soundcommand)] == -1 } {
		set config(soundcommand) "$config(soundcommand) \$sound"
	}


    if { $config(sound) == 1 } {
	set sound [GetSkinFile sounds $sound_name]
	catch {eval exec $config(soundcommand) &} res
 
    }
}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
proc choose_basefont { } {
   global config

   set font "[tk_chooseFont -title [trans choosebasefont] -initialfont $config(basefont)]"

   if { [llength $font] < 2 } {
     return 0
   }

   set family [lindex $font 0]
   set size [lindex $font 1]

   set newfont "\"$family\" $size normal"

   if { $newfont != $config(basefont)} {
      set config(basefont) $newfont
      msg_box [trans mustrestart]
   }

}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc show_languagechoose {} {
   global lang_list

   set languages [list]

   for {set i 0} {$i < [llength $lang_list]} {incr i} {
     set langelem [lindex $lang_list $i]
     set langshort [lindex $langelem 0]
     set langlong [lindex $langelem 1]
     lappend languages [list $langshort "$langlong"]
     #-command "set config(language) $langshort; load_lang;msg_box \"\[trans mustrestart\]\""
   }

  ::amsn::ChooseList "[trans language]" both "set_language" 0 1 $languages
}
#///////////////////////////////////////////////////////////////////////


proc set_language { langname } {
   global config
	set oldlang $config(language)
	set config(language) $langname
   load_lang
   msg_box [trans mustrestart]
   set config(language) $oldlang
   load_lang
	set config(language) $langname
	 return

   ::MSN::logout
   set config(language) $langname
   load_lang
   #Here instead of destroying, maybe we should call some kind of redraw
   set windows [winfo children .]
   foreach w $windows {
         #puts "Destroying $w"
         destroy $w
	 set windows [winfo children .]
   }
   cmsn_draw_main
}


#///////////////////////////////////////////////////////////////////////
proc show_encodingchoose {} {
  set encodings [encoding names]
  set encodings [lsort $encodings]
  set enclist [list]
  foreach enc $encodings {
	 lappend enclist [list $enc "" 0]
  }
  set enclist [linsert $enclist 0 [list auto "Automatic" 0]]
  ::amsn::ChooseList "[trans encoding]" both set_encoding 0 1 $enclist
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc set_encoding {enc} {
  global config
  if {[catch {encoding system $enc} res]} {
     msg_box "Selected encoding not available, selecting auto"
     set config(encoding) auto
  } else {
     set config(encoding) $enc
  }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_status {} {
    global followtext_status
   toplevel .status
   wm group .status .
   wm state .status withdrawn
   wm title .status "status log - [trans title]"

    set followtext_status 1

   text .status.info -background white -width 60 -height 30 -wrap word \
      -yscrollcommand ".status.ys set" -font splainf
   scrollbar .status.ys -command ".status.info yview"
   entry .status.enter -background white
    checkbutton .status.follow -text "[trans followtext]" -onvalue 1 -offvalue 0 -variable followtext_status

   frame .status.bot -relief sunken -borderwidth 1
    button .status.bot.save -text "[trans savetofile]" -command status_save
    	button .status.bot.clear  -text "Clear" -font sboldf \
		-command ".status.info delete 0.0 end"
    	button .status.bot.close -text [trans close] -command toggle_status -font sboldf
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
    
    fileDialog $w $w.filename.entry save "status_log.txt"

    grab $w
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

   global sboldf config password pgBuddy

   bind $pgBuddy.text <Configure>  ""

   wm title . "[trans title] - [trans offline]"

   $pgBuddy.text configure -state normal
   $pgBuddy.text delete 0.0 end

   #Iniciar sesion

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
	    "show_languagechoose"


   $pgBuddy.text tag conf start_login -fore #000000 -underline true \
      -font sboldf -justify center
   $pgBuddy.text tag bind start_login <Enter> \
	    "$pgBuddy.text tag conf start_login -fore #0000A0 -underline false;\
	    $pgBuddy.text conf -cursor hand2"
   $pgBuddy.text tag bind start_login <Leave> \
	    "$pgBuddy.text tag conf start_login -fore #000000 -underline true;\
	    $pgBuddy.text conf -cursor left_ptr"
    $pgBuddy.text tag bind start_login <Button1-ButtonRelease> \
        "::MSN::connect [list $config(login)] [list $password]"


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

   $pgBuddy.text image create end -image globe -pady 5 -padx 5
   $pgBuddy.text insert end "[trans language]\n" lang_sel



   $pgBuddy.text insert end "\n\n\n\n"

   if { $config(login) != ""} {
     if { $password != "" } {
        $pgBuddy.text insert end "$config(login)\n" start_login
        $pgBuddy.text insert end "[trans clicktologin]" start_login
     } else {
     	$pgBuddy.text insert end "$config(login)\n" start_loginas
        $pgBuddy.text insert end "[trans clicktologin]" start_loginas
     }

     #$pgBuddy.text tag bind start_login <Button1-ButtonRelease> \
	#"::MSN::connect $config(login) $password"

     $pgBuddy.text insert end "\n\n\n\n\n"

     $pgBuddy.text insert end "[trans loginas]...\n" start_loginas
     $pgBuddy.text insert end "\n\n\n\n\n\n\n\n\n"

   } else {
     $pgBuddy.text insert end "[trans clicktologin]..." start_loginas

     $pgBuddy.text insert end "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

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
   #Add a contact
   .main_menu.tools entryconfigure 0 -state disabled
   .main_menu.tools entryconfigure 1 -state disabled
   .main_menu.tools entryconfigure 4 -state disabled
   #Added by Trevor Feeney
   #Disables Group Order menu
   .main_menu.tools entryconfigure 5 -state disabled
   

   #Change nick
   configureMenuEntry .main_menu.actions "[trans changenick]..." disabled
   #configureMenuEntry .options "[trans changenick]..." disabled

   configureMenuEntry .main_menu.actions "[trans sendmail]..." disabled
   configureMenuEntry .main_menu.actions "[trans sendmsg]..." disabled

   configureMenuEntry .main_menu.actions "[trans sendmsg]..." disabled
   #configureMenuEntry .main_menu.actions "[trans verifyblocked]..." disabled
   #configureMenuEntry .main_menu.actions "[trans showblockedlist]..." disabled


   configureMenuEntry .main_menu.file "[trans savecontacts]..." disabled

   #Publish Phone Numbers
#   configureMenuEntry .options "[trans publishphones]..." disabled

   #Initialise Preferences if window is open
   if { [winfo exists .cfg] } {
   	InitPref
   }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_signin {} {
   bind . <Configure> ""

	 global config pgBuddy

   wm title . "[trans title] - $config(login)"


   $pgBuddy.text configure -state normal -font splainf
   $pgBuddy.text delete 0.0 end
   $pgBuddy.text tag conf signin -fore #000000 \
   -font sboldf -justify center
   #$pgBuddy.text insert end "\n\n\n\n\n\n\n"
   $pgBuddy.text insert end "\n\n\n\n\n"

   label .loginanim -background [$pgBuddy.text cget -background]
   ::anigif::anigif [GetSkinFile pixmaps loganim.gif] .loginanim

   $pgBuddy.text insert end " " signin
   $pgBuddy.text window create end -window .loginanim
   $pgBuddy.text insert end " " signin

   bind .loginanim <Destroy> "::anigif::destroy .loginanim"

   $pgBuddy.text insert end "\n\n"
   $pgBuddy.text insert end "[trans loggingin]..." signin
   $pgBuddy.text insert end "\n"
   $pgBuddy.text configure -state disabled

   tkwait visibility .loginanim
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc login_ok {} {
	global config password loginmode
	
	
	if { $loginmode == 0 } {
		set config(login) [string tolower [.login.main.f.f.loginentry get]]
	   	set password [.login.main.f.f.passentry get]
	} else {
		if { $password != [.login.main.f.f.passentry2 get] } {
			set password [.login.main.f.f.passentry2 get]
		}
	}
   
	grab release .login
	destroy .login

	if { $password != "" && $config(login) != "" } {
		::MSN::connect [list $config(login)] [list $password]
	} else {
		cmsn_draw_login
	}
}
#///////////////////////////////////////////////////////////////////////

proc SSLToggled {} {
	global config
	if {$config(nossl) == 1 } {
		::amsn::infoMsg "[trans sslwarning]"
	}
}



#///////////////////////////////////////////////////////////////////////
# Main login window, separated profiled or default logins
# cmsn_draw_login {}
# 
proc cmsn_draw_login {} {

	global config password loginmode HOME HOME2 protocol tcl_platform

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
	if { $config(disableprofiles)!=1} { grid $mainframe.button -row 1 -column 1 -columnspan 2 -sticky w -padx 10 }
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
	if { $config(disableprofiles)!=1} {
		grid $mainframe.button2 -row 1 -column 3 -sticky w
		grid $mainframe.box -row 2 -column 3 -sticky w
	}

	label $mainframe.passlabel -text "[trans pass]: " -font sboldf
	entry $mainframe.passentry -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 25 -show "*"
	entry $mainframe.passentry2 -bg #FFFFFF -bd 1 -font splainf -highlightthickness 0 -width 25 -show "*"
	checkbutton $mainframe.remember -variable config(save_password) \
	-text "[trans rememberpass]" -font splainf -highlightthickness 0 -pady 5 -padx 10
	checkbutton $mainframe.offline -variable config(startoffline) \
	-text "[trans startoffline]" -font splainf -highlightthickness 0 -pady 5 -padx 10

	#Set it, in case someone changes preferences...
	set config(protocol) 9

 checkbutton $mainframe.nossl -text "[trans disablessl]" -variable config(nossl) -padx 10 -command SSLToggled

	label $mainframe.example -text "[trans examples] :\ncopypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com" -font examplef -padx 10
	
	set buttonframe [frame .login.buttons -class Degt]
	button $buttonframe.cancel -text [trans cancel] -command "ButtonCancelLogin .login" -font sboldf
	button $buttonframe.ok -text [trans ok] -command login_ok  -font sboldf
	button $buttonframe.addprofile -text [trans addprofile] -command AddProfileWin -font sboldf
	if { $config(disableprofiles)!=1} {
		pack $buttonframe.ok $buttonframe.cancel $buttonframe.addprofile -side right -padx 10
	} else {
		pack $buttonframe.ok $buttonframe.cancel -side right -padx 10
	}

	grid $mainframe.passlabel -row 3 -column 1 -sticky e -padx 10
	grid $mainframe.passentry -row 3 -column 2 -sticky w -padx 10
	if { $config(disableprofiles)!=1} {
		grid $mainframe.passentry2 -row 3 -column 3 -sticky w
	}
	grid $mainframe.remember -row 5 -column 2 -sticky wn
	grid $mainframe.offline -row 6 -column 2 -sticky wn
	grid $mainframe.example -row 1 -column 4 -rowspan 4

	if { $config(disableprofiles) != 1 } {
		grid $mainframe.nossl -row 7 -column 1 -sticky en -columnspan 4
	}

	pack .login.main .login.buttons -side top -anchor n -expand true -fill both -padx 10 -pady 10

	# Lets fill our combobox
	#$mainframe.box insert 0 $config(login)
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

	if { $config(disableprofiles)==1} {
		set loginmode 0
	}

	RefreshLogin $mainframe

	bind .login <Return> "login_ok"
	bind .login <Escape> "ButtonCancelLogin .login"
	
	#tkwait visibility .login
	grab .login
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
	} elseif { $loginmode == 1 } {
		$mainframe.box configure -state normal
		$mainframe.passentry2 configure -state normal
		$mainframe.loginentry configure -state disabled
		$mainframe.passentry configure -state disabled
		$mainframe.remember configure -state normal
	}
}
	

#///////////////////////////////////////////////////////////////////////////////
# ButtonCancelLogin ()
# Function thats releases grab on .login and destroys it
proc ButtonCancelLogin { window {email ""} } {
	grab release $window
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
    button $buttonframe.cancel -text [trans cancel] -command "grab release  .add_profile; destroy .add_profile" -font sboldf 
    button $buttonframe.ok -text [trans ok] -command "AddProfileOk  $mainframe"  -font sboldf 

    AddProfileOk $mainframe 

    pack  $buttonframe.cancel $buttonframe.ok -side right -padx 10 


    bind .add_profile <Return> "AddProfileOk $mainframe" 
    if {$tcl_platform(os) == "Darwin"} {
    bind .add_profile <Command-w> "grab release .add_profile; destroy  .add_profile" 
	} else {
	bind .add_profile <Escape> "grab release .add_profile; destroy  .add_profile"
	}

    pack .add_profile.main .add_profile.buttons -side top -anchor n -expand  true -fill both -padx 10 -pady 10 
    #grab $mainframe 
	 grab .add_profile 
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
	grab release .add_profile 
	destroy .add_profile 
    } 

}

#///////////////////////////////////////////////////////////////////////
proc toggleGroup {tw name image id {padx 0} {pady 0}} {
   label $tw.$name -image $image
   $tw.$name configure -cursor hand2 -borderwidth 0
   bind $tw.$name <Button1-ButtonRelease> "::groups::ToggleStatus $id; cmsn_draw_online"
   $tw window create end -window $tw.$name -padx $padx -pady $pady
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
proc clickableImage {tw name image command {padx 0} {pady 0}} {
   label $tw.$name -image $image -background white
   $tw.$name configure -cursor hand2 -borderwidth 0
   bind $tw.$name <Button1-ButtonRelease> $command
   $tw window create end -window $tw.$name -padx $padx -pady $pady -align center -stretch true
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
# TODO: move into ::amsn namespace, and maybe improve it
proc cmsn_draw_online { {delay 0} } {

	#Delay not forced redrawing (to avoid too many redraws)
	if { $delay } {
		after cancel "cmsn_draw_online"
		after 250 "cmsn_draw_online"
		return
	}

	global emotions user_stat login list_users list_states user_info list_bl\
		config password pgBuddy bgcolor automessage emailBList tcl_platform

	set scrollidx [$pgBuddy.ys get]

	set my_name [urldecode [lindex $user_info 4]]
	set my_state_no [lsearch $list_states "$user_stat *"]
	set my_state [lindex $list_states $my_state_no]
	set my_state_desc [trans [lindex $my_state 1]]
	set my_colour [lindex $my_state 2]
	set my_image_type [lindex $my_state 5]

	#Clear every tag to avoid memory leaks:
	foreach tag [$pgBuddy.text tag names] {
		$pgBuddy.text tag delete $tag
	}

	# Decide which grouping we are going to use
	if {$config(orderbygroup)} {

		::groups::Enable

		#Order alphabetically
		set thelist [::groups::GetList]
		set thelistnames [list]

		foreach gid $thelist {
			set thename [::groups::GetName $gid]
			lappend thelistnames [list "$thename" $gid]
		}


		if {$config(ordergroupsbynormal)} {
			set sortlist [lsort -dictionary -index 0 $thelistnames ]
		} else {
			set sortlist [lsort -decreasing -dictionary -index 0 $thelistnames ]
		}

		set glist [list]

		foreach gdata $sortlist {
			lappend glist [lindex $gdata 1]
		}

		set gcnt [llength $glist]

		# Now setup each of the group's defaults
		for {set i 0} {$i < $gcnt} {incr i} {
			set gid [lindex $glist $i]
			::groups::UpdateCount $gid clear
		}

		if {$config(orderbygroup) == 2 } {
			lappend glist "offline"
			incr gcnt
		}

	} else {	# Order by Online/Offline
		# Defaults already set in setup_groups
		set glist [list online offline]
		set gcnt 2
		::groups::Disable
	}

	if { $config(showblockedgroup) == 1 && [llength [array names emailBList] ] != 0 } {
		lappend glist "blocked"
		incr gcnt
	}

	if { [::config::getKey emailsincontactlist] } {
		::MSN::sortContactList 2 0
	} else {
		::MSN::sortContactList 2 1
	}

	$pgBuddy.text configure -state normal -font splainf
	$pgBuddy.text delete 0.0 end

	#Set up TAGS for mail notification
	$pgBuddy.text tag conf mail -fore black -underline true -font splainf
	$pgBuddy.text tag bind mail <Button1-ButtonRelease> "$pgBuddy.text conf -cursor watch;hotmail_login [list $config(login)] [list $password]"
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
			#Specific for Mac OS X, Change button3 to button 2 and add control-click
			if {$tcl_platform(os) == "Darwin"} {
		$pgBuddy.text tag bind $gtag <Button2-ButtonRelease> \
			"tk_popup .group_menu %X %Y"
		$pgBuddy.text tag bind $gtag <Control-ButtonRelease> \
			"tk_popup .group_menu %X %Y"
			} else {
		$pgBuddy.text tag bind $gtag <Button3-ButtonRelease> \
			"tk_popup .group_menu %X %Y"
			}
			

			
		$pgBuddy.text tag bind $gtag <Enter> \
			"$pgBuddy.text tag conf $gtag -under true;$pgBuddy.text conf -cursor hand2"
		$pgBuddy.text tag bind $gtag <Leave> \
			"$pgBuddy.text tag conf $gtag -under false;$pgBuddy.text conf -cursor left_ptr"
	}

	$pgBuddy.text insert end "\n"

	# Display MSN logo with user's handle. Make it clickable so
	# that the user can change his/her status that way
	clickableImage $pgBuddy.text bigstate $my_image_type {tk_popup .my_menu %X %Y}
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
	if {$tcl_platform(os) == "Darwin"} {
	$pgBuddy.text.mystatus tag bind mystatus <Button2-ButtonRelease> "tk_popup .my_menu %X %Y"
	} else {
	$pgBuddy.text.mystatus tag bind mystatus <Button3-ButtonRelease> "tk_popup .my_menu %X %Y"
	}
	$pgBuddy.text.mystatus insert end "[trans mystatus]: " mystatuslabel

	if { [info exists automessage] && $automessage != -1} {
		$pgBuddy.text.mystatus insert end "[lindex $automessage 0]\n" mystatuslabel2
	} else {
		$pgBuddy.text.mystatus insert end "\n" mystatuslabel
	}

	set maxw [expr [winfo width $pgBuddy.text] -45]
	incr maxw [expr 0-[font measure bboldf -displayof $pgBuddy.text " ($my_state_desc)" ]]
	set my_short_name [trunc $my_name $pgBuddy.text.mystatus $maxw bboldf]
	$pgBuddy.text.mystatus insert end "$my_short_name " mystatus
	$pgBuddy.text.mystatus insert end "($my_state_desc)" mystatus

	set balloon_message "[string map {"%" "%%"} "$my_name \n $config(login) \n [trans status] : $my_state_desc"]"

	$pgBuddy.text.mystatus tag bind mystatus <Enter> +[list balloon_enter %W %X %Y $balloon_message]

	$pgBuddy.text.mystatus tag bind mystatus <Leave> \
		"+set Bulle(first) 0; kill_balloon"

	$pgBuddy.text.mystatus tag bind mystatus <Motion> +[list balloon_motion %W %X %Y $balloon_message]

	bind $pgBuddy.text.bigstate <Enter> +[list balloon_enter %W %X %Y $balloon_message]
	bind $pgBuddy.text.bigstate <Leave> \
		"+set Bulle(first) 0; kill_balloon;"
	bind $pgBuddy.text.bigstate <Motion> +[list balloon_motion %W %X %Y $balloon_message]


	#Calculate number of lines, and set my status size (for multiline nicks)
	set size [$pgBuddy.text.mystatus index end]
	set posyx [split $size "."]
	set lines [expr {[lindex $posyx 0] - 1}]
	if { [llength [$pgBuddy.text.mystatus image names]] } { incr lines }

	$pgBuddy.text.mystatus configure -state normal -height $lines -wrap none
	$pgBuddy.text.mystatus configure -state disabled

	$pgBuddy.text window create end -window $pgBuddy.text.mystatus -padx 6 -pady 0 -align bottom -stretch false
	$pgBuddy.text insert end "\n"

	#set width [expr {[winfo width $pgBuddy.text] - 10} ]
	set width [expr {[winfo width $pgBuddy.text]} - 1 ]

	if { $width < 160 } {
		set width 160
	}

	set barheight [image height colorbar]
	set barwidth [image width colorbar]

	image delete mainbar
	image create photo mainbar -width $width -height $barheight
	mainbar blank
	mainbar copy colorbar -from 0 0 5 $barheight
	mainbar copy colorbar -from 5 0 15 $barheight -to 5 0 [expr {$width - 150}] $barheight
	mainbar copy colorbar -from [expr {$barwidth - 150}] 0 $barwidth $barheight -to [expr {$width - 150}] 0 $width $barheight

	$pgBuddy.text image create end -image mainbar
	$pgBuddy.text insert end "\n"

	# Show Mail Notification status
	clickableImage $pgBuddy.text mailbox mailbox "hotmail_login [list $config(login)] [list $password]" 5 0

	set unread [::hotmail::unreadMessages]

	if { $unread == 0 } {
		set mailmsg "[trans nonewmail]\n"
	} elseif {$unread == 1} {
		set mailmsg "[trans onenewmail]\n"
	} elseif {$unread == 2} {
		set mailmsg "[trans twonewmail 2]\n"
	} else {
		set mailmsg "[trans newmail $unread]\n"
	}

	set maxw [expr [winfo width $pgBuddy.text] -30]
	set short_mailmsg [trunc $mailmsg $pgBuddy.text $maxw splainf]
	$pgBuddy.text insert end "$short_mailmsg\n" mail
	$pgBuddy.text tag add dont_replace_smileys mail.first mail.last

	# For each named group setup its heading where >><< image
	# appears together with the group name and total nr. of handles
	# [<<] My Group Name (n)
	for {set gidx 0} {$gidx < $gcnt} {incr gidx} {

		set gname [lindex $glist $gidx]
		set gtag  "tg$gname"

		if { [::groups::IsExpanded $gname] } {
			toggleGroup $pgBuddy.text contract$gname contract $gname 5 0
		} else {
			toggleGroup $pgBuddy.text expand$gname expand $gname 5 0
		}

		# Show the group's name/title
		if {$config(orderbygroup)} {

			# For user defined groups we don't have/need translations
			set gtitle [::groups::GetName $gname]

			if { $config(orderbygroup) == 2 } {
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
			} elseif { $config(showblockedgroup) == 1 && [llength [array names emailBList] ] != 0 } {
				$pgBuddy.text insert end "[trans youblocked]" blocked
			}

		}
		$pgBuddy.text insert end "\n"
	}

	::groups::UpdateCount online clear
	::groups::UpdateCount offline clear
	::groups::UpdateCount blocked clear

	#Draw the users in each group
	foreach user $list_users {

		set user_login [lindex $user 0]
		set user_name [lindex $user 1]
		set user_state_no [lindex $user 2]
		set state [lindex $list_states $user_state_no]
		set state_code [lindex $state 0]

		set colour [lindex $state 2]
		set section [lindex $state 3]; # Used in online/offline grouping

		if { $section == "online"} {
			::groups::UpdateCount online +1
		} elseif {$section == "offline"} {
			::groups::UpdateCount offline +1
		}


		set breaking ""

		if { $config(orderbygroup) } {
			foreach user_group [::abook::getGroup $user_login -id] {
				set section "tg$user_group"

				if { $section == "tgblocked" } {set section "blocked" }

				::groups::UpdateCount $user_group +1 [lindex $state 3]

				if { $config(orderbygroup) == 2 } {
					if { $state_code == "FLN" } { set section "offline"}
					if { $breaking == "$user_login" } { continue }
				}

				set myGroupExpanded [::groups::IsExpanded $user_group]

				if { $config(orderbygroup) == 2 } {
					if { $state_code == "FLN" } {
						set myGroupExpanded [::groups::IsExpanded offline]
					}
				}

				if {$myGroupExpanded} {
					ShowUser $user_name $user_login $state $state_code $colour $section $user_group
				}

				#Why "breaking"? Why not just a break? Or should we "continue" instead of breaking?
				if { $config(orderbygroup) == 2 && $state_code == "FLN" } { set breaking $user_login}

			}
		} elseif {[::groups::IsExpanded $section]} {
			ShowUser $user_name $user_login $state $state_code $colour $section 0
		}

		if { $config(showblockedgroup) == 1 && [info exists emailBList($user_login)]} {
			::groups::UpdateCount blocked +1
			if {[::groups::IsExpanded blocked]} {
				ShowUser $user_name $user_login $state $state_code $colour "blocked" [lindex [::abook::getGroup $user_login -id] 0]
			}
		}
	}

	if {$config(orderbygroup)} {
		for {set gidx 0} {$gidx < $gcnt} {incr gidx} {
			set gname [lindex $glist $gidx]
			set gtag  "tg$gname"
			if {$config(orderbygroup) == 2 } {
				if { $gname == "offline" } {
					$pgBuddy.text insert offline.last " ($::groups::uMemberCnt(offline))\n" offline
					$pgBuddy.text tag add dont_replace_smileys offline.first offline.last
				} elseif { $gname == "blocked" } {
					$pgBuddy.text insert blocked.last " ($::groups::uMemberCnt(blocked))\n" blocked
					$pgBuddy.text tag add dont_replace_smileys blocked.first blocked.last
				} else {
					$pgBuddy.text insert ${gtag}.last \
						" ($::groups::uMemberCnt_online(${gname}))\n" $gtag
					$pgBuddy.text tag add dont_replace_smileys $gtag.first $gtag.last
				}
			} else {
				if { $gname == "blocked" } {
					$pgBuddy.text insert blocked.last " ($::groups::uMemberCnt(blocked))\n" blocked
					$pgBuddy.text tag add dont_replace_smileys blocked.first blocked.last
				} else {
					$pgBuddy.text insert ${gtag}.last \
						" ($::groups::uMemberCnt_online(${gname})/$::groups::uMemberCnt($gname))\n" $gtag
					$pgBuddy.text tag add dont_replace_smileys $gtag.first $gtag.last
				}
			}
		}
	} else {
		$pgBuddy.text insert online.last " ($::groups::uMemberCnt(online))\n" online
		$pgBuddy.text insert offline.last " ($::groups::uMemberCnt(offline))\n" offline
		$pgBuddy.text tag add dont_replace_smileys online.first online.last
		$pgBuddy.text tag add dont_replace_smileys offline.first offline.last

		if { $config(showblockedgroup) == 1 && [llength [array names emailBList]] } {
			$pgBuddy.text insert blocked.last " ($::groups::uMemberCnt(blocked))\n" blocked
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
	if {$config(listsmileys)} {
		smile_subst $pgBuddy.text.mystatus
		smile_subst $pgBuddy.text 0.0 end
	}
	update idletasks
	$pgBuddy.ys set [lindex $scrollidx 0] [lindex $scrollidx 1]
	$pgBuddy.text yview moveto [lindex $scrollidx 0]



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
proc ShowUser {user_name user_login state state_code colour section grId} {
    global list_bl list_rl pgBuddy alarms emailBList Bulle config tcl_platform

         if {($state_code != "NLN") && ($state_code !="FLN")} {
            set state_desc " ([trans [lindex $state 1]])"
	 } else {
            set state_desc ""
         }

	 set user_unique_name "$user_login[getUniqueValue]"

	 # If user is not in the Reverse List it means (s)he has not
	 # yet added/approved us. Show their name in pink. A way
	 # of knowing how has a) not approved you yet, or b) has
	 # removed you from their contact list even if you still
	 # have them...
         if {[lsearch $list_rl "$user_login *"] == -1} {
	     set colour #DD00DD
	 }

         set image_type [lindex $state 4]


         if { [info exists emailBList($user_login)]} {
        	set colour #FF0000
	        set image_type "blockedme"
         }

       
         if {[lsearch $list_bl "$user_login *"] != -1} {
            set image_type "blocked"
      	    if {$state_desc == ""} {set state_desc " ([trans blocked])"}
         }
           $pgBuddy.text tag conf $user_unique_name -fore $colour


         $pgBuddy.text mark set new_text_start end
	 #set user_name [stringmap {"\n" "\n           "} $user_name]

	 if { [::config::getKey emailsincontactlist] } {
	 	set user_lines "$user_login"
	 } else {
	 	set user_lines [split $user_name "\n"]
	 }
	 set last_element [expr {[llength $user_lines] -1 }]

	 $pgBuddy.text insert $section.last " $state_desc \n" $user_unique_name
	 
	#Set maximum width for nick string, with some margin
	set maxw [winfo width $pgBuddy.text]
	incr maxw -20
	#Decrement status text out of max line width
	set statew [font measure splainf -displayof $pgBuddy.text " $state_desc "]
	set blanksw [font measure splainf -displayof $pgBuddy.text "      "]
	incr maxw [expr {-25-$statew-$blanksw}]
	if { [info exists alarms(${user_login})] } {
		incr maxw -25
	}
	 
	 for {set i $last_element} {$i >= 0} {set i [expr {$i-1}]} {
	    if { $i != $last_element} {
	       set current_line " [lindex $user_lines $i]\n"
	    } else {
	       set current_line " [lindex $user_lines $i]"
	    }
	    
        if {$config(truncatenames)} {
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
	       $pgBuddy.text insert $section.last "      "
	    }
	 }
         #$pgBuddy.text insert $section.last " $user_name$state_desc \n" $user_login

#	Draw alarm icon if alarm is set
	if { [info exists alarms(${user_login})] } {
	    #set imagee [string range [string tolower $user_login] 0 end-8]
	    #trying to make it non repetitive without the . in it
	    #Patch from kobasoft
	    set imagee "alrmimg_[getUniqueValue]"
	    #regsub -all "\[^\[:alnum:\]\]" [string tolower $user_login] "_" imagee

	    if { $alarms(${user_login}) == 1 } {
  	 	label $pgBuddy.text.$imagee -image bell
 	    } else {
		label $pgBuddy.text.$imagee -image belloff
            }

	    $pgBuddy.text.$imagee configure -cursor hand2 -borderwidth 0
            $pgBuddy.text window create $section.last -window $pgBuddy.text.$imagee  -padx 1 -pady 1
	    bind $pgBuddy.text.$imagee <Button1-ButtonRelease> "switch_alarm $user_login $pgBuddy.text.$imagee"

	    bind $pgBuddy.text.$imagee <<Button3>> "alarm_cfg $user_login"

	}


	 #set imgname "img[expr {$::groups::uMemberCnt(online)+$::groups::uMemberCnt(offline)}]"
	 set imgname "img[getUniqueValue]"
	label $pgBuddy.text.$imgname -image $image_type
	$pgBuddy.text.$imgname configure -cursor hand2 -borderwidth 0
	if { $last_element > 0 } {
		$pgBuddy.text window create $section.last -window $pgBuddy.text.$imgname -padx 3 -pady 1 -align baseline
	} else {
		$pgBuddy.text window create $section.last -window $pgBuddy.text.$imgname -padx 3 -pady 1 -align center
	}

    $pgBuddy.text insert $section.last "      "


    $pgBuddy.text tag bind $user_unique_name <Enter> \
	    "$pgBuddy.text tag conf $user_unique_name -under true; $pgBuddy.text conf -cursor hand2"

    $pgBuddy.text tag bind $user_unique_name <Leave> \
	    "$pgBuddy.text tag conf $user_unique_name -under false;	$pgBuddy.text conf -cursor left_ptr"

    bind $pgBuddy.text.$imgname <Enter> \
	    "$pgBuddy.text tag conf $user_unique_name -under true; $pgBuddy.text conf -cursor hand2"
    bind $pgBuddy.text.$imgname <Leave> \
	    "$pgBuddy.text tag conf $user_unique_name -under false;	$pgBuddy.text conf -cursor left_ptr"


    if { $config(tooltips) == 1 } {

	set balloon_message "[string map {"%" "%%"} $user_name] \n $user_login \n [trans status] : [trans [lindex $state 1]] "

	$pgBuddy.text tag bind $user_unique_name <Enter> +[list balloon_enter %W %X %Y $balloon_message]

	$pgBuddy.text tag bind $user_unique_name <Leave> \
	    "+set Bulle(first) 0; kill_balloon"

	$pgBuddy.text tag bind $user_unique_name <Motion> +[list balloon_motion %W %X %Y $balloon_message]

	bind $pgBuddy.text.$imgname <Enter> +[list balloon_enter %W %X %Y $balloon_message]
	bind $pgBuddy.text.$imgname <Leave> \
	    "+set Bulle(first) 0; kill_balloon"

	bind $pgBuddy.text.$imgname <Motion> +[list balloon_motion %W %X %Y $balloon_message]

    }
#Change mouse button and add control-click on Mac OS X
if {$tcl_platform(os) == "Darwin"} {
         $pgBuddy.text tag bind $user_unique_name <Button2-ButtonRelease> "show_umenu $user_login $grId %X %Y"
         $pgBuddy.text tag bind $user_unique_name <Control-ButtonRelease> "show_umenu $user_login $grId %X %Y"
	} else {
          $pgBuddy.text tag bind $user_unique_name <Button3-ButtonRelease> "show_umenu $user_login $grId %X %Y"
     }
bind $pgBuddy.text.$imgname <<Button3>> "show_umenu $user_login $grId %X %Y"

            bind $pgBuddy.text.$imgname <Double-Button-1> "::amsn::chatUser $user_login"
            $pgBuddy.text tag bind $user_unique_name <Double-Button-1> \
	        "::amsn::chatUser $user_login"

}
#///////////////////////////////////////////////////////////////////////

proc balloon_enter {window x y msg} {
	global Bulle
	#"+set Bulle(set) 0;set Bulle(first) 1; set Bulle(id) \[after 1000 [list balloon %W [list $balloon_message)] %X %Y]\]"
	set Bulle(set) 0
	set Bulle(first) 1
	set Bulle(id) [after 1000 [list balloon $window $msg $x $y]]
}

proc balloon_motion {window x y msg} {
	global Bulle
	#"if {\[set Bulle(set)\] == 0} \{after cancel \[set Bulle(id)\]; \
   #         set Bulle(id) \[after 1000 [list balloon %W [list $balloon_message] %X %Y]\]\} "
	if {[set Bulle(set)] == 0} {
		after cancel [set Bulle(id)]
		set Bulle(id) [after 1000 [list balloon $window $msg $x $y]]
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
	global config
	if { $window == "" || $font == "" || $config(truncatenames)!=1} {
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
	set window $w.f.bottom.in.input

	if { [ catch {$window tag ranges sel}]} {
	   set window $w
	}

	set index [$window tag ranges sel]

	if { $index == "" } {
		set window $w.f.out.text
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
	    $window.f.bottom.in.input insert insert $contents
	}
	#puts "CLIPBOARD selection enabled"
    } else {
	if { $middle == 0} {
	    catch {
		set contents [ selection get -selection CLIPBOARD ]
		$window.f.bottom.in.input insert insert $contents
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
   global addcontact_request lang

   if {[info exists addcontact_request]} {
      raise .addcontact
      return 0
   }

   set addcontact_request true
   toplevel .addcontact -width 400 -height 150
   wm group .addcontact .
   bind .addcontact <Destroy> {
      if {"%W" == ".addcontact"} {
         unset addcontact_request
      }
   }

#   wm geometry .addcontact -0+100
   wm title .addcontact "[trans addacontact] - [trans title]"
#   wm transient .addcontact .
   canvas .addcontact.c -width 320 -height 160
   pack .addcontact.c -expand true -fill both

   entry .addcontact.c.email -width 30 -bg #FFFFFF -bd 1 \
      -font splainf
   button .addcontact.c.next -text "[trans next]->" \
     -command addcontact_next -font sboldf
   button .addcontact.c.cancel -text [trans cancel]  \
      -command "grab release .addcontact;destroy .addcontact" -font sboldf

   .addcontact.c create text 5 10 -font sboldf -anchor nw \
	-text "[trans entercontactemail]:"
   .addcontact.c create text 80 60 -font examplef -anchor ne \
         -text "[trans examples]: "
   .addcontact.c create text 80 60 -font examplef -anchor nw \
         -text "copypastel@hotmail.com\nelbarney@msn.com\nexample@passport.com"
   .addcontact.c create window 5 35 -window .addcontact.c.email -anchor nw
   .addcontact.c create window 195 120 -window .addcontact.c.next -anchor ne
   .addcontact.c create window 205 120 -window .addcontact.c.cancel -anchor nw

   bind .addcontact.c.email <Return> "addcontact_next"
   focus .addcontact.c.email

#   tkwait visibility .addcontact
#   grab set .addcontact
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc addcontact_next {} {
   set tmp_email [.addcontact.c.email get]
   if { $tmp_email != ""} {
      ::MSN::addUser "$tmp_email"
      grab release .addcontact
      destroy .addcontact
   }
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_draw_otherwindow { title command } {

##hehe, here it's, nearly done ;)

   global lang

   toplevel .otherwindow -width 300 -height 100
   wm group .otherwindow .

   wm title .otherwindow "$title"
   canvas .otherwindow.c -width 270 -height 100
   pack .otherwindow.c -expand true -fill both

   entry .otherwindow.c.email -width 30 -bg #FFFFFF -bd 1 \
      -font splainf
   button .otherwindow.c.next -text "[trans ok]" \
     -command "run_command_otherwindow \"$command\"" -font sboldf
   button .otherwindow.c.cancel -text [trans cancel]  \
      -command "grab release .otherwindow;destroy .otherwindow" -font sboldf

   .otherwindow.c create text 5 10 -font sboldf -anchor nw \
	-text "[trans entercontactemail]:"
   .otherwindow.c create window 5 35 -window .otherwindow.c.email -anchor nw
   .otherwindow.c create window 163 65 -window .otherwindow.c.next -anchor ne
   .otherwindow.c create window 173 65 -window .otherwindow.c.cancel -anchor nw

   bind .otherwindow.c.email <Return> "run_command_otherwindow \"$command\""
   focus .otherwindow.c.email

   tkwait visibility .otherwindow
}
#///////////////////////////////////////////////////////////////////////







#///////////////////////////////////////////////////////////////////////
proc newcontact {new_login new_name} {
   global list_fl newc_allow_block tcl_platform

   set newc_allow_block "1"

   if {[lsearch $list_fl "$new_login *"] != -1} {
      set add_stat "disabled"
      set newc_add_to_list 0
   } else {
      set add_stat "normal"
      set newc_add_to_list 1
   }

    set login [split $new_login "@ ."]
    set login [join $login "_"]
    set wname ".newc_$login"

    if { [catch {toplevel ${wname} } ] } {
	return 0
    }
    wm group ${wname} .

    wm geometry ${wname} -0+100
    wm title ${wname} "$new_name - [trans title]"
    

    #ShowTransient ${wname}
    canvas ${wname}.c -width 500 -height 150
    pack ${wname}.c -expand true -fill both

   button ${wname}.c.ok -text [trans ok]  -font sboldf \
       -command "set newc_exit OK; newcontact_ok \"OK\" \$newc_add_to_list \"$new_login\" [list $new_name];destroy ${wname}"
   button ${wname}.c.cancel -text [trans cancel]  -font sboldf \
      -command "newcontact_ok \"CANCEL\" 0 \"$new_login\" [list $new_name];destroy ${wname}"

  radiobutton ${wname}.c.allow  -value "1" -variable newc_allow_block \
     -text [trans allowseen] \
      -highlightthickness 0 \
     -activeforeground #FFFFFF -selectcolor #FFFFFF -font sboldf
  radiobutton ${wname}.c.block -value "0" -variable newc_allow_block \
     -text [trans avoidseen] \
      -highlightthickness 0 \
     -activeforeground #FFFFFF -selectcolor #FFFFFF  -font sboldf
   checkbutton ${wname}.c.add -var newc_add_to_list -state $add_stat \
      -text [trans addtoo] -font sboldf \
      -highlightthickness 0 -activeforeground #FFFFFF -selectcolor #FFFFFF

   ${wname}.c.add select

   ${wname}.c create text 30 5 -font splainf -anchor nw -justify left \
        -text "[trans addedyou $new_name $new_login]" \
        -width 460
   ${wname}.c create text 30 40 -font splainf -anchor nw \
        -text "[trans youwant]:"
   ${wname}.c create window 40 58 -window ${wname}.c.allow -anchor nw
   ${wname}.c create window 40 76 -window ${wname}.c.block -anchor nw
   ${wname}.c create window 30 94 -window ${wname}.c.add -anchor nw
   ${wname}.c create window 245 120 -window ${wname}.c.ok -anchor ne
   ${wname}.c create window 255 120 -window ${wname}.c.cancel -anchor nw

    bind ${wname} <Destroy> "newcontact_ok \"DESTROY\" 0 \"$new_login\" [list $new_name]"
#   tkwait visibility ${wname}
#   grab set ${wname}
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc cmsn_change_name {} {
	global user_info tcl_platform

	if {[winfo exists .change_name]} {
		raise .change_name
		return 0
	}

	toplevel .change_name
	wm group .change_name .
	wm geometry .change_name -0+100
	wm title .change_name "[trans changenick] - [trans title]"

    #ShowTransient .change_name

	label .change_name.label -font sboldf -text "[trans enternick]:"

	frame .change_name.fn
	entry .change_name.fn.name -width 40 -bg #FFFFFF -bd 1 -font splainf
	button .change_name.fn.smiley -image butsmile -relief flat -padx 3 -highlightthickness 0

	frame .change_name.fb
	button .change_name.fb.ok -text [trans ok] -command change_name_ok -font sboldf
	button .change_name.fb.cancel -text [trans cancel] -command "destroy .change_name" -font sboldf


	pack .change_name.fn.name -side left -fill x -expand true
	pack .change_name.fn.smiley -side left

	pack .change_name.fb.ok -side left -padx 10
	pack .change_name.fb.cancel -side left -padx 10

	pack .change_name.label -side top -padx 5 -pady 3 -expand true
	pack .change_name.fn -side top -fill x -expand true -padx 5
	pack .change_name.fb -side top -pady 3 -expand true

   bind .change_name.fn.name <Return> "change_name_ok"
   bind .change_name.fn.smiley  <Button1-ButtonRelease> "smile_menu %X %Y .change_name.fn.name"

   .change_name.fn.name insert 0 [urldecode [lindex $user_info 4]]

   tkwait visibility .change_name
}

#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc change_name_ok {} {
   global config

   set new_name [.change_name.fn.name get]
   if {$new_name != ""} {
		if { [string length $new_name] > 130} {
			set parent .change_name
			set answer [tk_messageBox -message [trans longnick] -type yesno -icon question -title [trans confirm] -parent $parent]
			if { $answer != "yes" } {
				return
			}
		}
      ::MSN::changeName $config(login) $new_name 0

   }
   destroy .change_name
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc Fill_users_list { path path2} {
    global list_rl list_users list_bl list_al emailBList

 
    # clearing the list boxes from there content
    $path.allowlist.box delete 0 end
    $path.blocklist.box delete 0 end
    $path2.contactlist.box delete 0 end
    $path2.reverselist.box delete 0 end


    foreach user $list_al {
	$path.allowlist.box insert end [lindex $user 1]
	set user [lindex $user 0]
	if {[lsearch $list_rl "$user *"] == -1} {
	    set colour #FF00FF
	} else {
	    set colour #FFFFFF
	}

	$path.allowlist.box itemconfigure end -background $colour
    }

    foreach user $list_bl {
	$path.blocklist.box insert end [lindex $user 1] 
	set user [lindex $user 0]
	if {[lsearch $list_rl "$user *"] == -1} {
	    set colour #FF00FF
	} else {
	    set colour #FFFFFF
	}

	$path.blocklist.box itemconfigure end -background $colour
    }

    foreach user $list_users {
	$path2.contactlist.box insert end [lindex $user 1]
	set user [lindex $user 0]
	
	if {[lsearch $list_rl "$user *"] == -1} {
	    set colour #FF00FF
	} elseif { [info exists emailBList($user)]} {
	    set colour #FF0000
	} else {
	    set colour #FFFFFF
	}

	$path2.contactlist.box itemconfigure end -background $colour
    }


    foreach user $list_rl {
	$path2.reverselist.box insert end [lindex $user 1]
	set user [lindex $user 0]
	if {[lsearch $list_users "$user *"] == -1} {
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

	set user [NickToEmail "$user" $list]

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
	$path.${list}popup add command -label "[trans properties]" -command "::abookGui::showEntry $user"
	
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
    global list_rl list_users

    if { [VerifySelect $path "reverse"] } {

	$path.status configure -text ""

	set user [$path.reverselist.box get active]

	set user [NickToEmail "$user" "reverse"]

	AddToContactList "$user" "$path"

    }

}

proc Remove_Contact { path } {

    if { [$path.contactlist.box curselection] == "" } {
	$path.status configure -text "[trans choosecontact]"
    }  else {

	$path.status configure -text ""

	set user [$path.contactlist.box get active]

	set user [NickToEmail "$user" "contact"]

	Remove_from_list "contact" $user
    }
}

proc Allow_to_Block { path } {
    global list_rl list_users

    if { [VerifySelect $path "allow"] } {

	$path.status configure -text ""

	set username [$path.allowlist.box get active]

	set user [NickToEmail "$username" "allow"]

	::MSN::blockUser "$user" [urlencode $username]

    }

}

proc Block_to_Allow  { path } {
    global list_rl list_users

    if { [VerifySelect $path "block"] } {

	$path.status configure -text ""

	set username [$path.blocklist.box get active]

	set user [NickToEmail "$username" "block"]

	::MSN::unblockUser "$user" [urlencode $username]

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

proc NickToEmail { nick list } {
    global list_users list_rl list_al list_bl

    if { "$list" == "contact" } {
	foreach  tmp $list_users {
	    if { "[lindex $tmp 1]" == "$nick" } {
		set user [lindex $tmp 0]
		return "$user"
	    } 
	}
    } elseif { "$list" == "reverse" } {
	foreach  tmp $list_rl {
	    if { "[lindex $tmp 1]" == "$nick" } {
		set user [lindex $tmp 0]
		return "$user"
	    } 
	}
    } elseif { "$list" == "allow" } {
	foreach  tmp $list_al {
	    if { "[lindex $tmp 1]" == "$nick" } {
		set user [lindex $tmp 0]
		return "$user"
	    } 
	}
    } elseif { "$list" == "block" } {
	foreach  tmp $list_bl {
	    if { "[lindex $tmp 1]" == "$nick" } {
	    set user [lindex $tmp 0]
		return "$user"
	    } 
	}
    }

    return ""

}

proc NotInContactList { user } {
    global list_users
    
    if {[lsearch $list_users "$user *"] == -1} {
	return 1
    } else {
	return 0
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
proc launch_browser { url } {

	global config tcl_platform

	if { [string tolower [string range $url 0 6]] != "http://" } {
		set url "http://$url"
	}

	status_log "url is $url\n"

	#status_log "Launching browser for url: $url\n"
	if { $tcl_platform(platform) == "windows" } {

		#regsub -all -nocase {htm} $url {ht%6D} url
		regsub -all -nocase {&} $url {^&} url
    		catch { exec rundll32 url.dll,FileProtocolHandler $url & } res

  	} else {

		if { [string first "\$url" $config(browser)] == -1 } {
			set config(browser) "$config(browser) \$url"
		}

		#if { [catch {eval exec $config(browser) [list $url] &} res ] } {}
		#status_log "Launching $config(browser)\n"		
		if { [catch {eval exec $config(browser) &} res ] } {
		   ::amsn::errorMsg "[trans cantexec $config(browser)]"
		}

	}

}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
# launch_filemanager(directory)
# Launches the configured file manager
proc launch_filemanager {location} {
  global config

  if { [string length $config(filemanager)] < 1 } {
    msg_box "[trans checkfilman $location]"
  } else {
		if { [string first "\$location" $config(filemanager)] == -1 } {
			set config(filemanager) "$config(filemanager) \$location"
		}


    if {[catch {eval exec $config(filemanager) &} res]} {
       ::amsn::errorMsg "[trans cantexec $config(filemanager)]"
    }
  }

}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
# launch_mailer(directory)
# Launches the configured mailer program
proc launch_mailer {recipient} {
  global config password

  if {[string length $config(mailcommand)]==0} {
     ::hotmail::composeMail $recipient $config(login) $password
     return 0
  }

	if { [string first "\$recipient" $config(mailcommand)] == -1 } {
		set config(mailcommand) "$config(mailcommand) \$recipient"
	}


  if { [catch {eval exec $config(mailcommand) &} res]} {
     ::amsn::errorMsg "[trans cantexec $config(mailcommand)]"
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
   }
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
# timestamp()
# Returns a timestamp like [HH:MM:SS]
proc timestamp {} {
	global config
	set stamp [clock format [clock seconds] -format %H:%M:%S]
	return $config(leftdelimiter)$stamp$config(rightdelimiter)
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////////////
# status_log (text,[color])
# Logs the given text with a timestamp using the given color
# to the status window
proc status_log {txt {colour ""}} {
    global followtext_status

   .status.info insert end "[timestamp] $txt" $colour
   #puts "[timestamp] $txt"
   if { $followtext_status == 1 } {
       .status.info yview moveto 1.0
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
  global HOME config lockSock tcl_platform
  set config(wingeometry) [wm geometry .]

  save_config
  save_alarms   ;# Save alarm settings

  LoadLoginList 1
  # Unlock current profile
  LoginList changelock 0 $config(login) 0
  if { [info exists lockSock] } {
  	if { $lockSock != 0 } {
		catch {close $lockSock} res
	}
  }
  SaveLoginList
  SaveStateList
  
	#Kill soundplayer when we quit aMSN-Mac (sometime he stay open and eat your CPU)
	if { $tcl_platform(os) == "Darwin" } {
		catch {exec killall -c sndplay}
	}
  
  catch {::MSN::logout}
  
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
   global idletime config oldmousepos trigger autostatuschange

   set mousepos [winfo pointerxy .]
   if { $mousepos != $oldmousepos } {
      set oldmousepos $mousepos
      set idletime 0
   }


        # Check for empty fields and use 5min by default
        if {$config(awaytime) == ""} {
                set config(awaytime) 10
        }

        if {$config(idletime) == ""} {

                set config(idletime) 5
        }


   # TODO: According to preferences, this is always true
   if { $config(awaytime) >= $config(idletime) } {
	set first [expr {$config(awaytime) * 60}]
	set firstvar "autoaway"
	set firststate "AWY"
	set second [expr $config(idletime) * 60]
	set secondvar "autoidle"
	set secondstate "IDL"
   } else {
	set second [expr {$config(awaytime) * 60}]
	set secondvar "autoaway"
	set secondstate "AWY"
	set first [expr {$config(idletime) * 60}]
	set firstvar "autoidle"
	set firststate "IDL"
   }

   if { $idletime >= $first && $config(autoaway) == 1 && \
        (([::MSN::myStatusIs] == "IDL" && $autostatuschange == 1) || \
        ([::MSN::myStatusIs] == "NLN"))} {
      #We change to Away if time has passed, and if IDL was set automatically
      ::MSN::changeStatus AWY
      set autostatuschange 1
   } elseif {$idletime >= $second && [::MSN::myStatusIs] == "NLN" && $config(autoidle) == 1} {
   	#We change to idle if time has passed and we're online
	::MSN::changeStatus IDL
	set autostatuschange 1
   } elseif { $idletime == 0 && $autostatuschange == 1} {
   	#We change to only if mouse movement, and status change was automatic
	::MSN::changeStatus NLN
	#Status change always resets automatic change to 0
   }

   set idletime [expr {$idletime + 5}]
   after 5000 idleCheck
}
#///////////////////////////////////////////////////////////////////////


#///////////////////////////////////////////////////////////////////////
proc choose_theme { } {
    global config
    setColor . . background {-background -highlightbackground}
}
#///////////////////////////////////////////////////////////////////////



#///////////////////////////////////////////////////////////////////////
proc setColor {w button name options} {
    global config

    grab $w
    set initialColor [$button cget -$name]
    set color [tk_chooseColor -title "[trans choosebgcolor]" -parent $w \
	-initialcolor $initialColor]
    if { $color != "" } {
        set config(backgroundcolor) $color
	::themes::ApplyDeep $w $options $color
    }
    grab release $w
}
#///////////////////////////////////////////////////////////////////////






#///////////////////////////////////////////////////////////////////////
proc show_umenu {user_login grId x y} {
   global list_bl config alarms

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

      ::groups::updateMenu menu .move_group_menu ::groups::menuCmdMove [list $grId $user_login]
      ::groups::updateMenu menu .copy_group_menu ::groups::menuCmdCopy $user_login


   if {$config(orderbygroup)} {
      .user_menu add command -label "[trans movetogroup]..." -command "tk_popup .move_group_menu $x $y"
      .user_menu add command -label "[trans copytogroup]..." -command "tk_popup .copy_group_menu $x $y"
      .user_menu add command -label "[trans delete]" -command "::amsn::deleteUser ${user_login} $grId"
   } else {
       .user_menu add command -label "[trans movetogroup]..." -command "tk_popup .move_group_menu $x $y" -state disabled
       .user_menu add command -label "[trans copytogroup]..." -command "tk_popup .copy_group_menu $x $y" -state disabled
       .user_menu add command -label "[trans delete]" -command "::amsn::deleteUser ${user_login}"
   }

   .user_menu add command -label "[trans properties]" \
      -command "::abookGui::showEntry $user_login"

# Display Alarm Config settings
   .user_menu add separator
   .user_menu add command -label "[trans cfgalarm]" -command "alarm_cfg ${user_login}"

   tk_popup .user_menu $x $y
}
#///////////////////////////////////////////////////////////////////////



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
	    if { $newer == 1} {
		msg_box "[trans newveravailable $tmp_data]\n$weburl"
	    }
	    
	    
	} else {
	    catch {status_log "check_web_ver: status=[::http::status $token] ncode=[::http::ncode $token]\n" blue}
	    
	}
    ::http::cleanup $token

	return $newer
}
#///////////////////////////////////////////////////////////////////////

#///////////////////////////////////////////////////////////////////////
proc check_version {} {
	global weburl tcl_platform

   toplevel .checking

   wm title .checking "[trans title]"
   ShowTransient .checking
   canvas .checking.c -width 250 -height 50
   pack .checking.c -expand true -fill both

   .checking.c create text 125 25 -font splainf -anchor n \
	-text "[trans checkingver]..." -justify center -width 250

   tkwait visibility .checking
   grab .checking

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
	set tmp [.otherwindow.c.email get]
	if { $tmp != "" } {
		eval $command $tmp
		destroy .otherwindow
	}
}
#///////////////////////////////////////////////////////////////////////




#///////////////////////////////////////////////////////////////////////
# stringmap(substlist,string) returns string
# A try to replace "string map" function
proc stringmap { substitution str } {



	return [string map $substitution $str]

	set newstr $str

	set pos [expr {[string first [lindex $substitution 0] $newstr] -1}]

	while { $pos > -1 } {
		set end [expr {$pos + [string length [lindex $substitution 0]]}]
		set newstr "[string range $newstr 0 $pos] [lindex $substitution 1][string range $newstr [expr {$end+1}] end]"
		set pos [expr {[string first [lindex $substitution 0] $newstr] -1}]
	}


	return $newstr
}


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
	    
	    wm title .bossmode "Clock"

	    label .bossmode.time -text ""
	    
	    updatebossmodetime
	    
	    pack .bossmode.time
	    
	    bind .bossmode <Destroy> "after cancel updatebossmodetime; BossMode"
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


    } elseif { $bossMode == 1 } {
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
    }



}

proc updatebossmodetime { } {

    .bossmode.time configure -text "[string map { \" "" } [clock format [clock seconds] -format \"%T\"]]"
	#" Just to fix some editos syntax hilighting
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

proc convert_image { filename size } {

global tcl_platform


	if { ![file exists $filename] } {
		status_log "Tring to convert file $filename that does not exist\n" error
		return ""
	}

	set filename2 [filenoext $filename]

	status_log "converting $filename to $filename.gif with size $size\n"

	#IMPORTANT: If convertpath is blank, set it to "convert"
	if { [::config::getKey convertpath] == "" } {
		::config::setKey convertpath "convert"
	}

	#First converstion, no size, only .gif
	if { [catch { exec [::config::getKey convertpath] "${filename}" "${filename}.gif" } res] } {
		status_log "CONVERT ERROR IN CONVERSION 1: $res" white
		catch {[file delete $filename]}
		return ""
	}

	set img [image create photo -file "${filename}.gif"]
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
		catch { file delete ${filename}.gif}
		if { [catch { exec [::config::getKey convertpath] "${filename}" -resize "${resizew}x${resizeh}" "${filename}.gif" } res] } {
			status_log "CONVERT ERROR IN CONVERSION 2: $res" white
			catch {[file delete ${filename}]}
			return ""
		}
	}


	
	if { [file exists $filename2.png.0] } {
		set idx 1
		while { 1 } {
			if { [file exists $filename2.png.$idx] } {
				file delete $filename2.png.$idx
				incr idx
	    	} else { break }
		}
		file rename $filename2.png.0 $filename2.png
	}

	file delete ${filename}

 
	#Now let's crop image, from the center
   set img [image create photo -file "${filename}.gif"]
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
	 
	#Won't use convert to avoid the .png.0 .png.1... problem
	#if { [catch { exec convert "${filename}.gif" -gravity Center -crop "[lindex $sizexy 0]x[lindex $sizexy 1]" "${filename2}.gif" } res] } {
	#	msg_box "[trans installconvert]"
	#	status_log "converting returned error : $res\n"
	#	return 0
	#}

	set neww [image width $img]
	set newh [image height $img]
	status_log "Resized image size is $neww $newh\n" blue

	status_log "Center of image is $centerx,$centery, will crop from $x1,$y1 to $x2,$y2 \n" blue
	$img write "${filename2}.gif" -from $x1 $y1 $x2 $y2
	image delete $img
	
	catch {file delete ${filename}.gif}

	if { [catch { exec [::config::getKey convertpath] "${filename2}.gif"  "${filename2}.png"}] } {
		status_log "CONVERT ERROR IN CONVERSION 3: $res" white
		catch {[file delete ${filename2}.gif]}
		return ""
	}

	if { [file exists $filename2.png.0] } {
		set idx 1
		while { 1 } {
			if { [file exists $filename2.png.$idx] } {
				file delete $filename2.png.$idx
				incr idx
	    	} else { break }
		}
		file delete $filename2.png
		file rename $filename2.png.0 $filename2.png
	}


	return ${filename2}.png

}


proc convert_image_plus { filename type size } {

    global HOME


    catch {
	create_dir [file join $HOME $type]
	file copy $filename [file join $HOME $type]
	status_log "Copied $filename to [file join $HOME $type]\n"
    }

    set endfile [getfilename $filename]

    set file [convert_image [GetSkinFile $type $endfile] $size]

    if { $file == "" } { return ""}


    return $file
}


proc convert_display_picture { filename } {

	global HOME


	catch {
		create_dir [file join $HOME displaypic]
		file copy $filename [file join $HOME displaypic] 
		status_log "Copied $filename to [file join $HOME displaypic]\n"
	}

	set endfile [getfilename $filename]

	set file [convert_image [GetSkinFile displaypic $endfile] 96]

	if { $file == "" } { return "" }
	return $file

}


proc load_my_pic {} {
	global config
	if {[file readable [filenoext [GetSkinFile displaypic $config(displaypic)]].gif]} {
		image create photo my_pic -file "[filenoext [GetSkinFile displaypic $config(displaypic)]].gif"
	} else {
		clear_disp
	}
}

proc pictureBrowser {} {
	global config selected_image

	if { [winfo exists .picbrowser] } {
		raise .picbrowser
		return
	}

	toplevel .picbrowser

	set selected_image $config(displaypic)

	frame .picbrowser.pics
	text .picbrowser.pics.text -width 40 -font sboldf -background white -yscrollcommand ".picbrowser.pics.ys set" \
		-cursor left_ptr -font splainf -selectbackground white -selectborderwidth 0 -exportselection 0 \
		-relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0 -wrap none
	scrollbar .picbrowser.pics.ys -command ".picbrowser.pics.text yview"

	pack .picbrowser.pics.text -side left -expand true -fill both -padx 0 -pady 0
	pack .picbrowser.pics.ys -side left -fill y -padx 0 -pady 0


	load_my_pic

	label .picbrowser.mypic -image my_pic -background white -borderwidth 2 -relief solid
	label .picbrowser.mypic_label -text "[trans mypic]" -font splainf

	button .picbrowser.browse -command "set selected_image \[pictureChooseFile\]; reloadAvailablePics" -text "[trans browse]..." -font sboldf
	button .picbrowser.delete -command "pictureDeleteFile ;reloadAvailablePics" -text "[trans delete]" -font sboldf
	button .picbrowser.purge -command "destroy .picbrowser" -state disabled -text "[trans purge]..." -font sboldf
	button .picbrowser.ok -command "set_displaypic \${selected_image};destroy .picbrowser" -text "[trans ok]" -font sboldf
	button .picbrowser.cancel -command "destroy .picbrowser" -text "[trans cancel]" -font sboldf
	
	grid .picbrowser.pics -row 0 -column 0 -rowspan 4 -columnspan 3 -padx 3 -pady 3 -sticky nsew
	
	grid .picbrowser.browse -row 4 -column 0 -padx 3 -pady 3 -sticky ewn
	grid .picbrowser.delete -row 4 -column 1 -padx 3 -pady 3 -sticky ewn
	grid .picbrowser.purge -row 4 -column 2 -padx 5 -pady 3 -sticky ewn
	
	grid .picbrowser.mypic_label -row 0 -column 3 -padx 3 -pady 3 -sticky s
	grid .picbrowser.mypic -row 1 -column 3 -padx 3 -pady 3 -sticky n
	grid .picbrowser.ok -row 2 -column 3 -padx 3 -pady 3 -sticky sew
	grid .picbrowser.cancel -row 3 -column 3 -padx 3 -pady 3 -sticky new
	
	grid column .picbrowser 0 -weight 1	
	grid column .picbrowser 1 -weight 1	
	grid column .picbrowser 2 -weight 1	
	grid row .picbrowser 3 -weight 1		

	
	reloadAvailablePics
		
	#Free ifmages:
	bind .picbrowser <Destroy> {
		if {"%W" == ".picbrowser"} {
			global image_names
			foreach img $image_names {
				image delete $img
				status_log "Deleting $img\n"			
			}
			unset image_names
			unset selected_image
	} }

	
	.picbrowser.pics.text configure -state disabled
		
	wm title .picbrowser "[trans picbrowser]"
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
		-background white -highlightbackground black
	label .picbrowser.pics.text.$the_image.desc -text "$pic_text" -font splainf -background white
	pack .picbrowser.pics.text.$the_image.pic -side left -padx 3 -pady 0
	pack .picbrowser.pics.text.$the_image.desc -side left -padx 5 -pady 0
	bind .picbrowser.pics.text.$the_image <Enter> ".picbrowser.pics.text.$the_image.pic configure -highlightbackground red"
	bind .picbrowser.pics.text.$the_image <Leave> ".picbrowser.pics.text.$the_image.pic configure -highlightbackground black"
	bind .picbrowser.pics.text.$the_image <Button1-ButtonRelease> "[list .picbrowser.mypic configure -image $the_image];[list set selected_image $filename]"
	bind .picbrowser.pics.text.$the_image.pic <Button1-ButtonRelease> "[list .picbrowser.mypic configure -image $the_image];[list set selected_image $filename]"
	status_log "File: $filename\n" blue
			
	.picbrowser.pics.text window create end -window .picbrowser.pics.text.$the_image -padx 3 -pady 3
	.picbrowser.pics.text insert end "\n"
	
}

proc reloadAvailablePics { } {
	global HOME program_dir image_names

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
			
	#if { [catch { set skin "[::config::get skin]" } ] != 0 } {
	#	set skin "default"
	#}
	
	set files [list]
	#catch {set files [glob -directory [file join $program_dir skins $skin displaypic] *.png] }
	#if { $skin != "default" } {
	catch {set files [concat $files [glob -directory [file join $program_dir skins default displaypic] *.png]]}
	#}
	catch {set myfiles [glob -directory [file join $HOME displaypic] *.png]}
	catch {set cachefiles [glob -directory [file join $HOME displaypic cache] *.png]}
	
	addPicture no_pic "[trans nopic]" ""

	
	if { [info exists images_in_use]	} {
		set image_names $images_in_use
		unset images_in_use
	} else {
		set image_names [list]	
	}



	if { [info exists files] } {			
		set files [lsort -dictionary $files]
		foreach filename $files {
			if { [file exists "[filenoext $filename].gif"] } {
				set the_image [image create photo -file "[filenoext $filename].gif" ]	
				addPicture $the_image "[getPictureDesc $filename]" [file tail $filename]			
				lappend image_names $the_image
			}
		}
	}
	.picbrowser.pics.text insert end "___________________________\n\n"	
		
	if { [info exists myfiles] } {
		set myfiles [lsort -dictionary $myfiles]
		foreach filename $myfiles {
			if { [file exists "[filenoext $filename].gif"] } {
				set the_image [image create photo -file "[filenoext $filename].gif" ]	
				addPicture $the_image "[getPictureDesc $filename]" [file tail $filename]
				lappend image_names $the_image
			}
		}
	}

	.picbrowser.pics.text insert end "___________________________\n\n"	
	
	if { [info exists cachefiles] } {
		foreach filename $cachefiles {
			if { [file exists "[filenoext $filename].gif"] } {
				set the_image [image create photo -file "[filenoext $filename].gif" ]	
				addPicture $the_image "[getPictureDesc $filename]" "cache/[file tail $filename]"
				lappend image_names $the_image
			}
		}
	}

	update idletasks

	.picbrowser.pics.text yview moveto [lindex $scrollidx 0]

	.picbrowser.pics.text configure  -state disabled



}

#proc chooseFileDialog {basename {initialfile ""} {types {{"All files"         *}} }} {}
proc chooseFileDialog {basename {initialfile ""} {types {{"Image Files" {*.gif *.jpg *.jpeg *.bmp *.png} }} }} {
    set parent "."
    catch {set parent [focus]}

    if { "$initialfile" == "" } {
        return [tk_getOpenFile -filetypes $types -parent $parent]
    } else {
        return [tk_getOpenFile -filetypes $types -parent $parent \
                               -initialfile $initialfile ]
    }
}

proc pictureDeleteFile {} {
	global selected_image HOME
	
	set parent "."
	catch {set parent [focus]}
	
	if { $selected_image!="" && [file exists [file join $HOME displaypic $selected_image]]} {
		set answer [tk_messageBox -message [trans confirm] -type yesno -icon question -title [trans delete] -parent $parent]
		if {$answer == "yes"} {
			set filename [file join $HOME displaypic $selected_image]
			catch {file delete $filename}
			catch {file delete [filenoext $filename].gif}
			catch {file delete [filenoext $filename].dat}
			set selected_image ""
			.picbrowser.mypic configure -image no_pic
			if { [file exists $filename] == 1 } {
				tk_messageBox -message [trans faileddelete] -type ok -icon error -title [trans failed] -parent $parent
				status_log "Failed: file $filename could not be deleted.\n";
			}
		}
		
	} else {
		tk_messageBox -message [trans faileddeleteperso] -type ok -icon error -title [trans failed] -parent $parent
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


	set file [chooseFileDialog {{\"Image Files\" {*.gif *.jpg *.jpeg *.bmp *.png} }}]

	 if { $file != "" } {
	 	if { ![catch {convert_display_picture $file} res]} {
			set image_name [image create photo -file [GetSkinFile displaypic "[filenoext [file tail $file]].gif"]]
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
	global config
	
	if { $file != "" } {
		set config(displaypic) $file
		status_log "set_displaypic: File set to $file\n" blue
		load_my_pic
		::MSN::changeStatus [set ::MSN::myStatus]
	} else {
		status_log "set_displaypic: Setting displaypic to no_pic\n" blue
		clear_disp
	}
}

proc clear_disp { } {
    global config

    set config(displaypic) "amsn.png"

	 catch {image create photo my_pic -file "[GetSkinFile displaypic amsn.gif]"}
    ::MSN::changeStatus [set ::MSN::myStatus]

}


proc bgerror { args } {
    global errorInfo errorCode HOME
    
    status_log "\n\n\n\n\n" error
    status_log "GOT TCL/TK ERROR : $args\n$errorInfo\n$errorCode\n" red
    status_log "\n\n\n\n\n" error
    
    set fd [open [file join $HOME bugreport.amsn] a]
    
    puts $fd "Bug generated at [clock format [clock seconds] -format "%D - %T"]\n"
    puts $fd "Error : $args\nStack : $errorInfo\n\nCode : $errorCode\n\n"
    puts $fd "==========================================================================\n\n"
    

    close $fd

    msg_box "[trans tkerror [file join $HOME bugreport.amsn]]"
}



#ShowTransient Ê{wintransient}
#The function try to know if the operating system is Mac OS X or not. If no, enable window in transient. Else,
#don't change nothing.
proc ShowTransient {win {parent "."}} {
	global tcl_platform
	if {$tcl_platform(os) != "Darwin"} {
		wm transient $win $parent
	}
}

#proc prueba {} {
#	global tiempo_out
#	set tiempo_out 1
#	after 2000 prueba
#	status_log "Tiempo\n"
#}

#after 2000 prueba
