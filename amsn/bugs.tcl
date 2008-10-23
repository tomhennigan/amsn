
::Version::setSubversionId {$Id$}

proc bgerror { args } {
	set err $::errorInfo
	#if { [catch {::bugs::bgerror $args} res ] } {
		puts "Original stack trace :\n$err"
		puts "\nStack trace of bgerror :\n$::errorInfo"
		error $res
	#}
}

namespace eval ::bugs {
    variable dont_give_bug_reports 0
    variable details 0
    variable w ".bug_dialog"
    variable message
    variable bug 
    array set ::bugs::bug [list text "" date "" code "" info "" status "" protocol "" comment ""]
    
    #converts yyyyMMddhhmm to UNIX timestamp
    proc cvstostamp { date } {
	#get number of years
	set year [string range $date 0 3] 
	set month [string range $date 4 5]
	set day [string range $date 6 7]
	set hour [string range $date 8 9]
	set minute [string range $date 10 11]

	return [clock scan "$month/$day/$year $hour:$minute:00"]
    }

	proc get_svn_revision { } {
		variable svn_revision
		set entries_file [file join .svn entries]
		if { [file exists "$entries_file"] } {
			set svn_revision -1
			set sxml_err -1
			catch {
				set sxml_id [::sxml::init $entries_file]
				::sxml::register_routine $sxml_id "wc-entries:entry" ::bugs::got_svn_entry
				set sxml_err [::sxml::parse $sxml_id]
				::sxml::end $sxml_id
			} 
			if { $sxml_err == 0 } {
				return $svn_revision
			} else {
				return -1
			}
		} else {
			return -1
		}
	}
	
	proc got_svn_entry   {cstack cdata saved_data cattr saved_attr args} { 
		variable svn_revision
		array set attr $cattr
		if { [info exists attr(name)] && [info exists attr(revision)] && $attr(name) == "" } { 
			set svn_revision $attr(revision)
		}
		return 0
	}

    proc bgerror { args } {
	global errorInfo errorCode HOME2 tcl_platform tk_patchLevel tcl_patchLevel vendor
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

	set ::bugs::bug(text) [htmlentities $args]
	set ::bugs::bug(code) $errorCode
	set ::bugs::bug(info) [privacy [htmlentities $errorInfo]]
	set ::bugs::bug(status) [privacy [htmlentities [.status.info get $pos $posend]]]
	set ::bugs::bug(protocol) [privacy [htmlentities [.degt.mid.txt get $prot_pos $prot_posend]]]
	set ::bugs::bug(comment) ""
	set ::bugs::bug(msnprotocol) [::config::getKey protocol]
	set ::bugs::bug(loadedplugins) $::plugins::loadedplugins
	set ::bugs::bug(vendor) $vendor

	if {$::Version::amsn_revision > 0} {
	    set date $::Version::date
	} else {
	    set date  [clock scan "$::date 00:00:00"]
	}

	set ::bugs::bug(date) $date

	#error message into status_log
	status_log "-----------------------------------------\n" error
	status_log ">>> GOT TCL/TK ERROR : $args\n>>> Stack:\n[privacy $errorInfo]\n>>> Code: $::bugs::bug(code)\n" error
	status_log "-----------------------------------------\n" error
	catch { status_log ">>> AMSN version: $::version - AMSN date: $date\n" error }
	catch { status_log ">>> TCL version : $tcl_patchLevel - TK version : $tk_patchLevel\n" error }
	catch { status_log ">>> tcl_platform array content : [array get tcl_platform]\n" error }
	status_log "-----------------------------------------\n\n" error

	::bugs::show_bug_dialog [privacy $errorInfo]
    }

    proc save {path} {
	global tcl_platform tk_patchLevel tcl_patchLevel
	variable bug

	if {"$path" == ""} {
	    return;
	}

	#save to a file
	set fd [open "$path" w]
	
	puts $fd "<?xml version=\"1.0\"?>"
	puts $fd "<bug version=\"0.3\">"
	puts $fd "\t<error>"
	puts $fd "\t\t<date>[clock seconds]</date>"
	puts $fd "\t\t<text>$bug(text)</text>"
	puts $fd "\t\t<stack>$bug(info)</stack>"
	puts $fd "\t\t<code>$bug(code)</code>"
	puts $fd "\t</error>"
	puts $fd "\t<system>"
	puts $fd "\t\t<amsn>$::version</amsn>"
	puts $fd "\t\t<revision>$::Version::amsn_revision</revision>"
	puts $fd "\t\t<date>$bug(date)</date>"
	puts $fd "\t\t<tcl>$tcl_patchLevel</tcl>\n\t\t<tk>$tk_patchLevel</tk>"
	foreach {key value} [array get tcl_platform] {
	    puts $fd "\t\t<[string tolower $key]>$value</[string tolower $key]>"
	}
	puts $fd "\t\t<msnprotocol>$bug(msnprotocol)</msnprotocol>"
	puts $fd "\t\t<loadedplugins>$bug(loadedplugins)</loadedplugins>"
	puts $fd "\t\t<vendor>$bug(vendor)</vendor>"
	puts $fd "\t</system>"
	puts $fd "\t<extra>"
	puts $fd "\t\t<status_log>"
	puts $fd "$bug(status)"
	puts $fd "\t\t</status_log>"
	puts $fd "\t\t<protocol_log>"
	puts $fd "$bug(protocol)"
	puts $fd "\t\t</protocol_log>"
	puts $fd "\t</extra>"
	puts $fd "\t<user>"
	if {$bug(email) == 1} {
	    puts $fd "\t\t<email>[::config::getKey login]</email>"
	}
	puts $fd "\t\t<comment>"
	puts $fd "$bug(comment)"
	puts $fd "\t\t</comment>"
	puts $fd "\t</user>"
	puts $fd "</bug>\n\n"
	close $fd
    }

