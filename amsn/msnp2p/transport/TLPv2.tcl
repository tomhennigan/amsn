namespace eval ::p2pv2::TLPFlag {

	set NONE 0x0
	set SYN 0x1
	set RAK 0x2

}

namespace eval ::p2pv2::TLPParamType {

	set PEER_INFO 0x1
	set ACK_SEQ 0x2
	set NAK_SEQ 0x3

}

namespace eval ::p2pv2::DLPType {

	set SLP 0x0
	set MSN_OBJECT 0x4
	set FILE_TRANSFER 0x6

}

namespace eval ::p2pv2::DLPParamType {

	set DATA_REMAINING 0x1

}

namespace eval ::p2pv2 {

	snit::type tlv {
		variable data -array {}
		variable formats -array {
			1 c
			2 S
			4 I
			8 W
		}

		constructor { args } {
		}

		method get { key {def ""} } {

			if { [info exists data($key)] } {
				return data($key)
			} else {
				return $def
			}

		}

		method upd { key val } {

			if { $val != "" } {
				set data($key) $val
			} else {
				array unset data $key
			}

		}

		method toString { } {
			set str ""
			foreach t [array names data] {
				set v $data($t)
				set l [string length $v]
				puts "T L V: [hexify $t] [hexify $l] [hexify $v]"
				set app_str [binary format cucu $t $l]
				append str "$app_str$v"
			}
			set padding [expr {4 - ([string length $str] % 4)}]
			if {$padding != 4} {
				append str [string repeat "\x00" $padding]
			}
			puts "Final tlv: [hexify $str]"
			return $str

		}

		method parse { scandata size } {

			set offset 0
			puts "We are going to scan a TLV"
			puts "Data is [hexify $scandata]"
			while { $offset < $size } {
				puts "okay..."
				set scanme [string range $scandata $offset end]
				binary scan $scanme bcu t l
				if { $t == 0 } {
					puts "breaking"
					break
				}
				set end [expr {$offset + 2 + $l}]
				if { $end > $size } {
					puts ":("
					#raise some error i guess
					return
				}
				set v [string range $scanme 2 [expr {2 + $l}]]
				puts "Wow, we scanned a TLV"
				puts "Scanned tlv [hexify $t] [hexify $l] [hexify $v]"
				set data($t) $v
				set offset $end
			}

		}

	}

