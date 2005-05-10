#!/usr/bin/wish
lappend auto_path [pwd]
package require capture

#puts "Device list : [::Capture::ListDevices]"
#puts "[::Capture::ListChannels /dev/video]"
#set grabber [::Capture::Open /dev/video 0]
#puts "[::Capture::GetGrabber /dev/video 0]"

set devices [::Capture::ListDevices]
set ::grabber ""
set ::preview ""

wm protocol . WM_DELETE_WINDOW {
	if { [::Capture::IsValid $::grabber] } { ::Capture::Close $::grabber }
	if { [::Capture::IsValid $::preview] } { ::Capture::Close $::preview }
	exit
}

set img [image create photo]
label .l -image $img
button .s -text "Camera Settings" -command "ShowPropertiesPage $::grabber $img"
button .c -text "Choose device" -command "ChooseDevice; .s configure -command \"ShowPropertiesPage \$::grabber $img\"; StartGrab \$::grabber $img"

pack .l .s .c -side top


proc ChooseDevice { } {

	set window .chooser
	set lists $window.lists
	set devs $lists.devices
	set chans $lists.channels
	set buttons $window.buttons
	set status $window.status
	set preview $window.preview
	set settings $window.settings

	destroy $window
	toplevel $window


	frame $lists


	frame $devs -relief sunken -borderwidth 3
        label $devs.label -text "Devices"
	listbox $devs.list -yscrollcommand "$devs.ys set" -background \
	    white -relief flat -highlightthickness 0 -height 5
	scrollbar $devs.ys -command "$devs.list yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
        pack $devs.label $devs.list -side top -expand false -fill x
	pack $devs.ys -side right -fill y
	pack $devs.list -side left -expand true -fill both


	frame $chans -relief sunken -borderwidth 3
        label $chans.label -text "Channels"
	listbox $chans.list -yscrollcommand "$chans.ys set"  -background \
	    white -relief flat -highlightthickness 0 -height 5 -selectmode extended
	scrollbar $chans.ys -command "$chans.list yview" -highlightthickness 0 \
         -borderwidth 1 -elementborderwidth 2
        pack $chans.label $chans.list -side top -expand false -fill x
	pack $chans.ys -side right -fill y
	pack $chans.list -side left -expand true -fill both

	pack $devs $chans -side left

	label $status -text "Please choose a device"

	set img [image create photo]
	label $preview -image $img
	button $settings -text "Camera Settings" -command "ShowPropertiesPage $::preview $img"

	frame $buttons -relief sunken -borderwidth 3
	button $buttons.ok -text "Ok" -command "Choose_Ok $window $devs.list $chans.list $img"
	button $buttons.cancel -text "Cancel" -command "destroy $window"
	wm protocol $window WM_DELETE_WINDOW "Choose_Cancel $window $img"
	pack $buttons.ok $buttons.cancel -side left

	pack $lists $status $preview $settings $buttons -side top

	bind $devs.list <Button1-ButtonRelease> "FillChannels $devs.list $chans.list $status"
	bind $chans.list <Button1-ButtonRelease> "StartPreview $devs.list $chans.list $status $preview $settings"

	foreach device $::devices {
		set dev [lindex $device 0]
		set name [lindex $device 1]

		if {$name == "" } {
			set name "Device $dev is busy"
		}

		$devs.list insert end $name
	}

	tkwait window $window
}

proc FillChannels { device_w chan_w status } {

	$chan_w delete 0 end

	if { [$device_w curselection] == "" } {
		$status configure -text "Please choose a device"
		return
	}
	set dev [$device_w curselection]

	set device [lindex $::devices $dev]
	set ::device [lindex $device 0]

	if { [catch {set channels [::Capture::ListChannels $::device]} res] } {
		$status configure -text $res
		return
	}

	foreach chan $channels {
		$chan_w insert end [lindex $chan 1]
	}

	$status configure -text "Please choose a Channel"
}

proc StartPreview { device_w chan_w status preview_w settings } {

# 	if { [$device_w curselection] == "" } {
# 		$status configure -text "Please choose a device"
# 		return
# 	}

	if { [$chan_w curselection] == "" } {
		$status configure -text "Please choose a Channel"
		return
	}

	set img [$preview_w cget -image]
	if {$img == "" } {
		return
	}

	set dev [$device_w curselection]
	set chan [$chan_w curselection]

# 	set device [lindex $::devices $dev]
# 	set device [lindex $device 0]


	if { [catch {set channels [::Capture::ListChannels $::device]} res] } {
		$status configure -text $res
		return
	}

	set channel [lindex $channels $chan]
	set channel [lindex $channel 0]

	if { [::Capture::IsValid $::preview] } {
		::Capture::Close $::preview
	}

	if { [catch {set ::preview [::Capture::Open $::device $channel]} res] } {
		$status configure -text $res
		return
	}

	$settings configure -command "ShowPropertiesPage $::preview $img"
	after 0 "StartGrab $::preview $img"

}

