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
	{":-[" vampire} {":[" vampire} {"(\})" girlhug} {"(\{)" boyhug}
	{"(A)" angel} {"(6)" devil} {"(^)" cake} {"(O)" clk} {":-@" angry}
	{":@" angry} {"(&)" dog} {"(W)" rosew} {":`(" smilec} {":'(" smilec}
	{":$" smilemb} {":-$" smilemb} {"(#)" sun} {"(R)" rainbow}
	{"(%)" handcuffs} {(~) film} {(?) asl}}

set emotion_files {smile smiled smileo smilep wink sad crooked disgust thumbu
	thumbd love unlove lips gift rose emgirl emboy photo beer coctail
	emphone emcat emcup embulb emhottie emsleep emstar emnote email
	messenger vampire girlhug boyhug angel devil cake clk angry dog rosew
	smilec smilemb smilemb sun rainbow handcuffs film asl}


foreach img_name $emotion_files {
   image create photo $img_name -file ${images_folder}/${img_name}.gif
}


proc smile_subst {tw {start "0.0"}} {
  global emotions

#      tw mark set new_text_start end
#      tw insert $section.last "$user_name$state_desc\n" $user_login

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

