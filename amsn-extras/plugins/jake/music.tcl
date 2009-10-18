proc musicparseArgs { string_text } {
    #element 1 from list = text to search
    #element 2 from list = number of results to show
    #element 3 from list = status (ok if everything is ok, else err) 

    #if string starts with " and ends with " there are no other args
    #elseif string starts with " and has at least one more ". We might have aditional args!
    #else string isn't well formatted.
    if { [regexp -- {^".*"$} $string_text] } {
	#remove first char
	set string_text [string range $string_text 1 end]
	#remove last char
	set string_text [string range $string_text 0 [expr [string length $string_text] - 2]]
	set arguments [list $string_text $::jake::config(nresultssongs) "ok"]
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

proc musicCheckCoincidence { string_results string_searched} {
    #little hack to help matching lines.
    append string_results "\n\n"

    set numberofsearchedwords [llength $string_searched]
    set matches [regexp -all -inline {.*?\n\n} $string_results]
    set i 1
    foreach match $matches {
	regexp {.(.*?) - http} $match -> title
	if { [info exists title] == 1 } {
	    set title [string range $title 2 [string length $title]]
            foreach word $string_searched {
               if { [regexp -nocase -- $word $title] == 1 } {
                   incr i
               }
            }
	    if { $i > 2} { set i [expr $i - 1] }
	    if { $i >= $numberofsearchedwords } {
		return 1
	    } else {
		set i 1
	    }   
	}
    }
    return 0
}

proc musicsearchGoear { string_text number_of_results} {
    #we need this
    package require http
    set page 0
    set count 0
    set results ""
    catch {
        while { $count <= $number_of_results } {
            set query [httpformatQuery q $string_text]
            set token [::http::geturl http://www.goear.com/search.php?$query -timeout 8000]
            set ncode [::http::ncode $token]
            set data [::http::data $token]
            ::http::cleanup $token

            regexp {<iframe src=\"(.*?)\"} $data -> resultsrc ;#link containing results
            regexp {q=(.*?)&p=0} $resultsrc -> search_string ;#search string
            set query [httpformatQuery q $search_string]

            regexp {http://(.*?)php} $resultsrc -> temp
            set srclink "http://"
            append srclink $temp
            append srclink "php?"
            append srclink $query
            append srclink "&p="
            append srclink $page

            set token [::http::geturl $srclink -timeout 8000]
            set ncode [::http::ncode $token]
            set data [::http::data $token]
            ::http::cleanup $token

            set matches [regexp -all -inline {<pre>.*?</pre>} $data]
            foreach match $matches {
                regexp {href=\'(.*?)\'>(.*?)</a>} $match => falseurl title
                regexp {listen/(.*?)/} $falseurl -> id
                set token [::http::geturl "http://www.goear.com/files/xmlfiles/[string index $id 0]/secm$id.xml" -timeout 8000]
                set data [::http::data $token]
                ::http::cleanup $token
                regexp {path=\"(.*?)\"} $data -> url
                if { [info exists title] == 1 } {
                    incr count
                }
                if { $count <= $number_of_results && [info exists title] == 1 && [info exists url] == 1 } {
                    append results $count.\ $title " - " $url \n\n
                } else {
                    if { [info exists results] == 0 } {
                        set results noresults
                    } else {
                        #remove the last \n\n
                        set results [string range $results 0 [expr [string length $results] - 3]]
                    }
                    return $results
                }
            }
            incr page
        }
    }
    return $results
}

proc musicsearchElcamajan { string_text number_of_results} {
    #we need this
    package require http
    set page 1
    set count 0
    set results ""
    catch {
        while { $count <= $number_of_results } {
            regsub -all { +} $string_text {-} string_text
            set token [::http::geturl http://www.elcamajan.com/musicamp3/search/$string_text/$page/ -timeout 8000]
            set ncode [::http::ncode $token]
            set data [::http::data $token]
            ::http::cleanup $token

            set matches [regexp -all -inline {<table border=\"2\".*?id=\"row.*?</table>} $data]
            foreach match $matches {
                regexp {<a href=\".*?\">(.*?)</a></b>.*?<br><br>.*?<br><br>.*?<a href=\"(.*?)\"></a>} $match => title url

                if { [info exists title] == 1 } {
                    incr count
                }
                if { $count <= $number_of_results && [info exists title] == 1 && [info exists url] == 1 } {
                    append results $count.\ $title " - " $url \n\n
                } else {
                    if { [info exists results] == 0 } {
                        set results noresults
                    } else {
                        #remove the last \n\n
                        set results [string range $results 0 [expr [string length $results] - 3]]
                    }
                    return $results
                }
            }
            incr page
        }
    }
    return $results
}

proc musicsearchDilandau { string_text number_of_results} {
    #we need this
    package require http
    set page 1
    set count 0
    set results ""
    catch {
        while { $count <= $number_of_results } {
            set query [httpformatQuery $string_text]
            set token [::http::geturl http://www.dilandau.com/download_music/$query-$page.html -timeout 8000]
            set ncode [::http::ncode $token]
            set data [::http::data $token]
            ::http::cleanup $token

            set matches [regexp -all -inline {<div class=\"result result_.*?</a>} $data]
            foreach match $matches {
                regexp {title=\"(.*?)\".*? href=\"(.*?)\"} $match => title url
                if { [info exists title] == 1 } {
                    incr count
                }
                if { $count <= $number_of_results && [info exists title] == 1 && [info exists url] == 1 } {
                    append results $count.\ $title " - " $url \n\n
                } else {
                    if { [info exists results] == 0 } {
                        set results noresults
                    } else {
                        #remove the last \n\n
                        set results [string range $results 0 [expr [string length $results] - 3]]
                    }
                    return $results
                }
            }
            incr page
        }
    }
    return $results
}