proc learnparseArgs { string_text } {
    #element 0 from list = text to add
    #element 1 from list = status (ok if everything is ok, else err) 

    #if string starts with " and ends with " everyrhing is ok
    #else string isn't well formatted.
    if { [regexp -- {^"[^"]*" "[^"]*"$} $string_text] } {
        set arguments [list $string_text "ok"]
    } else {
        set arguments [list "" "err"]
    }
    return $arguments
}

proc learnalterString {phrase z} {
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
            return $phrase
        }
    } else {
        return -1
    }
}

proc learnaddToDictionary { string_text } {
    set originalMsg $string_text
    regexp {\"(.*?)\" \"} $string_text -> originalPhrase
    regsub -all {\"} $originalPhrase "\\\"" phrase
    regsub -all {\$} $phrase "\\\$" phrase ;#DLH
    source [file join $::HOME "jake" "dictionary.dic"]
    set z 0
    while {1} {
            if {[info exists dictionary($phrase)] == 1} {
                    set phrase [learnalterString $phrase $z]
                    if {[string equal $phrase "-1"]} {
                            return 0
                    } else {
                            incr z
                    }
            } else {
                  set msg [string map [list $originalPhrase $phrase] $originalMsg]
                  set msg [string range $msg 1 end]
                  regsub -all {\" \"} $msg ")\" \"" msg
                  set fileId [open [file join $::HOME  "jake" "dictionary.dic"] "a+"]
                  puts $fileId "set \"dictionary($msg"
                  close $fileId
                  return 1
            }
    }
}