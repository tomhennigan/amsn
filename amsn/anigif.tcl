# AniGif Package written in pure Tcl/Tk
#
# anigif.tcl v1.3 2002-09-09 (c) 2001-2002 Ryan Casey
#
# AniGif is distributed under the same license as Tcl/Tk.  As of
# AniGif 1.3, this license is applicable to all previous versions.
#
# ###############################  USAGE  #################################
#
#  ::anigif::anigif FILENAME WIDGET INDEX
#    FILENAME: appropriate path and file to use for the animated gif
#    WIDGET:   a label widget to place the animated gif into
#    DELAY:    how long to wait before loading next image (Default: 100ms)
#    INDEX:    what image to begin on (first image is 0) (Default: 0)
#
#  ::anigif::stop WIDGET
#  ::anigif::restart WIDGET INDEX
#    INDEX:    defaults to next index in loop
#  ::anigif::destroy WIDGET
#
#  NOTES:
#    There is currently a -zoom and -subsample hack to keep transparency.
#    Anigif does not handle interlaced gifs properly.  The image will look
#      distorted.
#    A delay of 0 renders as fast as possible, per the GIF specification.
#      This is currently set to 40 ms to approximate the IE default.
#    If you experience a problem with a compressed gif, try uncompressing
#      it. Search the web for gifsicle.    
#
# ############################## HISTORY #################################
#
#  1.3: Fixed error in disposal flag handling.
#       Added handling for non-valid comment/graphic blocks.
#       Searches for actual loop control block.  If it extists, loops.
#       Added more comments.
#  1.2: Now handles single playthrough gifs or gifs with partial images
#       Fixed bug in delay time (unsigned int was being treated as signed)
#  1.1: Reads default timing instead of 100 ms or user-defined.
#       You can no longer set the delay manually.
#  1.0: Moved all anigif variables to the anigif namespace
#  0.9: Initial release
# 

namespace eval anigif {

    proc anigif2 {fname {idx 0}} {
	if { ![info exists ::anigif::${fname}(images)] } {
	    #Cleanup
	    #???
	    #destroy $w
	    return
	} else {
	    catch {
		set list [set ::anigif::${fname}(images)]
		set delay [set ::anigif::${fname}(delay)]
	    }
	    if { ![info exists ::anigif::${fname}(images)] } { return }

	    if { $idx >= [llength $list]  } {
		set idx 0
		if { [set ::anigif::${fname}(repeat)] == 0} {
		    # Non-repeating GIF
		    ::anigif::stop $fname
		    return
		}
	    } 

	    set dispflag [lindex [set ::anigif::${fname}(disposal)] $idx ]
	   
	    #	    status_log "$fname\n" 
	    switch "$dispflag" {
		"000" {
		    # Do nothing
		}
		"001" {
		    # Do not dispose
		}
		"100" {
		    # Restore to background
		    [set ::anigif::${fname}(curimage)] blank
		    [set ::anigif::${fname}(curimage)] copy [lindex $list 0] -subsample 2 2 
		}
		"101" {
		    # Restore to previous 
		    [set ::anigif::${fname}(curimage)] blank
		    [set ::anigif::${fname}(curimage)] copy  [lindex $list 0] -subsample 2 2 
		}
		
		
		default { status_log "no match: $dispflag\n" }
	    }
	    [set ::anigif::${fname}(curimage)] blank
	    [set ::anigif::${fname}(curimage)] copy [lindex $list 0] -subsample 2 2 
	    for { set i 1 } { $i <= $idx } { incr i } {
		[set ::anigif::${fname}(curimage)] copy [lindex $list $i] -subsample 2 2 
	    }
	    
#	    [set ::anigif::${fname}(previmage)] copy [set ::anigif::${fname}(curimage)] -compositingrule set
#	    [set ::anigif::${fname}(curimage)] copy [lindex $list $idx] -subsample 2 2 
	    
	    if { [lindex $delay $idx] == 0 } {
		::anigif::stop $fname
		return
	    }
	    update
	    if { [info exists ::anigif::${fname}(count)] } {
		after [lindex $delay $idx] "::anigif::anigif2 $fname [expr {$idx + 1}]"
		set ::anigif::${fname}(idx) [incr idx]
	    }
	}
    }

