proc stateparseArgs { string_text } {
    #element 1 from list = contact
    #element 2 from list = status (ok if everything is ok, else err) 

    #if string starts with " and ends with " there are no other args
    #else string isn't well formatted.
    if { [regexp -- {^".*"$} $string_text] } {
        #remove first char
        set string_text [string range $string_text 1 end]
        #remove last char
        set string_text [string range $string_text 0 [expr [string length $string_text] - 2]]
        set arguments [list $string_text "ok"]
    } elseif { [regexp -- {} $string_text] } {
        set arguments [list "" "ok"]
    } else {
        set arguments [list "" "err"]
    }
    return $arguments
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

proc stategetState {starttime birthday chatid} {
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
    append version "0.8 STABLE"
    #dictionary size info
    if { [array exists dictionary] == 0 } {
            source [file join $::HOME "jake" "dictionary.dic"]
    }
    set dictionarysize [trans txtdictionarysize]
    append dictionarysize [array size dictionary]
    append dictionarysize " [trans txtregs]"
    if { [isuseroff $chatid] } {
            set state "[trans msgoff]"
            set results "\n\n$state\n$version\n$dictionarysize\n$uptime\n$lifetime"
    } else {
            set state "[trans msgon]"
            set results "\n\n$state\n$version\n$dictionarysize\n$uptime\n$lifetime"
    }
    return $results
}

proc stategetLastSeen { string_text } {
        set user_state_code [::abook::getVolatileData $string_text state FLN]
        if {[string equal $user_state_code "FLN"] == 1} {
            set fileId [file join $::HOME "jake" $string_text]
            if { [file exists $fileId] } {
                set fileId [open  $fileId "r+"]
                set saying [gets $fileId]
                set lastseen [clock format [gets $fileId] -format "%D - %H:%M:%S"]
                close $fileId
                return [list $saying $lastseen]
            } else {
                return notonlinebutneverseen
            }
        } else {
            return online
        }
}

proc statesetLastWord { event epvar } {
    
    upvar 2 $epvar args
    upvar 2 $args(msg) string_text
    upvar 2 $args(chatid) string_contact
    upvar 2 $args(user) user
    if { [string equal $string_contact $user] } {
        set fileId [file join $::HOME "jake" $string_contact]
        set fileId [open  $fileId "w"]
        regsub -all {[\r\t\n]+} $string_text "" string_text
        puts $fileId $string_text
        puts $fileId [clock seconds]
        close $fileId
    }
}

proc statesetLastSeen { event epvar } {
    upvar 2 $epvar args
    upvar 2 $args(substate) string_contact
    upvar 2 $args(substate) state
    if { [string equal $state "FLN"] == 1} {
        set fileId [file join $::HOME "jake" $string_contact]
        if { [file exists $fileId] } {
            set fileId [open  $fileId "r"]  
            set saying [gets $fileId]
            close $fileId
            set fileId [open  $fileId "w"]
            puts $fileId $saying
            puts $fileId [clock seconds]
            close $fileId
        } else {
            set fileId [open  $fileId "w"]
            puts $fileId ""
            puts $fileId [clock seconds]
            close $fileId
        }
    }
}