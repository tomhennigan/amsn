namespace eval ::jake {

global mydir

global birthday
global starttime

proc jakeStart { dir } {

	global mydir
	set mydir $dir

	global birthday
	global starttime
	global ntotalsearches

	set birthday [clock scan 05/02/2009/12/00 -format %d/%m/%Y/%H/%M]
	set starttime [clock seconds] 

	::plugins::RegisterPlugin jake
	::plugins::RegisterEvent jake chat_msg_received answer
	::plugins::RegisterEvent jake ChangeMyState online

	set langdir [file join $mydir "lang"]       
	set lang [::config::getGlobalKey language]    
	load_lang en $langdir                       
	load_lang $lang $langdir                    

	array set ::jake::config {
		botname {jake}                                             
		helptxt {I'm jake, an AI bot.}  
		nresults {5}          
	}

	set ::jake::configlist [list \
		[list str "[trans name]" botname] \
		[list str "[trans helptext]" helptxt] \
		[list str "[trans nresults]" nresults] \
	]
}

proc alterString {phrase z} {
	if {$z < [string length $phrase]} {
		if {[string is alpha [string range $phrase $z $z]]} {
			if {[string is lower [string range $phrase $z $z]]} {
				set phrase [string toupper $phrase $z $z]
				return $phrase
			} elseif {[string is upper [string range $phrase $z $z]]} {
				set phrase [string tolower $phrase $z $z]
				return $phrase
			} else {
				return
			}
		} else {
			return
		}
	} else {
		return -1
	}
}

proc howlongsince {secs {fmt "%H:%M:%S"}} {
      
	#I'm too lazy to do leap years =P
	#I'm also too lazy to do the rigth number of days in months (28/29, 30, 31 days)

	set days [expr {$secs/86400}] ; set Days [string range "0$days" end-1 end]
	set hours [expr {($secs%86400)/3600}] ; set Hours [string range "0$hours" end-1 end]
	set minutes [expr {(($secs%86400)%3600)/60}] ; set Minutes [string range "0$minutes" end-1 end]
	set seconds [expr {(($secs%86400)%3600)%60}] ; set Seconds [string range "0$seconds" end-2 end]

	if { [expr $days > 365]} {
		set months [expr {$days/30}] ; set Months [string range "0$months" end-1 end]
		set days [expr $days-($months*30)] ; set Days [string range "0$days" end-1 end]
		if { [expr $months > 12]} {
			set years [expr {$months/12}] ; set Years [string range "0$years" end-1 end]
			set months [expr $months-($years*12)] ; set Months [string range "0$months" end-1 end]
		} else {
			set years 0 ; set Years [string range "0$years" end-1 end]
		}
	} else {
		set years 0 ; set Years [string range "0$years" end-1 end]
		set months [expr {$days/30}] ; set Months [string range "0$months" end-1 end]
		set days [expr {$days-($months*30)}] ; set Days [string range "0$days" end-1 end]
	}

	set p "%% % %s $seconds %S $Seconds %m $minutes %M $Minutes %h $hours %H $Hours %d $days %D $Days %n $months %N $Months %y $years %Y $Years"
	set str [string map $p $fmt]
	return $str
}

proc stringDistance {a b} {
	set n [string length $a]
	set m [string length $b]
	for {set i 0} {$i<=$n} {incr i} {set c($i,0) $i}
	for {set j 0} {$j<=$m} {incr j} {set c(0,$j) $j}
	for {set i 1} {$i<=$n} {incr i} {
		for {set j 1} {$j<=$m} {incr j} {
			set x [expr {$c([- $i 1],$j)+1}]
			set y [expr {$c($i,[- $j 1])+1}]
			set z $c([- $i 1],[- $j 1])
			if {[string index $a [- $i 1]]!=[string index $b [- $j 1]]} {
				incr z
			}
			set c($i,$j) [min $x $y $z]
		}
	}
	set c($n,$m)
}

if {[catch {
	package require Tcl 8.5
	namespace path {tcl::mathfunc tcl::mathop}
	}]} then {
	proc min args {lindex [lsort -real $args] 0}
	proc max args {lindex [lsort -real $args] end}
	proc - {p q} {expr {$p-$q}}
}

proc stringSimilarity {a b} {
	set totalLength [string length $a$b]
	max [expr {double($totalLength-2*[stringDistance $a $b])/$totalLength}] 0.0
}

proc rand {m {n 0}} {
	expr {int(($m-$n)*rand()+$n)}
}

proc getPage {url} {
	package require http
	::http::config -useragent "Monkey cmdline tool (OpenBSD; en)"
	if {[catch {set token [::http::geturl $url]} msg]} {
	  return "Error: $msg"
	} else {
	  set data [::http::data $token]
	}
	::http::cleanup $token
	return $data
}

proc html2text {str} {
	regsub -all {<em>} $str "" str
	regsub -all {</em>} $str "" str
	regsub -all {<b>} $str "" str
	regsub -all {</b>} $str "" str
	regsub -all {&quot;} $str "\"" str
	regsub -all {&gt;} $str ">" str
	regsub -all {&lt;} $str "<" str
	regsub -all {&ntilde;} $str "ñ" str
	regsub -all {&Ntilde;} $str "Ñ" str
	regsub -all {&amp;} $str "\\&" str
	regsub -all {&acute;} $str "'" str
	regsub -all {&aacute;} $str "á" str
	regsub -all {&Aacute;} $str "Á" str
	regsub -all {&agrave;} $str "à" str
	regsub -all {&Agrave;} $str "À" str
	regsub -all {&acirc;} $str "â" str
	regsub -all {&Acirc;} $str "Â" str
	regsub -all {&auml;} $str "ä" str
	regsub -all {&Auml;} $str "Ä" str
	regsub -all {&Atilde;} $str "Ã" str
	regsub -all {&atilde;} $str "ã" str
	regsub -all {&ccedil;} $str "ç" str
	regsub -all {&euro;} $str "€" str
	regsub -all {&egrave;} $str "è" str
	regsub -all {&Egrave;} $str "È" str
	regsub -all {&ecirc;} $str "ê" str
	regsub -all {&Ecirc;} $str "Ê" str
	regsub -all {&euml;} $str "ë" str
	regsub -all {&Euml;} $str "Ë" str
	regsub -all {&Otilde;} $str "Õ" str
	regsub -all {&Ccedil;} $str "Ç" str
	regsub -all {&yen;} $str "¥" str
	regsub -all {&circ;} $str "ˆ" str
	regsub -all {&igrave;} $str "ì" str
	regsub -all {&Igrave;} $str "Ì" str
	regsub -all {&icirc;} $str "î" str
	regsub -all {&Icirc;} $str "Î" str
	regsub -all {&Iuml;} $str "Ï" str
	regsub -all {&copy;} $str "©" str
	regsub -all {&pound;} $str "£" str
	regsub -all {&ograve;} $str "ò" str
	regsub -all {&Ograve;} $str "Ò" str
	regsub -all {&Ocirc;} $str "Ô" str
	regsub -all {&ocirc;} $str "ô" str
	regsub -all {&ouml;} $str "ö" str
	regsub -all {&Ouml;} $str "Ö" str
	regsub -all {&aring;} $str "å" str
	regsub -all {&Aring;} $str "Å" str
	regsub -all {&reg;} $str "®" str
	regsub -all {&cent;} $str "¢" str
	regsub -all {&ugrave;} $str "ù" str
	regsub -all {&Ugrave;} $str "Ù" str
	regsub -all {&ucirc;} $str "û" str
	regsub -all {&Ucirc;} $str "Û" str
	regsub -all {&uuml;} $str "ü" str
	regsub -all {&Uuml;} $str "Ü" str
	regsub -all {&oslash;} $str "ø" str
	regsub -all {&Oslash;} $str "Ø" str
	regsub -all {&trade;} $str "™" str
	regsub -all {&deg;} $str "°" str
	regsub -all {&yacute;} $str "ý" str
	regsub -all {&yuml;} $str "ÿ" str
	regsub -all {&Yuml;} $str "Ÿ" str
	regsub -all {&scaron;} $str "š" str
	regsub -all {&Scaron;} $str "Š" str
	regsub -all {&eacute;} $str "é" str
	regsub -all {&Eacute;} $str "É" str
	regsub -all {&iacute;} $str "í" str
	regsub -all {&Iacute;} $str "Í" str
	regsub -all {&oacute;} $str "ó" str
	regsub -all {&Oacute;} $str "Ó" str
	regsub -all {&uacute;} $str "ú" str
	regsub -all {&Uacute;} $str "Ú" str
	regsub -all {&uuml;} $str "ü" str
	regsub -all {&Uuml;} $str "Ü" str
	regsub -all {&curren;} $str "¤" str

	return $str
}

proc searchInGoogle {str} {
	set botname $::jake::config(botname)
	set nresults $::jake::config(nresults)
	set language [::config::getGlobalKey language]
	set link "http://www.google.com/search?hl="
	append link $language&num=$nresults&q=$str
	set salida [ getPage $link ]
	if { [string first "Error: " $salida] != 0 } {
		set matches [regexp -all -inline {(<li class=g>.*<a [^>]*>.*</a>)+?} $salida]
		set count 0
		set bool 0
		foreach m $matches {
			regexp {href="([^"]*)[^>]*>(.*)</a>} $m => url title
			regsub -all {/url\?q=} $url "" url
			set url [html2text $url]
			set title [html2text $title]
			if { $bool == 0 && $count < $nresults } {
				incr count
				append final $count.\ $title " - " $url \n\n
				set bool 1
			} else {
				set bool 0
			}
		}
		set output "$botname: \n\n$final"
	} else {
		set output "$botname: Error: $salida"
	}
	return $output
}

