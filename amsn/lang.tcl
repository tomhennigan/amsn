set lang_list [list]

proc scan_languages {} {
   global lang_list program_dir
   set lang_list [list]

   set file_id [open "[file join $program_dir langlist]" r]

   while {[gets $file_id tmp_data] != "-1"} {
      set pos [string first " " $tmp_data]
      set langshort [string range $tmp_data 0 [expr {$pos -1}]]
      set pos [expr {$pos + 1}]
      set pos2 [string first " " $tmp_data $pos]
      set langenc [string range $tmp_data $pos [expr {$pos2 -1}]]
      set langlong [string range $tmp_data [expr {$pos2 +1}] [string length $tmp_data]]
      lappend lang_list "{$langshort} {$langlong} {$langenc}"
   }
   close $file_id

}

proc trans {msg args} {
global lang
  for {set i 1} {$i <= [llength $args]} {incr i} {
     set $i [lindex $args [expr {$i-1}]]
  }
   if {[ catch {
         if { [string length $lang($msg)] > 0 } {
            return [subst -nocommands $lang($msg)]
         } else {
            return "$msg $args"
         }
      }  res] == 1} {
      return "$msg $args"
   } else {
      return $res
   }

}


#Lectura del idioma
proc load_lang {} {
   global config lang program_dir lang_list

   set file_id [open "[file join $program_dir lang/lang$config(language)]" r]

   set langenc ""

   foreach langdata $lang_list {
   	if { [string compare [lindex $langdata 0]  $config(language)] == 0 } {
	  set langenc [lindex $langdata 2]
	}
   }

   fconfigure $file_id -encoding $langenc

   gets $file_id tmp_data
   if {$tmp_data != "amsn_lang_version 2"} {	;# config version not supported!
      return 1
   }

   while {[gets $file_id tmp_data] != "-1"} {
      set pos [string first " " $tmp_data]
      set l_msg [string range $tmp_data 0 [expr {$pos -1}]]
      set l_trans [string range $tmp_data [expr {$pos +1}] [string length $tmp_data]]
      set lang($l_msg) $l_trans
   }
   close $file_id
   return 0
}
