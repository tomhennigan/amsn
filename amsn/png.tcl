###########################################
# CreatePNG { filename }
# Parses the PNG file and returns an image containing the data
#

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
    unset pngreader(${img}_bitmap)

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
	binary scan [string range $chunk [expr $offset * 3] [expr ($offset * 3) + 3]] ccc red green blue
	set pngreader(${img}_palette_${offset}) [list $red $green $blue]
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
	    incr idx
	}
	
	if { $pngreader(${img}_status) != "ERROR" } {
	    set pngreader(${img}_status) "END"
	}
    }


}

#############################################
# uncompressIDAT { img }
# Uncompresses the data from the file using
# the zlib specifications
#

proc uncompressIDAT { img } {
    global pngreader

    set zlib $pngreader(${img}_IDAT)

    status_log "original data : [string length $zlib]\n"

    set pngreader(${img}_zlib) ""

    binary scan $zlib b* zlib

    status_log "binary : [string range $zlib 0 100]\n\n"

    set CMF [string range $zlib 0 7]
    set FLG [string range $zlib 8 15]
    status_log "CMF = $CMF\nFLG = $FLG\n" red

    if { [binary format b* $CMF] != "\x78" || [string range $FLG 5 5] != 0 } {
	status_log "Compression of the zlib data is in an unknown format\n" error
	set pngreader(${img}_status) "ERROR"
	return
    }

    binary scan [binary format b* [string range $zlib 0 15]] S FCHECK
    status_log "FCHECK is such that CMF_FLG = $FCHECK\n" red
    if { [expr $FCHECK % 31 ] != 0 } {
	status_log "FCHECK is not a multiple of 31, corrupted data\n"
	set pngreader(${img}_status) "ERROR"
	return
    }


    set bfinal  "0"
    set idx 16

    while { $bfinal != "1" } {

	
	set bfinal [string range $zlib $idx $idx]
	incr idx
        binary scan [binary format b* [string range $zlib $idx [expr $idx + 1]]] c btype
	set idx [expr $idx + 2]

	status_log "Reading compressed block, with compression type $btype and final bloc = $bfinal\n"
	if { $btype == 0 } {

	    if { [expr $idx % 8] != 0 } {
		set idx [expr $idx + 8 - ( $idx % 8)]
	    }

	    binary scan [string range $zlib $idx [expr $idx + 31]] SS len nlen 
	    set idx [expr $idx + 32]
	    if { [string map { "0" "1" } $bnlen] != $blen } {
		status_log "Len and NLen does not match : [string range $zlib [expr $idx -32] [expr $idx - 17]] --- [string range $zlib [expr $idx -16] [expr $idx - 1]]\nValues are $len and $nlen\n" red
		set pngreader(${img}_status) "ERROR"
		return
	    } else {
		binary scan [string range $zlib $idx [expr $idx + 1]] S len 
	    }
	    
	    status_log "Reading uncompressed block with length $len from index $idx to [expr $idx + 3 + $len]\n"
	    set pngreader(${img}_zlib) "$pngreader(${img}_zlib)[string range $zlib [expr $idx + 4] [expr $idx + 3 + $len]]"
	    set idx [expr $idx + 3 + $len]
	    
	} elseif { $btype == 3 } {
	    status_log "Got reserved word 11 for compression type : error\n" error
	    set pngreader(${img}_status) "ERROR"
	    return
	} else {
	    if { $btype == 2 } {
		status_log "Got Huffman's dynamic compression block, processing\n"
		
		binary scan [binary format b* [string range $zlib $idx [expr $idx + 4]]] c hlit
		set idx [expr $idx + 5]
		set hlit [expr $hlit + 257]
 		binary scan [binary format b* [string range $zlib $idx [expr $idx + 4]]] c hdist
		set idx [expr $idx + 5]
		incr hdist
 		binary scan [binary format b* [string range $zlib $idx [expr $idx + 3]]] c hclen
		set idx [expr $idx + 4]
		set hclen [expr $hclen + 4]

		status_log "Got hlit = $hlit \nhdist = $hdist\nhclen = $hclen\n"

		set codelengths [list 16 17 18 0 8 7 9 6 10 5 11 4 12 3 13 2 14 1 15]
		for { set i 0 } { $i < [expr $hclen * 3] } { set i [expr $i + 3]} {
		    binary scan [binary format b* [string range $zlib [expr $idx + $i] [expr $idx + $i + 2]]] c clen([lindex $codelengths [expr $i / 3]])
		}
		status_log "Read the codelengths, idx = $idx, new idx = [expr $idx + $i]\ncodelengths = \n[array get clen]\n"
		set idx [expr $idx + $i]

		set ohuffcodes [createcodes [array get clen] 7 18]
		foreach {name value } $ohuffcodes {
		    set huffcodes($name) $value
		}


		status_log "huffcodes = [array get huffcodes]\n"
		status_log "binary : [string range $zlib $idx  [expr $idx + 100]]\n\n"
		set inc 0
		set index 0
		while { $index < $hlit } {
		    set bin [string range $zlib $idx [expr $idx + $inc]]
		    if { [info exists huffcodes($bin)] } {
#			status_log "Found a length, for litteral value $index = $huffcodes($bin)\n"
			set idx [expr $idx + $inc + 1]
			if { $huffcodes($bin) < 16 } {
			    set litclen($index) $huffcodes($bin)
			    incr index
			} elseif { $huffcodes($bin) == 16 } {
			    set tocopy $litclen([expr $index - 1])
			    binary scan [binary format b* [string range $zlib $idx [expr $idx + 1]]] c length
			    set length [expr $length + 3]
			    incr idx
			    incr idx

#			    status_log "Copying value $tocopy into the next $length codes starting from $index\n"

			    for { set t 0 } { $t < $length } { incr t } {
#				status_log "Literal length $index, copied value : $tocopy\n"
				set litclen($index) $tocopy
				incr index
			    }

			} elseif { $huffcodes($bin) == 17 } {
			    binary scan [binary format b* [string range $zlib $idx [expr $idx + 2]]] c length
			    set length [expr $length + 3]
			    set idx [expr $idx + 3]
#			    status_log "Copying value 0 into the next $length codes starting from $index\n"
			    for { set t 0 } { $t < $length } { incr t } {
#				status_log "Literal length $index, copied value : 0\n"
				set litclen($index) 0
				incr index
			    }
			} else {
			    binary scan [binary format b* [string range $zlib $idx [expr $idx + 6]]] c length
			    set length [expr $length + 11]
			    set idx [expr $idx + 7]
#			    status_log "Copying value 0 into the next $length codes starting from $index\n"
			    for { set t 0 } { $t < $length } { incr t } {
#				status_log "Literal length $index, copied value : 0\n"
				set litclen($index) 0
				incr index
			    }
			    
			}
			set inc 0
		    } else {
			incr inc
			if { $inc > 7 } {
			    status_log "Erreur.. l'increment a depasse 7.. \ndump :\nindex = $idx - increment = $inc, index = $index, $hlit\nmemoire = [string range $zlib [expr $idx ] [expr $idx + $inc ]]\n"
			    set pngreader(${img}_status) "ERROR"
			    return
			}

		    }




		}

		set olitval [createcodes [array get litclen] 18 $hlit]
		foreach {name value } $olitval {
		    set litval($name) $value
		}

		set inc 0
		set index 0
		while { $index < $hdist } {
		    set bin [string range $zlib $idx [expr $idx + $inc]]
		    if { [info exists huffcodes($bin)] } {
#			status_log "Found a length, for distance value $index = $huffcodes($bin)\n"
			set idx [expr $idx + $inc + 1]
			if { $huffcodes($bin) < 16 } {
			    set distclen($index) $huffcodes($bin)
			    incr index
			} elseif { $huffcodes($bin) == 16 } {
			    set tocopy $distclen([expr $index - 1])
			    binary scan [binary format b* [string range $zlib $idx [expr $idx + 1]]] c length
			    set length [expr $length + 3]
			    incr idx
			    incr idx

#			    status_log "Copying value $tocopy into the next $length codes starting from $index\n"

			    for { set t 0 } { $t < $length } { incr t } {
#				status_log "distance length $index, copied value : $tocopy\n"
				set distclen($index) $tocopy
				incr index
			    }

			} elseif { $huffcodes($bin) == 17 } {
			    binary scan [binary format b* [string range $zlib $idx [expr $idx + 2]]] c length
			    set length [expr $length + 3]
			    set idx [expr $idx + 3]
#			    status_log "Copying value 0 into the next $length codes starting from $index\n"
			    for { set t 0 } { $t < $length } { incr t } {
#				status_log "distance length $index, copied value : 0\n"
				set distclen($index) 0
				incr index
			    }
			} else {
			    binary scan [binary format b* [string range $zlib $idx [expr $idx + 6]]] c length
			    set length [expr $length + 11]
			    set idx [expr $idx + 7]
#			    status_log "Copying value 0 into the next $length codes starting from $index\n"
			    for { set t 0 } { $t < $length } { incr t } {
#				status_log "distance length $index, copied value : 0\n"
				set distclen($index) 0
				incr index
			    }
			    
			}
			set inc 0
		    } else {
			incr inc
			if { $inc > 7 } {
			    status_log "Erreur.. l'increment a depasse 7.. \ndump :\nindex = $idx - increment = $inc, index = $index, $hlit\nmemoire = [string range $zlib [expr $idx ] [expr $idx + $inc ]]\n"
			    set pngreader(${img}_status) "ERROR"
			    return
			}

		    }
		}

		set odistval [createcodes [array get distclen] 18 $hdist]
		foreach {name value } $odistval {
		    set distval($name) $value
		}


	    } else {
		status_log "Got Huffman's compressed block, processing\n"
		set olitval [createcodes [fill_length lit] 18 287]
		foreach {name value } $olitval {
		    set litval($name) $value
		} 
		set odistval [createcodes [fill_length dist] 18 32]
		foreach {name value } $odistval {
		    set distval($name) $value
		} 

	    }

############################################################################################################

	    set inc 0
	    set index [string length $pngreader(${img}_zlib)]
	    for { } { 1 } { } {
		set bin [string range $zlib $idx [expr $idx + $inc]]
		if { [info exists litval($bin)] } {
		    set out $litval($bin)
#		    status_log "Found a length in index $index, for output = $out\n"
		    set idx [expr $idx + $inc + 1]
		    if { $out < 256 } {
			set pngreader(${img}_zlib) "$pngreader(${img}_zlib)[binary format c $out]"
			incr index
		    } elseif { $out == 256 } {
			status_log "FOUND END OF BLOCK\n" red
			break
		    } else {
#			status_log "Need to move backward distance $out -- processing\n"
			
			if { $out < 265 } {
			    set plus 0
			    set length [expr $out - 254]
			} elseif { $out == 285 } {
			    set plus 0
			    set length 258
			} elseif { $out > 264 && $out < 269 } {
			    binary scan [binary format b* [string range $zlib $idx  $idx]] c plus
			    incr idx
			    set length [expr (($out - 265) * 2) + $plus + 11]
			} elseif { $out > 268 && $out < 273} {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 1]]] c plus
			    incr idx
			    incr idx
			    set length [expr (($out - 269) * 4) + $plus + 19]
			} elseif { $out > 272 && $out < 277 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 2]]] c plus
			    set idx [expr $idx + 3]
			    set length [expr (($out - 273) * 8) + $plus + 35]
			} elseif { $out > 276 && $out < 281 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 3]]] c plus
			    set idx [expr $idx + 4]
			    set length [expr (($out - 277) * 16) + $plus + 67]
			} else {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 4]]] c plus
			    set idx [expr $idx + 5]
			    set length [expr (($out - 281) * 32) + $plus + 131]
			}

