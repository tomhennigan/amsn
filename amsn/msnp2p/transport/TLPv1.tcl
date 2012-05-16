namespace eval ::p2pv1::TLPFlag {

	set NAK 0x1
	set ACK 0x2
	set RAK 0x4
	set RST 0x8
	set FILE 0x10
	set EACH 0x20
	set CAN 0x40
	set ERR 0x80
	set KEY 0x100
	set CRYPT 0x200
	set UNKNOWN 0x1000000

}

namespace eval ::p2pv1 {

	snit::type TLPHeader {

		option -size 48
		option -header ""
		option -session_id 0
		option -blob_id 0
		option -blob_offset 0
		option -blob_size 0
		option -chunk_size 0
		option -flags 0
		option -dw1 0
		option -dw2 0
		option -qw1 0

		constructor { args } {

			#Gotta luv tcl
			$self configurelist $args
			$self configure -header [list $options(-session_id) $options(-blob_id) $options(-blob_offset) $options(-blob_size) $options(-chunk_size) $options(-flags) $options(-dw1) $options(-dw2) $options(-qw1)]

		}

		typemethod size { } {

			return 48

		}

		typemethod parse { data} {

			if { [string length $data] == 0 } { return [TLPHeader %AUTO%]}
			#set ret [binary scan $data iiwwiiiiw session_id blob_id blob_offset blob_size chunk_size flags dw1 dw2 qw1]
			set ret [binary scan $data iiiiiiiiiiw session_id blob_id cOffset1 cOffset2 cTotalDataSize1 cTotalDataSize2 chunk_size flags dw1 dw2 qw1]
			set blob_offset [int2word $cOffset1 $cOffset2]
			set blob_size [int2word $cTotalDataSize1 $cTotalDataSize2]
			
			return [TLPHeader %AUTO% -session_id $session_id -blob_id $blob_id -blob_offset $blob_offset -blob_size $blob_size -chunk_size $chunk_size -flags $flags -dw1 $dw1 -dw2 $dw2 -qw1 $qw1]

		}

		method toString { } {

			#set ret [binary format iiwwiiiiw $options(-session_id) $options(-blob_id) $options(-blob_offset) $options(-blob_size) $options(-chunk_size) $options(-flags) $options(-dw1) $options(-dw2) $options(-qw1)]
			set ret [binary format ii $options(-session_id) $options(-blob_id)]
			append ret [binword $options(-blob_offset)]
			append ret [binword $options(-blob_size)]
			append ret [binary format iiii $options(-chunk_size) $options(-flags) $options(-dw1) $options(-dw2)]
			append ret [binary format w $options(-qw1)]
			return $ret

		}

	}

