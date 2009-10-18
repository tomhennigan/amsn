proc megauploadparseArgs { string_text } {
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
        set arguments [list $string_text $::jake::config(nresultsmegaupload) "ok"]
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

proc megauploadsearch { string_text number_of_results} {
    #we need this
    package require http
    set page 1
    set count 0
    set results ""
    set matches {}
    catch {
        while { $count <= $number_of_results } {
            set query [httpformatQuery q $string_text page $page]
            set token [::http::geturl http://4megaupload.com/index.php?$query -timeout 8000]
            set ncode [::http::ncode $token]
            set data [::http::data $token]
            ::http::cleanup $token

            set matches [regexp -all -inline {<a href=\"download_file.*?</span><br></td>} $data]
            foreach match $matches {
                regexp {<a href=\"download_file.php?(.*?)\".*?title=\'(.*?)\'.*?>.*?>.*?>(.*?)</span>} $match => url title size
                regsub -all {[ \r\t\n]+} $size "" size
                regsub -all {/url\?q=} $url "" url
                regsub -all { +} $url "" url
                if { [info exists title] == 1 } {
                    incr count
                }
                if { $count <= $number_of_results && [info exists title] == 1 && [info exists url] == 1 } {
                    append results $count.\ $title " - " $size " - http://4megaupload.com/download_file.php" $url\n\n
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