proc Choose_Ok { w device_w chan_w img} {

	if { [::Capture::IsValid $::preview] } {
		::Capture::Close $::preview
	}

	image delete $img

# 	if { [$device_w curselection] == "" } {
# 		destroy $w
# 		return
# 	}

	if { [$chan_w curselection] == "" } {
		destroy $w
		return
	}

	set dev [$device_w curselection]
	set chan [$chan_w curselection]

# 	set device [lindex $::devices $dev]
# 	set device [lindex $device 0]


	if { [catch {set channels [::Capture::ListChannels $::device]} res] } {
		destroy $w
		return
	}

	set channel [lindex $channels $chan]
	set channel [lindex $channel 0]


	if { [catch {set temp [::Capture::Open $::device $channel]} res] } {
		destroy $w
		return
	}

	if { [::Capture::IsValid $::grabber] } {
		::Capture::Close $::grabber
	}
	set ::grabber $temp

	if { [winfo exists .properties_$::preview] } {
		destroy .properties_$::preview
	}


	destroy $w
}

proc Choose_Cancel { w  img} {

	if { [::Capture::IsValid $::preview] } {
		::Capture::Close $::preview
	}

	image delete $img

	if { [winfo exists .properties_$::preview] } {
		destroy .properties_$::preview
	}

	destroy $w
}

proc ShowPropertiesPage { capture_fd {img ""}} {

	if { ![::Capture::IsValid $capture_fd] } {
		return
	}

	set window .properties_$capture_fd
	set slides $window.slides
	set preview $window.preview
	set buttons $window.buttons

	set init_b [::Capture::GetBrightness $capture_fd]
	set init_c [::Capture::GetContrast $capture_fd]
	set init_h [::Capture::GetHue $capture_fd]
	set init_co [::Capture::GetColour $capture_fd]

	destroy $window
	toplevel $window

	frame $slides
	scale $slides.b -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Brightness" -command "Properties_Set $slides.b b $capture_fd" -orient horizontal
	scale $slides.c -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Contrast" -command "Properties_Set $slides.c c $capture_fd" -orient horizontal
	scale $slides.h -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Hue" -command "Properties_Set $slides.h h $capture_fd" -orient horizontal
	scale $slides.co -from 0 -to 65535 -resolution 1 -showvalue 1 -label "Colour" -command "Properties_Set $slides.co co $capture_fd" -orient horizontal

	pack $slides.b $slides.c $slides.h $slides.co -side top -expand true -fill x

	frame $buttons -relief sunken -borderwidth 3
	button $buttons.ok -text "Ok" -command "destroy $window"
	button $buttons.cancel -text "Cancel" -command "Properties_Cancel $window $capture_fd $init_b $init_c $init_h $init_co"
	wm protocol $window WM_DELETE_WINDOW "Properties_Cancel $window $capture_fd $init_b $init_c $init_h $init_co"


	pack $buttons.ok $buttons.cancel -side left

	if { $img == "" } {
		set img [image create photo]
	}
	label $preview -image $img

	after 0 "StartGrab $capture_fd $img"


	pack $slides $preview $buttons -side top


	$slides.b set $init_b
	$slides.c set $init_c
	$slides.h set $init_h
	$slides.co set $init_co

	return $window

}

proc Properties_Set { w property capture_fd new_value } {

	switch $property {
		b {
			::Capture::SetBrightness $capture_fd $new_value
			set val [::Capture::GetBrightness $capture_fd]
			$w set $val
		}
		c {
			::Capture::SetContrast $capture_fd $new_value
			set val [::Capture::GetContrast $capture_fd]
			$w set $val
		}
		h
		{
			::Capture::SetHue $capture_fd $new_value
			set val [::Capture::GetHue $capture_fd]
			$w set $val
		}
		co
		{
			::Capture::SetColour $capture_fd $new_value
			set val [::Capture::GetColour $capture_fd]
			$w set $val
		}
	}

}
proc Properties_Cancel { window capture_fd init_b init_c init_h init_co } {

	::Capture::SetBrightness $capture_fd $init_b
	::Capture::SetContrast $capture_fd $init_c
	::Capture::SetHue $capture_fd $init_h
	::Capture::SetColour $capture_fd $init_co
	destroy $window
}

proc StartGrab { grabber img } {
	set semaphore ::sem_$grabber
	set $semaphore 0

	while { [::Capture::IsValid $grabber] && [lsearch [image names] $img] != -1 } {
		::Capture::Grab $grabber $img
		after 100 "incr $semaphore"
		tkwait variable $semaphore
	}
}