	snit::type TLPHeader {

		option -op_code 0
		option -chunk_size 0
		option -chunk_id 0
		option -session_id 0
		option -data_type 0
		option -first 0
		option -package_number 0
		option -tlv ""
		option -data_tlv ""

		#$::p2pv2::TLPParamType::PEER_INFO 12
                #$::p2pv2::TLPParamType::ACK_SEQ 4
                #$::p2pv2::TLPParamType::NAK_SEQ 4

		typevariable TLPParamLength -array {
			0x1 12
			0x2 4
			0x3 4
		}
		typevariable DLPParamLength -array {
			0x1 8
		}

		constructor { args } {

			$self configurelist $args
			if { $options(-tlv) == "" } {
				set options(-tlv) [tlv %AUTO%]
			}
			if { $options(-data_tlv) == "" } {
				set options(-data_tlv) [tlv %AUTO%]
			}

		}

		destructor {

			catch {$options(-tlv) destroy}
			catch {$options(-data_tlv) destroy}

		}

		method size { } {
		
			set size [expr {8 + [string length [$options(-tlv) toString]]}]
			if { $options(-chunk_size) > 0 } {
				set size [expr {8 + [string length [$options(-data_tlv) toString]]}]
			}
			return $size
		}

		method data_size { } {
		
			set size $options(-chunk_size)
			if { $size > 0 } {
				set size [expr {8 + [string length [$options(-data_tlv) toString]]}]
			}
			return $size

		}

		method peer_info { } {
			return [$options(-tlv) get $::p2pv2::TLPParamType::PEER_INFO ""]
		}

		method set_peer_info { val } {
			if {$val != "" } {
				set len [set TLPParamLength($::p2pv2::TLPParamType::PEER_INFO)]
				if {[string length $val] != $len} {
					set val [string range $val[string repeat \x00 $len] 0 [expr {$len - 1}]]
				}
			}
			$options(-tlv) upd $::p2pv2::TLPParamType::PEER_INFO $val
		}

		method ack_seq { } {
			return [$options(-tlv) get $::p2pv2::TLPParamType::ACK_SEQ 0]
		}

		method set_ack_seq { val } {
			if {$val != "" } {
				set len [set TLPParamLength($::p2pv2::TLPParamType::ACK_SEQ)]
				if {[string length $val] != $len} {
					set val [string range $val[string repeat \x00 $len] 0 [expr {$len - 1}]]
					#wtf, I just puts this, $val was 59799 and now it became 5979... maybe we should binary format/scan it?
				}
			}
			$options(-tlv) upd $::p2pv2::TLPParamType::ACK_SEQ $val
		}

		method nak_seq { } {
			return [$options(-tlv) get $::p2pv2::TLPParamType::NAK_SEQ 0]
		}

		method set_nak_seq { val } {
			if {$val != "" } {
				set len [set TLPParamLength($::p2pv2::TLPParamType::NAK_SEQ)]
				if {[string length $val] != $len} {
					set val [string range $val[string repeat \x00 $len] 0 [expr {$len - 1}]]
				}
			}
			 $options(-tlv) upd $::p2pv2::TLPParamType::NAK_SEQ $val
		}

		method tf_combination { } {
			return [expr {$options(-data_type) | $options(-first)}]
		}

		method set_tf_combination { val } {
			set options(-first) [expr {$val & 0x01}]
			set options(-data_type) [expr {$val & 0xFE}]
		}

		method data_remaining { } {
			return [$options(-tlv) get $::p2pv2::DLPParamType::DATA_REMAINING 0]
		}

		method set_data_remaining { val } {
			if {$val != "" } {
				set len [set DLPParamLength($::p2pv2::DLPParamType::DATA_REMAINING)]
				if {[string length $val] != $len} {
					set val [string range $val[string repeat \x00 $len] 0 [expr {$len - 1}]]
				}
			}
			$options(-tlv) upd $::p2pv2::DLPParamType::DATA_REMAINING $val
		}

		method set_sync { sync } {
			if { $sync == 1 } {
				set options(-op_code) [expr {$::p2pv2::TLPFlag::SYN}]
				set peer_info [binary format SuSuSuSuIu $::p2p::PeerInfo::PROTOCOL_VERSION $::p2p::PeerInfo::IMPLEMENTATION_ID $::p2p::PeerInfo::VERSION 0 $::p2p::PeerInfo::CAPABILITIES]
				$self set_peer_info $peer_info
			} else {
				set options(-op_code) 0
				set options(-peer_info) ""
			}
		}

		method toString { } {

			set size [expr {8 + [string length [$options(-tlv) toString]]}]
			set data_size $options(-chunk_size)
			set data_header ""
			if { $data_size > 0} {
				set data_header [$self build_data_header]
				set data_header_size [string length $data_header]
				set data_size [ expr {$data_size + $data_header_size}]
			}
			set header [binary format cucuSuIu $size $options(-op_code) $data_size $options(-chunk_id)]
			set tlvstr [$options(-tlv) toString]
			return $header$tlvstr$data_header

		}

		method parse { data } {

			if { [catch {binary scan [string range $data 0 7] cubSuIu size options(-op_code) options(-chunk_size) options(-chunk_id)} msg]} {
				return ""
			}
			puts "scanned data [hexify [string range $data 0 7]] and got size $options(-chunk_size)"
			$options(-tlv) parse [string range $data 8 $size] [expr {$size - 8}]
			if { $options(-chunk_size) > 0 } {
				set dph_size [$self parse_data_header [string range $data $size end]]
				puts "dph size is $dph_size , chunk size is $options(-chunk_size)"
				set options(-chunk_size) [expr {$options(-chunk_size) - $dph_size}]
				set size [expr {$size + $dph_size}]
			}
			puts "Chunk size $options(-chunk_size) of data [hexify [string range $data 0 7]]"
			return $size

		}

		method build_data_header { } {

			set size [expr {[string length [$options(-data_tlv) toString]] + 8}]
			set header [binary format cubSuWu $size [$self tf_combination] $options(-package_number) $options(-session_id)]
			set datatlv [$options(-data_tlv) toString]
			return $header$datatlv

		}

		method parse_data_header { data } {

			if { [catch {binary scan [string range $data 0 7] cubSuWu size tf_combination options(-package_number) options(-session_id)}]} {
				return 0
			}
			$self set_tf_combination $tf_combination
			$options(-data_tlv) parse [string range $data 8 $size] [expr {$size - 8}]
			return $size

		}
			

	}