proc searchInMegaupload {str} {
	set botname $::jake::config(botname)
	set nresults $::jake::config(nresults)
	set link "http://4megaupload.com/index.php?q="
	append link $str
	set salida [ getPage $link ]
	if { [string first "Error: " $salida] != 0 } {
		set matches [regexp -all -inline {(<td bgcolor="#ECF7FF" rowspan="4".*</font>)+?} $salida]
		set count 0
		set bool 0
		foreach m $matches {
			regexp {href="([^"]*).*title='([^']*).*>(.*)</font>} $m => url title size
			regsub -all {/url\?q=} $url "" url
			regsub -all { +} $url "" url
			set title [html2text $title]
			if { $bool == 0 && $count < $nresults } {
				incr count
				append final $count.\ $title " - [string trim $size] - http://4megaupload.com/" $url \n\n
				set bool 1
			} else {
				set bool 0
			}
		}
		set output "$botname: \n\n$final"
	} else {
		set output "$botname: Error: $salida"
	}
	return $output
}

proc searchInYoutube {str} {
	set botname $::jake::config(botname)
	set nresults $::jake::config(nresults)
	set link "http://www.youtube.com/results?search_type=&search_query="
	append link $str
	set salida [ getPage $link ]
	if { [string first "Error: " $salida] != 0 } {
		set matches [regexp -all -inline {(<div class="v120WrapperInner">.* src)+?} $salida]
		set count 0
		set bool 0
		foreach m $matches {
			regexp {href="([^"]*).*title="([^"]*)} $m => url title
			regsub -all {/url\?q=} $url "" url
			set title [html2text $title]
			if { $bool == 0 && $count < $nresults } {
				incr count
				append final $count.\ $title " - www.youtube.com" $url \n\n
				set bool 1
			} else {
				set bool 0
			}
		}
		set output "$botname: \n\n$final"
	} else {
		set output "$botname: Error: $salida"
	}
	return $output
}