#			status_log "Found length $length with added $plus\n"

			set out2 -1 
			set inc2 0
			while { $out2 == -1 } {
			    set bin [string range $zlib $idx [expr $idx + $inc2]]
			    if { [info exists distval($bin)] } {
				set out2 $distval($bin)
#				status_log "Found a distance code  $out2\n"
				set idx [expr $idx + $inc2 + 1]
			    } else {
				incr inc2
				if { $inc2 > 15 } {
				    status_log "Erreur.. l'increment a depasse 15.. \ndump :\nindex = $idx - increment = $inc2, index = $index, $hlit\nmemoire = [string range $zlib [expr $idx ] [expr $idx + $inc2 ]]\n"
				    set pngreader(${img}_status) "ERROR"
				    status_log "\n\n$pngreader(${img}_zlib)\n\n\n\n"
				    return
				}
			    }
			}

			if { $out2 < 4 } {
			    set plus 0
			    set distance [expr $out2 + 1]
			} elseif { $out2 == 4 || $out2 == 5} {
			    binary scan [binary format b* [string range $zlib $idx  $idx]] c plus
			    incr idx
			    set distance [expr (($out2 - 4) * 2) + $plus + 5]
			} elseif { $out2 == 6 || $out2 == 7} {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 1]]] c plus
			    incr idx
			    incr idx 
			    set distance [expr (($out2 - 6) * 4) + $plus + 9]
			} elseif { $out2 == 8 || $out2 == 9 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 2]]] c plus
			    set idx [expr $idx + 3]
			    set distance [expr (($out2 - 8) * 8) + $plus + 17]
			} elseif { $out2 == 10 || $out2 == 11} {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 3]]] c plus
			    set idx [expr $idx + 4]
			    set distance [expr (($out2 - 10) * 16) + $plus + 33]
			} elseif {$out2 == 12 || $out2 == 13 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 4]]] c plus
			    set idx [expr $idx + 5]
			    set distance [expr (($out2 - 12) * 32) + $plus + 65]
			} elseif {$out2 == 14 || $out2 == 15 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 5]]] c plus
			    set idx [expr $idx + 6]
			    set distance [expr (($out2 - 14) * 64) + $plus + 129]
			} elseif {$out2 == 16 || $out2 == 17 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 6]]] c plus
			    set idx [expr $idx + 7]
			    set distance [expr (($out2 - 16) * 128) + $plus + 257]
			} elseif {$out2 == 18 || $out2 == 19 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 7]]] c plus
			    set idx [expr $idx + 8]
			    set distance [expr (($out2 - 18) * 256) + $plus + 513]
			} elseif {$out2 == 20 || $out2 == 21 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 8]]] c plus
			    set idx [expr $idx + 9]
			    set distance [expr (($out2 - 20) * 512) + $plus + 1025]
			} elseif {$out2 == 22 || $out2 == 23 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 9]]] c plus
			    set idx [expr $idx + 10]
			    set distance [expr (($out2 - 22) * 1024) + $plus + 2049]
			} elseif {$out2 == 24 || $out2 == 25 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 10]]] c plus
			    set idx [expr $idx + 11]
			    set distance [expr (($out2 - 24) * 2048) + $plus + 4097]
			} elseif {$out2 == 26 || $out2 == 27 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 11]]] c plus
			    set idx [expr $idx + 12]
			    set distance [expr (($out2 - 26) * 4096) + $plus + 8193]
			} elseif {$out2 == 28 || $out2 == 29 } {
			    binary scan [binary format b* [string range $zlib $idx  [expr $idx + 12]]] c plus
			    set idx [expr $idx + 13]
			    set distance [expr (($out2 - 28) * 8192) + $plus + 16385]
			}

