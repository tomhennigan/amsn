# XMMS Plugin for aMSN

set paths [split $env(PATH) ":"]

foreach path $paths { if {[file exist $path/xmms]} { set found 1 } }

if {[info exist found]} {

 set xmms(loaded) 1

 proc GetSong {} {
  set file "/tmp/xmms-info"
  if {![file exist $file]} {return 0}

  set gets [open $file r]
  gets $gets; gets $gets; set match [gets $gets]
  switch -- [lindex $match 1] {
   "Playing" {
    gets $gets; gets $gets; gets $gets; gets $gets; gets $gets; gets $gets; 
    gets $gets; gets $gets; gets $gets; set match [gets $gets]
    return [lrange $match 1 end]
   }
   "Stopped" {
    return 0
   }
   "Paused" {
    gets $gets; gets $gets; gets $gets; gets $gets; gets $gets; gets $gets;
    gets $gets; gets $gets; gets $gets; set match [gets $gets]
    return [lrange $match 1 end] 
   }
  }
 }

 proc xmms {win_name} {

  if {[GetSong] == "0"} { msg_box "Nothing is playing, or you dont have xmms-infopipe installed." }

  ::amsn::MessageSend .${win_name} 0 "Playing: [GetSong]"
 }
}
