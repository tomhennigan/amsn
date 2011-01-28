namespace eval ::p2p {

	snit::type MSNObject {

		option -creator ""
		option -size 0
		option -type ""
		option -location ""
		option -friendly ""
		option -shad ""
		option -shac ""
		option -data ""

		constructor {args} {

			$self configurelist $args

			if { $options(-shad) == "" } {
				if { $options(-data) == "" } {
					return ""
				}
				$self configure -shad [$self Compute_data_hash $options(-data)]
			}

			if { $options(-shac) == "" } {
				$self configure -shac [$self Compute_checksum]
			}

		}

		method Set_data {data} {

			$self configure -size [string length $data]
			$self configure -data $data
			$self configure -shad [$self Compute_data_hash $data]
			$self configure -shac [$self Compute_checksum]

		}

		typemethod parse { xml_data } {

			set elements [split $xml_data " "]
			set creator [MSNObject retrieve $elements "Creator"]
			set size [MSNObject retrieve $elements "Size"]
			set type [MSNObject retrieve $elements "Type"]
			set location [encoding convertfrom utf-8 [MSNObject retrieve $elements "Location"]]
			set friendly [base64::decode [::sxml::replacexml [encoding convertfrom utf-8 [MSNObject retrieve $elements "Friendly"]]]]
			set shad ""
			set shad [MSNObject retrieve $elements "SHA1D"]
			#if { [info exists shad] && $shad != "" } {
			#  set shad [MSNObject Decode_shad $shad]
			#}
			set shac [MSNObject retrieve $elements "SHA1C"]
			if { [info exists shac] && $shac != "" } {
				set shac [base64::decode $shac]
			}

			set result [MSNObject %AUTO% -creator $creator -size $size -type $type -location $location -friendly $friendly -shad $shad -shac $shac]

			return $result

		}
		typemethod retrieve { elem data } {

			set idx [lsearch $elem "$data=*"]
			if { $idx < 0 } { return "" }
			set ret [lindex $elem $idx]
			set ret [string range $ret [expr { [string length $data]+1}] end]
			if { [string index $ret 0] == "\"" } { set ret [string range $ret 1 end] }
			if { [string index $ret end] == "\"" } { set ret [string range $ret 0 end-1] }
			return $ret

		}

		typemethod Decode_shad { shad } {

			set shad [base64::decode $shad]
			if { [string first " " $shad] >= 0 } {
				set parts [split $shad " "]
				set shad [Decode_shad [lindex $parts 0]]
				if { $shad == "" } {
					set shad [Decode_shad [lindex $parts 1]]
				}
			} else {
				set shad ""
			}
			return $shad

		}

		method Compute_data_hash { data} {

			return [string map {"\n" ""} [::base64::encode [binary format H* [::sha1::sha1 $data]]]]

		}

		method Compute_checksum {} {

			set creator [$self cget -creator]
			set size [$self cget -size]
			set type [$self cget -type]
			set file [$self cget -location]
			set friendly [$self cget -friendly]
			set sha1d [$self cget -shad]

			set sha1d [base64::encode $sha1d]
			set friendly [base64::encode $friendly]

			return [string map {"\n" ""} [::base64::encode [binary format H* [::sha1::sha1 "Creator${creator}Size${size}Type${type}Location${file}Friendly${friendly}SHA1D${sha1d}"]]]]

		}

		method toString { } {

			set creator [$self cget -creator]
			set size [$self cget -size]
			set type [$self cget -type]
			set file [$self cget -location]
			set friendly [$self cget -friendly]
			set sha1d [$self cget -shad]
			set sha1c [$self cget -shac]

			set friendly [base64::encode $friendly]
			set file [encoding convertto utf-8 $file]
			set sha1c [base64::encode $sha1c]

			set msnobj "<msnobj Creator=\"$creator\" Size=\"$size\" Type=\"$type\" Location=\"$file\" Friendly=\"${friendly}\" SHA1D=\"$sha1d\" SHA1C=\"$sha1c\"/>\x00"
			return $msnobj

		}

	}

	snit::type MSNObjectSession {

		delegate method * to P2PSession
		delegate option * to P2PSession

		option -guid ""
		option -context ""

		variable data ""

		constructor { args } {

			install P2PSession using P2PSession %AUTO% -euf_guid $::p2p::EufGuid::MSN_OBJECT
			$self configurelist $args
			::Event::registerEvent p2pByeReceived all [list $self On_bye_received]
			::Event::registerEvent p2pOutgoingSessionTransferCompleted all [list $self On_data_blob_received]

		}

		destructor {

			catch {::Event::unregisterEvent p2pByeReceived all [list $self On_bye_received]}
			catch {::Event::unregisterEvent p2pBridgeSelected all [list $self On_bridge_selected]}
			catch {::Event::unregisterEvent p2pOutgoingSessionTransferCompleted all [list $self On_data_blob_received]}
			$P2PSession destroy

		}

		method conf2 { } {

			$P2PSession conf2
			set msg [$P2PSession cget -message]
			if { $msg != "" } {
				set options(-application_id) [$msg cget -application_id]
				set options(-context) [string trim [[$msg body] cget -context] \x00 ]
			}
			$P2PSession configure -context $options(-context)
			::Event::registerEvent p2pBridgeSelected all [list $self On_bridge_selected]

		}

                method On_data_blob_received { event session rcvdata } {

                        if { $session != $P2PSession } { return }
			$self Close $options(-context) ""
			after 60000 [list catch [list $self destroy]]

		}

		method data { } {

			return $data

		}

		method setData { newData } {

			set data $newData

		}

		method p2p_session { } {

			return $P2PSession

		}

		method On_bye_received { event session } {

			if { $session != $P2PSession } { return }
			after 60000 [list catch [list $self destroy]]

		}

		method accept { data_file } {
			set data $data_file
			$self Respond "200"
			$self Request_bridge
		}

		method reject { } {
			$self Respond "603"
			after 60000 [list catch [list $self destroy]]
		}

		#method invite { context } {
		#  $self Invite $context
		#  return 0
		#}

		method send { } {
			$self Send_p2p_data "\x00\x00\x00\x00"
			$self Send_p2p_data $data
		}

		method On_bridge_selected { event session } {

			if { $session != $P2PSession } { return }

			if { $data != "" } {
				$self send
			}
			after 60000 [list catch [list $self destroy]]
		}

	}

}
