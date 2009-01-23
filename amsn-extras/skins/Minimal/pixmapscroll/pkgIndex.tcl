package ifneeded pixmapscroll 0.9 [ format {
	set olddir [pwd]
	cd "%s"
	source [file join pixmapscroll.tcl]
	cd $olddir
} [list $dir]]
