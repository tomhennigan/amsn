# ***********************************************************
#            Advertisement/Branding Module
#        Copyright (c)2002 Coralys Technologies,Inc.
#	           http://www.coralys.com/
#		      Revision 1.2.2
# ***********************************************************
#
# Configuration of Advertisement Module (banner 234x46)
#
#
# $Id$
#

if { $initialize_amsn == 1 } {
    global adv_url adv_timeout adv_cycle adv_enable adv_paused
    global adv_fetched adv_recycle adv_lastfile adv_after_id

    set adv_url "http://ads.someserver.com/ads/servead.php?s=234x46&afid=1234"
    set adv_timeout 3000	; # Timeout (ms) for HTTP request
    #set adv_cycle 300000	; # Time (ms) between fetch requests
    set adv_cycle 3000	; # Time (ms) between fetch requests
    set adv_lastfile ""	; # Last file used in adv_show_banner file xxx
    set adv_recycle  2	; # Modulo used for recycling adv_lastfile
    
    #
    # Advertisement Module globals
    #
    set adv_enable 1	; # Enable/Disable banner fetching (dynamic)
    set adv_paused 1	; # Paused until connection established
    set adv_fetched 0	; # Count how many adverts we fetched
    set adv_after_id -1

}
 
package require http


#
# Initialize the Advertisement module (hey! need bread on the table!)
#
proc adv_initialize { win } {
    global adv_cycle adv_enable adv_paused adv_after_id

    label ${win}.banner -bd 0 -relief flat -background #FFFFFF
    pack ${win}.banner -side bottom -fill x

    # Banner is clickable, but so far no way to get the URL
    # that corresponds to that banner
#    bind ${win}.banner <Button-3> { puts "browse" }

    # Keybinding to enable/disable Banner cycling on main window
    bind . <Control-b> { set adv_enable 0 }
    bind . <Control-r> { set adv_enable 1 }
    if { ($adv_enable == 1) && ($adv_paused == 0) } {
        set adv_after_id [after $adv_cycle adv_fetch]
    }
}

# Reset the banner, either showing it or hiding it
proc resetBanner {} {
	if {[::config::getKey enablebanner]} {
		# This one is not a banner but a branding. When adverts are enabled
		# they share this space with the branding image. The branding image
		# is cycled in between adverts.
		.main.banner configure -background #FFFFFF -image [::skin::loadPixmap logolinmsn]
	} else {
		.main.banner configure -background [::skin::getColor mainwindowbg] -image [::skin::loadPixmap nullimage]
	}
}


# Progress callback for the HTTP advertisement module
proc adv_progress {token total current} {
    upvar #0 $token state
    global adv_fetched

#    puts "$token $total $current"
    if { $total == $current} {
#        puts "Completed"
	set image_data [ ::http::data $token ]
	adv_show_banner data $image_data
	incr adv_fetched
#	puts "Advert # $adv_fetched"

	# Discard data (gives error)
#	::http::cleanup $token
    }
}

#
# Fetch a new banner from the banner server. Call periodically but
# not too often!
#
proc adv_fetch {} {
    global adv_url adv_timeout adv_cycle adv_enable adv_paused
    global adv_fetched adv_recycle adv_lastfile adv_after_id

    set mod [expr {$adv_fetched % $adv_recycle}]
#    puts "F $adv_fetched R $adv_recycle M $mod"
    if { $adv_fetched > 0 && $mod == 0 } {
        adv_show_banner file $adv_lastfile
	incr adv_fetched
    } else {
	set htoken [ ::http::geturl $adv_url -timeout $adv_timeout -progress adv_progress]
#       puts "Fetched advert"
    }


    # TODO Actually since it is async we should set this after completed
    if { ($adv_enable == 1) && ($adv_paused == 0) } {
        set adv_after_id [after $adv_cycle adv_fetch]
    }
}

# Read image data from a file. Somehow mixing use of -file and -data
# in the same existing image does not work.
proc adv_read_file { filename } {

    set file_id [open "$filename" r]
    fconfigure $file_id -buffering none -translation {binary binary}
    set img_data [read -nonewline $file_id]
    close $file_id
    return $img_data
}

proc adv_show_banner { type banner_image } {
    global adv_lastfile

    if { [string compare $type "file"] == 0} {
	set img_data [adv_read_file $banner_image]
	banner configure -data $img_data
	set adv_lastfile $banner_image
    } else {
        banner blank
        banner configure -data $banner_image
    }
}

# Call this after a Sign Off
proc adv_pause {} {
    global adv_paused adv_after_id

    after cancel $adv_after_id
    set adv_paused 1
puts "ADV paused"
}

# Call this after a successful network logon
proc adv_resume {} {
    global adv_paused adv_after_id adv_enable adv_cycle

    set adv_paused 0

    if { $adv_enable == 1 } {
        set adv_after_id [after $adv_cycle adv_fetch]
    }
puts "ADV resumed $adv_enable"
}

