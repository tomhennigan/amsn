#
# $Id$
#
set emotions {{":-)" smile} {":)" smile} {":-D" smiled} {":D" smiled}
	{":->" smiled} {":>" smiled} {":-O" smileo} {":O" smileo} {":-P" smilep}
	{":P" smilep} {";-)" wink} {";)" wink} {":-(" sad} {":(" sad}
	{":-<" sad} {":<" sad} {":-S" crooked} {":S" crooked} {":-|" disgust}
	{":|" disgust} {"(Y)" thumbu} {"(N)" thumbd} {"(L)" love} {"(U)" unlove}
	{"(K)" lips} {"(G)" gift} {"(F)" rose} {"(X)" emgirl} {"(Z)" emboy}
	{"(P)" photo} {"(B)" beer} {"(D)" coctail} {"(T)" emphone} {"(@)" emcat}
	{"(C)" emcup} {"(I)" embulb} {"(H)" emhottie} {"(S)" emsleep}
	{"(*)" emstar} {"(8)" emnote} {"(E)" email} {"(M)" messenger}
	{":-\[" vampire} {":\[" vampire} {"(\})" girlhug} {"(\{)" boyhug}
	{"(A)" angel} {"(6)" devil} {"(^)" cake} {"(O)" clk} {":-@" angry}
	{":@" angry} {"(&)" dog} {"(W)" rosew} {":'(" smilec} {":`(" smilec} 
	{":$" smilemb} {":-$" smilemb} {"(#)" sun} {"(R)" rainbow}
	{"(%)" handcuffs} {"(~)" film} {"(?)" asl}}

set emotion_files {smile smiled smileo smilep wink sad crooked disgust thumbu
	thumbd love unlove lips gift rose emgirl emboy photo beer coctail
	emphone emcat emcup embulb emhottie emsleep emstar emnote email
	messenger vampire girlhug boyhug angel devil cake clk angry dog rosew
	smilec smilemb smilemb sun rainbow handcuffs film asl}


foreach img_name $emotion_files {
   image create photo $img_name -file [file join ${images_folder} ${img_name}.gif]
}


proc smile_subst {tw {start "0.0"}} {
  global emotions

   foreach emotion $emotions {
	   
      set symbol [lindex $emotion 0]
      set file [lindex $emotion 1]
      set chars [string length $symbol]
      
      while {[set pos [$tw search -exact -nocase \
	                              $symbol $start end]] != ""} {
         set posyx [split $pos "."]
         set endpos "[lindex $posyx 0].[expr [lindex $posyx 1] + $chars]"
         $tw delete $pos $endpos

         $tw image create $pos -image $file -pady 1 -padx 1

      }
   }

}


proc smile_menu { {x 0} {y 0} {text text}} {
   global emotions

   set w .smile_selector
   if {[catch [toplevel $w] res]} {
      destroy $w
      toplevel $w     
   }
   set x [expr {$x-10}]
   set y [expr {$y-10}]
   wm geometry $w 215x146+$x+$y
   wm title $w "[trans msn]"
   wm overrideredirect $w 1
   wm transient $w
   wm state $w normal
   

   text $w.text -background white -borderwidth 2 -relief ridge \
      -selectbackground white -selectborderwidth 0 -exportselection 0
                     
   pack $w.text

   $w.text configure -state normal


   foreach emotion $emotions {
      set symbol [lindex $emotion 0]
      set file [lindex $emotion 1]
      set chars [string length $symbol]

      catch {
         label $w.text.$file -image $file
         $w.text.$file configure -cursor hand2 -borderwidth 1 -relief flat

         if { [string match {(%)} $symbol] != 0 } {
           bind $w.text.$file <Button1-ButtonRelease> "catch {$text insert insert \{(%%)\}; destroy $w} res"
	 } else {
           bind $w.text.$file <Button1-ButtonRelease> "catch {[list $text insert insert $symbol]\;[list destroy $w]} res"     
	 }



         bind $w.text.$file <Enter> "$w.text.$file configure -relief raised"
         bind $w.text.$file <Leave> "$w.text.$file configure -relief flat"
         $w.text window create end -window $w.text.$file -padx 1 -pady 1
      }


   }

   $w.text configure -state disabled
      
   bind $w <Leave> "destroy $w"
   bind $w <Enter> "bind $w <Leave> \"bind $w <Leave> \\\"destroy $w\\\"\""
   
}
