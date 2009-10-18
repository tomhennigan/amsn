namespace eval ::jake {

    global mydir
    global starttime
    global birthday

    proc jakeStart { dir } {
	global mydir
	set mydir $dir

	#Global vars used for the "info" command.
        global starttime
        global birthday

        #Little hack. The "clock" was totally rewriten in 8.5
        if {[info tclversion] == 8.4} {
            set birthday [regexp {(\d+)/(\d+)/(\d+)/(\d+)/(\d+)} 05/02/2009/12/00 -> d m Y H M ; clock scan $Y-$m-${d}T$H:$M]
        } else {
            set birthday [clock scan 05/02/2009/12/00 -format %d/%m/%Y/%H/%M]
        }
        set starttime [clock seconds] 

	#Register the plugin
	::plugins::RegisterPlugin jake
	::plugins::RegisterEvent jake chat_msg_received answer
        ::plugins::RegisterEvent jake chat_msg_received statesetLastWord
	::plugins::RegisterEvent jake ChangeMyState online
        ::plugins::RegisterEvent jake ChangeState statesetLastSeen

	#Set and load the language for the plugin
	set langdir [file join $mydir "lang"]       
	set lang [::config::getGlobalKey language]    
	load_lang en $langdir                       
	load_lang $lang $langdir                    

	#Create the aray used in the conf
	array set ::jake::config {
	    botname {jake}                                             
	    helptxt {I'm jake, an AI bot.}  
	    nresultsgoogle {3}                
            nresultsmegaupload {3}
            nresultssongs {3}
            nresultsyoutube {3}
	}

	set ::jake::configlist [list \
	    [list str "[trans guiname]" botname] \
	    [list str "[trans guihelptext]" helptxt] \
	    [list str "[trans guinresultsgoogle]" nresultsgoogle] \
            [list str "[trans guinresultsmegaupload]" nresultsmegaupload] \
            [list str "[trans guinresultssongs]" nresultssongs] \
            [list str "[trans guinresultsyoutube]" nresultsyoutube] \
	]

	#Source needed tcl files
        source [file join $mydir "http.tcl"]
	source [file join $mydir "help.tcl"]
	source [file join $mydir "music.tcl"]
        source [file join $mydir "stack.tcl"]
        source [file join $mydir "learn.tcl"]
        source [file join $mydir "state.tcl"]
        source [file join $mydir "forget.tcl"]
	source [file join $mydir "google.tcl"]
	source [file join $mydir "youtube.tcl"]
        source [file join $mydir "cmdline.tcl"]
        source [file join $mydir "htmlparse.tcl"]
        source [file join $mydir "translate.tcl"]
        source [file join $mydir "megaupload.tcl"]
        source [file join $mydir "fuzzystringmatch.tcl"]

        #make sure that needed files exist
        if {![file exists [file join $::HOME "jake" "dictionary.dic"]]} {
            set fl [open [file join $::HOME "jake" "dictionary.dic"] "a+"]
            close $fl
        }
        if {![file exists [file join $::HOME "jake" "off.conf"]]} {
            set fl [open [file join $::HOME "jake" "off.conf"] "a+"]
            close $fl
        }
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

    proc answer {event epvar} {
	    
	    global mydir
            global starttime
            global birthday

	    upvar 2 $epvar args
	    upvar 2 $args(msg) msg                           
	    upvar 2 $args(chatid) chatid                      
	    upvar 2 $args(user) user                         
	    set me [::abook::getPersonal login]               
	    set window [::ChatWindow::For $chatid]            
	    set botname $::jake::config(botname)
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
	    } elseif { [string first "![trans cmdstate]" $msg] == 0 } {
                    set commandLength [expr [string length [trans cmdstate]] + 2]
                    set strWithoutCommand [string range $msg $commandLength end]

                    #get what options did the user wrote.
                    set arguments [stateparseArgs $strWithoutCommand]

                    #if everything is ok, keep on, else say that something went wrong
                    if { [string compare [lindex $arguments 1] "ok"] == 0 } {
                        if { [string compare [lindex $arguments 0] ""] == 0 } {
                            set results [stategetState $starttime $birthday $chatid]
                        } else {
                            set results [stategetLastSeen [lindex $arguments 0]]
                            if { [string compare $results "notonlinebutneverseen"] == 0 } {
                                set results "[trans txtstatenotonlinebutneverseen]"
                            } elseif { [string compare $results "online"] == 0 } {
                                set results "[trans txtstateonline]"
                            }
                        }
                    } else {
                        set results "[trans txtcmderr]\n\
                                    [trans txtcommand]: ![trans cmdstate]\n\
                                    [trans txtprm]: [trans prmstate]\n\
                                    [trans txtdsc]: [trans dscstate]\n\
                                    [trans txtexl]: [trans exlstate]"
                    }

                    #show results
                    ::amsn::MessageSend $window 0 "$botname: $results"
	    } elseif { [string first "![trans cmdhelp]" $msg] == 0 } {
		    set commandLength [expr [string length [trans cmdhelp]] + 2]
		    set strWithoutCommand [string range $msg $commandLength end]

		    #get what options did the user wrote.
		    set arguments [helpparseArgs $strWithoutCommand]

		    #if everything is ok, keep on, else say that something went wrong
		    if { [string compare [lindex $arguments 1] "ok"] == 0 } {
			if { [string compare [lindex $arguments 0] ""] == 0 } {
			    set results [helpgeneralHelp]
			} else {
			    set results [helpcommandHelp [lindex $arguments 0]]
			}
		    } else {
			set results "[trans txtcmderr]\n\
				    [trans txtcommand]: ![trans cmdhelp]\n\
				    [trans txtprm]: [trans prmhelp]\n\
				    [trans txtdsc]: [trans dschelp]\n\
				    [trans txtexl]: [trans exlhelp]"
		    }

		    #show results
		    ::amsn::MessageSend $window 0 "$botname: $results"
	    } elseif { [string first "![trans cmdhour]" $msg] == 0 } {
		    set commandLength [expr [string length [trans cmdhour]] + 1]
		    if { $commandLength == [string length $msg] } {
			set results "[clock format [clock seconds] -format {%H:%M:%S}]"
		    } else {
			set results "[trans txtcmderr]\n\
				    [trans txtcommand]: ![trans cmdhour]\n\
				    [trans txtprm]: [trans prmhour]\n\
				    [trans txtdsc]: [trans dschour]\n\
				    [trans txtexl]: [trans exlhour]"
		    }
		    ::amsn::MessageSend $window 0 "$botname: $results"
	    } elseif { [string first "![trans cmddate]" $msg] == 0 } {
		    set commandLength [expr [string length [trans cmddate]] + 1]
		    if { $commandLength == [string length $msg] } {
			set results "[clock format [clock seconds] -format {%d/%m/%Y}]"
		    } else {
			set results "[trans txtcmderr]\n\
				    [trans txtcommand]: ![trans cmddate]\n\
				    [trans txtprm]: [trans prmdate]\n\
				    [trans txtdsc]: [trans dscdate]\n\
				    [trans txtexl]: [trans exldate]"
		    }
		    ::amsn::MessageSend $window 0 "$botname: $results"
	    } elseif { [string first "![trans cmdgoogle] " $msg] == 0 } {
		    set commandLength [expr [string length [trans cmdgoogle]] + 2]
		    set strWithoutCommand [string range $msg $commandLength end]

		    #get what options did the user wrote.
		    set arguments [googleparseArgs $strWithoutCommand]

		    #if everything is ok, keep on, else say that something went wrong
		    if { [string compare [lindex $arguments 2] "ok"] == 0 } {
			set results [googlesearchText [lindex $arguments 0] [lindex $arguments 1] $language]
		    } else {
			set results "[trans txtcmderr]\n\
				    [trans txtcommand]: ![trans cmdgoogle]\n\
				    [trans txtprm]: [trans prmgoogle $::jake::config(nresultsgoogle)]\n\
				    [trans txtdsc]: [trans dscgoogle]\n\
				    [trans txtexl]: [trans exlgoogle]"
		    }

		    #convert to plain text
		    set results [::htmlparse::mapEscapes $results]
		    if {[string compare $results "noresults"] == 0 } {
                        set results "$botname: [trans txtnoresults] [trans txtchangesearchwords]"
                    }
		    #print results
		    ::amsn::MessageSend $window 0 $results
	    } elseif { [string first "![trans cmdmegaupload] " $msg] == 0 } {
		    set commandLength [expr [string length [trans cmdmegaupload]] + 2]
		    set strWithoutCommand [string range $msg $commandLength end] 

                    #get what options did the user wrote.
                    set arguments [megauploadparseArgs $strWithoutCommand]

                    #if everything is ok, keep on, else say that something went wrong
                    if { [string compare [lindex $arguments 2] "ok"] == 0 } {
                        set results [megauploadsearch [lindex $arguments 0] [lindex $arguments 1]]
                    } else {
                        set results "[trans txtcmderr]\n\
                                    [trans txtcommand]: ![trans cmdmegaupload]\n\
                                    [trans txtprm]: [trans prmmegaupload $::jake::config(nresultsmegaupload)]\n\
                                    [trans txtdsc]: [trans dscmegaupload]\n\
                                    [trans txtexl]: [trans exlmegaupload]"
                    }

                    #convert to plain text
                    set results [::htmlparse::mapEscapes $results]
                    
                    #print results
                    ::amsn::MessageSend $window 0 $results
	    } elseif { [string first "![trans cmdyoutube] " $msg] == 0 } {   
		    #leave only the text after the command
		    set commandLength [expr [string length [trans cmdyoutube]] + 2]
		    set strWithoutCommand [string range $msg $commandLength end]

		    #get what options did the user wrote.
		    set arguments [youtubeparseArgs $strWithoutCommand]

		    #if everything is ok, keep on, else say that something went wrong
		    if { [string compare [lindex $arguments 2] "ok"] == 0 } {
			set results [youtubesearchVideos [lindex $arguments 0] [lindex $arguments 1]]
		    } else {
			set results "[trans txtcmderr]\n\
				    [trans txtcommand]: ![trans cmdyoutube]\n\
				    [trans txtprm]: [trans prmyoutube $::jake::config(nresultsyoutube)]\n\
				    [trans txtdsc]: [trans dscyoutube]\n\
				    [trans txtexl]: [trans exlyoutube]"
		    }
		    
		    #convert to plain text
		    set results [::htmlparse::mapEscapes $results]

		    #print results
		    ::amsn::MessageSend $window 0 $results
	    } elseif { [string first "![trans cmddefine] " $msg] == 0 } {  
		    set commandLength [expr [string length [trans cmddefine]] + 2]
		    set strWithoutCommand [string range $msg $commandLength end]

		    #get what options did the user wrote.
		    set arguments [googleparseArgs $strWithoutCommand]

		    #if everything is ok, keep on, else say that something went wrong
		    if { [string compare [lindex $arguments 2] "ok"] == 0 } {
			set results [googledefineText [lindex $arguments 0] [lindex $arguments 1] $language]
		    } else {
			set results "[trans txtcmderr]\n\
				    [trans txtcommand]: ![trans cmddefine]\n\
				    [trans txtprm]: [trans prmdefine]\n\
				    [trans txtdsc]: [trans dscdefine]\n\
				    [trans txtexl]: [trans exldefine]"
		    }

		    #convert to plain text
		    set results [::htmlparse::mapEscapes $results]
                    if {[string compare $results "noresults"] == 0 } {
                        set results "$botname: [trans txtnoresults] [trans txtchangesearchwords]"
                    }
		    #print results
		    ::amsn::MessageSend $window 0 $results
	    } elseif { [string first "![trans cmdlearn] " $msg] == 0 } {   
		    if { [array exists dictionary] == 0 } {
			    source [file join $::HOME "jake" "dictionary.dic"]
		    }
		    set commandLength [expr [string length [trans cmdlearn]] + 2]
		    set strWithoutCommand [string range $msg $commandLength end]      

                    #get what options did the user wrote.
                    set arguments [learnparseArgs $strWithoutCommand]

                    #if everything is ok, keep on, else say that something went wrong
                    if { [string compare [lindex $arguments 1] "ok"] == 0 } {
                        if { [learnaddToDictionary [lindex $arguments 0]] == 1 } {
                            set results "$botname: [trans txtregadd] [expr [array size dictionary] + 1] [trans txtregs]"
                        } else {
                            set results "$botname: [trans txterradd]"
                        }
                    } else {
                        set results "[trans txtcmderr]\n\
                                    [trans txtcommand]: ![trans cmdlearn]\n\
                                    [trans txtprm]: [trans prmlearn]\n\
                                    [trans txtdsc]: [trans dsclearn]\n\
                                    [trans txtexl]: [trans exllearn]"
                    }

                    #print results
                    ::amsn::MessageSend $window 0 $results
	    } elseif { [string first "![trans cmdforget] " $msg] == 0 } {  

		    set commandLength [expr [string length [trans cmdforget]] + 2]
		    set strWithoutCommand [string range $msg $commandLength end]  

                    #get what options did the user wrote.
                    set arguments [forgetparseArgs $strWithoutCommand]

		    if { [string compare [lindex $arguments 1] "ok"] == 0 } {
                        set results [forgetremoveFromDictionary [lindex $arguments 0]]
			set results "$botname: [trans txtregdel] $results [trans txtregs]"
                    } else {
                        set results "[trans txtcmderr]\n\
                                    [trans txtcommand]: ![trans cmdforget]\n\
                                    [trans txtprm]: [trans prmforget]\n\
                                    [trans txtdsc]: [trans dscforget]\n\
                                    [trans txtexl]: [trans exlforget]"
                    }
                    ::amsn::MessageSend $window 0 $results
	    } elseif { [string first "![trans cmdexpr] " $msg] == 0 } {
		    set commandLength [expr [string length [trans cmdexpr]] + 2]
		    set msg [string range $msg $commandLength end]
		    ::amsn::MessageSend $window 0 "$botname: [expr [string map {/ *1./} $msg]]"
	    } elseif { [string first "![trans cmdsong] " $msg] == 0 } {
		    #leave only the text after the command
		    set commandLength [expr [string length [trans cmdsong]] + 2]
		    set strWithoutCommand [string range $msg $commandLength end]

		    #get what options did the user wrote.
		    set arguments [musicparseArgs $strWithoutCommand]

		    #if everything is ok, keep on, else say that something went wrong
		    if { [string compare [lindex $arguments 2] "ok"] == 0 } {
			set results [musicsearchGoear [lindex $arguments 0] [lindex $arguments 1]]
			if { [musicCheckCoincidence $results [lindex $arguments 0]] == 1 } {
			    #convert to plain text
                            set results [::htmlparse::mapEscapes $results]
			    ::amsn::MessageSend $window 0 $results
			    return
			}
			set results [musicsearchElcamajan [lindex $arguments 0] [lindex $arguments 1]]
			if { [musicCheckCoincidence $results [lindex $arguments 0]] == 1 } {
			    #convert to plain text
			    set results [::htmlparse::mapEscapes $results]
			    ::amsn::MessageSend $window 0 $results
			    return
			}
			set results [musicsearchDilandau [lindex $arguments 0] [lindex $arguments 1]]
			if { [musicCheckCoincidence $results [lindex $arguments 0]] == 1 } {
			    #convert to plain text
			    set results [::htmlparse::mapEscapes $results]
			    ::amsn::MessageSend $window 0 $results
			    return
			}
			set results "$botname: [trans txtnoresults] [trans txtchangesearchwords]"
		    } else {
			set results "[trans txtcmderr]\n\
				    [trans txtcommand]: ![trans cmdsong]\n\
				    [trans txtprm]: [trans prmsong $::jake::config(nresultssongs)]\n\
				    [trans txtdsc]: [trans dscsong]\n\
				    [trans txtexl]: [trans exlsong]"
		    }

		    #print results
		    ::amsn::MessageSend $window 0 $results
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
		    ::amsn::MessageSend $window 0 "Procesos separados lanzados!"
		    update
		    set url "http://www.google.com"
		    set text [getPage $url]
		    after 5000 [list ::amsn::MessageSend $window 0 $text]
	    } elseif { $user != $me && [isuseroff $chatid] == 0} {
		    if { [array exists dictionary] == 0 } {
			    source [file join $::HOME "jake" "dictionary.dic"]
		    }
		    set i 1
		    set j 0.6
		    foreach index [array names dictionary] {
			    if { [expr ([stringSimilarity $msg $index]) > $j] } {
				    #set j [expr ([stringSimilarity $msg $index])]
				    set respuesta($i) $dictionary($index)
				    incr i
			    }
		    }
		    if { $i > 1 } {
			    ::amsn::MessageSend $window 0 "$botname: $respuesta([rand [array size respuesta] 1])"
		    } else {
			    if { [rand 9 1] == 1 } {
				    ::amsn::MessageSend $window 0 "$botname: $::jake::config(helptxt)"
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