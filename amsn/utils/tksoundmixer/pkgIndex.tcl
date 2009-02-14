package ifneeded voipcontrol 0.1 [ format {
	set olddir [pwd]
	cd "%s"
	source [file join tksoundmixer.tcl]
	cd $olddir
} [list $dir]]
