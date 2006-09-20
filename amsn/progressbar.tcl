#From Donald K. Fellows's Megawidget and Dialog Stuff
#http://www.cs.man.ac.uk/~fellowsd/tcl/mwidx.html

if { $initialize_amsn == 1 } {

    option add *Progress.undoneForeground black  widgetDefault
    option add *Progress.undoneBackground white  widgetDefault
    option add *Progress.doneForeground   white  widgetDefault
    option add *Progress.doneBackground   green4 widgetDefault
    option add *Progress.borderWidth      1      widgetDefault
    option add *Progress.relief           sunken widgetDefault
}

namespace eval dkfprogress {
    namespace export Progress SetProgress

    proc Progress {w args} {
	uplevel 1 [list frame $w -class Progress] $args

	foreach {val} {
	    undoneForeground doneForeground
	    undoneBackground doneBackground
	} {
	    set class [string toupper [string index $val 0]\
		    ][string range $val 1 end]
	    set $val [option get $w $val $class]
	}

	set varname [namespace current]::progressPercent($w)

	frame $w.l -borderwidth 0 -background $undoneBackground
	label $w.l.l -textvariable $varname -borderwidth 0 \
		-foreground black -background $undoneBackground
	$w.l configure -height [expr {int([winfo reqheight $w.l.l]+2)}]
	frame $w.l.fill -background $doneBackground
	label $w.l.fill.l -textvariable $varname -borderwidth 0 \
		-foreground black -background $doneBackground

	bind $w.l <Configure> [namespace code [list ProgressConf $w "%w"]]

	pack $w.l -fill both -expand 1
	place $w.l.l -relx 0.5 -rely 0.5 -anchor center
	place $w.l.fill -x 0 -y 0 -relheight 1 -relwidth 0
	place $w.l.fill.l -x 0 -rely 0.5 -anchor center

	SetProgress $w 0
	return $w
    }

    proc ProgressConf {w width} {
	place conf $w.l.fill.l -x [expr {int($width/2)}]
    }

    proc SetProgress {win value {range 100}} {
		if {[winfo exists $win]} {
			set progress [expr {int(double($value)/ double($range/100))}]
			set relwidth [expr {double($value)/double($range)}]
			variable progressPercent
			place conf $win.l.fill -relwidth $relwidth
			set progressPercent($win) "${progress}%"
			
			if {[expr $relwidth < 0.5]} {
				set R e1
				binary scan [binary format i [expr {int(2*$relwidth*225)}]] H2 G
			} else {
				set G e1
				binary scan [binary format i [expr {int(2*(1.0 - $relwidth)*225)}]] H2 R
			}
			set B 00
			$win.l.fill configure -background \#${R}${G}${B}
			$win.l.fill.l configure -background \#${R}${G}${B}
		}
    }
}


if { $initialize_amsn == 1 } {
    namespace import dkfprogress::Progress dkfprogress::SetProgress
}
