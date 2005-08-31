proc bgerror { args } {
    ::bugs::bgerror $args
}

namespace eval ::bugs {
    variable dont_give_bug_reports 0
    variable details 0
    variable w ".bug_dialog"
    variable message
    variable website "http://localhost/~kkrizka/bugs/"

    proc bgerror { args } {
	global errorInfo errorCode HOME2 tcl_platform tk_version tcl_version
	variable dont_give_bug_reports
	
	if { [lindex $args 0] == [list] } {
	    return
	}
	
	if { $dont_give_bug_reports == 1 } {
	    return
	}
	
	set posend [split [.status.info index end] "."]
	set pos "[expr {[lindex $posend 0]-50}].[lindex $posend 1]"
	set posend "[lindex $posend 0].[lindex $posend 1]"
	
	set prot_posend [split [.degt.mid.txt index end] "."]
	set prot_pos "[expr {[lindex $prot_posend 0]-50}].[lindex $prot_posend 1]"
	set prot_posend "[lindex $prot_posend 0].[lindex $prot_posend 1]"

	if {[file exists cvs_date]==1} {
	    set fd [open cvs_date]
	    set date [gets $fd]
	    close $fd
	} else {
	    set date $::date
	}
		
	#save to a file
	set fd [open [file join $HOME2 bugreport.amsn] w]
	
	puts $fd "<?xml version=\"1.0\"?>"
	puts $fd "<bug>"
	puts $fd "\t<error>"
	puts $fd "\t\t<date>[clock seconds]</date>"
	puts $fd "\t\t<text>$args</text>"
	puts $fd "\t\t<stack>[privacy $errorInfo]</stack>"
	puts $fd "\t\t<code>$errorCode</code>"
	puts $fd "\t</error>"
	puts $fd "\t<system>"
	puts $fd "\t\t<amsn>$::version</amsn>"
	puts $fd "\t\t<date>$date</date>"
	puts $fd "\t\t<tcl>$tcl_version</tcl>\n\t\t<tk>$tk_version</tk>"
	foreach {key value} [array get tcl_platform] {
	    puts $fd "\t\t<[string tolower $key]>$value</[string tolower $key]>"
	}
	puts $fd "\t</system>"
	#catch { puts $fd ">>> tcl_platform array content : [array get tcl_platform]" }
	
	#set tclfiles [glob -nocomplain *.tcl]
	#set latestmtime 0
	#set latestfile ""
	#foreach tclfile $tclfiles {
	#file stat $tclfile filestat
	#set mtime $filestat(mtime)
	#if { $mtime > $latestmtime } {
	#set latestmtime $mtime
	#set latestfile $tclfile
	#}
	#}
	#puts $fd ">>> Latest modification time file: $latestfile: [clock format $latestmtime -format %y/%m/%d-%H:%M]"
	puts $fd "\t<extra>"
	puts $fd "\t\t<status_log>"
	puts $fd "[privacy [htmlentities [.status.info get $pos $posend]]]"
	puts $fd "\t\t</status_log>"
	puts $fd "\t\t<protocol_log>"
	puts $fd "[privacy [htmlentities [.degt.mid.txt get $prot_pos $prot_posend]]]"
	puts $fd "\t\t</protocol_log>"
	puts $fd "\t</extra>"
	puts $fd "</bug>\n\n"
	close $fd
	
	#msg_box "[trans tkerror [file join $HOME2 bugreport.amsn]]"
	
	#error message into status_log
	status_log "-----------------------------------------\n" error
	status_log ">>> GOT TCL/TK ERROR : $args\n>>> Stack:\n$errorInfo\n>>> Code: $errorCode\n" error
	status_log "-----------------------------------------\n" error
	catch { status_log ">>> AMSN version: $::version - AMSN date: $::date\n" error }
	catch { status_log ">>> TCL version : $tcl_version - TK version : $tk_version\n" error }
	catch { status_log ">>> tcl_platform array content : [array get tcl_platform]\n" error }
	status_log "-----------------------------------------\n\n" error

	::bugs::show_bug_dialog $errorInfo
    }

