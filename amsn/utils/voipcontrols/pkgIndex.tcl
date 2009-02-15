package ifneeded voipcontrols 0.1 [ format {
	set olddir [pwd]
	cd "%s"
	if {[catch {source [file join voipcontrols.tcl]} err]} {
		cd $olddir
		error "error while loading package voipcontrols: $err"
	} else {
		cd $olddir
	}

} [list $dir]]
