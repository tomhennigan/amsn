# Doesn't handle focus all that well yet.  Not totally bust though...

namespace eval notebook {
    # Start by configuring the "compiled-in" default for the label to
    # look like the compiled-in defaults for the buttons, making them
    # default to something not entirely daft in the process...
    foreach {opt val} {
	highlightThickness 0
	borderWidth        0
	relief             raised
	padX               3
	padY               3
    } {
	option add *NoteBook.Label.$opt $val 30
    }

    variable re {([0-9]+)x([0-9]+)\+(-?[0-9]+)\+(-?[0-9]+)}
    proc drawPoly {w} {
	variable buttonList
	variable paneList
	variable canvas
	variable index
	variable line
	variable text
	variable re

	set p [lindex $paneList($w)   $index($w)]
	set b [lindex $buttonList($w) $index($w)]

	regexp $re [winfo geometry $p] dummy pw ph px py
	# X-Coords
	set pl [expr {$px-1}]
	set pr [expr {$px+$pw}]
	# Y-Coords
	set pt [expr {$py-1}]
	set pb [expr {$py+$ph}]

	set i 0
	set c $canvas($w)
	foreach b $buttonList($w) l $line($w) t $text($w) {
	    foreach {p l1 l2} $l {break}
	    regexp $re [winfo geometry $b] dummy bw bh bx by
	    # X-Coords
	    set bl [expr {$bx-6}]
	    set br [expr {$bx+$bw}]
	    # Y-Coords
	    set bt [expr {$by-6}]
	    set bb [expr {$by+$bh}]

	    if {$i==$index($w)} {
		$c coords $p \
			$pl $pb  $pl $pt  $bl $pt  $bl $bt  $br $bt \
			$br $pt  $pr $pt  $pr $pb  $pl $pb
		$c coords $l1 [expr {$pl+1}] $pb $pr $pb $pr [expr {$pt+1}]
		$c coords $l2 $br [expr {$pt+1}] $br [expr {$bt+1}]
	    } else {
		foreach {v +} {bl 5 br 5 bt 5 bb 6} {
		    incr $v ${+}
		}
		$c coords $p \
			$bl $bb  $bl $bt  $br $bt  $br $bb  $bl $bb
		$c coords $l1 [expr {$bl+1}] $bb $br $bb $br [expr {$bt+1}]
		$c coords $l2 -10 -10 -20 -20
	    }
	    $c coords $t [expr {($bl+$br)/2}] [expr {($bt+$bb)/2}]
	    incr i
	}
	for {incr i -1} {$i>=0} {incr i -1} {
	    $c raise note$i
	}
	$c raise note$index($w)
    }

    proc selectLabel {w idx} {
	variable labelList
	variable paneList
	variable index
	set index($w) $idx
	focusPane $w $idx
	raise [lindex $paneList($w) $idx]
	drawPoly $w
    }

    proc focusIn {parent idx} {
	variable focus
	set focus($parent) $idx
    }
    proc focusOut {parent idx} {
	variable focus
	set focus($parent) {}
    }
    proc focusPane {parent idx} {
	variable focus
	variable paneList
	if {$focus($parent) != {} && $idx != $focus($parent)} {
	    set focus($parent) {}
	    focus [lindex $paneList($parent) $idx]
	}
    }

