############################################################
# License: GNU General Public License                     #
#                                                         #
# Plugin written by: Giuseppe Bottiglieri (aka Square87)  #
# Version: 0.1                                            #
###########################################################

namespace eval ::skincolor {

proc init { dir } {
	::plugins::RegisterPlugin "SkinColor"

	::plugins::RegisterEvent "SkinColor" ContactListColourBarDrawn draw
	
	::skin::setPixmap colorskin colorskin.gif pixmaps [file join $dir pixmaps]

	variable started 0

	array set ::skincolor::config [list \
		darklight "light" \
		color 0 \
	]
	
	if {$::contactlist_loaded} {
		draw 0 0
	}
}

proc deinit {} {
	variable started 0
	resetcolor
	cmsn_draw_online 0 1
}

proc draw {event evPar} {
	if {$event != 0} { upvar 2 $evPar vars }

	set icon colorskin
	
	#TODO: add parameter to event and get rid of hardcoded variable
	set pgtop $::pgBuddyTop
	set clbar $::pgBuddyTop.colorbar

	set mylabel $pgtop.skincolor
	if {[winfo exists $mylabel]} {
		destroy $mylabel
	}
	
	set notewidth [image width [::skin::loadPixmap $icon]]
	set noteheight [image height [::skin::loadPixmap $icon]]

	label $mylabel -image [::skin::loadPixmap $icon] -background [::skin::getKey topcontactlistbg] -borderwidth 0 -cursor left_ptr \
		-relief flat -highlightthickness 0 -relief flat -highlightthickness 0 -borderwidth 0 -padx 0 -pady 0 -width $notewidth -height $noteheight

	pack $mylabel -expand false -after $clbar -side right -padx 0 -pady 0

	bind $mylabel <<Button1>> "::skincolor::box .fdfsd %X %Y"

	set balloon_message [trans changecoloramsn]
	
	bind $mylabel <Enter> +[list balloon_enter %W %X %Y ""]
	bind $mylabel <Leave> "+set ::Bulle(first) 0; kill_balloon;"
	bind $mylabel <Motion> +[list balloon_motion %W %X %Y $balloon_message]
	
	variable started
	if {$started == 0} {
		cmsn_draw_online 0 1
		set started 1
	}
	
	if {$::skincolor::config(color) != 0} {
		::skin::setKey topgroupbg_style $::skincolor::config(darklight)
		setcolor $::skincolor::config(color) 1
	}
}


proc box { windowname x y {text text}} {
	set w .skincolor
	set sw $w.s

	if {[winfo exists $w]} { destroy $w }

	toplevel $w -takefocus 1
	wm title $w "[trans colorselector]"
	wm geometry $w 210x210
	wm maxsize $w 210 210
	wm overrideredirect $w 1
	focus -force $w

	wm geometry $w +[expr $x - 220]+[expr $y - 70]

	bind $w <FocusOut> "destroy $w"
#	bind $w <Leave> "destroy $w"
	
	set wf $w.wf
	frame $wf

	set canvas $wf.canvas
	canvas $canvas -height 160
	
	set x1 10
	set y1 10
	set x2 30
	set y2 30
	set s 0
	foreach color [get_listcolor] {
		$canvas create rect $x1 $y1 $x2 $y2 -fill [rgbcolor $color] -tag [list $color skincolor]
	#	$canvas create text $x2 $y1 -text [trans $color]
		$canvas bind $color <Button-1> [list ::skincolor::setcolor $color]
		incr x1 40
		incr x2 40
		incr s
		if {$s == 5} {
			set x1 10
			set x2 30
			incr y1 40
			incr y2 40
			set s 0
			
		}
	}
	
	$canvas create rect $x1 $y1 $x2 $y2 -tag [list reset skincolor]
	$canvas create line $x1 $y1 $x2 $y2 $x1 $y2 $x2 $y1 -tag [list reset skincolor]
	$canvas bind "reset" <Button-1> [list ::skincolor::resetcolor]
	
	$canvas bind skincolor <Enter> "$canvas configure -cursor hand2"
	$canvas bind skincolor <Leave> "$canvas configure -cursor left_ptr"
	
	pack $canvas
	pack $wf -anchor n

	variable dark
	set wr $w.radio
	frame $wr
	radiobutton $wr.button1 -text [trans light] -value 0 -variable dark -command "::skin::setKey topgroupbg_style light ; ::skincolor::update_cl"
	radiobutton $wr.button2 -text [trans dark] -value 1 -variable dark -command "::skin::setKey topgroupbg_style dark ; ::skincolor::update_cl"
	pack $wr.button2 -side left
	pack $wr.button1 -side right
	pack $wr -anchor n

}

proc resetcolor {} {
	skin::setKey contact_hover_box ""
	skin::setKey groupcolorborder ""
	skin::setKey topgroupbg ""
	
	set ::skincolor::config(color) 0
	
	update_cl
}

proc setcolor {color {skip 0}} {
	if {!$skip} {
		set color [rgbcolor $color]
	}
	#set lightcolor [fadecolor $color]
	
	skin::setKey contact_hover_box $color
	skin::setKey groupcolorborder $color
	skin::setKey topgroupbg $color
	
	set ::skincolor::config(color) $color
	
	update_cl
}

proc update_cl {} {
	::guiContactList::organiseList ".main.f.cl.cvs" [::guiContactList::getContactList]
}

#deleted: lime
proc get_listcolor {} {
      set list [list white black green teal red brown purple pink violet orange gold yellow aqua marine blue gray silver]
      return $list
}

proc rgbcolor {color} {
	array set colors [list  \
		white "FFFFFF" black "000000" marine "00007F" green "00FF00" red "FF0000" \
		brown "7F0000" purple "9C009C" orange "FC7F00" yellow "FFFF00" lime "00FC00" \
		teal "009393" aqua "00FFFF" blue "0000FF" pink "FF00FF" gray "7F7F7F" \
		silver "c0c0c0" gold "ffd700" violet "EE82EE"]
	if { [info exists colors($color)] } {
		return "#[set colors($color)]"
	} else {
		return -1
	}
}

#NOT USED
proc fadecolor {color} {
	set rgblist [list [expr 0x[string range $color 1 2]] [expr 0x[string range $color 3 4]] [expr 0x[string range $color 5 6]]]

	set a "#"
	foreach x $rgblist {
		set d [expr (255 - $x)]
		if {$d > 0} {
			set x [expr ($x + ($d/2))]
		}
		if {$x > 255} {set x 255}
		set x [format "%0.0f" $x]
		if {$x < 16} {
			append a "0[format %x $x]"
		} else {
			append a [format %x $x]
		}
	}

	return $a
}

}