proc defineInGoogle {str} {
	set botname $::jake::config(botname)
	set nresults $::jake::config(nresults)
	set language [::config::getGlobalKey language]
	set link "http://www.google.com/search?hl="
	append link $language&q=define:$str
	set salida [ getPage $link ]
	if { [string first "Error: " $salida] != 0 } {
		set matches [regexp -all -inline {(<li>.*<br><a href=.*><font)+?} $salida]
		set count 0
		set bool 0
		foreach m $matches {
			regexp {<li>([^<]*)(.*)><font} $m => title url
			regsub -all {<br>.*q=} $url "" url
			regsub -all {\"} $url "" url
			set title [html2text $title]
			if { $bool == 0 && $count < $nresults } {
				incr count
				append final $count.\ $title " - " $url \n\n
				set bool 1
			} else {
				set bool 0
			}
		}
		set output "$botname: \n\n$final"
	} else {
		set output "$botname: Error: $salida"
	}
	return $output
}

proc searchInGoear {str} {
	set botname $::jake::config(botname)
	set nresults $::jake::config(nresults)
	set link "http://www.goear.com/search.php?q="
	append link $str
	set salida [ getPage $link ]
	if { [string first "Error: " $salida] != 0 } {
		set matches [regexp -all -inline {(<strong>.*class="escuchar">)+?} $salida]
		set count 0
		set bool 0
		foreach m $matches {
			regexp {<strong><a title="([^"]*).*href="([^"]*)} $m => title url
			regsub -all {<br>.*q=} $url "" url
			regsub -all {\"} $url "" url
			set title [html2text $title]
			if { $bool == 0 && $count < $nresults } {
				incr count
				set goearLink "http://www.goear.com/"
				append goearLink $url
				regexp {listen/(.*?)/} $goearLink -> id
				set output [ getPage "http://www.goear.com/files/xmlfiles/[string index $id 0]/secm$id.xml" ]
				regexp {path=\"(.*?)\"} $output -> downloadlink
				append final $count.\ $title " - " $downloadlink "\n\n"
				set bool 1
			} else {
				set bool 0
			}
		}
		set output "$botname: \n\n$final"
	} else {
		set output "$botname: Error: $salida"
	}
	return $output
}

