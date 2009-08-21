

package require snit
package provide voipcontrols 0.1

snit::widget voipcontrol {

	option -orient -default "vertical" -readonly yes

	option -mixerframesize -default 10 -readonly yes
	option -buttonframesize -default 22 -readonly yes

	option -bg -default white -configuremethod SetBackground
	option -state -default normal -configuremethod SetState


	component mixerframe
	component mutecheckbutton
	component endcallbutton


	delegate option -endcallimage to endcallbutton as -image
	delegate option -endcallcommand to endcallbutton as -command
	delegate option -endcallstate to endcallbutton as -state

	delegate option -mutedimage to mutecheckbutton
	delegate option -unmutedimage to mutecheckbutton
	delegate option -mutevariable to mutecheckbutton
	delegate option -mutecommand to mutecheckbutton
	delegate option -mutestate to mutecheckbutton as -state

	delegate option -volumefrom to mixerframe
	delegate option -volumeto to mixerframe
	delegate option -levelfrom to mixerframe
	delegate option -levelto to mixerframe
	delegate option -volumevariable to mixerframe as -variable
	delegate option -volumecommand to mixerframe as -command
	delegate option -volumestate to mixerframe as -state

	delegate method setLevel to mixerframe

	delegate method Mute to mutecheckbutton
	delegate method UnMute to mutecheckbutton

	delegate option * to hull

	constructor {args} {

		set mixerframe [voipmixer ${win}.mixerframe]
		set buttonframe [frame ${win}.buttonframe]
		set mutecheckbutton [mutecheckbutton ${buttonframe}.mute]
		set endcallbutton [button ${buttonframe}.endcall -relief flat -image {}]

		$self configurelist $args
		#creating mixerframe again since $options(-orient) is not set yet and the component must exist when configurelist is called...
		destroy $mixerframe
		set mixerframe [voipmixer ${win}.mixerframe -orient $options(-orient) -mutecheckbutton $mutecheckbutton]
		$self configurelist $args

		if { $options(-orient) == "vertical" } {
			pack $mutecheckbutton $endcallbutton
			place $mixerframe -width $options(-mixerframesize) -relheight 1
			place $buttonframe -x $options(-mixerframesize) -width $options(-buttonframesize) -relheight 1
		} else {
			pack $mutecheckbutton $endcallbutton -side right
			place $mixerframe -height $options(-mixerframesize) -relwidth 1
			place $buttonframe -y $options(-mixerframesize) -height $options(-buttonframesize) -relwidth 1
		}
	}


	method SetBackground {option value} {
		set options($option) $value
		$win configure -background $value
		$mixerframe configure -background $value
		$win.buttonframe configure -background $value
		$mutecheckbutton configure -background $value
		$win.buttonframe.endcall configure -background $value
	}

	method SetState {option value} {
		set options($option) $value
		$mixerframe configure -state $value
		$endcallbutton configure -state $value
		$mutecheckbutton configure -state $value
	}

	method getSize {} {
		set size $options(-mixerframesize)
		incr size $options(-buttonframesize)
		return $size
	}
}


