
if { $initialize_amsn == 1 } {
    global lang_list langenc langlong

    set lang_list [list]
    set langenc "iso8859-1"
    set langlong "English"
}

proc scan_languages {} {
   global lang_list
   set lang_list [list]

   set file_id [open "langlist" r]
   fconfigure $file_id -encoding utf-8


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
				if {[llength $args]>0} {
					return "$msg $args"
				} else {
					return "$msg"
				}
			}
		}  res] == 1} {
		if {[llength $args]>0} {
			return "$msg $args"
		} else {
			return "$msg"
		}
	} else {
		return $res
	}

}


#Lectura del idioma
proc load_lang { {langcode "en"} } {
   global lang lang_list langenc langlong

   set file_id [open "[file join lang lang$langcode]" r]

   set langenc ""

   foreach langdata $lang_list {
   	if { [string compare [lindex $langdata 0] $langcode] == 0 } {
	  set langenc [lindex $langdata 2]
	  set langlong [lindex $langdata 1]
	}
   }

   fconfigure $file_id -encoding $langenc

   gets $file_id tmp_data
   if {$tmp_data != "amsn_lang_version 2"} {	;# config version not supported!
      return 1
   }

   while {[gets $file_id tmp_data] != "-1"} {
      #If line is a comment, skip
      if {[string range $tmp_data 0 0] == "#"} {
          continue
      }
      set pos [string first " " $tmp_data]
      
      #Remove comments at end of line
      set posend [string first "#" $tmp_data]
      if { $posend == -1 } {
          set posend [expr {[string length $tmp_data]-1}]
      } else {
         incr posend -1
	  while {[string range $tmp_data $posend $posend] == " "} {
	  	incr posend -1
	  }
      }
      set l_msg [string range $tmp_data 0 [expr {$pos -1}]]
      set l_trans [string range $tmp_data [expr {$pos +1}] $posend]
      set lang($l_msg) $l_trans
   }
   close $file_id
   return 0
}
