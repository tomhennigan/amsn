#windowlist.tcl: provides routines for managing windows from menu, i.e. minimize, raise, bring all to front; standard menu item on Mac OS X. 

#(c) 2009 WordTech Communications LLC. License: standard Tcl license, http://www.tcl.tk/software/tcltk/license.html

#includes code from http://wiki.tcl.tk/1461

##"cycle through windows" code courtesy of Tom Hennigan, tomhennigan@gmail.com, (c) 2009

package provide windowlist 1.1

namespace eval windowlist {

    #make the window menu
    proc windowMenu {mainmenu} {

	menu $mainmenu.window

	$mainmenu.window add command -label "Minimize" -command [namespace current]::minimizeFrontWindow
	$mainmenu.window add separator
	$mainmenu.window add command -label "Bring All to Front" -command [namespace current]::raiseAllWindows
	$mainmenu.window add separator
	$mainmenu.window add command -label "Cycle Through Windows" \
	    -command  {raise [lindex [wm stackorder .] 0]} \
	    -accelerator "Command-`"
       	bind all <Command-quoteleft> {raise [lindex [wm stackorder .] 0]}
	$mainmenu.window add separator
	$mainmenu.window add separator
	
	$mainmenu add cascade -label "Window" -menu $mainmenu.window
	
        #bind the window menu to update whenever a new window is added, on menu selection
       	bind all <<MenuSelect>> +[list [namespace current]::updateWindowMenu $mainmenu.window]

    }

    
    #update the window menu with windows
    proc updateWindowMenu {windowmenu} {

	set windowlist [wm stackorder .]
	if {$windowlist == {}} {
	    return
	} else {
	    $windowmenu delete 6 end
	    foreach item $windowlist {
		$windowmenu add command -label "[wm title $item]"  -command [list raise $item]

	    }
	}
    }


    #make all windows visible
    proc raiseAllWindows {} {
	#blacklist certain windows
	set blacklist [list .#BWidget .plugins_log .fake .status .degt .nscmd]
	
	#use [winfo children .] here to get windows that are minimized
	foreach item [winfo children .] {
	    # Check if the window has been blacklisted.
	    if { [lsearch $blacklist $item] != -1 } {
		continue
	    }
	    
	    #get all toplevel windows, exclude menubar windows
	    if { [string equal [winfo toplevel $item] $item] && [catch {$item cget -tearoff}]} {
		wm deiconify $item
	    }
	}
	#be sure to deiconify ., since the above command only gets the child toplevels
	wm deiconify .
    }

    #minimize the selected window
    proc minimizeFrontWindow {} {

	#get list of mapped windows
	set windowlist [wm stackorder .]

	#do nothing if all windows are minimized
	if {$windowlist == {}} {
	    return
	} else {

	    #minimize topmost window
	    set topwindow [lindex $windowlist end]
	    wm iconify $topwindow

	}
    }

    
    
    #demo to show how things work

    proc demo {} {

	menu .mb
	. configure -menu .mb

	menu .mb.file 
	.mb.file add command -label "Quit" -command exit
	.mb add cascade -label "File" -menu .mb.file
   
	[namespace current]::windowMenu .mb

	toplevel .a
	toplevel .b

    }
    

    namespace export *

}