#			status_log "Found distance $distance with added $plus\n"

			set tocopy [string range $pngreader(${img}_zlib) [expr $index - $distance] $index]
			while { [string length $tocopy] < $length } {
			    set tocopy "${tocopy}${tocopy}"
			}

			set tocopy [string range $tocopy 0 [expr $length -1]]
			set pngreader(${img}_zlib) "$pngreader(${img}_zlib)$tocopy"

			set index [expr $index + $length]

		    }
		    set inc 0
		} else {
		    incr inc
			if { $inc > 15 } {
			    status_log "Erreur.. l'increment a depasse 15.. \ndump :\nindex = $idx - increment = $inc, index = $index, $hlit\nmemoire = [string range $zlib [expr $idx ] [expr $idx + $inc ]]\n"
			    set pngreader(${img}_status) "ERROR"
			    status_log "\n\n$pngreader(${img}_zlib)\n\n\n\n"
			    return
			}
		}
	    }
	    
	}
	
    }


    status_log "Finished reading and uncompressing zlib blocks of data\n" blue


}

###################################################
# FilterIDAT { img }
# filters the uncompressed data using the PNG filtering
# specifications
#

proc FilterIDAT { img } {
    global pngreader

    set data $pngreader(${img}_zlib)
    set h $pngreader(${img}_height)
    set w $pngreader(${img}_width)
    set pngreader(${img}_bitmap) [list]
    status_log "Filtering data of image $img: size : [string length $data]\n"
    
    for { set i 0 } { $i < $h} { incr i } {
#	status_log "line $i : \n[string range $data [expr $i * 97] [expr ($i + 1) * 97]]\n"
	set out ""
	binary scan [string range $data [expr $i * ($w + 1 )] [expr $i * ($w + 1)]] c type
	
	switch -- $type {
	    "0" {
		status_log "On line $i, got filter 0\n"
		for { set j 1 } { $j <= $w } { incr j } {
		    binary scan [string range $data [expr $i * ($w + 1) + $j] [expr $i * ($w + 1) + $j]] c c
		    set c [expr $c % 256]
		    binary scan [binary format ccc [lindex $pngreader(${img}_palette_${c}) 0] [lindex $pngreader(${img}_palette_${c}) 1] [lindex $pngreader(${img}_palette_${c}) 2]] H2H2H2 R G B
		    set out "${out} #${R}${G}${B}"
		}
		lappend pngreader(${img}_bitmap) $out
	    } 
	    default {
		status_log "Got Filter $type on line $i -- Not yet supported SKIPPING\n" red
 		for { set j 1 } { $j <= $w } { incr j } {
 		    binary scan [string range $data [expr $i * ($w + 1) + $j] [expr $i * ($w + 1) + $j]] c c
 		    set c [expr $c % 256]
 		    binary scan [binary format ccc [lindex $pngreader(${img}_palette_${c}) 0] [lindex $pngreader(${img}_palette_${c}) 1] [lindex $pngreader(${img}_palette_${c}) 2]] H2H2H2 R G B
 		    set out "${out} #${R}${G}${B}"
 		}
		lappend pngreader(${img}_bitmap) $out
	    }
	}
    }

#    status_log "$pngreader(${img}_bitmap)\n"

}

