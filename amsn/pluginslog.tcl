namespace eval ::pluginslog {
    #counter: keeps the count
    variable idx -1
    #log: this is what keeps track of the log
    variable log
    #filter: this is the filters
    variable filters [list]
    #window: the name of window
    variable window ".plugins_log"
    #followtext: follow text?
    variable followtext 1
    
    proc plugins_log {plugin msg} {
	variable window
	variable idx
	variable log

	#ensure msg ends in a newline
	if { [string index $msg end] != "\n" } {
		set msg "$msg\n"
	}

	incr idx
	if { $idx > 499 } {
		set idx 0
	}
	set log($idx) [list $plugin [timestamp] $msg]
	if {"[wm state $window]" == "normal"} {	
		::pluginslog::display
	}
    }
    
    proc toggle {} {
	variable window
	if {"[wm state $window]" == "normal"} {
		wm state $window withdrawn
	} else {
		wm state $window normal
		::pluginslog::redisplay
		raise $window
	}
    }
    
    proc display {} {
	variable idx
	variable log
	variable window
	variable filters
	variable followtext
	set plugin [lindex $::pluginslog::log($idx) 0]
	#if no filters, show all
	#if in filter, show it.
	if {[llength $filters] == 0 || [lsearch $filters $plugin] != -1} { 
		$window.info insert end "[lindex $pluginslog::log($idx) 1] $plugin: [lindex $pluginslog::log($idx) 2]"
		#If option "scroll down when new text is entered" 
		if {$followtext} {
			catch {$window.info yview end}
		}
	}
    }
    
    proc redisplay {} {
	variable idx
	variable log
	variable window
	variable filters

	$window.info delete 1.0 end
	for {set count 0} {$count < [array size log]} {incr count} {
		set x [expr $count + $idx]
		if { $x > 499 } {
			set x 0
		}
		set plugin [lindex $::pluginslog::log($x) 0]
		#if no filters, show all
		#if in filter, show it.
		if {[llength $filters] == 0 || [lsearch $filters $plugin] != -1} { 
			$window.info insert end "[lindex $pluginslog::log($x) 1] $plugin: [lindex $pluginslog::log($x) 2]"
		}
	}
	catch {$window.info yview end}
    }
    
    proc filter {plugin} {
	variable filters
	set idx [lsearch $filters $plugin]
	if {$idx == -1} {
		lappend filters $plugin
	} else {
		set filters [lreplace $filters $idx $idx]
	}
    }
    
    proc show_filters {} {
	variable window
	if {[winfo exists $window.filters] == 1} {
		raise $window.filters
		return
	}
	
	toplevel $window.filters
	wm title $window.filters "Plugins Log - [trans filtersx]"
	# yes, I am really lazy...
	set w $window.filters
	label $w.msg -text [trans filtersselect]
	grid $w.msg -column 1 -row 1 -columnspan 2

	set tmplist [linsert $::plugins::loadedplugins 0 "core"]
	set s [llength $tmplist]

	set col 1
	set row 2
	for {set x 0} {$x<$s} {incr x} {
		checkbutton $w.check$x -text [lindex $tmplist $x] -command "::pluginslog::filter \"[lindex $tmplist $x]\" ; ::pluginslog::redisplay"
		grid $w.check$x -column $col -row $row -sticky w
		if {$col == 2} {
			set col 1
			incr row
		} else {
			incr col
		}
	}
	incr row
	button $w.update -text "[trans close]" -command "destroy $w" ;# "::pluginslog::redisplay"
	grid $w.update -columnspan 2 -row $row -column 1
	bind $w <Destroy> ;#"::pluginslog::redisplay; bind $w <Destroy> \"\""
	moveinscreen $w 30
    }
    
    proc draw {} {
	variable window
	
	if { [winfo exists $window] } {return}
	toplevel $window
	wm group $window .
	wm state $window withdrawn
	wm title $window "Plugins Log - [trans title]"
	
	text $window.info -background white -width 60 -height 30 -wrap word \
	    -yscrollcommand "$window.ys set"
	# -font splainf
	scrollbar $window.ys -command "$window.info yview"
	checkbutton $window.follow -text "[trans followtext]" -onvalue 1 -offvalue 0 -variable {::pluginslog::followtext}
	# -font sboldf
	
	frame $window.bot -relief sunken -borderwidth 1
	button $window.bot.filters -text "[trans filters]" -command ::pluginslog::show_filters
	button $window.bot.save -text "[trans savetofile]" -command ::pluginslog::save
	button $window.bot.clear -text "[trans clear]" -command "$window.info delete 0.0 end"
	button $window.bot.close -text "[trans close]" -command {::pluginslog::toggle}
	pack $window.bot.filters $window.bot.save $window.bot.close $window.bot.clear -side left
	pack $window.bot $window.follow -side bottom
	pack $window.ys -side right -fill y
	pack $window.info -expand true -fill both
	
	$window.info tag configure green -foreground darkgreen
	$window.info tag configure red -foreground red
	$window.info tag configure white -foreground white -background black
	$window.info tag configure blue -foreground blue
	$window.info tag configure error -foreground white -background black
	
	wm protocol $window WM_DELETE_WINDOW { ::pluginslog::toggle }
    }
    
    proc save {} {
	set w .filters_save
	
	toplevel $w
	wm title $w \"[trans savetofile]\"
	label $w.msg -justify center -text "Please give a filename"
	pack $w.msg -side top
	
	frame $w.buttons -class Degt
	pack $w.buttons -side bottom -fill x -pady 2m
	button $w.buttons.dismiss -text Cancel -command "destroy $w"
	button $w.buttons.save -text Save -command "::pluginslog::save_file $w.filename.entry; destroy $w"
	pack $w.buttons.save $w.buttons.dismiss -side left -expand 1
	
	frame $w.filename -bd 2 -class Degt
	entry $w.filename.entry -relief sunken -width 40
	label $w.filename.label -text "Filename:"
	pack $w.filename.entry -side right 
	pack $w.filename.label -side left
	pack $w.msg $w.filename -side top -fill x
	focus $w.filename.entry
	
	chooseFileDialog "plugins_log.txt" "" $w $w.filename.entry save
	
	catch {grab $w}
    }
    
    proc save_file { filename } {
	variable window
	
	set fd [open [${filename} get] a+]
	fconfigure $fd -encoding utf-8
	puts $fd "[$window.info get 0.0 end]"
	close $fd
    }
}

if { $initialize_amsn == 1 } {
     ::pluginslog::draw
}

