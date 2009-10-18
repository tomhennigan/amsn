proc youtubeparseArgs { string_text } {
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
	set arguments [list $string_text $::jake::config(nresultsyoutube) "ok"]
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

proc youtubesearchVideos { string_text number_of_results } {
    #we need this
    package require http

    set query [httpformatQuery q $string_text max-results $number_of_results v 2]
    set token [::http::geturl http://gdata.youtube.com/feeds/api/videos?$query -timeout 8000]
    set ncode [::http::ncode $token]
    set data [::http::data $token]
    ::http::cleanup $token

    set matches [regexp -all -inline {<title>.*?href='.*?'/>} $data]
    set count 0
    foreach match $matches {
	regexp {<title>(.*?)</title>.*href='(.*?)'/>} $match => title url
	incr count
	if { $count > 1 } {
	    append results [expr $count - 1].\ $title " - " $url \n\n
	}
    }
    #remove the last \n\n
    set results [string range $results 0 [expr [string length $results] - 3]]
    return $results
}

proc youtubedownloadMp3 { url } {
    #TODO
}

proc youtubedownloadVideo { url } {
    #TODO
}