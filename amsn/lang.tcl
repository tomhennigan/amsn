#This is the default language
set lang(about) "about"
set lang(addacontact) "Add a contact"
set lang(addedyou) "has added you to his/her contact list"
set lang(addtoo) "Add this person to my contact list"
set lang(adverts) "Advertisement"
set lang(allowseen) "Allow this person to see when I'm online and contact me"
set lang(appearoff) "Appear offline"
set lang(are) "are"
set lang(autohotmaillog) "Hotmail autologin"
set lang(avoidseen) "Avoid this person can see when I'm online and contact me"
set lang(away) "Away"
set lang(blankdirect) "Leave blank for direct connection"
set lang(block) "Block"
set lang(busy) "Busy"
set lang(cancel) "Cancel"
set lang(changenick) "Change nick"
set lang(chat) "Chat"
set lang(chatreq) "Requesting chat"
set lang(chatack) "Accepting chat from"
set lang(checkver) "Check for new version"
set lang(checkingver) "Checking for new versions"
set lang(clicktologin) "Click here to log in"
set lang(close) "Close"
set lang(contactadded) "Contact added"
set lang(connecterror) "Error connecting to server"
set lang(date) "Date"
set lang(delete) "Delete"
set lang(entercontactemail) "Enter contact e-mail"
set lang(enternick) "Enter your nick"
set lang(examples) "Examples"
set lang(gonelunch) "Gone to lunch"
set lang(help) "Help"
set lang(ident) "Identifying"
set lang(invite) "Invite"
set lang(is) "is"
set lang(joins) "\$1 \$2 joins conversation"
set lang(language) "Language"
set lang(leaves) "\$1 leaves conversation"
set lang(loggingin) "Logging In"
set lang(login) "Log In"
set lang(logout) "Log Out"
set lang(logsin) "has just logged in"
set lang(mustrestart) "You must restart the program to apply changes"
set lang(mystatus) "My status"
set lang(msg) "Message"
set lang(msn) "AMSN"
set lang(newmail) "\$1 new messages in In-Box"
set lang(newmailfrom) "New mail from"
set lang(newmsg) "New message"
set lang(newveravailable) "Newer version \$1 available for download"
set lang(next) "Next"
set lang(noactivity) "No activity"
set lang(nonewver) "There are no new versions available to download"
set lang(notify) "notify"
set lang(nousersinsession) "No users in session"
set lang(ok) "Ok"
set lang(offline) "Offline"
set lang(online) "Online"
set lang(onphone) "On phone"
set lang(other) "Other"
set lang(pass) "Password"
set lang(port) "Port"
set lang(proxyconf) "Proxy configuration"
set lang(proxyconfhttp) "HTTP proxy support configuration"
set lang(reconnect) "Waiting for \$1 to reconnect"
set lang(reconnecting) "Reconnecting to server"
set lang(rememberpass) "Remember password"
set lang(rightback) "Be right back"
set lang(says) "\$1 says"
set lang(sbcon) "Conecting to Switch Board"
set lang(send) "Send"
set lang(server) "Server"
set lang(sound) "Event Sound"
set lang(title) "Al's Messenger"
set lang(to) "To"
set lang(typing) "\$1 typing a message"
set lang(yousay) "You say"
set lang(youwant) "You want"
set lang(unblock) "Unblock"
set lang(uoffline) "Offline"
set lang(uonline) "Online"
set lang(user) "User"
set lang(version) "Version"
set lang(willjoin) "Waiting \$1 joins conversation"

set lang_list [list]

proc scan_languages {} { 
   global lang_list program_dir
   set lang_list [list]

   set file_id [open "[file join $program_dir langlist]" r]

   while {[gets $file_id tmp_data] != "-1"} {
      set pos [string first " " $tmp_data]
      set langshort [string range $tmp_data 0 [expr $pos -1]]
      set langlong [string range $tmp_data [expr $pos +1] [string length $tmp_data]]
      lappend lang_list "{$langshort} {$langlong}"
   }
   close $file_id

}

proc trans {msg args} {
global lang
 for {set i 1} {$i <= [llength $args]} {incr i} {
    set $i [lindex $args [expr $i-1]]
 }
 
if {[ catch {
          if { [string length $lang($msg)] > 0 } {
            return [subst -nobackslashes -nocommands $lang($msg)]
          } else {
            return $msg
          }
       }  res] == 1} {
    return $msg
  } else {
    return $res
  }

}


#Lectura del idioma
proc load_lang {} {
   global config lang program_dir

   set file_id [open "[file join $program_dir lang/lang$config(language)]" r]
   gets $file_id tmp_data
   if {$tmp_data != "amsn_lang_version 2"} {	;# config version not supported!
      return 1
   }

   while {[gets $file_id tmp_data] != "-1"} {
      set pos [string first " " $tmp_data]
      set l_msg [string range $tmp_data 0 [expr $pos -1]]
      set l_trans [string range $tmp_data [expr $pos +1] [string length $tmp_data]]
      set lang($l_msg) $l_trans
   }
   close $file_id
}
