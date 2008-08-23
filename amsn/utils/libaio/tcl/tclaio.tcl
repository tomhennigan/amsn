
proc ::Aio::_PlayWav_Closed { dev fd cb} {
	::Aio::Close $dev 
	close $fd
	eval $cb
}

proc ::Aio::_PlayWav_Callback { dev fd cb data_pos offset max } {
	if {$offset >= $max } {
		set a [expr {int([::Aio::GetDelay $dev] * 1000)}]
		if {$a > 0} {
			after $a [list ::Aio::_PlayWav_Closed $dev $fd $cb]
			return
		} else {
			 ::Aio::_PlayWav_Closed $dev $fd $cb
		}
	}
	seek $fd [expr {$offset + $data_pos}]
	set space [::Aio::GetSpace $dev]
	if {[expr {$offset + $space}] > $max} { 
		puts "Final data"
		set data [read $fd [expr {$max - $offset}]]
		set written [::Aio::Play $dev -final $data]
	} else {
		set data [read $fd $space]
		set written [::Aio::Play $dev $data]
	}
	incr offset $written
	set a [expr {int([::Aio::GetDelay $dev] * 1000 / 2)}]
	after $a [list ::Aio::_PlayWav_Callback $dev $fd $cb $data_pos $offset $max]
}

proc ::Aio::PlayWav { filename callback } {
	set fd [open $filename r]
	fconfigure $fd -translation binary

	set riff ""
	set wave ""
	set input [read $fd 12]
	binary scan $input a4ia4 riff size wave
	set offset 12
	if { $riff == "RIFF" && $wave == "WAVE" } {
		while { $offset < $size } {
			set input [read $fd 8]
			binary scan $input a4i id chunk_size
			incr offset 8
			if {$id == "fmt " } {
				set input [read $fd $chunk_size]
				binary scan $input ssiiss format channels sampleRate byteRate blockAlign bitsPerSample
		}
		if {$id == "data" } {
			set data_pos $offset
			set data_size $chunk_size
		} 
		incr offset $chunk_size
		seek $fd $offset
		}
	} else {
		error "File is not a WAV file"
	}

	if {![info exists format] } {
		set format 1
	}

	if {$format != 1} {
		error "WAV file is not PCM"
	}

	set dev [::Aio::Open -driver alsa -rate $sampleRate -bps $bitsPerSample -channels $channels]
	
	::Aio::_PlayWav_Callback $dev $fd $callback $data_pos 0 $data_size
}