    proc update_comment {} {
	variable w
	set ::bugs::bug(comment) [$w.f.t get 0.0 end]
    }

    proc show_bug_dialog {{info ''}} {
	
	variable w
	
	catch {destroy $w}
	toplevel $w -class Dialog
	wm title $w "AMSN Error"
	wm iconname $w Dialog
	wm protocol $w WM_DELETE_WINDOW "set ::bugs::closed_bug_window 1"
	
	ShowTransient $w [winfo toplevel [winfo parent $w]]

	set ::bugs::message [trans tkerror1]
	
	label $w.msg -justify left -textvariable "::bugs::message" -wraplength 500 -font sboldf
	label $w.desc_l -text "[trans enterbugdesc]"
	frame $w.f
	text $w.f.t -height 5 -width 50 -bg #FFFFFF -relief sunken -highlightthickness 0 -exportselection 1
	
	frame $w.c1
	checkbutton $w.c1.check -variable "::bugs::bug(email)" -text "[trans sendemail] ("
	label $w.c1.text -text "[trans cagreement]" -fg #0000FF -cursor hand1
	label $w.c1.end -text ")"

	checkbutton $w.c2 -text [trans ignoreerrors] -variable "::bugs::dont_give_bug_reports"
	button $w.f.b1 -text [trans report] -command "::bugs::report"
	button $w.f.b2 -text [trans ignore] -command "set ::bugs::closed_bug_window 1"
	button $w.f.b3 -text [trans save] -command "::bugs::save \[tk_getSaveFile -title \"Save Bug Report\" -parent $w\]"
	button $w.f.b4 -text [trans details] -command "::bugs::toggle_details"
	text $w.details -height 10 -width 10 -bg #FFFFFF
	$w.details insert 0.0 $info
	
	pack $w.msg -side top -expand 1 -anchor nw -padx 3m -pady 3m
	pack $w.desc_l -anchor nw
	pack $w.f.t -side left -fill both -expand yes
	pack $w.f.b1 $w.f.b2 $w.f.b3 $w.f.b4 -fill x
	pack $w.f -fill both -expand yes
	pack $w.c1.check $w.c1.text $w.c1.end -side left
	
	pack $w.c1 -expand yes -anchor w
	pack $w.c2 -expand yes -anchor w
	
	bind $w.f.t <KeyRelease> "::bugs::update_comment"
	
	bind $w.c1.text <Enter> "$w.c1.text configure -font sunderf"
	bind $w.c1.text <Leave> "$w.c1.text configure -font splainf"
	bind $w.c1.text <ButtonRelease> "my_focus \[::amsn::showHelpFileWindow AGREEMENT \"[trans cagreement]\"\]"
	
	
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
	#focus $w.f.b2
	focus $w.f.t
	bind $w <<Escape>> "set ::bugs::closed_bug_window 1;destroy $w"
	
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
    
    proc toggle_details { } {
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
		catch {file delete $datafile}
		
		return $token
    }
    
    proc report { } {
	global HOME2
	variable w
	if {$::bugs::bug(comment)==""} {
	    if {[tk_messageBox -type okcancel -message [trans bugnocomment]]=="cancel"} {
		return
	    }
	}
	::bugs::save [file join $HOME2 bugreport.amsn]
	$w.f.b1 configure -text [trans reporting] -state disabled
	
	#bugs::post {url field type file {params {}} {headers {}}}
	set lang [::config::getGlobalKey language]
	if { [catch {set token [bugs::post "$::weburl/bugs/report.php?lang=$lang" [file join $HOME2 bugreport.amsn]]}] == 0} {
	    upvar #0 $token state
	    set message $state(body)
	} else {
	    set message [trans bugerror]
	}

	tk_messageBox -message "$message" -title [trans done] -type ok
	
	$w.f.b1 configure -text [trans done] -state active -command "set ::bugs::closed_bug_window 1"
    }
}

proc privacy { str } {
    regsub -all {[A-Za-z0-9._-]{3}@[A-Za-z0-9.-]+} $str {xxx@sad-amsn-user.com} str
    #take care of url encoded ones 
    regsub -all {[A-Za-z0-9._-]{3}%40[A-Za-z0-9.-]+} $str {xxx%40sad-amsn-user.com} str
    return $str
}

proc htmlentities {str} {
    regsub -all & $str {\&amp;} str
    regsub -all {\<} $str {\&lt;} str
    regsub -all {\>} $str {\&gt;} str
    regsub -all {\"} $str {\&quot;} str
    regsub -all {\'} $str {\&apos;} str
    return $str
}

