#
# $Id$
#
set config(login) ""			;# These are defaults for users without
set config(save_password) 0		;# a config file
set config(keep_logs) 0
set config(proxy) ""
set config(withproxy) 0			;# 1 to enable proxy settings
set config(start_ns_server) "messenger.hotmail.com:1863"
set config(last_client_version) ""
#by AIM
set config(sound) 1
set config(browser) "mozilla"
set config(soundcommand) "esdplay"
set config(language) "en"
set config(adverts) 0
set config(autohotlogin) 1
set config(showonline) 1
set config(showoffline) 1
set config(listsmileys) 1
set config(chatsmileys) 1
set config(startoffline) 0
#end AIM

set password ""


proc save_config {} {
   global tcl_platform config HOME version password

   if {$tcl_platform(platform) == "unix"} {
      set file_id [open "${HOME}/config" w 00600]
   } else {
      set file_id [open "${HOME}/config" w]
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

   if {([file readable "${HOME}/config"] == 0) ||
       ([file isfile "${HOME}/config"] == 0)} {
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
      set var_value [lindex $var_data 1]
      set config($var_attribute) $var_value
   }
   if {[info exists config(password)]} {
      set password $config(password)
      unset config(password)
   }
   close $file_id
}

