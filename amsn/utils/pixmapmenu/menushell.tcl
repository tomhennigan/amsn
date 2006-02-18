snit::widget menushell {
	hulltype toplevel

	delegate option * to menu
	delegate method * to menu except { post unpost }

	component menu

	constructor { args } {
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

snit::widget menubar {
	hulltype frame

	delegate option * to menu
	delegate method * to menu

	component menu

	constructor { args } {
		install menu using pixmapmenu $self.m -orient horizontal -type menubar
		pack $menu -expand true -fill both

		# Bindings
		#bindtags $self "Pixmapmenu . all"
	}
}