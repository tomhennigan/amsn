

package require snit
package provide tksoundmixer 0.1

#TODO: use components
#TODO: be able to change the mixer position if the var pointed by "-variable" change

snit::widget tksoundmixer {

	variable frame
	variable volumePercent
	variable volumeRange
	variable deltaY
	variable varname

	option -from -default 0
	option -to -default 100
	option -orient -default "vertical" -configuremethod SetOrient

	option -width -default 15 -configuremethod SetWidth
	option -levelsize -default 5 -configuremethod SetLevelSize
	option -height -default 150 -configuremethod SetHeight
	option -variable -default {}

	constructor {args} {
		set frame [frame ${win}.mainframe]
		pack $frame

		$self configurelist $args

		frame ${frame}.fill
		place ${frame}.fill -x 0 -y 0 -relheight 1 -relwidth 1

		frame ${frame}.level -background black
		if {[info exists ::$options(-variable)] && [set ::$options(-variable)]<1 && [set ::$options(-variable)] >0} {
			if { $options(-orient) == "vertical" } {
				place ${frame}.level -relx 0 -rely [expr {1-[set ::$options(-variable)]}] -relwidth 1 -height $options(-levelsize)
			} else {
				place ${frame}.level -rely 0 -relx [set ::$options(-variable)] -relheight 1 -width $options(-levelsize)
			}
		} else {
			if { $options(-orient) == "vertical" } {
				place ${frame}.level -relx 0 -rely 0.5 -relwidth 1 -height $options(-levelsize)
			} else {
				place ${frame}.level -rely 0 -relx 0.5 -relheight 1 -width $options(-levelsize)
			}
		}

		bind ${frame}.level <B1-Motion> "$self Motion"
	}

	destructor {
	}

	method Motion {} {
		if { $options(-orient) == "vertical" } {
			set size [winfo height ${frame}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel [expr {double([winfo pointery ${frame}] - [winfo rooty ${frame}])/double(${size})}]
		} else {
			set size [winfo width ${frame}]
			set max [expr {1-double($options(-levelsize))/double(${size})}]
			set rel [expr {double([winfo pointerx ${frame}] - [winfo rootx ${frame}])/double(${size})}]
		}
		if {$rel > $max} {
			set rel $max
		} else {
			if {$rel < 0} {
				set rel 0
			}
		}
		if { $options(-orient) == "vertical" } {
			place configure ${frame}.level -rely $rel
		} else {
			place configure ${frame}.level -relx $rel
		}
		if {[info exists ::$options(-variable)]} {
			if { $options(-orient) == "vertical" } {
				set ::$options(-variable) [expr {1-$rel/$max}]
			} else {
				set ::$options(-variable) [expr {$rel/$max}]
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
			${frame}.level configure -height $value
		} else {
			${frame}.level configure -width $value
		}
	}

	method SetWidth {option value} {
		set options($option) $value
		${frame} configure -width $value
		#update
		if {[winfo exists ${frame}.level]} {
			$self Motion
			$self SetVolume $volumePercent $volumeRange
		}
	}

	method SetHeight {option value} {
		set options($option) $value
		${frame} configure -height $value
		#update
		if {[winfo exists ${frame}.level]} {
			$self Motion
			$self SetVolume $volumePercent $volumeRange
		}
	}

	method SetVolume {value {range 100}} {
		set relsize [expr {double($value)/double($range)}]
		set volumePercent $value
		set volumeRange $range
		if { $options(-orient) == "vertical" } {
			place conf $frame.fill -relheight $relsize
			place conf $frame.fill -rely [expr {1-$relsize}]
		} else {
			place conf $frame.fill -relwidth $relsize
		}
		
		if {[expr $relsize > 0.5]} {
			set R e1
			binary scan [binary format i [expr {int(2*(1.0-$relsize)*225)}]] H2 G
		} else {
			set G e1
			binary scan [binary format i [expr {int(2*$relsize*225)}]] H2 R
		}
		set B 00
		${frame}.fill configure -background \#${R}${G}${B}
    }
}


