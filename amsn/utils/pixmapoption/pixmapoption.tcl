package require snit
package provide pixmapoption 0.1

snit::widgetadaptor pixmapoption {

	component button

	option -buttontype -configuremethod setType -cgetmethod getType
	option -hoverimage -configuremethod setHover -cgetmethod getHover

	delegate option * to button except { -buttontype -hoverimage }
	delegate method * to button except { setType }

	constructor { args } {
		installhull using frame
		
		$self setType -buttontype [lindex $args [expr [lsearch $args -buttontype] + 1]]

		install button using $options(-buttontype) $win.checkbutton -relief solid \
			-compound left \
			-highlightthickness 5 \
			-borderwidth 0 \
			-background [[winfo parent $self] cget -background] \
			-activebackground [[winfo parent $self] cget -background] \
			-selectcolor [[winfo parent $self] cget -background] \
			-indicatoron 0
		
		$self configurelist $args
		
		pack $button -side left -padx 5
	}

	method setHover { option value } {
		set options(-hoverimage) $value
		bind $self <Leave> "$button configure -image [$self cget -image]"
		bind $self <Enter> "$button configure -image $value"
	}

	method getHover { option } {
		return $options(-hoverimage)
	}

	method setType { option value } {
		set options(-buttontype) $value
		puts "$options(-buttontype) by setType"
	}

	method getType { option } {
		return $options(-buttontype)
	}

}
