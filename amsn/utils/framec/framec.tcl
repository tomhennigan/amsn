#-----------------------------------------------------------------------
#	TITLE:
#		framec.tcl
#
#	AUTHOR:
#		Arieh Schneier
#
#	DESCRIPTION:
#		Widget adaptor to add a coloured frame around a widget.
#		Default widget if not specified is a frame.
#
#-----------------------------------------------------------------------
#	SYNOPSIS:
#		framec pathName ?options?
#	STANDARD OPTIONS
#		(all options available to 'type')
#	WIDGET SPECIFIC OPTIONS
#		-background or -bg
#		-bordercolor or -bc
#		-borderwidth or -bw
#		-innerpadx
#		-innerpady
#		-type
#	STANDARD COMMANDS
#		(all commands available to 'type')
#	WIDGET SPECIFIC COMMANDS
#		pathname configure ?option? ?value? ...
#		pathname cget option
#		pathname getinnerframe
#		(other standard snit commands)
#-----------------------------------------------------------------------

package require snit
package provide framec 0.2

snit::widget framec {
	component padding
	component inner

	option -bordercolor -default #000000 -cgetmethod getOption -configuremethod changeBorderColor
	option -bc -cgetmethod getOption -configuremethod changeBorderColor
	option -borderwidth -default 1 -cgetmethod getOption -configuremethod changeBorderWidth
	option -bd -cgetmethod getOption -configuremethod changeBorderWidth
	option -background -default #ffffff -cgetmethod getOption -configuremethod changeBackground
	option -bg -cgetmethod getOption -configuremethod changeBackground
	option -innerpadx -default 0 -cgetmethod getOption -configuremethod changePadWidthx
	option -innerpady -default 0 -cgetmethod getOption -configuremethod changePadWidthy
	option -class
	option -type

	delegate option * to inner except {-bordercolor -bc -borderwidth -bd -background -bg -padwidth -type -class}
	delegate method * to inner

	constructor {args} {
		#check for type and class
		set itstype frame
		set itsclass ""
		foreach {option value} $args {
			if { [string equal $option "-type"] } {
				set itstype $value
			} elseif { [string equal $option "-class"] } {
				set itsclass $value
			}
		}

		$hull configure -background $options(-bordercolor) -relief solid -borderwidth 0
		install padding using frame $win.padding_%AUTO% -background $options(-background) -relief solid -borderwidth 0
		if { $itsclass == "" } {
			install inner using $itstype $win.inner -borderwidth 0
		} else {
			install inner using $itstype $win.inner -class $itsclass -borderwidth 0
		}

		pack $padding -padx $options(-borderwidth) -pady $options(-borderwidth) -expand true -fill both
		pack $inner -padx $options(-innerpadx) -pady $options(-innerpady) -expand true -fill both -in $padding

		# Apply any options passed at creation time.
		$self configurelist $args
	}

	method getOption {option} {
		if { [string equal $option "-bd"] } {
			set option "-borderwidth"
		} elseif { [string equal $option "-bg"] } {
			set option "-background"
		} elseif { [string equal $option "-bc"] } {
			set option "-bordercolor"
		}

		return $options($option)
	}

	method changeBorderColor {option value} {
		set options(-bordercolor) $value
		$hull configure -background $value
	}

	method changeBorderWidth {option value} {
		set options(-borderwidth) $value
		pack configure $padding -padx $value -pady $value
	}

	method changeBackground {option value} {
		set options(-background) $value
		$padding configure -background $value
		$inner configure -background $value
	}

	method changePadWidthx {option value} {
		set options(-innerpadx) $value
		pack configure $inner -padx $value
	}

	method changePadWidthy {option value} {
		set options(-innerpady) $value
		pack configure $inner -pady $value
	}

	method getinnerframe {} {
		return $inner
	}
}
