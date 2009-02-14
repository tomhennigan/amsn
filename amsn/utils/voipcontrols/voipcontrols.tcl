

package require snit
package provide voipcontrols 0.1

#TODO: -bg/fg


snit::widget voipcontrol {

	option -amplificationvariable -default {}
	option -amplificationcommand -default {}

	option -orient -default "vertical" -readonly yes

	option -volumeframesize -default 10 -readonly yes
	option -buttonframesize -default 22 -readonly yes

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

	delegate option -from to volumeframe
	delegate option -to to volumeframe
	delegate option -levelimage to volumeframe
	delegate option -volumevariable to volumeframe
	delegate option -volumecommand to volumeframe

	delegate method setVolume to volumeframe

	delegate option * to hull

	constructor {args} {

		set volumeframe [soundmixervolume ${win}.volumeframe]
		set buttonframe [frame ${win}.buttonframe]
		set mutecheckbutton [mutecheckbutton ${buttonframe}.mute]
		set endcallbutton [button ${buttonframe}.endcall]
		set amplificationbutton [button ${buttonframe}.amplification]

		$self configurelist $args
		#creating volumeframe again since $options(-orient) is not set yet and the component must exist when configurelist is called...
		destroy $volumeframe
		set volumeframe [soundmixervolume ${win}.volumeframe -orient $options(-orient)]
		$self configurelist $args

		if { $options(-orient) == "vertical" } {
			pack $mutecheckbutton $endcallbutton $amplificationbutton
			place $volumeframe -width $options(-volumeframesize) -relheight 1
			place $buttonframe -x $options(-volumeframesize) -width $options(-buttonframesize) -relheight 1
		} else {
			pack $mutecheckbutton $endcallbutton $amplificationbutton -side right
			place $volumeframe -height $options(-volumeframesize) -relwidth 1
			place $buttonframe -y $options(-volumeframesize) -height $options(-buttonframesize) -relwidth 1
		}
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
		
		set muted 1

		if {[info exists ::$options(-mutevariable)]} {
			set muted [set ::$options(-mutevariable)]
		}
		puts "unmuteimage=$options(-unmuteimage)"
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
		puts "ooooooo"
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

	variable volumePercent
	variable volumeRange
	variable deltaY
	variable varname

	option -from -default 0
	option -to -default 100


	#option -levelimage -configuremethod SetLevelImage; #TODO
	option -levelsize -default 5 -configuremethod SetLevelSize

	option -volumevariable -default {}
	option -volumecommand -default {}

	option -orient -default "vertical" -readonly yes

	delegate option * to hull

	constructor {args} {

		$self configurelist $args

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


