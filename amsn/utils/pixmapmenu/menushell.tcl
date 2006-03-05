snit::widgetadaptor menushell {
	delegate option * to menu
	delegate method * to menu except { post unpost }

	component menu

	constructor { args } {
		installhull using toplevel -class Menu -borderwidth 0 -highlightthickness 0 -padx 0 -pady 0 -relief flat
		wm withdraw $self
		wm transient $self [winfo parent $self]
		wm overrideredirect $self 1
		install menu using pixmapmenu $self.m -type normal
		pack $menu -expand true -fill both 
		bindtags $self ". all"
	}

	method post { x y } {
		if { [expr {$x + [$self cget -width]}] > [winfo screenwidth $self] } {
			set x [expr {[winfo screenwidth $self] - [$self cget -width]}]
		}
		if { [expr {$y + [$self cget -height]}] > [winfo screenheight $self] } {
			set y [expr {[winfo screenheight $self] - [$self cget -height]}]
		}
		wm geometry $self +${x}+${y}
		wm deiconify $self
		raise $self
	}

	method unpost { } {
		wm withdraw $self
	}
}

snit::widgetadaptor menubar {
	delegate option * to menu
	delegate method * to menu

	component menu

	constructor { args } {
		installhull using frame -class Menu -borderwidth 0 -highlightthickness 0 -padx 0 -pady 0 -relief flat
		install menu using pixmapmenu $self.m -orient horizontal -type menubar
		pack $menu -expand true -fill both
		bindtags $self ". all"
	}
}

snit::widgetadaptor menubut {
	option -type -default menubutton -readonly yes

	delegate option * to hull

	constructor { args } {
		installhull using tk_menubutton
		$self configurelist $args
	}
}

proc OptionMenu { w var args } {
	puts $args
	menubutton $w -menu $w.menu -relief raised -textvariable $var
	menu $w.menu
	foreach val $args {
		$w.menu add radiobutton -indicatoron 0 -label $val -variable $var -value $val
		puts $val
	}
	return $w.menu
}
