
proc CreatePNG { filename } {
    global pngreader

    if { ![info exists pngreader] } {
	set img 0 
	set pngreader(images) 0
    } else {	
	incr pngreader(images)
	set img $pngreader(images)
    }

    set fd [open $filename "r" ]
    fconfigure $fd -translation binary
    set pngreader(${img}_data) [read $fd]
    close $fd

    ReadPNG $img

    if { $pngreader(${img}_status) != "END" } {
	return -1
    }

    foreach name [array names pngreader] {
	if { [string match $name "img_*"] } {
	    unset pngreader($name)
	}
    }

    return [image create photo -data $pngreader(${img}_bitmap)]


}



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

proc ReadChunk { img } {
    global pngreader

    set data $pngreader(${img}_data)
    set offset $pngreader(${img}_offset)

    binary scan [string range $data $offset [expr $offset + 3]] I length 
    set type [string range $data [expr $offset + 4] [expr $offset + 7]]
    binary scan [string range $data [expr $offset + 8 + $length] [expr $offset + 11 + $length]] I CRC
    set chunk [string range $data [expr $offset + 8] [expr $offset + 7 + $length]]

    status_log "Got chunk of type : $type with length $length  of CRC $CRC\nChunk is : \n$chunk\n\n\n"

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
	binary scan [string range $chunk [expr $offset * 3] [expr ($offset * 3) + 3]] ccc red green blue
	set pngreader(${img}_palette_${offset}) [list $red $green $blue]
    }
    
    set pngreader(${img}_status) "IDAT"
    set pngreader(${img}_IDAT) ""

}

proc ProcessIDAT { img chunk } {
    global pngreader

    set pngreader(${img}_IDAT) "$pngreader(${img}_IDAT)$chunk"

}

proc ProcessIEND { img chunk } {
    global pngreader

    status_log "Found an IEND chunk, ending data parsing\n"

    if { $chunk != "" } {
	status_log "Chunk is not empty, returning an error\n"
	set pngreader(${img}_status) "ERROR"
	unset pngreader(${img}_data)
	unset pngreader(${img}_IDAT)
    } else {
	status_log "Finished parsing PNG file with success\nStarting conversion of data\n" red
	unset pngreader(${img}_data)

	uncompressIDAT $img

	unset pngreader(${img}_IDAT)
	if { $pngreader(${img}_status) != "ERROR" } {
	    FilterIDAT $img
	}
	unset pngreader(${img}_zlib)

	set idx 0 
	while { [info exists pngreader(${img}_palette_$idx)] } {
	    unset pngreader(${img}_palette_$idx)
	}
	
	if { $pngreader(${img}_status) != "ERROR" } {
	    set pngreader(${img}_status) "END"
	}
    }


}

proc uncompressIDAT { img } {
    global pngreader

    set zlib $pngreader(${img}_IDAT)

    status_log "original data : [string length $zlib]\n"

    set pngreader(${img}_zlib) ""

    binary scan [string range $zlib 0 1] B8B8 CMF FLG
    status_log "CMF = $CMF\nFLG = $FLG\n" red

    if { $CMF != "01111000" || [string range $FLG 2 2] != 0 } {
	status_log "Compression of the zlib data is in an unknown format\n" error
	set pngreader(${img}_status) "ERROR"
	return
    }

    binary scan [string range $zlib 0 1] S FCHECK
    status_log "FCHECK is such that CMF_FLG = $FCHECK\n" red
    if { [expr $FCHECK % 31 ] != 0 } {
	status_log "FCHECK is not a multiple of 31, corrupted data\n"
	set pngreader(${img}_status) "ERROR"
	return
    }


    set bfinal  "0"
    set idx 2

    while { $bfinal != "1" } {

	binary scan [string range $zlib $idx $idx] B3 header
	status_log "Got header : $header\n"
	set bfinal [string range $header 0 0]
	set btype [string range $header 1 2]
	set idx [expr $idx + 3]

	status_log "Reading compressed block, with compression type $btype and final bloc = $bfinal\n"
	switch $btype {
	    "00" {
		if { [expr $idx % 8] != 0 } {
		    set idx [expr $idx + 8 - ( $idx % 8)]
		}
		binary scan [string range $zlib $idx [expr $idx + 3]] SS len nlen
		if { $nlen != [expr - $len - 1] } {
		    status_log "Len and NLen does not match : $len --- $nlen\n"
		    set pngreader(${img}_status) "ERROR"
		    return
		}
		status_log "Reading uncompressed block with length $len from index $idx to [expr $idx + 3 + $len]\n"
		set pngreader(${img}_zlib) "$pngreader(${img}_zlib)[string range $zlib [expr $idx + 4] [expr $idx + 3 + $len]]"

	    }
	    "01" {
		status_log "Got Huffman's compressed block, skipping\n"
	    }
	    "10" {
		status_log "Got Huffman's dynamic compression block, skipping\n"
	    }
	    "11" {
		status_log "Got reserved work 11 for compression type : error\n" error
		set pngreader(${img}_status) "ERROR"
		return
	    }
	}

    }


    status_log "Finished reading and \"uncompressing\" zlib blocks of data\n" blue


}


proc FilterIDAT { img } {
    global pngreader

    set data $pngreader(${img}_zlib)

    status_log "Filtering data :\n$data\n, size : [string length $data]\n"




}

proc test { } {
    CreatePNG ~/.amsn/gklzyffe_hotmail_com/displaypic/cache/05934554a62565262714736497c4a466c6d45644a45647342496b6d3.png
}