snit::widgetadaptor mutecheckbutton {

	variable muted

	option -mutedimage -default {} -configuremethod SetImage
	option -unmutedimage -default {} -configuremethod SetImage
	option -mutevariable -default {}
	option -mutecommand -default {}

	delegate option * to hull
	delegate method * to hull

	constructor {args} {

		installhull using button -relief flat -image {} -command [list $self invoke]

		$self configurelist $args
		
		set muted 0

		if {[info exists ::$options(-mutevariable)]} {
			if {[set ::$options(-mutevariable)]} {
				set muted 1
			} else {
				set muted 0
			}
		}
		$self configure -image $options(-unmutedimage)
	}

	method SetImage {option value} {
		set options($option) $value
		if {$muted} {
			$self configure -image $options(-mutedimage)
		} else {
			$self configure -image $options(-unmutedimage)
		}
	}

	method Mute {} {
		if {!$muted} {
			$self configure -image $options(-mutedimage)
			set muted 1

			if {[info exists ::$options(-mutevariable)]} {
				set ::$options(-mutevariable) $muted
			}
			if { $options(-mutecommand) != {} } {
				eval $options(-mutecommand)
			}
		}
	}

	method UnMute {} {
		if {$muted} {
			$self configure -image $options(-unmutedimage)
			set muted 0

			if {[info exists ::$options(-mutevariable)]} {
				set ::$options(-mutevariable) $muted
			}
			if { $options(-mutecommand) != {} } {
				eval $options(-mutecommand)
			}
		}
	}

	method invoke {} {
		if {$muted} {
			$self configure -image $options(-unmutedimage)
			set muted 0
		} else {
			$self configure -image $options(-mutedimage)
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




snit::widget voipmixer {

	option -mutecheckbutton -readonly yes -default ""
	option -volumefrom -default -25
	option -volumeto -default 15
	option -levelfrom -default -20
	option -levelto -default 0

	option -selectsize -default 5 -configuremethod SetSelectSize

	option -variable -default {} -configuremethod SetVariable
	option -command -default {}

	option -orient -default "vertical" -readonly yes

	option -state -default normal

	delegate option * to hull

	constructor {args} {

		frame ${win}.fill
		place ${win}.fill -relheight 1 -relwidth 1

		frame ${win}.select -background black

		$self configurelist $args

		bind ${win}.select <B1-Motion> "$self Motion"

		if {![catch {tk windowingsystem} wsystem] && $wsystem != "x11"} {
			bind ${win} <MouseWheel> "$self MouseWheel"
			bind ${win}.fill <MouseWheel> "$self MouseWheel"
			bind ${win}.select <MouseWheel> "$self MouseWheel"
		} else {
			bind ${win} <ButtonPress-5> "$self MoveSelect 0"
			bind ${win}.fill <ButtonPress-5> "$self MoveSelect 0"
			bind ${win}.select <ButtonPress-5> "$self MoveSelect 0"
			bind ${win} <ButtonPress-4> "$self MoveSelect 1"
			bind ${win}.fill <ButtonPress-4> "$self MoveSelect 1"
			bind ${win}.select <ButtonPress-4> "$self MoveSelect 1"
		}
	}


	method MoveSelect {{up 1}} {
		if { $options(-state) != "normal"} {return}

		set val [expr {double([set ::$options(-variable)]) - double($options(-volumefrom))}]
		set val [expr {$val / (double($options(-volumeto)) - double($options(-volumefrom)))}]

		if {$up == 1} {
			set val [expr {$val + 0.1}]
		} else {
			set val [expr {$val - 0.1}]
		}

		if { $options(-orient) == "vertical" } {
			set size [winfo height ${win}]
			set max [expr {1-double($options(-selectsize))/double(${size})}]
			set rel [expr {1-$val}]
		} else {
			set size [winfo width ${win}]
			set max [expr {1-double($options(-selectsize))/double(${size})}]
			set rel $val
		}
		if {$rel > $max} {
			set rel $max
		} else {
			if {$rel < 0} {
				set rel 0
			}
		}

		if { $options(-mutecheckbutton) != ""} {
			if { $options(-orient) == "vertical" } {
				if {$rel >= 0.95} {
					$options(-mutecheckbutton) Mute
				} else {
					$options(-mutecheckbutton) UnMute
				}
			} else {
				if {$rel <= 0.05} {
					$options(-mutecheckbutton) Mute
				} else {
					$options(-mutecheckbutton) UnMute
				}
			}
		}

		if { $options(-orient) == "vertical" } {
			place configure ${win}.select -rely $rel
		} else {
			place configure ${win}.select -relx $rel
		}

		if {[info exists ::$options(-variable)]} {
			if { $options(-orient) == "vertical" } {
				set val [expr {1-$rel/$max}]
				set val [expr {$options(-volumefrom) + $val * ($options(-volumeto) - $options(-volumefrom))}]
				set ::$options(-variable) $val
				if { $options(-command) != {} } {
					eval $options(-command) $val
				}
			} else {
				set val [expr {$rel/$max}]
				set val [expr {$options(-volumefrom) + $val * ($options(-volumeto) - $options(-volumefrom))}]
				set ::$options(-variable) $val
				if { $options(-command) != {} } {
					eval $options(-command) $val
				}
			}
		}
	}


	method MouseWheel {} {
		if {%D>0} {
			$self MoveSelect 1
		} else {
			$self MoveSelect 0
		}
	}

	method Motion {} {
		if { $options(-state) != "normal"} {return}

		if { $options(-orient) == "vertical" } {
			set size [winfo height ${win}]
			set max [expr {1-double($options(-selectsize))/double(${size})}]
			set rel [expr {double([winfo pointery ${win}] - [winfo rooty ${win}])/double(${size})}]
		} else {
			set size [winfo width ${win}]
			set max [expr {1-double($options(-selectsize))/double(${size})}]
			set rel [expr {double([winfo pointerx ${win}] - [winfo rootx ${win}])/double(${size})}]
		}

		if {$rel > $max} {
			set rel $max
		} else {
			if {$rel < 0} {
				set rel 0
			}
		}


		if { $options(-mutecheckbutton) != "" } {
			if { $options(-orient) == "vertical" } {
				if {$rel >= 0.95} {
					$options(-mutecheckbutton) Mute
				} else {
					$options(-mutecheckbutton) UnMute
				}
			} else {
				if {$rel <= 0.05} {
					$options(-mutecheckbutton) Mute
				} else {
					$options(-mutecheckbutton) UnMute
				}
			}
		}

		if { $options(-orient) == "vertical" } {
			place configure ${win}.select -rely ${rel}
		} else {
			place configure ${win}.select -relx ${rel}
		}

		if {[info exists ::$options(-variable)]} {
			if { $options(-orient) == "vertical" } {
				set val [expr {1-$rel/$max}]
				set val [expr {$options(-volumefrom) + $val * ($options(-volumeto) - $options(-volumefrom))}]
				set ::$options(-variable) $val
				if { $options(-command) != {} } {
					eval $options(-command) $val
				}
			} else {
				set val [expr {$rel/$max}]
				set val [expr {$options(-volumefrom) + $val * ($options(-volumeto) - $options(-volumefrom))}]
				set ::$options(-variable) $val
				if { $options(-command) != {} } {
					eval $options(-command) $val
				}
			}
		}
	}

	method SetSelectSize {option value} {
		set options($option) $value
		if { $options(-orient) == "vertical" } {
			${win}.select configure -height $value
			place ${win}.select -height $value
		} else {
			${win}.select configure -width $value
			place ${win}.select -width $value
		}
	}

	method SetVariable { option value} {
		set options($option) $value

		if {![info exists ::$options(-variable)]
			|| [set ::$options(-variable)] > $options(-volumeto)
			|| [set ::$options(-variable)] < $options(-volumefrom)} {
			set ::$options(-variable) [expr {$options(-volumefrom) + 0.5 * (double($options(-volumeto)) - double($options(-volumefrom)))}]
		}

		set val [expr {double([set ::$options(-variable)]) - double($options(-volumefrom))}]
		set val [expr {$val / (double($options(-volumeto)) - double($options(-volumefrom)))}]
		if { $options(-orient) == "vertical" } {
			set val [expr {1-$val}]
			place ${win}.select -relx 0 -rely ${val} -relwidth 1 -height $options(-selectsize)
		} else {
			place ${win}.select -rely 0 -relx ${val} -relheight 1 -width $options(-selectsize)
		}

	}

	method setLevel {value} {
		if { $options(-state) != "normal"} {return}

		if {[expr {$value == "-inf"}] ||
		    [expr {$value == "inf"}] } { 
			set value $options(-levelfrom) 
		}

		set relsize [expr {double($value) - double($options(-levelfrom))}]
		set relsize [expr {$relsize / (double($options(-levelto)) - double($options(-levelfrom)))}]

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


