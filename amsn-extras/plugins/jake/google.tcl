proc googleparseArgs { string_text } {
    #element 0 from list = text to search
    #element 1 from list = number of results to show
    #element 2 from list = status (ok if everything is ok, else err) 

    #if string starts with " and ends with " there are no other args
    #elseif string starts with " and has at least one more ". We might have aditional args!
    #else string isn't well formatted.
    if { [regexp -- {^".*"$} $string_text] } {
	#remove first char
	set string_text [string range $string_text 1 end]
	#remove last char
	set string_text [string range $string_text 0 [expr [string length $string_text] - 2]]
	set arguments [list $string_text $::jake::config(nresultsgoogle) "ok"]
    } elseif { [regexp -- {^".*"} $string_text] } {
	#search for the first index of "
	set first_index [string first \" $string_text]
	#search for the last index of "
	set last_index [string last \" $string_text]
	#get the number of results to show and remove spaces
	set number_of_results [string range $string_text [expr $last_index + 1] [string length $string_text]]
	regsub -all { +} $number_of_results {} number_of_results
	#get the string between "
	set string_text [string range $string_text 1 [expr $last_index - 1]]
	#check if the string containing the number of results is integer
	if { [string is integer -strict $number_of_results] } {
	    set arguments [list $string_text $number_of_results "ok"]
	} else {
	    set arguments [list "" 0 "err"]
	}
    } else {
	set arguments [list "" 0 "err"]
    }
    return $arguments
}

proc googlesearchText { string_text number_of_results language} {
    #we need this
    package require http
    set count 0
    set page 0
    set ncode 0
    catch {
        while { $count <= $number_of_results } {
            if { $ncode == 403 } {
                ::http::config -useragent "Jake searcher 0.8 BETA"
                set page 0
            }
            set query [httpformatQuery hl $language num 10 q $string_text start $page]
            set token [::http::geturl http://www.google.com/search?$query -timeout 8000]
            set ncode [::http::ncode $token]
            set data [::http::data $token]
            ::http::cleanup $token

            set spellcheck [regexp -all -inline {class=spell><b><i>.*?</i></b></a>} $data]
            if { $spellcheck != "" } {
                regexp {class=spell><b><i>(.*?)</i></b></a>} $spellcheck -> spellcheck
                append results "[trans txtmaybe]" " " $spellcheck \n\n
            }
            set matches [regexp -all -inline {<li class=g><h3 class=r><a href=.*?</a></h3>} $data]
            foreach match $matches {
                if { $spellcheck == "" } {
                    regexp {<a href=.(.*?). class=l>(.*?)</a></h3>} $match => url title
                    if { [info exists title] == 1 } {
                        incr count
                    }
                } else {
                    regexp {<a href=.(.*?).>(.*?)</a></h3>} $match => url title
                    if { [info exists title] == 1 } {
                        incr count
                    }
                }
                if { $count <= $number_of_results && [info exists title] == 1 && [info exists url] == 1 } {
                    append results $count.\ $title " - " $url \n\n
                } else {
                    if { [info exists results] == 0 } {
                        set results noresults
                    } else {
                        #remove the last \n\n
                        set results [string range $results 0 [expr [string length $results] - 3]]
                        #remove the <em></em> thing
                        regsub -all {<em>} $results "" results
                        regsub -all {</em>} $results "" results
                    }
                    return $results
                }
            }
            set page [expr $page + 10]
        }
    }
    return $results
}

proc googledefineText { string_text number_of_results language} {
    #we need this
    package require http

    set query [httpformatQuery hl $language q define:$string_text]
    set token [::http::geturl http://www.google.com/search?$query -timeout 8000]
    set ncode [::http::ncode $token]
    set data [::http::data $token]
    ::http::cleanup $token

    set matches [regexp -all -inline {<li>.*?</font></a>} $data]
    set count 0
    foreach match $matches {
	regexp {<li>(.*?)<br>(.*?)</a>} $match => title url
	regexp {<a href=\"(.*?)\"><font color=.......>(.*?)</font>} $url => garbage url
	if { [info exists title] == 1 } {
	    incr count
	}
	if { $count <= $number_of_results && [info exists title] == 1 && [info exists url] == 1 } {
	    append results $count.\ $title " - " $url \n\n
	} else {
            if { [info exists results] == 0 } {
                set results noresults
            }
        }
    }
    if { [info exists results] == 0 } {
        set results noresults
    } else {
        #remove the last \n\n
        set results [string range $results 0 [expr [string length $results] - 3]]
        #remove the <em></em> thing
        regsub -all {<em>} $results "" results
        regsub -all {</em>} $results "" results
    }
    return $results
}