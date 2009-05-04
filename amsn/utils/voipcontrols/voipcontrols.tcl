

package require snit
package provide voipcontrols 0.1

snit::widget voipcontrol {

	option -orient -default "vertical" -readonly yes

	option -volumeframesize -default 10 -readonly yes
	option -buttonframesize -default 22 -readonly yes

	option -bg -default white -configuremethod SetBackground
	option -state -default normal -configuremethod SetState


	component volumeframe
	component mutecheckbutton
	component endcallbutton


	delegate option -endcallimage to endcallbutton as -image
	delegate option -endcallcommand to endcallbutton as -command
	delegate option -endcallstate to endcallbutton as -state

	delegate option -muteimage to mutecheckbutton
	delegate option -unmuteimage to mutecheckbutton
	delegate option -mutevariable to mutecheckbutton
	delegate option -mutecommand to mutecheckbutton
	delegate option -mutestate to mutecheckbutton as -state

	delegate option -volumefrom to volumeframe as -from
	delegate option -volumeto to volumeframe as -to
	delegate option -levelimage to volumeframe
	delegate option -volumevariable to volumeframe as -variable
	delegate option -volumecommand to volumeframe as -command
	delegate option -volumestate to volumeframe as -state

	delegate method setVolume to volumeframe

	delegate option * to hull

	constructor {args} {

		set volumeframe [soundmixervolume ${win}.volumeframe]
		set buttonframe [frame ${win}.buttonframe]
		set mutecheckbutton [mutecheckbutton ${buttonframe}.mute]
		set endcallbutton [button ${buttonframe}.endcall -relief flat]

		$self configurelist $args
		#creating volumeframe again since $options(-orient) is not set yet and the component must exist when configurelist is called...
		destroy $volumeframe
		set volumeframe [soundmixervolume ${win}.volumeframe -orient $options(-orient)]
		$self configurelist $args

		if { $options(-orient) == "vertical" } {
			pack $mutecheckbutton $endcallbutton
			place $volumeframe -width $options(-volumeframesize) -relheight 1
			place $buttonframe -x $options(-volumeframesize) -width $options(-buttonframesize) -relheight 1
		} else {
			pack $mutecheckbutton $endcallbutton -side right
			place $volumeframe -height $options(-volumeframesize) -relwidth 1
			place $buttonframe -y $options(-volumeframesize) -height $options(-buttonframesize) -relwidth 1
		}
	}


	method SetBackground {option value} {
		set options($option) $value
		$win configure -background $value
		$volumeframe configure -background $value
		$win.buttonframe configure -background $value
		$mutecheckbutton configure -background $value
		$win.buttonframe.endcall configure -background $value
	}

	method SetState {option value} {
		set options($option) $value
		$volumeframe configure -state $value
		$endcallbutton configure -state $value
		$mutecheckbutton configure -state $value
	}

	method getSize {} {
		set size $options(-volumeframesize)
		incr size $options(-buttonframesize)
		return $size
	}
}


snit::widgetadaptor mutecheckbutton {

	variable muted

	option -muteimage -default {} -configuremethod SetImage
	option -unmuteimage -default {} -configuremethod SetImage
	option -mutevariable -default {}
	option -mutecommand -default {}

	delegate option * to hull
	delegate method * to hull

	constructor {args} {

		installhull using button -relief flat

		$self configurelist $args
		
		set muted 0

		if {[info exists ::$options(-mutevariable)]} {
			if {[set ::$options(-mutevariable)]} {
				set muted 1
			} else {
				set muted 0
			}
		}
		$self configure -image $options(-unmuteimage)
	}

	method SetImage {option value} {
		set options($option) $value
		if {$muted} {
			$self configure -image $options(-unmuteimage)
			set muted 0
		} else {
			$self configure -image $options(-muteimage)
			set muted 1
		}
	}


	method invoke {} {
		if {$muted} {
			$self configure -image $options(-unmuteimage)
			set muted 0
		} else {
			$self configure -image $options(-muteimage)
			set muted 1
		}

		if {[info exists ::$options(-mutevariable)]} {
			set ::$options(-mutevariable) $muted
		}
		if { $options(-mutecommand) != {} } {
			eval $options(-mutecommand)
		}
	}
}




snit::widget soundmixervolume {

	option -from -default 0
	option -to -default 1

	option -levelsize -default 5 -configuremethod SetLevelSize

	option -variable -default {}
	option -command -default {}

	option -orient -default "vertical" -readonly yes

	option -state -default normal

	delegate option * to hull

	constructor {args} {

		$self configurelist $args

		frame ${win}.fill
		place ${win}.fill -relheight 1 -relwidth 1

		frame ${win}.level -background black

		if {![info exists ::$options(-variable)]
			|| [set ::$options(-variable)] > $options(-to)
			|| [set ::$options(-variable)] < $options(-from)} {
			set ::$options(-variable) [expr {$options(-from) + 0.5 * (double($options(-to)) - double($options(-from)))}]
		}
		set val [expr {double([set ::$options(-variable)]) - double($options(-from))}]
		set val [expr {$val / (double($options(-to)) - double($options(-from)))}]
		if { $options(-orient) == "vertical" } {
			place ${win}.level -relx 0 -rely [expr {1-[set ::$options(-variable)]}] -relwidth 1 -height $options(-levelsize)
		} else {
			place ${win}.level -rely 0 -relx [set ::$options(-variable)] -relheight 1 -width $options(-levelsize)
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
		if { $options(-state) != "normal"} {return}

		set val [expr {double([set ::$options(-variable)]) - double($options(-from))}]
		set val [expr {$val / (double($options(-to)) - double($options(-from)))}]
		if { $options(-orient) == "vertical" } {
			set size [winfo height ${win}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel [expr {1-$val}]
		} else {
			set size [winfo width ${win}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel $val
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

		if {[info exists ::$options(-variable)]} {
			if { $options(-orient) == "vertical" } {
				set val [expr {1-$rel/$max}]
				set val [expr {$options(-from) + $val * ($options(-to) - $options(-from))}]
				set ::$options(-variable) $val
				if { $options(-command) != {} } {
					eval $options(-command) $val
				}
			} else {
				set val [expr {$rel/$max}]
				set val [expr {$options(-from) + $val * ($options(-to) - $options(-from))}]
				set ::$options(-variable) $val
				if { $options(-command) != {} } {
					eval $options(-command) $val
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
		if { $options(-state) != "normal"} {return}

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

		if {[info exists ::$options(-variable)]} {
			if { $options(-orient) == "vertical" } {
				set val [expr {1-$rel/$max}]
				set val [expr {$options(-from) + $val * ($options(-to) - $options(-from))}]
				set ::$options(-variable) $val
				if { $options(-command) != {} } {
					eval $options(-command) $val
				}
			} else {
				set val [expr {$rel/$max}]
				set val [expr {$options(-from) + $val * ($options(-to) - $options(-from))}]
				set ::$options(-variable) $val
				if { $options(-command) != {} } {
					eval $options(-command) $val
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


	method setVolume {value} {
		if { $options(-state) != "normal"} {return}

		set relsize [expr {double($value) - double($options(-from))}]
		set relsize [expr {$relsize / (double($options(-to)) - double($options(-from)))}]

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


