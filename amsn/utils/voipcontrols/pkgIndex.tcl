package ifneeded voipcontrols 0.1 [ format {
	set olddir [pwd]
	cd "%s"
	source [file join voipcontrols.tcl]
	cd $olddir
} [list $dir]]