proc testpng { file } {
    reload_files
#    CreatePNG ~/.amsn/gklzyffe_hotmail_com/displaypic/cache/05934554a62565262714736497c4a466c6d45644a45647342496b6d3.png
    catch {destroy .test}

    toplevel .test 
    label .test.l -image [CreatePNG [GetSkinFile displaypic ${file}.png]] 
    pack .test.l
}

proc createcodes { oclen maxbits maxcode } {

    foreach {name value } $oclen {
	set clen($name) $value
    }

#    set clen [list 3 3 3 3 3 2 4 4]

    foreach c [array names clen] {
	if {[info exists bl_count($clen($c))] } {
	    incr bl_count($clen($c))
	} else {
	    set bl_count($clen($c)) 1
	}
    }

    set code 0

    set bl_count(0) 0;
    status_log "bl_cout = [array get bl_count]\n"
    for { set bits 1 } { $bits <= $maxbits } {incr bits} {
	if { ![info exists bl_count([expr $bits - 1])] } {
	    set bl_count([expr $bits - 1]) 0
	}
	set code [expr ($code + $bl_count([expr $bits - 1])) << 1];
	set next_code($bits) $code;
    }
    
    status_log "code = $code\nnext_code = [array get next_code]\n"

    for {set n  0} { $n <= $maxcode} {incr n} {
	if { [info exists clen($n)]} {
	    set len $clen($n) 
	} else {
	    set len 0
	}
	if { $len != 0} {
	    binary scan [binary format s $next_code($len)] b$len bin
#	    status_log "$len = $next_code($len) = $bin = [invert $bin]\n"
	    set bin [invert $bin]
	    set codes($bin) $n
	    incr next_code($len)
	}
    }


    return [array get codes]

}


proc invert { bin } {

    set out ""
    
    for { set i [expr [string length $bin] - 1] } { $i >= 0 } { set i [expr $i - 1]} {
	set out "$out[string index $bin $i]"
    }

    return $out
}

proc fill_length { type } {
    set out ""
    switch $type { 
	"lit" {
	    for { set i 0 } { $i <= 287 } { incr i } {
		if { $i <= 143 } {
		    set out "$out $i 8"
		} elseif { $i <= 255 } {
		    set out "$out $i 9"
		} elseif { $i <= 279 } {
		    set out "$out $i 7"
		} else {
		    set out "$out $i 8"
		}
	    }
	}
	"dist" {
	    for { set i 0 } { $i <= 31} { incr i } {
		set out "$out $i 5"
	    }
	}
    }

    return $out
}