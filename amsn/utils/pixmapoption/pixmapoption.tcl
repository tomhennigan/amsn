package require snit
package provide pixmapoption 0.1

snit::widgetadaptor pixmapradio {

	component button

	delegate option * to button except { -buttontype -hoverimage }
	delegate method * to button except { setType }

	constructor { args } {
		installhull using frame
		
		set normal [image create photo -file radio.gif]
		set hover [image create photo -file radiohover.gif]
		set pressed [image create photo -file radiopress.gif]

		install button using radiobutton $win.radiobutton -relief solid \
			-compound left \
			-highlightthickness 5 \
			-borderwidth 0 \
			-background [[winfo parent $self] cget -background] \
			-activebackground [[winfo parent $self] cget -background] \
			-selectcolor [[winfo parent $self] cget -background] \
			-indicatoron 0 \
			-image $normal \
			-selectimage $pressed

		$self configurelist $args
		bind $self <Leave> "$button configure -image $normal"
		bind $self <Enter> "$button configure -image $hover"
		pack $button -side left -padx 5
	}

}

snit::widgetadaptor pixmapcheck {

	component button

	delegate option * to button
	delegate method * to button

	constructor { args } {
		installhull using frame
		
		set normal [image create photo -file check.gif]
		set hover [image create photo -file checkhover.gif]
		set pressed [image create photo -file checkpress.gif]

		install button using checkbutton $win.radiobutton -relief solid \
			-compound left \
			-highlightthickness 5 \
			-borderwidth 0 \
			-background [[winfo parent $self] cget -background] \
			-activebackground [[winfo parent $self] cget -background] \
			-selectcolor [[winfo parent $self] cget -background] \
			-indicatoron 0 \
			-image $normal \
			-selectimage $pressed

		$self configurelist $args
		bind $self <Leave> "$button configure -image $normal"
		bind $self <Enter> "$button configure -image $hover"
		bind $self <Button-1> "$button toggle"
		pack $button -side left -padx 5
	}

}