#Default look


namespace eval ::amsn {
   namespace export fileTransferRecv fileTransferProgress \
   errorMsg notifyAdd initLook 
   
   ##PUBLIC

   proc initLook { family size bgcolor} {

      font create menufont -family $family -size $size -weight normal
      font create sboldf -family $family -size $size -weight bold
      font create splainf -family $family -size $size -weight normal
      font create bboldf -family $family -size [expr {$size+1}] -weight bold
      font create bplainf -family $family -size [expr {$size+1}] -weight normal
      font create bigfont -family $family -size [expr {$size+2}] -weight bold
      font create examplef -family $family -size [expr {$size-1}] -weight normal

      tk_setPalette $bgcolor
      option add *Menu.font menufont
      option add *background $bgcolor
      option add *selectColor #DD0000

      set Entry {-bg #FFFFFF -foreground #0000FF}
      set Label {-bg #FFFFFF -foreground #000000}
      ::themes::AddClass Amsn Entry $Entry 90
      ::themes::AddClass Amsn Label $Label 90
      ::abookGui::Init
   }

   #///////////////////////////////////////////////////////////////////////////////
   # Shows the error message specified by "msg"
   proc errorMsg { msg } {
      tk_messageBox -type ok -icon error -message $msg -title "[trans title] Error"
   }
   #///////////////////////////////////////////////////////////////////////////////



   #FileTransferSend Switchboardane Windowtitle
   #Still need to improve
   proc FileTransferSend { win_name } {
      global config

      set ipaddr "[::MSN::getMyIP]"

      set w ${win_name}_sendfile
      toplevel $w
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

      if {$config(autoftip)} {
        $w.top.fields.ip insert 0 "$ipaddr"
      } else {
        $w.top.fields.ip insert 0 "$config(myip)"
      }

      focus $w.top.fields.file

      fileDialog2 $w $w.top.fields.file open ""
   }

   #PRIVATE: called by the FileTransferSend Dialog
   proc FileTransferSendOk { w win_name } {
      global config

      set filename [ $w.top.fields.file get ]

      if {$config(autoftip) == 0 } {
        set config(myip) [ $w.top.fields.ip get ]
        set ipaddr [ $w.top.fields.ip get ]
      } else {
        set ipaddr [ ::MSN::getMyIP ]
      }


      destroy $w

      #Calculate a random cookie
      set cookie [expr {[clock clicks]  % (65536 * 8)}]     
      
      status_log "Random generated cookie: $cookie\n"
      
      ::amsn::SendWin [file tail $filename] $cookie
      #TODO: We should get the chatid just at the beginning, and then go passing it as an argument,
      # so the file transfer won't give an error if the window is closed before clicking OK
      status_log "sending FT invitation to chatid [ChatFor $win_name] (win_name is $win_name)\n"
      ::MSN::inviteFT [ChatFor $win_name] $filename $cookie $ipaddr

      return 0
   }

   #Dialog shown when receiving a file
   proc fileTransferRecv {filename filesize cookie chatid fromlogin fromname} {
      global files_dir

      #Newer version

      set win_name [WindowFor $chatid]

      if { $win_name == 0 } {

         set win_name [openChatWindow]
	  SetWindowFor $chatid $win_name
         status_log "NEW - Window doesn't exists in messageFrom, created window named [WindowFor $chatid]\n"
	  WinTopUpdate $chatid

      }

     ${win_name}.f.text configure -state normal -font bplainf -foreground black


     ${win_name}.f.text tag configure ftyes$cookie \
       -foreground darkblue -background white -font bboldf -underline false
     ${win_name}.f.text tag bind ftyes$cookie <Enter> \
       "${win_name}.f.text tag conf ftyes$cookie -underline true;\
       ${win_name}.f.text conf -cursor hand2"
     ${win_name}.f.text tag bind ftyes$cookie <Leave> \
       "${win_name}.f.text tag conf ftyes$cookie -underline false;\
       ${win_name}.f.text conf -cursor left_ptr"
     ${win_name}.f.text tag bind ftyes$cookie <Button1-ButtonRelease> \
       "::amsn::AcceptedFT $chatid $cookie; ::amsn::RecvWin {$filename} $cookie; ::MSN::acceptFT $chatid {$filename} $filesize $cookie"

     ${win_name}.f.text tag configure ftno$cookie \
       -foreground darkblue -background white -font bboldf -underline false
     ${win_name}.f.text tag bind ftno$cookie <Enter> \
       "${win_name}.f.text tag conf ftno$cookie -underline true;\
       ${win_name}.f.text conf -cursor hand2"
     ${win_name}.f.text tag bind ftno$cookie <Leave> \
       "${win_name}.f.text tag conf ftno$cookie -underline false;\
       ${win_name}.f.text conf -cursor left_ptr"
     ${win_name}.f.text tag bind ftno$cookie <Button1-ButtonRelease> \
       "::amsn::RejectedFT $chatid $cookie; ::MSN::rejectFT $chatid $cookie"

     set timestamp [clock format [clock seconds] -format %H:%M]

     set txt [trans acceptfile '$filename' $filesize $files_dir]

     #TODO: Use Winwrite, os similar, instead of doing it directly
     ${win_name}.f.text insert end "----------\n" gray
     ${win_name}.f.text image create end -image fticon -pady 2 -padx 3
     ${win_name}.f.text insert end "\[$timestamp\] $fromname: $txt" gray
     ${win_name}.f.text insert end " - (" gray
     ${win_name}.f.text insert end "[trans accept]" ftyes$cookie
     ${win_name}.f.text insert end " / " gray
     ${win_name}.f.text insert end "[trans reject]" ftno$cookie
     ${win_name}.f.text insert end " )\n" gray
     ${win_name}.f.text insert end "----------\n" gray
     ${win_name}.f.text yview moveto 1.0
     ${win_name}.f.text configure -state disabled
     WinFlicker $chatid

      if { "[wm state ${win_name}]" == "withdrawn" } {
        wm state ${win_name} iconic
	::amsn::notifyAdd "[trans says $fromname]:\n$txt" \
	   "wm state ${win_name} normal"
      }

      if { [string first ${win_name} [focus]] != 0 } {
        sonido type
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
   # defined in the openChatWindow proc, or just "user". If the tpye is "user",
   # the 'fontformat' parameter will be used as font format.
   # The procedure will open a window if it does not exists, add a notifyWindow and
   # play a sound if it's necessary
   proc messageFrom { chatid user msg type {fontformat ""} } {

      set win_name [WindowFor $chatid]

      if { $win_name == 0 } {

         set win_name [openChatWindow]
	  SetWindowFor $chatid $win_name
         status_log "NEW - Window doesn't exists in messageFrom, created window named [WindowFor $chatid]\n"
	  WinTopUpdate $chatid

      }

      ::amsn::PutMessage $chatid $user $msg $type $fontformat

      if { "[wm state $win_name]" == "withdrawn" } {

         wm state $win_name iconic

         notifyAdd "[trans says [::MSN::userName $chatid $user]]:\n$msg" \
            "wm state ${win_name} normal; focus -force ${win_name}.in.input"

      }

      if { [string first ${win_name} [focus]] != 0 } {
         sonido type
      }

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # WinTopUpdate { chatid }
   # Gets the users in 'chatid' from the protocol layer, and updates the top of the
   # window with the user names and states.
   proc WinTopUpdate { chatid } {

      #TODO: Should we check chatReady? I don't think so, look where it's called from.
      # There should be no problem

      variable window_titles
      global list_states

      set topmsg ""
      set title ""
      set user_list [::MSN::usersInChat $chatid]

      foreach user_info $user_list {

         set user_login [lindex $user_info 0]
         set user_name [lindex $user_info 1]
         set user_state_no [lindex $user_info 2]
	  set user_state [lindex [lindex $list_states $user_state_no] 1]

	  set title "${title}${user_name}, "

 	  set topmsg "${topmsg}${user_name} <${user_login}> "
	  #TODO: The state information works, but it doesn't change, only when
	  #users left/join
	  #if { "$user_state" != "" && "$user_state" != "online" } {
         #   set topmsg "${topmsg} \([trans $user_state]\) "
	  #}
	  set topmsg "${topmsg}\n"
      }

      set title [string replace $title end-1 end " - [trans chat]"]
      set topmsg [string replace $topmsg end-1 end]

      set win_name [WindowFor $chatid]

      ${win_name}.f.top.text configure -state normal -font sboldf -height 1
      ${win_name}.f.top.text delete 0.0 end
      ${win_name}.f.top.text insert end $topmsg
      set size [${win_name}.f.top.text index end]
      set posyx [split $size "."]
      set lines [expr {[lindex $posyx 0] - 1}]

      ${win_name}.f.top.text configure -state normal -font sboldf -height $lines -wrap none
      ${win_name}.f.top.text configure -state disabled

      set window_titles(${win_name}) ${title}
      wm title ${win_name} ${title}

      #TODO: Should change the size of the top text to fit the users names
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # chatChange (chatid, newchatid)
   # this is called from the protocol layer when a private chat changes into a
   # conference, right after a JOI command comes from the SB. It mean that the window
   # assigned to $chatid should now be related to $newchatid
   # - 'chatid' is the name of the chat that was a single private before
   # - 'newchatid' is the new id of the chat for the conference
   proc chatChange { chatid newchatid } {

      set win_name [WindowFor $chatid]

      if { $win_name == 0 } {

	  status_log "chatChange: Window doesn't exist (probably invited to a conference)\n"
	  return 0

      }

      UnsetWindowFor $chatid $win_name
      SetWindowFor $newchatid $win_name

      status_log "chatChange: changing $chatid into $newchatid\n"

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # userJoins (charid, user_name)
   # called from the protocol layer when a user JOINS a chat, before userJoinsLeft.
   # It should be called after a IRO or JOI in the switchboard.
   # It will open a new window if it doesn't exists, and show the status message.
   # - 'chatid' is the chat name
   # - 'usr_name' is the user nick to show in the status message
   proc userJoins { chatid usr_name } {

      if {[WindowFor $chatid] == 0} {
	  status_log "userJoins: Window doesn't exist\n"
         set win_name [openChatWindow]
         SetWindowFor $chatid $win_name
      }

      set timestamp [clock format [clock seconds] -format %H:%M]
      set statusmsg "\[$timestamp\] [trans joins $usr_name]\n"
      WinStatus [ WindowFor $chatid ] $statusmsg
      WinTopUpdate $chatid

   }
   #///////////////////////////////////////////////////////////////////////////////


   #///////////////////////////////////////////////////////////////////////////////
   # userLeaves (charid, user_name)
   # called from the protocol layer when a user LEAVES a chat, before userJoinsLeft.
   # It will show the status message. No need to show it if the window is already
   # closed, right?
   # - 'chatid' is the chat name
   # - 'usr_name' is the user nick to show in the status message
   proc userLeaves { chatid usr_name } {

      if {[WindowFor $chatid] == 0} {
         return 0
      }

      set timestamp [clock format [clock seconds] -format %H:%M]
      set statusmsg "\[$timestamp\] [trans leaves $usr_name]\n"
      WinStatus [ WindowFor $chatid ] $statusmsg
      WinTopUpdate $chatid

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # updateTypers (chatid)
   # Called from the protocol.
   # Asks the protocol layer to get a list of typing users in the chat, and shows
   # a message in the status bar.
   # - 'chatid' is the name of the chat
   proc updateTypers { chatid } {


      if {[WindowFor $chatid] == 0} {
         return 0
      }

      set typers_list [::MSN::typersInChat $chatid]

      set typingusers ""
      foreach login $typers_list {
         set user_name [lindex $login 1]
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



   #///////////////////////////////////////////////////////////////////////////////
   # Auto incremented variable to name the windows
   variable winid 0
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # openChatWindow ()
   # Opens a new hidden chat window and returns its name.
   proc openChatWindow {} {
      variable winid
      variable window_titles
      global images_folder config HOME files_dir

      set win_name "msg_$winid"
      incr winid

      toplevel .${win_name}
      wm title .${win_name} "[trans chat]"
      #TODO: Here we should decide if start withdrawn or normal, depending on an option
      # Here or in userJoins? better use userJoins
      wm iconify .${win_name}
      wm state .${win_name} withdrawn
      wm group .${win_name} ""
#      wm iconbitmap . @${images_folder}/amsn.xbm
#      wm iconmask . @${images_folder}/amsnmask.xbm

      menu .${win_name}.menu -tearoff 0 -type menubar  \
         -borderwidth 0 -activeborderwidth -0
      .${win_name}.menu add cascade -label "[trans msn]" -menu .${win_name}.menu.msn
      .${win_name}.menu add cascade -label "[trans edit]" -menu .${win_name}.menu.edit
      .${win_name}.menu add cascade -label "[trans view]" -menu .${win_name}.menu.view
      .${win_name}.menu add cascade -label "[trans actions]" -menu .${win_name}.menu.actions

      menu .${win_name}.menu.msn -tearoff 0 -type normal
      .${win_name}.menu.msn add command -label "[trans save]" \
         -command " ChooseFilename .${win_name}.text ${win_name} "
      .${win_name}.menu.msn add command -label "[trans saveas]..." \
      -command " ChooseFilename .${win_name}.text ${win_name} "
      .${win_name}.menu.msn add separator
      .${win_name}.menu.msn add command -label "[trans sendfile]..." \
         -command "::amsn::FileTransferSend .${win_name}" -state disabled
      .${win_name}.menu.msn add command -label "[trans openreceived]..." \
         -command "cmsn_open_received \"$files_dir\""
      .${win_name}.menu.msn add separator
      .${win_name}.menu.msn add command -label "[trans close]" \
         -command "destroy .${win_name}"

      menu .${win_name}.menu.edit -tearoff 0 -type normal
      .${win_name}.menu.edit add command -label "[trans cut]" -command "copy 1 ${win_name}" -accelerator "CTRL+X"
      .${win_name}.menu.edit add command -label "[trans copy]" -command "copy 0 ${win_name}" -accelerator "CTRL+C"
      .${win_name}.menu.edit add command -label "[trans paste]" -command "paste ${win_name}" -accelerator "CTRL+V"

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

      menu .${win_name}.menu.actions -tearoff 0 -type normal
      .${win_name}.menu.actions add command -label "[trans addtocontacts]" \
         -command "::amsn::ShowAddList \"[trans addtocontacts]\" .${win_name} ::MSN::addUser"
      .${win_name}.menu.actions add command -label "[trans block]/[trans unblock]" \
         -command "::amsn::ShowChatList \"[trans block]/[trans unblock]\" .${win_name} blockun_user"
      .${win_name}.menu.actions add command -label "[trans properties]" \
         -command "::amsn::ShowChatList \"[trans properties]\" .${win_name} ::abookGui::showEntry"
      .${win_name}.menu.actions add separator
      .${win_name}.menu.actions add command -label "[trans invite]..." -command "::amsn::ShowInviteList \"[trans invite]\" .${win_name}"
      .${win_name}.menu.actions add command -label "[trans sendfile]..." \
      -command "::amsn::FileTransferSend .${win_name}"  -state disabled
      .${win_name}.menu.actions add separator
      .${win_name}.menu.actions add command -label [trans sendmail] -command "::amsn::ShowChatList \"[trans sendmail]\" .${win_name} send_mail"
      .${win_name} conf -menu .${win_name}.menu

      menu .${win_name}.copypaste -tearoff 0 -type normal
      .${win_name}.copypaste add command -label [trans cut] -command "status_log cut\n;copy 1 ${win_name}"
      .${win_name}.copypaste add command -label [trans copy] -command "status_log copy\n;copy 0 ${win_name}"
      .${win_name}.copypaste add command -label [trans paste] -command "status_log paste\n;paste ${win_name}"

      set bgcolor #0050C0
      set bgcolor2 #D0D0F0

      frame .${win_name}.f -class amsnChatFrame -background $bgcolor -borderwidth 0 -padx 3 -pady 1 -relief flat

      text .${win_name}.f.text -borderwidth 0 -background white -width 45 -height 15 -wrap word \
         -yscrollcommand ".${win_name}.f.ys set" -exportselection 1  -relief solid -highlightthickness 0\
	  -padx 3 -pady 1

      frame .${win_name}.f.top -class Amsn -relief flat -borderwidth 0 -padx 0 -pady 0 -background $bgcolor


      text .${win_name}.f.top.textto  -borderwidth 0 -width [string length "[trans to]:"] -relief solid -padx 0 -pady 3\
         -height 1 -wrap none -background $bgcolor -foreground $bgcolor2 -highlightthickness 0
      .${win_name}.f.top.textto configure -state normal -font bplainf
      .${win_name}.f.top.textto insert end "[trans to]:"
      .${win_name}.f.top.textto configure -state disabled

      text .${win_name}.f.top.text  -borderwidth 0 -width 45 -relief flat -padx 5 -pady 3\
         -height 1 -wrap none -background $bgcolor -foreground $bgcolor2 -highlightthickness 0

#-yscrollcommand ".${win_name}.f.top.ys set"



      frame .${win_name}.f.buttons -class Amsn -borderwidth 0 -relief solid -background $bgcolor2

      frame .${win_name}.f.in -class Amsn -pady 3 -background $bgcolor -relief solid -borderwidth 0

      text .${win_name}.f.in.input -background white -width 15 -height 3 -wrap word\
         -font bboldf -borderwidth 0 -relief solid -highlightthickness 0

      frame .${win_name}.f.in.f -class Amsn -borderwidth 0 -relief solid -background white -padx 3 -pady 4
      button .${win_name}.f.in.f.send  -text [trans send] -width 5 -borderwidth 1 -relief solid \
         -command "::amsn::MessageSend .${win_name} .${win_name}.f.in.input" -font bplainf -highlightthickness 0


      #scrollbar .${win_name}.f.top.ys -command ".${win_name}.f.top.text yview"

      scrollbar .${win_name}.f.ys -command ".${win_name}.f.text yview" \

      text .${win_name}.status  -width 30 -height 1 -wrap none\
         -font bplainf -borderwidth 1



      button .${win_name}.f.buttons.smileys  -image butsmile -relief flat -padx 5 -background $bgcolor2 -highlightthickness 0
      button .${win_name}.f.buttons.fontsel -image butfont -relief flat -padx 5 -background $bgcolor2 -highlightthickness 0
      button .${win_name}.f.buttons.block -image butblock -relief flat -padx 5 -background $bgcolor2 -highlightthickness 0
      pack .${win_name}.f.buttons.block .${win_name}.f.buttons.fontsel .${win_name}.f.buttons.smileys -side left

      pack .${win_name}.f.top -side top -fill x
      pack .${win_name}.status -side bottom -fill x
      pack .${win_name}.f.in -side bottom -fill x
      pack .${win_name}.f.buttons -side bottom -fill x
      pack .${win_name}.f.ys -side right -fill y
      pack .${win_name}.f.text -side right -expand true -fill both
           
      pack .${win_name}.f.top.textto -side left -expand true -fill y
      pack .${win_name}.f.top.text -side left -expand true -fill x

      pack .${win_name}.f.in.f -side right -fill y
      pack .${win_name}.f.in.f.send -fill both -expand true
      pack .${win_name}.f.in.input -side left -expand true -fill x
      
      pack .${win_name}.f -expand true -fill both

      .${win_name}.f.top.text configure -state disabled
      .${win_name}.f.text configure -state disabled
      .${win_name}.status configure -state disabled
      .${win_name}.f.in.f.send configure -state disabled
      .${win_name}.f.in.input configure -state normal


      .${win_name}.f.text tag configure green -foreground darkgreen -background white -font bboldf
      .${win_name}.f.text tag configure red -foreground red -background white -font bboldf
      .${win_name}.f.text tag configure blue -foreground blue -background white -font bboldf
      .${win_name}.f.text tag configure gray -foreground #808080 -background white
      .${win_name}.f.text tag configure white -foreground white -background black
      .${win_name}.f.text tag configure url -foreground darkblue -background white -font bboldf -underline true
      #.${win_name}.f.text tag configure sel -foreground white -background darkblue

      bind .${win_name}.f.in.input <Tab> "focus .${win_name}.f.in.f.send; break"

      bind  .${win_name}.f.buttons.smileys  <Button1-ButtonRelease> "smile_menu %X %Y .${win_name}.f.in.input"
      bind  .${win_name}.f.buttons.fontsel  <Button1-ButtonRelease> "change_myfont ${win_name}"
      bind  .${win_name}.f.buttons.block  <Button1-ButtonRelease> "::amsn::ShowChatList \"[trans block]/[trans unblock]\" .${win_name} blockun_user"

      bind .${win_name}.f.in.f.send <Return> \
         "::amsn::MessageSend .${win_name} .${win_name}.f.in.input; break"
      bind .${win_name}.f.in.input <Control-Return> {%W insert end "\n"; break}
      bind .${win_name}.f.in.input <Shift-Return> {%W insert end "\n"; break}

      bind .${win_name}.f.in.input <Button3-ButtonRelease> "tk_popup .${win_name}.copypaste %X %Y"
      bind .${win_name}.f.text <Button3-ButtonRelease> "tk_popup .${win_name}.copypaste %X %Y"
      bind .${win_name} <Control-x> "status_log cut\n;copy 1 ${win_name}"
      bind .${win_name} <Control-c> "status_log copy\n;copy 0 ${win_name}"
      bind .${win_name} <Control-v> "status_log paste\n;paste ${win_name}"

      bind .${win_name} <Destroy> "::amsn::closeWindow .${win_name} %W"

      focus .${win_name}.f.in.input

      change_myfontsize $config(textsize) ${win_name}

      status_log "NEW - Window created\n" white

      #TODO: We always want these menus and bindings enabled? Think it!!
      .${win_name}.f.in.input configure -state normal
      .${win_name}.f.in.f.send configure -state normal

      .${win_name}.menu.msn entryconfigure 3 -state normal
      .${win_name}.menu.actions entryconfigure 5 -state normal

      bind .${win_name}.f.in.input <Key> "::amsn::TypingNotification .${win_name}"
      bind .${win_name}.f.in.input <Return> "::amsn::MessageSend .${win_name} %W; break"
      bind .${win_name}.f.in.input <Key-KP_Enter> "::amsn::MessageSend .${win_name} %W; break"
      bind .${win_name}.f.in.input <Alt-s> "::amsn::MessageSend .${win_name} %W; break"


      set window_titles(.${win_name}) ""

      return ".${win_name}"

   }
   #///////////////////////////////////////////////////////////////////////////////


   proc ShowAddList {title win_name command} {
      global list_users

      set userlist [list]
      set chatusers [::MSN::usersInChat [ChatFor $win_name]]

      foreach user_info $chatusers {
         set user_login [lindex $user_info 0]
         set user_state_no [lindex $user_info 2]
	  #TODO: Check state here? Does it mind if the user is offline?
         if {($user_state_no < 7) && ([lsearch $list_users "$user_login *"] == -1)} {
	     set user_name [lindex $user_info 1]
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

	
	if {![::MSN::chatReady [ChatFor $win_name]]} {
	   return 0
	}

	set userlist [list]
	set chatusers [::MSN::usersInChat [ChatFor $win_name]]

	foreach user_info $list_users {
     		set user_login [lindex $user_info 0]
      		set user_state_no [lindex $user_info 2]
      		if {($user_state_no < 7) && ([lsearch $chatusers "$user_login *"] == -1)} {
          		set user_name [lindex $user_info 1]
	  		lappend userlist [list $user_login $user_name $user_state_no]
      		}
   	}

	if { [llength $userlist] > 0 } {
		#TODO: Should queue invitation until chat is ready, to fix some problems when
		# inviting a user while the first one hasn't joined yet
   		ChooseList $title both "::MSN::inviteUser [ChatFor $win_name]" 1 0 $userlist
  	} else {
		cmsn_draw_otherwindow $title "::MSN::inviteUser [ChatFor $win_name]"
	}
   }

   proc ShowChatList {title win_name command} {
      global list_users

      set userlist [list]
      set userlist2 [list]
      set chatusers [::MSN::usersInChat [ChatFor $win_name]]


      foreach user_info $list_users {
         set user_login [lindex $user_info 0]
         set user_state_no [lindex $user_info 2]
        if {($user_state_no < 7) && ([lsearch $chatusers "$user_login *"] != -1)} {
            set user_name [lindex $user_info 1]
            lappend userlist2 [list $user_login $user_name $user_state_no]
         }
      }

      foreach user_info $chatusers {
         set user_login [lindex $user_info 0]
         set user_state_no [lindex $user_info 2]
         if {($user_state_no < 7) && ([lsearch $list_users "$user_login *"] == -1)} {
      	     set user_name [lindex $user_info 1]
      	     lappend userlist2 [list $user_login $user_name $user_state_no]
         }
      }

      # TODO: Shouldn't just this  be right?
      foreach user_info $chatusers {
         set user_login [lindex $user_info 0]
         set user_state_no [lindex $user_info 2]

	  if { $user_state_no < 7 } {
      	     set user_name [lindex $user_info 1]
      	     lappend userlist [list $user_login $user_name $user_state_no]
         }
      }


      status_log "ShowChatList: Let's see the difference: one is $userlist\ntwo is $userlist2... any?\n"

      if { [llength $userlist] > 0 } {
   	   ChooseList $title both $command 0 1 $userlist
      }

   }

   #///////////////////////////////////////////////////////////////////////////////
   proc ChooseList {title online command other skip {userslist ""}} {
      global list_users list_bl list_states userchoose_req

      if { $userslist == "" } {
         set userslist $list_users
      }


      set usercount 0

      foreach user $userslist {
         set user_login [lindex $user 0]
         set user_state_no [lindex $user 2]
         set state [lindex $list_states $user_state_no]
         set state_code [lindex $state 0]

         if {($online != "online") || ($state_code != "FLN")} {
      	     set usercount [expr {$usercount + 1}]
         }

      }

      if { $usercount == 1 && $skip == 1} {
         eval $command $user_login
         return 0
      }

      set wname "[focus]_userchoose"

      if { [catch {toplevel $wname -width 400 -height 300} res ] } {
         raise $wname
         focus $wname
         return 0
      }

      wm title $wname $title
      wm transient $wname .
      wm geometry $wname 280x300

      frame $wname.list -class Amsn
      frame $wname.buttons -class Amsn


      listbox $wname.list.userlist -yscrollcommand "$wname.list.ys set" -font splainf
      scrollbar $wname.list.ys -command "$wname.list.userlist yview"

      button  $wname.buttons.ok -text "[trans ok]" -command "$command \[string range \[lindex \[$wname.list.userlist get active\] end\] 1 end-1\]\n;destroy $wname" -font sboldf
      button  $wname.buttons.cancel -text "[trans cancel]" -command "destroy $wname" -font sboldf



      pack $wname.list.ys -side right -fill y
      pack $wname.list.userlist -side left -expand true -fill both
      pack $wname.list -side top -expand true -fill both

      if { $other == 1 } {
         button  $wname.buttons.other -text "[trans other]..." -command "cmsn_draw_otherwindow \"$title\" \"$command\"; destroy $wname" -font sboldf
         pack $wname.buttons.other $wname.buttons.cancel $wname.buttons.ok -padx 10 -side right
      } else {
         pack $wname.buttons.cancel $wname.buttons.ok -padx 10 -side right
      }

      pack $wname.buttons -side bottom


      foreach user $userslist {
         set user_login [lindex $user 0]
         set user_name [lindex $user 1]
         set user_state_no [lindex $user 2]
         set state [lindex $list_states $user_state_no]
         set state_code [lindex $state 0]

         if {($online != "online") || ($state_code != "FLN")} {
            if {[lsearch $list_bl "$user_login *"] != -1} {
               $wname.list.userlist insert end "BLOCKED -> $user_name <$user_login>"
            } else {
               $wname.list.userlist insert end "$user_name <$user_login>"
            }
         }

      }

      bind $wname.list.userlist <Double-Button-1> "$command \[string range \[lindex \[$wname.list.userlist get active\] end\] 1 end-1\]\n;destroy $wname"
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # TypingNotification (win_name)
   # Called by a window when the user types something into the text box. It tells
   # the protocol layer to send a typing notificacion to the chat that the window
   # 'win_name' is connected to
   proc TypingNotification { win_name } {

      set chatid [ChatFor $win_name]

      # TODO: Should we queue it? It's fine just to call reconnect if chat not ready,
      # doesn't mind if we lose this
      ::MSN::chatQueue $chatid [list sb_change $chatid]

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # MessageSend (win_name,input)
   # Called from a window the the user enters a message to send to the chat. It will
   # just queue the message to send in the chat associated with 'win_name', and set
   # a timeout for the message
   proc MessageSend { win_name input } {
      #TODO: Check if the chat is available before actually sending the message / enqueue
      #Replaces obsolete proc sb_enter (delete it)

      set chatid [ChatFor $win_name]

      #TODO: Remove this when queueing works
      if {![ ::MSN::chatReady $chatid]} {
         status_log "Can't send message, chat not ready\n"
         return 0
      }

      set msg [$input get 0.0 end-1c]

      #Blank message
      if {[string length $msg] < 1} { return 0 }

      $input delete 0.0 end
      focus ${input}

      set ackid [after 30000 ::amsn::DeliveryFailed $chatid [list $msg]]
      ::MSN::chatQueue $chatid [list ::MSN::messageTo $chatid "$msg" $ackid]
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
     set command [lindex [after info $ackid] 0]
     after cancel $ackid
     eval $command
   }
   #///////////////////////////////////////////////////////////////////////////////

   

   #///////////////////////////////////////////////////////////////////////////////
   # DeliveryFailed (chatid,msg)
   # Writes the delivery error message along with the timeouted 'msg' into the
   # window related to 'chatid'
   proc DeliveryFailed { chatid msg } {
      #TODO: Add translation for this
      WinWrite $chatid "Message ack timed out, delivery probably failed: " red
      WinWrite $chatid "$msg\n" gray
   }
   #///////////////////////////////////////////////////////////////////////////////

   

   #///////////////////////////////////////////////////////////////////////////////
   # closeWindow (win_name,path)
   # Called when a window and its children are destroyed. When the main window is
   # detroyed ('win_name'=='path') then it tells the protocol layer to leave the
   # chat related to 'win_name', and unsets variables used for that window
   proc closeWindow { win_name path } {

      variable window_titles

      if { "$win_name" != "$path" } {
        return 0
      }

      ::MSN::leaveChat [ChatFor $win_name]

      UnsetWindowFor [ChatFor $win_name] $win_name
      unset window_titles(${win_name})

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # PutMessage (chatid,user,msg,type,fontformat)
   # Writes a message into the window related to 'chatid'
   # - 'user' is the user login. If 'user'=="msg" then the message is taken as a
   #   system or information message, and "XXXX says:" won't be added at the beginning.
   # - 'msg' is the message itself to be displayed.
   # - 'type' can be red, gray... or any tag defined for the textbox when the windo
   #   was created, or just "user" to use the fontformat parameter
   # - 'fontformat' is a list containing font style and color
   proc PutMessage { chatid user msg type fontformat } {

	if { "$user" != "msg" } {
	       set timestamp [clock format [clock seconds] -format %H:%M]
		WinWrite $chatid "\[$timestamp\] [trans says [::MSN::userName $chatid $user]]:\n" gray
	}

	WinWrite $chatid "$msg\n" $type [lindex $fontformat 0] [lindex $fontformat 1] [lindex $fontformat 2]
	WinFlicker $chatid

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # chatStatus (chatid,msg)
   # Called by the protocol layer to show some information about the chat, that
   # should be shown in the status bar. It will only show it if the chat is not
   # ready, as most information is about connections/reconnections, and we don't
   # mind in case we have a "chat ready to chat".
   proc chatStatus {chatid msg} {

      if { [WindowFor $chatid] == 0} {
         return 0
      } else {
         #TODO: Only show messages is a chat is not active
         if {![::MSN::chatReady $chatid]} {
           WinStatus [ WindowFor $chatid ] $msg
	  }
      }

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # WinStatus (win_name,msg,[icon])
   # Writes the message 'msg' in the window 'win_name' status bar. It will add the
   # icon 'icon' at the beginning of the message, if specified.
   proc WinStatus { win_name msg {icon ""}} {

      ${win_name}.status configure -state normal
      ${win_name}.status delete 0.0 end
      if { "$icon"!=""} {
	  ${win_name}.status image create end -image $icon -pady 0 -padx 1
      }
      ${win_name}.status insert end $msg
      ${win_name}.status configure -state disabled

      #TODO: Should change the size of the top text to fit the users names
   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # WinFlicker (chatid,[count])
   # Called when a window must flicker, and called by itself to produce the flickering
   # effect. It will flicker the window until it gots the focus.
   # - 'chatid' is the name of the chat to flicker.
   # - 'count' can be any number, it's just used in self calls
   proc WinFlicker {chatid {count 0}} {

      variable window_titles

      if { [WindowFor $chatid] != 0} {
         set win_name [WindowFor $chatid]
      } else {
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

      set win_name [WindowFor $user]

      if { $win_name == 0 } {

	  set win_name [openChatWindow]
         SetWindowFor $user $win_name

      }

      set chatid [::MSN::chatTo $user]

      if { "$chatid" != "$user"} {
         status_log "Error, expected same chatid as user, but was different\n" red
         return 0
      }

      wm state $win_name normal
      wm deiconify ${win_name}

      WinTopUpdate $chatid

      #We have a window for that chatid, raise it
      raise ${win_name}
      focus ${win_name}.f.in.input

   }
   #///////////////////////////////////////////////////////////////////////////////



   #///////////////////////////////////////////////////////////////////////////////
   # WinWrite (chatid,txt,[colour],[fontname,fontstyle,fontcolor])
   # Writes 'txt' into the window related to 'chatid'
   # It will use 'colour' as style tag, unles 'colour'=="user", where it will use
   # 'fontname', 'fontstyle' and 'fontcolor' as text parameters.
   proc WinWrite {chatid txt {colour ""} {fontname ""} {fontstyle ""} {fontcolor ""}} {
      global emotions urlstarts config urlcount

      set win_name [WindowFor $chatid]

      if { [WindowFor $chatid] == 0} {
         return 0
      }

      ${win_name}.f.text configure -state normal -font bplainf -foreground black


      set text_start [${win_name}.f.text index end]
      set posyx [split $text_start "."]
      set text_start "[expr {[lindex $posyx 0]-1}].[lindex $posyx 1]"

      set tagid $colour

      if { $colour == "user" || $colour == "yours" } {
         set size [expr {[lindex $config(basefont) 1]+$config(textsize)}]
         set font "\"$fontname\" $size $fontstyle"

         set tagid [::md5::md5 "$font$fontcolor"]

         if {[catch {${win_name}.f.text tag configure $tagid -foreground #$fontcolor -font $font} res] || [string length $fontname] <3} {
            status_log "Font $font or color $fontcolor wrong. Using default\n" red
            ${win_name}.f.text tag configure $tagid -foreground black -font bplainf
         }
      }

      ${win_name}.f.text insert end "$txt" $tagid

      if {$config(keep_logs) && [sb exists $name log_fcid]} {	;# LOGS!
         puts -nonewline [sb get $name log_fcid] $txt
      }


      set endpos $text_start

      foreach url $urlstarts {

         while { $endpos != [${win_name}.f.text index end] && [set pos [${win_name}.f.text search -forward -exact -nocase \
                                 $url $endpos end]] != "" } {


	   set urltext [${win_name}.f.text get $pos end]

	   set final 0
	   set caracter [string range $urltext $final $final]
	   while { $caracter != " " && $caracter != "\n" } {
		set final [expr {$final+1}]
		set caracter [string range $urltext $final $final]
	   }

	   set urltext [string range $urltext 0 [expr {$final-1}]]

           set posyx [split $pos "."]
           set endpos "[lindex $posyx 0].[expr {[lindex $posyx 1] + $final}]"

	   set urlcount "[expr {$urlcount+1}]"
	   set urlname "url_$urlcount"

	   ${win_name}.f.text tag configure $urlname \
	      -foreground darkblue -background white -font bboldf -underline true
	      ${win_name}.f.text tag bind $urlname <Enter> \
	      "${win_name}.f.text tag conf $urlname -underline false;\
	      ${win_name}.f.text conf -cursor hand2"
	   ${win_name}.f.text tag bind $urlname <Leave> \
	      "${win_name}.f.text tag conf $urlname -underline true;\
	      ${win_name}.f.text conf -cursor left_ptr"
	   ${win_name}.f.text tag bind $urlname <Button1-ButtonRelease> \
	      "launch_browser \"$urltext\""

  	   ${win_name}.f.text delete $pos $endpos
	   ${win_name}.f.text insert $pos "$urltext" $urlname

         }
      }

      if {$config(chatsmileys)} {
         smile_subst ${win_name}.f.text $text_start
      }


      ${win_name}.f.text yview moveto 1.0
      ${win_name}.f.text configure -state disabled

   }
   #///////////////////////////////////////////////////////////////////////////////



   proc AcceptedFT { chatid cookie } {
   

      set win_name [WindowFor $chatid]

     ${win_name}.f.text configure -state normal -font bplainf -foreground black


     ${win_name}.f.text tag configure ftyes$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.text tag bind ftyes$cookie <Enter> ""
     ${win_name}.f.text tag bind ftyes$cookie <Leave> ""
     ${win_name}.f.text tag bind ftyes$cookie <Button1-ButtonRelease> ""


     ${win_name}.f.text tag configure ftno$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.text tag bind ftno$cookie <Enter> ""
     ${win_name}.f.text tag bind ftno$cookie <Leave> ""
     ${win_name}.f.text tag bind ftno$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.text conf -cursor left_ptr

     set txt [trans ftaccepted]

     #TODO: Use WinWrite or similar
     ${win_name}.f.text insert end "----------\n" gray
     ${win_name}.f.text image create end -image fticon -pady 2 -padx 3
     ${win_name}.f.text insert end " $txt\n" gray
     ${win_name}.f.text insert end "----------\n" gray

     ${win_name}.f.text yview moveto 1.0
     ${win_name}.f.text configure -state disabled
   }

   proc RejectedFT {chatid cookie} {

      set win_name [WindowFor $chatid]

     #TODO: Use WinWrite or similar (when possible)
     # Improve WinWrite to support tags, clickable text, and so on
     ${win_name}.f.text configure -state normal -font bplainf -foreground black


     ${win_name}.text tag configure ftyes$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.text tag bind ftyes$cookie <Enter> ""
     ${win_name}.f.text tag bind ftyes$cookie <Leave> ""
     ${win_name}.f.text tag bind ftyes$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.text tag configure ftno$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     ${win_name}.f.text tag bind ftno$cookie <Enter> ""
     ${win_name}.f.text tag bind ftno$cookie <Leave> ""
     ${win_name}.f.text tag bind ftno$cookie <Button1-ButtonRelease> ""

     ${win_name}.f.text conf -cursor left_ptr

     set txt [trans ftrejected]

     ${win_name}.f.text insert end "----------\n" gray
     ${win_name}.f.text image create end -image ftreject -pady 2 -padx 3
     ${win_name}.f.text insert end "$txt\n" gray
     ${win_name}.f.text insert end "----------\n" gray

     ${win_name}.f.text yview moveto 1.0
     ${win_name}.f.text configure -state disabled
   }

   #PRIVATE: Opens Sending Window
   proc SendWin {filename cookie} {
      status_log "Creating send progress window\n"
      set w .ft$cookie
      toplevel $w
      wm title $w "[trans sendfile] $filename"
      wm geometry $w 300x100

      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans cancel]" -command "::MSN::cancelSending $cookie"
      pack $w.close -side bottom
      
      pack [::dkfprogress::Progress $w.prbar] -fill x -expand 1 -padx 5 -pady 5


      wm protocol $w WM_DELETE_WINDOW "::MSN::cancelSending $cookie"
   }

   #PRIVATE: Opens Receiving Window
   proc RecvWin {filename cookie} {
     status_log "Creating receive progress window\n"
      set w .ft$cookie
      toplevel $w
      wm title $w "[trans receivefile] $filename"
      wm geometry $w 300x100

      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans cancel]" -command "::MSN::cancelReceiving $cookie"
      pack $w.close -side bottom

      pack [::dkfprogress::Progress $w.prbar] -fill x -expand 1 -padx 5 -pady 5
      
      wm protocol $w WM_DELETE_WINDOW "::MSN::cancelReceiving $cookie"     
   }


   #Updates filetransfer progress window/baar
   #fileTransferProgress mode cookie bytes filesize
   # mode: c=Cancel
   #       s=Sending
   #       r=Receiving
   # cookie: ID for the filetransfer
   # bytes: bytes sent/received (-1 if cancelling)
   # filesize: total bytes in the file
   proc fileTransferProgress {mode cookie bytes filesize} {
      # -1 in bytes to transfer cancelled
      # bytes >= filesize for connection finished
      set w .ft$cookie

      if { [winfo exists $w] == 0} {
        return
      }

      if { $mode == "p" } {
	 $w.progress configure -text "[trans listeningon $bytes]"
	 return
      } 

      
      if { $bytes <0 } {
	 $w.progress configure -text "[trans filetransfercancelled]"
      } elseif { $bytes >= $filesize } {
	 ::dkfprogress::SetProgress $w.prbar 100
	 $w.progress configure -text "[trans filetransfercomplete]"
      }

      set bytes2 [expr {$bytes/1024}]
      set filesize2 [expr {$filesize/1024}]
      if { $filesize2 != 0 } {
        set percent [expr {($bytes2*100)/$filesize2}]
      } else {
        set percent 100
      }

      if { ($bytes >= $filesize) || ($bytes<0)} {
	 $w.close configure -text "[trans close]" -command "destroy $w"
         wm protocol $w WM_DELETE_WINDOW "destroy $w"
      } elseif { $mode == "r" } {
	 $w.progress configure -text "[trans receivedbytes $bytes2 [list $filesize2 Kb]]"
	 ::dkfprogress::SetProgress $w.prbar $percent
      } else {
	 $w.progress configure -text "[trans sentbytes $bytes2 [list $filesize2 Kb]]"
	 ::dkfprogress::SetProgress $w.prbar $percent
      }
   }

   variable NotifID 0
   variable NotifPos [list]
   variable im [image create photo -width 180 -height 110]

   
   #TODO: We will make amsn skinnable, so this should be used only if there not exists
   # a background bitmap for the notifyWindow
   for {set i 0} {$i < 110} {incr i} {
      set rg [expr {35+$i*2}]
      set col [format "%2.2X%2.2XFF" $rg $rg]
      $im put "#$col" -to 0 $i 180 [expr {$i + 1}]
   }

   proc close {} {
      set answer [tk_messageBox -message "[trans exitamsn]" -type yesno -icon question -title [trans title]]
      if {$answer == "yes"} {
         close_cleanup
         exit
      }
   }

   proc closeOrDock { closingdocks } {
     if {$closingdocks} {
        wm iconify .
     } else {
        ::amsn::close
     }
   }


   #Adds a message to the notify, that executes "command" when clicked, and
   #plays "sound"
   proc notifyAdd { msg command {sound ""}} {

      global config

      if { $config(notifywin) == 0 } {
        return;
      }
      variable NotifID
      variable NotifPos
      variable im
      global images_folder

      set w .notif$NotifID
      incr NotifID

      toplevel $w -width 1 -height 1
      wm state $w withdrawn

      set xpos $config(notifyXoffset)
      set ypos $config(notifyYoffset)

      while { [lsearch -exact $NotifPos $ypos] >=0 } {
        set ypos [expr {$ypos+105}]
      }
      lappend NotifPos $ypos


      if { $xpos < 0 } { set xpos 0 }
      if { $ypos < 0 } { set ypos 0 }

      wm geometry $w -$xpos-$ypos

      canvas $w.c -bg #EEEEFF -width 150 -height 100 \
         -relief ridge -borderwidth 2
      pack $w.c


      $w.c create image 75 50 -image $im
      $w.c create image 17 22 -image notifico
      $w.c create image 80 97 -image notifybar

      if {[string length $msg] >100} {
         set msg "[string range $msg 0 100]..."
      }

      set notify_id [$w.c create text 78 40 -font splainf \
         -justify center -width 148 -anchor n -text "$msg"]

      $w.c bind $notify_id <Enter> \
         "$w.c conf -cursor hand2"

      $w.c bind $notify_id <Leave> \
         "$w.c conf -cursor left_ptr"

      set after_id [after 8000 "::amsn::KillNotify $w $ypos"]

      $w.c bind $notify_id <ButtonRelease-1> "after cancel $after_id;\
        ::amsn::KillNotify $w $ypos; $command"

      $w.c bind $notify_id <ButtonRelease-3> "after cancel $after_id;\
        ::amsn::KillNotify $w $ypos"

      wm title $w "[trans msn] [trans notify]"
      wm overrideredirect $w 1
      #wm transient $w
      wm state $w normal

      raise $w

      if { $sound != ""} {
         sonido $sound
      }


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
