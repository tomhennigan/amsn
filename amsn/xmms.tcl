# XMMS Plugin for aMSN

set paths [split $env(PATH) ":"]

foreach path $paths { if {[file exist $path/xmms]} { set found 1 } }

if {[info exist found]} {

 set xmms(loaded) 1

 proc GetSong {} {
  set file "/tmp/xmms-info"
  if {![file exist $file]} {return 0}

  set gets [open $file r]

  while {![eof $gets]} {

   set tmp [gets $gets]
   set info([lindex $tmp 0]) [lrange $tmp 1 end]
   unset tmp

  }

  close $gets

  switch -- $info(Status:) {
   "Playing" { lappend return $info(Title:); lappend return $info(File:) }
   "Paused" { lappend return $info(Title:); lappend return $info(File:) }
   "Stopped" { set return 0 }
   default { set return 0 }
  }
  return $return
 }

 proc xmms {win_name action} {

  set info [GetSong]
  set song [lindex $info 0]
  set file [lindex $info 1]

  if {$info == "0"} { msg_box [trans xmmserr]; return 0 }

  if {$action == "1"} {
   ::amsn::MessageSend .${win_name} 0 "[trans playing $song]"
  } elseif {$action == "2"} {
#   ::MSNFT::SendFile ${win_name} $file
   return 0
  }
 }
 return 1
}
