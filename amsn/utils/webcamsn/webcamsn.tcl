#!/usr/bin/wish


proc GetDataSize { data } {
    binary scan $data ssssiiii h_size w h r1 p_size fcc r2 r3

    binary scan "\x30\x32\x4C\x4D" I r_fcc

    if { [string length $data] < 24 } {
	return 0
    }

    if { $h_size != 24 } {
	puts "invalid - $h_size"
	return -1
    }
    if { $fcc != $r_fcc} {
	puts "fcc invalide - $fcc - $r_fcc"
	return -1
    }
    #puts "resolution : $w x $h - $h_size $p_size -  frame : $::frame - data size : [string length $data]"

    if { $::frame == 271 } {
	set fd [open khra w]
	fconfigure $fd -encoding binary -translation binary	
	puts $fd $data
	close $fd
    }

    return [expr $h_size + $p_size]

}

proc DecodeFile { filename } {

     if { ![file readable $filename] } { error "Can't find the specified file" }
    
    set debug [open debug.log w]
    fconfigure $debug -buffering none
    puts $debug "Start :\n"
    set fd [open $filename]
    fconfigure $fd -encoding binary -translation binary
    set data [read $fd]
    close $fd
    
    puts $debug "Creating widgets :\n"

    set img [image create photo]

    catch {destroy .webcam}
    toplevel .webcam
    label .webcam.l -image $img
    pack .webcam.l
    set ::sem 0
    set ::frame 0
    puts $debug "Creating decoder"
    set decoder [::Webcamsn::NewDecoder]

    puts $debug "$decoder - [::Webcamsn::NumberOfOpenCodecs]"

    while { [set size [GetDataSize $data] ] > 0 } {
	puts $debug "decoding frame [::Webcamsn::NbFrames $decoder]"
	if { ![winfo exists .webcam] } {
		break
	}
	::Webcamsn::Decode $decoder $img $data
	set data [string range $data $size end]
	after 10 "incr ::sem"
	tkwait variable ::sem
	incr ::frame
    }
    puts $debug "$decoder - [::Webcamsn::NumberOfOpenCodecs]"
    ::Webcamsn::Close $decoder
    puts $debug "$decoder - [::Webcamsn::NumberOfOpenCodecs]"

}


proc Switch { cmd1 time1 cmd2 time2 } {
    eval $cmd1
    after $time1 "Switch $cmd2 $time2 $cmd1 $time1"
}


 proc EncodeToFile { filename } {
    
     if { $::tkcx == 0 } { error "Unable to find TkCximage" }
     if { $::file_to_test == "" || ![file readable $::file_to_test] } { error "Can't find movie2.gif" }

     set debug [open debug.log w]
     fconfigure $debug -buffering none
     puts $debug "Start :\n"
     set fd [open $filename w]
     fconfigure $fd -encoding binary -translation binary -buffering none

     puts $debug "Creating widgets :\n"

     set img [image create photo -file $::file_to_test]
     #Switch ::CxImage::DisableAnimated 1000 ::CxImage::EnableAnimated 1000

     catch {destroy .webcam}
     toplevel .webcam
     label .webcam.l -image $img
     pack .webcam.l
     set ::sem 0
     set ::frame 0
     puts $debug "creating encoder"
     set encoder [::Webcamsn::NewEncoder LOW]

     puts $debug "$encoder - [::Webcamsn::NumberOfOpenCodecs]"

     for {set i 0 } { $i < 1000 } { incr i} {
        if { ![winfo exists .webcam] } {
                break 
        }

	 puts $debug "encoding frame [::Webcamsn::NbFrames $encoder]"
 	if { [catch {set data [::Webcamsn::Encode $encoder $img]} res] } {
 	    puts $debug "ERROR : $res\n"
 	} else {
 	    set header "[binary format ssssi 24 160 120 0 [string length $data]]"
	    set header "$header\x4D\x4C\x32\x30\x00\x00\x00\x00\x00\x00\x00\x00"

 	    puts -nonewline $fd $header
 	    puts -nonewline $fd $data
 	}

 	after 10 "incr ::sem"
 	tkwait variable ::sem
 	incr ::frame
     }

     close $fd

     puts $debug "$encoder - [::Webcamsn::NumberOfOpenCodecs]"
     ::Webcamsn::Close $encoder
     puts $debug "$encoder - [::Webcamsn::NumberOfOpenCodecs]"

 }

proc EncodeFromWebcam { filename } {

    if { $::qttcl == 0 } { error "unable to find QuickTimeTcl"  }

    set debug [open debug.log w]
    fconfigure $debug -buffering none
    puts $debug "Start :\n"
    set fd [open $filename w]
    fconfigure $fd -encoding binary -translation binary -buffering none

    puts $debug "Creating widgets and sequencer :\n"

    set img [image create photo]
    seqgrabber .seq

    catch {destroy .webcam}
    toplevel .webcam
    label .webcam.l -image $img
    pack .webcam.l
    set ::sem 0
    set ::frame 0
    puts $debug "Creating encoder"
    set encoder [::Webcamsn::NewEncoder LOW]

    puts $debug "$encoder - [::Webcamsn::NumberOfOpenCodecs]"

    for {set i 0 } { $i < 1000 } { incr i} {
        if { ![winfo exists .webcam] } {
                break 
        }

	puts $debug "encoding frame [::Webcamsn::NbFrames $encoder]"
	.seq picture $img
	if { [catch {set data [::Webcamsn::Encode $encoder $img]} res] } {
	    puts $debug "ERROR : $res\n"
	} else {
	    set header "[binary format ssssi 24 160 120 0 [string length $data]]"
	    set header "$header\x4D\x4C\x32\x30\x00\x00\x00\x00\x00\x00\x00\x00"

	    puts -nonewline $fd $header
	    puts -nonewline $fd $data
	}

	after 10 "incr ::sem"
	tkwait variable ::sem
	incr ::frame
    }

    close $fd

    puts $debug "$encoder - [::Webcamsn::NumberOfOpenCodecs]"
    ::Webcamsn::Close $encoder
    puts $debug "$encoder - [::Webcamsn::NumberOfOpenCodecs]"

}

lappend ::auto_path [pwd]

if { [catch { package require webcamsn}] } {
    error "Can't load Webcamsn package"
}

set ::qttcl 1
set ::tkcx 1

catch {console show}


if { [catch { package require QuickTimeTcl} ] } {
    set ::qttcl 0
}
if { [catch { package require TkCximage }] } {
    set ::tkcx 0
}

if { $::qttcl == 0 && $::tkcx == 0 } {
    error "You must have at least TkCximage OR QuickTimeTcl to test the application"
}


proc GetMovieFile { } {
        foreach lib [info loaded] {
                if { [lindex $lib 1] == "Tkcximage" } {
                        set dir [file dirname [lindex $lib 0]]
			return "[file join $dir demos movie2.gif]"
	
                }
        }
	return ""
}

set ::file_to_test [GetMovieFile]

