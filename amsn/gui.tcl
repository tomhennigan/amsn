
namespace eval ::amsn {
   namespace export fileTransfer fileTransferProgress errorMsg
   
   proc errorMsg { msg } {
      tk_messageBox -type ok -icon error -message $msg -title "[trans title] Error" 
   }
   
   proc fileTransfer {filename filesize cookie sb_name} {
      global files_dir
      set answer [tk_messageBox -message "[trans acceptfile $filename $filesize $files_dir]" -type yesno -icon question]
      if {$answer == "yes"} {
         ::MSN::acceptFT $cookie $sb_name
      } else {
         ::MSN::rejectFT $sb_name $cookie
      }
   }
   
   proc fileTransferProgress {mode sbn bytes filesize} {
      set win_name "msg_[string tolower ${sbn}]"
			
      #Windows closed?
      .${win_name}.status configure -state normal
      .${win_name}.status delete 0.0 end
      
      if { $bytes == $filesize } {
        .${win_name}.status insert end "[trans filetransfercomplete]\n"         
      }
      
      if { $mode == "r" } {
        .${win_name}.status insert end "[trans receivedbytes $bytes $filesize].\n"
      } else {
        .${win_name}.status insert end "[trans sentbytes $bytes $filesize].\n"
      }
      .${win_name}.status configure -state disabled
   }
}
