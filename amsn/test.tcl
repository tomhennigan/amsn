for {set i 1} {$i <= 256} {incr i} {
   set c [format %c $i]
   if {![string match \[a-zA-Z0-9\] $c]} {
      set url_map($c) %[format %.2X $i]
      if { $c == ")" } {
      	set url_map() %[format %.2X $i]
      }

   }
}


proc urldecode {str} {
    # estracted from ncgi - solves users from needing to install extra packages!
    regsub -all {\+} $str { } str
    regsub -all {[][\\\$]} $str {\\&} str
    regsub -all {%([0-9a-fA-F][0-9a-fA-F])} $str {[format %c 0x\1]} str
#Bug with $'s in nick
#    regsub -all {[\$]} $str {\\\$} str
    return [subst $str]
}


proc urlencode {str} {
   global url_map

   regsub -all \[^a-zA-Z0-9\)\] $str {$url_map(&)} str
   set str [subst -nobackslashes -nocommands $str]
   regsub -all {\)} $str {$url_map()} str

#   return [subst -nobackslashes -nocommands $str]
   return [subst -nobackslashes -nocommands $str]
}
