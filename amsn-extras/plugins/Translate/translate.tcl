# Translate 0.3 for aMSN 0.97 - by number-g (g-at-imagination-dot-eu-dot-org)

package require http

namespace eval ::translate {

	array set ::translate::languages {
		Albanian sq Arabic ar Bulgarian bg Chinese_simp zh-cn
		Chinese_trad zh-tw Catalan ca Croatian hr Czech cs
		Danish da Dutch nl English en Estonian et Filipino tl
		Finnish fi French fr Galician gl German de Greek el
		Hebrew iw Hindi hi Hungarian hu Indonesian id Italian it
		Japanese ja Korean ko Latvian lv Lithuanian lt Maltese mt
		Norwegian no Polish pl Portuguese pt Romanian ro Russian ru
		Spanish es Serbian sr Slovak sk Slovenian sl Swedish sv
		Thai th Turkish tr Ukrainian uk Vietnamese vi
	}

	proc init {dir} {
		::plugins::RegisterPlugin "Translate"
		::plugins::RegisterEvent "Translate" new_conversation populate_chatwindow
		::plugins::RegisterEvent "Translate" chat_msg_send outgoing
		::plugins::RegisterEvent "Translate" chat_msg_receive incoming

		# Set config variables per-chatid.
		set c [::abook::getAllContacts]

		foreach contact $c {                            
			set ::translate::config($contact) 0
			set ::translate::config($contact.from) Source
			set ::translate::config($contact.to) Destination
			set ::translate::config($contact.hide) 0
			set ::translate::config($contact.viceversa) 0
		}
	}

	# Shameless self-promotion
	set ::translate::configlist [list \
					 [list label "Translate 0.3 for aMSN 0.97"] \
					 [list label "by number-g (g-at-imagination-dot-eu-dot-org)"] \
					 [list label ""] \
					 [list label "Hint: starting your sentences with a \".\" will"] \
					 [list label "bypass the translator."] \
					 [list label ""] \
					 [list label "If you find this plugin useful, please consider"] \
					 [list label "making a donation by clicking the link below:"] \
					 [list label ""] \
					 [list frame ::translate::donatebutton ""] \
					 [list label ""]
				    ]

	proc donatebutton {win} {

		set frame $win.frame
		frame $frame

		label $frame.donate -text "Donate!" -cursor hand2 -font splainf \
		    -background [::skin::getKey extrastdwindowcolor] -foreground [::skin::getKey extralinkcolor]
		
		bind $frame.donate <Enter> "$frame.donate configure -font sunderf -cursor hand2 \
	-background [::skin::getKey extralinkbgcoloractive] -foreground [::skin::getKey extralinkcoloractive]"
		bind $frame.donate <Leave> "$frame.donate configure -font splainf -cursor left_ptr \
	-background [::skin::getKey extrastdwindowcolor] -foreground [::skin::getKey extralinkcolor]"
		bind $frame.donate <ButtonRelease> "launch_browser https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=SKCWYSL36RGZW&lc=GB&item_name=Translate_plugin_v0.3-for_aMSN_0.97&currency_code=GBP&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted"
		
		pack $frame.donate
		pack $frame
	}

	proc populate_chatwindow {event evpar} {

		upvar 2 $evpar args

		set chatid $args(chatid)
		set window [::ChatWindow::For $chatid] 
		
		set placement $window.top.padding
		pack [create_ui $window $placement $chatid] -fill x
	}

	proc create_ui {window placement chatid} {
		
		set ui $placement.translate
		frame $ui

		set onoff $ui.cb
		set viceversa $ui.viceversa
		set showhide $ui.showhide

		set from $ui.from
		set to  $ui.to
		set fl	$ui.fl
		set tl	$ui.tl
		label $fl -text "Translate from: "
		label $tl -text "To:"
		
		checkbutton $onoff -indicatoron 1 -onvalue 1 -offvalue 0 	\
		    -selectcolor green -text "On/Off" -variable ::translate::config($chatid)

		checkbutton $viceversa -indicatoron 1 -onvalue 1 -offvalue 0        \
		    -selectcolor green -text "Translate incoming messages" -variable ::translate::config($chatid.viceversa)

		checkbutton $showhide -indicatoron 1 -onvalue 1 -offvalue 0        \
		    -selectcolor green -text "Hide original" -variable ::translate::config($chatid.hide)


		combobox::combobox $from -editable 0 -width 11 -textvariable ::translate::config($chatid.from)
		combobox::combobox $to -editable 0 -width 11 -textvariable ::translate::config($chatid.to)

		# Populate comboboxes.
		foreach language [lsort [array names ::translate::languages]] {
			$from list insert end $language
			$to list insert end $language	
		}

		pack $fl -side left;				pack $from -side left
		pack $tl -side left -padx 5;	pack $to -side left
		
		pack $onoff -side right -padx 2
		pack $showhide -side right -padx 2
		pack $viceversa -side right -padx 2

		return $ui	
	}

	proc outgoing {event evpar} {

		upvar 2 chatid chatid
		upvar 2 msg msg

		set from  $::translate::languages($::translate::config($chatid.from))
		set to    $::translate::languages($::translate::config($chatid.to))
		set state $::translate::config($chatid)

		if {$state==1} {
			set msg [translate $chatid $msg $from $to]
		} else {
			return 1
		}
		
	}

