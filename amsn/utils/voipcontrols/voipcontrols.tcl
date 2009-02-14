

package require snit
package provide tksoundmixer 0.1



snit::widget tksoundmixer {

	option -amplificationvariable -default {}
	option -amplificationcommand -default {}

	option -muteimage
	option -unmuteimage

	option -orient -default "vertical" -readonly yes

	component volumeframe
	component mutecheckbox

	delegate option -mutevariable to mutecheckbox as -variable
	delegate option -mutecommand to mutecheckbox as -command

	delegate option -from to volumeframe
	delegate option -to to volumeframe
	delegate option -levelimage to volumeframe
	delegate option -volumevariable to volumeframe
	delegate option -volumecommand to volumeframe

	delegate method setVolume to volumeframe

	delegate option * to hull

	constructor {args} {
		puts [array names options]
		puts "-orient=$options(-orient)"

		set volumeframe [tksoundmixervolume ${win}.volumeframe]
		$self configurelist $args
		#creating volumeframe again since $options(-orient) is not set yet and the component must exist when configurelist is called...
		destroy $volumeframe
		set volumeframe [tksoundmixervolume ${win}.volumeframe -orient $options(-orient)]
		set buttonframe [frame ${win}.buttonframe]

		$self configurelist $args
		
		set mutecheckbox [checkbutton ${buttonframe}.mute]


		pack $mutecheckbox
		if { $options(-orient) == "vertical" } {
			place $volumeframe -width 10 -relheight 1
			place $buttonframe -x 10 -width 15 -relheight 1
		} else {
			place $volumeframe -height 10 -relwidth 1
			place $buttonframe -y 10 -height 15 -relwidth 1
		}
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

	option -orient -default "vertical" -readonly yes

	delegate option * to hull

	constructor {args} {

		$self configurelist $args
		puts "-orient=$options(-orient)"

		frame ${win}.fill
		place ${win}.fill -relheight 1 -relwidth 1

		frame ${win}.level -background black

		if {[info exists ::$options(-volumevariable)] && [set ::$options(-volumevariable)]<1 && [set ::$options(-volumevariable)] >0} {
			if { $options(-orient) == "vertical" } {
				place ${win}.level -relx 0 -rely [expr {1-[set ::$options(-volumevariable)]}] -relwidth 1 -height $options(-levelsize)
			} else {
				place ${win}.level -rely 0 -relx [set ::$options(-volumevariable)] -relheight 1 -width $options(-levelsize)
			}
		} else {
			if { $options(-orient) == "vertical" } {
				place ${win}.level -relx 0 -rely 0.5 -relwidth 1 -height $options(-levelsize)
			} else {
				place ${win}.level -rely 0 -relx 0.5 -relheight 1 -width $options(-levelsize)
			}
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
		if { $options(-orient) == "vertical" } {
			set size [winfo height ${win}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel [expr {1-[set ::$options(-volumevariable)]}]
		} else {
			set size [winfo width ${win}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel [set ::$options(-volumevariable)]
		}
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
		if { $options(-orient) == "vertical" } {
			place configure ${win}.level -rely $rel
		} else {
			place configure ${win}.level -relx $rel
		}

		if {[info exists ::$options(-volumevariable)]} {
			if { $options(-orient) == "vertical" } {
				set ::$options(-volumevariable) [expr {1-$rel/$max}]
				if { $options(-volumecommand) != {} } {
					eval $options(-volumecommand) [expr {1-$rel/$max}]
				}
			} else {
				set ::$options(-volumevariable) [expr {$rel/$max}]
				if { $options(-volumecommand) != {} } {
					eval $options(-volumecommand) [expr {$rel/$max}]
				}
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

		if { $options(-orient) == "vertical" } {
			set size [winfo height ${win}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel [expr {double([winfo pointery ${win}] - [winfo rooty ${win}])/double(${size})}]
		} else {
			set size [winfo width ${win}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel [expr {double([winfo pointerx ${win}] - [winfo rootx ${win}])/double(${size})}]
		}

		if {$rel > $max} {
			set rel $max
		} else {
			if {$rel < 0} {
				set rel 0
			}
		}

		if { $options(-orient) == "vertical" } {
			place configure ${win}.level -rely $rel
		} else {
			place configure ${win}.level -relx $rel
		}

		if {[info exists ::$options(-volumevariable)]} {
			if { $options(-orient) == "vertical" } {
				set ::$options(-volumevariable) [expr {1-$rel/$max}]
				if { $options(-volumecommand) != {} } {
					eval $options(-volumecommand) [expr {1-$rel/$max}]
				}
			} else {
				set ::$options(-volumevariable) [expr {$rel/$max}]
				if { $options(-volumecommand) != {} } {
					eval $options(-volumecommand) [expr {$rel/$max}]
				}
			}
		}
	}

	method SetLevelSize {option value} {
		set options($option) $value
		if { $options(-orient) == "vertical" } {
			${win}.level configure -height $value
		} else {
			${win}.level configure -width $value
		}
	}


	method setVolume {value {range 100}} {
		set relsize [expr {double($value)/double($range)}]
		set volumePercent $value
		set volumeRange $range

		if { $options(-orient) == "vertical" } {
			place conf $win.fill -relheight $relsize
			place conf $win.fill -rely [expr {1-$relsize}]
		} else {
			place conf $win.fill -relwidth $relsize
		}
		
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


