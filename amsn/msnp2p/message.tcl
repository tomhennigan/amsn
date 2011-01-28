namespace eval ::p2p {

	snit::type Message {

		variable headers -array {}
		variable body ""
		variable headernames {}
		variable found 0
		option -content_type
		option -application_id \x00\x00\x00\x00

		constructor { args } {
			$self configurelist $args
			$self clear
		}

		method set_body { newbody } {
			set body $newbody
		}

		method get_body { } {
			return $body
		}

		method headers { } {
			return [array get headers]
		}

		method add_header { key value } {

			set headers($key) $value
			if { [lsearch $headernames $key] < 0 } {
				set headernames [lappend headernames $key]
			}
			if { $key == "Content-Type" } {
				set options(-content_type) $value
			}

		}

		method clear { } {
			array set headers {}
			set body ""
		}

		method parse { chunk } {

			if { $found == 1 } {
				set body $chunk
			} else {
				set idx [string first "\r\n\r\n" $chunk]
				set head [string range $chunk 0 [expr {$idx -1}]]
				set body [string range $chunk [expr {$idx+4}] end]
				set head [string map {"\r\n" "\n"} $head]
				set lines [split $head "\n"]
				foreach line $lines {
					if { $line == "" } {
						set found 1
					} else {
						set colon [string first ": " $line]
						set key [string range $line 0 [expr {$colon - 1}]]
						set value [string range $line [expr {$colon + 2}] end]
						$self add_header $key $value
					}
				}
			}

			if { [lsearch [array names headers] "Content-Type"] >= 0 } {
				set content_type $headers(Content-Type)
			} else {
				set content_type ""
			}
			set options(-content_type) $content_type
		}

		method toString { } {

			set str ""
			set newl \r\n
			#content-length
			foreach key $headernames {
				set value $headers($key)
				set str [join [list $str $key ": " $value $newl] ""] ;#concat strips newlines
			}
			set str [join [list $str $newl $body $options(-application_id)] ""]
			return $str

		}

	}

}