	snit::type MessageChunk {

		option -header ""
		option -body ""
		option -application_id 0
		option -version 1

		constructor { args } {

			$self configurelist $args
			if { $options(-header) == "" } {
				set options(-header) [TLPHeader %AUTO%]
			}

		}

		destructor {

			catch {$options(-header) destroy}
			catch {$options(-body) destroy}

		}

		method id {} {

			return [$self get_field dw1]

		}

		method set_id { val } {

			$self set_field dw1 $val

		}

		method set_appid { val } {

			set options(-application_id) $val

		}

		method next_id {} {

			if { [expr { [$self id] + 1 }] == 2147483647 } {
				return 1
			}
			return [expr { [$self id] + 1 }]

		}

		method session_id {} {

			return [$self get_field session_id]

		}

		method blob_id {} {

			return [$self get_field blob_id]

		}

		method ack_id {} {

			return "[$self get_field blob_id][$self get_field dw1]"

		}

		method acked_id {} {

			return "[$self get_field dw1][$self get_field dw2]"

		}

		method size {} {

			return [$self get_field chunk_size]

		}

		method blob_size {} {

			return [$self get_field blob_size]

		}

		method is_control_chunk {} {

			return [expr {[$self get_field flags] & 0xCF}]

		}

		method is_ack_chunk {} {

			return [expr {[$self get_field flags] & $::p2pv1::TLPFlag::ACK}]

		}

		method is_nak_chunk {} {

			return [expr {[$self get_field flags] & $::p2pv1::TLPFlag::NAK}]

		}

		method is_nonce_chunk {} {

			return [expr {[$self get_field flags] & $::p2pv1::TLPFlag::KEY}]

		}

		method is_signaling_chunk {} {

			return [expr {[$self get_field session_id] == 0}]

		}

		method has_progressed {} {

			return [expr {[$self get_field flags] & $::p2pv1::TLPFlag::EACH}]

		}

		method set_data { data } {

			$self configure -body $data

			$self set_field chunk_size [string length $data]

			if { [$self get_field session_id] != 0 && [$self get_field blob_size] != 4 && $data != "\x00\x00\x00\x00" } {
				set flags [$self get_field flags]
				$self set_field flags [expr { $flags | $::p2pv1::TLPFlag::EACH } ]
				if { $options(-application_id) == $::p2p::ApplicationID::FILE_TRANSFER } {
					set flags [$self get_field flags]
					$self set_field flags [expr { $flags | $::p2pv1::TLPFlag::FILE } ]
				}
			}

		}

		method require_ack {} {

			if { [$self is_ack_chunk] } {
				return 0
			}

			# chunk_size + blob_offset == blob_size : chunk is over and we need to ACK
			if { [expr { [$self get_field chunk_size] + [$self get_field blob_offset]}] == [$self get_field blob_size] } {
				return 1
			}

			return 0 ;#Chunk not over yet

		}

		method create_ack_chunk {} {

			set flags $::p2pv1::TLPFlag::ACK
			if { [expr {[$self get_field flags] & $::p2pv1::TLPFlag::RAK}] } {
				set flags [expr {$flags | $::p2pv1::TLPFlag::RAK} ]
			}

			set blob_id [ ::p2p::generate_id ]
			set header [TLPHeader %AUTO% -session_id [$self get_field session_id] -blob_id $blob_id -flags $flags -dw1 [$self get_field blob_id] -dw2 [$self get_field dw1] -qw1 [$self get_field blob_size]]
			return [MessageChunk %AUTO% -header $header]

		}

		method get_nonce {} {

			set data [$options(-header) toString]
			set bnonce [string range $data 32 end]
			binary scan $bnonce H2H2H2H2H2H2H2H2H4H* n1 n2 n3 n4 n5 n6 n7 n8 n9 n10
			set nonce [string toupper "$n4$n3$n2$n1-$n6$n5-$n8$n7-$n9-$n10"]
			return $nonce

		}

		method set_nonce { nonce} {

			set nonce [string map { \{ "" \} "" } $nonce]
			set n1 [string range $nonce 6 7]
			set n2 [string range $nonce 4 5]
			set n3 [string range $nonce 2 3]
			set n4 [string range $nonce 0 1]
			set n5 [string range $nonce 11 12]
			set n6 [string range $nonce 9 10]
			set n7 [string range $nonce 16 17]
			set n8 [string range $nonce 14 15]
			set n9 [string range $nonce 19 22]
			set n10 [string range $nonce 24 end]

			set nonce [string toupper "$n4$n3$n2$n1-$n6$n5-$n8$n7-$n9-$n10"]

			set bnonce [binary format H2H2H2H2H2H2H2H2H4H* $n1 $n2 $n3 $n4 $n5 $n6 $n7 $n8 $n9 $n10]

			set bdw1 [binary format H2H2H2H2 $n1 $n2 $n3 $n4]
			binary scan $bdw1 iu dw1
			set bdw2 [binary format H2H2H2H2 $n5 $n6 $n7 $n8]
			binary scan $bdw2 iu dw2
			set bqw1 [binary format H4H* $n9 $n10]
			binary scan $bqw1 wu qw1
			$self set_field dw1 $dw1
			$self set_field dw2 $dw2
			$self set_field qw1 $qw1
			$self set_field flags [expr {[$self get_field flags] | $::p2pv1::TLPFlag::KEY}]

		}

		method get_field { arg } {

			return [[$self cget -header] cget -$arg]

		}

		method set_field { arg val } {

			return [[$self cget -header] configure -$arg $val]

		}

		typemethod createMsg { app_id session_id blob_id offset blob_size max_size sync csize} {

			set header [TLPHeader %AUTO%]
			$header configure -session_id $session_id
			$header configure -blob_id $blob_id
			$header configure -blob_offset $offset
			$header configure -blob_size $blob_size
			status_log "Blob size $blob_size, offset $offset, max size $max_size, size $csize"
			$header configure -chunk_size $csize
			return [MessageChunk %AUTO% -header $header -application_id $app_id]

		}

		typemethod parse { data} {

			set header [TLPHeader parse [string range $data 0 48]]
			set chunk [MessageChunk %AUTO% -header $header -body [string range $data 48 end]]
			return $chunk

		}

		method toString { } {

			return "[$options(-header) toString]$options(-body)"

		}

	}

}