proc translateWithGoogle {lng txt} {
	set botname $::jake::config(botname)
	set languages([trans lngalbanian]) sq
	set languages([trans lngarabic]) ar          
	set languages([trans lngarmenian]) hy          
	set languages([trans lngbasque]) eu          
	set languages([trans lngbelarusian]) be          
	set languages([trans lngbengali]) bn                 
	set languages([trans lngbosnian]) bs          
	set languages([trans lngbreton]) br          
	set languages([trans lngbulgarian]) bg                 
	set languages([trans lngcatalan]) ca          
	set languages([trans lngchinese-simplified]) zh-CN       
	set languages([trans lngchinese-traditional]) zh-TW       
	set languages([trans lngcroatian]) hr          
	set languages([trans lngczech]) cs          
	set languages([trans lngdanish]) da          
	set languages([trans lngdutch]) nl          
	set languages([trans lngenglish]) en          
	set languages([trans lngesperanto]) eo                
	set languages([trans lngfilipino]) tl          
	set languages([trans lngfinnish]) fi          
	set languages([trans lngfrench]) fr                
	set languages([trans lnggalician]) gl                    
	set languages([trans lnggerman]) de          
	set languages([trans lnggreek]) el                
	set languages([trans lnghebrew]) iw                
	set languages([trans lnghungarian]) hu                               
	set languages([trans lngirish]) ga          
	set languages([trans lngitalian]) it          
	set languages([trans lngjapanese]) ja          
	set languages([trans lngkorean]) ko                   
	set languages([trans lnglatin]) la                
	set languages([trans lnglithuanian]) lt          
	set languages([trans lngmacedonian]) mk                          
	set languages([trans lngmongolian]) mn                   
	set languages([trans lngnorwegian]) no          
	set languages([trans lngpersian]) fa          
	set languages([trans lngpolish]) pl          
	set languages([trans lngportuguese-brazil]) pt-BR       
	set languages([trans lngportuguese-portugal]) pt-PT                 
	set languages([trans lngromanian]) ro          
	set languages([trans lngrussian]) ru          
	set languages([trans lngscots]) gd          
	set languages([trans lngserbian]) sr          
	set languages([trans lngserbo-croatian]) sh            
	set languages([trans lngslovak]) sk          
	set languages([trans lngslovenian]) sl          
	set languages([trans lngspanish]) es          
	set languages([trans lngswedish]) sv               
	set languages([trans lngturkish]) tr              
	set languages([trans lngukrainian]) uk          
	set languages([trans lngvietnamese]) vi          
	set languages([trans lngwelsh]) cy          
	if { [info exists languages($lng)] } {
		
		set query [http::formatQuery q $txt v 1.0]
		set token [::http::geturl http://www.google.com/uds/GlangDetect?$query -query]
		set data [::http::data $token]
		regexp {\"language\":\"(.*?)\",\"} $data -> from

		set query [::http::formatQuery v 1.0 q $txt langpair $from|$languages($lng)]
		set token [::http::geturl http://ajax.googleapis.com/ajax/services/language/translate?$query -query]
		set data [::http::data $token]
		regexp {\"translatedText\":\"(.*?)\"\}} $data -> str

		set output "$botname: \n\n$str"
	} else {
		set output "$botname: \n\n[trans errlng] $lng."
	}
	return $output
}

proc isuseroff {chatid} {
	set i 0
	set in [open [file join $::HOME "jake" "off.conf"] r]
	while { [gets $in line] >= 0 } {
		if { [string match $chatid $line] == 1 } {
			set i 1
		}
	}
	close $in
	if { $i == 0 } {
		return 0
	} else {
		return 1
	}
}

proc answer {event epvar} {
	
	global mydir
	global birthday
	global starttime

	upvar 2 $epvar args
	upvar 2 $args(msg) msg                           
	upvar 2 $args(chatid) chatid                      
	upvar 2 $args(user) user                         
	set me [::abook::getPersonal login]               
	set window [::ChatWindow::For $chatid]            
	set botname $::jake::config(botname)
	set nresults $::jake::config(nresults)
	set language [::config::getGlobalKey language]

	if { $msg == "![trans cmdon]" } {   
		if { [isuseroff $chatid] == 1 } {
			set in [open [file join $::HOME "jake" "off.conf"] r]
			set out [open [file join $::HOME "jake" "off.conf.tmp"] w]
			while { [gets $in line] >= 0 } {
				if { [string match $chatid $line] == 0 } {
					puts $out $line
				}
			}
			close $in
			close $out
			file delete -force [file join $::HOME "jake" "off.conf"]
			file rename -force [file join $::HOME "jake" "off.conf.tmp"] [file join $::HOME "jake" "off.conf"]
		}
		plugins_log jake "Plugin Jake activado!"
		::amsn::MessageSend $window 0 "$botname: [trans msgon]"
	} elseif { $msg == "![trans cmdoff]" } {
		set in [open [file join $::HOME "jake" "off.conf"] a+]
		if { ![isuseroff $chatid] } {
			puts $in $chatid
		}
		close $in
		plugins_log jake "Plugin Jake desactivado"
		::amsn::MessageSend $window 0 "$botname: [trans msgoff]"
	} elseif { $msg == "![trans cmdstate]" } {
		set format ""
		append format {%y }
		append format [trans txtyears]
		append format {, %n }
		append format [trans txtmonths]  
		append format {, %d }
		append format [trans txtdays]  
		append format {, %h }
		append format [trans txthours] 
		append format {, %m }
		append format [trans txtminutes] 
		append format {, %s }
		append format [trans txtseconds] 

		set now [clock seconds]
		#uptime
		set diffuptime [expr {$now-$starttime}]
		set howlonguptime [howlongsince $diffuptime $format]
		set uptime [trans txtuptime]
		append uptime " " $howlonguptime
		#lifetime
		set diffalive [expr {$now-$birthday}]
		set howlongalive [howlongsince $diffalive $format]
		set lifetime [trans txtlifetime]
		append lifetime " " $howlongalive
		#version info
		set version [trans txtversion]
		append version "0.8 BETA"
		#dictionary size info
		if { [array exists dictionary] == 0 } {
			source [file join $::HOME "jake" "dictionary.dic"]
		}
		set dictionarysize [trans txtdictionarysize]
		append dictionarysize [array size dictionary]
		append dictionarysize " [trans txtreg]"
		if { [isuseroff $chatid] } {
			set state "[trans msgoff]"
			::amsn::MessageSend $window 0 "$botname: \n\n$state\n$version\n$dictionarysize\n$uptime\n$lifetime"
		} else {
			set state "[trans msgon]"
			::amsn::MessageSend $window 0 "$botname: \n\n$state\n$version\n$dictionarysize\n$uptime\n$lifetime"
		}
	} elseif { $msg == "![trans cmdhelp]" } {
		::amsn::MessageSend $window 0 "$botname: $::jake::config(helptxt)\n\
		[trans txtcommands]\n\n\
		![trans cmdhelp] - [trans txthelp]\n\
		![trans cmdon] - [trans txtconveron]\n\
		![trans cmdoff] - [trans txtconveroff]\n\
		![trans cmdgoogle] [trans cmdargsgoogle] - [trans txtgoogle]\n\
		![trans cmddefine] [trans cmdargsdefine] - [trans txtdefine]\n\
		![trans cmdhour] - [trans txthour]\n\
		![trans cmddate] - [trans txtdate]\n\
		![trans cmdstate] - [trans txtstate]\n\
		![trans cmdlearn] [trans cmdargslearn] - [trans txtlearn] $botname\n\
		![trans cmdforget] [trans cmdargsforget] - [trans txtforget] $botname\n\
		![trans cmdyoutube] [trans cmdargsyoutube] - [trans txtyoutube]\n\
		![trans cmdexpr] [trans cmdargsexpr] - [trans txtexpr]\n\
		![trans cmdmegaupload] [trans cmdargsmegaupload] - [trans txtmegaupload]\n\
		![trans cmdmp3] [trans cmdargsmp3] - [trans txtmp3]\n\
		![trans cmdtranslate] [trans cmdargstranslate] - [trans txttranslate]"
	} elseif { $msg == "![trans cmdhour]" } {
		::amsn::MessageSend $window 0 "$botname: [trans rsphour] [clock format [clock seconds] -format {%H:%M:%S}]"
	} elseif { $msg == "![trans cmddate]" } {
		::amsn::MessageSend $window 0 "$botname: [trans rspdate] [clock format [clock seconds] -format {%d/%m/%Y}]"
	} elseif { [string first "![trans cmdgoogle] " $msg] == 0 } {
		set commandLength [expr [string length [trans cmdgoogle]] + 2]
		set strWithoutCommand [string range $msg $commandLength end]
		regsub -all { +}  $strWithoutCommand "+" str
		set output [searchInGoogle $str]
		::amsn::MessageSend $window 0 $output
	} elseif { [string first "![trans cmdmegaupload] " $msg] == 0 } {   
		set commandLength [expr [string length [trans cmdmegaupload]] + 2]
		set strWithoutCommand [string range $msg $commandLength end] 
		regsub -all { +}  $strWithoutCommand "+" str
		set output [searchInMegaupload $str]
		::amsn::MessageSend $window 0 $output
	} elseif { [string first "![trans cmdyoutube] " $msg] == 0 } {   
		set commandLength [expr [string length [trans cmdyoutube]] + 2]
		set strWithoutCommand [string range $msg $commandLength end]
		regsub -all { +} $strWithoutCommand "+" str
		set output [searchInYoutube $str]
		::amsn::MessageSend $window 0 $output
	} elseif { [string first "![trans cmddefine] " $msg] == 0 } {  
		set commandLength [expr [string length [trans cmddefine]] + 2]
		set strWithoutCommand [string range $msg $commandLength end]
		regsub -all { +} $strWithoutCommand "+" str
		set output [defineInGoogle $str]
		::amsn::MessageSend $window 0 $output
	} elseif { [string first "![trans cmdlearn] " $msg] == 0 } {   
		if { [array exists dictionary] == 0 } {
			source [file join $::HOME "jake" "dictionary.dic"]
		}
		set commandLength [expr [string length [trans cmdlearn]] + 2]
		set msg [string range $msg $commandLength end]      
		if { [regexp -- {^"[^"]*" "[^"]*"$} $msg] } {

			set originalMsg $msg
			regexp {\"(.*?)\" \"} $msg -> originalPhrase
			regsub -all {\"} $originalPhrase "\\\"" phrase

			set x 0 
			set z 0
			while {$x<1} {
				if {[info exists dictionary($phrase)] == 1} {
					set phrase [alterString $phrase $z]
					if {[string equal $phrase "-1"]} {
						::amsn::MessageSend $window 0 "$botname: [trans erradd]"
						return
					} else {
						incr z
					}
				} else {
				      set msg [string map "$originalPhrase $phrase" $originalMsg]
				      set msg [string range $msg 1 end]
				      regsub -all {\" \"} $msg ")\" \"" msg
				      set fileId [open [file join $::HOME  "jake" "dictionary.dic"] "a+"]
				      puts $fileId "set \"dictionary($msg"
				      close $fileId
				      source [file join $::HOME "jake" "dictionary.dic"]
				      ::amsn::MessageSend $window 0 "$botname: [trans txtregadd] [array size dictionary] [trans txtreg]"
				      incr x
				}
			}

		} else {
			::amsn::MessageSend $window 0 "$botname: [trans cmderror]\n\
				[trans txthelplearn] ![trans cmdlearn] [trans cmdargslearn]"
		}
	} elseif { [string first "![trans cmdforget] " $msg] == 0 } {  
		set commandLength [expr [string length [trans cmdforget]] + 2]
		set msg [string range $msg $commandLength end]      
		if { [regexp -- {^".*"$} $msg] } {
			if { [array exists dictionary] == 0 } {
				source [file join $::HOME "jake" "dictionary.dic"]
			}
			regsub -all {\"} $msg "" msg
			set in [open [file join $::HOME "jake" "dictionary.dic"] r]
			set out [open [file join $::HOME "jake" "dictionary.dic.tmp"] w]
			set i 0
			while { [gets $in line] >= 0 } {
				incr i
				if { [string match "set \"dictionary($msg)\"*" $line] == 0 } {
					puts $out $line
				}
			}
			close $in
			close $out
			file delete -force [file join $::HOME "jake" "dictionary.dic"]
			file rename -force [file join $::HOME "jake" "dictionary.dic.tmp"] [file join $::HOME "jake" "dictionary.dic"]
			array unset dictionary
			source [file join $::HOME "jake" "dictionary.dic"]
			set in [open [file join $::HOME "jake" "dictionary.dic"] r]
			set j 0
			while { [gets $in line] >= 0 } {
				incr j
			}
			::amsn::MessageSend $window 0 "$botname: [trans txtregdel] [expr $i - $j] [trans txtdic]"
		} else {
			::amsn::MessageSend $window 0 "$botname: [trans cmderror]\n\
				[trans txthelpforget] ![trans cmdforget] [trans cmdargsforget]"
		}
	} elseif { [string first "![trans cmdexpr] " $msg] == 0 } {
		set commandLength [expr [string length [trans cmdexpr]] + 2]
		set msg [string range $msg $commandLength end]
		if { [string first "[trans cmdhelp]" $msg] == 0 } {
			::amsn::MessageSend $window 0 "$botname: \n\n\
			[trans txtexprhelp]"
		} else {
			::amsn::MessageSend $window 0 "$botname: [trans txtsolution] [expr [string map {/ *1./} $msg]]"
		}
	} elseif { [string first "![trans cmdmp3] " $msg] == 0 } {
		set commandLength [expr [string length [trans cmdmp3]] + 2]
		set strWithoutCommand [string range $msg $commandLength end]
		regsub -all { +} $strWithoutCommand "+" str
		set output [searchInGoear $str]
		append output "[trans txthelpdownload]"
		::amsn::MessageSend $window 0 $output
	} elseif { [string first "![trans cmdtranslate] " $msg] == 0 } {
		set commandLength [expr [string length [trans cmdtranslate]] + 2]
		set str [string range $msg $commandLength end]
		set lngstartpos [string first " " $str]
		set lng [string range $str 0 [expr $lngstartpos - 1]]
		set txt [string range $str [expr $lngstartpos + 1] end]
		set output [translateWithGoogle $lng $txt]
		::amsn::MessageSend $window 0 $output
	} elseif { [string first "!envia " $msg] == 0 } {
		#test
	} elseif { $user != $me && [isuseroff $chatid] == 0} {
		if { [array exists dictionary] == 0 } {
			source [file join $::HOME "jake" "dictionary.dic"]
		}
		set i 1
		foreach index [array names dictionary] {
			if { [expr ([stringSimilarity $msg $index ]) > 0.6] } {
				set respuesta($i) $dictionary($index)
				incr i
			}
		}
		if { $i > 1 } {
			::amsn::MessageSend $window 0 "$botname: $respuesta([rand [array size respuesta] 1])"
		} else {
			if { [rand 5 1] == 1 } {
				::amsn::MessageSend $window 0 "$botname: [trans txtneedhelp]"
			}
		}
	}
}

proc online {event epvar} {
	upvar 2 $epvar args
	set status $args(idx)
	plugins_log "jake" "[trans txtchangestate] $status"
	if { $status == "AWY" } {
		plugins_log "jake" "Plugin Jake [trans txtlogactivated]"
		set ::jake::config(mystate) 1
	}
	if { $status == "NLN" } {
		plugins_log "jake" "Plugin Jake [trans txtlogdesactivated]"
		set ::jake::config(mystate) 0
	}
}

}