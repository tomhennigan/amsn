proc forgetparseArgs { string_text } {
    #element 0 from list = text to remove
    #element 1 from list = status (ok if everything is ok, else err) 

    #if string starts with " and ends with " everyrhing is ok
    #else string isn't well formatted.
    if { [regexp -- {^".*"$} $string_text] } {
        set arguments [list $string_text "ok"]
    } else {
        set arguments [list "" "err"]
    }
    return $arguments
}

proc forgetremoveFromDictionary { string_text } {
    if { [array exists dictionary] == 0 } {
            source [file join $::HOME "jake" "dictionary.dic"]
    }
    regsub -all {\"} $string_text "" string_text
    regsub -all {\$} $string_text "\\\\\\\$" string_text ;#DLH
    set in [open [file join $::HOME "jake" "dictionary.dic"] "r"]
    set out [open [file join $::HOME "jake" "dictionary.dic.tmp"] "w"]
    set i 0
    while { [gets $in line] >= 0 } {
            incr i
            if { [string match "set \"dictionary($string_text)\"*" $line] == 0 } {
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
    close $in
    return [expr $i - $j]
}