

package require snit
package provide tksoundmixer 0.1



snit::widget tksoundmixer {

	option -amplificationvariable -default {}
	option -amplificationcommand -default {}

	component volumeframe
	component mutecheckbox

	delegate option -mutevariable to mutecheckbox as -variable
	delegate option -mutecommand to mutecheckbox as -command

	delegate option -from to volumeframe
	delegate option -to to volumeframe
	delegate option -levelsize to volumeframe
	delegate option -volumevariable to volumeframe
	delegate option -volumecommand to volumeframe

	delegate method setVolume to volumeframe

	delegate option * to hull

	constructor {args} {

		set volumeframe [tksoundmixervolume ${win}.volumeframe]

		$self configurelist $args
		
		set mutecheckbox [checkbutton ${win}.mute -text "Mute"]


		pack ${win}.mute
		pack ${win}.volumeframe -expand true -fill both
	}
}

snit::widget tksoundmixervolume {

	variable volumePercent
	variable volumeRange
	variable deltaY
	variable varname

	option -from -default 0
	option -to -default 100

	option -levelsize -default 5 -configuremethod SetLevelSize

	option -volumevariable -default {}
	option -volumecommand -default {}

	delegate option * to hull

	constructor {args} {

		$self configurelist $args

		frame ${win}.fill
		place ${win}.fill -relheight 1 -relwidth 1

		frame ${win}.level -background black
		if {[info exists ::$options(-volumevariable)] && [set ::$options(-volumevariable)]<1 && [set ::$options(-volumevariable)] >0} {
			place ${win}.level -relx 0 -rely [expr {1-[set ::$options(-volumevariable)]}] -relwidth 1 -height $options(-levelsize)
		} else {
			place ${win}.level -relx 0 -rely 0.5 -height $options(-levelsize) -relwidth 1
		}

		bind ${win}.level <B1-Motion> "$self Motion"

		if {![catch {tk windowingsystem} wsystem] && $wsystem != "x11"} {
			bind ${win} <MouseWheel> "$self MouseWheel"
			bind ${win}.fill <MouseWheel> "$self MouseWheel"
			bind ${win}.level <MouseWheel> "$self MouseWheel"
		} else {
			bind ${win} <ButtonPress-5> "$self MoveLevel 0"
			bind ${win}.fill <ButtonPress-5> "$self MoveLevel 0"
			bind ${win}.level <ButtonPress-5> "$self MoveLevel 0"
			bind ${win} <ButtonPress-4> "$self MoveLevel 1"
			bind ${win}.fill <ButtonPress-4> "$self MoveLevel 1"
			bind ${win}.level <ButtonPress-4> "$self MoveLevel 1"
		}
	}

	destructor {
	}

	method MoveLevel {{up 1}} {
		puts $up
		set size [winfo height ${win}]
		set max [expr {1-double($options(-levelsize))/double(${size})}]
		set rel [expr {1-[set ::$options(-volumevariable)]}]
		if {$up == 1} {
			set rel [expr {$rel + 0.1}]
		} else {
			set rel [expr {$rel - 0.1}]
		}
		if {$rel > $max} {
			set rel $max
		} else {
			if {$rel < 0} {
				set rel 0
			}
		}
			place configure ${win}.level -rely $rel

		if {[info exists ::$options(-volumevariable)]} {
			set ::$options(-volumevariable) [expr {1-$rel/$max}]
			if { $options(-volumecommand) != {} } {
				eval $options(-volumecommand) [expr {1-$rel/$max}]
			}
		}
	}


	method MouseWheel {} {
		if {%D>0} {
			$self MoveLevel 1
		} else {
			$self MoveLevel 0
		}
	}

	method Motion {} {
		set size [winfo height ${win}]
		set max [expr {1-double($options(-levelsize))/double(${size})}]
		set rel [expr {double([winfo pointery ${win}] - [winfo rooty ${win}])/double(${size})}]
		if {$rel > $max} {
			set rel $max
		} else {
			if {$rel < 0} {
				set rel 0
			}
		}
		place configure ${win}.level -rely $rel
		if {[info exists ::$options(-volumevariable)]} {
			set ::$options(-volumevariable) [expr {1-$rel/$max}]
			if { $options(-volumecommand) != {} } {
				eval $options(-volumecommand) [expr {1-$rel/$max}]
			}
		}
	}

	method SetLevelSize {option value} {
		set options($option) $value
		${win}.level configure -height $value
	}

	method setVolume {value {range 100}} {
		set relsize [expr {double($value)/double($range)}]
		set volumePercent $value
		set volumeRange $range
		place conf $win.fill -relheight $relsize
		place conf $win.fill -rely [expr {1-$relsize}]
		
		if {[expr $relsize > 0.5]} {
			set R e1
			binary scan [binary format i [expr {int(2*(1.0-$relsize)*225)}]] H2 G
		} else {
			set G e1
			binary scan [binary format i [expr {int(2*$relsize*225)}]] H2 R
		}
		set B 00
		${win}.fill configure -background \#${R}${G}${B}
    }
}


