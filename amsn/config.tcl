#
# $Id$
#
set config(login) ""			;# These are defaults for users without
set config(save_password) 0		;# a config file
set config(keep_logs) 0
set config(proxy) ""
set config(withproxy) 0			;# 1 to enable proxy settings
set config(proxytype) "http"		;# http|socks
set config(proxyuser) ""		;# SOCKS5
set config(proxypass) ""		;# SOCKS5
set config(proxyauthenticate) 0		;# SOCKS5 use username/password
set config(start_ns_server) "messenger.hotmail.com:1863"
set config(last_client_version) ""
#by AIM
set config(sound) 1
set config(mailcommand) ""


if {$tcl_platform(platform) == "unix"} {
   set config(soundcommand) "play"
   set config(browser) "mozilla"
   set config(notifyXoffset) 0
   set config(notifyYoffset) 0
   set config(filemanager) ""
} elseif {$tcl_platform(platform) == "windows"} {
   set config(soundcommand) "plwav.exe"
   set config(browser) "explorer"
   set config(notifyXoffset) 0
   set config(notifyYoffset) 28
   set config(filemanager) "start"
} else {
   set config(soundcommand) ""
   set config(browser) ""
   set config(notifyXoffset) 0
   set config(notifyYoffset) 0
   set config(filemanager) ""
}



set config(language) "en"
set config(adverts) 0
set config(autohotlogin) 1
set config(autoidle) 1
set config(showonline) 1
set config(showoffline) 1
set config(listsmileys) 1
set config(chatsmileys) 1
set config(startoffline) 0
set config(autoftip) 1
set config(myip) "127.0.0.1"
set config(wingeometry) 275x400-0+0
set config(closingdocks) 0
set config(backgroundcolor)  "#AABBCC"
set config(encoding) auto
set config(basefont) "Helvetica 11 normal"
set config(backgroundcolor) #D8D8E0
set config(textsize) 2
set config(mychatfont) "{Helvetica} {} 000000"
#end AIM
set config(orderbygroup) 0
set config(withnotebook) 0
set config(keepalive) 0
set config(notifywin) 1
set config(natip) 0
set config(dock) 0

set password ""


namespace eval ::config {
   proc get {key} {
     global config
     return $config($key)
   }

   proc set {key value} {
     global config
     set config($key) $value
   }
}

proc save_config {} {
   global tcl_platform config HOME version password

   if {$tcl_platform(platform) == "unix"} {
		set file_id [open "[file join ${HOME} config]" w 00600]
   } else {
      set file_id [open "[file join ${HOME} config]" w]
   }
   puts $file_id "amsn_config_version 1"
   set config(last_client_version) $version

   set config_entries [array get config]
   set items [llength $config_entries]
   for {set idx 0} {$idx < $items} {incr idx 1} {
      set var_attribute [lindex $config_entries $idx]; incr idx 1
      set var_value [lindex $config_entries $idx]
      puts $file_id "$var_attribute $var_value"
   }
   if {$config(save_password)} {
      puts $file_id "password ${password}"
   }
   close $file_id
}

proc load_config {} {
   global config HOME password

   if {([file readable "[file join ${HOME} config]"] == 0) ||
       ([file isfile "[file join ${HOME}/config]"] == 0)} {
      return 1
   }
   set file_id [open "${HOME}/config" r]
   gets $file_id tmp_data
   if {$tmp_data != "amsn_config_version 1"} {	;# config version not supported!
      return 1
   }
   while {[gets $file_id tmp_data] != "-1"} {
      set var_data [split $tmp_data]
      set var_attribute [lindex $var_data 0]
      set var_value [join [lrange $var_data 1 end]]
      set config($var_attribute) $var_value
   }
   if {[info exists config(password)]} {
      set password $config(password)
      unset config(password)
   }
   close $file_id
}

