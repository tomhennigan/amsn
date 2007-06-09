#
# BWidget modifications by the aMSN team
#

# Cannot 'select plugins' or open 'preferences' more than once.
# Error says the proc cannot be renamed because it already exists.
# This dirty hack checks first whether it exists already, though I think
# it should be fixed some better way (forcing me to understand this code
# better first...)
#
# See several forum topics, e.g.:
# - http://www.amsn-project.net/forums/viewtopic.php?p=11765
# - http://www.amsn-project.net/forums/viewtopic.php?t=1982
# - http://www.amsn-project.net/forums/viewtopic.php?t=1980
# and several others

::Version::setSubversionId {$Id$}

proc Widget::create { class path {rename 1} } {
    if {$rename && [llength [info procs ::$path:cmd]] == 0} { 
		rename $path ::$path:cmd 
	}
    proc ::$path { cmd args } \
    	[subst {return \[eval \[linsert \$args 0 ${class}::\$cmd [list $path]\]\]}]
    return $path
}

################################################
# 'Missing' BWidget commands                   #
################################################

ScrollableFrame::use
proc ::ScrollableFrame::compute_width { path } {
		$path configure -width [winfo reqwidth [$path getframe]]
}

proc ::ScrollableFrame::compute_height { path } {
		$path configure -height [winfo reqheight [$path getframe]]
}

proc ::ScrollableFrame::compute_size { path } {
	$path compute_width
	$path compute_height
}


proc ::ScrollableFrame::_frameConfigure {canvas frame width height} {
    $canvas:cmd configure -scrollregion [$canvas:cmd bbox all]
}