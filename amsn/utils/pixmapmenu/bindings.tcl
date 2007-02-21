proc setupBindings {} {
	set substList [list # a b c d f h i k m o p s t w x y A B D E K N P R S T X Y]
	
	set EventList \
		[list FocusIn Enter Leave Motion ButtonPress ButtonRelease space Return Escape Left Right Up Down KeyPress]
	
	set mapping [list "%%%%" "%%"]
	foreach char $substList {
		lappend mapping "%%$char" "\[list %$char\]"
	}
	lappend mapping "%%W" { [winfo parent %W] }

	foreach event $EventList {
		set command "eval \[string map { $mapping } \[bind Menu <$event>\]\]"
		bind Pixmapmenu <$event> "$command"
	}
}

setupBindings