    proc makeButtons {parent labels} {
	variable buttonList
	variable labelList
	variable paneList
	variable canvas
	variable line
	variable text

	set labelList($parent) $labels
	set i 0; set j 0
	set bg [$canvas($parent) cget -bg]
	set dark  [tkDarkenn $bg 50]
	set light [tkDarkenn $bg 133]
	foreach l $labels {
	    grid column $parent $i -minsize 7
	    incr i
	    set b [label $parent.__b$j -text $l]
	    lappend buttonList($parent) $b

	    set pid [$canvas($parent) create polygon -10 -10 -20 -20 -20 -10 \
		    -fill $bg  -outline $light  -tags note$j]
	    set lid1 [$canvas($parent) create line -10 -10 -20 -20 \
		    -fill $dark  -tags note$j]
	    set lid2 [$canvas($parent) create line -10 -10 -20 -20 \
		    -fill $dark  -tags note$j]
	    lappend line($parent) [list $pid $lid1 $lid2]

	    set tid [$canvas($parent) create text -10 -10  -text $l \
		    -fill [$b cget -fg]  -font [$b cget -font]  -tags note$j]
	    lappend text($parent) $tid
	    $canvas($parent) bind note$j <1> \
		    [namespace code [list selectLabel $parent $j]]

	    lower $b
	    grid $b -row 1 -column $i -sticky ns
	    set f [frame $parent.__f$j -class NoteBookLeaf]
	    bind $f <FocusOut> [namespace code [list focusOut $parent $j]]
	    bind $f <FocusIn>  [namespace code [list focusIn  $parent $j]]
	    lappend paneList($parent) $f
	    incr i; incr j
	}
	grid column $parent $i -weight 1
	grid row    $parent 2  -weight 1
	incr i
	foreach p $paneList($parent) {
	    grid $p -row 2 -column 0 -columnspan $i -sticky nsew \
		    -padx 2 -pady 4
	}
    }

    proc cleanup {w} {
	variable buttonList
	variable labelList
	variable paneList
	variable canvas
	variable focus
	variable index
	variable line
	variable text
	unset buttonList($w)
	unset labelList($w)
	unset paneList($w)
	unset canvas($w)
	unset focus($w)
	unset index($w)
	unset line($w)
	unset text($w)
    }

    proc getNote {w label} {
	variable labelList
	variable paneList

	set idx [lsearch -exact $labelList($w) $label]
	if {$idx < 0} {
	    return -code error "unknown label \"$label\""
	}
	return [lindex $paneList($w) $idx]
    }

    proc notebook {w args} {
	variable buttonList
	variable labelList
	variable paneList
	variable canvas
	variable focus
	variable line
	variable text

	set buttonList($w) {}
	set labelList($w)  {}
	set paneList($w)   {}
	set canvas($w)     {}
	set focus($w)      {}
	set line($w)       {}
	set text($w)       {}

	frame $w -class NoteBook
	grid row $w 0 -minsize 7
	set canvas($w) [canvas $w.__canv -width 1 -height 1]
	grid $canvas($w) -rowspan 3 -sticky nsew \
		-columnspan [expr {[llength $args]*2+2}]
	makeButtons $w $args
	selectLabel $w 0
	bind $canvas($w) <Configure> [namespace code [list drawPoly $w]]
	bind $w <Destroy> [namespace code [list cleanup $w]]
	return $w
    }

    proc pickNote {w label} {
	variable labelList

	set idx [lsearch -exact $labelList($w) $label]
	if {$idx < 0} {
	    return -code error "unknown label \"$label\""
	}
	selectLabel $w $idx
    }


# -----------------------------------------------------------------------
# Demo code
#

#pack [notebook .p Foobar Spong Wibble] \
#	    -expand 1 -fill both -padx 1m -pady 1m
#pack [button [getNote .p Foobar].foo -text foo] \
#	-fill both -expand 1 -padx 3m -pady 1m
#pack [button [getNote .p Foobar].bar -text bar] \
#	-fill both           -padx 3m -pady 1m
#pack [text   [getNote .p Wibble].wibble] \
#	-fill both -expand 1 -padx 1m -pady 3m
#pack [canvas [getNote .p Spong].spong -bg white] \
#	-fill both -expand 1 -padx 2m -pady 2m
#pickNote .p Wibble

proc tkDarkenn {color percent} {
     foreach {red green blue} [winfo rgb . $color] {
         set red [expr {($red/256)*$percent/100}]
         set green [expr {($green/256)*$percent/100}]
         set blue [expr {($blue/256)*$percent/100}]
         break
     }
     if {$red > 255} {
         set red 255
     }
     if {$green > 255} {
         set green 255
     }
     if {$blue > 255} {
         set blue 255
     }
     return [format "#%02x%02x%02x" $red $green $blue]
 }

     namespace export getNote notebook pickNote tkDarkenn
}
namespace import notebook::*