    proc show_bug_dialog {{info ''}} {
	
	variable w
	
	catch {destroy $w}
	toplevel $w -class Dialog
	wm title $w "AMSN Error"
	wm iconname $w Dialog
	wm protocol $w WM_DELETE_WINDOW "set ::bugs::closed_bug_window 1"
	
	if {![catch {tk windowingsystem} wsystem] && $wsystem == "aqua"} {
	    #Empty, NO TRANSIENT ON MAC OS X!!! Plz use ShowTransient when it's possible
	} else {
	    if {[winfo viewable [winfo toplevel [winfo parent $w]]] } {
		wm transient $w [winfo toplevel [winfo parent $w]]
	    }
	}


	frame $w.top
	frame $w.buttons
	
	set ::bugs::message [trans tkerror1]
	label $w.msg -justify left -textvariable "::bugs::message" -wraplength 300 -font sboldf

	label $w.bitmap -image [::skin::loadPixmap warning]

	checkbutton $w.ignoreerrors -text [trans ignoreerrors] -variable "::bugs::dont_give_bug_reports" -font sboldf

	button $w.button -text [trans ok] -command "set ::bugs::closed_bug_window 1"
	button $w.report -text [trans report] -command "::bugs::report"
	button $w.details_button -text [trans details] -command "::bugs::showdetails"
	text $w.details -height 15 -width 50
	$w.details insert 0.0 $info
	
	pack $w.top -side top -fill both
	pack $w.buttons -side right -fill both  -padx 3m -pady 3m -in $w.top
	
	#pack $w.top -side top -fill both -expand 1
	pack $w.bitmap -side left -padx 3m -pady 3m -in $w.top
	pack $w.msg -side top -expand 1 -anchor nw -padx 3m -pady 3m -in $w.top
	pack $w.button -in $w.buttons -fill x
	pack $w.report -in $w.buttons -fill x
	pack $w.details_button -in $w.buttons -fill x	
	pack $w.ignoreerrors -side top -padx 10 -pady 5 -anchor nw
	
	bind $w <Return> "set ::bugs::closed_bug_window 1"
	
	wm withdraw $w
	
	update idletasks
	
	set x [expr {[winfo screenwidth $w]/2 - [winfo reqwidth $w]/2 \
			 - [winfo vrootx [winfo parent $w]]}]
	set y [expr {[winfo screenheight $w]/2 - [winfo reqheight $w]/2 \
			 - [winfo vrooty [winfo parent $w]]}]
	# Make sure that the window is on the screen and set the maximum
	# size of the window is the size of the screen.  That'll let things
	# fail fairly gracefully when very large messages are used. [Bug 827535]
	if {$x < 0} {
	    set x 0
	}
	if {$y < 0} {
	    set y 0
	}
	wm maxsize $w [winfo screenwidth $w] [winfo screenheight $w]
	wm geom $w +$x+$y
	wm deiconify $w
	
	# 7. Set a grab and claim the focus too.
	
	set oldFocus [focus]
	set oldGrab [grab current $w]
	if {[string compare $oldGrab ""]} {
	    set grabStatus [grab status $oldGrab]
	}
	grab $w
	raise $w
	focus $w.button
	
	# 8. Wait for the user to respond, then restore the focus and
	# return the index of the selected button.  Restore the focus
	# before deleting the window, since otherwise the window manager
	# may take the focus away so we can't redirect it.  Finally,
	# restore any grab that was in effect.
	
	vwait ::bugs::closed_bug_window
	catch {focus $oldFocus}
	catch {
	    bind $w <Destroy> {}
	    destroy $w
	}
    }

    proc showdetails { } {
        variable details
        variable w
        if {$details == 0} {
            pack $w.details -fill both -expand 1
            set details 1
        } else {
            pack forget $w.details
            set details 0
        }
    }