    proc anigif {fnam w {idx 0}} {
	set n 0
	set images {}
	set delay {}
	set fname [string map { " " "_" "/" "_" "." "_" } $fnam]


	# If the file is already opened 
	if { [info exists ::anigif::${fname}(count)] && [set ::anigif::${fname}(count)] != 0 } {

	    set ::anigif::${fname}(count) [expr {[set ::anigif::${fname}(count)] + 1}]
	    set ::anigif::${w}(fname) $fname
	    $w configure -image [set ::anigif::${fname}(curimage)]

	    return
	} else {
	    set ::anigif::${fname}(count) 1
	}

	set fin [open $fnam r]
	fconfigure $fin -translation binary
	set data [read $fin [file size $fnam]]
	close $fin

	# Find Loop Record
	set start [string first "\x21\xFF\x0B" $data]

	if {$start < 0} {
	    set repeat 0
	} else {
	    set repeat 1
	}

	# Find Control Records
	set start [string first "\x21\xF9\x04" $data]
	while {![catch "image create photo xpic$n$fname \
      -file  \"${fnam}\" \
      -format \{gif89 -index $n\}"] } {
	    set stop [string first "\x00" $data [expr {$start + 1}]]
	    if {$stop < $start} {
		break
	    }
	    set record [string range $data $start $stop]
	    binary scan $record @4c1 thisdelay
	    if {[info exists thisdelay]} {

		# Change to unsigned integer
		set thisdelay [expr {$thisdelay & 0xFF}];

		binary scan $record @2b3b3b1b1 -> disposalval userinput transflag

		lappend images pic$n$fname
		image create photo pic$n$fname
		pic$n$fname copy xpic$n$fname -zoom 2 2
		image delete xpic$n$fname
		lappend disposal $disposalval

		# Convert hundreths to thousandths for after
		set thisdelay [expr {$thisdelay * 10}]

		# If 0, set to fastest (25 ms min to seem to match browser default)
		if {$thisdelay == 0} {set thisdelay 40}

		lappend delay $thisdelay
		unset thisdelay

		incr n
	    }

	    if {($start >= 0) && ($stop >= 0)} {
		set start [string first "\x21\xF9\x04" $data [expr {$stop + 1}]]
	    } else {
		break
	    }
	}

	# Save the filename of the animated gif to be able to check wheter the pics
	# must be destroyed along with the widget
	set ::anigif::${w}(fname) $fname

	# Saving settings for this file
	set ::anigif::${fname}(repeat) $repeat
	set ::anigif::${fname}(delay) $delay
	set ::anigif::${fname}(disposal) $disposal
	set ::anigif::${fname}(images) $images


	set ::anigif::${fname}(curimage) [image create photo]
	[set ::anigif::${fname}(curimage)] blank
	set ::anigif::${fname}(previmage) [image create photo]
	[set ::anigif::${fname}(curimage)] copy pic0${fname} -subsample 2 2
	[set ::anigif::${fname}(previmage)] copy [set ::anigif::${fname}(curimage)]
	$w configure -image [set ::anigif::${fname}(curimage)]


	anigif2 $fname $idx

    }

    proc destroy {w} {

	catch { 
	    if { ![info exists ::anigif::${w}] } {
		return
	    }
	    set fname [set ::anigif::${w}(fname)]
 
	    if { [expr {[set ::anigif::${fname}(count)] - 1}]} {
		set ::anigif::${fname}(count) [expr {[set ::anigif::${fname}(count)] - 1}]
		unset ::anigif::${w}
		
	    } else {
		image delete [set ::anigif::${fname}(curimage)]
		foreach imagename [set  ::anigif::${fname}(images)] {
		    image delete $imagename
		}

		foreach timer [after info] {
		    if { [lsearch  [lindex [after info $timer] 0] $fname ] != -1 } {
			after cancel $timer
		    }
		}

		unset ::anigif::${w}
		unset ::anigif::${fname}
	
	    } 
	    
	} 

    } 

    proc stop { fname } {
	foreach timer [after info] {
	    if { [lsearch  [lindex [after info $timer] 0] $fname ] != -1 } {
		after cancel $timer
	    }
	}
    }

}

package provide anigif 1.3

