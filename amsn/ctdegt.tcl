###################### Emilio's Additions ###########################
proc degt_protocol { str } {
    .degt.mid.txt insert end "$str\n"
}

proc degt_protocol_win { } {
#    global debug_id
    toplevel .degt
    wm title .degt "MSN Protocol Debug"
    wm iconname .degt "MSNProt"
    wm state .degt withdraw

#   .notify.c insert $debug_id 0 $notify_text
#   set debug_id [.degt.c create text 75 50 -font {Helvetica 10} \ -justify center]
    frame .degt.top
        label .degt.top.name -text "Protocol" -justify left
#        label .degt.top.lines -textvariable lineCnt -justify right
	pack .degt.top.name -side left -anchor w
#	pack .degt.top.lines -side right  -anchor e -fill x

    frame .degt.mid
	scrollbar .degt.mid.sy -orient vertical -command ".degt.mid.txt yview"
	scrollbar .degt.mid.sx -orient horizontal -command ".degt.mid.txt xview"
	text   .degt.mid.txt -relief sunken -height 20 -width 85 -font fixed \
		-wrap none \
	 	-yscrollcommand ".degt.mid.sy set" \
		-xscrollcommand ".degt.mid.sx set"
	pack .degt.mid.sy -side right -fill y
	pack .degt.mid.sx -side bottom -fill x
	pack .degt.mid.txt -anchor nw

    frame .degt.bot -relief sunken -borderwidth 1
    	button .degt.bot.clear  -text "Clear" \
		-command ".degt.mid.txt delete 0.0 end"
    	button .degt.bot.close -text "Close" -command "wm withdraw .degt"
	pack .degt.bot.close .degt.bot.clear -side left

    pack .degt.top .degt.mid .degt.bot -side top

    bind . <Control-d> { wm state .degt normal }
    bind . <Control-t> { wm state .degt withdraw }
}    
###################### ****************** ###########################


