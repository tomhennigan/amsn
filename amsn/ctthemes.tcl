#	Simple Application Themes for Tcl/Tk
#	Copyright (c)2002 D. Emilio Grimaldo Tuñón 
#	Copyright (c)2002 Coralys Technologies,Inc.
#	All Rights Reserved
#	http://home.iae.nl/users/grimaldo/
#-----------------------------------------------------------------
# $Id$
#-----------------------------------------------------------------
namespace eval ::themes {
    namespace export Init RegisterWidget Apply ApplyDeep AddClass \
    		LoadXDefaults

    if { $initialize_amsn == 1 } {
	variable version "0.1"
    }

    #
    # P U B L I C
    #
    proc Init {} {
	set Entry {bg #FFFFFF foreground #0000FF}
	set Label {bg #AABBCC foreground #000000}
	set Text {bg #2200FF foreground #111111 font splainf}
	set Button {foreground #111111}
	#    set Frame {background #111111}
	::themes::AddClass Degt Entry $Entry 90
	::themes::AddClass Degt Label $Label 90
	::themes::AddClass Degt Text $Text 90
	::themes::AddClass Degt Button $Button 90
	#    ::themes::AddClass Degt Frame $Frame 90
    }

    # Function  : themes::RegisterWidget
    # Parameters:
    # See Also  : themes::Apply
    # Synopsis  :
    #	  Use this function to register the widgets that will be re-configured
    #	  in their properties/class with the ::Apply() member function.
    proc RegisterWidget {widget class} {
    }

    # Function  : themes::Apply
    # Parameters:
    # See Also  : themes::RegisterWidget
    # Synopsis  :
    #	  Reconfigures the stated properties of the registered widgets.
    #	  Only those widgets will be configured. If you want to
    #	  do a deep (recursive) reconfiguration down the tree/children,
    #     then you must use ::ApplyDeep() which requires specifying the
    #     parent widget among other things.
    proc Apply {} {
    }

    # *** Public Helpers ***
    # Function  : themes::AddClass
    # Parameters:
    #		name		Class name
    #		type		Widget type (Label, Entry, etc.), or "" or "*"
    #		option		Option list, ie "background #AABBCC fg #AA0011
    #		                Option names with/out the dash (-)
    #		priority	Priority level (see option(n))
    # Synopsis  :
    #	  Interactively create a class 'name' so that later the entire
    #	  collection of attributes in 'option' can be applied to a
    #     widget using -class ClassName. 
    #     If type is specified you get *Class.type.option value
    #	  otherwise ("" or "*") you get *Class.option value
    proc AddClass {name type options {priority ""}} {
        set len [llength $options]
	if {[expr {$len % 2}] != 0} {
	    status_log "Themes ERR: AddClass with incomplete option list"
	    return
	}
	for {set i 0} {$i < $len} {incr i} {
	    set key [lindex $options $i]; incr i;
	    set val [lindex $options $i]
	    # Eliminate leading '-' if present
	    if {[string index $key 0] == "-"} {
	        set key [string range $key 1 end]
	    }
	    if {($type != "") && ($type != "*")} {
	    	# i.e. class.Label.background #AABBCC,(widget specific)
	    	# otherwise  class.background #AABBCC (global)
		set type ".$type"
	    }
	    if {$priority != ""} {	;# See option(n)
		option add *$name$type.$key $val $priority
	    } else {
		option add *$name$type.$key $val
	    }
	}
    }

    # Function  : themes::ApplyDeep
    # Parameters:
    #		path  		Widget path
    #		options		Options, ie {-background -highlightBackground} 
    #		value		Value to apply to each option
    # Synopsis  :
    #	  For each of the named options apply the given value for the
    #	  given widget path. Then do the same recursively for ALL the
    #	  children of that widget.
    proc ApplyDeep {path options value} {
	foreach option $options {
	    catch {
		$path config $option $value
	    }
	}
	foreach child [winfo children $path] {
	    ::themes::ApplyDeep $child $options $value
	}
    }

    # Function  : themes::LoadXDefaults
    # Parameters:
    # See Also  : 
    # Synopsis  : Load the widget options from a file in Xdefaults
    #		  format.
    proc LoadXDefaults {file {priority "interactive"}} {
	# See option(n):
	#  widgetDefault (prio. 20), startupFile (prio. 40)
	#  userDefault (prio. 60), interactive (prio. 80)
	option readfile $file $priority
    }

    #
    # P R I V A T E
    #
}

# Widget types (for class)
#	Label Entry Text Dialog Menu Menubutton Button Scrollbar Canvas 
#	Listbox
#set classattr [list			\
#	highlightThickness	0	\
#	borderWidth		0	\
#	relief			raised	\
#	padX			3	\
#	padY			3	\
#]
#::themes::AddClass NoteBook Label $classattr
