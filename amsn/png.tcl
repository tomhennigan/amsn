###########################################
# CreatePNG { filename }
# Parses the PNG file and returns an image containing the data
#

package require tclzlib 
proc CreatePNG { filename } {
    global pngreader
    
    

    if { ![info exists pngreader] } {
	set img 0 
	set pngreader(images) 0
    } else {	
	incr pngreader(images)
	set img $pngreader(images)
    }

    status_log "Opening file for reading, img = $img\n"

     set fd [open $filename "r" ]
     fconfigure $fd -translation binary
     set pngreader(${img}_data) [read $fd]
     close $fd

    status_log "Finished reading file, now parsing\n"

    ReadPNG $img

    if { $pngreader(${img}_status) != "END" } {
	return -1
    }

    set im [image create photo -width $pngreader(${img}_width) -height $pngreader(${img}_height)]
    $im put "$pngreader(${img}_bitmap)"

  
    foreach name [array names pngreader] {
	if { [string match "${img}*" $name] } {
	    unset pngreader($name)
	}
    }
    return $im


}

########################################
# ReadPNG { img }
# Reads the PNG file, from the header until the last 
# chuck.
# The img variable is an ID to the image processed
#

proc ReadPNG { img} {
    global pngreader

    status_log "Parsing PNG file : $img\n"

    ReadHeader $img

    while { $pngreader(${img}_status) != "END" && $pngreader(${img}_status) != "ERROR" } {
	status_log "Reading next chunk, status is at $pngreader(${img}_status)\n" blue
	ReadChunk  $img
    }

    status_log "End of PNG parsing, finished with status code : $pngreader(${img}_status)\n" blue
    
}

########################################
# ReadHeader { img }
# Reads the header and initializes some variables
#

proc ReadHeader { img } {
    global pngreader

    if { [string range $pngreader(${img}_data) 0 7] == "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A" } {
	status_log "Header is correct\n"
	set pngreader(${img}_status) "HDR"
	set pngreader(${img}_offset) 8
    } else {
	status_log "Incorrect header\nGot [string range $pngreader(${img}_data) 0 7] instead of \x89\x50\x4E\x47\x0D\x0A\x1A\x0A" red
	set pngreader(${img}_status) "ERROR"
    }
}

############################################
# ReadChunk { img }
# Reads every chunk and calls the correct function
# to process the associated chunk.
#

proc ReadChunk { img } {
    global pngreader

    set data $pngreader(${img}_data)
    set offset $pngreader(${img}_offset)

    binary scan [string range $data $offset [expr $offset + 3]] I length 
    set type [string range $data [expr $offset + 4] [expr $offset + 7]]
    binary scan [string range $data [expr $offset + 8 + $length] [expr $offset + 11 + $length]] I CRC
    set chunk [string range $data [expr $offset + 8] [expr $offset + 7 + $length]]

    status_log "Got chunk of type : $type with length $length  of CRC $CRC\n"

    switch $type {
 	"IHDR" {
 	    ProcessIHDR $img $chunk
 	}
 	"PLTE" {
 	    ProcessPLTE $img $chunk
 	}
 	"IDAT" {
 	    ProcessIDAT $img $chunk
 	}
	"IEND" {
	    ProcessIEND $img $chunk
	}
 	default {
 	    status_log "IGNORING Ancillary chunk of $type\n" blue
 	}
    }

    set pngreader(${img}_offset) [expr $offset + 12 + $length]


}


#########################################
# ProcessIHDR { img chunk }
# Processes the IHDR chunk, gets image properties and 
# verifies everything before changing the
# image processing status
#

proc ProcessIHDR { img chunk } {
    global pngreader

    if { $pngreader(${img}_status) != "HDR" } {
	status_log "Processing Header twice\n" error
	set pngreader(${img}_status) "ERROR"
	return 
    }

    binary scan $chunk IIccccc pngreader(${img}_width) pngreader(${img}_height) pngreader(${img}_depth) pngreader(${img}_colors) pngreader(${img}_compression) pngreader(${img}_filter) pngreader(${img}_interlace)

    status_log "Got header with : \nwidth = $pngreader(${img}_width) \nheight = $pngreader(${img}_height)\n depth = $pngreader(${img}_depth)\n colors = $pngreader(${img}_colors)\n compression =  $pngreader(${img}_compression)\n Filter = $pngreader(${img}_filter)\n interlace mode = $pngreader(${img}_interlace)\n\n" red

    if { $pngreader(${img}_compression) != 0 || $pngreader(${img}_filter) != 0 && $pngreader(${img}_interlace) != 0 } {
	status_log "Got PNG with either compression or filter or interlace mode different from zero\naborting" error
	set pngreader(${img}_status) "ERROR"
	return
    }
    set  pngreader(${img}_bitmap) ""
    if {  $pngreader(${img}_colors) == 3 } {
	set pngreader(${img}_status) "PALETTE"
    } else {
	set pngreader(${img}_status) "BEGIN"
	set pngreader(${img}_IDAT) ""
    }

}


##############################################
# ProcessPLTE { img  chunk }
# Processes the PLTE chunk, reads every palette info
# and stores it in the appropriate variable.
#