    proc randomString {length {chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"}} {
	set range [expr {[string length $chars]-1}]
	set txt ""
	for {set i 0} {$i < $length} {incr i} {
	    set pos [expr {int(rand()*$range)}]
	    append txt [string range $chars $pos $pos]
	}
	return $txt
    }
    
    proc format {value} {
	set part "Content-Disposition: form-data; name=\"file\"; filename=\"bugreport.amsn\"\r\n"
	append part "Content-Type: text/plain\r\n"
	append part "\r\n"
	append part "$value"
	
	while {1} {
	    set boundary [::bugs::randomString 10]
	    if {[string first $boundary $part] == -1} {
		break;
	    }
	}
	
	set text "Content-Type: multipart/form-data; "
	append text "boundary=\"$boundary\"\r\n\r\n"
	append text "--$boundary\n"
	append text $part
	append text "--$boundary--\n"
	
	return $text
    }
    
    #cretids for the following proc: http://wiki.tcl.tk/13675
    proc post {url file} {
	global HOME2
	# get contents of the file
	set fd [open $file r]
	fconfigure $fd -translation binary
	set content [read $fd]
	close $fd
	
	# format the file and form
	set message [eval [list bugs::format $content]]
	
	# parse the headers out of the message body
	set message [split [string map {"\r\n\r\n" "\1"} $message] "\1"]
	set headers_raw [lindex $message 0]
	set body [join [lrange $message 1 end] "\r\n\r\n"]
	
	set headers_raw [string map {"\r\n " " " "\r\n" "\n"} $headers_raw]
	regsub {  +} $headers_raw " " headers_raw
	#set headers {} -- initial value comes from parameter
	foreach line [split $headers_raw "\n"] {
	    regexp {^([^:]+): (.*)$} $line all label value
	    lappend headers $label $value
	}
	
	# get the content-type
	array set ha $headers
	set content_type $ha(Content-Type)
	unset ha(Content-Type)
	set headers [array get ha]
	
	# create a temporary file for the body data (getting the temp directory
	# is more involved if you want to support Windows right)
	set datafile [file join $HOME2 bugreport.amsn.tmp]
	set data [open $datafile w+]
	fconfigure $data -translation binary
	puts -nonewline $data $body
	seek $data 0
	
	# POST it
	set token [http::geturl $url -type $content_type -binary true \
		       -headers $headers -querychannel $data]
	http::wait $token
	
	# cleanup the temporary
	close $data
	file delete $datafile
	
	return $token
    }
    
    proc report { } {
	global HOME2
	variable w
	$w.report configure -text [trans reporting] -state disabled
	
	#bugs::post {url field type file {params {}} {headers {}}}
	set lang [::config::getGlobalKey language]
	if { [catch {set token [bugs::post "$::bugs::website/report.php?lang=$lang" [file join $HOME2 bugreport.amsn]]}] == 0} {
	    upvar #0 $token state
	    set ::bugs::message $state(body)
	} else {
	    set ::bugs::message [trans bugerror]
	}
	
	$w.report configure -text [trans done]
    }
}

proc privacy { str } {
    regsub -all {[A-Za-z0-9._-]{3}@[A-Za-z0-9.-]+} $str {xxx@sadamsnuser.com} str
    #take care of url encoded ones 
    regsub -all {[A-Za-z0-9._-]{3}%40[A-Za-z0-9.-]+} $str {xxx%40sadamsnuser.com} str
    return $str
}

proc htmlentities {str} {
    regsub -all & $str {\&amp;} str
    regsub -all {\<} $str {\&lt;} str
    regsub -all {\>} $str {\&gt;} str
    regsub -all {\"} $str {\&quot;} str
    #all apostrophes are changed to a ` because php had trouble rendering them
    regsub -all {\'} $str {\&#96;} str
    return $str
}

