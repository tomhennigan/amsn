
namespace eval ::amsn {
   namespace export fileTransferSend fileTransferRecv fileTransferProgress errorMsg 
   
   proc errorMsg { msg } {
      tk_messageBox -type ok -icon error -message $msg -title "[trans title] Error" 
   }
   
   proc fileTransferSend { twn title } {

      set w .senfile$title
      toplevel $w
      wm title $w "[trans sendfile]"
      label $w.msg -justify center -text "[trans enterfilename]"
      pack $w.msg -side top


      frame $w.buttons
      pack $w.buttons -side bottom -fill x -pady 2m
      button $w.buttons.dismiss -text [trans cancel] -command "destroy $w"
      button $w.buttons.save -text "[trans ok]" \
        -command "::amsn::FileTransferSendOk $w $twn $w.filename.entry"
      pack $w.buttons.save $w.buttons.dismiss -side left -expand 1

      frame $w.options
      entry $w.options.ipentry -relief sunken -width 20 
      label $w.options.iplabel -text "[trans ipaddress]"
      pack $w.options.ipentry -side right
      pack $w.options.iplabel -side right
      pack $w.options -side bottom -fill x 


      frame $w.filename -bd 2
      entry $w.filename.entry -relief sunken -width 40 
      label $w.filename.label -text "[trans filename]"
      pack $w.filename.entry -side right
      pack $w.filename.label -side left
      pack $w.msg $w.filename -side top -fill x


      focus $w.filename.entry

      fileDialog2 $w $w.filename.entry open Untitled
   }
  
   proc FileTransferSendOk { w sbn entry } {
      set filename [ $entry get ]  
      destroy $w 

      #Calculate a random cookie
      set cookie [expr {[clock clicks]  % (65536 * 4)}]     
      
      status_log "Random generated cookie: $cookie\n"
      
      ::amsn::SendWin $filename $cookie
      ::MSN::inviteFT $sbn $filename $cookie
      return 0
   }
     
   proc fileTransferRecv {filename filesize cookie sb_name} {
      global files_dir
      set answer [tk_messageBox -message "[trans acceptfile $filename $filesize $files_dir]" -type yesno -icon question -title [trans receivefile]]
      if {$answer == "yes"} {
         ::amsn::RecvWin $filename $cookie 
         ::MSN::acceptFT $sb_name $filename $filesize $cookie
      } else {
         ::MSN::rejectFT $sb_name $cookie
      }
   }

   proc SendWin {filename cookie} {
      status_log "Creating send progress window\n"
      set w .ft$cookie
      toplevel $w
      wm title $w "[trans sendfile] $filename"

      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans cancel]" -command "::MSN::cancelSending $cookie"
      pack $w.close -side bottom
      
      wm protocol $w WM_DELETE_WINDOW "::MSN::cancelSending $cookie"
   }
   
   proc RecvWin {filename cookie} {
     status_log "Creating receive progress window\n"
      set w .ft$cookie
      toplevel $w
      wm title $w "[trans receivefile] $filename"

      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans cancel]" -command "::MSN::cancelReceiving $cookie"
      pack $w.close -side bottom
      
      wm protocol $w WM_DELETE_WINDOW "::MSN::cancelReceiving $cookie"     
   }

   
   proc fileTransferProgress {mode cookie bytes filesize} {
      # -1 in bytes to transfer cancelled
      # bytes >= filesize for connection finished
      set w .ft$cookie
      
      if { [winfo exists $w] == 0} {
        return 1
      }
      
      if { $bytes <0 } {
	 $w.progress configure -text "[trans filetransfercancelled]"
      } elseif { $bytes >= $filesize } {
	 $w.progress configure -text "[trans filetransfercomplete]"
      }
      
      if { ($bytes >= $filesize) || ($bytes<0)} {
	 $w.close configure -text "[trans close]" -command "destroy $w"
         wm protocol $w WM_DELETE_WINDOW "destroy $w"
      } elseif { $mode == "r" } {
	 $w.progress configure -text "[trans receivedbytes $bytes $filesize]"
      } else {
	 $w.progress configure -text "[trans sentbytes $bytes $filesize]"
      }
   }
   
}
