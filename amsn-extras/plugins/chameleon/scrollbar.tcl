namespace eval ::chameleon::scrollbar {
    proc scrollbar_customParseConfArgs {w parsed_options args } {
	return $parsed_options
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
	    -orient -orient
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
	
	array set scrollbar_widgetCommands [list activate {1 {scrollbar_activate $w $args}} \
						delta {1 {$w delta $args}} \
						fraction {1 {$w fraction $args}} \
						get {1 {$w get $args}} \
						identify {2 {$w identify $args}} \
						set {2 {$w set $args}} \
						scroll {2 {$w scroll $args}} \
						moveto {1 {$w moveto $args}}]

    }

    proc scrolbar_activate  { w  {element ""}} {
	#TODO	
    }
	    
    proc scrollbar_customCget { w option } {
	return ""
    }

}