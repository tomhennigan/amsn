
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
  
   proc FileTransferSendOk { w twn entry } {
      set filename [ $entry get ]  
      destroy $w 
      ::amsn::SendWin $twn $filename
      ::MSN::inviteFT $twn $filename
   }
     
   proc fileTransferRecv {filename filesize cookie sb_name} {
      global files_dir
      set answer [tk_messageBox -message "[trans acceptfile $filename $filesize $files_dir]" -type yesno -icon question]
      if {$answer == "yes"} {
         ::amsn::RecvWin $sb_name $cookie $filename
         ::MSN::acceptFT $cookie $sb_name
      } else {
         ::MSN::rejectFT $sb_name $cookie
      }
   }

   proc SendWin {sbn filename} {
      status_log "Creating send progress window\n"
      set w .ft$sbn
      toplevel $w
      wm title $w "[trans sendfile] $filename"

      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans close]" -command "destroy $w"
      pack $w.close -side bottom
      
      bind $w <Destroy> "::MSN::cancelSending"
   }
   
   proc RecvWin {sbn cookie filename} {
     status_log "Creating receive progress window\n"
      set w .ft$sbn
      toplevel $w
      wm title $w "[trans receivefile] $filename"

      label $w.file -text "$filename"
      pack $w.file -side top
      label $w.progress -text "Waiting for file transfer to start"
      pack $w.progress -side top
      
      button $w.close -text "[trans close]" -command "destroy $w"
      pack $w.close -side bottom
      
      bind $w <Destroy> "::MSN::cancelReceiving"     
   }

   
   proc fileTransferProgress {mode sbn bytes filesize} {
      set w .ft$sbn
		     
      if { $bytes >= $filesize } {
	 $w.progress configure -text "[trans filetransfercomplete]"
      }
      
      if { $mode == "r" } {
	 $w.progress configure -text "[trans receivedbytes $bytes $filesize]"
      } else {
	 $w.progress configure -text "[trans sentbytes $bytes $filesize]"
      }
   }
}
