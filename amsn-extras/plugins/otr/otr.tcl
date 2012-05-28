namespace eval ::otr {

    global mydir

    proc otrStart { dir } {

        global mydir
        set mydir $dir

        #Register the plugin
        ::plugins::RegisterPlugin "Off The Record"
        ::plugins::RegisterEvent "Off The Record" new_conversation populate_chatwindow
        ::plugins::RegisterEvent "Off The Record" chat_msg_send encrypt
        ::plugins::RegisterEvent "Off The Record" chat_msg_receive decrypt
        ::plugins::RegisterEvent "Off The Record" PacketReceived ReadSBRaw

        #Set and load the language for the plugin
        set langdir [file join $mydir "lang"]       
        set lang [::config::getGlobalKey language]    
        load_lang en $langdir
        load_lang $lang $langdir

        set c [::abook::getAllContacts]

        foreach contact $c {                            
            set ::otr::config($contact) 0
        }

        #Create the array used in the conf
        array set ::otr::config {

        }

        set ::otr::configlist [list \

        ]

        # Wrap the message
        if {[info proc ::otr::Original_WriteSBRaw] == "" } {
            rename ::MSN::WriteSBRaw ::otr::Original_WriteSBRaw
        }

        proc ::MSN::WriteSBRaw { sbn data } {
            eval [list ::otr::WriteSBRaw $sbn $data]
        }

    }

    proc otrEnd { } {

      if {[info proc ::otr::Original_WriteSBRaw] != "" } {
          rename ::MSN::WriteSBRaw ""
          rename ::otr::Original_WriteSBRaw ::MSN::WriteSBRaw
      }

    }

    proc populate_chatwindow {event evpar} {

        upvar 2 $evpar args

        set chatid $args(chatid)
        set window [::ChatWindow::For $chatid] 
        set placement $window.top.padding
        set ui $placement.otr
        frame $ui
        
        set status  $ui.status
        set onoff $ui.cb

        if { $::otr::config($chatid) == 0 } {
            label $status -text "This conversation is not OTRed"
        } else {
            label $status -text "This conversation is OTRed"
        }
        
        checkbutton $onoff -indicatoron 1 -onvalue 1 -offvalue 0 -command "::otr::changeState $chatid $status"    \
            -selectcolor green -text "On/Off OTR" -variable ::otr::config($chatid)
        
        pack $status -side left
        pack $onoff -side right -padx 2
        pack $ui -fill x

    }

    proc changeState { chatid status } {
        if { $::otr::config($chatid) == 0 } {
            $status configure -text "This conversation is not OTRed"
        } else {
            $status configure -text "This conversation is OTRed"
        }
    }

    proc encrypt { user data } {
        return $data
    }

    proc decrypt { user data } {
        return $data
    }

    proc BuildMultipartMessages { chatid encrypted_message} {
        set sbn [::MSN::SBFor $chatid]
        if { $sbn == 0 } { return }

        set total [expr int (ceil ([string length $encrypted_message] / 400.0))]
        set msgid "[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [myRand 4369 65450]]-[format %X [expr { int([expr {rand() * 1000000}])%65450 } ] + 4369]-[format %X [myRand 4369 65450]][format %X [myRand 4369 65450]][format %X [myRand 4369 65450]]"

        for {set part 1 } { $part <= $total } { incr part } {
            set first [expr ($part-1)*400]

            if { $part != $total } {
                set last [expr $first+399]
            } else {
                set last [string length $encrypted_message]
            }

            set chunk [string range $encrypted_message $first $last]
            set packet ""

            if {$part == 1 } {
                #That's wrong
                set packet "MIME-Version: 1.0\r\nContent-Type: application/x-otr-data\r\n"

                if { $total == 1 } {
                    set packet "${packet}\r\n$chunk"
                } else {
                    set packet "${packet}Message-ID: \{$msgid\}\r\nChunks: $total\r\n\r\n$chunk"
                }

            } else {
                set packet "${packet}Message-ID: \{$msgid\}\r\nChunk: [expr $part-1]\r\n\r\n$chunk"
            }

            set packet_length [string length $packet]
            set packet "MSG [incr ::MSN::trid] A $packet_length\r\n$packet"
            lappend messages_list $packet
        }
        return $messages_list
    }   

    proc ReadSBRaw { event evpar } {
        upvar 2 $evpar args
        upvar 2 $args(chatid) chatid
        upvar 2 $args(msg) message
        upvar 2 command command

        set sbn [::MSN::SBFor $chatid]
        if { $sbn == 0 } { return }

        set content_type [lindex [split [$message getHeader Content-Type] ";"] 0]

        set user [::MSN::usersInChat $chatid]
        if { [llength $user] != 1} {
            return
        }

        switch -- $content_type {
            #Detect ?OTR?+version
            #That's wrong. See BuildMultipartMessages
            application/x-otr-data {
                if { $::otr::config($chatid) == 1 } {
                    set plaintext [::otr::decrypt $user $message]
                    set message_received [Message create %AUTO%]

                    set plaintext [string map {"\n" "\r\n"} $plaintext]
                    $message_received createFromPayload $plaintext

                    $sbn handleMSG $command $message_received
                }
            }
        }
    }

    proc WriteSBRaw { sbn data } {
        set chatid [::MSN::ChatFor $sbn]

        if {$chatid != 0} {
            set user [::MSN::usersInChat $chatid]
            if { [llength $user] == 1 && 
                 [lindex [split $data] 0] == "MSG" &&
                 $::otr::config($chatid) == 1
            } {
                set msg [join [lrange [split $data \n] 1 end] \n]
                set encrypted_message [::otr::encrypt $user $msg]
                if { $encrypted_message == "" } {
                    ::otr::Original_WriteSBRaw $sbn $data
                }
                status_log $encrypted_message
                set messages [::otr::BuildMultipartMessages $user $encrypted_message]
                status_log $messages
                foreach data $messages {
                    ::otr::Original_WriteSBRaw $sbn $data
                }
            } else {
                ::otr::Original_WriteSBRaw $sbn $data
            }
        } else {
            ::otr::Original_WriteSBRaw $sbn $data
        }
    }


}