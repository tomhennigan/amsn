snit::widgetadaptor menushell {
	delegate option * to menu
	delegate method * to menu except { post unpost }

	component menu

	constructor { args } {
		installhull using toplevel -class Menu
		wm withdraw $self
		wm overrideredirect $self 1
		install menu using pixmapmenu $self.m -type normal
		pack $menu -expand true -fill both

		# Bindings
		#bindtags $self "Pixmapmenu . all"
	}

	method post { x y } {
		wm geometry $self +${x}+${y}
		wm deiconify $self
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
		installhull using frame -class Menu
		install menu using pixmapmenu $self.m -orient horizontal -type menubar
		pack $menu -expand true -fill both

		# Bindings
		#bindtags $self "Pixmapmenu . all"
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

proc optmenu { w var args } {
	puts $args
	menubutton $w -menu $w.menu -relief raised -textvariable $var
	menu $w.menu
	foreach val $args {
		$w.menu add radiobutton -label $val -variable $var -value $val
		puts $val
	}
	return $w.menu
}