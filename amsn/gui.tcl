#Default look


namespace eval ::amsn {
   namespace export fileTransferSend fileTransferRecv fileTransferProgress \
   errorMsg notifyAdd initLook 
   
   ##PUBLIC

   proc initLook { family size bgcolor} {

      #puts "family: $family size: $size\n"

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
   
   #Shows an error message
   proc errorMsg { msg } {
      tk_messageBox -type ok -icon error -message $msg -title "[trans title] Error" 
   }
   
   #fileTransferSend Switchboardane Windowtitle
   #Still need to improve
   proc fileTransferSend { twn title } {
      global config

      set ipaddr "[::MSN::getMyIP]"

      set w .sendfile$title
      toplevel $w
      wm title $w "[trans sendfile]"
      label $w.msg -justify center -text "[trans enterfilename]"
      pack $w.msg -side top -pady 5

      frame $w.buttons
      pack $w.buttons -side bottom -fill x -pady 2m
      button $w.buttons.dismiss -text [trans cancel] -command "destroy $w"
      button $w.buttons.save -text "[trans ok]" \
        -command "::amsn::FileTransferSendOk $w $twn"
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
  
   #PRIVATE: called by the fileTransferSend Dialog
   proc FileTransferSendOk { w sbn } {
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
      ::MSN::inviteFT $sbn $filename $cookie $ipaddr
      
      
      return 0
   }
     
   #Dialog shown when receiving a file
   proc fileTransferRecv {filename filesize cookie sb_name fromlogin fromname} {
      global files_dir

      #Newer version

      set win_name "msg_[string tolower ${sb_name}]"

     .${win_name}.text configure -state normal -font bplainf -foreground black
      

     .${win_name}.text tag configure ftyes$cookie \
       -foreground darkblue -background white -font bboldf -underline false
     .${win_name}.text tag bind ftyes$cookie <Enter> \
       ".${win_name}.text tag conf ftyes$cookie -underline true;\
       .${win_name}.text conf -cursor hand2"
     .${win_name}.text tag bind ftyes$cookie <Leave> \
       ".${win_name}.text tag conf ftyes$cookie -underline false;\
       .${win_name}.text conf -cursor left_ptr"
     .${win_name}.text tag bind ftyes$cookie <Button1-ButtonRelease> \
       "::amsn::AcceptedFT $sb_name $cookie; ::amsn::RecvWin $filename $cookie; ::MSN::acceptFT $sb_name $filename $filesize $cookie"

     .${win_name}.text tag configure ftno$cookie \
       -foreground darkblue -background white -font bboldf -underline false
     .${win_name}.text tag bind ftno$cookie <Enter> \
       ".${win_name}.text tag conf ftno$cookie -underline true;\
       .${win_name}.text conf -cursor hand2"
     .${win_name}.text tag bind ftno$cookie <Leave> \
       ".${win_name}.text tag conf ftno$cookie -underline false;\
       .${win_name}.text conf -cursor left_ptr"
     .${win_name}.text tag bind ftno$cookie <Button1-ButtonRelease> \
       "::amsn::RejectedFT $sb_name $cookie; ::MSN::rejectFT $sb_name $cookie"


     set timestamp [clock format [clock seconds] -format %H:%M]

     set txt [trans acceptfile '$filename' $filesize $files_dir]

     .${win_name}.text insert end "----------\n" gray
     .${win_name}.text image create end -image fticon -pady 2 -padx 3
     .${win_name}.text insert end "\[$timestamp\] $fromname: $txt" gray
     .${win_name}.text insert end " - (" gray
     .${win_name}.text insert end "[trans accept]" ftyes$cookie
     .${win_name}.text insert end " / " gray
     .${win_name}.text insert end "[trans reject]" ftno$cookie
     .${win_name}.text insert end " )\n" gray
     .${win_name}.text insert end "----------\n" gray

     .${win_name}.text yview moveto 1.0
     .${win_name}.text configure -state disabled

      #Trozo repetido en cmsn_sb_msg (protocol.tcl)
      #Hace falta unificar el sistema de ventanas de chat

      cmsn_msgwin_flicker $sb_name 20
      set win_name "msg_[string tolower ${sb_name}]"

      if { [string compare [wm state .${win_name}] "withdrawn"] == 0 } {
        wm state .${win_name} iconic
	::amsn::notifyAdd "[trans says $fromname]:\n$txt" \
	   "wm state .${win_name} normal"
      }            

      if { [string first $win_name [focus]] != 1 } {
        sonido type
      }


   }


   proc AcceptedFT {sb_name cookie} {

      set win_name "msg_[string tolower ${sb_name}]"

     .${win_name}.text configure -state normal -font bplainf -foreground black


     .${win_name}.text tag configure ftyes$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     .${win_name}.text tag bind ftyes$cookie <Enter> ""
     .${win_name}.text tag bind ftyes$cookie <Leave> ""
     .${win_name}.text tag bind ftyes$cookie <Button1-ButtonRelease> ""


     .${win_name}.text tag configure ftno$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     .${win_name}.text tag bind ftno$cookie <Enter> ""
     .${win_name}.text tag bind ftno$cookie <Leave> ""
     .${win_name}.text tag bind ftno$cookie <Button1-ButtonRelease> ""

     .${win_name}.text conf -cursor left_ptr

     set txt [trans ftaccepted]

     .${win_name}.text insert end "----------\n" gray
     .${win_name}.text image create end -image fticon -pady 2 -padx 3
     .${win_name}.text insert end " $txt\n" gray
     .${win_name}.text insert end "----------\n" gray

     .${win_name}.text yview moveto 1.0
     .${win_name}.text configure -state disabled
   }

   proc RejectedFT {sb_name cookie} {

      set win_name "msg_[string tolower ${sb_name}]"

     .${win_name}.text configure -state normal -font bplainf -foreground black


     .${win_name}.text tag configure ftyes$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     .${win_name}.text tag bind ftyes$cookie <Enter> ""
     .${win_name}.text tag bind ftyes$cookie <Leave> ""
     .${win_name}.text tag bind ftyes$cookie <Button1-ButtonRelease> ""

     .${win_name}.text tag configure ftno$cookie \
       -foreground #808080 -background white -font bplainf -underline false
     .${win_name}.text tag bind ftno$cookie <Enter> ""
     .${win_name}.text tag bind ftno$cookie <Leave> ""
     .${win_name}.text tag bind ftno$cookie <Button1-ButtonRelease> ""

     .${win_name}.text conf -cursor left_ptr

     set txt [trans ftrejected]

     .${win_name}.text insert end "----------\n" gray
     .${win_name}.text image create end -image ftreject -pady 2 -padx 3
     .${win_name}.text insert end "$txt\n" gray
     .${win_name}.text insert end "----------\n" gray

     .${win_name}.text yview moveto 1.0
     .${win_name}.text configure -state disabled
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
      set filesize2 "[expr {$filesize/1024}] Kb"      
      set cien 100
      set percent [expr {$bytes*100/$filesize}]
      
      if { ($bytes >= $filesize) || ($bytes<0)} {
	 $w.close configure -text "[trans close]" -command "destroy $w"
         wm protocol $w WM_DELETE_WINDOW "destroy $w"
      } elseif { $mode == "r" } {
	 $w.progress configure -text "[trans receivedbytes $bytes2 $filesize2]"
	 ::dkfprogress::SetProgress $w.prbar $percent
      } else {
	 $w.progress configure -text "[trans sentbytes $bytes2 $filesize2]"
	 ::dkfprogress::SetProgress $w.prbar $percent
      }
   }
   
   variable NotifID 0
   variable NotifPos [list]
   variable im [image create photo -width 180 -height 110]

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
      variable NotifID
      variable NotifPos
      variable im
      global images_folder

      set w .notif$NotifID
      incr NotifID
      
      toplevel $w -width 1 -height 1
      wm state $w withdrawn
            
      set ypos 0      
      while { [lsearch -exact $NotifPos $ypos] >=0 } {
        set ypos [expr {$ypos+105}]
      }      
      lappend NotifPos $ypos
      
      wm geometry $w -0-$ypos      
         
      canvas $w.c -bg #EEEEFF -width 150 -height 100 \
         -relief ridge -borderwidth 2
      pack $w.c


      $w.c create image 75 50 -image $im 
      $w.c create image 17 22 -image notifico
      $w.c create image 80 97 -image notifybar

      if {[string length $msg] >100} {
         set msg "[string range $msg 0 100]..."
      } 
   
      set notify_id [$w.c create text 75 63 -font splainf \
         -justify center -width 145 -text "$msg"]

      $w.c bind $notify_id <Enter> \
         "$w.c conf -cursor hand2"

      $w.c bind $notify_id <Leave> \
         "$w.c conf -cursor left_ptr"
      
      set after_id [after 8000 "::amsn::KillNotify $w $ypos"]

      $w.c bind $notify_id <Button-1> "after cancel $after_id;\
        ::amsn::KillNotify $w $ypos; $command"

      $w.c bind $notify_id <Button-3> "after cancel $after_id;\
        ::amsn::KillNotify $w $ypos"
      
      wm title $w "[trans msn] [trans notify]"
      wm overrideredirect $w 1
      wm transient $w
      wm state $w normal
      
      raise $w
      
      if { $sound != ""} {
         sonido $sound
      }


   }
   
   proc KillNotify { w ypos } {
      variable NotifPos
      destroy $w
      set lpos [lsearch -exact $NotifPos $ypos]
      set NotifPos [lreplace $NotifPos $lpos $lpos]
   }
   
}