	proc incoming {event evpar} {
		upvar 2 user user
		upvar 2 chatid chatid
		upvar 2 message message

		if {$user!=[::config::getKey login]}  {
			
			if {$::translate::config($chatid.viceversa)==1} {
				
				set from  $::translate::languages($::translate::config($chatid.from))
				set to    $::translate::languages($::translate::config($chatid.to))
				set state    $::translate::config($chatid)

				if {$state==1} {
					set message [translate $chatid $message $to $from]
				} else {
					return 1
				} 
			} else {
				return 1
			}
		}
	}
	

	proc translate {chatid msg from to} {

		set case [testcase $msg]

		# A "." at the beginning of a line bypasses translation
		if {[string range $msg 0 0]!="."} {

			set original ""
			set query [::http::formatQuery v 1.0 q [convert $msg] langpair $from|$to] ;# See convert proc for explaination.

			# Include original text, but we don't need to see the emoticons twice.
			if {$translate::config($chatid.hide)==0} {
				set original "« $msg »\n- "
				set query [::http::formatQuery v 1.0 q [convert [stripemoticons $msg]] langpair $from|$to]
			}

			set tran [::http::geturl http://ajax.googleapis.com/ajax/services/language/translate?$query -query]
			set tran [::http::data $tran]

			set tran [split $tran \"]									;# Maybe there is a more elegant way to do this(?) 
			set tran [string trim [replace [lindex $tran 5]]]	;# See replace proc for explaination


			# Some stuff here to make things feel more natural and avoid needless repetition:
			# 1: Don't bother with empty strings or dupes.
			# 2: Google will add a space to (for example) "hi...", returning "hi ..." adding needless repetition to the output.
			# 3: Can't remember exactly why these are here, but I can remember that it solved something that irritated me.

			if {$tran!=$msg && $tran!="" \
				&& [regsub -all { } $tran {}]!=[stripemoticons $msg] \
				&& [stripemoticons $msg]!=$tran \
				&& [string tolower $tran]!=$msg} {
				
				set msg $original$tran
			}
			# If I choose to type in lower case, I want the translated text to reflect this:
			if {$case==0} {return [string tolower $msg]} else {return $msg}
		} else { 
			return 1
		}
	}


	# Google returns these as HTML escaped unicode characters. We want them to be legible:

	proc replace {text} {
		array set chars {

			u0026ndash;			– 
			u0026mdash;			— 	
			u0026iexcl;			¡ 	
			u0026iquest;		¿ 	
			u0026quot;			\"
			u0026ldquo;			“
			u0026rdquo;			” 	
			u0026lsquo;			‘
			u0026rsquo;			’
			u0026aquo;			«
			u0026raquo;			»
			u0026amp;			\\&
			u0026cent;			¢
			u0026copy;			©
			u0026divide;		÷ 
			u0026gt;				> 
			u0026lt;				< 
			u0026micro;			µ 
			u0026middot;		·
			u0026para;			¶
			u0026plusmn;		±  
			u0026euro;			€  
			u0026pound;			£ 
			u0026reg;			® 
			u0026sect;			§  
			u0026trade;			™
			u0026yen;			¥ 
			u0026#39;			'
			u003d					=
		}
		
		foreach {char replace} [array get chars] {
			regsub -all \\\\$char $text $replace text
		}
		return $text
	}

	proc stripemoticons {text} {

		set emoticons [list {:-\)} {:\)} {:-D} {:d} {:-O} {:o} {:\-P} {:p} {;-\)} {;\)} {:-\(} {:\(} {:-S} {:s} {:-\|} {:\|}  \
				   {:'\(} {:-\$} {:\$} {\(H\)} {:-@} {:@} {\(A\)} {\(6\)} {:-#} {8o\|} {8-\|} {\^o\)} {:-\*} {\+o\(} 		\
				   {:\^\)} {\*-\)} {<:o\)} {8-\)} {\|-\)} {\(C\)} {\(Y\)} {\(N\)} {\(B\)} {\(D\)} {\(X\)} {\(Z\)}     		\
				   {\(\{\)} {\(\}\)} {:-\[} {:\[} {\(\^\)} {\(L\)} {\(U\)} {\(K\)} {\(G\)} {\(F\)} {\(W\)} {\(P\)}   		\
				   {\(~\)} {\(@\)} {\(&\)} {\(T\)} {\(I\)} {\(8\)} {\(S\)} {\(\*\)} {\(E\)} {\(O\)} {\(M\)} {\(sn\)}  		\
				   {\(bah\)} {\(pl\)} {\(\|\|\)} {\(pi\)} {\(so\)} {\(au\)} {\(ap\)} {\(um\)} {\(ip\)} {\(co\)}      		\
				   {\(mp\)} {\(st\)} {\(li\)} {\(mo\)} ]

		foreach code $emoticons {
			regsub -all -nocase $code $text {} text
		}
		return [string trim $text]
	}

	# Find out if we are typing in lowercase:
	proc testcase {string} {

		set x [string length $string]
		for {set i 0} {$i<$x} {incr i} {
			if {[string is alpha [string range $string $i $i]]} {append output [string range $string $i $i]}
		}
		if {[string is lower $output]} {return 0} else {return 1}
	}


	# Sending the text to Google as-is caused problems with accents for Windows users;
	# ie - "ça va?" was being sent as "a va?", leading to (sometimes hilarious) mistranslations.
	#
	# This proc converts each character to HTML escaped unicode before sending to Google.
	proc convert {string} {

		set x [string length $string]
		for {set i 0} {$i<$x} {incr i} {
			append output "&#[scan [string range $string $i $i] %c];"
		}
		return $output
	}
}
