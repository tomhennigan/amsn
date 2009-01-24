

package require snit
package provide tksoundmixer 0.1

#TODO: mute/unmute?

snit::widget tksoundmixer {

	variable volumePercent
	variable volumeRange
	variable deltaY
	variable varname

	option -from -default 0
	option -to -default 100
	option -orient -default "vertical" -configuremethod SetOrient

	option -levelsize -default 5 -configuremethod SetLevelSize
	option -levelvariable -default {}

	delegate option * to hull

	constructor {args} {

		$self configurelist $args

		frame ${win}.fill
		place ${win}.fill -x 0 -y 0 -relheight 1 -relwidth 1

		frame ${win}.level -background black
		if {[info exists ::$options(-levelvariable)] && [set ::$options(-levelvariable)]<1 && [set ::$options(-levelvariable)] >0} {
			if { $options(-orient) == "vertical" } {
				place ${win}.level -relx 0 -rely [expr {1-[set ::$options(-levelvariable)]}] -relwidth 1 -height $options(-levelsize)
			} else {
				place ${win}.level -rely 0 -relx [set ::$options(-levelvariable)] -relheight 1 -width $options(-levelsize)
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
		puts $up
		if { $options(-orient) == "vertical" } {
			set size [winfo height ${win}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel [expr {1-[set ::$options(-levelvariable)]}]
		} else {
			set size [winfo width ${win}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel [set ::$options(-levelvariable)]
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
		if {[info exists ::$options(-levelvariable)]} {
			if { $options(-orient) == "vertical" } {
				set ::$options(-levelvariable) [expr {1-$rel/$max}]
			} else {
				set ::$options(-levelvariable) [expr {$rel/$max}]
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
		if {[info exists ::$options(-levelvariable)]} {
			if { $options(-orient) == "vertical" } {
				set ::$options(-levelvariable) [expr {1-$rel/$max}]
			} else {
				set ::$options(-levelvariable) [expr {$rel/$max}]
			}
		}
	}

	method SetOrient {option value} {
		set options($option) $value
		if { ($options(-orient) == "v") || ($options(-orient) == "vert") } {
			set options(-orient) "vertical"
		}
		if { ($options(-orient) == "h") || ($options(-orient) == "hori") } {
			set options(-orient) "horizontal"
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

	method SetVolume {value {range 100}} {
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


