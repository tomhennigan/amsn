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
#		framec pathName ?type? ?options?
#	STANDARD OPTIONS
#		(all options available to 'type')
#	WIDGET SPECIFIC OPTIONS
#		-background or -bg
#		-bordercolor or -bc
#		-borderwidth or -bw
#		-innerpadx
#		-innerpady
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
	component border
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

	delegate option * to inner except {-bordercolor -bc -borderwidth -bd -background -bg -padwidth}
	delegate method * to inner

	constructor {itstype args} {
		#test if type is given
		if { [string equal -length 1 $itstype "-"] } {
			set args [linsert $args 0 $itstype]
			set itstype frame
		}

		install border using frame $win.borderrr -background $options(-bordercolor) -relief solid -borderwidth 0
		install padding using frame $border.padding -background $options(-background) -relief solid -borderwidth 0
		install inner using $itstype $padding.inner -border 0

		pack $inner -side left -padx $options(-innerpadx) -pady $options(-innerpady)
		pack $padding -padx $options(-borderwidth) -pady $options(-borderwidth)
		pack $border -padx 0 -pady 0

		# Apply any options passed at creation time.
		$self configurelist $args
	}

	method getOption {option} {
		if { string equal $option "-bd" } {
			set option "-borderwidth"
		} elseif { string equal $option "-bg" } {
			set option "-background"
		} elseif { string equal $option "-bc" } {
			set option "-bordercolor"
		}

		return $options($option)
	}

	method changeBorderColor {option value} {
		set options(-bordercolor) $value
		$border configure -background $value
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
