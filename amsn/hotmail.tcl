proc hotmail_login {userlogin {pass ""}} {
# Note: pass can be empty, so user must enter password in the login
# page.
#
# $Id$
#
  global tcl_platform HOME program_dir config

  if {($config(autohotlogin)) && ($pass != "")} {

    set read_id [open "${program_dir}/hotmlog.htm" r]

    set page_data ""
    while {[gets $read_id tmp_data] != "-1"} {
      set page_data "$page_data $tmp_data"
    }

    close $read_id

    set userdata [split $userlogin "@"]
   
    set user [lindex $userdata 0]
    set domain [lindex $userdata 1]

    set page_data [subst -nocommands -nobackslashes $page_data]

    if {$tcl_platform(platform) == "unix"} {
      set file_id [open "${HOME}/hotlog.htm" w 00600]
    } else {
      set file_id [open "${HOME}/hotlog.htm" w]
    }

     puts $file_id $page_data

     close $file_id

     launch_browser "file://${HOME}/hotlog.htm"
   } else {
     launch_browser "http://www.hotmail.com"
   }

}
