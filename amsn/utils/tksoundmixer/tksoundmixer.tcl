

package require snit
package provide tksoundmixer 0.1


snit::widget tksoundmixer {

	variable frame
	variable progressPercent
	variable progressRange
	variable deltaY
	variable varname

	option -from -default 0
	option -to -default 100
	option -orient -default "vertical"

	option -width -default 15 -configuremethod SetWidth
	option -levelheight -default 5 -configuremethod SetLevelHeight
	option -height -default 150 -configuremethod SetHeight
	option -variable -default {}

	constructor {args} {
		set frame [frame ${win}.mainframe]
		pack $frame

		$self configurelist $args

		#add abbreviations
		if { ($options(-orient) == "v") || ($options(-orient) == "vert") } {
			set options(-orient) "vertical"
		}

		if { $options(-orient) == "vertical" } {
			set orientation "vertical"
		} else {
			set orientation "horizontal"
		}

		frame ${frame}.fill
		place ${frame}.fill -x 0 -y 0 -relheight 1 -relwidth 1

		frame ${frame}.level -background black
		if {[info exists ::$options(-variable)] && [set ::$options(-variable)]<1 && [set ::$options(-variable)] >0} {
			place ${frame}.level -relx 0 -rely [expr {1-[set ::$options(-variable)]}] -relwidth 1 -height $options(-levelheight)
		} else {
			place ${frame}.level -relx 0 -rely 0.5 -relwidth 1 -height $options(-levelheight)
		}

		bind ${frame}.level <B1-Motion> "$self Motion"
	}

	destructor {
	}

	method Motion {} {
		set height [winfo height ${frame}]
		set max [expr {1-double($options(-levelheight))/double(${height})}]
		set rely [expr {double([winfo pointery ${frame}] - [winfo rooty ${frame}])/double(${height})}]
		if {$rely > $max} {
			set rely $max
		} else {
			if {$rely < 0} {
				set rely 0
			}
		}
		place configure ${frame}.level -rely $rely
		if {[info exists ::$options(-variable)]} {
			set ::$options(-variable) [expr {1-$rely/$max}]
		}
	}

	method SetLevelHeight {options value} {
		set options($option) $value
		${frame}.level configure -height $value
	}

	method SetWidth {option value} {
		set options($option) $value
		${frame} configure -width $value
		#update
		if {[winfo exists ${frame}.level]} {
			$self Motion
			$self SetProgress $progressPercent $progressRange
		}
	}

	method SetHeight {option value} {
		set options($option) $value
		${frame} configure -height $value
		#update
		if {[winfo exists ${frame}.level]} {
			$self Motion
			$self SetProgress $progressPercent $progressRange
		}
	}

	method SetProgress {value {range 100}} {
		set relsize [expr {double($value)/double($range)}]
		set progressPercent $value
		set progressRange $range
		if { $options(-orient) == "vertical" } {
			place conf $frame.fill -relheight $relsize
			place conf $frame.fill -rely [expr {1-$relsize}]
		} else {
			#TODO: check
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