proc ProcessPLTE { img chunk } {
    global pngreader

    if { ($pngreader(${img}_status) != "PALETTE" && $pngreader(${img}_status) != "BEGIN" ) || ([string length $chunk] % 3 != 0)} {
	status_log "Error processing PLTE chunk\n" error
	set pngreader(${img}_status) "ERROR"
	return
    } 

    set palettes [expr [string length $chunk] / 3]
    if { $palettes > [expr pow(2, $pngreader(${img}_depth) )] } {
	status_log "Error processing PLTE chunk : Too many palette entries for bit depth\n" error
	set pngreader(${img}_status) "ERROR"
	return
    }
    
    for {set offset 0} {$offset < $palettes } { incr offset  } {
	binary scan [string range $chunk [expr $offset * 3] [expr ($offset * 3) + 2]] H* col
	set pngreader(${img}_palette_${offset}) $col
    }
    
    set pngreader(${img}_status) "IDAT"
    set pngreader(${img}_IDAT) ""

}

########################################
# ProcessIDAT { img chunk }
# Processes the IDAT chunk containing the data
# it just appends all IDAT chunks together
#

proc ProcessIDAT { img chunk } {
    global pngreader

    set pngreader(${img}_IDAT) "$pngreader(${img}_IDAT)$chunk"

}

#######################################
# ProcessIEND { img chunk } 
# Processes the IEND chunk, which means an end of file
# it calls the procs for uncompressing, then filtering
# before returning the bitmap
#

proc ProcessIEND { img chunk } {
    global pngreader HOME

    status_log "Found an IEND chunk, ending data parsing\n"

    if { $chunk != "" } {
	status_log "Chunk is not empty, returning an error\n"
	set pngreader(${img}_status) "ERROR"
	unset pngreader(${img}_data)
	unset pngreader(${img}_IDAT)
    } else {
	status_log "Finished parsing PNG file with success\nStarting conversion of data\n" red
	unset pngreader(${img}_data)

	status_log "Opening file  [file join $HOME displaypic zlibtemp.dat] for writing\n"
	set fd [open [file join $HOME displaypic zlibtemp.dat] "w"]
	fconfigure $fd -translation binary

	puts $fd "$pngreader(${img}_IDAT)"
	close $fd
	
	unset pngreader(${img}_IDAT)

	status_log "Stored data\nOpening for reading\n"

	set fd [open [file join $HOME displaypic zlibtemp.dat] "r"]
	fconfigure $fd -translation binary

	set pngreader(${img}_zlib) [::tclzlib::deflate $fd]
	status_log "fd = $fd\n\n\n"
	close $fd

	set time [clock clicks]
	if { $pngreader(${img}_status) != "ERROR" } {
	    FilterIDAT $img
	}
	unset pngreader(${img}_zlib)
	status_log "Time for filtering : [expr [clock clicks] - $time]\n"
	
	if { $pngreader(${img}_status) != "ERROR" } {
	    set pngreader(${img}_status) "END"
	}
    }


}


###################################################
# FilterIDAT { img }
# filters the uncompressed data using the PNG filtering
# specifications
#

proc FilterIDAT { img } {
    global pngreader
  
    set time [clock clicks]

    binary scan $pngreader(${img}_zlib) c*  data 
    set h $pngreader(${img}_height)
    set w [expr $pngreader(${img}_width) + 1]
    set pngreader(${img}_bitmap) [list]
    status_log "Filtering data of image $img\n"
    
    set idx -1

    set out ""


    status_log "time for the begining : [expr  [clock clicks] - $time]\n"

    foreach color $data {
	incr idx
	if { [expr $idx % $w] == 0 } {
	    if { $color != 0 } {
		status_log "Got Filter $color on index $idx -- Not yet supported SKIPPING\n" red
		set pngreader(${img}_status)  "ERROR" 
		return
	    }
	    if {$idx != 0 } {
		lappend pngreader(${img}_bitmap) $out
		set out ""
	    }
	    continue
	}
       
	set color [expr $color % 256]
	set out "${out} #$pngreader(${img}_palette_${color})"

    }

}


proc testpng { file } {
    reload_files
    source plugins/tclzlib/tclzlib.tcl


    set im [CreatePNG [::skin::GetSkinFile displaypic ${file}.png]] 
    if {$im != -1} {
	catch {destroy .test}
	toplevel .test 
	label .test.l -image $im
	pack .test.l
    }
}

proc testpng2 { file } {
    reload_files

    source msn/plugins/tclzlib/tclzlib.tcl

    set im [CreatePNG [::skin::GetSkinFile displaypic ${file}.png]] 
    if {$im != -1} {
	catch {destroy .test2}
	toplevel .test2
	label .test2.l -image $im
	pack .test2.l
    }
}

proc testpng3 { file } {
    reload_files

    set im [CreatePNG [::skin::GetSkinFile displaypic ${file}.png]] 
    if {$im != -1} {
	catch {destroy .test3}
	toplevel .test3
	label .test3.l -image $im
	pack .test3.l
    }
}