	snit::type MessageChunk {

		option -header ""
		option -body ""
		option -application_id 0
		option -version 2

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

		method id { } {

			return [$self get_field chunk_id]

		}

		method set_id { val } {

			return [$self set_field chunk_id $val]

		}

		method next_id { } {

			return [expr { [$self id] + [$options(-header) data_size]}]

		}

		method set_appid { val } {

			set options(-application_id) $val
			if { [$self get_field session_id] == 0 || [$self is_data_preparation_chunk] } {
				$self set_field data_type $::p2pv2::DLPType::SLP
			} elseif { $val == $::p2p::ApplicationID::FILE_TRANSFER } {
				$self set_field data_type $::p2pv2::DLPType::FILE_TRANSFER
			} elseif { $val == $::p2p::ApplicationID::CUSTOM_EMOTICON_TRANSFER || $val == $::p2p::ApplicationID::DISPLAY_PICTURE_TRANSFER || $val == $::p2p::ApplicationID::WINK_TRANSFER || $val == $::p2p::ApplicationID::VOICE_CLIP_TRANSFER } {
				$self set_field data_type $::p2pv2::DLPType::MSN_OBJECT
			}

		}

		method session_id { } {

			return [$self get_field session_id]

		}

		method set_session_id { val } {

			return [$self set_field session_id $val]

		}

		method blob_id { } {

			return [$self get_field package_number]

		}

		method ack_id { } {

			puts "chunk id [hexify [$self get_field chunk_id]] and data size [hexify [$options(-header) data_size]]"
			return [expr {[$self get_field chunk_id] + [$options(-header) data_size]}]

		}

		method acked_id { } {

			return [$options(-header) ack_seq]

		}

		method naked_id { } {

			return [$options(-header) nak_seq]

		}

		method size { } {

			return [$self get_field chunk_size]

		}

		method blob_size { } {

			if { [$self get_field first] == 0 } {
				return 0
			}
			puts "Data remaining: [$options(-header) data_remaining] and size: [$self size]"
			return [expr {[$options(-header) data_remaining] + [$self size]}]

		}

		method is_control_chunk { } {

			puts "Is this a control chunk? [expr {[$self is_ack_chunk] || [$self is_nak_chunk] || ([$self require_ack] && [$self size] == 0)}]"
			puts "Our size is [$self size] and we require ack? [$self require_ack]"
			return [expr {[$self is_ack_chunk] || [$self is_nak_chunk] || ([$self require_ack] && [$self size] == 0)}]

		}

		method is_ack_chunk { } {

			return [expr {[$options(-header) ack_seq] > 0}]

		}

		method is_nak_chunk { } {

			return [expr {[$options(-header) nak_seq] > 0}]
		
		}

		method is_syn_request { } {

			return [expr {[$self get_field op_code] & $::p2pv2::TLPFlag::SYN}] && ! [$self is_ack_chunk]

		}

		method is_signaling_chunk { } {

			return [expr {[$options(-header) cget -data_type] == $::p2pv2::DLPType::SLP}]

		}

		method is_data_preparation_chunk { } {

			return [expr {[$self get_field first] == 1 || ([$self size] == 4)}]

		}

		method require_ack { } {

			puts "Requiring ack? [hexify [expr {[$self get_field op_code] & $::p2pv2::TLPFlag::RAK == $::p2pv2::TLPFlag::RAK}]]"
			return [expr {[$self get_field op_code] & $::p2pv2::TLPFlag::RAK == $::p2pv2::TLPFlag::RAK}]

		}

		method has_progressed { } {

			return 1

		}

		method create_ack_chunk { } {

			set header [TLPHeader %AUTO%]
			$header set_ack_seq [$self ack_id]
			$header set_sync [expr {([$self get_field op_code] & $::p2pv2::TLPFlag::SYN) != 0}]
			return [MessageChunk %AUTO% -header $header]

		}

		method set_data { data } {

			set options(-body) $data
			$self set_field chunk_size [string length $data]

		}

		typemethod createMsg { app_id session_id blob_id offset blob_size max_size sync csize } {
			#The chunk size argument is here ignored and recalculated, as explained in TLP.tcl method get_chunk
			set header [TLPHeader %AUTO% -session_id $session_id -first [expr {$offset == 0}]]
			set max_chunk_size [expr {$max_size - [$header size]}]
			set data_remaining [expr {$blob_size - $offset}]
			if { $max_chunk_size >= $data_remaining } {
				set chunk_size $data_remaining
			} else {
				set chunk_size $max_chunk_size
			}
			$header configure -chunk_size $chunk_size 
			$header set_data_remaining [expr {$data_remaining - $chunk_size}]
			$header set_sync $sync

			if { $session_id == 0 && [$header data_remaining] == 0 } {
				$header configure -op_code [expr {[$header cget -op_code] | $::p2pv2::TLPFlag::RAK}]
			}

			if { $session_id == 0 && ! ([$header cget -first] || ([$header data_remaining] > 0)) } {
				$header configure -package_number [expr {$blob_id & 0xFFFF}]
			}
			set chunk [MessageChunk %AUTO% -header $header]
			$chunk configure -application_id $app_id
			return $chunk

		}

		typemethod parse { data } {

			set header [TLPHeader %AUTO%]
			set header_size [$header parse $data]
			set body [string range $data $header_size end]
			return [MessageChunk %AUTO% -header $header -body $body]

		}

		method toString { } {

			set str1 [$options(-header) toString]
			set str2 $options(-body)
			return $str1$str2

		}
		
                method get_field { arg } {

                        return [[$self cget -header] cget -$arg]

                }

                method set_field { arg val } {

                        return [[$self cget -header] configure -$arg $val]

                }

	}

}
