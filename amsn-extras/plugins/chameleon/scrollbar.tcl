namespace eval ::chameleon::scrollbar {
    proc scrollbar_customParseConfArgs {w parsed_options args } {
	array set options $args
	array set ttk_options $parsed_options
	
	if { [info exists options(-orient)] } {
	    set pattern ""
	    for {set i 0} {$i < [string length $options(-orient)] } {incr i} {
		if {$i == 0 } {
		    append pattern [string index $options(-orient) $i]
		} else {
		    append pattern "\[[string index $options(-orient) $i]\]"
		}
	    }
	    append pattern "*"

	    if {[string match $pattern "vertical"]} {
		set ttk_options(-orient) "vertical"
	    } elseif {[string match $pattern "horizontal"]} {
		set ttk_options(-orient) "horizontal"
	    } else {
		set ttk_options(-orient) $options(-orient)
	    }
	}
	
	return [array get ttk_options]
    }

    proc init_scrollbarCustomOptions { } {
	variable scrollbar_widgetOptions
	variable scrollbar_widgetCommands
	

 	array set scrollbar_widgetOptions {
	    -activebackground -ignore
	    -background -styleOption
	    -bg -styleOption
	    -borderwidth -styleOption
	    -bd -styleOption
	    -highlightbackground -ignore
	    -highlightcolor -ignore
	    -highlightthickness -ignore
	    -jump -ignore
	    -orient -toImplement
	    -relief -styleOption
	    -repeatdelay -ignore
	    -repeatinterval -ignore
	    -troughcolor -ignore
	    -activerelief -ignore
	    -command -command
	    -elementborderwidth -ignore
	    -width -ignore
	    -height -ignore
	}    
	
	array set scrollbar_widgetCommands [list activate {1 {scrollbar_activate $w}} \
						delta {1 {$w delta}} \
						fraction {1 {$w fraction}} \
						get {1 {$w get}} \
						identify {2 {$w identify}} \
						set {2 {$w set}} \
						scroll {2 {$w scroll}} \
						moveto {1 {$w moveto}}]

    }

    proc scrolbar_activate  { w  {element ""}} {
	#TODO	
    }
	    
    proc scrollbar_customCget { w option } {
	if {$option == "-orient"} {
	    return [$w cget -orient]
	}
	return ""
    }

}